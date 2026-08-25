local __lt = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {}
	local sharedEnv = rawget(_G, "shared")
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil)
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver")
		if type(cached) == "table" then
			return cached
		end
	end
	local loader = loadstring or load
	if type(loader) ~= "function" then
		error("Service resolver loader unavailable")
	end
	local resolver = loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau")
	if type(resolver) ~= "function" then
		error("Service resolver failed to compile")
	end
	local loaded = resolver()
	if type(loaded) ~= "table" then
		error("Service resolver failed to load")
	end
	if cacheHost then
		cacheHost.__lt_service_resolver = loaded
	end
	return loaded
end)()

local __NAUIProtector = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {}
	local sharedEnv = rawget(_G, "shared")
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil)
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_ui_protector")
		if type(cached) == "table" then
			return cached
		end
	end
	local loader = loadstring or load
	if type(loader) ~= "function" then
		return nil
	end
	local okSource, source = pcall(function()
		return game:HttpGet("https://ltseverydayyou.github.io/UIprotector.luau")
	end)
	if not okSource or type(source) ~= "string" or source == "" then
		return nil
	end
	local chunk = loader(source, "@UIprotector.luau")
	if type(chunk) ~= "function" then
		return nil
	end
	local okLoaded, loaded = pcall(chunk)
	if okLoaded and type(loaded) == "table" then
		if cacheHost then
			cacheHost.__lt_ui_protector = loaded
		end
		return loaded
	end
	return nil
end)()

local function __NAProtectUI(gui, options)
	if __NAUIProtector and type(__NAUIProtector.protectUI) == "function" then
		local ok, protected = pcall(__NAUIProtector.protectUI, gui, options)
		if ok and protected then
			return protected
		end
	end
	return nil
end

local function __NAProtectedParent(fallback)
	if __NAUIProtector and type(__NAUIProtector.parent) == "function" then
		local ok, parent = pcall(__NAUIProtector.parent)
		if ok and typeof(parent) == "Instance" then
			return parent
		end
	end
	if __NAUIProtector and type(__NAUIProtector.huiGrabber) == "function" then
		local ok, parent = pcall(__NAUIProtector.huiGrabber)
		if ok and typeof(parent) == "Instance" then
			return parent
		end
	end
	if typeof(fallback) == "Instance" then
		return fallback
	end
	return nil
end

local Players = __lt.cs("Players", cloneref)
local UserInputService = __lt.cs("UserInputService", cloneref)
local TweenService = __lt.cs("TweenService", cloneref)
local MarketplaceService = __lt.cs("MarketplaceService", cloneref)
local SoundService = __lt.cs("SoundService", cloneref)
local Lighting = __lt.cs("Lighting", cloneref)
local Workspace = __lt.cs("Workspace", cloneref)
local HttpService = __lt.cs("HttpService", cloneref)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local env = (getgenv and getgenv()) or _G
local appKey = "__na_audio_logger_state"
local previous = type(env) == "table" and rawget(env, appKey) or nil
if type(previous) == "table" and type(previous.clean) == "function" then
	pcall(previous.clean)
end

local alive = true
local state = {}
if type(env) == "table" then
	rawset(env, appKey, state)
end

local connections = {}
local function connect(signal, callback)
	if not alive or not signal then
		return nil
	end
	local connection = signal:Connect(callback)
	connections[#connections + 1] = connection
	return connection
end

local function disconnectAll()
	for i = #connections, 1, -1 do
		local connection = connections[i]
		connections[i] = nil
		pcall(function()
			connection:Disconnect()
		end)
	end
end

local function create(className, parent, props)
	local instance = Instance.new(className)
	if props then
		for key, value in pairs(props) do
			instance[key] = value
		end
	end
	instance.Parent = parent
	return instance
end

local function round(parent, radius)
	return create("UICorner", parent, { CornerRadius = UDim.new(0, radius or 10) })
end

local function outline(parent, transparency, thickness)
	return create("UIStroke", parent, {
		Color = Color3.fromRGB(255, 255, 255),
		Transparency = transparency or 0.8,
		Thickness = thickness or 1,
	})
end

local COLORS = {
	root = Color3.fromRGB(18, 18, 24),
	top = Color3.fromRGB(13, 13, 19),
	panel = Color3.fromRGB(23, 23, 31),
	panel2 = Color3.fromRGB(28, 28, 38),
	button = Color3.fromRGB(35, 35, 45),
	buttonHover = Color3.fromRGB(50, 50, 62),
	red = Color3.fromRGB(220, 50, 50),
	redHover = Color3.fromRGB(255, 70, 70),
	green = Color3.fromRGB(40, 120, 80),
	greenHover = Color3.fromRGB(55, 155, 100),
	text = Color3.fromRGB(240, 240, 245),
	subtext = Color3.fromRGB(174, 180, 196),
	muted = Color3.fromRGB(125, 132, 150),
	selected = Color3.fromRGB(48, 53, 74),
}

local function isMobile()
	local platform = __lt.cm("UserInputService", "GetPlatform")
	if platform == Enum.Platform.IOS
		or platform == Enum.Platform.Android
		or platform == Enum.Platform.AndroidTV
		or platform == Enum.Platform.Chromecast
		or platform == Enum.Platform.MetaOS then
		return true
	end
	if platform == Enum.Platform.None then
		return UserInputService.TouchEnabled and not (UserInputService.KeyboardEnabled or UserInputService.MouseEnabled)
	end
	return UserInputService.TouchEnabled and not (UserInputService.KeyboardEnabled or UserInputService.MouseEnabled)
end

local function centerFrame(frame, viewport)
	if not frame then
		return false
	end
	viewport = viewport or (Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize)
	if typeof(viewport) ~= "Vector2" or viewport.X <= 0 or viewport.Y <= 0 then
		return false
	end
	local size = frame.AbsoluteSize
	if typeof(size) ~= "Vector2" or size.X <= 0 or size.Y <= 0 then
		size = Vector2.new(frame.Size.X.Offset, frame.Size.Y.Offset)
	end
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.Position = UDim2.fromOffset(
		math.floor((viewport.X - size.X) * 0.5),
		math.floor((viewport.Y - size.Y) * 0.5)
	)
	return true
end

local gui = create("ScreenGui", nil, {
	Name = "AudioLogger",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
	DisplayOrder = 1000,
})
if not __NAProtectUI(gui, { keepName = false }) then
	gui.Parent = (gethui and gethui()) or __lt.cs("CoreGui", cloneref) or PlayerGui
end

local root = create("Frame", gui, {
	Name = "Root",
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromOffset(780, 540),
	BackgroundColor3 = COLORS.root,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Active = true,
})
round(root, 8)
outline(root, 0.74, 2)
create("UIGradient", root, {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 24, 34)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 20)),
	}),
	Rotation = 90,
})

