local __lt = (function()
	local rootEnv = _G or {};
	local globalEnv = (getgenv and getgenv()) or rootEnv;
	local sharedEnv = rawget(rootEnv, "shared");
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

local _G = (getgenv and getgenv()) or _G or {};

local conns = {};
local function svc(n)
	local S = function(_, serviceName) return __lt.gs(serviceName); end;
	local R = cloneref or function(r)
		return r;
	end;
	return __lt.cs(n, R);
end;
local Players = svc("Players");
local RunService = svc("RunService");
local UIS = svc("UserInputService");
local TS = svc("TweenService");
local CAS = svc("ContextActionService");
local LS = svc("LocalizationService");
local MPS = svc("MarketplaceService");
local HS = svc("HttpService");
local rawNewUi = Instance.new;
local function makeUiName()
	local ok, id = pcall(function()
		return HS:GenerateGUID(false);
	end);
	if ok and type(id) == "string" and id ~= "" then
		return id;
	end;
	return "\0";
end;
local function setUiTag(obj, tag)
	if obj then
		pcall(function()
			obj.Name = makeUiName();
		end);
		if tag ~= nil then
			pcall(function()
				obj:SetAttribute("UiTag", tostring(tag));
			end);
		end;
	end;
	return obj;
end;
local function getUiTag(obj)
	local ok, tag = pcall(function()
		return obj:GetAttribute("UiTag");
	end);
	return ok and tag or nil;
end;
local function findUiTag(parent, tag, recursive)
	if not parent then
		return nil;
	end;
	for _, child in ipairs(parent:GetChildren()) do
		if getUiTag(child) == tag then
			return child;
		end;
	end;
	if recursive then
		for _, child in ipairs(parent:GetDescendants()) do
			if getUiTag(child) == tag then
				return child;
			end;
		end;
	end;
	return nil;
end;
local function newUi(className, parent, tag)
	local obj = rawNewUi(className);
	setUiTag(obj, tag or className);
	if parent ~= nil then
		obj.Parent = parent;
	end;
	return obj;
end;
local GS = svc("GuiService");
local uiRoot = gethui and gethui() or (svc("CoreGui") or (svc("Players")).LocalPlayer:WaitForChild("PlayerGui"));
local plr = Players.LocalPlayer;
local cam = workspace.CurrentCamera;
local ms = plr:GetMouse();
local isLock = false;
local mode = "FFA";
local lastMode = nil;
local capMode = false;
local capCooldownUntil = 0;
local gui = nil;
local frm = nil;
local uiMin = false;
local toastHolder = nil;
local toastIdx = 0;
local topBtn = nil;
local topToggleHolder = nil;
local espMap = {};
local startUnix = (DateTime.now()).UnixTimestamp;
local openDropdown = nil;
local aimCamTween = nil;
local lockCamLoop = nil;
local rng = Random.new();
local function newRandomAimCache()
	return setmetatable({}, {
		__mode = "k"
	});
end;
local randomAimCache = newRandomAimCache();
local randomAimSeq = 0;
local function platformName()
	local ok, p = pcall(function()
		return UIS:GetPlatform();
	end);
	return ok and p and p.Name or "";
end;
local function isMobilePlatform()
	local n = platformName();
	return UIS.TouchEnabled and (n == "Android" or n == "IOS" or n == "iOS" or ((not UIS.KeyboardEnabled) and (not UIS.MouseEnabled)));
end;
_G.isEnabled = _G.isEnabled or false;
_G.aimTargetMode = _G.aimTargetMode or (_G.lockToHead and "Head") or "Head";
_G.espEnabled = _G.espEnabled or false;
_G.espTransparency = _G.espTransparency or 0.3;
_G.lockToNearest = _G.lockToNearest or false;
_G.aliveCheck = _G.aliveCheck or false;
_G.teamCheck = _G.teamCheck or false;
_G.wallCheck = _G.wallCheck or false;
_G.aimTween = _G.aimTween or false;
_G.aimSmooth = _G.aimSmooth or 0.15;
_G.fovEnabled = _G.fovEnabled or false;
_G.fovValue = _G.fovValue or 70;
_G.espShowName = _G.espShowName ~= nil and _G.espShowName or true;
_G.espShowHP = _G.espShowHP ~= nil and _G.espShowHP or true;
_G.espShowTeam = _G.espShowTeam ~= nil and _G.espShowTeam or true;
_G.espTeamColor = _G.espTeamColor ~= nil and _G.espTeamColor or true;
_G.tbCPS = _G.tbCPS or 8;
_G.aimPredict = _G.aimPredict or false;
_G.aimLead = _G.aimLead or 0.12;
_G.aimRadius = _G.aimRadius or 150;
_G.targetPointMode = _G.targetPointMode or "Cursor";
_G.fovCircleEnabled = _G.fovCircleEnabled ~= nil and _G.fovCircleEnabled or false;
_G.fovCircleAlpha = _G.fovCircleAlpha ~= nil and _G.fovCircleAlpha or 0.25;
_G.fovCircleThickness = _G.fovCircleThickness or 2;
_G.aimLock = _G.aimLock or false;
_G.lockKey = _G.lockKey or "MouseButton2";
_G.mobileCenterAim = _G.mobileCenterAim ~= nil and _G.mobileCenterAim or isMobilePlatform();
_G.mobileButtons = _G.mobileButtons ~= nil and _G.mobileButtons or isMobilePlatform();
_G.uiScale = _G.uiScale or 1;
_G.uiWindowAlpha = _G.uiWindowAlpha ~= nil and _G.uiWindowAlpha or 0.08;
_G.uiContentAlpha = _G.uiContentAlpha ~= nil and _G.uiContentAlpha or 0.02;
_G.uiTheme = _G.uiTheme or "Midnight Purple";
_G.uiAnimations = _G.uiAnimations ~= nil and _G.uiAnimations or true;
_G.uiAnimSpeed = _G.uiAnimSpeed or 1;
_G.uiCompact = _G.uiCompact ~= nil and _G.uiCompact or false;
_G.uiRounded = _G.uiRounded or 24;
_G.toastDuration = _G.toastDuration or 3;
_G.toastMax = _G.toastMax or 4;
_G.toastCompact = _G.toastCompact ~= nil and _G.toastCompact or false;
_G.toastPosition = _G.toastPosition or "Top Right";
_G.centerDotVisible = _G.centerDotVisible ~= nil and _G.centerDotVisible or true;
_G.centerDotSize = _G.centerDotSize or 12;
_G.centerDotAlpha = _G.centerDotAlpha ~= nil and _G.centerDotAlpha or 0.35;
_G.mobileButtonScale = _G.mobileButtonScale or 1;
_G.mobileButtonAlpha = _G.mobileButtonAlpha ~= nil and _G.mobileButtonAlpha or 0.06;
_G.mobileHelperButtons = type(_G.mobileHelperButtons) == "table" and _G.mobileHelperButtons or {
	"Lock",
	"Menu",
	"Center Dot"
};
_G.mobileHelperPos = type(_G.mobileHelperPos) == "table" and _G.mobileHelperPos or nil;
_G.pendingMobileAction = _G.pendingMobileAction or "Aimbot";
_G.topTogglePos = type(_G.topTogglePos) == "table" and _G.topTogglePos or { XScale = 0.5, XOffset = -76, YScale = 0, YOffset = 8 };
_G.optionBinds = type(_G.optionBinds) == "table" and _G.optionBinds or {};
_G.pendingBindAction = _G.pendingBindAction or "Aimbot";
_G.espRenderMode = _G.espRenderMode or "Highlight";
_G.espAlwaysOnTop = _G.espAlwaysOnTop ~= nil and _G.espAlwaysOnTop or true;
_G.espShowDistance = _G.espShowDistance or false;
_G.espTextSize = _G.espTextSize or 14;
_G.espMaxDistance = _G.espMaxDistance or 2500;
_G.espOutlineTransparency = _G.espOutlineTransparency ~= nil and _G.espOutlineTransparency or 0.12;
_G.targetPriorityMode = _G.targetPriorityMode or (_G.lockToNearest and "Distance") or "Crosshair";
_G.stickyTarget = _G.stickyTarget ~= nil and _G.stickyTarget or true;
_G.targetMaxDistance = _G.targetMaxDistance or 2500;
local lastTargetName = "none";
local lastLockedCharacter = nil;
local lastLockedPart = nil;
local topClickBlock = 0;
_G.toggleKeys = _G.toggleKeys or {
	"RightAlt",
	"LeftAlt",
	"P",
	"RightControl"
};
local AIM_TARGET_OPTIONS = {
	"Head",
	"Torso",
	"Root",
	"Upper Torso",
	"Lower Torso",
	"Random"
};
local TARGET_POINT_OPTIONS = {
	"Cursor",
	"Center"
};
local TARGET_PRIORITY_OPTIONS = {
	"Crosshair",
	"Distance",
	"Lowest Health"
};
local ESP_RENDER_OPTIONS = {
	"Highlight",
	"BoxHandleAdornment"
};
local THEME_OPTIONS = {
	"Midnight Purple",
	"Cyan",
	"Purple",
	"Pink",
	"Green",
	"Gold",
	"Red"
};
local BIND_ACTION_OPTIONS = {
	"Aimbot",
	"Aim Lock",
	"ESP",
	"Wall Check",
	"Team Check",
	"Alive Check",
	"Lock FOV",
	"Tween Aim",
	"Prediction",
	"FOV Circle",
	"Lock Nearest",
	"Mobile Buttons",
	"Mobile Center Aim",
	"Center Dot"
};
local BIND_ACTION_VARS = {
	["Aimbot"] = "isEnabled",
	["Aim Lock"] = "aimLock",
	["ESP"] = "espEnabled",
	["Wall Check"] = "wallCheck",
	["Team Check"] = "teamCheck",
	["Alive Check"] = "aliveCheck",
	["Lock FOV"] = "fovEnabled",
	["Tween Aim"] = "aimTween",
	["Prediction"] = "aimPredict",
	["FOV Circle"] = "fovCircleEnabled",
	["Lock Nearest"] = "lockToNearest",
	["Mobile Buttons"] = "mobileButtons",
	["Mobile Center Aim"] = "mobileCenterAim",
	["Center Dot"] = "centerDotVisible"
};
local MOBILE_ACTION_OPTIONS = {
	"Lock",
	"Menu",
	"Aimbot",
	"Aim Lock",
	"ESP",
	"Wall Check",
	"Team Check",
	"Alive Check",
	"Lock FOV",
	"Prediction",
	"FOV Circle",
	"Lock Nearest",
	"Center Dot"
};
local TOAST_POS_OPTIONS = {
	"Top Right",
	"Top Left",
	"Bottom Right",
	"Bottom Left"
};
local MOBILE_HELPER_DEFAULTS = {
	"Lock",
	"Menu",
	"Center Dot"
};
local function normalizeAimMode(mode)
	local lower = (tostring(mode or "")):lower();
	for _, opt in ipairs(AIM_TARGET_OPTIONS) do
		if lower == opt:lower() then
			return opt;
		end;
	end;
	return "Head";
end;
_G.aimTargetMode = normalizeAimMode(_G.aimTargetMode);
local function normalizeChoice(mode, options, defaultValue)
	local lower = tostring(mode or ""):lower();
	for _, opt in ipairs(options or {}) do
		if lower == tostring(opt):lower() then
			return opt;
		end;
	end;
	return defaultValue or options[1];
end;
local function normalizeActionList(list, options, defaults)
	local out = {};
	local seen = {};
	local source = type(list) == "table" and list or defaults or {};
	for _, item in ipairs(source) do
		local picked = normalizeChoice(item, options, nil);
		if picked and (not seen[picked]) then
			seen[picked] = true;
			table.insert(out, picked);
		end;
	end;
	if #out == 0 and defaults then
		for _, item in ipairs(defaults) do
			local picked = normalizeChoice(item, options, nil);
			if picked and (not seen[picked]) then
				seen[picked] = true;
				table.insert(out, picked);
			end;
		end;
	end;
	return out;
end;
local function packUDim2(pos)
	if typeof(pos) ~= "UDim2" then
		return nil;
	end;
	return {
		XScale = pos.X.Scale,
		XOffset = pos.X.Offset,
		YScale = pos.Y.Scale,
		YOffset = pos.Y.Offset
	};
end;
local function unpackUDim2(tbl, fallback)
	if type(tbl) ~= "table" then
		return fallback;
	end;
	return UDim2.new(tonumber(tbl.XScale) or 0, tonumber(tbl.XOffset) or 0, tonumber(tbl.YScale) or 0, tonumber(tbl.YOffset) or 0);
end;
local function getAimTweenDuration()
	return math.clamp(_G.aimSmooth or 0.15, 0.05, 0.2);
end;
local cfgDir = "ltseverydayyou-Aimbot";
local cfgFile = cfgDir .. "/config.json";
local UI = {
	bg1 = Color3.fromRGB(5, 8, 15),
	bg2 = Color3.fromRGB(9, 14, 24),
	panel = Color3.fromRGB(12, 17, 29),
	panel2 = Color3.fromRGB(16, 23, 38),
	bar1 = Color3.fromRGB(14, 20, 34),
	bar2 = Color3.fromRGB(10, 15, 26),
	tab = Color3.fromRGB(13, 19, 32),
	tabActive = Color3.fromRGB(20, 31, 52),
	toast = Color3.fromRGB(14, 20, 34),
	stroke = Color3.fromRGB(56, 197, 255),
	stroke2 = Color3.fromRGB(72, 89, 130),
	knob = Color3.fromRGB(250, 252, 255),
	text = Color3.fromRGB(250, 253, 255),
	sub = Color3.fromRGB(205, 214, 238),
	dim = Color3.fromRGB(157, 171, 212),
	acc = Color3.fromRGB(117, 94, 255),
	acc2 = Color3.fromRGB(28, 225, 255),
	acc3 = Color3.fromRGB(255, 69, 162),
	ok = Color3.fromRGB(60, 232, 144),
	warn = Color3.fromRGB(255, 190, 80),
	danger = Color3.fromRGB(255, 75, 107),
	fallback = Color3.fromRGB(117, 94, 255)
};
local uiRefs = {};
local refreshMobileUI = function() end;
local rebuildMobileHelper = function() end;
local clampMobileHelperToScreen = function() end;
local updateFOVCircle = function() end;
local handleOptionBind = function()
	return false;
end;
local function applyTheme(name)
	local themes = {
		["Midnight Purple"] = { Color3.fromRGB(96, 67, 255), Color3.fromRGB(176, 90, 255), Color3.fromRGB(255, 80, 190) },
		Cyan = { Color3.fromRGB(117, 94, 255), Color3.fromRGB(28, 225, 255), Color3.fromRGB(255, 69, 162) },
		Purple = { Color3.fromRGB(132, 92, 255), Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 69, 162) },
		Pink = { Color3.fromRGB(255, 68, 180), Color3.fromRGB(255, 112, 208), Color3.fromRGB(123, 92, 255) },
		Green = { Color3.fromRGB(45, 219, 135), Color3.fromRGB(98, 255, 178), Color3.fromRGB(28, 225, 255) },
		Gold = { Color3.fromRGB(255, 168, 61), Color3.fromRGB(255, 214, 94), Color3.fromRGB(255, 100, 85) },
		Red = { Color3.fromRGB(255, 75, 107), Color3.fromRGB(255, 114, 114), Color3.fromRGB(255, 190, 80) }
	};
	local picked = tostring(name or "Midnight Purple");
	local t = themes[picked] or themes["Midnight Purple"];
	_G.uiTheme = themes[picked] and picked or "Midnight Purple";
	UI.acc = t[1];
	UI.acc2 = t[2];
	UI.acc3 = t[3];
	UI.stroke = t[2];
	UI.fallback = t[1];
end;
applyTheme(_G.uiTheme);
local function normChoice(v, opts, def)
	local low = tostring(v or ""):lower();
	for _, opt in ipairs(opts or {}) do
		if low == tostring(opt):lower() then
			return opt;
		end;
	end;
	return def or (opts and opts[1]);
end;
local function applyToastPos()
	local h = uiRefs.toastHolder or toastHolder;
	if not h then
		return;
	end;
	local pos = normChoice(_G.toastPosition, TOAST_POS_OPTIONS, "Top Right");
	_G.toastPosition = pos;
	local bottom = pos:find("Bottom") ~= nil;
	local right = pos:find("Right") ~= nil;
	h.AnchorPoint = Vector2.new(right and 1 or 0, bottom and 1 or 0);
	h.Position = UDim2.new(right and 1 or 0, right and -18 or 18, bottom and 1 or 0, bottom and -18 or 18);
	local lay = h:FindFirstChildOfClass("UIListLayout");
	if lay then
		lay.VerticalAlignment = bottom and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top;
		lay.HorizontalAlignment = right and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left;
	end;
end;
local function applyCustomUI()
	_G.uiScale = math.clamp(tonumber(_G.uiScale) or 1, 0.75, 1.25);
	_G.uiWindowAlpha = math.clamp(tonumber(_G.uiWindowAlpha) or 0.08, 0, 0.45);
	_G.uiContentAlpha = math.clamp(tonumber(_G.uiContentAlpha) or 0.02, 0, 0.55);
	_G.uiAnimSpeed = math.clamp(tonumber(_G.uiAnimSpeed) or 1, 0.35, 2.5);
	_G.uiRounded = math.clamp(tonumber(_G.uiRounded) or 24, 10, 34);
	_G.toastDuration = math.clamp(tonumber(_G.toastDuration) or 3, 1, 8);
	_G.toastMax = math.clamp(math.floor(tonumber(_G.toastMax) or 4), 1, 8);
	_G.centerDotSize = math.clamp(tonumber(_G.centerDotSize) or 12, 4, 40);
	_G.centerDotAlpha = math.clamp(tonumber(_G.centerDotAlpha) or 0.35, 0, 1);
	_G.mobileButtonScale = math.clamp(tonumber(_G.mobileButtonScale) or 1, 0.7, 1.45);
	_G.mobileButtonAlpha = math.clamp(tonumber(_G.mobileButtonAlpha) or 0.06, 0, 0.75);
	if uiRefs.rootScale then
		uiRefs.rootScale.Scale = _G.uiScale;
	end;
	if frm then
		frm.BackgroundTransparency = _G.uiWindowAlpha;
	end;
	if uiRefs.content then
		uiRefs.content.BackgroundTransparency = _G.uiContentAlpha;
	end;
	if uiRefs.centerDot then
		uiRefs.centerDot.Size = UDim2.new(0, _G.centerDotSize, 0, _G.centerDotSize);
		uiRefs.centerDot.BackgroundTransparency = _G.centerDotAlpha;
		uiRefs.centerDot.BackgroundColor3 = UI.acc2;
		local st = uiRefs.centerDot:FindFirstChildOfClass("UIStroke");
		if st then
			st.Color = UI.acc;
		end;
	end;
	if uiRefs.mobileHolder then
		if rebuildMobileHelper then
			rebuildMobileHelper();
		end;
		clampMobileHelperToScreen(uiRefs.mobileHolder);
	end;
	if uiRefs.topToggle then
		uiRefs.topToggle.BackgroundColor3 = UI.bar1;
	end;
	if gui then
		for _, d in ipairs(gui:GetDescendants()) do
			if d:IsA("GuiObject") and (getUiTag(d) == "Glow" or getUiTag(d) == "Accent") then
				d.BackgroundColor3 = UI.acc2;
			elseif d:IsA("ScrollingFrame") then
				d.AutomaticCanvasSize = d.ScrollingDirection == Enum.ScrollingDirection.X and Enum.AutomaticSize.X or Enum.AutomaticSize.Y;
				d.CanvasSize = UDim2.new(0, 0, 0, 0);
				d.ScrollBarImageColor3 = UI.acc2;
			elseif d:IsA("UIStroke") and d.Transparency <= 0.2 then
				d.Color = UI.stroke;
			end;
		end;
	end;
	if uiRefs.fovCircle then
		local st = uiRefs.fovCircle:FindFirstChildOfClass("UIStroke");
		if st then
			st.Color = UI.acc2;
			st.Transparency = math.clamp(tonumber(_G.fovCircleAlpha) or 0.25, 0, 1);
			st.Thickness = math.clamp(tonumber(_G.fovCircleThickness) or 2, 1, 8);
		end;
		updateFOVCircle();
	end;
	applyToastPos();
	if refreshMobileUI then
		refreshMobileUI();
	end;
end;
local function cleanup()
	for _, g in pairs(uiRoot:GetChildren()) do
		if g:IsA("ScreenGui") and (g.Name == "VyperiaBot" or getUiTag(g) == "VyperiaBot") then
			g:Destroy();
		end;
	end;
end;
local function round(p, r)
	local c = newUi("UICorner", p);
	c.CornerRadius = r or UDim.new(0, 0);
	return c;
end;
local function shadow(p)
	local s = newUi("ImageLabel");
	setUiTag(s, "Shadow");
	s.BackgroundTransparency = 1;
	s.Image = "rbxassetid://5028857476";
	s.ImageColor3 = Color3.fromRGB(0, 0, 0);
	s.ImageTransparency = 0.42;
	s.ScaleType = Enum.ScaleType.Slice;
	s.SliceCenter = Rect.new(24, 24, 276, 276);
	s.Size = UDim2.new(1, 44, 1, 44);
	s.Position = UDim2.new(0.5, 0, 0.5, 8);
	s.AnchorPoint = Vector2.new(0.5, 0.5);
	s.ZIndex = 0;
	s.Parent = p;
end;
local function stroke(p, t, c, tr)
	local s = newUi("UIStroke");
	s.Thickness = t or 1;
	s.Color = c or UI.stroke;
	s.Transparency = tr or 0;
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	s.Parent = p;
	return s;
