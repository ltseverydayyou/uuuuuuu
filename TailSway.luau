local __lt = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {};
	local sharedEnv = rawget(_G, "shared");
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil);
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver");
		if type(cached) == "table" then
			return cached;
		end;
	end;
	local loader = loadstring or load;
	if type(loader) ~= "function" then
		error("Service resolver loader unavailable");
	end;
	local resolver = loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau");
	if type(resolver) ~= "function" then
		error("Service resolver failed to compile");
	end;
	local loaded = resolver();
	if type(loaded) ~= "table" then
		error("Service resolver failed to load");
	end;
	if cacheHost then
		cacheHost.__lt_service_resolver = loaded;
	end;
	return loaded;
end)();

local env = (getgenv and getgenv()) or _G
env.__TailAnim = env.__TailAnim or {}
local TA = env.__TailAnim

if TA._restore then
	pcall(TA._restore)
end

for _, k in { "_conn", "_charConn", "_childConn" } do
	if TA[k] then
		TA[k]:Disconnect()
		TA[k] = nil
	end
end

if TA._method ~= "TuxPhysicsTails-3.1.2" then
	TA.Enabled = true
	TA.Speed = 0.85
	TA.Amplitude = 25
	TA._method = "TuxPhysicsTails-3.1.2"
else
	TA.Enabled = TA.Enabled ~= false
	TA.Speed = tonumber(TA.Speed) or 0.85
	TA.Amplitude = tonumber(TA.Amplitude) or 25
end

local Players = __lt.cs("Players", cloneref)
local RunService = __lt.cs("RunService", cloneref)
local lp = Players.LocalPlayer

local STIFFNESS = 248
local DAMPING = 12
local LINEAR_AMPLITUDE = Vector3.new(28, 9, 28)
local ANGULAR_AMPLITUDE = Vector3.new(0, 8, 0)
local WAG_DROP_AMPLITUDE = 0.2
local WAG_SWAY_AMPLITUDE = 0.4
local WAG_ROLL_AMPLITUDE = 0.5
local WAG_BLEND_IN_ALPHA = 0.008
local WAG_BLEND_OUT_ALPHA = 0.02
local MOVEMENT_DISTANCE_THRESHOLD = 15
local FIXED_STEP = 1 / 120

local function isTailAccessory(acc)
	if not acc or not acc:IsA("Accessory") then
		return false
	end

	local name = string.lower(acc.Name or "")
	if string.find(name, "tail", 1, true) then
		return true
	end

	if acc.AccessoryType ~= Enum.AccessoryType.Waist and acc.AccessoryType ~= Enum.AccessoryType.Back then
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

	return string.find(meshName, "tail", 1, true) ~= nil
		or string.find(meshId, "tail", 1, true) ~= nil
end

local function getJointFromAccessory(acc)
	local handle = acc:FindFirstChild("Handle")
	if not handle then
		return nil, nil
	end

	return handle:FindFirstChild("AccessoryWeld") or handle:FindFirstChildWhichIsA("Motor6D"), handle
end

local function findTailJoint(character)
	for _, child in character:GetChildren() do
		if isTailAccessory(child) then
			local joint, handle = getJointFromAccessory(child)
			if joint then
				return joint, handle
			end
		end
	end
	return nil, nil
end

local function getPivotOffset(root)
	local waistRig = root:FindFirstChild("WaistRigAttachment")
	if waistRig and waistRig:IsA("Attachment") then
		return waistRig.CFrame * CFrame.new(0, 0, root.Size.Z * 0.5)
	end

	local waistBack = root:FindFirstChild("WaistBackAttachment")
	if waistBack and waistBack:IsA("Attachment") then
		return waistBack.CFrame * CFrame.new(0, 0.3, 0)
	end

	return nil
end

local function getAttachmentBasedC0(root, handle)
	for _, child in handle:GetChildren() do
		if child:IsA("Attachment") then
			local rootAttachment = root:FindFirstChild(child.Name)
			if rootAttachment and rootAttachment:IsA("Attachment") then
				return rootAttachment.CFrame * child.CFrame:Inverse()
			end
		end
	end
	return nil
end

local function getWagSeed(character)
	local sum = 0
	local name = character.Name
	for i = 1, #name do
		local b = string.byte(name, i)
		sum += b * b
	end
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		sum += player.UserId
	end
	return sum
end

local state
local wagTime = 0
local accumulator = 0
local wasEnabled = TA.Enabled

