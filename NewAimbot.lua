local connectionStorage = {}

local function ClonedService(name)
    local service = (cloneref and cloneref(game:GetService(name))) or game:GetService(name)
    return service
end

local Players = ClonedService("Players")
local RunService = ClonedService("RunService")
local UserInputService = ClonedService("UserInputService")
local TweenService = ClonedService("TweenService")
local ContextActionService = ClonedService("ContextActionService")
local ScreenPath = gethui and gethui() or (ClonedService("CoreGui") or ClonedService("Players").LocalPlayer:WaitForChild("PlayerGui"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = player:GetMouse()
local target = nil
local isLocking = false
local isEnabled = false
local lockToHead = false
local espEnabled = false
local lockOnSmoothness = 0.000
local lockToNearest = false
local wallCheck = true
local teamCheck = false
local aliveCheck = false
local isDragging = false
local dragStart = nil
local startPos = nil
local Mode = "FFA"
local LastMode = nil

local espHighlights = {}

local screenGui = nil

function cleanupExistingUI()
    for _, gui in pairs(ScreenPath:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name == "CameraLockUI" then
            gui:Destroy()
        end
    end
end

function createRoundedCorners(parent, radius)
    local corner = Instance.new("UICorner", parent)
    corner.CornerRadius = radius or UDim.new(0, 0)
    return corner
end

local function createUI()
    cleanupExistingUI()
    
    screenGui = Instance.new("ScreenGui", ScreenPath)
    screenGui.Name = "CameraLockUI"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false

    local frame = Instance.new("Frame", screenGui)
    frame.Size = UDim2.new(0, 600, 0, 250)
    frame.Position = UDim2.new(0.5, -300, -0.3, 0)
    frame.BackgroundColor3 = Color3.fromRGB(240, 240, 247)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true

    local frameCorner = createRoundedCorners(frame, UDim.new(0.04, 0))

    local titleBar = Instance.new("Frame", frame)
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(230, 230, 235)
    titleBar.BorderSizePixel = 0

    local titleCorner = createRoundedCorners(titleBar, UDim.new(0.04, 0))

    local titleText = Instance.new("TextLabel", titleBar)
    titleText.Size = UDim2.new(0, 200, 0, 30)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.Text = "Aimbot"
    titleText.TextColor3 = Color3.fromRGB(80, 80, 80)
    titleText.BackgroundTransparency = 1
    titleText.Font = Enum.Font.GothamSemibold
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left

    local closeButton = Instance.new("TextButton", titleBar)
    closeButton.Size = UDim2.new(0, 15, 0, 15)
    closeButton.Position = UDim2.new(0.97, -10, 0.5, -7.5)
    closeButton.Text = ""
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 95, 90)
    closeButton.BorderSizePixel = 0
    closeButton.AutoButtonColor = false

    local minimizeButton = Instance.new("TextButton", titleBar)
    minimizeButton.Size = UDim2.new(0, 15, 0, 15)
    minimizeButton.Position = UDim2.new(0.90, -10, 0.5, -7.5)
    minimizeButton.Text = ""
    minimizeButton.BackgroundColor3 = Color3.fromRGB(255, 189, 68)
    minimizeButton.BorderSizePixel = 0
    minimizeButton.AutoButtonColor = false

    createRoundedCorners(closeButton, UDim.new(1, 0))
    createRoundedCorners(minimizeButton, UDim.new(1, 0))

    local leftToggles = {
        {name = "Lock to Torso", pos = 0.25, var = "isEnabled"},
        {name = "Lock to Head", pos = 0.50, var = "lockToHead"},
        {name = "ESP", pos = 0.75, var = "espEnabled"},
    }

    local rightToggles = {
        {name = "Lock to Nearest", pos = 0.50, var = "lockToNearest"}
    }

    local bottomToggles = {
        {name = "Alive Check", pos = 0.5, var = "aliveCheck"},
    }

    for _, toggleData in pairs(leftToggles) do
        local yPos = toggleData.pos
        
        local toggleBG = Instance.new("Frame", frame)
        toggleBG.Size = UDim2.new(0, 54, 0, 28)
        toggleBG.Position = UDim2.new(0.12, 0, yPos, 0)
        toggleBG.BackgroundColor3 = Color3.fromRGB(220, 220, 225)
        toggleBG.BorderSizePixel = 0
        
        local toggleBtn = Instance.new("TextButton", toggleBG)
        toggleBtn.Size = UDim2.new(0, 26, 0, 26)
        toggleBtn.Position = UDim2.new(0, 1, 0.5, -13)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.Text = ""
        toggleBtn.BorderSizePixel = 0
        toggleBtn.AutoButtonColor = false
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(0, 200, 0, 20)
        label.Position = UDim2.new(0.22, 0, yPos, 4)
        label.Text = toggleData.name
        label.TextColor3 = Color3.fromRGB(80, 80, 80)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        toggleData.bg = toggleBG
        toggleData.btn = toggleBtn
        
        createRoundedCorners(toggleBG, UDim.new(1, 0))
        createRoundedCorners(toggleBtn, UDim.new(1, 0))
        
        if _G[toggleData.var] then
            animateToggle(toggleBtn, toggleBG, true)
        end
    end

    for _, toggleData in pairs(rightToggles) do
        local yPos = toggleData.pos
        
        local toggleBG = Instance.new("Frame", frame)
        toggleBG.Size = UDim2.new(0, 54, 0, 28)
        toggleBG.Position = UDim2.new(0.62, 0, yPos, 0)
        toggleBG.BackgroundColor3 = Color3.fromRGB(220, 220, 225)
        toggleBG.BorderSizePixel = 0
        
        local toggleBtn = Instance.new("TextButton", toggleBG)
        toggleBtn.Size = UDim2.new(0, 26, 0, 26)
        toggleBtn.Position = UDim2.new(0, 1, 0.5, -13)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.Text = ""
        toggleBtn.BorderSizePixel = 0
        toggleBtn.AutoButtonColor = false
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(0, 200, 0, 20)
        label.Position = UDim2.new(0.72, 0, yPos, 4)
        label.Text = toggleData.name
        label.TextColor3 = Color3.fromRGB(80, 80, 80)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        toggleData.bg = toggleBG
        toggleData.btn = toggleBtn
        
        createRoundedCorners(toggleBG, UDim.new(1, 0))
        createRoundedCorners(toggleBtn, UDim.new(1, 0))
        
        if _G[toggleData.var] then
            animateToggle(toggleBtn, toggleBG, true)
        end
    end

    for _, toggleData in pairs(bottomToggles) do
        local toggleBG = Instance.new("Frame", frame)
        toggleBG.Size = UDim2.new(0, 54, 0, 28)
        toggleBG.Position = UDim2.new(0.37, 0, 0.9, -37)
        toggleBG.BackgroundColor3 = Color3.fromRGB(220, 220, 225)
        toggleBG.BorderSizePixel = 0
        
        local toggleBtn = Instance.new("TextButton", toggleBG)
        toggleBtn.Size = UDim2.new(0, 26, 0, 26)
        toggleBtn.Position = UDim2.new(0, 1, 0.5, -13)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.Text = ""
        toggleBtn.BorderSizePixel = 0
        toggleBtn.AutoButtonColor = false
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(0, 200, 0, 20)
        label.Position = UDim2.new(0.47, 0, 0.9, -33)
        label.Text = toggleData.name
        label.TextColor3 = Color3.fromRGB(80, 80, 80)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        
        toggleData.bg = toggleBG
        toggleData.btn = toggleBtn
        
        createRoundedCorners(toggleBG, UDim.new(1, 0))
        createRoundedCorners(toggleBtn, UDim.new(1, 0))
        
        if _G[toggleData.var] then
            animateToggle(toggleBtn, toggleBG, true)
        end
    end

    local minimizeButtonConn = minimizeButton.MouseButton1Click:Connect(function()
        isUIMinimized = true
        
        TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), 
            {Position = UDim2.new(0.5, -300, -0.5, 0)}):Play()
        showNotification("UI minimized - Press Right Alt to reopen")
    end)
    table.insert(connectionStorage, minimizeButtonConn)

    local closeButtonConn = closeButton.MouseButton1Click:Connect(function()
        for _, connection in pairs(connectionStorage) do
            if typeof(connection) == "RBXScriptConnection" and connection.Connected then 
                connection:Disconnect() 
            end
        end
        connectionStorage = {}
        
        isLocking = false
        _G.isEnabled = false
        _G.lockToHead = false
        _G.espEnabled = false
        _G.lockToNearest = false
        _G.aliveCheck = false
        
        for _, highlight in pairs(espHighlights) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
        end
        espHighlights = {}
        
        ContextActionService:UnbindAction("CameraLock")
        
        showNotification("Camera Lock unloaded successfully")
        
        spawn(function()
            wait(0.5)
            if screenGui and screenGui.Parent then
                screenGui:Destroy()
            end
        end)
    end)
    table.insert(connectionStorage, closeButtonConn)

    local titleBarInputBeganConn = titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    table.insert(connectionStorage, titleBarInputBeganConn)

    local titleBarInputEndedConn = titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    table.insert(connectionStorage, titleBarInputEndedConn)

    local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and isDragging then
            local delta = input.Position - dragStart
            TweenService:Create(frame, TweenInfo.new(0.1), {
                Position = UDim2.new(
                    startPos.X.Scale, 
                    startPos.X.Offset + delta.X, 
                    startPos.Y.Scale, 
                    startPos.Y.Offset + delta.Y
                )
            }):Play()
        end
    end)
    table.insert(connectionStorage, inputChangedConn)
    
    local allToggles = {}
    for _, v in pairs(leftToggles) do table.insert(allToggles, v) end
    for _, v in pairs(rightToggles) do table.insert(allToggles, v) end
    for _, v in pairs(bottomToggles) do table.insert(allToggles, v) end

    for _, toggleData in pairs(allToggles) do
        if _G[toggleData.var] == nil then
            _G[toggleData.var] = false
        end
        
        local toggleConn = toggleData.btn.MouseButton1Click:Connect(function()
            _G[toggleData.var] = not _G[toggleData.var]
            animateToggle(toggleData.btn, toggleData.bg, _G[toggleData.var])
            
            if toggleData.var == "espEnabled" then
                updateESP()
            end
        end)
        
        table.insert(connectionStorage, toggleConn)
    end

    frame.Position = UDim2.new(0.5, -300, -0.5, 0)
    TweenService:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
        {Position = UDim2.new(0.5, -300, 0.05, 0)}):Play()
    
    return frame
