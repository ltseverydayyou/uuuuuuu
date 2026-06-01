local __lt = (function()
	local g = (getgenv and getgenv()) or _G or {}
	local sh = rawget(_G, "shared")
	local host = type(sh) == "table" and sh or (type(g) == "table" and g or nil)

	local function fb()
		return {
			cs = function(n, cr)
				local ok, svc = pcall(game.GetService, game, n)
				if not ok or not svc then
					return nil
				end
				if type(cr) == "function" then
					local ok2, v = pcall(cr, svc)
					if ok2 and v then
						return v
					end
				end
				return svc
			end,
			cm = function(s, m, ...)
				local obj = s
				if type(s) == "string" then
					local ok, svc = pcall(game.GetService, game, s)
					if not ok then
						return nil
					end
					obj = svc
				end
				if typeof(obj) ~= "Instance" and type(obj) ~= "table" then
					return nil
				end
				local fn = obj[m]
				if type(fn) ~= "function" then
					return nil
				end
				local ok, res = pcall(fn, obj, ...)
				if ok then
					return res
				end
				return nil
			end,
		}
	end

	if host then
		local c = rawget(host, "__lt_service_resolver")
		if type(c) == "table" then
			return c
		end
	end

	local out
	local ok = pcall(function()
		local ld = loadstring or load
		if type(ld) ~= "function" then
			error("loader unavailable")
		end
		local src = game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau")
		local fn = ld(src, "@ServiceResolver.luau")
		if type(fn) ~= "function" then
			error("compile failed")
		end
		local t = fn()
		if type(t) ~= "table" then
			error("resolver load failed")
		end
		out = t
	end)

	if not ok or type(out) ~= "table" then
		out = fb()
	end

	if host then
		host.__lt_service_resolver = out
	end

	return out
end)()
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
local g = (getgenv and getgenv()) or _G or {}
local sh = rawget(_G, "shared")
local host = type(sh) == "table" and sh or (type(g) == "table" and g or nil)

if host and type(host.__lt_af_ctx) == "table" then
	local old = host.__lt_af_ctx
	if type(old.stop) == "function" then
		pcall(old.stop)
	elseif type(old.con) == "table" then
		for _, c in old.con do
			if c and type(c.Disconnect) == "function" then
				pcall(function()
					c:Disconnect()
				end)
			end
		end
	end
	old.live = false
	host.__lt_af_ctx = nil
end

local ctx = {
	live = true,
	con = {},
	threads = {},
}

if host then
	host.__lt_af_ctx = ctx
end

local __NAOriginalGetHui = gethui;
ctx.gethui = function()
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
ctx.__NAProtectUI = function(gui, options)
	if __NAUIProtector and type(__NAUIProtector.protectUI) == "function" then
		local ok, protected = pcall(__NAUIProtector.protectUI, gui, options);
		if ok and protected then
			return protected;
		end;
	end;
	return nil;
end;

