local Environment = if type(getgenv) == "function" then getgenv() else _G

local PreviousUnload = rawget(Environment, "UnloadNotoriety")

if type(PreviousUnload) == "function" then
	pcall(PreviousUnload)
end

local ServiceResolver = rawget(Environment, "__lt_service_resolver")

if type(ServiceResolver) ~= "table" then
	local Loader = loadstring

	if type(Loader) ~= "function" then
		error("ServiceResolver loader unavailable")
	end

	local ResolverSource = game:HttpGet(
		"https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/ServiceResolver.luau"
	)

	local ResolverChunk, ResolverCompileError = Loader(
		ResolverSource,
		"@ServiceResolver.luau"
	)

	if type(ResolverChunk) ~= "function" then
		error("ServiceResolver compile failed: " .. tostring(ResolverCompileError))
	end

	local ResolverSuccess, ResolverResult = pcall(ResolverChunk)

	if not ResolverSuccess or type(ResolverResult) ~= "table" then
		error("ServiceResolver load failed: " .. tostring(ResolverResult))
	end

	ServiceResolver = ResolverResult
	Environment.__lt_service_resolver = ServiceResolver
end

local UIProtectorURL = "https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/UIprotector.luau"

local function loadUIProtector()
	local Loader = loadstring

	if type(Loader) ~= "function" then
		error("UIProtector loader unavailable")
	end

	local ProtectorSource = game:HttpGet(UIProtectorURL)
	local ProtectorChunk, ProtectorCompileError = Loader(ProtectorSource, "@UIprotector.luau")

	if type(ProtectorChunk) ~= "function" then
		error("UIProtector compile failed: " .. tostring(ProtectorCompileError))
	end

	local ProtectorSuccess, ProtectorResult = pcall(ProtectorChunk)

	if not ProtectorSuccess or type(ProtectorResult) ~= "table" then
		error("UIProtector load failed: " .. tostring(ProtectorResult))
	end

	return ProtectorResult
end

local UIProtector = loadUIProtector()

local function resolveProtectedUIParent()
	local ResolveParent = UIProtector.resolveParent

	if type(ResolveParent) == "function" then
		local Success, Parent = pcall(ResolveParent)

		if Success and typeof(Parent) == "Instance" then
			return Parent
		end
	end

	local ParentFunction = UIProtector.parent

	if type(ParentFunction) == "function" then
		local Success, Parent = pcall(ParentFunction)

		if Success and typeof(Parent) == "Instance" then
			return Parent
		end
	end

	return nil
end

local Reference = if type(cloneref) == "function" then cloneref else function(Value)
	return Value
end

local ReplicatedStorage = ServiceResolver.cs("ReplicatedStorage", Reference)
local Workspace = ServiceResolver.cs("Workspace", Reference)
local Players = ServiceResolver.cs("Players", Reference)
local RunService = ServiceResolver.cs("RunService", Reference)
local CollectionService = ServiceResolver.cs("CollectionService", Reference)
local ContextActionService = ServiceResolver.cs("ContextActionService", Reference)
local UserInputService = ServiceResolver.cs("UserInputService", Reference)
local SoundService = ServiceResolver.cs("SoundService", Reference)

local LocalPlayer = Players.LocalPlayer

local RS_Package = ReplicatedStorage:WaitForChild("RS_Package", math.huge)
local Assets = RS_Package:WaitForChild("Assets", math.huge)
local Remotes = Assets:WaitForChild("Remotes", math.huge)
local Event = Remotes:WaitForChild("Damage", math.huge)

local NotorietyUI = {}

do
	local VibeUISource = game:HttpGet(
		"https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"
	):gsub("\r\n", "\n")

	local ParentPatchCount
	VibeUISource, ParentPatchCount = VibeUISource:gsub(
		"local function GetParentGui%(%): Instance.-\nend",
		[[local function GetParentGui(): Instance
	return LocalPlayer:WaitForChild("PlayerGui")
end]],
		1
	)

	if ParentPatchCount ~= 1 then
		error("VibeUI staging parent patch failed")
	end

	local AnchorPatchCount
	VibeUISource, AnchorPatchCount = VibeUISource:gsub(
		"LibMaid:GiveTask%(RunService%.RenderStepped:Connect%(function%(%)[\n]",
		"LibMaid:GiveTask(RunService.RenderStepped:Connect(function()\n\tif next(Anchors) == nil then return end\n",
		1
	)

	if AnchorPatchCount ~= 1 then
		error("VibeUI idle-loop compatibility patch failed")
	end

	local SharedEnvironment = shared
	local PreviousSharedVibeUI = SharedEnvironment and rawget(SharedEnvironment, "VibeUI") or nil
	local PreviousEnvironmentVibeUI = rawget(Environment, "VibeUI")

	if SharedEnvironment then
		rawset(SharedEnvironment, "VibeUI", nil)
	end

	rawset(Environment, "VibeUI", nil)
	local VibeUIChunk, VibeUICompileError = loadstring(VibeUISource, "@VibeUI.lua")

	if type(VibeUIChunk) ~= "function" then
		error("VibeUI compile failed: " .. tostring(VibeUICompileError))
	end

	local VibeUISuccess, VibeUI = pcall(VibeUIChunk)

	if SharedEnvironment then
		rawset(SharedEnvironment, "VibeUI", PreviousSharedVibeUI)
	end

	rawset(Environment, "VibeUI", PreviousEnvironmentVibeUI)

	if not VibeUISuccess or type(VibeUI) ~= "table" then
		error("VibeUI load failed: " .. tostring(VibeUI))
	end

	local Adapter = {}

	function Adapter:Notify(Config)
		return VibeUI:Notification({
			Title = Config.Title,
			Description = Config.Content or Config.Description,
			Duration = Config.Duration,
			Type = "success",
		})
	end

	function Adapter:CreateWindow(Config)
		local NativeWindow = VibeUI:Window({
			Title = Config.Title,
			Size = Config.Size,
			Keybind = Config.ToggleKey or Enum.KeyCode.RightShift,
			Layout = "Side",
			Resizable = true,
		})
		local Window = {}

		local NativeRoot = NativeWindow._root
		NotorietyUI.Root = if typeof(NativeRoot) == "Instance"
			then NativeRoot:FindFirstAncestorOfClass("ScreenGui")
			else nil

		local MouseUnlockButton

		if typeof(NativeRoot) == "Instance" then
			MouseUnlockButton = ServiceResolver.ns("TextButton")

			if MouseUnlockButton then
				MouseUnlockButton.Name = "VibeUIMouseUnlock"
				MouseUnlockButton.BackgroundTransparency = 1
				MouseUnlockButton.TextTransparency = 1
				MouseUnlockButton.AutoButtonColor = false
				MouseUnlockButton.Active = false
				MouseUnlockButton.Selectable = false
				MouseUnlockButton.Modal = true
				MouseUnlockButton.Size = UDim2.fromOffset(1, 1)
				MouseUnlockButton.Position = UDim2.fromOffset(0, 0)
				MouseUnlockButton.Visible = NativeWindow.IsOpen == true
				MouseUnlockButton.Parent = NativeRoot

				local NativeSetOpen = NativeWindow.SetOpen

				if type(NativeSetOpen) == "function" then
					NativeWindow.SetOpen = function(Self, Open, ...)
						local Results = table.pack(NativeSetOpen(Self, Open, ...))
						MouseUnlockButton.Visible = Open == true
						return table.unpack(Results, 1, Results.n)
					end
				end
			end
		end

		NotorietyUI.MouseUnlockButton = MouseUnlockButton

		local function wrapControlCallback(Control, Callback)
			return function(...)
				if type(Callback) == "function" then
					Callback(...)
				end

				local RequestSave = NotorietyUI.RequestConfigSave

				if type(RequestSave) == "function" then
					RequestSave()
				end
			end
		end

		function Window:Tab(TabConfig)
			local NativeTab = NativeWindow:Tab({
				Name = TabConfig.Title,
				Columns = 1,
			})
			local NativeSection = NativeTab:Section({
				Name = TabConfig.Title,
				Side = 1,
			})
			local Tab = {}

			function Tab:Button(Control)
				local Row = NativeSection:Button()
				Row:Add(Control.Title, Control.Callback)
				return Row
			end

			function Tab:Toggle(Control)
				return NativeSection:Toggle({
					Name = Control.Title,
					Flag = Control.Flag,
					Default = Control.Value,
					Callback = wrapControlCallback(Control, Control.Callback),
				})
			end

			function Tab:Input(Control)
				return NativeSection:Textbox({
					Name = Control.Title,
					Flag = Control.Flag,
					Default = Control.Value,
					Placeholder = Control.Placeholder,
					Finished = true,
					Callback = wrapControlCallback(Control, Control.Callback),
				})
			end

			function Tab:Dropdown(Control)
				return NativeSection:Dropdown({
					Name = Control.Title,
					Flag = Control.Flag,
					Items = Control.Values or Control.Items or {},
					Default = Control.Value,
					Multi = false,
					Search = false,
					Callback = wrapControlCallback(Control, Control.Callback),
				})
			end

			function Tab:Slider(Control)
				return NativeSection:Slider({
					Name = Control.Title,
					Flag = Control.Flag,
					Min = Control.Min,
					Max = Control.Max,
					Default = Control.Value,
					Decimals = Control.Step,
					Suffix = Control.Suffix,
					Callback = wrapControlCallback(Control, Control.Callback),
				})
			end

			function Tab:Keybind(Control)
				local DefaultKey = Enum.KeyCode[Control.Value] or Enum.KeyCode.RightShift
				return NativeSection:Label(Control.Title):AddKeybind({
					Flag = Control.Flag,
					Default = DefaultKey,
					Mode = "Toggle",
					OnChanged = function(Key)
						local KeyName = typeof(Key) == "EnumItem" and Key.Name or tostring(Key):match("([^%.]+)$")

						if KeyName then
							wrapControlCallback(Control, Control.Callback)(KeyName)
						end
					end,
				})
			end

			return Tab
		end

		function Window:SetToggleKey(Key)
			VibeUI.Config.MenuKeybind = Key
		end

		function Window:Destroy()
			local Success, UnloadError = pcall(VibeUI.Unload, VibeUI)

			if SharedEnvironment then
				rawset(SharedEnvironment, "VibeUI", PreviousSharedVibeUI)
			end

			rawset(Environment, "VibeUI", PreviousEnvironmentVibeUI)

			if not Success then
				error(UnloadError)
			end
		end

		local ConfigManager = {}

		function ConfigManager:AllConfigs()
			local Success, Configs = pcall(VibeUI.ListConfigs, VibeUI)
			return if Success and type(Configs) == "table" then Configs else {}
		end

		function ConfigManager:Config(Name)
			return {
				Save = function()
					local Success, SaveError = VibeUI:SaveConfig(Name)

					if not Success then
						error(SaveError or "VibeUI config save failed", 0)
					end

					return true
				end,
				Load = function()
					local Data = VibeUI:ReadConfig(Name)

					if type(Data) == "string" then
						return VibeUI:LoadConfig(Data)
					end
				end,
			}
		end

		Window.ConfigManager = ConfigManager
		return Window
	end

	NotorietyUI.Library = Adapter
end

if Environment.MaxEverythingConnection then
	Environment.MaxEverythingConnection:Disconnect()
	Environment.MaxEverythingConnection = nil
end

if Environment.MaxEverythingCharacterConnection then
	Environment.MaxEverythingCharacterConnection:Disconnect()
	Environment.MaxEverythingCharacterConnection = nil
end

if Environment.NotorietyPoliceHitboxConnection then
	Environment.NotorietyPoliceHitboxConnection:Disconnect()
	Environment.NotorietyPoliceHitboxConnection = nil
end

if type(Environment.NotorietyWeaponConnections) == "table" then
	for _, Connection in Environment.NotorietyWeaponConnections do
		pcall(function()
			Connection:Disconnect()
		end)
	end
end

if type(Environment.NotorietyNoDelayConnections) == "table" then
	for _, Connection in Environment.NotorietyNoDelayConnections do
		pcall(function()
			Connection:Disconnect()
		end)
	end
end

Environment.NotorietyNoDelayConnections = {}

if type(Environment.NotorietyGetAmmoWrappers) == "table" then
	for State, Record in Environment.NotorietyGetAmmoWrappers do
		if type(State) == "table" and type(Record) == "table" then
			local Original = Record.Original
			local Wrapper = Record.Wrapper

			if type(Original) == "function" and State.getAmmo == Wrapper then
				State.getAmmo = Original
			end
		end
	end
end

Environment.NotorietyGetAmmoWrappers = setmetatable({}, {
	__mode = "k",
})

if type(Environment.NotorietyItemESPController) == "table"
	and type(Environment.NotorietyItemESPController.Cleanup) == "function"
then
	pcall(Environment.NotorietyItemESPController.Cleanup)
	Environment.NotorietyItemESPController = nil
end

if Environment.NotorietyWindow then
	pcall(function()
		Environment.NotorietyWindow:Destroy()
	end)

	Environment.NotorietyWindow = nil
end

if type(Environment.NotorietyUIConnections) == "table" then
	for _, Connection in Environment.NotorietyUIConnections do
		pcall(function()
			Connection:Disconnect()
		end)
	end
end

Environment.MaxEverythingEnabled = true
Environment.KillPoliceRunning = false
Environment.KillTeammatesRunning = false
Environment.NotorietyTeammateTarget = tostring(Environment.NotorietyTeammateTarget or "All")
Environment.NotorietyWeaponEnabled = Environment.NotorietyWeaponEnabled ~= false
Environment.NotorietyFriendlyFireEnabled = Environment.NotorietyFriendlyFireEnabled ~= false
Environment.NotorietyRapidFireEnabled = Environment.NotorietyRapidFireEnabled ~= false
Environment.NotorietyNoRecoilEnabled = Environment.NotorietyNoRecoilEnabled ~= false
Environment.NotorietyInfiniteAmmoEnabled = Environment.NotorietyInfiniteAmmoEnabled ~= false
Environment.NotorietyFullAutoEnabled = Environment.NotorietyFullAutoEnabled ~= false
Environment.NotorietyAccuracyModEnabled = Environment.NotorietyAccuracyModEnabled ~= false
Environment.NotorietySilentAimEnabled = Environment.NotorietySilentAimEnabled == true
Environment.NotorietyWallBangEnabled = Environment.NotorietyWallBangEnabled == true
Environment.NotorietySilentAimTargetPolice = Environment.NotorietySilentAimTargetPolice ~= false
Environment.NotorietySilentAimTargetCriminals = Environment.NotorietySilentAimTargetCriminals == true
Environment.NotorietyWallBangTargetPolice = Environment.NotorietyWallBangTargetPolice ~= false
Environment.NotorietyWallBangTargetCriminals = Environment.NotorietyWallBangTargetCriminals == true
Environment.NotorietySilentAimFOV = math.clamp(tonumber(Environment.NotorietySilentAimFOV) or 250, 0, 2000)
Environment.NotorietyFireDelay = math.clamp(tonumber(Environment.NotorietyFireDelay) or 0.01, 0, 1)
Environment.NotorietyBoltDuration = math.clamp(tonumber(Environment.NotorietyBoltDuration) or 0.001, 0, 1)
Environment.NotorietyAccuracy = tonumber(Environment.NotorietyAccuracy) or 100
Environment.NotorietyItemESPEnabled = Environment.NotorietyItemESPEnabled == true
Environment.NotorietyESPTextEnabled = Environment.NotorietyESPTextEnabled ~= false
Environment.NotorietyItemESPLabels = Environment.NotorietyItemESPLabels ~= false
Environment.NotorietyItemESPTransparency = math.clamp(tonumber(Environment.NotorietyItemESPTransparency) or 55, 0, 100)
Environment.NotorietyItemESPMaxDistance = math.clamp(tonumber(Environment.NotorietyItemESPMaxDistance) or 2500, 0, 10000)
Environment.NotorietyItemESPCategories = type(Environment.NotorietyItemESPCategories) == "table" and Environment.NotorietyItemESPCategories or {}
for _, Category in { "LOOT", "ITEM", "KEY", "CONTAINER", "CAMERA", "SECURITY", "ACCESS", "ESCAPE" } do
	if Environment.NotorietyItemESPCategories[Category] == nil then
		Environment.NotorietyItemESPCategories[Category] = true
	end
end
Environment.NotorietyPoliceESPEnabled = Environment.NotorietyPoliceESPEnabled == true
Environment.NotorietyPoliceESPNames = Environment.NotorietyPoliceESPNames ~= false
Environment.NotorietyPoliceESPHealth = Environment.NotorietyPoliceESPHealth ~= false
Environment.NotorietyPoliceESPMaxDistance = math.clamp(tonumber(Environment.NotorietyPoliceESPMaxDistance) or 2500, 0, 10000)
Environment.NotorietyPoliceHeadScaleEnabled = Environment.NotorietyPoliceHeadScaleEnabled == true
Environment.NotorietyPoliceHeadScale = math.clamp(
	tonumber(Environment.NotorietyPoliceHeadScale) or 10,
	1,
	20
)
Environment.NotorietyEquipmentSpeedEnabled = Environment.NotorietyEquipmentSpeedEnabled == true
Environment.NotorietyEquipmentInstantEnabled = Environment.NotorietyEquipmentInstantEnabled == true
Environment.NotorietyEquipmentSpeedMultiplier = math.clamp(
	tonumber(Environment.NotorietyEquipmentSpeedMultiplier) or 2,
	1,
	10
)
Environment.NotorietyEquipmentRangeEnabled = Environment.NotorietyEquipmentRangeEnabled == true
Environment.NotorietyEquipmentPlacementRange = math.clamp(tonumber(Environment.NotorietyEquipmentPlacementRange) or 10, 10, 100)
Environment.NotorietyInfiniteEquipmentEnabled = Environment.NotorietyInfiniteEquipmentEnabled == true
Environment.NotorietyEquipmentPositionEnabled = Environment.NotorietyEquipmentPositionEnabled == true
Environment.NotorietyEquipmentPositionX = math.clamp(tonumber(Environment.NotorietyEquipmentPositionX) or 0, -50, 50)
Environment.NotorietyEquipmentPositionY = math.clamp(tonumber(Environment.NotorietyEquipmentPositionY) or 0, -50, 50)
Environment.NotorietyEquipmentPositionZ = math.clamp(tonumber(Environment.NotorietyEquipmentPositionZ) or 0, -50, 50)
Environment.NotorietyInfiniteYellMarkEnabled = Environment.NotorietyInfiniteYellMarkEnabled == true
Environment.NotorietyYellThroughWalls = Environment.NotorietyYellThroughWalls ~= false
Environment.NotorietyTeammateYellInfiniteRange = Environment.NotorietyTeammateYellInfiniteRange ~= false
Environment.NotorietyTeammateYellThroughWalls = Environment.NotorietyTeammateYellThroughWalls ~= false
Environment.NotorietyYellMarkMethod = tostring(Environment.NotorietyYellMarkMethod or "Viewport")

if Environment.NotorietyYellMarkMethod ~= "Viewport"
	and Environment.NotorietyYellMarkMethod ~= "Whole Game"
	and Environment.NotorietyYellMarkMethod ~= "Original"
then
	Environment.NotorietyYellMarkMethod = "Viewport"
end

Environment.NotorietyAutoYellEnabled = Environment.NotorietyAutoYellEnabled == true
Environment.NotorietyNoYellDelayEnabled = Environment.NotorietyNoYellDelayEnabled == true
Environment.NotorietyMusicVolume = math.clamp(tonumber(Environment.NotorietyMusicVolume) or 100, 0, 100)
Environment.NotorietyMusicTrack = tostring(Environment.NotorietyMusicTrack or "Game Selection")
Environment.NotorietyMusicMode = tostring(Environment.NotorietyMusicMode or "Follow Game")
Environment.NotorietySFXVolume = math.clamp(tonumber(Environment.NotorietySFXVolume) or 100, 0, 100)
Environment.NotorietyLocalGunshotsVolume = math.clamp(tonumber(Environment.NotorietyLocalGunshotsVolume) or 100, 0, 100)
Environment.NotorietyGunshotsVolume = math.clamp(tonumber(Environment.NotorietyGunshotsVolume) or 100, 0, 100)
Environment.NotorietyMapAmbienceVolume = math.clamp(tonumber(Environment.NotorietyMapAmbienceVolume) or 100, 0, 100)
Environment.NotorietyVoicesVolume = math.clamp(tonumber(Environment.NotorietyVoicesVolume) or 100, 0, 100)
Environment.NotorietyUIVolume = math.clamp(tonumber(Environment.NotorietyUIVolume) or 100, 0, 100)

if Environment.NotorietyEquipmentSpeedMultiplier <= 0
	or Environment.NotorietyEquipmentSpeedMultiplier == math.huge
	or Environment.NotorietyEquipmentSpeedMultiplier ~= Environment.NotorietyEquipmentSpeedMultiplier
then
	Environment.NotorietyEquipmentSpeedMultiplier = 2
end

if Environment.NotorietyAccuracy ~= Environment.NotorietyAccuracy
	or Environment.NotorietyAccuracy == math.huge
	or Environment.NotorietyAccuracy == -math.huge
then
	Environment.NotorietyAccuracy = 100
else
	Environment.NotorietyAccuracy = math.clamp(Environment.NotorietyAccuracy, 0, 100)
end

Environment.NotorietyWeaponConnections = {}
Environment.NotorietyUIConnections = {}
Environment.NotorietyUnloaded = false

local EquipmentSpeedState = {
	Refresh = 0,
}

local EquipmentPlacementState = {
	HookInstalled = false,
	Target = nil,
	Original = nil,
	Active = false,
}

local function getEquipmentPositionOffset()
	local X = tonumber(Environment.NotorietyEquipmentPositionX) or 0
	local Y = tonumber(Environment.NotorietyEquipmentPositionY) or 0
	local Z = tonumber(Environment.NotorietyEquipmentPositionZ) or 0

	if X == math.huge or X == -math.huge or X ~= X then X = 0 end
	if Y == math.huge or Y == -math.huge or Y ~= Y then Y = 0 end
	if Z == math.huge or Z == -math.huge or Z ~= Z then Z = 0 end

	return X, Y, Z
end

local function getEquipmentSpeedMultiplier()
	if Environment.NotorietyEquipmentInstantEnabled then
		return math.huge
	end

	if not Environment.NotorietyEquipmentSpeedEnabled then
		return 1
	end

	local Multiplier = tonumber(Environment.NotorietyEquipmentSpeedMultiplier) or 2
	if Multiplier <= 0 or Multiplier == math.huge or Multiplier ~= Multiplier then
		Multiplier = 2
		Environment.NotorietyEquipmentSpeedMultiplier = Multiplier
	end

	return Multiplier
end

local function shouldOverrideEquipmentPlacement()
	return not Environment.NotorietyUnloaded and (
		Environment.NotorietyEquipmentInstantEnabled
		or Environment.NotorietyEquipmentSpeedEnabled
		or Environment.NotorietyEquipmentRangeEnabled
		or Environment.NotorietyEquipmentPositionEnabled
	)
end

local function getEquipmentInputKeys()
	local PlayerData = ReplicatedStorage:FindFirstChild("PlayerData")
	local DataFolder = PlayerData and PlayerData:FindFirstChild(LocalPlayer.Name)
	local Data = DataFolder and DataFolder:FindFirstChild(LocalPlayer.Name .. "'s Data")
	local Options = Data and Data:FindFirstChild("Options")

	local KeyboardKey = Enum.KeyCode.G
	local ControllerKey = nil

	local Keybinds = Options and Options:FindFirstChild("Keybinds")
	local KeyboardValue = Keybinds and Keybinds:FindFirstChild("MaskEquipment")
	if KeyboardValue and Enum.KeyCode[KeyboardValue.Value] then
		KeyboardKey = Enum.KeyCode[KeyboardValue.Value]
	end

	local Controller = Options and Options:FindFirstChild("KeybindsController")
	local ControllerValue = Controller and Controller:FindFirstChild("Throw/Equipment")
	if ControllerValue and Enum.KeyCode[ControllerValue.Value] then
		ControllerKey = Enum.KeyCode[ControllerValue.Value]
	end

	return KeyboardKey, ControllerKey
end

local function isNativeEquipmentInputHeld(IsMobile)
	if IsMobile then
		return true
	end

	local KeyboardKey, ControllerKey = getEquipmentInputKeys()
	if KeyboardKey and UserInputService:IsKeyDown(KeyboardKey) then
		return true
	end

	if ControllerKey then
		for Index = 1, 8 do
			local GamepadType = Enum.UserInputType["Gamepad" .. Index]
			if GamepadType then
				local Success, Held = pcall(
					UserInputService.IsGamepadButtonDown,
					UserInputService,
					GamepadType,
					ControllerKey
				)

				if Success and Held then
					return true
				end
			end
		end
	end

	return false
end

