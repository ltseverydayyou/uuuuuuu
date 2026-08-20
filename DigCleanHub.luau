--!nonstrict

local cloneref = cloneref or function(value)
	return value
end

local SR = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/ServiceResolver.luau"))()

local Players = SR.cs("Players", cloneref)
local ReplicatedStorage = SR.cs("ReplicatedStorage", cloneref)
local CollectionService = SR.cs("CollectionService", cloneref)
local HttpService = SR.cs("HttpService", cloneref)
local RunService = SR.cs("RunService", cloneref)
local VirtualUser = SR.cs("VirtualUser", cloneref)
local Workspace = SR.cs("Workspace", cloneref)

local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")
local TS = PlayerScripts:WaitForChild("TS")
local Network = TS:WaitForChild("network")
local RuntimeLib = require(ReplicatedStorage:WaitForChild("rbxts_include"):WaitForChild("RuntimeLib"))
local env = getgenv()

local Risky = {
	Requested = env.DigCleanRisky ~= false,
	HasGetLoadedModules = type(getloadedmodules) == "function",
	HasGetGC = type(getgc) == "function",
	HasDebugUpvalues = type(debug) == "table" and type(debug.getupvalues) == "function",
	HasDebugSetupValue = type(debug) == "table" and type(debug.setupvalue) == "function",
	HasHookFunction = type(hookfunction) == "function",
	HasGetConnections = type(getconnections) == "function",
	LoadedNetworkModules = 0,
	SingletonCount = 0,
	DirectControllers = 0,
	ControllerSource = "Flamework fallback",
	NetworkSources = {},
	ControllerSources = {},
	InstantDigSuccess = 0,
	InstantDigRejected = 0,
	ManualAccelerations = 0,
}

local LoadedModulesByName = {}
if Risky.Requested and Risky.HasGetLoadedModules then
	pcall(function()
		for _, module in getloadedmodules() do
			if typeof(module) == "Instance" and module:IsA("ModuleScript") then
				local bucket = LoadedModulesByName[module.Name]
				if not bucket then
					bucket = {}
					LoadedModulesByName[module.Name] = bucket
				end
				table.insert(bucket, module)
			end
		end
	end)
end

local function findLoadedModule(name)
	local bucket = LoadedModulesByName[name]
	if type(bucket) ~= "table" then
		return nil
	end
	for _, module in bucket do
		if module.Parent and module:IsDescendantOf(PlayerScripts) then
			return module
		end
	end
	for _, module in bucket do
		if module.Parent and module:IsDescendantOf(ReplicatedStorage) then
			return module
		end
	end
	return bucket[1]
end

local function req(name)
	if Risky.Requested then
		local module = findLoadedModule(name)
		if module then
			local ok, result = pcall(require, module)
			if ok and type(result) == "table" then
				Risky.LoadedNetworkModules += 1
				Risky.NetworkSources[name] = "getloadedmodules"
				return result
			end
		end
	end
	Risky.NetworkSources[name] = "path fallback"
	return require(Network:WaitForChild(name))
end

local DataNetwork = req("DataNetwork")
local ItemsNetwork = req("ItemsNetwork")
local SellNetwork = req("SellNetwork")
local ShopNetwork = req("ShopNetwork")
local TravelNetwork = req("TravelNetwork")
local PolisherNetwork = req("PolisherNetwork")
local PlotSectionNetwork = req("PlotSectionNetwork")
local PedestalNetwork = req("PedestalNetwork")
local OfflineEarningsNetwork = req("OfflineEarningsNetwork")
local ForeverPackNetwork = req("ForeverPackNetwork")
local PyramidNetwork = req("PyramidNetwork")
local CodeNetwork = req("CodeNetwork")
local TutorialNetwork = req("TutorialNetwork")
local MiscNetwork = req("MiscNetwork")
local ShovelNetwork = req("ShovelNetwork")
local VisitorNetwork = req("VisitorNetwork")
local LuckNetwork = req("LuckNetwork")

local DataFunctions = DataNetwork.DataFunctions
local ItemsFunctions = ItemsNetwork.ItemsFunctions
local ItemsEvents = ItemsNetwork.ItemsEvents
local SellFunctions = SellNetwork.SellFunctions
local ShopFunctions = ShopNetwork.ShopFunctions
local TravelFunctions = TravelNetwork.TravelFunctions
local PolisherFunctions = PolisherNetwork.PolisherFunctions
local PlotSectionFunctions = PlotSectionNetwork.PlotSectionFunctions
local PedestalFunctions = PedestalNetwork.PedestalFunctions
local OfflineEarningsFunctions = OfflineEarningsNetwork.OfflineEarningsFunctions
local ForeverPackEvents = ForeverPackNetwork.ForeverPackEvents
local PyramidFunctions = PyramidNetwork.PyramidFunctions
local CodeFunctions = CodeNetwork.CodeFunctions
local TutorialFunctions = TutorialNetwork.TutorialFunctions
local TutorialEvents = TutorialNetwork.TutorialEvents
local MiscEvents = MiscNetwork.MiscEvents
local ShovelFunctions = ShovelNetwork.ShovelFunctions
local ShovelEvents = ShovelNetwork.ShovelEvents
local VisitorFunctions = VisitorNetwork.VisitorFunctions
local LuckFunctions = LuckNetwork.LuckFunctions

local ShovelConstants = require(ReplicatedStorage.TS.constants.digging.Shovels)
local SprayConstants = require(ReplicatedStorage.TS.constants.cleaning.SprayBottles)
local DetectorConstants = require(ReplicatedStorage.TS.constants.digging.Detectors)
local IslandConstants = require(ReplicatedStorage.TS.constants.world.Islands)
local PlotConstants = require(ReplicatedStorage.TS.constants.plot.PlotSections)
local PolishingConstants = require(ReplicatedStorage.TS.constants.plot.Polishing)
local UpstairsConstants = require(ReplicatedStorage.TS.constants.plot.UpstairsPedestals)
local TutorialConstants = require(ReplicatedStorage.TS.constants.tutorial.TutorialConfig)
local DiggingConfig = require(ReplicatedStorage.TS.constants.digging.DiggingConfig)
local CollectionConstants = require(ReplicatedStorage.TS.constants.items.CollectionMilestones)
local ItemConstants = require(ReplicatedStorage.TS.constants.items.Items)
local itemValueFor = ItemConstants.itemValueFor
local BackpackCapacity = require(ReplicatedStorage.TS.constants.inventory.BackpackCapacity).BackpackCapacity

local ControllerSource = TS:WaitForChild("controllers"):WaitForChild("world"):WaitForChild("DetectorSweepController")
local Flamework
if Risky.Requested then
	local module = findLoadedModule("flamework")
	if module then
		local ok, result = pcall(require, module)
		if ok and type(result) == "table" then
			Flamework = result.Flamework
		end
	end
end
if type(Flamework) ~= "table" then
	Flamework = RuntimeLib.import(ControllerSource, ReplicatedStorage, "rbxts_include", "node_modules", "@flamework", "core", "out").Flamework
end

local SingletonRegistry
local Singletons
local SingletonsByName = {}

local function acceptSingletonRegistry(candidate, source)
	if type(candidate) ~= "table" or type(candidate.getSingletons) ~= "function" or type(candidate.resolveDependency) ~= "function" then
		return false
	end
	local ok, singletons = pcall(candidate.getSingletons)
	if not ok or type(singletons) ~= "table" then
		return false
	end
	local count = 0
	local byName = {}
	for classKey, singleton in singletons do
		count += 1
		if type(singleton) == "table" then
			byName[tostring(classKey)] = singleton
		end
	end
	if count == 0 then
		return false
	end
	SingletonRegistry = candidate
	Singletons = singletons
	SingletonsByName = byName
	Risky.SingletonCount = count
	Risky.ControllerSource = source
	return true
end

if Risky.Requested and type(Flamework) == "table" and type(Flamework.resolveDependency) == "function" then
	if Risky.HasDebugUpvalues then
		pcall(function()
			local upvalues = debug.getupvalues(Flamework.resolveDependency)
			for _, value in upvalues do
				if acceptSingletonRegistry(value, "debug upvalue singleton registry") then
					break
				end
			end
		end)
	end
	if not Singletons and Risky.HasGetGC then
		pcall(function()
			for _, value in getgc(true) do
				if type(value) == "table" and acceptSingletonRegistry(value, "getgc singleton registry") then
					break
				end
			end
		end)
	end
end

local function resolveController(name, identifier)
	local direct = SingletonsByName[name]
	if type(direct) == "table" then
		Risky.DirectControllers += 1
		Risky.ControllerSources[name] = "singleton registry"
		return direct
	end
	local ok, controller = pcall(function()
		return Flamework.resolveDependency(identifier)
	end)
	if ok then
		Risky.ControllerSources[name] = "Flamework fallback"
		return controller
	end
	Risky.ControllerSources[name] = "unresolved"
	return nil
end

local DetectorSweepController = resolveController("DetectorSweepController", "client/controllers/world/DetectorSweepController@DetectorSweepController")
local DigController = resolveController("DigController", "client/controllers/world/DigController@DigController")
local DataController = resolveController("DataController", "client/controllers/data/DataController@DataController")
local VisitorController = resolveController("VisitorController", "client/controllers/npc/VisitorController@VisitorController")
local LuckController = resolveController("LuckController", "client/controllers/ui/LuckController@LuckController")
local ForeverPackController = resolveController("ForeverPackController", "client/controllers/ui/ForeverPackController@ForeverPackController")
local OfflineEarningsController = resolveController("OfflineEarningsController", "client/controllers/ui/OfflineEarningsController@OfflineEarningsController")
local SellerNpcController = resolveController("SellerNpcController", "client/controllers/npc/SellerNpcController@SellerNpcController")
local BenefitsController = resolveController("BenefitsController", "client/controllers/ui/BenefitsController@BenefitsController")
local CleanBarController = resolveController("CleanBarController", "client/controllers/world/CleanBarController@CleanBarController")

local RarityRank = {
	common = 1,
	uncommon = 2,
	rare = 3,
	epic = 4,
	legendary = 5,
	mythic = 6,
	divine = 7,
	eternal = 8,
	transcendent = 9,
	omega = 10,
	anomaly = 11,
}

local PreviousSettings = env.__DigCleanVibeHub and env.__DigCleanVibeHub.Settings or nil

if env.__DigCleanVibeHub then
	env.__DigCleanVibeHub.Alive = false
	if type(env.__DigCleanVibeHub.RestoreRuntimePatches) == "function" then
		pcall(env.__DigCleanVibeHub.RestoreRuntimePatches)
	end
	if env.__DigCleanVibeHub.UI then
		pcall(function()
			env.__DigCleanVibeHub.UI:Unload()
		end)
	end
end

local SETTINGS_FILE = "DigCleanHub_Settings.json"
local DefaultSettings = {
	AutoTutorial = false,
	AutoDig = false,
	AutoClean = false,
	AutoSell = false,
	AutoMove = true,
	PrioritizeSurfaced = true,
	InstantDig = Risky.Requested,
	ManualDigAccelerator = Risky.Requested,
	TurboMinigame = Risky.Requested and Risky.HasDebugSetupValue,
	SkipDigAnimations = Risky.Requested,
	PerfectPower = Risky.Requested,
	NoDigCooldown = Risky.Requested,
	RestorePosition = Risky.Requested,
	UseFreeCleanSkips = false,
	BypassClientBackpackFull = false,
	InstantDigInputDelay = 0.08,
	InstantDigSettle = 0.10,
	AutoShovel = false,
	AutoSpray = false,
	AutoDetector = false,
	AutoIslands = false,
	AutoPlotSections = false,
	AutoPolisherUnlock = false,
	AutoPolisherUpgrade = false,
	AutoPolish = false,
	AutoPedestalBuy = false,
	AutoFillMuseum = false,
	AutoOffline = false,
	AutoFreePack = false,
	AutoPyramid = false,
	AntiAFK = false,
	QueueOnTeleport = true,
	TravelIsland = "starterIsland",
	DigInterval = Risky.Requested and 0.20 or 0.6,
	SellInterval = 3,
	UpgradeInterval = 2,
	PlotInterval = 3,
	ClaimInterval = 15,
}

