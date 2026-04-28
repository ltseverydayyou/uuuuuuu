local function gs(n)
	local s = game:GetService(n)
	if cloneref then
		local ok, r = pcall(cloneref, s)
		if ok and r then
			return r
		end
	end
	return s
end

local Plrs = gs("Players")
local UIS = gs("UserInputService")
local Run = gs("RunService")
local Tween = gs("TweenService")
local Core = gs("CoreGui")
local Ws = gs("Workspace")
local Http = gs("HttpService")
local lp = Plrs.LocalPlayer

local name = "CC_Aimbot_Rework"
local function par()
	if gethui then
		local ok, r = pcall(gethui)
		if ok and r then
			return r
		end
	end
	local ok, r = pcall(function()
		return Core
	end)
	if ok and r then
		return r
	end
	return lp:WaitForChild("PlayerGui")
end

local pg = par()
local old = pg:FindFirstChild(name)
if old then
	old:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = name
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.DisplayOrder = 999999999
gui.Parent = pg

local cons = {}
local tws = setmetatable({}, {__mode = "k"})
local binds = {}
local rows = {}
local keyLs = {}
local vals = {}
local saveLbl
local saveMsg = ""
local cap
local capMods
local capOnly
local capTok = 0
local tabTok = 0

local function bind(sig, fn)
	local c = sig:Connect(fn)
	cons[#cons + 1] = c
	return c
end

local function mk(c, p, parn)
	local o = Instance.new(c)
	for k, v in pairs(p or {}) do
		o[k] = v
	end
	o.Parent = parn
	return o
end

local function cr(p, r)
	return mk("UICorner", {CornerRadius = UDim.new(0, r or 8)}, p)
end

local function st(p, c, t, th)
	return mk("UIStroke", {Color = c or Color3.fromRGB(70, 76, 100), Transparency = t or 0.35, Thickness = th or 1}, p)
end

local function gr(p, a, b, rot)
	return mk("UIGradient", {Color = ColorSequence.new(a, b), Rotation = rot or 0}, p)
end

local function txt(p, s, sz, b)
	return mk("TextLabel", {
		BackgroundTransparency = 1,
		Font = b and Enum.Font.GothamBold or Enum.Font.Gotham,
		Text = s or "",
		TextColor3 = Color3.fromRGB(239, 242, 255),
		TextSize = sz or 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd
	}, p)
end

local function tw(o, ti, pr)
	if tws[o] then
		pcall(function()
			tws[o]:Cancel()
		end)
	end
	local t = Tween:Create(o, ti, pr)
	tws[o] = t
	t:Play()
	return t
end

local state

local function tcol(v)
	return v and Color3.fromRGB(76, 147, 255) or Color3.fromRGB(43, 47, 63)
end

local function aDur(v)
	if state and state.redMotion then
		return 0.01
	end
	local sp = state and tonumber(state.animSpeed) or 1
	return math.clamp(v / math.max(0.25, sp), 0.01, 1)
end

local function ti(v, style, dir)
	return TweenInfo.new(aDur(v), style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
end

state = {
	aim = false,
	lock = false,
	assist = false,
	team = true,
	los = true,
	smooth = true,
	reacq = false,
	showFov = false,
	autoLock = false,
	fly = false,
	noclip = false,
	inf = false,
	esp = false,
	keys = true,
	keyA = true,
	keyP = true,
	keyV = true,
	keyU = true,
	strictMods = true,
	mobile = UIS.TouchEnabled,
	mobAuto = true,
	mobLabels = true,
	mobCompact = false,
	redMotion = false,
	tabAnim = true,
	hoverAnim = true,
	save = true,
	saveTog = true,
	saveBinds = true,
	saveUI = true,
	savePos = true,
	saveMobPos = true,
	minimized = false,
	uiX = nil,
	uiY = nil,
	mobX = nil,
	mobY = nil,
	part = "Head",
	fov = 180,
	maxDist = 1500,
	smoothPower = 0.28,
	assistPower = 0.12,
	flySpeed = 50,
	uiScale = 1,
	animSpeed = 1,
	mobSize = 44,
	mobAlpha = 0.08
}

local defs = {
	aim = false,
	lock = false,
	assist = false,
	team = true,
	los = true,
	smooth = true,
	reacq = false,
	showFov = false,
	autoLock = false,
	fly = false,
	noclip = false,
	inf = false,
	esp = false,
	keys = true,
	keyA = true,
	keyP = true,
	keyV = true,
	keyU = true,
	strictMods = true,
	mobile = UIS.TouchEnabled,
	mobAuto = true,
	mobLabels = true,
	mobCompact = false,
	redMotion = false,
	tabAnim = true,
	hoverAnim = true,
	save = true,
	saveTog = true,
	saveBinds = true,
	saveUI = true,
	savePos = true,
	saveMobPos = true,
	minimized = false
}

local function addBind(id, nm, key, ctrl, sec, shift, alt)
	binds[id] = {name = nm, key = key, ctrl = ctrl == true, shift = shift == true, alt = alt == true, sec = sec}
end

addBind("aim", "Aimbot", Enum.KeyCode.K, false, "aim")
addBind("lock", "Lock Target", Enum.KeyCode.E, false, "aim")
addBind("assist", "Aim Assist", Enum.KeyCode.Z, true, "aim")
addBind("team", "Team Check", Enum.KeyCode.U, false, "aim")
addBind("los", "Visible Check", Enum.KeyCode.L, false, "aim")
addBind("smooth", "Smooth Aim", Enum.KeyCode.Y, false, "aim")
addBind("reacq", "Auto Reacquire", Enum.KeyCode.R, false, "aim")
addBind("showFov", "Show FOV", Enum.KeyCode.G, false, "aim")
addBind("fly", "Fly", Enum.KeyCode.F, false, "plr")
addBind("noclip", "Noclip", Enum.KeyCode.N, false, "plr")
addBind("inf", "Infinite Jump", Enum.KeyCode.I, false, "plr")
addBind("esp", "ESP", Enum.KeyCode.V, false, "vis")
addBind("refesp", "Refresh ESP", Enum.KeyCode.T, false, "vis")
addBind("mini", "Minimize UI", Enum.KeyCode.RightControl, false, "ui")

local defState = {}
for k, v in pairs(state) do
	defState[k] = v
end

local defBinds = {}
for id, b in pairs(binds) do
	defBinds[id] = {key = b.key, ctrl = b.ctrl, shift = b.shift, alt = b.alt}
end

local saveDir = "CC_Aimbot"
local saveFile = saveDir .. "/config.json"
local saveFlat = "CC_Aimbot_config.json"
local savePath = saveFile
local saveBusy = false
local loading = false

local function note(s)
	saveMsg = s or ""
	if saveLbl then
		saveLbl.Text = saveMsg
	end
end

local function fileOK()
	return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
end

local function prepPath()
	if typeof(makefolder) == "function" then
		pcall(function()
			if typeof(isfolder) ~= "function" or not isfolder(saveDir) then
				makefolder(saveDir)
			end
		end)
		savePath = saveFile
	else
		savePath = saveFlat
	end
end

local function keyByName(n)
	if typeof(n) ~= "string" then
		return Enum.KeyCode.Unknown
	end
	local ok, r = pcall(function()
		return Enum.KeyCode[n]
	end)
	if ok and r then
		return r
	end
	return Enum.KeyCode.Unknown
end

local liveKeys = {
	aim = true,
	lock = true,
	assist = true,
	fly = true,
	noclip = true,
	inf = true,
	esp = true
}

local cfgKeys = {
	uiX = true,
	uiY = true,
	mobX = true,
	mobY = true
}

local function packCfg()
	local st = {}
	for k, v in pairs(state) do
		local tp = typeof(v)
		if tp == "boolean" or tp == "number" or tp == "string" then
			if state.saveTog or not liveKeys[k] then
				st[k] = v
			end
		end
	end
	local bd = {}
	if state.saveBinds then
		for id, b in pairs(binds) do
			bd[id] = {
				key = b.key and b.key.Name or "Unknown",
				ctrl = b.ctrl == true,
				shift = b.shift == true,
				alt = b.alt == true
			}
		end
	end
	return {ver = 4, state = st, binds = bd}
end

local function saveNow(force)
	if loading then
		return false
	end
	if not force and not state.save then
		note("Config saving disabled")
		return false
	end
	if not fileOK() then
		note("File API unavailable")
		return false
	end
	prepPath()
	local ok, data = pcall(function()
		return Http:JSONEncode(packCfg())
	end)
	if not ok or typeof(data) ~= "string" then
		note("Config encode failed")
		return false
	end
	local ok2 = pcall(writefile, savePath, data)
	if ok2 then
		note("Saved: " .. savePath)
		return true
	end
	note("Config write failed")
	return false
end

local function qSave()
	if loading or not state.save then
		return
	end
	if saveBusy then
		return
	end
	saveBusy = true
	task.delay(0.35, function()
		saveBusy = false
		saveNow(false)
	end)
end

local function loadCfg(silent)
	if not fileOK() then
		if not silent then
			note("File API unavailable")
		end
		return false
	end
	prepPath()
	if not isfile(savePath) and isfile(saveFlat) then
		savePath = saveFlat
	end
	if not isfile(savePath) then
		if not silent then
			note("No saved config")
		end
		return false
	end
	local ok, raw = pcall(readfile, savePath)
	if not ok or typeof(raw) ~= "string" then
		note("Config read failed")
		return false
	end
	local ok2, data = pcall(function()
		return Http:JSONDecode(raw)
	end)
	if not ok2 or typeof(data) ~= "table" then
		note("Config decode failed")
		return false
	end
	loading = true
	if typeof(data.state) == "table" then
		for k, v in pairs(data.state) do
			if state[k] ~= nil or cfgKeys[k] then
				local cur = typeof(state[k])
				local nt = typeof(v)
				if state[k] == nil or cur == nt then
					state[k] = v
				end
			end
		end
	end
	if typeof(data.binds) == "table" then
		for id, v in pairs(data.binds) do
			local b = binds[id]
			if b and typeof(v) == "table" then
				b.key = keyByName(v.key)
				b.ctrl = v.ctrl == true
				b.shift = v.shift == true
				b.alt = v.alt == true
			end
		end
	end
	loading = false
	note("Loaded: " .. savePath)
	return true
end

local function resetState()
	loading = true
	for k in pairs(state) do
		state[k] = nil
	end
	for k, v in pairs(defState) do
		state[k] = v
	end
	for id, b in pairs(defBinds) do
		if binds[id] then
			binds[id].key = b.key
			binds[id].ctrl = b.ctrl
			binds[id].shift = b.shift
			binds[id].alt = b.alt
		end
	end
	loading = false
	note("Config reset")
end

loadCfg(true)

local main = mk("Frame", {
	AnchorPoint = Vector2.new(0, 0),
	BackgroundColor3 = Color3.fromRGB(13, 15, 22),
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Position = UDim2.fromOffset(160, 120),
	Size = UDim2.fromOffset(520, 420)
}, gui)
cr(main, 18)
st(main, Color3.fromRGB(111, 121, 160), 0.18, 1.25)
gr(main, Color3.fromRGB(19, 22, 32), Color3.fromRGB(11, 12, 18), 90)


local scale = mk("UIScale", {Scale = 0.96}, main)
tw(scale, ti(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})

local top = mk("Frame", {
	BackgroundColor3 = Color3.fromRGB(26, 29, 43),
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 50)
}, main)
cr(top, 18)
gr(top, Color3.fromRGB(34, 39, 61), Color3.fromRGB(20, 22, 34), 0)

local title = txt(top, "CC Aimbot", 16, true)
title.Position = UDim2.fromOffset(16, 0)
title.Size = UDim2.new(1, -140, 1, 0)

local sub = txt(top, "locked-target aim controls", 11, false)
sub.TextColor3 = Color3.fromRGB(146, 157, 200)
sub.Position = UDim2.fromOffset(16, 26)
sub.Size = UDim2.new(1, -140, 0, 18)

local min = mk("TextButton", {
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(44, 49, 70),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "−",
	TextColor3 = Color3.fromRGB(240, 244, 255),
	TextSize = 18,
	Position = UDim2.new(1, -78, 0, 11),
	Size = UDim2.fromOffset(30, 28)
}, top)
cr(min, 9)

local close = mk("TextButton", {
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(76, 42, 55),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "×",
	TextColor3 = Color3.fromRGB(255, 211, 223),
	TextSize = 17,
	Position = UDim2.new(1, -40, 0, 11),
	Size = UDim2.fromOffset(30, 28)
}, top)
cr(close, 9)

local body = mk("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 50),
	Size = UDim2.new(1, 0, 1, -50)
}, main)

