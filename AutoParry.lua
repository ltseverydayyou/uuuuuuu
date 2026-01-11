local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Stats = game:GetService("Stats")

local guiCHECKINGAHHHHH=function()
	return (gethui and gethui()) or game:GetService("CoreGui"):FindFirstChildWhichIsA("ScreenGui") or game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:FindFirstChildWhichIsA("PlayerGui")
end

local localPlayer = Players.LocalPlayer
local character = localPlayer and localPlayer.Character

local function waitForChildFast(parent, name)
	if not parent then
		return nil
	end
	return parent:FindFirstChild(name) or parent:WaitForChild(name, 5)
end

getgenv().exe = true
pcall(function() setfpscap(240) end)

local visualizerRaw = getgenv().visualizer
if visualizerRaw == nil then
	getgenv().visualizer = false
	visualizerRaw = false
end
local visualizerConfig = type(visualizerRaw) == "table" and visualizerRaw or {}
local function isVisualizerEnabled()
	local v = getgenv().visualizer
	if type(v) == "boolean" then
		return v
	elseif type(v) == "table" then
		return v.enabled ~= false
	end
	return false
end

local speedScale = type(visualizerConfig) == "table" and visualizerConfig.speedScale or 0.06
local minSize = type(visualizerConfig) == "table" and visualizerConfig.minSize or 5
local maxSize = type(visualizerConfig) == "table" and visualizerConfig.maxSize or 200
local predictMaxSize = type(visualizerConfig) == "table" and visualizerConfig.predictMaxSize or 400
local predictMinRadius = type(visualizerConfig) == "table" and visualizerConfig.predictMinRadius or 10
local pingPredictScale = type(visualizerConfig) == "table" and visualizerConfig.pingPredictScale or 0.1
local pingTimeScale = type(visualizerConfig) == "table" and visualizerConfig.pingTimeScale or 0.001
local ringBaseTransparency = type(visualizerConfig) == "table" and visualizerConfig.transparency or 0.3
local ringPinkTransparency = type(visualizerConfig) == "table" and visualizerConfig.pinkTransparency or 0.55
local distanceDivisor = type(visualizerConfig) == "table" and visualizerConfig.distanceDivisor or 10
local predictBase = type(visualizerConfig) == "table" and visualizerConfig.predictBase or 28
local predictExtra = type(visualizerConfig) == "table" and visualizerConfig.predictExtra or 10

local function ensureIdentity()
	pcall(function()
		local level = 8
		if setidentity then
			setidentity(level)
		elseif setthreadidentity then
			setthreadidentity(level)
		elseif syn and syn.set_thread_identity then
			syn.set_thread_identity(level)
		elseif set_thread_identity then
			set_thread_identity(level)
		end
	end)
end

local function round(num, places)
	local mult = 10 ^ (places or 0)
	return math.floor(num * mult + 0.5) / mult
end

local function getBall()
	local balls = workspace:FindFirstChild("Balls")
	if not balls then
		return nil
	end
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local closest, bestDist
	for _, child in ipairs(balls:GetChildren()) do
		if child:IsA("BasePart") then
			if hrp then
				local dist = (child.Position - hrp.Position).Magnitude
				if not bestDist or dist < bestDist then
					closest = child
					bestDist = dist
				end
			else
				closest = child
			end
		end
	end
	return closest
end

local function newRing(name, color)
	ensureIdentity()
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = Vector3.new(10, 0.4, 10)
	part.Color = color
	part.CanCollide = false
	part.CastShadow = false
	part.CanQuery = false
	part.Transparency = type(visualizerConfig) == "table" and visualizerConfig.transparency or 0.3
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "rbxassetid://471124075"
	mesh.Scale = Vector3.new(0.067, 0.042, 0.067)
	mesh.Parent = part
	part.Parent = workspace
	return part
end

local ringPlayer = newRing("Visualizer", Color3.new(1, 0, 0))
local ringBall = ringPlayer:Clone()
ringBall.Name = "VisualizerFollowBall"
ringBall.Parent = workspace
local ringPlayerNoUnit = ringPlayer:Clone()
ringPlayerNoUnit.Name = "VisualizerNoUnit"
ringPlayerNoUnit.Color = Color3.new(1, 0, 1)
ringPlayerNoUnit.Transparency = 0.55
ringPlayerNoUnit.Parent = workspace

local function rescaleRing(part, diameter, overrideMax)
	local size = math.clamp(diameter or 10, minSize, overrideMax or maxSize)
	part.Size = Vector3.new(size, 0.4, size)
	local mesh = part:FindFirstChildOfClass("SpecialMesh")
	if mesh then
		local factor = size / 10
		mesh.Scale = Vector3.new(0.067 * factor, 0.042 * factor, 0.067 * factor)
		mesh.Offset = Vector3.new(0, -(0.2 * factor - 0.2), 0)
	end
	return size
