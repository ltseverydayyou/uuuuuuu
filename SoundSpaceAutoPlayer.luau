local S = {
    Players = game:GetService("Players"),
    ReplicatedFirst = game:GetService("ReplicatedFirst"),
    RunService = game:GetService("RunService"),
    Environment = getgenv(),
    Settings = {
        Enabled = false,
        AutoMode = "Perfect",
        Movement = "Snap",
        AimLead = 0.35,
        Smoothness = 28,
        EmergencySnap = 0.055,
        LockInput = true,
        ReturnToCenter = false,
        RestoreCursor = true,
    },
    Runtime = {
        Destroyed = false,
        Run = nil,
        Target = nil,
        SavedPosition = nil,
        InputOwned = false,
        OriginalInputEnabled = nil,
        LastStatus = "",
        LastUiUpdate = 0,
        LastPerfectCount = 0,
    },
    UI = {},
}

if game.PlaceId ~= 2677609345 then
    error("Sound Space Auto Player only supports place 2677609345")
end

S.LocalPlayer = S.Players.LocalPlayer
S.BindPre = "SoundSpaceAutoPlayer_Pre_" .. tostring(S.LocalPlayer.UserId)
S.BindPost = "SoundSpaceAutoPlayer_Post_" .. tostring(S.LocalPlayer.UserId)

S.Previous = rawget(S.Environment, "SoundSpaceAutoPlayer")
if type(S.Previous) == "table" and type(S.Previous.Destroy) == "function" then
    pcall(S.Previous.Destroy)
end

S.GameManager = require(
    S.ReplicatedFirst
        :WaitForChild("Modules")
        :WaitForChild("GameManager")
)

S.VibeUI = loadstring(game:HttpGet(
    "https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"
))()

S.Controller = {}
S.Environment.SoundSpaceAutoPlayer = S.Controller

function S.Notify(title, description, kind)
    pcall(function()
        S.VibeUI:Notification({
            Title = title,
            Description = description,
            Type = kind or "info",
            Duration = 4,
        })
    end)
end

function S.GetInput()
    return S.GameManager and S.GameManager.Input
end

function S.GetRun()
    return S.GameManager and S.GameManager._run
end

function S.IsRunReady(run)
    return run
        and run.Running
        and not run._spectating
        and not run._awaitEnd
        and not run._isPaused
        and run._canUpdate
        and run._synced
end

function S.GetLogicalPosition(note)
    if not note then
        return nil
    end

    local y = tonumber(note.Y)
    local z = tonumber(note.Z)

    if not y or not z then
        return nil
    end

    return Vector3.new(
        0,
        math.clamp(y * 2 + 1, 0.2625000000000002, 5.7375),
        math.clamp(z * 2 - 2, -2.7375, 2.7375)
    )
end

function S.GetAdjustedTime(run)
    local source = run._isPaused and run._spacebarDown and run.Preview or run.Music
    local now = 0

    if source and type(source.GetTime) == "function" then
        local ok, value = pcall(source.GetTime, source)
        if ok then
            now = tonumber(value) or 0
        end
    end

    return now - ((tonumber(run._noteOffset) or 0) + (tonumber(run._noteOffsetInternal) or 0)) / 1000
end

function S.GetTimeToContact(run, note, adjustedTime)
    local scrollSpeed = math.max(0.001, math.abs(tonumber(run._scrollSpeed) or 50))
    local halfWidth = run._mods and run._mods.HardMode and 0.5 or 0.875
    local centerDelta = (tonumber(note.Time) or math.huge)
        - adjustedTime
        + (tonumber(run._musicDelay) or 0)

    return centerDelta - halfWidth / scrollSpeed
end

function S.IsSpawnedNote(run, note)
    if not note or run._processed[note] then
        return false
    end

    local cube = note.Cube
    return typeof(cube) == "Instance"
        and cube:IsA("BasePart")
        and cube.Parent ~= nil
        and run._spawned[cube] == note
end

