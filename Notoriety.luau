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
					Tooltip = Control.Desc,
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
					Tooltip = Control.Desc,
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
					Tooltip = Control.Desc,
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
					Tooltip = Control.Desc,
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
Environment.NotorietyWeaponEnabled = true
Environment.NotorietyFireDelay = math.clamp(tonumber(Environment.NotorietyFireDelay) or 0.01, 0, 1)
Environment.NotorietyBoltDuration = math.clamp(tonumber(Environment.NotorietyBoltDuration) or 0.001, 0, 1)
Environment.NotorietyAccuracy = tonumber(Environment.NotorietyAccuracy) or 100
Environment.NotorietyItemESPEnabled = false
Environment.NotorietyPoliceHeadScaleEnabled = Environment.NotorietyPoliceHeadScaleEnabled ~= false
Environment.NotorietyPoliceHeadScale = math.clamp(
	tonumber(Environment.NotorietyPoliceHeadScale) or 10,
	1,
	20
)
Environment.NotorietyEquipmentSpeedEnabled = Environment.NotorietyEquipmentSpeedEnabled ~= false
Environment.NotorietyEquipmentSpeedMultiplier = math.clamp(
	tonumber(Environment.NotorietyEquipmentSpeedMultiplier) or 2,
	1,
	10
)
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
	Function = nil,
	FunctionEnvironment = nil,
	OriginalTick = nil,
	TickTarget = nil,
	WrappedTick = nil,
	EquipmentPercent = nil,
	VisibilityConnection = nil,
	ClockActive = false,
	RealAnchor = nil,
	ScaledAnchor = nil,
	LastMultiplier = nil,
	OriginalCFrame = nil,
	HadOwnCFrame = false,
	WrappedCFrame = nil,
	CFrameLookAtCount = 0,
	Refresh = 0,
}

local function getEquipmentSpeedMultiplier()
	if not Environment.NotorietyEquipmentSpeedEnabled then
		return 1
	end

	local Multiplier = tonumber(Environment.NotorietyEquipmentSpeedMultiplier) or 2

	if Multiplier <= 0
		or Multiplier == math.huge
		or Multiplier ~= Multiplier
	then
		Multiplier = 2
		Environment.NotorietyEquipmentSpeedMultiplier = Multiplier
	end

	return Multiplier
end

local function resetEquipmentClock()
	EquipmentSpeedState.ClockActive = false
	EquipmentSpeedState.RealAnchor = nil
	EquipmentSpeedState.ScaledAnchor = nil
	EquipmentSpeedState.LastMultiplier = nil
end

local function restoreEquipmentPlacementSpeed()
	if EquipmentSpeedState.VisibilityConnection then
		pcall(function()
			EquipmentSpeedState.VisibilityConnection:Disconnect()
		end)
		EquipmentSpeedState.VisibilityConnection = nil
	end

	if type(hookfunction) == "function"
		and type(EquipmentSpeedState.TickTarget) == "function"
		and type(EquipmentSpeedState.OriginalTick) == "function"
	then
		pcall(hookfunction, EquipmentSpeedState.TickTarget, EquipmentSpeedState.OriginalTick)
	end

	local FunctionEnvironment = EquipmentSpeedState.FunctionEnvironment
	local WrappedCFrame = EquipmentSpeedState.WrappedCFrame

	if type(FunctionEnvironment) == "table"
		and type(WrappedCFrame) == "table"
		and rawget(FunctionEnvironment, "CFrame") == WrappedCFrame
	then
		if EquipmentSpeedState.HadOwnCFrame then
			rawset(FunctionEnvironment, "CFrame", EquipmentSpeedState.OriginalCFrame)
		else
			rawset(FunctionEnvironment, "CFrame", nil)
		end
	end

	EquipmentSpeedState.Function = nil
	EquipmentSpeedState.FunctionEnvironment = nil
	EquipmentSpeedState.OriginalTick = nil
	EquipmentSpeedState.TickTarget = nil
	EquipmentSpeedState.WrappedTick = nil
	EquipmentSpeedState.EquipmentPercent = nil
	resetEquipmentClock()
	EquipmentSpeedState.OriginalCFrame = nil
	EquipmentSpeedState.HadOwnCFrame = false
	EquipmentSpeedState.WrappedCFrame = nil
	EquipmentSpeedState.CFrameLookAtCount = 0
	EquipmentSpeedState.Refresh = 0