local top = create("Frame", root, {
	Name = "Topbar",
	Size = UDim2.new(1, 0, 0, 52),
	BackgroundColor3 = COLORS.top,
	BorderSizePixel = 0,
	Active = true,
})
local title = create("TextLabel", top, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(18, 0),
	Size = UDim2.new(1, -180, 1, 0),
	Font = Enum.Font.GothamSemibold,
	TextSize = 17,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.text,
	Text = "Audio Logger",
})

local BUILDER_ICON_FONT_PATH = "rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json"

local function dropdownButtonText(text)
	return string.format('%s  <font family="%s">caret-small-down</font>', tostring(text or ""), BUILDER_ICON_FONT_PATH)
end

local function makeButton(parent, text, color, hover)
	local button = create("TextButton", parent, {
		AutoButtonColor = false,
		BackgroundColor3 = color or COLORS.button,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = COLORS.text,
		Text = text,
	})
	round(button, 6)
	outline(button, 0.72, 1)
	local normal = button.BackgroundColor3
	connect(button.MouseEnter, function()
		if alive then
			TweenService:Create(button, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { BackgroundColor3 = hover or COLORS.buttonHover }):Play()
		end
	end)
	connect(button.MouseLeave, function()
		if alive then
			TweenService:Create(button, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { BackgroundColor3 = normal }):Play()
		end
	end)
	return button
end

local compactButton = makeButton(top, "Compact")
compactButton.Name = "CompactButton"
compactButton.Position = UDim2.new(1, -190, 0.5, -15)
compactButton.Size = UDim2.fromOffset(78, 30)
compactButton.TextSize = 12

local minimizeButton = makeButton(top, "-")
minimizeButton.Position = UDim2.new(1, -102, 0.5, -17)
minimizeButton.Size = UDim2.fromOffset(42, 34)
minimizeButton.TextSize = 18
local closeButton = makeButton(top, "X", COLORS.red, COLORS.redHover)
closeButton.Position = UDim2.new(1, -52, 0.5, -17)
closeButton.Size = UDim2.fromOffset(42, 34)
closeButton.TextSize = 15

local searchBox = create("TextBox", root, {
	ClearTextOnFocus = false,
	PlaceholderText = "Filter by audio name, ID, instance or path...",
	Text = "",
	BackgroundColor3 = Color3.fromRGB(24, 24, 32),
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(18, 64),
	Size = UDim2.new(1, -36, 0, 40),
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.text,
	PlaceholderColor3 = Color3.fromRGB(150, 155, 170),
})
create("UIPadding", searchBox, {
	PaddingLeft = UDim.new(0, 12),
	PaddingRight = UDim.new(0, 12),
})
round(searchBox, 6)
outline(searchBox, 0.8, 1.5)

local toolbar = create("Frame", root, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(18, 112),
	Size = UDim2.new(1, -36, 0, 36),
})
local toolbarLayout = create("UIListLayout", toolbar, {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local scanButton = makeButton(toolbar, "Scan")
scanButton.Name = "ScanButton"
scanButton.Size = UDim2.fromOffset(72, 34)
scanButton.LayoutOrder = 1

local scopeButton = makeButton(toolbar, dropdownButtonText("Scope: Game"))
scopeButton.RichText = true
scopeButton.Name = "ScopeButton"
scopeButton.Size = UDim2.fromOffset(132, 34)
scopeButton.LayoutOrder = 2

local autoButton = makeButton(toolbar, "Auto: ON", COLORS.green, COLORS.greenHover)
autoButton.Name = "AutoScanButton"
autoButton.Size = UDim2.fromOffset(96, 34)
autoButton.LayoutOrder = 3

local clearButton = makeButton(toolbar, "Clear")
clearButton.Name = "ClearButton"
clearButton.Size = UDim2.fromOffset(70, 34)
clearButton.LayoutOrder = 4

local saveButton = makeButton(toolbar, "Save")
saveButton.Name = "SaveButton"
saveButton.Size = UDim2.fromOffset(70, 34)
saveButton.LayoutOrder = 5

local loopButton = makeButton(toolbar, "Loop: ON", COLORS.green, COLORS.greenHover)
loopButton.Name = "LoopButton"
loopButton.Size = UDim2.fromOffset(92, 34)
loopButton.LayoutOrder = 6

local volumeButton = makeButton(toolbar, dropdownButtonText("Vol: 5"))
volumeButton.RichText = true
volumeButton.Name = "VolumeButton"
volumeButton.Size = UDim2.fromOffset(82, 34)
volumeButton.LayoutOrder = 7

local speedButton = makeButton(toolbar, dropdownButtonText("Speed: 1x"))
speedButton.RichText = true
speedButton.Name = "SpeedButton"
speedButton.Size = UDim2.fromOffset(92, 34)
speedButton.LayoutOrder = 8

local statusLabel = create("TextLabel", root, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(20, 152),
	Size = UDim2.new(1, -40, 0, 18),
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.subtext,
	Text = "Initializing...",
})

local content = create("Frame", root, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(18, 178),
	Size = UDim2.new(1, -36, 1, -194),
})

local listPanel = create("Frame", content, {
	BackgroundColor3 = COLORS.panel,
	BorderSizePixel = 0,
	Size = UDim2.new(0.59, -7, 1, 0),
	ClipsDescendants = true,
})
round(listPanel, 7)
outline(listPanel, 0.84, 1)

local list = create("ScrollingFrame", listPanel, {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(8, 8),
	Size = UDim2.new(1, -16, 1, -16),
	CanvasSize = UDim2.fromOffset(0, 0),
	ScrollBarThickness = 5,
	ScrollBarImageColor3 = Color3.fromRGB(90, 100, 120),
	ScrollingDirection = Enum.ScrollingDirection.Y,
})
local listLayout = create("UIListLayout", list, {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 7),
})