local function readFunctionUpvalue(Function, Index)
	if type(debug) ~= "table" then
		return nil
	end

	if type(debug.getupvalue) == "function" then
		local Success, Value = pcall(debug.getupvalue, Function, Index)
		if Success then
			return Value
		end
	end

	if type(debug.getupvalues) == "function" then
		local Success, Values = pcall(debug.getupvalues, Function)
		if Success and type(Values) == "table" then
			return Values[Index]
		end
	end

	return nil
end

local function writeFunctionUpvalue(Function, Index, Value)
	if type(debug) ~= "table" or type(debug.setupvalue) ~= "function" then
		return false
	end

	return pcall(debug.setupvalue, Function, Index, Value)
end

local function findNativePlaceEquipment()
	if type(EquipmentPlacementState.Target) == "function" then
		return EquipmentPlacementState.Target
	end

	if type(getgc) ~= "function" or type(debug) ~= "table" or type(debug.getinfo) ~= "function" then
		return nil
	end

	local SourceSuffix = "Players." .. LocalPlayer.Name .. ".PlayerGui.SG_Package.LocalMovement"

	local Success, Objects = pcall(getgc, true)
	if not Success or type(Objects) ~= "table" then
		return nil
	end

	for _, Function in pairs(Objects) do
		if type(Function) == "function" then
			local InfoSuccess, Info = pcall(debug.getinfo, Function)

			if InfoSuccess
				and type(Info) == "table"
				and Info.name == "placeEquipment"
				and tostring(Info.source or Info.short_src or ""):find(SourceSuffix, 1, true)
			then
				EquipmentPlacementState.Target = Function
				return Function
			end
		end
	end

	return nil
end

local function runNativeEquipmentPlacement(Original, IsMobile)
	if EquipmentPlacementState.Active then
		return
	end

	local Preview = readFunctionUpvalue(Original, 2)
	local EquipmentName = readFunctionUpvalue(Original, 3)
	local HasSkill = readFunctionUpvalue(Original, 4)
	local Humanoid = readFunctionUpvalue(Original, 6)
	local MainGui = readFunctionUpvalue(Original, 7)
	local UseCenter = readFunctionUpvalue(Original, 8)
	local Mouse = readFunctionUpvalue(Original, 9)
	local CurrentCamera = readFunctionUpvalue(Original, 10)
	local ColorEquipment = readFunctionUpvalue(Original, 11)
	local EquipmentColors = readFunctionUpvalue(Original, 12)
	local Remotes = readFunctionUpvalue(Original, 13)

	if typeof(Preview) ~= "Instance"
		or not Preview:IsA("Model")
		or not Preview.PrimaryPart
		or type(EquipmentName) ~= "string"
		or EquipmentName == ""
		or type(HasSkill) ~= "function"
		or typeof(Humanoid) ~= "Instance"
		or not Humanoid:IsA("Humanoid")
		or typeof(MainGui) ~= "Instance"
		or typeof(CurrentCamera) ~= "Instance"
		or not CurrentCamera:IsA("Camera")
		or type(ColorEquipment) ~= "function"
		or type(EquipmentColors) ~= "table"
		or typeof(Remotes) ~= "Instance"
	then
		return Original(IsMobile)
	end

	local PlaceEquipmentRemote = Remotes:FindFirstChild("PlaceEquipment")
	if not PlaceEquipmentRemote or not PlaceEquipmentRemote:IsA("RemoteEvent") then
		return Original(IsMobile)
	end

	EquipmentPlacementState.Active = true
	writeFunctionUpvalue(Original, 1, true)

	local function IsStillActive()
		local NativeFlag = readFunctionUpvalue(Original, 1)
		if NativeFlag == false then
			return false
		end

		if not IsMobile and not isNativeEquipmentInputHeld(false) then
			return false
		end

		return true
	end

	local Success, ErrorMessage = xpcall(function()
		task.wait(IsMobile and 0 or 0.5)

		if not IsStillActive() then
			return
		end

		local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
		local RuntimeMainGui = SGPackage and SGPackage:FindFirstChild("MainGui")
		local Interaction = RuntimeMainGui and RuntimeMainGui:FindFirstChild("Interaction")
		local EquipmentPercent = Interaction and Interaction:FindFirstChild("EquipmentPercent")

		if not EquipmentPercent or not EquipmentPercent:IsA("TextLabel") then
			return Original(IsMobile)
		end

		Preview.Parent = Workspace

		local Duration = 2
		if EquipmentName == "Medical Kit" and HasSkill("Mastermind", "j") then
			Duration /= 2
		elseif EquipmentName == "Ammo Bag" and HasSkill("Enforcer", "b") then
			Duration /= 2
		end

		if HasSkill("Technician", "n") then
			Duration /= 2
		end

		local Multiplier = getEquipmentSpeedMultiplier()
		if Multiplier == math.huge then
			Duration = 0
		else
			Duration /= Multiplier
		end

		local Ignore = {
			Preview,
			Workspace.CurrentCamera,
			Workspace:FindFirstChild("Police"),
			Workspace:FindFirstChild("Criminals"),
			Workspace:FindFirstChild("Citizens"),
			Workspace:FindFirstChild("InvisibleParts"),
			Workspace:FindFirstChild("Lootables"),
			Workspace:FindFirstChild("Bags"),
			Workspace:FindFirstChild("Bodies"),
			Workspace:FindFirstChild("Tracers"),
			Workspace:FindFirstChild("ShatteredGlass"),
			Workspace:FindFirstChild("MapZones"),
		}

		for Index = #Ignore, 1, -1 do
			if Ignore[Index] == nil then
				table.remove(Ignore, Index)
			end
		end

		EquipmentPercent.Visible = true
		EquipmentPercent.Text = "0%"

		local IsGroundEquipment = EquipmentName == "Medical Kit"
			or EquipmentName == "Ammo Bag"
			or EquipmentName == "Body Bags"
			or EquipmentName == "Sentry Gun"
		local IsTripMine = EquipmentName == "Trip Mine"
		local StartTime = os.clock()
		local HitPart = false
		local UsefulTarget = false
		local PlacementCFrame = nil

		repeat
			if Environment.NotorietyUnloaded
				or not IsStillActive()
				or Humanoid.PlatformStand
				or not Preview.Parent
			then
				break
			end

			task.wait()

			local ViewSize = MainGui.AbsoluteSize / 2
			local ScreenPoint

			if UseCenter or IsMobile then
				ScreenPoint = Vector2.new(ViewSize.X, ViewSize.Y)
			else
				local MouseX = typeof(Mouse) == "Instance" and Mouse.X or ViewSize.X
				local MouseY = typeof(Mouse) == "Instance" and Mouse.Y or ViewSize.Y
				ScreenPoint = Vector2.new(MouseX, MouseY)
			end

			local ScreenRay = CurrentCamera:ScreenPointToRay(ScreenPoint.X, ScreenPoint.Y, 0)
			local Range = Environment.NotorietyEquipmentRangeEnabled
				and math.clamp(tonumber(Environment.NotorietyEquipmentPlacementRange) or 10, 10, 100)
				or 10

			local HitPosition
			local HitNormal
			HitPart, HitPosition, HitNormal = Workspace:FindPartOnRayWithIgnoreList(
				Ray.new(ScreenRay.Origin, ScreenRay.Direction * Range),
				Ignore
			)

			if HitPosition then
				PlacementCFrame = CFrame.new(
					HitPosition + Vector3.new(0, Preview.PrimaryPart.Size.Y / 2, 0),
					CurrentCamera.CFrame.Position
				)

				local SurfacePosition = HitPosition + Vector3.new(0, Preview.PrimaryPart.Size.Y / 2, 0)

				if not IsGroundEquipment and HitPart then
					PlacementCFrame = CFrame.new(
						SurfacePosition,
						SurfacePosition + (HitNormal or Vector3.new(0, 1, 0))
					) * CFrame.new(0, 0, -Preview.PrimaryPart.Size.X / 2)
				end

				UsefulTarget = false

				if IsGroundEquipment then
					local GroundPart, GroundPosition = Workspace:FindPartOnRayWithIgnoreList(
						Ray.new(
							PlacementCFrame.Position,
							Vector3.new(0, -Preview.PrimaryPart.Size.Y - 5, 0)
						),
						Ignore
					)

					HitPart = GroundPart

					if GroundPart and GroundPosition then
						PlacementCFrame = CFrame.new(
							GroundPosition + Vector3.new(0, Preview.PrimaryPart.Size.Y / 2, 0),
							Vector3.new(
								CurrentCamera.CFrame.Position.X,
								GroundPosition.Y + Preview.PrimaryPart.Size.Y / 2,
								CurrentCamera.CFrame.Position.Z
							)
						)
					else
						HitPart = false
						PlacementCFrame = nil
					end
				elseif HitPart and IsTripMine and HitPart.Parent then
					local TargetPart = HitPart

					if TargetPart.Parent.Name == "KickDoor" then
						table.insert(Ignore, TargetPart.Parent)

						if TargetPart.Parent.Parent and TargetPart.Parent.Parent.PrimaryPart then
							TargetPart = TargetPart.Parent.Parent.PrimaryPart
						end
					end

					local Parent = TargetPart.Parent
					local Grandparent = Parent and Parent.Parent
					local Door = nil

					if Parent and Parent:HasTag("Door") then
						Door = Parent
					elseif Grandparent and Grandparent:HasTag("Door") then
						Door = Grandparent
					end

					if not Door then
						local DoorModule = (Parent and Parent:FindFirstChild("DoorModule"))
							or (Grandparent and Grandparent:FindFirstChild("DoorModule"))
						Door = DoorModule and DoorModule.Parent or nil
					end

					if Door and (Door:GetAttribute("NoC4") or Door.Name ~= "Door") then
						Door = nil
					end

					if (Parent and Parent.Name == "Safe") or (Grandparent and Grandparent.Name == "Safe") then
						if TargetPart.Name ~= "SafeWall" then
							UsefulTarget = Parent and Parent.Name == "Safe" and Parent or Grandparent
						end
					elseif Door then
						UsefulTarget = Door
					end
				end

				if PlacementCFrame and Environment.NotorietyEquipmentPositionEnabled then
					local X, Y, Z = getEquipmentPositionOffset()
					PlacementCFrame += CurrentCamera.CFrame.RightVector * X
						+ Vector3.new(0, Y, 0)
						+ CurrentCamera.CFrame.LookVector * Z
				end

				if PlacementCFrame then
					if HitPart and not UsefulTarget then
						pcall(ColorEquipment, EquipmentColors.Good)
					elseif HitPart and UsefulTarget then
						pcall(ColorEquipment, EquipmentColors.Useful)
					else
						pcall(ColorEquipment, EquipmentColors.Bad)
					end

					Preview:SetPrimaryPartCFrame(PlacementCFrame)
				else
					pcall(ColorEquipment, EquipmentColors.Bad)
				end
			else
				HitPart = false
				PlacementCFrame = nil
				pcall(ColorEquipment, EquipmentColors.Bad)
			end

			local Elapsed = os.clock() - StartTime
			local Progress = Duration <= 0 and 1 or math.clamp(Elapsed / Duration, 0, 1)
			EquipmentPercent.Text = tostring(math.floor(Progress * 100)) .. "%"

			if Duration <= 0 or Elapsed >= Duration then
				break
			end
		until false

		if IsStillActive() then
			EquipmentPercent.Visible = false

			if HitPart and PlacementCFrame and Preview.PrimaryPart then
				PlaceEquipmentRemote:FireServer(
					EquipmentName,
					Preview.PrimaryPart.CFrame,
					UsefulTarget
				)
			end
		end

		writeFunctionUpvalue(Original, 1, false)
		Preview.Parent = nil
	end, debug.traceback)

	writeFunctionUpvalue(Original, 1, false)

	if typeof(Preview) == "Instance" then
		pcall(function()
			Preview.Parent = nil
		end)
	end

	EquipmentPlacementState.Active = false

	if not Success then
		warn("[Notoriety Equipment] " .. tostring(ErrorMessage))
	end
end

local function installEquipmentPlacementHook()
	if EquipmentPlacementState.HookInstalled
		and type(EquipmentPlacementState.Original) == "function"
	then
		return true
	end

	if type(hookfunction) ~= "function" then
		return false
	end

	local Target = findNativePlaceEquipment()
	if type(Target) ~= "function" then
		return false
	end

	local Original
	local function Wrapped(IsMobile, ...)
		if not shouldOverrideEquipmentPlacement() then
			return Original(IsMobile, ...)
		end

		return runNativeEquipmentPlacement(Original, IsMobile)
	end

	local Success, Result = pcall(hookfunction, Target, Wrapped)
	if not Success or type(Result) ~= "function" then
		return false
	end

	Original = Result
	EquipmentPlacementState.Target = Target
	EquipmentPlacementState.Original = Result
	EquipmentPlacementState.HookInstalled = true
	return true
end

local function restoreEquipmentPlacementSpeed()
	EquipmentPlacementState.Active = false

	if EquipmentPlacementState.HookInstalled
		and type(EquipmentPlacementState.Target) == "function"
		and type(EquipmentPlacementState.Original) == "function"
		and type(hookfunction) == "function"
	then
		pcall(hookfunction, EquipmentPlacementState.Target, EquipmentPlacementState.Original)
	end

	EquipmentPlacementState.HookInstalled = false
	EquipmentPlacementState.Target = nil
	EquipmentPlacementState.Original = nil
end

local function applyEquipmentPlacementSpeed()
	return installEquipmentPlacementHook()
end

local function applyEquipmentPositioning()
	return installEquipmentPlacementHook()
end

local function applyEquipmentPlacementRange()
	return installEquipmentPlacementHook()
end

local function restoreMobileEquipmentPlacementFix()
end

local function applyMobileEquipmentPlacementFix()
	return installEquipmentPlacementHook()
end

local PersistentAudioOriginalVolumes = rawget(Environment, "NotorietyAudioOriginalVolumes")
if type(PersistentAudioOriginalVolumes) ~= "table" then
	PersistentAudioOriginalVolumes = setmetatable({}, { __mode = "k" })
	Environment.NotorietyAudioOriginalVolumes = PersistentAudioOriginalVolumes
end

local PersistentAudioGroupVolumes = rawget(Environment, "NotorietyAudioGroupVolumes")
if type(PersistentAudioGroupVolumes) ~= "table" then
	PersistentAudioGroupVolumes = setmetatable({}, { __mode = "k" })
	Environment.NotorietyAudioGroupVolumes = PersistentAudioGroupVolumes
end

local AudioState = {
	Groups = {},
	OriginalVolumes = PersistentAudioGroupVolumes,
	DirectOriginalVolumes = PersistentAudioOriginalVolumes,
	RootConnections = {},
	Applying = false,
	ScanGeneration = 0,
}

local function addAudioGroup(Key, Group)
	if typeof(Group) ~= "Instance" or not Group:IsA("SoundGroup") then
		return
	end

	AudioState.Groups[Key] = AudioState.Groups[Key] or {}
	if not table.find(AudioState.Groups[Key], Group) then
		table.insert(AudioState.Groups[Key], Group)
	end
	if AudioState.OriginalVolumes[Group] == nil then
		AudioState.OriginalVolumes[Group] = Group.Volume
	end
end

local function resolveAudioGroups()
	table.clear(AudioState.Groups)
	local SoundPackage = SoundService:FindFirstChild("Sound_Package")
	local GlobalSounds = SoundPackage and SoundPackage:FindFirstChild("GlobalSounds")
	local GameAudio = GlobalSounds and GlobalSounds:FindFirstChild("GameAudio")
	local SFX = GameAudio and GameAudio:FindFirstChild("SFX")
	local GlobalVolume = SoundService:FindFirstChild("GlobalVolume")

	addAudioGroup("Music", GlobalSounds and GlobalSounds:FindFirstChild("Music"))
	addAudioGroup("SFX", SFX)
	addAudioGroup("SFXSibling", GameAudio and GameAudio:FindFirstChild("CueSFX"))
	addAudioGroup("SFXSibling", GameAudio and GameAudio:FindFirstChild("SubtleCueSFX"))
	addAudioGroup("LocalGunshots", SFX and SFX:FindFirstChild("LocalGunshots"))
	addAudioGroup("Gunshots", SFX and SFX:FindFirstChild("Gunshots"))
	addAudioGroup("MapAmbience", SFX and SFX:FindFirstChild("MapAmbience"))
	addAudioGroup("Voices", GameAudio and GameAudio:FindFirstChild("Voices"))
	addAudioGroup("Voices", GameAudio and GameAudio:FindFirstChild("NarratorVoice"))
	addAudioGroup("Voices", GlobalVolume and GlobalVolume:FindFirstChild("Voices"))
	addAudioGroup("UI", GlobalSounds and GlobalSounds:FindFirstChild("UI"))
end

local function soundUsesManagedGroup(Sound)
	local Group = Sound.SoundGroup
	if not Group then return false end

	for _, Groups in pairs(AudioState.Groups) do
		for _, Managed in Groups do
			local Current = Group
			while Current and Current:IsA("SoundGroup") do
				if Current == Managed then return true end
				Current = Current.Parent
			end
		end
	end

	return false
end

local function isGunshotSound(Sound)
	local Name = string.lower(Sound.Name)
	local ParentName = Sound.Parent and string.lower(Sound.Parent.Name) or ""
	return ParentName:find("muzzle", 1, true) ~= nil
		or Name:find("gunshot", 1, true) ~= nil
		or Name:find("gunfire", 1, true) ~= nil
		or Name == "fire"
		or Name == "firesound"
		or Name:find("suppressedsound", 1, true) ~= nil
end

local function isLocalGunshotSound(Sound)
	if not isGunshotSound(Sound) then return false end
	local Camera = Workspace.CurrentCamera
	local CameraModel = Camera and Camera:FindFirstChild("CameraModel")
	local Character = LocalPlayer.Character
	return (CameraModel and Sound:IsDescendantOf(CameraModel))
		or (Character and Sound:IsDescendantOf(Character))
end

local function isVoiceSound(Sound)
	local Camera = Workspace.CurrentCamera
	local AudioFolder = Camera and Camera:FindFirstChild("AudioFolder")
	local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
	local Voices = SGPackage and SGPackage:FindFirstChild("Voices")
	local CharVoice = SGPackage and SGPackage:FindFirstChild("CharVoice")
	return (AudioFolder and Sound:IsDescendantOf(AudioFolder))
		or (Voices and Sound:IsDescendantOf(Voices))
		or Sound == CharVoice
end

local function isMapAmbienceSound(Sound)
	local Map = Workspace:FindFirstChild("Map")
	return Map ~= nil and Sound:IsDescendantOf(Map) and not isGunshotSound(Sound)
end

local function isUISound(Sound)
	local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not PlayerGui or not Sound:IsDescendantOf(PlayerGui) or isVoiceSound(Sound) then
		return false
	end

	local SGPackage = PlayerGui:FindFirstChild("SG_Package")
	local MainGui = SGPackage and SGPackage:FindFirstChild("MainGui")
	local RankUp = SGPackage and SGPackage:FindFirstChild("RankUp")
	local SFXFolder = SGPackage and SGPackage:FindFirstChild("SFX")
	local UISFXNames = {
		Hover = true,
		Click = true,
		secondaryUpdate = true,
	}

	return (MainGui and Sound:IsDescendantOf(MainGui))
		or (RankUp and Sound:IsDescendantOf(RankUp))
		or (SFXFolder and Sound.Parent == SFXFolder and UISFXNames[Sound.Name] == true)
end

local function isGeneralSFXSound(Sound)
	local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
	local SFX = SGPackage and SGPackage:FindFirstChild("SFX")
	return SFX ~= nil and Sound:IsDescendantOf(SFX)
end

local function getDirectAudioPercent(Sound)
	if Environment.NotorietyUnloaded
		or typeof(Sound) ~= "Instance"
		or not Sound:IsA("Sound")
		or Sound.Parent == nil
		or soundUsesManagedGroup(Sound)
	then
		return nil
	end

	if isVoiceSound(Sound) then
		return math.clamp(tonumber(Environment.NotorietyVoicesVolume) or 100, 0, 100) / 100
	end

	local SFX = math.clamp(tonumber(Environment.NotorietySFXVolume) or 100, 0, 100) / 100

	if isGunshotSound(Sound) then
		local Gun = if isLocalGunshotSound(Sound)
			then math.clamp(tonumber(Environment.NotorietyLocalGunshotsVolume) or 100, 0, 100) / 100
			else math.clamp(tonumber(Environment.NotorietyGunshotsVolume) or 100, 0, 100) / 100
		return SFX * Gun
	end

	if isMapAmbienceSound(Sound) then
		return SFX * (math.clamp(tonumber(Environment.NotorietyMapAmbienceVolume) or 100, 0, 100) / 100)
	end

	if isUISound(Sound) then
		return SFX * (math.clamp(tonumber(Environment.NotorietyUIVolume) or 100, 0, 100) / 100)
	end

	if isGeneralSFXSound(Sound) then
		return SFX
	end

	return nil
end

local function getLegacyV5DirectAudioPercent(Sound)
	if typeof(Sound) ~= "Instance" or not Sound:IsA("Sound") or Sound.Parent == nil or soundUsesManagedGroup(Sound) then
		return nil
	end

	if isVoiceSound(Sound) then
		return math.clamp(tonumber(Environment.NotorietyVoicesVolume) or 100, 0, 100) / 100
	end

	local SFX = math.clamp(tonumber(Environment.NotorietySFXVolume) or 100, 0, 100) / 100
	if isGunshotSound(Sound) then
		local Gun = if isLocalGunshotSound(Sound)
			then math.clamp(tonumber(Environment.NotorietyLocalGunshotsVolume) or 100, 0, 100) / 100
			else math.clamp(tonumber(Environment.NotorietyGunshotsVolume) or 100, 0, 100) / 100
		return SFX * Gun
	end

	if isMapAmbienceSound(Sound) then
		return SFX * (math.clamp(tonumber(Environment.NotorietyMapAmbienceVolume) or 100, 0, 100) / 100)
	end

	local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
	local MainGui = SGPackage and SGPackage:FindFirstChild("MainGui")
	local RankUp = SGPackage and SGPackage:FindFirstChild("RankUp")
	if (MainGui and Sound:IsDescendantOf(MainGui)) or (RankUp and Sound:IsDescendantOf(RankUp)) then
		return SFX * (math.clamp(tonumber(Environment.NotorietyUIVolume) or 100, 0, 100) / 100)
	end

	if isGeneralSFXSound(Sound) then
		return SFX
	end

	return nil
end

local function applyDirectAudioVolume(Sound)
	local Percent = getDirectAudioPercent(Sound)
	if Percent == nil then return false end

	if AudioState.DirectOriginalVolumes[Sound] == nil then
		local BaseVolume = Sound.Volume

		if Environment.NotorietyAudioMigrateFromV5Double == true then
			local LegacyPercent = getLegacyV5DirectAudioPercent(Sound)
			local CurrentPercent = getDirectAudioPercent(Sound)
			local Combined = type(LegacyPercent) == "number" and type(CurrentPercent) == "number"
				and LegacyPercent * CurrentPercent or nil
			if type(Combined) == "number" and Combined > 0.000001 then
				BaseVolume /= Combined
			end
		elseif Environment.NotorietyAudioMigrateFromV5 == true then
			local LegacyPercent = getLegacyV5DirectAudioPercent(Sound)
			if type(LegacyPercent) == "number" and LegacyPercent > 0.000001 then
				BaseVolume /= LegacyPercent
			end
		end

		AudioState.DirectOriginalVolumes[Sound] = BaseVolume
	end

	local Base = AudioState.DirectOriginalVolumes[Sound]
	local Target = Base * Percent
	if math.abs(Sound.Volume - Target) > 0.0001 then
		Sound.Volume = Target
	end
	return true
end

local function getSafeAudioRoots()
	local Roots = {}
	local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local Camera = Workspace.CurrentCamera
	for _, Root in {
		PlayerGui,
		Workspace:FindFirstChild("Map"),
		Workspace:FindFirstChild("Police"),
		Workspace:FindFirstChild("Criminals"),
		Camera,
		LocalPlayer.Character,
	} do
		if Root then table.insert(Roots, Root) end
	end
	return Roots
end

local function scanSafeAudioRoots()
	AudioState.ScanGeneration += 1
	local Generation = AudioState.ScanGeneration

	task.spawn(function()
		local Queue = getSafeAudioRoots()
		local Index = 1
		local Visited = 0

		while Index <= #Queue and Generation == AudioState.ScanGeneration and not Environment.NotorietyUnloaded do
			local Object = Queue[Index]
			Index += 1

			if typeof(Object) == "Instance" and Object.Parent ~= nil then
				if Object:IsA("Sound") then
					applyDirectAudioVolume(Object)
				end

				local Success, Children = pcall(Object.GetChildren, Object)
				if Success then
					for _, Child in Children do
						table.insert(Queue, Child)
					end
				end
			end

			Visited += 1
			if Visited % 200 == 0 then
				task.wait()
			end
		end

		if Generation == AudioState.ScanGeneration then
			Environment.NotorietyAudioMigrateFromV5 = nil
			Environment.NotorietyAudioMigrateFromV5Double = nil
		end
	end)