local side = mk("Frame", {
	BackgroundColor3 = Color3.fromRGB(18, 20, 30),
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(10, 10),
	Size = UDim2.new(0, 132, 1, -20)
}, body)
cr(side, 14)
st(side, Color3.fromRGB(75, 83, 115), 0.55)
mk("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, side)
mk("UIListLayout", {Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, side)

local holder = mk("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(154, 10),
	Size = UDim2.new(1, -164, 1, -20)
}, body)

local pages = {}
local tabs = {}
local active

local function page(n)
	local sc = mk("ScrollingFrame", {
		Active = true,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		Position = UDim2.fromScale(0, 0),
		ScrollBarImageColor3 = Color3.fromRGB(94, 110, 170),
		ScrollBarThickness = 4,
		Size = UDim2.fromScale(1, 1),
		Visible = false
	}, holder)
	mk("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 6)}, sc)
	mk("UIListLayout", {Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder}, sc)
	pages[n] = sc
	return sc
end

local function tab(n)
	local b = mk("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(28, 32, 47),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = n,
		TextColor3 = Color3.fromRGB(176, 185, 220),
		TextSize = 13,
		Size = UDim2.new(1, 0, 0, 36)
	}, side)
	cr(b, 11)
	local s = st(b, Color3.fromRGB(85, 96, 140), 0.65)
	tabs[n] = {b = b, s = s}
	bind(b.Activated, function()
		if active == n then
			return
		end
		tabTok += 1
		active = n
		for pn, p in pairs(pages) do
			if pn == n then
				p.Visible = true
				p.CanvasPosition = Vector2.zero
				if state.tabAnim and not state.redMotion then
					p.Position = UDim2.fromOffset(0, 8)
					tw(p, ti(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0, 0)})
				else
					p.Position = UDim2.fromScale(0, 0)
				end
			else
				p.Visible = false
				p.Position = UDim2.fromScale(0, 0)
			end
		end
		for tn, tb in pairs(tabs) do
			local on = tn == n
			tw(tb.b, ti(0.18), {
				BackgroundColor3 = on and Color3.fromRGB(72, 91, 151) or Color3.fromRGB(28, 32, 47),
				TextColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(176, 185, 220)
			})
			tw(tb.s, ti(0.18), {Transparency = on and 0.22 or 0.65})
		end
	end)
	return b
