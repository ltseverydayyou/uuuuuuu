--[[
	Environment Explorer

	more stuff like getfunctionbytecode if supported, can be added

	TODO: add editing of funcs directly via this instead of data explorer
]]
local Main, Lib, Apps, Settings
local Explorer, Properties, ScriptViewer, EnvExplorer
local env, service, plr

local function InitDeps(Data)
	Main, Lib, Apps, Settings = Data.Main, Data.Lib, Data.Apps, Data.Settings
	env, service, plr = Data.env, Data.service, Data.plr
end

local function InitAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	EnvExplorer = Apps.EnvExplorer
end

local function MainFunc()
	local EnvExplorer = {}
	local Window, ListFrame, SearchBox, FilterBtn
	local ListItems = {}
	local ContextMenu, FilterMenu

	EnvExplorer.ShowTables = true
	EnvExplorer.MaxDepth = 3
	EnvExplorer.CurrentScript = nil

	local CurrentRefreshId = 0
	local BlockedFuncs = {}

	local DetailWindow, DetailCodeFrame
	local HookWindow, HookCodeFrame
	local DepthWindow

	local function GetHash(Func)
		if env.getfunctionhash then return env.getfunctionhash(Func) end
		return tostring(Func):match("0x%w+") or "No Hash"
	end

	local function SerializeData(Data, Depth, Seen)
		Depth = Depth or 1
		Seen = Seen or {}
		local Indent = string.rep("    ", Depth)
		local PrevIndent = string.rep("    ", Depth - 1)

		local DataType = typeof(Data)

		if DataType == "string" then
			return string.format("%q", Data)
		elseif DataType == "number" or DataType == "boolean" then
			return tostring(Data)
		elseif DataType == "nil" then
			return "nil"
		elseif DataType == "Instance" then
			local Success, Path = pcall(function() return Explorer.GetInstancePath(Data) end)
			return Success and Path or "Instance"
		elseif DataType == "function" then
			local InfoSrc = pcall(debug.info, Data, "s") and debug.info(Data, "s") or ""
			local InfoLine = pcall(debug.info, Data, "l") and debug.info(Data, "l") or -1
			local InfoWhat = (InfoLine == -1) and "C" or "Lua"
			local InfoName = pcall(debug.info, Data, "n") and debug.info(Data, "n") or ""
			local InfoArity, InfoVargs = pcall(debug.info, Data, "a")
			if not InfoArity then InfoArity = 0; InfoVargs = false end

			return string.format("function()\n%s--[[\n%s    info = {\n%s        source = %q,\n%s        line = %d,\n%s        what = %q,\n%s        name = %q,\n%s        numparams = %d,\n%s        vargs = %s\n%s    }\n%s]]\n%send",
				Indent, Indent, Indent, InfoSrc, Indent, InfoLine, Indent, InfoWhat, Indent, InfoName, Indent, InfoArity, Indent, tostring(InfoVargs), Indent, PrevIndent)
		elseif DataType == "table" then
			if Seen[Data] then return '"*** cycle table reference detected ***"' end
			if Depth > EnvExplorer.MaxDepth then return '"<Max Depth Reached>"' end
			Seen[Data] = true

			local Str = "{\n"
			local Count = 0
			for k, v in pairs(Data) do
				Count = Count + 1
				local KeyStr
				if type(k) == "string" and string.match(k, "^[%a_][%w_]*$") then
					KeyStr = k
				else
					KeyStr = "[" .. SerializeData(k, Depth + 1, Seen) .. "]"
				end
				Str = Str .. Indent .. KeyStr .. " = " .. SerializeData(v, Depth + 1, Seen) .. ",\n"
			end
			Seen[Data] = nil
			if Count == 0 then return "{}" end
			return Str .. PrevIndent .. "}"
		elseif DataType == "RBXScriptConnection" then
			return "(nil --[[ RBXScriptConnection | IsConnected: " .. tostring(Data.Connected) .. " ]])"
		else
			return DataType .. ".new(" .. tostring(Data) .. ")"
		end
	end

	local function ViewFunctionDetail(Func, Name, Hash)
		local InfoStr = ""
		local Success, NameInfo = pcall(debug.info, Func, "n")
		local _, SourceInfo = pcall(debug.info, Func, "s")
		local _, LineInfo = pcall(debug.info, Func, "l")
		local _, ArityInfo, IsVarargInfo = pcall(debug.info, Func, "a")

		InfoStr = InfoStr .. "Function Hash: " .. tostring(Hash) .. "\n"
		InfoStr = InfoStr .. "Name: " .. (NameInfo ~= "" and NameInfo or "Anonymous") .. "\n"
		InfoStr = InfoStr .. "Source: " .. tostring(SourceInfo) .. "\n"
		InfoStr = InfoStr .. "Current Line: " .. tostring(LineInfo) .. "\n"
		InfoStr = InfoStr .. "IsVararg, Arity: " .. tostring(IsVarargInfo) .. ", " .. tostring(ArityInfo) .. "\n"

		local IsCClosure = false
		if env.iscclosure then IsCClosure = env.iscclosure(Func) end
		InfoStr = InfoStr .. "Function Type: " .. (IsCClosure and "C Closure" or "Lua Closure") .. "\n\n"

		if not IsCClosure then
			local _, Constants = pcall(env.getconstants, Func)
			InfoStr = InfoStr .. "Constants (" .. (Constants and #Constants or 0) .. "):\n"
			if Constants and #Constants > 0 then
				for i, v in pairs(Constants) do
					InfoStr = InfoStr .. "[" .. i .. "] = " .. SerializeData(v, 1) .. "\n"
				end
			end

			local _, Upvalues = pcall(env.getupvalues, Func)
			InfoStr = InfoStr .. "\nUpvalues (" .. (Upvalues and #Upvalues or 0) .. "):\n"
			if Upvalues and #Upvalues > 0 then
				for i, v in pairs(Upvalues) do
					InfoStr = InfoStr .. "  [" .. i .. "] = " .. SerializeData(v, 1) .. "\n"
				end
			end

			local _, Protos = pcall(env.getprotos, Func)
			InfoStr = InfoStr .. "\nProtos (" .. (Protos and #Protos or 0) .. "):\n"
			if Protos and #Protos > 0 then
				for i, v in pairs(Protos) do
					local PName = (pcall(debug.info, v, "n") and debug.info(v, "n")) or ""
					InfoStr = InfoStr .. "  [" .. i .. "] " .. (PName == "" and "Anonymous" or PName) .. " - " .. GetHash(v) .. "\n"
				end
			end
		end

		DetailWindow:SetTitle("Details: " .. Name)
		DetailCodeFrame:SetText(InfoStr)
		DetailWindow:Show()
	end

	local function ViewTableDetail(Tab, Name)
		local Success, Content = pcall(SerializeData, Tab, 1)
		DetailWindow:SetTitle("Details: " .. Name)
		DetailCodeFrame:SetText(Success and Content or "Error reading table.")
		DetailWindow:Show()
	end

	EnvExplorer.Refresh = function()
		CurrentRefreshId = CurrentRefreshId + 1
		local ThisRefreshId = CurrentRefreshId

		for _, v in pairs(ListItems) do
			v.Gui:Destroy()
		end
		table.clear(ListItems)

		if not EnvExplorer.CurrentScript then return end
		local Scr = EnvExplorer.CurrentScript

		local FoundFuncs = {}
		local FoundTables = {}
		local Seen = {}
		local lys = os.clock()
		local frb = 0.012
		local ItemsCreated = 0

		local CurrentSearch = SearchBox.TextBox.Text:lower()

		local function CreateItem(Name, TypeNote, ObjRef, IsTable)
			if ThisRefreshId ~= CurrentRefreshId then return end

			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.new(1, 0, 0, 25)
			Btn.BackgroundColor3 = Settings.Theme.Main1
			Btn.BorderSizePixel = 0
			Btn.Text = ""
			Btn.AutoButtonColor = false

			local NameLabel = Instance.new("TextLabel", Btn)
			NameLabel.BackgroundTransparency = 1
			NameLabel.Position = UDim2.new(0, 5, 0, 0)
			NameLabel.Size = UDim2.new(0.6, -10, 1, 0)
			NameLabel.Font = Enum.Font.SourceSans
			NameLabel.TextSize = 14
			NameLabel.TextColor3 = Settings.Theme.Text
			NameLabel.TextXAlignment = Enum.TextXAlignment.Left
			NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			NameLabel.Text = (Name == "" and "Anonymous") or Name

			local NoteLabel = Instance.new("TextLabel", Btn)
			NoteLabel.BackgroundTransparency = 1
			NoteLabel.Position = UDim2.new(0.6, 0, 0, 0)
			NoteLabel.Size = UDim2.new(0.4, -25, 1, 0)
			NoteLabel.Font = Enum.Font.SourceSans
			NoteLabel.TextSize = 13
			NoteLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			NoteLabel.TextXAlignment = Enum.TextXAlignment.Right
			NoteLabel.Text = TypeNote

			local DotsBtn = Instance.new("ImageButton", Btn)
			DotsBtn.BackgroundTransparency = 1
			DotsBtn.Position = UDim2.new(1, -25, 0.1, 0)
			DotsBtn.Size = UDim2.new(0, 20, 0.8, 0)
			DotsBtn.Image = (getcustomasset and isfile and isfile("DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png")) and getcustomasset("DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png") or 'rbxassetid://71826111118631'

			Btn.MouseEnter:Connect(function() Btn.BackgroundColor3 = Settings.Theme.ButtonHover end)
			Btn.MouseLeave:Connect(function() Btn.BackgroundColor3 = Settings.Theme.Main1 end)

			Btn.MouseButton1Click:Connect(function()
				if IsTable then ViewTableDetail(ObjRef, Name) else ViewFunctionDetail(ObjRef, Name, GetHash(ObjRef)) end
			end)

			DotsBtn.MouseButton1Click:Connect(function()
				local MouseX, MouseY = Main.Mouse.X, Main.Mouse.Y
				ContextMenu:Clear()
				if IsTable then
					ContextMenu:Add({Name = "View Table Contents", OnClick = function()
						ViewTableDetail(ObjRef, Name)
					end})
				else
					ContextMenu:Add({Name = "Copy Function Hash", OnClick = function()
						if env.setclipboard then env.setclipboard(GetHash(ObjRef)) end
					end})

					ContextMenu:Add({Name = "Copy Function as Script", OnClick = function()
						if not env.setclipboard then return end
						if string.find(TypeNote, "Global") then
							local ScrPath = Explorer.GetInstancePath(Scr)
							env.setclipboard("local func = getsenv(" .. ScrPath .. ")[\"" .. Name .. "\"]")
						else
							local Template = [[local function findfunc(str)
    for i,v in next, getgc() do
        if type(v) == 'function' then
            if tostring(v):find(str) then
                return v
            end
        end
    end
end

local func = findfunc("]] .. tostring(ObjRef) .. [[")]]
							env.setclipboard(Template)
						end
					end})

					ContextMenu:AddDivider()

					ContextMenu:Add({Name = BlockedFuncs[ObjRef] and "Unblock Function" or "Block Function", OnClick = function()
						if not BlockedFuncs[ObjRef] then
							if env.hookfunction then
								BlockedFuncs[ObjRef] = true
								env.hookfunction(ObjRef, function() return end)
							end
						else
							if env.restorefunction then
								env.restorefunction(ObjRef)
							end
							BlockedFuncs[ObjRef] = nil
						end
					end})

					ContextMenu:Add({Name = "Hook Function", OnClick = function()
						local TargetPath = ""
						if string.find(TypeNote, "Global") then
							local ScrPath = Explorer.GetInstancePath(Scr)
							TargetPath = "getsenv(" .. ScrPath .. ")[\"" .. Name .. "\"]"
						else
							TargetPath = [[(function()
    for i,v in next, getgc() do
        if type(v) == 'function' and getfunctionhash(v) == ']] .. GetHash(ObjRef) .. [[' then
            return v
        end
    end
end)()]]
						end

						local HookTemplate = string.format([[local TargetFunc = %s

local old; old = hookfunction(TargetFunc, function(...)
    -- Your hook logic here
    return old(...)
end)
]], TargetPath)
						HookCodeFrame:SetText(HookTemplate)
						HookWindow:Show()
					end})

					ContextMenu:Add({Name = "Call with Args", OnClick = function()
						Lib.SaveAsPrompt("Arguments (e.g. 1, 'String')", function(StrArgs)
							local Success, CallFunc = pcall(loadstring, "return {" .. StrArgs .. "}")
							if Success and CallFunc then
								local Args = CallFunc()
								local Res = {pcall(ObjRef, unpack(Args))}
								local S = table.remove(Res, 1)

								local ResStr = ""
								for i, val in pairs(Res) do
									ResStr = ResStr .. tostring(val) .. (i < #Res and ", " or "")
								end
								if ResStr == "" then ResStr = "nil" end

								DetailWindow:SetTitle("Returns: " .. Name)
								DetailCodeFrame:SetText(S and "Returns:\n" .. ResStr or "Error:\n" .. tostring(Res[1]))
								DetailWindow:Show()
							end
						end)
					end})

					ContextMenu:Add({Name = "Get Return Values", OnClick = function()
						local Res = {pcall(ObjRef)}
						local S = table.remove(Res, 1)

						local ResStr = ""
						for i, val in pairs(Res) do
							ResStr = ResStr .. tostring(val) .. (i < #Res and ", " or "")
						end
						if ResStr == "" then ResStr = "nil" end

						DetailWindow:SetTitle("Returns: " .. Name)
						DetailCodeFrame:SetText(S and "Returns:\n" .. ResStr or "Error:\n" .. tostring(Res[1]))
						DetailWindow:Show()
					end})
				end
				ContextMenu:Show(MouseX, MouseY)
			end)

			if CurrentSearch ~= "" then
				if not (Name:lower():find(CurrentSearch, 1, true) or TypeNote:lower():find(CurrentSearch, 1, true)) then
					Btn.Visible = false
				end
			end

			Btn.Parent = ListFrame
			table.insert(ListItems, {Gui = Btn, Name = Name, Note = TypeNote})

			ItemsCreated = ItemsCreated + 1
			if ItemsCreated % 30 == 0 and (os.clock() - lys) > frb then
				task.wait()
				lys = os.clock()
			end
		end

		if env.getsenv then
			local Success, SEnv = pcall(env.getsenv, Scr)
			if Success and type(SEnv) == "table" then
			    local Iter = 0
				for k, v in pairs(SEnv) do
				    Iter = Iter + 1
				    if Iter % 10000 == 0 then task.wait() end
				    if ThisRefreshId ~= CurrentRefreshId then return end

					if type(v) == "function" and not Seen[v] then
						Seen[v] = true
						CreateItem(tostring(k), "Global Func | " .. tostring(v), v, false)
					elseif type(v) == "table" and EnvExplorer.ShowTables and not Seen[v] then
						Seen[v] = true
						CreateItem(tostring(k), "Global Table | " .. tostring(v), v, true)
					end
				end
			end
		end

		if env.getgc then
			local SuccessClos, Clos = pcall(getscriptclosure, Scr)
			if SuccessClos and type(Clos) == "function" and not Seen[Clos] then
			    Seen[Clos] = true
			    CreateItem(Scr.Name, "Main Closure | " .. tostring(Clos), Clos, false)
			end

			local ScrConstants = {}
			if SuccessClos and type(Clos) == "function" and env.getconstants then
				local SuccessConst, Consts = pcall(env.getconstants, Clos)
				if SuccessConst and Consts then
					for _, c in pairs(Consts) do
						if type(c) == "string" then ScrConstants[c] = true end
					end
				end
			end

			local Gc = env.getgc(true)
			for Iter, v in pairs(Gc) do
			   	Iter = Iter + 1
				if Iter % 2000 == 0 and (os.clock() - lys) > frb then
					task.wait()
					lys = os.clock()
				end
				if ThisRefreshId ~= CurrentRefreshId then return end

				if type(v) == "function" and not Seen[v] and not env.isourclosure(v) then
					local SuccessInfo, Src = pcall(debug.info, v, "s")
					if SuccessInfo and Src and (Src:find(Scr.Name, 1, true) or Src:find(Scr.ClassName, 1, true)) then
						Seen[v] = true
						CreateItem(debug.info(v, "n"), "Local Func | " .. tostring(v), v, false)
					end
				elseif type(v) == "table" and EnvExplorer.ShowTables and not Seen[v] then
					local MatchesScript = false
					for CStr, _ in pairs(ScrConstants) do
						local SuccessRaw, Res = pcall(rawget, v, CStr)
						if SuccessRaw and Res ~= nil then
							MatchesScript = true
							break
						end
					end

					if MatchesScript then
						Seen[v] = true
						CreateItem("Table", "Local Table | " .. tostring(v), v, true)
					end
				end
			end
		end
	end

	EnvExplorer.ViewEnvironment = function(Scr)
		EnvExplorer.CurrentScript = Scr
		Window:SetTitle("Environment: " .. Scr.Name)
		EnvExplorer.Refresh()
		Window:Show()
	end

	EnvExplorer.Init = function()
		Window = Lib.Window.new()
		Window.RestoreLastSide = false
		Window:SetTitle("Environment Explorer")
		Window:Resize(450, 400)
		EnvExplorer.Window = Window

		ContextMenu = Lib.ContextMenu.new()
		ContextMenu.Iconless = true
		ContextMenu.Width = 200

		FilterMenu = Lib.ContextMenu.new()
		FilterMenu.Iconless = true
		FilterMenu.Width = 150

		local function BuildFilterMenu()
			FilterMenu:Clear()
			FilterMenu:Add({
				Name = EnvExplorer.ShowTables and "Hide Tables" or "Show Tables",
				OnClick = function()
					EnvExplorer.ShowTables = not EnvExplorer.ShowTables
					BuildFilterMenu()
					EnvExplorer.Refresh()
				end
			})
			FilterMenu:Add({
				Name = "Set Depth Limit ("..EnvExplorer.MaxDepth..")",
				OnClick = function()
				    DepthWindow.Elements.DepthInput:SetText(tostring(EnvExplorer.MaxDepth))
				    DepthWindow:Show()
				end
			})
		end
		BuildFilterMenu()

		DepthWindow = Lib.Window.new()
		DepthWindow.Alignable = false
		DepthWindow.Resizable = false
		DepthWindow:SetTitle("Set Max Depth")
		DepthWindow:SetSize(250, 95)

		local DepthLabel = Lib.Label.new()
		DepthLabel.Text = "Depth:"
		DepthLabel.Position = UDim2.new(0, 10, 0, 10)
		DepthLabel.Size = UDim2.new(0, 50, 0, 20)
		DepthWindow:Add(DepthLabel)

		local DepthInput = Lib.ViewportTextBox.new()
		DepthInput.Position = UDim2.new(0, 60, 0, 10)
		DepthInput.Size = UDim2.new(1, -70, 0, 20)
		DepthWindow:Add(DepthInput, "DepthInput")

		local DepthSave = Lib.Button.new()
		DepthSave.Text = "Set"
		DepthSave.Position = UDim2.new(0, 5, 1, -25)
		DepthSave.Size = UDim2.new(1, -10, 0, 20)
		DepthSave.OnClick:Connect(function()
			local Num = tonumber(DepthInput:GetText())
			if Num then
			    EnvExplorer.MaxDepth = Num
			    BuildFilterMenu()
			    DepthWindow:Hide()
			end
		end)
		DepthWindow:Add(DepthSave)

		DetailWindow = Lib.Window.new()
		DetailWindow:SetTitle("Details")
		DetailWindow:Resize(450, 400)

		local DetailCopyBtn = Instance.new("TextButton", DetailWindow.GuiElems.Content)
		DetailCopyBtn.Size = UDim2.new(1, 0, 0, 20)
		DetailCopyBtn.Position = UDim2.new(0, 0, 0, 0)
		DetailCopyBtn.BackgroundTransparency = 1
		DetailCopyBtn.Text = "Copy to Clipboard"
		DetailCopyBtn.TextColor3 = Color3.new(1,1,1)
		DetailCopyBtn.MouseButton1Click:Connect(function()
			if env.setclipboard then env.setclipboard(DetailCodeFrame:GetText()) end
		end)

		DetailCodeFrame = Lib.CodeFrame.new()
		DetailCodeFrame.Frame.Position = UDim2.new(0, 0, 0, 20)
		DetailCodeFrame.Frame.Size = UDim2.new(1, 0, 1, -20)
		DetailCodeFrame.Frame.Parent = DetailWindow.GuiElems.Content
		DetailCodeFrame.Editable = false

		HookWindow = Lib.Window.new()
		HookWindow:SetTitle("Hook Editor")
		HookWindow:Resize(450, 400)

		HookCodeFrame = Lib.CodeFrame.new()
		HookCodeFrame.Frame.Position = UDim2.new(0, 0, 0, 0)
		HookCodeFrame.Frame.Size = UDim2.new(1, 0, 1, -20)
		HookCodeFrame.Frame.Parent = HookWindow.GuiElems.Content
		HookCodeFrame.Editable = true

		local HookCopyBtn = Instance.new("TextButton", HookWindow.GuiElems.Content)
		HookCopyBtn.Size = UDim2.new(0.5, 0, 0, 20)
		HookCopyBtn.Position = UDim2.new(0, 0, 1, -20)
		HookCopyBtn.BackgroundColor3 = Settings.Theme.Main2
		HookCopyBtn.BorderSizePixel = 0
		HookCopyBtn.Text = "Copy to Clipboard"
		HookCopyBtn.TextColor3 = Color3.new(1, 1, 1)

		HookCopyBtn.MouseButton1Click:Connect(function()
			if env.setclipboard then env.setclipboard(HookCodeFrame:GetText()) end
		end)

		local HookExecuteBtn = Instance.new("TextButton", HookWindow.GuiElems.Content)
		HookExecuteBtn.Size = UDim2.new(1, 0, 0, 20)
		HookExecuteBtn.Position = UDim2.new(0, 0, 1, -20)
		HookExecuteBtn.BackgroundColor3 = Settings.Theme.Button
		HookExecuteBtn.BorderSizePixel = 0
		HookExecuteBtn.Text = "Execute"
		HookExecuteBtn.TextColor3 = Color3.new(1, 1, 1)
		HookExecuteBtn.MouseButton1Click:Connect(function()
			if env.loadstring then env.loadstring(HookCodeFrame:GetText(), "DEX")() end
		end)

		local TopBar = Instance.new("Frame", Window.GuiElems.Content)
		TopBar.Size = UDim2.new(1, 0, 0, 24)
		TopBar.BackgroundColor3 = Settings.Theme.Main2
		TopBar.BorderSizePixel = 0

		SearchBox = Lib.ViewportTextBox.new()
		SearchBox.Gui.Parent = TopBar
		SearchBox.Size = UDim2.new(1, -75, 1, -4)
		SearchBox.Position = UDim2.new(0, 4, 0, 2)
		SearchBox.TextBox.PlaceholderText = "Search Functions & Tables..."

		local RefreshBtn = Instance.new("ImageButton", TopBar)
		RefreshBtn.Size = UDim2.new(0, 18, 0, 18)
		RefreshBtn.Position = UDim2.new(1, -22, 0, 3)
		RefreshBtn.BackgroundTransparency = 1
		RefreshBtn.Image = (getcustomasset and isfile and isfile("DEX_REContinued/Images/refresh-icon3.png")) and getcustomasset("DEX_REContinued/Images/refresh-icon3.png") or "rbxassetid://5642310344"
		RefreshBtn.MouseButton1Click:Connect(function()
			EnvExplorer.Refresh()
		end)

		FilterBtn = Instance.new("TextButton", TopBar)
		FilterBtn.Size = UDim2.new(0, 42, 0, 18)
		FilterBtn.Position = UDim2.new(1, -67, 0, 3)
		FilterBtn.BackgroundColor3 = Settings.Theme.Button
		FilterBtn.BorderSizePixel = 0
		FilterBtn.TextColor3 = Settings.Theme.Text
		FilterBtn.Font = Enum.Font.SourceSans
		FilterBtn.TextSize = 14
		FilterBtn.Text = "Filter"

		FilterBtn.MouseButton1Click:Connect(function()
			local MouseX, MouseY = Main.Mouse.X, Main.Mouse.Y
			FilterMenu:Show(MouseX, MouseY)
		end)

		ListFrame = Instance.new("ScrollingFrame", Window.GuiElems.Content)
		ListFrame.Size = UDim2.new(1, 0, 1, -24)
		ListFrame.Position = UDim2.new(0, 0, 0, 24)
		ListFrame.BackgroundTransparency = 1
		ListFrame.BorderSizePixel = 0
		ListFrame.ScrollBarThickness = 6
		ListFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)

		local ListLayout = Instance.new("UIListLayout", ListFrame)
		ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
		end)

		SearchBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
			local Txt = SearchBox.TextBox.Text:lower()
			for _, Item in pairs(ListItems) do
				if Txt == "" or Item.Name:lower():find(Txt, 1, true) or Item.Note:lower():find(Txt, 1, true) then
					Item.Gui.Visible = true
				else
					Item.Gui.Visible = false
				end
			end
		end)
	end

	return EnvExplorer
end
return {InitDeps = InitDeps, InitAfterMain = InitAfterMain, Main = MainFunc}
