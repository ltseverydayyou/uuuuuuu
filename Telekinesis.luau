local ENV = (getgenv and getgenv()) or _G

if type(ENV.__Telekinesis) == "table" and type(ENV.__Telekinesis.Unload) == "function" then
	pcall(ENV.__Telekinesis.Unload)
end

local loader = loadstring or load
assert(type(loader) == "function", "Telekinesis: loadstring/load unavailable")

local SR = assert(loader(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/ServiceResolver.luau"), "@ServiceResolver.luau"))()
local UIP = assert(loader(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/UIprotector.luau"), "@UIprotector.luau"))()
assert(type(SR) == "table" and type(SR.cs) == "function", "Telekinesis: ServiceResolver failed")
assert(type(UIP) == "table" and type(UIP.protectUI) == "function", "Telekinesis: UIprotector failed")

local ref = type(cloneref) == "function" and cloneref or function(value)
	return value
end

local S = {
	connections = {},
	frozen = {},
	hold = nil,
	tool = nil,
	character = nil,
	equipped = false,
	mobile = false,
	unloaded = false,
	simClock = 0,
	lastTouch = nil,
	distanceInput = {pull = false, push = false},
	physicsOwners = {service = nil, original = nil, changed = false},
	ui = {},
}

local Services = {}
for _, name in ipairs({"Players", "RunService", "UserInputService", "Workspace", "TweenService", "GuiService", "CoreGui"}) do
	Services[name] = SR.cs(name, ref) or SR.gs(name)
	assert(Services[name], "Telekinesis: missing service " .. name)
end

local Players = Services.Players
local RunService = Services.RunService
local UIS = Services.UserInputService
local Workspace = Services.Workspace
local TweenService = Services.TweenService
local GuiService = Services.GuiService
local CoreGui = Services.CoreGui
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local hiddenProperty = type(sethiddenproperty) == "function" and sethiddenproperty or nil

S.mobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
S.character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local COLORS = {
	bg = Color3.fromRGB(15, 17, 21),
	panel = Color3.fromRGB(22, 25, 31),
	panel2 = Color3.fromRGB(29, 33, 41),
	panelHover = Color3.fromRGB(37, 42, 52),
	line = Color3.fromRGB(53, 60, 74),
	text = Color3.fromRGB(240, 244, 252),
	muted = Color3.fromRGB(145, 155, 174),
	accent = Color3.fromRGB(87, 164, 255),
	accent2 = Color3.fromRGB(113, 186, 255),
	good = Color3.fromRGB(92, 220, 144),
	warn = Color3.fromRGB(255, 194, 92),
	bad = Color3.fromRGB(255, 102, 112),
}

local function bind(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(S.connections, connection)
	return connection
end

local function destroy(object)
	if object then
		pcall(function()
			object:Destroy()
		end)
	end
end

local function rounded(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = object
	return corner
end

local function stroke(object, color, thickness, transparency)
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = color or COLORS.line
	uiStroke.Thickness = thickness or 1
	uiStroke.Transparency = transparency or 0
	uiStroke.Parent = object
	return uiStroke
end

local function tween(object, properties, duration)
	pcall(function()
		TweenService:Create(object, TweenInfo.new(duration or 0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties):Play()
	end)
end

local function safeName(instance)
	if not instance then
		return "nothing"
	end
	local ok, value = pcall(function()
		return instance.Name
	end)
	return ok and tostring(value) or "object"
end

local function countFrozen()
	local count = 0
	for part, data in pairs(S.frozen) do
		if part and part.Parent and data then
			count += 1
		else
			S.frozen[part] = nil
		end
	end
	return count
end

local function setStatus(text, tone)
	local label = S.ui.statusText
	local dot = S.ui.statusDot
	if label then
		label.Text = text
	end
	if dot then
		local color = COLORS.muted
		if tone == "good" then
			color = COLORS.good
		elseif tone == "warn" then
			color = COLORS.warn
		elseif tone == "bad" then
			color = COLORS.bad
		elseif tone == "accent" then
			color = COLORS.accent
		end
		tween(dot, {BackgroundColor3 = color}, 0.12)
	end
end

local function updateGrabButton()
	local button = S.ui.grabButton
	local sub = S.ui.grabSub
	if not button or not sub then
		return
	end
	if S.hold and S.hold.part and S.hold.part.Parent then
		button.Text = "RELEASE"
		sub.Text = safeName(S.hold.part) .. "  •  " .. tostring(math.floor(S.hold.distance + 0.5)) .. " studs"
		tween(button, {BackgroundColor3 = COLORS.accent}, 0.12)
	elseif S.equipped then
		button.Text = "GRAB"
		sub.Text = S.mobile and "Tap a world part to grab it" or "Hold left click on an unanchored part"
		tween(button, {BackgroundColor3 = COLORS.panel2}, 0.12)
	else
		button.Text = "EQUIP TOOL"
		sub.Text = "Equip Telekinesis to begin"
		tween(button, {BackgroundColor3 = COLORS.panel2}, 0.12)
	end
end

local function updateStatus()
	updateGrabButton()
	if S.hold and S.hold.part and S.hold.part.Parent then
		setStatus("Holding " .. safeName(S.hold.part), "accent")
	elseif not S.equipped then
		setStatus("Equip Telekinesis to begin", "warn")
	else
		local frozen = countFrozen()
		if frozen > 0 then
			setStatus("Ready  •  " .. frozen .. " frozen", "good")
		else
			setStatus("Ready", "good")
		end
	end
end

local function currentCamera()	return Workspace.CurrentCamera
end

local function centerPoint()
	local camera = currentCamera()
	if not camera then
		return Vector2.zero
	end
	local size = camera.ViewportSize
	return Vector2.new(size.X * 0.5, size.Y * 0.5)
end

local Mouse = LocalPlayer:GetMouse()

local function aimPoint()
	if S.mobile then
		return centerPoint()
	end
	return Vector2.new(Mouse.X, Mouse.Y)
end

local function controlActive()
	return S.equipped
end

local function rayFromPoint(point)
	local camera = currentCamera()
	if not camera then
		return nil
	end
	local ray = camera:ScreenPointToRay(point.X, point.Y)
	return ray
end

local function targetFromPoint(point)
	local ray = rayFromPoint(point)
	if not ray then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excludes = {}
	if S.character then
		table.insert(excludes, S.character)
	end
	if S.tool then
		table.insert(excludes, S.tool)
	end
	params.FilterDescendantsInstances = excludes
	params.IgnoreWater = true
	local result = Workspace:Raycast(ray.Origin, ray.Direction * 1500, params)
	if result and result.Instance and result.Instance:IsA("BasePart") then
		return result.Instance, result.Position, ray
	end
	return nil, nil, ray
end

local function clearBeam(data)
	if not data then
		return
	end
	destroy(data.beam)
	destroy(data.beamA0)
	destroy(data.beamA1)
	data.beam = nil
	data.beamA0 = nil
	data.beamA1 = nil
end

local function clearMotionExtras(data)
	if not data then
		return
	end
	destroy(data.spinner)
	destroy(data.rotationLock)
	destroy(data.flingMover)
	if data.part and data.part.Parent and data.flingOriginalCanCollide ~= nil then
		pcall(function()
			data.part.CanCollide = data.flingOriginalCanCollide
		end)
	end
	if data.bodyPosition and data.bodyPosition.Parent then
		pcall(function()
			data.bodyPosition.P = data.flingOriginalP or 26000
			data.bodyPosition.D = data.flingOriginalD or 1150
		end)
	end
	data.spinner = nil
	data.rotationLock = nil
	data.flingMover = nil
end

local function releaseHeld(keepBodyPosition)
	local data = S.hold
	if not data then
		return
	end
	clearBeam(data)
	clearMotionExtras(data)
	if not keepBodyPosition then
		destroy(data.bodyPosition)
	end
	S.hold = nil
	if S.ui.selection then
		S.ui.selection.Adornee = nil
	end
	updateStatus()
end

local function unfreeze(part)
	local data = S.frozen[part]
	if not data then
		return false
	end
	destroy(data.bodyPosition)
	destroy(data.box)
	S.frozen[part] = nil
	updateStatus()
	return true
end

local function clearFrozen()
	for part, data in pairs(S.frozen) do
		destroy(data.bodyPosition)
		destroy(data.box)
		S.frozen[part] = nil
	end
	updateStatus()
end

local function attachBeam(part)
	if not S.tool or S.tool.Parent ~= S.character then
		return nil, nil, nil
	end
	local originPart = S.tool:FindFirstChild("Handle")
	if not originPart or not originPart:IsA("BasePart") then
		return nil, nil, nil
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "TKBeamOrigin"
	a0.Parent = originPart
	local a1 = Instance.new("Attachment")
	a1.Name = "TKBeamTarget"
	a1.Parent = part
	local beam = Instance.new("Beam")
	beam.Name = "TKBeam"
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.FaceCamera = true
	beam.Width0 = 0.055
	beam.Width1 = 0.035
	beam.LightEmission = 0.8
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(1, 0.38),
	})
	beam.Color = ColorSequence.new(COLORS.accent2)
	beam.Parent = originPart
	return beam, a0, a1
end

local function grab(part)	if not controlActive() or not part or not part.Parent or not part:IsA("BasePart") or part.Anchored then
		return false
	end
	if S.frozen[part] then
		unfreeze(part)
	end
	if S.hold then
		releaseHeld(false)
	end
	local camera = currentCamera()
	if not camera then
		return false
	end
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.Name = "TelekinesisPosition"
	bodyPosition.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bodyPosition.P = 26000
	bodyPosition.D = 1150
	bodyPosition.Position = part.Position
	bodyPosition.Parent = part
	local distance = math.clamp((part.Position - camera.CFrame.Position).Magnitude, 5, 500)
	local beam, a0, a1 = attachBeam(part)
	S.hold = {
		part = part,
		bodyPosition = bodyPosition,
		distance = distance,
		lift = 0,
		beam = beam,
		beamA0 = a0,
		beamA1 = a1,
		spinner = nil,
		rotationLock = nil,
		fling = false,
		flingMover = nil,
		flingOriginalCanCollide = part.CanCollide,
		flingOriginalP = bodyPosition.P,
		flingOriginalD = bodyPosition.D,
	}
	if S.ui.selection then
		S.ui.selection.Adornee = part
	end
	updateStatus()
	return true
end

local function grabAt(point)
	if not controlActive() then
		updateStatus()
		return false
	end
	local part = targetFromPoint(point or aimPoint())
	if not part then
		setStatus("No unanchored part under aim", "bad")
		return false
	end
	if part.Anchored then
		setStatus("That part is anchored", "bad")
		return false
	end
	return grab(part)
end

local function freezeAction()
	if S.hold and S.hold.part and S.hold.part.Parent then
		local data = S.hold
		local part = data.part
		clearBeam(data)
		clearMotionExtras(data)
		local box = Instance.new("SelectionBox")
		box.Name = "TelekinesisFrozen"
		box.LineThickness = 0.035
		box.Color3 = COLORS.good
		box.SurfaceTransparency = 1
		box.Adornee = part
		box.Parent = part
		S.frozen[part] = {
			bodyPosition = data.bodyPosition,
			box = box,
		}
		S.hold = nil
		if S.ui.selection then
			S.ui.selection.Adornee = nil
		end
		updateStatus()
		return true
	end
	local part = targetFromPoint(aimPoint())
	if part and S.frozen[part] then
		unfreeze(part)
		setStatus("Unfroze " .. safeName(part), "good")
		return true
	end
	setStatus("Grab something first", "warn")
	return false
end

local function changeDistance(delta)
	local data = S.hold
	if not data then
		setStatus("Grab something first", "warn")
		return false
	end
	data.distance = math.clamp(data.distance + delta, 3, 500)
	updateStatus()
	return true
end

local function setNear()
	local data = S.hold
	if not data then
		setStatus("Grab something first", "warn")
		return false
	end
	data.distance = 15
	data.lift = 0
	updateStatus()
	return true
end

local function adjustLift(delta)
	local data = S.hold
	if not data then
		setStatus("Grab something first", "warn")
		return false
	end
	data.lift = math.clamp(data.lift + delta, -100, 100)
	setStatus((delta > 0 and "Lifted " or "Lowered ") .. safeName(data.part), "accent")
	return true
end

local function spinAction()
	local data = S.hold
	if not data or not data.part or not data.part.Parent then
		setStatus("Grab something first", "warn")
		return false
	end
	if data.spinner then
		destroy(data.spinner)
		data.spinner = nil
		setStatus("Spin off", "good")
		return true
	end
	destroy(data.rotationLock)
	data.rotationLock = nil
	local spinner = Instance.new("BodyAngularVelocity")
	spinner.Name = "TelekinesisSpin"
	spinner.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	spinner.P = 1250
	spinner.AngularVelocity = Vector3.new(0, 7.5, 0)
	spinner.Parent = data.part
	data.spinner = spinner
	setStatus("Spin on", "accent")
	return true
end

local function lockRotationAction()
	local data = S.hold
	if not data or not data.part or not data.part.Parent then
		setStatus("Grab something first", "warn")
		return false
	end
	if data.rotationLock then
		destroy(data.rotationLock)
		data.rotationLock = nil
		setStatus("Rotation unlocked", "good")
		return true
	end
	destroy(data.spinner)
	data.spinner = nil
	pcall(function()
		data.part.AssemblyAngularVelocity = Vector3.zero
	end)
	local gyro = Instance.new("BodyGyro")
	gyro.Name = "TelekinesisRotationLock"
	gyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	gyro.P = 18000
	gyro.D = 700
	gyro.CFrame = data.part.CFrame
	gyro.Parent = data.part
	data.rotationLock = gyro
	setStatus("Rotation locked", "accent")
	return true
end

local function throwAction(power)
	local data = S.hold
	if not data or not data.part or not data.part.Parent then
		setStatus("Grab something first", "warn")
		return false
	end
	local part = data.part
	local ray = rayFromPoint(aimPoint())
	if not ray then
		return false
	end
	local direction = ray.Direction.Unit
	releaseHeld(false)
	pcall(function()
		part.AssemblyLinearVelocity = direction * power + Vector3.new(0, power * 0.08, 0)
	end)
	setStatus("Threw " .. safeName(part), "accent")
	return true
end

local function setFlingActive(data, enabled)
	if not data or not data.part or not data.part.Parent then
		return false
	end
	data.fling = enabled == true
	if data.fling then
		if not data.flingMover or not data.flingMover.Parent then
			local mover = Instance.new("BodyAngularVelocity")
			mover.Name = "TelekinesisFling"
			mover.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
			mover.P = 1e9
			mover.AngularVelocity = Vector3.new(0, 5000, 0)
			mover.Parent = data.part
			data.flingMover = mover
		end
		pcall(function()
			data.part.CanCollide = true
			if data.bodyPosition and data.bodyPosition.Parent then
				data.bodyPosition.P = 65000
				data.bodyPosition.D = 2600
			end
		end)
	else
		destroy(data.flingMover)
		data.flingMover = nil
		pcall(function()
			data.part.AssemblyAngularVelocity = Vector3.zero
			data.part.RotVelocity = Vector3.zero
		end)
		if data.flingOriginalCanCollide ~= nil then
			pcall(function()
				data.part.CanCollide = data.flingOriginalCanCollide
			end)
		end
		if data.bodyPosition and data.bodyPosition.Parent then
			pcall(function()
				data.bodyPosition.P = data.flingOriginalP or 26000
				data.bodyPosition.D = data.flingOriginalD or 1150
			end)
		end
	end
	return true
end

local function flingAction()
	local data = S.hold
	if not data or not data.part or not data.part.Parent then
		setStatus("Grab something first", "warn")
		return false
	end
	setFlingActive(data, not data.fling)
	setStatus((data.fling and "Fling on  •  " or "Fling off  •  ") .. safeName(data.part), data.fling and "accent" or "good")
	return true
end

local function togglePhysicsOwners()
	local state = S.physicsOwners
	if not state.service then
		local ok, service = pcall(function()
			return settings():GetService("PhysicsSettings")
		end)
		if not ok or not service then
			setStatus("PhysicsSettings unavailable", "bad")
			return false
		end
		state.service = service
		local readOk, original = pcall(function()
			return service.AreOwnersShown
		end)
		if readOk then
			state.original = original
		end
	end
	local currentOk, current = pcall(function()
		return state.service.AreOwnersShown
	end)
	if not currentOk then
		setStatus("Could not read physics owners", "bad")
		return false
	end
	local nextValue = not current
	local setOk = pcall(function()
		state.service.AreOwnersShown = nextValue
	end)
	if not setOk then
		setStatus("Could not change physics owners", "bad")
		return false
	end
	state.changed = true
	setStatus("Physics owners " .. (nextValue and "shown" or "hidden"), nextValue and "accent" or "good")
	return true
end

local function perform(action)
	if action == "freeze" then
		return freezeAction()
	elseif action == "pull" then
		return changeDistance(-5)
	elseif action == "push" then
		return changeDistance(5)
	elseif action == "near" then
		return setNear()
	elseif action == "throw" then
		return throwAction(425)
	elseif action == "fling" then
		return flingAction()
	elseif action == "owners" then
		return togglePhysicsOwners()
	elseif action == "spin" then
		return spinAction()
	elseif action == "lock" then
		return lockRotationAction()
	elseif action == "lift" then
		return adjustLift(10)
	elseif action == "lower" then
		return adjustLift(-10)
	elseif action == "release" then
		releaseHeld(false)
		return true
	elseif action == "grab" then
		if S.hold then
			releaseHeld(false)
			return true
		end
		if not S.equipped then
			local character = LocalPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and S.tool and S.tool.Parent then
				humanoid:EquipTool(S.tool)
				setStatus("Telekinesis equipped", "good")
				return true
			end
			setStatus("Could not equip Telekinesis", "bad")
			return false
		end
		return grabAt(aimPoint())
	end
	return false
end

local function createTool()
	if S.unloaded then
		return
	end
	local tool = Instance.new("Tool")
	tool.Name = "Telekinesis"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = S.mobile and "Tap a part to grab it" or "Hold left click to grab"
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.6, 0.6, 0.6)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.CanTouch = false
	handle.CanQuery = false
	handle.Massless = true
	handle.Parent = tool
	S.tool = tool
	bind(tool.Equipped, function()
		S.equipped = true
		S.character = tool.Parent
		updateStatus()
	end)
	bind(tool.Unequipped, function()
		S.equipped = false
		releaseHeld(false)
		updateStatus()
	end)
	bind(tool.AncestryChanged, function(_, parent)
		if parent == nil and not S.unloaded then
			S.Unload()
		end
	end)
	pcall(function()
		bind(tool.Destroying, function()
			if not S.unloaded then
				S.Unload(true)
			end
		end)
	end)
	tool.Parent = Backpack
	updateStatus()
end

local screen = Instance.new("ScreenGui")
screen.Name = "TelekinesisUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.DisplayOrder = 999998
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(1, 0.5)
main.Position = UDim2.new(1, -20, 0.5, 0)
main.Size = UDim2.fromOffset(310, 400)
main.BackgroundColor3 = COLORS.bg
main.BorderSizePixel = 0
main.Active = true
main.Parent = screen
rounded(main, 12)
stroke(main, COLORS.line, 1, 0.18)

local header = Instance.new("Frame")
header.Name = "Header"
header.BackgroundColor3 = COLORS.panel
header.BorderSizePixel = 0
header.Size = UDim2.new(1, 0, 0, 46)
header.Active = true
header.Parent = main
rounded(header, 12)

local headerMask = Instance.new("Frame")
headerMask.BackgroundColor3 = COLORS.panel
headerMask.BorderSizePixel = 0
headerMask.Position = UDim2.new(0, 0, 1, -12)
headerMask.Size = UDim2.new(1, 0, 0, 12)
headerMask.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(12, 5)
title.Size = UDim2.new(1, -134, 0, 21)
title.Font = Enum.Font.GothamBold
title.Text = "TELEKINESIS"
title.TextColor3 = COLORS.text
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(12, 24)
subtitle.Size = UDim2.new(1, -134, 0, 15)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = S.mobile and "MOBILE" or "DESKTOP"
subtitle.TextColor3 = COLORS.muted
subtitle.TextSize = 9
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local hide = Instance.new("TextButton")
hide.Name = "Hide"
hide.AnchorPoint = Vector2.new(1, 0.5)
hide.Position = UDim2.new(1, -68, 0.5, 0)
hide.Size = UDim2.fromOffset(42, 25)
hide.BackgroundColor3 = COLORS.panel2
hide.BorderSizePixel = 0
hide.AutoButtonColor = false
hide.Font = Enum.Font.GothamBold
hide.Text = "HIDE H"
hide.TextColor3 = COLORS.muted
hide.TextSize = 8
hide.Parent = header
rounded(hide, 7)
local minimize = Instance.new("TextButton")
minimize.Name = "Minimize"
minimize.AnchorPoint = Vector2.new(1, 0.5)
minimize.Position = UDim2.new(1, -38, 0.5, 0)
minimize.Size = UDim2.fromOffset(25, 25)
minimize.BackgroundColor3 = COLORS.panel2
minimize.BorderSizePixel = 0
minimize.AutoButtonColor = false
minimize.Font = Enum.Font.GothamBold
minimize.Text = "−"
minimize.TextColor3 = COLORS.muted
minimize.TextSize = 16
minimize.Parent = header
rounded(minimize, 7)

local close = Instance.new("TextButton")
close.Name = "Unload"
close.AnchorPoint = Vector2.new(1, 0.5)
close.Position = UDim2.new(1, -8, 0.5, 0)
close.Size = UDim2.fromOffset(25, 25)
close.BackgroundColor3 = COLORS.panel2
close.BorderSizePixel = 0
close.AutoButtonColor = false
close.Font = Enum.Font.GothamBold
close.Text = "×"
close.TextColor3 = COLORS.muted
close.TextSize = 16
close.Parent = header
rounded(close, 7)

local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.fromOffset(10, 54)
content.Size = UDim2.new(1, -20, 1, -64)
content.Parent = main

local statusFrame = Instance.new("Frame")
statusFrame.Name = "Status"
statusFrame.BackgroundColor3 = COLORS.panel
statusFrame.BorderSizePixel = 0
statusFrame.Size = UDim2.new(1, 0, 0, 30)
statusFrame.Parent = content
rounded(statusFrame, 8)
stroke(statusFrame, COLORS.line, 1, 0.4)

local statusDot = Instance.new("Frame")
statusDot.AnchorPoint = Vector2.new(0, 0.5)
statusDot.Position = UDim2.new(0, 10, 0.5, 0)
statusDot.Size = UDim2.fromOffset(7, 7)
statusDot.BackgroundColor3 = COLORS.warn
statusDot.BorderSizePixel = 0
statusDot.Parent = statusFrame
rounded(statusDot, 7)

local statusText = Instance.new("TextLabel")
statusText.BackgroundTransparency = 1
statusText.Position = UDim2.fromOffset(24, 0)
statusText.Size = UDim2.new(1, -32, 1, 0)
statusText.Font = Enum.Font.GothamMedium
statusText.Text = "Loading"
statusText.TextColor3 = COLORS.text
statusText.TextSize = 10
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.TextTruncate = Enum.TextTruncate.AtEnd
statusText.Parent = statusFrame

local grabWrap = Instance.new("Frame")
grabWrap.Name = "GrabWrap"
grabWrap.BackgroundTransparency = 1
grabWrap.Position = UDim2.fromOffset(0, 37)
grabWrap.Size = UDim2.new(1, 0, 0, 50)
grabWrap.Parent = content

local grabButton = Instance.new("TextButton")
grabButton.Name = "Grab"
grabButton.BackgroundColor3 = COLORS.panel2
grabButton.BorderSizePixel = 0
grabButton.Size = UDim2.new(1, 0, 0, 32)
grabButton.AutoButtonColor = false
grabButton.Font = Enum.Font.GothamBold
grabButton.Text = "GRAB"
grabButton.TextColor3 = COLORS.text
grabButton.TextSize = 11
grabButton.Parent = grabWrap
rounded(grabButton, 8)
stroke(grabButton, COLORS.line, 1, 0.3)

local grabSub = Instance.new("TextLabel")
grabSub.BackgroundTransparency = 1
grabSub.Position = UDim2.fromOffset(2, 33)
grabSub.Size = UDim2.new(1, -4, 0, 15)
grabSub.Font = Enum.Font.Gotham
grabSub.Text = ""
grabSub.TextColor3 = COLORS.muted
grabSub.TextSize = 8
grabSub.TextXAlignment = Enum.TextXAlignment.Center
grabSub.TextTruncate = Enum.TextTruncate.AtEnd
grabSub.Parent = grabWrap

local sectionTitle = Instance.new("TextLabel")
sectionTitle.BackgroundTransparency = 1
sectionTitle.Position = UDim2.fromOffset(2, 91)
sectionTitle.Size = UDim2.new(1, -4, 0, 14)
sectionTitle.Font = Enum.Font.GothamBold
sectionTitle.Text = "CONTROLS"
sectionTitle.TextColor3 = COLORS.muted
sectionTitle.TextSize = 8
sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
sectionTitle.Parent = content

local grid = Instance.new("ScrollingFrame")
grid.Name = "Actions"
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.Position = UDim2.fromOffset(0, 108)
grid.Size = UDim2.new(1, 0, 1, -108)
grid.CanvasSize = UDim2.fromOffset(0, 0)
grid.ScrollBarThickness = 2
grid.ScrollBarImageColor3 = COLORS.line
grid.ScrollingDirection = Enum.ScrollingDirection.Y
grid.Parent = content

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = grid
bind(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
	grid.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 2)
end)

local function createActionButton(order, action, name, key, description)
	local button = Instance.new("TextButton")
	button.Name = name:gsub("%s", "")
	button.LayoutOrder = order
	button.Size = UDim2.new(1, -4, 0, 34)
	button.BackgroundColor3 = COLORS.panel
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.Parent = grid
	rounded(button, 8)
	stroke(button, COLORS.line, 1, 0.4)

	local keyLabel = Instance.new("TextLabel")
	keyLabel.AnchorPoint = Vector2.new(0, 0.5)
	keyLabel.BackgroundColor3 = COLORS.panel2
	keyLabel.BorderSizePixel = 0
	keyLabel.Position = UDim2.new(0, 7, 0.5, 0)
	keyLabel.Size = UDim2.fromOffset(24, 20)
	keyLabel.Font = Enum.Font.GothamBold
	keyLabel.Text = key
	keyLabel.TextColor3 = COLORS.accent2
	keyLabel.TextSize = 9
	keyLabel.Parent = button
	rounded(keyLabel, 5)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(39, 0)
	nameLabel.Size = UDim2.fromOffset(72, 34)
	nameLabel.Font = Enum.Font.GothamSemibold
	nameLabel.Text = name
	nameLabel.TextColor3 = COLORS.text
	nameLabel.TextSize = 10
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = button

	local desc = Instance.new("TextLabel")
	desc.BackgroundTransparency = 1
	desc.Position = UDim2.fromOffset(112, 0)
	desc.Size = UDim2.new(1, -120, 1, 0)
	desc.Font = Enum.Font.Gotham
	desc.Text = description
	desc.TextColor3 = COLORS.muted
	desc.TextSize = 8
	desc.TextXAlignment = Enum.TextXAlignment.Right
	desc.TextTruncate = Enum.TextTruncate.AtEnd
	desc.Parent = button

	bind(button.Activated, function()
		tween(button, {BackgroundColor3 = COLORS.panelHover}, 0.06)
		perform(action)
		task.delay(0.09, function()
			if button and button.Parent then
				tween(button, {BackgroundColor3 = COLORS.panel}, 0.12)
			end
		end)
	end)
	if not S.mobile then
		bind(button.MouseEnter, function()
			tween(button, {BackgroundColor3 = COLORS.panelHover}, 0.12)
		end)
		bind(button.MouseLeave, function()
			tween(button, {BackgroundColor3 = COLORS.panel}, 0.12)
		end)
	end
	return button
end

createActionButton(1, "freeze", "Freeze", "F", "Lock / unlock")
createActionButton(2, "pull", "Pull", "Q", "5 studs closer")
createActionButton(3, "push", "Push", "E", "5 studs farther")
createActionButton(4, "near", "Near", "X", "Reset to 15 studs")
createActionButton(5, "throw", "Throw", "Y", "Maximum force")
createActionButton(6, "fling", "Fling", "J", "Toggle active fling")
createActionButton(7, "spin", "Spin", "U", "Toggle rotation")
createActionButton(8, "lock", "Lock Rot.", "L", "Hold orientation")
createActionButton(9, "lower", "Lower", "[", "-10 studs")
createActionButton(10, "lift", "Lift", "]", "+10 studs")
createActionButton(11, "owners", "Phys Owners", "K", "Toggle ownership view")

local selection = Instance.new("SelectionBox")selection.Name = "TelekinesisSelection"
selection.LineThickness = 0.035
selection.Color3 = COLORS.accent2
selection.SurfaceTransparency = 1
selection.Parent = Workspace

S.ui.screen = screen
S.ui.main = main
S.ui.content = content
S.ui.statusText = statusText
S.ui.statusDot = statusDot
S.ui.grabButton = grabButton
S.ui.grabSub = grabSub
S.ui.selection = selection

local protected = false
local okProtect = pcall(function()
	UIP.protectUI(screen, {
		name = "TelekinesisUI",
		keepName = true,
		harden = true,
		deep = true,
		watch = true,
		rename = false,
	})
end)
protected = okProtect and screen.Parent ~= nil
if not protected then
	screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local function applyResponsiveSize()
	local camera = currentCamera()
	if not camera or not main or not main.Parent then
		return
	end
	local viewport = camera.ViewportSize
	local width = math.clamp(viewport.X - 20, 270, 310)
	local height = math.clamp(viewport.Y - 70, 320, 400)
	main.Size = UDim2.fromOffset(width, height)
end

applyResponsiveSize()

local NAgui = {
	_dragState = {owner = nil, input = nil},
	_draggerCleanups = setmetatable({}, {__mode = "k"}),
}

NAgui.dragger = function(ui, dragui)
	if not ui or not ui:IsA("GuiObject") then
		return function() end
	end
	dragui = dragui or ui
	local previous = NAgui._draggerCleanups[ui]
	if previous then
		pcall(previous)
	end

	local dragging = false
	local dragStart
	local startPos
	local dragPointer
	local pendingInput
	local moveConn
	local endConn
	local stepConn
	local baseConns = {}
	local cleaned = false

	local function getParentSize()
		local parent = ui.Parent
		if parent then
			local ok, size = pcall(function()
				return parent.AbsoluteSize
			end)
			if ok and typeof(size) == "Vector2" and size.X > 0 and size.Y > 0 then
				return size
			end
		end
		local camera = currentCamera()
		return camera and camera.ViewportSize or Vector2.new(1280, 720)
	end

	local function clampPosition(position)
		if not ui or not ui.Parent then
			return
		end
		local parentSize = getParentSize()
		local size = ui.AbsoluteSize
		if parentSize.X <= 0 or parentSize.Y <= 0 or size.X <= 0 or size.Y <= 0 then
			return
		end
		local anchor = ui.AnchorPoint
		local px = position.X.Scale * parentSize.X + position.X.Offset
		local py = position.Y.Scale * parentSize.Y + position.Y.Offset
		local edgePadding = 18
		local minX = anchor.X * size.X + edgePadding
		local maxX = math.max(minX, parentSize.X - (1 - anchor.X) * size.X - edgePadding)
		local minY = anchor.Y * size.Y + edgePadding
		local maxY = math.max(minY, parentSize.Y - (1 - anchor.Y) * size.Y - edgePadding)
		px = math.clamp(px, minX, maxX)
		py = math.clamp(py, minY, maxY)
		ui.Position = UDim2.new(px / parentSize.X, 0, py / parentSize.Y, 0)
	end

	local function isTopMost(root, input)
		local list
		local ok = pcall(function()
			list = CoreGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
		end)
		if not ok or type(list) ~= "table" or #list == 0 then
			return true
		end
		for _, gui in ipairs(list) do
			if typeof(gui) == "Instance" and gui:IsA("GuiButton") and gui.Visible and gui.Active then
				if gui ~= root and gui:IsDescendantOf(root) then
					return false
				end
				break
			end
		end
		return true
	end

	local function disconnectLiveInput()
		if moveConn then moveConn:Disconnect() moveConn = nil end
		if endConn then endConn:Disconnect() endConn = nil end
		if stepConn then stepConn:Disconnect() stepConn = nil end
		pendingInput = nil
	end

	local function stopDrag()
		dragging = false
		dragPointer = nil
		pendingInput = nil
		if NAgui._dragState.owner == ui then
			NAgui._dragState.owner = nil
			NAgui._dragState.input = nil
		end
		disconnectLiveInput()
	end

	local function cleanup()
		if cleaned then return end
		cleaned = true
		stopDrag()
		for _, connection in ipairs(baseConns) do
			pcall(function() connection:Disconnect() end)
		end
		table.clear(baseConns)
		NAgui._draggerCleanups[ui] = nil
	end

	local function update(input)
		if not dragging or not dragStart or not startPos then
			return
		end
		local parentSize = getParentSize()
		local delta = input.Position - dragStart
		local startX = startPos.X.Scale * parentSize.X + startPos.X.Offset
		local startY = startPos.Y.Scale * parentSize.Y + startPos.Y.Offset
		clampPosition(UDim2.new(0, startX + delta.X, 0, startY + delta.Y))
	end

	table.insert(baseConns, dragui.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
			and (not NAgui._dragState.owner or NAgui._dragState.owner == ui)
			and isTopMost(dragui, input) then
			NAgui._dragState.owner = ui
			NAgui._dragState.input = input
			dragging = true
			dragPointer = input
			dragStart = input.Position
			startPos = ui.Position
			disconnectLiveInput()

			moveConn = UIS.InputChanged:Connect(function(changedInput)
				if not dragging or NAgui._dragState.owner ~= ui then return end
				local inputType = changedInput.UserInputType
				if inputType == Enum.UserInputType.MouseMovement then
					pendingInput = changedInput
				elseif inputType == Enum.UserInputType.Touch and changedInput == dragPointer then
					pendingInput = changedInput
				end
			end)

			endConn = UIS.InputEnded:Connect(function(endedInput)
				if endedInput.UserInputType == Enum.UserInputType.MouseButton1
					or (endedInput.UserInputType == Enum.UserInputType.Touch and endedInput == dragPointer) then
					stopDrag()
				end
			end)

			stepConn = RunService.RenderStepped:Connect(function()
				local frameInput = pendingInput
				if not frameInput then return end
				pendingInput = nil
				update(frameInput)
			end)
		end
	end))

	table.insert(baseConns, ui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		clampPosition(ui.Position)
	end))
	pcall(function()
		local parent = ui.Parent
		if parent and parent.GetPropertyChangedSignal then
			table.insert(baseConns, parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				clampPosition(ui.Position)
			end))
		end
	end)
	table.insert(baseConns, ui.AncestryChanged:Connect(function(_, parent)
		if not parent then task.defer(cleanup) end
	end))
	pcall(function()
		table.insert(baseConns, ui.Destroying:Connect(cleanup))
	end)

	ui.Active = true
	dragui.Active = true
	NAgui._draggerCleanups[ui] = cleanup
	clampPosition(ui.Position)
	return cleanup
