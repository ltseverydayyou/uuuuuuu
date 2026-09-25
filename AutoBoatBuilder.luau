local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local P=Players.LocalPlayer
local PG=P:WaitForChild("PlayerGui")
local RS=game:GetService("ReplicatedStorage")
local BP=RS:WaitForChild("BuildingParts")

if _G.BABFTSmartBuilder and _G.BABFTSmartBuilder.Stop then pcall(_G.BABFTSmartBuilder.Stop) end
local old=PG:FindFirstChild("BABFTSmartBuilder")
if old then old:Destroy() end

local S={Building=false,Cancel=false,Delay=0.002,LastMode="adaptive",Built=0,Total=0}

local function charHum()
    local c=P.Character or P.CharacterAdded:Wait()
    return c,c:WaitForChild("Humanoid")
end

local function getZone()
    return workspace:FindFirstChild(tostring(P.TeamColor).."Zone")
end

local function inZone(cf,z)
    local p=typeof(cf)=="CFrame" and cf.Position or cf.Position
    local sx,sz=z.Size.X,z.Size.Z
    if math.abs(z.Rotation.Y)>89 and math.abs(z.Rotation.Y)<91 then sx,sz=sz,sx end
    return p.X>z.Position.X-sx/2 and p.X<z.Position.X+sx/2 and p.Z>z.Position.Z-sz/2 and p.Z<z.Position.Z+sz/2
end

local function invOwner()
    local o=P
    local t=P.Team
    local leader=t and t:FindFirstChild("TeamLeader") and Players:FindFirstChild(t.TeamLeader.Value)
    if leader and P:FindFirstChild("Settings") and P.Settings:FindFirstChild("ShareBlocks") and P.Settings.ShareBlocks.Value then
        o=leader
    end
    return o
end

local function totalCount(name)
    local o=invOwner()
    local v=o:FindFirstChild("Data") and o.Data:FindFirstChild(name)
    return v and v.Value or 0
end

local function usedCounts()
    local out={}
    local z=getZone()
    local blocks=workspace:FindFirstChild("Blocks")
    if not z or not blocks then return out end
    for _,folder in ipairs(blocks:GetChildren()) do
        for _,m in ipairs(folder:GetChildren()) do
            if m:IsA("Model") and m.PrimaryPart and inZone(m.PrimaryPart.CFrame,z) then
                local base=BP:FindFirstChild(m.Name)
                if base and base.PrimaryPart then
                    local bv=base.PrimaryPart.Size.X*base.PrimaryPart.Size.Y*base.PrimaryPart.Size.Z
                    local sv=m.PrimaryPart.Size.X*m.PrimaryPart.Size.Y*m.PrimaryPart.Size.Z
                    out[m.Name]=(out[m.Name] or 0)+math.max(sv/bv,1)
                end
            end
        end
    end
    return out
end

local function freeCount(name,used)
    return math.max(0,math.floor(totalCount(name)-(used[name] or 0)+0.0001))
end

local function structuralInventory()
    local used=usedCounts()
    local arr,total={},0
    local data=invOwner():FindFirstChild("Data")
    if not data then return arr,0,used end
    for _,v in ipairs(data:GetChildren()) do
        if v:IsA("IntValue") and v.Value>0 then
            local m=BP:FindFirstChild(v.Name)
            if m and m:IsA("Model") and m.PrimaryPart and m:FindFirstChild("Health") then
                local sz=m.PrimaryPart.Size
                if math.abs(sz.X-2)<0.05 and math.abs(sz.Y-2)<0.05 and math.abs(sz.Z-2)<0.05 and string.find(v.Name,"Block") and v.Name~="BalloonBlock" then
                    local free=freeCount(v.Name,used)
                    if free>0 then
                        table.insert(arr,{name=v.Name,count=free,health=m.Health.Value})
                        total+=free
                    end
                end
            end
        end
    end
    table.sort(arr,function(a,b)
        if a.health==b.health then return a.count>b.count end
        return a.health>b.health
    end)
    return arr,total,used
end

local function equip(name)
    local c,h=charHum()
    local t=P.Backpack:FindFirstChild(name) or c:FindFirstChild(name)
    if not t then return nil end
    if t.Parent~=c then h:EquipTool(t) task.wait(0.04) end
    return c:FindFirstChild(name) or t
