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

cloneref = cloneref or function(value)
	return value
end

local sharedEnv = type(getgenv) == "function" and getgenv() or _G

local Players = __lt.cs("Players", cloneref)
local RunService = __lt.cs("RunService", cloneref)
local UserInputService = __lt.cs("UserInputService", cloneref)
local VirtualInputManager = __lt.cs("VirtualInputManager", cloneref)
local HttpService = __lt.cs("HttpService", cloneref)
local CoreGui = __lt.cs("CoreGui", cloneref)
local GuiService = __lt.cs("GuiService", cloneref)

local LocalPlayer = Players.LocalPlayer
local PlayerMouse = nil
if LocalPlayer and LocalPlayer.GetMouse then
	local ok, mouse = pcall(function()
		return LocalPlayer:GetMouse()
	end)
	if ok and mouse then
		PlayerMouse = mouse
	end
end
local parentUI = gethui and gethui() or CoreGui or LocalPlayer:WaitForChild("PlayerGui")
local CONFIG_PATH = "AutoClickerSettings.json"
local INSTANCE_MARKER = "__ltseverydayyou_autoclicker"

local sharedState = type(sharedEnv.AutoClickerState) == "table" and sharedEnv.AutoClickerState or {}
sharedEnv.AutoClickerState = sharedState

if sharedState.loaded and type(sharedState.cleanup) == "function" then
	pcall(sharedState.cleanup)
elseif type(sharedEnv.AutoClickerCleanup) == "function" then
	pcall(sharedEnv.AutoClickerCleanup)
end

for _, child in ipairs(parentUI:GetChildren()) do
	if child:IsA("ScreenGui") and child:GetAttribute(INSTANCE_MARKER) then
		pcall(function()
			child:Destroy()
		end)
	end
end

local BUTTONS = {
	left = {
		index = 0,
		label = "left Mouse Button",
		short = "LButton"
	},
	middle = {
		index = 2,
		label = "middle Mouse Button",
		short = "MButton"
	},
	right = {
		index = 1,
		label = "right Mouse Button",
		short = "RButton"
	}
}

local DEFAULTS = {
	activationKey = "Backquote",
	activationMode = "toggle",
	clickButton = "left",
	clickRate = 7000,
	unlimited = false,
	randomize = false,
	dutyCycle = 50,
	clickLimitEnabled = false,
	clickLimit = 0,
	targetRobloxOnly = true,
	ignoreOwnUI = true,
	ignoreFocusedTextBox = true
}

local THEME = {
	background = Color3.fromRGB(20, 22, 27),
	panel = Color3.fromRGB(28, 31, 38),
	section = Color3.fromRGB(24, 27, 34),
	border = Color3.fromRGB(58, 64, 77),
	text = Color3.fromRGB(232, 236, 242),
	muted = Color3.fromRGB(151, 159, 173),
	blue = Color3.fromRGB(61, 145, 255),
	blueDark = Color3.fromRGB(43, 112, 210),
	blueSoft = Color3.fromRGB(35, 52, 84),
	white = Color3.fromRGB(42, 46, 56),
	red = Color3.fromRGB(202, 92, 92),
	green = Color3.fromRGB(79, 184, 129)
}

