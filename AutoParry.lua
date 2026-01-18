local Players = game:GetService("Players");
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local VirtualInputManager = game:GetService("VirtualInputManager");
local Stats = game:GetService("Stats");
local guiCHECKINGAHHHHH = function()
	return gethui and gethui() or (game:GetService("CoreGui")):FindFirstChildWhichIsA("ScreenGui") or game:GetService("CoreGui") or (game:GetService("Players")).LocalPlayer:FindFirstChildWhichIsA("PlayerGui");
end;
task.spawn(function()
	task.wait(1);
	for _,v in ipairs(workspace:GetDescendants()) do
		if v.Name:lower():find("leaderboard") then
			v:Destroy();
		end
	end
end)
do
	local ok, guiParent = pcall(guiCHECKINGAHHHHH);
	if ok and guiParent then
		for _, n in ipairs({
			"Range",
			"Distance"
			}) do
			local old = guiParent:FindFirstChild(n);
			if old then
				old:Destroy();
			end;
		end;
	end;
end;
local localPlayer = Players.LocalPlayer;
local character = localPlayer and localPlayer.Character;
local function waitForChildFast(parent, name)
	if not parent then
		return nil;
	end;
	return parent:FindFirstChild(name) or parent:WaitForChild(name, 5);
end;
(getgenv()).exe = true;
pcall(function()
	setfpscap(240);
end);
local VisualizerDefaults = {
	enabled = false,
	speedScale = 0.06,
	minSize = 5,
	maxSize = 200,
	predictMaxSize = 400,
	predictMinRadius = 10,
	pingPredictScale = 0.1,
	pingTimeScale = 0.001,
	transparency = 0.3,
	pinkTransparency = 0.55,
	distanceDivisor = 10,
	predictBase = 35,
	predictExtra = 5,
	profile = "Balanced"
};
local VisualizerProfiles = {
	Safe = {
		speedScale = 0.045,
		predictBase = 28,
		predictExtra = 4,
		distanceDivisor = 11,
		pingPredictScale = 0.09,
		pingTimeScale = 0.0012
	},
	Balanced = {
		speedScale = 0.06,
		predictBase = 35,
		predictExtra = 5,
		distanceDivisor = 10,
		pingPredictScale = 0.1,
		pingTimeScale = 0.001
	},
	Aggressive = {
		speedScale = 0.08,
		predictBase = 44,
		predictExtra = 7,
		distanceDivisor = 9,
		pingPredictScale = 0.12,
		pingTimeScale = 0.0009
	}
};
local profileOrder = {
	"Safe",
	"Balanced",
	"Aggressive"
};
local function normalizeVisualizerConfig()
	local raw = (getgenv()).visualizer;
	if type(raw) ~= "table" then
		raw = {
			enabled = raw == true
		};
	end;
	for key, defaultValue in pairs(VisualizerDefaults) do
		if raw[key] == nil then
			raw[key] = defaultValue;
		end;
	end;
	(getgenv()).visualizer = raw;
	return raw;
end;
local visualizerConfig = normalizeVisualizerConfig();
visualizerConfig.profile = visualizerConfig.profile or VisualizerDefaults.profile;
local speedScale;
local minSize;
local maxSize;
local predictMaxSize;
local predictMinRadius;
local pingPredictScale;
local pingTimeScale;
local ringBaseTransparency;
local ringPinkTransparency;
local distanceDivisor;
local predictBase;
local predictExtra;
local function refreshVisualizerDerived()
	local cfg = visualizerConfig;
	speedScale = cfg.speedScale or VisualizerDefaults.speedScale;
	minSize = cfg.minSize or VisualizerDefaults.minSize;
	maxSize = cfg.maxSize or VisualizerDefaults.maxSize;
	predictMaxSize = cfg.predictMaxSize or VisualizerDefaults.predictMaxSize;
	predictMinRadius = cfg.predictMinRadius or VisualizerDefaults.predictMinRadius;
	pingPredictScale = cfg.pingPredictScale or VisualizerDefaults.pingPredictScale;
	pingTimeScale = cfg.pingTimeScale or VisualizerDefaults.pingTimeScale;
	ringBaseTransparency = cfg.transparency or VisualizerDefaults.transparency;
	ringPinkTransparency = cfg.pinkTransparency or VisualizerDefaults.pinkTransparency;
	distanceDivisor = cfg.distanceDivisor or VisualizerDefaults.distanceDivisor;
	predictBase = cfg.predictBase or VisualizerDefaults.predictBase;
	predictExtra = cfg.predictExtra or VisualizerDefaults.predictExtra;
