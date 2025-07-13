local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService   = game:GetService("UserInputService")

local player = Players.LocalPlayer
local gui    = (gethui and gethui()) or player:WaitForChild("PlayerGui")
local sg     = Instance.new("ScreenGui", gui)
sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
sg.DisplayOrder   = 1000

local mainFrame = Instance.new("Frame", sg)
mainFrame.AnchorPoint     = Vector2.new(0.5,0)
mainFrame.Position        = UDim2.new(0.5,0,0.02,0)
mainFrame.Size            = UDim2.new(0,260,0,60)
mainFrame.BackgroundColor3= Color3.fromRGB(30,30,30)
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", mainFrame).Thickness = 1

local toggleBtn = Instance.new("TextButton", mainFrame)
toggleBtn.Size               = UDim2.new(1,-120,0,40)
toggleBtn.Position           = UDim2.new(0,0,0,0)
toggleBtn.BackgroundTransparency = 1
toggleBtn.Font               = Enum.Font.SourceSansBold
toggleBtn.TextSize           = 18
toggleBtn.TextColor3         = Color3.new(1,1,1)
toggleBtn.Text               = "Animations ▼"
toggleBtn.AutoButtonColor    = false

local cancelBtn = Instance.new("TextButton", mainFrame)
cancelBtn.Size            = UDim2.new(0,120,0,40)
cancelBtn.Position        = UDim2.new(1,-120,0,0)
cancelBtn.BackgroundColor3= Color3.fromRGB(65,65,65)
cancelBtn.Font            = Enum.Font.SourceSans
cancelBtn.TextSize        = 16
cancelBtn.TextColor3      = Color3.new(1,1,1)
cancelBtn.Text            = "Cancel Animation"
cancelBtn.AutoButtonColor = false
Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0,8)

local loadingLbl = Instance.new("TextLabel", mainFrame)
loadingLbl.Size            = UDim2.new(1,0,0,20)
loadingLbl.Position        = UDim2.new(0,0,0,40)
loadingLbl.BackgroundTransparency = 1
loadingLbl.Font            = Enum.Font.SourceSans
loadingLbl.TextSize        = 14
loadingLbl.TextColor3      = Color3.new(1,1,1)
loadingLbl.Text            = "Loading... 0%"
loadingLbl.TextXAlignment  = Enum.TextXAlignment.Center

local animList = Instance.new("ScrollingFrame", mainFrame)
animList.Size            = UDim2.new(1,0,0,0)
animList.Position        = UDim2.new(0,0,0,60)
animList.BackgroundColor3= Color3.fromRGB(20,20,20)
animList.BorderSizePixel = 0
animList.ScrollingEnabled= true
animList.ScrollBarThickness = 6
Instance.new("UICorner", animList).CornerRadius = UDim.new(0,8)

local listLayout = Instance.new("UIListLayout", animList)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding   = UDim.new(0,4)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    animList.CanvasSize = UDim2.new(0,0,0,listLayout.AbsoluteContentSize.Y)
end)

local optionFrame = Instance.new("Frame", mainFrame)
optionFrame.AnchorPoint     = Vector2.new(0,0)
optionFrame.Position        = UDim2.new(1,0,0,0)
optionFrame.Size            = UDim2.new(0,0,0,0)
optionFrame.BackgroundColor3= Color3.fromRGB(25,25,25)
optionFrame.Visible         = false
Instance.new("UICorner", optionFrame).CornerRadius = UDim.new(0,8)

local playBtn = Instance.new("TextButton", optionFrame)
playBtn.Size            = UDim2.new(1,-20,0,30)
playBtn.Position        = UDim2.new(0,10,0,10)
playBtn.BackgroundColor3= Color3.fromRGB(70,70,70)
playBtn.Font            = Enum.Font.SourceSans
playBtn.TextSize        = 16
playBtn.TextColor3      = Color3.new(1,1,1)
playBtn.Text            = "Play"
Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0,4)

local copyBtn = Instance.new("TextButton", optionFrame)
copyBtn.Size            = UDim2.new(1,-20,0,30)
copyBtn.Position        = UDim2.new(0,10,0,50)
copyBtn.BackgroundColor3= Color3.fromRGB(70,70,70)
copyBtn.Font            = Enum.Font.SourceSans
copyBtn.TextSize        = 16
copyBtn.TextColor3      = Color3.new(1,1,1)
copyBtn.Text            = "Copy ID"
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0,4)

local animations = {}
local selected, currentTrack = nil, nil
local expanded = false

local function stopSelected()
    if currentTrack then
        currentTrack:Stop()
        currentTrack = nil
    end
end

local function bindHumanoid(h)
    h.Running:Connect(function(speed)
        if speed > 0 then stopSelected() end
    end)
    h.Jumping:Connect(stopSelected)
    h.StateChanged:Connect(function(_,ns)
        if ns==Enum.HumanoidStateType.Climbing
        or ns==Enum.HumanoidStateType.Freefall
        or ns==Enum.HumanoidStateType.Swimming then
            stopSelected()
        end
    end)
end

if player.Character then
    bindHumanoid(player.Character:WaitForChild("Humanoid"))
end
player.CharacterAdded:Connect(function(char)
    bindHumanoid(char:WaitForChild("Humanoid"))
end)

