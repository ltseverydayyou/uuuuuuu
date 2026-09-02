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
	keybinds = {},
	keyLabels = {},
	keyActions = {},
	bindingCapture = nil,
	ui = {},
}

local Services = {}
for _, name in ipairs({"Players", "RunService", "UserInputService", "Workspace", "TweenService", "GuiService", "CoreGui", "HttpService"}) do
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
local HttpService = Services.HttpService
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local hiddenProperty = type(sethiddenproperty) == "function" and sethiddenproperty or nil

S.mobile = UIS.TouchEnabled and (not UIS.KeyboardEnabled or not UIS.MouseEnabled)
S.character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local COLORS = {
	bg = Color3.fromRGB(10, 6, 18),
	bg2 = Color3.fromRGB(16, 9, 29),
	panel = Color3.fromRGB(22, 13, 38),
	panel2 = Color3.fromRGB(31, 18, 52),
	panelHover = Color3.fromRGB(45, 27, 73),
	line = Color3.fromRGB(78, 48, 116),
	lineSoft = Color3.fromRGB(53, 31, 82),
	text = Color3.fromRGB(247, 242, 255),
	muted = Color3.fromRGB(167, 145, 193),
	accent = Color3.fromRGB(161, 91, 255),
	accent2 = Color3.fromRGB(208, 151, 255),
	accentDark = Color3.fromRGB(91, 43, 153),
	good = Color3.fromRGB(116, 231, 174),
	warn = Color3.fromRGB(255, 198, 110),
	bad = Color3.fromRGB(255, 105, 137),
}

local ACTION_META = {
	{action = "freeze", name = "Freeze", description = "Lock / unlock", default = "F"},
	{action = "pull", name = "Pull", description = "Bring closer", default = "Q"},
	{action = "push", name = "Push", description = "Move farther", default = "E"},
	{action = "near", name = "Near", description = "Reset distance", default = "X"},
	{action = "throw", name = "Throw", description = "Maximum force", default = "Y"},
	{action = "fling", name = "Fling", description = "Toggle active fling", default = "J"},
	{action = "spin", name = "Spin", description = "Toggle rotation", default = "U"},
	{action = "lock", name = "Lock Rot.", description = "Hold orientation", default = "L"},
	{action = "lower", name = "Lower", description = "-10 studs", default = "LeftBracket"},
	{action = "lift", name = "Lift", description = "+10 studs", default = "RightBracket"},
	{action = "owners", name = "Phys Owners", description = "Ownership view", default = "K"},
	{action = "ui", name = "Show / Hide UI", description = "Toggle interface", default = "H", settingsOnly = true},
}

local DEFAULT_KEYBINDS = {}
local ACTION_BY_NAME = {}
for _, meta in ipairs(ACTION_META) do
	DEFAULT_KEYBINDS[meta.action] = meta.default
	ACTION_BY_NAME[meta.action] = meta
end

local CONFIG_DIR = "Telekinesis"
local CONFIG_FILE = CONFIG_DIR .. "/settings.json"

local function keyDisplay(keyName)
	if keyName == "LeftBracket" then return "[" end
	if keyName == "RightBracket" then return "]" end
	if keyName == "Semicolon" then return ";" end
	if keyName == "Quote" then return "'" end
	if keyName == "BackSlash" then return "\\" end
	return tostring(keyName or "?"):gsub("Keypad", "Num ")
end

local function rebuildKeyActions()
	table.clear(S.keyActions)
	for action, keyName in pairs(S.keybinds) do
		if action ~= "ui" then
			local keyCode = Enum.KeyCode[keyName]
			if keyCode then
				S.keyActions[keyCode] = action
			end
		end
	end
end

local function loadSettings()
	for action, keyName in pairs(DEFAULT_KEYBINDS) do
		S.keybinds[action] = keyName
	end
	if type(isfile) == "function" and type(readfile) == "function" then
		local okExists, exists = pcall(isfile, CONFIG_FILE)
		if okExists and exists then
			local okRead, raw = pcall(readfile, CONFIG_FILE)
			if okRead and type(raw) == "string" then
				local okDecode, data = pcall(function() return HttpService:JSONDecode(raw) end)
				if okDecode and type(data) == "table" and type(data.keybinds) == "table" then
					for action, keyName in pairs(data.keybinds) do
						if DEFAULT_KEYBINDS[action] and type(keyName) == "string" and Enum.KeyCode[keyName] then
							S.keybinds[action] = keyName
						end
					end
				end
			end
		end
	end
	rebuildKeyActions()
