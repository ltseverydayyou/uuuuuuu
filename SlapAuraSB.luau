if game.GameId~=2380077519 then return 'wrong game buddy' end
local P=game:GetService"Players"
local R=game:GetService"ReplicatedStorage"
local RS=game:GetService"RunService"
local TS=game:GetService"TweenService"
local U=game:GetService"UserInputService"
local pl=P.LocalPlayer
local ex={"disarmh","b","htstun"}
local function getRemotes()
    local t={}
    for _,v in ipairs(R:GetDescendants())do
        if v:IsA"RemoteEvent"then
            local n=v.Name:lower()
            if n:find("hit")then
                t[#t+1]=v
            else
                for _,e in ipairs(ex)do
                    if n==e then
                        t[#t+1]=v
                        break
                    end
                end
            end
        end
    end
    return t
end
local m=getRemotes()
local rd,dt=20,0.7
local rt,ar,ig
local function getRoot(c)return c:FindFirstChild"HumanoidRootPart"or c:FindFirstChild"Torso"end
local function makeAura()if ar then ar:Destroy()end;ar=Instance.new("Part",workspace);ar.Name="Aura";ar.Shape=Enum.PartType.Ball;ar.Anchored=true;ar.CanCollide=false;ar.CastShadow=false;ar.Material=Enum.Material.SmoothPlastic;ar.Transparency=0.9;ar.Size=Vector3.new(rd*2,rd*2,rd*2)end
local function onChar(c)
    local r=c:WaitForChild("HumanoidRootPart",5)or c:WaitForChild("Torso",5)
    if not r then return end
    rt=r;makeAura()
end
local function cleanChar()if ar then ar:Destroy()end;ar=nil;rt=nil end
pl.CharacterAdded:Connect(onChar)
pl.CharacterRemoving:Connect(cleanChar)
if pl.Character and pl.Character.Parent then onChar(pl.Character) end
local parent=(type(gethui)=="function"and gethui())or game:GetService"CoreGui"or pl:WaitForChild"PlayerGui"
local gui=Instance.new("ScreenGui",parent)
gui.ResetOnSpawn=false
local frame=Instance.new("Frame",gui)
frame.Size=UDim2.new(0,120,0,135)
frame.Position=UDim2.new(0.5,-60,0,50)
frame.BackgroundTransparency=1
frame.Active=true
local layout=Instance.new("UIListLayout",frame)
layout.FillDirection=Enum.FillDirection.Vertical
layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
layout.SortOrder=Enum.SortOrder.LayoutOrder
layout.Padding=UDim.new(0,5)
local function mkBox(v)
    local b=Instance.new("TextBox",frame)
    b.Size=UDim2.new(0,100,0,30)
    b.BackgroundColor3=Color3.new(0,0,0)
    b.TextColor3=Color3.new(1,1,1)
    b.PlaceholderText=tostring(v)
    b.Text=tostring(v)
    b.ClearTextOnFocus=false
    b.TextScaled=true
    b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0.5,0)
    return b
end
local rB=mkBox(rd)
local dB=mkBox(dt)
local btn=Instance.new("TextButton",frame)
btn.Size=UDim2.new(0,100,0,30)
btn.BackgroundColor3=Color3.new(0,0,0)
btn.TextColor3=Color3.new(1,1,1)
btn.Text="Ignore Friends: Off"
btn.TextScaled=true
btn.BorderSizePixel=0
Instance.new("UICorner",btn).CornerRadius=UDim.new(0.5,0)
btn.MouseButton1Click:Connect(function()ig=not ig;btn.Text=ig and"Ignore Friends: On"or"Ignore Friends: Off"end)
local drag,di,ds,sp
frame.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        drag=true;ds=i.Position;sp=frame.Position
        i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then drag=false end end)
    end
end)
frame.InputChanged:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then di=i end end)
U.InputChanged:Connect(function(i)if drag and i==di then local dd=i.Position-ds;frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+dd.X,sp.Y.Scale,sp.Y.Offset+dd.Y)end end)
RS.RenderStepped:Connect(function()if rt and ar then ar.CFrame=rt.CFrame end end)
task.spawn(function()
    while true do
        local nr=tonumber(rB.Text)
        if nr and nr~=rd then rd=nr;if ar then TS:Create(ar,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(rd*2,rd*2,rd*2)}):Play()end end
        local nd=tonumber(dB.Text)
        if nd then dt=nd end
        if rt then
            for _,plr in ipairs(P:GetPlayers())do
                if plr~=pl and plr.Character and (not ig or not pl:IsFriendsWith(plr.UserId)) then
                    local part=getRoot(plr.Character)
                    if part and (part.Position-rt.Position).Magnitude<=rd then
                        for _,ev in ipairs(m)do ev:FireServer(part)end
                    end
                end
            end
        end
        task.wait(dt)
    end
end)