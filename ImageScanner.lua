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
local __NAUIProtector = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {};
	local sharedEnv = rawget(_G, "shared");
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil);
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_ui_protector");
		if type(cached) == "table" then
			return cached;
		end;
	end;
	local loader = loadstring or load;
	if type(loader) ~= "function" then
		return nil;
	end;
	local okSource, source = pcall(function()
		return game:HttpGet("https://ltseverydayyou.github.io/UIprotector.luau");
	end);
	if not okSource or type(source) ~= "string" or source == "" then
		return nil;
	end;
	local chunk = loader(source, "@UIprotector.luau");
	if type(chunk) ~= "function" then
		return nil;
	end;
	local okLoaded, loaded = pcall(chunk);
	if okLoaded and type(loaded) == "table" then
		if cacheHost then
			cacheHost.__lt_ui_protector = loaded;
		end;
		return loaded;
	end;
	return nil;
end)();
local __NAOriginalGetHui = gethui;
local gethui = function()
	if __NAUIProtector and type(__NAUIProtector.huiGrabber) == "function" then
		local ok, ui = pcall(__NAUIProtector.huiGrabber);
		if ok and typeof(ui) == "Instance" then
			return ui;
		end;
	end;
	if type(__NAOriginalGetHui) == "function" then
		local ok, ui = pcall(__NAOriginalGetHui);
		if ok then
			return ui;
		end;
	end;
	return nil;
end;
local function __NAProtectUI(gui, options)
	if __NAUIProtector and type(__NAUIProtector.protectUI) == "function" then
		local ok, protected = pcall(__NAUIProtector.protectUI, gui, options);
		if ok and protected then
			return protected;
		end;
	end;
	return nil;
end;

local plr = __lt.cs("Players", cloneref)
local uis = __lt.cs("UserInputService", cloneref)
local TweenService = __lt.cs("TweenService", cloneref)

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

	local cg = __lt.cs("CoreGui", cloneref)
	local rg = __lt.cm("CoreGui", "FindFirstChild", "RobloxGui")
	if rg then return rg end
	if cg then return ref(cg) end

	local pgui = lp:FindFirstChildOfClass("PlayerGui")
	if pgui then return pgui end
	return pg
end

local par = getPar()
local store = (function()
	local okShared, sharedEnv = pcall(function()
		return rawget(_G, "shared")
	end)
	if okShared and type(sharedEnv) == "table" then
		return sharedEnv
	end
	local okGlobal, globalEnv = pcall(function()
		return getgenv and getgenv()
	end)
	if okGlobal and type(globalEnv) == "table" then
		return globalEnv
	end
	return nil
end)()
local appKey = "__img_scan_gui_state"
if store then
	local oldState = rawget(store, appKey)
	if type(oldState) == "table" and type(oldState.clean) == "function" then
		pcall(oldState.clean)
	end
end
local alive = true
local state = {}
if store then
	rawset(store, appKey, state)
end

local nm = "ImgScanGui"
local old = par:FindFirstChild(nm)
if old then pcall(function() old:Destroy() end) end