local dragInput, dragStart, inputStart
mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1
    or input.UserInputType==Enum.UserInputType.Touch then
        dragInput, dragStart, inputStart = input, mainFrame.Position, input.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then
                dragInput = nil
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input==dragInput then
        local delta = input.Position - inputStart
        mainFrame.Position = UDim2.new(
            dragStart.X.Scale, dragStart.X.Offset+delta.X,
            dragStart.Y.Scale, dragStart.Y.Offset+delta.Y
        )
    end
end)

toggleBtn.Activated:Connect(function()
    expanded = not expanded
    toggleBtn.Text = expanded and "Animations ▲" or "Animations ▼"
    local h = math.clamp(listLayout.AbsoluteContentSize.Y,0,176)
    TweenService:Create(animList, TweenInfo.new(0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out), {
        Size = expanded and UDim2.new(1,0,0,h) or UDim2.new(1,0,0,0)
    }):Play()
    TweenService:Create(mainFrame, TweenInfo.new(0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out), {
        Size = expanded and UDim2.new(0,260,0,60+h) or UDim2.new(0,260,0,60)
    }):Play()
    if not expanded then
        optionFrame.Visible = false
        TweenService:Create(optionFrame, TweenInfo.new(0.2), {Size=UDim2.new(0,0,0,0)}):Play()
    end
end)

cancelBtn.Activated:Connect(function()
    if player.Character then
        local h = player.Character:FindFirstChildOfClass("Humanoid")
        if h then
            for _,t in ipairs(h:GetPlayingAnimationTracks()) do
                t:Stop()
            end
        end
    end
    if expanded then
        expanded = false
        toggleBtn.Text = "Animations ▼"
        TweenService:Create(animList, TweenInfo.new(0.3), {Size=UDim2.new(1,0,0,0)}):Play()
        TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size=UDim2.new(0,260,0,60)}):Play()
        optionFrame.Visible = false
        TweenService:Create(optionFrame, TweenInfo.new(0.2), {Size=UDim2.new(0,0,0,0)}):Play()
    end
end)

playBtn.Activated:Connect(function()
    if selected and player.Character then
        local h = player.Character:FindFirstChildOfClass("Humanoid")
        if h then
            for _,t in ipairs(h:GetPlayingAnimationTracks()) do t:Stop() end
            currentTrack = h:LoadAnimation(selected.anim)
            currentTrack:Play()
        end
    end
    expanded = false
    toggleBtn.Text = "Animations ▼"
    TweenService:Create(animList, TweenInfo.new(0.3), {Size=UDim2.new(1,0,0,0)}):Play()
    TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size=UDim2.new(0,260,0,60)}):Play()
    optionFrame.Visible = false
    TweenService:Create(optionFrame, TweenInfo.new(0.2), {Size=UDim2.new(0,0,0,0)}):Play()
end)

copyBtn.Activated:Connect(function()
    if selected then
        local id = selected.anim.AnimationId:match("%d+")
        if setclipboard then setclipboard(id) end
        if syn and syn.set_clipboard then syn.set_clipboard(id) end
    end
    expanded = false
    toggleBtn.Text = "Animations ▼"
    TweenService:Create(animList, TweenInfo.new(0.3), {Size=UDim2.new(1,0,0,0)}):Play()
    TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size=UDim2.new(0,260,0,60)}):Play()
    optionFrame.Visible = false
    TweenService:Create(optionFrame, TweenInfo.new(0.2), {Size=UDim2.new(0,0,0,0)}):Play()
end)

task.spawn(function()
    local desc = game:GetDescendants()
    local tot  = #desc
    for i,inst in ipairs(desc) do
        if inst:IsA("Animation") then
            table.insert(animations, {name=inst.Name, anim=inst})
        elseif (inst:IsA("NumberValue") or inst:IsA("IntValue")) and typeof(inst.Value)=="number" then
            local ok,info = pcall(function()
                return MarketplaceService:GetProductInfo(inst.Value, Enum.InfoType.Asset)
            end)
            if ok and info.AssetTypeId == Enum.AssetType.Animation.Value then
                local a = Instance.new("Animation")
                a.Name        = info.Name
                a.AnimationId = "rbxassetid://"..inst.Value
                table.insert(animations, {name=info.Name, anim=a})
            end
        end
        loadingLbl.Text = "Loading... "..math.floor(i/tot*100).."%"
    end
    loadingLbl:Destroy()
    for i,data in ipairs(animations) do
        local btn = Instance.new("TextButton", animList)
        btn.Size            = UDim2.new(1,0,0,32)
        btn.BackgroundColor3= Color3.fromRGB(50,50,50)
        btn.BorderSizePixel = 0
        btn.Font            = Enum.Font.SourceSans
        btn.TextSize        = 16
        btn.TextColor3      = Color3.new(1,1,1)
        btn.Text            = data.name
        btn.LayoutOrder     = i
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0,4)
        btn.Activated:Connect(function()
            selected = data
            optionFrame.Visible = true
            TweenService:Create(optionFrame, TweenInfo.new(0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out), {
                Size = UDim2.new(0,120,0,90)
            }):Play()
        end)
    end
end)