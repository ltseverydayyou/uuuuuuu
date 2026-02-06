local Players = game:GetService("Players");
local RunService = game:GetService("RunService");
local UserInputService = game:GetService("UserInputService");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Stats = game:GetService("Stats");
local GuiService = game:GetService("GuiService");

local IsOnMobile=(function()
	local platform=UserInputService:GetPlatform()
	if platform==Enum.Platform.IOS or platform==Enum.Platform.Android or platform==Enum.Platform.AndroidTV or platform==Enum.Platform.Chromecast or platform==Enum.Platform.MetaOS then
		return true
	end
	if platform==Enum.Platform.None then
		return UserInputService.TouchEnabled and not (UserInputService.KeyboardEnabled or UserInputService.MouseEnabled)
	end
	return false
end)()
local IsOnPC=(function()
	local platform=UserInputService:GetPlatform()
	if platform==Enum.Platform.Windows or platform==Enum.Platform.OSX or platform==Enum.Platform.Linux or platform==Enum.Platform.SteamOS or platform==Enum.Platform.UWP or platform==Enum.Platform.DOS or platform==Enum.Platform.BeOS then
		return true
	end
	if platform==Enum.Platform.None then
		return UserInputService.KeyboardEnabled or UserInputService.MouseEnabled
	end
	return false
end)()

local connections = {}
local touchOpt = nil
local touchLock = false

local connect = function(name, connection)
	connections[name] = connections[name] or {}
	table.insert(connections[name], connection)
	return connection
end

local disconnect = function(name)
	if connections[name] then
		for _, conn in ipairs(connections[name]) do
			conn:Disconnect()
		end
		connections[name] = nil
	end
end

local LastInputConns = {}
local PreferredInputConns = {}
local LastInputPatched = false

local ApplyLastInputPatch = function()
	if not IsOnMobile then
		return
	end

	if getconnections and not LastInputPatched then
		table.clear(LastInputConns)
		table.clear(PreferredInputConns)

		for _, c in ipairs(getconnections(UserInputService.LastInputTypeChanged)) do
			table.insert(LastInputConns, c)
			pcall(function()
				if c.Disable then
					c:Disable()
				end
			end)
		end

		local prefSignal
		pcall(function()
			prefSignal = UserInputService:GetPropertyChangedSignal("PreferredInput")
		end)

		if prefSignal then
			for _, c in ipairs(getconnections(prefSignal)) do
				table.insert(PreferredInputConns, c)
				pcall(function()
					if c.Disable then
						c:Disable()
					end
				end)
			end
		end
	end

	pcall(function()
		GuiService.TouchControlsEnabled = true
	end)

	if connect and disconnect then
		disconnect("_LastInputTouch")
		connect("_LastInputTouch", GuiService:GetPropertyChangedSignal("TouchControlsEnabled"):Connect(function()
			if IsOnMobile then
				pcall(function()
					GuiService.TouchControlsEnabled = true
				end)
			end
		end))
	else
		GuiService:GetPropertyChangedSignal("TouchControlsEnabled"):Connect(function()
			if IsOnMobile then
				pcall(function()
					GuiService.TouchControlsEnabled = true
				end)
			end
		end)
	end

	LastInputPatched = true
end

local RevertLastInputPatch = function()
	if disconnect then
		disconnect("_LastInputTouch")
	end

	if getconnections then
		if LastInputConns and #LastInputConns > 0 then
			for _, c in ipairs(LastInputConns) do
				pcall(function()
					if c.Enable then
						c:Enable()
					end
				end)
			end
		end

		if PreferredInputConns and #PreferredInputConns > 0 then
			for _, c in ipairs(PreferredInputConns) do
				pcall(function()
					if c.Enable then
						c:Enable()
					end
				end)
			end
		end
	end

	LastInputPatched = false
end

local guiCHECKINGAHHHHH = function()
	return gethui and gethui() or (game:GetService("CoreGui")):FindFirstChildWhichIsA("ScreenGui") or game:GetService("CoreGui") or (game:GetService("Players")).LocalPlayer:FindFirstChildWhichIsA("PlayerGui");
end;
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
local Framework;
local Net;
local SwordController;
local SoundController;
local FRemote;
do
	local okFW, fw = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Framework"));
	end);
	if okFW and fw then
		Framework = fw;
		local okNet, svc = pcall(function()
			return Framework:Fetch("SwordService");
		end);
		if okNet then
			Net = svc;
		end;
		local okSw, swc = pcall(function()
			return Framework:Get("SwordController");
		end);
		if okSw then
			SwordController = swc;
		end;
		local okSnd, sdc = pcall(function()
			return Framework:Get("SoundController");
		end);
		if okSnd then
			SoundController = sdc;
		end;
	end;
	local okRf, rf = pcall(function()
		return (ReplicatedStorage:WaitForChild("Framework")):WaitForChild("RemoteFunction");
	end);
	if okRf then
		FRemote = rf;
	end;
end;
local function waitForChildFast(parent, name)
	if not parent then
		return nil;
	end;
	return parent:FindFirstChild(name) or parent:WaitForChild(name, 5);
