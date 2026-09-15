-- BETA: Arceus X customization module is unfinished and may break after Arceus UI updates.
--!nocheck
local __acm_boot = {}
__acm_boot.hostEnv = (getgenv and getgenv()) or _G or {}
__acm_boot.hostGetfenv = type(__acm_boot.hostEnv.getfenv) == "function" and __acm_boot.hostEnv.getfenv or getfenv
__acm_boot.hostSetfenv = type(__acm_boot.hostEnv.setfenv) == "function" and __acm_boot.hostEnv.setfenv or setfenv
__acm_boot.debug = rawget(__acm_boot.hostEnv, "debug") or debug
__acm_boot.registry = nil
if type(getreg) == "function" then
    pcall(function()
        __acm_boot.registry = getreg()
    end)
end
if type(__acm_boot.registry) ~= "table" and type(__acm_boot.debug) == "table" and type(__acm_boot.debug.getregistry) == "function" then
    pcall(function()
        __acm_boot.registry = __acm_boot.debug.getregistry()
    end)
end
if type(__acm_boot.registry) ~= "table" then
    __acm_boot.registry = {}
end
local function __acm_privateTable(parent, key)
    local value = rawget(parent, key)
    if type(value) ~= "table" then
        value = {}
        rawset(parent, key, value)
    end
    return value
end
__acm_boot.privateRoot = __acm_privateTable(__acm_boot.registry, "__nameless_admin_private")
local __acm_env = __acm_privateTable(__acm_boot.privateRoot, "arceus_customization")
local __acm_shared = __acm_privateTable(__acm_env, "shared")
local __acm_runtimeEnv = __acm_privateTable(__acm_env, "runtime")
__acm_runtimeEnv._G = __acm_runtimeEnv
__acm_runtimeEnv.shared = __acm_shared
__acm_runtimeEnv.getgenv = function()
    return __acm_runtimeEnv
end
__acm_runtimeEnv.getfenv = function(target)
    if target == nil or target == 0 then
        return __acm_runtimeEnv
    end
    if type(__acm_boot.hostGetfenv) == "function" then
        return __acm_boot.hostGetfenv(target)
    end
    return __acm_runtimeEnv
end
setmetatable(__acm_runtimeEnv, {
    __index = function(_, key)
        if key == "_G" then
            return __acm_runtimeEnv
        elseif key == "shared" then
            return __acm_shared
        elseif key == "getgenv" then
            return __acm_runtimeEnv.getgenv
        elseif key == "getfenv" then
            return __acm_runtimeEnv.getfenv
        end
        return __acm_boot.hostEnv[key]
    end,
})
if type(__acm_boot.hostSetfenv) == "function" then
    pcall(__acm_boot.hostSetfenv, 1, __acm_runtimeEnv)
end
local hostEnv = __acm_boot.hostEnv

local executorName = ""
pcall(function()
    executorName = tostring(identifyexecutor()):lower()
end)
if executorName ~= "" and not executorName:find("arceus", 1, true) then
    return
end

if type(__acm_env.__ArceusCustomizationRuntime) == "table" and type(__acm_env.__ArceusCustomizationRuntime.stop) == "function" then
    pcall(__acm_env.__ArceusCustomizationRuntime.stop)
end

local function getLoader()
    local loader = rawget(hostEnv, "loadstring") or loadstring
    return type(loader) == "function" and loader or nil
end

local function loadRemoteModule(url, chunkName)
    local loader = getLoader()
    if not loader then
        return nil
    end
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or type(source) ~= "string" or source == "" then
        return nil
    end
    local fn = loader(source, chunkName)
    if type(fn) ~= "function" then
        return nil
    end
    if type(__acm_boot.hostSetfenv) == "function" then
        pcall(__acm_boot.hostSetfenv, fn, __acm_runtimeEnv)
    end
    local ok2, result = pcall(fn)
    if ok2 then
        return result
    end
    return nil
end

local Resolver = loadRemoteModule("https://ltseverydayyou.github.io/ServiceResolver.luau", "@ServiceResolver.luau")
local UIProtector = loadRemoteModule("https://ltseverydayyou.github.io/UIprotector.luau", "@UIprotector.luau")
local ref = cloneref and type(cloneref) == "function" and cloneref or function(v)
    return v
end
local services = setmetatable({}, {
    __index = function(self, name)
        local service
        if type(Resolver) == "table" and type(Resolver.cs) == "function" then
            local ok, value = pcall(Resolver.cs, name, ref)
            if ok then
                service = value
            end
        end
        if not service then
            local ok, value = pcall(game.GetService, game, name)
            if ok then
                service = ref(value)
            end
        end
        rawset(self, name, service)
        return service
    end,
})

local CoreGui = services.CoreGui
local HttpService = services.HttpService
local RunService = services.RunService
local StarterGui = services.StarterGui
local TweenService = services.TweenService

local runtime = {
    version = "0.1.5",
    alive = true,
    conns = {},
    originals = setmetatable({}, { __mode = "k" }),
    custom = {},
    refs = {},
    applying = {},
}
__acm_env.__ArceusCustomizationRuntime = runtime

local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 4,
        })
    end)
end

local function remember(object, property)
    if not object then
        return
    end
    local entry = runtime.originals[object]
    if not entry then
        entry = {}
        runtime.originals[object] = entry
    end
    if entry[property] ~= nil then
        return
    end
    local ok, value = pcall(function()
        return object[property]
    end)
    if ok then
        entry[property] = { value = value }
    end
end

local function setTracked(object, property, value)
    if not object then
        return false
    end
    remember(object, property)
    return pcall(function()
        object[property] = value
    end)
end