end

local function inspectMobilePlacementFunction()
	if type(getconnections) ~= "function"
		or type(debug) ~= "table"
		or type(debug.getupvalues) ~= "function"
		or type(debug.getinfo) ~= "function"
	then
		return nil
	end

	local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
	local MainGui = SGPackage and SGPackage:FindFirstChild("MainGui")
	local MobileUI = MainGui and MainGui:FindFirstChild("MobileUI")
	local Hotbar = MobileUI and MobileUI:FindFirstChild("Hotbar")
	local Equipment = Hotbar and Hotbar:FindFirstChild("Equipment")
	local SelectButton = Equipment and Equipment:FindFirstChild("SelectButton")

	if not SelectButton or not SelectButton:IsA("GuiButton") then
		return nil
	end

	local Success, Connections = pcall(getconnections, SelectButton.MouseButton1Down)

	if not Success or type(Connections) ~= "table" then
		return nil
	end

	local function scanFunction(Function, Depth)
		if type(Function) ~= "function" or Depth > 2 then
			return nil
		end

		local InfoSuccess, Info = pcall(debug.getinfo, Function)

		if InfoSuccess
			and type(Info) == "table"
			and Info.source == "=Players." .. LocalPlayer.Name .. ".PlayerGui.SG_Package.LocalMovement"
			and Info.name == "placeEquipment"
		then
			return Function
		end

		local UpvalueSuccess, Upvalues = pcall(debug.getupvalues, Function)

		if not UpvalueSuccess or type(Upvalues) ~= "table" then
			return nil
		end

		for _, Value in pairs(Upvalues) do
			if type(Value) == "function" then
				local Found = scanFunction(Value, Depth + 1)

				if Found then
					return Found
				end
			end
		end

		return nil
	end

	for _, Connection in Connections do
		local Callback
		pcall(function()
			Callback = Connection.Function
		end)

		local Found = scanFunction(Callback, 0)

		if Found then
			return Found
		end
	end

	return nil
end

local function findEquipmentPlacementFunction()
	local Existing = EquipmentSpeedState.Function

	if type(Existing) == "function" then
		return Existing
	end

	if type(getgc) == "function"
		and type(getfenv) == "function"
		and type(debug) == "table"
		and type(debug.getinfo) == "function"
	then
		for _, Function in getgc(true) do
			if type(Function) == "function" then
				local Success, Info = pcall(debug.getinfo, Function)

				if Success
					and type(Info) == "table"
					and Info.source == "=Players." .. LocalPlayer.Name .. ".PlayerGui.SG_Package.LocalMovement"
					and Info.name == "placeEquipment"
				then
					EquipmentSpeedState.Function = Function
					local EnvironmentSuccess, FunctionEnvironmentResult = pcall(getfenv, Function)

					if EnvironmentSuccess and type(FunctionEnvironmentResult) == "table" then
						EquipmentSpeedState.FunctionEnvironment = FunctionEnvironmentResult
					end

					return Function
				end
			end
		end
	end

	local MobileFunction = inspectMobilePlacementFunction()

	if type(MobileFunction) == "function" then
		EquipmentSpeedState.Function = MobileFunction

		if type(getfenv) == "function" then
			local EnvironmentSuccess, FunctionEnvironmentResult = pcall(getfenv, MobileFunction)

			if EnvironmentSuccess and type(FunctionEnvironmentResult) == "table" then
				EquipmentSpeedState.FunctionEnvironment = FunctionEnvironmentResult
			end
		end
	end

	return MobileFunction
end

