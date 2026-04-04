local function bgs(n)
	local s = game:FindService(n)
	if s then
		return s
	end
	local ok, inst = pcall(Instance.new, n)
	if ok and inst and typeof(inst) == "Instance" then
		return inst
	end
	return nil
end

local function svc(n)
	local r = cloneref or function(x)
		return x
	end
	return r(bgs(n))
end

local Tw = svc("TweenService")
local Hs = svc("HttpService")
local UIS = svc("UserInputService")
local Plrs = svc("Players")
local Run = svc("RunService")
local LP = Plrs.LocalPlayer

local mobile = (function()
	local p = UIS:GetPlatform()
	if p == Enum.Platform.IOS or p == Enum.Platform.Android or p == Enum.Platform.AndroidTV or p == Enum.Platform.Chromecast or p == Enum.Platform.MetaOS then
		return true
	end
	if p == Enum.Platform.None then
		return UIS.TouchEnabled and not (UIS.KeyboardEnabled or UIS.MouseEnabled)
	end
	return false
end)()

local theme = {
	bg = Color3.fromRGB(16, 17, 20),
	ac = Color3.fromRGB(26, 27, 31),
	sc = Color3.fromRGB(32, 34, 38),
	tx = Color3.fromRGB(235, 238, 245),
	td = Color3.fromRGB(164, 170, 186),
	br = Color3.fromRGB(58, 60, 66),
	ok = Color3.fromRGB(48, 180, 120),
	warn = Color3.fromRGB(64, 132, 255),
	bad = Color3.fromRGB(200, 64, 72),
	ban_ac = Color3.fromRGB(56, 26, 30),
	ban_st = Color3.fromRGB(200, 64, 72),
	ver_ac = Color3.fromRGB(28, 36, 54),
	ver_st = Color3.fromRGB(64, 132, 255),
	toast = Color3.fromRGB(32, 36, 44)
}

local cfg = {
	show3d = true,
	showInv = true,
	showNames = true,
	showMeta = true,
	showStatus = true,
	showDesc = true,
	showHist = true,
	autoPick = false,
	compact = mobile,
	anim = true,
	invLim = mobile and 12 or 24,
	leftW = mobile and 1 or 0.29,
	corner = mobile and 12 or 14
}

local req = syn and syn.request or request or http_request or http and http.request or krnl and krnl.request or krnl_request or fluxus and fluxus.request
local clip = setclipboard or toclipboard or clipboard and clipboard.set

local gui = Instance.new("ScreenGui")
gui.Name = "\0"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.DisplayOrder = 2147483647
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = gethui and gethui() or svc("CoreGui")

local cons = {}
local function con(sig, fn)
	local c = sig:Connect(fn)
	cons[#cons + 1] = c
	return c
end

local function n2(v, a, b)
	return math.clamp(v, a, b)
end

local function txt(p, s, c, sz, bold)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = s or ""
	l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	l.TextColor3 = c or theme.tx
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Top
	l.TextWrapped = true
	l.TextScaled = false
	l.TextSize = sz or 16
	l.Parent = p
	return l
end

local function stroke(p, col, tr)
	local s = Instance.new("UIStroke")
	s.Color = col or theme.br
	s.Transparency = tr == nil and 0.5 or tr
	s.Thickness = 1
	s.Parent = p
	return s
end

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or cfg.corner)
	c.Parent = p
	return c
end

local function pad(p, l, r, t, b)
	local x = Instance.new("UIPadding")
	x.PaddingLeft = UDim.new(0, l or 0)
	x.PaddingRight = UDim.new(0, r or 0)
	x.PaddingTop = UDim.new(0, t or 0)
	x.PaddingBottom = UDim.new(0, b or 0)
	x.Parent = p
	return x
end

local function setZi(obj, zi)
	pcall(function()
		obj.ZIndex = zi
	end)
	for _, ch in ipairs(obj:GetDescendants()) do
		pcall(function()
			ch.ZIndex = zi
		end)
	end
end

local function btn(p, s)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundColor3 = theme.sc
	b.Text = s
	b.TextColor3 = theme.tx
	b.Font = Enum.Font.GothamBold
	b.TextSize = mobile and 15 or 16
	b.Size = UDim2.fromOffset(42, 36)
	b.Parent = p
	corner(b, 8)
	stroke(b, theme.br, 0.55)
	return b
end

local function tween(o, info, goal)
	if not cfg.anim then
		for k, v in pairs(goal) do
			o[k] = v
		end
		return nil
	end
	local tw = Tw:Create(o, info, goal)
	tw:Play()
	return tw
end

local function flash(b, col)
	local old = b.BackgroundColor3
	tween(b, TweenInfo.new(0.08), {BackgroundColor3 = col})
	task.delay(0.16, function()
		if b and b.Parent then
			tween(b, TweenInfo.new(0.18), {BackgroundColor3 = old})
		end
	end)
end

local toast = Instance.new("TextLabel")
toast.BackgroundColor3 = theme.toast
toast.TextColor3 = theme.tx
toast.Font = Enum.Font.Gotham
toast.TextSize = mobile and 14 or 16
toast.TextWrapped = true
toast.TextXAlignment = Enum.TextXAlignment.Left
toast.TextYAlignment = Enum.TextYAlignment.Center
toast.Text = ""
toast.Visible = false
toast.AnchorPoint = Vector2.new(1, 1)
toast.Size = UDim2.fromOffset(mobile and 260 or 360, mobile and 58 or 64)
toast.Position = UDim2.new(1, -10, 1, -10)
toast.Parent = gui
corner(toast, 10)
stroke(toast, theme.br, 0.45)
pad(toast, 14, 14, 10, 10)

local toastTok = 0
local function notify(s)
	toastTok += 1
	local tok = toastTok
	toast.Text = tostring(s or "")
	toast.Visible = true
	toast.BackgroundTransparency = 1
	toast.TextTransparency = 1
	tween(toast, TweenInfo.new(0.18), {BackgroundTransparency = 0.06, TextTransparency = 0})
	task.delay(1.6, function()
		if toastTok ~= tok then
			return
		end
		tween(toast, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextTransparency = 1})
		task.wait(0.22)
		if toastTok == tok then
			toast.Visible = false
		end
	end)
end

local root = Instance.new("Frame")
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = mobile and UDim2.fromScale(0.98, 0.98) or UDim2.fromScale(0.96, 0.92)
root.BackgroundColor3 = theme.bg
root.BorderSizePixel = 0
root.Parent = gui
corner(root, mobile and 0 or cfg.corner)
local rootSt = stroke(root, theme.br, 0.4)

local top = Instance.new("Frame")
top.BackgroundColor3 = theme.ac
top.BorderSizePixel = 0
top.Size = UDim2.new(1, 0, 0, mobile and 116 or 64)
top.Parent = root
corner(top, mobile and 0 or cfg.corner)

local main = Instance.new("Frame")
main.BackgroundTransparency = 1
main.Position = UDim2.new(0, 0, 0, top.Size.Y.Offset)
main.Size = UDim2.new(1, 0, 1, -top.Size.Y.Offset)
main.Parent = root