local con = {}
local function on(c)
	if not c then return nil end
	if not alive then
		pcall(function() c:Disconnect() end)
		return c
	end
	con[#con+1] = c
	return c
end
local function off()
	for i = #con, 1, -1 do
		local c = con[i]
		con[i] = nil
		pcall(function() c:Disconnect() end)
	end
	if store and rawget(store, appKey) == state then
		rawset(store, appKey, nil)
	end
end

local function isMob()
	local p = __lt.cm("UserInputService", "GetPlatform")
	if p == Enum.Platform.IOS or p == Enum.Platform.Android or p == Enum.Platform.AndroidTV or p == Enum.Platform.Chromecast or p == Enum.Platform.MetaOS then
		return true
	end
	if p == Enum.Platform.None then
		return uis.TouchEnabled and not (uis.KeyboardEnabled or uis.MouseEnabled)
	end
	return uis.TouchEnabled and not (uis.KeyboardEnabled or uis.MouseEnabled)
end

local data = {}
local seen = {}
local onNew
local statusLabel

local function resetData()
	table.clear(data)
	table.clear(seen)
end

local function addRes(src, inst, prop)
	if not src or src == "" then return end
	if seen[src] then return end
	seen[src] = true
	local it = { src = src, inst = inst, prop = prop }
	data[#data+1] = it
	if onNew then onNew(it) end
end

local function findIds(s, inst, prop)
	if type(s) ~= "string" then return end
	local lo = s:lower()

	if s:match("^%d+$") then
		addRes("rbxassetid://" .. s, inst, prop)
		return
	end

	if lo:find("rbxthumb://", 1, true) then
		addRes(s, inst, prop)
		local id = lo:match("id=(%d+)")
		if id then
			addRes("rbxassetid://" .. id, inst, prop)
		end
		return
	end

	if not (lo:find("rbx", 1, true) or lo:find("http", 1, true) or lo:find("id=", 1, true)) then
		return
	end

	local n = s
	if n:find("%s") then
		n = n:gsub("%s+", "")
	end

	for id in n:gmatch("rbxassetid://(%d+)") do
		addRes("rbxassetid://" .. id, inst, prop)
	end
	for pth in n:gmatch("rbxasset://([^%?%#]+)") do
		addRes("rbxasset://" .. pth, inst, prop)
	end
	for id in n:gmatch("https?://www%.roblox%.com/asset/%?id=(%d+)") do
		addRes("rbxassetid://" .. id, inst, prop)
	end
	for id in n:gmatch("https?://www%.roblox%.com/Thumbs/Asset%.ashx%?[^%s]*id=(%d+)") do
		addRes("rbxassetid://" .. id, inst, prop)
	end
	for id in n:gmatch("https?://assetdelivery%.roblox%.com/v1/asset/%?id=(%d+)") do
		addRes("rbxassetid://" .. id, inst, prop)
	end
	for id in n:gmatch("https?://assetdelivery%.roblox%.com/v1/assetId/(%d+)") do
		addRes("rbxassetid://" .. id, inst, prop)
	end
	if lo:find("roblox.com", 1, true) or lo:find("assetdelivery.roblox.com", 1, true) then
		for id in n:gmatch("id=(%d+)") do
			addRes("rbxassetid://" .. id, inst, prop)
		end
	end
end

local props = {
	"Image","Texture","TextureId","TextureID","Graphic","Thumbnail","Icon",
	"NormalMap","ColorMap","MetalnessMap","RoughnessMap","AmbientOcclusionMap","EmissionMap","HeightMap","AlphaMap",
	"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp","SunTextureId","MoonTextureId",
	"ShirtTemplate","PantsTemplate"
}

local clsProps = {
	ImageLabel = {"Image"}, ImageButton = {"Image"},
	ImageHandleAdornment = {"Image"},
	Decal = {"Texture"}, Texture = {"Texture"},
	ParticleEmitter = {"Texture"}, Beam = {"Texture"}, Trail = {"Texture"},
	Sky = {"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp","SunTextureId","MoonTextureId"},
	SurfaceAppearance = {"ColorMap","NormalMap","MetalnessMap","RoughnessMap"},
	MeshPart = {"TextureID"},
	SpecialMesh = {"TextureId"},
	ShirtGraphic = {"Graphic"},
	MaterialVariant = {"ColorMap","NormalMap","MetalnessMap","RoughnessMap"},
	Shirt = {"ShirtTemplate"},
	Pants = {"PantsTemplate"},
	Tool = {"TextureId"},
}

local ccache = {}
local function getPlist(inst)
	local cn = inst.ClassName
	local t = ccache[cn]
	if t then return t end

	local lst = {}
	local have = {}

	local function push(p)
		if not have[p] then
			have[p] = true
			lst[#lst+1] = p
		end
	end

	local cp = clsProps[cn]
	if cp then
		for i = 1, #cp do
			push(cp[i])
		end
	end

	for i = 1, #props do
		local p = props[i]
		local ok = pcall(function()
			return inst[p]
		end)
		if ok then
			push(p)
		end
	end

	ccache[cn] = lst
	return lst
end

local gui
local scanAttr = true
local function scanInst(inst)
	if not alive or not inst then return end
	if gui and (inst == gui or inst:IsDescendantOf(gui)) then return end
	local lst = getPlist(inst)
	for i = 1, #lst do
		local p = lst[i]
		local ok, v = pcall(function()
			return inst[p]
		end)
		if ok and type(v) == "string" then
			findIds(v, inst, p)
		end
	end
	if scanAttr then
		local ok, at = pcall(function()
			return inst:GetAttributes()
		end)
		if ok and type(at) == "table" then
			for k, v in at do
				if type(v) == "string" then
					findIds(v, inst, "Attr:" .. tostring(k))
				end
			end
		end
	end
end

gui = Instance.new("ScreenGui")
gui.Name = nm
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = par end)
on(gui.AncestryChanged:Connect(function(_, p)
	if not p and alive then
		if type(state.clean) == "function" then
			state.clean()
		else
			alive = false
			off()
		end
	end
end))

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(780, 540)
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

local rootGrad = Instance.new("UIGradient")
rootGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 34)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 20))
})
rootGrad.Rotation = 90
rootGrad.Parent = root

