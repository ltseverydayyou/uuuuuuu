local c = {
	bg = Color3.fromRGB(12, 12, 18),
	sf = Color3.fromRGB(18, 18, 26),
	cd = Color3.fromRGB(24, 24, 34),
	bd = Color3.fromRGB(40, 42, 56),
	tx = Color3.fromRGB(238, 240, 250),
	t2 = Color3.fromRGB(150, 155, 178),
	t3 = Color3.fromRGB(90, 95, 115),
	bl = Color3.fromRGB(65, 130, 255),
	pr = Color3.fromRGB(140, 95, 255),
	gn = Color3.fromRGB(45, 210, 95),
	am = Color3.fromRGB(255, 188, 55),
	rd = Color3.fromRGB(235, 60, 65),
	wh = Color3.fromRGB(255, 255, 255),
	bk = Color3.fromRGB(0, 0, 0),
}

local function CS(name)
	local ref = cloneref or function(r) return r end
	return ref(game:GetService(name))
end

local TS = CS("TweenService")
local TXS = CS("TextService")
local HS = CS("HttpService")
local UIS = CS("UserInputService")
local MPS = CS("MarketplaceService")

local function lerp(a, b, t)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

local function tw(obj, dur, props, style, dir)
	local t = TS:Create(obj, TweenInfo.new(dur, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function twBounce(obj, dur, props)
	return tw(obj, dur, props, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function protectUI(sg)
	if sg:IsA("ScreenGui") then
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
		sg.DisplayOrder = 2147483647
		sg.ResetOnSpawn = false
		sg.IgnoreGuiInset = true
	end
	local cg = CS("CoreGui")
	local lp = CS("Players").LocalPlayer
	local function h(i) if i then i.Name = "\000" i.Archivable = false end end
	if gethui then h(sg) sg.Parent = gethui() return sg
	elseif cg and cg:FindFirstChild("RobloxGui") then h(sg) sg.Parent = cg:FindFirstChild("RobloxGui") return sg
	elseif cg then h(sg) sg.Parent = cg return sg
	elseif lp and lp:FindFirstChildWhichIsA("PlayerGui") then h(sg) sg.Parent = lp:FindFirstChildWhichIsA("PlayerGui") sg.ResetOnSpawn = false return sg
	end
end

local function makeDrag(frame, handle)
	handle = handle or frame
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
			local d = input.Position - dragStart
			local s = frame.Parent.AbsoluteSize
			frame.Position = UDim2.new(math.clamp(startPos.X.Scale + (startPos.X.Offset + d.X) / s.X, 0, 1), 0, math.clamp(startPos.Y.Scale + (startPos.Y.Offset + d.Y) / s.Y, 0, 1), 0)
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			local s = frame.Parent.AbsoluteSize
			frame.Position = UDim2.new(math.clamp(startPos.X.Scale + (startPos.X.Offset + d.X) / s.X, 0, 1), 0, math.clamp(startPos.Y.Scale + (startPos.Y.Offset + d.Y) / s.Y, 0, 1), 0)
		end
	end)
	frame.Active = true
end

local function ripple(btn, col)
	btn.ClipsDescendants = true
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local rel = Vector2.new(input.Position.X - btn.AbsolutePosition.X, input.Position.Y - btn.AbsolutePosition.Y)
			local ci = Instance.new("Frame")
			ci.BackgroundColor3 = col or c.wh
			ci.BackgroundTransparency = 0.65
			ci.AnchorPoint = Vector2.new(0.5, 0.5)
			ci.Position = UDim2.fromOffset(rel.X, rel.Y)
			ci.Size = UDim2.fromOffset(0, 0)
			ci.ZIndex = 10
			ci.Parent = btn
			Instance.new("UICorner", ci).CornerRadius = UDim.new(1, 0)
			local d = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.8
			tw(ci, 0.5, {Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1}, Enum.EasingStyle.Quad)
			task.delay(0.55, function() ci:Destroy() end)
		end
	end)
end

local function pulseOnce(obj, prop, val1, val2, dur)
	tw(obj, dur * 0.5, {[prop] = val1}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	task.delay(dur * 0.5, function()
		tw(obj, dur * 0.5, {[prop] = val2}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end)
end

local req = syn and syn.request or request or http_request or (http and http.request) or (fluxus and fluxus.request) or (krnl and krnl.request) or krnl_request
local function jget(url)
	if req then
		local ok, r = pcall(function()
			return req({Url = url, Method = "GET", Headers = {Accept = "application/json", ["Cache-Control"] = "no-cache", ["User-Agent"] = "Roblox-Client"}})
		end)
		if not ok or not r or (r.StatusCode ~= 200 and r.StatusCode ~= 201) then return nil end
		local ok2, data = pcall(HS.JSONDecode, HS, r.Body)
		return ok2 and data or nil
	else
		local ok, res = pcall(HS.GetAsync, HS, url, true)
		if not ok or type(res) ~= "string" then return nil end
		local ok2, data = pcall(HS.JSONDecode, HS, res)
		return ok2 and data or nil
	end
end

local sg = Instance.new("ScreenGui")
sg.Name = "\000"
protectUI(sg)

local root = Instance.new("Frame")
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromScale(0.5, 0.6)
root.BackgroundColor3 = c.bg
root.BorderSizePixel = 0
root.ClipsDescendants = true
root.Parent = sg
Instance.new("UICorner", root).CornerRadius = UDim.new(0, 14)

local rootStroke = Instance.new("UIStroke")
rootStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
rootStroke.Color = c.bd
rootStroke.Transparency = 0.5
rootStroke.Thickness = 1
rootStroke.Parent = root

local glow = Instance.new("ImageLabel")
glow.BackgroundTransparency = 1
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.Position = UDim2.fromScale(0.5, 0.5)
glow.Size = UDim2.new(1, 70, 1, 70)
glow.Image = "rbxassetid://6014261993"
glow.ImageColor3 = c.bk
glow.ImageTransparency = 0.4
glow.ScaleType = Enum.ScaleType.Slice
glow.SliceCenter = Rect.new(49, 49, 450, 450)
glow.ZIndex = -1
glow.Parent = root

local topbar = Instance.new("Frame")
topbar.Size = UDim2.new(1, 0, 0, 46)
topbar.BackgroundColor3 = c.sf
topbar.BorderSizePixel = 0
topbar.Parent = root
Instance.new("UICorner", topbar).CornerRadius = UDim.new(0, 14)

local topMask = Instance.new("Frame")
topMask.Size = UDim2.new(1, 0, 0, 14)
topMask.Position = UDim2.new(0, 0, 1, -14)
topMask.BackgroundColor3 = c.sf
topMask.BorderSizePixel = 0
topMask.Parent = topbar

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(1, 0, 0, 2)
accentBar.Position = UDim2.new(0, 0, 1, -2)
accentBar.BorderSizePixel = 0
accentBar.BackgroundColor3 = c.bl
accentBar.Parent = topbar

local accentGrad = Instance.new("UIGradient")
accentGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, lerp(c.bl, c.pr, 0.6)),
	ColorSequenceKeypoint.new(0.5, c.bl),
	ColorSequenceKeypoint.new(1, lerp(c.bl, c.pr, 0.6)),
})
accentGrad.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.4),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 0.4),
})
accentGrad.Parent = accentBar

