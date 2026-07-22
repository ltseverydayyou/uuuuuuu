local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Environment = getgenv()

if Environment.MaxEverythingConnection then
	Environment.MaxEverythingConnection:Disconnect()
end

if Environment.MaxEverythingCharacterConnection then
	Environment.MaxEverythingCharacterConnection:Disconnect()
end

Environment.MaxEverythingEnabled = true

local MAX_VALUE = 999999

local MaxedValues = {
	Health = MAX_VALUE,
	Armor = MAX_VALUE,
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
}

local ValueSelector = table.concat({
	"#Health",
	"#Armor",
	"#Stamina",
	"#MaxStamina",
	"#PrimaryAmmo",
	"#PrimaryAmmoMax",
	"#SecondaryAmmo",
	"#SecondaryAmmoMax",
	"#GadgetAmmo",
	"#GadgetAmmoMax",
	"#CableTies",
	"#BodyBags",
	"#Throwables",
	"#EquipmentLeft",
	"#SecondEquipmentLeft",
	"#Messiah",
	"#Crit",
	"#Dodge",
	"#Detection",
	"#Capacity",
	"#AltAmmoMax",
}, ", ")

local function Apply()
	if not Environment.MaxEverythingEnabled then
		return
	end

	local Character = LocalPlayer.Character

	if not Character then
		return
	end

	for _, Object in ipairs(Character:QueryDescendants(ValueSelector)) do
		if Object:IsA("ValueBase") then
			local Value = MaxedValues[Object.Name]

			if Object.Name == "Capacity" or Object.Name == "AltAmmoMax" then
				Value = MAX_VALUE
			end

			if Value ~= nil and Object.Value ~= Value then
				Object.Value = Value
			end
		end
	end
end

Environment.MaxEverythingConnection = RunService.Heartbeat:Connect(Apply)

Environment.MaxEverythingCharacterConnection = LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	Apply()
end)

Apply()