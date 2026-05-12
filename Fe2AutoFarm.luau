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

if host and type(host.__lt_af_ctx) == "table" and type(host.__lt_af_ctx.stop) == "function" then
	pcall(host.__lt_af_ctx.stop)
end

local ctx = {
	live = true,
	con = {},
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
local SCI = 0.05
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
local PCD = 0.15
local FDM = 160
local VLM = 20
local RCH = 12

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
local plt
local drag = false
local dPos
local bPos
local cTab = {}
local locBtns = {}
local locSeq = 0
local roundCur = nil
local roundTotal = nil
local roundState = nil
local safeCf = nil
local safeAt = 0
local voidAt = 0
local farmTok = 0
local rh

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
	drag = false
	cut(aVc)
	cut(nCc)
	cut(nCd1)
	cut(nCd2)
	cut(chC)
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
	locBtns = {}
	locSeq += 1
	roundCur = nil
	roundTotal = nil
	roundState = nil
	safeCf = nil
	safeAt = 0
	voidAt = 0
	farmTok += 1
	killPlat()
	releaseRoot()
	if gui and gui.Parent then
		pcall(function()
			gui:Destroy()
		end)
	end
	gui = nil
	btn = nil
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
local PasskeyRemote = nil
local passKey = nil
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

	addRemote(PressRemotes, "PressedMapButton")
	addRemote(PressRemotes, "igzyswprgEbMOxwZWHUxvFWNJhDtaODb")
	addRemote(LocatorRemotes, "UpdGoalLocator")
	addRemote(LocatorRemotes, "FiIxfRCqDOTWRKHqFMoRjSaAxXOutMzD")
	addRemote(RoundStatsRemotes, "UpdIngameStats")
	addRemote(RoundStatsRemotes, "flDEUOrLddFXZVDiezUpxyiHWduVnlEC")
	addRemote(LoadedMapRemotes, "LoadedMap")
	addRemote(SurvivedRemotes, "Survived")
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
		return
	end
	local p = anyPart(obj)
	if not p then
		return
	end
	if obj:IsA("Model") then
		pcall(function()
			obj:PivotTo(r.CFrame)
		end)
	else
		p:PivotTo(r.CFrame)
	end
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
	locSeq += 1
	locBtns = {}
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

local function pressMapButton(hit)
	if not hit or not hit.Parent then
		return
	end
	for _, rem in ipairs(PressRemotes) do
		if rem and rem.Parent then
			pcall(function()
				rem:FireServer(hit)
			end)
		end
	end
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

local function fireFarmRemotes()
	local key = getPassArg(false)
	if key == nil then
		return
	end
	for _, rem in ipairs(LoadedMapRemotes) do
		if rem and rem.Parent then
			pcall(function()
				rem:FireServer(key)
			end)
		end
	end
	for _, rem in ipairs(SurvivedRemotes) do
		if rem and rem.Parent then
			pcall(function()
				rem:FireServer(key, 100)
			end)
		end
	end
end

local function startFarmRemotes()
	farmTok += 1
	local id = farmTok
	task.spawn(function()
		getPassArg(true)
		while alive() and on and farmTok == id do
			fireFarmRemotes()
			task.wait(0.15)
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
	if not Lift then
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

local function toggle(v)
	on = v and true or false
	tok += 1
	cur = nil
	setBtn()
	note(on and "Enabled" or "Disabled")
	setNc(on)
	farmTok += 1

	if not on then
		releaseRoot()
		killPlat()
		return
	end

	startFarmRemotes()

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
	task.spawn(function()
		if Lift then
			for _ = 1, RRP do
				if not alive() then
					return
				end
				pcall(function()
					Lift:FireServer()
				end)
				task.wait(RRG)
			end
		end
	end)
	if on then
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

		note("Map Loaded! " .. tostring(nm))

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

		local pg = findLow(map, "_lostpage")
		if pg then
			moveTo(pg, r)
			task.wait(TPD)
			note("Got Lost Page.")
		end

		local ct = findLow(map, "contact")
		if not ct then
			local npc = findLow(map, "npc")
			if npc and npc.Parent then
				ct = npc.Parent:FindFirstChild("Contact") or findLow(map, "contact")
			end
		end
		if ct then
			moveTo(ct, r)
			task.wait(TPD)
			note("Got Escapee.")
		end

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

	btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 160, 0, 50)
	btn.Position = UDim2.new(0.5, -80, 0, 10)
	btn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 20
	btn.Text = "Start AutoFarm"
	btn.Active = true
	btn.Parent = gui

	bind(btn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag = true
			dPos = i.Position
			bPos = btn.Position
		end
	end))

	if Uis then
		bind(Uis.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				drag = false
			end
		end))

		bind(Uis.InputChanged:Connect(function(i)
			if not drag then
				return
			end
			if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			if not dPos or not bPos or not btn then
				return
			end
			local d = i.Position - dPos
			btn.Position = UDim2.new(bPos.X.Scale, bPos.X.Offset + d.X, bPos.Y.Scale, bPos.Y.Offset + d.Y)
		end))
	end

	bind(btn.MouseButton1Click:Connect(function()
		toggle(not on)
	end))

	setBtn()
end

mkUi()

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