local function applyEquipmentPlacementSpeed()
	if Environment.NotorietyUnloaded then
		return false
	end

	local Function = findEquipmentPlacementFunction()

	if type(Function) ~= "function" or type(hookfunction) ~= "function" or type(tick) ~= "function" then
		return false
	end

	if type(EquipmentSpeedState.WrappedTick) == "function"
		and type(EquipmentSpeedState.OriginalTick) == "function"
	then
		return true
	end

	local EquipmentPercent = LocalPlayer
		:WaitForChild("PlayerGui", math.huge)
		:WaitForChild("SG_Package", math.huge)
		:WaitForChild("MainGui", math.huge)
		:WaitForChild("Interaction", math.huge)
		:WaitForChild("EquipmentPercent", math.huge)
	local TickTarget = tick
	local OriginalTick

	local function WrappedTick(...)
		local Now = OriginalTick(...)

		if Environment.NotorietyUnloaded or not Environment.NotorietyEquipmentSpeedEnabled then
			return Now
		end

		local IsEquipmentCaller = false

		for Level = 2, 6 do
			local SourceSuccess, Source = pcall(debug.info, Level, "s")
			local NameSuccess, Name = pcall(debug.info, Level, "n")

			if SourceSuccess
				and NameSuccess
				and Source == "Players." .. LocalPlayer.Name .. ".PlayerGui.SG_Package.LocalMovement"
				and Name == "placeEquipment"
			then
				IsEquipmentCaller = true
				break
			end
		end

		if not IsEquipmentCaller then
			return Now
		end

		if typeof(EquipmentPercent) ~= "Instance"
			or EquipmentPercent.Parent == nil
			or not EquipmentPercent.Visible
		then
			resetEquipmentClock()
			return Now
		end

		local Multiplier = getEquipmentSpeedMultiplier()

		if not EquipmentSpeedState.ClockActive then
			EquipmentSpeedState.ClockActive = true
			EquipmentSpeedState.RealAnchor = Now
			EquipmentSpeedState.ScaledAnchor = Now
			EquipmentSpeedState.LastMultiplier = Multiplier
		elseif EquipmentSpeedState.LastMultiplier ~= Multiplier then
			EquipmentSpeedState.ScaledAnchor += (Now - EquipmentSpeedState.RealAnchor) * EquipmentSpeedState.LastMultiplier
			EquipmentSpeedState.RealAnchor = Now
			EquipmentSpeedState.LastMultiplier = Multiplier
		end

		return EquipmentSpeedState.ScaledAnchor
			+ (Now - EquipmentSpeedState.RealAnchor) * EquipmentSpeedState.LastMultiplier
	end

	local HookSuccess, HookResult = pcall(hookfunction, TickTarget, WrappedTick)

	if not HookSuccess or type(HookResult) ~= "function" then
		return false
	end

	OriginalTick = HookResult
	EquipmentSpeedState.OriginalTick = OriginalTick
	EquipmentSpeedState.TickTarget = TickTarget
	EquipmentSpeedState.WrappedTick = WrappedTick
	EquipmentSpeedState.EquipmentPercent = EquipmentPercent
	resetEquipmentClock()

	EquipmentSpeedState.VisibilityConnection = EquipmentPercent:GetPropertyChangedSignal("Visible"):Connect(function()
		if not EquipmentPercent.Visible then
			resetEquipmentClock()
		end
	end)

	return true
end

local function getEquipmentPositionOffset()
	local X = tonumber(Environment.NotorietyEquipmentPositionX) or 0
	local Y = tonumber(Environment.NotorietyEquipmentPositionY) or 0
	local Z = tonumber(Environment.NotorietyEquipmentPositionZ) or 0

	if X == math.huge or X == -math.huge or X ~= X then
		X = 0
	end

	if Y == math.huge or Y == -math.huge or Y ~= Y then
		Y = 0
	end

	if Z == math.huge or Z == -math.huge or Z ~= Z then
		Z = 0
	end

	return X, Y, Z
end

