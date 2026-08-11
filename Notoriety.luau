if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Environment = if type(getgenv) == "function" then getgenv() else _G

local ExistingLoadState = rawget(Environment, "NotorietyLoadState")

if type(ExistingLoadState) == "table" and ExistingLoadState.Status == "loading" then
	ExistingLoadState.Cancelled = true

	if type(ExistingLoadState.Cancel) == "function" then
		pcall(ExistingLoadState.Cancel)
	end

	local CancelDeadline = os.clock() + 2

	repeat
		task.wait(0.05)
	until ExistingLoadState.Status ~= "loading" or os.clock() >= CancelDeadline
end

local PreviousUnload = rawget(Environment, "UnloadNotoriety")
local LoadState = {
	Status = "loading",
	Stage = "bootstrap",
	StartedAt = os.clock(),
	Cancelled = false,
}

Environment.NotorietyLoadState = LoadState

local function ownsNotorietyBootstrap()
	return rawget(Environment, "NotorietyLoadState") == LoadState
end

local function isCurrentNotorietyRun()
	return ownsNotorietyBootstrap() and not LoadState.Cancelled
end

local function ensureExecutorIdentity()
	local Setter = if type(setthreadidentity) == "function" then setthreadidentity else setidentity

	if type(Setter) == "function" then
		pcall(Setter, 8)
	end
end

local function startupCheckpoint(Stage)
	LoadState.Stage = Stage

	if not isCurrentNotorietyRun() then
		error("Notoriety initialization superseded during " .. tostring(Stage), 0)
	end
end

local function waitForStartupChild(Parent, Name)
	while isCurrentNotorietyRun() do
		local Child = Parent:FindFirstChild(Name)

		if Child then
			return Child
		end

		task.wait(0.1)
	end

	error("Notoriety initialization cancelled while waiting for " .. tostring(Name), 0)
end

local function waitForRobloxRuntime()
	startupCheckpoint("Roblox runtime readiness")

	local BootstrapPlayers = game:GetService("Players")
	local BootstrapReplicatedStorage = game:GetService("ReplicatedStorage")
	local BootstrapRunService = game:GetService("RunService")
	local BootstrapLocalPlayer = BootstrapPlayers.LocalPlayer

	while BootstrapLocalPlayer == nil and isCurrentNotorietyRun() do
		task.wait(0.05)
		BootstrapLocalPlayer = BootstrapPlayers.LocalPlayer
	end

	if BootstrapLocalPlayer == nil then
		error("Notoriety initialization cancelled while waiting for LocalPlayer", 0)
	end

	waitForStartupChild(BootstrapLocalPlayer, "PlayerScripts")
	waitForStartupChild(BootstrapLocalPlayer, "PlayerGui")
	waitForStartupChild(BootstrapLocalPlayer, "Backpack")

	local BootstrapPackage = waitForStartupChild(BootstrapReplicatedStorage, "RS_Package")
	local BootstrapAssets = waitForStartupChild(BootstrapPackage, "Assets")
	local BootstrapRemotes = waitForStartupChild(BootstrapAssets, "Remotes")
	waitForStartupChild(BootstrapRemotes, "Damage")

	local GraceDeadline = os.clock() + 1.5

	repeat
		BootstrapRunService.Heartbeat:Wait()
	until not isCurrentNotorietyRun() or os.clock() >= GraceDeadline

	startupCheckpoint("Roblox runtime ready")
end

local function disconnectBootstrapConnection(Connection)
	if typeof(Connection) == "RBXScriptConnection" then
		pcall(function()
			Connection:Disconnect()
		end)
	end
end

local function cleanupPartialNotorietyRuntime()
	if not ownsNotorietyBootstrap() then
		return
	end

	Environment.NotorietyUnloaded = true

	for _, Name in {
		"MaxEverythingConnection",
		"MaxEverythingCharacterConnection",
		"NotorietyPoliceHitboxConnection",
	} do
		disconnectBootstrapConnection(rawget(Environment, Name))
		Environment[Name] = nil
	end

	for _, Name in {
		"NotorietyWeaponConnections",
		"NotorietyUIConnections",
		"NotorietyNoDelayConnections",
		"NotorietyMaxValueConnections",
	} do
		local Connections = rawget(Environment, Name)

		if type(Connections) == "table" then
			for _, Connection in Connections do
				disconnectBootstrapConnection(Connection)
			end

			table.clear(Connections)
		end
	end

	local ItemController = rawget(Environment, "NotorietyItemESPController")

	if type(ItemController) == "table" and type(ItemController.Cleanup) == "function" then
		pcall(ItemController.Cleanup)
	end

	local PoliceState = rawget(Environment, "NotorietyPoliceHeadScaleState")

	if type(PoliceState) == "table" and type(PoliceState.SetEnabled) == "function" then
		pcall(PoliceState.SetEnabled, false)
	end

	local MeleeState = rawget(Environment, "NotorietyMeleeReachHookState")

	if type(MeleeState) == "table" then
		MeleeState.Enabled = false
	end

	local NamecallState = rawget(Environment, "NotorietyNamecallHookState")

	if type(NamecallState) == "table" and NamecallState.Owner == LoadState then
		NamecallState.Dispatch = nil
		NamecallState.Owner = nil
	end

	local Window = rawget(Environment, "NotorietyWindow")

	if Window ~= nil then
		pcall(function()
			Window:Destroy()
		end)
		Environment.NotorietyWindow = nil
	end

	local ModalRoot = rawget(Environment, "NotorietyModalRoot")
	Environment.NotorietyModalRoot = nil

	if typeof(ModalRoot) == "Instance" then
		pcall(function()
			ModalRoot:Destroy()
		end)
	end
end

LoadState.Cancel = function()
	LoadState.Cancelled = true
end

local function emergencyUnloadNotoriety()
	LoadState.Cancelled = true

	if type(LoadState.FinalUnload) == "function" then
		pcall(LoadState.FinalUnload)
	else
		cleanupPartialNotorietyRuntime()
	end
end

Environment.UnloadNotoriety = emergencyUnloadNotoriety

local function initializeNotoriety()
	ensureExecutorIdentity()
	startupCheckpoint("previous runtime cleanup")

	if type(PreviousUnload) == "function" and PreviousUnload ~= emergencyUnloadNotoriety then
		local UnloadSuccess, UnloadError = pcall(PreviousUnload)

		if not UnloadSuccess then
			error("Previous Notoriety cleanup failed: " .. tostring(UnloadError), 0)
		end
	end

	waitForRobloxRuntime()

	startupCheckpoint("dependency setup")

local function getService(Name)
	local Service = game:GetService(Name)

	if type(cloneref) == "function" then
		local Success, ClonedService = pcall(cloneref, Service)

		if Success and typeof(ClonedService) == "Instance" then
			return ClonedService
		end
	end

	return Service
end

local ReplicatedStorage = getService("ReplicatedStorage")
local Workspace = getService("Workspace")
local Players = getService("Players")
local RunService = getService("RunService")
local CollectionService = getService("CollectionService")
local ContextActionService = getService("ContextActionService")
local UserInputService = getService("UserInputService")
local HttpService = getService("HttpService")
local CoreGui = getService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local function queryDescendants(Root, Selector)
	if typeof(Root) ~= "Instance" or type(Root.QueryDescendants) ~= "function" then
		return {}
	end

	local Success, Results = pcall(Root.QueryDescendants, Root, Selector)
	return if Success and type(Results) == "table" then Results else {}
end

local function processInBatches(Objects, Callback, BatchSize)
	BatchSize = BatchSize or 40

	for Index = 1, #Objects do
		Callback(Objects[Index])

		if Index % BatchSize == 0 then
			RunService.Heartbeat:Wait()
		end
	end
end

local function getNotorietyUIParent()
	ensureExecutorIdentity()

	if type(gethui) == "function" then
		local Success, Parent = pcall(gethui)

		if Success and typeof(Parent) == "Instance" then
			return Parent
		end
	end

	return CoreGui
end

local RS_Package = waitForStartupChild(ReplicatedStorage, "RS_Package")
local Assets = waitForStartupChild(RS_Package, "Assets")
local Remotes = waitForStartupChild(Assets, "Remotes")
local Event = waitForStartupChild(Remotes, "Damage")

local NotorietyUI = {}