local function cloneTable(source)
	local copy = {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			copy[key] = cloneTable(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function mergeTable(base, override)
	local merged = cloneTable(base)
	for key, value in pairs(override or {}) do
		merged[key] = value
	end
	return merged
end

local function resolveKeyCode(keyName)
	if type(keyName) ~= "string" then
		return nil
	end
	local ok, keyCode = pcall(function()
		return Enum.KeyCode[keyName]
	end)
	if ok then
		return keyCode
	end
	return nil
end

local function normalizeConfig(raw)
	local config = mergeTable(DEFAULTS, raw)
	local activationKey = resolveKeyCode(config.activationKey)
	if activationKey == nil then
		config.activationKey = DEFAULTS.activationKey
	else
		config.activationKey = activationKey.Name
	end
	if config.activationMode ~= "hold" and config.activationMode ~= "toggle" then
		config.activationMode = DEFAULTS.activationMode
	end
	if BUTTONS[config.clickButton] == nil then
		config.clickButton = DEFAULTS.clickButton
	end
	config.clickRate = math.max(tonumber(config.clickRate) or DEFAULTS.clickRate, 0.1)
	config.unlimited = config.unlimited == true
	config.randomize = config.randomize == true
	config.dutyCycle = math.clamp(tonumber(config.dutyCycle) or DEFAULTS.dutyCycle, 1, 99)
	config.clickLimitEnabled = config.clickLimitEnabled == true
	config.clickLimit = math.max(math.floor(tonumber(config.clickLimit) or DEFAULTS.clickLimit), 0)
	config.language = nil
	config.targetRobloxOnly = config.targetRobloxOnly ~= false
	config.ignoreOwnUI = config.ignoreOwnUI ~= false
	config.ignoreFocusedTextBox = config.ignoreFocusedTextBox ~= false
	if config.clickLimitEnabled and config.clickLimit <= 0 then
		config.clickLimit = 1
	end
	return config
end

local function loadConfig()
	if type(readfile) ~= "function" or type(isfile) ~= "function" or not isfile(CONFIG_PATH) then
		return cloneTable(DEFAULTS)
	end
	local ok, content = pcall(readfile, CONFIG_PATH)
	if not ok or type(content) ~= "string" or content == "" then
		return cloneTable(DEFAULTS)
	end
	local decodedOk, decoded = pcall(function()
		return __lt.cm("HttpService", "JSONDecode", content)
	end)
	if not decodedOk or type(decoded) ~= "table" then
		return cloneTable(DEFAULTS)
	end
	return normalizeConfig(decoded)
end

local function saveConfig(config)
	if type(writefile) ~= "function" then
		return
	end
	local ok, encoded = pcall(function()
		return __lt.cm("HttpService", "JSONEncode", config)
	end)
	if ok then
		pcall(writefile, CONFIG_PATH, encoded)
	end
end

local config = loadConfig()

local function formatNumber(value, decimals)
	return string.format("%." .. tostring(decimals) .. "f", value)
end

local function formatDuration(seconds)
	if seconds <= 0 then
		return "0.0 us"
	end
	if seconds >= 1 then
		return string.format("%.2f s", seconds)
	end
	if seconds >= 0.001 then
		return string.format("%.1f ms", seconds * 1000)
	end
	return string.format("%.1f us", seconds * 1000000)
end

local function new(className, parent, properties)
	local instance = Instance.new(className)
	local randomName = "\0"
	if HttpService and HttpService.GenerateGUID then
		local ok, guid = pcall(function()
			return __lt.cm("HttpService", "GenerateGUID", false)
		end)
		if ok and type(guid) == "string" and guid ~= "" then
			randomName = guid:gsub("%-", "")
		end
	end
	instance.Name = randomName
	for key, value in pairs(properties or {}) do
		if key ~= "Name" then
		instance[key] = value
		end
	end
	instance.Parent = parent
	return instance
end

local function makeCorner(parent, radius)
	return new("UICorner", parent, {
		CornerRadius = UDim.new(0, radius)
	})
end

local function makeStroke(parent, color, thickness)
	return new("UIStroke", parent, {
		Color = color,
		Thickness = thickness or 1
	})
end

local ui = new("ScreenGui", parentUI, {
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
	DisplayOrder = 50
})
ui:SetAttribute(INSTANCE_MARKER, true)

local root = new("Frame", ui, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(548, 548),
	BackgroundColor3 = THEME.background,
	BorderSizePixel = 0,
	Active = true
})
makeCorner(root, 10)
makeStroke(root, THEME.border, 1)

local rootScale = new("UIScale", root, {
	Scale = 1
})

local header = new("Frame", root, {
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = Color3.fromRGB(30, 33, 40),
	BorderSizePixel = 0
})
makeCorner(header, 10)
new("Frame", header, {
	Position = UDim2.fromOffset(0, 24),
	Size = UDim2.new(1, 0, 0, 10),
	BackgroundColor3 = Color3.fromRGB(30, 33, 40),
	BorderSizePixel = 0
})

local titleLabel = new("TextLabel", header, {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(12, 0),
	Size = UDim2.new(1, -96, 1, 0),
	Text = "ltseverydayyou - AutoClicker",
	TextColor3 = THEME.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.SourceSans,
	TextSize = 21
})

local minimizeButton = new("TextButton", header, {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -44, 0.5, 0),
	Size = UDim2.fromOffset(18, 18),
	BackgroundTransparency = 1,
	Text = "-",
	Font = Enum.Font.SourceSansBold,
	TextSize = 24,
	TextColor3 = THEME.text
})

local closeButton = new("TextButton", header, {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -16, 0.5, 0),
	Size = UDim2.fromOffset(18, 18),
	BackgroundTransparency = 1,
	Text = "X",
	Font = Enum.Font.SourceSansBold,
	TextSize = 20,
	TextColor3 = THEME.text
})

