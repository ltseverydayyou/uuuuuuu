if game.GameId~=2380077519 then return 'wrong game buddy' end
local P=game:GetService"Players"
local R=game:GetService"ReplicatedStorage"
local RS=game:GetService"RunService"
local TS=game:GetService"TweenService"
local U=game:GetService"UserInputService"
local pl=P.LocalPlayer
local ex={"disarmh","b","htstun"}
local function gR()
    local t={}
    for _,v in ipairs(R:GetDescendants()) do
        if v:IsA"RemoteEvent" then
            local n=v.Name:lower()
            if n:find("hit") then
                t[#t+1]=v
            else
                for _,k in ipairs(ex) do
                    if n:lower()==k then
                        t[#t+1]=v
                        break
                    end
                end
            end
        end
    end
    return t
end
local m=gR()
local rd,dt=20,0.85
local rt,ar,ig
local function g(c) return c:FindFirstChild"HumanoidRootPart"or c:FindFirstChild"Torso" end
local function cA() if ar then ar:Destroy() end; ar=Instance.new("Part",workspace); ar.Name="Aura"; ar.Shape=Enum.PartType.Ball; ar.Anchored=true; ar.CanCollide=false; ar.CastShadow=false; ar.Material=Enum.Material.SmoothPlastic; ar.Transparency=0.9; ar.Size=Vector3.new(rd*2,rd*2,rd*2) end
local function a(c)
    local r=c:WaitForChild("HumanoidRootPart",5) or c:WaitForChild("Torso",5)
    if not r then return end
    rt=r; cA()
end
local function rC() if ar then ar:Destroy() end; ar=nil; rt=nil end
pl.CharacterAdded:Connect(a)
pl.CharacterRemoving:Connect(rC)
if pl.Character and pl.Character.Parent then a(pl.Character) end
local parent=(type(gethui)=="function" and gethui()) or game:GetService"CoreGui" or pl:WaitForChild"PlayerGui"
local gui=Instance.new("ScreenGui",parent); gui.ResetOnSpawn=false
local f=Instance.new("Frame",gui); f.Size=UDim2.new(0,120,0,155); f.Position=UDim2.new(0.5,-60,0,50); f.BackgroundTransparency=1; f.Active=true
local l=Instance.new("UIListLayout",f); l.FillDirection=Enum.FillDirection.Vertical; l.HorizontalAlignment=Enum.HorizontalAlignment.Center; l.SortOrder=Enum.SortOrder.LayoutOrder; l.Padding=UDim.new(0,5)
local function B(v)
    local b=Instance.new("TextBox",f); b.Size=UDim2.new(0,100,0,30); b.BackgroundColor3=Color3.new(0,0,0); b.TextColor3=Color3.new(1,1,1); b.PlaceholderText=tostring(v); b.Text=tostring(v); b.ClearTextOnFocus=false; b.TextScaled=true; b.BorderSizePixel=0; Instance.new("UICorner",b).CornerRadius=UDim.new(0.5,0); return b
end
local rB=B(rd)
local dB=B(dt)
local T=Instance.new("TextButton",f); T.Size=UDim2.new(0,100,0,30); T.BackgroundColor3=Color3.new(0,0,0); T.TextColor3=Color3.new(1,1,1); T.Text="Ignore Friends: Off"; T.TextScaled=true; T.BorderSizePixel=0; Instance.new("UICorner",T).CornerRadius=UDim.new(0.5,0)
T.MouseButton1Click:Connect(function() ig=not ig; T.Text = ig and "Ignore Friends: On" or "Ignore Friends: Off" end)
local drag,di,ds,sp
f.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true; ds=i.Position; sp=f.Position; i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then drag=false end end) end end)
f.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then di=i end end)
U.InputChanged:Connect(function(i) if drag and i==di then local d=i.Position-ds; f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end)
RS.RenderStepped:Connect(function() if rt and ar then ar.CFrame = rt.CFrame end end)
task.spawn(function()
    while true do
        local nr=tonumber(rB.Text)
        if nr and nr~=rd then rd=nr; if ar then TS:Create(ar,TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(rd*2,rd*2,rd*2)}):Play() end end
        local nd=tonumber(dB.Text)
        if nd then dt=nd end
        if rt then
            for _,plr in ipairs(P:GetPlayers()) do
                if plr~=pl and plr.Character and (not ig or not pl:IsFriendsWith(plr.UserId)) then
                    local p=g(plr.Character)
                    if p and (p.Position-rt.Position).Magnitude<=rd then
                        for _,e in ipairs(m) do e:FireServer(p) end
                        task.wait(0.3)
                    end
                end
            end
        end
        task.wait(dt)
    end
end)