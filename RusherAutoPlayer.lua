local __lt = (function()
	local ge = {}
	pcall(function()
		if type(getgenv) == "function" then
			ge = getgenv()
		end
	end)
	if type(ge) ~= "table" then
		ge = type(_G) == "table" and _G or {}
	end

	local sh = nil
	pcall(function()
		if type(_G) == "table" then
			sh = rawget(_G, "shared")
		end
	end)
	if type(sh) ~= "table" then
		pcall(function()
			sh = shared
		end)
	end

	local host = type(sh) == "table" and sh or (type(ge) == "table" and ge or nil)
	local srUrl = "https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/ServiceResolver.luau"

	local geturl = function(url)
		local ok, body = pcall(function()
			return game:HttpGet(url)
		end)
		if ok and type(body) == "string" and body ~= "" then
			return body
		end

		local req = nil
		pcall(function()
			req = type(request) == "function" and request or nil
		end)
		if type(req) ~= "function" then
			pcall(function()
				req = type(http) == "table" and type(http.request) == "function" and http.request or nil
			end)
		end
		if type(req) ~= "function" then
			pcall(function()
				req = type(syn) == "table" and type(syn.request) == "function" and syn.request or nil
			end)
		end
		if type(req) ~= "function" then
			pcall(function()
				req = type(http_request) == "function" and http_request or nil
			end)
		end

		if type(req) == "function" then
			local ok2, res = pcall(req, {
				Url = url,
				Method = "GET"
			})
			local b = type(res) == "table" and (res.Body or res.body) or nil
			if ok2 and type(b) == "string" and b ~= "" then
				return b
			end
		end

		return nil
	end

	local loadurl = function(url, chunk)
		local body = geturl(url)
		local ld = loadstring or load
		if type(body) ~= "string" or type(ld) ~= "function" then
			return nil
		end

		local fn = ld(body, chunk or ("@" .. tostring(url)))
		if type(fn) ~= "function" then
			return nil
		end

		local ok, lib = pcall(fn)
		if ok and type(lib) == "table" then
			return lib
		end

		return nil
	end

	local sr = nil

	if host then
		pcall(function()
			local old = rawget(host, "__lt_service_resolver")
			if type(old) == "table" then
				sr = old
			end
		end)
	end

	sr = sr or loadurl(srUrl, "@ServiceResolver.luau")

	if host and type(sr) == "table" then
		pcall(function()
			host.__lt_service_resolver = sr
		end)
	end

	if type(sr) ~= "table" then
		sr = {
			cs = function(n, cr)
				if type(cr) == "function" then
					local ok2, r = pcall(function()
						return cr(game:GetService(n))
					end)
					if ok2 and r then
						return r
					end
				end
				local ok3, s = pcall(function()
					return game:GetService(n)
				end)
				if ok3 then
					return s
				end
				return nil
			end,
			gs = function(n)
				local ok3, s = pcall(function()
					return game:GetService(n)
				end)
				if ok3 then
					return s
				end
				return nil
			end,
			cm = function(n, m, ...)
				local ok2, s = pcall(function()
					return game:GetService(n)
				end)
				if not ok2 or not s or type(s[m]) ~= "function" then
					return nil
				end
				return s[m](s, ...)
			end
		}
	end

	return sr
end)()

local A = {}
A.ex = {}
pcall(function()
	if type(getfenv) == "function" then
		A.ex = getfenv()
	end
end)
if type(A.ex) ~= "table" then
	A.ex = {}
end

A.globs = {}
A.addglob = function(g)
	if type(g) ~= "table" then
		return
	end
	for _, v in ipairs(A.globs) do
		if v == g then
			return
		end
	end
	table.insert(A.globs, g)
end
A.addglob(A.ex)
pcall(function()
	if type(getgenv) == "function" then
		A.addglob(getgenv())
	end
end)
if type(_G) == "table" then
	A.addglob(_G)
end
pcall(function()
	if type(shared) == "table" then
		A.addglob(shared)
	end
end)
pcall(function()
	if type(_G) == "table" and type(rawget(_G, "shared")) == "table" then
		A.addglob(rawget(_G, "shared"))
	end
end)

local old = nil
for _, g in ipairs(A.globs) do
	pcall(function()
		if type(rawget(g, "__rusher_obs")) == "table" then
			old = rawget(g, "__rusher_obs")
		end
	end)
end
if type(old) == "table" and type(old.cln) == "function" then
	pcall(old.cln)
end
for _, g in ipairs(A.globs) do
	pcall(function()
		g.__rusher_obs = A
	end)
end
A.ex.__rusher_obs = A

A.run = true
A.con = {}
A.envs = {}
A.envnames = { "game", "song", "menu", "cfg", "assist", "load", "caj", "news", "outside", "room", "tutorial", "dialog", "chartmod" }
A.vars = {}
A.last = {}
A.keys = {}
A.upq = {}
A.mode = "none"
A.bind = "__rusher_obs_step"
A.cfg = {
	ap = false,
	imode = "Direct (Engine)", 
	timingmode = "Perfect (0ms)", 
	jitter = 0,         
	off = 0,            
	reloff = 0,         
	tdur = 15,          
	clead = 45,         
	ctail = 120,        
	bombavoid = true,   
	caj = false,        
	cwin = 55,          
	autonews = false,   
	ninp = false,       
	keep = false,       
	speed = 1,
	voff = 0,
	tw = 2,
	notecolor = 2,
	bgdim = 0,
	comboposition = 1,
	combotransparency = 0,
	clumpaces = 1,
	newrating = 1,
	pm = 1,
	em = 1,
	he = 1,
	guide = 2,
	hit = 2,
	hurt = 2,
	partner = "lester"
}

A.inputmodes = {
	"Direct (Engine)",
	"Virtual Input",
	"FireSignal",
	"Connections",
	"Auto"
}

A.timingmodes = {
	"Perfect (0ms)",
	"Humanized"
}

A.svc = function(n)
	if type(__lt) == "table" then
		if type(__lt.cs) == "function" then
			local ok, s = pcall(__lt.cs, n, cloneref)
			if ok and s then
				return s
			end
		end
		if type(__lt.gs) == "function" then
			local ok, s = pcall(__lt.gs, n)
			if ok and s then
				return s
			end
		end
	end

	if type(cloneref) == "function" then
		local ok, r = pcall(function()
			return cloneref(game:GetService(n))
		end)
		if ok and r then
			return r
		end
	end
	return game:GetService(n)
end

A.plrs = A.svc("Players")
A.rs = A.svc("RunService")
A.sg = A.svc("StarterGui")
A.uis = A.svc("UserInputService")
A.hsvc = A.svc("HttpService")
A.vim = nil
A.lp = A.plrs.LocalPlayer
A.pg = A.lp and A.lp:WaitForChild("PlayerGui", 30)

A.add = function(c)
	if c then
		table.insert(A.con, c)
	end
	return c
end

