local root = (getgenv and getgenv()) or _G
local old = rawget(root, "__chatLockFix") or rawget(_G, "__chatLockFix")

if type(old) == "table" and type(old.stop) == "function" then
	pcall(old.stop)
end

local st = {}
root.__chatLockFix = st
_G.__chatLockFix = st

local function getCg()
	local s = game:GetService("CoreGui")
	if cloneref and type(cloneref) == "function" then
		local ok, r = pcall(cloneref, s)
		if ok and r then
			return r
		end
	end
	return s
end

local cg = getCg()
if not cg then
	return
end

local ec = cg:FindFirstChild("ExperienceChat") or cg:WaitForChild("ExperienceChat", 30)
if not ec then
	return
end

local app = ec:FindFirstChild("appLayout") or ec:WaitForChild("appLayout", 30)
if not app then
	return
end

local run = game:GetService("RunService")

local live = true
local cons = {}
local cbag = {}

local win
local cont
local tok = 0

local qset = setmetatable({}, { __mode = "k" })
local hid = setmetatable({}, { __mode = "k" })
local wmap = setmetatable({}, { __mode = "k" })

local qh = 1
local qn = 0
local qrow = {}
local qtry = {}
local qdue = {}

local dly = {0.03, 0.08, 0.18, 0.4}

local function bind(sig, fn, bag)
	local c = sig:Connect(fn)
	local t = bag or cons
	t[#t + 1] = c
	return c
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

	if rawget(root, "__chatLockFix") == st then
		root.__chatLockFix = nil
	end
	if rawget(_G, "__chatLockFix") == st then
		_G.__chatLockFix = nil
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

local function ctext(lbl)
	local ok, s = pcall(function()
		return lbl.ContentText
	end)
	if ok and type(s) == "string" then
		return s
	end
	return ""
end

local function shouldHide(pre, body)
	local p = pre and pre.Text or ""
	if p == "🔒 :" or p == "🔒:" then
		return true
	end

	local b = body.Text or ""
	if b == "" then
		b = ctext(body)
		if b == "" then
			return nil
		end
	end

	if b:find("Only people in similar age groups", 1, true) then
		return true
	end

	if b:find("trusted friends can chat with you", 1, true) then
		return true
	end

	if b:find("🔒 :", 1, true) or b:find("🔒:", 1, true) then
		return true
	end

	return false
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

	local msg = row:FindFirstChild("TextMessage")
	if not msg then
		return false
	end

	local pre = msg:FindFirstChild("PrefixText")
	local body = msg:FindFirstChild("BodyText")
	if not body or not body:IsA("TextLabel") then
		return false
	end

	local bad = shouldHide(pre, body)
	if bad == nil then
		return false
	end

	if bad then
		keepHidden(row, body)
	end

	return true
end

local function clearCont()
	drop(cbag)
	cont = nil
end

local function hookCont(nc)
	if not live or not nc or cont == nc then
		return
	end

	clearCont()
	cont = nc

	local kids = nc:GetChildren()
	for i = 1, #kids do
		push(kids[i], 0, 0)
	end

	bind(nc.ChildAdded, function(ch)
		if not live or cont ~= nc then
			return
		end
		push(ch, 0, 0)
	end, cbag)

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

		local c = b:FindFirstChild("RCTScrollView") or b:WaitForChild("RCTScrollView", 10)
		if not c or not live or tok ~= id or win ~= nw then
			return
		end

		local d = c:FindFirstChild("RCTScrollContentView") or c:WaitForChild("RCTScrollContentView", 10)
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

	local t0 = os.clock()
	local now = t0
	local n = 0

	while qh <= qn and n < 10 and os.clock() - t0 < 0.0012 do
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