if game.GameId~=3168615253 then return "wrong game buddy" end
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local UserInputService=game:GetService("UserInputService")
local localPlayer=Players.LocalPlayer
local punchRemote=ReplicatedStorage:WaitForChild("Remote Events"):WaitForChild("Punch")
local PUNCH_ID=314159265359
local PUNCH_FORCE=1.0196832418441772
local radius=13.5
local delay=0
local ignoreFriends=false
local auraEnabled=false
local rootPart,aura
local loops={}
local function getRootPart(c) return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") end
local function createAura()
    if aura then aura:Destroy() end
    aura=Instance.new("Part",workspace)
    aura.Name="Aura"
    aura.Shape=Enum.PartType.Ball
    aura.Anchored=true
    aura.CanCollide=false
    aura.CastShadow=false
    aura.Material=Enum.Material.ForceField
    aura.Transparency=0
    aura.Size=Vector3.new(radius*2,radius*2,radius*2)
end
local function onCharacterAdded(c)
    local rp=c:WaitForChild("HumanoidRootPart",5) or c:WaitForChild("Torso",5)
    if not rp then return end
    rootPart=rp
    if auraEnabled then createAura() end
end
local function onCharacterRemoving()
    if aura then aura:Destroy() end
    rootPart,aura=nil,nil
    loops={}
end
localPlayer.CharacterAdded:Connect(onCharacterAdded)
localPlayer.CharacterRemoving:Connect(onCharacterRemoving)
if localPlayer.Character then onCharacterAdded(localPlayer.Character) end
local guiParent=(type(gethui)=="function" and gethui()) or game:GetService("CoreGui") or localPlayer:WaitForChild("PlayerGui")
local screenGui=Instance.new("ScreenGui",guiParent)
screenGui.ResetOnSpawn=false
local mainFrame=Instance.new("Frame",screenGui)
mainFrame.Size=UDim2.new(0,600,0,40)
mainFrame.Position=UDim2.new(0.5,-300,0,50)
mainFrame.BackgroundTransparency=1
mainFrame.Active=true
local layout=Instance.new("UIListLayout",mainFrame)
layout.FillDirection=Enum.FillDirection.Horizontal
layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
layout.SortOrder=Enum.SortOrder.LayoutOrder
layout.Padding=UDim.new(0,5)
local function makeTextBox(d)
    local tb=Instance.new("TextBox",mainFrame)
    tb.Size=UDim2.new(0,100,0,30)
    tb.BackgroundColor3=Color3.new(0,0,0)
    tb.TextColor3=Color3.new(1,1,1)
    tb.PlaceholderText=tostring(d)
    tb.Text=tostring(d)
    tb.ClearTextOnFocus=false
    tb.TextScaled=true
    tb.BorderSizePixel=0
    Instance.new("UICorner",tb).CornerRadius=UDim.new(0.5,0)
    return tb
end
local radiusBox=makeTextBox(radius)
local auraBtn=Instance.new("TextButton",mainFrame)
auraBtn.Size=UDim2.new(0,100,0,30)
auraBtn.BackgroundColor3=Color3.new(1,0,0)
auraBtn.TextColor3=Color3.new(1,1,1)
auraBtn.Text="Aura: OFF"
auraBtn.TextScaled=true
auraBtn.BorderSizePixel=0
Instance.new("UICorner",auraBtn).CornerRadius=UDim.new(0.5,0)
auraBtn.MouseButton1Click:Connect(function()
    auraEnabled=not auraEnabled
    if auraEnabled then
        auraBtn.Text="Aura: ON"
        auraBtn.BackgroundColor3=Color3.new(0,1,0)
        if rootPart then createAura() end
    else
        auraBtn.Text="Aura: OFF"
        auraBtn.BackgroundColor3=Color3.new(1,0,0)
        if aura then aura:Destroy() end
        loops={}
    end
end)
local ignoreBtn=Instance.new("TextButton",mainFrame)
ignoreBtn.Size=UDim2.new(0,140,0,30)
ignoreBtn.BackgroundColor3=Color3.new(1,0,0)
ignoreBtn.TextColor3=Color3.new(1,1,1)
ignoreBtn.Text="Ignore Friends: OFF"
ignoreBtn.TextScaled=true
ignoreBtn.BorderSizePixel=0
Instance.new("UICorner",ignoreBtn).CornerRadius=UDim.new(0.5,0)
ignoreBtn.MouseButton1Click:Connect(function()
    ignoreFriends=not ignoreFriends
    if ignoreFriends then
        ignoreBtn.Text="Ignore Friends: ON"
        ignoreBtn.BackgroundColor3=Color3.new(0,1,0)
    else
        ignoreBtn.Text="Ignore Friends: OFF"
        ignoreBtn.BackgroundColor3=Color3.new(1,0,0)
    end
end)
do
    local dragging,di,ds,sp
    mainFrame.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            ds=inp.Position
            sp=mainFrame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    mainFrame.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
            di=inp
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp==di then
            local delta=inp.Position-ds
            mainFrame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+delta.X,sp.Y.Scale,sp.Y.Offset+delta.Y)
        end
    end)
end
RunService.RenderStepped:Connect(function()
    if rootPart and aura then aura.CFrame=rootPart.CFrame end
end)
do
    local acc,ci=0,0.1
    RunService.Heartbeat:Connect(function(dt)
        acc=acc+dt
        if acc<ci or not auraEnabled or not rootPart then return end
        acc=0
        local nr=tonumber(radiusBox.Text)
        if nr and nr>0 then
            radius=nr
            if aura then
                TweenService:Create(aura,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(radius*2,radius*2,radius*2)}):Play()
            end
        end
        for _,other in ipairs(Players:GetPlayers()) do
            if other~=localPlayer and other.Character and (not ignoreFriends or not localPlayer:IsFriendsWith(other.UserId)) then
                local tp=getRootPart(other.Character)
                if tp then
                    local dist=(tp.Position-rootPart.Position).Magnitude
                    if dist<=radius then
                        if not loops[other] then
                            loops[other]=true
                            task.spawn(function()
                                while loops[other] and auraEnabled do
                                    local targetPart=getRootPart(other.Character)
                                    if not targetPart then break end
                                    if (targetPart.Position-rootPart.Position).Magnitude>radius then break end
                                    punchRemote:FireServer(PUNCH_ID,other.Character,targetPart.Position,PUNCH_FORCE,targetPart)
                                    task.wait(delay)
                                end
                                loops[other]=nil
                            end)
                        end
                    else
                        loops[other]=nil
                    end
                end
            else
                loops[other]=nil
            end
        end
    end)
end