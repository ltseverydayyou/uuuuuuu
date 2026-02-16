local plr = game:GetService("Players")
local uis = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local lp = plr.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

local function ref(x)
	if cloneref then
		local ok, v = pcall(cloneref, x)
		if ok and v then return v end
	end
	return x
end

local function getPar()
	local ok, ui = pcall(function()
		if gethui then
			return ref(gethui())
		end
	end)
	if ok and ui then return ui end

	local cg = game:GetService("CoreGui")
	local rg = cg:FindFirstChild("RobloxGui")
	if rg then return rg end
	if cg then return ref(cg) end

	local pgui = lp:FindFirstChildOfClass("PlayerGui")
	if pgui then return pgui end
	return pg
end

local par = getPar()
local nm = "ImgScanGui"
local old = par:FindFirstChild(nm)
if old then pcall(function() old:Destroy() end) end

local con = {}
local function on(c)
	con[#con+1] = c
	return c
end
local function off()
	for i = #con, 1, -1 do
		local c = con[i]
		con[i] = nil
		pcall(function() c:Disconnect() end)
	end
end

local data = {}
local seen = {}
local onNewAsset
local statusLabel

local function resetData()
	table.clear(data)
	table.clear(seen)
end

local function norm(s)
	s = tostring(s or "")
	s = s:gsub("%s+", "")
	return s
end

local function addRes(src, inst, prop)
	if seen[src] then return end
	seen[src] = true
	local it = { src = src, inst = inst, prop = prop }
	data[#data+1] = it
	if onNewAsset then onNewAsset(it) end
end

local function findIds(s, inst, prop)
	s = tostring(s or "")
	local n = norm(s)

	for id in n:gmatch("rbxassetid://(%d+)") do
		addRes("rbxassetid://" .. id, inst, prop)
	end
	for pth in n:gmatch("rbxasset://([^%?%#]+)") do
		addRes("rbxasset://" .. pth, inst, prop)
	end
	for id in n:gmatch("https?://www%.roblox%.com/asset/%?id=(%d+)") do
		addRes("rbxassetid://" .. id, inst, prop)
	end
	for id in n:gmatch("https?://assetdelivery%.roblox%.com/v1/asset/%?id=(%d+)") do
		addRes("rbxassetid://" .. id, inst, prop)
	end
	for id in n:gmatch("https?://assetdelivery%.roblox%.com/v1/assetId/(%d+)") do
		addRes("rbxassetid://" .. id, inst, prop)
	end
	for id in n:gmatch("id=(%d+)") do
		if s:find("roblox%.com") or s:find("assetdelivery%.roblox%.com") then
			addRes("rbxassetid://" .. id, inst, prop)
		end
	end
end

local props = {"Image","Texture","TextureId","TextureID","Graphic","Thumbnail","Icon","NormalMap","ColorMap","MetalnessMap","RoughnessMap","AmbientOcclusionMap","EmissionMap","HeightMap","AlphaMap"}

local clsProps = {
	ImageLabel = {"Image"}, ImageButton = {"Image"},
	Decal = {"Texture"}, Texture = {"Texture"},
	ParticleEmitter = {"Texture"}, Beam = {"Texture"}, Trail = {"Texture"},
	Sky = {"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp","SunTextureId","MoonTextureId"},
	SurfaceAppearance = {"ColorMap","NormalMap","MetalnessMap","RoughnessMap"},
	MeshPart = {"TextureID"}, SpecialMesh = {"TextureId","MeshId"},
	ShirtGraphic = {"Graphic"},
	MaterialVariant = {"ColorMap","NormalMap","MetalnessMap","RoughnessMap"},
}

local function scanInst(inst)
	local cn = inst.ClassName
	local p = clsProps[cn]
	if p then
		for _, nm2 in ipairs(p) do
			local ok, v = pcall(function() return inst[nm2] end)
			if ok and v ~= nil then findIds(v, inst, nm2) end
		end
	end
	for _, nm2 in ipairs(props) do
		local ok, v = pcall(function() return inst[nm2] end)
		if ok and v ~= nil then findIds(v, inst, nm2) end
	end
	local okA, at = pcall(function() return inst:GetAttributes() end)
	if okA and type(at) == "table" then
		for k, v in pairs(at) do
			if type(v) == "string" then findIds(v, inst, "Attr:" .. tostring(k)) end
		end
	end
end

local scanning = false

local function scanAsync(onDone)
	if scanning then return end
	scanning = true
	task.spawn(function()
		local list = game:GetDescendants()
		table.insert(list, 1, game)
		local n = #list
		for i = 1, n do
			scanInst(list[i])
			if i % 180 == 0 then
				if statusLabel then statusLabel.Text = ("Scanning... %d/%d • %d images"):format(i, n, #data) end
				task.wait()
			end
		end
		if statusLabel then statusLabel.Text = ("Done • %d images found"):format(#data) end
		scanning = false
		onNewAsset = nil
		if onDone then onDone() end
	end)
end

local gui = Instance.new("ScreenGui")
gui.Name = nm
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = par end)
on(gui.AncestryChanged:Connect(function(_, p) if not p then off() end end))

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(760, 500)
root.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
root.BackgroundTransparency = 0
root.BorderSizePixel = 0
root.Parent = gui
root.Active = true
root.ClipsDescendants = true
root.Draggable = true

local rootCorner = Instance.new("UICorner")
rootCorner.CornerRadius = UDim.new(0, 14)
rootCorner.Parent = root

local rootStroke = Instance.new("UIStroke")
rootStroke.Thickness = 2
rootStroke.Color = Color3.fromRGB(255, 255, 255)
rootStroke.Transparency = 0.75
rootStroke.Parent = root

local sc = Instance.new("UIScale")
sc.Scale = 0.85
sc.Parent = root

local top = Instance.new("Frame")
top.Size = UDim2.new(1, 0, 0, 52)
top.BackgroundColor3 = Color3.fromRGB(13, 13, 19)
top.BorderSizePixel = 0
top.Parent = root

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 14)
topCorner.Parent = top

local topMask = Instance.new("Frame")
topMask.Size = UDim2.new(1, 0, 0, 14)
topMask.Position = UDim2.new(0, 0, 1, -14)
topMask.BackgroundColor3 = top.BackgroundColor3
topMask.BorderSizePixel = 0
topMask.Parent = top

local ttl = Instance.new("TextLabel")
ttl.BackgroundTransparency = 1
ttl.Position = UDim2.new(0, 18, 0, 0)
ttl.Size = UDim2.new(1, -160, 1, 0)
ttl.Font = Enum.Font.GothamSemibold
ttl.TextSize = 17
ttl.TextXAlignment = Enum.TextXAlignment.Left
ttl.TextColor3 = Color3.fromRGB(240, 240, 245)
ttl.Text = "Image Scanner"
ttl.Parent = top

local function mkBtn(txt, x, accent)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundColor3 = accent and Color3.fromRGB(220, 50, 50) or Color3.fromRGB(35, 35, 45)
	b.BorderSizePixel = 0
	b.Size = UDim2.fromOffset(48, 34)
	b.Position = UDim2.new(1, x, 0.5, -17)
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 16
	b.TextColor3 = accent and Color3.fromRGB(255,255,255) or Color3.fromRGB(230,230,235)
	b.Text = txt
	b.Parent = top

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = b

	local s = Instance.new("UIStroke")
	s.Thickness = 1.5
	s.Transparency = 0.65
	s.Color = Color3.fromRGB(255,255,255)
	s.Parent = b

	local normal = b.BackgroundColor3
	on(b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = accent and Color3.fromRGB(255,70,70) or Color3.fromRGB(50,50,62)}):Play()
	end))
	on(b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = normal}):Play()
	end))

	return b