end

local function saveSettings()
	if type(writefile) ~= "function" then
		return false
	end
	if type(makefolder) == "function" then
		pcall(makefolder, CONFIG_DIR)
	end
	local okEncode, raw = pcall(function()
		return HttpService:JSONEncode({version = 1, keybinds = S.keybinds})
	end)
	if not okEncode then
		return false
	end
	return pcall(writefile, CONFIG_FILE, raw)
end

local function refreshKeyLabels(action)
	local labels = S.keyLabels[action]
	if not labels then return end
	local textValue = keyDisplay(S.keybinds[action])
	for _, label in ipairs(labels) do
		if label and label.Parent then
			label.Text = textValue
		end
	end
end

local function registerKeyLabel(action, label)
	S.keyLabels[action] = S.keyLabels[action] or {}
	table.insert(S.keyLabels[action], label)
	label.Text = keyDisplay(S.keybinds[action])
end

loadSettings()

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

local function cancelBindingCapture(message)
	local capture = S.bindingCapture
	S.bindingCapture = nil
	if capture then
		refreshKeyLabels(capture.action)
	end
	if message then
		setStatus(message, "good")
	end
end

local function beginBindingCapture(action)
	if not DEFAULT_KEYBINDS[action] then return end
	if S.bindingCapture then
		refreshKeyLabels(S.bindingCapture.action)
	end
	S.bindingCapture = {action = action}
	local labels = S.keyLabels[action] or {}
	for _, label in ipairs(labels) do
		if label and label.Parent then label.Text = "..." end
	end
	local meta = ACTION_BY_NAME[action]
	setStatus("Press a key for " .. (meta and meta.name or action) .. "  •  Esc to cancel", "accent")
end

local function assignKeybind(action, keyCode)
	if not keyCode or keyCode == Enum.KeyCode.Unknown then return false end
	local keyName = keyCode.Name
	for otherAction, otherKey in pairs(S.keybinds) do
		if otherAction ~= action and otherKey == keyName then
			local otherMeta = ACTION_BY_NAME[otherAction]
			setStatus(keyDisplay(keyName) .. " is already bound to " .. (otherMeta and otherMeta.name or otherAction), "warn")
			return false
		end
	end
	S.keybinds[action] = keyName
	rebuildKeyActions()
	refreshKeyLabels(action)
	S.bindingCapture = nil
	local saved = saveSettings()
	local meta = ACTION_BY_NAME[action]
	setStatus((meta and meta.name or action) .. " → " .. keyDisplay(keyName) .. (saved and "  •  saved" or ""), "good")
	return true
end

local function resetKeybinds()
	for action, keyName in pairs(DEFAULT_KEYBINDS) do
		S.keybinds[action] = keyName
	end
	rebuildKeyActions()
	for action in pairs(S.keyLabels) do refreshKeyLabels(action) end
	S.bindingCapture = nil
	saveSettings()
	setStatus("Keybinds reset to defaults", "good")
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

local reopen = Instance.new("TextButton")
reopen.Name = "Reopen"
reopen.AnchorPoint = Vector2.new(1, 1)
reopen.Position = UDim2.new(1, -16, 1, -16)
reopen.Size = UDim2.fromOffset(54, 38)
reopen.BackgroundColor3 = COLORS.panel2
reopen.BorderSizePixel = 0
reopen.AutoButtonColor = false
reopen.Font = Enum.Font.GothamBold
reopen.Text = "TK"
reopen.TextColor3 = COLORS.accent2
reopen.TextSize = 12
reopen.Visible = false
reopen.Parent = screen
rounded(reopen, 12)
stroke(reopen, COLORS.accentDark, 1, 0.12)
local reopenScale = Instance.new("UIScale")
reopenScale.Parent = reopen

