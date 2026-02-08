local plr = game:GetService("Players")
local uis = game:GetService("UserInputService")

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
	if ok and ui then
		return ui
	end

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
	if onNewAsset then
		onNewAsset(it)
	end
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

local props = {
	"Image",
	"Texture",
	"TextureId",
	"TextureID",
	"Graphic",
	"Thumbnail",
	"Icon",
	"NormalMap",
	"ColorMap",
	"MetalnessMap",
	"RoughnessMap",
	"AmbientOcclusionMap",
	"EmissionMap",
	"HeightMap",
	"AlphaMap",
}

local clsProps = {
	ImageLabel = {"Image"},
	ImageButton = {"Image"},
	Decal = {"Texture"},
	Texture = {"Texture"},
	ParticleEmitter = {"Texture"},
	Beam = {"Texture"},
	Trail = {"Texture"},
	Sky = {"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp","SunTextureId","MoonTextureId"},
	SurfaceAppearance = {"ColorMap","NormalMap","MetalnessMap","RoughnessMap"},
	MeshPart = {"TextureID"},
	SpecialMesh = {"TextureId","MeshId"},
	ShirtGraphic = {"Graphic"},
	MaterialVariant = {"ColorMap","NormalMap","MetalnessMap","RoughnessMap"},
}

local function scanInst(inst)
	local cn = inst.ClassName
	local p = clsProps[cn]
	if p then
		for _, nm2 in ipairs(p) do
			local ok, v = pcall(function() return inst[nm2] end)
			if ok and v ~= nil then
				findIds(v, inst, nm2)
			end
		end
	end

	for _, nm2 in ipairs(props) do
		local ok, v = pcall(function() return inst[nm2] end)
		if ok and v ~= nil then
			findIds(v, inst, nm2)
		end
	end

	local okA, at = pcall(function() return inst:GetAttributes() end)
	if okA and type(at) == "table" then
		for k, v in pairs(at) do
			if type(v) == "string" then
				findIds(v, inst, "Attr:" .. tostring(k))
			end
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
		local batch = 200
		for i = 1, n do
			scanInst(list[i])
			if i % batch == 0 then
				if statusLabel then
					statusLabel.Text = ("Scanning... %d/%d instances • %d images"):format(i, n, #data)
				end
				task.wait()
			end
		end
		if statusLabel then
			statusLabel.Text = ("Done. %d images found."):format(#data)
		end
		scanning = false
		onNewAsset = nil
		if onDone then
			onDone()
		end
	end)
end

local gui = Instance.new("ScreenGui")
gui.Name = nm
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = par end)
on(gui.AncestryChanged:Connect(function(_, parent)
	if not parent then
		off()
	end
end))

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(640, 360)
root.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
root.BorderSizePixel = 0
root.Parent = gui
root.Active = true
root.Draggable = true
root.ClipsDescendants = true

local cr = Instance.new("UICorner")
cr.CornerRadius = UDim.new(0, 10)
cr.Parent = root

local st = Instance.new("UIStroke")
st.Thickness = 1
st.Transparency = 0.25
st.Color = Color3.fromRGB(255, 255, 255)
st.Parent = root

local sc = Instance.new("UIScale")
sc.Parent = root

local function updSc()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local vp = cam.ViewportSize
	local w, h = vp.X, vp.Y
	local s = math.min(w / 760, h / 460)
	s = math.clamp(s, 0.75, 1.15)
	sc.Scale = s
end

updSc()
local function hookCam(c)
	if c then
		on(c:GetPropertyChangedSignal("ViewportSize"):Connect(updSc))
	end
end
hookCam(workspace.CurrentCamera)
on(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	hookCam(workspace.CurrentCamera)
	updSc()
end))

local top = Instance.new("Frame")
top.Name = "Top"
top.Size = UDim2.new(1, 0, 0, 42)
top.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
top.BorderSizePixel = 0
top.Parent = root
top.Active = true

local tcr = Instance.new("UICorner")
tcr.CornerRadius = UDim.new(0, 10)
tcr.Parent = top

local tmask = Instance.new("Frame")
tmask.Size = UDim2.new(1, 0, 0, 10)
tmask.Position = UDim2.new(0, 0, 1, -10)
tmask.BackgroundColor3 = top.BackgroundColor3
tmask.BorderSizePixel = 0
tmask.Parent = top

local ttl = Instance.new("TextLabel")
ttl.BackgroundTransparency = 1
ttl.Position = UDim2.new(0, 12, 0, 0)
ttl.Size = UDim2.new(1, -160, 1, 0)
ttl.Font = Enum.Font.GothamSemibold
ttl.TextSize = 15
ttl.TextXAlignment = Enum.TextXAlignment.Left
ttl.TextColor3 = Color3.fromRGB(230, 230, 235)
ttl.Text = "Image Scanner"
ttl.Parent = top

