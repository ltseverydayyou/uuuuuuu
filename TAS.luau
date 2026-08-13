local AutoLoadAndPlayFile = getgenv().AutoLoadAndPlayFile
if AutoLoadAndPlayFile == nil then AutoLoadAndPlayFile = "" end

local ExtremeSmoothing = getgenv().ExtremeSmoothing
if ExtremeSmoothing == nil then ExtremeSmoothing = false end

local TargetSmoothingFPS = getgenv().TargetSmoothingFPS
if TargetSmoothingFPS == nil then TargetSmoothingFPS = 24 end

local ShowVelocityDuringPlayback = getgenv().ShowVelocityDuringPlayback
if ShowVelocityDuringPlayback == nil then ShowVelocityDuringPlayback = false end

local ShowTASPathDuringPlayback = getgenv().ShowTASPathDuringPlayback
if ShowTASPathDuringPlayback == nil then ShowTASPathDuringPlayback = false end

local PlaybackCamera = getgenv().PlaybackCamera
if PlaybackCamera == nil then PlaybackCamera = true end

local MaxTrajectoryFrames = getgenv().MaxTrajectoryFrames
if MaxTrajectoryFrames == nil then MaxTrajectoryFrames = 150 end

if getgenv().TAS_Recorder_Running then
	pcall(function() getgenv().TAS_Recorder_Disconnect() end)
	task.wait(0.2)
end
getgenv().TAS_Recorder_Running = true

local __lt = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {}
	local sharedEnv = rawget(_G, "shared")
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil)
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver")
		if type(cached) == "table" then
			return cached
		end
	end
	local loader = loadstring or load
	if type(loader) ~= "function" then
		error("Service resolver loader unavailable")
	end
	local resolver = loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau")
	if type(resolver) ~= "function" then
		error("Service resolver failed to compile")
	end
	local loaded = resolver()
	if type(loaded) ~= "table" then
		error("Service resolver failed to load")
	end
	if cacheHost then
		cacheHost.__lt_service_resolver = loaded
	end
	return loaded
end)()

local __NAUIProtector = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {}
	local sharedEnv = rawget(_G, "shared")
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil)
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_ui_protector")
		if type(cached) == "table" then
			return cached
		end
	end
	local loader = loadstring or load
	if type(loader) ~= "function" then
		return nil
	end
	local okSource, source = pcall(function()
		return game:HttpGet("https://ltseverydayyou.github.io/UIprotector.luau")
	end)
	if not okSource or type(source) ~= "string" or source == "" then
		return nil
	end
	local chunk = loader(source, "@UIprotector.luau")
	if type(chunk) ~= "function" then
		return nil
	end
	local okLoaded, loaded = pcall(chunk)
	if okLoaded and type(loaded) == "table" then
		if cacheHost then
			cacheHost.__lt_ui_protector = loaded
		end
		return loaded
	end
	return nil
end)()

local __NAOriginalGetHui = gethui
local gethui = function()
	if __NAUIProtector and type(__NAUIProtector.huiGrabber) == "function" then
		local ok, ui = pcall(__NAUIProtector.huiGrabber)
		if ok and typeof(ui) == "Instance" then
			return ui
		end
	end
	if type(__NAOriginalGetHui) == "function" then
		local ok, ui = pcall(__NAOriginalGetHui)
		if ok and typeof(ui) == "Instance" then
			return ui
		end
	end
	return nil
end

local function __NAProtectUI(gui, options)
	if __NAUIProtector and type(__NAUIProtector.protectUI) == "function" then
		local ok, protected = pcall(__NAUIProtector.protectUI, gui, options)
		if ok and protected then
			return protected
		end
	end
	return nil
end

local Reference = cloneref and type(cloneref) == "function" and cloneref or function(value)
	return value
end

local UserInputService = __lt.cs("UserInputService", Reference)
local RunService = __lt.cs("RunService", Reference)
local HttpService = __lt.cs("HttpService", Reference)
local Players = __lt.cs("Players", Reference)
local Workspace = __lt.cs("Workspace", Reference)
local StarterGui = __lt.cs("StarterGui", Reference)
local ContextActionService = __lt.cs("ContextActionService", Reference)
local CoreGui = __lt.cs("CoreGui", Reference)
local GuiService = __lt.cs("GuiService", Reference)

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local ValToStateName = {}
for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
	ValToStateName[state.Value] = state.Name
end

local KeepEnabledStates = {
	[Enum.HumanoidStateType.Dead] = true,
	[Enum.HumanoidStateType.GettingUp] = true,
	[Enum.HumanoidStateType.Landed] = true,
	[Enum.HumanoidStateType.None] = true
}

