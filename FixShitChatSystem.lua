local env = (getgenv and getgenv()) or _G or {}
local sh = rawget(_G, "shared")

local function loaded()
	if env and (env.ltseverydayyou_chatFix or env.chatFixLoaded) then
		return true
	end
	if sh and (sh.ltseverydayyou_chatFix or sh.chatFixLoaded) then
		return true
	end
	return false
end

if loaded() then
	return
end

pcall(function()
	if env then
		env.ltseverydayyou_chatFix = true
		env.chatFixLoaded = true
	end
	if sh then
		sh.ltseverydayyou_chatFix = true
		sh.chatFixLoaded = true
	end
end)

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

local Run = game:GetService("RunService")

local live = true
local cons = {}
local contCons = {}

local curWin
local curCont
local tok = 0

local gen = 1
local seen = setmetatable({}, { __mode = "k" })
local queued = setmetatable({}, { __mode = "k" })

local qi = 1
local qn = 0
local qRow = {}
local qTry = {}
local qAt = {}

local dly = {0.04, 0.12, 0.3, 0.7}

local function bind(sig, fn, bucket)
	local c = sig:Connect(fn)
	local t = bucket or cons
	t[#t + 1] = c
	return c
end

local function clearBucket(t)
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
	clearBucket(contCons)
	clearBucket(cons)
end

local function txt(lbl)
	local ok, v = pcall(function()
		return lbl.ContentText
	end)
	if ok and type(v) == "string" and v ~= "" then
		return v
	end
	v = lbl.Text
	if type(v) == "string" then
		return v
	end
	return ""
end

local function isLock(s)
	return s:match("^%s*🔒%s*:") ~= nil
end

local function markSeen(a, b)
	seen[a] = gen
	if b then
		seen[b] = gen
	end
end

local function enqueue(row, tries, delay)
	if not live or not row or queued[row] then
		return
	end
	qn = qn + 1
	qRow[qn] = row
	qTry[qn] = tries or 0
	qAt[qn] = os.clock() + (delay or 0)
	queued[row] = true
end

local function packQ()
	local nr = {}
	local nt = {}
	local na = {}
	local n = 0
	for i = qi, qn do
		local row = qRow[i]
		if row ~= nil then
			n = n + 1
			nr[n] = row
			nt[n] = qTry[i]
			na[n] = qAt[i]
		end
	end
	qRow = nr
	qTry = nt
	qAt = na
	qi = 1
	qn = n
end

local function hideRow(row)
	if not live or not row or not row.Parent then
		return true
	end
	if seen[row] == gen then
		return true
	end

	local tm = row:FindFirstChild("TextMessage")
	if not tm then
		return false
	end

	local body = tm:FindFirstChild("BodyText")
	if not body or not body:IsA("TextLabel") then
		return false
	end

	if seen[body] == gen then
		markSeen(row, body)
		return true
	end

	local s = txt(body)
	if s == "" then
		return false
	end

	if isLock(s) then
		if row:IsA("GuiObject") and row.Visible then
			row.Visible = false
		elseif body.Visible then
			body.Visible = false
		end
	end

	markSeen(row, body)
	return true
end

local function clearCont()
	clearBucket(contCons)
	curCont = nil
end

local function hookCont(cont)
	if not live or not cont or curCont == cont then
		return
	end

	clearCont()
	curCont = cont

	for _, ch in ipairs(cont:GetChildren()) do
		enqueue(ch, 0, 0)
	end

	bind(cont.ChildAdded, function(ch)
		if not live or curCont ~= cont then
			return
		end
		enqueue(ch, 0, 0)
	end, contCons)

	bind(cont.AncestryChanged, function(_, par)
		if par == nil and curCont == cont then
			clearCont()
			if curWin and curWin.Parent then
				tok = tok + 1
				local myTok = tok
				task.spawn(function()
					local win = curWin
					if not win or not win.Parent then
						return
					end

					local a = win:FindFirstChild("scrollingView") or win:WaitForChild("scrollingView", 10)
					if not a or myTok ~= tok or curWin ~= win or not live then
						return
					end

					local b = a:FindFirstChild("bottomLockedScrollView") or a:WaitForChild("bottomLockedScrollView", 10)
					if not b or myTok ~= tok or curWin ~= win or not live then
						return
					end

					local c = b:FindFirstChild("RCTScrollView") or b:WaitForChild("RCTScrollView", 10)
					if not c or myTok ~= tok or curWin ~= win or not live then
						return
					end

					local d = c:FindFirstChild("RCTScrollContentView") or c:WaitForChild("RCTScrollContentView", 10)
					if not d or myTok ~= tok or curWin ~= win or not live then
						return
					end

					hookCont(d)
				end)
			end
		end
	end, contCons)
end

local function useWin(win)
	if not live or not win then
		return
	end

	curWin = win
	tok = tok + 1
	local myTok = tok

	task.spawn(function()
		local a = win:FindFirstChild("scrollingView") or win:WaitForChild("scrollingView", 10)
		if not a or myTok ~= tok or curWin ~= win or not live then
			return
		end

		local b = a:FindFirstChild("bottomLockedScrollView") or a:WaitForChild("bottomLockedScrollView", 10)
		if not b or myTok ~= tok or curWin ~= win or not live then
			return
		end

		local c = b:FindFirstChild("RCTScrollView") or b:WaitForChild("RCTScrollView", 10)
		if not c or myTok ~= tok or curWin ~= win or not live then
			return
		end

		local d = c:FindFirstChild("RCTScrollContentView") or c:WaitForChild("RCTScrollContentView", 10)
		if not d or myTok ~= tok or curWin ~= win or not live then
			return
		end

		hookCont(d)
	end)
end

local win = app:FindFirstChild("chatWindow")
if win then
	useWin(win)
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
	if ch == curWin then
		curWin = nil
		tok = tok + 1
		clearCont()
	end
end)

bind(ec.AncestryChanged, function(_, par)
	if par == nil then
		stop()
	end
end)

bind(Run.Heartbeat, function()
	if not live then
		return
	end

	local t0 = os.clock()
	local now = t0
	local n = 0

	while qi <= qn and n < 14 and os.clock() - t0 < 0.0015 do
		local row = qRow[qi]
		local tries = qTry[qi]
		local at = qAt[qi]

		qRow[qi] = nil
		qTry[qi] = nil
		qAt[qi] = nil
		qi = qi + 1
		n = n + 1

		if row then
			queued[row] = nil
		end

		if row and row.Parent then
			if at > now then
				enqueue(row, tries, at - now)
			else
				local ok = hideRow(row)
				if not ok and tries < #dly then
					enqueue(row, tries + 1, dly[tries + 1])
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
		if gen > 2048 then
			gen = 1
			seen = setmetatable({}, { __mode = "k" })
		end
	end
end)