local left = Instance.new("Frame")
left.BackgroundColor3 = theme.ac
left.BorderSizePixel = 0
left.Parent = main
corner(left, 10)
local leftSt = stroke(left, theme.br, 0.5)

local right = Instance.new("Frame")
right.BackgroundTransparency = 1
right.Parent = main

local title = txt(top, "User Search", theme.tx, mobile and 22 or 24, true)
local sub = txt(top, "profile • avatar • inventory • tools", theme.td, mobile and 12 or 13, false)
local stat = txt(top, "", theme.td, mobile and 12 or 13, false)

local topBar = Instance.new("Frame")
topBar.BackgroundTransparency = 1
topBar.Parent = top

local topList = Instance.new("UIListLayout")
topList.FillDirection = Enum.FillDirection.Horizontal
topList.Padding = UDim.new(0, 8)
topList.HorizontalAlignment = Enum.HorizontalAlignment.Right
topList.VerticalAlignment = Enum.VerticalAlignment.Center
topList.Parent = topBar

local box = Instance.new("TextBox")
box.BackgroundColor3 = theme.sc
box.TextColor3 = theme.tx
box.PlaceholderText = "search username or id"
box.PlaceholderColor3 = theme.td
box.Text = ""
box.ClearTextOnFocus = false
box.TextXAlignment = Enum.TextXAlignment.Left
box.Font = Enum.Font.Gotham
box.TextSize = mobile and 16 or 18
box.Parent = topBar
corner(box, 8)
stroke(box, theme.br, 0.55)
pad(box, 12, 12, 0, 0)

local bWear = btn(topBar, "WEAR")
local bSearch = btn(topBar, "GO")
local bOpts = btn(topBar, "⚙")
local bClose = btn(topBar, "X")

local res = Instance.new("ScrollingFrame")
res.BackgroundTransparency = 1
res.BorderSizePixel = 0
res.ScrollBarThickness = 6
res.ScrollBarImageColor3 = Color3.fromRGB(100, 102, 110)
res.CanvasSize = UDim2.new()
res.Parent = left
pad(res, 10, 10, 10, 10)
res.Position = UDim2.new(0, 0, 0, 0)
res.Size = UDim2.new(1, 0, 1, 0)
res.AutomaticCanvasSize = Enum.AutomaticSize.None

local resList = Instance.new("UIListLayout")
resList.Padding = UDim.new(0, 8)
resList.SortOrder = Enum.SortOrder.LayoutOrder
resList.Parent = res

local head = Instance.new("Frame")
head.BackgroundColor3 = theme.ac
head.BorderSizePixel = 0
head.Parent = right
corner(head, 10)
local headSt = stroke(head, theme.br, 0.5)

local info = Instance.new("ScrollingFrame")
info.BackgroundTransparency = 1
info.BorderSizePixel = 0
info.ScrollBarThickness = 6
info.ScrollBarImageColor3 = Color3.fromRGB(100, 102, 110)
info.CanvasSize = UDim2.new()
info.Parent = right
pad(info, 10, 10, 0, 10)

local infoList = Instance.new("UIListLayout")
infoList.Padding = UDim.new(0, 10)
infoList.SortOrder = Enum.SortOrder.LayoutOrder
infoList.Parent = info

local pv = Instance.new("ViewportFrame")
pv.BackgroundColor3 = theme.sc
pv.BorderSizePixel = 0
pv.Parent = head
corner(pv, 10)
local pvWm = Instance.new("WorldModel")
pvWm.Parent = pv

local p2 = Instance.new("Frame")
p2.BackgroundColor3 = theme.sc
p2.BorderSizePixel = 0
p2.Parent = head
corner(p2, 10)

local full = Instance.new("ImageLabel")
full.BackgroundTransparency = 1
full.ScaleType = Enum.ScaleType.Fit
full.Image = "rbxassetid://0"
full.Parent = p2
full.AnchorPoint = Vector2.new(0.5, 0.5)
full.Position = UDim2.fromScale(0.5, 0.5)
full.Size = UDim2.fromScale(1, 1)

local face = Instance.new("ImageLabel")
face.BackgroundColor3 = theme.sc
face.BorderSizePixel = 0
face.Image = "rbxassetid://0"
face.Parent = head
corner(face, 10)

local faceVp = Instance.new("ViewportFrame")
faceVp.BackgroundColor3 = theme.sc
faceVp.BorderSizePixel = 0
faceVp.Visible = false
faceVp.Parent = head
corner(faceVp, 10)
local faceWm = Instance.new("WorldModel")
faceWm.Parent = faceVp

local dn = txt(head, "Display Name", theme.tx, mobile and 20 or 22, true)
local un = txt(head, "@username • ID: -", theme.td, mobile and 13 or 14, false)
local quick = txt(head, "Pick a user to view more details.", theme.td, mobile and 12 or 13, false)

local dnCopy = btn(head, "COPY")
local unCopy = btn(head, "COPY")

local optWrap = Instance.new("Frame")
optWrap.BackgroundColor3 = theme.ac
optWrap.BorderSizePixel = 0
optWrap.Visible = false
optWrap.ZIndex = 20
optWrap.Parent = root
optWrap.ClipsDescendants = true
corner(optWrap, 10)
stroke(optWrap, theme.br, 0.45)
pad(optWrap, 12, 12, 12, 12)
setZi(optWrap, 20)

local optTitle = txt(optWrap, "Options", theme.tx, 18, true)
optTitle.Size = UDim2.new(1, 0, 0, 24)

local optScroll = Instance.new("ScrollingFrame")
optScroll.BackgroundTransparency = 1
optScroll.BorderSizePixel = 0
optScroll.Position = UDim2.new(0, 0, 0, 30)
optScroll.Size = UDim2.new(1, 0, 1, -30)
optScroll.ScrollBarThickness = 5
optScroll.CanvasSize = UDim2.new()
optScroll.Parent = optWrap

local optList = Instance.new("UIListLayout")
optList.Padding = UDim.new(0, 8)
optList.SortOrder = Enum.SortOrder.LayoutOrder
optList.Parent = optScroll

local curUid, curTok, seaTok, curProf, curAv
local rows = {}
local rowFns = {}
local histRows = {}
local tryMap = {}
local baseDesc
local faceCam, bodyCam
local selected
local lastQ = ""

local function clearWorld(w)
	for _, v in ipairs(w:GetChildren()) do
		v:Destroy()
	end
end

local function qsz(list, sf, padY)
	sf.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + (padY or 0))
end

con(resList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
	qsz(resList, res, 20)
end)
con(infoList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
	qsz(infoList, info, 10)
end)
con(optList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
	qsz(optList, optScroll, 8)
end)

local function jreq(m, u, b, tries)
	if not req then
		return nil
	end
	local body = b and Hs:JSONEncode(b) or nil
	for _ = 1, tries or 3 do
		local ok, r = pcall(function()
			return req({
				Url = u,
				Method = m,
				Headers = {
					Accept = "application/json",
					["Content-Type"] = body and "application/json" or nil,
					["Cache-Control"] = "no-cache",
					Pragma = "no-cache",
					["User-Agent"] = "Roblox-Client"
				},
				Body = body
			})
		end)
		if ok and r and type(r.Body) == "string" then
			local ok2, data = pcall(function()
				return Hs:JSONDecode(r.Body)
			end)
			if ok2 then
				return data
			end
		end
		task.wait(0.25)
	end
	return nil