local function DeepCopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = table.create and table.create(#orig) or {}
		for orig_key, orig_value in pairs(orig) do
			copy[orig_key] = DeepCopy(orig_value)
		end
	else
		copy = orig
	end
	return copy
end

local ActionOrder = {
	"Pause",
	"AddSavestate",
	"RemoveSavestate",
	"EnterSavestate",
	"BackSavestate",
	"GoFrameBack",
	"GoFrameForward",
	"SaveRun",
	"LoadRun",
	"ViewTAS",
	"CollisionToggler",
	"DebugToggler",
	"ToggleVelocityVis",
	"ResetToNormal"
}

local ActionLabels = {
	Pause = "Pause/Unpause",
	AddSavestate = "Add Savestate",
	RemoveSavestate = "Remove Savestate",
	EnterSavestate = "Enter Last Savestate (Edit)",
	BackSavestate = "Load Last Savestate",
	GoFrameBack = "-1 Frame",
	GoFrameForward = "+1 Frame",
	SaveRun = "Save Run (Hold for JSON)",
	LoadRun = "Load Run",
	ViewTAS = "Playback TAS",
	CollisionToggler = "Toggle Collision",
	DebugToggler = "Debug View",
	ToggleVelocityVis = "Toggle Velocity Vis",
	ResetToNormal = "STOP SCRIPT"
}

local TouchBindingLabels = {
	Pause = "Pause",
	AddSavestate = "Add State",
	RemoveSavestate = "Remove State",
	EnterSavestate = "Edit State",
	BackSavestate = "Load State",
	GoFrameBack = "-1 Frame",
	GoFrameForward = "+1 Frame",
	SaveRun = "Save / Hold JSON",
	LoadRun = "Load Run",
	ViewTAS = "Playback",
	CollisionToggler = "Collision",
	DebugToggler = "Debug",
	ToggleVelocityVis = "Velocity",
	ResetToNormal = "Unload"
}

local DefaultKeyboardBindings = {
	Pause = Enum.KeyCode.CapsLock,
	AddSavestate = Enum.KeyCode.One,
	RemoveSavestate = Enum.KeyCode.Two,
	EnterSavestate = Enum.KeyCode.Three,
	BackSavestate = Enum.KeyCode.Eight,
	GoFrameBack = Enum.KeyCode.R,
	GoFrameForward = Enum.KeyCode.F,
	SaveRun = Enum.KeyCode.Six,
	LoadRun = Enum.KeyCode.Minus,
	ViewTAS = Enum.KeyCode.Zero,
	CollisionToggler = Enum.KeyCode.C,
	DebugToggler = Enum.KeyCode.V,
	ToggleVelocityVis = Enum.KeyCode.L,
	ResetToNormal = Enum.KeyCode.Delete
}

local DefaultControllerActionBindings = {
	Pause = {Modifier = Enum.KeyCode.ButtonL1, Key = Enum.KeyCode.ButtonY},
	AddSavestate = {Modifier = Enum.KeyCode.ButtonL1, Key = Enum.KeyCode.ButtonA},
	RemoveSavestate = {Modifier = Enum.KeyCode.ButtonL1, Key = Enum.KeyCode.ButtonB},
	EnterSavestate = {Modifier = Enum.KeyCode.ButtonL1, Key = Enum.KeyCode.ButtonX},
	BackSavestate = {Modifier = Enum.KeyCode.ButtonL1, Key = Enum.KeyCode.DPadDown},
	GoFrameBack = {Modifier = Enum.KeyCode.ButtonL1, Key = Enum.KeyCode.DPadLeft},
	GoFrameForward = {Modifier = Enum.KeyCode.ButtonL1, Key = Enum.KeyCode.DPadRight},
	SaveRun = {Modifier = Enum.KeyCode.ButtonR1, Key = Enum.KeyCode.ButtonA},
	LoadRun = {Modifier = Enum.KeyCode.ButtonR1, Key = Enum.KeyCode.ButtonB},
	ViewTAS = {Modifier = Enum.KeyCode.ButtonL1, Key = Enum.KeyCode.DPadUp},
	CollisionToggler = {Modifier = Enum.KeyCode.ButtonR1, Key = Enum.KeyCode.ButtonX},
	DebugToggler = {Modifier = Enum.KeyCode.ButtonR1, Key = Enum.KeyCode.ButtonY},
	ToggleVelocityVis = {Modifier = Enum.KeyCode.ButtonR1, Key = Enum.KeyCode.DPadUp},
	ResetToNormal = {Modifier = Enum.KeyCode.ButtonR1, Key = Enum.KeyCode.DPadDown}
}

local KeyboardBindings = DeepCopy(DefaultKeyboardBindings)
local ControllerActionBindings = DeepCopy(DefaultControllerActionBindings)

local Savestates = {}
local PlayerInfo = {}
local TimePaused = 0
local Pause = true
local ViewingTAS = false
local TimePauseHolder
local TimeStart
local DebugView = false
local ShowVelocityDuringRecording = true
local LastRecordTime = 0

local OriginalVisuals = setmetatable({}, { __mode = "k" }) 

getgenv().TAS_IsRecording = false 
getgenv().TAS_IsPlaying = false 
local ActivePlaybackFrames = nil
local CurrentPlaybackIndex = 1
local LastTrajectoryUpdate = 0

local HUD
local FrameCountLabel, SavestatesCountLabel, TimeTextLabel, TASNameBox, KeyBindFrame, MainFrame
local MobileControlsFrame, TouchControlsButton, SettingsFrame, SettingsList, SettingsButton
local KeyBindContent, KeyBindTitle
local TrajectoryFolder
local TrajectoryLines = {}
local PathLines = {}

local Connections = {}
local CharConnections = {}
local PlayConn
local ActionRouter = {}
local ControllerModifiers = {L1 = false, R1 = false}
local ControllerActiveActions = {}
local ControllerActionName = "TASControllerControls"
local ControllerBindableKeys = {
	Enum.KeyCode.ButtonA,
	Enum.KeyCode.ButtonB,
	Enum.KeyCode.ButtonX,
	Enum.KeyCode.ButtonY,
	Enum.KeyCode.DPadUp,
	Enum.KeyCode.DPadDown,
	Enum.KeyCode.DPadLeft,
	Enum.KeyCode.DPadRight,
	Enum.KeyCode.ButtonL2,
	Enum.KeyCode.ButtonR2,
	Enum.KeyCode.ButtonL3,
	Enum.KeyCode.ButtonR3,
	Enum.KeyCode.ButtonStart,
	Enum.KeyCode.ButtonSelect
}
local ControllerBindings = {L1 = {}, R1 = {}, None = {}}
local CurrentInputMode = "Keyboard"
local SettingsTab = "Keyboard"
local BindingCapture = nil
local RefreshKeybindDisplay = function() end
local RefreshSettingsRows = function() end

local function RebuildControllerBindings()
	ControllerBindings = {L1 = {}, R1 = {}, None = {}}
	for action, binding in pairs(ControllerActionBindings) do
		if binding and binding.Key then
			local modifierName = "None"
			if binding.Modifier == Enum.KeyCode.ButtonL1 then
				modifierName = "L1"
			elseif binding.Modifier == Enum.KeyCode.ButtonR1 then
				modifierName = "R1"
			end
			ControllerBindings[modifierName][binding.Key] = action
		end
	end
end

RebuildControllerBindings()

local function notify(text, title, dur)
	pcall(function()
		__lt.cm("StarterGui", "SetCore", "SendNotification", {Title = title or "TAS Recorder", Text = text or "", Duration = dur or 3})
	end)
end

local TASRootFolder = "ltseverydayyou-TAS"
local TASPlaceFolder = TASRootFolder .. "/" .. tostring(game.PlaceId)
local TASSettingsFile = TASRootFolder .. "/Settings.json"

local function EnsureFolder(path)
	if not makefolder then return false end
	if isfolder then
		local ok, exists = pcall(isfolder, path)
		if ok and exists then return true end
	end
	return pcall(makefolder, path)
end

local function EnsureStorage()
	if not makefolder then return false end
	EnsureFolder(TASRootFolder)
	EnsureFolder(TASPlaceFolder)
	return true
end

local function GetRunPath(fileName)
	return TASPlaceFolder .. "/" .. fileName
end

local function KeyCodeFromName(name)
	if type(name) ~= "string" then return nil end
	local ok, key = pcall(function() return Enum.KeyCode[name] end)
	if ok and typeof(key) == "EnumItem" then return key end
	return nil
end

local function SaveSettings(silent)
	if not writefile then
		if not silent then notify("Executor does not support writefile!", "Settings") end
		return false
	end
	local data = {Keyboard = {}, Controller = {}}
	for action, key in pairs(KeyboardBindings) do
		data.Keyboard[action] = key.Name
	end
	for action, binding in pairs(ControllerActionBindings) do
		data.Controller[action] = {
			Modifier = binding.Modifier and binding.Modifier.Name or nil,
			Key = binding.Key and binding.Key.Name or nil
		}
	end
	local ok, err = pcall(function()
		EnsureFolder(TASRootFolder)
		local encoded = __lt.cm("HttpService", "JSONEncode", data)
		writefile(TASSettingsFile, encoded)
	end)
	if not silent then
		if ok then notify("Keybind settings saved", "TAS Settings", 2)
		else notify("Settings save failed: " .. tostring(err), "Error") end
	end
	return ok
end

local function LoadSettings()
	KeyboardBindings = DeepCopy(DefaultKeyboardBindings)
	ControllerActionBindings = DeepCopy(DefaultControllerActionBindings)
	if readfile and isfile then
		local okExists, exists = pcall(isfile, TASSettingsFile)
		if okExists and exists then
			pcall(function()
				local data = __lt.cm("HttpService", "JSONDecode", readfile(TASSettingsFile))
				if type(data) == "table" then
					if type(data.Keyboard) == "table" then
						for action, name in pairs(data.Keyboard) do
							local key = KeyCodeFromName(name)
							if key and DefaultKeyboardBindings[action] then KeyboardBindings[action] = key end
						end
					end
					if type(data.Controller) == "table" then
						for action, saved in pairs(data.Controller) do
							if DefaultControllerActionBindings[action] and type(saved) == "table" then
								local key = KeyCodeFromName(saved.Key)
								local modifier = KeyCodeFromName(saved.Modifier)
								if key then ControllerActionBindings[action] = {Modifier = modifier, Key = key} end
							end
						end
					end
				end
			end)
		end
	end
	RebuildControllerBindings()
end

local function ResetBindingDefaults()
	KeyboardBindings = DeepCopy(DefaultKeyboardBindings)
	ControllerActionBindings = DeepCopy(DefaultControllerActionBindings)
	RebuildControllerBindings()
	BindingCapture = nil
	SaveSettings(true)
	RefreshKeybindDisplay()
	RefreshSettingsRows()
	notify("Keybinds reset to defaults", "TAS Settings", 2)
end

local function IsGamepadInput(inputType)
	return inputType and inputType.Name and inputType.Name:match("^Gamepad") ~= nil
end

local function InputModeFromType(inputType)
	if inputType == Enum.UserInputType.Touch then return "Touch" end
	if IsGamepadInput(inputType) then return "Controller" end
	return "Keyboard"
end

local function SetInputMode(mode)
	if mode ~= "Keyboard" and mode ~= "Controller" and mode ~= "Touch" then return end
	if CurrentInputMode ~= mode then
		CurrentInputMode = mode
		RefreshKeybindDisplay()
	end
end

local function ShortKeyName(key)
	if not key then return "None" end
	local name = key.Name
	if name:sub(1, 3) == "Button" then name = name:sub(7) end
	return name
end

local function FormatControllerBinding(binding)
	if not binding or not binding.Key then return "None" end
	local keyName = ShortKeyName(binding.Key)
	if binding.Modifier then
		return ShortKeyName(binding.Modifier) .. "+" .. keyName
	end
	return keyName
end

local function GetKeyboardActionForKey(key)
	for action, boundKey in pairs(KeyboardBindings) do
		if boundKey == key then return action end
	end
	return nil
end

local function FindKeyboardConflict(action, key)
	for otherAction, boundKey in pairs(KeyboardBindings) do
		if otherAction ~= action and boundKey == key then return otherAction end
	end
	return nil
end

local function FindControllerConflict(action, modifier, key)
	for otherAction, binding in pairs(ControllerActionBindings) do
		if otherAction ~= action and binding.Key == key and binding.Modifier == modifier then return otherAction end
	end
	return nil
end


local function makeDraggable(guiObject, dragHandle)
	dragHandle = dragHandle or guiObject
	local dragging, dragInput, dragStart, startPos
	local function update(input)
		local delta = input.Position - dragStart
		guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	
	local inputConn
	inputConn = UserInputService.InputChanged:Connect(function(input) 
		if input == dragInput and dragging then update(input) end 
	end)
	
	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = guiObject.Position
			input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	
	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
	end)

	guiObject.Destroying:Connect(function()
		if inputConn then inputConn:Disconnect() end
	end)
end

