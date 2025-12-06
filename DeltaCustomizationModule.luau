if identifyexecutor():lower() ~= "delta" then return end

local deltaEnv = type(getgenv) == "function" and getgenv() or _G
if type(deltaEnv) == "table" then
	if deltaEnv.__DeltaCustomizationModuleLoaded then
		return
	end
	deltaEnv.__DeltaCustomizationModuleLoaded = true
end

local SRV = setmetatable({}, {
	__index = function(self, n)
		local ref = cloneref and type(cloneref) == "function" and cloneref or function(v) return v end
		local ok, s = pcall(function() return ref(game:GetService(n)) end)
		if ok and s then
			rawset(self, n, s)
			return s
		end
	end
})

local function Svc(n)
	return SRV[n]
end

local UIS = Svc("UserInputService")
local CG = Svc("CoreGui")
local HS = Svc("HttpService")
local RS = Svc("RunService")
local Stats = Svc("Stats")
local TS = Svc("TweenService")

local notifMod
local nt

local colorsPath = "DeltaCustom/Colors.json"
local colorConfig = {}

do
	if HS and type(isfile) == "function" and type(readfile) == "function" then
		if isfile(colorsPath) then
			local ok, data = pcall(readfile, colorsPath)
			if ok and data then
				local ok2, decoded = pcall(function()
					return HS:JSONDecode(data)
				end)
				if ok2 and type(decoded) == "table" then
					colorConfig = decoded
				end
			end
		end
	end
end

local settingsPath = "DeltaCustom/Settings.json"
local settingsConfig = {}

do
	if HS and type(isfile) == "function" and type(readfile) == "function" then
		if isfile(settingsPath) then
			local ok, data = pcall(readfile, settingsPath)
			if ok and data then
				local ok2, decoded = pcall(function()
					return HS:JSONDecode(data)
				end)
				if ok2 and type(decoded) == "table" then
					settingsConfig = decoded
				end
			end
		end
	end
end

do
	local n = nil
	local tries = 0
	repeat
		tries += 1
		local s, r = pcall(function()
			return loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/NamelessAdminNotifications.lua"))()
		end)
		if s and type(r) == "table" and type(r.Notify) == "function" then
			n = r
			notifMod = r
			nt = r.Notify
		else
			task.wait(0.5)
		end
	until n ~= nil or tries >= 5
end

local function notify(info)
	if not nt or type(info) ~= "table" then
		return
	end
	pcall(function()
		nt(info)
	end)
end

local _naConns = _naConns or {}
local NAlib = {}

function NAlib.disconnect(n)
	local t = _naConns[n]
	if t then
		for _, c in ipairs(t) do
			pcall(function() c:Disconnect() end)
		end
		_naConns[n] = nil
	end
end

function NAlib.connect(n, c)
	if not c then return end
	_naConns[n] = _naConns[n] or {}
	table.insert(_naConns[n], c)
	return c
end

function NAlib.isProperty(o, p)
	return pcall(function() return o[p] end)
end

function NAlib.setProperty(o, p, v)
	pcall(function() o[p] = v end)
end

local uiLib = {}

uiLib.draggerV2 = function(ui, dragui)
	dragui = dragui or ui
	local dragging, dragInput, dragStart, startPos
	local anchor = ui.AnchorPoint
	local sg = ui:FindFirstAncestorWhichIsA("ScreenGui") or ui.Parent

	local function sClamp(v, lo, hi)
		if hi < lo then hi = lo end
		return math.clamp(v, lo, hi)
	end

	local function upd(input)
		pcall(function()
			local p = sg.AbsoluteSize
			local s = ui.AbsoluteSize
			if p.X <= 0 or p.Y <= 0 then return end

			local sx = startPos.X.Scale * p.X + startPos.X.Offset
			local sy = startPos.Y.Scale * p.Y + startPos.Y.Offset
			local dx = input.Position.X - dragStart.X
			local dy = input.Position.Y - dragStart.Y

			local minX = anchor.X * s.X
			local maxX = p.X - (1 - anchor.X) * s.X
			local minY = anchor.Y * s.Y
			local maxY = p.Y - (1 - anchor.Y) * s.Y

			local nx = sClamp(sx + dx, minX, maxX)
			local ny = sClamp(sy + dy, minY, maxY)

			ui.Position = UDim2.new(nx / p.X, 0, ny / p.Y, 0)
		end)
	end

	local id = "DraggerV2_" .. ui:GetDebugId()
	NAlib.disconnect(id)

	NAlib.connect(id, dragui.InputBegan:Connect(function(input)
		pcall(function()
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then

				dragging = true
				dragStart = input.Position
				startPos = ui.Position

				local c = input.Changed:Connect(function()
					pcall(function()
						if input.UserInputState == Enum.UserInputState.End then
							dragging = false
						end
					end)
				end)

				NAlib.connect(id, c)
			end
		end)
	end))

	NAlib.connect(id, dragui.InputChanged:Connect(function(input)
		pcall(function()
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)
	end))

	NAlib.connect(id, UIS.InputChanged:Connect(function(input)
		pcall(function()
			if input == dragInput and dragging then
				upd(input)
			end
		end)
	end))

	local function clampToView()
		pcall(function()
			local p = sg.AbsoluteSize
			local s = ui.AbsoluteSize
			if p.X <= 0 or p.Y <= 0 then return end

			local pos = ui.Position
			local ax = pos.X.Scale * p.X + pos.X.Offset
			local ay = pos.Y.Scale * p.Y + pos.Y.Offset

			local minX = anchor.X * s.X
			local maxX = p.X - (1 - anchor.X) * s.X
			local minY = anchor.Y * s.Y
			local maxY = p.Y - (1 - anchor.Y) * s.Y

			local nx = sClamp(ax, minX, maxX)
			local ny = sClamp(ay, minY, maxY)

			ui.Position = UDim2.new(nx / p.X, 0, ny / p.Y, 0)
		end)
	end

	NAlib.connect(id, sg:GetPropertyChangedSignal("AbsoluteSize"):Connect(clampToView))
	if ui and ui.GetPropertyChangedSignal then
		NAlib.connect(id, ui:GetPropertyChangedSignal("AbsoluteSize"):Connect(clampToView))
	end

	clampToView()

	if ui and NAlib.isProperty(ui, "Active") then
		NAlib.setProperty(ui, "Active", true)
	end
	if dragui and NAlib.isProperty(dragui, "Active") then
		NAlib.setProperty(dragui, "Active", true)
	end
end

local root = (gethui and gethui()) or CG

local function isGib(n)
	if typeof(n) ~= "string" or n == "" then return false end
	return not n:match("^[%w _%-]+$")
end

local function getMain()
	for _, g in ipairs(root:GetChildren()) do
		if g:IsA("ScreenGui") and isGib(g.Name) then
			if g:FindFirstChild("Executor", true)
				and g:FindFirstChild("Scripthub", true)
				and g:FindFirstChild("Sidebar", true) then
				return g
			end
		end
	end
end

local function getIconGui()
	local function chk(g)
		if not (g:IsA("ScreenGui") and isGib(g.Name)) then return end
		local kids = g:GetChildren()
		local img
		local cnt = 0
		for _, c in ipairs(kids) do
			if c:IsA("ImageButton") then
				cnt += 1
				img = c
			else
				return
			end
		end
		if cnt == 1 then
			return g, img
		end
	end

	for _, g in ipairs(root:GetChildren()) do
		local ig, ib = chk(g)
		if ig then
			return ig, ib
		end
	end
end

local mainGui = getMain()
local iconGui, iconBtn = getIconGui()

local iconStroke = iconBtn and (iconBtn:FindFirstChildOfClass("UIStroke") or iconBtn:FindFirstChildWhichIsA("UIStroke", true))
local iconBaseColor = iconStroke and iconStroke.Color
local iconBaseSize = iconBtn and iconBtn.Size
local iconColorUseCustom = false