end

local function ensureSafeAudioWatchers()
	if #AudioState.RootConnections > 0 then return end

	for _, Root in getSafeAudioRoots() do
		table.insert(AudioState.RootConnections, Root.DescendantAdded:Connect(function(Descendant)
			if not Environment.NotorietyUnloaded and Descendant:IsA("Sound") then
				task.defer(applyDirectAudioVolume, Descendant)
			end
		end))
	end
end

local function setAudioGroups(Groups, Volume)
	for _, Group in Groups or {} do
		if Group.Parent then
			Group.Volume = Volume
		end
	end
end

local function applyAudioVolumes()
	if Environment.NotorietyUnloaded or AudioState.Applying then return end
	AudioState.Applying = true
	resolveAudioGroups()
	ensureSafeAudioWatchers()

	local Music = math.clamp(tonumber(Environment.NotorietyMusicVolume) or 100, 0, 100) / 100
	local SFX = math.clamp(tonumber(Environment.NotorietySFXVolume) or 100, 0, 100) / 100
	local LocalGunshots = math.clamp(tonumber(Environment.NotorietyLocalGunshotsVolume) or 100, 0, 100) / 100
	local Gunshots = math.clamp(tonumber(Environment.NotorietyGunshotsVolume) or 100, 0, 100) / 100
	local MapAmbience = math.clamp(tonumber(Environment.NotorietyMapAmbienceVolume) or 100, 0, 100) / 100
	local Voices = math.clamp(tonumber(Environment.NotorietyVoicesVolume) or 100, 0, 100) / 100
	local UI = math.clamp(tonumber(Environment.NotorietyUIVolume) or 100, 0, 100) / 100

	setAudioGroups(AudioState.Groups.Music, Music)
	setAudioGroups(AudioState.Groups.SFX, SFX)
	setAudioGroups(AudioState.Groups.SFXSibling, SFX)
	setAudioGroups(AudioState.Groups.LocalGunshots, LocalGunshots)
	setAudioGroups(AudioState.Groups.Gunshots, Gunshots)
	setAudioGroups(AudioState.Groups.MapAmbience, MapAmbience)
	setAudioGroups(AudioState.Groups.Voices, Voices)
	setAudioGroups(AudioState.Groups.UI, SFX * UI)

	scanSafeAudioRoots()
	AudioState.Applying = false
end

local function restoreAudioVolumes()
	for _, Connection in AudioState.RootConnections do
		pcall(function() Connection:Disconnect() end)
	end
	table.clear(AudioState.RootConnections)

	for Sound, Volume in AudioState.DirectOriginalVolumes do
		if typeof(Sound) == "Instance" and Sound.Parent ~= nil and type(Volume) == "number" then
			pcall(function() Sound.Volume = Volume end)
		end
	end

	for Group, Volume in AudioState.OriginalVolumes do
		if typeof(Group) == "Instance" and Group.Parent ~= nil then
			pcall(function() Group.Volume = Volume end)
		end
	end

	table.clear(AudioState.Groups)
	AudioState.ScanGeneration += 1
	AudioState.Applying = false
end


local YellPatchState = {
	Module = nil,
	Original = nil,
	Wrapper = nil,
	AutoRefresh = 0,
	AutoLastFire = 0,
	AutoGeneration = 0,
	AutoSeen = setmetatable({}, {
		__mode = "k",
	}),
	NoDelayTargets = {},
	NoDelayConnections = Environment.NotorietyNoDelayConnections,
	TargetParts = setmetatable({}, {
		__mode = "k",
	}),
	SkillCache = {},
}

local function getYellModule()
	local ReplicatedScripts = RS_Package:FindFirstChild("ReplicatedScripts")
	local YellScript = ReplicatedScripts and ReplicatedScripts:FindFirstChild("Yell")

	if not YellScript or not YellScript:IsA("ModuleScript") then
		return nil
	end

	local Success, Result = pcall(require, YellScript)

	if Success and type(Result) == "table" and type(Result.Yell) == "function" then
		return Result
	end

	return nil
end

local function isPartInViewport(Part, Camera)
	if not Part or not Part:IsA("BasePart") then
		return false
	end

	Camera = Camera or Workspace.CurrentCamera

	if not Camera then
		return false
	end

	local ViewportPoint, OnScreen = Camera:WorldToViewportPoint(Part.Position)
	return OnScreen and ViewportPoint.Z > 0
end

local function hasYellSkill(PlayerName, TreeName, Skill)
	local CacheKey = PlayerName .. "|" .. TreeName .. "|" .. Skill
	local Cached = YellPatchState.SkillCache[CacheKey]

	if Cached ~= nil then
		return Cached
	end

	local PlayerData = ReplicatedStorage:FindFirstChild("PlayerData")
	local PlayerFolder = PlayerData and PlayerData:FindFirstChild(PlayerName)
	local Data = PlayerFolder and PlayerFolder:FindFirstChild(PlayerName .. "'s Data")
	local SkillTree = Data and Data:FindFirstChild("SkillTree")
	local Tree = SkillTree and SkillTree:FindFirstChild(TreeName .. "Tree")
	local Result = Tree ~= nil
		and type(Tree.Value) == "string"
		and string.find(Tree.Value, Skill, 1, true) ~= nil

	YellPatchState.SkillCache[CacheKey] = Result == true
	return Result == true
end

local function getYellTargetPart(Object)
	if not Object then
		return nil
	end

	local Cached = YellPatchState.TargetParts[Object]

	if Cached and Cached.Parent then
		return Cached
	end

	if Object:IsA("BasePart") then
		YellPatchState.TargetParts[Object] = Object
		return Object
	end

	local Part = Object:FindFirstChild("Head")
		or Object:FindFirstChild("HumanoidRootPart")
		or Object:FindFirstChild("Torso")
		or Object:FindFirstChild("UpperTorso")

	if not Part and Object:IsA("Model") then
		Part = Object.PrimaryPart
	end

	if Part and Part:IsA("BasePart") then
		YellPatchState.TargetParts[Object] = Part
		return Part
	end

	return nil
end

local function canYellSeeTarget(Actor, TargetPart, Camera)
	if not Actor or not TargetPart then
		return false
	end

	Camera = Camera or Workspace.CurrentCamera

	local OriginCFrame

	if Actor == LocalPlayer.Character and Camera then
		OriginCFrame = Camera.CFrame
	else
		local Root = Actor:FindFirstChild("HumanoidRootPart")

		if not Root or not Root:IsA("BasePart") then
			return false
		end

		OriginCFrame = Root.CFrame * CFrame.new(0, 1.5, 0)
	end

	local Origin = OriginCFrame.Position
	local Direction = TargetPart.Position - Origin

	if Direction.Magnitude <= 0.01 then
		return true
	end

	local Ignore = {
		Actor,
		Camera,
		Workspace:FindFirstChild("Tracers"),
		Workspace:FindFirstChild("Bodies"),
		Workspace:FindFirstChild("InvisibleParts"),
		Workspace:FindFirstChild("MapZones"),
		Workspace:FindFirstChild("NonPoliceObjectives"),
		Workspace:FindFirstChild("Bags"),
	}
	local FilteredIgnore = {}

	for _, Object in Ignore do
		if Object then
			table.insert(FilteredIgnore, Object)
		end
	end

	local Hit, HitPosition = Workspace:FindPartOnRayWithIgnoreList(
		Ray.new(Origin, Direction),
		FilteredIgnore
	)

	if not Hit then
		return true
	end

	if Hit:IsDescendantOf(TargetPart.Parent) then
		return true
	end

	return HitPosition ~= nil and (HitPosition - TargetPart.Position).Magnitude < 2
end

local function shouldIncludeYellTarget(Actor, TargetPart, Camera)
	if not TargetPart then
		return false
	end

	local Method = Environment.NotorietyYellMarkMethod

	if Method == "Viewport" and not isPartInViewport(TargetPart, Camera) then
		return false
	end

	if Method ~= "Viewport" and Method ~= "Whole Game" then
		return false
	end

	if Environment.NotorietyYellThroughWalls then
		return true
	end

	return canYellSeeTarget(Actor, TargetPart, Camera)
end

local function shouldIncludeTeammateYellTarget(Actor, TargetPart, Camera)
	if not TargetPart then
		return false
	end

	local Method = Environment.NotorietyYellMarkMethod

	if Method == "Viewport" and not isPartInViewport(TargetPart, Camera) then
		return false
	end

	if Method ~= "Viewport" and Method ~= "Whole Game" then
		return false
	end

	local OriginPart = Actor:FindFirstChild("HumanoidRootPart") or Actor.PrimaryPart

	if not Environment.NotorietyTeammateYellInfiniteRange
		and OriginPart
		and (TargetPart.Position - OriginPart.Position).Magnitude > 100
	then
		return false
	end

	if Environment.NotorietyTeammateYellThroughWalls then
		return true
	end

	return canYellSeeTarget(Actor, TargetPart, Camera)
end