local function updateStatusColor()
	if not MainFrame then return end
	local color
	if ViewingTAS then color = Color3.fromRGB(0, 255, 100)
	elseif Pause then color = Color3.fromRGB(255, 200, 0)
	else color = Color3.fromRGB(255, 50, 50) end
	MainFrame.BorderColor3 = color
	local stroke = MainFrame:FindFirstChild("TASLegacyStroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Color = color
	end
end

local function CFrameToQuat(cf)
	local axis, angle = cf:ToAxisAngle()
	local sinHalf = math.sin(angle/2)
	return axis.X * sinHalf, axis.Y * sinHalf, axis.Z * sinHalf, math.cos(angle/2)
end

local function QuatToCFrame(x, y, z, qX, qY, qZ, qW)
	return CFrame.new(x, y, z, qX, qY, qZ, qW)
end

local function ToggleDebugView()
	DebugView = not DebugView
	if DebugView then
		notify("Debug View: Enabled", "TAS Tools")
		OriginalVisuals = setmetatable({}, { __mode = "k" })
		
		local descendants = __lt.cm("Workspace", "GetDescendants")
		for i, v in ipairs(descendants) do
			if i % 500 == 0 then task.wait() end 
			if not DebugView then return end 
			
			if v:IsA("BasePart") and not v:IsDescendantOf(LocalPlayer.Character) then
				OriginalVisuals[v] = {Color = v.Color, Transparency = v.Transparency}
				
				local gray = math.random(200, 800) / 1000
				v.Color = Color3.new(gray, gray, gray)
				
				if v.Transparency == 1 then v.Transparency = 0.5 end
				if v.CanCollide == false then v.Transparency = 0.9 end
				
				local minSize = math.min(v.Size.X, v.Size.Y, v.Size.Z)
				if v:FindFirstChild("TouchInterest") then 
					v.Color = Color3.fromRGB(math.random(100, 255), math.random(0, 50), math.random(0, 50))
					v.Transparency = 0 
				elseif minSize < 1 then
					local h; repeat h = math.random() until h < 0.45 or h > 0.55 
					local s = math.random(40, 100) / 100 
					local val = math.random(20, 100) / 100 
					v.Color = Color3.fromHSV(h, s, val)
				end
			end
		end
	else
		notify("Debug View: Disabled", "TAS Tools")
		for part, props in pairs(OriginalVisuals) do
			if part and part.Parent then part.Color = props.Color; part.Transparency = props.Transparency end
		end
		OriginalVisuals = setmetatable({}, { __mode = "k" })
	end
end

local function ReturnPlayerInfo()
	local char = LocalPlayer.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")
	
	local cf = root and root.CFrame or CFrame.new()
	local vel = root and root.Velocity or Vector3.zero
	local rvel = root and root.RotVelocity or Vector3.zero
	local camCf = Workspace.CurrentCamera.CFrame
	
	local hs = hum and hum:GetState().Value or 18
	
	local qX, qY, qZ, qW = CFrameToQuat(cf)
	local cqX, cqY, cqZ, cqW = CFrameToQuat(camCf)

	return {
		CF = {cf.X, cf.Y, cf.Z, qX, qY, qZ, qW}, 
		CCF = {camCf.X, camCf.Y, camCf.Z, cqX, cqY, cqZ, cqW},
		V = {vel.X, vel.Y, vel.Z},
		RV = {rvel.X, rvel.Y, rvel.Z},
		HS = hs, T = os.clock() - TimeStart - TimePaused
	}
end

local function UpdateGUIText()
	if SavestatesCountLabel then SavestatesCountLabel.Text = "Savestates: " .. tostring(#Savestates) end
	if FrameCountLabel then FrameCountLabel.Text = "Frames: " .. tostring(#PlayerInfo) end
end

local function FormatTime(TimeValue)
	local m = math.floor(TimeValue / 60)
	local s = math.floor(TimeValue % 60)
	local ms = math.floor((TimeValue * 1000) % 1000)
	return string.format("%d:%02d.%03d", m, s, ms)
end

local function UpdateTimeGUI()
	if TimeTextLabel then
		local TimePlayed = os.clock() - TimeStart - TimePaused
		TimeTextLabel.Text = FormatTime(TimePlayed)
	end
end

local function SetUpGui()
	if HUD then HUD:Destroy() end

	local function RoundCorners(gui, radius)
	if not gui or not gui:IsA("GuiObject") then return end
	local corner = gui:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Parent = gui
	end
	corner.CornerRadius = UDim.new(0, radius or 3)
	task.defer(function()
		if not gui or not gui.Parent or gui.BackgroundTransparency >= 1 then return end
		local thickness = gui.BorderSizePixel
		if thickness <= 0 then return end
		local stroke = gui:FindFirstChild("TASLegacyStroke")
		if not stroke then
			stroke = Instance.new("UIStroke")
			stroke.Name = "TASLegacyStroke"
			stroke.Parent = gui
		end
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = gui.BorderColor3
		stroke.Thickness = thickness
		stroke.Transparency = 0
		gui.BorderSizePixel = 0
	end)
end

	HUD = Instance.new("ScreenGui")
	HUD.Name = "TASRecorderGUI"
	HUD.ResetOnSpawn = false
	HUD.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	if not __NAProtectUI(HUD) then
		local uiParent = gethui()
		if not uiParent then uiParent = CoreGui end
		if not uiParent then uiParent = LocalPlayer:WaitForChild("PlayerGui") end
		HUD.Parent = uiParent
	end

	MainFrame = Instance.new("Frame", HUD)
	RoundCorners(MainFrame, 4)
	MainFrame.AnchorPoint = Vector2.new(0.5, 1)
	MainFrame.Position = UDim2.new(0.5, 0, 0.9, 0)
	local MainFrameHeight = UserInputService.TouchEnabled and 204 or 178
	MainFrame.Size = UDim2.new(0, 280, 0, MainFrameHeight)
	MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	MainFrame.BackgroundTransparency = 0.2
	MainFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
	MainFrame.BorderSizePixel = 2

	local UIListLayout = Instance.new("UIListLayout", MainFrame)
	UIListLayout.Padding = UDim.new(0, 4)
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local Header = Instance.new("Frame", MainFrame)
	RoundCorners(Header, 4)
	Header.LayoutOrder = 0
	Header.Size = UDim2.new(1, -8, 0, 24)
	Header.BackgroundTransparency = 1
	Header.Active = true
	makeDraggable(MainFrame, Header)

	local HeaderTitle = Instance.new("TextLabel", Header)
	RoundCorners(HeaderTitle, 3)
	HeaderTitle.Size = UDim2.new(1, -86, 1, 0)
	HeaderTitle.Position = UDim2.new(0, 4, 0, 0)
	HeaderTitle.BackgroundTransparency = 1
	HeaderTitle.Font = Enum.Font.SourceSansBold
	HeaderTitle.Text = "TAS Recorder"
	HeaderTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	HeaderTitle.TextSize = 16
	HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left

	SettingsButton = Instance.new("TextButton", Header)
	RoundCorners(SettingsButton, 3)
	SettingsButton.Size = UDim2.new(0, 54, 0, 22)
	SettingsButton.Position = UDim2.new(1, -80, 0, 1)
	SettingsButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	SettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	SettingsButton.Font = Enum.Font.SourceSansBold
	SettingsButton.Text = "Settings"
	SettingsButton.TextSize = 12

	local CloseButton = Instance.new("TextButton", Header)
	RoundCorners(CloseButton, 3)
	CloseButton.Size = UDim2.new(0, 22, 0, 22)
	CloseButton.Position = UDim2.new(1, -23, 0, 1)
	CloseButton.BackgroundColor3 = Color3.fromRGB(110, 45, 45)
	CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloseButton.Font = Enum.Font.SourceSansBold
	CloseButton.Text = "X"
	CloseButton.TextSize = 14
	CloseButton.Activated:Connect(function()
		if ActionRouter.Begin then ActionRouter.Begin("ResetToNormal", CloseButton) end
	end)

	TimeTextLabel = Instance.new("TextLabel", MainFrame)
	RoundCorners(TimeTextLabel, 3)
	TimeTextLabel.LayoutOrder = 1
	TimeTextLabel.Size = UDim2.new(0.9, 0, 0, 25)
	TimeTextLabel.BackgroundTransparency = 1
	TimeTextLabel.Font = Enum.Font.RobotoMono
	TimeTextLabel.Text = "0:00.000"
	TimeTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TimeTextLabel.TextScaled = true

	SavestatesCountLabel = Instance.new("TextLabel", MainFrame)
	RoundCorners(SavestatesCountLabel, 3)
	SavestatesCountLabel.LayoutOrder = 2
	SavestatesCountLabel.Size = UDim2.new(0.9, 0, 0, 15)
	SavestatesCountLabel.BackgroundTransparency = 1
	SavestatesCountLabel.Font = Enum.Font.SourceSans
	SavestatesCountLabel.Text = "Savestates: 0"
	SavestatesCountLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	SavestatesCountLabel.TextScaled = true

	FrameCountLabel = Instance.new("TextLabel", MainFrame)
	RoundCorners(FrameCountLabel, 3)
	FrameCountLabel.LayoutOrder = 3
	FrameCountLabel.Size = UDim2.new(0.9, 0, 0, 15)
	FrameCountLabel.BackgroundTransparency = 1
	FrameCountLabel.Font = Enum.Font.SourceSans
	FrameCountLabel.Text = "Frames: 0"
	FrameCountLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	FrameCountLabel.TextScaled = true

	TASNameBox = Instance.new("TextBox", MainFrame)
	RoundCorners(TASNameBox, 3)
	TASNameBox.LayoutOrder = 4
	TASNameBox.Size = UDim2.new(0.9, 0, 0, 20)
	TASNameBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
	TASNameBox.BackgroundTransparency = 0.5
	TASNameBox.Font = Enum.Font.SourceSans
	TASNameBox.PlaceholderText = "File Name (Place " .. tostring(game.PlaceId) .. ")"
	TASNameBox.Text = ""
	TASNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	TASNameBox.TextSize = 14

	local KeybindsButton = Instance.new("TextButton", MainFrame)
	RoundCorners(KeybindsButton, 3)
	KeybindsButton.LayoutOrder = 5
	KeybindsButton.Size = UDim2.new(0.9, 0, 0, 20)
	KeybindsButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	KeybindsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	KeybindsButton.Text = "Toggle Keybinds"
	KeybindsButton.Font = Enum.Font.SourceSansBold
	KeybindsButton.TextSize = 14

	KeyBindFrame = Instance.new("Frame", HUD)
	RoundCorners(KeyBindFrame, 4)
	KeyBindFrame.AnchorPoint = Vector2.new(0.5, 1)
	KeyBindFrame.Position = UDim2.new(0.5, 0, 0.9, -(MainFrameHeight + 10))
	KeyBindFrame.Size = UDim2.new(0, 330, 0, 345)
	KeyBindFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	KeyBindFrame.BackgroundTransparency = 0.2
	KeyBindFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
	KeyBindFrame.Visible = false
	makeDraggable(KeyBindFrame)

	KeyBindTitle = Instance.new("TextLabel", KeyBindFrame)
	RoundCorners(KeyBindTitle, 3)
	KeyBindTitle.Size = UDim2.new(1, -10, 0, 26)
	KeyBindTitle.Position = UDim2.new(0, 5, 0, 3)
	KeyBindTitle.BackgroundTransparency = 1
	KeyBindTitle.Font = Enum.Font.SourceSansBold
	KeyBindTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	KeyBindTitle.TextSize = 17
	KeyBindTitle.TextXAlignment = Enum.TextXAlignment.Left

	KeyBindContent = Instance.new("Frame", KeyBindFrame)
	RoundCorners(KeyBindContent, 4)
	KeyBindContent.Position = UDim2.new(0, 5, 0, 31)
	KeyBindContent.Size = UDim2.new(1, -10, 1, -36)
	KeyBindContent.BackgroundTransparency = 1

	local KBLayout = Instance.new("UIListLayout", KeyBindContent)
	KBLayout.Padding = UDim.new(0, 1)
	KBLayout.SortOrder = Enum.SortOrder.LayoutOrder

	RefreshKeybindDisplay = function()
		if not KeyBindContent or not KeyBindContent.Parent then return end
		for _, child in ipairs(KeyBindContent:GetChildren()) do
			if not child:IsA("UIListLayout") then child:Destroy() end
		end
		local title = CurrentInputMode == "Controller" and "Controller Keybinds" or (CurrentInputMode == "Touch" and "Touch Controls" or "PC Keybinds")
		KeyBindTitle.Text = title
		for index, action in ipairs(ActionOrder) do
			local bindingText
			if CurrentInputMode == "Controller" then
				bindingText = FormatControllerBinding(ControllerActionBindings[action])
			elseif CurrentInputMode == "Touch" then
				bindingText = TouchBindingLabels[action] or action
			else
				bindingText = KeyboardBindings[action] and KeyboardBindings[action].Name or "None"
			end
			local label = Instance.new("TextLabel", KeyBindContent)
			RoundCorners(label, 3)
			label.LayoutOrder = index
			label.Size = UDim2.new(1, 0, 0, 20)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.SourceSansBold
			label.Text = bindingText .. " : " .. ActionLabels[action]
			label.TextColor3 = action == "Pause" and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(230, 230, 230)
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextSize = 15
		end
	end

	KeybindsButton.Activated:Connect(function()
		RefreshKeybindDisplay()
		KeyBindFrame.Visible = not KeyBindFrame.Visible
	end)

	local CreditButton = Instance.new("TextButton", MainFrame)
	RoundCorners(CreditButton, 3)
	CreditButton.LayoutOrder = 7
	CreditButton.Size = UDim2.new(0.9, 0, 0, 16)
	CreditButton.BackgroundTransparency = 1
	CreditButton.TextColor3 = Color3.fromRGB(190, 190, 190)
	CreditButton.Font = Enum.Font.SourceSans
	CreditButton.Text = "Original TAS by Tomato (@tomatotxt)"
	CreditButton.TextSize = 12
	CreditButton.AutoButtonColor = false
	CreditButton.Activated:Connect(function()
		if type(setclipboard) == "function" then
			pcall(setclipboard, "https://github.com/tomatotxt")
			notify("Tomato's GitHub link copied to clipboard", "TAS Credits", 2)
		else
			notify("Original TAS by Tomato - github.com/tomatotxt", "TAS Credits", 4)
		end
	end)

	SettingsFrame = Instance.new("Frame", HUD)
	RoundCorners(SettingsFrame, 4)
	SettingsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	SettingsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	SettingsFrame.Size = UDim2.new(0, 430, 0, 440)
	SettingsFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	SettingsFrame.BackgroundTransparency = 0.05
	SettingsFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
	SettingsFrame.BorderSizePixel = 2
	SettingsFrame.Visible = false

	local function resizeSettingsFrame()
		local camera = Workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
		local width = math.floor(math.clamp(viewport.X - 24, 300, 430))
		local height = math.floor(math.clamp(viewport.Y - 50, 300, 440))
		SettingsFrame.Size = UDim2.new(0, width, 0, height)
	end

	resizeSettingsFrame()
	if Workspace.CurrentCamera then
		table.insert(Connections, Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeSettingsFrame))
	end

	local SettingsHeader = Instance.new("Frame", SettingsFrame)
	RoundCorners(SettingsHeader, 4)
	SettingsHeader.Size = UDim2.new(1, 0, 0, 30)
	SettingsHeader.BackgroundTransparency = 1
	SettingsHeader.Active = true
	makeDraggable(SettingsFrame, SettingsHeader)

	local SettingsTitle = Instance.new("TextLabel", SettingsHeader)
	RoundCorners(SettingsTitle, 3)
	SettingsTitle.Size = UDim2.new(1, -40, 1, 0)
	SettingsTitle.Position = UDim2.new(0, 8, 0, 0)
	SettingsTitle.BackgroundTransparency = 1
	SettingsTitle.Font = Enum.Font.SourceSansBold
	SettingsTitle.Text = "TAS Settings - Original TAS by Tomato"
	SettingsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	SettingsTitle.TextSize = 18
	SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left

	local SettingsClose = Instance.new("TextButton", SettingsHeader)
	RoundCorners(SettingsClose, 3)
	SettingsClose.Size = UDim2.new(0, 26, 0, 24)
	SettingsClose.Position = UDim2.new(1, -30, 0, 3)
	SettingsClose.BackgroundColor3 = Color3.fromRGB(80, 50, 50)
	SettingsClose.TextColor3 = Color3.fromRGB(255, 255, 255)
	SettingsClose.Font = Enum.Font.SourceSansBold
	SettingsClose.Text = "X"
	SettingsClose.TextSize = 14
	SettingsClose.Activated:Connect(function()
		BindingCapture = nil
		SettingsFrame.Visible = false
		if CurrentInputMode == "Controller" then
			pcall(function() GuiService.SelectedObject = SettingsButton end)
		end
	end)

	local TabBar = Instance.new("Frame", SettingsFrame)
	RoundCorners(TabBar, 4)
	TabBar.Position = UDim2.new(0, 8, 0, 34)
	TabBar.Size = UDim2.new(1, -16, 0, 30)
	TabBar.BackgroundTransparency = 1

	local KeyboardTab = Instance.new("TextButton", TabBar)
	RoundCorners(KeyboardTab, 3)
	KeyboardTab.Size = UDim2.new(0.5, -3, 1, 0)
	KeyboardTab.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
	KeyboardTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	KeyboardTab.Font = Enum.Font.SourceSansBold
	KeyboardTab.Text = "Keyboard / PC"
	KeyboardTab.TextSize = 14

	local ControllerTab = Instance.new("TextButton", TabBar)
	RoundCorners(ControllerTab, 3)
	ControllerTab.Position = UDim2.new(0.5, 3, 0, 0)
	ControllerTab.Size = UDim2.new(0.5, -3, 1, 0)
	ControllerTab.BackgroundColor3 = Color3.fromRGB(75, 75, 75)
	ControllerTab.TextColor3 = Color3.fromRGB(255, 255, 255)
	ControllerTab.Font = Enum.Font.SourceSansBold
	ControllerTab.Text = "Controller"
	ControllerTab.TextSize = 14

	SettingsList = Instance.new("ScrollingFrame", SettingsFrame)
	RoundCorners(SettingsList, 4)
	SettingsList.Position = UDim2.new(0, 8, 0, 70)
	SettingsList.Size = UDim2.new(1, -16, 1, -116)
	SettingsList.BackgroundColor3 = Color3.fromRGB(42, 42, 42)
	SettingsList.BackgroundTransparency = 0.2
	SettingsList.BorderSizePixel = 0
	SettingsList.ScrollBarThickness = 5
	SettingsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	SettingsList.CanvasSize = UDim2.new()

	local SettingsLayout = Instance.new("UIListLayout", SettingsList)
	SettingsLayout.Padding = UDim.new(0, 4)
	SettingsLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local function StartBindingCapture(action, kind, button)
		BindingCapture = {Action = action, Kind = kind, Button = button, Started = os.clock()}
		button.Text = kind == "Keyboard" and "Press a key..." or "Hold L1/R1 + button"
	end

	RefreshSettingsRows = function()
		if not SettingsList or not SettingsList.Parent then return end
		BindingCapture = nil
		for _, child in ipairs(SettingsList:GetChildren()) do
			if not child:IsA("UIListLayout") then child:Destroy() end
		end
		KeyboardTab.BackgroundColor3 = SettingsTab == "Keyboard" and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(65, 65, 65)
		ControllerTab.BackgroundColor3 = SettingsTab == "Controller" and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(65, 65, 65)
		for index, action in ipairs(ActionOrder) do
			local row = Instance.new("Frame", SettingsList)
			RoundCorners(row, 4)
			row.LayoutOrder = index
			row.Size = UDim2.new(1, -8, 0, 32)
			row.BackgroundTransparency = 1

			local label = Instance.new("TextLabel", row)
			RoundCorners(label, 3)
			label.Size = UDim2.new(0.56, -4, 1, 0)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.SourceSans
			label.Text = ActionLabels[action]
			label.TextColor3 = Color3.fromRGB(235, 235, 235)
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left

			local bindButton = Instance.new("TextButton", row)
			RoundCorners(bindButton, 3)
			bindButton.Position = UDim2.new(0.56, 0, 0, 2)
			bindButton.Size = UDim2.new(0.44, -2, 1, -4)
			bindButton.BackgroundColor3 = Color3.fromRGB(72, 72, 72)
			bindButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			bindButton.Font = Enum.Font.SourceSansBold
			bindButton.TextSize = 13
			if SettingsTab == "Keyboard" then
				bindButton.Text = KeyboardBindings[action] and KeyboardBindings[action].Name or "None"
			else
				bindButton.Text = FormatControllerBinding(ControllerActionBindings[action])
			end
			bindButton.Activated:Connect(function()
				StartBindingCapture(action, SettingsTab, bindButton)
			end)
		end
	end

	KeyboardTab.Activated:Connect(function()
		SettingsTab = "Keyboard"
		RefreshSettingsRows()
	end)
	ControllerTab.Activated:Connect(function()
		SettingsTab = "Controller"
		RefreshSettingsRows()
	end)

	local SaveSettingsButton = Instance.new("TextButton", SettingsFrame)
	RoundCorners(SaveSettingsButton, 3)
	SaveSettingsButton.Position = UDim2.new(0, 8, 1, -40)
	SaveSettingsButton.Size = UDim2.new(0.5, -12, 0, 30)
	SaveSettingsButton.BackgroundColor3 = Color3.fromRGB(60, 90, 60)
	SaveSettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	SaveSettingsButton.Font = Enum.Font.SourceSansBold
	SaveSettingsButton.Text = "Save Settings"
	SaveSettingsButton.TextSize = 14
	SaveSettingsButton.Activated:Connect(function()
		SaveSettings(false)
	end)

	local ResetSettingsButton = Instance.new("TextButton", SettingsFrame)
	RoundCorners(ResetSettingsButton, 3)
	ResetSettingsButton.Position = UDim2.new(0.5, 4, 1, -40)
	ResetSettingsButton.Size = UDim2.new(0.5, -12, 0, 30)
	ResetSettingsButton.BackgroundColor3 = Color3.fromRGB(90, 65, 55)
	ResetSettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ResetSettingsButton.Font = Enum.Font.SourceSansBold
	ResetSettingsButton.Text = "Reset Defaults"
	ResetSettingsButton.TextSize = 14
	ResetSettingsButton.Activated:Connect(ResetBindingDefaults)

	SettingsButton.Activated:Connect(function()
		SettingsTab = CurrentInputMode == "Controller" and "Controller" or "Keyboard"
		RefreshSettingsRows()
		SettingsFrame.Visible = not SettingsFrame.Visible
		if SettingsFrame.Visible and CurrentInputMode == "Controller" then
			pcall(function() GuiService.SelectedObject = KeyboardTab end)
		end
	end)

	if UserInputService.TouchEnabled then
		TouchControlsButton = Instance.new("TextButton", MainFrame)
		RoundCorners(TouchControlsButton, 3)
		TouchControlsButton.LayoutOrder = 6
		TouchControlsButton.Size = UDim2.new(0.9, 0, 0, 20)
		TouchControlsButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		TouchControlsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		TouchControlsButton.Text = "Toggle Touch Controls"
		TouchControlsButton.Font = Enum.Font.SourceSansBold
		TouchControlsButton.TextSize = 14

		MobileControlsFrame = Instance.new("Frame", HUD)
		RoundCorners(MobileControlsFrame, 4)
		MobileControlsFrame.AnchorPoint = Vector2.new(1, 0.5)
		MobileControlsFrame.Position = UDim2.new(1, -8, 0.5, 0)
		MobileControlsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		MobileControlsFrame.BackgroundTransparency = 0.15
		MobileControlsFrame.BorderColor3 = Color3.fromRGB(200, 200, 200)
		MobileControlsFrame.BorderSizePixel = 2
		MobileControlsFrame.Visible = true

		local mobileTitle = Instance.new("TextLabel", MobileControlsFrame)
		RoundCorners(mobileTitle, 3)
		mobileTitle.Size = UDim2.new(1, -8, 0, 24)
		mobileTitle.Position = UDim2.new(0, 4, 0, 3)
		mobileTitle.BackgroundTransparency = 1
		mobileTitle.Font = Enum.Font.SourceSansBold
		mobileTitle.Text = "TAS Touch Controls"
		mobileTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
		mobileTitle.TextSize = 16
		mobileTitle.Active = true
		makeDraggable(MobileControlsFrame, mobileTitle)

		local function resizeMobileControls()
			local camera = Workspace.CurrentCamera
			local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
			local panelWidth = math.floor(math.clamp(viewport.X * 0.42, 240, 360))
			local panelHeight = math.floor(math.clamp(viewport.Y * 0.55, 245, 330))
			MobileControlsFrame.Size = UDim2.new(0, panelWidth, 0, panelHeight)
		end

		resizeMobileControls()
		if Workspace.CurrentCamera then
			table.insert(Connections, Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeMobileControls))
		end

		local mobileButtons = Instance.new("Frame", MobileControlsFrame)
		RoundCorners(mobileButtons, 4)
		mobileButtons.Position = UDim2.new(0, 6, 0, 31)
		mobileButtons.Size = UDim2.new(1, -12, 1, -37)
		mobileButtons.BackgroundTransparency = 1

		local grid = Instance.new("UIGridLayout", mobileButtons)
		grid.CellPadding = UDim2.new(0, 5, 0, 5)
		grid.CellSize = UDim2.new(1/3, -4, 0, 38)
		grid.FillDirectionMaxCells = 3
		grid.SortOrder = Enum.SortOrder.LayoutOrder

		local function addMobileButton(label, action, holdable)
			local button = Instance.new("TextButton", mobileButtons)
			RoundCorners(button, 3)
			button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			button.BackgroundTransparency = 0.1
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.Font = Enum.Font.SourceSansBold
			button.Text = label
			button.TextScaled = true
			button.TextWrapped = true
			if holdable then
				button.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
						if ActionRouter.Begin then ActionRouter.Begin(action, button) end
					end
				end)
				button.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
						if ActionRouter.End then ActionRouter.End(action, button) end
					end
				end)
			else
				button.Activated:Connect(function()
					if ActionRouter.Begin then ActionRouter.Begin(action, button) end
				end)
			end
			return button
		end

		for _, action in ipairs(ActionOrder) do
			local holdable = action == "GoFrameBack" or action == "GoFrameForward" or action == "SaveRun"
			addMobileButton(TouchBindingLabels[action], action, holdable)
		end

		TouchControlsButton.Activated:Connect(function()
			MobileControlsFrame.Visible = not MobileControlsFrame.Visible
		end)
	end

	RefreshKeybindDisplay()
	RefreshSettingsRows()
	if CurrentInputMode == "Controller" then
		pcall(function() GuiService.SelectedObject = SettingsButton end)
	end