local function mkBtn(txt, x)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
	b.BorderSizePixel = 0
	b.Size = UDim2.fromOffset(38, 28)
	b.Position = UDim2.new(1, x, 0.5, -14)
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 14
	b.TextColor3 = Color3.fromRGB(235, 235, 240)
	b.Text = txt
	b.Parent = top
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = b
	return b
end

local bRef = mkBtn("R", -92)
local bX = mkBtn("X", -48)

local dragging = false
local dragInput
local dragStart
local startPos

on(top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = root.Position
		dragInput = input
	end
end))

on(uis.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			root.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end
end))

on(uis.InputEnded:Connect(function(input)
	if input == dragInput then
		dragging = false
		dragInput = nil
	end
end))

local box = Instance.new("TextBox")
box.ClearTextOnFocus = false
box.PlaceholderText = "filter (id / rbxassetid / name / path)"
box.Text = ""
box.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
box.BorderSizePixel = 0
box.Position = UDim2.new(0, 12, 0, 54)
box.Size = UDim2.new(1, -24, 0, 34)
box.Font = Enum.Font.Gotham
box.TextSize = 14
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextColor3 = Color3.fromRGB(235, 235, 240)
box.Parent = root

local bc = Instance.new("UICorner")
bc.CornerRadius = UDim.new(0, 10)
bc.Parent = box

statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 12, 0, 92)
statusLabel.Size = UDim2.new(1, -24, 0, 16)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
statusLabel.Text = ""
statusLabel.Parent = root

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.new(0, 12, 0, 112)
content.Size = UDim2.new(1, -24, 1, -130)
content.Parent = root

local left = Instance.new("Frame")
left.BackgroundTransparency = 1
left.Size = UDim2.new(0.58, 0, 1, 0)
left.Parent = content

local right = Instance.new("Frame")
right.BackgroundTransparency = 1
right.Position = UDim2.new(0.6, 8, 0, 0)
right.Size = UDim2.new(0.4, -8, 1, 0)
right.ClipsDescendants = true
right.Parent = content

local list = Instance.new("ScrollingFrame")
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.Position = UDim2.new(0, 0, 0, 0)
list.Size = UDim2.new(1, 0, 1, 0)
list.ScrollBarThickness = 6
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.Parent = left

local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 4)
pad.PaddingLeft = UDim.new(0, 4)
pad.PaddingRight = UDim.new(0, 4)
pad.PaddingBottom = UDim.new(0, 4)
pad.Parent = list

local grid = Instance.new("UIGridLayout")
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.CellPadding = UDim2.new(0, 6, 0, 6)
grid.CellSize = UDim2.new(0, 60, 0, 60)
grid.Parent = list

local function setCan()
	local csize = grid.AbsoluteContentSize
	list.CanvasSize = UDim2.new(0, csize.X + 8, 0, csize.Y + 8)
end
on(grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(setCan))

local previewFrame = Instance.new("Frame")
previewFrame.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
previewFrame.BorderSizePixel = 0
previewFrame.Size = UDim2.new(1, 0, 0.45, 0)
previewFrame.Position = UDim2.new(0, 0, 0, 0)
previewFrame.ClipsDescendants = true
previewFrame.Parent = right

local pfCorner = Instance.new("UICorner")
pfCorner.CornerRadius = UDim.new(0, 10)
pfCorner.Parent = previewFrame

local previewImage = Instance.new("ImageLabel")
previewImage.BackgroundTransparency = 1
previewImage.Size = UDim2.new(1, -16, 1, -16)
previewImage.Position = UDim2.new(0, 8, 0, 8)
previewImage.ScaleType = Enum.ScaleType.Fit
previewImage.Image = ""
previewImage.Parent = previewFrame

local idBox = Instance.new("TextBox")
idBox.ClearTextOnFocus = false
idBox.PlaceholderText = "id / url"
idBox.Text = ""
idBox.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
idBox.BorderSizePixel = 0
idBox.Size = UDim2.new(1, 0, 0.14, 0)
idBox.Position = UDim2.new(0, 0, 0.47, 0)
idBox.Font = Enum.Font.Gotham
idBox.TextScaled = true
idBox.TextXAlignment = Enum.TextXAlignment.Left
idBox.TextYAlignment = Enum.TextYAlignment.Center
idBox.TextColor3 = Color3.fromRGB(235, 235, 240)
idBox.ClipsDescendants = true
idBox.Parent = right

local idCorner = Instance.new("UICorner")
idCorner.CornerRadius = UDim.new(0, 10)
idCorner.Parent = idBox

local infoScroll = Instance.new("ScrollingFrame")
infoScroll.BackgroundTransparency = 1
infoScroll.BorderSizePixel = 0
infoScroll.Position = UDim2.new(0, 0, 0.62, 0)
infoScroll.Size = UDim2.new(1, 0, 0.25, -4)
infoScroll.ScrollBarThickness = 4
infoScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
infoScroll.Parent = right

