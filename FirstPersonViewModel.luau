-- This script was too easy to deobfuscate and it's shit.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local InsertService = game:GetService("InsertService")

local R6_FALLBACK_ASSET = "rbxassetid://137532430198493"
local R6_INSERT_ASSET_ID = 137532430198493

local R15_FALLBACK_ASSET = "rbxassetid://125567515196521"
local R15_INSERT_ASSET_ID = 125567386714117

local FIRST_PERSON_DISTANCE = 1.5
local VIEWMODEL_SPIN_SPEED = 0
local ORBIT_VIEWMODEL = false

local MOVE_THRESHOLD = 0.75
local SPRINT_SPEED_BONUS = 10
local ANIMATION_BLEND_TIME = 0.25

local IDLE_BOB_FREQUENCY = 2.4
local IDLE_BOB_AMOUNT = 0.039

local MOVE_BOB_FREQUENCY = 1.7
local MOVE_BOB_AMOUNT = 0.03

local STRAFE_ROLL_AMOUNT = 0.12
local CAMERA_YAW_ROLL_SCALE = 0.09
local MAX_CAMERA_YAW_ROLL = 0.1

local FOOTSTEP_SOUND_ID = "rbxassetid://134766660977018"
local FOOTSTEP_VOLUME = 0.5
local FOOTSTEP_ECHO_VOLUME = 0.15
local FOOTSTEP_ECHO_PLAYBACK_SPEED = 0.7
local FOOTSTEP_ECHO_DELAY = 0.12
local WALK_STEP_INTERVAL = 0.5
local RUN_STEP_BASE_INTERVAL = 0.5
local FOOTSTEP_MIN_PLAYBACK_SPEED = 0.85
local FOOTSTEP_MAX_PLAYBACK_SPEED = 1.25

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local CharacterRoot = Character:WaitForChild("HumanoidRootPart")

local ViewModel = nil
local ViewRoot = nil
local ViewHead = nil
local ViewParts = {}
local ViewOffset = CFrame.new()

local Motors = {}
local Animations = {
	idle = nil,
	walk = nil,
	run = nil,
}

local AnimationTime = 0
local ActiveAnimation = nil
local TransitionAnimation = nil
local TransitionStartTransforms = nil
local TransitionElapsed = 0

local ShiftHeld = false
local BaseWalkSpeed = nil
local SprintApplied = false
local RigType = nil

local CameraRoll = 0
local CameraRollTarget = 0
local MoveBobPhase = 0
local MoveBobOffset = 0
local SmoothedStrafe = 0
local SmoothedVelocity = Vector3.new(0, 0, 0)
local PreviousRightDot = 0
local PreviousCameraYaw = 0
local CameraYawVelocity = 0
local IdleBobPhase = 0
local FootstepTimer = 0

local FootstepSound = nil
local FootstepEcho = nil