end

local dragCleanup = NAgui.dragger(main, header)
table.insert(S.connections, {Disconnect = dragCleanup})

local collapsed = false
bind(minimize.Activated, function()
	collapsed = not collapsed
	content.Visible = not collapsed
	minimize.Text = collapsed and "+" or "−"
	if collapsed then
		tween(main, {Size = UDim2.fromOffset(main.AbsoluteSize.X, 46)}, 0.18)
	else
		applyResponsiveSize()
	end
end)

local function toggleUIVisibility(forceVisible)
	if not main or not main.Parent then
		return false
	end
	if forceVisible == nil then
		main.Visible = not main.Visible
	else
		main.Visible = forceVisible == true
	end
	return main.Visible
end

bind(hide.Activated, function()
	toggleUIVisibility(false)
end)
bind(grabButton.Activated, function()
	perform("grab")
end)

local function pointInsideMain(point)
	if not point or not main or not main.Parent or not main.Visible then
		return false
	end
	local position = main.AbsolutePosition
	local size = main.AbsoluteSize
	return point.X >= position.X and point.Y >= position.Y and point.X <= position.X + size.X and point.Y <= position.Y + size.Y
end

local keyActions = {
	[Enum.KeyCode.F] = "freeze",
	[Enum.KeyCode.Q] = "pull",
	[Enum.KeyCode.E] = "push",
	[Enum.KeyCode.X] = "near",
	[Enum.KeyCode.Y] = "throw",
	[Enum.KeyCode.J] = "fling",
	[Enum.KeyCode.K] = "owners",
	[Enum.KeyCode.U] = "spin",
	[Enum.KeyCode.L] = "lock",
	[Enum.KeyCode.LeftBracket] = "lower",
	[Enum.KeyCode.RightBracket] = "lift",
}