end

local function unequip()
    local _,h=charHum()
    h:UnequipTools()
end

local function rotOf(name)
    local m=BP:FindFirstChild(name)
    return m and m.PrimaryPart and m.PrimaryPart.CFrame.Rotation or CFrame.new()
end

local function deckY(name)
    local m=BP:FindFirstChild(name)
    local sy=m and m.PrimaryPart and m.PrimaryPart.Size.Y or 2
    return 1+sy/2
end

local function place(tool,name,offset,yaw,z)
    local localData=P:FindFirstChild("Data") and P.Data:FindFirstChild(name)
    local amount=localData and localData.Value or totalCount(name)
    if amount<=0 then return false end
    local baseY=z.Size.Y/2+1
    local cf=z.CFrame*CFrame.new(offset.X,baseY+offset.Y,offset.Z)*rotOf(name)*CFrame.Angles(0,yaw or 0,0)
    local ok=pcall(function()
        tool.RF:InvokeServer(name,amount,z,z.CFrame:ToObjectSpace(cf),false,cf,false,false)
    end)
    if ok then S.Built+=1 end
    return ok
end

local function clearMine()
    if S.Building then
        S.Cancel=true
        repeat task.wait() until not S.Building
    end
    local blocks=workspace:FindFirstChild("Blocks")
    local f=blocks and blocks:FindFirstChild(P.Name)
    if not f then return 0 end
    local t=equip("DeleteTool")
    if not t or not t:FindFirstChild("RF") then unequip() return 0 end

    local items=f:GetChildren()
    local removed=0
    local batch=35

    for i=1,#items,batch do
        local remaining=0
        local signal=Instance.new("BindableEvent")

        for j=i,math.min(i+batch-1,#items) do
            local m=items[j]
            if m and m.Parent==f then
                remaining+=1
                task.spawn(function()
                    local ok=pcall(function() t.RF:InvokeServer(m) end)
                    if ok then removed+=1 end
                    remaining-=1
                    if remaining==0 then signal:Fire() end
                end)
            end
        end

        if remaining>0 then
            task.delay(0.8,function()
                if remaining>0 then signal:Fire() end
            end)
            signal.Event:Wait()
        end
        signal:Destroy()
        task.wait()
    end

    unequip()
    return removed
end

local function rowWidth(maxW,idx,len)
    local mid=(len+1)/2
    local rel=(idx-mid)/(mid-1)
    local f=1
    if rel>0.45 then
        f=1-(rel-0.45)/0.55*0.78
    elseif rel<-0.82 then
        f=0.72+(rel+1)/0.18*0.28
    end
    local w=math.max(3,math.floor(maxW*f))
    if w%2==0 then w-=1 end
    return math.min(maxW,w)
end

local function addUnique(parts,seen,role,x,y,z,support)
    local k=math.round(x*10)..":"..math.round(y*10)..":"..math.round(z*10)
    if seen[k] then return end
    seen[k]=true
    table.insert(parts,{role=role,offset=Vector3.new(x,y,z),support=support or 0})
end

local function geometry(maxW,len)
    local parts,seen={},{}
    local mid=(len+1)/2
    local half=(len-1)/2

    for i=1,len do
        local z=(i-mid)*2
        local w=rowWidth(maxW,i,len)
        local hw=(w-1)/2

        addUnique(parts,seen,"floor",0,0,z,0)
        for d=1,hw do
            addUnique(parts,seen,d==hw and "shell" or "floor",-d*2,0,z,d)
            addUnique(parts,seen,d==hw and "shell" or "floor", d*2,0,z,d)
        end
    end

    for i=1,len do
        local z=(i-mid)*2
        local hw=(rowWidth(maxW,i,len)-1)/2
        addUnique(parts,seen,"shell",-hw*2,2,z,0)
        if hw>0 then addUnique(parts,seen,"shell",hw*2,2,z,0) end

        if i%2==1 and i>2 and i<len-2 then
            addUnique(parts,seen,"shell",-hw*2,4,z,0)
            if hw>0 then addUnique(parts,seen,"shell",hw*2,4,z,0) end
        end
    end

    local cabW=math.max(5,maxW-8)
    if cabW%2==0 then cabW-=1 end
    local cabHalf=(cabW-1)/2
    local cabLen=math.max(7,math.min(11,math.floor(len/3)))
    if cabLen%2==0 then cabLen-=1 end
    local cStart=-math.floor(cabLen/2)*2-2
    local cEnd=cStart+(cabLen-1)*2

    for z=cStart,cEnd,2 do
        addUnique(parts,seen,"cabin",-cabHalf*2,2,z,0)
        if cabHalf>0 then addUnique(parts,seen,"cabin",cabHalf*2,2,z,0) end
    end

    for z=cStart,cEnd,2 do
        addUnique(parts,seen,"window",-cabHalf*2,4,z,0)
        if cabHalf>0 then addUnique(parts,seen,"window",cabHalf*2,4,z,0) end
    end

    for z=cStart,cEnd,2 do
        addUnique(parts,seen,"cabin",-cabHalf*2,6,z,0)
        if cabHalf>0 then addUnique(parts,seen,"cabin",cabHalf*2,6,z,0) end
        for d=cabHalf-1,0,-1 do
            if d==0 then
                addUnique(parts,seen,"cabin",0,6,z,cabHalf)
            else
                addUnique(parts,seen,"cabin",-d*2,6,z,cabHalf-d)
                addUnique(parts,seen,"cabin", d*2,6,z,cabHalf-d)
            end
        end
    end

    return parts,{
        width=maxW,
        length=len,
        stern=-half*2,
        bow=half*2,
        bowWidth=rowWidth(maxW,len,len),
        cabWidth=cabW,
        cabStart=cStart,
        cabEnd=cEnd
    }
end

local function assignMaterials(parts,inv)
    local remaining,health={},{}
    for _,e in ipairs(inv) do
        remaining[e.name]=e.count
        health[e.name]=e.health
    end

    local strong={}
    for _,e in ipairs(inv) do table.insert(strong,e.name) end
    table.sort(strong,function(a,b)
        if health[a]==health[b] then return (remaining[a] or 0)>(remaining[b] or 0) end
        return health[a]>health[b]
    end)

    local function abundant()
        local best,bestN=nil,-1
        for n,c in pairs(remaining) do
            if c>bestN then best,bestN=n,c end
        end
        return best
    end

    local function take(role)
        local n
        if role=="shell" then
            for _,x in ipairs(strong) do
                if (remaining[x] or 0)>0 then n=x break end
            end
        elseif role=="window" and (remaining.IceBlock or 0)>0 then
            n="IceBlock"
        elseif role=="cabin" and (remaining.BrickBlock or 0)>0 then
            n="BrickBlock"
        else
            n=abundant()
        end
        if not n then return nil end
        remaining[n]-=1
        return n
    end

    local out,used={},{}
    for _,p in ipairs(parts) do
        local n=take(p.role)
        if n then
            p.name=n
            used[n]=(used[n] or 0)+1
            table.insert(out,p)
        end
    end
    return out,used
end

local function addSpecials(plan,dims,mode,usedNow)
    local function freeSpecial(name)
        return freeCount(name,usedNow)
    end

    local function consume(name)
        usedNow[name]=(usedNow[name] or 0)+1
    end

    local function addDeck(name,x,z,yaw)
        if freeSpecial(name)<=0 then return false end
        table.insert(plan,{
            name=name,
            offset=Vector3.new(x,deckY(name),z),
            yaw=yaw or 0,
            special=true,
            support=0
        })
        consume(name)
        return true
    end

    local function addFoundation(name,x,z,yaw)
        if freeSpecial(name)<=0 then return false end
        table.insert(plan,{
            name=name,
            offset=Vector3.new(x,0,z),
            yaw=yaw or 0,
            special=true,
            foundationSpecial=true,
            support=0
        })
        consume(name)
        return true
    end

    if freeSpecial("Seat")>0 then
        addDeck("Seat",0,-2,0)
    elseif freeSpecial("CarSeat")>0 then
        addDeck("CarSeat",0,-2,0)
    end

    addDeck("BoatMotor",0,dims.stern+2,0)

    local thr=math.min(freeSpecial("Thruster"),mode=="max" and 6 or 4)
    local sternWidth=rowWidth(dims.width,2,dims.length)
    local sternHalf=(sternWidth-1)
    local side=math.min(math.max(2,dims.width-5),sternHalf)

    for i=1,thr do
        local x=i%2==1 and -side or side
        local z=dims.stern+2+math.floor((i-1)/2)*2
        addDeck("Thruster",x,z,0)
    end

    local bowHalf=(dims.bowWidth-1)/2
    local wedgeN=math.min(freeSpecial("Wedge"),dims.bowWidth)
    local placed=0
    for d=0,bowHalf do
        if placed>=wedgeN then break end
        if d==0 then
            addFoundation("Wedge",0,dims.bow+2,math.pi)
            placed+=1
        else
            if placed<wedgeN then
                addFoundation("Wedge",-d*2,dims.bow+2,math.pi)
                placed+=1
            end
            if placed<wedgeN then
                addFoundation("Wedge", d*2,dims.bow+2,math.pi)
                placed+=1
            end
        end
    end

    if mode=="war" or mode=="max" then
        local cannons=math.min(freeSpecial("Cannon"),6)
        local sideX=dims.width-1
        for i=1,cannons do
            local left=i%2==1
            addDeck("Cannon",left and -sideX or sideX,-2+math.floor((i-1)/2)*6,left and -math.pi/2 or math.pi/2)
        end

        local harps=math.min(freeSpecial("Harpoon"),3)
        local hx={0,-2,2}
        for i=1,harps do
            addDeck("Harpoon",hx[i],dims.bow-4,0)
        end
    end
end

local function sortBuildOrder(parts)
    table.sort(parts,function(a,b)
        local ay,by=a.offset.Y,b.offset.Y
        if ay~=by then return ay<by end

        local af=a.foundationSpecial and 1 or 0
        local bf=b.foundationSpecial and 1 or 0
        if af~=bf then return af<bf end

        if ay==0 then
            local az,bz=math.abs(a.offset.Z),math.abs(b.offset.Z)
            if az~=bz then return az<bz end
            local ax,bx=math.abs(a.offset.X),math.abs(b.offset.X)
            if ax~=bx then return ax<bx end
        end

        local as=a.special and 1 or 0
        local bs=b.special and 1 or 0
        if as~=bs then return as<bs end

        local ar,br=a.support or 0,b.support or 0
        if ar~=br then return ar<br end

        local az,bz=math.abs(a.offset.Z),math.abs(b.offset.Z)
        if az~=bz then return az<bz end
        return math.abs(a.offset.X)<math.abs(b.offset.X)
    end)
end

local function makePlan(mode)
    local inv,total,usedNow=structuralInventory()
    if total<25 then return nil,"Only "..total.." free structural blocks detected." end

    local ratio=mode=="max" and 0.86 or mode=="war" and 0.72 or 0.68
    local cap=mode=="max" and 1050 or mode=="war" and 850 or 800
    local target=math.clamp(math.floor(total*ratio),60,cap)

    local bestParts,bestDims
    for w=7,23,2 do
        local len=math.min(55,w*2+5)
        if len%2==0 then len-=1 end
        local g,d=geometry(w,len)
        if #g<=target and (not bestParts or #g>#bestParts) then
            bestParts,bestDims=g,d
        end
    end

    if not bestParts then bestParts,bestDims=geometry(7,19) end

    local assigned,usedMat=assignMaterials(bestParts,inv)
    addSpecials(assigned,bestDims,mode,usedNow)
    sortBuildOrder(assigned)

    return {
        parts=assigned,
        dims=bestDims,
        structural=#bestParts,
        total=#assigned,
        available=total,
        target=target,
        materials=usedMat
    }
end

local gui=Instance.new("ScreenGui")
gui.Name="BABFTSmartBuilder"
gui.ResetOnSpawn=false
gui.Parent=PG

local f=Instance.new("Frame")
f.Size=UDim2.fromOffset(360,410)
f.Position=UDim2.new(0,18,0.5,-205)
f.BackgroundColor3=Color3.fromRGB(24,24,28)
f.BorderSizePixel=0
f.Parent=gui
Instance.new("UICorner",f).CornerRadius=UDim.new(0,10)
local stroke=Instance.new("UIStroke",f)
stroke.Color=Color3.fromRGB(70,70,78)

local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-20,0,32)
title.Position=UDim2.fromOffset(10,8)
title.BackgroundTransparency=1
title.TextXAlignment=Enum.TextXAlignment.Left
title.Font=Enum.Font.GothamBold
title.TextSize=17
title.TextColor3=Color3.fromRGB(242,242,247)
title.Text="BABFT Inventory-Aware Builder"
title.Parent=f

