local __lt = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {};
	local sharedEnv = rawget(_G, "shared");
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

local function ClonedService(name)
	local Service = function(_, serviceName) return __lt.gs(serviceName); end;
	local Reference = cloneref or function(reference)
		return reference;
	end;
	return __lt.cs(name, Reference);
end;

local root = (getgenv and getgenv()) or _G or {}
local glob = type(_G) == "table" and _G or root
local function naEnvList()
	local list = {root, glob}

	pcall(function()
		if type(shared) == "table" then
			list[#list + 1] = shared
		end
	end)

	pcall(function()
		if type(_G) == "table" and type(rawget(_G, "shared")) == "table" then
			list[#list + 1] = rawget(_G, "shared")
		end
	end)

	return list
end

local function naManage()
	local list = naEnvList()
	for i = 1, #list do
		local env = list[i]
		if type(env) == "table" then
			local direct = rawget(env, "NAmanage") or rawget(env, "__NAmanage")
			if type(direct) == "table" then
				return direct
			end

			local rootEnv = rawget(env, "__nameless_admin_private")
			local testEnv = type(rootEnv) == "table" and rawget(rootEnv, "testing") or nil
			local sharedState = type(testEnv) == "table" and rawget(testEnv, "shared") or nil
			local nested = type(sharedState) == "table" and (rawget(sharedState, "NAmanage") or rawget(sharedState, "__NAmanage")) or nil
			if type(nested) == "table" then
				return nested
			end
		end
	end

	return nil
end

local function qDesc(rootInst, className)
	if not rootInst then
		return {}
	end

	local mgr = naManage()
	if type(mgr) == "table" and type(mgr.qDesc) == "function" then
		local ok, res = pcall(mgr.qDesc, rootInst, className)
		if ok and type(res) == "table" then
			return res
		end
	end

	local ok, res = pcall(function()
		return rootInst:QueryDescendants("Instance")
	end)

	if not ok or type(res) ~= "table" then
		return {}
	end

	if type(className) ~= "string" or className == "" then
		return res
	end

	local out = {}
	for i = 1, #res do
		local inst = res[i]
		if inst and inst:IsA(className) then
			out[#out + 1] = inst
		end
	end

	return out
end

local old = rawget(root, "__chatLockFix") or rawget(glob, "__chatLockFix")

if type(old) == "table" and type(old.stop) == "function" then
	pcall(old.stop)
end

local okSvc, cg, run = pcall(function()
	return ClonedService("CoreGui"), ClonedService("RunService")
end)

if not okSvc or not cg or not run then
	return
end

local st = {}
root.__chatLockFix = st
glob.__chatLockFix = st

local ec = cg:FindFirstChild("ExperienceChat") or cg:WaitForChild("ExperienceChat", 30)
if not ec then
	return
end

local app = ec:FindFirstChild("appLayout") or ec:WaitForChild("appLayout", 30)
if not app then
	return
end

local live = true
local cons = {}
local cbag = {}

local win
local cont
local tok = 0

local qset = setmetatable({}, { __mode = "k" })
local iset = setmetatable({}, { __mode = "k" })
local hid = setmetatable({}, { __mode = "k" })
local wmap = setmetatable({}, { __mode = "k" })

local qh = 1
local qn = 0
local qrow = {}
local qtry = {}
local qdue = {}

local ih = 1
local inq = 0
local irow = {}

local fullScanAt = 0
local dly = {0.04, 0.1, 0.22, 0.5}

local function bind(sig, fn, bag)
	local c = sig:Connect(fn)
	local t = bag or cons
	t[#t + 1] = c
	return c
end

local function bindDescAdd(rootInst, fn, filter, bag)
	if not rootInst or type(fn) ~= "function" then
		return nil
	end

	local mgr = naManage()
	if type(mgr) == "table" and type(mgr.descAdd) == "function" then
		local ok, con = pcall(mgr.descAdd, rootInst, fn, filter)
		if ok and con then
			local t = bag or cons
			t[#t + 1] = con
			return con
		end
	end

	return bind(rootInst.DescendantAdded, function(inst)
		if type(filter) == "function" and not filter(inst) then
			return
		end
		fn(inst)
	end, bag)
end

local function drop(t)
	for i = #t, 1, -1 do
		local c = t[i]
		if c then
			c:Disconnect()
		end
		t[i] = nil
	end
end

local function unwatch(row)
	local t = wmap[row]
	if not t then
		return
	end
	for i = #t, 1, -1 do
		local c = t[i]
		if c then
			c:Disconnect()
		end
		t[i] = nil
	end
	wmap[row] = nil
	hid[row] = nil
end

local function stop()
	if not live then
		return
	end
	live = false

	drop(cbag)
	drop(cons)

	for row in next, wmap do
		unwatch(row)
	end

	win = nil
	cont = nil
	tok = tok + 1
	qrow = {}
	qtry = {}
	qdue = {}
	irow = {}
	qh = 1
	qn = 0
	ih = 1
	inq = 0
	fullScanAt = 0

	if rawget(root, "__chatLockFix") == st then
		root.__chatLockFix = nil
	end
	if rawget(glob, "__chatLockFix") == st then
		glob.__chatLockFix = nil
	end
end

st.stop = stop

local function packQ()
	local nr = {}
	local nt = {}
	local nd = {}
	local n = 0

	for i = qh, qn do
		local row = qrow[i]
		if row ~= nil then
			n = n + 1
			nr[n] = row
			nt[n] = qtry[i]
			nd[n] = qdue[i]
		end
	end

	qrow = nr
	qtry = nt
	qdue = nd
	qh = 1
	qn = n
end

local function packI()
	local nr = {}
	local n = 0

	for i = ih, inq do
		local inst = irow[i]
		if inst ~= nil then
			n = n + 1
			nr[n] = inst
		end
	end

	irow = nr
	ih = 1
	inq = n
end

local function push(row, tries, delay)
	if not live or not row or qset[row] then
		return
	end
	if not row:IsA("GuiObject") then
		return
	end

	qn = qn + 1
	qrow[qn] = row
	qtry[qn] = tries or 0
	qdue[qn] = os.clock() + (delay or 0)
	qset[row] = true
end

local function pushInst(inst)
	if not live or not inst or iset[inst] then
		return
	end

	inq = inq + 1
	irow[inq] = inst
	iset[inst] = true
end

local function ctext(lbl)
	local ok, s = pcall(function()
		return lbl.ContentText
	end)
	if ok and type(s) == "string" then
		return s
	end
	return ""
end

local function plain(s)
	if type(s) ~= "string" or s == "" then
		return ""
	end

	s = s:gsub("<br%s*/?>", " ")
	s = s:gsub("</?[^>]->", "")
	s = s:gsub("&lt;", "<")
	s = s:gsub("&gt;", ">")
	s = s:gsub("&amp;", "&")
	s = s:gsub("&quot;", "\"")
	s = s:gsub("&#39;", "'")
	s = s:gsub("[%z\1-\31\127]", " ")
	s = s:gsub("%s+", " ")
	s = s:gsub("^%s+", "")
	s = s:gsub("%s+$", "")
	return s
end

local function isTextNode(inst)
	if not inst then
		return false
	end
	local cls = inst.ClassName
	return cls == "TextLabel" or cls == "TextButton" or cls == "TextBox"
end

local function likelyInst(inst)
	if not inst then
		return false
	end
	local cls = inst.ClassName
	if cls == "TextLabel" or cls == "TextButton" or cls == "TextBox" then
		return true
	end
	local name = inst.Name
	return name == "TextMessage" or name == "BodyText"
end

local function fontFamily(inst)
	local ok, family = pcall(function()
		local ff = inst.FontFace
		return ff and ff.Family
	end)
	if ok and type(family) == "string" then
		return family
	end
	return ""
end

local function isLockTextNode(inst)
	if not isTextNode(inst) then
		return false
	end

	local text = plain(inst.Text)
	local content = plain(ctext(inst))
	if text:find("🔒", 1, true) or content:find("🔒", 1, true) then
		return true
	end

	local lowerText = text:lower()
	local lowerContent = content:lower()
	if lowerText ~= "lock" and lowerContent ~= "lock" then
		return false
	end

	local family = fontFamily(inst)
	return family:find("BuilderIcons", 1, true) ~= nil
end

local function shouldHide(row)
	if not row then
		return nil
	end

	if isLockTextNode(row) then
		return true
	end

	local desc = qDesc(row)
	if #desc == 0 then
		return nil
	end

	for i = 1, #desc do
		if isLockTextNode(desc[i]) then
			return true
		end
	end

	return false
end

local function rowFromInst(inst)
	local node = inst
	local lastGui

	while node and node ~= ec do
		if node:IsA("GuiObject") then
			lastGui = node
		end

		local par = node.Parent
		if not par then
			break
		end

		if par == cont or par.Name == "RCTScrollContentView" then
			if node:IsA("GuiObject") then
				return node
			end
			return lastGui
		end

		if node.Name == "TextMessage" and par:IsA("GuiObject") then
			return par
		end

		node = par
	end

	return lastGui
end

local function queueInst(inst)
	if not live or not inst then
		return
	end
	if not likelyInst(inst) then
		return
	end

	local row = rowFromInst(inst)
	if row then
		push(row, 0, 0)
	end
end

local function keepHidden(row, body)
	if not live or not row or not row.Parent then
		return
	end

	if row.Visible then
		row.Visible = false
	end

	if body and body.Parent and body:IsA("GuiObject") and body.Visible then
		body.Visible = false
	end

	if hid[row] then
		return
	end

	hid[row] = true

	local bag = {}
	wmap[row] = bag

	bag[#bag + 1] = row:GetPropertyChangedSignal("Visible"):Connect(function()
		if not live or not row or not row.Parent then
			return
		end
		if row.Visible then
			row.Visible = false
		end
	end)

	if body and body:IsA("GuiObject") then
		bag[#bag + 1] = body:GetPropertyChangedSignal("Visible"):Connect(function()
			if not live or not body or not body.Parent then
				return
			end
			if body.Visible then
				body.Visible = false
			end
		end)
	end

	bag[#bag + 1] = row.AncestryChanged:Connect(function(_, par)
		if par == nil then
			unwatch(row)
		end
	end)
end

local function scan(row)
	if not live or not row or not row.Parent then
		return true
	end

	if hid[row] then
		if row.Visible then
			row.Visible = false
		end
		return true
	end

	local bad = shouldHide(row)
	if bad == nil then
		return false
	end

	if bad then
		local msg = row:FindFirstChild("TextMessage", true)
		local body = msg and msg:FindFirstChild("BodyText", true)
		keepHidden(row, body)
	end

	return true
end

local function clearCont()
	drop(cbag)
	cont = nil
end

local function queueKids(nc)
	local kids = nc:GetChildren()
	for i = 1, #kids do
		push(kids[i], 0, 0)
	end
end

local function hookCont(nc)
	if not live or not nc or cont == nc then
		return
	end

	clearCont()
	cont = nc
	queueKids(nc)
	fullScanAt = os.clock() + 1

	bind(nc.ChildAdded, function(ch)
		if not live or cont ~= nc then
			return
		end
		push(ch, 0, 0)
	end, cbag)

	bindDescAdd(nc, function(inst)
		if not live or cont ~= nc then
			return
		end
		pushInst(inst)
	end, likelyInst, cbag)

	bind(nc.AncestryChanged, function(_, par)
		if par == nil and cont == nc then
			clearCont()
		end
	end, cbag)
end

local function walkWin(nw, id)
	task.spawn(function()
		local a = nw:FindFirstChild("scrollingView") or nw:WaitForChild("scrollingView", 10)
		if not a or not live or tok ~= id or win ~= nw then
			return
		end

		local b = a:FindFirstChild("bottomLockedScrollView") or a:WaitForChild("bottomLockedScrollView", 10)
		if not b or not live or tok ~= id or win ~= nw then
			return
		end

		local d = b:FindFirstChild("scrollView")
		if not d then
			local c = b:FindFirstChild("RCTScrollView") or b:WaitForChild("RCTScrollView", 10)
			if not c or not live or tok ~= id or win ~= nw then
				return
			end
			d = c:FindFirstChild("RCTScrollContentView") or c:WaitForChild("RCTScrollContentView", 10)
		end

		if not d or not live or tok ~= id or win ~= nw then
			return
		end

		hookCont(d)
	end)
end

local function useWin(nw)
	if not live or not nw then
		return
	end
	win = nw
	tok = tok + 1
	walkWin(nw, tok)
end

local cur = app:FindFirstChild("chatWindow")
if cur then
	useWin(cur)
end

bind(app.ChildAdded, function(ch)
	if not live then
		return
	end
	if ch.Name == "chatWindow" then
		useWin(ch)
	end
end)

bind(app.ChildRemoved, function(ch)
	if ch == win then
		win = nil
		tok = tok + 1
		clearCont()
	end
end)

bind(ec.AncestryChanged, function(_, par)
	if par == nil then
		stop()
	end
end)

bind(run.Heartbeat, function()
	if not live then
		return
	end

	local now = os.clock()
	if cont and now >= fullScanAt then
		fullScanAt = now + 1.25
		queueKids(cont)
	end

	local t0 = os.clock()
	local n = 0

	while ih <= inq and n < 30 and os.clock() - t0 < 0.0007 do
		local inst = irow[ih]
		irow[ih] = nil
		ih = ih + 1
		n = n + 1

		if inst then
			iset[inst] = nil
		end

		if inst and inst.Parent then
			queueInst(inst)
		end
	end

	if ih > 256 and ih > inq / 2 then
		packI()
	end

	t0 = os.clock()
	now = t0
	n = 0

	while qh <= qn and n < 8 and os.clock() - t0 < 0.001 do
		local row = qrow[qh]
		local tries = qtry[qh]
		local due = qdue[qh]

		qrow[qh] = nil
		qtry[qh] = nil
		qdue[qh] = nil
		qh = qh + 1
		n = n + 1

		if row then
			qset[row] = nil
		end

		if row and row.Parent then
			if due > now then
				push(row, tries, due - now)
			else
				local ok = scan(row)
				if not ok and tries < #dly then
					push(row, tries + 1, dly[tries + 1])
				end
			end
		end
	end

	if qh > 128 and qh > qn / 2 then
		packQ()
	end
end)