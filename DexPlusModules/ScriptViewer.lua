--[[
	Script Viewer App Module
	
	A script viewer that is basically a notepad
]]
-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

	local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local executorName = "Unknown"
local executorVersion = "???"
if identifyexecutor then
	local name,ver = identifyexecutor()
	executorName = name
	executorVersion = ver
elseif game:GetService("RunService"):IsStudio() then
	executorName = "Studio"
	executorVersion = version()
end

local function getPath(obj)
	if obj.Parent == nil then
		return "Nil parented"
	else
		return Explorer.GetInstancePath(obj)
	end
end

	local function main()
		local ScriptViewer = {}
		local window, codeFrame
	
		local execute, clear, dumpbtn
		local textSizeValue, textSizeFrame, textSizeInput
	
	local PreviousScr = nil
	
	ScriptViewer.DumpFunctions = function(scr)
		-- thanks King.Kevin#6025 you'll obviously be credited (no discord tag since that can easily be impersonated)
		local getgc = getgc or get_gc_objects
		local getupvalues = (debug and debug.getupvalues) or getupvalues or getupvals
		local getconstants = (debug and debug.getconstants) or getconstants or getconsts
		local getinfo = (debug and (debug.getinfo or debug.info)) or getinfo
		local original = ("\n-- // Function Dumper made by King.Kevin\n-- // Script Path: %s\n\n--[["):format(getPath(scr))
		local dump = original
		local functions, function_count, data_base = {}, 0, {}
		function functions:add_to_dump(str, indentation, new_line)
			local new_line = new_line or true
			dump = dump .. ("%s%s%s"):format(string.rep("		", indentation), tostring(str), new_line and "\n" or "")
		end
		function functions:get_function_name(func)
			local n = getinfo(func).name
			return n ~= "" and n or "Unknown Name"
		end
		function functions:dump_table(input, indent, index)
			local indent = indent < 0 and 0 or indent
			functions:add_to_dump(("%s [%s] %s"):format(tostring(index), tostring(typeof(input)), tostring(input)), indent - 1)
			local count = 0
			for index, value in pairs(input) do
				count = count + 1
				if type(value) == "function" then
					functions:add_to_dump(("%d [function] = %s"):format(count, functions:get_function_name(value)), indent)
				elseif type(value) == "table" then
					if not data_base[value] then
						data_base[value] = true
						functions:add_to_dump(("%d [table]:"):format(count), indent)
						functions:dump_table(value, indent + 1, index)
					else
						functions:add_to_dump(("%d [table] (Recursive table detected)"):format(count), indent)
					end
				else
					functions:add_to_dump(("%d [%s] = %s"):format(count, tostring(typeof(value)), tostring(value)), indent)
				end
			end
		end
		function functions:dump_function(input, indent)
			functions:add_to_dump(("\nFunction Dump: %s"):format(functions:get_function_name(input)), indent)
			functions:add_to_dump(("\nFunction Upvalues: %s"):format(functions:get_function_name(input)), indent)
			for index, upvalue in pairs(getupvalues(input)) do
				if type(upvalue) == "function" then
					functions:add_to_dump(("%d [function] = %s"):format(index, functions:get_function_name(upvalue)), indent + 1)
				elseif type(upvalue) == "table" then
					if not data_base[upvalue] then
						data_base[upvalue] = true
						functions:add_to_dump(("%d [table]:"):format(index), indent + 1)
						functions:dump_table(upvalue, indent + 2, index)
					else
						functions:add_to_dump(("%d [table] (Recursive table detected)"):format(index), indent + 1)
					end
				else
					functions:add_to_dump(("%d [%s] = %s"):format(index, tostring(typeof(upvalue)), tostring(upvalue)), indent + 1)
				end
			end
			functions:add_to_dump(("\nFunction Constants: %s"):format(functions:get_function_name(input)), indent)
			for index, constant in pairs(getconstants(input)) do
				if type(constant) == "function" then
					functions:add_to_dump(("%d [function] = %s"):format(index, functions:get_function_name(constant)), indent + 1)
				elseif type(constant) == "table" then
					if not data_base[constant] then
						data_base[constant] = true
						functions:add_to_dump(("%d [table]:"):format(index), indent + 1)
						functions:dump_table(constant, indent + 2, index)
					else
						functions:add_to_dump(("%d [table] (Recursive table detected)"):format(index), indent + 1)
					end
				else
					functions:add_to_dump(("%d [%s] = %s"):format(index, tostring(typeof(constant)), tostring(constant)), indent + 1)
				end
			end
		end
		for _, _function in pairs(env.getgc()) do
			if typeof(_function) == "function" and getfenv(_function).script and getfenv(_function).script == scr then
				functions:dump_function(_function, 0)
				functions:add_to_dump("\n" .. ("="):rep(100), 0, false)
			end
		end
		local source = codeFrame:GetText()

		if dump ~= original then source = source .. dump .. "]]" end
		codeFrame:SetText(source)
		
		window:Show()
	end

	ScriptViewer.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Executor")
		window:Resize(500,400)
		ScriptViewer.Window = window
	ScriptViewer.ShowExecutor = function()
		if window then window:SetTitle("Executor") end
		if dumpbtn then dumpbtn.Visible = false end
	end

		codeFrame = Lib.CodeFrame.new()
		codeFrame.Frame.Position = UDim2.new(0,0,0,20)
		codeFrame.Frame.Size = UDim2.new(1,0,1,-40)
		codeFrame.Frame.Parent = window.GuiElems.Content

		textSizeValue = Instance.new("NumberValue")
		textSizeValue.Name = "CodeTextSize"
		textSizeValue.Parent = codeFrame.Frame

		local savedTextSize = Main and Main.UserSettings and tonumber(Main.UserSettings.ScriptViewerTextSize)
		textSizeValue.Value = savedTextSize or codeFrame.FontSize or 16

		textSizeFrame = Instance.new("Frame", window.GuiElems.Content)
		textSizeFrame.Name = "TextSizeBox"
		textSizeFrame.BorderSizePixel = 0
		textSizeFrame.BackgroundColor3 = Color3.fromRGB(37, 37, 37)
		textSizeFrame.ClipsDescendants = true
		textSizeFrame.Size = UDim2.new(0.06, 0, 0, 18)
		textSizeFrame.Position = UDim2.new(0.64, 0, 0, 1)

		local textSizeStroke = Instance.new("UIStroke", textSizeFrame)
		textSizeStroke.Transparency = 0.65
		textSizeStroke.Thickness = 1.25

		textSizeInput = Instance.new("TextBox", textSizeFrame)
		textSizeInput.Name = "TextBox"
		textSizeInput.PlaceholderColor3 = Color3.fromRGB(108, 108, 108)
		textSizeInput.BorderSizePixel = 0
		textSizeInput.TextWrapped = true
		textSizeInput.TextSize = 15
		textSizeInput.TextColor3 = Color3.fromRGB(211, 211, 211)
		textSizeInput.TextScaled = true
		textSizeInput.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		textSizeInput.FontFace = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		textSizeInput.PlaceholderText = [[Size]]
		textSizeInput.Size = UDim2.new(1, 0, 1, 0)
		textSizeInput.BorderColor3 = Color3.fromRGB(0, 0, 0)
		textSizeInput.ClearTextOnFocus = false
		textSizeInput.Text = tostring(textSizeValue.Value)
		textSizeInput.BackgroundTransparency = 1

		local textSizePad = Instance.new("UIPadding", textSizeInput)
		textSizePad.PaddingTop = UDim.new(0, 2)
		textSizePad.PaddingRight = UDim.new(0, 5)
		textSizePad.PaddingLeft = UDim.new(0, 5)
		textSizePad.PaddingBottom = UDim.new(0, 2)

		local sizeBoxFocused = false
		textSizeInput.Focused:Connect(function()
			sizeBoxFocused = true
		end)

		local saveQueued = false
		local function queueSaveUserSettings()
			if not (Main and Main.SaveUserSettings) then return end
			if saveQueued then return end
			saveQueued = true
			delay(0.35, function()
				saveQueued = false
				if Main and Main.SaveUserSettings then
					Main.SaveUserSettings()
				end
			end)
		end

		local function applyTextSize()
			if not (codeFrame and textSizeValue) then return end

			local size = math.floor(tonumber(textSizeValue.Value) or (codeFrame.FontSize or 16))
			size = math.clamp(size, 1, 64)
			if size ~= textSizeValue.Value then
				textSizeValue.Value = size
				return
			end

			if not sizeBoxFocused and textSizeInput then
				textSizeInput.Text = tostring(size)
			end

			codeFrame.FontSize = size
			if codeFrame.LineFrames then
				for i = #codeFrame.LineFrames, 1, -1 do
					local lf = codeFrame.LineFrames[i]
					if lf and lf.Destroy then
						lf:Destroy()
					end
					codeFrame.LineFrames[i] = nil
				end
			end
			codeFrame:UpdateView()
			codeFrame:Refresh()

			if Main then
				Main.UserSettings = Main.UserSettings or {}
				Main.UserSettings.ScriptViewerTextSize = size
				queueSaveUserSettings()
			end
		end

		textSizeInput.FocusLost:Connect(function()
			sizeBoxFocused = false
			local n = tonumber(textSizeInput.Text)
			if n and n > 0 then
				textSizeValue.Value = n
			else
				textSizeInput.Text = tostring(textSizeValue.Value)
			end
		end)
		textSizeValue:GetPropertyChangedSignal("Value"):Connect(applyTextSize)
		applyTextSize()

		local UserInputService = game:GetService("UserInputService")
		local isHoldingCTRL = false

		local function setWheelScrollingEnabled(enabled)
			if not (codeFrame and codeFrame.ScrollV) then return end
			local scrollV = codeFrame.ScrollV

			if not enabled then
				if scrollV.ScrollUpEvent then
					scrollV.ScrollUpEvent:Disconnect()
					scrollV.ScrollUpEvent = nil
				end
				if scrollV.ScrollDownEvent then
					scrollV.ScrollDownEvent:Disconnect()
					scrollV.ScrollDownEvent = nil
				end
				return
			end

			local lines = codeFrame.Frame and (codeFrame.Frame:FindFirstChild("Lines") or codeFrame.Frame.Lines)
			if lines then
				scrollV:SetScrollFrame(lines)
			end
		end

		UserInputService.InputBegan:Connect(function(input, gameproc)
			if gameproc then return end
			if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
				isHoldingCTRL = true
				setWheelScrollingEnabled(false)
			end
		end)
		UserInputService.InputEnded:Connect(function(input, gameproc)
			if gameproc then return end
			if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
				isHoldingCTRL = false
				setWheelScrollingEnabled(true)
			end
		end)

		local linesFrame = codeFrame.Frame:FindFirstChild("Lines")
		if linesFrame then
			linesFrame.MouseWheelForward:Connect(function()
				if isHoldingCTRL then
					textSizeValue.Value = textSizeValue.Value + 1
				end
			end)
			linesFrame.MouseWheelBackward:Connect(function()
				if isHoldingCTRL then
					local newSize = textSizeValue.Value - 1
					if newSize >= 1 then
						textSizeValue.Value = newSize
					end
				end
			end)
		end
		
		local copy = Instance.new("TextButton",window.GuiElems.Content)
		copy.BackgroundTransparency = 1
		copy.Size = UDim2.new(0.32,0,0,20)
		copy.Position = UDim2.new(0,0,0,0)
		copy.Text = "Copy to Clipboard"
		
		if env.setclipboard then
			copy.TextColor3 = Color3.new(1,1,1)
			copy.Interactable = true
		else
			copy.TextColor3 = Color3.new(0.5,0.5,0.5)
			copy.Interactable = false
		end

		copy.MouseButton1Click:Connect(function()
			local source = codeFrame:GetText()
			env.setclipboard(source)
		end)

		local save = Instance.new("TextButton",window.GuiElems.Content)
		save.BackgroundTransparency = 1
		save.Size = UDim2.new(0.32,0,0,20)
		save.Position = UDim2.new(0.32,0,0,0)
		save.Text = "Save to File"
		save.TextColor3 = Color3.new(1,1,1)
		
		if env.writefile then
			save.TextColor3 = Color3.new(1,1,1)
			save.Interactable = true
		else
			save.TextColor3 = Color3.new(0.5,0.5,0.5)
			--save.Interactable = false
		end

		save.MouseButton1Click:Connect(function()
			local source = codeFrame:GetText()
			local filename = "Place_"..game.PlaceId.."_Script_"..os.time()..".txt"

			Lib.SaveAsPrompt(filename,source)
			--env.writefile(filename,source)
		end)
		-- Buttons below the editor
		
		
		execute = Instance.new("TextButton",window.GuiElems.Content)
		execute.BackgroundTransparency = 1
		execute.Size = UDim2.new(0.5,0,0,20)
		execute.Position = UDim2.new(0,0,1,-20)
		execute.Text = "Execute"
		execute.TextColor3 = Color3.new(1,1,1)
		
		if env.loadstring then
			execute.TextColor3 = Color3.new(1,1,1)
			execute.Interactable = true
		else
			execute.TextColor3 = Color3.new(0.5,0.5,0.5)
			execute.Interactable = false
		end

		execute.MouseButton1Click:Connect(function()
			local source = codeFrame:GetText()
			env.loadstring(source)()
		end)

		clear = Instance.new("TextButton",window.GuiElems.Content)
		clear.BackgroundTransparency = 1
		clear.Size = UDim2.new(0.5,0,0,20)
		clear.Position = UDim2.new(0.5,0,1,-20)
		clear.Text = "Clear"
		clear.TextColor3 = Color3.new(1,1,1)

		clear.MouseButton1Click:Connect(function()
			codeFrame:SetText("")
		end)

		ScriptViewer.ApplyTheme = function()
			local t = Settings and Settings.Theme
			if not t then return end
			if ScriptViewer.Window and ScriptViewer.Window.ApplyTheme then
				ScriptViewer.Window:ApplyTheme()
			end
			if codeFrame and codeFrame.Frame then
				codeFrame.Frame.BackgroundColor3 = t.TextBox or codeFrame.Frame.BackgroundColor3
			end
			if textSizeFrame then
				textSizeFrame.BackgroundColor3 = t.TextBox or textSizeFrame.BackgroundColor3
			end
		end
	end
	
	ScriptViewer.ViewScript = function(scr)
		local oldtick = tick()
		local s,source = pcall(env.decompile or function() end,scr)

		if window then window:SetTitle("Script Viewer") end

		if not dumpbtn then
			dumpbtn = Instance.new("TextButton",window.GuiElems.Content)
			dumpbtn.BackgroundTransparency = 1
			dumpbtn.Position = UDim2.new(0.7,0,0,0)
			dumpbtn.Size = UDim2.new(0.3,0,0,20)
			dumpbtn.Text = "Dump Functions"
			dumpbtn.TextColor3 = Color3.new(0.5,0.5,0.5)
			dumpbtn.Visible = false -- hidden until viewing a script

			dumpbtn.MouseButton1Click:Connect(function()
				if PreviousScr ~= nil then
					pcall(ScriptViewer.DumpFunctions, PreviousScr)
				end
			end)
		end
		dumpbtn.Visible = true
		if env.getgc then
			dumpbtn.TextColor3 = Color3.new(1,1,1)
			dumpbtn.Interactable = true
		else
			dumpbtn.TextColor3 = Color3.new(0.5,0.5,0.5)
			dumpbtn.Interactable = false
		end

		if not s or not source then
			PreviousScr = nil
			dumpbtn.TextColor3 = Color3.new(0.5,0.5,0.5)
			source = "-- Unable to view source.\n"
			source = source .. "-- Script Path: "..getPath(scr).."\n"
			if (scr.ClassName == "Script" and (scr.RunContext == Enum.RunContext.Legacy or scr.RunContext == Enum.RunContext.Server)) or not scr:IsA("LocalScript") then
				source = source .. "-- Reason: The script is not running on client. (attempt to decompile ServerScript or 'Script' with RunContext Server)\n"
			elseif not env.decompile then
				source = source .. "-- Reason: Your executor does not support decompiler. (missing 'decompile' function)\n"
			else
				source = source .. "-- Reason: Unknown\n"
			end
			source = source .. "-- Executor: "..executorName.." ("..executorVersion..")"
		else
			PreviousScr = scr
			dumpbtn.TextColor3 = Color3.new(1,1,1)

			local decompiled = source

			source = "-- Script Path: "..getPath(scr).."\n"
			source = source .. "-- Took "..tostring(math.floor( (tick() - oldtick) * 100) / 100).."s to decompile.\n"
			source = source .. "-- Executor: "..executorName.." ("..executorVersion..")\n\n"

			source = source .. decompiled

			oldtick = nil
			decompiled = nil
		end

		codeFrame:SetText(source)
		if window then window:SetTitle("Script Viewer") end
		window:Show()
	end

	return ScriptViewer
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