end

local bRef = mkBtn("R", -106)
local bX = mkBtn("X", -52, true)

local box = Instance.new("TextBox")
box.ClearTextOnFocus = false
box.PlaceholderText = "Filter by ID, name or path..."
box.Text = ""
box.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
box.BorderSizePixel = 0
box.Position = UDim2.new(0, 18, 0, 64)
box.Size = UDim2.new(1, -36, 0, 40)
box.Font = Enum.Font.Gotham
box.TextSize = 15
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextColor3 = Color3.fromRGB(235, 235, 240)
box.PlaceholderColor3 = Color3.fromRGB(150, 155, 170)
box.Parent = root

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 12)
boxCorner.Parent = box

local boxStroke = Instance.new("UIStroke")
boxStroke.Thickness = 1.5
boxStroke.Color = Color3.fromRGB(255,255,255)
boxStroke.Transparency = 0.8
boxStroke.Parent = box

statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 20, 0, 110)
statusLabel.Size = UDim2.new(1, -40, 0, 20)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 13
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextColor3 = Color3.fromRGB(170, 175, 190)
statusLabel.Text = ""
statusLabel.Parent = root

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 18, 0, 136)
content.Size = UDim2.new(1, -36, 1, -152)
content.Parent = root

local left = Instance.new("Frame")
left.BackgroundTransparency = 1
left.Size = UDim2.new(0.59, 0, 1, 0)
left.Parent = content