end

local pAim = page("Aimbot")
local pPlr = page("Player")
local pVis = page("Visual")
local pSet = page("Settings")
tab("Aimbot")
tab("Player")
tab("Visual")
tab("Settings")

local targetLbl
local lockPart
local noCon
local addCon
local oldCol = setmetatable({}, {__mode = "k"})
local noParts = setmetatable({}, {__mode = "k"})
local flyCon
local flyBg
local flyBv
local flyRt
local espMap = {}
local espCon = {}
local fovBox
local mobPanel
local mobBtns = {}
local mobUp = false
local mobDown = false
local mobRefresh
local mobLayout
local makeMobile
local fit
local set

local function clear(t)
	for k in pairs(t) do
		t[k] = nil
	end
end

local function char()
	return lp.Character
end

local function hum(c)
	c = c or char()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function root(c)
	c = c or char()
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function alive(plr)
	local c = plr and plr.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if not c or not h or h.Health <= 0 then
		return nil
	end
	local hd = c:FindFirstChild(state.part) or c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
	if not hd or not hd:IsA("BasePart") then
		return nil
	end
	return c, h, hd
end

local function same(plr)
	if not state.team then
		return false
	end
	if not lp.Team or not plr.Team then
		return false
	end
	return lp.Team == plr.Team
end

local function los(part)
	local cam = Ws.CurrentCamera
	local c = char()
	if not cam or not part or not c then
		return false
	end
	local rp = RaycastParams.new()
	rp.FilterDescendantsInstances = {c}
	pcall(function()
		rp.FilterType = Enum.RaycastFilterType.Exclude
	end)
	local dir = part.Position - cam.CFrame.Position
	local r = Ws:Raycast(cam.CFrame.Position, dir, rp)
	return not r or r.Instance:IsDescendantOf(part.Parent)
end

local function valid(part)
	if not part or not part.Parent then
		return false
	end
	local p = Plrs:GetPlayerFromCharacter(part.Parent)
	if not p or p == lp or same(p) then
		return false
	end
	local c, h, tg = alive(p)
	if not c or not h or not tg then
		return false
	end
	if state.los and not los(tg) then
		return false
	end
	if (tg.Position - (root() and root().Position or tg.Position)).Magnitude > state.maxDist then
		return false
	end
	return true, tg
end

local function partOf(plr)
	local c, h, tg = alive(plr)
	if not c or not h or not tg then
		return nil
	end
	return tg
end

local function pick()
	local cam = Ws.CurrentCamera
	local rr = root()
	if not cam or not rr then
		return nil
	end
	local vp = cam.ViewportSize
	local cen = Vector2.new(vp.X * 0.5, vp.Y * 0.5)
	local best
	local score = math.huge
	for _, plr in ipairs(Plrs:GetPlayers()) do
		if plr ~= lp and not same(plr) then
			local tg = partOf(plr)
			if tg then
				local dist = (tg.Position - rr.Position).Magnitude
				if dist <= state.maxDist and (not state.los or los(tg)) then
					local pos, on = cam:WorldToViewportPoint(tg.Position)
					if on and pos.Z > 0 then
						local px = (Vector2.new(pos.X, pos.Y) - cen).Magnitude
						if px <= state.fov then
							local sc = px + dist * 0.015
							if sc < score then
								score = sc
								best = tg
							end
						end
					end
				end
			end
		end
	end
	return best
end

local function targ()
	if not targetLbl then
		return
	end
	local n = "None"
	if lockPart and lockPart.Parent then
		local p = Plrs:GetPlayerFromCharacter(lockPart.Parent)
		n = p and p.Name or lockPart.Parent.Name
	end
	targetLbl.Text = "Target: " .. n
end

local function setRow(k, v)
	local it = rows[k]
	if not it then
		return
	end
	local bg = tcol(v)
	local kp = v and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 6, 0.5, 0)
	tw(it.sw, ti(0.16), {BackgroundColor3 = bg})
	tw(it.kn, ti(0.18), {Position = kp})
	if it.lbl then
		it.lbl.TextColor3 = v and Color3.fromRGB(247, 250, 255) or Color3.fromRGB(202, 208, 230)
	end
end

local function kstr(id)
	local b = binds[id]
	if not b or not b.key or b.key == Enum.KeyCode.Unknown then
		return "None"
	end
	local t = {}
	if b.ctrl then
		t[#t + 1] = "Ctrl"
	end
	if b.shift then
		t[#t + 1] = "Shift"
	end
	if b.alt then
		t[#t + 1] = "Alt"
	end
	t[#t + 1] = b.key.Name
	return table.concat(t, "+")
end

local function updKey(id)
	local ls = keyLs[id]
	if ls then
		for _, l in ipairs(ls) do
			l.Text = kstr(id)
		end
	end
end

local function updKeys()
	for id in pairs(binds) do
		updKey(id)
	end
end

local function keyBox(id, parn)
	local box = mk("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(38, 43, 61),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = kstr(id),
		TextColor3 = Color3.fromRGB(201, 211, 245),
		TextSize = 11,
		Size = UDim2.fromOffset(82, 24)
        }, parn)
	cr(box, 8)
	st(box, Color3.fromRGB(90, 102, 150), 0.62)
	if not keyLs[id] then
		keyLs[id] = {}
	end
	keyLs[id][#keyLs[id] + 1] = box
	return box
end

local function header(p, s, subTxt)
	local box = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, subTxt and 40 or 24)}, p)
	local h = txt(box, s, 15, true)
	h.TextColor3 = Color3.fromRGB(166, 179, 230)
	h.Size = UDim2.new(1, 0, 0, 22)
	if subTxt then
		local stx = txt(box, subTxt, 11, false)
		stx.TextColor3 = Color3.fromRGB(126, 137, 178)
		stx.Position = UDim2.fromOffset(0, 20)
		stx.Size = UDim2.new(1, 0, 0, 18)
	end
	return box
end

local function rowBase(p, h)
	local row = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(22, 25, 37),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -4, 0, h or 48)
	}, p)
	cr(row, 12)
	local rs = st(row, Color3.fromRGB(73, 83, 120), 0.58)
	bind(row.MouseEnter, function()
		if not state.hoverAnim or state.redMotion then
			return
		end
		tw(row, ti(0.12), {BackgroundColor3 = Color3.fromRGB(27, 31, 46)})
		tw(rs, ti(0.12), {Transparency = 0.4})
	end)
	bind(row.MouseLeave, function()
		if not state.hoverAnim or state.redMotion then
			return
		end
		tw(row, ti(0.12), {BackgroundColor3 = Color3.fromRGB(22, 25, 37)})
		tw(rs, ti(0.12), {Transparency = 0.58})
	end)
	return row
