--!nonstrict
local unpack = table.unpack or unpack
local loadstring = loadstring or load
local newproxy = newproxy or function()
	return setmetatable({}, {
		__tostring = function()
			return "userdata: 0x0"
		end,
	})
end

--[[
	Debug Explorer App Module
]]
local Main, Lib, Apps, Settings
local Explorer, Properties, ScriptViewer, EnvExplorer, DebugExplorer
local API, RMD, env, service, plr, create, createSimple

local function InitDeps(Data)
	Main, Lib, Apps, Settings = Data.Main, Data.Lib, Data.Apps, Data.Settings
	API, RMD, env, service, plr = Data.API, Data.RMD, Data.env, Data.service, Data.plr
	create, createSimple = Data.create, Data.createSimple
end

local function InitAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	EnvExplorer = Apps.EnvExplorer
	DebugExplorer = Apps.DebugExplorer
end

local function MainFunc()
	local DebugExplorer = {}
	local Window
	local TopFrame, LeftPane, RightPane, WaitingLabel
	local NameLabel, IconImage, PathLabel
	local LeftList, RightList

	local FuncContextMenu, PropContextMenu, EventContextMenu
	local LeftContextMenu, ConnContextMenu

	local HookWindow, HookCodeFrame
	local ConnWindow, ConnList
	local SpoofWindow, SpoofDrop, SpoofBox -- Unified Spoof UI

	DebugExplorer.CurrentInstance = nil
	DebugExplorer.SelectedMember = nil
	DebugExplorer.SelectedHookIndex = nil
	DebugExplorer.SelectedConnection = nil

	DebugExplorer.ActiveHooks = {}
	DebugExplorer.BlockedConnections = {}
	DebugExplorer.BlockedMembers = {} -- Tracks { [Inst] = { [PropName] = HookIndex } }

	local function ApplyInstantHook(ActionName, Code)
		if env.loadstring then
			env.loadstring(Code, "DEX")()
			local HookData = {
				Inst = DebugExplorer.SelectedMember.Target,
				Type = DebugExplorer.SelectedMember.Type,
				Name = DebugExplorer.SelectedMember.Name,
				Action = ActionName,
				ScriptSource = Code
			}
			table.insert(DebugExplorer.ActiveHooks, HookData)
			DebugExplorer.RefreshLeftPane()
			return true
		else
			warn("Executor does not support loadstring!")
			return false
		end
	end

	local function GetHookIndex(Target, Name)
		for Idx, Hook in pairs(DebugExplorer.ActiveHooks) do
			if Hook.Inst == Target and Hook.Name == Name then
				return Idx, Hook
			end
		end
		return nil
	end

	local function UnhookMember(Target, Name)
		local Idx, Hook = GetHookIndex(Target, Name)
		if not Idx then return end

		if env.restorefunction then
			if Hook.Type == "Function" then
				pcall(env.restorefunction, getrawmetatable(game).__namecall)
				pcall(env.restorefunction, Target[Name])
			end
			if Hook.Type == "Property" then
				pcall(env.restorefunction, getrawmetatable(game).__index)
			end
		end

		table.remove(DebugExplorer.ActiveHooks, Idx)
		DebugExplorer.RefreshLeftPane()
	end

	DebugExplorer.RefreshLeftPane = function()
		for _, Child in pairs(LeftList:GetChildren()) do
			if Child:IsA("TextButton") or Child:IsA("Frame") then Child:Destroy() end
		end

		for Idx, Hook in pairs(DebugExplorer.ActiveHooks) do
			if Hook.Inst == DebugExplorer.CurrentInstance then
				local Btn = Instance.new("TextButton")
				Btn.Size = UDim2.new(1, 0, 0, 25)
				Btn.BackgroundColor3 = Settings.Theme.Main1
				Btn.BorderSizePixel = 0
				Btn.Text = ""
				Btn.AutoButtonColor = false

				local Lbl = Instance.new("TextLabel", Btn)
				Lbl.BackgroundTransparency = 1
				Lbl.Position = UDim2.new(0, 5, 0, 0)
				Lbl.Size = UDim2.new(1, -10, 1, 0)
				Lbl.Font = Enum.Font.SourceSans
				Lbl.TextSize = 14
				Lbl.TextColor3 = Settings.Theme.Text
				Lbl.TextXAlignment = Enum.TextXAlignment.Left
				Lbl.TextTruncate = Enum.TextTruncate.AtEnd

				local TypeColor = (Hook.Type == "Function") and "rgb(132,214,247)" or "rgb(173,241,149)"
				Lbl.RichText = true
				Lbl.Text = string.format("<b><font color='%s'>[%s]</font></b> %s <font color='rgb(150,150,150)'>- %s</font>", TypeColor, Hook.Type, Hook.Name, Hook.Action)

				Btn.MouseEnter:Connect(function() Btn.BackgroundColor3 = Settings.Theme.ButtonHover end)
				Btn.MouseLeave:Connect(function() Btn.BackgroundColor3 = Settings.Theme.Main1 end)

				Btn.MouseButton2Click:Connect(function()
					DebugExplorer.SelectedHookIndex = Idx
					LeftContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
				end)

				Btn.Parent = LeftList
			end
		end
	end

	DebugExplorer.RefreshConnections = function()
		for _, Child in pairs(ConnList:GetChildren()) do
			if Child:IsA("TextButton") or Child:IsA("Frame") or Child:IsA("TextLabel") then Child:Destroy() end
		end

		local Mem = DebugExplorer.SelectedMember
		if not Mem or Mem.Type ~= "Event" then return end

		local S, Conns = pcall(env.getconnections, Mem.Target[Mem.Name])
		if not S or type(Conns) ~= "table" or #Conns == 0 then
			local NoConnLbl = Instance.new("TextLabel", ConnList)
			NoConnLbl.BackgroundTransparency = 1
			NoConnLbl.Size = UDim2.new(1, 0, 1, 0)
			NoConnLbl.Font = Enum.Font.SourceSans
			NoConnLbl.TextSize = 16
			NoConnLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
			NoConnLbl.Text = "No Connections Found"
			return
		end

		for Idx, Conn in pairs(Conns) do
			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.new(1, 0, 0, 25)
			Btn.BackgroundColor3 = Settings.Theme.Main1
			Btn.BorderSizePixel = 0
			Btn.Text = ""
			Btn.AutoButtonColor = false

			local Lbl = Instance.new("TextLabel", Btn)
			Lbl.BackgroundTransparency = 1
			Lbl.Position = UDim2.new(0, 5, 0, 0)
			Lbl.Size = UDim2.new(1, -30, 1, 0)
			Lbl.Font = Enum.Font.SourceSans
			Lbl.TextSize = 14
			Lbl.TextColor3 = Settings.Theme.Text
			Lbl.TextXAlignment = Enum.TextXAlignment.Left
			Lbl.RichText = true

			local StateStr = Conn.Enabled and "<font color='rgb(0,255,0)'>Enabled</font>" or "<font color='rgb(255,0,0)'>Disabled</font>"
			local BlockStr = DebugExplorer.BlockedConnections[tostring(Conn.Function)] and " | <font color='rgb(255,100,100)'>[Blocked]</font>" or ""
			local TypeStr = Conn.ForeignState and "(Foreign/C)" or "(Lua)"

			Lbl.Text = string.format("Conn %d %s - State: %s%s", Idx, TypeStr, StateStr, BlockStr)

			local DotsBtn = Instance.new("ImageButton", Btn)
			DotsBtn.BackgroundTransparency = 1
			DotsBtn.Position = UDim2.new(1, -25, 0.1, 0)
			DotsBtn.Size = UDim2.new(0, 20, 0.8, 0)
			DotsBtn.Image = (getcustomasset and isfile and isfile("DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png")) and getcustomasset("DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png") or 'rbxassetid://71826111118631'

			Btn.MouseEnter:Connect(function() Btn.BackgroundColor3 = Settings.Theme.ButtonHover end)
			Btn.MouseLeave:Connect(function() Btn.BackgroundColor3 = Settings.Theme.Main1 end)

			Btn.MouseButton2Click:Connect(function()
				DebugExplorer.SelectedConnection = Conn
				ConnContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
			end)

			DotsBtn.MouseButton1Click:Connect(function()
				DebugExplorer.SelectedConnection = Conn
				ConnContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
			end)

			Btn.Parent = ConnList
		end
	end

	local function ShowInputPrompt(Title, DefaultText, Callback)
		local PromptWin = Lib.Window.new()
		PromptWin.Alignable = false
		PromptWin.Resizable = false
		PromptWin:SetTitle(Title)
		PromptWin:SetSize(300, 95)
		local Lbl = Lib.Label.new()
		Lbl.Text = "Input:"
		Lbl.Position = UDim2.new(0, 30, 0, 10)
		Lbl.Size = UDim2.new(0, 40, 0, 20)
		PromptWin:Add(Lbl)
		local Box = Lib.ViewportTextBox.new()
		Box.Position = UDim2.new(0, 75, 0, 10)
		Box.Size = UDim2.new(0, 210, 0, 20)
		Box.TextBox.Text = tostring(DefaultText)
		PromptWin:Add(Box, "InputBox")
		local Btn = Lib.Button.new()
		Btn.Text = "Confirm"
		Btn.Position = UDim2.new(0, 5, 1, -25)
		Btn.Size = UDim2.new(1, -10, 0, 20)
		Btn.OnClick:Connect(function()
			Callback(Box:GetText())
			PromptWin:Close()
		end)
		PromptWin:Add(Btn)
		PromptWin:Show()
	end

	local function ApplyInstantHook(ActionName, Code)
		if env.loadstring then
			env.loadstring(Code, "DEX")()
			table.insert(DebugExplorer.ActiveHooks, {
				Inst = DebugExplorer.SelectedMember.Target,
				Type = DebugExplorer.SelectedMember.Type,
				Name = DebugExplorer.SelectedMember.Name,
				Action = ActionName,
				ScriptSource = Code
			})
			DebugExplorer.RefreshLeftPane()
		else
			warn("Executor does not support loadstring!")
		end
	end

	DebugExplorer.Refresh = function()
		if not DebugExplorer.CurrentInstance then
			TopFrame.Visible = false
			LeftPane.Visible = false
			RightPane.Visible = false
			WaitingLabel.Visible = true
			return
		end

		WaitingLabel.Visible = false
		TopFrame.Visible = true
		LeftPane.Visible = true
		RightPane.Visible = true

		local Target = DebugExplorer.CurrentInstance
		NameLabel.Text = Target.Name
		PathLabel.Text = Explorer.GetInstancePath(Target)

		-- Icon
		if Settings.ClassIcon == "Vanilla3" then
			IconImage.Size = UDim2.fromOffset(16, 16)
			IconImage.Position = UDim2.new(0.5, -8, 0, 32)
		else
			IconImage.Size = UDim2.fromOffset(32, 32)
			IconImage.Position = UDim2.new(0.5, -16, 0, 25)
		end
		Explorer.ClassIcons:DisplayByKey(IconImage, Target.ClassName)

		for _, Child in pairs(RightList:GetChildren()) do
			if Child:IsA("TextButton") or Child:IsA("Frame") then Child:Destroy() end
		end

		DebugExplorer.RefreshLeftPane()

		local ClassName = Target.ClassName
		local Funcs = API.GetMember(ClassName, "Functions") or {}
		local Props = API.GetMember(ClassName, "Properties") or {}
		local Events = API.GetMember(ClassName, "Events") or {}

		local function CreateMemberItem(Type, Name, DetailStr, ApiData)
			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.new(1, 0, 0, 25)
			Btn.BackgroundColor3 = Settings.Theme.Main1
			Btn.BorderSizePixel = 0
			Btn.Text = ""
			Btn.AutoButtonColor = false

			local ItemLabel = Instance.new("TextLabel", Btn)
			ItemLabel.BackgroundTransparency = 1
			ItemLabel.Position = UDim2.new(0, 5, 0, 0)
			ItemLabel.Size = UDim2.new(1, -30, 1, 0)
			ItemLabel.Font = Enum.Font.SourceSans
			ItemLabel.TextSize = 14
			ItemLabel.TextColor3 = Settings.Theme.Text
			ItemLabel.TextXAlignment = Enum.TextXAlignment.Left
			ItemLabel.TextTruncate = Enum.TextTruncate.AtEnd
			ItemLabel.RichText = true

			local TypeColor = "rgb(200, 200, 200)"
			if Type == "Function" then TypeColor = "rgb(132, 214, 247)"
			elseif Type == "Event" then TypeColor = "rgb(255, 198, 0)"
			elseif Type == "Property" then TypeColor = "rgb(173, 241, 149)" end

			ItemLabel.Text = string.format("<b><font color='%s'>[%s]</font></b> %s<font color='rgb(150,150,150)'>%s</font>", TypeColor, Type, Name, DetailStr:gsub("<", "&lt;"):gsub(">", "&gt;"))

			local DotsBtn = Instance.new("ImageButton", Btn)
			DotsBtn.BackgroundTransparency = 1
			DotsBtn.Position = UDim2.new(1, -25, 0.1, 0)
			DotsBtn.Size = UDim2.new(0, 20, 0.8, 0)
			DotsBtn.Image = (getcustomasset and isfile and isfile("DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png")) and getcustomasset("DEX_REContinued/more_vert_1000dp_FFFFFF_FILL0_wght400_GRAD0_opsz48.png") or 'rbxassetid://71826111118631'

			Btn.MouseEnter:Connect(function() Btn.BackgroundColor3 = Settings.Theme.ButtonHover end)
			Btn.MouseLeave:Connect(function() Btn.BackgroundColor3 = Settings.Theme.Main1 end)

			local function HandleClick()
				DebugExplorer.SelectedMember = {Type = Type, Name = Name, Target = Target, ApiData = ApiData}
				local HookIdx, ExistingHook = GetHookIndex(Target, Name)
				local IsBlocked = (HookIdx ~= nil)

				if Type == "Function" then
					FuncContextMenu:Clear()
					FuncContextMenu:Add({Name = "Hook Method", OnClick = function()
						local TargetPath = Explorer.GetInstancePath(Target)
						local Template = string.format([[local Inst = %s
local compare = compareinstances or rawequal
local hookEnv = (getgenv and getgenv()) or _G
local hookCallable = hookEnv and hookEnv["hook" .. "function"]

local o; o = hookCallable(getrawmetatable(game).__namecall, newcclosure(function(self, ...)
    local method = getnamecallmethod()

    if not checkcaller() and compare(self, Inst) and method == '%s' then
        -- Your logic here
        return o(self, ...)
    end

    return o(self, ...)
end))]], TargetPath, Name)
						HookCodeFrame:SetText(Template)
						HookWindow:SetTitle("Hooking Method: " .. Name)
						HookWindow:Show()
					end})

					FuncContextMenu:Add({Name = IsBlocked and "Unblock Function" or "Block Function", OnClick = function()
						if IsBlocked then
							UnhookMember(Target, Name)
						else
							local TargetPath = Explorer.GetInstancePath(Target)
							local Code = string.format([[local Inst = %s
local compare = compareinstances or rawequal
local hookEnv = (getgenv and getgenv()) or _G
local hookCallable = hookEnv and hookEnv["hook" .. "function"]

local o; o = hookCallable(getrawmetatable(game).__namecall, newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if not checkcaller() and compare(self, Inst) and method == '%s' then
        return nil
    end
    return o(self, ...)
end))
local o2; o2 = hookCallable(Inst.%s, newcclosure(function(self, ...)
    if not checkcaller() and compare(self, Inst) then
        return nil
    end
    return o2(self, ...)
end))]], TargetPath, Name, Name)
							ApplyInstantHook("Blocked", Code)
						end
					end})

					if Name == "GetPropertyChangedSignal" then
						FuncContextMenu:AddDivider()
						FuncContextMenu:Add({Name = "Disable ALL Property Connections", OnClick = function()
							local Props = API.GetMember(Target.ClassName, "Properties") or {}
							for _, P in pairs(Props) do
								local S, Signal = pcall(function() return Target:GetPropertyChangedSignal(P.Name) end)
								if S and Signal then
									local S2, Conns = pcall(env.getconnections, Signal)
									if S2 and type(Conns) == "table" then
										for _, C in pairs(Conns) do pcall(function() C:Disable() end) end
									end
								end
							end
						end})
					end

					FuncContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)

				elseif Type == "Property" then
					PropContextMenu:Clear()
					PropContextMenu:Add({Name = "Hook Access", OnClick = function()
						local TargetPath = Explorer.GetInstancePath(Target)
						local Template = string.format([[local Inst = %s
local compare = compareinstances or rawequal
local hookEnv = (getgenv and getgenv()) or _G
local hookCallable = hookEnv and hookEnv["hook" .. "function"]

local o; o = hookCallable(getrawmetatable(game).__index, newcclosure(function(...)
    local self, arg = ...

    if not checkcaller() and compare(self, Inst) and arg == '%s' then
        -- Your logic here
        return o(...)
    end

    return o(...)
end))]], TargetPath, Name)
						HookCodeFrame:SetText(Template)
						HookWindow:SetTitle("Hooking Property: " .. Name)
						HookWindow:Show()
					end})

					PropContextMenu:Add({Name = IsBlocked and "Unblock Access" or "Block Access", OnClick = function()
						if IsBlocked then
							UnhookMember(Target, Name)
						else
							local TargetPath = Explorer.GetInstancePath(Target)
							local Code = string.format([[local Inst = %s
local compare = compareinstances or rawequal
local hookEnv = (getgenv and getgenv()) or _G
local hookCallable = hookEnv and hookEnv["hook" .. "function"]

local o; o = hookCallable(getrawmetatable(game).__index, newcclosure(function(...)
    local self, arg = ...

    if not checkcaller() and compare(self, Inst) and arg == '%s' then
        return nil
    end
    return o(...)
end))]], TargetPath, Name)
							ApplyInstantHook("Blocked", Code)
						end
					end})

					PropContextMenu:Add({Name = "Spoof Value", OnClick = function()
						SpoofWindow:SetTitle("Spoof: " .. Name)
						SpoofWindow:Show()
					end})

					PropContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)

				elseif Type == "Event" then
					EventContextMenu:Clear()
					EventContextMenu:Add({Name = "Fire All Connections", OnClick = function()
						local S, Conns = pcall(env.getconnections, Target[Name])
						if S and type(Conns) == "table" then
							for _, C in pairs(Conns) do pcall(function() C:Fire() end) end
						end
					end})
					EventContextMenu:Add({Name = "Manage Connections", OnClick = function()
						ConnWindow:SetTitle("Connections: " .. Name)
						DebugExplorer.RefreshConnections()
						ConnWindow:Show()
					end})

					EventContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
				end
			end

			DotsBtn.MouseButton1Click:Connect(HandleClick)
			Btn.MouseButton2Click:Connect(HandleClick)
			Btn.Parent = RightList
		end

		for _, f in pairs(Funcs) do
			local Params = {}
			if f.Parameters then
				for _, p in pairs(f.Parameters) do
					table.insert(Params, (p.Type and p.Type.Name or "any") .. " " .. p.Name)
				end
			end
			local Ret = (f.ReturnType and f.ReturnType.Name) or "void"
			CreateMemberItem("Function", f.Name, "(" .. table.concat(Params, ", ") .. ") : " .. Ret, f)
		end

		for _, e in pairs(Events) do
			local Params = {}
			if e.Parameters then
				for _, p in pairs(e.Parameters) do
					table.insert(Params, (p.Type and p.Type.Name or "any") .. " " .. p.Name)
				end
			end
			CreateMemberItem("Event", e.Name, "(" .. table.concat(Params, ", ") .. ")", e)
		end

		for _, p in pairs(Props) do
			local VType = p.ValueType and p.ValueType.Name or "Unknown"
			CreateMemberItem("Property", p.Name, " : " .. VType, p)
		end
	end

	DebugExplorer.Init = function()
		Window = Lib.Window.new()
		Window.RestoreLastSide = false
		Window:SetTitle("Debug Interface")
		Window:Resize(650, 500)
		DebugExplorer.Window = Window

		local Content = Window.GuiElems.Content

		WaitingLabel = Instance.new("TextLabel", Content)
		WaitingLabel.Size = UDim2.new(1, 0, 1, 0)
		WaitingLabel.BackgroundTransparency = 1
		WaitingLabel.Text = "Select an instance in the Explorer"
		WaitingLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		WaitingLabel.Font = Enum.Font.SourceSans
		WaitingLabel.TextSize = 18
		WaitingLabel.ZIndex = 5

		TopFrame = Instance.new("Frame", Content)
		TopFrame.Size = UDim2.new(1, 0, 0, 80)
		TopFrame.BackgroundColor3 = Settings.Theme.Main2
		TopFrame.BorderSizePixel = 0
		TopFrame.Visible = false

		NameLabel = Instance.new("TextLabel", TopFrame)
		NameLabel.Size = UDim2.new(1, 0, 0, 20)
		NameLabel.Position = UDim2.new(0, 0, 0, 5)
		NameLabel.BackgroundTransparency = 1
		NameLabel.TextColor3 = Settings.Theme.Text
		NameLabel.Font = Enum.Font.SourceSansBold
		NameLabel.TextSize = 16

		IconImage = Instance.new("ImageLabel", TopFrame)
		IconImage.BackgroundTransparency = 1

		PathLabel = Instance.new("TextLabel", TopFrame)
		PathLabel.Size = UDim2.new(1, 0, 0, 20)
		PathLabel.Position = UDim2.new(0, 0, 0, 55)
		PathLabel.BackgroundTransparency = 1
		PathLabel.TextColor3 = Color3.fromRGB(130, 130, 130)
		PathLabel.Font = Enum.Font.SourceSans
		PathLabel.TextSize = 14

		LeftPane = Instance.new("Frame", Content)
		LeftPane.Size = UDim2.new(0.35, 0, 1, -80)
		LeftPane.Position = UDim2.new(0, 0, 0, 80)
		LeftPane.BackgroundColor3 = Settings.Theme.Main1
		LeftPane.BorderColor3 = Settings.Theme.Outline1
		LeftPane.BorderSizePixel = 0
		LeftPane.Visible = false

		local LeftTitle = Instance.new("TextLabel", LeftPane)
		LeftTitle.Size = UDim2.new(1, 0, 0, 25)
		LeftTitle.BackgroundColor3 = Settings.Theme.Main2
		LeftTitle.BorderSizePixel = 0
		LeftTitle.Text = " Active Hooks"
		LeftTitle.TextColor3 = Settings.Theme.Text
		LeftTitle.Font = Enum.Font.SourceSansBold
		LeftTitle.TextSize = 14
		LeftTitle.TextXAlignment = Enum.TextXAlignment.Left

		LeftList = Instance.new("ScrollingFrame", LeftPane)
		LeftList.Size = UDim2.new(1, 0, 1, -25)
		LeftList.Position = UDim2.new(0, 0, 0, 25)
		LeftList.BackgroundTransparency = 1
		LeftList.BorderSizePixel = 0
		LeftList.ScrollBarThickness = 4

		local LeftLayout = Instance.new("UIListLayout", LeftList)
		LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
		LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			LeftList.CanvasSize = UDim2.new(0, 0, 0, LeftLayout.AbsoluteContentSize.Y)
		end)

		RightPane = Instance.new("Frame", Content)
		RightPane.Size = UDim2.new(0.65, 0, 1, -80)
		RightPane.Position = UDim2.new(0.35, 0, 0, 80)
		RightPane.BackgroundColor3 = Settings.Theme.Main1
		RightPane.BorderSizePixel = 0
		RightPane.Visible = false

		local RightTitle = Instance.new("TextLabel", RightPane)
		RightTitle.Size = UDim2.new(1, 0, 0, 25)
		RightTitle.BackgroundColor3 = Settings.Theme.Main2
		RightTitle.BorderSizePixel = 0
		RightTitle.Text = " Functions / Properties / Events"
		RightTitle.TextColor3 = Settings.Theme.Text
		RightTitle.Font = Enum.Font.SourceSansBold
		RightTitle.TextSize = 14
		RightTitle.TextXAlignment = Enum.TextXAlignment.Left

		RightList = Instance.new("ScrollingFrame", RightPane)
		RightList.Size = UDim2.new(1, 0, 1, -25)
		RightList.Position = UDim2.new(0, 0, 0, 25)
		RightList.BackgroundTransparency = 1
		RightList.BorderSizePixel = 0
		RightList.ScrollBarThickness = 6

		local RightLayout = Instance.new("UIListLayout", RightList)
		RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
		RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			RightList.CanvasSize = UDim2.new(0, 0, 0, RightLayout.AbsoluteContentSize.Y)
		end)

		FuncContextMenu = Lib.ContextMenu.new()
		FuncContextMenu.Iconless = true
		FuncContextMenu.Width = 150

		PropContextMenu = Lib.ContextMenu.new()
		PropContextMenu.Iconless = true
		PropContextMenu.Width = 150

		EventContextMenu = Lib.ContextMenu.new()
		EventContextMenu.Iconless = true
		EventContextMenu.Width = 200

		FuncContextMenu:Add({Name = "Hook Method", OnClick = function()
			local Mem = DebugExplorer.SelectedMember
			local TargetPath = Explorer.GetInstancePath(Mem.Target)
			local Template = string.format([[local Inst = %s
local compare = compareinstances or rawequal
local hookEnv = (getgenv and getgenv()) or _G
local hookCallable = hookEnv and hookEnv["hook" .. "function"]

local o; o = hookCallable(getrawmetatable(game).__namecall, newcclosure(function(self, ...)
    local method = getnamecallmethod()

    if not checkcaller() and compare(self, Inst) and method == '%s' then
        -- Your logic here
        -- return nil
    end

    return o(self, ...)
end))]], TargetPath, Mem.Name)
			HookCodeFrame:SetText(Template)
			HookWindow:SetTitle("Hooking Method: " .. Mem.Name)
			HookWindow:Show()
		end})

		PropContextMenu:Add({Name = "Hook Access", OnClick = function()
			local Mem = DebugExplorer.SelectedMember
			local TargetPath = Explorer.GetInstancePath(Mem.Target)
			local Template = string.format([[local Inst = %s
local compare = compareinstances or rawequal
local hookEnv = (getgenv and getgenv()) or _G
local hookCallable = hookEnv and hookEnv["hook" .. "function"]

local o; o = hookCallable(getrawmetatable(game).__index, newcclosure(function(...)
    local self, arg = ...

    if not checkcaller() and compare(self, Inst) and arg == '%s' then
        -- Your logic here
        -- return o(...)
    end

    return o(...)
end))]], TargetPath, Mem.Name)
			HookCodeFrame:SetText(Template)
			HookWindow:SetTitle("Hooking Property: " .. Mem.Name)
			HookWindow:Show()
		end})

		PropContextMenu:Add({Name = "Block Access", OnClick = function()
			local Mem = DebugExplorer.SelectedMember
			local TargetPath = Explorer.GetInstancePath(Mem.Target)
			local Code = string.format([[local Inst = %s
local compare = compareinstances or rawequal
local hookEnv = (getgenv and getgenv()) or _G
local hookCallable = hookEnv and hookEnv["hook" .. "function"]

local o; o = hookCallable(getrawmetatable(game).__index, newcclosure(function(...)
    local self, arg = ...

    if not checkcaller() and compare(self, Inst) and arg == '%s' then
        return nil
    end
    return o(...)
end))]], TargetPath, Mem.Name)
			ApplyInstantHook("Blocked", Code)
		end})

		PropContextMenu:Add({Name = "Spoof Value", OnClick = function()
			local Mem = DebugExplorer.SelectedMember
			ShowInputPrompt("Spoof Value Type (e.g. number, string, boolean, Color3)", "string", function(StrType)
				ShowInputPrompt("Spoofed Value", "Hello", function(StrVal)
					local ValCode = StrVal
					if StrType == "string" then ValCode = '"' .. StrVal .. '"'
					elseif StrType == "boolean" then ValCode = string.lower(StrVal)
					elseif StrType == "Color3" then ValCode = "Color3.new(" .. StrVal .. ")"
					elseif StrType == "CFrame" then ValCode = "CFrame.new(" .. StrVal .. ")"
					elseif StrType == "Vector3" then ValCode = "Vector3.new(" .. StrVal .. ")" end

					local TargetPath = Explorer.GetInstancePath(Mem.Target)
					local Code = string.format([[local Inst = %s
local compare = compareinstances or rawequal
local hookEnv = (getgenv and getgenv()) or _G
local hookCallable = hookEnv and hookEnv["hook" .. "function"]

local o; o = hookCallable(getrawmetatable(game).__index, newcclosure(function(...)
    local self, arg = ...

    if not checkcaller() and compare(self, Inst) and arg == '%s' then
        return %s
    end
    return o(...)
end))]], TargetPath, Mem.Name, ValCode)
					ApplyInstantHook("Spoofed: " .. tostring(ValCode), Code)
				end)
			end)
		end})

		EventContextMenu:Add({Name = "Fire All Connections", OnClick = function()
			local Mem = DebugExplorer.SelectedMember
			local S, Conns = pcall(env.getconnections, Mem.Target[Mem.Name])
			if S and type(Conns) == "table" then
				for _, C in pairs(Conns) do pcall(function() C:Fire() end) end
			end
		end})
		EventContextMenu:Add({Name = "Manage Connections", OnClick = function()
			local Mem = DebugExplorer.SelectedMember
			ConnWindow:SetTitle("Connections: " .. Mem.Name)
			DebugExplorer.RefreshConnections()
			ConnWindow:Show()
		end})

		LeftContextMenu = Lib.ContextMenu.new()
		LeftContextMenu.Iconless = true
		LeftContextMenu.Width = 150
		LeftContextMenu:Add({Name = "Modify", OnClick = function()
			local Hook = DebugExplorer.ActiveHooks[DebugExplorer.SelectedHookIndex]
			if Hook then
				HookCodeFrame:SetText(Hook.ScriptSource)
				HookWindow:SetTitle("Modifying Hook: " .. Hook.Name)
				HookWindow:Show()
			end
		end})
		LeftContextMenu:Add({Name = "Unhook", OnClick = function()
			local Idx = DebugExplorer.SelectedHookIndex
			local Hook = DebugExplorer.ActiveHooks[Idx]
			if not Hook then return end

			if env.restorefunction then
				if Hook.Type == "Function" then
					pcall(env.restorefunction, getrawmetatable(game).__namecall)
					pcall(env.restorefunction, Hook.Inst[Hook.Name])
				end
				if Hook.Type == "Property" then
					pcall(env.restorefunction, getrawmetatable(game).__index)
				end
			end

			table.remove(DebugExplorer.ActiveHooks, Idx)
			DebugExplorer.SelectedHookIndex = nil
			DebugExplorer.RefreshLeftPane()
		end})

		ConnContextMenu = Lib.ContextMenu.new()
		ConnContextMenu.Iconless = true
		ConnContextMenu.Width = 180
		ConnContextMenu:Add({Name = "Fire", OnClick = function()
			pcall(function() DebugExplorer.SelectedConnection:Fire() end)
		end})
		ConnContextMenu:Add({Name = "Toggle Enable/Disable", OnClick = function()
			local C = DebugExplorer.SelectedConnection
			if C.Enabled then pcall(function() C:Disable() end) else pcall(function() C:Enable() end) end
			DebugExplorer.RefreshConnections()
		end})
		ConnContextMenu:Add({Name = "Disconnect", OnClick = function()
			pcall(function() DebugExplorer.SelectedConnection:Disconnect() end)
			DebugExplorer.RefreshConnections()
		end})
		ConnContextMenu:Add({Name = "Toggle Block (.Function of conn)", OnClick = function()
			local C = DebugExplorer.SelectedConnection
			local Func = C.Function
			if not Func then return end

			local Hash = tostring(Func)
			if DebugExplorer.BlockedConnections[Hash] then
				if env.restorefunction then pcall(env.restorefunction, Func) end
				DebugExplorer.BlockedConnections[Hash] = nil
			else
				local hookCallable = env.GetHookFunction and env.GetHookFunction() or env.hookfunction
				if hookCallable then
					DebugExplorer.BlockedConnections[Hash] = true
					pcall(hookCallable, Func, function() end)
				end
			end
			DebugExplorer.RefreshConnections()
		end})

		HookWindow = Lib.Window.new()
		HookWindow:SetTitle("Hook Editor")
		HookWindow:Resize(500, 450)

		HookCodeFrame = Lib.CodeFrame.new()
		HookCodeFrame.Frame.Position = UDim2.new(0, 0, 0, 20)
		HookCodeFrame.Frame.Size = UDim2.new(1, 0, 1, -20)
		HookCodeFrame.Frame.Parent = HookWindow.GuiElems.Content
		HookCodeFrame.Editable = true

		local HookCopyBtn = Instance.new("TextButton", HookWindow.GuiElems.Content)
		HookCopyBtn.Size = UDim2.new(0.5, 0, 0, 20)
		HookCopyBtn.Position = UDim2.new(0, 0, 0, 0)
		HookCopyBtn.BackgroundColor3 = Settings.Theme.Main2
		HookCopyBtn.BorderSizePixel = 0
		HookCopyBtn.Text = "Copy to Clipboard"
		HookCopyBtn.TextColor3 = Color3.new(1, 1, 1)

		HookCopyBtn.MouseButton1Click:Connect(function()
			if env.setclipboard then env.setclipboard(HookCodeFrame:GetText()) end
		end)

		local HookExecuteBtn = Instance.new("TextButton", HookWindow.GuiElems.Content)
		HookExecuteBtn.Size = UDim2.new(0.5, 0, 0, 20)
		HookExecuteBtn.Position = UDim2.new(0.5, 0, 0, 0)
		HookExecuteBtn.BackgroundColor3 = Settings.Theme.Button
		HookExecuteBtn.BorderSizePixel = 0
		HookExecuteBtn.Text = "Execute & Save Hook"
		HookExecuteBtn.TextColor3 = Color3.new(1, 1, 1)

		HookExecuteBtn.MouseButton1Click:Connect(function()
			local Source = HookCodeFrame:GetText()
			if env.loadstring then
				if DebugExplorer.SelectedHookIndex then
					local Hook = DebugExplorer.ActiveHooks[DebugExplorer.SelectedHookIndex]
					if env.restorefunction then
						if Hook.Type == "Function" then pcall(env.restorefunction, getrawmetatable(game).__namecall) end
						if Hook.Type == "Property" then pcall(env.restorefunction, getrawmetatable(game).__index) end
					end
					table.remove(DebugExplorer.ActiveHooks, DebugExplorer.SelectedHookIndex)
					DebugExplorer.SelectedHookIndex = nil
				end

				env.loadstring(Source, "DEX")()

				if DebugExplorer.SelectedMember then
					table.insert(DebugExplorer.ActiveHooks, {
						Inst = DebugExplorer.SelectedMember.Target,
						Type = DebugExplorer.SelectedMember.Type,
						Name = DebugExplorer.SelectedMember.Name,
						Action = "Custom Hook",
						ScriptSource = Source
					})
					DebugExplorer.RefreshLeftPane()
				end
				HookWindow:Close()
			end
		end)

		ConnWindow = Lib.Window.new()
		ConnWindow:SetTitle("Connections")
		ConnWindow:Resize(450, 300)

		ConnList = Instance.new("ScrollingFrame", ConnWindow.GuiElems.Content)
		ConnList.Size = UDim2.new(1, 0, 1, 0)
		ConnList.BackgroundTransparency = 1
		ConnList.BorderSizePixel = 0
		ConnList.ScrollBarThickness = 6

		local ConnLayout = Instance.new("UIListLayout", ConnList)
		ConnLayout.SortOrder = Enum.SortOrder.LayoutOrder
		ConnLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ConnList.CanvasSize = UDim2.new(0, 0, 0, ConnLayout.AbsoluteContentSize.Y)
		end)

		SpoofWindow = Lib.Window.new()
		SpoofWindow.Alignable = false
		SpoofWindow.Resizable = false
		SpoofWindow:SetTitle("Spoof Value")
		SpoofWindow:SetSize(300, 130)

		local TypeLbl = Lib.Label.new()
		TypeLbl.Text = "Type:"
		TypeLbl.Position = UDim2.new(0, 10, 0, 10)
		TypeLbl.Size = UDim2.new(0, 50, 0, 20)
		SpoofWindow:Add(TypeLbl)

		SpoofDrop = Lib.DropDown.new()
		SpoofDrop.CanBeEmpty = false
		SpoofDrop.Size = UDim2.new(0, 210, 0, 20)
		SpoofDrop.Position = UDim2.new(0, 70, 0, 10)
		SpoofDrop:SetOptions({"string", "number", "boolean", "Color3", "CFrame", "Vector3"})
		SpoofDrop:SetSelected("string")
		SpoofWindow:Add(SpoofDrop, "TypeDrop")

		local ValLbl = Lib.Label.new()
		ValLbl.Text = "Value:"
		ValLbl.Position = UDim2.new(0, 10, 0, 40)
		ValLbl.Size = UDim2.new(0, 50, 0, 20)
		SpoofWindow:Add(ValLbl)

		SpoofBox = Lib.ViewportTextBox.new()
		SpoofBox.Position = UDim2.new(0, 70, 0, 40)
		SpoofBox.Size = UDim2.new(0, 210, 0, 20)
		SpoofWindow:Add(SpoofBox, "ValBox")

		local ConfirmSpoofBtn = Lib.Button.new()
		ConfirmSpoofBtn.Text = "Confirm Spoof"
		ConfirmSpoofBtn.Position = UDim2.new(0, 5, 1, -25)
		ConfirmSpoofBtn.Size = UDim2.new(1, -10, 0, 20)
		ConfirmSpoofBtn.OnClick:Connect(function()
			local StrType = SpoofDrop.Selected
			local StrVal = SpoofBox:GetText()
			local ValCode = StrVal
			if StrType == "string" then ValCode = '"' .. StrVal .. '"'
			elseif StrType == "boolean" then ValCode = string.lower(StrVal)
			elseif StrType == "Color3" then ValCode = "Color3.new(" .. StrVal .. ")"
			elseif StrType == "CFrame" then ValCode = "CFrame.new(" .. StrVal .. ")"
			elseif StrType == "Vector3" then ValCode = "Vector3.new(" .. StrVal .. ")" end

			local Mem = DebugExplorer.SelectedMember
			local TargetPath = Explorer.GetInstancePath(Mem.Target)
			local Code = string.format([[local Inst = %s
local compare = compareinstances or rawequal
local hookEnv = (getgenv and getgenv()) or _G
local hookCallable = hookEnv and hookEnv["hook" .. "function"]

local o; o = hookCallable(getrawmetatable(game).__index, newcclosure(function(...)
    local self, arg = ...

    if not checkcaller() and compare(self, Inst) and arg == '%s' then
        return %s
    end
    return o(...)
end))]], TargetPath, Mem.Name, ValCode)

			ApplyInstantHook("Spoofed: " .. tostring(ValCode), Code)
			SpoofWindow:Close()
		end)
		SpoofWindow:Add(ConfirmSpoofBtn)

		Explorer.Selection.Changed:Connect(function()
			local Selected = Explorer.Selection.List[1]
			if Selected then
				DebugExplorer.CurrentInstance = Selected.Obj
			else
				DebugExplorer.CurrentInstance = nil
			end

			if Window:IsVisible() then
				DebugExplorer.Refresh()
			end
		end)

		Window.OnActivate:Connect(function()
			DebugExplorer.Refresh()
		end)
	end

	return DebugExplorer
end
return {InitDeps = InitDeps, InitAfterMain = InitAfterMain, Main = MainFunc}