local right = Instance.new("Frame")
right.BackgroundTransparency = 1
right.Position = UDim2.new(0.605, 0, 0, 0)
right.Size = UDim2.new(0.395, 0, 1, 0)
right.Parent = content

local list = Instance.new("ScrollingFrame")
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.Size = UDim2.new(1, 0, 1, 0)
list.ScrollBarThickness = 6
list.ScrollBarImageColor3 = Color3.fromRGB(90, 100, 120)
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.Parent = left

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 8)
pad.PaddingLeft = UDim.new(0, 8)
pad.PaddingRight = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.Parent = list

local grid = Instance.new("UIGridLayout")
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.CellPadding = UDim2.new(0, 10, 0, 10)
grid.CellSize = UDim2.new(0, 86, 0, 86)
grid.Parent = list

local function setCan()
	list.CanvasSize = UDim2.new(0, grid.AbsoluteContentSize.X + 16, 0, grid.AbsoluteContentSize.Y + 16)
end
on(grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(setCan))

local previewFrame = Instance.new("Frame")
previewFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 29)
previewFrame.BorderSizePixel = 0
previewFrame.Size = UDim2.new(1, 0, 0.47, 0)
previewFrame.ClipsDescendants = true
previewFrame.Parent = right

local pfCorner = Instance.new("UICorner")
pfCorner.CornerRadius = UDim.new(0, 14)
pfCorner.Parent = previewFrame

local pfStroke = Instance.new("UIStroke")
pfStroke.Thickness = 2
pfStroke.Color = Color3.fromRGB(255,255,255)
pfStroke.Transparency = 0.82
pfStroke.Parent = previewFrame

local previewImage = Instance.new("ImageLabel")
previewImage.BackgroundTransparency = 1
previewImage.Size = UDim2.new(1, -24, 1, -24)
previewImage.Position = UDim2.new(0, 12, 0, 12)
previewImage.ScaleType = Enum.ScaleType.Fit
previewImage.Image = ""
previewImage.ImageTransparency = 1
previewImage.Parent = previewFrame

local idBox = Instance.new("TextBox")
idBox.ClearTextOnFocus = false
idBox.PlaceholderText = "Asset ID / URL"
idBox.Text = ""
idBox.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
idBox.BorderSizePixel = 0
idBox.Size = UDim2.new(1, 0, 0, 38)
idBox.Position = UDim2.new(0, 0, 0.49, 6)
idBox.Font = Enum.Font.Gotham
idBox.TextScaled = true
idBox.TextXAlignment = Enum.TextXAlignment.Left
idBox.TextColor3 = Color3.fromRGB(235,235,240)
idBox.PlaceholderColor3 = Color3.fromRGB(155,160,175)
idBox.Parent = right

local idCorner = Instance.new("UICorner")
idCorner.CornerRadius = UDim.new(0, 12)
idCorner.Parent = idBox

local idStroke = Instance.new("UIStroke")
idStroke.Thickness = 1.5
idStroke.Color = Color3.fromRGB(255,255,255)
idStroke.Transparency = 0.8
idStroke.Parent = idBox

