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

local Reference = if type(cloneref) == "function" then cloneref else function(Value)
	return Value
end

local ReplicatedStorage = ServiceResolver.cs("ReplicatedStorage", Reference)
local Workspace = ServiceResolver.cs("Workspace", Reference)
local Players = ServiceResolver.cs("Players", Reference)
local RunService = ServiceResolver.cs("RunService", Reference)
local CollectionService = ServiceResolver.cs("CollectionService", Reference)

local LocalPlayer = Players.LocalPlayer

local RS_Package = ReplicatedStorage:WaitForChild("RS_Package", math.huge)
local Assets = RS_Package:WaitForChild("Assets", math.huge)
local Remotes = Assets:WaitForChild("Remotes", math.huge)
local Event = Remotes:WaitForChild("Damage", math.huge)

local IconSource = game:HttpGet(
	"https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Icon.luau"
)
local IconChunk, IconCompileError = loadstring(IconSource, "@Icon.luau")

if type(IconChunk) ~= "function" then
	error("Icon compile failed: " .. tostring(IconCompileError))
end

local IconSuccess, IconResult = pcall(IconChunk)

if not IconSuccess or type(IconResult) ~= "table" then
	error("Icon load failed: " .. tostring(IconResult))
end

local Icon = IconResult

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

if type(Environment.NotorietyTopbarConnections) == "table" then
	for _, Connection in Environment.NotorietyTopbarConnections do
		pcall(function()
			Connection:Disconnect()
		end)
	end
end

if type(Environment.NotorietyTopbarCharacterConnections) == "table" then
	for _, Connection in Environment.NotorietyTopbarCharacterConnections do
		pcall(function()
			Connection:Disconnect()
		end)
	end
end

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

if Environment.NotorietyMenuIcon then
	pcall(function()
		Environment.NotorietyMenuIcon:destroy()
	end)

	Environment.NotorietyMenuIcon = nil
end

if Environment.NotorietyWeaponIcon then
	pcall(function()
		Environment.NotorietyWeaponIcon:destroy()
	end)

	Environment.NotorietyWeaponIcon = nil
end

if Environment.MaxEverythingIcon then
	pcall(function()
		Environment.MaxEverythingIcon:destroy()
	end)

	Environment.MaxEverythingIcon = nil
end

if Environment.NotorietyItemESPIcon then
	pcall(function()
		Environment.NotorietyItemESPIcon:destroy()
	end)

	Environment.NotorietyItemESPIcon = nil
end

if type(Environment.NotorietyItemESPController) == "table"
	and type(Environment.NotorietyItemESPController.Cleanup) == "function"
then
	pcall(Environment.NotorietyItemESPController.Cleanup)
	Environment.NotorietyItemESPController = nil
end

Environment.MaxEverythingEnabled = true
Environment.KillPoliceRunning = false
Environment.NotorietyWeaponEnabled = true
Environment.NotorietyItemESPEnabled = false
Environment.NotorietyWeaponConnections = {}
Environment.NotorietyTopbarConnections = {}
Environment.NotorietyTopbarCharacterConnections = {}
Environment.NotorietyTopbarRepairToken = 0
Environment.NotorietyTopbarRebuilding = false
Environment.NotorietyTopbarRefresh = 0
Environment.NotorietyUnloaded = false

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

local function shortenGunSequence(Value, Backup, Seen, Depth)
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

		Value[7] = 0.001
	end

	for Key, Item in Value do
		local LowerKey = type(Key) == "string" and string.lower(Key) or nil

		if LowerKey and type(Item) == "number" and (
			LowerKey == "boltduration"
			or LowerKey == "firedelay"
			or LowerKey == "shotdelay"
			or LowerKey == "cooldown"
			or LowerKey == "duration"
		) then
			captureNestedField(Backup, Value, Key)
			Value[Key] = 0.001
		elseif LowerKey == "boltlock" and type(Item) == "boolean" then
			captureNestedField(Backup, Value, Key)
			Value[Key] = false
		end

		if type(Item) == "table" then
			shortenGunSequence(Item, Backup, Seen, Depth + 1)
		end
	end
end

