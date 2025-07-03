if game.GameId ~= 2380077519 then return 'wrong game buddy' end
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local StarterGui        = game:GetService("StarterGui")

local localPlayer     = Players.LocalPlayer
local forbiddenNames  = { "disarmh","b","htstun" }
local attackRemotes   = {}
for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") then
        local n=v.Name:lower()
        if n:find("hit") then
            table.insert(attackRemotes,v)
        else
            for _,f in ipairs(forbiddenNames) do
                if n==f then table.insert(attackRemotes,v); break end
            end
        end
    end
end
local ghostRemote    = ReplicatedStorage:WaitForChild("Ghostinvisibilityactivated")
local radius,delay   = 20,0.7
local rootPart,aura
local ignoreFriends  = false
local auraEnabled    = false
local loops          = {}

local function getRootPart(ch)
    return ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso")
end

local function createAura()
    if aura then aura:Destroy() end
    aura=Instance.new("Part",workspace)
    aura.Name="Aura"; aura.Shape=Enum.PartType.Ball
    aura.Anchored=true; aura.CanCollide=false; aura.CastShadow=false
    aura.Material=Enum.Material.ForceField; aura.Transparency=0
    aura.Size=Vector3.new(radius*2,radius*2,radius*2)
end

local function onCharacterAdded(ch)
    local r=ch:WaitForChild("HumanoidRootPart",5) or ch:WaitForChild("Torso",5)
    if not r then return end
    rootPart=r
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

local guiParent=(type(gethui)=="function" and gethui())or game:GetService("CoreGui")or localPlayer:WaitForChild("PlayerGui")
local screenGui=Instance.new("ScreenGui",guiParent); screenGui.ResetOnSpawn=false

local mainFrame=Instance.new("Frame",screenGui)
mainFrame.Size=UDim2.new(0,600,0,40)
mainFrame.Position=UDim2.new(0.5,-300,0,50)
mainFrame.BackgroundTransparency=1; mainFrame.Active=true

local hl=Instance.new("UIListLayout",mainFrame)
hl.FillDirection=Enum.FillDirection.Horizontal
hl.HorizontalAlignment=Enum.HorizontalAlignment.Center
hl.SortOrder=Enum.SortOrder.LayoutOrder
hl.Padding=UDim.new(0,5)

local function makeTextBox(val)
    local tb=Instance.new("TextBox",mainFrame)
    tb.Size=UDim2.new(0,100,0,30)
    tb.BackgroundColor3=Color3.new(0,0,0)
    tb.TextColor3=Color3.new(1,1,1)
    tb.PlaceholderText=tostring(val)
    tb.Text=tostring(val)
    tb.ClearTextOnFocus=false
    tb.TextScaled=true
    tb.BorderSizePixel=0
    Instance.new("UICorner",tb).CornerRadius=UDim.new(0.5,0)
    return tb
end

local radiusBox=makeTextBox(radius)
local delayBox =makeTextBox(delay)

local invisBtn=Instance.new("TextButton",mainFrame)
invisBtn.Size=UDim2.new(0,120,0,30)
invisBtn.BackgroundColor3=Color3.new(0,0,0)
invisBtn.TextColor3=Color3.new(1,1,1)
invisBtn.Text="Invis (Ghost Hand)"
invisBtn.TextScaled=true; invisBtn.BorderSizePixel=0
Instance.new("UICorner",invisBtn).CornerRadius=UDim.new(0.5,0)
invisBtn.MouseButton1Click:Connect(function()
    local stats=localPlayer:FindFirstChild("leaderstats")
    local slaps=stats and stats:FindFirstChild("Slaps")
    if slaps and slaps.Value>=666 then
        local lobby=workspace:FindFirstChild("Lobby")
        if lobby then
            local ghost=lobby:FindFirstChild("Ghost")
            if ghost then
                local cd=ghost:FindFirstChildOfClass("ClickDetector")
                if cd then fireclickdetector(cd) end
            end
        end
        ghostRemote:FireServer()
    else
        StarterGui:SetCore("SendNotification",{Title="Error",Text="Requires 666 slaps to use",Duration=5})
    end
end)