end;
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
	profile = "Balance"
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
	Balance = {
		speedScale = 0.06,
		predictBase = 35,
		predictExtra = 5,
		distanceDivisor = 10,
		pingPredictScale = 0.1,
		pingTimeScale = 0.001
	},
	Brutal = {
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
	"Balance",
	"Brutal"
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
local resetToken = 0;
local parCd = 1.6;
local nextPar = 0;
local lastParryTime = 0;
local curFrame = 0;
local lastParryFrame = -1;
local lastQueueTime = 0;
local wasInPredict = {};
local ringLimited = false;
local lastBallSamples = {};
local lastBallVel = {};
local lastBallMoveTime = {};
local closeParryBlocked = {};
local smoothedSpeed = {};
local lastHighlightMatch = {};
local lastCharHighlightEnabled = {};
local lastParryPerBall = {};
local predictEnterAt = {};
local targetedSince = {};
local lastAttrTargeted = {};
local baitUntil = {};
local awaySince = {};
local lastAwayFlag = {};
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
local apEnabled = true;
local topbarIconInstance;
local apOption;
local spamOption;
local visualizerOption;
local modeOption;
local modeDropdown;
local apState = "Idle";
local debugEnabled = false;
local debugIconInstance;
local debugToggleOption;
local debugStateOption;
local debugTargetOption;
local debugBallsOption;
local debugCooldownOption;
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
local function updateApLabel()
	if not apOption then
		return;
	end;
	apOption:setLabel("AP: " .. (apEnabled and "ON" or "OFF"));
end;
local function updateVisualizerLabel()
	if not visualizerOption then
		return;
	end;
	visualizerOption:setLabel("Visual: " .. (isVisualizerEnabled() and "ON" or "OFF"));
end;
local function updateModeLabel()
	if not modeOption then
		return;
	end;
	local profileName = visualizerConfig.profile or VisualizerDefaults.profile;
	modeOption:setLabel("Mode: " .. profileName);
	updateTopbarCaption();
end;
local function updateDebugMenu(numBalls, anyTargeted, nowTime)
	if not debugIconInstance then
		return;
	end;
	if debugStateOption then
		debugStateOption:setLabel("State: " .. apState);
	end;
	if debugTargetOption then
		debugTargetOption:setLabel("Targeted: " .. (anyTargeted and "Yes" or "No"));
	end;
	if debugBallsOption then
		debugBallsOption:setLabel("Balls: " .. tostring((numBalls or 0)));
	end;
	if debugCooldownOption then
		local nowT = nowTime or tick();
		local cd = math.max((nextPar or 0) - nowT, 0);
		debugCooldownOption:setLabel(string.format("CD: %.2fs", cd));
	end;
	if debugIconInstance.setCaption then
		debugIconInstance:setCaption(apState);
	end;
end;
local function iconHide(ico)
	if ico and ico.setEnabled then
		ico:setEnabled(false);
	end;
end;
local function iconShow(ico)
	if ico and ico.setEnabled then
		ico:setEnabled(true);
	end;
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
local function setupDebugIcon(IconModule)
	local existing = IconModule.getIcon and IconModule.getIcon("APDebug");
	if existing then
		iconHide(existing);
	end;
	local icon = IconModule.new();
	icon:disableOverlay(true);
	((icon:setName("APDebug")):setImage("rbxassetid://11348555035")):align("Right");
	debugIconInstance = icon;
	local menu = icon:addMenu();
	debugStateOption = (menu:new()):setLabel("State: " .. apState);
	debugTargetOption = (menu:new()):setLabel("Targeted: No");
	debugBallsOption = (menu:new()):setLabel("Balls: 0");
	debugCooldownOption = (menu:new()):setLabel("CD: 0.00s");
	if icon.setCaption then
		icon:setCaption(apState);
	end;
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
		iconHide(existing);
	end;
	local icon = IconModule.new();
	(((icon:setName("AutoParry")):setLabel("Auto Parry")):setImage("rbxassetid://11322093465")):align("Center");
	topbarIconInstance = icon;
	local dropdown = icon:addMenu();
	apOption = (dropdown:new()):setLabel("AP: ON");
	apOption:oneClick(function()
		apEnabled = not apEnabled;
		updateApLabel();
	end);
	visualizerOption = (dropdown:new()):setLabel("Visual: OFF");
	visualizerOption:oneClick(function()
		toggleVisualizer();
	end);
	modeOption = (dropdown:new()):setLabel("Mode: " .. (visualizerConfig.profile or VisualizerDefaults.profile));
	modeOption:oneClick(function()
		cycleProfile();
	end);
	modeDropdown = modeOption:addMenu();
	spamOption = (dropdown:new()):setLabel("Spam: OFF");
	spamOption:oneClick(function()
		toggleSpam();
	end);
	debugToggleOption = (dropdown:new()):setLabel("Debug: OFF");
	debugToggleOption:oneClick(function()
		debugEnabled = not debugEnabled;
		if debugEnabled then
			if debugIconInstance then
				iconShow(debugIconInstance);
			else
				setupDebugIcon(IconModule);
			end;
			updateDebugMenu(0, false, tick());
		else
			iconHide(debugIconInstance);
		end;
		if debugToggleOption then
			debugToggleOption:setLabel("Debug: " .. (debugEnabled and "ON" or "OFF"));
		end;
	end);

	if IsOnMobile then
		touchOpt = (dropdown:new()):setLabel("TouchLock: " .. (touchLock and "ON" or "OFF"))
		touchOpt:oneClick(function()
			touchLock = not touchLock
			if touchLock then
				ApplyLastInputPatch()
			else
				RevertLastInputPatch()
			end
			if touchOpt then
				touchOpt:setLabel("TouchLock: " .. (touchLock and "ON" or "OFF"))
			end
		end)
	end

	local function addModeEntry(name)
		local entry = (modeDropdown:new()):setLabel(name);
		entry:oneClick(function()
			applyProfile(name);
		end);
	end;
	for _, name in ipairs(profileOrder) do
		addModeEntry(name);
	end;
	updateApLabel();
	updateSpamLabel();
	updateVisualizerLabel();
	updateModeLabel();
	updateDebugMenu(0, false, tick());
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
if getgenv().AutoParryCleanup then
	getgenv().AutoParryCleanup();
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
local ringPlayer = newRing("Visualizer", Color3.new(1, 0, 0))
local ringPlayerNoUnit = ringPlayer:Clone()
ringPlayerNoUnit.Name = "VisualizerNoUnit"
ringPlayerNoUnit.Color = Color3.new(1, 0, 1)
ringPlayerNoUnit.Transparency = 0.55
ringPlayerNoUnit.Parent = workspace

local ringSizeState = {}
local ballVis = {}
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
local rangeGui, rangeText, rangeMulti = newBillboard("Range", UDim2.new(3, 0, 3, 0), Vector3.new(0, 5, 0), true)

local ballsMap = {}
local ballList = {}
local mainRealBall = {}
local ballConns = {}
local containerConns = {}

local function addBall(b)
	if ballsMap[b] or not (b and b:IsA("BasePart") and b.Parent) then
		return
	end
	ballsMap[b] = true
end

local function removeBall(b)
	if not ballsMap[b] then
		return
	end
	ballsMap[b] = nil
	mainRealBall[b] = nil
end

local function cleanupBallVisual(ball)
	local v = ballVis[ball]
	if not v then
		return
	end
	ballVis[ball] = nil
	if v.gui then
		v.gui:Destroy()
	end
	if v.ring then
		v.ring:Destroy()
	end
end

local function attachContainer(c)
	if not (c and c.Parent) or ballConns[c] then
		return
	end

	if c:IsA("BasePart") then
		addBall(c)
	end

	for _, d in ipairs(c:GetDescendants()) do
		if d:IsA("BasePart") then
			addBall(d)
		end
	end

	local added = c.DescendantAdded:Connect(function(d)
		if d:IsA("BasePart") then
			addBall(d)
		end
	end)

	local removing = c.DescendantRemoving:Connect(function(d)
		if d:IsA("BasePart") then
			removeBall(d)
		end
	end)

	local ancestry = c.AncestryChanged:Connect(function(inst, parent)
		if inst == c and parent == nil and c:IsA("BasePart") then
			removeBall(c)
		end
	end)

	ballConns[c] = {added, removing, ancestry}
end

local function trackNamedContainer(parent, name)
	if not (typeof(parent) == "Instance" and type(name) == "string") then
		return
	end
	for _, inst in ipairs(parent:GetDescendants()) do
		if inst.Name == name then
			attachContainer(inst)
		end
	end
	local direct = parent:FindFirstChild(name)
	if direct then
		attachContainer(direct)
	end
	if containerConns[parent] then
		return
	end
	local c = parent.DescendantAdded:Connect(function(ch)
		if ch.Name == name then
			attachContainer(ch)
		end
	end)
	containerConns[parent] = c
end

local function setupBallTracking()
	local p = visualizerConfig and visualizerConfig.path
	local paths

	if p == nil then
		paths = { { parent = workspace, name = "Balls" } }
	elseif typeof(p) == "table" then
		if p[1] == nil and (p.parent or p.container or p.name) then
			paths = { p }
		else
			paths = p
		end
	else
		paths = { p }
	end

	for _, src in ipairs(paths) do
		local t = typeof(src)
		if t == "Instance" then
			attachContainer(src)
		elseif t == "table" then
			local par = src.parent
			local name = src.name
			local container = src.container
			if typeof(container) == "Instance" then
				attachContainer(container)
			elseif typeof(par) == "Instance" and type(name) == "string" then
				trackNamedContainer(par, name)
			end
		end
	end
end

local function isVisualizerPart(p)
	if not p or not p:IsA("BasePart") then
		return false
	end
	local tr = p.Transparency or 0
	local ltm = 0
	pcall(function()
		ltm = p.LocalTransparencyModifier or 0
	end)
	return tr < 0.95 and ltm < 0.95
end

local function getBalls()
	table.clear(ballList)

	local byName = {}

	for b in pairs(ballsMap) do
		if b and b.Parent then
			local name = b.Name
			local list = byName[name]
			if not list then
				list = {}
				byName[name] = list
			end
			list[#list + 1] = b
		else
			ballsMap[b] = nil
			mainRealBall[b] = nil
			cleanupBallVisual(b)
		end
	end

	for _, list in pairs(byName) do
		local count = #list
		if count == 1 then
			local only = list[1]
			ballList[#ballList + 1] = only
		else
			local invis = {}
			local vis = {}
			local anyMain

			for i = 1, count do
				local part = list[i]
				if isVisualizerPart(part) then
					vis[#vis + 1] = part
				else
					invis[#invis + 1] = part
				end
				if mainRealBall[part] then
					anyMain = part
				end
			end

			local winner

			if #invis > 0 then
				winner = anyMain or invis[1]
			elseif anyMain then
				winner = anyMain
			elseif #vis > 0 then
				winner = vis[1]
			else
				winner = list[1]
			end

			if winner then
				mainRealBall[winner] = true
				for i = 1, count do
					local part = list[i]
					if part ~= winner then
						mainRealBall[part] = nil
						ballsMap[part] = nil
						cleanupBallVisual(part)
					end
				end
				ballList[#ballList + 1] = winner
			end
		end
	end

	return ballList
end

setupBallTracking()

local function getBallVisual(ball)
	if not ball then
		return nil
	end
	local v = ballVis[ball]
	if v and (not v.ring or not v.ring.Parent or not v.gui or not v.gui.Parent) then
		v = nil
	end
	if not v then
		local gui = select(1, newBillboard("Distance", UDim2.new(2, 0, 2, 0), Vector3.new(0, 5, 0), false))
		local txt = gui:FindFirstChild("Text")
		gui.Adornee = ball
		local ring = ringPlayer:Clone()
		ring.Name = "VisualizerFollowBall"
		ring.Transparency = ringBaseTransparency
		ring.Parent = workspace
		v = { ring = ring, gui = gui, text = txt }
		ballVis[ball] = v
	end
	return v
end

local function cleanupAllBallVisuals()
	for b in pairs(ballVis) do
		cleanupBallVisual(b)
	end
end

local function applyVisualizerVisible(show)
	rangeGui.Enabled = show
	ringPlayer.Transparency = show and ringBaseTransparency or 1
	ringPlayerNoUnit.Transparency = show and ringPinkTransparency or 1
	for _, v in pairs(ballVis) do
		if v.gui then
			v.gui.Enabled = show
		end
		if v.ring then
			v.ring.Transparency = show and ringBaseTransparency or 1
		end
	end
end
local visualizerAttached = true;
local trackedConnections = {};
local function trackConnection(conn)
	trackedConnections[#trackedConnections + 1] = conn;
	return conn;
end;
local function cleanup()
	for _, c in ipairs(trackedConnections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	trackedConnections = {}

	for _, conns in pairs(ballConns) do
		for _, conn in ipairs(conns) do
			pcall(function()
				conn:Disconnect()
			end)
		end
	end
	ballConns = {}
	for _, conn in pairs(containerConns) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	containerConns = {}
	ballsMap = {}
	ballList = {}
	mainRealBall = {}

	pcall(function()
		rangeGui.Parent = nil
	end)
	pcall(function()
		cleanupAllBallVisuals()
		ringPlayer:Destroy()
		ringPlayerNoUnit:Destroy()
	end)
	pcall(function()
		iconHide(debugIconInstance);
		debugIconInstance = nil;
		debugStateOption = nil;
		debugTargetOption = nil;
		debugBallsOption = nil;
		debugCooldownOption = nil;
	end)

	touchLock = false
	RevertLastInputPatch()
	table.clear(connections)

	getgenv().AutoParryCleanup = nil;
end;
getgenv().AutoParryCleanup = cleanup;
local function attachVisualizer(hasBall)
	if hasBall then
		if not visualizerAttached then
			local guiParent = guiCHECKINGAHHHHH()
			rangeGui.Parent = guiParent
			for _, v in pairs(ballVis) do
				if v.gui then
					v.gui.Parent = guiParent
				end
				if v.ring then
					v.ring.Parent = workspace
				end
			end
			ringPlayer.Parent = workspace
			ringPlayerNoUnit.Parent = workspace
			visualizerAttached = true
		end
	elseif visualizerAttached then
		rangeGui.Parent = nil
		rangeGui.Adornee = nil
		for _, v in pairs(ballVis) do
			if v.gui then
				v.gui.Parent = nil
				v.gui.Adornee = nil
			end
			if v.ring then
				v.ring.Parent = nil
			end
		end
		ringPlayer.Parent = nil
		ringPlayerNoUnit.Parent = nil
		visualizerAttached = false
	end
end
local function resolveRemote()
	local cfg = visualizerConfig;
	local r = cfg and cfg.remote;
	if not r then
		return nil, nil;
	end;
	local function resolveOne(x)
		if typeof(x) == "Instance" then
			if x.Parent then
				return x, nil;
			end;
		elseif type(x) == "table" then
			local inst = x.inst or x[1];
			local args = x.args or x[2];
			if typeof(inst) == "Instance" and inst.Parent then
				return inst, args;
			end;
			local par = x.parent;
			local name = x.name;
			if not inst and typeof(par) == "Instance" and type(name) == "string" and par.Parent then
				local f = par:FindFirstChild(name, true);
				if f and f.Parent then
					return f, args;
				end;
			end;
		end;
		return nil, nil;
	end;

	if typeof(r) == "Instance" or (type(r) == "table" and (r.inst or r.parent or r[1])) then
		return resolveOne(r);
	elseif type(r) == "table" then
		for _, v in ipairs(r) do
			local inst, args = resolveOne(v);
			if inst then
				return inst, args;
			end;
		end;
	end;
	return nil, nil;
end;
local function fireRemote(rem, args)
	if not (rem and typeof(rem) == "Instance" and rem.Parent) then
		return false;
	end;
	local a = args;
	if a == nil then
		a = {};
	end;
	if typeof(a) ~= "table" then
		a = { a };
	end;
	local t = rem.ClassName;
	local ok = false;
	if t == "RemoteEvent" then
		local s = pcall(function()
			rem:FireServer(unpack(a));
		end);
		if s then
			ok = true;
		end;
	elseif t == "RemoteFunction" then
		local s = pcall(function()
			rem:InvokeServer(unpack(a));
		end);
		if s then
			ok = true;
		end;
	elseif t == "BindableEvent" then
		local s = pcall(function()
			rem:Fire(unpack(a));
		end);
		if s then
			ok = true;
		end;
	elseif t == "BindableFunction" then
		local s = pcall(function()
			rem:Invoke(unpack(a));
		end);
		if s then
			ok = true;
		end;
	end;
	return ok;
end;
local function resolveBtn()
	local cfg = visualizerConfig;
	local b = cfg and cfg.btn;
	if not b then
		return nil;
	end;
	local function resolveOne(x)
		if typeof(x) == "Instance" then
			if x:IsA("GuiButton") and x.Parent then
				return x;
			end;
		elseif type(x) == "table" then
			local par = x.parent;
			local name = x.name;
			if typeof(par) == "Instance" and type(name) == "string" and par.Parent then
				local f = par:FindFirstChild(name, true);
				if f and f:IsA("GuiButton") and f.Parent then
					return f;
				end;
			end;
		end;
		return nil;
	end;

	if typeof(b) == "Instance" or (type(b) == "table" and (b.parent or b.name)) then
		return resolveOne(b);
	elseif type(b) == "table" then
		for _, v in ipairs(b) do
			local r = resolveOne(v);
			if r then
				return r;
			end;
		end;
	end;
	return nil;
end;
local function pressBtn(btn)
	if typeof(firesignal) ~= "function" then
		return false;
	end;
	if not (btn and btn:IsA("GuiButton") and btn.Parent) then
		return false;
	end;
	local fired = false;
	local ev;
	ev = btn.MouseButton1Down;
	if ev then
		pcall(function()
			firesignal(ev);
		end);
		fired = true;
	end;
	ev = btn.MouseButton1Up;
	if ev then
		pcall(function()
			firesignal(ev);
		end);
		fired = true;
	end;
	ev = btn.MouseButton1Click;
	if ev then
		pcall(function()
			firesignal(ev);
		end);
		fired = true;
	end;
	ev = btn.Activated;
	if ev then
		pcall(function()
			firesignal(ev);
		end);
		fired = true;
	end;
	return fired;
end;
local function QuickParry()
	local cam = workspace.CurrentCamera;
	local y = cam and cam.CFrame.LookVector.Y or 0;
	if Net and Net.Block then
		pcall(function()
			Net.Block:Invoke(y);
		end);
		return;
	end;
	if FRemote then
		pcall(function()
			FRemote:InvokeServer("SwordService", "Block", {
				y
			});
		end);
	end;
end;
local function DoParry()
	local rem, rargs = resolveRemote();
	if rem and fireRemote(rem, rargs) then
		return;
	end;
	local btn = resolveBtn();
	if btn and pressBtn(btn) then
		return;
	end;
	local cam = workspace.CurrentCamera;
	local y = cam and cam.CFrame.LookVector.Y or 0;
	local success = false;
	if Net and Net.Block then
		local ok, res = pcall(function()
			return Net.Block:Invoke(y);
		end);
		if ok and res ~= nil then
			success = true;
		end;
	end;
	if not success and FRemote then
		pcall(function()
			FRemote:InvokeServer("SwordService", "Block", {
				y
			});
		end);
		success = true;
	end;
	if success then
		local hold = SwordController and SwordController.GetSwordAnim and SwordController.GetSwordAnim("Hold");
		if hold then
			hold:Play();
		end;
		if SoundController and SoundController.PlaySound then
			SoundController.PlaySound("Block");
		end;
		if SwordController and SwordController.ShowShield then
			SwordController.ShowShield();
		end;
	end;
	return success;
end;
local function queueParry(isSpam, hasTarget)
	if (not apEnabled) and (not isSpam) then
		return;
	end;
	if not isSpam and not hasTarget then
		return;
	end;
	local now = tick();
	if curFrame == lastParryFrame then
		return;
	end;
	if not isSpam and now - lastQueueTime < 0.03 then
		return;
	end;
	lastParryFrame = curFrame;
	if not isSpam then
		lastQueueTime = now;
	end;
	task.defer(DoParry);
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
	local charHighlight, charColor = getHighlightColor(char);
	local ballHighlight, hlBallColor = getHighlightColor(ball);
	local ballColorPrimary;
	if ball and ball:IsA("BasePart") then
		ballColorPrimary = ball.Color;
	end;
	local targetedColor = false;
	local usedBallColor;
	if ballColorPrimary and charHighlight and charColor then
		if colorsClose(ballColorPrimary, charColor, 0.05) then
			targetedColor = true;
			usedBallColor = ballColorPrimary;
		end;
	end;
	if not targetedColor and ballHighlight and hlBallColor and charHighlight and charColor and ballHighlight.Enabled ~= false and charHighlight.Enabled ~= false and (ballHighlight.FillTransparency or 0) < 0.9 and (charHighlight.FillTransparency or 0) < 0.9 and colorsClose(hlBallColor, charColor, 0.05) then
		targetedColor = true;
		usedBallColor = hlBallColor;
	end;
	local targeted = targetedColor;
	return targeted, ballHighlight, charHighlight, usedBallColor, charColor;
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
local function updateGuiTargets(hrp, hasBall)
	if hasBall and hrp then
		rangeGui.Adornee = hrp
	else
		rangeGui.Adornee = nil
	end
end
trackConnection(RunService.RenderStepped:Connect(function(dt)
	curFrame = curFrame + 1
	character = localPlayer.Character or character
	local hrp = waitForChildFast(character, "HumanoidRootPart")
	local balls = getBalls()
	local hasBalls = #balls > 0
	attachVisualizer(hasBalls)
	local showViz = isVisualizerEnabled() and hasBalls
	if not (hrp and hrp.Position) then
		return
	end
	local nowFrame = tick()
	local pingItem = Stats.Network.ServerStatsItem and Stats.Network.ServerStatsItem["Data Ping"]
	local pingFrame = pingItem and pingItem:GetValue() or 0
	updateGuiTargets(hrp, hasBalls)
	local anyTargeted = false

	if hasBalls then
		local seen = {}
		local focusPos = nil
		local focusDist = math.huge
		local focusPosTargeted = nil
		local focusDistTargeted = math.huge
		local focusIsTargeted = false
		local primBaseSize, primPredictNoPing, primPredictRadius

		for _, ball in ipairs(balls) do
			if ball and ball.Position then
				seen[ball] = true
				local vis = getBallVisual(ball)
				local ringBall = vis and vis.ring
				local dGui = vis and vis.gui
				local dText = vis and vis.text

				local rawDist = (ball.Position - hrp.Position).Magnitude
				local dist = rawDist / distanceDivisor
				local now = nowFrame
				if ringBall then
					ringBall.CFrame = CFrame.new(ball.Position)
				end

				local velocity = ball.AssemblyLinearVelocity or ball.Velocity or Vector3.zero
				local lastVel = lastBallVel[ball] or Vector3.zero
				local sample = lastBallSamples[ball]
				local sampleDt = sample and now - sample.t or 0
				local posDelta = sample and ball.Position - sample.pos or Vector3.zero
				if not sample or sampleDt > 0.4 then
					sample = { pos = ball.Position, t = now }
					sampleDt = 0
					posDelta = Vector3.zero
				end
				local manualVel = sampleDt > 0 and posDelta / math.max(sampleDt, 0.001) or velocity
				local chosenVel = velocity
				if chosenVel.Magnitude < 0.001 or chosenVel.Magnitude < manualVel.Magnitude * 0.5 then
					chosenVel = manualVel
				end
				local lastMoveTime = lastBallMoveTime[ball] or 0
				if chosenVel.Magnitude >= 4 then
					lastBallMoveTime[ball] = now
				elseif lastVel.Magnitude > 8 and now - lastMoveTime < 0.2 then
					chosenVel = lastVel:Lerp(chosenVel, 0.15)
				end
				local smoothingAlpha = sampleDt > 0 and math.clamp(sampleDt / 0.04, 0.35, 0.9) or 0.45
				lastBallSamples[ball] = { pos = ball.Position, t = now }
				velocity = lastVel:Lerp(chosenVel, smoothingAlpha)

				local speed = velocity.Magnitude
				local prevSpeed = smoothedSpeed[ball] or speed
				local speedLerp = math.clamp((dt or 0.016) / 0.03, 0.35, 0.95)
				speed = prevSpeed + (speed - prevSpeed) * speedLerp
				smoothedSpeed[ball] = speed
				lastBallVel[ball] = velocity

				local baseSize = 10 + speed * speedScale * 2

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

				local ping = pingFrame
				local baseFactor = math.clamp(predictBase / 50, 0.25, 2)
				local predictRadiusNoPing = predictMinRadius + predictExtra * baseFactor + effectiveSpeed * (multiplier + speedBoost) * baseFactor
				local predictRadius = predictRadiusNoPing + ping * pingPredictScale
				local preEntryMargin = math.clamp(predictRadius * 0.12 + ping * 0.018, 3, 14)
				local parryPredictRadius = predictRadius + preEntryMargin

				if ringBall then
					rescaleRing(ringBall, baseSize, nil, dt)
				end

				if not focusIsTargeted and rawDist < focusDist then
					focusDist = rawDist
					focusPos = ball.Position
					primBaseSize = baseSize
					primPredictNoPing = predictRadiusNoPing
					primPredictRadius = predictRadius
				end

				local inPredict = rawDist <= predictRadius
				local nearPredict = rawDist <= predictRadius + preEntryMargin
				local inParryPredict = rawDist <= parryPredictRadius
				local displayedPredict = predictRadius

				rangeText.Text = tostring(round(displayedPredict, 1))
				if rangeMulti then
					rangeMulti.Text = string.format("%.1fx", round(displayedPredict / 100, 1))
				end
				if dText then
					dText.Text = tostring(round(dist, 1))
				end

				local prevInPredict = wasInPredict[ball] or false
				if nearPredict then
					predictEnterAt[ball] = predictEnterAt[ball] or now
					resetToken = resetToken + 1
				elseif prevInPredict then
					predictEnterAt[ball] = nil
				else
					predictEnterAt[ball] = nil
				end
				wasInPredict[ball] = nearPredict

				local settleTime = math.clamp(0.003 + ping * 0.0002, 0.002, 0.014)
				local settledInPredict = nearPredict and predictEnterAt[ball] and now - predictEnterAt[ball] >= settleTime

				local targeted, ballHighlight, charHighlight, ballColor, charColor = isBallTargetingYou(ball, character)
				local attrNow = isBallTargetingYouAttr(ball, character)
				local charHighlightEnabled = charHighlight and charHighlight.Enabled ~= false
				if targeted or attrNow then
					anyTargeted = true
					if rawDist < focusDistTargeted then
						focusDistTargeted = rawDist
						focusPosTargeted = ball.Position
						focusIsTargeted = true
						primBaseSize = baseSize
						primPredictNoPing = predictRadiusNoPing
						primPredictRadius = predictRadius
					end
				end

				local lastChar = lastCharHighlightEnabled[ball] or false
				if charHighlightEnabled and (not lastChar) then
					lastParryPerBall[ball] = -math.huge
				end

				local hasTargetLock = targeted and targetedSince[ball] ~= nil
				local lastMatch = lastHighlightMatch[ball] or false
				local highlightsMatch = targeted
				if highlightsMatch and (not lastMatch) then
					lastParryPerBall[ball] = -math.huge
					targetedSince[ball] = now
				elseif not highlightsMatch and lastMatch then
					lastParryPerBall[ball] = -math.huge
					targetedSince[ball] = nil
					if not attrNow then
						closeParryBlocked[ball] = nil
						nextPar = 0
					end
				end
				lastHighlightMatch[ball] = highlightsMatch
				lastCharHighlightEnabled[ball] = charHighlightEnabled

				local approaching = false
				local isBait = false
				local dotNow = 0
				if speed >= 4 then
					local toYou = hrp.Position - ball.Position
					local mag = toYou.Magnitude
					if mag > 0.001 then
						local dirToYou = toYou / mag
						local velDir = speed > 0.001 and velocity.Unit or dirToYou
						dotNow = dirToYou:Dot(velDir)
						local toward = dotNow > 0.2
						local away = dotNow < -0.2

						local wasAway = lastAwayFlag[ball]
						if away then
							if not wasAway then
								awaySince[ball] = now
							end
							lastAwayFlag[ball] = true
						else
							if wasAway then
								local startAway = awaySince[ball]
								if toward and startAway and now - startAway >= 0.06 then
									baitUntil[ball] = now + 0.14
								end
							end
							lastAwayFlag[ball] = false
						end

						isBait = baitUntil[ball] and now < baitUntil[ball] and rawDist > parryPredictRadius * 0.6
						approaching = toward and (not isBait)
					end
				else
					lastAwayFlag[ball] = false
					awaySince[ball] = nil
				end

				local toRingTime = approaching and speed > 1 and math.max((rawDist - parryPredictRadius), 0) / speed or math.huge
				local closeHit = targeted and rawDist <= math.max(10, parryPredictRadius * 0.45)
				local nearHitTime = speed > 1 and rawDist / speed or math.huge
				local veryFastHit = targeted and nearHitTime <= 0.18 + ping * pingTimeScale
				local closeHitSafe = closeHit and (nearHitTime <= 0.3 or speed >= 25)
				local targetSnap = targeted and inParryPredict and settledInPredict and (nearHitTime <= 0.6 or rawDist <= math.max(10, parryPredictRadius * 0.6))
				local innerEmergency = targeted and rawDist <= math.max(8, predictRadius * 0.4)
				local fastApproach = targeted and approaching and (nearHitTime <= 0.22 or rawDist <= parryPredictRadius * 0.95)

				local parryTriggered = false
				if innerEmergency and hasTargetLock and (not closeParryBlocked[ball]) then
					local nowInner = tick()
					local lastBallFire = lastParryPerBall[ball] or (-math.huge)
					if nowInner >= nextPar and nowInner - lastBallFire > 0.05 then
						nextPar = nowInner + parCd
						lastParryPerBall[ball] = nowInner
						closeParryBlocked[ball] = true
						lastParryTime = nowInner
						parryTriggered = true
						queueParry(false, true)
					end
				end

				local outsideRing = rawDist >= math.max(predictRadius - math.max(preEntryMargin * 1.1, 2.5), predictRadius * 0.85)
				local ringEdgeSafe = innerEmergency or rawDist >= parryPredictRadius * 0.6 or nearHitTime <= 0.2 or veryFastHit
				local ringTimeSoon = toRingTime <= 0.55 + ping * 0.003

				local function attemptParry()
					if parryTriggered then
						return
					end
					if isBait and not innerEmergency then
						return
					end
					if closeParryBlocked[ball] and (rawDist > parryPredictRadius * 1.15 or tick() - (lastParryPerBall[ball] or 0) > 1.2) then
						closeParryBlocked[ball] = nil
					end
					local inCloseBlock = closeParryBlocked[ball] and rawDist <= parryPredictRadius * 1.15

					local slowClose = targeted
						and approaching
						and hasTargetLock
						and rawDist <= math.max(14, parryPredictRadius * 0.55)
						and speed >= 3
						and nearHitTime <= 1.1

					local slowVeryClose = targeted
						and hasTargetLock
						and rawDist <= math.max(10, parryPredictRadius * 0.45)
						and speed > 0
						and speed <= 4

					local canPredict = approaching and nearPredict and settledInPredict and highlightsMatch and hasTargetLock and (outsideRing or fastApproach) and (speed >= 12 or nearHitTime <= 0.25 or ringTimeSoon or fastApproach) or closeHitSafe and hasTargetLock or veryFastHit and hasTargetLock or targetSnap and hasTargetLock or innerEmergency and hasTargetLock or slowClose or slowVeryClose
					canPredict = canPredict and ringEdgeSafe
					canPredict = canPredict and (not inCloseBlock)
					if canPredict then
						local nowTry = tick()
						local lastBallFire = lastParryPerBall[ball] or (-math.huge)
						local minBallCooldown = highlightsMatch and 0.7 or 0.35
						if nowTry >= nextPar and nowTry - lastBallFire > minBallCooldown then
							nextPar = nowTry + parCd
							lastParryPerBall[ball] = nowTry
							if rawDist <= parryPredictRadius * 0.8 then
								closeParryBlocked[ball] = true
							end
							lastParryTime = nowTry
							parryTriggered = true
							queueParry(false, true)
						end
					end
				end

				task.defer(attemptParry)

				task.defer(function()
					if parryTriggered then
						return
					end
					if targeted then
						return
					end
					if closeParryBlocked[ball] then
						return
					end
					if isBait and not innerEmergency then
						return
					end
					local nowAttr = tick()
					local attrTargeted = isBallTargetingYouAttr(ball, character)
					local prevAttr = lastAttrTargeted[ball]
					if attrTargeted and (not prevAttr) then
						lastParryPerBall[ball] = -math.huge
						if nowAttr < nextPar then
							nextPar = nowAttr
						end
					elseif not attrTargeted and prevAttr then
						lastParryPerBall[ball] = -math.huge
						if not targeted then
							nextPar = 0
						end
					end
					lastAttrTargeted[ball] = attrTargeted
					if not attrTargeted then
						return
					end
					local attrNear = rawDist <= math.max(10, parryPredictRadius * 0.9)
					local attrFast = speed > 20 or nearHitTime <= 0.35
					if not (attrNear and attrFast) then
						return
					end
					local lastBallFire = lastParryPerBall[ball] or (-math.huge)
					if nowAttr >= nextPar and nowAttr - lastBallFire > 0.7 then
						nextPar = nowAttr + parCd
						lastParryPerBall[ball] = nowAttr
						lastParryTime = nowAttr
						parryTriggered = true
						queueParry(false, true)
					end
				end)
			end
		end

		local focus = focusPosTargeted or focusPos
		if focus then
			local lookAtBall = CFrame.lookAt(hrp.Position, focus)
			ringPlayer.CFrame = lookAtBall
			ringPlayerNoUnit.CFrame = lookAtBall
		else
			ringPlayer.CFrame = CFrame.new(hrp.Position)
			ringPlayerNoUnit.CFrame = ringPlayer.CFrame
		end

		if primBaseSize and primPredictNoPing and primPredictRadius then
			local appliedPlayerPredict = rescaleRing(ringPlayer, primPredictNoPing * 2, maxSize, dt)
			ringLimited = appliedPlayerPredict >= maxSize - 0.1
			rescaleRing(ringPlayerNoUnit, primPredictRadius * 2, predictMaxSize, dt)
			ringPlayerNoUnit.Transparency = ringPinkTransparency
		else
			rescaleRing(ringPlayer, 10, maxSize, dt)
			rescaleRing(ringPlayerNoUnit, 10, predictMaxSize, dt)
			ringLimited = false
		end

		for b in pairs(ballVis) do
			if (not seen[b]) or (not b.Parent) then
				cleanupBallVisual(b)
				lastBallSamples[b] = nil
				lastBallVel[b] = nil
				lastBallMoveTime[b] = nil
				smoothedSpeed[b] = nil
				closeParryBlocked[b] = nil
				predictEnterAt[b] = nil
				wasInPredict[b] = nil
				lastHighlightMatch[b] = nil
				lastCharHighlightEnabled[b] = nil
				targetedSince[b] = nil
				lastAttrTargeted[b] = nil
				lastParryPerBall[b] = nil
				baitUntil[b] = nil
				awaySince[b] = nil
				lastAwayFlag[b] = nil
			end
		end
	else
		ringPlayer.CFrame = CFrame.new(hrp.Position)
		ringPlayerNoUnit.CFrame = ringPlayer.CFrame
		cleanupAllBallVisuals()
		lastBallSamples = {}
		lastBallVel = {}
		lastBallMoveTime = {}
		smoothedSpeed = {}
		closeParryBlocked = {}
		predictEnterAt = {}
		wasInPredict = {}
		lastHighlightMatch = {}
		lastCharHighlightEnabled = {}
		targetedSince = {}
		lastAttrTargeted = {}
		lastParryPerBall = {}
		baitUntil = {}
		awaySince = {}
		lastAwayFlag = {}
		nextPar = 0
		ringLimited = false
		resetToken = 0
		rangeText.Text = "0"
		if rangeMulti then
			rangeMulti.Text = "0x"
		end
	end

	local nowStateTime = tick()
	local inCooldown = nowStateTime < nextPar
	local state
	if not apEnabled then
		state = "Disabled"
	elseif lastParryTime > 0 and nowStateTime - lastParryTime <= 0.25 then
		state = "Parried"
	elseif not hasBalls then
		if inCooldown then
			state = "Recovering"
		else
			state = "Idle"
		end
	elseif inCooldown then
		if anyTargeted then
			state = "Cooldown"
		else
			state = "Recovering"
		end
	elseif anyTargeted then
		state = "Targeted"
	else
		state = "Active"
	end
	apState = state
	updateDebugMenu(#balls, anyTargeted, nowStateTime)
	updateRingColors()
	applyVisualizerVisible(showViz)
end));
trackConnection(RunService.Heartbeat:Connect(function()
	task.defer(function()
		if spam then
			task.defer(QuickParry)
			task.defer(QuickParry)
			task.defer(QuickParry)
		end;
	end);
end));
