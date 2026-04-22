local env = (getgenv and getgenv()) or _G or {}
local old = env.__ecfix

if type(old) == "table" and type(old.stop) == "function" then
	pcall(old.stop)
end

local st = {}
env.__ecfix = st

local function getCg()
	local ok, s = pcall(function()
		return game:GetService("CoreGui")
	end)
	if not ok or not s then
		return nil
	end
	if cloneref and type(cloneref) == "function" then
		local ok2, r = pcall(cloneref, s)
		if ok2 and r then
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
local ccons = {}

local win
local cont
local tok = 0

local gen = 1
local seen = setmetatable({}, { __mode = "k" })
local qset = setmetatable({}, { __mode = "k" })

local qi = 1
local qn = 0
local qrow = {}
local qtry = {}
local qat = {}

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

local function stop()
	if not live then
		return
	end
	live = false
	drop(ccons)
	drop(cons)
end

st.stop = stop

local function packQ()
	local nrow = {}
	local ntry = {}
	local nat = {}
	local n = 0

	for i = qi, qn do
		local row = qrow[i]
		if row ~= nil then
			n = n + 1
			nrow[n] = row
			ntry[n] = qtry[i]
			nat[n] = qat[i]
		end
	end

	qrow = nrow
	qtry = ntry
	qat = nat
	qi = 1
	qn = n
end

local function mark(a, b)
	seen[a] = gen
	if b then
		seen[b] = gen
	end
end

local function rawTxt(lbl)
	local s = lbl.Text
	if type(s) == "string" then
		return s
	end
	return ""
end

local function richTxt(lbl)
	local ok, s = pcall(function()
		return lbl.ContentText
	end)
	if ok and type(s) == "string" then
		return s
	end
	return ""
end

local function isLock(s)
	return s:match("^%s*🔒%s*:") ~= nil
end

local function push(row, tries, delay)
	if not live or not row or qset[row] then
		return
	end
	qn = qn + 1
	qrow[qn] = row
	qtry[qn] = tries or 0
	qat[qn] = os.clock() + (delay or 0)
	qset[row] = true
end

local function scanRow(row)
	if not live or not row or not row.Parent then
		return true
	end
	if seen[row] == gen then
		return true
	end
	if not row:IsA("GuiObject") then
		return true
	end

	local msg = row:FindFirstChild("TextMessage")
	if not msg then
		return false
	end

	local body = msg:FindFirstChild("BodyText")
	if not body or not body:IsA("TextLabel") then
		return false
	end

	if seen[body] == gen then
		mark(row, body)
		return true
	end

	local raw = rawTxt(body)
	if raw == "" then
		return false
	end

	if not raw:find("🔒", 1, true) then
		mark(row, body)
		return true
	end

	local txt = richTxt(body)
	if txt == "" then
		return false
	end

	if isLock(txt) then
		if row.Visible then
			row.Visible = false
		end
	end

	mark(row, body)
	return true
end

local function clearCont()
	drop(ccons)
	cont = nil
end

local function hookCont(newCont)
	if not live or not newCont or cont == newCont then
		return
	end

	clearCont()
	cont = newCont

	local kids = newCont:GetChildren()
	for i = 1, #kids do
		push(kids[i], 0, 0)
	end

	bind(newCont.ChildAdded, function(ch)
		if not live or cont ~= newCont then
			return
		end
		push(ch, 0, 0)
	end, ccons)

	bind(newCont.AncestryChanged, function(_, par)
		if par == nil and cont == newCont then
			clearCont()
		end
	end, ccons)
end

local function walkWin(newWin, myTok)
	task.spawn(function()
		local a = newWin:FindFirstChild("scrollingView") or newWin:WaitForChild("scrollingView", 10)
		if not a or not live or tok ~= myTok or win ~= newWin then
			return
		end

		local b = a:FindFirstChild("bottomLockedScrollView") or a:WaitForChild("bottomLockedScrollView", 10)
		if not b or not live or tok ~= myTok or win ~= newWin then
			return
		end

		local c = b:FindFirstChild("RCTScrollView") or b:WaitForChild("RCTScrollView", 10)
		if not c or not live or tok ~= myTok or win ~= newWin then
			return
		end

		local d = c:FindFirstChild("RCTScrollContentView") or c:WaitForChild("RCTScrollContentView", 10)
		if not d or not live or tok ~= myTok or win ~= newWin then
			return
		end

		hookCont(d)
	end)
end

local function useWin(newWin)
	if not live or not newWin then
		return
	end
	win = newWin
	tok = tok + 1
	walkWin(newWin, tok)
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

	while qi <= qn and n < 10 and os.clock() - t0 < 0.0012 do
		local row = qrow[qi]
		local tries = qtry[qi]
		local at = qat[qi]

		qrow[qi] = nil
		qtry[qi] = nil
		qat[qi] = nil
		qi = qi + 1
		n = n + 1

		if row then
			qset[row] = nil
		end

		if row and row.Parent then
			if at > now then
				push(row, tries, at - now)
			else
				local ok = scanRow(row)
				if not ok and tries < #dly then
					push(row, tries + 1, dly[tries + 1])
				end
			end
		end
	end

	if qi > 128 and qi > qn / 2 then
		packQ()
	end
end))

task.spawn(function()
	while live do
		task.wait(300)
		if not live then
			break
		end
		gen = gen + 1
	end
end)