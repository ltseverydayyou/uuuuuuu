local function ClonedService(name)
    local Service = (game.GetService);
    local Reference = (cloneref) or function(reference) return reference end
    return Reference(Service(game, name));
end

local TweenService = ClonedService("TweenService")
local player = ClonedService("Players").LocalPlayer
local gui = Instance.new("ScreenGui")

local function NAdrag(ui, dragui)
    if not dragui then dragui = ui end
    local UserInputService = ClonedService("UserInputService")
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        local newXOffset = startPos.X.Offset + delta.X
        local newYOffset = startPos.Y.Offset + delta.Y
        local screenSize = ui.Parent.AbsoluteSize
        local newXScale = startPos.X.Scale + (newXOffset / screenSize.X)
        local newYScale = startPos.Y.Scale + (newYOffset / screenSize.Y)
        ui.Position = UDim2.new(newXScale, 0, newYScale, 0)
    end
    dragui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = ui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    dragui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
    ui.Active = true
end

local function protectUI(sGui)
    if sGui:IsA("ScreenGui") then
        sGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
        sGui.DisplayOrder = 999999999
        sGui.ResetOnSpawn = false
        sGui.IgnoreGuiInset = true
    end
    local cGUI = ClonedService("CoreGui")
    local lPlr = ClonedService("Players").LocalPlayer
    local function NAProtection(inst, var)
        if inst then
            if var then
                inst[var] = "\0"
                inst.Archivable = false
            else
                inst.Name = "\0"
                inst.Archivable = false
            end
        end
    end
    if gethui then
        NAProtection(sGui)
        sGui.Parent = gethui()
        return sGui
    elseif cGUI and cGUI:FindFirstChild("RobloxGui") then
        NAProtection(sGui)
        sGui.Parent = cGUI:FindFirstChild("RobloxGui")
        return sGui
    elseif cGUI then
        NAProtection(sGui)
        sGui.Parent = cGUI
        return sGui
    elseif lPlr and lPlr:FindFirstChildWhichIsA("PlayerGui") then
        NAProtection(sGui)
        sGui.Parent = lPlr:FindFirstChildWhichIsA("PlayerGui")
        sGui.ResetOnSpawn = false
        return sGui
    else
        return nil
    end
end

protectUI(gui)

local root = Instance.new("Frame")
root.Name = "Panel"
root.Parent = gui
root.Size = UDim2.fromOffset(360, 210)
root.Position = UDim2.new(0.5, 0, 0.12, 0)
root.AnchorPoint = Vector2.new(0.5, 0)
root.BackgroundColor3 = Color3.fromRGB(24, 24, 27)
root.BackgroundTransparency = 0.05

local rootCorner = Instance.new("UICorner")
rootCorner.CornerRadius = UDim.new(0, 14)
rootCorner.Parent = root

local rootStroke = Instance.new("UIStroke")
rootStroke.Thickness = 1
rootStroke.Transparency = 0.4
rootStroke.Color = Color3.fromRGB(255, 255, 255)
rootStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
rootStroke.Parent = root

local rootGrad = Instance.new("UIGradient")
rootGrad.Color = ColorSequence.new(Color3.fromRGB(32, 32, 36), Color3.fromRGB(18, 18, 20))
rootGrad.Rotation = 90
rootGrad.Parent = root

local header = Instance.new("Frame")
header.Parent = root
header.Size = UDim2.new(1, -16, 0, 44)
header.Position = UDim2.new(0, 8, 0, 8)
header.BackgroundColor3 = Color3.fromRGB(34, 34, 38)
header.BackgroundTransparency = 0.2

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 10)
headerCorner.Parent = header

local headerStroke = Instance.new("UIStroke")
headerStroke.Thickness = 1
headerStroke.Transparency = 0.55
headerStroke.Color = Color3.fromRGB(255, 255, 255)
headerStroke.Parent = header