A.scr = function(n)
	local pg = A.pg or (A.lp and A.lp:FindFirstChild("PlayerGui"))
	if not pg then
		return nil
	end

	if n == "game" then
		return pg:FindFirstChild("gameplay_script")
	elseif n == "song" then
		return pg:FindFirstChild("songselect_script")
	elseif n == "menu" then
		return pg:FindFirstChild("menu_script")
	elseif n == "cfg" then
		return pg:FindFirstChild("configs")
	elseif n == "assist" then
		return pg:FindFirstChild("assist_scripts")
	elseif n == "news" then
		return pg:FindFirstChild("news_script")
	elseif n == "outside" then
		return pg:FindFirstChild("outside_script")
	elseif n == "room" then
		return pg:FindFirstChild("roomsearch_script")
	elseif n == "tutorial" then
		return pg:FindFirstChild("tutorial_script")
	elseif n == "dialog" then
		local d = pg:FindFirstChild("dialogue")
		return d and d:FindFirstChild("dialoguesystem")
	elseif n == "load" then
		local l = pg:FindFirstChild("loading")
		return l and l:FindFirstChild("initializer")
	elseif n == "caj" then
		local m = pg:FindFirstChild("minigame")
		return m and m:FindFirstChild("cajon")
	elseif n == "chartmod" then
		local ch = nil
		for _, nm in ipairs({ "song", "load", "game", "menu" }) do
			local e = A.envs[nm] or A.fenv(A.scr(nm))
			local g = A.gtab(e)
			if type(g) == "table" and type(g.currentsong) == "table" then
				ch = g.currentsong
				break
			end
		end
		local id = type(ch) == "table" and tostring(ch.chart_id or "") or ""
		local charts = workspace:FindFirstChild("Charts")
		local f = id ~= "" and charts and charts:FindFirstChild(id) or nil
		return f and f:FindFirstChild("mod") or nil
	end

	return nil
end


A.fenv = function(s)
	if not s then
		return nil
	end

	if type(getsenv) == "function" then
		local ok, e = pcall(getsenv, s)
		if ok and type(e) == "table" then
			return e
		end
	end

	if type(getfenv) == "function" then
		local ok, e = pcall(getfenv, s)
		if ok and type(e) == "table" then
			return e
		end
	end

	if type(getscriptclosure) == "function" and type(getfenv) == "function" then
		local ok, f = pcall(getscriptclosure, s)
		if ok and type(f) == "function" then
			local ok2, e = pcall(getfenv, f)
			if ok2 and type(e) == "table" then
				return e
			end
		end
	end

	return nil
end

A.gtab = function(e)
	if type(e) ~= "table" then
		return nil
	end
	local ok, g = pcall(function()
		return rawget(e, "_G")
	end)
	if ok and type(g) == "table" then
		return g
	end
	ok, g = pcall(function()
		return e._G
	end)
	if ok and type(g) == "table" then
		return g
	end
	return e
end

A.env = function(n)
	if A.envs[n] then
		return A.envs[n]
	end
	local s = A.scr(n)
	local e = A.fenv(s)
	if type(e) == "table" then
		A.envs[n] = e
		return e
	end
	return nil
end

A.envall = function()
	local out = {}
	local seen = {}
	for _, n in ipairs(A.envnames) do
		local e = A.env(n)
		if type(e) == "table" and not seen[e] then
			seen[e] = true
			table.insert(out, e)
		end
	end
	return out
end

A.gkeys = {
	"currentchart",
	"currentsong",
	"currentdiff",
	"currentdifficulty",
	"currentfolder",
	"selectedsong",
	"beattime",
	"currentbpm",
	"noinput",
	"CONFIGURATIONS",
	"partner",
	"playing",
	"waitabit",
	"chartid",
	"songid"
}

A.pullg = function()
	for _, e in ipairs(A.envall()) do
		local g = A.gtab(e)
		if type(g) == "table" then
			for _, k in ipairs(A.gkeys) do
				local v = rawget(g, k)
				if v == nil then
					pcall(function()
						v = g[k]
					end)
				end
				if v ~= nil then
					A.vars[k] = v
				end
			end
		end
	end
end

A.gget = function(k)
	A.pullg()
	for _, e in ipairs(A.envall()) do
		local g = A.gtab(e)
		if type(g) == "table" then
			local ok, v = pcall(function()
				return g[k]
			end)
			if ok and v ~= nil then
				return v
			end
		end
	end
	return A.vars[k]
end

A.gset = function(k, v)
	A.vars[k] = v
	for _, e in ipairs(A.envall()) do
		local g = A.gtab(e)
		if type(g) == "table" then
			pcall(function()
				g[k] = v
			end)
		end
		pcall(function()
			e[k] = v
		end)
	end
end

A.call = function(sc, fn, ...)
	local e = A.env(sc)
	if not e or type(e[fn]) ~= "function" then
		return false
	end
	return pcall(e[fn], ...)
end

A.fire = function(n, ...)
	local sw = A.sg:FindFirstChild("switchscreen")
	if sw and type(sw.Fire) == "function" then
		return pcall(function(...)
			sw:Fire(...)
		end, n, ...)
	end
	return false
end

A.conf = function(k, v)
	local c = A.gget("CONFIGURATIONS")
	if type(c) ~= "table" then
		c = {}
		A.gset("CONFIGURATIONS", c)
	end
	c[k] = v
	A.gset("CONFIGURATIONS", c)

	local e = A.env("cfg")
	if e and type(e.updatevalue) == "function" then
		pcall(e.updatevalue, k, v)
	end
end

A.hooks = {
	script = nil,
	env = nil,
	inputFn = nil,
	releaseFn = nil,
	applylockFn = nil,
	heartbeatFn = nil,
	startFn = nil,
	tapQueue = nil,
	catchQueue = nil,
	relQueue = nil,
	bombQueue = nil,
	lastResolve = 0
}

function A.resolveHooks(force)
	local now = os.clock()
	if not force and A.hooks.env and (now - A.hooks.lastResolve < 0.5) then
		return A.hooks
	end
	A.hooks.lastResolve = now

	local pg = A.pg or (A.lp and A.lp:FindFirstChild("PlayerGui"))
	if not pg then
		return nil
	end
	local gs = pg:FindFirstChild("gameplay_script")
	if not gs then
		return nil
	end

	local env = A.fenv(gs)
	if type(env) ~= "table" or type(env.input) ~= "function" then
		return nil
	end

	A.hooks.script = gs
	A.hooks.env = env
	A.hooks.inputFn = env.input
	A.hooks.applylockFn = env.applylock
	A.hooks.heartbeatFn = env.heartbeat
	A.hooks.startFn = env.start

	if type(debug) == "table" and type(debug.getupvalues) == "function" then
		local inUps = debug.getupvalues(env.input)
		if type(inUps) == "table" then
			A.hooks.tapQueue = type(inUps[13]) == "table" and inUps[13] or nil
			A.hooks.bombQueue = type(inUps[12]) == "table" and inUps[12] or nil
		end
	end

	if type(env.applylock) == "function" and type(debug) == "table" and type(debug.getupvalues) == "function" then
		local lockUps = debug.getupvalues(env.applylock)
		if type(lockUps) == "table" then
			A.hooks.catchQueue = type(lockUps[1]) == "table" and lockUps[1] or nil
			if not A.hooks.tapQueue and type(lockUps[2]) == "table" then
				A.hooks.tapQueue = lockUps[2]
			end
		end
	end

	if type(env.start) == "function" and type(debug) == "table" and type(debug.getupvalues) == "function" then
		local startUps = debug.getupvalues(env.start)
		if type(startUps) == "table" then
			local relFn = startUps[94]
			if type(relFn) == "function" then
				A.hooks.releaseFn = relFn
				local relUps = debug.getupvalues(relFn)
				if type(relUps) == "table" then
					
					A.hooks.relQueue = type(relUps[7]) == "table" and relUps[7] or nil
				end
			end
		end
	end

	if not (A.hooks.tapQueue and A.hooks.catchQueue and A.hooks.relQueue and A.hooks.bombQueue) then
		local function scanQueues(fn)
			if type(fn) ~= "function" or type(debug) ~= "table" or type(debug.getupvalues) ~= "function" then
				return
			end
			local ups = debug.getupvalues(fn)
			if type(ups) ~= "table" then
				return
			end
			for _, val in pairs(ups) do
				if type(val) == "table" and #val > 0 then
					local item = val[1]
					if type(item) == "table" and type(item.notetype) == "string" then
						if item.notetype == "tap" or item.notetype == "ln" then
							A.hooks.tapQueue = A.hooks.tapQueue or val
						elseif item.notetype == "catch" then
							A.hooks.catchQueue = A.hooks.catchQueue or val
						elseif item.notetype == "release" then
							A.hooks.relQueue = A.hooks.relQueue or val
						elseif item.notetype == "bomb" then
							A.hooks.bombQueue = A.hooks.bombQueue or val
						end
					end
				end
			end
		end
		scanQueues(A.hooks.inputFn)
		scanQueues(A.hooks.applylockFn)
		scanQueues(A.hooks.heartbeatFn)
		scanQueues(A.hooks.releaseFn)
	end

	return A.hooks
