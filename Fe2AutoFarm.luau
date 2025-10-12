local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local MP = Workspace:WaitForChild("Multiplayer")

local TP_DELAY = 0.05
local BTN_DELAY = 0.05
local SCAN_INT = 0.05
local VOID_Y = -50
local EXIT_PUSH = Vector3.new(50, -1, 50)
local JUMP_UP = Vector3.new(0, 100, 0)
local PLAT_SIZE = Vector3.new(24, 2, 24)
local EXP_SAFE_Y = 5
local LIFT_NUDGE = Vector3.new(0, 0, 100)
local RESPAWN_REMOTE_REPS = 5
local RESPAWN_REMOTE_GAP = 0.3
local EXIT_MAX = 50

local Enabled = false
local CurMap = nil
local MapTok = 0
local AntiVoidConn, NoClipConn
local SafePlat

local CL = LP.PlayerScripts:FindFirstChild("CL_MAIN_GameScript")
local CLenv = CL and getsenv(CL) or nil
local newAlert = CLenv and CLenv.newAlert or nil
local function Alert(s)
    if newAlert then newAlert(tostring(s), nil, nil, "rainbow") end
end

local function uiParent()
    local ok, ui = pcall(gethui)
    if ok and typeof(ui) == "Instance" then return ui end
    local cg = game:GetService("CoreGui")
    if pcall(function() return cg:FindFirstChildOfClass("ScreenGui") end) then return cg end
    return cg
end

local LiftRemote do
    local ok, r = pcall(function()
        return ReplicatedStorage:WaitForChild("Remote"):WaitForChild("dKgyIXnLdhwvSyEorkEWJJAkgUslGCtR")
    end)
    LiftRemote = ok and r or nil
end