local function restoreState()
	if not state then
		return
	end

	local joint = state.joint
	if joint and joint.Parent then
		pcall(function()
			joint.Part0 = state.savedPart0
			joint.Part1 = state.savedPart1
			joint.C0 = state.savedC0
			joint.C1 = state.savedC1
		end)
	end

	state = nil
end

TA._restore = restoreState

local function setupState(character, joint, handle)
	restoreState()

	if not character or not joint or not handle then
		return false
	end

	local savedPart0 = joint.Part0
	local savedPart1 = joint.Part1
	local savedC0 = joint.C0
	local savedC1 = joint.C1
	local root = savedPart0
	local reversed = false

	if root == handle then
		root = savedPart1
		reversed = true
	end

	if not root or not root:IsA("BasePart") then
		return false
	end

	local pivotOffset = getPivotOffset(root)
	if not pivotOffset then
		return false
	end

	local originalC0 = getAttachmentBasedC0(root, handle)
	if not originalC0 then
		if reversed then
			originalC0 = savedC1 * savedC0:Inverse()
		else
			originalC0 = savedC0 * savedC1:Inverse()
		end
	end

	if reversed then
		joint.Part0 = root
		joint.Part1 = handle
	end

	joint.C0 = originalC0
	joint.C1 = CFrame.identity

	local pivotDelta = originalC0:ToObjectSpace(CFrame.new(pivotOffset.Position))
	local scale = character:GetScale()

	state = {
		character = character,
		root = root,
		joint = joint,
		handle = handle,
		savedPart0 = savedPart0,
		savedPart1 = savedPart1,
		savedC0 = savedC0,
		savedC1 = savedC1,
		inverseCharacterScale = 1 / scale,
		rootPreviousCFrame = root.CFrame,
		rootPreviousDeltaCFrame = CFrame.identity,
		weldOriginalCFrame = originalC0,
		weldPreviousCFrame = originalC0,
		weldCurrentCFrame = originalC0,
		currentAngle = Vector3.zero,
		angularVelocity = Vector3.zero,
		wagAnimationBlendAlpha = 0,
		wagSeed = getWagSeed(character),
		pivotCFrame = originalC0 * pivotDelta,
		inversePivotOffsetCFrame = pivotDelta:Inverse(),
	}

	wagTime = 0
	accumulator = 0
	return true
end

local function bindCharacter(character)
	local joint, handle = findTailJoint(character)
	if joint then
		setupState(character, joint, handle)
	else
		restoreState()
	end

	if TA._childConn then
		TA._childConn:Disconnect()
		TA._childConn = nil
	end

	TA._childConn = character.ChildAdded:Connect(function(child)
		if state and state.joint and state.joint.Parent then
			return
		end
		if not isTailAccessory(child) then
			return
		end
		local newJoint, newHandle = getJointFromAccessory(child)
		if newJoint then
			setupState(character, newJoint, newHandle)
		end
	end)
end

local function getTailAnimationOffset(s)
	local blendAlpha = s.wagAnimationBlendAlpha

	if s.angularVelocity.Magnitude > 0.3 then
		if blendAlpha < 0.01 then
			blendAlpha = 0
		else
			blendAlpha *= 1 - WAG_BLEND_OUT_ALPHA
		end
	elseif blendAlpha > 0.99 then
		blendAlpha = 1
	else
		blendAlpha += (1 - blendAlpha) * WAG_BLEND_IN_ALPHA
	end

	s.wagAnimationBlendAlpha = blendAlpha

	if blendAlpha <= 0 then
		return Vector3.zero
	end

	local phase = wagTime + s.wagSeed
	local modifiedPhase = phase + math.sin(phase) * math.sin(phase * 0.22727272727272727) * 0.9
	local amplitudeScale = math.max(0, (tonumber(TA.Amplitude) or 25) / 25)

	return Vector3.new(
		(math.sin(modifiedPhase * 2) + 0.8) * WAG_DROP_AMPLITUDE * blendAlpha * amplitudeScale,
		math.cos(modifiedPhase) * WAG_SWAY_AMPLITUDE * blendAlpha * amplitudeScale,
		math.sin(modifiedPhase) * -WAG_ROLL_AMPLITUDE * blendAlpha * amplitudeScale
	)
end

local function applyRenderedCFrame(s, weldCFrame)
	local wagOffset = getTailAnimationOffset(s)
	local wagTarget = s.pivotCFrame
		* CFrame.fromEulerAnglesXYZ(wagOffset.X, wagOffset.Y, wagOffset.Z)
		* s.inversePivotOffsetCFrame

	weldCFrame = weldCFrame * weldCFrame:ToObjectSpace(wagTarget):Inverse()

	local characterScale = s.inverseCharacterScale * s.character:GetScale()
	s.joint.C0 = weldCFrame.Rotation + weldCFrame.Position * characterScale