bind(UIS.InputBegan, function(input, processed)
	if S.unloaded then
		return
	end
	if input.KeyCode == Enum.KeyCode.H and not processed then
		toggleUIVisibility()
		return
	end
	if processed or not controlActive() then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q then
		S.distanceInput.pull = true
	elseif input.KeyCode == Enum.KeyCode.E then
		S.distanceInput.push = true
	end
	local action = keyActions[input.KeyCode]
	if action then
		perform(action)
		return
	end
	if not S.mobile and input.UserInputType == Enum.UserInputType.MouseButton1 then
		if pointInsideMain(input.Position) then
			return
		end
		if not S.hold then
			grabAt(Vector2.new(input.Position.X, input.Position.Y))
		end
	end
end)

bind(UIS.InputEnded, function(input)
	if input.KeyCode == Enum.KeyCode.Q then
		S.distanceInput.pull = false
	elseif input.KeyCode == Enum.KeyCode.E then
		S.distanceInput.push = false
	end
	if S.unloaded or S.mobile then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1 and S.hold then
		releaseHeld(false)
	end
end)

if S.mobile then
	bind(UIS.TouchTap, function(points, processed)
		if processed or S.unloaded or not controlActive() then
			return
		end
		local point = points and points[1]
		if not point or pointInsideMain(point) then
			return
		end
		S.lastTouch = point
		if S.hold then
			releaseHeld(false)
		else
			grabAt(point)
		end
	end)
