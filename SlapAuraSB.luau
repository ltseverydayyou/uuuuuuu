if game.GameId~=2380077519 then return 'wrong game buddy' end
local P=game:GetService"Players"
local R=game:GetService"ReplicatedStorage"
local Run=game:GetService"RunService"
local TS=game:GetService"TweenService"
local UI=game:GetService"UserInputService"
local pl=P.LocalPlayer
local ex={"disarmh","b","htstun"}
local function getRemotes()
    local t={}
    for _,v in ipairs(R:GetDescendants()) do
        if v:IsA"RemoteEvent" then
            local n=v.Name:lower()
            if n:find("hit") then
                t[#t+1]=v
            else
                for _,k in ipairs(ex) do
                    if n==k then
                        t[#t+1]=v
                        break
                    end
                end
            end
        end
    end
    return t
end
local remotes=getRemotes()
local rad,dt=20,0.7
local root,aura,ignore
local function getRoot(c)return c:FindFirstChild"HumanoidRootPart"or c:FindFirstChild"Torso"end
local function makeAura()
    if aura then aura:Destroy() end
    aura=Instance.new("Part",workspace)
    aura.Name="Aura"
    aura.Shape=Enum.PartType.Ball
    aura.Anchored=true
    aura.CanCollide=false
    aura.CastShadow=false
    aura.Material=Enum.Material.ForceField
    aura.Transparency=0
    aura.Size=Vector3.new(rad*2,rad*2,rad*2)
end
local function onChar(c)
    local r=c:WaitForChild("HumanoidRootPart",5)or c:WaitForChild("Torso",5)
    if not r then return end
    root=r
    makeAura()
end
local function onDespawn()
    if aura then aura:Destroy() end
    aura=nil
    root=nil
end
pl.CharacterAdded:Connect(onChar)
pl.CharacterRemoving:Connect(onDespawn)
if pl.Character then onChar(pl.Character) end
local parent=(type(gethui)=="function"and gethui())or game:GetService"CoreGui"or pl:WaitForChild"PlayerGui"
local gui=Instance.new("ScreenGui",parent);gui.ResetOnSpawn=false
local f=Instance.new("Frame",gui);f.Size=UDim2.new(0,120,0,155);f.Position=UDim2.new(0.5,-60,0,50);f.BackgroundTransparency=1;f.Active=true
local ls=Instance.new("UIListLayout",f);ls.FillDirection=Enum.FillDirection.Vertical;ls.HorizontalAlignment=Enum.HorizontalAlignment.Center;ls.SortOrder=Enum.SortOrder.LayoutOrder;ls.Padding=UDim.new(0,5)
local function mkBox(v)
    local b=Instance.new("TextBox",f)
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
local rB=mkBox(rad)
local dB=mkBox(dt)
local btn=Instance.new("TextButton",f)
btn.Size=UDim2.new(0,100,0,30)
btn.BackgroundColor3=Color3.new(0,0,0)
btn.TextColor3=Color3.new(1,1,1)
btn.Text="Ignore Friends: Off"
btn.TextScaled=true
btn.BorderSizePixel=0
Instance.new("UICorner",btn).CornerRadius=UDim.new(0.5,0)
btn.MouseButton1Click:Connect(function()ignore=not ignore;btn.Text=ignore and"Ignoring Friends" or"Ignoring Off"end)
local drag,di,ds,sp
f.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        drag=true;ds=i.Position;sp=f.Position
        i.Changed:Connect(function()if i.UserInputState==Enum.UserInputState.End then drag=false end end)
    end
end)
f.InputChanged:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
        di=i
    end
end)
UI.InputChanged:Connect(function(i)
    if drag and i==di then
        local d=i.Position-ds
        f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
    end
end)
local loops={}
Run.RenderStepped:Connect(function()
    if root and aura then aura.CFrame=root.CFrame end
    local nr=tonumber(rB.Text)
    if nr and nr~=rad then rad=nr;makeAura() end
    local nd=tonumber(dB.Text)
    if nd then dt=nd end
    for _,p in ipairs(P:GetPlayers()) do
        if p~=pl and p.Character and root and (not ignore or not pl:IsFriendsWith(p.UserId)) then
            local part=getRoot(p.Character)
            local inside=part and (part.Position-root.Position).Magnitude<=rad
            if inside and not loops[p] then
                loops[p]=true
                task.spawn(function()
                    while loops[p] do
                        if p.Character and root then
                            local tpart=getRoot(p.Character)
                            if tpart and (tpart.Position-root.Position).Magnitude<=rad then
                                for _,e in ipairs(remotes) do e:FireServer(tpart) end
                            else break end
                        else break end
                        task.wait(dt)
                    end
                    loops[p]=nil
                end)
            elseif loops[p] and not inside then
                loops[p]=nil
            end
        else
            loops[p]=nil
        end
    end
end)