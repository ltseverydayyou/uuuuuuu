if game.GameId==319401355 then
local tpp = game:GetService("Workspace").Axe.Handle.ClickDetector
local runservice = game:GetService("RunService")
local lp = game:GetService("Players").LocalPlayer
local mouse = lp:GetMouse()

function protectUI(sGui)
    local function blankfunction(...)
        return ...
    end

    local cloneref = cloneref or blankfunction

    local function SafeGetService(service)
        return cloneref(game:GetService(service)) or game:GetService(service)
    end

    local cGUI = SafeGetService("CoreGui")
    local rPlr = SafeGetService("Players"):FindFirstChildWhichIsA("Player")
    local cGUIProtect = {}
    local rService = SafeGetService("RunService")
    local lPlr = SafeGetService("Players").LocalPlayer

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

    if (get_hidden_gui or gethui) then
        local hiddenUI = (get_hidden_gui or gethui)
        NAProtection(sGui)
        sGui.Parent = hiddenUI()
        return sGui
    elseif (not is_sirhurt_closure) and (syn and syn.protect_gui) then
        NAProtection(sGui)
        syn.protect_gui(sGui)
        sGui.Parent = cGUI
        return sGui
    elseif cGUI:FindFirstChildWhichIsA("ScreenGui") then
        pcall(function()
            for _, v in pairs(sGui:GetDescendants()) do
                cGUIProtect[v] = rPlr.Name
            end
            sGui.DescendantAdded:Connect(function(v)
                cGUIProtect[v] = rPlr.Name
            end)
            cGUIProtect[sGui] = rPlr.Name

            local meta = getrawmetatable(game)
            local tostr = meta.__tostring
            setreadonly(meta, false)
            meta.__tostring = newcclosure(function(t)
                if cGUIProtect[t] and not checkcaller() then
                    return cGUIProtect[t]
                end
                return tostr(t)
            end)
        end)
        if not rService:IsStudio() then
            local newGui = cGUI:FindFirstChildWhichIsA("ScreenGui")
            newGui.DescendantAdded:Connect(function(v)
                cGUIProtect[v] = rPlr.Name
            end)
            for _, v in pairs(sGui:GetChildren()) do
                v.Parent = newGui
            end
            sGui = newGui
        end
        return sGui
    elseif cGUI then
        NAProtection(sGui)
        sGui.Parent = cGUI
        return sGui
    elseif lPlr and lPlr:FindFirstChild("PlayerGui") then
        NAProtection(sGui)
        sGui.Parent = lPlr:FindFirstChild("PlayerGui")
        return sGui
    else
        return nil
    end
end

local ScreenGui = Instance.new("ScreenGui")
protectUI(ScreenGui)

local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Size = UDim2.new(0, 200, 0, 50)
ToggleButton.Position = UDim2.new(0.5, -100, 0, 10)
ToggleButton.Text = "Toggle Axes: OFF"
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.TextSize = 20
ToggleButton.BorderSizePixel = 2
ToggleButton.BorderColor3 = Color3.new(0, 0, 0)
ToggleButton.AutoButtonColor = false

local UICorner = Instance.new("UICorner", ToggleButton)
UICorner.CornerRadius = UDim.new(0, 10)

local function NAdrag(ui, dragui)
    if not dragui then dragui = ui end
    local UserInputService = game:GetService("UserInputService")

    local dragging
    local dragInput
    local dragStart
    local startPos

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

NAdrag(ToggleButton)

local scriptEnabled = false

ToggleButton.MouseButton1Click:Connect(function()
    scriptEnabled = not scriptEnabled
    if scriptEnabled then
        ToggleButton.Text = "Toggle Axes: ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    else
        ToggleButton.Text = "Toggle Axes: OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    end
end)

local function CustomClick(onClick)
    local initialMousePosition = nil
    local dragThreshold = 10

    mouse.Button1Down:Connect(function()
        initialMousePosition = Vector2.new(mouse.X, mouse.Y)
    end)

    mouse.Button1Up:Connect(function()
        if initialMousePosition then
            local currentMousePosition = Vector2.new(mouse.X, mouse.Y)
            local distance = (currentMousePosition - initialMousePosition).Magnitude

            if distance <= dragThreshold then
                onClick(mouse)
            end
        end
        initialMousePosition = nil
    end)
end

local function mainScript()
    runservice.Stepped:Connect(function()
        if scriptEnabled then
            fireclickdetector(tpp)
        end
    end)

    lp.Backpack.ChildRemoved:Connect(function(hh)
        if scriptEnabled and hh:IsA("Tool") and hh.Name == "Axe" then
            fireclickdetector(tpp)
        end
    end)

    lp.CharacterAdded:Connect(function(hhh)
        fireclickdetector(tpp)
        lp.Backpack.ChildRemoved:Connect(function(hb)
            if scriptEnabled and hb:IsA("Tool") and hb.Name == "Axe" then
                fireclickdetector(tpp)
            end
        end)
    end)

    CustomClick(function()
        if scriptEnabled and lp.Character then
            for i, v in pairs(lp.Character:GetChildren()) do
                if v:IsA("Tool") and v.Name == "Axe" and v:FindFirstChild("ServerControl") then
                    coroutine.wrap(function()
                        v.ServerControl:InvokeServer("Click", true, mouse.Hit.p)
                    end)()
                end
            end
        elseif scriptEnabled then
            lp.CharacterAdded:Wait()
            for i, v in pairs(lp.Character:GetChildren()) do
                if v:IsA("Tool") and v.Name == "Axe" and v:FindFirstChild("ServerControl") then
                    coroutine.wrap(function()
                        v.ServerControl:InvokeServer("Click", true, mouse.Hit.p)
                    end)()
                end
            end
        end
    end)

    mouse.KeyDown:Connect(function(key)
        if scriptEnabled and key:lower() == "q" and lp.Backpack ~= nil then
            for i, v in pairs(lp.Backpack:GetChildren()) do
                coroutine.wrap(function()
                    if v.Name == "Axe" and v:IsA("Tool") then
                        v.Parent = lp.Character
                    end
                end)()
            end
        end
    end)

    lp.Backpack.ChildAdded:Connect(function(hh)
        if scriptEnabled and hh:IsA("Tool") and hh.Name == "Axe" then
            runservice.Stepped:Wait()
            hh.Parent = game:GetService("Players").LocalPlayer.Character
        end
    end)

    lp.CharacterAdded:Connect(function(hb)
        lp.Backpack.ChildAdded:Connect(function(hh)
            if scriptEnabled and hh:IsA("Tool") and hh.Name == "Axe" then
                runservice.Stepped:Wait()
                hh.Parent = game:GetService("Players").LocalPlayer.Character
            end
        end)
    end)
end

mainScript()
end