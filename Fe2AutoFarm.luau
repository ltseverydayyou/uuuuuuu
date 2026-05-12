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

local g = (getgenv and getgenv()) or _G or {}
local sh = rawget(_G, "shared")
local host = type(sh) == "table" and sh or (type(g) == "table" and g or nil)

if host and type(host.__lt_af_ctx) == "table" then
	local old = host.__lt_af_ctx
	if type(old.stop) == "function" then
		pcall(old.stop)
	elseif type(old.con) == "table" then
		for _, c in ipairs(old.con) do
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

local function bind(c)
	if c then
		ctx.con[#ctx.con + 1] = c
	end
	return c
end

local function spawnLoop(fn)
	local th = task.spawn(function()
		local ok, err = xpcall(fn, debug.traceback)
		if not ok then
			warn(err)
		end
	end)
	ctx.threads[#ctx.threads + 1] = th
	return th
end

local function cut(c)
	if c then
		pcall(function()
			c:Disconnect()
		end)
	end
end

local function gt(n)
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

local Plr = gt("Players")
local Wsp = gt("Workspace")
local Rsp = gt("ReplicatedStorage")
local Run = gt("RunService")
local Uis = gt("UserInputService")
local Sgui = gt("StarterGui")
local Guis = gt("GuiService")
local Cgui = gt("CoreGui")
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
local plt
local cTab = {}
local locBtns = {}
local pressTimes = setmetatable({}, { __mode = "k" })
local bonusSeen = setmetatable({}, { __mode = "k" })
local locSeq = 0
local roundCur = nil
local roundTotal = nil
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
local optionsOpen = false
local rh
local markSurvived
local pressMapButton
local rootPart
local locatorEntries

local function current()
	return ctx.live and (not host or host.__lt_af_ctx == ctx)
end

local function alive()
	return current() and LP and LP.Parent and Run ~= nil
end

local function killPlat()
	if plt and plt.Parent then
		pcall(function()
			plt:Destroy()
		end)
	end
	plt = nil
end

local function clearLocators()
	locBtns = {}
	locSeq += 1
end

local function releaseRoot()
	if type(rh) ~= "function" then
		return
	end
	local r = select(1, rh(false))
	if r then
		pcall(function()
			r.Anchored = false
		end)
	end
end

local function stop()
	if not ctx.live then
		return
	end
	ctx.live = false
	on = false
	tok += 1
	cur = nil
	cut(aVc)
	cut(nCc)
	cut(nCd1)
	cut(nCd2)
	cut(chC)
	for _, th in ipairs(ctx.threads) do
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
	for _, c in ipairs(ctx.con) do
		cut(c)
	end
	ctx.con = {}
	cTab = {}
	pressTimes = setmetatable({}, { __mode = "k" })
	bonusSeen = setmetatable({}, { __mode = "k" })
	clearLocators()
	auraList = {}
	auraMap = nil
	auraAt = 0
	roundCur = nil
	roundTotal = nil
	roundState = nil
	safeCf = nil
	safeAt = 0
	voidAt = 0
	farmTok += 1
	auraTok += 1
	saveFlushTok += 1
	pendingSaveSig = nil
	killPlat()
	releaseRoot()
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
end

ctx.stop = stop

local function descOf(obj)
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

local function ffc(obj, n, rec)
	if not obj then
		return nil
	end
	local ok, res = pcall(obj.FindFirstChild, obj, n, rec)
	if ok then
		return res
	end
	return nil
end

local function uiPar()
	if type(gethui) == "function" then
		local ok, ui = pcall(gethui)
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

local function note(msg)
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
end

do
	local ok, r = pcall(function()
		local rem = Rsp and Rsp:FindFirstChild("Remote")
		if not rem then
			return nil
		end
		return rem:FindFirstChild("dKgyIXnLdhwvSyEorkEWJJAkgUslGCtR") or rem:FindFirstChild("sTYfsJjxNdIpKgbXIuymAQiYcmAaORRN") or rem:FindFirstChild("AddedWaiting")
	end)
	Lift = ok and r or nil

	local rem = Rsp and Rsp:FindFirstChild("Remote")
	local function addRemote(list, name)
		local obj = rem and rem:FindFirstChild(name)
		if obj and obj:IsA("RemoteEvent") then
			list[#list + 1] = obj
		end
	end

	local pk = rem and rem:FindFirstChild("ReqPasskey")
	if pk and pk:IsA("RemoteFunction") then
		PasskeyRemote = pk
	end

	local rb = rem and rem:FindFirstChild("ReqRebirth")
	if rb and rb:IsA("RemoteEvent") then
		RebirthRemote = rb
	end

	addRemote(PressRemotes, "PressedMapButton")
	addRemote(PressRemotes, "igzyswprgEbMOxwZWHUxvFWNJhDtaODb")
	addRemote(LocatorRemotes, "UpdGoalLocator")
	addRemote(LocatorRemotes, "FiIxfRCqDOTWRKHqFMoRjSaAxXOutMzD")
	addRemote(RoundStatsRemotes, "UpdIngameStats")
	addRemote(RoundStatsRemotes, "flDEUOrLddFXZVDiezUpxyiHWduVnlEC")
	addRemote(LoadedMapRemotes, "LoadedMap")
	addRemote(SurvivedRemotes, "Survived")
	addRemote(PlayerDataRemotes, "UpdPlayerData")
	addRemote(ItemDataRemotes, "ReqItemData")
	addRemote(GameStateRemotes, "UpdateGameState")
end

local function chr(w)
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

function rh(w)
	local c = chr(w)
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

local function pivotRootTo(cf, r, c)
	if typeof(cf) ~= "CFrame" then
		return
	end
	if not r or not r.Parent then
		r = select(1, rh(false))
	end
	if not c or not c.Parent then
		c = chr(false)
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

local function voidY()
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

local function limVel(r, hard)
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

local function saveSafe(r)
	if not r or not r.Parent then
		return
	end
	local y = voidY()
	local pos = r.Position
	if pos.Y > y + FDM then
		safeCf = r.CFrame
		safeAt = os.clock()
	end
end

local function safeMapCf(map, r)
	local y = voidY()
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

local function inState(nm)
	local r = select(1, rh(false))
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

local function activeRun(map, id)
	return alive() and on and cur == map and map and map.Parent and tok == id
end

local function updateRoundStats(stats)
	if type(stats) ~= "table" then
		return
	end
	if type(stats.currentButton) == "number" then
		roundCur = stats.currentButton
	end
	if type(stats.totalButtons) == "number" then
		roundTotal = stats.totalButtons
	end
	if type(stats.gameStatus) == "string" then
		roundState = stats.gameStatus
		local st = stats.gameStatus:lower()
		if st == "ingame" then
			survivedSeen = false
		elseif st == "survived" then
			markSurvived("round")
		end
	end
end

local function buttonsDone()
	if roundState and roundState ~= "ingame" then
		return false
	end
	if type(roundCur) == "number" and type(roundTotal) == "number" then
		return roundCur >= roundTotal
	end
	return false
end

local function isRoundIngame()
	local physical = inState("InGame")
	if type(roundState) == "string" then
		return roundState:lower() == "ingame" or physical
	end
	return physical
end

local function isRand(s)
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

local function mkPlat(r)
	local c = chr(false)
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

local function anyPart(obj)
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
		for _, d in ipairs(descOf(obj)) do
			if d:IsA("BasePart") then
				return d
			end
		end
	end
	return nil
end

local function moveTo(obj, r)
	if not obj or not r or not r.Parent then
		return false
	end
	local p = anyPart(obj)
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

local function findLow(map, name)
	name = tostring(name):lower()
	for _, obj in ipairs(descOf(map)) do
		local nm = obj.Name
		if type(nm) == "string" and nm:lower() == name then
			return obj
		end
	end
	return nil
end

local function collectMapBonuses(map, r, notify)
	if not (map and map.Parent) then
		return false
	end
	if not (r and r.Parent) then
		r = select(1, rh(false))
	end
	if not (r and r.Parent) then
		return false
	end
	local now = os.clock()
	local moved = false
	local pg = findLow(map, "_lostpage")
	if pg and pg.Parent and (not bonusSeen[pg] or now - bonusSeen[pg] > 2) then
		bonusSeen[pg] = now
		local ok = moveTo(pg, r)
		moved = ok or moved
		if ok and notify then
			note("Got Lost Page.")
		end
		task.wait(TPD)
	end

	local ct = findLow(map, "contact")
	if not ct then
		local npc = findLow(map, "npc")
		if npc and npc.Parent then
			ct = npc.Parent:FindFirstChild("Contact") or findLow(map, "contact")
		end
	end
	if ct and ct.Parent and (not bonusSeen[ct] or now - bonusSeen[ct] > 2) then
		bonusSeen[ct] = now
		local ok = moveTo(ct, r)
		moved = ok or moved
		if ok and notify then
			note("Got Escapee.")
		end
		task.wait(TPD)
	end
	return moved
end

local function addBtnEntry(t, src, hit, loc)
	if not hit or not hit:IsA("BasePart") then
		return
	end
	t[#t + 1] = {
		src = src or hit,
		hit = hit,
		loc = loc and true or false,
	}
end

local function scanBtns(map)
	local t = {}
	for _, obj in ipairs(descOf(map)) do
		if obj.ClassName == "Model" then
			local hit = nil
			local hasUi = obj:FindFirstChildWhichIsA("BillboardGui", true) ~= nil
			local hasFuse = ffc(obj, "Fuse", true) ~= nil
			for _, ch in ipairs(obj:GetChildren()) do
				if ch:IsA("BasePart") and tostring(ch.BrickColor) ~= "Medium stone grey" then
					hit = ch
					break
				end
			end
			local hasTouch = hit and ffc(hit, "TouchInterest", true) ~= nil
			if hit and (isRand(obj.Name) or hasUi or hasFuse or hasTouch) then
				if isRand(hit.Name) then
					hit.Name = "Hitbox"
				end
				addBtnEntry(t, obj, hit, false)
			end
		end
	end
	return t
end

local function valOf(obj, names)
	if not obj then
		return nil
	end
	for _, n in ipairs(names) do
		local ok, v = pcall(function()
			return obj:GetAttribute(n)
		end)
		if ok and v ~= nil then
			return v
		end
	end
	for _, d in ipairs(descOf(obj)) do
		if d:IsA("ValueBase") then
			local nm = d.Name:lower():gsub("[^%w]", "")
			for _, n in ipairs(names) do
				if nm == n:lower():gsub("[^%w]", "") then
					return d.Value
				end
			end
		end
	end
	return nil
end

local function numOf(obj)
	local v = valOf(obj, { "ButtonID", "ButtonId", "ButtonIndex", "ButtonNumber", "ButtonNum", "Number", "ID", "Index", "Order" })
	v = tonumber(v)
	if v then
		return v
	end
	local nm = obj and tostring(obj.Name) or ""
	local a = nm:match("%d+")
	return tonumber(a)
end

local function guiOn(obj)
	if not obj then
		return false
	end
	for _, d in ipairs(descOf(obj)) do
		if d:IsA("BillboardGui") and d.Enabled then
			return true
		end
	end
	return false
end

local function auraReady(entry)
	local hit = entry and entry.hit
	local src = entry and entry.src
	if not (hit and hit.Parent) then
		return false
	end
	if entry.loc then
		return true
	end
	local av = valOf(src, { "Active", "IsActive", "Enabled", "Pressable", "CanPress", "Current", "Selected" })
	if av ~= nil then
		return av == true or av == 1 or tostring(av):lower() == "true"
	end
	if type(roundCur) == "number" then
		local n = numOf(src) or numOf(hit)
		if n then
			return n == roundCur or n == roundCur + 1
		end
	end
	if guiOn(src) or guiOn(hit) then
		return true
	end
	return ffc(hit, "TouchInterest", true) ~= nil
end

local function auraEntries(map)
	local t = locatorEntries(map)
	if #t > 0 then
		return t, true
	end
	local now = os.clock()
	if auraMap ~= map or now - auraAt > 0.25 then
		auraMap = map
		auraAt = now
		auraList = {}
		local ok, res = pcall(scanBtns, map)
		if ok and type(res) == "table" then
			for _, entry in ipairs(res) do
				if auraReady(entry) then
					auraList[#auraList + 1] = entry
				end
			end
		end
	end
	for i = #auraList, 1, -1 do
		local entry = auraList[i]
		local hit = entry and entry.hit
		if not (hit and hit.Parent and hit:IsDescendantOf(map) and auraReady(entry)) then
			table.remove(auraList, i)
		end
	end
	return auraList, false
end

local function asPart(v)
	if typeof(v) == "Instance" and v:IsA("BasePart") then
		return v
	end
	if type(v) ~= "table" then
		return nil
	end
	local r = select(1, rh(false))
	local best = nil
	local bestDist = math.huge
	for _, obj in pairs(v) do
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

local function addLocatorBtn(hit, nextHit)
	clearLocators()
	hit = asPart(hit)
	nextHit = asPart(nextHit)
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
		while alive() and locSeq == id and hit and hit.Parent do
			if not auraOn then
				task.wait(0.1)
				continue
			end
			if type(pressMapButton) == "function" and isRoundIngame() then
				local hb = auraUseDistance and type(rootPart) == "function" and rootPart() or nil
				local maxDist = math.max(0, tonumber(auraDist) or 7)
				if not auraUseDistance or (hb and hb.Parent and (hb.Position - hit.Position).Magnitude <= maxDist) then
					pressMapButton(hit)
				end
			end
			task.wait(BSI)
		end
	end)
end

locatorEntries = function(map)
	local t = {}
	for hit, entry in pairs(locBtns) do
		if hit and hit.Parent and (not map or hit:IsDescendantOf(map)) then
			t[#t + 1] = entry
		else
			locBtns[hit] = nil
		end
	end
	return t
end

local function nearestEntry(entries, pos)
	local best = nil
	local bestDist = math.huge
	if not pos then
		return nil
	end
	for _, entry in ipairs(entries) do
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

local function pressAuraEntries(entries, map, allowNearestFallback)
	local hb = type(rootPart) == "function" and rootPart() or nil
	local maxDist = math.max(0, tonumber(auraDist) or 7)
	local pressed = false
	if not hb and auraUseDistance then
		return false
	end

	if not auraUseDistance and allowNearestFallback then
		if not (hb and hb.Parent) then
			return false
		end
		local entry = nearestEntry(entries, hb and hb.Position or nil)
		local hit = entry and entry.hit
		if hit and hit.Parent and (not map or hit:IsDescendantOf(map)) then
			pressMapButton(hit)
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
			if type(pressMapButton) == "function" then
				pressMapButton(hit)
			end
		end
	end
	return pressed
end

local function mergeLocatorBtns(t, map)
	local seen = {}
	for _, entry in ipairs(t) do
		if entry.hit and (not entry.loc or locBtns[entry.hit] == entry) then
			seen[entry.hit] = true
		end
	end
	for hit, entry in pairs(locBtns) do
		if not (hit and hit.Parent) then
			locBtns[hit] = nil
		elseif not seen[hit] and (not map or hit:IsDescendantOf(map)) then
			t[#t + 1] = entry
			seen[hit] = true
		end
	end
	return t
end

local function isFuseBtn(src)
	local f = ffc(src, "Fuse", true)
	if not f and src and src.Parent then
		f = ffc(src.Parent, "Fuse", true)
	end
	return f and f:IsA("ValueBase")
end

local function fuseRange(src, hit)
	local best = nil
	local bestSize = 0
	local root = src
	if hit and hit.Parent and (not root or root == hit) then
		root = hit.Parent
	end
	for _, obj in ipairs(descOf(root)) do
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

local function waitFuseRange(src, hit, keepGoing)
	if keepGoing and not keepGoing() then
		return nil
	end
	return fuseRange(src, hit)
end

local function moveFuseSafe(src, hit, r, keepGoing)
	if keepGoing and not keepGoing() then
		return
	end
	if not hit or not hit.Parent then
		return
	end
	if not r or not r.Parent then
		r = select(1, rh(false))
	end
	if not r or not r.Parent then
		return
	end
	local sp = fuseRange(src, hit)
	local pos = sp and sp.Parent and sp.Position or (hit.Position + Vector3.new(0, ESY, 0))
	pcall(function()
		pivotRootTo(CFrame.new(pos), r)
		r.AssemblyLinearVelocity = Vector3.zero
		r.AssemblyAngularVelocity = Vector3.zero
		r.Anchored = true
	end)
end

pressMapButton = function(hit)
	if not hit or not hit.Parent then
		return
	end
	local now = os.clock()
	local last = pressTimes[hit]
	if last and now - last < PCD then
		return
	end
	pressTimes[hit] = now
	for _, rem in ipairs(PressRemotes) do
		if rem and rem.Parent then
			pcall(function()
				rem:FireServer(hit)
			end)
		end
	end
end

local function startPressLoop(hit, runId, keepGoing)
	if not hit or not hit.Parent then
		return
	end
	task.spawn(function()
		while alive() and on and tok == runId and hit and hit.Parent do
			if type(keepGoing) == "function" and not keepGoing() then
				break
			end
			pressMapButton(hit)
			task.wait(BSI)
		end
	end)
end

local function startAutoFarmButtonSpam(map, runId, entries)
	if not map or not map.Parent then
		return
	end
	entries = type(entries) == "table" and entries or {}
	spawnLoop(function()
		while activeRun(map, runId) and inState("InGame") do
			mergeLocatorBtns(entries, map)
			if not buttonsDone() then
				for i = #entries, 1, -1 do
					local entry = entries[i]
					local hit = entry and entry.hit
					if hit and hit.Parent and hit:IsDescendantOf(map) then
						pressMapButton(hit)
					else
						table.remove(entries, i)
					end
				end
			end
			task.wait(BSI)
		end
	end)
end

local function getPassArg(force)
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

local paintStats

local function dataSig(data)
	local st = data and data.stats
	if type(st) ~= "table" then
		return nil
	end
	local parts = {}
	for k, v in pairs(st) do
		if type(v) ~= "table" and typeof(v) ~= "Instance" then
			parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
		end
	end
	table.sort(parts)
	return table.concat(parts, "|")
end

local function cacheData(data)
	if type(data) == "table" and type(data.stats) == "table" then
		local sig = dataSig(data)
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
		if type(paintStats) == "function" then
			paintStats()
		end
	end
end

local function needXp(lv, rb)
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

paintStats = function()
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
	local req = needXp(lv, rb)
	if req <= 0 then
		req = 1
	end
	local rdy = lv >= 100 and rb < 30 and xp >= req
	local xs = ui:FindFirstChild("XPStats")
	if xs then
		local ic = ffc(xs, "Icon", false)
		local inf = ic and ic:FindFirstChild("Info")
		if inf then
			inf.Text = tostring(lv)
		end
		local xt = xs:FindFirstChild("XP")
		if xt then
			xt.Text = tostring(xp) .. "/" .. tostring(req) .. " XP"
		end
		local pb = ffc(xs, "Percentage", true)
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
		local ca = ffc(cur, "CoinAmt", true)
		local ga = ffc(cur, "GemAmt", true)
		local ct = ca and ffc(ca, "Amount", true)
		local gt = ga and ffc(ga, "Amount", true)
		if ct then
			ct.Text = tostring(st.coins or 0)
		end
		if gt then
			gt.Text = tostring(st.gems or 0)
		end
	end
end

local function canRebirth()
	local st = pdata and pdata.stats
	if type(st) ~= "table" then
		return nil
	end
	local lv = tonumber(st.level) or 0
	local rb = tonumber(st.rebirth) or 0
	local xp = tonumber(st.xp) or 0
	local req = needXp(lv, rb)
	if rb >= 30 or lv < 100 then
		return false
	end
	return req <= 0 or xp >= req
end

local function fireLoaded(key)
	for _, rem in ipairs(LoadedMapRemotes) do
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

local function fireSurvived(key, tm)
	tm = tonumber(tm) or 100
	for _, rem in ipairs(SurvivedRemotes) do
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

local function requestRoundStats()
	for _, rem in ipairs(RoundStatsRemotes) do
		if rem and rem.Parent then
			pcall(function()
				rem:FireServer()
			end)
		end
	end
end

local function requestPlayerData(force)
	local now = os.clock()
	if not force and now - lastData < DRI then
		return
	end
	lastData = now
	local key = getPassArg(false)
	for _, rem in ipairs(ItemDataRemotes) do
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
	for _, rem in ipairs(PlayerDataRemotes) do
		if rem and rem.Parent then
			pcall(function()
				rem:FireServer()
			end)
		end
	end
end

local function tryRebirth(force)
	if not (RebirthRemote and RebirthRemote.Parent) then
		return
	end
	local now = os.clock()
	local okRb = canRebirth()
	if okRb ~= true then
		return
	end
	local gap = RBI
	if not force and now - lastRb < gap then
		return
	end
	lastRb = now
	local key = getPassArg(false)
	pcall(function()
		if key ~= nil then
			RebirthRemote:FireServer(key)
		else
			RebirthRemote:FireServer()
		end
	end)
end

local function statPulse(force)
	local now = os.clock()
	if not force and now - lastStat < SRI then
		return
	end
	lastStat = now
	requestRoundStats()
	requestPlayerData(true)
	task.delay(0.5, function()
		if alive() and on then
			requestPlayerData(true)
			tryRebirth(true)
		end
	end)
end

local function statBurst()
	local now = os.clock()
	if now - lastBurst < 0.5 then
		return
	end
	lastBurst = now
	for _, d in ipairs(RFD) do
		task.delay(d, function()
			if alive() and on then
				requestRoundStats()
				requestPlayerData(true)
				tryRebirth(true)
			end
		end)
	end
end

local function flushStatsAfterSurvival()
	saveFlushTok += 1
	local id = saveFlushTok
	pendingSaveSig = statsSig or ""
	local started = os.clock()
	task.spawn(function()
		while alive() and on and saveFlushTok == id and os.clock() - started < SFT do
			requestRoundStats()
			requestPlayerData(true)
			tryRebirth(true)
			if pendingSaveSig == nil and lastFreshData >= started then
				break
			end
			task.wait(SFI)
		end
		if alive() and on and saveFlushTok == id then
			requestRoundStats()
			requestPlayerData(true)
			tryRebirth(true)
		end
	end)
end

markSurvived = function(src)
	if survivedSeen then
		return
	end
	local now = os.clock()
	survivedSeen = true
	survivedAt = now
	roundState = "survived"
	tok += 1
	releaseRoot()
	statPulse(true)
	statBurst()
	flushStatsAfterSurvival()
	if src then
		note("Survived; refreshing stats")
	end
end

local function burstLoaded()
	local key = getPassArg(false)
	for _ = 1, LDB do
		if not (alive() and on) then
			return
		end
		fireLoaded(key)
		requestRoundStats()
		task.wait(LDI)
	end
end

local function startFarmRemotes()
	farmTok += 1
	local id = farmTok
	task.spawn(function()
		local ka = 0
		local ra = 0
		while alive() and on and farmTok == id do
			local ok, err = xpcall(function()
				local now = os.clock()
				if now >= ka then
					getPassArg(true)
					requestPlayerData(false)
					tryRebirth(false)
					ka = now + 2
				end
				if now >= ra then
					requestRoundStats()
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

local function startPassiveRemotes()
	spawnLoop(function()
		local ra = 0
		local la = 0
		local sa = 0
		while alive() do
			local now = os.clock()
			if now >= la then
				fireLoaded(getPassArg(false))
				la = now + PLI
			end
			if isRoundIngame() and now >= sa then
				fireSurvived(getPassArg(false), 100)
				sa = now + PSI
			end
			if now >= ra then
				requestRoundStats()
				ra = now + RSI
			end
			task.wait(PMW)
		end
	end)
end

for _, rem in ipairs(LocatorRemotes) do
	if rem and rem.Parent then
		bind(rem.OnClientEvent:Connect(function(goal, hit, _, nextHit)
			addLocatorBtn(hit or goal, nextHit)
		end))
	end
end

for _, rem in ipairs(RoundStatsRemotes) do
	if rem and rem.Parent then
		bind(rem.OnClientEvent:Connect(updateRoundStats))
		pcall(function()
			rem:FireServer()
		end)
	end
end

for _, rem in ipairs(PlayerDataRemotes) do
	if rem and rem.Parent then
		bind(rem.OnClientEvent:Connect(cacheData))
	end
end

for _, rem in ipairs(ItemDataRemotes) do
	if rem and rem.Parent then
		bind(rem.OnClientEvent:Connect(function(data)
			cacheData(data)
		end))
	end
end

for _, rem in ipairs(SurvivedRemotes) do
	if rem and rem.Parent then
		bind(rem.OnClientEvent:Connect(function(ok)
			if ok == true or tostring(ok):lower() == "survived" then
				markSurvived("remote")
			end
		end))
	end
end

for _, rem in ipairs(GameStateRemotes) do
	if rem and rem.Parent then
		bind(rem.OnClientEvent:Connect(function(st)
			local state = tostring(st):lower()
			if state ~= "" and state ~= "nil" then
				roundState = state
			end
			if state == "ingame" then
				survivedSeen = false
			elseif state == "survived" then
				markSurvived("state")
			end
		end))
	end
end

requestPlayerData(true)

local function addNc(obj)
	if obj and obj:IsA("BasePart") then
		cTab[obj] = true
	end
end

local function clrNc()
	cTab = {}
	cut(nCd1)
	cut(nCd2)
	nCd1 = nil
	nCd2 = nil
end

local function bindNc(c)
	clrNc()
	if not c then
		return
	end
	addNc(c)
	for _, d in ipairs(descOf(c)) do
		addNc(d)
	end
	nCd1 = c.DescendantAdded:Connect(function(d)
		addNc(d)
	end)
	nCd2 = c.DescendantRemoving:Connect(function(d)
		cTab[d] = nil
	end)
end

local function setNc(v)
	cut(nCc)
	nCc = nil
	clrNc()
	if not v or not Run or not LP then
		return
	end
	bindNc(LP.Character)
	nCc = Run.PreSimulation:Connect(function()
		if not on then
			return
		end
		for p in pairs(cTab) do
			if p and p.Parent then
				p.CanCollide = false
			else
				cTab[p] = nil
			end
		end
	end)
end

local function pushLift()
	local r = select(1, rh(true))
	if not r then
		return
	end
	pcall(function()
		pivotRootTo(r.CFrame + Vector3.new(0, 5, 0), r)
	end)
	while alive() and on and not inState("InLift") do
		task.wait(0.1)
		local rr = select(1, rh(false))
		if not rr then
			continue
		end
		rr.AssemblyLinearVelocity = LFG
		mkPlat(rr)
	end
end

local function doLift()
	if not (on and Lift) then
		return
	end
	pcall(function()
		Lift:FireServer()
	end)
	task.spawn(function()
		local ok, err = xpcall(pushLift, debug.traceback)
		if not ok then
			warn(err)
		end
	end)
end

local function antiVoid(getMap)
	cut(aVc)
	aVc = nil
	if not Run then
		return
	end
	aVc = Run.Heartbeat:Connect(function()
		if not on then
			return
		end
		local r = select(1, rh(false))
		if not r then
			return
		end

		local fy = voidY()
		local pos = r.Position
		local vel = Vector3.zero
		pcall(function()
			vel = r.AssemblyLinearVelocity
		end)

		local nearVoid = pos.Y <= fy + FDM
		local badFall = vel.Y < -VLM and pos.Y <= fy + FDM * 2

		if not nearVoid and not badFall then
			saveSafe(r)
			return
		end

		if nearVoid or badFall then
			limVel(r, nearVoid)
		end

		local map = nil
		local ok, res = pcall(getMap)
		if ok then
			map = res
		end

		local cf = safeMapCf(map, r)
		pcall(function()
			pivotRootTo(cf, r)
		end)
		limVel(r, true)
		mkPlat(r)

		if os.clock() - voidAt > 1 then
			voidAt = os.clock()
			note("Recovered from void")
		end
	end)
end

local function setBtn()
	if not btn then
		return
	end
	btn.Text = on and "Stop AutoFarm" or "Start AutoFarm"
	btn.BackgroundColor3 = on and Color3.fromRGB(180, 60, 60) or Color3.fromRGB(60, 180, 60)
end

local function setAuraBtn()
	if not auraBtn then
		return
	end
	auraBtn.Text = auraOn and "Button Aura: ON" or "Button Aura: OFF"
	auraBtn.BackgroundColor3 = auraOn and Color3.fromRGB(60, 130, 210) or Color3.fromRGB(70, 70, 70)
end

local function setDistModeBtn()
	if not distModeBtn then
		return
	end
	distModeBtn.Text = auraUseDistance and "Button Distance: ON" or "Button Distance: OFF"
	distModeBtn.BackgroundColor3 = auraUseDistance and Color3.fromRGB(60, 130, 210) or Color3.fromRGB(70, 70, 70)
end

local function setDistBtn()
	if not distBtn then
		return
	end
	distBtn.Text = tostring(auraDist)
end

local function setBonusBtn()
	if not bonusBtn then
		return
	end
	bonusBtn.Text = autoCollectBonuses and "Collect Bonuses: ON" or "Collect Bonuses: OFF"
	bonusBtn.BackgroundColor3 = autoCollectBonuses and Color3.fromRGB(60, 130, 210) or Color3.fromRGB(70, 70, 70)
end

local function setOptionsOpen(open)
	optionsOpen = open and true or false
	if optBtn then
		optBtn.Text = optionsOpen and "Options ^" or "Options v"
	end
	if optionsFrame then
		optionsFrame.Visible = optionsOpen
	end
	if panel then
		panel.Size = optionsOpen and UDim2.new(0, 190, 0, 285) or UDim2.new(0, 190, 0, 105)
	end
end

local mouseButtonFixHooks = setmetatable({}, { __mode = "k" })

local function tryDisconnect(conn)
	if conn and type(conn.Disconnect) == "function" then
		pcall(function()
			conn:Disconnect()
		end)
	end
end

local function MouseButtonFix(button, clickCallback, pressInput)
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
		tryDisconnect(existing)
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
			tryDisconnect(connections[i])
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

function NAgui.dragger(ui, dragui)
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
		tryDisconnect(moveConn)
		tryDisconnect(endConn)
		tryDisconnect(stepConn)
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
			tryDisconnect(connections[i])
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
		for _, g in ipairs(list) do
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

local function toggle(v)
	on = v and true or false
	tok += 1
	cur = nil
	clearLocators()
	survivedSeen = false
	setBtn()
	note(on and "Enabled" or "Disabled")
	setNc(on)
	farmTok += 1

	if not on then
		saveFlushTok += 1
		pendingSaveSig = nil
		releaseRoot()
		killPlat()
		return
	end

	startFarmRemotes()
	task.spawn(burstLoaded)
	requestPlayerData(true)

	if inState("InGame") then
		note("Resuming current map")
	else
		doLift()
	end
end

local function onChar(c)
	if not alive() then
		return
	end
	bindNc(c)
	if on then
		task.spawn(function()
			if not Lift then
				return
			end
			for _ = 1, RRP do
				if not (alive() and on) then
					return
				end
				pcall(function()
					Lift:FireServer()
				end)
				task.wait(RRG)
			end
		end)
		task.spawn(function()
			local ok, err = xpcall(pushLift, debug.traceback)
			if not ok then
				warn(err)
			end
		end)
	end
end

local function onMap(map, id)
	local hp
	local ok, err = xpcall(function()
		local r, h = rh(true)
		if not r or not h or not map or not map.Parent then
			return
		end
		safeCf = r.CFrame
		safeAt = os.clock()

		local st = ffc(map, "Settings", false)
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
		note("Map Loaded! " .. tostring(nm))
		task.spawn(burstLoaded)

		if not inState("InGame") then
			note("Skipping due to InGame == false.")
			cur = nil
			return
		end

		local btns = {}
		local ok2, res = pcall(scanBtns, map)
		if ok2 and type(res) == "table" then
			btns = res
		end
		mergeLocatorBtns(btns, map)
		startAutoFarmButtonSpam(map, id, btns)

		collectMapBonuses(map, r, true)

		note("Commencing Auto Farm")

		hp = h:GetPropertyChangedSignal("Health"):Connect(function()
			pcall(function()
				if h.Parent and h.Health < 1000 then
					h.Health = 1000
				end
			end)
		end)

		roundCur = nil
		roundTotal = nil
		roundState = nil
		for _, rem in ipairs(RoundStatsRemotes) do
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

		while activeRun(map, id) and inState("InGame") do
			task.wait(SCI)
			if not (activeRun(map, id) and inState("InGame")) then
				break
			end

			r, h = rh(false)
			if not r or not h then
				continue
			end

			pcall(function()
				h.Jump = true
			end)

			local ex = ffc(map, "ExitRegion", true)
			mergeLocatorBtns(btns, map)
			local statsExpected = #RoundStatsRemotes > 0
			local exitReady = ex and (buttonsDone() or (not statsExpected and roundCur == nil and roundTotal == nil))

			if waitLocSeq and locSeq ~= waitLocSeq then
				waitLocSeq = nil
			end

			local pressFirst = not exitReady
			if exitReady then
				for _, entry in ipairs(btns) do
					if entry.loc and entry.hit and entry.hit.Parent and locBtns[entry.hit] == entry then
						pressFirst = true
						break
					end
				end
			end

			if exitReady and not pressFirst and waitLocSeq and os.clock() - waitLocAt < LHW then
				mkPlat(r)
				continue
			end

			if pressFirst then
				for _, entry in ipairs(btns) do
					if not activeRun(map, id) then
						break
					end

					local b = entry.src
					local hit = entry.hit
					local key = entry.loc and entry or hit
					local currentLoc = not entry.loc or locBtns[hit] == entry
					local canPress = entry.loc or not (exitReady and sent[key])
					if currentLoc and canPress and (not exitReady or entry.loc) and hit and hit.Parent then
						local ti = ffc(hit, "TouchInterest", true) or ffc(b, "TouchInterest", true)
						local gg = nil
						pcall(function()
							gg = (b and b:FindFirstChildWhichIsA("BillboardGui", true)) or hit:FindFirstChildWhichIsA("BillboardGui", true)
						end)
						if entry.loc or (ti and gg) then
							r, h = rh(false)
							if not r or not h then
								break
							end
							if not activeRun(map, id) then
								break
							end
							local fuse = isFuseBtn(b)
							pcall(function()
								r.Anchored = false
								pivotRootTo(CFrame.new(hit.Position), r)
								h:ChangeState(Enum.HumanoidStateType.Jumping)
								r.Velocity = JMP
							end)
							task.wait(TPD)
							if not activeRun(map, id) then
								releaseRoot()
								break
							end
							local now = os.clock()
							if entry.loc then
								if not lastPress[key] or now - lastPress[key] >= PCD then
									lastPress[key] = now
									pressMapButton(hit)
									waitLocSeq = entry.seq
									waitLocAt = now
								end
							elseif not sent[key] then
								sent[key] = true
								if not pressLoops[key] then
									pressLoops[key] = true
									startPressLoop(hit, id, function()
										return activeRun(map, id) and inState("InGame") and not buttonsDone()
									end)
								end
								pressMapButton(hit)
							end
							if fuse then
								moveFuseSafe(b, hit, r, function()
									return activeRun(map, id)
								end)
							else
								pcall(function()
									pivotRootTo(CFrame.new(hit.Position + Vector3.new(0, ESY, 0)), r)
									r.Anchored = true
								end)
							end
							task.wait(BTD)
							if not activeRun(map, id) then
								releaseRoot()
								break
							end
						end
					end
				end
			else
				if not activeRun(map, id) then
					break
				end
				pcall(function()
					r.Anchored = false
				end)
				if tr < EXM then
					tr += 1
					pcall(function()
						pivotRootTo(ex.CFrame, r)
						h:ChangeState(Enum.HumanoidStateType.Landed)
						r.Velocity = EXP
					end)
					mkPlat(r)
					task.wait(TPD)
					if not activeRun(map, id) then
						releaseRoot()
						break
					end
					if (r.Position - ex.Position).Magnitude <= 5 then
						tr += 1
						fireSurvived(getPassArg(false), 100)
						local now = os.clock()
						if now - lastExitPulse >= 0.5 then
							lastExitPulse = now
							statPulse(false)
							statBurst()
							if pendingSaveSig == nil then
								flushStatsAfterSurvival()
							end
						end
					end
				else
					tr = 0
					mkPlat(r)
					task.wait(TPD)
					if not activeRun(map, id) then
						releaseRoot()
						break
					end
				end
			end
		end
	end, debug.traceback)

	cut(hp)

	if not ok then
		warn(err)
		note("Map handler error; continuing")
	end

	if not activeRun(map, id) then
		clearLocators()
		releaseRoot()
		return
	end

	local r = select(1, rh(false))
	if r then
		mkPlat(r)
	end

	if not (alive() and on) then
		return
	end

	note("Complete. Waiting for next map..")

	while alive() and on do
		task.wait(0.2)
		local m = MP and MP:FindFirstChild("Map") or nil
		local rr = select(1, rh(false))
		if rr then
			mkPlat(rr)
		end
		if m and m ~= map then
			clearLocators()
			break
		end
	end
end

local function curMap()
	if not MP or not MP.Parent then
		MP = Wsp and (Wsp:FindFirstChild("Multiplayer") or Wsp:WaitForChild("Multiplayer", 3)) or nil
	end
	return MP and MP:FindFirstChild("Map") or nil
end

rootPart = function()
	local c = chr(false)
	if not c then
		return nil
	end
	return c:FindFirstChild("HumanoidRootPart", true)
end

local function startButtonAura()
	auraTok += 1
	local id = auraTok
	spawnLoop(function()
		local map = nil
		local req = 0
		while alive() and auraTok == id do
			if not auraOn then
				task.wait(0.1)
				map = nil
				auraList = {}
				auraMap = nil
				continue
			end

			local m = curMap()
			if m ~= map then
				map = m
				auraList = {}
				auraMap = nil
			end

			local now = os.clock()
			if now >= req then
				requestRoundStats()
				req = now + 0.25
			end

			if map and isRoundIngame() and type(pressMapButton) == "function" then
				local entries, hasLoc = auraEntries(map)
				if #entries > 0 then
					pressAuraEntries(entries, map, not hasLoc)
				end
			end

			task.wait(ASI)
		end
	end)
end

local function startBonusCollector()
	spawnLoop(function()
		while alive() do
			if autoCollectBonuses and isRoundIngame() then
				local map = curMap()
				if map then
					local r = select(1, rh(false))
					collectMapBonuses(map, r, true)
				end
			end
			task.wait(0.35)
		end
	end)
end

if MP then
	bind(MP.ChildAdded:Connect(function(ch)
		if ch.Name == "Map" and on then
			task.spawn(burstLoaded)
		end
	end))
end

local function mkUi()
	local par = uiPar()
	if not par then
		return
	end

	local old = ffc(par, "AF_Toggle", false)
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
	optionsFrame.Size = UDim2.new(1, -20, 0, 175)
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

	bind(NAgui.dragger(panel))

	bind(MouseButtonFix(btn, function()
		toggle(not on)
	end))

	bind(MouseButtonFix(optBtn, function()
		setOptionsOpen(not optionsOpen)
	end))

	bind(MouseButtonFix(auraBtn, function()
		auraOn = not auraOn
		setAuraBtn()
	end))

	bind(MouseButtonFix(distModeBtn, function()
		auraUseDistance = not auraUseDistance
		setDistModeBtn()
	end))

	bind(distBtn.FocusLost:Connect(function()
		local n = tonumber(distBtn.Text)
		if n then
			auraDist = math.clamp(math.floor(n + 0.5), 1, 100)
		end
		setDistBtn()
	end))

	bind(MouseButtonFix(bonusBtn, function()
		autoCollectBonuses = not autoCollectBonuses
		setBonusBtn()
	end))

	setBtn()
	setOptionsOpen(false)
	setAuraBtn()
	setDistModeBtn()
	setDistBtn()
	setBonusBtn()
end

mkUi()
startPassiveRemotes()
startButtonAura()
startBonusCollector()

if LP then
	chC = LP.CharacterAdded:Connect(onChar)
	if LP.Character then
		task.spawn(onChar, LP.Character)
	end
end

antiVoid(curMap)
note("Ready")

task.spawn(function()
	while alive() do
		local ok, err = xpcall(function()
			task.wait(SCI)
			if not on then
				return
			end
			local m = curMap()
			local ig = inState("InGame")
			if m and ig and m ~= cur then
				cur = m
				tok += 1
				local id = tok
				note("New Map")
				onMap(m, id)
			elseif not m or not ig then
				cur = nil
			end
		end, debug.traceback)

		if not ok then
			warn(err)
			note("Loop error; continuing")
			task.wait(0.25)
		end
	end
end)