end

local function jget(u)
	return jreq("GET", u, nil, 3)
end

local function jpost(u, b)
	return jreq("POST", u, b, 3)
end

local function headUrl(uid)
	local t = jget("https://thumbnails.roproxy.com/v1/users/headshot?userIds=" .. uid .. "&size=420x420&format=Png&isCircular=false")
	return t and t.data and t.data[1] and t.data[1].imageUrl
end

local function mapProp(t)
	if t:find("Animation") then
		return t:gsub("Animation", "") .. "Animation"
	end
	if t == "TShirt" or t == "TShirtGraphic" then
		return "GraphicTShirt"
	end
	if t == "Hat" then
		return "HatAccessory"
	end
	return t
end

local function setProp(d, p, v)
	pcall(function()
		d[p] = v
	end)
end

local function buildDesc(av)
	local d = Instance.new("HumanoidDescription")
	if av and av.bodyColors then
		local bc = av.bodyColors
		setProp(d, "HeadColor", BrickColor.new(bc.headColorId).Color)
		setProp(d, "TorsoColor", BrickColor.new(bc.torsoColorId).Color)
		setProp(d, "LeftArmColor", BrickColor.new(bc.leftArmColorId).Color)
		setProp(d, "RightArmColor", BrickColor.new(bc.rightArmColorId).Color)
		setProp(d, "LeftLegColor", BrickColor.new(bc.leftLegColorId).Color)
		setProp(d, "RightLegColor", BrickColor.new(bc.rightLegColorId).Color)
	end
	local acc = {
		HairAccessory = {},
		FaceAccessory = {},
		NeckAccessory = {},
		ShoulderAccessory = {},
		FrontAccessory = {},
		BackAccessory = {},
		WaistAccessory = {},
		HatAccessory = {}
	}
	if av and av.assets then
		for _, a in ipairs(av.assets) do
			local t = a.assetType and (a.assetType.name or a.assetType.id) or ""
			local p = mapProp(t)
			if p:find("Animation") then
				setProp(d, p, a.id)
			elseif acc[p] then
				table.insert(acc[p], tostring(a.id))
			elseif p == "Shirt" or p == "Pants" or p == "Face" or p == "GraphicTShirt" or p == "Head" or p == "Torso" or p == "LeftArm" or p == "RightArm" or p == "LeftLeg" or p == "RightLeg" then
				setProp(d, p, a.id)
			end
		end
	end
	for k, v in pairs(acc) do
		if #v > 0 then
			setProp(d, k, table.concat(v, ","))
		end
	end
	if av and av.scales then
		local s = av.scales
		setProp(d, "HeightScale", s.height)
		setProp(d, "WidthScale", s.width)
		setProp(d, "HeadScale", s.head)
		setProp(d, "DepthScale", s.depth)
		setProp(d, "BodyTypeScale", s.bodyType)
		setProp(d, "ProportionScale", s.proportion)
	end
	return d
end

local function fmtIso(s, withTime)
	if type(s) ~= "string" then
		return tostring(s or "")
	end
	local y, m, d, H, M, S = s:match("^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)")
	y, m, d, H, M, S = tonumber(y), tonumber(m), tonumber(d), tonumber(H), tonumber(M), tonumber(S)
	if not y then
		return s
	end
	local t = os.time({year = y, month = m, day = d, hour = H, min = M, sec = S})
	local mo = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"}
	local tm = os.date("*t", t)
	if withTime then
		return string.format("%s %02d, %04d  %02d:%02d:%02d", mo[tm.month], tm.day, tm.year, tm.hour, tm.min, tm.sec)
	end
	return string.format("%s %02d, %04d", mo[tm.month], tm.day, tm.year)
end

local function getHum()
	local ch = LP.Character or LP.CharacterAdded:Wait()
	return ch:WaitForChild("Humanoid"), ch
end

do
	local ok, d = pcall(Plrs.GetHumanoidDescriptionFromUserId, Plrs, LP.UserId)
	if ok and d then
		baseDesc = d
	else
		local h = (LP.Character or LP.CharacterAdded:Wait()):WaitForChild("Humanoid")
		baseDesc = h:GetAppliedDescription()
	end
end

local clothes = {
	GraphicTShirt = "ShirtGraphic",
	Shirt = "Shirt",
	Pants = "Pants"
}

local function applyTry()
	local hum, ch = getHum()
	local d = baseDesc:Clone()
	for id, prop in pairs(tryMap) do
		local n = tonumber(id)
		if clothes[prop] or prop == "Face" or prop == "Head" or prop == "Torso" or prop == "LeftArm" or prop == "RightArm" or prop == "LeftLeg" or prop == "RightLeg" then
			d[prop] = n
		elseif prop == "WalkAnimation" or prop == "RunAnimation" or prop == "JumpAnimation" or prop == "FallAnimation" or prop == "ClimbAnimation" or prop == "SwimAnimation" or prop == "IdleAnimation" then
			d[prop] = n
		else
			local cur = tostring(d[prop] or "")
			d[prop] = cur == "" and tostring(n) or (cur .. "," .. n)
		end
	end
	for _, prop in pairs(tryMap) do
		local cls = clothes[prop]
		if cls then
			for _, inst in ipairs(ch:GetChildren()) do
				if inst.ClassName == cls then
					inst:Destroy()
				end
			end
		end
	end
	if hum.ApplyDescriptionClientServer then
		hum:ApplyDescriptionClientServer(d)
	else
		hum:ApplyDescription(d)
	end
end

local function mkSec(name)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = theme.ac
	f.BorderSizePixel = 0
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.Size = UDim2.new(1, -20, 0, 0)
	f.Parent = info
	corner(f, 10)
	stroke(f, theme.br, 0.45)
	pad(f, 10, 10, 8, 10)
	local t = txt(f, name, theme.tx, 17, true)
	t.Size = UDim2.new(1, 0, 0, 22)
	local h = Instance.new("Frame")
	h.BackgroundTransparency = 1
	h.Position = UDim2.new(0, 0, 0, 28)
	h.Size = UDim2.new(1, 0, 0, 0)
	h.AutomaticSize = Enum.AutomaticSize.Y
	h.Parent = f
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, 8)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = h
	return f, h
end

local function kv(h, k, v)
	local r = Instance.new("Frame")
	r.BackgroundTransparency = 1
	r.AutomaticSize = Enum.AutomaticSize.Y
	r.Size = UDim2.new(1, 0, 0, 24)
	r.Parent = h
	local a = txt(r, tostring(k), theme.td, mobile and 13 or 14, false)
	a.Size = mobile and UDim2.new(1, 0, 0, 20) or UDim2.new(0.32, 0, 0, 20)
	local b = txt(r, tostring(v), theme.tx, mobile and 13 or 14, false)
	if mobile then
		b.Position = UDim2.new(0, 0, 0, 18)
		b.Size = UDim2.new(1, 0, 0, 20)
	else
		b.Position = UDim2.new(0.34, 0, 0, 0)
		b.Size = UDim2.new(0.66, 0, 0, 20)
	end
	r.Size = mobile and UDim2.new(1, 0, 0, 40) or UDim2.new(1, 0, 0, 24)