end;
local function grad(p, c1, c2, rot)
	local g = newUi("UIGradient");
	g.Color = ColorSequence.new(c1, c2);
	g.Rotation = rot or 90;
	g.Parent = p;
	return g;
end;
local function noGrad(p)
	for _, c in ipairs(p:GetChildren()) do
		if c:IsA("UIGradient") then
			c:Destroy();
		end;
	end;
end;
local function fadeFrame()
	local ok, obj = pcall(function()
		return newUi("CanvasGroup");
	end);
	if ok and obj then
		return obj, true;
	end;
	return newUi("Frame"), false;
end;
local function tw(obj, info, props)
	if not obj then
		return;
	end;
	if _G.uiAnimations == false then
		for k, v in pairs(props or {}) do
			pcall(function()
				obj[k] = v;
			end);
		end;
		return;
	end;
	local ti = info;
	local spd = math.clamp(tonumber(_G.uiAnimSpeed) or 1, 0.35, 2.5);
	if typeof(info) == "TweenInfo" and spd ~= 1 then
		ti = TweenInfo.new(math.max(0.01, info.Time / spd), info.EasingStyle, info.EasingDirection, info.RepeatCount, info.Reverses, info.DelayTime / spd);
	end;
	local ok, tween = pcall(function()
		return TS:Create(obj, ti, props);
	end);
	if ok and tween then
		tween:Play();
		return tween;
	end;
end;
local function styleTog(bg, btn)
	bg.BackgroundColor3 = UI.bar2;
	stroke(bg, 1, UI.stroke2, 0.2);
	local g = grad(bg, UI.bar2, UI.bg2, 90);
	setUiTag(g, "Grad");
	btn.BackgroundColor3 = UI.knob;
	stroke(btn, 1, Color3.fromRGB(205, 208, 220), 0.35);
end;
local function styleWin(frame, bar, title, btnX, btnMin)
	frame.BackgroundColor3 = UI.panel;
	frame.BackgroundTransparency = 0.02;
	stroke(frame, 1, UI.stroke, 0.08);
	noGrad(frame);
	bar.BackgroundColor3 = UI.bar1;
	stroke(bar, 1, UI.stroke2, 0.14);
	noGrad(bar);
	title.TextColor3 = UI.text;
	local function winBtn(b, base)
		b.BackgroundColor3 = base;
		stroke(b, 1, Color3.fromRGB(0, 0, 0), 0.82);
		local e = b.MouseEnter:Connect(function()
			tw(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
				BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.18)
			});
		end);
		local l = b.MouseLeave:Connect(function()
			tw(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
				BackgroundColor3 = base
			});
		end);
		table.insert(conns, e);
		table.insert(conns, l);
	end;
	winBtn(btnX, UI.danger);
	winBtn(btnMin, UI.warn);
end;
refreshMobileUI = function() end;
local startLockAction, endLockAction;
local function isMobileDevice()
	return isMobilePlatform() and _G.mobileCenterAim == true;
end;
local function clampFlex(n, mn, mx)
	if mx < mn then
		return mx;
	end;
	return math.clamp(n, mn, mx);
end;
local function getViewport()
	local c = workspace.CurrentCamera or cam;
	local vp = c and c.ViewportSize or Vector2.new(1280, 720);
	if vp.X <= 0 or vp.Y <= 0 then
		return Vector2.new(1280, 720);
	end;
	return vp;
end;
local function getInputScreenPos(input)
	if input and input.UserInputType == Enum.UserInputType.Touch then
		local p = input.Position;
		return Vector2.new(p.X, p.Y);
	end;
	local ok, pos = pcall(function()
		return UIS:GetMouseLocation();
	end);
	if ok and typeof(pos) == "Vector2" then
		return pos;
	end;
	if input and input.Position then
		local p = input.Position;
		return Vector2.new(p.X, p.Y);
	end;
	return Vector2.zero;
end;
local function getAimPoint()
	local vp = getViewport();
	if isMobileDevice() or ((not isMobilePlatform()) and tostring(_G.targetPointMode or "Cursor") == "Center") then
		return Vector2.new(vp.X * 0.5, vp.Y * 0.5);
	end;
	local ml = UIS:GetMouseLocation();
	return Vector2.new(ml.X, ml.Y);
end;
updateFOVCircle = function()
	local circ = uiRefs.fovCircle;
	if not circ then
		return;
	end;
	local r = math.clamp(tonumber(_G.aimRadius) or 150, 10, 900);
	local pos = getAimPoint();
	circ.Visible = _G.fovCircleEnabled == true;
	circ.Position = UDim2.new(0, pos.X, 0, pos.Y);
	circ.Size = UDim2.new(0, r * 2, 0, r * 2);
	local st = circ:FindFirstChildOfClass("UIStroke");
	if st then
		st.Color = UI.acc2;
		st.Transparency = math.clamp(tonumber(_G.fovCircleAlpha) or 0.25, 0, 1);
		st.Thickness = math.clamp(tonumber(_G.fovCircleThickness) or 2, 1, 8);
	end;
end;
local function frameSizeForViewport()
	local vp = getViewport();
	local touch = isMobilePlatform();
	local maxW = math.max(280, vp.X - 24);
	local maxH = math.max(320, vp.Y - 38);
	local minW = touch and 320 or 460;
	local minH = touch and 390 or 430;
	local w = clampFlex(math.floor(vp.X * (touch and 0.94 or 0.64)), math.min(minW, maxW), maxW);
	local h = clampFlex(math.floor(vp.Y * (touch and 0.82 or 0.76)), math.min(minH, maxH), maxH);
	return w, h;
end;
local function clampFrameToScreen(f)
	if not f then
		return;
	end;
	local vp = getViewport();
	local sz = f.AbsoluteSize;
	if sz.X <= 0 or sz.Y <= 0 then
		return;
	end;
	local pos = f.Position;
	local anchor = f.AnchorPoint;
	local halfX = sz.X * 0.5;
	local halfY = sz.Y * 0.5;
	local centerX = pos.X.Scale * vp.X + pos.X.Offset + (0.5 - anchor.X) * sz.X;
	local centerY = pos.Y.Scale * vp.Y + pos.Y.Offset + (0.5 - anchor.Y) * sz.Y;
	centerX = math.clamp(centerX, halfX + 8, math.max(halfX + 8, vp.X - halfX - 8));
	centerY = math.clamp(centerY, halfY + 8, math.max(halfY + 8, vp.Y - halfY - 8));
	local finalOffsetX = centerX - (pos.X.Scale * vp.X) - ((0.5 - anchor.X) * sz.X);
	local finalOffsetY = centerY - (pos.Y.Scale * vp.Y) - ((0.5 - anchor.Y) * sz.Y);
	f.Position = UDim2.new(pos.X.Scale, finalOffsetX, pos.Y.Scale, finalOffsetY);
end;
local function attachOffsetUIDrag(target, onDragStart, onDragEnd, detectorParent)
	local host = detectorParent or target;
	local ok, detector = pcall(function()
		return newUi("UIDragDetector", host);
	end);
	if not ok or not detector then
		return nil;
	end;
	detector.DragStyle = Enum.UIDragDetectorDragStyle.TranslatePlane;
	detector.ResponseStyle = Enum.UIDragDetectorResponseStyle.Offset;
	local startCon = detector.DragStart:Connect(function()
		if onDragStart then
			onDragStart(target, detector);
		end;
	end);
	local endCon = detector.DragEnd:Connect(function()
		if onDragEnd then
			onDragEnd(target, detector);
		end;
	end);
	table.insert(conns, startCon);
	table.insert(conns, endCon);
	return detector;
end;
local function MouseButtonFix(button, clickCallback)
	if not button or type(clickCallback) ~= "function" then
		return {
			Disconnect = function() end
		};
	end;
	local clickTimeThreshold = 0.45;
	local moveThreshold = 10;
	local mouseDownTime = 0;
	local isPointerDown = false;
	local startPosition = nil;
	local maxMoveDistance = 0;
	local connections = {};
	local function getSignal(obj, signalName)
		local ok, signal = pcall(function()
			return obj[signalName];
		end);
		if ok and signal then
			return signal;
		end;
		return nil;
	end;
	local function connectSignal(signal, fn)
		if not signal then
			return false;
		end;
		local ok, conn = pcall(function()
			return signal:Connect(fn);
		end);
		if ok and conn then
			table.insert(connections, conn);
			return true;
		end;
		return false;
	end;
	local function isPressInput(inputType)
		return inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch;
	end;
	local function resetState()
		mouseDownTime = 0;
		isPointerDown = false;
		startPosition = nil;
		maxMoveDistance = 0;
	end;
	local function beginPointer(input)
		isPointerDown = true;
		mouseDownTime = tick();
		maxMoveDistance = 0;
		local pos = input and input.Position;
		startPosition = pos and Vector2.new(pos.X, pos.Y) or nil;
	end;
	local function endPointer()
		if not isPointerDown or mouseDownTime == 0 then
			resetState();
			return;
		end;
		local holdDuration = tick() - mouseDownTime;
		local isClick = (holdDuration < clickTimeThreshold) and (maxMoveDistance <= moveThreshold);
		resetState();
		if isClick then
			clickCallback();
		end;
	end;
	local boundPress = false;
	local isGuiButton = type(button.IsA) == "function" and button:IsA("GuiButton");
	if isGuiButton then
		local downSignal = getSignal(button, "MouseButton1Down");
		local upSignal = getSignal(button, "MouseButton1Up");
		local downBound = connectSignal(downSignal, function()
			beginPointer(nil);
		end);
		local upBound = connectSignal(upSignal, function()
			endPointer();
		end);
		boundPress = downBound and upBound;
	end;
	if not boundPress then
		local beganSignal = getSignal(button, "InputBegan");
		local endedSignal = getSignal(button, "InputEnded");
		local beganBound = connectSignal(beganSignal, function(input)
			if input and isPressInput(input.UserInputType) then
				beginPointer(input);
			end;
		end);
		local endedBound = connectSignal(endedSignal, function(input)
			if input and isPressInput(input.UserInputType) then
				endPointer();
			end;
		end);
		boundPress = beganBound and endedBound;
	end;
	local changedSignal = getSignal(button, "InputChanged");
	connectSignal(changedSignal, function(input)
		if not isPointerDown then
			return;
		end;
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return;
		end;
		local pos = input.Position;
		if not pos then
			return;
		end;
		if not startPosition then
			startPosition = Vector2.new(pos.X, pos.Y);
			return;
		end;
		local currentPos = Vector2.new(pos.X, pos.Y);
		local delta = (currentPos - startPosition).Magnitude;
		if delta > maxMoveDistance then
			maxMoveDistance = delta;
		end;
	end);
	if not boundPress then
		return {
			Disconnect = function() end
		};
	end;
	return {
		Disconnect = function()
			for _, conn in ipairs(connections) do
				if conn and conn.Disconnect then
					conn:Disconnect();
				end;
			end;
		end
};
end;
local function bindClick(button, callback)
	local conn = MouseButtonFix(button, callback);
	table.insert(conns, conn);
	return conn;
end;
local function disconnectConn(item)
	if typeof(item) == "RBXScriptConnection" then
		if item.Connected then
			item:Disconnect();
		end;
	elseif type(item) == "table" and type(item.Disconnect) == "function" then
		item:Disconnect();
	end;
end;
local function attachBetterDragger(ui, dragTargets, onDragEnd)
	if not ui then
		return;
	end;
	local handles = {};
	if typeof(dragTargets) == "Instance" then
		handles = {
			dragTargets
		};
	elseif type(dragTargets) == "table" then
		for _, handle in ipairs(dragTargets) do
			if typeof(handle) == "Instance" then
				table.insert(handles, handle);
			end;
		end;
	end;
	if #handles == 0 then
		handles = {
			ui
		};
	end;
	local dragging = false;
	local dragStart = nil;
	local startPos = nil;
	local dragPointer = nil;
	local pendingInput = nil;
	local moved = false;
	local moveConn = nil;
	local endConn = nil;
	local stepConn = nil;
	local function disconnectLiveInput()
		if moveConn then
			moveConn:Disconnect();
			moveConn = nil;
		end;
		if endConn then
			endConn:Disconnect();
			endConn = nil;
		end;
		if stepConn then
			stepConn:Disconnect();
			stepConn = nil;
		end;
		pendingInput = nil;
	end;
	local function getOrder(g)
		local z = g.ZIndex or 0;
		local lc = g:FindFirstAncestorWhichIsA("LayerCollector");
		local d = 0;
		if lc and lc:IsA("ScreenGui") then
			d = lc.DisplayOrder or 0;
		end;
		return d * 10000 + z;
	end;
	local function isTopMost(root, input)
		local pos = input.Position;
		local list;
		local ok = pcall(function()
			list = GS:GetGuiObjectsAtPosition(pos.X, pos.Y);
		end);
		if not ok or type(list) ~= "table" or #list == 0 then
			return true;
		end;
		local top, topOrder;
		for _, g in ipairs(list) do
			if typeof(g) == "Instance" and g:IsA("GuiObject") then
				local ord = getOrder(g);
				if not top or ord > topOrder then
					top = g;
					topOrder = ord;
				end;
			end;
		end;
		if not top then
			return true;
		end;
		return top == root or top:IsDescendantOf(root);
	end;
	local function stopDrag()
		if not dragging then
			return;
		end;
		dragging = false;
		dragPointer = nil;
		disconnectLiveInput();
		if onDragEnd then
			onDragEnd(ui, moved);
		end;
	end;
	local function update(input)
		if not ui or not ui.Parent then
			return;
		end;
		local screenSize = ui.Parent.AbsoluteSize;
		if not screenSize or screenSize.X <= 0 or screenSize.Y <= 0 then
			return;
		end;
		local delta = input.Position - dragStart;
		if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then
			moved = true;
		end;
		local newXScale = startPos.X.Scale + ((startPos.X.Offset + delta.X) / screenSize.X);
		local newYScale = startPos.Y.Scale + ((startPos.Y.Offset + delta.Y) / screenSize.Y);
		ui.Position = UDim2.new(newXScale, 0, newYScale, 0);
	end;
	local function beginDrag(root, input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return;
		end;
		if dragging or not isTopMost(root, input) then
			return;
		end;
		dragging = true;
		dragPointer = input;
		dragStart = input.Position;
		startPos = ui.Position;
		moved = false;
		disconnectLiveInput();
		moveConn = UIS.InputChanged:Connect(function(changedInput)
			if not dragging then
				return;
			end;
			local inputType = changedInput.UserInputType;
			if inputType == Enum.UserInputType.MouseMovement then
				pendingInput = changedInput;
				return;
			end;
			if inputType == Enum.UserInputType.Touch and changedInput == dragPointer then
				pendingInput = changedInput;
			end;
		end);
		endConn = UIS.InputEnded:Connect(function(endedInput)
			if not dragging then
				return;
			end;
			local inputType = endedInput.UserInputType;
			if inputType == Enum.UserInputType.MouseButton1 or (inputType == Enum.UserInputType.Touch and endedInput == dragPointer) then
				stopDrag();
			end;
		end);
		stepConn = RunService.RenderStepped:Connect(function()
			local frameInput = pendingInput;
			if not frameInput then
				return;
			end;
			pendingInput = nil;
			if not dragging then
				return;
			end;
			update(frameInput);
		end);
	end;
	for _, handle in ipairs(handles) do
		pcall(function()
			handle.Active = true;
		end);
		table.insert(conns, handle.InputBegan:Connect(function(input)
			beginDrag(handle, input);
		end));
	end;
	if ui and ui.AncestryChanged then
		table.insert(conns, ui.AncestryChanged:Connect(function(_, parent)
			if not parent then
				stopDrag();
			end;
		end));
	end;
	if ui and ui.Destroying then
		table.insert(conns, ui.Destroying:Connect(function()
			stopDrag();
		end));
	end;
	pcall(function()
		ui.Active = true;
	end);
end;
local function goodPart(p)
	if not p or (not p:IsA("BasePart")) then
		return false;
	end;
	if p.Transparency >= 0.95 then
		return false;
	end;
	if p.CanQuery == false then
		return false;
	end;
	if p.CanCollide == false then
		return false;
	end;
	return true;
end;
local function clearLOS(targetPart)
	if not targetPart then
		return false;
	end;
	local origin = cam.CFrame.Position;
	local dir = targetPart.Position - origin;
	local ignore = {
		plr.Character,
		targetPart.Parent
	};
	local params = RaycastParams.new();
	params.FilterType = Enum.RaycastFilterType.Blacklist;
	params.FilterDescendantsInstances = ignore;
	params.IgnoreWater = true;
	local maxHops = 10;
	local curOrigin = origin;
	local remaining = dir;
	for _ = 1, maxHops do
		local r = workspace:Raycast(curOrigin, remaining, params);
		if not r then
			return true;
		end;
		local hit = r.Instance;
		if not goodPart(hit) or hit:IsDescendantOf(targetPart.Parent) then
			table.insert(ignore, hit);
			params.FilterDescendantsInstances = ignore;
			curOrigin = r.Position + remaining.Unit * 0.01;
			remaining = origin + dir - curOrigin;
		else
			return false;
		end;
	end;
	return false;
end;
local function getTeamColor(p)
	if _G.espTeamColor then
		if p.Team and p.Team.TeamColor then
			local bc = p.Team.TeamColor;
			if typeof(bc) == "BrickColor" then
				return bc.Color;
			end;
		end;
		if p.TeamColor then
			local bc = p.TeamColor;
			if typeof(bc) == "BrickColor" then
				return bc.Color;
			end;
		end;
	end;
	return UI.fallback;
end;
local function sanitizeNumber(txt, min, max, def)
	local s = tostring(txt or "");
	local out, dot = {}, false;
	for i = 1, #s do
		local ch = s:sub(i, i);
		if ch:match("%d") then
			table.insert(out, ch);
		elseif ch == "." and (not dot) then
			table.insert(out, ch);
			dot = true;
		end;
	end;
	local num = tonumber(table.concat(out, ""));
	if not num then
		num = def;
	end;
	if min then
		num = math.max(min, num);
	end;
	if max then
		num = math.min(max, num);
	end;
	return num;
end;
local function toast(msg)
	if not gui or (not toastHolder) then
		return;
	end;
	toastIdx += 1;
	local card, isCg = fadeFrame();
	setUiTag(card, "Toast");
	card.Size = UDim2.new(1, 0, 0, _G.toastCompact and 48 or 64);
	card.Position = UDim2.new(0, 44, 0, 0);
	card.BackgroundColor3 = UI.toast;
	card.BackgroundTransparency = 0.01;
	card.BorderSizePixel = 0;
	card.ClipsDescendants = true;
	card.LayoutOrder = -toastIdx;
	card.ZIndex = 100;
	if isCg then
		card.GroupTransparency = 1;
	end;
	card.Parent = toastHolder;
	round(card, UDim.new(0, 18));
	stroke(card, 1, UI.stroke2, 0.12);
	noGrad(card);
	local accent = UI.acc2;
	local m = tostring(msg or "");
	local low = m:lower();
	if low:find("unload") or low:find("reset") then
		accent = UI.danger;
	elseif low:find("copied") or low:find("loaded") then
		accent = UI.ok;
	elseif low:find("press") or low:find("minimized") then
		accent = UI.warn;
	end;
	local side = newUi("Frame", card);
	side.Size = UDim2.new(0, 5, 1, -14);
	side.Position = UDim2.new(0, 8, 0, 7);
	side.BackgroundColor3 = accent;
	side.BorderSizePixel = 0;
	side.ZIndex = 101;
	round(side, UDim.new(1, 0));
	grad(side, accent, UI.acc, 90);
	local icon = newUi("TextLabel", card);
	icon.BackgroundColor3 = accent;
	icon.BackgroundTransparency = 0.86;
	icon.BorderSizePixel = 0;
	icon.Position = UDim2.new(0, 22, 0.5, _G.toastCompact and -12 or -16);
	icon.Size = _G.toastCompact and UDim2.new(0, 24, 0, 24) or UDim2.new(0, 32, 0, 32);
	icon.Font = Enum.Font.GothamBlack;
	icon.Text = "!";
	icon.TextSize = 16;
	icon.TextColor3 = accent;
	icon.ZIndex = 101;
	round(icon, UDim.new(1, 0));
	stroke(icon, 1, accent, 0.25);
	local title = newUi("TextLabel", card);
	title.BackgroundTransparency = 1;
	title.Position = UDim2.new(0, 64, 0, _G.toastCompact and 7 or 10);
	title.Size = UDim2.new(1, -82, 0, 18);
	title.Font = Enum.Font.GothamBlack;
	title.TextSize = 13;
	title.TextColor3 = UI.text;
	title.TextXAlignment = Enum.TextXAlignment.Left;
	title.Text = "VYPERIA-AIMBOT";
	title.ZIndex = 101;
	local body = newUi("TextLabel", card);
	body.BackgroundTransparency = 1;
	body.Position = UDim2.new(0, 64, 0, _G.toastCompact and 25 or 30);
	body.Size = UDim2.new(1, -78, 0, 20);
	body.Font = Enum.Font.GothamMedium;
	body.TextSize = 13;
	body.TextColor3 = UI.sub;
	body.TextXAlignment = Enum.TextXAlignment.Left;
	body.TextTruncate = Enum.TextTruncate.AtEnd;
	body.Text = m;
	body.ZIndex = 101;
	local prog = newUi("Frame", card);
	prog.AnchorPoint = Vector2.new(0, 1);
	prog.Position = UDim2.new(0, 20, 1, -7);
	prog.Size = UDim2.new(1, -40, 0, 2);
	prog.BackgroundColor3 = accent;
	prog.BorderSizePixel = 0;
	prog.ZIndex = 101;
	round(prog, UDim.new(1, 0));
	local props = {
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 0.01
	};
	if isCg then
		props.GroupTransparency = 0;
	end;
	tw(card, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props);
	tw(prog, TweenInfo.new(math.max(0.2, (_G.toastDuration or 3) - 0.3), Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 0, 2)
	});
	local live = {};
	for _, c in ipairs(toastHolder:GetChildren()) do
		if c:IsA("GuiObject") and c.Name:match("^Toast_") then
			table.insert(live, c);
		end;
	end;
	table.sort(live, function(a, b)
		return a.LayoutOrder < b.LayoutOrder;
	end);
	for i = (_G.toastMax or 4) + 1, #live do
		local old = live[i];
		if old and old.Parent then
			old:Destroy();
		end;
	end;
	task.delay(_G.toastDuration or 3, function()
		if not card or (not card.Parent) then
			return;
		end;
		local outProps = {
			Position = UDim2.new(0, 44, 0, 0),
			BackgroundTransparency = 1
		};
		if isCg then
			outProps.GroupTransparency = 1;
		end;
		tw(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), outProps);
		task.delay(0.25, function()
			if card and card.Parent then
				card:Destroy();
			end;
		end);
	end);