local function loadSavedSettings()
	local settings = table.clone(DefaultSettings)
	if type(isfile) ~= "function" or type(readfile) ~= "function" or not isfile(SETTINGS_FILE) then
		if type(PreviousSettings) == "table" then
			for key, default in pairs(DefaultSettings) do
				local value = PreviousSettings[key]
				if type(value) == type(default) then
					settings[key] = value
				end
			end
		end
		return settings
	end
	pcall(function()
		local decoded = HttpService:JSONDecode(readfile(SETTINGS_FILE))
		if type(decoded) ~= "table" then
			return
		end
		for key, default in pairs(DefaultSettings) do
			local value = decoded[key]
			if type(value) == type(default) then
				settings[key] = value
			end
		end
	end)
	return settings
end

local LoadedSettings = loadSavedSettings()
if not Risky.Requested then
	LoadedSettings.InstantDig = false
	LoadedSettings.ManualDigAccelerator = false
	LoadedSettings.TurboMinigame = false
	LoadedSettings.SkipDigAnimations = false
	LoadedSettings.PerfectPower = false
	LoadedSettings.NoDigCooldown = false
	LoadedSettings.RestorePosition = false
	LoadedSettings.BypassClientBackpackFull = false
elseif not Risky.HasDebugSetupValue then
	LoadedSettings.TurboMinigame = false
end

local Hub = {
	Alive = true,
	Resolver = Risky,
	Controllers = {
		Dig = DigController,
		DetectorSweep = DetectorSweepController,
		Data = DataController,
		Visitor = VisitorController,
		Luck = LuckController,
		ForeverPack = ForeverPackController,
		OfflineEarnings = OfflineEarningsController,
		Seller = SellerNpcController,
		Benefits = BenefitsController,
		CleanBar = CleanBarController,
	},
	BusyDig = false,
	BusyClean = false,
	BusySell = false,
	BusyUpgrade = false,
	BusyPlot = false,
	ActionLock = nil,
	Settings = LoadedSettings,

}
env.__DigCleanVibeHub = Hub

local SettingsSaveQueued = false
local function saveSettings()
	if type(writefile) ~= "function" then
		return false
	end
	local out = {}
	for key, default in pairs(DefaultSettings) do
		local value = Hub.Settings[key]
		if type(value) == type(default) then
			out[key] = value
		end
	end
	local ok = pcall(function()
		writefile(SETTINGS_FILE, HttpService:JSONEncode(out))
	end)
	return ok
end

local function queueSettingsSave()
	if SettingsSaveQueued then
		return
	end
	SettingsSaveQueued = true
	task.delay(0.15, function()
		SettingsSaveQueued = false
		if Hub.Alive then
			saveSettings()
		end
	end)
end

local function setSetting(key, value)
	Hub.Settings[key] = value
	queueSettingsSave()
	return value
end

Hub.SaveSettings = saveSettings
Hub.SetSetting = setSetting
Hub.SettingsFile = SETTINGS_FILE
Hub.SettingsPersistence = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"

local QueueTeleport = queue_on_teleport or queueonteleport
if type(QueueTeleport) ~= "function" and type(syn) == "table" then
	QueueTeleport = syn.queue_on_teleport
end
if type(QueueTeleport) ~= "function" and type(fluxus) == "table" then
	QueueTeleport = fluxus.queue_on_teleport
end

local TELEPORT_LOADER_URL = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/DigCleanHub.luau"
local TeleportQueueRegistered = env.__DigCleanHubTeleportQueueRegistered == true
local TeleportBootstrap = ([=[
local env = getgenv()
env.__DigCleanHubTeleportQueueRegistered = nil

local enabled = true
if type(isfile) == "function" and type(readfile) == "function" and isfile(%q) then
	pcall(function()
		local HttpService = game:GetService("HttpService")
		local settings = HttpService:JSONDecode(readfile(%q))
		if type(settings) == "table" and settings.QueueOnTeleport == false then
			enabled = false
		end
	end)
end

if enabled then
	local source = game:HttpGet(%q .. "?v=" .. tostring(os.clock()))
	local chunk = loadstring(source)
	if chunk then
		pcall(chunk)
	end
end
]=]):format(SETTINGS_FILE, SETTINGS_FILE, TELEPORT_LOADER_URL)

local function registerTeleportQueue()
	if TeleportQueueRegistered then
		return true
	end
	if type(QueueTeleport) ~= "function" then
		return false
	end
	local ok = pcall(QueueTeleport, TeleportBootstrap)
	if ok then
		TeleportQueueRegistered = true
		env.__DigCleanHubTeleportQueueRegistered = true
	end
	return ok
end

Hub.QueueOnTeleportSupported = type(QueueTeleport) == "function"
Hub.RegisterTeleportQueue = registerTeleportQueue
if Hub.Settings.QueueOnTeleport then
	registerTeleportQueue()
end

Hub.CleanCooldownUntil = 0
Hub.CleanCooldownDelay = 1.05
Hub.LootStats = { cleaned = 0, museum = 0, sold = 0, cleanRejected = 0 }
Hub.LootState = "idle"
Hub.LootReadyAt = {}
task.defer(saveSettings)

local RuntimePatches = {
	BackpackOriginal = type(BackpackCapacity) == "table" and BackpackCapacity.isFull or nil,
	BackpackReplacement = nil,
	TurboFunction = type(DigController) == "table" and DigController.updateMinigame or nil,
	TurboBurst = nil,
	TurboCPS = nil,
	TurboApplied = false,
}

if Risky.HasDebugUpvalues and type(RuntimePatches.TurboFunction) == "function" then
	pcall(function()
		local upvalues = debug.getupvalues(RuntimePatches.TurboFunction)
		RuntimePatches.TurboBurst = upvalues[2]
		RuntimePatches.TurboCPS = upvalues[3]
	end)
end

local function applyTurboMinigame(enabled)
	if not (Risky.Requested and Risky.HasDebugSetupValue and type(RuntimePatches.TurboFunction) == "function") then
		return false
	end
	if type(RuntimePatches.TurboBurst) ~= "number" or type(RuntimePatches.TurboCPS) ~= "number" then
		return false
	end
	local ok = pcall(function()
		if enabled then
			debug.setupvalue(RuntimePatches.TurboFunction, 2, 50)
			debug.setupvalue(RuntimePatches.TurboFunction, 3, 50)
		else
			debug.setupvalue(RuntimePatches.TurboFunction, 2, RuntimePatches.TurboBurst)
			debug.setupvalue(RuntimePatches.TurboFunction, 3, RuntimePatches.TurboCPS)
		end
	end)
	RuntimePatches.TurboApplied = ok and enabled or false
	return ok
end

local function setBackpackBypass(enabled)
	if type(BackpackCapacity) ~= "table" or type(RuntimePatches.BackpackOriginal) ~= "function" then
		return false
	end
	if enabled and Risky.Requested then
		if type(RuntimePatches.BackpackReplacement) ~= "function" then
			RuntimePatches.BackpackReplacement = function()
				return false
			end
		end
		BackpackCapacity.isFull = RuntimePatches.BackpackReplacement
	else
		if BackpackCapacity.isFull == RuntimePatches.BackpackReplacement or not enabled then
			BackpackCapacity.isFull = RuntimePatches.BackpackOriginal
		end
	end
	return true
end

Hub.RestoreRuntimePatches = function()
	pcall(function()
		applyTurboMinigame(false)
	end)
	pcall(function()
		setBackpackBypass(false)
	end)
end

if Hub.Settings.TurboMinigame then
	applyTurboMinigame(true)
end

local function acquireAction(name, timeout)
	local deadline = os.clock() + (timeout or 0)
	repeat
		if not Hub.Alive then
			return false
		end
		if Hub.ActionLock == nil or Hub.ActionLock == name then
			Hub.ActionLock = name
			return true
		end
		if os.clock() >= deadline then
			return false
		end
		task.wait(0.03)
	until false
end

local function releaseAction(name)
	if Hub.ActionLock == name then
		Hub.ActionLock = nil
	end
end

local function awaitPromise(promise, fallback)
	local ok, value = pcall(function()
		return RuntimeLib.await(promise:catch(function()
			return fallback
		end))
	end)
	if ok then
		return value
	end
	return fallback
end

local function getData()
	if type(DataController) == "table" then
		for _, methodName in { "getDataIfLoaded", "getData" } do
			local method = DataController[methodName]
			if type(method) == "function" then
				local ok, data = pcall(method, DataController)
				if ok and type(data) == "table" then
					return data
				end
			end
		end
	end
	return awaitPromise(DataFunctions.requestDataUpdate:invoke(), nil)
end

local function contains(list, value)
	if type(list) ~= "table" then
		return false
	end
	return table.find(list, value) ~= nil
end

local function character()
	return LocalPlayer.Character
end

local function rootPart()
	local char = character()
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function capturePivot()
	local char = character()
	if not char then
		return nil, nil
	end
	return char, char:GetPivot()
end

local function restorePivot(char, pivot)
	if not Hub.Settings.RestorePosition or not char or not pivot then
		return
	end
	if char == LocalPlayer.Character and char.Parent then
		pcall(function()
			char:PivotTo(pivot)
		end)
	end
end

local function notify(title, kind)
	if not Hub.UI then
		return
	end
	pcall(function()
		Hub.UI:Notification({
			Title = tostring(title),
			Type = kind or "info",
			Duration = 3,
			Sound = "",
		})
	end)
end

local function currentTutorialState()
	return awaitPromise(TutorialFunctions.GetTutorialState:invoke(), nil)
end

local function moveToPosition(position)
	local char = character()
	local root = rootPart()
	if not char or not root or typeof(position) ~= "Vector3" then
		return false
	end
	char:PivotTo(CFrame.new(position + Vector3.new(0, 3, 0), position + Vector3.new(0, 3, -1)))
	task.wait(0.35)
	return true
end

local function nearestDigZone(islandId)
	local root = rootPart()
	if not root then
		return nil, math.huge
	end

	local best
	local bestDistance = math.huge
	for _, zone in CollectionService:GetTagged(ShovelConstants.DIG_ZONE_TAG) do
		if zone:IsA("BasePart") then
			local taggedIsland = zone:GetAttribute(IslandConstants.ISLAND_ID_ATTRIBUTE)
			if taggedIsland == nil or islandId == nil or taggedIsland == islandId then
				local localPoint = zone.CFrame:PointToObjectSpace(root.Position)
				local halfX = zone.Size.X * 0.5
				local halfZ = zone.Size.Z * 0.5
				local insetX = math.min(2, math.max(0, halfX - 0.05))
				local insetZ = math.min(2, math.max(0, halfZ - 0.05))
				local minX, maxX = -halfX + insetX, halfX - insetX
				local minZ, maxZ = -halfZ + insetZ, halfZ - insetZ
				local x = minX <= maxX and math.clamp(localPoint.X, minX, maxX) or 0
				local z = minZ <= maxZ and math.clamp(localPoint.Z, minZ, maxZ) or 0
				local worldPoint = zone.CFrame:PointToWorldSpace(Vector3.new(x, 0, z))
				local target = Vector3.new(worldPoint.X, root.Position.Y, worldPoint.Z)
				local distance = (target - root.Position).Magnitude
				if distance < bestDistance then
					bestDistance = distance
					best = target
				end
			end
		end
	end
	return best, bestDistance