local main = Instance.new("Frame")
main.Name = "Main"
main.AnchorPoint = Vector2.new(1, 0.5)
main.Position = UDim2.new(1, -18, 0.5, 0)
main.Size = UDim2.fromOffset(340, 454)
main.BackgroundColor3 = COLORS.bg
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = true
main.Parent = screen
rounded(main, 16)
local mainStroke = stroke(main, COLORS.accentDark, 1, 0.12)
local mainScale = Instance.new("UIScale")
mainScale.Scale = 0.94
mainScale.Parent = main

local mainGradient = Instance.new("UIGradient")
mainGradient.Rotation = 35
mainGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, COLORS.bg),
	ColorSequenceKeypoint.new(0.55, COLORS.bg2),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 12, 39)),
})
mainGradient.Parent = main
pcall(function()
	TweenService:Create(mainGradient, TweenInfo.new(6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(0.08, 0)}):Play()
end)

local header = Instance.new("Frame")
header.Name = "Header"
header.BackgroundColor3 = COLORS.panel
header.BorderSizePixel = 0
header.Size = UDim2.new(1, 0, 0, 54)
header.Active = true
header.Parent = main
rounded(header, 16)

local headerGradient = Instance.new("UIGradient")
headerGradient.Rotation = 12
headerGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 19, 65)),
	ColorSequenceKeypoint.new(0.6, COLORS.panel),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 13, 43)),
})
headerGradient.Parent = header
pcall(function()
	TweenService:Create(headerGradient, TweenInfo.new(4.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Offset = Vector2.new(-0.12, 0)}):Play()
end)

local headerMask = Instance.new("Frame")
headerMask.BackgroundColor3 = COLORS.panel
headerMask.BackgroundTransparency = 0.15
headerMask.BorderSizePixel = 0
headerMask.Position = UDim2.new(0, 0, 1, -14)
headerMask.Size = UDim2.new(1, 0, 0, 14)
headerMask.Parent = header

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14, 7)
title.Size = UDim2.new(1, -150, 0, 21)
title.Font = Enum.Font.GothamBold
title.Text = "TELEKINESIS"
title.TextColor3 = COLORS.text
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromOffset(14, 28)
subtitle.Size = UDim2.new(1, -150, 0, 15)
subtitle.Font = Enum.Font.GothamMedium
subtitle.Text = S.mobile and "TOUCH CONTROL" or "DESKTOP CONTROL"
subtitle.TextColor3 = COLORS.accent2
subtitle.TextSize = 8
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local function headerButton(name, textValue, xOffset, width)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, xOffset, 0.5, 0)
	button.Size = UDim2.fromOffset(width or 28, 28)
	button.BackgroundColor3 = COLORS.panel2
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamBold
	button.Text = textValue
	button.TextColor3 = COLORS.muted
	button.TextSize = 9
	button.Parent = header
	rounded(button, 9)
	local scale = Instance.new("UIScale")
	scale.Parent = button
	bind(button.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			tween(scale, {Scale = 0.9}, 0.08)
		end
	end)
	bind(button.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			tween(scale, {Scale = 1}, 0.16)
		end
	end)
	if not S.mobile then
		bind(button.MouseEnter, function() tween(button, {BackgroundColor3 = COLORS.panelHover, TextColor3 = COLORS.text}, 0.12) end)
		bind(button.MouseLeave, function() tween(button, {BackgroundColor3 = COLORS.panel2, TextColor3 = COLORS.muted}, 0.16) end)
	end
	return button
end

local hide = headerButton("Hide", "HIDE", -74, 44)
local minimize = headerButton("Minimize", "—", -40, 28)
minimize.TextSize = 14
local close = headerButton("Unload", "×", -8, 28)
close.TextSize = 16

local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.Position = UDim2.fromOffset(12, 64)
content.Size = UDim2.new(1, -24, 1, -76)
content.Parent = main

local statusFrame = Instance.new("Frame")
statusFrame.Name = "Status"
statusFrame.BackgroundColor3 = COLORS.panel
statusFrame.BorderSizePixel = 0
statusFrame.Size = UDim2.new(1, 0, 0, 34)
statusFrame.Parent = content
rounded(statusFrame, 10)
stroke(statusFrame, COLORS.lineSoft, 1, 0.2)