local sc = Instance.new("UIScale")
sc.Scale = 1
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
ttl.TextTruncate = Enum.TextTruncate.AtEnd
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
		__lt.cm("TweenService", "Create", b, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = accent and Color3.fromRGB(255,70,70) or Color3.fromRGB(50,50,62)}):Play()
	end))
	on(b.MouseLeave:Connect(function()
		__lt.cm("TweenService", "Create", b, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = normal}):Play()
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
box.TextWrapped = false
box.TextTruncate = Enum.TextTruncate.AtEnd
box.TextColor3 = Color3.fromRGB(235, 235, 240)
box.PlaceholderColor3 = Color3.fromRGB(150, 155, 170)
box.Parent = root

local boxPad = Instance.new("UIPadding")
boxPad.PaddingLeft = UDim.new(0, 12)
boxPad.PaddingRight = UDim.new(0, 12)
boxPad.Parent = box

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
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
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
list.ScrollingDirection = Enum.ScrollingDirection.Y
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
	if not alive then return end
	list.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 16)
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
idBox.TextSize = 13
idBox.TextWrapped = false
idBox.TextTruncate = Enum.TextTruncate.AtEnd
idBox.TextXAlignment = Enum.TextXAlignment.Left
idBox.TextColor3 = Color3.fromRGB(235,235,240)
idBox.PlaceholderColor3 = Color3.fromRGB(155,160,175)
idBox.Parent = right

local idPad = Instance.new("UIPadding")
idPad.PaddingLeft = UDim.new(0, 10)
idPad.PaddingRight = UDim.new(0, 10)
idPad.Parent = idBox

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
infoScroll.ClipsDescendants = true
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
	if not alive then return end
	infoScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(infoScroll.AbsoluteSize.Y, infoLabel.TextBounds.Y + 20))
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