local function registerCustom(object)
    if object then
        runtime.custom[#runtime.custom + 1] = object
    end
    return object
end

local function connect(signal, callback)
    if not signal then
        return nil
    end
    local ok, connection = pcall(function()
        return signal:Connect(callback)
    end)
    if ok and connection then
        runtime.conns[#runtime.conns + 1] = connection
        return connection
    end
end

local function clearConnections()
    for i = #runtime.conns, 1, -1 do
        local connection = runtime.conns[i]
        pcall(function()
            connection:Disconnect()
        end)
        runtime.conns[i] = nil
    end
end

local function lowerText(value)
    return tostring(value or ""):gsub("%s+", " "):lower()
end

local function textOf(object)
    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
        return object.Text
    end
    return nil
end

local function collectTextFlags(root, wanted)
    local flags = {}
    local count = 0
    if not root then
        return flags, count
    end
    for _, object in ipairs(root:GetDescendants()) do
        count += 1
        local text = textOf(object)
        if type(text) == "string" and text ~= "" then
            local normalized = lowerText(text)
            for key, needle in pairs(wanted) do
                if not flags[key] and normalized:find(needle, 1, true) then
                    flags[key] = true
                end
            end
        end
    end
    return flags, count
end

local function hasText(root, needle, exact)
    needle = lowerText(needle)
    for _, object in ipairs(root:GetDescendants()) do
        local text = textOf(object)
        if type(text) == "string" then
            local normalized = lowerText(text)
            if exact then
                if normalized == needle then
                    return true
                end
            elseif normalized:find(needle, 1, true) then
                return true
            end
        end
    end
    return false
end

local function getScanRoots()
    local result = {}
    local seen = {}
    local function add(root)
        if typeof(root) == "Instance" and not seen[root] then
            seen[root] = true
            result[#result + 1] = root
        end
    end
    add(CoreGui)
    if UIProtector and type(UIProtector.huiGrabber) == "function" then
        local ok, hui = pcall(UIProtector.huiGrabber)
        if ok then
            add(hui)
        end
    end
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok then
            add(hui)
        end
    end
    return result
end

local function gatherScreenGuis()
    local list = {}
    local seen = {}
    local function add(object)
        if object and object:IsA("ScreenGui") and not seen[object] then
            seen[object] = true
            list[#list + 1] = object
        end
    end
    for _, root in ipairs(getScanRoots()) do
        if root:IsA("ScreenGui") then
            add(root)
        end
        for _, child in ipairs(root:GetChildren()) do
            add(child)
            if child:IsA("Folder") or child:IsA("ScreenGui") then
                for _, sub in ipairs(child:GetChildren()) do
                    add(sub)
                end
            end
        end
    end
    return list
end

local function scoreArceusGui(gui)
    local flags, count = collectTextFlags(gui, {
        arceus = "arceus x",
        neo = "neo",
        executor = "executor & scripts handler",
        hub = "script hub",
        hacks = "auto-hacks",
    })
    local score = 0
    if flags.arceus then score += 12 end
    if flags.neo then score += 4 end
    if flags.executor then score += 10 end
    if flags.hub then score += 4 end
    if flags.hacks then score += 3 end
    if count >= 1000 then score += 3 end
    if count >= 3000 then score += 2 end
    return score
end

local function findArceusGui()
    local best
    local bestScore = 0
    for _, gui in ipairs(gatherScreenGuis()) do
        local score = scoreArceusGui(gui)
        if score > bestScore then
            best = gui
            bestScore = score
        end
    end
    if bestScore >= 20 then
        return best
    end
    return nil
end

local function scoreMainFrame(frame)
    if not frame:IsA("Frame") then
        return -1
    end
    local flags, count = collectTextFlags(frame, {
        arceus = "arceus x",
        neo = "neo",
        executor = "executor & scripts handler",
        general = "general",
    })
    local score = 0
    if flags.arceus then score += 8 end
    if flags.neo then score += 3 end
    if flags.executor then score += 8 end
    if flags.general then score += 2 end
    if count >= 1500 then score += 3 end
    if count >= 3000 then score += 2 end
    if frame:FindFirstChildWhichIsA("UIAspectRatioConstraint") then score += 2 end
    return score
end

local function findMainFrame(gui)
    local best
    local bestScore = 0
    for _, child in ipairs(gui:GetChildren()) do
        if child:IsA("Frame") then
            local score = scoreMainFrame(child)
            if score > bestScore then
                best = child
                bestScore = score
            end
        end
    end
    if bestScore >= 15 then
        return best
    end
    return nil
end

local function scorePageHost(parent)
    if not parent or not parent:IsA("GuiObject") then
        return -1
    end
    local executorPage = false
    local hubPage = false
    local settingsPage = false
    local homePage = false
    for _, child in ipairs(parent:GetChildren()) do
        if child:IsA("Frame") then
            if hasText(child, "Execute clipboard", true) and hasText(child, "Console", true) then
                executorPage = true
            end
            if hasText(child, "CloudScripts", true) and hasText(child, "LocalScripts", true) then
                hubPage = true
            end
            if hasText(child, "Startup page", true) and hasText(child, "Personalization", true) then
                settingsPage = true
            end
            if hasText(child, "Key System Status", true) then
                homePage = true
            end
        end
    end
    local score = 0
    if executorPage then score += 6 end
    if hubPage then score += 5 end
    if settingsPage then score += 7 end
    if homePage then score += 2 end
    return score
end

local function findPageHost(main)
    local best
    local bestScore = 0
    for _, object in ipairs(main:GetDescendants()) do
        if object:IsA("UIPageLayout") and object.Parent then
            local score = scorePageHost(object.Parent)
            if score > bestScore then
                best = object.Parent
                bestScore = score
            end
        end
    end
    if bestScore >= 12 then
        return best
    end
    return nil
end

local function findSettingsPage(pageHost)
    if not pageHost then
        return nil
    end
    local best
    local bestScore = 0
    for _, child in ipairs(pageHost:GetChildren()) do
        if child:IsA("Frame") then
            local score = 0
            if hasText(child, "Startup page", true) then score += 5 end
            if hasText(child, "Startup window state", true) then score += 4 end
            if hasText(child, "Personalization", true) then score += 5 end
            if hasText(child, "Reset ALL settings", true) then score += 3 end
            if score > bestScore then
                best = child
                bestScore = score
            end
        end
    end
    if bestScore >= 10 then
        return best
    end
    return nil
end

local function findSettingsScroller(settingsPage)
    if not settingsPage then
        return nil
    end
    local best
    local bestScore = 0
    for _, object in ipairs(settingsPage:GetDescendants()) do
        if object:IsA("ScrollingFrame") then
            local score = 0
            if hasText(object, "Personalization", true) then score += 5 end
            if hasText(object, "Main color", true) then score += 4 end
            if hasText(object, "Animations", true) then score += 3 end
            if hasText(object, "Reset ALL settings", true) then score += 2 end
            if score > bestScore then
                best = object
                bestScore = score
            end
        end
    end
    if bestScore >= 8 then
        return best
    end
    return nil
end

local function findFloatingIcon(gui)
    local best
    local bestScore = -math.huge
    for _, child in ipairs(gui:GetChildren()) do
        if child:IsA("ImageButton") then
            local score = 0
            local size = child.AbsoluteSize
            if size.X >= 40 and size.X <= 150 and size.Y >= 40 and size.Y <= 150 then
                score += 4
            end
            if size.Y > 0 then
                local ratio = size.X / size.Y
                if ratio >= 0.75 and ratio <= 1.25 then
                    score += 4
                end
            end
            if child:FindFirstChildWhichIsA("UICorner") then score += 2 end
            if child:FindFirstChildWhichIsA("UIAspectRatioConstraint") then score += 2 end
            local imageCount = 0
            local buttonCount = 0
            for _, object in ipairs(child:GetDescendants()) do
                if object:IsA("ImageLabel") then imageCount += 1 end
                if object:IsA("TextButton") then buttonCount += 1 end
            end
            if imageCount >= 1 then score += 3 end
            if buttonCount >= 3 then score += 2 end
            if score > bestScore then
                best = child
                bestScore = score
            end
        end
    end
    if bestScore >= 10 then
        return best
    end
    return nil
end

local function findIconImage(icon)
    if not icon then
        return nil
    end
    local best
    local bestArea = -1
    for _, object in ipairs(icon:GetDescendants()) do
        if object:IsA("ImageLabel") and type(object.Image) == "string" and object.Image ~= "" then
            local size = object.AbsoluteSize
            local area = size.X * size.Y
            if area > bestArea then
                best = object
                bestArea = area
            end
        end
    end
    return best
end

local baseDir = "ArceusCustom"
local settingsPath = baseDir .. "/Settings.json"
local assetDir = baseDir .. "/Assets"

local function fsReady()
    return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function ensureFolder(path)
    if type(isfolder) ~= "function" or type(makefolder) ~= "function" then
        return false
    end
    local ok, exists = pcall(isfolder, path)
    if ok and exists then
        return true
    end
    return pcall(makefolder, path)
end

local defaults = {
    uiScale = 1,
    windowTransparency = -1,
    cornerRadius = -1,
    iconVisible = true,
    iconSize = 1,
    iconShape = "Default",
    rgbIcon = false,
    rgbSpeed = 0.2,
    saveIconPosition = false,
    iconPosition = nil,
    customIconSource = "",
    backgroundSource = "",
    backgroundTransparency = 0.3,
}

local config = {}
for key, value in pairs(defaults) do
    config[key] = value
end

local function loadConfig()
    if not fsReady() or not HttpService then
        return
    end
    ensureFolder(baseDir)
    ensureFolder(assetDir)
    if not isfile(settingsPath) then
        return
    end
    local ok, raw = pcall(readfile, settingsPath)
    if not ok or type(raw) ~= "string" then
        return
    end
    local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
    if ok2 and type(decoded) == "table" then
        for key, value in pairs(decoded) do
            if defaults[key] ~= nil or key == "iconPosition" then
                config[key] = value
            end
        end
    end
end

local function saveConfig()
    if not fsReady() or not HttpService then
        return false
    end
    ensureFolder(baseDir)
    ensureFolder(assetDir)
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, config)
    if not ok or type(encoded) ~= "string" then
        return false
    end
    return pcall(writefile, settingsPath, encoded)
end

loadConfig()

local requestFn = rawget(hostEnv, "request") or rawget(hostEnv, "http_request") or request or http_request
local assetFn = rawget(hostEnv, "getcustomasset") or rawget(hostEnv, "getsynasset") or getcustomasset or getsynasset

local function normalizeAssetSource(source)
    if type(source) ~= "string" then
        return ""
    end
    return source:match("^%s*(.-)%s*$") or ""
end

local function resolveAsset(source, key)
    source = normalizeAssetSource(source)
    if source == "" then
        return nil
    end
    if source:match("^rbxassetid://") or source:match("^rbxasset://") or source:match("^rbxthumb://") then
        return source
    end
    if source:match("^%d+$") then
        return "rbxassetid://" .. source
    end
    if type(assetFn) == "function" and type(isfile) == "function" and isfile(source) then
        local ok, asset = pcall(assetFn, source)
        if ok and type(asset) == "string" then
            return asset
        end
    end
    if source:match("^https?://") and type(requestFn) == "function" and type(writefile) == "function" and type(assetFn) == "function" then
        ensureFolder(baseDir)
        ensureFolder(assetDir)
        local ok, response = pcall(requestFn, { Url = source, Method = "GET" })
        if ok and type(response) == "table" then
            local status = tonumber(response.StatusCode or response.Status or response.status_code) or 0
            local body = response.Body or response.body
            if (status == 0 or status >= 200 and status < 300) and type(body) == "string" and body ~= "" then
                local ext = source:lower():match("%.([a-z0-9]+)[%?#]?") or "png"
                if ext ~= "png" and ext ~= "jpg" and ext ~= "jpeg" and ext ~= "webp" then
                    ext = "png"
                end
                local path = string.format("%s/%s.%s", assetDir, key, ext)
                local wrote = pcall(writefile, path, body)
                if wrote then
                    local ok2, asset = pcall(assetFn, path)
                    if ok2 and type(asset) == "string" then
                        return asset
                    end
                end
            end
        end
    end
    return nil
end

local mainScale
local mainCornerBase
local iconScale
local iconCornerBase
local iconImageBase
local iconStroke
local backgroundImage
local settingsPanel
local settingsLayout
local sidebarButtons = {}

local function applyUiScale()
    local main = runtime.refs.main
    if not main then
        return
    end
    local value = math.clamp(tonumber(config.uiScale) or 1, 0.65, 1.35)
    config.uiScale = value
    if not mainScale or mainScale.Parent ~= main then
        local existing = main:FindFirstChild("LT_ArceusScale")
        if existing and existing:IsA("UIScale") then
            mainScale = existing
        else
            mainScale = registerCustom(Instance.new("UIScale"))
            mainScale.Name = "LT_ArceusScale"
            mainScale.Parent = main
        end
    end
    mainScale.Scale = value
end

local function applyWindowTransparency()
    local main = runtime.refs.main
    if not main then
        return
    end
    local value = tonumber(config.windowTransparency) or -1
    if value < 0 then
        local original = runtime.originals[main] and runtime.originals[main].BackgroundTransparency
        if original then
            pcall(function()
                main.BackgroundTransparency = original.value
            end)
        end
        return
    end
    setTracked(main, "BackgroundTransparency", math.clamp(value, 0, 0.95))
end

local function applyCornerRadius()
    local corner = runtime.refs.mainCorner
    if not corner then
        return
    end
    local value = tonumber(config.cornerRadius) or -1
    if value < 0 then
        if mainCornerBase then
            setTracked(corner, "CornerRadius", mainCornerBase)
        end
        return
    end
    setTracked(corner, "CornerRadius", UDim.new(0, math.clamp(value, 0, 36)))
end

local function applyIconVisible()
    local icon = runtime.refs.icon
    if icon then
        setTracked(icon, "Visible", config.iconVisible ~= false)
    end
end

local function applyIconSize()
    local icon = runtime.refs.icon
    if not icon then
        return
    end
    local value = math.clamp(tonumber(config.iconSize) or 1, 0.5, 2.5)
    config.iconSize = value
    if not iconScale or iconScale.Parent ~= icon then
        local existing = icon:FindFirstChild("LT_ArceusIconScale")
        if existing and existing:IsA("UIScale") then
            iconScale = existing
        else
            iconScale = registerCustom(Instance.new("UIScale"))
            iconScale.Name = "LT_ArceusIconScale"
            iconScale.Parent = icon
        end
    end
    iconScale.Scale = value
end

local function applyIconShape()
    local corner = runtime.refs.iconCorner
    if not corner then
        return
    end
    local shape = tostring(config.iconShape or "Default")
    local radius = iconCornerBase
    if shape == "Square" then
        radius = UDim.new(0, 0)
    elseif shape == "Rounded" then
        radius = UDim.new(0, 10)
    elseif shape == "Circle" then
        radius = UDim.new(1, 0)
    end
    if radius then
        setTracked(corner, "CornerRadius", radius)
    end
end

local function ensureIconStroke()
    local icon = runtime.refs.icon
    if not icon then
        return nil
    end
    if iconStroke and iconStroke.Parent == icon then
        return iconStroke
    end
    iconStroke = icon:FindFirstChildWhichIsA("UIStroke")
    if iconStroke then
        remember(iconStroke, "Enabled")
        remember(iconStroke, "Color")
        remember(iconStroke, "Thickness")
        remember(iconStroke, "Transparency")
    else
        iconStroke = registerCustom(Instance.new("UIStroke"))
        iconStroke.Name = "LT_ArceusIconStroke"
        iconStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        iconStroke.Thickness = 1.5
        iconStroke.Transparency = 0.08
        iconStroke.Color = Color3.fromRGB(79, 164, 242)
        iconStroke.Parent = icon
    end
    return iconStroke
end

local function applyRgbState()
    local stroke = ensureIconStroke()
    if not stroke then
        return
    end
    setTracked(stroke, "Enabled", config.rgbIcon == true)
    if config.rgbIcon ~= true then
        setTracked(stroke, "Color", Color3.fromRGB(79, 164, 242))
    end
end

local function applyIconPosition()
    local icon = runtime.refs.icon
    local pos = config.iconPosition
    if not icon or config.saveIconPosition ~= true or type(pos) ~= "table" then
        return
    end
    local xs = tonumber(pos.xScale)
    local xo = tonumber(pos.xOffset)
    local ys = tonumber(pos.yScale)
    local yo = tonumber(pos.yOffset)
    if xs and xo and ys and yo then
        setTracked(icon, "Position", UDim2.new(xs, xo, ys, yo))
    end
end

local function saveIconPosition()
    local icon = runtime.refs.icon
    if not icon or config.saveIconPosition ~= true then
        return
    end
    config.iconPosition = {
        xScale = icon.Position.X.Scale,
        xOffset = icon.Position.X.Offset,
        yScale = icon.Position.Y.Scale,
        yOffset = icon.Position.Y.Offset,
    }
    saveConfig()
end

local function applyCustomIcon()
    local image = runtime.refs.iconImage
    if not image then
        return false
    end
    local source = normalizeAssetSource(config.customIconSource)
    if source == "" then
        if iconImageBase then
            setTracked(image, "Image", iconImageBase)
        end
        return true
    end
    local asset = resolveAsset(source, "icon")
    if asset then
        setTracked(image, "Image", asset)
        setTracked(image, "ImageColor3", Color3.new(1, 1, 1))
        return true
    end
    return false
end

local function ensureBackground()
    local main = runtime.refs.main
    if not main then
        return nil
    end
    if backgroundImage and backgroundImage.Parent == main then
        return backgroundImage
    end
    backgroundImage = registerCustom(Instance.new("ImageLabel"))
    backgroundImage.Name = "LT_ArceusBackground"
    backgroundImage.AnchorPoint = Vector2.new(0, 0)
    backgroundImage.Position = UDim2.fromScale(0, 0)
    backgroundImage.Size = UDim2.fromScale(1, 1)
    backgroundImage.BackgroundTransparency = 1
    backgroundImage.BorderSizePixel = 0
    backgroundImage.ScaleType = Enum.ScaleType.Crop
    backgroundImage.ZIndex = 0
    backgroundImage.Active = false
    backgroundImage.Visible = false
    local corner = Instance.new("UICorner")
    corner.Name = "LT_ArceusBackgroundCorner"
    corner.CornerRadius = runtime.refs.mainCorner and runtime.refs.mainCorner.CornerRadius or UDim.new(0, 12)
    corner.Parent = backgroundImage
    backgroundImage.Parent = main
    return backgroundImage
end

local function applyBackground()
    local image = ensureBackground()
    if not image then
        return false
    end
    local source = normalizeAssetSource(config.backgroundSource)
    if source == "" then
        image.Visible = false
        return true
    end
    local asset = resolveAsset(source, "background")
    if not asset then
        image.Visible = false
        return false
    end
    image.Image = asset
    image.ImageColor3 = Color3.new(1, 1, 1)
    image.ImageTransparency = math.clamp(tonumber(config.backgroundTransparency) or 0.3, 0, 0.95)
    image.Visible = true
    local corner = image:FindFirstChildWhichIsA("UICorner")
    if corner and runtime.refs.mainCorner then
        corner.CornerRadius = runtime.refs.mainCorner.CornerRadius
    end
    return true
end

local function applyAll()
    applyUiScale()
    applyWindowTransparency()
    applyCornerRadius()
    applyIconVisible()
    applyIconSize()
    applyIconShape()
    applyRgbState()
    applyIconPosition()
    if normalizeAssetSource(config.customIconSource) ~= "" then
        task.spawn(applyCustomIcon)
    end
    if normalizeAssetSource(config.backgroundSource) ~= "" then
        task.spawn(applyBackground)
    else
        applyBackground()
    end
end

local function makeCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function makeStroke(parent, color)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(60, 66, 80)
    stroke.Thickness = 1
    stroke.Transparency = 0.25
    stroke.Parent = parent
    return stroke
end

local function makeText(parent, text, size, bold)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(235, 239, 247)
    label.TextSize = size or 13
    label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

local function makeButton(parent, text, width)
    local button = Instance.new("TextButton")
    button.AutoButtonColor = true
    button.BackgroundColor3 = Color3.fromRGB(38, 43, 54)
    button.BorderSizePixel = 0
    button.Size = UDim2.fromOffset(width or 108, 28)
    button.Text = text
    button.TextColor3 = Color3.fromRGB(240, 244, 250)
    button.TextSize = 12
    button.Font = Enum.Font.GothamSemibold
    button.Parent = parent
    makeCorner(button, 7)
    makeStroke(button, Color3.fromRGB(74, 87, 110))
    return button
end

local function makeRow(parent, title, desc, height)
    local row = Instance.new("Frame")
    row.Name = "LT_Row"
    row.BackgroundColor3 = Color3.fromRGB(24, 27, 34)
    row.BorderSizePixel = 0
    row.Size = UDim2.new(1, 0, 0, height or 54)
    row.Parent = parent
    makeCorner(row, 9)
    makeStroke(row, Color3.fromRGB(54, 61, 75))
    local titleLabel = makeText(row, title, 13, true)
    titleLabel.Position = UDim2.new(0, 12, 0, 7)
    titleLabel.Size = UDim2.new(0.58, -12, 0, 18)
    local descLabel = makeText(row, desc or "", 10, false)
    descLabel.TextColor3 = Color3.fromRGB(154, 162, 177)
    descLabel.Position = UDim2.new(0, 12, 0, 26)
    descLabel.Size = UDim2.new(0.58, -12, 0, 18)
    descLabel.TextTruncate = Enum.TextTruncate.AtEnd
    local control = Instance.new("Frame")
    control.BackgroundTransparency = 1
    control.AnchorPoint = Vector2.new(1, 0.5)
    control.Position = UDim2.new(1, -10, 0.5, 0)
    control.Size = UDim2.new(0.4, 0, 0, math.max(32, (height or 54) - 10))
    control.Parent = row
    return row, control
end

local function makeToggle(parent, getter, setter)
    local button = makeButton(parent, "", 96)
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, 0, 0.5, 0)
    local function refresh()
        local enabled = getter() == true
        button.Text = enabled and "Enabled" or "Disabled"
        button.BackgroundColor3 = enabled and Color3.fromRGB(40, 92, 143) or Color3.fromRGB(38, 43, 54)
    end
    connect(button.Activated, function()
        setter(not getter())
        refresh()
    end)
    refresh()
    return button, refresh
end

local function makeStepper(parent, getter, setter, min, max, step, formatter)
    local wrap = Instance.new("Frame")
    wrap.BackgroundTransparency = 1
    wrap.AnchorPoint = Vector2.new(1, 0.5)
    wrap.Position = UDim2.new(1, 0, 0.5, 0)
    wrap.Size = UDim2.fromOffset(138, 28)
    wrap.Parent = parent
    local minus = makeButton(wrap, "-", 30)
    minus.Position = UDim2.fromOffset(0, 0)
    local value = Instance.new("TextLabel")
    value.BackgroundColor3 = Color3.fromRGB(30, 34, 43)
    value.BorderSizePixel = 0
    value.Position = UDim2.fromOffset(34, 0)
    value.Size = UDim2.fromOffset(70, 28)
    value.TextColor3 = Color3.fromRGB(235, 239, 247)
    value.TextSize = 11
    value.Font = Enum.Font.GothamSemibold
    value.Parent = wrap
    makeCorner(value, 7)
    local plus = makeButton(wrap, "+", 30)
    plus.Position = UDim2.fromOffset(108, 0)
    local function refresh()
        local v = tonumber(getter()) or min
        value.Text = formatter and formatter(v) or tostring(v)
    end
    local function bump(delta)
        local v = tonumber(getter()) or min
        v = math.clamp(v + delta, min, max)
        v = math.floor(v / step + 0.5) * step
        setter(v)
        refresh()
    end
    connect(minus.Activated, function() bump(-step) end)
    connect(plus.Activated, function() bump(step) end)
    refresh()
    return wrap, refresh
end

local function makeCycle(parent, getter, setter, values)
    local button = makeButton(parent, "", 118)
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, 0, 0.5, 0)
    local function indexOf(value)
        for i, item in ipairs(values) do
            if item == value then
                return i
            end
        end
        return 1
    end
    local function refresh()
        button.Text = tostring(getter())
    end
    connect(button.Activated, function()
        local index = indexOf(getter()) + 1
        if index > #values then index = 1 end
        setter(values[index])
        refresh()
    end)
    refresh()
    return button, refresh
end

local function makeAssetInput(parent, initial, applyCallback, placeholder)
    local box = Instance.new("TextBox")
    box.BackgroundColor3 = Color3.fromRGB(30, 34, 43)
    box.BorderSizePixel = 0
    box.ClearTextOnFocus = false
    box.PlaceholderText = placeholder or "asset id / URL / local path"
    box.PlaceholderColor3 = Color3.fromRGB(120, 128, 145)
    box.Text = initial or ""
    box.TextColor3 = Color3.fromRGB(235, 239, 247)
    box.TextSize = 10
    box.Font = Enum.Font.Code
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.AnchorPoint = Vector2.new(1, 0.5)
    box.Position = UDim2.new(1, -54, 0.5, 0)
    box.Size = UDim2.new(1, -58, 0, 30)
    box.Parent = parent
    makeCorner(box, 7)
    makeStroke(box, Color3.fromRGB(58, 65, 80))
    local button = makeButton(parent, "Apply", 50)
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, 0, 0.5, 0)
    connect(button.Activated, function()
        applyCallback(box.Text)
    end)
    return box, button