end


A.getGameState = function()
	local h = A.resolveHooks()
	if not h or not h.env or not h.inputFn then
		return nil
	end

	local env = h.env
	local inUps = (type(debug) == "table" and type(debug.getupvalues) == "function") and debug.getupvalues(h.inputFn) or nil
	if type(inUps) ~= "table" then
		return nil
	end

	
	
	
	
	
	local songTime = tonumber(inUps[15]) or 0
	local window = tonumber(inUps[14]) or 0.075
	local isStopped = inUps[2] == true
	local isAnyInput = inUps[10] == true

	local isPlaying = false
	local g = A.gtab(env)
	if type(g) == "table" and g.playing == true then
		isPlaying = true
	end
	if not isStopped and songTime > 0 then
		isPlaying = true
	end

	return {
		env = env,
		hooks = h,
		songTime = songTime,
		window = window,
		isPlaying = isPlaying,
		isStopped = isStopped,
		isAnyInput = isAnyInput,
		currentnote = tonumber(env.currentnote) or 1,
		currentcatch = tonumber(env.currentcatch) or 1,
		currentrel = tonumber(env.currentrel) or 1,
		currentbomb = tonumber(env.currentbomb) or 1,
		tapQueue = h.tapQueue,
		catchQueue = h.catchQueue,
		relQueue = h.relQueue,
		bombQueue = h.bombQueue,
		inputFn = h.inputFn,
		releaseFn = h.releaseFn
	}
end




A.kpool = {
	Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.J, Enum.KeyCode.K,
	Enum.KeyCode.S, Enum.KeyCode.L, Enum.KeyCode.A, Enum.KeyCode.Semicolon,
	Enum.KeyCode.Q, Enum.KeyCode.W, Enum.KeyCode.E, Enum.KeyCode.R,
	Enum.KeyCode.U, Enum.KeyCode.I, Enum.KeyCode.O, Enum.KeyCode.P
}

A.hpool = {
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four,
	Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight
}

A.rkey = Enum.KeyCode.P
A.ckey = Enum.KeyCode.KeypadZero
A.kidx = 1
A.hidx = 1

A.nextKeyFrom = function(pool, idxName)
	pool = pool or A.kpool
	if #pool == 0 then
		return Enum.KeyCode.F
	end
	local start = A[idxName] or 1
	for _ = 1, #pool do
		local k = pool[start]
		start = start + 1
		if start > #pool then
			start = 1
		end
		A[idxName] = start
		if k and not A.keys[k] then
			return k
		end
	end
	return pool[1]
end

A.nextTapKey = function()
	return A.nextKeyFrom(A.kpool, "kidx")
end

A.nextHoldKey = function()
	return A.nextKeyFrom(A.hpool, "hidx") or A.nextTapKey()
end

A.fakeInput = function(k, down)
	return {
		KeyCode = k or Enum.KeyCode.F,
		UserInputType = Enum.UserInputType.Keyboard,
		UserInputState = (down == false) and Enum.UserInputState.End or Enum.UserInputState.Begin,
		Position = Vector3.zero
	}
end

A.getvim = function()
	if A.vim and typeof(A.vim) == "Instance" then
		return A.vim
	end
	local ok, v = pcall(function()
		return A.svc("VirtualInputManager")
	end)
	if ok and v then
		A.vim = v
		return v
	end
	return nil
end

A.vkey = function(k, down)
	if not k or typeof(k) ~= "EnumItem" then
		return false
	end
	local v = A.getvim()
	if not v then
		return false
	end
	return pcall(function()
		v:SendKeyEvent(down == true, k, false, nil)
	end)
end

A.firesig = function(sig, k, down)
	if not sig or not k or type(firesignal) ~= "function" then
		return false
	end
	return pcall(firesignal, sig, A.fakeInput(k, down), false)
end

A.connkey = function(sig, k, down)
	if not sig or not k or type(getconnections) ~= "function" then
		return false
	end
	local ok, cons = pcall(getconnections, sig)
	if not ok or type(cons) ~= "table" then
		return false
	end

	local inp = A.fakeInput(k, down)
	local fired = false
	for _, c in ipairs(cons) do
		local enabled = true
		pcall(function()
			if c.Enabled == false then
				enabled = false
			end
		end)
		if enabled then
			local ok2 = false
			if type(c.Fire) == "function" then
				ok2 = pcall(c.Fire, c, inp, false)
			elseif type(c.fire) == "function" then
				ok2 = pcall(c.fire, c, inp, false)
			else
				local fn = nil
				pcall(function()
					fn = c.Function or c._function
				end)
				if type(fn) == "function" then
					ok2 = pcall(fn, inp, false)
				end
			end
			if ok2 then
				fired = true
			end
		end
	end
	return fired
end

A.inputsignal = function(down)
	return (down == false) and A.uis.InputEnded or A.uis.InputBegan
end


A.dispatchKey = function(k, down, mode)
	if not k then
		return false
	end
	mode = mode or A.cfg.imode or "Direct (Engine)"

	if mode == "Direct (Engine)" then
		local h = A.resolveHooks()
		if h and h.env then
			if down then
				if type(h.inputFn) == "function" then
					return pcall(h.inputFn, A.fakeInput(k, true), false)
				end
			else
				if type(h.releaseFn) == "function" then
					return pcall(h.releaseFn, A.fakeInput(k, false), false)
				end
			end
		end
		
		return A.vkey(k, down)
	elseif mode == "Virtual Input" then
		return A.vkey(k, down)
	elseif mode == "FireSignal" then
		return A.firesig(A.inputsignal(down), k, down)
	elseif mode == "Connections" then
		return A.connkey(A.inputsignal(down), k, down)
	elseif mode == "Auto" then
		local h = A.resolveHooks()
		if h and h.env and type(h.inputFn) == "function" then
			local ok = false
			if down then
				ok = pcall(h.inputFn, A.fakeInput(k, true), false)
			else
				if type(h.releaseFn) == "function" then
					ok = pcall(h.releaseFn, A.fakeInput(k, false), false)
				end
			end
			if ok then
				return true
			end
		end
		if A.vkey(k, down) then
			return true
		end
		if A.firesig(A.inputsignal(down), k, down) then
			return true
		end
		return A.connkey(A.inputsignal(down), k, down)
	end

	return false