do
	local VibeUISource = game:HttpGet(
		"https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"
	)
	startupCheckpoint("VibeUI download")
	VibeUISource = VibeUISource:gsub("\r\n", "\n")
	local VibeUIAnchorLoopPatchCount
	VibeUISource, VibeUIAnchorLoopPatchCount = VibeUISource:gsub(
		"LibMaid:GiveTask%(RunService%.RenderStepped:Connect%(function%(%)[\n]",
		"LibMaid:GiveTask(RunService.RenderStepped:Connect(function()\n\tif next(Anchors) == nil then return end\n",
		1
	)

	if VibeUIAnchorLoopPatchCount ~= 1 then
		error("VibeUI idle anchor-loop compatibility patch failed")
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
		if SharedEnvironment then
			rawset(SharedEnvironment, "VibeUI", PreviousSharedVibeUI)
		end

		rawset(Environment, "VibeUI", PreviousEnvironmentVibeUI)
		error("VibeUI compile failed: " .. tostring(VibeUICompileError))
	end

	local VibeUISuccess, VibeUI = pcall(VibeUIChunk)
	startupCheckpoint("VibeUI initialization")

	if SharedEnvironment then
		rawset(SharedEnvironment, "VibeUI", PreviousSharedVibeUI)
	end

	rawset(Environment, "VibeUI", PreviousEnvironmentVibeUI)

	if not VibeUISuccess or type(VibeUI) ~= "table" then
		error("VibeUI load failed: " .. tostring(VibeUI))
	end

	local Adapter = {
		IsVibeUIAdapter = true,
		ScreenGui = nil,
	}

	function Adapter:IsCorrectInput(Input, Target)
		return Input ~= nil
			and typeof(Target) == "EnumItem"
			and (Input.KeyCode == Target or Input.UserInputType == Target)
	end

	function Adapter:CreateWindow(Configuration)
		local NativeWindow = VibeUI:Window({
			Title = Configuration.Title,
			Size = Configuration.Size,
			Keybind = Environment.NotorietyToggleUIKey or Enum.KeyCode.RightShift,
			Layout = "Side",
			Resizable = true,
		})
		local Tabs = {}
		local Window = {}
		local NativeRoot = NativeWindow._root

		Adapter.ScreenGui = if typeof(NativeRoot) == "Instance"
			then NativeRoot:FindFirstAncestorOfClass("ScreenGui")
			else nil

		function Window:SetTheme(_Theme)
		end

		function Window:AddTab(Name)
			local NativeTab = NativeWindow:Tab({
				Name = Name,
				Columns = 1,
			})
			local NativeSection = NativeTab:Section({
				Name = Name,
				Side = 1,
			})
			local Tab = {}
			Tabs[Name] = NativeTab

			function Tab:New(Kind)
				return function(Config)
					local FlagTitle = (Config.Title or "Control"):gsub("%W+", "_")
					local Flag = string.format(
						"Notoriety_%s_%s_%s",
						Name,
						Kind,
						FlagTitle
					)

					if Kind == "Button" then
						local Row = NativeSection:Button()
						Row:Add(Config.Title, Config.Callback)
						return Row
					elseif Kind == "Toggle" then
						return NativeSection:Toggle({
							Name = Config.Title,
							Flag = Flag,
							Default = Config.DefaultValue,
							Tooltip = Config.Description,
							Callback = Config.Callback,
						})
					elseif Kind == "Input" then
						return NativeSection:Textbox({
							Name = Config.Title,
							Flag = Flag,
							Default = Config.DefaultText,
							Placeholder = Config.Placeholder,
							Finished = true,
							Tooltip = Config.Description,
							Callback = Config.Callback,
						})
					elseif Kind == "Slider" then
						return NativeSection:Slider({
							Name = Config.Title,
							Flag = Flag,
							Min = Config.Min,
							Max = Config.Max,
							Default = Config.DefaultValue,
							Decimals = Config.Step,
							Suffix = Config.Suffix,
							Tooltip = Config.Description,
							Callback = Config.Callback,
						})
					elseif Kind == "Dropdown" then
						return NativeSection:Dropdown({
							Name = Config.Title,
							Flag = Flag,
							Items = Config.Options,
							Default = Config.Default,
							Tooltip = Config.Description,
							Callback = Config.Callback,
						})
					elseif Kind == "Keybind" then
						local DefaultInput = Enum.KeyCode[Config.DefaultKeybind]
							or Enum.UserInputType[Config.DefaultKeybind]
							or Enum.KeyCode.RightShift
						return NativeSection:Label(Config.Title):AddKeybind({
							Name = Config.Title,
							Flag = Flag,
							Default = DefaultInput,
							Mode = "Toggle",
							OnChanged = function(Key)
								local KeyName = tostring(Key):match("([^%.]+)$")
								local Input = KeyName
									and (Enum.KeyCode[KeyName] or Enum.UserInputType[KeyName])
									or nil

								if Input then
									VibeUI.Config.MenuKeybind = Input
									Config.Callback(Input)
								end
							end,
						})
					end

					error("Unsupported VibeUI component: " .. tostring(Kind))
				end
			end

			return Tab
		end

		function Window:SetTab(Name)
			local Tab = Tabs[Name]

			if Tab then
				pcall(function()
					Tab:Turn(true)
				end)
			end
		end

		function Window:Notify(Config)
			return VibeUI:Notification({
				Title = Config.Title,
				Description = Config.Description,
				Type = string.lower(Config.Type or "info"),
				Duration = Config.Duration,
			})
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

		return Window
	end

	NotorietyUI.Library = Adapter
end

startupCheckpoint("runtime construction")

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

if type(Environment.NotorietyMaxValueConnections) == "table" then
	for _, Connection in Environment.NotorietyMaxValueConnections do
		pcall(function()
			Connection:Disconnect()
		end)
	end
end

Environment.NotorietyMaxValueConnections = {}

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
Environment.NotorietyMeleeReachEnabled = Environment.NotorietyMeleeReachEnabled == true
Environment.NotorietyMeleeReach = math.clamp(
	tonumber(Environment.NotorietyMeleeReach) or 25,
	5,
	100
)
Environment.NotorietySawReachEnabled = Environment.NotorietySawReachEnabled == true
Environment.NotorietySawReach = math.clamp(
	tonumber(Environment.NotorietySawReach) or 25,
	10,
	250
)
Environment.NotorietyPoliceHeadScaleEnabled = Environment.NotorietyPoliceHeadScaleEnabled == true
Environment.NotorietyPoliceHeadScale = math.clamp(
	tonumber(Environment.NotorietyPoliceHeadScale) or 10,
	1,
	20
)
Environment.NotorietyItemESPEnabled = false
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
Environment.NotorietyAutoYellEnabled = Environment.NotorietyAutoYellEnabled == true
Environment.NotorietyNoYellDelayEnabled = Environment.NotorietyNoYellDelayEnabled == true

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
	HadOwnTick = false,
	WrappedTick = nil,
	EquipmentPercent = nil,
	ClockActive = false,
	RealAnchor = nil,
	ScaledAnchor = nil,
	LastMultiplier = nil,
	OriginalCFrame = nil,
	HadOwnCFrame = false,
	WrappedCFrame = nil,
	CFrameLookAtCount = 0,
	Refresh = 0,
	DiscoveryAttempted = false,
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

local function restoreEquipmentPlacementSpeed()
	local FunctionEnvironment = EquipmentSpeedState.FunctionEnvironment
	local WrappedTick = EquipmentSpeedState.WrappedTick
	local WrappedCFrame = EquipmentSpeedState.WrappedCFrame

	if type(FunctionEnvironment) == "table"
		and type(WrappedTick) == "function"
		and rawget(FunctionEnvironment, "tick") == WrappedTick
	then
		if EquipmentSpeedState.HadOwnTick then
			rawset(FunctionEnvironment, "tick", EquipmentSpeedState.OriginalTick)
		else
			rawset(FunctionEnvironment, "tick", nil)
		end
	end

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
	EquipmentSpeedState.HadOwnTick = false
	EquipmentSpeedState.WrappedTick = nil
	EquipmentSpeedState.EquipmentPercent = nil
	EquipmentSpeedState.ClockActive = false
	EquipmentSpeedState.RealAnchor = nil
	EquipmentSpeedState.ScaledAnchor = nil
	EquipmentSpeedState.LastMultiplier = nil
	EquipmentSpeedState.OriginalCFrame = nil
	EquipmentSpeedState.HadOwnCFrame = false
	EquipmentSpeedState.WrappedCFrame = nil
	EquipmentSpeedState.CFrameLookAtCount = 0
	EquipmentSpeedState.Refresh = 0
	EquipmentSpeedState.DiscoveryAttempted = false
end

local function findEquipmentPlacementFunction()
	local Existing = EquipmentSpeedState.Function
	local FunctionEnvironment = EquipmentSpeedState.FunctionEnvironment
	local WrappedTick = EquipmentSpeedState.WrappedTick

	if typeof(Existing) == "Instance"
		and type(FunctionEnvironment) == "table"
		and type(WrappedTick) == "function"
		and rawget(FunctionEnvironment, "tick") == WrappedTick
	then
		return Existing
	end

	if type(getsenv) ~= "function" then
		return nil
	end

	if EquipmentSpeedState.DiscoveryAttempted then
		return nil
	end

	EquipmentSpeedState.DiscoveryAttempted = true
	local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
	local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
	local LocalMovement = SGPackage and SGPackage:FindFirstChild("LocalMovement")

	if not LocalMovement or not LocalMovement:IsA("LocalScript") then
		return nil
	end

	local EnvironmentSuccess, FunctionEnvironmentResult = pcall(getsenv, LocalMovement)

	if EnvironmentSuccess and type(FunctionEnvironmentResult) == "table" then
		EquipmentSpeedState.Function = LocalMovement
		EquipmentSpeedState.FunctionEnvironment = FunctionEnvironmentResult
		return LocalMovement
	end

	return nil