end

local function newBillboard(name, size, studsOffset, includeMulti)
	ensureIdentity()
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Parent = guiCHECKINGAHHHHH()
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.LightInfluence = 1
	gui.Size = size
	gui.StudsOffset = studsOffset or Vector3.new(0, 5, 0)
	gui.Enabled = true
	gui.AlwaysOnTop = true
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.Parent = gui
	text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	text.BackgroundTransparency = 1
	text.BorderColor3 = Color3.fromRGB(0, 0, 0)
	text.BorderSizePixel = 0
	text.Size = UDim2.new(1, 0, 0.55, 0)
	text.Position = UDim2.new(0, 0, 0.45, 0)
	text.Font = Enum.Font.FredokaOne
	text.Text = "100"
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextScaled = true
	text.TextSize = 14
	text.TextStrokeTransparency = 0
	text.TextWrapped = true
	local textMulti
	if includeMulti then
		textMulti = text:Clone()
		textMulti.Name = "TextMulti"
		textMulti.TextTransparency = 0.5
		textMulti.TextStrokeTransparency = 0.5
		textMulti.Size = UDim2.new(1, 0, 0.45, 0)
		textMulti.Position = UDim2.new(0, 0, 0, 0)
		textMulti.Text = "1x"
		textMulti.Parent = gui
	end
	return gui, text, textMulti
end

local rangeGui, rangeText, rangeMulti = newBillboard("Range", UDim2.new(3, 0, 3, 0), Vector3.new(0, 5, 0), true)
local distanceGui, distanceText = newBillboard("Distance", UDim2.new(2, 0, 2, 0), Vector3.new(0, 5, 0), false)

local function applyVisualizerVisible(show)
	rangeGui.Enabled = show
	distanceGui.Enabled = show
	ringPlayer.Transparency = show and ringBaseTransparency or 1
	ringBall.Transparency = show and ringBaseTransparency or 1
	ringPlayerNoUnit.Transparency = show and ringPinkTransparency or 1
end

local spam = false
local lastFire = 0
local resetToken = 0
local wasInPredict = false
local ringLimited = false
local lastBallSamples = {}
local lastBallVel = {}
local currentBall = nil
local lastHighlightMatch = false
local function getHighlightColor(inst)
	local h = inst and (inst:FindFirstChildOfClass("Highlight") or inst:FindFirstChild("Highlight"))
	return h, h and h.FillColor
end
local function colorsClose(a, b, tol)
	if not (a and b) then
		return false
	end
	tol = tol or 0.05
	return math.abs(a.R - b.R) <= tol and math.abs(a.G - b.G) <= tol and math.abs(a.B - b.B) <= tol
end
local function scheduleReset()
	resetToken = resetToken + 1
	local token = resetToken
	lastFire = 0
	task.delay(0.001, function()
		if resetToken == token then
			lastFire = 0
		end
	end)
end

local function updateRingColors()
	if ringLimited then
		ringPlayer.Color = Color3.new(0, 1, 0)
	elseif spam then
		ringPlayer.Color = Color3.new(1, 0.7, 0)
	else
		ringPlayer.Color = Color3.new(1, 0, 0)
	end
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if input.KeyCode == Enum.KeyCode.X then
		spam = not spam
		updateRingColors()
	end
end)
updateRingColors()

local function updateGuiTargets(hrp, ball)
	rangeGui.Adornee = hrp
	distanceGui.Adornee = ball or hrp
end