local title = Instance.new("TextLabel")
title.Parent = header
title.Size = UDim2.new(1, -16, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Utilities"
title.TextColor3 = Color3.fromRGB(235, 235, 240)
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextSize = 18

local body = Instance.new("Frame")
body.Parent = root
body.Size = UDim2.new(1, -16, 1, -60)
body.Position = UDim2.new(0, 8, 0, 52)
body.BackgroundTransparency = 1

local list = Instance.new("UIListLayout")
list.Parent = body
list.Padding = UDim.new(0, 10)
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.SortOrder = Enum.SortOrder.LayoutOrder

local function toggleRow(text)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 46)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
    row.BackgroundTransparency = 0.15
    row.LayoutOrder = #body:GetChildren()+1

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 10)
    rowCorner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Thickness = 1
    rowStroke.Transparency = 0.6
    rowStroke.Color = Color3.fromRGB(255, 255, 255)
    rowStroke.Parent = row

    local label = Instance.new("TextLabel")
    label.Parent = row
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -90, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(230, 230, 236)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("TextButton")
    track.Parent = row
    track.AutoButtonColor = false
    track.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    track.Size = UDim2.fromOffset(56, 28)
    track.Position = UDim2.new(1, -16 - 56, 0.5, -14)
    track.Text = ""
    track.ZIndex = 2

    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local trackStroke = Instance.new("UIStroke")
    trackStroke.Parent = track
    trackStroke.Thickness = 1
    trackStroke.Transparency = 0.35
    trackStroke.Color = Color3.fromRGB(255, 255, 255)

    local trackGrad = Instance.new("UIGradient")
    trackGrad.Color = ColorSequence.new(Color3.fromRGB(52, 52, 58), Color3.fromRGB(38, 38, 44))
    trackGrad.Rotation = 90
    trackGrad.Parent = track

    local knob = Instance.new("Frame")
    knob.Parent = track
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    knob.Size = UDim2.fromOffset(24, 24)
    knob.Position = UDim2.new(0, 2, 0.5, -12)
    knob.ZIndex = 3

    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local state = false

    local function setState(on)
        state = on
        local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local destX = on and (56 - 24 - 2) or 2
        local colorOnA = Color3.fromRGB(88, 170, 255)
        local colorOnB = Color3.fromRGB(134, 96, 255)
        local colorOffA = Color3.fromRGB(52, 52, 58)
        local colorOffB = Color3.fromRGB(38, 38, 44)
        TweenService:Create(knob, ti, {Position = UDim2.new(0, destX, 0.5, -12)}):Play()
        TweenService:Create(track, ti, {BackgroundColor3 = on and Color3.fromRGB(55, 60, 75) or Color3.fromRGB(45, 45, 50)}):Play()
        trackGrad.Color = ColorSequence.new(on and colorOnA or colorOffA, on and colorOnB or colorOffB)
        trackStroke.Transparency = on and 0.15 or 0.35
    end

    track.MouseButton1Click:Connect(function()
        setState(not state)
    end)

    row.Parent = body
    return {
        row = row,
        set = setState,
        get = function() return state end,
        button = track
    }
end

local moneyFarmEnabled = false
local monitorEnabled = false
local shutterEnabled = false

local moneyRow = toggleRow("Money Farm")
local monitorRow = toggleRow("Monitor Farm")
local shutterRow = toggleRow("Janitor Body Farm")

moneyRow.button.MouseButton1Click:Connect(function()
    moneyFarmEnabled = not moneyFarmEnabled
end)
monitorRow.button.MouseButton1Click:Connect(function()
    monitorEnabled = not monitorEnabled
end)
shutterRow.button.MouseButton1Click:Connect(function()
    shutterEnabled = not shutterEnabled
end)

NAdrag(root, header)

local monitorCds = {}
local trashCds = {}

for _, m in ipairs(workspace:GetDescendants()) do
    if m.Name:lower() == "monitor" then
        local cd = m:FindFirstChildWhichIsA("ClickDetector", true)
        if cd then
            table.insert(monitorCds, cd)
        end
    end
end

for _, t in ipairs(workspace:GetDescendants()) do
    if t.Name:lower() == "trashcan" then
        local cd = t:FindFirstChildWhichIsA("ClickDetector", true)
        if cd then
            table.insert(trashCds, cd)
        end
    end
end

task.spawn(function()
    while task.wait(0.1) do
        if monitorEnabled then
            pcall(function()
                for _, cd in ipairs(monitorCds) do
                    fireclickdetector(cd)
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if moneyFarmEnabled then
            local p = ClonedService("Players").LocalPlayer
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            local mh = ClonedService("Workspace").Buildings.DeadBurger.DumpsterMoneyMaker:FindFirstChild("MoneyHitbox")
            if hrp and mh then
                local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
                local tween1 = TweenService:Create(mh, tweenInfo, {CFrame = hrp.CFrame})
                local tween2 = TweenService:Create(mh, tweenInfo, {CFrame = hrp.CFrame + Vector3.new(0, 20, 0)})
                tween1:Play()
                tween1.Completed:Wait()
                tween2:Play()
                tween2.Completed:Wait()
            end
            local bp = p:FindFirstChild("Backpack")
            if bp then
                local tool = bp:FindFirstChild("Garbage Bag")
                if tool then
                    p.Character.Humanoid:EquipTool(tool)
                end
            end
            for _, cd in ipairs(trashCds) do
                fireclickdetector(cd)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if shutterEnabled then
            pcall(function()
                local s = ClonedService("Workspace").Model.Shutter.Root:FindFirstChildWhichIsA("ClickDetector", true)
                if s then fireclickdetector(s) end
            end)
        end
    end
end)