end

local function desc(h, s)
	local r = Instance.new("Frame")
	r.BackgroundTransparency = 1
	r.AutomaticSize = Enum.AutomaticSize.Y
	r.Size = UDim2.new(1, 0, 0, 36)
	r.Parent = h
	local l = txt(r, s or "", theme.tx, mobile and 13 or 14, false)
	l.AutomaticSize = Enum.AutomaticSize.Y
	l.Size = UDim2.new(1, -94, 0, 20)
	local b = btn(r, "COPY")
	b.Size = UDim2.fromOffset(84, 30)
	b.Position = UDim2.new(1, -84, 0, 0)
	con(b.MouseButton1Click, function()
		if clip then
			clip(l.Text)
			flash(b, theme.ok)
			notify("Copied")
		end
	end)
end

local function invCard(h, it)
	local c = Instance.new("Frame")
	c.BackgroundColor3 = theme.sc
	c.BorderSizePixel = 0
	c.Size = UDim2.new(1, 0, 0, mobile and 64 or 72)
	c.Parent = h
	corner(c, 8)
	stroke(c, theme.br, 0.6)
	local im = Instance.new("ImageLabel")
	im.ZIndex = 3
	im.BackgroundColor3 = theme.ac
	im.BorderSizePixel = 0
	im.Position = UDim2.new(0, 8, 0.5, -(mobile and 22 or 24))
	im.Size = UDim2.fromOffset(mobile and 44 or 48, mobile and 44 or 48)
	im.Image = "rbxthumb://type=Asset&id=" .. it.assetId .. "&w=150&h=150"
	im.Parent = c
	corner(im, 6)
	local nm = txt(c, tostring(it.name or "Item"), theme.tx, mobile and 13 or 14, false)
	nm.Position = UDim2.new(0, mobile and 60 or 64, 0, 8)
	nm.Size = UDim2.new(1, -240, 0, 18)
	local idt = txt(c, tostring(it.assetId), theme.td, mobile and 12 or 13, false)
	idt.Position = UDim2.new(0, mobile and 60 or 64, 0, 30)
	idt.Size = UDim2.new(0, 120, 0, 16)
	local b1 = btn(c, "ID")
	local b2 = btn(c, "URL")
	b1.Size = UDim2.fromOffset(72, 28)
	b2.Size = UDim2.fromOffset(72, 28)
	b2.Position = UDim2.new(1, -80, 0, 8)
	b1.Position = UDim2.new(1, -160, 0, 8)
	con(b1.MouseButton1Click, function()
		if clip then
			clip(tostring(it.assetId))
			flash(b1, theme.ok)
		end
	end)
	con(b2.MouseButton1Click, function()
		if clip then
			local slug = (tostring(it.name or "Item"):gsub("[^%w%s%-_]", ""):gsub("%s+", "-"))
			clip("https://www.roblox.com/catalog/" .. it.assetId .. "/" .. slug)
			flash(b2, theme.ok)
		end
	end)
end

local function itemRow(h, id, name, kind, prop, canTry)
	local r = Instance.new("Frame")
	r.BackgroundColor3 = theme.sc
	r.BorderSizePixel = 0
	r.Size = UDim2.new(1, 0, 0, mobile and 78 or 72)
	r.Parent = h
	corner(r, 8)
	stroke(r, theme.br, 0.6)
	local im = Instance.new("ImageLabel")
	im.ZIndex = 3
	im.BackgroundColor3 = theme.ac
	im.BorderSizePixel = 0
	im.Position = UDim2.new(0, 8, 0.5, -(mobile and 24 or 22))
	im.Size = UDim2.fromOffset(mobile and 48 or 44, mobile and 48 or 44)
	im.Image = "rbxthumb://type=Asset&id=" .. id .. "&w=150&h=150"
	im.Parent = r
	corner(im, 6)
	local nm = txt(r, (name or "Item") .. " • " .. (kind or "Asset"), theme.tx, mobile and 13 or 14, false)
	nm.Position = UDim2.new(0, mobile and 64 or 60, 0, 8)
	nm.Size = UDim2.new(1, -300, 0, 18)
	local idt = txt(r, tostring(id), theme.td, mobile and 12 or 13, false)
	idt.Position = UDim2.new(0, mobile and 64 or 60, 0, 30)
	idt.Size = UDim2.new(0, 120, 0, 16)
	local x = 1
	local function mk(s, ox)
		local b = btn(r, s)
		b.Size = UDim2.fromOffset(mobile and 62 or 72, 28)
		b.Position = UDim2.new(x, ox, 0, 8)
		return b
	end
	local bUrl = mk("URL", mobile and -70 or -80)
	local bId = mk("ID", mobile and -138 or -160)
	local bTry
	if canTry then
		bTry = mk(tryMap[tostring(id)] and "OFF" or "TRY", mobile and -206 or -240)
	end
	con(bId.MouseButton1Click, function()
		if clip then
			clip(tostring(id))
			flash(bId, theme.ok)
		end
	end)
	con(bUrl.MouseButton1Click, function()
		if clip then
			local slug = (tostring(name or "Item"):gsub("[^%w%s%-_]", ""):gsub("%s+", "-"))
			clip("https://www.roblox.com/catalog/" .. id .. "/" .. slug)
			flash(bUrl, theme.ok)
		end
	end)
	if bTry then
		con(bTry.MouseButton1Click, function()
			local key = tostring(id)
			if tryMap[key] then
				tryMap[key] = nil
			else
				tryMap[key] = prop
			end
			bTry.Text = tryMap[key] and "OFF" or "TRY"
			stat.Text = "Applying try-on"
			applyTry()
			stat.Text = ""
			flash(bTry, theme.ok)
		end)
	end
end

local function tintTop(ban, ver)
	if ban then
		top.BackgroundColor3 = theme.ban_ac
		head.BackgroundColor3 = theme.ban_ac
		left.BackgroundColor3 = theme.ban_ac
		rootSt.Color = theme.ban_st
		headSt.Color = theme.ban_st
		leftSt.Color = theme.ban_st
	elseif ver then
		top.BackgroundColor3 = theme.ver_ac
		head.BackgroundColor3 = theme.ver_ac
		left.BackgroundColor3 = theme.ver_ac
		rootSt.Color = theme.ver_st
		headSt.Color = theme.ver_st
		leftSt.Color = theme.ver_st
	else
		top.BackgroundColor3 = theme.ac
		head.BackgroundColor3 = theme.ac
		left.BackgroundColor3 = theme.ac
		rootSt.Color = theme.br
		headSt.Color = theme.br
		leftSt.Color = theme.br
	end
end

local function camBody(m)
	if bodyCam then
		bodyCam:Destroy()
	end
	bodyCam = Instance.new("Camera")
	bodyCam.Parent = pv
	pv.CurrentCamera = bodyCam
	local cf, sz = m:GetBoundingBox()
	local hrp = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
	if hrp then
		hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.pi, 0)
	end
	local focus = hrp and hrp.Position or cf.Position
	local yOff = sz.Y * 0.18
	local dist = math.max(sz.X, sz.Y, sz.Z) * 1.15 + 0.6
	bodyCam.CFrame = CFrame.new(focus + Vector3.new(0, yOff, dist), focus + Vector3.new(0, (-sz.Y) * 0.05, 0))