local infoScroll = Instance.new("ScrollingFrame")
infoScroll.BackgroundTransparency = 1
infoScroll.BorderSizePixel = 0
infoScroll.Position = UDim2.new(0, 0, 0.64, 8)
infoScroll.Size = UDim2.new(1, 0, 0.23, -8)
infoScroll.ScrollBarThickness = 5
infoScroll.ScrollBarImageColor3 = Color3.fromRGB(90,100,120)
infoScroll.CanvasSize = UDim2.new(0,0,0,0)
infoScroll.Parent = right

local infoLabel = Instance.new("TextLabel")
infoLabel.BackgroundTransparency = 1
infoLabel.Size = UDim2.new(1, -16, 0, 0)
infoLabel.Position = UDim2.new(0, 8, 0, 8)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 14
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.AutomaticSize = Enum.AutomaticSize.Y
infoLabel.TextColor3 = Color3.fromRGB(190,195,210)
infoLabel.TextWrapped = true
infoLabel.Text = "Select an image to preview"
infoLabel.Parent = infoScroll

local function updInfoCanvas()
	infoScroll.CanvasSize = UDim2.new(0, 0, 0, infoLabel.TextBounds.Y + 20)
end
on(infoLabel:GetPropertyChangedSignal("TextBounds"):Connect(updInfoCanvas))

local cp = Instance.new("TextButton")
cp.AutoButtonColor = false
cp.BackgroundColor3 = Color3.fromRGB(40, 120, 80)
cp.BorderSizePixel = 0
cp.Position = UDim2.new(0, 0, 0.89, 0)
cp.Size = UDim2.new(1, 0, 0, 42)
cp.Font = Enum.Font.GothamSemibold
cp.TextSize = 15
cp.TextColor3 = Color3.fromRGB(255,255,255)
cp.Text = "Copy ID"
cp.Parent = right

local cpCorner = Instance.new("UICorner")
cpCorner.CornerRadius = UDim.new(0, 12)
cpCorner.Parent = cp

local cpStroke = Instance.new("UIStroke")
cpStroke.Thickness = 2
cpStroke.Color = Color3.fromRGB(255,255,255)
cpStroke.Transparency = 0.7
cpStroke.Parent = cp

local rows = {}
local pick
local curBtn
local isCopying = false

local function mkInfoText(it)
	return ("Instance:\n%s\n\nProperty: %s\n\nSource:\n%s"):format(it.inst:GetFullName(), it.prop, it.src)
end

local function mkRow(it, idx)
	local fr = Instance.new("TextButton")
	fr.AutoButtonColor = false
	fr.BackgroundColor3 = Color3.fromRGB(26, 26, 34)
	fr.BackgroundTransparency = 1
	fr.BorderSizePixel = 0
	fr.Size = UDim2.new(0, 86, 0, 86)
	fr.LayoutOrder = idx
	fr.Text = ""
	fr.Parent = list

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 13)
	c.Parent = fr

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(255,255,255)
	stroke.Transparency = 0.85
	stroke.Parent = fr

	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.fromScale(0.5, 0.5)
	img.Size = UDim2.new(1, -16, 1, -16)
	img.ScaleType = Enum.ScaleType.Fit
	img.Image = it.src
	img.ImageTransparency = 1
	img.Parent = fr

	local tip = Instance.new("TextLabel")
	tip.BackgroundTransparency = 1
	tip.AnchorPoint = Vector2.new(0.5, 1)
	tip.Position = UDim2.new(0.5, 0, 1, -6)
	tip.Size = UDim2.new(1, -12, 0, 16)
	tip.Font = Enum.Font.Gotham
	tip.TextSize = 10
	tip.TextColor3 = Color3.fromRGB(200,200,215)
	tip.TextXAlignment = Enum.TextXAlignment.Center
	tip.TextTruncate = Enum.TextTruncate.AtEnd
	tip.Text = it.src
	tip.Parent = fr

	local imgScale = Instance.new("UIScale")
	imgScale.Scale = 1
	imgScale.Parent = img

	on(fr.MouseEnter:Connect(function()
		TweenService:Create(fr, TweenInfo.new(0.2), {BackgroundTransparency = 0.28, BackgroundColor3 = Color3.fromRGB(38,38,48)}):Play()
		TweenService:Create(imgScale, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Scale = 1.09}):Play()
	end))
	on(fr.MouseLeave:Connect(function()
		local targetTrans = (curBtn == fr) and 0.22 or 0.35
		TweenService:Create(fr, TweenInfo.new(0.2), {BackgroundTransparency = targetTrans, BackgroundColor3 = Color3.fromRGB(26,26,34)}):Play()
		TweenService:Create(imgScale, TweenInfo.new(0.25), {Scale = 1}):Play()
	end))

	on(fr.MouseButton1Click:Connect(function()
		pick = it
		idBox.Text = it.src
		infoLabel.Text = mkInfoText(it)
		updInfoCanvas()

		previewImage.ImageTransparency = 1
		previewImage.Image = it.src
		TweenService:Create(previewImage, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {ImageTransparency = 0}):Play()

		if curBtn and curBtn ~= fr then
			curBtn.BackgroundTransparency = 0.35
			curBtn.BackgroundColor3 = Color3.fromRGB(26,26,34)
		end
		curBtn = fr
		fr.BackgroundTransparency = 0.22
		fr.BackgroundColor3 = Color3.fromRGB(44, 48, 68)
	end))

	TweenService:Create(fr, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.35}):Play()
	TweenService:Create(img, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {ImageTransparency = 0}):Play()

	return fr