local info=Instance.new("TextLabel")
info.Size=UDim2.new(1,-20,0,70)
info.Position=UDim2.fromOffset(10,42)
info.BackgroundColor3=Color3.fromRGB(32,32,37)
info.BorderSizePixel=0
info.TextWrapped=true
info.TextXAlignment=Enum.TextXAlignment.Left
info.Font=Enum.Font.Gotham
info.TextSize=12
info.TextColor3=Color3.fromRGB(200,200,210)
info.Parent=f
Instance.new("UICorner",info).CornerRadius=UDim.new(0,7)

local barbg=Instance.new("Frame")
barbg.Size=UDim2.new(1,-20,0,6)
barbg.Position=UDim2.fromOffset(10,120)
barbg.BackgroundColor3=Color3.fromRGB(48,48,55)
barbg.BorderSizePixel=0
barbg.Parent=f
Instance.new("UICorner",barbg).CornerRadius=UDim.new(1,0)

local bar=Instance.new("Frame")
bar.Size=UDim2.fromScale(0,1)
bar.BackgroundColor3=Color3.fromRGB(130,160,255)
bar.BorderSizePixel=0
bar.Parent=barbg
Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)

local function button(text,x,y,w)
    local b=Instance.new("TextButton")
    b.Size=UDim2.fromOffset(w or 108,38)
    b.Position=UDim2.fromOffset(x,y)
    b.BackgroundColor3=Color3.fromRGB(43,43,50)
    b.BorderSizePixel=0
    b.Font=Enum.Font.GothamMedium
    b.TextSize=13
    b.TextColor3=Color3.fromRGB(238,238,242)
    b.Text=text
    b.Parent=f
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
    return b