end

A.pressKey = function(k)
	if not k then
		return false
	end
	A.keys[k] = true
	return A.dispatchKey(k, true)
end

A.releaseKey = function(k)
	if not k then
		return false
	end
	A.keys[k] = nil
	return A.dispatchKey(k, false)
end

A.scheduleRelease = function(k, t)
	if not k then
		return false
	end
	table.insert(A.upq, {
		k = k,
		t = t or os.clock()
	})
	return true
end

A.flushReleaseQueue = function()
	local now = os.clock()
	for i = #A.upq, 1, -1 do
		local it = A.upq[i]
		if it then
			local k = it.k
			if not k or not A.keys[k] then
				table.remove(A.upq, i)
			elseif now >= (tonumber(it.t) or now) then
				A.releaseKey(k)
				table.remove(A.upq, i)
			end
		end
	end
end

A.resetkeys = function()
	A.upq = {}
	for k in pairs(A.keys) do
		A.releaseKey(k)
	end
	A.keys = {}
	A.activeHolds = {}
	A.catchActive = false
	A.lastProcessedNote = nil
	A.lastProcessedRel = nil
end

A.tapKey = function(k, dur)
	k = k or A.nextTapKey()
	if not k then
		return false
	end
	A.pressKey(k)
	local d = math.clamp((tonumber(dur) or A.cfg.tdur or 15) / 1000, 0.005, 0.06)
	A.scheduleRelease(k, os.clock() + d)
	return true
end




A.activeHolds = {}
A.catchActive = false
A.lastSongTime = 0
A.lastProcessedNote = nil
A.lastProcessedRel = nil


A.calcTargetTime = function(realStime)
	if not realStime then
		return nil
	end
	local target = realStime

	
	local uOff = (tonumber(A.cfg.off) or 0) / 1000
	target = target + uOff

	
	local c = A.gget("CONFIGURATIONS")
	if type(c) == "table" and c.offsetvisual then
		target = target - (tonumber(c.offsetvisual) or 0) / 1000
	end

	
	if A.cfg.timingmode == "Humanized" then
		local jMax = math.max(0, tonumber(A.cfg.jitter) or 0) / 1000
		if jMax > 0 then
			local jitter = (math.random() * 2 - 1) * jMax
			target = target + jitter
		end
	end

	return target
end


A.isBombBlocking = function(state)
	if not A.cfg.bombavoid or not state.bombQueue then
		return false
	end
	local cb = state.currentbomb
	local bq = state.bombQueue
	if cb > #bq then
		return false
	end

	local bomb = bq[cb]
	if type(bomb) ~= "table" or bomb.notetype ~= "bomb" or bomb.hitted == true then
		return false
	end

	local bTime = tonumber(bomb.real_stime)
	if not bTime then
		return false
	end

	local dist = bTime - state.songTime
	
	local win = state.window
	if dist > -win * 0.3 and dist < win * 1.5 then
		return true, bomb
	end

	return false
end


A.processCatch = function(state)
	local cq = state.catchQueue
	if not cq or state.currentcatch > #cq then
		if A.catchActive then
			A.releaseKey(A.ckey)
			A.catchActive = false
		end
		return
	end

	
	if A.isBombBlocking(state) then
		if A.catchActive then
			A.releaseKey(A.ckey)
			A.catchActive = false
		end
		return
	end

	local note = cq[state.currentcatch]
	if type(note) ~= "table" or note.miss == true or (note.acc and note.acc > 0) then
		return
	end

	local st = tonumber(note.real_stime) or state.songTime
	local dist = st - state.songTime
	local lead = math.max((tonumber(A.cfg.clead) or 45) / 1000, state.window * 1.2)
	local tail = math.max((tonumber(A.cfg.ctail) or 120) / 1000, state.window * 1.5)

	if dist <= lead and dist > -tail then
		if not A.catchActive then
			A.pressKey(A.ckey)
			A.catchActive = true
		end
	elseif dist > lead or dist <= -tail then
		if A.catchActive then
			A.releaseKey(A.ckey)
			A.catchActive = false
		end
	end
end


A.processReleases = function(state)
	local now = state.songTime
	local relOff = (tonumber(A.cfg.reloff) or 0) / 1000

	
	local rq = state.relQueue
	if rq and state.currentrel <= #rq then
		local relNote = rq[state.currentrel]
		if type(relNote) == "table" and relNote.miss ~= true and relNote.hitted ~= true then
			local st = tonumber(relNote.real_stime)
			if st then
				local target = st + relOff
				if now >= target and (now - target) <= state.window * 2 then
					local relId = tostring(relNote.id or state.currentrel)
					if A.lastProcessedRel ~= relId then
						A.lastProcessedRel = relId

						
						local holdKey = nil
						for id, hold in pairs(A.activeHolds) do
							holdKey = hold.key
							A.activeHolds[id] = nil
							break
						end
						holdKey = holdKey or A.rkey
						A.releaseKey(holdKey)

						
						if A.cfg.imode == "Direct (Engine)" and type(relNote.hit) == "function" then
							pcall(function()
								relNote:hit(now, false)
							end)
							if relNote.acc and relNote.acc > 0 then
								state.env.currentrel = state.currentrel + 1
							end
						end
					end
				end
			end
		end
	end

	
	for id, hold in pairs(A.activeHolds) do
		local et = tonumber(hold.etime)
		if et and et > 0 and now >= et + relOff then
			if hold.key then
				A.releaseKey(hold.key)
			end
			A.activeHolds[id] = nil
		end
	end
end


A.processTaps = function(state)
	local tq = state.tapQueue
	if not tq or state.currentnote > #tq then
		return
	end

	local note = tq[state.currentnote]
	if type(note) ~= "table" or note.fake == true or note.hitted == true or note.miss == true then
		return
	end

	
	if A.isBombBlocking(state) then
		return
	end

	local st = tonumber(note.real_stime)
	if not st then
		return
	end

	local target = A.calcTargetTime(st)
	local now = state.songTime

	
	if now < target then
		return
	end
	if (now - target) > math.max(state.window * 2, 0.15) then
		return
	end

	local noteId = tostring(note.id or state.currentnote)
	if A.lastProcessedNote == noteId then
		return
	end
	A.lastProcessedNote = noteId

	local isLN = (note.notetype == "ln")
	local imode = A.cfg.imode or "Direct (Engine)"

	if isLN then
		local holdKey = A.nextHoldKey()
		A.pressKey(holdKey)
		A.activeHolds[noteId] = {
			key = holdKey,
			note = note,
			etime = tonumber(note.real_etime) or (st + 0.5)
		}
	else
		if imode == "Direct (Engine)" then
			
			A.dispatchKey(Enum.KeyCode.F, true, "Direct (Engine)")
		else
			local k = A.nextTapKey()
			A.tapKey(k, A.cfg.tdur)
		end
	end