end;
refreshVisualizerDerived();
local spam = false;
local topbarIconInstance;
local spamOption;
local visualizerOption;
local modeOption;
local modeDropdown;
local updateRingColors = function()
end;
local function updateTopbarCaption()
	if not topbarIconInstance then
		return;
	end;
	local profileName = visualizerConfig.profile or VisualizerDefaults.profile;
	topbarIconInstance:setCaption("Mode: " .. profileName);
end;
local function isVisualizerEnabled()
	local cfg = visualizerConfig;
	if type(cfg) == "table" then
		return cfg.enabled ~= false;
	end;
	return false;
end;
local function updateSpamLabel()
	if not spamOption then
		return;
	end;
	spamOption:setLabel("Spam: " .. (spam and "ON" or "OFF"));
end;
local function updateVisualizerLabel()
	if not visualizerOption then
		return;
	end;
	visualizerOption:setLabel("Visualizer: " .. (isVisualizerEnabled() and "ON" or "OFF"));
end;
local function updateModeLabel()
	if not modeOption then
		return;
	end;
	local profileName = visualizerConfig.profile or VisualizerDefaults.profile;
	modeOption:setLabel("Mode: " .. profileName);
	updateTopbarCaption();
end;
local function toggleSpam()
	spam = not spam;
	updateSpamLabel();
	updateRingColors();
end;
local function toggleVisualizer()
	visualizerConfig.enabled = not isVisualizerEnabled();
	(getgenv()).visualizer = visualizerConfig;
	updateVisualizerLabel();
end;
local function applyProfile(name)
	local profile = VisualizerProfiles[name];
	if not profile then
		return;
	end;
	for key, value in pairs(profile) do
		visualizerConfig[key] = value;
	end;
	visualizerConfig.profile = name;
	refreshVisualizerDerived();
	updateModeLabel();
end;
local function findProfileIndex(name)
	for idx, profileName in ipairs(profileOrder) do
		if profileName == name then
			return idx;
		end;
	end;
	return nil;