local function patchGunSequences(Data, Backup)
	local Seen = {}

	for Key, Value in Data do
		if type(Key) == "string" and type(Value) == "table" then
			local LowerKey = string.lower(Key)

			if string.find(LowerKey, "shoot", 1, true)
				or string.find(LowerKey, "bolt", 1, true)
				or string.find(LowerKey, "fire", 1, true)
			then
				shortenGunSequence(Value, Backup, Seen, 0)
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

	if not isInfiniteGunState(State, Data) then
		restoreAmmoWrapper(State)
		WeaponState.RuntimeWeapons[State] = nil
		return Patched
	end

	WeaponState.RuntimeWeapons[State] = true
	State.Ready = true
	State.postshooting = false
	State.postshooting2 = false
	State.waspostshooting = false
	State.waspostshooting2 = false
	State.LastShot = 0
	State.shoottick0 = 0
	State.shoottick0_2 = 0
	State.firemodeT0 = 0
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

local function refreshRuntimeAmmo()
	if not Environment.NotorietyWeaponEnabled then
		return
	end

	for State in WeaponState.RuntimeWeapons do
		patchRuntimeWeaponState(State)
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

applyWeaponData = function(Data)
	if not Environment.NotorietyWeaponEnabled or type(Data) ~= "table" then
		return false
	end

	local WeaponType = rawget(Data, "WeaponType")

	if WeaponType == "Gun" then
		if not isStandardGunData(Data) then
			return false
		end

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
			"ShakeMagnitude",
			"ShakeRoughness",
			"PushBack",
		} do
			captureField(Data, Backup, Key)
		end

		Data.FireDelay = 0.01
		Data.BoltDuration = 0.001
		Data.BoltLock = false
		Data.FireMode = "Auto"

		if type(Data.FireModeList) ~= "table"
			or Data.FireModeList[1] ~= "Auto"
			or Data.FireModeList[2] ~= nil
		then
			Data.FireModeList = {
				"Auto",
			}
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

local function setIconLabel(Label)
	local CurrentIcon = Environment.MaxEverythingIcon

	if not CurrentIcon then
		return
	end

	pcall(function()
		CurrentIcon:setLabel(Label)
	end)
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
	setIconLabel("Killing....")

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

				task.wait(0.3)
			end
		end
	end, debug.traceback)

	Environment.KillPoliceRunning = false
	setIconLabel("Kill Police [P]")

	if not Success then
		warn(Error)
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
	end

	local CurrentIcon = Environment.NotorietyWeaponIcon

	if CurrentIcon then
		pcall(function()
			CurrentIcon:setLabel(
				Environment.NotorietyWeaponEnabled and "Weapon Mods: ON" or "Weapon Mods: OFF"
			)
		end)
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

	local CurrentIcon = Environment.NotorietyItemESPIcon

	if CurrentIcon then
		pcall(function()
			CurrentIcon:setLabel(
				Environment.NotorietyItemESPEnabled and "Item ESP: ON" or "Item ESP: OFF"
			)
		end)
	end
end

local ItemESPController = {}

function ItemESPController.Cleanup()
	Environment.NotorietyItemESPEnabled = false
	stopItemESP()
end

Environment.NotorietyItemESPController = ItemESPController

local function isIconAlive(CurrentIcon)
	if type(CurrentIcon) ~= "table" then
		return false
	end

	local Widget = rawget(CurrentIcon, "widget")

	return typeof(Widget) == "Instance" and Widget.Parent ~= nil
end

local function destroyIcon(CurrentIcon)
	if type(CurrentIcon) ~= "table" then
		return
	end

	pcall(function()
		CurrentIcon:destroy()
	end)
end

local function createKillPoliceIcon()
	local CurrentIcon = Icon.new()
		:setName("Kill Police")
		:setLabel("Kill Police [P]")
		:setRight()
		:autoDeselect(false)
		:bindToggleKey(Enum.KeyCode.P)
		:bindEvent("selected", function()
			task.spawn(runKill)
		end)
		:oneClick()

	Environment.MaxEverythingIcon = CurrentIcon

	return CurrentIcon
end