end

local function updateCanvas()
    local scroller = runtime.refs.settingsScroller
    if not scroller or not settingsLayout then
        return
    end
    local h = settingsLayout.AbsoluteContentSize.Y + 12
    setTracked(scroller, "AutomaticCanvasSize", Enum.AutomaticSize.None)
    setTracked(scroller, "CanvasSize", UDim2.fromOffset(0, h))
end


local function openCustomization()
    local pageHost = runtime.refs.pageHost
    local settingsPage = runtime.refs.settingsPage
    local scroller = runtime.refs.settingsScroller
    if not (pageHost and settingsPage and scroller) then
        return
    end
    local pageLayout = pageHost:FindFirstChildWhichIsA("UIPageLayout")
    if pageLayout then
        pcall(function()
            pageLayout:JumpTo(settingsPage)
        end)
    else
        pcall(function()
            settingsPage.Visible = true
        end)
    end
    local function settleScroll()
        if not (runtime.alive and settingsPanel and settingsPanel.Parent == scroller) then
            return
        end
        local currentY = scroller.CanvasPosition.Y
        local targetY = settingsPanel.AbsolutePosition.Y - scroller.AbsolutePosition.Y + currentY - 8
        local maxY = math.max(0, scroller.AbsoluteCanvasSize.Y - scroller.AbsoluteWindowSize.Y)
        scroller.CanvasPosition = Vector2.new(0, math.clamp(targetY, 0, maxY))
    end
    task.defer(settleScroll)
    for _, delayTime in ipairs({ 0.18, 0.35, 0.6 }) do
        task.delay(delayTime, settleScroll)
    end