local function fitUi()
	if not alive then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local vp = cam.ViewportSize
	local mob = isMob()
	local margin = mob and 10 or 24
	local minW = mob and 310 or 520
	local minH = mob and 340 or 420
	local w = math.clamp(vp.X - margin * 2, math.min(minW, math.max(300, vp.X - 8)), 860)
	local h = math.clamp(vp.Y - margin * 2, math.min(minH, math.max(300, vp.Y - 8)), 620)

	root.Size = UDim2.fromOffset(w, h)
	root.Position = UDim2.fromScale(0.5, 0.5)
	sc.Scale = 1

	local compact = w < 610 or (mob and vp.X < 760)
	local topH = compact and 48 or 52
	local boxH = compact and 36 or 40
	local boxY = topH + 12
	local statusY = boxY + boxH + 6
	local contentY = statusY + 24
	local contentW = math.max(0, w - 36)
	local contentH = math.max(120, h - contentY - 16)

	top.Size = UDim2.new(1, 0, 0, topH)
	topMask.Position = UDim2.new(0, 0, 1, -14)
	topMask.Size = UDim2.new(1, 0, 0, 14)

	local bw = compact and 42 or 48
	local bh = compact and 32 or 34
	bRef.Size = UDim2.fromOffset(bw, bh)
	bX.Size = UDim2.fromOffset(bw, bh)
	bRef.Position = UDim2.new(1, -(bw * 2 + 16), 0.5, -bh / 2)
	bX.Position = UDim2.new(1, -(bw + 10), 0.5, -bh / 2)
	ttl.Position = UDim2.new(0, compact and 14 or 18, 0, 0)
	ttl.Size = UDim2.new(1, -(bw * 2 + 64), 1, 0)
	ttl.TextSize = compact and 15 or 17

	box.Position = UDim2.new(0, 18, 0, boxY)
	box.Size = UDim2.new(1, -36, 0, boxH)
	box.TextSize = compact and 13 or 15

	statusLabel.Position = UDim2.new(0, 20, 0, statusY)
	statusLabel.Size = UDim2.new(1, -40, 0, 18)
	statusLabel.TextSize = compact and 11 or 13

	content.Position = UDim2.new(0, 18, 0, contentY)
	content.Size = UDim2.new(1, -36, 0, contentH)

	local gap = compact and 10 or 14
	local rightH
	local leftW
	if compact then
		local listH = math.floor(contentH * (contentH < 330 and 0.42 or 0.47))
		listH = math.clamp(listH, 118, math.max(118, contentH - 150))
		left.Position = UDim2.fromOffset(0, 0)
		left.Size = UDim2.new(1, 0, 0, listH)
		right.Position = UDim2.fromOffset(0, listH + gap)
		rightH = math.max(120, contentH - listH - gap)
		right.Size = UDim2.new(1, 0, 0, rightH)
		leftW = contentW
	else
		leftW = math.floor(contentW * 0.58)
		left.Position = UDim2.fromOffset(0, 0)
		left.Size = UDim2.new(0, leftW, 1, 0)
		right.Position = UDim2.fromOffset(leftW + gap, 0)
		rightH = contentH
		right.Size = UDim2.new(0, math.max(0, contentW - leftW - gap), 1, 0)
	end

	local padX = compact and 8 or 10
	local cells = compact and 4 or 5
	local cell = math.floor((math.max(260, leftW) - 16 - padX * (cells - 1)) / cells)
	cell = math.clamp(cell, mob and 58 or 68, compact and 82 or 94)
	grid.CellSize = UDim2.fromOffset(cell, cell)
	grid.CellPadding = UDim2.fromOffset(padX, padX)

	local rgap = compact and 7 or 9
	local idH = compact and 34 or 38
	local cpH = compact and 36 or 42
	local minInfo = compact and 42 or 64
	local prevH = math.floor(rightH * (compact and 0.34 or 0.45))
	prevH = math.clamp(prevH, compact and 64 or 112, compact and 132 or 230)
	local infoH = rightH - prevH - idH - cpH - rgap * 3
	if infoH < minInfo then
		prevH = math.max(compact and 54 or 90, prevH - (minInfo - infoH))
		infoH = rightH - prevH - idH - cpH - rgap * 3
	end
	infoH = math.max(34, infoH)

	previewFrame.Position = UDim2.fromOffset(0, 0)
	previewFrame.Size = UDim2.new(1, 0, 0, prevH)
	idBox.Position = UDim2.fromOffset(0, prevH + rgap)
	idBox.Size = UDim2.new(1, 0, 0, idH)
	idBox.TextSize = compact and 12 or 13
	infoScroll.Position = UDim2.fromOffset(0, prevH + rgap + idH + rgap)
	infoScroll.Size = UDim2.new(1, 0, 0, infoH)
	cp.Position = UDim2.fromOffset(0, math.max(0, rightH - cpH))
	cp.Size = UDim2.new(1, 0, 0, cpH)
	cp.TextSize = compact and 13 or 15

	setCan()
	updInfoCanvas()