local function createSection(parent, title, position, size)
	local section = new("Frame", parent, {
		Position = position,
		Size = size,
		BackgroundColor3 = THEME.section,
		BorderSizePixel = 0
	})
	makeCorner(section, 6)
	makeStroke(section, THEME.border, 1)

	local titleBack = new("Frame", section, {
		Position = UDim2.fromOffset(8, -9),
		Size = UDim2.fromOffset(math.max(70, (#title * 7) + 12), 18),
		BackgroundColor3 = THEME.background,
		BorderSizePixel = 0
	})

	new("TextLabel", titleBack, {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = THEME.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.SourceSans,
		TextSize = 22
	})

	return section
end

local activationSection = createSection(root, "Activation", UDim2.fromOffset(12, 44), UDim2.fromOffset(524, 92))
local clicksSection = createSection(root, "Clicks", UDim2.fromOffset(12, 146), UDim2.fromOffset(524, 168))
local rateSection = createSection(root, "Click rate", UDim2.fromOffset(12, 326), UDim2.fromOffset(260, 136))
local limitSection = createSection(root, "Click limit", UDim2.fromOffset(280, 326), UDim2.fromOffset(256, 136))

local statusLabel = new("TextLabel", root, {
	Position = UDim2.fromOffset(16, 472),
	Size = UDim2.fromOffset(360, 24),
	BackgroundTransparency = 1,
	Text = "Status: Idle",
	TextColor3 = THEME.muted,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.SourceSansSemibold,
	TextSize = 18
})

local toggleButton = new("TextButton", root, {
	Position = UDim2.fromOffset(12, 496),
	Size = UDim2.fromOffset(108, 32),
	BackgroundColor3 = THEME.green,
	Text = "START",
	TextColor3 = THEME.white,
	Font = Enum.Font.SourceSansBold,
	TextSize = 22,
	AutoButtonColor = false
})
makeCorner(toggleButton, 4)

local exitButton = new("TextButton", root, {
	Position = UDim2.fromOffset(420, 496),
	Size = UDim2.fromOffset(116, 32),
	BackgroundColor3 = THEME.blue,
	Text = "EXIT",
	TextColor3 = THEME.white,
	Font = Enum.Font.SourceSansBold,
	TextSize = 24,
	AutoButtonColor = false
})
makeCorner(exitButton, 4)

local dockBar = new("Frame", ui, {
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(500, 40),
	BackgroundColor3 = Color3.fromRGB(28, 31, 38),
	BorderSizePixel = 0
})
makeCorner(dockBar, 8)
makeStroke(dockBar, THEME.border, 1)

local dockTitle = new("TextLabel", dockBar, {
	Position = UDim2.fromOffset(12, 0),
	Size = UDim2.fromOffset(168, 40),
	BackgroundTransparency = 1,
	Text = "AutoClicker",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.text,
	Font = Enum.Font.SourceSansBold,
	TextSize = 17
})

local dockState = new("TextLabel", dockBar, {
	Position = UDim2.fromOffset(200, 0),
	Size = UDim2.fromOffset(196, 40),
	BackgroundTransparency = 1,
	Text = "Idle",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.muted,
	Font = Enum.Font.SourceSansSemibold,
	TextSize = 16
})

local dockOpen = new("TextButton", dockBar, {
	Position = UDim2.fromOffset(404, 6),
	Size = UDim2.fromOffset(52, 28),
	BackgroundColor3 = THEME.blue,
	Text = "OPEN",
	TextColor3 = THEME.white,
	Font = Enum.Font.SourceSansBold,
	TextSize = 19,
	AutoButtonColor = false
})
makeCorner(dockOpen, 4)

local dockExit = new("TextButton", dockBar, {
	Position = UDim2.fromOffset(460, 6),
	Size = UDim2.fromOffset(28, 28),
	BackgroundColor3 = Color3.fromRGB(210, 132, 132),
	Text = "X",
	TextColor3 = THEME.white,
	Font = Enum.Font.SourceSansBold,
	TextSize = 19,
	AutoButtonColor = false
})
makeCorner(dockExit, 4)

local function updateViewportLayout()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
	local margin = math.clamp(math.floor(math.min(viewport.X, viewport.Y) * 0.04), 10, 28)
	local usableWidth = math.max(viewport.X - (margin * 2), 160)
	local usableHeight = math.max(viewport.Y - (margin * 2), 160)
	rootScale.Scale = math.clamp(math.min(usableWidth / 548, usableHeight / 548, 1), 0.32, 1)
	dockBar.Size = UDim2.fromOffset(math.max(math.min(viewport.X - (margin * 2), 500), 220), 40)
end

updateViewportLayout()

local overlay = new("Frame", root, {
	Visible = false,
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.32,
	BorderSizePixel = 0,
	ZIndex = 90,
	Active = true
})
makeCorner(overlay, 10)

local appsModal = new("Frame", overlay, {
	Visible = false,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(360, 226),
	BackgroundColor3 = THEME.panel,
	BorderSizePixel = 0,
	ZIndex = 91
})
makeCorner(appsModal, 8)
makeStroke(appsModal, THEME.border, 1)

new("TextLabel", appsModal, {
	Position = UDim2.fromOffset(14, 10),
	Size = UDim2.fromOffset(220, 24),
	BackgroundTransparency = 1,
	Text = "Settings",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.text,
	Font = Enum.Font.SourceSansBold,
	TextSize = 24,
	ZIndex = 92
})

new("TextLabel", appsModal, {
	Position = UDim2.fromOffset(14, 38),
	Size = UDim2.fromOffset(330, 34),
	BackgroundTransparency = 1,
	Text = "Script settings for click behavior and UI safety.",
	TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = THEME.muted,
	Font = Enum.Font.SourceSans,
	TextSize = 20,
	ZIndex = 92
})

local function createToggle(parent, text, position, width, circular)
	local button = new("TextButton", parent, {
		Position = position,
		Size = UDim2.fromOffset(width, 24),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = parent.ZIndex + 1
	})

	local indicator = new("Frame", button, {
		Position = UDim2.fromOffset(0, 3),
		Size = circular and UDim2.fromOffset(16, 16) or UDim2.fromOffset(15, 15),
		BackgroundColor3 = Color3.fromRGB(31, 35, 43),
		BorderSizePixel = 0,
		ZIndex = button.ZIndex + 1
	})
	makeCorner(indicator, circular and 8 or 3)
	makeStroke(indicator, THEME.border, 1)

	local fill = new("Frame", indicator, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = circular and UDim2.fromOffset(8, 8) or UDim2.fromOffset(9, 9),
		BackgroundColor3 = THEME.blue,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = indicator.ZIndex + 1
	})
	makeCorner(fill, circular and 4 or 2)

	local label = new("TextLabel", button, {
		Position = UDim2.fromOffset(24, 0),
		Size = UDim2.new(1, -24, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.text,
		Font = Enum.Font.SourceSans,
		TextSize = 22,
		ZIndex = button.ZIndex + 1
	})

	return {
		button = button,
		fill = fill,
		label = label,
		circular = circular
	}
end

local appTargetToggle = createToggle(appsModal, "Active Roblox client", UDim2.fromOffset(16, 74), 240, false)
local appIgnoreUIToggle = createToggle(appsModal, "Ignore auto clicker UI", UDim2.fromOffset(16, 108), 240, false)
local appTypingToggle = createToggle(appsModal, "Pause while typing", UDim2.fromOffset(16, 142), 240, false)

local appsClose = new("TextButton", appsModal, {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -14, 1, -12),
	Size = UDim2.fromOffset(88, 30),
	BackgroundColor3 = THEME.blue,
	Text = "OK",
	TextColor3 = THEME.white,
	Font = Enum.Font.SourceSansBold,
	TextSize = 22,
	AutoButtonColor = false,
	ZIndex = 92
})
makeCorner(appsClose, 4)

local function createField(parent, labelText, labelPosition, boxPosition, boxSize, suffixText)
	new("TextLabel", parent, {
		Position = labelPosition,
		Size = UDim2.fromOffset(150, 24),
		BackgroundTransparency = 1,
		Text = labelText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.text,
		Font = Enum.Font.SourceSans,
		TextSize = 23
	})

	local box = new("TextBox", parent, {
		Position = boxPosition,
		Size = boxSize,
		BackgroundColor3 = THEME.white,
		TextColor3 = THEME.text,
		Text = "",
		ClearTextOnFocus = false,
		Font = Enum.Font.SourceSansSemibold,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Center
	})
	makeStroke(box, THEME.border, 1)

	if suffixText then
		new("TextLabel", parent, {
			Position = UDim2.new(boxPosition.X.Scale, boxPosition.X.Offset + boxSize.X.Offset + 8, boxPosition.Y.Scale, boxPosition.Y.Offset),
			Size = UDim2.fromOffset(130, boxSize.Y.Offset),
			BackgroundTransparency = 1,
			Text = suffixText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = THEME.text,
			Font = Enum.Font.SourceSans,
			TextSize = 23
		})
	end

	return box
end

new("TextLabel", activationSection, {
	Position = UDim2.fromOffset(12, 12),
	Size = UDim2.fromOffset(150, 24),
	BackgroundTransparency = 1,
	Text = "Activation Key:",
	TextColor3 = THEME.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.SourceSans,
	TextSize = 23
})

local keyValue = new("TextLabel", activationSection, {
	Position = UDim2.fromOffset(172, 8),
	Size = UDim2.fromOffset(182, 28),
	BackgroundColor3 = THEME.white,
	Text = "",
	TextColor3 = THEME.text,
	Font = Enum.Font.SourceSansBold,
	TextSize = 23
})
makeStroke(keyValue, THEME.border, 1)

local selectKeyButton = new("TextButton", activationSection, {
	Position = UDim2.fromOffset(364, 8),
	Size = UDim2.fromOffset(136, 28),
	BackgroundColor3 = THEME.blue,
	Text = "SELECT...",
	TextColor3 = THEME.white,
	Font = Enum.Font.SourceSansBold,
	TextSize = 23,
	AutoButtonColor = false
})
makeCorner(selectKeyButton, 3)

new("TextLabel", activationSection, {
	Position = UDim2.fromOffset(12, 50),
	Size = UDim2.fromOffset(150, 24),
	BackgroundTransparency = 1,
	Text = "Activation Mode:",
	TextColor3 = THEME.text,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.SourceSans,
	TextSize = 23
})

local holdModeToggle = createToggle(activationSection, "hold", UDim2.fromOffset(176, 52), 72, true)
local toggleModeToggle = createToggle(activationSection, "toggle", UDim2.fromOffset(240, 52), 82, true)

local chooseAppsButton = new("TextButton", activationSection, {
	Position = UDim2.fromOffset(364, 44),
	Size = UDim2.fromOffset(136, 28),
	BackgroundColor3 = THEME.blue,
	Text = "SETTINGS",
	TextColor3 = THEME.white,
	Font = Enum.Font.SourceSansBold,
	TextSize = 21,
	AutoButtonColor = false
})
makeCorner(chooseAppsButton, 3)

local leftButtonToggle = createToggle(clicksSection, BUTTONS.left.label .. "\n" .. BUTTONS.left.short, UDim2.fromOffset(18, 98), 154, true)
leftButtonToggle.label.TextYAlignment = Enum.TextYAlignment.Center
leftButtonToggle.label.TextWrapped = true
leftButtonToggle.label.TextSize = 19

local middleButtonToggle = createToggle(clicksSection, BUTTONS.middle.label .. "\n" .. BUTTONS.middle.short, UDim2.fromOffset(165, 18), 190, true)
middleButtonToggle.label.TextYAlignment = Enum.TextYAlignment.Center
middleButtonToggle.label.TextWrapped = true
middleButtonToggle.label.TextSize = 19

local rightButtonToggle = createToggle(clicksSection, BUTTONS.right.label .. "\n" .. BUTTONS.right.short, UDim2.fromOffset(344, 98), 160, true)
rightButtonToggle.label.TextYAlignment = Enum.TextYAlignment.Center
rightButtonToggle.label.TextWrapped = true
rightButtonToggle.label.TextSize = 19

local mouseShell = new("Frame", clicksSection, {
	Position = UDim2.fromOffset(212, 40),
	Size = UDim2.fromOffset(110, 116),
	BackgroundColor3 = Color3.fromRGB(35, 39, 48),
	BorderSizePixel = 0
})
makeCorner(mouseShell, 55)
makeStroke(mouseShell, THEME.border, 1)

local mouseTopLayer = new("Frame", mouseShell, {
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromOffset(110, 58),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = true
})
makeCorner(mouseTopLayer, 55)

local mouseHighlight = new("Frame", mouseTopLayer, {
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromOffset(110, 58),
	BackgroundColor3 = THEME.red,
	BorderSizePixel = 0
})

local mouseHighlightGradient = new("UIGradient", mouseHighlight, {
	Rotation = 0,
	Transparency = NumberSequence.new(1)
})

new("Frame", mouseShell, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.fromOffset(2, 58),
	BackgroundColor3 = THEME.border,
	BorderSizePixel = 0
})

new("Frame", mouseShell, {
	Position = UDim2.fromOffset(0, 58),
	Size = UDim2.new(1, 0, 0, 2),
	BackgroundColor3 = THEME.border,
	BorderSizePixel = 0
})

local mouseMiddle = new("Frame", mouseShell, {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(0.5, 0),
	Size = UDim2.fromOffset(16, 38),
	BackgroundColor3 = Color3.fromRGB(110, 118, 136),
	BorderSizePixel = 0
})
makeCorner(mouseMiddle, 8)

local rateBox = createField(rateSection, "Click rate", UDim2.fromOffset(12, 12), UDim2.fromOffset(12, 40), UDim2.fromOffset(84, 28), "Clicks per second")
local unlimitedToggle = createToggle(rateSection, "unlimited", UDim2.fromOffset(12, 74), 104, false)
local randomToggle = createToggle(rateSection, "random", UDim2.fromOffset(128, 74), 92, false)

new("TextLabel", rateSection, {
	Position = UDim2.fromOffset(12, 98),
	Size = UDim2.fromOffset(112, 24),
	BackgroundTransparency = 1,
	Text = "Click duty cycle:",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.text,
	Font = Enum.Font.SourceSans,
	TextSize = 20
})

local dutyBox = new("TextBox", rateSection, {
	Position = UDim2.fromOffset(126, 94),
	Size = UDim2.fromOffset(60, 28),
	BackgroundColor3 = THEME.white,
	Text = "",
	Font = Enum.Font.SourceSansSemibold,
	TextSize = 22,
	TextColor3 = THEME.text,
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Center
})
makeStroke(dutyBox, THEME.border, 1)

new("TextLabel", rateSection, {
	Position = UDim2.fromOffset(190, 94),
	Size = UDim2.fromOffset(18, 28),
	BackgroundTransparency = 1,
	Text = "%",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.text,
	Font = Enum.Font.SourceSans,
	TextSize = 22
})

local enableLimitToggle = createToggle(limitSection, "Enable Click Limit", UDim2.fromOffset(12, 18), 156, false)

local maxLabel = new("TextLabel", limitSection, {
	Position = UDim2.fromOffset(12, 56),
	Size = UDim2.fromOffset(72, 28),
	BackgroundTransparency = 1,
	Text = "Maximum",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.muted,
	Font = Enum.Font.SourceSans,
	TextSize = 20
})

local limitBox = new("TextBox", limitSection, {
	Position = UDim2.fromOffset(82, 54),
	Size = UDim2.fromOffset(58, 30),
	BackgroundColor3 = THEME.white,
	Text = "",
	TextColor3 = THEME.text,
	Font = Enum.Font.SourceSansSemibold,
	TextSize = 22,
	ClearTextOnFocus = false,
	TextXAlignment = Enum.TextXAlignment.Center
})
makeStroke(limitBox, THEME.border, 1)

local limitSuffix = new("TextLabel", limitSection, {
	Position = UDim2.fromOffset(148, 56),
	Size = UDim2.fromOffset(64, 28),
	BackgroundTransparency = 1,
	Text = "Clicks",
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.muted,
	Font = Enum.Font.SourceSans,
	TextSize = 20
})

local timingLabel = new("TextLabel", limitSection, {
	Position = UDim2.fromOffset(24, 104),
	Size = UDim2.fromOffset(208, 20),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = THEME.text,
	TextXAlignment = Enum.TextXAlignment.Center,
	Font = Enum.Font.SourceSans,
	TextSize = 19
})

local resetButton = new("TextButton", root, {
	Position = UDim2.fromOffset(128, 496),
	Size = UDim2.fromOffset(180, 32),
	BackgroundColor3 = THEME.blue,
	Text = "RESET SETTINGS",
	TextColor3 = THEME.white,
	Font = Enum.Font.SourceSansBold,
	TextSize = 23,
	AutoButtonColor = false
})
makeCorner(resetButton, 3)

local connections = {}

local function bind(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

if PlayerMouse and PlayerMouse.Move then
	bind(PlayerMouse.Move, function()
		if not UserInputService.TouchEnabled then
			local point = getMousePosition()
			if point then
				lastPointerPosition = point
			end
		end
	end)
end

local function setToggleVisual(toggle, enabled)
	toggle.fill.Visible = enabled
	if toggle.circular then
		toggle.fill.BackgroundColor3 = THEME.blue
	else
		toggle.fill.BackgroundColor3 = enabled and THEME.blue or THEME.white
	end
end

local listeningForKey = false
local dragging = false
local dragStartMouse = nil
local dragStartPos = nil
local active = false
local buttonHeld = false
local releaseAt = 0
local clickAccumulator = 0
local totalClicks = 0
local lastPointerPosition = Vector2.new(0, 0)
local activeTouchInput = nil
local cleaningUp = false
local MAX_BURST_PER_FRAME = 4096

local function getActivationKey()
	return resolveKeyCode(config.activationKey) or resolveKeyCode(DEFAULTS.activationKey) or Enum.KeyCode.P
end

local function buildDockState(text)
	return string.format("%s [%s]", text, config.activationKey)
end

local function setStatus(text, color)
	statusLabel.Text = "Status: " .. text
	statusLabel.TextColor3 = color or THEME.muted
	dockState.Text = buildDockState(text)
	dockState.TextColor3 = color or THEME.muted
	toggleButton.Text = active and "STOP" or "START"
	toggleButton.BackgroundColor3 = active and THEME.red or THEME.green
end

local function getClickInterval()
	local interval = 1 / math.max(config.clickRate, 0.1)
	if config.randomize then
		interval = interval / math.clamp(0.85 + math.random() * 0.3, 0.2, 2)
	end
	return interval
end

local function currentTiming()
	if config.unlimited then
		return nil, nil, nil
	end
	local interval = 1 / math.max(config.clickRate, 0.1)
	local hold = interval * (config.dutyCycle / 100)
	local waitTime = math.max(interval - hold, 0)
	return interval, hold, waitTime
end

local function updateTimingLabel()
	local _, hold, waitTime = currentTiming()
	if config.unlimited then
		timingLabel.Text = "Click / Wait: fastest / fastest"
	else
		timingLabel.Text = "Click / Wait: " .. formatDuration(hold) .. " / " .. formatDuration(waitTime)
	end
end

local function updateButtonGraphic()
	mouseMiddle.BackgroundColor3 = config.clickButton == "middle" and THEME.red or Color3.fromRGB(110, 118, 136)
	if config.clickButton == "left" then
		mouseHighlight.Visible = true
		mouseHighlightGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.499, 0),
			NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(1, 1)
		})
	elseif config.clickButton == "right" then
		mouseHighlight.Visible = true
		mouseHighlightGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.499, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 0)
		})
	else
		mouseHighlight.Visible = false
	end