end

function animateToggle(toggleBtn, toggleBG, state)
    TweenService:Create(toggleBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = state and UDim2.new(1, -27, 0.5, -13) or UDim2.new(0, 1, 0.5, -13)
    }):Play()
    
    TweenService:Create(toggleBG, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        BackgroundColor3 = state and Color3.fromRGB(0, 122, 255) or Color3.fromRGB(220, 220, 225)
    }):Play()
end

function updateESP()
    for _, highlight in pairs(espHighlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    espHighlights = {}

    if _G.espEnabled then
        for _, otherPlayer in pairs(Players:GetPlayers()) do
            if otherPlayer ~= player and otherPlayer.Character then
                local character = otherPlayer.Character
                local humanoid = character:FindFirstChildOfClass("Humanoid")

                if _G.aliveCheck and (not humanoid or humanoid.Health <= 0) then
                    continue
                end

                if humanoid and humanoid.Health > 0 then
                    if not isEnemy(otherPlayer) then
                        continue
                    end
                    
                    local highlight = Instance.new("Highlight")
                    highlight.FillColor = Color3.fromRGB(128, 0, 255)
                    highlight.OutlineColor = Color3.fromRGB(200, 0, 255)
                    highlight.FillTransparency = 0.3
                    highlight.OutlineTransparency = 0.1
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Adornee = character
                    highlight.Parent = screenGui
                    
                    table.insert(espHighlights, highlight)
                    
                    local healthLabel = Instance.new("BillboardGui")
                    healthLabel.Size = UDim2.new(0, 100, 0, 40)
                    healthLabel.StudsOffset = Vector3.new(0, 3, 0)
                    healthLabel.Adornee = character:FindFirstChild("Head")
                    healthLabel.AlwaysOnTop = true
                    healthLabel.Parent = screenGui
                    
                    local healthText = Instance.new("TextLabel", healthLabel)
                    healthText.Size = UDim2.new(1, 0, 1, 0)
                    healthText.BackgroundTransparency = 1
                    healthText.Text = otherPlayer.Name .. "\nHP: " .. math.floor(humanoid.Health)
                    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
                    healthText.TextStrokeTransparency = 0.5
                    healthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    healthText.Font = Enum.Font.GothamBold
                    healthText.TextSize = 14
                    
                    table.insert(espHighlights, healthLabel)
                    
                    local healthConn = humanoid.HealthChanged:Connect(function()
                        if healthText and healthText.Parent then
                            healthText.Text = otherPlayer.Name .. "\nHP: " .. math.floor(humanoid.Health)
                            
                            if _G.aliveCheck and humanoid.Health <= 0 then
                                if highlight and highlight.Parent then
                                    highlight:Destroy()
                                end
                                if healthLabel and healthLabel.Parent then
                                    healthLabel:Destroy()
                                end
                            end
                        end
                    end)
                    
                    table.insert(connectionStorage, healthConn)
                end
            end
        end
    end
end

function isEnemy(otherPlayer)
    if Mode == "FFA" then
        return true
    else
        return otherPlayer.Team ~= nil and player.Team ~= nil and otherPlayer.Team ~= player.Team
    end
end

function isAlive(character)
    if not _G.aliveCheck then return true end
    if not character then return false end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

function findTarget()
    local nearest = nil
    local minDist = math.huge

    for _, otherPlayer in pairs(Players:GetPlayers()) do
        if otherPlayer ~= player and otherPlayer.Character and isEnemy(otherPlayer) then
            local character = otherPlayer.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            
            if not isAlive(character) then 
                continue 
            end
            
            if humanoid and humanoid.Health > 0 then
                local targetPart = _G.lockToHead and character:FindFirstChild("Head") 
                               or character:FindFirstChild("HumanoidRootPart")

                if targetPart then
                    local screenPos, onScreen = camera:WorldToScreenPoint(targetPart.Position)
                    
                    if onScreen then
                        local actualDistance = (targetPart.Position - camera.CFrame.Position).Magnitude
                        
                        local mousePos = Vector2.new(mouse.X, mouse.Y)
                        local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        
                        if _G.lockToNearest then
                            if actualDistance < minDist then
                                minDist = actualDistance
                                nearest = character
                            end
                        else
                            if screenDistance < 150 and screenDistance < minDist then
                                minDist = screenDistance
                                nearest = character
                            end
                        end
                    end
                end
            end
        end
    end
    return nearest
end

local lockCameraActive = false
function lockCamera()
    if lockCameraActive then return end
    lockCameraActive = true
    
    local cameraLockLoop
    cameraLockLoop = RunService.RenderStepped:Connect(function()
        if not isLocking or not _G.isEnabled then
            cameraLockLoop:Disconnect()
            lockCameraActive = false
            return
        end
        
        local targetCharacter = findTarget()
        if targetCharacter then
            local targetPart = _G.lockToHead and targetCharacter:FindFirstChild("Head") 
                           or targetCharacter:FindFirstChild("HumanoidRootPart")
            
            if targetPart then
                local newCFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
                if (camera.CFrame.LookVector - newCFrame.LookVector).Magnitude > 0.01 then
                    TweenService:Create(camera, TweenInfo.new(lockOnSmoothness), {CFrame = newCFrame}):Play()
                else
                    camera.CFrame = newCFrame
                end
            end
        end
    end)
    
    table.insert(connectionStorage, cameraLockLoop)
end

function showNotification(message)
    local notification = Instance.new("Frame", screenGui)
    notification.Size = UDim2.new(0, 240, 0, 40)
    notification.Position = UDim2.new(0.5, -120, 0.9, 0)
    notification.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    notification.BackgroundTransparency = 0.6
    notification.BorderSizePixel = 0
    
    createRoundedCorners(notification, UDim.new(0.2, 0))

    local textLabel = Instance.new("TextLabel", notification)
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.Text = message
    textLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 14
    textLabel.TextWrapped = true

    notification.Position = UDim2.new(0.5, -120, 1.1, 0)
    local notifTween = TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
        {Position = UDim2.new(0.5, -120, 0.9, 0)}):Play()
    
    spawn(function()
        wait(3)
        TweenService:Create(notification, TweenInfo.new(0.5, Enum.EasingStyle.Quad), 
            {Position = UDim2.new(0.5, -120, 1.1, 0), BackgroundTransparency = 1}):Play()
        wait(0.5)
        notification:Destroy()
    end)
