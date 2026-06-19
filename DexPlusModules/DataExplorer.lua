--[[
	Data Explorer App Module
]]
local Main, Lib, Apps, Settings
local Explorer, Properties, ScriptViewer, EnvExplorer, DataExplorer, DebugExplorer
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
	DataExplorer = Apps.DataExplorer
	DebugExplorer = Apps.DebugExplorer
end

local function SafeGetScriptFromClosure(Fn)
	local Ok, Env = pcall(env.getsenv or getsenv, Fn)
	if not Ok or type(Env) ~= "table" then return nil end

	local Script = rawget(Env, "script")
	if typeof(Script) == "Instance" and Script:IsA("LuaSourceContainer") then
		return Script
	end
	return nil
end

local function MainFunc()
	local DataExplorer = {}
	local Window, ListFrame, SearchBox, FilterBtn
	local FuncContextMenu, TableContextMenu, ValueContextMenu

	DataExplorer.Filters = {
		Constants = true,
		Upvalues = true,
		Protos = true,
		Functions = true,
		Tables = true,
		Globals = false
	}
	DataExplorer.MaxDepth = 3
	DataExplorer.CurrentResults = {}
	DataExplorer.SelectedResult = nil
	DataExplorer.SelectedMatch = nil

	local DetailWindow, DetailCodeFrame
	local BlockedFuncs = {}

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

	local function GetHash(Func)
		if env.getfunctionhash then return env.getfunctionhash(Func) end
		return tostring(Func):match("0x%w+") or "No Hash"
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
		InfoStr = InfoStr .. "Type: " .. (IsCClosure and "C Closure" or "Lua Closure") .. "\n\n"

		if not IsCClosure then
			local _, Constants = pcall(env.getconstants, Func)
			InfoStr = InfoStr .. "Constants (" .. (Constants and #Constants or 0) .. "):\n"
			if Constants then
				for i, v in pairs(Constants) do
					InfoStr = InfoStr .. "   [" .. i .. "] = " .. typeof(v) .. " : " .. tostring(v) .. "\n"
				end
			end

			local _, Upvalues = pcall(env.getupvalues, Func)
			InfoStr = InfoStr .. "\nUpvalues (" .. (Upvalues and #Upvalues or 0) .. "):\n"
			if Upvalues then
				for i, v in pairs(Upvalues) do
					InfoStr = InfoStr .. "   [" .. i .. "] = " .. typeof(v) .. " : " .. tostring(v) .. "\n"
				end
			end

			local _, Protos = pcall(env.getprotos, Func)
			InfoStr = InfoStr .. "\nProtos (" .. (Protos and #Protos or 0) .. "):\n"
			if Protos then
				for i, v in pairs(Protos) do
					local PName = (pcall(debug.info, v, "n") and debug.info(v, "n")) or "Anonymous"
					InfoStr = InfoStr .. "   [" .. i .. "] " .. (PName == "" and "Anonymous" or PName) .. " - " .. GetHash(v) .. "\n"
				end
			end
		end

		DetailWindow:SetTitle("Details: " .. Name)
		DetailCodeFrame:SetText(InfoStr)
		DetailWindow:Show()
	end

local function ViewTableDetail(Tab, Name)
		local TableSerializer = {}
		do
			local function IsIdentifier(str)
				if type(str) ~= "string" or #str == 0 then return false end
				if str:match("^[%a_][%w_]*$") == nil then return false end
				local Reserved = {
					["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
					["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
					["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true,
					["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
					["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
					["while"] = true, ["continue"] = true
				}
				return not Reserved[str]
			end

			local ESCAPES = { [34] = '\\"', [92] = "\\\\", [7] = "\\a", [8] = "\\b", [9] = "\\t", [10] = "\\n", [11] = "\\v", [12] = "\\f", [13] = "\\r" }
			local function EscapeString(str)
				local n = #str
				local out = table.create(n + 2)
				out[1] = '"'
				local len = 1
				for i = 1, n do
					local b = string.byte(str, i)
					local esc = ESCAPES[b]
					if esc then
						len = len + 1
						out[len] = esc
					else
						if b >= 32 and b <= 126 then
							len = len + 1
							out[len] = string.sub(str, i, i)
						else
							len = len + 1
							out[len] = string.format("\\%03d", b)
						end
					end
				end
				out[len + 1] = '"'
				return table.concat(out)
			end

			local function FormatNumber(n)
				if n ~= n then return "0/0" end
				if n == math.huge then return "math.huge" end
				if n == -math.huge then return "-math.huge" end
				if n == math.floor(n) and math.abs(n) < 1000000000000000 then
					return string.format("%d", n)
				end
				return string.format("%.14g", n)
			end

			local function IsPureArray(t)
				local count = 0
				local k = next(t)
				while true do
					if k ~= nil then
						count = count + 1
						k = next(t, k)
					else
						break
					end
				end
				local len = rawlen(t)
				if count ~= len then return false, len end
				for i = 1, len do
					if rawget(t, i) == nil then return false, len end
				end
				return true, len
			end

			local function GetInstancePath(instance)
				local ok, path = pcall(function() return Explorer.GetInstancePath(instance) end)
				return ok and path or '"<instance>"'
			end

			local SCALAR_HANDLERS = {
				["string"] = function(v) return EscapeString(v) end,
				["number"] = function(v) return FormatNumber(v) end,
				["boolean"] = function(v) return v and "true" or "false" end,
				["Instance"] = function(v) return GetInstancePath(v) end,
				["EnumItem"] = function(v) return "Enum." .. tostring(v.EnumType) .. "." .. v.Name end,
				["Enum"] = function(v) return "Enum." .. tostring(v) end,
				["Vector3"] = function(v) return string.format("Vector3.new(%s, %s, %s)", FormatNumber(v.X), FormatNumber(v.Y), FormatNumber(v.Z)) end,
				["Vector2"] = function(v) return string.format("Vector2.new(%s, %s)", FormatNumber(v.X), FormatNumber(v.Y)) end,
				["Color3"] = function(v) return string.format("Color3.fromRGB(%d, %d, %d)", math.round(v.R * 255), math.round(v.G * 255), math.round(v.B * 255)) end,
				["CFrame"] = function(v)
					local comps = { v:GetComponents() }
					for i = 1, #comps do comps[i] = FormatNumber(comps[i]) end
					return string.format("CFrame.new(%s)", table.concat(comps, ", "))
				end,
				["UDim2"] = function(v) return string.format("UDim2.new(%s, %s, %s, %s)", FormatNumber(v.X.Scale), FormatNumber(v.X.Offset), FormatNumber(v.Y.Scale), FormatNumber(v.Y.Offset)) end,
				["UDim"] = function(v) return string.format("UDim.new(%s, %s)", FormatNumber(v.Scale), FormatNumber(v.Offset)) end,
				["BrickColor"] = function(v) return string.format("BrickColor.new(%s)", EscapeString(v.Name)) end,
				["function"] = function() return '"<function>"' end,
				["thread"] = function() return '"<thread>"' end,
				["RBXScriptConnection"] = function() return '"<RBXScriptConnection>"' end,
				["RBXScriptSignal"] = function() return '"<RBXScriptSignal>"' end
			}

			local function SerializeScalar(value)
				if value == nil then return "nil" end
				local vt = typeof(value)
				local handler = SCALAR_HANDLERS[vt]
				return handler and handler(value) or '"<' .. vt .. '>"'
			end

			local function BuildEntries(t)
				local entries = {}
				local ecount = 0
				local pure, arrayLen = IsPureArray(t)
				if pure then
					for idx = 1, arrayLen do
						ecount = ecount + 1
						entries[ecount] = { keyStr = nil, value = rawget(t, idx) }
					end
					return entries
				end

				local seen = {}
				for idx = 1, arrayLen do
					if rawget(t, idx) == nil then break end
					seen[idx] = true
					ecount = ecount + 1
					entries[ecount] = { keyStr = nil, value = rawget(t, idx) }
				end

				local keyed = {}
				local kcount = 0
				local key = next(t)
				while true do
					if key ~= nil then
						if not seen[key] then
							kcount = kcount + 1
							keyed[kcount] = key
						end
						key = next(t, key)
					else
						break
					end
				end

				pcall(function()
					table.sort(keyed, function(a, b)
						local ta, tb = typeof(a), typeof(b)
						if ta == "string" and tb == "string" then return a < b end
						return tostring(ta) < tostring(tb)
					end)
				end)

				for i = 1, kcount do
					local k = keyed[i]
					local keyStr = (type(k) == "string" and IsIdentifier(k)) and k or ("[" .. SerializeScalar(k) .. "]")
					ecount = ecount + 1
					entries[ecount] = { keyStr = keyStr, value = rawget(t, k) }
				end
				return entries
			end

			function TableSerializer.Serialize(root, maxDepth, pretty)
				local function Normalize(v)
					if type(v) == "function" then
						local ok, source, line, name, numparams, isvararg = pcall(debug.info, v, "slna")
						if ok then
							return {
								["__Type"] = "function",
								["Name"] = (name and name ~= "") and name or "(anonymous)",
								["Source"] = source,
								["Line"] = line,
								["NumParams"] = numparams,
								["IsVararg"] = isvararg
							}
						end
						return "<function>"
					end
					return v
				end

				root = Normalize(root)

				if typeof(root) ~= "table" then return SerializeScalar(root) end
				local out = {}
				local len = 0
				local visited = {}
				local function emit(s) len = len + 1 out[len] = s end
				local sep = pretty and "," or ", "

				visited[root] = true
				local stack = { { entries = BuildEntries(root), i = 1, indent = 0, tableRef = root, sep = "" } }
				local depth = 1
				emit("{")

				while true do
					if depth > 0 then
						local frame = stack[depth]
						local entries = frame.entries
						local fi = frame.i
						if fi > #entries then
							if pretty and #entries > 0 then
								emit("\n" .. string.rep("   ", frame.indent))
							end
							emit("}")
							emit(frame.sep)
							stack[depth] = nil
							depth = depth - 1
							continue
						end
						local entry = entries[fi]
						frame.i = fi + 1

						local rawValue = Normalize(entry.value)
						local nextIndent = frame.indent + 1

						if pretty then
							emit(entry.keyStr and ("\n" .. string.rep("   ", nextIndent) .. entry.keyStr .. " = ") or ("\n" .. string.rep("   ", nextIndent)))
						elseif entry.keyStr then
							emit(entry.keyStr .. " = ")
						end

						if typeof(rawValue) == "table" then
							if nextIndent > maxDepth then
								emit("{ ... }")
								emit(sep)
							elseif visited[rawValue] then
								emit('"<cyclic table>"')
								emit(sep)
							else
								visited[rawValue] = true
								emit("{")
								depth = depth + 1
								stack[depth] = { entries = BuildEntries(rawValue), i = 1, indent = nextIndent, tableRef = rawValue, sep = sep }
							end
						else
							emit(SerializeScalar(rawValue))
							emit(sep)
						end
					else
						break
					end
				end
				return table.concat(out)
			end
		end

		local Success, Content = pcall(function() return TableSerializer.Serialize(Tab, DataExplorer.MaxDepth, true) end)
		DetailWindow:SetTitle("Details: " .. Name)
		DetailCodeFrame:SetText(Success and Content or ("Error reading table: " .. tostring(Content)))
		DetailWindow:Show()
	end

	local function RenderResults()
		for _, Child in pairs(ListFrame:GetChildren()) do
			if not Child:IsA("UIListLayout") and not Child:IsA("UIPadding") then
				Child:Destroy()
			end
		end

		local function SetupLongPress(btn, callback)
			btn.MouseButton2Click:Connect(callback)
			local holding = false
			local pressPos = nil
			btn.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					holding = true
					pressPos = input.Position
					task.delay(0.5, function()
						if holding then
							holding = false
							callback()
						end
					end)
				end
			end)
			btn.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					holding = false
				end
			end)
			btn.InputChanged:Connect(function(input)
				if holding and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
					if pressPos and (input.Position - pressPos).Magnitude > 10 then
						holding = false
					end
				end
			end)
		end

		for _, Result in pairs(DataExplorer.CurrentResults) do
			local MainBox = Instance.new("Frame")
			MainBox.BackgroundColor3 = Settings.Theme.Main1
			MainBox.BorderSizePixel = 0
			MainBox.Size = UDim2.new(1, 0, 0, 0)
			MainBox.AutomaticSize = Enum.AutomaticSize.Y
			MainBox.Parent = ListFrame

			local MainLayout = Instance.new("UIListLayout", MainBox)
			MainLayout.SortOrder = Enum.SortOrder.LayoutOrder
			MainLayout.Padding = UDim.new(0, 2)

			local HeaderBtn = Instance.new("TextButton", MainBox)
			HeaderBtn.Size = UDim2.new(1, 0, 0, 25)
			HeaderBtn.BackgroundColor3 = Settings.Theme.Main2
			HeaderBtn.BorderSizePixel = 0
			HeaderBtn.Text = "  " .. tostring(Result.Name) .. " [" .. Result.Type .. "]"
			HeaderBtn.TextColor3 = Settings.Theme.Text
			HeaderBtn.Font = Enum.Font.SourceSansBold
			HeaderBtn.TextSize = 14
			HeaderBtn.TextXAlignment = Enum.TextXAlignment.Left
			HeaderBtn.AutoButtonColor = false

			HeaderBtn.MouseButton1Click:Connect(function()
				if Result.Type == "Function" then
					ViewFunctionDetail(Result.Ref, Result.Name, GetHash(Result.Ref))
				else
					ViewTableDetail(Result.Ref, Result.Name)
				end
			end)

			SetupLongPress(HeaderBtn, function()
				DataExplorer.SelectedResult = Result
				if Result.Type == "Function" then
					FuncContextMenu.Items[4].Name = BlockedFuncs[Result.Ref] and "Unblock" or "Block"
					FuncContextMenu:Refresh()
					FuncContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
				else
					TableContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
				end
			end)

local MatchesContainer = Instance.new("Frame", MainBox)
            MatchesContainer.BackgroundTransparency = 1
            MatchesContainer.Size = UDim2.new(1.0355, -20, 0, 0)
            MatchesContainer.Position = UDim2.new(0, 20, 0, 0)
            MatchesContainer.AutomaticSize = Enum.AutomaticSize.Y

            local jj = Instance.new("UIPadding", MatchesContainer)
            jj.PaddingLeft = UDim.new(0, 2)

			local MatchLayout = Instance.new("UIListLayout", MatchesContainer)
			MatchLayout.SortOrder = Enum.SortOrder.LayoutOrder
			MatchLayout.Padding = UDim.new(0, 2)

			for _, Match in pairs(Result.Matches) do
				local MatchBtn = Instance.new("TextButton", MatchesContainer)
				MatchBtn.Size = UDim2.new(1, 0, 0, 22)
				MatchBtn.BackgroundColor3 = Settings.Theme.Button
				MatchBtn.BorderSizePixel = 0
				MatchBtn.TextColor3 = Settings.Theme.Text
				MatchBtn.Font = Enum.Font.SourceSans
				MatchBtn.TextSize = 13
				MatchBtn.TextXAlignment = Enum.TextXAlignment.Left
				MatchBtn.AutoButtonColor = false
				MatchBtn.TextTruncate = Enum.TextTruncate.AtEnd
				MatchBtn.ClipsDescendants = true

				local DisplayVal = tostring(Match.Value)
				if #DisplayVal > 10000 then
					DisplayVal = string.sub(DisplayVal, 1, 10000) .. "..."
				end
				DisplayVal = string.gsub(DisplayVal, "[\n\r]", "\\n")

				local DisplayName = Match.ValueName and ("[" .. tostring(Match.ValueName) .. "] ") or ""
				pcall(function()
					MatchBtn.Text = "    " .. DisplayVal .. " " .. DisplayName .. "(" .. Match.ValueType .. ") - " .. Match.LocationType .. " " .. tostring(Match.Index)
				end)

				MatchBtn.MouseEnter:Connect(function() MatchBtn.BackgroundColor3 = Settings.Theme.ButtonHover end)
				MatchBtn.MouseLeave:Connect(function() MatchBtn.BackgroundColor3 = Settings.Theme.Button end)

				MatchBtn.MouseButton1Click:Connect(function()
					if Match.ValueType == "function" then
						ViewFunctionDetail(Match.Value, Match.ValueName or "Match", GetHash(Match.Value))
					elseif Match.ValueType == "table" then
						ViewTableDetail(Match.Value, Match.ValueName or "Match")
					elseif Match.ValueType == "number" or Match.ValueType == "string" or Match.ValueType == "boolean" or Match.ValueType == "CFrame" or Match.ValueType == "Vector3" then
						if Result.Type == "Function" then
							ViewFunctionDetail(Result.Ref, Result.Name, GetHash(Result.Ref))
						else
							ViewTableDetail(Result.Ref, Result.Name)
						end
					else
						DetailWindow:SetTitle("Notice")
						DetailCodeFrame:SetText("-- Unsupported Type for Detailed View: " .. Match.ValueType .. "\n-- Please view the parent container instead.")
						DetailWindow:Show()
					end
				end)

				SetupLongPress(MatchBtn, function()
					DataExplorer.SelectedResult = Result
					DataExplorer.SelectedMatch = Match
					ValueContextMenu:Show(Main.Mouse.X, Main.Mouse.Y)
				end)
			end

			local Pad = Instance.new("Frame", MainBox)
			Pad.BackgroundTransparency = 1
			Pad.Size = UDim2.new(1, 0, 0, 2)
		end
	end

	local CurrentRefreshId = 0
	DataExplorer.Refresh = function()
		local QueryStr = SearchBox.TextBox.Text
		local QueryNum = tonumber(QueryStr)
		local F = DataExplorer.Filters

		CurrentRefreshId = CurrentRefreshId + 1
		local ThisRefreshId = CurrentRefreshId

		DataExplorer.CurrentResults = {}

		for _, Child in pairs(ListFrame:GetChildren()) do
			if not Child:IsA("UIListLayout") and not Child:IsA("UIPadding") then
				Child:Destroy()
			end
		end

		local function CompareValue(Val)
			local ValType = typeof(Val)
			if ValType == "string" then
				return string.find(string.lower(Val), string.lower(QueryStr), 1, true) ~= nil
			elseif ValType == "number" and QueryNum then
				return Val == QueryNum
			elseif ValType == "boolean" then
				return tostring(Val) == string.lower(QueryStr)
			end
			return false
		end

		local function ScanTable(Tbl, Depth, Seen, Matches, IgnoreSearch)
			if Depth > DataExplorer.MaxDepth then return end
			if Seen[Tbl] then return end
			Seen[Tbl] = true

			-- if Depth == 1 then task.wait() end

			for k, v in pairs(Tbl) do
				if ThisRefreshId ~= CurrentRefreshId then return end

				if IgnoreSearch or CompareValue(v) or CompareValue(k) then
					table.insert(Matches, {
						LocationType = "Table Index", Index = tostring(k), ValueName = tostring(k), Value = v, ValueType = typeof(v)
					})
				end

				if type(v) == "table" then
					ScanTable(v, Depth + 1, Seen, Matches, IgnoreSearch)
				end
			end
		end

		task.spawn(function()
			if F.Globals then
				local Renv = env.getrenv and env.getrenv() or _G
				local GlobalSources = {
					{Name = "_G", Ref = Renv._G or _G},
					{Name = "shared", Ref = Renv.shared or shared}
				}

				for _, Source in pairs(GlobalSources) do
					if type(Source.Ref) == "table" then
						local PrimitiveMatches = {}

						for k, v in pairs(Source.Ref) do
							if ThisRefreshId ~= CurrentRefreshId then return end

							local vType = type(v)
							if vType == "function" then
								table.insert(DataExplorer.CurrentResults, {
									Type = "Function",
									Name = Source.Name .. "." .. tostring(k),
									Ref = v,
									Script = nil,
									Matches = {}
								})
							elseif vType == "table" then
								local TblMatches = {}
								ScanTable(v, 1, {}, TblMatches, true)
								table.insert(DataExplorer.CurrentResults, {
									Type = "Table",
									Name = Source.Name .. "." .. tostring(k),
									Ref = v,
									Script = nil,
									Matches = TblMatches
								})
							else
								table.insert(PrimitiveMatches, {
									LocationType = "Table Index",
									Index = tostring(k),
									ValueName = tostring(k),
									Value = v,
									ValueType = typeof(v)
								})
							end
						end

						if #PrimitiveMatches > 0 then
							table.insert(DataExplorer.CurrentResults, {
								Type = "Table",
								Name = Source.Name .. " (Primitives)",
								Ref = Source.Ref,
								Script = nil,
								Matches = PrimitiveMatches
							})
						end
					end
				end
			else
				if QueryStr == "" then return end

				local Gc = env.getgc and env.getgc(true) or {}
				local SeenTables = {}

				local SkipTables = {
					[Main] = true, [Lib] = true, [Apps] = true, [Settings] = true,
					[Explorer] = true, [Properties] = true, [ScriptViewer] = true, [DataExplorer] = true,
					[_G] = true, [shared] = true
				}
				if env.getgenv then pcall(function() SkipTables[env.getgenv()] = true end) end
				if env.getrenv then pcall(function() SkipTables[env.getrenv()] = true end) end

				local function ISDexTable(t)
					if SkipTables[t] then return true end
					local s, res = pcall(function()
						if rawget(t, "InsertObjectContext") or rawget(t, "GuiElems") or rawget(t, "InitAfterMain") or rawget(t, "AppControls") then return true end
						return false
					end)
					return s and res
				end

				for Iter, Obj in pairs(Gc) do
					if Iter % 900000 == 0 then task.wait() end
					if ThisRefreshId ~= CurrentRefreshId then return end

					local ObjType = type(Obj)
					if ObjType == "table" and ISDexTable(Obj) then continue end
					if ObjType == "function" then
						local Matches = {}
						local HasMatch = false
						local IsCClos = env.iscclosure and env.iscclosure(Obj)
						local isour = env.isourclosure and env.isourclosure(Obj)

						if F.Functions then
							local S, NInfo = pcall(debug.info, Obj, "n")
							if S and NInfo and NInfo ~= "" and CompareValue(NInfo) then
								HasMatch = true
								table.insert(Matches, {LocationType = "Function Name", Index = 0, ValueName = "Name", Value = NInfo, ValueType = "string"})
							end
						end

						if F.Constants and env.getconstants and not IsCClos and not isour then
							local S, Consts = pcall(env.getconstants, Obj)
							if S and Consts then
								for Idx, Val in pairs(Consts) do
									if CompareValue(Val) then
										HasMatch = true
										table.insert(Matches, {LocationType = "Constant", Index = Idx, ValueName = "Const_" .. Idx, Value = Val, ValueType = typeof(Val)})
									end
								end
							end
						end

						if F.Upvalues and env.getupvalues and not IsCClos and not isour then
							local S, Upvals = pcall(env.getupvalues, Obj)
							if S and Upvals then
								for Idx, Val in pairs(Upvals) do
									if CompareValue(Val) then
										HasMatch = true
										table.insert(Matches, {LocationType = "Upvalue", Index = Idx, ValueName = "Upv_" .. Idx, Value = Val, ValueType = typeof(Val)})
									end
									if F.Tables and type(Val) == "table" then
										local TblMatches = {}
										ScanTable(Val, 1, SeenTables, TblMatches, false)
										for _, TM in pairs(TblMatches) do
											HasMatch = true
											table.insert(Matches, {
												LocationType = "Upvalue Table ["..Idx.."] -> " .. TM.LocationType,
												Index = TM.Index,
												ValueName = TM.ValueName,
												Value = TM.Value,
												ValueType = TM.ValueType,
												RootIndex = Idx,
												TableRef = Val
											})
										end
									end
								end
							end
						end

						if F.Protos and env.getprotos and not IsCClos and not isour then
							local S, Protos = pcall(env.getprotos, Obj)
							if S and Protos then
								for Idx, Proto in pairs(Protos) do
									local S2, PName = pcall(debug.info, Proto, "n")
									if S2 and PName and PName ~= "" and CompareValue(PName) then
										HasMatch = true
										table.insert(Matches, {LocationType = "Proto", Index = Idx, ValueName = "Proto_" .. Idx, Value = PName, ValueType = "function"})
									end
								end
							end
						end

						if HasMatch then
							local S_scr, Scr = pcall(SafeGetScriptFromClosure, Obj)
							local S_n, N = pcall(debug.info, Obj, "n")
							table.insert(DataExplorer.CurrentResults, {Type = "Function", Name = ((S_n and N ~= "") and N or "Anonymous"), Ref = Obj, Script = S_scr and Scr or nil, Matches = Matches})
						end

					elseif ObjType == "table" and F.Tables then
						local Matches = {}
						ScanTable(Obj, 1, SeenTables, Matches, false)
						if #Matches > 0 then
							table.insert(DataExplorer.CurrentResults, {Type = "Table", Name = tostring(Obj), Ref = Obj, Script = nil, Matches = Matches})
						end
					end
				end
			end

			if ThisRefreshId == CurrentRefreshId then
				RenderResults()
			end
		end)
	end

	DataExplorer.Init = function()
		Window = Lib.Window.new()
		Window:SetTitle("Data Explorer")
		Window:Resize(500, 450)
		DataExplorer.Window = Window

		FuncContextMenu = Lib.ContextMenu.new()
		FuncContextMenu.Iconless = true
		FuncContextMenu.Width = 200

		TableContextMenu = Lib.ContextMenu.new()
		TableContextMenu.Iconless = true
		TableContextMenu.Width = 200

		ValueContextMenu = Lib.ContextMenu.new()
		ValueContextMenu.Iconless = true
		ValueContextMenu.Width = 200

		FuncContextMenu:Add({Name = "Copy Function as Script", OnClick = function()
			if not env.setclipboard then return end
			local Target = DataExplorer.SelectedResult.Ref
			local Template = [[local function findfunc(str)
    for i,v in next, getgc() do
        if type(v) == 'function' then
            if tostring(v):find(str) then
                return v
            end
        end
    end
end

local func = findfunc("]] .. tostring(Target) .. [[")]]
			env.setclipboard(Template)
		end})

		FuncContextMenu:Add({Name = "Copy Function Hash", OnClick = function()
			if env.setclipboard then env.setclipboard(GetHash(DataExplorer.SelectedResult.Ref)) end
		end})

		local function GetScriptFromFunction(func)
			if type(func) ~= "function" then return nil end

			local ok, env = pcall(getfenv, func)
			if ok and type(env) == "table" then
				local s = rawget(env, "script")
				if typeof(s) == "Instance" and s:IsA("LuaSourceContainer") then
					return s
				end

				local foundScript = nil
				pcall(function()
					local count = 0
					for k, v in next, env do
						if typeof(v) == "Instance" and v:IsA("LuaSourceContainer") then
							foundScript = v
							break
						end
						count = count + 1
						if count >= 64 then break end
					end
				end)
				if foundScript then return foundScript end
			end

			local ok2, source = pcall(debug.info, func, "s")
			if ok2 and type(source) == "string" and source ~= "" then
				local cleanSource = source:gsub("^[=@]", "")
				if nodes then
					for inst, _ in next, env.getscripts() do
						if typeof(inst) == "Instance" and inst:IsA("LuaSourceContainer") then
							local sName = inst.Name
							if sName ~= "" and string.find(cleanSource, sName, 1, true) then
								return inst
							end
						end
					end
				end
			end

			return nil
		end

		FuncContextMenu:Add({Name = "View Script", OnClick = function()
			local Scr = DataExplorer.SelectedResult.Script or GetScriptFromFunction(DataExplorer.SelectedResult.Ref)
			if Scr then
				ScriptViewer.ViewScript(Scr)
			else
				DetailWindow:SetTitle("Notice")
				DetailCodeFrame:SetText("-- couldnt find any")
				DetailWindow:Show()
			end
		end})

		FuncContextMenu:Add({Name = "Block", OnClick = function()
			local Target = DataExplorer.SelectedResult.Ref
			if BlockedFuncs[Target] then
				if env.restorefunction then env.restorefunction(Target) end
				BlockedFuncs[Target] = nil
			else
				if env.hookfunction then
					BlockedFuncs[Target] = true
					env.hookfunction(Target, function() end)
				end
			end
		end})

		TableContextMenu:Add({Name = "Copy Table as Script", OnClick = function()
			if not env.setclipboard then return end
			local Target = DataExplorer.SelectedResult.Ref
			local Template = [[local function findtable()
    for i,v in next, getgc() do
        if type(v) == 'table' and tostring(v) == ']] .. tostring(Target) .. [[' then
            return v
        end
    end
end

local tbl = findtable()]]
			env.setclipboard(Template)
		end})

		ValueContextMenu:Add({Name = "Modify Value", OnClick = function()
			local Match = DataExplorer.SelectedMatch
			local Result = DataExplorer.SelectedResult

			ShowInputPrompt("New Value (" .. Match.ValueType .. ")", Match.Value, function(StrVal)
				local NewVal = StrVal
				if Match.ValueType == "number" then NewVal = tonumber(StrVal)
				elseif Match.ValueType == "boolean" then NewVal = (StrVal:lower() == "true")
				elseif Match.ValueType == "Color3" then
				    local s, c = pcall(loadstring, "return Color3.new("..StrVal..")")
				    if s and c then NewVal = c() end
				end

				if Match.LocationType == "Constant" then
					if env.setconstant then pcall(env.setconstant, Result.Ref, tonumber(Match.Index), NewVal) end
				elseif Match.LocationType == "Upvalue" then
					if env.setupvalue then pcall(env.setupvalue, Result.Ref, tonumber(Match.Index), NewVal) end
				elseif string.find(Match.LocationType, "Upvalue Table") or Match.LocationType == "Table Index" then
					local Idx = Match.Index
					if tonumber(Idx) then Idx = tonumber(Idx) end
					if env.getgc then
						local Gc = env.getgc(true)
						for _, v in pairs(Gc) do
							if type(v) == "table" and rawget(v, Idx) ~= nil then
								pcall(rawset, v, Idx, NewVal)
							end
						end
					else
						local TargetTbl = Match.TableRef or Result.Ref
						if type(TargetTbl) == "table" then
							pcall(rawset, TargetTbl, Idx, NewVal)
						end
					end
				end
				DataExplorer.Refresh()
			end)
		end})

		ValueContextMenu:Add({Name = "Generate Script", OnClick = function()
			if not env.setclipboard then return end
			local Match = DataExplorer.SelectedMatch
			local Result = DataExplorer.SelectedResult
			local Template = ""

			if Match.LocationType == "Table Index" or string.find(Match.LocationType, "Upvalue Table") then
				local IdxStr = tonumber(Match.Index) and Match.Index or "'" .. Match.Index .. "'"
				Template = [[local function modifytable()
    for i,v in next, getgc(true) do
        if type(v) == 'table' and rawget(v, ]] .. IdxStr .. [[) ~= nil then
            rawset(v, ]] .. IdxStr .. [[, NEW_VALUE_HERE)
        end
    end
end

modifytable()]]
			elseif Result.Type == "Function" then
				Template = [[local function findfunc(str)
    for i,v in next, getgc() do
        if type(v) == 'function' and tostring(v) == str then
            return v
        end
    end
end

local func = findfunc("]] .. tostring(Result.Ref) .. [[")
]]
				if Match.LocationType == "Constant" then
					Template = Template .. "debug.setconstant(func, " .. Match.Index .. ", NEW_VALUE_HERE)"
				elseif Match.LocationType == "Upvalue" then
					Template = Template .. "debug.setupvalue(func, " .. Match.Index .. ", NEW_VALUE_HERE)"
				end
			end
			env.setclipboard(Template)
		end})

		-- Detail View Window Setup
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

		local FilterMenu = Lib.ContextMenu.new()
		FilterMenu.Iconless = true
		FilterMenu.Width = 190

		local function BuildFilterMenu()
			FilterMenu:Clear()
			local F = DataExplorer.Filters
			local GlobalsActive = F.Globals

			FilterMenu:Add({
				Name = (GlobalsActive and "[X] " or "[ ] ") .. "Show _G / Shared",
				OnClick = function()
					F.Globals = not F.Globals
					BuildFilterMenu()
					if F.Globals then DataExplorer.Refresh() end
				end
			})
			FilterMenu:AddDivider()
			FilterMenu:Add({
				Name = (F.Constants and "[X] " or "[ ] ") .. "Scan Constants",
				Disabled = GlobalsActive,
				OnClick = function() if not GlobalsActive then F.Constants = not F.Constants; BuildFilterMenu() end end
			})
			FilterMenu:Add({
				Name = (F.Upvalues and "[X] " or "[ ] ") .. "Scan Upvalues",
				Disabled = GlobalsActive,
				OnClick = function() if not GlobalsActive then F.Upvalues = not F.Upvalues; BuildFilterMenu() end end
			})
			FilterMenu:Add({
				Name = (F.Protos and "[X] " or "[ ] ") .. "Scan Protos",
				Disabled = GlobalsActive,
				OnClick = function() if not GlobalsActive then F.Protos = not F.Protos; BuildFilterMenu() end end
			})
			FilterMenu:Add({
				Name = (F.Functions and "[X] " or "[ ] ") .. "Functions / Name",
				Disabled = GlobalsActive,
				OnClick = function() if not GlobalsActive then F.Functions = not F.Functions; BuildFilterMenu() end end
			})
			FilterMenu:Add({
				Name = (F.Tables and "[X] " or "[ ] ") .. "Tables",
				Disabled = GlobalsActive,
				OnClick = function() if not GlobalsActive then F.Tables = not F.Tables; BuildFilterMenu() end end
			})
			FilterMenu:AddDivider()
			FilterMenu:Add({
				Name = "Set Depth Limit (" .. DataExplorer.MaxDepth .. ")",
				OnClick = function()
					ShowInputPrompt("Set Depth Limit", DataExplorer.MaxDepth, function(StrVal)
						local Num = tonumber(StrVal)
						if Num then
							DataExplorer.MaxDepth = Num
							BuildFilterMenu()
						end
					end)
				end
			})
		end
		BuildFilterMenu()

		local TopBar = Instance.new("Frame", Window.GuiElems.Content)
		TopBar.Size = UDim2.new(1, 0, 0, 24)
		TopBar.BackgroundColor3 = Settings.Theme.Main2
		TopBar.BorderSizePixel = 0

		SearchBox = Lib.ViewportTextBox.new()
		SearchBox.Gui.Parent = TopBar
		SearchBox.Size = UDim2.new(1, -75, 1, -4)
		SearchBox.Position = UDim2.new(0, 4, 0, 2)
		SearchBox.TextBox.PlaceholderText = "Search for something.."

		local RefreshBtn = Instance.new("ImageButton", TopBar)
		RefreshBtn.Size = UDim2.new(0, 18, 0, 18)
		RefreshBtn.Position = UDim2.new(1, -22, 0, 3)
		RefreshBtn.BackgroundTransparency = 1
		RefreshBtn.Image = (getcustomasset and isfile and isfile("DEX_REContinued/Images/refresh-icon3.png")) and getcustomasset("DEX_REContinued/Images/refresh-icon3.png") or "rbxassetid://5642310344"
		RefreshBtn.MouseButton1Click:Connect(DataExplorer.Refresh)

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
			FilterMenu:Show(Main.Mouse.X, Main.Mouse.Y)
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
		ListLayout.Padding = UDim.new(0, 4)
		ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ListFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10)
		end)

		local Padding = Instance.new("UIPadding", ListFrame)
		Padding.PaddingTop = UDim.new(0, 4)
		Padding.PaddingBottom = UDim.new(0, 4)
		Padding.PaddingLeft = UDim.new(0, 4)
		Padding.PaddingRight = UDim.new(0, 4)

		SearchBox.TextBox.FocusLost:Connect(function(Enter)
			if Enter then DataExplorer.Refresh() end
		end)
	end

	return DataExplorer
end
return {InitDeps = InitDeps, InitAfterMain = InitAfterMain, Main = MainFunc}