local statusDot = Instance.new("Frame")
statusDot.AnchorPoint = Vector2.new(0, 0.5)
statusDot.Position = UDim2.new(0, 11, 0.5, 0)
statusDot.Size = UDim2.fromOffset(8, 8)
statusDot.BackgroundColor3 = COLORS.warn
statusDot.BorderSizePixel = 0
statusDot.Parent = statusFrame
rounded(statusDot, 8)

local statusText = Instance.new("TextLabel")
statusText.BackgroundTransparency = 1
statusText.Position = UDim2.fromOffset(27, 0)
statusText.Size = UDim2.new(1, -38, 1, 0)
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
grabWrap.Position = UDim2.fromOffset(0, 42)
grabWrap.Size = UDim2.new(1, 0, 0, 54)
grabWrap.Parent = content

local grabButton = Instance.new("TextButton")
grabButton.Name = "Grab"
grabButton.BackgroundColor3 = COLORS.panel2
grabButton.BorderSizePixel = 0
grabButton.Size = UDim2.new(1, 0, 0, 36)
grabButton.AutoButtonColor = false
grabButton.Font = Enum.Font.GothamBold
grabButton.Text = "GRAB"
grabButton.TextColor3 = COLORS.text
grabButton.TextSize = 11
grabButton.Parent = grabWrap
rounded(grabButton, 10)
stroke(grabButton, COLORS.line, 1, 0.2)
local grabScale = Instance.new("UIScale")
grabScale.Parent = grabButton
bind(grabButton.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		tween(grabScale, {Scale = 0.975}, 0.07)
	end
end)
bind(grabButton.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		tween(grabScale, {Scale = 1}, 0.15)
	end
end)

local grabSub = Instance.new("TextLabel")
grabSub.BackgroundTransparency = 1
grabSub.Position = UDim2.fromOffset(2, 37)
grabSub.Size = UDim2.new(1, -4, 0, 15)
grabSub.Font = Enum.Font.Gotham
grabSub.Text = ""
grabSub.TextColor3 = COLORS.muted
grabSub.TextSize = 8
grabSub.TextXAlignment = Enum.TextXAlignment.Center
grabSub.TextTruncate = Enum.TextTruncate.AtEnd
grabSub.Parent = grabWrap

local tabBar = Instance.new("Frame")
tabBar.Name = "Tabs"
tabBar.BackgroundColor3 = COLORS.panel
tabBar.BorderSizePixel = 0
tabBar.Position = UDim2.fromOffset(0, 103)
tabBar.Size = UDim2.new(1, 0, 0, 32)
tabBar.Parent = content
rounded(tabBar, 10)

local controlsTab = Instance.new("TextButton")
controlsTab.Name = "Controls"
controlsTab.Position = UDim2.fromOffset(3, 3)
controlsTab.Size = UDim2.new(0.5, -5, 1, -6)
controlsTab.BackgroundColor3 = COLORS.accentDark
controlsTab.BorderSizePixel = 0
controlsTab.AutoButtonColor = false
controlsTab.Font = Enum.Font.GothamBold
controlsTab.Text = "CONTROLS"
controlsTab.TextColor3 = COLORS.text
controlsTab.TextSize = 8
controlsTab.Parent = tabBar
rounded(controlsTab, 8)

local keybindsTab = Instance.new("TextButton")
keybindsTab.Name = "Keybinds"
keybindsTab.AnchorPoint = Vector2.new(1, 0)
keybindsTab.Position = UDim2.new(1, -3, 0, 3)
keybindsTab.Size = UDim2.new(0.5, -5, 1, -6)
keybindsTab.BackgroundColor3 = COLORS.panel2
keybindsTab.BorderSizePixel = 0
keybindsTab.AutoButtonColor = false
keybindsTab.Font = Enum.Font.GothamBold
keybindsTab.Text = "KEYBINDS"
keybindsTab.TextColor3 = COLORS.muted
keybindsTab.TextSize = 8
keybindsTab.Parent = tabBar
rounded(keybindsTab, 8)