local function applyEquipmentPositioning()
	if Environment.NotorietyUnloaded then
		return false
	end

	local Function = findEquipmentPlacementFunction()

	if not Function then
		return false
	end

	local FunctionEnvironment = EquipmentSpeedState.FunctionEnvironment
	local ExistingWrapper = EquipmentSpeedState.WrappedCFrame

	if type(FunctionEnvironment) ~= "table" then
		return false
	end

	if type(ExistingWrapper) == "table"
		and rawget(FunctionEnvironment, "CFrame") == ExistingWrapper
	then
		return true
	end

	local OriginalCFrame = FunctionEnvironment.CFrame

	if type(OriginalCFrame) ~= "table"
		or type(OriginalCFrame.new) ~= "function"
	then
		return false
	end

	local HadOwnCFrame = rawget(FunctionEnvironment, "CFrame") ~= nil
	local WrappedCFrame = {}

	setmetatable(WrappedCFrame, {
		__index = OriginalCFrame,
	})

	WrappedCFrame.new = function(...)
		local Result = OriginalCFrame.new(...)

		if not Environment.NotorietyEquipmentPositionEnabled
			or Environment.NotorietyUnloaded
		then
			return Result
		end

		local CallerSuccess, Caller = pcall(debug.info, 2, "f")

		if not CallerSuccess or Caller ~= Function then
			return Result
		end

		local ArgumentCount = select("#", ...)
		local Position, LookAt = ...

		if ArgumentCount ~= 2
			or typeof(Position) ~= "Vector3"
			or typeof(LookAt) ~= "Vector3"
		then
			return Result
		end

		EquipmentSpeedState.CFrameLookAtCount += 1

		if EquipmentSpeedState.CFrameLookAtCount ~= 2 then
			return Result
		end

		local X, Y, Z = getEquipmentPositionOffset()

		if X == 0 and Y == 0 and Z == 0 then
			return Result
		end

		return Result * OriginalCFrame.new(X, Y, -Z)
	end

	EquipmentSpeedState.OriginalCFrame = OriginalCFrame
	EquipmentSpeedState.HadOwnCFrame = HadOwnCFrame
	EquipmentSpeedState.WrappedCFrame = WrappedCFrame
	rawset(FunctionEnvironment, "CFrame", WrappedCFrame)

	return rawget(FunctionEnvironment, "CFrame") == WrappedCFrame
end

local AudioState = {
	Groups = {},
	OriginalVolumes = setmetatable({}, {
		__mode = "k",
	}),
	DirectOriginalVolumes = setmetatable({}, {
		__mode = "k",
	}),
	DirectConnections = setmetatable({}, {
		__mode = "k",
	}),
	DescendantConnection = nil,
	Applying = false,
	ApplyingDirect = false,
}

local AudioDefinitions = {
	{
		Key = "Music",
		EnvironmentKey = "NotorietyMusicVolume",
	},
	{
		Key = "SFX",
		EnvironmentKey = "NotorietySFXVolume",
	},
	{
		Key = "LocalGunshots",
		EnvironmentKey = "NotorietyLocalGunshotsVolume",
	},
	{
		Key = "Gunshots",
		EnvironmentKey = "NotorietyGunshotsVolume",
	},
	{
		Key = "MapAmbience",
		EnvironmentKey = "NotorietyMapAmbienceVolume",
	},
	{
		Key = "Voices",
		EnvironmentKey = "NotorietyVoicesVolume",
	},
	{
		Key = "UI",
		EnvironmentKey = "NotorietyUIVolume",
	},
}

local function resolveAudioGroups()
	local SoundPackage = SoundService:FindFirstChild("Sound_Package")
	local GlobalSounds = SoundPackage and SoundPackage:FindFirstChild("GlobalSounds")
	local GameAudio = GlobalSounds and GlobalSounds:FindFirstChild("GameAudio")
	local SFX = GameAudio and GameAudio:FindFirstChild("SFX")

	AudioState.Groups.Music = GlobalSounds and GlobalSounds:FindFirstChild("Music")
	AudioState.Groups.SFX = SFX
	AudioState.Groups.LocalGunshots = SFX and SFX:FindFirstChild("LocalGunshots")
	AudioState.Groups.Gunshots = SFX and SFX:FindFirstChild("Gunshots")
	AudioState.Groups.MapAmbience = SFX and SFX:FindFirstChild("MapAmbience")
	AudioState.Groups.Voices = GameAudio and GameAudio:FindFirstChild("Voices")
	AudioState.Groups.UI = GlobalSounds and GlobalSounds:FindFirstChild("UI")

	for _, Definition in AudioDefinitions do
		local Group = AudioState.Groups[Definition.Key]

		if typeof(Group) == "Instance"
			and Group:IsA("SoundGroup")
			and AudioState.OriginalVolumes[Group] == nil
		then
			AudioState.OriginalVolumes[Group] = Group.Volume
		end
	end
end

local function isGunshotSound(Sound)
	if typeof(Sound) ~= "Instance" or not Sound:IsA("Sound") then
		return false
	end

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
	if not isGunshotSound(Sound) then
		return false
	end

	local Camera = Workspace.CurrentCamera
	local CameraModel = Camera and Camera:FindFirstChild("CameraModel")
	local Character = LocalPlayer.Character

	return (CameraModel and Sound:IsDescendantOf(CameraModel))
		or (Character and Sound:IsDescendantOf(Character))
