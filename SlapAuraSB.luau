if game.GameId ~= 2380077519 then return 'wrong game buddy' end

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local StarterGui        = game:GetService("StarterGui")

local localPlayer    = Players.LocalPlayer
local forbiddenNames = { "disarmh", "b", "htstun" }
local attackRemotes  = {}
local ghostRemote    = ReplicatedStorage:WaitForChild("Ghostinvisibilityactivated")
local radius, delay  = 20, 0.7
local rootPart, aura
local ignoreFriends  = false

for _, desc in ipairs(ReplicatedStorage:GetDescendants()) do
    if desc:IsA("RemoteEvent") then
        local lname = desc.Name:lower()
        if lname:find("hit") then
            table.insert(attackRemotes, desc)
        else
            for _, forbidden in ipairs(forbiddenNames) do
                if lname == forbidden then
                    table.insert(attackRemotes, desc)
                    break
                end
            end
        end
    end
end

local function getRootPart(character)
    return character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChild("Torso")
end

local function createAura()
    if aura then aura:Destroy() end
    aura = Instance.new("Part", workspace)
    aura.Name         = "Aura"
    aura.Shape        = Enum.PartType.Ball
    aura.Anchored     = true
    aura.CanCollide   = false
    aura.CastShadow   = false
    aura.Material     = Enum.Material.SmoothPlastic
    aura.Transparency = 0.9
    aura.Size         = Vector3.new(radius*2, radius*2, radius*2)
end

local function onCharacterAdded(char)
    local root = char:WaitForChild("HumanoidRootPart", 5) or char:WaitForChild("Torso", 5)
    if not root then return end
    rootPart = root
    createAura()
end

local function onCharacterRemoving()
    if aura then aura:Destroy() end
    rootPart, aura = nil, nil
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)
localPlayer.CharacterRemoving:Connect(onCharacterRemoving)
if localPlayer.Character then
    onCharacterAdded(localPlayer.Character)
end

local guiParent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui") or localPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui", guiParent)
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size               = UDim2.new(0, 120, 0, 200)
mainFrame.Position           = UDim2.new(0.5, -60, 0, 50)
mainFrame.BackgroundTransparency = 1
mainFrame.Active             = true

local verticalLayout = Instance.new("UIListLayout", mainFrame)
verticalLayout.FillDirection       = Enum.FillDirection.Vertical
verticalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
verticalLayout.SortOrder           = Enum.SortOrder.LayoutOrder
verticalLayout.Padding             = UDim.new(0, 5)

local function makeTextBox(default)
    local tb = Instance.new("TextBox", mainFrame)
    tb.Size            = UDim2.new(0, 100, 0, 30)
    tb.BackgroundColor3= Color3.new(0, 0, 0)
    tb.TextColor3      = Color3.new(1, 1, 1)
    tb.PlaceholderText = tostring(default)
    tb.Text            = tostring(default)
    tb.ClearTextOnFocus= false
    tb.TextScaled      = true
    tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0.5, 0)
    return tb
end

local radiusBox = makeTextBox(radius)
local delayBox  = makeTextBox(delay)

local bottomFrame = Instance.new("Frame", mainFrame)
bottomFrame.Size               = UDim2.new(1, 0, 0, 40)
bottomFrame.BackgroundTransparency = 1

local horizontalLayout = Instance.new("UIListLayout", bottomFrame)
horizontalLayout.FillDirection       = Enum.FillDirection.Horizontal
horizontalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
horizontalLayout.SortOrder           = Enum.SortOrder.LayoutOrder
horizontalLayout.Padding             = UDim.new(0, 5)

local ignoreBtn = Instance.new("TextButton", bottomFrame)
ignoreBtn.Size            = UDim2.new(0, 100, 0, 30)
ignoreBtn.BackgroundColor3= Color3.new(0, 0, 0)
ignoreBtn.TextColor3      = Color3.new(1, 1, 1)
ignoreBtn.Text            = "Ignore Friends: Off"
ignoreBtn.TextScaled      = true
ignoreBtn.BorderSizePixel = 0
Instance.new("UICorner", ignoreBtn).CornerRadius = UDim.new(0.5, 0)
ignoreBtn.MouseButton1Click:Connect(function()
    ignoreFriends = not ignoreFriends
    ignoreBtn.Text = ignoreFriends
        and "Ignore Friends: On"
        or "Ignore Friends: Off"
end)

local invisBtn = Instance.new("TextButton", bottomFrame)
invisBtn.Size            = UDim2.new(0, 120, 0, 30)
invisBtn.BackgroundColor3= Color3.new(0, 0, 0)
invisBtn.TextColor3      = Color3.new(1, 1, 1)
invisBtn.Text            = "Invis (ghost hand)"
invisBtn.TextScaled      = true
invisBtn.BorderSizePixel = 0
Instance.new("UICorner", invisBtn).CornerRadius = UDim.new(0.5, 0)
invisBtn.MouseButton1Click:Connect(function()
    local stats = localPlayer:FindFirstChild("leaderstats")
    local slaps = stats and stats:FindFirstChild("Slaps")
    if slaps and slaps.Value >= 666 then
        local lobby = workspace:FindFirstChild("Lobby")
        if lobby then
            local ghost = lobby:FindFirstChild("Ghost")
            if ghost then
                local cd = ghost:FindFirstChildOfClass("ClickDetector")
                if cd then
                    fireclickdetector(cd)
                end
            end
        end
        ghostRemote:FireServer()
    else
        StarterGui:SetCore("SendNotification", {
            Title    = "Error";
            Text     = "Requires 666 slaps to use";
            Duration = 5;
        })
    end
end)

do
    local dragging, dragInput, dragStart, startPos
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local loops = {}
RunService.RenderStepped:Connect(function()
    if rootPart and aura then
        aura.CFrame = rootPart.CFrame
    end

    local newR = tonumber(radiusBox.Text)
    if newR and newR ~= radius then
        radius = newR
        createAura()
    end

    local newD = tonumber(delayBox.Text)
    if newD then
        delay = newD
    end

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= localPlayer
        and other.Character
        and rootPart
        and (not ignoreFriends or not localPlayer:IsFriendsWith(other.UserId)) then

            local rp = getRootPart(other.Character)
            local inside = rp
                and (rp.Position - rootPart.Position).Magnitude <= radius

            if inside and not loops[other] then
                loops[other] = true
                task.spawn(function()
                    while loops[other] do
                        local tp = getRootPart(other.Character)
                        if tp and (tp.Position - rootPart.Position).Magnitude <= radius then
                            for _, ev in ipairs(attackRemotes) do
                                ev:FireServer(tp)
                            end
                            task.wait(delay)
                        else
                            break
                        end
                    end
                    loops[other] = nil
                end)
            elseif loops[other] and not inside then
                loops[other] = nil
            end
        else
            loops[other] = nil
        end
    end
end)