task.defer(function()
	while not mainGui do
		mainGui = getMain()
		if mainGui then break end
		task.wait(0.1)
	end
	if not mainGui then
		notify({
			Title = "Delta Customization",
			Description = "Failed to find Delta UI.",
			Duration = 4,
		})
		return
	end

	local execFrame = mainGui:FindFirstChild("Executor")
	if not (execFrame and execFrame:IsA("Frame")) then
		notify({
			Title = "Delta Customization",
			Description = "Executor frame not found.",
			Duration = 4,
		})
		return
	end

	local execImage = execFrame:FindFirstChild("Executor")
	if not (execImage and execImage:IsA("ImageLabel")) then
		notify({
			Title = "Delta Customization",
			Description = "Executor image not found.",
			Duration = 4,
		})
		return
	end

	local overlay = execImage:FindFirstChild("Overlay")
	if not overlay then
		notify({
			Title = "Delta Customization",
			Description = "Overlay frame not found.",
			Duration = 4,
		})
		return
	end

	local sidebar = mainGui:FindFirstChild("Sidebar", true)
	local toggleUIBtn = sidebar and sidebar:FindFirstChild("ToggleUI", true)
	local activeColorValue = sidebar and sidebar:FindFirstChild("ActiveColor")
	local inactiveColorValue = sidebar and sidebar:FindFirstChild("InactiveColor")
	local darkOverlay = mainGui:FindFirstChild("DarkOverlay")
	local sidebarGradient = nil
	local sidebarGrad1 = nil
	local sidebarGrad2 = nil

	if iconGui and iconGui:IsA("ScreenGui") then
		pcall(function() iconGui.IgnoreGuiInset = true end)
	end

	if iconBtn then
		pcall(function() iconBtn.Draggable = false end)
		uiLib.draggerV2(iconBtn, iconBtn)
	end

	if darkOverlay then
		darkOverlay.Visible=false
		darkOverlay:GetPropertyChangedSignal("Visible"):Connect(function()
			darkOverlay.Visible=false
		end)
	end

	local settingsFrame
	do
		local cand = mainGui:FindFirstChild("Settings", true)
		if cand and cand:IsA("Frame") and cand:FindFirstChild("Holder") then
			settingsFrame = cand
		end
	end

	local settingsHolder = settingsFrame and settingsFrame:FindFirstChild("Holder")
	local settingTemplate
	local function setupAutoScroll(sf)
		if not (sf and sf:IsA("ScrollingFrame")) then return end
		local layout = sf:FindFirstChildWhichIsA("UIListLayout") or sf:FindFirstChildWhichIsA("UIGridLayout")
		if not layout then return end

		local fixed = false

		local function fixSizesOnce()
			if fixed then return end
			fixed = true

			if layout:IsA("UIGridLayout") then
				local cs = layout.CellSize
				if cs.Y.Scale > 0 and cs.Y.Offset == 0 then
					local abs = layout.AbsoluteCellSize
					local oy = abs.Y
					if oy <= 0 then
						oy = cs.Y.Scale * sf.AbsoluteSize.Y
					end
					layout.CellSize = UDim2.new(
						cs.X.Scale,
						cs.X.Offset,
						0,
						math.floor(oy + 0.5)
					)
				end
			else
				for _, ch in ipairs(sf:GetChildren()) do
					if ch:IsA("GuiObject") then
						local cs = ch.Size
						if cs.Y.Scale > 0 and cs.Y.Offset == 0 then
							local oy = ch.AbsoluteSize.Y
							if oy <= 0 then
								oy = cs.Y.Scale * sf.AbsoluteSize.Y
							end
							ch.Size = UDim2.new(
								cs.X.Scale,
								cs.X.Offset,
								0,
								math.floor(oy + 0.5)
							)
						end
					end
				end
			end
		end

		local function upd()
			fixSizesOnce()
			local size = layout.AbsoluteContentSize
			sf.CanvasSize = UDim2.new(0, 0, 0, size.Y + 250)
		end

		upd()

		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd)

		sf.ChildAdded:Connect(function()
			fixed = false
			task.defer(upd)
		end)

		sf.ChildRemoved:Connect(function()
			task.defer(upd)
		end)
	end
	if settingsHolder then
		for _, c in ipairs(settingsHolder:GetChildren()) do
			if c:IsA("Frame") and c.Name == "Button" then
				settingTemplate = c
				break
			end
		end
	end

	if settingsHolder and settingTemplate then
		local function makeSectionTitle(text, order, isCustom)
			local f = settingTemplate:Clone()
			f.Name = isCustom and "Section_Customization" or "Section_Delta"
			f.Parent = settingsHolder
			f.LayoutOrder = order
			for _, d in ipairs(f:GetDescendants()) do
				if d:IsA("LocalScript") then
					d:Destroy()
				end
			end
			local btn = f:FindFirstChild("Button", true)
			if btn then
				btn:Destroy()
			end
			local tLabel = f:FindFirstChild("Title", true)
			local dLabel = f:FindFirstChild("Desc", true)
			if tLabel then
				tLabel.Text = text
				if isCustom then
					tLabel.TextColor3 = Color3.fromRGB(160, 200, 255)
				else
					tLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
				end
			end
			if dLabel then
				dLabel.Text = ""
			end
			return f
		end

		makeSectionTitle("Customization", -3, true)
		makeSectionTitle("Delta settings", -1, false)
	end

	if sidebar then
		local existingGrad = sidebar:FindFirstChildOfClass("UIGradient")

		local c1
		local c2

		if existingGrad then
			local kps = existingGrad.Color.Keypoints
			c1 = (kps[1] and kps[1].Value) or Color3.fromRGB(79, 164, 242)
			c2 = (kps[#kps] and kps[#kps].Value) or Color3.fromRGB(28, 34, 46)
			sidebarGradient = existingGrad
		else
			c1 = Color3.fromRGB(79, 164, 242)
			c2 = Color3.fromRGB(28, 34, 46)
			sidebarGradient = Instance.new("UIGradient")
			sidebarGradient.Name = "DeltaCustomGradient"
			sidebarGradient.Parent = sidebar
		end

		sidebarGradient.Rotation = 100
		sidebarGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, c1),
			ColorSequenceKeypoint.new(1, c2),
		})

		sidebarGrad1 = Instance.new("Color3Value")
		sidebarGrad1.Name = "SidebarGradientColor1"
		sidebarGrad1.Value = c1

		sidebarGrad2 = Instance.new("Color3Value")
		sidebarGrad2.Name = "SidebarGradientColor2"
		sidebarGrad2.Value = c2

		sidebar:GetPropertyChangedSignal("Position"):Connect(function()
			local p = sidebar.Position
			if p.X.Scale > sidebarOpenPos.X.Scale then
				task.spawn(function()
					local last = p
					local stable = 0
					local step = 0.05
					while stable < 0.1 do
						task.wait(step)
						local cur = sidebar.Position
						if cur ~= last then
							last = cur
							stable = 0
						else
							stable = stable + step
						end
					end
					if sidebar.Parent and sidebar.Position.X.Scale > sidebarOpenPos.X.Scale then
						local cur = sidebar.Position
						sidebar.Position = UDim2.new(sidebarClosedPos.X.Scale, 0, cur.Y.Scale, cur.Y.Offset)
					end
				end)
			end
		end)
	end

	local iconColorValue
	if iconStroke then
		iconColorValue = Instance.new("Color3Value")
		iconColorValue.Name = "IconColorValue"
		iconColorValue.Value = iconBaseColor or iconStroke.Color

		iconColorValue.Changed:Connect(function()
			if not iconColorUseCustom then
				return
			end
			pcall(function()
				iconStroke.Color = iconColorValue.Value
			end)
		end)
	end

	local iconSizeValue
	if iconBtn and iconBaseSize then
		iconSizeValue = Instance.new("NumberValue")
		iconSizeValue.Name = "IconSizeValue"
		iconSizeValue.Value = 1

		local sizeCfg = settingsConfig["IconSize"]
		if type(sizeCfg) == "table" and type(sizeCfg.value) == "number" then
			iconSizeValue.Value = math.clamp(sizeCfg.value, 0.5, 5)
		end

		local function applyIconSize(v)
			v = math.clamp(v, 0.5, 5)
			if not iconBtn or not iconBaseSize then return end
			local sx = iconBaseSize.X.Scale * v
			local so = iconBaseSize.X.Offset * v
			local sy = iconBaseSize.Y.Scale * v
			local syo = iconBaseSize.Y.Offset * v
			iconBtn.Size = UDim2.new(sx, so, sy, syo)
		end

		iconSizeValue.Changed:Connect(function()
			applyIconSize(iconSizeValue.Value)
			if HS and type(writefile) == "function" then
				settingsConfig["IconSize"] = { value = math.clamp(iconSizeValue.Value, 0.5, 5) }
				local ok, encoded = pcall(function()
					return HS:JSONEncode(settingsConfig)
				end)
				if ok and encoded then
					pcall(writefile, settingsPath, encoded)
				end
			end
		end)

		applyIconSize(iconSizeValue.Value)
	end

	local iconVisible = true
	do
		local cfg = settingsConfig["IconVisible"]
		if type(cfg) == "table" and cfg.enabled ~= nil then
			iconVisible = cfg.enabled and true or false
		end
	end

	local function tweenIconVisual(imgT, bgT, instant)
		if not iconBtn then return end
		if TS and not instant then
			pcall(function()
				TS:Create(iconBtn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					ImageTransparency = imgT,
					BackgroundTransparency = bgT,
				}):Play()
			end)
		else
			pcall(function()
				iconBtn.ImageTransparency = imgT
				iconBtn.BackgroundTransparency = bgT
			end)
		end
	end

	local function applyIconUserVisibility(instant)
		if not iconBtn then return end
		if iconVisible then
			tweenIconVisual(0, 0, instant)
			if iconStroke then
				iconStroke.Enabled = true
			end
		else
			tweenIconVisual(1, 1, instant)
			if iconStroke then
				iconStroke.Enabled = false
			end
		end
	end

	local function setIconForcedHidden(hidden)
		if not iconBtn then return end
		if hidden then
			tweenIconVisual(1, 1, false)
			if iconStroke then
				iconStroke.Enabled = false
			end
		else
			applyIconUserVisibility(false)
		end
	end

	applyIconUserVisibility(true)

	local scriptHubHolder
	local homeHolder

	do
		local sh = mainGui:FindFirstChild("Scripthub")
		if sh then
			scriptHubHolder = sh:FindFirstChild("Holder")
		end

		local ho = mainGui:FindFirstChild("Home")
		if ho then
			homeHolder = ho:FindFirstChild("Holder")
		end
	end

	setupAutoScroll(settingsHolder)
	setupAutoScroll(scriptHubHolder)
	setupAutoScroll(homeHolder)

	local function makeColorSlider(id, titleText, descText, colorValue)
		if not (settingsHolder and settingTemplate and colorValue) then
			return
		end

		local key = id or titleText or ("Color_" .. tostring(math.random(1, 1e9)))
		local isIcon = (id == "IconColor") and iconStroke ~= nil

		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2

		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = titleText
		end
		if dLabel then
			dLabel.Text = descText
		end

		local oldBtn = frame:FindFirstChild("Button", true)
		local size, pos, anchor, order
		if oldBtn then
			size = oldBtn.Size
			pos = oldBtn.Position
			anchor = oldBtn.AnchorPoint
			order = oldBtn.LayoutOrder
			oldBtn:Destroy()
		end

		local basePos = pos or UDim2.new(1, -160, 0.5, 0)
		local bx, bo = basePos.X.Scale, basePos.X.Offset
		local by, byo = basePos.Y.Scale, basePos.Y.Offset

		local slider = Instance.new("Frame")
		slider.Name = "ColorSlider"
		slider.BackgroundTransparency = 1
		slider.Size = size or UDim2.new(0, 150, 0, 18)
		slider.AnchorPoint = Vector2.new(1, 0.5)
		slider.Position = UDim2.new(bx, bo - 90, by, byo)
		slider.LayoutOrder = order or 0
		slider.Parent = frame

		local valueBox = Instance.new("TextBox")
		valueBox.Name = "ColorValue"
		valueBox.Size = UDim2.new(0, 70, 0, 18)
		valueBox.AnchorPoint = Vector2.new(1, 0.5)
		valueBox.Position = UDim2.new(bx, bo, by, byo)
		valueBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		valueBox.BorderSizePixel = 0
		valueBox.ClearTextOnFocus = false
		valueBox.TextXAlignment = Enum.TextXAlignment.Center
		valueBox.Font = Enum.Font.Gotham
		valueBox.TextSize = 12
		valueBox.TextColor3 = Color3.new(1, 1, 1)
		valueBox.Parent = frame

		local toggle = Instance.new("TextButton")
		toggle.Name = "Toggle"
		toggle.Size = UDim2.new(0, 18, 0, 18)
		toggle.AnchorPoint = Vector2.new(1, 0.5)
		toggle.Position = UDim2.new(bx, bo - 200, by, byo)
		toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		toggle.BorderSizePixel = 0
		toggle.Font = Enum.Font.GothamBold
		toggle.TextSize = 11
		toggle.TextColor3 = Color3.new(1, 1, 1)
		toggle.Text = "C"
		toggle.Parent = frame

		local toggleCorner = Instance.new("UICorner")
		toggleCorner.CornerRadius = UDim.new(0, 4)
		toggleCorner.Parent = toggle

		local bar = Instance.new("Frame")
		bar.Name = "Bar"
		bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		bar.BorderSizePixel = 0
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.new(0.5, 0, 0.5, 0)
		bar.Size = UDim2.new(1, 0, 0, 6)
		bar.Parent = slider

		local barCorner = Instance.new("UICorner")
		barCorner.CornerRadius = UDim.new(0, 3)
		barCorner.Parent = bar

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BorderSizePixel = 0
		fill.AnchorPoint = Vector2.new(0, 0.5)
		fill.Position = UDim2.new(0, 0, 0.5, 0)
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.Parent = bar

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 3)
		fillCorner.Parent = fill

		local knob = Instance.new("Frame")
		knob.Name = "Knob"
		knob.Size = UDim2.new(0, 12, 0, 12)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.BackgroundColor3 = Color3.new(1, 1, 1)
		knob.BorderSizePixel = 0
		knob.Parent = bar

		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = UDim.new(1, 0)
		knobCorner.Parent = knob

		local defaultColor = colorValue and colorValue.Value or Color3.new(1, 1, 1)
		local customEnabled = true
		local lastCustomColor = defaultColor

		local saved = colorConfig[key]
		if type(saved) == "table" then
			if type(saved.customColor) == "table" and #saved.customColor == 3 then
				lastCustomColor = Color3.new(
					saved.customColor[1],
					saved.customColor[2],
					saved.customColor[3]
				)
			end
			if saved.useCustom ~= nil then
				customEnabled = saved.useCustom and true or false
			end
		end

		local function setBoxFromColor(c)
			local r = math.floor(c.R * 255 + 0.5)
			local g = math.floor(c.G * 255 + 0.5)
			local b = math.floor(c.B * 255 + 0.5)
			valueBox.Text = string.format("%d,%d,%d", r, g, b)
		end

		local function saveState()
			if not (HS and type(writefile) == "function") then return end
			colorConfig[key] = {
				useCustom = customEnabled,
				customColor = { lastCustomColor.R, lastCustomColor.G, lastCustomColor.B },
			}
			local ok, encoded = pcall(function()
				return HS:JSONEncode(colorConfig)
			end)
			if ok and encoded then
				pcall(writefile, colorsPath, encoded)
			end
		end

		local function setVisualFromColor(c)
			local h = select(1, Color3.toHSV(c)) or 0
			fill.Size = UDim2.new(h, 0, 1, 0)
			fill.BackgroundColor3 = c
			knob.Position = UDim2.new(h, 0, 0.5, 0)
			setBoxFromColor(c)
		end

		local function applyColor(c, storeCustom)
			if colorValue then
				colorValue.Value = c
			end
			if storeCustom then
				lastCustomColor = c
			end
			setVisualFromColor(c)
			saveState()
		end

		local function applyHue(alpha, storeCustom)
			alpha = math.clamp(alpha, 0, 1)
			local c = Color3.fromHSV(alpha, 0.9, 1)
			applyColor(c, storeCustom)
		end

		if customEnabled then
			if isIcon then
				iconColorUseCustom = true
			end
			applyColor(lastCustomColor, false)
			toggle.Text = "C"
		else
			if isIcon then
				iconColorUseCustom = false
				if iconStroke then
					pcall(function()
						iconStroke.Color = iconBaseColor or iconStroke.Color
					end)
				end
			end
			applyColor(defaultColor, false)
			toggle.Text = "D"
		end

		local dragging = false

		local function updateFromInput(input)
			local rel = 0
			pcall(function()
				rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
			end)
			rel = math.clamp(rel, 0, 1)
			customEnabled = true
			toggle.Text = "C"
			if isIcon then
				iconColorUseCustom = true
			end
			applyHue(rel, true)
		end

		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				updateFromInput(input)
			end
		end)

		UIS.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				updateFromInput(input)
			end
		end)

		UIS.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		valueBox.FocusLost:Connect(function()
			local txt = valueBox.Text or ""
			local r, g, b = txt:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
			r, g, b = tonumber(r), tonumber(g), tonumber(b)
			if r and g and b then
				r = math.clamp(r, 0, 255) / 255
				g = math.clamp(g, 0, 255) / 255
				b = math.clamp(b, 0, 255) / 255
				local c = Color3.new(r, g, b)
				customEnabled = true
				toggle.Text = "C"
				if isIcon then
					iconColorUseCustom = true
				end
				applyColor(c, true)
			else
				setBoxFromColor(colorValue.Value)
			end
		end)

		toggle.MouseButton1Click:Connect(function()
			if customEnabled then
				customEnabled = false
				toggle.Text = "D"
				if isIcon then
					iconColorUseCustom = false
					if iconStroke then
						pcall(function()
							iconStroke.Color = iconBaseColor or iconStroke.Color
						end)
					end
				end
				applyColor(defaultColor, false)
			else
				customEnabled = true
				toggle.Text = "C"
				if isIcon then
					iconColorUseCustom = true
				end
				applyColor(lastCustomColor or defaultColor, true)
			end
			saveState()
		end)
	end

	local function makeSizeSlider(id, titleText, descText, numValue, minV, maxV)
		if not (settingsHolder and settingTemplate and numValue) then
			return
		end

		local key = id or titleText or ("Size_" .. tostring(math.random(1, 1e9)))
		minV = minV or 0.5
		maxV = maxV or 5

		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2

		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = titleText
		end
		if dLabel then
			dLabel.Text = descText
		end

		local oldBtn = frame:FindFirstChild("Button", true)
		local size, pos, order
		if oldBtn then
			size = oldBtn.Size
			pos = oldBtn.Position
			order = oldBtn.LayoutOrder
			oldBtn:Destroy()
		end

		local basePos = pos or UDim2.new(1, -160, 0.5, 0)
		local bx, bo = basePos.X.Scale, basePos.X.Offset
		local by, byo = basePos.Y.Scale, basePos.Y.Offset

		local slider = Instance.new("Frame")
		slider.Name = "SizeSlider"
		slider.BackgroundTransparency = 1
		slider.Size = size or UDim2.new(0, 150, 0, 18)
		slider.AnchorPoint = Vector2.new(1, 0.5)
		slider.Position = UDim2.new(bx, bo - 90, by, byo)
		slider.LayoutOrder = order or 0
		slider.Parent = frame

		local valueBox = Instance.new("TextBox")
		valueBox.Name = "SizeValue"
		valueBox.Size = UDim2.new(0, 70, 0, 18)
		valueBox.AnchorPoint = Vector2.new(1, 0.5)
		valueBox.Position = UDim2.new(bx, bo, by, byo)
		valueBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		valueBox.BorderSizePixel = 0
		valueBox.ClearTextOnFocus = false
		valueBox.TextXAlignment = Enum.TextXAlignment.Center
		valueBox.Font = Enum.Font.Gotham
		valueBox.TextSize = 12
		valueBox.TextColor3 = Color3.new(1, 1, 1)
		valueBox.Parent = frame

		local bar = Instance.new("Frame")
		bar.Name = "Bar"
		bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		bar.BorderSizePixel = 0
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.new(0.5, 0, 0.5, 0)
		bar.Size = UDim2.new(1, 0, 0, 6)
		bar.Parent = slider

		local barCorner = Instance.new("UICorner")
		barCorner.CornerRadius = UDim.new(0, 3)
		barCorner.Parent = bar

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BorderSizePixel = 0
		fill.AnchorPoint = Vector2.new(0, 0.5)
		fill.Position = UDim2.new(0, 0, 0.5, 0)
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.Parent = bar

		local fillCorner = Instance.new("UICorner")
		fillCorner.CornerRadius = UDim.new(0, 3)
		fillCorner.Parent = fill

		local knob = Instance.new("Frame")
		knob.Name = "Knob"
		knob.Size = UDim2.new(0, 12, 0, 12)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.BackgroundColor3 = Color3.new(1, 1, 1)
		knob.BorderSizePixel = 0
		knob.Parent = bar

		local knobCorner = Instance.new("UICorner")
		knobCorner.CornerRadius = UDim.new(1, 0)
		knobCorner.Parent = knob

		local function saveState(v)
			if not (HS and type(writefile) == "function") then return end
			settingsConfig[key] = { value = v }
			local ok, encoded = pcall(function()
				return HS:JSONEncode(settingsConfig)
			end)
			if ok and encoded then
				pcall(writefile, settingsPath, encoded)
			end
		end

		local function setVisual(v)
			v = math.clamp(v, minV, maxV)
			local alpha = (v - minV) / (maxV - minV)
			fill.Size = UDim2.new(alpha, 0, 1, 0)
			knob.Position = UDim2.new(alpha, 0, 0.5, 0)
			valueBox.Text = string.format("%.2f", v)
		end

		local function apply(v)
			v = math.clamp(v, minV, maxV)
			numValue.Value = v
			setVisual(v)
			saveState(v)
		end

		local initial = numValue.Value
		local savedCfg = settingsConfig[key]
		if type(savedCfg) == "table" and type(savedCfg.value) == "number" then
			initial = math.clamp(savedCfg.value, minV, maxV)
			numValue.Value = initial
		end
		setVisual(initial)

		local dragging = false

		local function updateFromInput(input)
			local rel = 0
			pcall(function()
				rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
			end)
			rel = math.clamp(rel, 0, 1)
			local v = minV + (maxV - minV) * rel
			apply(v)
		end

		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				updateFromInput(input)
			end
		end)

		UIS.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				updateFromInput(input)
			end
		end)

		UIS.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		valueBox.FocusLost:Connect(function()
			local txt = valueBox.Text or ""
			local v = tonumber(txt)
			if v then
				apply(v)
			else
				setVisual(numValue.Value)
			end
		end)
	end

	local function makeIconRgbToggle()
		if not (settingsHolder and settingTemplate and iconBtn and iconStroke) then
			return
		end

		local key = "IconRGB"

		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2

		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end

		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "RGB icon"
		end
		if dLabel then
			dLabel.Text = "Rainbow outline on the Delta icon."
		end

		local btnFrame = frame:FindFirstChild("Button", true)
		if not btnFrame then return end
		local btnLabel = btnFrame:FindFirstChildWhichIsA("TextLabel")
		if btnLabel then
			btnLabel.Text="Toggle"
		end

		local clickable = btnFrame:FindFirstChildWhichIsA("GuiButton") or btnFrame

		local saved = settingsConfig[key]
		local enabled = false
		if type(saved) == "table" and saved.enabled ~= nil then
			enabled = saved.enabled and true or false
		end

		local hue = 0

		local function saveState()
			if not (HS and type(writefile) == "function") then return end
			settingsConfig[key] = {
				enabled = enabled,
			}
			local ok, encoded = pcall(function()
				return HS:JSONEncode(settingsConfig)
			end)
			if ok and encoded then
				pcall(writefile, settingsPath, encoded)
			end
		end

		local function setVisualToggle()
			if enabled then
				btnFrame.BackgroundColor3 = Color3.fromRGB(79, 164, 242)
			else
				btnFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			end
		end

		local function startLoop()
			NAlib.disconnect("IconRGB_Loop")
			NAlib.connect("IconRGB_Loop", RS.Heartbeat:Connect(function(dt)
				hue = (hue + dt * 0.2) % 1
				local c = Color3.fromHSV(hue, 1, 1)
				pcall(function()
					iconStroke.Color = c
				end)
			end))
		end

		local function stopLoop()
			NAlib.disconnect("IconRGB_Loop")
			pcall(function()
				if iconColorUseCustom and iconColorValue then
					iconStroke.Color = iconColorValue.Value
				else
					iconStroke.Color = iconBaseColor or iconStroke.Color
				end
			end)
		end

		local function applyState()
			setVisualToggle()
			if enabled then
				startLoop()
			else
				stopLoop()
			end
			saveState()
		end

		applyState()

		local function toggleClick()
			enabled = not enabled
			applyState()
		end

		if clickable:IsA("GuiButton") then
			clickable.MouseButton1Click:Connect(toggleClick)
		else
			clickable.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					toggleClick()
				end
			end)
		end
	end

	local function makeIconVisibilityToggle()
		if not (settingsHolder and settingTemplate and iconBtn) then
			return
		end

		local key = "IconVisible"

		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2

		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end

		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "Icon visibility"
		end
		if dLabel then
			dLabel.Text = "Makes the Delta icon invisible"
		end

		local btnFrame = frame:FindFirstChild("Button", true)
		if not btnFrame then return end
		local btnLabel = btnFrame:FindFirstChildWhichIsA("TextLabel")
		if btnLabel then
			btnLabel.Text="Toggle"
		end

		local clickable = btnFrame:FindFirstChildWhichIsA("GuiButton") or btnFrame

		local function saveState()
			if not (HS and type(writefile) == "function") then return end
			settingsConfig[key] = {
				enabled = iconVisible,
			}
			local ok, encoded = pcall(function()
				return HS:JSONEncode(settingsConfig)
			end)
			if ok and encoded then
				pcall(writefile, settingsPath, encoded)
			end
		end

		local function setVisual()
			if iconVisible then
				btnFrame.BackgroundColor3 = Color3.fromRGB(79, 164, 242)
			else
				btnFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			end
		end

		setVisual()

		local function toggleClick()
			iconVisible = not iconVisible
			applyIconUserVisibility(false)
			setVisual()
			saveState()
		end

		if clickable:IsA("GuiButton") then
			clickable.MouseButton1Click:Connect(toggleClick)
		else
			clickable.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					toggleClick()
				end
			end)
		end
	end

	local function makeDestroyUIButton()
		if not (settingsHolder and settingTemplate) then
			return
		end

		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2

		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end

		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "Destroy Delta UI"
			tLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		end
		if dLabel then
			dLabel.Text = "Deletes Delta's UI and icon until you rejoin."
			dLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
		end

		local btnFrame = frame:FindFirstChild("Button", true)
		if not btnFrame then return end
		local btnLabel = btnFrame:FindFirstChildWhichIsA("TextLabel")
		if btnLabel then
			btnLabel.Text="KILL"
		end
		btnFrame.BackgroundColor3 = Color3.fromRGB(255, 80, 80)

		local clickable = btnFrame:FindFirstChildWhichIsA("GuiButton") or btnFrame

		local function click()
			if iconGui then
				pcall(function() iconGui:Destroy() end)
				iconGui = nil
			end
			if mainGui then
				pcall(function() mainGui:Destroy() end)
				mainGui = nil
			end
		end

		if clickable:IsA("GuiButton") then
			clickable.MouseButton1Click:Connect(click)
		else
			clickable.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					click()
				end
			end)
		end
	end

	local sidebarClosedPos = UDim2.new(1.08, 0, 0.474000007, 0)
	local sidebarOpenPos   = UDim2.new(1,          0, 0.474000007, 0)

	local sidebarGestureEnabled = false
	local sidebarGestureVisible = true
	local sidebarGestureWidth = 18
	local sidebarGestureHeight = 120
	local sidebarGestureFrame
	local sidebarDragActive = false
	local sidebarDragStartX = 0
	local sidebarDragStartAlpha = 0
	local sidebarDragAlpha  = 0
	local sidebarCurrentSection = nil
	local autoCloseOnLoad = true

	local sectionsList = { "Executor", "Home", "Scripthub", "Settings", "Console" }

	local gestureWidthValue = Instance.new("NumberValue")
	gestureWidthValue.Name = "GestureWidthValue"
	gestureWidthValue.Value = sidebarGestureWidth

	local gestureHeightValue = Instance.new("NumberValue")
	gestureHeightValue.Name = "GestureHeightValue"
	gestureHeightValue.Value = sidebarGestureHeight

	do
		local cfg = settingsConfig["GestureWidth"]
		if type(cfg) == "table" and type(cfg.value) == "number" then
			gestureWidthValue.Value = math.clamp(cfg.value, 6, 80)
		end
	end

	do
		local cfg = settingsConfig["GestureHeight"]
		if type(cfg) == "table" and type(cfg.value) == "number" then
			gestureHeightValue.Value = math.clamp(cfg.value, 60, 400)
		end
	end

	do
		local cfg = settingsConfig["SidebarGesture"]
		if type(cfg) == "table" and cfg.enabled ~= nil then
			sidebarGestureEnabled = cfg.enabled and true or false
		end
	end

	do
		local cfg = settingsConfig["SidebarGestureVisible"]
		if type(cfg) == "table" and cfg.enabled ~= nil then
			sidebarGestureVisible = cfg.enabled and true or false
		end
	end

	do
		local cfg = settingsConfig["AutoCloseOnLoad"]
		if type(cfg) == "table" and cfg.enabled ~= nil then
			autoCloseOnLoad = cfg.enabled and true or false
		end
	end

	local function closeDeltaSidebar()
		if sidebar then
			sidebar.Position = sidebarClosedPos
		end

		if mainGui then
			for _, n in ipairs(sectionsList) do
				local fr = mainGui:FindFirstChild(n)
				if fr and fr:IsA("GuiObject") then
					fr.Visible = false
				end
			end
		end

		if iconGui then
			iconGui.Enabled = true
		end

		setIconForcedHidden(false)
	end

	local function saveSidebarGesture()
		if not (HS and type(writefile) == "function") then return end
		settingsConfig["SidebarGesture"] = { enabled = sidebarGestureEnabled }
		local ok, encoded = pcall(function()
			return HS:JSONEncode(settingsConfig)
		end)
		if ok and encoded then
			pcall(writefile, settingsPath, encoded)
		end
	end

	local function saveSidebarGestureVisible()
		if not (HS and type(writefile) == "function") then return end
		settingsConfig["SidebarGestureVisible"] = { enabled = sidebarGestureVisible }
		local ok, encoded = pcall(function()
			return HS:JSONEncode(settingsConfig)
		end)
		if ok and encoded then
			pcall(writefile, settingsPath, encoded)
		end
	end

	local function applyGestureVisual()
		if sidebarGestureFrame then
			sidebarGestureFrame.BackgroundTransparency = sidebarGestureVisible and 0.4 or 1
		end
	end

	local function applyGestureSize()
		if not sidebarGestureFrame then return end
		local h = gestureHeightValue and gestureHeightValue.Value or sidebarGestureHeight
		h = math.clamp(h, 60, 400)
		local w = gestureWidthValue and gestureWidthValue.Value or sidebarGestureWidth
		w = math.clamp(w, 6, 80)
		if UIS and UIS.TouchEnabled then
			w = math.floor(w * 1.6)
		end
		sidebarGestureFrame.Size = UDim2.new(0, w, 0, h)
	end

	gestureWidthValue.Changed:Connect(function()
		if sidebarGestureFrame then
			applyGestureSize()
		end
	end)

	gestureHeightValue.Changed:Connect(function()
		if sidebarGestureFrame then
			applyGestureSize()
		end
	end)

	local function ensureSidebarGestureFrame()
		if sidebarGestureFrame or not (sidebar and mainGui) then return end

		local f = Instance.new("Frame")
		sidebarGestureFrame = f
		f.Name = "SidebarGestureZone"
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(1, 0.5)
		f.Size = UDim2.new(0, sidebarGestureWidth, 0, sidebarGestureHeight)
		f.Active = false
		f.Visible = false
		f.Parent = mainGui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = f

		applyGestureSize()
		applyGestureVisual()
	end

	local function makeSidebarGestureToggle()
		if not (settingsHolder and settingTemplate and sidebar) then
			return
		end

		local key = "SidebarGesture"

		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2

		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end

		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "Sidebar gesture"
		end
		if dLabel then
			dLabel.Text = "Drag from the right edge to open/close the sidebar"
		end

		local btnFrame = frame:FindFirstChild("Button", true)
		if not btnFrame then return end
		local btnLabel = btnFrame:FindFirstChildWhichIsA("TextLabel")
		if btnLabel then
			btnLabel.Text="Toggle"
		end

		local clickable = btnFrame:FindFirstChildWhichIsA("GuiButton") or btnFrame

		local function setVisual()
			if sidebarGestureEnabled then
				btnFrame.BackgroundColor3 = Color3.fromRGB(79, 164, 242)
			else
				btnFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			end
		end

		setVisual()

		local function toggleClick()
			sidebarGestureEnabled = not sidebarGestureEnabled
			setVisual()
			saveSidebarGesture()
			if not sidebarGestureEnabled then
				if iconGui then
					iconGui.Enabled = true
				end
				setIconForcedHidden(false)
			end
			task.defer(function()
				if applySidebarGestureState then
					applySidebarGestureState()
				end
			end)
		end

		if clickable:IsA("GuiButton") then
			clickable.MouseButton1Click:Connect(toggleClick)
		else
			clickable.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					toggleClick()
				end
			end)
		end
	end

	local function makeSidebarGestureBarVisibilityToggle()
		if not (settingsHolder and settingTemplate) then
			return
		end

		local key = "SidebarGestureVisible"

		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2

		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end

		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "Gesture bar visible"
		end
		if dLabel then
			dLabel.Text = "Hide the sidebar gesture bar but keep it usable"
		end

		local btnFrame = frame:FindFirstChild("Button", true)
		if not btnFrame then return end
		local btnLabel = btnFrame:FindFirstChildWhichIsA("TextLabel")
		if btnLabel then
			btnLabel.Text="Toggle"
		end

		local clickable = btnFrame:FindFirstChildWhichIsA("GuiButton") or btnFrame

		local function setVisual()
			if sidebarGestureVisible then
				btnFrame.BackgroundColor3 = Color3.fromRGB(79, 164, 242)
			else
				btnFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			end
		end

		setVisual()
		applyGestureVisual()

		local function toggleClick()
			sidebarGestureVisible = not sidebarGestureVisible
			setVisual()
			applyGestureVisual()
			saveSidebarGestureVisible()
		end

		if clickable:IsA("GuiButton") then
			clickable.MouseButton1Click:Connect(toggleClick)
		else
			clickable.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					toggleClick()
				end
			end)
		end
	end

	local function makeAutoCloseToggle()
		if not (settingsHolder and settingTemplate and sidebar) then
			return
		end

		local key = "AutoCloseOnLoad"

		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2

		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end

		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "Auto-close on load"
		end
		if dLabel then
			dLabel.Text = "Close the Delta sidebar right after it loads"
		end

		local btnFrame = frame:FindFirstChild("Button", true)
		if not btnFrame then return end

		local btnLabel = btnFrame:FindFirstChildWhichIsA("TextLabel")
		if btnLabel then
			btnLabel.Text = "Toggle"
		end

		local clickable = btnFrame:FindFirstChildWhichIsA("GuiButton") or btnFrame

		local function saveState()
			if not (HS and type(writefile) == "function") then return end
			settingsConfig[key] = {
				enabled = autoCloseOnLoad,
			}
			local ok, encoded = pcall(function()
				return HS:JSONEncode(settingsConfig)
			end)
			if ok and encoded then
				pcall(writefile, settingsPath, encoded)
			end
		end

		local function setVisual()
			if autoCloseOnLoad then
				btnFrame.BackgroundColor3 = Color3.fromRGB(79, 164, 242)
			else
				btnFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
			end
		end

		setVisual()

		local function toggleClick()
			autoCloseOnLoad = not autoCloseOnLoad
			setVisual()
			saveState()
		end

		if clickable:IsA("GuiButton") then
			clickable.MouseButton1Click:Connect(toggleClick)
		else
			clickable.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					toggleClick()
				end
			end)
		end
	end

	local function getCurrentSectionName()
		if not mainGui then return nil end
		local cur
		for _, name in ipairs(sectionsList) do
			local fr = mainGui:FindFirstChild(name)
			if fr and fr:IsA("GuiObject") and fr.Visible then
				cur = name
			end
		end
		return cur
	end

	function applySidebarGestureState()
		if not sidebar then
			sidebarGestureEnabled = false
			saveSidebarGesture()
			return
		end

		ensureSidebarGestureFrame()

		if not sidebarGestureFrame then
			sidebarGestureEnabled = false
			saveSidebarGesture()
			return
		end

		if toggleUIBtn and toggleUIBtn:IsA("ImageButton") then
			pcall(function()
				toggleUIBtn.Visible = not sidebarGestureEnabled
			end)
		end

		NAlib.disconnect("SidebarGesture")
		sidebarGestureFrame.Active = false
		sidebarGestureFrame.Visible = false

		if not sidebarGestureEnabled then
			saveSidebarGesture()
			return
		end

		sidebarGestureFrame.Active = true
		sidebarGestureFrame.Visible = true
		applyGestureVisual()
		applyGestureSize()

		local id = "SidebarGesture"

		local function recalcGesturePosition()
			if not (mainGui and sidebar and sidebarGestureFrame) then return end
			local sgSize = mainGui.AbsoluteSize
			if sgSize.X <= 0 or sgSize.Y <= 0 then return end

			local sbPos = sidebar.AbsolutePosition
			local sbSize = sidebar.AbsoluteSize

			local offset = 8
			local px = sbPos.X - offset
			local py = sbPos.Y + sbSize.Y * 0.5

			local sx = px / sgSize.X
			local sy = py / sgSize.Y

			sidebarGestureFrame.Position = UDim2.new(sx, 0, sy, 0)
		end

		local function getSidebarAlpha()
			if not sidebar then return 0 end
			local sx = sidebar.Position.X.Scale
			local denom = sidebarClosedPos.X.Scale - sidebarOpenPos.X.Scale
			if denom == 0 then return 0 end
			local a = (sidebarClosedPos.X.Scale - sx) / denom
			return math.clamp(a, 0, 1)
		end

		recalcGesturePosition()

		NAlib.connect(id, sidebar:GetPropertyChangedSignal("Position"):Connect(recalcGesturePosition))
		if sidebar.GetPropertyChangedSignal then
			NAlib.connect(id, sidebar:GetPropertyChangedSignal("Size"):Connect(recalcGesturePosition))
		end
		if mainGui and mainGui.GetPropertyChangedSignal then
			NAlib.connect(id, mainGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(recalcGesturePosition))
		end

		local function updateSidebarFromInput(input)
			if not sidebar or not mainGui then return end

			local dx = input.Position.X - sidebarDragStartX

			local guiSize = mainGui.AbsoluteSize
			local dist = guiSize.X * math.abs(sidebarClosedPos.X.Scale - sidebarOpenPos.X.Scale)
			if dist <= 0 then
				dist = 100
			end

			local alpha = sidebarDragStartAlpha - dx / dist
			alpha = math.clamp(alpha, 0, 1)
			sidebarDragAlpha = alpha

			local sx = sidebarClosedPos.X.Scale + (sidebarOpenPos.X.Scale - sidebarClosedPos.X.Scale) * alpha
			sidebar.Position = UDim2.new(sx, 0, sidebarClosedPos.Y.Scale, sidebarClosedPos.Y.Offset)
		end

		NAlib.connect(id, sidebarGestureFrame.InputBegan:Connect(function(input)
			if not sidebarGestureEnabled then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			sidebarDragAlpha = getSidebarAlpha()
			sidebarDragStartAlpha = sidebarDragAlpha
			sidebarDragStartX = input.Position.X
			sidebarDragActive = true
		end))

		NAlib.connect(id, UIS.InputChanged:Connect(function(input)
			if not sidebarDragActive or not sidebarGestureEnabled then return end
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then
				updateSidebarFromInput(input)
			end
		end))

		NAlib.connect(id, UIS.InputEnded:Connect(function(input)
			if not sidebarDragActive or not sidebarGestureEnabled then
				return
			end

			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			sidebarDragActive = false

			local curSec = getCurrentSectionName()
			if curSec then
				sidebarCurrentSection = curSec
			end

			local targetPos = sidebarClosedPos
			if sidebarDragAlpha > 0.5 then
				targetPos = sidebarOpenPos
			end

			if TS and sidebar then
				local tw = TS:Create(
					sidebar,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Position = targetPos }
				)
				tw:Play()
			else
				if sidebar then
					sidebar.Position = targetPos
				end
			end

			if targetPos == sidebarOpenPos then
				if not sidebarCurrentSection then
					sidebarCurrentSection = getCurrentSectionName() or "Executor"
				end

				if iconGui then
					iconGui.Enabled = false
				end

				setIconForcedHidden(true)

				if mainGui and sidebarCurrentSection then
					for _, n in ipairs(sectionsList) do
						local fr = mainGui:FindFirstChild(n)
						if fr and fr:IsA("GuiObject") then
							fr.Visible = (n == sidebarCurrentSection)
						end
					end
				end
			else
				if mainGui then
					if curSec then
						sidebarCurrentSection = curSec
					end
					for _, n in ipairs(sectionsList) do
						local fr = mainGui:FindFirstChild(n)
						if fr and fr:IsA("GuiObject") then
							fr.Visible = false
						end
					end
				end

				if iconGui then
					iconGui.Enabled = true
				end

				setIconForcedHidden(false)
			end
		end))

		saveSidebarGesture()
	end

	if toggleUIBtn and toggleUIBtn:IsA("GuiButton") then
		toggleUIBtn.MouseButton1Click:Connect(function()
			if iconGui then
				iconGui.Enabled = true
			end
			setIconForcedHidden(false)
		end)
	end

	if activeColorValue then
		makeColorSlider(
			"ActiveColor",
			"Active Color",
			"Sidebar active button color",
			activeColorValue
		)
	end

	if inactiveColorValue then
		makeColorSlider(
			"InactiveColor",
			"Inactive Color",
			"Sidebar inactive button color",
			inactiveColorValue
		)
	end

	if iconColorValue then
		makeColorSlider(
			"IconColor",
			"Icon Color",
			"Custom color for the Delta icon",
			iconColorValue
		)
	end

	if iconSizeValue then
		makeSizeSlider(
			"IconSize",
			"Icon Size",
			"Scale the Delta icon size",
			iconSizeValue,
			0.5,
			5
		)
	end

	if sidebarGrad1 and sidebarGrad2 and sidebarGradient then
		makeColorSlider(
			"SidebarGradient1",
			"Sidebar Gradient 1",
			"First sidebar gradient color",
			sidebarGrad1
		)

		makeColorSlider(
			"SidebarGradient2",
			"Sidebar Gradient 2",
			"Second sidebar gradient color",
			sidebarGrad2
		)

		local function updateSidebarGradient()
			sidebarGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, sidebarGrad1.Value),
				ColorSequenceKeypoint.new(1, sidebarGrad2.Value),
			})
		end

		updateSidebarGradient()

		sidebarGrad1:GetPropertyChangedSignal("Value"):Connect(updateSidebarGradient)
		sidebarGrad2:GetPropertyChangedSignal("Value"):Connect(updateSidebarGradient)
	end

	makeIconVisibilityToggle()
	makeIconRgbToggle()
	makeSidebarGestureToggle()
	makeSidebarGestureBarVisibilityToggle()

	if gestureWidthValue then
		makeSizeSlider(
			"GestureWidth",
			"Gesture width",
			"Width of the sidebar gesture area",
			gestureWidthValue,
			6,
			80
		)
	end

	if gestureHeightValue then
		makeSizeSlider(
			"GestureHeight",
			"Gesture height",
			"Height of the sidebar gesture area",
			gestureHeightValue,
			60,
			400
		)
	end

	makeAutoCloseToggle()
	makeDestroyUIButton()
	applySidebarGestureState()

	if autoCloseOnLoad then
		task.defer(function()
			pcall(function()
				closeDeltaSidebar()
				if iconGui then
					iconGui.Enabled = true
				end
				setIconForcedHidden(false)
			end)
		end)
	end

	local sidemenu = execFrame:FindFirstChild("Sidemenu", true)
	if sidemenu then
		local oldCard = sidemenu:FindFirstChild("Script", true)
		if oldCard and oldCard:IsA("ImageLabel") then
			local parent = oldCard.Parent
			local newCard = oldCard:Clone()
			oldCard:Destroy()
			newCard.Parent = parent
			newCard.Name = "Script"

			local labs = {}
			for _, d in ipairs(newCard:GetDescendants()) do
				if d:IsA("TextLabel") then
					table.insert(labs, d)
				end
			end

			if #labs >= 3 then
				table.sort(labs, function(a, b)
					return a.AbsolutePosition.Y < b.AbsolutePosition.Y
				end)

				local bigHeader = labs[1]
				local subTitle = labs[2]
				local desc = labs[3]

				if bigHeader then
					bigHeader.Text = "Featured"
				end
				if subTitle then
					subTitle.Text = "Nameless Admin"
				end
				if desc then
					desc.Text = "continuation of Nameless Admin with advanced features, fixed commands and lots of customization."
				end
			end

			local clickable = nil

			for _, d in ipairs(newCard:GetDescendants()) do
				if d:IsA("LocalScript") then
					d:Destroy()
				elseif d:IsA("TextButton") then
					clickable = d
				end
			end

			if not clickable then clickable = newCard:FindFirstChildWhichIsA("GuiButton") or newCard:FindFirstChildWhichIsA("GuiButton",true) or newCard end
			local function runNA()
				pcall(function()
					loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua"))()
				end)
			end
			if clickable:IsA("GuiButton") then
				clickable.MouseButton1Click:Connect(runNA)
			else
				clickable.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch then
						runNA()
					end
				end)
			end
		end
	end

	local pingLabel
	do
		local nFrame = sidemenu and sidemenu:FindFirstChild("Network", true)
		if nFrame then
			local overlayNet = nFrame:FindFirstChild("Overlay", true)
			local holderNet = overlayNet and overlayNet:FindFirstChild("Holder", true)
			local infoNet = holderNet and holderNet:FindFirstChild("Information", true)
			pingLabel = infoNet and infoNet:FindFirstChild("Ping")
		end
	end

	if pingLabel and Stats and RS then
		local net = Stats.Network
		local item = net and net.ServerStatsItem and net.ServerStatsItem["Data Ping"]
		if item then
			pingLabel.RichText = true
			local id = "DeltaCustom_Ping"

			NAlib.disconnect(id)

			local function updatePing()
				local v = 0
				pcall(function()
					if item.GetValue then
						v = item:GetValue()
					elseif item.Value ~= nil then
						v = item.Value
					end
				end)
				v = math.floor(tonumber(v) or 0)
				pingLabel.Text = string.format('<font color="#4FA4F2">%d</font> MS Ping', v)
			end

			updatePing()

			NAlib.connect(id, RS.Heartbeat:Connect(function()
				updatePing()
			end))
		end
	end

	local tabs = overlay:FindFirstChild("Tabs", true)
	local codeSf = overlay:FindFirstChild("Code", true)
	if not tabs then
		notify({
			Title = "Delta Customization",
			Description = "Tabs frame not found.",
			Duration = 4,
		})
		return
	end
	if not codeSf then
		notify({
			Title = "Delta Customization",
			Description = "Code frame not found.",
			Duration = 4,
		})
		return
	end

	local btns = overlay:FindFirstChild("Buttons", true)
	if btns then
		local bl = {}
		for _, v in ipairs(btns:GetChildren()) do
			if v:IsA("ImageButton") or v:IsA("TextButton") then
				table.insert(bl, v)
			end
		end

		local tpl = btns:FindFirstChild("ExecuteClipboard") or btns:FindFirstChild("Execute") or bl[1]
		if tpl then
			local cp = tpl:Clone()
			cp.Name = "CopyCode"
			local tl = cp:FindFirstChild("Title", true) or cp:FindFirstChildWhichIsA("TextLabel")
			if tl then
				tl.Text = "COPY CODE"
			end
			cp.Parent = btns
			table.insert(bl, cp)

			local cnt = #bl
			if cnt > 0 then
				local w
				if cnt == 4 then
					w = 0.22
				else
					w = 1 / cnt
				end
				for _, b in ipairs(bl) do
					b.Size = UDim2.new(w, 0, 1, 0)
				end
			end

			cp.MouseButton1Click:Connect(function()
				if type(setclipboard) ~= "function" then
					return
				end
				local cur
				for _, tb in ipairs(codeSf:GetDescendants()) do
					if tb:IsA("TextBox") and tb.Visible then
						cur = tb
						break
					end
				end
				if cur then
					setclipboard(cur.Text or "")
					notify({
						Title = "Delta Customization",
						Description = "Copied code from the selected tab.",
						Duration = 4,
					})
				end
			end)
		end
	end

	local hasFS = type(isfolder) == "function"
		and type(makefolder) == "function"
		and type(isfile) == "function"
		and type(writefile) == "function"
		and type(readfile) == "function"
		and type(listfiles) == "function"

	if not hasFS then
		notify({
			Title = "Delta Customization",
			Description = "Your executor does not support saving tabs.",
			Duration = 5,
		})
		return
	end

	local rootDir = "DeltaCustom"
	local tabsDir = rootDir .. "/DeltaTabs"

	if not isfolder(rootDir) then
		pcall(function() makefolder(rootDir) end)
	end
	if not isfolder(tabsDir) then
		pcall(function() makefolder(tabsDir) end)
	end

	local function parseIndex(nm)
		local n = nm:match("^script(%d+)%.lua$")
		return tonumber(n)
	end

	local function isScriptName(nm)
		return parseIndex(nm) ~= nil
	end

	local function getCodeBoxes()
		local t = {}
		for _, c in ipairs(codeSf:GetDescendants()) do
			if c:IsA("TextBox") and isScriptName(c.Name) then
				table.insert(t, c)
			end
		end
		table.sort(t, function(a, b)
			return (parseIndex(a.Name) or 0) < (parseIndex(b.Name) or 0)
		end)
		return t
	end

	local function getSavedNames()
		local list = {}
		for _, p in ipairs(listfiles(tabsDir)) do
			local nm = p:match("([^/\\]+)$")
			if nm and isScriptName(nm) then
				table.insert(list, nm)
			end
		end
		table.sort(list, function(a, b)
			return (parseIndex(a) or 0) < (parseIndex(b) or 0)
		end)
		return list
	end

	local saved = getSavedNames()
	local boxes = getCodeBoxes()

	if #saved > 0 then
		local desc
		if #saved > #boxes then
			desc = "Saved tabs: " .. tostring(#saved) .. "\nCreate your tabs in Delta and the saved code will load automatically."
		else
			desc = "Saved tabs: " .. tostring(#saved) .. "\nYour saved code will load into matching tabs automatically."
		end
		notify({
			Title = "Delta Customization",
			Description = desc,
			Duration = 8,
		})
	else
		notify({
			Title = "Delta Customization",
			Description = "No saved tabs yet. Anything you type will be saved automatically.",
			Duration = 6,
		})
	end

	local hooked = {}

	local function hookBox(box)
		if not box or hooked[box] then return end
		hooked[box] = true

		local ready = false

		local function setupForName(nm)
			if ready then return end
			if not isScriptName(nm) then
				return
			end

			ready = true
			local nameForFile = nm
			local path = tabsDir .. "/" .. nameForFile

			if isfile(path) then
				local ok, data = pcall(readfile, path)
				if ok and type(data) == "string" then
					box.Text = data
				end
			end

			local last = 0
			box:GetPropertyChangedSignal("Text"):Connect(function()
				last = tick()
				local id = last
				task.delay(0.4, function()
					if id ~= last then return end
					local txt = box.Text
					pcall(function()
						writefile(path, txt)
					end)
				end)
			end)
		end

		setupForName(box.Name)

		box:GetPropertyChangedSignal("Name"):Connect(function()
			setupForName(box.Name)
		end)
	end

	for _, b in ipairs(boxes) do
		hookBox(b)
	end

	codeSf.DescendantAdded:Connect(function(obj)
		if obj:IsA("TextBox") then
			task.wait(0.05)
			hookBox(obj)
		end
	end)

	codeSf.DescendantRemoving:Connect(function(obj)
		if obj:IsA("TextBox") and isScriptName(obj.Name) and type(delfile) == "function" then
			local path = tabsDir .. "/" .. obj.Name
			if isfile(path) then
				pcall(function()
					delfile(path)
				end)
			end
		end
	end)
end)
