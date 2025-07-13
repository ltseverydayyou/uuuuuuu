local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local radius = 150
local CLONE_RATE = 0.2
local zoomDist, zoomHeight, headOff = 35, 30, 3
local rayEnabled, overhead = true, false

local elapsed = 0
local clones = {}

local function getRoot()
    local c = player.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp end
    if c.PrimaryPart then return c.PrimaryPart end
    for _,v in ipairs(c:GetChildren()) do
        if v:IsA("BasePart") then return v end
    end
end

local screenGui = Instance.new("ScreenGui", gethui())
screenGui.Name = "MiniMapGui"

local container = Instance.new("Frame", screenGui)
container.AnchorPoint = Vector2.new(1,0)
container.Position = UDim2.new(0.95,0,0.05,0)
container.Size = UDim2.new(0,200,0,200)
container.BackgroundColor3 = Color3.fromRGB(30,30,30)
container.BackgroundTransparency = 0.2
container.Active = true
Instance.new("UICorner", container).CornerRadius = UDim.new(0,5)

local viewport = Instance.new("ViewportFrame", container)
viewport.Size = UDim2.new(1,0,1,0)
viewport.BackgroundTransparency = 1

local worldModel = Instance.new("WorldModel", viewport)
local cloneRoot = Instance.new("Model", worldModel)

local camera = Instance.new("Camera", viewport)
viewport.CurrentCamera = camera
camera.FieldOfView = 70

local lightPart = Instance.new("Part", worldModel)
lightPart.Size = Vector3.new(1,1,1)
lightPart.Transparency = 1
lightPart.Anchored = true
lightPart.CanCollide = false
Instance.new("PointLight", lightPart).Brightness = 2

local marker = Instance.new("Part", worldModel)
marker.Size = Vector3.new(1,2,1)
marker.Anchored = true
marker.CanCollide = false
marker.Material = Enum.Material.Neon
marker.Color = Color3.new(1,0,0)
local msh = Instance.new("SpecialMesh", marker)
msh.MeshType = Enum.MeshType.Sphere
msh.Scale = Vector3.new(0.5,1,0.5)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.IgnoreWater = true

local function subscribeProps(orig, cp)
    for _,p in ipairs({"Size","Transparency","Color","BrickColor","Material","Reflectance","CastShadow","Anchored","CanCollide","CFrame"}) do
        orig:GetPropertyChangedSignal(p):Connect(function() cp[p] = orig[p] end)
    end
    if orig:IsA("MeshPart") then
        orig:GetPropertyChangedSignal("MeshId"):Connect(function() cp.MeshId = orig.MeshId end)
        orig:GetPropertyChangedSignal("TextureID"):Connect(function() cp.TextureID = orig.TextureID end)
    end
end

local function addClone(p)
    if clones[p] then return end
    local root = getRoot()
    if not root then return end
    if (p.Position - root.Position).Magnitude > radius then return end
    p.Archivable = true
    for _,d in ipairs(p:GetDescendants()) do d.Archivable = true end
    local ok, cp = pcall(function() return p:Clone() end)
    if ok and cp then
        clones[p] = cp
        cp.Parent = cloneRoot
        cp.CFrame = p.CFrame
        subscribeProps(p, cp)
    end
end

local function removeClone(p)
    local cp = clones[p]
    if cp then cp:Destroy() end
    clones[p] = nil
end

for _,p in ipairs(Workspace:GetDescendants()) do
    if p:IsA("BasePart") then addClone(p) end
end
Workspace.DescendantAdded:Connect(function(o) if o:IsA("BasePart") then addClone(o) end end)
Workspace.DescendantRemoving:Connect(function(o) if clones[o] then removeClone(o) end end)

local function refreshClones()
    local root = getRoot()
    if not root then return end
    for p,_ in pairs(clones) do
        if not p.Parent or (p.Position - root.Position).Magnitude > radius then
            removeClone(p)
        end
    end
    for _,p in ipairs(Workspace:GetDescendants()) do
        if p:IsA("BasePart") then addClone(p) end
    end
    for p,cp in pairs(clones) do
        cp.CFrame = p.CFrame
    end
end

local renderLabel = Instance.new("TextLabel", container)
renderLabel.Size = UDim2.new(1,0,0,18)
renderLabel.Position = UDim2.new(0,0,1,-18)
renderLabel.BackgroundTransparency = 1
renderLabel.TextColor3 = Color3.new(1,1,1)
renderLabel.TextScaled = true
renderLabel.Text = "R: "..radius

local function style(b)
    b.BackgroundColor3 = Color3.fromRGB(50,50,50)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.SourceSansSemibold
    b.TextScaled = true
    b.AutoButtonColor = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
end

local dragBtn = Instance.new("TextButton", container)
dragBtn.Text = "⇅"
dragBtn.Size = UDim2.new(0,24,0,24)
dragBtn.Position = UDim2.new(0,8,0,8)
style(dragBtn)

