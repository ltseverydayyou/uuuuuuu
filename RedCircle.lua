local visualizer = getgenv().visualizer or {
    Enabled = true,
    ShowDistance = true,
    Range = 60,
    Color = Color3.fromRGB(255, 60, 60),
    SpamKey = Enum.KeyCode.F,
    SpamHold = false,
}
getgenv().visualizer = visualizer

local players = game:GetService("Players")
local runService = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local vim = game:GetService("VirtualInputManager")
local stats = game:GetService("Stats")
local lp = players.LocalPlayer

local function round(num)
    return math.floor(num + 0.5)
end

local function getBall()
    local ballsFolder = workspace:FindFirstChild("Balls")
    local char = lp.Character or lp.CharacterAdded:Wait()
    local root = char:WaitForChild("HumanoidRootPart")

    local nearestModel, nearestPart, nearestDist
    if not ballsFolder then
        return
    end

    for _, model in pairs(ballsFolder:GetChildren()) do
        local part = model:FindFirstChildOfClass("Part")
        if part then
            local distance = (part.Position - root.Position).Magnitude
            if not nearestDist or distance < nearestDist then
                nearestModel, nearestPart, nearestDist = model, part, distance
            end
        end
    end

    return nearestModel, nearestPart, nearestDist, root
end

-- template part + mesh
local template = Instance.new("Part")
template.Name = "Visualizer"
template.Size = Vector3.new(30, 30, 30)
template.Anchored = true
template.CanCollide = false
template.CanQuery = false
template.CastShadow = false
template.Transparency = 0.65
template.Color = visualizer.Color

local mesh = Instance.new("SpecialMesh")
mesh.MeshType = Enum.MeshType.FileMesh
mesh.MeshId = "rbxassetid://471124075"
mesh.Scale = Vector3.new(1, 1, 1)
mesh.Parent = template

local followBall = template:Clone()
followBall.Name = "VisualizerFollowBall"
followBall.Parent = workspace
local followUnit = template:Clone()
followUnit.Name = "VisualizerFollowBallNoUnit"
followUnit.Parent = workspace

local billboard = Instance.new("BillboardGui")
billboard.Name = "Range"
billboard.Enabled = visualizer.ShowDistance
billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
billboard.Size = UDim2.new(5, 0, 2, 0)
billboard.StudsOffset = Vector3.new(0, 3.5, 0)
billboard.LightInfluence = 1
billboard.AlwaysOnTop = true
billboard.Parent = followBall

local textLabel = Instance.new("TextLabel")
textLabel.BackgroundTransparency = 1
textLabel.BorderSizePixel = 0
textLabel.Font = Enum.Font.FredokaOne
textLabel.TextWrapped = true
textLabel.TextScaled = true
textLabel.TextColor3 = visualizer.Color
textLabel.TextStrokeTransparency = 0.35
textLabel.Parent = billboard

local highlight = Instance.new("Highlight")
highlight.FillColor = visualizer.Color
highlight.OutlineColor = Color3.new(1, 1, 1)
highlight.Parent = game:GetService("CoreGui")

uis.InputBegan:Connect(function(input, gpe)
    if gpe then
        return
    end
    if input.KeyCode == visualizer.SpamKey then
        visualizer.SpamHold = not visualizer.SpamHold
    end
end)

runService.RenderStepped:Connect(function()
    if not visualizer.Enabled then
        followBall.Transparency = 1
        followUnit.Transparency = 1
        highlight.Enabled = false
        return
    end

    local model, part, dist, root = getBall()
    if not part then
        textLabel.Text = "No balls found"
        highlight.Enabled = false
        return
    end

    followBall.Transparency = 0.35
    followBall.CFrame = CFrame.new(part.Position)
    followUnit.CFrame = CFrame.lookAt(root.Position, part.Position)
    highlight.Adornee = part
    highlight.Enabled = true

    local ping = round(stats.Network.ServerStatsItem["Data Ping"]:GetValue())
    local velocity = round(part.Velocity.Magnitude)
    textLabel.Text = string.format(
        "Distance: %d\nPing: %d ms\nVelocity: %d",
        round(dist),
        ping,
        velocity
    )

    if visualizer.SpamHold and model:GetAttribute("target") then
        vim:SendKeyEvent(true, visualizer.SpamKey, false, game)
        vim:SendKeyEvent(false, visualizer.SpamKey, false, game)
    end
end)