end

local function positionInIslandDigZone(position, islandId)
	if typeof(position) ~= "Vector3" or islandId == nil then
		return true
	end

	for _, zone in CollectionService:GetTagged(ShovelConstants.DIG_ZONE_TAG) do
		if zone:IsA("BasePart") and zone:GetAttribute(IslandConstants.ISLAND_ID_ATTRIBUTE) == islandId then
			local point = zone.CFrame:PointToObjectSpace(position)
			local margin = 8
			if math.abs(point.X) <= zone.Size.X * 0.5 + margin
				and math.abs(point.Z) <= zone.Size.Z * 0.5 + margin then
				return true
			end
		end
	end

	return false
end

local function selectBuriedNode(islandId)
	local root = rootPart()
	if not root or type(DetectorSweepController) ~= "table" or type(DetectorSweepController.nodes) ~= "table" then
		return nil, nil
	end

	local bestId
	local bestNode
	local bestRank = math.huge
	local bestDistance = math.huge

	for id, node in DetectorSweepController.nodes do
		if type(id) == "string"
			and type(node) == "table"
			and typeof(node.position) == "Vector3"
			and positionInIslandDigZone(node.position, islandId) then
			local rank = RarityRank[node.rarity] or math.huge
			local distance = (node.position - root.Position).Magnitude
			if rank < bestRank or (rank == bestRank and distance < bestDistance) then
				bestRank = rank
				bestDistance = distance
				bestId = id
				bestNode = node
			end
		end
	end

	return bestId, bestNode
end

local function acquireBuriedNodes(islandId)
	if not Hub.Settings.AutoMove or type(DetectorSweepController) ~= "table" or type(DetectorSweepController.nodes) ~= "table" then
		return false
	end

	local nodeId = selectBuriedNode(islandId)
	if nodeId then
		return true
	end

	local target = nearestDigZone(islandId)
	if not target or not moveToPosition(target) then
		return false
	end

	local deadline = os.clock() + 2.25
	repeat
		task.wait(0.05)
		nodeId = selectBuriedNode(islandId)
	until nodeId ~= nil or not Hub.Alive or os.clock() >= deadline

	return nodeId ~= nil
end

local function canDigSurfaced(item, data)
	if type(item) ~= "table" or type(item.itemId) ~= "string" or type(item.kg) ~= "number" then
		return false
	end
	local shovelId = data and data.EquippedShovel
	local shovel = shovelId and ShovelConstants.Shovels[shovelId]
	if not shovel or type(shovel.power) ~= "number" then
		return false
	end
	local ok, difficulty = pcall(DiggingConfig.digDifficultyFor, item.itemId, item.kg, shovel.power, 1)
	return ok and type(difficulty) == "table" and not DiggingConfig.isDigImpossible(difficulty)
end

local function selectSafeSurfaced(data)
	if not Hub.Settings.PrioritizeSurfaced then
		return nil
	end
	local items = awaitPromise(ShovelFunctions.GetSurfacedItems:invoke(), {})
	if type(items) ~= "table" then
		return nil
	end
	local root = rootPart()
	local best
	local bestOneIn = -math.huge
	local bestDistance = math.huge
	local islandId = data and data.CurrentIsland
	for _, item in items do
		if canDigSurfaced(item, data)
			and typeof(item.position) == "Vector3"
			and positionInIslandDigZone(item.position, islandId) then
			local oneIn = tonumber(item.oneIn) or 0
			local distance = root and (item.position - root.Position).Magnitude or math.huge
			if oneIn > bestOneIn or (oneIn == bestOneIn and distance < bestDistance) then
				best = item
				bestOneIn = oneIn
				bestDistance = distance
			end
		end
	end
	return best
end

local function beginControllerDig(before)
	local tutorialState = currentTutorialState()
	local tutorialStep = tutorialState and tutorialState.step or before.TutorialStep

	if tutorialStep == TutorialConstants.TutorialStep.StartDig or tutorialStep == TutorialConstants.TutorialStep.SpamDig then
		if tutorialState and tutorialState.digSpot and Hub.Settings.AutoMove then
			moveToPosition(tutorialState.digSpot)
		end
	else
		local surfacedItem = selectSafeSurfaced(before)
		if surfacedItem then
			if Hub.Settings.AutoMove then
				moveToPosition(surfacedItem.position)
			end
			task.wait(0.12)
		else
			local nodeId, node = selectBuriedNode(before.CurrentIsland)
			if not nodeId or not node then
				return false
			end

			if Hub.Settings.AutoMove then
				moveToPosition(node.position)
			end

			if type(DetectorSweepController.surfaced) == "table" and DetectorSweepController.surfaced[nodeId] == nil then
				pcall(function()
					DetectorSweepController:surface(nodeId, node)
				end)
				task.wait(0.12)
			end
		end
	end

	if DigController.session then
		return true
	end

	local ok = pcall(function()
		DigController:requestSession()
	end)
	if not ok then
		return false
	end

	local deadline = os.clock() + 4
	while Hub.Alive and not DigController.session and os.clock() < deadline do
		task.wait(0.03)
	end
	return DigController.session ~= nil
end

local function runControllerMinigame()
	local session = DigController.session
	if not session then
		return false
	end

	if session.difficulty and DiggingConfig.isDigImpossible(session.difficulty) then
		pcall(function()
			DigController:finish(false)
		end)
		return false
	end

	if session.phase == "power" then
		local powerDeadline = os.clock() + 2.5
		while Hub.Alive and DigController.session == session and session.phase == "power" and os.clock() < powerDeadline do
			if (session.power or 0) >= 0.97 then
				break
			end
			task.wait(0.02)
		end
		if DigController.session == session and session.phase == "power" then
			pcall(function()
				DigController:stopPower(false)
			end)
		end
	end

	local minigameDeadline = os.clock() + 5
	while Hub.Alive and DigController.session == session and session.phase ~= "minigame" and os.clock() < minigameDeadline do
		task.wait(0.03)
	end

	if DigController.session ~= session or session.phase ~= "minigame" then
		return false
	end

	local finishDeadline = os.clock() + 15
	while Hub.Alive and DigController.session == session and session.phase == "minigame" and os.clock() < finishDeadline do
		if (session.clickCredits or 0) >= 1 then
			pcall(function()
				DigController:onDigInput()
			end)
		end
		task.wait(0.02)
	end

	return true
end

local function riskyInstantDig(before)
	if not (Risky.Requested and Hub.Settings.InstantDig) then
		return nil
	end
	if not before or (before.TutorialStep or 0) < TutorialConstants.TutorialStep.Done then
		return nil
	end
	if selectSafeSurfaced(before) then
		return nil
	end

	local nodeId, node = selectBuriedNode(before.CurrentIsland)
	if not nodeId or not node then
		return nil
	end

	local root = rootPart()
	if not root then
		return nil
	end
	if not Hub.Settings.AutoMove and (node.position - root.Position).Magnitude > 12 then
		return nil
	end

	if Hub.Settings.AutoMove then
		local char = character()
		if not char then
			return nil
		end
		char:PivotTo(CFrame.new(node.position + Vector3.new(0, 3, 0), node.position))
	end

	if type(DetectorSweepController.surfaced) == "table" and DetectorSweepController.surfaced[nodeId] == nil then
		pcall(function()
			DetectorSweepController:surface(nodeId, node)
		end)
	end
	task.wait(math.max(0.05, Hub.Settings.InstantDigSettle or 0.10))

	local result = awaitPromise(ShovelFunctions.BeginDig:invoke(nodeId), nil)
	if type(result) ~= "table" or type(result.sessionId) ~= "string" then
		return nil
	end

	if type(result.difficulty) ~= "table" then
		awaitPromise(ShovelFunctions.ResolveDig:invoke(result.sessionId, false, 0), nil)
		return nil
	end

	if DiggingConfig.isDigImpossible(result.difficulty) then
		awaitPromise(ShovelFunctions.ResolveDig:invoke(result.sessionId, false, 0), nil)
		Risky.InstantDigRejected += 1
		return false
	end

	pcall(function()
		ShovelEvents.DigInput:fire(result.sessionId, 999)
	end)
	task.wait(math.max(0.03, Hub.Settings.InstantDigInputDelay or 0.08))

	local resolved = awaitPromise(ShovelFunctions.ResolveDig:invoke(result.sessionId, true, 999), false)
	if resolved == true then
		Risky.InstantDigSuccess += 1
		pcall(function()
			DetectorSweepController:removeSurfaced(nodeId)
		end)
		return true
	end

	Risky.InstantDigRejected += 1
	return false
end

local function digOnce()
	if Hub.BusyDig or not Hub.Alive or not acquireAction("dig", 0) then
		return false
	end
	Hub.BusyDig = true

	local before = getData()
	if not before then
		Hub.BusyDig = false
		releaseAction("dig")
		return false
	end

	if before.TutorialStep < TutorialConstants.TutorialStep.Done
		and before.TutorialStep ~= TutorialConstants.TutorialStep.StartDig
		and before.TutorialStep ~= TutorialConstants.TutorialStep.SpamDig then
		Hub.BusyDig = false
		releaseAction("dig")
		return false
	end

	local beforeDug = before.ItemsDug or 0
	local beforeUids = {}
	for _, item in before.Inventory or {} do
		if type(item.uid) == "string" then
			beforeUids[item.uid] = true
		end
	end
	local restoreChar, restoreCFrame = capturePivot()
	local _, restoreIslandDistance = nearestDigZone(before.CurrentIsland)
	local restoreOriginalPivot = restoreIslandDistance <= 500
	acquireBuriedNodes(before.CurrentIsland)
	local instantResult = riskyInstantDig(before)

	if instantResult == false then
		if restoreOriginalPivot then
			restorePivot(restoreChar, restoreCFrame)
		end
		Hub.BusyDig = false
		releaseAction("dig")
		return false
	elseif instantResult == nil then
		local started = beginControllerDig(before)
		if started then
			runControllerMinigame()
		end
	end

	local resolveDeadline = os.clock() + 3
	local after = getData()
	while Hub.Alive and after and (after.ItemsDug or 0) <= beforeDug and os.clock() < resolveDeadline do
		task.wait(0.15)
		after = getData()
	end

	if restoreOriginalPivot then
		restorePivot(restoreChar, restoreCFrame)
	end
	Hub.BusyDig = false
	releaseAction("dig")
	local success = after and (after.ItemsDug or 0) > beforeDug or false
	local newUid = nil
	if success and after then
		for _, item in after.Inventory or {} do
			if type(item.uid) == "string" and not beforeUids[item.uid] then
				newUid = item.uid
				Hub.LootReadyAt[newUid] = os.clock() + 0.45
				break
			end
		end
	end
	return success, newUid
end

local function inventoryItemByUid(data, uid)
	if type(data) ~= "table" or type(uid) ~= "string" then
		return nil
	end
	for _, item in data.Inventory or {} do
		if item.uid == uid then
			return item
		end
	end
	return nil
end

local function isItemUnclean(item)
	return type(item) == "table" and (item.dirty == true or item.condition == nil)
end

