local P=game:GetService("Players")
local T=game:GetService("TweenService")
local M=game:GetService("MarketplaceService")
local U=game:GetService("UserInputService")
local pl=P.LocalPlayer
local g=(gethui and gethui()) or pl:WaitForChild("PlayerGui")
local sg=Instance.new("ScreenGui",g)
sg.ZIndexBehavior,sg.DisplayOrder=Enum.ZIndexBehavior.Global,1000

local f=Instance.new("Frame",sg)
f.AnchorPoint,f.Position=Vector2.new(0.5,0),UDim2.new(0.5,0,0.02,0)
f.Size,f.BackgroundColor3=UDim2.new(0,260,0,60),Color3.fromRGB(30,30,30)
Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",f).Thickness=1

local tb=Instance.new("TextButton",f)
tb.Size,tb.Position=UDim2.new(1,-120,0,40),UDim2.new(0,0,0,0)
tb.BackgroundTransparency,tb.AutoButtonColor=1,false
tb.Font,tb.TextSize,tb.TextColor3=Enum.Font.SourceSansBold,18,Color3.new(1,1,1)
tb.Text="Animations ▼"

local cb=Instance.new("TextButton",f)
cb.Size,cb.Position=UDim2.new(0,120,0,40),UDim2.new(1,-120,0,0)
cb.BackgroundColor3,cb.AutoButtonColor=Color3.fromRGB(65,65,65),false
cb.Font,cb.TextSize,cb.TextColor3=Enum.Font.SourceSans,16,Color3.new(1,1,1)
cb.Text="Cancel Animation"
Instance.new("UICorner",cb).CornerRadius=UDim.new(0,8)

local ld=Instance.new("TextLabel",f)
ld.Size,ld.Position=UDim2.new(1,0,0,20),UDim2.new(0,0,0,40)
ld.BackgroundTransparency=1
ld.Font,ld.TextSize,ld.TextColor3=Enum.Font.SourceSans,14,Color3.new(1,1,1)
ld.TextXAlignment=Enum.TextXAlignment.Center
ld.Text="Loading... 0%"

local sf=Instance.new("ScrollingFrame",f)
sf.Size,sf.Position=UDim2.new(1,0,0,0),UDim2.new(0,0,0,60)
sf.BackgroundColor3,sf.BorderSizePixel=Color3.fromRGB(20,20,20),0
sf.ScrollingEnabled,sf.ScrollBarThickness=true,6
Instance.new("UICorner",sf).CornerRadius=UDim.new(0,8)
local ly=Instance.new("UIListLayout",sf)
ly.SortOrder,ly.Padding=Enum.SortOrder.LayoutOrder,UDim.new(0,4)
ly:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sf.CanvasSize=UDim2.new(0,0,0,ly.AbsoluteContentSize.Y)
end)

local of=Instance.new("Frame",f)
of.Position,of.AnchorPoint=UDim2.new(1,0,0,0),Vector2.new(0,0)
of.Size,of.BackgroundColor3=UDim2.new(0,0,0,0),Color3.fromRGB(25,25,25)
of.Visible=false
Instance.new("UICorner",of).CornerRadius=UDim.new(0,8)

local pb=Instance.new("TextButton",of)
pb.Size,pb.Position=UDim2.new(1,-20,0,30),UDim2.new(0,10,0,10)
pb.BackgroundColor3,pb.Font,pb.TextSize,pb.TextColor3=Color3.fromRGB(70,70,70),Enum.Font.SourceSans,16,Color3.new(1,1,1)
pb.Text="Play"
Instance.new("UICorner",pb).CornerRadius=UDim.new(0,4)

local cpy=Instance.new("TextButton",of)
cpy.Size,cpy.Position=UDim2.new(1,-20,0,30),UDim2.new(0,10,0,50)
cpy.BackgroundColor3,cpy.Font,cpy.TextSize,cpy.TextColor3=Color3.fromRGB(70,70,70),Enum.Font.SourceSans,16,Color3.new(1,1,1)
cpy.Text="Copy ID"
Instance.new("UICorner",cpy).CornerRadius=UDim.new(0,4)

local anims,idSet,sel,cur,exp={},{},nil,nil,false

local function stopCur()
    if cur then cur:Stop() cur=nil end
end

local function bindH(h)
    h.Running:Connect(function(s) if s>0 then stopCur() end end)
    h.Jumping:Connect(stopCur)
    h.StateChanged:Connect(function(_,ns)
        if ns==Enum.HumanoidStateType.Climbing or ns==Enum.HumanoidStateType.Freefall or ns==Enum.HumanoidStateType.Swimming then
            stopCur()
        end
    end)
end

if pl.Character then bindH(pl.Character:WaitForChild("Humanoid")) end
pl.CharacterAdded:Connect(function(c) bindH(c:WaitForChild("Humanoid")) end)

