local env = _G

if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then
        env = result
    end
end

if env.FNP_AutoPlayer and type(env.FNP_AutoPlayer.Destroy) == "function" then
    pcall(env.FNP_AutoPlayer.Destroy)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function showFatalCompatibility(title, message)
    warn("[FNP Autoplayer] " .. title .. ": " .. message)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "FNP Autoplayer",
            Text = title,
            Duration = 10
        })
    end)
    pcall(function()
        local parent = PlayerGui
        if type(gethui) == "function" then
            local ok, result = pcall(gethui)
            if ok and typeof(result) == "Instance" then
                parent = result
            end
        else
            local ok = pcall(function()
                parent = CoreGui
            end)
            if not ok then
                parent = PlayerGui
            end
        end
        local old = parent:FindFirstChild("FNP_Autoplayer_Compatibility")
        if old then
            old:Destroy()
        end
        local gui = Instance.new("ScreenGui")
        gui.Name = "FNP_Autoplayer_Compatibility"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = parent

        local frame = Instance.new("Frame")
        frame.Name = "Panel"
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.fromScale(0.5, 0.5)
        frame.Size = UDim2.fromOffset(470, 230)
        frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.Draggable = true
        frame.Parent = gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = frame

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(65, 65, 72)
        stroke.Thickness = 1
        stroke.Parent = frame

        local heading = Instance.new("TextLabel")
        heading.BackgroundTransparency = 1
        heading.Position = UDim2.fromOffset(18, 14)
        heading.Size = UDim2.new(1, -56, 0, 28)
        heading.Font = Enum.Font.GothamBold
        heading.Text = title
        heading.TextColor3 = Color3.fromRGB(245, 245, 248)
        heading.TextSize = 18
        heading.TextXAlignment = Enum.TextXAlignment.Left
        heading.Parent = frame

        local close = Instance.new("TextButton")
        close.BackgroundTransparency = 1
        close.Position = UDim2.new(1, -42, 0, 10)
        close.Size = UDim2.fromOffset(32, 32)
        close.Font = Enum.Font.GothamBold
        close.Text = "×"
        close.TextColor3 = Color3.fromRGB(190, 190, 198)
        close.TextSize = 22
        close.Parent = frame
        close.MouseButton1Click:Connect(function()
            gui:Destroy()
        end)

        local body = Instance.new("TextLabel")
        body.BackgroundTransparency = 1
        body.Position = UDim2.fromOffset(18, 52)
        body.Size = UDim2.new(1, -36, 1, -70)
        body.Font = Enum.Font.Gotham
        body.Text = message
        body.TextColor3 = Color3.fromRGB(205, 205, 212)
        body.TextSize = 14
        body.TextWrapped = true
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.Parent = frame
    end)
end

