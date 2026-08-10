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

local UIProtector = rawget(Environment, "__lt_ui_protector")

if type(UIProtector) ~= "table" then
	local Loader = loadstring

	if type(Loader) ~= "function" then
		error("UIProtector loader unavailable")
	end

	local ProtectorSource = game:HttpGet(
		"https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/UIprotector.luau"
	)

	local ProtectorChunk, ProtectorCompileError = Loader(
		ProtectorSource,
		"@UIprotector.luau"
	)

	if type(ProtectorChunk) ~= "function" then
		error("UIProtector compile failed: " .. tostring(ProtectorCompileError))
	end

	local ProtectorSuccess, ProtectorResult = pcall(ProtectorChunk)

	if not ProtectorSuccess or type(ProtectorResult) ~= "table" then
		error("UIProtector load failed: " .. tostring(ProtectorResult))
	end

	UIProtector = ProtectorResult
	Environment.__lt_ui_protector = UIProtector
end

if type(UIProtector.installGetHuiOverride) ~= "function"
	or UIProtector.installGetHuiOverride() ~= true
then
	error("UIProtector gethui override failed")
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

local LocalPlayer = Players.LocalPlayer

local RS_Package = ReplicatedStorage:WaitForChild("RS_Package", math.huge)
local Assets = RS_Package:WaitForChild("Assets", math.huge)
local Remotes = Assets:WaitForChild("Remotes", math.huge)
local Event = Remotes:WaitForChild("Damage", math.huge)

local NotorietyUI = {}

do
	local WindUISource = game:HttpGet(
		"https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"
	)
	local WindUIInputPatchCount
	WindUISource, WindUIInputPatchCount = WindUISource:gsub(
		"if not ao then\nal%.Frame%.Frame%.TextBox%.Text=an\nend",
		"if not ao then pcall(function() al.Frame.Frame.TextBox.Text=an end) end",
		1
	)

	if WindUIInputPatchCount ~= 1 then
		error("WindUI input compatibility patch failed")
	end

	local WindUIChunk, WindUICompileError = loadstring(WindUISource, "@WindUI.lua")

	if type(WindUIChunk) ~= "function" then
		error("WindUI compile failed: " .. tostring(WindUICompileError))
	end

	local WindUISuccess, WindUIResult = pcall(WindUIChunk)

	if not WindUISuccess or type(WindUIResult) ~= "table" then
		error("WindUI load failed: " .. tostring(WindUIResult))
	end

	NotorietyUI.Library = WindUIResult
	NotorietyUI.ProtectedRoots = {
		ScreenGui = "WindUI",
		NotificationGui = "WindUI/Notifications",
		DropdownGui = "WindUI/Dropdowns",
		TooltipGui = "WindUI/Tooltips",
	}

	for Key, Name in NotorietyUI.ProtectedRoots do
		local Root = WindUIResult[Key]

		if typeof(Root) ~= "Instance"
			or not Root:IsA("ScreenGui")
		then
			error("WindUI root unavailable for UIProtector: " .. tostring(Key))
		end

		if UIProtector.protectUI(Root, {
			name = Name,
			harden = true,
			deep = true,
			watch = true,
		}) ~= Root then
			error("UIProtector failed to protect WindUI root: " .. tostring(Key))
		end
	end
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
Environment.NotorietyFireDelay = tonumber(Environment.NotorietyFireDelay) or 0.01
Environment.NotorietyBoltDuration = tonumber(Environment.NotorietyBoltDuration) or 0.001
Environment.NotorietyAccuracy = tonumber(Environment.NotorietyAccuracy) or 100
Environment.NotorietyItemESPEnabled = false
Environment.NotorietyEquipmentSpeedEnabled = Environment.NotorietyEquipmentSpeedEnabled ~= false
Environment.NotorietyEquipmentSpeedMultiplier = tonumber(Environment.NotorietyEquipmentSpeedMultiplier) or 2
Environment.NotorietyEquipmentPositionEnabled = Environment.NotorietyEquipmentPositionEnabled == true
Environment.NotorietyEquipmentPositionX = tonumber(Environment.NotorietyEquipmentPositionX) or 0
Environment.NotorietyEquipmentPositionY = tonumber(Environment.NotorietyEquipmentPositionY) or 0
Environment.NotorietyEquipmentPositionZ = tonumber(Environment.NotorietyEquipmentPositionZ) or 0
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
end