end

local function SetCharacterState(InfoState)
	if not InfoState or type(InfoState) ~= "table" then return end
	if not InfoState.CF or type(InfoState.CF) ~= "table" then return end
	if not InfoState.V or type(InfoState.V) ~= "table" then return end
	if not InfoState.RV or type(InfoState.RV) ~= "table" then return end

	if not LocalPlayer.Character then return end
	local Root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
	if not Root then return end

	local charCF = QuatToCFrame(table.unpack(InfoState.CF))
	local vel = Vector3.new(table.unpack(InfoState.V))
	local rvel = Vector3.new(table.unpack(InfoState.RV))

	Root.CFrame = charCF
	for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Velocity = vel
			part.RotVelocity = rvel
		end
	end

	local hsName = type(InfoState.HS) == "number" and ValToStateName[InfoState.HS] or InfoState.HS
	if Hum and hsName and hsName ~= "None" then
		if Hum:GetState().Name ~= hsName then
			pcall(function() Hum:ChangeState(Enum.HumanoidStateType[hsName]) end)
		end
	end
end

local function UserPauseToggle()
	if ViewingTAS then return end
	Pause = not Pause
	getgenv().TAS_IsRecording = not Pause
	
	local Root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if Root then Root.Anchored = Pause end

	if Pause then
		TimePauseHolder = os.clock()
		if TimeTextLabel then TimeTextLabel.TextColor3 = Color3.fromRGB(255, 255, 0) end
	else
		if TimePauseHolder then
			TimePaused = TimePaused + (os.clock() - TimePauseHolder)
			TimePauseHolder = nil
		end
		if TimeTextLabel then TimeTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255) end
	end
	updateStatusColor()