end

local function getDirectGunshotPercent(Sound)
	local SFXPercent = math.clamp(tonumber(Environment.NotorietySFXVolume) or 100, 0, 100) / 100
	local GunPercent

	if isLocalGunshotSound(Sound) then
		GunPercent = math.clamp(tonumber(Environment.NotorietyLocalGunshotsVolume) or 100, 0, 100) / 100
	else
		GunPercent = math.clamp(tonumber(Environment.NotorietyGunshotsVolume) or 100, 0, 100) / 100
	end

	return SFXPercent * GunPercent
end

local function applyDirectGunshotVolume(Sound)
	if Environment.NotorietyUnloaded
		or typeof(Sound) ~= "Instance"
		or not Sound:IsA("Sound")
		or Sound.Parent == nil
		or not isGunshotSound(Sound)
	then
		return false
	end

	local LocalGroup = AudioState.Groups.LocalGunshots
	local OtherGroup = AudioState.Groups.Gunshots

	if Sound.SoundGroup == LocalGroup or Sound.SoundGroup == OtherGroup then
		return false
	end

	if AudioState.DirectOriginalVolumes[Sound] == nil then
		AudioState.DirectOriginalVolumes[Sound] = Sound.Volume
	end

	local BaseVolume = AudioState.DirectOriginalVolumes[Sound]
	local TargetVolume = BaseVolume * getDirectGunshotPercent(Sound)

	if math.abs(Sound.Volume - TargetVolume) > 0.0001 then
		AudioState.ApplyingDirect = true
		Sound.Volume = TargetVolume
		AudioState.ApplyingDirect = false
	end

	return true
end

local function trackDirectGunshotSound(Sound)
	if not isGunshotSound(Sound) then
		return false
	end

	if AudioState.DirectOriginalVolumes[Sound] == nil then
		AudioState.DirectOriginalVolumes[Sound] = Sound.Volume
	end

	if AudioState.DirectConnections[Sound] == nil then
		AudioState.DirectConnections[Sound] = Sound:GetPropertyChangedSignal("Volume"):Connect(function()
			if Environment.NotorietyUnloaded or AudioState.ApplyingDirect then
				return
			end

			local Percent = getDirectGunshotPercent(Sound)

			if Percent >= 0.9999 then
				AudioState.DirectOriginalVolumes[Sound] = Sound.Volume
				return
			end

			-- The game rewrites weapon volumes during equip/fire. Treat that value as
			-- the new unscaled base, then immediately re-apply the user's slider.
			AudioState.DirectOriginalVolumes[Sound] = Sound.Volume
			applyDirectGunshotVolume(Sound)
		end)
	end

	return applyDirectGunshotVolume(Sound)
end

local function scanDirectGunshotSounds()
	local Camera = Workspace.CurrentCamera
	local CameraModel = Camera and Camera:FindFirstChild("CameraModel")
	local Character = LocalPlayer.Character

	if CameraModel then
		for _, Descendant in CameraModel:GetDescendants() do
			if Descendant:IsA("Sound") then
				trackDirectGunshotSound(Descendant)
			end
		end
	end

	if Character then
		for _, Descendant in Character:GetDescendants() do
			if Descendant:IsA("Sound") then
				trackDirectGunshotSound(Descendant)
			end
		end
	end

	-- Other players/NPCs may also use ungrouped muzzle sounds.
	for _, ContainerName in { "Criminals", "Police" } do
		local Container = Workspace:FindFirstChild(ContainerName)

		if Container then
			for _, Descendant in Container:GetDescendants() do
				if Descendant:IsA("Sound") and isGunshotSound(Descendant) then
					trackDirectGunshotSound(Descendant)
				end
			end
		end
	end
end

local function ensureDirectAudioWatcher()
	if AudioState.DescendantConnection then
		return
	end

	AudioState.DescendantConnection = Workspace.DescendantAdded:Connect(function(Descendant)
		if Environment.NotorietyUnloaded or not Descendant:IsA("Sound") then
			return
		end

		if isGunshotSound(Descendant) then
			task.defer(trackDirectGunshotSound, Descendant)
		end
	end)
end

