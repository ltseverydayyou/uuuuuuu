if getgenv().PressureBallsLoaded then return end

pcall(function() getgenv().PressureBallsLoaded = true end)

local ScreenGui = Instance.new("ScreenGui")
local ttLabel = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local rep = game:GetService("ReplicatedStorage")
local plrUI = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local isRan = false
local modulesToRestore = {}

local function restoreModule(module)
    if module then
        for _, child in pairs(module:GetChildren()) do
            restoreModule(child)
        end
        modulesToRestore[#modulesToRestore + 1] = {module, module.Parent}
        module:Remove()
    end
end

local success, errorMsg = pcall(function()
    restoreModule(rep:FindFirstChild("PermanentEyefestation", true))
    restoreModule(rep:FindFirstChild("Searchlight", true))
    restoreModule(plrUI:FindFirstChild("LocalParasites", true))
    restoreModule(plrUI:FindFirstChild("LocalSquiddles", true))
    restoreModule(plrUI:FindFirstChild("LocalEntities", true))
end)

game:GetService("Players").LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid").Died:Connect(function()
    task.spawn(function()
        for _, moduleInfo in pairs(modulesToRestore) do
            task.spawn(function()
                moduleInfo[1].Parent = moduleInfo[2]
            end)
        end
    end)
end)

if not gethui then
    getgenv().gethui = function()
        local h = game:GetService("CoreGui"):FindFirstChildWhichIsA("ScreenGui") or game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
        return h
    end
end

local function randomString(length)
    length = length or math.random(10, 20)
    local array = {}
    for i = 1, length do
        array[i] = string.char(math.random(32, 126))
    end
    return table.concat(array)
end

ScreenGui.Name = randomString()
ScreenGui.Parent = gethui()
ttLabel.Name = randomString()
ttLabel.Parent = ScreenGui
ttLabel.BackgroundColor3 = Color3.fromRGB(4, 4, 4)
ttLabel.BackgroundTransparency = 1.0
ttLabel.AnchorPoint = Vector2.new(0.5, 0.5)
ttLabel.Position = UDim2.new(0.5, 0, 0, 0)
ttLabel.Size = UDim2.new(0, 32, 0, 33)
ttLabel.Font = Enum.Font.SourceSansBold
ttLabel.Text = "God Mode (click me)"
ttLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ttLabel.TextSize = 20.0
ttLabel.TextWrapped = true
ttLabel.ZIndex = 9999

UICorner.CornerRadius = UDim.new(1, 0)
UICorner.Parent = ttLabel

local function draggable(frame)
    frame.Active = true
    frame.Draggable = true
end

local function removeKillables(eye)
    if eye.Parent == game:GetService("Workspace"):FindFirstChild("deathModel") then
        return
    end

    local lowerName = eye.Name:lower()
    if lowerName == "eyes" or lowerName == "eye" or lowerName == "damageparts" or lowerName == "damagepart" or (lowerName == "pandemonium" and eye:IsA("Part")) or lowerName == "monsterlocker" or lowerName == "tricksterroom" then
        task.wait()
        eye:Destroy()
    end
end

local function perform()
    local oldPivot = game:GetService("Players").LocalPlayer.Character:GetPivot()
    local enterFunction = nil

    for _, v in ipairs(game:GetService("Workspace"):GetDescendants()) do
        if v.Name:lower() == "locker" and (v:IsA("Model") or v:IsA("BasePart")) then
            local success, errorMsg = pcall(function()
                for _, rem in ipairs(v:GetDescendants()) do
                    if rem.Name:lower() == "enter" and rem:IsA("RemoteFunction") then
                        enterFunction = rem
                    end
                end
                if enterFunction then
                    for i = 1, 5 do
                        game:GetService("Players").LocalPlayer.Character:PivotTo(v:GetPivot())
                        enterFunction:InvokeServer("true")
                        task.wait(0.1)
                    end
                end
            end)

            if not success then
                warn("Error invoking Remote: " .. errorMsg)
            end
            game:GetService("Players").LocalPlayer.Character:PivotTo(oldPivot)
            if enterFunction then break end
        end
    end

    task.wait(0.5)

    local success, errorMsg = pcall(function()
        game:GetService("Players").LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid").WalkSpeed = 20
    end)
    if not success then warn("No humanoid") end

    local eBorder = plrUI:FindFirstChild("EntityBorder", true)
    if eBorder then
        eBorder:GetPropertyChangedSignal("Visible"):Connect(function()
            if eBorder.Visible then eBorder.Visible = false end
        end)
    end

    for _, g in ipairs(game:GetService("Workspace"):GetDescendants()) do
        removeKillables(g)
    end

    if not isRan then
        isRan = true
        game:GetService("Workspace").DescendantAdded:Connect(removeKillables)
    end
end

local function initializeUI()
    local txtlabel = ttLabel
    txtlabel.Size = UDim2.new(0, 32, 0, 33)
    txtlabel.BackgroundTransparency = 0.14
    local textWidth = game:GetService("TextService"):GetTextSize(txtlabel.Text, txtlabel.TextSize, txtlabel.Font, Vector2.new(math.huge, math.huge)).X
    local newSize = UDim2.new(0, textWidth + 69, 0, 33)
    txtlabel:TweenSize(newSize, "Out", "Quint", 1, true)
    txtlabel.MouseButton1Click:Connect(function()
        spawn(perform)
    end)
    draggable(txtlabel)
end

coroutine.wrap(initializeUI)()