end

local function applyEquipmentPlacementSpeed()
	if Environment.NotorietyUnloaded then
		return false
	end

	local Function = findEquipmentPlacementFunction()

	if not Function then
		return false
	end

	local FunctionEnvironment = EquipmentSpeedState.FunctionEnvironment
	local ExistingWrapper = EquipmentSpeedState.WrappedTick

	if type(FunctionEnvironment) ~= "table" then
		return false
	end

	if type(ExistingWrapper) == "function"
		and rawget(FunctionEnvironment, "tick") == ExistingWrapper
	then
		return true
	end

	local OriginalTick = FunctionEnvironment.tick

	if type(OriginalTick) ~= "function" then
		return false
	end

	local HadOwnTick = rawget(FunctionEnvironment, "tick") ~= nil
	local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
	local SGPackage = PlayerGui and PlayerGui:FindFirstChild("SG_Package")
	local MainGui = SGPackage and SGPackage:FindFirstChild("MainGui")
	local Interaction = MainGui and MainGui:FindFirstChild("Interaction")
	local EquipmentPercent = Interaction and Interaction:FindFirstChild("EquipmentPercent")

	if not EquipmentPercent then
		return false
	end

	local function WrappedTick(...)
		local Now = OriginalTick(...)

		if Environment.NotorietyUnloaded
			or typeof(EquipmentPercent) ~= "Instance"
			or EquipmentPercent.Parent == nil
			or not EquipmentPercent.Visible
		then
			EquipmentSpeedState.ClockActive = false
			EquipmentSpeedState.RealAnchor = nil
			EquipmentSpeedState.ScaledAnchor = nil
			EquipmentSpeedState.LastMultiplier = nil
			return Now
		end

		local Multiplier = getEquipmentSpeedMultiplier()

		if not EquipmentSpeedState.ClockActive then
			EquipmentSpeedState.CFrameLookAtCount = 0
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

	EquipmentSpeedState.OriginalTick = OriginalTick
	EquipmentSpeedState.HadOwnTick = HadOwnTick
	EquipmentSpeedState.WrappedTick = WrappedTick
	EquipmentSpeedState.EquipmentPercent = EquipmentPercent
	rawset(FunctionEnvironment, "tick", WrappedTick)

	return rawget(FunctionEnvironment, "tick") == WrappedTick
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
	NoDelayDiscoveryAttempted = false,
	TargetParts = setmetatable({}, {
		__mode = "k",
	}),
	SkillCache = {},
}
Environment.NotorietyYellPatchState = YellPatchState

local function isYellModule(Module)
	return type(Module) == "table" and type(rawget(Module, "Yell")) == "function"
end

local function getYellModule()
	if isYellModule(YellPatchState.LiveModule) then
		return YellPatchState.LiveModule
	end

	local DirectStorage = game:GetService("ReplicatedStorage")
	local DirectPackage = DirectStorage:FindFirstChild("RS_Package")
	local ReplicatedScripts = DirectPackage and DirectPackage:FindFirstChild("ReplicatedScripts")
	local YellScript = ReplicatedScripts and ReplicatedScripts:FindFirstChild("Yell")

	if not YellScript or not YellScript:IsA("ModuleScript") then
		return nil
	end

	local Success, Result = pcall(require, YellScript)

	if Success and isYellModule(Result) then
		YellPatchState.LiveModule = Result
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

local function createViewportYellWrapper()
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

					if TargetPart and isPartInViewport(TargetPart, Camera) then
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

					if TargetPart and isPartInViewport(TargetPart, Camera) then
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

						if TargetPart and isPartInViewport(TargetPart, Camera) then
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

				if TargetPart and isPartInViewport(TargetPart, Camera) then
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
	YellPatchState.LastApplyAttempt = os.clock()

	if Environment.NotorietyUnloaded or not Environment.NotorietyInfiniteYellMarkEnabled then
		YellPatchState.LastApplySuccess = false
		return false
	end

	local Module = getYellModule()

	if not Module then
		YellPatchState.LastApplySuccess = false
		return false
	end

	if YellPatchState.Module == Module
		and type(YellPatchState.Wrapper) == "function"
		and Module.Yell == YellPatchState.Wrapper
	then
		YellPatchState.LastApplySuccess = true
		return true
	end

	restoreYellMarkPatch()

	local Original = Module.Yell

	if type(Original) ~= "function" then
		YellPatchState.LastApplySuccess = false
		return false
	end

	local Wrapper = createViewportYellWrapper()
	YellPatchState.Module = Module
	YellPatchState.Original = Original
	YellPatchState.Wrapper = Wrapper
	Module.Yell = Wrapper

	YellPatchState.LastApplySuccess = Module.Yell == Wrapper
	return YellPatchState.LastApplySuccess
end

local function setYellMarkPatchEnabled(Enabled)
	Environment.NotorietyInfiniteYellMarkEnabled = Enabled == true

	if Environment.NotorietyInfiniteYellMarkEnabled then
		applyYellMarkPatch()
	else
		restoreYellMarkPatch()
	end
end

YellPatchState.RefreshNoDelayTargets = function()
	table.clear(YellPatchState.NoDelayTargets)

	if type(getconnections) ~= "function"
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

	if YellPatchState.NoDelayDiscoveryAttempted then
		return false
	end

	YellPatchState.NoDelayDiscoveryAttempted = true
	local Success, Objects = pcall(getconnections, UserInputService.InputBegan)

	if not Success or type(Objects) ~= "table" then
		return false
	end

	for _, Connection in pairs(Objects) do
		local FunctionSuccess, Function = pcall(function()
			return Connection.Function
		end)

		if not FunctionSuccess then
			Function = nil
		end

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
		YellPatchState.NoDelayDiscoveryAttempted = false
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

local DEFAULT_POLICE_HEAD_STATE = {
	Size = Vector3.new(1.1908922, 1.1954262, 1.1909529),
	Transparency = 0,
	Massless = false,
	CanCollide = false,
}

local function isReasonablePoliceHeadSize(Size)
	return typeof(Size) == "Vector3"
		and Size.X >= 0.25
		and Size.Y >= 0.25
		and Size.Z >= 0.25
		and Size.X <= 4
		and Size.Y <= 4
		and Size.Z <= 4
end

local function looksLikeModifiedPoliceHead(Head)
	return Head.Transparency == 0.5 and Head.Massless and not Head.CanCollide
end

local function copyPoliceHeadState(State)
	return {
		Size = State.Size,
		Transparency = State.Transparency,
		Massless = State.Massless,
		CanCollide = State.CanCollide,
	}
end

local function getReferencePoliceHeadState(ExcludedHead)
	local Folder = Workspace:FindFirstChild("Police")

	if Folder then
		for _, NPC in Folder:GetChildren() do
			local Head = NPC:FindFirstChild("Head")
			local Stored = Head and PoliceOriginalSizes[Head]
			local StoredSize = typeof(Stored) == "Vector3" and Stored
				or (type(Stored) == "table" and Stored.Size or nil)

			if Head ~= ExcludedHead and isReasonablePoliceHeadSize(StoredSize) then
				if typeof(Stored) == "Vector3" then
					return {
						Size = Stored,
						Transparency = Head.Transparency,
						Massless = Head.Massless,
						CanCollide = Head.CanCollide,
					}
				end

				return copyPoliceHeadState(Stored)
			end
		end

		for _, NPC in Folder:GetChildren() do
			local Head = NPC:FindFirstChild("Head")

			if Head ~= ExcludedHead
				and Head
				and Head:IsA("BasePart")
				and isReasonablePoliceHeadSize(Head.Size)
				and not looksLikeModifiedPoliceHead(Head)
			then
				return {
					Size = Head.Size,
					Transparency = Head.Transparency,
					Massless = Head.Massless,
					CanCollide = Head.CanCollide,
				}
			end
		end
	end

	return copyPoliceHeadState(DEFAULT_POLICE_HEAD_STATE)
end

local function applyPoliceHeadState(Head, State)
	Head.Size = State.Size
	Head.Transparency = State.Transparency
	Head.Massless = State.Massless
	Head.CanCollide = State.CanCollide
end

local function restorePolicePart(Object)
	local Original = PoliceOriginalSizes[Object]

	if Object.Parent and Original then
		if typeof(Original) == "Vector3" then
			if isReasonablePoliceHeadSize(Original) then
				Object.Size = Original
			else
				applyPoliceHeadState(Object, getReferencePoliceHeadState(Object))
			end
		else
			if not isReasonablePoliceHeadSize(Original.Size) then
				Original = getReferencePoliceHeadState(Object)
			end

			applyPoliceHeadState(Object, Original)
		end

		PoliceOriginalSizes[Object] = nil
	end