end;
local function saveCfg()
	if not writefile or (not HS) then
		return;
	end;
	local okFolder = true;
	if isfolder and (not isfolder(cfgDir)) then
		if makefolder then
			local s, e = pcall(makefolder, cfgDir);
			okFolder = s and e == nil or s;
		else
			okFolder = false;
		end;
	end;
	if not okFolder then
		return;
	end;
	local aimMode = normalizeAimMode(_G.aimTargetMode);
	_G.aimTargetMode = aimMode;
	local data = {
		isEnabled = _G.isEnabled,
		aimTargetMode = aimMode,
		espEnabled = _G.espEnabled,
		lockToNearest = _G.lockToNearest,
		aliveCheck = _G.aliveCheck,
		teamCheck = _G.teamCheck,
		wallCheck = _G.wallCheck,
		aimTween = _G.aimTween,
		aimSmooth = _G.aimSmooth,
		fovEnabled = _G.fovEnabled,
		fovValue = _G.fovValue,
		espShowName = _G.espShowName,
		espShowHP = _G.espShowHP,
		espShowTeam = _G.espShowTeam,
		espTeamColor = _G.espTeamColor,
		espTransparency = _G.espTransparency,
		tbCPS = _G.tbCPS,
		aimPredict = _G.aimPredict,
		aimLead = _G.aimLead,
		aimRadius = _G.aimRadius,
		aimLock = _G.aimLock,
		lockKey = _G.lockKey,
		mobileCenterAim = _G.mobileCenterAim,
		mobileButtons = _G.mobileButtons,
		uiScale = _G.uiScale,
		uiWindowAlpha = _G.uiWindowAlpha,
		uiContentAlpha = _G.uiContentAlpha,
		uiTheme = _G.uiTheme,
		uiAnimations = _G.uiAnimations,
		uiAnimSpeed = _G.uiAnimSpeed,
		uiCompact = _G.uiCompact,
		uiRounded = _G.uiRounded,
		toastDuration = _G.toastDuration,
		toastMax = _G.toastMax,
		toastCompact = _G.toastCompact,
		toastPosition = _G.toastPosition,
		centerDotVisible = _G.centerDotVisible,
		centerDotSize = _G.centerDotSize,
		centerDotAlpha = _G.centerDotAlpha,
		mobileButtonScale = _G.mobileButtonScale,
		mobileButtonAlpha = _G.mobileButtonAlpha,
		mobileHelperButtons = _G.mobileHelperButtons,
		mobileHelperPos = _G.mobileHelperPos,
		pendingMobileAction = _G.pendingMobileAction,
		topTogglePos = _G.topTogglePos,
		optionBinds = _G.optionBinds,
		toggleKeys = _G.toggleKeys,
		espRenderMode = _G.espRenderMode,
		espAlwaysOnTop = _G.espAlwaysOnTop,
		espShowDistance = _G.espShowDistance,
		espTextSize = _G.espTextSize,
		espMaxDistance = _G.espMaxDistance,
		espOutlineTransparency = _G.espOutlineTransparency,
		targetPriorityMode = _G.targetPriorityMode,
		stickyTarget = _G.stickyTarget,
		targetMaxDistance = _G.targetMaxDistance
	};
	local ok, enc = pcall(function()
		return HS:JSONEncode(data);
	end);
	if ok and enc then
		pcall(writefile, cfgFile, enc);
	end;
end;
local function loadCfg()
	if not readfile or (not isfile) or (not HS) then
		return;
	end;
	if not isfile(cfgFile) then
		return;
	end;
	local ok, txt = pcall(readfile, cfgFile);
	if not ok or (not txt) or txt == "" then
		return;
	end;
	local ok2, obj = pcall(function()
		return HS:JSONDecode(txt);
	end);
	if not ok2 or type(obj) ~= "table" then
		return;
	end;
	if obj.lockToHead ~= nil and obj.aimTargetMode == nil then
		obj.aimTargetMode = obj.lockToHead and "Head" or "Torso";
	end;
	if obj.aimTargetMode then
		obj.aimTargetMode = normalizeAimMode(obj.aimTargetMode);
	end;
	if obj.uiTheme then
		obj.uiTheme = normChoice(obj.uiTheme, THEME_OPTIONS, "Midnight Purple");
	end;
	if obj.toastPosition then
		obj.toastPosition = normChoice(obj.toastPosition, TOAST_POS_OPTIONS, "Top Right");
	end;
	if obj.targetPriorityMode then
		obj.targetPriorityMode = normChoice(obj.targetPriorityMode, TARGET_PRIORITY_OPTIONS, "Crosshair");
	end;
	if obj.espRenderMode then
		obj.espRenderMode = normChoice(obj.espRenderMode, ESP_RENDER_OPTIONS, "Highlight");
	end;
	if obj.pendingMobileAction then
		obj.pendingMobileAction = normChoice(obj.pendingMobileAction, MOBILE_ACTION_OPTIONS, "Aimbot");
	end;
	if obj.targetPointMode then
		obj.targetPointMode = normChoice(obj.targetPointMode, TARGET_POINT_OPTIONS, "Cursor");
	end;
	if obj.fovCircleAlpha ~= nil then
		obj.fovCircleAlpha = math.clamp(tonumber(obj.fovCircleAlpha) or 0.25, 0, 1);
	end;
	if obj.fovCircleThickness ~= nil then
		obj.fovCircleThickness = math.clamp(tonumber(obj.fovCircleThickness) or 2, 1, 8);
	end;
	if type(obj.topTogglePos) ~= "table" then
		obj.topTogglePos = nil;
	end;
	if type(obj.mobileHelperPos) ~= "table" then
		obj.mobileHelperPos = nil;
	end;
	if type(obj.optionBinds) ~= "table" then
		obj.optionBinds = {};
	end;
	if type(obj.mobileHelperButtons) ~= "table" then
		obj.mobileHelperButtons = nil;
	end;
	if obj.espTransparency ~= nil then
		obj.espTransparency = math.clamp(obj.espTransparency, 0, 1);
	end;
	if obj.espOutlineTransparency ~= nil then
		obj.espOutlineTransparency = math.clamp(tonumber(obj.espOutlineTransparency) or 0.12, 0, 1);
	end;
	if obj.espTextSize ~= nil then
		obj.espTextSize = math.clamp(tonumber(obj.espTextSize) or 14, 10, 24);
	end;
	if obj.espMaxDistance ~= nil then
		obj.espMaxDistance = math.clamp(tonumber(obj.espMaxDistance) or 2500, 100, 5000);
	end;
	if obj.targetMaxDistance ~= nil then
		obj.targetMaxDistance = math.clamp(tonumber(obj.targetMaxDistance) or 2500, 100, 5000);
	end;
	for k, v in pairs(obj) do
		if _G[k] ~= nil then
			_G[k] = v;
		end;
	end;
end;
loadCfg();
_G.targetPointMode = normChoice(_G.targetPointMode, TARGET_POINT_OPTIONS, "Cursor");
_G.fovCircleAlpha = math.clamp(tonumber(_G.fovCircleAlpha) or 0.25, 0, 1);
_G.fovCircleThickness = math.clamp(tonumber(_G.fovCircleThickness) or 2, 1, 8);
_G.espRenderMode = normChoice(_G.espRenderMode, ESP_RENDER_OPTIONS, "Highlight");
_G.pendingMobileAction = normChoice(_G.pendingMobileAction, MOBILE_ACTION_OPTIONS, "Aimbot");
_G.targetPriorityMode = normChoice(_G.targetPriorityMode, TARGET_PRIORITY_OPTIONS, "Crosshair");
_G.mobileHelperButtons = normalizeActionList(_G.mobileHelperButtons, MOBILE_ACTION_OPTIONS, MOBILE_HELPER_DEFAULTS);
_G.espTextSize = math.clamp(tonumber(_G.espTextSize) or 14, 10, 24);
_G.espMaxDistance = math.clamp(tonumber(_G.espMaxDistance) or 2500, 100, 5000);
_G.espOutlineTransparency = math.clamp(tonumber(_G.espOutlineTransparency) or 0.12, 0, 1);
_G.targetMaxDistance = math.clamp(tonumber(_G.targetMaxDistance) or 2500, 100, 5000);
applyTheme(_G.uiTheme);
local camFOVCon, camSwapCon;
local function bindFOV()
	if camFOVCon then
		camFOVCon:Disconnect();
		camFOVCon = nil;
	end;
	if not cam then
		return;
	end;
	camFOVCon = (cam:GetPropertyChangedSignal("FieldOfView")):Connect(function()
		if _G.fovEnabled and math.abs((cam.FieldOfView or 70) - (_G.fovValue or 70)) > 0.01 then
			cam.FieldOfView = _G.fovValue;
		end;
	end);
end;
local function clearFOVHooks()
	if camFOVCon then
		camFOVCon:Disconnect();
		camFOVCon = nil;
	end;
	if camSwapCon then
		camSwapCon:Disconnect();
		camSwapCon = nil;
	end;
end;
local function hookCamera()
	cam = workspace.CurrentCamera;
	if camSwapCon then
		camSwapCon:Disconnect();
	end;
	camSwapCon = (workspace:GetPropertyChangedSignal("CurrentCamera")):Connect(function()
		cam = workspace.CurrentCamera;
		bindFOV();
		if _G.fovEnabled and cam then
			cam.FieldOfView = _G.fovValue;
		end;
	end);
	bindFOV();
end;
hookCamera();
local NA_GRAB_BODY = (function()
	local _cache = {};
	local function asChar(obj)
		if not obj or typeof(obj) ~= "Instance" then
			return nil;
		end;
		if obj:IsA("Player") then
			return obj.Character;
		end;
		if obj:IsA("Model") then
			return obj;
		end;
		return nil;
	end;
	local function firstPart(model)
		for _, d in ipairs(model:QueryDescendants("Instance")) do
			if d:IsA("BasePart") then
				return d;
			end;
		end;
		return nil;
	end;
	local function rebuild(model, rec)
		rec.head = nil;
		rec.root = nil;
		rec.torso = nil;
		rec.humanoid = nil;
		rec.parts = {};
		for _, inst in ipairs(model:QueryDescendants("Instance")) do
			if inst:IsA("Humanoid") or inst:IsA("AnimationController") then
				rec.humanoid = rec.humanoid or inst;
			elseif inst:IsA("BasePart") then
				table.insert(rec.parts, inst);
				local ln = inst.Name:lower();
				if ln:find("root") then
					rec.root = rec.root or inst;
				elseif ln:find("torso") then
					rec.torso = rec.torso or inst;
				elseif ln:find("head") then
					rec.head = rec.head or inst;
				end;
			end;
		end;
		rec.dirty = false;
	end;
	local function ensure(obj)
		local model = asChar(obj) or obj;
		if not model or (not model:IsA("Model")) then
			return nil;
		end;
		local rec = _cache[model];
		if not rec then
			rec = {
				dirty = true
			};
			_cache[model] = rec;
			rec.a = model.DescendantAdded:Connect(function()
				rec.dirty = true;
			end);
			rec.r = model.DescendantRemoving:Connect(function()
				rec.dirty = true;
			end);
			rec.c = model.AncestryChanged:Connect(function(_, parent)
				if parent then
					return;
				end;
				if rec.a then
					rec.a:Disconnect();
				end;
				if rec.r then
					rec.r:Disconnect();
				end;
				if rec.c then
					rec.c:Disconnect();
				end;
				_cache[model] = nil;
			end);
		end;
		if rec.dirty or rec.humanoid and rec.humanoid.Parent == nil then
			rebuild(model, rec);
		end;
		return rec, model;
	end;
	return {
		ensure = ensure,
		firstPart = firstPart,
		asChar = asChar
	};
end)();
local function getHumanoid(m)
	local rec = NA_GRAB_BODY.ensure(m);
	return rec and rec.humanoid or nil;
end;
local function getPart(m, name)
	local rec, model = NA_GRAB_BODY.ensure(m);
	if not rec or (not model) then
		return nil;
	end;
	local lname = (tostring(name or "")):lower();
	if lname == "head" and rec.head then
		return rec.head;
	end;
	if (lname == "humanoidrootpart" or lname == "rootpart") and rec.root then
		return rec.root;
	end;
	if (lname == "upper torso" or lname == "upper_torso" or lname == "upper" or lname == "lower torso" or lname == "torso") and rec.torso then
		return rec.torso;
	end;
	local direct = model:FindFirstChild(name, true);
	if direct and direct:IsA("BasePart") then
		return direct;
	end;
	return rec.root or rec.torso or rec.head or NA_GRAB_BODY.firstPart(model);
end;
local function getTorsoLikePart(m)
	return getPart(m, "HumanoidRootPart") or getPart(m, "UpperTorso") or getPart(m, "LowerTorso") or getPart(m, "Torso");
end;
local function usableAimPart(part, model)
	if not part or (not part:IsA("BasePart")) then
		return false;
	end;
	if not model or (not model:IsA("Model")) then
		return false;
	end;
	if not part.Parent or (not part:IsDescendantOf(model)) then
		return false;
	end;
	if part.Transparency >= 1 then
		return false;
	end;
	if part:FindFirstAncestorOfClass("Accessory") then
		return false;
	end;
	return true;
end;
local function aimPartPool(m, needLOS)
	local rec, model = NA_GRAB_BODY.ensure(m);
	if not rec or (not model) then
		return {};
	end;
	local pool = {};
	local seen = {};
	local function add(part, weight)
		if not usableAimPart(part, model) or seen[part] then
			return;
		end;
		if needLOS and (not clearLOS(part)) then
			return;
		end;
		seen[part] = true;
		for _ = 1, weight or 1 do
			table.insert(pool, part);
		end;
	end;
	add(getPart(model, "Head"), 4);
	add(getPart(model, "HumanoidRootPart"), 2);
	add(getPart(model, "UpperTorso"), 2);
	add(getPart(model, "LowerTorso"), 1);
	add(getPart(model, "Torso"), 1);
	if rec.parts then
		for _, part in ipairs(rec.parts) do
			add(part, 1);
		end;
	end;
	return pool;