local function hasLooseDirtyItems(data)
	if type(data) ~= "table" then
		return false
	end
	for _, item in data.Inventory or {} do
		if isItemUnclean(item) and item.pedestalSlot == nil and item.polisherSlot == nil then
			return true
		end
	end
	return false
end

local function waitForItemClean(uid, timeout)
	local deadline = os.clock() + (timeout or 0.9)
	repeat
		local data = getData()
		local item = inventoryItemByUid(data, uid)
		if item == nil or not isItemUnclean(item) then
			return true
		end
		task.wait(0.05)
	until not Hub.Alive or os.clock() >= deadline
	return false
end

local function cleanUid(uid)
	if type(uid) ~= "string" then
		return false
	end

	local cooldownRemaining = (Hub.CleanCooldownUntil or 0) - os.clock()
	if cooldownRemaining > 0 then
		task.wait(cooldownRemaining)
	end

	local result = awaitPromise(ItemsFunctions.beginCleaning:invoke(uid), nil)
	if not result then
		Hub.CleanCooldownDelay = math.min(1.60, (Hub.CleanCooldownDelay or 1.05) + 0.10)
		Hub.CleanCooldownUntil = os.clock() + 0.40
		return false
	end

	local data = getData()
	local canSkip = Hub.Settings.UseFreeCleanSkips
		and ((data and (data.FreeSkips or 0) > 0) or (type(CleanBarController) == "table" and CleanBarController.ownsInstantClean == true))

	if canSkip then
		ItemsEvents.requestSkipClean:fire()
		if waitForItemClean(uid, 0.55) then
			Hub.CleanCooldownUntil = os.clock() + (Hub.CleanCooldownDelay or 1.05)
			return true
		end
	end

	ItemsEvents.finishCleaning:fire(uid)
	local cleaned = waitForItemClean(uid, 0.95)
	Hub.CleanCooldownUntil = os.clock() + (cleaned and (Hub.CleanCooldownDelay or 1.05) or 0.55)
	return cleaned
end

local function cleanAll()
	if Hub.BusyClean or not Hub.Alive or not acquireAction("clean", 0) then
		return 0
	end
	Hub.BusyClean = true
	local count = 0

	for _ = 1, 100 do
		if not Hub.Alive then
			break
		end
		local data = getData()
		if not data then
			break
		end

		local target
		for _, item in data.Inventory do
			if isItemUnclean(item) and type(item.uid) == "string" and item.pedestalSlot == nil and item.polisherSlot == nil then
				target = item
				break
			end
		end

		if not target then
			break
		end

		if cleanUid(target.uid) then
			count += 1
		else
			break
		end
	end

	Hub.BusyClean = false
	releaseAction("clean")
	return count
end

local function sellAll()
	if Hub.BusySell or not Hub.Alive or not acquireAction("sell", 6) then
		return false
	end

	local data = getData()
	if not data or (data.TutorialStep or 0) < TutorialConstants.TutorialStep.Done then
		releaseAction("sell")
		return false
	end

	Hub.BusySell = true
	local restoreChar, restoreCFrame = capturePivot()

	if Hub.Settings.AutoClean then
		for _ = 1, 100 do
			local cleanData = getData()
			if not cleanData then
				break
			end
			local dirtyUid
			for _, item in cleanData.Inventory do
				if isItemUnclean(item) and type(item.uid) == "string" and item.pedestalSlot == nil and item.polisherSlot == nil then
					dirtyUid = item.uid
					break
				end
			end
			if not dirtyUid or not cleanUid(dirtyUid) then
				break
			end
		end
	end

	local sellData = getData()
	if hasLooseDirtyItems(sellData) then
		restorePivot(restoreChar, restoreCFrame)
		Hub.BusySell = false
		releaseAction("sell")
		return false
	end

	if Hub.Settings.AutoMove then
		local islands = Workspace:FindFirstChild("Islands")
		local home = islands and islands:FindFirstChild("Home Beach")
		local npcs = home and home:FindFirstChild("NPCs")
		local sell = npcs and npcs:FindFirstChild("Sell")
		local seller = sell and sell:FindFirstChild("SellerNPC")
		local sellerRoot = seller and seller:FindFirstChild("HumanoidRootPart")
		if sellerRoot and sellerRoot:IsA("BasePart") then
			local char = character()
			if char then
				char:PivotTo(CFrame.new(sellerRoot.Position + sellerRoot.CFrame.LookVector * -4))
				task.wait(0.12)
			end
		end
	end

	local result = awaitPromise(SellFunctions.sellInventory:invoke(), nil)
	restorePivot(restoreChar, restoreCFrame)
	Hub.BusySell = false
	releaseAction("sell")
	return result == true or (type(result) == "number" and result > 0)
end

local Gear = {
	shovel = {
		Order = ShovelConstants.SHOVEL_TIER_ORDER,
		Definitions = ShovelConstants.Shovels,
		OwnedKey = "OwnedShovels",
		EquippedKey = "EquippedShovel",
	},
	spray = {
		Order = SprayConstants.SPRAY_TIER_ORDER,
		Definitions = SprayConstants.SprayBottles,
		OwnedKey = "OwnedSprays",
		EquippedKey = "EquippedSpray",
	},
	detector = {
		Order = DetectorConstants.DETECTOR_TIER_ORDER,
		Definitions = DetectorConstants.Detectors,
		OwnedKey = "OwnedDetectors",
		EquippedKey = "EquippedDetector",
	},
}

local SpecialGear = {
	shovel = { "reaperShovel", "horusShovel" },
	spray = { "reaper", "horus" },
	detector = { "reaper", "horus" },
}

local function highestOwned(category, data)
	local info = Gear[category]
	if not info or not data then
		return nil
	end
	local owned = data[info.OwnedKey] or {}
	for _, specialId in SpecialGear[category] or {} do
		if contains(owned, specialId) then
			return specialId
		end
	end
	for i = #info.Order, 1, -1 do
		if contains(owned, info.Order[i]) then
			return info.Order[i]
		end
	end
	return nil
end

local function equipBestOwned(category)
	local data = getData()
	local info = Gear[category]
	if not data or not info then
		return false
	end
	local id = highestOwned(category, data)
	if not id or data[info.EquippedKey] == id then
		return id ~= nil
	end
	return awaitPromise(ShopFunctions.equipGear:invoke(category, id), false) == true
end

local function moveNearGear(category, id)
	local info = Gear[category]
	local def = info and info.Definitions[id]
	local islandsFolder = Workspace:FindFirstChild("Islands")
	local char = character()
	if not def or not islandsFolder or not char then
		return false
	end

	local target
	for _, instance in islandsFolder:GetDescendants() do
		if instance:IsA("Model") and instance.Name == def.displayName then
			local ancestor = instance.Parent
			local isGearModel = false
			while ancestor and ancestor ~= islandsFolder do
				if ancestor.Name == "Gear" then
					isGearModel = true
					break
				end
				ancestor = ancestor.Parent
			end
			if isGearModel then
				target = instance
				break
			end
		end
	end

	if not target then
		return false
	end

	local position = target:GetPivot().Position
	char:PivotTo(CFrame.new(position + Vector3.new(5, 3, 0), position))
	task.wait(0.45)
	return true
end

local function buyBestAffordable(category)
	if Hub.BusyUpgrade or not Hub.Alive or not acquireAction("upgrade", 6) then
		return false
	end
	Hub.BusyUpgrade = true

	local data = getData()
	local info = Gear[category]
	if not data or not info then
		Hub.BusyUpgrade = false
		releaseAction("upgrade")
		return false
	end

	local owned = data[info.OwnedKey] or {}
	local gold = data.Gold or 0
	local bought = false
	local restoreChar, restoreCFrame = capturePivot()

	for i = #info.Order, 1, -1 do
		local id = info.Order[i]
		local def = info.Definitions[id]
		local islandAllowed = def and (def.islandId == "starterIsland" or contains(data.UnlockedIslands, def.islandId))
		if def and islandAllowed and not contains(owned, id) and (def.cost or math.huge) <= gold then
			moveNearGear(category, id)
			local ok = awaitPromise(ShopFunctions.buyGear:invoke(category, id), false)
			if ok == true then
				bought = true
				task.wait(0.2)
				awaitPromise(ShopFunctions.equipGear:invoke(category, id), false)
				break
			end
		end
	end

	if not bought then
		equipBestOwned(category)
	end

	restorePivot(restoreChar, restoreCFrame)
	Hub.BusyUpgrade = false
	releaseAction("upgrade")
	return bought
end

local function buyAllBest()
	for _, category in { "shovel", "spray", "detector" } do
		buyBestAffordable(category)
		task.wait(0.15)
	end
end

local function travelTo(islandId)
	if not IslandConstants.Islands[islandId] then
		return false
	end
	local result = awaitPromise(TravelFunctions.travel:invoke(islandId), nil)
	if result ~= "ok" then
		return false
	end

	local islands = awaitPromise(TravelFunctions.getIslands:invoke(), {})
	for _, island in islands do
		if island.id == islandId and island.spawn then
			local char = character()
			if char then
				char:PivotTo(island.spawn + Vector3.new(0, 4, 0))
			end
			break
		end
	end
	return true
end

local function unlockNextIsland()
	local data = getData()
	if not data then
		return false
	end

	local highestUnlocked = nil
	for _, id in IslandConstants.ISLAND_ORDER do
		if contains(data.UnlockedIslands, id) then
			highestUnlocked = id
		else
			local config = IslandConstants.Islands[id]
			if config and (data.Gold or 0) >= (config.cost or math.huge) then
				return travelTo(id)
			end
			break
		end
	end

	if highestUnlocked then
		local _, distance = nearestDigZone(highestUnlocked)
		if data.CurrentIsland ~= highestUnlocked or distance > 500 then
			return travelTo(highestUnlocked)
		end
	end

	return false
end

local function unlockPlotSections()
	local data = getData()
	if not data then
		return false
	end
	local changed = false
	for _, id in PlotConstants.PLOT_SECTION_ORDER do
		if not contains(data.UnlockedSections, id) then
			local config = PlotConstants.PlotSections[id]
			if config and (data.Gold or 0) >= (config.unlockCost or math.huge) then
				local result = awaitPromise(PlotSectionFunctions.unlockSection:invoke(id), nil)
				if result == "ok" then
					changed = true
					task.wait(0.25)
					data = getData() or data
				end
			end
		end
	end
	return changed
end

local function unlockPolishers()
	local data = getData()
	if not data or not contains(data.UnlockedSections, "Polishing") then
		return false
	end
	local owned = tonumber(data.OwnedPolishers) or 1
	local changed = false
	for slot = owned + 1, PolishingConstants.POLISHER_SLOT_COUNT do
		local result = awaitPromise(PolisherFunctions.unlockPolisher:invoke(slot), nil)
		if result == "ok" then
			changed = true
			task.wait(0.25)
		else
			break
		end
	end
	return changed
end

local function upgradePolishers()
	local data = getData()
	if not data or not contains(data.UnlockedSections, "Polishing") then
		return false
	end

	local owned = math.clamp(tonumber(data.OwnedPolishers) or 1, 1, PolishingConstants.POLISHER_SLOT_COUNT)
	local changed = false
	for slot = 1, owned do
		for _ = 1, PolishingConstants.POLISHER_MAX_LEVEL do
			local result = awaitPromise(PolisherFunctions.upgradePolisher:invoke(slot), nil)
			if result == "ok" then
				changed = true
				task.wait(0.2)
			else
				break
			end
		end
	end
	return changed
end