RunService.RenderStepped:Connect(function()
	character = localPlayer.Character or character
	local hrp = waitForChildFast(character, "HumanoidRootPart")
	local ball = getBall()
	local showViz = isVisualizerEnabled()
	if not (hrp and hrp.Position) then
		return
	end

	updateGuiTargets(hrp, ball)

	if ball and ball.Position then
		if ball ~= currentBall then
			currentBall = ball
			lastBallSamples = {}
			lastBallVel = {}
		end
		local lookAtBall = CFrame.lookAt(hrp.Position, ball.Position)
		ringPlayer.CFrame = lookAtBall
		ringPlayerNoUnit.CFrame = lookAtBall
		ringBall.CFrame = CFrame.new(ball.Position)

		local rawDist = (ball.Position - hrp.Position).Magnitude
		local dist = rawDist / distanceDivisor

		local now = tick()
		local velocity = ball.AssemblyLinearVelocity or ball.Velocity or Vector3.zero
		local speed = velocity.Magnitude
		local lastVel = lastBallVel[ball] or Vector3.zero
		local sample = lastBallSamples[ball]
		local dt = sample and (now - sample.t) or 0
		local posDelta = sample and (ball.Position - sample.pos) or Vector3.zero
		if (not sample) or dt > 0.4 then
			sample = {pos = ball.Position, t = now}
			dt = 0
			posDelta = Vector3.zero
		end
		local manualVel = (dt > 0 and posDelta / dt) or velocity
		local chosenVel = velocity
		if chosenVel.Magnitude < 1e-3 or chosenVel.Magnitude < manualVel.Magnitude * 0.5 then
			chosenVel = manualVel
		end
		lastBallSamples[ball] = {pos = ball.Position, t = now}
		velocity = chosenVel:Lerp(lastVel, 0.5)
		speed = velocity.Magnitude
		lastBallVel[ball] = velocity
		local baseSize = 10 + speed * speedScale * 2
		local appliedPlayerSize = rescaleRing(ringPlayer, baseSize, maxSize)
		ringLimited = appliedPlayerSize >= maxSize - 0.1

		local multiplier = 0.12
		if speed < 60 then
			multiplier = 0.06
		elseif speed > 120 then
			multiplier = 0.2
		elseif speed > 80 then
			multiplier = 0.16
		end

		local effectiveSpeed = math.max(speed - 5, 0)
		local speedBoost = 0.05
		if speed > 160 then
			speedBoost = 0.12
		elseif speed > 120 then
			speedBoost = 0.09
		elseif speed > 80 then
			speedBoost = 0.07
		end
		local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
		local predictRadius = predictMinRadius + predictExtra + effectiveSpeed * (multiplier + speedBoost) + ping * pingPredictScale
		local appliedPredictSize = rescaleRing(ringPlayerNoUnit, predictRadius * 2, predictMaxSize)
		ringPlayerNoUnit.Transparency = ringPinkTransparency
		rescaleRing(ringBall, baseSize)

		local inPredict = rawDist <= predictRadius

		local displayedPredict = predictRadius
		rangeText.Text = tostring(round(displayedPredict, 1))
		if rangeMulti then
			rangeMulti.Text = string.format("%.1fx", round(displayedPredict / 100, 1))
		end
		distanceText.Text = tostring(round(dist, 1))

		if inPredict then
			resetToken = resetToken + 1
		elseif wasInPredict then
			scheduleReset()
		end
		wasInPredict = inPredict

		local ballHighlight, ballColor = getHighlightColor(ball)
		local charHighlight, charColor = getHighlightColor(character)
		local highlightsMatch = ballHighlight and charHighlight and colorsClose(ballColor, charColor, 0.07)
		if highlightsMatch and not lastHighlightMatch then
			lastFire = 0
		end
		lastHighlightMatch = highlightsMatch

		local approaching = false
		if speed >= 8 then
			local toYou = hrp.Position - ball.Position
			local mag = toYou.Magnitude
			if mag > 0.001 then
				local dirToYou = toYou / mag
				local velDir = speed > 0.001 and velocity.Unit or (-dirToYou)
				local dot = dirToYou:Dot(velDir)
				approaching = dot > 0.4
			end
		end

		local closeHit = highlightsMatch and rawDist <= math.max(10, appliedPredictSize * 0.45)
		local nearHitTime = speed > 1 and (rawDist / speed) or math.huge
		local veryFastHit = highlightsMatch and nearHitTime <= (0.18 + ping * pingTimeScale)

		local closeHitSafe = closeHit and (nearHitTime <= 0.3 or speed >= 25)
		local canPredict = (approaching and inPredict and highlightsMatch and (speed >= 12 or nearHitTime <= 0.25)) or closeHitSafe or veryFastHit
		if canPredict then
			local now = tick()
			if now - lastFire > 1 then
				lastFire = now
				task.defer(function()
					VirtualInputManager:SendKeyEvent(true, "F", false, game)
					VirtualInputManager:SendKeyEvent(false, "F", false, game)
				end)
			end
		end
	else
		ringPlayer.CFrame = CFrame.new(hrp.Position)
		ringPlayerNoUnit.CFrame = ringPlayer.CFrame
		ringBall.CFrame = ringPlayer.CFrame

		lastFire = 0
		ringLimited = false
		resetToken = resetToken + 1
		rangeText.Text = "0"
		if rangeMulti then
			rangeMulti.Text = "0x"
		end
		distanceText.Text = "0"
	end

	updateRingColors()
	applyVisualizerVisible(showViz)
end)

RunService.Stepped:Connect(function()
	if spam then
		VirtualInputManager:SendKeyEvent(true, "F", false, game)
		VirtualInputManager:SendKeyEvent(false, "F", false, game)
	end
end)
