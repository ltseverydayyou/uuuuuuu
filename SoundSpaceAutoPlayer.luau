local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")

if game.PlaceId ~= 2677609345 then
    error("Sound Space Auto Player only supports place 2677609345")
end

local LocalPlayer = Players.LocalPlayer
local Environment = getgenv()

local Previous = rawget(Environment, "SoundSpaceAutoPlayer")
if type(Previous) == "table" and type(Previous.Destroy) == "function" then
    pcall(Previous.Destroy)
end

local GameManager = require(
    ReplicatedFirst
        :WaitForChild("Modules")
        :WaitForChild("GameManager")
)

local Modal = loadstring(
    game:HttpGet("https://github.com/lxte/Modal/releases/latest/download/main.lua")
)()

local Window = Modal:CreateWindow({
    Title = "Sound Space",
    SubTitle = "Auto Player",
    Size = UDim2.fromOffset(430, 430),
    MinimumSize = Vector2.new(320, 300),
    Transparency = 0,
    Icon = "rbxassetid://68073547",
})

local Settings = {
    Enabled = false,
    Mode = "Snap",
    Lookahead = 0.75,
    Smoothness = 22,
    ReturnToCenter = false,
    RestoreCursor = true,
}

local Controller = {}
local BindName = "SoundSpaceAutoPlayer_" .. tostring(LocalPlayer.UserId)
local CurrentRun = nil
local CurrentTarget = nil
local SavedPosition = nil
local LastStatus = ""
local Destroyed = false
local AutoToggle

Environment.SoundSpaceAutoPlayer = Controller

local function Notify(title, description, notificationType)
    pcall(function()
        Window:Notify({
            Title = title,
            Description = description,
            Duration = 4,
            Type = notificationType or "Info",
        })
    end)
end

local function SetStatus(status)
    if LastStatus == status then
        return
    end

    LastStatus = status

    if AutoToggle then
        pcall(function()
            AutoToggle:SetDescription(status)
        end)
    end
end

local function ResetTracking(restore)
    CurrentTarget = nil
    CurrentRun = nil

    if restore and Settings.RestoreCursor and SavedPosition then
        local Input = GameManager.Input
        if Input then
            Input._pos = SavedPosition
            Input._posClamped = Vector3.new(
                0,
                math.clamp(SavedPosition.Y, 0.2625000000000002, 5.7375),
                math.clamp(SavedPosition.Z, -2.7375, 2.7375)
            )
        end
    end

    SavedPosition = nil
end

local function IsTargetValid(run, target)
    if not target or not target.Parent then
        return false
    end

    local Spawned = run and run._spawned
    return type(Spawned) == "table" and Spawned[target] ~= nil
end

local function SelectTarget(run)
    if IsTargetValid(run, CurrentTarget) then
        return CurrentTarget
    end

    CurrentTarget = nil

    local Spawned = run._spawned
    if type(Spawned) ~= "table" then
        return nil
    end

    local ScrollSpeed = math.max(1, tonumber(run._scrollSpeed) or 50)
    local MinimumX = -ScrollSpeed * Settings.Lookahead
    local BestX = -math.huge

    for Note in pairs(Spawned) do
        if typeof(Note) == "Instance" and Note:IsA("BasePart") and Note.Parent then
            local X = Note.Position.X
            if X >= MinimumX and X > BestX then
                BestX = X
                CurrentTarget = Note
            end
        end
    end

    return CurrentTarget
end

local function IsRunReady(run)
    return run
        and run.Running
        and not run._spectating
        and not run._awaitEnd
        and not run._isPaused
        and run._canUpdate
end

local function MoveCursor(run, target, deltaTime)
    local Input = GameManager.Input
    if not Input then
        return
    end

    if not SavedPosition then
        SavedPosition = Input._posClamped or Input._pos or Vector3.new(0, 3, 0)
    end

    local TargetPosition = Vector3.new(
        0,
        math.clamp(target.Position.Y, 0.2625000000000002, 5.7375),
        math.clamp(target.Position.Z, -2.7375, 2.7375)
    )

    local CurrentPosition = Input._posClamped or Input._pos or Vector3.new(0, 3, 0)
    local NextPosition

    if Settings.Mode == "Smooth" and target.Position.X < -1 then
        local Alpha = math.clamp(
            1 - math.exp(-math.max(1, Settings.Smoothness) * deltaTime),
            0,
            1
        )
        NextPosition = CurrentPosition:Lerp(TargetPosition, Alpha)
    else
        NextPosition = TargetPosition
    end

    Input._pos = NextPosition
    Input._posClamped = NextPosition

    if run.Cursor and run.Cursor.Parent then
        run.Cursor.CFrame = CFrame.new(NextPosition)
    end
end

local function ReturnCursor(deltaTime)
    if not Settings.ReturnToCenter then
        return
    end

    local Input = GameManager.Input
    if not Input then
        return
    end

    local CurrentPosition = Input._posClamped or Input._pos or Vector3.new(0, 3, 0)
    local Center = Vector3.new(0, 3, 0)
    local Alpha = math.clamp(
        1 - math.exp(-math.max(1, Settings.Smoothness) * deltaTime),
        0,
        1
    )
    local NextPosition = CurrentPosition:Lerp(Center, Alpha)

    Input._pos = NextPosition
    Input._posClamped = NextPosition
