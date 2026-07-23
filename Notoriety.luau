local Environment = getgenv and getgenv() or _G

local ServiceResolver = rawget(Environment, "__lt_service_resolver")

if type(ServiceResolver) ~= "table" then
	local Loader = loadstring or load

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

local Reference = type(cloneref) == "function" and cloneref or function(Value)
	return Value
end

local ReplicatedStorage = ServiceResolver.cs("ReplicatedStorage", Reference)
local Workspace = ServiceResolver.cs("Workspace", Reference)
local Players = ServiceResolver.cs("Players", Reference)
local RunService = ServiceResolver.cs("RunService", Reference)

local LocalPlayer = Players.LocalPlayer

local RS_Package = ReplicatedStorage:WaitForChild("RS_Package")
local Assets = RS_Package:WaitForChild("Assets")
local Remotes = Assets:WaitForChild("Remotes")
local Event = Remotes:WaitForChild("Damage")

local Icon = loadstring(
	game:HttpGet(
		"https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Icon.luau"
	)
)()

if Environment.MaxEverythingConnection then
	Environment.MaxEverythingConnection:Disconnect()
	Environment.MaxEverythingConnection = nil
end

if Environment.MaxEverythingCharacterConnection then
	Environment.MaxEverythingCharacterConnection:Disconnect()
	Environment.MaxEverythingCharacterConnection = nil
end

if Environment.MaxEverythingIcon then
	pcall(function()
		Environment.MaxEverythingIcon:destroy()
	end)

	Environment.MaxEverythingIcon = nil
end

Environment.MaxEverythingEnabled = true
Environment.KillPoliceRunning = false

local MAX_VALUE = 999999

local MaxedValues = {
	Stamina = MAX_VALUE,
	MaxStamina = MAX_VALUE,
	PrimaryAmmo = MAX_VALUE,
	PrimaryAmmoMax = MAX_VALUE,
	SecondaryAmmo = MAX_VALUE,
	SecondaryAmmoMax = MAX_VALUE,
	GadgetAmmo = MAX_VALUE,
	GadgetAmmoMax = MAX_VALUE,
	CableTies = MAX_VALUE,
	BodyBags = MAX_VALUE,
	Throwables = MAX_VALUE,
	EquipmentLeft = MAX_VALUE,
	SecondEquipmentLeft = MAX_VALUE,
	Messiah = MAX_VALUE,
	Crit = 100,
	Dodge = 100,
	Detection = 0,
	Capacity = MAX_VALUE,
	AltAmmoMax = MAX_VALUE,
}

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
		if Object:IsA("ValueBase") then
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

Environment.MaxEverythingIcon = Icon.new()
	:setName("Kill Police")
	:setLabel("Kill Police [P]")
	:setMid()
	:bindToggleKey(Enum.KeyCode.P)
	:bindEvent("selected", function()
		task.spawn(runKill)
	end)
	:oneClick()

Environment.MaxEverythingConnection = RunService.Heartbeat:Connect(Apply)

Environment.MaxEverythingCharacterConnection = LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	Apply()
end)

Apply()