end;
local function chooseAimPart(pool, avoid)
	if avoid then
		local alt = {};
		for _, part in ipairs(pool) do
			if part ~= avoid then
				table.insert(alt, part);
			end;
		end;
		if #alt > 0 then
			pool = alt;
		end;
	end;
	if #pool > 0 then
		return pool[rng:NextInteger(1, #pool)];
	end;
	return nil;
end;
local function randomVisibleAimPart(m, avoid)
	return chooseAimPart(aimPartPool(m, true), avoid);
end;
local function pickPreferredPart(m, prefer)
	local head = getPart(m, "Head");
	local torso = getTorsoLikePart(m);
	local order = {};
	if prefer == "Head" then
		table.insert(order, head);
		table.insert(order, torso);
	else
		table.insert(order, torso);
		table.insert(order, head);
	end;
	local fallback = nil;
	for _, part in ipairs(order) do
		if usableAimPart(part, m) then
			if not _G.wallCheck or clearLOS(part) then
				return part;
			end;
			fallback = fallback or part;
		end;
	end;
	if _G.wallCheck then
		return randomVisibleAimPart(m, fallback);
	end;
	return fallback;
end;
local function getRandomAimPart(m, avoid)
	return chooseAimPart(aimPartPool(m, _G.wallCheck == true), avoid);
end;
local function bumpRandomAim(ch)
	randomAimSeq = randomAimSeq + 1;
end;
local function randomTargetFor(ch)
	local rec = randomAimCache[ch];
	if rec and rec.seq == randomAimSeq and rec.part and rec.part.Parent and rec.part:IsDescendantOf(ch) and ((not _G.wallCheck) or clearLOS(rec.part)) then
		return rec.part;
	end;
	local prev = rec and rec.part or nil;
	local p = getRandomAimPart(ch, prev);
	randomAimCache[ch] = {
		part = p,
		seq = randomAimSeq
	};
	return p;
end;
local function getPartVelocity(part)
	if not part then
		return Vector3.zero;
	end;
	local ch = part.Parent;
	local root = ch and getPart(ch, "HumanoidRootPart");
	local src = root or part;
	local ok, v = pcall(function()
		return src.AssemblyLinearVelocity;
	end);
	if ok and typeof(v) == "Vector3" then
		return v;
	end;
	ok, v = pcall(function()
		return src.Velocity;
	end);
	if ok and typeof(v) == "Vector3" then
		return v;
	end;
	return Vector3.zero;
end;
local function getPredictedAimPos(part)
	local base = part.Position;
	local camPos = cam and cam.CFrame.Position or base;
	local dist = (base - camPos).Magnitude;
	local lead = math.clamp(tonumber(_G.aimLead) or 0.12, 0, 1);
	if dist < 14 or lead <= 0 then
		return base;
	end;
	local vel = getPartVelocity(part);
	if vel.Magnitude < 1 then
		return base;
	end;
	local distScale = math.clamp((dist - 14) / 170, 0, 1);
	local yScale = math.clamp((dist - 45) / 180, 0, 0.35);
	vel = Vector3.new(vel.X, vel.Y * yScale, vel.Z);
	local off = vel * lead * distScale;
	local maxOff = math.clamp(dist * 0.075, 0.75, 9);
	if off.Magnitude > maxOff then
		off = off.Unit * maxOff;
	end;
	return base + off;
end;
local function topAimPart(m)
	local aimMode = normalizeAimMode(_G.aimTargetMode);
	_G.aimTargetMode = aimMode;
	if aimMode == "Head" then
		local p = pickPreferredPart(m, "Head");
		if p then
			return p;
		end;
	elseif aimMode == "Random" then
		local p = randomTargetFor(m);
		if p then
			return p;
		end;
	elseif aimMode == "Root" then
		local p = getPart(m, "HumanoidRootPart");
		if p and ((not _G.wallCheck) or clearLOS(p)) then
			return p;
		end;
		if _G.wallCheck then
			return randomVisibleAimPart(m, p);
		end;
	elseif aimMode == "Upper Torso" then
		local p = getPart(m, "UpperTorso") or getPart(m, "Torso");
		if p and ((not _G.wallCheck) or clearLOS(p)) then
			return p;
		end;
		if _G.wallCheck then
			return randomVisibleAimPart(m, p);
		end;
	elseif aimMode == "Lower Torso" then
		local p = getPart(m, "LowerTorso") or getPart(m, "Torso");
		if p and ((not _G.wallCheck) or clearLOS(p)) then
			return p;
		end;
		if _G.wallCheck then
			return randomVisibleAimPart(m, p);
		end;
	else
		local p = pickPreferredPart(m, "Torso");
		if p then
			return p;
		end;
	end;
	if _G.wallCheck then
		return randomVisibleAimPart(m);
	end;
	return getTorsoLikePart(m) or getPart(m, "Head");
end;
local function getScanAimPart(ch)
	local aimMode = normalizeAimMode(_G.aimTargetMode);
	local candidates = {};
	local function add(part)
		if part and usableAimPart(part, ch) then
			table.insert(candidates, part);
		end;
	end;
	if aimMode == "Head" then
		add(getPart(ch, "Head"));
		add(getTorsoLikePart(ch));
	elseif aimMode == "Root" then
		add(getPart(ch, "HumanoidRootPart"));
		add(getTorsoLikePart(ch));
		add(getPart(ch, "Head"));
	elseif aimMode == "Upper Torso" then
		add(getPart(ch, "UpperTorso") or getPart(ch, "Torso"));
		add(getPart(ch, "HumanoidRootPart"));
		add(getPart(ch, "Head"));
	elseif aimMode == "Lower Torso" then
		add(getPart(ch, "LowerTorso") or getPart(ch, "Torso"));
		add(getPart(ch, "HumanoidRootPart"));
		add(getPart(ch, "Head"));
	else
		add(getPart(ch, "HumanoidRootPart"));
		add(getPart(ch, "UpperTorso") or getPart(ch, "Torso"));
		add(getPart(ch, "Head"));
	end;
	for _, part in ipairs(candidates) do
		if not _G.wallCheck or clearLOS(part) then
			return part;
		end;
	end;
	if _G.wallCheck then
		return nil;
	end;
	return candidates[1];
end;
local function isTrackedAimPartUsable(ch, part, requireLOS)
	if not usableAimPart(part, ch) then
		return false;
	end;
	if requireLOS and _G.wallCheck and (not clearLOS(part)) then
		return false;
	end;
	return true;
end;
local function isEnemy(op)
	if not _G.teamCheck then
		return true;
	end;
	if mode == "FFA" then
		return true;
	else
		return op.Team ~= nil and plr.Team ~= nil and op.Team ~= plr.Team;
	end;
end;
local function isAlive(ch)
	if not _G.aliveCheck then
		return true;
	end;
	if not ch then
		return false;
	end;
	local hum = getHumanoid(ch);
	return hum and hum.Health > 0;
end;
local function getTargetPriorityMode()
	_G.targetPriorityMode = normChoice(_G.targetPriorityMode, TARGET_PRIORITY_OPTIONS, "Crosshair");
	return _G.targetPriorityMode;
end;
local function isCharacterStillTargetable(ch, preferredPart)
	if not ch or not ch.Parent then
		return false, nil;
	end;
	local op = Players:GetPlayerFromCharacter(ch);
	if not op or op == plr or (not isEnemy(op)) or (not isAlive(ch)) then
		return false, nil;
	end;
	local part = isTrackedAimPartUsable(ch, preferredPart, _G.wallCheck == true) and preferredPart or getScanAimPart(ch);
	local hum = getHumanoid(ch);
	if not part or not hum or hum.Health <= 0 then
		return false, nil;
	end;
	local scr, on = cam:WorldToViewportPoint(part.Position);
	if not on then
		return false, nil;
	end;
	local dist = (part.Position - cam.CFrame.Position).Magnitude;
	if dist > math.clamp(tonumber(_G.targetMaxDistance) or 2500, 100, 5000) then
		return false, nil;
	end;
	if getTargetPriorityMode() == "Crosshair" then
		local mp = getAimPoint();
		local sdist = (Vector2.new(scr.X, scr.Y) - mp).Magnitude;
		if sdist > (_G.aimRadius or 150) then
			return false, nil;
		end;
	end;
	return true, part;
end;
local function findTarget()
	local stickyOk, stickyPart = false, nil;
	if _G.stickyTarget then
		stickyOk, stickyPart = isCharacterStillTargetable(lastLockedCharacter, lastLockedPart);
	end;
	if stickyOk then
		lastTargetName = lastLockedCharacter.Name;
		lastLockedPart = stickyPart;
		return lastLockedCharacter, stickyPart;
	end;
	local near = nil;
	local nearPart = nil;
	local bestPrimary = math.huge;
	local bestSecondary = math.huge;
	local modeName = getTargetPriorityMode();
	local maxR = _G.aimRadius or 150;
	local maxDistance = math.clamp(tonumber(_G.targetMaxDistance) or 2500, 100, 5000);
	local mp = getAimPoint();
	for _, op in ipairs(Players:GetPlayers()) do
		if op ~= plr and op.Character and isEnemy(op) then
			local ch = op.Character;
			if not isAlive(ch) then
				continue;
			end;
			local part = getScanAimPart(ch);
			local hum = getHumanoid(ch);
			if part and hum and hum.Health > 0 then
				local scr, on = cam:WorldToViewportPoint(part.Position);
				if on then
					local dist = (part.Position - cam.CFrame.Position).Magnitude;
					if dist > maxDistance then
						continue;
					end;
					local sdist = (Vector2.new(scr.X, scr.Y) - mp).Magnitude;
					if modeName == "Crosshair" and sdist > maxR then
						continue;
					end;
					local primary = sdist;
					local secondary = dist;
					if modeName == "Distance" or _G.lockToNearest then
						primary = dist;
						secondary = sdist;
					elseif modeName == "Lowest Health" then
						primary = hum.Health;
						secondary = sdist;
					end;
					if primary < bestPrimary or (math.abs(primary - bestPrimary) < 0.001 and secondary < bestSecondary) then
						bestPrimary = primary;
						bestSecondary = secondary;
						near = ch;
						nearPart = part;
					end;
				end;
			end;
		end;
	end;
	lastTargetName = near and near.Name or "none";
	lastLockedCharacter = near;
	lastLockedPart = nearPart;
	return near, nearPart;
end;
local function getLockRefreshInterval()
	local interval = 0.05;
	if _G.wallCheck then
		interval += 0.02;
	end;
	if normalizeAimMode(_G.aimTargetMode) == "Random" then
		interval += 0.03;
	end;
	return math.clamp(interval, 0.04, 0.12);
end;
local function updateESPText(p)
	local rec = espMap[p];
	if not rec or (not rec.tx) then
		return;
	end;
	local nameStr = _G.espShowName and p.Name or "";
	local hpStr = "";
	local ch = p.Character;
	local hum = ch and getHumanoid(ch);
	if _G.espShowHP and hum then
		hpStr = "HP: " .. math.floor(hum.Health);
	end;
	local teamStr = "";
	if _G.espShowTeam and p.Team then
		teamStr = p.Team.Name;
	end;
	local distStr = "";
	if _G.espShowDistance and ch and cam then
		local anchor = topAimPart(ch);
		if anchor then
			distStr = "DIST: " .. math.floor((anchor.Position - cam.CFrame.Position).Magnitude);
		end;
	end;
	local lines = {};
	if nameStr ~= "" then
		table.insert(lines, nameStr);
	end;
	if hpStr ~= "" then
		table.insert(lines, hpStr);
	end;
	if teamStr ~= "" then
		table.insert(lines, teamStr);
	end;
	if distStr ~= "" then
		table.insert(lines, distStr);
	end;
	rec.tx.Text = table.concat(lines, "\n");
	rec.tx.TextSize = math.clamp(tonumber(_G.espTextSize) or 14, 10, 24);
	rec.bb.Enabled = #lines > 0;
end;
local function espDetach(p)
	local rec = espMap[p];
	if not rec then
		return;
	end;
	if rec.conns then
		for _, cc in ipairs(rec.conns) do
			if typeof(cc) == "RBXScriptConnection" and cc.Connected then
				cc:Disconnect();
			end;
		end;
	end;
	if rec.hi and rec.hi.Parent then
		rec.hi:Destroy();
	end;
	if rec.box and rec.box.Parent then
		rec.box:Destroy();
	end;
	if rec.bb and rec.bb.Parent then
		rec.bb:Destroy();
	end;
	espMap[p] = nil;
end;
local function getTeamColorSafe(p)
	if mode == "FFA" then
		return UI.fallback;
	end;
	return getTeamColor(p);
end;
local function getEspDistance(ch)
	local part = ch and topAimPart(ch);
	if not part or not cam then
		return math.huge;
	end;
	return (part.Position - cam.CFrame.Position).Magnitude;
end;
local function getESPAdornmentParent()
	return workspace.CurrentCamera or cam or uiRoot;
end;
local function ensureESPBillboard(rec, ch)
	local head = getPart(ch, "Head") or getPart(ch, "HumanoidRootPart");
	if not rec.bb or not rec.bb.Parent then
		local bb = newUi("BillboardGui");
		bb.Size = UDim2.new(0, 140, 0, 50);
		bb.StudsOffset = Vector3.new(0, 3, 0);
		bb.AlwaysOnTop = true;
		bb.Parent = gui;
		local tx = newUi("TextLabel", bb);
		tx.Size = UDim2.new(1, 0, 1, 0);
		tx.BackgroundTransparency = 1;
		tx.TextColor3 = Color3.fromRGB(255, 255, 255);
		tx.TextStrokeTransparency = 0.5;
		tx.TextStrokeColor3 = Color3.fromRGB(0, 0, 0);
		tx.Font = Enum.Font.GothamBold;
		rec.bb = bb;
		rec.tx = tx;
	end;
	rec.bb.Adornee = head;
	rec.tx.TextSize = math.clamp(tonumber(_G.espTextSize) or 14, 10, 24);
end;
local function ensureESPVisual(rec, p, ch)
	local col = getTeamColorSafe(p);
	local tr = math.clamp(_G.espTransparency or 0.3, 0, 1);
	local modeName = normChoice(_G.espRenderMode, ESP_RENDER_OPTIONS, "Highlight");
	_G.espRenderMode = modeName;
	if modeName == "Highlight" then
		if rec.box and rec.box.Parent then
			rec.box:Destroy();
			rec.box = nil;
		end;
		if not rec.hi or not rec.hi.Parent then
			rec.hi = newUi("Highlight");
			rec.hi.Parent = gui;
		end;
		rec.hi.FillColor = col;
		rec.hi.OutlineColor = col:Lerp(Color3.new(1, 1, 1), 0.25);
		rec.hi.FillTransparency = tr;
		rec.hi.OutlineTransparency = math.clamp(tonumber(_G.espOutlineTransparency) or 0.12, 0, 1);
		rec.hi.DepthMode = _G.espAlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded;
		rec.hi.Adornee = ch;
		return;
	end;
	if rec.hi and rec.hi.Parent then
		rec.hi:Destroy();
		rec.hi = nil;
	end;
	local root = getPart(ch, "HumanoidRootPart") or getPart(ch, "UpperTorso") or getPart(ch, "Torso") or getPart(ch, "Head");
	if not root then
		return;
	end;
	if not rec.box or not rec.box.Parent then
		rec.box = newUi("BoxHandleAdornment");
	end;
	rec.box.Parent = getESPAdornmentParent();
	local cf, size = ch:GetBoundingBox();
	rec.box.Adornee = root;
	rec.box.CFrame = root.CFrame:ToObjectSpace(cf);
	rec.box.Size = size + Vector3.new(0.15, 0.15, 0.15);
	rec.box.Color3 = col;
	rec.box.Transparency = tr;
	rec.box.AlwaysOnTop = _G.espAlwaysOnTop == true;
	rec.box.ZIndex = 4;
end;
local function espAttach(p)
	if not _G.espEnabled then
		return;
	end;
	if p == plr then
		return;
	end;
	local ch = p.Character;
	if not ch then
		return;
	end;
	local hum = getHumanoid(ch);
	if _G.teamCheck and (not isEnemy(p)) then
		return;
	end;
	if _G.aliveCheck and (not hum or hum.Health <= 0) then
		return;
	end;
	if getEspDistance(ch) > math.clamp(tonumber(_G.espMaxDistance) or 2500, 100, 5000) then
		espDetach(p);
		return;
	end;
	local rec = espMap[p];
	if rec and rec.character ~= ch then
		espDetach(p);
		rec = nil;
	end;
	rec = rec or {
		conns = {},
		character = ch
	};
	local rconns = {};
	if rec ~= espMap[p] and hum then
		local hc = hum.HealthChanged:Connect(function()
			updateESPText(p);
			if _G.aliveCheck and hum.Health <= 0 then
				espDetach(p);
			end;
		end);
		table.insert(rconns, hc);
		local teamC = (p:GetPropertyChangedSignal("Team")):Connect(function()
			ensureESPVisual(rec, p, ch);
			updateESPText(p);
		end);
		table.insert(rconns, teamC);
		rec.conns = rconns;
	end;
	rec.character = ch;
	ensureESPVisual(rec, p, ch);
	ensureESPBillboard(rec, ch);
	espMap[p] = rec;
	updateESPText(p);
end;
local function updateESP()
	if not gui then
		return;
	end;
	if not _G.espEnabled then
		for p, _ in pairs(espMap) do
			espDetach(p);
		end;
		espMap = {};
		return;
	end;
	local playerList = Players:GetPlayers();
	local livePlayers = {};
	for _, p in ipairs(playerList) do
		livePlayers[p] = true;
		if p ~= plr then
			if _G.teamCheck and (not isEnemy(p)) then
				espDetach(p);
			else
				espAttach(p);
			end;
		end;
	end;
	for p, _ in pairs(espMap) do
		if not livePlayers[p] then
			espDetach(p);
		end;
	end;
end;
local function refreshESPTransparency()
	local tr = math.clamp(_G.espTransparency or 0.3, 0, 1);
	for _, rec in pairs(espMap) do
		if rec.hi then
			rec.hi.FillTransparency = tr;
			rec.hi.OutlineTransparency = math.clamp(tonumber(_G.espOutlineTransparency) or 0.12, 0, 1);
		end;
		if rec.box then
			rec.box.Transparency = tr;
		end;
	end;
end;
local tabs = {};
local activeTab = nil;
local tabTok = 0;
local function setTab(name)
	local nextTab = tabs[name];
	if not nextTab then
		return;
	end;
	if activeTab == name and nextTab.page.Visible then
		return;
	end;
	local oldName = activeTab;
	local oldTab = oldName and tabs[oldName] or nil;
	activeTab = name;
	tabTok += 1;
	for k, t in pairs(tabs) do
		local sel = k == name;
		local targetText = sel and UI.text or UI.sub;
		local targetBg = sel and UI.tabActive or UI.tab;
		local targetSize = sel and UDim2.new(0, isMobilePlatform() and 112 or 132, 1, 0) or UDim2.new(0, isMobilePlatform() and 102 or 118, 1, 0);
		tw(t.btn, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			TextColor3 = targetText,
			BackgroundColor3 = targetBg,
			Size = targetSize
		});
		local st = t.btn:FindFirstChildOfClass("UIStroke");
		if st then
			st.Color = sel and UI.acc2 or UI.stroke2;
			st.Transparency = sel and 0.05 or 0.55;
		end;
		local glow = findUiTag(t.btn, "Glow");
		if glow then
			tw(glow, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
				BackgroundTransparency = sel and 0 or 1,
				Size = sel and UDim2.new(1, -24, 0, 3) or UDim2.new(0, 0, 0, 3)
			});
		end;
	end;
	if nextTab.scroll then
		nextTab.scroll.CanvasPosition = Vector2.new(0, 0);
	end;
	if oldTab and oldTab.page and oldTab.page ~= nextTab.page then
		local outPage = oldTab.page;
		local outName = oldName;
		local outProps = {
			Position = UDim2.new(0, -18, 0, 10)
		};
		if oldTab.fade then
			outProps.GroupTransparency = 1;
		end;
		tw(outPage, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), outProps);
		task.delay(0.15, function()
			if activeTab ~= outName and outPage and outPage.Parent then
				outPage.Visible = false;
			end;
		end);
	end;
	local p = nextTab.page;
	p.Visible = true;
	p.Position = UDim2.new(0, 28, 0, 10);
	if nextTab.fade then
		p.GroupTransparency = 1;
	end;
	local inProps = {
		Position = UDim2.new(0, 10, 0, 10)
	};
	if nextTab.fade then
		inProps.GroupTransparency = 0;
	end;
	tw(p, TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), inProps);
end;
local function addRowToggle(parent, labelText, var, desc)
	local row = newUi("Frame", parent);
	setUiTag(row, "Row");
	row.BackgroundTransparency = 1;
	row.ZIndex = 8;
	row.Size = UDim2.new(1, -24, 0, desc and (_G.uiCompact and 52 or 60) or (_G.uiCompact and 30 or 34));
	local lbl = newUi("TextLabel", row);
	lbl.Size = UDim2.new(0.58, -8, 0, 20);
	lbl.Position = UDim2.new(0, 0, 0, 0);
	lbl.BackgroundTransparency = 1;
	lbl.Font = Enum.Font.GothamMedium;
	lbl.TextSize = 14;
	lbl.TextXAlignment = Enum.TextXAlignment.Left;
	lbl.Text = labelText;
	lbl.TextColor3 = UI.text;
	if desc then
		local dl = newUi("TextLabel", row);
		dl.BackgroundTransparency = 1;
		dl.Text = desc;
		dl.TextColor3 = UI.sub;
		dl.TextTransparency = 0.2;
		dl.Font = Enum.Font.Gotham;
		dl.TextSize = 12;
		dl.TextXAlignment = Enum.TextXAlignment.Left;
		dl.Position = UDim2.new(0, 0, 0, 22);
		dl.Size = UDim2.new(0.58, -8, 0, 18);
	end;
	local bg = newUi("Frame", row);
	bg.Size = UDim2.new(0, 60, 0, 28);
	bg.Position = UDim2.new(1, -74, 0.5, -14);
	bg.BackgroundColor3 = UI.bar2;
	bg.BorderSizePixel = 0;
	round(bg, UDim.new(1, 0));
	stroke(bg, 1, UI.stroke2, 0.25);
	grad(bg, UI.bar2, UI.bg2, 90);
	local btn = newUi("TextButton", bg);
	btn.Size = UDim2.new(0, 26, 0, 26);
	btn.Position = UDim2.new(0, 1, 0.5, -13);
	btn.BackgroundColor3 = UI.knob;
	btn.Text = "";
	btn.BorderSizePixel = 0;
	btn.AutoButtonColor = false;
	round(btn, UDim.new(1, 0));
	stroke(btn, 1, Color3.fromRGB(205, 208, 220), 0.35);
	if _G[var] then
		btn.Position = UDim2.new(1, -27, 0.5, -13);
		bg.BackgroundColor3 = UI.ok;
		local g = bg:FindFirstChildOfClass("UIGradient");
		if g then
			g.Color = ColorSequence.new(UI.ok, UI.acc2);
		end;
		local st = bg:FindFirstChildOfClass("UIStroke");
		if st then
			st.Color = UI.acc2;
			st.Transparency = 0;
		end;
	end;
	local c = bindClick(btn, function()
		_G[var] = not _G[var];
		if var == "lockToNearest" then
			_G.targetPriorityMode = _G.lockToNearest and "Distance" or "Crosshair";
		end;
		tw(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Position = _G[var] and UDim2.new(1, (-27), 0.5, (-13)) or UDim2.new(0, 1, 0.5, (-13))
		});
		local toBg = _G[var] and UI.ok or UI.bar2;
		tw(bg, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
			BackgroundColor3 = toBg
		});
		local g = bg:FindFirstChildOfClass("UIGradient");
		if g then
			g.Color = _G[var] and ColorSequence.new(UI.ok, UI.acc2) or ColorSequence.new(UI.bar2, UI.bg2);
		end;
		local st = bg:FindFirstChildOfClass("UIStroke");
		if st then
			st.Color = _G[var] and UI.acc2 or UI.stroke2;
			st.Transparency = _G[var] and 0 or 0.25;
		end;
		if var == "espEnabled" or var == "teamCheck" or var == "aliveCheck" or var == "espShowName" or var == "espShowHP" or var == "espShowTeam" or var == "espTeamColor" or var == "espShowDistance" or var == "espAlwaysOnTop" then
			updateESP();
		elseif var == "fovEnabled" then
			if _G.fovEnabled and cam then
				cam.FieldOfView = _G.fovValue;
			end;
		elseif var == "mobileCenterAim" or var == "mobileButtons" or var == "centerDotVisible" or var == "toastCompact" or var == "uiCompact" or var == "uiAnimations" or var == "fovCircleEnabled" then
			if var == "mobileButtons" then
				rebuildMobileHelper();
			end;
			applyCustomUI();
			updateFOVCircle();
		end;
		saveCfg();
	end);
	return row;