end

local function updateLimitVisual()
	local enabledBg = config.clickLimitEnabled and THEME.white or Color3.fromRGB(34, 38, 46)
	local enabledText = config.clickLimitEnabled and THEME.text or Color3.fromRGB(106, 113, 126)
	maxLabel.TextColor3 = config.clickLimitEnabled and THEME.text or Color3.fromRGB(106, 113, 126)
	limitSuffix.TextColor3 = maxLabel.TextColor3
	limitBox.BackgroundColor3 = enabledBg
	limitBox.TextEditable = config.clickLimitEnabled
	limitBox.TextColor3 = enabledText
end

local function updateUI()
	keyValue.Text = config.activationKey
	selectKeyButton.Text = listeningForKey and "PRESS KEY..." or "SELECT..."

	setToggleVisual(holdModeToggle, config.activationMode == "hold")
	setToggleVisual(toggleModeToggle, config.activationMode == "toggle")

	setToggleVisual(leftButtonToggle, config.clickButton == "left")
	setToggleVisual(middleButtonToggle, config.clickButton == "middle")
	setToggleVisual(rightButtonToggle, config.clickButton == "right")
	updateButtonGraphic()

	rateBox.Text = formatNumber(config.clickRate, 2)
	dutyBox.Text = formatNumber(config.dutyCycle, 2)
	limitBox.Text = tostring(config.clickLimit)
	setToggleVisual(unlimitedToggle, config.unlimited)
	setToggleVisual(randomToggle, config.randomize)
	setToggleVisual(enableLimitToggle, config.clickLimitEnabled)
	setToggleVisual(appTargetToggle, config.targetRobloxOnly)
	setToggleVisual(appIgnoreUIToggle, config.ignoreOwnUI)
	setToggleVisual(appTypingToggle, config.ignoreFocusedTextBox)
	dockState.Text = buildDockState(active and (config.activationMode == "hold" and "Holding" or "Active") or "Idle")
	updateTimingLabel()
	updateLimitVisual()
	toggleButton.Text = active and "STOP" or "START"
	toggleButton.BackgroundColor3 = active and THEME.red or THEME.green