local function runPolishers()
	local data = getData()
	if not data or not contains(data.UnlockedSections, "Polishing") then
		return false
	end

	local owned = math.clamp(tonumber(data.OwnedPolishers) or 1, 1, PolishingConstants.POLISHER_SLOT_COUNT)
	local changed = false

	for slot = 1, owned do
		if awaitPromise(PolisherFunctions.collectPolish:invoke(slot), false) == true then
			changed = true
			task.wait(0.2)
		end
	end

	for slot = 1, owned do
		data = getData() or data
		for _, item in data.Inventory do
			if item.dirty ~= true and item.condition ~= "mint" and type(item.uid) == "string" then
				local result = awaitPromise(PolisherFunctions.startPolish:invoke(slot, item.uid), nil)
				if result == "ok" then
					changed = true
					task.wait(0.25)
					break
				elseif result == "busy" then
					break
				end
			end
		end
	end

	return changed
end

local function nextUpstairsSlot(data)
	local count = tonumber(data and data.OwnedUpstairsPedestals) or 0
	local ok, slot = pcall(UpstairsConstants.nextUpstairsSlot, count)
	if ok and type(slot) == "number" then
		return slot
	end
	return UpstairsConstants.FIRST_BUYABLE_UPSTAIRS_SLOT + count
end

local function buyNextPedestal()
	local data = getData()
	if not data or not contains(data.UnlockedSections, UpstairsConstants.UPSTAIRS_SECTION_ID) then
		return false
	end
	local slot = nextUpstairsSlot(data)
	if not slot then
		return false
	end
	return awaitPromise(PedestalFunctions.buyPedestal:invoke(slot), nil) == "ok"
end

local function ownPlot()
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then
		return nil
	end
	for _, plot in plots:GetChildren() do
		if plot:IsA("Model") and plot:GetAttribute("OwnerUserId") == LocalPlayer.UserId then
			return plot
		end
	end
	return nil
end

local function museumItemValue(item)
	if type(item) ~= "table"
		or item.dirty == true
		or item.condition == nil
		or type(item.id) ~= "string" then
		return nil
	end
	local ok, value = pcall(itemValueFor, item.id, item.condition, tonumber(item.kg) or 0)
	if ok and type(value) == "number" then
		return value
	end
	return nil
end

local function museumState(data)
	local plot = ownPlot()
	if not plot then
		return {}
	end

	local byUid = {}
	local bySlot = {}
	for _, item in data.Inventory or {} do
		if type(item.uid) == "string" then
			byUid[item.uid] = item
		end
		if type(item.pedestalSlot) == "number" then
			bySlot[item.pedestalSlot] = item
		end
	end

	local seen = {}
	local slots = {}
	for _, instance in plot:GetDescendants() do
		if instance:IsA("Model") then
			local slot = tonumber(string.match(instance.Name, "^Pedestal_(%d+)$"))
			if slot and not seen[slot] and instance:GetAttribute("Owned") == true then
				seen[slot] = true
				local itemUid = instance:GetAttribute("ItemUid")
				local item = nil
				if type(itemUid) == "string" and itemUid ~= "" then
					item = byUid[itemUid]
				end
				item = item or bySlot[slot]
				slots[#slots + 1] = {
					slot = slot,
					model = instance,
					itemUid = itemUid,
					item = item,
					value = museumItemValue(item),
					empty = item == nil and (itemUid == nil or itemUid == ""),
				}
			end
		end
	end
	table.sort(slots, function(a, b)
		return a.slot < b.slot
	end)
	return slots
end

local function museumCandidates(data)
	local candidates = {}
	for _, item in data.Inventory or {} do
		if item.dirty ~= true
			and item.pedestalSlot == nil
			and item.polisherSlot == nil
			and item.favorited ~= true
			and type(item.uid) == "string" then
			local value = museumItemValue(item)
			if value then
				candidates[#candidates + 1] = {
					item = item,
					value = value,
				}
			end
		end
	end
	table.sort(candidates, function(a, b)
		if a.value == b.value then
			return a.item.uid < b.item.uid
		end
		return a.value > b.value
	end)
	return candidates
end

local function placeMuseumItem(slot, uid)
	for _ = 1, 4 do
		local result = awaitPromise(PedestalFunctions.placeItem:invoke(slot, uid), false)
		if result == true or result == "ok" then
			return true
		end
		task.wait(0.3)
	end
	return false
end

local function pickupMuseumItem(slot)
	for _ = 1, 4 do
		local result = awaitPromise(PedestalFunctions.pickupItem:invoke(slot), false)
		if result == true or result == "ok" then
			return true
		end
		task.wait(0.3)
	end
	return false
end

local function fillMuseum()
	if not Hub.Alive or not acquireAction("museum", 8) then
		return false, 0, 0
	end

	local changed = false
	local placements = 0
	local replacements = 0

	for _ = 1, 32 do
		if not Hub.Alive then
			break
		end

		local data = getData()
		if not data then
			break
		end

		local slots = museumState(data)
		local candidates = museumCandidates(data)
		if #slots == 0 or #candidates == 0 then
			break
		end

		local best = candidates[1]
		local emptySlot = nil
		for _, state in slots do
			if state.empty then
				emptySlot = state
				break
			end
		end

		if emptySlot then
			if placeMuseumItem(emptySlot.slot, best.item.uid) then
				changed = true
				placements += 1
				task.wait(0.4)
			else
				break
			end
		else
			local worst = nil
			for _, state in slots do
				if state.item and state.value ~= nil then
					if not worst or state.value < worst.value then
						worst = state
					end
				end
			end

			if not worst or best.value <= worst.value then
				break
			end

			local oldUid = worst.item and worst.item.uid
			if not pickupMuseumItem(worst.slot) then
				break
			end
			task.wait(0.4)

			if placeMuseumItem(worst.slot, best.item.uid) then
				changed = true
				replacements += 1
				task.wait(0.45)
			else
				if type(oldUid) == "string" then
					placeMuseumItem(worst.slot, oldUid)
				end
				break
			end
		end
	end

	Hub.MuseumStats = {
		placements = placements,
		replacements = replacements,
	}
	releaseAction("museum")
	return changed, placements, replacements
end

local function isLooseItem(item)
	return type(item) == "table"
		and item.pedestalSlot == nil
		and item.polisherSlot == nil
		and type(item.uid) == "string"
end

local function looseItemCount(data)
	local count = 0
	if type(data) == "table" then
		for _, item in data.Inventory or {} do
			if isLooseItem(item) and item.favorited ~= true then
				count += 1
			end
		end
	end
	return count
end

local function museumDecisionForUid(data, uid)
	local item = inventoryItemByUid(data, uid)
	if not isLooseItem(item) or isItemUnclean(item) or item.favorited == true then
		return nil
	end
	local value = museumItemValue(item)
	if type(value) ~= "number" then
		return nil
	end
	local slots = museumState(data)
	if #slots == 0 then
		return nil
	end
	for _, state in slots do
		if state.empty then
			return { kind = "fill", slot = state.slot, value = value, item = item }
		end
	end
	local worst = nil
	for _, state in slots do
		if state.item and type(state.value) == "number" then
			if not worst or state.value < worst.value then
				worst = state
			end
		end
	end
	if worst and value > worst.value then
		return { kind = "replace", slot = worst.slot, value = value, item = item, oldItem = worst.item, oldValue = worst.value }
	end
	return { kind = "keep_loose", value = value, item = item, oldValue = worst and worst.value or nil }
end

local function optimizeMuseumUidLocked(uid)
	local data = getData()
	local decision = museumDecisionForUid(data, uid)
	if not decision then
		return false, "unavailable"
	end
	if decision.kind == "keep_loose" then
		return false, "not_better"
	end
	if decision.kind == "fill" then
		if placeMuseumItem(decision.slot, uid) then
			Hub.LootStats.museum += 1
			return true, "filled"
		end
		return false, "place_failed"
	end

	local oldUid = decision.oldItem and decision.oldItem.uid
	if not pickupMuseumItem(decision.slot) then
		return false, "pickup_failed"
	end
	task.wait(0.25)
	if placeMuseumItem(decision.slot, uid) then
		Hub.LootStats.museum += 1
		return true, "upgraded"
	end
	if type(oldUid) == "string" then
		placeMuseumItem(decision.slot, oldUid)
	end
	return false, "restore"
end

local function findInventoryTool(uid)
	local char = character()
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	for _, parent in { char, backpack } do
		if parent then
			for _, child in parent:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("inventoryId") == uid then
					return child, backpack
				end
			end
		end
	end
	return nil, backpack
end

local function sellUidLocked(uid)
	local data = getData()
	local item = inventoryItemByUid(data, uid)
	if not isLooseItem(item) or isItemUnclean(item) or item.favorited == true then
		return false
	end

	local char = character()
	local root = rootPart()
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local target, backpack = findInventoryTool(uid)
	if not char or not root or not humanoid or not target then
		return false
	end

	local oldTool = char:FindFirstChildOfClass("Tool")
	local restoreChar, restoreCFrame = capturePivot()
	humanoid:UnequipTools()
	task.wait(0.04)
	if target.Parent ~= char then
		target.Parent = char
	end
	task.wait(0.08)

	if Hub.Settings.AutoMove then
		local islands = Workspace:FindFirstChild("Islands")
		local home = islands and islands:FindFirstChild("Home Beach")
		local npcs = home and home:FindFirstChild("NPCs")
		local sell = npcs and npcs:FindFirstChild("Sell")
		local seller = sell and sell:FindFirstChild("SellerNPC")
		local sellerRoot = seller and seller:FindFirstChild("HumanoidRootPart")
		if sellerRoot and sellerRoot:IsA("BasePart") then
			char:PivotTo(sellerRoot.CFrame * CFrame.new(0, 0, 3))
			task.wait(0.12)
		end
	end

	local result = awaitPromise(SellFunctions.sellHeldItem:invoke(), nil)
	task.wait(0.08)
	restorePivot(restoreChar, restoreCFrame)

	if oldTool and oldTool ~= target and oldTool.Parent == backpack then
		oldTool.Parent = char
	elseif target.Parent == char and result == nil and backpack then
		target.Parent = backpack
	end

	if type(result) == "number" and result > 0 then
		Hub.LootStats.sold += 1
		return true
	end
	return false
end

local function choosePipelineItem(data, preferredUid)
	if type(preferredUid) == "string" then
		local preferred = inventoryItemByUid(data, preferredUid)
		local readyAt = Hub.LootReadyAt[preferredUid] or 0
		if isLooseItem(preferred) and (not isItemUnclean(preferred) or os.clock() >= readyAt) then
			return preferred
		end
	end

	if Hub.Settings.AutoClean then
		for _, item in data.Inventory or {} do
			local readyAt = type(item.uid) == "string" and (Hub.LootReadyAt[item.uid] or 0) or 0
			if isLooseItem(item) and isItemUnclean(item) and os.clock() >= readyAt then
				return item
			end
		end
	end

	if Hub.Settings.AutoFillMuseum then
		local candidates = museumCandidates(data)
		if #candidates > 0 then
			return candidates[1].item
		end
	end

	if Hub.Settings.AutoSell then
		for _, item in data.Inventory or {} do
			if isLooseItem(item) and not isItemUnclean(item) and item.favorited ~= true then
				return item
			end
		end
	end
	return nil
end

