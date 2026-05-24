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

	if host then
		local ok, old = pcall(function()
			return rawget(host, "__lt_service_resolver")
		end)
		if ok and type(old) == "table" then
			return old
		end
	end

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

	local ok, lib = pcall(function()
		local ld = loadstring or load
		if type(ld) ~= "function" then
			return nil
		end

		local body = geturl("https://ltseverydayyou.github.io/ServiceResolver.luau")
		if type(body) ~= "string" then
			return nil
		end

		local fn = ld(body, "@ServiceResolver.luau")
		if type(fn) ~= "function" then
			return nil
		end

		return fn()
	end)

	if ok and type(lib) == "table" then
		if host then
			pcall(function()
				host.__lt_service_resolver = lib
			end)
		end
		return lib
	end

	return {
		cs = function(n, cr)
			if type(cr) == "function" then
				local ok2, r = pcall(function()
					return cloneref(game:GetService(n))
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
A.relq2 = {}
A.apstate = false
A.mode = "none"
A.cfg = {
	ap = false,
	cap = false,
	caj = false,
	ninp = false,
	keep = false,
	cwin = 55,
	tlead = 18,
	tdur = 12,
	hlate = 45,
	clead = 45,
	ctail = 160,
	late = 180,
	rhold = 12,
	rgap = 10,
	rretry = 3,
	aprefer = false,
	autonews = false,
	speed = 1,
	off = 0,
	voff = 0,
	tw = 2,
	pm = 1,
	em = 1,
	he = 1,
	guide = 2,
	hit = 2,
	hurt = 2,
	partner = "lester"
}

A.svc = function(n)
	if type(__lt) == "table" and type(__lt.cs) == "function" then
		local ok, s = pcall(__lt.cs, n, cloneref)
		if ok and s then
			return s
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
A.vim = nil
A.lp = A.plrs.LocalPlayer
A.pg = A.lp:WaitForChild("PlayerGui", 30)

A.add = function(c)
	if c then
		table.insert(A.con, c)
	end
	return c
end

A.scr = function(n)
	if not A.pg then
		return nil
	end

	if n == "game" then
		return A.pg:FindFirstChild("gameplay_script")
	elseif n == "song" then
		return A.pg:FindFirstChild("songselect_script")
	elseif n == "menu" then
		return A.pg:FindFirstChild("menu_script")
	elseif n == "cfg" then
		return A.pg:FindFirstChild("configs")
	elseif n == "assist" then
		return A.pg:FindFirstChild("assist_scripts")
	elseif n == "news" then
		return A.pg:FindFirstChild("news_script")
	elseif n == "outside" then
		return A.pg:FindFirstChild("outside_script")
	elseif n == "room" then
		return A.pg:FindFirstChild("roomsearch_script")
	elseif n == "tutorial" then
		return A.pg:FindFirstChild("tutorial_script")
	elseif n == "dialog" then
		local d = A.pg:FindFirstChild("dialogue")
		return d and d:FindFirstChild("dialoguesystem")
	elseif n == "load" then
		local l = A.pg:FindFirstChild("loading")
		return l and l:FindFirstChild("initializer")
	elseif n == "caj" then
		local m = A.pg:FindFirstChild("minigame")
		return m and m:FindFirstChild("cajon")
	elseif n == "chartmod" then
		local ch = nil
		for _, nm in ipairs({ "song", "load", "game", "menu" }) do
			local e = A.envs[nm]
			if type(e) ~= "table" then
				e = A.fenv(A.scr(nm))
			end
			local g = A.gtab(e)
			if type(g) == "table" then
				local ok, v = pcall(function()
					return g.currentsong
				end)
				if ok and type(v) == "table" then
					ch = v
					break
				end
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

A.push = function(e)
	local g = A.gtab(e)
	if type(g) == "table" then
		for k, v in pairs(A.vars) do
			pcall(function()
				g[k] = v
			end)
		end
	end

	if type(e) == "table" then
		for k, v in pairs(A.vars) do
			pcall(function()
				e[k] = v
			end)
		end
	end
end

A.env = function(n)
	if A.envs[n] then
		return A.envs[n]
	end

	local s = A.scr(n)
	local e = A.fenv(s)

	if type(e) == "table" then
		A.envs[n] = e
		A.push(e)
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

A.gtabs = function()
	local out = {}
	local seen = {}

	for _, e in ipairs(A.envall()) do
		local g = A.gtab(e)
		if type(g) == "table" and not seen[g] then
			seen[g] = true
			table.insert(out, g)
		end
		if type(e) == "table" and not seen[e] then
			seen[e] = true
			table.insert(out, e)
		end
	end

	for _, g in ipairs(A.globs) do
		if type(g) == "table" and not seen[g] then
			seen[g] = true
			table.insert(out, g)
		end
	end

	return out
end

A.gkeys = {
	"currentchart",
	"currentsong",
	"currentdiff",
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
				local v = nil
				pcall(function()
					v = rawget(g, k)
				end)
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
		if type(e) == "table" then
			for _, k in ipairs(A.gkeys) do
				if A.vars[k] == nil then
					local v = nil
					pcall(function()
						v = rawget(e, k)
					end)
					if v == nil then
						pcall(function()
							v = e[k]
						end)
					end
					if v ~= nil then
						A.vars[k] = v
					end
				end
			end
		end
	end
end

A.gget = function(k)
	A.pullg()
	for _, g in ipairs(A.gtabs()) do
		local ok, v = pcall(function()
			return g[k]
		end)
		if ok and v ~= nil then
			return v
		end
	end

	return A.vars[k]
end

A.gset = function(k, v)
	A.vars[k] = v

	for _, g in ipairs(A.gtabs()) do
		pcall(function()
			g[k] = v
		end)
	end
end

A.req = function(m)
	if typeof(m) ~= "Instance" then
		return false, nil, "not_instance"
	end

	local okc, ismod = pcall(function()
		return m:IsA("ModuleScript")
	end)
	if not okc or not ismod then
		return false, nil, "not_module"
	end

	local okp, par = pcall(function()
		return m.Parent
	end)
	if not okp or par == nil then
		return false, nil, "no_parent"
	end

	if type(require) == "function" then
		local ok, r = pcall(require, m)
		if ok then
			return true, r, "require"
		end
	end

	if type(getscriptclosure) == "function" then
		local ok, f = pcall(getscriptclosure, m)
		if ok and type(f) == "function" then
			local ok2, r = pcall(f)
			if ok2 then
				return true, r, "closure"
			end
		end
	end

	return false, nil, "unavailable"
end

A.gcf = function(kind, pred, one)
	if type(pred) ~= "function" then
		return one and nil or {}
	end

	if type(filtergc) == "function" then
		local opt = {}
		local ok, res = pcall(filtergc, kind or "table", opt, one == true)
		if ok then
			if one and pred(res) then
				return res
			end
			if type(res) == "table" then
				local out = {}
				for _, v in pairs(res) do
					if pred(v) then
						if one then
							return v
						end
						table.insert(out, v)
					end
				end
				return out
			end
		end
	end

	if type(getgc) == "function" then
		local ok, res = pcall(getgc, true)
		if ok and type(res) == "table" then
			local out = {}
			for _, v in pairs(res) do
				if (not kind or type(v) == kind) and pred(v) then
					if one then
						return v
					end
					table.insert(out, v)
				end
			end
			return out
		end
	end

	return one and nil or {}
end

A.guv = function(f, n)
	if type(f) ~= "function" or type(debug) ~= "table" then
		return nil, nil
	end

	if type(debug.getupvalue) == "function" then
		for i = 1, 180 do
			local r = { pcall(debug.getupvalue, f, i) }
			if not r[1] then
				break
			end

			if r[3] ~= nil and r[2] == n then
				return r[3], i
			end

			if r[2] ~= nil and n == i then
				return r[2], i
			end

			if r[2] == nil then
				break
			end
		end
	end

	if type(debug.getupvalues) == "function" then
		local ok, uv = pcall(debug.getupvalues, f)
		if ok and type(uv) == "table" and uv[n] ~= nil then
			return uv[n], n
		end
	end

	return nil, nil
end

A.suv = function(f, n, v)
	if type(f) ~= "function" or type(debug) ~= "table" or type(debug.setupvalue) ~= "function" then
		return false
	end

	if type(debug.getupvalue) == "function" then
		for i = 1, 180 do
			local r = { pcall(debug.getupvalue, f, i) }
			if not r[1] then
				break
			end

			if r[3] ~= nil and r[2] == n then
				return pcall(debug.setupvalue, f, i, v)
			end

			if r[2] == nil then
				break
			end
		end
	end

	if type(debug.getupvalues) == "function" then
		local ok, uv = pcall(debug.getupvalues, f)
		if ok and type(uv) == "table" and uv[n] ~= nil then
			return pcall(debug.setupvalue, f, n, v)
		end
	end

	return false
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

A.setap = function(v)
	A.apstate = false
	return false
end

A.kpool = {
	Enum.KeyCode.A,
	Enum.KeyCode.B,
	Enum.KeyCode.C,
	Enum.KeyCode.D,
	Enum.KeyCode.E,
	Enum.KeyCode.F,
	Enum.KeyCode.G,
	Enum.KeyCode.H,
	Enum.KeyCode.I,
	Enum.KeyCode.J,
	Enum.KeyCode.K,
	Enum.KeyCode.L,
	Enum.KeyCode.M,
	Enum.KeyCode.N,
	Enum.KeyCode.O,
	Enum.KeyCode.P,
	Enum.KeyCode.Q,
	Enum.KeyCode.R,
	Enum.KeyCode.S,
	Enum.KeyCode.T,
	Enum.KeyCode.U,
	Enum.KeyCode.V,
	Enum.KeyCode.W,
	Enum.KeyCode.X,
	Enum.KeyCode.Y,
	Enum.KeyCode.Z,
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
	Enum.KeyCode.KeypadOne,
	Enum.KeyCode.KeypadTwo,
	Enum.KeyCode.KeypadThree,
	Enum.KeyCode.KeypadFour,
	Enum.KeyCode.KeypadFive,
	Enum.KeyCode.KeypadSix,
	Enum.KeyCode.KeypadSeven,
	Enum.KeyCode.KeypadEight,
	Enum.KeyCode.KeypadNine
}

A.hpool = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
	Enum.KeyCode.KeypadOne,
	Enum.KeyCode.KeypadTwo,
	Enum.KeyCode.KeypadThree,
	Enum.KeyCode.KeypadFour,
	Enum.KeyCode.KeypadFive,
	Enum.KeyCode.KeypadSix,
	Enum.KeyCode.KeypadSeven,
	Enum.KeyCode.KeypadEight,
	Enum.KeyCode.KeypadNine
}

A.rkey = Enum.KeyCode.P
A.ckey = Enum.KeyCode.KeypadZero
A.kidx = 1
A.hidx = 1
A.pidx = {}

A.idx = function(pool)
	if pool == A.hpool then
		return "hidx"
	end
	return "kidx"
end

A.nextkey = function(pool)
	pool = pool or A.kpool
	if #pool <= 0 then
		return nil
	end

	local idx = A.idx(pool)
	for _ = 1, #pool do
		local k = pool[A[idx]]
		A[idx] = A[idx] + 1
		if A[idx] > #pool then
			A[idx] = 1
		end
		if k and not A.keys[k] then
			return k
		end
	end

	return nil
end

A.nexthold = function()
	return A.nextkey(A.hpool) or A.nextkey(A.kpool)
end

A.fake = function(k, down)
	return {
		KeyCode = k,
		UserInputType = Enum.UserInputType.Keyboard,
		UserInputState = if down == false then Enum.UserInputState.End else Enum.UserInputState.Begin,
		Position = Vector3.zero
	}
end

A.hasenv = function(fn)
	local e = A.env("game")
	return e and type(e[fn]) == "function"
end

A.evk = function(k, down)
	local e = A.env("game")
	if not e then
		return false
	end

	local fn = if down == false then e.release else e.input
	if type(fn) ~= "function" then
		return false
	end

	return pcall(fn, A.fake(k, down), false)
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

	local ok = pcall(function()
		v:SendKeyEvent(down == true, k, false, nil)
	end)

	return ok
end

A.firecons = function(sig, k, down)
	if not sig or not k then
		return false
	end

	local inp = A.fake(k, down)
	local fired = false

	if type(firesignal) == "function" then
		local ok = pcall(firesignal, sig, inp, false)
		if ok then
			fired = true
		end
	end

	if fired then
		return true
	end

	if type(getconnections) ~= "function" then
		return false
	end

	local ok, cons = pcall(getconnections, sig)
	if not ok or type(cons) ~= "table" then
		return false
	end

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
				ok2 = pcall(function()
					c:Fire(inp, false)
				end)
			elseif type(c.fire) == "function" then
				ok2 = pcall(function()
					c:fire(inp, false)
				end)
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

A.hasin = function(list, k)
	if type(list) ~= "table" then
		return nil
	end

	for i, v in ipairs(list) do
		if type(v) == "table" and v[1] == k then
			return i
		end
	end

	return nil
end

A.markdown = function(k)
	if not k then
		return false
	end

	local e = A.env("game")
	if not e or type(e.release) ~= "function" then
		return false
	end

	local t27 = A.guv(e.release, "t27")
	local t28 = A.guv(e.release, "t28")
	local ok = false
	local tm = tick()

	if type(t27) == "table" then
		if not A.hasin(t27, k) then
			table.insert(t27, { k, tm })
		end
		ok = true
	end

	if type(t28) == "table" then
		if not A.hasin(t28, k) then
			table.insert(t28, { k, tm })
		end
		ok = true
	end

	if ok then
		A.keys[k] = true
	end

	return ok
end

A.rawpress = function(k)
	if not k then
		return false
	end

	if A.evk(k, true) then
		A.keys[k] = true
		return true
	end

	if A.firecons(A.uis.InputBegan, k, true) then
		A.keys[k] = true
		return true
	end

	if A.vkey(k, true) then
		A.keys[k] = true
		return true
	end

	return false
end

A.rawrel = function(k)
	if not k then
		return false
	end

	A.keys[k] = nil

	if A.evk(k, false) then
		return true
	end

	if A.firecons(A.uis.InputEnded, k, false) then
		return true
	end

	if A.vkey(k, false) then
		return true
	end

	return false
end

A.gpress = function(k, force)
	k = k or A.nextkey(A.kpool)
	if not k then
		return false
	end

	if A.keys[k] and not force then
		return true
	end

	if A.evk(k, true) then
		A.keys[k] = true
		return true
	end

	if A.vkey(k, true) then
		A.keys[k] = true
		return true
	end

	return false
end

A.grel = function(k, force)
	if not k then
		return false
	end

	A.keys[k] = nil

	if A.evk(k, false) then
		return true
	end

	if A.vkey(k, false) then
		return true
	end

	return false
end

A.relq = function(k, t)
	if not k then
		return false
	end

	table.insert(A.upq, {
		k = k,
		t = t or os.clock()
	})

	return true
end

A.flush = function()
	local now = os.clock()

	for i = #A.upq, 1, -1 do
		local it = A.upq[i]
		local k = it and it.k
		if not k or not A.keys[k] then
			table.remove(A.upq, i)
		elseif now >= (tonumber(it.t) or now) then
			A.grel(k, true)
			table.remove(A.upq, i)
		end
	end
end

A.relpush = function()
	return false
end

A.flushrel = function()
	A.relq2 = {}
	return
end

A.tap = function(k, dur)
	k = k or A.nextkey(A.kpool)
	if not k or A.keys[k] then
		return false
	end

	if not A.gpress(k, true) then
		return false
	end

	dur = math.clamp((tonumber(dur) or A.cfg.tdur or 12) / 1000, 0.004, 0.08)
	A.relq(k, os.clock() + dur)

	return true
end

A.chart = {
	cur = nil,
	seq = {},
	i = 1,
	bpms = nil,
	last = 0,
	holds = {},
	catch = false
}

A.same = function(a, b)
	return math.abs((a or 0) - (b or 0)) <= 0.004
end

A.bps = function(ch)
	return 60 / (tonumber(ch and ch.basebpm) or 120)
end

A.mkbpm = function(ch)
	local b = tonumber(ch and ch.basebpm) or 120
	local src = type(ch and ch.bpms) == "table" and ch.bpms or {
		{ beat = 0, bpm = b },
		{ beat = 999999, bpm = b }
	}

	if #src == 0 then
		src = {
			{ beat = 0, bpm = b },
			{ beat = 999999, bpm = b }
		}
	end

	local out = {}
	local last = {
		sum = 0,
		mul = 1,
		ms = tonumber(src[1] and src[1].beat) or 0,
		bpm = tonumber(src[1] and src[1].bpm) or b
	}

	last.mul = last.bpm / b
	table.insert(out, last)

	for i = 2, #src do
		local it = src[i]
		local ms = tonumber(it.beat) or last.ms
		local bpm = tonumber(it.bpm) or b
		local sum = last.sum + (ms - last.ms) * last.mul

		last = {
			ms = ms,
			sum = sum,
			mul = bpm / b,
			bpm = bpm
		}

		table.insert(out, last)
	end

	table.insert(out, {
		ms = 99999999,
		sum = last.sum + (99999999 - last.ms) * last.mul,
		mul = last.mul,
		bpm = last.bpm
	})

	return out
end

A.bpmnow = function(ch, pos)
	local map = A.chart.bpms
	if type(map) ~= "table" then
		return pos
	end

	local old = map[1]
	for i = 2, #map do
		local nxt = map[i]
		if pos <= nxt.ms then
			return old.sum + (pos - old.ms) * old.mul
		end
		old = nxt
	end

	return pos
end

A.gnow = function()
	local e = A.env("game")

	if e and type(e.playing) == "function" then
		local v = A.guv(e.playing, "v30")
		if type(v) == "number" then
			return v
		end
	end

	local gs = A.scr("game")
	local snd = gs and gs:FindFirstChild("Sound")
	local ch = A.gget("currentchart")

	if not snd or type(ch) ~= "table" then
		return nil
	end

	local c = A.gget("CONFIGURATIONS")
	local song = A.gget("currentsong")
	local off = 0

	off = off + (tonumber(ch.offset) or 0) / 1000

	if type(c) == "table" then
		off = off + (tonumber(c.offset) or 0) / 1000
	end

	if type(song) == "table" then
		off = off - (tonumber(song.offset) or 0) / 1000
	end

	return A.bpmnow(ch, snd.TimePosition + off)
end

A.addseq = function(t, k, a, lead)
	table.insert(A.chart.seq, {
		t = t,
		k = k,
		a = a,
		lead = lead or 0.018
	})
end

A.resetkeys = function()
	A.chart.holds = {}
	A.chart.catch = false
	A.upq = {}
	A.relq2 = {}

	for k in pairs(A.keys) do
		A.grel(k, true)
	end

	A.keys = {}
end

A.buildcatch = function(catches)
	if #catches == 0 then
		return
	end

	table.sort(catches, function(a, b)
		return a < b
	end)

	local s = catches[1]
	local e = catches[1]

	for i = 2, #catches do
		local t = catches[i]
		if t - e <= 0.35 then
			e = t
		else
			A.addseq(s - A.cfg.clead / 1000, "cstart", nil, 0.01)
			A.addseq(e + A.cfg.ctail / 1000, "cend", nil, 0)
			s = t
			e = t
		end
	end

	A.addseq(s - A.cfg.clead / 1000, "cstart", nil, 0.01)
	A.addseq(e + A.cfg.ctail / 1000, "cend", nil, 0)
end

A.loadchart = function()
	local ch = A.gget("currentchart")
	if type(ch) ~= "table" or type(ch.notes) ~= "table" then
		return false
	end

	if A.chart.cur == ch then
		return true
	end

	A.resetkeys()
	A.chart.cur = ch
	A.chart.seq = {}
	A.chart.i = 1
	A.chart.bpms = A.mkbpm(ch)
	A.chart.last = 0

	local bps = A.bps(ch)
	local catches = {}
	local rels = {}
	local id = 0

	for _, n in ipairs(ch.notes) do
		local nt = tonumber(n[1]) or 1
		local st = tonumber(n[2])
		local en = tonumber(n[3]) or -1
		local layer = tonumber(n[5]) or 0

		if st and layer >= 0 then
			id = id + 1
			local ts = st * bps

			if nt == 4 then
			elseif nt == 2 then
				table.insert(catches, ts)
			elseif nt == 3 then
				A.addseq(ts, "tap", id, A.cfg.tlead / 1000)
			elseif en and en > 0 then
				A.addseq(ts, "hstart", id, A.cfg.tlead / 1000)
				A.addseq(en * bps + A.cfg.hlate / 1000, "hend", id, 0)
			else
				A.addseq(ts, "tap", id, A.cfg.tlead / 1000)
			end
		end
	end

	A.buildcatch(catches)

	table.sort(A.chart.seq, function(a, b)
		if a.t == b.t then
			local o = {
				hstart = 1,
				cstart = 2,
				tap = 3,
				cend = 4,
				hend = 5,
				rel = 3
			}
			return (o[a.k] or 99) < (o[b.k] or 99)
		end
		return a.t < b.t
	end)

	return true
end

A.doev = function(ev)
	local k = ev.k
	local id = ev.a

	if k == "tap" then
		A.tap()
	elseif k == "rel" then
		A.tap()
	elseif k == "hstart" then
		local hk = A.nexthold()
		if not hk then
			return
		end
		A.chart.holds[id] = hk
		A.gpress(hk, true)
	elseif k == "hend" then
		local hk = A.chart.holds[id]
		if hk then
			A.chart.holds[id] = nil
			A.grel(hk, true)
		end
	elseif k == "cstart" then
		if not A.chart.catch then
			A.chart.catch = true
			A.gpress(A.ckey, true)
		end
	elseif k == "cend" then
		if A.chart.catch then
			A.chart.catch = false
			A.grel(A.ckey, true)
		end
	end
end

A.chartplay = function()
	A.flush()

	if not A.loadchart() then
		return
	end

	local now = A.gnow()
	if not now then
		return
	end

	local c = A.gget("CONFIGURATIONS")
	local vo = 0

	if type(c) == "table" then
		vo = (tonumber(c.offsetvisual) or 0) / 1000
	end

	now = now + vo

	if A.chart.last > 0 and now < A.chart.last - 1 then
		A.chart.i = 1
		A.resetkeys()
	end

	A.chart.last = now

	while true do
		local ev = A.chart.seq[A.chart.i]
		if not ev then
			break
		end

		local lead = ev.lead or 0
		if ev.t - now > lead then
			break
		end

		if now - ev.t <= math.clamp(A.cfg.late / 1000, 0.04, 0.35) then
			A.doev(ev)
		end

		A.chart.i = A.chart.i + 1
	end
end

A.cajon = function()
	local e = A.env("caj")
	if not e or type(e.input) ~= "function" then
		return
	end

	local ready = A.guv(e.input, "v6")
	if ready == false then
		return
	end

	local list = A.guv(e.input, "t4")
	local idx = A.guv(e.input, "v9")
	local bar = A.guv(e.input, "v8")
	local tim = A.guv(e.input, "v7")

	if type(list) ~= "table" or type(idx) ~= "number" or type(bar) ~= "number" or type(tim) ~= "number" then
		return
	end

	local note = list[idx]
	if type(note) ~= "number" then
		return
	end

	local dst = math.abs((note + bar) * 0.6 - tim)
	if dst <= math.clamp(A.cfg.cwin / 1000, 0.01, 0.11) then
		local id = tostring(idx) .. ":" .. tostring(bar)
		if A.last.caj ~= id then
			A.last.caj = id
			local k = A.nextkey(A.kpool)
			A.tap(k)
		end
	end
end

A.sync = function()
	A.conf("speed", A.cfg.speed)
	A.conf("offset", A.cfg.off)
	A.conf("offsetvisual", A.cfg.voff)
	A.conf("tw", A.cfg.tw)
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
	A.cfg.cap = false
	A.cfg.caj = false
	A.setap(false)
	A.resetkeys()

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
	A.flush()
	A.flushrel()

	if A.apstate then
		A.setap(false)
	end

	local runchart = A.cfg.ap or A.cfg.cap

	if runchart then
		A.chartplay()
	end

	if runchart then
		A.mode = "chart"
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

A.add(A.rs.Heartbeat:Connect(A.step))


A.hsvc = A.svc("HttpService")
A.dir = "RusherAutoplayer"
A.afile = A.dir .. "/autoload.txt"

A.cname = function()
	local n = "default"
	local ok, o = pcall(function()
		return Options and Options.RusherConfigName
	end)
	if ok and type(o) == "table" and o.Value ~= nil then
		n = tostring(o.Value)
	end
	n = n:gsub("[^%w%-%_ ]", "_")
	if n == "" then
		n = "default"
	end
	return n
end

A.cfile = function(n)
	n = tostring(n or A.cname())
	n = n:gsub("[^%w%-%_ ]", "_")
	if n == "" then
		n = "default"
	end
	return A.dir .. "/" .. n .. ".json", n
end

A.setctl = function(o, v)
	if type(o) ~= "table" then
		return false
	end
	if type(o.SetValue) == "function" then
		local ok = pcall(function()
			o:SetValue(v)
		end)
		if ok then
			return true
		end
	end
	if type(o.SetValueRGB) == "function" then
		local ok = pcall(function()
			o:SetValueRGB(v)
		end)
		if ok then
			return true
		end
	end
	local ok = pcall(function()
		o.Value = v
	end)
	return ok
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
	local dat = {
		objects = {}
	}

	local function add(idx, obj)
		if type(idx) ~= "string" or A.signore[idx] then
			return
		end
		if type(obj) ~= "table" or obj.Type == nil then
			return
		end

		if obj.Type == "Toggle" then
			table.insert(dat.objects, {
				type = "Toggle",
				idx = idx,
				value = obj.Value
			})
		elseif obj.Type == "Slider" then
			table.insert(dat.objects, {
				type = "Slider",
				idx = idx,
				value = tostring(obj.Value)
			})
		elseif obj.Type == "Dropdown" then
			table.insert(dat.objects, {
				type = "Dropdown",
				idx = idx,
				value = obj.Value,
				multi = obj.Multi
			})
		elseif obj.Type == "ColorPicker" and obj.Value and type(obj.Value.ToHex) == "function" then
			table.insert(dat.objects, {
				type = "ColorPicker",
				idx = idx,
				value = obj.Value:ToHex(),
				transparency = obj.Transparency
			})
		elseif obj.Type == "KeyPicker" then
			table.insert(dat.objects, {
				type = "KeyPicker",
				idx = idx,
				mode = obj.Mode,
				key = obj.Value,
				modifiers = obj.Modifiers
			})
		elseif obj.Type == "Input" then
			table.insert(dat.objects, {
				type = "Input",
				idx = idx,
				text = obj.Value
			})
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

	if type(dat.objects) == "table" then
		for _, it in ipairs(dat.objects) do
			local idx = type(it) == "table" and it.idx or nil
			local typ = type(it) == "table" and it.type or nil
			if type(idx) == "string" and not A.signore[idx] then
				local obj = nil
				if typ == "Toggle" then
					obj = Toggles[idx]
				elseif typ == "Slider" or typ == "Dropdown" or typ == "ColorPicker" or typ == "KeyPicker" or typ == "Input" then
					obj = Options[idx]
				else
					obj = Options[idx] or Toggles[idx]
				end

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
						A.setctl(obj, it.text)
					elseif it.value ~= nil then
						A.setctl(obj, it.value)
					end
				end
			end
		end

		A.sync()
		return true
	end

	local tg = type(Toggles) == "table" and Toggles or {}
	local op = type(Options) == "table" and Options or {}

	if type(dat.tog) == "table" then
		for k, v in pairs(dat.tog) do
			A.setctl(tg[k], v)
		end
	end

	if type(dat.opt) == "table" then
		for k, v in pairs(dat.opt) do
			A.setctl(op[k], v)
		end
	end

	A.sync()
	return true
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

	local file = A.cfile(n)
	return pcall(writefile, file, body)
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

	local ok2, ret = pcall(fn)
	if ok2 then
		return true, ret
	end

	return false, nil
end

local okLib, Library = A.ldurl("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua", "@Obsidian.lua")
if not okLib or type(Library) ~= "table" or type(Library.CreateWindow) ~= "function" then
	warn("Rusher Autoplayer: UI library unavailable, runtime loaded without menu")
	A.envall()
	A.sync()
	task.defer(function()
		A.lacfg()
	end)
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
	local ok2 = A.fsave(n)
	return ok or ok2
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
	local ok2 = A.fload(n)
	return ok or ok2
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
		elseif type(SaveManager.SetAutoload) == "function" then
			local ok0, ret = pcall(function()
				return SaveManager:SetAutoload(n)
			end)
			ok = ok0 and ret == true
		end
	end
	local ok2 = A.asave(n)
	return ok or ok2
end

A.lacfg = function()
	local ok = false
	if type(SaveManager) == "table" and type(SaveManager.LoadAutoloadConfig) == "function" then
		local ok0 = pcall(function()
			SaveManager:LoadAutoloadConfig()
		end)
		ok = ok0 == true
	end
	local ok2 = A.aload()
	return ok or ok2
end

local W = Library:CreateWindow({
	Title = "Rusher Autoplayer",
	Footer = "Obsidian",
	Center = true,
	AutoShow = true,
	ToggleKeybind = Enum.KeyCode.RightControl
})

local T = {
	Main = W:AddTab("Main", "play"),
	Config = W:AddTab("Config", "settings"),
	Settings = W:AddTab("UI Settings", "wrench")
}

local M1 = T.Main:AddLeftGroupbox("Auto Player")
local M2 = T.Main:AddRightGroupbox("Game")
local C1 = T.Config:AddLeftGroupbox("Gameplay")
local C2 = T.Config:AddRightGroupbox("Audio / Visual")
local S1 = T.Settings:AddLeftGroupbox("Menu")

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

M1:AddToggle("RusherAutoPlay", {
	Text = "Gameplay Auto Player",
	Default = false,
	Tooltip = "Runs the chart autoplayer path.",
	Callback = function(v)
		A.cfg.ap = v
		A.setap(false)
		A.chart.cur = nil
		A.chart.seq = {}
		A.chart.i = 1
		A.resetkeys()
	end
})

M1:AddToggle("RusherChartAuto", {
	Text = "Chart Fallback Auto Player",
	Default = false,
	Tooltip = "Runs the chart autoplayer path with type 3 handled like a normal tap.",
	Callback = function(v)
		A.cfg.cap = v
		A.chart.cur = nil
		A.chart.seq = {}
		A.chart.i = 1
		A.resetkeys()
	end
})

M1:AddToggle("RusherCajonAuto", {
	Text = "Cajon Auto Player",
	Default = false,
	Tooltip = "Uses cajon script timing values through its game env.",
	Callback = function(v)
		A.cfg.caj = v
	end
})

M1:AddSlider("RusherCajonWindow", {
	Text = "Cajon Hit Window",
	Default = 55,
	Min = 10,
	Max = 110,
	Rounding = 0,
	Suffix = "ms",
	Callback = function(v)
		A.cfg.cwin = v
	end
})

M1:AddSlider("RusherTapLead", {
	Text = "Tap Lead",
	Default = 18,
	Min = 0,
	Max = 60,
	Rounding = 0,
	Suffix = "ms",
	Callback = function(v)
		A.cfg.tlead = v
		A.chart.cur = nil
	end
})

M1:AddSlider("RusherTapHold", {
	Text = "Tap Hold Time",
	Default = 12,
	Min = 4,
	Max = 45,
	Rounding = 0,
	Suffix = "ms",
	Callback = function(v)
		A.cfg.tdur = v
	end
})

M1:AddSlider("RusherHoldLate", {
	Text = "Hold Release Delay",
	Default = 45,
	Min = 0,
	Max = 120,
	Rounding = 0,
	Suffix = "ms",
	Callback = function(v)
		A.cfg.hlate = v
		A.chart.cur = nil
	end
})





M1:AddToggle("RusherAutoNews", {
	Text = "Auto Close News",
	Default = false,
	Callback = function(v)
		A.cfg.autonews = v
	end
})


M1:AddSlider("RusherCatchLead", {
	Text = "Catch Lead",
	Default = 45,
	Min = 10,
	Max = 120,
	Rounding = 0,
	Suffix = "ms",
	Callback = function(v)
		A.cfg.clead = v
		A.chart.cur = nil
	end
})

M1:AddSlider("RusherCatchTail", {
	Text = "Catch End Delay",
	Default = 160,
	Min = 40,
	Max = 260,
	Rounding = 0,
	Suffix = "ms",
	Callback = function(v)
		A.cfg.ctail = v
		A.chart.cur = nil
	end
})

M1:AddSlider("RusherLateWindow", {
	Text = "Max Catch-Up",
	Default = 180,
	Min = 80,
	Max = 350,
	Rounding = 0,
	Suffix = "ms",
	Callback = function(v)
		A.cfg.late = v
	end
})

M1:AddToggle("RusherNoInput", {
	Text = "Force NoInput Off",
	Default = false,
	Callback = function(v)
		A.cfg.ninp = v
		if v then
			A.gset("noinput", false)
		end
	end
})

M1:AddToggle("RusherKeepCfg", {
	Text = "Keep Config Applied",
	Default = false,
	Callback = function(v)
		A.cfg.keep = v
		if v then
			A.sync()
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
	Text = "Open Menu",
	Func = function()
		A.fire("menu")
	end
})

M2:AddButton({
	Text = "Show News",
	Func = function()
		A.call("news", "main")
	end
})

M2:AddButton({
	Text = "Close News",
	Func = function()
		A.call("news", "close")
	end
})

M2:AddButton({
	Text = "Reload Globals",
	Func = function()
		A.envs = {}
		A.envall()
		A.pullg()
	end
})

M2:AddButton({
	Text = "Release All Keys",
	Func = function()
		A.resetkeys()
	end
})

M2:AddButton({
	Text = "Start Cajon",
	Func = function()
		A.fire("cajon")
	end
})

M2:AddDropdown("RusherPartner", {
	Text = "Partner",
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
	Text = "Note Speed",
	Default = 1,
	Min = 0.25,
	Max = 5,
	Rounding = 2,
	Callback = function(v)
		A.cfg.speed = v
		A.conf("speed", v)
	end
})

C1:AddSlider("RusherOffset", {
	Text = "Audio Offset",
	Default = 0,
	Min = -500,
	Max = 500,
	Rounding = 0,
	Suffix = "ms",
	Callback = function(v)
		A.cfg.off = v
		A.conf("offset", v)
	end
})

C1:AddSlider("RusherVOffset", {
	Text = "Visual Offset",
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
	Text = "Timing Window",
	Values = {
		"Easy",
		"Normal",
		"Strict"
	},
	Default = 2,
	Multi = false,
	Callback = function(v)
		local n = v == "Easy" and 1 or v == "Normal" and 2 or 3
		A.cfg.tw = n
		A.conf("tw", n)
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

C2:AddToggle("RusherEM", {
	Text = "Extra Effects",
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
	Text = "Hit Effect Beta",
	Values = {
		"Normal",
		"Beta"
	},
	Default = 1,
	Multi = false,
	Callback = function(v)
		A.cfg.he = v == "Beta" and 2 or 1
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
	Text = "Hit Volume",
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
	Text = "Guide Volume",
	Default = 0.1,
	Min = 0,
	Max = 2,
	Rounding = 2,
	Callback = function(v)
		A.conf("hvolume1", v)
	end
})

S1:AddButton({
	Text = "Reload Game Envs",
	Func = function()
		A.envs = {}
		A.envall()
	end
})

S1:AddButton({
	Text = "Apply Config Now",
	Func = function()
		A.sync()
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
		if not A.smcfg(A.cname()) then
			warn("Rusher Autoplayer: failed to save config")
		end
	end
})

S1:AddButton({
	Text = "Load Config",
	Func = function()
		if not A.lmcfg(A.cname()) then
			warn("Rusher Autoplayer: failed to load config")
		end
	end
})

S1:AddButton({
	Text = "Set Autoload",
	Func = function()
		if not A.amcfg(A.cname()) then
			warn("Rusher Autoplayer: failed to set autoload")
		end
	end
})

S1:AddButton({
	Text = "Load Autoload",
	Func = function()
		if not A.lacfg() then
			warn("Rusher Autoplayer: failed to load autoload")
		end
	end
})

end

S1:AddButton({
	Text = "Unload",
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
task.defer(function()
	A.lacfg()
end)