local function createWeaponModsIcon()
	local CurrentIcon = Icon.new()
		:setName("Weapon Mods")
		:setLabel(
			Environment.NotorietyWeaponEnabled and "Weapon Mods: ON" or "Weapon Mods: OFF"
		)
		:setRight()
		:autoDeselect(false)
		:bindEvent("selected", function()
			if not Environment.NotorietyTopbarRebuilding then
				setWeaponModificationsEnabled(true)
			end
		end)
		:bindEvent("deselected", function()
			if not Environment.NotorietyTopbarRebuilding then
				setWeaponModificationsEnabled(false)
			end
		end)

	Environment.NotorietyWeaponIcon = CurrentIcon

	if Environment.NotorietyWeaponEnabled then
		CurrentIcon:select()
	else
		CurrentIcon:deselect()
	end

	return CurrentIcon
end

local function createItemESPIcon()
	local CurrentIcon = Icon.new()
		:setName("Item ESP")
		:setLabel(
			Environment.NotorietyItemESPEnabled and "Item ESP: ON" or "Item ESP: OFF"
		)
		:setRight()
		:autoDeselect(false)
		:bindEvent("selected", function()
			if not Environment.NotorietyTopbarRebuilding then
				setItemESPEnabled(true)
			end
		end)
		:bindEvent("deselected", function()
			if not Environment.NotorietyTopbarRebuilding then
				setItemESPEnabled(false)
			end
		end)

	Environment.NotorietyItemESPIcon = CurrentIcon

	if Environment.NotorietyItemESPEnabled then
		CurrentIcon:select()
	else
		CurrentIcon:deselect()
	end

	return CurrentIcon
end

local function rebuildTopbarIcons(Force)
	if Environment.NotorietyUnloaded then
		return
	end

	local RebuildMenu = Force == true
		or not isIconAlive(Environment.NotorietyMenuIcon)
		or not isIconAlive(Environment.MaxEverythingIcon)
		or not isIconAlive(Environment.NotorietyWeaponIcon)
		or not isIconAlive(Environment.NotorietyItemESPIcon)

	if not RebuildMenu then
		return
	end

	local WeaponEnabled = Environment.NotorietyWeaponEnabled
	local ItemESPEnabled = Environment.NotorietyItemESPEnabled
	Environment.NotorietyTopbarRebuilding = true

	destroyIcon(Environment.MaxEverythingIcon)
	destroyIcon(Environment.NotorietyWeaponIcon)
	destroyIcon(Environment.NotorietyItemESPIcon)
	destroyIcon(Environment.NotorietyMenuIcon)

	Environment.MaxEverythingIcon = nil
	Environment.NotorietyWeaponIcon = nil
	Environment.NotorietyItemESPIcon = nil
	Environment.NotorietyMenuIcon = nil

	local MenuIcon = Icon.new()
		:setName("Notoriety Menu")
		:setLabel("Notoriety")
		:setMid()
		:autoDeselect(false)
	local KillPoliceIcon = createKillPoliceIcon()
	local WeaponModsIcon = createWeaponModsIcon()
	local ItemESPIcon = createItemESPIcon()

	MenuIcon:setMenu({
		KillPoliceIcon,
		WeaponModsIcon,
		ItemESPIcon,
	})

	Environment.NotorietyMenuIcon = MenuIcon

	Environment.NotorietyTopbarRebuilding = false

	local CurrentIcon = Environment.NotorietyWeaponIcon

	if CurrentIcon then
		pcall(function()
			CurrentIcon:setLabel(WeaponEnabled and "Weapon Mods: ON" or "Weapon Mods: OFF")
		end)
	end

	local CurrentItemESPIcon = Environment.NotorietyItemESPIcon

	if CurrentItemESPIcon then
		pcall(function()
			CurrentItemESPIcon:setLabel(ItemESPEnabled and "Item ESP: ON" or "Item ESP: OFF")
		end)
	end
end

local function scheduleTopbarRepair()
	if Environment.NotorietyUnloaded then
		return
	end

	Environment.NotorietyTopbarRepairToken += 1
	local RepairToken = Environment.NotorietyTopbarRepairToken

	task.spawn(function()
		for _, Delay in {
			0.1,
			0.35,
			0.8,
		} do
			task.wait(Delay)

			if RepairToken ~= Environment.NotorietyTopbarRepairToken then
				return
			end

			rebuildTopbarIcons(false)
		end
	end)
