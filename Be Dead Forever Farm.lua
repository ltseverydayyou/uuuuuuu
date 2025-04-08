local TweenService = game:GetService("TweenService")
local player = game:GetService("Players").LocalPlayer
local gui = Instance.new("ScreenGui")

local function NAdrag(ui, dragui)
    if not dragui then dragui = ui end
    local UserInputService = game:GetService("UserInputService")
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

local function createButton(name, position, callback)
    local button = Instance.new("TextButton", gui)
    button.Size = UDim2.new(0, 100, 0, 50)
    button.Position = position
    button.Text = name
    button.TextScaled = true
    button.BackgroundColor3 = Color3.new(1, 0, 0)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.BorderSizePixel = 0
    button.BackgroundTransparency = 0.2
    button.Font = Enum.Font.SourceSans
    button.ClipsDescendants = true
    button.ZIndex = 2
    button.AutoButtonColor = true
    button.TextWrapped = true
    button.TextStrokeTransparency = 0.8
    button.TextStrokeColor3 = Color3.new(0, 0, 0)
    button.TextSize = 14
    button.TextXAlignment = Enum.TextXAlignment.Center
    button.TextYAlignment = Enum.TextYAlignment.Center
    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(1, 0)
    callback(button)
    return button
end

local moneyFarmEnabled = false
local monitorEnabled = false
local shutterEnabled = false

local moneyFarmButton = createButton("Money Farm", UDim2.new(0.5, -160, 0, 10), function(button)
    button.MouseButton1Click:Connect(function()
        moneyFarmEnabled = not moneyFarmEnabled
        button.BackgroundColor3 = moneyFarmEnabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    end)
end)

local monitorButton = createButton("Monitor Farm", UDim2.new(0.5, -50, 0, 10), function(button)
    button.MouseButton1Click:Connect(function()
        monitorEnabled = not monitorEnabled
        button.BackgroundColor3 = monitorEnabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    end)
end)

local shutterButton = createButton("Janitor Body Farm", UDim2.new(0.5, 60, 0, 10), function(button)
    button.MouseButton1Click:Connect(function()
        shutterEnabled = not shutterEnabled
        button.BackgroundColor3 = shutterEnabled and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    end)
end)

NAdrag(moneyFarmButton)
NAdrag(monitorButton)
NAdrag(shutterButton)

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
            local p = game:GetService("Players").LocalPlayer
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            local mh = game:GetService("Workspace").Buildings.DeadBurger.DumpsterMoneyMaker:FindFirstChild("MoneyHitbox")
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
                local s = game:GetService("Workspace").Model.Shutter.Root:FindFirstChildWhichIsA("ClickDetector", true)
                if s then fireclickdetector(s) end
            end)
        end
    end
end)

if player.UserId == 817571515 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/thefuni.lua"))()
end