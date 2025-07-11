local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player      = Players.LocalPlayer
local zoomDist    = 35
local zoomHeight  = 30
local headOff     = 3
local rayEnabled  = true
local overhead    = false

local uiTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local screenGui = Instance.new("ScreenGui", gethui())
screenGui.Name = "MiniMapGui"

local container = Instance.new("Frame", screenGui)
container.Name               = "MiniMapContainer"
container.AnchorPoint        = Vector2.new(1, 0)
container.Position           = UDim2.new(0.95, 0, 0.05, 0)
container.Size               = UDim2.new(0, 200, 0, 200)
container.BackgroundColor3   = Color3.fromRGB(30, 30, 30)
container.BackgroundTransparency = 0.2
container.Active             = true
Instance.new("UICorner", container).CornerRadius = UDim.new(0, 5)

local viewport = Instance.new("ViewportFrame", container)
viewport.Size                = UDim2.new(1, 0, 1, 0)
viewport.BackgroundTransparency = 1

local worldModel = Instance.new("WorldModel", viewport)
local cloneRoot  = Instance.new("Model", worldModel)

local camera = Instance.new("Camera", viewport)
viewport.CurrentCamera = camera
camera.FieldOfView     = 70

local lightPart = Instance.new("Part", worldModel)
lightPart.Size         = Vector3.new(1,1,1)
lightPart.Transparency = 1
lightPart.Anchored     = true
lightPart.CanCollide   = false
local pointLight = Instance.new("PointLight", lightPart)
pointLight.Brightness = 2
pointLight.Range      = 500

local marker = Instance.new("Part", worldModel)
marker.Size       = Vector3.new(1,2,1)
marker.Anchored   = true
marker.CanCollide = false
marker.Material   = Enum.Material.Neon
marker.Color      = Color3.new(1,0,0)
local mesh = Instance.new("SpecialMesh", marker)
mesh.MeshType = Enum.MeshType.Sphere
mesh.Scale    = Vector3.new(0.5,1,0.5)

local rayParams = RaycastParams.new()
rayParams.FilterType             = Enum.RaycastFilterType.Blacklist
rayParams.IgnoreWater            = true
local ignoreList = { player.Character }
rayParams.FilterDescendantsInstances = ignoreList

local function trackPart(p)
    if p:IsA("BasePart") then
        if not p.CanCollide then table.insert(ignoreList, p) end
        p:GetPropertyChangedSignal("CanCollide"):Connect(function()
            if p.CanCollide then
                for i,v in ipairs(ignoreList) do
                    if v == p then table.remove(ignoreList,i); break end
                end
            else
                table.insert(ignoreList, p)
            end
            rayParams.FilterDescendantsInstances = ignoreList
        end)
    end
end

for _,o in ipairs(Workspace:GetDescendants()) do
    if not o:IsDescendantOf(Workspace.Terrain) then trackPart(o) end
end
Workspace.DescendantAdded:Connect(function(o)
    if not o:IsDescendantOf(Workspace.Terrain) then trackPart(o) end
end)

local clones = {}
local function addClone(o)
    if o:IsDescendantOf(Workspace.Terrain) then return end
    if o:IsA("BasePart") or o:IsA("MeshPart") or o:IsA("UnionOperation") then
        o.Archivable = true
        local ok, cp = pcall(function() return o:Clone() end)
        if ok and cp then
            clones[o] = cp
            cp.Parent = cloneRoot
            cp.CFrame = o.CFrame
            for _,prop in ipairs({"Size","Transparency","Color","BrickColor","Material","Reflectance","CastShadow","Anchored","CanCollide"}) do
                o:GetPropertyChangedSignal(prop):Connect(function()
                    cp[prop] = o[prop]
                end)
            end
            o:GetPropertyChangedSignal("CFrame"):Connect(function()
                cp.CFrame = o.CFrame
            end)
            if o:IsA("MeshPart") then
                o:GetPropertyChangedSignal("MeshId"):Connect(function()
                    cp.MeshId = o.MeshId
                end)
                o:GetPropertyChangedSignal("TextureID"):Connect(function()
                    cp.TextureID = o.TextureID
                end)
            end
        end
    end
end
local function removeClone(o)
    local cp = clones[o]
    if cp then
        cp:Destroy()
        clones[o] = nil
    end
end

for _,o in ipairs(Workspace:GetDescendants()) do addClone(o) end
Workspace.DescendantAdded:Connect(addClone)
Workspace.DescendantRemoving:Connect(removeClone)

local function style(btn)
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3       = Color3.new(1,1,1)
    btn.Font             = Enum.Font.SourceSansSemibold
    btn.TextScaled       = true
    btn.AutoButtonColor  = true
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,4)
end

local dragBtn = Instance.new("TextButton", container)
dragBtn.Text     = "⇅"
dragBtn.Size     = UDim2.new(0,24,0,24)
dragBtn.Position = UDim2.new(0,8,0,8)
style(dragBtn)

local menuBtn = Instance.new("TextButton", container)
menuBtn.Text     = ":"
menuBtn.Size     = UDim2.new(0,24,0,24)
menuBtn.Position = UDim2.new(1,-32,0,8)
style(menuBtn)

local buttonHeight = 24
local spacing      = 4

local zoomInBtn   = Instance.new("TextButton",container)
local zoomOutBtn  = Instance.new("TextButton",container)
local rayBtn      = Instance.new("TextButton",container)
local viewBtn     = Instance.new("TextButton",container)
local sizeUpBtn   = Instance.new("TextButton",container)
local sizeDownBtn = Instance.new("TextButton",container)