local shimmerOffset = 0
task.spawn(function()
	while sg.Parent do
		shimmerOffset = (shimmerOffset + 0.003) % 1
		accentGrad.Offset = Vector2.new(shimmerOffset, 0)
		task.wait()
	end
end)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0, 16, 0, 0)
title.Size = UDim2.new(1, -150, 1, 0)
title.Font = Enum.Font.GothamBold
title.Text = "Game Info"
title.TextSize = 15
title.TextColor3 = c.tx
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topbar

local ctrlFrame = Instance.new("Frame")
ctrlFrame.BackgroundTransparency = 1
ctrlFrame.Size = UDim2.new(0, 110, 1, 0)
ctrlFrame.Position = UDim2.new(1, -118, 0, 0)
ctrlFrame.Parent = topbar

local ctrlLayout = Instance.new("UIListLayout")
ctrlLayout.FillDirection = Enum.FillDirection.Horizontal
ctrlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
ctrlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
ctrlLayout.Padding = UDim.new(0, 5)
ctrlLayout.Parent = ctrlFrame

local function makeBtn(txt, col)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.Size = UDim2.fromOffset(28, 28)
	b.BackgroundColor3 = lerp(col, c.bg, 0.75)
	b.Font = Enum.Font.GothamBold
	b.Text = txt
	b.TextSize = 12
	b.TextColor3 = col
	b.Parent = ctrlFrame
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
	local st = Instance.new("UIStroke")
	st.Color = lerp(col, c.bg, 0.5)
	st.Transparency = 0.65
	st.Thickness = 1
	st.Parent = b
	b.MouseEnter:Connect(function()
		tw(b, 0.15, {BackgroundColor3 = lerp(col, c.bg, 0.4)})
		tw(st, 0.15, {Transparency = 0.3})
		twBounce(b, 0.2, {Size = UDim2.fromOffset(30, 30)})
	end)
	b.MouseLeave:Connect(function()
		tw(b, 0.15, {BackgroundColor3 = lerp(col, c.bg, 0.75)})
		tw(st, 0.15, {Transparency = 0.65})
		tw(b, 0.15, {Size = UDim2.fromOffset(28, 28)})
	end)
	ripple(b, col)
	return b