do
    local SG = Instance.new("ScreenGui")
    SG.Name = "AF_Toggle"
    SG.IgnoreGuiInset = true
    SG.ResetOnSpawn = false
    SG.Parent = uiParent()
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 160, 0, 50)
    Btn.Position = UDim2.new(0.5, -80, 0, 10)
    Btn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
    Btn.TextColor3 = Color3.new(1,1,1)
    Btn.Font = Enum.Font.SourceSansBold
    Btn.TextSize = 20
    Btn.Text = "Start AutoFarm"
    Btn.Parent = SG
    local dragging, dragStart, startPos = false, nil, nil
    Btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = Btn.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            Btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    local function refresh()
        Btn.Text = Enabled and "Stop AutoFarm" or "Start AutoFarm"
        Btn.BackgroundColor3 = Enabled and Color3.fromRGB(180,60,60) or Color3.fromRGB(60,180,60)
    end
    local function setNoClip(on)
        if NoClipConn then NoClipConn:Disconnect(); NoClipConn = nil end
        if not on then return end
        NoClipConn = RunService.Stepped:Connect(function()
            local c = LP.Character
            if not c then return end
            for _,part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    end
    local function pushToLift()
        local r = (LP.Character or LP.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
        r.CFrame = r.CFrame + Vector3.new(0, 5, 0)
        repeat
            task.wait(0.1)
            r.AssemblyLinearVelocity = LIFT_NUDGE
            local c = LP.Character
            if c then
                local cf, sz = c:GetBoundingBox()
                local bottom = cf.Position.Y - sz.Y/2
                if not (SafePlat and SafePlat.Parent) then
                    local p = Instance.new("Part")
                    p.Name = "AF_SafePlatform"
                    p.Size = PLAT_SIZE
                    p.Anchored = true
                    p.CanCollide = true
                    p.CFrame = CFrame.new(r.Position.X, bottom - (PLAT_SIZE.Y/2) - 0.05, r.Position.Z)
                    p.Parent = Workspace
                    SafePlat = p
                else
                    SafePlat.CFrame = CFrame.new(r.Position.X, bottom - (PLAT_SIZE.Y/2) - 0.05, r.Position.Z)
                end
            end
        until (r.Position.X < 50 and r.Position.Z > 70) or not Enabled
    end
    Btn.MouseButton1Click:Connect(function()
        Enabled = not Enabled
        refresh()
        Alert(Enabled and "Enabled" or "Disabled")
        setNoClip(Enabled)
        if Enabled and LiftRemote then
            pcall(function() LiftRemote:FireServer() end)
            task.spawn(pushToLift)
        end
    end)
    refresh()
end

local function chr()
    return LP.Character or LP.CharacterAdded:Wait()
end

local function rootHum()
    local c = chr()
    return c:WaitForChild("HumanoidRootPart"), c:WaitForChild("Humanoid")
end

local function Check(flag)
    local r = chr():FindFirstChild("HumanoidRootPart")
    if not r then return false end
    if flag == "InLift" then
        return r.Position.X < 50 and r.Position.Z > 70
    elseif flag == "InGame" then
        return r.Position.X > 50
    end
    return false
end

local function isRand(s)
    if #s == 0 then return false end
    for i=1,#s do
        local c = s:sub(i,i)
        if c:lower() == c then return false end
    end
    return true
end

local function mkPlatAtFeet(r)
    local c = LP.Character
    if not c then return end
    local cf, sz = c:GetBoundingBox()
    local bottom = cf.Position.Y - sz.Y/2
    if not (SafePlat and SafePlat.Parent) then
        local p = Instance.new("Part")
        p.Name = "AF_SafePlatform"
        p.Size = PLAT_SIZE
        p.Anchored = true
        p.CanCollide = true
        p.CFrame = CFrame.new(r.Position.X, bottom - (PLAT_SIZE.Y/2) - 0.05, r.Position.Z)
        p.Parent = Workspace
        SafePlat = p
    else
        SafePlat.CFrame = CFrame.new(r.Position.X, bottom - (PLAT_SIZE.Y/2) - 0.05, r.Position.Z)
    end
end

local function antiVoidStart(getMap)
    if AntiVoidConn then AntiVoidConn:Disconnect() end
    AntiVoidConn = RunService.Heartbeat:Connect(function()
        if not Enabled then return end
        local r = chr():FindFirstChild("HumanoidRootPart")
        if not r then return end
        if r.Position.Y < VOID_Y then
            local map = getMap()
            if map and map.Parent then
                local ok, cf, sz = pcall(map.GetBoundingBox, map)
                if ok and cf and sz then
                    r.CFrame = CFrame.new(cf.Position + Vector3.new(0, sz.Y/2 + 8, 0))
                    mkPlatAtFeet(r)
                    Alert("Recovered from void")
                end
            end
        end
    end)
end

local function findLower(map, target)
    for _, inst in ipairs(map:GetDescendants()) do
        local n = inst.Name
        if typeof(n) == "string" and n:lower() == target then
            return inst
        end
    end
end

local function anyPart(inst)
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        if inst.PrimaryPart then return inst.PrimaryPart end
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("BasePart") then return d end
        end
    end
end

local function bringToPlayer(inst, r)
    local part = anyPart(inst)
    if not part then return end
    if inst:IsA("Model") then
        if inst.PrimaryPart then inst:SetPrimaryPartCFrame(r.CFrame) else inst:PivotTo(r.CFrame) end
    else
        part.CFrame = r.CFrame
    end
end

local function scanButtons(map)
    local buttons = {}
    for _, o in pairs(map:GetDescendants()) do
        if o.ClassName == "Model" and isRand(o.Name) then
            local hit
            for _, ch in pairs(o:GetChildren()) do
                if ch:IsA("BasePart") and tostring(ch.BrickColor) ~= "Medium stone grey" then hit = ch break end
            end
            if hit and isRand(hit.Name) then
                hit.Name = "Hitbox"
                table.insert(buttons, o)
            end
        end
    end
    return buttons
end

local function pushToLift()
    local r = (LP.Character or LP.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart")
    r.CFrame = r.CFrame + Vector3.new(0, 5, 0)
    repeat
        task.wait(0.1)
        r.AssemblyLinearVelocity = LIFT_NUDGE
        mkPlatAtFeet(r)
    until Check("InLift") or not Enabled
end

local function onRespawn(char)
    task.spawn(function()
        if LiftRemote then
            for i=1,RESPAWN_REMOTE_REPS do
                pcall(function() LiftRemote:FireServer() end)
                task.wait(RESPAWN_REMOTE_GAP)
            end
        end
    end)
    task.spawn(function()
        if Enabled then pushToLift() end
    end)
    if Enabled then
        if NoClipConn then NoClipConn:Disconnect() end
        NoClipConn = RunService.Stepped:Connect(function()
            local c = LP.Character
            if not c then return end
            for _,part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end)
    end
end
LP.CharacterAdded:Connect(onRespawn)

local function onMap(map, tok)
    local r, h = rootHum()
    local s = map:FindFirstChild("Settings")
    local mapName = nil
    if s then
        local okAttr, n = pcall(function() return s:GetAttribute("MapName") end)
        if okAttr then mapName = n end
    end
    if not mapName then mapName = map.Name end
    Alert("Map Loaded! "..tostring(mapName))
    if not Check("InGame") then Alert("Skipping due to InGame == false.") return end

    local buttons = {}
    local okScan, res = pcall(scanButtons, map)
    if okScan and res then buttons = res end

    local page = findLower(map, "_lostpage")
    if page then
        bringToPlayer(page, r)
        task.wait(TP_DELAY)
        Alert("Got Lost Page.")
    end
    local contact = findLower(map, "contact")
    if not contact then
        local npc = findLower(map, "npc")
        if npc and npc.Parent then
            contact = npc.Parent:FindFirstChild("Contact") or findLower(map, "contact")
        end
    end
    if contact then
        bringToPlayer(contact, r)
        task.wait(TP_DELAY)
        Alert("Got Escapee.")
    end

    Alert("Commencing Auto Farm")
    local hpConn = h:GetPropertyChangedSignal("Health"):Connect(function() h.Health = 1000 end)
    local tries = 0

    while task.wait(SCAN_INT) and Enabled and CurMap == map and map.Parent and Check("InGame") do
        local exit = map:FindFirstChild("ExitRegion", true)
        r = chr():FindFirstChild("HumanoidRootPart")
        h.Jump = true
        if not exit then
            for _, btn in pairs(buttons) do
                if not (Enabled and CurMap == map and map.Parent) then break end
                local hit = btn:FindFirstChild("Hitbox")
                if hit then
                    local touch = btn:FindFirstChild("TouchInterest", true)
                    local gui = btn:FindFirstChildWhichIsA("BillboardGui", true)
                    if touch and gui then
                        r.Anchored = false
                        r.CFrame = CFrame.new(hit.Position)
                        h:ChangeState(Enum.HumanoidStateType.Jumping)
                        r.Velocity = JUMP_UP
                        task.wait(TP_DELAY)
                        r.CFrame = CFrame.new(hit.Position + Vector3.new(0, EXP_SAFE_Y, 0))
                        r.Anchored = true
                        task.wait(BTN_DELAY)
                    end
                end
            end
        else
            r.Anchored = false
            if tries < EXIT_MAX then
                tries += 1
                r.CFrame = exit.CFrame
                h:ChangeState(Enum.HumanoidStateType.Landed)
                r.Velocity = EXIT_PUSH
                mkPlatAtFeet(r)
                task.wait(TP_DELAY)
                if (r.Position - exit.Position).Magnitude <= 5 then tries += 1 end
            else
                tries = 0
                mkPlatAtFeet(r)
                task.wait(TP_DELAY)
            end
        end
    end

    if hpConn then hpConn:Disconnect() end
    local rr = chr():FindFirstChild("HumanoidRootPart")
    if rr then mkPlatAtFeet(rr) end
    Alert("Complete. Waiting for next map..")
    repeat
        task.wait(0.2)
        local m = MP:FindFirstChild("Map")
        local r2 = chr():FindFirstChild("HumanoidRootPart")
        if r2 then mkPlatAtFeet(r2) end
        if not Enabled then return end
    until m and m ~= map
end

local function currentMap()
    return MP:FindFirstChild("Map")
end

local function antiVoidStartWrapper()
    antiVoidStart(currentMap)
end
antiVoidStartWrapper()
Alert("Ready")

task.spawn(function()
    while true do
        task.wait(SCAN_INT)
        if not Enabled then continue end
        local m = currentMap()
        if m and m ~= CurMap then
            CurMap = m
            MapTok += 1
            local tok = MapTok
            Alert("New Map")
            local ok = pcall(onMap, m, tok)
            if not ok then Alert("Map handler error; continuing") end
        end
    end
end)