end

local function persistAndRefresh()
	config = normalizeConfig(config)
	saveConfig(config)
	updateUI()
end

local function getMousePosition()
	if UserInputService.TouchEnabled then
		return lastPointerPosition
	end
	if PlayerMouse and type(PlayerMouse.X) == "number" and type(PlayerMouse.Y) == "number" then
		if PlayerMouse.X > 0 or PlayerMouse.Y > 0 then
			return Vector2.new(PlayerMouse.X, PlayerMouse.Y)
		end
	end
	if UserInputService.MouseEnabled then
		local ok, current = pcall(function()
			return __lt.cm("UserInputService", "GetMouseLocation")
		end)
		if ok and current then
			return current
		end
	end
	return lastPointerPosition
end

local function pointInside(guiObject, point)
	local position = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return point.X >= position.X and point.X <= position.X + size.X and point.Y >= position.Y and point.Y <= position.Y + size.Y
end

local function pointOverOwnUI(point)
	return (root.Visible and pointInside(root, point)) or (dockBar.Visible and pointInside(dockBar, point))
end

local function getOwnUIPoint(point)
	local insetOk, topLeftInset = pcall(function()
		return __lt.cm("GuiService", "GetGuiInset")
	end)
	if insetOk and topLeftInset then
		return Vector2.new(point.X - topLeftInset.X, point.Y - topLeftInset.Y)
	end
	return point