end


A.liveplay = function()
	A.flushReleaseQueue()

	local state = A.getGameState()
	if not state or not state.isPlaying then
		if A.catchActive or next(A.activeHolds) ~= nil then
			A.resetkeys()
		end
		return false
	end

	
	if state.songTime < A.lastSongTime - 0.5 then
		A.resetkeys()
	end
	A.lastSongTime = state.songTime

	
	
	A.processReleases(state)

	
	A.processCatch(state)

	
	A.processTaps(state)

	return true
end




A.cajon = function()
	local e = A.env("caj")
	if not e or type(e.input) ~= "function" then
		return
	end

	if type(debug) ~= "table" or type(debug.getupvalues) ~= "function" then
		return
	end
	local ups = debug.getupvalues(e.input)
	if type(ups) ~= "table" then
		return
	end

	
	
	
	
	
	
	local ready = ups[4]
	if ready ~= true then
		return
	end

	local list = ups[5]
	local idx = tonumber(ups[6])
	local bar = tonumber(ups[7])
	local tim = tonumber(ups[8])

	if type(list) ~= "table" or not idx or not bar or not tim then
		return
	end

	local note = list[idx]
	if type(note) ~= "number" then
		return
	end

	local dst = math.abs((note + bar) * 0.6 - tim)
	local win = math.clamp((tonumber(A.cfg.cwin) or 55) / 1000, 0.015, 0.10)

	if dst <= win then
		local id = tostring(idx) .. ":" .. tostring(bar)
		if A.last.caj ~= id then
			A.last.caj = id
			pcall(e.input, {
				UserInputType = Enum.UserInputType.Keyboard,
				KeyCode = Enum.KeyCode.Space,
				Position = Vector3.zero
			})
		end
	end
end




A.sync = function()
	A.conf("speed", A.cfg.speed)
	A.conf("offset", A.cfg.off)
	A.conf("offsetvisual", A.cfg.voff)
	A.conf("tw", A.cfg.tw)
	A.conf("notecolor", A.cfg.notecolor)
	A.conf("bgdim", A.cfg.bgdim)
	A.conf("comboposition", A.cfg.comboposition)
	A.conf("combotransparency", A.cfg.combotransparency)
	A.conf("clumpaces", A.cfg.clumpaces)
	A.conf("newrating", A.cfg.newrating)
	A.conf("pm", A.cfg.pm)
	A.conf("em", A.cfg.em)
	A.conf("hebeta", A.cfg.he)
	A.conf("guideenable", A.cfg.guide)
	A.conf("hitsoundenable", A.cfg.hit)
	A.conf("disablehurtanimation", A.cfg.hurt)
end

A.pick = function(p)
	A.cfg.partner = p
	A.gset("partner", p)

	A.call("song", "select_partner", p)
	A.call("assist", "selectassist", p)

	for _, n in ipairs({ "song", "assist" }) do
		local e = A.env(n)
		if e and type(e.playerdata) == "table" then
			pcall(function()
				e.playerdata.partner = p
				if type(e.playerdata.savepartner) == "function" then
					e.playerdata.savepartner()
				end
			end)
		end
	end
end

A.cln = function()
	A.run = false
	A.cfg.ap = false
	A.cfg.caj = false
	A.resetkeys()

	pcall(function()
		if type(A.rs.UnbindFromRenderStep) == "function" then
			A.rs:UnbindFromRenderStep(A.bind)
		end
	end)

	for _, c in ipairs(A.con) do
		pcall(function()
			c:Disconnect()
		end)
	end
	A.con = {}
end


A.step = function()
	if not A.run then
		return
	end

	A.pullg()
	A.flushReleaseQueue()

	if A.cfg.ap then
		A.liveplay()
		A.mode = "live:" .. tostring(A.cfg.imode or "Direct (Engine)")
	else
		A.mode = "none"
	end

	if A.cfg.caj then
		A.cajon()
	end

	if A.cfg.autonews then
		A.call("news", "close")
	end

	if A.cfg.ninp then
		A.gset("noinput", false)
	end

	if A.cfg.keep then
		A.sync()
	end
end


pcall(function()
	if type(A.rs.UnbindFromRenderStep) == "function" then
		A.rs:UnbindFromRenderStep(A.bind)
	end
end)

if type(A.rs.BindToRenderStep) == "function" then
	local ok = pcall(function()
		A.rs:BindToRenderStep(A.bind, 401, A.step)
	end)
	if not ok then
		if A.rs.RenderStepped then
			A.add(A.rs.RenderStepped:Connect(A.step))
		else
			A.add(A.rs.Heartbeat:Connect(A.step))
		end
	end
elseif A.rs.RenderStepped then
	A.add(A.rs.RenderStepped:Connect(A.step))
else
	A.add(A.rs.Heartbeat:Connect(A.step))
end




A.dir = "RusherAutoplayer"
A.afile = A.dir .. "/autoload.txt"

A.cname = function()
	local n = "default"
	pcall(function()
		if Options and Options.RusherConfigName and Options.RusherConfigName.Value ~= nil then
			n = tostring(Options.RusherConfigName.Value)
		end
	end)
	n = n:gsub("[^%w%-%_ ]", "_")
	if n == "" then
		n = "default"
	end
	return n
end

A.cfile = function(n)
	n = tostring(n or A.cname()):gsub("[^%w%-%_ ]", "_")
	if n == "" then
		n = "default"
	end
	return A.dir .. "/" .. n .. ".json", n
end

A.mkdir = function()
	if type(isfolder) == "function" and type(makefolder) == "function" then
		local ok, yes = pcall(isfolder, A.dir)
		if not ok or not yes then
			pcall(makefolder, A.dir)
		end
	end
end

A.signore = {
	MenuKeybind = true,
	RusherConfigName = true,
	SaveManager_ConfigList = true,
	SaveManager_ConfigName = true
}

A.objsave = function()
	local dat = { objects = {} }
	local function add(idx, obj)
		if type(idx) ~= "string" or A.signore[idx] or type(obj) ~= "table" or obj.Type == nil then
			return
		end
		if obj.Type == "Toggle" then
			table.insert(dat.objects, { type = "Toggle", idx = idx, value = obj.Value })
		elseif obj.Type == "Slider" then
			table.insert(dat.objects, { type = "Slider", idx = idx, value = tostring(obj.Value) })
		elseif obj.Type == "Dropdown" then
			table.insert(dat.objects, { type = "Dropdown", idx = idx, value = obj.Value, multi = obj.Multi })
		elseif obj.Type == "ColorPicker" and obj.Value and type(obj.Value.ToHex) == "function" then
			table.insert(dat.objects, { type = "ColorPicker", idx = idx, value = obj.Value:ToHex(), transparency = obj.Transparency })
		elseif obj.Type == "KeyPicker" then
			table.insert(dat.objects, { type = "KeyPicker", idx = idx, mode = obj.Mode, key = obj.Value, modifiers = obj.Modifiers })
		elseif obj.Type == "Input" then
			table.insert(dat.objects, { type = "Input", idx = idx, text = obj.Value })
		end
	end

	for idx, obj in pairs(type(Toggles) == "table" and Toggles or {}) do
		add(idx, obj)
	end
	for idx, obj in pairs(type(Options) == "table" and Options or {}) do
		add(idx, obj)
	end
	return dat