end;
local function addRowDropdown(parent, labelText, var, options, desc, onChange)
	if not options or #options == 0 then
		return;
	end;
	local baseHeight = desc and (_G.uiCompact and 54 or 62) or (_G.uiCompact and 38 or 44);
	local optH = _G.uiCompact and 29 or 33;
	local listHeight = (#options) * (optH + 5) + 12;
	local row = newUi("Frame", parent);
	setUiTag(row, "Row");
	row.BackgroundTransparency = 1;
	row.ZIndex = 20;
	row.ClipsDescendants = false;
	row.Size = UDim2.new(1, -20, 0, baseHeight);
	local lbl = newUi("TextLabel", row);
	lbl.Size = UDim2.new(0.5, -8, 0, 20);
	lbl.Position = UDim2.new(0, 0, 0, 2);
	lbl.BackgroundTransparency = 1;
	lbl.Font = Enum.Font.GothamSemibold;
	lbl.TextSize = 14;
	lbl.TextXAlignment = Enum.TextXAlignment.Left;
	lbl.Text = labelText;
	lbl.TextColor3 = UI.text;
	lbl.ZIndex = 21;
	if desc then
		local dl = newUi("TextLabel", row);
		dl.BackgroundTransparency = 1;
		dl.Text = desc;
		dl.TextColor3 = UI.sub;
		dl.TextTransparency = 0.12;
		dl.Font = Enum.Font.Gotham;
		dl.TextSize = 12;
		dl.TextWrapped = true;
		dl.TextXAlignment = Enum.TextXAlignment.Left;
		dl.TextYAlignment = Enum.TextYAlignment.Top;
		dl.Position = UDim2.new(0, 0, 0, 24);
		dl.Size = UDim2.new(0.5, -8, 0, 30);
		dl.ZIndex = 21;
	end;
	local holder = newUi("Frame", row);
	holder.BackgroundTransparency = 1;
	holder.Size = UDim2.new(0.46, 0, 0, baseHeight);
	holder.Position = UDim2.new(0.54, 0, 0, 0);
	holder.ZIndex = 30;
	local btn = newUi("TextButton", holder);
	setUiTag(btn, "DropdownBtn");
	btn.Size = UDim2.new(1, 0, 0, _G.uiCompact and 32 or 36);
	btn.Position = UDim2.new(0, 0, 0, math.floor((baseHeight - (_G.uiCompact and 32 or 36)) * 0.5));
	btn.BackgroundColor3 = UI.bar2;
	btn.BackgroundTransparency = 0.02;
	btn.Text = "";
	btn.AutoButtonColor = false;
	btn.BorderSizePixel = 0;
	btn.ZIndex = 31;
	round(btn, UDim.new(0, 14));
	stroke(btn, 1, UI.stroke2, 0.18);
	noGrad(btn);
	local selGlow = newUi("Frame", btn);
	setUiTag(selGlow, "Accent");
	selGlow.Size = UDim2.new(0, 4, 1, -14);
	selGlow.Position = UDim2.new(0, 8, 0, 7);
	selGlow.BackgroundColor3 = UI.acc2;
	selGlow.BorderSizePixel = 0;
	selGlow.ZIndex = 32;
	round(selGlow, UDim.new(1, 0));
	local txt = newUi("TextLabel", btn);
	txt.BackgroundTransparency = 1;
	txt.Size = UDim2.new(1, -54, 1, 0);
	txt.Position = UDim2.new(0, 20, 0, 0);
	txt.Font = Enum.Font.GothamBold;
	txt.TextSize = 13;
	txt.TextColor3 = UI.text;
	txt.TextXAlignment = Enum.TextXAlignment.Left;
	txt.TextTruncate = Enum.TextTruncate.AtEnd;
	txt.ZIndex = 32;
	local arrow = newUi("TextLabel", btn);
	arrow.BackgroundTransparency = 1;
	arrow.Size = UDim2.new(0, 28, 1, 0);
	arrow.Position = UDim2.new(1, -32, 0, 0);
	arrow.Font = Enum.Font.GothamBlack;
	arrow.TextSize = 14;
	arrow.Text = "v";
	arrow.TextColor3 = UI.acc2;
	arrow.ZIndex = 32;
	local list = newUi("Frame", holder);
	setUiTag(list, "Options");
	list.Visible = false;
	list.ClipsDescendants = true;
	list.Size = UDim2.new(1, 0, 0, 0);
	list.Position = UDim2.new(0, 0, 0, baseHeight + 4);
	list.BackgroundColor3 = UI.bar1;
	list.BackgroundTransparency = 0.02;
	list.BorderSizePixel = 0;
	list.ZIndex = 40;
	round(list, UDim.new(0, 16));
	stroke(list, 1, UI.acc2, 0.18);
	noGrad(list);
	local pad = newUi("UIPadding", list);
	pad.PaddingTop = UDim.new(0, 6);
	pad.PaddingBottom = UDim.new(0, 6);
	pad.PaddingLeft = UDim.new(0, 6);
	pad.PaddingRight = UDim.new(0, 6);
	local lay = newUi("UIListLayout", list);
	lay.FillDirection = Enum.FillDirection.Vertical;
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Center;
	lay.Padding = UDim.new(0, 5);
	lay.SortOrder = Enum.SortOrder.LayoutOrder;
	local function normalize(opt)
		for _, o in ipairs(options) do
			if (tostring(opt)):lower() == (tostring(o)):lower() then
				return o;
			end;
		end;
		return options[1];
	end;
	_G[var] = normalize(_G[var]);
	txt.Text = _G[var];
	local btns = {};
	local function refreshButtons()
		for opt, o in pairs(btns) do
			local sel = normalize(_G[var]) == opt;
			o.BackgroundColor3 = sel and UI.tabActive or UI.bar2;
			o.TextColor3 = sel and UI.text or UI.sub;
			local st = o:FindFirstChildOfClass("UIStroke");
			if st then
				st.Color = sel and UI.acc2 or UI.stroke2;
				st.Transparency = sel and 0.05 or 0.45;
			end;
			local check = findUiTag(o, "Check");
			if check then
				check.TextTransparency = sel and 0 or 1;
			end;
		end;
	end;
	local function setOpt(opt)
		_G[var] = normalize(opt);
		txt.Text = _G[var];
		refreshButtons();
		if onChange then
			onChange(_G[var]);
		end;
		saveCfg();
	end;
	local closeOpenDropdown;
	local function rebuildOptions()
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("TextButton") then
				c:Destroy();
			end;
		end;
		btns = {};
		for i, opt in ipairs(options) do
			local o = newUi("TextButton", list);
			o.LayoutOrder = i;
			o.Size = UDim2.new(1, 0, 0, optH);
			o.BackgroundColor3 = UI.bar2;
			o.BorderSizePixel = 0;
			o.AutoButtonColor = false;
			o.Text = opt;
			o.Font = Enum.Font.GothamSemibold;
			o.TextSize = 13;
			o.TextColor3 = UI.sub;
			o.TextXAlignment = Enum.TextXAlignment.Left;
			o.TextTruncate = Enum.TextTruncate.AtEnd;
			o.ZIndex = 41;
			round(o, UDim.new(0, 12));
			stroke(o, 1, UI.stroke2, 0.45);
			local p = newUi("UIPadding", o);
			p.PaddingLeft = UDim.new(0, 12);
			p.PaddingRight = UDim.new(0, 28);
			local check = newUi("TextLabel", o);
			setUiTag(check, "Check");
			check.BackgroundTransparency = 1;
			check.Size = UDim2.new(0, 20, 1, 0);
			check.Position = UDim2.new(1, -24, 0, 0);
			check.Text = "*";
			check.TextTransparency = 1;
			check.TextColor3 = UI.acc2;
			check.Font = Enum.Font.GothamBlack;
			check.TextSize = 13;
			check.ZIndex = 42;
			btns[opt] = o;
			local e = o.MouseEnter:Connect(function()
				tw(o, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
					BackgroundColor3 = UI.tabActive
				});
			end);
			local l = o.MouseLeave:Connect(function()
				refreshButtons();
			end);
			local c = bindClick(o, function()
				setOpt(opt);
				closeOpenDropdown();
			end);
			table.insert(conns, e);
			table.insert(conns, l);
		end;
		refreshButtons();
	end;
	rebuildOptions();
	function closeOpenDropdown()
		if openDropdown then
			local old = openDropdown;
			if old.list and old.list.Parent then
				tw(old.list, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = UDim2.new(1, 0, 0, 0),
					BackgroundTransparency = 1
				});
				task.delay(0.13, function()
					if old.list and old.list.Parent and ((not openDropdown) or openDropdown.list ~= old.list) then
						old.list.Visible = false;
					end;
				end);
			end;
			if old.row then
				tw(old.row, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {
					Size = UDim2.new(1, -20, 0, old.baseHeight or baseHeight)
				});
			end;
			if old.arrow then
				old.arrow.Text = "v";
			end;
		end;
		openDropdown = nil;
	end;
	local function setDropdownOpen(state)
		if state then
			closeOpenDropdown();
			list.Visible = true;
			list.BackgroundTransparency = 1;
			list.Size = UDim2.new(1, 0, 0, 0);
			tw(row, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, -20, 0, baseHeight + listHeight + 10)
			});
			tw(list, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 0, listHeight),
				BackgroundTransparency = 0.02
			});
			arrow.Text = "^";
			openDropdown = {
				list = list,
				row = row,
				baseHeight = baseHeight,
				arrow = arrow
			};
		else
			closeOpenDropdown();
		end;
	end;
	local b = bindClick(btn, function()
		setDropdownOpen(not list.Visible);
	end);
	local scrollParent = parent and parent.Parent;
	local function pointIn(f, pos)
		if not f or not f.Parent then
			return false;
		end;
		local p = f.AbsolutePosition;
		local sz = f.AbsoluteSize;
		return pos.X >= p.X and pos.X <= p.X + sz.X and pos.Y >= p.Y and pos.Y <= p.Y + sz.Y;
	end;
	local function closeIfTap(input)
		local pos0 = input.Position;
		local can0 = scrollParent and scrollParent:IsA("ScrollingFrame") and scrollParent.CanvasPosition or nil;
		local moved = false;
		local chg;
		local ended;
		chg = UIS.InputChanged:Connect(function(x)
			if x == input or x.UserInputType == input.UserInputType then
				local ok, pos = pcall(function()
					return x.Position;
				end);
				if ok and pos and (pos - pos0).Magnitude > 8 then
					moved = true;
				end;
			end;
		end);
		table.insert(conns, chg);
		ended = UIS.InputEnded:Connect(function(x)
			if x ~= input and x.UserInputType ~= input.UserInputType then
				return;
			end;
			if chg then
				chg:Disconnect();
			end;
			if ended then
				ended:Disconnect();
			end;
			local scrolled = false;
			if can0 and scrollParent and scrollParent.Parent then
				scrolled = (scrollParent.CanvasPosition - can0).Magnitude > 1;
			end;
			if list.Visible and (not moved) and (not scrolled) then
				closeOpenDropdown();
			end;
		end);
		table.insert(conns, ended);
	end;
	local outside = UIS.InputBegan:Connect(function(i, gp)
		if gp or (not list.Visible) then
			return;
		end;
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
			return;
		end;
		local pos = i.Position;
		if pointIn(list, pos) or pointIn(btn, pos) then
			return;
		end;
		if scrollParent and scrollParent:IsA("ScrollingFrame") and pointIn(scrollParent, pos) then
			closeIfTap(i);
			return;
		end;
		closeOpenDropdown();
	end);
	table.insert(conns, outside);
	return row;
end;
local function addRowToggleSlider(parent, labelText, varToggle, valueVar, min, max, decimals, desc)
	local row = addRowToggle(parent, labelText, varToggle, desc);
	local track = newUi("Frame", row);
	track.BackgroundColor3 = UI.bar2;
	track.BorderSizePixel = 0;
	track.Size = UDim2.new(0.24, 0, 0, 8);
	track.Position = UDim2.new(0.64, 0, 0.5, -4);
	round(track, UDim.new(0, 4));
	stroke(track, 1, UI.stroke2, 0.3);
	local fill = newUi("Frame", track);
	fill.BackgroundColor3 = UI.acc2;
	fill.BorderSizePixel = 0;
	fill.Size = UDim2.new(0, 0, 1, 0);
	round(fill, UDim.new(0, 4));
	local knob = newUi("Frame", track);
	knob.Size = UDim2.new(0, 14, 0, 14);
	knob.Position = UDim2.new(0, -7, 0.5, -7);
	knob.BackgroundColor3 = UI.knob;
	knob.BorderSizePixel = 0;
	round(knob, UDim.new(1, 0));
	stroke(knob, 1, UI.stroke2, 0.15);
	local valLbl = newUi("TextLabel", row);
	valLbl.BackgroundTransparency = 1;
	valLbl.Font = Enum.Font.Gotham;
	valLbl.TextSize = 13;
	valLbl.TextColor3 = UI.text;
	valLbl.Size = UDim2.new(0, 64, 0, 20);
	valLbl.Position = UDim2.new(0.55, 0, 0.5, -10);
	local function fmt(n)
		local m = decimals or 0;
		if m <= 0 then
			return tostring(math.floor(n + 0.5));
		end;
		local p = 10 ^ m;
		return tostring(math.floor((n * p + 0.5)) / p);
	end;
	local function setVal(n, fromDrag)
		n = math.clamp(n, min, max);
		_G[valueVar] = n;
		valLbl.Text = fmt(n);
		local alpha = (n - min) / (max - min);
		fill.Size = UDim2.new(alpha, 0, 1, 0);
		knob.Position = UDim2.new(alpha, -7, 0.5, -7);
		if valueVar == "fovValue" and _G.fovEnabled and cam then
			cam.FieldOfView = n;
		end;
		saveCfg();
		if not fromDrag then
			tw(knob, TweenInfo.new(0.08), {
				BackgroundColor3 = UI.knob
			});
		end;
	end;
	setVal(_G[valueVar] or min);
	local draggingS = false;
	local function posToVal(x)
		local ax = math.clamp(x - track.AbsolutePosition.X, 0, track.AbsoluteSize.X);
		local a = ax / track.AbsoluteSize.X;
		return min + a * (max - min);
	end;
	local tb = track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			draggingS = true;
			setVal(posToVal(i.Position.X), true);
			tw(knob, TweenInfo.new(0.06), {
				BackgroundColor3 = UI.acc2
			});
		end;
	end);
	local te = track.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			if draggingS then
				setVal(posToVal(i.Position.X), false);
			end;
			draggingS = false;
			tw(knob, TweenInfo.new(0.1), {
				BackgroundColor3 = UI.knob
			});
		end;
	end);
	local tc = UIS.InputChanged:Connect(function(i)
		if draggingS and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			setVal(posToVal(i.Position.X), true);
		end;
	end);
	table.insert(conns, tb);
	table.insert(conns, te);
	table.insert(conns, tc);
	return row;
end;
local function addRowSlider(parent, labelText, valueVar, min, max, decimals, desc, onChange)
	local deferApply = valueVar == "uiScale";
	local row = newUi("Frame", parent);
	setUiTag(row, "Row");
	row.BackgroundTransparency = 1;
	row.ZIndex = 8;
	row.Size = UDim2.new(1, -24, 0, desc and (_G.uiCompact and 52 or 60) or (_G.uiCompact and 30 or 34));
	local lbl = newUi("TextLabel", row);
	lbl.Size = UDim2.new(0.58, -8, 0, 20);
	lbl.Position = UDim2.new(0, 0, 0, 0);
	lbl.BackgroundTransparency = 1;
	lbl.Font = Enum.Font.GothamMedium;
	lbl.TextSize = 14;
	lbl.TextXAlignment = Enum.TextXAlignment.Left;
	lbl.Text = labelText;
	lbl.TextColor3 = UI.text;
	if desc then
		local dl = newUi("TextLabel", row);
		dl.BackgroundTransparency = 1;
		dl.Text = desc;
		dl.TextColor3 = UI.sub;
		dl.TextTransparency = 0.2;
		dl.Font = Enum.Font.Gotham;
		dl.TextSize = 12;
		dl.TextXAlignment = Enum.TextXAlignment.Left;
		dl.Position = UDim2.new(0, 0, 0, 22);
		dl.Size = UDim2.new(0.58, -8, 0, 18);
	end;
	local track = newUi("Frame", row);
	track.BackgroundColor3 = UI.bar2;
	track.BorderSizePixel = 0;
	track.Size = UDim2.new(0.32, 0, 0, 8);
	track.Position = UDim2.new(0.62, 0, 0.5, -4);
	round(track, UDim.new(0, 4));
	stroke(track, 1, UI.stroke2, 0.3);
	local fill = newUi("Frame", track);
	fill.BackgroundColor3 = UI.acc2;
	fill.BorderSizePixel = 0;
	fill.Size = UDim2.new(0, 0, 1, 0);
	round(fill, UDim.new(0, 4));
	local knob = newUi("Frame", track);
	knob.Size = UDim2.new(0, 14, 0, 14);
	knob.Position = UDim2.new(0, -7, 0.5, -7);
	knob.BackgroundColor3 = UI.knob;
	knob.BorderSizePixel = 0;
	round(knob, UDim.new(1, 0));
	stroke(knob, 1, UI.stroke2, 0.15);
	local valLbl = newUi("TextLabel", row);
	valLbl.BackgroundTransparency = 1;
	valLbl.Font = Enum.Font.Gotham;
	valLbl.TextSize = 13;
	valLbl.TextColor3 = UI.text;
	valLbl.Size = UDim2.new(0, 64, 0, 20);
	valLbl.Position = UDim2.new(0.53, 0, 0.5, -10);
	local function fmt(n)
		local m = decimals or 0;
		if m <= 0 then
			return tostring(math.floor(n + 0.5));
		end;
		local p = 10 ^ m;
		return tostring(math.floor((n * p + 0.5)) / p);
	end;
	local function setVal(n, fromDrag)
		n = math.clamp(n, min, max);
		_G[valueVar] = n;
		valLbl.Text = fmt(n);
		local alpha = (n - min) / (max - min);
		fill.Size = UDim2.new(alpha, 0, 1, 0);
		knob.Position = UDim2.new(alpha, -7, 0.5, -7);
		if onChange and ((not fromDrag) or (not deferApply)) then
			onChange(n);
		end;
		if not fromDrag then
			saveCfg();
			tw(knob, TweenInfo.new(0.08), {
				BackgroundColor3 = UI.knob
			});
		end;
	end;
	setVal(_G[valueVar] or min);
	local draggingS = false;
	local function posToVal(x)
		local ax = math.clamp(x - track.AbsolutePosition.X, 0, track.AbsoluteSize.X);
		local a = ax / track.AbsoluteSize.X;
		return min + a * (max - min);
	end;
	local tb = track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			draggingS = true;
			setVal(posToVal(i.Position.X), true);
			tw(knob, TweenInfo.new(0.06), {
				BackgroundColor3 = UI.acc2
			});
		end;
	end);
	local te = track.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			if draggingS then
				setVal(posToVal(i.Position.X), false);
			end;
			draggingS = false;
			tw(knob, TweenInfo.new(0.1), {
				BackgroundColor3 = UI.knob
			});
		end;
	end);
	local tc = UIS.InputChanged:Connect(function(i)
		if draggingS and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			setVal(posToVal(i.Position.X), true);
		end;
	end);
	table.insert(conns, tb);
	table.insert(conns, te);
	table.insert(conns, tc);
	return row;
end;
local function makeTabBar(parent)
	local bar = newUi("ScrollingFrame");
	setUiTag(bar, "Tabs");
	bar.Parent = parent;
	bar.Size = UDim2.new(1, -32, 0, 40);
	bar.Position = UDim2.new(0, 16, 0, 58);
	bar.BackgroundTransparency = 1;
	bar.BorderSizePixel = 0;
	bar.ScrollBarThickness = 0;
	bar.ScrollingDirection = Enum.ScrollingDirection.X;
	bar.AutomaticCanvasSize = Enum.AutomaticSize.X;
	bar.CanvasSize = UDim2.new(0, 0, 0, 0);
	local list = newUi("UIListLayout", bar);
	list.FillDirection = Enum.FillDirection.Horizontal;
	list.Padding = UDim.new(0, 8);
	list.SortOrder = Enum.SortOrder.LayoutOrder;
	list.VerticalAlignment = Enum.VerticalAlignment.Center;
	local function makeBtn(txt, order)
		local b = newUi("TextButton");
		setUiTag(b, "Tab_" .. txt);
		b.Parent = bar;
		b.LayoutOrder = order or 1;
		b.AutoButtonColor = false;
		b.BackgroundTransparency = 0;
		b.BackgroundColor3 = UI.tab;
		b.Size = UDim2.new(0, isMobilePlatform() and 102 or 118, 1, 0);
		b.Font = Enum.Font.GothamBlack;
		b.TextSize = 12;
		b.Text = string.upper(txt);
		b.TextColor3 = UI.sub;
		b.ClipsDescendants = true;
		b.ZIndex = 8;
		round(b, UDim.new(0, 16));
		stroke(b, 1, UI.stroke2, 0.55);
		noGrad(b);
		local glow = newUi("Frame", b);
		setUiTag(glow, "Glow");
		glow.AnchorPoint = Vector2.new(0.5, 1);
		glow.Position = UDim2.new(0.5, 0, 1, -5);
		glow.Size = UDim2.new(0, 0, 0, 3);
		glow.BackgroundColor3 = UI.acc2;
		glow.BackgroundTransparency = 1;
		glow.BorderSizePixel = 0;
		glow.ZIndex = 9;
		round(glow, UDim.new(1, 0));
		grad(glow, UI.acc, UI.acc2, 0);
		local e = b.MouseEnter:Connect(function()
			if activeTab ~= txt then
				tw(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
					BackgroundColor3 = UI.tabActive,
					TextColor3 = UI.sub
				});
			end;
		end);
		local l = b.MouseLeave:Connect(function()
			if activeTab ~= txt then
				tw(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
					BackgroundColor3 = UI.tab,
					TextColor3 = UI.dim
				});
			end;
		end);
		table.insert(conns, e);
		table.insert(conns, l);
		return b;
	end;
	local content = newUi("ScrollingFrame", parent);
	setUiTag(content, "Content");
	content.Size = UDim2.new(1, -32, 1, -132);
	content.Position = UDim2.new(0, 16, 0, 106);
	content.BackgroundColor3 = UI.bg2;
	content.BackgroundTransparency = _G.uiContentAlpha;
	content.BorderSizePixel = 0;
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y;
	content.CanvasSize = UDim2.new(0, 0, 0, 0);
	content.ScrollBarThickness = 4;
	content.ScrollBarImageTransparency = 0.25;
	content.ScrollBarImageColor3 = UI.acc2;
	content.ClipsDescendants = true;
	content.ZIndex = 6;
	uiRefs.content = content;
	round(content, UDim.new(0, 20));
	stroke(content, 1, UI.stroke2, 0.18);
	noGrad(content);
	local function makePage()
		local p, isCg = fadeFrame();
		p.BackgroundTransparency = 1;
		p.ZIndex = 8;
		p.Size = UDim2.new(1, -24, 0, 0);
		p.Position = UDim2.new(0, 28, 0, 10);
		p.AutomaticSize = Enum.AutomaticSize.Y;
		p.Visible = false;
		if isCg then
			p.GroupTransparency = 1;
		end;
		p.Parent = content;
		local lay = newUi("UIListLayout", p);
		lay.Padding = UDim.new(0, 9);
		lay.FillDirection = Enum.FillDirection.Vertical;
		lay.SortOrder = Enum.SortOrder.LayoutOrder;
		return p, isCg;
	end;
	local btnAim = makeBtn("aim", 1);
	local btnTarget = makeBtn("target", 2);
	local btnESP = makeBtn("esp", 3);
	local btnStatus = makeBtn("status", 4);
	local btnSettings = makeBtn("settings", 5);
	local btnCustom = makeBtn("customize", 6);
	local pgAim, fadeAim = makePage();
	local pgTarget, fadeTarget = makePage();
	local pgESP, fadeESP = makePage();
	local pgStatus, fadeStatus = makePage();
	local pgSettings, fadeSettings = makePage();
	local pgCustom, fadeCustom = makePage();
	tabs = {
		aim = {
			btn = btnAim,
			page = pgAim,
			fade = fadeAim,
			scroll = content
		},
		target = {
			btn = btnTarget,
			page = pgTarget,
			fade = fadeTarget,
			scroll = content
		},
		esp = {
			btn = btnESP,
			page = pgESP,
			fade = fadeESP,
			scroll = content
		},
		status = {
			btn = btnStatus,
			page = pgStatus,
			fade = fadeStatus,
			scroll = content
		},
		settings = {
			btn = btnSettings,
			page = pgSettings,
			fade = fadeSettings,
			scroll = content
		},
		customize = {
			btn = btnCustom,
			page = pgCustom,
			fade = fadeCustom,
			scroll = content
		}
	};
	for name, t in pairs(tabs) do
		local c = bindClick(t.btn, function()
			setTab(name);
		end);
	end;
	setTab("aim");
	return tabs;
end;
local function normalizeTopPos()
	local p = _G.topTogglePos;
	if type(p) ~= "table" then
		p = {};
	end;
	local xs = tonumber(p.XScale) or 0.5;
	local xo = tonumber(p.XOffset) or -76;
	local ys = tonumber(p.YScale) or 0;
	local yo = tonumber(p.YOffset) or 8;
	_G.topTogglePos = {
		XScale = xs,
		XOffset = xo,
		YScale = ys,
		YOffset = yo
	};
	return _G.topTogglePos;
