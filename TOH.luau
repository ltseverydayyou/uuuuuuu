local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local VibeURL = "https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"
local ENV = getgenv()

if type(ENV.TOH_VibeHubController) == "table" and type(ENV.TOH_VibeHubController.Destroy) == "function" then
    pcall(ENV.TOH_VibeHubController.Destroy, ENV.TOH_VibeHubController)
end

if type(ENV.TOH_AutoplayerController) == "table" and type(ENV.TOH_AutoplayerController.Stop) == "function" then
    pcall(ENV.TOH_AutoplayerController.Stop)
end

local State = {
    Enabled = false,
    Running = false,
    Busy = false,
    TraverseSections = true,
    StepDelay = 0.12,
    RetryDelay = 1.25,
    NotifyWins = true,
    LoopToken = 0,
    LastAttempt = 0,
    LastWinSignature = nil,
    Status = "Initializing",
}

local UI = {
    Library = nil,
    Status = nil,
    Tower = nil,
    Winner = nil,
}

local Controller = {}
ENV.TOH_VibeHubController = Controller

local function setStatus(text)
    State.Status = tostring(text)
    if UI.Status and type(UI.Status.SetText) == "function" then
        pcall(UI.Status.SetText, UI.Status, State.Status)
    end
end

local function notify(title, description, kind, duration)
    local lib = UI.Library
    if not lib then
        return
    end
    pcall(function()
        lib:Notification({
            Title = tostring(title),
            Description = tostring(description or ""),
            Type = kind or "info",
            Duration = duration or 3,
        })
    end)
end

local function getCharacter(timeout)
    local started = os.clock()
    repeat
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local root = character:FindFirstChild("HumanoidRootPart")
            if humanoid and root and humanoid.Health > 0 then
                return character, humanoid, root
            end
        end
        task.wait(0.1)
    until timeout and os.clock() - started >= timeout
    return nil
end

local function getTower()
    local tower = workspace:FindFirstChild("tower")
    if not tower then
        return nil
    end
    local sections = tower:FindFirstChild("sections")
    local finishes = tower:FindFirstChild("finishes")
    if not sections or not finishes then
        return nil
    end
    return tower, sections, finishes
end