function S.GetFirstPending(run, requireLead)
    local notes = run._notes
    local spawned = run._spawned
    local processed = run._processed

    if type(notes) ~= "table" or type(spawned) ~= "table" or type(processed) ~= "table" then
        return nil, nil
    end

    local first = math.max(1, tonumber(run._noteIndex) or 1)
    local last = math.min(#notes, tonumber(run._noteIndexLast) or #notes)
    local adjustedTime = S.GetAdjustedTime(run)

    for index = first, math.min(last, first + 31) do
        local note = notes[index]

        if note and not processed[note] then
            if S.IsSpawnedNote(run, note) then
                local timeToContact = S.GetTimeToContact(run, note, adjustedTime)

                if not requireLead or timeToContact <= S.Settings.AimLead then
                    return note, timeToContact
                end

                return nil, timeToContact
            end

            return nil, nil
        end
    end

    return nil, nil
end

function S.WriteCursor(position)
    local input = S.GetInput()
    if not input or not position then
        return
    end

    input._pos = position
    input._posClamped = position

    local run = S.GetRun()
    if run and run.Cursor and run.Cursor.Parent then
        run.Cursor.CFrame = CFrame.new(position)
    elseif input.Cursor and input.Cursor.Parent then
        input.Cursor.CFrame = CFrame.new(position)
    end
end

function S.CaptureCursor()
    if S.Runtime.SavedPosition then
        return
    end

    local input = S.GetInput()
    if not input then
        return
    end

    S.Runtime.SavedPosition = input._posClamped or input._pos or Vector3.new(0, 3, 0)
end

function S.AcquireInput()
    if S.Runtime.InputOwned or not S.Settings.LockInput then
        return
    end

    local input = S.GetInput()
    if not input then
        return
    end

    S.Runtime.OriginalInputEnabled = input._enabled ~= false
    S.Runtime.InputOwned = true

    if type(input.Disable) == "function" then
        pcall(input.Disable, input)
    else
        input._enabled = false
    end
end

function S.ReleaseInput()
    if not S.Runtime.InputOwned then
        return
    end

    local input = S.GetInput()
    S.Runtime.InputOwned = false

    if not input then
        S.Runtime.OriginalInputEnabled = nil
        return
    end

    if S.Runtime.OriginalInputEnabled then
        if type(input.Enable) == "function" then
            pcall(input.Enable, input)
        else
            input._enabled = true
        end
    else
        if type(input.Disable) == "function" then
            pcall(input.Disable, input)
        else
            input._enabled = false
        end
    end

    S.Runtime.OriginalInputEnabled = nil
end

function S.RestoreCursor()
    local saved = S.Runtime.SavedPosition
    S.Runtime.SavedPosition = nil

    if S.Settings.RestoreCursor and saved then
        S.WriteCursor(saved)
    end
end

function S.SetStatus(text)
    if S.Runtime.LastStatus == text then
        return
    end

    S.Runtime.LastStatus = text

    local label = S.UI.StatusLabel
    if label and type(label.Set) == "function" then
        pcall(label.Set, label, "Status: " .. text)
    end
end

function S.ResetTarget()
    S.Runtime.Target = nil
end

function S.DisableRuntime(restore)
    S.Settings.Enabled = false
    S.ResetTarget()
    S.ReleaseInput()

    if restore then
        S.RestoreCursor()
    else
        S.Runtime.SavedPosition = nil
    end

    S.SetStatus("Disabled")
end

function S.EnableRuntime()
    S.CaptureCursor()
    S.AcquireInput()
    S.ResetTarget()
    S.SetStatus("Waiting for a run")
end

function S.MoveToward(position, deltaTime, timeToContact)
    local input = S.GetInput()
    if not input then
        return
    end

    if S.Settings.Movement == "Snap" or (timeToContact and timeToContact <= S.Settings.EmergencySnap) then
        S.WriteCursor(position)
        return
    end

    local current = input._posClamped or input._pos or Vector3.new(0, 3, 0)
    local alpha = math.clamp(
        1 - math.exp(-math.max(1, S.Settings.Smoothness) * math.max(deltaTime, 0)),
        0,
        1
    )

    S.WriteCursor(current:Lerp(position, alpha))
end

function S.ReturnCursor(deltaTime)
    if not S.Settings.ReturnToCenter then
        return
    end

    S.MoveToward(Vector3.new(0, 3, 0), deltaTime, nil)
end

function S.PreRender(deltaTime)
    if S.Runtime.Destroyed then
        return
    end

    if not S.Settings.Enabled then
        return
    end

    local run = S.GetRun()

    if run ~= S.Runtime.Run then
        S.Runtime.Run = run
        S.ResetTarget()
    end

    if S.Settings.LockInput then
        S.AcquireInput()
    else
        S.ReleaseInput()
    end

    if not run or not run.Running then
        S.SetStatus("Waiting for a run")
        S.ReturnCursor(deltaTime)
        return
    end

    if run._spectating then
        S.SetStatus("Spectating")
        S.ResetTarget()
        return
    end

    if run._isPaused then
        S.SetStatus("Paused")
        return
    end

    if not S.IsRunReady(run) then
        S.SetStatus("Waiting for map sync")
        return
    end

    local note, timeToContact = S.GetFirstPending(run, true)

    if not note then
        S.ResetTarget()
        S.SetStatus("Active - waiting for next note")
        S.ReturnCursor(deltaTime)
        return
    end

    local position = S.GetLogicalPosition(note)
    if not position then
        S.SetStatus("Active - invalid note data")
        return
    end

    S.Runtime.Target = note
    S.MoveToward(position, deltaTime, timeToContact)
    S.SetStatus("Active - tracking")
end

function S.PerfectPass(run)
    if S.Settings.AutoMode ~= "Perfect" or not S.IsRunReady(run) then
        return 0
    end

    local hitCount = 0

    for _ = 1, 16 do
        local note, timeToContact = S.GetFirstPending(run, false)

        if not note or not timeToContact or timeToContact > 0 then
            break
        end

        local position = S.GetLogicalPosition(note)
        if position then
            S.WriteCursor(position)
        end

        local before = run._processed[note] == true
        local ok = pcall(function()
            run:_onTouch(note, false)
        end)
        local after = run._processed[note] == true

        if not ok or before or not after then
            break
        end

        hitCount += 1
    end

    return hitCount
end

function S.UpdateStats(run)
    local now = os.clock()
    if now - S.Runtime.LastUiUpdate < 0.2 then
        return
    end

    S.Runtime.LastUiUpdate = now

    local stats = S.UI.StatsLabel
    if not stats or type(stats.Set) ~= "function" then
        return
    end

    if not run or not run.Running then
        pcall(stats.Set, stats, "Run: idle")
        return
    end

    local hits = tonumber(run._hit) or 0
    local misses = tonumber(run._missed) or 0
    local combo = tonumber(run._combo) or 0
    local total = hits + misses
    local accuracy = total > 0 and hits / total * 100 or 100

    pcall(stats.Set, stats, ("Hits: %d | Misses: %d | Combo: %d | %.2f%%"):format(
        hits,
        misses,
        combo,
        accuracy
    ))
end

function S.PostRender()
    if S.Runtime.Destroyed or not S.Settings.Enabled then
        return
    end

    local run = S.GetRun()
    if not run then
        S.UpdateStats(nil)
        return
    end

    S.Runtime.LastPerfectCount = S.PerfectPass(run)
    S.UpdateStats(run)
end

function S.ShowState()
    local run = S.GetRun()

    if not run or not run.Running then
        S.Notify("Current State", "No active run.", "info")
        return
    end

    local note, timeToContact = S.GetFirstPending(run, false)
    local text = ("Hits %d | Misses %d | Combo %d"):format(
        tonumber(run._hit) or 0,
        tonumber(run._missed) or 0,
        tonumber(run._combo) or 0
    )

    if note and timeToContact then
        text ..= (" | Next #%s in %.3fs"):format(
            tostring(note.NoteIndex or "?"),
            timeToContact
        )
    end

    S.Notify("Current State", text, "info")
end

function S.Controller.Destroy()
    if S.Runtime.Destroyed then
        return
    end

    S.Runtime.Destroyed = true
    S.Settings.Enabled = false

    pcall(S.RunService.UnbindFromRenderStep, S.RunService, S.BindPre)
    pcall(S.RunService.UnbindFromRenderStep, S.RunService, S.BindPost)

    S.ReleaseInput()
    S.RestoreCursor()

    pcall(function()
        S.VibeUI:Unload()
    end)

    if rawget(S.Environment, "SoundSpaceAutoPlayer") == S.Controller then
        S.Environment.SoundSpaceAutoPlayer = nil
    end
end

S.RunService:BindToRenderStep(
    S.BindPre,
    Enum.RenderPriority.Camera.Value,
    S.PreRender
)

S.RunService:BindToRenderStep(
    S.BindPost,
    Enum.RenderPriority.Camera.Value + 2,
    S.PostRender
)

S.ViewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(720, 520)
S.WindowWidth = math.max(420, math.min(720, S.ViewportSize.X - 32))
S.WindowHeight = math.max(340, math.min(520, S.ViewportSize.Y - 32))

S.UI.Window = S.VibeUI:Window({
    Title = "Sound Space Auto Player",
    Size = UDim2.fromOffset(S.WindowWidth, S.WindowHeight),
    Keybind = Enum.KeyCode.RightControl,
})

S.UI.AutoTab = S.UI.Window:Tab({ Name = "Auto Player", Columns = 2 })
S.UI.Main = S.UI.AutoTab:Section({ Name = "Main", Side = 1 })
S.UI.Behavior = S.UI.AutoTab:Section({ Name = "Behavior", Side = 2 })
S.UI.RuntimeSection = S.UI.AutoTab:Section({ Name = "Runtime", Side = 2 })

S.UI.Main:Toggle({
    Name = "Enable Auto Player",
    Flag = "SoundSpaceEnabled",
    Default = false,
    Info = "Runs only while a Sound Space map is active.",
    Callback = function(value)
        S.Settings.Enabled = value == true

        if S.Settings.Enabled then
            S.EnableRuntime()
            S.Notify("Auto Player", "Enabled.", "success")
        else
            S.DisableRuntime(true)
            S.Notify("Auto Player", "Disabled.", "info")
        end
    end,
})

S.UI.Main:Dropdown({
    Name = "Auto Mode",
    Flag = "SoundSpaceAutoMode",
    Items = { "Perfect", "Cursor" },
    Default = "Perfect",
    Callback = function(value)
        if value == "Perfect" or value == "Cursor" then
            S.Settings.AutoMode = value
        end
    end,
})

S.UI.Main:Dropdown({
    Name = "Movement",
    Flag = "SoundSpaceMovement",
    Items = { "Snap", "Smooth" },
    Default = "Snap",
    Callback = function(value)
        if value == "Snap" or value == "Smooth" then
            S.Settings.Movement = value
        end
    end,
})

S.UI.Main:Slider({
    Name = "Aim Lead",
    Flag = "SoundSpaceAimLead",
    Min = 0.02,
    Max = 1.25,
    Default = 0.35,
    Decimals = 0.01,
    Suffix = "s",
    Callback = function(value)
        S.Settings.AimLead = math.clamp(tonumber(value) or 0.35, 0.02, 1.25)
    end,
})

S.UI.Main:Slider({
    Name = "Smoothness",
    Flag = "SoundSpaceSmoothness",
    Min = 1,
    Max = 80,
    Default = 28,
    Decimals = 1,
    Callback = function(value)
        S.Settings.Smoothness = math.clamp(tonumber(value) or 28, 1, 80)
    end,
})

S.UI.Main:Slider({
    Name = "Emergency Snap",
    Flag = "SoundSpaceEmergencySnap",
    Min = 0,
    Max = 0.2,
    Default = 0.055,
    Decimals = 0.005,
    Suffix = "s",
    Callback = function(value)
        S.Settings.EmergencySnap = math.clamp(tonumber(value) or 0.055, 0, 0.2)
    end,
})

S.UI.Behavior:Toggle({
    Name = "Lock Game Input",
    Flag = "SoundSpaceLockInput",
    Default = true,
    Info = "Stops touch/mouse movement from fighting the auto player while enabled.",
    Callback = function(value)
        S.Settings.LockInput = value == true

        if S.Settings.Enabled then
            if S.Settings.LockInput then
                S.AcquireInput()
            else
                S.ReleaseInput()
            end
        end
    end,
})

S.UI.Behavior:Toggle({
    Name = "Return Cursor to Center",
    Flag = "SoundSpaceReturnCenter",
    Default = false,
    Callback = function(value)
        S.Settings.ReturnToCenter = value == true
    end,
})

S.UI.Behavior:Toggle({
    Name = "Restore Cursor on Disable",
    Flag = "SoundSpaceRestoreCursor",
    Default = true,
    Callback = function(value)
        S.Settings.RestoreCursor = value == true
    end,
})

S.UI.RuntimeSection:Paragraph({
    Name = "Modes",
    Content = "Perfect uses the game's own hit handler only after the note reaches its native hit plane. Cursor relies entirely on normal cursor collision.",
})

S.UI.StatusLabel = S.UI.RuntimeSection:Label("Status: Disabled")
S.UI.StatsLabel = S.UI.RuntimeSection:Label("Run: idle")

S.UI.RuntimeButtons = S.UI.RuntimeSection:Button()
S.UI.RuntimeButtons:Add("Show State", S.ShowState)
S.UI.RuntimeButtons:Add("Reset Tracking", function()
    S.ResetTarget()
    S.Runtime.Run = S.GetRun()
    S.Notify("Auto Player", "Tracking state reset.", "success")
end)

S.UI.RuntimeButtons2 = S.UI.RuntimeSection:Button()
S.UI.RuntimeButtons2:Add("Unload", function()
    S.Controller.Destroy()
end)

S.VibeUI:CreateSettingsPage(S.UI.Window)

S.SetStatus("Disabled")
return S.Controller