end

local function setupKeybinds()
    local isUIMinimized = false

    local inputBeganConn = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 and _G.isEnabled then
            isLocking = true
            lockCamera()
        elseif input.KeyCode == Enum.KeyCode.RightAlt then
            if isUIMinimized then
                TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
                    {Position = UDim2.new(0.5, -300, 0.05, 0)}):Play()
                isUIMinimized = false
            else
                TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), 
                    {Position = UDim2.new(0.5, -300, -0.5, 0)}):Play()
                isUIMinimized = true
                showNotification("UI minimized - Press Right Alt to reopen")
            end
        end
    end)
    table.insert(connectionStorage, inputBeganConn)

    local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            isLocking = false
        end
    end)
    table.insert(connectionStorage, inputEndedConn)
end

function setupPlayerMonitoring()
    local playerAddedConn = Players.PlayerAdded:Connect(function()
        if _G.espEnabled then
            updateESP()
        end
    end)
    table.insert(connectionStorage, playerAddedConn)
    
    local playerRemovingConn = Players.PlayerRemoving:Connect(function()
        if _G.espEnabled then
            updateESP()
        end
    end)
    table.insert(connectionStorage, playerRemovingConn)
    
    local characterAddedConn = player.CharacterAdded:Connect(function()
        if not screenGui or not screenGui.Parent then
            frame = createUI()
            setupKeybinds()
        end
        
        if _G.espEnabled then
            updateESP()
        end
    end)
    table.insert(connectionStorage, characterAddedConn)
end

frame = createUI()
setupKeybinds()
setupPlayerMonitoring()

if _G.espEnabled then
    updateESP()
end

showNotification("Camera Lock loaded successfully")

local function CheckMode()
    if #Players:GetPlayers() > 0 and Players.LocalPlayer.Team == nil then
        Mode = "FFA"
    else
        Mode = "Team"
    end

    if Mode ~= LastMode then
        LastMode = Mode
    end
end

local teamCon = RunService.RenderStepped:Connect(function()
    CheckMode()
end)

table.insert(connectionStorage, teamCon)

return function()
    for _, connection in pairs(connectionStorage) do
        if typeof(connection) == "RBXScriptConnection" and connection.Connected then 
            connection:Disconnect() 
        end
    end
    
    for _, highlight in pairs(espHighlights) do
        if highlight and highlight.Parent then
            highlight:Destroy()
        end
    end
    
    if screenGui and screenGui.Parent then
        screenGui:Destroy()
    end
end