for _,btn in ipairs({zoomInBtn,zoomOutBtn,rayBtn,viewBtn,sizeUpBtn,sizeDownBtn}) do
    btn.Visible = false
    style(btn)
end

zoomInBtn.Text   = "+"
zoomInBtn.Size   = UDim2.new(0,24,0,buttonHeight)

zoomOutBtn.Text  = "–"
zoomOutBtn.Size  = UDim2.new(0,24,0,buttonHeight)

rayBtn.Text      = "Ray:On"
rayBtn.Size      = UDim2.new(0,60,0,buttonHeight)

viewBtn.Text     = "3D"
viewBtn.Size     = UDim2.new(0,60,0,buttonHeight)

sizeUpBtn.Text   = "S+"
sizeUpBtn.Size   = UDim2.new(0,36,0,buttonHeight)

sizeDownBtn.Text = "S-"
sizeDownBtn.Size = UDim2.new(0,36,0,buttonHeight)

local dropButtons = {zoomInBtn,zoomOutBtn,rayBtn,viewBtn,sizeUpBtn,sizeDownBtn}

local function updateButtons()
    local totalHeight = #dropButtons * buttonHeight + (#dropButtons - 1) * spacing
    local startY = (container.Size.Y.Offset - totalHeight) / 2
    for i,btn in ipairs(dropButtons) do
        local pos = UDim2.new(1, 4, 0, startY + (i - 1)*(buttonHeight+spacing))
        TweenService:Create(btn, uiTweenInfo, {Position = pos}):Play()
    end
end

menuBtn.MouseButton1Click:Connect(function()
    local show = not zoomInBtn.Visible
    for _,btn in ipairs(dropButtons) do
        btn.Visible = show
        if show then
            btn.Position = UDim2.new(1,4,0,container.Size.Y.Offset/2)
            TweenService:Create(btn, uiTweenInfo, {TextTransparency=0}):Play()
        else
            local t = TweenService:Create(btn, uiTweenInfo, {TextTransparency=1})
            t:Play()
            t.Completed:Connect(function() btn.Visible = false end)
        end
    end
    if show then updateButtons() end
end)

local function dragger(ui,handle)
    handle = handle or ui
    local dragging,dragInput,dragStart,startPos = false,nil,Vector2.zero,UDim2.new()
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true;dragInput=i;dragStart=i.Position;startPos=ui.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            dragInput=i
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i==dragInput then
            local delta=i.Position-dragStart
            local abs=ui.Parent.AbsoluteSize
            ui.Position=UDim2.new(startPos.X.Scale+delta.X/abs.X,0,startPos.Y.Scale+delta.Y/abs.Y,0)
            updateButtons()
        end
    end)
    ui.Active=true
end

dragger(container,dragBtn)

zoomInBtn.MouseButton1Click:Connect(function()
    zoomDist   = math.max(5, zoomDist - 5)
    zoomHeight = math.max(5, zoomHeight - 5)
end)
zoomOutBtn.MouseButton1Click:Connect(function()
    zoomDist   = zoomDist + 5
    zoomHeight = zoomHeight + 5
end)
rayBtn.MouseButton1Click:Connect(function()
    rayEnabled = not rayEnabled
    rayBtn.Text = rayEnabled and "Ray:On" or "Ray:Off"
end)
viewBtn.MouseButton1Click:Connect(function()
    overhead = not overhead
    viewBtn.Text = overhead and "Top" or "3D"
end)
sizeUpBtn.MouseButton1Click:Connect(function()
    local newSize = container.Size + UDim2.new(0,50,0,50)
    TweenService:Create(container,uiTweenInfo,{Size=newSize}):Play()
    updateButtons()
end)
sizeDownBtn.MouseButton1Click:Connect(function()
    local w=math.max(50,container.Size.X.Offset-50)
    local h=math.max(50,container.Size.Y.Offset-50)
    local newSize=UDim2.new(container.Size.X.Scale,w,container.Size.Y.Scale,h)
    TweenService:Create(container,uiTweenInfo,{Size=newSize}):Play()
    updateButtons()
end)

RunService.RenderStepped:Connect(function(dt)
    for o,cp in pairs(clones) do
        if o.Parent then
            cp.CFrame = o.CFrame
        else
            removeClone(o)
        end
    end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        marker.CFrame = CFrame.new(hrp.Position + Vector3.new(0,1,0))
        local focus = hrp.Position + Vector3.new(0, headOff, 0)
        local cf,_   = cloneRoot:GetBoundingBox()
        lightPart.CFrame = cf
        local target
        if overhead then
            local look = Workspace.CurrentCamera.CFrame.LookVector
            local yaw  = math.atan2(-look.X, -look.Z)
            local pos  = focus + Vector3.new(0, zoomHeight, 0)
            target = CFrame.new(pos) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(-math.pi/2, 0, 0)
        else
            local dir = Workspace.CurrentCamera.CFrame.LookVector
            dir = Vector3.new(dir.X, 0, dir.Z)
            dir = (dir.Magnitude > 0 and dir.Unit) or Vector3.new(0, 0, -1)
            local desired = hrp.Position - dir*zoomDist + Vector3.new(0, zoomHeight, 0)
            local camPos  = desired
            if rayEnabled then
                rayParams.FilterDescendantsInstances = ignoreList
                local r = Workspace:Raycast(focus, desired - focus, rayParams)
                if r then camPos = r.Position + r.Normal*0.5 end
            end
            target = CFrame.lookAt(camPos, focus)
        end
        camera.CFrame = camera.CFrame:Lerp(target, math.clamp(dt * 8, 0, 1))
    end
end)