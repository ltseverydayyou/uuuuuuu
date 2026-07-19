local env = getgenv()

if env.FNP_AutoPlayer and type(env.FNP_AutoPlayer.Destroy) == "function" then
    pcall(env.FNP_AutoPlayer.Destroy)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local NoteModule = require(Modules:WaitForChild("Note"))
local Conductor = require(Modules:WaitForChild("Conductor"))
local GameSettings = require(Modules:WaitForChild("GameSettings"))
local UserInputBindables = require(Modules:WaitForChild("UserInputBindables"))

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
    if type(isfile) == "function" and isfile(SETTINGS_PATH) then
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(SETTINGS_PATH))
        end)
        if ok and type(decoded) == "table" then
            for key, value in decoded do
                settings[key] = value
            end
        end
    end
    return settings
end

if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(FOLDER) then
    makefolder(FOLDER)
end

local Config = loadSettings()

local state = {
    Version = 10,
    Enabled = Config.Enabled ~= false,
    InputMode = table.find({"Virtual Input", "firesignal", "getgc"}, Config.InputMode) and Config.InputMode or "Virtual Input",
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
            Keybinds = keybinds
        }
        if type(writefile) == "function" then
            pcall(writefile, SETTINGS_PATH, HttpService:JSONEncode(payload))
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
    local configured = state.ConfigKeybinds[Layouts[index].Name]
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
    return Layouts[index].Keys[lane]
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

local VirtualInputManager = Instance.new("VirtualInputManager")
state.VirtualInput = VirtualInputManager

local originalIsBindPressed
if type(hookfunction) == "function" and type(UserInputBindables.IsBindPressed) == "function" then
    local wrapper
    wrapper = function(name)
        if state and not state.Destroyed and state.InputMode == "firesignal" and state.FireHeld[name] then
            return true
        end
        return originalIsBindPressed(name)
    end
    local ok, original = pcall(hookfunction, UserInputBindables.IsBindPressed, wrapper)
    if ok and type(original) == "function" then
        originalIsBindPressed = original
        state.OriginalIsBindPressed = original
    end
end

local function withIdentity8(callback)
    local oldIdentity
    if type(getthreadidentity) == "function" and type(setthreadidentity) == "function" then
        oldIdentity = getthreadidentity()
        pcall(setthreadidentity, 8)
    end
    local ok, result = pcall(callback)
    if oldIdentity then
        pcall(setthreadidentity, oldIdentity)
    end
    return ok, result
end

local function sendVirtual(key, down)
    return withIdentity8(function()
        VirtualInputManager:SendKeyEvent(down, key, false, game)
    end)
end

local function sendFireSignal(lane, down)
    local bindName = "Direction" .. lane
    state.FireHeld[bindName] = down or nil
    if type(firesignal) ~= "function" then
        return false
    end
    local signal = down and UserInputBindables.InputEvents.Began or UserInputBindables.InputEvents.Ended
    return pcall(firesignal, signal, bindName, nil, false)
end

local function resolveGetGC(force)
    if not force and os.clock() - state.LastGCResolve < 1 and type(state.GCGoodhit) == "function" then
        return true
    end
    state.LastGCResolve = os.clock()
    state.GCGoodhit = nil
    state.GCCheckInput = nil
    if type(getgc) ~= "function" then
        return false
    end
    local ok, objects = pcall(getgc, true)
    if not ok or type(objects) ~= "table" then
        return false
    end
    for _, object in objects do
        if type(object) == "function" then
            local name
            pcall(function()
                name = debug.info(object, "n")
            end)
            if name == "Goodhit" then
                state.GCGoodhit = object
            elseif name == "CheckInput" then
                state.GCCheckInput = object
            elseif name == "checkHeldKeys" and type(debug.getupvalues) == "function" then
                local upvalues = debug.getupvalues(object)
                local notes = type(upvalues) == "table" and upvalues[2]
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
    if not table.find({"Virtual Input", "firesignal", "getgc"}, mode) then
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

local OriginalSpawn = NoteModule.SpawnNote
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

local function wrappedSpawn(note)
    local result = OriginalSpawn(note)
    if result then
        trackNote(note)
    end
    return result
end

state.WrappedSpawn = wrappedSpawn
NoteModule.SpawnNote = wrappedSpawn

local function removeGui(gui)
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

local function connectContainer(container)
    if state.ConnectedContainers[container] then
        return
    end
    state.ConnectedContainers[container] = true
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
    if instance:IsA("GuiObject") and (instance.Name == "BFNotes" or instance.Name == "DadNotes") then
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
    removeGui(instance)
end)

if type(getgc) == "function" then
    resolveGetGC(true)
end

local function getAccuracy()
    local handler = rawget(shared, "handler")
    if type(handler) == "table" and type(handler.PlayerStats) == "table" and type(handler.PlayerStats.Accuracy) == "number" then
        return string.format("%.2f%%", handler.PlayerStats.Accuracy)
    end
    return "N/A"
end

local function processNotes(deltaTime)
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
    if type(getconnections) == "function" then
        for _, signal in {UserInputService.InputBegan, UserInputService.InputEnded, UserInputService.InputChanged} do
            local ok, connections = pcall(getconnections, signal)
            if ok then
                for _, connection in connections do
                    local fn = connection.Function
                    local remove = false
                    if type(fn) == "function" and type(debug.getupvalues) == "function" then
                        local okUps, upvalues = pcall(debug.getupvalues, fn)
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

local function buildUI()
    local source = game:HttpGet(WINDUI_URL)
    WindUI = loadstring(source)()
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
    local inputModes = {"Virtual Input", "firesignal", "getgc"}
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
            state.Enabled = value == true
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
        Desc = "Virtual Input uses VirtualInputManager. firesignal drives UserInputBindables directly. getgc resolves the game input closures once and reuses them."
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

    ready = true
    state.UIReady = true
    state.UIBuildVersion = 8

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
            local chartName = state.CurrentMania and Layouts[state.CurrentMania + 1] and Layouts[state.CurrentMania + 1].Name or "Idle"
            status:SetDesc(string.format(
                "State: %s\nHits: %d  |  Misses: %d\nTracked notes: %d  |  Held lanes: %d\nChart mode: %s  |  Accuracy: %s",
                state.Enabled and "Enabled" or "Disabled",
                state.Hits,
                state.Misses,
                countTable(state.Active),
                countTable(state.Pressed),
                chartName,
                getAccuracy()
            ))
            backend:SetDesc(string.format(
                "Method: %s\nVirtualInputManager: %s\nfiresignal: %s\ngetgc cache: %s",
                state.InputMode,
                state.VirtualInput and state.VirtualInput.ClassName or "Unavailable",
                type(firesignal) == "function" and "Available" or "Unavailable",
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
                "Core version: %d  |  UI build: %d\nRuntime connections: %d\nStale key-capture listeners removed: %d\nWorkspace file: FNP_Autoplayer.luau",
                state.Version,
                state.UIBuildVersion,
                #state.Connections,
                state.StaleInputListenersRemoved or 0
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
    if NoteModule.SpawnNote == wrappedSpawn then
        NoteModule.SpawnNote = OriginalSpawn
    end
    if originalIsBindPressed and type(hookfunction) == "function" then
        pcall(hookfunction, UserInputBindables.IsBindPressed, originalIsBindPressed)
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
    if VirtualInputManager then
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
end

queueSave()