end

bind(RunService.RenderStepped, function(dt)
	local data = S.hold
	if not data then
		return
	end
	local distanceDirection = (S.distanceInput.push and 1 or 0) - (S.distanceInput.pull and 1 or 0)
	if distanceDirection ~= 0 then
		data.distance = math.clamp(data.distance + distanceDirection * 35 * dt, 3, 500)
	end
	if not data.part or not data.part.Parent or not data.bodyPosition or not data.bodyPosition.Parent then
		releaseHeld(false)
		return
	end
	local ray = rayFromPoint(aimPoint())
	if not ray then
		return
	end
	local target = ray.Origin + ray.Direction.Unit * data.distance + Vector3.new(0, data.lift, 0)
	data.bodyPosition.Position = target
end)

bind(RunService.Heartbeat, function(dt)
	local data = S.hold
	if data and data.part and data.part.Parent then
		if data.fling then
			setFlingActive(data, true)
		elseif data.flingMover then
			setFlingActive(data, false)
		end
	end
	if not hiddenProperty then
		return
	end
	S.simClock += dt
	if S.simClock >= 1 then
		S.simClock = 0
		pcall(hiddenProperty, LocalPlayer, "SimulationRadius", 1000)
	end
end)

local viewportConnection
local function bindViewport()
	if viewportConnection then
		viewportConnection:Disconnect()
		viewportConnection = nil
	end
	local camera = currentCamera()
	if camera then
		viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if not collapsed then
				applyResponsiveSize()
			end
		end)
		table.insert(S.connections, viewportConnection)
	end
