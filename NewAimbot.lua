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
local __NAUIProtector = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {};
	local sharedEnv = rawget(_G, "shared");
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil);
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_ui_protector");
		if type(cached) == "table" then
			return cached;
		end;
	end;
	local loader = loadstring or load;
	if type(loader) ~= "function" then
		return nil;
	end;
	local okSource, source = pcall(function()
		return game:HttpGet("https://ltseverydayyou.github.io/UIprotector.luau");
	end);
	if not okSource or type(source) ~= "string" or source == "" then
		return nil;
	end;
	local chunk = loader(source, "@UIprotector.luau");
	if type(chunk) ~= "function" then
		return nil;
	end;
	local okLoaded, loaded = pcall(chunk);
	if okLoaded and type(loaded) == "table" then
		if cacheHost then
			cacheHost.__lt_ui_protector = loaded;
		end;
		return loaded;
	end;
	return nil;
end)();
local __NAOriginalGetHui = gethui;
local gethui = function()
	if __NAUIProtector and type(__NAUIProtector.huiGrabber) == "function" then
		local ok, ui = pcall(__NAUIProtector.huiGrabber);
		if ok and typeof(ui) == "Instance" then
			return ui;
		end;
	end;
	if type(__NAOriginalGetHui) == "function" then
		local ok, ui = pcall(__NAOriginalGetHui);
		if ok then
			return ui;
		end;
	end;
	return nil;
end;
local function __NAProtectUI(gui, options)
	if __NAUIProtector and type(__NAUIProtector.protectUI) == "function" then
		local ok, protected = pcall(__NAUIProtector.protectUI, gui, options);
		if ok and protected then
			return protected;
		end;
	end;
	return nil;
end;

local _G = (getgenv and getgenv()) or _G or {};
if type(_G.__vyperiaAimbotCleanup) == "function" then
	pcall(_G.__vyperiaAimbotCleanup);
end;
_G.__vyperiaAimbotCleanup = nil;

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
_G.__vyperiaLockOpt = type(_G.__vyperiaLockOpt) == "table" and _G.__vyperiaLockOpt or {};
VLO = _G.__vyperiaLockOpt;
VLO.deathWatch = type(VLO.deathWatch) == "table" and VLO.deathWatch or {};
VLO.scanGap = 0;
VLO.partGap = 0;
VLO.aliveGap = 0;
VLO.seq = 0;
local rng = Random.new();
local trackedPlayers = {};
local plrIdx = {};
local plrChars = {};
local charOwner = {};
local plrModelMark = setmetatable({}, { __mode = "k" });
local function newRandomAimCache()
	return setmetatable({}, {
		__mode = "k"
	});
end;
local randomAimCache = newRandomAimCache();
local randomAimSeq = 0;
local function setTrackedCharacter(pp, ch)
	local old = plrChars[pp];
	if old and charOwner[old] == pp then
		charOwner[old] = nil;
	end;
	plrChars[pp] = ch;
	if ch then
		charOwner[ch] = pp;
		plrModelMark[ch] = pp;
	end;