end

local btnRefresh = makeBtn("R", c.bl)
local btnMin = makeBtn("-", c.am)
local btnClose = makeBtn("X", c.rd)

local HEADER_H = 100
local header = Instance.new("Frame")
header.BackgroundTransparency = 1
header.ClipsDescendants = true
header.Position = UDim2.new(0, 0, 0, 46)
header.Size = UDim2.new(1, 0, 0, HEADER_H)
header.Parent = root

local headerBg = Instance.new("Frame")
headerBg.Size = UDim2.fromScale(1, 1)
headerBg.BackgroundColor3 = c.sf
headerBg.BackgroundTransparency = 0.6
headerBg.BorderSizePixel = 0
headerBg.Parent = header
local hGrad = Instance.new("UIGradient")
hGrad.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1)})
hGrad.Rotation = 90
hGrad.Parent = headerBg

local iconHolder = Instance.new("Frame")
iconHolder.BackgroundColor3 = c.cd
iconHolder.Size = UDim2.fromOffset(68, 68)
iconHolder.Position = UDim2.new(0, 20, 0.5, -34)
iconHolder.BorderSizePixel = 0
iconHolder.Parent = header
Instance.new("UICorner", iconHolder).CornerRadius = UDim.new(0, 12)
local iconStroke = Instance.new("UIStroke")
iconStroke.Color = c.bd
iconStroke.Transparency = 0.4
iconStroke.Thickness = 1
iconStroke.Parent = iconHolder

local gIcon = Instance.new("ImageLabel")
gIcon.BackgroundTransparency = 1
gIcon.Size = UDim2.fromScale(1, 1)
gIcon.Image = "rbxassetid://0"
gIcon.ScaleType = Enum.ScaleType.Crop
gIcon.Parent = iconHolder
Instance.new("UICorner", gIcon).CornerRadius = UDim.new(0, 12)

local gName = Instance.new("TextLabel")
gName.BackgroundTransparency = 1
gName.Position = UDim2.new(0, 102, 0, 14)
gName.Size = UDim2.new(1, -120, 0, 26)
gName.Font = Enum.Font.GothamBold
gName.Text = "Loading..."
gName.TextSize = 18
gName.TextColor3 = c.tx
gName.TextXAlignment = Enum.TextXAlignment.Left
gName.TextTruncate = Enum.TextTruncate.AtEnd
gName.Parent = header

local gOwner = Instance.new("TextLabel")
gOwner.BackgroundTransparency = 1
gOwner.Position = UDim2.new(0, 102, 0, 42)
gOwner.Size = UDim2.new(1, -120, 0, 20)
gOwner.Font = Enum.Font.Gotham
gOwner.Text = ""
gOwner.TextSize = 13
gOwner.TextColor3 = c.t2
gOwner.TextXAlignment = Enum.TextXAlignment.Left
gOwner.Parent = header