end

local function toggle(p, k, nm, bid)
	local row = rowBase(p, 48)
	local l = txt(row, nm, 13, true)
	l.TextColor3 = Color3.fromRGB(202, 208, 230)
	l.Position = UDim2.fromOffset(12, 0)
	l.Size = UDim2.new(1, -158, 1, 0)
	if bid then
		local kb = keyBox(bid, row)
		kb.Position = UDim2.new(1, -138, 0.5, -12)
	end
	local sw = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(43, 47, 63),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -48, 0.5, -12),
		Size = UDim2.fromOffset(38, 24)
	}, row)
	cr(sw, 12)
	local kn = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 6, 0.5, 0),
		Size = UDim2.fromOffset(16, 16)
	}, sw)
	cr(kn, 8)
	local bt = mk("TextButton", {AutoButtonColor = false, BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1)}, row)
	rows[k] = {sw = sw, kn = kn, lbl = l}
	bind(bt.Activated, function()
		set(k, not state[k])
	end)
	if state[k] == nil then
		state[k] = defs[k] == true
	end
	setRow(k, state[k])
	return row
end

local function actBtn(p, nm, bid, fn)
	local row = rowBase(p, 46)
	local l = txt(row, nm, 13, true)
	l.Position = UDim2.fromOffset(12, 0)
	l.Size = UDim2.new(1, -110, 1, 0)
	if bid then
		local kb = keyBox(bid, row)
		kb.Position = UDim2.new(1, -96, 0.5, -12)
	end
	local b = mk("TextButton", {AutoButtonColor = false, BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1)}, row)
	bind(b.Activated, fn)
	return row
end

local function slider(p, k, nm, mn, mx, step, suf)
	local row = rowBase(p, 62)
	local l = txt(row, nm, 13, true)
	l.Position = UDim2.fromOffset(12, 3)
	l.Size = UDim2.new(1, -110, 0, 26)
	local vl = txt(row, "", 12, true)
	vl.TextXAlignment = Enum.TextXAlignment.Right
	vl.TextColor3 = Color3.fromRGB(180, 191, 235)
	vl.Position = UDim2.new(1, -90, 3, 0)
	vl.Size = UDim2.fromOffset(80, 26)
	local bar = mk("Frame", {BackgroundColor3 = Color3.fromRGB(37, 42, 58), BorderSizePixel = 0, Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -24, 0, 8)}, row)
	cr(bar, 8)
	local fill = mk("Frame", {BackgroundColor3 = Color3.fromRGB(76, 147, 255), BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0)}, bar)
	cr(fill, 8)
	local hit = mk("TextButton", {AutoButtonColor = false, BackgroundTransparency = 1, Text = "", Position = UDim2.fromOffset(0, -8), Size = UDim2.new(1, 0, 1, 16)}, bar)
	local drag = false
	local function show()
		local v = state[k]
		local pct = math.clamp((v - mn) / (mx - mn), 0, 1)
		fill.Size = UDim2.new(pct, 0, 1, 0)
		vl.Text = tostring(math.floor(v * 100 + 0.5) / 100) .. (suf or "")
	end
	local function apply(input)
		local x = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
		local v = mn + (mx - mn) * x
		if step and step > 0 then
			v = math.floor((v / step) + 0.5) * step
		end
		state[k] = math.clamp(v, mn, mx)
		show()
		if k == "uiScale" then
			if fit then
				fit()
			end
		elseif k == "mobSize" or k == "mobAlpha" then
			if mobRefresh then
				mobRefresh()
			end
		end
		qSave()
	end
	bind(hit.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			drag = true
			apply(input)
		end
	end)
	bind(UIS.InputChanged, function(input)
		if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			apply(input)
		end
	end)
	bind(UIS.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			drag = false
		end
	end)
	show()
	vals[k] = show
	return row, show
end

local function choose(p, k, nm, vals)
	local row = rowBase(p, 48)
	local l = txt(row, nm, 13, true)
	l.Position = UDim2.fromOffset(12, 0)
	l.Size = UDim2.new(1, -116, 1, 0)
	local b = mk("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(38, 43, 61),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = tostring(state[k]),
		TextColor3 = Color3.fromRGB(201, 211, 245),
		TextSize = 12,
		Position = UDim2.new(1, -104, 0.5, -13),
		Size = UDim2.fromOffset(96, 26)
	}, row)
	cr(b, 8)
	st(b, Color3.fromRGB(90, 102, 150), 0.62)
	bind(b.Activated, function()
		local idx = 1
		for i, v in ipairs(vals) do
			if v == state[k] then
				idx = i
				break
			end
		end
		idx = idx + 1
		if idx > #vals then
			idx = 1
		end
		state[k] = vals[idx]
		b.Text = tostring(state[k])
		if state.lock and lockPart then
			local p = Plrs:GetPlayerFromCharacter(lockPart.Parent)
			local np = p and partOf(p)
			lockPart = np or lockPart
			targ()
		end
		qSave()
	end)
	vals[k] = function()
		b.Text = tostring(state[k])
	end
	return row
end

local function keyRow(p, id)
	local bnd = binds[id]
	local row = rowBase(p, 46)
	local l = txt(row, bnd.name, 13, true)
	l.Position = UDim2.fromOffset(12, 0)
	l.Size = UDim2.new(1, -120, 1, 0)
	local kb = keyBox(id, row)
	kb.Position = UDim2.new(1, -96, 0.5, -12)
	bind(kb.Activated, function()
		cap = id
		capMods = {ctrl = false, shift = false, alt = false}
		capOnly = nil
		capTok += 1
		for _, l in ipairs(keyLs[id] or {}) do
			l.Text = "Press..."
		end
	end)
	return row
end

local function addPart(o)
	if o and o:IsA("BasePart") then
		noParts[o] = true
		if oldCol[o] == nil then
			oldCol[o] = o.CanCollide
		end
		o.CanCollide = false
	end
end

local function scanNo()
	local c = char()
	if not c then
		return
	end
	for _, v in ipairs(c:GetDescendants()) do
		addPart(v)
	end
end

local function noStep()
	for p in pairs(noParts) do
		if p and p.Parent then
			if p.CanCollide then
				p.CanCollide = false
			end
		else
			noParts[p] = nil
			oldCol[p] = nil
		end
	end
end