end

local function bindTopbarCharacter(Character)
	if Environment.NotorietyUnloaded then
		return
	end

	for _, Connection in Environment.NotorietyTopbarCharacterConnections do
		pcall(function()
			Connection:Disconnect()
		end)
	end

	table.clear(Environment.NotorietyTopbarCharacterConnections)

	if not Character then
		return
	end

	local function onCharacterToolChanged(Object)
		if Object:IsA("Tool") then
			scheduleTopbarRepair()
		end
	end

	table.insert(
		Environment.NotorietyTopbarCharacterConnections,
		Character.ChildAdded:Connect(onCharacterToolChanged)
	)
	table.insert(
		Environment.NotorietyTopbarCharacterConnections,
		Character.ChildRemoved:Connect(onCharacterToolChanged)
	)
end

local function onBackpackToolChanged(Object)
	if Object:IsA("Tool") then
		scheduleTopbarRepair()
	end
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

	Environment.NotorietyUnloaded = true
	Environment.MaxEverythingEnabled = false
	Environment.NotorietyWeaponEnabled = false
	Environment.NotorietyItemESPEnabled = false
	Environment.KillPoliceRunning = false
	Environment.NotorietyTopbarRepairToken += 1

	disconnectConnection(Environment.MaxEverythingConnection)
	disconnectConnection(Environment.MaxEverythingCharacterConnection)
	disconnectConnection(Environment.NotorietyPoliceHitboxConnection)

	Environment.MaxEverythingConnection = nil
	Environment.MaxEverythingCharacterConnection = nil
	Environment.NotorietyPoliceHitboxConnection = nil

	disconnectConnections(Environment.NotorietyWeaponConnections)
	disconnectConnections(Environment.NotorietyTopbarConnections)
	disconnectConnections(Environment.NotorietyTopbarCharacterConnections)

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
	ItemESPController.Cleanup()

	for Object in PoliceOriginalSizes do
		pcall(restorePolicePart, Object)
	end

	destroyIcon(Environment.NotorietyWeaponIcon)
	destroyIcon(Environment.MaxEverythingIcon)
	destroyIcon(Environment.NotorietyItemESPIcon)
	destroyIcon(Environment.NotorietyMenuIcon)

	Environment.NotorietyWeaponIcon = nil
	Environment.MaxEverythingIcon = nil
	Environment.NotorietyItemESPIcon = nil
	Environment.NotorietyMenuIcon = nil
	Environment.NotorietyItemESPController = nil
	Environment.NotorietyGetAmmoWrappers = setmetatable({}, {
		__mode = "k",
	})

	table.clear(WeaponState.RuntimeWeapons)
end

Environment.UnloadNotoriety = unloadNotoriety

trackWeaponContainer(Weapons)
trackWeaponContainer(Backpack)
trackWeaponContainer(LocalPlayer.Character)
bindTopbarCharacter(LocalPlayer.Character)

table.insert(
	Environment.NotorietyTopbarConnections,
	Backpack.ChildAdded:Connect(onBackpackToolChanged)
)
table.insert(
	Environment.NotorietyTopbarConnections,
	Backpack.ChildRemoved:Connect(onBackpackToolChanged)
)

rebuildTopbarIcons(true)
setWeaponModificationsEnabled(Environment.NotorietyWeaponEnabled)

Environment.MaxEverythingConnection = RunService.Heartbeat:Connect(function(DeltaTime)
	if Environment.NotorietyUnloaded then
		return
	end

	Apply()
	Environment.NotorietyTopbarRefresh += DeltaTime

	if Environment.NotorietyTopbarRefresh >= 0.25 then
		Environment.NotorietyTopbarRefresh = 0
		rebuildTopbarIcons(false)
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

	bindTopbarCharacter(Character)
	scheduleTopbarRepair()
	task.wait(1)

	if Environment.NotorietyUnloaded then
		return
	end

	Apply()
	trackWeaponContainer(Character)
	scheduleTopbarRepair()

	if Environment.NotorietyWeaponEnabled then
		applyAllWeaponModifications()
	end
end)

Apply()