local badge = Instance.new("Frame")
badge.BackgroundColor3 = c.bl
badge.BackgroundTransparency = 0.82
badge.Size = UDim2.fromOffset(0, 0)
badge.Position = UDim2.new(0, 102, 0, 66)
badge.BorderSizePixel = 0
badge.AutomaticSize = Enum.AutomaticSize.XY
badge.Visible = false
badge.Parent = header
Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 5)
local bPad = Instance.new("UIPadding")
bPad.PaddingLeft = UDim.new(0, 7)
bPad.PaddingRight = UDim.new(0, 7)
bPad.PaddingTop = UDim.new(0, 2)
bPad.PaddingBottom = UDim.new(0, 2)
bPad.Parent = badge

local badgeLbl = Instance.new("TextLabel")
badgeLbl.BackgroundTransparency = 1
badgeLbl.Font = Enum.Font.GothamBold
badgeLbl.TextSize = 10
badgeLbl.TextColor3 = c.bl
badgeLbl.Text = ""
badgeLbl.AutomaticSize = Enum.AutomaticSize.XY
badgeLbl.Parent = badge

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -40, 0, 1)
divider.Position = UDim2.new(0, 20, 1, -1)
divider.BackgroundColor3 = c.bd
divider.BackgroundTransparency = 0.55
divider.BorderSizePixel = 0
divider.Parent = header

local CONTENT_Y = 46 + HEADER_H
local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 0, 0, CONTENT_Y)
content.Size = UDim2.new(1, 0, 1, -CONTENT_Y)
content.Parent = root

local scroll = Instance.new("ScrollingFrame")
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.Size = UDim2.fromScale(1, 1)
scroll.CanvasSize = UDim2.new()
scroll.ScrollBarThickness = 3
scroll.ScrollBarImageColor3 = lerp(c.bl, c.wh, 0.15)
scroll.ScrollBarImageTransparency = 0.35
scroll.TopImage = "rbxassetid://7857296138"
scroll.MidImage = "rbxassetid://7857296138"
scroll.BottomImage = "rbxassetid://7857296138"
scroll.Parent = content

local sPad = Instance.new("UIPadding")
sPad.PaddingLeft = UDim.new(0, 16)
sPad.PaddingRight = UDim.new(0, 16)
sPad.PaddingTop = UDim.new(0, 10)
sPad.PaddingBottom = UDim.new(0, 14)
sPad.Parent = scroll

local sLayout = Instance.new("UIListLayout")
sLayout.SortOrder = Enum.SortOrder.LayoutOrder
sLayout.Padding = UDim.new(0, 6)
sLayout.Parent = scroll

sLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, sLayout.AbsoluteContentSize.Y + sPad.PaddingTop.Offset + sPad.PaddingBottom.Offset)
end)

local accent = c.bl

local function makeCard(h)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = c.cd
	f.Size = UDim2.new(1, 0, 0, h)
	f.BorderSizePixel = 0
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
	local st = Instance.new("UIStroke")
	st.Color = lerp(accent, c.bg, 0.6)
	st.Transparency = 0.5
	st.Thickness = 1
	st.Parent = f
	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(0, 3, 1, -10)
	bar.Position = UDim2.new(0, 0, 0, 5)
	bar.BackgroundColor3 = accent
	bar.BackgroundTransparency = 0.4
	bar.BorderSizePixel = 0
	bar.Parent = f
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
	return f
end

local function autoH(row, kL, vL, ls)
	local w = row.AbsoluteSize.X - 26
	if w <= 0 then return end
	local lw = math.floor(w * ls)
	local rw = w - lw - 10
	local kh = TXS:GetTextSize(kL.Text, kL.TextSize, kL.Font, Vector2.new(lw, 1e6)).Y
	local vh = TXS:GetTextSize(vL.Text, vL.TextSize, vL.Font, Vector2.new(rw, 1e6)).Y
	row.Size = UDim2.new(1, 0, 0, math.max(kh, vh) + 14)
end

local rowIndex = 0

