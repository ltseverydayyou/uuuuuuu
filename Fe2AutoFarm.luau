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
	if type(old.opt) == "table" then
		old.opt.fePhysicsOn = true
	end
	if type(old.applyFeMovement) == "function" then
		pcall(old.applyFeMovement)
	end
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
	ui = {},
	opt = {},
	cache = {},
	flood = {},
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

ctx.protectedScreen = function(name)
	local gui = nil
	if __NAUIProtector and type(__NAUIProtector.getScreenGui) == "function" then
		local ok, res = pcall(__NAUIProtector.getScreenGui, name)
		if ok and typeof(res) == "Instance" then
			gui = res
		end
	end
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = name
		local par = nil
		if __NAUIProtector and type(__NAUIProtector.parent) == "function" then
			local ok, res = pcall(__NAUIProtector.parent)
			if ok and typeof(res) == "Instance" then
				par = res
			end
		end
		if not par then
			local cg = type(ctx.gt) == "function" and ctx.gt("CoreGui") or nil
			local ps = type(ctx.gt) == "function" and ctx.gt("Players") or nil
			local lp = ps and ps.LocalPlayer or nil
			par = ctx.gethui() or cg or (lp and lp:FindFirstChildOfClass("PlayerGui"))
		end
		if not par then
			return nil
		end
		pcall(function()
			gui.Parent = par
		end)
	end
	pcall(function()
		gui.Name = name
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	end)
	ctx.__NAProtectUI(gui, {
		name = name,
		keepName = true,
		harden = true,
		deep = true,
		watch = true,
		rename = false,
	})
	return gui
end

ctx.pruneCons = function()
	for i = #ctx.con, 1, -1 do
		local c = ctx.con[i]
		if not c or c.Connected == false then
			table.remove(ctx.con, i)
		end
	end
end