end

A.objload = function(dat)
	if type(dat) ~= "table" then
		return false
	end

	local function setctl(o, v)
		if type(o) ~= "table" then
			return false
		end
		if type(o.SetValue) == "function" then
			return pcall(o.SetValue, o, v)
		end
		if type(o.SetValueRGB) == "function" then
			return pcall(o.SetValueRGB, o, v)
		end
		return pcall(function()
			o.Value = v
		end)
	end

	if type(dat.objects) == "table" then
		for _, it in ipairs(dat.objects) do
			local idx = type(it) == "table" and it.idx or nil
			local typ = type(it) == "table" and it.type or nil
			if type(idx) == "string" and not A.signore[idx] then
				local obj = (typ == "Toggle") and Toggles[idx] or Options[idx] or (Toggles and Toggles[idx])
				if obj then
					if typ == "ColorPicker" and type(obj.SetValueRGB) == "function" and type(it.value) == "string" then
						pcall(function()
							obj:SetValueRGB(Color3.fromHex(it.value), it.transparency)
						end)
					elseif typ == "KeyPicker" and type(obj.SetValue) == "function" then
						pcall(function()
							obj:SetValue({ it.key, it.mode, it.modifiers })
						end)
					elseif typ == "Input" and type(it.text) == "string" then
						setctl(obj, it.text)
					elseif it.value ~= nil then
						setctl(obj, it.value)
					end
				end
			end
		end
		A.sync()
		return true
	end
	return false
end

A.fsave = function(n)
	if type(writefile) ~= "function" then
		return false
	end
	A.mkdir()
	local ok, body = pcall(function()
		return A.hsvc:JSONEncode(A.objsave())
	end)
	if not ok then
		return false
	end
	return pcall(writefile, A.cfile(n), body)
end

A.fload = function(n)
	if type(readfile) ~= "function" or type(isfile) ~= "function" then
		return false
	end
	local file = A.cfile(n)
	local ok, yes = pcall(isfile, file)
	if not ok or not yes then
		return false
	end
	local ok2, body = pcall(readfile, file)
	if not ok2 then
		return false
	end
	local ok3, dat = pcall(function()
		return A.hsvc:JSONDecode(body)
	end)
	if not ok3 or type(dat) ~= "table" then
		return false
	end
	return A.objload(dat)
end

A.asave = function(n)
	if type(writefile) ~= "function" then
		return false
	end
	A.mkdir()
	return pcall(writefile, A.afile, tostring(n or A.cname()))
end

A.aload = function()
	if type(readfile) ~= "function" or type(isfile) ~= "function" then
		return false
	end
	local ok, yes = pcall(isfile, A.afile)
	if not ok or not yes then
		return false
	end
	local ok2, n = pcall(readfile, A.afile)
	if not ok2 then
		return false
	end
	return A.fload(n)
end

A.geturl = function(url)
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and type(body) == "string" and body ~= "" then
		return body
	end
	local req = (type(request) == "function" and request)
		or (type(http) == "table" and http.request)
		or (type(syn) == "table" and syn.request)
		or (type(http_request) == "function" and http_request)
	if type(req) == "function" then
		local ok2, res = pcall(req, { Url = url, Method = "GET" })
		local b = type(res) == "table" and (res.Body or res.body) or nil
		if ok2 and type(b) == "string" and b ~= "" then
			return b
		end
	end
	return nil
end

A.ldurl = function(url, name)
	local ld = loadstring or load
	if type(ld) ~= "function" then
		return false, nil
	end
	local body = A.geturl(url)
	if type(body) ~= "string" then
		return false, nil
	end
	local ok, fn = pcall(ld, body, name or "@chunk")
	if not ok or type(fn) ~= "function" then
		return false, nil
	end
	return pcall(fn)
end




local okLib, Library = A.ldurl("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua", "@Obsidian.lua")
if not okLib or type(Library) ~= "table" or type(Library.CreateWindow) ~= "function" then
	warn("Rusher Autoplayer: Obsidian UI library unavailable, running in headless mode")
	A.envall()
	A.sync()
	return A
end

local Options = Library.Options
local Toggles = Library.Toggles
local ThemeManager = nil
local SaveManager = nil

pcall(function()
	local okTm, tm = A.ldurl("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua", "@ThemeManager.lua")
	if okTm and type(tm) == "table" then
		ThemeManager = tm
	end
end)

pcall(function()
	local okSm, sm = A.ldurl("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua", "@SaveManager.lua")
	if okSm and type(sm) == "table" then
		SaveManager = sm
	end
end)

if type(ThemeManager) == "table" then
	pcall(function()
		ThemeManager:SetLibrary(Library)
		ThemeManager:SetFolder("RusherAutoplayer")
	end)
end

if type(SaveManager) == "table" then
	pcall(function()
		SaveManager:SetLibrary(Library)
		SaveManager:IgnoreThemeSettings()
		SaveManager:SetIgnoreIndexes({ "MenuKeybind", "RusherConfigName" })
		SaveManager:SetFolder("RusherAutoplayer")
		SaveManager:SetLoadingOrder(true, { "Toggle", "Dropdown", "Slider", "ColorPicker", "KeyPicker", "Input" })
	end)
end

A.smcfg = function(n)
	n = n or A.cname()
	local ok = false
	if type(SaveManager) == "table" and type(SaveManager.Save) == "function" then
		local ok0, ret = pcall(function()
			return SaveManager:Save(n)
		end)
		ok = ok0 and ret == true
	end
	return ok or A.fsave(n)
end

A.lmcfg = function(n)
	n = n or A.cname()
	local ok = false
	if type(SaveManager) == "table" and type(SaveManager.Load) == "function" then
		local ok0, ret = pcall(function()
			return SaveManager:Load(n)
		end)
		ok = ok0 and ret == true
	end
	return ok or A.fload(n)
end

A.amcfg = function(n)
	n = n or A.cname()
	local ok = false
	if type(SaveManager) == "table" then
		if type(SaveManager.SaveAutoloadConfig) == "function" then
			local ok0, ret = pcall(function()
				return SaveManager:SaveAutoloadConfig(n)
			end)
			ok = ok0 and ret == true
		elseif type(SaveManager.SetAutoloadConfig) == "function" then
			local ok0, ret = pcall(function()
				return SaveManager:SetAutoloadConfig(n)
			end)
			ok = ok0 and ret == true
		end
	end
	return ok or A.asave(n)
end

A.lacfg = function()
	local ok = false
	if type(SaveManager) == "table" and type(SaveManager.LoadAutoloadConfig) == "function" then
		local ok0 = pcall(function()
			SaveManager:LoadAutoloadConfig()
		end)
		ok = ok0 == true
	end
	return ok or A.aload()
end

local W = Library:CreateWindow({
	Title = "Project : RUSHER | Autoplayer Revamp",
	Footer = "Obsidian UI | Revamped Engine",
	Center = true,
	AutoShow = true,
	ToggleKeybind = Enum.KeyCode.RightControl
})

local T = {
	Main = W:AddTab("Main", "play"),
	Config = W:AddTab("Config", "settings"),
	Settings = W:AddTab("UI Settings", "wrench")
}