local function addRow(k, v, order)
	rowIndex += 1
	local idx = rowIndex
	local row = makeCard(38)
	row.LayoutOrder = order or 0
	row.Parent = scroll
	row.Visible = false

	local inner = Instance.new("Frame")
	inner.BackgroundTransparency = 1
	inner.Position = UDim2.new(0, 13, 0, 7)
	inner.Size = UDim2.new(1, -26, 1, -14)
	inner.Parent = row

	local hl = Instance.new("UIListLayout")
	hl.FillDirection = Enum.FillDirection.Horizontal
	hl.Padding = UDim.new(0, 10)
	hl.Parent = inner

	local kL = Instance.new("TextLabel")
	kL.BackgroundTransparency = 1
	kL.Size = UDim2.new(0.3, 0, 1, 0)
	kL.Font = Enum.Font.GothamMedium
	kL.Text = tostring(k)
	kL.TextSize = 12
	kL.TextColor3 = c.t2
	kL.TextXAlignment = Enum.TextXAlignment.Left
	kL.TextWrapped = true
	kL.Parent = inner

	local vL = Instance.new("TextLabel")
	vL.BackgroundTransparency = 1
	vL.Size = UDim2.new(0.7, 0, 1, 0)
	vL.Font = Enum.Font.Gotham
	vL.Text = typeof(v) == "table" and HS:JSONEncode(v) or tostring(v)
	vL.TextSize = 12
	vL.TextColor3 = c.tx
	vL.TextXAlignment = Enum.TextXAlignment.Left
	vL.TextWrapped = true
	vL.Parent = inner

	row.MouseEnter:Connect(function()
		tw(row, 0.15, {BackgroundColor3 = lerp(c.cd, c.wh, 0.03)})
	end)
	row.MouseLeave:Connect(function()
		tw(row, 0.15, {BackgroundColor3 = c.cd})
	end)

	task.defer(function()
		autoH(row, kL, vL, 0.3)
		local function rc() autoH(row, kL, vL, 0.3) end
		row:GetPropertyChangedSignal("AbsoluteSize"):Connect(rc)
		kL:GetPropertyChangedSignal("Text"):Connect(rc)
		vL:GetPropertyChangedSignal("Text"):Connect(rc)

		task.wait(idx * 0.035)
		row.Visible = true
		row.BackgroundTransparency = 1
		row.Position = UDim2.new(0, -25, 0, 0)
		tw(row, 0.35, {BackgroundTransparency = 0})
		tw(row, 0.45, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
	end)
end

local function addDropdown(titleText, tbl, order)
	rowIndex += 1
	local idx = rowIndex
	local container = makeCard(46)
	container.LayoutOrder = order or 100
	container.Parent = scroll

	local hRow = Instance.new("Frame")
	hRow.BackgroundTransparency = 1
	hRow.Position = UDim2.new(0, 13, 0, 0)
	hRow.Size = UDim2.new(1, -26, 0, 46)
	hRow.Parent = container

	local hLabel = Instance.new("TextLabel")
	hLabel.BackgroundTransparency = 1
	hLabel.Size = UDim2.new(1, -36, 1, 0)
	hLabel.Font = Enum.Font.GothamMedium
	hLabel.Text = titleText
	hLabel.TextSize = 13
	hLabel.TextColor3 = c.tx
	hLabel.TextXAlignment = Enum.TextXAlignment.Left
	hLabel.Parent = hRow

	local arrow = Instance.new("TextLabel")
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromOffset(20, 20)
	arrow.Position = UDim2.new(1, -20, 0.5, -10)
	arrow.Font = Enum.Font.GothamBold
	arrow.Text = "+"
	arrow.TextSize = 16
	arrow.TextColor3 = c.t3
	arrow.Parent = hRow

	local clickArea = Instance.new("TextButton")
	clickArea.BackgroundTransparency = 1
	clickArea.Size = UDim2.fromScale(1, 1)
	clickArea.Text = ""
	clickArea.Parent = hRow

	local sub = Instance.new("Frame")
	sub.BackgroundTransparency = 1
	sub.ClipsDescendants = true
	sub.Position = UDim2.new(0, 13, 0, 46)
	sub.Size = UDim2.new(1, -26, 0, 0)
	sub.Parent = container

	local subL = Instance.new("UIListLayout")
	subL.SortOrder = Enum.SortOrder.LayoutOrder
	subL.Padding = UDim.new(0, 5)
	subL.Parent = sub

	local expanded = false

	local function subRow(parent, k, v)
		local r = Instance.new("Frame")
		r.BackgroundTransparency = 1
		r.Size = UDim2.new(1, 0, 0, 20)
		r.Parent = parent

		local rl = Instance.new("UIListLayout")
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.Padding = UDim.new(0, 10)
		rl.Parent = r

		local kL = Instance.new("TextLabel")
		kL.BackgroundTransparency = 1
		kL.Size = UDim2.new(0.3, 0, 1, 0)
		kL.Font = Enum.Font.Gotham
		kL.Text = tostring(k)
		kL.TextSize = 11
		kL.TextColor3 = c.t3
		kL.TextXAlignment = Enum.TextXAlignment.Left
		kL.TextWrapped = true
		kL.Parent = r

		local vL = Instance.new("TextLabel")
		vL.BackgroundTransparency = 1
		vL.Size = UDim2.new(0.7, 0, 1, 0)
		vL.Font = Enum.Font.Gotham
		vL.TextSize = 11
		vL.TextColor3 = c.tx
		vL.TextXAlignment = Enum.TextXAlignment.Left
		vL.TextWrapped = true
		vL.Parent = r

		if typeof(v) == "table" then
			local n, isArr, maxk = 0, true, 0
			for kk in pairs(v) do n += 1 if typeof(kk) ~= "number" then isArr = false elseif kk > maxk then maxk = kk end end
			if n == 0 then return end
			if isArr and maxk == n then
				local p = {} for i = 1, #v do p[i] = tostring(v[i]) end
				vL.Text = table.concat(p, ", ")
			else
				vL.Text = HS:JSONEncode(v)
			end
		else
			vL.Text = tostring(v)
		end

		task.defer(function()
			autoH(r, kL, vL, 0.3)
			local function rc() autoH(r, kL, vL, 0.3) end
			r:GetPropertyChangedSignal("AbsoluteSize"):Connect(rc)
			kL:GetPropertyChangedSignal("Text"):Connect(rc)
			vL:GetPropertyChangedSignal("Text"):Connect(rc)
		end)
	end

	local function rebuild()
		for _, ch in ipairs(sub:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
		local keys = {}
		for k in pairs(tbl) do table.insert(keys, k) end
		table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
		for _, k in ipairs(keys) do subRow(sub, k, tbl[k]) end
		task.defer(function()
			local h = subL.AbsoluteContentSize.Y + 8
			tw(sub, 0.3, {Size = UDim2.new(1, -26, 0, h)}, Enum.EasingStyle.Back)
			tw(container, 0.3, {Size = UDim2.new(1, 0, 0, 46 + h)}, Enum.EasingStyle.Back)
		end)
	end

	clickArea.MouseButton1Click:Connect(function()
		expanded = not expanded
		if expanded then
			tw(arrow, 0.2, {Rotation = 45, TextColor3 = accent})
			rebuild()
		else
			tw(arrow, 0.2, {Rotation = 0, TextColor3 = c.t3})
			tw(sub, 0.25, {Size = UDim2.new(1, -26, 0, 0)})
			tw(container, 0.25, {Size = UDim2.new(1, 0, 0, 46)})
		end
	end)

	container.MouseEnter:Connect(function()
		tw(container, 0.15, {BackgroundColor3 = lerp(c.cd, c.wh, 0.025)})
	end)
	container.MouseLeave:Connect(function()
		tw(container, 0.15, {BackgroundColor3 = c.cd})
	end)

	task.defer(function()
		task.wait(idx * 0.035)
		container.BackgroundTransparency = 1
		container.Position = UDim2.new(0, -25, 0, 0)
		tw(container, 0.35, {BackgroundTransparency = 0})
		tw(container, 0.45, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back)
	end)
end

local function clearBody()
	rowIndex = 0
	for _, ch in ipairs(scroll:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end
end

local function applyAccent(col)
	accent = col
	tw(accentBar, 0.4, {BackgroundColor3 = col})
	accentGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, lerp(col, c.pr, 0.5)),
		ColorSequenceKeypoint.new(0.5, col),
		ColorSequenceKeypoint.new(1, lerp(col, c.pr, 0.5)),
	})
	tw(rootStroke, 0.4, {Color = lerp(col, c.bg, 0.6)})
	tw(iconStroke, 0.4, {Color = lerp(col, c.bg, 0.45)})
	tw(divider, 0.4, {BackgroundColor3 = lerp(col, c.bd, 0.5)})
	scroll.ScrollBarImageColor3 = lerp(col, c.wh, 0.15)
	headerBg.BackgroundColor3 = lerp(col, c.bg, 0.9)