local function lootPipelineStep(preferredUid)
	if not Hub.Alive or not acquireAction("loot", 5) then
		return false
	end
	Hub.LootState = "scan"
	local data = getData()
	local item = data and choosePipelineItem(data, preferredUid) or nil
	if not item then
		Hub.LootState = "idle"
		releaseAction("loot")
		return false
	end

	local uid = item.uid
	if isItemUnclean(item) then
		if not Hub.Settings.AutoClean then
			Hub.LootState = "waiting_for_auto_clean"
			releaseAction("loot")
			return false
		end
		Hub.LootState = "cleaning"
		if not cleanUid(uid) then
			Hub.LootStats.cleanRejected += 1
			Hub.LootState = "clean_cooldown"
			releaseAction("loot")
			return false
		end
		Hub.LootStats.cleaned += 1
		Hub.LootReadyAt[uid] = nil
		data = getData()
		item = inventoryItemByUid(data, uid)
		if not isLooseItem(item) or isItemUnclean(item) then
			Hub.LootState = "clean_confirm"
			releaseAction("loot")
			return false
		end
	end

	if Hub.Settings.AutoFillMuseum then
		Hub.LootState = "museum_check"
		local used = optimizeMuseumUidLocked(uid)
		if used then
			Hub.LootReadyAt[uid] = nil
			Hub.LootState = "museum"
			releaseAction("loot")
			return true
		end
	end

	if Hub.Settings.AutoSell then
		Hub.LootState = "selling"
		local sold = sellUidLocked(uid)
		if sold then
			Hub.LootReadyAt[uid] = nil
		end
		Hub.LootState = sold and "sold" or "sell_retry"
		releaseAction("loot")
		return sold
	end

	Hub.LootState = "clean_ready"
	releaseAction("loot")
	return true
end

local function shouldThrottleDigForLoot()
	local data = getData()
	if not data then
		return false
	end
	if Hub.Settings.AutoClean and hasLooseDirtyItems(data) then
		return true
	end
	if Hub.Settings.AutoClean and Hub.Settings.AutoSell and looseItemCount(data) > 0 then
		return true
	end
	return false
end

local function claimOffline()
	if type(OfflineEarningsController) == "table" and OfflineEarningsController.resolved == true and type(OfflineEarningsController.claim) == "function" then
		pcall(OfflineEarningsController.claim, OfflineEarningsController)
		return true
	end

	local request = OfflineEarningsFunctions.requestOfflineEarnings
	if type(request) ~= "table" or type(request.invoke) ~= "function" then
		return false
	end
	local pending = awaitPromise(request:invoke(), nil)
	if not pending then
		return false
	end
	awaitPromise(OfflineEarningsFunctions.claimOfflineEarnings:invoke(), nil)
	return true
end

local function claimFreePack()
	if type(ForeverPackController) == "table"
		and type(ForeverPackController.slots) == "table"
		and type(ForeverPackController.claim) == "function" then
		local slot = ForeverPackController.slots[1]
		if type(slot) == "table"
			and slot.paid ~= true
			and slot.index == ForeverPackController.index
			and (ForeverPackController.graceUntil or 0) <= os.clock() then
			pcall(ForeverPackController.claim, ForeverPackController, slot)
			return true
		end
		return false
	end
	ForeverPackEvents.claimFree:fire()
	return true
end

local function unlockPyramid()
	local data = getData()
	if not data or data.PyramidUnlocked then
		return false
	end
	if (data.Level or 0) < 25 then
		return false
	end
	return awaitPromise(PyramidFunctions.unlockPyramid:invoke(), false) == true
end

local function sacrificeGold(amount)
	amount = math.floor(tonumber(amount) or 0)
	if amount < 1 then
		return false
	end
	return awaitPromise(PyramidFunctions.sacrificeGold:invoke(amount), nil) ~= nil
end