local function applyAudioVolumes()
	if Environment.NotorietyUnloaded or AudioState.Applying then
		return false
	end

	resolveAudioGroups()
	ensureDirectAudioWatcher()
	AudioState.Applying = true
	local Applied = false

	for _, Definition in AudioDefinitions do
		local Group = AudioState.Groups[Definition.Key]
		local Percent = math.clamp(tonumber(Environment[Definition.EnvironmentKey]) or 100, 0, 100)
		Environment[Definition.EnvironmentKey] = Percent

		if typeof(Group) == "Instance" and Group:IsA("SoundGroup") then
			Group.Volume = Percent / 100
			Applied = true
		end
	end

	AudioState.Applying = false
	scanDirectGunshotSounds()
	return Applied
end

local function restoreAudioVolumes()
	AudioState.Applying = true
	AudioState.ApplyingDirect = true

	if AudioState.DescendantConnection then
		pcall(function()
			AudioState.DescendantConnection:Disconnect()
		end)
		AudioState.DescendantConnection = nil
	end

	for Sound, Connection in AudioState.DirectConnections do
		pcall(function()
			Connection:Disconnect()
		end)

		local Original = AudioState.DirectOriginalVolumes[Sound]

		if typeof(Sound) == "Instance" and Sound.Parent ~= nil and type(Original) == "number" then
			pcall(function()
				Sound.Volume = Original
			end)
		end
	end

	for Group, Volume in AudioState.OriginalVolumes do
		if typeof(Group) == "Instance" and Group.Parent ~= nil then
			pcall(function()
				Group.Volume = Volume
			end)
		end
	end

	AudioState.ApplyingDirect = false
	AudioState.Applying = false
	table.clear(AudioState.Groups)
	table.clear(AudioState.OriginalVolumes)
	table.clear(AudioState.DirectOriginalVolumes)
	table.clear(AudioState.DirectConnections)
end

local MobileEquipmentState = {
	Targets = {},
	Refresh = 0,
}

local function getFunctionUpvalues(Function)
	if type(debug) ~= "table" or type(debug.getupvalues) ~= "function" then
		return nil
	end

	local Success, Upvalues = pcall(debug.getupvalues, Function)
	return if Success and type(Upvalues) == "table" then Upvalues else nil
end

local function getConnectionFunction(Connection)
	local Success, Function = pcall(function()
		return Connection.Function
	end)

	return if Success and type(Function) == "function" then Function else nil
end

local function restoreMobileEquipmentPlacementFix()
	if type(debug) == "table" and type(debug.setupvalue) == "function" then
		for _, Record in MobileEquipmentState.Targets do
			if type(Record) == "table"
				and type(Record.Callback) == "function"
				and type(Record.Index) == "number"
				and type(Record.Original) == "function"
			then
				local Upvalues = getFunctionUpvalues(Record.Callback)

				if Upvalues and Upvalues[Record.Index] == Record.Wrapper then
					pcall(debug.setupvalue, Record.Callback, Record.Index, Record.Original)
				end
			end
		end
	end

	table.clear(MobileEquipmentState.Targets)
	MobileEquipmentState.Refresh = 0
end

local function hasMobileEquipmentTarget(Callback, Index)
	for _, Record in MobileEquipmentState.Targets do
		if Record.Callback == Callback and Record.Index == Index then
			return true
		end
	end

	return false
end