ctx.bind = function(c)
	if c then
		ctx.con[#ctx.con + 1] = c
	end
	return c
end

ctx.spawnLoop = function(fn)
	local th = task.spawn(function()
		local ok, err = xpcall(fn, debug.traceback)
		if not ok then
			warn(err)
		end
	end)
	ctx.threads[#ctx.threads + 1] = th
	return th
end

ctx.cut = function(c)
	if c then
		pcall(function()
			c:Disconnect()
		end)
	end
end

ctx.gt = function(n)
	local ok, svc = pcall(function()
		return __lt.cs(n, cloneref)
	end)
	if ok and svc then
		return svc
	end
	local ok2, svc2 = pcall(game.GetService, game, n)
	if ok2 then
		if type(cloneref) == "function" then
			local ok3, v = pcall(cloneref, svc2)
			if ok3 and v then
				return v
			end
		end
		return svc2
	end
	return nil
end

local Plr = ctx.gt("Players")
local Wsp = ctx.gt("Workspace")
local Rsp = ctx.gt("ReplicatedStorage")
local Run = ctx.gt("RunService")
local Uis = ctx.gt("UserInputService")
local Sgui = ctx.gt("StarterGui")
local Guis = ctx.gt("GuiService")
local Cgui = ctx.gt("CoreGui")
local LP = Plr and Plr.LocalPlayer or nil
local MP = Wsp and (Wsp:FindFirstChild("Multiplayer") or Wsp:WaitForChild("Multiplayer", 10)) or nil

local TPD = 0.05
local BTD = 0.05
local SCI = 0.025
local VDY = -50
local EXP = Vector3.new(50, -1, 50)
local JMP = Vector3.new(0, 100, 0)
local PSZ = Vector3.new(24, 2, 24)
local ESY = 5
local LFG = Vector3.new(0, 0, 100)
local RRP = 5
local RRG = 0.3
local EXM = 50
local FGM = 2
local LHW = 8
local PCD = 0.03
local RFD = { 0, 0.25, 0.75, 1.5, 3, 5 }
local FDM = 160
local VLM = 20
local RCH = 12
local LDB = 6
local LDI = 0.1
local BSI = 0.035
local ASI = 0.035
local PLI = 0.25
local PSI = 0.1
local PMW = 0.03
local FMI = 0.1
local RSI = 1
local SRI = 0.75
local DRI = 6
local RBI = 3
local SFT = 20
local SFI = 0.35
local CHI = 1.5

local on = false
local cur = nil
local tok = 0
local aVc
local nCc
local nCd1
local nCd2
local chC
local gui
local btn
local panel
local optBtn
local optionsFrame
local auraBtn
local distModeBtn
local distBtn
local distLabel
local distRow
local bonusBtn
local chBtn
local plt
local cTab = {}
local locBtns = {}
local pressTimes = setmetatable({}, { __mode = "k" })
local bonusSeen = setmetatable({}, { __mode = "k" })
local bMap = nil
local bCache = nil
local bCons = {}
local bDirty = true
local bScanAt = 0
local locSeq = 0
local roundCur = nil
local roundTotal = nil
local roundLeft = nil
local roundState = nil
local safeCf = nil
local safeAt = 0
local voidAt = 0
local farmTok = 0
local pdata = nil
local lastData = 0
local lastStat = 0
local lastRb = 0
local lastBurst = 0
local survivedAt = 0
local survivedSeen = false
local statsSig = nil
local lastFreshData = 0
local pendingSaveSig = nil
local saveFlushTok = 0
local auraOn = false
local auraUseDistance = true
local auraDist = 7
local auraTok = 0
local auraList = {}
local auraMap = nil
local auraAt = 0
local autoCollectBonuses = true
local autoChallenges = false
local optionsOpen = false
local chSeen = setmetatable({}, { __mode = "k" })
local chWallSeen = setmetatable({}, { __mode = "k" })
local chZipSeen = setmetatable({}, { __mode = "k" })
local chSlideSeen = setmetatable({}, { __mode = "k" })
local chMap = nil
local chAt = 0
local chCache = {}
local zipBusy = false
local chSlideAt = 0
local chWallAt = 0
local chZipAt = 0
local chAirAt = 0
local chDumpAt = 0
local chRegAt = 0
local chLavaAt = 0
local chCons = {}
local chTok = 0
local chIndex = { air = {}, wall = {}, zip = {}, slide = {} }

ctx.current = function()
	return ctx.live and (not host or host.__lt_af_ctx == ctx)
end

ctx.alive = function()
	return ctx.current() and LP and LP.Parent and Run ~= nil
end

ctx.killPlat = function()
	if plt and plt.Parent then
		pcall(function()
			plt:Destroy()
		end)
	end
	plt = nil
end

ctx.clearLocators = function()
	locBtns = {}
	locSeq += 1
end

ctx.releaseRoot = function()
	if type(ctx.rh) ~= "function" then
		return
	end
	local r = select(1, ctx.rh(false))
	if r then
		pcall(function()
			r.Anchored = false
		end)
	end
end

ctx.clearBonuses = function()
	for i = 1, #bCons do
		ctx.cut(bCons[i])
		bCons[i] = nil
	end
	bMap = nil
	bCache = nil
	bDirty = true
	bScanAt = 0
end

ctx.stop = function()
	if not ctx.live then
		return
	end
	ctx.live = false
	on = false
	tok += 1
	cur = nil
	ctx.cut(aVc)
	ctx.cut(nCc)
	ctx.cut(nCd1)
	ctx.cut(nCd2)
	ctx.cut(chC)
	for _, th in ctx.threads do
		if type(task.cancel) == "function" then
			pcall(task.cancel, th)
		end
	end
	ctx.threads = {}
	aVc = nil
	nCc = nil
	nCd1 = nil
	nCd2 = nil
	chC = nil
	for _, c in ctx.con do
		ctx.cut(c)
	end
	ctx.con = {}
	cTab = {}
	pressTimes = setmetatable({}, { __mode = "k" })
	bonusSeen = setmetatable({}, { __mode = "k" })
	if ctx.clearBonuses then
		ctx.clearBonuses()
	end
	ctx.clearLocators()
	auraList = {}
	auraMap = nil
	auraAt = 0
	roundCur = nil
	roundTotal = nil
	roundLeft = nil
	roundState = nil
	safeCf = nil
	safeAt = 0
	voidAt = 0
	farmTok += 1
	auraTok += 1
	saveFlushTok += 1
	pendingSaveSig = nil
	ctx.killPlat()
	ctx.releaseRoot()
	if gui and gui.Parent then
		pcall(function()
			gui:Destroy()
		end)
	end
	gui = nil
	btn = nil
	panel = nil
	optBtn = nil
	optionsFrame = nil
	auraBtn = nil
	distModeBtn = nil
	distBtn = nil
	distLabel = nil
	distRow = nil
	bonusBtn = nil
	chBtn = nil
	chSeen = setmetatable({}, { __mode = "k" })
	chWallSeen = setmetatable({}, { __mode = "k" })
	chZipSeen = setmetatable({}, { __mode = "k" })
	chSlideSeen = setmetatable({}, { __mode = "k" })
	chMap = nil
	chAt = 0
	chCache = {}
	chSlideAt = 0
	chWallAt = 0
	chZipAt = 0
	chDumpAt = 0
	chRegAt = 0
	chLavaAt = 0
	chTok += 1
	for _, c in chCons do
		ctx.cut(c)
	end
	chCons = {}
	chIndex = { air = {}, wall = {}, zip = {}, slide = {} }
end

ctx.descOf = function(obj)
	if not obj then
		return {}
	end
	local q = obj.QueryDescendants
	if type(q) == "function" then
		local ok, res = pcall(q, obj, "Instance")
		if ok and type(res) == "table" then
			return res
		end
	end
	local ok, res = pcall(obj.GetDescendants, obj)
	if ok and type(res) == "table" then
		return res
	end
	return {}
end

ctx.ffc = function(obj, n, rec)
	if not obj then
		return nil
	end
	local ok, res = pcall(obj.FindFirstChild, obj, n, rec)
	if ok then
		return res
	end
	return nil
end

ctx.uiPar = function()
	if type(ctx.gethui) == "function" then
		local ok, ui = pcall(ctx.gethui)
		if ok and typeof(ui) == "Instance" then
			return ui
		end
	end
	return Cgui or (LP and LP:FindFirstChildOfClass("PlayerGui")) or nil
end

local Cls = LP and LP:FindFirstChild("PlayerScripts") or nil
local Clm = Cls and Cls:FindFirstChild("CL_MAIN_GameScript") or nil
local cenv = nil

if Clm and type(getsenv) == "function" then
	local ok, env = pcall(getsenv, Clm)
	if ok and type(env) == "table" then
		cenv = env
	end
end

local alert = cenv and cenv.newAlert or nil

ctx.note = function(msg)
	msg = tostring(msg)

	if type(alert) == "function" then
		local ok = pcall(alert, msg, nil, nil, "rainbow")
		if ok then
			return
		end
		alert = nil
	end

	if Sgui then
		for _ = 1, 3 do
			local ok = pcall(function()
				Sgui:SetCore("SendNotification", {
					Title = "AutoFarm",
					Text = msg,
					Duration = 3,
				})
			end)
			if ok then
				return
			end
			task.wait(0.15)
		end
	end

	if Guis and type(Guis.SetCore) == "function" then
		pcall(function()
			Guis:SetCore("SendNotification", {
				Title = "AutoFarm",
				Text = msg,
				Duration = 3,
			})
		end)
	end
end

local Lift = nil
local PressRemotes = {}
local LocatorRemotes = {}
local RoundStatsRemotes = {}
local LoadedMapRemotes = {}
local SurvivedRemotes = {}
local PlayerDataRemotes = {}
local ItemDataRemotes = {}
local GameStateRemotes = {}
local ChallengeRemotes = {
	GetAirBubble = {},
	SwimInLava = {},
	RegeneratedAir = {},
	SlideCheck = {},
	Walljumped = {},
	RideZipline = {},
}
local ZiplineRemotes = {
	RideZipline = {},
	Zipline = {},
}
local WalljumpRemotes = {
	Walljump = {},
}
local RebirthRemote = nil
local PasskeyRemote = nil
local passKey = nil
local FE2CalcLevelXP = nil
do
	local mods = Rsp and Rsp:FindFirstChild("Modules")
	local shared = mods and mods:FindFirstChild("Shared")
	local lib = shared and shared:FindFirstChild("FE2Library")
	if lib and type(require) == "function" then
		local ok, loaded = pcall(require, lib)
		if ok and type(loaded) == "table" and type(loaded.calcLevelXP) == "function" then
			FE2CalcLevelXP = loaded.calcLevelXP
		end
	end
	local lib2 = mods and mods:FindFirstChild("Library")
	if not FE2CalcLevelXP and lib2 and type(require) == "function" then
		local ok, loaded = pcall(require, lib2)
		if ok and type(loaded) == "table" and type(loaded.GetLevelExperience) == "function" then
			FE2CalcLevelXP = function(lv)
				return loaded.GetLevelExperience(lv)
			end
		end
	end
end

do
	local remFolders = {}
	local seenFolders = {}

	local function addFolder(folder)
		if folder and not seenFolders[folder] then
			seenFolders[folder] = true
			remFolders[#remFolders + 1] = folder
		end
	end

	addFolder(Rsp and Rsp:FindFirstChild("Remote"))
	addFolder(Rsp and Rsp:FindFirstChild("Events"))
	local rmt = Rsp and Rsp:FindFirstChild("Remote")
	local chFolder = rmt and rmt:FindFirstChild("Challenges")
	local gpFolder = rmt and rmt:FindFirstChild("Gameplay")
	addFolder(chFolder)
	addFolder(gpFolder)

	local function scanRuntime(name, cls)
		local scanners = {}
		if type(getnilinstances) == "function" then
			scanners[#scanners + 1] = getnilinstances
		end
		if type(getinstances) == "function" then
			scanners[#scanners + 1] = getinstances
		end
		for _, fn in scanners do
			local ok, list = pcall(fn)
			if ok and type(list) == "table" then
				for _, obj in list do
					if typeof(obj) == "Instance" and obj.Name == name and (not cls or obj:IsA(cls)) then
						return obj
					end
				end
			end
		end
		return nil
	end

	local function findRemote(name, cls)
		for _, folder in remFolders do
			local obj = folder:FindFirstChild(name)
			if obj and (not cls or obj:IsA(cls)) then
				return obj
			end
		end
		return scanRuntime(name, cls)
	end

	local ok, r = pcall(function()
		return findRemote("dKgyIXnLdhwvSyEorkEWJJAkgUslGCtR", "RemoteEvent")
			or findRemote("sTYfsJjxNdIpKgbXIuymAQiYcmAaORRN", "RemoteEvent")
			or findRemote("AddedWaiting", "RemoteEvent")
	end)
	Lift = ok and r or nil

	local function addRemote(list, name)
		local obj = findRemote(name, "RemoteEvent")
		if obj and obj:IsA("RemoteEvent") then
			for _, old in list do
				if old == obj then
					return
				end
			end
			list[#list + 1] = obj
		end
	end

	local function addFolderRemote(list, folder, name)
		local obj = folder and folder:FindFirstChild(name)
		if obj and obj:IsA("RemoteEvent") then
			for _, old in list do
				if old == obj then
					return
				end
			end
			list[#list + 1] = obj
		end
	end

	local pk = findRemote("ReqPasskey", "RemoteFunction")
	if pk and pk:IsA("RemoteFunction") then
		PasskeyRemote = pk
	end

	local rb = findRemote("ReqRebirth", "RemoteEvent") or findRemote("rebirth", "RemoteEvent")
	if rb and rb:IsA("RemoteEvent") then
		RebirthRemote = rb
	end

	addRemote(PressRemotes, "PressedMapButton")
	addRemote(PressRemotes, "igzyswprgEbMOxwZWHUxvFWNJhDtaODb")
	addRemote(LocatorRemotes, "UpdGoalLocator")
	addRemote(LocatorRemotes, "FiIxfRCqDOTWRKHqFMoRjSaAxXOutMzD")
	addRemote(LocatorRemotes, "SetButtonLocator")
	addRemote(RoundStatsRemotes, "UpdIngameStats")
	addRemote(RoundStatsRemotes, "flDEUOrLddFXZVDiezUpxyiHWduVnlEC")
	addRemote(RoundStatsRemotes, "UpdateGameInfo")
	addRemote(LoadedMapRemotes, "LoadedMap")
	addRemote(SurvivedRemotes, "Survived")
	addRemote(PlayerDataRemotes, "UpdPlayerData")
	addRemote(ItemDataRemotes, "ReqItemData")
	addRemote(GameStateRemotes, "UpdateGameState")
	addRemote(ChallengeRemotes.GetAirBubble, "GetAirBubble")
	addRemote(ChallengeRemotes.SwimInLava, "SwimInLava")
	addRemote(ChallengeRemotes.RegeneratedAir, "RegeneratedAir")
	addRemote(ChallengeRemotes.SlideCheck, "SlideCheck")
	addRemote(ChallengeRemotes.Walljumped, "Walljumped")
	addFolderRemote(ChallengeRemotes.RideZipline, chFolder, "RideZipline")
	addFolderRemote(ZiplineRemotes.RideZipline, rmt, "RideZipline")
	addRemote(ZiplineRemotes.Zipline, "Zipline")
	addFolderRemote(WalljumpRemotes.Walljump, gpFolder, "Walljump")
	addRemote(WalljumpRemotes.Walljump, "Walljump")
end

ctx.chr = function(w)
	if not LP then
		return nil
	end
	local c = LP.Character
	if c then
		return c
	end
	if w then
		local ok, res = pcall(function()
			return LP.CharacterAdded:Wait()
		end)
		if ok then
			return res
		end
	end
	return nil
end

ctx.rh = function(w)
	local c = ctx.chr(w)
	if not c then
		return nil, nil, nil
	end
	local r = c:FindFirstChild("HumanoidRootPart")
	local h = c:FindFirstChildOfClass("Humanoid")
	if w then
		if not r then
			r = c:WaitForChild("HumanoidRootPart", 10)
		end
		if not h then
			h = c:WaitForChild("Humanoid", 10)
		end
	end
	return r, h, c
end

ctx.pivotRootTo = function(cf, r, c)
	if typeof(cf) ~= "CFrame" then
		return
	end
	if not r or not r.Parent then
		r = select(1, ctx.rh(false))
	end
	if not c or not c.Parent then
		c = ctx.chr(false)
	end
	if c and c.Parent and r and r.Parent then
		local ok, pivot = pcall(function()
			return c:GetPivot()
		end)
		if ok and pivot then
			local ok2, rel = pcall(function()
				return r.CFrame:ToObjectSpace(pivot)
			end)
			pcall(function()
				c:PivotTo(ok2 and (cf * rel) or cf)
			end)
			return
		end
	end
	if r and r.Parent then
		pcall(function()
			r:PivotTo(cf)
		end)
	end
end

ctx.voidY = function()
	local y = -500
	if Wsp then
		pcall(function()
			local v = Wsp.FallenPartsDestroyHeight
			if type(v) == "number" and v == v then
				y = v
			end
		end)
	end
	return y
end

ctx.limVel = function(r, hard)
	if not r or not r.Parent then
		return
	end
	pcall(function()
		local v = r.AssemblyLinearVelocity
		local x = math.clamp(v.X, -VLM, VLM)
		local y = v.Y
		if hard then
			y = math.clamp(y, -VLM, VLM)
		elseif y < -VLM then
			y = -VLM
		end
		local z = math.clamp(v.Z, -VLM, VLM)
		r.AssemblyLinearVelocity = Vector3.new(x, y, z)
		local a = r.AssemblyAngularVelocity
		if a.Magnitude > VLM then
			r.AssemblyAngularVelocity = a.Unit * VLM
		end
	end)
end

ctx.saveSafe = function(r)
	if not r or not r.Parent then
		return
	end
	local y = ctx.voidY()
	local pos = r.Position
	if pos.Y > y + FDM then
		safeCf = r.CFrame
		safeAt = os.clock()
	end
end

ctx.safeMapCf = function(map, r)
	local y = ctx.voidY()
	if safeCf and safeCf.Position.Y > y + FDM then
		return safeCf + Vector3.new(0, RCH, 0)
	end
	if map and map.Parent then
		local ok, cf, sz = pcall(map.GetBoundingBox, map)
		if ok and cf and sz then
			local pos = cf.Position + Vector3.new(0, sz.Y / 2 + RCH, 0)
			if pos.Y > y + FDM then
				return CFrame.new(pos)
			end
		end
	end
	if r and r.Parent then
		return CFrame.new(r.Position.X, y + FDM + RCH, r.Position.Z)
	end
	return CFrame.new(0, y + FDM + RCH, 0)
end

ctx.inState = function(nm)
	if LP then
		local ok, a = pcall(function()
			return LP:GetAttribute(nm == "InLift" and "IsInLift" or "IsPlaying")
		end)
		if ok and a ~= nil then
			if nm == "InGame" then
				local survived = false
				pcall(function()
					survived = LP:GetAttribute("SurvivedRound") == true
				end)
				return a == true and not survived
			end
			return a == true
		end
	end

	local r = select(1, ctx.rh(false))
	if not r then
		return false
	end
	if nm == "InLift" then
		return r.Position.X < 50 and r.Position.Z > 70
	elseif nm == "InGame" then
		return r.Position.X > 50
	end
	return false
end

ctx.activeRun = function(map, id)
	return ctx.alive() and on and cur == map and map and map.Parent and tok == id
end

ctx.updateRoundStats = function(stats)
	if type(stats) ~= "table" then
		return
	end

	local curVal = stats.currentButton
	local newButtonMode = false
	if curVal == nil then
		curVal = stats.CurrentButton
		newButtonMode = curVal ~= nil
	end
	if type(curVal) == "number" then
		if newButtonMode then
			roundLeft = curVal
			if curVal <= 0 then
				roundCur = 1
				if type(roundTotal) ~= "number" then
					roundTotal = 1
				end
			else
				roundCur = curVal
			end
		else
			roundCur = curVal
		end
	end

	local totalVal = stats.totalButtons or stats.TotalButtons or stats.TotalButton or stats.ButtonsTotal
	if type(totalVal) == "number" then
		roundTotal = totalVal
	end

	local stateVal = stats.gameStatus or stats.GameStatus or stats.GameState or stats.State
	if type(stateVal) == "string" then
		local st = stateVal:lower()
		roundState = st
		if st == "ingame" then
			survivedSeen = false
		elseif st == "survived" then
			ctx.markSurvived("round")
		end
	end
end

ctx.buttonsDone = function()
	if roundState and roundState ~= "ingame" then
		return false
	end
	if type(roundLeft) == "number" then
		return roundLeft <= 0
	end
	if type(roundCur) == "number" and type(roundTotal) == "number" then
		return roundCur >= roundTotal
	end
	return false
end

ctx.isRoundIngame = function()
	local physical = ctx.inState("InGame")
	if type(roundState) == "string" then
		return roundState:lower() == "ingame" or physical
	end
	return physical
end

ctx.isRand = function(s)
	if type(s) ~= "string" or #s == 0 then
		return false
	end
	for i = 1, #s do
		local c = s:sub(i, i)
		if c:lower() == c then
			return false
		end
	end
	return true
end

ctx.mkPlat = function(r)
	local c = ctx.chr(false)
	if not c or not r or not r.Parent then
		return
	end
	local ok, cf, sz = pcall(c.GetBoundingBox, c)
	if not ok or not cf or not sz then
		return
	end
	local y = cf.Position.Y - sz.Y / 2
	if not (plt and plt.Parent) then
		local p = Instance.new("Part")
		p.Name = "AF_SafePlatform"
		p.Size = PSZ
		p.Anchored = true
		p.CanCollide = true
		p.Transparency = 1
		p:PivotTo(CFrame.new(r.Position.X, y - PSZ.Y / 2 - 0.05, r.Position.Z))
		p.Parent = Wsp
		plt = p
	else
		plt:PivotTo(CFrame.new(r.Position.X, y - PSZ.Y / 2 - 0.05, r.Position.Z))
	end
end

ctx.anyPart = function(obj)
	if not obj then
		return nil
	end
	if obj:IsA("BasePart") then
		return obj
	end
	if obj:IsA("Model") then
		if obj.PrimaryPart then
			return obj.PrimaryPart
		end
		for _, d in ctx.descOf(obj) do
			if d:IsA("BasePart") then
				return d
			end
		end
	end
	return nil
end

ctx.moveTo = function(obj, r)
	if not obj or not r or not r.Parent then
		return false
	end
	local p = ctx.anyPart(obj)
	if not p then
		return false
	end
	local moved = false
	if obj:IsA("Model") then
		moved = pcall(function()
			obj:PivotTo(r.CFrame)
		end)
	else
		moved = pcall(function()
			p:PivotTo(r.CFrame)
		end)
	end
	return moved
end

ctx.bKind = function(obj)
	if not obj then
		return nil
	end
	local nm = obj.Name
	if type(nm) ~= "string" then
		return nil
	end
	nm = nm:lower()
	if nm == "_lostpage" then
		return "pg"
	end
	if nm == "contact" then
		return "ct"
	end
	if nm == "npc" then
		return "npc"
	end
	return nil
end

ctx.addBonus = function(obj)
	if not bCache or not obj then
		return
	end
	local k = ctx.bKind(obj)
	if k == "pg" then
		if not (bCache.pg and bCache.pg.Parent) then
			bCache.pg = obj
		end
	elseif k == "ct" then
		if not (bCache.ct and bCache.ct.Parent) then
			bCache.ct = obj
		end
	elseif k == "npc" then
		if not (bCache.npc and bCache.npc.Parent) then
			bCache.npc = obj
		end
		if not (bCache.ct and bCache.ct.Parent) and obj.Parent then
			local ok, ct = pcall(function()
				return obj.Parent:FindFirstChild("Contact")
			end)
			if ok and ct then
				bCache.ct = ct
			end
		end
	end
end

ctx.scanBonuses = function(map)
	if not bCache then
		bCache = {}
	end
	bCache.pg = nil
	bCache.ct = nil
	bCache.npc = nil
	for _, obj in ctx.descOf(map) do
		ctx.addBonus(obj)
		if bCache.pg and bCache.ct then
			break
		end
	end
	if not bCache.ct and bCache.npc and bCache.npc.Parent then
		local ok, ct = pcall(function()
			return bCache.npc.Parent:FindFirstChild("Contact")
		end)
		if ok and ct then
			bCache.ct = ct
		end
	end
	bDirty = false
end

ctx.getBonuses = function(map)
	if not (map and map.Parent) then
		ctx.clearBonuses()
		return nil
	end
	if map ~= bMap then
		ctx.clearBonuses()
		bMap = map
		bCache = {}
		bDirty = true
		bCons[#bCons + 1] = map.DescendantAdded:Connect(function(obj)
			if not bCache then
				return
			end
			local k = ctx.bKind(obj)
			if k then
				ctx.addBonus(obj)
			end
		end)
		bCons[#bCons + 1] = map.DescendantRemoving:Connect(function(obj)
			if bCache and (obj == bCache.pg or obj == bCache.ct or obj == bCache.npc) then
				if obj == bCache.pg then
					bCache.pg = nil
				end
				if obj == bCache.ct then
					bCache.ct = nil
				end
				if obj == bCache.npc then
					bCache.npc = nil
				end
				bDirty = true
			end
		end)
	end
	local now = os.clock()
	if bDirty and now >= bScanAt then
		bScanAt = now + 2
		ctx.scanBonuses(map)
	end
	return bCache
end

ctx.takeBonus = function(obj, r, notify, msg)
	if not (obj and obj.Parent) then
		return false
	end
	local now = os.clock()
	if bonusSeen[obj] and now - bonusSeen[obj] <= 2 then
		return false
	end
	bonusSeen[obj] = now
	local ok = ctx.moveTo(obj, r)
	if ok then
		if notify then
			ctx.note(msg)
		end
		task.wait(TPD)
	end
	return ok
end

ctx.collectMapBonuses = function(map, r, notify)
	if not (map and map.Parent) then
		return false
	end
	if not (r and r.Parent) then
		r = select(1, ctx.rh(false))
	end
	if not (r and r.Parent) then
		return false
	end
	local bc = ctx.getBonuses(map)
	if not bc then
		return false
	end
	local moved = false
	if bc.pg and not bc.pg.Parent then
		bc.pg = nil
		bDirty = true
	end
	if bc.ct and not bc.ct.Parent then
		bc.ct = nil
		bDirty = true
	end
	if not bc.ct and bc.npc and bc.npc.Parent then
		local ok, ct = pcall(function()
			return bc.npc.Parent:FindFirstChild("Contact")
		end)
		if ok and ct then
			bc.ct = ct
		end
	end
	moved = ctx.takeBonus(bc.pg, r, nil, "Got Lost Page.") or moved
	moved = ctx.takeBonus(bc.ct, r, nil, "Got Escapee.") or moved
	return moved
end

ctx.addBtnEntry = function(t, src, hit, loc)
	if not hit or not hit:IsA("BasePart") then
		return
	end
	t[#t + 1] = {
		src = src or hit,
		hit = hit,
		loc = loc and true or false,
	}
end

ctx.scanBtns = function(map)
	local t = {}
	for _, obj in ctx.descOf(map) do
		if obj.ClassName == "Model" then
			local hit = nil
			local hasUi = obj:FindFirstChildWhichIsA("BillboardGui", true) ~= nil
			local hasFuse = ctx.ffc(obj, "Fuse", true) ~= nil
			for _, ch in obj:GetChildren() do
				if ch:IsA("BasePart") and tostring(ch.BrickColor) ~= "Medium stone grey" then
					hit = ch
					break
				end
			end
			local hasTouch = hit and ctx.ffc(hit, "TouchInterest", true) ~= nil
			if hit and (ctx.isRand(obj.Name) or hasUi or hasFuse or hasTouch) then
				if ctx.isRand(hit.Name) then
					hit.Name = "Hitbox"
				end
				ctx.addBtnEntry(t, obj, hit, false)
			end
		end
	end
	return t
end

ctx.valOf = function(obj, names)
	if not obj then
		return nil
	end
	for _, n in names do
		local ok, v = pcall(function()
			return obj:GetAttribute(n)
		end)
		if ok and v ~= nil then
			return v
		end
	end
	for _, d in ctx.descOf(obj) do
		if d:IsA("ValueBase") then
			local nm = d.Name:lower():gsub("[^%w]", "")
			for _, n in names do
				if nm == n:lower():gsub("[^%w]", "") then
					return d.Value
				end
			end
		end
	end
	return nil
end

ctx.numOf = function(obj)
	local v = ctx.valOf(obj, { "ButtonID", "ButtonId", "ButtonIndex", "ButtonNumber", "ButtonNum", "Number", "ID", "Index", "Order" })
	v = tonumber(v)
	if v then
		return v
	end
	local nm = obj and tostring(obj.Name) or ""
	local a = nm:match("%d+")
	return tonumber(a)
end

ctx.guiOn = function(obj)
	if not obj then
		return false
	end
	for _, d in ctx.descOf(obj) do
		if d:IsA("BillboardGui") and d.Enabled then
			return true
		end
	end
	return false
end

ctx.auraReady = function(entry)
	local hit = entry and entry.hit
	local src = entry and entry.src
	if not (hit and hit.Parent) then
		return false
	end
	if entry.loc then
		return true
	end
	local av = ctx.valOf(src, { "Active", "IsActive", "Enabled", "Pressable", "CanPress", "Current", "Selected" })
	if av ~= nil then
		return av == true or av == 1 or tostring(av):lower() == "true"
	end
	if type(roundCur) == "number" then
		local n = ctx.numOf(src) or ctx.numOf(hit)
		if n then
			return n == roundCur or n == roundCur + 1
		end
	end
	if ctx.guiOn(src) or ctx.guiOn(hit) then
		return true
	end
	return ctx.ffc(hit, "TouchInterest", true) ~= nil
end

ctx.auraEntries = function(map)
	local t = ctx.locatorEntries(map)
	if #t > 0 then
		return t, true
	end
	local now = os.clock()
	if auraMap ~= map or now - auraAt > 0.25 then
		auraMap = map
		auraAt = now
		auraList = {}
		local ok, res = pcall(ctx.scanBtns, map)
		if ok and type(res) == "table" then
			for _, entry in res do
				if ctx.auraReady(entry) then
					auraList[#auraList + 1] = entry
				end
			end
		end
	end
	for i = #auraList, 1, -1 do
		local entry = auraList[i]
		local hit = entry and entry.hit
		if not (hit and hit.Parent and hit:IsDescendantOf(map) and ctx.auraReady(entry)) then
			table.remove(auraList, i)
		end
	end
	return auraList, false
end

ctx.asPart = function(v)
	if typeof(v) == "Instance" and v:IsA("BasePart") then
		return v
	end
	if type(v) ~= "table" then
		return nil
	end
	local r = select(1, ctx.rh(false))
	local best = nil
	local bestDist = math.huge
	for _, obj in v do
		if typeof(obj) == "Instance" and obj:IsA("BasePart") then
			local dist = r and (r.Position - obj.Position).Magnitude or 0
			if dist < bestDist then
				best = obj
				bestDist = dist
			end
		end
	end
	return best
end

ctx.addLocatorBtn = function(hit, nextHit)
	ctx.clearLocators()
	hit = ctx.asPart(hit)
	nextHit = ctx.asPart(nextHit)
	if not hit then
		return
	end
	local src = hit.Parent or hit
	locBtns[hit] = {
		src = src,
		hit = hit,
		loc = true,
		next = nextHit,
		seq = locSeq,
	}
	local id = locSeq
	task.spawn(function()
		while ctx.alive() and locSeq == id and hit and hit.Parent do
			if not auraOn then
				task.wait(0.1)
				continue
			end
			if type(ctx.pressMapButton) == "function" and ctx.isRoundIngame() then
				local hb = auraUseDistance and type(ctx.rootPart) == "function" and ctx.rootPart() or nil
				local maxDist = math.max(0, tonumber(auraDist) or 7)
				if not auraUseDistance or (hb and hb.Parent and (hb.Position - hit.Position).Magnitude <= maxDist) then
					ctx.pressMapButton(hit)
				end
			end
			task.wait(BSI)
		end
	end)
end

ctx.locatorEntries = function(map)
	local t = {}
	for hit, entry in locBtns do
		if hit and hit.Parent and (not map or hit:IsDescendantOf(map)) then
			t[#t + 1] = entry
		else
			locBtns[hit] = nil
		end
	end
	return t
end

ctx.nearestEntry = function(entries, pos)
	local best = nil
	local bestDist = math.huge
	if not pos then
		return nil
	end
	for _, entry in entries do
		local hit = entry and entry.hit
		if hit and hit.Parent then
			local dist = (pos - hit.Position).Magnitude
			if dist < bestDist then
				best = entry
				bestDist = dist
			end
		end
	end
	return best
end

ctx.pressAuraEntries = function(entries, map, allowNearestFallback)
	local hb = type(ctx.rootPart) == "function" and ctx.rootPart() or nil
	local maxDist = math.max(0, tonumber(auraDist) or 7)
	local pressed = false
	if not hb and auraUseDistance then
		return false
	end

	if not auraUseDistance and allowNearestFallback then
		if not (hb and hb.Parent) then
			return false
		end
		local entry = ctx.nearestEntry(entries, hb and hb.Position or nil)
		local hit = entry and entry.hit
		if hit and hit.Parent and (not map or hit:IsDescendantOf(map)) then
			ctx.pressMapButton(hit)
			return true
		end
		return false
	end

	for i = #entries, 1, -1 do
		local entry = entries[i]
		local hit = entry and entry.hit
		if not (hit and hit.Parent and (not map or hit:IsDescendantOf(map))) then
			table.remove(entries, i)
		elseif not auraUseDistance or (hb and hb.Parent and (hb.Position - hit.Position).Magnitude <= maxDist) then
			pressed = true
			if type(ctx.pressMapButton) == "function" then
				ctx.pressMapButton(hit)
			end
		end
	end
	return pressed
end

ctx.mergeLocatorBtns = function(t, map)
	local seen = {}
	for _, entry in t do
		if entry.hit and (not entry.loc or locBtns[entry.hit] == entry) then
			seen[entry.hit] = true
		end
	end
	for hit, entry in locBtns do
		if not (hit and hit.Parent) then
			locBtns[hit] = nil
		elseif not seen[hit] and (not map or hit:IsDescendantOf(map)) then
			t[#t + 1] = entry
			seen[hit] = true
		end
	end
	return t
end

ctx.isFuseBtn = function(src)
	local f = ctx.ffc(src, "Fuse", true)
	if not f and src and src.Parent then
		f = ctx.ffc(src.Parent, "Fuse", true)
	end
	return f and f:IsA("ValueBase")
end

ctx.fuseRange = function(src, hit)
	local best = nil
	local bestSize = 0
	local root = src
	if hit and hit.Parent and (not root or root == hit) then
		root = hit.Parent
	end
	for _, obj in ctx.descOf(root) do
		if obj:IsA("Part") and obj ~= hit and obj.Shape == Enum.PartType.Ball then
			local sz = math.max(obj.Size.X, obj.Size.Y, obj.Size.Z)
			local red = obj.Color.R > 0.75 and obj.Color.G < 0.15 and obj.Color.B < 0.15
			if sz >= 10 and red and sz > bestSize then
				best = obj
				bestSize = sz
			end
		end
	end
	return best
end

ctx.waitFuseRange = function(src, hit, keepGoing)
	if keepGoing and not keepGoing() then
		return nil
	end
	return ctx.fuseRange(src, hit)
end

ctx.moveFuseSafe = function(src, hit, r, keepGoing)
	if keepGoing and not keepGoing() then
		return
	end
	if not hit or not hit.Parent then
		return
	end
	if not r or not r.Parent then
		r = select(1, ctx.rh(false))
	end
	if not r or not r.Parent then
		return
	end
	local sp = ctx.fuseRange(src, hit)
	local pos = sp and sp.Parent and sp.Position or (hit.Position + Vector3.new(0, ESY, 0))
	pcall(function()
		ctx.pivotRootTo(CFrame.new(pos), r)
		r.AssemblyLinearVelocity = Vector3.zero
		r.AssemblyAngularVelocity = Vector3.zero
		r.Anchored = true
	end)
end

ctx.pressMapButton = function(hit)
	if not hit or not hit.Parent then
		return
	end
	local now = os.clock()
	local last = pressTimes[hit]
	if last and now - last < PCD then
		return
	end
	pressTimes[hit] = now
	for _, rem in PressRemotes do
		if rem and rem.Parent then
			pcall(function()
				rem:FireServer(hit)
			end)
		end
	end
end

ctx.startPressLoop = function(hit, runId, keepGoing)
	if not hit or not hit.Parent then
		return
	end
	task.spawn(function()
		while ctx.alive() and on and tok == runId and hit and hit.Parent do
			if type(keepGoing) == "function" and not keepGoing() then
				break
			end
			ctx.pressMapButton(hit)
			task.wait(BSI)
		end
	end)
end

ctx.startAutoFarmButtonSpam = function(map, runId, entries)
	if not map or not map.Parent then
		return
	end
	entries = type(entries) == "table" and entries or {}
	ctx.spawnLoop(function()
		while ctx.activeRun(map, runId) and ctx.inState("InGame") do
			ctx.mergeLocatorBtns(entries, map)
			if not ctx.buttonsDone() then
				for i = #entries, 1, -1 do
					local entry = entries[i]
					local hit = entry and entry.hit
					if hit and hit.Parent and hit:IsDescendantOf(map) then
						ctx.pressMapButton(hit)
					else
						table.remove(entries, i)
					end
				end
			end
			task.wait(BSI)
		end
	end)
end

ctx.getPassArg = function(force)
	if force then
		passKey = nil
	end
	if passKey ~= nil then
		return type(passKey) == "number" and -passKey or passKey
	end
	if not (PasskeyRemote and PasskeyRemote.Parent) then
		return nil
	end
	local ok, res = pcall(function()
		return PasskeyRemote:InvokeServer()
	end)
	if not ok or res == nil then
		return nil
	end
	passKey = res
	return type(res) == "number" and -res or res
end


ctx.dataSig = function(data)
	local st = data and data.stats
	if type(st) ~= "table" then
		return nil
	end
	local parts = {}
	for k, v in st do
		if type(v) ~= "table" and typeof(v) ~= "Instance" then
			parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
		end
	end
	table.sort(parts)
	return table.concat(parts, "|")
end

ctx.cacheData = function(data)
	if type(data) == "table" and type(data.stats) == "table" then
		local sig = ctx.dataSig(data)
		pdata = data
		if sig then
			if sig ~= statsSig then
				lastFreshData = os.clock()
				if pendingSaveSig and sig ~= pendingSaveSig then
					pendingSaveSig = nil
				end
			end
			statsSig = sig
		end
		if type(ctx.paintStats) == "function" then
			ctx.paintStats()
		end
	end
end

ctx.cacheLocalData = function()
	if not LP then
		return
	end
	local data = LP:FindFirstChild("Data")
	if not data then
		return
	end
	local function val(n)
		local obj = data:FindFirstChild(n)
		return obj and obj:IsA("ValueBase") and obj.Value or nil
	end
	ctx.cacheData({
		stats = {
			level = val("Level"),
			xp = val("Experience"),
			coins = val("Coins"),
			gems = val("Amethysts"),
			rebirth = val("Rebirths"),
		},
	})
end

ctx.needXp = function(lv, rb)
	lv = tonumber(lv) or 0
	rb = tonumber(rb) or 0
	if FE2CalcLevelXP then
		local ok, xp = pcall(FE2CalcLevelXP, lv, rb)
		if ok and type(xp) == "number" then
			return xp
		end
	end
	if lv == 0 then
		return 1
	end
	local base = math.clamp(200 + (lv - 1) * 200, 1, 12000)
	return base + base * (math.clamp(rb, 0, 30) * 0.05)
end

ctx.paintStats = function()
	local st = pdata and pdata.stats
	if type(st) ~= "table" or not LP then
		return
	end
	local pg = LP:FindFirstChild("PlayerGui")
	local gg = pg and pg:FindFirstChild("GameGui")
	local hud = gg and gg:FindFirstChild("HUD")
	local main = hud and hud:FindFirstChild("Main")
	local gs = main and main:FindFirstChild("GameStats")
	local ui = gs and gs:FindFirstChild("Stats")
	if not ui then
		return
	end
	local lv = tonumber(st.level) or 0
	local rb = tonumber(st.rebirth) or 0
	local xp = tonumber(st.xp) or 0
	local req = ctx.needXp(lv, rb)
	if req <= 0 then
		req = 1
	end
	local rdy = lv >= 100 and rb < 30 and xp >= req
	local xs = ui:FindFirstChild("XPStats")
	if xs then
		local ic = ctx.ffc(xs, "Icon", false)
		local inf = ic and ic:FindFirstChild("Info")
		if inf then
			inf.Text = tostring(lv)
		end
		local xt = xs:FindFirstChild("XP")
		if xt then
			xt.Text = tostring(xp) .. "/" .. tostring(req) .. " XP"
		end
		local pb = ctx.ffc(xs, "Percentage", true)
		if pb then
			pb.Size = UDim2.new(math.clamp(xp / req, 0, 1), 0, 1, 0)
		end
		local reb = xs:FindFirstChild("Rebirth")
		if reb then
			reb.Visible = rb > 0
			local ri = reb:FindFirstChild("Info")
			if ri then
				ri.Text = "x" .. tostring(rb)
			end
		end
		xs.Visible = not rdy
	end
	local rbui = ui:FindFirstChild("Rebirth")
	if rbui then
		rbui.Visible = rdy
	end
	local ms = ui:FindFirstChild("MapStats")
	local mb = ms and ms:FindFirstChild("MapBar")
	if mb then
		local dm = tonumber(st.dailyMapsCompleted) or 0
		for i = 1, 10 do
			local m = mb:FindFirstChild("Map" .. i)
			if m then
				m.BackgroundTransparency = i <= dm and 0.2 or 0.7
			end
		end
	end
	local cur = ui:FindFirstChild("Currency")
	if cur then
		local ca = ctx.ffc(cur, "CoinAmt", true)
		local ga = ctx.ffc(cur, "GemAmt", true)
		local ct = ca and ctx.ffc(ca, "Amount", true)
		local gx = ga and ctx.ffc(ga, "Amount", true)
		if ct then
			ct.Text = tostring(st.coins or 0)
		end
		if gx then
			gx.Text = tostring(st.gems or 0)
		end
	end
end

ctx.canRebirth = function()
	local st = pdata and pdata.stats
	if type(st) ~= "table" then
		return nil
	end
	local lv = tonumber(st.level) or 0
	local rb = tonumber(st.rebirth) or 0
	local xp = tonumber(st.xp) or 0
	local req = ctx.needXp(lv, rb)
	if rb >= 30 or lv < 100 then
		return false
	end
	return req <= 0 or xp >= req
end

ctx.fireLoaded = function(key)
	for _, rem in LoadedMapRemotes do
		if rem and rem.Parent then
			pcall(function()
				if key ~= nil then
					rem:FireServer(key)
				else
					rem:FireServer()
				end
			end)
		end
	end
end

ctx.fireSurvived = function(key, tm)
	tm = tonumber(tm) or 100
	for _, rem in SurvivedRemotes do
		if rem and rem.Parent then
			pcall(function()
				if key ~= nil then
					rem:FireServer(key, tm)
				else
					rem:FireServer(tm)
				end
			end)
		end
	end
end

ctx.requestRoundStats = function()
	for _, rem in RoundStatsRemotes do
		if rem and rem.Parent then
			pcall(function()
				rem:FireServer()
			end)
		end
	end
end

ctx.requestPlayerData = function(force)
	local now = os.clock()
	if not force and now - lastData < DRI then
		return
	end
	lastData = now
	local key = ctx.getPassArg(false)
	for _, rem in ItemDataRemotes do
		if rem and rem.Parent then
			pcall(function()
				if key ~= nil then
					rem:FireServer(key, true)
				else
					rem:FireServer(nil, true)
				end
			end)
		end
	end
	for _, rem in PlayerDataRemotes do
		if rem and rem.Parent then
			pcall(function()
				rem:FireServer()
			end)
		end
	end
	ctx.cacheLocalData()
end

ctx.tryRebirth = function(force)
	if not (RebirthRemote and RebirthRemote.Parent) then
		return
	end
	local now = os.clock()
	local okRb = ctx.canRebirth()
	if okRb ~= true then
		return
	end
	local gap = RBI
	if not force and now - lastRb < gap then
		return
	end
	lastRb = now
	local key = ctx.getPassArg(false)
	pcall(function()
		if key ~= nil then
			RebirthRemote:FireServer(key)
		else
			RebirthRemote:FireServer()
		end
	end)
end

ctx.statPulse = function(force)
	local now = os.clock()
	if not force and now - lastStat < SRI then
		return
	end
	lastStat = now
	ctx.requestRoundStats()
	ctx.requestPlayerData(true)
	task.delay(0.5, function()
		if ctx.alive() and on then
			ctx.requestPlayerData(true)
			ctx.tryRebirth(true)
		end
	end)
end

ctx.statBurst = function()
	local now = os.clock()
	if now - lastBurst < 0.5 then
		return
	end
	lastBurst = now
	for _, d in RFD do
		task.delay(d, function()
			if ctx.alive() and on then
				ctx.requestRoundStats()
				ctx.requestPlayerData(true)
				ctx.tryRebirth(true)
			end
		end)
	end
end

ctx.flushStatsAfterSurvival = function()
	saveFlushTok += 1
	local id = saveFlushTok
	pendingSaveSig = statsSig or ""
	local started = os.clock()
	task.spawn(function()
		while ctx.alive() and on and saveFlushTok == id and os.clock() - started < SFT do
			ctx.requestRoundStats()
			ctx.requestPlayerData(true)
			ctx.tryRebirth(true)
			if pendingSaveSig == nil and lastFreshData >= started then
				break
			end
			task.wait(SFI)
		end
		if ctx.alive() and on and saveFlushTok == id then
			ctx.requestRoundStats()
			ctx.requestPlayerData(true)
			ctx.tryRebirth(true)
		end
	end)
end

ctx.markSurvived = function(src)
	if survivedSeen then
		return
	end
	local now = os.clock()
	survivedSeen = true
	survivedAt = now
	roundState = "survived"
	tok += 1
	ctx.releaseRoot()
	ctx.statPulse(true)
	ctx.statBurst()
	ctx.flushStatsAfterSurvival()
	if src then
		ctx.note("Survived; refreshing stats")
	end
end

ctx.burstLoaded = function()
	local key = ctx.getPassArg(false)
	for _ = 1, LDB do
		if not (ctx.alive() and on) then
			return
		end
		ctx.fireLoaded(key)
		ctx.requestRoundStats()
		task.wait(LDI)
	end
end

ctx.startFarmRemotes = function()
	farmTok += 1
	local id = farmTok
	task.spawn(function()
		local ka = 0
		local ra = 0
		while ctx.alive() and on and farmTok == id do
			local ok, err = xpcall(function()
				local now = os.clock()
				if now >= ka then
					ctx.getPassArg(true)
					ctx.requestPlayerData(false)
					ctx.tryRebirth(false)
					ka = now + 2
				end
				if now >= ra then
					ctx.requestRoundStats()
					ra = now + RSI
				end
			end, debug.traceback)
			if not ok then
				warn(err)
			end
			task.wait(FMI)
		end
	end)
end

ctx.startPassiveRemotes = function()
	ctx.spawnLoop(function()
		local ra = 0
		local la = 0
		local sa = 0
		while ctx.alive() do
			local now = os.clock()
			if now >= la then
				ctx.fireLoaded(ctx.getPassArg(false))
				la = now + PLI
			end
			if ctx.isRoundIngame() and now >= sa then
				ctx.fireSurvived(ctx.getPassArg(false), 100)
				sa = now + PSI
			end
			if now >= ra then
				ctx.requestRoundStats()
				ra = now + RSI
			end
			task.wait(PMW)
		end
	end)
end

for _, rem in LocatorRemotes do
	if rem then
		ctx.bind(rem.OnClientEvent:Connect(function(goal, hit, ui, nextHit)
			ctx.addLocatorBtn(hit or goal, nextHit or ui)
		end))
	end
end

for _, rem in RoundStatsRemotes do
	if rem then
		ctx.bind(rem.OnClientEvent:Connect(ctx.updateRoundStats))
		if rem.Parent then
			pcall(function()
				rem:FireServer()
			end)
		end
	end
end

for _, rem in PlayerDataRemotes do
	if rem and rem.Parent then
		ctx.bind(rem.OnClientEvent:Connect(ctx.cacheData))
	end
end

for _, rem in ItemDataRemotes do
	if rem and rem.Parent then
		ctx.bind(rem.OnClientEvent:Connect(function(data)
			ctx.cacheData(data)
		end))
	end
end

for _, rem in SurvivedRemotes do
	if rem and rem.Parent then
		ctx.bind(rem.OnClientEvent:Connect(function(ok)
			if ok == true or tostring(ok):lower() == "survived" then
				ctx.markSurvived("remote")
			end
		end))
	end
end

for _, rem in GameStateRemotes do
	if rem and rem.Parent then
		ctx.bind(rem.OnClientEvent:Connect(function(st)
			local state = tostring(st):lower()
			if state ~= "" and state ~= "nil" then
				roundState = state
			end
			if state == "ingame" then
				survivedSeen = false
			elseif state == "survived" then
				ctx.markSurvived("state")
			end
		end))
	end
end

if LP then
	ctx.bind(LP:GetAttributeChangedSignal("SurvivedRound"):Connect(function()
		if LP:GetAttribute("SurvivedRound") == true then
			ctx.markSurvived("attribute")
		elseif LP:GetAttribute("IsPlaying") == true then
			survivedSeen = false
			roundState = "ingame"
		end
	end))
	ctx.bind(LP:GetAttributeChangedSignal("IsPlaying"):Connect(function()
		if LP:GetAttribute("IsPlaying") == true and LP:GetAttribute("SurvivedRound") ~= true then
			survivedSeen = false
			roundState = "ingame"
		end
	end))
end

ctx.requestPlayerData(true)

ctx.addNc = function(obj)
	if obj and obj:IsA("BasePart") then
		cTab[obj] = true
	end
end

ctx.clrNc = function()
	cTab = {}
	ctx.cut(nCd1)
	ctx.cut(nCd2)
	nCd1 = nil
	nCd2 = nil
end

ctx.bindNc = function(c)
	ctx.clrNc()
	if not c then
		return
	end
	ctx.addNc(c)
	for _, d in ctx.descOf(c) do
		ctx.addNc(d)
	end
	nCd1 = c.DescendantAdded:Connect(function(d)
		ctx.addNc(d)
	end)
	nCd2 = c.DescendantRemoving:Connect(function(d)
		cTab[d] = nil
	end)
end

ctx.setNc = function(v)
	ctx.cut(nCc)
	nCc = nil
	ctx.clrNc()
	if not v or not Run or not LP then
		return
	end
	ctx.bindNc(LP.Character)
	nCc = Run.PreSimulation:Connect(function()
		if not on then
			return
		end
		for p in cTab do
			if p and p.Parent then
				p.CanCollide = false
			else
				cTab[p] = nil
			end
		end
	end)
end

ctx.liftTarget = function()
	local lobby = Wsp and Wsp:FindFirstChild("Lobby")
	if not lobby then
		return nil
	end
	local play = lobby:FindFirstChild("PlayHere")
	if play then
		local best = nil
		for _, obj in ctx.descOf(play) do
			if obj:IsA("BasePart") then
				if obj:FindFirstChild("SurfaceGui") or not best then
					best = obj
				end
			end
		end
		if best then
			return best
		end
	end
	local mw = lobby:FindFirstChild("MapWaiting")
	local direct = mw and (mw:FindFirstChild("LiftTeleport", true) or mw:FindFirstChild("LiftCollision", true) or mw:FindFirstChild("Plate", true))
	if direct and direct:IsA("BasePart") then
		return direct
	end
	return nil
end

ctx.touchLift = function(part, r)
	if not (part and part.Parent and r and r.Parent) then
		return
	end
	if type(firetouchinterest) == "function" then
		pcall(firetouchinterest, r, part, 0)
		pcall(firetouchinterest, r, part, 1)
	end
end

ctx.pushLift = function()
	local r = select(1, ctx.rh(true))
	if not r then
		return
	end
	pcall(function()
		ctx.pivotRootTo(r.CFrame + Vector3.new(0, 5, 0), r)
	end)
	while ctx.alive() and on and not ctx.inState("InLift") do
		task.wait(0.1)
		local rr = select(1, ctx.rh(false))
		if not rr then
			continue
		end
		local part = ctx.liftTarget()
		if part then
			pcall(function()
				ctx.pivotRootTo(part.CFrame + Vector3.new(0, 3, 0), rr)
				rr.AssemblyLinearVelocity = Vector3.zero
			end)
			ctx.touchLift(part, rr)
		else
			rr.AssemblyLinearVelocity = LFG
		end
		ctx.mkPlat(rr)
	end
end

ctx.doLift = function()
	if not on then
		return
	end
	if Lift then
		pcall(function()
			Lift:FireServer()
		end)
	end
	task.spawn(function()
		local ok, err = xpcall(ctx.pushLift, debug.traceback)
		if not ok then
			warn(err)
		end
	end)
end

ctx.antiVoid = function(getMap)
	ctx.cut(aVc)
	aVc = nil
	if not Run then
		return
	end
	aVc = Run.Heartbeat:Connect(function()
		if not on then
			return
		end
		local r = select(1, ctx.rh(false))
		if not r then
			return
		end

		local fy = ctx.voidY()
		local pos = r.Position
		local vel = Vector3.zero
		pcall(function()
			vel = r.AssemblyLinearVelocity
		end)

		local nearVoid = pos.Y <= fy + FDM
		local badFall = vel.Y < -VLM and pos.Y <= fy + FDM * 2

		if not nearVoid and not badFall then
			ctx.saveSafe(r)
			return
		end

		if nearVoid or badFall then
			ctx.limVel(r, nearVoid)
		end

		local map = nil
		local ok, res = pcall(getMap)
		if ok then
			map = res
		end

		local cf = ctx.safeMapCf(map, r)
		pcall(function()
			ctx.pivotRootTo(cf, r)
		end)
		ctx.limVel(r, true)
		ctx.mkPlat(r)

		if os.clock() - voidAt > 1 then
			voidAt = os.clock()
			ctx.note("Recovered from void")
		end
	end)
end

ctx.setBtn = function()
	if not btn then
		return
	end
	btn.Text = on and "Stop AutoFarm" or "Start AutoFarm"
	btn.BackgroundColor3 = on and Color3.fromRGB(180, 60, 60) or Color3.fromRGB(60, 180, 60)
end

ctx.setAuraBtn = function()
	if not auraBtn then
		return
	end
	auraBtn.Text = auraOn and "Button Aura: ON" or "Button Aura: OFF"
	auraBtn.BackgroundColor3 = auraOn and Color3.fromRGB(60, 130, 210) or Color3.fromRGB(70, 70, 70)
end

ctx.setDistModeBtn = function()
	if not distModeBtn then
		return
	end
	distModeBtn.Text = auraUseDistance and "Button Distance: ON" or "Button Distance: OFF"
	distModeBtn.BackgroundColor3 = auraUseDistance and Color3.fromRGB(60, 130, 210) or Color3.fromRGB(70, 70, 70)
end

ctx.setDistBtn = function()
	if not distBtn then
		return
	end
	distBtn.Text = tostring(auraDist)
end

ctx.setBonusBtn = function()
	if not bonusBtn then
		return
	end
	bonusBtn.Text = autoCollectBonuses and "Collect Bonuses: ON" or "Collect Bonuses: OFF"
	bonusBtn.BackgroundColor3 = autoCollectBonuses and Color3.fromRGB(60, 130, 210) or Color3.fromRGB(70, 70, 70)
end

ctx.setChallengeBtn = function()
	if not chBtn then
		return
	end
	chBtn.Text = autoChallenges and "Challenges: ON" or "Challenges: OFF"
	chBtn.BackgroundColor3 = autoChallenges and Color3.fromRGB(60, 130, 210) or Color3.fromRGB(70, 70, 70)
end

ctx.setOptionsOpen = function(open)
	optionsOpen = open and true or false
	if optBtn then
		optBtn.Text = optionsOpen and "Options ^" or "Options v"
	end
	if optionsFrame then
		optionsFrame.Visible = optionsOpen
	end
	if panel then
		panel.Size = optionsOpen and UDim2.new(0, 190, 0, 330) or UDim2.new(0, 190, 0, 105)
	end
end

local mouseButtonFixHooks = setmetatable({}, { __mode = "k" })

ctx.tryDisconnect = function(conn)
	if conn and type(conn.Disconnect) == "function" then
		pcall(function()
			conn:Disconnect()
		end)
	end
end

ctx.MouseButtonFix = function(button, clickCallback, pressInput)
	if not button or type(clickCallback) ~= "function" then
		return { Connected = false, Disconnect = function() end }
	end

	local clickTimeThreshold = 0.45
	local moveThreshold = 10
	local mouseDownTime = 0
	local isPointerDown = false
	local startPosition = nil
	local maxMoveDistance = 0
	local connections = {}
	local disconnected = false
	local wantedInput = pressInput or Enum.UserInputType.MouseButton1
	local hookKey = tostring(wantedInput)
	local hooks = mouseButtonFixHooks[button]
	if type(hooks) ~= "table" then
		hooks = {}
		mouseButtonFixHooks[button] = hooks
	end
	local existing = hooks[hookKey]
	if existing then
		ctx.tryDisconnect(existing)
	end

	local state = {
		Connected = true,
	}

	local function disconnectAll()
		if disconnected then
			return
		end
		disconnected = true
		state.Connected = false
		for i = 1, #connections do
			ctx.tryDisconnect(connections[i])
			connections[i] = nil
		end
		if hooks[hookKey] == state then
			hooks[hookKey] = nil
		end
	end

	function state:Disconnect()
		disconnectAll()
	end

	hooks[hookKey] = state

	local function getSignal(obj, signalName)
		local ok, signal = pcall(function()
			return obj[signalName]
		end)
		if ok and signal then
			return signal
		end
		return nil
	end

	local function connectSignal(signal, fn)
		if disconnected or not signal then
			return false
		end
		local ok, conn = pcall(function()
			return signal:Connect(fn)
		end)
		if ok and conn then
			connections[#connections + 1] = conn
			return true
		end
		return false
	end

	local function isPressInput(inputType)
		if wantedInput == Enum.UserInputType.MouseButton1 then
			return inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch
		end
		return inputType == wantedInput
	end

	local function resetState()
		mouseDownTime = 0
		isPointerDown = false
		startPosition = nil
		maxMoveDistance = 0
	end

	local function beginPointer(input)
		if disconnected then
			return
		end
		isPointerDown = true
		mouseDownTime = tick()
		maxMoveDistance = 0
		local pos = input and input.Position
		startPosition = pos and Vector2.new(pos.X, pos.Y) or nil
	end

	local function endPointer()
		if disconnected then
			return
		end
		if not isPointerDown or mouseDownTime == 0 then
			resetState()
			return
		end
		local holdDuration = tick() - mouseDownTime
		local isClick = holdDuration < clickTimeThreshold and maxMoveDistance <= moveThreshold
		resetState()
		if isClick then
			clickCallback()
		end
	end

	local boundPress = false
	local isGuiButton = type(button.IsA) == "function" and button:IsA("GuiButton")
	if isGuiButton then
		local downName = wantedInput == Enum.UserInputType.MouseButton2 and "MouseButton2Down" or "MouseButton1Down"
		local upName = wantedInput == Enum.UserInputType.MouseButton2 and "MouseButton2Up" or "MouseButton1Up"
		local downBound = connectSignal(getSignal(button, downName), function()
			beginPointer(nil)
		end)
		local upBound = connectSignal(getSignal(button, upName), function()
			endPointer()
		end)
		boundPress = downBound and upBound
	end

	if not boundPress then
		local beganBound = connectSignal(getSignal(button, "InputBegan"), function(input)
			if input and isPressInput(input.UserInputType) then
				beginPointer(input)
			end
		end)
		local endedBound = connectSignal(getSignal(button, "InputEnded"), function(input)
			if input and isPressInput(input.UserInputType) then
				endPointer()
			end
		end)
		boundPress = beganBound and endedBound
	end

	connectSignal(getSignal(button, "InputChanged"), function(input)
		if not isPointerDown then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local pos = input.Position
		if not pos then
			return
		end
		if not startPosition then
			startPosition = Vector2.new(pos.X, pos.Y)
			return
		end
		local delta = (Vector2.new(pos.X, pos.Y) - startPosition).Magnitude
		if delta > maxMoveDistance then
			maxMoveDistance = delta
		end
	end)

	if not boundPress then
		disconnectAll()
		return state
	end

	connectSignal(getSignal(button, "AncestryChanged"), function(_, parent)
		if not parent then
			task.defer(disconnectAll)
		end
	end)
	connectSignal(getSignal(button, "Destroying"), disconnectAll)

	return state
end

local NAgui = {
	_dragState = {},
	_draggerCleanups = {},
}

ctx.NAgui_dragger = function(ui, dragui)
	if not ui then
		return { Connected = false, Disconnect = function() end }
	end
	dragui = dragui or ui

	local draggerId = tostring((ui.GetDebugId and ui:GetDebugId()) or ui)
	local oldCleanup = NAgui._draggerCleanups[draggerId]
	if type(oldCleanup) == "function" then
		pcall(oldCleanup)
	end

	local ds = NAgui._dragState
	local dragging = false
	local dragStart = nil
	local startPos = nil
	local cleaned = false
	local dragPointer = nil
	local pendingInput = nil
	local connections = {}
	local moveConn = nil
	local endConn = nil
	local stepConn = nil

	local state = {
		Connected = true,
	}

	local function addConn(conn)
		if conn then
			connections[#connections + 1] = conn
		end
		return conn
	end

	local function disconnectLiveInput()
		ctx.tryDisconnect(moveConn)
		ctx.tryDisconnect(endConn)
		ctx.tryDisconnect(stepConn)
		moveConn = nil
		endConn = nil
		stepConn = nil
		pendingInput = nil
	end

	local function stopDrag()
		dragging = false
		dragPointer = nil
		pendingInput = nil
		if ds.owner == ui then
			ds.owner = nil
			ds.input = nil
		end
		disconnectLiveInput()
	end

	local function cleanupDragger()
		if cleaned then
			return
		end
		cleaned = true
		state.Connected = false
		stopDrag()
		for i = 1, #connections do
			ctx.tryDisconnect(connections[i])
			connections[i] = nil
		end
		if NAgui._draggerCleanups[draggerId] == cleanupDragger then
			NAgui._draggerCleanups[draggerId] = nil
		end
	end

	function state:Disconnect()
		cleanupDragger()
	end

	NAgui._draggerCleanups[draggerId] = cleanupDragger

	local function getOrder(g)
		local z = 0
		pcall(function()
			z = g.ZIndex or 0
		end)
		local lc = g:FindFirstAncestorWhichIsA("LayerCollector")
		local d = 0
		if lc and lc:IsA("ScreenGui") then
			pcall(function()
				d = lc.DisplayOrder or 0
			end)
		end
		return d * 10000 + z
	end

	local function isTopMost(root, input)
		if not (Guis and input and input.Position) then
			return true
		end
		local pos = input.Position
		local list = nil
		local ok = pcall(function()
			list = Guis:GetGuiObjectsAtPosition(pos.X, pos.Y)
		end)
		if not ok or type(list) ~= "table" or #list == 0 then
			return true
		end
		local top = nil
		local topOrder = nil
		for _, g in list do
			if typeof(g) == "Instance" and g:IsA("GuiObject") then
				local order = getOrder(g)
				if not top or order > topOrder then
					top = g
					topOrder = order
				end
			end
		end
		if not top then
			return true
		end
		return top == root or top:IsDescendantOf(root)
	end

	local function getParentSize()
		local parent = ui.Parent
		if parent then
			local ok, size = pcall(function()
				return parent.AbsoluteSize
			end)
			if ok and size and size.X > 0 and size.Y > 0 then
				return size
			end
		end
		local cam = Wsp and Wsp.CurrentCamera
		if cam then
			return cam.ViewportSize
		end
		return Vector2.new(1920, 1080)
	end

	local function update(input)
		if not ui or not ui.Parent or not input or not dragStart or not startPos then
			return
		end
		local delta = input.Position - dragStart
		local screenSize = getParentSize()
		if not screenSize or screenSize.X <= 0 or screenSize.Y <= 0 then
			return
		end
		local newXScale = startPos.X.Scale + (startPos.X.Offset + delta.X) / screenSize.X
		local newYScale = startPos.Y.Scale + (startPos.Y.Offset + delta.Y) / screenSize.Y
		ui.Position = UDim2.new(newXScale, 0, newYScale, 0)
	end

	addConn(dragui.InputBegan:Connect(function(input)
		if cleaned then
			return
		end
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
			and (not ds.owner or ds.owner == ui)
			and isTopMost(dragui, input) then
			ds.owner = ui
			ds.input = input
			dragging = true
			dragPointer = input
			dragStart = input.Position
			startPos = ui.Position
			disconnectLiveInput()
			if Uis then
				moveConn = Uis.InputChanged:Connect(function(changedInput)
					if not dragging or ds.owner ~= ui then
						return
					end
					local inputType = changedInput.UserInputType
					if inputType == Enum.UserInputType.MouseMovement then
						pendingInput = changedInput
					elseif inputType == Enum.UserInputType.Touch and changedInput == dragPointer then
						pendingInput = changedInput
					end
				end)
				endConn = Uis.InputEnded:Connect(function(endedInput)
					if not dragging then
						return
					end
					local inputType = endedInput.UserInputType
					if inputType == Enum.UserInputType.MouseButton1 or (inputType == Enum.UserInputType.Touch and endedInput == dragPointer) then
						stopDrag()
					end
				end)
			end
			if Run then
				stepConn = Run.RenderStepped:Connect(function()
					local frameInput = pendingInput
					if not frameInput then
						return
					end
					pendingInput = nil
					if not dragging or ds.owner ~= ui then
						return
					end
					update(frameInput)
				end)
			end
		end
	end))

	addConn(ui.AncestryChanged:Connect(function(_, parent)
		if not parent then
			task.defer(cleanupDragger)
		end
	end))
	if ui.Destroying then
		addConn(ui.Destroying:Connect(cleanupDragger))
	end
	if dragui ~= ui then
		addConn(dragui.AncestryChanged:Connect(function(_, parent)
			if not parent then
				task.defer(cleanupDragger)
			end
		end))
		if dragui.Destroying then
			addConn(dragui.Destroying:Connect(cleanupDragger))
		end
	end

	pcall(function()
		ui.Active = true
	end)
	pcall(function()
		dragui.Active = true
	end)

	return state
end

ctx.toggle = function(v)
	on = v and true or false
	tok += 1
	cur = nil
	ctx.clearLocators()
	survivedSeen = false
	ctx.setBtn()
	ctx.note(on and "Enabled" or "Disabled")
	ctx.setNc(on)
	farmTok += 1

	if not on then
		saveFlushTok += 1
		pendingSaveSig = nil
		ctx.releaseRoot()
		ctx.killPlat()
		return
	end

	ctx.startFarmRemotes()
	task.spawn(ctx.burstLoaded)
	ctx.requestPlayerData(true)

	if ctx.inState("InGame") then
		ctx.note("Resuming current map")
	else
		ctx.doLift()
	end
end

ctx.onChar = function(c)
	if not ctx.alive() then
		return
	end
	ctx.bindNc(c)
	if on then
		task.spawn(function()
			if not Lift then
				return
			end
			for _ = 1, RRP do
				if not (ctx.alive() and on) then
					return
				end
				pcall(function()
					Lift:FireServer()
				end)
				task.wait(RRG)
			end
		end)
		task.spawn(function()
			local ok, err = xpcall(ctx.pushLift, debug.traceback)
			if not ok then
				warn(err)
			end
		end)
	end
end

ctx.onMap = function(map, id)
	local hp
	local ok, err = xpcall(function()
		local r, h = ctx.rh(true)
		if not r or not h or not map or not map.Parent then
			return
		end
		safeCf = r.CFrame
		safeAt = os.clock()

		local st = ctx.ffc(map, "Settings", false)
		local nm = nil
		if st then
			local ok2, v = pcall(function()
				return st:GetAttribute("MapName")
			end)
			if ok2 then
				nm = v
			end
		end
		if not nm then
			nm = map.Name
		end

		survivedSeen = false
		ctx.note("Map Loaded! " .. tostring(nm))
		task.spawn(ctx.burstLoaded)

		if not ctx.inState("InGame") then
			ctx.note("Skipping due to InGame == false.")
			cur = nil
			return
		end

		local btns = {}
		local ok2, res = pcall(ctx.scanBtns, map)
		if ok2 and type(res) == "table" then
			btns = res
		end
		ctx.mergeLocatorBtns(btns, map)
		ctx.startAutoFarmButtonSpam(map, id, btns)

		ctx.collectMapBonuses(map, r, true)

		ctx.note("Commencing Auto Farm")

		hp = h:GetPropertyChangedSignal("Health"):Connect(function()
			pcall(function()
				if h.Parent and h.Health < 1000 then
					h.Health = 1000
				end
			end)
		end)

		roundCur = nil
		roundTotal = nil
		roundLeft = nil
		roundState = nil
		for _, rem in RoundStatsRemotes do
			if rem and rem.Parent then
				pcall(function()
					rem:FireServer()
				end)
			end
		end
		local tr = 0
		local sent = {}
		local lastPress = {}
		local pressLoops = {}
		local lastExitPulse = 0
		local waitLocSeq = nil
		local waitLocAt = 0

		while ctx.activeRun(map, id) and ctx.inState("InGame") do
			task.wait(SCI)
			if not (ctx.activeRun(map, id) and ctx.inState("InGame")) then
				break
			end

			r, h = ctx.rh(false)
			if not r or not h then
				continue
			end

			pcall(function()
				h.Jump = true
			end)

			local ex = ctx.ffc(map, "ExitRegion", true)
			ctx.mergeLocatorBtns(btns, map)
			local statsExpected = #RoundStatsRemotes > 0
			local exitReady = ex and (ctx.buttonsDone() or (not statsExpected and roundCur == nil and roundTotal == nil))

			if waitLocSeq and locSeq ~= waitLocSeq then
				waitLocSeq = nil
			end

			local pressFirst = not exitReady
			if exitReady then
				for _, entry in btns do
					if entry.loc and entry.hit and entry.hit.Parent and locBtns[entry.hit] == entry then
						pressFirst = true
						break
					end
				end
			end

			if exitReady and not pressFirst and waitLocSeq and os.clock() - waitLocAt < LHW then
				ctx.mkPlat(r)
				continue
			end

			if pressFirst then
				for _, entry in btns do
					if not ctx.activeRun(map, id) then
						break
					end

					local b = entry.src
					local hit = entry.hit
					local key = entry.loc and entry or hit
					local currentLoc = not entry.loc or locBtns[hit] == entry
					local canPress = entry.loc or not (exitReady and sent[key])
					if currentLoc and canPress and (not exitReady or entry.loc) and hit and hit.Parent then
						local ti = ctx.ffc(hit, "TouchInterest", true) or ctx.ffc(b, "TouchInterest", true)
						local gg = nil
						pcall(function()
							gg = (b and b:FindFirstChildWhichIsA("BillboardGui", true)) or hit:FindFirstChildWhichIsA("BillboardGui", true)
						end)
						if entry.loc or (ti and gg) then
							r, h = ctx.rh(false)
							if not r or not h then
								break
							end
							if not ctx.activeRun(map, id) then
								break
							end
							local fuse = ctx.isFuseBtn(b)
							pcall(function()
								r.Anchored = false
								ctx.pivotRootTo(CFrame.new(hit.Position), r)
								h:ChangeState(Enum.HumanoidStateType.Jumping)
								r.Velocity = JMP
							end)
							task.wait(TPD)
							if not ctx.activeRun(map, id) then
								ctx.releaseRoot()
								break
							end
							local now = os.clock()
							if entry.loc then
								if not lastPress[key] or now - lastPress[key] >= PCD then
									lastPress[key] = now
									ctx.pressMapButton(hit)
									waitLocSeq = entry.seq
									waitLocAt = now
								end
							elseif not sent[key] then
								sent[key] = true
								if not pressLoops[key] then
									pressLoops[key] = true
									ctx.startPressLoop(hit, id, function()
										return ctx.activeRun(map, id) and ctx.inState("InGame") and not ctx.buttonsDone()
									end)
								end
								ctx.pressMapButton(hit)
							end
							if fuse then
								ctx.moveFuseSafe(b, hit, r, function()
									return ctx.activeRun(map, id)
								end)
							else
								pcall(function()
									ctx.pivotRootTo(CFrame.new(hit.Position + Vector3.new(0, ESY, 0)), r)
									r.Anchored = true
								end)
							end
							task.wait(BTD)
							if not ctx.activeRun(map, id) then
								ctx.releaseRoot()
								break
							end
						end
					end
				end
			else
				if not ctx.activeRun(map, id) then
					break
				end
				pcall(function()
					r.Anchored = false
				end)
				if tr < EXM then
					tr += 1
					pcall(function()
						ctx.pivotRootTo(ex.CFrame, r)
						h:ChangeState(Enum.HumanoidStateType.Landed)
						r.Velocity = EXP
					end)
					ctx.mkPlat(r)
					task.wait(TPD)
					if not ctx.activeRun(map, id) then
						ctx.releaseRoot()
						break
					end
					if (r.Position - ex.Position).Magnitude <= 5 then
						tr += 1
						ctx.fireSurvived(ctx.getPassArg(false), 100)
						local now = os.clock()
						if now - lastExitPulse >= 0.5 then
							lastExitPulse = now
							ctx.statPulse(false)
							ctx.statBurst()
							if pendingSaveSig == nil then
								ctx.flushStatsAfterSurvival()
							end
						end
					end
				else
					tr = 0
					ctx.mkPlat(r)
					task.wait(TPD)
					if not ctx.activeRun(map, id) then
						ctx.releaseRoot()
						break
					end
				end
			end
		end
	end, debug.traceback)

	ctx.cut(hp)

	if not ok then
		warn(err)
		ctx.note("Map handler error; continuing")
	end

	if not ctx.activeRun(map, id) then
		ctx.clearLocators()
		ctx.releaseRoot()
		return
	end

	local r = select(1, ctx.rh(false))
	if r then
		ctx.mkPlat(r)
	end

	if not (ctx.alive() and on) then
		return
	end

	ctx.note("Complete. Waiting for next map..")

	while ctx.alive() and on do
		task.wait(0.2)
		local m = MP and MP:FindFirstChild("Map") or nil
		local rr = select(1, ctx.rh(false))
		if rr then
			ctx.mkPlat(rr)
		end
		if m and m ~= map then
			ctx.clearLocators()
			break
		end
	end
end

ctx.curMap = function()
	if not MP or not MP.Parent then
		MP = Wsp and (Wsp:FindFirstChild("Multiplayer") or Wsp:WaitForChild("Multiplayer", 3)) or nil
	end
	return MP and (MP:FindFirstChild("Map") or MP:FindFirstChild("NewMap")) or nil
end

ctx.rootPart = function()
	local c = ctx.chr(false)
	if not c then
		return nil
	end
	return c:FindFirstChild("HumanoidRootPart", true)
end

ctx.startButtonAura = function()
	auraTok += 1
	local id = auraTok
	ctx.spawnLoop(function()
		local map = nil
		local req = 0
		while ctx.alive() and auraTok == id do
			if not auraOn then
				task.wait(0.1)
				map = nil
				auraList = {}
				auraMap = nil
				continue
			end

			local m = ctx.curMap()
			if m ~= map then
				map = m
				auraList = {}
				auraMap = nil
			end

			local now = os.clock()
			if now >= req then
				ctx.requestRoundStats()
				req = now + 0.25
			end

			if map and ctx.isRoundIngame() and type(ctx.pressMapButton) == "function" then
				local entries, hasLoc = ctx.auraEntries(map)
				if #entries > 0 then
					ctx.pressAuraEntries(entries, map, not hasLoc)
				end
			end

			task.wait(ASI)
		end
	end)
end

ctx.fireChallenge = function(n, ...)
	local t = ChallengeRemotes[n]
	if type(t) ~= "table" then
		return false
	end
	local fired = false
	for _, rem in t do
		if rem and rem.Parent then
			local ok = pcall(function(...)
				rem:FireServer(...)
			end, ...)
			fired = fired or ok
		end
	end
	return fired
end

ctx.fireZipline = function(part)
	if not (part and part.Parent) then
		return false
	end
	local fired = ctx.fireChallenge("RideZipline", part)
	for _, rem in ZiplineRemotes.RideZipline do
		if rem and rem.Parent then
			local ok = pcall(function()
				rem:FireServer(part)
			end)
			fired = fired or ok
		end
	end
	for _, rem in ZiplineRemotes.Zipline do
		if rem and rem.Parent then
			local ok = pcall(function()
				rem:FireServer(part)
			end)
			fired = fired or ok
		end
	end
	return fired
end

ctx.wallData = function(wall, r, c)
	if not (wall and wall.Parent and wall:IsA("BasePart")) then
		return nil
	end
	r = r or select(1, ctx.rh(false))
	c = c or ctx.chr(false)
	local rp = r and r.Position or (wall.Position + wall.CFrame.LookVector * 4)
	local pos = wall.Position
	local norm = nil
	local dir = wall.Position - rp
	if dir.Magnitude > 0.05 and Wsp then
		local prm = RaycastParams.new()
		prm.FilterType = Enum.RaycastFilterType.Exclude
		local ex = {}
		if c then
			ex[#ex + 1] = c
		end
		if Wsp.CurrentCamera then
			ex[#ex + 1] = Wsp.CurrentCamera
		end
		prm.FilterDescendantsInstances = ex
		local ok, hit = pcall(function()
			return Wsp:Raycast(rp, dir.Unit * math.min(dir.Magnitude + 6, 12), prm)
		end)
		if ok and hit and hit.Instance == wall then
			pos = hit.Position
			norm = hit.Normal
		end
	end
	if not norm then
		norm = rp - wall.Position
		norm = Vector3.new(norm.X, 0, norm.Z)
		if norm.Magnitude < 0.05 then
			norm = wall.CFrame.LookVector
		end
		norm = norm.Unit
	end
	local c0 = wall.CFrame:ToObjectSpace(CFrame.new(pos + norm * 0.5, pos + norm))
	return pos, norm, c0
end

ctx.fireWalljump = function(wall, c0)
	if not (wall and wall.Parent) then
		return false
	end
	local fired = false
	for _, rem in WalljumpRemotes.Walljump do
		if rem and rem.Parent then
			local ok = pcall(function()
				if c0 ~= nil then
					rem:FireServer(wall, c0)
				else
					rem:FireServer(wall)
				end
			end)
			fired = fired or ok
		end
	end
	fired = ctx.fireChallenge("Walljumped", wall) or fired
	return fired
end

ctx.releaseWalljump = function()
	local r, h, c = ctx.rh(false)
	for _, rem in WalljumpRemotes.Walljump do
		if rem and rem.Parent then
			pcall(function()
				rem:FireServer()
			end)
		end
	end
	if r and r.Parent then
		for _, ch in r:GetChildren() do
			if ch.ClassName == "ManualWeld" and (ch.Name == "WalljumpWeld_Live" or ch.Name == "WalljumpWeld_Server") then
				pcall(function()
					ch.Part0 = nil
					ch.Part1 = nil
					ch:Destroy()
				end)
			end
		end
	end
	if h then
		pcall(function()
			h.AutoRotate = true
			h:SetStateEnabled(Enum.HumanoidStateType.Running, true)
			h:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			h:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
			h:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
			h:ChangeState(Enum.HumanoidStateType.Jumping)
		end)
	end
	local ps = LP and LP:FindFirstChild("PlayerScripts")
	local main = ps and ps:FindFirstChild("CL_MAIN_GameScript")
	local tv = main and main:FindFirstChild("ToggleVelocity")
	if tv and tv.Fire then
		pcall(function()
			tv:Fire(true)
		end)
	end
end

ctx.jumpOffWall = function(wall, norm)
	local r, h = ctx.rh(false)
	if not (r and r.Parent) then
		return
	end
	norm = norm or Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
	if norm.Magnitude < 0.05 then
		norm = Vector3.new(0, 0, -1)
	end
	norm = norm.Unit
	local cfg = wall and wall:FindFirstChild("_Wall")
	local ang = 45
	if cfg then
		local a = cfg:GetAttribute("JumpAngle")
		if type(a) == "number" then
			ang = math.clamp(a, -90, 90)
		end
	end
	local sp = 70.71
	local cf = CFrame.new(Vector3.new(), norm)
	local lv = (cf * CFrame.Angles(math.rad(ang), 0, 0)).LookVector
	ctx.releaseWalljump()
	pcall(function()
		r.AssemblyLinearVelocity = Vector3.new(lv.X * sp, math.max(48, lv.Y * sp), lv.Z * sp)
		r.AssemblyAngularVelocity = Vector3.zero
		if h then
			h:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
end

ctx.dumpChallenges = function()
	return
end

ctx.addChallengeHit = function(list, obj)
	if obj and not list[obj] then
		list[obj] = true
	end
end

ctx.remChallengeHit = function(list, obj)
	if obj then
		list[obj] = nil
	end
end

ctx.clearChallengeIndex = function()
	chTok += 1
	for _, c in chCons do
		ctx.cut(c)
	end
	chCons = {}
	chIndex = { air = {}, wall = {}, zip = {}, slide = {} }
	chCache = chIndex
end

ctx.airHitbox = function(obj)
	if not obj then
		return nil
	end
	if obj.Name == "AirTank" then
		local hb = obj:FindFirstChild("Hitbox")
		if hb and hb:IsA("BasePart") then
			return hb
		end
	elseif obj:IsA("BasePart") and obj.Name == "Hitbox" and obj.Parent and obj.Parent.Name == "AirTank" then
		return obj
	end
	return nil
end

ctx.indexChallengeObj = function(obj)
	if not obj then
		return
	end
	local hb = ctx.airHitbox(obj)
	if hb then
		ctx.addChallengeHit(chIndex.air, hb)
	end
	if obj:IsA("BasePart") then
		if obj:FindFirstChild("_Wall") then
			ctx.addChallengeHit(chIndex.wall, obj)
		elseif obj.Name == "RopeStart" then
			ctx.addChallengeHit(chIndex.zip, obj)
		elseif obj.Name == "SlideBeam" then
			ctx.addChallengeHit(chIndex.slide, obj)
		end
	end
end

ctx.unindexChallengeObj = function(obj)
	if not obj then
		return
	end
	local hb = ctx.airHitbox(obj)
	if hb then
		ctx.remChallengeHit(chIndex.air, hb)
	end
	ctx.remChallengeHit(chIndex.air, obj)
	ctx.remChallengeHit(chIndex.wall, obj)
	ctx.remChallengeHit(chIndex.zip, obj)
	ctx.remChallengeHit(chIndex.slide, obj)
end

ctx.seedChallengeRoot = function(root, id)
	if not (root and root.Parent) then
		return
	end
	ctx.indexChallengeObj(root)
	local q = { root }
	local qi = 1
	local steps = 0
	while ctx.alive() and chTok == id and qi <= #q do
		local obj = q[qi]
		qi += 1
		if obj and obj.Parent then
			ctx.indexChallengeObj(obj)
			local ok, kids = pcall(obj.GetChildren, obj)
			if ok and type(kids) == "table" then
				for _, ch in kids do
					q[#q + 1] = ch
				end
			end
		end
		steps += 1
		if steps % 120 == 0 then
			task.wait()
		end
	end
end

ctx.bindChallengeRoot = function(root, id, seed)
	if not (root and root.Parent) then
		return
	end
	chCons[#chCons + 1] = root.DescendantAdded:Connect(function(obj)
		if chTok == id then
			ctx.indexChallengeObj(obj)
		end
	end)
	chCons[#chCons + 1] = root.DescendantRemoving:Connect(function(obj)
		if chTok == id then
			ctx.unindexChallengeObj(obj)
		end
	end)
	if seed ~= false then
		task.spawn(function()
			ctx.seedChallengeRoot(root, id)
		end)
	end
end

ctx.ensureChallenges = function(map)
	if not (map and map.Parent) then
		if chMap ~= nil then
			chMap = nil
			ctx.clearChallengeIndex()
		end
		return false
	end
	if chMap == map then
		return true
	end
	chMap = map
	ctx.clearChallengeIndex()
	local id = chTok
	chSeen = setmetatable({}, { __mode = "k" })
	chWallSeen = setmetatable({}, { __mode = "k" })
	chZipSeen = setmetatable({}, { __mode = "k" })
	chSlideSeen = setmetatable({}, { __mode = "k" })
	chSlideAt = 0
	chWallAt = 0
	chZipAt = 0
	chAirAt = 0
	ctx.bindChallengeRoot(map, id, true)
	local deb = Wsp and Wsp:FindFirstChild("Debris")
	if deb then
		ctx.bindChallengeRoot(deb, id, false)
	end
	return true
end

ctx.listFromIndex = function(src, root)
	local out = {}
	local deb = Wsp and Wsp:FindFirstChild("Debris")
	for obj in src do
		if obj and obj.Parent and ((root and obj:IsDescendantOf(root)) or (deb and obj:IsDescendantOf(deb))) then
			out[#out + 1] = obj
		else
			src[obj] = nil
		end
	end
	return out
end

ctx.challengeHits = function(map)
	if not ctx.ensureChallenges(map) then
		return { air = {}, wall = {}, zip = {}, slide = {} }
	end
	return {
		air = ctx.listFromIndex(chIndex.air, map),
		wall = ctx.listFromIndex(chIndex.wall, map),
		zip = ctx.listFromIndex(chIndex.zip, map),
		slide = ctx.listFromIndex(chIndex.slide, map),
	}
end

ctx.feScript = function()
	local c = ctx.chr(false)
	if not c then
		return nil
	end
	local fe = c:FindFirstChild("FE2_Character")
	if fe then
		return fe
	end
	return nil
end

ctx.feEnv = function()
	local fe = ctx.feScript()
	if not (fe and type(getsenv) == "function") then
		return nil
	end
	local ok, env = pcall(getsenv, fe)
	if ok and type(env) == "table" then
		return env
	end
	return nil
end

ctx.slidePts = function(bm, r)
	if not (bm and bm.Parent and bm:IsA("BasePart")) then
		return nil
	end
	local sx = bm.Size.X
	local sz = bm.Size.Z
	local ax = sx >= sz and bm.CFrame.RightVector or bm.CFrame.LookVector
	ax = Vector3.new(ax.X, 0, ax.Z)
	if ax.Magnitude < 0.05 then
		ax = r and Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z) or Vector3.new(1, 0, 0)
	end
	ax = ax.Unit
	local len = math.max(sx, sz)
	local a = bm.Position - ax * math.max(8, len * 0.48)
	local b = bm.Position + ax * math.max(28, len * 0.48)
	local y = bm.Position.Y - math.max(2.25, bm.Size.Y * 0.5 + 1.75)
	return Vector3.new(a.X, y, a.Z), Vector3.new(b.X, y, b.Z), ax
end

ctx.trySlideChallenge = function(list, remoteOnly)
	local now = os.clock()
	if now - chSlideAt < 6 then
		return false
	end
	list = type(list) == "table" and list or {}
	local r, h, c = ctx.rh(false)
	if not (r and r.Parent and h and c and c.Parent) then
		return false
	end
	local best = nil
	local bestDist = math.huge
	for _, bm in list do
		if bm and bm.Parent then
			local t = chSlideSeen[bm]
			if not t or now - t > 8 then
				local d = (r.Position - bm.Position).Magnitude
				if d < bestDist then
					best = bm
					bestDist = d
				end
			end
		end
	end
	local p1, p2, dir
	if best then
		p1, p2, dir = ctx.slidePts(best, r)
	else
		return false
	end
	if not (p1 and p2 and dir) then
		return false
	end
	chSlideAt = now
	if best then
		chSlideSeen[best] = now
	end
	if remoteOnly == true then
		return ctx.fireChallenge("SlideCheck", p1, Vector3.new(p2.X, p1.Y, p2.Z))
	end
	local old = r.CFrame
	local ok = false
	local env = ctx.feEnv()
	pcall(function()
		ctx.pivotRootTo(CFrame.new(p1, p1 + dir), r, c)
		r.AssemblyLinearVelocity = Vector3.zero
		r.AssemblyAngularVelocity = Vector3.zero
	end)
	task.wait(0.05)
	local fe = ctx.feScript()
	local sl = fe and fe:FindFirstChild("Slide")
	if sl and sl:IsA("BindableEvent") then
		pcall(function()
			sl:Fire(nil, Enum.UserInputState.Begin, best ~= nil)
		end)
	end
	if env and type(env.runSlide) == "function" then
		pcall(env.runSlide, nil, Enum.UserInputState.Begin, best ~= nil)
	end
	task.wait(0.12)
	pcall(function()
		ctx.pivotRootTo(CFrame.new(p2, p2 + dir), r, c)
		r.AssemblyLinearVelocity = Vector3.zero
		r.AssemblyAngularVelocity = Vector3.zero
	end)
	task.wait(0.05)
	if env and type(env.endSlide) == "function" then
		ok = pcall(env.endSlide, p1) or ok
	end
	ok = ctx.fireChallenge("SlideCheck", p1, Vector3.new(p2.X, p1.Y, p2.Z)) or ok
	if old and r and r.Parent and on then
		task.delay(0.15, function()
			if ctx.alive() and on and r and r.Parent then
				pcall(function()
					ctx.pivotRootTo(old, r, c)
					r.AssemblyLinearVelocity = Vector3.zero
					r.AssemblyAngularVelocity = Vector3.zero
				end)
			end
		end)
	end
	return ok
end

ctx.tryWallChallenge = function(list, remoteOnly)
	local now = os.clock()
	if now - chWallAt < 3 then
		return false
	end
	list = type(list) == "table" and list or {}
	local r, h, c = ctx.rh(false)
	local best = nil
	local bestDist = math.huge
	for _, wall in list do
		if wall and wall.Parent and not chWallSeen[wall] then
			local dist = r and (r.Position - wall.Position).Magnitude or 0
			if dist < bestDist then
				best = wall
				bestDist = dist
			end
		end
	end
	if not best then
		return false
	end
	chWallSeen[best] = now
	chWallAt = now
	local pos, norm, c0 = ctx.wallData(best, r, c)
	if remoteOnly == true then
		local ok = ctx.fireWalljump(best, c0)
		task.delay(0.08, function()
			if ctx.alive() then
				ctx.releaseWalljump()
			end
		end)
		return ok
	end
	if not (r and r.Parent and c and c.Parent and pos and norm) then
		local ok = ctx.fireWalljump(best, c0)
		task.delay(0.08, function()
			if ctx.alive() then
				ctx.releaseWalljump()
			end
		end)
		return ok
	end
	local ok = false
	pcall(function()
		ctx.pivotRootTo(CFrame.new(pos + norm * 1.35 + Vector3.new(0, 1.5, 0), pos), r, c)
		r.AssemblyLinearVelocity = Vector3.zero
		r.AssemblyAngularVelocity = Vector3.zero
		if h then
			h.AutoRotate = false
			h:ChangeState(Enum.HumanoidStateType.Freefall)
		end
	end)
	task.wait(0.08)
	ok = ctx.fireWalljump(best, c0) or ok
	task.wait(0.12)
	ctx.jumpOffWall(best, norm)
	task.delay(0.25, function()
		if ctx.alive() then
			ctx.releaseWalljump()
		end
	end)
	return ok
end

ctx.tryZipChallenge = function(list, remoteOnly)
	local now = os.clock()
	if zipBusy or now - chZipAt < 8 then
		return false
	end
	list = type(list) == "table" and list or {}
	local r, h, c = ctx.rh(false)
	if not (r and r.Parent and c and c.Parent) then
		return false
	end
	local best = nil
	local bestDist = math.huge
	for _, rope in list do
		if rope and rope.Parent then
			local t = chZipSeen[rope]
			if not t or now - t > 10 then
				local dist = (r.Position - rope.Position).Magnitude
				if dist < bestDist then
					best = rope
					bestDist = dist
				end
			end
		end
	end
	if not best then
		return false
	end
	chZipSeen[best] = now
	chZipAt = now
	if remoteOnly == true then
		return ctx.fireZipline(best)
	end
	zipBusy = true
	task.spawn(function()
		local ok, err = xpcall(function()
			local rr, hh, cc = ctx.rh(false)
			if not (rr and rr.Parent and cc and cc.Parent and best and best.Parent) then
				return
			end
			local old = rr.CFrame
			pcall(function()
				ctx.pivotRootTo(best.CFrame + Vector3.new(0, 1.5, 0), rr, cc)
				rr.AssemblyLinearVelocity = Vector3.zero
				rr.AssemblyAngularVelocity = Vector3.zero
			end)
			task.wait(0.08)
			local feh = ctx.getFeHitbox()
			if feh and feh.Parent and type(firetouchinterest) == "function" then
				pcall(firetouchinterest, feh, best, 0)
				pcall(firetouchinterest, best, feh, 0)
				task.wait(0.05)
				pcall(firetouchinterest, feh, best, 1)
				pcall(firetouchinterest, best, feh, 1)
			end
			local env = ctx.feEnv()
			local used = false
			if env and type(env.startZipline) == "function" then
				used = pcall(env.startZipline, best) or used
			end
			if not used then
				ctx.fireZipline(best)
			else
				ctx.fireZipline(best)
			end
			task.delay(0.35, function()
				if ctx.alive() and on and rr and rr.Parent and old then
					pcall(function()
						rr.AssemblyLinearVelocity = Vector3.zero
						rr.AssemblyAngularVelocity = Vector3.zero
					end)
				end
			end)
		end, debug.traceback)
		if not ok then
			warn(err)
		end
		zipBusy = false
	end)
	return true
end

ctx.getFeHitbox = function()
	local c = ctx.chr(false)
	if not c then
		return nil
	end
	local hb = c:FindFirstChild("FE2_Hitbox")
	if hb and hb:IsA("BasePart") then
		return hb
	end
	return nil
end

ctx.touchAirTank = function(hb, remoteOnly)
	if not (hb and hb.Parent and hb:IsA("BasePart")) then
		return false
	end
	local now = os.clock()
	local last = chSeen[hb]
	if last and now - last < 2.5 then
		return false
	end
	local r, h = ctx.rh(false)
	if not (r and r.Parent) or (h and h.Health <= 0) then
		return false
	end
	local dist = (r.Position - hb.Position).Magnitude
	if remoteOnly == true then
		chSeen[hb] = now
		return ctx.fireChallenge("GetAirBubble", hb)
	end
	if dist > 10 then
		return false
	end
	chSeen[hb] = now
	local fe = ctx.getFeHitbox()
	local ok = false
	if fe and fe.Parent and type(firetouchinterest) == "function" then
		pcall(firetouchinterest, fe, hb, 0)
		pcall(firetouchinterest, hb, fe, 0)
		task.wait(0.05)
		pcall(firetouchinterest, fe, hb, 1)
		pcall(firetouchinterest, hb, fe, 1)
		ok = true
	end
	if hb and hb.Parent then
		ok = ctx.fireChallenge("GetAirBubble", hb) or ok
	end
	return ok
end

ctx.tryAirChallenges = function(list, remoteOnly)
	local now = os.clock()
	if now - chAirAt < 1.5 then
		return false
	end
	chAirAt = now
	list = type(list) == "table" and list or {}
	local r = select(1, ctx.rh(false))
	if not (r and r.Parent) then
		return false
	end
	local best = nil
	local bestDist = remoteOnly == true and math.huge or 10
	for _, hb in list do
		if hb and hb.Parent then
			local t = chSeen[hb]
			if not t or now - t > 6 then
				local d = (r.Position - hb.Position).Magnitude
				if d <= bestDist then
					best = hb
					bestDist = d
				end
			end
		end
	end
	return best and ctx.touchAirTank(best, remoteOnly) or false
end

ctx.doChallenges = function(map, remoteOnly)
	if not (autoChallenges and ctx.isRoundIngame()) then
		return
	end
	ctx.dumpChallenges()
	local now = os.clock()
	if now - chRegAt > 3 then
		chRegAt = now
		ctx.fireChallenge("RegeneratedAir", 9999)
	end
	if now - chLavaAt > 5 then
		chLavaAt = now
		ctx.fireChallenge("SwimInLava")
	end
	local hits = ctx.challengeHits(map)
	ctx.tryAirChallenges(hits.air, remoteOnly == true)
	ctx.trySlideChallenge(hits.slide, remoteOnly == true)
	ctx.tryWallChallenge(hits.wall, remoteOnly == true)
	ctx.tryZipChallenge(hits.zip, remoteOnly == true)
end

ctx.startChallenges = function()
	ctx.spawnLoop(function()
		while ctx.alive() do
			if autoChallenges then
				ctx.doChallenges(ctx.curMap(), not on)
			end
			task.wait(CHI)
		end
	end)
end

ctx.startBonusCollector = function()
	ctx.spawnLoop(function()
		while ctx.alive() do
			if autoCollectBonuses and ctx.isRoundIngame() then
				local map = ctx.curMap()
				if map then
					local r = select(1, ctx.rh(false))
					ctx.collectMapBonuses(map, r, true)
				end
			end
			task.wait(0.35)
		end
	end)
end

if MP then
	ctx.bind(MP.ChildAdded:Connect(function(ch)
		if (ch.Name == "Map" or ch.Name == "NewMap") and on then
			task.spawn(ctx.burstLoaded)
		end
	end))
end

ctx.mkUi = function()
	local par = ctx.uiPar()
	if not par then
		return
	end

	local old = ctx.ffc(par, "AF_Toggle", false)
	if old then
		pcall(function()
			old:Destroy()
		end)
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "AF_Toggle"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = par

	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 190, 0, 105)
	panel.Position = UDim2.new(0.5, -95, 0, 10)
	panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	panel.BorderSizePixel = 0
	panel.Active = true
	panel.Parent = gui

	btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 40)
	btn.Position = UDim2.new(0, 10, 0, 10)
	btn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 18
	btn.Text = "Start AutoFarm"
	btn.Active = true
	btn.Parent = panel

	optBtn = Instance.new("TextButton")
	optBtn.Size = UDim2.new(1, -20, 0, 40)
	optBtn.Position = UDim2.new(0, 10, 0, 55)
	optBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	optBtn.TextColor3 = Color3.new(1, 1, 1)
	optBtn.Font = Enum.Font.SourceSansBold
	optBtn.TextSize = 18
	optBtn.Text = "Options v"
	optBtn.Active = true
	optBtn.Parent = panel

	optionsFrame = Instance.new("Frame")
	optionsFrame.Name = "Options"
	optionsFrame.Size = UDim2.new(1, -20, 0, 220)
	optionsFrame.Position = UDim2.new(0, 10, 0, 100)
	optionsFrame.BackgroundTransparency = 1
	optionsFrame.Visible = false
	optionsFrame.Parent = panel

	auraBtn = Instance.new("TextButton")
	auraBtn.Size = UDim2.new(1, 0, 0, 35)
	auraBtn.Position = UDim2.new(0, 0, 0, 0)
	auraBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	auraBtn.TextColor3 = Color3.new(1, 1, 1)
	auraBtn.Font = Enum.Font.SourceSansBold
	auraBtn.TextSize = 16
	auraBtn.Text = "Button Aura: OFF"
	auraBtn.Active = true
	auraBtn.Parent = optionsFrame

	distModeBtn = Instance.new("TextButton")
	distModeBtn.Size = UDim2.new(1, 0, 0, 35)
	distModeBtn.Position = UDim2.new(0, 0, 0, 45)
	distModeBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 210)
	distModeBtn.TextColor3 = Color3.new(1, 1, 1)
	distModeBtn.Font = Enum.Font.SourceSansBold
	distModeBtn.TextSize = 16
	distModeBtn.Text = "Button Distance: ON"
	distModeBtn.Active = true
	distModeBtn.Parent = optionsFrame

	distRow = Instance.new("Frame")
	distRow.Size = UDim2.new(1, 0, 0, 35)
	distRow.Position = UDim2.new(0, 0, 0, 90)
	distRow.BackgroundTransparency = 1
	distRow.Parent = optionsFrame

	distLabel = Instance.new("TextLabel")
	distLabel.Size = UDim2.new(0.48, 0, 1, 0)
	distLabel.Position = UDim2.new(0, 0, 0, 0)
	distLabel.BackgroundTransparency = 1
	distLabel.TextColor3 = Color3.new(1, 1, 1)
	distLabel.Font = Enum.Font.SourceSansBold
	distLabel.TextSize = 16
	distLabel.TextXAlignment = Enum.TextXAlignment.Left
	distLabel.Text = "Aura Dist:"
	distLabel.Parent = distRow

	distBtn = Instance.new("TextBox")
	distBtn.Size = UDim2.new(0.5, 0, 1, 0)
	distBtn.Position = UDim2.new(0.5, 0, 0, 0)
	distBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	distBtn.TextColor3 = Color3.new(1, 1, 1)
	distBtn.Font = Enum.Font.SourceSansBold
	distBtn.TextSize = 16
	distBtn.Text = "7"
	distBtn.PlaceholderText = "1-100"
	distBtn.ClearTextOnFocus = false
	distBtn.Active = true
	distBtn.Parent = distRow

	bonusBtn = Instance.new("TextButton")
	bonusBtn.Size = UDim2.new(1, 0, 0, 35)
	bonusBtn.Position = UDim2.new(0, 0, 0, 135)
	bonusBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 210)
	bonusBtn.TextColor3 = Color3.new(1, 1, 1)
	bonusBtn.Font = Enum.Font.SourceSansBold
	bonusBtn.TextSize = 16
	bonusBtn.Text = "Collect Bonuses: ON"
	bonusBtn.Active = true
	bonusBtn.Parent = optionsFrame

	chBtn = Instance.new("TextButton")
	chBtn.Size = UDim2.new(1, 0, 0, 35)
	chBtn.Position = UDim2.new(0, 0, 0, 180)
	chBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	chBtn.TextColor3 = Color3.new(1, 1, 1)
	chBtn.Font = Enum.Font.SourceSansBold
	chBtn.TextSize = 16
	chBtn.Text = "Challenges: OFF"
	chBtn.Active = true
	chBtn.Parent = optionsFrame

	ctx.bind(ctx.NAgui_dragger(panel))

	ctx.bind(ctx.MouseButtonFix(btn, function()
		ctx.toggle(not on)
	end))

	ctx.bind(ctx.MouseButtonFix(optBtn, function()
		ctx.setOptionsOpen(not optionsOpen)
	end))

	ctx.bind(ctx.MouseButtonFix(auraBtn, function()
		auraOn = not auraOn
		ctx.setAuraBtn()
	end))

	ctx.bind(ctx.MouseButtonFix(distModeBtn, function()
		auraUseDistance = not auraUseDistance
		ctx.setDistModeBtn()
	end))

	ctx.bind(distBtn.FocusLost:Connect(function()
		local n = tonumber(distBtn.Text)
		if n then
			auraDist = math.clamp(math.floor(n + 0.5), 1, 100)
		end
		ctx.setDistBtn()
	end))

	ctx.bind(ctx.MouseButtonFix(bonusBtn, function()
		autoCollectBonuses = not autoCollectBonuses
		ctx.setBonusBtn()
	end))

	ctx.bind(ctx.MouseButtonFix(chBtn, function()
		autoChallenges = not autoChallenges
		ctx.setChallengeBtn()
	end))

	ctx.setBtn()
	ctx.setOptionsOpen(false)
	ctx.setAuraBtn()
	ctx.setDistModeBtn()
	ctx.setDistBtn()
	ctx.setBonusBtn()
	ctx.setChallengeBtn()
end

ctx.mkUi()
ctx.startPassiveRemotes()
ctx.startButtonAura()
ctx.startBonusCollector()
ctx.startChallenges()

if LP then
	chC = LP.CharacterAdded:Connect(ctx.onChar)
	if LP.Character then
		task.spawn(ctx.onChar, LP.Character)
	end
end

ctx.antiVoid(ctx.curMap)
ctx.note("Ready")

task.spawn(function()
	while ctx.alive() do
		local ok, err = xpcall(function()
			task.wait(SCI)
			if not on then
				return
			end
			local m = ctx.curMap()
			local ig = ctx.inState("InGame")
			if m and ig and m ~= cur then
				cur = m
				tok += 1
				local id = tok
				ctx.note("New Map")
				ctx.onMap(m, id)
			elseif not m or not ig then
				cur = nil
			end
		end, debug.traceback)

		if not ok then
			warn(err)
			ctx.note("Loop error; continuing")
			task.wait(0.25)
		end
	end
end)