local function removeCompatibilityPanels()
    local parents = {PlayerGui}
    pcall(function()
        parents[#parents + 1] = CoreGui
    end)
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and typeof(result) == "Instance" then
            parents[#parents + 1] = result
        end
    end
    for _, parent in parents do
        if typeof(parent) == "Instance" then
            local old = parent:FindFirstChild("FNP_Autoplayer_Compatibility")
            if old then
                old:Destroy()
            end
        end
    end
end

removeCompatibilityPanels()

local requireCandidates = {}
local requireSeen = {}

local function addRequireCandidate(name, value)
    if type(value) == "function" and not requireSeen[value] then
        requireSeen[value] = true
        requireCandidates[#requireCandidates + 1] = {Name = name, Function = value}
    end
end

addRequireCandidate("require", require)

if type(getrenv) == "function" then
    local ok, result = pcall(getrenv)
    if ok and type(result) == "table" then
        addRequireCandidate("getrenv().require", rawget(result, "require"))
    end
end

if type(getfenv) == "function" then
    local ok, result = pcall(getfenv, 0)
    if ok and type(result) == "table" then
        addRequireCandidate("getfenv(0).require", rawget(result, "require"))
    end
end

local function safeRequireModule(module)
    local failures = {}
    for _, candidate in requireCandidates do
        local ok, result = pcall(candidate.Function, module)
        if ok and result ~= nil then
            return result, candidate.Name
        end
        failures[#failures + 1] = candidate.Name .. ": " .. tostring(result)
    end
    if #failures == 0 then
        failures[1] = "No callable require implementation was exposed"
    end
    return nil, table.concat(failures, " | ")
end

local closureCandidates = {}
local closureSeen = {}

local function addClosureCandidate(name, value)
    if type(value) == "function" and not closureSeen[value] then
        closureSeen[value] = true
        closureCandidates[#closureCandidates + 1] = {Name = name, Function = value}
    end
end

addClosureCandidate("getscriptclosure", getscriptclosure)
addClosureCandidate("getscriptfunction", getscriptfunction)

local function attemptModuleClosure(module)
    local failures = {}
    for _, candidate in closureCandidates do
        local okGet, closure = pcall(candidate.Function, module)
        if okGet and type(closure) == "function" then
            local okCall, result = pcall(closure)
            if okCall and result ~= nil then
                return result, candidate.Name .. " returned an isolated value"
            end
            failures[#failures + 1] = candidate.Name .. " execute: " .. tostring(result)
        else
            failures[#failures + 1] = candidate.Name .. " acquire: " .. tostring(closure)
        end
    end
    if #failures == 0 then
        failures[1] = "No script-closure loader was exposed"
    end
    return nil, table.concat(failures, " | ")
end

local Modules = ReplicatedStorage:FindFirstChild("Modules") or ReplicatedStorage:WaitForChild("Modules", 15)

if not Modules then
    showFatalCompatibility(
        "Unsupported game state",
        "ReplicatedStorage.Modules was not found after 15 seconds. Join an active FNP server and execute the script after the game finishes loading."
    )
    return
end

local requiredModuleNames = {"Note", "Conductor", "GameSettings", "UserInputBindables"}
local loadedModules = {}
local requireFailures = {}
local requireProviders = {}
local closureAttempts = {}

for _, moduleName in requiredModuleNames do
    local module = Modules:FindFirstChild(moduleName) or Modules:WaitForChild(moduleName, 10)
    if not module or not module:IsA("ModuleScript") then
        requireFailures[#requireFailures + 1] = moduleName .. ": ModuleScript not found"
        closureAttempts[moduleName] = "ModuleScript not found"
    else
        local result, providerOrError = safeRequireModule(module)
        if result ~= nil then
            loadedModules[moduleName] = result
            requireProviders[moduleName] = providerOrError
        else
            local isolated, closureStatus = attemptModuleClosure(module)
            closureAttempts[moduleName] = closureStatus
            if isolated ~= nil then
                requireFailures[#requireFailures + 1] = moduleName .. ": live require failed; " .. closureStatus
            else
                requireFailures[#requireFailures + 1] = moduleName .. ": " .. providerOrError .. " | closure attempts: " .. closureStatus
            end
        end
    end
end

local moduleShapeFailures = {}

if loadedModules.Note ~= nil and (type(loadedModules.Note) ~= "table" or type(loadedModules.Note.SpawnNote) ~= "function") then
    moduleShapeFailures[#moduleShapeFailures + 1] = "Note.SpawnNote is unavailable"
end
if loadedModules.Conductor ~= nil and type(loadedModules.Conductor) ~= "table" then
    moduleShapeFailures[#moduleShapeFailures + 1] = "Conductor did not return a table"
end
if loadedModules.GameSettings ~= nil and (type(loadedModules.GameSettings) ~= "table" or type(loadedModules.GameSettings.settings) ~= "table") then
    moduleShapeFailures[#moduleShapeFailures + 1] = "GameSettings.settings is unavailable"
end
if loadedModules.UserInputBindables ~= nil and type(loadedModules.UserInputBindables) ~= "table" then
    moduleShapeFailures[#moduleShapeFailures + 1] = "UserInputBindables did not return a table"
end

local ModuleAccessMode = #requireFailures == 0 and #moduleShapeFailures == 0 and "live" or "visual"
local ReconstructedGameSettings
local ReconstructedGameSettingsStatus = "Not needed"

if ModuleAccessMode == "visual" and type(decompile) == "function" and type(loadstring) == "function" and type(setfenv) == "function" then
    local cache = {}
    local loading = {}
    local baseEnvironment = _G

    if type(getrenv) == "function" then
        local ok, result = pcall(getrenv)
        if ok and type(result) == "table" then
            baseEnvironment = result
        end
    end

    local loadDecompiledModule
    loadDecompiledModule = function(module)
        if cache[module] ~= nil then
            return cache[module]
        end
        if loading[module] then
            error("Circular reconstructed require: " .. module:GetFullName())
        end

        loading[module] = true
        local source = decompile(module)
        local compileOk, chunk, compileError = pcall(loadstring, source, "=" .. module:GetFullName())
        if not compileOk or type(chunk) ~= "function" then
            compileOk, chunk, compileError = pcall(loadstring, source)
        end
        if not compileOk or type(chunk) ~= "function" then
            loading[module] = nil
            error(compileError or chunk)
        end

        local moduleEnvironment = setmetatable({
            script = module
        }, {
            __index = baseEnvironment
        })

        moduleEnvironment.require = function(target)
            if typeof(target) == "Instance" and target:IsA("ModuleScript") then
                return loadDecompiledModule(target)
            end
            return require(target)
        end

        setfenv(chunk, moduleEnvironment)
        local ok, result = pcall(chunk)
        loading[module] = nil

        if not ok then
            error(result)
        end

        cache[module] = result
        return result
    end

    local gameSettingsModule = Modules:FindFirstChild("GameSettings")
    if gameSettingsModule and gameSettingsModule:IsA("ModuleScript") then
        local ok, result = pcall(loadDecompiledModule, gameSettingsModule)
        if ok and type(result) == "table" and type(result.settings) == "table" then
            ReconstructedGameSettings = result
            ReconstructedGameSettingsStatus = "Reconstructed from decompiled module"
        else
            ReconstructedGameSettingsStatus = "Reconstruction failed: " .. tostring(result)
        end
    else
        ReconstructedGameSettingsStatus = "GameSettings ModuleScript not found"
    end
elseif ModuleAccessMode == "visual" then
    ReconstructedGameSettingsStatus = "decompile/loadstring/setfenv unavailable"
end

local NoteModule = type(loadedModules.Note) == "table" and loadedModules.Note or {}
local Conductor = type(loadedModules.Conductor) == "table" and loadedModules.Conductor or {}
local GameSettings = type(loadedModules.GameSettings) == "table"
    and loadedModules.GameSettings
    or ReconstructedGameSettings
    or {settings = {Keybinds = {}}}
local UserInputBindables = type(loadedModules.UserInputBindables) == "table" and loadedModules.UserInputBindables or {}

if type(GameSettings.settings) ~= "table" then
    GameSettings.settings = {Keybinds = {}}
end
if type(GameSettings.settings.Keybinds) ~= "table" then
    GameSettings.settings.Keybinds = {}
end

local moduleDiagnostics = {}
for _, failure in requireFailures do
    moduleDiagnostics[#moduleDiagnostics + 1] = failure
end
for _, failure in moduleShapeFailures do
    moduleDiagnostics[#moduleDiagnostics + 1] = failure
end

if ModuleAccessMode == "visual" then
    warn("[FNP Autoplayer] Live ModuleScript access is blocked. Visual note tracking fallback enabled.")
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "FNP Autoplayer",
            Text = "Live modules blocked; visual fallback enabled.",
            Duration = 7
        })
    end)
end

local FOLDER = "FNP_Autoplayer"
local SETTINGS_PATH = FOLDER .. "/settings.json"
local WINDUI_URL = "https://github.com/Footagesus/WindUI/releases/download/1.6.65/main.lua"

local Layouts = {
    {Name = "4K", Keys = {Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.J, Enum.KeyCode.K}},
    {Name = "6K", Keys = {Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.J, Enum.KeyCode.K, Enum.KeyCode.L}},
    {Name = "9K", Keys = {Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.Space, Enum.KeyCode.H, Enum.KeyCode.J, Enum.KeyCode.K, Enum.KeyCode.L}},
    {Name = "5K", Keys = {Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.Space, Enum.KeyCode.J, Enum.KeyCode.K}},
    {Name = "7K", Keys = {Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.Space, Enum.KeyCode.J, Enum.KeyCode.K, Enum.KeyCode.L}},
    {Name = "8K", Keys = {Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.J, Enum.KeyCode.K, Enum.KeyCode.L, Enum.KeyCode.Semicolon}},
    {Name = "12K", Keys = {Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.C, Enum.KeyCode.V, Enum.KeyCode.N, Enum.KeyCode.M, Enum.KeyCode.J, Enum.KeyCode.K, Enum.KeyCode.L, Enum.KeyCode.Semicolon}}
}

local Defaults = {
    Enabled = true,
    InputMode = "Virtual Input",
    TimingOffset = 0,
    TapDuration = 24,
    SustainBuffer = 80,
    AutoFillBinds = true,
    SkipHarmful = true,
    AutoplayerToggleKey = "RightShift",
    WindowKey = "Insert",
    Theme = "Dark",
    UIScale = 1,
    WindowWidth = 640,
    WindowHeight = 500,
    BackgroundTransparency = 0.15,
    BackgroundImageTransparency = 0,
    SelectedMode = "4K",
    VisualSide = "Auto",
    Keybinds = {}
}

local function safeCall(callback, ...)
    local ok, result = pcall(callback, ...)
    return ok, result
end

local function normalizeKey(value)
    if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
        return value
    end
    if type(value) == "string" then
        return Enum.KeyCode[value:gsub("Enum.KeyCode%.", "")]
    end
end

local function keyName(value)
    return tostring(value or ""):gsub("Enum.KeyCode%.", "")
end

local function isKeyboardKey(value)
    if typeof(value) ~= "EnumItem" or value.EnumType ~= Enum.KeyCode then
        return false
    end
    local name = value.Name
    if name == "Unknown" or name:match("^Button") or name:match("^DPad") then
        return false
    end
    return true
end

local function countTable(value)
    local count = 0
    if type(value) == "table" then
        for _ in value do
            count += 1
        end
    end
    return count
end

local function cloneTable(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local copy = {}
    seen[value] = copy
    for key, item in value do
        copy[cloneTable(key, seen)] = cloneTable(item, seen)
    end
    return copy
end

local function loadSettings()
    local settings = cloneTable(Defaults)
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return settings
    end
    local existsOk, exists = pcall(isfile, SETTINGS_PATH)
    if not existsOk or not exists then
        return settings
    end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile(SETTINGS_PATH))
    end)
    if ok and type(decoded) == "table" then
        for key, value in decoded do
            settings[key] = value
        end
    end
    return settings
end

if type(isfolder) == "function" and type(makefolder) == "function" then
    local ok, exists = pcall(isfolder, FOLDER)
    if ok and not exists then
        pcall(makefolder, FOLDER)
    end
end

local DebugLibrary = type(debug) == "table" and debug or {}
local DebugInfoFunction

if type(DebugLibrary.info) == "function" then
    DebugInfoFunction = function(object)
        return DebugLibrary.info(object, "n")
    end
elseif type(DebugLibrary.getinfo) == "function" then
    DebugInfoFunction = function(object)
        local info = DebugLibrary.getinfo(object)
        return type(info) == "table" and info.name or nil
    end
end

local FiresignalFunction = type(firesignal) == "function" and firesignal or nil
local GetGCFunction = type(getgc) == "function" and getgc or nil
local HookFunction = type(hookfunction) == "function" and hookfunction or nil
local GetConnectionsFunction = type(getconnections) == "function" and getconnections or nil
local GetThreadIdentityFunction = type(getthreadidentity) == "function" and getthreadidentity or nil
local SetThreadIdentityFunction = type(setthreadidentity) == "function" and setthreadidentity or nil
local LoadstringFunction = type(loadstring) == "function" and loadstring or nil
local RequestFunction = type(request) == "function" and request or nil

if not RequestFunction and type(http_request) == "function" then
    RequestFunction = http_request
end
if not RequestFunction and type(syn) == "table" and type(syn.request) == "function" then
    RequestFunction = syn.request
end

local function resolveVirtualInputManager()
    local ok, service = pcall(game.GetService, game, "VirtualInputManager")
    if ok and typeof(service) == "Instance" and type(service.SendKeyEvent) == "function" then
        return service, false, "game:GetService"
    end
    local createdOk, created = pcall(Instance.new, "VirtualInputManager")
    if createdOk and typeof(created) == "Instance" and type(created.SendKeyEvent) == "function" then
        return created, true, "Instance.new"
    end
    return nil, false, tostring(service or created)
end

local VirtualInputManager, VirtualInputOwned, VirtualInputProvider = resolveVirtualInputManager()
local BackendAvailability = {
    ["Virtual Input"] = VirtualInputManager ~= nil,
    firesignal = ModuleAccessMode == "live"
        and FiresignalFunction ~= nil
        and type(UserInputBindables.InputEvents) == "table"
        and UserInputBindables.InputEvents.Began ~= nil
        and UserInputBindables.InputEvents.Ended ~= nil,
    getgc = ModuleAccessMode == "live" and GetGCFunction ~= nil and DebugInfoFunction ~= nil
}
local AvailableInputModes = {}

for _, mode in {"Virtual Input", "firesignal", "getgc"} do
    if BackendAvailability[mode] then
        AvailableInputModes[#AvailableInputModes + 1] = mode
    end
end

local function chooseInputMode(requested)
    if BackendAvailability[requested] then
        return requested
    end
    return AvailableInputModes[1] or "Unavailable"
end

local Config = loadSettings()

local state = {
    Version = 15,
    Enabled = Config.Enabled ~= false and #AvailableInputModes > 0,
    InputMode = chooseInputMode(Config.InputMode),
    BackendAvailability = BackendAvailability,
    AvailableInputModes = AvailableInputModes,
    RequireProviders = requireProviders,
    ClosureAttempts = closureAttempts,
    ModuleDiagnostics = moduleDiagnostics,
    ModuleAccessMode = ModuleAccessMode,
    VisualMode = ModuleAccessMode == "visual",
    VirtualInputProvider = VirtualInputProvider,
    VirtualInputOwned = VirtualInputOwned,
    TimingOffset = tonumber(Config.TimingOffset) or 0,
    TapDuration = tonumber(Config.TapDuration) or 24,
    SustainBuffer = tonumber(Config.SustainBuffer) or 80,
    AutoFillBinds = Config.AutoFillBinds ~= false,
    SkipHarmful = Config.SkipHarmful ~= false,
    AutoplayerToggleKey = normalizeKey(Config.AutoplayerToggleKey) or Enum.KeyCode.RightShift,
    WindowKey = normalizeKey(Config.WindowKey) or Enum.KeyCode.Insert,
    Theme = type(Config.Theme) == "string" and Config.Theme or "Dark",
    UIScale = tonumber(Config.UIScale) or 1,
    WindowWidth = tonumber(Config.WindowWidth) or 640,
    WindowHeight = tonumber(Config.WindowHeight) or 500,
    BackgroundTransparency = tonumber(Config.BackgroundTransparency) or 0.15,
    BackgroundImageTransparency = tonumber(Config.BackgroundImageTransparency) or 0,
    SelectedMode = type(Config.SelectedMode) == "string" and Config.SelectedMode or "4K",
    VisualSide = table.find({"Auto", "BF", "Dad"}, Config.VisualSide) and Config.VisualSide or "Auto",
    DetectedSide = "Unknown",
    DetectedSideMethod = "Waiting for gameplay",
    ConfigKeybinds = type(Config.Keybinds) == "table" and Config.Keybinds or {},
    Layouts = Layouts,
    Connections = {},
    ContainerConnections = {},
    ConnectedContainers = {},
    Active = {},
    GuiToNote = {},
    PendingGui = {},
    Triggered = {},
    Counted = {},
    Pressed = {},
    HoldUntil = {},
    TapReleaseAt = {},
    VisualHoldUntil = {},
    VisualNotes = {},
    VisualReceptors = {},
    VisualCandidateFirstSeen = {},
    VisualContainers = {},
    VisualContainer = nil,
    VisualSideVote = nil,
    VisualSideVoteCount = 0,
    LastVisualSideCheck = 0,
    LastVisualSideSwitch = 0,
    LastVisualReceptorScan = 0,
    CurrentLaneCount = nil,
    DetectedMode = "Idle",
    FireHeld = {},
    Hits = 0,
    Misses = 0,
    LastSongPos = 0,
    CurrentMania = nil,
    RuntimeBindsAdded = 0,
    SettingsFilled = 0,
    LastGCResolve = 0,
    Destroyed = false,
    SaveQueued = false
}

env.FNP_AutoPlayer = state

local function queueSave()
    if state.SaveQueued or state.Destroyed then
        return
    end
    state.SaveQueued = true
    task.delay(0.3, function()
        state.SaveQueued = false
        if state.Destroyed then
            return
        end
        local keybinds = {}
        for index, layout in Layouts do
            local mode = {}
            for lane = 1, #layout.Keys do
                local value = state.GetLaneKey and state.GetLaneKey(index, lane) or layout.Keys[lane]
                mode[tostring(lane)] = keyName(value)
            end
            keybinds[layout.Name] = mode
        end
        local payload = {
            Enabled = state.Enabled,
            InputMode = state.InputMode,
            TimingOffset = state.TimingOffset,
            TapDuration = state.TapDuration,
            SustainBuffer = state.SustainBuffer,
            AutoFillBinds = state.AutoFillBinds,
            SkipHarmful = state.SkipHarmful,
            AutoplayerToggleKey = keyName(state.AutoplayerToggleKey),
            WindowKey = keyName(state.WindowKey),
            Theme = state.Theme,
            UIScale = state.UIScale,
            WindowWidth = state.WindowWidth,
            WindowHeight = state.WindowHeight,
            BackgroundTransparency = state.BackgroundTransparency,
            BackgroundImageTransparency = state.BackgroundImageTransparency,
            SelectedMode = state.SelectedMode,
            VisualSide = state.VisualSide,
            Keybinds = keybinds
        }
        if type(writefile) == "function" then
            pcall(function()
                writefile(SETTINGS_PATH, HttpService:JSONEncode(payload))
            end)
        end
    end)
end

state.SaveConfig = queueSave

local function getModeIndex(name)
    for index, layout in Layouts do
        if layout.Name == name then
            return index
        end
    end
    return 1
end

local function getLaneTable(index, lane)
    local settings = GameSettings.settings
    if type(settings) ~= "table" then
        return nil
    end
    settings.Keybinds = type(settings.Keybinds) == "table" and settings.Keybinds or {}
    settings.Keybinds[index] = type(settings.Keybinds[index]) == "table" and settings.Keybinds[index] or {}
    settings.Keybinds[index][lane] = type(settings.Keybinds[index][lane]) == "table" and settings.Keybinds[index][lane] or {}
    return settings.Keybinds[index][lane]
end

local function getLaneKey(index, lane)
    local layout = Layouts[index]
    if not layout then
        return nil
    end
    local configured = state.ConfigKeybinds[layout.Name]
    local configuredName = configured and (configured[tostring(lane)] or configured[lane])
    local configuredKey = normalizeKey(configuredName)
    if configuredKey then
        return configuredKey
    end
    local laneTable = getLaneTable(index, lane)
    if laneTable then
        for _, value in laneTable do
            local key = typeof(value) == "Instance" and value.Value or value
            if isKeyboardKey(key) then
                return key
            end
        end
    end
    return layout.Keys[lane]
end

state.GetLaneKey = getLaneKey

local function setLaneKey(index, lane, key, saveNow)
    key = normalizeKey(key)
    local layout = Layouts[index]
    if not layout or not layout.Keys[lane] or not key then
        return false
    end
    local settings = GameSettings.settings
    if type(settings) ~= "table" then
        return false
    end
    settings.Keybinds = type(settings.Keybinds) == "table" and settings.Keybinds or {}
    settings.Keybinds[index] = type(settings.Keybinds[index]) == "table" and settings.Keybinds[index] or {}
    for otherLane = 1, #layout.Keys do
        local laneTable = getLaneTable(index, otherLane)
        if otherLane ~= lane then
            for itemIndex = #laneTable, 1, -1 do
                local value = laneTable[itemIndex]
                local existing = typeof(value) == "Instance" and value.Value or value
                if existing == key then
                    table.remove(laneTable, itemIndex)
                end
            end
        end
    end
    local laneTable = getLaneTable(index, lane)
    local preserved = {}
    for _, value in laneTable do
        local existing = typeof(value) == "Instance" and value.Value or value
        if not isKeyboardKey(existing) then
            preserved[#preserved + 1] = value
        end
    end
    table.clear(laneTable)
    laneTable[1] = key
    for _, value in preserved do
        laneTable[#laneTable + 1] = value
    end
    state.ConfigKeybinds[layout.Name] = state.ConfigKeybinds[layout.Name] or {}
    state.ConfigKeybinds[layout.Name][tostring(lane)] = key.Name
    if state.CurrentMania == index - 1 then
        task.defer(function()
            if state.ApplyRuntimeBinds then
                state.ApplyRuntimeBinds(state.CurrentMania)
            end
        end)
    end
    if saveNow then
        queueSave()
    end
    return true
end

state.SetLaneKey = setLaneKey

local function fillMissingBinds()
    local filled = 0
    for index, layout in Layouts do
        for lane = 1, #layout.Keys do
            local laneTable = getLaneTable(index, lane)
            local hasKeyboard = false
            for _, value in laneTable do
                local key = typeof(value) == "Instance" and value.Value or value
                if isKeyboardKey(key) then
                    hasKeyboard = true
                    break
                end
            end
            if not hasKeyboard then
                local configured = state.ConfigKeybinds[layout.Name]
                local key = normalizeKey(configured and (configured[tostring(lane)] or configured[lane])) or layout.Keys[lane]
                laneTable[#laneTable + 1] = key
                filled += 1
            end
        end
    end
    state.SettingsFilled += filled
    return filled
end

state.FillMissingBinds = fillMissingBinds

local function resetModeBinds(index)
    local layout = Layouts[index]
    if not layout then
        return false
    end
    for lane, key in layout.Keys do
        setLaneKey(index, lane, key, false)
    end
    queueSave()
    return true
end

state.ResetModeBinds = resetModeBinds

local function saveGameBinds()
    if state.VisualMode then
        return false
    end
    local settings = cloneTable(GameSettings.settings)
    if type(settings) ~= "table" or type(settings.Keybinds) ~= "table" then
        return false
    end
    for index, mode in settings.Keybinds do
        if type(mode) == "table" then
            for lane, values in mode do
                if type(values) == "table" then
                    for itemIndex = 1, 12 do
                        if values[itemIndex] ~= nil then
                            values[tostring(itemIndex)] = values[itemIndex]
                            values[itemIndex] = nil
                        end
                    end
                end
            end
        end
    end
    local remote = ReplicatedStorage:FindFirstChild("InfoRetriever") or RunService:FindFirstChild("InfoRetriever")
    if not remote then
        return false
    end
    return pcall(function()
        remote:InvokeServer(2, settings)
    end)
end

state.SaveGameBinds = saveGameBinds

if state.AutoFillBinds then
    fillMissingBinds()
end

local function applyRuntimeBinds(mania)
    if state.VisualMode or type(UserInputBindables.AddBind) ~= "function" then
        return
    end
    local index = mania + 1
    local layout = Layouts[index]
    if not layout then
        return
    end
    for lane = 1, #layout.Keys do
        local bindName = "Direction" .. lane
        local laneTable = getLaneTable(index, lane)
        local added = false
        for _, value in laneTable do
            local key = typeof(value) == "Instance" and value.Value or value
            if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
                pcall(UserInputBindables.AddBind, bindName, key)
                added = true
            end
        end
        if not added then
            local key = getLaneKey(index, lane)
            if key then
                pcall(UserInputBindables.AddBind, bindName, key)
                state.RuntimeBindsAdded += 1
            end
        end
    end
end

state.ApplyRuntimeBinds = applyRuntimeBinds
state.VirtualInput = VirtualInputManager

local originalIsBindPressed
if BackendAvailability.firesignal and HookFunction and type(UserInputBindables.IsBindPressed) == "function" then
    local wrapper
    wrapper = function(name)
        if state and not state.Destroyed and state.InputMode == "firesignal" and state.FireHeld[name] then
            return true
        end
        if type(originalIsBindPressed) == "function" then
            return originalIsBindPressed(name)
        end
        return false
    end
    local ok, original = pcall(HookFunction, UserInputBindables.IsBindPressed, wrapper)
    if ok and type(original) == "function" then
        originalIsBindPressed = original
        state.OriginalIsBindPressed = original
    end
end

local function withIdentity8(callback)
    local oldIdentity
    if GetThreadIdentityFunction and SetThreadIdentityFunction then
        local ok, result = pcall(GetThreadIdentityFunction)
        if ok then
            oldIdentity = result
            pcall(SetThreadIdentityFunction, 8)
        end
    end
    local ok, result = pcall(callback)
    if oldIdentity ~= nil and SetThreadIdentityFunction then
        pcall(SetThreadIdentityFunction, oldIdentity)
    end
    return ok, result
end

local function sendVirtual(key, down)
    if not BackendAvailability["Virtual Input"] or not VirtualInputManager then
        return false
    end
    return withIdentity8(function()
        VirtualInputManager:SendKeyEvent(down, key, false, game)
    end)
end

local function sendFireSignal(lane, down)
    if not BackendAvailability.firesignal or not FiresignalFunction then
        return false
    end
    local bindName = "Direction" .. lane
    local signal = down and UserInputBindables.InputEvents.Began or UserInputBindables.InputEvents.Ended
    local ok = pcall(FiresignalFunction, signal, bindName, nil, false)
    if ok then
        state.FireHeld[bindName] = down or nil
    end
    return ok
end

local function resolveGetGC(force)
    if not BackendAvailability.getgc or not GetGCFunction then
        return false
    end
    if not force and os.clock() - state.LastGCResolve < 1 and type(state.GCGoodhit) == "function" then
        return true
    end
    state.LastGCResolve = os.clock()
    state.GCGoodhit = nil
    state.GCCheckInput = nil
    local ok, objects = pcall(GetGCFunction, true)
    if not ok or type(objects) ~= "table" then
        ok, objects = pcall(GetGCFunction)
    end
    if not ok or type(objects) ~= "table" then
        return false
    end
    for _, object in objects do
        if type(object) == "function" then
            local name
            pcall(function()
                name = DebugInfoFunction(object)
            end)
            if name == "Goodhit" then
                state.GCGoodhit = object
            elseif name == "CheckInput" then
                state.GCCheckInput = object
            elseif name == "checkHeldKeys" and type(DebugLibrary.getupvalues) == "function" then
                local upvaluesOk, upvalues = pcall(DebugLibrary.getupvalues, object)
                local notes = upvaluesOk and type(upvalues) == "table" and upvalues[2]
                if type(notes) == "table" then
                    for _, note in notes do
                        if type(note) == "table" then
                            state.Active[note] = true
                            if typeof(note.NoteObject) == "Instance" then
                                state.GuiToNote[note.NoteObject] = note
                            end
                        end
                    end
                end
            end
        end
    end
    return type(state.GCGoodhit) == "function"
end

state.ResolveGetGC = resolveGetGC

local function setInputMode(mode)
    if not BackendAvailability[mode] then
        return false
    end
    if state.ReleaseAll then
        state.ReleaseAll()
    end
    state.InputMode = mode
    if mode == "getgc" then
        resolveGetGC(true)
    end
    queueSave()
    return true
end

state.SetInputMode = setInputMode

local function pressLane(lane, key)
    if state.Pressed[lane] then
        return true
    end
    local ok
    if state.InputMode == "Virtual Input" then
        ok = sendVirtual(key, true)
    elseif state.InputMode == "firesignal" then
        ok = sendFireSignal(lane, true)
    else
        ok = true
    end
    if ok then
        state.Pressed[lane] = key
    end
    return ok
end

local function releaseLane(lane)
    local key = state.Pressed[lane]
    if not key then
        return
    end
    if state.InputMode == "Virtual Input" then
        sendVirtual(key, false)
    elseif state.InputMode == "firesignal" then
        sendFireSignal(lane, false)
    end
    state.Pressed[lane] = nil
    state.TapReleaseAt[lane] = nil
end

local function releaseAll()
    for lane in state.Pressed do
        releaseLane(lane)
    end
    table.clear(state.Pressed)
    table.clear(state.HoldUntil)
    table.clear(state.TapReleaseAt)
    table.clear(state.VisualHoldUntil)
    table.clear(state.FireHeld)
end

state.ReleaseAll = releaseAll

local harmfulTokens = {
    "poison", "mine", "hurt", "death", "kill", "damage", "attack", "bullet", "trap", "black", "fake", "warning", "bomb", "danger"
}

local function isHarmful(note)
    if not state.SkipHarmful then
        return false
    end
    local noteType = string.lower(tostring(note.Type or ""))
    if noteType == "" or noteType == "none" then
        return false
    end
    for _, token in harmfulTokens do
        if noteType:find(token, 1, true) then
            return true
        end
    end
    return false
end

local OriginalSpawn = type(NoteModule.SpawnNote) == "function" and NoteModule.SpawnNote or nil
state.OriginalSpawn = OriginalSpawn

local function trackNote(note)
    if type(note) ~= "table" then
        return
    end
    state.Active[note] = true
    local gui = note.NoteObject
    if typeof(gui) == "Instance" then
        state.GuiToNote[gui] = note
        state.PendingGui[gui] = note
    end
    if note.MustPress and type(note.Mania) == "number" then
        if state.CurrentMania ~= note.Mania then
            state.CurrentMania = note.Mania
            applyRuntimeBinds(note.Mania)
        end
        if note.IsSustain and type(note.StrumTime) == "number" then
            local lane = (tonumber(note.NoteData) or 0) + 1
            state.HoldUntil[lane] = math.max(state.HoldUntil[lane] or 0, note.StrumTime + state.SustainBuffer)
        end
    end
end

local wrappedSpawn
local spawnHookError

if not state.VisualMode and OriginalSpawn then
    wrappedSpawn = function(note)
        local result = OriginalSpawn(note)
        if result then
            trackNote(note)
        end
        return result
    end
    state.WrappedSpawn = wrappedSpawn
    local spawnHookOk
    spawnHookOk, spawnHookError = pcall(function()
        NoteModule.SpawnNote = wrappedSpawn
    end)
    state.SpawnHooked = spawnHookOk
    if not spawnHookOk then
        if BackendAvailability.getgc then
            state.InputMode = "getgc"
            resolveGetGC(true)
            warn("[FNP Autoplayer] Note.SpawnNote could not be wrapped; using getgc tracking:", spawnHookError)
        else
            state.VisualMode = true
            state.ModuleAccessMode = "visual-hook-fallback"
            warn("[FNP Autoplayer] Note.SpawnNote could not be wrapped. Visual note tracking fallback enabled:", spawnHookError)
        end
    end
else
    state.SpawnHooked = false
end

local laneCountToLayout = {
    [4] = 1,
    [6] = 2,
    [9] = 3,
    [5] = 4,
    [7] = 5,
    [8] = 6,
    [12] = 7
}

local supportedLaneCounts = {4, 5, 6, 7, 8, 9, 12}
local detectVisualSide
local refreshVisualReceptors

local function normalizedGuiName(gui)
    return tostring(gui.Name or ""):gsub("%z", "")
end

local function isVisualGui(gui)
    return typeof(gui) == "Instance" and (gui:IsA("ImageLabel") or gui:IsA("ImageButton"))
end

local function removeVisualGui(gui)
    state.VisualNotes[gui] = nil
    state.VisualCandidateFirstSeen[gui] = nil
end

local function removeGui(gui)
    removeVisualGui(gui)
    local note = state.GuiToNote[gui] or state.PendingGui[gui]
    if note then
        if state.Triggered[note] and not state.Counted[note] then
            if note.GoodHit then
                state.Counted[note] = true
                state.Hits += 1
            elseif note.TooLate then
                state.Counted[note] = true
                state.Misses += 1
            end
        end
        state.Active[note] = nil
        state.Triggered[note] = nil
        state.Counted[note] = nil
        state.GuiToNote[gui] = nil
        state.PendingGui[gui] = nil
    end
end

local function registerVisualGui(gui)
    if not isVisualGui(gui) or gui.Parent ~= state.VisualContainer then
        return
    end

    if state.VisualCandidateFirstSeen[gui] == nil then
        state.VisualCandidateFirstSeen[gui] = os.clock()
    end

    if normalizedGuiName(gui) == "" then
        return
    end

    if not state.VisualNotes[gui] then
        state.VisualNotes[gui] = {
            Gui = gui,
            LastCenterY = nil,
            LastRawSigned = nil,
            LastAdjustedSigned = nil,
            LastTop = nil,
            LastBottom = nil,
            LastTime = nil,
            Triggered = false,
            MissCounted = false
        }
    end
end

local function visualCenter(gui)
    local position = gui.AbsolutePosition
    local size = gui.AbsoluteSize
    return position.X + size.X * 0.5, position.Y + size.Y * 0.5
end

local function selectVisualContainer(container, side, method)
    if not container or not container.Parent then
        return false
    end

    local changed = state.VisualContainer ~= container
    if changed then
        releaseAll()
        table.clear(state.VisualNotes)
        table.clear(state.VisualReceptors)
        table.clear(state.VisualCandidateFirstSeen)
        state.VisualContainer = container
        state.LastVisualReceptorScan = 0
        state.CurrentMania = nil
        state.CurrentLaneCount = nil
        state.DetectedMode = "Detecting"
        state.LastVisualSideSwitch = os.clock()

        for _, child in container:GetChildren() do
            registerVisualGui(child)
        end
    end

    state.DetectedSide = side
    state.DetectedSideMethod = method

    if changed then
        task.defer(function()
            if refreshVisualReceptors then
                refreshVisualReceptors(true)
            end
        end)
    end

    return true
end

local function inferSideFromPerformingSpot()
    local character = LocalPlayer.Character
    if not character then
        return nil
    end

    local positions = {}
    local oldPosition = character:GetAttribute("OldPos")

    if typeof(oldPosition) == "CFrame" then
        positions[#positions + 1] = oldPosition.Position
    elseif typeof(oldPosition) == "Vector3" then
        positions[#positions + 1] = oldPosition
    elseif type(oldPosition) == "string" then
        local x, y, z = oldPosition:match("^%s*([%+%-]?[%d%.eE]+)%s*,%s*([%+%-]?[%d%.eE]+)%s*,%s*([%+%-]?[%d%.eE]+)")
        if x and y and z then
            positions[#positions + 1] = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
        end
    end

    local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    if root and root:IsA("BasePart") then
        positions[#positions + 1] = root.Position
    end

    if #positions == 0 then
        return nil
    end

    local performingSpots = workspace:FindFirstChild("PerformingSpots")
    if not performingSpots then
        return nil
    end

    local bestSide
    local bestDistance = math.huge

    for _, spot in performingSpots:GetChildren() do
        if spot:IsA("Model") then
            local boyfriend = spot:FindFirstChild("Boyfriend")
            local dad = spot:FindFirstChild("Dad")

            if boyfriend and boyfriend:IsA("BasePart") and dad and dad:IsA("BasePart") then
                for _, position in positions do
                    local bfDistance = (position - boyfriend.Position).Magnitude
                    if bfDistance < bestDistance then
                        bestDistance = bfDistance
                        bestSide = "BF"
                    end

                    local dadDistance = (position - dad.Position).Magnitude
                    if dadDistance < bestDistance then
                        bestDistance = dadDistance
                        bestSide = "Dad"
                    end
                end
            end
        end
    end

    if bestSide and bestDistance <= 7.5 then
        return bestSide, string.format("Performing-spot position matched %s at %.2f studs", bestSide, bestDistance)
    end
end

local function inferSideFromOpponentScore()
    local gameUI = PlayerGui:FindFirstChild("GameUI")
    local realGameUI = gameUI and gameUI:FindFirstChild("realGameUI")
    local opponentScore = realGameUI and realGameUI:FindFirstChild("OpponentScore")
    local format = opponentScore and opponentScore:FindFirstChild("Format")

    if not format or not format:IsA("StringValue") then
        return nil
    end

    local gameHandler = gameUI and gameUI:FindFirstChild("GameHandler")
    local templates = gameHandler and gameHandler:FindFirstChild("OpponentStats")
    if not templates then
        return nil
    end

    for _, scrollFolder in templates:GetChildren() do
        local bf = scrollFolder:FindFirstChild("BFScore")
        local dad = scrollFolder:FindFirstChild("DadScore")
        local bfFormat = bf and bf:FindFirstChild("Format")
        local dadFormat = dad and dad:FindFirstChild("Format")

        if bfFormat and bfFormat:IsA("StringValue") and format.Value == bfFormat.Value then
            return "Dad", "Opponent-score layout identifies the local side as Dad/left"
        end
        if dadFormat and dadFormat:IsA("StringValue") and format.Value == dadFormat.Value then
            return "BF", "Opponent-score layout identifies the local side as BF/right"
        end
    end
end

local function inferSideFromKeyHints()
    local keyNames = {}

    for _, layout in Layouts do
        for _, key in layout.Keys do
            keyNames[key.Name] = true
        end
    end

    for _, mode in GameSettings.settings.Keybinds do
        if type(mode) == "table" then
            for _, lane in mode do
                if type(lane) == "table" then
                    for _, value in lane do
                        local key = typeof(value) == "Instance" and value.Value or value
                        if typeof(key) == "EnumItem" and key.EnumType == Enum.KeyCode then
                            keyNames[key.Name] = true
                        end
                    end
                end
            end
        end
    end

    local counts = {BF = 0, Dad = 0}

    for side, containerName in {BF = "BFNotes", Dad = "DadNotes"} do
        local container = state.VisualContainers[containerName]
        if container and container.Parent then
            for _, descendant in container:GetDescendants() do
                if descendant:IsA("TextLabel") then
                    local value = tostring(descendant.Text):gsub("^%s+", ""):gsub("%s+$", "")
                    if keyNames[value] then
                        counts[side] += 1
                    end
                end
            end
        end
    end

    if counts.BF > counts.Dad and counts.BF > 0 then
        return "BF", string.format("Found %d key labels on BF/right receptors", counts.BF)
    end
    if counts.Dad > counts.BF and counts.Dad > 0 then
        return "Dad", string.format("Found %d key labels on Dad/left receptors", counts.Dad)
    end
end

local function inferSideFromCharacter()
    local character = LocalPlayer.Character
    local camera = workspace.CurrentCamera
    if not character or not camera or camera.ViewportSize.X <= 0 then
        return nil
    end

    local root = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    if not root or not root:IsA("BasePart") then
        return nil
    end

    local point = camera:WorldToViewportPoint(root.Position)
    if point.Z <= 0 then
        return nil
    end

    local ratio = point.X / camera.ViewportSize.X
    if ratio < 0.42 then
        return "Dad", string.format("Fallback screen projection placed the character at %.1f%%", ratio * 100)
    end
    if ratio > 0.58 then
        return "BF", string.format("Fallback screen projection placed the character at %.1f%%", ratio * 100)
    end
end

detectVisualSide = function(force)
    if not state.VisualMode then
        return false
    end

    local now = os.clock()
    if not force and now - state.LastVisualSideCheck < 0.2 then
        return state.VisualContainer ~= nil
    end
    state.LastVisualSideCheck = now

    local side
    local method
    local immediate = false

    if state.VisualSide == "BF" or state.VisualSide == "Dad" then
        side = state.VisualSide
        method = "Manual override"
        immediate = true
    else
        side, method = inferSideFromPerformingSpot()
        if side then
            immediate = true
        else
            side, method = inferSideFromOpponentScore()
            if side then
                immediate = true
            elseif state.VisualContainer and state.VisualContainer.Parent then
                return true
            else
                side, method = inferSideFromKeyHints()
                if side then
                    immediate = true
                else
                    side, method = inferSideFromCharacter()
                end
            end
        end
    end

    if not side then
        side = state.VisualContainers.BFNotes and "BF" or state.VisualContainers.DadNotes and "Dad" or nil
        method = side and "Temporary default while waiting for a performing-spot match" or "Waiting for BFNotes or DadNotes"
    end

    if not side then
        state.DetectedSide = "Unknown"
        state.DetectedSideMethod = method
        return false
    end

    if state.VisualSideVote == side then
        state.VisualSideVoteCount += 1
    else
        state.VisualSideVote = side
        state.VisualSideVoteCount = 1
    end

    local requiredVotes = immediate and 1 or 3
    if state.VisualSideVoteCount < requiredVotes then
        state.DetectedSideMethod = method .. " (confirming)"
        return state.VisualContainer ~= nil
    end

    local container = state.VisualContainers[side .. "Notes"]
    if not container or not container.Parent then
        state.DetectedSide = side
        state.DetectedSideMethod = method .. " (container unavailable)"
        return false
    end

    return selectVisualContainer(container, side, method)
end

local function groupReceptorCandidates(candidates)
    table.sort(candidates, function(a, b)
        if a.X ~= b.X then
            return a.X < b.X
        end
        return a.FirstSeen < b.FirstSeen
    end)

    local averageWidth = 0
    for _, candidate in candidates do
        averageWidth += candidate.Width
    end
    averageWidth = #candidates > 0 and averageWidth / #candidates or 40
    local tolerance = math.clamp(averageWidth * 0.3, 10, 32)

    local groups = {}
    for _, candidate in candidates do
        local group = groups[#groups]
        if not group or math.abs(candidate.X - group.X) > tolerance then
            group = {
                X = candidate.X,
                Items = {}
            }
            groups[#groups + 1] = group
        end

        group.Items[#group.Items + 1] = candidate
        group.X = (group.X * (#group.Items - 1) + candidate.X) / #group.Items
    end

    local selected = {}
    for _, group in groups do
        table.sort(group.Items, function(a, b)
            if a.FirstSeen ~= b.FirstSeen then
                return a.FirstSeen < b.FirstSeen
            end
            return a.Area > b.Area
        end)
        selected[#selected + 1] = group.Items[1]
    end

    return selected
end

refreshVisualReceptors = function(force)
    local container = state.VisualContainer
    if not container or not container.Parent then
        table.clear(state.VisualReceptors)
        state.CurrentMania = nil
        state.CurrentLaneCount = nil
        state.DetectedMode = "Idle"
        return false
    end

    local now = os.clock()
    if not force and now - state.LastVisualReceptorScan < 0.15 then
        return #state.VisualReceptors > 0
    end
    state.LastVisualReceptorScan = now

    local imageBuckets = {}
    local allCandidates = {}

    for _, child in container:GetChildren() do
        if isVisualGui(child) then
            if state.VisualCandidateFirstSeen[child] == nil then
                state.VisualCandidateFirstSeen[child] = now
            end

            local size = child.AbsoluteSize
            local age = now - state.VisualCandidateFirstSeen[child]
            if normalizedGuiName(child) == ""
                and child.Visible
                and child.ZIndex == 1
                and child.ImageTransparency < 0.98
                and size.X > 4
                and size.Y > 4
                and age >= 0.1
            then
                local x, y = visualCenter(child)
                local candidate = {
                    Gui = child,
                    X = x,
                    Y = y,
                    Width = size.X,
                    Height = size.Y,
                    Area = size.X * size.Y,
                    FirstSeen = state.VisualCandidateFirstSeen[child],
                    Image = tostring(child.Image)
                }

                allCandidates[#allCandidates + 1] = candidate
                imageBuckets[candidate.Image] = imageBuckets[candidate.Image] or {}
                imageBuckets[candidate.Image][#imageBuckets[candidate.Image] + 1] = candidate
            end
        end
    end

    local selected
    local selectedLayout

    for _, candidates in imageBuckets do
        local grouped = groupReceptorCandidates(candidates)
        local layoutIndex = laneCountToLayout[#grouped]
        if layoutIndex and (not selected or #grouped > #selected) then
            selected = grouped
            selectedLayout = layoutIndex
        end
    end

    if not selected then
        local grouped = groupReceptorCandidates(allCandidates)
        selectedLayout = laneCountToLayout[#grouped]
        if selectedLayout then
            selected = grouped
        end
    end

    if not selected or not selectedLayout then
        return #state.VisualReceptors > 0
    end

    table.sort(selected, function(a, b)
        return a.X < b.X
    end)

    table.clear(state.VisualReceptors)
    for _, candidate in selected do
        state.VisualReceptors[#state.VisualReceptors + 1] = candidate.Gui
    end

    state.CurrentMania = selectedLayout - 1
    state.CurrentLaneCount = #selected
    state.DetectedMode = Layouts[selectedLayout].Name
    return true
end

local function connectContainer(container)
    if state.ConnectedContainers[container] then
        return
    end

    state.ConnectedContainers[container] = true

    if state.VisualMode then
        state.VisualContainers[container.Name] = container

        state.ContainerConnections[#state.ContainerConnections + 1] = container.ChildAdded:Connect(function(child)
            if container == state.VisualContainer then
                registerVisualGui(child)
                task.defer(function()
                    if child.Parent == container and container == state.VisualContainer then
                        registerVisualGui(child)
                    end
                end)
                task.delay(0.03, function()
                    if child.Parent == container and container == state.VisualContainer then
                        registerVisualGui(child)
                    end
                end)
                if normalizedGuiName(child) == "" or #state.VisualReceptors == 0 then
                    task.defer(refreshVisualReceptors, true)
                end
            end
        end)

        state.ContainerConnections[#state.ContainerConnections + 1] = container.ChildRemoved:Connect(function(child)
            if container == state.VisualContainer then
                local wasReceptor = table.find(state.VisualReceptors, child) ~= nil
                removeVisualGui(child)
                if wasReceptor then
                    task.defer(refreshVisualReceptors, true)
                end
            end
        end)

        task.defer(detectVisualSide, true)
        return
    end

    state.ContainerConnections[#state.ContainerConnections + 1] = container.ChildAdded:Connect(function(child)
        local note = state.PendingGui[child] or state.GuiToNote[child]
        if note then
            state.Active[note] = true
            state.GuiToNote[child] = note
            state.PendingGui[child] = nil
        end
    end)

    state.ContainerConnections[#state.ContainerConnections + 1] = container.ChildRemoved:Connect(removeGui)

    for _, child in container:GetChildren() do
        local note = state.PendingGui[child] or state.GuiToNote[child]
        if note then
            state.Active[note] = true
            state.GuiToNote[child] = note
            state.PendingGui[child] = nil
        end
    end
end

local function inspectContainer(instance)
    if not instance:IsA("GuiObject") then
        return
    end

    if state.VisualMode then
        if instance.Name == "BFNotes" or instance.Name == "DadNotes" then
            connectContainer(instance)
        end
    elseif instance.Name == "BFNotes" or instance.Name == "DadNotes" then
        connectContainer(instance)
    end
end

for _, descendant in PlayerGui:GetDescendants() do
    inspectContainer(descendant)
end

state.Connections[#state.Connections + 1] = PlayerGui.DescendantAdded:Connect(inspectContainer)
state.Connections[#state.Connections + 1] = PlayerGui.DescendantRemoving:Connect(function(instance)
    if state.ConnectedContainers[instance] then
        state.ConnectedContainers[instance] = nil
    end

    if state.VisualContainers[instance.Name] == instance then
        state.VisualContainers[instance.Name] = nil
    end

    if instance == state.VisualContainer then
        state.VisualContainer = nil
        table.clear(state.VisualNotes)
        table.clear(state.VisualReceptors)
        state.CurrentMania = nil
        state.CurrentLaneCount = nil
        state.DetectedMode = "Idle"
        releaseAll()
        task.defer(detectVisualSide, true)
    end

    removeGui(instance)
end)

if BackendAvailability.getgc then
    resolveGetGC(true)
end

local function getAccuracy()
    local sharedTable = type(shared) == "table" and shared or {}
    local handler = rawget(sharedTable, "handler")
    if type(handler) == "table" and type(handler.PlayerStats) == "table" and type(handler.PlayerStats.Accuracy) == "number" then
        return string.format("%.2f%%", handler.PlayerStats.Accuracy)
    end
    return "N/A"
end

local function isVisualHarmful(gui)
    if not state.SkipHarmful then
        return false
    end

    local name = string.lower(normalizedGuiName(gui))
    if name == "" or name == "none" or name == "default" or name == "original" then
        return false
    end

    for _, token in harmfulTokens do
        if name:find(token, 1, true) then
            return true
        end
    end

    return false
end

local function nearestVisualReceptor(x)
    local bestLane
    local bestReceptor
    local bestDistance

    for lane, receptor in state.VisualReceptors do
        if receptor and receptor.Parent == state.VisualContainer then
            local receptorX = receptor.AbsolutePosition.X + receptor.AbsoluteSize.X * 0.5
            local distance = math.abs(x - receptorX)
            if not bestDistance or distance < bestDistance then
                bestLane = lane
                bestReceptor = receptor
                bestDistance = distance
            end
        end
    end

    return bestLane, bestReceptor, bestDistance
end

local function hasFollowingVisualSustain(headGui, lane, receptor, relativeVelocity)
    local headX, headY = visualCenter(headGui)
    local receptorHeight = receptor.AbsoluteSize.Y
    local maxDistance = math.max(receptorHeight * 7, 320)

    for gui in state.VisualNotes do
        if gui ~= headGui
            and gui.Parent == state.VisualContainer
            and gui.Visible
            and gui.ImageTransparency < 0.98
            and gui.ZIndex <= 1
            and not isVisualHarmful(gui)
        then
            local x, y = visualCenter(gui)
            local otherLane, _, horizontalDistance = nearestVisualReceptor(x)
            if otherLane == lane and horizontalDistance <= math.max(receptor.AbsoluteSize.X, 72) then
                local delta = y - headY
                local follows = relativeVelocity < -1 and delta >= -receptorHeight
                    or relativeVelocity > 1 and delta <= receptorHeight
                    or math.abs(relativeVelocity) <= 1

                if follows
                    and math.abs(delta) <= maxDistance
                    and math.abs(x - headX) <= math.max(receptor.AbsoluteSize.X * 1.25, 84)
                then
                    return true
                end
            end
        end
    end

    return false
end

local function processVisualNotes()
    detectVisualSide(false)

    local container = state.VisualContainer
    if not container or not container.Parent then
        if next(state.Pressed) then
            releaseAll()
        end
        return
    end

    local receptorsValid = #state.VisualReceptors > 0
    if receptorsValid then
        for _, receptor in state.VisualReceptors do
            if not receptor or receptor.Parent ~= container then
                receptorsValid = false
                break
            end
        end
    end

    refreshVisualReceptors(not receptorsValid)

    local now = os.clock()
    local activeSustain = {}
    local dueCount = 0

    for gui, record in state.VisualNotes do
        if not gui.Parent or gui.Parent ~= container then
            state.VisualNotes[gui] = nil
        elseif gui.Visible
            and gui.ImageTransparency < 0.98
            and gui.AbsoluteSize.X > 2
            and gui.AbsoluteSize.Y > 2
            and normalizedGuiName(gui) ~= ""
            and table.find(state.VisualReceptors, gui) == nil
        then
            local centerX, centerY = visualCenter(gui)
            local lane, receptor, horizontalDistance = nearestVisualReceptor(centerX)

            if lane and receptor then
                local _, receptorY = visualCenter(receptor)
                local maxHorizontalDistance = math.max(receptor.AbsoluteSize.X, 72)

                if horizontalDistance <= maxHorizontalDistance then
                    local rawSigned = centerY - receptorY
                    local deltaTime = record.LastTime and math.max(now - record.LastTime, 0.001) or 0
                    local relativeVelocity = 0

                    if deltaTime > 0 and record.LastRawSigned ~= nil then
                        relativeVelocity = (rawSigned - record.LastRawSigned) / deltaTime
                    end

                    local offsetSeconds = state.TimingOffset / 1000
                    local adjustedSigned = rawSigned - relativeVelocity * offsetSeconds
                    local previous = record.LastAdjustedSigned
                    local travel = deltaTime > 0 and math.abs(relativeVelocity) * deltaTime or 0
                    local baseThreshold = math.clamp(receptor.AbsoluteSize.Y * 0.52, 16, 52)
                    local dynamicThreshold = math.max(baseThreshold, math.min(baseThreshold * 4, travel * 1.5 + 10))
                    local crossed = previous ~= nil
                        and ((previous > 0 and adjustedSigned <= 0) or (previous < 0 and adjustedSigned >= 0))
                    local within = math.abs(adjustedSigned) <= dynamicThreshold
                    local timeToHit = math.huge

                    if math.abs(relativeVelocity) > 1 then
                        timeToHit = -adjustedSigned / relativeVelocity
                    end

                    local predicted = timeToHit >= 0
                        and timeToHit <= math.max(0.09, deltaTime * 3.5)
                    local harmful = isVisualHarmful(gui)
                    local sustain = gui.ZIndex <= 1
                    local adjustedTop = gui.AbsolutePosition.Y - relativeVelocity * offsetSeconds
                    local adjustedBottom = adjustedTop + gui.AbsoluteSize.Y
                    local tapThreshold = math.max(
                        baseThreshold,
                        math.min(baseThreshold * 2.75, travel * 2 + 14)
                    )
                    local tapOverlap = adjustedTop <= receptorY + tapThreshold
                        and adjustedBottom >= receptorY - tapThreshold
                    local sweptTop = record.LastTop ~= nil
                        and math.min(record.LastTop, adjustedTop) <= receptorY + tapThreshold
                        and math.max(record.LastBottom, adjustedBottom) >= receptorY - tapThreshold
                    local movingTowardOrAcross = previous == nil
                        or math.abs(adjustedSigned) <= math.abs(previous)
                        or crossed

                    if sustain then
                        local overlap = adjustedTop <= receptorY + dynamicThreshold
                            and adjustedBottom >= receptorY - dynamicThreshold

                        if overlap and not harmful then
                            dueCount += 1
                            if state.Enabled then
                                local key = getLaneKey((state.CurrentMania or 0) + 1, lane)
                                if key and pressLane(lane, key) then
                                    state.VisualHoldUntil[lane] = now + math.max(
                                        0.12,
                                        state.SustainBuffer / 1000 + math.max(deltaTime * 2, 0.03)
                                    )
                                    state.TapReleaseAt[lane] = nil
                                    activeSustain[lane] = true
                                    record.Triggered = true
                                end
                            end
                        end
                    elseif not record.Triggered
                        and not harmful
                        and movingTowardOrAcross
                        and (within or crossed or predicted or tapOverlap or sweptTop)
                    then
                        dueCount += 1
                        if state.Enabled then
                            local key = getLaneKey((state.CurrentMania or 0) + 1, lane)
                            if key then
                                if state.Pressed[lane] and not activeSustain[lane] then
                                    releaseLane(lane)
                                    state.RetriggerCount = (state.RetriggerCount or 0) + 1
                                end

                                if pressLane(lane, key) then
                                    if hasFollowingVisualSustain(gui, lane, receptor, relativeVelocity) then
                                        state.VisualHoldUntil[lane] = now + math.max(
                                            0.22,
                                            state.SustainBuffer / 1000 + math.max(deltaTime * 3, 0.05)
                                        )
                                        state.TapReleaseAt[lane] = nil
                                    else
                                        state.TapReleaseAt[lane] = now + math.max(
                                            0.04,
                                            state.TapDuration / 1000
                                        )
                                    end

                                    record.Triggered = true
                                    state.Hits += 1
                                    state.ProcessedThisFrame = (state.ProcessedThisFrame or 0) + 1
                                end
                            end
                        end
                    elseif not record.Triggered
                        and state.Enabled
                        and previous ~= nil
                        and math.abs(adjustedSigned) > dynamicThreshold * 3
                        and math.abs(adjustedSigned) > math.abs(previous)
                        and ((relativeVelocity < 0 and adjustedSigned < 0) or (relativeVelocity > 0 and adjustedSigned > 0))
                    then
                        record.Triggered = true
                        if not record.MissCounted and not harmful then
                            record.MissCounted = true
                            state.Misses += 1
                        end
                    end

                    record.LastRawSigned = rawSigned
                    record.LastAdjustedSigned = adjustedSigned
                    record.LastTop = adjustedTop
                    record.LastBottom = adjustedBottom
                end
            end

            record.LastCenterY = centerY
            record.LastTime = now
        end
    end

    state.LastDueCount = dueCount
    state.PeakDueCount = math.max(state.PeakDueCount or 0, dueCount)

    if not state.Enabled then
        releaseAll()
        return
    end

    for lane in state.Pressed do
        if activeSustain[lane] then
            continue
        end

        local holdUntil = state.VisualHoldUntil[lane]
        local tapAt = state.TapReleaseAt[lane]

        if holdUntil then
            if now >= holdUntil then
                state.VisualHoldUntil[lane] = nil
                releaseLane(lane)
            end
        elseif tapAt and now >= tapAt then
            releaseLane(lane)
        end
    end
end

state.DetectVisualSide = detectVisualSide
state.RefreshVisualReceptors = refreshVisualReceptors

local function trackedNoteCount()
    if state.VisualMode then
        return countTable(state.VisualNotes)
    end
    return countTable(state.Active)
end

local function processNotes(deltaTime)
    if state.VisualMode then
        processVisualNotes()
        return
    end
    if not state.SpawnHooked and BackendAvailability.getgc and os.clock() - state.LastGCResolve >= 1 then
        resolveGetGC(true)
    end
    local songPosition = Conductor.SongPos
    if type(songPosition) ~= "number" then
        return
    end
    if songPosition < state.LastSongPos - 1000 then
        releaseAll()
        table.clear(state.Triggered)
        table.clear(state.Counted)
        state.CurrentMania = nil
        if state.InputMode == "getgc" then
            resolveGetGC(true)
        end
    end
    state.LastSongPos = songPosition

    local now = os.clock()
    local frameLead = math.clamp((tonumber(deltaTime) or 0) * 500, 0, 10)
    local hitPosition = songPosition - state.TimingOffset + frameLead
    local dueNotes = state.DueNotes

    if type(dueNotes) ~= "table" then
        dueNotes = {}
        state.DueNotes = dueNotes
    else
        table.clear(dueNotes)
    end

    for note in state.Active do
        if type(note) ~= "table" or note.Destroyed == true then
            state.Active[note] = nil
            state.Triggered[note] = nil
            state.Counted[note] = nil
        elseif note.MustPress == true and note.shouldPress ~= false and not isHarmful(note) then
            local lane = (tonumber(note.NoteData) or 0) + 1
            local strumTime = tonumber(note.StrumTime)

            if note.IsSustain and strumTime then
                state.HoldUntil[lane] = math.max(state.HoldUntil[lane] or 0, strumTime + state.SustainBuffer)
            end

            if state.Enabled
                and strumTime
                and not note.TooLate
                and not note.GoodHit
                and note.CanBeHit
                and not state.Triggered[note]
                and hitPosition >= strumTime
            then
                dueNotes[#dueNotes + 1] = note
            end

            if state.Triggered[note] and note.GoodHit and not state.Counted[note] then
                state.Counted[note] = true
                state.Hits += 1
            elseif note.TooLate and state.Triggered[note] and not note.GoodHit and not state.Counted[note] then
                state.Counted[note] = true
                state.Misses += 1
            end
        end
    end

    table.sort(dueNotes, function(a, b)
        local aTime = tonumber(a.StrumTime) or math.huge
        local bTime = tonumber(b.StrumTime) or math.huge

        if aTime ~= bTime then
            return aTime < bTime
        end

        if a.IsSustain ~= b.IsSustain then
            return not a.IsSustain
        end

        local aLane = tonumber(a.NoteData) or 0
        local bLane = tonumber(b.NoteData) or 0

        if aLane ~= bLane then
            return aLane < bLane
        end

        return tostring(a) < tostring(b)
    end)

    state.LastDueCount = #dueNotes
    state.PeakDueCount = math.max(state.PeakDueCount or 0, #dueNotes)

    for index = 1, #dueNotes do
        local note = dueNotes[index]

        if not state.Triggered[note]
            and not note.GoodHit
            and not note.TooLate
            and note.CanBeHit
        then
            local lane = (tonumber(note.NoteData) or 0) + 1
            local mania = tonumber(note.Mania) or 0
            local key = getLaneKey(mania + 1, lane)
            local strumTime = tonumber(note.StrumTime) or songPosition
            local success = false

            if state.InputMode == "getgc" then
                if type(state.GCGoodhit) ~= "function" then
                    resolveGetGC(true)
                end
                if type(state.GCGoodhit) == "function" then
                    success = pcall(state.GCGoodhit, note)
                end
            elseif note.IsSustain then
                if key then
                    success = pressLane(lane, key)
                end
            elseif key then
                if state.Pressed[lane] then
                    releaseLane(lane)
                    state.RetriggerCount = (state.RetriggerCount or 0) + 1
                end

                success = pressLane(lane, key)

                if success then
                    local holdLength = tonumber(note.SustainLength) or 0

                    if holdLength > 0 then
                        local step = tonumber(Conductor.stepCrochet) or 0
                        state.HoldUntil[lane] = math.max(
                            state.HoldUntil[lane] or 0,
                            strumTime + holdLength + step + state.SustainBuffer
                        )
                    else
                        state.TapReleaseAt[lane] = now + math.max(0.003, state.TapDuration / 1000)
                    end
                end
            end

            if success then
                state.Triggered[note] = true
                state.ProcessedThisFrame = (state.ProcessedThisFrame or 0) + 1
            end
        end
    end

    for lane in state.Pressed do
        local holdUntil = state.HoldUntil[lane] or 0
        local tapAt = state.TapReleaseAt[lane]

        if holdUntil > 0 then
            if songPosition > holdUntil then
                state.HoldUntil[lane] = nil
                releaseLane(lane)
            end
        elseif tapAt and now >= tapAt then
            releaseLane(lane)
        end
    end
end

state.Connections[#state.Connections + 1] = RunService.RenderStepped:Connect(processNotes)

state.Connections[#state.Connections + 1] = UserInputService.InputBegan:Connect(function(input, processed)
    if processed or state.Destroyed then
        return
    end
    if input.KeyCode == state.AutoplayerToggleKey then
        if #state.AvailableInputModes == 0 then
            state.Enabled = false
            return
        end
        state.Enabled = not state.Enabled
        if not state.Enabled then
            releaseAll()
        end
        if state.EnabledToggle and type(state.EnabledToggle.Set) == "function" then
            withIdentity8(function()
                state.EnabledToggle:Set(state.Enabled)
            end)
        end
        queueSave()
    end
end)

local function cleanupOrphanedWindUIInputs(oldGui, oldWindow)
    local removed = 0
    local function referencesOld(value)
        if value == oldWindow then
            return true
        end
        if typeof(value) == "Instance" and oldGui then
            local ok, result = pcall(function()
                return value == oldGui or value:IsDescendantOf(oldGui)
            end)
            if ok and result then
                return true
            end
        end
        if type(value) == "table" and value.__type == "Keybind" then
            return true
        end
        if type(value) == "string" then
            if value:match("^%d+K %- Lane %d+$") or value:match("^Lane %d+$") or value == "Autoplayer toggle key" then
                return true
            end
        end
        return false
    end
    if GetConnectionsFunction then
        for _, signal in {UserInputService.InputBegan, UserInputService.InputEnded, UserInputService.InputChanged} do
            local ok, connections = pcall(GetConnectionsFunction, signal)
            if ok then
                for _, connection in connections do
                    local fn
                    pcall(function()
                        fn = connection.Function
                    end)
                    local remove = false
                    if type(fn) == "function" and type(DebugLibrary.getupvalues) == "function" then
                        local okUps, upvalues = pcall(DebugLibrary.getupvalues, fn)
                        if okUps and type(upvalues) == "table" then
                            for _, value in upvalues do
                                if referencesOld(value) then
                                    remove = true
                                    break
                                end
                            end
                        end
                    end
                    if remove then
                        pcall(function()
                            connection:Disconnect()
                        end)
                        removed += 1
                    end
                end
            end
        end
    end
    state.StaleInputListenersRemoved = (state.StaleInputListenersRemoved or 0) + removed
    return removed
end

state.CleanupOrphanedWindUIInputs = cleanupOrphanedWindUIInputs

local WindUI
local Window

local function fetchText(url)
    local failures = {}
    local ok, result = pcall(game.HttpGet, game, url)
    if ok and type(result) == "string" and #result > 0 then
        return result, "game:HttpGet"
    end
    failures[#failures + 1] = "game:HttpGet: " .. tostring(result)
    if RequestFunction then
        local requestOk, response = pcall(RequestFunction, {
            Url = url,
            Method = "GET"
        })
        if requestOk then
            if type(response) == "string" and #response > 0 then
                return response, "request"
            end
            if type(response) == "table" then
                local body = response.Body or response.body
                local status = tonumber(response.StatusCode or response.Status or response.status_code)
                if type(body) == "string" and #body > 0 and (not status or status < 400) then
                    return body, "request"
                end
                failures[#failures + 1] = "request: HTTP " .. tostring(status or "unknown")
            else
                failures[#failures + 1] = "request: invalid response"
            end
        else
            failures[#failures + 1] = "request: " .. tostring(response)
        end
    else
        failures[#failures + 1] = "request: unavailable"
    end
    return nil, table.concat(failures, " | ")
end

local function buildFallbackUI(reason)
    local old = PlayerGui:FindFirstChild("FNP_Autoplayer_Fallback")
    if old then
        old:Destroy()
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "FNP_Autoplayer_Fallback"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Position = UDim2.fromScale(0.5, 0.5)
    frame.Size = UDim2.fromOffset(420, 245)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(65, 65, 72)
    stroke.Thickness = 1
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(16, 12)
    title.Size = UDim2.new(1, -32, 0, 28)
    title.Font = Enum.Font.GothamBold
    title.Text = "FNP Autoplayer"
    title.TextColor3 = Color3.fromRGB(245, 245, 248)
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Position = UDim2.fromOffset(16, 48)
    status.Size = UDim2.new(1, -32, 0, 92)
    status.Font = Enum.Font.Gotham
    status.TextColor3 = Color3.fromRGB(210, 210, 216)
    status.TextSize = 14
    status.TextWrapped = true
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.Parent = frame

    local reasonLabel = Instance.new("TextLabel")
    reasonLabel.BackgroundTransparency = 1
    reasonLabel.Position = UDim2.fromOffset(16, 143)
    reasonLabel.Size = UDim2.new(1, -32, 0, 42)
    reasonLabel.Font = Enum.Font.Gotham
    reasonLabel.Text = "WindUI unavailable: " .. tostring(reason)
    reasonLabel.TextColor3 = Color3.fromRGB(155, 155, 164)
    reasonLabel.TextSize = 11
    reasonLabel.TextWrapped = true
    reasonLabel.TextXAlignment = Enum.TextXAlignment.Left
    reasonLabel.TextYAlignment = Enum.TextYAlignment.Top
    reasonLabel.Parent = frame

    local toggle = Instance.new("TextButton")
    toggle.Position = UDim2.fromOffset(16, 196)
    toggle.Size = UDim2.new(0.5, -22, 0, 34)
    toggle.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
    toggle.BorderSizePixel = 0
    toggle.Font = Enum.Font.GothamSemibold
    toggle.TextColor3 = Color3.fromRGB(240, 240, 244)
    toggle.TextSize = 14
    toggle.Parent = frame
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggle

    local release = Instance.new("TextButton")
    release.Position = UDim2.new(0.5, 6, 0, 196)
    release.Size = UDim2.new(0.5, -22, 0, 34)
    release.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
    release.BorderSizePixel = 0
    release.Font = Enum.Font.GothamSemibold
    release.Text = "Release lanes"
    release.TextColor3 = Color3.fromRGB(240, 240, 244)
    release.TextSize = 14
    release.Parent = frame
    local releaseCorner = Instance.new("UICorner")
    releaseCorner.CornerRadius = UDim.new(0, 8)
    releaseCorner.Parent = release

    toggle.MouseButton1Click:Connect(function()
        if #state.AvailableInputModes == 0 then
            state.Enabled = false
            return
        end
        state.Enabled = not state.Enabled
        if not state.Enabled then
            releaseAll()
        end
        queueSave()
    end)
    release.MouseButton1Click:Connect(releaseAll)

    state.FallbackGui = gui
    state.FallbackUIConnection = RunService.Heartbeat:Connect(function()
        if state.Destroyed or not gui.Parent then
            return
        end
        toggle.Text = state.Enabled and "Disable autoplayer" or "Enable autoplayer"
        status.Text = string.format(
            "State: %s\nTracking: %s  |  Method: %s\nSide: %s  |  Key mode: %s\nHits: %d  |  Misses: %d\nTracked notes: %d  |  Held lanes: %d",
            state.Enabled and "Enabled" or "Disabled",
            state.ModuleAccessMode,
            state.InputMode,
            state.DetectedSide,
            state.DetectedMode,
            state.Hits,
            state.Misses,
            trackedNoteCount(),
            countTable(state.Pressed)
        )
    end)
end

local function buildUI()
    if not LoadstringFunction then
        error("loadstring is unavailable")
    end
    local source, sourceProvider = fetchText(WINDUI_URL)
    if not source then
        error("WindUI download failed: " .. tostring(sourceProvider))
    end
    local chunk, compileError = LoadstringFunction(source)
    if type(chunk) ~= "function" then
        error("WindUI compile failed: " .. tostring(compileError))
    end
    local runOk, library = pcall(chunk)
    if not runOk or type(library) ~= "table" then
        error("WindUI startup failed: " .. tostring(library))
    end
    WindUI = library
    state.WindUISourceProvider = sourceProvider
    Window = WindUI:CreateWindow({
        Title = "FNP Autoplayer",
        Icon = "music-2",
        Author = "Autoplayer",
        Folder = FOLDER,
        Size = UDim2.fromOffset(state.WindowWidth, state.WindowHeight),
        Transparent = false,
        Theme = state.Theme,
        Resizable = true,
        SideBarWidth = 170,
        HideSearchBar = false,
        ScrollBarEnabled = true
    })
    Window:SetToggleKey(state.WindowKey)
    Window:SetUIScale(state.UIScale)
    Window:SetBackgroundTransparency(state.BackgroundTransparency)
    Window:SetBackgroundImageTransparency(state.BackgroundImageTransparency)

    state.WindUI = WindUI
    state.Window = Window

    local Main = Window:Tab({Title = "Autoplayer", Icon = "play"})
    local Settings = Window:Tab({Title = "Settings", Icon = "settings"})
    local Mapper = Window:Tab({Title = "Keybind Mapper", Icon = "keyboard"})
    local Interface = Window:Tab({Title = "WindUI", Icon = "panel-top"})
    local Advanced = Window:Tab({Title = "Advanced", Icon = "wrench"})

    state.MainTab = Main
    state.SettingsTab = Settings
    state.MapperTab = Mapper
    state.InterfaceTab = Interface
    state.AdvancedTab = Advanced

    local ready = false

    local function pick(value)
        if type(value) == "string" or type(value) == "number" then
            return tostring(value)
        end
        if type(value) == "table" then
            if value.Value ~= nil then
                return tostring(value.Value)
            end
            if value[1] ~= nil then
                return tostring(value[1])
            end
            for key, item in value do
                if item == true then
                    return tostring(key)
                elseif type(key) == "number" then
                    return tostring(item)
                end
            end
        end
        return tostring(value)
    end

    local modeNames = {"4K", "5K", "6K", "7K", "8K", "9K", "12K"}
    local sideModes = {"Auto", "BF", "Dad"}
    local inputModes = #state.AvailableInputModes > 0 and cloneTable(state.AvailableInputModes) or {"Unavailable"}
    local laneValues = {}
    for lane = 1, 12 do
        laneValues[lane] = tostring(lane)
    end
    local keyValues = {
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
        "Space", "Semicolon", "Comma", "Period", "Slash", "BackSlash", "LeftBracket", "RightBracket", "Minus", "Equals", "Quote", "Tab",
        "Left", "Down", "Up", "Right", "LeftShift", "RightShift", "LeftControl", "RightControl"
    }
    local hotkeys = {"Insert", "Home", "End", "PageUp", "PageDown", "RightShift", "RightControl", "LeftControl", "F6", "F7", "F8", "F9", "F10", "F11", "F12"}
    local themes = {"Dark", "Light", "Midnight", "MonokaiPro", "Indigo", "Violet", "Sky", "Emerald", "Amber", "Crimson", "Rose", "CottonCandy", "Mellowsi", "Plant", "Rainbow", "Red"}

    local status = Main:Paragraph({Title = "Runtime", Desc = "Loading runtime state..."})
    local enabledToggle = Main:Toggle({
        Title = "Enabled",
        Desc = "RightShift toggles the autoplayer. Insert opens or closes WindUI.",
        Value = state.Enabled,
        Callback = function(value)
            if not ready then
                return
            end
            state.Enabled = value == true and #state.AvailableInputModes > 0
            if not state.Enabled then
                releaseAll()
            end
            queueSave()
        end
    })
    local modeDropdown = Main:Dropdown({
        Title = "Input method",
        Desc = "Choose how note presses are delivered.",
        Values = inputModes,
        Value = state.InputMode,
        Multi = false,
        AllowNone = false,
        Callback = function(value)
            if not ready then
                return
            end
            local mode = pick(value)
            if table.find(inputModes, mode) then
                setInputMode(mode)
            end
        end
    })
    local sideDropdown = Main:Dropdown({
        Title = "Player side",
        Desc = "Auto detects BF/right or Dad/left from the performing spot, opponent-score layout, and receptor key labels.",
        Values = sideModes,
        Value = state.VisualSide,
        Multi = false,
        AllowNone = false,
        Callback = function(value)
            if not ready then
                return
            end
            local side = pick(value)
            if table.find(sideModes, side) then
                state.VisualSide = side
                state.VisualSideVote = nil
                state.VisualSideVoteCount = 0
                detectVisualSide(true)
                queueSave()
            end
        end
    })
    local backend = Main:Paragraph({Title = "Backend status", Desc = "Loading backend state..."})
    Main:Button({
        Title = "Release held lanes",
        Desc = "Immediately release every key currently held by the autoplayer.",
        Icon = "hand",
        Callback = releaseAll
    })

    Settings:Section({Title = "Timing"})
    Settings:Slider({
        Title = "Hit timing offset",
        Desc = "Negative values hit earlier; positive values hit later.",
        Step = 1,
        Value = {Min = -100, Max = 100, Default = state.TimingOffset},
        Callback = function(value)
            if ready then
                state.TimingOffset = tonumber(value) or 0
                queueSave()
            end
        end
    })
    Settings:Slider({
        Title = "Tap duration",
        Desc = "How long normal notes remain pressed, in milliseconds.",
        Step = 1,
        Value = {Min = 5, Max = 120, Default = state.TapDuration},
        Callback = function(value)
            if ready then
                state.TapDuration = tonumber(value) or 24
                queueSave()
            end
        end
    })
    Settings:Slider({
        Title = "Sustain release buffer",
        Desc = "Extra hold time after the final generated sustain segment.",
        Step = 1,
        Value = {Min = 0, Max = 250, Default = state.SustainBuffer},
        Callback = function(value)
            if ready then
                state.SustainBuffer = tonumber(value) or 80
                queueSave()
            end
        end
    })
    Settings:Section({Title = "Safety and keybinds"})
    Settings:Toggle({
        Title = "Repair missing game binds",
        Desc = "Preserve existing binds and fill only empty lanes for 4K through 12K.",
        Value = state.AutoFillBinds,
        Callback = function(value)
            if ready then
                state.AutoFillBinds = value == true
                if state.AutoFillBinds then
                    fillMissingBinds()
                end
                queueSave()
            end
        end
    })
    Settings:Toggle({
        Title = "Skip harmful notes",
        Desc = "Avoid poison, mine, hurt, death, and similar note types.",
        Value = state.SkipHarmful,
        Callback = function(value)
            if ready then
                state.SkipHarmful = value == true
                queueSave()
            end
        end
    })
    Settings:Dropdown({
        Title = "Autoplayer toggle key",
        Desc = "Separate from the WindUI window key.",
        Values = hotkeys,
        Value = keyName(state.AutoplayerToggleKey),
        Multi = false,
        AllowNone = false,
        Callback = function(value)
            if not ready then
                return
            end
            local key = normalizeKey(pick(value))
            if key then
                if key == state.WindowKey then
                    state.WindowKey = key == Enum.KeyCode.Insert and Enum.KeyCode.Home or Enum.KeyCode.Insert
                    Window:SetToggleKey(state.WindowKey)
                end
                state.AutoplayerToggleKey = key
                queueSave()
            end
        end
    })
    local settingsState = Settings:Paragraph({Title = "Current settings", Desc = "Loading settings..."})
    Settings:Button({
        Title = "Fill missing binds now",
        Desc = "Run the missing-lane repair immediately and save the game settings.",
        Icon = "wrench",
        Callback = function()
            fillMissingBinds()
            saveGameBinds()
            queueSave()
        end
    })
    Settings:Button({
        Title = "Save settings",
        Desc = "Save autoplayer configuration and queue the game keybind save.",
        Icon = "save",
        Callback = function()
            queueSave()
            saveGameBinds()
        end
    })

    local selectedMode = table.find(modeNames, state.SelectedMode) and state.SelectedMode or "4K"
    local selectedLane = 1
    local selectedKey = keyName(getLaneKey(getModeIndex(selectedMode), selectedLane))

    local function laneCount(name)
        return #Layouts[getModeIndex(name)].Keys
    end

    local function layoutText(name)
        local index = getModeIndex(name)
        local items = {}
        for lane = 1, laneCount(name) do
            items[#items + 1] = string.format("%d: %s", lane, keyName(getLaneKey(index, lane)))
        end
        return table.concat(items, "   |   ")
    end

    Mapper:Section({Title = "Dropdown mapper"})
    local mapperParagraph = Mapper:Paragraph({Title = "Current layout", Desc = layoutText(selectedMode)})
    local mapperState = Mapper:Paragraph({Title = "Selection", Desc = string.format("%s lane %d is bound to %s.", selectedMode, selectedLane, selectedKey)})
    Mapper:Dropdown({
        Title = "Key mode",
        Desc = "Choose the chart key count to edit.",
        Values = modeNames,
        Value = selectedMode,
        Multi = false,
        AllowNone = false,
        Callback = function(value)
            if not ready then
                return
            end
            local name = pick(value)
            if table.find(modeNames, name) then
                selectedMode = name
                state.SelectedMode = name
                if selectedLane > laneCount(name) then
                    selectedLane = 1
                end
                mapperParagraph:SetDesc(layoutText(selectedMode))
                mapperState:SetDesc(string.format("%s lane %d is bound to %s. Selected replacement: %s.", selectedMode, selectedLane, keyName(getLaneKey(getModeIndex(selectedMode), selectedLane)), selectedKey))
                queueSave()
            end
        end
    })
    Mapper:Dropdown({
        Title = "Lane",
        Desc = "Choose a lane from the selected key mode.",
        Values = laneValues,
        Value = tostring(selectedLane),
        Multi = false,
        AllowNone = false,
        Callback = function(value)
            if not ready then
                return
            end
            local lane = tonumber(pick(value))
            if lane and lane >= 1 and lane <= laneCount(selectedMode) then
                selectedLane = lane
                mapperState:SetDesc(string.format("%s lane %d is bound to %s. Selected replacement: %s.", selectedMode, selectedLane, keyName(getLaneKey(getModeIndex(selectedMode), selectedLane)), selectedKey))
            else
                mapperState:SetDesc(string.format("%s has %d lanes. Choose a valid lane.", selectedMode, laneCount(selectedMode)))
            end
        end
    })
    Mapper:Dropdown({
        Title = "Replacement key",
        Desc = "Choose the keyboard key to bind to this lane.",
        Values = keyValues,
        Value = selectedKey,
        Multi = false,
        AllowNone = false,
        SearchBarEnabled = true,
        Callback = function(value)
            if not ready then
                return
            end
            local name = pick(value)
            if normalizeKey(name) then
                selectedKey = name
                mapperState:SetDesc(string.format("%s lane %d is bound to %s. Selected replacement: %s.", selectedMode, selectedLane, keyName(getLaneKey(getModeIndex(selectedMode), selectedLane)), selectedKey))
            end
        end
    })
    Mapper:Button({
        Title = "Apply lane bind",
        Desc = "Apply the selected key to the selected lane and save it.",
        Icon = "check",
        Callback = function()
            local key = normalizeKey(selectedKey)
            if key and selectedLane <= laneCount(selectedMode) then
                setLaneKey(getModeIndex(selectedMode), selectedLane, key, true)
                saveGameBinds()
                mapperParagraph:SetDesc(layoutText(selectedMode))
                mapperState:SetDesc(string.format("Applied %s to %s lane %d.", selectedKey, selectedMode, selectedLane))
            end
        end
    })
    Mapper:Button({
        Title = "Reset selected mode",
        Desc = "Restore the standard layout for the selected key mode.",
        Icon = "rotate-ccw",
        Callback = function()
            resetModeBinds(getModeIndex(selectedMode))
            saveGameBinds()
            mapperParagraph:SetDesc(layoutText(selectedMode))
            mapperState:SetDesc(string.format("Reset the complete %s layout.", selectedMode))
        end
    })
    Mapper:Button({
        Title = "Repair all missing lanes",
        Desc = "Fill only empty lanes across every supported key mode.",
        Icon = "wand-sparkles",
        Callback = function()
            fillMissingBinds()
            saveGameBinds()
            mapperParagraph:SetDesc(layoutText(selectedMode))
            mapperState:SetDesc("Filled every missing lane while preserving existing bindings.")
        end
    })

    Interface:Section({Title = "Window"})
    Interface:Dropdown({
        Title = "WindUI window key",
        Desc = "Opens and closes WindUI without toggling the autoplayer.",
        Values = hotkeys,
        Value = keyName(state.WindowKey),
        Multi = false,
        AllowNone = false,
        Callback = function(value)
            if not ready then
                return
            end
            local key = normalizeKey(pick(value))
            if key then
                if key == state.AutoplayerToggleKey then
                    state.AutoplayerToggleKey = key == Enum.KeyCode.RightShift and Enum.KeyCode.RightControl or Enum.KeyCode.RightShift
                end
                state.WindowKey = key
                Window:SetToggleKey(key)
                queueSave()
            end
        end
    })
    Interface:Dropdown({
        Title = "Theme",
        Desc = "Change the WindUI color theme.",
        Values = themes,
        Value = state.Theme,
        Multi = false,
        AllowNone = false,
        Callback = function(value)
            if not ready then
                return
            end
            local theme = pick(value)
            if table.find(themes, theme) then
                state.Theme = theme
                pcall(WindUI.SetTheme, WindUI, theme)
                queueSave()
            end
        end
    })
    Interface:Slider({
        Title = "UI scale",
        Desc = "Scale the complete WindUI interface.",
        Step = 0.05,
        Value = {Min = 0.65, Max = 1.4, Default = state.UIScale},
        Callback = function(value)
            if ready then
                state.UIScale = tonumber(value) or 1
                Window:SetUIScale(state.UIScale)
                queueSave()
            end
        end
    })
    Interface:Slider({
        Title = "Window width",
        Desc = "Resize the main window width.",
        Step = 10,
        Value = {Min = 480, Max = 1000, Default = state.WindowWidth},
        Callback = function(value)
            if ready then
                state.WindowWidth = math.floor(tonumber(value) or 640)
                Window:SetSize(UDim2.fromOffset(state.WindowWidth, state.WindowHeight))
                queueSave()
            end
        end
    })
    Interface:Slider({
        Title = "Window height",
        Desc = "Resize the main window height.",
        Step = 10,
        Value = {Min = 360, Max = 800, Default = state.WindowHeight},
        Callback = function(value)
            if ready then
                state.WindowHeight = math.floor(tonumber(value) or 500)
                Window:SetSize(UDim2.fromOffset(state.WindowWidth, state.WindowHeight))
                queueSave()
            end
        end
    })
    Interface:Slider({
        Title = "Background transparency",
        Desc = "Adjust the main WindUI background transparency.",
        Step = 0.05,
        Value = {Min = 0, Max = 0.9, Default = state.BackgroundTransparency},
        Callback = function(value)
            if ready then
                state.BackgroundTransparency = tonumber(value) or 0.15
                Window:SetBackgroundTransparency(state.BackgroundTransparency)
                queueSave()
            end
        end
    })
    Interface:Slider({
        Title = "Background image transparency",
        Desc = "Adjust the optional background-image layer.",
        Step = 0.05,
        Value = {Min = 0, Max = 1, Default = state.BackgroundImageTransparency},
        Callback = function(value)
            if ready then
                state.BackgroundImageTransparency = tonumber(value) or 0
                Window:SetBackgroundImageTransparency(state.BackgroundImageTransparency)
                queueSave()
            end
        end
    })
    Interface:Button({
        Title = "Center window",
        Desc = "Move WindUI back to the center of the screen.",
        Icon = "move",
        Callback = function()
            Window:SetToTheCenter()
        end
    })
    Interface:Button({
        Title = "Reset interface",
        Desc = "Restore Insert, Dark theme, 100% scale, default size, and default transparency.",
        Icon = "rotate-ccw",
        Callback = function()
            state.WindowKey = Enum.KeyCode.Insert
            state.Theme = "Dark"
            state.UIScale = 1
            state.WindowWidth = 640
            state.WindowHeight = 500
            state.BackgroundTransparency = 0.15
            state.BackgroundImageTransparency = 0
            Window:SetToggleKey(state.WindowKey)
            pcall(WindUI.SetTheme, WindUI, state.Theme)
            Window:SetUIScale(state.UIScale)
            Window:SetSize(UDim2.fromOffset(state.WindowWidth, state.WindowHeight))
            Window:SetBackgroundTransparency(state.BackgroundTransparency)
            Window:SetBackgroundImageTransparency(state.BackgroundImageTransparency)
            Window:SetToTheCenter()
            queueSave()
        end
    })

    Advanced:Section({Title = "Backends and diagnostics"})
    local diagnostics = Advanced:Paragraph({Title = "Diagnostics", Desc = "Loading diagnostics..."})
    Advanced:Paragraph({
        Title = "Backend details",
        Desc = "Live mode wraps the game modules. Visual mode detects the local BF/right or Dad/left container, counts its receptors, and tracks its notes without require."
    })
    Advanced:Button({
        Title = "Resolve getgc functions now",
        Desc = "Perform one closure scan and cache CheckInput and Goodhit.",
        Icon = "scan-search",
        Callback = function()
            resolveGetGC(true)
        end
    })
    Advanced:Button({
        Title = "Clear WindUI popups",
        Desc = "Remove any currently visible WindUI popup or notification cards.",
        Icon = "x",
        Callback = function()
            local robloxGui = CoreGui:FindFirstChild("RobloxGui")
            local gui = robloxGui and robloxGui:FindFirstChild("WindUI")
            local popups = gui and gui:FindFirstChild("Popups")
            if popups then
                for _, child in popups:GetChildren() do
                    child:Destroy()
                end
            end
        end
    })
    Advanced:Button({
        Title = "Save everything",
        Desc = "Save the autoplayer config and the game keybind table.",
        Icon = "save-all",
        Callback = function()
            queueSave()
            saveGameBinds()
        end
    })
    Advanced:Button({
        Title = "Destroy autoplayer",
        Desc = "Release held lanes, restore wrapped functions, destroy WindUI, and disconnect every listener.",
        Icon = "trash-2",
        Callback = function()
            state.Destroy()
        end
    })

    state.StatusParagraph = status
    state.BackendParagraph = backend
    state.SettingsParagraph = settingsState
    state.DiagnosticsParagraph = diagnostics
    state.EnabledToggle = enabledToggle
    state.ModeDropdown = modeDropdown
    state.SideDropdown = sideDropdown

    ready = true
    state.UIReady = true
    state.UIBuildVersion = 11

    local lastUpdate = 0
    state.WindUIUpdateConnection = RunService.Heartbeat:Connect(function()
        if state.Destroyed then
            return
        end
        local now = os.clock()
        if now - lastUpdate < 0.25 then
            return
        end
        lastUpdate = now
        withIdentity8(function()
            local chartName = state.DetectedMode or (state.CurrentMania and Layouts[state.CurrentMania + 1] and Layouts[state.CurrentMania + 1].Name) or "Idle"
            status:SetDesc(string.format(
                "State: %s\nSide: %s  |  Key mode: %s\nHits: %d  |  Misses: %d\nTracked notes: %d  |  Held lanes: %d\nAccuracy: %s",
                state.Enabled and "Enabled" or "Disabled",
                state.DetectedSide,
                chartName,
                state.Hits,
                state.Misses,
                trackedNoteCount(),
                countTable(state.Pressed),
                getAccuracy()
            ))
            backend:SetDesc(string.format(
                "Tracking: %s\nMethod: %s\nSide detector: %s\nGameSettings: %s\nVirtualInputManager: %s\nfiresignal: %s\ngetgc cache: %s",
                state.ModuleAccessMode,
                state.InputMode,
                state.DetectedSideMethod,
                ReconstructedGameSettingsStatus,
                state.VirtualInput and state.VirtualInput.ClassName or "Unavailable",
                BackendAvailability.firesignal and "Available" or "Unavailable",
                type(state.GCGoodhit) == "function" and "Resolved" or "Not resolved"
            ))
            settingsState:SetDesc(string.format(
                "Autoplayer key: %s\nWindow key: %s\nTiming: %+d ms  |  Tap: %d ms  |  Sustain buffer: %d ms\nMissing-bind repair: %s  |  Harmful-note filter: %s",
                keyName(state.AutoplayerToggleKey),
                keyName(state.WindowKey),
                state.TimingOffset,
                state.TapDuration,
                state.SustainBuffer,
                state.AutoFillBinds and "On" or "Off",
                state.SkipHarmful and "On" or "Off"
            ))
            diagnostics:SetDesc(string.format(
                "Core version: %d  |  UI build: %d\nRuntime connections: %d\nStale key-capture listeners removed: %d\nModule failures: %d\nWorkspace file: FNP_Autoplayer.luau",
                state.Version,
                state.UIBuildVersion,
                #state.Connections,
                state.StaleInputListenersRemoved or 0,
                #state.ModuleDiagnostics
            ))
        end)
    end)
end

local function destroy()
    if state.Destroyed then
        return
    end
    state.Destroyed = true
    releaseAll()
    queueSave()
    if wrappedSpawn and OriginalSpawn and NoteModule.SpawnNote == wrappedSpawn then
        NoteModule.SpawnNote = OriginalSpawn
    end
    if originalIsBindPressed and HookFunction and type(UserInputBindables.IsBindPressed) == "function" then
        pcall(HookFunction, UserInputBindables.IsBindPressed, originalIsBindPressed)
    end
    for _, connection in state.Connections do
        pcall(function()
            connection:Disconnect()
        end)
    end
    for _, connection in state.ContainerConnections do
        pcall(function()
            connection:Disconnect()
        end)
    end
    if state.WindUIUpdateConnection then
        pcall(function()
            state.WindUIUpdateConnection:Disconnect()
        end)
    end
    if state.FallbackUIConnection then
        pcall(function()
            state.FallbackUIConnection:Disconnect()
        end)
    end
    if state.FallbackGui then
        pcall(function()
            state.FallbackGui:Destroy()
        end)
    end
    local oldGui
    local robloxGui = CoreGui:FindFirstChild("RobloxGui")
    if robloxGui then
        oldGui = robloxGui:FindFirstChild("WindUI")
    end
    cleanupOrphanedWindUIInputs(oldGui, state.Window)
    if state.Window then
        withIdentity8(function()
            state.Window:Destroy()
        end)
    elseif oldGui then
        pcall(function()
            oldGui:Destroy()
        end)
    end
    if VirtualInputManager and VirtualInputOwned then
        pcall(function()
            VirtualInputManager:Destroy()
        end)
    end
    if env.FNP_AutoPlayer == state then
        env.FNP_AutoPlayer = nil
    end
end

state.Destroy = destroy

local ok, errorMessage = pcall(buildUI)
if not ok then
    warn("[FNP Autoplayer] WindUI failed:", errorMessage)
    local fallbackOk, fallbackError = pcall(buildFallbackUI, errorMessage)
    if not fallbackOk then
        showFatalCompatibility("UI initialization failed", tostring(errorMessage) .. "\n\nFallback UI: " .. tostring(fallbackError))
    end
end

queueSave()