end;
local function topToggleUDim(hidden)
	local p = normalizeTopPos();
	if hidden then
		return UDim2.new(p.XScale, p.XOffset, -0.2, 0);
	end;
	return UDim2.new(p.XScale, p.XOffset, p.YScale, p.YOffset);
end;
local function rememberTopToggle(pos)
	_G.topTogglePos = {
		XScale = pos.X.Scale,
		XOffset = pos.X.Offset,
		YScale = pos.Y.Scale,
		YOffset = pos.Y.Offset
	};
end;
local function defaultMobileHelperUDim(size)
	local vp = getViewport();
	local w = size and size.X or 196;
	local h = size and size.Y or 150;
	return UDim2.new(0, math.max(8, vp.X - w - 18), 0, math.max(8, vp.Y - h - 96));
end;
local function mobileHelperUDim(size)
	return unpackUDim2(_G.mobileHelperPos, defaultMobileHelperUDim(size));
end;
local function rememberMobileHelperPos(pos)
	_G.mobileHelperPos = packUDim2(pos);
end;
local function showTopBtn(state)
	if not topBtn or not topToggleHolder then
		return;
	end;
	topToggleHolder.Visible = state;
	if state then
		tw(topToggleHolder, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Position = topToggleUDim(false)
		});
	else
		tw(topToggleHolder, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Position = topToggleUDim(true)
		});
	end;
end;
local function openUI()
	if not frm or (not frm.Parent) then
		return;
	end;
	uiMin = false;
	applyCustomUI();
	tw(frm, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = _G.uiWindowAlpha
	});
	showTopBtn(false);
end;
local function closeUI()
	if not frm or (not frm.Parent) then
		return;
	end;
	uiMin = true;
	applyCustomUI();
	tw(frm, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, -0.65, 0),
		BackgroundTransparency = math.clamp((_G.uiWindowAlpha or 0.08) + 0.08, 0, 0.6)
	});
	showTopBtn(true);
end;
local function makeKeyChip(parent, keyName, onRemove)
	local chip = newUi("Frame", parent);
	chip.BackgroundColor3 = UI.bar2;
	chip.Size = UDim2.new(0, 120, 0, 24);
	chip.BorderSizePixel = 0;
	round(chip, UDim.new(0.2, 0));
	stroke(chip, 1, UI.stroke2, 0.25);
	local tl = newUi("TextLabel", chip);
	tl.BackgroundTransparency = 1;
	tl.Size = UDim2.new(1, -30, 1, 0);
	tl.Position = UDim2.new(0, 8, 0, 0);
	tl.Font = Enum.Font.Gotham;
	tl.TextSize = 13;
	tl.TextColor3 = UI.text;
	tl.TextXAlignment = Enum.TextXAlignment.Left;
	tl.TextTruncate = Enum.TextTruncate.AtEnd;
	tl.Text = keyName;
	task.defer(function()
		local w = math.clamp(tl.TextBounds.X + 36, 96, 200);
		chip.Size = UDim2.new(0, w, 0, 24);
	end);
	local rm = newUi("TextButton", chip);
	rm.Size = UDim2.new(0, 24, 0, 24);
	rm.Position = UDim2.new(1, -24, 0, 0);
	rm.BackgroundColor3 = UI.danger;
	rm.Text = "x";
	rm.TextColor3 = Color3.new(1, 1, 1);
	rm.Font = Enum.Font.GothamSemibold;
	rm.TextSize = 12;
	rm.AutoButtonColor = false;
	round(rm, UDim.new(0.2, 0));
	stroke(rm, 1, UI.stroke2, 0.1);
	local c = bindClick(rm, function()
		if onRemove then
			onRemove(keyName, chip);
		end;
	end);
	return chip;
