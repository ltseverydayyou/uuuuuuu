local ENV = (getgenv and getgenv()) or _G

if type(ENV.__RoBeatsAuto) == "table" and type(ENV.__RoBeatsAuto.Unload) == "function" then
    pcall(function()
        ENV.__RoBeatsAuto:Unload()
    end)
end

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

local clone = type(cloneref) == "function" and cloneref or function(v)
    return v
end

local Players = __lt.cs("Players", clone)
local RunService = __lt.cs("RunService", clone)
local UserInputService = __lt.cs("UserInputService", clone)
local VirtualInputManager = __lt.cs("VirtualInputManager", clone)

local LocalPlayer = Players.LocalPlayer
local HasFireSignal = type(firesignal) == "function"
local HasVirtualInput = VirtualInputManager ~= nil

local InputModes = {}
if HasVirtualInput then
    InputModes[#InputModes + 1] = "Virtual Input"
end
if HasFireSignal then
    InputModes[#InputModes + 1] = "firesignal"
end
if #InputModes == 0 then
    error("No supported input mode available")
end

local IsMobile = false
pcall(function()
    local platform = UserInputService:GetPlatform()
    IsMobile = platform == Enum.Platform.IOS
        or platform == Enum.Platform.Android
        or platform == Enum.Platform.AndroidTV
        or platform == Enum.Platform.Chromecast
        or platform == Enum.Platform.MetaOS
end)
if not IsMobile then
    IsMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

local DefaultInputMode = (IsMobile and HasFireSignal) and "firesignal" or InputModes[1]

local st = {
    buildTag = "dual-backend-playseq-v6",
    alive = true,
    enabled = true,
    mode = DefaultInputMode,
    offset = 0,
    vimCompensationMs = IsMobile and -20 or -10,
    tapMs = 35,
    services = nil,
    game = nil,
    slot = nil,
    noteList = nil,
    pressFunction = nil,
    input = nil,
    laneKeys = {},
    laneHolders = {},
    laneDown = {},
    laneCount = {},
    seen = {},
    lastKeyRefresh = 0,
    status = "Starting",
    attempts = 0,
    sequenceGeneration = 0,
    debugPresses = {},
    debugReleases = {},
    VibeUI = nil,
    UpdateConnection = nil,
    Bridge = nil,
    BridgeConnection = nil,
}

ENV.__RoBeatsAuto = st

local function findLocalServices()
    if st.services then
        return st.services
    end
    if type(getconnections) ~= "function" or type(debug) ~= "table" or type(debug.getupvalue) ~= "function" then
        return nil
    end

    local visited = {}
    local function scanFunction(fn, depth)
        if depth > 4 or visited[fn] then
            return nil
        end
        visited[fn] = true

        for i = 1, 40 do
            local ok, value = pcall(debug.getupvalue, fn, i)
            if not ok or value == nil then
                break
            end

            if type(value) == "table"
                and type(rawget(value, "local_services_copy")) == "function"
                and rawget(value, "_game_join") ~= nil
                and rawget(value, "_input") ~= nil then
                return value
            end

            if type(value) == "function" then
                local found = scanFunction(value, depth + 1)
                if found then
                    return found
                end
            end
        end

        return nil
    end

    local ok, connections = pcall(getconnections, RunService.Heartbeat)
    if not ok or type(connections) ~= "table" then
        return nil
    end

    for _, connection in ipairs(connections) do
        local fn = connection.Function
        if type(fn) == "function" then
            local found = scanFunction(fn, 0)
            if found then
                st.services = found
                return found
            end
        end
    end

    return nil
end

local function getCurrentGame()
    local services = findLocalServices()
    if not services or not services._game_join then
        return nil
    end

    local current
    pcall(function()
        current = services._game_join:get_game()
    end)
    return current
end

local function getLocalSlot(currentGame)
    if not currentGame then
        return nil
    end

    local fn = currentGame._3MkXorqP8choIVYMa5JJ
    if type(fn) ~= "function" then
        return nil
    end

    local ok, slot = pcall(fn, currentGame)
    if ok and type(slot) == "table" then
        return slot
    end

    return nil
end

local function constantsContain(fn, wanted)
    if type(debug) ~= "table" or type(debug.getconstants) ~= "function" then
        return false
    end

    local ok, constants = pcall(debug.getconstants, fn)
    if not ok or type(constants) ~= "table" then
        return false
    end

    for _, value in ipairs(constants) do
        if value == wanted then
            return true
        end
    end

    return false
end

local function isNoteObject(value)
    return type(value) == "table"
        and type(value.get_delta_time_from_hit_time) == "function"
        and type(value.get_track_index) == "function"
        and type(value.get_note_index) == "function"
        and type(value.get_state) == "function"
end

local function findNoteList(slot)
    if not slot or type(debug) ~= "table" or type(debug.getupvalue) ~= "function" then
        return nil
    end

    if st.pressFunction then
        for i = 1, 16 do
            local ok, value = pcall(debug.getupvalue, st.pressFunction, i)
            if not ok or value == nil then
                break
            end

            if type(value) == "table" and type(value.count) == "function" and type(value.get) == "function" then
                local okCount, count = pcall(value.count, value)
                if okCount and count > 0 then
                    local okFirst, first = pcall(value.get, value, 1)
                    if okFirst and isNoteObject(first) then
                        st.noteList = value
                        return value
                    end
                end
            end
        end
    end

    for _, fn in pairs(slot) do
        if type(fn) == "function" and constantsContain(fn, "press") then
            for i = 1, 16 do
                local ok, value = pcall(debug.getupvalue, fn, i)
                if not ok or value == nil then
                    break
                end

                if type(value) == "table" and type(value.count) == "function" and type(value.get) == "function" then
                    local okCount, count = pcall(value.count, value)
                    if okCount and count > 0 then
                        local okFirst, first = pcall(value.get, value, 1)
                        if okFirst and isNoteObject(first) then
                            st.pressFunction = fn
                            st.noteList = value
                            return value
                        end
                    end
                end
            end
        end
    end

    return nil
end

local trackControlIds = IsMobile and {2, 3, 0, 1} or {0, 1, 2, 3}
local fallbackKeys = IsMobile and {
    Enum.KeyCode.J,
    Enum.KeyCode.K,
    Enum.KeyCode.D,
    Enum.KeyCode.F,
} or {
    Enum.KeyCode.D,
    Enum.KeyCode.F,
    Enum.KeyCode.J,
    Enum.KeyCode.K,
}

local function refreshLaneKeys()
    local input = st.input
    if not input then
        return
    end

    for lane = 1, 4 do
        local key
        local controlId = trackControlIds[lane]
        if type(input.get_custom_key_keycode) == "function" then
            pcall(function()
                key = input:get_custom_key_keycode(controlId)
            end)
        end
        st.laneKeys[lane] = key or fallbackKeys[lane]
    end

    st.lastKeyRefresh = os.clock()
end

st.Bridge = Instance.new("BindableEvent")
st.Bridge.Name = "RoBeatsAutoplayerInputBridge"
st.BridgeConnection = st.Bridge.Event:Connect(function(lane, down)
    local slot = st.slot
    local currentGame = st.game
    if not slot or not currentGame or type(lane) ~= "number" then
        return
    end

    if down then
        local press = slot._kr2nQnuij4fHyYHwtYxj
        if type(press) == "function" then
            pcall(press, slot, currentGame, lane)
        end
    else
        local release = slot._zSKGj4zY7YYAZ471PQSa
        if type(release) == "function" then
            pcall(release, slot, currentGame, lane)
        end
    end
end)

local function sendLane(lane, keyCode, down)
    if type(lane) ~= "number" or not keyCode then
        return false
    end

    if st.mode == "firesignal" then
        if not HasFireSignal or not st.Bridge then
            return false
        end
        return pcall(firesignal, st.Bridge.Event, lane, down)
    end

    if not HasVirtualInput then
        return false
    end

    return pcall(function()
        VirtualInputManager:SendKeyEvent(down, keyCode, false, game)
    end)
end

local function getAudioManager()
    local currentGame = st.game
    if not currentGame or type(currentGame._qXGQXwqL9SzcZAiaQtmu) ~= "function" then
        return nil
    end
    local ok, audio = pcall(currentGame._qXGQXwqL9SzcZAiaQtmu, currentGame)
    return ok and type(audio) == "table" and audio or nil
end

local function getTrackTimeMs()
    local audio = getAudioManager()
    if not audio then
        return nil
    end
    local fn = audio._kcHOjddK0oxsHBsscsMV
    if type(fn) ~= "function" then
        fn = audio._1aeaJt0hbKst8XoaDZ17
    end
    if type(fn) ~= "function" then
        return nil
    end
    local ok, value = pcall(fn, audio)
    return ok and type(value) == "number" and value or nil
end

local function getPreStartClockOffsetMs()
    local audio = getAudioManager()
    if not audio then
        return 0
    end
    local trackFn = audio._kcHOjddK0oxsHBsscsMV
    local preFn = audio._1aeaJt0hbKst8XoaDZ17
    if type(trackFn) ~= "function" or type(preFn) ~= "function" then
        return 0
    end
    local okTrack, trackTime = pcall(trackFn, audio)
    local okPre, preTime = pcall(preFn, audio)
    if okTrack and okPre and type(trackTime) == "number" and type(preTime) == "number" then
        local diff = preTime - trackTime
        if math.abs(diff) < 10000 then
            return diff
        end
    end
    return 0
end

for lane = 1, 4 do
    st.laneHolders[lane] = {Name = lane}
end

local function releaseAll()
    st.sequenceGeneration += 1
    for lane = 1, 4 do
        local Holder = st.laneHolders[lane]
        local keyCode = st.laneKeys[lane]
        if Holder and st.laneDown[Holder] and keyCode then
            sendLane(lane, keyCode, false)
        end
        if Holder then
            st.laneDown[Holder] = false
            st.laneCount[Holder] = 0
        end
    end
end

local AutoCtx = {
    enabled = true,
    tapMs = st.tapMs,
    relMs = 0,
    holdTick = 0.005,
    maxHold = 30,
    laneDown = st.laneDown,
    laneCount = st.laneCount,
    press = function(lane, keyCode)
        local ok = sendLane(lane, keyCode, true)
        if ok then
            st.attempts += 1
        end
        return ok
    end,
    release = function(lane, keyCode)
        return sendLane(lane, keyCode, false)
    end,
}

local function waitUntilTrackTime(targetMs, generation)
    local currentMs = getTrackTimeMs()
    if type(currentMs) ~= "number" then
        return nil
    end

    local coarseMs = targetMs - currentMs - 40
    if coarseMs > 0 then
        task.wait(coarseMs / 1000)
    end

    while st.alive and st.enabled and st.sequenceGeneration == generation do
        currentMs = getTrackTimeMs()
        if type(currentMs) ~= "number" then
            return nil
        end
        if currentMs >= targetMs then
            return currentMs
        end
        RunService.RenderStepped:Wait()
    end

    return nil
end

local function playSeq(Holder, Arrow, keyCode, AutoCtx)
    task.spawn(function()
        local generation = Arrow.Generation
        local targetHitMs = Arrow.HitTime + Arrow.TargetOffsetMs
        local currentMs = waitUntilTrackTime(targetHitMs, generation)
        if type(currentMs) ~= "number" then
            return
        end

        if not AutoCtx.enabled or not st.alive or not st.enabled or st.sequenceGeneration ~= generation then
            return
        end

        st.debugPresses[#st.debugPresses + 1] = {
            index = Arrow.Index,
            lane = Arrow.Lane,
            delta = currentMs - Arrow.HitTime,
            targetDelta = currentMs - targetHitMs,
            songTime = currentMs,
            hitTime = Arrow.HitTime,
            tailHitTime = Arrow.TailHitTime,
            key = Arrow.Key,
            mode = st.mode,
        }
        if #st.debugPresses > 120 then
            table.remove(st.debugPresses, 1)
        end

        if AutoCtx.laneDown[Holder] then
            AutoCtx.release(Holder.Name, keyCode)
        end

        AutoCtx.press(Holder.Name, keyCode)
        AutoCtx.laneDown[Holder] = true
        AutoCtx.laneCount[Holder] = (AutoCtx.laneCount[Holder] or 0) + 1

        local rawTailHitTime = tonumber(Arrow.TailHitTime)
        local tailHitTime = rawTailHitTime and (rawTailHitTime - (Arrow.TailClockOffset or 0)) or nil
        local isHold = tailHitTime and tailHitTime > Arrow.HitTime + 1

        if isHold then
            local targetTailMs = tailHitTime + Arrow.TargetOffsetMs
            local untilTime = os.clock() + math.max(0.05, AutoCtx.maxHold or 8)
            local tailNow = getTrackTimeMs()
            if type(tailNow) == "number" then
                local coarseMs = targetTailMs - tailNow - 40
                if coarseMs > 0 then
                    task.wait(coarseMs / 1000)
                end
            end
            while st.alive and st.enabled and st.sequenceGeneration == generation and os.clock() <= untilTime do
                tailNow = getTrackTimeMs()
                if type(tailNow) ~= "number" or tailNow >= targetTailMs then
                    break
                end
                RunService.RenderStepped:Wait()
            end
            st.debugReleases[#st.debugReleases + 1] = {
                index = Arrow.Index,
                lane = Arrow.Lane,
                target = targetTailMs,
                actual = tailNow,
                delta = type(tailNow) == "number" and tailNow - targetTailMs or nil,
                hold = true,
                mode = st.mode,
            }
            if #st.debugReleases > 120 then
                table.remove(st.debugReleases, 1)
            end
        else
            task.wait(math.max(0, AutoCtx.tapMs or 35) / 1000)
        end

        if AutoCtx.relMs and AutoCtx.relMs > 0 then
            task.wait(AutoCtx.relMs / 1000)
        end

        if st.sequenceGeneration ~= generation then
            return
        end

        AutoCtx.laneCount[Holder] = math.max((AutoCtx.laneCount[Holder] or 1) - 1, 0)
        if AutoCtx.laneCount[Holder] <= 0 then
            AutoCtx.laneCount[Holder] = 0
            if AutoCtx.laneDown[Holder] then
                AutoCtx.release(Holder.Name, keyCode)
                AutoCtx.laneDown[Holder] = false
            end
        end
    end)
end

local function resetRuntime(currentGame)
    releaseAll()
    table.clear(st.seen)
    st.game = currentGame
    st.slot = nil
    st.noteList = nil
    st.pressFunction = nil
    st.input = currentGame and currentGame._input or nil
    st.lastKeyRefresh = 0

    if currentGame then
        st.slot = getLocalSlot(currentGame)
        refreshLaneKeys()
    end
end

local function updateAutoplayer()
    if not st.alive then
        return
    end

    local currentGame = getCurrentGame()
    if currentGame ~= st.game then
        resetRuntime(currentGame)
    end

    if not currentGame then
        st.status = "Waiting for song"
        return
    end

    st.input = currentGame._input or st.input
    if not st.input then
        st.status = "Waiting for input"
        return
    end

    if os.clock() - st.lastKeyRefresh >= 1 then
        refreshLaneKeys()
    end

    if not st.slot then
        st.slot = getLocalSlot(currentGame)
    end
    if not st.slot then
        st.status = "Waiting for local track"
        return
    end

    local notes = st.noteList or findNoteList(st.slot)
    if not notes then
        st.status = "Waiting for notes"
        return
    end

    st.status = st.enabled and ("Playing - " .. st.mode) or "Paused"
    if not st.enabled then
        releaseAll()
        return
    end

    local okCount, count = pcall(notes.count, notes)
    if not okCount then
        st.noteList = nil
        return
    end

    local currentMs = getTrackTimeMs()
    if type(currentMs) ~= "number" then
        return
    end

    local modeOffset = st.mode == "Virtual Input" and st.vimCompensationMs or 0
    local targetOffset = (tonumber(st.offset) or 0) + modeOffset
    local generation = st.sequenceGeneration

    for i = 1, count do
        local okNote, note = pcall(notes.get, notes, i)
        if okNote and isNoteObject(note) then
            local okState, noteState = pcall(note.get_state, note)
            if okState and noteState == 0 then
                local okIndex, noteIndex = pcall(note.get_note_index, note)
                local okDelta, delta = pcall(note.get_delta_time_from_hit_time, note)
                local okLane, lane = pcall(note.get_track_index, note)
                if okIndex and noteIndex ~= nil and okDelta and type(delta) == "number" and okLane and type(lane) == "number" and lane >= 1 and lane <= 4 then
                    local hitTime = currentMs - delta
                    local noteKey = string.format("%d|%.3f|%s", lane, hitTime, tostring(noteIndex))
                    if not st.seen[noteKey] then
                        st.seen[noteKey] = true

                        local tailHitTime
                        if type(note.get_tail_hit_time) == "function" then
                            local okTail, value = pcall(note.get_tail_hit_time, note)
                            if okTail and type(value) == "number" then
                                tailHitTime = value
                            end
                        end

                        local Holder = st.laneHolders[lane]
                        local keyCode = st.laneKeys[lane]
                        if Holder and keyCode then
                            local Arrow = {
                                Index = noteIndex,
                                Lane = lane,
                                HitTime = hitTime,
                                TailHitTime = tailHitTime,
                                TailClockOffset = getPreStartClockOffsetMs(),
                                TargetOffsetMs = targetOffset,
                                Key = noteKey,
                                Generation = generation,
                            }
                            local NoteCtx = {
                                enabled = true,
                                tapMs = st.tapMs,
                                relMs = AutoCtx.relMs,
                                maxHold = AutoCtx.maxHold,
                                laneDown = st.laneDown,
                                laneCount = st.laneCount,
                                press = AutoCtx.press,
                                release = AutoCtx.release,
                            }
                            playSeq(Holder, Arrow, keyCode, NoteCtx)
                        end
                    end
                end
            end
        end
    end
end

function st:Rebind()
    self.services = nil
    resetRuntime(nil)
    findLocalServices()
end

function st:Unload()
    if not self.alive then
        return
    end

    self.alive = false
    self.enabled = false
    releaseAll()

    if self.UpdateConnection then
        pcall(function()
            self.UpdateConnection:Disconnect()
        end)
        self.UpdateConnection = nil
    end

    if self.BridgeConnection then
        pcall(function()
            self.BridgeConnection:Disconnect()
        end)
        self.BridgeConnection = nil
    end

    if self.Bridge then
        pcall(function()
            self.Bridge:Destroy()
        end)
        self.Bridge = nil
    end

    if self.VibeUI then
        pcall(function()
            self.VibeUI:Unload()
        end)
    end

    if ENV.__RoBeatsAuto == self then
        ENV.__RoBeatsAuto = nil
    end
end

local VibeUI = loadstring(game:HttpGet("https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"))()
st.VibeUI = VibeUI
VibeUI.Config.MobileToggle = true

local Window = VibeUI:Window({
    Title = "RoBeats Autoplayer",
    Size = UDim2.fromOffset(660, 430),
    Keybind = Enum.KeyCode.RightControl,
    Layout = "Side",
    Resizable = true,
})

local Main = Window:Tab({
    Name = "Autoplayer",
    Columns = 2,
})

local Playback = Main:Section({
    Name = "Playback",
    Side = 1,
})

Playback:Toggle({
    Name = "Autoplay",
    Flag = "RoBeats_Autoplay",
    Default = true,
    Callback = function(value)
        st.enabled = value == true
        if not st.enabled then
            releaseAll()
        end
    end,
})

Playback:Dropdown({
    Name = "Input Mode",
    Flag = "RoBeats_InputMode",
    Items = InputModes,
    Default = DefaultInputMode,
    Callback = function(value)
        if table.find(InputModes, value) then
            releaseAll()
            st.mode = value
            table.clear(st.seen)
        end
    end,
})

Playback:Slider({
    Name = "Timing Offset",
    Flag = "RoBeats_TimingOffset",
    Min = -50,
    Max = 50,
    Default = 0,
    Decimals = 1,
    Suffix = "ms",
    Callback = function(value)
        st.offset = tonumber(value) or 0
    end,
})

Playback:Slider({
    Name = "Tap Duration",
    Flag = "RoBeats_TapDuration",
    Min = 10,
    Max = 80,
    Default = 35,
    Decimals = 1,
    Suffix = "ms",
    Callback = function(value)
        st.tapMs = math.clamp(tonumber(value) or 35, 5, 150)
    end,
})

Playback:Paragraph({
    Name = "Keybinds",
    Content = "Uses RoBeats' KEY_TRACK mapping and live custom bindings. Track order is resolved per platform/client mapping, and custom binds refresh while the script runs.",
})

local Runtime = Main:Section({
    Name = "Runtime",
    Side = 2,
})

Runtime:Paragraph({
    Name = "Playtest",
    Content = "Virtual Input uses RoBeats' platform-specific track mapping with backend latency compensation. firesignal uses RoBeats' native track dispatcher. Both share per-note playSeq scheduling.",
})

Runtime:Paragraph({
    Name = "Input behavior",
    Content = "Virtual Input sends real key events with a mobile-only timing compensation. firesignal triggers RoBeats' native track press/release path. Long-note tails are converted from the pre-start clock before release.",
})

local RebindButton = Runtime:Button()
RebindButton:Add("Rebind Runtime", function()
    st:Rebind()
    VibeUI:Notification({
        Title = "RoBeats Autoplayer",
        Description = "Runtime and live keybinds rebound.",
        Type = "success",
        Duration = 3,
    })
end)

local UnloadButton = Runtime:Button()
UnloadButton:Add("Unload", function()
    st:Unload()
end)

VibeUI:CreateSettingsPage(Window)

findLocalServices()
st.UpdateConnection = RunService.RenderStepped:Connect(updateAutoplayer)

VibeUI:Notification({
    Title = "RoBeats Autoplayer",
    Description = "Per-note playSeq autoplayer loaded.",
    Type = "success",
    Duration = 4,
})