end

local adaptive=button("Adaptive Boat",10,138,108)
local maxb=button("Max Boat",126,138,108)
local war=button("War Boat",242,138,108)
local clear=button("Clear Build",10,184,108)
local rebuild=button("Rebuild Last",126,184,108)
local rescan=button("Rescan",242,184,108)
local stop=button("Stop",10,230,82)
local launch=button("Launch",268,230,82)

local delay=Instance.new("TextBox")
delay.Size=UDim2.fromOffset(158,38)
delay.Position=UDim2.fromOffset(101,230)
delay.BackgroundColor3=Color3.fromRGB(35,35,41)
delay.BorderSizePixel=0
delay.Font=Enum.Font.Gotham
delay.TextSize=13
delay.TextColor3=Color3.fromRGB(235,235,240)
delay.Text="Placement delay: "..S.Delay
delay.ClearTextOnFocus=false
delay.Parent=f
Instance.new("UICorner",delay).CornerRadius=UDim.new(0,7)

local mats=Instance.new("TextLabel")
mats.Size=UDim2.new(1,-20,0,125)
mats.Position=UDim2.fromOffset(10,278)
mats.BackgroundTransparency=1
mats.TextWrapped=true
mats.TextXAlignment=Enum.TextXAlignment.Left
mats.TextYAlignment=Enum.TextYAlignment.Top
mats.Font=Enum.Font.Gotham
mats.TextSize=12
mats.TextColor3=Color3.fromRGB(155,155,165)
mats.Parent=f