local function getOrderedSections()
    local tower, sections = getTower()
    if not tower then
        return nil
    end
    local list = {}
    for _, section in ipairs(sections:GetChildren()) do
        if section:IsA("Model") then
            local index = section:FindFirstChild("i")
            if index and index:IsA("IntValue") then
                list[#list + 1] = section
            end
        end
    end
    table.sort(list, function(a, b)
        return a.i.Value < b.i.Value
    end)
    return list
end

local function q(n)
    return math.floor(n * 10 + 0.5) / 10
end

local function towerSignature()
    local tower = getTower()
    if not tower then
        return nil
    end
    local ordered = getOrderedSections()
    if not ordered or #ordered == 0 then
        return nil
    end
    local pieces = {}
    for _, section in ipairs(ordered) do
        local id = section:FindFirstChild("id")
        local rotate = section:FindFirstChild("rotate")
        local start = section:FindFirstChild("start")
        local stop = section:FindFirstChild("stop")
        local token = section.Name
        if id and id:IsA("StringValue") then
            token ..= ":" .. id.Value
        end
        if rotate and rotate:IsA("NumberValue") then
            token ..= ":" .. tostring(q(rotate.Value))
        end
        if start and start:IsA("BasePart") then
            local p = start.Position
            token ..= string.format(":s%.1f,%.1f,%.1f", q(p.X), q(p.Y), q(p.Z))
        end
        if stop and stop:IsA("BasePart") then
            local p = stop.Position
            token ..= string.format(":e%.1f,%.1f,%.1f", q(p.X), q(p.Y), q(p.Z))
        end
        pieces[#pieces + 1] = token
    end
    return table.concat(pieces, "|")
end

local function getFinishTarget()
    local tower, sections, finishes = getTower()
    if not tower then
        return nil
    end
    local finishSection = sections:FindFirstChild("finish")
    local reference = nil
    if finishSection then
        local glow = finishSection:FindFirstChild("FinishGlow", true)
        if glow and glow:IsA("BasePart") then
            reference = glow.Position
        else
            local exit = finishSection:FindFirstChild("exit")
            local particleBrick = exit and exit:FindFirstChild("ParticleBrick", true)
            if particleBrick and particleBrick:IsA("BasePart") then
                reference = particleBrick.Position
            end
        end
    end
    if not reference then
        return nil
    end
    local best, bestDistance
    for _, instance in ipairs(finishes:GetDescendants()) do
        if instance:IsA("BasePart") and instance.Name == "Finish" then
            local distance = (instance.Position - reference).Magnitude
            if not bestDistance or distance < bestDistance then
                best = instance
                bestDistance = distance
            end
        end
    end
    return best
end

local function getWinnerRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local gameRemotes = remotes and remotes:FindFirstChild("Game")
    local remote = gameRemotes and gameRemotes:FindFirstChild("fetchRoundWinners")
    if remote and remote:IsA("RemoteFunction") then
        return remote
    end
    return nil
end

local function winnerName(value)
    if typeof(value) == "Instance" then
        return value.Name
    end
    local text = tostring(value)
    return string.match(text, "Players%.(.+)$") or text
end

local function isWinner()
    local remote = getWinnerRemote()
    if not remote then
        return false, nil
    end
    local ok, winners = pcall(remote.InvokeServer, remote)
    if not ok or type(winners) ~= "table" then
        return false, nil
    end
    local names = {}
    local won = false
    for _, winner in pairs(winners) do
        local name = winnerName(winner)
        names[#names + 1] = name
        if name == LocalPlayer.Name then
            won = true
        end
    end
    table.sort(names)
    return won, names
end

local function updateWinnerText(names)
    if not UI.Winner or type(UI.Winner.SetText) ~= "function" then
        return
    end
    local text = "None yet"
    if type(names) == "table" and #names > 0 then
        text = table.concat(names, ", ")
    end
    pcall(UI.Winner.SetText, UI.Winner, text)
end

local function updateTowerText()
    if not UI.Tower or type(UI.Tower.SetText) ~= "function" then
        return
    end
    local ordered = getOrderedSections()
    if not ordered then
        pcall(UI.Tower.SetText, UI.Tower, "Waiting for tower")
        return
    end
    local names = {}
    for _, section in ipairs(ordered) do
        if section.Name ~= "lobby" and section.Name ~= "finish" then
            names[#names + 1] = section.Name
        end
    end
    pcall(UI.Tower.SetText, UI.Tower, table.concat(names, "  →  "))
end

local function moveCharacterTo(targetCFrame)
    local character, humanoid, root = getCharacter(4)
    if not character then
        return false, "Waiting for respawn"
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    character:PivotTo(targetCFrame)
    task.wait()
    if humanoid.Health <= 0 then
        return false, "Died"
    end
    return true
end

local function moveAbove(part)
    local y = math.max(3.25, part.Size.Y * 0.5 + 2.75)
    local target = CFrame.new(part.Position + Vector3.new(0, y, 0))
    return moveCharacterTo(target)
end

local function touchFinish(finish)
    local character, _, root = getCharacter(4)
    if not character then
        return false, "Waiting for respawn"
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    character:PivotTo(finish.CFrame)
    task.wait(0.12)
    if type(firetouchinterest) == "function" then
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") then
                pcall(firetouchinterest, part, finish, 0)
                pcall(firetouchinterest, part, finish, 1)
            end
        end
    end
    task.wait(0.3)
    return true
end

local function completeTower(force)
    if State.Busy then
        return false, "Already running"
    end
    if not force and not State.Enabled then
        return false, "Disabled"
    end
    local signature = towerSignature()
    if not signature then
        return false, "Tower is still loading"
    end
    local ordered = getOrderedSections()
    if not ordered then
        return false, "Tower sections unavailable"
    end

    State.Busy = true
    State.LastAttempt = os.clock()
    updateTowerText()

    local function finishRun(ok, reason)
        State.Busy = false
        return ok, reason
    end

    if State.TraverseSections then
        for _, section in ipairs(ordered) do
            if not force and not State.Enabled then
                return finishRun(false, "Cancelled")
            end
            if towerSignature() ~= signature then
                return finishRun(false, "Tower changed")
            end
            if section.Name ~= "lobby" and section.Name ~= "finish" then
                setStatus("Entering " .. section.Name)
                local start = section:FindFirstChild("start")
                if start and start:IsA("BasePart") then
                    local ok = moveAbove(start)
                    if not ok then
                        return finishRun(false, "Respawning")
                    end
                    task.wait(State.StepDelay)
                end
                setStatus("Clearing " .. section.Name)
                local stop = section:FindFirstChild("stop")
                if stop and stop:IsA("BasePart") then
                    local ok = moveAbove(stop)
                    if not ok then
                        return finishRun(false, "Respawning")
                    end
                    task.wait(State.StepDelay)
                end
            end
        end
    end

    if towerSignature() ~= signature then
        return finishRun(false, "Tower changed")
    end

    local finishSection = nil
    for _, section in ipairs(ordered) do
        if section.Name == "finish" then
            finishSection = section
            break
        end
    end
    if finishSection then
        local start = finishSection:FindFirstChild("start")
        if start and start:IsA("BasePart") then
            setStatus("Entering finish")
            local ok = moveAbove(start)
            if not ok then
                return finishRun(false, "Respawning")
            end
            task.wait(State.StepDelay)
        end
    end

    local finish = getFinishTarget()
    if not finish then
        return finishRun(false, "Finish trigger unavailable")
    end

    setStatus("Touching finish")
    local ok, reason = touchFinish(finish)
    if not ok then
        return finishRun(false, reason)
    end

    local won, names = isWinner()
    updateWinnerText(names)
    if won then
        State.LastWinSignature = signature
        setStatus("Tower completed")
        if State.NotifyWins then
            notify("Tower completed", "The round registered " .. LocalPlayer.Name .. " as a winner.", "success", 4)
        end
        return finishRun(true, "Won")
    end

    setStatus("Finish touched; verifying")
    return finishRun(true, "Touched finish")
end

local function runLoop(token)
    State.Running = true
    while State.Enabled and token == State.LoopToken do
        local won, names = isWinner()
        updateWinnerText(names)
        updateTowerText()
        if won then
            setStatus("Winner registered — waiting for next tower")
            State.LastWinSignature = towerSignature()
            task.wait(1)
        elseif not State.Busy then
            local now = os.clock()
            if now - State.LastAttempt >= State.RetryDelay then
                local ok, reason = completeTower(false)
                if not ok and reason ~= "Cancelled" and reason ~= "Tower changed" and reason ~= "Disabled" then
                    setStatus(reason)
                end
            end
            task.wait(0.25)
        else
            task.wait(0.1)
        end
    end
    State.Running = false
    if not State.Enabled then
        setStatus("Autoplay disabled")
    end
end

function Controller:Start()
    if State.Enabled and State.Running then
        return
    end
    State.Enabled = true
    State.LoopToken += 1
    local token = State.LoopToken
    setStatus("Autoplay enabled")
    task.spawn(runLoop, token)
end

function Controller:Stop()
    State.Enabled = false
    State.LoopToken += 1
    setStatus("Autoplay disabled")
end

function Controller:CompleteNow()
    task.spawn(function()
        local ok, reason = completeTower(true)
        if not ok then
            setStatus(reason)
            notify("Autoplayer", reason, "warning", 3)
        end
    end)
end

function Controller:SetTraverse(enabled)
    State.TraverseSections = enabled == true
end

function Controller:SetStepDelay(value)
    State.StepDelay = math.clamp(tonumber(value) or 0.12, 0.02, 2)
end

function Controller:SetRetryDelay(value)
    State.RetryDelay = math.clamp(tonumber(value) or 1.25, 0.5, 10)
end

function Controller:SetNotifyWins(enabled)
    State.NotifyWins = enabled == true
end

function Controller:Destroy()
    self:Stop()
    ENV.TOH_VibeHubController = nil
end

function Controller:GetState()
    return State
end

local loadOk, VibeUI = pcall(function()
    return loadstring(game:HttpGet(VibeURL))()
end)

if not loadOk or type(VibeUI) ~= "table" then
    warn("[TOH VibeHub] Failed to load VibeUI: " .. tostring(VibeUI))
    Controller:Start()
    return
end

UI.Library = VibeUI

local Window = VibeUI:Window({
    Title = "Tower of Hell • Autoplayer",
    Size = UDim2.fromOffset(720, 500),
    Keybind = Enum.KeyCode.RightControl,
    Layout = "Side",
    Resizable = true,
})

local Main = Window:Tab({ Name = "Autoplayer", Columns = 2 })
local Automation = Main:Section({ Name = "Automation", Side = 1 })
local Status = Main:Section({ Name = "Live Status", Side = 2 })

Automation:Toggle({
    Name = "Auto Complete",
    Flag = "TOH_AutoComplete",
    Default = true,
    Info = "Automatically completes the current tower and repeats on new rounds.",
    InfoType = "tip",
    Callback = function(value)
        if value then
            Controller:Start()
        else
            Controller:Stop()
        end
    end,
})

Automation:Toggle({
    Name = "Traverse Sections",
    Flag = "TOH_TraverseSections",
    Default = true,
    Info = "Visits generated section start/stop points before touching the finish.",
    InfoType = "info",
    Callback = function(value)
        Controller:SetTraverse(value)
    end,
})

Automation:Slider({
    Name = "Step Delay",
    Flag = "TOH_StepDelay",
    Min = 0.02,
    Max = 1,
    Default = 0.12,
    Decimals = 2,
    Suffix = "s",
    Callback = function(value)
        Controller:SetStepDelay(value)
    end,
})

Automation:Slider({
    Name = "Retry Delay",
    Flag = "TOH_RetryDelay",
    Min = 0.5,
    Max = 5,
    Default = 1.25,
    Decimals = 2,
    Suffix = "s",
    Callback = function(value)
        Controller:SetRetryDelay(value)
    end,
})

Automation:Toggle({
    Name = "Win Notifications",
    Flag = "TOH_WinNotifications",
    Default = true,
    Callback = function(value)
        Controller:SetNotifyWins(value)
    end,
})

local actions = Automation:Button()
actions:Add("Complete Now", function()
    Controller:CompleteNow()
end)
actions:Add("Stop", function()
    Controller:Stop()
end)

UI.Status = Status:Paragraph({
    Name = "State",
    Content = "Initializing",
})

UI.Tower = Status:Paragraph({
    Name = "Current Tower",
    Content = "Reading generated sections...",
})

UI.Winner = Status:Paragraph({
    Name = "Round Winners",
    Content = "Checking...",
})

Status:Divider()
Status:Paragraph({
    Name = "Window Keybind",
    Content = "RightControl",
})
Status:Paragraph({
    Name = "Recovery",
    Content = "Respawns, tower regeneration, and new rounds are handled automatically while Auto Complete is enabled.",
})

local statusActions = Status:Button()
statusActions:Add("Refresh", function()
    local _, names = isWinner()
    updateWinnerText(names)
    updateTowerText()
end)
statusActions:Add("Re-enable", function()
    Controller:Start()
end)

updateTowerText()
local _, currentWinners = isWinner()
updateWinnerText(currentWinners)
Controller:Start()
notify("TOH Autoplayer", "VibeUI hub loaded. Auto Complete is enabled.", "success", 3)
