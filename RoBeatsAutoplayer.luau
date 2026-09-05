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
local HasInternalDiscovery = type(getconnections) == "function"
    and type(debug) == "table"
    and type(debug.getupvalue) == "function"
    and type(debug.getconstants) == "function"
local IsExternalExecutor = not HasInternalDiscovery

local ExternalVIMCompensationMs = IsExternalExecutor and HasVirtualInput and 75 or 0

local InputModes = {}
if HasVirtualInput then
    InputModes[#InputModes + 1] = "Virtual Input"
end
if HasFireSignal and HasInternalDiscovery then
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

local DefaultInputMode = (IsMobile and HasFireSignal and HasInternalDiscovery) and "firesignal" or InputModes[1]

local st = {
    buildTag = "dynamic-runtime-discovery-v10",
    external = IsExternalExecutor,
    alive = true,
    enabled = true,
    mode = DefaultInputMode,
    offset = 0,
    vimCompensationMs = IsExternalExecutor and ExternalVIMCompensationMs or (IsMobile and -20 or -10),
    tapMs = 35,
    services = nil,
    game = nil,
    slot = nil,
    noteList = nil,
    pressFunction = nil,
    releaseFunction = nil,
    slotResolverFunction = nil,
    audioResolverFunction = nil,
    audioManager = nil,
    audioTrackFunction = nil,
    audioPreFunction = nil,
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
    externalChart = nil,
    externalChartSource = nil,
    externalChartCapturedAt = 0,
    externalSongKey = nil,
    externalSound = nil,
    externalSoundScanAt = 0,
    externalRemoteConnections = {},
    externalChartVersion = 0,
    externalLastSound = nil,
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

local function isTrackSystem(value)
    return type(value) == "table"
        and type(value.get_active_note_display_mode) == "function"
        and type(value.tracksystem_update_all_active_notes_display_mode) == "function"
end

local function getLocalSlot(currentGame)
    if not currentGame then
        return nil
    end

    if type(st.slotResolverFunction) == "function" then
        local ok, slot = pcall(st.slotResolverFunction, currentGame)
        if ok and isTrackSystem(slot) then
            return slot
        end
        st.slotResolverFunction = nil
    end

    for key, fn in pairs(currentGame) do
        if type(key) == "string" and key:sub(1, 1) == "_" and type(fn) == "function" then
            local ok, slot = pcall(fn, currentGame)
            if ok and isTrackSystem(slot) then
                st.slotResolverFunction = fn
                return slot
            end
        end
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

local function findSlotInputFunctions(slot)
    if not slot then
        return nil, nil
    end

    if type(st.pressFunction) == "function" and type(st.releaseFunction) == "function" then
        return st.pressFunction, st.releaseFunction
    end

    for _, fn in pairs(slot) do
        if type(fn) == "function" then
            if not st.pressFunction and constantsContain(fn, "press") then
                st.pressFunction = fn
            end
            if not st.releaseFunction and constantsContain(fn, "release") then
                st.releaseFunction = fn
            end
        end
    end

    return st.pressFunction, st.releaseFunction
end

local function noteListFromFunction(fn)
    if type(fn) ~= "function" then
        return nil
    end

    for i = 1, 24 do
        local ok, value = pcall(debug.getupvalue, fn, i)
        if not ok or value == nil then
            break
        end

        if type(value) == "table" and type(value.count) == "function" and type(value.get) == "function" then
            local okCount, count = pcall(value.count, value)
            if okCount and type(count) == "number" and count > 0 then
                local okFirst, first = pcall(value.get, value, 1)
                if okFirst and isNoteObject(first) then
                    return value
                end
            end
        end
    end

    return nil
end

local function findNoteList(slot)
    if not slot or type(debug) ~= "table" or type(debug.getupvalue) ~= "function" then
        return nil
    end

    findSlotInputFunctions(slot)

    for _, fn in pairs(slot) do
        if type(fn) == "function" then
            local value = noteListFromFunction(fn)
            if value then
                st.noteList = value
                return value
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

for lane = 1, 4 do
    st.laneKeys[lane] = fallbackKeys[lane]
end

local function refreshLaneKeys()
    local input = st.input
    if not input then
        if st.external then
            for lane = 1, 4 do
                st.laneKeys[lane] = st.laneKeys[lane] or fallbackKeys[lane]
            end
            st.lastKeyRefresh = os.clock()
        end
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

local function setExternalLaneKey(lane, value)
    if not st.external or type(lane) ~= "number" then
        return false
    end
    local text = tostring(value or ""):gsub("%s+", "")
    if text == "" then
        st.laneKeys[lane] = fallbackKeys[lane]
        return true
    end
    local key
    pcall(function()
        key = Enum.KeyCode[text]
    end)
    if not key then
        local upper = text:upper()
        pcall(function()
            key = Enum.KeyCode[upper]
        end)
    end
    if key then
        st.laneKeys[lane] = key
        return true
    end
    return false
end

st.Bridge = Instance.new("BindableEvent")
st.Bridge.Name = "RoBeatsAutoplayerInputBridge"
st.BridgeConnection = st.Bridge.Event:Connect(function(lane, down)
    local slot = st.slot
    local currentGame = st.game
    if not slot or not currentGame or type(lane) ~= "number" then
        return
    end

    local press, release = findSlotInputFunctions(slot)
    if down then
        if type(press) == "function" then
            pcall(press, slot, currentGame, lane)
        end
    else
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


local function queryByClass(root, className)
    local ok, result = pcall(function()
        if type(root.QueryDescendants) == "function" then
            return root:QueryDescendants(className)
        end
    end)
    if ok and type(result) == "table" then
        return result
    end

    local fallback = {}
    local okDesc, descendants = pcall(root.GetDescendants, root)
    if okDesc and type(descendants) == "table" then
        for _, item in ipairs(descendants) do
            if item:IsA(className) then
                fallback[#fallback + 1] = item
            end
        end
    end
    return fallback
end

local releaseAll

local function normalizeExternalChart(candidate, sourceName)
    if type(candidate) ~= "table" then
        return nil
    end

    local raw = candidate.HitObjects
    local compressed = false
    if type(raw) ~= "table" then
        raw = candidate.Notes
        compressed = type(raw) == "table"
    end
    if type(raw) ~= "table" then
        return nil
    end

    local notes = {}
    for _, item in pairs(raw) do
        if type(item) == "table" then
            local track
            local hitTime
            local duration
            local noteType

            if compressed then
                track = tonumber(item[1])
                hitTime = tonumber(item[2])
                duration = tonumber(item[3])
                noteType = duration and duration > 0 and 2 or 1
            else
                track = tonumber(item.Track)
                hitTime = tonumber(item.Time)
                duration = tonumber(item.Duration)
                noteType = tonumber(item.Type) or (duration and duration > 0 and 2 or 1)
            end

            if track and track >= 1 and track <= 4 and hitTime and hitTime >= -5000 then
                notes[#notes + 1] = {
                    Track = track,
                    Time = hitTime,
                    Duration = duration and duration > 0 and duration or nil,
                    Type = noteType,
                }
            end
        end
    end

    if #notes < 8 then
        return nil
    end

    table.sort(notes, function(a, b)
        if a.Time == b.Time then
            return a.Track < b.Track
        end
        return a.Time < b.Time
    end)

    return {
        Notes = notes,
        Source = sourceName or "RemoteEvent",
        FirstTime = notes[1].Time,
        LastTime = notes[#notes].Time + (notes[#notes].Duration or 0),
    }
end

local function commitExternalChart(chart)
    if not chart or type(chart.Notes) ~= "table" then
        return
    end

    local current = st.externalChart
    if current and #current.Notes > #chart.Notes and os.clock() - st.externalChartCapturedAt < 3 then
        return
    end

    releaseAll()
    table.clear(st.seen)
    st.externalChart = chart
    st.externalChartSource = chart.Source
    st.externalChartCapturedAt = os.clock()
    st.externalChartVersion += 1
    st.externalSound = nil
    st.externalLastSound = nil
    st.status = string.format("External chart captured (%d notes)", #chart.Notes)
end

local function scanExternalPayload(value, sourceName, depth, visited, best)
    if depth > 7 or type(value) ~= "table" or visited[value] then
        return best
    end
    visited[value] = true

    local chart = normalizeExternalChart(value, sourceName)
    if chart and (not best or #chart.Notes > #best.Notes) then
        best = chart
    end

    for key, child in pairs(value) do
        local keyText = tostring(key)
        if (keyText == "RequestedSongKey" or keyText == "SongKey") and type(child) == "number" and child > 0 then
            if keyText == "RequestedSongKey" or st.externalSongKey == nil then
                st.externalSongKey = child
            end
        end
        if type(child) == "table" then
            best = scanExternalPayload(child, sourceName, depth + 1, visited, best)
        end
    end

    return best
end

local function attachExternalRemoteCapture()
    if not st.external then
        return
    end

    for _, connection in ipairs(st.externalRemoteConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(st.externalRemoteConnections)

    local remoteEvents = queryByClass(game:GetService("ReplicatedStorage"), "RemoteEvent")
    for _, remote in ipairs(remoteEvents) do
        local connection = remote.OnClientEvent:Connect(function(...)
            local args = table.pack(...)
            local best
            local visited = {}
            for i = 1, args.n do
                if type(args[i]) == "table" then
                    best = scanExternalPayload(args[i], remote:GetFullName(), 0, visited, best)
                end
            end
            if best then
                commitExternalChart(best)
            end
        end)
        st.externalRemoteConnections[#st.externalRemoteConnections + 1] = connection
    end
end

local function findExternalSongSound()
    local cached = st.externalSound
    if cached and cached.Parent and cached.IsPlaying then
        return cached
    end

    if os.clock() - st.externalSoundScanAt < 0.35 then
        return nil
    end
    st.externalSoundScanAt = os.clock()

    local expectedLength = st.externalChart and st.externalChart.LastTime and st.externalChart.LastTime / 1000 or nil
    local best
    local bestScore = math.huge

    for _, sound in ipairs(queryByClass(game:GetService("Workspace"), "Sound")) do
        local okPlaying, playing = pcall(function()
            return sound.IsPlaying
        end)
        if okPlaying and playing then
            local timeLength = 0
            local timePosition = 0
            local rolloff = 0
            pcall(function()
                timeLength = sound.TimeLength
                timePosition = sound.TimePosition
                rolloff = sound.RollOffMaxDistance
            end)

            if timePosition >= 0 and (timeLength > 20 or rolloff >= 1000) then
                local score
                if expectedLength and timeLength > 0 then
                    score = math.abs(timeLength - expectedLength)
                else
                    score = -(timeLength + math.min(rolloff, 10000) / 10000)
                end

                if not best or score < bestScore then
                    best = sound
                    bestScore = score
                end
            end
        end
    end

    if best then
        st.externalSound = best
    end
    return best
end

local function isAudioManager(value)
    return type(value) == "table"
        and type(value.get_audio_time_offset_ms) == "function"
        and type(value.get_bgm) == "function"
        and type(value.get_pre_start_time_ms) == "function"
        and type(value.get_song_length_ms) == "function"
end

local function getAudioManager()
    local currentGame = st.game
    if not currentGame then
        return nil
    end

    if isAudioManager(st.audioManager) then
        return st.audioManager
    end

    if type(st.audioResolverFunction) == "function" then
        local ok, audio = pcall(st.audioResolverFunction, currentGame)
        if ok and isAudioManager(audio) then
            st.audioManager = audio
            return audio
        end
        st.audioResolverFunction = nil
    end

    for key, fn in pairs(currentGame) do
        if type(key) == "string" and key:sub(1, 1) == "_" and type(fn) == "function" then
            local ok, audio = pcall(fn, currentGame)
            if ok and isAudioManager(audio) then
                st.audioResolverFunction = fn
                st.audioManager = audio
                return audio
            end
        end
    end

    return nil
end

local function getAudioClockFunctions(audio)
    if type(st.audioTrackFunction) == "function" and type(st.audioPreFunction) == "function" then
        return st.audioTrackFunction, st.audioPreFunction
    end

    local numericPrivate = {}
    for key, fn in pairs(audio) do
        if type(key) == "string" and key:sub(1, 1) == "_" and type(fn) == "function" then
            local okValue, value = pcall(fn, audio)
            if okValue and type(value) == "number" then
                numericPrivate[#numericPrivate + 1] = fn

                if type(debug) == "table" and type(debug.getupvalue) == "function" then
                    local ok1, up1 = pcall(debug.getupvalue, fn, 1)
                    if ok1 and type(up1) == "number" and not st.audioTrackFunction then
                        st.audioTrackFunction = fn
                    elseif ok1 and rawequal(up1, audio) and not st.audioPreFunction then
                        st.audioPreFunction = fn
                    end
                end
            end
        end
    end

    st.audioTrackFunction = st.audioTrackFunction or numericPrivate[1]
    if not st.audioPreFunction then
        for _, fn in ipairs(numericPrivate) do
            if fn ~= st.audioTrackFunction then
                st.audioPreFunction = fn
                break
            end
        end
    end
    st.audioPreFunction = st.audioPreFunction or st.audioTrackFunction

    return st.audioTrackFunction, st.audioPreFunction
end

local function getTrackTimeMs()
    if st.external then
        local sound = findExternalSongSound()
        if not sound then
            return nil
        end
        local ok, timePosition = pcall(function()
            return sound.TimePosition
        end)
        if ok and type(timePosition) == "number" then
            return timePosition * 1000
        end
        return nil
    end

    local audio = getAudioManager()
    if not audio then
        return nil
    end

    local trackFn = getAudioClockFunctions(audio)
    if type(trackFn) == "function" then
        local ok, value = pcall(trackFn, audio)
        if ok and type(value) == "number" then
            return value
        end
    end

    local okBgm, bgm = pcall(audio.get_bgm, audio)
    if okBgm and typeof(bgm) == "Instance" and bgm:IsA("Sound") then
        local okTime, timePosition = pcall(function()
            return bgm.TimePosition
        end)
        if okTime and type(timePosition) == "number" then
            return timePosition * 1000
        end
    end

    return nil
end

local function getPreStartClockOffsetMs()
    if st.external then
        return 0
    end
    local audio = getAudioManager()
    if not audio then
        return 0
    end

    local trackFn, preFn = getAudioClockFunctions(audio)
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

releaseAll = function()
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
    st.releaseFunction = nil
    st.slotResolverFunction = nil
    st.audioResolverFunction = nil
    st.audioManager = nil
    st.audioTrackFunction = nil
    st.audioPreFunction = nil
    st.input = currentGame and currentGame._input or nil
    st.lastKeyRefresh = 0

    if currentGame then
        st.slot = getLocalSlot(currentGame)
        refreshLaneKeys()
    end
end

local function updateInternalAutoplayer()
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
                            playSeq(Holder, {
                                Index = noteIndex,
                                Lane = lane,
                                HitTime = hitTime,
                                TailHitTime = tailHitTime,
                                TailClockOffset = getPreStartClockOffsetMs(),
                                TargetOffsetMs = targetOffset,
                                Key = noteKey,
                                Generation = generation,
                            }, keyCode, {
                                enabled = true,
                                tapMs = st.tapMs,
                                relMs = AutoCtx.relMs,
                                maxHold = AutoCtx.maxHold,
                                laneDown = st.laneDown,
                                laneCount = st.laneCount,
                                press = AutoCtx.press,
                                release = AutoCtx.release,
                            })
                        end
                    end
                end
            end
        end
    end
end

local function updateExternalAutoplayer()
    if not st.enabled then
        st.status = "Paused"
        releaseAll()
        return
    end

    local chart = st.externalChart
    if not chart or type(chart.Notes) ~= "table" then
        st.status = "External - waiting for chart (start a song)"
        return
    end

    local currentMs = getTrackTimeMs()
    if type(currentMs) ~= "number" then
        st.status = "External - waiting for BGM"
        return
    end

    local sound = st.externalSound
    if sound ~= st.externalLastSound then
        releaseAll()
        table.clear(st.seen)
        st.externalLastSound = sound
    end

    st.status = string.format("Playing - External Virtual Input (%d notes)", #chart.Notes)
    local targetOffset = (tonumber(st.offset) or 0) + st.vimCompensationMs
    local generation = st.sequenceGeneration
    local lookAheadMs = 2500

    for index, note in ipairs(chart.Notes) do
        local hitTime = note.Time
        if hitTime > currentMs + lookAheadMs then
            break
        end
        if hitTime >= currentMs - 90 then
            local lane = note.Track
            local noteKey = string.format("ext|%d|%.3f|%d", lane, hitTime, index)
            if not st.seen[noteKey] then
                st.seen[noteKey] = true
                local Holder = st.laneHolders[lane]
                local keyCode = st.laneKeys[lane]
                if Holder and keyCode then
                    playSeq(Holder, {
                        Index = index,
                        Lane = lane,
                        HitTime = hitTime,
                        TailHitTime = note.Duration and (hitTime + note.Duration) or nil,
                        TailClockOffset = 0,
                        TargetOffsetMs = targetOffset,
                        Key = noteKey,
                        Generation = generation,
                    }, keyCode, {
                        enabled = true,
                        tapMs = st.tapMs,
                        relMs = AutoCtx.relMs,
                        maxHold = AutoCtx.maxHold,
                        laneDown = st.laneDown,
                        laneCount = st.laneCount,
                        press = AutoCtx.press,
                        release = AutoCtx.release,
                    })
                end
            end
        end
    end
end

local function updateAutoplayer()
    if not st.alive then
        return
    end
    if st.external then
        updateExternalAutoplayer()
    else
        updateInternalAutoplayer()
    end
end

function st:Rebind()
    releaseAll()
    table.clear(self.seen)
    if self.external then
        self.externalChart = nil
        self.externalChartSource = nil
        self.externalSound = nil
        self.externalLastSound = nil
        attachExternalRemoteCapture()
        self.status = "External - waiting for chart (start a song)"
        return
    end
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

    for _, connection in ipairs(self.externalRemoteConnections or {}) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(self.externalRemoteConnections or {})

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
if type(VibeUI.Config) == "table" then
    VibeUI.Config.MobileToggle = true
end

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

if #InputModes > 1 then
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
else
    Playback:Paragraph({
        Name = "Input Mode",
        Content = "",
    })
    if st.external then
        Playback:Paragraph({
            Name = "External Calibration",
            Content = "",
        })
    end
end

Playback:Slider({
    Name = "Fine Offset (+ later / - earlier)",
    Flag = "RoBeats_TimingOffset",
    Min = -100,
    Max = 100,
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
    Content = "",
})

if st.external then
    for lane = 1, 4 do
        Playback:Textbox({
            Name = "Track " .. lane .. " key",
            Flag = "RoBeats_ExternalKey_" .. lane,
            Default = fallbackKeys[lane].Name,
            Finished = true,
            Callback = function(value)
                setExternalLaneKey(lane, value)
            end,
        })
    end
end

local Runtime = Main:Section({
    Name = "Runtime",
    Side = 2,
})

Runtime:Paragraph({
    Name = "Playtest",
    Content = "",
})

Runtime:Paragraph({
    Name = "Input behavior",
    Content = "",
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

if st.external then
    attachExternalRemoteCapture()
    st.status = "External - waiting for chart (start a song)"
else
    findLocalServices()
end
st.UpdateConnection = RunService.RenderStepped:Connect(updateAutoplayer)

VibeUI:Notification({
    Title = "RoBeats Autoplayer",
    Description = st.external and "External backend armed. Start a song to capture its chart." or "Per-note playSeq autoplayer loaded.",
    Type = "success",
    Duration = 4,
})