local function createYellMarkWrapper()
	return function(_, Actor, _, MarkOnly, AutoMode)
		local IsPlayer = typeof(Actor) == "Instance" and Actor:IsA("Player")

		if IsPlayer then
			Actor = Actor.Character
		end

		if typeof(Actor) ~= "Instance" or not Actor:IsA("Model") then
			return 0, false
		end

		local Camera = Workspace.CurrentCamera

		if not Camera then
			return 0, false
		end

		local Targets = {}
		local YellTier = 0
		local GameStatus = RS_Package:FindFirstChild("ReplicatedGameStatus")
		local Caught = GameStatus and GameStatus:FindFirstChild("Caught")
		local IsCaught = Caught and Caught.Value == true

		if not MarkOnly then
			local Citizens = Workspace:FindFirstChild("Citizens")

			if Citizens then
				for _, Citizen in Citizens:GetChildren() do
					local TargetPart = getYellTargetPart(Citizen)

					if TargetPart and shouldIncludeYellTarget(Actor, TargetPart, Camera) then
						if Citizen:FindFirstChild("Alerted") then
							table.insert(Targets, Citizen)
							YellTier = math.max(YellTier, 1)
						end

						if Citizen:FindFirstChild("Cuffed") then
							table.insert(Targets, Citizen)
							YellTier = math.max(YellTier, 4)
						end
					end
				end
			end
		end

		if not IsCaught then
			local Cameras = Workspace:FindFirstChild("Cameras")

			if Cameras then
				for _, CameraObject in Cameras:GetChildren() do
					local TargetPart = getYellTargetPart(CameraObject)

					if TargetPart and shouldIncludeYellTarget(Actor, TargetPart, Camera) then
						table.insert(Targets, CameraObject)
						YellTier = 2
					end
				end
			end
		end

		if not MarkOnly then
			local Criminals = Workspace:FindFirstChild("Criminals")

			if Criminals then
				local CanBoost = hasYellSkill(Actor.Name, "Mastermind", "k")
				local CanInspire = hasYellSkill(Actor.Name, "Mastermind", "s")
				local ForceFollowTarget

				for _, Criminal in Criminals:GetChildren() do
					if Criminal ~= Actor then
						local TargetPart = getYellTargetPart(Criminal)

						if TargetPart and shouldIncludeTeammateYellTarget(Actor, TargetPart, Camera) then
							local Health = Criminal:FindFirstChild("Health")
							local ShouldTarget = false

							if Health
								and Health.Value <= 0
								and CanInspire
								and Actor:GetAttribute("DIDINSPIRE") == nil
							then
								ShouldTarget = true
								YellTier = 5
							elseif CanBoost
								and not (Criminal:GetAttribute("CHARISMA") or Criminal:GetAttribute("charisma"))
							then
								ShouldTarget = true
								YellTier = math.max(YellTier, 3)
							elseif IsCaught and Criminal:FindFirstChild("ForceFollow") and not ForceFollowTarget then
								ForceFollowTarget = Criminal
							end

							if ShouldTarget then
								table.insert(Targets, Criminal)
							end
						end
					end
				end

				if ForceFollowTarget then
					table.insert(Targets, ForceFollowTarget)
					YellTier = 5
				end
			end
		end

		local Police = Workspace:FindFirstChild("Police")

		if Police then
			for _, Officer in Police:GetChildren() do
				local TargetPart = getYellTargetPart(Officer)

				if TargetPart and shouldIncludeYellTarget(Actor, TargetPart, Camera) then
					table.insert(Targets, Officer)
					YellTier = math.max(YellTier, 4)
				end
			end
		end

		if AutoMode then
			YellPatchState.AutoGeneration += 1
			local Generation = YellPatchState.AutoGeneration
			local HasNewTarget = false

			for _, Target in Targets do
				if YellPatchState.AutoSeen[Target] == nil then
					HasNewTarget = true
				end

				YellPatchState.AutoSeen[Target] = Generation
			end

			for Target, SeenGeneration in YellPatchState.AutoSeen do
				if SeenGeneration ~= Generation then
					YellPatchState.AutoSeen[Target] = nil
				end
			end

			if #Targets == 0 then
				return YellTier, false
			end

			if not HasNewTarget and os.clock() - YellPatchState.AutoLastFire < 2 then
				return YellTier, false
			end
		end

		if IsPlayer and #Targets > 0 then
			local YellRemotes = RS_Package:FindFirstChild("Remotes")
			local PlayerYell = YellRemotes and YellRemotes:FindFirstChild("PlayerYell")

			if PlayerYell and PlayerYell:IsA("RemoteEvent") then
				PlayerYell:FireServer(Targets, MarkOnly)
			end
		end

		if not MarkOnly and (not AutoMode or #Targets > 0) then
			local GestureName = if YellTier == 6 then "Whistle"
				elseif YellTier == 5 then "Inspire"
				elseif YellTier == 3 then "Boost"
				elseif YellTier == 1 then "StayDown"
				else "Point"
			local YellRemotes = RS_Package:FindFirstChild("Remotes")
			local YellEvent = YellRemotes and YellRemotes:FindFirstChild("YellEvent")

			if YellEvent and type(YellEvent.Fire) == "function" then
				YellEvent:Fire({
					Type = "Gesture",
					Name = GestureName,
					YellTier = YellTier,
				})
			end
		end

		if AutoMode and #Targets > 0 then
			YellPatchState.AutoLastFire = os.clock()
		end

		return YellTier, #Targets > 0
	end
end

local function restoreYellMarkPatch()
	local Module = YellPatchState.Module
	local Original = YellPatchState.Original
	local Wrapper = YellPatchState.Wrapper

	if type(Module) == "table"
		and type(Original) == "function"
		and Module.Yell == Wrapper
	then
		Module.Yell = Original
	end

	YellPatchState.Module = nil
	YellPatchState.Original = nil
	YellPatchState.Wrapper = nil
end

local function applyYellMarkPatch()
	if Environment.NotorietyUnloaded or not Environment.NotorietyInfiniteYellMarkEnabled then
		return false
	end

	if Environment.NotorietyYellMarkMethod == "Original" then
		restoreYellMarkPatch()
		return true
	end

	local Module = getYellModule()

	if not Module then
		return false
	end

	if YellPatchState.Module == Module
		and type(YellPatchState.Wrapper) == "function"
		and Module.Yell == YellPatchState.Wrapper
	then
		return true
	end

	restoreYellMarkPatch()

	local Original = Module.Yell

	if type(Original) ~= "function" then
		return false
	end

	local Wrapper = createYellMarkWrapper()
	YellPatchState.Module = Module
	YellPatchState.Original = Original
	YellPatchState.Wrapper = Wrapper
	Module.Yell = Wrapper

	return Module.Yell == Wrapper
end

local function setYellMarkPatchEnabled(Enabled)
	Environment.NotorietyInfiniteYellMarkEnabled = Enabled == true

	if Environment.NotorietyInfiniteYellMarkEnabled then
		applyYellMarkPatch()
	else
		restoreYellMarkPatch()
	end
end

local function setYellMarkMethod(Method)
	Method = tostring(Method)

	if Method ~= "Viewport" and Method ~= "Whole Game" and Method ~= "Original" then
		Method = "Viewport"
	end

	Environment.NotorietyYellMarkMethod = Method
	YellPatchState.AutoGeneration = 0
	YellPatchState.AutoLastFire = 0
	table.clear(YellPatchState.AutoSeen)

	if Environment.NotorietyInfiniteYellMarkEnabled then
		applyYellMarkPatch()
	elseif Method == "Original" then
		restoreYellMarkPatch()
	end
end

local function setYellThroughWalls(Enabled)
	Environment.NotorietyYellThroughWalls = Enabled == true
	YellPatchState.AutoGeneration = 0
	YellPatchState.AutoLastFire = 0
	table.clear(YellPatchState.AutoSeen)
end

local function setTeammateYellInfiniteRange(Enabled)
	Environment.NotorietyTeammateYellInfiniteRange = Enabled == true
	YellPatchState.AutoGeneration = 0
	YellPatchState.AutoLastFire = 0
	table.clear(YellPatchState.AutoSeen)
end

local function setTeammateYellThroughWalls(Enabled)
	Environment.NotorietyTeammateYellThroughWalls = Enabled == true
	YellPatchState.AutoGeneration = 0
	YellPatchState.AutoLastFire = 0
	table.clear(YellPatchState.AutoSeen)
end

YellPatchState.RefreshNoDelayTargets = function()
	table.clear(YellPatchState.NoDelayTargets)

	if type(getgc) ~= "function"
		or type(debug) ~= "table"
		or type(debug.getupvalues) ~= "function"
		or type(debug.setupvalue) ~= "function"
	then
		return false
	end

	local Module = getYellModule()

	if not Module then
		return false
	end

	local Success, Objects = pcall(getgc, true)

	if not Success or type(Objects) ~= "table" then
		return false
	end

	for _, Function in pairs(Objects) do
		if type(Function) == "function" then
			local UpvalueSuccess, Upvalues = pcall(debug.getupvalues, Function)

			if UpvalueSuccess and type(Upvalues) == "table" then
				local ModuleIndex

				for Index, Value in pairs(Upvalues) do
					if Value == Module then
						ModuleIndex = Index
						break
					end
				end

				if ModuleIndex then
					local Source = ""

					if type(debug.getinfo) == "function" then
						local InfoSuccess, Info = pcall(debug.getinfo, Function)

						if InfoSuccess and type(Info) == "table" then
							Source = tostring(Info.source or Info.short_src or "")
						end
					end

					if Source == "" or string.find(Source, "HandleInteractionPrompts", 1, true) then
						local DebounceIndex

						if ModuleIndex == 9 and type(Upvalues[5]) == "boolean" then
							DebounceIndex = 5
						elseif ModuleIndex == 5 and type(Upvalues[1]) == "boolean" then
							DebounceIndex = 1
						end

						if DebounceIndex then
							table.insert(YellPatchState.NoDelayTargets, {
								Function = Function,
								Index = DebounceIndex,
							})
						end
					end
				end
			end
		end
	end

	return #YellPatchState.NoDelayTargets > 0
end

YellPatchState.ApplyNoDelay = function()
	if Environment.NotorietyUnloaded or not Environment.NotorietyNoYellDelayEnabled then
		return false
	end

	if #YellPatchState.NoDelayTargets == 0 then
		YellPatchState.RefreshNoDelayTargets()
	end

	local Patched = false

	for _, Target in YellPatchState.NoDelayTargets do
		if type(Target) == "table"
			and type(Target.Function) == "function"
			and type(Target.Index) == "number"
		then
			local Success = pcall(debug.setupvalue, Target.Function, Target.Index, false)

			if Success then
				Patched = true
			end
		end
	end

	return Patched
end

YellPatchState.ClearNoDelayConnections = function()
	for _, Connection in YellPatchState.NoDelayConnections do
		pcall(function()
			Connection:Disconnect()
		end)
	end

	table.clear(YellPatchState.NoDelayConnections)
end

YellPatchState.ConnectNoDelaySignals = function()
	YellPatchState.ClearNoDelayConnections()

	if Environment.NotorietyUnloaded or not Environment.NotorietyNoYellDelayEnabled then
		return
	end

	local function ResetDebounce()
		if not Environment.NotorietyNoYellDelayEnabled then
			return
		end

		YellPatchState.ApplyNoDelay()
		task.defer(YellPatchState.ApplyNoDelay)
	end

	local PlayerData = ReplicatedStorage:FindFirstChild("PlayerData")
	local PlayerFolder = PlayerData and PlayerData:FindFirstChild(LocalPlayer.Name)
	local DataFolder = PlayerFolder and PlayerFolder:FindFirstChild(LocalPlayer.Name .. "'s Data")
	local Options = DataFolder and DataFolder:FindFirstChild("Options")
	local Keybinds = Options and Options:FindFirstChild("Keybinds")
	local ControllerKeybinds = Options and Options:FindFirstChild("KeybindsController")
	local InteractShout = Keybinds and Keybinds:FindFirstChild("InteractShout")
	local ControllerShout = ControllerKeybinds and ControllerKeybinds:FindFirstChild("Shout/SecondaryInteract")

	table.insert(
		YellPatchState.NoDelayConnections,
		UserInputService.InputBegan:Connect(function(Input, Processed)
			if Processed then
				return
			end

			local KeyboardKey = InteractShout and Enum.KeyCode[InteractShout.Value]
			local ControllerKey = ControllerShout and Enum.KeyCode[ControllerShout.Value]

			if Input.KeyCode == KeyboardKey or Input.KeyCode == ControllerKey then
				ResetDebounce()
			end
		end)
	)

	local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
	local MainGui = SGPackage and SGPackage:FindFirstChild("MainGui")
	local MobileUI = MainGui and MainGui:FindFirstChild("MobileUI")
	local Buttons = MobileUI and MobileUI:FindFirstChild("Buttons")
	local Action = Buttons and Buttons:FindFirstChild("Action")
	local YellButton = Action and Action:FindFirstChild("Yell")

	if YellButton and YellButton:IsA("GuiButton") then
		table.insert(
			YellPatchState.NoDelayConnections,
			YellButton.MouseButton1Down:Connect(ResetDebounce)
		)
	end
end

YellPatchState.SetNoDelayEnabled = function(Enabled)
	Environment.NotorietyNoYellDelayEnabled = Enabled == true

	if Environment.NotorietyNoYellDelayEnabled then
		YellPatchState.RefreshNoDelayTargets()
		YellPatchState.ApplyNoDelay()
		YellPatchState.ConnectNoDelaySignals()
	else
		YellPatchState.ClearNoDelayConnections()
		table.clear(YellPatchState.NoDelayTargets)
	end
end

YellPatchState.SetAutoYellEnabled = function(Enabled)
	Environment.NotorietyAutoYellEnabled = Enabled == true
	YellPatchState.AutoRefresh = 0
	YellPatchState.AutoLastFire = 0
	YellPatchState.AutoGeneration = 0
	table.clear(YellPatchState.AutoSeen)
end

YellPatchState.AutoYell = function()
	if Environment.NotorietyUnloaded or not Environment.NotorietyAutoYellEnabled then
		return false
	end

	local Module = getYellModule()
	local Character = LocalPlayer.Character

	if not Module
		or not Character
		or not Character.Parent
	then
		return false
	end

	local Success, _, Fired = pcall(function()
		if Environment.NotorietyYellMarkMethod == "Original" then
			if os.clock() - YellPatchState.AutoLastFire < 2 then
				return 0, false
			end

			YellPatchState.AutoLastFire = os.clock()
			return Module:Yell(LocalPlayer, math.huge, nil), true
		end

		return Module:Yell(LocalPlayer, math.huge, nil, true)
	end)

	if not Success or Fired == false then
		return false
	end

	local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
	local MaskOn = SGPackage and SGPackage:FindFirstChild("MaskOn")
	local MainGui = SGPackage and SGPackage:FindFirstChild("MainGui")
	local Events = MainGui and MainGui:FindFirstChild("Events")
	local LocalYell = Events and Events:FindFirstChild("Yell")

	if LocalYell and LocalYell:IsA("BindableEvent") then
		LocalYell:Fire(Character, true, not (MaskOn and MaskOn.Value == true))
	end

	return true
end

local MAX_VALUE = 999999

if type(Environment.NotorietyPoliceOriginalSizes) ~= "table" then
	Environment.NotorietyPoliceOriginalSizes = setmetatable({}, {
		__mode = "k",
	})
end

local PoliceOriginalSizes = Environment.NotorietyPoliceOriginalSizes
local DEFAULT_POLICE_HEAD_SIZE = Vector3.new(1.1908922, 1.1954262, 1.1909529)
local DEFAULT_POLICE_TORSO_SIZE = Vector3.new(2, 2, 1)

local function isReasonablePolicePartSize(Size)
	return typeof(Size) == "Vector3"
		and Size.X >= 0.25
		and Size.Y >= 0.25
		and Size.Z >= 0.25
		and Size.X <= 4
		and Size.Y <= 4
		and Size.Z <= 4
end

local function getDefaultPolicePartState(Object)
	return {
		Size = if Object.Name == "Head" then DEFAULT_POLICE_HEAD_SIZE else DEFAULT_POLICE_TORSO_SIZE,
		Transparency = 0,
		Massless = false,
		CanCollide = false,
	}
end

local function restorePolicePart(Object)
	local Original = PoliceOriginalSizes[Object]

	if Original and Object.Parent then
		local State = if typeof(Original) == "Vector3"
			then {
				Size = Original,
				Transparency = Object.Transparency,
				Massless = Object.Massless,
				CanCollide = Object.CanCollide,
			}
			else Original

		if type(State) ~= "table" or not isReasonablePolicePartSize(State.Size) then
			State = getDefaultPolicePartState(Object)
		end

		Object.Size = State.Size
		Object.Transparency = State.Transparency
		Object.Massless = State.Massless
		Object.CanCollide = State.CanCollide

		PoliceOriginalSizes[Object] = nil
	end
end

local function resizePoliceNPC(NPC)
	if not NPC or not NPC:IsA("Model") then
		return
	end

	local Head = NPC:FindFirstChild("Head")
	local Torso = NPC:FindFirstChild("Torso")
	local Target = Head or Torso

	if not Environment.NotorietyPoliceHeadScaleEnabled then
		if Head and Head:IsA("BasePart") then
			restorePolicePart(Head)
		end

		if Torso and Torso:IsA("BasePart") then
			restorePolicePart(Torso)
		end

		return
	end

	if Head and Torso then
		restorePolicePart(Torso)
	end

	if Target and Target:IsA("BasePart") then
		local Original = PoliceOriginalSizes[Target]
		local OriginalSize = typeof(Original) == "Vector3" and Original
			or (type(Original) == "table" and Original.Size or nil)

		if not isReasonablePolicePartSize(OriginalSize) then
			local State = if isReasonablePolicePartSize(Target.Size)
				then {
					Size = Target.Size,
					Transparency = Target.Transparency,
					Massless = Target.Massless,
					CanCollide = Target.CanCollide,
				}
				else getDefaultPolicePartState(Target)
			PoliceOriginalSizes[Target] = State
		elseif typeof(Original) == "Vector3" then
			PoliceOriginalSizes[Target] = {
				Size = Original,
				Transparency = Target.Transparency,
				Massless = Target.Massless,
				CanCollide = Target.CanCollide,
			}
		end

		local Stored = PoliceOriginalSizes[Target]
		local BaseSize = typeof(Stored) == "Vector3" and Stored or Stored.Size
		Target.Size = BaseSize * Environment.NotorietyPoliceHeadScale
		Target.Transparency = 0.5
		Target.Massless = true
		Target.CanCollide = false
	end
end

local function getPoliceNPC(Object, PoliceFolder)
	local Current = Object

	while Current and Current.Parent ~= PoliceFolder do
		Current = Current.Parent
	end

	if Current and Current:IsA("Model") then
		return Current
	end
end

local PoliceFolder = Workspace:FindFirstChild("Police")

local function applyPoliceHeadScale()
	if not PoliceFolder then
		return
	end

	for _, NPC in PoliceFolder:GetChildren() do
		resizePoliceNPC(NPC)
	end
end

local function setPoliceHeadScaleEnabled(Enabled)
	Environment.NotorietyPoliceHeadScaleEnabled = Enabled == true
	applyPoliceHeadScale()
end

if PoliceFolder then
	Environment.NotorietyPoliceHitboxConnection = PoliceFolder.DescendantAdded:Connect(
		function(Object)
			local NPC = getPoliceNPC(Object, PoliceFolder)

			if NPC then
				task.defer(resizePoliceNPC, NPC)
			end
		end
	)
end

local MaxedValues = {
	Stamina = MAX_VALUE,
	MaxStamina = MAX_VALUE,
	PrimaryAmmo = MAX_VALUE,
	PrimaryAmmoMax = MAX_VALUE,
	SecondaryAmmo = MAX_VALUE,
	SecondaryAmmoMax = MAX_VALUE,
	GadgetAmmo = MAX_VALUE,
	GadgetAmmoMax = MAX_VALUE,
	EquipmentLeft = MAX_VALUE,
	SecondEquipmentLeft = MAX_VALUE,
	Crit = 100,
	Dodge = 100,
	Detection = 0,
}

local FiniteSupplyCaps = setmetatable({}, {
	__mode = "k",
})

local function getFiniteSupplyCap(Value, SuggestedCap)
	local ExistingCap = FiniteSupplyCaps[Value]
	local CurrentValue = Value.Value

	if type(SuggestedCap) == "number" and SuggestedCap > 0 then
		if type(CurrentValue) == "number" and CurrentValue >= 0 and CurrentValue < 1000 then
			SuggestedCap = math.max(SuggestedCap, CurrentValue)
		end

		if not ExistingCap or SuggestedCap > ExistingCap then
			ExistingCap = SuggestedCap
		end
	elseif type(CurrentValue) == "number" and CurrentValue > 0 and CurrentValue < 1000 then
		if not ExistingCap or CurrentValue > ExistingCap then
			ExistingCap = CurrentValue
		end
	end

	FiniteSupplyCaps[Value] = ExistingCap
	return ExistingCap
end

local function replenishFiniteSupplies(Character)
	local GadgetAmmoMax = Character:FindFirstChild("GadgetAmmoMax")

	if GadgetAmmoMax and GadgetAmmoMax:IsA("ValueBase") and type(GadgetAmmoMax.Value) == "number" then
		local Capacity = GadgetAmmoMax:FindFirstChild("Capacity")
		local SuggestedCap = Capacity and Capacity:IsA("ValueBase") and type(Capacity.Value) == "number"
			and Capacity.Value
			or nil
		local Cap = getFiniteSupplyCap(GadgetAmmoMax, SuggestedCap)

		if Cap and GadgetAmmoMax.Value < Cap then
			GadgetAmmoMax.Value = Cap
		end
	end

	for _, Name in {
		"EquipmentLeft",
		"SecondEquipmentLeft",
	} do
		local Value = Character:FindFirstChild(Name)

		if Value and Value:IsA("ValueBase") and type(Value.Value) == "number" then
			local Cap = getFiniteSupplyCap(Value)

			if Cap and Value.Value < Cap then
				Value.Value = Cap
			end
		end
	end
end

local WeaponState = {
	RequireFunctions = {},
	RequireUnavailable = false,
	RequireFailures = 0,
	FallbackQueued = false,
	FallbackAttempts = 0,
	ModuleCache = setmetatable({}, {
		__mode = "k",
	}),
	Backups = {},
	RuntimeWeapons = setmetatable({}, {
		__mode = "k",
	}),
	RuntimeAccuracyBackups = setmetatable({}, {
		__mode = "k",
	}),
	RuntimeRecoilBackups = setmetatable({}, {
		__mode = "k",
	}),
	RuntimeSpreadBackups = setmetatable({}, {
		__mode = "k",
	}),
	RuntimeSilentAimBackups = setmetatable({}, {
		__mode = "k",
	}),
	ProjectileSilentAim = nil,
	RuntimeRefresh = 0,
}

local function addRequireFunction(Value)
	if type(Value) ~= "function" then
		return
	end

	for _, Existing in WeaponState.RequireFunctions do
		if Existing == Value then
			return
		end
	end

	table.insert(WeaponState.RequireFunctions, Value)
end

addRequireFunction(require)

if type(getrenv) == "function" then
	local Success, RuntimeEnvironment = pcall(getrenv)

	if Success and type(RuntimeEnvironment) == "table" then
		addRequireFunction(rawget(RuntimeEnvironment, "require"))
	end
end

if type(getfenv) == "function" then
	local Success, CurrentEnvironment = pcall(getfenv, 0)

	if Success and type(CurrentEnvironment) == "table" then
		addRequireFunction(rawget(CurrentEnvironment, "require"))
	end
end

local function getWeaponBackup(Data)
	local Backup = WeaponState.Backups[Data]

	if Backup then
		return Backup
	end

	Backup = {
		Fields = {},
		Patterns = {},
		Steps = {},
		NestedFields = {},
	}

	WeaponState.Backups[Data] = Backup
	return Backup
end

local function captureField(Data, Backup, Key)
	if Backup.Fields[Key] then
		return
	end

	local Value = rawget(Data, Key)

	Backup.Fields[Key] = {
		Exists = Value ~= nil,
		Value = Value,
	}
end

local function captureNestedField(Backup, Container, Key)
	local Fields = Backup.NestedFields[Container]

	if not Fields then
		Fields = {}
		Backup.NestedFields[Container] = Fields
	end

	if Fields[Key] then
		return
	end

	local Value = rawget(Container, Key)

	Fields[Key] = {
		Exists = Value ~= nil,
		Value = Value,
	}
end

local function shortenSequence(Sequence, Backup)
	if type(Sequence) ~= "table" then
		return
	end

	for _, Step in Sequence do
		if type(Step) == "table" and type(Step[7]) == "number" then
			if not Backup.Steps[Step] then
				Backup.Steps[Step] = {
					Exists = rawget(Step, 7) ~= nil,
					Value = rawget(Step, 7),
				}
			end

			Step[7] = 0.01
		end
	end
end

local function shortenGunSequence(Value, Backup, Seen, Depth, FireDelay, BoltDuration)
	if type(Value) ~= "table" or Depth > 8 or Seen[Value] then
		return
	end

	Seen[Value] = true

	if type(Value[7]) == "number" then
		if not Backup.Steps[Value] then
			Backup.Steps[Value] = {
				Exists = rawget(Value, 7) ~= nil,
				Value = rawget(Value, 7),
			}
		end

		Value[7] = BoltDuration
	end

	for Key, Item in Value do
		local LowerKey = type(Key) == "string" and string.lower(Key) or nil

		if LowerKey and type(Item) == "number" then
			if LowerKey == "firedelay"
				or LowerKey == "shotdelay"
				or LowerKey == "cooldown"
			then
				captureNestedField(Backup, Value, Key)
				Value[Key] = FireDelay
			elseif LowerKey == "boltduration" or LowerKey == "duration" then
				captureNestedField(Backup, Value, Key)
				Value[Key] = BoltDuration
			end
		elseif LowerKey == "boltlock" and type(Item) == "boolean" then
			captureNestedField(Backup, Value, Key)
			Value[Key] = false
		end

		if type(Item) == "table" then
			shortenGunSequence(Item, Backup, Seen, Depth + 1, FireDelay, BoltDuration)
		end
	end
end

local function patchGunSequences(Data, Backup)
	local Seen = {}
	local FireDelay = tonumber(Environment.NotorietyFireDelay) or 0.01
	local BoltDuration = tonumber(Environment.NotorietyBoltDuration) or 0.001

	for Key, Value in Data do
		if type(Key) == "string" and type(Value) == "table" then
			local LowerKey = string.lower(Key)

			if string.find(LowerKey, "shoot", 1, true)
				or string.find(LowerKey, "bolt", 1, true)
				or string.find(LowerKey, "fire", 1, true)
			then
				shortenGunSequence(Value, Backup, Seen, 0, FireDelay, BoltDuration)
			end
		end
	end
end

local applyWeaponData

local function isStandardGunData(Data)
	if type(Data) ~= "table" or rawget(Data, "WeaponType") ~= "Gun" then
		return false
	end

	local AmmoClass = rawget(Data, "AmmoClass")

	return AmmoClass == "Primary" or AmmoClass == "Secondary"
end

local function isInfiniteGunState(State, Data)
	if type(State) ~= "table" or not isStandardGunData(Data) then
		return false
	end

	local AmmoClass = rawget(Data, "AmmoClass") or rawget(State, "AmmoType")

	return AmmoClass == "Primary" or AmmoClass == "Secondary"
end

local function patchAmmoResult(Result, State)
	if not Environment.NotorietyWeaponEnabled
		or not Environment.NotorietyInfiniteAmmoEnabled
		or type(Result) ~= "table"
	then
		return Result
	end

	local Data = type(State) == "table" and rawget(State, "data") or nil

	if not isInfiniteGunState(State, Data) then
		return Result
	end

	for Key, Value in Result do
		if type(Key) == "string" and type(Value) == "number" then
			local LowerKey = string.lower(Key)

			if string.find(LowerKey, "ammo", 1, true)
				or string.find(LowerKey, "mag", 1, true)
				or LowerKey == "spare"
			then
				Result[Key] = MAX_VALUE
			end
		end
	end

	local AmmoMax = Result.AmmoMax

	if typeof(AmmoMax) == "Instance" and AmmoMax:IsA("ValueBase") and typeof(AmmoMax.Value) == "number" then
		AmmoMax.Value = MAX_VALUE
	end

	return Result
end

local function restoreAmmoWrapper(State)
	local Wrappers = Environment.NotorietyGetAmmoWrappers
	local Record = type(Wrappers) == "table" and Wrappers[State] or nil

	if type(Record) ~= "table" then
		return
	end

	if type(Record.Original) == "function" and State.getAmmo == Record.Wrapper then
		State.getAmmo = Record.Original
	end

	Wrappers[State] = nil
end

local function getDebugUpvalue(Function, Index)
	local DebugLibrary = debug

	if type(DebugLibrary) ~= "table" or type(DebugLibrary.getupvalue) ~= "function" then
		return nil
	end

	local Success, First, Second = pcall(DebugLibrary.getupvalue, Function, Index)

	if not Success or First == nil then
		return nil
	end

	if type(First) == "string" and Second ~= nil then
		return Second
	end

	if Second ~= nil then
		return Second
	end

	return First
end

local Targeting = {}

function Targeting.getCategory(TargetModel)
	if not TargetModel or TargetModel == LocalPlayer.Character then
		return nil
	end

	local PoliceFolder = Workspace:FindFirstChild("Police")
	if PoliceFolder and TargetModel:IsDescendantOf(PoliceFolder) then
		return "Police"
	end

	local CriminalsFolder = Workspace:FindFirstChild("Criminals")
	if CriminalsFolder and TargetModel:IsDescendantOf(CriminalsFolder) then
		local Player = Players:GetPlayerFromCharacter(TargetModel)
		if Player and Player ~= LocalPlayer then
			return "Criminals"
		end
	end

	return nil
end

function Targeting.isCategoryEnabled(Category, PoliceEnabled, CriminalsEnabled)
	if Category == "Police" then
		return PoliceEnabled == true
	end

	if Category == "Criminals" then
		return CriminalsEnabled == true
	end

	return false
end

function Targeting.isSilentAimCategoryEnabled(Category)
	return Targeting.isCategoryEnabled(
		Category,
		Environment.NotorietySilentAimTargetPolice,
		Environment.NotorietySilentAimTargetCriminals
	)
end

function Targeting.isWallBangCategoryEnabled(Category)
	return Targeting.isCategoryEnabled(
		Category,
		Environment.NotorietyWallBangTargetPolice,
		Environment.NotorietyWallBangTargetCriminals
	)
end

function Targeting.getPart(Target)
	return Target and (
		Target:FindFirstChild("Head", true)
		or Target:FindFirstChild("UpperTorso", true)
		or Target:FindFirstChild("Torso", true)
		or Target:FindFirstChild("HumanoidRootPart", true)
	) or nil
end

function Targeting.isAlive(Target)
	if not Target then
		return false
	end

	local Humanoid = Target:FindFirstChildWhichIsA("Humanoid", true)
	if not Humanoid or Humanoid.Health <= 0 then
		return false
	end

	local Health = Target:FindFirstChild("Health")
	if Health and Health:IsA("ValueBase") and type(Health.Value) == "number" and Health.Value <= 0 then
		return false
	end

	return true
end

function Targeting.forEach(PoliceEnabled, CriminalsEnabled, Callback)
	if PoliceEnabled then
		local PoliceFolder = Workspace:FindFirstChild("Police")
		if PoliceFolder then
			for _, Target in PoliceFolder:GetChildren() do
				Callback(Target, "Police")
			end
		end
	end

	if CriminalsEnabled then
		local CriminalsFolder = Workspace:FindFirstChild("Criminals")
		if CriminalsFolder then
			for _, Player in Players:GetPlayers() do
				if Player ~= LocalPlayer then
					local Target = Player.Character
					if Target and Target:IsDescendantOf(CriminalsFolder) then
						Callback(Target, "Criminals")
					end
				end
			end
		end
	end
end

function Targeting.isWallBangAllowed(TargetModel)
	if not Environment.NotorietyWallBangEnabled then
		return false
	end

	return Targeting.isWallBangCategoryEnabled(Targeting.getCategory(TargetModel))
end

function Targeting.isVisible(TargetModel, TargetPart)
	if Targeting.isWallBangAllowed(TargetModel) then
		return true
	end

	local Camera = Workspace.CurrentCamera

	if not Camera or not TargetPart then
		return false
	end

	local Origin = Camera.CFrame.Position
	local Direction = TargetPart.Position - Origin

	if Direction.Magnitude <= 0.001 then
		return true
	end

	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.IgnoreWater = true

	local Filter = {}
	local Character = LocalPlayer.Character

	if Character then
		table.insert(Filter, Character)
	end

	table.insert(Filter, Camera)
	Params.FilterDescendantsInstances = Filter

	local Result = Workspace:Raycast(Origin, Direction, Params)

	return Result == nil
		or Result.Instance == TargetPart
		or Result.Instance:IsDescendantOf(TargetModel)
end

function Targeting.getSilentAimTargetPart()
	if not Environment.NotorietySilentAimEnabled then
		return nil
	end

	local Camera = Workspace.CurrentCamera
	if not Camera then
		return nil
	end

	local MousePosition = UserInputService:GetMouseLocation()
	local MaxFOV = math.clamp(tonumber(Environment.NotorietySilentAimFOV) or 250, 0, 2000)
	local BestPart
	local BestDistance = math.huge

	Targeting.forEach(
		Environment.NotorietySilentAimTargetPolice,
		Environment.NotorietySilentAimTargetCriminals,
		function(Target, Category)
			if not Targeting.isSilentAimCategoryEnabled(Category) or not Targeting.isAlive(Target) then
				return
			end

			local HitPart = Targeting.getPart(Target)
			if not HitPart or not HitPart:IsA("BasePart") then
				return
			end

			local ScreenPosition, OnScreen = Camera:WorldToViewportPoint(HitPart.Position)
			if not OnScreen or ScreenPosition.Z <= 0 then
				return
			end

			local ScreenDistance = (Vector2.new(ScreenPosition.X, ScreenPosition.Y) - MousePosition).Magnitude
			if (MaxFOV <= 0 or ScreenDistance <= MaxFOV)
				and ScreenDistance < BestDistance
				and Targeting.isVisible(Target, HitPart)
			then
				BestDistance = ScreenDistance
				BestPart = HitPart
			end
		end
	)

	return BestPart
end

function Targeting.getWallBangTargetPartFromShot(StartPosition, Direction)
	if not Environment.NotorietyWallBangEnabled
		or typeof(StartPosition) ~= "Vector3"
		or typeof(Direction) ~= "Vector3"
		or Direction.Magnitude <= 0.001
	then
		return nil
	end

	local UnitDirection = Direction.Unit
	local BestPart
	local BestAngle = math.rad(5)
	local BestAlong = math.huge

	Targeting.forEach(
		Environment.NotorietyWallBangTargetPolice,
		Environment.NotorietyWallBangTargetCriminals,
		function(Target, Category)
			if not Targeting.isWallBangCategoryEnabled(Category) or not Targeting.isAlive(Target) then
				return
			end

			local HitPart = Targeting.getPart(Target)
			if not HitPart or not HitPart:IsA("BasePart") then
				return
			end

			local Offset = HitPart.Position - StartPosition
			local Along = Offset:Dot(UnitDirection)
			if Along <= 0 then
				return
			end

			local Perpendicular = (Offset - UnitDirection * Along).Magnitude
			local Angle = math.atan2(Perpendicular, Along)

			if Angle < BestAngle or (math.abs(Angle - BestAngle) <= 1e-5 and Along < BestAlong) then
				BestAngle = Angle
				BestAlong = Along
				BestPart = HitPart
			end
		end
	)

	return BestPart
end

local function restoreRuntimeSilentAimWrapper(State)
	local Record = WeaponState.RuntimeSilentAimBackups[State]

	if type(Record) ~= "table" then
		return
	end

	if type(Record.Original) == "function" and State.shoot == Record.Wrapper then
		State.shoot = Record.Original
	end

	WeaponState.RuntimeSilentAimBackups[State] = nil
end

local function restoreProjectileSilentAimWrapper()
	local Record = WeaponState.ProjectileSilentAim

	if type(Record) ~= "table" then
		return
	end

	if type(Record.Projectile) == "table"
		and type(Record.Original) == "function"
		and Record.Projectile.new == Record.Wrapper
	then
		Record.Projectile.new = Record.Original
	end

	WeaponState.ProjectileSilentAim = nil
end

local function restoreRuntimeSilentAimWrappers()
	local States = {}

	for State in WeaponState.RuntimeSilentAimBackups do
		States[#States + 1] = State
	end

	for _, State in States do
		restoreRuntimeSilentAimWrapper(State)
	end

	restoreProjectileSilentAimWrapper()
end

local function getProjectileTableFromShoot(Shoot)
	if type(Shoot) ~= "function" then
		return nil
	end

	local Direct = getDebugUpvalue(Shoot, 28)

	if type(Direct) == "table" and type(rawget(Direct, "new")) == "function" then
		return Direct
	end

	local PossibleOriginal = getDebugUpvalue(Shoot, 2)

	if type(PossibleOriginal) == "function" then
		local FromOriginal = getDebugUpvalue(PossibleOriginal, 28)

		if type(FromOriginal) == "table" and type(rawget(FromOriginal, "new")) == "function" then
			return FromOriginal
		end
	end

	return nil
end

local function patchRuntimeSilentAim(State)
	if type(State) ~= "table" then
		return false
	end

	if not Environment.NotorietyWeaponEnabled
		or (not Environment.NotorietySilentAimEnabled and not Environment.NotorietyWallBangEnabled)
	then
		restoreRuntimeSilentAimWrapper(State)
		restoreProjectileSilentAimWrapper()
		return false
	end

	restoreRuntimeSilentAimWrapper(State)

	local Shoot = rawget(State, "shoot")
	local ProjectileTable = getProjectileTableFromShoot(Shoot)

	if type(ProjectileTable) ~= "table" then
		return false
	end

	local Existing = WeaponState.ProjectileSilentAim

	if type(Existing) == "table"
		and Existing.Projectile == ProjectileTable
		and ProjectileTable.new == Existing.Wrapper
	then
		return true
	end

	if type(Existing) == "table" then
		restoreProjectileSilentAimWrapper()
	end

	local OriginalNew = rawget(ProjectileTable, "new")

	if type(OriginalNew) ~= "function" then
		return false
	end

	local Wrapper
	Wrapper = function(Data, ...)
		if not Environment.NotorietyUnloaded
			and Environment.NotorietyWeaponEnabled
			and type(Data) == "table"
			and Data.Player == LocalPlayer
			and not Data.IsNPC
			and typeof(Data.StartPosition) == "Vector3"
		then
			local RedirectedTarget

			if Environment.NotorietySilentAimEnabled then
				local TargetPart = Targeting.getSilentAimTargetPart()

				if TargetPart and TargetPart.Parent then
					local Delta = TargetPart.Position - Data.StartPosition

					if Delta.Magnitude > 0.001 then
						Data.TargetPosition = TargetPart.Position
						Data.Direction = Delta.Unit
						RedirectedTarget = TargetPart
						Environment.NotorietySilentAimLastTarget = TargetPart:GetFullName()
						Environment.NotorietySilentAimLastRedirect = TargetPart.Position
					end
				end
			end

			if Environment.NotorietyWallBangEnabled and typeof(Data.Direction) == "Vector3" then
				local WallBangTarget = RedirectedTarget

				if WallBangTarget then
					local TargetModel = WallBangTarget:FindFirstAncestorOfClass("Model")
					if not TargetModel or not Targeting.isWallBangAllowed(TargetModel) then
						WallBangTarget = nil
					end
				end

				if not WallBangTarget then
					WallBangTarget = Targeting.getWallBangTargetPartFromShot(Data.StartPosition, Data.Direction)
				end

				if WallBangTarget then
					Data.Piercing = math.max(tonumber(Data.Piercing) or 0, 1000)

					if type(Data.GunData) == "table" then
						local GunData = table.clone(Data.GunData)
						GunData.EnemyPiercing = math.max(tonumber(GunData.EnemyPiercing) or 0, 1000)
						Data.GunData = GunData
					end

					Environment.NotorietyWallBangLastTarget = WallBangTarget:GetFullName()
				end
			end
		end

		return OriginalNew(Data, ...)
	end

	WeaponState.ProjectileSilentAim = {
		Projectile = ProjectileTable,
		Original = OriginalNew,
		Wrapper = Wrapper,
	}

	ProjectileTable.new = Wrapper
	return true
end

local function patchRuntimeWeaponSpread(State, Spread)
	local DebugLibrary = debug
	local Shoot = type(State) == "table" and rawget(State, "shoot") or nil
	local AimRecord = type(State) == "table" and WeaponState.RuntimeSilentAimBackups[State] or nil

	if type(AimRecord) == "table" and Shoot == AimRecord.Wrapper then
		Shoot = AimRecord.Original
	end

	if type(Shoot) ~= "function"
		or type(DebugLibrary) ~= "table"
		or type(DebugLibrary.setupvalue) ~= "function"
	then
		return false
	end

	local Index = 11
	local Current = getDebugUpvalue(Shoot, Index)

	if type(Current) ~= "number" or Current < 0 or Current > 10000 then
		return false
	end

	local Record = WeaponState.RuntimeSpreadBackups[State]

	if type(Record) ~= "table" or Record.Function ~= Shoot then
		Record = {
			Function = Shoot,
			Index = Index,
			Value = Current,
		}

		WeaponState.RuntimeSpreadBackups[State] = Record
	end

	local Success = pcall(DebugLibrary.setupvalue, Shoot, Index, Spread)

	return Success
end

local function patchRuntimeWeaponState(State)
	if not Environment.NotorietyWeaponEnabled or type(State) ~= "table" then
		return false
	end

	local GetAmmo = rawget(State, "getAmmo")
	local Data = rawget(State, "data")

	if type(GetAmmo) ~= "function" or type(Data) ~= "table" then
		return false
	end

	local Patched = applyWeaponData(Data)

	if rawget(Data, "WeaponType") == "Gun" then
		if Environment.NotorietyAccuracyModEnabled then
			local DesiredAccuracy = math.clamp(tonumber(Environment.NotorietyAccuracy) or 100, 0, 100)
			local DesiredSpread = 10000 - DesiredAccuracy * 100

			if type(rawget(State, "Accuracy")) == "number" then
				if WeaponState.RuntimeAccuracyBackups[State] == nil then
					WeaponState.RuntimeAccuracyBackups[State] = State.Accuracy
				end

				State.Accuracy = DesiredSpread
			end

			patchRuntimeWeaponSpread(State, DesiredSpread)
		end

		patchRuntimeSilentAim(State)

		if Environment.NotorietyNoRecoilEnabled then
			local RecoilBackup = WeaponState.RuntimeRecoilBackups[State]

			if not RecoilBackup then
				RecoilBackup = {}

				for _, Key in { "ShakeMagnitude", "ShakeRoughness", "pushdist" } do
					local Value = rawget(State, Key)
					RecoilBackup[Key] = { Exists = Value ~= nil, Value = Value }
				end

				WeaponState.RuntimeRecoilBackups[State] = RecoilBackup
			end

			State.ShakeMagnitude = 0
			State.ShakeRoughness = 0
			State.pushdist = 0
		end

		WeaponState.RuntimeWeapons[State] = true
	else
		WeaponState.RuntimeWeapons[State] = nil
	end

	if not isInfiniteGunState(State, Data) or not Environment.NotorietyInfiniteAmmoEnabled then
		restoreAmmoWrapper(State)
		return Patched
	end

	local Record = Environment.NotorietyGetAmmoWrappers[State]

	if not Record or State.getAmmo ~= Record.Wrapper then
		local Original = State.getAmmo
		local Wrapper

		Wrapper = function(...)
			local Result = Original(...)

			return patchAmmoResult(Result, State)
		end

		Record = {
			Original = Original,
			Wrapper = Wrapper,
		}

		Environment.NotorietyGetAmmoWrappers[State] = Record
		State.getAmmo = Wrapper
	end

	local Success, Result = pcall(State.getAmmo, State)

	if Success then
		patchAmmoResult(Result, State)
	end

	return true
end

local function refreshRuntimeFireTiming(State)
	if not Environment.NotorietyWeaponEnabled
		or not Environment.NotorietyRapidFireEnabled
		or type(State) ~= "table"
	then
		return
	end

	local Data = rawget(State, "data")

	if type(Data) ~= "table" or rawget(Data, "WeaponType") ~= "Gun" then
		return
	end

	local FireDelay = math.max(tonumber(rawget(Data, "FireDelay")) or tonumber(Environment.NotorietyFireDelay) or 0.01, 0)
	local LastShot = rawget(State, "LastShot")

	if type(LastShot) ~= "number" or os.clock() - LastShot < FireDelay then
		return
	end

	if rawget(State, "postshooting") == true then
		State.postshooting = false
	end

	if rawget(State, "postshooting2") == true then
		State.postshooting2 = false
	end

	if rawget(State, "waspostshooting") == true then
		State.waspostshooting = false
	end

	if rawget(State, "waspostshooting2") == true then
		State.waspostshooting2 = false
	end
end

local function refreshRuntimeAmmo()
	if not Environment.NotorietyWeaponEnabled then
		return
	end

	for State in WeaponState.RuntimeWeapons do
		patchRuntimeWeaponState(State)
		refreshRuntimeFireTiming(State)
	end
end

local function zeroVectorPattern(Pattern, Backup)
	if type(Pattern) ~= "table" then
		return
	end

	local PatternBackup = Backup.Patterns[Pattern]

	if not PatternBackup then
		PatternBackup = {}
		Backup.Patterns[Pattern] = PatternBackup

		for Index, Value in Pattern do
			PatternBackup[Index] = Value
		end
	end

	for Index, Value in Pattern do
		if typeof(Value) == "Vector2" then
			Pattern[Index] = Vector2.zero
		end
	end
end

local function restoreWeaponData(Data, Backup)
	for Key, Field in Backup.Fields do
		if Field.Exists then
			Data[Key] = Field.Value
		else
			Data[Key] = nil
		end
	end

	for Pattern, Values in Backup.Patterns do
		for Index, Value in Values do
			Pattern[Index] = Value
		end
	end

	for Step, Value in Backup.Steps do
		if Value.Exists then
			Step[7] = Value.Value
		else
			Step[7] = nil
		end
	end

	for Container, Fields in Backup.NestedFields do
		for Key, Field in Fields do
			if Field.Exists then
				Container[Key] = Field.Value
			else
				Container[Key] = nil
			end
		end
	end
end

local function restoreAllWeaponData()
	for Data, Backup in WeaponState.Backups do
		pcall(restoreWeaponData, Data, Backup)
	end
end

local function restoreRuntimeWeaponAccuracy()
	for State, Accuracy in WeaponState.RuntimeAccuracyBackups do
		if type(State) == "table" and type(Accuracy) == "number" then
			State.Accuracy = Accuracy
		end
	end

	local DebugLibrary = debug

	if type(DebugLibrary) == "table" and type(DebugLibrary.setupvalue) == "function" then
		for _, Record in WeaponState.RuntimeSpreadBackups do
			if type(Record) == "table"
				and type(Record.Function) == "function"
				and type(Record.Index) == "number"
				and type(Record.Value) == "number"
			then
				pcall(DebugLibrary.setupvalue, Record.Function, Record.Index, Record.Value)
			end
		end
	end

	table.clear(WeaponState.RuntimeAccuracyBackups)
	table.clear(WeaponState.RuntimeSpreadBackups)
end

local function restoreRuntimeWeaponRecoil()
	for State, Backup in WeaponState.RuntimeRecoilBackups do
		if type(State) == "table" and type(Backup) == "table" then
			for Key, Field in Backup do
				if type(Field) == "table" and Field.Exists then
					State[Key] = Field.Value
				else
					State[Key] = nil
				end
			end
		end
	end

	table.clear(WeaponState.RuntimeRecoilBackups)
end

local function restoreAllAmmoWrappers()
	if type(Environment.NotorietyGetAmmoWrappers) ~= "table" then
		return
	end

	local States = {}
	for State in Environment.NotorietyGetAmmoWrappers do States[#States + 1] = State end
	for _, State in States do restoreAmmoWrapper(State) end
	table.clear(WeaponState.RuntimeWeapons)
end

applyWeaponData = function(Data)
	if not Environment.NotorietyWeaponEnabled or type(Data) ~= "table" then
		return false
	end

	local WeaponType = rawget(Data, "WeaponType")

	if WeaponType == "Gun" then
		local StandardGun = isStandardGunData(Data)
		local Backup = getWeaponBackup(Data)
		for _, Key in {
			"FireDelay",
			"BoltDuration",
			"BoltLock",
			"Piercing",
			"EnemyPiercing",
			"FireMode",
			"FireModeList",
			"MagazineSize",
			"AmmoMax",
			"AmmoSeparate",
			"AmmoSwitch",
			"ManualCasingEjection",
			"RecoilCameraDirection",
			"MaxCameraRecoil",
			"Accuracy",
			"ShakeMagnitude",
			"ShakeRoughness",
			"PushBack",
		} do
			captureField(Data, Backup, Key)
		end

		if Environment.NotorietyRapidFireEnabled then
			Data.FireDelay = tonumber(Environment.NotorietyFireDelay) or 0.01
			Data.BoltDuration = tonumber(Environment.NotorietyBoltDuration) or 0.001
			Data.BoltLock = false
			patchGunSequences(Data, Backup)

			if type(Data.ManualCasingEjection) == "boolean" then
				Data.ManualCasingEjection = false
			end
		end

		if Environment.NotorietyAccuracyModEnabled and type(Data.Accuracy) == "number" then
			Data.Accuracy = math.clamp(tonumber(Environment.NotorietyAccuracy) or 100, 0, 100)
		end

		if Environment.NotorietyFullAutoEnabled and StandardGun then
			Data.FireMode = "Auto"

			if type(Data.FireModeList) ~= "table"
				or Data.FireModeList[1] ~= "Auto"
				or Data.FireModeList[2] ~= nil
			then
				Data.FireModeList = { "Auto" }
			end
		end

		if Environment.NotorietyInfiniteAmmoEnabled then
			local AmmoClass = Data.AmmoClass
			local UsesInfiniteGunAmmo = AmmoClass == "Primary" or AmmoClass == "Secondary"

			if UsesInfiniteGunAmmo then
				Data.MagazineSize = MAX_VALUE
				Data.AmmoMax = MAX_VALUE
			end
		end

		if Environment.NotorietyNoRecoilEnabled then
			zeroVectorPattern(Data.RecoilDirectionPattern, Backup)
			zeroVectorPattern(Data.RecoilCameraDirectionPattern, Backup)

			if typeof(Data.RecoilCameraDirection) == "Vector2" then
				Data.RecoilCameraDirection = Vector2.zero
			end

			if type(Data.MaxCameraRecoil) == "number" then
				Data.MaxCameraRecoil = 0
			end

			if type(Data.ShakeMagnitude) == "number" then
				Data.ShakeMagnitude = 0
			end

			if type(Data.ShakeRoughness) == "number" then
				Data.ShakeRoughness = 0
			end

			if type(Data.PushBack) == "number" then
				Data.PushBack = 0
			end
		end

		return true
	end

	if WeaponType == "Melee" then
		local Backup = getWeaponBackup(Data)

		for _, Key in {
			"FireMode",
			"MaxCharge",
			"AttackSpeed",
		} do
			captureField(Data, Backup, Key)
		end

		Data.FireMode = "Auto"
		Data.MaxCharge = 0.01
		Data.AttackSpeed = 100

		shortenSequence(Data.ChargeAnim, Backup)
		shortenSequence(Data.StrikeAnim, Backup)
		shortenSequence(Data.StrikeAnim2, Backup)

		return true
	end

	return false
end

local function getFunctionUpvalues(Function)
	local DebugLibrary = debug

	if type(DebugLibrary) ~= "table" then
		return nil
	end

	if type(DebugLibrary.getupvalue) == "function" then
		local Upvalues = {}

		for Index = 1, 200 do
			local Success, First, Second = pcall(DebugLibrary.getupvalue, Function, Index)

			if not Success or First == nil then
				break
			end

			local Value

			if type(First) == "string" and Second ~= nil then
				Value = Second
			elseif Second ~= nil then
				Value = Second
			else
				Value = First
			end

			Upvalues[Index] = Value
		end

		if next(Upvalues) ~= nil then
			return Upvalues
		end
	end

	if type(DebugLibrary.getupvalues) == "function" then
		local Success, Upvalues = pcall(DebugLibrary.getupvalues, Function)

		if Success and type(Upvalues) == "table" then
			return Upvalues
		end
	end

	return nil
end

local function getLocalGunsEnvironment()
	local PlayerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
	local SPSPackage = PlayerScripts and PlayerScripts:FindFirstChild("SPS_Package")
	local LocalGuns = SPSPackage and SPSPackage:FindFirstChild("LocalGuns")

	if not LocalGuns then
		return nil
	end

	local GetEnvironment = getsenv

	if type(GetEnvironment) ~= "function" and type(getrenv) == "function" then
		local Success, RuntimeEnvironment = pcall(getrenv)

		if Success and type(RuntimeEnvironment) == "table" then
			GetEnvironment = rawget(RuntimeEnvironment, "getsenv")
		end
	end

	if type(GetEnvironment) ~= "function" then
		return nil
	end

	local Success, ScriptEnvironment = pcall(GetEnvironment, LocalGuns)

	if Success and type(ScriptEnvironment) == "table" then
		return ScriptEnvironment
	end

	return nil
end

local function patchLoadedWeaponTables()
	local ScriptEnvironment = getLocalGunsEnvironment()

	if not ScriptEnvironment then
		return 0
	end

	local Seen = {}
	local Patched = 0
	local Nodes = 0
	local NodeLimit = 60000

	local function Scan(Value, Depth)
		if Nodes >= NodeLimit or Depth > 8 or type(Value) ~= "table" then
			return
		end

		if Seen[Value] then
			return
		end

		Seen[Value] = true
		Nodes += 1

		if applyWeaponData(Value) then
			Patched += 1
		end

		patchRuntimeWeaponState(Value)

		for Key, Item in Value do
			if type(Key) == "table" then
				Scan(Key, Depth + 1)
			end

			if type(Item) == "table" then
				Scan(Item, Depth + 1)
			end

			if Nodes >= NodeLimit then
				break
			end
		end
	end

	for _, Value in ScriptEnvironment do
		if type(Value) == "table" then
			Scan(Value, 0)
		elseif type(Value) == "function" then
			local Upvalues = getFunctionUpvalues(Value)

			if type(Upvalues) == "table" then
				for _, Item in Upvalues do
					if type(Item) == "table" then
						Scan(Item, 0)
					end
				end
			end
		end

		if Nodes >= NodeLimit then
			break
		end
	end

	return Patched
end

local function queueLoadedWeaponFallback()
	if not Environment.NotorietyWeaponEnabled or WeaponState.FallbackQueued then
		return
	end

	WeaponState.FallbackQueued = true

	task.delay(0.25, function()
		WeaponState.FallbackQueued = false

		if not Environment.NotorietyWeaponEnabled then
			return
		end

		if patchLoadedWeaponTables() > 0 then
			WeaponState.FallbackAttempts = 0
		elseif WeaponState.RequireUnavailable and WeaponState.FallbackAttempts < 20 then
			WeaponState.FallbackAttempts += 1
			task.delay(0.75, queueLoadedWeaponFallback)
		else
			WeaponState.FallbackAttempts = 0
		end
	end)
end

local function getModuleData(Module)
	local Cached = WeaponState.ModuleCache[Module]

	if type(Cached) == "table" then
		return Cached
	end

	if WeaponState.RequireUnavailable then
		return nil
	end

	for _, RequireFunction in WeaponState.RequireFunctions do
		local Success, Result = pcall(RequireFunction, Module)

		if Success and type(Result) == "table" then
			WeaponState.RequireFailures = 0
			WeaponState.ModuleCache[Module] = Result
			return Result
		end
	end

	WeaponState.RequireFailures += 1

	if #WeaponState.RequireFunctions == 0 or WeaponState.RequireFailures >= 3 then
		WeaponState.RequireUnavailable = true
	end

	return nil
end

local function applyWeaponModule(Object)
	if not Environment.NotorietyWeaponEnabled
		or not Object:IsA("ModuleScript")
		or Object.Name ~= "Data"
	then
		return
	end

	local Data = getModuleData(Object)

	if Data then
		applyWeaponData(Data)
	else
		queueLoadedWeaponFallback()
	end
end

local function trackWeaponContainer(Container)
	if Environment.NotorietyUnloaded or not Container then
		return
	end

	for _, Object in Container:GetDescendants() do
		applyWeaponModule(Object)
	end

	table.insert(
		Environment.NotorietyWeaponConnections,
		Container.DescendantAdded:Connect(function(Object)
			if Environment.NotorietyUnloaded then
				return
			end

			if Object:IsA("ModuleScript") and Object.Name == "Data" then
				task.defer(function()
					applyWeaponModule(Object)
					patchLoadedWeaponTables()
				end)
			end
		end)
	)
end

local function getEquippedGun()
	local Character = LocalPlayer.Character

	if not Character then
		return nil
	end

	for _, Object in Character:GetChildren() do
		if Object:IsA("Tool") then
			return Object
		end
	end

	return nil
end

local function Apply()
	local Character = LocalPlayer.Character

	if not Character then
		return
	end

	if Environment.NotorietyInfiniteEquipmentEnabled then
		for _, Name in { "EquipmentLeft", "SecondEquipmentLeft" } do
			local Value = Character:FindFirstChild(Name)
			if Value and Value:IsA("ValueBase") and type(Value.Value) == "number" and Value.Value ~= MAX_VALUE then
				Value.Value = MAX_VALUE
			end
		end
	end

	if not Environment.MaxEverythingEnabled then
		return
	end

	for _, Object in Character:GetDescendants() do
		if Object:IsA("ValueBase") and not Object:FindFirstAncestorWhichIsA("Tool") then
			local Value = MaxedValues[Object.Name]

			if Value ~= nil and typeof(Object.Value) == "number" and Object.Value ~= Value then
				Object.Value = Value
			end
		end
	end

	replenishFiniteSupplies(Character)
end

local FriendlyFireState = {
	Instance = nil,
	Owned = false,
	Captured = false,
	OriginalValue = nil,
}

local function getActiveMutators()
	return RS_Package:FindFirstChild("ActiveMutators")
end

local function restoreFriendlyFire()
	local Instance = FriendlyFireState.Instance

	if typeof(Instance) == "Instance" and Instance.Parent then
		if FriendlyFireState.Owned then
			pcall(function()
				Instance:Destroy()
			end)
		elseif FriendlyFireState.Captured and Instance:IsA("NumberValue") then
			pcall(function()
				Instance.Value = FriendlyFireState.OriginalValue
			end)
		end
	end

	FriendlyFireState.Instance = nil
	FriendlyFireState.Owned = false
	FriendlyFireState.Captured = false
	FriendlyFireState.OriginalValue = nil
end

local function applyFriendlyFire()
	local ActiveMutators = getActiveMutators()

	if not ActiveMutators then
		return false
	end

	if not Environment.NotorietyFriendlyFireEnabled then
		restoreFriendlyFire()
		return false
	end

	local Existing = ActiveMutators:FindFirstChild("FriendlyFire")

	if Existing then
		if FriendlyFireState.Instance ~= Existing then
			restoreFriendlyFire()
			FriendlyFireState.Instance = Existing
			FriendlyFireState.Owned = Existing:GetAttribute("NotorietyFriendlyFireOwned") == true

			if not FriendlyFireState.Owned and Existing:IsA("NumberValue") then
				FriendlyFireState.Captured = true
				FriendlyFireState.OriginalValue = Existing.Value
			end
		end

		if Existing:IsA("NumberValue") then
			Existing.Value = 100
		end

		return true
	end

	restoreFriendlyFire()

	local FriendlyFire = ServiceResolver.ns("NumberValue")
	if not FriendlyFire then
		FriendlyFire = Instance.new("NumberValue")
	end

	FriendlyFire.Name = "FriendlyFire"
	FriendlyFire.Value = 100
	FriendlyFire:SetAttribute("NotorietyFriendlyFireOwned", true)
	FriendlyFire.Parent = ActiveMutators

	FriendlyFireState.Instance = FriendlyFire
	FriendlyFireState.Owned = true

	return true
end

local function setFriendlyFireEnabled(Enabled)
	Environment.NotorietyFriendlyFireEnabled = Enabled == true

	if Environment.NotorietyFriendlyFireEnabled then
		applyFriendlyFire()
		return
	end

	local ActiveMutators = getActiveMutators()
	local Existing = ActiveMutators and ActiveMutators:FindFirstChild("FriendlyFire")

	if not Existing then
		restoreFriendlyFire()
		return
	end

	if Existing:GetAttribute("NotorietyFriendlyFireOwned") == true then
		if FriendlyFireState.Instance ~= Existing then
			restoreFriendlyFire()
			FriendlyFireState.Instance = Existing
			FriendlyFireState.Owned = true
		end

		restoreFriendlyFire()
		return
	end

	if FriendlyFireState.Instance ~= Existing then
		restoreFriendlyFire()
		FriendlyFireState.Instance = Existing
		FriendlyFireState.Owned = false

		if Existing:IsA("NumberValue") then
			FriendlyFireState.Captured = true
			FriendlyFireState.OriginalValue = Existing.Value
		end
	end

	if Existing:IsA("NumberValue") then
		Existing.Value = 0
	end
end

local function isTeammatePlayer(Player)
	if not Player or Player == LocalPlayer then
		return false
	end

	local Criminals = Workspace:FindFirstChild("Criminals")
	local Character = Player.Character
	return Criminals ~= nil and Character ~= nil and Character:IsDescendantOf(Criminals)
end

local function getTeammatePlayers()
	local Teammates = {}

	for _, Player in Players:GetPlayers() do
		if isTeammatePlayer(Player) then
			table.insert(Teammates, Player)
		end
	end

	table.sort(Teammates, function(Left, Right)
		return string.lower(Left.Name) < string.lower(Right.Name)
	end)

	return Teammates
end

local function getTeammatePickerValues()
	local Names = {}

	for _, Player in Players:GetPlayers() do
		if Player ~= LocalPlayer then
			table.insert(Names, Player.Name)
		end
	end

	table.sort(Names, function(Left, Right)
		return string.lower(Left) < string.lower(Right)
	end)

	local Values = { "All" }
	for _, Name in Names do
		table.insert(Values, Name)
	end

	return Values
end

local function runKillTeammates(TargetName)
	if Environment.KillTeammatesRunning then
		return
	end

	Environment.KillTeammatesRunning = true

	local Killed = 0
	local Attempted = 0
	local Success, Error = xpcall(function()
		local Gun = getEquippedGun()

		if not Gun then
			return
		end

		local Targets = {}
		TargetName = tostring(TargetName or Environment.NotorietyTeammateTarget or "All")

		if TargetName == "All" then
			Targets = getTeammatePlayers()
		else
			local Player = Players:FindFirstChild(TargetName)
			if isTeammatePlayer(Player) then
				table.insert(Targets, Player)
			end
		end

		for _, Player in Targets do
			if Environment.NotorietyUnloaded then
				break
			end

			if not Gun.Parent then
				Gun = getEquippedGun()
				if not Gun then
					break
				end
			end

			local Character = Player.Character
			local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid", true)
			local Health = Character and Character:FindFirstChild("Health")
			local HitPart = Character and (
				Character:FindFirstChild("Head", true)
				or Character:FindFirstChild("UpperTorso", true)
				or Character:FindFirstChild("Torso", true)
				or Character:FindFirstChild("HumanoidRootPart", true)
			)

			local IsAlive = Humanoid ~= nil and HitPart ~= nil
			if Health and Health:IsA("ValueBase") and type(Health.Value) == "number" then
				IsAlive = IsAlive and Health.Value > 0
			end

			if IsAlive then
				Attempted += 1
				Event:FireServer(
					"Damage",
					Gun,
					Humanoid,
					99999999999999,
					HitPart,
					Gun.Name,
					Vector3.new(4.3659992218018, -2.7754878997803, -0.7671462893486),
					{}
				)

				task.wait(0.3)

				if not Health or not Health.Parent or Health.Value <= 0 then
					Killed += 1
				end
			end
		end
	end, debug.traceback)

	Environment.KillTeammatesRunning = false

	if not Success then
		warn(Error)
	elseif not Environment.NotorietyUnloaded then
		pcall(function()
			NotorietyUI.Library:Notify({
				Title = "Kill Teammates",
				Content = Attempted == 0
					and "No valid teammate target was available."
					or string.format("Targeted %d teammate(s); %d reached zero health.", Attempted, Killed),
				Icon = Killed > 0 and "check" or "triangle-alert",
				Duration = 3,
			})
		end)
	end
end

local function runKill()
	if Environment.KillPoliceRunning then
		return
	end

	Environment.KillPoliceRunning = true

	local Killed = 0
	local Success, Error = xpcall(function()
		local PoliceFolder = Workspace:FindFirstChild("Police")
		local Gun = getEquippedGun()

		if not PoliceFolder or not Gun then
			return
		end

		for _, Target in PoliceFolder:GetChildren() do
			if Environment.NotorietyUnloaded then
				break
			end

			if not Gun.Parent then
				Gun = getEquippedGun()

				if not Gun then
					break
				end
			end

			local Humanoid = Target:FindFirstChildWhichIsA("Humanoid", true)
			local HitPart = Target:FindFirstChild("Head", true)
				or Target:FindFirstChild("UpperTorso", true)
				or Target:FindFirstChild("Torso", true)
				or Target:FindFirstChild("HumanoidRootPart", true)

			if Humanoid and HitPart and Humanoid.Health > 0 then
				Event:FireServer(
					"Damage",
					Gun,
					Humanoid,
					99999999999999,
					HitPart,
					Gun.Name,
					Vector3.new(4.3659992218018, -2.7754878997803, -0.7671462893486),
					{}
				)

				Killed += 1
				task.wait(0.3)
			end
		end
	end, debug.traceback)

	Environment.KillPoliceRunning = false

	if not Success then
		warn(Error)
	elseif not Environment.NotorietyUnloaded then
		pcall(function()
			NotorietyUI.Library:Notify({
				Title = "Kill Police",
				Content = string.format("Finished. Killed %d police.", Killed),
				Icon = "check",
				Duration = 3,
			})
		end)
	end
end

local Weapons = Assets:FindFirstChild("Weapons")
local Backpack = LocalPlayer:WaitForChild("Backpack", math.huge)

local function applyAllWeaponModifications()
	if not Environment.NotorietyWeaponEnabled then
		return
	end

	for _, Container in {
		Weapons,
		Backpack,
		LocalPlayer.Character,
	} do
		if Container then
			for _, Object in Container:GetDescendants() do
				applyWeaponModule(Object)
			end
		end
	end

	patchLoadedWeaponTables()
end

local function refreshWeaponModifications()
	restoreRuntimeSilentAimWrappers()
	restoreAllWeaponData()
	restoreRuntimeWeaponAccuracy()
	restoreRuntimeWeaponRecoil()
	restoreAllAmmoWrappers()

	if Environment.NotorietyWeaponEnabled then
		applyAllWeaponModifications()
	end
end

local function setWeaponModificationsEnabled(Enabled)
	Environment.NotorietyWeaponEnabled = Enabled == true
	refreshWeaponModifications()
end

local ItemESPColors = {
	LOOT = Color3.fromRGB(255, 215, 50),
	ITEM = Color3.fromRGB(60, 210, 255),
	KEY = Color3.fromRGB(210, 80, 255),
	CONTAINER = Color3.fromRGB(255, 125, 45),
	CAMERA = Color3.fromRGB(255, 50, 50),
	SECURITY = Color3.fromRGB(255, 65, 145),
	ACCESS = Color3.fromRGB(140, 105, 255),
	ESCAPE = Color3.fromRGB(70, 255, 130),
}

local ItemESPState = {
	Definitions = nil,
	Folder = nil,
	Connections = {},
	Tracked = setmetatable({}, {
		__mode = "k",
	}),
	Refresh = 0,
	Rescan = 0,
	ScanRefresh = 0,
	ScanCursor = 1,
	ScanList = {},
}

local function isItemESPCategoryEnabled(Category)
	local Categories = Environment.NotorietyItemESPCategories
	return type(Categories) ~= "table" or Categories[Category] ~= false
end

local function containsItemESPWord(Text, Words)
	Text = string.lower(Text)

	for _, Word in Words do
		if string.find(Text, Word, 1, true) then
			return true
		end
	end

	return false
end

local function loadInteractionDefinitions()
	if type(ItemESPState.Definitions) == "table" then
		return ItemESPState.Definitions
	end

	local ReplicatedScripts = RS_Package:FindFirstChild("ReplicatedScripts")
	local InteractListModule = ReplicatedScripts and ReplicatedScripts:FindFirstChild("InteractList")

	if not InteractListModule or not InteractListModule:IsA("ModuleScript") then
		return nil
	end

	local RequireSuccess, Factory = pcall(require, InteractListModule)

	if not RequireSuccess then
		return nil
	end

	local Definitions = Factory

	if type(Factory) == "function" then
		local FactorySuccess, FactoryResult = pcall(Factory)

		if not FactorySuccess then
			return nil
		end

		Definitions = FactoryResult
	end

	if type(Definitions) ~= "table" then
		return nil
	end

	ItemESPState.Definitions = Definitions

	return Definitions
end

local function resolveItemESPInteraction(Prompt)
	local Definitions = loadInteractionDefinitions()

	if not Definitions then
		return nil
	end

	local Object = Prompt.Parent

	while Object and Object ~= Workspace do
		local Key = Object:GetAttribute("InteractType") or Object.Name
		local Data = Definitions[Key]

		if type(Data) == "table" then
			return Object, Key, Data
		end

		local Normalized = string.gsub(Key, "%d+$", "")
		Data = Definitions[Normalized]

		if type(Data) == "table" then
			return Object, Normalized, Data
		end

		Object = Object.Parent
	end

	return nil
end

local function classifyItemESPInteraction(Prompt, Key, Data)
	local PromptAction = string.upper(Prompt.ActionText or "")
	local KeyLower = string.lower(Key)
	local RegistryAction = string.lower(Data.actiontext or "")
	local Searchable = KeyLower .. " " .. RegistryAction

	if PromptAction == "SECURE"
		or containsItemESPWord(KeyLower, {
			"safespot",
			"escapecrate",
		})
	then
		return "ESCAPE"
	end

	if containsItemESPWord(Searchable, {
		"electrical box",
		"power box",
		"camera box",
		"camera feed",
		"rushhourelectricalbox",
	}) then
		return "SECURITY"
	end

	if containsItemESPWord(KeyLower, {
		"cardreader",
		"card reader",
		"wirecutterfence",
		"acunitcover",
	}) or PromptAction == "INSERT" or PromptAction == "UNLOCK" then
		return "ACCESS"
	end

	if containsItemESPWord(KeyLower, {
		"keycard",
		"key card",
		"accesspass",
		"access pass",
	}) then
		return "KEY"
	end

	if containsItemESPWord(KeyLower, {
		"crowbar",
		"wirecutters",
		"thermal drill",
		"drill bag",
	}) then
		return "ITEM"
	end

	if PromptAction == "DISABLE" or containsItemESPWord(KeyLower, {
		"camera",
	}) then
		return "CAMERA"
	end

	if PromptAction == "START DRILL"
		or containsItemESPWord(KeyLower, {
			"rushcrate",
			"randomcrate",
			"folderopen",
			"mini safe",
			"depositbox",
			"deposit box",
			"lockbox",
		})
	then
		return "CONTAINER"
	end

	local PickupActions = {
		TAKE = true,
		STEAL = true,
		GRAB = true,
		BAG = true,
		REMOVE = true,
	}

	if (Data.value or 0) > 0 and PickupActions[PromptAction] then
		return "LOOT"
	end

	if containsItemESPWord(RegistryAction, {
		"take cash",
		"take gold",
		"take jewelry",
		"bag ",
		"steal ",
		"grab gold",
		"grab bag",
		"grab bloxy cola",
		"open cash register",
	}) then
		return "LOOT"
	end

	if PromptAction == "STEAL"
		or PromptAction == "GRAB"
		or PromptAction == "BAG"
		or PromptAction == "REMOVE"
	then
		return "LOOT"
	end

	return nil
end

local function resolveItemESPBox(Object)
	if Object:IsA("BasePart") then
		return Object, Object.Size, CFrame.new()
	end

	if Object:IsA("Model") then
		local Adornee = Object.PrimaryPart or Object:FindFirstChildWhichIsA("BasePart", true)

		if not Adornee then
			return nil
		end

		local BoundsSuccess, BoundsCFrame, BoundsSize = pcall(Object.GetBoundingBox, Object)

		if BoundsSuccess then
			return Adornee, BoundsSize, Adornee.CFrame:ToObjectSpace(BoundsCFrame)
		end

		return Adornee, Adornee.Size, CFrame.new()
	end

	local Adornee = Object:FindFirstChildWhichIsA("BasePart", true)

	if Adornee then
		return Adornee, Adornee.Size, CFrame.new()
	end

	return nil
end

local function removeItemESPObject(Object)
	local Entry = ItemESPState.Tracked[Object]

	if not Entry then
		return
	end

	if Entry.Connection then
		pcall(function()
			Entry.Connection:Disconnect()
		end)
	end

	if Entry.Box then
		pcall(function()
			Entry.Box:Destroy()
		end)
	end

	if Entry.Label then
		pcall(function()
			Entry.Label:Destroy()
		end)
	end

	ItemESPState.Tracked[Object] = nil
end

local function resolveESPMaxDistance(Value, DefaultValue)
	local Distance = tonumber(Value)

	if Distance == nil or Distance ~= Distance or Distance == math.huge or Distance == -math.huge then
		Distance = DefaultValue or 2500
	end

	Distance = math.clamp(Distance, 0, 10000)
	return Distance <= 0 and math.huge or Distance
end

local function addItemESPObject(Category, Object)
	if not Category or not Object or not isItemESPCategoryEnabled(Category) then
		return
	end

	local ExistingEntry = ItemESPState.Tracked[Object]

	if ExistingEntry then
		return
	end

	local Folder = ItemESPState.Folder
	local Color = ItemESPColors[Category]

	if not Folder or not Folder.Parent or not Color then
		return
	end

	local Adornee, Size, BoxCFrame = resolveItemESPBox(Object)

	if not Adornee then
		return
	end

	local Box = ServiceResolver.ns("BoxHandleAdornment")

	if not Box then
		return
	end

	Box.Name = Category .. "_Box"
	Box.Adornee = Adornee
	Box.Size = Size
	Box.CFrame = BoxCFrame
	Box.Color3 = Color
	Box.Transparency = math.clamp((tonumber(Environment.NotorietyItemESPTransparency) or 55) / 100, 0, 1)
	Box.AlwaysOnTop = true
	Box.ZIndex = 10
	Box.Parent = Folder

	local Label

	if Environment.NotorietyItemESPLabels then
		Label = ServiceResolver.ns("BillboardGui")

		if Label then
			Label.Name = Category .. "_Label"
			Label.Adornee = Adornee
			Label.AlwaysOnTop = true
			Label.Size = UDim2.fromOffset(220, 30)
			Label.StudsOffsetWorldSpace = Vector3.new(0, math.max(Size.Y * 0.5 + 1, 2), 0)
			Label.MaxDistance = resolveESPMaxDistance(Environment.NotorietyItemESPMaxDistance, 2500)
			Label.Parent = Folder

			local Text = ServiceResolver.ns("TextLabel")

			if Text then
				Text.BackgroundTransparency = 1
				Text.Size = UDim2.fromScale(1, 1)
				Text.Text = string.format("%s • %s", Category, Object.Name)
				Text.TextColor3 = Color
				Text.TextStrokeTransparency = 0.2
				Text.TextScaled = false
				Text.TextSize = 14
				Text.Font = Enum.Font.GothamSemibold
				Text.Parent = Label
			end
		end
	end

	local AncestryConnection

	AncestryConnection = Object.AncestryChanged:Connect(function(_, Parent)
		if not Parent then
			removeItemESPObject(Object)
		end
	end)

	ItemESPState.Tracked[Object] = {
		Category = Category,
		Adornee = Adornee,
		Box = Box,
		Label = Label,
		Connection = AncestryConnection,
	}
end

local function updateItemESPVisibility()
	local Character = LocalPlayer.Character
	local Root = Character and Character:FindFirstChild("HumanoidRootPart")
	local MaxDistance = resolveESPMaxDistance(Environment.NotorietyItemESPMaxDistance, 2500)
	local Transparency = math.clamp((tonumber(Environment.NotorietyItemESPTransparency) or 55) / 100, 0, 1)

	for Object, Entry in ItemESPState.Tracked do
		local Adornee = Entry.Adornee
		local Visible = isItemESPCategoryEnabled(Entry.Category)

		if Visible and Root and typeof(Adornee) == "Instance" and Adornee:IsA("BasePart") then
			Visible = (Root.Position - Adornee.Position).Magnitude <= MaxDistance
		end

		if Entry.Box then
			Entry.Box.Visible = Visible
			Entry.Box.Transparency = Transparency
		end

		if Entry.Label then
			Entry.Label.Enabled = Visible and Environment.NotorietyESPTextEnabled and Environment.NotorietyItemESPLabels
			Entry.Label.MaxDistance = MaxDistance
		end

		if not Object.Parent
			or typeof(Adornee) ~= "Instance"
			or not Adornee.Parent
		then
			removeItemESPObject(Object)
		end
	end
end

local function inspectItemESPPrompt(Prompt)
	if Environment.NotorietyUnloaded
		or not Environment.NotorietyItemESPEnabled
		or not Prompt:IsA("ProximityPrompt")
		or not Prompt:IsDescendantOf(Workspace)
	then
		return
	end

	local CurrentCamera = Workspace.CurrentCamera

	if CurrentCamera and Prompt:IsDescendantOf(CurrentCamera) then
		return
	end

	local Object, Key, Data = resolveItemESPInteraction(Prompt)

	if not Object then
		return
	end

	local Category = classifyItemESPInteraction(Prompt, Key, Data)

	addItemESPObject(Category, Object)
end

local function stopItemESP()
	for _, Connection in ItemESPState.Connections do
		pcall(function()
			Connection:Disconnect()
		end)
	end

	table.clear(ItemESPState.Connections)
	table.clear(ItemESPState.ScanList)
	ItemESPState.ScanCursor = 1
	ItemESPState.Rescan = 0
	ItemESPState.ScanRefresh = 0

	local Objects = {}

	for Object in ItemESPState.Tracked do
		table.insert(Objects, Object)
	end

	for _, Object in Objects do
		removeItemESPObject(Object)
	end

	local Folder = ItemESPState.Folder
	ItemESPState.Folder = nil

	if Folder then
		pcall(function()
			Folder:Destroy()
		end)
	end
end

local function resolveESPParent()
	return resolveProtectedUIParent() or LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

local function startItemESP()
	stopItemESP()

	if not loadInteractionDefinitions() then
		warn("Item ESP could not load InteractList")
		return false
	end

	local Folder = ServiceResolver.ns("Folder")

	if not Folder then
		return false
	end

	Folder.Name = "NotorietyItemESP"
	Folder.Archivable = false
	local Parent = resolveESPParent()
	local ParentSuccess = typeof(Parent) == "Instance" and pcall(function()
		Folder.Parent = Parent
	end)

	if not ParentSuccess then
		pcall(function()
			Folder:Destroy()
		end)
		return false
	end

	ItemESPState.Folder = Folder
	ItemESPState.ScanList = CollectionService:GetTagged("Prompt")
	ItemESPState.ScanCursor = 1
	ItemESPState.Rescan = 0
	ItemESPState.ScanRefresh = 0

	for _, Prompt in ItemESPState.ScanList do
		inspectItemESPPrompt(Prompt)
	end

	table.insert(
		ItemESPState.Connections,
		CollectionService:GetInstanceAddedSignal("Prompt"):Connect(inspectItemESPPrompt)
	)
	return true
end

local function setItemESPEnabled(Enabled)
	Environment.NotorietyItemESPEnabled = Enabled == true

	if Environment.NotorietyItemESPEnabled then
		if not startItemESP() then
			Environment.NotorietyItemESPEnabled = false
		end
	else
		stopItemESP()
	end
end

local ItemESPController = {}

function ItemESPController.Cleanup()
	Environment.NotorietyItemESPEnabled = false
	stopItemESP()
end

Environment.NotorietyItemESPController = ItemESPController

local PoliceESPState = {
	Folder = nil,
	PoliceFolder = nil,
	Connections = {},
	Tracked = setmetatable({}, { __mode = "k" }),
	Refresh = 0,
	Rescan = 0,
	ScanCursor = 1,
}

local function removePoliceESP(Model)
	local Entry = PoliceESPState.Tracked[Model]

	if not Entry then
		return
	end

	for _, Connection in Entry.Connections or {} do
		pcall(function() Connection:Disconnect() end)
	end

	for _, InstanceObject in { Entry.Highlight, Entry.Label } do
		if InstanceObject then
			pcall(function() InstanceObject:Destroy() end)
		end
	end

	PoliceESPState.Tracked[Model] = nil
end

local function addPoliceESP(Model)
	if not Environment.NotorietyPoliceESPEnabled
		or typeof(Model) ~= "Instance"
		or not Model:IsA("Model")
		or PoliceESPState.Tracked[Model]
	then
		return
	end

	local Humanoid = Model:FindFirstChildWhichIsA("Humanoid", true)
	local Head = Model:FindFirstChild("Head", true)
	local Root = Model:FindFirstChild("HumanoidRootPart", true) or Head

	if not Humanoid or not Root or not Root:IsA("BasePart") then
		return
	end

	local Folder = PoliceESPState.Folder

	if not Folder then
		return
	end

	local Highlight = ServiceResolver.ns("Highlight")
	local Label = ServiceResolver.ns("BillboardGui")
	local Connections = {}

	if Highlight then
		Highlight.Name = "PoliceHighlight"
		Highlight.Adornee = Model
		Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		Highlight.FillColor = Color3.fromRGB(255, 70, 70)
		Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		Highlight.FillTransparency = 0.72
		Highlight.OutlineTransparency = 0.05
		Highlight.Parent = Folder
	end

	local Text

	if Label then
		Label.Name = "PoliceLabel"
		Label.Adornee = Head or Root
		Label.AlwaysOnTop = true
		Label.Size = UDim2.fromOffset(220, 34)
		Label.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
		Label.MaxDistance = resolveESPMaxDistance(Environment.NotorietyPoliceESPMaxDistance, 2500)
		Label.Parent = Folder

		Text = ServiceResolver.ns("TextLabel")

		if Text then
			Text.BackgroundTransparency = 1
			Text.Size = UDim2.fromScale(1, 1)
			Text.TextColor3 = Color3.fromRGB(255, 90, 90)
			Text.TextStrokeTransparency = 0.2
			Text.TextSize = 14
			Text.Font = Enum.Font.GothamSemibold
			Text.Parent = Label
		end
	end

	local function refreshText()
		if not Text then
			return
		end

		local Parts = {}

		if Environment.NotorietyPoliceESPNames then
			Parts[#Parts + 1] = Model.Name
		end

		if Environment.NotorietyPoliceESPHealth then
			Parts[#Parts + 1] = string.format("%d HP", math.max(math.floor(Humanoid.Health + 0.5), 0))
		end

		Text.Text = table.concat(Parts, " • ")
		Label.Enabled = Environment.NotorietyESPTextEnabled and #Parts > 0
	end

	Connections[#Connections + 1] = Humanoid.HealthChanged:Connect(refreshText)
	Connections[#Connections + 1] = Model.AncestryChanged:Connect(function(_, Parent)
		if not Parent then removePoliceESP(Model) end
	end)

	PoliceESPState.Tracked[Model] = {
		Humanoid = Humanoid,
		Root = Root,
		Highlight = Highlight,
		Label = Label,
		Text = Text,
		Connections = Connections,
		RefreshText = refreshText,
	}

	refreshText()
end

local function stopPoliceESP()
	for _, Connection in PoliceESPState.Connections do
		pcall(function() Connection:Disconnect() end)
	end
	table.clear(PoliceESPState.Connections)

	local Models = {}
	for Model in PoliceESPState.Tracked do Models[#Models + 1] = Model end
	for _, Model in Models do removePoliceESP(Model) end

	if PoliceESPState.Folder then
		pcall(function() PoliceESPState.Folder:Destroy() end)
	end

	PoliceESPState.Folder = nil
	PoliceESPState.PoliceFolder = nil
	PoliceESPState.Rescan = 0
	PoliceESPState.ScanCursor = 1
end

local function startPoliceESP()
	stopPoliceESP()

	local PoliceFolder = Workspace:FindFirstChild("Police")

	if not PoliceFolder then
		return false
	end

	local Folder = ServiceResolver.ns("Folder")
	if not Folder then return false end
	Folder.Name = "NotorietyPoliceESP"
	Folder.Archivable = false

	local Parent = resolveESPParent()
	local ParentSuccess = typeof(Parent) == "Instance" and pcall(function()
		Folder.Parent = Parent
	end)

	if not ParentSuccess then
		pcall(function()
			Folder:Destroy()
		end)
		return false
	end

	PoliceESPState.Folder = Folder
	PoliceESPState.PoliceFolder = PoliceFolder
	PoliceESPState.Rescan = 0
	PoliceESPState.ScanCursor = 1

	for _, Model in PoliceFolder:GetChildren() do addPoliceESP(Model) end
	PoliceESPState.Connections[#PoliceESPState.Connections + 1] = PoliceFolder.ChildAdded:Connect(function(Model)
		task.defer(addPoliceESP, Model)
	end)
	PoliceESPState.Connections[#PoliceESPState.Connections + 1] = PoliceFolder.DescendantAdded:Connect(function(Descendant)
		local Model = Descendant

		while Model and Model.Parent ~= PoliceFolder do
			Model = Model.Parent
		end

		if Model and Model:IsA("Model") and not PoliceESPState.Tracked[Model] then
			task.defer(addPoliceESP, Model)
		end
	end)
	return true
end

local function updatePoliceESP()
	if not Environment.NotorietyPoliceESPEnabled then return end

	local Character = LocalPlayer.Character
	local LocalRoot = Character and Character:FindFirstChild("HumanoidRootPart")
	local MaxDistance = resolveESPMaxDistance(Environment.NotorietyPoliceESPMaxDistance, 2500)

	for Model, Entry in PoliceESPState.Tracked do
		if not Model.Parent
			or not Entry.Humanoid
			or not Entry.Humanoid.Parent
			or not Entry.Root
			or not Entry.Root.Parent
		then
			removePoliceESP(Model)
		else
			local Visible = true

			if LocalRoot then
				Visible = (LocalRoot.Position - Entry.Root.Position).Magnitude <= MaxDistance
			end

			if Entry.Highlight then Entry.Highlight.Enabled = Visible end
			if Entry.Label then
				Entry.Label.MaxDistance = MaxDistance
				Entry.RefreshText()
				Entry.Label.Enabled = Visible and Entry.Label.Enabled
			end
		end
	end
end

local function setPoliceESPEnabled(Enabled)
	Environment.NotorietyPoliceESPEnabled = Enabled == true
	if Environment.NotorietyPoliceESPEnabled then
		if not startPoliceESP() then Environment.NotorietyPoliceESPEnabled = false end
	else
		stopPoliceESP()
	end
end

local function refreshPoliceESP()
	if Environment.NotorietyPoliceESPEnabled then startPoliceESP() end
end

local MusicOverrideState = {
	MusicInfo = nil,
	Tracks = { "Game Selection" },
	Folder = nil,
	LastAppliedTrack = nil,
	PlaySoundtrackFunction = nil,
	OriginalPlaySoundtrack = nil,
	WrappedPlaySoundtrack = nil,
	HookInstalled = false,
	Refresh = 0,
}

local function initializeMusicOverride()
	local ReplicatedScripts = RS_Package:FindFirstChild("ReplicatedScripts")
	local MusicInfoModule = ReplicatedScripts and ReplicatedScripts:FindFirstChild("MusicInfo")

	if not MusicInfoModule then return end

	local Success, MusicInfo = pcall(require, MusicInfoModule)
	if not Success or type(MusicInfo) ~= "table" then return end
	MusicOverrideState.MusicInfo = MusicInfo

	local Keys
	if type(MusicInfo.GetKeys) == "function" then
		local KeysSuccess, Result = pcall(MusicInfo.GetKeys, MusicInfo)
		if not KeysSuccess then KeysSuccess, Result = pcall(MusicInfo.GetKeys) end
		if KeysSuccess and type(Result) == "table" then Keys = Result end
	end

	if not Keys and type(MusicInfo.Soundtracks) == "table" then
		Keys = {}
		for Name, Data in MusicInfo.Soundtracks do
			if type(Name) == "string" and (type(Data) ~= "table" or Data.Enabled ~= false) then Keys[#Keys + 1] = Name end
		end
		table.sort(Keys)
	end

	if Keys then
		for _, Name in Keys do
			if Name ~= "Off" then MusicOverrideState.Tracks[#MusicOverrideState.Tracks + 1] = Name end
		end
	end
end

local function getMusicFolder()
	local PlayerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
	local SPSPackage = PlayerScripts and PlayerScripts:FindFirstChild("SPS_Package")
	local Music = SPSPackage and SPSPackage:FindFirstChild("Music")
	if Music then MusicOverrideState.Folder = Music end
	return Music
end

local function getMusicTrackEntryValue(Entry)
	if typeof(Entry) == "table" then
		return Entry.SoundId or Entry.ModFilePath, Entry.ModFilePath
	end
	return Entry, nil
end

local function isMusicTrackSelectionApplied(Track, Music)
	local MusicInfo = MusicOverrideState.MusicInfo
	local Soundtracks = MusicInfo and MusicInfo.Soundtracks
	local TrackData = Soundtracks and Soundtracks[Track]

	if type(TrackData) ~= "table" then
		return false
	end

	local Checked = false
	for Name, Entry in TrackData do
		local Sound = Music:FindFirstChild(Name)
		if Sound and Sound:IsA("Sound") then
			local Expected, ModFilePath = getMusicTrackEntryValue(Entry)
			if type(Expected) == "string" then
				Checked = true
				if ModFilePath then
					if Sound:GetAttribute("MOD_FilePath") ~= ModFilePath then return false end
				elseif Sound.SoundId ~= Expected then
					return false
				end
			end
		end
	end

	return Checked
end

local function applyMusicTrackSelection(Force)
	local Music = getMusicFolder()
	if not Music then return false end

	local Track = tostring(Environment.NotorietyMusicTrack or "Game Selection")

	if Track == "Game Selection" then
		MusicOverrideState.LastAppliedTrack = nil
		return true
	end

	if not Force
		and MusicOverrideState.LastAppliedTrack == Track
		and isMusicTrackSelectionApplied(Track, Music)
	then
		return true
	end

	local Finalize = Music:FindFirstChild("FinalizeSoundtrack")
	if not Finalize or not Finalize:IsA("BindableEvent") then return false end
	Finalize:Fire(Track)
	MusicOverrideState.LastAppliedTrack = Track
	return true
end

local function getNativeMusicMode()
	local Status = RS_Package:FindFirstChild("ReplicatedGameStatus")
	if not Status then return "Stealth" end
	local Assault = Status:FindFirstChild("PoliceAssault")
	local Anticipate = Status:FindFirstChild("Anticipate")
	local Caught = Status:FindFirstChild("Caught")
	if Assault and Assault.Value then return "Assault" end
	if Anticipate and Anticipate.Value then return "Anticipation" end
	if Caught and Caught.Value then return "Control" end
	return "Stealth"
end

local function getForcedNativeMusicMode()
	local RequestedMode = tostring(Environment.NotorietyMusicMode or "Follow Game")
	local ModeMap = {
		Stealth = "Stealth",
		Control = "Control",
		["Build Up"] = "Anticipation",
		Loud = "Assault",
	}
	return ModeMap[RequestedMode]
end

local function remapMusicModeRequest(Mode)
	local ForcedMode = getForcedNativeMusicMode()
	if not ForcedMode or type(Mode) ~= "string" then return Mode end

	if Mode == "Stealth" or Mode == "Control" or Mode == "Anticipation" or Mode == "Assault" then
		return ForcedMode
	end

	return Mode
end

local function findGamePlaySoundtrackFunction()
	if type(MusicOverrideState.PlaySoundtrackFunction) == "function" then
		return MusicOverrideState.PlaySoundtrackFunction
	end

	if type(getgc) ~= "function" or type(debug) ~= "table" or type(debug.getinfo) ~= "function" then
		return nil
	end

	local SourceSuffix = "Players." .. LocalPlayer.Name .. ".PlayerScripts.SPS_Package.Music.RunMusic"

	for _, Function in getgc(true) do
		if type(Function) == "function" then
			local Success, Info = pcall(debug.getinfo, Function)
			if Success
				and type(Info) == "table"
				and Info.name == "play_soundtrack"
				and tostring(Info.source):find(SourceSuffix, 1, true)
			then
				MusicOverrideState.PlaySoundtrackFunction = Function
				return Function
			end
		end
	end
end

local function installMusicModeHook()
	if MusicOverrideState.HookInstalled
		and type(MusicOverrideState.OriginalPlaySoundtrack) == "function"
	then
		return true
	end

	if type(hookfunction) ~= "function" then return false end
	local Target = findGamePlaySoundtrackFunction()
	if type(Target) ~= "function" then return false end

	local Original
	local function Wrapped(Mode, ...)
		return Original(remapMusicModeRequest(Mode), ...)
	end

	local Success, Result = pcall(hookfunction, Target, Wrapped)
	if not Success or type(Result) ~= "function" then return false end

	Original = Result
	MusicOverrideState.OriginalPlaySoundtrack = Result
	MusicOverrideState.WrappedPlaySoundtrack = Wrapped
	MusicOverrideState.HookInstalled = true
	return true
end

local function applyMusicModeOverride()
	applyMusicTrackSelection(false)
	if not installMusicModeHook() then return false end

	local Original = MusicOverrideState.OriginalPlaySoundtrack
	if type(Original) ~= "function" then return false end

	local RequestedMode = tostring(Environment.NotorietyMusicMode or "Follow Game")
	local TargetMode = RequestedMode == "Follow Game" and getNativeMusicMode() or getForcedNativeMusicMode()
	if not TargetMode then return false end

	task.spawn(function()
		pcall(Original, TargetMode)
	end)
	return true
end

local function restoreNativeMusicMode()
	if not installMusicModeHook() then return end
	local Original = MusicOverrideState.OriginalPlaySoundtrack
	if type(Original) == "function" then
		local NativeMode = getNativeMusicMode()
		task.spawn(function()
			pcall(Original, NativeMode)
		end)
	end
end

local function restoreMusicModeHook()
	if MusicOverrideState.HookInstalled
		and type(hookfunction) == "function"
		and type(MusicOverrideState.PlaySoundtrackFunction) == "function"
		and type(MusicOverrideState.OriginalPlaySoundtrack) == "function"
	then
		pcall(hookfunction, MusicOverrideState.PlaySoundtrackFunction, MusicOverrideState.OriginalPlaySoundtrack)
	end

	MusicOverrideState.PlaySoundtrackFunction = nil
	MusicOverrideState.OriginalPlaySoundtrack = nil
	MusicOverrideState.WrappedPlaySoundtrack = nil
	MusicOverrideState.HookInstalled = false
end

initializeMusicOverride()

local function createVibeUI()
	local UIAdapter = NotorietyUI.Library
	local Window = UIAdapter:CreateWindow({
		Title = "Notoriety",
		Folder = "Notoriety",
		Icon = "crosshair",
		NewElements = false,
		Size = UDim2.fromOffset(560, 430),
		ToggleKey = Enum.KeyCode.RightShift,
		HideSearchBar = true,
		OpenButton = {
			Title = "Notoriety",
			Enabled = true,
			Draggable = true,
			OnlyMobile = false,
		},
	})

	Environment.NotorietyWindow = Window
	NotorietyUI.Window = Window

	local ConfigManager = Window.ConfigManager
	local ConfigName = "default"

	local SaveGeneration = 0

	local function saveVibeUIConfig()
		if NotorietyUI.ConfigLoading or not NotorietyUI.Config then
			return false
		end

		local Success, SaveError = pcall(function()
			return NotorietyUI.Config:Save()
		end)

		if not Success then
			warn("[Notoriety] VibeUI config save failed: " .. tostring(SaveError))
			return false
		end

		return true
	end

	local function requestVibeUIConfigSave()
		if NotorietyUI.ConfigLoading or not NotorietyUI.Config then
			return
		end

		SaveGeneration += 1
		local Generation = SaveGeneration

		task.delay(0.12, function()
			if Generation ~= SaveGeneration
				or NotorietyUI.ConfigLoading
				or not NotorietyUI.Config
			then
				return
			end

			saveVibeUIConfig()
		end)
	end

	NotorietyUI.SaveConfig = saveVibeUIConfig
	NotorietyUI.RequestConfigSave = requestVibeUIConfigSave

	local MainTab = Window:Tab({
		Title = "Main",
		Icon = "house",
		Border = true,
	})

	MainTab:Toggle({
		Flag = "MaxEverything",
		Title = "Max Everything",
		Desc = "Keeps supported character values and finite supplies maxed",
		Value = Environment.MaxEverythingEnabled,
		Callback = function(Enabled)
			Environment.MaxEverythingEnabled = Enabled == true
			if Environment.MaxEverythingEnabled then Apply() end
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Button({
		Title = "Kill Police [P]",
		Desc = "Kills every currently spawned police NPC",
		Icon = "crosshair",
		Callback = function()
			task.spawn(runKill)
		end,
	})

	local TeammateTargetValues = getTeammatePickerValues()
	if not table.find(TeammateTargetValues, Environment.NotorietyTeammateTarget) then
		Environment.NotorietyTeammateTarget = "All"
	end

	NotorietyUI.TeammateTargetDropdown = MainTab:Dropdown({
		Flag = "TeammateTarget",
		Title = "Teammate Target",
		Desc = "Pick All or a specific current teammate",
		Values = TeammateTargetValues,
		Value = Environment.NotorietyTeammateTarget,
		Callback = function(Value)
			Environment.NotorietyTeammateTarget = tostring(Value or "All")
			requestVibeUIConfigSave()
		end,
	})

	local function refreshTeammateTargetDropdown()
		if Environment.NotorietyUnloaded then
			return
		end

		local Dropdown = NotorietyUI.TeammateTargetDropdown
		if type(Dropdown) ~= "table" or type(Dropdown.Refresh) ~= "function" then
			return
		end

		local Values = getTeammatePickerValues()
		Dropdown:Refresh(Values)

		if not table.find(Values, Environment.NotorietyTeammateTarget) then
			Environment.NotorietyTeammateTarget = "All"
			pcall(function()
				Dropdown:Set("All")
			end)
		end
	end

	local function queueTeammateTargetRefresh()
		task.defer(refreshTeammateTargetDropdown)
	end

	table.insert(Environment.NotorietyUIConnections, Players.PlayerAdded:Connect(queueTeammateTargetRefresh))
	table.insert(Environment.NotorietyUIConnections, Players.PlayerRemoving:Connect(queueTeammateTargetRefresh))

	local Criminals = Workspace:FindFirstChild("Criminals")
	if Criminals then
		table.insert(Environment.NotorietyUIConnections, Criminals.ChildAdded:Connect(queueTeammateTargetRefresh))
		table.insert(Environment.NotorietyUIConnections, Criminals.ChildRemoved:Connect(queueTeammateTargetRefresh))
	end

	MainTab:Button({
		Title = "Kill Teammate(s)",
		Desc = "Uses the selected teammate target; All targets every current teammate",
		Icon = "user-x",
		Callback = function()
			task.spawn(runKillTeammates, Environment.NotorietyTeammateTarget)
		end,
	})

	MainTab:Toggle({
		Flag = "InfiniteYellMark",
		Title = "Infinite Yell / Mark",
		Desc = "Enables the selected custom yell / mark targeting method",
		Value = Environment.NotorietyInfiniteYellMarkEnabled,
		Callback = function(Enabled)
			setYellMarkPatchEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Dropdown({
		Flag = "YellMarkMethod",
		Title = "Yell / Mark Method",
		Desc = "Viewport targets the screen, Whole Game targets every eligible object, Original restores the native 25-degree/range behavior",
		Values = {
			"Viewport",
			"Whole Game",
			"Original",
		},
		Value = Environment.NotorietyYellMarkMethod,
		Callback = function(Method)
			setYellMarkMethod(Method)
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Toggle({
		Flag = "YellThroughWalls",
		Title = "Yell / Mark Through Walls",
		Desc = "When disabled, Viewport and Whole Game require line of sight; Original always keeps the game's native visibility rules",
		Value = Environment.NotorietyYellThroughWalls,
		Callback = function(Enabled)
			setYellThroughWalls(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Toggle({
		Flag = "TeammateYellInfiniteRange",
		Title = "Boost / Inspire Infinite Range",
		Desc = "Custom Viewport/Whole Game modes can boost or inspire teammates beyond 100 studs; Original keeps the game's native behavior",
		Value = Environment.NotorietyTeammateYellInfiniteRange,
		Callback = function(Enabled)
			setTeammateYellInfiniteRange(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Toggle({
		Flag = "TeammateYellThroughWalls",
		Title = "Boost / Inspire Through Walls",
		Desc = "Custom Viewport/Whole Game modes can boost or inspire teammates through walls; Original keeps the game's native behavior",
		Value = Environment.NotorietyTeammateYellThroughWalls,
		Callback = function(Enabled)
			setTeammateYellThroughWalls(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Toggle({
		Flag = "AutoYell",
		Title = "Auto Yell",
		Desc = "Automatically yells new targets from the selected method without spamming unchanged custom targets",
		Value = Environment.NotorietyAutoYellEnabled,
		Callback = function(Enabled)
			YellPatchState.SetAutoYellEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Toggle({
		Flag = "NoYellDelay",
		Title = "No Yell / Mark Delay",
		Desc = "Removes the native 0.5 second client yell debounce without per-frame scanning",
		Value = Environment.NotorietyNoYellDelayEnabled,
		Callback = function(Enabled)
			YellPatchState.SetNoDelayEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Toggle({
		Flag = "PoliceHeadScaleEnabled",
		Title = "Police Head Scale",
		Desc = "Enlarges police head hitboxes",
		Value = Environment.NotorietyPoliceHeadScaleEnabled,
		Callback = function(Enabled)
			setPoliceHeadScaleEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	NotorietyUI.PoliceHeadScaleSlider = MainTab:Slider({
		Flag = "PoliceHeadScale",
		Title = "Police Head Scale Amount",
		Desc = "Multiplier for police head size",
		Min = 1,
		Max = 20,
		Step = 1,
		Suffix = "x",
		Value = Environment.NotorietyPoliceHeadScale,
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil then
				return
			end

			Environment.NotorietyPoliceHeadScale = math.clamp(Number, 1, 20)

			if Environment.NotorietyPoliceHeadScaleEnabled then
				applyPoliceHeadScale()
			end

			requestVibeUIConfigSave()
		end,
	})

	local ESPTab = Window:Tab({
		Title = "ESP",
		Icon = "eye",
		Border = true,
	})

	ESPTab:Toggle({
		Flag = "ESPText",
		Title = "ESP Text",
		Desc = "Master text switch. Disable this for box/highlight-only ESP",
		Value = Environment.NotorietyESPTextEnabled,
		Callback = function(Enabled)
			Environment.NotorietyESPTextEnabled = Enabled == true
			updateItemESPVisibility()
			updatePoliceESP()
			requestVibeUIConfigSave()
		end,
	})

	ESPTab:Toggle({
		Flag = "ItemESP",
		Title = "Item / Interaction ESP",
		Desc = "Highlights supported interactions and incrementally re-scans tagged prompts to catch late-loaded items",
		Value = Environment.NotorietyItemESPEnabled,
		Callback = function(Enabled)
			setItemESPEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	ESPTab:Toggle({
		Flag = "ItemESPLabels",
		Title = "Item ESP Text Details",
		Desc = "Controls item names/category text when the master ESP Text toggle is enabled",
		Value = Environment.NotorietyItemESPLabels,
		Callback = function(Enabled)
			Environment.NotorietyItemESPLabels = Enabled == true
			if Environment.NotorietyItemESPEnabled and not NotorietyUI.ConfigLoading then startItemESP() end
			requestVibeUIConfigSave()
		end,
	})

	NotorietyUI.ItemESPTransparencySlider = ESPTab:Slider({
		Flag = "ItemESPTransparency",
		Title = "Item Box Transparency",
		Desc = "0 = solid, 100 = invisible",
		Min = 0, Max = 100, Step = 1, Suffix = "%",
		Value = Environment.NotorietyItemESPTransparency,
		Callback = function(Value)
			Environment.NotorietyItemESPTransparency = math.clamp(tonumber(Value) or 55, 0, 100)
			updateItemESPVisibility()
			requestVibeUIConfigSave()
		end,
	})

	NotorietyUI.ItemESPDistanceSlider = ESPTab:Slider({
		Flag = "ItemESPDistance",
		Title = "Item ESP Distance",
		Desc = "Maximum display distance. 0 = infinite",
		Min = 0, Max = 10000, Step = 50, Suffix = " studs",
		Value = Environment.NotorietyItemESPMaxDistance,
		Callback = function(Value)
			Environment.NotorietyItemESPMaxDistance = math.clamp(tonumber(Value) or 2500, 0, 10000)
			updateItemESPVisibility()
			requestVibeUIConfigSave()
		end,
	})

	local CategoryTitles = {
		LOOT = "Loot", ITEM = "Tools / Items", KEY = "Keys / Passes", CONTAINER = "Containers",
		CAMERA = "Cameras", SECURITY = "Security Systems", ACCESS = "Access Objects", ESCAPE = "Escape / Secure",
	}

	for _, Category in { "LOOT", "ITEM", "KEY", "CONTAINER", "CAMERA", "SECURITY", "ACCESS", "ESCAPE" } do
		ESPTab:Toggle({
			Flag = "ItemESP_" .. Category,
			Title = "Show " .. CategoryTitles[Category],
			Desc = "Include this category in Item ESP",
			Value = Environment.NotorietyItemESPCategories[Category] ~= false,
			Callback = function(Enabled)
				Environment.NotorietyItemESPCategories[Category] = Enabled == true
				if Environment.NotorietyItemESPEnabled and not NotorietyUI.ConfigLoading then startItemESP() end
				requestVibeUIConfigSave()
			end,
		})
	end

	ESPTab:Toggle({
		Flag = "PoliceESP",
		Title = "Police ESP",
		Desc = "Highlights police through walls with event-driven late-load retries plus a bounded reconciliation scan",
		Value = Environment.NotorietyPoliceESPEnabled,
		Callback = function(Enabled)
			setPoliceESPEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	ESPTab:Toggle({
		Flag = "PoliceESPNames",
		Title = "Police Names",
		Value = Environment.NotorietyPoliceESPNames,
		Callback = function(Enabled)
			Environment.NotorietyPoliceESPNames = Enabled == true
			if not NotorietyUI.ConfigLoading then refreshPoliceESP() end
			requestVibeUIConfigSave()
		end,
	})

	ESPTab:Toggle({
		Flag = "PoliceESPHealth",
		Title = "Police Health",
		Value = Environment.NotorietyPoliceESPHealth,
		Callback = function(Enabled)
			Environment.NotorietyPoliceESPHealth = Enabled == true
			if not NotorietyUI.ConfigLoading then refreshPoliceESP() end
			requestVibeUIConfigSave()
		end,
	})

	NotorietyUI.PoliceESPDistanceSlider = ESPTab:Slider({
		Flag = "PoliceESPDistance",
		Title = "Police ESP Distance",
		Desc = "Maximum display distance. 0 = infinite",
		Min = 0, Max = 10000, Step = 50, Suffix = " studs",
		Value = Environment.NotorietyPoliceESPMaxDistance,
		Callback = function(Value)
			Environment.NotorietyPoliceESPMaxDistance = math.clamp(tonumber(Value) or 2500, 0, 10000)
			updatePoliceESP()
			requestVibeUIConfigSave()
		end,
	})

	local WeaponTab = Window:Tab({
		Title = "Weapon Mods",
		Icon = "crosshair",
		Border = true,
	})

	WeaponTab:Toggle({
		Flag = "WeaponMods",
		Title = "Weapon Mods",
		Desc = "Master switch for the weapon modifications below",
		Value = Environment.NotorietyWeaponEnabled,
		Callback = function(Enabled)
			setWeaponModificationsEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	local function addWeaponFeatureToggle(Flag, Title, Desc, EnvironmentKey)
		WeaponTab:Toggle({
			Flag = Flag,
			Title = Title,
			Desc = Desc,
			Value = Environment[EnvironmentKey] == true,
			Callback = function(Enabled)
				Environment[EnvironmentKey] = Enabled == true
				if not NotorietyUI.ConfigLoading then refreshWeaponModifications() end
				requestVibeUIConfigSave()
			end,
		})
	end

	WeaponTab:Toggle({
		Flag = "FriendlyFire",
		Title = "Friendly Fire",
		Desc = "Lets normal gunfire hit teammates; the toggle now forces the native FriendlyFire value to match the visible state",
		Value = Environment.NotorietyFriendlyFireEnabled,
		Callback = function(Enabled)
			setFriendlyFireEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	WeaponTab:Toggle({
		Flag = "SilentAim",
		Title = "Silent Aim",
		Desc = "Redirects each native gun shot toward the nearest enabled target group without moving the camera",
		Value = Environment.NotorietySilentAimEnabled,
		Callback = function(Enabled)
			Environment.NotorietySilentAimEnabled = Enabled == true
			if not NotorietyUI.ConfigLoading then refreshWeaponModifications() end
			requestVibeUIConfigSave()
		end,
	})

	addWeaponFeatureToggle(
		"SilentAimPolice",
		"Silent Aim: Police",
		"Allows Silent Aim to target police NPCs",
		"NotorietySilentAimTargetPolice"
	)
	addWeaponFeatureToggle(
		"SilentAimCriminals",
		"Silent Aim: Criminals / Teammates",
		"Allows Silent Aim to target other player criminals; Friendly Fire must permit teammate damage",
		"NotorietySilentAimTargetCriminals"
	)

	WeaponTab:Toggle({
		Flag = "WallBang",
		Title = "Wall Bang",
		Desc = "Raises native projectile penetration only when the shot is aimed at an enabled target group",
		Value = Environment.NotorietyWallBangEnabled,
		Callback = function(Enabled)
			Environment.NotorietyWallBangEnabled = Enabled == true
			if not NotorietyUI.ConfigLoading then refreshWeaponModifications() end
			requestVibeUIConfigSave()
		end,
	})

	addWeaponFeatureToggle(
		"WallBangPolice",
		"Wall Bang: Police",
		"Allows wall penetration when the shot is aimed at police",
		"NotorietyWallBangTargetPolice"
	)
	addWeaponFeatureToggle(
		"WallBangCriminals",
		"Wall Bang: Criminals / Teammates",
		"Allows wall penetration when the shot is aimed at another player criminal",
		"NotorietyWallBangTargetCriminals"
	)

	NotorietyUI.SilentAimFOVSlider = WeaponTab:Slider({
		Flag = "SilentAimFOV",
		Title = "Silent Aim FOV",
		Desc = "Maximum cursor distance in pixels. 0 = any on-screen enabled Silent Aim target",
		Min = 0,
		Max = 2000,
		Step = 1,
		Suffix = " px",
		Value = Environment.NotorietySilentAimFOV,
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil then
				return
			end

			Environment.NotorietySilentAimFOV = math.clamp(Number, 0, 2000)
			requestVibeUIConfigSave()
		end,
	})

	addWeaponFeatureToggle("RapidFire", "Rapid Fire", "Applies custom fire delay and bolt duration", "NotorietyRapidFireEnabled")
	addWeaponFeatureToggle("NoRecoil", "No Recoil", "Removes recoil, camera kick, shake, and pushback", "NotorietyNoRecoilEnabled")
	addWeaponFeatureToggle("InfiniteAmmo", "Infinite Ammo", "Keeps primary/secondary magazine and reserve ammo effectively infinite", "NotorietyInfiniteAmmoEnabled")
	addWeaponFeatureToggle("FullAuto", "Force Full Auto", "Forces supported guns into automatic fire mode", "NotorietyFullAutoEnabled")
	addWeaponFeatureToggle("AccuracyMod", "Accuracy Override", "Enables the custom accuracy slider independently of recoil", "NotorietyAccuracyModEnabled")

	NotorietyUI.FireDelaySlider = WeaponTab:Slider({
		Flag = "FireDelay",
		Title = "Fire Delay",
		Desc = "Shot cooldown in seconds. Default: 0.01",
		Min = 0,
		Max = 1,
		Step = 0.001,
		Suffix = "s",
		Value = math.clamp(Environment.NotorietyFireDelay, 0, 1),
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil then
				return
			end

			Environment.NotorietyFireDelay = Number

			if Environment.NotorietyWeaponEnabled and not NotorietyUI.ConfigLoading then
				refreshWeaponModifications()
			end

			requestVibeUIConfigSave()
		end,
	})

	NotorietyUI.BoltDurationSlider = WeaponTab:Slider({
		Flag = "BoltDuration",
		Title = "Bolt Duration",
		Desc = "Bolt animation/tween duration in seconds. Default: 0.001",
		Min = 0,
		Max = 1,
		Step = 0.001,
		Suffix = "s",
		Value = math.clamp(Environment.NotorietyBoltDuration, 0, 1),
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil then
				return
			end

			Environment.NotorietyBoltDuration = Number

			if Environment.NotorietyWeaponEnabled and not NotorietyUI.ConfigLoading then
				refreshWeaponModifications()
			end

			requestVibeUIConfigSave()
		end,
	})

	NotorietyUI.AccuracySlider = WeaponTab:Slider({
		Flag = "GunAccuracy",
		Title = "Gun Accuracy",
		Desc = "0-100, default: 100. Updates live weapon spread immediately.",
		Min = 0,
		Max = 100,
		Step = 1,
		Suffix = "%",
		Value = Environment.NotorietyAccuracy,
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil then
				return
			end

			Number = math.clamp(Number, 0, 100)
			Environment.NotorietyAccuracy = Number

			if Environment.NotorietyWeaponEnabled and not NotorietyUI.ConfigLoading then
				refreshWeaponModifications()
			end

			requestVibeUIConfigSave()
		end,
	})

	WeaponTab:Button({
		Title = "Reset Weapon Defaults",
		Desc = "Fire Delay = 0.01, Bolt Duration = 0.001, Accuracy = 100",
		Icon = "rotate-ccw",
		Callback = function()
			Environment.NotorietyFireDelay = 0.01
			Environment.NotorietyBoltDuration = 0.001
			Environment.NotorietyAccuracy = 100

			pcall(function()
				NotorietyUI.FireDelaySlider:Set(0.01)
			end)
			pcall(function()
				NotorietyUI.BoltDurationSlider:Set(0.001)
			end)
			pcall(function()
				NotorietyUI.AccuracySlider:Set(100)
			end)

			if Environment.NotorietyWeaponEnabled and not NotorietyUI.ConfigLoading then
				refreshWeaponModifications()
			end

			requestVibeUIConfigSave()
		end,
	})

	local AudioTab = Window:Tab({
		Title = "Audio",
		Icon = "volume-2",
		Border = true,
	})

	AudioTab:Dropdown({
		Flag = "MusicTrack",
		Title = "Soundtrack",
		Desc = "Game Selection follows the game's chosen track; selecting another track changes only your local soundtrack",
		Values = MusicOverrideState.Tracks,
		Value = table.find(MusicOverrideState.Tracks, Environment.NotorietyMusicTrack) and Environment.NotorietyMusicTrack or "Game Selection",
		Callback = function(Value)
			Environment.NotorietyMusicTrack = tostring(Value or "Game Selection")
			MusicOverrideState.LastAppliedTrack = nil
			if not NotorietyUI.ConfigLoading then
				applyMusicTrackSelection(true)
				applyMusicModeOverride()
			end
			requestVibeUIConfigSave()
		end,
	})

	AudioTab:Dropdown({
		Flag = "MusicMode",
		Title = "Force Music Mode",
		Desc = "Changes only the local soundtrack layer. Example: Loud music can play while the actual heist remains in Stealth",
		Values = { "Follow Game", "Stealth", "Control", "Build Up", "Loud" },
		Value = Environment.NotorietyMusicMode,
		Callback = function(Value)
			local Previous = Environment.NotorietyMusicMode
			Environment.NotorietyMusicMode = tostring(Value or "Follow Game")
			if not NotorietyUI.ConfigLoading then
				if Environment.NotorietyMusicMode == "Follow Game" and Previous ~= "Follow Game" then
					restoreNativeMusicMode()
				else
					applyMusicModeOverride()
				end
			end
			requestVibeUIConfigSave()
		end,
	})

	local function addAudioSlider(Flag, Title, Desc, EnvironmentKey)
		return AudioTab:Slider({
			Flag = Flag,
			Title = Title,
			Desc = Desc,
			Min = 0,
			Max = 100,
			Step = 1,
			Suffix = "%",
			Value = math.clamp(tonumber(Environment[EnvironmentKey]) or 100, 0, 100),
			Callback = function(Value)
				local Number = tonumber(Value)

				if Number == nil or Number ~= Number then
					return
				end

				Environment[EnvironmentKey] = math.clamp(Number, 0, 100)
				applyAudioVolumes()
				requestVibeUIConfigSave()
			end,
		})
	end

	NotorietyUI.MusicVolumeSlider = addAudioSlider(
		"MusicVolume",
		"Music Volume",
		"Heist/background music only",
		"NotorietyMusicVolume"
	)
	NotorietyUI.LocalGunshotsVolumeSlider = addAudioSlider(
		"LocalGunshotsVolume",
		"Your Gunshots",
		"Local weapon firing audio. Set to 0% to mute your shots without muting music",
		"NotorietyLocalGunshotsVolume"
	)
	NotorietyUI.GunshotsVolumeSlider = addAudioSlider(
		"GunshotsVolume",
		"Other Gunshots",
		"World/NPC/other-player gunfire",
		"NotorietyGunshotsVolume"
	)
	NotorietyUI.SFXVolumeSlider = addAudioSlider(
		"SFXVolume",
		"All SFX",
		"Master multiplier for grouped and ungrouped runtime SFX",
		"NotorietySFXVolume"
	)
	NotorietyUI.MapAmbienceVolumeSlider = addAudioSlider(
		"MapAmbienceVolume",
		"Map Ambience",
		"Environmental map loops, including ungrouped map sounds",
		"NotorietyMapAmbienceVolume"
	)
	NotorietyUI.VoicesVolumeSlider = addAudioSlider(
		"VoicesVolume",
		"Voices",
		"Character, narrator, and police voice audio",
		"NotorietyVoicesVolume"
	)
	NotorietyUI.UIVolumeSlider = addAudioSlider(
		"UIVolume",
		"UI Sounds",
		"PlayerGui/interface sounds; also follows the All SFX master",
		"NotorietyUIVolume"
	)

	AudioTab:Button({
		Title = "Reset Audio Volumes",
		Desc = "Resets all script audio sliders to 100%",
		Icon = "rotate-ccw",
		Callback = function()
			Environment.NotorietyMusicVolume = 100
			Environment.NotorietySFXVolume = 100
			Environment.NotorietyLocalGunshotsVolume = 100
			Environment.NotorietyGunshotsVolume = 100
			Environment.NotorietyMapAmbienceVolume = 100
			Environment.NotorietyVoicesVolume = 100
			Environment.NotorietyUIVolume = 100

			for _, Slider in {
				NotorietyUI.MusicVolumeSlider,
				NotorietyUI.SFXVolumeSlider,
				NotorietyUI.LocalGunshotsVolumeSlider,
				NotorietyUI.GunshotsVolumeSlider,
				NotorietyUI.MapAmbienceVolumeSlider,
				NotorietyUI.VoicesVolumeSlider,
				NotorietyUI.UIVolumeSlider,
			} do
				pcall(function()
					Slider:Set(100)
				end)
			end

			applyAudioVolumes()
			requestVibeUIConfigSave()
		end,
	})

	local EquipmentTab = Window:Tab({
		Title = "Equipment",
		Icon = "package",
		Border = true,
	})

	EquipmentTab:Toggle({
		Flag = "EquipmentSpeedEnabled",
		Title = "Equipment Placement Speed",
		Desc = "Uses the game\'s native equipment keybind/hold behavior with the selected speed multiplier",
		Value = Environment.NotorietyEquipmentSpeedEnabled,
		Callback = function(Enabled)
			Environment.NotorietyEquipmentSpeedEnabled = Enabled == true
			applyEquipmentPlacementSpeed()
			requestVibeUIConfigSave()
		end,
	})

	EquipmentTab:Toggle({
		Flag = "EquipmentInstantEnabled",
		Title = "Instant Equipment Placement",
		Desc = "Keeps the game\'s native 0.5s hold delay, then completes placement immediately",
		Value = Environment.NotorietyEquipmentInstantEnabled,
		Callback = function(Enabled)
			Environment.NotorietyEquipmentInstantEnabled = Enabled == true
			applyEquipmentPlacementSpeed()
			requestVibeUIConfigSave()
		end,
	})

	NotorietyUI.EquipmentSpeedSlider = EquipmentTab:Slider({
		Flag = "EquipmentSpeedMultiplier",
		Title = "Placement Speed",
		Desc = "Default: 2x. Use 1 for normal speed",
		Min = 1,
		Max = 10,
		Step = 0.1,
		Suffix = "x",
		Value = math.clamp(Environment.NotorietyEquipmentSpeedMultiplier, 1, 10),
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil
				or Number <= 0
				or Number == math.huge
				or Number ~= Number
			then
				return
			end

			Environment.NotorietyEquipmentSpeedMultiplier = Number

			if Environment.NotorietyEquipmentSpeedEnabled then
				applyEquipmentPlacementSpeed()
			end

			requestVibeUIConfigSave()
		end,
	})

	EquipmentTab:Button({
		Title = "Reset Placement Speed",
		Desc = "Resets the multiplier to 2x",
		Icon = "rotate-ccw",
		Callback = function()
			Environment.NotorietyEquipmentSpeedMultiplier = 2

			pcall(function()
				NotorietyUI.EquipmentSpeedSlider:Set(2)
			end)

			if Environment.NotorietyEquipmentSpeedEnabled then
				applyEquipmentPlacementSpeed()
			end

			requestVibeUIConfigSave()
		end,
	})

	EquipmentTab:Toggle({
		Flag = "InfiniteEquipment",
		Title = "Infinite Equipment",
		Desc = "Keeps primary and secondary equipment uses full independently of Max Everything",
		Value = Environment.NotorietyInfiniteEquipmentEnabled,
		Callback = function(Enabled)
			Environment.NotorietyInfiniteEquipmentEnabled = Enabled == true
			Apply()
			requestVibeUIConfigSave()
		end,
	})

	EquipmentTab:Toggle({
		Flag = "EquipmentRangeEnabled",
		Title = "Extended Placement Range",
		Desc = "Extends the equipment placement ray beyond the normal 10 studs",
		Value = Environment.NotorietyEquipmentRangeEnabled,
		Callback = function(Enabled)
			Environment.NotorietyEquipmentRangeEnabled = Enabled == true
			applyEquipmentPlacementRange()
			requestVibeUIConfigSave()
		end,
	})

	NotorietyUI.EquipmentRangeSlider = EquipmentTab:Slider({
		Flag = "EquipmentPlacementRange",
		Title = "Placement Range",
		Desc = "Game default: 10 studs",
		Min = 10,
		Max = 100,
		Step = 1,
		Suffix = " studs",
		Value = math.clamp(Environment.NotorietyEquipmentPlacementRange, 10, 100),
		Callback = function(Value)
			local Number = tonumber(Value)
			if Number == nil or Number ~= Number then return end
			Environment.NotorietyEquipmentPlacementRange = math.clamp(Number, 10, 100)
			applyEquipmentPlacementRange()
			requestVibeUIConfigSave()
		end,
	})

	EquipmentTab:Toggle({
		Flag = "EquipmentPositionEnabled",
		Title = "Custom Equipment Position",
		Desc = "Offsets the preview and final placement position",
		Value = Environment.NotorietyEquipmentPositionEnabled,
		Callback = function(Enabled)
			Environment.NotorietyEquipmentPositionEnabled = Enabled == true
			applyEquipmentPositioning()
			requestVibeUIConfigSave()
		end,
	})

	NotorietyUI.EquipmentPositionXSlider = EquipmentTab:Slider({
		Flag = "EquipmentPositionX",
		Title = "Left / Right Offset",
		Desc = "Positive = right, negative = left",
		Min = -50,
		Max = 50,
		Step = 0.5,
		Suffix = " studs",
		Value = math.clamp(Environment.NotorietyEquipmentPositionX, -50, 50),
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil or Number == math.huge or Number == -math.huge or Number ~= Number then
				return
			end

			Environment.NotorietyEquipmentPositionX = Number
			requestVibeUIConfigSave()
		end,
	})

	NotorietyUI.EquipmentPositionYSlider = EquipmentTab:Slider({
		Flag = "EquipmentPositionY",
		Title = "Up / Down Offset",
		Desc = "Positive = up, negative = down",
		Min = -50,
		Max = 50,
		Step = 0.5,
		Suffix = " studs",
		Value = math.clamp(Environment.NotorietyEquipmentPositionY, -50, 50),
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil or Number == math.huge or Number == -math.huge or Number ~= Number then
				return
			end

			Environment.NotorietyEquipmentPositionY = Number
			requestVibeUIConfigSave()
		end,
	})

	NotorietyUI.EquipmentPositionZSlider = EquipmentTab:Slider({
		Flag = "EquipmentPositionZ",
		Title = "Forward / Back Offset",
		Desc = "Positive = forward, negative = back",
		Min = -50,
		Max = 50,
		Step = 0.5,
		Suffix = " studs",
		Value = math.clamp(Environment.NotorietyEquipmentPositionZ, -50, 50),
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil or Number == math.huge or Number == -math.huge or Number ~= Number then
				return
			end

			Environment.NotorietyEquipmentPositionZ = Number
			requestVibeUIConfigSave()
		end,
	})

	EquipmentTab:Button({
		Title = "Reset Equipment Position",
		Desc = "Resets X, Y, and Z offsets to 0",
		Icon = "rotate-ccw",
		Callback = function()
			Environment.NotorietyEquipmentPositionX = 0
			Environment.NotorietyEquipmentPositionY = 0
			Environment.NotorietyEquipmentPositionZ = 0

			pcall(function()
				NotorietyUI.EquipmentPositionXSlider:Set(0)
			end)
			pcall(function()
				NotorietyUI.EquipmentPositionYSlider:Set(0)
			end)
			pcall(function()
				NotorietyUI.EquipmentPositionZSlider:Set(0)
			end)

			requestVibeUIConfigSave()
		end,
	})

	local UtilityTab = Window:Tab({
		Title = "Utility",
		Icon = "settings",
		Border = true,
	})

	UtilityTab:Keybind({
		Flag = "ToggleUIKey",
		Title = "Toggle UI",
		Desc = "Default: RightShift",
		Value = "RightShift",
		Callback = function(Value)
			local KeyCode = Enum.KeyCode[Value]

			if KeyCode then
				Window:SetToggleKey(KeyCode)
			end

			requestVibeUIConfigSave()
		end,
	})

	UtilityTab:Button({
		Title = "Unload",
		Desc = "Restores modified data and unloads Notoriety",
		Icon = "log-out",
		Callback = function()
			requestVibeUIConfigSave()

			task.defer(function()
				if type(Environment.UnloadNotoriety) == "function" then
					Environment.UnloadNotoriety()
				end
			end)
		end,
	})

	if type(ConfigManager) == "table" then
		local Configs = ConfigManager:AllConfigs()
		local Config = ConfigManager:Config(ConfigName)

		Window.CurrentConfig = Config
		NotorietyUI.Config = Config
		NotorietyUI.ConfigLoading = true

		if table.find(Configs, ConfigName) then
			pcall(function()
				Config:Load()
			end)
		else
			pcall(function()
				Config:Save()
			end)
		end

		NotorietyUI.ConfigLoading = false
	end

	pcall(function()
		ContextActionService:UnbindAction("NotorietyKillPolice")
	end)

	ContextActionService:BindActionAtPriority(
		"NotorietyKillPolice",
		function(_, InputState)
			if InputState == Enum.UserInputState.Begin and not Environment.NotorietyUnloaded then
				task.spawn(runKill)
			end

			return Enum.ContextActionResult.Pass
		end,
		false,
		Enum.ContextActionPriority.High.Value + 1,
		Enum.KeyCode.P
	)
end

local function disconnectConnection(Connection)
	if Connection then
		pcall(function()
			Connection:Disconnect()
		end)
	end
end

local function disconnectConnections(Connections)
	if type(Connections) ~= "table" then
		return
	end

	for _, Connection in Connections do
		disconnectConnection(Connection)
	end

	table.clear(Connections)
end

local function unloadNotoriety()
	if Environment.NotorietyUnloaded then
		return
	end

	if type(NotorietyUI.SaveConfig) == "function" then
		NotorietyUI.SaveConfig()
	end

	Environment.NotorietyUnloaded = true
	Environment.MaxEverythingEnabled = false
	Environment.NotorietyWeaponEnabled = false
	Environment.NotorietyFriendlyFireEnabled = false
	Environment.NotorietySilentAimEnabled = false
	Environment.NotorietyWallBangEnabled = false
	Environment.NotorietyItemESPEnabled = false
	Environment.NotorietyPoliceESPEnabled = false
	Environment.NotorietyPoliceHeadScaleEnabled = false
	Environment.NotorietyInfiniteYellMarkEnabled = false
	Environment.NotorietyAutoYellEnabled = false
	Environment.NotorietyNoYellDelayEnabled = false
	Environment.KillPoliceRunning = false
	Environment.KillTeammatesRunning = false

	pcall(function()
		ContextActionService:UnbindAction("NotorietyKillPolice")
	end)

	disconnectConnection(Environment.MaxEverythingConnection)
	disconnectConnection(Environment.MaxEverythingCharacterConnection)
	disconnectConnection(Environment.NotorietyPoliceHitboxConnection)

	Environment.MaxEverythingConnection = nil
	Environment.MaxEverythingCharacterConnection = nil
	Environment.NotorietyPoliceHitboxConnection = nil

	disconnectConnections(Environment.NotorietyWeaponConnections)
	disconnectConnections(Environment.NotorietyUIConnections)

	if type(Environment.NotorietyGetAmmoWrappers) == "table" then
		for State, Record in Environment.NotorietyGetAmmoWrappers do
			if type(State) == "table" and type(Record) == "table" then
				local Original = Record.Original
				local Wrapper = Record.Wrapper

				if type(Original) == "function" and State.getAmmo == Wrapper then
					State.getAmmo = Original
				end
			end
		end
	end

	restoreFriendlyFire()
	restoreRuntimeSilentAimWrappers()
	restoreAllWeaponData()
	restoreRuntimeWeaponAccuracy()
	restoreRuntimeWeaponRecoil()
	restoreAllAmmoWrappers()
	restoreEquipmentPlacementSpeed()
	restoreMobileEquipmentPlacementFix()
	restoreAudioVolumes()
	restoreYellMarkPatch()
	YellPatchState.ClearNoDelayConnections()
	table.clear(YellPatchState.NoDelayTargets)
	table.clear(YellPatchState.AutoSeen)
	table.clear(YellPatchState.TargetParts)
	table.clear(YellPatchState.SkillCache)
	ItemESPController.Cleanup()
	stopPoliceESP()
	restoreNativeMusicMode()
	restoreMusicModeHook()

	for Object in PoliceOriginalSizes do
		pcall(restorePolicePart, Object)
	end
	Environment.NotorietyItemESPController = nil

	local CurrentWindow = Environment.NotorietyWindow
	Environment.NotorietyWindow = nil
	NotorietyUI.Window = nil
	NotorietyUI.Config = nil
	NotorietyUI.SaveConfig = nil
	NotorietyUI.RequestConfigSave = nil
	NotorietyUI.MouseUnlockButton = nil

	if CurrentWindow then
		pcall(function()
			CurrentWindow:Destroy()
		end)
	end

	Environment.NotorietyGetAmmoWrappers = setmetatable({}, {
		__mode = "k",
	})

	table.clear(WeaponState.RuntimeWeapons)
	table.clear(WeaponState.RuntimeSilentAimBackups)
end

Environment.UnloadNotoriety = unloadNotoriety

trackWeaponContainer(Weapons)
trackWeaponContainer(Backpack)
trackWeaponContainer(LocalPlayer.Character)
createVibeUI()

if typeof(NotorietyUI.Root) == "Instance" and type(UIProtector.protectUI) == "function" then
	local ProtectedParent = resolveProtectedUIParent()
	local Success, ProtectedRoot = pcall(UIProtector.protectUI, NotorietyUI.Root, {
		keepName = true,
		parent = ProtectedParent,
	})

	if Success and typeof(ProtectedRoot) == "Instance" then
		NotorietyUI.Root = ProtectedRoot
	end
end

applyPoliceHeadScale()
setFriendlyFireEnabled(Environment.NotorietyFriendlyFireEnabled)
setWeaponModificationsEnabled(Environment.NotorietyWeaponEnabled)
setYellMarkPatchEnabled(Environment.NotorietyInfiniteYellMarkEnabled)
YellPatchState.SetAutoYellEnabled(Environment.NotorietyAutoYellEnabled)
YellPatchState.SetNoDelayEnabled(Environment.NotorietyNoYellDelayEnabled)
applyEquipmentPlacementSpeed()
applyEquipmentPositioning()
applyEquipmentPlacementRange()
applyMobileEquipmentPlacementFix()
applyAudioVolumes()
if Environment.NotorietyItemESPEnabled then setItemESPEnabled(true) end
if Environment.NotorietyPoliceESPEnabled then setPoliceESPEnabled(true) end
applyMusicTrackSelection(true)
applyMusicModeOverride()

Environment.MaxEverythingConnection = RunService.Heartbeat:Connect(function(DeltaTime)
	if Environment.NotorietyUnloaded then
		return
	end

	Apply()

	if Environment.NotorietyAutoYellEnabled then
		YellPatchState.AutoRefresh += DeltaTime

		if YellPatchState.AutoRefresh >= 0.75 then
			YellPatchState.AutoRefresh = 0
			YellPatchState.AutoYell()
		end
	else
		YellPatchState.AutoRefresh = 0
	end

	ItemESPState.Refresh += DeltaTime
	ItemESPState.Rescan += DeltaTime
	ItemESPState.ScanRefresh += DeltaTime
	if ItemESPState.Refresh >= 0.25 then
		ItemESPState.Refresh = 0
		if Environment.NotorietyItemESPEnabled then updateItemESPVisibility() end
	end

	if Environment.NotorietyItemESPEnabled and ItemESPState.Rescan >= 0.5 then
		ItemESPState.Rescan = 0

		if ItemESPState.ScanRefresh >= 2 or #ItemESPState.ScanList == 0 then
			ItemESPState.ScanRefresh = 0
			ItemESPState.ScanList = CollectionService:GetTagged("Prompt")
			if ItemESPState.ScanCursor > #ItemESPState.ScanList then
				ItemESPState.ScanCursor = 1
			end
		end

		local ScanCount = #ItemESPState.ScanList
		local ScanBudget = math.min(24, ScanCount)

		for _ = 1, ScanBudget do
			if ItemESPState.ScanCursor > ScanCount then
				ItemESPState.ScanCursor = 1
			end

			local Prompt = ItemESPState.ScanList[ItemESPState.ScanCursor]
			ItemESPState.ScanCursor += 1

			if typeof(Prompt) == "Instance" and Prompt.Parent then
				inspectItemESPPrompt(Prompt)
			end
		end
	elseif not Environment.NotorietyItemESPEnabled then
		ItemESPState.Rescan = 0
		ItemESPState.ScanRefresh = 0
	end

	PoliceESPState.Refresh += DeltaTime
	PoliceESPState.Rescan += DeltaTime
	if PoliceESPState.Refresh >= 0.25 then
		PoliceESPState.Refresh = 0
		if Environment.NotorietyPoliceESPEnabled then updatePoliceESP() end
	end

	if Environment.NotorietyPoliceESPEnabled and PoliceESPState.Rescan >= 0.75 then
		PoliceESPState.Rescan = 0
		local PoliceFolder = PoliceESPState.PoliceFolder

		if PoliceFolder and PoliceFolder.Parent then
			local Models = PoliceFolder:GetChildren()
			local ModelCount = #Models
			local ScanBudget = math.min(12, ModelCount)

			for _ = 1, ScanBudget do
				if PoliceESPState.ScanCursor > ModelCount then
					PoliceESPState.ScanCursor = 1
				end

				local Model = Models[PoliceESPState.ScanCursor]
				PoliceESPState.ScanCursor += 1

				if Model and not PoliceESPState.Tracked[Model] then
					addPoliceESP(Model)
				end
			end
		end
	elseif not Environment.NotorietyPoliceESPEnabled then
		PoliceESPState.Rescan = 0
	end

	MusicOverrideState.Refresh += DeltaTime
	if MusicOverrideState.Refresh >= 1 then
		MusicOverrideState.Refresh = 0
		if Environment.NotorietyMusicTrack ~= "Game Selection" then applyMusicTrackSelection(false) end
		if Environment.NotorietyMusicMode ~= "Follow Game" and not MusicOverrideState.HookInstalled then
			applyMusicModeOverride()
		end
	end

	EquipmentSpeedState.Refresh += DeltaTime

	if EquipmentSpeedState.Refresh >= 1 then
		EquipmentSpeedState.Refresh = 0

		if Environment.NotorietyInfiniteYellMarkEnabled then
			applyYellMarkPatch()
		end
	end

	if not Environment.NotorietyWeaponEnabled then
		return
	end

	refreshRuntimeAmmo()
	WeaponState.RuntimeRefresh += DeltaTime

	if WeaponState.RuntimeRefresh >= 0.25 then
		WeaponState.RuntimeRefresh = 0

		for Data in WeaponState.Backups do
			applyWeaponData(Data)
		end
	end
end)

Environment.MaxEverythingCharacterConnection = LocalPlayer.CharacterAdded:Connect(function(Character)
	if Environment.NotorietyUnloaded then
		return
	end

	task.wait(1)

	if Environment.NotorietyUnloaded then
		return
	end

	Apply()
	applyEquipmentPlacementSpeed()
	applyEquipmentPositioning()
	applyEquipmentPlacementRange()
	applyMobileEquipmentPlacementFix()
	applyAudioVolumes()
	if Environment.NotorietyPoliceESPEnabled then refreshPoliceESP() end
	applyMusicTrackSelection(true)
	applyMusicModeOverride()
	trackWeaponContainer(Character)
	table.clear(YellPatchState.TargetParts)
	table.clear(YellPatchState.SkillCache)
	table.clear(YellPatchState.AutoSeen)

	if Environment.NotorietyNoYellDelayEnabled then
		YellPatchState.RefreshNoDelayTargets()
		YellPatchState.ConnectNoDelaySignals()
	end

	if Environment.NotorietyWeaponEnabled then
		applyAllWeaponModifications()
	end
end)

Apply()