end

local function camHead(m)
	if faceCam then
		faceCam:Destroy()
	end
	faceCam = Instance.new("Camera")
	faceCam.Parent = faceVp
	faceVp.CurrentCamera = faceCam
	local h = m:FindFirstChild("Head") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
	if h then
		local p = h.Position
		faceCam.CFrame = CFrame.new(p + Vector3.new(0, 0.1, 2.2), p + Vector3.new(0, 0.1, 0))
	end
end

local function setHead(uid, ban, tok, av)
	if not ban then
		faceVp.Visible = false
		face.Visible = true
		local u = headUrl(uid)
		if curTok ~= tok then
			return
		end
		face.Image = u or ("rbxthumb://type=AvatarHeadShot&id=" .. uid .. "&w=420&h=420")
	else
		face.Visible = false
		faceVp.Visible = true
		clearWorld(faceWm)
		local a = av or jget("https://avatar.roproxy.com/v1/users/" .. uid .. "/avatar")
		if curTok ~= tok then
			return
		end
		local d = buildDesc(a)
		local mdl = Plrs:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R6)
		mdl.Parent = faceWm
		camHead(mdl)
	end
end

local function clearInfo()
	for _, ch in ipairs(info:GetChildren()) do
		if ch:IsA("Frame") then
			ch:Destroy()
		end
	end
end

local function clearRes()
	for _, ch in ipairs(res:GetChildren()) do
		if ch:IsA("Frame") then
			ch:Destroy()
		end
	end
	rows = {}
	rowFns = {}
	selected = nil
end

local function rowTint(r, ban, ver, picked)
	local st = r:FindFirstChildOfClass("UIStroke")
	local col = theme.sc
	local stc = theme.br
	if ban then
		col = theme.ban_ac
		stc = theme.ban_st
	elseif ver then
		col = theme.ver_ac
		stc = theme.ver_st
	end
	if picked then
		col = Color3.fromRGB(math.floor(math.min(col.R * 255 + 14, 255)), math.floor(math.min(col.G * 255 + 14, 255)), math.floor(math.min(col.B * 255 + 14, 255)))
	end
	r.BackgroundColor3 = col
	if st then
		st.Color = stc
	end
end

local function pickRow(r)
	if selected and selected ~= r then
		rowTint(selected, selected:GetAttribute("Ban"), selected:GetAttribute("Ver"), false)
	end
	selected = r
	rowTint(r, r:GetAttribute("Ban"), r:GetAttribute("Ver"), true)
end