end

local function resizePoliceNPC(NPC)
	if not NPC or not NPC:IsA("Model") then
		return
	end

	local Head = NPC:FindFirstChild("Head")

	if not Environment.NotorietyPoliceHeadScaleEnabled then
		if Head and Head:IsA("BasePart") then
			if PoliceOriginalSizes[Head] then
				restorePolicePart(Head)
			elseif not isReasonablePoliceHeadSize(Head.Size) or looksLikeModifiedPoliceHead(Head) then
				applyPoliceHeadState(Head, getReferencePoliceHeadState(Head))
			end
		end

		return
	end

	if Head and Head:IsA("BasePart") then
		local Original = PoliceOriginalSizes[Head]
		local OriginalSize = typeof(Original) == "Vector3" and Original
			or (type(Original) == "table" and Original.Size or nil)

		if not isReasonablePoliceHeadSize(OriginalSize) then
			if isReasonablePoliceHeadSize(Head.Size) and not looksLikeModifiedPoliceHead(Head) then
				PoliceOriginalSizes[Head] = {
					Size = Head.Size,
					Transparency = Head.Transparency,
					Massless = Head.Massless,
					CanCollide = Head.CanCollide,
				}
			else
				PoliceOriginalSizes[Head] = getReferencePoliceHeadState(Head)
			end
		elseif typeof(Original) == "Vector3" then
			PoliceOriginalSizes[Head] = {
				Size = Original,
				Transparency = Head.Transparency,
				Massless = Head.Massless,
				CanCollide = Head.CanCollide,
			}
		end

		Original = PoliceOriginalSizes[Head]
		Head.Size = Original.Size * Environment.NotorietyPoliceHeadScale
		Head.Transparency = 0.5
		Head.Massless = true
		Head.CanCollide = false
	end
end

local function applyPoliceHeadScale()
	local Folder = Workspace:FindFirstChild("Police")

	if not Folder then
		return
	end

	if not Environment.NotorietyPoliceHeadScaleEnabled then
		for Object in PoliceOriginalSizes do
			pcall(restorePolicePart, Object)
		end
	end

	for _, NPC in Folder:GetChildren() do
		resizePoliceNPC(NPC)
	end
end

local function setPoliceHeadScaleEnabled(Enabled)
	Environment.NotorietyPoliceHeadScaleEnabled = Enabled == true
	applyPoliceHeadScale()
end

local PoliceHeadScaleState = {
	Apply = applyPoliceHeadScale,
	SetEnabled = setPoliceHeadScaleEnabled,
}
Environment.NotorietyPoliceHeadScaleState = PoliceHeadScaleState

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

if PoliceFolder then
	local PoliceConnection

	PoliceConnection = PoliceFolder.DescendantAdded:Connect(
		function(Object)
			if not isCurrentNotorietyRun() then
				disconnectBootstrapConnection(PoliceConnection)
				return
			end

			local NPC = getPoliceNPC(Object, PoliceFolder)

			if NPC then
				task.defer(resizePoliceNPC, NPC)
			end
		end
	)
	Environment.NotorietyPoliceHitboxConnection = PoliceConnection
end

local PreviousMeleeReachState = rawget(Environment, "NotorietyMeleeReachHookState")

if type(PreviousMeleeReachState) == "table" then
	PreviousMeleeReachState.Enabled = false
end

local MeleeReachState = {
	Enabled = false,
	Installed = false,
}
Environment.NotorietyMeleeReachHookState = MeleeReachState

local NamecallState = rawget(Environment, "NotorietyNamecallHookState")

if type(NamecallState) ~= "table" then
	NamecallState = {
		Installed = false,
		Version = 2,
	}
	Environment.NotorietyNamecallHookState = NamecallState
end

local function setMeleeReachEnabled(Enabled)
	Environment.NotorietyMeleeReachEnabled = Enabled == true
	MeleeReachState.Enabled = Environment.NotorietyMeleeReachEnabled
end

local function isMeleeOverlapParameters(Parameters)
	if typeof(Parameters) ~= "OverlapParams" or Parameters.MaxParts ~= 60 then
		return false
	end

	local Filter = Parameters.FilterDescendantsInstances
	local Camera = Workspace.CurrentCamera
	local Character = LocalPlayer.Character

	return type(Filter) == "table"
		and Camera ~= nil
		and Character ~= nil
		and table.find(Filter, Camera) ~= nil
		and table.find(Filter, Character) ~= nil
end

local function dispatchNotorietyNamecall(State, Self, ...)
	local OriginalNamecall = State.OriginalNamecall

	if type(OriginalNamecall) ~= "function" then
		return nil
	end

	if Self ~= Workspace or checkcaller() then
		return OriginalNamecall(Self, ...)
	end

	local Method = getnamecallmethod()

	if Method == "GetPartBoundsInBox" and MeleeReachState.Enabled then
		local Arguments = table.pack(...)
		local Parameters = Arguments[3]

		if isMeleeOverlapParameters(Parameters) then
			local Camera = Workspace.CurrentCamera
			local Reach = math.clamp(tonumber(Environment.NotorietyMeleeReach) or 25, 5, 100)
			local Width = math.clamp(Reach * 0.3, 5, 8)

			Arguments[1] = Camera.CFrame * CFrame.new(0, 0, -Reach * 0.5)
			Arguments[2] = Vector3.new(Width, Width, Reach)
			MeleeReachState.LastReach = Reach
			MeleeReachState.ApplyCount = (MeleeReachState.ApplyCount or 0) + 1
			return OriginalNamecall(Self, table.unpack(Arguments, 1, Arguments.n))
		end
	end

	return OriginalNamecall(Self, ...)
end

local function installNamecallHook()
	NamecallState.Dispatch = dispatchNotorietyNamecall
	NamecallState.Owner = LoadState

	if NamecallState.Installed
		and NamecallState.Version == 2
		and type(NamecallState.OriginalNamecall) == "function"
		and type(NamecallState.Hook) == "function"
	then
		return true
	end

	if type(hookmetamethod) ~= "function"
		or type(checkcaller) ~= "function"
		or type(getnamecallmethod) ~= "function"
	then
		NamecallState.Dispatch = nil
		return false
	end

	local Hook = function(Self, ...)
		local Dispatch = NamecallState.Dispatch

		if type(Dispatch) == "function" then
			local Results = table.pack(pcall(Dispatch, NamecallState, Self, ...))

			if Results[1] then
				return table.unpack(Results, 2, Results.n)
			end

			NamecallState.LastError = tostring(Results[2])
		end

		local OriginalNamecall = NamecallState.OriginalNamecall

		if type(OriginalNamecall) == "function" then
			return OriginalNamecall(Self, ...)
		end

		return nil
	end

	if type(newcclosure) == "function" then
		local WrapSuccess, WrappedHook = pcall(newcclosure, Hook)

		if WrapSuccess and type(WrappedHook) == "function" then
			Hook = WrappedHook
		end
	end

	local Success, Previous = pcall(hookmetamethod, game, "__namecall", Hook)

	if not Success or type(Previous) ~= "function" then
		NamecallState.Dispatch = nil
		NamecallState.LastError = tostring(Previous)
		return false
	end

	NamecallState.OriginalNamecall = Previous
	NamecallState.Hook = Hook
	NamecallState.Installed = true
	NamecallState.Version = 2
	return true
end

local function installMeleeReachHook()
	MeleeReachState.Enabled = Environment.NotorietyMeleeReachEnabled
	MeleeReachState.Installed = installNamecallHook()
	MeleeReachState.HookVersion = 2
	return MeleeReachState.Installed
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

local MaxValueObjects = setmetatable({}, {
	__mode = "k",
})
local MaxValueCharacter

local function clearMaxValueTracking()
	for _, Connection in Environment.NotorietyMaxValueConnections do
		disconnectBootstrapConnection(Connection)
	end

	table.clear(Environment.NotorietyMaxValueConnections)
	table.clear(MaxValueObjects)
	MaxValueCharacter = nil
end

local function trackMaxValueObject(Object)
	if not Object:IsA("ValueBase") or MaxedValues[Object.Name] == nil then
		return
	end

	MaxValueObjects[Object] = if Object:FindFirstAncestorWhichIsA("Tool") then nil else true
end

local function setMaxValueCharacter(Character)
	if Character == MaxValueCharacter then
		return
	end

	clearMaxValueTracking()

	if typeof(Character) ~= "Instance" then
		return
	end

	MaxValueCharacter = Character
	processInBatches(queryDescendants(Character, "ValueBase"), trackMaxValueObject, 80)
	table.insert(
		Environment.NotorietyMaxValueConnections,
		Character.DescendantAdded:Connect(trackMaxValueObject)
	)
	table.insert(
		Environment.NotorietyMaxValueConnections,
		Character.DescendantRemoving:Connect(function(Object)
			MaxValueObjects[Object] = nil
		end)
	)
