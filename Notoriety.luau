local NState = {}
NState.Environment = if type(getgenv) == "function" then getgenv() else _G

NState.PreviousUnload = rawget(NState.Environment, "UnloadNotoriety")

if type(NState.PreviousUnload) == "function" then
	pcall(NState.PreviousUnload)
end

NState.ServiceResolver = rawget(NState.Environment, "__lt_service_resolver")

if type(NState.ServiceResolver) ~= "table" then
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

	NState.ServiceResolver = ResolverResult
	NState.Environment.__lt_service_resolver = NState.ServiceResolver
end

NState.UIProtectorURL = "https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/UIprotector.luau"

NState.loadUIProtector = function()
	local Loader = loadstring

	if type(Loader) ~= "function" then
		error("UIProtector loader unavailable")
	end

	local ProtectorSource = game:HttpGet(NState.UIProtectorURL)
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

NState.UIProtector = NState.loadUIProtector()

NState.resolveProtectedUIParent = function()
	local ResolveParent = NState.UIProtector.resolveParent

	if type(ResolveParent) == "function" then
		local Success, Parent = pcall(ResolveParent)

		if Success and typeof(Parent) == "Instance" then
			return Parent
		end
	end

	local ParentFunction = NState.UIProtector.parent

	if type(ParentFunction) == "function" then
		local Success, Parent = pcall(ParentFunction)

		if Success and typeof(Parent) == "Instance" then
			return Parent
		end
	end

	return nil
end

NState.Reference = if type(cloneref) == "function" then cloneref else function(Value)
	return Value
end

NState.ReplicatedStorage = NState.ServiceResolver.cs("ReplicatedStorage", NState.Reference)
NState.Workspace = NState.ServiceResolver.cs("Workspace", NState.Reference)
NState.Players = NState.ServiceResolver.cs("Players", NState.Reference)
NState.RunService = NState.ServiceResolver.cs("RunService", NState.Reference)
NState.CollectionService = NState.ServiceResolver.cs("CollectionService", NState.Reference)
NState.ContextActionService = NState.ServiceResolver.cs("ContextActionService", NState.Reference)
NState.UserInputService = NState.ServiceResolver.cs("UserInputService", NState.Reference)
NState.SoundService = NState.ServiceResolver.cs("SoundService", NState.Reference)

NState.LocalPlayer = NState.Players.LocalPlayer

NState.RS_Package = NState.ReplicatedStorage:WaitForChild("RS_Package", math.huge)
NState.Assets = NState.RS_Package:WaitForChild("Assets", math.huge)
NState.Remotes = NState.Assets:WaitForChild("Remotes", math.huge)
NState.Event = NState.Remotes:WaitForChild("Damage", math.huge)

NState.NotorietyUI = {}

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
	local PreviousEnvironmentVibeUI = rawget(NState.Environment, "VibeUI")

	if SharedEnvironment then
		rawset(SharedEnvironment, "VibeUI", nil)
	end

	rawset(NState.Environment, "VibeUI", nil)
	local VibeUIChunk, VibeUICompileError = loadstring(VibeUISource, "@VibeUI.lua")

	if type(VibeUIChunk) ~= "function" then
		error("VibeUI compile failed: " .. tostring(VibeUICompileError))
	end

	local VibeUISuccess, VibeUI = pcall(VibeUIChunk)

	if SharedEnvironment then
		rawset(SharedEnvironment, "VibeUI", PreviousSharedVibeUI)
	end

	rawset(NState.Environment, "VibeUI", PreviousEnvironmentVibeUI)

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
		NState.NotorietyUI.Root = if typeof(NativeRoot) == "Instance"
			then NativeRoot:FindFirstAncestorOfClass("ScreenGui")
			else nil

		local MouseUnlockButton

		if typeof(NativeRoot) == "Instance" then
			MouseUnlockButton = NState.ServiceResolver.ns("TextButton")

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

		NState.NotorietyUI.MouseUnlockButton = MouseUnlockButton

		local function wrapControlCallback(Control, Callback)
			return function(...)
				if type(Callback) == "function" then
					Callback(...)
				end

				local RequestSave = NState.NotorietyUI.RequestConfigSave

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

			rawset(NState.Environment, "VibeUI", PreviousEnvironmentVibeUI)

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

	NState.NotorietyUI.Library = Adapter
end

if NState.Environment.MaxEverythingConnection then
	NState.Environment.MaxEverythingConnection:Disconnect()
	NState.Environment.MaxEverythingConnection = nil
end

if NState.Environment.MaxEverythingCharacterConnection then
	NState.Environment.MaxEverythingCharacterConnection:Disconnect()
	NState.Environment.MaxEverythingCharacterConnection = nil
end

if NState.Environment.NotorietyPoliceHitboxConnection then
	NState.Environment.NotorietyPoliceHitboxConnection:Disconnect()
	NState.Environment.NotorietyPoliceHitboxConnection = nil
end

if type(NState.Environment.NotorietyWeaponConnections) == "table" then
	for _, Connection in NState.Environment.NotorietyWeaponConnections do
		pcall(function()
			Connection:Disconnect()
		end)
	end
end

if type(NState.Environment.NotorietyNoDelayConnections) == "table" then
	for _, Connection in NState.Environment.NotorietyNoDelayConnections do
		pcall(function()
			Connection:Disconnect()
		end)
	end
end

NState.Environment.NotorietyNoDelayConnections = {}

if type(NState.Environment.NotorietyGetAmmoWrappers) == "table" then
	for State, Record in NState.Environment.NotorietyGetAmmoWrappers do
		if type(State) == "table" and type(Record) == "table" then
			local Original = Record.Original
			local Wrapper = Record.Wrapper

			if type(Original) == "function" and State.getAmmo == Wrapper then
				State.getAmmo = Original
			end
		end
	end
end

NState.Environment.NotorietyGetAmmoWrappers = setmetatable({}, {
	__mode = "k",
})

if type(NState.Environment.NotorietyItemESPController) == "table"
	and type(NState.Environment.NotorietyItemESPController.Cleanup) == "function"
then
	pcall(NState.Environment.NotorietyItemESPController.Cleanup)
	NState.Environment.NotorietyItemESPController = nil
end

if NState.Environment.NotorietyWindow then
	pcall(function()
		NState.Environment.NotorietyWindow:Destroy()
	end)

	NState.Environment.NotorietyWindow = nil
end

if type(NState.Environment.NotorietyUIConnections) == "table" then
	for _, Connection in NState.Environment.NotorietyUIConnections do
		pcall(function()
			Connection:Disconnect()
		end)
	end
end

NState.Environment.MaxEverythingEnabled = true
NState.Environment.KillPoliceRunning = false
NState.Environment.KillTeammatesRunning = false
NState.Environment.NotorietyTeammateTarget = tostring(NState.Environment.NotorietyTeammateTarget or "All")
NState.Environment.NotorietyWeaponEnabled = NState.Environment.NotorietyWeaponEnabled ~= false
NState.Environment.NotorietyFriendlyFireEnabled = NState.Environment.NotorietyFriendlyFireEnabled ~= false
NState.Environment.NotorietyRealismModeEnabled = NState.Environment.NotorietyRealismModeEnabled == true
NState.Environment.NotorietyBugFeatureEnabled = NState.Environment.NotorietyBugFeatureEnabled == true
NState.Environment.NotorietyRapidFireEnabled = NState.Environment.NotorietyRapidFireEnabled ~= false
NState.Environment.NotorietyNoRecoilEnabled = NState.Environment.NotorietyNoRecoilEnabled ~= false
NState.Environment.NotorietyInfiniteAmmoEnabled = NState.Environment.NotorietyInfiniteAmmoEnabled ~= false
NState.Environment.NotorietyFullAutoEnabled = NState.Environment.NotorietyFullAutoEnabled ~= false
NState.Environment.NotorietyAccuracyModEnabled = NState.Environment.NotorietyAccuracyModEnabled ~= false
NState.Environment.NotorietySilentAimEnabled = NState.Environment.NotorietySilentAimEnabled == true
NState.Environment.NotorietyWallBangEnabled = NState.Environment.NotorietyWallBangEnabled == true
NState.Environment.NotorietySilentAimTargetPolice = NState.Environment.NotorietySilentAimTargetPolice ~= false
NState.Environment.NotorietySilentAimTargetCriminals = NState.Environment.NotorietySilentAimTargetCriminals == true
NState.Environment.NotorietyWallBangTargetPolice = NState.Environment.NotorietyWallBangTargetPolice ~= false
NState.Environment.NotorietyWallBangTargetCriminals = NState.Environment.NotorietyWallBangTargetCriminals == true
NState.Environment.NotorietySilentAimFOV = math.clamp(tonumber(NState.Environment.NotorietySilentAimFOV) or 250, 0, 2000)
NState.Environment.NotorietyFireDelay = math.clamp(tonumber(NState.Environment.NotorietyFireDelay) or 0.01, 0, 1)
NState.Environment.NotorietyBoltDuration = math.clamp(tonumber(NState.Environment.NotorietyBoltDuration) or 0.001, 0, 1)
NState.Environment.NotorietyAccuracy = tonumber(NState.Environment.NotorietyAccuracy) or 100
NState.Environment.NotorietyItemESPEnabled = NState.Environment.NotorietyItemESPEnabled == true
NState.Environment.NotorietyESPTextEnabled = NState.Environment.NotorietyESPTextEnabled ~= false
NState.Environment.NotorietyItemESPLabels = NState.Environment.NotorietyItemESPLabels ~= false
NState.Environment.NotorietyItemESPTransparency = math.clamp(tonumber(NState.Environment.NotorietyItemESPTransparency) or 55, 0, 100)
NState.Environment.NotorietyItemESPMaxDistance = math.clamp(tonumber(NState.Environment.NotorietyItemESPMaxDistance) or 2500, 0, 10000)
NState.Environment.NotorietyItemESPCategories = type(NState.Environment.NotorietyItemESPCategories) == "table" and NState.Environment.NotorietyItemESPCategories or {}
for _, Category in { "LOOT", "ITEM", "KEY", "CONTAINER", "CAMERA", "SECURITY", "ACCESS", "ESCAPE" } do
	if NState.Environment.NotorietyItemESPCategories[Category] == nil then
		NState.Environment.NotorietyItemESPCategories[Category] = true
	end
end
NState.Environment.NotorietyPoliceESPEnabled = NState.Environment.NotorietyPoliceESPEnabled == true
NState.Environment.NotorietyPoliceESPNames = NState.Environment.NotorietyPoliceESPNames ~= false
NState.Environment.NotorietyPoliceESPHealth = NState.Environment.NotorietyPoliceESPHealth ~= false
NState.Environment.NotorietyPoliceESPMaxDistance = math.clamp(tonumber(NState.Environment.NotorietyPoliceESPMaxDistance) or 2500, 0, 10000)
NState.Environment.NotorietyPoliceHeadScaleEnabled = NState.Environment.NotorietyPoliceHeadScaleEnabled == true
NState.Environment.NotorietyPoliceHeadScale = math.clamp(
	tonumber(NState.Environment.NotorietyPoliceHeadScale) or 10,
	1,
	20
)
NState.Environment.NotorietyEquipmentSpeedEnabled = NState.Environment.NotorietyEquipmentSpeedEnabled == true
NState.Environment.NotorietyEquipmentInstantEnabled = NState.Environment.NotorietyEquipmentInstantEnabled == true
NState.Environment.NotorietyEquipmentSpeedMultiplier = math.clamp(
	tonumber(NState.Environment.NotorietyEquipmentSpeedMultiplier) or 2,
	1,
	10
)
NState.Environment.NotorietyEquipmentRangeEnabled = NState.Environment.NotorietyEquipmentRangeEnabled == true
NState.Environment.NotorietyEquipmentPlacementRange = math.clamp(tonumber(NState.Environment.NotorietyEquipmentPlacementRange) or 10, 10, 100)
NState.Environment.NotorietyInfiniteEquipmentEnabled = NState.Environment.NotorietyInfiniteEquipmentEnabled == true
NState.Environment.NotorietyEquipmentPositionEnabled = NState.Environment.NotorietyEquipmentPositionEnabled == true
NState.Environment.NotorietyEquipmentPositionX = math.clamp(tonumber(NState.Environment.NotorietyEquipmentPositionX) or 0, -50, 50)
NState.Environment.NotorietyEquipmentPositionY = math.clamp(tonumber(NState.Environment.NotorietyEquipmentPositionY) or 0, -50, 50)
NState.Environment.NotorietyEquipmentPositionZ = math.clamp(tonumber(NState.Environment.NotorietyEquipmentPositionZ) or 0, -50, 50)
NState.Environment.NotorietyInfiniteYellMarkEnabled = NState.Environment.NotorietyInfiniteYellMarkEnabled == true
NState.Environment.NotorietyYellThroughWalls = NState.Environment.NotorietyYellThroughWalls ~= false
NState.Environment.NotorietyTeammateYellInfiniteRange = NState.Environment.NotorietyTeammateYellInfiniteRange ~= false
NState.Environment.NotorietyTeammateYellThroughWalls = NState.Environment.NotorietyTeammateYellThroughWalls ~= false
NState.Environment.NotorietyYellMarkMethod = tostring(NState.Environment.NotorietyYellMarkMethod or "Viewport")

if NState.Environment.NotorietyYellMarkMethod ~= "Viewport"
	and NState.Environment.NotorietyYellMarkMethod ~= "Whole Game"
	and NState.Environment.NotorietyYellMarkMethod ~= "Original"
then
	NState.Environment.NotorietyYellMarkMethod = "Viewport"
end

NState.Environment.NotorietyAutoYellEnabled = NState.Environment.NotorietyAutoYellEnabled == true
NState.Environment.NotorietyNoYellDelayEnabled = NState.Environment.NotorietyNoYellDelayEnabled == true
NState.Environment.NotorietyMusicVolume = math.clamp(tonumber(NState.Environment.NotorietyMusicVolume) or 100, 0, 100)
NState.Environment.NotorietyMusicTrack = tostring(NState.Environment.NotorietyMusicTrack or "Game Selection")
NState.Environment.NotorietyMusicMode = tostring(NState.Environment.NotorietyMusicMode or "Follow Game")
NState.Environment.NotorietySFXVolume = math.clamp(tonumber(NState.Environment.NotorietySFXVolume) or 100, 0, 100)
NState.Environment.NotorietyLocalGunshotsVolume = math.clamp(tonumber(NState.Environment.NotorietyLocalGunshotsVolume) or 100, 0, 100)
NState.Environment.NotorietyGunshotsVolume = math.clamp(tonumber(NState.Environment.NotorietyGunshotsVolume) or 100, 0, 100)
NState.Environment.NotorietyMapAmbienceVolume = math.clamp(tonumber(NState.Environment.NotorietyMapAmbienceVolume) or 100, 0, 100)
NState.Environment.NotorietyVoicesVolume = math.clamp(tonumber(NState.Environment.NotorietyVoicesVolume) or 100, 0, 100)
NState.Environment.NotorietyUIVolume = math.clamp(tonumber(NState.Environment.NotorietyUIVolume) or 100, 0, 100)

if NState.Environment.NotorietyEquipmentSpeedMultiplier <= 0
	or NState.Environment.NotorietyEquipmentSpeedMultiplier == math.huge
	or NState.Environment.NotorietyEquipmentSpeedMultiplier ~= NState.Environment.NotorietyEquipmentSpeedMultiplier
then
	NState.Environment.NotorietyEquipmentSpeedMultiplier = 2
end

if NState.Environment.NotorietyAccuracy ~= NState.Environment.NotorietyAccuracy
	or NState.Environment.NotorietyAccuracy == math.huge
	or NState.Environment.NotorietyAccuracy == -math.huge
then
	NState.Environment.NotorietyAccuracy = 100
else
	NState.Environment.NotorietyAccuracy = math.clamp(NState.Environment.NotorietyAccuracy, 0, 100)
end

NState.Environment.NotorietyWeaponConnections = {}
NState.Environment.NotorietyUIConnections = {}
NState.Environment.NotorietyUnloaded = false

NState.EquipmentSpeedState = {
	Refresh = 0,
}

NState.EquipmentPlacementState = {
	HookInstalled = false,
	Target = nil,
	Original = nil,
	Active = false,
}

NState.getEquipmentPositionOffset = function()
	local X = tonumber(NState.Environment.NotorietyEquipmentPositionX) or 0
	local Y = tonumber(NState.Environment.NotorietyEquipmentPositionY) or 0
	local Z = tonumber(NState.Environment.NotorietyEquipmentPositionZ) or 0

	if X == math.huge or X == -math.huge or X ~= X then X = 0 end
	if Y == math.huge or Y == -math.huge or Y ~= Y then Y = 0 end
	if Z == math.huge or Z == -math.huge or Z ~= Z then Z = 0 end

	return X, Y, Z
end

NState.getEquipmentSpeedMultiplier = function()
	if NState.Environment.NotorietyEquipmentInstantEnabled then
		return math.huge
	end

	if not NState.Environment.NotorietyEquipmentSpeedEnabled then
		return 1
	end

	local Multiplier = tonumber(NState.Environment.NotorietyEquipmentSpeedMultiplier) or 2
	if Multiplier <= 0 or Multiplier == math.huge or Multiplier ~= Multiplier then
		Multiplier = 2
		NState.Environment.NotorietyEquipmentSpeedMultiplier = Multiplier
	end

	return Multiplier
end

NState.shouldOverrideEquipmentPlacement = function()
	return not NState.Environment.NotorietyUnloaded and (
		NState.Environment.NotorietyEquipmentInstantEnabled
		or NState.Environment.NotorietyEquipmentSpeedEnabled
		or NState.Environment.NotorietyEquipmentRangeEnabled
		or NState.Environment.NotorietyEquipmentPositionEnabled
	)
end

NState.getEquipmentInputKeys = function()
	local PlayerData = NState.ReplicatedStorage:FindFirstChild("PlayerData")
	local DataFolder = PlayerData and PlayerData:FindFirstChild(NState.LocalPlayer.Name)
	local Data = DataFolder and DataFolder:FindFirstChild(NState.LocalPlayer.Name .. "'s Data")
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