local function noWatch()
	if addCon then
		addCon:Disconnect()
		addCon = nil
	end
	local c = char()
	if c then
		addCon = c.DescendantAdded:Connect(function(o)
			if state.noclip then
				addPart(o)
			end
		end)
		cons[#cons + 1] = addCon
	end
end

local function noOff()
	if noCon then
		noCon:Disconnect()
		noCon = nil
	end
	if addCon then
		addCon:Disconnect()
		addCon = nil
	end
	for p, v in pairs(oldCol) do
		if p and p.Parent then
			pcall(function()
				p.CanCollide = v
			end)
		end
	end
	clear(oldCol)
	clear(noParts)
end

local function flyObjOff()
	if flyBg then
		flyBg:Destroy()
		flyBg = nil
	end
	if flyBv then
		flyBv:Destroy()
		flyBv = nil
	end
	if flyRt then
		local h = hum(flyRt.Parent)
		if h then
			h.PlatformStand = false
		end
	end
	flyRt = nil
end

local function flyStep()
	local c = char()
	local h = hum(c)
	local r = root(c)
	local cam = Ws.CurrentCamera
	if not c or not h or not r or not cam then
		return
	end
	if flyRt ~= r then
		flyObjOff()
		flyRt = r
		flyBg = Instance.new("BodyGyro")
		flyBg.P = 90000
		flyBg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		flyBg.CFrame = r.CFrame
		flyBg.Parent = r
		flyBv = Instance.new("BodyVelocity")
		flyBv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		flyBv.Velocity = Vector3.zero
		flyBv.Parent = r
	end
	local mv = Vector3.zero
	if h.MoveDirection.Magnitude > 0 then
		mv = mv + h.MoveDirection
	end
	if UIS:IsKeyDown(Enum.KeyCode.W) then
		mv = mv + cam.CFrame.LookVector
	end
	if UIS:IsKeyDown(Enum.KeyCode.S) then
		mv = mv - cam.CFrame.LookVector
	end
	if UIS:IsKeyDown(Enum.KeyCode.A) then
		mv = mv - cam.CFrame.RightVector
	end
	if UIS:IsKeyDown(Enum.KeyCode.D) then
		mv = mv + cam.CFrame.RightVector
	end
	if UIS:IsKeyDown(Enum.KeyCode.Space) or mobUp then
		mv = mv + Vector3.yAxis
	end
	if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) or mobDown then
		mv = mv - Vector3.yAxis
	end
	if mv.Magnitude > 0 then
		flyBv.Velocity = mv.Unit * state.flySpeed
	else
		flyBv.Velocity = Vector3.zero
	end
	flyBg.CFrame = cam.CFrame
	h.PlatformStand = true
end

local function flyOff()
	if flyCon then
		flyCon:Disconnect()
		flyCon = nil
	end
	flyObjOff()
end

local function espDel(plr)
	local d = espMap[plr]
	if d then
		for _, o in pairs(d) do
			if typeof(o) == "Instance" then
				o:Destroy()
			end
		end
	end
	espMap[plr] = nil
end

local function espOne(plr)
	if plr == lp then
		return
	end
	espDel(plr)
	local c, h, tg = alive(plr)
	if not c or not h or not tg then
		return
	end
	local col = plr.TeamColor.Color
	local hi = Instance.new("Highlight")
	hi.Name = "CC_Highlight"
	hi.Adornee = c
	hi.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hi.FillColor = col
	hi.FillTransparency = 0.78
	hi.OutlineColor = col
	hi.OutlineTransparency = 0.05
	hi.Parent = gui
	local bb = Instance.new("BillboardGui")
	bb.Name = "CC_Name"
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(180, 34)
	bb.StudsOffset = Vector3.new(0, 2.6, 0)
	bb.Parent = tg
	local lb = Instance.new("TextLabel")
	lb.BackgroundTransparency = 1
	lb.Font = Enum.Font.GothamBold
	lb.Text = plr.Name
	lb.TextColor3 = col
	lb.TextSize = 13
	lb.TextStrokeTransparency = 0.45
	lb.Size = UDim2.fromScale(1, 1)
	lb.Parent = bb
	espMap[plr] = {hi = hi, bb = bb}
end

local function espRefresh()
	for plr in pairs(espMap) do
		espDel(plr)
	end
	if not state.esp then
		return
	end
	for _, plr in ipairs(Plrs:GetPlayers()) do
		espOne(plr)
	end
end

local function espOff()
	for _, c in ipairs(espCon) do
		c:Disconnect()
	end
	clear(espCon)
	for plr in pairs(espMap) do
		espDel(plr)
	end
end

local function espOn()
	espOff()
	espRefresh()
	espCon[#espCon + 1] = Plrs.PlayerAdded:Connect(function(plr)
		espCon[#espCon + 1] = plr.CharacterAdded:Connect(function()
			task.wait(0.45)
			if state.esp then
				espOne(plr)
			end
		end)
	end)
	espCon[#espCon + 1] = Plrs.PlayerRemoving:Connect(function(plr)
		espDel(plr)
	end)
	for _, plr in ipairs(Plrs:GetPlayers()) do
		if plr ~= lp then
			espCon[#espCon + 1] = plr.CharacterAdded:Connect(function()
				task.wait(0.45)
				if state.esp then
					espOne(plr)
				end
			end)
		end
	end
end

local function aimAt(part, pow)
	local cam = Ws.CurrentCamera
	if not cam or not part then
		return
	end
	local cf = CFrame.new(cam.CFrame.Position, part.Position)
	if state.smooth then
		cam.CFrame = cam.CFrame:Lerp(cf, math.clamp(pow, 0.01, 1))
	else
		cam.CFrame = cf
	end
end

local function fovUpd()
	if not fovBox then
		return
	end
	local cam = Ws.CurrentCamera
	if not cam then
		return
	end
	local vp = cam.ViewportSize
	local d = math.max(40, state.fov * 2)
	fovBox.Size = UDim2.fromOffset(d, d)
	fovBox.Position = UDim2.fromOffset((vp.X - d) * 0.5, (vp.Y - d) * 0.5)
	fovBox.Visible = state.showFov
end