end

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

local function isSawWeaponData(Data)
	if type(Data) ~= "table" or rawget(Data, "WeaponType") ~= "Gun" then
		return false
	end

	local BulletType = rawget(Data, "BulletType")
	local FireMode = rawget(Data, "FireMode")

	return BulletType == "saw"
		or (type(FireMode) == "string" and string.find(FireMode, "Saw", 1, true) ~= nil)
end

local function shouldApplyWeaponData()
	return Environment.NotorietyWeaponEnabled or Environment.NotorietySawReachEnabled
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
	if type(Data) ~= "table" then
		return false
	end

	local WeaponType = rawget(Data, "WeaponType")
	local ApplySawReach = Environment.NotorietySawReachEnabled and isSawWeaponData(Data)

	if not Environment.NotorietyWeaponEnabled and not ApplySawReach then
		return false
	end

	if WeaponType == "Gun" then
		local StandardGun = isStandardGunData(Data)
		local Backup = getWeaponBackup(Data)

		if ApplySawReach then
			captureField(Data, Backup, "BulletRange")
			Data.BulletRange = math.clamp(tonumber(Environment.NotorietySawReach) or 25, 10, 250)
		end

		if not Environment.NotorietyWeaponEnabled then
			return ApplySawReach
		end

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
	-- Requiring the targeted Data modules is the only supported path. Walking the
	-- entire LocalGuns environment caused multi-second stalls on some executors.
	return 0

	--[[ Disabled legacy fallback retained below only for source-history context.
	local ScriptEnvironment = getLocalGunsEnvironment()

	if not ScriptEnvironment then
		return 0
	end

	local Seen = {}
	local Patched = 0
	local Nodes = 0
	local NodeLimit = 12000
	local Pending = {}
	local PendingIndex = 1
	local Discovered = 0

	local function Queue(Value, Depth)
		if Discovered >= NodeLimit
			or Depth > 8
			or type(Value) ~= "table"
			or Seen[Value]
		then
			return
		end

		Seen[Value] = true
		Discovered += 1
		table.insert(Pending, {
			Value = Value,
			Depth = Depth,
		})
	end

	for _, Value in ScriptEnvironment do
		if type(Value) == "table" then
			Queue(Value, 0)
		elseif type(Value) == "function" then
			local Upvalues = getFunctionUpvalues(Value)

			if type(Upvalues) == "table" then
				for _, Item in Upvalues do
					if type(Item) == "table" then
						Queue(Item, 0)
					end
				end
			end
		end
	end

	while PendingIndex <= #Pending and Nodes < NodeLimit do
		local Record = Pending[PendingIndex]
		PendingIndex += 1
		Nodes += 1
		local Value = Record.Value
		local Depth = Record.Depth

		if applyWeaponData(Value) then
			Patched += 1
		end

		patchRuntimeWeaponState(Value)

		for Key, Item in Value do
			Queue(Key, Depth + 1)
			Queue(Item, Depth + 1)
		end

		if Nodes % 100 == 0 then
			RunService.Heartbeat:Wait()
		end
	end

	return Patched ]]
end