end

local function displayGameInfo()
	clearBody()

	gName.Text = "Loading..."
	gOwner.Text = ""
	badge.Visible = false

	local loadDots = 0
	local loading = true
	task.spawn(function()
		while loading and sg.Parent do
			loadDots = (loadDots % 3) + 1
			gName.Text = "Loading" .. string.rep(".", loadDots)
			task.wait(0.35)
		end
	end)

	local universeId = tostring(game.GameId)
	local placeId = game.PlaceId

	local gi
	do
		local ok, res = pcall(MPS.GetProductInfo, MPS, placeId)
		if ok and typeof(res) == "table" then gi = res end
	end

	if gi and gi.IconImageAssetId and gi.IconImageAssetId > 0 then
		gIcon.Image = "https://assetgame.roblox.com/Game/Tools/ThumbnailAsset.ashx?aid=" .. tostring(gi.IconImageAssetId) .. "&fmt=png&wd=420&ht=420"
		iconHolder.BackgroundTransparency = 1
		tw(iconHolder, 0.3, {BackgroundTransparency = 0})
		twBounce(iconHolder, 0.35, {Size = UDim2.fromOffset(68, 68)})
	end

	local gjson = jget("https://games.roproxy.com/v1/games?universeIds=" .. universeId)
	local gdata = gjson and gjson.data and gjson.data[1]

	loading = false

	local name = (gdata and gdata.name) or (gi and gi.Name) or "Experience"
	gName.Text = name
	gName.TextTransparency = 1
	tw(gName, 0.3, {TextTransparency = 0})

	local creator = gdata and gdata.creator or {}
	local cType = (tostring(creator.type or (gi and gi.Creator and gi.Creator.CreatorType) or "")):lower()
	local cName = tostring(creator.name or (gi and gi.Creator and gi.Creator.Name) or "Unknown")
	gOwner.Text = cName
	gOwner.TextTransparency = 1
	tw(gOwner, 0.35, {TextTransparency = 0})

	if cType == "group" then
		applyAccent(c.pr)
		badgeLbl.Text = "GROUP"
		badgeLbl.TextColor3 = c.pr
		badge.BackgroundColor3 = c.pr
	else
		applyAccent(c.bl)
		badgeLbl.Text = "USER"
		badgeLbl.TextColor3 = c.bl
		badge.BackgroundColor3 = c.bl
	end
	badge.Visible = true
	badge.BackgroundTransparency = 1
	tw(badge, 0.3, {BackgroundTransparency = 0.82})

	local seen = {}
	local order = 0

	local function stringify(v)
		if typeof(v) == "table" then
			local n, isArr, maxk = 0, true, 0
			for kk in pairs(v) do n += 1 if typeof(kk) ~= "number" then isArr = false elseif kk > maxk then maxk = kk end end
			if n == 0 then return nil end
			if isArr and maxk == n then
				local p = {} for i = 1, #v do p[i] = tostring(v[i]) end
				return table.concat(p, ", ")
			end
			return HS:JSONEncode(v)
		end
		return v
	end

	local function addKV(k, v)
		if v == nil or (typeof(v) == "string" and v == "") then return end
		local low = string.lower(k)
		if seen[low] then return end
		local sv = stringify(v)
		if sv == nil then return end
		order += 1
		addRow(k, sv, order)
		seen[low] = true
	end

	if gdata then
		for k, v in pairs(gdata) do
			if k ~= "creator" then addKV(k, v) end
		end
	end
	if gi then
		for k, v in pairs(gi) do
			if k ~= "Creator" and k ~= "ProductId" then addKV(k, v) end
		end
	end

	order += 1
	local cdrop = {}
	if creator then for ck, cv in pairs(creator) do cdrop[ck] = cv end end
	if next(cdrop) == nil and gi and typeof(gi.Creator) == "table" then
		for ck, cv in pairs(gi.Creator) do cdrop[ck] = cv end
	end
	if next(cdrop) then addDropdown("Creator Details", cdrop, order) end

	local vjson = jget("https://games.roproxy.com/v1/games/votes?universeIds=" .. universeId)
	local votes = vjson and vjson.data and vjson.data[1]
	if votes then
		local up, down = votes.upVotes or 0, votes.downVotes or 0
		local total = up + down
		local ratio = total > 0 and math.floor(up / total * 1000) / 10 or 0
		order += 1
		addDropdown("Votes", {upVotes = up, downVotes = down, total = total, likePercent = ratio}, order)
	end

	local socials = jget("https://games.roproxy.com/v1/games/" .. universeId .. "/social-links/list")
	if socials and socials.data and #socials.data > 0 then
		local stbl = {}
		for _, s in ipairs(socials.data) do
			stbl[(s.type or "Link") .. " (" .. (s.title or "") .. ")"] = s.url or ""
		end
		order += 1
		addDropdown("Social Links", stbl, order)
	end