ctx.bind = function(c)
	if c then
		ctx.con[#ctx.con + 1] = c
		if #ctx.con % 32 == 0 then
			ctx.pruneCons()
		end
	end
	return c
end

ctx.dropThread = function(th)
	for i = #ctx.threads, 1, -1 do
		if ctx.threads[i] == th then
			table.remove(ctx.threads, i)
			return
		end
	end
end

ctx.spawnLoop = function(fn, ...)
	local args = table.pack(...)
	local th
	th = task.spawn(function()
		local ok, err = xpcall(function()
			return fn(table.unpack(args, 1, args.n))
		end, debug.traceback)
		args = nil
		if not ok and (type(ctx.current) ~= "function" or ctx.current()) then
			warn(err)
		end
		ctx.dropThread(th)
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

ctx.clearCons = function(t)
	if type(t) ~= "table" then
		return
	end
	for i = #t, 1, -1 do
		ctx.cut(t[i])
		t[i] = nil
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
ctx.hs = ctx.gt("HttpService")
ctx.cfgPath = "ltseverydayyou-fe2/gay.json"
ctx.cfgDir = "ltseverydayyou-fe2"
ctx.gameProfiles = {
	[323675642] = "FE2",
	[761462079] = "FEM",
	[4229990801] = "FE2CM",
}
ctx.placeProfiles = {
	[12339127827] = "FE2_Retro",
	[11951199229] = "FE2CM",
	[12074120006] = "FE2CM",
	[14708572114] = "FE2CM",
}
ctx.fe2cmPlaces = {
	[11951199229] = true,
	[12074120006] = true,
	[14708572114] = true,
}
ctx.profileName = function()
	ctx.tmpPlaceId = nil
	pcall(function()
		ctx.tmpPlaceId = game.PlaceId
	end)
	if ctx.placeProfiles[ctx.tmpPlaceId] then
		return ctx.placeProfiles[ctx.tmpPlaceId]
	end
	ctx.tmpGameId = nil
	pcall(function()
		ctx.tmpGameId = game.GameId
	end)
	return ctx.gameProfiles[ctx.tmpGameId] or ("Game_" .. tostring(ctx.tmpGameId or "Unknown"))
end

ctx.placeId = function()
	ctx.tmpPlaceId = nil
	pcall(function()
		ctx.tmpPlaceId = game.PlaceId
	end)
	return ctx.tmpPlaceId
end

ctx.gameId = function()
	ctx.tmpGameId = nil
	pcall(function()
		ctx.tmpGameId = game.GameId
	end)
	return ctx.tmpGameId
end

ctx.isFE2CMGame = function()
	return ctx.gameId() == 4229990801 or ctx.fe2cmPlaces[ctx.placeId()] == true
end

ctx.isFE2Game = function()
	return ctx.gameId() == 323675642 or ctx.placeId() == 12339127827 or ctx.isFE2CMGame()
end

ctx.isRetroGame = function()
	return ctx.placeId() == 12339127827
end

ctx.isFEMGame = function()
	return ctx.gameId() == 761462079
end

ctx.support = function(k)
	if ctx.isFEMGame() then
		return ({
			start = true,
			aura = true,
			bonus = false,
			challenges = false,
			flood = false,
			paid = true,
			shop = true,
			clip = false,
			rescue = false,
			dev = false,
			zip = true,
			infAir = true,
			infJump = true,
			clickTp = true,
			next = true,
			femVote = true,
			survive = false,
		})[k] == true
	end
	if ctx.isRetroGame() then
		return ({
			start = true,
			aura = true,
			bonus = false,
			challenges = false,
			flood = false,
			paid = true,
			shop = true,
			clip = true,
			rescue = false,
			dev = false,
			zip = false,
			infAir = true,
			infJump = true,
			clickTp = true,
			next = true,
			femVote = false,
			survive = true,
		})[k] == true
	end
	if ctx.isFE2CMGame() then
		return ({
			start = true,
			aura = true,
			bonus = true,
			challenges = true,
			flood = true,
			paid = true,
			shop = true,
			clip = true,
			rescue = true,
			dev = true,
			zip = true,
			infAir = true,
			infJump = true,
			clickTp = true,
			next = true,
			femVote = false,
			survive = true,
		})[k] == true
	end
	if ctx.isFE2Game() then
		return ({
			start = true,
			aura = true,
			bonus = true,
			challenges = true,
			flood = true,
			paid = true,
			shop = true,
			clip = true,
			rescue = true,
			dev = true,
			zip = true,
			infAir = true,
			infJump = true,
			clickTp = true,
			next = true,
			femVote = false,
			survive = true,
		})[k] == true
	end
	return k == "start" or k == "infJump" or k == "clickTp"
end
local MP = Wsp and (Wsp:FindFirstChild("Multiplayer") or Wsp:WaitForChild("Multiplayer", 10)) or nil

local TPD = 0.05
local BTD = 0.05
local SCI = 0.08
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
local PCD = 0.1 -- Button press cooldown per button/locator hit
local RFD = { 0, 0.25, 0.75, 1.5, 3, 5 }
local FDM = 160
local VLM = 20
local RCH = 12
local LDB = 6
local LDI = 0.1
local BSI = 0.1 -- Direct button spam loop wait floor
local ASI = 0.1 -- Button aura spam loop interval
local PLI = 2 -- Loaded remote interval
local PSI = 0.1 -- Survived remote spam interval
local PMW = 0.1 -- Passive remote loop wait / tick speed
local FMI = 0.2
local RSI = 3
local SRI = 1.5
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
local plt
local cTab = {}
local locBtns = {}
local pressTimes = setmetatable({}, { __mode = "k" })
local pressWin = 0
local pressCnt = 0
local pressMax = 12
local pressGap = 0.1
local pressBudget = 3
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
ctx.opt.floodOn = true
ctx.opt.floodEnabled = true
ctx.opt.floodRandom = false
ctx.cache.floodTok = 0
ctx.cache.floodHooks = setmetatable({}, { __mode = "k" })
ctx.cache.uiTok = 0
ctx.cache.uiHooks = setmetatable({}, { __mode = "k" })
ctx.opt.passOn = true
ctx.opt.paidOn = true
ctx.opt.clipOn = false
ctx.opt.fePhysicsOn = false
ctx.opt.fpPartOn = false
ctx.opt.rescueOn = false
ctx.opt.devOn = false
ctx.opt.wallLvl = 0
ctx.opt.zipFastOn = false
ctx.opt.zipSpeed = 90
ctx.opt.zipStopOn = true
ctx.opt.zipAutoOn = true
ctx.opt.zipActive = false
ctx.opt.infAirOn = false
ctx.opt.infJumpOn = false
ctx.opt.clickTpOn = false
ctx.opt.femVoteOn = false
ctx.opt.surviveLoopOn = true
ctx.opt.claimBusy = false
ctx.opt.shopBusy = false
ctx.cache.zipOld = setmetatable({}, { __mode = "k" })
ctx.cache.zipWatches = setmetatable({}, { __mode = "k" })
ctx.cache.remoteByName = {}
ctx.cache.auraPromptCons = {}
ctx.cache.zipPromptCons = {}
ctx.cache.godAt = 0
ctx.cache.zipAt = 0
ctx.cache.zipConn = nil
ctx.cache.zipChar = nil
ctx.cache.airHum = nil
ctx.cache.airHealthConn = nil
ctx.cache.airDiedConn = nil
ctx.cache.airHooked = false
ctx.cache.airAlertEnv = nil
ctx.cache.airAlertOld = nil
ctx.cache.femStarted = false
ctx.cache.femVoteAt = 0
ctx.cache.femLastVoteId = nil
ctx.cache.femBtnStarted = false
ctx.cache.femButtonPart = nil
ctx.cache.femZipStarted = false
ctx.cache.femZipStopStarted = false
ctx.cache.femRopeData = nil
ctx.cache.femRopeOld = setmetatable({}, { __mode = "k" })
ctx.cache.jumpAt = 0
ctx.cache.wallAt = 0
ctx.cache.slideAt = 0
ctx.cache.swimAt = 0
ctx.flood.floodColors = {
	water = Color3.fromHSV(0.6, 0.99, 0.99),
	acid = Color3.fromHSV(0.33, 0.99, 0.99),
	lava = Color3.fromHSV(0.01, 0.99, 0.99),
}

ctx.cfgKeys = {
	"auraOn",
	"auraUseDistance",
	"auraDist",
	"autoCollectBonuses",
	"autoChallenges",
	"floodOn",
	"floodEnabled",
	"floodRandom",
	"paidOn",
	"clipOn",
	"fePhysicsOn",
	"rescueOn",
	"devOn",
	"zipFastOn",
	"zipSpeed",
	"zipStopOn",
	"zipAutoOn",
	"infAirOn",
	"infJumpOn",
	"clickTpOn",
	"femVoteOn",
	"surviveLoopOn",
}

ctx.getSetting = function(k)
	if k == "auraOn" then
		return auraOn
	elseif k == "auraUseDistance" then
		return auraUseDistance
	elseif k == "auraDist" then
		return auraDist
	elseif k == "autoCollectBonuses" then
		return autoCollectBonuses
	elseif k == "autoChallenges" then
		return autoChallenges
	elseif ctx.opt[k] ~= nil then
		return ctx.opt[k]
	end
	return nil
end

ctx.setSetting = function(k, v)
	if k == "auraOn" then
		auraOn = v == true
	elseif k == "auraUseDistance" then
		auraUseDistance = v ~= false
	elseif k == "auraDist" then
		if type(v) == "number" then
			auraDist = math.clamp(v, 0, 1000)
		end
	elseif k == "autoCollectBonuses" then
		autoCollectBonuses = v == true
	elseif k == "autoChallenges" then
		autoChallenges = v == true
	elseif ctx.opt[k] ~= nil then
		if type(ctx.opt[k]) == "number" then
			ctx.opt[k] = tonumber(v) or ctx.opt[k]
		else
			ctx.opt[k] = v == true
		end
	end
end

ctx.fs = ctx.fs or {}
ctx.fs.dir = ctx.cfgDir
ctx.fs.path = ctx.cfgPath
ctx.fs.ready = function()
	ctx.fs.hasRead = type(readfile) == "function"
	ctx.fs.hasWrite = type(writefile) == "function"
	ctx.fs.hasIsFile = type(isfile) == "function"
	ctx.fs.hasIsFolder = type(isfolder) == "function"
	ctx.fs.hasMakeFolder = type(makefolder) == "function"
	ctx.fs.hasDeleteFile = type(delfile) == "function"
	ctx.fs.hasListFiles = type(listfiles) == "function"
	ctx.fs.hasAppendFile = type(appendfile) == "function"
	ctx.fs.hasLoadFile = type(loadfile) == "function"
	return ctx.fs.hasRead and ctx.fs.hasWrite and ctx.fs.hasIsFile
end

ctx.fs.jsonEncode = function(t)
	if not ctx.hs then
		return nil
	end
	ctx.fs.ok, ctx.fs.res = pcall(function()
		return ctx.hs:JSONEncode(t)
	end)
	if ctx.fs.ok and type(ctx.fs.res) == "string" then
		return ctx.fs.res
	end
	return nil
end

ctx.fs.jsonDecode = function(s)
	if not ctx.hs then
		return nil
	end
	ctx.fs.ok, ctx.fs.res = pcall(function()
		return ctx.hs:JSONDecode(s)
	end)
	if ctx.fs.ok and type(ctx.fs.res) == "table" then
		return ctx.fs.res
	end
	return nil
end

ctx.fs.ensure = function()
	if not ctx.fs.ready() then
		return false
	end
	if ctx.fs.hasIsFolder and ctx.fs.hasMakeFolder then
		pcall(function()
			if not isfolder(ctx.fs.dir) then
				makefolder(ctx.fs.dir)
			end
		end)
	end
	return true
end

ctx.fs.write = function(path, txt)
	if not ctx.fs.ensure() or type(txt) ~= "string" then
		return false
	end
	ctx.fs.ok = pcall(writefile, path, txt)
	return ctx.fs.ok == true
end

ctx.fs.read = function(path)
	if not ctx.fs.ready() then
		return nil
	end
	ctx.fs.ok, ctx.fs.res = pcall(function()
		if not isfile(path) then
			return nil
		end
		return readfile(path)
	end)
	if ctx.fs.ok and type(ctx.fs.res) == "string" then
		return ctx.fs.res
	end
	return nil
end

ctx.readCfgRoot = function()
	ctx.tmpTxt = ctx.fs.read(ctx.cfgPath)
	if type(ctx.tmpTxt) ~= "string" or ctx.tmpTxt == "" then
		return {}
	end
	ctx.tmpData = ctx.fs.jsonDecode(ctx.tmpTxt)
	if type(ctx.tmpData) == "table" then
		return ctx.tmpData
	end
	return {}
end

ctx.profileCfg = function(root)
	ctx.tmpProfile = ctx.profileName()
	if type(root) ~= "table" then
		return {}
	end
	if type(root[ctx.tmpProfile]) == "table" then
		return root[ctx.tmpProfile]
	end
	for _, k in ctx.cfgKeys do
		if root[k] ~= nil then
			return root
		end
	end
	return {}
end

ctx.saveNow = function()
	ctx.tmpRootCfg = ctx.readCfgRoot()
	ctx.tmpProfile = ctx.profileName()
	ctx.tmpCfg = {}
	for _, k in ctx.cfgKeys do
		ctx.tmpCfg[k] = ctx.getSetting(k)
	end
	ctx.tmpRootCfg[ctx.tmpProfile] = ctx.tmpCfg
	ctx.tmpTxt = ctx.fs.jsonEncode(ctx.tmpRootCfg)
	if type(ctx.tmpTxt) ~= "string" then
		return false
	end
	return ctx.fs.write(ctx.cfgPath, ctx.tmpTxt)
end

ctx.saveSoon = function()
	ctx.cache.saveTok = (ctx.cache.saveTok or 0) + 1
	task.delay(0.2, function(tk)
		if ctx.alive() and ctx.cache.saveTok == tk then
			ctx.saveNow()
		end
	end, ctx.cache.saveTok)
end

ctx.loadSettings = function()
	ctx.tmpRootCfg = ctx.readCfgRoot()
	ctx.tmpData = ctx.profileCfg(ctx.tmpRootCfg)
	if type(ctx.tmpData) ~= "table" then
		return false
	end
	for _, k in ctx.cfgKeys do
		if ctx.tmpData[k] ~= nil then
			ctx.setSetting(k, ctx.tmpData[k])
		end
	end
	return true
end

ctx.loadSettings()
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
	pressTimes = setmetatable({}, { __mode = "k" })
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
	ctx.opt.fePhysicsOn = true
	if type(ctx.applyFeMovement) == "function" then
		pcall(ctx.applyFeMovement)
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
	ctx.cut(ctx.cache.zipConn)
	ctx.cut(ctx.cache.infAirHb)
	ctx.cut(ctx.cache.airHealthConn)
	ctx.cut(ctx.cache.airDiedConn)
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
	ctx.cache.zipConn = nil
	ctx.cache.infAirHb = nil
	ctx.cache.airHealthConn = nil
	ctx.cache.airDiedConn = nil
	ctx.cache.airHealthHum = nil
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
	if ctx.unprotectAirHealth then
		ctx.unprotectAirHealth()
	end
	ctx.clearLocators()
	auraList = {}
	auraMap = nil
	auraAt = 0
	pressWin = 0
	pressCnt = 0
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
	if type(ctx.closeAuraPrompt) == "function" then
		ctx.closeAuraPrompt()
	elseif ctx.ui.auraPrompt then
		pcall(function()
			ctx.ui.auraPrompt:Destroy()
		end)
		ctx.ui.auraPrompt = nil
	end
	if type(ctx.closeZipPrompt) == "function" then
		ctx.closeZipPrompt()
	elseif ctx.ui.zipPrompt then
		pcall(function()
			ctx.ui.zipPrompt:Destroy()
		end)
		ctx.ui.zipPrompt = nil
	end
	if gui and gui.Parent then
		pcall(function()
			gui:Destroy()
		end)
	end
	if ctx.ui.rootIcon then
		pcall(function()
			ctx.ui.rootIcon:destroy()
		end)
	end
	if type(ctx.ui.menu) == "table" then
		for _, ic in ctx.ui.menu do
			if ic and type(ic.destroy) == "function" then
				pcall(function()
					ic:destroy()
				end)
			end
		end
	end
	gui = nil
	btn = nil
	panel = nil
	ctx.ui.optBtn = nil
	ctx.ui.optionsFrame = nil
	ctx.ui.auraBtn = nil
	ctx.ui.distModeBtn = nil
	ctx.ui.distBtn = nil
	ctx.ui.distLabel = nil
	ctx.ui.distRow = nil
	ctx.ui.bonusBtn = nil
	ctx.ui.chBtn = nil
	ctx.ui.floodBtn = nil
	ctx.ui.passBtn = nil
	ctx.ui.paidBtn = nil
	ctx.ui.buyCoinBtn = nil
	ctx.ui.buyGemBtn = nil
	ctx.ui.clipBtn = nil
	ctx.ui.rescueBtn = nil
	ctx.ui.devBtn = nil
	ctx.ui.zipBtn = nil
	ctx.ui.zipStopBtn = nil
	ctx.ui.zipAutoBtn = nil
	ctx.ui.infAirBtn = nil
	ctx.ui.infJumpBtn = nil
	ctx.ui.clickTpBtn = nil
	ctx.ui.femVoteBtn = nil
	ctx.ui.surviveBtn = nil
	ctx.ui.nextBtn = nil
	ctx.ui.rootIcon = nil
	ctx.ui.menu = {}
	ctx.cache.floodTok += 1
	ctx.cache.uiTok += 1
	ctx.cache.floodHooks = setmetatable({}, { __mode = "k" })
	ctx.cache.uiHooks = setmetatable({}, { __mode = "k" })
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
	ctx.cache.remoteByName = {}
	ctx.cache.zipOld = setmetatable({}, { __mode = "k" })
	ctx.cache.zipWatches = setmetatable({}, { __mode = "k" })
	ctx.cache.femRopeOld = setmetatable({}, { __mode = "k" })
	ctx.cache.femRopeData = nil
	ctx.cache.shopItems = nil
	ctx.cache.airEnv = nil
	ctx.cache.femSwim = nil
	if host and host.__lt_af_ctx == ctx then
		host.__lt_af_ctx = nil
	end
end

ctx.descOf = function(obj)
	if not obj then
		return {}
	end
	local ok, res = pcall(function()
		return obj:GetDescendants()
	end)
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
local ItemDataFunction = nil
local ConfirmItemRemote = nil
local PassReqSeasonData = nil
local PassReqSeasonList = nil
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

	local rb = findRemote("ReqRebirth", "RemoteEvent") or findRemote("rebirth", "RemoteEvent") or findRemote("LxWowhVdggjbxLTozuicVKHltFbUuVUg", "RemoteEvent")
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
	addRemote(PlayerDataRemotes, "mbTUpXEtICXoMoBrBEoiHpRywCzJjtba")
	addRemote(ItemDataRemotes, "ReqItemData")
	addRemote(ItemDataRemotes, "jBRXdUHKhwduqDelrUCPdolYbvaFGFMi")
	local idf = findRemote("ReqItemData", "RemoteFunction")
	if idf and idf:IsA("RemoteFunction") then
		ItemDataFunction = idf
	end
	ConfirmItemRemote = findRemote("ConfirmItem", "RemoteEvent") or findRemote("IBHzeWzRcHyDJcPNXXfEkcXARFJrSvvt", "RemoteEvent")
	do
		local rr = Rsp and Rsp:FindFirstChild("Remote")
		local pf = rr and rr:FindFirstChild("Pass")
		local rsd = pf and (pf:FindFirstChild("ReqSeasonData") or pf:FindFirstChild("wYXTxuCjheiXJfcizJPuPwrfonMOVMVJ"))
		local rsl = pf and (pf:FindFirstChild("ReqSeasonList") or pf:FindFirstChild("eumTfRpsBhpIbMhPbsgBhNWijGPZcWZZ"))
		PassReqSeasonData = rsd and rsd:IsA("RemoteEvent") and rsd or nil
		PassReqSeasonList = rsl and rsl:IsA("RemoteEvent") and rsl or nil
	end
	addRemote(GameStateRemotes, "UpdateGameState")
	addRemote(GameStateRemotes, "FBbJEWQDfbOPQZBNaWtXPmnKTDndEbbK")
	addRemote(ChallengeRemotes.GetAirBubble, "GetAirBubble")
	addRemote(ChallengeRemotes.SwimInLava, "SwimInLava")
	addRemote(ChallengeRemotes.SwimInLava, "fvgxdrskCQyGiyAbJXnVrzFRinSqigYN")
	addRemote(ChallengeRemotes.RegeneratedAir, "RegeneratedAir")
	addRemote(ChallengeRemotes.RegeneratedAir, "ZdwUWbHbtYFphslKtWDPwBpPOrOQbGPZ")
	addRemote(ChallengeRemotes.SlideCheck, "SlideCheck")
	addRemote(ChallengeRemotes.Walljumped, "Walljumped")
	addRemote(ChallengeRemotes.Walljumped, "cLtjGlpevadbSJSvVQMCvNicyzbFZMGj")
	addFolderRemote(ChallengeRemotes.RideZipline, chFolder, "RideZipline")
	addFolderRemote(ZiplineRemotes.RideZipline, rmt, "RideZipline")
	addRemote(ZiplineRemotes.Zipline, "Zipline")
	addFolderRemote(ZiplineRemotes.Zipline, gpFolder, "Zipline")
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
		bScanAt = now + 0.3 -- Bonus cache rescan throttle after DescendantAdded/GetDescendants changes
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

ctx.addBtnEntry = function(t, src, hit, loc, retro)
	if not hit or not hit:IsA("BasePart") then
		return
	end
	t[#t + 1] = {
		src = src or hit,
		hit = hit,
		loc = loc and true or false,
		retro = retro and true or false,
	}
end

ctx.scanBtns = function(map)
	local t = {}
	for _, obj in ctx.descOf(map) do
		if obj.ClassName == "Model" then
			if ctx.isRetroGame() and tostring(obj.Name):match("^_Button%d+$") then
				local hit = obj:FindFirstChild("Hitbox", true)
				if hit and hit:IsA("BasePart") then
					ctx.addBtnEntry(t, obj, hit, false, true)
				end
				continue
			end
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
	if ctx.isRetroGame() then
		table.sort(t, function(a, b)
			local aSrc = a and (a.src or a.hit)
			local bSrc = b and (b.src or b.hit)
			local aNum = tonumber(tostring(aSrc and aSrc.Name or ""):match("%d+"))
			local bNum = tonumber(tostring(bSrc and bSrc.Name or ""):match("%d+"))
			if aNum and bNum then
				return aNum < bNum
			end
			if aNum then
				return true
			end
			if bNum then
				return false
			end
			return false
		end)
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
	if entry.retro then
		return true
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
	if auraMap ~= map or now - auraAt > 0.6 then
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
	local used = 0
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
			return ctx.pressMapButton(hit) == true
		end
		return false
	end

	for i = #entries, 1, -1 do
		local entry = entries[i]
		local hit = entry and entry.hit
		if not (hit and hit.Parent and (not map or hit:IsDescendantOf(map))) then
			table.remove(entries, i)
		elseif used < pressBudget and (not auraUseDistance or (hb and hb.Parent and (hb.Position - hit.Position).Magnitude <= maxDist)) then
			used += 1
			if type(ctx.pressMapButton) == "function" and ctx.pressMapButton(hit) then
				pressed = true
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
		return false
	end
	local now = os.clock()
	local last = pressTimes[hit]
	if last and now - last < PCD then
		return false
	end
	if now - pressWin >= pressGap then
		pressWin = now
		pressCnt = 0
	end
	if pressCnt >= pressMax then
		return false
	end
	pressCnt += 1
	pressTimes[hit] = now
	if ctx.isRetroGame() and type(firetouchinterest) == "function" then
		local r = type(ctx.rootPart) == "function" and ctx.rootPart() or nil
		if r and r.Parent then
			pcall(firetouchinterest, r, hit, 0)
			pcall(firetouchinterest, hit, r, 0)
			task.wait(0.03)
			pcall(firetouchinterest, r, hit, 1)
			pcall(firetouchinterest, hit, r, 1)
		end
	end
	local fired = false
	for _, rem in PressRemotes do
		if rem and rem.Parent then
			local ok = pcall(function()
				rem:FireServer(hit)
			end)
			fired = fired or ok
		end
	end
	return fired
end

ctx.startPressLoop = function(hit, runId, keepGoing)
	if not hit or not hit.Parent then
		return
	end
	ctx.spawnLoop(function()
		local tries = 0
		local t0 = os.clock()
		while ctx.alive() and on and tok == runId and hit and hit.Parent and tries < 30 and os.clock() - t0 < 3 do
			if type(keepGoing) == "function" and not keepGoing() then
				break
			end
			if ctx.pressMapButton(hit) then
				tries += 1
			end
			task.wait(math.max(BSI, PCD))
		end
	end)
end

ctx.startAutoFarmButtonSpam = function(map, runId, entries)
	if not map or not map.Parent then
		return
	end
	entries = type(entries) == "table" and entries or {}
	ctx.spawnLoop(function()
		local idx = 1
		while ctx.activeRun(map, runId) and ctx.inState("InGame") do
			ctx.mergeLocatorBtns(entries, map)
			if not ctx.buttonsDone() then
				local total = #entries
				local tried = 0
				local done = 0
				while total > 0 and tried < total and done < pressBudget do
					if idx > #entries then
						idx = 1
					end
					local entry = entries[idx]
					local hit = entry and entry.hit
					if hit and hit.Parent and hit:IsDescendantOf(map) then
						ctx.pressMapButton(hit)
						done += 1
						idx += 1
					else
						table.remove(entries, idx)
						if idx > #entries then
							idx = 1
						end
					end
					tried += 1
				end
			end
			task.wait(BSI)
		end
	end)
end

ctx.retroButtonsDone = function(entries, sent)
	entries = type(entries) == "table" and entries or {}
	sent = type(sent) == "table" and sent or {}
	local hasRetro = false
	for _, entry in entries do
		if entry and entry.retro then
			local hit = entry.hit
			if hit and hit.Parent then
				hasRetro = true
				if not sent[hit] then
					return false
				end
			end
		end
	end
	return hasRetro
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
	ctx.tmpHasSurvived = false
	for _, rem in SurvivedRemotes do
		if rem and rem.Parent then
			ctx.tmpHasSurvived = true
			break
		end
	end
	if not ctx.tmpHasSurvived and os.clock() >= (ctx.cache.surviveFindAt or 0) then
		ctx.addRemoteOnce(SurvivedRemotes, ctx.findRemoteNamed("Survived"))
		ctx.cache.surviveFindAt = os.clock() + 3
	end
	ctx.tmpSurvivedFired = false
	for _, rem in SurvivedRemotes do
		if rem and rem.Parent then
			if key ~= nil then
				ctx.tmpOk = pcall(function() rem:FireServer(key, tm) end)
				ctx.tmpSurvivedFired = ctx.tmpSurvivedFired or ctx.tmpOk
				ctx.tmpOk = pcall(function() rem:FireServer(key) end)
				ctx.tmpSurvivedFired = ctx.tmpSurvivedFired or ctx.tmpOk
			end
			ctx.tmpOk = pcall(function() rem:FireServer(tm) end)
			ctx.tmpSurvivedFired = ctx.tmpSurvivedFired or ctx.tmpOk
			ctx.tmpOk = pcall(function() rem:FireServer() end)
			ctx.tmpSurvivedFired = ctx.tmpSurvivedFired or ctx.tmpOk
		end
	end
	return ctx.tmpSurvivedFired
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
	if ItemDataFunction and ItemDataFunction.Parent then
		local ok, data, items = pcall(function()
			if key ~= nil then
				return ItemDataFunction:InvokeServer(key, LP, true)
			end
			return ItemDataFunction:InvokeServer(nil, LP, true)
		end)
		if ok then
			ctx.cacheData(data)
			if type(items) == "table" then
				ctx.cache.shopItems = items
			end
		end
	end
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
	ctx.spawnLoop(function()
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
	ctx.spawnLoop(function()
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
		local ka = 0
		local sk = nil
		while ctx.alive() do
			if ctx.isFEMGame() then
				task.wait(0.5)
				continue
			end
			local now = os.clock()
			local playing = on or autoChallenges
			local doSurvive = ctx.opt.surviveLoopOn and ctx.isFE2Game()
			if doSurvive and now >= la then
				if now >= ka then
					sk = ctx.getPassArg(false)
					ka = now + 3
				end
				ctx.fireLoaded(sk)
				la = now + PLI
			end
			if doSurvive and now >= sa then
				if now >= ka then
					sk = ctx.getPassArg(false)
					ka = now + 3
				end
				ctx.fireSurvived(sk, 100)
				sa = now + PSI
			end
			if playing and now >= ra then
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
		ctx.bind(rem.OnClientEvent:Connect(function(data, items)
			ctx.cacheData(data)
			if type(items) == "table" then
				ctx.cache.shopItems = items
			end
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
	ctx.spawnLoop(function()
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

ctx.uiLabel = function(o, t)
	if not o then
		return
	end
	if type(o.setLabel) == "function" then
		pcall(function()
			o:setLabel(t)
		end)
	else
		pcall(function()
			o.Text = t
		end)
	end
end

ctx.uiColor = function(o, c)
	if not o then
		return
	end
	if type(o.modifyTheme) == "function" then
		pcall(function()
			o:modifyTheme({
				{ "IconButton", "BackgroundColor3", c },
				{ "IconOverlay", "BackgroundColor3", c },
			})
		end)
	else
		pcall(function()
			o.BackgroundColor3 = c
		end)
	end
end

ctx.setTopBtn = function(o, t, st, col)
	ctx.uiLabel(o, t)
	ctx.uiColor(o, col or (st and Color3.fromRGB(60, 130, 210) or Color3.fromRGB(70, 70, 70)))
end

ctx.setBtn = function()
	ctx.setTopBtn(ctx.ui.startBtn or btn, on and "Stop AutoFarm" or "Start AutoFarm", on, on and Color3.fromRGB(180, 60, 60) or Color3.fromRGB(60, 180, 60))
end

ctx.setAuraBtn = function()
	ctx.setTopBtn(ctx.ui.auraBtn, auraOn and "Button Aura: ON" or "Button Aura: OFF", auraOn)
end

ctx.setDistModeBtn = function()
	ctx.setTopBtn(ctx.ui.distModeBtn, auraUseDistance and "Button Distance: ON" or "Button Distance: OFF", auraUseDistance)
end

ctx.setDistBtn = function()
	ctx.setTopBtn(ctx.ui.distBtn, "Aura Dist: " .. tostring(auraDist), false, Color3.fromRGB(55, 55, 55))
end

ctx.setBonusBtn = function()
	ctx.setTopBtn(ctx.ui.bonusBtn, autoCollectBonuses and "Collect Bonuses: ON" or "Collect Bonuses: OFF", autoCollectBonuses)
end

ctx.setChallengeBtn = function()
	ctx.setTopBtn(ctx.ui.chBtn, autoChallenges and "Challenges: ON" or "Challenges: OFF", autoChallenges)
end

ctx.setFloodBtn = function()
	ctx.setTopBtn(ctx.ui.floodBtn, ctx.opt.floodOn and "Custom Flood: ON" or "Custom Flood: OFF", ctx.opt.floodOn)
end

ctx.setPassBtn = function()
end

ctx.setPaidBtn = function()
	ctx.setTopBtn(ctx.ui.paidBtn, ctx.opt.paidOn and "Paid UI Locks: ON" or "Paid UI Locks: OFF", ctx.opt.paidOn)
end

ctx.setBuyCoinBtn = function()
	ctx.setTopBtn(ctx.ui.buyCoinBtn, ctx.opt.shopBusy and "Buying Shop Items..." or "Buy Coin Shop Items", ctx.opt.shopBusy, ctx.opt.shopBusy and Color3.fromRGB(155, 89, 182) or Color3.fromRGB(218, 165, 32))
end

ctx.setBuyGemBtn = function()
	ctx.setTopBtn(ctx.ui.buyGemBtn, ctx.opt.shopBusy and "Buying Shop Items..." or "Buy Gem Shop Items", ctx.opt.shopBusy, ctx.opt.shopBusy and Color3.fromRGB(155, 89, 182) or Color3.fromRGB(142, 68, 173))
end

ctx.setClipBtn = function()
	ctx.setTopBtn(ctx.ui.clipBtn, ctx.opt.clipOn and "No SideClip TP: ON" or "No SideClip TP: OFF", ctx.opt.clipOn)
end

ctx.setFePhysicsBtn = function()
	ctx.setTopBtn(ctx.ui.fePhysBtn, ctx.opt.fePhysicsOn and "FE2 Physics: ON" or "FE2 Physics: OFF", ctx.opt.fePhysicsOn, ctx.opt.fePhysicsOn and Color3.fromRGB(180, 90, 45) or Color3.fromRGB(60, 130, 210))
end

ctx.setFpPartBtn = function()
end

ctx.setRescueBtn = function()
	ctx.setTopBtn(ctx.ui.rescueBtn, ctx.opt.rescueOn and "Hide Rescue NPC: ON" or "Hide Rescue NPC: OFF", ctx.opt.rescueOn)
end

ctx.setDevBtn = function()
	ctx.setTopBtn(ctx.ui.devBtn, ctx.opt.devOn and "DevTools: ON" or "DevTools: OFF", ctx.opt.devOn)
end

ctx.setWallBtn = function()
end

ctx.setSwimBtn = function()
end

ctx.setSlidePhysBtn = function()
end

ctx.setZipBtn = function()
	ctx.setTopBtn(ctx.ui.zipBtn, ctx.opt.zipFastOn and ("Zip Speed: " .. tostring(ctx.opt.zipSpeed)) or "Zip Speed: OFF", ctx.opt.zipFastOn)
end

ctx.setZipStopBtn = function()
	ctx.setTopBtn(ctx.ui.zipStopBtn, ctx.opt.zipStopOn and "Zip Stop Velocity: ON" or "Zip Stop Velocity: OFF", ctx.opt.zipStopOn)
end

ctx.setZipAutoBtn = function()
	ctx.setTopBtn(ctx.ui.zipAutoBtn, ctx.opt.zipAutoOn and "Zip Auto Apply: ON" or "Zip Auto Apply: OFF", ctx.opt.zipAutoOn)
end

ctx.setInfAirBtn = function()
	ctx.setTopBtn(ctx.ui.infAirBtn, ctx.opt.infAirOn and "Inf Air: ON" or "Inf Air: OFF", ctx.opt.infAirOn)
end

ctx.setInfJumpBtn = function()
	ctx.setTopBtn(ctx.ui.infJumpBtn, ctx.opt.infJumpOn and "Inf Jump: ON" or "Inf Jump: OFF", ctx.opt.infJumpOn)
end

ctx.setClickTpBtn = function()
	ctx.setTopBtn(ctx.ui.clickTpBtn, ctx.opt.clickTpOn and "Click TP: ON" or "Click TP: OFF", ctx.opt.clickTpOn)
end

ctx.setFemVoteBtn = function()
	ctx.setTopBtn(ctx.ui.femVoteBtn, ctx.opt.femVoteOn and "FEM Auto Vote: ON" or "FEM Auto Vote: OFF", ctx.opt.femVoteOn)
end

ctx.setSurviveBtn = function()
	ctx.setTopBtn(ctx.ui.surviveBtn, ctx.opt.surviveLoopOn and "Survived Loop: ON" or "Survived Loop: OFF", ctx.opt.surviveLoopOn)
end

ctx.setOptionsOpen = function(open)
	optionsOpen = open and true or false
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
	pressWin = 0
	pressCnt = 0
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
	ctx.spawnLoop(ctx.burstLoaded)
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
	ctx.hookZipStop(c)
	if ctx.opt.zipFastOn and ctx.opt.zipAutoOn then
		task.defer(ctx.reapplyZipSpeed)
	end
	if on then
		ctx.spawnLoop(function()
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
		ctx.spawnLoop(function()
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
		ctx.spawnLoop(ctx.burstLoaded)

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
			if ctx.isRetroGame() then
				exitReady = ex and ctx.retroButtonsDone(btns, sent)
			end

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
						if entry.loc or entry.retro or (ti and gg) then
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
			if not ctx.isFEMGame() and now >= req then
				ctx.requestRoundStats()
				req = now + 0.75
			end

			if ctx.isFEMGame() and type(ctx.pressMapButton) == "function" then
				ctx.tmpRoot = select(1, ctx.rh(false))
				ctx.tmpHit = ctx.femLocatorHit()
				if ctx.tmpRoot and ctx.tmpHit and ctx.tmpHit.Parent then
					ctx.tmpDist = (ctx.tmpRoot.Position - ctx.tmpHit.Position).Magnitude
					if not auraUseDistance or ctx.tmpDist <= auraDist then
						ctx.pressMapButton(ctx.tmpHit)
					end
				end
			elseif map and ctx.isRoundIngame() and type(ctx.pressMapButton) == "function" then
				local entries, hasLoc = ctx.auraEntries(map)
				if #entries > 0 then
					ctx.pressAuraEntries(entries, map, not hasLoc)
				end
			end

			task.wait(ASI)
		end
	end)
end

ctx.addRemoteOnce = function(list, obj)
	if type(list) ~= "table" or not (obj and typeof(obj) == "Instance" and obj:IsA("RemoteEvent")) then
		return false
	end
	for _, old in list do
		if old == obj then
			return true
		end
	end
	list[#list + 1] = obj
	return true
end

ctx.findRemoteNamed = function(nm)
	if type(nm) ~= "string" or nm == "" then
		return nil
	end
	ctx.tmpCachedRemote = ctx.cache.remoteByName[nm]
	if ctx.tmpCachedRemote and ctx.tmpCachedRemote.Parent then
		return ctx.tmpCachedRemote
	end
	ctx.tmpRootRemote = Rsp and Rsp:FindFirstChild("Remote")
	ctx.tmpTestRemote = ctx.tmpRootRemote and ctx.tmpRootRemote:FindFirstChild("TEST")
	ctx.tmpFoundRemote = ctx.tmpTestRemote and ctx.tmpTestRemote:FindFirstChild(nm) or nil
	if not (ctx.tmpFoundRemote and ctx.tmpFoundRemote:IsA("RemoteEvent")) then
		ctx.tmpFoundRemote = ctx.tmpRootRemote and ctx.tmpRootRemote:FindFirstChild(nm, true) or nil
	end
	if not (ctx.tmpFoundRemote and ctx.tmpFoundRemote:IsA("RemoteEvent")) then
		pcall(function()
			for _, o in Rsp:GetDescendants() do
				if o.Name == nm and o:IsA("RemoteEvent") then
					ctx.tmpFoundRemote = o
					break
				end
			end
		end)
	end
	if not (ctx.tmpFoundRemote and ctx.tmpFoundRemote:IsA("RemoteEvent")) then
		ctx.tmpScanFns = {}
		if type(getnilinstances) == "function" then
			ctx.tmpScanFns[#ctx.tmpScanFns + 1] = getnilinstances
		end
		if type(getinstances) == "function" then
			ctx.tmpScanFns[#ctx.tmpScanFns + 1] = getinstances
		end
		for _, fn in ctx.tmpScanFns do
			ctx.tmpOk, ctx.tmpList = pcall(fn)
			if ctx.tmpOk and type(ctx.tmpList) == "table" then
				for _, o in ctx.tmpList do
					if typeof(o) == "Instance" and o.Name == nm and o:IsA("RemoteEvent") then
						ctx.tmpFoundRemote = o
						break
					end
				end
			end
			if ctx.tmpFoundRemote then
				break
			end
		end
	end
	if ctx.tmpFoundRemote and ctx.tmpFoundRemote:IsA("RemoteEvent") then
		ctx.cache.remoteByName[nm] = ctx.tmpFoundRemote
		return ctx.tmpFoundRemote
	end
	return nil
end

ctx.fireChallenge = function(n, ...)
	local t = ChallengeRemotes[n]
	if type(t) ~= "table" then
		return false
	end
	ctx.addRemoteOnce(t, ctx.findRemoteNamed(n))
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
		if ok and hit then
			local okPos, hitPos = pcall(function()
				return hit.Position
			end)
			local okNorm, hitNorm = pcall(function()
				return hit.Normal
			end)
			if okPos and hitPos then
				pos = hitPos
			end
			if okNorm and hitNorm then
				norm = hitNorm
			end
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
		ctx.spawnLoop(function()
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

ctx.envOf = function(scr)
	if not scr then
		return nil
	end
	if type(getsenv) == "function" then
		local ok, env = pcall(getsenv, scr)
		if ok and type(env) == "table" then
			return env
		end
	end
	return nil
end

ctx.gameEnv = function()
	if ctx.cache.gameEnv then
		return ctx.cache.gameEnv
	end
	local m = ctx.mainScript()
	ctx.cache.gameEnv = ctx.envOf(m)
	return ctx.cache.gameEnv
end

ctx.baseEnv = function()
	if ctx.cache.baseEnv ~= nil then
		return ctx.cache.baseEnv ~= false and ctx.cache.baseEnv or nil
	end
	if type(getfenv) == "function" then
		local ok, env = pcall(getfenv)
		if ok and type(env) == "table" then
			ctx.cache.baseEnv = env
			return env
		end
	end
	ctx.cache.baseEnv = type(_G) == "table" and _G or false
	return ctx.cache.baseEnv ~= false and ctx.cache.baseEnv or nil
end

ctx.scriptGlobal = function(env, name)
	if type(env) == "table" then
		local v = rawget(env, name)
		if v ~= nil then
			return v
		end
		local g = rawget(env, "_G")
		if type(g) == "table" and rawget(g, name) ~= nil then
			return rawget(g, name)
		end
	end
	local b = ctx.baseEnv()
	if type(b) == "table" then
		if rawget(b, name) ~= nil then
			return rawget(b, name)
		end
		local g = rawget(b, "_G")
		if type(g) == "table" then
			return rawget(g, name)
		end
	end
	return nil
end

ctx.callScriptGlobal = function(env, name, ...)
	local fn = ctx.scriptGlobal(env, name)
	if type(fn) ~= "function" then
		return false
	end
	return pcall(fn, ...)
end

ctx.feEnv = function()
	ctx.tmpFeScript = ctx.feScript()
	return ctx.envOf(ctx.tmpFeScript)
end

ctx.feCall = function(name, ...)
	return ctx.callScriptGlobal(ctx.feEnv(), name, ...)
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
	list = type(list) == "table" and list or {}
	ctx.tmpWallSent = false
	for _, wall in list do
		if wall and wall.Parent and not chWallSeen[wall] then
			chWallSeen[wall] = os.clock()
			ctx.tmpWallSent = ctx.fireChallenge("Walljumped", wall) or ctx.tmpWallSent
			task.wait(0.05)
		end
	end
	return ctx.tmpWallSent
end
ctx.tryZipChallenge = function(list, remoteOnly)
	list = type(list) == "table" and list or {}
	ctx.tmpZipSent = false
	for _, rope in list do
		if rope and rope.Parent then
			ctx.tmpZipLast = chZipSeen[rope]
			if not ctx.tmpZipLast then
				chZipSeen[rope] = os.clock()
				ctx.tmpZipSent = ctx.fireChallenge("RideZipline", rope) or ctx.tmpZipSent
				task.wait(0.05)
			end
		end
	end
	return ctx.tmpZipSent
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
				ctx.doChallenges(ctx.curMap(), true)
			end
			task.wait(CHI)
		end
	end)
	ctx.spawnLoop(function()
		while ctx.alive() do
			if autoChallenges or ctx.opt.infAirOn then
				ctx.fireChallenge("RegeneratedAir", 9999)
			end
			task.wait(1)
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
			task.wait(0.3) -- Bonus collector loop interval
		end
	end)
end

ctx.floodPage = function()
	local pg = LP and LP:FindFirstChildOfClass("PlayerGui")
	local mg = pg and pg:FindFirstChild("MenuGui")
	local op = mg and mg:FindFirstChild("Options")
	local win = op and op:FindFirstChild("Window")
	local cont = win and win:FindFirstChild("Content")
	local pages = cont and cont:FindFirstChild("Pages")
	return pages and pages:FindFirstChild("CustomFloodColors") or nil
end

ctx.floodWaterScript = function()
	local ps = LP and LP:FindFirstChild("PlayerScripts")
	local misc = ps and ps:FindFirstChild("Misc")
	return misc and misc:FindFirstChild("CL_WaterColors") or nil
end

ctx.floodBind = function(obj, ev, fn)
	if not obj or ctx.cache.floodHooks[obj] then
		return
	end
	local sig = obj[ev]
	if not sig then
		return
	end
	ctx.cache.floodHooks[obj] = true
	ctx.bind(sig:Connect(fn))
end

ctx.floodCols = function()
	if not ctx.opt.floodRandom then
		return ctx.flood.floodColors
	end
	local cfg = Rsp and Rsp:FindFirstChild("Config")
	local rnd = cfg and cfg:FindFirstChild("RandomFloodColors")
	if not rnd then
		return ctx.flood.floodColors
	end
	local out = {}
	for k, v in ctx.flood.floodColors do
		local ok, c = pcall(function()
			return rnd:GetAttribute(k)
		end)
		out[k] = ok and typeof(c) == "Color3" and c or v
	end
	return out
end

ctx.floodSetProp = function(obj, prop, col)
	pcall(function()
		local old = obj[prop]
		obj[prop] = typeof(old) == "ColorSequence" and ColorSequence.new(col) or col
	end)
end

ctx.floodVisual = function(col, obj)
	if not obj then
		return
	end
	if obj:IsA("BasePart") then
		ctx.floodSetProp(obj, "Color", col)
	elseif obj:IsA("Light") then
		ctx.floodSetProp(obj, "Color", col)
	elseif obj.ClassName == "Decal" then
		ctx.floodSetProp(obj, "Color3", col)
	elseif obj.ClassName == "Smoke" then
		ctx.floodSetProp(obj, "Color", col)
	elseif obj.ClassName == "Trail" or obj.ClassName == "ParticleEmitter" or obj.ClassName == "Beam" then
		ctx.floodSetProp(obj, "Color", col)
	elseif obj.ClassName == "Fire" then
		ctx.floodSetProp(obj, "Color", col)
		ctx.floodSetProp(obj, "SecondaryColor", col)
	elseif obj.ClassName == "Sparkles" then
		ctx.floodSetProp(obj, "SparklesColor", col)
	elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
		ctx.floodSetProp(obj, "ImageColor3", col)
	end
end

ctx.floodState = function(part)
	local st = "water"
	local val = part and part:FindFirstChild("WaterState")
	pcall(function()
		if val and type(val.Value) == "string" then
			st = string.lower(val.Value)
		end
	end)
	if ctx.flood.floodColors[st] then
		return st
	end
	local nm = string.lower(part and part.Name or "")
	if string.find(nm, "acid") then
		return "acid"
	elseif string.find(nm, "lava") then
		return "lava"
	end
	return "water"
end

ctx.floodApply = function(root)
	if not (ctx.opt.floodOn and ctx.opt.floodEnabled and root) then
		return
	end
	local cols = ctx.floodCols()
	local desc = ctx.descOf(root)
	for _, obj in desc do
		if obj:IsA("BasePart") and string.find(obj.Name, "_Water") then
			local col = cols[ctx.floodState(obj)] or cols.water
			ctx.floodVisual(col, obj)
		end
	end
	for _, obj in desc do
		if obj:IsA("ObjectValue") and obj.Name == "_LinkColor" and obj.Value and obj.Value:IsA("BasePart") then
			local p = obj.Parent
			if p then
				local col = obj.Value.Color
				ctx.floodVisual(col, p)
				for _, ch in ctx.descOf(p) do
					ctx.floodVisual(col, ch)
				end
			end
		end
	end
end

ctx.floodSetHsv = function(key, nm, val)
	local h, s, v = ctx.flood.floodColors[key]:ToHSV()
	val = math.clamp(val, 0.01, 0.99)
	if nm == "Hue" then
		h = val
	elseif nm == "Saturation" then
		s = val
	elseif nm == "Value" then
		v = val
	end
	ctx.flood.floodColors[key] = Color3.fromHSV(h, s, v)
	ctx.floodPush()
end

ctx.floodStep = function(key, nm, dir)
	local h, s, v = ctx.flood.floodColors[key]:ToHSV()
	local cur = nm == "Hue" and h or nm == "Saturation" and s or v
	ctx.floodSetHsv(key, nm, cur + 0.06125 * dir)
end

ctx.floodUi = function()
	local page = ctx.floodPage()
	if not page then
		return
	end
	local buy = page:FindFirstChild("PurchaseGamepass")
	if buy then
		buy.Visible = false
		buy.Active = false
	end
	local tog = page:FindFirstChild("CustomToggle")
	if tog then
		tog.Text = ctx.opt.floodEnabled and "Enabled" or "Disabled"
		tog.BackgroundColor3 = ctx.opt.floodEnabled and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(24, 34, 44)
	end
	local rnd = page:FindFirstChild("MapRandomizer")
	if rnd then
		rnd.BackgroundColor3 = ctx.opt.floodRandom and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(24, 34, 44)
	end
	local hsv = page:FindFirstChild("HSV_Container")
	if not hsv then
		return
	end
	for key, col in ctx.flood.floodColors do
		local box = hsv:FindFirstChild(key .. "_HSV")
		if box then
			pcall(function()
				local h, ss, vv = col:ToHSV()
				local dat = {
					{ n = "Hue", v = h },
					{ n = "Saturation", v = ss },
					{ n = "Value", v = vv },
				}
				for _, it in dat do
					local cn = it.n == "Saturation" and "Sat" or it.n == "Value" and "Val" or it.n
					local obj = box.Config[cn]
					obj.Info.Text = it.n .. ": " .. tostring(math.floor(it.v * 100 * 1.021) - 1) .. "%"
					obj.Bar.Graphic.Marker:TweenPosition(UDim2.new(it.v, 0, 0.5, 0), "Out", "Sine", 0.3, true)
				end
				box.Input.HexInput.Text = "#" .. col:ToHex()
				box.Preview.BackgroundColor3 = col
				box.Config.Val.Bar.Graphic.BackgroundColor3 = Color3.fromHSV(h, ss, 1)
				box.Config.Sat.Bar.Graphic.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				box.Config.Sat.Bar.Graphic.DarknessCover.BackgroundTransparency = vv
			end)
		end
	end
end

ctx.floodPush = function()
	local wc = ctx.floodWaterScript()
	local ev = wc and wc:FindFirstChild("UpdCustomColors")
	if ev and ev.Fire then
		pcall(function()
			ev:Fire(ctx.flood.floodColors, ctx.opt.floodEnabled, ctx.opt.floodRandom, "RGB")
		end)
	end
	ctx.floodUi()
	ctx.floodApply(ctx.curMap())
end

ctx.floodHookUi = function()
	local page = ctx.floodPage()
	if not page then
		return
	end
	ctx.floodUi()
	ctx.floodBind(page:FindFirstChild("CustomToggle"), "Activated", function()
		if not ctx.opt.floodOn then
			return
		end
		ctx.opt.floodEnabled = not ctx.opt.floodEnabled
		ctx.floodPush()
	end)
	ctx.floodBind(page:FindFirstChild("MapRandomizer"), "Activated", function()
		if not ctx.opt.floodOn then
			return
		end
		ctx.opt.floodRandom = not ctx.opt.floodRandom
		ctx.floodPush()
	end)
	local hsv = page:FindFirstChild("HSV_Container")
	if not hsv then
		return
	end
	local themes = {
		Classic = { water = Color3.fromRGB(13, 105, 172), acid = Color3.fromRGB(3, 252, 3), lava = Color3.fromRGB(252, 28, 3) },
		Realism = { water = Color3.fromRGB(152, 194, 219), acid = Color3.fromRGB(117, 17, 1), lava = Color3.fromRGB(213, 115, 61) },
		Vapor = { water = Color3.fromRGB(86, 3, 252), acid = Color3.fromRGB(252, 169, 3), lava = Color3.fromRGB(3, 252, 252) },
		Soda = { water = Color3.fromRGB(252, 169, 3), acid = Color3.fromRGB(252, 84, 126), lava = Color3.fromRGB(84, 84, 252) },
	}
	local th = hsv:FindFirstChild("Themes")
	local tc = th and th:FindFirstChild("ThemeContainer")
	if tc then
		for _, b in tc:GetChildren() do
			if b:IsA("GuiButton") then
				ctx.floodBind(b, "Activated", function()
					local dat = themes[b.Text]
					if not dat then
						return
					end
					for k, v in dat do
						ctx.flood.floodColors[k] = v
					end
					ctx.floodPush()
				end)
			end
		end
	end
	for key in ctx.flood.floodColors do
		local box = hsv:FindFirstChild(key .. "_HSV")
		if box then
			local hex = box:FindFirstChild("Input") and box.Input:FindFirstChild("HexInput")
			ctx.floodBind(hex, "FocusLost", function()
				local ok, c = pcall(function()
					return Color3.fromHex(hex.Text)
				end)
				if ok and typeof(c) == "Color3" then
					ctx.flood.floodColors[key] = c
				end
				ctx.floodPush()
			end)
			for _, sp in {
				{ n = "Hue" },
				{ n = "Saturation" },
				{ n = "Value" },
			} do
				local cn = sp.n == "Saturation" and "Sat" or sp.n == "Value" and "Val" or sp.n
				local row = box.Config and box.Config:FindFirstChild(cn)
				local bar = row and row:FindFirstChild("Bar")
				local gr = bar and bar:FindFirstChild("Graphic")
				ctx.floodBind(bar and bar:FindFirstChild("Less"), "Activated", function()
					ctx.floodStep(key, sp.n, -1)
				end)
				ctx.floodBind(bar and bar:FindFirstChild("More"), "Activated", function()
					ctx.floodStep(key, sp.n, 1)
				end)
				ctx.floodBind(gr, "MouseButton1Down", function(x)
					if type(x) ~= "number" or gr.AbsoluteSize.X <= 0 then
						return
					end
					ctx.floodSetHsv(key, sp.n, (x - gr.AbsolutePosition.X) / gr.AbsoluteSize.X)
				end)
			end
		end
	end
end

ctx.startFloodColors = function()
	if not ctx.support("flood") then
		return
	end
	ctx.cache.floodTok += 1
	local id = ctx.cache.floodTok
	local rmt = Rsp and Rsp:FindFirstChild("Remote")
	local tw = rmt and rmt:FindFirstChild("TweenWaterColor")
	if tw and tw:IsA("RemoteEvent") then
		ctx.bind(tw.OnClientEvent:Connect(function(part)
			if ctx.opt.floodOn and part then
				task.defer(function()
					ctx.floodApply(ctx.curMap() or part.Parent)
				end)
			end
		end))
	end
	ctx.spawnLoop(function()
		local uiAt = 0
		local lastMap = nil
		while ctx.alive() and ctx.cache.floodTok == id do
			if ctx.opt.floodOn then
				local now = os.clock()
				if now >= uiAt then
					ctx.floodHookUi()
					uiAt = now + 3
				end
				local map = ctx.curMap()
				if map and map ~= lastMap then
					lastMap = map
					task.defer(ctx.floodApply, map)
				end
			end
			task.wait(1.5)
		end
	end)
end

ctx.pg = function()
	return LP and LP:FindFirstChildOfClass("PlayerGui") or nil
end

ctx.uiSet = function(obj, prop, val)
	if not obj then
		return
	end
	pcall(function()
		obj[prop] = val
	end)
end

ctx.uiHide = function(obj)
	ctx.uiSet(obj, "Visible", false)
	ctx.uiSet(obj, "Active", false)
end

ctx.uiEach = function(root, fn)
	if not (root and type(fn) == "function") then
		return
	end
	fn(root)
	for _, obj in ctx.descOf(root) do
		fn(obj)
	end
end

ctx.uiBind = function(obj, ev, tag, fn)
	if not (obj and type(fn) == "function") then
		return
	end
	local h = ctx.cache.uiHooks[obj]
	if type(h) ~= "table" then
		h = {}
		ctx.cache.uiHooks[obj] = h
	end
	local k = tostring(ev) .. tostring(tag)
	if h[k] then
		return
	end
	local sig = obj[ev]
	if not sig then
		return
	end
	h[k] = true
	ctx.bind(sig:Connect(fn))
end

ctx.dataLib = function()
	local mods = Rsp and Rsp:FindFirstChild("Modules")
	local sh = mods and mods:FindFirstChild("Shared")
	local m = sh and sh:FindFirstChild("FE2DataLibrary")
	if m and type(require) == "function" then
		local ok, lib = pcall(require, m)
		if ok and type(lib) == "table" then
			return lib
		end
	end
end


ctx.shopItemList = function()
	local dl = ctx.dataLib()
	if dl and type(dl.ItemData) == "table" then
		ctx.cache.shopItems = dl.ItemData
		return ctx.cache.shopItems, dl
	end
	if type(ctx.cache.shopItems) == "table" then
		return ctx.cache.shopItems, dl
	end
	ctx.requestPlayerData(true)
	local st = os.clock()
	repeat
		dl = ctx.dataLib()
		if dl and type(dl.ItemData) == "table" then
			ctx.cache.shopItems = dl.ItemData
			return ctx.cache.shopItems, dl
		end
		if type(ctx.cache.shopItems) == "table" then
			return ctx.cache.shopItems, dl
		end
		task.wait(0.05)
	until os.clock() - st > 3 or not ctx.alive()
	return ctx.cache.shopItems, dl
end

ctx.ownedItems = function()
	local out = {}
	local inv = type(pdata) == "table" and pdata.inventory or nil
	if type(inv) == "table" then
		for _, id in inv do
			local n = tonumber(id) or id
			out[n] = true
		end
	end
	return out
end

ctx.shopBuyIds = function(cur)
	local list = ctx.shopItemList()
	local ids = {}
	local seen = {}
	local owned = ctx.ownedItems()
	cur = tonumber(cur)
	if type(list) ~= "table" then
		return ids
	end
	for _, it in list do
		if type(it) == "table" then
			local id = tonumber(it.ID)
			local cat = tostring(it.catagory or "")
			local cc = tonumber(it.currency)
			if id and cc == cur and not seen[id] and not owned[id] and it.notForSale ~= true and cat ~= "Currency" and cat ~= "Gamepasses" and cat ~= "UGC" then
				seen[id] = true
				ids[#ids + 1] = id
			end
		end
	end
	return ids
end

ctx.buyShopCurrency = function(cur)
	if ctx.isFEMGame() then
		return ctx.buyFemShopCurrency(cur)
	end
	if ctx.opt.shopBusy then
		return
	end
	ctx.opt.shopBusy = true
	ctx.setBuyCoinBtn()
	ctx.setBuyGemBtn()
	local name = cur == 1 and "gem" or "coin"
	local function done(msg)
		ctx.opt.shopBusy = false
		ctx.setBuyCoinBtn()
		ctx.setBuyGemBtn()
		if msg then
			ctx.note(msg)
		end
	end

	if not (ConfirmItemRemote and ConfirmItemRemote.Parent) then
		done("ConfirmItem remote not found.")
		return
	end
	local key = ctx.getPassArg(false)
	if key == nil then
		done("Passkey not ready.")
		return
	end
	ctx.requestPlayerData(true)
	local ids = ctx.shopBuyIds(cur)
	if #ids < 1 then
		done("No " .. name .. " shop items found.")
		return
	end
	for _, id in ids do
		pcall(function()
			ConfirmItemRemote:FireServer(key, id)
		end)
		task.wait(0.08)
	end
	pcall(function()
		ConfirmItemRemote:FireServer(key, -1)
	end)
	ctx.requestPlayerData(true)
	done(("Sent %d %s shop purchase%s"):format(#ids, name, #ids == 1 and "" or "s"))
end


ctx.isFxObj = function(o)
	return o and (o:IsA("ParticleEmitter") or o:IsA("Beam") or o:IsA("Trail") or o:IsA("Fire") or o:IsA("Smoke") or o:IsA("Sparkles"))
end

ctx.patchSideClip = function(force)
	local c = ctx.chr(false)
	local s = c and c:FindFirstChild("CL_AntiSideClip")
	local z = s and s:FindFirstChild("Ziplining")
	local block = ctx.opt.clipOn == true or force == true
	if s and s:IsA("LocalScript") then
		pcall(function()
			s.Disabled = block
		end)
	end
	if z and z:IsA("BindableEvent") then
		pcall(function()
			z:Fire(block)
		end)
	end
end

ctx.patchFpParts = function()
	if not ctx.opt.fpPartOn then
		return
	end
	local c = ctx.chr(false)
	if not c then
		return
	end
	local m = c:FindFirstChild("CL_FirstPerson_ParticleManager")
	if m and m:IsA("LocalScript") then
		pcall(function()
			m.Disabled = true
		end)
	end
	for _, o in ctx.descOf(c) do
		if ctx.isFxObj(o) then
			pcall(function()
				o.Enabled = true
			end)
		end
	end
end

ctx.patchRescue = function()
	if not ctx.opt.rescueOn then
		return
	end
	local cam = Wsp and Wsp.CurrentCamera
	if not cam then
		return
	end
	for _, o in ctx.descOf(cam) do
		if o:IsA("BasePart") then
			local p = o.Parent
			if p and (p.Name == "NPC" or p:FindFirstChild("HumanoidRootPart")) then
				pcall(function()
					o.LocalTransparencyModifier = 1
				end)
			end
		elseif ctx.isFxObj(o) then
			pcall(function()
				o.Enabled = false
			end)
		end
	end
end

ctx.setDevTools = function(st)
	ctx.opt.devOn = st and true or false
	ctx.opt.infAirOn = ctx.opt.devOn
	ctx.opt.infJumpOn = ctx.opt.devOn
	ctx.opt.clickTpOn = ctx.opt.devOn
	local main = LP and LP:FindFirstChild("PlayerScripts") and LP.PlayerScripts:FindFirstChild("CL_MAIN_GameScript")
	local god = main and main:FindFirstChild("GodMode")
	if god and god.Fire then
		pcall(function()
			god:Fire(ctx.opt.devOn)
		end)
	end
	if ctx.opt.infAirOn then
		ctx.keepAirFast()
	else
		ctx.unprotectAirHealth()
	end
	ctx.setDevBtn()
	ctx.setInfAirBtn()
	ctx.setInfJumpBtn()
	ctx.setClickTpBtn()
end


ctx.patchPaidUi = function()
	if not ctx.opt.paidOn then
		return
	end
	local pg = ctx.pg()
	if not pg then
		return
	end
	if ctx.support("flood") then
		ctx.floodUi()
	end
	local roots = {
		pg:FindFirstChild("MenuGui"),
		pg:FindFirstChild("GameGui"),
		pg:FindFirstChild("DailyChallengeGui"),
	}
	local lob = Wsp and Wsp:FindFirstChild("Lobby")
	if lob then
		roots[#roots + 1] = lob:FindFirstChild("ProductWindows")
	end
	for _, root in roots do
		ctx.uiEach(root, function(o)
			if o.Name == "PurchaseGamepass" or o.Name == "PremiumOnly" or o.Name == "LockedFrame" then
				ctx.uiHide(o)
			elseif o:IsA("GuiButton") then
				ctx.uiSet(o, "Active", true)
				ctx.uiSet(o, "AutoButtonColor", true)
			elseif o:IsA("TextLabel") or o:IsA("TextButton") then
				local tx = tostring(o.Text or "")
				if string.find(tx, "Unlock") then
					ctx.uiSet(o, "Text", (string.gsub(tx, "Unlock & ", "")))
				elseif string.find(tx, "Premium Only") then
					ctx.uiSet(o, "Visible", false)
				end
			end
		end)
	end
end


ctx.mainScript = function()
	local ps = LP and LP:FindFirstChild("PlayerScripts")
	return ps and ps:FindFirstChild("CL_MAIN_GameScript") or nil
end

ctx.isSwimmingNow = function()
	local m = ctx.mainScript()
	local f = m and m:FindFirstChild("isSwimming")
	if f and f.Invoke then
		local ok, res = pcall(function()
			return f:Invoke()
		end)
		return ok and res == true
	end
	return false
end

ctx.partWords = function(p, words)
	if not p then
		return false
	end
	ctx.tmpName = string.lower((p.Name or "") .. " " .. (p.Parent and p.Parent.Name or ""))
	for _, w in words do
		if string.find(ctx.tmpName, w, 1, true) then
			return true
		end
	end
	return false
end

ctx.nearNamedPart = function(r, words, dist)
	if not (Wsp and r) then
		return false
	end
	ctx.tmpParts = nil
	pcall(function()
		ctx.tmpParts = Wsp:GetPartBoundsInRadius(r.Position, dist or 8)
	end)
	if type(ctx.tmpParts) == "table" then
		for _, p in ctx.tmpParts do
			if p and p:IsA("BasePart") then
				if table.find(words, "truss") and p:IsA("TrussPart") then
					return true
				end
				if ctx.partWords(p, words) then
					return true
				end
			end
		end
	end
	ctx.tmpMap = ctx.curMap() or MP
	if ctx.tmpMap then
		for _, p in ctx.descOf(ctx.tmpMap) do
			if p and p:IsA("BasePart") then
				if table.find(words, "truss") and p:IsA("TrussPart") and (r.Position - p.Position).Magnitude <= (dist or 8) then
					return true
				end
				if ctx.partWords(p, words) and (r.Position - p.Position).Magnitude <= (dist or 8) then
					return true
				end
			end
		end
	end
	return false
end

ctx.nearWalljump = function(r)
	if not r then
		return nil
	end
	ctx.tmpBestWall = nil
	ctx.tmpBestWallDist = 9
	ctx.tmpMap = ctx.curMap()
	if ctx.tmpMap then
		ctx.ensureChallenges(ctx.tmpMap)
		ctx.tmpHits = ctx.challengeHits(ctx.tmpMap)
		for _, wall in ctx.tmpHits.wall do
			if wall and wall.Parent then
				ctx.tmpDist = (r.Position - wall.Position).Magnitude
				if ctx.tmpDist < ctx.tmpBestWallDist then
					ctx.tmpBestWall = wall
					ctx.tmpBestWallDist = ctx.tmpDist
				end
			end
		end
	end
	ctx.tmpRoots = { ctx.tmpMap, MP }
	for _, root in ctx.tmpRoots do
		if root then
			for _, p in ctx.descOf(root) do
				if p and p:IsA("BasePart") and ((p:FindFirstChild("_Wall") ~= nil) or ctx.partWords(p, { "walljump", "wall_jump", "_wall" })) then
					ctx.tmpDist = (r.Position - p.Position).Magnitude
					if ctx.tmpDist < ctx.tmpBestWallDist then
						ctx.tmpBestWall = p
						ctx.tmpBestWallDist = ctx.tmpDist
					end
				end
			end
		end
	end
	if ctx.tmpBestWall then
		ctx.tmpPos, ctx.tmpNorm = ctx.wallData(ctx.tmpBestWall, r, ctx.chr(false))
		return ctx.tmpBestWall, ctx.tmpNorm
	end
	return nil
end

ctx.nearSwim = function(r)
	return ctx.nearNamedPart(r, { "water", "flood", "acid", "lava", "liquid", "swim" }, 12)
end

ctx.climbJump = function(lvl)
	ctx.tmpRoot, ctx.tmpHum = ctx.rh(false)
	if not (ctx.tmpRoot and ctx.tmpHum) then
		return false
	end
	ctx.tmpOldState = ctx.tmpHum:GetState()
	if ctx.tmpOldState ~= Enum.HumanoidStateType.Climbing then
		return false
	end
	ctx.tmpPow = lvl == 1 and 6 or lvl == 2 and 11 or 16
	ctx.tmpFwd = lvl == 1 and 4 or lvl == 2 and 7 or 10
	pcall(function()
		ctx.tmpHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		ctx.tmpHum.Jump = true
		ctx.tmpHum:ChangeState(Enum.HumanoidStateType.Jumping)
	end)
	if ctx.feCall("AccurateJump", true) ~= true then
		ctx.callScriptGlobal(ctx.feEnv(), "AccurateJump", true)
	end
	pcall(function()
		ctx.tmpVel = ctx.tmpRoot.AssemblyLinearVelocity
		ctx.tmpLoc = ctx.tmpRoot.CFrame:VectorToObjectSpace(ctx.tmpVel)
		ctx.tmpLoc = Vector3.new(ctx.tmpLoc.X, ctx.tmpLoc.Y + ctx.tmpPow, ctx.tmpLoc.Z + ctx.tmpFwd)
		ctx.tmpVel = ctx.tmpRoot.CFrame:VectorToWorldSpace(ctx.tmpLoc)
		ctx.tmpRoot.Velocity = ctx.tmpVel
		ctx.tmpRoot.AssemblyLinearVelocity = ctx.tmpVel
	end)
	return true
end

ctx.jumpRoot = function(pow, fwd, climb)
	ctx.tmpRoot, ctx.tmpHum = ctx.rh(false)
	if not (ctx.tmpRoot and ctx.tmpHum) then
		return false
	end
	if climb then
		return false
	end
	ctx.tmpVel = ctx.tmpRoot.AssemblyLinearVelocity
	pcall(function()
		ctx.tmpHum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		ctx.tmpHum.Jump = true
		ctx.tmpHum:ChangeState(Enum.HumanoidStateType.Jumping)
		ctx.tmpRoot.Velocity = Vector3.new(ctx.tmpVel.X, math.max(ctx.tmpVel.Y, pow), ctx.tmpVel.Z)
		ctx.tmpRoot.AssemblyLinearVelocity = ctx.tmpRoot.Velocity
	end)
	return true
end

ctx.doJumpBoost = function()
	ctx.tmpRoot, ctx.tmpHum = ctx.rh(false)
	if not (ctx.tmpHum and ctx.tmpRoot) then
		return
	end
	ctx.tmpState = ctx.tmpHum:GetState()
	if ctx.opt.infJumpOn then
		ctx.jumpRoot(52, 0, false)
	end
end


ctx.remoteRoot = function()
	return Rsp and Rsp:FindFirstChild("Remote") or nil
end

ctx.remotePath = function(...)
	ctx.tmpNode = ctx.remoteRoot()
	for _, nm in { ... } do
		ctx.tmpNode = ctx.tmpNode and ctx.tmpNode:FindFirstChild(nm)
	end
	return ctx.tmpNode
end

ctx.fireRemote = function(rem, ...)
	if not (rem and rem.FireServer) then
		return false
	end
	return pcall(function(...)
		rem:FireServer(...)
	end, ...)
end

ctx.fireRegenAir = function()
	ctx.tmpRem = ctx.remotePath("Challenges", "RegeneratedAir") or ctx.findRemoteNamed("RegeneratedAir")
	ctx.tmpOk = ctx.fireRemote(ctx.tmpRem, 9999)
	ctx.tmpOk = ctx.fireRemote(ctx.tmpRem, 300) or ctx.tmpOk
	ctx.tmpOk = ctx.fireRemote(ctx.tmpRem) or ctx.tmpOk
	return ctx.tmpOk
end

ctx.keepAirLocal = function()
	ctx.tmpAirEnv = ctx.gameEnv()
	ctx.callScriptGlobal(ctx.tmpAirEnv, "takeAir", -9999)
	ctx.callScriptGlobal(ctx.tmpAirEnv, "switchAir", "tank", true)
	ctx.tmpPg = ctx.pg()
	ctx.tmpAir = ctx.tmpPg and ctx.tmpPg:FindFirstChild("Air", true)
	ctx.tmpCnt = ctx.tmpAir and ctx.tmpAir:FindFirstChild("Count", true)
	if ctx.tmpCnt and (ctx.tmpCnt:IsA("TextLabel") or ctx.tmpCnt:IsA("TextButton")) then
		pcall(function()
			ctx.tmpCnt.Text = "∞"
			ctx.tmpCnt.TextColor3 = Color3.new(1, 1, 1)
		end)
	end
end

ctx.airHpValue = function(h)
	ctx.tmpHp = 100
	if h then
		pcall(function()
			ctx.tmpHp = math.max(100, h.MaxHealth)
		end)
	end
	return ctx.tmpHp
end

ctx.resetAirHealth = function(h)
	if not h then
		return
	end
	pcall(function()
		if ctx.live and ctx.opt.infAirOn and h.Health <= math.max(1, h.MaxHealth * 0.2) then
			h.Health = ctx.airHpValue(h)
		end
	end)
end

ctx.airBlockAlert = function(env)
	if type(env) ~= "table" then
		return
	end
	if ctx.cache.airAlertEnv ~= env then
		if ctx.cache.airAlertEnv and ctx.cache.airAlertOld then
			pcall(function()
				ctx.cache.airAlertEnv.newAlert = ctx.cache.airAlertOld
			end)
		end
		ctx.cache.airAlertEnv = env
		ctx.cache.airAlertOld = type(env.newAlert) == "function" and env.newAlert or nil
	end
	if type(ctx.cache.airAlertOld) ~= "function" then
		return
	end
	if env.newAlert ~= ctx.cache.airAlertWrap then
		ctx.cache.airAlertWrap = function(msg, ...)
			if ctx.live and ctx.opt.infAirOn and type(msg) == "string" and (msg:find("Drowned") or msg:find("drowned") or msg:find("lava") or msg:find("Lava")) then
				return
			end
			return ctx.cache.airAlertOld(msg, ...)
		end
		pcall(function()
			env.newAlert = ctx.cache.airAlertWrap
		end)
	end
end

ctx.unblockAirAlert = function()
	if ctx.cache.airAlertEnv and ctx.cache.airAlertOld then
		pcall(function()
			ctx.cache.airAlertEnv.newAlert = ctx.cache.airAlertOld
		end)
	end
	ctx.cache.airAlertEnv = nil
	ctx.cache.airAlertOld = nil
	ctx.cache.airAlertWrap = nil
end

ctx.protectAirHealth = function()
	ctx.tmpRoot, ctx.tmpHum = ctx.rh(false)
	if not ctx.tmpHum then
		return
	end
	ctx.cache.airHum = ctx.tmpHum
	if ctx.cache.airHealthHum ~= ctx.tmpHum then
		ctx.cut(ctx.cache.airHealthConn)
		ctx.cut(ctx.cache.airDiedConn)
		ctx.cache.airHealthHum = ctx.tmpHum
		ctx.cache.airHealthConn = ctx.tmpHum:GetPropertyChangedSignal("Health"):Connect(function()
			ctx.resetAirHealth(ctx.cache.airHealthHum)
		end)
		ctx.cache.airDiedConn = ctx.tmpHum.Died:Connect(function()
			if ctx.live and ctx.opt.infAirOn then
				ctx.resetAirHealth(ctx.cache.airHealthHum)
			end
		end)
	end
	pcall(function()
		ctx.tmpHum.BreakJointsOnDeath = false
	end)
	pcall(function()
		ctx.tmpHum.RequiresNeck = false
	end)
	pcall(function()
		ctx.tmpHum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	end)
	pcall(function()
		if ctx.tmpHum.Health <= math.max(1, ctx.tmpHum.MaxHealth * 0.2) then
			ctx.tmpHum.Health = ctx.airHpValue(ctx.tmpHum)
		end
	end)
end

ctx.unprotectAirHealth = function()
	ctx.tmpRoot, ctx.tmpHum = ctx.rh(false)
	ctx.cut(ctx.cache.airHealthConn)
	ctx.cut(ctx.cache.airDiedConn)
	ctx.cache.airHealthConn = nil
	ctx.cache.airDiedConn = nil
	ctx.cache.airHealthHum = nil
	ctx.cache.airHum = nil
	if ctx.tmpHum then
		pcall(function()
			ctx.tmpHum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
		end)
	end
	ctx.unblockAirAlert()
	ctx.keepFemAir(false)
end

ctx.femSwimming = function()
	if type(ctx.cache.femSwim) == "table" then
		return ctx.cache.femSwim
	end
	if ctx.cache.femSwim == false and os.clock() < (ctx.cache.femSwimRetry or 0) then
		return nil
	end
	ctx.cache.femSwim = false
	ctx.cache.femSwimRetry = os.clock() + 2
	ctx.tmpPs = LP and LP:FindFirstChild("PlayerScripts")
	ctx.tmpLh = ctx.tmpPs and ctx.tmpPs:FindFirstChild("LocalHandler")
	ctx.tmpSw = ctx.tmpLh and ctx.tmpLh:FindFirstChild("Swimming")
	if ctx.tmpSw and type(require) == "function" then
		ctx.tmpOk, ctx.tmpMod = pcall(require, ctx.tmpSw)
		if ctx.tmpOk and type(ctx.tmpMod) == "table" then
			ctx.cache.femSwim = ctx.tmpMod
			return ctx.tmpMod
		end
	end
	return nil
end

ctx.keepFemAir = function(st)
	ctx.tmpSwim = ctx.femSwimming()
	if type(ctx.tmpSwim) ~= "table" then
		return false
	end
	if type(ctx.tmpSwim.Invincibility) == "function" then
		pcall(ctx.tmpSwim.Invincibility, st ~= false)
	end
	if st ~= false and type(ctx.tmpSwim.SubtractAir) == "function" then
		pcall(ctx.tmpSwim.SubtractAir, -9999)
	end
	return true
end

ctx.keepAirFast = function()
	ctx.protectAirHealth()
	ctx.keepFemAir(true)
	ctx.tmpAirEnv = ctx.cache.airEnv or ctx.gameEnv()
	if ctx.tmpAirEnv then
		ctx.cache.airEnv = ctx.tmpAirEnv
		ctx.airBlockAlert(ctx.tmpAirEnv)
	end
	ctx.callScriptGlobal(ctx.tmpAirEnv, "takeAir", -9999)
	ctx.callScriptGlobal(ctx.tmpAirEnv, "switchAir", "tank", true)
	ctx.protectAirHealth()
end

ctx.fireGod = function(st)
	ctx.tmpMain = ctx.mainScript()
	ctx.tmpGod = ctx.tmpMain and ctx.tmpMain:FindFirstChild("GodMode")
	if ctx.tmpGod and ctx.tmpGod.Fire then
		pcall(function()
			ctx.tmpGod:Fire(st == true)
		end)
	end
	if st == true then
		ctx.keepAirLocal()
		ctx.keepFemAir(true)
		ctx.fireRegenAir()
	else
		ctx.keepFemAir(false)
	end
end

ctx.femLocatorHit = function()
	ctx.tmpPg = ctx.pg()
	ctx.tmpLoc = ctx.tmpPg and ctx.tmpPg:FindFirstChild("Locator", true)
	ctx.tmpView = ctx.tmpLoc and ctx.tmpLoc:FindFirstChild("LocatorViewport", true)
	ctx.tmpBall = ctx.tmpView and ctx.tmpView:FindFirstChild("Ball")
	if ctx.tmpBall and ctx.tmpBall:IsA("BasePart") then
		return ctx.tmpBall
	end
	return nil
end

ctx.fireNextButton = function()
	ctx.tmpMap = ctx.curMap()
	ctx.tmpRoot = select(1, ctx.rh(false))
	if ctx.isFEM() then
		ctx.tmpHit = ctx.femLocatorHit()
		if ctx.tmpHit and ctx.tmpHit.Parent then
			if ctx.tmpRoot and ctx.tmpRoot.Parent then
				pcall(function()
					ctx.pivotRootTo(ctx.tmpHit.CFrame + Vector3.new(0, 3, 0), ctx.tmpRoot)
					ctx.tmpRoot.AssemblyLinearVelocity = Vector3.zero
				end)
				task.wait(0.08)
			end
			ctx.cache.muteNotifyUntil = os.clock() + 1.5
			ctx.pressMapButton(ctx.tmpHit)
			return true
		end
	end
	ctx.tmpEntries = {}
	if ctx.tmpMap then
		ctx.tmpEntries = ctx.auraEntries(ctx.tmpMap) or {}
		ctx.mergeLocatorBtns(ctx.tmpEntries, ctx.tmpMap)
		if #ctx.tmpEntries <= 0 then
			ctx.tmpOk, ctx.tmpRes = pcall(ctx.scanBtns, ctx.tmpMap)
			if ctx.tmpOk and type(ctx.tmpRes) == "table" then
				ctx.tmpEntries = ctx.tmpRes
			end
		end
	end
	ctx.tmpEntry = ctx.nearestEntry(ctx.tmpEntries, ctx.tmpRoot and ctx.tmpRoot.Position)
	ctx.tmpHit = ctx.tmpEntry and ctx.tmpEntry.hit
	if ctx.tmpHit and ctx.tmpHit.Parent then
		if ctx.tmpRoot and ctx.tmpRoot.Parent then
			pcall(function()
				ctx.pivotRootTo(ctx.tmpHit.CFrame + Vector3.new(0, 3, 0), ctx.tmpRoot)
				ctx.tmpRoot.AssemblyLinearVelocity = Vector3.zero
			end)
			task.wait(0.08)
			if type(firetouchinterest) == "function" then
				pcall(firetouchinterest, ctx.tmpRoot, ctx.tmpHit, 0)
				pcall(firetouchinterest, ctx.tmpRoot, ctx.tmpHit, 1)
			end
		end
		ctx.cache.muteNotifyUntil = os.clock() + 1.5
		ctx.pressMapButton(ctx.tmpHit)
		return true
	end
	ctx.note("No map button found")
	return false
end

ctx.fireTestRemote = function(nm)
	if nm == "NextButton" then
		return ctx.fireNextButton()
	end
	ctx.tmpEv = ctx.findRemoteNamed(nm)
	if not (ctx.tmpEv and ctx.tmpEv.FireServer) then
		ctx.note(tostring(nm) .. " remote not found")
		return false
	end
	return ctx.fireRemote(ctx.tmpEv)
end


ctx.safeParent = function(o)
	ctx.tmpOk, ctx.tmpPar = pcall(function()
		return o and o.Parent
	end)
	if ctx.tmpOk then
		return ctx.tmpPar
	end
	return nil
end

ctx.zipTarget = function(o)
	if not (o and typeof(o) == "Instance") then
		return false
	end
	ctx.tmpZipPar = ctx.safeParent(o)
	ctx.tmpZipName = string.lower((o.Name or "") .. " " .. (ctx.tmpZipPar and ctx.tmpZipPar.Name or ""))
	return string.find(ctx.tmpZipName, "zip", 1, true)
		or string.find(ctx.tmpZipName, "rope", 1, true)
		or o:GetAttribute("RopeSpeed") ~= nil
		or o:GetAttribute("ZiplineSpeed") ~= nil
		or o:GetAttribute("VelocityInheritance") ~= nil
end

ctx.zipPatchOne = function(o, st)
	if not (o and typeof(o) == "Instance") then
		return
	end
	if ctx.cache.zipOld[o] == nil then
		ctx.cache.zipOld[o] = {
			o:GetAttribute("RopeSpeed"),
			o:GetAttribute("ZiplineSpeed"),
			o:GetAttribute("Speed"),
			o:GetAttribute("VelocityInheritance"),
		}
	end
	pcall(function()
		if st and ctx.opt.zipSpeed > 0 then
			o:SetAttribute("RopeSpeed", ctx.opt.zipSpeed)
			o:SetAttribute("ZiplineSpeed", ctx.opt.zipSpeed)
			o:SetAttribute("Speed", ctx.opt.zipSpeed)
			o:SetAttribute("VelocityInheritance", 0)
		elseif ctx.cache.zipOld[o] then
			o:SetAttribute("RopeSpeed", ctx.cache.zipOld[o][1])
			o:SetAttribute("ZiplineSpeed", ctx.cache.zipOld[o][2])
			o:SetAttribute("Speed", ctx.cache.zipOld[o][3])
			o:SetAttribute("VelocityInheritance", ctx.cache.zipOld[o][4])
		end
	end)
end

ctx.watchZipRoot = function(root)
	if not (root and typeof(root) == "Instance") or ctx.cache.zipWatches[root] then
		return
	end
	ctx.cache.zipWatches[root] = true
	if root.DescendantAdded then
		ctx.bind(root.DescendantAdded:Connect(function(o)
			if not (ctx.alive() and ctx.opt.zipFastOn and ctx.opt.zipAutoOn) then
				return
			end
			task.defer(function()
				if not (ctx.alive() and ctx.opt.zipFastOn and ctx.opt.zipAutoOn) then
					return
				end
				if ctx.zipTarget(o) then
					ctx.zipPatchOne(o, true)
				end
				ctx.tmpZipPar = ctx.safeParent(o)
				if ctx.tmpZipPar and ctx.zipTarget(ctx.tmpZipPar) then
					ctx.zipPatchOne(ctx.tmpZipPar, true)
				end
			end)
		end))
	end
end

ctx.setZipAttrs = function(st)
	ctx.tmpMap = ctx.curMap()
	ctx.tmpZipRoots = {}
	if ctx.tmpMap then
		ctx.tmpZipRoots[#ctx.tmpZipRoots + 1] = ctx.tmpMap
	end
	if MP then
		ctx.tmpZipRoots[#ctx.tmpZipRoots + 1] = MP
	end
	for _, root in ctx.tmpZipRoots do
		ctx.watchZipRoot(root)
		for _, o in ctx.descOf(root) do
			if ctx.zipTarget(o) then
				ctx.zipPatchOne(o, st)
			end
			ctx.tmpZipPar = ctx.safeParent(o)
			if ctx.tmpZipPar and ctx.zipTarget(ctx.tmpZipPar) then
				ctx.zipPatchOne(ctx.tmpZipPar, st)
			end
		end
	end
end

ctx.reapplyZipSpeed = function()
	if not (ctx.opt.zipFastOn and ctx.opt.zipAutoOn) then
		return
	end
	ctx.setZipAttrs(true)
end

ctx.resetZipVelocity = function()
	ctx.tmpRoot = select(1, ctx.rh(false))
	if not ctx.tmpRoot then
		return
	end
	pcall(function()
		ctx.tmpRoot.AssemblyLinearVelocity = Vector3.zero
		ctx.tmpRoot.Velocity = Vector3.zero
	end)
	task.delay(0.04, function()
		if not ctx.alive() then
			return
		end
		ctx.tmpRoot = select(1, ctx.rh(false))
		if ctx.tmpRoot then
			pcall(function()
				ctx.tmpRoot.AssemblyLinearVelocity = Vector3.zero
				ctx.tmpRoot.Velocity = Vector3.zero
			end)
		end
	end)
end

ctx.hookZipStop = function(c)
	if ctx.cache.zipChar == c then
		return
	end
	ctx.cut(ctx.cache.zipConn)
	ctx.cache.zipConn = nil
	ctx.cache.zipChar = c
	ctx.tmpAnti = c and c:FindFirstChild("CL_AntiSideClip")
	ctx.tmpZipEv = ctx.tmpAnti and ctx.tmpAnti:FindFirstChild("Ziplining")
	if ctx.tmpZipEv and ctx.tmpZipEv.Event then
		ctx.cache.zipConn = ctx.tmpZipEv.Event:Connect(function(st)
			ctx.opt.zipActive = st and true or false
			if not st and ctx.opt.zipStopOn then
				ctx.resetZipVelocity()
			end
		end)
	end
end

ctx.fireSlideBindable = function()
	ctx.tmpOk = ctx.feCall("runSlide", "FE2Helper", Enum.UserInputState.Begin, true)
	if ctx.tmpOk then
		return true
	end
	ctx.tmpChar = ctx.chr(false)
	ctx.tmpFe = ctx.tmpChar and ctx.tmpChar:FindFirstChild("FE2_Character")
	ctx.tmpSlide = ctx.tmpFe and ctx.tmpFe:FindFirstChild("Slide")
	if ctx.tmpSlide and ctx.tmpSlide.Fire then
		pcall(function()
			ctx.tmpSlide:Fire("FE2Helper", Enum.UserInputState.Begin, true)
		end)
		return true
	end
	return false
end

ctx.swimVelocity = function(r, h, y, spd)
	if not (r and h and ctx.isSwimmingNow()) then
		return
	end
	ctx.tmpDir = h.MoveDirection
	if ctx.tmpDir.Magnitude < 0.05 then
		return
	end
	ctx.tmpSwimVel = r:FindFirstChild("SwimVel")
	if not ctx.tmpSwimVel then
		return
	end
	pcall(function()
		ctx.tmpSwimVel.MaxForce = Vector3.new(5000, 0, 5000)
		ctx.tmpSwimVel.Velocity = Vector3.new(ctx.tmpDir.X * spd, 0, ctx.tmpDir.Z * spd)
		if y ~= 0 then
			ctx.tmpSwimVel.MaxForce = Vector3.new(5000, 3500, 5000)
			ctx.tmpSwimVel.Velocity = ctx.tmpSwimVel.Velocity + Vector3.new(0, y, 0)
		end
	end)
end

ctx.applyPhysicsOptions = function()
	if not (ctx.opt.infJumpOn or ctx.opt.zipFastOn) then
		return
	end
	ctx.tmpRoot, ctx.tmpHum, ctx.tmpChar = ctx.rh(false)
	if not (ctx.tmpChar and ctx.tmpHum and ctx.tmpRoot) then
		return
	end
	ctx.tmpNow = os.clock()
	ctx.tmpSpace = Uis and Uis:IsKeyDown(Enum.KeyCode.Space)

	if ctx.opt.infJumpOn and ctx.tmpSpace and ctx.tmpNow - ctx.cache.jumpAt >= 0.16 and ctx.tmpHum:GetState() ~= Enum.HumanoidStateType.Climbing then
		ctx.cache.jumpAt = ctx.tmpNow
		ctx.jumpRoot(52, 0, false)
	end
end

ctx.startInfAirHeartbeat = function()
	if not Run or ctx.cache.infAirHb then
		return
	end
	ctx.cache.infAirHb = Run.Heartbeat:Connect(function()
		if not ctx.alive() then
			return
		end
		if ctx.opt.infAirOn then
			ctx.keepAirFast()
		elseif ctx.cache.airAlertEnv then
			ctx.unprotectAirHealth()
		end
	end)
	ctx.bind(ctx.cache.infAirHb)
end

ctx.cache.feMoveOrig = ctx.cache.feMoveOrig or setmetatable({}, { __mode = "k" })
ctx.cache.feMoveModOrig = ctx.cache.feMoveModOrig or {}
ctx.cache.feMoveChar = nil
ctx.cache.feMoveCharCons = ctx.cache.feMoveCharCons or {}
ctx.cache.feMoveLoop = nil
ctx.cache.feVelHb = ctx.cache.feVelHb
ctx.cache.feVelTask = ctx.cache.feVelTask
ctx.cache.feVelSeen = ctx.cache.feVelSeen
ctx.cache.feVelLast = 0
ctx.cache.feVelLastState = nil

ctx.feMoveNoop = function()
end

ctx.patchFeMoveEnv = function(scr, st)
	if type(getsenv) ~= "function" or not scr then
		return
	end
	local ok, env = pcall(getsenv, scr)
	if not ok or type(env) ~= "table" then
		return
	end
	local save = ctx.cache.feMoveOrig[scr]
	if type(save) ~= "table" then
		save = {}
		ctx.cache.feMoveOrig[scr] = save
	end
	for _, n in { "AccurateJump" } do
		if st == true then
			if save[n] ~= nil then
				env[n] = save[n]
			end
		else
			if save[n] == nil and type(env[n]) == "function" and env[n] ~= ctx.feMoveNoop then
				save[n] = env[n]
			end
			if type(env[n]) == "function" then
				env[n] = ctx.feMoveNoop
			end
		end
	end
end

ctx.patchFeAntiWallhop = function(st)
	local mods = Rsp and Rsp:FindFirstChild("Modules")
	local client = mods and mods:FindFirstChild("Client")
	local mod = client and client:FindFirstChild("AntiWallhop")
	if not (mod and type(require) == "function") then
		return
	end
	local ok, t = pcall(require, mod)
	if not ok or type(t) ~= "table" then
		return
	end
	for _, n in { "enable", "onPostSimulation" } do
		if st == true then
			if ctx.cache.feMoveModOrig[n] ~= nil then
				t[n] = ctx.cache.feMoveModOrig[n]
			end
		else
			if ctx.cache.feMoveModOrig[n] == nil and type(t[n]) == "function" and t[n] ~= ctx.feMoveNoop then
				ctx.cache.feMoveModOrig[n] = t[n]
			end
			if type(t[n]) == "function" then
				t[n] = ctx.feMoveNoop
			end
		end
	end
end

ctx.connectionFn = function(c)
	if type(c) ~= "table" and typeof(c) ~= "RBXScriptConnection" then
		return nil
	end
	for _, k in { "Function", "func", "Callback", "_function" } do
		local ok, v = pcall(function()
			return c[k]
		end)
		if ok and type(v) == "function" then
			return v
		end
	end
	return nil
end

ctx.connectionMethod = function(c, n)
	if not c then
		return nil
	end
	local ok, v = pcall(function()
		return c[n]
	end)
	if ok and type(v) == "function" then
		return v
	end
	return nil
end

ctx.fnEnvScript = function(fn)
	if type(fn) ~= "function" or type(getfenv) ~= "function" then
		return nil
	end
	local ok, env = pcall(getfenv, fn)
	if ok and type(env) == "table" and typeof(env.script) == "Instance" then
		return env.script
	end
	return nil
end

ctx.fnBelongsToScript = function(fn, scr)
	if not (scr and type(fn) == "function") then
		return false
	end
	local envScript = ctx.fnEnvScript(fn)
	if envScript == scr then
		return true
	end
	local dbg = type(debug) == "table" and debug or nil
	local info = dbg and dbg.info
	if type(info) == "function" then
		local ok, src = pcall(info, fn, "s")
		if ok and type(src) == "string" and string.find(src, scr.Name, 1, true) then
			return true
		end
	end
	return false
end

ctx.setFirstBoolUpvalue = function(fn, v)
	if type(fn) ~= "function" then
		return false
	end
	local dbg = type(debug) == "table" and debug or nil
	local setup = (dbg and dbg.setupvalue) or setupvalue
	if type(setup) ~= "function" then
		return false
	end
	local getvals = (dbg and dbg.getupvalues) or getupvalues
	if type(getvals) == "function" then
		local ok, vals = pcall(getvals, fn)
		if ok and type(vals) == "table" then
			for i, val in vals do
				if type(i) == "number" and type(val) == "boolean" then
					local ok2 = pcall(setup, fn, i, v == true)
					return ok2
				end
			end
		end
	end
	local getone = (dbg and dbg.getupvalue) or getupvalue
	if type(getone) ~= "function" then
		return false
	end
	for i = 1, 64 do
		local ok, a, b = pcall(getone, fn, i)
		if not ok or (a == nil and b == nil) then
			break
		end
		local val = if b ~= nil then b else a
		if type(val) == "boolean" then
			local ok2 = pcall(setup, fn, i, v == true)
			return ok2
		end
	end
	return false
end

ctx.eachSignalConnection = function(sig, cb)
	if type(getconnections) ~= "function" or not sig then
		return false
	end
	local ok, list = pcall(getconnections, sig)
	if not ok or type(list) ~= "table" then
		return false
	end
	local hit = false
	for _, con in list do
		hit = true
		pcall(cb, con)
	end
	return hit
end

ctx.patchFeVelocityConnections = function(st)
	local tv = ctx.feVelocityEvent()
	if not (tv and tv.Event) then
		return false
	end
	ctx.cache.feVelCons = ctx.cache.feVelCons or setmetatable({}, { __mode = "k" })
	if st == true then
		for con in ctx.cache.feVelCons do
			local enable = ctx.connectionMethod(con, "Enable")
			if enable then
				pcall(function()
					enable(con)
				end)
			end
		end
		ctx.cache.feVelCons = setmetatable({}, { __mode = "k" })
		return true
	end
	local patched = false
	ctx.eachSignalConnection(tv.Event, function(con)
		local fn = ctx.connectionFn(con)
		if ctx.setFirstBoolUpvalue(fn, false) then
			patched = true
		end
		local disable = ctx.connectionMethod(con, "Disable")
		local enable = ctx.connectionMethod(con, "Enable")
		if disable and enable then
			pcall(function()
				disable(con)
			end)
			ctx.cache.feVelCons[con] = true
			patched = true
		end
	end)
	return patched
end

ctx.patchFeSignalConnections = function(sig, scr, key, st)
	if not sig then
		return false
	end
	ctx.cache[key] = ctx.cache[key] or setmetatable({}, { __mode = "k" })
	if st == true then
		for con in ctx.cache[key] do
			local enable = ctx.connectionMethod(con, "Enable")
			if enable then
				pcall(function()
					enable(con)
				end)
			end
		end
		ctx.cache[key] = setmetatable({}, { __mode = "k" })
		return true
	end
	local patched = false
	ctx.eachSignalConnection(sig, function(con)
		local fn = ctx.connectionFn(con)
		if not ctx.fnBelongsToScript(fn, scr) then
			return
		end
		local disable = ctx.connectionMethod(con, "Disable")
		local enable = ctx.connectionMethod(con, "Enable")
		if disable and enable then
			pcall(function()
				disable(con)
			end)
			ctx.cache[key][con] = true
			patched = true
		end
	end)
	return patched
end

ctx.patchFeHumanoidSignals = function(scr, st)
	local _, h = ctx.rh(false)
	if not (scr and h) then
		return
	end
	ctx.patchFeSignalConnections(h.StateChanged, scr, "feStateCons", st)
	ctx.patchFeSignalConnections(h.FallingDown, scr, "feFallCons", st)
	if st == true then
		ctx.cut(ctx.cache.feScanConn)
		ctx.cache.feScanConn = nil
		return
	end
	if ctx.cache.feScanHum == h and ctx.cache.feScanConn then
		return
	end
	ctx.cut(ctx.cache.feScanConn)
	ctx.cache.feScanHum = h
	ctx.cache.feScanConn = h.StateChanged:Connect(function(_, newState)
		if ctx.opt.fePhysicsOn == true then
			return
		end
		if newState ~= Enum.HumanoidStateType.Freefall and newState ~= Enum.HumanoidStateType.Jumping then
			return
		end
		local env = ctx.envOf(scr)
		if env and type(env.scanWalljumps) == "function" then
			task.defer(function()
				pcall(env.scanWalljumps)
			end)
		end
	end)
	ctx.bind(ctx.cache.feScanConn)
end

ctx.patchFeMainEnv = function(st)
	local env = ctx.gameEnv()
	if not env then
		return
	end
	local save = ctx.cache.feMoveOrig.__main
	if type(save) ~= "table" then
		save = {}
		ctx.cache.feMoveOrig.__main = save
	end
	for _, n in { "AccurateJump" } do
		if st == true then
			if save[n] ~= nil then
				env[n] = save[n]
			end
		else
			if save[n] == nil and type(env[n]) == "function" and env[n] ~= ctx.feMoveNoop then
				save[n] = env[n]
			end
			if type(env[n]) == "function" then
				env[n] = ctx.feMoveNoop
			end
		end
	end
end

ctx.patchFeMovementState = function(st)
	ctx.patchFeAntiWallhop(st)
	if st == true then
		ctx.patchFeVelocityConnections(true)
	else
		ctx.fireFeVelocityLimit(false, true)
		ctx.patchFeVelocityConnections(false)
	end
	ctx.patchFeMainEnv(st)
end

ctx.restoreFeMoveEnv = function(scr)
	local save = ctx.cache.feMoveOrig[scr]
	if type(save) ~= "table" then
		return
	end
	local env = ctx.envOf(scr)
	if not env then
		return
	end
	for n, fn in save do
		if type(n) == "string" and type(fn) == "function" then
			env[n] = save[n]
		end
	end
end

ctx.feVelocityEvent = function()
	local main = ctx.mainScript()
	local tv = main and main:FindFirstChild("ToggleVelocity")
	if tv and tv.Fire then
		return tv
	end
	return nil
end

ctx.fireFeVelocityLimit = function(st, force)
	local tv = ctx.feVelocityEvent()
	if not tv then
		return false
	end
	local now = os.clock()
	if force ~= true and ctx.cache.feVelLastState == st and now - (ctx.cache.feVelLast or 0) < (st and 0.75 or 0.015) then
		return true
	end
	local ok = pcall(function()
		tv:Fire(st == true)
	end)
	if ok then
		ctx.cache.feVelLastState = st
		ctx.cache.feVelLast = now
	end
	return ok
end

ctx.keepFeVelocityLimitOff = function()
	if ctx.opt.fePhysicsOn == true then
		if ctx.cache.feVelSeen ~= true then
			ctx.patchFeVelocityConnections(true)
			ctx.fireFeVelocityLimit(true, true)
			ctx.cache.feVelSeen = true
		end
		return
	end
	ctx.cache.feVelSeen = false
	ctx.fireFeVelocityLimit(false, true)
	ctx.patchFeVelocityConnections(false)
end

ctx.startFeVelocityLoop = function()
	if Run and not ctx.cache.feVelHb then
		ctx.cache.feVelHb = Run.Heartbeat:Connect(function()
			ctx.keepFeVelocityLimitOff()
		end)
		ctx.bind(ctx.cache.feVelHb)
	end
	if not ctx.cache.feVelTask then
		ctx.cache.feVelTask = true
		ctx.spawnLoop(function()
			while ctx.alive() do
				ctx.keepFeVelocityLimitOff()
				task.wait(ctx.opt.fePhysicsOn and 0.75 or 0.03)
			end
		end)
	end
end

ctx.applyFeMovement = function()
	local st = ctx.opt.fePhysicsOn == true
	local c = ctx.chr(false)
	ctx.patchFeMovementState(st)
	if st == true then
		ctx.fireFeVelocityLimit(true, true)
	end
	if not c then
		return
	end
	local fe = c:FindFirstChild("FE2_Character")
	if fe and fe:IsA("LocalScript") then
		pcall(function()
			fe.Disabled = false
		end)
		ctx.patchFeMoveEnv(fe, st)
		ctx.patchFeHumanoidSignals(fe, st)
	end
	local anti = c:FindFirstChild("CL_AntiSideClip")
	if anti and anti:IsA("LocalScript") then
		pcall(function()
			anti.Disabled = ctx.opt.clipOn == true
		end)
		local z = anti:FindFirstChild("Ziplining")
		if z and z.Fire then
			pcall(function()
				z:Fire(ctx.opt.clipOn == true)
			end)
		end
	end
	local main = ctx.mainScript()
	if main then
		ctx.patchFeMoveEnv(main, st)
	end
end

ctx.bindFeMovementChar = function(c)
	ctx.clearCons(ctx.cache.feMoveCharCons)
	ctx.cache.feMoveChar = c
	if not c then
		return
	end
	ctx.cache.feMoveCharCons[#ctx.cache.feMoveCharCons + 1] = c.ChildAdded:Connect(function(v)
		if v.Name == "FE2_Character" or v.Name == "CL_AntiSideClip" then
			task.defer(ctx.applyFeMovement)
		end
	end)
	ctx.applyFeMovement()
end

ctx.startFeMovementPatch = function()
	ctx.startFeVelocityLoop()
	if ctx.cache.feMoveLoop then
		return
	end
	if LP then
		ctx.bind(LP.CharacterAdded:Connect(function(c)
			task.defer(ctx.bindFeMovementChar, c)
		end))
	end
	if LP and LP.Character then
		ctx.bindFeMovementChar(LP.Character)
	end
	ctx.cache.feMoveLoop = true
	ctx.spawnLoop(function()
		while ctx.alive() do
			if LP and LP.Character ~= ctx.cache.feMoveChar then
				ctx.bindFeMovementChar(LP.Character)
			end
			ctx.applyFeMovement()
			task.wait(ctx.opt.fePhysicsOn and 1.5 or 0.25)
		end
	end)
end

ctx.startPhysicsOptions = function()
	ctx.startInfAirHeartbeat()
	ctx.startFeMovementPatch()
	if Uis then
		ctx.bind(Uis.JumpRequest:Connect(function()
			ctx.doJumpBoost()
		end))
		ctx.bind(Uis.InputBegan:Connect(function(inp, gp)
			if gp or not inp then
				return
			end
			if inp.KeyCode == Enum.KeyCode.Space then
				ctx.doJumpBoost()
			end
		end))
	end
	ctx.tmpMouse = LP and LP:GetMouse()
	if ctx.tmpMouse then
		ctx.bind(ctx.tmpMouse.Button1Up:Connect(function()
			if not ctx.opt.clickTpOn then
				return
			end
			ctx.tmpRoot = select(1, ctx.rh(false))
			if ctx.tmpRoot and ctx.tmpMouse.Hit then
				ctx.tmpRx, ctx.tmpRy, ctx.tmpRz = ctx.tmpRoot.CFrame:ToEulerAnglesXYZ()
				pcall(function()
					ctx.tmpRoot.CFrame = CFrame.new(ctx.tmpMouse.Hit.Position + Vector3.new(0, 2.5, 0)) * CFrame.fromEulerAnglesXYZ(ctx.tmpRx, ctx.tmpRy, ctx.tmpRz)
				end)
			end
		end))
	end
	ctx.spawnLoop(function()
		while ctx.alive() do
			ctx.applyPhysicsOptions()
			task.wait(0.18)
		end
	end)
end

ctx.startUiUnlocks = function()
	ctx.cache.uiTok += 1
	ctx.tmpUiTok = ctx.cache.uiTok
	ctx.spawnLoop(function()
		while ctx.alive() and ctx.cache.uiTok == ctx.tmpUiTok do
			if ctx.opt.paidOn then
				ctx.patchPaidUi()
			end
			if ctx.opt.clipOn then
				ctx.patchSideClip()
			end
			if ctx.opt.rescueOn then
				ctx.patchRescue()
			end
			task.wait(3)
		end
	end)
end

if MP then
	ctx.bind(MP.ChildAdded:Connect(function(ch)
		if ch.Name == "Map" or ch.Name == "NewMap" then
			if on then
				ctx.spawnLoop(ctx.burstLoaded)
			end
			if ctx.opt.zipFastOn and ctx.opt.zipAutoOn then
				task.defer(ctx.reapplyZipSpeed)
				task.delay(0.75, ctx.reapplyZipSpeed)
				task.delay(2, ctx.reapplyZipSpeed)
			end
		end
	end))
end

ctx.loadTopbar = function()
	if ctx.topbar then
		return ctx.topbar
	end
	ctx.tmpLoader = loadstring or load
	if type(ctx.tmpLoader) ~= "function" then
		return nil
	end
	ctx.tmpSrc = nil
	pcall(function()
		ctx.tmpSrc = game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Icon.luau")
	end)
	if type(ctx.tmpSrc) ~= "string" or ctx.tmpSrc == "" then
		return nil
	end
	ctx.tmpChunk = ctx.tmpLoader(ctx.tmpSrc, "@lt_topbar_icon.luau")
	if type(ctx.tmpChunk) ~= "function" then
		return nil
	end
	pcall(function()
		ctx.topbar = ctx.tmpChunk()
	end)
	if type(ctx.topbar) == "table" then
		pcall(function()
			ctx.topbar.setDisplayOrder(2147483647)
		end)
		return ctx.topbar
	end
	return nil
end

ctx.icon = function(name, label, cb, col)
	ctx.tmpIcon = ctx.topbar.new()
	pcall(function()
		ctx.tmpIcon:setName("FE2_" .. name)
	end)
	pcall(function()
		ctx.tmpIcon:setLabel(label)
	end)
	pcall(function()
		ctx.tmpIcon:oneClick()
	end)
	if col then
		ctx.uiColor(ctx.tmpIcon, col)
	end
	if type(cb) == "function" then
		pcall(function()
			ctx.tmpIcon:bindEvent("selected", function()
				pcall(cb)
			end)
		end)
	end
	ctx.ui.menu[#ctx.ui.menu + 1] = ctx.tmpIcon
	return ctx.tmpIcon
end

ctx.applyAuraDistText = function(txt)
	ctx.tmpNum = tonumber(txt)
	if not ctx.tmpNum then
		ctx.note("Invalid aura distance")
		return false
	end
	auraDist = math.clamp(math.floor(ctx.tmpNum * 100 + 0.5) / 100, 0, 1000)
	ctx.setDistBtn()
	ctx.saveSoon()
	ctx.note("Aura distance set to " .. tostring(auraDist))
	return true
end

ctx.closeAuraPrompt = function()
	ctx.clearCons(ctx.cache.auraPromptCons)
	if ctx.ui.auraPrompt then
		pcall(function()
			ctx.ui.auraPrompt:Destroy()
		end)
	end
	ctx.ui.auraPrompt = nil
	ctx.tmpFrame = nil
	ctx.tmpCorner = nil
	ctx.tmpTitle = nil
	ctx.tmpBox = nil
	ctx.tmpBoxCorner = nil
	ctx.tmpApply = nil
	ctx.tmpApplyCorner = nil
	ctx.tmpCancel = nil
	ctx.tmpCancelCorner = nil
end

ctx.openAuraPrompt = function()
	if ctx.ui.auraPrompt then
		ctx.closeAuraPrompt()
		return
	end
	ctx.ui.auraPrompt = ctx.protectedScreen("FE2AuraDistancePrompt")
	if not ctx.ui.auraPrompt then
		ctx.note("No protected UI parent")
		return
	end
	ctx.tmpFrame = Instance.new("Frame")
	ctx.tmpFrame.Name = "Box"
	ctx.tmpFrame.AnchorPoint = Vector2.new(0.5, 0)
	ctx.tmpFrame.Position = UDim2.new(0.5, 0, 0, 72)
	ctx.tmpFrame.Size = UDim2.fromOffset(260, 112)
	ctx.tmpFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	ctx.tmpFrame.BorderSizePixel = 0
	ctx.tmpFrame.Parent = ctx.ui.auraPrompt
	ctx.tmpCorner = Instance.new("UICorner")
	ctx.tmpCorner.CornerRadius = UDim.new(0, 10)
	ctx.tmpCorner.Parent = ctx.tmpFrame
	ctx.tmpTitle = Instance.new("TextLabel")
	ctx.tmpTitle.BackgroundTransparency = 1
	ctx.tmpTitle.Size = UDim2.new(1, -16, 0, 28)
	ctx.tmpTitle.Position = UDim2.fromOffset(8, 6)
	ctx.tmpTitle.Font = Enum.Font.GothamBold
	ctx.tmpTitle.TextScaled = true
	ctx.tmpTitle.TextColor3 = Color3.new(1, 1, 1)
	ctx.tmpTitle.Text = "Aura Distance"
	ctx.tmpTitle.Parent = ctx.tmpFrame
	ctx.tmpBox = Instance.new("TextBox")
	ctx.tmpBox.Name = "Input"
	ctx.tmpBox.Size = UDim2.new(1, -24, 0, 34)
	ctx.tmpBox.Position = UDim2.fromOffset(12, 42)
	ctx.tmpBox.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
	ctx.tmpBox.BorderSizePixel = 0
	ctx.tmpBox.ClearTextOnFocus = false
	ctx.tmpBox.Text = tostring(auraDist)
	ctx.tmpBox.PlaceholderText = "number, e.g. 2 or 8"
	ctx.tmpBox.Font = Enum.Font.Gotham
	ctx.tmpBox.TextScaled = true
	ctx.tmpBox.TextColor3 = Color3.new(1, 1, 1)
	ctx.tmpBox.Parent = ctx.tmpFrame
	ctx.tmpBoxCorner = Instance.new("UICorner")
	ctx.tmpBoxCorner.CornerRadius = UDim.new(0, 8)
	ctx.tmpBoxCorner.Parent = ctx.tmpBox
	ctx.tmpApply = Instance.new("TextButton")
	ctx.tmpApply.Name = "Apply"
	ctx.tmpApply.Size = UDim2.new(0.5, -18, 0, 26)
	ctx.tmpApply.Position = UDim2.fromOffset(12, 82)
	ctx.tmpApply.BackgroundColor3 = Color3.fromRGB(60, 160, 75)
	ctx.tmpApply.BorderSizePixel = 0
	ctx.tmpApply.Font = Enum.Font.GothamBold
	ctx.tmpApply.TextScaled = true
	ctx.tmpApply.TextColor3 = Color3.new(1, 1, 1)
	ctx.tmpApply.Text = "Apply"
	ctx.tmpApply.Parent = ctx.tmpFrame
	ctx.tmpApplyCorner = Instance.new("UICorner")
	ctx.tmpApplyCorner.CornerRadius = UDim.new(0, 8)
	ctx.tmpApplyCorner.Parent = ctx.tmpApply
	ctx.tmpCancel = Instance.new("TextButton")
	ctx.tmpCancel.Name = "Cancel"
	ctx.tmpCancel.Size = UDim2.new(0.5, -18, 0, 26)
	ctx.tmpCancel.Position = UDim2.new(0.5, 6, 0, 82)
	ctx.tmpCancel.BackgroundColor3 = Color3.fromRGB(150, 55, 55)
	ctx.tmpCancel.BorderSizePixel = 0
	ctx.tmpCancel.Font = Enum.Font.GothamBold
	ctx.tmpCancel.TextScaled = true
	ctx.tmpCancel.TextColor3 = Color3.new(1, 1, 1)
	ctx.tmpCancel.Text = "Cancel"
	ctx.tmpCancel.Parent = ctx.tmpFrame
	ctx.tmpCancelCorner = Instance.new("UICorner")
	ctx.tmpCancelCorner.CornerRadius = UDim.new(0, 8)
	ctx.tmpCancelCorner.Parent = ctx.tmpCancel
	ctx.cache.auraPromptCons[#ctx.cache.auraPromptCons + 1] = ctx.tmpApply.MouseButton1Click:Connect(function()
		if ctx.applyAuraDistText(ctx.tmpBox.Text) then
			ctx.closeAuraPrompt()
		end
	end)
	ctx.cache.auraPromptCons[#ctx.cache.auraPromptCons + 1] = ctx.tmpCancel.MouseButton1Click:Connect(ctx.closeAuraPrompt)
	ctx.cache.auraPromptCons[#ctx.cache.auraPromptCons + 1] = ctx.tmpBox.FocusLost:Connect(function(enter)
		if enter and ctx.applyAuraDistText(ctx.tmpBox.Text) then
			ctx.closeAuraPrompt()
		end
	end)
	pcall(function()
		ctx.tmpBox:CaptureFocus()
	end)
end

ctx.applyZipSpeedText = function(txt)
	ctx.tmpNum = tonumber(txt)
	if not ctx.tmpNum then
		ctx.note("Invalid zipline speed")
		return false
	end
	ctx.tmpNum = math.clamp(math.floor(ctx.tmpNum * 100 + 0.5) / 100, 0, 500)
	ctx.opt.zipSpeed = ctx.tmpNum
	ctx.opt.zipFastOn = ctx.tmpNum > 0
	ctx.setZipBtn()
	ctx.setZipAttrs(ctx.opt.zipFastOn)
	if not ctx.opt.zipFastOn and ctx.opt.zipStopOn then
		ctx.resetZipVelocity()
	end
	ctx.saveSoon()
	ctx.note(ctx.opt.zipFastOn and ("Zipline speed set to " .. tostring(ctx.opt.zipSpeed)) or "Zipline speed disabled")
	return true
end

ctx.closeZipPrompt = function()
	ctx.clearCons(ctx.cache.zipPromptCons)
	if ctx.ui.zipPrompt then
		pcall(function()
			ctx.ui.zipPrompt:Destroy()
		end)
	end
	ctx.ui.zipPrompt = nil
	ctx.tmpFrame = nil
	ctx.tmpCorner = nil
	ctx.tmpTitle = nil
	ctx.tmpBox = nil
	ctx.tmpBoxCorner = nil
	ctx.tmpApply = nil
	ctx.tmpApplyCorner = nil
	ctx.tmpCancel = nil
	ctx.tmpCancelCorner = nil
end

ctx.openZipPrompt = function()
	if ctx.ui.zipPrompt then
		ctx.closeZipPrompt()
		return
	end
	ctx.ui.zipPrompt = ctx.protectedScreen("FE2ZipSpeedPrompt")
	if not ctx.ui.zipPrompt then
		ctx.note("No protected UI parent")
		return
	end
	ctx.tmpFrame = Instance.new("Frame")
	ctx.tmpFrame.Name = "Box"
	ctx.tmpFrame.AnchorPoint = Vector2.new(0.5, 0)
	ctx.tmpFrame.Position = UDim2.new(0.5, 0, 0, 72)
	ctx.tmpFrame.Size = UDim2.fromOffset(270, 116)
	ctx.tmpFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	ctx.tmpFrame.BorderSizePixel = 0
	ctx.tmpFrame.Parent = ctx.ui.zipPrompt
	ctx.tmpCorner = Instance.new("UICorner")
	ctx.tmpCorner.CornerRadius = UDim.new(0, 10)
	ctx.tmpCorner.Parent = ctx.tmpFrame
	ctx.tmpTitle = Instance.new("TextLabel")
	ctx.tmpTitle.BackgroundTransparency = 1
	ctx.tmpTitle.Size = UDim2.new(1, -16, 0, 28)
	ctx.tmpTitle.Position = UDim2.fromOffset(8, 6)
	ctx.tmpTitle.Font = Enum.Font.GothamBold
	ctx.tmpTitle.TextScaled = true
	ctx.tmpTitle.TextColor3 = Color3.new(1, 1, 1)
	ctx.tmpTitle.Text = "Zipline Speed"
	ctx.tmpTitle.Parent = ctx.tmpFrame
	ctx.tmpBox = Instance.new("TextBox")
	ctx.tmpBox.Name = "Input"
	ctx.tmpBox.Size = UDim2.new(1, -24, 0, 34)
	ctx.tmpBox.Position = UDim2.fromOffset(12, 42)
	ctx.tmpBox.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
	ctx.tmpBox.BorderSizePixel = 0
	ctx.tmpBox.ClearTextOnFocus = false
	ctx.tmpBox.Text = tostring(ctx.opt.zipSpeed)
	ctx.tmpBox.PlaceholderText = "0 disables, e.g. 60 or 90"
	ctx.tmpBox.Font = Enum.Font.Gotham
	ctx.tmpBox.TextScaled = true
	ctx.tmpBox.TextColor3 = Color3.new(1, 1, 1)
	ctx.tmpBox.Parent = ctx.tmpFrame
	ctx.tmpBoxCorner = Instance.new("UICorner")
	ctx.tmpBoxCorner.CornerRadius = UDim.new(0, 8)
	ctx.tmpBoxCorner.Parent = ctx.tmpBox
	ctx.tmpApply = Instance.new("TextButton")
	ctx.tmpApply.Name = "Apply"
	ctx.tmpApply.Size = UDim2.new(0.5, -18, 0, 26)
	ctx.tmpApply.Position = UDim2.fromOffset(12, 86)
	ctx.tmpApply.BackgroundColor3 = Color3.fromRGB(60, 160, 75)
	ctx.tmpApply.BorderSizePixel = 0
	ctx.tmpApply.Font = Enum.Font.GothamBold
	ctx.tmpApply.TextScaled = true
	ctx.tmpApply.TextColor3 = Color3.new(1, 1, 1)
	ctx.tmpApply.Text = "Apply"
	ctx.tmpApply.Parent = ctx.tmpFrame
	ctx.tmpApplyCorner = Instance.new("UICorner")
	ctx.tmpApplyCorner.CornerRadius = UDim.new(0, 8)
	ctx.tmpApplyCorner.Parent = ctx.tmpApply
	ctx.tmpCancel = Instance.new("TextButton")
	ctx.tmpCancel.Name = "Cancel"
	ctx.tmpCancel.Size = UDim2.new(0.5, -18, 0, 26)
	ctx.tmpCancel.Position = UDim2.new(0.5, 6, 0, 86)
	ctx.tmpCancel.BackgroundColor3 = Color3.fromRGB(150, 55, 55)
	ctx.tmpCancel.BorderSizePixel = 0
	ctx.tmpCancel.Font = Enum.Font.GothamBold
	ctx.tmpCancel.TextScaled = true
	ctx.tmpCancel.TextColor3 = Color3.new(1, 1, 1)
	ctx.tmpCancel.Text = "Cancel"
	ctx.tmpCancel.Parent = ctx.tmpFrame
	ctx.tmpCancelCorner = Instance.new("UICorner")
	ctx.tmpCancelCorner.CornerRadius = UDim.new(0, 8)
	ctx.tmpCancelCorner.Parent = ctx.tmpCancel
	ctx.cache.zipPromptCons[#ctx.cache.zipPromptCons + 1] = ctx.tmpApply.MouseButton1Click:Connect(function()
		if ctx.applyZipSpeedText(ctx.tmpBox.Text) then
			ctx.closeZipPrompt()
		end
	end)
	ctx.cache.zipPromptCons[#ctx.cache.zipPromptCons + 1] = ctx.tmpCancel.MouseButton1Click:Connect(ctx.closeZipPrompt)
	ctx.cache.zipPromptCons[#ctx.cache.zipPromptCons + 1] = ctx.tmpBox.FocusLost:Connect(function(enter)
		if enter and ctx.applyZipSpeedText(ctx.tmpBox.Text) then
			ctx.closeZipPrompt()
		end
	end)
	pcall(function()
		ctx.tmpBox:CaptureFocus()
	end)
end


ctx.femEventsRoot = function()
	return Rsp and Rsp:FindFirstChild("Events") or nil
end

ctx.femGetEventsTable = function()
	if ctx.cache.femEventsTable ~= nil then
		return ctx.cache.femEventsTable
	end
	ctx.cache.femEventsTable = false
	ctx.tmpPs = LP and LP:FindFirstChild("PlayerScripts")
	ctx.tmpLh = ctx.tmpPs and ctx.tmpPs:FindFirstChild("LocalHandler")
	ctx.tmpGe = ctx.tmpLh and ctx.tmpLh:FindFirstChild("GetEvents")
	if ctx.tmpGe and type(require) == "function" then
		ctx.tmpOk, ctx.tmpRes = pcall(function()
			return require(ctx.tmpGe)()
		end)
		if ctx.tmpOk and type(ctx.tmpRes) == "table" then
			ctx.cache.femEventsTable = ctx.tmpRes
			return ctx.tmpRes
		end
	end
	return nil
end

ctx.femEvent = function(n, cls)
	ctx.tmpEvs = ctx.femEventsRoot()
	ctx.tmpEv = ctx.tmpEvs and ctx.tmpEvs:FindFirstChild(n)
	if ctx.tmpEv and (not cls or ctx.tmpEv:IsA(cls)) then
		return ctx.tmpEv
	end
	ctx.tmpTbl = ctx.femGetEventsTable()
	ctx.tmpEv = type(ctx.tmpTbl) == "table" and ctx.tmpTbl[n] or nil
	if ctx.tmpEv and (not cls or ctx.tmpEv:IsA(cls)) then
		return ctx.tmpEv
	end
	if type(getnilinstances) == "function" or type(getinstances) == "function" then
		for _, fn in { getnilinstances, getinstances } do
			if type(fn) == "function" then
				ctx.tmpOk, ctx.tmpList = pcall(fn)
				if ctx.tmpOk and type(ctx.tmpList) == "table" then
					for _, obj in ctx.tmpList do
						if typeof(obj) == "Instance" and obj.Name == n and (not cls or obj:IsA(cls)) then
							return obj
						end
					end
				end
			end
		end
	end
	return nil
end

ctx.isFEM = function()
	if ctx.cache.isFEM == true then
		return true
	end
	if ctx.cache.isFEM == false and os.clock() < (ctx.cache.femRetry or 0) then
		return false
	end
	ctx.tmpGameId = nil
	pcall(function()
		ctx.tmpGameId = game.GameId
	end)
	ctx.cache.isFEM = ctx.tmpGameId == 761462079 and ctx.femEvent("StartMapVote", "RemoteEvent") ~= nil and ctx.femEvent("UpdMapVote", "RemoteEvent") ~= nil
	if ctx.cache.isFEM ~= true then
		ctx.cache.femRetry = os.clock() + 2
	end
	return ctx.cache.isFEM == true
end

ctx.femFreeMap = function(data)
	if type(data) ~= "table" or type(data.MapData) ~= "table" then
		return nil
	end
	ctx.tmpBest = nil
	for _, map in data.MapData do
		if type(map) == "table" and map.ID ~= nil and map.ShowMap ~= false and map.Cooldown ~= true and map.Locked ~= true then
			ctx.tmpBest = map
			break
		end
	end
	return ctx.tmpBest
end

ctx.femVoteData = function(data)
	if not ctx.opt.femVoteOn or not ctx.isFEM() then
		return false
	end
	ctx.tmpMap = ctx.femFreeMap(data)
	if not ctx.tmpMap then
		return false
	end
	ctx.tmpId = ctx.tmpMap.ID
	ctx.tmpNow = os.clock()
	if ctx.cache.femLastVoteId == ctx.tmpId and ctx.tmpNow - (ctx.cache.femVoteAt or 0) < 1.25 then
		return false
	end
	ctx.tmpVote = ctx.femEvent("UpdMapVote", "RemoteEvent")
	if not ctx.tmpVote then
		return false
	end
	ctx.cache.femLastVoteId = ctx.tmpId
	ctx.cache.femVoteAt = ctx.tmpNow
	return ctx.fireRemote(ctx.tmpVote, ctx.tmpId, 0)
end

ctx.startFemAutoVote = function()
	if ctx.cache.femStarted then
		return
	end
	ctx.cache.femStarted = true
	ctx.tmpStartVote = ctx.femEvent("StartMapVote", "RemoteEvent")
	if ctx.tmpStartVote then
		ctx.bind(ctx.tmpStartVote.OnClientEvent:Connect(function(data)
			if ctx.opt.femVoteOn then
				task.defer(ctx.femVoteData, data)
			end
		end))
	end
	ctx.tmpUpdVote = ctx.femEvent("UpdMapVote", "RemoteEvent")
	if ctx.tmpUpdVote then
		ctx.bind(ctx.tmpUpdVote.OnClientEvent:Connect(function(data)
			if ctx.opt.femVoteOn then
				task.defer(ctx.femVoteData, data)
			end
		end))
	end
end

ctx.femItemData = function()
	if type(ctx.cache.femItems) == "table" then
		return ctx.cache.femItems
	end
	ctx.cache.femItems = false
	ctx.tmpMods = Rsp and Rsp:FindFirstChild("Modules")
	ctx.tmpItemData = ctx.tmpMods and ctx.tmpMods:FindFirstChild("ItemData")
	if ctx.tmpItemData and type(require) == "function" then
		ctx.tmpOk, ctx.tmpMod = pcall(require, ctx.tmpItemData)
		if ctx.tmpOk and type(ctx.tmpMod) == "table" and type(ctx.tmpMod.GetItemData) == "function" then
			ctx.tmpOk2, ctx.tmpItems = pcall(ctx.tmpMod.GetItemData)
			if ctx.tmpOk2 and type(ctx.tmpItems) == "table" then
				ctx.cache.femItems = ctx.tmpItems
				return ctx.tmpItems
			end
		end
	end
	return nil
end

ctx.femOwnedItems = function()
	ctx.tmpOwned = {}
	ctx.tmpData = LP and LP:FindFirstChild("Data")
	ctx.tmpShop = ctx.tmpData and ctx.tmpData:FindFirstChild("Shop")
	ctx.tmpItems = ctx.tmpShop and ctx.tmpShop:FindFirstChild("Items")
	if ctx.tmpItems then
		for _, obj in ctx.tmpItems:GetChildren() do
			ctx.tmpId = tonumber(obj.Name) or obj.Name
			ctx.tmpOwned[ctx.tmpId] = true
		end
	end
	return ctx.tmpOwned
end

ctx.femFunds = function(cur)
	ctx.tmpData = LP and LP:FindFirstChild("Data")
	ctx.tmpVal = ctx.tmpData and ctx.tmpData:FindFirstChild(cur == 1 and "Amethysts" or "Coins")
	return ctx.tmpVal and tonumber(ctx.tmpVal.Value) or 0
end

ctx.femShopBuyIds = function(cur)
	ctx.tmpItems = ctx.femItemData()
	ctx.tmpIds = {}
	ctx.tmpSeen = {}
	ctx.tmpOwned = ctx.femOwnedItems()
	ctx.tmpBudget = ctx.femFunds(cur)
	ctx.tmpSpent = 0
	if type(ctx.tmpItems) ~= "table" then
		return ctx.tmpIds
	end
	for _, it in ctx.tmpItems do
		if type(it) == "table" then
			ctx.tmpId = tonumber(it.ID)
			ctx.tmpCat = tostring(it.Catagory or it.catagory or "")
			ctx.tmpPrice = tonumber(cur == 1 and it.Price_Amethysts or it.Price_Coins)
			if ctx.tmpId and ctx.tmpPrice and ctx.tmpPrice > 0 and not ctx.tmpSeen[ctx.tmpId] and not ctx.tmpOwned[ctx.tmpId] and it.NotForSale ~= true and it.notForSale ~= true and ctx.tmpCat ~= "Currency" and ctx.tmpCat ~= "Gamepasses" and ctx.tmpSpent + ctx.tmpPrice <= ctx.tmpBudget then
				ctx.tmpSeen[ctx.tmpId] = true
				ctx.tmpSpent += ctx.tmpPrice
				ctx.tmpIds[#ctx.tmpIds + 1] = { id = ctx.tmpId, cat = ctx.tmpCat }
			end
		end
	end
	return ctx.tmpIds
end

ctx.buyFemShopCurrency = function(cur)
	if ctx.opt.shopBusy then
		return
	end
	ctx.opt.shopBusy = true
	ctx.setBuyCoinBtn()
	ctx.setBuyGemBtn()
	ctx.tmpName = cur == 1 and "amethyst" or "coin"
	local function done(msg)
		ctx.opt.shopBusy = false
		ctx.setBuyCoinBtn()
		ctx.setBuyGemBtn()
		if msg then
			ctx.note(msg)
		end
	end
	ctx.tmpPurchase = ctx.femEvent("PurchaseItem", "RemoteFunction")
	if not ctx.tmpPurchase then
		done("FEM PurchaseItem remote not found.")
		return
	end
	ctx.tmpIds = ctx.femShopBuyIds(cur)
	if #ctx.tmpIds < 1 then
		done("No affordable FEM " .. ctx.tmpName .. " shop items found.")
		return
	end
	ctx.tmpBought = 0
	for _, it in ctx.tmpIds do
		ctx.tmpOk, ctx.tmpRes = pcall(function()
			return ctx.tmpPurchase:InvokeServer(it.id, cur == 1 and 2 or 1, nil, it.cat)
		end)
		if ctx.tmpOk and ctx.tmpRes == true then
			ctx.tmpBought += 1
		end
		task.wait(0.08)
	end
	done(("Sent %d FEM %s purchase%s"):format(ctx.tmpBought, ctx.tmpName, ctx.tmpBought == 1 and "" or "s"))
end

ctx.patchFemRopeData = function(data)
	if type(data) ~= "table" then
		return false
	end
	ctx.cache.femRopeData = data
	ctx.tmpTarget = tonumber(ctx.opt.zipSpeed) or 0
	for _, rope in data do
		if type(rope) == "table" and type(rope[2]) == "table" then
			if ctx.cache.femRopeOld[rope] == nil then
				ctx.cache.femRopeOld[rope] = tonumber(rope[3]) or 40
			end
			if ctx.opt.zipFastOn and ctx.tmpTarget > 0 then
				ctx.tmpBase = ctx.cache.femRopeOld[rope] or tonumber(rope[3]) or 40
				rope[3] = math.clamp(ctx.tmpBase * 40 / math.max(ctx.tmpTarget, 1), 1, 200)
			else
				rope[3] = ctx.cache.femRopeOld[rope] or rope[3]
			end
		end
	end
	return true
end

ctx.startFemZipPatch = function()
	if ctx.cache.femZipStarted then
		return
	end
	ctx.cache.femZipStarted = true
	ctx.tmpRope = ctx.femEvent("UpdRopeData", "RemoteEvent")
	if ctx.tmpRope then
		ctx.bind(ctx.tmpRope.OnClientEvent:Connect(function(data)
			task.defer(ctx.patchFemRopeData, data)
		end))
	end
end

ctx.femSetZip = function(st)
	ctx.startFemZipPatch()
	if ctx.cache.femRopeData then
		ctx.patchFemRopeData(ctx.cache.femRopeData)
	end
end

ctx.startFemZipStop = function()
	if ctx.cache.femZipStopStarted or not LP then
		return
	end
	ctx.cache.femZipStopStarted = true
	ctx.cache.femZipLast = LP:GetAttribute("Ziplining") == true
	ctx.bind(LP:GetAttributeChangedSignal("Ziplining"):Connect(function()
		ctx.tmpZipState = LP:GetAttribute("Ziplining") == true
		if ctx.cache.femZipLast and not ctx.tmpZipState and ctx.opt.zipStopOn then
			ctx.resetZipVelocity()
		end
		ctx.cache.femZipLast = ctx.tmpZipState
	end))
end

ctx.startFemButtonCache = function()
	if ctx.cache.femBtnStarted then
		return
	end
	ctx.cache.femBtnStarted = true
	ctx.tmpSet = ctx.femEvent("SetButtonLocator", "RemoteEvent")
	if ctx.tmpSet then
		ctx.bind(ctx.tmpSet.OnClientEvent:Connect(function(goal, hit, ui)
			if hit and typeof(hit) == "Instance" and hit:IsA("BasePart") then
				ctx.cache.femButtonPart = hit
			end
		end))
	end
end

ctx.hideIcon = function(field)
	ctx.tmpIcon = ctx.ui[field]
	if not ctx.tmpIcon then
		return
	end
	for i = #ctx.ui.menu, 1, -1 do
		if ctx.ui.menu[i] == ctx.tmpIcon then
			table.remove(ctx.ui.menu, i)
		end
	end
	pcall(function()
		if type(ctx.tmpIcon.destroy) == "function" then
			ctx.tmpIcon:destroy()
		elseif type(ctx.tmpIcon.Destroy) == "function" then
			ctx.tmpIcon:Destroy()
		end
	end)
	ctx.ui[field] = nil
end

ctx.applyProfileUi = function()
	if ctx.isRetroGame() then
		for _, field in { "bonusBtn", "chBtn", "floodBtn", "rescueBtn", "devBtn", "zipBtn", "zipStopBtn", "zipAutoBtn", "femVoteBtn" } do
			ctx.hideIcon(field)
		end
	elseif ctx.isFEMGame() then
		for _, field in { "bonusBtn", "chBtn", "floodBtn", "clipBtn", "rescueBtn", "devBtn", "surviveBtn" } do
			ctx.hideIcon(field)
		end
	elseif ctx.isFE2Game() then
		ctx.hideIcon("femVoteBtn")
	end
end

do
	local oldSetZipAttrs = ctx.setZipAttrs
	ctx.setZipAttrs = function(st)
		if ctx.isFEMGame() then
			return ctx.femSetZip(st)
		end
		return oldSetZipAttrs(st)
	end
	local oldHookZipStop = ctx.hookZipStop
	ctx.hookZipStop = function(c)
		oldHookZipStop(c)
		if ctx.isFEMGame() then
			ctx.startFemZipStop()
		end
	end
	local oldFemLocatorHit = ctx.femLocatorHit
	ctx.femLocatorHit = function()
		ctx.startFemButtonCache()
		ctx.tmpBtn = ctx.cache.femButtonPart
		if ctx.tmpBtn and ctx.tmpBtn.Parent then
			return ctx.tmpBtn
		end
		return nil
	end
end

ctx.mkUi = function()
	ctx.topbar = ctx.loadTopbar()
	if type(ctx.topbar) ~= "table" or type(ctx.topbar.new) ~= "function" then
		ctx.note("Topbar loader failed")
		return
	end
	ctx.ui.menu = {}
	ctx.ui.rootIcon = ctx.topbar.new()
	ctx.ui.rootIcon:setName("FE2_Helper_Dropdown")
	ctx.ui.rootIcon:setLabel("FE2 Helper")
	ctx.ui.rootIcon:setImage(6031280882)
	ctx.ui.rootIcon:align("Center")
	ctx.ui.rootIcon:setOrder(50)
	ctx.ui.startBtn = ctx.icon("Start", "Start AutoFarm", function()
		ctx.toggle(not on)
	end, Color3.fromRGB(60, 180, 60))
	ctx.ui.auraBtn = ctx.icon("Aura", "Button Aura: OFF", function()
		auraOn = not auraOn
		ctx.setAuraBtn()
		ctx.saveSoon()
	end)
	ctx.ui.distModeBtn = ctx.icon("AuraDistance", "Button Distance: ON", function()
		auraUseDistance = not auraUseDistance
		ctx.setDistModeBtn()
		ctx.saveSoon()
	end, Color3.fromRGB(60, 130, 210))
	ctx.ui.distBtn = ctx.icon("AuraDist", "Aura Dist: 7", ctx.openAuraPrompt, Color3.fromRGB(55, 55, 55))
	ctx.ui.bonusBtn = ctx.icon("Bonuses", "Collect Bonuses: ON", function()
		autoCollectBonuses = not autoCollectBonuses
		ctx.setBonusBtn()
		ctx.saveSoon()
	end, Color3.fromRGB(60, 130, 210))
	ctx.ui.chBtn = ctx.icon("Challenges", "Challenges: OFF", function()
		autoChallenges = not autoChallenges
		ctx.setChallengeBtn()
		ctx.saveSoon()
	end)
	ctx.ui.floodBtn = ctx.icon("CustomFlood", "Custom Flood: ON", function()
		ctx.opt.floodOn = not ctx.opt.floodOn
		ctx.setFloodBtn()
		ctx.saveSoon()
		ctx.floodPush()
	end, Color3.fromRGB(60, 130, 210))
	ctx.ui.paidBtn = ctx.icon("PaidLocks", "Paid UI Locks: ON", function()
		ctx.opt.paidOn = not ctx.opt.paidOn
		ctx.setPaidBtn()
		ctx.saveSoon()
		if ctx.opt.paidOn then
			ctx.patchPaidUi()
		end
	end, Color3.fromRGB(60, 130, 210))
	ctx.ui.buyCoinBtn = ctx.icon("BuyCoin", "Buy Coin Shop Items", function()
		ctx.spawnLoop(ctx.buyShopCurrency, 0)
	end, Color3.fromRGB(218, 165, 32))
	ctx.ui.buyGemBtn = ctx.icon("BuyGem", "Buy Gem Shop Items", function()
		ctx.spawnLoop(ctx.buyShopCurrency, 1)
	end, Color3.fromRGB(142, 68, 173))
	ctx.ui.clipBtn = ctx.icon("NoSideClip", "No SideClip TP: OFF", function()
		ctx.opt.clipOn = not ctx.opt.clipOn
		ctx.setClipBtn()
		ctx.saveSoon()
		ctx.patchSideClip()
	end)
	ctx.ui.fePhysBtn = ctx.icon("FePhysics", "FE2 Physics: OFF", function()
		ctx.opt.fePhysicsOn = not ctx.opt.fePhysicsOn
		ctx.setFePhysicsBtn()
		ctx.saveSoon()
		ctx.applyFeMovement()
	end)
	ctx.ui.rescueBtn = ctx.icon("HideRescue", "Hide Rescue NPC: OFF", function()
		ctx.opt.rescueOn = not ctx.opt.rescueOn
		ctx.setRescueBtn()
		ctx.saveSoon()
		ctx.patchRescue()
	end)
	ctx.ui.zipBtn = ctx.icon("ZiplineSpeed", "Zip Speed: OFF", ctx.openZipPrompt)
	ctx.ui.zipStopBtn = ctx.icon("ZipStopVelocity", "Zip Stop Velocity: ON", function()
		ctx.opt.zipStopOn = not ctx.opt.zipStopOn
		ctx.setZipStopBtn()
		ctx.saveSoon()
	end)
	ctx.ui.zipAutoBtn = ctx.icon("ZipAutoApply", "Zip Auto Apply: ON", function()
		ctx.opt.zipAutoOn = not ctx.opt.zipAutoOn
		ctx.setZipAutoBtn()
		ctx.saveSoon()
		if ctx.opt.zipAutoOn then
			ctx.reapplyZipSpeed()
		end
	end)
	ctx.ui.devBtn = ctx.icon("DevTools", "DevTools: OFF", function()
		ctx.setDevTools(not ctx.opt.devOn)
		ctx.saveSoon()
	end)
	ctx.ui.infAirBtn = ctx.icon("InfAir", "Inf Air: OFF", function()
		ctx.opt.infAirOn = not ctx.opt.infAirOn
		ctx.setInfAirBtn()
		ctx.saveSoon()
		if ctx.opt.infAirOn then
			ctx.keepAirFast()
		else
			ctx.unprotectAirHealth()
		end
		ctx.fireGod(ctx.opt.infAirOn)
	end)
	ctx.ui.infJumpBtn = ctx.icon("InfJump", "Inf Jump: OFF", function()
		ctx.opt.infJumpOn = not ctx.opt.infJumpOn
		ctx.setInfJumpBtn()
		ctx.saveSoon()
	end)
	ctx.ui.clickTpBtn = ctx.icon("ClickTP", "Click TP: OFF", function()
		ctx.opt.clickTpOn = not ctx.opt.clickTpOn
		ctx.setClickTpBtn()
		ctx.saveSoon()
	end)
	ctx.ui.femVoteBtn = ctx.icon("FemAutoVote", "FEM Auto Vote: OFF", function()
		ctx.opt.femVoteOn = not ctx.opt.femVoteOn
		ctx.setFemVoteBtn()
		ctx.saveSoon()
		if ctx.opt.femVoteOn then
			ctx.startFemAutoVote()
		end
	end, Color3.fromRGB(44, 160, 110))
	ctx.ui.surviveBtn = ctx.icon("SurvivedLoop", "Survived Loop: ON", function()
		ctx.opt.surviveLoopOn = not ctx.opt.surviveLoopOn
		ctx.setSurviveBtn()
		ctx.saveSoon()
	end, Color3.fromRGB(80, 150, 220))
	ctx.ui.nextBtn = ctx.icon("NextButton", "Next Button", function()
		ctx.fireNextButton()
	end, Color3.fromRGB(55, 90, 150))
	ctx.applyProfileUi()
	ctx.ui.rootIcon:setDropdown(ctx.ui.menu)
	ctx.setBtn()
	ctx.setAuraBtn()
	ctx.setDistModeBtn()
	ctx.setDistBtn()
	ctx.setBonusBtn()
	ctx.setChallengeBtn()
	ctx.setFloodBtn()
	ctx.setPaidBtn()
	ctx.setBuyCoinBtn()
	ctx.setBuyGemBtn()
	ctx.setClipBtn()
	ctx.setFePhysicsBtn()
	ctx.setRescueBtn()
	ctx.setDevBtn()
	ctx.setZipBtn()
	ctx.setZipStopBtn()
	ctx.setZipAutoBtn()
	ctx.setInfAirBtn()
	ctx.setInfJumpBtn()
	ctx.setClickTpBtn()
	ctx.setFemVoteBtn()
	ctx.setSurviveBtn()
end

ctx.mkUi()
ctx.startPassiveRemotes()
ctx.startButtonAura()
if ctx.support("bonus") then
	ctx.startBonusCollector()
end
if ctx.support("challenges") then
	ctx.startChallenges()
end
if ctx.support("flood") then
	ctx.startFloodColors()
end
ctx.startUiUnlocks()
ctx.startPhysicsOptions()
if ctx.support("femVote") then
	ctx.startFemAutoVote()
end
if ctx.isFEMGame() then
	ctx.startFemButtonCache()
	ctx.startFemZipPatch()
	ctx.startFemZipStop()
end
if LP and LP.Character then
	ctx.hookZipStop(LP.Character)
end
if ctx.opt.zipFastOn and ctx.opt.zipAutoOn then
	task.defer(ctx.reapplyZipSpeed)
end

if LP then
	chC = LP.CharacterAdded:Connect(ctx.onChar)
	if LP.Character then
		ctx.spawnLoop(ctx.onChar, LP.Character)
	end
end

ctx.antiVoid(ctx.curMap)
ctx.note("Ready [" .. ctx.profileName() .. "]")

ctx.spawnLoop(function()
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