local function findEquipmentPlacementFunction()
	local Existing = EquipmentSpeedState.Function
	local FunctionEnvironment = EquipmentSpeedState.FunctionEnvironment
	local WrappedTick = EquipmentSpeedState.WrappedTick

	if type(Existing) == "function"
		and type(FunctionEnvironment) == "table"
		and type(WrappedTick) == "function"
		and rawget(FunctionEnvironment, "tick") == WrappedTick
	then
		return Existing
	end

	if type(getgc) ~= "function"
		or type(getfenv) ~= "function"
		or type(debug) ~= "table"
		or type(debug.getinfo) ~= "function"
	then
		return nil
	end

	for _, Function in getgc(true) do
		if type(Function) == "function" then
			local Success, Info = pcall(debug.getinfo, Function)

			if Success
				and type(Info) == "table"
				and Info.source == "=Players." .. LocalPlayer.Name .. ".PlayerGui.SG_Package.LocalMovement"
				and Info.name == "placeEquipment"
			then
				local EnvironmentSuccess, FunctionEnvironmentResult = pcall(getfenv, Function)

				if EnvironmentSuccess and type(FunctionEnvironmentResult) == "table" then
					EquipmentSpeedState.Function = Function
					EquipmentSpeedState.FunctionEnvironment = FunctionEnvironmentResult
					return Function
				end
			end
		end
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
	local EquipmentPercent = LocalPlayer
		:WaitForChild("PlayerGui", math.huge)
		:WaitForChild("SG_Package", math.huge)
		:WaitForChild("MainGui", math.huge)
		:WaitForChild("Interaction", math.huge)
		:WaitForChild("EquipmentPercent", math.huge)

	local function WrappedTick(...)
		local Now = OriginalTick(...)
		local CallerSuccess, Caller = pcall(debug.info, 2, "f")

		if CallerSuccess and Caller == Function then
			EquipmentSpeedState.CFrameLookAtCount = 0
		end

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
	if Environment.NotorietyUnloaded or not Environment.NotorietyInfiniteYellMarkEnabled then
		return false
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

	local Wrapper = createViewportYellWrapper()
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

	table.insert(
		YellPatchState.NoDelayConnections,
		UserInputService.InputBegan:Connect(function()
			ResetDebounce()
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
local PoliceHitboxSize = Vector3.new(10, 10, 10)

local function restorePolicePart(Object)
	local Original = PoliceOriginalSizes[Object]

	if Original and Object.Parent then
		if typeof(Original) == "Vector3" then
			Object.Size = Original
		else
			Object.Size = Original.Size
			Object.Transparency = Original.Transparency
			Object.Massless = Original.Massless
			Object.CanCollide = Original.CanCollide
		end

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

	if Head and Torso then
		restorePolicePart(Torso)
	end

	if Target and Target:IsA("BasePart") then
		local Original = PoliceOriginalSizes[Target]

		if not Original then
			PoliceOriginalSizes[Target] = {
				Size = Target.Size,
				Transparency = Target.Transparency,
				Massless = Target.Massless,
				CanCollide = Target.CanCollide,
			}
		elseif typeof(Original) == "Vector3" then
			PoliceOriginalSizes[Target] = {
				Size = Original,
				Transparency = Target.Transparency,
				Massless = Target.Massless,
				CanCollide = Target.CanCollide,
			}
		end

		Target.Size = PoliceHitboxSize
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

if PoliceFolder then
	for _, NPC in PoliceFolder:GetChildren() do
		resizePoliceNPC(NPC)
	end

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
		pcall(UIProtector.cleanup, Folder)
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

	local ProtectSuccess, ProtectedFolder = pcall(UIProtector.protectUI, Folder, {
		lockName = true,
		name = "NotorietyItemESP",
		harden = true,
		deep = true,
		watch = true,
	})

	if not ProtectSuccess or typeof(ProtectedFolder) ~= "Instance" then
		pcall(function()
			Folder:Destroy()
		end)
		return false
	end

	ItemESPState.Folder = ProtectedFolder

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

local function createWindUI()
	local WindUI = NotorietyUI.Library
	local Window = WindUI:CreateWindow({
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

	local function saveWindUIConfig()
		if NotorietyUI.ConfigLoading or not NotorietyUI.Config then
			return
		end

		pcall(function()
			NotorietyUI.Config:Save()
		end)
	end

	NotorietyUI.SaveConfig = saveWindUIConfig

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
		Desc = "Targets the full viewport through walls with no distance limit",
		Value = Environment.NotorietyInfiniteYellMarkEnabled,
		Callback = function(Enabled)
			setYellMarkPatchEnabled(Enabled)
			saveWindUIConfig()
		end,
	})

	MainTab:Toggle({
		Flag = "AutoYell",
		Title = "Auto Yell",
		Desc = "Automatically yells new viewport targets without spamming unchanged targets",
		Value = Environment.NotorietyAutoYellEnabled,
		Callback = function(Enabled)
			YellPatchState.SetAutoYellEnabled(Enabled)
			saveWindUIConfig()
		end,
	})

	MainTab:Toggle({
		Flag = "NoYellDelay",
		Title = "No Yell / Mark Delay",
		Desc = "Removes the native 0.5 second client yell debounce without per-frame scanning",
		Value = Environment.NotorietyNoYellDelayEnabled,
		Callback = function(Enabled)
			YellPatchState.SetNoDelayEnabled(Enabled)
			saveWindUIConfig()
		end,
	})

	MainTab:Toggle({
		Flag = "ItemESP",
		Title = "Item ESP",
		Desc = "Highlights supported loot and interaction objects",
		Value = Environment.NotorietyItemESPEnabled,
		Callback = function(Enabled)
			setItemESPEnabled(Enabled)
			saveWindUIConfig()
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
			saveWindUIConfig()
		end,
	})

	NotorietyUI.FireDelayInput = WeaponTab:Input({
		Flag = "FireDelay",
		Title = "Fire Delay",
		Desc = "Shot cooldown in seconds. Default: 0.01",
		Value = tostring(Environment.NotorietyFireDelay),
		Placeholder = "0.01",
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil then
				return
			end

			Environment.NotorietyFireDelay = Number

			if Environment.NotorietyWeaponEnabled then
				applyAllWeaponModifications()
			end

			saveWindUIConfig()
		end,
	})

	NotorietyUI.BoltDurationInput = WeaponTab:Input({
		Flag = "BoltDuration",
		Title = "Bolt Duration",
		Desc = "Bolt animation/tween duration in seconds. Default: 0.001",
		Value = tostring(Environment.NotorietyBoltDuration),
		Placeholder = "0.001",
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil then
				return
			end

			Environment.NotorietyBoltDuration = Number

			if Environment.NotorietyWeaponEnabled then
				applyAllWeaponModifications()
			end

			saveWindUIConfig()
		end,
	})

	NotorietyUI.AccuracyInput = WeaponTab:Input({
		Flag = "GunAccuracy",
		Title = "Gun Accuracy",
		Desc = "0-100, default: 100. Updates live weapon spread immediately.",
		Value = tostring(Environment.NotorietyAccuracy),
		Placeholder = "100",
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

			saveWindUIConfig()
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
				NotorietyUI.FireDelayInput:Set("0.01")
			end)
			pcall(function()
				NotorietyUI.BoltDurationInput:Set("0.001")
			end)
			pcall(function()
				NotorietyUI.AccuracyInput:Set("100")
			end)

			if Environment.NotorietyWeaponEnabled then
				applyAllWeaponModifications()
			end

			saveWindUIConfig()
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
			saveWindUIConfig()
		end,
	})

	NotorietyUI.EquipmentSpeedInput = EquipmentTab:Input({
		Flag = "EquipmentSpeedMultiplier",
		Title = "Placement Speed",
		Desc = "Default: 2x. Use 1 for normal speed",
		Value = tostring(Environment.NotorietyEquipmentSpeedMultiplier),
		Placeholder = "2",
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

			saveWindUIConfig()
		end,
	})

	EquipmentTab:Button({
		Title = "Reset Placement Speed",
		Desc = "Resets the multiplier to 2x",
		Icon = "rotate-ccw",
		Callback = function()
			Environment.NotorietyEquipmentSpeedMultiplier = 2

			pcall(function()
				NotorietyUI.EquipmentSpeedInput:Set("2")
			end)

			if Environment.NotorietyEquipmentSpeedEnabled then
				applyEquipmentPlacementSpeed()
			end

			saveWindUIConfig()
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
			saveWindUIConfig()
		end,
	})

	NotorietyUI.EquipmentPositionXInput = EquipmentTab:Input({
		Flag = "EquipmentPositionX",
		Title = "Left / Right Offset",
		Desc = "Positive = right, negative = left",
		Value = tostring(Environment.NotorietyEquipmentPositionX),
		Placeholder = "0",
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil or Number == math.huge or Number == -math.huge or Number ~= Number then
				return
			end

			Environment.NotorietyEquipmentPositionX = Number
			saveWindUIConfig()
		end,
	})

	NotorietyUI.EquipmentPositionYInput = EquipmentTab:Input({
		Flag = "EquipmentPositionY",
		Title = "Up / Down Offset",
		Desc = "Positive = up, negative = down",
		Value = tostring(Environment.NotorietyEquipmentPositionY),
		Placeholder = "0",
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil or Number == math.huge or Number == -math.huge or Number ~= Number then
				return
			end

			Environment.NotorietyEquipmentPositionY = Number
			saveWindUIConfig()
		end,
	})

	NotorietyUI.EquipmentPositionZInput = EquipmentTab:Input({
		Flag = "EquipmentPositionZ",
		Title = "Forward / Back Offset",
		Desc = "Positive = forward, negative = back",
		Value = tostring(Environment.NotorietyEquipmentPositionZ),
		Placeholder = "0",
		Callback = function(Value)
			local Number = tonumber(Value)

			if Number == nil or Number == math.huge or Number == -math.huge or Number ~= Number then
				return
			end

			Environment.NotorietyEquipmentPositionZ = Number
			saveWindUIConfig()
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
				NotorietyUI.EquipmentPositionXInput:Set("0")
			end)
			pcall(function()
				NotorietyUI.EquipmentPositionYInput:Set("0")
			end)
			pcall(function()
				NotorietyUI.EquipmentPositionZInput:Set("0")
			end)

			saveWindUIConfig()
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

			saveWindUIConfig()
		end,
	})

	UtilityTab:Button({
		Title = "Unload",
		Desc = "Restores modified data and unloads Notoriety",
		Icon = "log-out",
		Callback = function()
			saveWindUIConfig()

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
createWindUI()
setWeaponModificationsEnabled(Environment.NotorietyWeaponEnabled)
setYellMarkPatchEnabled(Environment.NotorietyInfiniteYellMarkEnabled)
YellPatchState.SetAutoYellEnabled(Environment.NotorietyAutoYellEnabled)
YellPatchState.SetNoDelayEnabled(Environment.NotorietyNoYellDelayEnabled)
applyEquipmentPlacementSpeed()
applyEquipmentPositioning()

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