local function applyMobileEquipmentPlacementFix()
	if Environment.NotorietyUnloaded
		or type(getconnections) ~= "function"
		or type(debug) ~= "table"
		or type(debug.getupvalues) ~= "function"
		or type(debug.setupvalue) ~= "function"
	then
		return false
	end

	local PlaceEquipment = findEquipmentPlacementFunction()

	if type(PlaceEquipment) ~= "function" then
		return false
	end

	local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
	local MainGui = SGPackage and SGPackage:FindFirstChild("MainGui")
	local MobileUI = MainGui and MainGui:FindFirstChild("MobileUI")
	local Buttons = MobileUI and MobileUI:FindFirstChild("Hotbar")
	local Equipment = Buttons and Buttons:FindFirstChild("Equipment")
	local SelectButton = Equipment and Equipment:FindFirstChild("SelectButton")

	if not SelectButton or not SelectButton:IsA("GuiButton") then
		return false
	end

	local Success, Connections = pcall(getconnections, SelectButton.MouseButton1Down)

	if not Success or type(Connections) ~= "table" then
		return false
	end

	local Patched = false

	for _, Connection in Connections do
		local Callback = getConnectionFunction(Connection)
		local Upvalues = Callback and getFunctionUpvalues(Callback) or nil

		if Upvalues then
			for Index, Value in pairs(Upvalues) do
				if Value == PlaceEquipment then
					if hasMobileEquipmentTarget(Callback, Index) then
						Patched = true
						break
					end

					local Original = PlaceEquipment
					local Wrapper = function(...)
						applyEquipmentPlacementSpeed()
						return Original(...)
					end
					local SetupSuccess = pcall(debug.setupvalue, Callback, Index, Wrapper)

					if SetupSuccess then
						table.insert(MobileEquipmentState.Targets, {
							Callback = Callback,
							Index = Index,
							Original = Original,
							Wrapper = Wrapper,
						})
						Patched = true
					end

					break
				end
			end
		end
	end

	return Patched
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
	applyPoliceHeadScale()

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
	RuntimeSpreadBackups = setmetatable({}, {
		__mode = "k",
	}),
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
	if not Environment.NotorietyWeaponEnabled or type(Result) ~= "table" then
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

local function patchRuntimeWeaponSpread(State, Spread)
	local DebugLibrary = debug
	local Shoot = type(State) == "table" and rawget(State, "shoot") or nil

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

	if not isInfiniteGunState(State, Data) then
		restoreAmmoWrapper(State)
		WeaponState.RuntimeWeapons[State] = nil
		return Patched
	end

	WeaponState.RuntimeWeapons[State] = true
	State.ShakeMagnitude = 0
	State.ShakeRoughness = 0
	State.pushdist = 0

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
	if not Environment.NotorietyWeaponEnabled or type(State) ~= "table" then
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

		Data.FireDelay = tonumber(Environment.NotorietyFireDelay) or 0.01
		Data.BoltDuration = tonumber(Environment.NotorietyBoltDuration) or 0.001
		Data.BoltLock = false

		if type(Data.Accuracy) == "number" then
			Data.Accuracy = math.clamp(tonumber(Environment.NotorietyAccuracy) or 100, 0, 100)
		end

		if StandardGun then
			Data.FireMode = "Auto"

			if type(Data.FireModeList) ~= "table"
				or Data.FireModeList[1] ~= "Auto"
				or Data.FireModeList[2] ~= nil
			then
				Data.FireModeList = {
					"Auto",
				}
			end
		end

		local AmmoClass = Data.AmmoClass
		local UsesInfiniteGunAmmo = AmmoClass == "Primary" or AmmoClass == "Secondary"

		if UsesInfiniteGunAmmo then
			Data.MagazineSize = MAX_VALUE
			Data.AmmoMax = MAX_VALUE
		end

		if type(Data.ManualCasingEjection) == "boolean" then
			Data.ManualCasingEjection = false
		end

		patchGunSequences(Data, Backup)
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
	if not Environment.MaxEverythingEnabled then
		return
	end

	local Character = LocalPlayer.Character

	if not Character then
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

local function setWeaponModificationsEnabled(Enabled)
	Environment.NotorietyWeaponEnabled = Enabled == true

	if Environment.NotorietyWeaponEnabled then
		applyAllWeaponModifications()
	else
		restoreAllWeaponData()
		restoreRuntimeWeaponAccuracy()
	end
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
}

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

	ItemESPState.Tracked[Object] = nil
end