local dragging,dragStart,startPos
title.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true
        dragStart=i.Position
        startPos=f.Position
    end
end)
title.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
        local d=i.Position-dragStart
        f.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)

local function matString(t)
    local a={}
    for n,c in pairs(t or {}) do table.insert(a,{n,c}) end
    table.sort(a,function(x,y) return x[2]>y[2] end)
    local s={}
    for i=1,math.min(#a,5) do table.insert(s,a[i][1]..": "..a[i][2]) end
    return table.concat(s," | ")
end

local function refresh()
    if S.Building then return end
    local p,err=makePlan("adaptive")
    if not p then info.Text=err mats.Text="" return end

    info.Text=("Free structural blocks: %d\nAdaptive: %d structural / %d total — %d wide × %d rows"):format(
        p.available,p.structural,p.total,p.dims.width,p.dims.length
    )

    mats.Text="Order: floor center-out → hull walls → cabin/windows → roof → deck-mounted specials. No blocks use negative Y. Bow wedges are limited to the supported bow width.\nMaterials: "..matString(p.materials)
end

delay.FocusLost:Connect(function()
    local n=tonumber(delay.Text:match("[%d%.]+"))
    if n then S.Delay=math.clamp(n,0,0.1) end
    delay.Text="Placement delay: "..S.Delay
end)

local function build(mode)
    if S.Building then return end
    local plan,err=makePlan(mode)
    if not plan then info.Text=err return end

    local z=getZone()
    if not z then info.Text="Build zone not found." return end

    local t=equip("BuildingTool")
    if not t or not t:FindFirstChild("RF") then
        unequip()
        info.Text="BuildingTool/RF unavailable."
        return
    end

    S.Building=true
    S.Cancel=false
    S.Built=0
    S.Total=plan.total
    S.LastMode=mode

    mats.Text=("Supported bottom-to-top plan | structural %d/%d | %s"):format(
        plan.structural,plan.available,matString(plan.materials)
    )

    for i,piece in ipairs(plan.parts) do
        if S.Cancel then break end

        place(t,piece.name,piece.offset,piece.yaw or 0,z)
        bar.Size=UDim2.fromScale(i/plan.total,1)
        info.Text=("%s: %d/%d\nSupported bottom-to-top | hull %d wide × %d rows | %.3fs"):format(
            mode,i,plan.total,plan.dims.width,plan.dims.length,S.Delay
        )

        if S.Delay>0 then task.wait(S.Delay) end
    end

    unequip()
    S.Building=false

    if S.Cancel then
        info.Text=("Stopped after %d server placements."):format(S.Built)
    else
        info.Text=("%s complete: %d placements, supported bottom-to-top."):format(mode,S.Built)
    end
end

adaptive.MouseButton1Click:Connect(function() task.spawn(build,"adaptive") end)
maxb.MouseButton1Click:Connect(function() task.spawn(build,"max") end)
war.MouseButton1Click:Connect(function() task.spawn(build,"war") end)

clear.MouseButton1Click:Connect(function()
    task.spawn(function()
        info.Text="Turbo-clearing your build..."
        local n=clearMine()
        bar.Size=UDim2.fromScale(0,1)
        info.Text=("Cleared %d models."):format(n)
        task.wait(0.03)
        refresh()
    end)
end)

rebuild.MouseButton1Click:Connect(function()
    if S.Building then return end
    task.spawn(function()
        local m=S.LastMode
        info.Text="Turbo-clearing before rebuild..."
        clearMine()
        task.wait(0.03)
        build(m)
    end)
end)

rescan.MouseButton1Click:Connect(refresh)
stop.MouseButton1Click:Connect(function()
    S.Cancel=true
    info.Text="Stopping after current placement..."
end)

launch.MouseButton1Click:Connect(function()
    local z=getZone()
    local r=z and z:FindFirstChild("VoteLaunchRE")
    if r and r:IsA("RemoteEvent") then
        r:FireServer()
        info.Text="Launch request sent."
    else
        info.Text="Launch remote not found."
    end
end)

_G.BABFTSmartBuilder={
    Stop=function() S.Cancel=true end,
    Clear=function() task.spawn(function() clearMine() refresh() end) end,
    BuildAdaptive=function() task.spawn(build,"adaptive") end,
    BuildMax=function() task.spawn(build,"max") end,
    BuildWar=function() task.spawn(build,"war") end,
    GetPlan=function(mode) return makePlan(mode or "adaptive") end,
    Refresh=refresh,
    State=S,
    Gui=gui
}

refresh()