local dIn,dSt,iSt
f.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dIn,dSt,iSt=i,f.Position,i.Position
        i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dIn=nil end end)
    end
end)
U.InputChanged:Connect(function(i)
    if i==dIn then
        local d=i.Position-iSt
        f.Position=UDim2.new(dSt.X.Scale,dSt.X.Offset+d.X,dSt.Y.Scale,dSt.Y.Offset+d.Y)
    end
end)

tb.Activated:Connect(function()
    exp=not exp
    tb.Text=exp and"Animations ▲"or"Animations ▼"
    local H=math.clamp(ly.AbsoluteContentSize.Y,0,176)
    T:Create(sf,TweenInfo.new(0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=exp and UDim2.new(1,0,0,H)or UDim2.new(1,0,0,0)}):Play()
    T:Create(f, TweenInfo.new(0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=exp and UDim2.new(0,260,0,60+H)or UDim2.new(0,260,0,60)}):Play()
    if not exp then
        of.Visible=false
        T:Create(of,TweenInfo.new(0.2),{Size=UDim2.new(0,0,0,0)}):Play()
    end
end)

cb.Activated:Connect(function()
    if pl.Character then
        local h=pl.Character:FindFirstChildOfClass("Humanoid")
        for _,t in ipairs((h and h:GetPlayingAnimationTracks())or{})do t:Stop() end
    end
    if exp then
        exp=false; tb.Text="Animations ▼"
        T:Create(sf,TweenInfo.new(0.3),{Size=UDim2.new(1,0,0,0)}):Play()
        T:Create(f, TweenInfo.new(0.3),{Size=UDim2.new(0,260,0,60)}):Play()
        of.Visible=false
        T:Create(of,TweenInfo.new(0.2),{Size=UDim2.new(0,0,0,0)}):Play()
    end
end)

pb.Activated:Connect(function()
    if sel and pl.Character then
        local h=pl.Character:FindFirstChildOfClass("Humanoid")
        if h then
            for _,t in ipairs(h:GetPlayingAnimationTracks())do t:Stop() end
            cur=h:LoadAnimation(sel.anim)
            cur:Play()
        end
    end
    exp=false; tb.Text="Animations ▼"
    T:Create(sf,TweenInfo.new(0.3),{Size=UDim2.new(1,0,0,0)}):Play()
    T:Create(f, TweenInfo.new(0.3),{Size=UDim2.new(0,260,0,60)}):Play()
    of.Visible=false
    T:Create(of,TweenInfo.new(0.2),{Size=UDim2.new(0,0,0,0)}):Play()
end)

cpy.Activated:Connect(function()
    if sel then
        local id=sel.anim.AnimationId:match("%d+")or""
        if setclipboard then setclipboard(id) end
        if syn and syn.set_clipboard then syn.set_clipboard(id) end
    end
    exp=false; tb.Text="Animations ▼"
    T:Create(sf,TweenInfo.new(0.3),{Size=UDim2.new(1,0,0,0)}):Play()
    T:Create(f, TweenInfo.new(0.3),{Size=UDim2.new(0,260,0,60)}):Play()
    of.Visible=false
    T:Create(of,TweenInfo.new(0.2),{Size=UDim2.new(0,0,0,0)}):Play()
end)

task.spawn(function()
    local D=game:GetDescendants()
    local tot=#D
    for i,inst in ipairs(D) do
        local aid
        if inst:IsA("Animation") then
            aid=tonumber(inst.AnimationId:match("%d+") or "")
        elseif (inst:IsA("NumberValue") or inst:IsA("IntValue")) and typeof(inst.Value)=="number" then
            aid=inst.Value
        end
        if aid and not idSet[aid] then
            idSet[aid]=true
            if inst:IsA("Animation") then
                table.insert(anims,{name=inst.Name,anim=inst})
            else
                local ok,info=pcall(function()return M:GetProductInfo(aid,Enum.InfoType.Asset)end)
                if ok and info.AssetTypeId==Enum.AssetType.Animation.Value then
                    local a=Instance.new("Animation")
                    a.Name, a.AnimationId=info.Name,"rbxassetid://"..aid
                    table.insert(anims,{name=info.Name,anim=a})
                end
            end
        end
        ld.Text="Loading... "..math.floor(i/tot*100).."%"
    end
    ld:Destroy()
    for i,d in ipairs(anims) do
        local b=Instance.new("TextButton",sf)
        b.Size=UDim2.new(1,0,0,32)
        b.BackgroundColor3=Color3.fromRGB(50,50,50)
        b.BorderSizePixel=0
        b.Font,b.TextSize,b.TextColor3=Enum.Font.SourceSans,16,Color3.new(1,1,1)
        b.Text=d.name
        b.LayoutOrder=i
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,4)
        b.Activated:Connect(function()
            sel=d
            of.Visible=true
            T:Create(of,TweenInfo.new(0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=UDim2.new(0,120,0,90)}):Play()
        end)
    end
end)