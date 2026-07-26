local Environment = if type(getgenv) == "function" then getgenv() else _G

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

Environment.MaxEverythingEnabled = true
Environment.KillPoliceRunning = false
Environment.NotorietyWeaponEnabled = true
Environment.NotorietyWeaponConnections = {}
Environment.NotorietyTopbarConnections = {}
Environment.NotorietyTopbarCharacterConnections = {}
Environment.NotorietyTopbarRepairToken = 0
Environment.NotorietyTopbarRebuilding = false
Environment.NotorietyTopbarRefresh = 0

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
	Crit = 100,
	Dodge = 100,
	Detection = 0,
}

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
	RuntimeAmmoTables = setmetatable({}, {
		__mode = "k",
	}),
	RuntimeAmmoUpvalues = setmetatable({}, {
		__mode = "k",
	}),
	RuntimeWeapons = setmetatable({}, {
		__mode = "k",
	}),
	RuntimeRefresh = 0,
	AmmoKeys = {
		ammo = true,
		ammo2 = true,
		ammoleft = true,
		ammoleft2 = true,
		ammoinmag = true,
		ammoinmag2 = true,
		currentammo = true,
		currentammo2 = true,
		curammo = true,
		curammo2 = true,
		magammo = true,
		magammo2 = true,
		magazine = true,
		magazine2 = true,
		magazineammo = true,
		magazineammo2 = true,
		clip = true,
		clip2 = true,
		currentclip = true,
		currentclip2 = true,
		primaryammo = true,
		secondaryammo = true,
		ammocapacity = true,
		spare = true,
	},
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

local function normalizeAmmoKey(Key)
	if type(Key) ~= "string" then
		return nil
	end

	return string.lower(Key):gsub("[^%w]", "")
end

local function isRuntimeAmmoKey(Key)
	local Normalized = normalizeAmmoKey(Key)

	return Normalized ~= nil and WeaponState.AmmoKeys[Normalized] == true
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

local function patchAmmoResult(Result)
	if not Environment.NotorietyWeaponEnabled or type(Result) ~= "table" then
		return Result
	end

	for Key, Value in Result do
		if type(Value) == "number" and isRuntimeAmmoKey(Key) then
			Result[Key] = MAX_VALUE
		elseif typeof(Value) == "Instance" and Value:IsA("ValueBase") and isRuntimeAmmoKey(Key) then
			if typeof(Value.Value) == "number" then
				Value.Value = MAX_VALUE
			end
		end
	end

	return Result
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

	WeaponState.RuntimeWeapons[State] = true
	applyWeaponData(Data)

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

	if type(Environment.NotorietyGetAmmoWrappers) ~= "table" then
		Environment.NotorietyGetAmmoWrappers = setmetatable({}, {
			__mode = "k",
		})
	end

	local Record = Environment.NotorietyGetAmmoWrappers[State]

	if not Record or State.getAmmo ~= Record.Wrapper then
		local Original = State.getAmmo
		local Wrapper

		Wrapper = function(...)
			local Result = Original(...)

			return patchAmmoResult(Result)
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
		patchAmmoResult(Result)
	end

	return true
end

local function patchRuntimeAmmoTable(Data)
	if not Environment.NotorietyWeaponEnabled or type(Data) ~= "table" then
		return false
	end

	local Found = false

	for Key, Value in Data do
		if type(Value) == "number" and isRuntimeAmmoKey(Key) then
			Data[Key] = MAX_VALUE
			Found = true
		end
	end

	if Found then
		WeaponState.RuntimeAmmoTables[Data] = true
	end

	return Found
end

local function registerRuntimeAmmoUpvalue(Function, Index)
	local Indices = WeaponState.RuntimeAmmoUpvalues[Function]

	if not Indices then
		Indices = {}
		WeaponState.RuntimeAmmoUpvalues[Function] = Indices
	end

	Indices[Index] = true

	if type(debug) == "table" and type(debug.setupvalue) == "function" then
		pcall(debug.setupvalue, Function, Index, MAX_VALUE)
	end
end