NState.isNativeEquipmentInputHeld = function(IsMobile)
	if IsMobile then
		return true
	end

	local KeyboardKey, ControllerKey = NState.getEquipmentInputKeys()
	if KeyboardKey and NState.UserInputService:IsKeyDown(KeyboardKey) then
		return true
	end

	if ControllerKey then
		for Index = 1, 8 do
			local GamepadType = Enum.UserInputType["Gamepad" .. Index]
			if GamepadType then
				local Success, Held = pcall(
					NState.UserInputService.IsGamepadButtonDown,
					NState.UserInputService,
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

NState.readFunctionUpvalue = function(Function, Index)
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

NState.writeFunctionUpvalue = function(Function, Index, Value)
	if type(debug) ~= "table" or type(debug.setupvalue) ~= "function" then
		return false
	end

	return pcall(debug.setupvalue, Function, Index, Value)
end

NState.findNativePlaceEquipment = function()
	if type(NState.EquipmentPlacementState.Target) == "function" then
		return NState.EquipmentPlacementState.Target
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
				NState.EquipmentPlacementState.Target = Function
				return Function
			end
		end
	end

	return nil
end

NState.runNativeEquipmentPlacement = function(Original, IsMobile)
	if NState.EquipmentPlacementState.Active then
		return
	end

	local Preview = NState.readFunctionUpvalue(Original, 2)
	local EquipmentName = NState.readFunctionUpvalue(Original, 3)
	local HasSkill = NState.readFunctionUpvalue(Original, 4)
	local Humanoid = NState.readFunctionUpvalue(Original, 6)
	local MainGui = NState.readFunctionUpvalue(Original, 7)
	local UseCenter = NState.readFunctionUpvalue(Original, 8)
	local Mouse = NState.readFunctionUpvalue(Original, 9)
	local CurrentCamera = NState.readFunctionUpvalue(Original, 10)
	local ColorEquipment = NState.readFunctionUpvalue(Original, 11)
	local EquipmentColors = NState.readFunctionUpvalue(Original, 12)
	local Remotes = NState.readFunctionUpvalue(Original, 13)

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

	NState.EquipmentPlacementState.Active = true
	NState.writeFunctionUpvalue(Original, 1, true)

	local function IsStillActive()
		local NativeFlag = NState.readFunctionUpvalue(Original, 1)
		if NativeFlag == false then
			return false
		end

		if not IsMobile and not NState.isNativeEquipmentInputHeld(false) then
			return false
		end

		return true
	end

	local Success, ErrorMessage = xpcall(function()
		task.wait(IsMobile and 0 or 0.5)

		if not IsStillActive() then
			return
		end

		local PlayerGui = NState.LocalPlayer:FindFirstChildOfClass("PlayerGui")
		local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
		local RuntimeMainGui = SGPackage and SGPackage:FindFirstChild("MainGui")
		local Interaction = RuntimeMainGui and RuntimeMainGui:FindFirstChild("Interaction")
		local EquipmentPercent = Interaction and Interaction:FindFirstChild("EquipmentPercent")

		if not EquipmentPercent or not EquipmentPercent:IsA("TextLabel") then
			return Original(IsMobile)
		end

		Preview.Parent = NState.Workspace

		local Duration = 2
		if EquipmentName == "Medical Kit" and HasSkill("Mastermind", "j") then
			Duration /= 2
		elseif EquipmentName == "Ammo Bag" and HasSkill("Enforcer", "b") then
			Duration /= 2
		end

		if HasSkill("Technician", "n") then
			Duration /= 2
		end

		local Multiplier = NState.getEquipmentSpeedMultiplier()
		if Multiplier == math.huge then
			Duration = 0
		else
			Duration /= Multiplier
		end

		local Ignore = {
			Preview,
			NState.Workspace.CurrentCamera,
			NState.Workspace:FindFirstChild("Police"),
			NState.Workspace:FindFirstChild("Criminals"),
			NState.Workspace:FindFirstChild("Citizens"),
			NState.Workspace:FindFirstChild("InvisibleParts"),
			NState.Workspace:FindFirstChild("Lootables"),
			NState.Workspace:FindFirstChild("Bags"),
			NState.Workspace:FindFirstChild("Bodies"),
			NState.Workspace:FindFirstChild("Tracers"),
			NState.Workspace:FindFirstChild("ShatteredGlass"),
			NState.Workspace:FindFirstChild("MapZones"),
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
			if NState.Environment.NotorietyUnloaded
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
			local Range = NState.Environment.NotorietyEquipmentRangeEnabled
				and math.clamp(tonumber(NState.Environment.NotorietyEquipmentPlacementRange) or 10, 10, 100)
				or 10

			local HitPosition
			local HitNormal
			HitPart, HitPosition, HitNormal = NState.Workspace:FindPartOnRayWithIgnoreList(
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
					local GroundPart, GroundPosition = NState.Workspace:FindPartOnRayWithIgnoreList(
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

				if PlacementCFrame and NState.Environment.NotorietyEquipmentPositionEnabled then
					local X, Y, Z = NState.getEquipmentPositionOffset()
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

		NState.writeFunctionUpvalue(Original, 1, false)
		Preview.Parent = nil
	end, debug.traceback)

	NState.writeFunctionUpvalue(Original, 1, false)

	if typeof(Preview) == "Instance" then
		pcall(function()
			Preview.Parent = nil
		end)
	end

	NState.EquipmentPlacementState.Active = false

	if not Success then
		warn("[Notoriety Equipment] " .. tostring(ErrorMessage))
	end
end

NState.installEquipmentPlacementHook = function()
	if NState.EquipmentPlacementState.HookInstalled
		and type(NState.EquipmentPlacementState.Original) == "function"
	then
		return true
	end

	if type(hookfunction) ~= "function" then
		return false
	end

	local Target = NState.findNativePlaceEquipment()
	if type(Target) ~= "function" then
		return false
	end

	local Original
	local function Wrapped(IsMobile, ...)
		if not NState.shouldOverrideEquipmentPlacement() then
			return Original(IsMobile, ...)
		end

		return NState.runNativeEquipmentPlacement(Original, IsMobile)
	end

	local Success, Result = pcall(hookfunction, Target, Wrapped)
	if not Success or type(Result) ~= "function" then
		return false
	end

	Original = Result
	NState.EquipmentPlacementState.Target = Target
	NState.EquipmentPlacementState.Original = Result
	NState.EquipmentPlacementState.HookInstalled = true
	return true
end

NState.restoreEquipmentPlacementSpeed = function()
	NState.EquipmentPlacementState.Active = false

	if NState.EquipmentPlacementState.HookInstalled
		and type(NState.EquipmentPlacementState.Target) == "function"
		and type(NState.EquipmentPlacementState.Original) == "function"
		and type(hookfunction) == "function"
	then
		pcall(hookfunction, NState.EquipmentPlacementState.Target, NState.EquipmentPlacementState.Original)
	end

	NState.EquipmentPlacementState.HookInstalled = false
	NState.EquipmentPlacementState.Target = nil
	NState.EquipmentPlacementState.Original = nil
end

NState.applyEquipmentPlacementSpeed = function()
	return NState.installEquipmentPlacementHook()
end

NState.applyEquipmentPositioning = function()
	return NState.installEquipmentPlacementHook()
end

NState.applyEquipmentPlacementRange = function()
	return NState.installEquipmentPlacementHook()
end

NState.restoreMobileEquipmentPlacementFix = function()
end

NState.applyMobileEquipmentPlacementFix = function()
	return NState.installEquipmentPlacementHook()
end

NState.PersistentAudioOriginalVolumes = rawget(NState.Environment, "NotorietyAudioOriginalVolumes")
if type(NState.PersistentAudioOriginalVolumes) ~= "table" then
	NState.PersistentAudioOriginalVolumes = setmetatable({}, { __mode = "k" })
	NState.Environment.NotorietyAudioOriginalVolumes = NState.PersistentAudioOriginalVolumes
end

NState.PersistentAudioGroupVolumes = rawget(NState.Environment, "NotorietyAudioGroupVolumes")
if type(NState.PersistentAudioGroupVolumes) ~= "table" then
	NState.PersistentAudioGroupVolumes = setmetatable({}, { __mode = "k" })
	NState.Environment.NotorietyAudioGroupVolumes = NState.PersistentAudioGroupVolumes
end

NState.AudioState = {
	Groups = {},
	OriginalVolumes = NState.PersistentAudioGroupVolumes,
	DirectOriginalVolumes = NState.PersistentAudioOriginalVolumes,
	RootConnections = {},
	Applying = false,
	ScanGeneration = 0,
}

NState.addAudioGroup = function(Key, Group)
	if typeof(Group) ~= "Instance" or not Group:IsA("SoundGroup") then
		return
	end

	NState.AudioState.Groups[Key] = NState.AudioState.Groups[Key] or {}
	if not table.find(NState.AudioState.Groups[Key], Group) then
		table.insert(NState.AudioState.Groups[Key], Group)
	end
	if NState.AudioState.OriginalVolumes[Group] == nil then
		NState.AudioState.OriginalVolumes[Group] = Group.Volume
	end
end

NState.resolveAudioGroups = function()
	table.clear(NState.AudioState.Groups)
	local SoundPackage = NState.SoundService:FindFirstChild("Sound_Package")
	local GlobalSounds = SoundPackage and SoundPackage:FindFirstChild("GlobalSounds")
	local GameAudio = GlobalSounds and GlobalSounds:FindFirstChild("GameAudio")
	local SFX = GameAudio and GameAudio:FindFirstChild("SFX")
	local GlobalVolume = NState.SoundService:FindFirstChild("GlobalVolume")

	NState.addAudioGroup("Music", GlobalSounds and GlobalSounds:FindFirstChild("Music"))
	NState.addAudioGroup("SFX", SFX)
	NState.addAudioGroup("SFXSibling", GameAudio and GameAudio:FindFirstChild("CueSFX"))
	NState.addAudioGroup("SFXSibling", GameAudio and GameAudio:FindFirstChild("SubtleCueSFX"))
	NState.addAudioGroup("LocalGunshots", SFX and SFX:FindFirstChild("LocalGunshots"))
	NState.addAudioGroup("Gunshots", SFX and SFX:FindFirstChild("Gunshots"))
	NState.addAudioGroup("MapAmbience", SFX and SFX:FindFirstChild("MapAmbience"))
	NState.addAudioGroup("Voices", GameAudio and GameAudio:FindFirstChild("Voices"))
	NState.addAudioGroup("Voices", GameAudio and GameAudio:FindFirstChild("NarratorVoice"))
	NState.addAudioGroup("Voices", GlobalVolume and GlobalVolume:FindFirstChild("Voices"))
	NState.addAudioGroup("UI", GlobalSounds and GlobalSounds:FindFirstChild("UI"))
end

NState.soundUsesManagedGroup = function(Sound)
	local Group = Sound.SoundGroup
	if not Group then return false end

	for _, Groups in pairs(NState.AudioState.Groups) do
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

NState.isGunshotSound = function(Sound)
	local Name = string.lower(Sound.Name)
	local ParentName = Sound.Parent and string.lower(Sound.Parent.Name) or ""
	return ParentName:find("muzzle", 1, true) ~= nil
		or Name:find("gunshot", 1, true) ~= nil
		or Name:find("gunfire", 1, true) ~= nil
		or Name == "fire"
		or Name == "firesound"
		or Name:find("suppressedsound", 1, true) ~= nil
end

NState.isLocalGunshotSound = function(Sound)
	if not NState.isGunshotSound(Sound) then return false end
	local Camera = NState.Workspace.CurrentCamera
	local CameraModel = Camera and Camera:FindFirstChild("CameraModel")
	local Character = NState.LocalPlayer.Character
	return (CameraModel and Sound:IsDescendantOf(CameraModel))
		or (Character and Sound:IsDescendantOf(Character))
end

NState.isVoiceSound = function(Sound)
	local Camera = NState.Workspace.CurrentCamera
	local AudioFolder = Camera and Camera:FindFirstChild("AudioFolder")
	local PlayerGui = NState.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
	local Voices = SGPackage and SGPackage:FindFirstChild("Voices")
	local CharVoice = SGPackage and SGPackage:FindFirstChild("CharVoice")
	return (AudioFolder and Sound:IsDescendantOf(AudioFolder))
		or (Voices and Sound:IsDescendantOf(Voices))
		or Sound == CharVoice
end

NState.isMapAmbienceSound = function(Sound)
	local Map = NState.Workspace:FindFirstChild("Map")
	return Map ~= nil and Sound:IsDescendantOf(Map) and not NState.isGunshotSound(Sound)
end

NState.isUISound = function(Sound)
	local PlayerGui = NState.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not PlayerGui or not Sound:IsDescendantOf(PlayerGui) or NState.isVoiceSound(Sound) then
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

NState.isGeneralSFXSound = function(Sound)
	local PlayerGui = NState.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
	local SFX = SGPackage and SGPackage:FindFirstChild("SFX")
	return SFX ~= nil and Sound:IsDescendantOf(SFX)
end

NState.getDirectAudioPercent = function(Sound)
	if NState.Environment.NotorietyUnloaded
		or typeof(Sound) ~= "Instance"
		or not Sound:IsA("Sound")
		or Sound.Parent == nil
		or NState.soundUsesManagedGroup(Sound)
	then
		return nil
	end

	if NState.isVoiceSound(Sound) then
		return math.clamp(tonumber(NState.Environment.NotorietyVoicesVolume) or 100, 0, 100) / 100
	end

	local SFX = math.clamp(tonumber(NState.Environment.NotorietySFXVolume) or 100, 0, 100) / 100

	if NState.isGunshotSound(Sound) then
		local Gun = if NState.isLocalGunshotSound(Sound)
			then math.clamp(tonumber(NState.Environment.NotorietyLocalGunshotsVolume) or 100, 0, 100) / 100
			else math.clamp(tonumber(NState.Environment.NotorietyGunshotsVolume) or 100, 0, 100) / 100
		return SFX * Gun
	end

	if NState.isMapAmbienceSound(Sound) then
		return SFX * (math.clamp(tonumber(NState.Environment.NotorietyMapAmbienceVolume) or 100, 0, 100) / 100)
	end

	if NState.isUISound(Sound) then
		return SFX * (math.clamp(tonumber(NState.Environment.NotorietyUIVolume) or 100, 0, 100) / 100)
	end

	if NState.isGeneralSFXSound(Sound) then
		return SFX
	end

	return nil
end

NState.getLegacyV5DirectAudioPercent = function(Sound)
	if typeof(Sound) ~= "Instance" or not Sound:IsA("Sound") or Sound.Parent == nil or NState.soundUsesManagedGroup(Sound) then
		return nil
	end

	if NState.isVoiceSound(Sound) then
		return math.clamp(tonumber(NState.Environment.NotorietyVoicesVolume) or 100, 0, 100) / 100
	end

	local SFX = math.clamp(tonumber(NState.Environment.NotorietySFXVolume) or 100, 0, 100) / 100
	if NState.isGunshotSound(Sound) then
		local Gun = if NState.isLocalGunshotSound(Sound)
			then math.clamp(tonumber(NState.Environment.NotorietyLocalGunshotsVolume) or 100, 0, 100) / 100
			else math.clamp(tonumber(NState.Environment.NotorietyGunshotsVolume) or 100, 0, 100) / 100
		return SFX * Gun
	end

	if NState.isMapAmbienceSound(Sound) then
		return SFX * (math.clamp(tonumber(NState.Environment.NotorietyMapAmbienceVolume) or 100, 0, 100) / 100)
	end

	local PlayerGui = NState.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
	local MainGui = SGPackage and SGPackage:FindFirstChild("MainGui")
	local RankUp = SGPackage and SGPackage:FindFirstChild("RankUp")
	if (MainGui and Sound:IsDescendantOf(MainGui)) or (RankUp and Sound:IsDescendantOf(RankUp)) then
		return SFX * (math.clamp(tonumber(NState.Environment.NotorietyUIVolume) or 100, 0, 100) / 100)
	end

	if NState.isGeneralSFXSound(Sound) then
		return SFX
	end

	return nil
end

NState.applyDirectAudioVolume = function(Sound)
	local Percent = NState.getDirectAudioPercent(Sound)
	if Percent == nil then return false end

	if NState.AudioState.DirectOriginalVolumes[Sound] == nil then
		local BaseVolume = Sound.Volume

		if NState.Environment.NotorietyAudioMigrateFromV5Double == true then
			local LegacyPercent = NState.getLegacyV5DirectAudioPercent(Sound)
			local CurrentPercent = NState.getDirectAudioPercent(Sound)
			local Combined = type(LegacyPercent) == "number" and type(CurrentPercent) == "number"
				and LegacyPercent * CurrentPercent or nil
			if type(Combined) == "number" and Combined > 0.000001 then
				BaseVolume /= Combined
			end
		elseif NState.Environment.NotorietyAudioMigrateFromV5 == true then
			local LegacyPercent = NState.getLegacyV5DirectAudioPercent(Sound)
			if type(LegacyPercent) == "number" and LegacyPercent > 0.000001 then
				BaseVolume /= LegacyPercent
			end
		end

		NState.AudioState.DirectOriginalVolumes[Sound] = BaseVolume
	end

	local Base = NState.AudioState.DirectOriginalVolumes[Sound]
	local Target = Base * Percent
	if math.abs(Sound.Volume - Target) > 0.0001 then
		Sound.Volume = Target
	end
	return true
end

NState.getSafeAudioRoots = function()
	local Roots = {}
	local PlayerGui = NState.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local Camera = NState.Workspace.CurrentCamera
	for _, Root in {
		PlayerGui,
		NState.Workspace:FindFirstChild("Map"),
		NState.Workspace:FindFirstChild("Police"),
		NState.Workspace:FindFirstChild("Criminals"),
		Camera,
		NState.LocalPlayer.Character,
	} do
		if Root then table.insert(Roots, Root) end
	end
	return Roots
end

NState.scanSafeAudioRoots = function()
	NState.AudioState.ScanGeneration += 1
	local Generation = NState.AudioState.ScanGeneration

	task.spawn(function()
		local Queue = NState.getSafeAudioRoots()
		local Index = 1
		local Visited = 0

		while Index <= #Queue and Generation == NState.AudioState.ScanGeneration and not NState.Environment.NotorietyUnloaded do
			local Object = Queue[Index]
			Index += 1

			if typeof(Object) == "Instance" and Object.Parent ~= nil then
				if Object:IsA("Sound") then
					NState.applyDirectAudioVolume(Object)
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

		if Generation == NState.AudioState.ScanGeneration then
			NState.Environment.NotorietyAudioMigrateFromV5 = nil
			NState.Environment.NotorietyAudioMigrateFromV5Double = nil
		end
	end)
end

NState.ensureSafeAudioWatchers = function()
	if #NState.AudioState.RootConnections > 0 then return end

	for _, Root in NState.getSafeAudioRoots() do
		table.insert(NState.AudioState.RootConnections, Root.DescendantAdded:Connect(function(Descendant)
			if not NState.Environment.NotorietyUnloaded and Descendant:IsA("Sound") then
				task.defer(NState.applyDirectAudioVolume, Descendant)
			end
		end))
	end
end

NState.setAudioGroups = function(Groups, Volume)
	for _, Group in Groups or {} do
		if Group.Parent then
			Group.Volume = Volume
		end
	end
end

NState.applyAudioVolumes = function()
	if NState.Environment.NotorietyUnloaded or NState.AudioState.Applying then return end
	NState.AudioState.Applying = true
	NState.resolveAudioGroups()
	NState.ensureSafeAudioWatchers()

	local Music = math.clamp(tonumber(NState.Environment.NotorietyMusicVolume) or 100, 0, 100) / 100
	local SFX = math.clamp(tonumber(NState.Environment.NotorietySFXVolume) or 100, 0, 100) / 100
	local LocalGunshots = math.clamp(tonumber(NState.Environment.NotorietyLocalGunshotsVolume) or 100, 0, 100) / 100
	local Gunshots = math.clamp(tonumber(NState.Environment.NotorietyGunshotsVolume) or 100, 0, 100) / 100
	local MapAmbience = math.clamp(tonumber(NState.Environment.NotorietyMapAmbienceVolume) or 100, 0, 100) / 100
	local Voices = math.clamp(tonumber(NState.Environment.NotorietyVoicesVolume) or 100, 0, 100) / 100
	local UI = math.clamp(tonumber(NState.Environment.NotorietyUIVolume) or 100, 0, 100) / 100

	NState.setAudioGroups(NState.AudioState.Groups.Music, Music)
	NState.setAudioGroups(NState.AudioState.Groups.SFX, SFX)
	NState.setAudioGroups(NState.AudioState.Groups.SFXSibling, SFX)
	NState.setAudioGroups(NState.AudioState.Groups.LocalGunshots, LocalGunshots)
	NState.setAudioGroups(NState.AudioState.Groups.Gunshots, Gunshots)
	NState.setAudioGroups(NState.AudioState.Groups.MapAmbience, MapAmbience)
	NState.setAudioGroups(NState.AudioState.Groups.Voices, Voices)
	NState.setAudioGroups(NState.AudioState.Groups.UI, SFX * UI)

	NState.scanSafeAudioRoots()
	NState.AudioState.Applying = false
end

NState.restoreAudioVolumes = function()
	for _, Connection in NState.AudioState.RootConnections do
		pcall(function() Connection:Disconnect() end)
	end
	table.clear(NState.AudioState.RootConnections)

	for Sound, Volume in NState.AudioState.DirectOriginalVolumes do
		if typeof(Sound) == "Instance" and Sound.Parent ~= nil and type(Volume) == "number" then
			pcall(function() Sound.Volume = Volume end)
		end
	end

	for Group, Volume in NState.AudioState.OriginalVolumes do
		if typeof(Group) == "Instance" and Group.Parent ~= nil then
			pcall(function() Group.Volume = Volume end)
		end
	end

	table.clear(NState.AudioState.Groups)
	NState.AudioState.ScanGeneration += 1
	NState.AudioState.Applying = false
end


NState.YellPatchState = {
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
	NoDelayConnections = NState.Environment.NotorietyNoDelayConnections,
	TargetParts = setmetatable({}, {
		__mode = "k",
	}),
	SkillCache = {},
}

NState.getYellModule = function()
	local ReplicatedScripts = NState.RS_Package:FindFirstChild("ReplicatedScripts")
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

NState.isPartInViewport = function(Part, Camera)
	if not Part or not Part:IsA("BasePart") then
		return false
	end

	Camera = Camera or NState.Workspace.CurrentCamera

	if not Camera then
		return false
	end

	local ViewportPoint, OnScreen = Camera:WorldToViewportPoint(Part.Position)
	return OnScreen and ViewportPoint.Z > 0
end

NState.hasYellSkill = function(PlayerName, TreeName, Skill)
	local CacheKey = PlayerName .. "|" .. TreeName .. "|" .. Skill
	local Cached = NState.YellPatchState.SkillCache[CacheKey]

	if Cached ~= nil then
		return Cached
	end

	local PlayerData = NState.ReplicatedStorage:FindFirstChild("PlayerData")
	local PlayerFolder = PlayerData and PlayerData:FindFirstChild(PlayerName)
	local Data = PlayerFolder and PlayerFolder:FindFirstChild(PlayerName .. "'s Data")
	local SkillTree = Data and Data:FindFirstChild("SkillTree")
	local Tree = SkillTree and SkillTree:FindFirstChild(TreeName .. "Tree")
	local Result = Tree ~= nil
		and type(Tree.Value) == "string"
		and string.find(Tree.Value, Skill, 1, true) ~= nil

	NState.YellPatchState.SkillCache[CacheKey] = Result == true
	return Result == true
end

NState.getYellTargetPart = function(Object)
	if not Object then
		return nil
	end

	local Cached = NState.YellPatchState.TargetParts[Object]

	if Cached and Cached.Parent then
		return Cached
	end

	if Object:IsA("BasePart") then
		NState.YellPatchState.TargetParts[Object] = Object
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
		NState.YellPatchState.TargetParts[Object] = Part
		return Part
	end

	return nil
end

NState.canYellSeeTarget = function(Actor, TargetPart, Camera)
	if not Actor or not TargetPart then
		return false
	end

	Camera = Camera or NState.Workspace.CurrentCamera

	local OriginCFrame

	if Actor == NState.LocalPlayer.Character and Camera then
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
		NState.Workspace:FindFirstChild("Tracers"),
		NState.Workspace:FindFirstChild("Bodies"),
		NState.Workspace:FindFirstChild("InvisibleParts"),
		NState.Workspace:FindFirstChild("MapZones"),
		NState.Workspace:FindFirstChild("NonPoliceObjectives"),
		NState.Workspace:FindFirstChild("Bags"),
	}
	local FilteredIgnore = {}

	for _, Object in Ignore do
		if Object then
			table.insert(FilteredIgnore, Object)
		end
	end

	local Hit, HitPosition = NState.Workspace:FindPartOnRayWithIgnoreList(
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

NState.shouldIncludeYellTarget = function(Actor, TargetPart, Camera)
	if not TargetPart then
		return false
	end

	local Method = NState.Environment.NotorietyYellMarkMethod

	if Method == "Viewport" and not NState.isPartInViewport(TargetPart, Camera) then
		return false
	end

	if Method ~= "Viewport" and Method ~= "Whole Game" then
		return false
	end

	if NState.Environment.NotorietyYellThroughWalls then
		return true
	end

	return NState.canYellSeeTarget(Actor, TargetPart, Camera)
end

NState.shouldIncludeTeammateYellTarget = function(Actor, TargetPart, Camera)
	if not TargetPart then
		return false
	end

	local Method = NState.Environment.NotorietyYellMarkMethod

	if Method == "Viewport" and not NState.isPartInViewport(TargetPart, Camera) then
		return false
	end

	if Method ~= "Viewport" and Method ~= "Whole Game" then
		return false
	end

	local OriginPart = Actor:FindFirstChild("HumanoidRootPart") or Actor.PrimaryPart

	if not NState.Environment.NotorietyTeammateYellInfiniteRange
		and OriginPart
		and (TargetPart.Position - OriginPart.Position).Magnitude > 100
	then
		return false
	end

	if NState.Environment.NotorietyTeammateYellThroughWalls then
		return true
	end

	return NState.canYellSeeTarget(Actor, TargetPart, Camera)
end

NState.createYellMarkWrapper = function()
	return function(_, Actor, _, MarkOnly, AutoMode)
		local IsPlayer = typeof(Actor) == "Instance" and Actor:IsA("Player")

		if IsPlayer then
			Actor = Actor.Character
		end

		if typeof(Actor) ~= "Instance" or not Actor:IsA("Model") then
			return 0, false
		end

		local Camera = NState.Workspace.CurrentCamera

		if not Camera then
			return 0, false
		end

		local Targets = {}
		local YellTier = 0
		local GameStatus = NState.RS_Package:FindFirstChild("ReplicatedGameStatus")
		local Caught = GameStatus and GameStatus:FindFirstChild("Caught")
		local IsCaught = Caught and Caught.Value == true

		if not MarkOnly then
			local Citizens = NState.Workspace:FindFirstChild("Citizens")

			if Citizens then
				for _, Citizen in Citizens:GetChildren() do
					local TargetPart = NState.getYellTargetPart(Citizen)

					if TargetPart and NState.shouldIncludeYellTarget(Actor, TargetPart, Camera) then
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
			local Cameras = NState.Workspace:FindFirstChild("Cameras")

			if Cameras then
				for _, CameraObject in Cameras:GetChildren() do
					local TargetPart = NState.getYellTargetPart(CameraObject)

					if TargetPart and NState.shouldIncludeYellTarget(Actor, TargetPart, Camera) then
						table.insert(Targets, CameraObject)
						YellTier = 2
					end
				end
			end
		end

		if not MarkOnly then
			local Criminals = NState.Workspace:FindFirstChild("Criminals")

			if Criminals then
				local CanBoost = NState.hasYellSkill(Actor.Name, "Mastermind", "k")
				local CanInspire = NState.hasYellSkill(Actor.Name, "Mastermind", "s")
				local ForceFollowTarget

				for _, Criminal in Criminals:GetChildren() do
					if Criminal ~= Actor then
						local TargetPart = NState.getYellTargetPart(Criminal)

						if TargetPart and NState.shouldIncludeTeammateYellTarget(Actor, TargetPart, Camera) then
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

		local Police = NState.Workspace:FindFirstChild("Police")

		if Police then
			for _, Officer in Police:GetChildren() do
				local TargetPart = NState.getYellTargetPart(Officer)

				if TargetPart and NState.shouldIncludeYellTarget(Actor, TargetPart, Camera) then
					table.insert(Targets, Officer)
					YellTier = math.max(YellTier, 4)
				end
			end
		end

		if AutoMode then
			NState.YellPatchState.AutoGeneration += 1
			local Generation = NState.YellPatchState.AutoGeneration
			local HasNewTarget = false

			for _, Target in Targets do
				if NState.YellPatchState.AutoSeen[Target] == nil then
					HasNewTarget = true
				end

				NState.YellPatchState.AutoSeen[Target] = Generation
			end

			for Target, SeenGeneration in NState.YellPatchState.AutoSeen do
				if SeenGeneration ~= Generation then
					NState.YellPatchState.AutoSeen[Target] = nil
				end
			end

			if #Targets == 0 then
				return YellTier, false
			end

			if not HasNewTarget and os.clock() - NState.YellPatchState.AutoLastFire < 2 then
				return YellTier, false
			end
		end

		if IsPlayer and #Targets > 0 then
			local YellRemotes = NState.RS_Package:FindFirstChild("Remotes")
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
			local YellRemotes = NState.RS_Package:FindFirstChild("Remotes")
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
			NState.YellPatchState.AutoLastFire = os.clock()
		end

		return YellTier, #Targets > 0
	end
end

NState.restoreYellMarkPatch = function()
	local Module = NState.YellPatchState.Module
	local Original = NState.YellPatchState.Original
	local Wrapper = NState.YellPatchState.Wrapper

	if type(Module) == "table"
		and type(Original) == "function"
		and Module.Yell == Wrapper
	then
		Module.Yell = Original
	end

	NState.YellPatchState.Module = nil
	NState.YellPatchState.Original = nil
	NState.YellPatchState.Wrapper = nil
end

NState.applyYellMarkPatch = function()
	if NState.Environment.NotorietyUnloaded or not NState.Environment.NotorietyInfiniteYellMarkEnabled then
		return false
	end

	if NState.Environment.NotorietyYellMarkMethod == "Original" then
		NState.restoreYellMarkPatch()
		return true
	end

	local Module = NState.getYellModule()

	if not Module then
		return false
	end

	if NState.YellPatchState.Module == Module
		and type(NState.YellPatchState.Wrapper) == "function"
		and Module.Yell == NState.YellPatchState.Wrapper
	then
		return true
	end

	NState.restoreYellMarkPatch()

	local Original = Module.Yell

	if type(Original) ~= "function" then
		return false
	end

	local Wrapper = NState.createYellMarkWrapper()
	NState.YellPatchState.Module = Module
	NState.YellPatchState.Original = Original
	NState.YellPatchState.Wrapper = Wrapper
	Module.Yell = Wrapper

	return Module.Yell == Wrapper
end

NState.setYellMarkPatchEnabled = function(Enabled)
	NState.Environment.NotorietyInfiniteYellMarkEnabled = Enabled == true

	if NState.Environment.NotorietyInfiniteYellMarkEnabled then
		NState.applyYellMarkPatch()
	else
		NState.restoreYellMarkPatch()
	end
end

NState.setYellMarkMethod = function(Method)
	Method = tostring(Method)

	if Method ~= "Viewport" and Method ~= "Whole Game" and Method ~= "Original" then
		Method = "Viewport"
	end

	NState.Environment.NotorietyYellMarkMethod = Method
	NState.YellPatchState.AutoGeneration = 0
	NState.YellPatchState.AutoLastFire = 0
	table.clear(NState.YellPatchState.AutoSeen)

	if NState.Environment.NotorietyInfiniteYellMarkEnabled then
		NState.applyYellMarkPatch()
	elseif Method == "Original" then
		NState.restoreYellMarkPatch()
	end
end

NState.setYellThroughWalls = function(Enabled)
	NState.Environment.NotorietyYellThroughWalls = Enabled == true
	NState.YellPatchState.AutoGeneration = 0
	NState.YellPatchState.AutoLastFire = 0
	table.clear(NState.YellPatchState.AutoSeen)
end

NState.setTeammateYellInfiniteRange = function(Enabled)
	NState.Environment.NotorietyTeammateYellInfiniteRange = Enabled == true
	NState.YellPatchState.AutoGeneration = 0
	NState.YellPatchState.AutoLastFire = 0
	table.clear(NState.YellPatchState.AutoSeen)
end

NState.setTeammateYellThroughWalls = function(Enabled)
	NState.Environment.NotorietyTeammateYellThroughWalls = Enabled == true
	NState.YellPatchState.AutoGeneration = 0
	NState.YellPatchState.AutoLastFire = 0
	table.clear(NState.YellPatchState.AutoSeen)
end

NState.YellPatchState.RefreshNoDelayTargets = function()
	table.clear(NState.YellPatchState.NoDelayTargets)

	if type(getgc) ~= "function"
		or type(debug) ~= "table"
		or type(debug.getupvalues) ~= "function"
		or type(debug.setupvalue) ~= "function"
	then
		return false
	end

	local Module = NState.getYellModule()

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
							table.insert(NState.YellPatchState.NoDelayTargets, {
								Function = Function,
								Index = DebounceIndex,
							})
						end
					end
				end
			end
		end
	end

	return #NState.YellPatchState.NoDelayTargets > 0
end

NState.YellPatchState.ApplyNoDelay = function()
	if NState.Environment.NotorietyUnloaded or not NState.Environment.NotorietyNoYellDelayEnabled then
		return false
	end

	if #NState.YellPatchState.NoDelayTargets == 0 then
		NState.YellPatchState.RefreshNoDelayTargets()
	end

	local Patched = false

	for _, Target in NState.YellPatchState.NoDelayTargets do
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

NState.YellPatchState.ClearNoDelayConnections = function()
	for _, Connection in NState.YellPatchState.NoDelayConnections do
		pcall(function()
			Connection:Disconnect()
		end)
	end

	table.clear(NState.YellPatchState.NoDelayConnections)
end

NState.YellPatchState.ConnectNoDelaySignals = function()
	NState.YellPatchState.ClearNoDelayConnections()

	if NState.Environment.NotorietyUnloaded or not NState.Environment.NotorietyNoYellDelayEnabled then
		return
	end

	local function ResetDebounce()
		if not NState.Environment.NotorietyNoYellDelayEnabled then
			return
		end

		NState.YellPatchState.ApplyNoDelay()
		task.defer(NState.YellPatchState.ApplyNoDelay)
	end

	local PlayerData = NState.ReplicatedStorage:FindFirstChild("PlayerData")
	local PlayerFolder = PlayerData and PlayerData:FindFirstChild(NState.LocalPlayer.Name)
	local DataFolder = PlayerFolder and PlayerFolder:FindFirstChild(NState.LocalPlayer.Name .. "'s Data")
	local Options = DataFolder and DataFolder:FindFirstChild("Options")
	local Keybinds = Options and Options:FindFirstChild("Keybinds")
	local ControllerKeybinds = Options and Options:FindFirstChild("KeybindsController")
	local InteractShout = Keybinds and Keybinds:FindFirstChild("InteractShout")
	local ControllerShout = ControllerKeybinds and ControllerKeybinds:FindFirstChild("Shout/SecondaryInteract")

	table.insert(
		NState.YellPatchState.NoDelayConnections,
		NState.UserInputService.InputBegan:Connect(function(Input, Processed)
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

	local PlayerGui = NState.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
	local MainGui = SGPackage and SGPackage:FindFirstChild("MainGui")
	local MobileUI = MainGui and MainGui:FindFirstChild("MobileUI")
	local Buttons = MobileUI and MobileUI:FindFirstChild("Buttons")
	local Action = Buttons and Buttons:FindFirstChild("Action")
	local YellButton = Action and Action:FindFirstChild("Yell")

	if YellButton and YellButton:IsA("GuiButton") then
		table.insert(
			NState.YellPatchState.NoDelayConnections,
			YellButton.MouseButton1Down:Connect(ResetDebounce)
		)
	end
end

NState.YellPatchState.SetNoDelayEnabled = function(Enabled)
	NState.Environment.NotorietyNoYellDelayEnabled = Enabled == true

	if NState.Environment.NotorietyNoYellDelayEnabled then
		NState.YellPatchState.RefreshNoDelayTargets()
		NState.YellPatchState.ApplyNoDelay()
		NState.YellPatchState.ConnectNoDelaySignals()
	else
		NState.YellPatchState.ClearNoDelayConnections()
		table.clear(NState.YellPatchState.NoDelayTargets)
	end
end

NState.YellPatchState.SetAutoYellEnabled = function(Enabled)
	NState.Environment.NotorietyAutoYellEnabled = Enabled == true
	NState.YellPatchState.AutoRefresh = 0
	NState.YellPatchState.AutoLastFire = 0
	NState.YellPatchState.AutoGeneration = 0
	table.clear(NState.YellPatchState.AutoSeen)
end

NState.YellPatchState.AutoYell = function()
	if NState.Environment.NotorietyUnloaded or not NState.Environment.NotorietyAutoYellEnabled then
		return false
	end

	local Module = NState.getYellModule()
	local Character = NState.LocalPlayer.Character

	if not Module
		or not Character
		or not Character.Parent
	then
		return false
	end

	local Success, _, Fired = pcall(function()
		if NState.Environment.NotorietyYellMarkMethod == "Original" then
			if os.clock() - NState.YellPatchState.AutoLastFire < 2 then
				return 0, false
			end

			NState.YellPatchState.AutoLastFire = os.clock()
			return Module:Yell(NState.LocalPlayer, math.huge, nil), true
		end

		return Module:Yell(NState.LocalPlayer, math.huge, nil, true)
	end)

	if not Success or Fired == false then
		return false
	end

	local PlayerGui = NState.LocalPlayer:FindFirstChildOfClass("PlayerGui")
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

NState.MAX_VALUE = 999999

if type(NState.Environment.NotorietyPoliceOriginalSizes) ~= "table" then
	NState.Environment.NotorietyPoliceOriginalSizes = setmetatable({}, {
		__mode = "k",
	})
end

NState.PoliceOriginalSizes = NState.Environment.NotorietyPoliceOriginalSizes
NState.DEFAULT_POLICE_HEAD_SIZE = Vector3.new(1.1908922, 1.1954262, 1.1909529)
NState.DEFAULT_POLICE_TORSO_SIZE = Vector3.new(2, 2, 1)

NState.isReasonablePolicePartSize = function(Size)
	return typeof(Size) == "Vector3"
		and Size.X >= 0.25
		and Size.Y >= 0.25
		and Size.Z >= 0.25
		and Size.X <= 4
		and Size.Y <= 4
		and Size.Z <= 4
end

NState.getDefaultPolicePartState = function(Object)
	return {
		Size = if Object.Name == "Head" then NState.DEFAULT_POLICE_HEAD_SIZE else NState.DEFAULT_POLICE_TORSO_SIZE,
		Transparency = 0,
		Massless = false,
		CanCollide = false,
	}
end

NState.restorePolicePart = function(Object)
	local Original = NState.PoliceOriginalSizes[Object]

	if Original and Object.Parent then
		local State = if typeof(Original) == "Vector3"
			then {
				Size = Original,
				Transparency = Object.Transparency,
				Massless = Object.Massless,
				CanCollide = Object.CanCollide,
			}
			else Original

		if type(State) ~= "table" or not NState.isReasonablePolicePartSize(State.Size) then
			State = NState.getDefaultPolicePartState(Object)
		end

		Object.Size = State.Size
		Object.Transparency = State.Transparency
		Object.Massless = State.Massless
		Object.CanCollide = State.CanCollide

		NState.PoliceOriginalSizes[Object] = nil
	end
end

NState.resizePoliceNPC = function(NPC)
	if not NPC or not NPC:IsA("Model") then
		return
	end

	local Head = NPC:FindFirstChild("Head")
	local Torso = NPC:FindFirstChild("Torso")
	local Target = Head or Torso

	if not NState.Environment.NotorietyPoliceHeadScaleEnabled then
		if Head and Head:IsA("BasePart") then
			NState.restorePolicePart(Head)
		end

		if Torso and Torso:IsA("BasePart") then
			NState.restorePolicePart(Torso)
		end

		return
	end

	if Head and Torso then
		NState.restorePolicePart(Torso)
	end

	if Target and Target:IsA("BasePart") then
		local Original = NState.PoliceOriginalSizes[Target]
		local OriginalSize = typeof(Original) == "Vector3" and Original
			or (type(Original) == "table" and Original.Size or nil)

		if not NState.isReasonablePolicePartSize(OriginalSize) then
			local State = if NState.isReasonablePolicePartSize(Target.Size)
				then {
					Size = Target.Size,
					Transparency = Target.Transparency,
					Massless = Target.Massless,
					CanCollide = Target.CanCollide,
				}
				else NState.getDefaultPolicePartState(Target)
			NState.PoliceOriginalSizes[Target] = State
		elseif typeof(Original) == "Vector3" then
			NState.PoliceOriginalSizes[Target] = {
				Size = Original,
				Transparency = Target.Transparency,
				Massless = Target.Massless,
				CanCollide = Target.CanCollide,
			}
		end

		local Stored = NState.PoliceOriginalSizes[Target]
		local BaseSize = typeof(Stored) == "Vector3" and Stored or Stored.Size
		Target.Size = BaseSize * NState.Environment.NotorietyPoliceHeadScale
		Target.Transparency = 0.5
		Target.Massless = true
		Target.CanCollide = false
	end
end

NState.getPoliceNPC = function(Object, PoliceFolder)
	local Current = Object

	while Current and Current.Parent ~= PoliceFolder do
		Current = Current.Parent
	end

	if Current and Current:IsA("Model") then
		return Current
	end
end

NState.PoliceFolder = NState.Workspace:FindFirstChild("Police")

NState.applyPoliceHeadScale = function()
	if not NState.PoliceFolder then
		return
	end

	for _, NPC in NState.PoliceFolder:GetChildren() do
		NState.resizePoliceNPC(NPC)
	end
end

NState.setPoliceHeadScaleEnabled = function(Enabled)
	NState.Environment.NotorietyPoliceHeadScaleEnabled = Enabled == true
	NState.applyPoliceHeadScale()
end

if NState.PoliceFolder then
	NState.Environment.NotorietyPoliceHitboxConnection = NState.PoliceFolder.DescendantAdded:Connect(
		function(Object)
			local NPC = NState.getPoliceNPC(Object, NState.PoliceFolder)

			if NPC then
				task.defer(NState.resizePoliceNPC, NPC)
			end
		end
	)
end

NState.MaxedValues = {
	Stamina = NState.MAX_VALUE,
	MaxStamina = NState.MAX_VALUE,
	PrimaryAmmo = NState.MAX_VALUE,
	PrimaryAmmoMax = NState.MAX_VALUE,
	SecondaryAmmo = NState.MAX_VALUE,
	SecondaryAmmoMax = NState.MAX_VALUE,
	GadgetAmmo = NState.MAX_VALUE,
	GadgetAmmoMax = NState.MAX_VALUE,
	EquipmentLeft = NState.MAX_VALUE,
	SecondEquipmentLeft = NState.MAX_VALUE,
	Crit = 100,
	Dodge = 100,
	Detection = 0,
}

NState.FiniteSupplyCaps = setmetatable({}, {
	__mode = "k",
})

NState.getFiniteSupplyCap = function(Value, SuggestedCap)
	local ExistingCap = NState.FiniteSupplyCaps[Value]
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

	NState.FiniteSupplyCaps[Value] = ExistingCap
	return ExistingCap
end

NState.replenishFiniteSupplies = function(Character)
	local GadgetAmmoMax = Character:FindFirstChild("GadgetAmmoMax")

	if GadgetAmmoMax and GadgetAmmoMax:IsA("ValueBase") and type(GadgetAmmoMax.Value) == "number" then
		local Capacity = GadgetAmmoMax:FindFirstChild("Capacity")
		local SuggestedCap = Capacity and Capacity:IsA("ValueBase") and type(Capacity.Value) == "number"
			and Capacity.Value
			or nil
		local Cap = NState.getFiniteSupplyCap(GadgetAmmoMax, SuggestedCap)

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
			local Cap = NState.getFiniteSupplyCap(Value)

			if Cap and Value.Value < Cap then
				Value.Value = Cap
			end
		end
	end
end

NState.WeaponState = {
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

NState.addRequireFunction = function(Value)
	if type(Value) ~= "function" then
		return
	end

	for _, Existing in NState.WeaponState.RequireFunctions do
		if Existing == Value then
			return
		end
	end

	table.insert(NState.WeaponState.RequireFunctions, Value)
end

NState.addRequireFunction(require)

if type(getrenv) == "function" then
	local Success, RuntimeEnvironment = pcall(getrenv)

	if Success and type(RuntimeEnvironment) == "table" then
		NState.addRequireFunction(rawget(RuntimeEnvironment, "require"))
	end
end

if type(getfenv) == "function" then
	local Success, CurrentEnvironment = pcall(getfenv, 0)

	if Success and type(CurrentEnvironment) == "table" then
		NState.addRequireFunction(rawget(CurrentEnvironment, "require"))
	end
end

NState.getWeaponBackup = function(Data)
	local Backup = NState.WeaponState.Backups[Data]

	if Backup then
		return Backup
	end

	Backup = {
		Fields = {},
		Patterns = {},
		Steps = {},
		NestedFields = {},
	}

	NState.WeaponState.Backups[Data] = Backup
	return Backup
end

NState.captureField = function(Data, Backup, Key)
	if Backup.Fields[Key] then
		return
	end

	local Value = rawget(Data, Key)

	Backup.Fields[Key] = {
		Exists = Value ~= nil,
		Value = Value,
	}
end

NState.captureNestedField = function(Backup, Container, Key)
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

NState.shortenSequence = function(Sequence, Backup)
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

NState.shortenGunSequence = function(Value, Backup, Seen, Depth, FireDelay, BoltDuration)
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
				NState.captureNestedField(Backup, Value, Key)
				Value[Key] = FireDelay
			elseif LowerKey == "boltduration" or LowerKey == "duration" then
				NState.captureNestedField(Backup, Value, Key)
				Value[Key] = BoltDuration
			end
		elseif LowerKey == "boltlock" and type(Item) == "boolean" then
			NState.captureNestedField(Backup, Value, Key)
			Value[Key] = false
		end

		if type(Item) == "table" then
			NState.shortenGunSequence(Item, Backup, Seen, Depth + 1, FireDelay, BoltDuration)
		end
	end
end

NState.patchGunSequences = function(Data, Backup)
	local Seen = {}
	local FireDelay = tonumber(NState.Environment.NotorietyFireDelay) or 0.01
	local BoltDuration = tonumber(NState.Environment.NotorietyBoltDuration) or 0.001

	for Key, Value in Data do
		if type(Key) == "string" and type(Value) == "table" then
			local LowerKey = string.lower(Key)

			if string.find(LowerKey, "shoot", 1, true)
				or string.find(LowerKey, "bolt", 1, true)
				or string.find(LowerKey, "fire", 1, true)
			then
				NState.shortenGunSequence(Value, Backup, Seen, 0, FireDelay, BoltDuration)
			end
		end
	end
end

NState.applyWeaponData = nil

NState.isStandardGunData = function(Data)
	if type(Data) ~= "table" or rawget(Data, "WeaponType") ~= "Gun" then
		return false
	end

	local AmmoClass = rawget(Data, "AmmoClass")

	return AmmoClass == "Primary" or AmmoClass == "Secondary"
end

NState.isInfiniteGunState = function(State, Data)
	if type(State) ~= "table" or not NState.isStandardGunData(Data) then
		return false
	end

	local AmmoClass = rawget(Data, "AmmoClass") or rawget(State, "AmmoType")

	return AmmoClass == "Primary" or AmmoClass == "Secondary"
end

NState.patchAmmoResult = function(Result, State)
	if not NState.Environment.NotorietyWeaponEnabled
		or not NState.Environment.NotorietyInfiniteAmmoEnabled
		or type(Result) ~= "table"
	then
		return Result
	end

	local Data = type(State) == "table" and rawget(State, "data") or nil

	if not NState.isInfiniteGunState(State, Data) then
		return Result
	end

	for Key, Value in Result do
		if type(Key) == "string" and type(Value) == "number" then
			local LowerKey = string.lower(Key)

			if string.find(LowerKey, "ammo", 1, true)
				or string.find(LowerKey, "mag", 1, true)
				or LowerKey == "spare"
			then
				Result[Key] = NState.MAX_VALUE
			end
		end
	end

	local AmmoMax = Result.AmmoMax

	if typeof(AmmoMax) == "Instance" and AmmoMax:IsA("ValueBase") and typeof(AmmoMax.Value) == "number" then
		AmmoMax.Value = NState.MAX_VALUE
	end

	return Result
end

NState.restoreAmmoWrapper = function(State)
	local Wrappers = NState.Environment.NotorietyGetAmmoWrappers
	local Record = type(Wrappers) == "table" and Wrappers[State] or nil

	if type(Record) ~= "table" then
		return
	end

	if type(Record.Original) == "function" and State.getAmmo == Record.Wrapper then
		State.getAmmo = Record.Original
	end

	Wrappers[State] = nil
end

NState.getDebugUpvalue = function(Function, Index)
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

NState.Targeting = {}

function NState.Targeting.getCategory(TargetModel)
	if not TargetModel or TargetModel == NState.LocalPlayer.Character then
		return nil
	end

	local PoliceFolder = NState.Workspace:FindFirstChild("Police")
	if PoliceFolder and TargetModel:IsDescendantOf(PoliceFolder) then
		return "Police"
	end

	local CriminalsFolder = NState.Workspace:FindFirstChild("Criminals")
	if CriminalsFolder and TargetModel:IsDescendantOf(CriminalsFolder) then
		local Player = NState.Players:GetPlayerFromCharacter(TargetModel)
		if Player and Player ~= NState.LocalPlayer then
			return "Criminals"
		end
	end

	return nil
end

function NState.Targeting.isCategoryEnabled(Category, PoliceEnabled, CriminalsEnabled)
	if Category == "Police" then
		return PoliceEnabled == true
	end

	if Category == "Criminals" then
		return CriminalsEnabled == true
	end

	return false
end

function NState.Targeting.isSilentAimCategoryEnabled(Category)
	return NState.Targeting.isCategoryEnabled(
		Category,
		NState.Environment.NotorietySilentAimTargetPolice,
		NState.Environment.NotorietySilentAimTargetCriminals
	)
end

function NState.Targeting.isWallBangCategoryEnabled(Category)
	return NState.Targeting.isCategoryEnabled(
		Category,
		NState.Environment.NotorietyWallBangTargetPolice,
		NState.Environment.NotorietyWallBangTargetCriminals
	)
end

function NState.Targeting.getPart(Target)
	return Target and (
		Target:FindFirstChild("Head", true)
		or Target:FindFirstChild("UpperTorso", true)
		or Target:FindFirstChild("Torso", true)
		or Target:FindFirstChild("HumanoidRootPart", true)
	) or nil
end

function NState.Targeting.isAlive(Target)
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

function NState.Targeting.forEach(PoliceEnabled, CriminalsEnabled, Callback)
	if PoliceEnabled then
		local PoliceFolder = NState.Workspace:FindFirstChild("Police")
		if PoliceFolder then
			for _, Target in PoliceFolder:GetChildren() do
				Callback(Target, "Police")
			end
		end
	end

	if CriminalsEnabled then
		local CriminalsFolder = NState.Workspace:FindFirstChild("Criminals")
		if CriminalsFolder then
			for _, Player in NState.Players:GetPlayers() do
				if Player ~= NState.LocalPlayer then
					local Target = Player.Character
					if Target and Target:IsDescendantOf(CriminalsFolder) then
						Callback(Target, "Criminals")
					end
				end
			end
		end
	end
end

function NState.Targeting.isWallBangAllowed(TargetModel)
	if not NState.Environment.NotorietyWallBangEnabled then
		return false
	end

	return NState.Targeting.isWallBangCategoryEnabled(NState.Targeting.getCategory(TargetModel))
end

function NState.Targeting.isVisible(TargetModel, TargetPart)
	if NState.Targeting.isWallBangAllowed(TargetModel) then
		return true
	end

	local Camera = NState.Workspace.CurrentCamera

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
	local Character = NState.LocalPlayer.Character

	if Character then
		table.insert(Filter, Character)
	end

	table.insert(Filter, Camera)
	Params.FilterDescendantsInstances = Filter

	local Result = NState.Workspace:Raycast(Origin, Direction, Params)

	return Result == nil
		or Result.Instance == TargetPart
		or Result.Instance:IsDescendantOf(TargetModel)
end

function NState.Targeting.getSilentAimTargetPart()
	if not NState.Environment.NotorietySilentAimEnabled then
		return nil
	end

	local Camera = NState.Workspace.CurrentCamera
	if not Camera then
		return nil
	end

	local MousePosition = NState.UserInputService:GetMouseLocation()
	local MaxFOV = math.clamp(tonumber(NState.Environment.NotorietySilentAimFOV) or 250, 0, 2000)
	local BestPart
	local BestDistance = math.huge

	NState.Targeting.forEach(
		NState.Environment.NotorietySilentAimTargetPolice,
		NState.Environment.NotorietySilentAimTargetCriminals,
		function(Target, Category)
			if not NState.Targeting.isSilentAimCategoryEnabled(Category) or not NState.Targeting.isAlive(Target) then
				return
			end

			local HitPart = NState.Targeting.getPart(Target)
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
				and NState.Targeting.isVisible(Target, HitPart)
			then
				BestDistance = ScreenDistance
				BestPart = HitPart
			end
		end
	)

	return BestPart
end

function NState.Targeting.getWallBangTargetPartFromShot(StartPosition, Direction)
	if not NState.Environment.NotorietyWallBangEnabled
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

	NState.Targeting.forEach(
		NState.Environment.NotorietyWallBangTargetPolice,
		NState.Environment.NotorietyWallBangTargetCriminals,
		function(Target, Category)
			if not NState.Targeting.isWallBangCategoryEnabled(Category) or not NState.Targeting.isAlive(Target) then
				return
			end

			local HitPart = NState.Targeting.getPart(Target)
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

NState.restoreRuntimeSilentAimWrapper = function(State)
	local Record = NState.WeaponState.RuntimeSilentAimBackups[State]

	if type(Record) ~= "table" then
		return
	end

	if type(Record.Original) == "function" and State.shoot == Record.Wrapper then
		State.shoot = Record.Original
	end

	NState.WeaponState.RuntimeSilentAimBackups[State] = nil
end

NState.restoreProjectileSilentAimWrapper = function()
	local Record = NState.WeaponState.ProjectileSilentAim

	if type(Record) ~= "table" then
		return
	end

	if type(Record.Projectile) == "table"
		and type(Record.Original) == "function"
		and Record.Projectile.new == Record.Wrapper
	then
		Record.Projectile.new = Record.Original
	end

	NState.WeaponState.ProjectileSilentAim = nil
end

NState.restoreRuntimeSilentAimWrappers = function()
	local States = {}

	for State in NState.WeaponState.RuntimeSilentAimBackups do
		States[#States + 1] = State
	end

	for _, State in States do
		NState.restoreRuntimeSilentAimWrapper(State)
	end

	NState.restoreProjectileSilentAimWrapper()
end

NState.getProjectileTableFromShoot = function(Shoot)
	if type(Shoot) ~= "function" then
		return nil
	end

	local Direct = NState.getDebugUpvalue(Shoot, 28)

	if type(Direct) == "table" and type(rawget(Direct, "new")) == "function" then
		return Direct
	end

	local PossibleOriginal = NState.getDebugUpvalue(Shoot, 2)

	if type(PossibleOriginal) == "function" then
		local FromOriginal = NState.getDebugUpvalue(PossibleOriginal, 28)

		if type(FromOriginal) == "table" and type(rawget(FromOriginal, "new")) == "function" then
			return FromOriginal
		end
	end

	return nil
end

NState.patchRuntimeSilentAim = function(State)
	if type(State) ~= "table" then
		return false
	end

	if not NState.Environment.NotorietyWeaponEnabled
		or (not NState.Environment.NotorietySilentAimEnabled and not NState.Environment.NotorietyWallBangEnabled)
	then
		NState.restoreRuntimeSilentAimWrapper(State)
		NState.restoreProjectileSilentAimWrapper()
		return false
	end

	NState.restoreRuntimeSilentAimWrapper(State)

	local Shoot = rawget(State, "shoot")
	local ProjectileTable = NState.getProjectileTableFromShoot(Shoot)

	if type(ProjectileTable) ~= "table" then
		return false
	end

	local Existing = NState.WeaponState.ProjectileSilentAim

	if type(Existing) == "table"
		and Existing.Projectile == ProjectileTable
		and ProjectileTable.new == Existing.Wrapper
	then
		return true
	end

	if type(Existing) == "table" then
		NState.restoreProjectileSilentAimWrapper()
	end

	local OriginalNew = rawget(ProjectileTable, "new")

	if type(OriginalNew) ~= "function" then
		return false
	end

	local Wrapper
	Wrapper = function(Data, ...)
		if not NState.Environment.NotorietyUnloaded
			and NState.Environment.NotorietyWeaponEnabled
			and type(Data) == "table"
			and Data.Player == NState.LocalPlayer
			and not Data.IsNPC
			and typeof(Data.StartPosition) == "Vector3"
		then
			local RedirectedTarget

			if NState.Environment.NotorietySilentAimEnabled then
				local TargetPart = NState.Targeting.getSilentAimTargetPart()

				if TargetPart and TargetPart.Parent then
					local Delta = TargetPart.Position - Data.StartPosition

					if Delta.Magnitude > 0.001 then
						Data.TargetPosition = TargetPart.Position
						Data.Direction = Delta.Unit
						RedirectedTarget = TargetPart
						NState.Environment.NotorietySilentAimLastTarget = TargetPart:GetFullName()
						NState.Environment.NotorietySilentAimLastRedirect = TargetPart.Position
					end
				end
			end

			if NState.Environment.NotorietyWallBangEnabled and typeof(Data.Direction) == "Vector3" then
				local WallBangTarget = RedirectedTarget

				if WallBangTarget then
					local TargetModel = WallBangTarget:FindFirstAncestorOfClass("Model")
					if not TargetModel or not NState.Targeting.isWallBangAllowed(TargetModel) then
						WallBangTarget = nil
					end
				end

				if not WallBangTarget then
					WallBangTarget = NState.Targeting.getWallBangTargetPartFromShot(Data.StartPosition, Data.Direction)
				end

				if WallBangTarget then
					Data.Piercing = math.max(tonumber(Data.Piercing) or 0, 1000)

					if type(Data.GunData) == "table" then
						local GunData = table.clone(Data.GunData)
						GunData.EnemyPiercing = math.max(tonumber(GunData.EnemyPiercing) or 0, 1000)
						Data.GunData = GunData
					end

					NState.Environment.NotorietyWallBangLastTarget = WallBangTarget:GetFullName()
				end
			end
		end

		return OriginalNew(Data, ...)
	end

	NState.WeaponState.ProjectileSilentAim = {
		Projectile = ProjectileTable,
		Original = OriginalNew,
		Wrapper = Wrapper,
	}

	ProjectileTable.new = Wrapper
	return true
end

NState.patchRuntimeWeaponSpread = function(State, Spread)
	local DebugLibrary = debug
	local Shoot = type(State) == "table" and rawget(State, "shoot") or nil
	local AimRecord = type(State) == "table" and NState.WeaponState.RuntimeSilentAimBackups[State] or nil

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
	local Current = NState.getDebugUpvalue(Shoot, Index)

	if type(Current) ~= "number" or Current < 0 or Current > 10000 then
		return false
	end

	local Record = NState.WeaponState.RuntimeSpreadBackups[State]

	if type(Record) ~= "table" or Record.Function ~= Shoot then
		Record = {
			Function = Shoot,
			Index = Index,
			Value = Current,
		}

		NState.WeaponState.RuntimeSpreadBackups[State] = Record
	end

	local Success = pcall(DebugLibrary.setupvalue, Shoot, Index, Spread)

	return Success
end

NState.patchRuntimeWeaponState = function(State)
	if not NState.Environment.NotorietyWeaponEnabled or type(State) ~= "table" then
		return false
	end

	local GetAmmo = rawget(State, "getAmmo")
	local Data = rawget(State, "data")

	if type(GetAmmo) ~= "function" or type(Data) ~= "table" then
		return false
	end

	local Patched = NState.applyWeaponData(Data)

	if rawget(Data, "WeaponType") == "Gun" then
		if NState.Environment.NotorietyAccuracyModEnabled then
			local DesiredAccuracy = math.clamp(tonumber(NState.Environment.NotorietyAccuracy) or 100, 0, 100)
			local DesiredSpread = 10000 - DesiredAccuracy * 100

			if type(rawget(State, "Accuracy")) == "number" then
				if NState.WeaponState.RuntimeAccuracyBackups[State] == nil then
					NState.WeaponState.RuntimeAccuracyBackups[State] = State.Accuracy
				end

				State.Accuracy = DesiredSpread
			end

			NState.patchRuntimeWeaponSpread(State, DesiredSpread)
		end

		NState.patchRuntimeSilentAim(State)

		if NState.Environment.NotorietyNoRecoilEnabled then
			local RecoilBackup = NState.WeaponState.RuntimeRecoilBackups[State]

			if not RecoilBackup then
				RecoilBackup = {}

				for _, Key in { "ShakeMagnitude", "ShakeRoughness", "pushdist" } do
					local Value = rawget(State, Key)
					RecoilBackup[Key] = { Exists = Value ~= nil, Value = Value }
				end

				NState.WeaponState.RuntimeRecoilBackups[State] = RecoilBackup
			end

			State.ShakeMagnitude = 0
			State.ShakeRoughness = 0
			State.pushdist = 0
		end

		NState.WeaponState.RuntimeWeapons[State] = true
	else
		NState.WeaponState.RuntimeWeapons[State] = nil
	end

	if not NState.isInfiniteGunState(State, Data) or not NState.Environment.NotorietyInfiniteAmmoEnabled then
		NState.restoreAmmoWrapper(State)
		return Patched
	end

	local Record = NState.Environment.NotorietyGetAmmoWrappers[State]

	if not Record or State.getAmmo ~= Record.Wrapper then
		local Original = State.getAmmo
		local Wrapper

		Wrapper = function(...)
			local Result = Original(...)

			return NState.patchAmmoResult(Result, State)
		end

		Record = {
			Original = Original,
			Wrapper = Wrapper,
		}

		NState.Environment.NotorietyGetAmmoWrappers[State] = Record
		State.getAmmo = Wrapper
	end

	local Success, Result = pcall(State.getAmmo, State)

	if Success then
		NState.patchAmmoResult(Result, State)
	end

	return true
end

NState.refreshRuntimeFireTiming = function(State)
	if not NState.Environment.NotorietyWeaponEnabled
		or not NState.Environment.NotorietyRapidFireEnabled
		or type(State) ~= "table"
	then
		return
	end

	local Data = rawget(State, "data")

	if type(Data) ~= "table" or rawget(Data, "WeaponType") ~= "Gun" then
		return
	end

	local FireDelay = math.max(tonumber(rawget(Data, "FireDelay")) or tonumber(NState.Environment.NotorietyFireDelay) or 0.01, 0)
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

NState.refreshRuntimeAmmo = function()
	if not NState.Environment.NotorietyWeaponEnabled then
		return
	end

	for State in NState.WeaponState.RuntimeWeapons do
		NState.patchRuntimeWeaponState(State)
		NState.refreshRuntimeFireTiming(State)
	end
end

NState.zeroVectorPattern = function(Pattern, Backup)
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

NState.restoreWeaponData = function(Data, Backup)
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

NState.restoreAllWeaponData = function()
	for Data, Backup in NState.WeaponState.Backups do
		pcall(NState.restoreWeaponData, Data, Backup)
	end
end

NState.restoreRuntimeWeaponAccuracy = function()
	for State, Accuracy in NState.WeaponState.RuntimeAccuracyBackups do
		if type(State) == "table" and type(Accuracy) == "number" then
			State.Accuracy = Accuracy
		end
	end

	local DebugLibrary = debug

	if type(DebugLibrary) == "table" and type(DebugLibrary.setupvalue) == "function" then
		for _, Record in NState.WeaponState.RuntimeSpreadBackups do
			if type(Record) == "table"
				and type(Record.Function) == "function"
				and type(Record.Index) == "number"
				and type(Record.Value) == "number"
			then
				pcall(DebugLibrary.setupvalue, Record.Function, Record.Index, Record.Value)
			end
		end
	end

	table.clear(NState.WeaponState.RuntimeAccuracyBackups)
	table.clear(NState.WeaponState.RuntimeSpreadBackups)
end

NState.restoreRuntimeWeaponRecoil = function()
	for State, Backup in NState.WeaponState.RuntimeRecoilBackups do
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

	table.clear(NState.WeaponState.RuntimeRecoilBackups)
end

NState.restoreAllAmmoWrappers = function()
	if type(NState.Environment.NotorietyGetAmmoWrappers) ~= "table" then
		return
	end

	local States = {}
	for State in NState.Environment.NotorietyGetAmmoWrappers do States[#States + 1] = State end
	for _, State in States do NState.restoreAmmoWrapper(State) end
	table.clear(NState.WeaponState.RuntimeWeapons)
end

NState.applyWeaponData = function(Data)
	if not NState.Environment.NotorietyWeaponEnabled or type(Data) ~= "table" then
		return false
	end

	local WeaponType = rawget(Data, "WeaponType")

	if WeaponType == "Gun" then
		local StandardGun = NState.isStandardGunData(Data)
		local Backup = NState.getWeaponBackup(Data)
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
			NState.captureField(Data, Backup, Key)
		end

		if NState.Environment.NotorietyRapidFireEnabled then
			Data.FireDelay = tonumber(NState.Environment.NotorietyFireDelay) or 0.01
			Data.BoltDuration = tonumber(NState.Environment.NotorietyBoltDuration) or 0.001
			Data.BoltLock = false
			NState.patchGunSequences(Data, Backup)

			if type(Data.ManualCasingEjection) == "boolean" then
				Data.ManualCasingEjection = false
			end
		end

		if NState.Environment.NotorietyAccuracyModEnabled and type(Data.Accuracy) == "number" then
			Data.Accuracy = math.clamp(tonumber(NState.Environment.NotorietyAccuracy) or 100, 0, 100)
		end

		if NState.Environment.NotorietyFullAutoEnabled and StandardGun then
			Data.FireMode = "Auto"

			if type(Data.FireModeList) ~= "table"
				or Data.FireModeList[1] ~= "Auto"
				or Data.FireModeList[2] ~= nil
			then
				Data.FireModeList = { "Auto" }
			end
		end

		if NState.Environment.NotorietyInfiniteAmmoEnabled then
			local AmmoClass = Data.AmmoClass
			local UsesInfiniteGunAmmo = AmmoClass == "Primary" or AmmoClass == "Secondary"

			if UsesInfiniteGunAmmo then
				Data.MagazineSize = NState.MAX_VALUE
				Data.AmmoMax = NState.MAX_VALUE
			end
		end

		if NState.Environment.NotorietyNoRecoilEnabled then
			NState.zeroVectorPattern(Data.RecoilDirectionPattern, Backup)
			NState.zeroVectorPattern(Data.RecoilCameraDirectionPattern, Backup)

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
		local Backup = NState.getWeaponBackup(Data)

		for _, Key in {
			"FireMode",
			"MaxCharge",
			"AttackSpeed",
		} do
			NState.captureField(Data, Backup, Key)
		end

		Data.FireMode = "Auto"
		Data.MaxCharge = 0.01
		Data.AttackSpeed = 100

		NState.shortenSequence(Data.ChargeAnim, Backup)
		NState.shortenSequence(Data.StrikeAnim, Backup)
		NState.shortenSequence(Data.StrikeAnim2, Backup)

		return true
	end

	return false
end

NState.getFunctionUpvalues = function(Function)
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

NState.getLocalGunsEnvironment = function()
	local PlayerScripts = NState.LocalPlayer:FindFirstChild("PlayerScripts")
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

NState.patchLoadedWeaponTables = function()
	local ScriptEnvironment = NState.getLocalGunsEnvironment()

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

		if NState.applyWeaponData(Value) then
			Patched += 1
		end

		NState.patchRuntimeWeaponState(Value)

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
			local Upvalues = NState.getFunctionUpvalues(Value)

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

NState.queueLoadedWeaponFallback = function()
	if not NState.Environment.NotorietyWeaponEnabled or NState.WeaponState.FallbackQueued then
		return
	end

	NState.WeaponState.FallbackQueued = true

	task.delay(0.25, function()
		NState.WeaponState.FallbackQueued = false

		if not NState.Environment.NotorietyWeaponEnabled then
			return
		end

		if NState.patchLoadedWeaponTables() > 0 then
			NState.WeaponState.FallbackAttempts = 0
		elseif NState.WeaponState.RequireUnavailable and NState.WeaponState.FallbackAttempts < 20 then
			NState.WeaponState.FallbackAttempts += 1
			task.delay(0.75, NState.queueLoadedWeaponFallback)
		else
			NState.WeaponState.FallbackAttempts = 0
		end
	end)
end

NState.getModuleData = function(Module)
	local Cached = NState.WeaponState.ModuleCache[Module]

	if type(Cached) == "table" then
		return Cached
	end

	if NState.WeaponState.RequireUnavailable then
		return nil
	end

	for _, RequireFunction in NState.WeaponState.RequireFunctions do
		local Success, Result = pcall(RequireFunction, Module)

		if Success and type(Result) == "table" then
			NState.WeaponState.RequireFailures = 0
			NState.WeaponState.ModuleCache[Module] = Result
			return Result
		end
	end

	NState.WeaponState.RequireFailures += 1

	if #NState.WeaponState.RequireFunctions == 0 or NState.WeaponState.RequireFailures >= 3 then
		NState.WeaponState.RequireUnavailable = true
	end

	return nil
end

NState.applyWeaponModule = function(Object)
	if not NState.Environment.NotorietyWeaponEnabled
		or not Object:IsA("ModuleScript")
		or Object.Name ~= "Data"
	then
		return
	end

	local Data = NState.getModuleData(Object)

	if Data then
		NState.applyWeaponData(Data)
	else
		NState.queueLoadedWeaponFallback()
	end
end

NState.trackWeaponContainer = function(Container)
	if NState.Environment.NotorietyUnloaded or not Container then
		return
	end

	for _, Object in Container:GetDescendants() do
		NState.applyWeaponModule(Object)
	end

	table.insert(
		NState.Environment.NotorietyWeaponConnections,
		Container.DescendantAdded:Connect(function(Object)
			if NState.Environment.NotorietyUnloaded then
				return
			end

			if Object:IsA("ModuleScript") and Object.Name == "Data" then
				task.defer(function()
					NState.applyWeaponModule(Object)
					NState.patchLoadedWeaponTables()
				end)
			end
		end)
	)
end

NState.getEquippedGun = function()
	local Character = NState.LocalPlayer.Character

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

NState.Apply = function()
	local Character = NState.LocalPlayer.Character

	if not Character then
		return
	end

	if NState.Environment.NotorietyInfiniteEquipmentEnabled then
		for _, Name in { "EquipmentLeft", "SecondEquipmentLeft" } do
			local Value = Character:FindFirstChild(Name)
			if Value and Value:IsA("ValueBase") and type(Value.Value) == "number" and Value.Value ~= NState.MAX_VALUE then
				Value.Value = NState.MAX_VALUE
			end
		end
	end

	if not NState.Environment.MaxEverythingEnabled then
		return
	end

	for _, Object in Character:GetDescendants() do
		if Object:IsA("ValueBase") and not Object:FindFirstAncestorWhichIsA("Tool") then
			local Value = NState.MaxedValues[Object.Name]

			if Value ~= nil and typeof(Object.Value) == "number" and Object.Value ~= Value then
				Object.Value = Value
			end
		end
	end

	NState.replenishFiniteSupplies(Character)
end

NState.FriendlyFireState = {
	Instance = nil,
	Owned = false,
	Captured = false,
	OriginalValue = nil,
}

NState.getActiveMutators = function()
	return NState.RS_Package:FindFirstChild("ActiveMutators")
end

NState.restoreFriendlyFire = function()
	local Instance = NState.FriendlyFireState.Instance

	if typeof(Instance) == "Instance" and Instance.Parent then
		if NState.FriendlyFireState.Owned then
			pcall(function()
				Instance:Destroy()
			end)
		elseif NState.FriendlyFireState.Captured and Instance:IsA("NumberValue") then
			pcall(function()
				Instance.Value = NState.FriendlyFireState.OriginalValue
			end)
		end
	end

	NState.FriendlyFireState.Instance = nil
	NState.FriendlyFireState.Owned = false
	NState.FriendlyFireState.Captured = false
	NState.FriendlyFireState.OriginalValue = nil
end

NState.applyFriendlyFire = function()
	local ActiveMutators = NState.getActiveMutators()

	if not ActiveMutators then
		return false
	end

	if not NState.Environment.NotorietyFriendlyFireEnabled then
		NState.restoreFriendlyFire()
		return false
	end

	local Existing = ActiveMutators:FindFirstChild("FriendlyFire")

	if Existing then
		if NState.FriendlyFireState.Instance ~= Existing then
			NState.restoreFriendlyFire()
			NState.FriendlyFireState.Instance = Existing
			NState.FriendlyFireState.Owned = Existing:GetAttribute("NotorietyFriendlyFireOwned") == true

			if not NState.FriendlyFireState.Owned and Existing:IsA("NumberValue") then
				NState.FriendlyFireState.Captured = true
				NState.FriendlyFireState.OriginalValue = Existing.Value
			end
		end

		if Existing:IsA("NumberValue") then
			Existing.Value = 100
		end

		return true
	end

	NState.restoreFriendlyFire()

	local FriendlyFire = NState.ServiceResolver.ns("NumberValue")
	if not FriendlyFire then
		FriendlyFire = Instance.new("NumberValue")
	end

	FriendlyFire.Name = "FriendlyFire"
	FriendlyFire.Value = 100
	FriendlyFire:SetAttribute("NotorietyFriendlyFireOwned", true)
	FriendlyFire.Parent = ActiveMutators

	NState.FriendlyFireState.Instance = FriendlyFire
	NState.FriendlyFireState.Owned = true

	return true
end

NState.setFriendlyFireEnabled = function(Enabled)
	NState.Environment.NotorietyFriendlyFireEnabled = Enabled == true

	if NState.Environment.NotorietyFriendlyFireEnabled then
		NState.applyFriendlyFire()
		return
	end

	local ActiveMutators = NState.getActiveMutators()
	local Existing = ActiveMutators and ActiveMutators:FindFirstChild("FriendlyFire")

	if not Existing then
		NState.restoreFriendlyFire()
		return
	end

	if Existing:GetAttribute("NotorietyFriendlyFireOwned") == true then
		if NState.FriendlyFireState.Instance ~= Existing then
			NState.restoreFriendlyFire()
			NState.FriendlyFireState.Instance = Existing
			NState.FriendlyFireState.Owned = true
		end

		NState.restoreFriendlyFire()
		return
	end

	if NState.FriendlyFireState.Instance ~= Existing then
		NState.restoreFriendlyFire()
		NState.FriendlyFireState.Instance = Existing
		NState.FriendlyFireState.Owned = false

		if Existing:IsA("NumberValue") then
			NState.FriendlyFireState.Captured = true
			NState.FriendlyFireState.OriginalValue = Existing.Value
		end
	end

	if Existing:IsA("NumberValue") then
		Existing.Value = 0
	end
end

NState.ClientMutatorState = {
	Records = {},
	BugFeatureParts = setmetatable({}, {
		__mode = "k",
	}),
	BugFeatureConnection = nil,
}

NState.createClientMutatorValue = function(Name)
	local Value = NState.ServiceResolver.ns("BoolValue")

	if not Value then
		Value = Instance.new("BoolValue")
	end

	Value.Name = Name
	Value.Value = true
	Value:SetAttribute("NotorietyClientMutatorOwned", true)

	return Value
end

NState.setClientBooleanMutator = function(Name, Enabled)
	local ActiveMutators = NState.getActiveMutators()

	if not ActiveMutators then
		return false
	end

	local Record = NState.ClientMutatorState.Records[Name]
	local Existing = ActiveMutators:FindFirstChild(Name)

	if Enabled then
		if Existing then
			NState.ClientMutatorState.Records[Name] = {
				Instance = Existing,
				Owned = Existing:GetAttribute("NotorietyClientMutatorOwned") == true,
			}
			return true
		end

		local Value = NState.createClientMutatorValue(Name)
		Value.Parent = ActiveMutators

		NState.ClientMutatorState.Records[Name] = {
			Instance = Value,
			Owned = true,
		}

		return true
	end

	if Record and Record.Owned and typeof(Record.Instance) == "Instance" and Record.Instance.Parent then
		pcall(function()
			Record.Instance:Destroy()
		end)
	elseif Existing and Existing:GetAttribute("NotorietyClientMutatorOwned") == true then
		pcall(function()
			Existing:Destroy()
		end)
	end

	NState.ClientMutatorState.Records[Name] = nil
	return false
end

NState.isBugFeatureJumpPart = function(Object)
	if typeof(Object) ~= "Instance" or not Object:IsA("BasePart") or Object.Name ~= "JumpPart" then
		return false
	end

	local Current = Object.Parent

	for _ = 1, 6 do
		if not Current then
			break
		end

		if Current.Name == "SAW" or Current.Name == "Chainsaw" then
			return true
		end

		Current = Current.Parent
	end

	return false
end

NState.applyBugFeaturePart = function(Part)
	if not NState.Environment.NotorietyBugFeatureEnabled or not NState.isBugFeatureJumpPart(Part) then
		return
	end

	if NState.ClientMutatorState.BugFeatureParts[Part] == nil then
		local Highlight = Part:FindFirstChild("Highlight")
		NState.ClientMutatorState.BugFeatureParts[Part] = {
			CanCollide = Part.CanCollide,
			Transparency = Part.Transparency,
			Highlight = Highlight,
			HighlightEnabled = Highlight and Highlight:IsA("Highlight") and Highlight.Enabled or nil,
		}
	end

	Part.CanCollide = true
	Part.Transparency = 0

	local Highlight = Part:FindFirstChild("Highlight")
	if Highlight and Highlight:IsA("Highlight") then
		Highlight.Enabled = true
	end
end

NState.restoreBugFeatureParts = function()
	for Part, Original in NState.ClientMutatorState.BugFeatureParts do
		if typeof(Part) == "Instance" and Part.Parent and type(Original) == "table" then
			pcall(function()
				Part.CanCollide = Original.CanCollide
				Part.Transparency = Original.Transparency
			end)

			local Highlight = Original.Highlight
			if typeof(Highlight) == "Instance" and Highlight.Parent and Original.HighlightEnabled ~= nil then
				pcall(function()
					Highlight.Enabled = Original.HighlightEnabled
				end)
			end
		end
	end

	table.clear(NState.ClientMutatorState.BugFeatureParts)
end

NState.scanBugFeatureParts = function()
	if not NState.Environment.NotorietyBugFeatureEnabled then
		return
	end

	for _, Object in NState.Workspace:GetDescendants() do
		if NState.isBugFeatureJumpPart(Object) then
			NState.applyBugFeaturePart(Object)
		end
	end
end

NState.setRealismModeEnabled = function(Enabled)
	NState.Environment.NotorietyRealismModeEnabled = Enabled == true
	NState.setClientBooleanMutator("RealismMode", NState.Environment.NotorietyRealismModeEnabled)
end

NState.setBugFeatureEnabled = function(Enabled)
	NState.Environment.NotorietyBugFeatureEnabled = Enabled == true
	NState.setClientBooleanMutator("BugFeature", NState.Environment.NotorietyBugFeatureEnabled)

	if NState.Environment.NotorietyBugFeatureEnabled then
		if not NState.ClientMutatorState.BugFeatureConnection then
			NState.ClientMutatorState.BugFeatureConnection = NState.Workspace.DescendantAdded:Connect(function(Object)
				if NState.Environment.NotorietyUnloaded or not NState.Environment.NotorietyBugFeatureEnabled then
					return
				end

				if NState.isBugFeatureJumpPart(Object) then
					task.defer(NState.applyBugFeaturePart, Object)
				end
			end)
		end

		NState.scanBugFeatureParts()
		return
	end

	if NState.ClientMutatorState.BugFeatureConnection then
		pcall(function()
			NState.ClientMutatorState.BugFeatureConnection:Disconnect()
		end)
		NState.ClientMutatorState.BugFeatureConnection = nil
	end

	NState.restoreBugFeatureParts()
end

NState.restoreClientMutators = function()
	if NState.ClientMutatorState.BugFeatureConnection then
		pcall(function()
			NState.ClientMutatorState.BugFeatureConnection:Disconnect()
		end)
		NState.ClientMutatorState.BugFeatureConnection = nil
	end

	NState.restoreBugFeatureParts()

	for Name, Record in NState.ClientMutatorState.Records do
		if type(Record) == "table"
			and Record.Owned
			and typeof(Record.Instance) == "Instance"
			and Record.Instance.Parent
		then
			pcall(function()
				Record.Instance:Destroy()
			end)
		end

		NState.ClientMutatorState.Records[Name] = nil
	end
end

NState.isTeammatePlayer = function(Player)
	if not Player or Player == NState.LocalPlayer then
		return false
	end

	local Criminals = NState.Workspace:FindFirstChild("Criminals")
	local Character = Player.Character
	return Criminals ~= nil and Character ~= nil and Character:IsDescendantOf(Criminals)
end

NState.getTeammatePlayers = function()
	local Teammates = {}

	for _, Player in NState.Players:GetPlayers() do
		if NState.isTeammatePlayer(Player) then
			table.insert(Teammates, Player)
		end
	end

	table.sort(Teammates, function(Left, Right)
		return string.lower(Left.Name) < string.lower(Right.Name)
	end)

	return Teammates
end

NState.getTeammatePickerValues = function()
	local Names = {}

	for _, Player in NState.Players:GetPlayers() do
		if Player ~= NState.LocalPlayer then
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

NState.runKillTeammates = function(TargetName)
	if NState.Environment.KillTeammatesRunning then
		return
	end

	NState.Environment.KillTeammatesRunning = true

	local Killed = 0
	local Attempted = 0
	local Success, Error = xpcall(function()
		local Gun = NState.getEquippedGun()

		if not Gun then
			return
		end

		local Targets = {}
		TargetName = tostring(TargetName or NState.Environment.NotorietyTeammateTarget or "All")

		if TargetName == "All" then
			Targets = NState.getTeammatePlayers()
		else
			local Player = NState.Players:FindFirstChild(TargetName)
			if NState.isTeammatePlayer(Player) then
				table.insert(Targets, Player)
			end
		end

		for _, Player in Targets do
			if NState.Environment.NotorietyUnloaded then
				break
			end

			if not Gun.Parent then
				Gun = NState.getEquippedGun()
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
				NState.Event:FireServer(
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

	NState.Environment.KillTeammatesRunning = false

	if not Success then
		warn(Error)
	elseif not NState.Environment.NotorietyUnloaded then
		pcall(function()
			NState.NotorietyUI.Library:Notify({
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

NState.runKill = function()
	if NState.Environment.KillPoliceRunning then
		return
	end

	NState.Environment.KillPoliceRunning = true

	local Killed = 0
	local Success, Error = xpcall(function()
		local PoliceFolder = NState.Workspace:FindFirstChild("Police")
		local Gun = NState.getEquippedGun()

		if not PoliceFolder or not Gun then
			return
		end

		for _, Target in PoliceFolder:GetChildren() do
			if NState.Environment.NotorietyUnloaded then
				break
			end

			if not Gun.Parent then
				Gun = NState.getEquippedGun()

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
				NState.Event:FireServer(
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

	NState.Environment.KillPoliceRunning = false

	if not Success then
		warn(Error)
	elseif not NState.Environment.NotorietyUnloaded then
		pcall(function()
			NState.NotorietyUI.Library:Notify({
				Title = "Kill Police",
				Content = string.format("Finished. Killed %d police.", Killed),
				Icon = "check",
				Duration = 3,
			})
		end)
	end
end

NState.Weapons = NState.Assets:FindFirstChild("Weapons")
NState.Backpack = NState.LocalPlayer:WaitForChild("Backpack", math.huge)

NState.applyAllWeaponModifications = function()
	if not NState.Environment.NotorietyWeaponEnabled then
		return
	end

	for _, Container in {
		NState.Weapons,
		NState.Backpack,
		NState.LocalPlayer.Character,
	} do
		if Container then
			for _, Object in Container:GetDescendants() do
				NState.applyWeaponModule(Object)
			end
		end
	end

	NState.patchLoadedWeaponTables()
end

NState.refreshWeaponModifications = function()
	NState.restoreRuntimeSilentAimWrappers()
	NState.restoreAllWeaponData()
	NState.restoreRuntimeWeaponAccuracy()
	NState.restoreRuntimeWeaponRecoil()
	NState.restoreAllAmmoWrappers()

	if NState.Environment.NotorietyWeaponEnabled then
		NState.applyAllWeaponModifications()
	end
end

NState.setWeaponModificationsEnabled = function(Enabled)
	NState.Environment.NotorietyWeaponEnabled = Enabled == true
	NState.refreshWeaponModifications()
end

NState.ItemESPColors = {
	LOOT = Color3.fromRGB(255, 215, 50),
	ITEM = Color3.fromRGB(60, 210, 255),
	KEY = Color3.fromRGB(210, 80, 255),
	CONTAINER = Color3.fromRGB(255, 125, 45),
	CAMERA = Color3.fromRGB(255, 50, 50),
	SECURITY = Color3.fromRGB(255, 65, 145),
	ACCESS = Color3.fromRGB(140, 105, 255),
	ESCAPE = Color3.fromRGB(70, 255, 130),
}

NState.ItemESPState = {
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

NState.isItemESPCategoryEnabled = function(Category)
	local Categories = NState.Environment.NotorietyItemESPCategories
	return type(Categories) ~= "table" or Categories[Category] ~= false
end

NState.containsItemESPWord = function(Text, Words)
	Text = string.lower(Text)

	for _, Word in Words do
		if string.find(Text, Word, 1, true) then
			return true
		end
	end

	return false
end

NState.loadInteractionDefinitions = function()
	if type(NState.ItemESPState.Definitions) == "table" then
		return NState.ItemESPState.Definitions
	end

	local ReplicatedScripts = NState.RS_Package:FindFirstChild("ReplicatedScripts")
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

	NState.ItemESPState.Definitions = Definitions

	return Definitions
end

NState.resolveItemESPInteraction = function(Prompt)
	local Definitions = NState.loadInteractionDefinitions()

	if not Definitions then
		return nil
	end

	local Object = Prompt.Parent

	while Object and Object ~= NState.Workspace do
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

NState.classifyItemESPInteraction = function(Prompt, Key, Data)
	local PromptAction = string.upper(Prompt.ActionText or "")
	local KeyLower = string.lower(Key)
	local RegistryAction = string.lower(Data.actiontext or "")
	local Searchable = KeyLower .. " " .. RegistryAction

	if PromptAction == "SECURE"
		or NState.containsItemESPWord(KeyLower, {
			"safespot",
			"escapecrate",
		})
	then
		return "ESCAPE"
	end

	if NState.containsItemESPWord(Searchable, {
		"electrical box",
		"power box",
		"camera box",
		"camera feed",
		"rushhourelectricalbox",
	}) then
		return "SECURITY"
	end

	if NState.containsItemESPWord(KeyLower, {
		"cardreader",
		"card reader",
		"wirecutterfence",
		"acunitcover",
	}) or PromptAction == "INSERT" or PromptAction == "UNLOCK" then
		return "ACCESS"
	end

	if NState.containsItemESPWord(KeyLower, {
		"keycard",
		"key card",
		"accesspass",
		"access pass",
	}) then
		return "KEY"
	end

	if NState.containsItemESPWord(KeyLower, {
		"crowbar",
		"wirecutters",
		"thermal drill",
		"drill bag",
	}) then
		return "ITEM"
	end

	if PromptAction == "DISABLE" or NState.containsItemESPWord(KeyLower, {
		"camera",
	}) then
		return "CAMERA"
	end

	if PromptAction == "START DRILL"
		or NState.containsItemESPWord(KeyLower, {
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

	if NState.containsItemESPWord(RegistryAction, {
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

NState.resolveItemESPBox = function(Object)
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

NState.removeItemESPObject = function(Object)
	local Entry = NState.ItemESPState.Tracked[Object]

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

	NState.ItemESPState.Tracked[Object] = nil
end

NState.resolveESPMaxDistance = function(Value, DefaultValue)
	local Distance = tonumber(Value)

	if Distance == nil or Distance ~= Distance or Distance == math.huge or Distance == -math.huge then
		Distance = DefaultValue or 2500
	end

	Distance = math.clamp(Distance, 0, 10000)
	return Distance <= 0 and math.huge or Distance
end

NState.addItemESPObject = function(Category, Object)
	if not Category or not Object or not NState.isItemESPCategoryEnabled(Category) then
		return
	end

	local ExistingEntry = NState.ItemESPState.Tracked[Object]

	if ExistingEntry then
		return
	end

	local Folder = NState.ItemESPState.Folder
	local Color = NState.ItemESPColors[Category]

	if not Folder or not Folder.Parent or not Color then
		return
	end

	local Adornee, Size, BoxCFrame = NState.resolveItemESPBox(Object)

	if not Adornee then
		return
	end

	local Box = NState.ServiceResolver.ns("BoxHandleAdornment")

	if not Box then
		return
	end

	Box.Name = Category .. "_Box"
	Box.Adornee = Adornee
	Box.Size = Size
	Box.CFrame = BoxCFrame
	Box.Color3 = Color
	Box.Transparency = math.clamp((tonumber(NState.Environment.NotorietyItemESPTransparency) or 55) / 100, 0, 1)
	Box.AlwaysOnTop = true
	Box.ZIndex = 10
	Box.Parent = Folder

	local Label

	if NState.Environment.NotorietyItemESPLabels then
		Label = NState.ServiceResolver.ns("BillboardGui")

		if Label then
			Label.Name = Category .. "_Label"
			Label.Adornee = Adornee
			Label.AlwaysOnTop = true
			Label.Size = UDim2.fromOffset(220, 30)
			Label.StudsOffsetWorldSpace = Vector3.new(0, math.max(Size.Y * 0.5 + 1, 2), 0)
			Label.MaxDistance = NState.resolveESPMaxDistance(NState.Environment.NotorietyItemESPMaxDistance, 2500)
			Label.Parent = Folder

			local Text = NState.ServiceResolver.ns("TextLabel")

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
			NState.removeItemESPObject(Object)
		end
	end)

	NState.ItemESPState.Tracked[Object] = {
		Category = Category,
		Adornee = Adornee,
		Box = Box,
		Label = Label,
		Connection = AncestryConnection,
	}
end

NState.updateItemESPVisibility = function()
	local Character = NState.LocalPlayer.Character
	local Root = Character and Character:FindFirstChild("HumanoidRootPart")
	local MaxDistance = NState.resolveESPMaxDistance(NState.Environment.NotorietyItemESPMaxDistance, 2500)
	local Transparency = math.clamp((tonumber(NState.Environment.NotorietyItemESPTransparency) or 55) / 100, 0, 1)

	for Object, Entry in NState.ItemESPState.Tracked do
		local Adornee = Entry.Adornee
		local Visible = NState.isItemESPCategoryEnabled(Entry.Category)

		if Visible and Root and typeof(Adornee) == "Instance" and Adornee:IsA("BasePart") then
			Visible = (Root.Position - Adornee.Position).Magnitude <= MaxDistance
		end

		if Entry.Box then
			Entry.Box.Visible = Visible
			Entry.Box.Transparency = Transparency
		end

		if Entry.Label then
			Entry.Label.Enabled = Visible and NState.Environment.NotorietyESPTextEnabled and NState.Environment.NotorietyItemESPLabels
			Entry.Label.MaxDistance = MaxDistance
		end

		if not Object.Parent
			or typeof(Adornee) ~= "Instance"
			or not Adornee.Parent
		then
			NState.removeItemESPObject(Object)
		end
	end
end

NState.inspectItemESPPrompt = function(Prompt)
	if NState.Environment.NotorietyUnloaded
		or not NState.Environment.NotorietyItemESPEnabled
		or not Prompt:IsA("ProximityPrompt")
		or not Prompt:IsDescendantOf(NState.Workspace)
	then
		return
	end

	local CurrentCamera = NState.Workspace.CurrentCamera

	if CurrentCamera and Prompt:IsDescendantOf(CurrentCamera) then
		return
	end

	local Object, Key, Data = NState.resolveItemESPInteraction(Prompt)

	if not Object then
		return
	end

	local Category = NState.classifyItemESPInteraction(Prompt, Key, Data)

	NState.addItemESPObject(Category, Object)
end

NState.stopItemESP = function()
	for _, Connection in NState.ItemESPState.Connections do
		pcall(function()
			Connection:Disconnect()
		end)
	end

	table.clear(NState.ItemESPState.Connections)
	table.clear(NState.ItemESPState.ScanList)
	NState.ItemESPState.ScanCursor = 1
	NState.ItemESPState.Rescan = 0
	NState.ItemESPState.ScanRefresh = 0

	local Objects = {}

	for Object in NState.ItemESPState.Tracked do
		table.insert(Objects, Object)
	end

	for _, Object in Objects do
		NState.removeItemESPObject(Object)
	end

	local Folder = NState.ItemESPState.Folder
	NState.ItemESPState.Folder = nil

	if Folder then
		pcall(function()
			Folder:Destroy()
		end)
	end
end

NState.resolveESPParent = function()
	return NState.resolveProtectedUIParent() or NState.LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

NState.startItemESP = function()
	NState.stopItemESP()

	if not NState.loadInteractionDefinitions() then
		warn("Item ESP could not load InteractList")
		return false
	end

	local Folder = NState.ServiceResolver.ns("Folder")

	if not Folder then
		return false
	end

	Folder.Name = "NotorietyItemESP"
	Folder.Archivable = false
	local Parent = NState.resolveESPParent()
	local ParentSuccess = typeof(Parent) == "Instance" and pcall(function()
		Folder.Parent = Parent
	end)

	if not ParentSuccess then
		pcall(function()
			Folder:Destroy()
		end)
		return false
	end

	NState.ItemESPState.Folder = Folder
	NState.ItemESPState.ScanList = NState.CollectionService:GetTagged("Prompt")
	NState.ItemESPState.ScanCursor = 1
	NState.ItemESPState.Rescan = 0
	NState.ItemESPState.ScanRefresh = 0

	for _, Prompt in NState.ItemESPState.ScanList do
		NState.inspectItemESPPrompt(Prompt)
	end

	table.insert(
		NState.ItemESPState.Connections,
		NState.CollectionService:GetInstanceAddedSignal("Prompt"):Connect(NState.inspectItemESPPrompt)
	)
	return true
end

NState.setItemESPEnabled = function(Enabled)
	NState.Environment.NotorietyItemESPEnabled = Enabled == true

	if NState.Environment.NotorietyItemESPEnabled then
		if not NState.startItemESP() then
			NState.Environment.NotorietyItemESPEnabled = false
		end
	else
		NState.stopItemESP()
	end
end

NState.ItemESPController = {}

function NState.ItemESPController.Cleanup()
	NState.Environment.NotorietyItemESPEnabled = false
	NState.stopItemESP()
end

NState.Environment.NotorietyItemESPController = NState.ItemESPController

NState.PoliceESPState = {
	Folder = nil,
	PoliceFolder = nil,
	Connections = {},
	Tracked = setmetatable({}, { __mode = "k" }),
	Refresh = 0,
	Rescan = 0,
	ScanCursor = 1,
}

NState.removePoliceESP = function(Model)
	local Entry = NState.PoliceESPState.Tracked[Model]

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

	NState.PoliceESPState.Tracked[Model] = nil
end

NState.addPoliceESP = function(Model)
	if not NState.Environment.NotorietyPoliceESPEnabled
		or typeof(Model) ~= "Instance"
		or not Model:IsA("Model")
		or NState.PoliceESPState.Tracked[Model]
	then
		return
	end

	local Humanoid = Model:FindFirstChildWhichIsA("Humanoid", true)
	local Head = Model:FindFirstChild("Head", true)
	local Root = Model:FindFirstChild("HumanoidRootPart", true) or Head

	if not Humanoid or not Root or not Root:IsA("BasePart") then
		return
	end

	local Folder = NState.PoliceESPState.Folder

	if not Folder then
		return
	end

	local Highlight = NState.ServiceResolver.ns("Highlight")
	local Label = NState.ServiceResolver.ns("BillboardGui")
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
		Label.MaxDistance = NState.resolveESPMaxDistance(NState.Environment.NotorietyPoliceESPMaxDistance, 2500)
		Label.Parent = Folder

		Text = NState.ServiceResolver.ns("TextLabel")

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

		if NState.Environment.NotorietyPoliceESPNames then
			Parts[#Parts + 1] = Model.Name
		end

		if NState.Environment.NotorietyPoliceESPHealth then
			Parts[#Parts + 1] = string.format("%d HP", math.max(math.floor(Humanoid.Health + 0.5), 0))
		end

		Text.Text = table.concat(Parts, " • ")
		Label.Enabled = NState.Environment.NotorietyESPTextEnabled and #Parts > 0
	end

	Connections[#Connections + 1] = Humanoid.HealthChanged:Connect(refreshText)
	Connections[#Connections + 1] = Model.AncestryChanged:Connect(function(_, Parent)
		if not Parent then NState.removePoliceESP(Model) end
	end)

	NState.PoliceESPState.Tracked[Model] = {
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

NState.stopPoliceESP = function()
	for _, Connection in NState.PoliceESPState.Connections do
		pcall(function() Connection:Disconnect() end)
	end
	table.clear(NState.PoliceESPState.Connections)

	local Models = {}
	for Model in NState.PoliceESPState.Tracked do Models[#Models + 1] = Model end
	for _, Model in Models do NState.removePoliceESP(Model) end

	if NState.PoliceESPState.Folder then
		pcall(function() NState.PoliceESPState.Folder:Destroy() end)
	end

	NState.PoliceESPState.Folder = nil
	NState.PoliceESPState.PoliceFolder = nil
	NState.PoliceESPState.Rescan = 0
	NState.PoliceESPState.ScanCursor = 1
end

NState.startPoliceESP = function()
	NState.stopPoliceESP()

	local PoliceFolder = NState.Workspace:FindFirstChild("Police")

	if not PoliceFolder then
		return false
	end

	local Folder = NState.ServiceResolver.ns("Folder")
	if not Folder then return false end
	Folder.Name = "NotorietyPoliceESP"
	Folder.Archivable = false

	local Parent = NState.resolveESPParent()
	local ParentSuccess = typeof(Parent) == "Instance" and pcall(function()
		Folder.Parent = Parent
	end)

	if not ParentSuccess then
		pcall(function()
			Folder:Destroy()
		end)
		return false
	end

	NState.PoliceESPState.Folder = Folder
	NState.PoliceESPState.PoliceFolder = PoliceFolder
	NState.PoliceESPState.Rescan = 0
	NState.PoliceESPState.ScanCursor = 1

	for _, Model in PoliceFolder:GetChildren() do NState.addPoliceESP(Model) end
	NState.PoliceESPState.Connections[#NState.PoliceESPState.Connections + 1] = PoliceFolder.ChildAdded:Connect(function(Model)
		task.defer(NState.addPoliceESP, Model)
	end)
	NState.PoliceESPState.Connections[#NState.PoliceESPState.Connections + 1] = PoliceFolder.DescendantAdded:Connect(function(Descendant)
		local Model = Descendant

		while Model and Model.Parent ~= PoliceFolder do
			Model = Model.Parent
		end

		if Model and Model:IsA("Model") and not NState.PoliceESPState.Tracked[Model] then
			task.defer(NState.addPoliceESP, Model)
		end
	end)
	return true
end

NState.updatePoliceESP = function()
	if not NState.Environment.NotorietyPoliceESPEnabled then return end

	local Character = NState.LocalPlayer.Character
	local LocalRoot = Character and Character:FindFirstChild("HumanoidRootPart")
	local MaxDistance = NState.resolveESPMaxDistance(NState.Environment.NotorietyPoliceESPMaxDistance, 2500)

	for Model, Entry in NState.PoliceESPState.Tracked do
		if not Model.Parent
			or not Entry.Humanoid
			or not Entry.Humanoid.Parent
			or not Entry.Root
			or not Entry.Root.Parent
		then
			NState.removePoliceESP(Model)
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

NState.setPoliceESPEnabled = function(Enabled)
	NState.Environment.NotorietyPoliceESPEnabled = Enabled == true
	if NState.Environment.NotorietyPoliceESPEnabled then
		if not NState.startPoliceESP() then NState.Environment.NotorietyPoliceESPEnabled = false end
	else
		NState.stopPoliceESP()
	end
end

NState.refreshPoliceESP = function()
	if NState.Environment.NotorietyPoliceESPEnabled then NState.startPoliceESP() end
end

NState.MusicOverrideState = {
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

NState.initializeMusicOverride = function()
	local ReplicatedScripts = NState.RS_Package:FindFirstChild("ReplicatedScripts")
	local MusicInfoModule = ReplicatedScripts and ReplicatedScripts:FindFirstChild("MusicInfo")

	if not MusicInfoModule then return end

	local Success, MusicInfo = pcall(require, MusicInfoModule)
	if not Success or type(MusicInfo) ~= "table" then return end
	NState.MusicOverrideState.MusicInfo = MusicInfo

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
			if Name ~= "Off" then NState.MusicOverrideState.Tracks[#NState.MusicOverrideState.Tracks + 1] = Name end
		end
	end
end

NState.getMusicFolder = function()
	local PlayerScripts = NState.LocalPlayer:FindFirstChild("PlayerScripts")
	local SPSPackage = PlayerScripts and PlayerScripts:FindFirstChild("SPS_Package")
	local Music = SPSPackage and SPSPackage:FindFirstChild("Music")
	if Music then NState.MusicOverrideState.Folder = Music end
	return Music
end

NState.getMusicTrackEntryValue = function(Entry)
	if typeof(Entry) == "table" then
		return Entry.SoundId or Entry.ModFilePath, Entry.ModFilePath
	end
	return Entry, nil
end

NState.isMusicTrackSelectionApplied = function(Track, Music)
	local MusicInfo = NState.MusicOverrideState.MusicInfo
	local Soundtracks = MusicInfo and MusicInfo.Soundtracks
	local TrackData = Soundtracks and Soundtracks[Track]

	if type(TrackData) ~= "table" then
		return false
	end

	local Checked = false
	for Name, Entry in TrackData do
		local Sound = Music:FindFirstChild(Name)
		if Sound and Sound:IsA("Sound") then
			local Expected, ModFilePath = NState.getMusicTrackEntryValue(Entry)
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

NState.applyMusicTrackSelection = function(Force)
	local Music = NState.getMusicFolder()
	if not Music then return false end

	local Track = tostring(NState.Environment.NotorietyMusicTrack or "Game Selection")

	if Track == "Game Selection" then
		NState.MusicOverrideState.LastAppliedTrack = nil
		return true
	end

	if not Force
		and NState.MusicOverrideState.LastAppliedTrack == Track
		and NState.isMusicTrackSelectionApplied(Track, Music)
	then
		return true
	end

	local Finalize = Music:FindFirstChild("FinalizeSoundtrack")
	if not Finalize or not Finalize:IsA("BindableEvent") then return false end
	Finalize:Fire(Track)
	NState.MusicOverrideState.LastAppliedTrack = Track
	return true
end

NState.getNativeMusicMode = function()
	local Status = NState.RS_Package:FindFirstChild("ReplicatedGameStatus")
	if not Status then return "Stealth" end
	local Assault = Status:FindFirstChild("PoliceAssault")
	local Anticipate = Status:FindFirstChild("Anticipate")
	local Caught = Status:FindFirstChild("Caught")
	if Assault and Assault.Value then return "Assault" end
	if Anticipate and Anticipate.Value then return "Anticipation" end
	if Caught and Caught.Value then return "Control" end
	return "Stealth"
end

NState.getForcedNativeMusicMode = function()
	local RequestedMode = tostring(NState.Environment.NotorietyMusicMode or "Follow Game")
	local ModeMap = {
		Stealth = "Stealth",
		Control = "Control",
		["Build Up"] = "Anticipation",
		Loud = "Assault",
	}
	return ModeMap[RequestedMode]
end

NState.remapMusicModeRequest = function(Mode)
	local ForcedMode = NState.getForcedNativeMusicMode()
	if not ForcedMode or type(Mode) ~= "string" then return Mode end

	if Mode == "Stealth" or Mode == "Control" or Mode == "Anticipation" or Mode == "Assault" then
		return ForcedMode
	end

	return Mode
end

NState.findGamePlaySoundtrackFunction = function()
	if type(NState.MusicOverrideState.PlaySoundtrackFunction) == "function" then
		return NState.MusicOverrideState.PlaySoundtrackFunction
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
				NState.MusicOverrideState.PlaySoundtrackFunction = Function
				return Function
			end
		end
	end
end

NState.installMusicModeHook = function()
	if NState.MusicOverrideState.HookInstalled
		and type(NState.MusicOverrideState.OriginalPlaySoundtrack) == "function"
	then
		return true
	end

	if type(hookfunction) ~= "function" then return false end
	local Target = NState.findGamePlaySoundtrackFunction()
	if type(Target) ~= "function" then return false end

	local Original
	local function Wrapped(Mode, ...)
		return Original(NState.remapMusicModeRequest(Mode), ...)
	end

	local Success, Result = pcall(hookfunction, Target, Wrapped)
	if not Success or type(Result) ~= "function" then return false end

	Original = Result
	NState.MusicOverrideState.OriginalPlaySoundtrack = Result
	NState.MusicOverrideState.WrappedPlaySoundtrack = Wrapped
	NState.MusicOverrideState.HookInstalled = true
	return true
end

NState.applyMusicModeOverride = function()
	NState.applyMusicTrackSelection(false)
	if not NState.installMusicModeHook() then return false end

	local Original = NState.MusicOverrideState.OriginalPlaySoundtrack
	if type(Original) ~= "function" then return false end

	local RequestedMode = tostring(NState.Environment.NotorietyMusicMode or "Follow Game")
	local TargetMode = RequestedMode == "Follow Game" and NState.getNativeMusicMode() or NState.getForcedNativeMusicMode()
	if not TargetMode then return false end

	task.spawn(function()
		pcall(Original, TargetMode)
	end)
	return true
end

NState.restoreNativeMusicMode = function()
	if not NState.installMusicModeHook() then return end
	local Original = NState.MusicOverrideState.OriginalPlaySoundtrack
	if type(Original) == "function" then
		local NativeMode = NState.getNativeMusicMode()
		task.spawn(function()
			pcall(Original, NativeMode)
		end)
	end
end

NState.restoreMusicModeHook = function()
	if NState.MusicOverrideState.HookInstalled
		and type(hookfunction) == "function"
		and type(NState.MusicOverrideState.PlaySoundtrackFunction) == "function"
		and type(NState.MusicOverrideState.OriginalPlaySoundtrack) == "function"
	then
		pcall(hookfunction, NState.MusicOverrideState.PlaySoundtrackFunction, NState.MusicOverrideState.OriginalPlaySoundtrack)
	end

	NState.MusicOverrideState.PlaySoundtrackFunction = nil
	NState.MusicOverrideState.OriginalPlaySoundtrack = nil
	NState.MusicOverrideState.WrappedPlaySoundtrack = nil
	NState.MusicOverrideState.HookInstalled = false
end

NState.initializeMusicOverride()

NState.createVibeUI = function()
	local UIAdapter = NState.NotorietyUI.Library
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

	NState.Environment.NotorietyWindow = Window
	NState.NotorietyUI.Window = Window

	local ConfigManager = Window.ConfigManager
	local ConfigName = "default"

	local SaveGeneration = 0

	local function saveVibeUIConfig()
		if NState.NotorietyUI.ConfigLoading or not NState.NotorietyUI.Config then
			return false
		end

		local Success, SaveError = pcall(function()
			return NState.NotorietyUI.Config:Save()
		end)

		if not Success then
			warn("[Notoriety] VibeUI config save failed: " .. tostring(SaveError))
			return false
		end

		return true
	end

	local function requestVibeUIConfigSave()
		if NState.NotorietyUI.ConfigLoading or not NState.NotorietyUI.Config then
			return
		end

		SaveGeneration += 1
		local Generation = SaveGeneration

		task.delay(0.12, function()
			if Generation ~= SaveGeneration
				or NState.NotorietyUI.ConfigLoading
				or not NState.NotorietyUI.Config
			then
				return
			end

			saveVibeUIConfig()
		end)
	end

	NState.NotorietyUI.SaveConfig = saveVibeUIConfig
	NState.NotorietyUI.RequestConfigSave = requestVibeUIConfigSave

	local MainTab = Window:Tab({
		Title = "Main",
		Icon = "house",
		Border = true,
	})

	MainTab:Toggle({
		Flag = "MaxEverything",
		Title = "Max Everything",
		Desc = "Keeps supported character values and finite supplies maxed",
		Value = NState.Environment.MaxEverythingEnabled,
		Callback = function(Enabled)
			NState.Environment.MaxEverythingEnabled = Enabled == true
			if NState.Environment.MaxEverythingEnabled then NState.Apply() end
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Button({
		Title = "Kill Police [P]",
		Desc = "Kills every currently spawned police NPC",
		Icon = "crosshair",
		Callback = function()
			task.spawn(NState.runKill)
		end,
	})

	local TeammateTargetValues = NState.getTeammatePickerValues()
	if not table.find(TeammateTargetValues, NState.Environment.NotorietyTeammateTarget) then
		NState.Environment.NotorietyTeammateTarget = "All"
	end

	NState.NotorietyUI.TeammateTargetDropdown = MainTab:Dropdown({
		Flag = "TeammateTarget",
		Title = "Teammate Target",
		Desc = "Pick All or a specific current teammate",
		Values = TeammateTargetValues,
		Value = NState.Environment.NotorietyTeammateTarget,
		Callback = function(Value)
			NState.Environment.NotorietyTeammateTarget = tostring(Value or "All")
			requestVibeUIConfigSave()
		end,
	})

	local function refreshTeammateTargetDropdown()
		if NState.Environment.NotorietyUnloaded then
			return
		end

		local Dropdown = NState.NotorietyUI.TeammateTargetDropdown
		if type(Dropdown) ~= "table" or type(Dropdown.Refresh) ~= "function" then
			return
		end

		local Values = NState.getTeammatePickerValues()
		Dropdown:Refresh(Values)

		if not table.find(Values, NState.Environment.NotorietyTeammateTarget) then
			NState.Environment.NotorietyTeammateTarget = "All"
			pcall(function()
				Dropdown:Set("All")
			end)
		end
	end

	local function queueTeammateTargetRefresh()
		task.defer(refreshTeammateTargetDropdown)
	end

	table.insert(NState.Environment.NotorietyUIConnections, NState.Players.PlayerAdded:Connect(queueTeammateTargetRefresh))
	table.insert(NState.Environment.NotorietyUIConnections, NState.Players.PlayerRemoving:Connect(queueTeammateTargetRefresh))

	local Criminals = NState.Workspace:FindFirstChild("Criminals")
	if Criminals then
		table.insert(NState.Environment.NotorietyUIConnections, Criminals.ChildAdded:Connect(queueTeammateTargetRefresh))
		table.insert(NState.Environment.NotorietyUIConnections, Criminals.ChildRemoved:Connect(queueTeammateTargetRefresh))
	end

	MainTab:Button({
		Title = "Kill Teammate(s)",
		Desc = "Uses the selected teammate target; All targets every current teammate",
		Icon = "user-x",
		Callback = function()
			task.spawn(NState.runKillTeammates, NState.Environment.NotorietyTeammateTarget)
		end,
	})

	MainTab:Toggle({
		Flag = "InfiniteYellMark",
		Title = "Infinite Yell / Mark",
		Desc = "Enables the selected custom yell / mark targeting method",
		Value = NState.Environment.NotorietyInfiniteYellMarkEnabled,
		Callback = function(Enabled)
			NState.setYellMarkPatchEnabled(Enabled)
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
		Value = NState.Environment.NotorietyYellMarkMethod,
		Callback = function(Method)
			NState.setYellMarkMethod(Method)
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Toggle({
		Flag = "YellThroughWalls",
		Title = "Yell / Mark Through Walls",
		Desc = "When disabled, Viewport and Whole Game require line of sight; Original always keeps the game's native visibility rules",
		Value = NState.Environment.NotorietyYellThroughWalls,
		Callback = function(Enabled)
			NState.setYellThroughWalls(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Toggle({
		Flag = "TeammateYellInfiniteRange",
		Title = "Boost / Inspire Infinite Range",
		Desc = "Custom Viewport/Whole Game modes can boost or inspire teammates beyond 100 studs; Original keeps the game's native behavior",
		Value = NState.Environment.NotorietyTeammateYellInfiniteRange,
		Callback = function(Enabled)
			NState.setTeammateYellInfiniteRange(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Toggle({
		Flag = "TeammateYellThroughWalls",
		Title = "Boost / Inspire Through Walls",
		Desc = "Custom Viewport/Whole Game modes can boost or inspire teammates through walls; Original keeps the game's native behavior",
		Value = NState.Environment.NotorietyTeammateYellThroughWalls,
		Callback = function(Enabled)
			NState.setTeammateYellThroughWalls(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Toggle({
		Flag = "AutoYell",
		Title = "Auto Yell",
		Desc = "Automatically yells new targets from the selected method without spamming unchanged custom targets",
		Value = NState.Environment.NotorietyAutoYellEnabled,
		Callback = function(Enabled)
			NState.YellPatchState.SetAutoYellEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Toggle({
		Flag = "NoYellDelay",
		Title = "No Yell / Mark Delay",
		Desc = "Removes the native 0.5 second client yell debounce without per-frame scanning",
		Value = NState.Environment.NotorietyNoYellDelayEnabled,
		Callback = function(Enabled)
			NState.YellPatchState.SetNoDelayEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	MainTab:Toggle({
		Flag = "PoliceHeadScaleEnabled",
		Title = "Police Head Scale",
		Desc = "Enlarges police head hitboxes",
		Value = NState.Environment.NotorietyPoliceHeadScaleEnabled,
		Callback = function(Enabled)
			NState.setPoliceHeadScaleEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	NState.NotorietyUI.PoliceHeadScaleSlider = MainTab:Slider({
		Flag = "PoliceHeadScale",
		Title = "Police Head Scale Amount",
		Desc = "Multiplier for police head size",
		Min = 1,
		Max = 20,
		Step = 1,
		Suffix = "x",
		Value = NState.Environment.NotorietyPoliceHeadScale,
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil then
				return
			end

			NState.Environment.NotorietyPoliceHeadScale = math.clamp(Number, 1, 20)

			if NState.Environment.NotorietyPoliceHeadScaleEnabled then
				NState.applyPoliceHeadScale()
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
		Value = NState.Environment.NotorietyESPTextEnabled,
		Callback = function(Enabled)
			NState.Environment.NotorietyESPTextEnabled = Enabled == true
			NState.updateItemESPVisibility()
			NState.updatePoliceESP()
			requestVibeUIConfigSave()
		end,
	})

	ESPTab:Toggle({
		Flag = "ItemESP",
		Title = "Item / Interaction ESP",
		Desc = "Highlights supported interactions and incrementally re-scans tagged prompts to catch late-loaded items",
		Value = NState.Environment.NotorietyItemESPEnabled,
		Callback = function(Enabled)
			NState.setItemESPEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	ESPTab:Toggle({
		Flag = "ItemESPLabels",
		Title = "Item ESP Text Details",
		Desc = "Controls item names/category text when the master ESP Text toggle is enabled",
		Value = NState.Environment.NotorietyItemESPLabels,
		Callback = function(Enabled)
			NState.Environment.NotorietyItemESPLabels = Enabled == true
			if NState.Environment.NotorietyItemESPEnabled and not NState.NotorietyUI.ConfigLoading then NState.startItemESP() end
			requestVibeUIConfigSave()
		end,
	})

	NState.NotorietyUI.ItemESPTransparencySlider = ESPTab:Slider({
		Flag = "ItemESPTransparency",
		Title = "Item Box Transparency",
		Desc = "0 = solid, 100 = invisible",
		Min = 0, Max = 100, Step = 1, Suffix = "%",
		Value = NState.Environment.NotorietyItemESPTransparency,
		Callback = function(Value)
			NState.Environment.NotorietyItemESPTransparency = math.clamp(tonumber(Value) or 55, 0, 100)
			NState.updateItemESPVisibility()
			requestVibeUIConfigSave()
		end,
	})

	NState.NotorietyUI.ItemESPDistanceSlider = ESPTab:Slider({
		Flag = "ItemESPDistance",
		Title = "Item ESP Distance",
		Desc = "Maximum display distance. 0 = infinite",
		Min = 0, Max = 10000, Step = 50, Suffix = " studs",
		Value = NState.Environment.NotorietyItemESPMaxDistance,
		Callback = function(Value)
			NState.Environment.NotorietyItemESPMaxDistance = math.clamp(tonumber(Value) or 2500, 0, 10000)
			NState.updateItemESPVisibility()
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
			Value = NState.Environment.NotorietyItemESPCategories[Category] ~= false,
			Callback = function(Enabled)
				NState.Environment.NotorietyItemESPCategories[Category] = Enabled == true
				if NState.Environment.NotorietyItemESPEnabled and not NState.NotorietyUI.ConfigLoading then NState.startItemESP() end
				requestVibeUIConfigSave()
			end,
		})
	end

	ESPTab:Toggle({
		Flag = "PoliceESP",
		Title = "Police ESP",
		Desc = "Highlights police through walls with event-driven late-load retries plus a bounded reconciliation scan",
		Value = NState.Environment.NotorietyPoliceESPEnabled,
		Callback = function(Enabled)
			NState.setPoliceESPEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	ESPTab:Toggle({
		Flag = "PoliceESPNames",
		Title = "Police Names",
		Value = NState.Environment.NotorietyPoliceESPNames,
		Callback = function(Enabled)
			NState.Environment.NotorietyPoliceESPNames = Enabled == true
			if not NState.NotorietyUI.ConfigLoading then NState.refreshPoliceESP() end
			requestVibeUIConfigSave()
		end,
	})

	ESPTab:Toggle({
		Flag = "PoliceESPHealth",
		Title = "Police Health",
		Value = NState.Environment.NotorietyPoliceESPHealth,
		Callback = function(Enabled)
			NState.Environment.NotorietyPoliceESPHealth = Enabled == true
			if not NState.NotorietyUI.ConfigLoading then NState.refreshPoliceESP() end
			requestVibeUIConfigSave()
		end,
	})

	NState.NotorietyUI.PoliceESPDistanceSlider = ESPTab:Slider({
		Flag = "PoliceESPDistance",
		Title = "Police ESP Distance",
		Desc = "Maximum display distance. 0 = infinite",
		Min = 0, Max = 10000, Step = 50, Suffix = " studs",
		Value = NState.Environment.NotorietyPoliceESPMaxDistance,
		Callback = function(Value)
			NState.Environment.NotorietyPoliceESPMaxDistance = math.clamp(tonumber(Value) or 2500, 0, 10000)
			NState.updatePoliceESP()
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
		Value = NState.Environment.NotorietyWeaponEnabled,
		Callback = function(Enabled)
			NState.setWeaponModificationsEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	local function addWeaponFeatureToggle(Flag, Title, Desc, EnvironmentKey)
		WeaponTab:Toggle({
			Flag = Flag,
			Title = Title,
			Desc = Desc,
			Value = NState.Environment[EnvironmentKey] == true,
			Callback = function(Enabled)
				NState.Environment[EnvironmentKey] = Enabled == true
				if not NState.NotorietyUI.ConfigLoading then NState.refreshWeaponModifications() end
				requestVibeUIConfigSave()
			end,
		})
	end

	WeaponTab:Toggle({
		Flag = "FriendlyFire",
		Title = "Friendly Fire",
		Desc = "Lets normal gunfire hit teammates; the toggle now forces the native FriendlyFire value to match the visible state",
		Value = NState.Environment.NotorietyFriendlyFireEnabled,
		Callback = function(Enabled)
			NState.setFriendlyFireEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	WeaponTab:Toggle({
		Flag = "SilentAim",
		Title = "Silent Aim",
		Desc = "Redirects each native gun shot toward the nearest enabled target group without moving the camera",
		Value = NState.Environment.NotorietySilentAimEnabled,
		Callback = function(Enabled)
			NState.Environment.NotorietySilentAimEnabled = Enabled == true
			if not NState.NotorietyUI.ConfigLoading then NState.refreshWeaponModifications() end
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
		Value = NState.Environment.NotorietyWallBangEnabled,
		Callback = function(Enabled)
			NState.Environment.NotorietyWallBangEnabled = Enabled == true
			if not NState.NotorietyUI.ConfigLoading then NState.refreshWeaponModifications() end
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

	NState.NotorietyUI.SilentAimFOVSlider = WeaponTab:Slider({
		Flag = "SilentAimFOV",
		Title = "Silent Aim FOV",
		Desc = "Maximum cursor distance in pixels. 0 = any on-screen enabled Silent Aim target",
		Min = 0,
		Max = 2000,
		Step = 1,
		Suffix = " px",
		Value = NState.Environment.NotorietySilentAimFOV,
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil then
				return
			end

			NState.Environment.NotorietySilentAimFOV = math.clamp(Number, 0, 2000)
			requestVibeUIConfigSave()
		end,
	})

	addWeaponFeatureToggle("RapidFire", "Rapid Fire", "Applies custom fire delay and bolt duration", "NotorietyRapidFireEnabled")
	addWeaponFeatureToggle("NoRecoil", "No Recoil", "Removes recoil, camera kick, shake, and pushback", "NotorietyNoRecoilEnabled")
	addWeaponFeatureToggle("InfiniteAmmo", "Infinite Ammo", "Keeps primary/secondary magazine and reserve ammo effectively infinite", "NotorietyInfiniteAmmoEnabled")
	addWeaponFeatureToggle("FullAuto", "Force Full Auto", "Forces supported guns into automatic fire mode", "NotorietyFullAutoEnabled")
	addWeaponFeatureToggle("AccuracyMod", "Accuracy Override", "Enables the custom accuracy slider independently of recoil", "NotorietyAccuracyModEnabled")

	NState.NotorietyUI.FireDelaySlider = WeaponTab:Slider({
		Flag = "FireDelay",
		Title = "Fire Delay",
		Desc = "Shot cooldown in seconds. Default: 0.01",
		Min = 0,
		Max = 1,
		Step = 0.001,
		Suffix = "s",
		Value = math.clamp(NState.Environment.NotorietyFireDelay, 0, 1),
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil then
				return
			end

			NState.Environment.NotorietyFireDelay = Number

			if NState.Environment.NotorietyWeaponEnabled and not NState.NotorietyUI.ConfigLoading then
				NState.refreshWeaponModifications()
			end

			requestVibeUIConfigSave()
		end,
	})

	NState.NotorietyUI.BoltDurationSlider = WeaponTab:Slider({
		Flag = "BoltDuration",
		Title = "Bolt Duration",
		Desc = "Bolt animation/tween duration in seconds. Default: 0.001",
		Min = 0,
		Max = 1,
		Step = 0.001,
		Suffix = "s",
		Value = math.clamp(NState.Environment.NotorietyBoltDuration, 0, 1),
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil then
				return
			end

			NState.Environment.NotorietyBoltDuration = Number

			if NState.Environment.NotorietyWeaponEnabled and not NState.NotorietyUI.ConfigLoading then
				NState.refreshWeaponModifications()
			end

			requestVibeUIConfigSave()
		end,
	})

	NState.NotorietyUI.AccuracySlider = WeaponTab:Slider({
		Flag = "GunAccuracy",
		Title = "Gun Accuracy",
		Desc = "0-100, default: 100. Updates live weapon spread immediately.",
		Min = 0,
		Max = 100,
		Step = 1,
		Suffix = "%",
		Value = NState.Environment.NotorietyAccuracy,
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil then
				return
			end

			Number = math.clamp(Number, 0, 100)
			NState.Environment.NotorietyAccuracy = Number

			if NState.Environment.NotorietyWeaponEnabled and not NState.NotorietyUI.ConfigLoading then
				NState.refreshWeaponModifications()
			end

			requestVibeUIConfigSave()
		end,
	})

	WeaponTab:Button({
		Title = "Reset Weapon Defaults",
		Desc = "Fire Delay = 0.01, Bolt Duration = 0.001, Accuracy = 100",
		Icon = "rotate-ccw",
		Callback = function()
			NState.Environment.NotorietyFireDelay = 0.01
			NState.Environment.NotorietyBoltDuration = 0.001
			NState.Environment.NotorietyAccuracy = 100

			pcall(function()
				NState.NotorietyUI.FireDelaySlider:Set(0.01)
			end)
			pcall(function()
				NState.NotorietyUI.BoltDurationSlider:Set(0.001)
			end)
			pcall(function()
				NState.NotorietyUI.AccuracySlider:Set(100)
			end)

			if NState.Environment.NotorietyWeaponEnabled and not NState.NotorietyUI.ConfigLoading then
				NState.refreshWeaponModifications()
			end

			requestVibeUIConfigSave()
		end,
	})

	local MutatorsTab = Window:Tab({
		Title = "Mutators",
		Icon = "flask-conical",
		Border = true,
	})

	MutatorsTab:Toggle({
		Flag = "RealismMode",
		Title = "Tactical / Realism Mode",
		Desc = "Activates the client-observed RealismMode branches: no armor regeneration/iFrames, hidden native highlights, and 8x default headshots. Server-only Tactical Mode effects are not faked",
		Value = NState.Environment.NotorietyRealismModeEnabled,
		Callback = function(Enabled)
			NState.setRealismModeEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	MutatorsTab:Toggle({
		Flag = "BugFeature",
		Title = "Legacy Glitches / Bug Feature",
		Desc = "Activates the client-backed BugFeature mutator and enables the native SAW/Chainsaw jump-part collision behavior, including already spawned weapon models",
		Value = NState.Environment.NotorietyBugFeatureEnabled,
		Callback = function(Enabled)
			NState.setBugFeatureEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

	MutatorsTab:Button({
		Title = "Refresh Client Mutators",
		Desc = "Re-applies enabled client mutators and rescans runtime SAW/Chainsaw parts",
		Icon = "refresh-cw",
		Callback = function()
			NState.setRealismModeEnabled(NState.Environment.NotorietyRealismModeEnabled)
			NState.setBugFeatureEnabled(NState.Environment.NotorietyBugFeatureEnabled)
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
		Values = NState.MusicOverrideState.Tracks,
		Value = table.find(NState.MusicOverrideState.Tracks, NState.Environment.NotorietyMusicTrack) and NState.Environment.NotorietyMusicTrack or "Game Selection",
		Callback = function(Value)
			NState.Environment.NotorietyMusicTrack = tostring(Value or "Game Selection")
			NState.MusicOverrideState.LastAppliedTrack = nil
			if not NState.NotorietyUI.ConfigLoading then
				NState.applyMusicTrackSelection(true)
				NState.applyMusicModeOverride()
			end
			requestVibeUIConfigSave()
		end,
	})

	AudioTab:Dropdown({
		Flag = "MusicMode",
		Title = "Force Music Mode",
		Desc = "Changes only the local soundtrack layer. Example: Loud music can play while the actual heist remains in Stealth",
		Values = { "Follow Game", "Stealth", "Control", "Build Up", "Loud" },
		Value = NState.Environment.NotorietyMusicMode,
		Callback = function(Value)
			local Previous = NState.Environment.NotorietyMusicMode
			NState.Environment.NotorietyMusicMode = tostring(Value or "Follow Game")
			if not NState.NotorietyUI.ConfigLoading then
				if NState.Environment.NotorietyMusicMode == "Follow Game" and Previous ~= "Follow Game" then
					NState.restoreNativeMusicMode()
				else
					NState.applyMusicModeOverride()
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
			Value = math.clamp(tonumber(NState.Environment[EnvironmentKey]) or 100, 0, 100),
			Callback = function(Value)
				local Number = tonumber(Value)

				if Number == nil or Number ~= Number then
					return
				end

				NState.Environment[EnvironmentKey] = math.clamp(Number, 0, 100)
				NState.applyAudioVolumes()
				requestVibeUIConfigSave()
			end,
		})
	end

	NState.NotorietyUI.MusicVolumeSlider = addAudioSlider(
		"MusicVolume",
		"Music Volume",
		"Heist/background music only",
		"NotorietyMusicVolume"
	)
	NState.NotorietyUI.LocalGunshotsVolumeSlider = addAudioSlider(
		"LocalGunshotsVolume",
		"Your Gunshots",
		"Local weapon firing audio. Set to 0% to mute your shots without muting music",
		"NotorietyLocalGunshotsVolume"
	)
	NState.NotorietyUI.GunshotsVolumeSlider = addAudioSlider(
		"GunshotsVolume",
		"Other Gunshots",
		"World/NPC/other-player gunfire",
		"NotorietyGunshotsVolume"
	)
	NState.NotorietyUI.SFXVolumeSlider = addAudioSlider(
		"SFXVolume",
		"All SFX",
		"Master multiplier for grouped and ungrouped runtime SFX",
		"NotorietySFXVolume"
	)
	NState.NotorietyUI.MapAmbienceVolumeSlider = addAudioSlider(
		"MapAmbienceVolume",
		"Map Ambience",
		"Environmental map loops, including ungrouped map sounds",
		"NotorietyMapAmbienceVolume"
	)
	NState.NotorietyUI.VoicesVolumeSlider = addAudioSlider(
		"VoicesVolume",
		"Voices",
		"Character, narrator, and police voice audio",
		"NotorietyVoicesVolume"
	)
	NState.NotorietyUI.UIVolumeSlider = addAudioSlider(
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
			NState.Environment.NotorietyMusicVolume = 100
			NState.Environment.NotorietySFXVolume = 100
			NState.Environment.NotorietyLocalGunshotsVolume = 100
			NState.Environment.NotorietyGunshotsVolume = 100
			NState.Environment.NotorietyMapAmbienceVolume = 100
			NState.Environment.NotorietyVoicesVolume = 100
			NState.Environment.NotorietyUIVolume = 100

			for _, Slider in {
				NState.NotorietyUI.MusicVolumeSlider,
				NState.NotorietyUI.SFXVolumeSlider,
				NState.NotorietyUI.LocalGunshotsVolumeSlider,
				NState.NotorietyUI.GunshotsVolumeSlider,
				NState.NotorietyUI.MapAmbienceVolumeSlider,
				NState.NotorietyUI.VoicesVolumeSlider,
				NState.NotorietyUI.UIVolumeSlider,
			} do
				pcall(function()
					Slider:Set(100)
				end)
			end

			NState.applyAudioVolumes()
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
		Value = NState.Environment.NotorietyEquipmentSpeedEnabled,
		Callback = function(Enabled)
			NState.Environment.NotorietyEquipmentSpeedEnabled = Enabled == true
			NState.applyEquipmentPlacementSpeed()
			requestVibeUIConfigSave()
		end,
	})

	EquipmentTab:Toggle({
		Flag = "EquipmentInstantEnabled",
		Title = "Instant Equipment Placement",
		Desc = "Keeps the game\'s native 0.5s hold delay, then completes placement immediately",
		Value = NState.Environment.NotorietyEquipmentInstantEnabled,
		Callback = function(Enabled)
			NState.Environment.NotorietyEquipmentInstantEnabled = Enabled == true
			NState.applyEquipmentPlacementSpeed()
			requestVibeUIConfigSave()
		end,
	})

	NState.NotorietyUI.EquipmentSpeedSlider = EquipmentTab:Slider({
		Flag = "EquipmentSpeedMultiplier",
		Title = "Placement Speed",
		Desc = "Default: 2x. Use 1 for normal speed",
		Min = 1,
		Max = 10,
		Step = 0.1,
		Suffix = "x",
		Value = math.clamp(NState.Environment.NotorietyEquipmentSpeedMultiplier, 1, 10),
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil
				or Number <= 0
				or Number == math.huge
				or Number ~= Number
			then
				return
			end

			NState.Environment.NotorietyEquipmentSpeedMultiplier = Number

			if NState.Environment.NotorietyEquipmentSpeedEnabled then
				NState.applyEquipmentPlacementSpeed()
			end

			requestVibeUIConfigSave()
		end,
	})

	EquipmentTab:Button({
		Title = "Reset Placement Speed",
		Desc = "Resets the multiplier to 2x",
		Icon = "rotate-ccw",
		Callback = function()
			NState.Environment.NotorietyEquipmentSpeedMultiplier = 2

			pcall(function()
				NState.NotorietyUI.EquipmentSpeedSlider:Set(2)
			end)

			if NState.Environment.NotorietyEquipmentSpeedEnabled then
				NState.applyEquipmentPlacementSpeed()
			end

			requestVibeUIConfigSave()
		end,
	})

	EquipmentTab:Toggle({
		Flag = "InfiniteEquipment",
		Title = "Infinite Equipment",
		Desc = "Keeps primary and secondary equipment uses full independently of Max Everything",
		Value = NState.Environment.NotorietyInfiniteEquipmentEnabled,
		Callback = function(Enabled)
			NState.Environment.NotorietyInfiniteEquipmentEnabled = Enabled == true
			NState.Apply()
			requestVibeUIConfigSave()
		end,
	})

	EquipmentTab:Toggle({
		Flag = "EquipmentRangeEnabled",
		Title = "Extended Placement Range",
		Desc = "Extends the equipment placement ray beyond the normal 10 studs",
		Value = NState.Environment.NotorietyEquipmentRangeEnabled,
		Callback = function(Enabled)
			NState.Environment.NotorietyEquipmentRangeEnabled = Enabled == true
			NState.applyEquipmentPlacementRange()
			requestVibeUIConfigSave()
		end,
	})

	NState.NotorietyUI.EquipmentRangeSlider = EquipmentTab:Slider({
		Flag = "EquipmentPlacementRange",
		Title = "Placement Range",
		Desc = "Game default: 10 studs",
		Min = 10,
		Max = 100,
		Step = 1,
		Suffix = " studs",
		Value = math.clamp(NState.Environment.NotorietyEquipmentPlacementRange, 10, 100),
		Callback = function(Value)
			local Number = tonumber(Value)
			if Number == nil or Number ~= Number then return end
			NState.Environment.NotorietyEquipmentPlacementRange = math.clamp(Number, 10, 100)
			NState.applyEquipmentPlacementRange()
			requestVibeUIConfigSave()
		end,
	})

	EquipmentTab:Toggle({
		Flag = "EquipmentPositionEnabled",
		Title = "Custom Equipment Position",
		Desc = "Offsets the preview and final placement position",
		Value = NState.Environment.NotorietyEquipmentPositionEnabled,
		Callback = function(Enabled)
			NState.Environment.NotorietyEquipmentPositionEnabled = Enabled == true
			NState.applyEquipmentPositioning()
			requestVibeUIConfigSave()
		end,
	})

	NState.NotorietyUI.EquipmentPositionXSlider = EquipmentTab:Slider({
		Flag = "EquipmentPositionX",
		Title = "Left / Right Offset",
		Desc = "Positive = right, negative = left",
		Min = -50,
		Max = 50,
		Step = 0.5,
		Suffix = " studs",
		Value = math.clamp(NState.Environment.NotorietyEquipmentPositionX, -50, 50),
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil or Number == math.huge or Number == -math.huge or Number ~= Number then
				return
			end

			NState.Environment.NotorietyEquipmentPositionX = Number
			requestVibeUIConfigSave()
		end,
	})

	NState.NotorietyUI.EquipmentPositionYSlider = EquipmentTab:Slider({
		Flag = "EquipmentPositionY",
		Title = "Up / Down Offset",
		Desc = "Positive = up, negative = down",
		Min = -50,
		Max = 50,
		Step = 0.5,
		Suffix = " studs",
		Value = math.clamp(NState.Environment.NotorietyEquipmentPositionY, -50, 50),
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil or Number == math.huge or Number == -math.huge or Number ~= Number then
				return
			end

			NState.Environment.NotorietyEquipmentPositionY = Number
			requestVibeUIConfigSave()
		end,
	})

	NState.NotorietyUI.EquipmentPositionZSlider = EquipmentTab:Slider({
		Flag = "EquipmentPositionZ",
		Title = "Forward / Back Offset",
		Desc = "Positive = forward, negative = back",
		Min = -50,
		Max = 50,
		Step = 0.5,
		Suffix = " studs",
		Value = math.clamp(NState.Environment.NotorietyEquipmentPositionZ, -50, 50),
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil or Number == math.huge or Number == -math.huge or Number ~= Number then
				return
			end

			NState.Environment.NotorietyEquipmentPositionZ = Number
			requestVibeUIConfigSave()
		end,
	})

	EquipmentTab:Button({
		Title = "Reset Equipment Position",
		Desc = "Resets X, Y, and Z offsets to 0",
		Icon = "rotate-ccw",
		Callback = function()
			NState.Environment.NotorietyEquipmentPositionX = 0
			NState.Environment.NotorietyEquipmentPositionY = 0
			NState.Environment.NotorietyEquipmentPositionZ = 0

			pcall(function()
				NState.NotorietyUI.EquipmentPositionXSlider:Set(0)
			end)
			pcall(function()
				NState.NotorietyUI.EquipmentPositionYSlider:Set(0)
			end)
			pcall(function()
				NState.NotorietyUI.EquipmentPositionZSlider:Set(0)
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
				if type(NState.Environment.UnloadNotoriety) == "function" then
					NState.Environment.UnloadNotoriety()
				end
			end)
		end,
	})

	if type(ConfigManager) == "table" then
		local Configs = ConfigManager:AllConfigs()
		local Config = ConfigManager:Config(ConfigName)

		Window.CurrentConfig = Config
		NState.NotorietyUI.Config = Config
		NState.NotorietyUI.ConfigLoading = true

		if table.find(Configs, ConfigName) then
			pcall(function()
				Config:Load()
			end)
		else
			pcall(function()
				Config:Save()
			end)
		end

		NState.NotorietyUI.ConfigLoading = false
	end

	pcall(function()
		NState.ContextActionService:UnbindAction("NotorietyKillPolice")
	end)

	NState.ContextActionService:BindActionAtPriority(
		"NotorietyKillPolice",
		function(_, InputState)
			if InputState == Enum.UserInputState.Begin and not NState.Environment.NotorietyUnloaded then
				task.spawn(NState.runKill)
			end

			return Enum.ContextActionResult.Pass
		end,
		false,
		Enum.ContextActionPriority.High.Value + 1,
		Enum.KeyCode.P
	)
end

NState.disconnectConnection = function(Connection)
	if Connection then
		pcall(function()
			Connection:Disconnect()
		end)
	end
end

NState.disconnectConnections = function(Connections)
	if type(Connections) ~= "table" then
		return
	end

	for _, Connection in Connections do
		NState.disconnectConnection(Connection)
	end

	table.clear(Connections)
end

NState.unloadNotoriety = function()
	if NState.Environment.NotorietyUnloaded then
		return
	end

	if type(NState.NotorietyUI.SaveConfig) == "function" then
		NState.NotorietyUI.SaveConfig()
	end

	NState.Environment.NotorietyUnloaded = true
	NState.Environment.MaxEverythingEnabled = false
	NState.Environment.NotorietyWeaponEnabled = false
	NState.Environment.NotorietyFriendlyFireEnabled = false
	NState.Environment.NotorietyRealismModeEnabled = false
	NState.Environment.NotorietyBugFeatureEnabled = false
	NState.Environment.NotorietySilentAimEnabled = false
	NState.Environment.NotorietyWallBangEnabled = false
	NState.Environment.NotorietyItemESPEnabled = false
	NState.Environment.NotorietyPoliceESPEnabled = false
	NState.Environment.NotorietyPoliceHeadScaleEnabled = false
	NState.Environment.NotorietyInfiniteYellMarkEnabled = false
	NState.Environment.NotorietyAutoYellEnabled = false
	NState.Environment.NotorietyNoYellDelayEnabled = false
	NState.Environment.KillPoliceRunning = false
	NState.Environment.KillTeammatesRunning = false

	pcall(function()
		NState.ContextActionService:UnbindAction("NotorietyKillPolice")
	end)

	NState.disconnectConnection(NState.Environment.MaxEverythingConnection)
	NState.disconnectConnection(NState.Environment.MaxEverythingCharacterConnection)
	NState.disconnectConnection(NState.Environment.NotorietyPoliceHitboxConnection)

	NState.Environment.MaxEverythingConnection = nil
	NState.Environment.MaxEverythingCharacterConnection = nil
	NState.Environment.NotorietyPoliceHitboxConnection = nil

	NState.disconnectConnections(NState.Environment.NotorietyWeaponConnections)
	NState.disconnectConnections(NState.Environment.NotorietyUIConnections)

	if type(NState.Environment.NotorietyGetAmmoWrappers) == "table" then
		for State, Record in NState.Environment.NotorietyGetAmmoWrappers do
			if type(State) == "table" and type(Record) == "table" then
				local Original = Record.Original
				local Wrapper = Record.Wrapper

				if type(Original) == "function" and State.getAmmo == Wrapper then
					State.getAmmo = Original
				end
			end
		end
	end

	NState.restoreFriendlyFire()
	NState.restoreClientMutators()
	NState.restoreRuntimeSilentAimWrappers()
	NState.restoreAllWeaponData()
	NState.restoreRuntimeWeaponAccuracy()
	NState.restoreRuntimeWeaponRecoil()
	NState.restoreAllAmmoWrappers()
	NState.restoreEquipmentPlacementSpeed()
	NState.restoreMobileEquipmentPlacementFix()
	NState.restoreAudioVolumes()
	NState.restoreYellMarkPatch()
	NState.YellPatchState.ClearNoDelayConnections()
	table.clear(NState.YellPatchState.NoDelayTargets)
	table.clear(NState.YellPatchState.AutoSeen)
	table.clear(NState.YellPatchState.TargetParts)
	table.clear(NState.YellPatchState.SkillCache)
	NState.ItemESPController.Cleanup()
	NState.stopPoliceESP()
	NState.restoreNativeMusicMode()
	NState.restoreMusicModeHook()

	for Object in NState.PoliceOriginalSizes do
		pcall(NState.restorePolicePart, Object)
	end
	NState.Environment.NotorietyItemESPController = nil

	local CurrentWindow = NState.Environment.NotorietyWindow
	NState.Environment.NotorietyWindow = nil
	NState.NotorietyUI.Window = nil
	NState.NotorietyUI.Config = nil
	NState.NotorietyUI.SaveConfig = nil
	NState.NotorietyUI.RequestConfigSave = nil
	NState.NotorietyUI.MouseUnlockButton = nil

	if CurrentWindow then
		pcall(function()
			CurrentWindow:Destroy()
		end)
	end

	NState.Environment.NotorietyGetAmmoWrappers = setmetatable({}, {
		__mode = "k",
	})

	table.clear(NState.WeaponState.RuntimeWeapons)
	table.clear(NState.WeaponState.RuntimeSilentAimBackups)
end

NState.Environment.UnloadNotoriety = NState.unloadNotoriety

NState.trackWeaponContainer(NState.Weapons)
NState.trackWeaponContainer(NState.Backpack)
NState.trackWeaponContainer(NState.LocalPlayer.Character)
NState.createVibeUI()

if typeof(NState.NotorietyUI.Root) == "Instance" and type(NState.UIProtector.protectUI) == "function" then
	local ProtectedParent = NState.resolveProtectedUIParent()
	local Success, ProtectedRoot = pcall(NState.UIProtector.protectUI, NState.NotorietyUI.Root, {
		keepName = true,
		parent = ProtectedParent,
	})

	if Success and typeof(ProtectedRoot) == "Instance" then
		NState.NotorietyUI.Root = ProtectedRoot
	end
end

NState.applyPoliceHeadScale()
NState.setFriendlyFireEnabled(NState.Environment.NotorietyFriendlyFireEnabled)
NState.setRealismModeEnabled(NState.Environment.NotorietyRealismModeEnabled)
NState.setBugFeatureEnabled(NState.Environment.NotorietyBugFeatureEnabled)
NState.setWeaponModificationsEnabled(NState.Environment.NotorietyWeaponEnabled)
NState.setYellMarkPatchEnabled(NState.Environment.NotorietyInfiniteYellMarkEnabled)
NState.YellPatchState.SetAutoYellEnabled(NState.Environment.NotorietyAutoYellEnabled)
NState.YellPatchState.SetNoDelayEnabled(NState.Environment.NotorietyNoYellDelayEnabled)
NState.applyEquipmentPlacementSpeed()
NState.applyEquipmentPositioning()
NState.applyEquipmentPlacementRange()
NState.applyMobileEquipmentPlacementFix()
NState.applyAudioVolumes()
if NState.Environment.NotorietyItemESPEnabled then NState.setItemESPEnabled(true) end
if NState.Environment.NotorietyPoliceESPEnabled then NState.setPoliceESPEnabled(true) end
NState.applyMusicTrackSelection(true)
NState.applyMusicModeOverride()

NState.Environment.MaxEverythingConnection = NState.RunService.Heartbeat:Connect(function(DeltaTime)
	if NState.Environment.NotorietyUnloaded then
		return
	end

	NState.Apply()

	if NState.Environment.NotorietyAutoYellEnabled then
		NState.YellPatchState.AutoRefresh += DeltaTime

		if NState.YellPatchState.AutoRefresh >= 0.75 then
			NState.YellPatchState.AutoRefresh = 0
			NState.YellPatchState.AutoYell()
		end
	else
		NState.YellPatchState.AutoRefresh = 0
	end

	NState.ItemESPState.Refresh += DeltaTime
	NState.ItemESPState.Rescan += DeltaTime
	NState.ItemESPState.ScanRefresh += DeltaTime
	if NState.ItemESPState.Refresh >= 0.25 then
		NState.ItemESPState.Refresh = 0
		if NState.Environment.NotorietyItemESPEnabled then NState.updateItemESPVisibility() end
	end

	if NState.Environment.NotorietyItemESPEnabled and NState.ItemESPState.Rescan >= 0.5 then
		NState.ItemESPState.Rescan = 0

		if NState.ItemESPState.ScanRefresh >= 2 or #NState.ItemESPState.ScanList == 0 then
			NState.ItemESPState.ScanRefresh = 0
			NState.ItemESPState.ScanList = NState.CollectionService:GetTagged("Prompt")
			if NState.ItemESPState.ScanCursor > #NState.ItemESPState.ScanList then
				NState.ItemESPState.ScanCursor = 1
			end
		end

		local ScanCount = #NState.ItemESPState.ScanList
		local ScanBudget = math.min(24, ScanCount)

		for _ = 1, ScanBudget do
			if NState.ItemESPState.ScanCursor > ScanCount then
				NState.ItemESPState.ScanCursor = 1
			end

			local Prompt = NState.ItemESPState.ScanList[NState.ItemESPState.ScanCursor]
			NState.ItemESPState.ScanCursor += 1

			if typeof(Prompt) == "Instance" and Prompt.Parent then
				NState.inspectItemESPPrompt(Prompt)
			end
		end
	elseif not NState.Environment.NotorietyItemESPEnabled then
		NState.ItemESPState.Rescan = 0
		NState.ItemESPState.ScanRefresh = 0
	end

	NState.PoliceESPState.Refresh += DeltaTime
	NState.PoliceESPState.Rescan += DeltaTime
	if NState.PoliceESPState.Refresh >= 0.25 then
		NState.PoliceESPState.Refresh = 0
		if NState.Environment.NotorietyPoliceESPEnabled then NState.updatePoliceESP() end
	end

	if NState.Environment.NotorietyPoliceESPEnabled and NState.PoliceESPState.Rescan >= 0.75 then
		NState.PoliceESPState.Rescan = 0
		local PoliceFolder = NState.PoliceESPState.PoliceFolder

		if PoliceFolder and PoliceFolder.Parent then
			local Models = PoliceFolder:GetChildren()
			local ModelCount = #Models
			local ScanBudget = math.min(12, ModelCount)

			for _ = 1, ScanBudget do
				if NState.PoliceESPState.ScanCursor > ModelCount then
					NState.PoliceESPState.ScanCursor = 1
				end

				local Model = Models[NState.PoliceESPState.ScanCursor]
				NState.PoliceESPState.ScanCursor += 1

				if Model and not NState.PoliceESPState.Tracked[Model] then
					NState.addPoliceESP(Model)
				end
			end
		end
	elseif not NState.Environment.NotorietyPoliceESPEnabled then
		NState.PoliceESPState.Rescan = 0
	end

	NState.MusicOverrideState.Refresh += DeltaTime
	if NState.MusicOverrideState.Refresh >= 1 then
		NState.MusicOverrideState.Refresh = 0
		if NState.Environment.NotorietyMusicTrack ~= "Game Selection" then NState.applyMusicTrackSelection(false) end
		if NState.Environment.NotorietyMusicMode ~= "Follow Game" and not NState.MusicOverrideState.HookInstalled then
			NState.applyMusicModeOverride()
		end
	end

	NState.EquipmentSpeedState.Refresh += DeltaTime

	if NState.EquipmentSpeedState.Refresh >= 1 then
		NState.EquipmentSpeedState.Refresh = 0

		if NState.Environment.NotorietyInfiniteYellMarkEnabled then
			NState.applyYellMarkPatch()
		end
	end

	if not NState.Environment.NotorietyWeaponEnabled then
		return
	end

	NState.refreshRuntimeAmmo()
	NState.WeaponState.RuntimeRefresh += DeltaTime

	if NState.WeaponState.RuntimeRefresh >= 0.25 then
		NState.WeaponState.RuntimeRefresh = 0

		for Data in NState.WeaponState.Backups do
			NState.applyWeaponData(Data)
		end
	end
end)

NState.Environment.MaxEverythingCharacterConnection = NState.LocalPlayer.CharacterAdded:Connect(function(Character)
	if NState.Environment.NotorietyUnloaded then
		return
	end

	task.wait(1)

	if NState.Environment.NotorietyUnloaded then
		return
	end

	NState.Apply()
	NState.applyEquipmentPlacementSpeed()
	NState.applyEquipmentPositioning()
	NState.applyEquipmentPlacementRange()
	NState.applyMobileEquipmentPlacementFix()
	NState.applyAudioVolumes()
	if NState.Environment.NotorietyPoliceESPEnabled then NState.refreshPoliceESP() end
	NState.applyMusicTrackSelection(true)
	NState.applyMusicModeOverride()
	NState.trackWeaponContainer(Character)
	table.clear(NState.YellPatchState.TargetParts)
	table.clear(NState.YellPatchState.SkillCache)
	table.clear(NState.YellPatchState.AutoSeen)

	if NState.Environment.NotorietyNoYellDelayEnabled then
		NState.YellPatchState.RefreshNoDelayTargets()
		NState.YellPatchState.ConnectNoDelaySignals()
	end

	if NState.Environment.NotorietyWeaponEnabled then
		NState.applyAllWeaponModifications()
	end
end)

NState.Apply()
