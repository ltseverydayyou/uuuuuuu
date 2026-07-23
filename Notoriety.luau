local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Environment = getgenv()

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

	if Environment.MaxEverythingIcon then
		Environment.MaxEverythingIcon:setLabel("Killing....")
	end

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

	if Environment.MaxEverythingIcon then
		Environment.MaxEverythingIcon:setLabel("Kill Police")
	end

	if not Success then
		warn(Error)
	end
end

Environment.MaxEverythingIcon = Icon.new()
	:setName("Kill Police")
	:setLabel("Kill Police")
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