end

local function findSidebarStates()
    local main = runtime.refs.main
    if not main then
        return {}
    end
    local candidates = {}
    for _, frame in ipairs(main:GetDescendants()) do
        if frame:IsA("Frame") then
            local buttons = {}
            local layout = frame:FindFirstChildWhichIsA("UIListLayout")
            if layout then
                for _, child in ipairs(frame:GetChildren()) do
                    if child:IsA("ImageButton") then
                        buttons[#buttons + 1] = child
                    end
                end
            end
            if #buttons >= 5 and #buttons <= 7 then
                table.sort(buttons, function(a, b)
                    return a.LayoutOrder < b.LayoutOrder
                end)
                local template = buttons[#buttons]
                local parent = frame.Parent
                if template and parent and parent:IsA("Frame") then
                    local rootSize = parent.Size
                    if rootSize.X.Scale >= 0.8 and rootSize.Y.Scale >= 0.8 then
                        candidates[#candidates + 1] = {
                            frame = frame,
                            layout = layout,
                            template = template,
                            maxOrder = template.LayoutOrder,
                        }
                    end
                end
            end
        end
    end
    table.sort(candidates, function(a, b)
        return a.frame.AbsolutePosition.X < b.frame.AbsolutePosition.X
    end)
    return candidates
end

local function buildSidebarButtons()
    sidebarButtons = {}
    local states = findSidebarStates()
    for index, state in ipairs(states) do
        local frame = state.frame
        for _, child in ipairs(frame:GetChildren()) do
            if child.Name == "LT_ArceusCustomizationSidebar" then
                pcall(function() child:Destroy() end)
            end
        end
        if state.layout then
            remember(state.layout, "Padding")
            setTracked(state.layout, "Padding", UDim.new(0.045, 0))
        end
        local button = registerCustom(state.template:Clone())
        button.Name = "LT_ArceusCustomizationSidebar"
        button.LayoutOrder = state.maxOrder + 1
        button.Parent = frame
        local badge = Instance.new("TextLabel")
        badge.Name = "LT_CustomBadge"
        badge.AnchorPoint = Vector2.new(1, 1)
        badge.Position = UDim2.new(1, 1, 1, 1)
        badge.Size = UDim2.fromOffset(12, 12)
        badge.BackgroundColor3 = Color3.fromRGB(42, 132, 214)
        badge.BackgroundTransparency = 0
        badge.BorderSizePixel = 0
        badge.Text = "C"
        badge.TextColor3 = Color3.new(1, 1, 1)
        badge.TextSize = 8
        badge.Font = Enum.Font.GothamBold
        badge.ZIndex = button.ZIndex + 2
        badge.Parent = button
        makeCorner(badge, 6)
        connect(button.Activated, openCustomization)
        sidebarButtons[#sidebarButtons + 1] = button
    end
end

local function buildSettingsPanel()
    local scroller = runtime.refs.settingsScroller
    if not scroller then
        return
    end
    for _, child in ipairs(scroller:GetChildren()) do
        if child.Name == "LT_ArceusCustomization" then
            pcall(function() child:Destroy() end)
        end
    end
    settingsPanel = registerCustom(Instance.new("Frame"))
    settingsPanel.Name = "LT_ArceusCustomization"
    settingsPanel.BackgroundTransparency = 1
    settingsPanel.BorderSizePixel = 0
    settingsPanel.LayoutOrder = 4
    settingsPanel.Size = UDim2.new(0.986, 0, 0, 0)
    settingsPanel.AutomaticSize = Enum.AutomaticSize.Y
    settingsPanel.Parent = scroller

    local panelLayout = Instance.new("UIListLayout")
    panelLayout.Padding = UDim.new(0, 7)
    panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
    panelLayout.Parent = settingsPanel
    local panelPadding = Instance.new("UIPadding")
    panelPadding.PaddingLeft = UDim.new(0, 3)
    panelPadding.PaddingRight = UDim.new(0, 3)
    panelPadding.Parent = settingsPanel

    local header = Instance.new("Frame")
    header.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 58)
    header.LayoutOrder = 0
    header.Parent = settingsPanel
    makeCorner(header, 10)
    makeStroke(header, Color3.fromRGB(69, 121, 178))
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 47, 72)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 25, 32)),
    })
    grad.Rotation = 0
    grad.Parent = header
    local title = makeText(header, "Customization", 16, true)
    title.Position = UDim2.new(0, 12, 0, 8)
    title.Size = UDim2.new(1, -24, 0, 22)
    local desc = makeText(header, "Extra Arceus X controls that survive randomized instance names", 10, false)
    desc.TextColor3 = Color3.fromRGB(157, 170, 190)
    desc.Position = UDim2.new(0, 12, 0, 30)
    desc.Size = UDim2.new(1, -24, 0, 18)

    local order = 1
    local function row(titleText, descText, height)
        local r, c = makeRow(settingsPanel, titleText, descText, height)
        r.LayoutOrder = order
        order += 1
        return r, c
    end

    do
        local _, c = row("UI scale", "Resize the Arceus window without relying on its randomized names")
        makeStepper(c, function() return config.uiScale end, function(v)
            config.uiScale = v
            applyUiScale()
            saveConfig()
        end, 0.65, 1.35, 0.05, function(v) return string.format("%.2fx", v) end)
    end

    do
        local _, c = row("Window transparency", "-1 keeps the native Arceus value")
        makeStepper(c, function() return config.windowTransparency end, function(v)
            config.windowTransparency = v
            applyWindowTransparency()
            saveConfig()
        end, -0.05, 0.9, 0.05, function(v)
            if v < 0 then return "Native" end
            return string.format("%d%%", math.floor(v * 100 + 0.5))
        end)
    end

    do
        local _, c = row("Window corner radius", "Change the outer Arceus window rounding")
        makeStepper(c, function() return config.cornerRadius end, function(v)
            config.cornerRadius = v
            applyCornerRadius()
            applyBackground()
            saveConfig()
        end, -2, 30, 2, function(v)
            if v < 0 then return "Native" end
            return tostring(math.floor(v + 0.5)) .. "px"
        end)
    end

    do
        local _, c = row("Floating icon", "Show or hide the Arceus floating launcher")
        makeToggle(c, function() return config.iconVisible end, function(v)
            config.iconVisible = v
            applyIconVisible()
            saveConfig()
        end)
    end

    do
        local _, c = row("Floating icon size", "Scale the launcher while keeping its current behavior")
        makeStepper(c, function() return config.iconSize end, function(v)
            config.iconSize = v
            applyIconSize()
            saveConfig()
        end, 0.5, 2.5, 0.1, function(v) return string.format("%.1fx", v) end)
    end

    do
        local _, c = row("Floating icon shape", "Cycle between native, rounded, square and circle")
        makeCycle(c, function() return config.iconShape end, function(v)
            config.iconShape = v
            applyIconShape()
            saveConfig()
        end, { "Default", "Rounded", "Square", "Circle" })
    end

    do
        local _, c = row("RGB icon outline", "Animated outline around the Arceus floating icon")
        makeToggle(c, function() return config.rgbIcon end, function(v)
            config.rgbIcon = v
            applyRgbState()
            saveConfig()
        end)
    end

    do
        local _, c = row("RGB speed", "Adjust icon outline hue cycle speed")
        makeStepper(c, function() return config.rgbSpeed end, function(v)
            config.rgbSpeed = v
            saveConfig()
        end, 0.05, 1.5, 0.05, function(v) return string.format("%.2f", v) end)
    end

    do
        local _, c = row("Save icon position", "Restore the floating icon to its last position")
        makeToggle(c, function() return config.saveIconPosition end, function(v)
            config.saveIconPosition = v
            if v then
                saveIconPosition()
            else
                config.iconPosition = nil
                saveConfig()
            end
        end)
    end

    do
        local _, c = row("Custom floating icon", "Blank + Apply restores the native icon", 62)
        makeAssetInput(c, config.customIconSource, function(value)
            config.customIconSource = normalizeAssetSource(value)
            local ok = applyCustomIcon()
            saveConfig()
            notify("Arceus Customization", ok and "Floating icon updated." or "Could not load that icon asset.")
        end, "asset id / URL / local file")
    end

    do
        local _, c = row("Background image", "Blank + Apply disables the custom background", 62)
        makeAssetInput(c, config.backgroundSource, function(value)
            config.backgroundSource = normalizeAssetSource(value)
            local ok = applyBackground()
            saveConfig()
            notify("Arceus Customization", ok and "Background updated." or "Could not load that background asset.")
        end, "asset id / URL / local file")
    end

    do
        local _, c = row("Background transparency", "Control the custom background image opacity")
        makeStepper(c, function() return config.backgroundTransparency end, function(v)
            config.backgroundTransparency = v
            if backgroundImage then
                backgroundImage.ImageTransparency = math.clamp(v, 0, 0.95)
            end
            saveConfig()
        end, 0, 0.9, 0.05, function(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end)
    end

    do
        local _, c = row("Unload customization", "Restore every Arceus property changed by this module")
        local button = makeButton(c, "Unload", 118)
        button.AnchorPoint = Vector2.new(1, 0.5)
        button.Position = UDim2.new(1, 0, 0.5, 0)
        button.BackgroundColor3 = Color3.fromRGB(117, 43, 49)
        connect(button.Activated, function()
            task.defer(runtime.stop)
        end)
    end

    settingsLayout = scroller:FindFirstChildWhichIsA("UIListLayout")
    if settingsLayout then
        connect(settingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            task.defer(updateCanvas)
        end)
    end
    task.defer(updateCanvas)
end

local function bindDynamicBehavior()
    local main = runtime.refs.main
    local icon = runtime.refs.icon
    if main then
        connect(main.AncestryChanged, function(_, parent)
            if runtime.alive and parent == nil then
                task.delay(0.35, function()
                    if runtime.alive then
                        runtime.refresh()
                    end
                end)
            end
        end)
    end
    if icon then
        local saveStamp = 0
        connect(icon:GetPropertyChangedSignal("Position"), function()
            if config.saveIconPosition ~= true then
                return
            end
            saveStamp += 1
            local stamp = saveStamp
            task.delay(0.2, function()
                if runtime.alive and stamp == saveStamp then
                    saveIconPosition()
                end
            end)
        end)
    end
end

local function locate()
    local gui = findArceusGui()
    if not gui then
        return false, "Arceus ScreenGui not found"
    end
    local main = findMainFrame(gui)
    if not main then
        return false, "Arceus main frame not found"
    end
    local pageHost = findPageHost(main)
    if not pageHost then
        return false, "Arceus page host not found"
    end
    local settingsPage = findSettingsPage(pageHost)
    if not settingsPage then
        return false, "Arceus settings page not found"
    end
    local settingsScroller = findSettingsScroller(settingsPage)
    if not settingsScroller then
        return false, "Arceus settings scroller not found"
    end
    local icon = findFloatingIcon(gui)
    local iconImage = findIconImage(icon)
    runtime.refs.gui = gui
    runtime.refs.main = main
    runtime.refs.pageHost = pageHost
    runtime.refs.settingsPage = settingsPage
    runtime.refs.settingsScroller = settingsScroller
    runtime.refs.icon = icon
    runtime.refs.iconImage = iconImage
    runtime.refs.mainCorner = main:FindFirstChildWhichIsA("UICorner")
    runtime.refs.iconCorner = icon and icon:FindFirstChildWhichIsA("UICorner") or nil
    return true
end

local function captureBases()
    local main = runtime.refs.main
    local icon = runtime.refs.icon
    local mainCorner = runtime.refs.mainCorner
    local iconCorner = runtime.refs.iconCorner
    local iconImage = runtime.refs.iconImage
    if main then
        remember(main, "BackgroundTransparency")
    end
    if mainCorner then
        mainCornerBase = mainCorner.CornerRadius
        remember(mainCorner, "CornerRadius")
        if tonumber(config.cornerRadius) == -1 then
            config.cornerRadius = -1
        end
    end
    if icon then
        remember(icon, "Visible")
        remember(icon, "Position")
    end
    if iconCorner then
        iconCornerBase = iconCorner.CornerRadius
        remember(iconCorner, "CornerRadius")
    end
    if iconImage then
        iconImageBase = iconImage.Image
        remember(iconImage, "Image")
        remember(iconImage, "ImageColor3")
    end
    local scroller = runtime.refs.settingsScroller
    if scroller then
        remember(scroller, "CanvasSize")
        remember(scroller, "AutomaticCanvasSize")
    end
end

local function restore()
    for i = #runtime.custom, 1, -1 do
        local object = runtime.custom[i]
        if object then
            pcall(function()
                object:Destroy()
            end)
        end
        runtime.custom[i] = nil
    end
    for object, properties in pairs(runtime.originals) do
        if object then
            for property, wrapped in pairs(properties) do
                pcall(function()
                    object[property] = wrapped.value
                end)
            end
        end
    end
end

runtime.stop = function()
    if not runtime.alive then
        return
    end
    runtime.alive = false
    clearConnections()
    restore()
    if __acm_env.__ArceusCustomizationRuntime == runtime then
        __acm_env.__ArceusCustomizationRuntime = nil
    end
    if __acm_env.ArceusCustomization and __acm_env.ArceusCustomization.runtime == runtime then
        __acm_env.ArceusCustomization = nil
    end
    notify("Arceus Customization", "Customization unloaded and native properties restored.")
end

runtime.refresh = function()
    if not runtime.alive then
        return false
    end
    clearConnections()
    restore()
    runtime.originals = setmetatable({}, { __mode = "k" })
    runtime.custom = {}
    runtime.refs = {}
    iconStroke = nil
    backgroundImage = nil
    settingsPanel = nil
    settingsLayout = nil
    sidebarButtons = {}
    mainScale = nil
    mainCornerBase = nil
    iconScale = nil
    iconCornerBase = nil
    iconImageBase = nil
    local ok, reason = locate()
    if not ok then
        return false, reason
    end
    captureBases()
    buildSettingsPanel()
    buildSidebarButtons()
    bindDynamicBehavior()
    applyAll()
    return true
end

local ok, reason = locate()
if not ok then
    runtime.alive = false
    __acm_env.__ArceusCustomizationRuntime = nil
    notify("Arceus Customization", reason)
    return
end

captureBases()
buildSettingsPanel()
buildSidebarButtons()
bindDynamicBehavior()
applyAll()

if RunService then
    connect(RunService.Heartbeat, function()
        if not runtime.alive or config.rgbIcon ~= true then
            return
        end
        local stroke = ensureIconStroke()
        if not stroke or not stroke.Parent then
            return
        end
        local speed = math.clamp(tonumber(config.rgbSpeed) or 0.2, 0.05, 1.5)
        stroke.Color = Color3.fromHSV((os.clock() * speed) % 1, 0.82, 1)
    end)
end

connect(runtime.refs.gui.AncestryChanged, function(_, parent)
    if runtime.alive and parent == nil then
        task.delay(0.5, function()
            if not runtime.alive then
                return
            end
            for _ = 1, 20 do
                local refreshed = runtime.refresh()
                if refreshed then
                    return
                end
                task.wait(0.5)
            end
        end)
    end
end)

__acm_env.ArceusCustomization = {
    runtime = runtime,
    settings = config,
    unload = runtime.stop,
    refresh = runtime.refresh,
    save = saveConfig,
}

notify("Arceus Customization", "Loaded. Use the C-badged sidebar button to open customization.")
return __acm_env.ArceusCustomization
