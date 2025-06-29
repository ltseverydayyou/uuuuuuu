if not game.GameId==2380077519 then return 'wrong game buddy' end
local P=game:GetService"Players"
local R=game:GetService"ReplicatedStorage"
local RS=game:GetService"RunService"
local TS=game:GetService"TweenService"
local U=game:GetService"UserInputService"
local pl=P.LocalPlayer
local m={}
for _,v in ipairs(R:GetDescendants())do if v:IsA"RemoteEvent"and v.Name:lower():sub(-3)=="hit"then m[#m+1]=v end end
local rad,dt=15,0.7
local root,A,ig=false

local function g(c) return c:FindFirstChild"HumanoidRootPart"or c:FindFirstChild"Torso"end
local function cA()if A then A:Destroy()end;A=Instance.new("Part",workspace);A.Name="Aura";A.Shape=Enum.PartType.Ball;A.Anchored=true;A.CanCollide=false;A.CastShadow=false;A.Material=Enum.Material.SmoothPlastic;A.Transparency=0.9;A.Size=Vector3.new(rad*2,rad*2,rad*2)end

local function a(c)
    local r=c:WaitForChild("HumanoidRootPart",5)or c:WaitForChild("Torso",5)
    if not r then return end
    root=r;cA()
end

local function rC()if A then A:Destroy()end;A=nil;root=nil end
pl.CharacterAdded:Connect(a)
pl.CharacterRemoving:Connect(rC)
if pl.Character and pl.Character.Parent then a(pl.Character)end

local parent=(type(gethui)=="function"and gethui())or game:GetService"CoreGui"or pl:WaitForChild"PlayerGui"
local gui=Instance.new("ScreenGui",parent)
gui.ResetOnSpawn=false

local c=Instance.new("Frame",gui)
c.Size=UDim2.new(0,120,0,135)
c.Position=UDim2.new(0.5,-60,0,50)
c.BackgroundTransparency=1
c.Active=true

local l=Instance.new("UIListLayout",c)
l.FillDirection=Enum.FillDirection.Vertical
l.HorizontalAlignment=Enum.HorizontalAlignment.Center
l.SortOrder=Enum.SortOrder.LayoutOrder
l.Padding=UDim.new(0,5)

local function B(d)
    local b=Instance.new("TextBox",c)
    b.Size=UDim2.new(0,100,0,30)
    b.BackgroundColor3=Color3.new(0,0,0)
    b.TextColor3=Color3.new(1,1,1)
    b.PlaceholderText=tostring(d)
    b.Text=tostring(d)
    b.ClearTextOnFocus=false
    b.TextScaled=true
    b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0.5,0)
    return b
end

local rB=B(rad)
local dB=B(dt)

local T=Instance.new("TextButton",c)
T.Size=UDim2.new(0,100,0,30)
T.BackgroundColor3=Color3.new(0,0,0)
T.TextColor3=Color3.new(1,1,1)
T.Text="Ignore Friends: Off"
T.TextScaled=true
T.BorderSizePixel=0
Instance.new("UICorner",T).CornerRadius=UDim.new(0.5,0)
T.MouseButton1Click:Connect(function()ig=not ig;T.Text=ig and"Ignore Friends: On"or"Ignore Friends: Off"end)

local dragging,dragInput,dragStart,startPos
c.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true;dragStart=i.Position;startPos=c.Position
        i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
end)
c.InputChanged:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then dragInput=i end end)
U.InputChanged:Connect(function(i)
    if i==dragInput and dragging then
        local d=i.Position-dragStart
        c.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)

RS.RenderStepped:Connect(function()if root and A then A.CFrame=root.CFrame end end)

task.spawn(function()
    while true do
        local nr=tonumber(rB.Text)
        if nr and nr~=rad then rad=nr; if A then TS:Create(A,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(rad*2,rad*2,rad*2)}):Play()end end
        local nd=tonumber(dB.Text)
        if nd then dt=nd end
        if root then
            local tgt,bd
            for _,plr in ipairs(P:GetPlayers())do
                if plr~=pl and plr.Character and (not ig or not pl:IsFriendsWith(plr.UserId)) then
                    local p=g(plr.Character)
                    if p then
                        local d=(p.Position-root.Position).Magnitude
                        if d<=rad and (not bd or d<bd)then tgt,bd=p,d end
                    end
                end
            end
            if tgt then for _,e in ipairs(m)do e:FireServer(tgt)end end
        end
        task.wait(dt)
    end
end)