local grid = Instance.new("ScrollingFrame")
grid.Name = "Actions"
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.Position = UDim2.fromOffset(0, 143)
grid.Size = UDim2.new(1, 0, 1, -143)
grid.CanvasSize = UDim2.fromOffset(0, 0)
grid.ScrollBarThickness = S.mobile and 0 or 2
grid.ScrollBarImageColor3 = COLORS.accentDark
grid.ScrollingDirection = Enum.ScrollingDirection.Y
grid.Parent = content
local controlsPageScale = Instance.new("UIScale")
controlsPageScale.Parent = grid

local actionLayout = Instance.new("UIGridLayout")
actionLayout.SortOrder = Enum.SortOrder.LayoutOrder
actionLayout.CellPadding = UDim2.fromOffset(0, 6)
actionLayout.CellSize = UDim2.new(1, -4, 0, 40)
actionLayout.Parent = grid
bind(actionLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
	grid.CanvasSize = UDim2.fromOffset(0, actionLayout.AbsoluteContentSize.Y + 4)
end)

local keybindPage = Instance.new("ScrollingFrame")
keybindPage.Name = "KeybindSettings"
keybindPage.BackgroundTransparency = 1
keybindPage.BorderSizePixel = 0
keybindPage.Position = grid.Position
keybindPage.Size = grid.Size
keybindPage.CanvasSize = UDim2.fromOffset(0, 0)
keybindPage.ScrollBarThickness = S.mobile and 0 or 2
keybindPage.ScrollBarImageColor3 = COLORS.accentDark
keybindPage.Visible = false
keybindPage.Parent = content
local keybindPageScale = Instance.new("UIScale")
keybindPageScale.Parent = keybindPage

local keybindLayout = Instance.new("UIListLayout")
keybindLayout.Padding = UDim.new(0, 6)
keybindLayout.SortOrder = Enum.SortOrder.LayoutOrder
keybindLayout.Parent = keybindPage
bind(keybindLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
	keybindPage.CanvasSize = UDim2.fromOffset(0, keybindLayout.AbsoluteContentSize.Y + 8)
end)

local function pulseControl(button, scale, down)
	if scale then tween(scale, {Scale = down and 0.975 or 1}, down and 0.06 or 0.14) end
	if not down then tween(button, {BackgroundColor3 = COLORS.panel}, 0.15) end
end

local function createActionButton(order, meta)
	local action = meta.action
	local button = Instance.new("TextButton")
	button.Name = meta.name:gsub("%W", "")
	button.LayoutOrder = order
	button.BackgroundColor3 = COLORS.panel
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.Parent = grid
	rounded(button, 11)
	stroke(button, COLORS.lineSoft, 1, 0.18)
	local scale = Instance.new("UIScale")
	scale.Parent = button

	local keyLabel = Instance.new("TextLabel")
	keyLabel.AnchorPoint = S.mobile and Vector2.new(1, 0) or Vector2.new(0, 0.5)
	keyLabel.BackgroundColor3 = COLORS.panel2
	keyLabel.BorderSizePixel = 0
	keyLabel.Position = S.mobile and UDim2.new(1, -8, 0, 7) or UDim2.new(0, 8, 0.5, 0)
	keyLabel.Size = UDim2.fromOffset(S.mobile and 30 or 28, 22)
	keyLabel.Font = Enum.Font.GothamBold
	keyLabel.TextColor3 = COLORS.accent2
	keyLabel.TextSize = 9
	keyLabel.Parent = button
	rounded(keyLabel, 6)
	registerKeyLabel(action, keyLabel)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = S.mobile and UDim2.fromOffset(10, 5) or UDim2.fromOffset(44, 0)
	nameLabel.Size = S.mobile and UDim2.new(1, -50, 0, 22) or UDim2.fromOffset(92, 40)
	nameLabel.Font = Enum.Font.GothamSemibold
	nameLabel.Text = meta.name
	nameLabel.TextColor3 = COLORS.text
	nameLabel.TextSize = S.mobile and 10 or 10
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = button

	local desc = Instance.new("TextLabel")
	desc.BackgroundTransparency = 1
	desc.Position = S.mobile and UDim2.fromOffset(10, 27) or UDim2.fromOffset(137, 0)
	desc.Size = S.mobile and UDim2.new(1, -18, 0, 18) or UDim2.new(1, -145, 1, 0)
	desc.Font = Enum.Font.Gotham
	desc.Text = meta.description
	desc.TextColor3 = COLORS.muted
	desc.TextSize = 8
	desc.TextXAlignment = S.mobile and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
	desc.TextTruncate = Enum.TextTruncate.AtEnd
	desc.Parent = button

	local isDistance = action == "pull" or action == "push"
	local distanceHeld = false
	local function beginDistanceHold()
		if not (S.mobile and isDistance) or distanceHeld then return end
		distanceHeld = true
		S.distanceInput[action] = true
		perform(action)
	end
	local function endDistanceHold()
		if not isDistance then return end
		distanceHeld = false
		S.distanceInput[action] = false
	end
	bind(button.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			tween(scale, {Scale = 0.97}, 0.06)
			tween(button, {BackgroundColor3 = COLORS.panelHover}, 0.08)
			beginDistanceHold()
		end
	end)
	bind(button.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			pulseControl(button, scale, false)
			endDistanceHold()
		end
	end)
	if S.mobile and isDistance then
		bind(button.MouseButton1Down, beginDistanceHold)
		bind(button.MouseButton1Up, endDistanceHold)
	end
	bind(button.Activated, function()
		if not (S.mobile and isDistance) then perform(action) end
	end)
	if not S.mobile then
		bind(button.MouseEnter, function() tween(button, {BackgroundColor3 = COLORS.panelHover}, 0.12); tween(scale, {Scale = 1.012}, 0.12) end)
		bind(button.MouseLeave, function() tween(button, {BackgroundColor3 = COLORS.panel}, 0.16); tween(scale, {Scale = 1}, 0.16) end)
	end
	return button