end
local camCon
local function bindCam()
	if camCon then
		pcall(function() camCon:Disconnect() end)
		camCon = nil
	end
	local cam = workspace.CurrentCamera
	if cam then
		camCon = on(cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitUi))
	end
	fitUi()
end

task.defer(function()
	while alive and not workspace.CurrentCamera do
		task.wait()
	end
	if not alive then return end
	bindCam()
	on(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCam))
end)

local rows = {}
local rmeta = {}
local shown = {}
local pick
local curBtn
local isCopying = false

local function safeFullName(inst)
	local ok, v = pcall(function() return inst:GetFullName() end)
	return ok and v or tostring(inst)
end

local function mkInfoText(it)
	return ("Instance:\n%s\n\nProperty: %s\n\nSource:\n%s"):format(safeFullName(it.inst), tostring(it.prop), tostring(it.src))
end

local function reg(fr, c)
	local t = rmeta[fr]
	if not t then
		t = {}
		rmeta[fr] = t
	end
	t[#t+1] = c
	return c
end

local function killRow(fr)
	local t = rmeta[fr]
	rmeta[fr] = nil
	if t then
		for i = #t, 1, -1 do
			local c = t[i]
			t[i] = nil
			pcall(function() c:Disconnect() end)
		end
	end
	pcall(function() fr:Destroy() end)
end

local function mkRow(it, idx)
	if not alive then return nil end
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

	reg(fr, fr.MouseEnter:Connect(function()
		__lt.cm("TweenService", "Create", fr, TweenInfo.new(0.2), {BackgroundTransparency = 0.28, BackgroundColor3 = Color3.fromRGB(38,38,48)}):Play()
		__lt.cm("TweenService", "Create", imgScale, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Scale = 1.09}):Play()
	end))
	reg(fr, fr.MouseLeave:Connect(function()
		local targetTrans = (curBtn == fr) and 0.22 or 0.35
		__lt.cm("TweenService", "Create", fr, TweenInfo.new(0.2), {BackgroundTransparency = targetTrans, BackgroundColor3 = Color3.fromRGB(26,26,34)}):Play()
		__lt.cm("TweenService", "Create", imgScale, TweenInfo.new(0.25), {Scale = 1}):Play()
	end))

	reg(fr, fr.MouseButton1Click:Connect(function()
		pick = it
		idBox.Text = it.src
		infoLabel.Text = mkInfoText(it)
		updInfoCanvas()

		previewImage.ImageTransparency = 1
		previewImage.Image = it.src
		__lt.cm("TweenService", "Create", previewImage, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {ImageTransparency = 0}):Play()

		if curBtn and curBtn ~= fr then
			curBtn.BackgroundTransparency = 0.35
			curBtn.BackgroundColor3 = Color3.fromRGB(26,26,34)
		end
		curBtn = fr
		fr.BackgroundTransparency = 0.22
		fr.BackgroundColor3 = Color3.fromRGB(44, 48, 68)
	end))

	__lt.cm("TweenService", "Create", fr, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.35}):Play()
	__lt.cm("TweenService", "Create", img, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {ImageTransparency = 0}):Play()

	return fr
end