end;
local function trackPlayer(pp)
	if not pp or plrIdx[pp] then
		return;
	end;
	trackedPlayers[#trackedPlayers + 1] = pp;
	plrIdx[pp] = #trackedPlayers;
	setTrackedCharacter(pp, pp.Character);
end;
local function untrackPlayer(pp)
	if not pp then
		return;
	end;
	setTrackedCharacter(pp, nil);
	local idx = plrIdx[pp];
	if not idx then
		return;
	end;
	local last = trackedPlayers[#trackedPlayers];
	trackedPlayers[idx] = last;
	trackedPlayers[#trackedPlayers] = nil;
	plrIdx[pp] = nil;
	if last and last ~= pp then
		plrIdx[last] = idx;
	end;
end;
local function rebuildPlrs()
	table.clear(trackedPlayers);
	table.clear(plrIdx);
	table.clear(plrChars);
	table.clear(charOwner);
	table.clear(plrModelMark);
	for _, pp in ipairs(Players:GetPlayers()) do
		trackPlayer(pp);
	end;
end;
local function getPlrs()
	return trackedPlayers;
end;
local function getPlrCount()
	return #trackedPlayers;
end;
local function getPlrFromCh(ch)
	return charOwner[ch] or plrModelMark[ch] or Players:GetPlayerFromCharacter(ch);
end;
local npc = {
	owner = tostring(os.clock()) .. ":" .. tostring(math.random(1, 1000000000)),
	roots = {
		"HumanoidRootPart",
		"UpperTorso",
		"LowerTorso",
		"Torso",
		"Head"
	}
};
function npc.safe(c)
	if c then
		pcall(function()
			c:Disconnect();
		end);
	end;
end;
function npc.player(model)
	if not model or (not model:IsA("Model")) then
		return false;
	end;
	if plrModelMark[model] then
		return true;
	end;
	if getPlrFromCh(model) then
		return true;
	end;
	local ok, owner = pcall(function()
		return Players:GetPlayerFromCharacter(model);
	end);
	if ok and owner then
		return true;
	end;
	for _, pp in ipairs(getPlrs()) do
		local ch = pp.Character;
		if ch and (model == ch or model:IsDescendantOf(ch) or ch:IsDescendantOf(model)) then
			return true;
		end;
	end;
	return false;
end;
function npc.cand(model)
	if not model or (not model:IsA("Model")) then
		return false;
	end;
	if not model.Parent or (not model:IsDescendantOf(workspace)) then
		return false;
	end;
	local hum = model:FindFirstChildOfClass("Humanoid");
	if not hum or hum.Parent == nil then
		return false;
	end;
	if npc.player(model) then
		return false;
	end;
	return true;
end;
function npc.hum(model, rec)
	if rec and rec.hum and rec.hum.Parent == model and rec.hum:IsA("Humanoid") then
		return rec.hum;
	end;
	local hum = model and model:FindFirstChildOfClass("Humanoid");
	if rec then
		rec.hum = hum;
	end;
	return hum;
end;
function npc.root(model, rec)
	if rec and rec.root and rec.root.Parent and rec.root:IsA("BasePart") and rec.root:IsDescendantOf(model) then
		return rec.root;
	end;
	for i = 1, #npc.roots do
		local p = model:FindFirstChild(npc.roots[i]);
		if p and p:IsA("BasePart") then
			if rec then
				rec.root = p;
			end;
			return p;
		end;
	end;
	local pp = model.PrimaryPart;
	if pp and pp:IsA("BasePart") then
		if rec then
			rec.root = pp;
		end;
		return pp;
	end;
	for _, ch in ipairs(model:GetChildren()) do
		if ch:IsA("BasePart") then
			if rec then
				rec.root = ch;
			end;
			return ch;
		end;
	end;
	if rec and rec.deepRootTried ~= true then
		rec.deepRootTried = true;
		for i = 1, #npc.roots do
			local p = model:FindFirstChild(npc.roots[i], true);
			if p and p:IsA("BasePart") then
				rec.root = p;
				return p;
			end;
		end;
	end;
	return nil;
end;
function npc.is(model)
	if not npc.cand(model) then
		return false;
	end;
	local hum = model:FindFirstChildOfClass("Humanoid");
	if not hum or hum.Parent == nil or hum.Health <= 0 then
		return false;
	end;
	local ok, state = pcall(function()
		return hum:GetState();
	end);
	if ok and (state == Enum.HumanoidStateType.Dead or state == Enum.HumanoidStateType.None) then
		return false;
	end;
	local rec = {};
	local anchor = npc.root(model, rec);
	if not anchor or (not anchor:IsA("BasePart")) then
		return false;
	end;
	return true;
end;
function npc.dispose(force)
	local cache = _G.__vyperiaNpcTargetCache;
	if type(cache) ~= "table" then
		return;
	end;
	if not force and cache.owner ~= npc.owner then
		return;
	end;
	npc.safe(cache.addConn);
	npc.safe(cache.remConn);
	cache.addConn = nil;
	cache.remConn = nil;
	cache.dead = true;
	if type(cache.cands) == "table" then
		table.clear(cache.cands);
	end;
	if type(cache.idx) == "table" then
		table.clear(cache.idx);
	end;
	if type(cache.order) == "table" then
		table.clear(cache.order);
	end;
	if type(cache.meta) == "table" then
		table.clear(cache.meta);
	end;
	if type(cache.list) == "table" then
		table.clear(cache.list);
	end;
	if type(cache.live) == "table" then
		table.clear(cache.live);
	end;
	if type(cache.nextPicks) == "table" then
		table.clear(cache.nextPicks);
	end;
	if _G.__vyperiaNpcTargetCache == cache then
		_G.__vyperiaNpcTargetCache = nil;
	end;
end;
function npc.rem(cache, model)
	if not model or not cache.cands[model] then
		return;
	end;
	local rec = cache.meta[model];
	if rec then
		npc.safe(rec.hpConn);
		npc.safe(rec.diedConn);
		rec.hpConn = nil;
		rec.diedConn = nil;
	end;
	cache.cands[model] = nil;
	cache.live[model] = nil;
	cache.meta[model] = nil;
	local i = cache.idx[model];
	if i then
		local n = #cache.order;
		local last = cache.order[n];
		cache.order[n] = nil;
		cache.idx[model] = nil;
		if last and last ~= model then
			cache.order[i] = last;
			cache.idx[last] = i;
		end;
		if cache.cursor > n then
			cache.cursor = 1;
		elseif i < cache.cursor then
			cache.cursor = math.max(1, cache.cursor - 1);
		end;
	end;
end;
function npc.add(cache, model)
	if cache.dead or not model or cache.cands[model] then
		return;
	end;
	if not npc.cand(model) then
		return;
	end;
	cache.meta[model] = cache.meta[model] or {};
	local rec = cache.meta[model];
	local hum = npc.hum(model, rec);
	if not hum or hum.Parent == nil or hum.Health <= 0 then
		cache.meta[model] = nil;
		return;
	end;
	cache.cands[model] = true;
	cache.order[#cache.order + 1] = model;
	cache.idx[model] = #cache.order;
	rec.hpConn = hum.HealthChanged:Connect(function(hp)
		if tonumber(hp) and hp <= 0 then
			npc.rem(cache, model);
		end;
	end);
	rec.diedConn = hum.Died:Connect(function()
		npc.rem(cache, model);
	end);
end;
function npc.model(inst)
	if not inst then
		return nil;
	end;
	if inst:IsA("Model") then
		return inst;
	end;
	if inst:IsA("Humanoid") then
		local par = inst.Parent;
		if par and par:IsA("Model") then
			return par;
		end;
	end;
	return inst:FindFirstAncestorOfClass("Model");
end;
function npc.seed(cache)
	if cache.seeding or cache.seeded or cache.dead then
		return;
	end;
	cache.seeding = true;
	task.spawn(function()
		local q = { workspace };
		local qi = 1;
		local steps = 0;
		while (not cache.dead) and qi <= #q do
			local inst = q[qi];
			q[qi] = nil;
			qi += 1;
			if inst and inst.Parent then
				if inst:IsA("Model") then
					npc.add(cache, inst);
				elseif inst:IsA("Humanoid") then
					local par = inst.Parent;
					if par and par:IsA("Model") then
						npc.add(cache, par);
					end;
				end;
				local ok, children = pcall(function()
					return inst:GetChildren();
				end);
				if ok and type(children) == "table" then
					for i = 1, #children do
						q[#q + 1] = children[i];
					end;
				end;
			end;
			steps += 1;
			if steps % 900 == 0 then
				task.wait();
			end;
		end;
		cache.seeded = true;
		cache.seeding = false;
	end);
end;
function npc.make()
	local old = _G.__vyperiaNpcTargetCache;
	if type(old) == "table" and old.owner ~= npc.owner then
		npc.dispose(true);
	end;
	local cache = _G.__vyperiaNpcTargetCache;
	if type(cache) == "table" and cache.init == true and cache.owner == npc.owner and cache.dead ~= true then
		return cache;
	end;
	cache = {
		init = true,
		ver = 6,
		owner = npc.owner,
		dead = false,
		stamp = 0,
		seeded = false,
		seeding = false,
		cursor = 1,
		cands = {},
		idx = {},
		order = {},
		meta = setmetatable({}, { __mode = "k" }),
		live = {},
		list = {},
		nextPicks = {}
	};
	cache.add = function(model)
		return npc.add(cache, model);
	end;
	cache.remove = function(model)
		return npc.rem(cache, model);
	end;
	cache.seed = function()
		return npc.seed(cache);
	end;
	cache.addConn = workspace.DescendantAdded:Connect(function(inst)
		if cache.dead then
			return;
		end;
		if inst:IsA("Model") or inst:IsA("Humanoid") then
			local model = npc.model(inst);
			if model then
				npc.add(cache, model);
			end;
		elseif inst:IsA("BasePart") then
			local model = inst:FindFirstAncestorOfClass("Model");
			local rec = model and cache.meta[model];
			if rec then
				rec.deepRootTried = false;
				if not rec.root then
					local ln = inst.Name;
					if ln == "HumanoidRootPart" or ln == "UpperTorso" or ln == "LowerTorso" or ln == "Torso" or ln == "Head" then
						rec.root = inst;
					end;
				end;
			end;
		end;
	end);
	cache.remConn = workspace.DescendantRemoving:Connect(function(inst)
		if cache.dead then
			return;
		end;
		if inst:IsA("Model") then
			npc.rem(cache, inst);
		elseif inst:IsA("Humanoid") then
			local par = inst.Parent;
			if par and par:IsA("Model") then
				npc.rem(cache, par);
			end;
		elseif inst:IsA("BasePart") then
			local model = inst:FindFirstAncestorOfClass("Model");
			local rec = model and cache.meta[model];
			if rec and rec.root == inst then
				rec.root = nil;
				rec.deepRootTried = false;
			end;
		end;
	end);
	_G.__vyperiaNpcTargetCache = cache;
	npc.seed(cache);
	return cache;
end;
function npc.ok(model, rec)
	if not model or not model.Parent or not model:IsDescendantOf(workspace) then
		return false, nil, true;
	end;
	if npc.player(model) then
		return false, nil, true;
	end;
	local hum = npc.hum(model, rec);
	if not hum or hum.Parent == nil then
		return false, nil, true;
	end;
	if hum.Health <= 0 then
		return false, nil, true;
	end;
	local ok, state = pcall(function()
		return hum:GetState();
	end);
	if ok and (state == Enum.HumanoidStateType.Dead or state == Enum.HumanoidStateType.None) then
		return false, nil, true;
	end;
	local root = npc.root(model, rec);
	if not root or root.Parent == nil then
		return false, nil, false;
	end;
	return true, root, false;
end;
function npc.finish(cache)
	local picks = cache.nextPicks;
	table.sort(picks, function(a, b)
		if math.abs((a.dist or 0) - (b.dist or 0)) < 0.001 then
			return tostring(a.model.Name) < tostring(b.model.Name);
		end;
		return (a.dist or 0) < (b.dist or 0);
	end);
	local list = {};
	local live = {};
	local maxCnt = math.clamp(tonumber(_G.npcTargetMaxCount) or 200, 16, 500);
	for i = 1, math.min(#picks, maxCnt) do
		local model = picks[i].model;
		if model and model.Parent then
			list[#list + 1] = model;
			live[model] = true;
		end;
	end;
	cache.list = list;
	cache.live = live;
	table.clear(picks);
end;
function npc.step(cache)
	if cache.dead then
		return;
	end;
	if type(cache.seed) == "function" then
		cache.seed();
	end;
	local now = os.clock();
	local int = math.clamp(tonumber(_G.npcTargetScanInterval) or 0.12, 0.05, 1);
	if now - (tonumber(cache.stamp) or 0) < int then
		return;
	end;
	cache.stamp = now;
	cache.cursor = tonumber(cache.cursor) or 1;
	local order = cache.order;
	local n = #order;
	if n == 0 then
		cache.cursor = 1;
		if #cache.list > 0 then
			cache.list = {};
		end;
		return;
	end;
	if cache.cursor < 1 or cache.cursor > n then
		cache.cursor = 1;
	end;
	if cache.cursor == 1 then
		table.clear(cache.nextPicks);
	end;
	local char = plr and plr.Character;
	local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("LowerTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("Head"));
	local maxDist = math.clamp(tonumber(_G.targetMaxDistance) or 2500, 100, 5000);
	local budget = math.clamp(tonumber(_G.npcTargetScanBudget) or 96, 16, 512);
	local scanned = 0;
	while scanned < budget and n > 0 do
		local i = cache.cursor;
		local model = order[i];
		scanned += 1;
		if not model then
			cache.cursor = i + 1;
		elseif not cache.cands[model] then
			cache.cursor = i + 1;
		else
			local rec = cache.meta[model];
			if not rec then
				rec = {};
				cache.meta[model] = rec;
			end;
			local ok, anchor, drop = npc.ok(model, rec);
			if drop then
				npc.rem(cache, model);
				n = #order;
				if i > n then
					cache.cursor = 1;
					npc.finish(cache);
					break;
				else
					cache.cursor = i;
				end;
			elseif ok and anchor then
				local dist = root and (anchor.Position - root.Position).Magnitude or 0;
				if (not root) or dist <= maxDist then
					cache.nextPicks[#cache.nextPicks + 1] = {
						model = model,
						dist = dist
					};
				end;
				cache.cursor = i + 1;
			else
				cache.cursor = i + 1;
			end;
		end;
		if cache.cursor > n then
			cache.cursor = 1;
			npc.finish(cache);
			break;
		end;
	end;
end;
function npc.get()
	local cache = npc.make();
	npc.step(cache);
	return cache.list or {};
end;
rebuildPlrs();
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
_G.entMode = _G.entMode or _G.targetEntityMode or ((_G.targetNPCs == true) and "Player/NPC" or "Player");
_G.randWtOn = _G.randWtOn ~= nil and _G.randWtOn or (_G.randomTargetWeightsEnabled == true);
_G.randomWeightHead = _G.randomWeightHead or 40;
_G.randomWeightRoot = _G.randomWeightRoot or 20;
_G.randomWeightUpperTorso = _G.randomWeightUpperTorso or 18;
_G.randomWeightLowerTorso = _G.randomWeightLowerTorso or 10;
_G.randomWeightTorso = _G.randomWeightTorso or 12;
_G.randomWeightOther = _G.randomWeightOther or 5;
_G.autoSaveConfigs = _G.autoSaveConfigs ~= nil and _G.autoSaveConfigs or true;
_G.selectedConfigName = _G.selectedConfigName or "default";
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
local OPT = {
	AIM_TARGET_OPTIONS = {
		"Head",
		"Torso",
		"Root",
		"Upper Torso",
		"Lower Torso",
		"Random"
	},
	TARGET_POINT_OPTIONS = {
		"Cursor",
		"Center"
	},
	TARGET_PRIORITY_OPTIONS = {
		"Crosshair",
		"Distance",
		"Lowest Health"
	},
	TARGET_ENTITY_OPTIONS = {
		"Player",
		"NPC",
		"Player/NPC"
	},
	RANDOM_WEIGHT_VARS = {
		"randomWeightHead",
		"randomWeightRoot",
		"randomWeightUpperTorso",
		"randomWeightLowerTorso",
		"randomWeightTorso",
		"randomWeightOther"
	},
	ESP_RENDER_OPTIONS = {
		"Highlight",
		"BoxHandleAdornment"
	},
	THEME_OPTIONS = {
		"Midnight Purple",
		"Cyan",
		"Purple",
		"Pink",
		"Green",
		"Gold",
		"Red"
	},
	BIND_ACTION_OPTIONS = {
		"Aimbot",
		"Aim Lock",
		"ESP",
		"Wall Check",
		"Team Check",
		"Alive Check",
		"Lock FOV",
		"Smooth Aim",
		"Prediction",
		"FOV Circle",
		"Lock Nearest",
		"Mobile Buttons",
		"Mobile Center Aim",
		"Center Dot"
	},
	BIND_ACTION_VARS = {
		["Aimbot"] = "isEnabled",
		["Aim Lock"] = "aimLock",
		["ESP"] = "espEnabled",
		["Wall Check"] = "wallCheck",
		["Team Check"] = "teamCheck",
		["Alive Check"] = "aliveCheck",
		["Lock FOV"] = "fovEnabled",
		["Smooth Aim"] = "aimTween",
		["Prediction"] = "aimPredict",
		["FOV Circle"] = "fovCircleEnabled",
		["Lock Nearest"] = "lockToNearest",
		["Mobile Buttons"] = "mobileButtons",
		["Mobile Center Aim"] = "mobileCenterAim",
		["Center Dot"] = "centerDotVisible"
	},
	MOBILE_ACTION_OPTIONS = {
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
	},
	TOAST_POS_OPTIONS = {
		"Top Right",
		"Top Left",
		"Bottom Right",
		"Bottom Left"
	},
	MOBILE_HELPER_DEFAULTS = {
		"Lock",
		"Menu",
		"Center Dot"
	}
};
local function normalizeAimMode(mode)
	local lower = (tostring(mode or "")):lower();
	for _, opt in ipairs(OPT.AIM_TARGET_OPTIONS) do
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
	return math.clamp(_G.aimSmooth or 0.28, 0.03, 1);
end;
local cfgFile = "ltseverydayyou-Aimbot/config.json";
local function cleanCfgName(name)
	local clean = tostring(name or "default");
	clean = clean:gsub("[^%w%-%_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "");
	if clean == "" then
		clean = "default";
	end;
	return clean;
end;
local function copyCfgVal(v)
	if type(v) ~= "table" then
		return v;
	end;
	local out = {};
	for k, vv in pairs(v) do
		out[k] = copyCfgVal(vv);
	end;
	return out;
end;
local DEFAULT_CONFIG = {
	isEnabled = false,
	aimTargetMode = "Head",
	espEnabled = false,
	lockToNearest = false,
	aliveCheck = false,
	teamCheck = false,
	wallCheck = false,
	aimTween = false,
	aimSmooth = 0.28,
	fovEnabled = false,
	fovValue = 70,
	espShowName = true,
	espShowHP = true,
	espShowTeam = true,
	espTeamColor = true,
	espTransparency = 0.3,
	tbCPS = 8,
	aimPredict = false,
	aimLead = 0.12,
	aimRadius = 150,
	targetPointMode = "Cursor",
	fovCircleEnabled = false,
	fovCircleAlpha = 0.25,
	fovCircleThickness = 2,
	aimLock = false,
	lockKey = "MouseButton2",
	mobileCenterAim = isMobilePlatform(),
	mobileButtons = isMobilePlatform(),
	uiScale = 1,
	uiWindowAlpha = 0.08,
	uiContentAlpha = 0.02,
	uiTheme = "Midnight Purple",
	uiAnimations = true,
	uiAnimSpeed = 1,
	uiCompact = false,
	uiRounded = 24,
	toastDuration = 3,
	toastMax = 4,
	toastCompact = false,
	toastPosition = "Top Right",
	centerDotVisible = true,
	centerDotSize = 12,
	centerDotAlpha = 0.35,
	mobileButtonScale = 1,
	mobileButtonAlpha = 0.06,
	mobileHelperButtons = {
		"Lock",
		"Menu",
		"Center Dot"
	},
	mobileHelperPos = nil,
	pendingMobileAction = "Aimbot",
	topTogglePos = {
		XScale = 0.5,
		XOffset = -76,
		YScale = 0,
		YOffset = 8
	},
	optionBinds = {},
	pendingBindAction = "Aimbot",
	toggleKeys = {
		"RightAlt",
		"LeftAlt",
		"P",
		"RightControl"
	},
	espRenderMode = "Highlight",
	espAlwaysOnTop = true,
	espShowDistance = false,
	espTextSize = 14,
	espMaxDistance = 2500,
	espOutlineTransparency = 0.12,
	targetPriorityMode = "Crosshair",
	stickyTarget = true,
	targetMaxDistance = 2500,
	entMode = "Player",
	randWtOn = false,
	randomWeightHead = 40,
	randomWeightRoot = 20,
	randomWeightUpperTorso = 18,
	randomWeightLowerTorso = 10,
	randomWeightTorso = 12,
	randomWeightOther = 5,
	autoSaveConfigs = true,
	selectedConfigName = "default"
};
local function resetCfg()
	for k, v in pairs(DEFAULT_CONFIG) do
		_G[k] = copyCfgVal(v);
	end;
end;
local function getCfgPath(name)
	return "ltseverydayyou-Aimbot/configs/" .. cleanCfgName(name) .. ".json";
end;
local function saveMeta()
	if not writefile or (not HS) then
		return;
	end;
	if isfolder and (not isfolder("ltseverydayyou-Aimbot")) then
		if makefolder then
			pcall(makefolder, "ltseverydayyou-Aimbot");
		else
			return;
		end;
	end;
	local ok, enc = pcall(function()
		return HS:JSONEncode({
			selectedConfigName = cleanCfgName(_G.selectedConfigName),
			autoSaveConfigs = _G.autoSaveConfigs == true
		});
	end);
	if ok and enc then
		pcall(writefile, cfgFile, enc);
	end;
end;
local function getConfigNames()
	local picked = cleanCfgName(_G.selectedConfigName);
	local names = {
		"default"
	};
	local seen = {
		["default"] = true
	};
	if picked ~= "default" then
		seen[picked] = true;
		table.insert(names, picked);
	end;
	if listfiles and isfolder and isfolder("ltseverydayyou-Aimbot/configs") then
		for _, path in ipairs(listfiles("ltseverydayyou-Aimbot/configs")) do
			local name = tostring(path):match("([^/\\]+)%.json$");
			if name then
				name = cleanCfgName(name);
				if not seen[name] then
					seen[name] = true;
					table.insert(names, name);
				end;
			end;
		end;
	end;
	table.sort(names, function(a, b)
		if a == "default" then
			return true;
		end;
		if b == "default" then
			return false;
		end;
		return tostring(a):lower() < tostring(b):lower();
	end);
	return names;
end;
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
local function clampRandomWeightValue(v, defaultValue)
	return math.clamp(tonumber(v) or defaultValue or 0, 0, 100);
end;
local function normalizeRandomWeights()
	_G.randWtOn = _G.randWtOn == true or _G.randomTargetWeightsEnabled == true;
	_G.randomWeightHead = clampRandomWeightValue(_G.randomWeightHead, 40);
	_G.randomWeightRoot = clampRandomWeightValue(_G.randomWeightRoot, 20);
	_G.randomWeightUpperTorso = clampRandomWeightValue(_G.randomWeightUpperTorso, 18);
	_G.randomWeightLowerTorso = clampRandomWeightValue(_G.randomWeightLowerTorso, 10);
	_G.randomWeightTorso = clampRandomWeightValue(_G.randomWeightTorso, 12);
	_G.randomWeightOther = clampRandomWeightValue(_G.randomWeightOther, 5);
end;
local function applyToastPos()
	local h = uiRefs.toastHolder or toastHolder;
	if not h then
		return;
	end;
	local pos = normChoice(_G.toastPosition, OPT.TOAST_POS_OPTIONS, "Top Right");
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
local unbindStrongInputs, rebindStrongInputs;
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
		if isClick and type(clickCallback) == "function" then
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
local function saveCfg(forceSave, nameOverride)
	if not writefile or (not HS) then
		return;
	end;
	if (not forceSave) and _G.autoSaveConfigs == false then
		return;
	end;
	local okFolder = true;
	if isfolder and (not isfolder("ltseverydayyou-Aimbot")) then
		if makefolder then
			local s, e = pcall(makefolder, "ltseverydayyou-Aimbot");
			okFolder = s and e == nil or s;
		else
			okFolder = false;
		end;
	end;
	if not okFolder then
		return;
	end;
	if isfolder and (not isfolder("ltseverydayyou-Aimbot/configs")) then
		if makefolder then
			local s = pcall(makefolder, "ltseverydayyou-Aimbot/configs");
			if not s then
				return;
			end;
		else
			return;
		end;
	end;
	local aimMode = normalizeAimMode(_G.aimTargetMode);
	_G.aimTargetMode = aimMode;
	_G.selectedConfigName = cleanCfgName(nameOverride or _G.selectedConfigName);
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
		targetPointMode = _G.targetPointMode,
		fovCircleEnabled = _G.fovCircleEnabled,
		fovCircleAlpha = _G.fovCircleAlpha,
		fovCircleThickness = _G.fovCircleThickness,
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
		pendingBindAction = _G.pendingBindAction,
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
		targetMaxDistance = _G.targetMaxDistance,
		entMode = _G.entMode,
		randWtOn = _G.randWtOn,
		randomWeightHead = _G.randomWeightHead,
		randomWeightRoot = _G.randomWeightRoot,
		randomWeightUpperTorso = _G.randomWeightUpperTorso,
		randomWeightLowerTorso = _G.randomWeightLowerTorso,
		randomWeightTorso = _G.randomWeightTorso,
		randomWeightOther = _G.randomWeightOther,
		autoSaveConfigs = _G.autoSaveConfigs == true,
		selectedConfigName = _G.selectedConfigName
	};
	local ok, enc = pcall(function()
		return HS:JSONEncode(data);
	end);
	if ok and enc then
		pcall(writefile, getCfgPath(_G.selectedConfigName), enc);
		saveMeta();
	end;
end;
local function applyCfg(obj)
	if type(obj) ~= "table" then
		return false;
	end;
	if obj.lockToHead ~= nil and obj.aimTargetMode == nil then
		obj.aimTargetMode = obj.lockToHead and "Head" or "Torso";
	end;
	if obj.aimTargetMode then
		obj.aimTargetMode = normalizeAimMode(obj.aimTargetMode);
	end;
	if obj.uiTheme then
		obj.uiTheme = normChoice(obj.uiTheme, OPT.THEME_OPTIONS, "Midnight Purple");
	end;
	if obj.toastPosition then
		obj.toastPosition = normChoice(obj.toastPosition, OPT.TOAST_POS_OPTIONS, "Top Right");
	end;
	if obj.targetPriorityMode then
		obj.targetPriorityMode = normChoice(obj.targetPriorityMode, OPT.TARGET_PRIORITY_OPTIONS, "Crosshair");
	end;
	if obj.entMode then
		obj.entMode = normChoice(obj.entMode, OPT.TARGET_ENTITY_OPTIONS, "Player");
	elseif obj.targetEntityMode then
		obj.entMode = normChoice(obj.targetEntityMode, OPT.TARGET_ENTITY_OPTIONS, "Player");
	elseif obj.targetNPCs ~= nil then
		obj.entMode = obj.targetNPCs == true and "Player/NPC" or "Player";
	end;
	if obj.randWtOn == nil and obj.randomTargetWeightsEnabled ~= nil then
		obj.randWtOn = obj.randomTargetWeightsEnabled == true;
	end;
	if obj.espRenderMode then
		obj.espRenderMode = normChoice(obj.espRenderMode, OPT.ESP_RENDER_OPTIONS, "Highlight");
	end;
	if obj.pendingMobileAction then
		obj.pendingMobileAction = normChoice(obj.pendingMobileAction, OPT.MOBILE_ACTION_OPTIONS, "Aimbot");
	end;
	if obj.pendingBindAction then
		obj.pendingBindAction = normChoice(obj.pendingBindAction, OPT.BIND_ACTION_OPTIONS, "Aimbot");
	end;
	if obj.targetPointMode then
		obj.targetPointMode = normChoice(obj.targetPointMode, OPT.TARGET_POINT_OPTIONS, "Cursor");
	end;
	if obj.selectedConfigName then
		obj.selectedConfigName = cleanCfgName(obj.selectedConfigName);
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
	if type(obj.toggleKeys) ~= "table" then
		obj.toggleKeys = copyCfgVal(DEFAULT_CONFIG.toggleKeys);
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
	for _, key in ipairs(OPT.RANDOM_WEIGHT_VARS) do
		if obj[key] ~= nil then
			obj[key] = clampRandomWeightValue(obj[key], _G[key]);
		end;
	end;
	for k, v in pairs(obj) do
		if _G[k] ~= nil then
			_G[k] = copyCfgVal(v);
		end;
	end;
	return true;
end;
local function loadNameCfg(name)
	if not readfile or (not isfile) or (not HS) then
		return false;
	end;
	local picked = cleanCfgName(name or _G.selectedConfigName);
	local path = getCfgPath(picked);
	if not isfile(path) then
		return false;
	end;
	local ok, txt = pcall(readfile, path);
	if not ok or type(txt) ~= "string" or txt == "" then
		return false;
	end;
	local ok2, obj = pcall(function()
		return HS:JSONDecode(txt);
	end);
	if not ok2 or type(obj) ~= "table" then
		return false;
	end;
	_G.selectedConfigName = picked;
	saveMeta();
	return applyCfg(obj);
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
	if obj.selectedConfigName ~= nil or obj.autoSaveConfigs ~= nil then
		_G.selectedConfigName = cleanCfgName(obj.selectedConfigName or _G.selectedConfigName);
		if obj.autoSaveConfigs ~= nil then
			_G.autoSaveConfigs = obj.autoSaveConfigs == true;
		end;
		if not loadNameCfg(_G.selectedConfigName) and next(obj) ~= nil then
			applyCfg(obj);
		end;
		return;
	end;
	applyCfg(obj);
end;
loadCfg();
_G.selectedConfigName = cleanCfgName(_G.selectedConfigName);
_G.autoSaveConfigs = _G.autoSaveConfigs == true;
_G.targetPointMode = normChoice(_G.targetPointMode, OPT.TARGET_POINT_OPTIONS, "Cursor");
_G.fovCircleAlpha = math.clamp(tonumber(_G.fovCircleAlpha) or 0.25, 0, 1);
_G.fovCircleThickness = math.clamp(tonumber(_G.fovCircleThickness) or 2, 1, 8);
_G.espRenderMode = normChoice(_G.espRenderMode, OPT.ESP_RENDER_OPTIONS, "Highlight");
_G.pendingMobileAction = normChoice(_G.pendingMobileAction, OPT.MOBILE_ACTION_OPTIONS, "Aimbot");
_G.targetPriorityMode = normChoice(_G.targetPriorityMode, OPT.TARGET_PRIORITY_OPTIONS, "Crosshair");
_G.entMode = normChoice(_G.entMode, OPT.TARGET_ENTITY_OPTIONS, "Player");
_G.mobileHelperButtons = normalizeActionList(_G.mobileHelperButtons, OPT.MOBILE_ACTION_OPTIONS, OPT.MOBILE_HELPER_DEFAULTS);
_G.randWtOn = _G.randWtOn == true;
_G.espTextSize = math.clamp(tonumber(_G.espTextSize) or 14, 10, 24);
_G.espMaxDistance = math.clamp(tonumber(_G.espMaxDistance) or 2500, 100, 5000);
_G.espOutlineTransparency = math.clamp(tonumber(_G.espOutlineTransparency) or 0.12, 0, 1);
_G.targetMaxDistance = math.clamp(tonumber(_G.targetMaxDistance) or 2500, 100, 5000);
normalizeRandomWeights();
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
		rec.upperTorso = nil;
		rec.lowerTorso = nil;
		rec.humanoid = nil;
		rec.parts = {};
		for _, inst in ipairs(model:QueryDescendants("Instance")) do
			if inst:IsA("Humanoid") then
				rec.humanoid = inst;
			elseif inst:IsA("AnimationController") then
				rec.humanoid = rec.humanoid or inst;
			elseif inst:IsA("BasePart") then
				table.insert(rec.parts, inst);
				local ln = inst.Name:lower();
				if ln:find("root") then
					rec.root = rec.root or inst;
				elseif ln == "uppertorso" or ln == "upper_torso" or ln == "upper torso" then
					rec.upperTorso = rec.upperTorso or inst;
					rec.torso = rec.torso or inst;
				elseif ln == "lowertorso" or ln == "lower_torso" or ln == "lower torso" then
					rec.lowerTorso = rec.lowerTorso or inst;
					rec.torso = rec.torso or inst;
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
	local rec, model = NA_GRAB_BODY.ensure(m);
	model = model or NA_GRAB_BODY.asChar(m) or m;
	if model and model:IsA("Model") then
		local hum = model:FindFirstChildOfClass("Humanoid");
		if rec then
			rec.humanoid = hum;
		end;
		return hum;
	end;
	return nil;
end;
uiRefs.humAlive = function(hum, ch)
	if not hum or (not hum:IsA("Humanoid")) or hum.Parent ~= ch or (not hum:IsDescendantOf(workspace)) then
		return false;
	end;
	if hum.Health <= 0 then
		return false;
	end;
	local ok, state = pcall(function()
		return hum:GetState();
	end);
	if ok and (state == Enum.HumanoidStateType.Dead or state == Enum.HumanoidStateType.None) then
		return false;
	end;
	return true;
end;
uiRefs.liveHum = function(ch)
	if not ch or (not ch:IsA("Model")) or ch.Parent == nil or (not ch:IsDescendantOf(workspace)) then
		return nil;
	end;
	local hum = ch:FindFirstChildOfClass("Humanoid");
	if not uiRefs.humAlive(hum, ch) then
		local rec = NA_GRAB_BODY.ensure(ch);
		if rec then
			rec.humanoid = hum;
		end;
		return nil;
	end;
	local rec = NA_GRAB_BODY.ensure(ch);
	if rec then
		rec.humanoid = hum;
	end;
	local anchor = rec and (rec.root or rec.torso or rec.head or NA_GRAB_BODY.firstPart(ch)) or nil;
	if not anchor or anchor.Parent == nil or (not anchor:IsDescendantOf(ch)) then
		return nil;
	end;
	return hum;
end;
uiRefs.hardAlive = function(ch, part)
	local hum = uiRefs.liveHum(ch);
	if not hum then
		return false;
	end;
	if part then
		if not part:IsA("BasePart") or part.Parent == nil or (not part:IsDescendantOf(ch)) then
			return false;
		end;
		if part.Transparency >= 1 or part:FindFirstAncestorOfClass("Accessory") then
			return false;
		end;
	end;
	return true;
end;
uiRefs.clearAimDeathWatch = function(w)
	if type(w) ~= "table" then
		return;
	end;
	disconnectConn(w.hpConn);
	disconnectConn(w.diedConn);
	w.hpConn = nil;
	w.diedConn = nil;
	w.ch = nil;
	w.hum = nil;
end;
uiRefs.watchAimDeath = function(w, ch, onDead)
	if type(w) ~= "table" then
		return;
	end;
	local hum = ch and uiRefs.liveHum(ch) or nil;
	if not ch or not hum then
		uiRefs.clearAimDeathWatch(w);
		return;
	end;
	if w.ch == ch and w.hum == hum then
		return;
	end;
	uiRefs.clearAimDeathWatch(w);
	w.ch = ch;
	w.hum = hum;
	w.hpConn = hum.HealthChanged:Connect(function(hp)
		if tonumber(hp) and hp <= 0 then
			if type(onDead) == "function" then
				onDead();
			end;
			uiRefs.clearAimDeathWatch(w);
		end;
	end);
	w.diedConn = hum.Died:Connect(function()
		if type(onDead) == "function" then
			onDead();
		end;
		uiRefs.clearAimDeathWatch(w);
	end);
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
	if (lname == "upper torso" or lname == "upper_torso" or lname == "uppertorso" or lname == "upper") and rec.upperTorso then
		return rec.upperTorso;
	end;
	if (lname == "lower torso" or lname == "lower_torso" or lname == "lowertorso" or lname == "lower") and rec.lowerTorso then
		return rec.lowerTorso;
	end;
	if lname == "torso" and rec.torso then
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
local function getRoot(m)
	return getPart(m, "HumanoidRootPart") or getTorsoLikePart(m);
end;
local function getTorso(m)
	return getPart(m, "UpperTorso") or getPart(m, "LowerTorso") or getPart(m, "Torso") or getRoot(m);
end;
local function getHead(m)
	return getPart(m, "Head") or getRoot(m);
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
	add(getHead(model), 4);
	add(getRoot(model), 2);
	add(getPart(model, "UpperTorso"), 2);
	add(getPart(model, "LowerTorso"), 1);
	add(getTorso(model), 1);
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
local function resetAimCaches(resetTrackedTarget)
	randomAimCache = newRandomAimCache();
	randomAimSeq = randomAimSeq + 1;
	local npcCache = _G.__vyperiaNpcTargetCache;
	if type(npcCache) == "table" and npcCache.init == true and npcCache.owner == npc.owner then
		npcCache.stamp = 0;
		npcCache.cursor = 1;
		if type(npcCache.list) == "table" then
			table.clear(npcCache.list);
		end;
		if type(npcCache.live) == "table" then
			table.clear(npcCache.live);
		end;
		if type(npcCache.nextPicks) == "table" then
			table.clear(npcCache.nextPicks);
		end;
		for model in pairs(npcCache.cands or {}) do
			if not model or not model.Parent or npc.player(model) then
				if type(npcCache.remove) == "function" then
					npcCache.remove(model);
				else
					npcCache.cands[model] = nil;
				end;
			end;
		end;
	else
		npc.dispose(true);
	end;
	if resetTrackedTarget then
		lastLockedCharacter = nil;
		lastLockedPart = nil;
		lastTargetName = "none";
	end;
end;
local function invalidateTargetState(ch)
	resetAimCaches(lastLockedCharacter ~= nil and (ch == nil or lastLockedCharacter == ch));
end;
local function buildWeightedPartEntries(m, needLOS, avoid)
	local rec, model = NA_GRAB_BODY.ensure(m);
	if not rec or (not model) then
		return {};
	end;
	local entries = {};
	local seen = {};
	local function add(part, weight)
		weight = clampRandomWeightValue(weight, 0);
		if weight <= 0 or not usableAimPart(part, model) or seen[part] then
			return;
		end;
		if needLOS and (not clearLOS(part)) then
			return;
		end;
		seen[part] = true;
		table.insert(entries, {
			part = part,
			weight = weight
		});
	end;
	add(getHead(model), _G.randomWeightHead);
	add(getRoot(model), _G.randomWeightRoot);
	add(getPart(model, "UpperTorso"), _G.randomWeightUpperTorso);
	add(getPart(model, "LowerTorso"), _G.randomWeightLowerTorso);
	add(getTorso(model), _G.randomWeightTorso);
	local otherWeight = clampRandomWeightValue(_G.randomWeightOther, 0);
	if otherWeight > 0 and rec.parts then
		for _, part in ipairs(rec.parts) do
			if part ~= avoid then
				add(part, otherWeight);
			end;
		end;
	end;
	if avoid then
		local alt = {};
		for _, entry in ipairs(entries) do
			if entry.part ~= avoid then
				table.insert(alt, entry);
			end;
		end;
		if #alt > 0 then
			entries = alt;
		end;
	end;
	return entries;
end;
local function chooseWeightedEntry(entries)
	local total = 0;
	for _, entry in ipairs(entries) do
		total += entry.weight;
	end;
	if total <= 0 then
		return nil;
	end;
	local roll = rng:NextNumber(0, total);
	local acc = 0;
	for _, entry in ipairs(entries) do
		acc += entry.weight;
		if roll <= acc then
			return entry.part;
		end;
	end;
	return entries[#entries] and entries[#entries].part or nil;
end;
local function randomVisibleAimPart(m, avoid)
	return chooseAimPart(aimPartPool(m, true), avoid);
end;
local function pickPreferredPart(m, prefer)
	local head = getHead(m);
	local torso = getTorso(m);
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
	if _G.randWtOn then
		local weighted = buildWeightedPartEntries(m, _G.wallCheck == true, avoid);
		local picked = chooseWeightedEntry(weighted);
		if picked then
			return picked;
		end;
	end;
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
local function getAimPos(part)
	local pos = _G.aimPredict and getPredictedAimPos(part) or part.Position;
	local aimMode = normalizeAimMode(_G.aimTargetMode);
	if aimMode == "Head" and tostring(part.Name):lower():find("head") then
		local yOff = math.clamp((part.Size.Y or 1) * 0.18, 0.08, 0.35);
		pos += Vector3.new(0, yOff, 0);
	end;
	return pos;
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
		local p = getRoot(m);
		if p and ((not _G.wallCheck) or clearLOS(p)) then
			return p;
		end;
		if _G.wallCheck then
			return randomVisibleAimPart(m, p);
		end;
	elseif aimMode == "Upper Torso" then
		local p = getPart(m, "UpperTorso") or getTorso(m);
		if p and ((not _G.wallCheck) or clearLOS(p)) then
			return p;
		end;
		if _G.wallCheck then
			return randomVisibleAimPart(m, p);
		end;
	elseif aimMode == "Lower Torso" then
		local p = getPart(m, "LowerTorso") or getTorso(m);
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
	return getTorso(m) or getHead(m);
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
		add(getHead(ch));
		add(getTorso(ch));
	elseif aimMode == "Root" then
		add(getRoot(ch));
		add(getTorso(ch));
		add(getHead(ch));
	elseif aimMode == "Upper Torso" then
		add(getPart(ch, "UpperTorso") or getTorso(ch));
		add(getRoot(ch));
		add(getHead(ch));
	elseif aimMode == "Lower Torso" then
		add(getPart(ch, "LowerTorso") or getTorso(ch));
		add(getRoot(ch));
		add(getHead(ch));
	elseif aimMode == "Random" then
		add(randomTargetFor(ch));
		if _G.randWtOn then
			local weighted = buildWeightedPartEntries(ch, false);
			table.sort(weighted, function(a, b)
				if a.weight == b.weight then
					return tostring(a.part.Name) < tostring(b.part.Name);
				end;
				return a.weight > b.weight;
			end);
			for _, entry in ipairs(weighted) do
				add(entry.part);
			end;
		end;
		add(getRoot(ch));
		add(getTorso(ch));
		add(getHead(ch));
	else
		add(getRoot(ch));
		add(getTorso(ch));
		add(getHead(ch));
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
	if _G.aliveCheck and (not uiRefs.liveHum(ch)) then
		return false;
	end;
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
	return uiRefs.liveHum(ch) ~= nil;
end;
local function getTargetPriorityMode()
	_G.targetPriorityMode = normChoice(_G.targetPriorityMode, OPT.TARGET_PRIORITY_OPTIONS, "Crosshair");
	return _G.targetPriorityMode;
end;
local function isCharacterStillTargetable(ch, preferredPart)
	if not ch or not ch.Parent then
		return false, nil;
	end;
	local entityMode = normChoice(_G.entMode, OPT.TARGET_ENTITY_OPTIONS, "Player");
	local allowPlayers = entityMode == "Player" or entityMode == "Player/NPC";
	local allowNpcs = entityMode == "NPC" or entityMode == "Player/NPC";
	local op = getPlrFromCh(ch);
	local validNpc = false;
	if op then
		if not allowPlayers then
			return false, nil;
		end;
		if op == plr or (not isEnemy(op)) or (not isAlive(ch)) then
			return false, nil;
		end;
	else
		if not allowNpcs then
			return false, nil;
		end;
		validNpc = npc.is(ch);
		if (not validNpc) or (not isAlive(ch)) then
			return false, nil;
		end;
	end;
	if (not op) and (not validNpc) then
		return false, nil;
	end;
	local part = isTrackedAimPartUsable(ch, preferredPart, _G.wallCheck == true) and preferredPart or getScanAimPart(ch);
	if not part or not uiRefs.hardAlive(ch, part) then
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
	local entityMode = normChoice(_G.entMode, OPT.TARGET_ENTITY_OPTIONS, "Player");
	local allowPlayers = entityMode == "Player" or entityMode == "Player/NPC";
	local allowNpcs = entityMode == "NPC" or entityMode == "Player/NPC";
	local stickyOk, stickyPart = false, nil;
	if _G.stickyTarget then
		stickyOk, stickyPart = isCharacterStillTargetable(lastLockedCharacter, lastLockedPart);
	end;
	if stickyOk then
		lastTargetName = lastLockedCharacter.Name;
		lastLockedPart = stickyPart;
		return lastLockedCharacter, stickyPart;
	end;
	if lastLockedCharacter and (not stickyOk) then
		lastLockedCharacter = nil;
		lastLockedPart = nil;
	end;
	local near = nil;
	local nearPart = nil;
	local nearIsNpc = false;
	local bestPrimary = math.huge;
	local bestSecondary = math.huge;
	local modeName = getTargetPriorityMode();
	local maxR = _G.aimRadius or 150;
	local maxDistance = math.clamp(tonumber(_G.targetMaxDistance) or 2500, 100, 5000);
	local mp = getAimPoint();
	local camPos = cam.CFrame.Position;
	local coarseR = maxR + 48;
	local coarse = {};
	local function considerCharacter(ch, isNpc)
		if isNpc and npc.player(ch) then
			return;
		end;
		if not isAlive(ch) then
			return;
		end;
		local hum = uiRefs.liveHum(ch);
		if not hum then
			return;
		end;
		local anchor = getRoot(ch) or getTorso(ch) or getHead(ch);
		if not anchor then
			return;
		end;
		local anchorDist = (anchor.Position - camPos).Magnitude;
		if anchorDist > maxDistance then
			return;
		end;
		local anchorScr, anchorOn = cam:WorldToViewportPoint(anchor.Position);
		if not anchorOn then
			return;
		end;
		local anchorSdist = (Vector2.new(anchorScr.X, anchorScr.Y) - mp).Magnitude;
		if modeName == "Crosshair" and anchorSdist > coarseR then
			return;
		end;
		local primary = anchorSdist;
		local secondary = anchorDist;
		if modeName == "Distance" or _G.lockToNearest then
			primary = anchorDist;
			secondary = anchorSdist;
		elseif modeName == "Lowest Health" then
			primary = hum.Health;
			secondary = anchorSdist;
		end;
		coarse[#coarse + 1] = {
			ch = ch,
			isNpc = isNpc == true,
			primary = primary,
			secondary = secondary
		};
	end;
	if allowPlayers then
		for _, op in ipairs(getPlrs()) do
			if op ~= plr and op.Character and isEnemy(op) then
				considerCharacter(op.Character, false);
			end;
		end;
	end;
	if allowNpcs then
		for _, np in ipairs(npc.get()) do
			considerCharacter(np, true);
		end;
	end;
	table.sort(coarse, function(a, b)
		if math.abs(a.primary - b.primary) >= 0.001 then
			return a.primary < b.primary;
		end;
		if math.abs(a.secondary - b.secondary) >= 0.001 then
			return a.secondary < b.secondary;
		end;
		if entityMode == "Player/NPC" and a.isNpc ~= b.isNpc then
			return b.isNpc;
		end;
		return tostring(a.ch.Name) < tostring(b.ch.Name);
	end);
	local scan = {};
	local seen = {};
	local scanLimit = math.min(#coarse, 8);
	if #coarse > 8 and entityMode ~= "Player" then
		scanLimit = math.min(#coarse, 12);
	end;
	for i = 1, scanLimit do
		local cand = coarse[i];
		if cand and cand.ch and not seen[cand.ch] then
			seen[cand.ch] = true;
			scan[#scan + 1] = cand;
		end;
	end;
	if entityMode == "Player/NPC" then
		local addPlayer = 0;
		local addNpc = 0;
		for i = 1, #coarse do
			local cand = coarse[i];
			if cand and cand.ch and not seen[cand.ch] then
				if cand.isNpc then
					if addNpc < 8 then
						addNpc += 1;
						seen[cand.ch] = true;
						scan[#scan + 1] = cand;
					end;
				else
					if addPlayer < 8 then
						addPlayer += 1;
						seen[cand.ch] = true;
						scan[#scan + 1] = cand;
					end;
				end;
			end;
			if addPlayer >= 8 and addNpc >= 8 then
				break;
			end;
		end;
	end;
	for i = 1, #scan do
		local cand = scan[i];
		local part = getScanAimPart(cand.ch);
		if part then
			local scr, on = cam:WorldToViewportPoint(part.Position);
			if on then
				local dist = (part.Position - camPos).Magnitude;
				if dist <= maxDistance then
					local sdist = (Vector2.new(scr.X, scr.Y) - mp).Magnitude;
					if modeName ~= "Crosshair" or sdist <= maxR then
						local primary = sdist;
						local secondary = dist;
						if modeName == "Distance" or _G.lockToNearest then
							primary = dist;
							secondary = sdist;
						else
							local hum = getHumanoid(cand.ch);
							if modeName == "Lowest Health" and hum then
								primary = hum.Health;
								secondary = sdist;
							end;
						end;
						local better = false;
						if primary < bestPrimary then
							better = true;
						elseif math.abs(primary - bestPrimary) < 0.001 then
							if secondary < bestSecondary then
								better = true;
							elseif entityMode == "Player/NPC" and near ~= nil and nearIsNpc and (not cand.isNpc) and math.abs(secondary - bestSecondary) < 0.001 then
								better = true;
							end;
						end;
						if better then
							bestPrimary = primary;
							bestSecondary = secondary;
							near = cand.ch;
							nearPart = part;
							nearIsNpc = cand.isNpc;
						end;
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
	local interval = 0.11;
	if _G.wallCheck then
		interval += 0.04;
	end;
	if normalizeAimMode(_G.aimTargetMode) == "Random" then
		interval += 0.03;
	end;
	if normChoice(_G.entMode, OPT.TARGET_ENTITY_OPTIONS, "Player") ~= "Player" then
		interval += 0.04;
	end;
	return math.clamp(interval, 0.09, 0.24);
end;

function VLO.clearTarget()
	VLO.trackedCh = nil;
	VLO.trackedPart = nil;
	lastLockedCharacter = nil;
	lastLockedPart = nil;
	lastTargetName = "none";
end;
function VLO.stop()
	if aimCamTween then
		pcall(function()
			aimCamTween:Cancel();
		end);
		aimCamTween = nil;
	end;
	if uiRefs and uiRefs.clearAimDeathWatch then
		uiRefs.clearAimDeathWatch(VLO.deathWatch);
	end;
	VLO.trackedCh = nil;
	VLO.trackedPart = nil;
	VLO.lastCh = nil;
	VLO.scanGap = 0;
	VLO.partGap = 0;
	VLO.aliveGap = 0;
	if lockCamLoop and lockCamLoop.Connected then
		lockCamLoop:Disconnect();
	end;
	lockCamLoop = nil;
end;
function VLO.acquire(aimMode)
	VLO.ch, VLO.scanPart = findTarget();
	if VLO.ch ~= VLO.lastCh then
		if aimMode == "Random" and VLO.ch then
			bumpRandomAim(VLO.ch);
		end;
		VLO.lastCh = VLO.ch;
	end;
	VLO.trackedCh = VLO.ch;
	if _G.aliveCheck then
		uiRefs.watchAimDeath(VLO.deathWatch, VLO.ch, function()
			VLO.clearTarget();
			VLO.scanGap = math.huge;
			VLO.partGap = math.huge;
			VLO.aliveGap = math.huge;
		end);
	else
		uiRefs.clearAimDeathWatch(VLO.deathWatch);
	end;
	if VLO.ch then
		if aimMode ~= "Random" then
			VLO.prefPart = topAimPart(VLO.ch);
			if isTrackedAimPartUsable(VLO.ch, VLO.prefPart, _G.wallCheck == true) then
				VLO.trackedPart = VLO.prefPart;
			elseif isTrackedAimPartUsable(VLO.ch, lastLockedPart, _G.wallCheck == true) then
				VLO.trackedPart = lastLockedPart;
			else
				VLO.trackedPart = isTrackedAimPartUsable(VLO.ch, VLO.scanPart, _G.wallCheck == true) and VLO.scanPart or VLO.prefPart;
			end;
		else
			VLO.trackedPart = isTrackedAimPartUsable(VLO.ch, VLO.scanPart, _G.wallCheck == true) and VLO.scanPart or topAimPart(VLO.ch);
		end;
		lastLockedPart = VLO.trackedPart;
	else
		VLO.trackedPart = nil;
		lastLockedPart = nil;
	end;
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
	local modeName = normChoice(_G.espRenderMode, OPT.ESP_RENDER_OPTIONS, "Highlight");
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
	local root = getRoot(ch) or getTorso(ch) or getHead(ch);
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
	for _, p in ipairs(getPlrs()) do
		if p ~= plr then
			if _G.teamCheck and (not isEnemy(p)) then
				espDetach(p);
			else
				espAttach(p);
			end;
		end;
	end;
	for p, _ in pairs(espMap) do
		if not plrIdx[p] then
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
		elseif var == "randWtOn" then
			normalizeRandomWeights();
			resetAimCaches(false);
		end;
		if var == "autoSaveConfigs" then
			saveCfg(true);
			return;
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
uiRefs.updateLockUi = function()
	if not topBtn then
		return;
	end;
	topBtn.Text = isLock and "OPEN AIMBOT [LOCK ON]" or "OPEN AIMBOT [LOCK OFF]";
	topBtn.BackgroundColor3 = isLock and UI.ok or UI.bar1;
	topBtn.BackgroundTransparency = isLock and 0.08 or 0.2;
	topBtn.TextStrokeColor3 = Color3.new(0, 0, 0);
	topBtn.TextStrokeTransparency = 0;
	local st = topBtn:FindFirstChildOfClass("UIStroke");
	if st then
		st.Color = isLock and UI.acc2 or UI.stroke2;
		st.Transparency = isLock and 0.08 or 0.25;
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
	topToggleHolder.Size = UDim2.new(0, 196, 0, 30);
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
	topBtn.Text = "OPEN AIMBOT [LOCK OFF]";
	topBtn.Font = Enum.Font.GothamBlack;
	topBtn.TextSize = 12;
	topBtn.TextStrokeColor3 = Color3.new(0, 0, 0);
	topBtn.TextStrokeTransparency = 0;
	topBtn.AutoButtonColor = false;
	topBtn.ZIndex = 20;
	uiRefs.topToggle = topBtn;
	round(topBtn, UDim.new(0.3, 0));
	stroke(topBtn, 1, UI.stroke2, 0.25);
	uiRefs.updateLockUi();
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
	addRowDropdown(pgAim, "aim target", "aimTargetMode", OPT.AIM_TARGET_OPTIONS, "Body part used for camera locking", function(v)
		if normalizeAimMode(v) == "Random" then
			bumpRandomAim();
		end;
	end);
	if not isMobilePlatform() then
		addRowDropdown(pgAim, "target point", "targetPointMode", OPT.TARGET_POINT_OPTIONS, "PC only: use cursor or screen center", function()
			_G.targetPointMode = normChoice(_G.targetPointMode, OPT.TARGET_POINT_OPTIONS, "Cursor");
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
	addRowToggleSlider(pgAim, "smooth aim", "aimTween", "aimSmooth", 0.03, 1, 2, "smooth camera aim");
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
	addRowDropdown(pgTarget, "target priority", "targetPriorityMode", OPT.TARGET_PRIORITY_OPTIONS, "choose how targets are sorted", function(v)
		_G.targetPriorityMode = normChoice(v, OPT.TARGET_PRIORITY_OPTIONS, "Crosshair");
		_G.lockToNearest = _G.targetPriorityMode == "Distance";
		saveCfg();
	end);
	addRowToggle(pgTarget, "sticky target", "stickyTarget", "keep the current target while it stays valid");
	addRowSlider(pgTarget, "max target distance", "targetMaxDistance", 100, 5000, 0, "ignore targets farther than this");
	addRowDropdown(pgTarget, "target mode", "entMode", OPT.TARGET_ENTITY_OPTIONS, "choose whether the aimbot targets players, NPCs, or both", function(v)
		_G.entMode = normChoice(v, OPT.TARGET_ENTITY_OPTIONS, "Player");
		resetAimCaches(true);
	end);
	addSection(pgTarget, "random target weights");
	addRowToggle(pgTarget, "use weighted random", "randWtOn", "use the sliders below when aim target is set to Random");
	addRowSlider(pgTarget, "random head %", "randomWeightHead", 0, 100, 0, "chance weight for Head", function()
		normalizeRandomWeights();
		resetAimCaches(false);
	end);
	addRowSlider(pgTarget, "random root %", "randomWeightRoot", 0, 100, 0, "chance weight for HumanoidRootPart", function()
		normalizeRandomWeights();
		resetAimCaches(false);
	end);
	addRowSlider(pgTarget, "random upper torso %", "randomWeightUpperTorso", 0, 100, 0, "chance weight for UpperTorso", function()
		normalizeRandomWeights();
		resetAimCaches(false);
	end);
	addRowSlider(pgTarget, "random lower torso %", "randomWeightLowerTorso", 0, 100, 0, "chance weight for LowerTorso", function()
		normalizeRandomWeights();
		resetAimCaches(false);
	end);
	addRowSlider(pgTarget, "random torso %", "randomWeightTorso", 0, 100, 0, "chance weight for Torso fallback rigs", function()
		normalizeRandomWeights();
		resetAimCaches(false);
	end);
	addRowSlider(pgTarget, "random other %", "randomWeightOther", 0, 100, 0, "chance weight for other visible body parts", function()
		normalizeRandomWeights();
		resetAimCaches(false);
	end);
	addSection(pgESP, "render");
	addRowDropdown(pgESP, "esp mode", "espRenderMode", OPT.ESP_RENDER_OPTIONS, "swap between highlight and boxhandleadornment", function(v)
		_G.espRenderMode = normChoice(v, OPT.ESP_RENDER_OPTIONS, "Highlight");
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
	addRowDropdown(pgCustom, "accent theme", "uiTheme", OPT.THEME_OPTIONS, "changes accent colors", function(v)
		applyTheme(v);
		applyCustomUI();
	end);
	addRowToggle(pgCustom, "animated ui", "uiAnimations", "disable if you want instant UI changes");
	addRowSlider(pgCustom, "animation speed", "uiAnimSpeed", 0.35, 2.5, 2, "higher = faster tweens", function()
		applyCustomUI();
	end);
	addSection(pgCustom, "notifications");
	addRowDropdown(pgCustom, "toast position", "toastPosition", OPT.TOAST_POS_OPTIONS, "where notifications appear", function()
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
	local vTargetMode = addRow(pgStatus, "aim target", "");
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
				rebindStrongInputs();
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
		capMode = false;
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
				rebindStrongInputs();
				saveCfg();
			end;
			stopCap();
		end);
	end);
	local clrCon = bindClick(clrKey, function()
		keysSet = {};
		_G.toggleKeys = {};
		rebuildChips();
		rebindStrongInputs();
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
		capMode = true;
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
			rebindStrongInputs();
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
		rebindStrongInputs();
		saveCfg();
		toast("lock key reset to MouseButton2");
	end);
	addSection(pgSettings, "configs");
	addRowToggle(pgSettings, "auto save configs", "autoSaveConfigs", "save changes instantly or only when you press save");
	local function refreshLoadedConfigRuntime()
		_G.selectedConfigName = cleanCfgName(_G.selectedConfigName);
		_G.targetPointMode = normChoice(_G.targetPointMode, OPT.TARGET_POINT_OPTIONS, "Cursor");
		_G.pendingBindAction = normChoice(_G.pendingBindAction, OPT.BIND_ACTION_OPTIONS, "Aimbot");
		_G.pendingMobileAction = normChoice(_G.pendingMobileAction, OPT.MOBILE_ACTION_OPTIONS, "Aimbot");
		_G.targetPriorityMode = normChoice(_G.targetPriorityMode, OPT.TARGET_PRIORITY_OPTIONS, "Crosshair");
		_G.entMode = normChoice(_G.entMode, OPT.TARGET_ENTITY_OPTIONS, "Player");
		_G.randWtOn = _G.randWtOn == true;
		_G.espRenderMode = normChoice(_G.espRenderMode, OPT.ESP_RENDER_OPTIONS, "Highlight");
		_G.mobileHelperButtons = normalizeActionList(_G.mobileHelperButtons, OPT.MOBILE_ACTION_OPTIONS, OPT.MOBILE_HELPER_DEFAULTS);
		normalizeRandomWeights();
		applyTheme(_G.uiTheme);
		applyToastPos();
		applyCustomUI();
		updateFOVCircle();
		refreshESPTransparency();
		updateESP();
		rebindStrongInputs();
		rebuildMobileHelper();
		refreshMobileUI();
		if _G.fovEnabled and cam then
			cam.FieldOfView = _G.fovValue;
		end;
		if lockBtn and lockBtn.Parent then
			lockBtn.Text = tostring(_G.lockKey or "MouseButton2");
		end;
	end;
	local cfgNameRow = newUi("Frame", pgSettings);
	cfgNameRow.BackgroundTransparency = 1;
	cfgNameRow.Size = UDim2.new(1, -20, 0, 48);
	local cfgNameLbl = newUi("TextLabel", cfgNameRow);
	cfgNameLbl.BackgroundTransparency = 1;
	cfgNameLbl.Size = UDim2.new(0.42, 0, 0, 20);
	cfgNameLbl.Position = UDim2.new(0, 0, 0, 2);
	cfgNameLbl.Font = Enum.Font.GothamSemibold;
	cfgNameLbl.TextSize = 14;
	cfgNameLbl.TextXAlignment = Enum.TextXAlignment.Left;
	cfgNameLbl.TextColor3 = UI.text;
	cfgNameLbl.Text = "config name";
	local cfgNameHint = newUi("TextLabel", cfgNameRow);
	cfgNameHint.BackgroundTransparency = 1;
	cfgNameHint.Size = UDim2.new(0.42, 0, 0, 18);
	cfgNameHint.Position = UDim2.new(0, 0, 0, 24);
	cfgNameHint.Font = Enum.Font.Gotham;
	cfgNameHint.TextSize = 12;
	cfgNameHint.TextXAlignment = Enum.TextXAlignment.Left;
	cfgNameHint.TextColor3 = UI.sub;
	cfgNameHint.Text = "type a name to save or select";
	local cfgNameBox = newUi("TextBox", cfgNameRow);
	cfgNameBox.Size = UDim2.new(0.54, 0, 0, 34);
	cfgNameBox.Position = UDim2.new(0.46, 0, 0.5, -17);
	cfgNameBox.BackgroundColor3 = UI.bar2;
	cfgNameBox.BorderSizePixel = 0;
	cfgNameBox.TextColor3 = UI.text;
	cfgNameBox.PlaceholderColor3 = UI.sub;
	cfgNameBox.PlaceholderText = "default";
	cfgNameBox.Text = cleanCfgName(_G.selectedConfigName);
	cfgNameBox.ClearTextOnFocus = false;
	cfgNameBox.Font = Enum.Font.GothamSemibold;
	cfgNameBox.TextSize = 13;
	cfgNameBox.TextXAlignment = Enum.TextXAlignment.Left;
	round(cfgNameBox, UDim.new(0, 12));
	stroke(cfgNameBox, 1, UI.stroke2, 0.2);
	local cfgNamePad = newUi("UIPadding", cfgNameBox);
	cfgNamePad.PaddingLeft = UDim.new(0, 10);
	cfgNamePad.PaddingRight = UDim.new(0, 10);
	local cfgPickRow = newUi("Frame", pgSettings);
	cfgPickRow.BackgroundTransparency = 1;
	cfgPickRow.Size = UDim2.new(1, -20, 0, 44);
	local cfgPickLbl = newUi("TextLabel", cfgPickRow);
	cfgPickLbl.BackgroundTransparency = 1;
	cfgPickLbl.Size = UDim2.new(0.42, 0, 0, 20);
	cfgPickLbl.Position = UDim2.new(0, 0, 0, 12);
	cfgPickLbl.Font = Enum.Font.GothamSemibold;
	cfgPickLbl.TextSize = 14;
	cfgPickLbl.TextXAlignment = Enum.TextXAlignment.Left;
	cfgPickLbl.TextColor3 = UI.text;
	cfgPickLbl.Text = "saved configs";
	local cfgPickBtn = newUi("TextButton", cfgPickRow);
	cfgPickBtn.Size = UDim2.new(0.54, 0, 0, 34);
	cfgPickBtn.Position = UDim2.new(0.46, 0, 0.5, -17);
	cfgPickBtn.BackgroundColor3 = UI.bar2;
	cfgPickBtn.BorderSizePixel = 0;
	cfgPickBtn.Text = "";
	cfgPickBtn.AutoButtonColor = false;
	round(cfgPickBtn, UDim.new(0, 12));
	stroke(cfgPickBtn, 1, UI.stroke2, 0.2);
	local cfgPickTxt = newUi("TextLabel", cfgPickBtn);
	cfgPickTxt.BackgroundTransparency = 1;
	cfgPickTxt.Size = UDim2.new(1, -42, 1, 0);
	cfgPickTxt.Position = UDim2.new(0, 12, 0, 0);
	cfgPickTxt.Font = Enum.Font.GothamBold;
	cfgPickTxt.TextSize = 13;
	cfgPickTxt.TextXAlignment = Enum.TextXAlignment.Left;
	cfgPickTxt.TextColor3 = UI.text;
	local cfgPickArrow = newUi("TextLabel", cfgPickBtn);
	cfgPickArrow.BackgroundTransparency = 1;
	cfgPickArrow.Size = UDim2.new(0, 24, 1, 0);
	cfgPickArrow.Position = UDim2.new(1, -28, 0, 0);
	cfgPickArrow.Font = Enum.Font.GothamBlack;
	cfgPickArrow.TextSize = 14;
	cfgPickArrow.TextColor3 = UI.acc2;
	cfgPickArrow.Text = "v";
	local cfgPickList = newUi("Frame", cfgPickRow);
	cfgPickList.Visible = false;
	cfgPickList.ClipsDescendants = true;
	cfgPickList.Size = UDim2.new(0.54, 0, 0, 0);
	cfgPickList.Position = UDim2.new(0.46, 0, 1, 4);
	cfgPickList.BackgroundColor3 = UI.bar1;
	cfgPickList.BorderSizePixel = 0;
	cfgPickList.ZIndex = 40;
	round(cfgPickList, UDim.new(0, 14));
	stroke(cfgPickList, 1, UI.acc2, 0.2);
	local cfgPickPad = newUi("UIPadding", cfgPickList);
	cfgPickPad.PaddingTop = UDim.new(0, 6);
	cfgPickPad.PaddingBottom = UDim.new(0, 6);
	cfgPickPad.PaddingLeft = UDim.new(0, 6);
	cfgPickPad.PaddingRight = UDim.new(0, 6);
	local cfgPickLay = newUi("UIListLayout", cfgPickList);
	cfgPickLay.Padding = UDim.new(0, 5);
	cfgPickLay.SortOrder = Enum.SortOrder.LayoutOrder;
	local configNames = getConfigNames();
	local function syncConfigNameBox()
		local picked = cleanCfgName(cfgNameBox.Text);
		cfgNameBox.Text = picked;
		_G.selectedConfigName = picked;
		saveMeta();
	end;
	local function refreshConfigPicker()
		configNames = getConfigNames();
		cfgPickTxt.Text = cleanCfgName(_G.selectedConfigName);
		for _, c in ipairs(cfgPickList:GetChildren()) do
			if c:IsA("TextButton") then
				c:Destroy();
			end;
		end;
		for i, name in ipairs(configNames) do
			local opt = newUi("TextButton", cfgPickList);
			opt.LayoutOrder = i;
			opt.Size = UDim2.new(1, 0, 0, _G.uiCompact and 29 or 33);
			opt.BackgroundColor3 = cleanCfgName(_G.selectedConfigName) == name and UI.tabActive or UI.bar2;
			opt.BorderSizePixel = 0;
			opt.AutoButtonColor = false;
			opt.Text = name;
			opt.Font = Enum.Font.GothamSemibold;
			opt.TextSize = 13;
			opt.TextColor3 = UI.text;
			opt.TextXAlignment = Enum.TextXAlignment.Left;
			opt.ZIndex = 41;
			round(opt, UDim.new(0, 10));
			local pad = newUi("UIPadding", opt);
			pad.PaddingLeft = UDim.new(0, 10);
			pad.PaddingRight = UDim.new(0, 10);
			bindClick(opt, function()
				_G.selectedConfigName = name;
				cfgNameBox.Text = name;
				saveMeta();
				refreshConfigPicker();
				cfgPickList.Visible = false;
				cfgPickList.Size = UDim2.new(0.54, 0, 0, 0);
				cfgPickArrow.Text = "v";
			end);
		end;
	end;
	refreshConfigPicker();
	cfgNameBox.FocusLost:Connect(function()
		syncConfigNameBox();
		refreshConfigPicker();
	end);
	bindClick(cfgPickBtn, function()
		if cfgPickList.Visible then
			cfgPickList.Visible = false;
			cfgPickList.Size = UDim2.new(0.54, 0, 0, 0);
			cfgPickArrow.Text = "v";
			return;
		end;
		refreshConfigPicker();
		cfgPickList.Visible = true;
		cfgPickArrow.Text = "^";
		cfgPickList.Size = UDim2.new(0.54, 0, 0, (#configNames * ((_G.uiCompact and 29 or 33) + 5)) + 12);
	end);
	local cfgBtnRow = newUi("Frame", pgSettings);
	cfgBtnRow.BackgroundTransparency = 1;
	cfgBtnRow.Size = UDim2.new(1, -20, 0, 30);
	local cfgBtnLay = newUi("UIListLayout", cfgBtnRow);
	cfgBtnLay.FillDirection = Enum.FillDirection.Horizontal;
	cfgBtnLay.Padding = UDim.new(0, 8);
	cfgBtnLay.SortOrder = Enum.SortOrder.LayoutOrder;
	local saveCfgBtn = newUi("TextButton", cfgBtnRow);
	saveCfgBtn.Text = "save config";
	saveCfgBtn.Font = Enum.Font.GothamSemibold;
	saveCfgBtn.TextSize = 13;
	saveCfgBtn.TextColor3 = UI.text;
	saveCfgBtn.AutoButtonColor = false;
	saveCfgBtn.BackgroundColor3 = UI.ok;
	saveCfgBtn.Size = UDim2.new(0, 106, 0, 26);
	round(saveCfgBtn, UDim.new(0.2, 0));
	stroke(saveCfgBtn, 1, UI.stroke2, 0.15);
	local loadCfgBtn = newUi("TextButton", cfgBtnRow);
	loadCfgBtn.Text = "load config";
	loadCfgBtn.Font = Enum.Font.GothamSemibold;
	loadCfgBtn.TextSize = 13;
	loadCfgBtn.TextColor3 = UI.text;
	loadCfgBtn.AutoButtonColor = false;
	loadCfgBtn.BackgroundColor3 = UI.bar2;
	loadCfgBtn.Size = UDim2.new(0, 106, 0, 26);
	round(loadCfgBtn, UDim.new(0.2, 0));
	stroke(loadCfgBtn, 1, UI.stroke2, 0.25);
	local delCfgBtn = newUi("TextButton", cfgBtnRow);
	delCfgBtn.Text = "delete config";
	delCfgBtn.Font = Enum.Font.GothamSemibold;
	delCfgBtn.TextSize = 13;
	delCfgBtn.TextColor3 = UI.text;
	delCfgBtn.AutoButtonColor = false;
	delCfgBtn.BackgroundColor3 = UI.danger;
	delCfgBtn.Size = UDim2.new(0, 112, 0, 26);
	round(delCfgBtn, UDim.new(0.2, 0));
	stroke(delCfgBtn, 1, UI.stroke2, 0.15);
	bindClick(saveCfgBtn, function()
		syncConfigNameBox();
		saveCfg(true, _G.selectedConfigName);
		refreshConfigPicker();
		toast("config saved");
	end);
	bindClick(loadCfgBtn, function()
		syncConfigNameBox();
		if not loadNameCfg(_G.selectedConfigName) then
			toast("config not found");
			return;
		end;
		cfgNameBox.Text = cleanCfgName(_G.selectedConfigName);
		refreshLoadedConfigRuntime();
		refreshConfigPicker();
		toast("config loaded");
	end);
	bindClick(delCfgBtn, function()
		syncConfigNameBox();
		local path = getCfgPath(_G.selectedConfigName);
		if delfile and isfile and isfile(path) then
			pcall(delfile, path);
		end;
		resetCfg();
		_G.selectedConfigName = "default";
		cfgNameBox.Text = "default";
		saveMeta();
		refreshLoadedConfigRuntime();
		refreshConfigPicker();
		toast("config reset to default");
	end);
	addSection(pgSettings, "option binds");
	_G.pendingBindAction = normChoice(_G.pendingBindAction, OPT.BIND_ACTION_OPTIONS, "Aimbot");
	addRowDropdown(pgSettings, "bind option", "pendingBindAction", OPT.BIND_ACTION_OPTIONS, "pick what the next key should toggle");
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
				rebindStrongInputs();
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
		local action = normChoice(_G.pendingBindAction, OPT.BIND_ACTION_OPTIONS, "Aimbot");
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
			rebindStrongInputs();
			saveCfg();
			stopCap();
		end);
	end);
	local clrBindCon = bindClick(clrBind, function()
		_G.optionBinds = {};
		rebuildOptionBindRows();
		rebindStrongInputs();
		saveCfg();
	end);
	if isMobilePlatform() then
		addSection(pgSettings, "mobile helper");
		addRowToggle(pgSettings, "mobile center aim", "mobileCenterAim", "touch devices use the exact screen center instead of cursor");
		addRowToggle(pgSettings, "mobile buttons", "mobileButtons", "floating lock and menu buttons for touch devices");
		addRowToggle(pgSettings, "center dot visible", "centerDotVisible", "show or hide the mobile center marker");
		addRowDropdown(pgSettings, "helper button", "pendingMobileAction", OPT.MOBILE_ACTION_OPTIONS, "pick what the add helper button action inserts");
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
			local picked = normChoice(_G.pendingMobileAction, OPT.MOBILE_ACTION_OPTIONS, "Aimbot");
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
			_G.mobileHelperButtons = normalizeActionList(nil, OPT.MOBILE_ACTION_OPTIONS, OPT.MOBILE_HELPER_DEFAULTS);
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
		local num = Players.NumPlayers or getPlrCount();
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
		local actions = normalizeActionList(_G.mobileHelperButtons, OPT.MOBILE_ACTION_OPTIONS, OPT.MOBILE_HELPER_DEFAULTS);
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
				if uiMin then
					frame.Position = UDim2.new(0.5, 0, -0.65, 0);
					frame.BackgroundTransparency = math.clamp((_G.uiWindowAlpha or 0.08) + 0.08, 0, 0.6);
					showTopBtn(true);
				else
					clampFrameToScreen(frame);
				end;
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
				if uiMin then
					frame.Position = UDim2.new(0.5, 0, -0.65, 0);
					frame.BackgroundTransparency = math.clamp((_G.uiWindowAlpha or 0.08) + 0.08, 0, 0.6);
					showTopBtn(true);
				else
					clampFrameToScreen(frame);
				end;
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
		uiRefs.updateLockUi();
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
		VLO.stop();
		clearFOVHooks();
		for p, _ in pairs(espMap) do
			espDetach(p);
		end;
		espMap = {};
		unbindStrongInputs();
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
local function getBindInputEnum(name)
	local raw = tostring(name or "");
	if raw == "" then
		return nil;
	end;
	if raw == "MouseButton1" then
		return Enum.UserInputType.MouseButton1;
	end;
	if raw == "MouseButton2" then
		return Enum.UserInputType.MouseButton2;
	end;
	if raw == "MouseButton3" then
		return Enum.UserInputType.MouseButton3;
	end;
	local okKey, keyCode = pcall(function()
		return Enum.KeyCode[raw];
	end);
	if okKey and keyCode and keyCode ~= Enum.KeyCode.Unknown then
		return keyCode;
	end;
	local okInput, inputType = pcall(function()
		return Enum.UserInputType[raw];
	end);
	if okInput and inputType and (inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.MouseButton2 or inputType == Enum.UserInputType.MouseButton3) then
		return inputType;
	end;
	return nil;
end;
local function collectHotkeyInputs()
	local out = {};
	local seen = {};
	local function push(name)
		local enumItem = getBindInputEnum(name);
		if enumItem and (not seen[enumItem]) then
			seen[enumItem] = true;
			out[#out + 1] = enumItem;
		end;
	end;
	for _, name in ipairs(type(_G.toggleKeys) == "table" and _G.toggleKeys or {}) do
		push(name);
	end;
	for keyName, _ in pairs(type(_G.optionBinds) == "table" and _G.optionBinds or {}) do
		push(keyName);
	end;
	return out;
end;
unbindStrongInputs = function()
	pcall(function()
		CAS:UnbindAction("VyperiaBotLock");
	end);
	pcall(function()
		CAS:UnbindAction("VyperiaBotHotkeys");
	end);
	if uiRefs.hotkeyRawCon and uiRefs.hotkeyRawCon.Connected then
		uiRefs.hotkeyRawCon:Disconnect();
	end;
	uiRefs.hotkeyRawCon = nil;
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
		uiRefs.updateLockUi();
		if isLock then
			if normalizeAimMode(_G.aimTargetMode) == "Random" then
				bumpRandomAim();
			end;
			if _G.fovEnabled and cam then
				cam.FieldOfView = _G.fovValue;
			end;
			lockCamera();
		else
			VLO.stop();
		end;
	else
		isLock = true;
		uiRefs.updateLockUi();
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
	uiRefs.updateLockUi();
	VLO.stop();
end;
handleOptionBind = function(action)
	local var = OPT.BIND_ACTION_VARS[action];
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
	rebindStrongInputs();
end;
rebindStrongInputs = function()
	unbindStrongInputs();
	local lockInput = getBindInputEnum(_G.lockKey or "MouseButton2");
	if lockInput then
		local ok = pcall(function()
			CAS:BindActionAtPriority("VyperiaBotLock", function(_, inputState)
				if capMode or UIS:GetFocusedTextBox() then
					return Enum.ContextActionResult.Pass;
				end;
				if inputState == Enum.UserInputState.Begin then
					if not _G.isEnabled then
						return Enum.ContextActionResult.Pass;
					end;
					startLockAction();
					return Enum.ContextActionResult.Sink;
				end;
				if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
					if not _G.isEnabled and (not isLock) then
						return Enum.ContextActionResult.Pass;
					end;
					endLockAction();
					return Enum.ContextActionResult.Sink;
				end;
				return Enum.ContextActionResult.Pass;
			end, false, Enum.ContextActionPriority.High.Value + 1000, lockInput);
		end);
		if not ok then
			pcall(function()
				CAS:BindAction("VyperiaBotLock", function(_, inputState)
					if capMode or UIS:GetFocusedTextBox() then
						return Enum.ContextActionResult.Pass;
					end;
					if inputState == Enum.UserInputState.Begin then
						if not _G.isEnabled then
							return Enum.ContextActionResult.Pass;
						end;
						startLockAction();
						return Enum.ContextActionResult.Sink;
					end;
					if inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
						if not _G.isEnabled and (not isLock) then
							return Enum.ContextActionResult.Pass;
						end;
						endLockAction();
						return Enum.ContextActionResult.Sink;
					end;
					return Enum.ContextActionResult.Pass;
				end, false, lockInput);
			end);
		end;
	end;
	local hotkeyInputs = collectHotkeyInputs();
	if #hotkeyInputs > 0 then
		uiRefs.runHotkey = function(name)
			local now = os.clock();
			if uiRefs.hotkeyName == name and (now - (uiRefs.hotkeyAt or 0)) < 0.12 then
				return false;
			end;
			uiRefs.hotkeyName = name;
			uiRefs.hotkeyAt = now;
			local bindsMap = type(_G.optionBinds) == "table" and _G.optionBinds or {};
			local action = bindsMap[name];
			if action and handleOptionBind(action) then
				return true;
			end;
			if table.find(_G.toggleKeys, name) then
				if frm and frm.Parent then
					if uiMin then
						openUI();
					else
						closeUI();
					end;
				end;
				return true;
			end;
			return false;
		end;
		uiRefs.hotkeyAct = function(_, inputState, inputObject)
			if inputState ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Pass;
			end;
			if capMode or UIS:GetFocusedTextBox() or time() < capCooldownUntil then
				return Enum.ContextActionResult.Pass;
			end;
			local keyCode = inputObject and inputObject.KeyCode or Enum.KeyCode.Unknown;
			local name = keyCode ~= Enum.KeyCode.Unknown and keyCode.Name or (inputObject and inputObject.UserInputType and inputObject.UserInputType.Name or "");
			if name == "" then
				return Enum.ContextActionResult.Pass;
			end;
			if uiRefs.runHotkey(name) then
				return Enum.ContextActionResult.Sink;
			end;
			return Enum.ContextActionResult.Pass;
		end;
		local ok = pcall(function()
			CAS:BindActionAtPriority("VyperiaBotHotkeys", uiRefs.hotkeyAct, false, Enum.ContextActionPriority.High.Value + 1000, unpack(hotkeyInputs));
		end);
		if not ok then
			pcall(function()
				CAS:BindAction("VyperiaBotHotkeys", uiRefs.hotkeyAct, false, unpack(hotkeyInputs));
			end);
		end;
		uiRefs.hotkeyRawCon = UIS.InputBegan:Connect(function(inputObject, _)
			if capMode or UIS:GetFocusedTextBox() or time() < capCooldownUntil then
				return;
			end;
			local keyCode = inputObject and inputObject.KeyCode or Enum.KeyCode.Unknown;
			local name = keyCode ~= Enum.KeyCode.Unknown and keyCode.Name or (inputObject and inputObject.UserInputType and inputObject.UserInputType.Name or "");
			if name == "" then
				return;
			end;
			uiRefs.runHotkey(name);
		end);
	end;
end;
function lockCamera()
	if lockCamLoop and lockCamLoop.Connected then
		return;
	end;
	VLO.seq += 1;
	VLO.trackedCh = nil;
	VLO.trackedPart = nil;
	VLO.lastCh = nil;
	VLO.scanGap = math.huge;
	VLO.partGap = math.huge;
	VLO.aliveGap = math.huge;
	uiRefs.clearAimDeathWatch(VLO.deathWatch);
	lockCamLoop = RunService.RenderStepped:Connect(function(dt)
		VLO.dt = dt or 0.016;
		if VLO.dt <= 0 then
			VLO.dt = 0.016;
		end;
		if not isLock or not _G.isEnabled then
			VLO.stop();
			return;
		end;
		VLO.scanGap += VLO.dt;
		VLO.partGap += VLO.dt;
		VLO.aliveGap += VLO.dt;
		VLO.aimMode = normalizeAimMode(_G.aimTargetMode);
		VLO.refreshWait = getLockRefreshInterval();
		VLO.needScan = false;
		if not VLO.trackedCh then
			VLO.needScan = VLO.scanGap >= VLO.refreshWait;
		elseif not _G.stickyTarget and VLO.scanGap >= math.max(VLO.refreshWait, 0.3) then
			VLO.needScan = true;
		end;
		if VLO.trackedCh and VLO.aliveGap >= 0.07 then
			VLO.aliveGap = 0;
			if _G.aliveCheck and not uiRefs.liveHum(VLO.trackedCh) then
				uiRefs.clearAimDeathWatch(VLO.deathWatch);
				VLO.clearTarget();
				VLO.needScan = VLO.scanGap >= VLO.refreshWait;
			elseif not isTrackedAimPartUsable(VLO.trackedCh, VLO.trackedPart, false) then
				VLO.trackedPart = nil;
				lastLockedPart = nil;
				VLO.needScan = VLO.scanGap >= VLO.refreshWait;
			end;
		end;
		if VLO.needScan then
			VLO.scanGap = 0;
			VLO.partGap = 0;
			VLO.acquire(VLO.aimMode);
		elseif VLO.trackedCh and VLO.partGap >= 0.2 then
			VLO.partGap = 0;
			if VLO.aimMode ~= "Random" then
				VLO.prefPart = topAimPart(VLO.trackedCh);
				if isTrackedAimPartUsable(VLO.trackedCh, VLO.prefPart, _G.wallCheck == true) then
					VLO.trackedPart = VLO.prefPart;
					lastLockedPart = VLO.trackedPart;
				end;
			elseif not isTrackedAimPartUsable(VLO.trackedCh, VLO.trackedPart, _G.wallCheck == true) then
				VLO.trackedPart = topAimPart(VLO.trackedCh) or VLO.trackedPart;
				lastLockedPart = VLO.trackedPart;
			end;
		end;
		if VLO.trackedCh and VLO.trackedPart and _G.aliveCheck and VLO.aliveGap == 0 and not uiRefs.hardAlive(VLO.trackedCh, VLO.trackedPart) then
			uiRefs.clearAimDeathWatch(VLO.deathWatch);
			VLO.clearTarget();
			VLO.scanGap = math.huge;
			VLO.partGap = math.huge;
			VLO.aliveGap = math.huge;
		end;
		if VLO.trackedCh and VLO.trackedPart then
			VLO.tgtPos = getAimPos(VLO.trackedPart);
			VLO.cf = CFrame.new(cam.CFrame.Position, VLO.tgtPos);
			if aimCamTween then
				pcall(function()
					aimCamTween:Cancel();
				end);
				aimCamTween = nil;
			end;
			if _G.aimTween == true then
				VLO.alpha = math.clamp(getAimTweenDuration(), 0.01, 1);
				cam.CFrame = cam.CFrame:Lerp(VLO.cf, VLO.alpha);
			else
				cam.CFrame = VLO.cf;
			end;
		end;
	end);
end;
uiRefs.setupPlayerMonitoring = function()
	local function hook(pp)
		trackPlayer(pp);
		setTrackedCharacter(pp, pp.Character);
		local ca = pp.CharacterAdded:Connect(function(char)
			setTrackedCharacter(pp, char);
			resetAimCaches(false);
			task.wait(0.1);
			if _G.espEnabled then
				espAttach(pp);
			end;
		end);
		table.insert(conns, ca);
		local cr = pp.CharacterRemoving:Connect(function(ch)
			if ch then
				plrModelMark[ch] = pp;
				local cache = _G.__vyperiaNpcTargetCache;
				if type(cache) == "table" and type(cache.remove) == "function" then
					cache.remove(ch);
				end;
			end;
			if plrChars[pp] == ch then
				setTrackedCharacter(pp, nil);
			end;
			invalidateTargetState(ch);
		end);
		table.insert(conns, cr);
	end;
	rebuildPlrs();
	for _, pp in ipairs(getPlrs()) do
		if pp ~= plr then
			hook(pp);
		end;
	end;
	local a = Players.PlayerAdded:Connect(function(pp)
		trackPlayer(pp);
		resetAimCaches(false);
		hook(pp);
		if _G.espEnabled then
			task.defer(function()
				espAttach(pp);
			end);
		end;
	end);
	table.insert(conns, a);
	local r = Players.PlayerRemoving:Connect(function(pp)
		untrackPlayer(pp);
		if pp.Character and lastLockedCharacter == pp.Character then
			invalidateTargetState(pp.Character);
		else
			resetAimCaches(false);
		end;
		espDetach(pp);
	end);
	table.insert(conns, r);
	local c = plr.CharacterAdded:Connect(function(char)
		setTrackedCharacter(plr, char);
		invalidateTargetState();
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
uiRefs.setupPlayerMonitoring();
if _G.espEnabled then
	updateESP();
end;
toast("Aimbot loaded");
saveCfg();
uiRefs.chkMode = function()
	local newMode;
	if getPlrCount() > 0 and Players.LocalPlayer.Team == nil then
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
uiRefs.teamPulse = 0;
table.insert(conns, RunService.Heartbeat:Connect(function(dt)
	uiRefs.teamPulse += dt or 0.016;
	if uiRefs.teamPulse < 0.5 then
		return;
	end;
	uiRefs.teamPulse = 0;
	uiRefs.chkMode();
end));
_G.__vyperiaAimbotCleanup = function()
	npc.dispose(false);
	for _, c in pairs(conns) do
		disconnectConn(c);
	end;
	table.clear(conns);
	VLO.stop();
	for p, _ in pairs(espMap) do
		espDetach(p);
	end;
	unbindStrongInputs();
	clearFOVHooks();
	if gui and gui.Parent then
		gui:Destroy();
	end;
	gui = nil;
	frm = nil;
	_G.__vyperiaAimbotCleanup = nil;
end;
return _G.__vyperiaAimbotCleanup;