local function redeemCode(code)
	code = tostring(code or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if code == "" then
		return false
	end
	return awaitPromise(CodeFunctions.redeemCode:invoke(code), nil)
end

local function teleportHome()
	if MiscEvents and MiscEvents.RequestTeleportHome then
		MiscEvents.RequestTeleportHome:fire()
		return true
	end
	return false
end

local function tutorialTick()
	if not Hub.Settings.AutoTutorial then
		return
	end

	local state = currentTutorialState()
	local data = getData()
	if not state or not data then
		return
	end

	local step = state.step
	local T = TutorialConstants.TutorialStep

	if step >= T.Done then
		return
	elseif step == T.GoToDigZone then
		local target = nearestDigZone("starterIsland")
		if target then
			moveToPosition(target)
		end
	elseif step == T.DetectItem then
		local target = nearestDigZone("starterIsland")
		if target then
			moveToPosition(target)
		end
	elseif step == T.GoToDigSpot then
		if state.digSpot then
			moveToPosition(state.digSpot)
		end
	elseif step == T.StartDig or step == T.SpamDig then
		digOnce()
	elseif step == T.GoClean or step == T.SprayDirt then
		cleanAll()
	elseif step == T.Reveal then
		TutorialEvents.ReportTutorialProgress:fire(T.PlaceItem)
	elseif step == T.PlaceItem then
		local uid = state.itemUid
		if type(uid) ~= "string" then
			for _, item in data.Inventory do
				if item.dirty ~= true and type(item.uid) == "string" then
					uid = item.uid
					break
				end
			end
		end
		if type(uid) == "string" then
			awaitPromise(PedestalFunctions.placeItem:invoke(TutorialConstants.TUTORIAL_PEDESTAL_SLOT, uid), false)
		end
	elseif step == T.Tourists then
		return
	elseif step == T.BuyShovel then
		moveNearGear("shovel", TutorialConstants.TUTORIAL_SHOVEL_ID)
		awaitPromise(ShopFunctions.buyGear:invoke("shovel", TutorialConstants.TUTORIAL_SHOVEL_ID), false)
		task.wait(0.2)
		awaitPromise(ShopFunctions.equipGear:invoke("shovel", TutorialConstants.TUTORIAL_SHOVEL_ID), false)
	end
end

local VibeUI = loadstring(game:HttpGet(
	"https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau?v=" .. tostring(os.clock())
))()
Hub.UI = VibeUI

local Window = VibeUI:Window({
	Title = "Dig & Clean Hub",
	Size = UDim2.fromOffset(760, 540),
	FadeTime = 0.2,
	Keybind = Enum.KeyCode.RightControl,
})

local FarmTab = Window:Tab({ Name = "Farm", Columns = 2 })
local Farm = FarmTab:Section({ Name = "Automation", Side = 1 })
local FarmActions = FarmTab:Section({ Name = "Actions", Side = 2 })

Farm:Toggle({
	Name = "Auto Tutorial",
	Flag = "DCAutoTutorial",
	Default = Hub.Settings.AutoTutorial,
	Callback = function(v)
		setSetting("AutoTutorial", v)
	end,
})

Farm:Toggle({
	Name = "Auto Dig",
	Flag = "DCAutoDig",
	Default = Hub.Settings.AutoDig,
	Callback = function(v)
		setSetting("AutoDig", v)
	end,
})

Farm:Toggle({
	Name = "Prioritize Safe Surfaced Items",
	Flag = "DCPrioritizeSurfaced",
	Default = Hub.Settings.PrioritizeSurfaced,
	Callback = function(v)
		setSetting("PrioritizeSurfaced", v)
	end,
})

Farm:Toggle({
	Name = "Auto Clean",
	Flag = "DCAutoClean",
	Default = Hub.Settings.AutoClean,
	Callback = function(v)
		setSetting("AutoClean", v)
	end,
})

Farm:Toggle({
	Name = "Auto Sell Inventory",
	Flag = "DCAutoSell",
	Default = Hub.Settings.AutoSell,
	Callback = function(v)
		setSetting("AutoSell", v)
	end,
})

Farm:Toggle({
	Name = "Auto Move To Dig Zone",
	Flag = "DCAutoMove",
	Default = Hub.Settings.AutoMove,
	Callback = function(v)
		setSetting("AutoMove", v)
	end,
})

Farm:Slider({
	Name = "Dig Loop Delay",
	Flag = "DCDigInterval",
	Min = 0.10,
	Max = 5,
	Default = Hub.Settings.DigInterval,
	Decimals = 0.05,
	Suffix = "s",
	Callback = function(v)
		setSetting("DigInterval", v)
	end,
})

Farm:Slider({
	Name = "Sell Delay",
	Flag = "DCSellInterval",
	Min = 1,
	Max = 30,
	Default = Hub.Settings.SellInterval,
	Decimals = 1,
	Suffix = "s",
	Callback = function(v)
		setSetting("SellInterval", v)
	end,
})

FarmActions:Button():Add("Dig Once", function()
	task.spawn(function()
		notify(digOnce() and "Dig completed" or "Dig could not start", "info")
	end)
end)

FarmActions:Button():Add("Clean All Dirty", function()
	task.spawn(function()
		local count = cleanAll()
		notify(("Cleaned %d item(s)"):format(count), count > 0 and "success" or "info")
	end)
end)

FarmActions:Button():Add("Sell Inventory", function()
	task.spawn(function()
		notify(sellAll() and "Inventory sold" or "Nothing sold", "info")
	end)
end)

FarmActions:Button():Add("Run Tutorial Tick", function()
	task.spawn(tutorialTick)
end)

FarmActions:Paragraph({
	Name = "Dig Method",
	Content = Risky.Requested
		and "Advanced mode tries the server-valid instant path first (BeginDig -> DigInput -> ResolveDig). Rejected or unsupported sessions fall back to the real controller/minigame path. Safe surfaced spawns remain prioritized."
		or "Fallback mode uses Flamework controllers and the real dig minigame. Safe surfaced spawns remain prioritized.",
})

FarmActions:Paragraph({
	Name = "Clean / Sell Safety",
	Content = "Loot is processed one item at a time: dig -> confirmed clean -> museum value check -> single-item sell if it is not a museum upgrade. Auto Dig pauses while the clean/sell pipeline is backed up, so dirty items cannot flood the backpack.",
})

local UpgradeTab = Window:Tab({ Name = "Upgrades", Columns = 2 })
local GearSection = UpgradeTab:Section({ Name = "Gear", Side = 1 })
local TravelSection = UpgradeTab:Section({ Name = "Islands", Side = 2 })

GearSection:Toggle({
	Name = "Auto Buy Shovel",
	Flag = "DCAutoShovel",
	Default = Hub.Settings.AutoShovel,
	Callback = function(v)
		setSetting("AutoShovel", v)
	end,
})

GearSection:Toggle({
	Name = "Auto Buy Spray",
	Flag = "DCAutoSpray",
	Default = Hub.Settings.AutoSpray,
	Callback = function(v)
		setSetting("AutoSpray", v)
	end,
})

GearSection:Toggle({
	Name = "Auto Buy Detector",
	Flag = "DCAutoDetector",
	Default = Hub.Settings.AutoDetector,
	Callback = function(v)
		setSetting("AutoDetector", v)
	end,
})

GearSection:Slider({
	Name = "Upgrade Check Delay",
	Flag = "DCUpgradeInterval",
	Min = 1,
	Max = 30,
	Default = Hub.Settings.UpgradeInterval,
	Decimals = 1,
	Suffix = "s",
	Callback = function(v)
		setSetting("UpgradeInterval", v)
	end,
})

GearSection:Button():Add("Buy Best All", function()
	task.spawn(function()
		buyAllBest()
		notify("Gear check complete", "success")
	end)
end)

GearSection:Button():Add("Equip Best Owned", function()
	task.spawn(function()
		for _, category in { "shovel", "spray", "detector" } do
			equipBestOwned(category)
		end
		notify("Best owned gear equipped", "success")
	end)
end)

TravelSection:Toggle({
	Name = "Auto Unlock Next Island",
	Flag = "DCAutoIslands",
	Default = Hub.Settings.AutoIslands,
	Callback = function(v)
		setSetting("AutoIslands", v)
	end,
})

local SelectedIsland = Hub.Settings.TravelIsland or "starterIsland"
TravelSection:Dropdown({
	Name = "Travel Island",
	Flag = "DCTravelIsland",
	Items = { "starterIsland", "island2", "island3", "island4" },
	Default = SelectedIsland,
	Callback = function(v)
		SelectedIsland = v
		setSetting("TravelIsland", v)
	end,
})

TravelSection:Button():Add("Travel / Unlock", function()
	task.spawn(function()
		notify(travelTo(SelectedIsland) and ("Traveled to " .. SelectedIsland) or "Travel failed", "info")
	end)
end)

TravelSection:Button():Add("Unlock Next Affordable", function()
	task.spawn(function()
		notify(unlockNextIsland() and "Unlocked next island" or "No affordable island", "info")
	end)
end)

TravelSection:Paragraph({
	Name = "Island Costs",
	Content = "Shipwreck Cove: 1.1M | Sphinx Sands: 32M | Frozen Shores: 120M",
})

local PlotTab = Window:Tab({ Name = "Plot", Columns = 2 })
local PlotProgress = PlotTab:Section({ Name = "Expansion", Side = 1 })
local Polishers = PlotTab:Section({ Name = "Polishers & Museum", Side = 2 })

PlotProgress:Toggle({
	Name = "Auto Unlock Plot Sections",
	Flag = "DCAutoPlotSections",
	Default = Hub.Settings.AutoPlotSections,
	Callback = function(v)
		setSetting("AutoPlotSections", v)
	end,
})

PlotProgress:Toggle({
	Name = "Auto Unlock Polishers",
	Flag = "DCAutoPolisherUnlock",
	Default = Hub.Settings.AutoPolisherUnlock,
	Callback = function(v)
		setSetting("AutoPolisherUnlock", v)
	end,
})

PlotProgress:Toggle({
	Name = "Auto Upgrade Polishers",
	Flag = "DCAutoPolisherUpgrade",
	Default = Hub.Settings.AutoPolisherUpgrade,
	Callback = function(v)
		setSetting("AutoPolisherUpgrade", v)
	end,
})

PlotProgress:Slider({
	Name = "Plot Check Delay",
	Flag = "DCPlotInterval",
	Min = 1,
	Max = 30,
	Default = Hub.Settings.PlotInterval,
	Decimals = 1,
	Suffix = "s",
	Callback = function(v)
		setSetting("PlotInterval", v)
	end,
})

PlotProgress:Button():Add("Unlock Affordable Sections", function()
	task.spawn(function()
		unlockPlotSections()
		unlockPolishers()
		notify("Plot unlock check complete", "success")
	end)
end)

PlotProgress:Button():Add("Upgrade Polishers", function()
	task.spawn(function()
		upgradePolishers()
		notify("Polisher upgrade check complete", "success")
	end)
end)

Polishers:Toggle({
	Name = "Auto Collect / Start Polish",
	Flag = "DCAutoPolish",
	Default = Hub.Settings.AutoPolish,
	Callback = function(v)
		setSetting("AutoPolish", v)
	end,
})

Polishers:Toggle({
	Name = "Auto Buy Upstairs Pedestals",
	Flag = "DCAutoPedestalBuy",
	Default = Hub.Settings.AutoPedestalBuy,
	Callback = function(v)
		setSetting("AutoPedestalBuy", v)
	end,
})

Polishers:Toggle({
	Name = "Auto Optimize Museum",
	Flag = "DCAutoFillMuseum",
	Default = Hub.Settings.AutoFillMuseum,
	Callback = function(v)
		setSetting("AutoFillMuseum", v)
	end,
})

Polishers:Button():Add("Collect / Start Polishers", function()
	task.spawn(function()
		runPolishers()
		notify("Polisher cycle complete", "success")
	end)
end)

Polishers:Button():Add("Buy Next Upstairs Pedestal", function()
	task.spawn(function()
		notify(buyNextPedestal() and "Pedestal purchased" or "Pedestal purchase failed", "info")
	end)
end)

Polishers:Button():Add("Optimize Museum Now", function()
	task.spawn(function()
		local changed, fills, upgrades = fillMuseum()
		if changed then
			notify(("Museum optimized: %d filled, %d upgraded"):format(fills, upgrades), "success")
		else
			notify("Museum is already using the best available items", "info")
		end
	end)
end)

local ProgressTab = Window:Tab({ Name = "Progress", Columns = 2 })
local Claims = ProgressTab:Section({ Name = "Claims", Side = 1 })
local Pyramid = ProgressTab:Section({ Name = "Pyramid / Codes", Side = 2 })

Claims:Toggle({
	Name = "Auto Claim Offline Earnings",
	Flag = "DCAutoOffline",
	Default = Hub.Settings.AutoOffline,
	Callback = function(v)
		setSetting("AutoOffline", v)
	end,
})

Claims:Toggle({
	Name = "Auto Claim Free Pack",
	Flag = "DCAutoFreePack",
	Default = Hub.Settings.AutoFreePack,
	Callback = function(v)
		setSetting("AutoFreePack", v)
	end,
})

Claims:Toggle({
	Name = "Auto Unlock Pyramid",
	Flag = "DCAutoPyramid",
	Default = Hub.Settings.AutoPyramid,
	Callback = function(v)
		setSetting("AutoPyramid", v)
	end,
})

Claims:Slider({
	Name = "Claim Check Delay",
	Flag = "DCClaimInterval",
	Min = 5,
	Max = 120,
	Default = Hub.Settings.ClaimInterval,
	Decimals = 1,
	Suffix = "s",
	Callback = function(v)
		setSetting("ClaimInterval", v)
	end,
})

Claims:Button():Add("Claim Offline Earnings", function()
	task.spawn(function()
		claimOffline()
		notify("Offline earnings claim sent", "success")
	end)
end)

Claims:Button():Add("Claim Free Pack", function()
	claimFreePack()
	notify("Free pack claim sent", "success")
end)

Claims:Button():Add("Unlock Pyramid", function()
	task.spawn(function()
		notify(unlockPyramid() and "Pyramid unlocked" or "Pyramid not available", "info")
	end)
end)

local CodeValue = ""
Pyramid:Textbox({
	Name = "Redeem Code",
	Flag = "DCRedeemCode",
	Placeholder = "Enter code",
	Finished = true,
	Callback = function(v)
		CodeValue = v
	end,
})

Pyramid:Button():Add("Redeem Code", function()
	task.spawn(function()
		local result = redeemCode(CodeValue)
		notify(result and ("Code result: " .. tostring(result)) or "Code failed", "info")
	end)
end)

local SacrificeAmount = "1"
Pyramid:Textbox({
	Name = "Sacrifice Gold",
	Flag = "DCSacrificeGold",
	Placeholder = "Amount",
	Finished = true,
	Callback = function(v)
		SacrificeAmount = v
	end,
})

Pyramid:Button():Add("Sacrifice Gold", function()
	task.spawn(function()
		notify(sacrificeGold(SacrificeAmount) and "Sacrifice sent" or "Sacrifice failed", "info")
	end)
end)

Pyramid:Paragraph({
	Name = "Horus Rewards",
	Content = "Weekly Well ranks: Shovel top 50 | Detector top 300 | Spray top 1000. Pyramid requires level 25.",
})

local RiskyTab = Window:Tab({ Name = "Advanced", Columns = 2 })
local RiskyDig = RiskyTab:Section({ Name = "Dig Acceleration", Side = 1 })
local RiskyRuntime = RiskyTab:Section({ Name = "Runtime Patches", Side = 2 })

RiskyDig:Toggle({
	Name = "Instant Auto Dig",
	Flag = "DCInstantDig",
	Default = Hub.Settings.InstantDig,
	Callback = function(v)
		setSetting("InstantDig", v and Risky.Requested)
	end,
})

RiskyDig:Toggle({
	Name = "Manual Dig Accelerator",
	Flag = "DCManualDigAccelerator",
	Default = Hub.Settings.ManualDigAccelerator,
	Callback = function(v)
		setSetting("ManualDigAccelerator", v and Risky.Requested)
	end,
})

RiskyDig:Toggle({
	Name = "Turbo Minigame 50 CPS",
	Flag = "DCTurboMinigame",
	Default = Hub.Settings.TurboMinigame,
	Callback = function(v)
		setSetting("TurboMinigame", v and Risky.Requested)
		applyTurboMinigame(Hub.Settings.TurboMinigame)
	end,
})

RiskyDig:Toggle({
	Name = "Skip Dig Animations",
	Flag = "DCSkipDigAnimations",
	Default = Hub.Settings.SkipDigAnimations,
	Callback = function(v)
		setSetting("SkipDigAnimations", v and Risky.Requested)
	end,
})

RiskyDig:Toggle({
	Name = "Perfect Power Timing",
	Flag = "DCPerfectPower",
	Default = Hub.Settings.PerfectPower,
	Callback = function(v)
		setSetting("PerfectPower", v and Risky.Requested)
	end,
})

RiskyDig:Toggle({
	Name = "No Client Dig Cooldown",
	Flag = "DCNoDigCooldown",
	Default = Hub.Settings.NoDigCooldown,
	Callback = function(v)
		setSetting("NoDigCooldown", v and Risky.Requested)
	end,
})

RiskyDig:Slider({
	Name = "Instant Resolve Delay",
	Flag = "DCInstantDigInputDelay",
	Min = 0.03,
	Max = 0.20,
	Default = Hub.Settings.InstantDigInputDelay,
	Decimals = 0.01,
	Suffix = "s",
	Callback = function(v)
		setSetting("InstantDigInputDelay", v)
	end,
})

RiskyDig:Slider({
	Name = "Node Surface Settle",
	Flag = "DCInstantDigSettle",
	Min = 0.05,
	Max = 0.30,
	Default = Hub.Settings.InstantDigSettle,
	Decimals = 0.01,
	Suffix = "s",
	Callback = function(v)
		setSetting("InstantDigSettle", v)
	end,
})

RiskyRuntime:Toggle({
	Name = "Restore Position After Warps",
	Flag = "DCRestorePosition",
	Default = Hub.Settings.RestorePosition,
	Callback = function(v)
		setSetting("RestorePosition", v)
	end,
})

RiskyRuntime:Toggle({
	Name = "Use Free Clean Skips",
	Flag = "DCUseFreeCleanSkips",
	Default = Hub.Settings.UseFreeCleanSkips,
	Callback = function(v)
		setSetting("UseFreeCleanSkips", v)
	end,
})

RiskyRuntime:Toggle({
	Name = "Bypass Client Backpack Full",
	Flag = "DCBypassBackpackFull",
	Default = Hub.Settings.BypassClientBackpackFull,
	Callback = function(v)
		setSetting("BypassClientBackpackFull", v and Risky.Requested)
		setBackpackBypass(Hub.Settings.BypassClientBackpackFull)
	end,
})

RiskyRuntime:Button():Add("Restore Runtime Patches", function()
	setSetting("TurboMinigame", false)
	setSetting("BypassClientBackpackFull", false)
	Hub.RestoreRuntimePatches()
	notify("Runtime patches restored", "success")
end)

RiskyRuntime:Paragraph({
	Name = "Resolver",
	Content = ("Mode: %s | Singleton controllers: %d | Loaded networks: %d\nsetupvalue: %s | hookfunction: %s | getconnections: %s\nFallback remains active feature-by-feature when an advanced executor primitive is missing."):format(
		Risky.ControllerSource,
		Risky.DirectControllers,
		Risky.LoadedNetworkModules,
		Risky.HasDebugSetupValue and "yes" or "no",
		Risky.HasHookFunction and "yes" or "no",
		Risky.HasGetConnections and "yes" or "no"
	),
})

local MiscTab = Window:Tab({ Name = "Misc", Columns = 2 })
local Misc = MiscTab:Section({ Name = "Utility", Side = 1 })
local Status = MiscTab:Section({ Name = "Status", Side = 2 })

Misc:Toggle({
	Name = "Anti AFK",
	Flag = "DCAntiAFK",
	Default = Hub.Settings.AntiAFK,
	Callback = function(v)
		setSetting("AntiAFK", v)
	end,
})

Misc:Toggle({
	Name = "Queue on Teleport",
	Flag = "DCQueueOnTeleport",
	Default = Hub.Settings.QueueOnTeleport,
	Callback = function(v)
		setSetting("QueueOnTeleport", v)
		saveSettings()
		if v then
			registerTeleportQueue()
		end
	end,
})

Misc:Button():Add("Teleport Home", function()
	teleportHome()
end)

Misc:Button():Add("Unload Hub", function()
	Hub.Alive = false
	pcall(Hub.RestoreRuntimePatches)
	pcall(function()
		VibeUI:Unload()
	end)
end)

local StatusParagraph = Status:Paragraph({
	Name = "Player Data",
	Content = "Press Refresh Status",
})

local function refreshStatus()
	local data = getData()
	if not data then
		StatusParagraph:SetText("Data unavailable")
		return
	end

	local plot = ownPlot()
	local plotIndex = plot and tonumber(string.match(plot.Name, "^Plot_(%d+)$")) or nil
	local visitors = 0
	if type(VisitorController) == "table" and type(VisitorController.rigged) == "table" and plotIndex then
		for _, visit in VisitorController.rigged do
			if type(visit) == "table" and type(visit.info) == "table" and visit.info.plotIndex == plotIndex then
				visitors += 1
			end
		end
	elseif type(VisitorFunctions) == "table" and type(VisitorFunctions.requestCrowdState) == "table" then
		local crowd = awaitPromise(VisitorFunctions.requestCrowdState:invoke(), nil)
		if type(crowd) == "table" and type(crowd.visits) == "table" and plotIndex then
			for _, visit in crowd.visits do
				if visit.plotIndex == plotIndex then
					visitors += 1
				end
			end
		end
	end

	local serverLuck = 1
	local globalLuck = 1
	if type(LuckController) == "table" then
		if type(LuckController.getServerLuck) == "function" then
			local ok, value = pcall(LuckController.getServerLuck, LuckController)
			if ok and type(value) == "number" then
				serverLuck = value
			end
		end
		if type(LuckController.getGlobalBoost) == "function" then
			local ok, boost = pcall(LuckController.getGlobalBoost, LuckController)
			if ok and type(boost) == "table" and type(boost.multiplier) == "number" then
				globalLuck = boost.multiplier
			end
		end
	end

	local safeSurfaced = 0
	local surfaced = awaitPromise(ShovelFunctions.GetSurfacedItems:invoke(), {})
	if type(surfaced) == "table" then
		for _, item in surfaced do
			if canDigSurfaced(item, data) then
				safeSurfaced += 1
			end
		end
	end

	local discovered = 0
	local collectionBonus = 0
	local nextMilestone
	pcall(function()
		discovered = CollectionConstants.discoveredCount(data.Discovered or {})
		collectionBonus = CollectionConstants.collectionLuckPercent(data.CollectionMilestones or 0)
		nextMilestone = CollectionConstants.nextMilestoneCount(data.CollectionMilestones or 0)
	end)

	StatusParagraph:SetText(table.concat({
		("Resolver: %s | %d direct | %d loaded networks"):format(Risky.ControllerSource, Risky.DirectControllers, Risky.LoadedNetworkModules),
		("Instant Dig: %d success / %d rejected | Manual accel: %d"):format(Risky.InstantDigSuccess, Risky.InstantDigRejected, Risky.ManualAccelerations),
		("Loot Pipeline: %s | Cleaned %d | Museum %d | Sold %d | Cooldown rejects %d"):format(tostring(Hub.LootState), Hub.LootStats.cleaned, Hub.LootStats.museum, Hub.LootStats.sold, Hub.LootStats.cleanRejected),
		("Turbo: %s | Backpack bypass: %s"):format(RuntimePatches.TurboApplied and "50 CPS" or "off", Hub.Settings.BypassClientBackpackFull and "on" or "off"),
		("Gold: %s"):format(tostring(data.Gold or 0)),
		("Level: %s | XP: %s"):format(tostring(data.Level or 0), tostring(data.Xp or 0)),
		("Island: %s | Plot: %s"):format(tostring(data.CurrentIsland), tostring(plotIndex or "?")),
		("Dug: %s | Cleaned: %s"):format(tostring(data.ItemsDug or 0), tostring(data.ItemsCleaned or 0)),
		("Inventory: %d | Free Clean Skips: %s"):format(type(data.Inventory) == "table" and #data.Inventory or 0, tostring(data.FreeSkips or 0)),
		("Shovel: %s | Spray: %s | Detector: %s"):format(tostring(data.EquippedShovel), tostring(data.EquippedSpray), tostring(data.EquippedDetector)),
		("Visitors: %d | Safe Surfaced: %d"):format(visitors, safeSurfaced),
		("Luck: %.2fx server | %.2fx global"):format(serverLuck, globalLuck),
		("Collection: %d/%s | Bonus: +%s%% | Next: %s"):format(discovered, tostring(CollectionConstants.TOTAL_DISCOVERABLE_ITEMS or "?"), tostring(collectionBonus), tostring(nextMilestone or "MAX")),
		("Tutorial Step: %s | Pyramid: %s"):format(tostring(data.TutorialStep), data.PyramidUnlocked and "Unlocked" or "Locked"),
	}, "\n"))
end

Status:Button():Add("Refresh Status", function()
	task.spawn(refreshStatus)
end)

local AcceleratedSessions = setmetatable({}, { __mode = "k" })
local PowerHandled = setmetatable({}, { __mode = "k" })

local RiskyHeartbeat = RunService.Heartbeat:Connect(function()
	if not Hub.Alive then
		return
	end
	if not Risky.Requested or type(DigController) ~= "table" then
		return
	end

	if Hub.Settings.NoDigCooldown then
		DigController.nextAttemptAt = 0
	end

	local session = DigController.session
	if not session or not Hub.Settings.ManualDigAccelerator then
		return
	end

	if Hub.Settings.SkipDigAnimations then
		session.fovPunch = 0
		session.itemKick = 0
	end

	if session.phase == "power" and Hub.Settings.PerfectPower and not PowerHandled[session] then
		local startedAt = tonumber(session.powerStartedAt) or 0
		if startedAt > 0 and Workspace:GetServerTimeNow() - startedAt >= 0.275 then
			PowerHandled[session] = true
			pcall(function()
				DigController:stopPower(false)
			end)
		end
	elseif session.phase == "revealing" then
		session.revealStarted = os.clock() - 100
		pcall(function()
			DigController:updateMoundReveal(session)
		end)
	elseif session.phase == "minigame" and not AcceleratedSessions[session] then
		if type(session.difficulty) == "table" and not DiggingConfig.isDigImpossible(session.difficulty) and type(session.sessionId) == "string" then
			AcceleratedSessions[session] = true
			Risky.ManualAccelerations += 1
			session.totalClicks = math.max(tonumber(session.totalClicks) or 0, 999)
			session.progress = 1
			pcall(function()
				ShovelEvents.DigInput:fire(session.sessionId, session.totalClicks)
			end)
			task.delay(math.max(0.03, Hub.Settings.InstantDigInputDelay or 0.08), function()
				if Hub.Alive and DigController.session == session and session.phase == "minigame" then
					pcall(function()
						DigController:finish(true)
					end)
				end
			end)
		end
	elseif Hub.Settings.SkipDigAnimations and session.phase == "success" then
		pcall(function()
			session.restoreMovement()
		end)
		pcall(function()
			DigController:endSession(session)
		end)
	elseif Hub.Settings.SkipDigAnimations and session.phase == "loss" then
		pcall(function()
			DigController:endSession(session)
		end)
	end
end)

task.spawn(function()
	while Hub.Alive do
		if Hub.Settings.AutoTutorial then
			pcall(tutorialTick)
		end
		if Hub.Settings.AutoDig then
			local throttled = false
			if Hub.Settings.AutoClean then
				local ok, result = pcall(shouldThrottleDigForLoot)
				throttled = ok and result == true
			end
			if not throttled then
				local ok, success, uid = pcall(digOnce)
				if not ok then
					Hub.BusyDig = false
					releaseAction("dig")
				end
				if ok and success and type(uid) == "string" and (Hub.Settings.AutoClean or Hub.Settings.AutoSell or Hub.Settings.AutoFillMuseum) then
					task.spawn(function()
						pcall(lootPipelineStep, uid)
					end)
				end
			end
		end
		task.wait(math.max(Risky.Requested and Hub.Settings.InstantDig and 0.10 or 0.55, Hub.Settings.DigInterval))
	end
end)

task.spawn(function()
	while Hub.Alive do
		if Hub.Settings.AutoClean or Hub.Settings.AutoSell or Hub.Settings.AutoFillMuseum then
			pcall(lootPipelineStep)
		end
		task.wait(0.12)
	end
end)

task.spawn(function()
	while Hub.Alive do
		if Hub.Settings.AutoShovel then
			pcall(buyBestAffordable, "shovel")
		end
		if Hub.Settings.AutoSpray then
			pcall(buyBestAffordable, "spray")
		end
		if Hub.Settings.AutoDetector then
			pcall(buyBestAffordable, "detector")
		end
		if Hub.Settings.AutoIslands then
			pcall(unlockNextIsland)
		end
		task.wait(math.max(1, Hub.Settings.UpgradeInterval))
	end
end)

task.spawn(function()
	while Hub.Alive do
		if not Hub.BusyPlot then
			Hub.BusyPlot = true
			if Hub.Settings.AutoPlotSections then
				pcall(unlockPlotSections)
			end
			if Hub.Settings.AutoPolisherUnlock then
				pcall(unlockPolishers)
			end
			if Hub.Settings.AutoPolisherUpgrade then
				pcall(upgradePolishers)
			end
			if Hub.Settings.AutoPolish then
				pcall(runPolishers)
			end
			if Hub.Settings.AutoPedestalBuy then
				pcall(buyNextPedestal)
			end
			Hub.BusyPlot = false
		end
		task.wait(math.max(1, Hub.Settings.PlotInterval))
	end
end)

task.spawn(function()
	while Hub.Alive do
		if Hub.Settings.AutoOffline then
			pcall(claimOffline)
		end
		if Hub.Settings.AutoFreePack then
			pcall(claimFreePack)
		end
		if Hub.Settings.AutoPyramid then
			pcall(unlockPyramid)
		end
		task.wait(math.max(5, Hub.Settings.ClaimInterval))
	end
end)

task.spawn(function()
	while Hub.Alive do
		if Hub.Settings.AntiAFK then
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new(0, 0))
			end)
		end
		task.wait(60)
	end
end)

task.spawn(function()
	while Hub.Alive do
		task.wait(0.5)
	end
	pcall(function()
		RiskyHeartbeat:Disconnect()
	end)
	pcall(Hub.RestoreRuntimePatches)
end)

task.spawn(function()
	task.wait(0.5)
	refreshStatus()
	notify("Dig & Clean Hub loaded", "success")
end)

return Hub