end;
local function createUI()
	cleanup();
	gui = newUi("ScreenGui", uiRoot);
	setUiTag(gui, "VyperiaBot");
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
	gui.ResetOnSpawn = false;
	gui.IgnoreGuiInset = true;
	gui.DisplayOrder = 999999;
	toastHolder = newUi("Frame", gui);
	setUiTag(toastHolder, "ToastHolder");
	toastHolder.AnchorPoint = Vector2.new(1, 0);
	toastHolder.Position = UDim2.new(1, -18, 0, 18);
	toastHolder.Size = UDim2.new(0, isMobilePlatform() and 300 or 340, 0, 330);
	toastHolder.BackgroundTransparency = 1;
	toastHolder.ZIndex = 100;
	uiRefs.toastHolder = toastHolder;
	local tLayout = newUi("UIListLayout", toastHolder);
	tLayout.Padding = UDim.new(0, 8);
	tLayout.SortOrder = Enum.SortOrder.LayoutOrder;
	tLayout.VerticalAlignment = Enum.VerticalAlignment.Top;
	applyToastPos();
	local fovCircle = newUi("Frame", gui);
	setUiTag(fovCircle, "FOVCircle");
	fovCircle.AnchorPoint = Vector2.new(0.5, 0.5);
	fovCircle.BackgroundTransparency = 1;
	fovCircle.BorderSizePixel = 0;
	fovCircle.Visible = false;
	fovCircle.ZIndex = 2;
	round(fovCircle, UDim.new(1, 0));
	stroke(fovCircle, _G.fovCircleThickness or 2, UI.acc2, _G.fovCircleAlpha or 0.25);
	uiRefs.fovCircle = fovCircle;
	local fovLoop = RunService.RenderStepped:Connect(function()
		updateFOVCircle();
	end);
	table.insert(conns, fovLoop);
	local espPulse = 0;
	local espLoop = RunService.Heartbeat:Connect(function(dt)
		if not _G.espEnabled then
			return;
		end;
		espPulse += dt or 0.016;
		if espPulse < 0.25 then
			return;
		end;
		espPulse = 0;
		if _G.espRenderMode == "BoxHandleAdornment" or _G.espShowDistance or ((_G.espMaxDistance or 2500) < 5000) then
			updateESP();
		end;
	end);
	table.insert(conns, espLoop);
	topToggleHolder = newUi("Frame", gui);
	setUiTag(topToggleHolder, "TopToggleHolder");
	topToggleHolder.Size = UDim2.new(0, 152, 0, 30);
	topToggleHolder.Position = topToggleUDim(true);
	topToggleHolder.BackgroundTransparency = 1;
	topToggleHolder.Visible = false;
	topToggleHolder.ZIndex = 20;
	topToggleHolder.Active = true;
	topBtn = newUi("TextButton", topToggleHolder);
	setUiTag(topBtn, "TopToggle");
	topBtn.Size = UDim2.new(1, 0, 1, 0);
	topBtn.Position = UDim2.new(0, 0, 0, 0);
	topBtn.BackgroundColor3 = UI.bar1;
	topBtn.BackgroundTransparency = 0.2;
	topBtn.TextColor3 = UI.text;
	topBtn.Text = "OPEN AIMBOT";
	topBtn.Font = Enum.Font.GothamBlack;
	topBtn.TextSize = 14;
	topBtn.AutoButtonColor = false;
	topBtn.ZIndex = 20;
	uiRefs.topToggle = topBtn;
	round(topBtn, UDim.new(0.3, 0));
	stroke(topBtn, 1, UI.stroke2, 0.25);
	local fw, fh = frameSizeForViewport();
	local frame = newUi("Frame", gui);
	setUiTag(frame, "Root");
	frame.AnchorPoint = Vector2.new(0.5, 0.5);
	frame.Size = UDim2.new(0, fw, 0, fh);
	frame.Position = UDim2.new(0.5, 0, -0.5, 0);
	frame.BackgroundColor3 = UI.panel;
	frame.BackgroundTransparency = _G.uiWindowAlpha;
	frame.BorderSizePixel = 0;
	frame.ClipsDescendants = true;
	frame.Active = true;
	frame.ZIndex = 5;
	frm = frame;
	round(frame, UDim.new(0, _G.uiRounded or 24));
	local rootScale = newUi("UIScale", frame);
	rootScale.Scale = math.clamp(tonumber(_G.uiScale) or 1, 0.75, 1.25);
	uiRefs.rootScale = rootScale;
	shadow(frame);
	stroke(frame, 1, UI.stroke, 0.16);
	noGrad(frame);
	local bar = newUi("Frame", frame);
	setUiTag(bar, "Bar");
	bar.Size = UDim2.new(1, 0, 0, 48);
	bar.Position = UDim2.new(0, 0, 0, 0);
	bar.BackgroundColor3 = UI.bar1;
	bar.BorderSizePixel = 0;
	bar.ZIndex = 6;
	round(bar, UDim.new(0, 24));
	stroke(bar, 1, UI.stroke2, 0.18);
	noGrad(bar);
	local title = newUi("TextLabel", bar);
	setUiTag(title, "Title");
	title.Size = UDim2.new(1, -110, 1, 0);
	title.Position = UDim2.new(0, 16, 0, 0);
	title.Text = "VYPERIA-AIMBOT";
	title.TextColor3 = UI.text;
	title.BackgroundTransparency = 1;
	title.Font = Enum.Font.GothamBlack;
	title.TextSize = 15;
	title.TextXAlignment = Enum.TextXAlignment.Left;
	title.ZIndex = 7;
	local btnX = newUi("TextButton", bar);
	setUiTag(btnX, "Close");
	btnX.Size = UDim2.new(0, 18, 0, 18);
	btnX.Position = UDim2.new(1, -24, 0.5, -9);
	btnX.Text = "";
	btnX.BackgroundColor3 = UI.danger;
	btnX.BorderSizePixel = 0;
	btnX.AutoButtonColor = false;
	btnX.ZIndex = 7;
	local btnMin = newUi("TextButton", bar);
	setUiTag(btnMin, "Min");
	btnMin.Size = UDim2.new(0, 18, 0, 18);
	btnMin.Position = UDim2.new(1, -48, 0.5, -9);
	btnMin.Text = "";
	btnMin.BackgroundColor3 = UI.warn;
	btnMin.BorderSizePixel = 0;
	btnMin.AutoButtonColor = false;
	btnMin.ZIndex = 7;
	round(btnX, UDim.new(1, 0));
	round(btnMin, UDim.new(1, 0));
	styleWin(frame, bar, title, btnX, btnMin);
	local tabObjs = makeTabBar(frame);
	local pgAim = tabObjs.aim.page;
	local pgTarget = tabObjs.target.page;
	local pgESP = tabObjs.esp.page;
	local pgStatus = tabObjs.status.page;
	local pgSettings = tabObjs.settings.page;
	local pgCustom = tabObjs.customize.page;
	addRowToggle(pgAim, "Aimbot", "isEnabled");
	addRowToggle(pgAim, "Aim Lock", "aimLock", "tap lock key to toggle, off = hold key");
	addRowDropdown(pgAim, "aim target", "aimTargetMode", AIM_TARGET_OPTIONS, "Body part used for camera locking", function(v)
		if normalizeAimMode(v) == "Random" then
			bumpRandomAim();
		end;
	end);
	if not isMobilePlatform() then
		addRowDropdown(pgAim, "target point", "targetPointMode", TARGET_POINT_OPTIONS, "PC only: use cursor or screen center", function()
			_G.targetPointMode = normChoice(_G.targetPointMode, TARGET_POINT_OPTIONS, "Cursor");
			updateFOVCircle();
		end);
	end;
	addRowToggle(pgAim, "lock to nearest", "lockToNearest");
	addRowToggle(pgAim, "show FOV circle", "fovCircleEnabled", "draws the current target radius");
	addRowSlider(pgAim, "FOV radius", "aimRadius", 10, 400, 0, "targeting circle radius (px)", function()
		updateFOVCircle();
	end);
	addRowSlider(pgAim, "FOV circle transparency", "fovCircleAlpha", 0, 1, 2, "0 = visible, 1 = hidden", function()
		updateFOVCircle();
	end);
	addRowSlider(pgAim, "FOV circle thickness", "fovCircleThickness", 1, 8, 0, "outline thickness", function()
		updateFOVCircle();
	end);
	addRowToggle(pgAim, "wall check", "wallCheck");
	addRowToggleSlider(pgAim, "tween aim", "aimTween", "aimSmooth", 0.05, 0.2, 2, "smoothly rotate camera to target");
	addRowToggleSlider(pgAim, "aim prediction", "aimPredict", "aimLead", 0.01, 1, 2, "adaptive prediction, dampens close targets");
	addRowToggleSlider(pgAim, "lock fov", "fovEnabled", "fovValue", 1, 120, 0, "changes camera FOV");
	addRowToggle(pgTarget, "team check", "teamCheck");
	addRowToggle(pgTarget, "alive check", "aliveCheck");
	addRowToggle(pgESP, "enable esp", "espEnabled");
	addRowToggle(pgESP, "team color", "espTeamColor");
	addRowToggle(pgESP, "show name", "espShowName");
	addRowToggle(pgESP, "show health", "espShowHP");
	addRowToggle(pgESP, "show team", "espShowTeam");
	addRowSlider(pgESP, "esp transparency", "espTransparency", 0, 1, 2, "highlight fill transparency", function()
		refreshESPTransparency();
	end);
	local function addSection(parent, text)
		local row = newUi("Frame", parent);
		row.BackgroundTransparency = 1;
		row.Size = UDim2.new(1, -20, 0, 30);
		local line = newUi("Frame", row);
		line.BackgroundColor3 = UI.acc2;
		line.BackgroundTransparency = 0.1;
		line.BorderSizePixel = 0;
		line.Size = UDim2.new(0, 4, 0, 20);
		line.Position = UDim2.new(0, 0, 0.5, -10);
		round(line, UDim.new(1, 0));
		local lbl = newUi("TextLabel", row);
		lbl.BackgroundTransparency = 1;
		lbl.Text = string.upper(text);
		lbl.TextColor3 = UI.acc2;
		lbl.Font = Enum.Font.GothamBlack;
		lbl.TextSize = 12;
		lbl.TextXAlignment = Enum.TextXAlignment.Left;
		lbl.Position = UDim2.new(0, 14, 0, 0);
		lbl.Size = UDim2.new(1, -14, 1, 0);
		return row;
	end;
	addSection(pgTarget, "selection");
	addRowDropdown(pgTarget, "target priority", "targetPriorityMode", TARGET_PRIORITY_OPTIONS, "choose how targets are sorted", function(v)
		_G.targetPriorityMode = normChoice(v, TARGET_PRIORITY_OPTIONS, "Crosshair");
		_G.lockToNearest = _G.targetPriorityMode == "Distance";
		saveCfg();
	end);
	addRowToggle(pgTarget, "sticky target", "stickyTarget", "keep the current target while it stays valid");
	addRowSlider(pgTarget, "max target distance", "targetMaxDistance", 100, 5000, 0, "ignore targets farther than this");
	addSection(pgESP, "render");
	addRowDropdown(pgESP, "esp mode", "espRenderMode", ESP_RENDER_OPTIONS, "swap between highlight and boxhandleadornment", function(v)
		_G.espRenderMode = normChoice(v, ESP_RENDER_OPTIONS, "Highlight");
		updateESP();
	end);
	addRowToggle(pgESP, "always on top", "espAlwaysOnTop", "draw esp over walls when possible");
	addRowToggle(pgESP, "show distance", "espShowDistance");
	addRowSlider(pgESP, "text size", "espTextSize", 10, 24, 0, "billboard text size", function()
		updateESP();
	end);
	addRowSlider(pgESP, "max esp distance", "espMaxDistance", 100, 5000, 0, "hide esp beyond this distance", function()
		updateESP();
	end);
	addRowSlider(pgESP, "outline transparency", "espOutlineTransparency", 0, 1, 2, "highlight outline alpha", function()
		refreshESPTransparency();
		updateESP();
	end);
	addSection(pgCustom, "window");
	addRowSlider(pgCustom, "ui scale", "uiScale", 0.75, 1.25, 2, "scales the whole window", function()
		applyCustomUI();
	end);
	addRowSlider(pgCustom, "window transparency", "uiWindowAlpha", 0, 0.45, 2, "root panel transparency", function()
		applyCustomUI();
	end);
	addRowSlider(pgCustom, "content transparency", "uiContentAlpha", 0, 0.55, 2, "inside panel transparency", function()
		applyCustomUI();
	end);
	addRowSlider(pgCustom, "corner roundness", "uiRounded", 10, 34, 0, "applies fully on reload", function()
		applyCustomUI();
	end);
	addRowToggle(pgCustom, "compact rows", "uiCompact", "smaller rows on next UI rebuild");
	addSection(pgCustom, "theme");
	addRowDropdown(pgCustom, "accent theme", "uiTheme", THEME_OPTIONS, "changes accent colors", function(v)
		applyTheme(v);
		applyCustomUI();
	end);
	addRowToggle(pgCustom, "animated ui", "uiAnimations", "disable if you want instant UI changes");
	addRowSlider(pgCustom, "animation speed", "uiAnimSpeed", 0.35, 2.5, 2, "higher = faster tweens", function()
		applyCustomUI();
	end);
	addSection(pgCustom, "notifications");
	addRowDropdown(pgCustom, "toast position", "toastPosition", TOAST_POS_OPTIONS, "where notifications appear", function()
		applyCustomUI();
	end);
	addRowSlider(pgCustom, "toast duration", "toastDuration", 1, 8, 1, "how long notifications stay", function()
		applyCustomUI();
	end);
	addRowSlider(pgCustom, "toast max stack", "toastMax", 1, 8, 0, "maximum visible notifications", function()
		applyCustomUI();
	end);
	addRowToggle(pgCustom, "compact toasts", "toastCompact", "shorter notification cards");
	if isMobilePlatform() then
	addSection(pgCustom, "mobile / center point");
	addRowToggle(pgCustom, "center dot", "centerDotVisible", "show the mobile center lock point");
	addRowSlider(pgCustom, "center dot size", "centerDotSize", 4, 40, 0, "center lock marker size", function()
		applyCustomUI();
	end);
	addRowSlider(pgCustom, "center dot transparency", "centerDotAlpha", 0, 1, 2, "0 = visible, 1 = hidden", function()
		applyCustomUI();
	end);
	addRowSlider(pgCustom, "mobile button scale", "mobileButtonScale", 0.7, 1.45, 2, "floating button size", function()
		applyCustomUI();
	end);
	addRowSlider(pgCustom, "mobile button transparency", "mobileButtonAlpha", 0, 0.75, 2, "floating button transparency", function()
		applyCustomUI();
	end);
	end;
	local function addRow(parent, labelText, valueText, copyFn)
		local row = newUi("Frame", parent);
		row.BackgroundTransparency = 1;
		row.Size = UDim2.new(1, -20, 0, 26);
		local lbl = newUi("TextLabel", row);
		lbl.BackgroundTransparency = 1;
		lbl.Text = labelText;
		lbl.TextColor3 = UI.text;
		lbl.Font = Enum.Font.GothamMedium;
		lbl.TextSize = 14;
		lbl.TextXAlignment = Enum.TextXAlignment.Left;
		lbl.Position = UDim2.new(0, 0, 0, 0);
		lbl.Size = UDim2.new(0, 220, 1, 0);
		local reserve = copyFn and 70 or 0;
		local val = newUi("TextLabel", row);
		val.BackgroundTransparency = 1;
		val.Text = valueText or "";
		val.TextColor3 = UI.text;
		val.Font = Enum.Font.Gotham;
		val.TextSize = 14;
		val.TextXAlignment = Enum.TextXAlignment.Left;
		val.Position = UDim2.new(0, 230, 0, 0);
		val.Size = UDim2.new(1, -(240 + reserve), 1, 0);
		if copyFn then
			local b = newUi("TextButton", row);
			b.Text = "copy";
			b.Font = Enum.Font.GothamSemibold;
			b.TextSize = 12;
			b.TextColor3 = UI.text;
			b.AutoButtonColor = false;
			b.BackgroundColor3 = UI.bar2;
			b.Size = UDim2.new(0, 60, 0, 22);
			b.AnchorPoint = Vector2.new(1, 0.5);
			b.Position = UDim2.new(1, -4, 0.5, 0);
			stroke(b, 1, UI.stroke2, 0.25);
			round(b, UDim.new(0.2, 0));
			local c = bindClick(b, function()
				local v = tostring(copyFn());
				if setclipboard then
					setclipboard(v);
				end;
				toast("copied");
			end);
		end;
		return val;
	end;
	local vPlayers = addRow(pgStatus, "players", "");
	local vTime = addRow(pgStatus, "time playing", "");
	local vNow = addRow(pgStatus, "current time", "");
	local vGame = addRow(pgStatus, "game name", game.Name or "unknown");
	local vPlace = addRow(pgStatus, "place id", tostring(game.PlaceId), function()
		return game.PlaceId;
	end);
	local vGameId = addRow(pgStatus, "game id", tostring(game.GameId), function()
		return game.GameId;
	end);
	local vJobId = addRow(pgStatus, "job id", tostring(game.JobId), function()
		return game.JobId;
	end);
	local vDevice = addRow(pgStatus, "device", UIS:GetPlatform() and (UIS:GetPlatform()).Name or "unknown");
	local vLocale = addRow(pgStatus, "locale", (LS.RobloxLocaleId or "unknown") .. " / " .. (LS.SystemLocaleId or "unknown"));
	local vExec = addRow(pgStatus, "executor", identifyexecutor and identifyexecutor() or identifyexec and identifyexec() or "Unknown");
	local vAimState = addRow(pgStatus, "aimbot state", "");
	local vLockState = addRow(pgStatus, "lock state", "");
	local vTargetMode = addRow(pgStatus, "target mode", "");
	local vTargetNow = addRow(pgStatus, "current target", "");
	local vEspState = addRow(pgStatus, "esp state", "");
	local vThemeState = addRow(pgStatus, "theme", "");
	local vAnimState = addRow(pgStatus, "animations", "");
	local vMobileState = addRow(pgStatus, "mobile mode", "");
	local vFrameRate = addRow(pgStatus, "client fps", "");
	task.spawn(function()
		local ok, info = pcall(function()
			return MPS:GetProductInfo(game.PlaceId);
		end);
		if ok and info and info.Name then
			vGame.Text = info.Name;
		end;
	end);
	local chips = newUi("Frame", pgSettings);
	setUiTag(chips, "Keys");
	chips.BackgroundTransparency = 1;
	chips.Size = UDim2.new(1, -20, 0, 32);
	local chipsLayout = newUi("UIListLayout", chips);
	chipsLayout.FillDirection = Enum.FillDirection.Horizontal;
	chipsLayout.Padding = UDim.new(0, 6);
	chipsLayout.SortOrder = Enum.SortOrder.LayoutOrder;
	chipsLayout.VerticalAlignment = Enum.VerticalAlignment.Center;
	local keysSet = {};
	for _, k in ipairs(_G.toggleKeys) do
		keysSet[k] = true;
	end;
	local function rebuildChips()
		for _, c in ipairs(chips:GetChildren()) do
			if c:IsA("Frame") then
				c:Destroy();
			end;
		end;
		for k, _ in pairs(keysSet) do
			makeKeyChip(chips, k, function(name, chip)
				keysSet[name] = nil;
				if chip and chip.Parent then
					chip:Destroy();
				end;
				local list = {};
				for n, _ in pairs(keysSet) do
					table.insert(list, n);
				end;
				_G.toggleKeys = list;
				saveCfg();
			end);
		end;
	end;
	rebuildChips();
	local btnRow = newUi("Frame", pgSettings);
	btnRow.BackgroundTransparency = 1;
	btnRow.Size = UDim2.new(1, -20, 0, 30);
	local btnLayout = newUi("UIListLayout", btnRow);
	btnLayout.FillDirection = Enum.FillDirection.Horizontal;
	btnLayout.Padding = UDim.new(0, 8);
	btnLayout.SortOrder = Enum.SortOrder.LayoutOrder;
	btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center;
	local addKey = newUi("TextButton", btnRow);
	addKey.Text = "add key";
	addKey.Font = Enum.Font.GothamSemibold;
	addKey.TextSize = 13;
	addKey.TextColor3 = UI.text;
	addKey.AutoButtonColor = false;
	addKey.BackgroundColor3 = UI.ok;
	addKey.Size = UDim2.new(0, 80, 0, 26);
	round(addKey, UDim.new(0.2, 0));
	stroke(addKey, 1, UI.stroke2, 0.15);
	local clrKey = newUi("TextButton", btnRow);
	clrKey.Text = "clear";
	clrKey.Font = Enum.Font.GothamSemibold;
	clrKey.TextSize = 13;
	clrKey.TextColor3 = UI.text;
	clrKey.AutoButtonColor = false;
	clrKey.BackgroundColor3 = UI.danger;
	clrKey.Size = UDim2.new(0, 80, 0, 26);
	round(clrKey, UDim.new(0.2, 0));
	stroke(clrKey, 1, UI.stroke2, 0.15);
	local capConn;
	local lockCapConn;
	local lockCapMode = false;
	local function stopCap()
		capMode = false;
		capCooldownUntil = time() + 0.3;
		if capConn and capConn.Connected then
			capConn:Disconnect();
		end;
		capConn = nil;
	end;
	local function stopLockCap()
		lockCapMode = false;
		capCooldownUntil = time() + 0.3;
		if lockCapConn and lockCapConn.Connected then
			lockCapConn:Disconnect();
		end;
		lockCapConn = nil;
	end;
	local addCon = bindClick(addKey, function()
		if capMode or lockCapMode then
			return;
		end;
		capMode = true;
		toast("press a key");
		capConn = UIS.InputBegan:Connect(function(i, gp)
			if gp then
				return;
			end;
			if i.UserInputType ~= Enum.UserInputType.Keyboard then
				return;
			end;
			local kc = i.KeyCode;
			if kc == Enum.KeyCode.Unknown then
				stopCap();
				return;
			end;
			local name = kc.Name;
			if not keysSet[name] then
				keysSet[name] = true;
				local list = {};
				for n, _ in pairs(keysSet) do
					table.insert(list, n);
				end;
				_G.toggleKeys = list;
				rebuildChips();
				saveCfg();
			end;
			stopCap();
		end);
	end);
	local clrCon = bindClick(clrKey, function()
		keysSet = {};
		_G.toggleKeys = {};
		rebuildChips();
		saveCfg();
	end);
	local lockLbl = newUi("TextLabel", pgSettings);
	lockLbl.BackgroundTransparency = 1;
	lockLbl.Text = "lock key";
	lockLbl.TextColor3 = UI.sub;
	lockLbl.Font = Enum.Font.GothamMedium;
	lockLbl.TextSize = 14;
	lockLbl.TextXAlignment = Enum.TextXAlignment.Left;
	lockLbl.Size = UDim2.new(1, -20, 0, 24);
	local lockBtn = newUi("TextButton", pgSettings);
	lockBtn.Text = _G.lockKey or "MouseButton2";
	lockBtn.Font = Enum.Font.GothamSemibold;
	lockBtn.TextSize = 13;
	lockBtn.TextColor3 = UI.text;
	lockBtn.AutoButtonColor = false;
	lockBtn.BackgroundColor3 = UI.bar2;
	lockBtn.Size = UDim2.new(0, 120, 0, 26);
	round(lockBtn, UDim.new(0.2, 0));
	stroke(lockBtn, 1, UI.stroke2, 0.25);
	local lockCon = bindClick(lockBtn, function()
		if capMode or lockCapMode then
			return;
		end;
		if time() < capCooldownUntil then
			return;
		end;
		lockCapMode = true;
		toast("press key or mouse for lock");
		lockCapConn = UIS.InputBegan:Connect(function(i, gp)
			if not lockCapMode then
				return;
			end;
			local name;
			if i.UserInputType == Enum.UserInputType.Keyboard then
				if i.KeyCode == Enum.KeyCode.Unknown then
					stopLockCap();
					return;
				end;
				name = i.KeyCode.Name;
			elseif i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.MouseButton2 or i.UserInputType == Enum.UserInputType.MouseButton3 then
				name = i.UserInputType.Name;
			else
				return;
			end;
			_G.lockKey = name;
			lockBtn.Text = name;
			saveCfg();
			stopLockCap();
		end);
		table.insert(conns, lockCapConn);
	end);
	local lockReset = newUi("TextButton", pgSettings);
	lockReset.Text = "reset lock key";
	lockReset.Font = Enum.Font.GothamSemibold;
	lockReset.TextSize = 13;
	lockReset.TextColor3 = UI.text;
	lockReset.AutoButtonColor = false;
	lockReset.BackgroundColor3 = UI.bar2;
	lockReset.Size = UDim2.new(0, 140, 0, 26);
	round(lockReset, UDim.new(0.2, 0));
	stroke(lockReset, 1, UI.stroke2, 0.25);
	local lockResetCon = bindClick(lockReset, function()
		_G.lockKey = "MouseButton2";
		lockBtn.Text = "MouseButton2";
		saveCfg();
		toast("lock key reset to MouseButton2");
	end);
	addSection(pgSettings, "option binds");
	_G.pendingBindAction = normChoice(_G.pendingBindAction, BIND_ACTION_OPTIONS, "Aimbot");
	addRowDropdown(pgSettings, "bind option", "pendingBindAction", BIND_ACTION_OPTIONS, "pick what the next key should toggle");
	local bindBox = newUi("Frame", pgSettings);
	bindBox.BackgroundTransparency = 1;
	bindBox.Size = UDim2.new(1, -20, 0, 30);
	bindBox.AutomaticSize = Enum.AutomaticSize.Y;
	local bindLay = newUi("UIListLayout", bindBox);
	bindLay.FillDirection = Enum.FillDirection.Vertical;
	bindLay.Padding = UDim.new(0, 6);
	bindLay.SortOrder = Enum.SortOrder.LayoutOrder;
	local bindBtns = newUi("Frame", pgSettings);
	bindBtns.BackgroundTransparency = 1;
	bindBtns.Size = UDim2.new(1, -20, 0, 30);
	local bindBtnsLay = newUi("UIListLayout", bindBtns);
	bindBtnsLay.FillDirection = Enum.FillDirection.Horizontal;
	bindBtnsLay.Padding = UDim.new(0, 8);
	bindBtnsLay.SortOrder = Enum.SortOrder.LayoutOrder;
	bindBtnsLay.VerticalAlignment = Enum.VerticalAlignment.Center;
	local addBind = newUi("TextButton", bindBtns);
	addBind.Text = "add bind";
	addBind.Font = Enum.Font.GothamSemibold;
	addBind.TextSize = 13;
	addBind.TextColor3 = UI.text;
	addBind.AutoButtonColor = false;
	addBind.BackgroundColor3 = UI.ok;
	addBind.Size = UDim2.new(0, 92, 0, 26);
	round(addBind, UDim.new(0.2, 0));
	stroke(addBind, 1, UI.stroke2, 0.15);
	local clrBind = newUi("TextButton", bindBtns);
	clrBind.Text = "clear binds";
	clrBind.Font = Enum.Font.GothamSemibold;
	clrBind.TextSize = 13;
	clrBind.TextColor3 = UI.text;
	clrBind.AutoButtonColor = false;
	clrBind.BackgroundColor3 = UI.danger;
	clrBind.Size = UDim2.new(0, 104, 0, 26);
	round(clrBind, UDim.new(0.2, 0));
	stroke(clrBind, 1, UI.stroke2, 0.15);
	local function rebuildOptionBindRows()
		for _, c in ipairs(bindBox:GetChildren()) do
			if c:IsA("Frame") then
				c:Destroy();
			end;
		end;
		local any = false;
		for keyName, action in pairs(type(_G.optionBinds) == "table" and _G.optionBinds or {}) do
			any = true;
			local row = newUi("Frame", bindBox);
			row.BackgroundColor3 = UI.bar2;
			row.BackgroundTransparency = 0.08;
			row.BorderSizePixel = 0;
			row.Size = UDim2.new(1, 0, 0, 28);
			round(row, UDim.new(0, 10));
			stroke(row, 1, UI.stroke2, 0.35);
			local txt = newUi("TextLabel", row);
			txt.BackgroundTransparency = 1;
			txt.Size = UDim2.new(1, -42, 1, 0);
			txt.Position = UDim2.new(0, 10, 0, 0);
			txt.Font = Enum.Font.GothamMedium;
			txt.TextSize = 13;
			txt.TextColor3 = UI.text;
			txt.TextXAlignment = Enum.TextXAlignment.Left;
			txt.TextTruncate = Enum.TextTruncate.AtEnd;
			txt.Text = tostring(keyName) .. " -> " .. tostring(action);
			local rm = newUi("TextButton", row);
			rm.Size = UDim2.new(0, 26, 0, 22);
			rm.Position = UDim2.new(1, -30, 0.5, -11);
			rm.BackgroundColor3 = UI.danger;
			rm.AutoButtonColor = false;
			rm.Text = "x";
			rm.TextColor3 = UI.text;
			rm.Font = Enum.Font.GothamBold;
			rm.TextSize = 12;
			round(rm, UDim.new(0, 8));
			local rc = bindClick(rm, function()
				_G.optionBinds[keyName] = nil;
				rebuildOptionBindRows();
				saveCfg();
			end);
		end;
		if not any then
			local empty = newUi("Frame", bindBox);
			empty.BackgroundTransparency = 1;
			empty.Size = UDim2.new(1, 0, 0, 22);
			local txt = newUi("TextLabel", empty);
			txt.BackgroundTransparency = 1;
			txt.Size = UDim2.new(1, 0, 1, 0);
			txt.Font = Enum.Font.Gotham;
			txt.TextSize = 12;
			txt.TextColor3 = UI.sub;
			txt.TextXAlignment = Enum.TextXAlignment.Left;
			txt.Text = "no option binds yet";
		end;
	end;
	rebuildOptionBindRows();
	local addBindCon = bindClick(addBind, function()
		if capMode or lockCapMode then
			return;
		end;
		capMode = true;
		local action = normChoice(_G.pendingBindAction, BIND_ACTION_OPTIONS, "Aimbot");
		toast("press key for " .. action);
		capConn = UIS.InputBegan:Connect(function(i, gp)
			if gp then
				return;
			end;
			if i.UserInputType ~= Enum.UserInputType.Keyboard then
				return;
			end;
			if i.KeyCode == Enum.KeyCode.Unknown then
				stopCap();
				return;
			end;
			_G.optionBinds = type(_G.optionBinds) == "table" and _G.optionBinds or {};
			_G.optionBinds[i.KeyCode.Name] = action;
			rebuildOptionBindRows();
			saveCfg();
			stopCap();
		end);
	end);
	local clrBindCon = bindClick(clrBind, function()
		_G.optionBinds = {};
		rebuildOptionBindRows();
		saveCfg();
	end);
	if isMobilePlatform() then
		addSection(pgSettings, "mobile helper");
		addRowToggle(pgSettings, "mobile center aim", "mobileCenterAim", "touch devices use the exact screen center instead of cursor");
		addRowToggle(pgSettings, "mobile buttons", "mobileButtons", "floating lock and menu buttons for touch devices");
		addRowToggle(pgSettings, "center dot visible", "centerDotVisible", "show or hide the mobile center marker");
		addRowDropdown(pgSettings, "helper button", "pendingMobileAction", MOBILE_ACTION_OPTIONS, "pick what the add helper button action inserts");
		local helperBox = newUi("Frame", pgSettings);
		helperBox.BackgroundTransparency = 1;
		helperBox.Size = UDim2.new(1, -20, 0, 30);
		helperBox.AutomaticSize = Enum.AutomaticSize.Y;
		local helperLay = newUi("UIListLayout", helperBox);
		helperLay.FillDirection = Enum.FillDirection.Vertical;
		helperLay.Padding = UDim.new(0, 6);
		helperLay.SortOrder = Enum.SortOrder.LayoutOrder;
		local function rebuildMobileHelperRows()
			for _, c in ipairs(helperBox:GetChildren()) do
				if c:IsA("Frame") then
					c:Destroy();
				end;
			end;
			if #_G.mobileHelperButtons == 0 then
				local empty = newUi("Frame", helperBox);
				empty.BackgroundTransparency = 1;
				empty.Size = UDim2.new(1, 0, 0, 22);
				local txt = newUi("TextLabel", empty);
				txt.BackgroundTransparency = 1;
				txt.Size = UDim2.new(1, 0, 1, 0);
				txt.Font = Enum.Font.Gotham;
				txt.TextSize = 12;
				txt.TextColor3 = UI.sub;
				txt.TextXAlignment = Enum.TextXAlignment.Left;
				txt.Text = "no helper buttons selected";
				return;
			end;
			for _, actionName in ipairs(_G.mobileHelperButtons) do
				local row = newUi("Frame", helperBox);
				row.BackgroundTransparency = 1;
				row.Size = UDim2.new(1, 0, 0, 28);
				makeKeyChip(row, actionName, function(name)
					local nextList = {};
					for _, existing in ipairs(_G.mobileHelperButtons) do
						if existing ~= name then
							table.insert(nextList, existing);
						end;
					end;
					_G.mobileHelperButtons = nextList;
					rebuildMobileHelperRows();
					rebuildMobileHelper();
					saveCfg();
				end);
			end;
		end;
		rebuildMobileHelperRows();
		local helperBtns = newUi("Frame", pgSettings);
		helperBtns.BackgroundTransparency = 1;
		helperBtns.Size = UDim2.new(1, -20, 0, 30);
		local helperBtnsLay = newUi("UIListLayout", helperBtns);
		helperBtnsLay.FillDirection = Enum.FillDirection.Horizontal;
		helperBtnsLay.Padding = UDim.new(0, 8);
		helperBtnsLay.SortOrder = Enum.SortOrder.LayoutOrder;
		helperBtnsLay.VerticalAlignment = Enum.VerticalAlignment.Center;
		local addHelper = newUi("TextButton", helperBtns);
		addHelper.Text = "add helper";
		addHelper.Font = Enum.Font.GothamSemibold;
		addHelper.TextSize = 13;
		addHelper.TextColor3 = UI.text;
		addHelper.AutoButtonColor = false;
		addHelper.BackgroundColor3 = UI.ok;
		addHelper.Size = UDim2.new(0, 96, 0, 26);
		round(addHelper, UDim.new(0.2, 0));
		stroke(addHelper, 1, UI.stroke2, 0.15);
		local resetHelper = newUi("TextButton", helperBtns);
		resetHelper.Text = "defaults";
		resetHelper.Font = Enum.Font.GothamSemibold;
		resetHelper.TextSize = 13;
		resetHelper.TextColor3 = UI.text;
		resetHelper.AutoButtonColor = false;
		resetHelper.BackgroundColor3 = UI.bar2;
		resetHelper.Size = UDim2.new(0, 84, 0, 26);
		round(resetHelper, UDim.new(0.2, 0));
		stroke(resetHelper, 1, UI.stroke2, 0.25);
		local resetHelperPos = newUi("TextButton", helperBtns);
		resetHelperPos.Text = "reset pos";
		resetHelperPos.Font = Enum.Font.GothamSemibold;
		resetHelperPos.TextSize = 13;
		resetHelperPos.TextColor3 = UI.text;
		resetHelperPos.AutoButtonColor = false;
		resetHelperPos.BackgroundColor3 = UI.bar2;
		resetHelperPos.Size = UDim2.new(0, 92, 0, 26);
		round(resetHelperPos, UDim.new(0.2, 0));
		stroke(resetHelperPos, 1, UI.stroke2, 0.25);
		bindClick(addHelper, function()
			local picked = normChoice(_G.pendingMobileAction, MOBILE_ACTION_OPTIONS, "Aimbot");
			for _, existing in ipairs(_G.mobileHelperButtons) do
				if existing == picked then
					toast("helper button already added");
					return;
				end;
			end;
			table.insert(_G.mobileHelperButtons, picked);
			rebuildMobileHelperRows();
			rebuildMobileHelper();
			saveCfg();
		end);
		bindClick(resetHelper, function()
			_G.mobileHelperButtons = normalizeActionList(nil, MOBILE_ACTION_OPTIONS, MOBILE_HELPER_DEFAULTS);
			rebuildMobileHelperRows();
			rebuildMobileHelper();
			saveCfg();
		end);
		bindClick(resetHelperPos, function()
			_G.mobileHelperPos = nil;
			if uiRefs.mobileHolder then
				uiRefs.mobileHolder.Position = defaultMobileHelperUDim(uiRefs.mobileHolder.AbsoluteSize);
				rememberMobileHelperPos(uiRefs.mobileHolder.Position);
				clampMobileHelperToScreen(uiRefs.mobileHolder);
				saveCfg();
			end;
		end);
	end;
	table.insert(conns, clrCon);
	local statusPulse = 0;
	local fpsAccum = 0;
	local fpsFrames = 0;
	local statusLoop = RunService.Heartbeat:Connect(function(dt)
		local step = dt or 0.016;
		fpsAccum += step;
		fpsFrames += 1;
		statusPulse += step;
		if statusPulse < 0.25 then
			return;
		end;
		local avgDt = fpsFrames > 0 and (fpsAccum / fpsFrames) or step;
		fpsAccum = 0;
		fpsFrames = 0;
		statusPulse = 0;
		local num = Players.NumPlayers or (#Players:GetPlayers());
		local max = Players.MaxPlayers or 0;
		vPlayers.Text = tostring(num) .. " / " .. tostring(max);
		local elapsed = (DateTime.now()).UnixTimestamp - startUnix;
		local h = math.floor(elapsed / 3600);
		local m = math.floor(elapsed % 3600 / 60);
		local s = elapsed % 60;
		vTime.Text = string.format("%02d:%02d:%02d", h, m, s);
		vNow.Text = os.date("%Y-%m-%d %H:%M:%S");
		vPlace.Text = tostring(game.PlaceId);
		vGameId.Text = tostring(game.GameId);
		vJobId.Text = tostring(game.JobId);
		vDevice.Text = UIS:GetPlatform() and (UIS:GetPlatform()).Name or "unknown";
		vLocale.Text = (LS.RobloxLocaleId or "unknown") .. " / " .. (LS.SystemLocaleId or "unknown");
		vExec.Text = identifyexecutor and identifyexecutor() or identifyexec and identifyexec() or "Unknown";
		vAimState.Text = _G.isEnabled and "enabled" or "disabled";
		vLockState.Text = isLock and "locked" or "idle";
		vTargetMode.Text = normalizeAimMode(_G.aimTargetMode);
		vTargetNow.Text = isLock and (lastTargetName or "none") or "none";
		vEspState.Text = _G.espEnabled and "enabled" or "disabled";
		vThemeState.Text = tostring(_G.uiTheme or "Midnight Purple");
		vAnimState.Text = _G.uiAnimations == false and "off" or ("on / " .. tostring(_G.uiAnimSpeed or 1) .. "x");
		vMobileState.Text = isMobilePlatform() and "yes" or "no";
		vFrameRate.Text = tostring(math.floor(1 / math.max(avgDt, 0.001) + 0.5));
	end);
	table.insert(conns, statusLoop);
	local centerDot = newUi("Frame", gui);
	setUiTag(centerDot, "CenterLockPoint");
	centerDot.AnchorPoint = Vector2.new(0.5, 0.5);
	centerDot.Position = UDim2.new(0.5, 0, 0.5, 0);
	centerDot.Size = UDim2.new(0, _G.centerDotSize or 12, 0, _G.centerDotSize or 12);
	centerDot.BackgroundTransparency = _G.centerDotAlpha;
	centerDot.BackgroundColor3 = UI.acc2;
	centerDot.BorderSizePixel = 0;
	centerDot.ZIndex = 25;
	round(centerDot, UDim.new(1, 0));
	stroke(centerDot, 2, UI.acc, 0.15);
	local dotIn = newUi("Frame", centerDot);
	dotIn.AnchorPoint = Vector2.new(0.5, 0.5);
	dotIn.Position = UDim2.new(0.5, 0, 0.5, 0);
	dotIn.Size = UDim2.new(0, 4, 0, 4);
	dotIn.BackgroundColor3 = UI.text;
	dotIn.BorderSizePixel = 0;
	round(dotIn, UDim.new(1, 0));
	uiRefs.centerDot = centerDot;
	local mobHolder = newUi("Frame", gui);
	setUiTag(mobHolder, "MobileButtons");
	mobHolder.BackgroundColor3 = UI.bar1;
	mobHolder.BackgroundTransparency = 0.08;
	mobHolder.AnchorPoint = Vector2.zero;
	mobHolder.Position = mobileHelperUDim();
	mobHolder.ZIndex = 24;
	mobHolder.Active = true;
	mobHolder.BorderSizePixel = 0;
	round(mobHolder, UDim.new(0, 18));
	stroke(mobHolder, 1, UI.stroke2, 0.16);
	uiRefs.mobileHolder = mobHolder;
	local mobBar = newUi("Frame", mobHolder);
	mobBar.BackgroundColor3 = UI.tabActive;
	mobBar.BackgroundTransparency = 0.04;
	mobBar.BorderSizePixel = 0;
	mobBar.Size = UDim2.new(1, -10, 0, 26);
	mobBar.Position = UDim2.new(0, 5, 0, 5);
	mobBar.ZIndex = 25;
	round(mobBar, UDim.new(0, 14));
	local mobBarLbl = newUi("TextLabel", mobBar);
	mobBarLbl.BackgroundTransparency = 1;
	mobBarLbl.Size = UDim2.new(1, -16, 1, 0);
	mobBarLbl.Position = UDim2.new(0, 10, 0, 0);
	mobBarLbl.Font = Enum.Font.GothamBlack;
	mobBarLbl.TextSize = 12;
	mobBarLbl.TextXAlignment = Enum.TextXAlignment.Left;
	mobBarLbl.TextColor3 = UI.text;
	mobBarLbl.Text = "MOBILE HELPER";
	mobBarLbl.ZIndex = 26;
	local mobHint = newUi("TextLabel", mobBar);
	mobHint.BackgroundTransparency = 1;
	mobHint.AnchorPoint = Vector2.new(1, 0.5);
	mobHint.Position = UDim2.new(1, -10, 0.5, 0);
	mobHint.Size = UDim2.new(0, 44, 0, 18);
	mobHint.Font = Enum.Font.GothamBold;
	mobHint.TextSize = 11;
	mobHint.TextColor3 = UI.acc2;
	mobHint.Text = "DRAG";
	mobHint.ZIndex = 26;
	local mobContent = newUi("Frame", mobHolder);
	mobContent.BackgroundTransparency = 1;
	mobContent.Position = UDim2.new(0, 10, 0, 38);
	mobContent.Size = UDim2.new(1, -20, 1, -48);
	mobContent.ZIndex = 25;
	local mobGrid = newUi("UIGridLayout", mobContent);
	mobGrid.FillDirectionMaxCells = 2;
	mobGrid.SortOrder = Enum.SortOrder.LayoutOrder;
	mobGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center;
	mobGrid.VerticalAlignment = Enum.VerticalAlignment.Top;
	local mobEmpty = newUi("TextLabel", mobContent);
	mobEmpty.BackgroundTransparency = 1;
	mobEmpty.Size = UDim2.new(1, 0, 0, 22);
	mobEmpty.Position = UDim2.new(0, 0, 0, 0);
	mobEmpty.Font = Enum.Font.Gotham;
	mobEmpty.TextSize = 12;
	mobEmpty.TextColor3 = UI.sub;
	mobEmpty.Text = "No helper buttons";
	mobEmpty.Visible = false;
	mobEmpty.ZIndex = 26;
	local function helperLabel(actionName)
		local labels = {
			["Aim Lock"] = "LOCKMODE",
			["Wall Check"] = "WALL",
			["Team Check"] = "TEAM",
			["Alive Check"] = "ALIVE",
			["Lock FOV"] = "FOV",
			["FOV Circle"] = "CIRCLE",
			["Lock Nearest"] = "NEAREST",
			["Center Dot"] = "DOT"
		};
		return string.upper(labels[actionName] or actionName);
	end;
	local function mobileActionTap(actionName)
		if actionName == "Menu" then
			if uiMin then
				openUI();
			else
				closeUI();
			end;
			return;
		end;
		if actionName == "Lock" then
			startLockAction();
			task.delay(0.05, function()
				if _G.aimLock then
					return;
				end;
				endLockAction();
			end);
			return;
		end;
		handleOptionBind(actionName);
	end;
	clampMobileHelperToScreen = function(target)
		local holder = target or uiRefs.mobileHolder;
		if not holder or not holder.Parent then
			return;
		end;
		local vp = getViewport();
		local size = holder.AbsoluteSize;
		local pos = holder.Position;
		local x = math.clamp(pos.X.Scale * vp.X + pos.X.Offset, 8, math.max(8, vp.X - size.X - 8));
		local y = math.clamp(pos.Y.Scale * vp.Y + pos.Y.Offset, 8, math.max(8, vp.Y - size.Y - 8));
		holder.Position = UDim2.new(pos.X.Scale, x - (pos.X.Scale * vp.X), pos.Y.Scale, y - (pos.Y.Scale * vp.Y));
		rememberMobileHelperPos(holder.Position);
	end;
	rebuildMobileHelper = function()
		for _, child in ipairs(mobContent:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy();
			end;
		end;
		local actions = normalizeActionList(_G.mobileHelperButtons, MOBILE_ACTION_OPTIONS, MOBILE_HELPER_DEFAULTS);
		_G.mobileHelperButtons = actions;
		local scale = math.clamp(tonumber(_G.mobileButtonScale) or 1, 0.7, 1.45);
		local btnW = math.floor(82 * scale);
		local btnH = math.floor(40 * scale);
		local pad = math.floor(8 * scale);
		local cols = math.min(2, math.max(1, #actions));
		local rows = math.max(1, math.ceil(math.max(#actions, 1) / cols));
		mobGrid.CellSize = UDim2.new(0, btnW, 0, btnH);
		mobGrid.CellPadding = UDim2.new(0, pad, 0, pad);
		mobGrid.FillDirectionMaxCells = cols;
		mobEmpty.Visible = #actions == 0;
		for index, actionName in ipairs(actions) do
			local b = newUi("TextButton", mobContent);
			b.LayoutOrder = index;
			b.BackgroundColor3 = actionName == "Menu" and UI.acc2 or (actionName == "Lock" and UI.acc or UI.bar2);
			b.BackgroundTransparency = _G.mobileButtonAlpha;
			b.BorderSizePixel = 0;
			b.AutoButtonColor = false;
			b.Text = helperLabel(actionName);
			b.TextColor3 = UI.text;
			b.Font = Enum.Font.GothamBlack;
			b.TextSize = math.floor(12 * scale);
			b.ZIndex = 26;
			round(b, UDim.new(0, 14));
			stroke(b, 1, UI.stroke, 0.18);
			if actionName == "Lock" then
				table.insert(conns, b.InputBegan:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
						startLockAction();
					end;
				end));
				table.insert(conns, b.InputEnded:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
						endLockAction();
					end;
				end));
			else
				bindClick(b, function()
					mobileActionTap(actionName);
				end);
			end;
		end;
		local width = (cols * btnW) + (math.max(0, cols - 1) * pad) + 20;
		local bodyHeight = mobEmpty.Visible and 24 or ((rows * btnH) + (math.max(0, rows - 1) * pad));
		mobHolder.Size = UDim2.new(0, width, 0, bodyHeight + 50);
		mobContent.Size = UDim2.new(1, -20, 0, bodyHeight);
		if not _G.mobileHelperPos then
			mobHolder.Position = defaultMobileHelperUDim(Vector2.new(width, bodyHeight + 50));
			rememberMobileHelperPos(mobHolder.Position);
		end;
		clampMobileHelperToScreen(mobHolder);
	end;
	refreshMobileUI = function()
		local touch = isMobilePlatform();
		centerDot.Visible = touch and _G.mobileCenterAim == true and _G.centerDotVisible == true;
		mobHolder.Visible = touch and _G.mobileButtons == true;
	end;
	rebuildMobileHelper();
	refreshMobileUI();
	applyCustomUI();
	local mobBarDrag = attachOffsetUIDrag(mobHolder, nil, function(holder)
		clampMobileHelperToScreen(holder);
		saveCfg();
	end);
	if mobBarDrag then
		mobBarDrag.ReferenceUIInstance = mobBar;
	end;
	local camVpCon;
	local function bindViewportResize()
		if camVpCon then
			camVpCon:Disconnect();
		end;
		if cam then
			camVpCon = (cam:GetPropertyChangedSignal("ViewportSize")):Connect(function()
				local w, h = frameSizeForViewport();
				frame.Size = UDim2.new(0, w, 0, h);
				clampFrameToScreen(frame);
				rebuildMobileHelper();
				refreshMobileUI();
			end);
			table.insert(conns, camVpCon);
		end;
	end;
	bindViewportResize();
	local resizeCon = (workspace:GetPropertyChangedSignal("CurrentCamera")):Connect(function()
		task.defer(function()
			cam = workspace.CurrentCamera;
			bindViewportResize();
			local w, h = frameSizeForViewport();
			if frame and frame.Parent then
				frame.Size = UDim2.new(0, w, 0, h);
				clampFrameToScreen(frame);
			end;
			rebuildMobileHelper();
			refreshMobileUI();
		end);
	end);
	table.insert(conns, resizeCon);
	local minCon = bindClick(btnMin, function()
		if uiMin then
			openUI();
		else
			closeUI();
		end;
	end);
	local topCon = bindClick(topBtn, function()
		if time() < topClickBlock then
			return;
		end;
		if uiMin then
			openUI();
		end;
	end);
	attachBetterDragger(topToggleHolder, {
		topToggleHolder,
		topBtn
	}, function(target, moved)
		rememberTopToggle(topToggleHolder.Position);
		if moved then
			topClickBlock = time() + 0.18;
		end;
		saveCfg();
	end);
	local closeCon = bindClick(btnX, function()
		for _, c in pairs(conns) do
			disconnectConn(c);
		end;
		conns = {};
		isLock = false;
		_G.isEnabled = false;
		_G.aimTargetMode = "Head";
		_G.espEnabled = false;
		_G.lockToNearest = false;
		_G.aliveCheck = false;
		_G.teamCheck = false;
		_G.wallCheck = false;
		_G.fovEnabled = false;
		if openDropdown and openDropdown.row then
			openDropdown.row.Size = UDim2.new(1, -20, 0, openDropdown.baseHeight or openDropdown.row.Size.Y.Offset);
		end;
		openDropdown = nil;
		randomAimCache = newRandomAimCache();
		randomAimSeq = randomAimSeq + 1;
		lastLockedCharacter = nil;
		lastLockedPart = nil;
		if lockCamLoop and lockCamLoop.Connected then
			lockCamLoop:Disconnect();
			lockCamLoop = nil;
		end;
		clearFOVHooks();
		for p, _ in pairs(espMap) do
			espDetach(p);
		end;
		espMap = {};
		CAS:UnbindAction("VyperiaBot");
		CAS:UnbindAction("VyperiaBotBlock");
		toast("Aimbot unloaded");
		task.delay(0.5, function()
			if gui and gui.Parent then
				gui:Destroy();
			end;
		end);
	end);
	attachBetterDragger(frame, bar);
	frame.Position = UDim2.new(0.5, 0, -0.5, 0);
	tw(frame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundTransparency = _G.uiWindowAlpha
	});
	return frame;
end;
local function modelAABBOnScreen(m)
	local cf, sz = m:GetBoundingBox();
	local hx, hy, hz = sz.X / 2, sz.Y / 2, sz.Z / 2;
	local pts = {
		Vector3.new(-hx, -hy, -hz),
		Vector3.new(hx, -hy, -hz),
		Vector3.new(-hx, hy, -hz),
		Vector3.new(hx, hy, -hz),
		Vector3.new(-hx, -hy, hz),
		Vector3.new(hx, -hy, hz),
		Vector3.new(-hx, hy, hz),
		Vector3.new(hx, hy, hz)
	};
	local minX, minY = math.huge, math.huge;
	local maxX, maxY = -math.huge, -math.huge;
	local any = false;
	for i = 1, 8 do
		local wp = cf:PointToWorldSpace(pts[i]);
		local v, on = cam:WorldToViewportPoint(wp);
		if v.Z > 0 then
			any = true;
			if on then
				if v.X < minX then
					minX = v.X;
				end;
				if v.X > maxX then
					maxX = v.X;
				end;
				if v.Y < minY then
					minY = v.Y;
				end;
				if v.Y > maxY then
					maxY = v.Y;
				end;
			else
				if v.X < minX then
					minX = v.X;
				end;
				if v.X > maxX then
					maxX = v.X;
				end;
				if v.Y < minY then
					minY = v.Y;
				end;
				if v.Y > maxY then
					maxY = v.Y;
				end;
			end;
		end;
	end;
	if not any then
		return nil;
	end;
	return minX, minY, maxX, maxY;
end;
local function cursorInsideModel(m, pad)
	local a, b, c, d = modelAABBOnScreen(m);
	if not a then
		return false;
	end;
	local aim = getAimPoint();
	local x, y = aim.X, aim.Y;
	local p = pad or 2;
	return x >= a - p and x <= c + p and y >= b - p and y <= d + p;
end;
local function isLockInput(i)
	local key = _G.lockKey or "MouseButton2";
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.MouseButton2 or i.UserInputType == Enum.UserInputType.MouseButton3 then
		return i.UserInputType.Name == key;
	end;
	if i.UserInputType == Enum.UserInputType.Keyboard then
		return i.KeyCode.Name == key;
	end;
	return false;
end;
function startLockAction()
	if UIS:GetFocusedTextBox() then
		return;
	end;
	if not _G.isEnabled then
		return;
	end;
	if _G.aimLock then
		isLock = not isLock;
		if isLock then
			if normalizeAimMode(_G.aimTargetMode) == "Random" then
				bumpRandomAim();
			end;
			if _G.fovEnabled and cam then
				cam.FieldOfView = _G.fovValue;
			end;
			lockCamera();
		end;
	else
		isLock = true;
		if normalizeAimMode(_G.aimTargetMode) == "Random" then
			bumpRandomAim();
		end;
		if _G.fovEnabled and cam then
			cam.FieldOfView = _G.fovValue;
		end;
		lockCamera();
	end;
end;
function endLockAction()
	if _G.aimLock then
		return;
	end;
	isLock = false;
end;
handleOptionBind = function(action)
	local var = BIND_ACTION_VARS[action];
	if not var then
		return false;
	end;
	_G[var] = not _G[var];
	if var == "lockToNearest" then
		_G.targetPriorityMode = _G.lockToNearest and "Distance" or "Crosshair";
	end;
	if var == "espEnabled" or var == "teamCheck" or var == "aliveCheck" or var == "espShowName" or var == "espShowHP" or var == "espShowTeam" or var == "espTeamColor" or var == "espShowDistance" or var == "espAlwaysOnTop" then
		updateESP();
	elseif var == "fovEnabled" then
		if _G.fovEnabled and cam then
			cam.FieldOfView = _G.fovValue;
		end;
	elseif var == "mobileButtons" or var == "mobileCenterAim" or var == "centerDotVisible" then
		if var == "mobileButtons" then
			rebuildMobileHelper();
		end;
		refreshMobileUI();
		updateFOVCircle();
	elseif var == "fovCircleEnabled" then
		updateFOVCircle();
	end;
	saveCfg();
	toast(action .. (_G[var] and " enabled" or " disabled"));
	return true;
end;
local function binds()
	local bMouse = UIS.InputBegan:Connect(function(i, gp)
		if gp then
			return;
		end;
		if not isLockInput(i) then
			return;
		end;
		startLockAction();
	end);
	table.insert(conns, bMouse);
	local bMouseEnd = UIS.InputEnded:Connect(function(i)
		if not isLockInput(i) then
			return;
		end;
		endLockAction();
	end);
	table.insert(conns, bMouseEnd);
	local bKeys = UIS.InputEnded:Connect(function(i, gp)
		if gp then
			return;
		end;
		if UIS:GetFocusedTextBox() then
			return;
		end;
		if capMode or time() < capCooldownUntil then
			return;
		end;
		if i.UserInputType ~= Enum.UserInputType.Keyboard then
			return;
		end;
		local name = i.KeyCode.Name;
		local bindsMap = type(_G.optionBinds) == "table" and _G.optionBinds or {};
		local action = bindsMap[name];
		if action and handleOptionBind(action) then
			return;
		end;
		if table.find(_G.toggleKeys, name) then
			if not frm or (not frm.Parent) then
				return;
			end;
			if uiMin then
				openUI();
			else
				closeUI();
			end;
		end;
	end);
	table.insert(conns, bKeys);
end;
function lockCamera()
	if lockCamLoop and lockCamLoop.Connected then
		return;
	end;
	local lastCh = nil;
	local trackedCh = nil;
	local trackedPart = nil;
	local reacquireClock = math.huge;
	lockCamLoop = RunService.RenderStepped:Connect(function(dt)
		if not isLock or (not _G.isEnabled) then
			if aimCamTween then
				aimCamTween:Cancel();
				aimCamTween = nil;
			end;
			trackedCh = nil;
			trackedPart = nil;
			if lockCamLoop then
				lockCamLoop:Disconnect();
				lockCamLoop = nil;
			end;
			return;
		end;
		reacquireClock += dt or 0.016;
		local aimMode = normalizeAimMode(_G.aimTargetMode);
		local needsRefresh = reacquireClock >= getLockRefreshInterval();
		if trackedCh and (not isTrackedAimPartUsable(trackedCh, trackedPart, false)) then
			needsRefresh = true;
		end;
		if (not trackedCh) or needsRefresh then
			reacquireClock = 0;
			local ch, scanPart = findTarget();
			if ch ~= lastCh then
				if aimMode == "Random" and ch then
					bumpRandomAim(ch);
				end;
				lastCh = ch;
			end;
			trackedCh = ch;
			if ch then
				if aimMode ~= "Random" and isTrackedAimPartUsable(ch, lastLockedPart, _G.wallCheck == true) then
					trackedPart = lastLockedPart;
				else
					trackedPart = topAimPart(ch) or scanPart;
					lastLockedPart = trackedPart;
				end;
			else
				trackedPart = nil;
				lastLockedPart = nil;
			end;
		end;
		if trackedCh and trackedPart then
			local tgtPos = _G.aimPredict and getPredictedAimPos(trackedPart) or trackedPart.Position;
			local cf = CFrame.new(cam.CFrame.Position, tgtPos);
			local doTween = _G.aimTween == true;
			if doTween then
				if aimCamTween then
					aimCamTween:Cancel();
					aimCamTween = nil;
				end;
				local alpha = math.clamp(getAimTweenDuration() * 8, 0.08, 0.9);
				cam.CFrame = cam.CFrame:Lerp(cf, alpha);
			else
				if aimCamTween then
					aimCamTween:Cancel();
					aimCamTween = nil;
				end;
				cam.CFrame = cf;
			end;
		end;
	end);
	table.insert(conns, lockCamLoop);
end;
local function setupPlayerMonitoring()
	local function hook(pp)
		local ca = pp.CharacterAdded:Connect(function()
			task.wait(0.1);
			if _G.espEnabled then
				espAttach(pp);
			end;
		end);
		table.insert(conns, ca);
	end;
	for _, pp in ipairs(Players:GetPlayers()) do
		if pp ~= plr then
			hook(pp);
		end;
	end;
	local a = Players.PlayerAdded:Connect(function(pp)
		hook(pp);
		if _G.espEnabled then
			task.defer(function()
				espAttach(pp);
			end);
		end;
	end);
	table.insert(conns, a);
	local r = Players.PlayerRemoving:Connect(function(pp)
		espDetach(pp);
	end);
	table.insert(conns, r);
	local c = plr.CharacterAdded:Connect(function()
		if not gui or (not gui.Parent) then
			frm = createUI();
			binds();
		end;
		if _G.espEnabled then
			updateESP();
		end;
	end);
	table.insert(conns, c);
end;
frm = createUI();
binds();
setupPlayerMonitoring();
if _G.espEnabled then
	updateESP();
end;
toast("Aimbot loaded");
saveCfg();
local function chkMode()
	local newMode;
	if #Players:GetPlayers() > 0 and Players.LocalPlayer.Team == nil then
		newMode = "FFA";
	else
		newMode = "Team";
	end;
	if newMode ~= mode then
		mode = newMode;
		lastMode = mode;
		updateESP();
	end;
end;
local teamPulse = 0;
local teamCon = RunService.Heartbeat:Connect(function(dt)
	teamPulse += dt or 0.016;
	if teamPulse < 0.5 then
		return;
	end;
	teamPulse = 0;
	chkMode();
end);
table.insert(conns, teamCon);
return function()
	for _, c in pairs(conns) do
		disconnectConn(c);
	end;
	if lockCamLoop and lockCamLoop.Connected then
		lockCamLoop:Disconnect();
		lockCamLoop = nil;
	end;
	for p, _ in pairs(espMap) do
		espDetach(p);
	end;
	CAS:UnbindAction("VyperiaBot");
	CAS:UnbindAction("VyperiaBotBlock");
	clearFOVHooks();
	if gui and gui.Parent then
		gui:Destroy();
	end;
end;