end

local function getDispatchPoint()
	if UserInputService.TouchEnabled then
		local point = getMousePosition()
		local insetOk, topLeftInset = pcall(function()
			return __lt.cm("GuiService", "GetGuiInset")
		end)
		if insetOk and topLeftInset then
			return Vector2.new(point.X + topLeftInset.X, point.Y + topLeftInset.Y)
		end
		return point
	end
	if UserInputService.MouseEnabled then
		local ok, current = pcall(function()
			return __lt.cm("UserInputService", "GetMouseLocation")
		end)
		if ok and current then
			return current
		end
	end
	if PlayerMouse and type(PlayerMouse.X) == "number" and type(PlayerMouse.Y) == "number" then
		local insetOk, topLeftInset = pcall(function()
			return __lt.cm("GuiService", "GetGuiInset")
		end)
		if insetOk and topLeftInset then
			return Vector2.new(PlayerMouse.X + topLeftInset.X, PlayerMouse.Y + topLeftInset.Y)
		end
		return Vector2.new(PlayerMouse.X, PlayerMouse.Y)
	end
	return getMousePosition()
end

local function updatePointerTarget(point)
	if point == nil then
		return
	end
	if not pointOverOwnUI(getOwnUIPoint(point)) then
		lastPointerPosition = point
	end
end

local function pointerOverOwnUI()
	if not config.ignoreOwnUI then
		return false
	end
	return pointOverOwnUI(getOwnUIPoint(getMousePosition()))
end

local function shouldPauseClicks()
	if config.ignoreFocusedTextBox and __lt.cm("UserInputService", "GetFocusedTextBox") then
		return true
	end
	if not UserInputService.MouseEnabled and lastPointerPosition.X <= 0 and lastPointerPosition.Y <= 0 then
		return true
	end
	if pointerOverOwnUI() then
		return true
	end
	return false
end

local function sendButtonState(isDown)
	local point = getDispatchPoint()
	local buttonIndex = BUTTONS[config.clickButton].index
	local ok = false
	if VirtualInputManager and VirtualInputManager.SendMouseButtonEvent then
		ok = pcall(function()
			__lt.cm("VirtualInputManager", "SendMouseButtonEvent", point.X, point.Y, buttonIndex, isDown, game, 0)
		end)
	end
	return ok
end

local function clickNow()
	local point = getDispatchPoint()
	if VirtualInputManager and VirtualInputManager.SendMouseButtonEvent then
		local ok = pcall(function()
			local buttonIndex = BUTTONS[config.clickButton].index
			__lt.cm("VirtualInputManager", "SendMouseButtonEvent", point.X, point.Y, buttonIndex, true, game, 0)
			__lt.cm("VirtualInputManager", "SendMouseButtonEvent", point.X, point.Y, buttonIndex, false, game, 0)
		end)
		if ok then
			return
		end
	end
	if config.clickButton == "left" and type(mouse1click) == "function" then
		pcall(mouse1click)
	elseif config.clickButton == "right" and type(mouse2click) == "function" then
		pcall(mouse2click)
	end