local function clr()
	for i = 1, #rows do
		local r = rows[i]
		rows[i] = nil
		if r then killRow(r) end
	end
	table.clear(shown)
	curBtn = nil
	setCan()
end

local function match(it, q)
	if q == "" then return true end
	local s1 = tostring(it.src):lower()
	if s1:find(q, 1, true) then return true end
	local ok, fn = pcall(function() return it.inst and it.inst:GetFullName() end)
	local nm2 = (ok and fn) and fn or tostring(it.inst)
	return tostring(nm2):lower():find(q, 1, true) ~= nil
end

local qadd = {}
local qh = 1
local pumping = false
local pumpTok = 0
local building = false
local buildTok = 0
local pump

local function enq(it)
	qadd[#qadd+1] = it
	if pump then pump() end
end
onNew = enq

local uiBud = isMob() and 0.0034 or 0.0064

pump = function()
	if not alive or pumping then return end
	pumpTok += 1
	local tok = pumpTok
	pumping = true

	task.spawn(function()
		while alive and tok == pumpTok do
			if building then
				task.wait()
			else
				local t0 = os.clock()
				local q = box.Text:lower()

				while alive and tok == pumpTok and not building and qh <= #qadd and (os.clock() - t0) < uiBud do
					local it = qadd[qh]
					qadd[qh] = nil
					qh += 1
					if it and not shown[it.src] and match(it, q) then
						shown[it.src] = true
						rows[#rows+1] = mkRow(it, #rows+1)
					end
				end

				if qh > 9000 then
					local n = #qadd
					if qh > n then
						table.clear(qadd)
						qh = 1
					else
						local tmp = {}
						local j = 1
						for i = qh, n do
							tmp[j] = qadd[i]
							j += 1
						end
						qadd = tmp
						qh = 1
					end
				end

				setCan()
				if qh > #qadd then
					break
				end
				task.wait()
			end
		end
		pumping = false
		if alive and tok == pumpTok and qh <= #qadd then
			pump()
		end
	end)
end

local function rebuild()
	if not alive then return end
	buildTok += 1
	local tok = buildTok
	building = true
	pumpTok += 1

	task.spawn(function()
		if not alive then return end
		clr()

		local q = box.Text:lower()
		local i = 1
		local n = #data
		local made = 0

		while alive and tok == buildTok and i <= n do
			local t0 = os.clock()
			while alive and tok == buildTok and i <= n and (os.clock() - t0) < uiBud do
				local it = data[i]
				i += 1
				if it and not shown[it.src] and match(it, q) then
					shown[it.src] = true
					made += 1
					rows[#rows+1] = mkRow(it, made)
				end
			end
			setCan()
			task.wait()
		end

		building = false
		if alive and tok == buildTok then
			pump()
		end
	end)
end

local scanTok = 0
local scanBud = isMob() and 0.0058 or 0.0105
local scanning = false
local tot = 0
local done = 0
local addSeen = 0

local din = {}
local dh = 1
local dRun = false
local dTok = 0

local function dPump()
	if not alive or dRun then return end
	dTok += 1
	local tok = dTok
	dRun = true
	task.spawn(function()
		while alive and tok == dTok and dh <= #din do
			local t0 = os.clock()
			while alive and tok == dTok and dh <= #din and (os.clock() - t0) < scanBud do
				local inst = din[dh]
				din[dh] = nil
				dh += 1
				if inst and not (gui and (inst == gui or inst:IsDescendantOf(gui))) then
					pcall(scanInst, inst)
					addSeen += 1
				end
			end

			if dh > 14000 then
				local n = #din
				if dh > n then
					table.clear(din)
					dh = 1
				else
					local tmp = {}
					local j = 1
					for i = dh, n do
						tmp[j] = din[i]
						j += 1
					end
					din = tmp
					dh = 1
				end
			end

			if dh > #din then
				break
			end
			task.wait()
		end
		dRun = false
		if alive and tok == dTok and dh <= #din then
			dPump()
		end
	end)
end

on(game.DescendantAdded:Connect(function(inst)
	if not alive or (gui and (inst == gui or inst:IsDescendantOf(gui))) then return end
	din[#din+1] = inst
	dPump()
end))

local function scanStart()
	if not alive then return end
	scanTok += 1
	local tok = scanTok
	scanning = true
	tot = 0
	done = 0
	addSeen = 0

	task.spawn(function()
		if not alive then return end
		if statusLabel then
			statusLabel.Text = "Indexing..."
		end

		local desc
		local ok = pcall(function()
			desc = game:QueryDescendants("Instance")
		end)
		if not ok or type(desc) ~= "table" then
			local okDesc = pcall(function()
				desc = game:GetDescendants()
			end)
			if not okDesc or type(desc) ~= "table" then
				desc = {}
			end
		end
		desc[#desc+1] = game

		tot = #desc
		done = 0
		local last = 0

		if statusLabel then
			statusLabel.Text = ("Scanning... %d/%d • %d images"):format(0, tot, #data)
		end

		local i = 1
		while alive and tok == scanTok and i <= tot do
			local t0 = os.clock()
			while alive and tok == scanTok and i <= tot and (os.clock() - t0) < scanBud do
				local inst = desc[i]
				i += 1
				if inst then
					pcall(scanInst, inst)
				end
			end

			done = i - 1
			local now = os.clock()
			if statusLabel and (now - last) > 0.08 then
				last = now
				statusLabel.Text = ("Scanning... %d/%d • %d images • %d shown"):format(done, tot, #data, #rows)
			end
			task.wait()
		end

		if alive and tok == scanTok then
			scanning = false
			if statusLabel then
				statusLabel.Text = ("Done • %d/%d • %d images • %d shown"):format(done, tot, #data, #rows)
			end
		end
	end)
end

on(cp.MouseButton1Click:Connect(function()
	local it = pick
	if not alive or not it or isCopying then return end
	isCopying = true
	local s = it.src

	if setclipboard then
		pcall(setclipboard, s)
		local origColor = cp.BackgroundColor3
		cp.Text = "Copied ✓"
		__lt.cm("TweenService", "Create", cp, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(70, 190, 110)}):Play()
		task.delay(0.35, function()
			if not alive or not cp.Parent then return end
			__lt.cm("TweenService", "Create", cp, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = origColor}):Play()
		end)
		task.delay(1.1, function()
			if not alive or not cp.Parent then return end
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

local ftok = 0
on(box:GetPropertyChangedSignal("Text"):Connect(function()
	ftok += 1
	local t = ftok
	task.delay(0.14, function()
		if not alive or t ~= ftok then return end
		rebuild()
	end)
end))

local function stopAll()
	scanTok += 1
	buildTok += 1
	pumpTok += 1
	dTok += 1
	scanning = false
	building = false
	pumping = false
	dRun = false
end

state.clean = function()
	if not alive then return end
	alive = false
	stopAll()
	pcall(clr)
	off()
	if gui then
		pcall(function() gui:Destroy() end)
	end
end

local function refData()
	if not alive then return end
	stopAll()
	resetData()
	table.clear(ccache)
	clr()
	table.clear(qadd)
	qh = 1
	table.clear(din)
	dh = 1
	pick = nil
	curBtn = nil
	previewImage.Image = ""
	idBox.Text = ""
	infoLabel.Text = "Scanning..."
	updInfoCanvas()
	if statusLabel then statusLabel.Text = "Indexing..." end
	pump()
	scanStart()
end

on(bRef.MouseButton1Click:Connect(refData))
on(bX.MouseButton1Click:Connect(function()
	state.clean()
end))

refData()

task.spawn(function()
	if not alive then return end
	__lt.cm("TweenService", "Create", root, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
	__lt.cm("TweenService", "Create", sc, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = sc.Scale}):Play()
end)end)