local function scanViewModelParts()
	table.clear(ViewParts)
	ViewRoot = nil
	ViewHead = nil

	if ViewModel:IsA("BasePart") then
		table.insert(ViewParts, ViewModel)
	end

	for _, descendant in ipairs(ViewModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(ViewParts, descendant)

			if descendant.Name == "HumanoidRootPart" then
				ViewRoot = descendant
			elseif descendant.Name == "Head" then
				ViewHead = descendant
			end
		end
	end
end

local function configureViewModelPhysics()
	local anchorPart = ViewRoot
		or (ViewModel:IsA("BasePart") and ViewModel)
		or ViewModel.PrimaryPart

	for _, part in ipairs(ViewParts) do
		part.Anchored = part == anchorPart
		part.CanCollide = false

		pcall(function()
			part.CanQuery = false
			part.CanTouch = false
		end)
	end
end

local function loadViewModel(fallbackAsset, insertAssetId)
	if ViewModel then
		ViewModel:Destroy()
		ViewModel = nil
	end

	Motors = {}
	Animations = {
		idle = nil,
		walk = nil,
		run = nil,
	}

	ActiveAnimation = nil
	TransitionAnimation = nil
	TransitionStartTransforms = nil
	TransitionElapsed = 0
	AnimationTime = 0

	local insertSuccess, loadedAsset = pcall(function()
		return InsertService:LoadAsset(insertAssetId)
	end)

	if insertSuccess and loadedAsset then
		for _, child in ipairs(loadedAsset:GetChildren()) do
			if child:IsA("Model")
				or child:IsA("BasePart")
				or child:IsA("Accoutrement")
			then
				ViewModel = child
				break
			end
		end

		if not ViewModel and loadedAsset:IsA("Model") then
			ViewModel = loadedAsset
		else
			-- This is what the original script does. If ViewModel is a child
			-- of loadedAsset, destroying loadedAsset can also destroy that child.
			loadedAsset:Destroy()
		end
	end

	if not ViewModel then
		local success, objects = pcall(function()
			return game:GetObjects(fallbackAsset)
		end)

		if success and type(objects) == "table" and #objects > 0 then
			ViewModel = objects[1]
		end
	end

	if not ViewModel then
		return
	end

	ViewModel.Parent = workspace

	local animateScript = ViewModel:FindFirstChild("Animate")
	if animateScript then
		animateScript:Destroy()
	end

	local animSaves = ViewModel:FindFirstChild("AnimSaves")
	if animSaves then
		animSaves.Parent = nil
	end

	local sourceHumanoid = Character:FindFirstChildOfClass("Humanoid")
	if sourceHumanoid then
		local viewHumanoid = ViewModel:FindFirstChildOfClass("Humanoid")

		if not viewHumanoid then
			viewHumanoid = Instance.new("Humanoid")
			viewHumanoid.RigType = RigType or Enum.HumanoidRigType.R15
			viewHumanoid.Parent = ViewModel
		end

		local descriptionSuccess, description = pcall(function()
			return sourceHumanoid:GetAppliedDescription()
		end)

		if descriptionSuccess and description then
			pcall(function()
				viewHumanoid:ApplyDescription(description)
			end)

			task.wait(0.5)
		end
	end

	if animSaves then
		animSaves.Parent = ViewModel
	end

	scanViewModelParts()
	configureViewModelPhysics()

	if ViewModel:IsA("Model") then
		if ViewRoot then
			ViewModel.PrimaryPart = ViewRoot
		else
			local firstPart = ViewModel:FindFirstChildOfClass("BasePart")
			if firstPart then
				ViewModel.PrimaryPart = firstPart
			end
		end
	end

	configureViewModelPhysics()
	scanViewModelParts()
	configureViewModelPhysics()
end

local function setObjectVisible(object, visible)
	if not object then
		return
	end

	local success = pcall(function()
		object.Visible = visible
	end)

	if not success then
		object.Transparency = visible and 0 or 1
	end
end

local function setViewModelVisible(visible)
	for _, part in ipairs(ViewParts) do
		if part == ViewRoot or part == ViewHead then
			setObjectVisible(part, false)
		else
			setObjectVisible(part, visible)
		end
	end
end

local function moveViewModel(cframe)
	if ViewModel:IsA("BasePart") then
		ViewModel.CFrame = cframe
	elseif ViewModel:IsA("Model") then
		pcall(function()
			ViewModel:PivotTo(cframe)
		end)
	end
end

local function isFirstPerson()
	local currentCharacter = LocalPlayer.Character
	local head = currentCharacter and currentCharacter:FindFirstChild("Head")
	local camera = workspace.CurrentCamera

	if not head or not camera then
		return false
	end

	return (camera.CFrame.Position - head.Position).Magnitude <= FIRST_PERSON_DISTANCE
end

local function collectMotors(model)
	local motors = {}

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Motor6D") then
			if descendant.Part1 then
				motors[descendant.Part1.Name] = descendant
			elseif descendant.Part0 then
				motors[descendant.Part0.Name] = descendant
			end
		end
	end

	return motors
end

local function collectPoses(parent, output)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Pose") then
			output[child.Name] = child
			collectPoses(child, output)
		end
	end
end

local function parseKeyframeSequence(sequence)
	local keyframes = {}

	for _, child in ipairs(sequence:GetChildren()) do
		if child:IsA("Keyframe") then
			local poses = {}
			collectPoses(child, poses)

			table.insert(keyframes, {
				time = child.Time,
				poses = poses,
			})
		end
	end

	table.sort(keyframes, function(a, b)
		return a.time < b.time
	end)

	local duration = #keyframes > 0 and keyframes[#keyframes].time or 0

	return {
		keyframes = keyframes,
		duration = duration,
	}
end

local function sampleAnimation(animation, timePosition)
	local result = {}
	local keyframes = animation.keyframes
	local count = #keyframes

	if count == 0 then
		return result
	end

	if count == 1 then
		for name, pose in pairs(keyframes[1].poses) do
			result[name] = pose.CFrame
		end

		return result
	end

	local currentKeyframe = nil
	local nextKeyframe = nil

	for index = 1, count do
		if keyframes[index].time <= timePosition then
			currentKeyframe = keyframes[index]
			nextKeyframe = keyframes[index + 1] or keyframes[1]
		end
	end

	if not currentKeyframe then
		currentKeyframe = keyframes[count]
		nextKeyframe = keyframes[1]
	end

	local segmentDuration = nextKeyframe.time - currentKeyframe.time
	if segmentDuration < 0 then
		segmentDuration += animation.duration
	end

	local alpha = 0

	if segmentDuration > 0 then
		local elapsed = timePosition - currentKeyframe.time

		if elapsed < 0 then
			elapsed += animation.duration
		end

		alpha = elapsed / segmentDuration
	end

	for name, pose in pairs(currentKeyframe.poses) do
		local nextPose = nextKeyframe.poses[name]

		if nextPose then
			result[name] = pose.CFrame:Lerp(nextPose.CFrame, alpha)
		else
			result[name] = pose.CFrame
		end
	end

	return result
end

local function applyAnimation(animation, motors, timePosition)
	local transforms = sampleAnimation(animation, timePosition)

	for name, transform in pairs(transforms) do
		local motor = motors[name]
		if motor then
			motor.Transform = transform
		end
	end

	for name, motor in pairs(motors) do
		if not transforms[name] then
			motor.Transform = CFrame.new()
		end
	end
end

local function resetMotorTransforms(motors)
	for _, motor in pairs(motors) do
		motor.Transform = CFrame.new()
	end
end

local function loadAnimations()
	if not ViewModel then
		return
	end

	Motors = collectMotors(ViewModel)

	local animSaves = ViewModel:FindFirstChild("AnimSaves")
	if not animSaves then
		return
	end

	local function loadSequence(name)
		local sequence = animSaves:FindFirstChild(name)

		if sequence and sequence:IsA("KeyframeSequence") then
			return parseKeyframeSequence(sequence)
		end

		return nil
	end

	Animations.idle = loadSequence("idle")
	Animations.walk = loadSequence("walk")
	Animations.run = loadSequence("run")
end

local function beginAnimationTransition(targetAnimation)
	if TransitionAnimation ~= nil then
		if targetAnimation == TransitionAnimation then
			return
		end

		if targetAnimation == ActiveAnimation then
			return
		end
	elseif targetAnimation == ActiveAnimation then
		return
	end

	local currentTransforms = {}

	for name, motor in pairs(Motors) do
		currentTransforms[name] = motor.Transform
	end

	TransitionStartTransforms = currentTransforms
	TransitionAnimation = targetAnimation
	TransitionElapsed = 0
	AnimationTime = 0
end

local function finishAnimationTransition()
	ActiveAnimation = TransitionAnimation
	TransitionAnimation = nil
	TransitionStartTransforms = nil
	TransitionElapsed = 0
end

local function createFootstepSounds(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	if root:FindFirstChild("LocalFootstepSound") then
		return
	end

	FootstepSound = Instance.new("Sound")
	FootstepSound.Name = "LocalFootstepSound"
	FootstepSound.SoundId = FOOTSTEP_SOUND_ID
	FootstepSound.Volume = FOOTSTEP_VOLUME
	FootstepSound.Parent = root

	FootstepEcho = Instance.new("Sound")
	FootstepEcho.Name = "LocalFootstepEcho"
	FootstepEcho.SoundId = FOOTSTEP_SOUND_ID
	FootstepEcho.Volume = FOOTSTEP_ECHO_VOLUME
	FootstepEcho.PlaybackSpeed = FOOTSTEP_ECHO_PLAYBACK_SPEED
	FootstepEcho.Parent = root
end

local function removeDefaultCharacterSounds(character)
	task.wait(0.1)

	local root = character:FindFirstChild("HumanoidRootPart")

	if root then
		for _, child in pairs(root:GetChildren()) do
			if child:IsA("Sound")
				and child.Name ~= "LocalFootstepSound"
				and child.Name ~= "LocalFootstepEcho"
			then
				child:Destroy()
			end
		end
	end

	for _, descendant in pairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			for _, child in pairs(descendant:GetChildren()) do
				if child:IsA("Sound")
					and (
						child.Name == "Running"
						or child.Name == "SwimSurface"
						or child.Name == "Swim"
						or child.Name == "Splash"
						or child.Name == "GettingUp"
						or child.Name == "Climbing"
					)
				then
					child:Destroy()
				end
			end
		end
	end
end

local function setupViewModel(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then
		return
	end

	RigType = humanoid.RigType

	local fallbackAsset
	local insertAssetId

	if RigType == Enum.HumanoidRigType.R15 then
		fallbackAsset = R15_FALLBACK_ASSET
		insertAssetId = R15_INSERT_ASSET_ID
		ViewOffset = CFrame.new(0, 0, 1.5)
	else
		fallbackAsset = R6_FALLBACK_ASSET
		insertAssetId = R6_INSERT_ASSET_ID
		ViewOffset = CFrame.new(0, 0, 0.1)
	end

	loadViewModel(fallbackAsset, insertAssetId)
	loadAnimations()
end

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift
		or input.KeyCode == Enum.KeyCode.RightShift
	then
		ShiftHeld = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift
		or input.KeyCode == Enum.KeyCode.RightShift
	then
		ShiftHeld = false
	end
end)

task.spawn(function()
	removeDefaultCharacterSounds(Character)
	createFootstepSounds(Character)
	setupViewModel(Character)
end)

RunService.RenderStepped:Connect(function(deltaTime)
	if not Character or not Character.Parent then
		return
	end

	local humanoid = Character:FindFirstChildOfClass("Humanoid")
	local root = Character:FindFirstChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera

	if not root or not humanoid or not camera then
		return
	end

	if BaseWalkSpeed == nil then
		BaseWalkSpeed = humanoid.WalkSpeed
		SprintApplied = false
	end

	local firstPerson = isFirstPerson()

	local velocity = root.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

	if ViewModel then
		configureViewModelPhysics()

		if not firstPerson then
			setViewModelVisible(false)

			ActiveAnimation = nil
			TransitionAnimation = nil
			TransitionStartTransforms = nil
			TransitionElapsed = 0
		else
			setViewModelVisible(true)

			local position = root.Position
			local rootCFrame = root.CFrame

			if ORBIT_VIEWMODEL then
				local angle = tick() * VIEWMODEL_SPIN_SPEED
				local orbitPosition = position + Vector3.new(
					math.cos(angle) * 3,
					0,
					math.sin(angle) * 3
				)

				moveViewModel(
					CFrame.lookAt(
						orbitPosition,
						position + Vector3.new(0, 1, 0)
					)
				)
			else
				local viewCFrame = CFrame.new(position)
					* rootCFrame.Rotation
					* ViewOffset

				if VIEWMODEL_SPIN_SPEED > 0 then
					viewCFrame *= CFrame.Angles(
						0,
						tick() * VIEWMODEL_SPIN_SPEED,
						0
					)
				end

				moveViewModel(viewCFrame)
			end

			local moving = horizontalSpeed > MOVE_THRESHOLD
			local running = moving and ShiftHeld
			local walking = moving and not ShiftHeld

			local desiredAnimation

			if running
				and Animations.run
				and #Animations.run.keyframes > 0
			then
				desiredAnimation = "run"
			elseif walking
				and Animations.walk
				and #Animations.walk.keyframes > 0
			then
				desiredAnimation = "walk"
			elseif not moving
				and Animations.idle
				and #Animations.idle.keyframes > 0
			then
				desiredAnimation = "idle"
			else
				desiredAnimation = nil
			end

			beginAnimationTransition(desiredAnimation)

			local playingAnimation = TransitionAnimation or ActiveAnimation

			if playingAnimation then
				local animation = Animations[playingAnimation]

				if animation and animation.duration > 0 then
					AnimationTime += deltaTime
					AnimationTime %= animation.duration
				end
			end

			if TransitionAnimation ~= nil then
				local targetTransforms = {}

				if Animations[TransitionAnimation] then
					targetTransforms = sampleAnimation(
						Animations[TransitionAnimation],
						AnimationTime
					)
				end

				local alpha = math.clamp(
					TransitionElapsed / ANIMATION_BLEND_TIME,
					0,
					1
				)

				for name, motor in pairs(Motors) do
					local from = TransitionStartTransforms[name] or CFrame.new()
					local to = targetTransforms[name] or CFrame.new()
					motor.Transform = from:Lerp(to, alpha)
				end

				TransitionElapsed += deltaTime

				if TransitionElapsed >= ANIMATION_BLEND_TIME then
					finishAnimationTransition()

					if ActiveAnimation then
						applyAnimation(
							Animations[ActiveAnimation],
							Motors,
							AnimationTime
						)
					else
						resetMotorTransforms(Motors)
					end
				end
			elseif ActiveAnimation then
				applyAnimation(
					Animations[ActiveAnimation],
					Motors,
					AnimationTime
				)
			else
				resetMotorTransforms(Motors)
			end
		end
	end

	local shouldSprint = firstPerson
		and horizontalSpeed > MOVE_THRESHOLD
		and ShiftHeld

	if shouldSprint and not SprintApplied then
		humanoid.WalkSpeed = BaseWalkSpeed + SPRINT_SPEED_BONUS
		SprintApplied = true
	elseif not shouldSprint and SprintApplied then
		humanoid.WalkSpeed = BaseWalkSpeed
		SprintApplied = false
	end

	local _, cameraYaw = camera.CFrame:ToEulerAnglesYXZ()
	local yawDelta = cameraYaw - PreviousCameraYaw

	CameraYawVelocity = deltaTime > 0 and yawDelta / deltaTime or 0
	PreviousCameraYaw = cameraYaw

	local yawRoll = CameraYawVelocity * CAMERA_YAW_ROLL_SCALE
	yawRoll = math.clamp(
		yawRoll,
		-MAX_CAMERA_YAW_ROLL,
		MAX_CAMERA_YAW_ROLL
	)

	local idleBob = 0

	if horizontalSpeed <= 2 then
		IdleBobPhase += deltaTime
		idleBob = math.sin(IdleBobPhase * IDLE_BOB_FREQUENCY)
			* IDLE_BOB_AMOUNT
	end

	if horizontalSpeed > 2 then
		MoveBobPhase += deltaTime * (horizontalSpeed / 4)

		MoveBobOffset = math.sin(
			MoveBobPhase * MOVE_BOB_FREQUENCY
		) * MOVE_BOB_AMOUNT

		SmoothedVelocity = SmoothedVelocity:Lerp(
			Vector3.new(velocity.X, 0, velocity.Z),
			0.1
		)

		local movementDirection = SmoothedVelocity.Unit

		local cameraRight = Vector3.new(
			camera.CFrame.RightVector.X,
			0,
			camera.CFrame.RightVector.Z
		).Unit

		local rightDot = movementDirection:Dot(cameraRight)
		local rightDotChange = math.abs(rightDot - PreviousRightDot)
		PreviousRightDot = rightDot

		local responsiveness = math.clamp(
			1.5 - rightDotChange * 3,
			0.15,
			1.5
		)

		SmoothedStrafe += (
			rightDot - SmoothedStrafe
		) * math.clamp(
			deltaTime * 4 * responsiveness,
			0.01,
			0.15
		)

		CameraRollTarget = -SmoothedStrafe * STRAFE_ROLL_AMOUNT

		CameraRoll += (
			CameraRollTarget - CameraRoll
		) * math.clamp(
			deltaTime * 6,
			0.01,
			0.2
		)

		CameraRoll += yawRoll * math.clamp(
			deltaTime * 5,
			0.01,
			0.2
		)

		camera.CFrame = camera.CFrame
			* CFrame.Angles(0, 0, CameraRoll)
			* CFrame.new(0, MoveBobOffset, 0)
	else
		CameraRoll += yawRoll * math.clamp(
			deltaTime * 5,
			0.01,
			0.2
		)

		camera.CFrame = camera.CFrame
			* CFrame.Angles(0, 0, CameraRoll)
			* CFrame.new(0, idleBob, 0)

		SmoothedStrafe *= 0.9
		MoveBobOffset *= 0.92
		MoveBobPhase = 0
	end

	CameraRoll *= 0.95

	local groundedAndMoving = horizontalSpeed > 2
		and humanoid.FloorMaterial ~= Enum.Material.Air

	if groundedAndMoving then
		FootstepTimer += deltaTime

		local stepInterval

		if ShiftHeld then
			stepInterval = RUN_STEP_BASE_INTERVAL
				/ math.clamp(horizontalSpeed / 10, 0.8, 1.5)
		else
			stepInterval = WALK_STEP_INTERVAL
		end

		if FootstepTimer >= stepInterval then
			FootstepTimer = 0

			if FootstepSound and FootstepEcho then
				local playbackSpeed =
					FOOTSTEP_MIN_PLAYBACK_SPEED
					+ math.random()
					* (
						FOOTSTEP_MAX_PLAYBACK_SPEED
						- FOOTSTEP_MIN_PLAYBACK_SPEED
					)

				FootstepSound.PlaybackSpeed = playbackSpeed
				FootstepSound:Play()

				task.delay(FOOTSTEP_ECHO_DELAY, function()
					if FootstepEcho and FootstepEcho.Parent then
						FootstepEcho:Play()
					end
				end)
			end
		end
	else
		FootstepTimer = WALK_STEP_INTERVAL * 0.4
	end
end)

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
	CharacterRoot = newCharacter:WaitForChild("HumanoidRootPart")

	ActiveAnimation = nil
	TransitionAnimation = nil
	TransitionStartTransforms = nil
	TransitionElapsed = 0
	AnimationTime = 0

	BaseWalkSpeed = nil
	SprintApplied = false
	ShiftHeld = false

	CameraRoll = 0
	CameraRollTarget = 0
	MoveBobPhase = 0
	MoveBobOffset = 0
	SmoothedStrafe = 0
	SmoothedVelocity = Vector3.new(0, 0, 0)
	PreviousRightDot = 0
	PreviousCameraYaw = 0
	CameraYawVelocity = 0
	IdleBobPhase = 0
	FootstepTimer = 0

	FootstepSound = nil
	FootstepEcho = nil

	task.spawn(function()
		removeDefaultCharacterSounds(newCharacter)
		createFootstepSounds(newCharacter)
		setupViewModel(newCharacter)
	end)
end)