end;
local function cycleProfile()
	local current = visualizerConfig.profile or VisualizerDefaults.profile;
	local idx = findProfileIndex(current) or 1;
	local nextIdx = idx % (#profileOrder) + 1;
	applyProfile(profileOrder[nextIdx]);
end;
local function setupTopbarIcon()
	local ok, IconModule = pcall(function()
		return (loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Icon.luau")))();
	end);
	if not ok or (not IconModule) then
		return;
	end;
	local existing = IconModule.getIcon and IconModule.getIcon("AutoParry");
	if existing then
		existing:destroy();
	end;
	local icon = IconModule.new();
	(((icon:setName("AutoParry")):setLabel("Auto Parry")):setImage("rbxassetid://395920626")):align("Center");
	topbarIconInstance = icon;
	local dropdown = icon:addDropdown();
	spamOption = (dropdown:new()):setLabel("Spam: OFF");
	spamOption:oneClick(function()
		toggleSpam();
	end);
	visualizerOption = (dropdown:new()):setLabel("Visualizer: OFF");
	visualizerOption:oneClick(function()
		toggleVisualizer();
	end);
	modeOption = (dropdown:new()):setLabel("Mode: " .. (visualizerConfig.profile or VisualizerDefaults.profile));
	modeOption:oneClick(function()
		cycleProfile();
	end);
	modeDropdown = modeOption:addDropdown();
	local function addModeEntry(name)
		local entry = (modeDropdown:new()):setLabel(name);
		entry:oneClick(function()
			applyProfile(name);
		end);
	end;
	for _, name in ipairs(profileOrder) do
		addModeEntry(name);
	end;
	updateSpamLabel();
	updateVisualizerLabel();
	updateModeLabel();
end;
setupTopbarIcon();
local function ensureIdentity()
	pcall(function()
		local level = 8;
		if setidentity then
			setidentity(level);
		elseif setthreadidentity then
			setthreadidentity(level);
		elseif syn and syn.set_thread_identity then
			syn.set_thread_identity(level);
		elseif set_thread_identity then
			set_thread_identity(level);
		end;
	end);
end;
if (getgenv()).AutoParryCleanup then
	(getgenv()).AutoParryCleanup();
end;
local function colorsClose(a, b, tol)
	if not (a and b) then
		return false;
	end;
	tol = tol or 0.05;
	return math.abs(a.R - b.R) <= tol and math.abs(a.G - b.G) <= tol and math.abs(a.B - b.B) <= tol;
end;
local function round(num, places)
	local mult = 10 ^ (places or 0);
	return math.floor((num * mult + 0.5)) / mult;
end;
local function getBall()
	local balls = workspace:FindFirstChild("Balls");
	if not balls then
		return nil;
	end;
	local hrp = character and character:FindFirstChild("HumanoidRootPart");
	local closest, bestDist;
	for _, child in ipairs(balls:GetChildren()) do
		if child:IsA("BasePart") then
			if hrp then
				local dist = (child.Position - hrp.Position).Magnitude;
				if not bestDist or dist < bestDist then
					closest = child;
					bestDist = dist;
				end;
			else
				closest = child;
			end;
		end;
	end;
	return closest;
end;
local function newRing(name, color)
	ensureIdentity();
	local part = Instance.new("Part");
	part.Name = name;
	part.Anchored = true;
	part.Size = Vector3.new(10, 0.4, 10);
	part.Color = color;
	part.CanCollide = false;
	part.CastShadow = false;
	part.CanQuery = false;
	part.Transparency = ringBaseTransparency;
	local mesh = Instance.new("SpecialMesh");
	mesh.MeshType = Enum.MeshType.FileMesh;
	mesh.MeshId = "rbxassetid://471124075";
	mesh.Scale = Vector3.new(0.067, 0.1, 0.067);
	mesh.Parent = part;
	part.Parent = workspace;
	return part;
end;
local ringPlayer = newRing("Visualizer", Color3.new(1, 0, 0));
local ringBall = ringPlayer:Clone();
ringBall.Name = "VisualizerFollowBall";
ringBall.Parent = workspace;
local ringPlayerNoUnit = ringPlayer:Clone();
ringPlayerNoUnit.Name = "VisualizerNoUnit";
ringPlayerNoUnit.Color = Color3.new(1, 0, 1);
ringPlayerNoUnit.Transparency = 0.55;
ringPlayerNoUnit.Parent = workspace;
local ringSizeState = {};
local function rescaleRing(part, diameter, overrideMax, dt)
	local target = math.clamp(diameter or 10, minSize, overrideMax or maxSize);
	local current = ringSizeState[part] or part and part.Size.X or target;
	local alpha = dt and math.clamp(dt / 0.05, 0.08, 0.6) or 0.35;
	local size = current + (target - current) * alpha;
	ringSizeState[part] = size;
	part.Size = Vector3.new(size, 0.4, size);
	local mesh = part:FindFirstChildOfClass("SpecialMesh");
	if mesh then
		local factor = size / 10;
		mesh.Scale = Vector3.new(0.067 * factor, 0.1, 0.067 * factor);
		mesh.Offset = Vector3.new(0, -(0.2 * factor - 0.2), 0);
	end;
	return target;
end;
local function newBillboard(name, size, studsOffset, includeMulti)
	ensureIdentity();
	local gui = Instance.new("BillboardGui");
	gui.Name = name;
	gui.Parent = guiCHECKINGAHHHHH();
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	gui.LightInfluence = 1;
	gui.Size = size;
	gui.StudsOffset = studsOffset or Vector3.new(0, 5, 0);
	gui.Enabled = true;
	gui.AlwaysOnTop = true;
	local text = Instance.new("TextLabel");
	text.Name = "Text";
	text.Parent = gui;
	text.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	text.BackgroundTransparency = 1;
	text.BorderColor3 = Color3.fromRGB(0, 0, 0);
	text.BorderSizePixel = 0;
	text.Size = UDim2.new(1, 0, 0.55, 0);
	text.Position = UDim2.new(0, 0, 0.45, 0);
	text.Font = Enum.Font.FredokaOne;
	text.Text = "100";
	text.TextColor3 = Color3.fromRGB(255, 255, 255);
	text.TextScaled = true;
	text.TextSize = 14;
	text.TextStrokeTransparency = 0;
	text.TextWrapped = true;
	local textMulti;
	if includeMulti then
		textMulti = text:Clone();
		textMulti.Name = "TextMulti";
		textMulti.TextTransparency = 0.5;
		textMulti.TextStrokeTransparency = 0.5;
		textMulti.Size = UDim2.new(1, 0, 0.45, 0);
		textMulti.Position = UDim2.new(0, 0, 0, 0);
		textMulti.Text = "1x";
		textMulti.Parent = gui;
	end;
	return gui, text, textMulti;
end;
local rangeGui, rangeText, rangeMulti = newBillboard("Range", UDim2.new(3, 0, 3, 0), Vector3.new(0, 5, 0), true);
local distanceGui, distanceText = newBillboard("Distance", UDim2.new(2, 0, 2, 0), Vector3.new(0, 5, 0), false);
local function applyVisualizerVisible(show)
	rangeGui.Enabled = show;
	distanceGui.Enabled = show;
	ringPlayer.Transparency = show and ringBaseTransparency or 1;
	ringBall.Transparency = show and ringBaseTransparency or 1;
	ringPlayerNoUnit.Transparency = show and ringPinkTransparency or 1;
end;
local visualizerAttached = true;
local connections = {};
local function trackConnection(conn)
	table.insert(connections, conn);
	return conn;
end;
local function cleanup()
	for _, c in ipairs(connections) do
		pcall(function()
			c:Disconnect();
		end);
	end;
	connections = {};
	pcall(function()
		rangeGui.Parent = nil;
		distanceGui.Parent = nil;
	end);
	pcall(function()
		ringPlayer:Destroy();
		ringBall:Destroy();
		ringPlayerNoUnit:Destroy();
	end);
	(getgenv()).AutoParryCleanup = nil;
end;
(getgenv()).AutoParryCleanup = cleanup;
local function attachVisualizer(hasBall)
	if hasBall then
		if not visualizerAttached then
			local guiParent = guiCHECKINGAHHHHH();
			rangeGui.Parent = guiParent;
			distanceGui.Parent = guiParent;
			ringPlayer.Parent = workspace;
			ringBall.Parent = workspace;
			ringPlayerNoUnit.Parent = workspace;
			visualizerAttached = true;
		end;
	elseif visualizerAttached then
		rangeGui.Parent = nil;
		distanceGui.Parent = nil;
		rangeGui.Adornee = nil;
		distanceGui.Adornee = nil;
		ringPlayer.Parent = nil;
		ringBall.Parent = nil;
		ringPlayerNoUnit.Parent = nil;
		visualizerAttached = false;
	end;
end;
local lastFire = 0;
local resetToken = 0;
local parCd = 1.75;
local nextPar = 0;
local wasInPredict = false;
local ringLimited = false;
local lastBallSamples = {};
local lastBallVel = {};
local lastBallMoveTime = {};
local closeParryBlocked = {};
local smoothedSpeed = {};
local currentBall = nil;
local lastHighlightMatch = false;
local lastCharHighlightEnabled = false;
local lastParryPerBall = {};
local predictEnterAt = {};
local targetedSince = {};
local function DoParry()
	VirtualInputManager:SendKeyEvent(true, "F", false, game);
	VirtualInputManager:SendKeyEvent(false, "F", false, game);
end;
local function getHighlightColor(inst)
	if not inst then
		return nil, nil;
	end;
	local best;
	local bestColor;
	local bestTrans = math.huge;
	for _, child in ipairs(inst:GetChildren()) do
		if child:IsA("Highlight") then
			local ft = child.FillTransparency or 1;
			if child.Enabled ~= false and ft < bestTrans then
				best = child;
				bestColor = child.FillColor;
				bestTrans = ft;
			end;
		end;
	end;
	if not best then
		best = inst:FindFirstChildOfClass("Highlight") or inst:FindFirstChild("Highlight");
		if best and best.Enabled ~= false then
			bestColor = best.FillColor;
		else
			best = nil;
			bestColor = nil;
		end;
	end;
	return best, bestColor;
end;
local function isBallTargetingYou(ball, char)
	local ballHighlight, ballColor = getHighlightColor(ball);
	local charHighlight, charColor = getHighlightColor(char);
	local targetedColor = ballHighlight and charHighlight and ballColor and charColor and ballHighlight.Enabled ~= false and charHighlight.Enabled ~= false and (ballHighlight.FillTransparency or 0) < 0.9 and (charHighlight.FillTransparency or 0) < 0.9 and colorsClose(ballColor, charColor, 0.05);
	local targeted = targetedColor;
	return targeted, ballHighlight, charHighlight, ballColor, charColor;
end;
local function getBallTargetAttr(ball)
	if not ball then
		return nil;
	end;
	local attrs = ball:GetAttributes();
	for k, v in pairs(attrs) do
		if typeof(k) == "string" and k:lower() == "target" then
			return v;
		end;
	end;
	return nil;
end;
local function isBallTargetingYouAttr(ball, char)
	local v = getBallTargetAttr(ball);
	if not v then
		return false;
	end;
	if typeof(v) == "Instance" then
		if char and v == char then
			return true;
		end;
		if v:IsA("Player") and localPlayer and v == localPlayer then
			return true;
		end;
	elseif typeof(v) == "string" then
		local plr = Players:GetPlayerFromCharacter(char) or localPlayer;
		if not plr then
			return false;
		end;
		local lower = v:lower();
		local n1 = plr.Name and plr.Name:lower() or "";
		local n2 = plr.DisplayName and plr.DisplayName:lower() or "";
		if (n1 ~= "" and lower:find(n1, 1, true)) or (n2 ~= "" and lower:find(n2, 1, true)) then
			return true;
		end;
	end;
	return false;
end;
local function scheduleReset()
	resetToken = resetToken + 1;
	local token = resetToken;
	lastFire = 0;
	task.delay(0.001, function()
		if resetToken == token then
			lastFire = 0;
		end;
	end);
end;
updateRingColors = function()
	if ringLimited then
		ringPlayer.Color = Color3.new(0, 1, 0);
	elseif spam then
		ringPlayer.Color = Color3.new(1, 0.7, 0);
	else
		ringPlayer.Color = Color3.new(1, 0, 0);
	end;
end;
trackConnection(UserInputService.InputBegan:Connect(function(input, gpe)
	if input.KeyCode == Enum.KeyCode.X and (not gpe) then
		toggleSpam();
	end;
end));
updateRingColors();
local function updateGuiTargets(hrp, ball)
	if ball then
		rangeGui.Adornee = hrp;
		distanceGui.Adornee = ball;
	else
		rangeGui.Adornee = nil;
		distanceGui.Adornee = nil;
	end;
end;
trackConnection(RunService.RenderStepped:Connect(function(dt)
	character = localPlayer.Character or character;
	local hrp = waitForChildFast(character, "HumanoidRootPart");
	local ball = getBall();
	attachVisualizer(ball ~= nil);
	local showViz = isVisualizerEnabled();
	if not (hrp and hrp.Position) then
		return;
	end;
	updateGuiTargets(hrp, ball);
	if ball and ball.Position then
		if ball ~= currentBall then
			currentBall = ball;
			lastBallSamples = {};
			lastBallVel = {};
			lastBallMoveTime = {};
			closeParryBlocked = {};
			smoothedSpeed = {};
			predictEnterAt = {};
			ringSizeState = {};
			targetedSince = {};
		end;
		local lookAtBall = CFrame.lookAt(hrp.Position, ball.Position);
		ringPlayer.CFrame = lookAtBall;
		ringPlayerNoUnit.CFrame = lookAtBall;
		ringBall.CFrame = CFrame.new(ball.Position);
		local rawDist = (ball.Position - hrp.Position).Magnitude;
		local dist = rawDist / distanceDivisor;
		local now = tick();
		local velocity = ball.AssemblyLinearVelocity or ball.Velocity or Vector3.zero;
		local lastVel = lastBallVel[ball] or Vector3.zero;
		local sample = lastBallSamples[ball];
		local sampleDt = sample and now - sample.t or 0;
		local posDelta = sample and ball.Position - sample.pos or Vector3.zero;
		if not sample or sampleDt > 0.4 then
			sample = {
				pos = ball.Position,
				t = now
			};
			sampleDt = 0;
			posDelta = Vector3.zero;
		end;
		local manualVel = sampleDt > 0 and posDelta / math.max(sampleDt, 0.001) or velocity;
		local chosenVel = velocity;
		if chosenVel.Magnitude < 0.001 or chosenVel.Magnitude < manualVel.Magnitude * 0.5 then
			chosenVel = manualVel;
		end;
		local lastMoveTime = lastBallMoveTime[ball] or 0;
		if chosenVel.Magnitude >= 4 then
			lastBallMoveTime[ball] = now;
		elseif lastVel.Magnitude > 8 and now - lastMoveTime < 0.2 then
			chosenVel = lastVel:Lerp(chosenVel, 0.15);
		end;
		local smoothingAlpha = sampleDt > 0 and math.clamp(sampleDt / 0.04, 0.35, 0.9) or 0.45;
		lastBallSamples[ball] = {
			pos = ball.Position,
			t = now
		};
		velocity = lastVel:Lerp(chosenVel, smoothingAlpha);
		local speed = velocity.Magnitude;
		local prevSpeed = smoothedSpeed[ball] or speed;
		local speedLerp = math.clamp((dt or 0.016) / 0.03, 0.35, 0.95);
		speed = prevSpeed + (speed - prevSpeed) * speedLerp;
		smoothedSpeed[ball] = speed;
		lastBallVel[ball] = velocity;
		local baseSize = 10 + speed * speedScale * 2;
		local appliedPlayerSize = rescaleRing(ringPlayer, baseSize, maxSize, dt);
		ringLimited = appliedPlayerSize >= maxSize - 0.1;
		local multiplier = 0.12;
		if speed < 60 then
			multiplier = 0.06;
		elseif speed > 120 then
			multiplier = 0.2;
		elseif speed > 80 then
			multiplier = 0.16;
		end;
		local effectiveSpeed = math.max(speed - 5, 0);
		local speedBoost = 0.05;
		if speed > 160 then
			speedBoost = 0.12;
		elseif speed > 120 then
			speedBoost = 0.09;
		elseif speed > 80 then
			speedBoost = 0.07;
		end;
		local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue();
		local baseFactor = math.clamp(predictBase / 50, 0.25, 2);
		local predictRadiusNoPing = predictMinRadius + predictExtra * baseFactor + effectiveSpeed * (multiplier + speedBoost) * baseFactor;
		local predictRadius = predictRadiusNoPing + ping * pingPredictScale;
		local predictEntryInset = math.clamp(predictRadius * 0.025 + ping * 0.01, 1, 6);
		local preEntryMargin = math.clamp(predictRadius * 0.12 + ping * 0.018, 3, 14);
		local parryPredictRadius = predictRadius + preEntryMargin;
		local appliedPlayerPredict = rescaleRing(ringPlayer, predictRadiusNoPing * 2, maxSize, dt);
		ringLimited = appliedPlayerPredict >= maxSize - 0.1;
		local appliedPredictSize = rescaleRing(ringPlayerNoUnit, predictRadius * 2, predictMaxSize, dt);
		ringPlayerNoUnit.Transparency = ringPinkTransparency;
		rescaleRing(ringBall, baseSize, nil, dt);
		local inPredict = rawDist <= predictRadius;
		local nearPredict = rawDist <= predictRadius + preEntryMargin;
		local inParryPredict = rawDist <= parryPredictRadius;
		local displayedPredict = predictRadius;
		rangeText.Text = tostring(round(displayedPredict, 1));
		if rangeMulti then
			rangeMulti.Text = string.format("%.1fx", round(displayedPredict / 100, 1));
		end;
		distanceText.Text = tostring(round(dist, 1));
		if nearPredict then
			predictEnterAt[ball] = predictEnterAt[ball] or now;
			resetToken = resetToken + 1;
		elseif wasInPredict then
			predictEnterAt[ball] = nil;
			scheduleReset();
		else
			predictEnterAt[ball] = nil;
		end;
		wasInPredict = nearPredict;
		local settleTime = math.clamp(0.003 + ping * 0.0002, 0.002, 0.014);
		local settledInPredict = nearPredict and predictEnterAt[ball] and now - predictEnterAt[ball] >= settleTime;
		local targeted, ballHighlight, charHighlight, ballColor, charColor = isBallTargetingYou(ball, character);
		local charHighlightEnabled = charHighlight and charHighlight.Enabled ~= false;

		if charHighlightEnabled and (not lastCharHighlightEnabled) then
			lastParryPerBall[ball] = -math.huge;
		end;

		local targetAge = targeted and targetedSince[ball] and now - targetedSince[ball] or math.huge;
		local hasTargetLock = targeted and targetedSince[ball] ~= nil;
		local highlightsMatch = targeted;

		if highlightsMatch and (not lastHighlightMatch) then
			lastParryPerBall[ball] = -math.huge;
			targetedSince[ball] = now;
		elseif not highlightsMatch and lastHighlightMatch then
			lastParryPerBall[ball] = -math.huge;
			targetedSince[ball] = nil;
			local stillAttrTarget = isBallTargetingYouAttr(ball, character);
			if not stillAttrTarget then
				nextPar = 0;
			end;
		end;

		lastHighlightMatch = highlightsMatch;
		lastCharHighlightEnabled = charHighlightEnabled;
		local approaching = false;
		if speed >= 8 then
			local toYou = hrp.Position - ball.Position;
			local mag = toYou.Magnitude;
			if mag > 0.001 then
				local dirToYou = toYou / mag;
				local velDir = speed > 0.001 and velocity.Unit or (-dirToYou);
				local dot = dirToYou:Dot(velDir);
				approaching = dot > 0.4;
			end;
		end;
		local toRingTime = approaching and speed > 1 and math.max((rawDist - parryPredictRadius), 0) / speed or math.huge;
		local closeHit = targeted and rawDist <= math.max(10, appliedPredictSize * 0.45);
		local nearHitTime = speed > 1 and rawDist / speed or math.huge;
		local veryFastHit = targeted and nearHitTime <= 0.18 + ping * pingTimeScale;
		local closeHitSafe = closeHit and (nearHitTime <= 0.3 or speed >= 25);
		local targetSnap = targeted and inParryPredict and settledInPredict and (nearHitTime <= 0.6 or rawDist <= math.max(10, parryPredictRadius * 0.6));
		local innerEmergency = targeted and rawDist <= math.max(8, predictRadius * 0.4);
		local fastApproach = targeted and approaching and (nearHitTime <= 0.22 or rawDist <= parryPredictRadius * 0.95);
		local parryTriggered = false;
		if innerEmergency and hasTargetLock and (not closeParryBlocked[ball]) then
			local nowInner = tick();
			local lastBallFire = lastParryPerBall[ball] or (-math.huge);
			if nowInner >= nextPar and nowInner - lastBallFire > 0.05 then
				nextPar = nowInner + parCd;
				lastFire = nowInner;
				lastParryPerBall[ball] = nowInner;
				closeParryBlocked[ball] = true;
				parryTriggered = true;
				task.defer(DoParry);
				return;
			end;
		end;
		local outsideRing = rawDist >= math.max(predictRadius - math.max(preEntryMargin * 1.1, 2.5), predictRadius * 0.85);
		local ringEdgeSafe = innerEmergency or rawDist >= parryPredictRadius * 0.6 or nearHitTime <= 0.2 or veryFastHit;
		local ringTimeSoon = toRingTime <= 0.55 + ping * 0.003;
		local function attemptParry()
			if parryTriggered then
				return;
			end;
			if closeParryBlocked[ball] and (rawDist > parryPredictRadius * 1.15 or tick() - (lastParryPerBall[ball] or 0) > 1.2) then
				closeParryBlocked[ball] = nil;
			end;
			local inCloseBlock = closeParryBlocked[ball] and rawDist <= parryPredictRadius * 1.15;
			local canPredict = approaching and nearPredict and settledInPredict and highlightsMatch and hasTargetLock and (outsideRing or fastApproach) and (speed >= 12 or nearHitTime <= 0.25 or ringTimeSoon or fastApproach) or closeHitSafe and hasTargetLock or veryFastHit and hasTargetLock or targetSnap and hasTargetLock or innerEmergency and hasTargetLock;
			canPredict = canPredict and ringEdgeSafe;
			canPredict = canPredict and (not inCloseBlock);
			if canPredict then
				local nowTry = tick();
				local lastBallFire = lastParryPerBall[ball] or (-math.huge);
				local minBallCooldown = highlightsMatch and 0.7 or 0.35;
				if nowTry >= nextPar and nowTry - lastBallFire > minBallCooldown then
					nextPar = nowTry + parCd;
					lastFire = nowTry;
					lastParryPerBall[ball] = nowTry;
					if rawDist <= parryPredictRadius * 0.8 then
						closeParryBlocked[ball] = true;
					end;
					parryTriggered = true;
					task.defer(DoParry);
				end;
			end;
		end;
		task.spawn(attemptParry);
		task.spawn(function()
			if parryTriggered then
				return;
			end;
			if targeted then
				return;
			end;
			if not nearPredict then
				return;
			end;
			if closeParryBlocked[ball] then
				return;
			end;

			local attrTargeted = isBallTargetingYouAttr(ball, character);
			if not attrTargeted then
				return;
			end;

			local nowAttr = tick();
			local lastBallFire = lastParryPerBall[ball] or (-math.huge);
			if nowAttr >= nextPar and nowAttr - lastBallFire > 0.9 then
				if rawDist <= math.max(10, parryPredictRadius * 0.7) then
					nextPar = nowAttr + parCd;
					lastFire = nowAttr;
					lastParryPerBall[ball] = nowAttr;
					parryTriggered = true;
					task.defer(DoParry);
				end;
			end;
		end);
	else
		ringPlayer.CFrame = CFrame.new(hrp.Position);
		ringPlayerNoUnit.CFrame = ringPlayer.CFrame;
		ringBall.CFrame = ringPlayer.CFrame;
		currentBall = nil;
		lastBallSamples = {};
		lastBallVel = {};
		lastBallMoveTime = {};
		smoothedSpeed = {};
		closeParryBlocked = {};
		predictEnterAt = {};
		lastFire = 0;
		nextPar = 0;
		ringLimited = false;
		resetToken = resetToken + 1;
		rangeText.Text = "0";
		if rangeMulti then
			rangeMulti.Text = "0x";
		end;
		distanceText.Text = "0";
	end;
	updateRingColors();
	applyVisualizerVisible(showViz);
end));
trackConnection(RunService.Stepped:Connect(function()
	if spam then
		task.defer(DoParry);
	end;
end));