local detailPanel = create("Frame", content, {
	BackgroundColor3 = COLORS.panel,
	BorderSizePixel = 0,
	Position = UDim2.new(0.59, 7, 0, 0),
	Size = UDim2.new(0.41, -7, 1, 0),
	ClipsDescendants = true,
})
round(detailPanel, 7)
outline(detailPanel, 0.84, 1)

local detailTitle = create("TextLabel", detailPanel, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(14, 12),
	Size = UDim2.new(1, -28, 0, 24),
	Font = Enum.Font.GothamSemibold,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.text,
	TextTruncate = Enum.TextTruncate.AtEnd,
	Text = "No audio selected",
})

local idBox = create("TextBox", detailPanel, {
	ClearTextOnFocus = false,
	TextEditable = false,
	BackgroundColor3 = COLORS.panel2,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(14, 44),
	Size = UDim2.new(1, -28, 0, 38),
	Font = Enum.Font.Code,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = COLORS.text,
	Text = "",
	PlaceholderText = "Sound ID",
	PlaceholderColor3 = COLORS.muted,
})
create("UIPadding", idBox, {
	PaddingLeft = UDim.new(0, 10),
	PaddingRight = UDim.new(0, 10),
})
round(idBox, 6)
outline(idBox, 0.84, 1)

local infoScroll = create("ScrollingFrame", detailPanel, {
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(14, 92),
	Size = UDim2.new(1, -28, 1, -158),
	CanvasSize = UDim2.fromOffset(0, 0),
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = Color3.fromRGB(90, 100, 120),
})
local infoLabel = create("TextLabel", infoScroll, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(2, 0),
	Size = UDim2.new(1, -12, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = COLORS.subtext,
	Text = "Select an entry to inspect its source instances and playback state.",
})

local detailButtons = create("Frame", detailPanel, {
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 14, 1, -54),
	Size = UDim2.new(1, -28, 0, 40),
})
local detailButtonLayout = create("UIListLayout", detailButtons, {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Left,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 7),
})
local copyIdButton = makeButton(detailButtons, "Copy ID", COLORS.green, COLORS.greenHover)
copyIdButton.Size = UDim2.new(0.32, -4, 1, 0)
local copyPathButton = makeButton(detailButtons, "Copy Path")
copyPathButton.Size = UDim2.new(0.32, -4, 1, 0)
local listenButton = makeButton(detailButtons, "Listen")
listenButton.Size = UDim2.new(0.36, -6, 1, 0)

local records = {}
local byKey = {}
local tracked = setmetatable({}, { __mode = "k" })
local selectedRecord = nil
local selectedRow = nil
local autoScan = true
local scanning = false
local minimized = false
local compactMode = false
local applyRowDensity
local sampleSound = nil
local previewLoop = true
local previewVolume = 5
local previewSpeed = 1
local scopeNames = { "Game", "Workspace", "SoundService", "Lighting" }
local scopeIndex = 1
local openDropdown = nil
local metadataQueue = {}
local metadataRunning = 0
local metadataMaxWorkers = 2
local metadataCache = {}
local uniqueCount = 0
local sourceCount = 0
local lastStatus = "Ready"
local updateStatus

local function safePath(instance)
	if not instance then
		return "<none>"
	end
	local ok, path = pcall(function()
		return instance:GetFullName()
	end)
	return ok and path or "<destroyed>"
end

local function normalizeSoundId(value)
	if type(value) ~= "string" then
		return nil
	end
	local raw = value:match("^%s*(.-)%s*$")
	if not raw or raw == "" then
		return nil
	end
	local numeric = raw:match("^%d+$")
		or raw:match("[Rr][Bb][Xx][Aa][Ss][Ss][Ee][Tt][Ii][Dd]://(%d+)")
		or raw:match("[?&][Ii][Dd]=(%d+)")
		or raw:match("/(%d+)[/?]?")
	if not numeric then
		numeric = raw:match("(%d+)")
	end
	if numeric then
		return "rbxassetid://" .. numeric, tonumber(numeric), raw
	end
	return string.lower(raw), nil, raw
end

local function currentSource(record)
	if not record then
		return nil
	end
	for _, sound in ipairs(record.sources) do
		if sound and sound.Parent ~= nil then
			return sound
		end
	end
	return record.sources[1]
end

local function recordSourceCount(record)
	local count = 0
	for sound in pairs(record.sourceSet) do
		if sound then
			count += 1
		end
	end
	return count
end

updateStatus = function(message)
	if message then
		lastStatus = message
	end
	statusLabel.Text = string.format("%d unique  |  %d tracked sources  |  Auto %s  |  %s", uniqueCount, sourceCount, autoScan and "ON" or "OFF", lastStatus)
end

local function closeDropdown(menu)
	if menu then
		menu.Visible = false
	end
	if openDropdown == menu then
		openDropdown = nil
	end
end

local function makeDropdown(owner, menuName, options, onSelect)
	owner.ZIndex = 40
	local menu = create("Frame", owner, {
		Name = menuName,
		BackgroundColor3 = COLORS.panel,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, 6),
		Size = UDim2.fromOffset(owner.Size.X.Offset, 10 + (#options * 30)),
		Visible = false,
		ZIndex = 100,
		ClipsDescendants = true,
	})
	round(menu, 6)
	outline(menu, 0.72, 1)
	create("UIPadding", menu, {
		PaddingTop = UDim.new(0, 5),
		PaddingBottom = UDim.new(0, 5),
		PaddingLeft = UDim.new(0, 5),
		PaddingRight = UDim.new(0, 5),
	})
	create("UIListLayout", menu, {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
	})

	for index, option in ipairs(options) do
		local label = tostring(option.label or option.value)
		local optionButton = create("TextButton", menu, {
			Name = "Option_" .. tostring(index),
			AutoButtonColor = false,
			BackgroundColor3 = COLORS.button,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 28),
			Font = Enum.Font.Gotham,
			TextSize = 12,
			TextColor3 = COLORS.text,
			Text = label,
			ZIndex = 101,
			LayoutOrder = index,
		})
		round(optionButton, 5)
		connect(optionButton.MouseEnter, function()
			if alive then
				optionButton.BackgroundColor3 = COLORS.buttonHover
			end
		end)
		connect(optionButton.MouseLeave, function()
			if alive then
				optionButton.BackgroundColor3 = COLORS.button
			end
		end)
		connect(optionButton.Activated, function()
			closeDropdown(menu)
			onSelect(option.value, label, index)
		end)
	end

	connect(owner.Activated, function()
		if openDropdown and openDropdown ~= menu then
			openDropdown.Visible = false
		end
		menu.Visible = not menu.Visible
		openDropdown = menu.Visible and menu or nil
	end)

	return menu