end

local controlOrder = 0
for _, meta in ipairs(ACTION_META) do
	if not meta.settingsOnly then
		controlOrder += 1
		createActionButton(controlOrder, meta)
	end
end

local function createKeybindRow(order, meta)
	local row = Instance.new("Frame")
	row.Name = meta.action
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -4, 0, S.mobile and 46 or 40)
	row.BackgroundColor3 = COLORS.panel
	row.BorderSizePixel = 0
	row.Parent = keybindPage
	rounded(row, 10)
	stroke(row, COLORS.lineSoft, 1, 0.25)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(11, 0)
	label.Size = UDim2.new(1, -106, 1, 0)
	label.Font = Enum.Font.GothamSemibold
	label.Text = meta.name
	label.TextColor3 = COLORS.text
	label.TextSize = 9
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local bindButton = Instance.new("TextButton")
	bindButton.AnchorPoint = Vector2.new(1, 0.5)
	bindButton.Position = UDim2.new(1, -8, 0.5, 0)
	bindButton.Size = UDim2.fromOffset(78, S.mobile and 32 or 28)
	bindButton.BackgroundColor3 = COLORS.panel2
	bindButton.BorderSizePixel = 0
	bindButton.AutoButtonColor = false
	bindButton.Font = Enum.Font.GothamBold
	bindButton.TextColor3 = COLORS.accent2
	bindButton.TextSize = 9
	bindButton.Parent = row
	rounded(bindButton, 8)
	registerKeyLabel(meta.action, bindButton)
	bind(bindButton.Activated, function() beginBindingCapture(meta.action) end)
	if not S.mobile then
		bind(bindButton.MouseEnter, function() tween(bindButton, {BackgroundColor3 = COLORS.panelHover}, 0.12) end)
		bind(bindButton.MouseLeave, function() tween(bindButton, {BackgroundColor3 = COLORS.panel2}, 0.15) end)
	end
end

for order, meta in ipairs(ACTION_META) do createKeybindRow(order, meta) end