local M1 = T.Main:AddLeftGroupbox("Auto Player Engine")
local M2 = T.Main:AddRightGroupbox("Game Controls")
local C1 = T.Config:AddLeftGroupbox("Gameplay Options")
local C2 = T.Config:AddRightGroupbox("Audio & Visuals")
local S1 = T.Settings:AddLeftGroupbox("Menu Preferences")


M1:AddToggle("RusherAutoPlay", {
	Text = "Enable Auto Player",
	Default = false,
	Tooltip = "Frame-synchronized engine autoplayer. Automatically tracks notes, holds, catches, and releases.",
	Callback = function(v)
		A.cfg.ap = v
		if not v then
			A.resetkeys()
		end
	end
})

M1:AddDropdown("RusherInputMode", {
	Text = "Input Execution Mode",
	Values = A.inputmodes,
	Default = 1,
	Multi = false,
	Tooltip = "Direct (Engine): 100% ACE rate, zero latency via internal engine calls.\nVirtual Input: Simulates real keyboard input via VirtualInputManager.\nFireSignal: Invokes InputBegan signals.\nConnections: Directly fires input listeners.",
	Callback = function(v)
		A.cfg.imode = tostring(v or "Direct (Engine)")
		A.resetkeys()
	end
})

M1:AddDropdown("RusherTimingMode", {
	Text = "Timing Accuracy Mode",
	Values = A.timingmodes,
	Default = 1,
	Multi = false,
	Tooltip = "Perfect (0ms): Exact note target timing (max ACE/Perfect score).\nHumanized: Applies subtle realistic jitter to score distributions.",
	Callback = function(v)
		A.cfg.timingmode = tostring(v or "Perfect (0ms)")
	end
})

M1:AddSlider("RusherJitter", {
	Text = "Humanization Jitter",
	Default = 0,
	Min = 0,
	Max = 30,
	Rounding = 0,
	Suffix = "ms",
	Tooltip = "Random timing variance applied when Humanized mode is enabled.",
	Callback = function(v)
		A.cfg.jitter = v
	end
})

M1:AddSlider("RusherOffset", {
	Text = "Hit Timing Offset",
	Default = 0,
	Min = -80,
	Max = 80,
	Rounding = 0,
	Suffix = "ms",
	Tooltip = "Shifts note tap timing earlier or later to compensate for hardware latency.",
	Callback = function(v)
		A.cfg.off = v
	end
})

M1:AddSlider("RusherRelOffset", {
	Text = "Hold Release Offset",
	Default = 0,
	Min = -50,
	Max = 50,
	Rounding = 0,
	Suffix = "ms",
	Tooltip = "Fine-tunes the release timing of Long Notes.",
	Callback = function(v)
		A.cfg.reloff = v
	end
})

M1:AddToggle("RusherBombAvoid", {
	Text = "Smart Bomb Avoidance",
	Default = true,
	Tooltip = "Automatically suppresses key presses and releases catch holds when a bomb note approaches.",
	Callback = function(v)
		A.cfg.bombavoid = v
	end
})

M1:AddSlider("RusherCatchLead", {
	Text = "Catch Lead Window",
	Default = 45,
	Min = 15,
	Max = 120,
	Rounding = 0,
	Suffix = "ms",
	Tooltip = "How early to prepare and hold the catch key before a catch note stream.",
	Callback = function(v)
		A.cfg.clead = v
	end
})

M1:AddSlider("RusherCatchTail", {
	Text = "Catch Release Tail",
	Default = 120,
	Min = 40,
	Max = 250,
	Rounding = 0,
	Suffix = "ms",
	Tooltip = "Delay before releasing the catch key after the last catch note in a cluster.",
	Callback = function(v)
		A.cfg.ctail = v
	end
})

M1:AddDivider()

M1:AddToggle("RusherCajonAuto", {
	Text = "Cajon Minigame Auto",
	Default = false,
	Tooltip = "Automatically plays the Cajon rhythm minigame using synchronized beat timings.",
	Callback = function(v)
		A.cfg.caj = v
	end
})

M1:AddSlider("RusherCajonWindow", {
	Text = "Cajon Hit Window",
	Default = 55,
	Min = 15,
	Max = 100,
	Rounding = 0,
	Suffix = "ms",
	Callback = function(v)
		A.cfg.cwin = v
	end
})

M1:AddToggle("RusherAutoNews", {
	Text = "Auto Close News",
	Default = false,
	Tooltip = "Automatically dismisses news/patch popups.",
	Callback = function(v)
		A.cfg.autonews = v
	end
})

M1:AddToggle("RusherNoInput", {
	Text = "Force NoInput Off",
	Default = false,
	Tooltip = "Overrides the game's internal noinput lock flag.",
	Callback = function(v)
		A.cfg.ninp = v
		if v then
			A.gset("noinput", false)
		end
	end
})


M2:AddButton({
	Text = "Open Song Select",
	Func = function()
		A.fire("songselect", true)
	end
})

M2:AddButton({
	Text = "Play Selected Song",
	Func = function()
		A.call("song", "play")
	end
})

M2:AddButton({
	Text = "Random Song",
	Func = function()
		A.call("song", "randomize")
	end
})

M2:AddButton({
	Text = "Open Main Menu",
	Func = function()
		A.fire("menu")
	end
})

M2:AddButton({
	Text = "Start Cajon Minigame",
	Func = function()
		A.fire("cajon")
	end
})

M2:AddButton({
	Text = "Release All Keys / Reset",
	Func = function()
		A.resetkeys()
		Library:Notify("Released all held keys and reset cursors.", 3)
	end
})

M2:AddButton({
	Text = "Re-resolve Engine Hooks",
	Func = function()
		A.hooks.env = nil
		A.resolveHooks(true)
		Library:Notify("Engine hooks re-resolved successfully!", 3)
	end
})

M2:AddDropdown("RusherPartner", {
	Text = "Select Partner",
	Values = {
		"iris",
		"lester",
		"lisa",
		"rae",
		"ziera",
		"bellemond",
		"aetheria"
	},
	Default = 2,
	Multi = false,
	Callback = function(v)
		A.pick(v)
	end
})


C1:AddSlider("RusherSpeed", {
	Text = "Note Scroll Speed",
	Default = 1,
	Min = 0.25,
	Max = 5,
	Rounding = 2,
	Callback = function(v)
		A.cfg.speed = v
		A.conf("speed", v)
	end
})

C1:AddSlider("RusherGameOffset", {
	Text = "Game Audio Offset",
	Default = 0,
	Min = -500,
	Max = 500,
	Rounding = 0,
	Suffix = "ms",
	Callback = function(v)
		A.conf("offset", v)
	end
})

C1:AddSlider("RusherVOffset", {
	Text = "Game Visual Offset",
	Default = 0,
	Min = -500,
	Max = 500,
	Rounding = 0,
	Suffix = "ms",
	Callback = function(v)
		A.cfg.voff = v
		A.conf("offsetvisual", v)
	end
})

C1:AddDropdown("RusherTW", {
	Text = "Judgement Timing Window",
	Values = { "Easy", "Normal", "Strict" },
	Default = 2,
	Multi = false,
	Callback = function(v)
		local n = (v == "Easy") and 1 or ((v == "Normal") and 2 or 3)
		A.cfg.tw = n
		A.conf("tw", n)
	end
})

