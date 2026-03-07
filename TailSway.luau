local __lt = { cr = type(cloneref) == "function" and cloneref or nil };
function __lt.cv(value)
	if __lt.cr and typeof(value) == "Instance" then
		local ok, cloned = pcall(__lt.cr, value);
		if ok and cloned ~= nil then
			return cloned;
		end;
	end;
	return value;
end;
function __lt.cs(name, refFn)
	if type(refFn) ~= "function" then
		return game:GetService(name);
	end;
	local ok, ref = pcall(function()
		return refFn(game:GetService(name));
	end);
	if ok and ref ~= nil then
		return ref;
	end;
	return game:GetService(name);
end;
function __lt.ig(method)
	return method == "FindFirstChild"
		or method == "WaitForChild"
		or method == "FindFirstChildOfClass"
		or method == "FindFirstChildWhichIsA"
		or method == "FindFirstAncestor"
		or method == "FindFirstAncestorOfClass"
		or method == "FindFirstAncestorWhichIsA"
		or method == "GetChildren"
		or method == "GetDescendants"
		or method == "QueryDescendants";
end;
function __lt.cm(name, method, ...)
	local service = __lt.ig(method)
		and __lt.cs(name, __lt.cr)
		or game:GetService(name);
	local fn = service[method];
	if type(fn) ~= "function" then
		error(string.format("Service method %s.%s is not callable", tostring(name), tostring(method)));
	end;
	return fn(service, ...);
end;


local env = (getgenv and getgenv()) or _G
env.__TailAnim = env.__TailAnim or {}
local TA = env.__TailAnim

TA.Enabled   = (TA.Enabled ~= false)
TA.Speed     = TA.Speed or 1.5
TA.Amplitude = TA.Amplitude or 25

for _, k in ipairs({ "_conn", "_charConn", "_childConn" }) do
	if TA[k] then
		TA[k]:Disconnect()
		TA[k] = nil
	end
end

local Players = __lt.cs("Players", cloneref)
local RunService = __lt.cs("RunService", cloneref)
local lp = Players.LocalPlayer

local function isTailAccessory(acc)
	if not acc or not acc:IsA("Accessory") then
		return false
	end

	local name = string.lower(acc.Name or "")
	if string.find(name, "tail", 1, true) then
		return true
	end

	if acc.AccessoryType ~= Enum.AccessoryType.Waist then
		return false
	end

	local handle = acc:FindFirstChild("Handle")
	if not handle then
		return false
	end

	local mesh = handle:FindFirstChildWhichIsA("SpecialMesh") or handle:FindFirstChildWhichIsA("Mesh")
	if not mesh then
		return false
	end

	local meshName = string.lower(mesh.Name or "")
	local meshId = string.lower(tostring(mesh.MeshId or ""))

	return (string.find(meshName, "tail", 1, true) ~= nil)
		or (string.find(meshId, "tail", 1, true) ~= nil)
end

local function getMotorFromAccessory(acc)
	local handle = acc:FindFirstChild("Handle")
	if not handle then
		return nil
	end
	return handle:FindFirstChildWhichIsA("Motor6D") or handle:FindFirstChild("AccessoryWeld")
end

local function findTailMotor(character)
	for _, child in ipairs(character:GetChildren()) do
		if isTailAccessory(child) then
			local m = getMotorFromAccessory(child)
			if m then
				return m
			end
		end
	end
	return nil
end

local motor, baseC0
local t = 0
local currentYaw = 0

local function bindCharacter(character)
	motor = findTailMotor(character)
	baseC0 = motor and motor.C0 or nil
	t = 0
	currentYaw = 0

	if TA._childConn then
		TA._childConn:Disconnect()
		TA._childConn = nil
	end

	TA._childConn = character.ChildAdded:Connect(function(child)
		if motor then return end
		if not isTailAccessory(child) then return end
		local m = getMotorFromAccessory(child)
		if m then
			motor = m
			baseC0 = m.C0
			t = 0
			currentYaw = 0
		end
	end)
end

if lp.Character then
	bindCharacter(lp.Character)
end

TA._charConn = lp.CharacterAdded:Connect(function(character)
	bindCharacter(character)
end)

function TA:SetEnabled(v)   self.Enabled = not not v end
function TA:SetSpeed(v)     self.Speed = tonumber(v) or self.Speed end
function TA:SetAmplitude(d) self.Amplitude = tonumber(d) or self.Amplitude end

TA._conn = RunService.RenderStepped:Connect(function(dt)
	if not motor or not motor.Parent then
		local character = lp.Character
		if not character then return end
		motor = findTailMotor(character)
		baseC0 = motor and motor.C0 or nil
		t = 0
		currentYaw = 0
		if not motor then return end
	end

	local targetYaw = 0
	if TA.Enabled and baseC0 then
		t += dt * TA.Speed
		targetYaw = math.sin(t) * math.rad(TA.Amplitude)
	end

	local smooth = 1 - math.exp(-dt * 18)
	currentYaw += (targetYaw - currentYaw) * smooth

	motor.C0 = baseC0 * CFrame.Angles(0, currentYaw, 0)
end)