end

local function applyPreviewSettings()
	if sampleSound then
		pcall(function()
			sampleSound.Looped = previewLoop
			sampleSound.Volume = previewVolume
			sampleSound.PlaybackSpeed = previewSpeed
		end)
	end
end

local scopeMenu = makeDropdown(scopeButton, "ScopeMenu", {
	{ label = "Game", value = "Game" },
	{ label = "Workspace", value = "Workspace" },
	{ label = "SoundService", value = "SoundService" },
	{ label = "Lighting", value = "Lighting" },
}, function(value)
	for index, name in ipairs(scopeNames) do
		if name == value then
			scopeIndex = index
			break
		end
	end
	scopeButton.Text = dropdownButtonText("Scope: " .. value)
	updateStatus("Scope changed to " .. value)
end)

local volumeMenu = makeDropdown(volumeButton, "VolumeMenu", {
	{ label = "0.25", value = 0.25 },
	{ label = "0.5", value = 0.5 },
	{ label = "1", value = 1 },
	{ label = "2", value = 2 },
	{ label = "5", value = 5 },
	{ label = "10", value = 10 },
}, function(value, label)
	previewVolume = value
	volumeButton.Text = dropdownButtonText("Vol: " .. label)
	applyPreviewSettings()
	updateStatus("Preview volume set to " .. label)
end)

local speedMenu = makeDropdown(speedButton, "SpeedMenu", {
	{ label = "0.5x", value = 0.5 },
	{ label = "0.75x", value = 0.75 },
	{ label = "1x", value = 1 },
	{ label = "1.25x", value = 1.25 },
	{ label = "1.5x", value = 1.5 },
	{ label = "2x", value = 2 },
}, function(value, label)
	previewSpeed = value
	speedButton.Text = dropdownButtonText("Speed: " .. label)
	applyPreviewSettings()
	updateStatus("Preview speed set to " .. label)
end)

connect(loopButton.Activated, function()
	previewLoop = not previewLoop
	loopButton.Text = previewLoop and "Loop: ON" or "Loop: OFF"
	loopButton.BackgroundColor3 = previewLoop and COLORS.green or COLORS.button
	applyPreviewSettings()
	updateStatus("Preview loop " .. (previewLoop and "enabled" or "disabled"))
end)

connect(UserInputService.InputBegan, function(input)
	if not openDropdown then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local pos = input.Position
	local menuPos = openDropdown.AbsolutePosition
	local menuSize = openDropdown.AbsoluteSize
	local owner = openDropdown.Parent
	local ownerPos = owner.AbsolutePosition
	local ownerSize = owner.AbsoluteSize
	local insideMenu = pos.X >= menuPos.X and pos.X <= menuPos.X + menuSize.X and pos.Y >= menuPos.Y and pos.Y <= menuPos.Y + menuSize.Y
	local insideOwner = pos.X >= ownerPos.X and pos.X <= ownerPos.X + ownerSize.X and pos.Y >= ownerPos.Y and pos.Y <= ownerPos.Y + ownerSize.Y
	if not insideMenu and not insideOwner then
		closeDropdown(openDropdown)
	end
end)

local function refreshInfoCanvas()
	task.defer(function()
		if alive and infoScroll and infoLabel then
			infoScroll.CanvasSize = UDim2.fromOffset(0, math.max(infoScroll.AbsoluteSize.Y, infoLabel.TextBounds.Y + 12))
		end
	end)
end