end

local function Render(deltaTime)
    if Destroyed then
        return
    end

    if not Settings.Enabled then
        SetStatus("Disabled")
        return
    end

    local Run = GameManager._run

    if Run ~= CurrentRun then
        CurrentRun = Run
        CurrentTarget = nil
        SavedPosition = nil
    end

    if not Run or not Run.Running then
        SetStatus("Waiting for a run")
        ReturnCursor(deltaTime)
        return
    end

    if Run._spectating then
        SetStatus("Blocked while spectating")
        CurrentTarget = nil
        return
    end

    if Run._isPaused then
        SetStatus("Paused")
        return
    end

    if not IsRunReady(Run) then
        SetStatus("Waiting for the map to become active")
        return
    end

    local Target = SelectTarget(Run)

    if not Target then
        SetStatus("Active: waiting for the next note")
        ReturnCursor(deltaTime)
        return
    end

    MoveCursor(Run, Target, deltaTime)

    local SpawnedCount = 0
    for _ in pairs(Run._spawned) do
        SpawnedCount += 1
    end

    SetStatus(("Active: tracking %d spawned note%s"):format(
        SpawnedCount,
        SpawnedCount == 1 and "" or "s"
    ))
end

RunService:BindToRenderStep(
    BindName,
    Enum.RenderPriority.Camera.Value,
    Render
)

local MainTab = Window:AddTab("Auto Player")
local SettingsTab = Window:AddTab("Settings")

MainTab:New("Title")({
    Title = "note tracking",
})

AutoToggle = MainTab:New("Toggle")({
    Title = "Enable Auto Player",
    Description = "Disabled",
    DefaultValue = false,
    Callback = function(value)
        Settings.Enabled = value == true
        CurrentTarget = nil

        if Settings.Enabled then
            Notify(
                "Auto Player",
                "Enabled. It will only operate during a run.",
                "Success"
            )
        else
            ResetTracking(true)
            SetStatus("Disabled")
            Notify("Auto Player", "Disabled.", "Info")
        end
    end,
})

MainTab:New("Dropdown")({
    Title = "Movement Mode",
    Description = "Snap is exact. Smooth interpolates until the note is urgent.",
    Options = { "Snap", "Smooth" },
    Default = "Snap",
    Callback = function(value)
        Settings.Mode = value
    end,
})

MainTab:New("Slider")({
    Title = "Lookahead",
    Description = "Seconds before the hit plane to begin following a note.",
    Default = 0.75,
    Minimum = 0.05,
    Maximum = 2,
    DecimalCount = 2,
    Callback = function(value)
        Settings.Lookahead = value
    end,
})

MainTab:New("Slider")({
    Title = "Smoothness",
    Description = "Higher values move faster in Smooth mode.",
    Default = 22,
    Minimum = 1,
    Maximum = 60,
    DecimalCount = 0,
    Callback = function(value)
        Settings.Smoothness = value
    end,
})

MainTab:New("Button")({
    Title = "Show Current State",
    Description = "Displays run-state information.",
    Callback = function()
        local Run = GameManager._run
        local RunText

        if not Run or not Run.Running then
            RunText = "no active run"
        else
            RunText = "normal scoring run"
        end

        Notify(
            "Current State",
            ("%s; %s"):format(
                RunText,
                LastStatus ~= "" and LastStatus or "idle"
            ),
            "Info"
        )
    end,
})

SettingsTab:New("Toggle")({
    Title = "Return Cursor to Center",
    Description = "Moves toward the center while no note is in lookahead range.",
    DefaultValue = false,
    Callback = function(value)
        Settings.ReturnToCenter = value == true
    end,
})

SettingsTab:New("Toggle")({
    Title = "Restore Cursor on Disable",
    Description = "Restores the cursor position captured when tracking began.",
    DefaultValue = true,
    Callback = function(value)
        Settings.RestoreCursor = value == true
    end,
})

SettingsTab:New("Dropdown")({
    Title = "Theme",
    Description = "Changes the Modal window theme.",
    Options = { "Light", "Dark", "Midnight", "Rose", "Emerald" },
    Default = "Midnight",
    Callback = function(value)
        Window:SetTheme(value)
    end,
})

SettingsTab:New("Button")({
    Title = "Destroy",
    Description = "Stops the auto player and removes the interface.",
    Callback = function()
        Controller.Destroy()
    end,
})

function Controller.Destroy()
    if Destroyed then
        return
    end

    Destroyed = true
    Settings.Enabled = false
    RunService:UnbindFromRenderStep(BindName)
    ResetTracking(true)

    pcall(function()
        Window:Destroy()
    end)

    if rawget(Environment, "SoundSpaceAutoPlayer") == Controller then
        Environment.SoundSpaceAutoPlayer = nil
    end
end

Window:SetTab("Auto Player")
Window:SetTheme("Midnight")
SetStatus("Disabled")

return Controller