local infoLabel = Instance.new("TextLabel")
infoLabel.BackgroundTransparency = 1
infoLabel.Size = UDim2.new(1, -8, 0, 0)
infoLabel.Position = UDim2.new(0, 4, 0, 4)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 14
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.TextYAlignment = Enum.TextYAlignment.Center
infoLabel.AutomaticSize = Enum.AutomaticSize.Y
infoLabel.TextColor3 = Color3.fromRGB(190, 190, 200)
infoLabel.TextWrapped = true
infoLabel.Text = "select an image"
infoLabel.Parent = infoScroll

local function updInfoCanvas()
	infoScroll.CanvasSize = UDim2.new(0, 0, 0, infoLabel.TextBounds.Y + 8)
end
updInfoCanvas()
on(infoLabel:GetPropertyChangedSignal("TextBounds"):Connect(updInfoCanvas))

local cp = Instance.new("TextButton")
cp.AutoButtonColor = false
cp.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
cp.BorderSizePixel = 0
cp.Position = UDim2.new(0, 0, 0.87, 0)
cp.Size = UDim2.new(1, 0, 0.13, -4)
cp.Font = Enum.Font.GothamSemibold
cp.TextSize = 14
cp.TextColor3 = Color3.fromRGB(235, 235, 240)
cp.Text = "Copy ID"
cp.Parent = right

local cpCorner = Instance.new("UICorner")
cpCorner.CornerRadius = UDim.new(0, 10)
cpCorner.Parent = cp

local rows = {}
local pick
local curBtn

local function mkInfoText(it)
	local full = it.inst:GetFullName()
	return full
end

local function mkRow(it, idx)
	local fr = Instance.new("TextButton")
	fr.AutoButtonColor = false
	fr.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
	fr.BorderSizePixel = 0
	fr.Size = UDim2.new(0, 60, 0, 60)
	fr.LayoutOrder = idx
	fr.Font = Enum.Font.Gotham
	fr.Text = ""
	fr.Parent = list

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = fr

	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.fromScale(0.5, 0.5)
	img.Size = UDim2.new(1, -10, 1, -10)
	img.ScaleType = Enum.ScaleType.Fit
	img.Image = it.src
	img.Parent = fr

	local tip = Instance.new("TextLabel")
	tip.BackgroundTransparency = 1
	tip.AnchorPoint = Vector2.new(0.5, 1)
	tip.Position = UDim2.new(0.5, 0, 1, -2)
	tip.Size = UDim2.new(1, -6, 0, 12)
	tip.Font = Enum.Font.Gotham
	tip.TextSize = 10
	tip.TextColor3 = Color3.fromRGB(200, 200, 210)
	tip.TextXAlignment = Enum.TextXAlignment.Center
	tip.TextTruncate = Enum.TextTruncate.AtEnd
	tip.Text = it.src
	tip.Parent = fr

	on(fr.MouseButton1Click:Connect(function()
		pick = it
		idBox.Text = it.src
		infoLabel.Text = mkInfoText(it)
		previewImage.Image = it.src

		if curBtn and curBtn ~= fr then
			curBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
		end
		curBtn = fr
		fr.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	end))

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
	infoLabel.Text = "scanning..."
	updInfoCanvas()
	if statusLabel then
		statusLabel.Text = "Scanning..."
	end

	onNewAsset = function(it)
		local q = box.Text:lower()
		local s = (it.src .. " " .. it.inst:GetFullName()):lower()
		if q == "" or s:find(q, 1, true) then
			rows[#rows+1] = mkRow(it, #rows+1)
			setCan()
		end
		if statusLabel then
			statusLabel.Text = ("Scanning... %d images found"):format(#data)
		end
	end

	scanAsync(function()
		busy = false
	end)
end

on(box:GetPropertyChangedSignal("Text"):Connect(filt))

local TweenService = game:GetService("TweenService")

on(cp.MouseButton1Click:Connect(function()
	local it = pick
	if not it then return end
	local s = it.src
	local ok = false
	if setclipboard then
		pcall(function()
			setclipboard(s)
			ok = true
		end)
	end
	if not ok then
		idBox.Text = s
		idBox:CaptureFocus()
		idBox.CursorPosition = #s + 1
		idBox.SelectionStart = 1
	end

	local origText = cp.Text
	local origColor = cp.BackgroundColor3
	cp.Text = "Copied"
	local tween1 = TweenService:Create(cp, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = Color3.fromRGB(70, 200, 120)
	})
	local tween2 = TweenService:Create(cp, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = origColor
	})
	tween1:Play()
	tween1.Completed:Wait()
	tween2:Play()
	tween2.Completed:Wait()
	cp.Text = origText
end))

on(bRef.MouseButton1Click:Connect(refData))

on(bX.MouseButton1Click:Connect(function()
	off()
	gui:Destroy()
end))

refData()