end

local function releaseHeldButton()
	if buttonHeld then
		pcall(sendButtonState, false)
		buttonHeld = false
		releaseAt = 0
	end
end

local function clearRuntimeState()
	dragging = false
	dragStartMouse = nil
	dragStartPos = nil
	activeTouchInput = nil
	clickAccumulator = 0
	releaseHeldButton()
end

local function stopClicking(statusText)
	active = false
	clearRuntimeState()
	if statusText == "Click limit reached" then
		setStatus(statusText, THEME.red)
	else
		setStatus(statusText or "Idle", THEME.muted)
	end
end

local function startClicking(statusText)
	totalClicks = 0
	clickAccumulator = 0
	active = true
	setStatus(statusText or "Active", THEME.green)
end

local function toggleClicking()
	if active then
		stopClicking("Idle")
	else
		startClicking("Active")
	end
end

local function performConfiguredClick(now, interval)
	if config.clickLimitEnabled and totalClicks >= config.clickLimit then
		stopClicking("Click limit reached")
		return
	end

	if config.unlimited then
		clickNow()
		totalClicks = totalClicks + 1
		return
	end

	interval = interval or getClickInterval()
	local holdDuration = interval * (config.dutyCycle / 100)
	local fastPath = interval < (1 / 120)
	if not fastPath and sendButtonState(true) then
		buttonHeld = true
		releaseAt = now + holdDuration
	else
		clickNow()
	end
	totalClicks = totalClicks + 1

	if config.clickLimitEnabled and totalClicks >= config.clickLimit then
		stopClicking("Click limit reached")
	end
end

bind(RunService.Heartbeat, function(dt)
	updateViewportLayout()

	if UserInputService.TouchEnabled then
		local ok, touches = pcall(function()
			return __lt.cm("UserInputService", "GetTouches")
		end)
		if ok and type(touches) == "table" then
			local matchedTouch = nil
			if activeTouchInput ~= nil then
				for _, touch in ipairs(touches) do
					if touch == activeTouchInput then
						matchedTouch = touch
						break
					end
				end
			end

			if matchedTouch and matchedTouch.Position then
				updatePointerTarget(Vector2.new(matchedTouch.Position.X, matchedTouch.Position.Y))
			else
				activeTouchInput = nil
				for _, touch in ipairs(touches) do
					if touch and touch.Position then
						local point = Vector2.new(touch.Position.X, touch.Position.Y)
						if not pointOverOwnUI(getOwnUIPoint(point)) then
							activeTouchInput = touch
							lastPointerPosition = point
							break
						end
					end
				end
			end
		else
			activeTouchInput = nil
		end
	elseif (PlayerMouse and type(PlayerMouse.X) == "number" and type(PlayerMouse.Y) == "number" and (PlayerMouse.X > 0 or PlayerMouse.Y > 0)) or UserInputService.MouseEnabled then
		local point = getMousePosition()
		if point then
			lastPointerPosition = point
		end
	end

	if buttonHeld and os.clock() >= releaseAt then
		releaseHeldButton()
	end

	if not active then
		return
	end

	if shouldPauseClicks() then
		releaseHeldButton()
		clickAccumulator = 0
		return
	end

	if config.unlimited then
		for _ = 1, MAX_BURST_PER_FRAME do
			if not active then
				break
			end
			performConfiguredClick(os.clock())
		end
		return
	end

	clickAccumulator = clickAccumulator + (dt or (1 / 60))
	local now = os.clock()
	if config.randomize then
		local burst = 0
		while active and burst < MAX_BURST_PER_FRAME do
			local interval = getClickInterval()
			if clickAccumulator < interval then
				break
			end
			clickAccumulator = clickAccumulator - interval
			performConfiguredClick(now, interval)
			burst = burst + 1
		end
		return
	end

	local interval = 1 / math.max(config.clickRate, 0.1)
	local clicksDue = math.floor(clickAccumulator / interval)
	if clicksDue <= 0 then
		return
	end
	clicksDue = math.min(clicksDue, MAX_BURST_PER_FRAME)
	clickAccumulator = clickAccumulator - (clicksDue * interval)
	for _ = 1, clicksDue do
		if not active then
			break
		end
		performConfiguredClick(now, interval)
	end
end)

local function showApps()
	overlay.Visible = true
	appsModal.Visible = true
end

local function hideOverlay()
	overlay.Visible = false
	appsModal.Visible = false
end

bind(chooseAppsButton.MouseButton1Click, showApps)
bind(appsClose.MouseButton1Click, function()
	persistAndRefresh()
	hideOverlay()
end)

bind(overlay.InputBegan, function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local point = Vector2.new(input.Position.X, input.Position.Y)
	if appsModal.Visible and not pointInside(appsModal, point) then
		hideOverlay()
	end
end)

bind(selectKeyButton.MouseButton1Click, function()
	listeningForKey = true
	setStatus("Waiting for key", THEME.blueDark)
	updateUI()
end)

bind(holdModeToggle.button.MouseButton1Click, function()
	config.activationMode = "hold"
	stopClicking("Idle")
	persistAndRefresh()
end)

bind(toggleModeToggle.button.MouseButton1Click, function()
	config.activationMode = "toggle"
	persistAndRefresh()
end)

local function setClickButton(name)
	config.clickButton = name
	persistAndRefresh()
end

bind(leftButtonToggle.button.MouseButton1Click, function()
	setClickButton("left")
end)

bind(middleButtonToggle.button.MouseButton1Click, function()
	setClickButton("middle")
end)

bind(rightButtonToggle.button.MouseButton1Click, function()
	setClickButton("right")
end)

bind(unlimitedToggle.button.MouseButton1Click, function()
	config.unlimited = not config.unlimited
	persistAndRefresh()
end)