local closeBtn = Instance.new("TextButton", container)
closeBtn.Text = "X"
closeBtn.Size = UDim2.new(0,24,0,24)
closeBtn.AnchorPoint = Vector2.new(1,0)
closeBtn.Position = UDim2.new(1,-8,0,8)
style(closeBtn)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

local menuBtn = Instance.new("TextButton", container)
menuBtn.Text = ":"
menuBtn.Size = UDim2.new(0,24,0,24)
menuBtn.AnchorPoint = Vector2.new(1,0)
menuBtn.Position = UDim2.new(1,-40,0,8)
style(menuBtn)

local specs = {
    {"+", function() zoomDist = math.max(5,zoomDist-5); zoomHeight = math.max(5,zoomHeight-5) end},
    {"–", function() zoomDist = zoomDist+5; zoomHeight = zoomHeight+5 end},
    {"Ray:On", function(b) rayEnabled = not rayEnabled; b.Text = rayEnabled and "Ray:On" or "Ray:Off" end},
    {"3D", function(b) overhead = not overhead; b.Text = overhead and "Top" or "3D" end},
    {"S+", function() TweenService:Create(container, TweenInfo.new(0.25), {Size = container.Size + UDim2.new(0,50,0,50)}):Play() end},
    {"S-", function() local w = math.max(50,container.Size.X.Offset-50); local h = math.max(50,container.Size.Y.Offset-50); TweenService:Create(container, TweenInfo.new(0.25), {Size = UDim2.new(container.Size.X.Scale,w,container.Size.Y.Scale,h)}):Play() end},
    {"R+", function(b) radius = radius + 25; renderLabel.Text = "R: "..radius end},
    {"R-", function(b) radius = math.max(0,radius-25); renderLabel.Text = "R: "..radius end},
}

local buttons = {}
for _,sp in ipairs(specs) do
    local b = Instance.new("TextButton", container)
    b.Text = sp[1]
    style(b)
    b.Size = UDim2.new(0,(#sp[1]>1 and #sp[1]*12 or 24),0,24)
    b.Visible = false
    b.MouseButton1Click:Connect(function() sp[2](b) end)
    buttons[#buttons+1] = b
end

local function updateButtons()
    local total = #buttons*24 + (#buttons-1)*4
    local startY = (container.Size.Y.Offset - total)/2
    for i,b in ipairs(buttons) do
        local pos = UDim2.new(1,4,0,startY + (i-1)*28)
        TweenService:Create(b, TweenInfo.new(0.25), {Position = pos}):Play()
    end
end

menuBtn.MouseButton1Click:Connect(function()
    local show = not buttons[1].Visible
    for _,b in ipairs(buttons) do
        b.Visible = show
        if show then
            b.Position = UDim2.new(1,4,0,container.Size.Y.Offset/2)
            TweenService:Create(b, TweenInfo.new(0.25), {TextTransparency=0}):Play()
        else
            local t = TweenService:Create(b, TweenInfo.new(0.25), {TextTransparency=1})
            t:Play()
            t.Completed:Connect(function() b.Visible = false end)
        end
    end
    if show then updateButtons() end
end)

do
    local dragging, inputRef, startPos, startScale = false, nil, Vector2.new(), Vector2.new()
    dragBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            inputRef = i
            startPos = i.Position
            startScale = Vector2.new(container.Position.X.Scale, container.Position.Y.Scale)
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    dragBtn.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            inputRef = i
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i == inputRef then
            local delta = i.Position - startPos
            container.Position = UDim2.new(
                startScale.X + delta.X / container.Parent.AbsoluteSize.X, 0,
                startScale.Y + delta.Y / container.Parent.AbsoluteSize.Y, 0
            )
            updateButtons()
        end
    end)
    container.Active = true
end

RunService.RenderStepped:Connect(function(dt)
    elapsed = elapsed + dt
    if elapsed >= CLONE_RATE then
        refreshClones()
        elapsed = 0
    end
    local root = getRoot()
    if root then
        marker.CFrame = CFrame.new(root.Position + Vector3.new(0,1,0))
        lightPart.CFrame = cloneRoot:GetBoundingBox()
        local focus = root.Position + Vector3.new(0,headOff,0)
        if overhead then
            local look = Workspace.CurrentCamera.CFrame.LookVector
            look = Vector3.new(look.X,0,look.Z).Unit
            camera.CFrame = CFrame.lookAt(focus + Vector3.new(0,zoomHeight,0), focus + look)
        else
            local dir = Workspace.CurrentCamera.CFrame.LookVector
            dir = Vector3.new(dir.X,0,dir.Z).Unit
            local desired = focus - dir * zoomDist + Vector3.new(0,zoomHeight,0)
            local r = rayEnabled and Workspace:Raycast(focus, desired - focus, rayParams)
            local camPos = r and (r.Position + r.Normal * 0.5) or desired
            camera.CFrame = CFrame.lookAt(camPos, focus)
        end
    end
end)