local function addRow(u, prof0, tok)
	if seaTok ~= tok then
		return
	end
	local r = Instance.new("Frame")
	r.BackgroundColor3 = theme.sc
	r.BorderSizePixel = 0
	r.Size = UDim2.new(1, 0, 0, mobile and 84 or 78)
	r.ZIndex = 2
	r.Parent = res
	corner(r, 10)
	stroke(r, theme.br, 0.55)
	local ban = prof0 and prof0.isBanned == true
	local ver = not ban and (u.hasVerifiedBadge == true or prof0 and prof0.hasVerifiedBadge)
	r:SetAttribute("Ban", ban)
	r:SetAttribute("Ver", ver)
	rowTint(r, ban, ver, false)
	local im = Instance.new("ImageLabel")
	im.ZIndex = 3
	im.BackgroundColor3 = theme.ac
	im.BorderSizePixel = 0
	im.Position = UDim2.new(0, 8, 0.5, -28)
	im.Size = UDim2.fromOffset(56, 56)
	im.Image = "rbxthumb://type=AvatarHeadShot&id=" .. u.id .. "&w=150&h=150"
	im.Parent = r
	corner(im, 8)
	local n1 = txt(r, tostring(u.displayName or u.name), theme.tx, mobile and 14 or 15, true)
	n1.ZIndex = 3
	n1.Position = UDim2.new(0, 72, 0, 8)
	n1.Size = UDim2.new(1, -84, 0, 18)
	local line = "@" .. tostring(u.name) .. " • " .. (ban and "Banned" or (ver and "Verified" or "User")) .. " • " .. tostring(u.id)
	local n2 = txt(r, line, ban and theme.ban_st or (ver and theme.ver_st or theme.td), mobile and 12 or 13, false)
	n2.ZIndex = 3
	n2.Position = UDim2.new(0, 72, 0, 34)
	n2.Size = UDim2.new(1, -84, 0, 30)
	local hit = Instance.new("TextButton")
	hit.Text = ""
	hit.BackgroundTransparency = 1
	hit.ZIndex = 4
	hit.Size = UDim2.fromScale(1, 1)
	hit.Parent = r
	local busy = false
	local function openRow()
		if busy then
			return
		end
		busy = true
		pickRow(r)
		stat.Text = "Loading: profile"
		task.spawn(function()
			local ok, err = pcall(function()
				curUid = u.id
				curTok = Hs:GenerateGUID(false)
				local tok2 = curTok
				clearInfo()
				full.Image = "rbxassetid://0"
				clearWorld(pvWm)
				clearWorld(faceWm)
				local prof = prof0 or jget("https://users.roproxy.com/v1/users/" .. u.id)
				if not prof or prof.errors then
					prof = jget("https://users.roproxy.com/v1/users/" .. u.id)
				end
				if not prof or prof.errors then
					dn.Text = "User not found"
					un.Text = ""
					stat.Text = ""
					return
				end
				curProf = prof
				tintTop(prof.isBanned == true, prof.hasVerifiedBadge == true)
				dn.Text = tostring(prof.displayName or prof.name or "")
				un.Text = "@" .. tostring(prof.name or "") .. " • ID: " .. tostring(prof.id)
				quick.Text = (prof.isBanned and "Banned profile" or (prof.hasVerifiedBadge and "Verified profile" or "Regular profile")) .. " • choose options in the gear menu"
				curAv = jget("https://avatar.roproxy.com/v1/users/" .. u.id .. "/avatar")
				local mdl = Plrs:CreateHumanoidModelFromDescription(buildDesc(curAv or {}), Enum.HumanoidRigType.R6)
				mdl.Parent = pvWm
				camBody(mdl)
				setHead(prof.id, prof.isBanned == true, tok2, curAv)
				full.Image = "rbxthumb://type=Avatar&id=" .. u.id .. "&w=420&h=420"
				if cfg.showMeta then
					local _, h = mkSec("Overview")
					kv(h, "Has Verified Badge", prof.hasVerifiedBadge)
					kv(h, "Is Banned", prof.isBanned)
					kv(h, "Created", fmtIso(prof.created or "", true))
				end
				if cfg.showDesc then
					local dsc = tostring(prof.description or "")
					if dsc ~= "" then
						local _, h = mkSec("Description")
						desc(h, dsc)
					end
				end
				if cfg.showStatus then
					local st = jget("https://users.roproxy.com/v1/users/" .. u.id .. "/status")
					if st and not st.errors and st.status and st.status ~= "" then
						local _, h = mkSec("Status")
						desc(h, st.status)
					end
				end
				if cfg.showHist then
					local h1 = jget("https://users.roproxy.com/v1/users/" .. u.id .. "/username-history?limit=100&sortOrder=Asc")
					local h2 = jget("https://users.roproxy.com/v1/users/" .. u.id .. "/username-history?limit=100&sortOrder=Desc")
					local seen, arr = {}, {}
					local function push(hx)
						if hx and hx.data then
							for _, it in ipairs(hx.data) do
								local n = it.name or it.username
								if n and not seen[n] then
									seen[n] = true
									arr[#arr + 1] = {n = n, t = it.created or ""}
								end
							end
						end
					end
					push(h1)
					push(h2)
					if #arr > 0 then
						table.sort(arr, function(a, b)
							return a.t < b.t
						end)
						local _, h = mkSec("Previous Usernames")
						for i = 1, math.min(#arr, cfg.compact and 18 or 40) do
							local x = arr[i]
							local rr = Instance.new("Frame")
							rr.BackgroundTransparency = 1
							rr.Size = UDim2.new(1, 0, 0, 30)
							rr.Parent = h
							local vv = txt(rr, fmtIso(x.t, false) .. " • " .. x.n, theme.tx, mobile and 13 or 14, false)
							vv.Size = UDim2.new(1, -92, 1, 0)
							local bb = btn(rr, "COPY")
							bb.Size = UDim2.fromOffset(84, 28)
							bb.Position = UDim2.new(1, -84, 0, 0)
							con(bb.MouseButton1Click, function()
								if clip then
									clip(x.n)
									flash(bb, theme.ok)
								end
							end)
						end
					end
				end
				if curAv and not curAv.errors then
					local _, ah = mkSec("Avatar")
					kv(ah, "Avatar Type", curAv.playerAvatarType or "")
					local _, sh = mkSec("Body Scales")
					for _, k in ipairs({"height","width","head","depth","proportion","bodyType"}) do
						local v = curAv.scales and curAv.scales[k]
						if v ~= nil then
							kv(sh, k, math.floor(v * 100) / 100)
						end
					end
					local _, ch = mkSec("Body Colors")
					local bc = curAv.bodyColors or {}
					for _, pair in ipairs({
						{"Head", bc.headColorId},
						{"Torso", bc.torsoColorId},
						{"Left Arm", bc.leftArmColorId},
						{"Right Arm", bc.rightArmColorId},
						{"Left Leg", bc.leftLegColorId},
						{"Right Leg", bc.rightLegColorId}
					}) do
						if pair[2] then
							local br = BrickColor.new(pair[2])
							local rgb = math.floor(br.Color.R * 255 + 0.5) .. "," .. math.floor(br.Color.G * 255 + 0.5) .. "," .. math.floor(br.Color.B * 255 + 0.5)
							kv(ch, pair[1], br.Name .. " (" .. pair[2] .. ") • RGB(" .. rgb .. ")")
						end
					end
					local _, an = mkSec("Animations")
					local _, bp = mkSec("Body Parts")
					local _, ac = mkSec("Accessories")
					local _, em = mkSec("Emotes")
					for _, a in ipairs(curAv.assets or {}) do
						local kind = a.assetType and a.assetType.name or "Asset"
						local prop = mapProp(kind)
						if kind ~= "Emote" then
							if kind:find("Animation") then
								itemRow(an, a.id, a.name and #a.name > 0 and a.name or kind, kind, prop, true)
							elseif kind == "Head" or kind == "Torso" or kind == "LeftArm" or kind == "RightArm" or kind == "LeftLeg" or kind == "RightLeg" or kind == "Face" or kind == "Shirt" or kind == "Pants" or kind == "TShirt" then
								itemRow(bp, a.id, a.name and #a.name > 0 and a.name or kind, kind, prop, true)
							else
								itemRow(ac, a.id, a.name and #a.name > 0 and a.name or kind, kind, prop, true)
							end
						end
					end
					if curAv.emotes and #curAv.emotes > 0 then
						for _, e in ipairs(curAv.emotes) do
							itemRow(em, e.assetId, e.assetName or "Emote", "Emote", "", false)
						end
					else
						kv(em, "Empty", "No emotes")
					end
				end
				if cfg.showMeta then
					local promo = jget("https://users.roproxy.com/v1/users/" .. u.id .. "/promotion-channels")
					if promo and not promo.errors then
						local keep = {}
						for k, v in pairs(promo) do
							if v and v ~= "" then
								keep[k] = v
							end
						end
						if next(keep) then
							local _, h = mkSec("Promotion Channels")
							for k, v in pairs(keep) do
								kv(h, k, v)
							end
						end
					end
					local meta = jget("https://users.roproxy.com/v1/users/" .. u.id .. "/metadata")
					if meta and not meta.errors and next(meta) then
						local _, h = mkSec("User Metadata")
						for k, v in pairs(meta) do
							kv(h, k, v)
						end
					end
				end
				if cfg.showInv then
					local function addInv(name, kinds)
						local d = jget("https://inventory.roproxy.com/v2/users/" .. tostring(u.id) .. "/inventory?assetTypes=" .. kinds .. "&limit=" .. tostring(cfg.invLim) .. "&sortOrder=Desc")
						if d and d.data and #d.data > 0 then
							local _, h = mkSec(name)
							for _, it in ipairs(d.data) do
								invCard(h, it)
							end
						end
					end
					addInv("Inventory • Accessories", "Hat,HairAccessory,FaceAccessory,NeckAccessory,ShoulderAccessory,FrontAccessory,BackAccessory,WaistAccessory")
					addInv("Inventory • Clothing", "TShirt,Shirt,Pants,Jacket,Sweater,Shorts,DressSkirt")
				end
				if mobile then
					info.CanvasPosition = Vector2.zero
				end
			end)
			if not ok then
				notify("Failed to render profile")
				warn(err)
			end
			busy = false
			stat.Text = ""
		end)
	end
	rowFns[r] = openRow
	con(hit.MouseButton1Click, openRow)
	if hit:IsA("GuiButton") then
		con(hit.Activated, openRow)
	end
end

local function fillRows(list, tok)
	for i = 1, #list do
		if seaTok ~= tok then
			return
		end
		local inf = list[i]
		local full = i <= 10 and jget("https://users.roproxy.com/v1/users/" .. inf.id) or nil
		addRow(inf.basic, full, tok)
		if i % 4 == 0 then
			Run.Heartbeat:Wait()
		end
	end
	if cfg.autoPick then
		for _, ch in ipairs(res:GetChildren()) do
			if ch:IsA("Frame") and rowFns[ch] then
				task.spawn(function()
					pcall(rowFns[ch])
				end)
				break
			end
		end
	end
end

local function runSearch(q)
	seaTok = Hs:GenerateGUID(false)
	local tok = seaTok
	stat.Text = "Loading: search"
	clearRes()
	q = tostring(q or ""):gsub("^%s+", ""):gsub("%s+$", "")
	lastQ = q
	if q == "" then
		stat.Text = ""
		return
	end
	local list = {}
	if q:match("^%d+$") then
		local u = jget("https://users.roproxy.com/v1/users/" .. q)
		if u and not u.errors then
			list[#list + 1] = {id = u.id, basic = {id = u.id, name = u.name, displayName = u.displayName, hasVerifiedBadge = u.hasVerifiedBadge}}
		end
	else
		local resData = jget("https://users.roproxy.com/v1/users/search?keyword=" .. Hs:UrlEncode(q) .. "&limit=" .. tostring(cfg.compact and 12 or 25))
		if resData and not resData.errors and resData.data then
			for _, u in ipairs(resData.data) do
				list[#list + 1] = {id = u.id, basic = u}
			end
		end
		local ex = jpost("https://users.roproxy.com/v1/usernames/users", {
			usernames = {q},
			excludeBannedUsers = false
		})
		local d = ex and ex.data and ex.data[1]
		if d and d.id then
			local seen = false
			for _, it in ipairs(list) do
				if it.id == d.id then
					seen = true
					break
				end
			end
			if not seen then
				table.insert(list, 1, {id = d.id, basic = {id = d.id, name = d.requestedUsername or d.name, displayName = d.displayName or d.name, hasVerifiedBadge = d.hasVerifiedBadge}})
			end
		end
	end
	if #list == 0 then
		stat.Text = "No results"
		notify("No users found")
		return
	end
	fillRows(list, tok)
	stat.Text = ""
end

local function boolRow(name, key)
	local r = Instance.new("Frame")
	r.BackgroundColor3 = theme.sc
	r.BorderSizePixel = 0
	r.Size = UDim2.new(1, 0, 0, 42)
	r.Parent = optScroll
	corner(r, 8)
	stroke(r, theme.br, 0.55)
	local l = txt(r, name, theme.tx, 14, false)
	l.Position = UDim2.new(0, 10, 0, 11)
	l.Size = UDim2.new(1, -88, 0, 20)
	local b = btn(r, cfg[key] and "ON" or "OFF")
	b.Size = UDim2.fromOffset(68, 28)
	b.Position = UDim2.new(1, -78, 0, 7)
	con(b.MouseButton1Click, function()
		cfg[key] = not cfg[key]
		b.Text = cfg[key] and "ON" or "OFF"
		if key == "show3d" then
			pv.Visible = cfg.show3d
		end
		if curUid then
			runSearch(lastQ)
		end
	end)
end

local function stepRow(name, key, min, max, step)
	local r = Instance.new("Frame")
	r.BackgroundColor3 = theme.sc
	r.BorderSizePixel = 0
	r.Size = UDim2.new(1, 0, 0, 42)
	r.Parent = optScroll
	corner(r, 8)
	stroke(r, theme.br, 0.55)
	local l = txt(r, name .. ": " .. tostring(cfg[key]), theme.tx, 14, false)
	l.Position = UDim2.new(0, 10, 0, 11)
	l.Size = UDim2.new(1, -156, 0, 20)
	local m = btn(r, "-")
	local p = btn(r, "+")
	m.Size = UDim2.fromOffset(32, 28)
	p.Size = UDim2.fromOffset(32, 28)
	m.Position = UDim2.new(1, -78, 0, 7)
	p.Position = UDim2.new(1, -40, 0, 7)
	local function sync()
		cfg[key] = n2(cfg[key], min, max)
		l.Text = name .. ": " .. tostring(cfg[key])
		if key == "invLim" and curUid then
			runSearch(lastQ)
		end
	end
	con(m.MouseButton1Click, function()
		cfg[key] -= step
		sync()
	end)
	con(p.MouseButton1Click, function()
		cfg[key] += step
		sync()
	end)
	sync()
end

boolRow("3D preview", "show3d")
boolRow("Show inventory", "showInv")
boolRow("Show username history", "showHist")
boolRow("Show metadata", "showMeta")
boolRow("Show status", "showStatus")
boolRow("Show description", "showDesc")
boolRow("Compact mode", "compact")
boolRow("Auto pick first result", "autoPick")
boolRow("UI animations", "anim")
stepRow("Inventory limit", "invLim", 6, 36, 6)

local function layout()
	local cam = workspace.CurrentCamera
	local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
	mobile = mobile or vs.X < 900
	if vs.X < 900 then
		local topH = 116
		local leftH = math.floor(n2(vs.Y * 0.19, 132, 176))
		local rightH = vs.Y - topH - leftH - 24
		local headH = math.floor(n2(rightH * 0.28, 156, 220))
		local topInfoH = 76
		local previewY = topInfoH + 8
		local previewH = math.max(72, headH - previewY - 8)
		root.Size = UDim2.fromScale(0.98, 0.98)
		top.Size = UDim2.new(1, 0, 0, topH)
		main.Position = UDim2.new(0, 0, 0, topH)
		main.Size = UDim2.new(1, 0, 1, -topH)
		title.Position = UDim2.new(0, 12, 0, 8)
		title.Size = UDim2.new(1, -24, 0, 24)
		sub.Position = UDim2.new(0, 12, 0, 34)
		sub.Size = UDim2.new(1, -24, 0, 18)
		stat.Position = UDim2.new(0, 12, 0, 52)
		stat.Size = UDim2.new(1, -24, 0, 18)
		topBar.Position = UDim2.new(0, 12, 0, 74)
		topBar.Size = UDim2.new(1, -24, 0, 36)
		box.Size = UDim2.new(1, -174, 1, 0)
		bWear.Size = UDim2.fromOffset(64, 36)
		bSearch.Size = UDim2.fromOffset(42, 36)
		bOpts.Size = UDim2.fromOffset(42, 36)
		bClose.Size = UDim2.fromOffset(42, 36)
		left.Position = UDim2.new(0, 8, 0, 8)
		left.Size = UDim2.new(1, -16, 0, leftH)
		right.Position = UDim2.new(0, 8, 0, leftH + 14)
		right.Size = UDim2.new(1, -16, 1, -(leftH + 22))
		head.Position = UDim2.new(0, 0, 0, 0)
		head.Size = UDim2.new(1, 0, 0, headH)
		info.Position = UDim2.new(0, 0, 0, headH + 6)
		info.Size = UDim2.new(1, 0, 1, -(headH + 6))
		face.Size = UDim2.fromOffset(58, 58)
		face.Position = UDim2.new(0, 10, 0, 10)
		faceVp.Size = face.Size
		faceVp.Position = face.Position
		dn.Position = UDim2.new(0, 78, 0, 10)
		dn.Size = UDim2.new(1, -172, 0, 20)
		un.Position = UDim2.new(0, 78, 0, 30)
		un.Size = UDim2.new(1, -172, 0, 15)
		quick.Position = UDim2.new(0, 78, 0, 46)
		quick.Size = UDim2.new(1, -96, 0, 28)
		dnCopy.Size = UDim2.fromOffset(72, 24)
		unCopy.Size = UDim2.fromOffset(72, 24)
		dnCopy.Position = UDim2.new(1, -82, 0, 10)
		unCopy.Position = UDim2.new(1, -82, 0, 38)
		p2.Position = UDim2.new(0, 10, 0, previewY)
		p2.Size = UDim2.new(0.32, -14, 0, previewH)
		pv.Position = UDim2.new(0.32, 6, 0, previewY)
		pv.Size = UDim2.new(0.68, -16, 0, previewH)
		local optH = math.floor(n2(vs.Y * 0.46, 260, 420))
		optWrap.Size = UDim2.new(1, -20, 0, optH)
		optWrap.Position = UDim2.new(0, 10, 0, math.max(10, math.min(topH + 8, vs.Y - optH - 10)))
	else
		root.Size = UDim2.fromScale(0.96, 0.92)
		top.Size = UDim2.new(1, 0, 0, 64)
		main.Position = UDim2.new(0, 0, 0, 64)
		main.Size = UDim2.new(1, 0, 1, -64)
		title.Position = UDim2.new(0, 16, 0, 8)
		title.Size = UDim2.new(0, 220, 0, 24)
		sub.Position = UDim2.new(0, 16, 0, 34)
		sub.Size = UDim2.new(0, 260, 0, 16)
		stat.Position = UDim2.new(0, 290, 0, 18)
		stat.Size = UDim2.new(0, 220, 0, 18)
		topBar.Position = UDim2.new(1, -620, 0, 14)
		topBar.Size = UDim2.new(0, 604, 0, 36)
		box.Size = UDim2.fromOffset(n2(vs.X * 0.24, 260, 420), 36)
		bWear.Size = UDim2.fromOffset(82, 36)
		bSearch.Size = UDim2.fromOffset(48, 36)
		bOpts.Size = UDim2.fromOffset(48, 36)
		bClose.Size = UDim2.fromOffset(48, 36)
		local lw = math.floor(n2(vs.X * cfg.leftW, 260, 430))
		left.Position = UDim2.new(0, 0, 0, 0)
		left.Size = UDim2.new(0, lw, 1, 0)
		right.Position = UDim2.new(0, lw + 8, 0, 0)
		right.Size = UDim2.new(1, -(lw + 8), 1, 0)
		head.Position = UDim2.new(0, 0, 0, 0)
		head.Size = UDim2.new(1, 0, 0, 248)
		info.Position = UDim2.new(0, 0, 0, 254)
		info.Size = UDim2.new(1, 0, 1, -254)
		face.Size = UDim2.fromOffset(84, 84)
		face.Position = UDim2.new(0, 12, 0, 12)
		faceVp.Size = face.Size
		faceVp.Position = face.Position
		dn.Position = UDim2.new(0, 108, 0, 12)
		dn.Size = UDim2.new(1, -292, 0, 22)
		un.Position = UDim2.new(0, 108, 0, 38)
		un.Size = UDim2.new(1, -292, 0, 16)
		quick.Position = UDim2.new(0, 108, 0, 58)
		quick.Size = UDim2.new(1, -292, 0, 28)
		dnCopy.Size = UDim2.fromOffset(76, 28)
		unCopy.Size = UDim2.fromOffset(76, 28)
		dnCopy.Position = UDim2.new(1, -172, 0, 12)
		unCopy.Position = UDim2.new(1, -88, 0, 12)
		p2.Position = UDim2.new(0, 12, 0, 102)
		p2.Size = UDim2.new(0.28, -16, 1, -114)
		pv.Position = UDim2.new(0.28, 12, 0, 102)
		pv.Size = UDim2.new(0.72, -24, 1, -114)
		local optW = math.floor(n2(vs.X * 0.28, 280, 360))
		local optH = math.floor(n2(vs.Y * 0.62, 280, 430))
		optWrap.Size = UDim2.fromOffset(optW, optH)
		optWrap.Position = UDim2.new(1, -(optW + 12), 0, math.max(10, math.min(72, vs.Y - optH - 10)))
	end
	pv.Visible = cfg.show3d
end

con(dnCopy.MouseButton1Click, function()
	if clip and curProf then
		clip(tostring(curProf.displayName or curProf.name or ""))
		flash(dnCopy, theme.ok)
		notify("Copied display name")
	end
end)

con(unCopy.MouseButton1Click, function()
	if clip and curProf then
		clip(tostring(curProf.name or ""))
		flash(unCopy, theme.ok)
		notify("Copied username")
	end
end)

con(bSearch.MouseButton1Click, function()
	runSearch(box.Text)
end)

con(box.FocusLost, function(enter)
	if enter then
		runSearch(box.Text)
	end
end)

if box.ReturnPressedFromOnScreenKeyboard then
	con(box.ReturnPressedFromOnScreenKeyboard, function()
		runSearch(box.Text)
	end)
end


con(bOpts.MouseButton1Click, function()
	optWrap.Visible = not optWrap.Visible
	if optWrap.Visible then
		setZi(optWrap, 20)
	end
end)

con(bClose.MouseButton1Click, function()
	for _, c in ipairs(cons) do
		pcall(function()
			c:Disconnect()
		end)
	end
	tween(root, TweenInfo.new(0.12), {BackgroundTransparency = 1})
	tween(rootSt, TweenInfo.new(0.12), {Transparency = 1})
	task.wait(0.14)
	gui:Destroy()
end)

con(bWear.MouseButton1Click, function()
	if not curUid then
		notify("No user selected")
		return
	end
	local hum, ch = getHum()
	for _, cls in ipairs({"Shirt", "Pants", "ShirtGraphic"}) do
		for _, inst in ipairs(ch:GetChildren()) do
			if inst.ClassName == cls then
				inst:Destroy()
			end
		end
	end
	if curProf and curProf.isBanned == true then
		if not curAv then
			notify("No avatar data")
			return
		end
		local d = buildDesc(curAv)
		if hum.ApplyDescriptionClientServer then
			hum:ApplyDescriptionClientServer(d)
		else
			hum:ApplyDescription(d)
		end
	else
		local ok, d = pcall(Plrs.GetHumanoidDescriptionFromUserId, Plrs, curUid)
		if not ok or not d then
			notify("Failed to load avatar")
			return
		end
		if hum.ApplyDescriptionClientServer then
			hum:ApplyDescriptionClientServer(d)
		else
			hum:ApplyDescription(d)
		end
	end
	flash(bWear, theme.ok)
	notify("Applied once")
end)

do
	local dragOn = false
	local dragInp
	local startPos
	local startUd
	local function stopDrag()
		dragOn = false
		dragInp = nil
	end
	top.Active = true
	root.Active = true
	con(top.InputBegan, function(i)
		local t = i.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragOn = true
			dragInp = i
			startPos = i.Position
			startUd = root.Position
		end
	end)
	con(top.InputEnded, function(i)
		if i == dragInp or i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			stopDrag()
		end
	end)
	con(UIS.InputChanged, function(i)
		if not dragOn then
			return
		end
		if i == dragInp or i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			local d = i.Position - startPos
			root.Position = UDim2.new(startUd.X.Scale, startUd.X.Offset + d.X, startUd.Y.Scale, startUd.Y.Offset + d.Y)
		end
	end)
	con(UIS.InputEnded, function(i)
		if i == dragInp then
			stopDrag()
		end
	end)
end

local cam = workspace.CurrentCamera
if cam then
	con(cam:GetPropertyChangedSignal("ViewportSize"), layout)
end
layout()
root.BackgroundTransparency = 1
rootSt.Transparency = 1
tween(root, TweenInfo.new(0.18), {BackgroundTransparency = 0})
tween(rootSt, TweenInfo.new(0.18), {Transparency = 0.4})
notify("UI loaded")