local function queueLoadedWeaponFallback()
	if not shouldApplyWeaponData() or WeaponState.FallbackQueued then
		return
	end

	WeaponState.FallbackQueued = true

	task.delay(0.25, function()
		if not shouldApplyWeaponData() then
			WeaponState.FallbackQueued = false
			return
		end

		local Patched = patchLoadedWeaponTables()
		WeaponState.FallbackQueued = false

		if Patched > 0 then
			WeaponState.FallbackAttempts = 0
		elseif WeaponState.RequireUnavailable and WeaponState.FallbackAttempts < 4 then
			WeaponState.FallbackAttempts += 1
			task.delay(2, queueLoadedWeaponFallback)
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
	if not shouldApplyWeaponData()
		or not Object:IsA("ModuleScript")
		or Object.Name ~= "Data"
	then
		return
	end

	local Data = getModuleData(Object)

	if Data then
		applyWeaponData(Data)
	end
end

local function trackWeaponContainer(Container)
	if Environment.NotorietyUnloaded or not Container then
		return
	end

	processInBatches(queryDescendants(Container, "ModuleScript#Data"), applyWeaponModule)

	table.insert(
		Environment.NotorietyWeaponConnections,
		Container.DescendantAdded:Connect(function(Object)
			if Environment.NotorietyUnloaded then
				return
			end

			if Object:IsA("ModuleScript") and Object.Name == "Data" then
				task.defer(function()
					applyWeaponModule(Object)
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

	if Character ~= MaxValueCharacter then
		setMaxValueCharacter(Character)
	end

	for Object in MaxValueObjects do
		if Object.Parent == nil then
			MaxValueObjects[Object] = nil
		else
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
			NotorietyUI.Window:Notify({
				Title = "Kill Police",
				Description = string.format("Finished. Killed %d police.", Killed),
				Duration = 3,
				Type = "Success",
			})
		end)
	end
end

local Weapons = Assets:FindFirstChild("Weapons")
local Backpack = waitForStartupChild(LocalPlayer, "Backpack")

local function applyAllWeaponModifications()
	if not shouldApplyWeaponData() then
		return
	end

	for _, Container in {
		Weapons,
		Backpack,
		LocalPlayer.Character,
	} do
		if Container then
			processInBatches(queryDescendants(Container, "ModuleScript#Data"), applyWeaponModule)
		end
	end

end

local function refreshTrackedWeaponModifications()
	if not Environment.NotorietyWeaponEnabled then
		return
	end

	for Data in WeaponState.Backups do
		applyWeaponData(Data)
	end

	refreshRuntimeAmmo()
end

local function setWeaponModificationsEnabled(Enabled)
	Environment.NotorietyWeaponEnabled = Enabled == true
	restoreAllWeaponData()
	restoreRuntimeWeaponAccuracy()

	if shouldApplyWeaponData() then
		applyAllWeaponModifications()
	end
end

local function setSawReachEnabled(Enabled)
	Environment.NotorietySawReachEnabled = Enabled == true
	restoreAllWeaponData()

	if shouldApplyWeaponData() then
		applyAllWeaponModifications()
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

	local BoxSuccess, Box = pcall(Instance.new, "BoxHandleAdornment")

	if not BoxSuccess or typeof(Box) ~= "Instance" then
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

	local FolderSuccess, Folder = pcall(Instance.new, "Folder")

	if not FolderSuccess or typeof(Folder) ~= "Instance" then
		return false
	end

	Folder.Name = "NotorietyItemESP"
	Folder.Archivable = false

	local Parent = getNotorietyUIParent()

	if typeof(Parent) ~= "Instance" then
		pcall(function()
			Folder:Destroy()
		end)
		return false
	end

	Folder.Parent = Parent
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
		startItemESP()
	else
		stopItemESP()
	end
end

local ItemESPController = {}

function ItemESPController.Cleanup()
	Environment.NotorietyItemESPEnabled = false
	stopItemESP()
end

function ItemESPController.IsRunning()
	return ItemESPState.Folder ~= nil and ItemESPState.Folder.Parent ~= nil
end

Environment.NotorietyItemESPController = ItemESPController

local NOTORIETY_CONFIG_FOLDER = "Notoriety"
local NOTORIETY_CONFIG_PATH = NOTORIETY_CONFIG_FOLDER .. "/default.json"

local function isFiniteNumber(Value)
	return type(Value) == "number"
		and Value == Value
		and Value ~= math.huge
		and Value ~= -math.huge
end

local function getSavedToggleInput(Name, InputType)
	if type(Name) ~= "string" then
		return nil
	end

	local InputEnum = if InputType == "UserInputType"
		then Enum.UserInputType
		else Enum.KeyCode

	for _, Input in InputEnum:GetEnumItems() do
		if Input.Name == Name then
			return Input
		end
	end

	return nil
end

local function isSupportedToggleInput(Value)
	if typeof(Value) ~= "EnumItem" then
		return false
	end

	return table.find(Enum.KeyCode:GetEnumItems(), Value) ~= nil
		or table.find(Enum.UserInputType:GetEnumItems(), Value) ~= nil
end

local function loadNotorietyConfig()
	if type(readfile) ~= "function" then
		return
	end

	local Success, Data = pcall(function()
		return HttpService:JSONDecode(readfile(NOTORIETY_CONFIG_PATH))
	end)

	if not Success or type(Data) ~= "table" then
		return
	end

	local BooleanFields = {
		InfiniteYellMark = "NotorietyInfiniteYellMarkEnabled",
		AutoYell = "NotorietyAutoYellEnabled",
		NoYellDelay = "NotorietyNoYellDelayEnabled",
		ItemESP = "NotorietyItemESPEnabled",
		WeaponMods = "NotorietyWeaponEnabled",
		MeleeReachEnabled = "NotorietyMeleeReachEnabled",
		SawReachEnabled = "NotorietySawReachEnabled",
		PoliceHeadScaleEnabled = "NotorietyPoliceHeadScaleEnabled",
		EquipmentSpeedEnabled = "NotorietyEquipmentSpeedEnabled",
		EquipmentPositionEnabled = "NotorietyEquipmentPositionEnabled",
	}

	for ConfigKey, EnvironmentKey in BooleanFields do
		if type(Data[ConfigKey]) == "boolean" then
			Environment[EnvironmentKey] = Data[ConfigKey]
		end
	end

	if isFiniteNumber(Data.FireDelay) then
		Environment.NotorietyFireDelay = math.clamp(Data.FireDelay, 0, 1)
	end

	if isFiniteNumber(Data.BoltDuration) then
		Environment.NotorietyBoltDuration = math.clamp(Data.BoltDuration, 0, 1)
	end

	if isFiniteNumber(Data.GunAccuracy) then
		Environment.NotorietyAccuracy = math.clamp(Data.GunAccuracy, 0, 100)
	end

	if isFiniteNumber(Data.MeleeReach) then
		Environment.NotorietyMeleeReach = math.clamp(Data.MeleeReach, 5, 100)
	end

	if isFiniteNumber(Data.SawReach) then
		Environment.NotorietySawReach = math.clamp(Data.SawReach, 10, 250)
	end

	if isFiniteNumber(Data.PoliceHeadScale) then
		Environment.NotorietyPoliceHeadScale = math.clamp(Data.PoliceHeadScale, 1, 20)
	end

	if isFiniteNumber(Data.EquipmentSpeedMultiplier)
		and Data.EquipmentSpeedMultiplier > 0
	then
		Environment.NotorietyEquipmentSpeedMultiplier = math.clamp(Data.EquipmentSpeedMultiplier, 1, 10)
	end

	for ConfigKey, EnvironmentKey in {
		EquipmentPositionX = "NotorietyEquipmentPositionX",
		EquipmentPositionY = "NotorietyEquipmentPositionY",
		EquipmentPositionZ = "NotorietyEquipmentPositionZ",
	} do
		if isFiniteNumber(Data[ConfigKey]) then
			Environment[EnvironmentKey] = math.clamp(Data[ConfigKey], -50, 50)
		end
	end

	local ToggleInput = getSavedToggleInput(Data.ToggleUIKey, Data.ToggleUIInputType)

	if ToggleInput then
		Environment.NotorietyToggleUIKey = ToggleInput
	end
end

local function saveNotorietyConfig()
	if type(writefile) ~= "function" then
		return
	end

	local ToggleInput = Environment.NotorietyToggleUIKey
	local ToggleInputType = if table.find(Enum.UserInputType:GetEnumItems(), ToggleInput)
		then "UserInputType"
		else "KeyCode"

	local Data = {
		InfiniteYellMark = Environment.NotorietyInfiniteYellMarkEnabled,
		AutoYell = Environment.NotorietyAutoYellEnabled,
		NoYellDelay = Environment.NotorietyNoYellDelayEnabled,
		ItemESP = Environment.NotorietyItemESPEnabled,
		WeaponMods = Environment.NotorietyWeaponEnabled,
		FireDelay = Environment.NotorietyFireDelay,
		BoltDuration = Environment.NotorietyBoltDuration,
		GunAccuracy = Environment.NotorietyAccuracy,
		MeleeReachEnabled = Environment.NotorietyMeleeReachEnabled,
		MeleeReach = Environment.NotorietyMeleeReach,
		SawReachEnabled = Environment.NotorietySawReachEnabled,
		SawReach = Environment.NotorietySawReach,
		PoliceHeadScaleEnabled = Environment.NotorietyPoliceHeadScaleEnabled,
		PoliceHeadScale = Environment.NotorietyPoliceHeadScale,
		EquipmentSpeedEnabled = Environment.NotorietyEquipmentSpeedEnabled,
		EquipmentSpeedMultiplier = Environment.NotorietyEquipmentSpeedMultiplier,
		EquipmentPositionEnabled = Environment.NotorietyEquipmentPositionEnabled,
		EquipmentPositionX = Environment.NotorietyEquipmentPositionX,
		EquipmentPositionY = Environment.NotorietyEquipmentPositionY,
		EquipmentPositionZ = Environment.NotorietyEquipmentPositionZ,
		ToggleUIKey = if typeof(ToggleInput) == "EnumItem" then ToggleInput.Name else "RightShift",
		ToggleUIInputType = ToggleInputType,
	}

	pcall(function()
		if type(makefolder) == "function"
			and (type(isfolder) ~= "function" or not isfolder(NOTORIETY_CONFIG_FOLDER))
		then
			makefolder(NOTORIETY_CONFIG_FOLDER)
		end

		writefile(NOTORIETY_CONFIG_PATH, HttpService:JSONEncode(Data))
	end)
end

local function applyLoadedNotorietyConfig()
	setMeleeReachEnabled(Environment.NotorietyMeleeReachEnabled)
	setSawReachEnabled(Environment.NotorietySawReachEnabled)
	setWeaponModificationsEnabled(Environment.NotorietyWeaponEnabled)
	setPoliceHeadScaleEnabled(Environment.NotorietyPoliceHeadScaleEnabled)
	setItemESPEnabled(Environment.NotorietyItemESPEnabled)
	setYellMarkPatchEnabled(Environment.NotorietyInfiniteYellMarkEnabled)
	YellPatchState.SetAutoYellEnabled(Environment.NotorietyAutoYellEnabled)
	YellPatchState.SetNoDelayEnabled(Environment.NotorietyNoYellDelayEnabled)
	applyEquipmentPlacementSpeed()
	applyEquipmentPositioning()

	if Environment.NotorietyMeleeReachEnabled then
		installMeleeReachHook()
	end
end

local function setModalValue(Component, Value)
	if type(Component) ~= "table" then
		return
	end

	if type(Component.Set) == "function" then
		local Success = pcall(Component.Set, Component, Value)

		if Success then
			return
		end
	end

	if typeof(Component.Object) ~= "Instance" then
		return
	end

	local TextBox = Component.Object:FindFirstChild("Toggle", true)

	if TextBox and TextBox:IsA("TextBox") then
		TextBox.Text = tostring(Value)
	end
end

local function createModalUI()
	local Modal = NotorietyUI.Library

	if not isSupportedToggleInput(Environment.NotorietyToggleUIKey) then
		Environment.NotorietyToggleUIKey = Enum.KeyCode.RightShift
	end

	local Window = Modal:CreateWindow({
		Title = "Notoriety",
		SubTitle = "Gameplay tools",
		Icon = "rbxassetid://68073547",
		Size = UDim2.fromOffset(560, 430),
		MinimumSize = Vector2.new(420, 320),
		Transparency = 0,
	})
	local WindowRoot = Modal.ScreenGui

	if typeof(WindowRoot) ~= "Instance" then
		error("VibeUI did not create a ScreenGui root")
	end

	Environment.NotorietyModalRoot = WindowRoot
	NotorietyUI.Root = WindowRoot
	Window:SetToggleKey(Environment.NotorietyToggleUIKey)

	Window:SetTheme("Midnight")
	Environment.NotorietyWindow = Window
	NotorietyUI.Window = Window
	NotorietyUI.SaveConfig = saveNotorietyConfig

	local PoliceTab = Window:AddTab("Main")

	PoliceTab:New("Button")({
		Title = "Kill Police [P]",
		Description = "Kills every currently spawned police NPC",
		Callback = function()
			task.spawn(runKill)
		end,
	})

	PoliceTab:New("Toggle")({
		Title = "Infinite Yell / Mark",
		Description = "Targets the full viewport through walls with no distance limit",
		DefaultValue = Environment.NotorietyInfiniteYellMarkEnabled,
		Callback = function(Enabled)
			setYellMarkPatchEnabled(Enabled)
			saveNotorietyConfig()
		end,
	})

	PoliceTab:New("Toggle")({
		Title = "Auto Yell",
		Description = "Automatically yells new viewport targets without spamming unchanged targets",
		DefaultValue = Environment.NotorietyAutoYellEnabled,
		Callback = function(Enabled)
			YellPatchState.SetAutoYellEnabled(Enabled)
			saveNotorietyConfig()
		end,
	})

	PoliceTab:New("Toggle")({
		Title = "No Yell / Mark Delay",
		Description = "Removes the native 0.5 second client yell debounce without per-frame scanning",
		DefaultValue = Environment.NotorietyNoYellDelayEnabled,
		Callback = function(Enabled)
			YellPatchState.SetNoDelayEnabled(Enabled)
			saveNotorietyConfig()
		end,
	})

	PoliceTab:New("Toggle")({
		Title = "Police Head Scale",
		Description = "Enlarges Head parts inside the Police folder",
		DefaultValue = Environment.NotorietyPoliceHeadScaleEnabled,
		Callback = function(Enabled)
			setPoliceHeadScaleEnabled(Enabled)
			saveNotorietyConfig()
		end,
	})

	NotorietyUI.PoliceHeadScaleSlider = PoliceTab:New("Slider")({
		Title = "Police Head Scale Amount",
		Description = "Multiplier for each police Head",
		Min = 1,
		Max = 20,
		Step = 1,
		Suffix = "x",
		DefaultValue = Environment.NotorietyPoliceHeadScale,
		Callback = function(Value)
			local Number = tonumber(Value)

			if not isFiniteNumber(Number) then
				return
			end

			Number = math.clamp(Number, 1, 20)
			Environment.NotorietyPoliceHeadScale = Number

			if Environment.NotorietyPoliceHeadScaleEnabled then
				applyPoliceHeadScale()
			end

			saveNotorietyConfig()
		end,
	})

	local WeaponTab = Window:AddTab("Weapons")

	WeaponTab:New("Toggle")({
		Title = "Weapon Mods",
		Description = "Enables the weapon stat and runtime modifications",
		DefaultValue = Environment.NotorietyWeaponEnabled,
		Callback = function(Enabled)
			setWeaponModificationsEnabled(Enabled)
			saveNotorietyConfig()
		end,
	})

	WeaponTab:New("Toggle")({
		Title = "Melee Reach",
		Description = "Extends the shared hitbox for every melee weapon",
		DefaultValue = Environment.NotorietyMeleeReachEnabled,
		Callback = function(Enabled)
			setMeleeReachEnabled(Enabled)

			if Environment.NotorietyMeleeReachEnabled then
				installMeleeReachHook()
			end

			saveNotorietyConfig()
		end,
	})

	NotorietyUI.MeleeReachSlider = WeaponTab:New("Slider")({
		Title = "Melee Reach Distance",
		Description = "Forward reach in studs",
		Min = 5,
		Max = 100,
		Step = 1,
		Suffix = " studs",
		DefaultValue = Environment.NotorietyMeleeReach,
		Callback = function(Value)
			local Number = tonumber(Value)

			if not isFiniteNumber(Number) then
				return
			end

			Number = math.clamp(Number, 5, 100)
			Environment.NotorietyMeleeReach = Number
			saveNotorietyConfig()
		end,
	})

	WeaponTab:New("Toggle")({
		Title = "SAW Reach",
		Description = "Extends BulletRange for the SAW gadget",
		DefaultValue = Environment.NotorietySawReachEnabled,
		Callback = function(Enabled)
			setSawReachEnabled(Enabled)
			saveNotorietyConfig()
		end,
	})

	NotorietyUI.SawReachSlider = WeaponTab:New("Slider")({
		Title = "SAW Reach Distance",
		Description = "SAW interaction reach in studs",
		Min = 10,
		Max = 250,
		Step = 1,
		Suffix = " studs",
		DefaultValue = Environment.NotorietySawReach,
		Callback = function(Value)
			local Number = tonumber(Value)

			if not isFiniteNumber(Number) then
				return
			end

			Number = math.clamp(Number, 10, 250)
			Environment.NotorietySawReach = Number

			if Environment.NotorietySawReachEnabled then
				refreshTrackedWeaponModifications()
			end

			saveNotorietyConfig()
		end,
	})

	NotorietyUI.FireDelaySlider = WeaponTab:New("Slider")({
		Title = "Fire Delay",
		Description = "Shot cooldown in seconds. Default: 0.01",
		Min = 0,
		Max = 1,
		Step = 0.001,
		Suffix = "s",
		DefaultValue = math.clamp(Environment.NotorietyFireDelay, 0, 1),
		Callback = function(Value)
			local Number = tonumber(Value)

			if not isFiniteNumber(Number) then
				return
			end

			Environment.NotorietyFireDelay = math.clamp(Number, 0, 1)

			refreshTrackedWeaponModifications()

			saveNotorietyConfig()
		end,
	})

	NotorietyUI.BoltDurationSlider = WeaponTab:New("Slider")({
		Title = "Bolt Duration",
		Description = "Bolt animation/tween duration in seconds. Default: 0.001",
		Min = 0,
		Max = 1,
		Step = 0.001,
		Suffix = "s",
		DefaultValue = math.clamp(Environment.NotorietyBoltDuration, 0, 1),
		Callback = function(Value)
			local Number = tonumber(Value)

			if not isFiniteNumber(Number) then
				return
			end

			Environment.NotorietyBoltDuration = math.clamp(Number, 0, 1)

			refreshTrackedWeaponModifications()

			saveNotorietyConfig()
		end,
	})

	NotorietyUI.AccuracySlider = WeaponTab:New("Slider")({
		Title = "Gun Accuracy",
		Description = "Updates live weapon spread immediately",
		Min = 0,
		Max = 100,
		Step = 1,
		Suffix = "%",
		DefaultValue = Environment.NotorietyAccuracy,
		Callback = function(Value)
			local Number = tonumber(Value)

			if not isFiniteNumber(Number) then
				return
			end

			Number = math.clamp(Number, 0, 100)
			Environment.NotorietyAccuracy = Number

			refreshTrackedWeaponModifications()

			saveNotorietyConfig()
		end,
	})

	WeaponTab:New("Button")({
		Title = "Reset Weapon Defaults",
		Description = "Fire Delay = 0.01, Bolt Duration = 0.001, Accuracy = 100",
		Callback = function()
			Environment.NotorietyFireDelay = 0.01
			Environment.NotorietyBoltDuration = 0.001
			Environment.NotorietyAccuracy = 100
			setModalValue(NotorietyUI.FireDelaySlider, 0.01)
			setModalValue(NotorietyUI.BoltDurationSlider, 0.001)
			setModalValue(NotorietyUI.AccuracySlider, 100)

			refreshTrackedWeaponModifications()

			saveNotorietyConfig()
		end,
	})

	local VisualsTab = Window:AddTab("Visuals")

	VisualsTab:New("Toggle")({
		Title = "Item ESP",
		Description = "Highlights supported loot and interaction objects",
		DefaultValue = Environment.NotorietyItemESPEnabled,
		Callback = function(Enabled)
			setItemESPEnabled(Enabled)
			saveNotorietyConfig()
		end,
	})

	local EquipmentTab = Window:AddTab("Equipment")

	EquipmentTab:New("Toggle")({
		Title = "Equipment Placement Speed",
		Description = "Speeds up the real 0% to 100% equipment placement timer",
		DefaultValue = Environment.NotorietyEquipmentSpeedEnabled,
		Callback = function(Enabled)
			Environment.NotorietyEquipmentSpeedEnabled = Enabled == true

			if Environment.NotorietyEquipmentSpeedEnabled then
				EquipmentSpeedState.DiscoveryAttempted = false
			end

			applyEquipmentPlacementSpeed()
			saveNotorietyConfig()
		end,
	})

	NotorietyUI.EquipmentSpeedSlider = EquipmentTab:New("Slider")({
		Title = "Placement Speed",
		Description = "Default: 2x. Use 1 for normal speed",
		Min = 1,
		Max = 10,
		Step = 0.1,
		Suffix = "x",
		DefaultValue = math.clamp(Environment.NotorietyEquipmentSpeedMultiplier, 1, 10),
		Callback = function(Value)
			local Number = tonumber(Value)

			if not isFiniteNumber(Number) then
				return
			end

			Environment.NotorietyEquipmentSpeedMultiplier = math.clamp(Number, 1, 10)

			if Environment.NotorietyEquipmentSpeedEnabled then
				applyEquipmentPlacementSpeed()
			end

			saveNotorietyConfig()
		end,
	})

	EquipmentTab:New("Button")({
		Title = "Reset Placement Speed",
		Description = "Resets the multiplier to 2x",
		Callback = function()
			Environment.NotorietyEquipmentSpeedMultiplier = 2
			setModalValue(NotorietyUI.EquipmentSpeedSlider, 2)

			if Environment.NotorietyEquipmentSpeedEnabled then
				applyEquipmentPlacementSpeed()
			end

			saveNotorietyConfig()
		end,
	})

	EquipmentTab:New("Toggle")({
		Title = "Custom Equipment Position",
		Description = "Offsets the equipment from its normal placement position",
		DefaultValue = Environment.NotorietyEquipmentPositionEnabled,
		Callback = function(Enabled)
			Environment.NotorietyEquipmentPositionEnabled = Enabled == true
			applyEquipmentPositioning()
			saveNotorietyConfig()
		end,
	})

	NotorietyUI.EquipmentPositionXSlider = EquipmentTab:New("Slider")({
		Title = "Left / Right Offset",
		Description = "Positive = right, negative = left",
		Min = -50,
		Max = 50,
		Step = 0.5,
		Suffix = " studs",
		DefaultValue = math.clamp(Environment.NotorietyEquipmentPositionX, -50, 50),
		Callback = function(Value)
			local Number = tonumber(Value)

			if not isFiniteNumber(Number) then
				return
			end

			Environment.NotorietyEquipmentPositionX = math.clamp(Number, -50, 50)
			applyEquipmentPositioning()
			saveNotorietyConfig()
		end,
	})

	NotorietyUI.EquipmentPositionYSlider = EquipmentTab:New("Slider")({
		Title = "Up / Down Offset",
		Description = "Positive = up, negative = down",
		Min = -50,
		Max = 50,
		Step = 0.5,
		Suffix = " studs",
		DefaultValue = math.clamp(Environment.NotorietyEquipmentPositionY, -50, 50),
		Callback = function(Value)
			local Number = tonumber(Value)

			if not isFiniteNumber(Number) then
				return
			end

			Environment.NotorietyEquipmentPositionY = math.clamp(Number, -50, 50)
			applyEquipmentPositioning()
			saveNotorietyConfig()
		end,
	})

	NotorietyUI.EquipmentPositionZSlider = EquipmentTab:New("Slider")({
		Title = "Forward / Back Offset",
		Description = "Positive = forward, negative = back",
		Min = -50,
		Max = 50,
		Step = 0.5,
		Suffix = " studs",
		DefaultValue = math.clamp(Environment.NotorietyEquipmentPositionZ, -50, 50),
		Callback = function(Value)
			local Number = tonumber(Value)

			if not isFiniteNumber(Number) then
				return
			end

			Environment.NotorietyEquipmentPositionZ = math.clamp(Number, -50, 50)
			applyEquipmentPositioning()
			saveNotorietyConfig()
		end,
	})

	EquipmentTab:New("Button")({
		Title = "Reset Equipment Position",
		Description = "Resets X, Y, and Z offsets to 0",
		Callback = function()
			Environment.NotorietyEquipmentPositionX = 0
			Environment.NotorietyEquipmentPositionY = 0
			Environment.NotorietyEquipmentPositionZ = 0
			setModalValue(NotorietyUI.EquipmentPositionXSlider, 0)
			setModalValue(NotorietyUI.EquipmentPositionYSlider, 0)
			setModalValue(NotorietyUI.EquipmentPositionZSlider, 0)
			applyEquipmentPositioning()
			saveNotorietyConfig()
		end,
	})

	local UtilityTab = Window:AddTab("Utility")

	UtilityTab:New("Keybind")({
		Title = "Toggle UI",
		Description = "Default: RightShift",
		DefaultKeybind = Environment.NotorietyToggleUIKey.Name,
		Callback = function(Value)
			if isSupportedToggleInput(Value) then
				Environment.NotorietyToggleUIKey = Value
				saveNotorietyConfig()
			end
		end,
	})

	UtilityTab:New("Button")({
		Title = "Unload",
		Description = "Restores modified data and unloads Notoriety",
		Callback = function()
			saveNotorietyConfig()

			task.defer(function()
				if type(Environment.UnloadNotoriety) == "function" then
					Environment.UnloadNotoriety()
				end
			end)
		end,
	})

	Window:SetTab("Main")

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

	if ownsNotorietyBootstrap() then
		LoadState.Status = "unloading"
		LoadState.Stage = "runtime cleanup"
	end

	if type(NotorietyUI.SaveConfig) == "function" then
		NotorietyUI.SaveConfig()
	end

	Environment.NotorietyUnloaded = true
	Environment.MaxEverythingEnabled = false
	Environment.NotorietyWeaponEnabled = false
	Environment.NotorietyMeleeReachEnabled = false
	Environment.NotorietySawReachEnabled = false
	Environment.NotorietyPoliceHeadScaleEnabled = false
	Environment.NotorietyItemESPEnabled = false
	Environment.NotorietyInfiniteYellMarkEnabled = false
	Environment.NotorietyAutoYellEnabled = false
	Environment.NotorietyNoYellDelayEnabled = false
	Environment.KillPoliceRunning = false
	MeleeReachState.Enabled = false

	if NamecallState.Owner == LoadState then
		NamecallState.Dispatch = nil
		NamecallState.Owner = nil
	end

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
	clearMaxValueTracking()

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
	PoliceHeadScaleState.Apply = nil
	PoliceHeadScaleState.SetEnabled = nil
	Environment.NotorietyPoliceHeadScaleState = nil
	Environment.NotorietyItemESPController = nil
	Environment.NotorietyYellPatchState = nil

	local CurrentWindow = Environment.NotorietyWindow
	local CurrentModalRoot = Environment.NotorietyModalRoot
	Environment.NotorietyWindow = nil
	Environment.NotorietyModalRoot = nil
	NotorietyUI.Window = nil
	NotorietyUI.Root = nil
	NotorietyUI.SaveConfig = nil

	if CurrentWindow then
		pcall(function()
			CurrentWindow:Destroy()
		end)
	end

	if typeof(CurrentModalRoot) == "Instance" then
		pcall(function()
			CurrentModalRoot:Destroy()
		end)
	end

	Environment.NotorietyGetAmmoWrappers = setmetatable({}, {
		__mode = "k",
	})

	table.clear(WeaponState.RuntimeWeapons)

	if ownsNotorietyBootstrap() then
		LoadState.Status = "unloaded"
		LoadState.FinishedAt = os.clock()
	end
end

LoadState.FinalUnload = unloadNotoriety
Environment.UnloadNotoriety = unloadNotoriety

startupCheckpoint("configuration loading")
loadNotorietyConfig()
trackWeaponContainer(Weapons)
trackWeaponContainer(Backpack)
trackWeaponContainer(LocalPlayer.Character)
applyLoadedNotorietyConfig()
createModalUI()
startupCheckpoint("runtime connection setup")

local HeartbeatConnection

HeartbeatConnection = RunService.Heartbeat:Connect(function(DeltaTime)
	if not isCurrentNotorietyRun() then
		disconnectBootstrapConnection(HeartbeatConnection)
		return
	end

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
		applyPoliceHeadScale()

		if Environment.NotorietyInfiniteYellMarkEnabled then
			applyYellMarkPatch()
		end

		if Environment.NotorietyItemESPEnabled
			and (ItemESPState.Folder == nil or ItemESPState.Folder.Parent == nil)
		then
			startItemESP()
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

Environment.MaxEverythingConnection = HeartbeatConnection

local CharacterConnection

CharacterConnection = LocalPlayer.CharacterAdded:Connect(function(Character)
	if not isCurrentNotorietyRun() then
		disconnectBootstrapConnection(CharacterConnection)
		return
	end

	if Environment.NotorietyUnloaded then
		return
	end

	task.wait(1)

	if not isCurrentNotorietyRun() or Environment.NotorietyUnloaded then
		return
	end

	Apply()
	applyEquipmentPlacementSpeed()
	applyEquipmentPositioning()
	trackWeaponContainer(Character)
	table.clear(YellPatchState.TargetParts)
	table.clear(YellPatchState.SkillCache)
	table.clear(YellPatchState.AutoSeen)
	EquipmentSpeedState.DiscoveryAttempted = false
	YellPatchState.NoDelayDiscoveryAttempted = false

	if Environment.NotorietyNoYellDelayEnabled then
		YellPatchState.RefreshNoDelayTargets()
		YellPatchState.ConnectNoDelaySignals()
	end

	if Environment.NotorietyWeaponEnabled then
		applyAllWeaponModifications()
	end
end)

Environment.MaxEverythingCharacterConnection = CharacterConnection

setMaxValueCharacter(LocalPlayer.Character)
Apply()

startupCheckpoint("startup completion")
LoadState.Status = "ready"
LoadState.Stage = "running"
LoadState.FinishedAt = os.clock()
end

local InitializeSuccess, InitializeError = xpcall(initializeNotoriety, debug.traceback)

if not InitializeSuccess then
	local FailureStage = LoadState.Stage
	LoadState.Error = tostring(InitializeError)
	LoadState.FinishedAt = os.clock()
	local FailureStatus = if LoadState.Cancelled then "cancelled" else "failed"
	LoadState.Status = FailureStatus

	if ownsNotorietyBootstrap() then
		if type(LoadState.FinalUnload) == "function" then
			pcall(LoadState.FinalUnload)
		else
			cleanupPartialNotorietyRuntime()
		end

		if rawget(Environment, "UnloadNotoriety") == emergencyUnloadNotoriety
			or rawget(Environment, "UnloadNotoriety") == LoadState.FinalUnload
		then
			Environment.UnloadNotoriety = nil
		end

		LoadState.Status = FailureStatus
		LoadState.Stage = "rollback complete"
	end

	warn("Notoriety failed during " .. tostring(FailureStage) .. ":\n" .. tostring(InitializeError))
end