end

local function updatePhysicsTail(s, renderThisStep, interpolationAlpha)
	local rootCFrame = s.root.CFrame
	local rootDeltaCFrame = s.rootPreviousCFrame:ToObjectSpace(rootCFrame)

	if rootDeltaCFrame.Position.Magnitude > MOVEMENT_DISTANCE_THRESHOLD then
		rootDeltaCFrame = rootDeltaCFrame.Rotation
	end

	local accelerationCFrame = s.rootPreviousDeltaCFrame:ToObjectSpace(rootDeltaCFrame)
	local linearForce = accelerationCFrame.Position * LINEAR_AMPLITUDE
	local torque = (s.pivotCFrame.Position - s.weldPreviousCFrame.Position):Cross(linearForce)
	local rx, ry, rz = accelerationCFrame:ToEulerAnglesXYZ()
	local angularForce = Vector3.new(rx, ry, rz) * ANGULAR_AMPLITUDE
	local currentAngle = s.currentAngle
	local angularVelocity = s.angularVelocity
	local nextAngularVelocity = angularVelocity - (STIFFNESS * currentAngle + DAMPING * angularVelocity) * FIXED_STEP
	local nextAngle = currentAngle + nextAngularVelocity * FIXED_STEP
	local characterScale = s.inverseCharacterScale * s.character:GetScale()

	s.currentAngle = nextAngle
	s.angularVelocity = nextAngularVelocity + torque / characterScale - angularForce

	local nextWeldCFrame = s.pivotCFrame
		* CFrame.fromEulerAnglesXYZ(nextAngle.X, nextAngle.Y, nextAngle.Z)
		* s.inversePivotOffsetCFrame
	local weldCurrentCFrame = s.weldCurrentCFrame

	if renderThisStep then
		applyRenderedCFrame(s, weldCurrentCFrame:Lerp(nextWeldCFrame, interpolationAlpha))
	end

	s.rootPreviousCFrame = rootCFrame
	s.rootPreviousDeltaCFrame = rootDeltaCFrame
	s.weldPreviousCFrame = weldCurrentCFrame
	s.weldCurrentCFrame = nextWeldCFrame
end

local function updateInterpolation(s, alpha)
	applyRenderedCFrame(s, s.weldPreviousCFrame:Lerp(s.weldCurrentCFrame, alpha))
end

if lp.Character then
	bindCharacter(lp.Character)
end

TA._charConn = lp.CharacterAdded:Connect(bindCharacter)

function TA:SetEnabled(v)
	self.Enabled = not not v
end

function TA:SetSpeed(v)
	self.Speed = math.max(0, tonumber(v) or self.Speed)
end

function TA:SetAmplitude(v)
	self.Amplitude = math.max(0, tonumber(v) or self.Amplitude)
end

TA._conn = RunService.RenderStepped:Connect(function(dt)
	local character = lp.Character
	if not character then
		return
	end

	if not state or not state.joint or not state.joint.Parent or state.character ~= character then
		local joint, handle = findTailJoint(character)
		if not joint or not setupState(character, joint, handle) then
			return
		end
	end

	if TA.Enabled ~= wasEnabled then
		wasEnabled = TA.Enabled
		if TA.Enabled then
			local joint, handle = findTailJoint(character)
			if joint then
				setupState(character, joint, handle)
			end
		else
			local s = state
			if s and s.joint and s.joint.Parent then
				local scale = s.inverseCharacterScale * s.character:GetScale()
				s.joint.C0 = s.weldOriginalCFrame.Rotation + s.weldOriginalCFrame.Position * scale
			end
		end
	end

	if not TA.Enabled or not state then
		return
	end

	local frameDelta = math.min(dt, 0.1)
	wagTime += frameDelta * (tonumber(TA.Speed) or 0.85)
	accumulator += frameDelta

	local steps = math.floor(accumulator / FIXED_STEP)
	if steps <= 0 then
		updateInterpolation(state, accumulator / FIXED_STEP)
		return
	end

	accumulator -= steps * FIXED_STEP
	local interpolationAlpha = accumulator / FIXED_STEP

	for i = 1, steps do
		updatePhysicsTail(state, i == steps, interpolationAlpha)
	end
end)