local function addItemESPObject(Category, Object)
	if not Category or not Object then
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
	Box.Transparency = 0.55
	Box.AlwaysOnTop = true
	Box.ZIndex = 10
	Box.Parent = Folder

	local AncestryConnection

	AncestryConnection = Object.AncestryChanged:Connect(function(_, Parent)
		if not Parent then
			removeItemESPObject(Object)
		end
	end)

	local Entry = {
		Category = Category,
		Box = Box,
		Connection = AncestryConnection,
	}

	ItemESPState.Tracked[Object] = Entry
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
	local Parent

	if type(gethui) == "function" then
		local ParentSuccess, HiddenUI = pcall(gethui)

		if ParentSuccess and typeof(HiddenUI) == "Instance" then
			Parent = HiddenUI
		end
	end

	Parent = Parent or LocalPlayer:FindFirstChildOfClass("PlayerGui")
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

	for _, Prompt in CollectionService:GetTagged("Prompt") do
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

	MainTab:Button({
		Title = "Kill Police [P]",
		Desc = "Kills every currently spawned police NPC",
		Icon = "crosshair",
		Callback = function()
			task.spawn(runKill)
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

	MainTab:Toggle({
		Flag = "ItemESP",
		Title = "Item ESP",
		Desc = "Highlights supported loot and interaction objects",
		Value = Environment.NotorietyItemESPEnabled,
		Callback = function(Enabled)
			setItemESPEnabled(Enabled)
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
		Desc = "Enables the weapon stat and runtime modifications",
		Value = Environment.NotorietyWeaponEnabled,
		Callback = function(Enabled)
			setWeaponModificationsEnabled(Enabled)
			requestVibeUIConfigSave()
		end,
	})

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

			if Environment.NotorietyWeaponEnabled then
				applyAllWeaponModifications()
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

			if Environment.NotorietyWeaponEnabled then
				applyAllWeaponModifications()
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

			if Environment.NotorietyWeaponEnabled then
				applyAllWeaponModifications()
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

			if Environment.NotorietyWeaponEnabled then
				applyAllWeaponModifications()
			end

			requestVibeUIConfigSave()
		end,
	})

	local AudioTab = Window:Tab({
		Title = "Audio",
		Icon = "volume-2",
		Border = true,
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
		"Master game SFX group. This also scales gunshots and map ambience",
		"NotorietySFXVolume"
	)
	NotorietyUI.MapAmbienceVolumeSlider = addAudioSlider(
		"MapAmbienceVolume",
		"Map Ambience",
		"Environmental/map ambience",
		"NotorietyMapAmbienceVolume"
	)
	NotorietyUI.VoicesVolumeSlider = addAudioSlider(
		"VoicesVolume",
		"Voices",
		"Character/police voice audio",
		"NotorietyVoicesVolume"
	)
	NotorietyUI.UIVolumeSlider = addAudioSlider(
		"UIVolume",
		"UI Sounds",
		"Interface sound effects",
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
		Desc = "Speeds up the real 0% to 100% equipment placement timer",
		Value = Environment.NotorietyEquipmentSpeedEnabled,
		Callback = function(Enabled)
			Environment.NotorietyEquipmentSpeedEnabled = Enabled == true
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
		Flag = "EquipmentPositionEnabled",
		Title = "Custom Equipment Position",
		Desc = "Offsets the equipment from its normal placement position",
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
	Environment.NotorietyItemESPEnabled = false
	Environment.NotorietyPoliceHeadScaleEnabled = false
	Environment.NotorietyInfiniteYellMarkEnabled = false
	Environment.NotorietyAutoYellEnabled = false
	Environment.NotorietyNoYellDelayEnabled = false
	Environment.KillPoliceRunning = false

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

	restoreAllWeaponData()
	restoreRuntimeWeaponAccuracy()
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

	if CurrentWindow then
		pcall(function()
			CurrentWindow:Destroy()
		end)
	end

	Environment.NotorietyGetAmmoWrappers = setmetatable({}, {
		__mode = "k",
	})

	table.clear(WeaponState.RuntimeWeapons)
end

Environment.UnloadNotoriety = unloadNotoriety

trackWeaponContainer(Weapons)
trackWeaponContainer(Backpack)
trackWeaponContainer(LocalPlayer.Character)
createVibeUI()
setWeaponModificationsEnabled(Environment.NotorietyWeaponEnabled)
setYellMarkPatchEnabled(Environment.NotorietyInfiniteYellMarkEnabled)
YellPatchState.SetAutoYellEnabled(Environment.NotorietyAutoYellEnabled)
YellPatchState.SetNoDelayEnabled(Environment.NotorietyNoYellDelayEnabled)
applyEquipmentPlacementSpeed()
applyEquipmentPositioning()
applyMobileEquipmentPlacementFix()
applyAudioVolumes()

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

	EquipmentSpeedState.Refresh += DeltaTime

	if EquipmentSpeedState.Refresh >= 1 then
		EquipmentSpeedState.Refresh = 0
		applyEquipmentPlacementSpeed()
		applyEquipmentPositioning()
		applyMobileEquipmentPlacementFix()
		applyAudioVolumes()

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
	applyMobileEquipmentPlacementFix()
	applyAudioVolumes()
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