bind(randomToggle.button.MouseButton1Click, function()
	config.randomize = not config.randomize
	persistAndRefresh()
end)

bind(enableLimitToggle.button.MouseButton1Click, function()
	config.clickLimitEnabled = not config.clickLimitEnabled
	if config.clickLimitEnabled and config.clickLimit <= 0 then
		config.clickLimit = 1
	end
	persistAndRefresh()
end)

bind(appTargetToggle.button.MouseButton1Click, function()
	config.targetRobloxOnly = not config.targetRobloxOnly
	persistAndRefresh()
end)

bind(appIgnoreUIToggle.button.MouseButton1Click, function()
	config.ignoreOwnUI = not config.ignoreOwnUI
	persistAndRefresh()
end)

bind(appTypingToggle.button.MouseButton1Click, function()
	config.ignoreFocusedTextBox = not config.ignoreFocusedTextBox
	persistAndRefresh()
end)

bind(resetButton.MouseButton1Click, function()
	config = cloneTable(DEFAULTS)
	stopClicking("Settings reset")
	persistAndRefresh()
end)

bind(toggleButton.MouseButton1Click, toggleClicking)

local function parseNumberBox(text, fallback)
	local numeric = tonumber(text)
	if numeric == nil then
		return fallback
	end
	return numeric
end

bind(rateBox.FocusLost, function()
	config.clickRate = math.max(parseNumberBox(rateBox.Text, config.clickRate), 0.1)
	persistAndRefresh()
end)

bind(dutyBox.FocusLost, function()
	config.dutyCycle = math.clamp(parseNumberBox(dutyBox.Text, config.dutyCycle), 1, 99)
	persistAndRefresh()
end)

bind(limitBox.FocusLost, function()
	local parsed = math.floor(parseNumberBox(limitBox.Text, config.clickLimit))
	config.clickLimit = math.max(parsed, 0)
	if config.clickLimitEnabled and config.clickLimit <= 0 then
		config.clickLimit = 1
	end
	persistAndRefresh()
end)

local function hideToDock()
	root.Visible = false
	dockBar.Visible = true
end

local function showFromDock()
	dockBar.Visible = false
	root.Visible = true
end

bind(minimizeButton.MouseButton1Click, function()
	hideOverlay()
	hideToDock()
end)

bind(dockOpen.MouseButton1Click, showFromDock)

local function cleanup()
	if cleaningUp then
		return
	end
	cleaningUp = true
	stopClicking("Closed")
	activeTouchInput = nil
	for _, connection in ipairs(connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(connections)
	sharedEnv.AutoClickerCleanup = nil
	if sharedEnv.AutoClickerState == sharedState then
		sharedState.loaded = false
		sharedState.cleanup = nil
	end
	ui:Destroy()
end

bind(exitButton.MouseButton1Click, cleanup)
bind(closeButton.MouseButton1Click, cleanup)
bind(dockExit.MouseButton1Click, cleanup)

local function beginDrag(input)
	if overlay.Visible then
		return
	end
	dragging = true
	dragStartPos = root.Position
	dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
end

bind(header.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginDrag(input)
	end
end)

bind(titleLabel.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginDrag(input)
	end
end)

bind(UserInputService.InputChanged, function(input)
	if UserInputService.TouchEnabled then
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
	elseif input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if input.Position then
		updatePointerTarget(Vector2.new(input.Position.X, input.Position.Y))
	end
	if dragging and dragStartPos and dragStartMouse then
		local current = Vector2.new(input.Position.X, input.Position.Y)
		local delta = current - dragStartMouse
		root.Position = UDim2.new(
			dragStartPos.X.Scale,
			dragStartPos.X.Offset + delta.X,
			dragStartPos.Y.Scale,
			dragStartPos.Y.Offset + delta.Y
		)
	end
end)

bind(UserInputService.InputEnded, function(input)
	if (not UserInputService.TouchEnabled and input.UserInputType == Enum.UserInputType.MouseButton1) or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

bind(UserInputService.InputBegan, function(input, processed)
	if input.Position then
		if ((not UserInputService.TouchEnabled and input.UserInputType == Enum.UserInputType.MouseButton1) or input.UserInputType == Enum.UserInputType.Touch) then
			updatePointerTarget(Vector2.new(input.Position.X, input.Position.Y))
		end
	end

	if listeningForKey then
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
			config.activationKey = input.KeyCode.Name
			listeningForKey = false
			persistAndRefresh()
			setStatus("Key set", THEME.green)
		end
		return
	end

	if processed and input.UserInputType == Enum.UserInputType.Keyboard then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
	if input.KeyCode ~= getActivationKey() then
		return
	end
	if config.ignoreFocusedTextBox and __lt.cm("UserInputService", "GetFocusedTextBox") then
		return
	end

	if config.activationMode == "toggle" then
		toggleClicking()
	else
		startClicking("Holding")
	end
end)

bind(UserInputService.InputEnded, function(input)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
	if input.KeyCode ~= getActivationKey() then
		return
	end
	if config.activationMode == "hold" then
		stopClicking("Idle")
	end
end)

if UserInputService.TouchStarted then
	bind(UserInputService.TouchStarted, function(input)
		if input and input.Position then
			activeTouchInput = input
			updatePointerTarget(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
end

if UserInputService.TouchMoved then
	bind(UserInputService.TouchMoved, function(input)
		if input and input.Position then
			if activeTouchInput == nil or input == activeTouchInput then
				activeTouchInput = input
			end
			updatePointerTarget(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
end

if UserInputService.TouchEnded then
	bind(UserInputService.TouchEnded, function(input)
		if input == activeTouchInput then
			activeTouchInput = nil
		end
	end)
end

sharedEnv.AutoClickerCleanup = cleanup
sharedState.loaded = true
sharedState.cleanup = cleanup

persistAndRefresh()
setStatus("Idle", THEME.muted)