local aimCon = Run.RenderStepped:Connect(function()
	fovUpd()
	if state.lock then
		local ok, np = valid(lockPart)
		if not ok then
			if state.reacq then
				lockPart = pick()
			else
				lockPart = nil
				state.lock = false
				setRow("lock", false)
			end
			targ()
		else
			lockPart = np or lockPart
		end
	end
	if not state.lock or not lockPart then
		return
	end
	if not state.aim and not state.assist then
		return
	end
	local p = state.aim and state.smoothPower or state.assistPower
	if state.aim and state.assist then
		p = math.max(state.smoothPower, state.assistPower)
	end
	aimAt(lockPart, p)
end)
cons[#cons + 1] = aimCon

set = function(k, v)
	v = not not v
	if state[k] == v then
		setRow(k, v)
		return
	end
	state[k] = v
	if k == "lock" then
		if v then
			lockPart = pick()
			if not lockPart then
				state[k] = false
				v = false
			end
		else
			lockPart = nil
		end
		targ()
	elseif k == "aim" or k == "assist" then
		if v and state.autoLock and not state.lock then
			state.lock = true
			lockPart = pick()
			if not lockPart then
				state.lock = false
			end
			setRow("lock", state.lock)
			targ()
		end
	elseif k == "noclip" then
		if v then
			scanNo()
			noWatch()
			if not noCon then
				noCon = Run.Stepped:Connect(noStep)
			end
		else
			noOff()
		end
	elseif k == "fly" then
		if v then
			if not flyCon then
				flyCon = Run.RenderStepped:Connect(flyStep)
			end
		else
			flyOff()
		end
	elseif k == "esp" then
		if v then
			espOn()
		else
			espOff()
		end
	elseif k == "showFov" then
		fovUpd()
	elseif k == "mobile" or k == "mobAuto" or k == "mobLabels" or k == "mobCompact" then
		if mobRefresh then
			mobRefresh()
		end
	elseif k == "redMotion" or k == "tabAnim" or k == "hoverAnim" or k == "strictMods" then
		if mobRefresh then
			mobRefresh()
		end
	end
	setRow(k, v)
	if mobRefresh then
		mobRefresh()
	end
	if k == "save" then
		saveNow(true)
	else
		qSave()
	end
end

local function refreshUI()
	for k, v in pairs(state) do
		if rows[k] then
			setRow(k, v == true)
		end
	end
	for _, fn in pairs(vals) do
		pcall(fn)
	end
	updKeys()
	if fit then
		fit()
	end
	fovUpd()
	targ()
	if mobRefresh then
		mobRefresh()
	end
	if saveLbl then
		saveLbl.Text = saveMsg
	end
end

local function applyLive()
	if state.noclip then
		scanNo()
		noWatch()
		if not noCon then
			noCon = Run.Stepped:Connect(noStep)
		end
	else
		noOff()
	end
	if state.fly then
		if not flyCon then
			flyCon = Run.RenderStepped:Connect(flyStep)
		end
	else
		flyOff()
	end
	if state.esp then
		espOn()
	else
		espOff()
	end
	if state.lock then
		lockPart = pick()
		if not lockPart then
			state.lock = false
		end
	else
		lockPart = nil
	end
	refreshUI()
end

header(pAim, "Aimbot", "Aimbot and Aim Assist only move your camera after Lock Target has a valid target.")
toggle(pAim, "aim", "Aimbot", "aim")
toggle(pAim, "lock", "Lock Target", "lock")
toggle(pAim, "assist", "Aim Assist", "assist")
targetLbl = txt(pAim, "Target: None", 12, true)
targetLbl.TextColor3 = Color3.fromRGB(172, 184, 225)
targetLbl.Size = UDim2.new(1, -4, 0, 24)
header(pAim, "Targeting Options")
toggle(pAim, "team", "Team Check", "team")
toggle(pAim, "los", "Visible Check", "los")
toggle(pAim, "smooth", "Smooth Aim", "smooth")
toggle(pAim, "reacq", "Auto Reacquire", "reacq")
toggle(pAim, "autoLock", "Auto Lock When Enabling Aim", nil)
toggle(pAim, "showFov", "Show FOV Circle", "showFov")
choose(pAim, "part", "Aim Part", {"Head", "HumanoidRootPart"})
slider(pAim, "fov", "FOV Radius", 40, 500, 5, "px")
slider(pAim, "maxDist", "Max Distance", 100, 5000, 50, "st")
slider(pAim, "smoothPower", "Aimbot Smoothness", 0.03, 1, 0.01, "")
slider(pAim, "assistPower", "Assist Strength", 0.02, 0.5, 0.01, "")
actBtn(pAim, "Refresh Lock Target", nil, function()
	if state.lock then
		lockPart = pick()
		if not lockPart then
			state.lock = false
			setRow("lock", false)
		end
		targ()
	end
end)

header(pPlr, "Player")
toggle(pPlr, "fly", "Fly", "fly")
toggle(pPlr, "noclip", "Noclip", "noclip")
toggle(pPlr, "inf", "Infinite Jump", "inf")
slider(pPlr, "flySpeed", "Fly Speed", 10, 250, 5, "")

header(pVis, "Visual")
toggle(pVis, "esp", "ESP", "esp")
actBtn(pVis, "Refresh ESP", "refesp", function()
	if state.esp then
		espRefresh()
	end
end)

header(pSet, "Settings", "Click a key box, press a key to bind it, Backspace/Delete clears it, Esc cancels.")
header(pSet, "Config")
toggle(pSet, "save", "Auto Save Config", nil)
toggle(pSet, "saveTog", "Save Live Toggle States", nil)
toggle(pSet, "saveBinds", "Save Keybinds", nil)
toggle(pSet, "saveUI", "Save UI Settings", nil)
toggle(pSet, "savePos", "Save Window Position", nil)
toggle(pSet, "saveMobPos", "Save Mobile Panel Position", nil)
saveLbl = txt(pSet, saveMsg ~= "" and saveMsg or "Config path: " .. savePath, 11, false)
saveLbl.TextColor3 = Color3.fromRGB(146, 157, 200)
saveLbl.Size = UDim2.new(1, -4, 0, 22)
actBtn(pSet, "Save Config Now", nil, function()
	saveNow(true)
end)
actBtn(pSet, "Load Config Now", nil, function()
	if loadCfg(false) then
		applyLive()
	else
		refreshUI()
	end
end)
actBtn(pSet, "Reset Config", nil, function()
	resetState()
	applyLive()
	saveNow(true)
end)
header(pSet, "Keybinds")
toggle(pSet, "keys", "Enable Keybinds", nil)
toggle(pSet, "keyA", "Aimbot Keybinds", nil)
toggle(pSet, "keyP", "Player Keybinds", nil)
toggle(pSet, "keyV", "Visual Keybinds", nil)
toggle(pSet, "keyU", "UI Keybinds", nil)
toggle(pSet, "strictMods", "Strict Combo Matching", nil)
header(pSet, "Interface")
toggle(pSet, "mobile", "Mobile Buttons", nil)
toggle(pSet, "mobAuto", "Auto Mobile Only On Touch", nil)
toggle(pSet, "mobLabels", "Mobile Button Labels", nil)
toggle(pSet, "mobCompact", "Compact Mobile Panel", nil)
toggle(pSet, "tabAnim", "Tab Switch Animations", nil)
toggle(pSet, "hoverAnim", "Hover Animations", nil)
toggle(pSet, "redMotion", "Reduced Motion", nil)
slider(pSet, "uiScale", "UI Scale", 0.75, 1.25, 0.01, "x")
slider(pSet, "animSpeed", "Animation Speed", 0.5, 2, 0.05, "x")
slider(pSet, "mobSize", "Mobile Button Size", 34, 62, 1, "px")
slider(pSet, "mobAlpha", "Mobile Button Transparency", 0, 0.55, 0.01, "")
header(pSet, "Aimbot Binds")
keyRow(pSet, "aim")
keyRow(pSet, "lock")
keyRow(pSet, "assist")
keyRow(pSet, "team")
keyRow(pSet, "los")
keyRow(pSet, "smooth")
keyRow(pSet, "reacq")
keyRow(pSet, "showFov")
header(pSet, "Player Binds")
keyRow(pSet, "fly")
keyRow(pSet, "noclip")
keyRow(pSet, "inf")
header(pSet, "Visual / UI Binds")
keyRow(pSet, "esp")
keyRow(pSet, "refesp")
keyRow(pSet, "mini")
actBtn(pSet, "Reset Binds", nil, function()
	for id, b in pairs(defBinds) do
		if binds[id] then
			binds[id].key = b.key
			binds[id].ctrl = b.ctrl
			binds[id].shift = b.shift
			binds[id].alt = b.alt
		end
	end
	updKeys()
	qSave()
end)

fovBox = mk("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 1000}, gui)
cr(fovBox, 999)
st(fovBox, Color3.fromRGB(90, 160, 255), 0.25, 1.4)
fovUpd()

for _, p in pairs(pages) do
	p.Visible = false
end
pages.Aimbot.Visible = true
tabs.Aimbot.b.BackgroundColor3 = Color3.fromRGB(72, 91, 151)
tabs.Aimbot.b.TextColor3 = Color3.fromRGB(255, 255, 255)
tabs.Aimbot.s.Transparency = 0.22
active = "Aimbot"

local fullSz = UDim2.fromOffset(520, 420)
local minSz = UDim2.fromOffset(520, 50)
local mini = false

fit = function()
	local cam = Ws.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local sc = math.min(1, (vp.X - 24) / 520, (vp.Y - 24) / 420)
	if sc < 0.56 then
		sc = 0.56
	end
	scale.Scale = sc * math.clamp(state.uiScale or 1, 0.65, 1.35)
	local abs = main.AbsoluteSize
	local x = math.clamp(main.Position.X.Offset, 8, math.max(8, vp.X - abs.X - 8))
	local y = math.clamp(main.Position.Y.Offset, 8, math.max(8, vp.Y - abs.Y - 8))
	main.Position = UDim2.fromOffset(x, y)
	fovUpd()
end

task.defer(function()
	local cam = Ws.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	if state.saveUI and state.savePos and typeof(state.uiX) == "number" and typeof(state.uiY) == "number" then
		main.Position = UDim2.fromOffset(state.uiX, state.uiY)
	else
		main.Position = UDim2.fromOffset(math.max(8, (vp.X - 520) / 2), math.max(8, (vp.Y - 420) / 2))
	end
	fit()
end)

local camCon
local function camBind()
	if camCon then
		camCon:Disconnect()
		camCon = nil
	end
	local cam = Ws.CurrentCamera
	if cam then
		camCon = cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
		cons[#cons + 1] = camCon
	end
end
camBind()
bind(Ws:GetPropertyChangedSignal("CurrentCamera"), camBind)

local function setMini(v)
	mini = v
	state.minimized = mini
	body.Visible = not mini
	min.Text = mini and "+" or "−"
	tw(main, ti(0.2), {Size = mini and minSz or fullSz})
	task.delay(aDur(0.22), fit)
	qSave()
end

bind(min.Activated, function()
	setMini(not mini)
end)

bind(close.Activated, function()
	saveNow(false)
	gui:Destroy()
end)

if state.minimized then
	setMini(true)
end

local dragging = false
local dStart
local pStart
local dInput

local function drag(input)
	local delta = input.Position - dStart
	local cam = Ws.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local abs = main.AbsoluteSize
	local x = math.clamp(pStart.X.Offset + delta.X, 8, math.max(8, vp.X - abs.X - 8))
	local y = math.clamp(pStart.Y.Offset + delta.Y, 8, math.max(8, vp.Y - abs.Y - 8))
	main.Position = UDim2.fromOffset(x, y)
	if state.saveUI and state.savePos then
		state.uiX = x
		state.uiY = y
		qSave()
	end
end

bind(top.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dStart = input.Position
		pStart = main.Position
		local ic
		ic = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				if ic then
					ic:Disconnect()
				end
			end
		end)
	end
end)

bind(top.InputChanged, function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dInput = input
	end
end)

bind(UIS.InputChanged, function(input)
	if dragging and input == dInput then
		drag(input)
	end
end)

bind(UIS.JumpRequest, function()
	if state.inf then
		local h = hum()
		if h then
			h:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

local function secOn(sec)
	if sec == "aim" then
		return state.keyA
	elseif sec == "plr" then
		return state.keyP
	elseif sec == "vis" then
		return state.keyV
	elseif sec == "ui" then
		return state.keyU
	end
	return true
end

local function downMod()
	return UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl), UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift), UIS:IsKeyDown(Enum.KeyCode.LeftAlt) or UIS:IsKeyDown(Enum.KeyCode.RightAlt)
end

local function isMod(k)
	return k == Enum.KeyCode.LeftControl or k == Enum.KeyCode.RightControl or k == Enum.KeyCode.LeftShift or k == Enum.KeyCode.RightShift or k == Enum.KeyCode.LeftAlt or k == Enum.KeyCode.RightAlt
end

local function modName(k)
	if k == Enum.KeyCode.LeftControl or k == Enum.KeyCode.RightControl then
		return "ctrl"
	elseif k == Enum.KeyCode.LeftShift or k == Enum.KeyCode.RightShift then
		return "shift"
	elseif k == Enum.KeyCode.LeftAlt or k == Enum.KeyCode.RightAlt then
		return "alt"
	end
end

local function modText(m, key)
	local t = {}
	if m.ctrl then
		t[#t + 1] = "Ctrl"
	end
	if m.shift then
		t[#t + 1] = "Shift"
	end
	if m.alt then
		t[#t + 1] = "Alt"
	end
	if key then
		t[#t + 1] = key.Name
	end
	if #t == 0 then
		return "Press..."
	end
	return table.concat(t, "+")
end

local function applyBind(id, key, m)
	binds[id].key = key or Enum.KeyCode.Unknown
	binds[id].ctrl = m and m.ctrl == true
	binds[id].shift = m and m.shift == true
	binds[id].alt = m and m.alt == true
	cap = nil
	capMods = nil
	capOnly = nil
	updKey(id)
	qSave()
end

local function matched(input, id)
	local b = binds[id]
	if not b or not b.key or b.key == Enum.KeyCode.Unknown then
		return false
	end
	if input.KeyCode ~= b.key then
		return false
	end
	local c, sh, a = downMod()
	if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
		c = false
	elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		sh = false
	elseif input.KeyCode == Enum.KeyCode.LeftAlt or input.KeyCode == Enum.KeyCode.RightAlt then
		a = false
	end
	if state.strictMods then
		return c == (b.ctrl == true) and sh == (b.shift == true) and a == (b.alt == true)
	end
	if b.ctrl and not c then
		return false
	end
	if b.shift and not sh then
		return false
	end
	if b.alt and not a then
		return false
	end
	return true
end

local function runAct(id)
	if id == "refesp" then
		if state.esp then
			espRefresh()
		end
	elseif id == "mini" then
		setMini(not mini)
	elseif state[id] ~= nil then
		set(id, not state[id])
	end
end

local function mobAllowed()
	if not state.mobile then
		return false
	end
	if state.mobAuto and not UIS.TouchEnabled then
		return false
	end
	return true
end

local function mobSetBtn(id)
	local b = mobBtns[id]
	if not b then
		return
	end
	local on = false
	if id == "up" then
		on = mobUp
	elseif id == "down" then
		on = mobDown
	elseif id == "hide" then
		on = mini
	else
		on = state[id] == true
	end
	tw(b, ti(0.12), {
		BackgroundColor3 = on and Color3.fromRGB(76, 147, 255) or Color3.fromRGB(31, 35, 50),
		BackgroundTransparency = math.clamp(state.mobAlpha or 0.08, 0, 0.65)
	})
end

mobLayout = function()
	if not mobPanel then
		return
	end
	local sz = math.floor(state.mobSize or 44)
	local gap = state.mobCompact and 5 or 7
	local cols = state.mobCompact and 3 or 2
	local names = {"aim", "lock", "assist", "fly", "noclip", "esp", "up", "down", "hide"}
	local rowsN = math.ceil(#names / cols)
	mobPanel.Size = UDim2.fromOffset(cols * sz + (cols + 1) * gap, rowsN * sz + (rowsN + 1) * gap)
	local i = 0
	for _, id in ipairs(names) do
		local b = mobBtns[id]
		if b then
			i += 1
			local col = (i - 1) % cols
			local row = math.floor((i - 1) / cols)
			b.Size = UDim2.fromOffset(sz, sz)
			b.Position = UDim2.fromOffset(gap + col * (sz + gap), gap + row * (sz + gap))
			b.TextSize = state.mobLabels and math.clamp(math.floor(sz * 0.24), 9, 13) or 16
		end
	end
	local cam = Ws.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local abs = mobPanel.AbsoluteSize
	local x = math.clamp(mobPanel.Position.X.Offset, 8, math.max(8, vp.X - abs.X - 8))
	local y = math.clamp(mobPanel.Position.Y.Offset, 58, math.max(58, vp.Y - abs.Y - 8))
	mobPanel.Position = UDim2.fromOffset(x, y)
end

mobRefresh = function()
	if not mobPanel then
		return
	end
	mobPanel.Visible = mobAllowed()
	mobLayout()
	local labels = {
		aim = "AIM",
		lock = "LOCK",
		assist = "ASST",
		fly = "FLY",
		noclip = "NOCL",
		esp = "ESP",
		up = "UP",
		down = "DN",
		hide = mini and "+" or "−"
	}
	for id, b in pairs(mobBtns) do
		b.Text = state.mobLabels and labels[id] or "•"
		mobSetBtn(id)
	end
end

makeMobile = function()
	if mobPanel then
		mobPanel:Destroy()
	end
	mobBtns = {}
	mobPanel = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(16, 18, 28),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Position = (state.saveUI and state.saveMobPos and typeof(state.mobX) == "number" and typeof(state.mobY) == "number") and UDim2.fromOffset(state.mobX, state.mobY) or UDim2.new(1, -144, 1, -300),
		Visible = false,
		ZIndex = 1200
	}, gui)
	cr(mobPanel, 16)
	st(mobPanel, Color3.fromRGB(92, 108, 160), 0.45)
	local items = {
		{"aim", "AIM"},
		{"lock", "LOCK"},
		{"assist", "ASST"},
		{"fly", "FLY"},
		{"noclip", "NOCL"},
		{"esp", "ESP"},
		{"up", "UP"},
		{"down", "DN"},
		{"hide", "−"}
	}
	for _, it in ipairs(items) do
		local id, label = it[1], it[2]
		local b = mk("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(31, 35, 50),
			BackgroundTransparency = math.clamp(state.mobAlpha or 0.08, 0, 0.65),
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			Text = label,
			TextColor3 = Color3.fromRGB(242, 246, 255),
			TextSize = 11,
			ZIndex = 1201
		}, mobPanel)
		cr(b, 12)
		mobBtns[id] = b
		if id == "up" or id == "down" then
			bind(b.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					if id == "up" then
						mobUp = true
					else
						mobDown = true
					end
					mobSetBtn(id)
				end
			end)
			bind(b.InputEnded, function(input)
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
					if id == "up" then
						mobUp = false
					else
						mobDown = false
					end
					mobSetBtn(id)
				end
			end)
		elseif id == "hide" then
			bind(b.Activated, function()
				setMini(not mini)
				mobRefresh()
			end)
		else
			bind(b.Activated, function()
				runAct(id)
				mobRefresh()
			end)
		end
	end
	local draggingMob = false
	local ms
	local ps
	bind(mobPanel.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			draggingMob = true
			ms = input.Position
			ps = mobPanel.Position
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					draggingMob = false
					if c then
						c:Disconnect()
					end
				end
			end)
		end
	end)
	bind(UIS.InputChanged, function(input)
		if draggingMob and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local delta = input.Position - ms
			mobPanel.Position = UDim2.fromOffset(ps.X.Offset + delta.X, ps.Y.Offset + delta.Y)
			mobLayout()
			if state.saveUI and state.saveMobPos then
				state.mobX = mobPanel.Position.X.Offset
				state.mobY = mobPanel.Position.Y.Offset
				qSave()
			end
		end
	end)
	mobRefresh()
end

bind(UIS.InputBegan, function(input, gp)
	if UIS:GetFocusedTextBox() then
		return
	end
	if cap then
		local id = cap
		if input.UserInputType == Enum.UserInputType.Keyboard then
			local kc = input.KeyCode
			if kc == Enum.KeyCode.Escape then
				cap = nil
				capMods = nil
				capOnly = nil
				updKey(id)
				return
			elseif kc == Enum.KeyCode.Backspace or kc == Enum.KeyCode.Delete then
				applyBind(id, Enum.KeyCode.Unknown, {})
				return
			elseif kc ~= Enum.KeyCode.Unknown then
				capMods = capMods or {ctrl = false, shift = false, alt = false}
				if isMod(kc) then
					local m = modName(kc)
					capMods[m] = true
					capOnly = kc
					capTok += 1
					local tok = capTok
					for _, l in ipairs(keyLs[id] or {}) do
						l.Text = modText(capMods)
					end
					task.delay(1.25, function()
						if cap == id and capOnly == kc and capTok == tok then
							for _, l in ipairs(keyLs[id] or {}) do
								l.Text = modText(capMods)
							end
						end
					end)
					return
				end
				local c, sh, a = downMod()
				capMods.ctrl = capMods.ctrl or c
				capMods.shift = capMods.shift or sh
				capMods.alt = capMods.alt or a
				applyBind(id, kc, capMods)
				return
			end
		end
		updKey(id)
		return
	end
	if gp or not state.keys or input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
	for id, b in pairs(binds) do
		if secOn(b.sec) and matched(input, id) then
			runAct(id)
			if mobRefresh then
				mobRefresh()
			end
			return
		end
	end
end)

bind(UIS.InputEnded, function(input)
	if not cap or input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
	local id = cap
	local kc = input.KeyCode
	if capOnly == kc and isMod(kc) then
		applyBind(id, kc, {})
	end
end)

makeMobile()
applyLive()
refreshUI()

bind(lp.CharacterAdded, function()
	lockPart = nil
	state.lock = false
	setRow("lock", false)
	targ()
	if state.noclip then
		clear(oldCol)
		clear(noParts)
		task.wait(0.2)
		scanNo()
		noWatch()
	end
	if state.fly then
		flyObjOff()
	end
	if mobRefresh then
		mobRefresh()
	end
end)

gui.Destroying:Connect(function()
	saveNow(false)
	noOff()
	flyOff()
	espOff()
	for _, t in pairs(tws) do
		pcall(function()
			t:Cancel()
		end)
	end
	for _, c in ipairs(cons) do
		pcall(function()
			c:Disconnect()
		end)
	end
end)