local resetBinds = Instance.new("TextButton")
resetBinds.Name = "ResetKeybinds"
resetBinds.LayoutOrder = #ACTION_META + 1
resetBinds.Size = UDim2.new(1, -4, 0, 34)
resetBinds.BackgroundColor3 = Color3.fromRGB(53, 24, 70)
resetBinds.BorderSizePixel = 0
resetBinds.AutoButtonColor = false
resetBinds.Font = Enum.Font.GothamBold
resetBinds.Text = "RESET KEYBINDS"
resetBinds.TextColor3 = COLORS.accent2
resetBinds.TextSize = 8
resetBinds.Parent = keybindPage
rounded(resetBinds, 10)
bind(resetBinds.Activated, resetKeybinds)

local activeTab = "controls"
local function setTab(name, instant)
	activeTab = name == "keybinds" and "keybinds" or "controls"
	local controlsOpen = activeTab == "controls"
	grid.Visible = controlsOpen
	keybindPage.Visible = not controlsOpen
	tween(controlsTab, {BackgroundColor3 = controlsOpen and COLORS.accentDark or COLORS.panel2, TextColor3 = controlsOpen and COLORS.text or COLORS.muted}, instant and 0 or 0.14)
	tween(keybindsTab, {BackgroundColor3 = controlsOpen and COLORS.panel2 or COLORS.accentDark, TextColor3 = controlsOpen and COLORS.muted or COLORS.text}, instant and 0 or 0.14)
	local page = controlsOpen and grid or keybindPage
	local pageScale = controlsOpen and controlsPageScale or keybindPageScale
	page.CanvasPosition = Vector2.zero
	pageScale.Scale = instant and 1 or 0.965
	if not instant then tween(pageScale, {Scale = 1}, 0.2) end
end
bind(controlsTab.Activated, function() setTab("controls") end)
bind(keybindsTab.Activated, function() setTab("keybinds") end)
setTab("controls", true)

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
S.ui.reopen = reopen
S.ui.mainScale = mainScale
S.ui.actionLayout = actionLayout
S.ui.grid = grid
S.ui.keybindPage = keybindPage

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

local function getResponsiveSize()
	local camera = currentCamera()
	if not camera then return main.Size end
	local viewport = camera.ViewportSize
	if S.mobile then
		local width = math.clamp(viewport.X - 14, 300, 430)
		local height = math.clamp(viewport.Y * 0.72, 390, 560)
		actionLayout.CellPadding = UDim2.fromOffset(6, 6)
		actionLayout.CellSize = UDim2.new(0.5, -5, 0, 54)
		reopen.AnchorPoint = Vector2.new(1, 1)
		reopen.Position = UDim2.new(1, -12, 1, -12)
		reopen.Size = UDim2.fromOffset(58, 42)
		return UDim2.fromOffset(width, math.min(height, viewport.Y - 20))
	end
	local width = math.clamp(viewport.X - 24, 310, 340)
	local height = math.clamp(viewport.Y - 80, 390, 454)
	actionLayout.CellPadding = UDim2.fromOffset(0, 6)
	actionLayout.CellSize = UDim2.new(1, -4, 0, 40)
	return UDim2.fromOffset(width, height)
end

local function applyResponsiveSize(resetPosition)
	if not main or not main.Parent then return end
	if resetPosition then
		if S.mobile then
			main.AnchorPoint = Vector2.new(0.5, 1)
			main.Position = UDim2.new(0.5, 0, 1, -10)
		else
			main.AnchorPoint = Vector2.new(1, 0.5)
			main.Position = UDim2.new(1, -18, 0.5, 0)
		end
	end
	main.Size = getResponsiveSize()
	S.ui.openPosition = main.Position
end

applyResponsiveSize(true)
task.defer(function()
	mainScale.Scale = 0.94
	tween(mainScale, {Scale = 1}, 0.32)
	tween(mainStroke, {Transparency = 0.32}, 0.45)
end)

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
	if collapsed then
		S.ui.expandedPosition = main.Position
		S.ui.expandedSize = getResponsiveSize()
		S.ui.openPosition = main.Position
		tween(mainScale, {Scale = 0.985}, 0.1)
		tween(main, {Size = UDim2.fromOffset(main.AbsoluteSize.X, 54)}, 0.22)
		task.delay(0.12, function()
			if collapsed and content and content.Parent then content.Visible = false end
		end)
		minimize.Text = "+"
	else
		local restorePosition = S.ui.expandedPosition or main.Position
		local restoreSize = getResponsiveSize()
		main.Position = restorePosition
		S.ui.openPosition = restorePosition
		content.Visible = false
		tween(main, {Size = restoreSize}, 0.26)
		tween(mainScale, {Scale = 1}, 0.22)
		task.delay(0.08, function()
			if not collapsed and content and content.Parent then
				content.Visible = true
			end
		end)
		minimize.Text = "—"
	end