local function refreshDetails()
	local record = selectedRecord
	if not record then
		detailTitle.Text = "No audio selected"
		idBox.Text = ""
		infoLabel.Text = "Select an entry to inspect its source instances and playback state."
		listenButton.Text = "Listen"
		refreshInfoCanvas()
		return
	end
	local source = currentSource(record)
	local displayName = record.productName or record.instanceName or "Unknown Audio"
	detailTitle.Text = displayName
	idBox.Text = record.canonical
	local lines = {
		"Asset name: " .. displayName,
		"Asset ID: " .. (record.assetId and tostring(record.assetId) or "non-numeric / local"),
		"Original SoundId: " .. tostring(record.originalId or record.canonical),
		"Sources: " .. tostring(recordSourceCount(record)),
	}
	if source then
		lines[#lines + 1] = ""
		lines[#lines + 1] = "Current source: " .. tostring(source.Name)
		lines[#lines + 1] = "Path: " .. safePath(source)
		local okPlaying, playing = pcall(function() return source.Playing end)
		local okVolume, volume = pcall(function() return source.Volume end)
		local okSpeed, speed = pcall(function() return source.PlaybackSpeed end)
		local okLooped, looped = pcall(function() return source.Looped end)
		local okTime, timePosition = pcall(function() return source.TimePosition end)
		if okPlaying then lines[#lines + 1] = "Playing: " .. tostring(playing) end
		if okVolume then lines[#lines + 1] = string.format("Volume: %.3f", volume) end
		if okSpeed then lines[#lines + 1] = string.format("PlaybackSpeed: %.3f", speed) end
		if okLooped then lines[#lines + 1] = "Looped: " .. tostring(looped) end
		if okTime then lines[#lines + 1] = string.format("TimePosition: %.3f", timePosition) end
	end
	if record.productError then
		lines[#lines + 1] = ""
		lines[#lines + 1] = "Metadata: unavailable"
	end
	infoLabel.Text = table.concat(lines, "\n")
	listenButton.Text = sampleSound and sampleSound.SoundId == record.canonical and "Stop" or "Listen"
	refreshInfoCanvas()
end

local function refreshRow(record)
	if not record or not record.row then
		return
	end
	local displayName = record.productName or record.instanceName or "Unknown Audio"
	record.rowTitle.Text = displayName
	record.rowId.Text = record.canonical
	local source = currentSource(record)
	local path = safePath(source)
	local count = recordSourceCount(record)
	record.rowMeta.Text = string.format("%d source%s  |  %s", count, count == 1 and "" or "s", path)
	if selectedRecord == record then
		record.row.BackgroundColor3 = COLORS.selected
	else
		record.row.BackgroundColor3 = COLORS.panel2
	end
end

local function matchesFilter(record, query)
	if query == "" then
		return true
	end
	local chunks = {
		record.productName,
		record.instanceName,
		record.canonical,
		record.originalId,
	}
	for _, value in ipairs(chunks) do
		if type(value) == "string" and string.find(string.lower(value), query, 1, true) then
			return true
		end
	end
	for sound in pairs(record.sourceSet) do
		if sound then
			local name = string.lower(tostring(sound.Name))
			if string.find(name, query, 1, true) then
				return true
			end
			local path = string.lower(safePath(sound))
			if string.find(path, query, 1, true) then
				return true
			end
		end
	end
	return false
end

local function applyFilter()
	local query = string.lower(searchBox.Text or "")
	for _, record in ipairs(records) do
		if record.row then
			record.row.Visible = matchesFilter(record, query)
		end
	end
end

local function selectRecord(record)
	if selectedRow and selectedRow.Parent then
		selectedRow.BackgroundColor3 = COLORS.panel2
	end
	selectedRecord = record
	selectedRow = record and record.row or nil
	if selectedRow then
		selectedRow.BackgroundColor3 = COLORS.selected
	end
	refreshDetails()
end

local function createRow(record)
	local row = create("Frame", list, {
		BackgroundColor3 = COLORS.panel2,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -2, 0, 68),
	})
	round(row, 6)
	outline(row, 0.88, 1)
	local rowTitle = create("TextLabel", row, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(1, -24, 0, 18),
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = COLORS.text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = record.instanceName or "Unknown Audio",
	})
	local rowId = create("TextLabel", row, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 27),
		Size = UDim2.new(1, -24, 0, 16),
		Font = Enum.Font.Code,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Color3.fromRGB(205, 210, 225),
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = record.canonical,
	})
	local rowMeta = create("TextLabel", row, {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 45),
		Size = UDim2.new(1, -24, 0, 15),
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = COLORS.muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "",
	})
	local hitbox = create("TextButton", row, {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 4,
	})
	record.row = row
	record.rowTitle = rowTitle
	record.rowId = rowId
	record.rowMeta = rowMeta
	if applyRowDensity then
		applyRowDensity(record)
	end
	connect(hitbox.MouseButton1Click, function()
		selectRecord(record)
	end)
	connect(hitbox.MouseEnter, function()
		if selectedRecord ~= record then
			TweenService:Create(row, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(38, 38, 50) }):Play()
		end
	end)
	connect(hitbox.MouseLeave, function()
		refreshRow(record)
	end)
	refreshRow(record)
end

connect(listLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
	list.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 2)
end)

local function pumpMetadata()
	while metadataRunning < metadataMaxWorkers and #metadataQueue > 0 do
		local record = table.remove(metadataQueue, 1)
		if record and not record.metadataStarted then
			record.metadataStarted = true
			metadataRunning += 1
			task.spawn(function()
				if record.assetId then
					local cached = metadataCache[record.assetId]
					if cached then
						record.productName = cached.name
						record.productError = cached.error
					else
						local ok, info = pcall(function()
							return MarketplaceService:GetProductInfo(record.assetId, Enum.InfoType.Asset)
						end)
						if ok and type(info) == "table" then
							record.productName = tostring(info.Name or record.instanceName or "Unknown Audio")
							metadataCache[record.assetId] = { name = record.productName, error = false }
						else
							record.productError = true
							metadataCache[record.assetId] = { name = nil, error = true }
						end
					end
				end
				if alive then
					refreshRow(record)
					if selectedRecord == record then
						refreshDetails()
					end
					applyFilter()
				end
				metadataRunning -= 1
				task.wait(0.08)
				pumpMetadata()
			end)
		end
	end
end

local function queueMetadata(record)
	if not record or not record.assetId or record.metadataStarted or record.metadataQueued then
		return
	end
	record.metadataQueued = true
	metadataQueue[#metadataQueue + 1] = record
	task.defer(function()
		record.metadataQueued = false
		pumpMetadata()
	end)
end

local function newRecord(key, assetId, originalId, instanceName)
	local record = {
		key = key,
		canonical = key,
		assetId = assetId,
		originalId = originalId,
		instanceName = instanceName,
		sources = {},
		sourceSet = setmetatable({}, { __mode = "k" }),
		firstSeen = os.clock(),
	}
	byKey[key] = record
	records[#records + 1] = record
	uniqueCount += 1
	createRow(record)
	queueMetadata(record)
	return record
end

local function attachSource(record, sound)
	if record.sourceSet[sound] then
		return
	end
	record.sourceSet[sound] = true
	record.sources[#record.sources + 1] = sound
	sourceCount += 1
	refreshRow(record)
	if selectedRecord == record then
		refreshDetails()
	end
end

local function detachSource(record, sound)
	if not record or not record.sourceSet[sound] then
		return
	end
	record.sourceSet[sound] = nil
	sourceCount = math.max(0, sourceCount - 1)
	for i = #record.sources, 1, -1 do
		if record.sources[i] == sound then
			table.remove(record.sources, i)
			break
		end
	end
	refreshRow(record)
	if selectedRecord == record then
		refreshDetails()
	end
end

local function processSound(sound)
	if not alive or not sound or not sound:IsA("Sound") then
		return
	end
	local track = tracked[sound]
	if not track then
		return
	end
	local key, assetId, originalId = normalizeSoundId(sound.SoundId)
	if track.key and track.key ~= key then
		detachSource(byKey[track.key], sound)
		track.key = nil
	end
	if not key then
		updateStatus("Ignored empty SoundId")
		return
	end
	local record = byKey[key]
	if not record then
		record = newRecord(key, assetId, originalId, sound.Name)
	end
	track.key = key
	record.instanceName = record.instanceName or sound.Name
	record.originalId = record.originalId or originalId
	attachSource(record, sound)
	applyFilter()
	updateStatus("Captured " .. tostring(sound.Name))
end

local function trackSound(sound)
	if not sound or not sound:IsA("Sound") then
		return
	end
	local okInternal, internal = pcall(function()
		return sound:GetAttribute("__AudioLoggerInternal")
	end)
	if okInternal and internal then
		return
	end
	if tracked[sound] then
		processSound(sound)
		return
	end
	tracked[sound] = { key = nil }
	connect(sound:GetPropertyChangedSignal("SoundId"), function()
		processSound(sound)
	end)
	connect(sound.AncestryChanged, function(_, parent)
		local track = tracked[sound]
		if not track then
			return
		end
		if parent == nil then
			if track.key then
				detachSource(byKey[track.key], sound)
			end
			tracked[sound] = nil
			updateStatus("Source removed")
		else
			if not track.key then
				processSound(sound)
			end
		end
	end)
	processSound(sound)
end

local function scopeRoot()
	local scope = scopeNames[scopeIndex]
	if scope == "Workspace" then
		return Workspace
	elseif scope == "SoundService" then
		return SoundService
	elseif scope == "Lighting" then
		return Lighting
	end
	return game
end

local function scanCurrentScope()
	if scanning or not alive then
		return
	end
	scanning = true
	scanButton.Text = "Scanning..."
	updateStatus("Scanning " .. scopeNames[scopeIndex])
	task.spawn(function()
		local rootObject = scopeRoot()
		local ok, descendants = pcall(function()
			return rootObject:GetDescendants()
		end)
		local sounds = 0
		if ok and type(descendants) == "table" then
			for index, instance in ipairs(descendants) do
				if not alive then
					break
				end
				if instance:IsA("Sound") then
					sounds += 1
					trackSound(instance)
				end
				if index % 250 == 0 then
					task.wait()
				end
			end
		end
		scanning = false
		if alive then
			scanButton.Text = "Scan"
			updateStatus(string.format("Scan complete: %d Sound instance%s", sounds, sounds == 1 and "" or "s"))
		end
	end)
end

local function clearRecords()
	if sampleSound then
		pcall(function() sampleSound:Destroy() end)
		sampleSound = nil
	end
	selectRecord(nil)
	for _, record in ipairs(records) do
		if record.row then
			pcall(function() record.row:Destroy() end)
		end
	end
	table.clear(records)
	table.clear(byKey)
	uniqueCount = 0
	sourceCount = 0
	for sound, track in pairs(tracked) do
		if sound and track then
			track.key = nil
		end
	end
	updateStatus("Cleared")
end

local function copyText(text, successMessage)
	if type(setclipboard) ~= "function" then
		updateStatus("setclipboard unavailable")
		return
	end
	local ok = pcall(setclipboard, tostring(text or ""))
	updateStatus(ok and successMessage or "Clipboard failed")
end

local function saveRecords()
	if type(writefile) ~= "function" then
		updateStatus("writefile unavailable")
		return
	end
	local output = {}
	for _, record in ipairs(records) do
		local paths = {}
		for sound in pairs(record.sourceSet) do
			paths[#paths + 1] = safePath(sound)
		end
		output[#output + 1] = {
			name = record.productName or record.instanceName or "Unknown Audio",
			assetId = record.assetId,
			soundId = record.canonical,
			originalSoundId = record.originalId,
			sources = paths,
		}
	end
	local okEncode, encoded = pcall(function()
		return HttpService:JSONEncode(output)
	end)
	if not okEncode then
		updateStatus("JSON encode failed")
		return
	end
	local filename = string.format("AudioLogger_%s_%s.json", tostring(game.PlaceId), tostring(os.time()))
	local okWrite = pcall(writefile, filename, encoded)
	updateStatus(okWrite and ("Saved " .. filename) or "Save failed")
end

connect(searchBox:GetPropertyChangedSignal("Text"), applyFilter)
connect(scanButton.MouseButton1Click, scanCurrentScope)
connect(autoButton.MouseButton1Click, function()
	autoScan = not autoScan
	autoButton.Text = autoScan and "Auto: ON" or "Auto: OFF"
	autoButton.BackgroundColor3 = autoScan and COLORS.green or COLORS.button
	updateStatus("Auto scan " .. (autoScan and "enabled" or "disabled"))
end)
connect(clearButton.MouseButton1Click, clearRecords)
connect(saveButton.MouseButton1Click, saveRecords)
connect(copyIdButton.MouseButton1Click, function()
	if selectedRecord then
		copyText(selectedRecord.canonical, "Copied audio ID")
	end
end)
connect(copyPathButton.MouseButton1Click, function()
	local source = currentSource(selectedRecord)
	if source then
		copyText(safePath(source), "Copied source path")
	end
end)
local function stopPreview(message)
	if sampleSound then
		pcall(function() sampleSound:Destroy() end)
		sampleSound = nil
	end
	listenButton.Text = "Listen"
	if message then
		updateStatus(message)
	end
end

local function startPreview(record)
	if not record then
		return
	end
	stopPreview()
	local sound = Instance.new("Sound")
	sound.Name = "AudioLoggerPreview"
	sound.SoundId = record.canonical
	sound.Volume = previewVolume
	sound.Looped = previewLoop
	sound.PlaybackSpeed = previewSpeed
	sound:SetAttribute("__AudioLoggerInternal", true)
	local previewParent = __NAProtectedParent(gui.Parent) or gui
	sound.Parent = previewParent
	sampleSound = sound
	local ok = pcall(function()
		sound:Play()
	end)
	if not ok then
		stopPreview("Preview failed")
		return
	end
	listenButton.Text = "Stop"
	updateStatus(string.format("Previewing | Loop %s | Vol %s | Speed %sx", previewLoop and "ON" or "OFF", tostring(previewVolume), tostring(previewSpeed)))
	connect(sound.Ended, function()
		if sampleSound == sound then
			sampleSound = nil
			pcall(function() sound:Destroy() end)
			if alive then
				listenButton.Text = "Listen"
				updateStatus("Preview finished")
			end
		end
	end)
end

connect(listenButton.MouseButton1Click, function()
	if not selectedRecord then
		return
	end
	if sampleSound and sampleSound.SoundId == selectedRecord.canonical then
		stopPreview("Preview stopped")
	else
		startPreview(selectedRecord)
	end
end)

connect(game.DescendantAdded, function(instance)
	if autoScan and instance:IsA("Sound") then
		local okInternal, internal = pcall(function()
			return instance:GetAttribute("__AudioLoggerInternal")
		end)
		if not (okInternal and internal) then
			trackSound(instance)
		end
	end
end)

local dragging = false
local dragStart = nil
local rootStart = nil
local dragInput = nil
connect(top.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		rootStart = root.Position
		dragInput = input
	end
end)
connect(top.InputChanged, function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)
connect(UserInputService.InputChanged, function(input)
	if dragging and input == dragInput and dragStart and rootStart then
		local delta = input.Position - dragStart
		root.Position = UDim2.new(rootStart.X.Scale, rootStart.X.Offset + delta.X, rootStart.Y.Scale, rootStart.Y.Offset + delta.Y)
	end
end)
connect(UserInputService.InputEnded, function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		dragging = false
		dragInput = nil
	end
end)

local fullSize = root.Size

applyRowDensity = function(record)
	if not record or not record.row then
		return
	end
	if compactMode then
		record.row.Size = UDim2.new(1, -2, 0, 56)
		if record.rowTitle then
			record.rowTitle.Position = UDim2.fromOffset(10, 6)
			record.rowTitle.Size = UDim2.new(1, -20, 0, 16)
			record.rowTitle.TextSize = 12
		end
		if record.rowId then
			record.rowId.Position = UDim2.fromOffset(10, 22)
			record.rowId.Size = UDim2.new(1, -20, 0, 15)
			record.rowId.TextSize = 11
		end
		if record.rowMeta then
			record.rowMeta.Position = UDim2.fromOffset(10, 38)
			record.rowMeta.Size = UDim2.new(1, -20, 0, 13)
			record.rowMeta.TextSize = 10
		end
	else
		record.row.Size = UDim2.new(1, -2, 0, 68)
		if record.rowTitle then
			record.rowTitle.Position = UDim2.fromOffset(12, 8)
			record.rowTitle.Size = UDim2.new(1, -24, 0, 18)
			record.rowTitle.TextSize = 13
		end
		if record.rowId then
			record.rowId.Position = UDim2.fromOffset(12, 27)
			record.rowId.Size = UDim2.new(1, -24, 0, 16)
			record.rowId.TextSize = 12
		end
		if record.rowMeta then
			record.rowMeta.Position = UDim2.fromOffset(12, 45)
			record.rowMeta.Size = UDim2.new(1, -24, 0, 15)
			record.rowMeta.TextSize = 11
		end
	end
end

local function applyCompactMetrics()
	local topH = compactMode and 44 or 52
	local buttonH = compactMode and 28 or 34
	local topButtonH = compactMode and 28 or 34
	local topButtonY = -math.floor(topButtonH / 2)

	top.Size = UDim2.new(1, 0, 0, topH)
	title.Position = UDim2.fromOffset(compactMode and 16 or 18, 0)
	title.Size = UDim2.new(1, -292, 1, 0)
	title.TextSize = compactMode and 15 or 17

	compactButton.Text = compactMode and "Comfort" or "Compact"
	compactButton.Position = UDim2.new(1, -190, 0.5, compactMode and -14 or -15)
	compactButton.Size = UDim2.fromOffset(78, compactMode and 28 or 30)
	compactButton.TextSize = 12

	minimizeButton.Position = UDim2.new(1, -102, 0.5, topButtonY)
	minimizeButton.Size = UDim2.fromOffset(42, topButtonH)
	minimizeButton.TextSize = compactMode and 16 or 18
	closeButton.Position = UDim2.new(1, -52, 0.5, topButtonY)
	closeButton.Size = UDim2.fromOffset(42, topButtonH)
	closeButton.TextSize = compactMode and 14 or 15

	searchBox.TextSize = compactMode and 13 or 14
	toolbarLayout.Padding = UDim.new(0, compactMode and 6 or 8)
	listLayout.Padding = UDim.new(0, compactMode and 5 or 7)
	detailButtonLayout.Padding = UDim.new(0, compactMode and 5 or 7)

	local widths = compactMode and {
		scan = 62, scope = 118, auto = 84, clear = 60, save = 60,
		loop = 80, volume = 72, speed = 82,
	} or {
		scan = 72, scope = 132, auto = 96, clear = 70, save = 70,
		loop = 92, volume = 82, speed = 92,
	}

	scanButton.Size = UDim2.fromOffset(widths.scan, buttonH)
	scopeButton.Size = UDim2.fromOffset(widths.scope, buttonH)
	autoButton.Size = UDim2.fromOffset(widths.auto, buttonH)
	clearButton.Size = UDim2.fromOffset(widths.clear, buttonH)
	saveButton.Size = UDim2.fromOffset(widths.save, buttonH)
	loopButton.Size = UDim2.fromOffset(widths.loop, buttonH)
	volumeButton.Size = UDim2.fromOffset(widths.volume, buttonH)
	speedButton.Size = UDim2.fromOffset(widths.speed, buttonH)

	for _, button in ipairs({ scanButton, scopeButton, autoButton, clearButton, saveButton, loopButton, volumeButton, speedButton }) do
		button.TextSize = compactMode and 12 or 13
	end

	scopeMenu.Size = UDim2.fromOffset(scopeButton.Size.X.Offset, scopeMenu.Size.Y.Offset)
	volumeMenu.Size = UDim2.fromOffset(volumeButton.Size.X.Offset, volumeMenu.Size.Y.Offset)
	speedMenu.Size = UDim2.fromOffset(speedButton.Size.X.Offset, speedMenu.Size.Y.Offset)

	detailTitle.Position = UDim2.fromOffset(compactMode and 12 or 14, compactMode and 9 or 12)
	detailTitle.Size = UDim2.new(1, compactMode and -24 or -28, 0, compactMode and 21 or 24)
	detailTitle.TextSize = compactMode and 14 or 15

	idBox.Position = UDim2.fromOffset(compactMode and 12 or 14, compactMode and 36 or 44)
	idBox.Size = UDim2.new(1, compactMode and -24 or -28, 0, compactMode and 32 or 38)
	idBox.TextSize = compactMode and 12 or 13

	infoScroll.Position = UDim2.fromOffset(compactMode and 12 or 14, compactMode and 76 or 92)
	infoScroll.Size = UDim2.new(1, compactMode and -24 or -28, 1, compactMode and -132 or -158)
	infoLabel.TextSize = compactMode and 12 or 13

	detailButtons.Position = UDim2.new(0, compactMode and 12 or 14, 1, compactMode and -44 or -54)
	detailButtons.Size = UDim2.new(1, compactMode and -24 or -28, 0, compactMode and 32 or 40)
	for _, button in ipairs({ copyIdButton, copyPathButton, listenButton }) do
		button.TextSize = compactMode and 12 or 13
	end

	for _, record in ipairs(records) do
		applyRowDensity(record)
	end
end

connect(minimizeButton.MouseButton1Click, function()
	minimized = not minimized
	if minimized then
		if openDropdown then
			closeDropdown(openDropdown)
		end
		fullSize = root.Size
		local topH = compactMode and 44 or 52
		root.Size = UDim2.fromOffset(math.max(310, root.AbsoluteSize.X), topH)
		searchBox.Visible = false
		toolbar.Visible = false
		statusLabel.Visible = false
		content.Visible = false
		compactButton.Visible = false
		minimizeButton.Text = "+"
	else
		root.Size = fullSize
		searchBox.Visible = true
		toolbar.Visible = true
		statusLabel.Visible = true
		content.Visible = true
		compactButton.Visible = true
		minimizeButton.Text = "-"
	end
end)

local function fitUI()
	if not alive or minimized then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	local mobile = isMobile()
	local margin = mobile and 10 or 24
	local minW = mobile and 310 or 520
	local minH = mobile and 340 or 420
	local width = math.clamp(viewport.X - margin * 2, math.min(minW, math.max(300, viewport.X - 8)), 860)
	local height = math.clamp(viewport.Y - margin * 2, math.min(minH, math.max(300, viewport.Y - 8)), 620)

	root.Size = UDim2.fromOffset(width, height)
	root.AnchorPoint = Vector2.new(0, 0)
	root.Position = UDim2.fromOffset(
		math.floor((viewport.X - width) * 0.5),
		math.floor((viewport.Y - height) * 0.5)
	)
	fullSize = root.Size

	applyCompactMetrics()

	local stackPanels = width < 610 or (mobile and viewport.X < 760)
	local wrapToolbar = width < (compactMode and 690 or 820) or stackPanels
	local topH = compactMode and 44 or 52
	local searchH = compactMode and 32 or (stackPanels and 36 or 40)
	local searchY = topH + (compactMode and 8 or 12)
	local toolbarY = searchY + searchH + (compactMode and 6 or 8)
	local toolbarH
	if wrapToolbar then
		toolbarH = compactMode and 58 or 70
	else
		toolbarH = compactMode and 30 or 36
	end
	local statusY = toolbarY + toolbarH + (compactMode and 2 or 4)
	local statusH = compactMode and 16 or 18
	local contentY = statusY + statusH + (compactMode and 6 or 8)
	local bottomPad = compactMode and 12 or 16

	searchBox.Position = UDim2.fromOffset(compactMode and 14 or 18, searchY)
	searchBox.Size = UDim2.new(1, compactMode and -28 or -36, 0, searchH)

	toolbar.Position = UDim2.fromOffset(compactMode and 14 or 18, toolbarY)
	toolbar.Size = UDim2.new(1, compactMode and -28 or -36, 0, toolbarH)
	toolbarLayout.Wraps = wrapToolbar

	statusLabel.Position = UDim2.fromOffset(compactMode and 16 or 20, statusY)
	statusLabel.Size = UDim2.new(1, compactMode and -32 or -40, 0, statusH)
	statusLabel.TextSize = compactMode and 11 or 12

	content.Position = UDim2.fromOffset(compactMode and 14 or 18, contentY)
	content.Size = UDim2.new(1, compactMode and -28 or -36, 1, -(contentY + bottomPad))

	if stackPanels then
		listPanel.Position = UDim2.fromOffset(0, 0)
		listPanel.Size = UDim2.new(1, 0, 0.46, -5)
		detailPanel.Position = UDim2.new(0, 0, 0.46, 7)
		detailPanel.Size = UDim2.new(1, 0, 0.54, -7)
	else
		listPanel.Position = UDim2.fromOffset(0, 0)
		listPanel.Size = UDim2.new(0.59, -7, 1, 0)
		detailPanel.Position = UDim2.new(0.59, 7, 0, 0)
		detailPanel.Size = UDim2.new(0.41, -7, 1, 0)
	end
end

connect(compactButton.MouseButton1Click, function()
	if minimized then
		return
	end
	compactMode = not compactMode
	if openDropdown then
		closeDropdown(openDropdown)
	end
	fitUI()
	updateStatus(compactMode and "Compact layout enabled" or "Comfort layout enabled")
end)

local cameraConnection = nil
local function bindCamera()
	if cameraConnection then
		pcall(function() cameraConnection:Disconnect() end)
		cameraConnection = nil
	end
	local camera = Workspace.CurrentCamera
	if camera then
		cameraConnection = connect(camera:GetPropertyChangedSignal("ViewportSize"), fitUI)
	end
	fitUI()
end
connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), bindCamera)
bindCamera()

local function clean()
	if not alive then
		return
	end
	alive = false
	if sampleSound then
		pcall(function() sampleSound:Destroy() end)
		sampleSound = nil
	end
	disconnectAll()
	pcall(function() gui:Destroy() end)
	if type(env) == "table" and rawget(env, appKey) == state then
		rawset(env, appKey, nil)
	end
end
state.clean = clean
state.gui = gui
state.scan = scanCurrentScope
state.records = records
state.byKey = byKey
state.previewSettings = function()
	return previewLoop, previewVolume, previewSpeed, scopeNames[scopeIndex]
end
state.compactMode = function()
	return compactMode
end
state.previewParent = function()
	return __NAProtectedParent(gui.Parent) or gui
end

connect(closeButton.MouseButton1Click, clean)
connect(gui.AncestryChanged, function(_, parent)
	if parent == nil and alive then
		clean()
	end
end)

updateStatus("Ready")
scanCurrentScope()