C1:AddDropdown("RusherNoteColor", {
	Text = "Note Color Scheme",
	Values = { "Gray", "Beat Color", "Direction", "Subdivision Chain" },
	Default = 2,
	Multi = false,
	Callback = function(v)
		local n = table.find({ "Gray", "Beat Color", "Direction", "Subdivision Chain" }, v) or 2
		A.cfg.notecolor = n
		A.conf("notecolor", n)
	end
})

C1:AddSlider("RusherBGDim", {
	Text = "Background Dim",
	Default = 0,
	Min = 0,
	Max = 0.8,
	Rounding = 2,
	Callback = function(v)
		A.cfg.bgdim = v
		A.conf("bgdim", v)
	end
})

C1:AddDropdown("RusherComboPosition", {
	Text = "Combo Display Position",
	Values = { "Bottom", "Middle", "Top" },
	Default = 1,
	Multi = false,
	Callback = function(v)
		local n = (v == "Middle") and 2 or ((v == "Top") and 3 or 1)
		A.cfg.comboposition = n
		A.conf("comboposition", n)
	end
})

C1:AddSlider("RusherComboTransparency", {
	Text = "Combo Transparency",
	Default = 0,
	Min = 0,
	Max = 1,
	Rounding = 2,
	Callback = function(v)
		A.cfg.combotransparency = v
		A.conf("combotransparency", v)
	end
})

C1:AddToggle("RusherClumpAces", {
	Text = "Clump ACEs",
	Default = false,
	Callback = function(v)
		A.cfg.clumpaces = v and 2 or 1
		A.conf("clumpaces", A.cfg.clumpaces)
	end
})

C1:AddToggle("RusherNewRating", {
	Text = "New Rating Display",
	Default = false,
	Callback = function(v)
		A.cfg.newrating = v and 2 or 1
		A.conf("newrating", A.cfg.newrating)
	end
})

C1:AddToggle("RusherNoHurtAnim", {
	Text = "Disable Hurt Animation",
	Default = true,
	Callback = function(v)
		A.cfg.hurt = v and 2 or 1
		A.conf("disablehurtanimation", A.cfg.hurt)
	end
})

C1:AddToggle("RusherKeepCfg", {
	Text = "Keep Config Enforced",
	Default = false,
	Tooltip = "Continuously re-applies configuration values across songs.",
	Callback = function(v)
		A.cfg.keep = v
		if v then
			A.sync()
		end
	end
})


C2:AddToggle("RusherEM", {
	Text = "Extra Visual Effects",
	Default = false,
	Callback = function(v)
		A.cfg.em = v and 2 or 1
		A.conf("em", A.cfg.em)
	end
})

C2:AddToggle("RusherPM", {
	Text = "Performance Mode",
	Default = false,
	Callback = function(v)
		A.cfg.pm = v and 2 or 1
		A.conf("pm", A.cfg.pm)
	end
})

C2:AddDropdown("RusherHBeta", {
	Text = "Hit Effect Style",
	Values = { "Normal", "Beta" },
	Default = 1,
	Multi = false,
	Callback = function(v)
		A.cfg.he = (v == "Beta") and 2 or 1
		A.conf("hebeta", A.cfg.he)
	end
})

C2:AddToggle("RusherGuideSound", {
	Text = "Guide Sound",
	Default = true,
	Callback = function(v)
		A.cfg.guide = v and 2 or 1
		A.conf("guideenable", A.cfg.guide)
	end
})

C2:AddToggle("RusherHitSound", {
	Text = "Hit Sound",
	Default = true,
	Callback = function(v)
		A.cfg.hit = v and 2 or 1
		A.conf("hitsoundenable", A.cfg.hit)
	end
})

C2:AddSlider("RusherHitVol", {
	Text = "Hit Sound Volume",
	Default = 1,
	Min = 0,
	Max = 2,
	Rounding = 2,
	Callback = function(v)
		A.conf("hvolume", v)
		A.conf("hvolume2", v)
		A.conf("hvolume3", v)
	end
})

C2:AddSlider("RusherGuideVol", {
	Text = "Guide Sound Volume",
	Default = 0.1,
	Min = 0,
	Max = 2,
	Rounding = 2,
	Callback = function(v)
		A.conf("hvolume1", v)
	end
})


S1:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame and Library.KeybindFrame.Visible or false,
	Text = "Open Keybind Menu",
	Callback = function(value)
		if Library.KeybindFrame then
			Library.KeybindFrame.Visible = value
		end
	end
})

S1:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(v)
		Library.ShowCustomCursor = v
	end
})

S1:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(v)
		if type(Library.SetNotifySide) == "function" then
			Library:SetNotifySide(v)
		end
	end
})

S1:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",
	Text = "DPI Scale",
	Callback = function(v)
		local n = tonumber((tostring(v):gsub("%%", "")))
		if n and type(Library.SetDPIScale) == "function" then
			Library:SetDPIScale(n)
		end
	end
})

S1:AddSlider("UICornerSlider", {
	Text = "Corner Radius",
	Default = tonumber(Library.CornerRadius) or 6,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(v)
		if type(W.SetCornerRadius) == "function" then
			W:SetCornerRadius(v)
		end
	end
})

S1:AddDivider()

S1:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightControl",
	NoUI = true,
	Text = "Menu keybind"
})

if Options and Options.MenuKeybind then
	Library.ToggleKeybind = Options.MenuKeybind
end

S1:AddButton({
	Text = "Apply Game Config Now",
	Func = function()
		A.sync()
		Library:Notify("Game settings synchronized!", 3)
	end
})

if not (type(SaveManager) == "table" and type(SaveManager.BuildConfigSection) == "function") then
	S1:AddInput("RusherConfigName", {
		Text = "Config Name",
		Default = "default",
		Numeric = false,
		Finished = false
	})

	S1:AddButton({
		Text = "Save Config",
		Func = function()
			if A.smcfg(A.cname()) then
				Library:Notify("Config saved successfully!", 3)
			else
				warn("Rusher Autoplayer: failed to save config")
			end
		end
	})

	S1:AddButton({
		Text = "Load Config",
		Func = function()
			if A.lmcfg(A.cname()) then
				Library:Notify("Config loaded successfully!", 3)
			else
				warn("Rusher Autoplayer: failed to load config")
			end
		end
	})

	S1:AddButton({
		Text = "Set Autoload",
		Func = function()
			if A.amcfg(A.cname()) then
				Library:Notify("Autoload profile set!", 3)
			else
				warn("Rusher Autoplayer: failed to set autoload")
			end
		end
	})
end

S1:AddButton({
	Text = "Unload Autoplayer",
	Func = function()
		A.cln()
		if Library and type(Library.Unload) == "function" then
			Library:Unload()
		end
	end
})

if type(SaveManager) == "table" and type(SaveManager.BuildConfigSection) == "function" then
	pcall(function()
		SaveManager:BuildConfigSection(T.Settings)
	end)
end

if type(ThemeManager) == "table" and type(ThemeManager.ApplyToTab) == "function" then
	pcall(function()
		ThemeManager:ApplyToTab(T.Settings)
	end)
end


A.envall()
A.sync()
A.resolveHooks(true)
task.defer(function()
	A.lacfg()
end)

Library:Notify("Rusher Autoplayer Revamped! Press RightControl to toggle menu.", 5)
return A