end)

local function offsetHidden(position)
	if S.mobile then
		return UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset + 72)
	end
	return UDim2.new(position.X.Scale, position.X.Offset + 54, position.Y.Scale, position.Y.Offset)
end

local function toggleUIVisibility(forceVisible)
	local targetVisible = forceVisible
	if targetVisible == nil then targetVisible = not (S.ui.visibleWanted ~= false and main.Visible) end
	S.ui.visibleWanted = targetVisible == true
	if targetVisible then
		main.Visible = true
		reopen.Visible = false
		local target = S.ui.openPosition or main.Position
		main.Position = offsetHidden(target)
		mainScale.Scale = 0.92
		tween(main, {Position = target}, 0.24)
		tween(mainScale, {Scale = 1}, 0.3)
	else
		S.ui.openPosition = main.Position
		local hidden = offsetHidden(main.Position)
		tween(main, {Position = hidden}, 0.2)
		tween(mainScale, {Scale = 0.93}, 0.18)
		task.delay(0.2, function()
			if S.ui.visibleWanted == false and main and main.Parent then
				main.Visible = false
				reopen.Visible = true
				reopenScale.Scale = 0.7
				tween(reopenScale, {Scale = 1}, 0.24)
			end
		end)
	end
	return targetVisible
end

S.ui.visibleWanted = true
bind(hide.Activated, function() toggleUIVisibility(false) end)
bind(reopen.Activated, function() toggleUIVisibility(true) end)
bind(grabButton.Activated, function() perform("grab") end)

local function pointInsideMain(point)
	if not point or not main or not main.Parent or not main.Visible then
		return false
	end
	local position = main.AbsolutePosition
	local size = main.AbsoluteSize
	return point.X >= position.X and point.Y >= position.Y and point.X <= position.X + size.X and point.Y <= position.Y + size.Y
end


bind(UIS.InputBegan, function(input, processed)
	if S.unloaded then return end
	if S.bindingCapture then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then
				cancelBindingCapture("Keybind change cancelled")
			elseif input.KeyCode == Enum.KeyCode.Backspace then
				local action = S.bindingCapture.action
				S.keybinds[action] = DEFAULT_KEYBINDS[action]
				rebuildKeyActions()
				S.bindingCapture = nil
				refreshKeyLabels(action)
				saveSettings()
				setStatus((ACTION_BY_NAME[action] and ACTION_BY_NAME[action].name or action) .. " reset", "good")
			elseif input.KeyCode ~= Enum.KeyCode.Unknown then
				assignKeybind(S.bindingCapture.action, input.KeyCode)
			end
		end
		return
	end
	local uiKey = Enum.KeyCode[S.keybinds.ui]
	if uiKey and input.KeyCode == uiKey and not processed then
		toggleUIVisibility()
		return
	end
	if processed or not controlActive() then return end
	local pullKey = Enum.KeyCode[S.keybinds.pull]
	local pushKey = Enum.KeyCode[S.keybinds.push]
	if pullKey and input.KeyCode == pullKey then
		S.distanceInput.pull = true
	elseif pushKey and input.KeyCode == pushKey then
		S.distanceInput.push = true
	end
	local action = S.keyActions[input.KeyCode]
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
	local pullKey = Enum.KeyCode[S.keybinds.pull]
	local pushKey = Enum.KeyCode[S.keybinds.push]
	if pullKey and input.KeyCode == pullKey then
		S.distanceInput.pull = false
	elseif pushKey and input.KeyCode == pushKey then
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
	S.bindingCapture = nil
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
			keybinds = table.clone(S.keybinds),
			uiVisible = main and main.Visible or false,
		}
	end,
}

ENV.__Telekinesis = S
bind(close.Activated, function()
	S.Unload()
end)
createTool()
updateStatus()