end

local function AddSavestate()
	local stateCopy = DeepCopy(PlayerInfo)
	table.insert(Savestates, stateCopy)
	PlayerInfo = {}
	UpdateGUIText()
	notify("Savestate Added", "TAS", 1)
end

local function RemoveSavestate()
	if #Savestates > 1 then
		table.remove(Savestates)
		local lastSegment = Savestates[#Savestates]
		if lastSegment and #lastSegment > 0 then
			local lastFrame = lastSegment[#lastSegment]
			PlayerInfo = {}
			Pause = true
			getgenv().TAS_IsRecording = false
			
			TimeStart = os.clock() - lastFrame.T
			TimePaused = 0
			TimePauseHolder = os.clock() 
			
			SetCharacterState(lastFrame)
			UpdateTimeGUI()
		end
		UpdateGUIText()
		notify("Savestate Removed", "TAS", 1)
	else
		notify("Cannot remove initial state", "TAS", 1)
	end
	updateStatusColor()
end

local function EnterSavestate()
	if #Savestates > 0 then
		local lastSegment = table.remove(Savestates)
		PlayerInfo = lastSegment
		local lastFrame = PlayerInfo[#PlayerInfo]
		if lastFrame then
			Pause = true
			getgenv().TAS_IsRecording = false
			SetCharacterState(lastFrame)
			
			TimeStart = os.clock() - lastFrame.T
			TimePaused = 0
			TimePauseHolder = os.clock()
			
			UpdateGUIText()
			UpdateTimeGUI()
			updateStatusColor()
			notify("Entered Last Savestate (Edited)", "TAS", 2)
		end
	else
		notify("No Savestates to enter!", "TAS", 1)
	end
end

local function BackSavestate()
	if #Savestates > 0 then
		local lastStateList = Savestates[#Savestates]
		if lastStateList and #lastStateList > 0 then
			local InfoState = lastStateList[#lastStateList]
			PlayerInfo = {}
			Pause = true
			getgenv().TAS_IsRecording = false
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
				LocalPlayer.Character.HumanoidRootPart.Anchored = true
			end
			
			TimeStart = os.clock() - InfoState.T
			TimePaused = 0
			TimePauseHolder = os.clock()
			
			SetCharacterState(InfoState)
			updateStatusColor()
			UpdateTimeGUI()
		end
	end
end

local function GoFrameForward()
	if Pause then
		local CurrentFrameCount = #PlayerInfo
		UserPauseToggle()
		repeat RunService.Heartbeat:Wait() until #PlayerInfo > CurrentFrameCount
		UserPauseToggle()
	end
end

local function GoFrameBack()
	if not LocalPlayer.Character then return end
	local TargetFrameInfo = nil
	
	if #PlayerInfo > 1 then
		TargetFrameInfo = PlayerInfo[#PlayerInfo - 1]
		PlayerInfo[#PlayerInfo] = nil
	end

	if TargetFrameInfo then
		if not Pause then 
			Pause = true 
			getgenv().TAS_IsRecording = false
			if LocalPlayer.Character.HumanoidRootPart then 
				LocalPlayer.Character.HumanoidRootPart.Anchored = true 
			end
		end
		
		TimeStart = os.clock() - TargetFrameInfo.T
		TimePaused = 0
		TimePauseHolder = os.clock()
		
		SetCharacterState(TargetFrameInfo)
		UpdateTimeGUI()
		UpdateGUIText()
		updateStatusColor()
	end
end

local heldInputs = {}
local function handleHold(key, action)
	local pressId = os.clock()
	heldInputs[key] = pressId
	action()
	task.wait(0.2)
	while heldInputs[key] == pressId do
		action()
		task.wait(1/50)
	end
end

local function GetFileName(overrideName)
	if overrideName and overrideName ~= "" then
		local name = overrideName:gsub("^%s*(.-)%s*$", "%1")
		if not name:match("%.json$") and not name:match("%.tas$") then name = name .. ".tas" end
		return name
	end
	local rawName = TASNameBox and TASNameBox.Text or "Untitled"
	local cleanName = rawName:gsub("%p", ""):gsub("^%s*(.-)%s*$", "%1")
	if cleanName == "" then cleanName = "Untitled" end
	return cleanName .. ".tas"
end

local FRAME_PACK_FMT_V3 = "<f B " .. string.rep("f", 20)
local FRAME_PACK_FMT_V2 = "<f B " .. string.rep("f", 18)
local FRAME_PACK_FMT_V1 = "<f B " .. string.rep("f", 30)

local function PackFrame(frame)
	return string.pack(FRAME_PACK_FMT_V3,
		frame.T, frame.HS,
		frame.V[1], frame.V[2], frame.V[3],
		frame.RV[1], frame.RV[2], frame.RV[3],
		frame.CF[1], frame.CF[2], frame.CF[3], frame.CF[4], frame.CF[5], frame.CF[6], frame.CF[7],
		frame.CCF[1], frame.CCF[2], frame.CCF[3], frame.CCF[4], frame.CCF[5], frame.CCF[6], frame.CCF[7]
	)
end

local function UnpackFrameV3(data, pos)
	local t, hs, v1, v2, v3, rv1, rv2, rv3,
		cf1, cf2, cf3, cf4, cf5, cf6, cf7,
		ccf1, ccf2, ccf3, ccf4, ccf5, ccf6, ccf7,
		nextPos = string.unpack(FRAME_PACK_FMT_V3, data, pos)

	return {
		T = t, HS = hs,
		V = {v1, v2, v3}, RV = {rv1, rv2, rv3},
		CF = {cf1, cf2, cf3, cf4, cf5, cf6, cf7},
		CCF = {ccf1, ccf2, ccf3, ccf4, ccf5, ccf6, ccf7}
	}, nextPos
end

local function UnpackFrameV2(data, pos)
	local t, hs, v1, v2, v3, rv1, rv2, rv3,
		cf1, cf2, cf3, cf4, cf5, cf6,
		ccf1, ccf2, ccf3, ccf4, ccf5, ccf6,
		nextPos = string.unpack(FRAME_PACK_FMT_V2, data, pos)

	local cf = CFrame.new(cf1, cf2, cf3) * CFrame.fromEulerAnglesYXZ(cf4, cf5, cf6)
	local ccf = CFrame.new(ccf1, ccf2, ccf3) * CFrame.fromEulerAnglesYXZ(ccf4, ccf5, ccf6)
	local qX, qY, qZ, qW = CFrameToQuat(cf)
	local cqX, cqY, cqZ, cqW = CFrameToQuat(ccf)

	return {
		T = t, HS = hs,
		V = {v1, v2, v3}, RV = {rv1, rv2, rv3},
		CF = {cf.X, cf.Y, cf.Z, qX, qY, qZ, qW},
		CCF = {ccf.X, ccf.Y, ccf.Z, cqX, cqY, cqZ, cqW}
	}, nextPos
end

local function UnpackFrameV1(data, pos)
	local t, hs, v1, v2, v3, rv1, rv2, rv3,
		cf1, cf2, cf3, cf4, cf5, cf6, cf7, cf8, cf9, cf10, cf11, cf12,
		ccf1, ccf2, ccf3, ccf4, ccf5, ccf6, ccf7, ccf8, ccf9, ccf10, ccf11, ccf12,
		nextPos = string.unpack(FRAME_PACK_FMT_V1, data, pos)

	local cf = CFrame.new(cf1, cf2, cf3, cf4, cf5, cf6, cf7, cf8, cf9, cf10, cf11, cf12)
	local ccf = CFrame.new(ccf1, ccf2, ccf3, ccf4, ccf5, ccf6, ccf7, ccf8, ccf9, ccf10, ccf11, ccf12)
	local qX, qY, qZ, qW = CFrameToQuat(cf)
	local cqX, cqY, cqZ, cqW = CFrameToQuat(ccf)

	return {
		T = t, HS = hs,
		V = {v1, v2, v3}, RV = {rv1, rv2, rv3},
		CF = {cf.X, cf.Y, cf.Z, qX, qY, qZ, qW},
		CCF = {ccf.X, ccf.Y, ccf.Z, cqX, cqY, cqZ, cqW}
	}, nextPos
end

local function SaveRun()
	if not writefile then notify("Executor does not support writefile!", "Error"); return end
	local fileName = GetFileName()
	local success, err = pcall(function()
		local chunks = {}
		table.insert(chunks, string.pack("<c4 B", "TASB", 3))

		table.insert(chunks, string.pack("<I4", #Savestates))
		for _, stateList in ipairs(Savestates) do
			table.insert(chunks, string.pack("<I4", #stateList))
			for _, frame in ipairs(stateList) do
				table.insert(chunks, PackFrame(frame))
			end
		end

		table.insert(chunks, string.pack("<I4", #PlayerInfo))
		for _, frame in ipairs(PlayerInfo) do
			table.insert(chunks, PackFrame(frame))
		end

		local binData = table.concat(chunks)

		EnsureStorage()
		writefile(GetRunPath(fileName), binData)
	end)
	
	if success then notify("Saved " .. fileName, "Success")
	else notify("Save Failed: " .. tostring(err), "Error") end
end

local function SaveRunJSON()
	if not writefile then notify("Executor does not support writefile!", "Error"); return end
	local Data = {Savestates, PlayerInfo}
	local fileName = GetFileName():gsub("%.tas$", ".json")
	local success, err = pcall(function()
		local Encoded = __lt.cm("HttpService", "JSONEncode", Data)
		EnsureStorage()
		writefile(GetRunPath(fileName), Encoded)
	end)
	if success then notify("Saved JSON " .. fileName, "Success")
	else notify("JSON Save Failed: " .. tostring(err), "Error") end
end

local function LoadRun(overrideName)
	if type(overrideName) ~= "string" then overrideName = nil end
	if not readfile then notify("Executor does not support readfile!", "Error"); return false end
	
	local fileName = GetFileName(overrideName)
	local runPath = GetRunPath(fileName)
	if not isfile(runPath) then
		fileName = fileName:gsub("%.tas$", ".json")
		runPath = GetRunPath(fileName)
		if not isfile(runPath) then
			notify("File not found!", "Error")
			return false
		end
	end
	
	local success, err = pcall(function()
		local content = readfile(runPath)

		if content:sub(1, 4) == "TASB" then
			local magic, version, pos = string.unpack("<c4 B", content)
			
			local unpackerFunc = nil
			if version == 3 then unpackerFunc = UnpackFrameV3
			elseif version == 2 then unpackerFunc = UnpackFrameV2
			elseif version == 1 then unpackerFunc = UnpackFrameV1
			else error("Unsupported TAS binary version") end

			local numSavestates
			numSavestates, pos = string.unpack("<I4", content, pos)
			Savestates = table.create and table.create(numSavestates) or {}
			
			for i = 1, numSavestates do
				local numFrames
				numFrames, pos = string.unpack("<I4", content, pos)
				local stateList = table.create and table.create(numFrames) or {}
				for j = 1, numFrames do
					stateList[j], pos = unpackerFunc(content, pos)
				end
				Savestates[i] = stateList
			end

			local numPlayerFrames
			numPlayerFrames, pos = string.unpack("<I4", content, pos)
			PlayerInfo = table.create and table.create(numPlayerFrames) or {}
			for i = 1, numPlayerFrames do
				PlayerInfo[i], pos = unpackerFunc(content, pos)
			end

		elseif content:sub(1, 1) == "[" or content:sub(1, 1) == "{" then
			local loadedTAS = __lt.cm("HttpService", "JSONDecode", content)
			if type(loadedTAS) ~= "table" or type(loadedTAS[1]) ~= "table" or type(loadedTAS[2]) ~= "table" then 
				error("Invalid TAS file format") 
			end
			
			local function convertLegacy(frames)
				for _, f in ipairs(frames) do
					if type(f.CF) == "table" then
						if #f.CF == 12 then
							local cf = CFrame.new(table.unpack(f.CF))
							local qX, qY, qZ, qW = CFrameToQuat(cf)
							f.CF = {cf.X, cf.Y, cf.Z, qX, qY, qZ, qW}
						elseif #f.CF == 6 then
							local cf = CFrame.new(f.CF[1], f.CF[2], f.CF[3]) * CFrame.fromEulerAnglesYXZ(f.CF[4], f.CF[5], f.CF[6])
							local qX, qY, qZ, qW = CFrameToQuat(cf)
							f.CF = {cf.X, cf.Y, cf.Z, qX, qY, qZ, qW}
						end
					end
					if type(f.CCF) == "table" then
						if #f.CCF == 12 then
							local ccf = CFrame.new(table.unpack(f.CCF))
							local cqX, cqY, cqZ, cqW = CFrameToQuat(ccf)
							f.CCF = {ccf.X, ccf.Y, ccf.Z, cqX, cqY, cqZ, cqW}
						elseif #f.CCF == 6 then
							local ccf = CFrame.new(f.CCF[1], f.CCF[2], f.CCF[3]) * CFrame.fromEulerAnglesYXZ(f.CCF[4], f.CCF[5], f.CCF[6])
							local cqX, cqY, cqZ, cqW = CFrameToQuat(ccf)
							f.CCF = {ccf.X, ccf.Y, ccf.Z, cqX, cqY, cqZ, cqW}
						end
					end
				end
			end
			
			Savestates = loadedTAS[1]
			for _, st in ipairs(Savestates) do convertLegacy(st) end
			
			PlayerInfo = loadedTAS[2]
			convertLegacy(PlayerInfo)
		else
			error("Unrecognized or corrupted TAS file format.")
		end

		TimeStart = os.clock()
		TimePaused = 0
		TimePauseHolder = os.clock()
		
		Pause = true
		getgenv().TAS_IsRecording = false
		
		UpdateGUIText()
		UpdateTimeGUI()
		updateStatusColor()
	end)
	
	if success then 
		notify("Loaded " .. fileName, "Success") 
		return true
	else 
		notify("Load Failed: " .. tostring(err), "Error") 
		return false
	end
end

local function ViewTASPlayback()
	if ViewingTAS then return end
	
	local FlatFrames = {}
	for _, state in ipairs(Savestates) do
		for _, frame in ipairs(state) do table.insert(FlatFrames, frame) end
	end
	for _, frame in ipairs(PlayerInfo) do table.insert(FlatFrames, frame) end
	
	if #FlatFrames == 0 then 
		notify("No frames to play!", "Error")
		if AutoLoadAndPlayFile and AutoLoadAndPlayFile ~= "" then DisconnectAll() end
		return 
	end

	local FullFrames = FlatFrames

	if ExtremeSmoothing then
		local smoothedFrames = {}
		local interval = 1 / math.max(0.001, TargetSmoothingFPS)
		local nextTargetTime = 0
		
		for i, frame in ipairs(FlatFrames) do
			if frame.T >= nextTargetTime or i == 1 or i == #FlatFrames then
				table.insert(smoothedFrames, frame)
				nextTargetTime = frame.T + interval
			end
		end
		FlatFrames = smoothedFrames
	end

	ViewingTAS = true
	getgenv().TAS_IsRecording = false 
	getgenv().TAS_IsPlaying = true 
	
	ActivePlaybackFrames = FlatFrames
	CurrentPlaybackIndex = 1
	
	updateStatusColor()
	notify("Starting Playback...", "TAS")
	
	local Character = LocalPlayer.Character
	local Root = Character and Character:FindFirstChild("HumanoidRootPart")
	local Humanoid = Character and Character:FindFirstChild("Humanoid")

	if not Root then 
		ViewingTAS = false
		getgenv().TAS_IsPlaying = false
		ActivePlaybackFrames = nil
		if AutoLoadAndPlayFile and AutoLoadAndPlayFile ~= "" then DisconnectAll() end
		return 
	end

	Root.Anchored = false 
	
	if Humanoid then
		for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
			if not KeepEnabledStates[state] then
				pcall(function() Humanoid:SetStateEnabled(state, false) end)
			end
		end
	end
	
	local StartPlay = os.clock()
	local CurrentIndex = 1
	local FullCurrentIndex = 1
	
	if PlayConn then PlayConn:Disconnect() end
	
	PlayConn = RunService.Heartbeat:Connect(function()
		if not Character or not Character.Parent or not Root or not Root.Parent or (Humanoid and Humanoid.Health <= 0) then
			return 
		end
		
		local Elapsed = os.clock() - StartPlay
		
		while CurrentIndex < #FlatFrames and FlatFrames[CurrentIndex + 1] and FlatFrames[CurrentIndex + 1].T <= Elapsed do
			CurrentIndex = CurrentIndex + 1
			CurrentPlaybackIndex = CurrentIndex
		end
		
		while FullCurrentIndex < #FullFrames and FullFrames[FullCurrentIndex + 1] and FullFrames[FullCurrentIndex + 1].T <= Elapsed do
			FullCurrentIndex = FullCurrentIndex + 1
		end
		
		local FrameA = FlatFrames[CurrentIndex]
		local FrameB = FlatFrames[CurrentIndex + 1]
		local StateFrame = FullFrames[FullCurrentIndex]
		
		if FrameB and type(FrameA) == "table" and type(FrameB) == "table" and FrameA.CF and FrameB.CF and FrameA.V and FrameB.V and FrameA.RV and FrameB.RV then
			local Delta = FrameB.T - FrameA.T
			local Alpha = 0
			if Delta > 0 then Alpha = (Elapsed - FrameA.T) / Delta end
			Alpha = math.clamp(Alpha, 0, 1)
			
			local cfA = QuatToCFrame(table.unpack(FrameA.CF))
			local cfB = QuatToCFrame(table.unpack(FrameB.CF))
			
			local velA = Vector3.new(table.unpack(FrameA.V))
			local velB = Vector3.new(table.unpack(FrameB.V))
			local rvelA = Vector3.new(table.unpack(FrameA.RV))
			local rvelB = Vector3.new(table.unpack(FrameB.RV))
			
			Root.CFrame = cfA:Lerp(cfB, Alpha)
			
			if PlaybackCamera and type(FrameA.CCF) == "table" and type(FrameB.CCF) == "table" then
				local camA = QuatToCFrame(table.unpack(FrameA.CCF))
				local camB = QuatToCFrame(table.unpack(FrameB.CCF))
				Workspace.CurrentCamera.CFrame = camA:Lerp(camB, Alpha)
			end
			
			local curV = velA:Lerp(velB, Alpha)
			local curRV = rvelA:Lerp(rvelB, Alpha)
			for _, part in ipairs(Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Velocity = curV
					part.RotVelocity = curRV
				end
			end

			if Humanoid and StateFrame and StateFrame.HS then
				local targetStateName = type(StateFrame.HS) == "number" and ValToStateName[StateFrame.HS] or StateFrame.HS
				
				if targetStateName and targetStateName ~= "None" then
					local currentState = Humanoid:GetState().Name
					if currentState ~= targetStateName then
						local targetStateEnum = Enum.HumanoidStateType[targetStateName]
						if targetStateEnum then
							pcall(function() Humanoid:ChangeState(targetStateEnum) end)
						end
					end
				end
			end
		else
			if AutoLoadAndPlayFile and AutoLoadAndPlayFile ~= "" then
				DisconnectAll()
				return
			end
			
			PlayConn:Disconnect()
			PlayConn = nil
			ViewingTAS = false
			getgenv().TAS_IsPlaying = false 
			Pause = true
			Root.Anchored = true
			ActivePlaybackFrames = nil
			CurrentPlaybackIndex = 1
			
			if Humanoid then
				for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
					pcall(function() Humanoid:SetStateEnabled(state, true) end)
				end
				pcall(function()
					if Humanoid:GetState() ~= Enum.HumanoidStateType.GettingUp then
						Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
					end
				end)
			end

			updateStatusColor()
			notify("Playback Finished", "TAS")
		end
	end)
end

local function CollisionToggler()
	local target = Mouse.Target
	if not target then
		local camera = Workspace.CurrentCamera
		if camera then
			local viewport = camera.ViewportSize
			local ray = camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = LocalPlayer.Character and {LocalPlayer.Character} or {}
			local result = __lt.cm("Workspace", "Raycast", ray.Origin, ray.Direction * 1000, params)
			target = result and result.Instance or nil
		end
	end
	if target and target:IsA("BasePart") then
		target.CanCollide = not target.CanCollide
		target.Transparency = target.CanCollide and 0 or 0.5
	end
end

local function GetActionToken(action, source)
	return action .. ":" .. tostring(source)
end

ActionRouter.Begin = function(action, source)
	if action == "Pause" then
		UserPauseToggle()
	elseif action == "AddSavestate" then
		AddSavestate()
	elseif action == "RemoveSavestate" then
		RemoveSavestate()
	elseif action == "EnterSavestate" then
		EnterSavestate()
	elseif action == "BackSavestate" then
		BackSavestate()
	elseif action == "CollisionToggler" then
		CollisionToggler()
	elseif action == "ViewTAS" then
		ViewTASPlayback()
	elseif action == "LoadRun" then
		LoadRun()
	elseif action == "ResetToNormal" then
		DisconnectAll()
	elseif action == "DebugToggler" then
		ToggleDebugView()
	elseif action == "ToggleVelocityVis" then
		ShowVelocityDuringRecording = not ShowVelocityDuringRecording
		notify("Velocity Visualizer: " .. (ShowVelocityDuringRecording and "ON" or "OFF"), "TAS Tools", 1)
	elseif action == "SaveRun" then
		local token = GetActionToken(action, source)
		local pressId = os.clock()
		heldInputs[token] = pressId
		task.delay(0.5, function()
			if heldInputs[token] == pressId then
				SaveRunJSON()
				heldInputs[token] = nil
			end
		end)
	elseif action == "GoFrameForward" then
		local token = GetActionToken(action, source)
		task.spawn(function() handleHold(token, GoFrameForward) end)
	elseif action == "GoFrameBack" then
		local token = GetActionToken(action, source)
		task.spawn(function() handleHold(token, GoFrameBack) end)
	end
end

ActionRouter.End = function(action, source)
	local token = GetActionToken(action, source)
	if action == "SaveRun" and heldInputs[token] then
		SaveRun()
	end
	heldInputs[token] = nil
end

local function EndControllerModifierActions(modifier)
	for key, data in pairs(ControllerActiveActions) do
		if data.Modifier == modifier then
			ActionRouter.End(data.Action, data.Source)
			ControllerActiveActions[key] = nil
		end
	end
end

local function ControllerActionHandler(_, inputState, inputObject)
	local key = inputObject.KeyCode
	if BindingCapture and BindingCapture.Kind == "Controller" then
		if inputState == Enum.UserInputState.Begin and os.clock() - BindingCapture.Started > 0.1 then
			local modifier = ControllerModifiers.L1 and Enum.KeyCode.ButtonL1 or (ControllerModifiers.R1 and Enum.KeyCode.ButtonR1 or nil)
			if not modifier then
				notify("Hold L1 or R1, then press the button you want", "TAS Settings", 2)
				return Enum.ContextActionResult.Sink
			end
			local action = BindingCapture.Action
			local conflict = FindControllerConflict(action, modifier, key)
			if conflict then
				notify("Already used by " .. ActionLabels[conflict], "TAS Settings", 2)
			else
				ControllerActionBindings[action] = {Modifier = modifier, Key = key}
				RebuildControllerBindings()
				BindingCapture = nil
				SaveSettings(true)
				RefreshSettingsRows()
				RefreshKeybindDisplay()
			end
		end
		return Enum.ContextActionResult.Sink
	end
	if inputState == Enum.UserInputState.Begin then
		if GuiService.SelectedObject and not ControllerModifiers.L1 and not ControllerModifiers.R1 then
			return Enum.ContextActionResult.Pass
		end
		local modifier
		if ControllerModifiers.L1 and ControllerBindings.L1[key] then
			modifier = "L1"
		elseif ControllerModifiers.R1 and ControllerBindings.R1[key] then
			modifier = "R1"
		elseif ControllerBindings.None[key] then
			modifier = "None"
		end
		if modifier then
			local action = ControllerBindings[modifier][key]
			local source = "Controller:" .. modifier .. ":" .. key.Name
			ControllerActiveActions[key] = {Action = action, Modifier = modifier, Source = source}
			ActionRouter.Begin(action, source)
			return Enum.ContextActionResult.Sink
		end
	elseif inputState == Enum.UserInputState.End then
		local data = ControllerActiveActions[key]
		if data then
			ActionRouter.End(data.Action, data.Source)
			ControllerActiveActions[key] = nil
			return Enum.ContextActionResult.Sink
		end
	elseif ControllerActiveActions[key] then
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

DisconnectAll = function()
	pcall(function() __lt.cm("ContextActionService", "UnbindAction", ControllerActionName) end)
	pcall(function() GuiService.SelectedObject = nil end)
	BindingCapture = nil
	ControllerModifiers.L1 = false
	ControllerModifiers.R1 = false
	ControllerActiveActions = {}
	if PlayConn then 
		PlayConn:Disconnect()
		PlayConn = nil 
	end
	
	if TrajectoryFolder then
		TrajectoryFolder:Destroy()
		TrajectoryFolder = nil
	end
	TrajectoryLines = {}
	PathLines = {}
	
	ViewingTAS = false
	Pause = true
	ActivePlaybackFrames = nil
	CurrentPlaybackIndex = 1
	
	for _, c in pairs(Connections) do c:Disconnect() end
	for _, c in pairs(CharConnections) do c:Disconnect() end
	if HUD then HUD:Destroy() end
	if DebugView then ToggleDebugView() end
	
	local char = LocalPlayer.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then 
			root.Anchored = false
			root.Velocity = Vector3.zero 
			root.RotVelocity = Vector3.zero
		end
		
		local hum = char:FindFirstChild("Humanoid")
		if hum then
			for _, state in ipairs(Enum.HumanoidStateType:GetEnumItems()) do
				pcall(function() hum:SetStateEnabled(state, true) end)
			end
			pcall(function()
				if hum:GetState() ~= Enum.HumanoidStateType.GettingUp then
					hum:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end)
		end
	end

	getgenv().TAS_Recorder_Running = false
	getgenv().TAS_IsRecording = false
	getgenv().TAS_IsPlaying = false
	notify("TAS Recorder Unloaded", "TAS")
end
getgenv().TAS_Recorder_Disconnect = DisconnectAll

local function SetupCharacterConnections(char)
	for _, c in pairs(CharConnections) do c:Disconnect() end
	CharConnections = {}

	if not char then return end
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end
	
	local diedHandled = false
	
	table.insert(CharConnections, hum.Died:Connect(function()
		if diedHandled then return end
		diedHandled = true
		
		local wasPlaying = getgenv().TAS_IsPlaying
		
		Pause = true
		getgenv().TAS_IsRecording = false
		getgenv().TAS_IsPlaying = false
		ViewingTAS = false
		
		if PlayConn then
			PlayConn:Disconnect()
			PlayConn = nil
		end
		
		ActivePlaybackFrames = nil
		CurrentPlaybackIndex = 1
		
		if AutoLoadAndPlayFile and AutoLoadAndPlayFile ~= "" and wasPlaying then
			DisconnectAll()
			return
		end
		
		updateStatusColor()
		notify("Character Died! Paused. Waiting for Respawn...", "TAS Warning", 5)
		
		task.spawn(function()
			local newChar = LocalPlayer.CharacterAdded:Wait()
			local newRoot = newChar:WaitForChild("HumanoidRootPart", 10)
			task.wait(0.5) 
			
			local lastState = nil
			if #PlayerInfo > 0 then
				lastState = PlayerInfo[#PlayerInfo]
			elseif #Savestates > 0 then
				local lastList = Savestates[#Savestates]
				if lastList and #lastList > 0 then
					lastState = lastList[#lastList]
				end
			end
			
			if lastState then
				SetCharacterState(lastState)
				notify("Restored Position. Press '8' to Undo death, or Unpause to continue.", "TAS System", 8)
			end
			
			Pause = true
			if newRoot then newRoot.Anchored = true end
			updateStatusColor()
		end)
	end))
end

local function Initialize()
	LoadSettings()
	local okLastInput, lastInput = pcall(function() return __lt.cm("UserInputService", "GetLastInputType") end)
	if okLastInput and lastInput then CurrentInputMode = InputModeFromType(lastInput) end
	Savestates = {}
	PlayerInfo = {}
	TimePaused = 0
	Pause = true
	getgenv().TAS_IsRecording = false
	getgenv().TAS_IsPlaying = false
	TimeStart = os.clock()
	TimePauseHolder = os.clock()
	LastRecordTime = os.clock()
	
	local initialData = ReturnPlayerInfo()
	initialData.T = 0
	table.insert(Savestates, {initialData})
	
	TrajectoryFolder = Instance.new("Folder")
	TrajectoryFolder.Name = "TAS_Trajectory"
	TrajectoryFolder.Parent = __lt.cm("Workspace", "FindFirstChild", "Terrain") or Workspace
	
	local isAuto = (AutoLoadAndPlayFile and AutoLoadAndPlayFile ~= "")
	if not isAuto then
		SetUpGui()
		updateStatusColor()
	end
	
	table.insert(Connections, RunService.Heartbeat:Connect(function()
		local shouldShowVel = (not ViewingTAS and ShowVelocityDuringRecording) or (ViewingTAS and ShowVelocityDuringPlayback)
		if shouldShowVel then
			local now = os.clock()
			if now - LastTrajectoryUpdate >= 1/15 then
				LastTrajectoryUpdate = now
				
				local char = LocalPlayer.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChild("Humanoid")
				
				if root and hum and (root.Velocity.Magnitude > 0.5 or hum.MoveDirection.Magnitude > 0.1) then
					local p = root.Position
					local v = root.Velocity
					local dt240 = 1 / 240
					local grav = Vector3.new(0, -196.2, 0)
					
					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Exclude
					rayParams.FilterDescendantsInstances = {char}
					rayParams.RespectCanCollide = true
					
					local points = {p}
					local velocities = {v}
					
					local charRot = root.CFrame.Rotation
					local floorBox = Vector3.new(1.5, 0.2, 1.5) 
					local wallBox = Vector3.new(1.5, 4.5, 1.5)  
					local feetOffset = Vector3.new(0, -3.1, 0)
					local walkSpeed = hum.WalkSpeed
					
					local targetDir = hum.MoveDirection
					local isHoldingJump = false
					
					if ViewingTAS then
						local flatV = Vector3.new(v.X, 0, v.Z)
						if flatV.Magnitude > 0.5 then targetDir = flatV.Unit else targetDir = Vector3.zero end
						isHoldingJump = false
					else
						isHoldingJump = __lt.cm("UserInputService", "IsKeyDown", Enum.KeyCode.Space) or hum.Jump
					end
					
					local targetVXZ = targetDir * walkSpeed
					local jumpVelocity = 50
					pcall(function()
						if hum.UseJumpPower then jumpVelocity = hum.JumpPower
						else jumpVelocity = math.sqrt(2 * Workspace.Gravity * hum.JumpHeight) end
					end)
					
					local airAccelStep = 0.59584 * (walkSpeed / 16)
					local groundFactorTarget = 0.625
					local groundFactorCurrent = 0.375
					
					local jumpTimer = 0
					local currentState = hum:GetState()
					if currentState == Enum.HumanoidStateType.Freefall or currentState == Enum.HumanoidStateType.Jumping or currentState == Enum.HumanoidStateType.FallingDown then
						jumpTimer = 15
					end
					if v.Y > 10 then jumpTimer = 15 end
					
					for frame = 1, MaxTrajectoryFrames do
						local hitSomething = false
						for step = 1, 4 do
							local currVXZ = Vector3.new(v.X, 0, v.Z)
							local floorHit = nil
							
							if jumpTimer == 0 then
								floorHit = __lt.cm("Workspace", "Blockcast", CFrame.new(p) * charRot, floorBox, feetOffset, rayParams)
							end
							
							if floorHit then
								currVXZ = (currVXZ * groundFactorCurrent) + (targetVXZ * groundFactorTarget)
								if isHoldingJump then
									v = Vector3.new(currVXZ.X, jumpVelocity, currVXZ.Z)
									jumpTimer = 15
								else
									local normal = floorHit.Normal
									v = currVXZ - (currVXZ:Dot(normal) * normal)
								end
							else
								if jumpTimer > 0 then jumpTimer = jumpTimer - 1 end
								local diff = targetVXZ - currVXZ
								if diff.Magnitude > 0 then
									local accelStep = math.min(diff.Magnitude, airAccelStep)
									currVXZ = currVXZ + (diff.Unit * accelStep)
								end
								v = Vector3.new(currVXZ.X, v.Y, currVXZ.Z) + (grav * dt240)
							end
							
							local stepVec = v * dt240
							if stepVec.Magnitude > 0.0001 then
								local hitCenter = __lt.cm("Workspace", "Blockcast", CFrame.new(p) * charRot, wallBox, stepVec, rayParams)
								if hitCenter then
									p = p + (stepVec.Unit * hitCenter.Distance)
									hitSomething = true
									break
								else
									p = p + stepVec
								end
							end
						end
						
						table.insert(points, p)
						table.insert(velocities, v)
						if hitSomething then break end
						if (not isHoldingJump) and v.Magnitude <= 1 and targetVXZ.Magnitude < 0.5 then break end
					end
					
					local ws = hum.WalkSpeed > 0 and hum.WalkSpeed or 16
					for i = 1, #points - 1 do
						local line = TrajectoryLines[i]
						if not line then
							line = Instance.new("CylinderHandleAdornment")
							line.Radius = 0.08; line.ZIndex = 5; line.AlwaysOnTop = false
							line.Adornee = Workspace.Terrain; line.Parent = TrajectoryFolder
							TrajectoryLines[i] = line
						end
						
						local p1, p2 = points[i], points[i+1]
						local length = (p2 - p1).Magnitude
						local mag = velocities[i].Magnitude
						
						if length > 0.001 then
							line.Height = length
							line.CFrame = CFrame.lookAt(p1 + (p2 - p1) / 2, p2)
							local cG = Color3.new(0, 1, 0); local cY = Color3.new(1, 1, 0); local cR = Color3.new(1, 0, 0)
							if mag <= ws then line.Color3 = cG:Lerp(cY, mag / ws)
							else line.Color3 = cY:Lerp(cR, math.clamp((mag - ws) / ws, 0, 1)) end
							line.Visible = true
						else
							line.Visible = false
						end
					end
					for i = #points, #TrajectoryLines do TrajectoryLines[i].Visible = false end
				else
					for _, line in ipairs(TrajectoryLines) do line.Visible = false end
				end
			end
		else
			for _, line in ipairs(TrajectoryLines) do line.Visible = false end
		end
		
		if ViewingTAS and ShowTASPathDuringPlayback and ActivePlaybackFrames then
			local frames = ActivePlaybackFrames
			local startIdx = CurrentPlaybackIndex
			local maxFrames = math.min(#frames, startIdx + 1200) 
			
			local lineIndex = 1
			for i = startIdx, maxFrames - 1 do
				if type(frames[i]) == "table" and type(frames[i].CF) == "table" and type(frames[i+1]) == "table" and type(frames[i+1].CF) == "table" then
					local p1 = Vector3.new(frames[i].CF[1], frames[i].CF[2], frames[i].CF[3])
					local p2 = Vector3.new(frames[i+1].CF[1], frames[i+1].CF[2], frames[i+1].CF[3])
					local dist = (p2 - p1).Magnitude
					
					if dist > 0.005 then 
						local line = PathLines[lineIndex]
						if not line then
							line = Instance.new("CylinderHandleAdornment")
							line.Radius = 0.06; line.Color3 = Color3.fromRGB(0, 200, 255); line.Transparency = 0.2
							line.ZIndex = 4; line.AlwaysOnTop = false; line.Adornee = Workspace.Terrain; line.Parent = TrajectoryFolder
							PathLines[lineIndex] = line
						end
						line.Height = dist; line.CFrame = CFrame.lookAt(p1 + (p2 - p1) / 2, p2); line.Visible = true
						lineIndex = lineIndex + 1
					end
				end
			end
			for i = lineIndex, #PathLines do PathLines[i].Visible = false end
		else
			for _, line in ipairs(PathLines) do line.Visible = false end
		end
	end))
	
	table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
		if not Pause and not ViewingTAS then
			local now = os.clock()
			if now - LastRecordTime < (1/60) then return end
			LastRecordTime = now
			
			if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
			if LocalPlayer.Character.Humanoid.Health <= 0 then return end

			local success, err = pcall(function()
				UpdateTimeGUI()
				table.insert(PlayerInfo, ReturnPlayerInfo())
				UpdateGUIText()
			end)
			if not success then warn("TAS Recording Glitch:", err) end
		end
	end))
	
	__lt.cm(
		"ContextActionService",
		"BindActionAtPriority",
		ControllerActionName,
		ControllerActionHandler,
		false,
		3000,
		table.unpack(ControllerBindableKeys)
	)

	table.insert(Connections, UserInputService.LastInputTypeChanged:Connect(function(inputType)
		SetInputMode(InputModeFromType(inputType))
	end))

	table.insert(Connections, UserInputService.InputBegan:Connect(function(Input, Processed)
		local Key = Input.KeyCode
		SetInputMode(InputModeFromType(Input.UserInputType))
		if Key == Enum.KeyCode.ButtonL1 then
			ControllerModifiers.L1 = true
			return
		elseif Key == Enum.KeyCode.ButtonR1 then
			ControllerModifiers.R1 = true
			return
		end
		if BindingCapture and BindingCapture.Kind == "Keyboard" then
			if Input.UserInputType == Enum.UserInputType.Keyboard and Key ~= Enum.KeyCode.Unknown and os.clock() - BindingCapture.Started > 0.1 then
				local action = BindingCapture.Action
				local conflict = FindKeyboardConflict(action, Key)
				if conflict then
					notify("Already used by " .. ActionLabels[conflict], "TAS Settings", 2)
				else
					KeyboardBindings[action] = Key
					BindingCapture = nil
					SaveSettings(true)
					RefreshSettingsRows()
					RefreshKeybindDisplay()
				end
			end
			return
		end
		if Processed then return end
		if Input.UserInputType == Enum.UserInputType.Keyboard then
			local action = GetKeyboardActionForKey(Key)
			if action then ActionRouter.Begin(action, "Keyboard:" .. Key.Name) end
		end
	end))

	table.insert(Connections, UserInputService.InputEnded:Connect(function(Input)
		local Key = Input.KeyCode
		if Key == Enum.KeyCode.ButtonL1 then
			ControllerModifiers.L1 = false
			EndControllerModifierActions("L1")
			return
		elseif Key == Enum.KeyCode.ButtonR1 then
			ControllerModifiers.R1 = false
			EndControllerModifierActions("R1")
			return
		end
		if Input.UserInputType == Enum.UserInputType.Keyboard then
			local action = GetKeyboardActionForKey(Key)
			if action then ActionRouter.End(action, "Keyboard:" .. Key.Name) end
		end
	end))

	table.insert(Connections, LocalPlayer.CharacterAdded:Connect(SetupCharacterConnections))
	if LocalPlayer.Character then SetupCharacterConnections(LocalPlayer.Character) end
	
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		LocalPlayer.Character.HumanoidRootPart.Anchored = true
		LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new()
	end
	
	notify("TAS Recorder Initialized", "TAS")
	
	if isAuto then
		task.spawn(function()
			if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
			local char = LocalPlayer.Character
			if not char:FindFirstChild("HumanoidRootPart") then char:WaitForChild("HumanoidRootPart", 5) end
			
			local loadSuccess = LoadRun(AutoLoadAndPlayFile)
			if loadSuccess then
				task.wait(0.1)
				ViewTASPlayback()
			else
				DisconnectAll()
			end
		end)
	end
end

Initialize()