local function refreshRuntimeAmmo()
	if not Environment.NotorietyWeaponEnabled then
		return
	end

	for Data in WeaponState.RuntimeAmmoTables do
		patchRuntimeAmmoTable(Data)
	end

	for State in WeaponState.RuntimeWeapons do
		patchRuntimeWeaponState(State)
	end

	if type(debug) == "table" and type(debug.setupvalue) == "function" then
		for Function, Indices in WeaponState.RuntimeAmmoUpvalues do
			for Index in Indices do
				pcall(debug.setupvalue, Function, Index, MAX_VALUE)
			end
		end
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

		Data.MagazineSize = MAX_VALUE
		Data.AmmoMax = MAX_VALUE

		if Data.Dual == true then
			Data.AmmoSeparate = false
			Data.AmmoSwitch = false
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

			local Name
			local Value

			if type(First) == "string" and Second ~= nil then
				Name = First
				Value = Second
			elseif Second ~= nil then
				Value = Second
			else
				Value = First
			end

			if Name and type(Value) == "number" and isRuntimeAmmoKey(Name) then
				registerRuntimeAmmoUpvalue(Function, Index)
				Value = MAX_VALUE
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
		if Nodes >= NodeLimit or Depth > 8 then
			return
		end

		local ValueType = type(Value)

		if ValueType ~= "table" and ValueType ~= "function" then
			return
		end

		if Seen[Value] then
			return
		end

		Seen[Value] = true
		Nodes += 1

		if ValueType == "table" then
			if applyWeaponData(Value) then
				Patched += 1
			end

			patchRuntimeAmmoTable(Value)
			patchRuntimeWeaponState(Value)

			for Key, Item in Value do
				if type(Key) == "table" or type(Key) == "function" then
					Scan(Key, Depth + 1)
				end

				Scan(Item, Depth + 1)

				if Nodes >= NodeLimit then
					break
				end
			end
		else
			local Upvalues = getFunctionUpvalues(Value)

			if type(Upvalues) == "table" then
				for _, Item in Upvalues do
					Scan(Item, Depth + 1)

					if Nodes >= NodeLimit then
						break
					end
				end
			end
		end
	end

	for _, Value in ScriptEnvironment do
		Scan(Value, 0)

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
	if not Container then
		return
	end

	for _, Object in Container:GetDescendants() do
		applyWeaponModule(Object)
	end

	table.insert(
		Environment.NotorietyWeaponConnections,
		Container.DescendantAdded:Connect(function(Object)
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
		:bindToggleKey(Enum.KeyCode.P)
		:bindEvent("selected", function()
			task.spawn(runKill)
		end)
		:oneClick()

	Environment.MaxEverythingIcon = CurrentIcon
end

local function createWeaponModsIcon()
	local CurrentIcon = Icon.new()
		:setName("Weapon Mods")
		:setLabel(
			Environment.NotorietyWeaponEnabled and "Weapon Mods: ON" or "Weapon Mods: OFF"
		)
		:setRight()
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
end

local function rebuildTopbarIcons(Force)
	local RebuildKill = Force == true or not isIconAlive(Environment.MaxEverythingIcon)
	local RebuildWeapon = Force == true or not isIconAlive(Environment.NotorietyWeaponIcon)

	if not RebuildKill and not RebuildWeapon then
		return
	end

	local WeaponEnabled = Environment.NotorietyWeaponEnabled
	Environment.NotorietyTopbarRebuilding = true

	if RebuildKill then
		destroyIcon(Environment.MaxEverythingIcon)
		Environment.MaxEverythingIcon = nil
		createKillPoliceIcon()
	end

	if RebuildWeapon then
		destroyIcon(Environment.NotorietyWeaponIcon)
		Environment.NotorietyWeaponIcon = nil
		createWeaponModsIcon()
	end

	Environment.NotorietyTopbarRebuilding = false

	local CurrentIcon = Environment.NotorietyWeaponIcon

	if CurrentIcon then
		pcall(function()
			CurrentIcon:setLabel(WeaponEnabled and "Weapon Mods: ON" or "Weapon Mods: OFF")
		end)
	end
end

local function scheduleTopbarRepair()
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
	bindTopbarCharacter(Character)
	scheduleTopbarRepair()
	task.wait(1)
	Apply()
	trackWeaponContainer(Character)
	scheduleTopbarRepair()

	if Environment.NotorietyWeaponEnabled then
		applyAllWeaponModifications()
	end
end)

Apply()