local auraBtn=Instance.new("TextButton",mainFrame)
auraBtn.Size=UDim2.new(0,80,0,30)
auraBtn.BackgroundColor3=Color3.new(1,0,0)
auraBtn.TextColor3=Color3.new(1,1,1)
auraBtn.Text="Aura: OFF"
auraBtn.TextScaled=true; auraBtn.BorderSizePixel=0
Instance.new("UICorner",auraBtn).CornerRadius=UDim.new(0.5,0)
auraBtn.MouseButton1Click:Connect(function()
    auraEnabled=not auraEnabled
    if auraEnabled then
        auraBtn.Text="Aura: ON"; auraBtn.BackgroundColor3=Color3.new(0,1,0)
        if rootPart then createAura() end
    else
        auraBtn.Text="Aura: OFF"; auraBtn.BackgroundColor3=Color3.new(1,0,0)
        if aura then aura:Destroy() end
        loops={}
    end
end)

local ignoreBtn=Instance.new("TextButton",mainFrame)
ignoreBtn.Size=UDim2.new(0,100,0,30)
ignoreBtn.BackgroundColor3=Color3.new(1,0,0)
ignoreBtn.TextColor3=Color3.new(1,1,1)
ignoreBtn.Text="Ignore Friends: OFF"
ignoreBtn.TextScaled=true; ignoreBtn.BorderSizePixel=0
Instance.new("UICorner",ignoreBtn).CornerRadius=UDim.new(0.5,0)
ignoreBtn.MouseButton1Click:Connect(function()
    ignoreFriends=not ignoreFriends
    if ignoreFriends then
        ignoreBtn.Text="Ignore Friends: ON"; ignoreBtn.BackgroundColor3=Color3.new(0,1,0)
    else
        ignoreBtn.Text="Ignore Friends: OFF"; ignoreBtn.BackgroundColor3=Color3.new(1,0,0)
    end
end)

do
    local dragging,di,ds,sp
    mainFrame.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; ds=inp.Position; sp=mainFrame.Position
            inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    mainFrame.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then di=inp end
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
    local nr=tonumber(radiusBox.Text)
    if nr and nr~=radius then
        radius=nr
        if auraEnabled and aura then
            TweenService:Create(aura,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(radius*2,radius*2,radius*2)}):Play()
        end
    end
    local nd=tonumber(delayBox.Text)
    if nd then delay=nd end
    if auraEnabled and rootPart then
        for _,other in ipairs(Players:GetPlayers()) do
            if other~=localPlayer and other.Character and (not ignoreFriends or not localPlayer:IsFriendsWith(other.UserId)) then
                local rp=getRootPart(other.Character)
                local flag=other.Character:FindFirstChild("isInArena") or other.Character:FindFirstChild("IsInDefaultArena")
                if flag and flag.Value then
                    if not loops[other] then
                        loops[other]=true
                        task.spawn(function()
                            while loops[other] and auraEnabled do
                                local tp=getRootPart(other.Character)
                                if not tp then break end
                                for _,ev in ipairs(attackRemotes) do ev:FireServer(tp) end
                                task.wait(delay)
                            end
                            loops[other]=nil
                        end)
                    end
                    continue
                end
                if not rp then
                    loops[other]=nil
                else
                    loops[other]=true
                    task.spawn(function()
                        while loops[other] and auraEnabled do
                            local tp=getRootPart(other.Character)
                            if not tp or (tp.Position-rootPart.Position).Magnitude>radius then break end
                            for _,ev in ipairs(attackRemotes) do ev:FireServer(tp) end
                            task.wait(delay)
                        end
                        loops[other]=nil
                    end)
                end
            else
                loops[other]=nil
            end
        end
    end
end)