end

local function clr()
	for i = 1, #rows do
		local r = rows[i]
		rows[i] = nil
		if r then r:Destroy() end
	end
	curBtn = nil
	setCan()
end

local function filt()
	clr()
	local q = box.Text:lower()
	local n = 0
	for i = 1, #data do
		local it = data[i]
		local s = (it.src .. " " .. it.inst:GetFullName()):lower()
		if q == "" or s:find(q, 1, true) then
			n += 1
			rows[#rows+1] = mkRow(it, n)
		end
	end
	setCan()
end

local busy = false

local function refData()
	if busy then return end
	busy = true
	resetData()
	clr()
	pick = nil
	curBtn = nil
	previewImage.Image = ""
	idBox.Text = ""
	infoLabel.Text = "Scanning..."
	updInfoCanvas()
	statusLabel.Text = "Scanning..."

	onNewAsset = function(it)
		local q = box.Text:lower()
		local s = (it.src .. " " .. it.inst:GetFullName()):lower()
		if q == "" or s:find(q, 1, true) then
			rows[#rows+1] = mkRow(it, #rows+1)
			setCan()
		end
		statusLabel.Text = ("Scanning... %d images"):format(#data)
	end

	scanAsync(function()
		busy = false
		if #data == 0 then statusLabel.Text = "No images found" end
	end)
end

on(box:GetPropertyChangedSignal("Text"):Connect(filt))

on(cp.MouseButton1Click:Connect(function()
	local it = pick
	if not it or isCopying then return end
	isCopying = true
	local s = it.src

	if setclipboard then
		pcall(setclipboard, s)
		local origColor = cp.BackgroundColor3
		cp.Text = "Copied ✓"
		local tween1 = TweenService:Create(cp, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(70, 190, 110)})
		tween1:Play()
		tween1.Completed:Wait()
		local tween2 = TweenService:Create(cp, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = origColor})
		tween2:Play()
		tween2.Completed:Wait()
		task.delay(1.1, function()
			cp.Text = "Copy ID"
			isCopying = false
		end)
	else
		idBox.Text = s
		idBox:CaptureFocus()
		idBox.CursorPosition = #s + 1
		idBox.SelectionStart = 1
		isCopying = false
	end
end))

on(bRef.MouseButton1Click:Connect(refData))
on(bX.MouseButton1Click:Connect(function() off() gui:Destroy() end))

on(box.FocusLost:Connect(function(enter) if enter then filt() end end))

refData()

task.spawn(function()
	TweenService:Create(root, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
	TweenService:Create(sc, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end)