end
bindViewport()
bind(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
	bindViewport()
	if not collapsed then
		applyResponsiveSize()
	end
end)

bind(LocalPlayer.CharacterAdded, function(character)
	S.character = character
	S.equipped = false
	releaseHeld(false)
	clearFrozen()
end)

function S.Unload(skipToolDestroy)
	if S.unloaded then
		return
	end
	S.unloaded = true
	releaseHeld(false)
	clearFrozen()
	S.distanceInput.pull = false
	S.distanceInput.push = false
	if S.physicsOwners.changed and S.physicsOwners.service and S.physicsOwners.original ~= nil then
		pcall(function()
			S.physicsOwners.service.AreOwnersShown = S.physicsOwners.original
		end)
	end
	for _, connection in ipairs(S.connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(S.connections)
	if not skipToolDestroy then
		destroy(S.tool)
	end
	S.tool = nil
	destroy(S.ui.selection)
	if UIP and type(UIP.cleanup) == "function" then
		pcall(UIP.cleanup, screen)
	end
	destroy(screen)
	if ENV.__Telekinesis == S then
		ENV.__Telekinesis = nil
	end
end

S.API = {
	Grab = grab,
	GrabAt = grabAt,
	Release = function()
		releaseHeld(false)
	end,
	Action = perform,
	ClearFrozen = clearFrozen,
	Status = function()
		return {
			loaded = not S.unloaded,
			equipped = S.equipped,
			mobile = S.mobile,
			holding = S.hold and safeName(S.hold.part) or nil,
			frozen = countFrozen(),
			uiParent = screen.Parent and screen.Parent:GetFullName() or nil,
			toolParent = S.tool and S.tool.Parent and S.tool.Parent:GetFullName() or nil,
		}
	end,
}

ENV.__Telekinesis = S
bind(close.Activated, function()
	S.Unload()
end)
createTool()
updateStatus()