end

local originalSize = root.Size
local minimized = false

btnMin.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		tw(iconHolder, 0.15, {Size = UDim2.fromOffset(0, 0)})
		tw(gName, 0.1, {TextTransparency = 1})
		tw(gOwner, 0.1, {TextTransparency = 1})
		tw(badge, 0.1, {BackgroundTransparency = 1})
		tw(btnMin, 0.25, {Rotation = 180})
		task.wait(0.1)
		header.Visible = false
		badge.Visible = false
		tw(content, 0.2, {Size = UDim2.new(1, 0, 0, 0)})
		tw(root, 0.25, {Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 46)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	else
		header.Visible = true
		badge.Visible = true
		twBounce(root, 0.35, {Size = originalSize})
		tw(content, 0.3, {Size = UDim2.new(1, 0, 1, -CONTENT_Y)})
		twBounce(iconHolder, 0.3, {Size = UDim2.fromOffset(68, 68)})
		tw(gName, 0.25, {TextTransparency = 0})
		tw(gOwner, 0.25, {TextTransparency = 0})
		tw(badge, 0.25, {BackgroundTransparency = 0.82})
		tw(btnMin, 0.25, {Rotation = 0})
	end
end)

btnClose.MouseButton1Click:Connect(function()
	tw(root, 0.18, {Size = UDim2.new(originalSize.X.Scale - 0.02, 0, originalSize.Y.Scale - 0.02, 0), BackgroundTransparency = 1})
	tw(rootStroke, 0.15, {Transparency = 1})
	tw(glow, 0.15, {ImageTransparency = 1})
	task.wait(0.2)
	sg:Destroy()
end)

btnRefresh.MouseButton1Click:Connect(function()
	tw(btnRefresh, 0.5, {Rotation = btnRefresh.Rotation + 360}, Enum.EasingStyle.Cubic)
	pulseOnce(accentBar, "BackgroundTransparency", 0.5, 0, 0.4)
	task.defer(displayGameInfo)
end)

makeDrag(root, topbar)

root.BackgroundTransparency = 1
rootStroke.Transparency = 1
glow.ImageTransparency = 1
title.TextTransparency = 1
root.Size = UDim2.new(originalSize.X.Scale - 0.04, 0, originalSize.Y.Scale - 0.04, 0)

task.wait(0.05)
twBounce(root, 0.45, {Size = originalSize, BackgroundTransparency = 0})
tw(rootStroke, 0.35, {Transparency = 0.5})
tw(glow, 0.5, {ImageTransparency = 0.4})
tw(title, 0.4, {TextTransparency = 0})

displayGameInfo()
