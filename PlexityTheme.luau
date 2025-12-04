local cloneref=cloneref or function(x)return x end
local function ClonedService(n)return cloneref(game:GetService(n))end
local cg=ClonedService("CoreGui")
local ps=ClonedService("Players")
local ui=ClonedService("UserInputService")
local hs=ClonedService("HttpService")
local wf=writefile or writeFile
local rf=readfile or readFile
local isf=isfile or isFile
local isd=isfolder or isFolder
local mkd=makefolder or makeFolder
local fsok=wf and rf and isf and isd and mkd
local cfgDir="GradientPicker"
local cfgPath=cfgDir.."/settings.json"
local Wait=task.wait
local Insert=table.insert

local defData={
    enabled=true,
    start={h=0.8,s=1,v=1},
    finish={h=0,s=1,v=1},
}

local function sGet(inst,prop)
    if not inst then return nil end
    local ok,value=pcall(function()return inst[prop]end)
    if ok then return value end
    return nil
end

local function ensureCfgDir()
    if fsok and not isd(cfgDir) then
        mkd(cfgDir)
    end
end

local function copyColor(target,src)
    if type(src)~="table" then return end
    local function copy(key)
        if type(src[key])=="number" then
            target[key]=src[key]
        end
    end
    copy("h")
    copy("s")
    copy("v")
end

local function loadCfg()
    local data={
        enabled=defData.enabled,
        start={h=defData.start.h,s=defData.start.s,v=defData.start.v},
        finish={h=defData.finish.h,s=defData.finish.s,v=defData.finish.v},
    }
    if fsok then
        ensureCfgDir()
        if isf(cfgPath) then
            local ok,raw=pcall(rf,cfgPath)
            if ok and type(raw)=="string" then
                local ok2,decoded=pcall(hs.JSONDecode,hs,raw)
                if ok2 and type(decoded)=="table" then
                    if type(decoded.enabled)=="boolean" then
                        data.enabled=decoded.enabled
                    end
                    if type(decoded.start)=="table" then
                        copyColor(data.start,decoded.start)
                    end
                    if type(decoded.finish)=="table" then
                        copyColor(data.finish,decoded.finish)
                    end
                    if type(decoded.sH)=="number" then data.start.h=decoded.sH end
                    if type(decoded.sV)=="number" then data.start.v=decoded.sV end
                    if type(decoded.eH)=="number" then data.finish.h=decoded.eH end
                    if type(decoded.eV)=="number" then data.finish.v=decoded.eV end
                end
            end
        end
    end
    return data
end

local function saveCfg(data)
    if fsok then
        ensureCfgDir()
        pcall(function()
            wf(cfgPath,hs:JSONEncode(data))
        end)
    end
end

local PT={
    path=cfgPath,
    default=defData,
    cg=cg,
    images=setmetatable({},{__mode="k"}),
    queue={},
    queueSet={},
    processing=false,
    applying=false,
    data=nil,
}

PT.data=loadCfg()

local HUI=(typeof(gethui)=="function" and gethui()) or nil

local function isTarget(o)
    if not o then return false end
    if HUI and o:IsDescendantOf(HUI) then
        return false
    end
    return o:IsA("ImageLabel") or o:IsA("ImageButton") or o:IsA("TextLabel") or o:IsA("TextButton")
end

local function getImgId(o)
    local value=sGet(o,"Image")
    if type(value)=="string" and value~="" then return value end
    value=sGet(o,"Texture")
    if type(value)=="string" and value~="" then return value end
    value=sGet(o,"TextureId")
    if type(value)=="string" and value~="" then return value end
    return nil
end

local function fixTxt(o)
    local text=sGet(o,"Text")
    if type(text)=="string" and text:find("Connection") then
        o.Text=text:gsub("Connections","Friends"):gsub("Connection","Friend")
    end
end

local function remGrad(o)
    if not o then return end
    local existing=o:FindFirstChildOfClass("UIGradient")
    if existing then existing:Destroy() end
end

local function applyGrad(o)
    remGrad(o)
    if not PT.data.enabled then
        return
    end
    if not (o and o.Parent) then
        return
    end
    local seq=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromHSV(PT.data.start.h,PT.data.start.s,PT.data.start.v)),
        ColorSequenceKeypoint.new(1,Color3.fromHSV(PT.data.finish.h,PT.data.finish.s,PT.data.finish.v)),
    }
    local ug=Instance.new("UIGradient")
    ug.Name="\0"
    ug.Color=seq
    ug.Rotation=45
    ug.Transparency=NumberSequence.new{
        NumberSequenceKeypoint.new(0,0,0),
        NumberSequenceKeypoint.new(0.5,0,0),
        NumberSequenceKeypoint.new(1,0,0),
    }
    ug.Parent=o
end

local function applyReady(o)
    if not (o and o.Parent) then
        return false
    end
    if HUI and o:IsDescendantOf(HUI) then
        return false
    end
    fixTxt(o)
    if PT.images[o] then
        applyGrad(o)
        return true
    end
    if not isTarget(o) then
        return false
    end
    local imgId=getImgId(o)
    if type(imgId)=="string" and imgId:match("img_set_%dx_%d+%.png$") then
        PT.images[o]=true
        applyGrad(o)
        return true
    end
    if o:IsA("TextLabel") or o:IsA("TextButton") then
        local ff=sGet(o,"FontFace")
        local ffType=ff and typeof(ff) or nil
        local fam=ff and ff.Family or nil
        if (ffType=="Font" or ffType=="FontFace") and type(fam)=="string" and fam:find("BuilderIcons/BuilderIcons.json",1,true) then
            PT.images[o]=true
            applyGrad(o)
            return true
        end
    end
    return false
end

local function qAdd(o)
    if not o then return end
    if PT.queueSet[o] then return end
    if HUI and o:IsDescendantOf(HUI) then return end
    PT.queueSet[o]=true
    Insert(PT.queue,o)
end

local function processQ()
    if PT.processing then return end
    PT.processing=true
    task.spawn(function()
        while #PT.queue>0 do
            local stepCount=math.min(#PT.queue,50)
            for i=1,stepCount do
                local target=table.remove(PT.queue,1)
                if target then
                    PT.queueSet[target]=nil
                    if target.Parent then
                        applyReady(target)
                    end
                end
            end
            Wait()
        end
        PT.processing=false
    end)
end

function PT.applyAll()
    if PT.applying then
        return
    end
    PT.applying=true
    task.spawn(function()
        local n=0
        for o in pairs(PT.images) do
            if o and o.Parent then
                applyGrad(o)
            else
                PT.images[o]=nil
            end
            n+=1
            if n%50==0 then
                Wait()
            end
        end
        PT.applying=false
    end)
end

local function rescan()
    task.spawn(function()
        local target=PT.cg
        if not target then return end
        local desc=target:GetDescendants()
        for i=1,#desc do
            qAdd(desc[i])
            if i%200==0 then
                Wait()
            end
        end
        processQ()
    end)
end

local function onDescAdded(o)
    task.spawn(function()
        qAdd(o)
        local desc=o:GetDescendants()
        for i=1,#desc do
            qAdd(desc[i])
            if i%100==0 then
                Wait()
            end
        end
        processQ()
    end)
end

if PT.cg then
    PT.cg.DescendantAdded:Connect(onDescAdded)
end

rescan()

local stops={0,1/6,2/6,3/6,4/6,5/6,1}
local sliders={}

local function refresh()
    PT.applyAll()
    if fsok then
        saveCfg(PT.data)
    end
    for _,s in ipairs(sliders)do
        local t=s.get()
        s.handle.Position=UDim2.new(t*(1-s.handle.Size.X.Scale),0,0,0)
        if s.isVal then
            local hue=s.getHue()
            s.grad.Color=ColorSequence.new{
                ColorSequenceKeypoint.new(0,Color3.fromHSV(hue,1,0)),
                ColorSequenceKeypoint.new(1,Color3.fromHSV(hue,1,1)),
            }
            s.track.BackgroundColor3=Color3.fromHSV(hue,1,t)
        else
            local pts={}
            for _,v in ipairs(stops)do
                pts[#pts+1]=ColorSequenceKeypoint.new(v,Color3.fromHSV(v,1,1))
            end
            s.grad.Color=ColorSequence.new(pts)
            s.track.BackgroundColor3=Color3.new(1,1,1)
        end
    end
end

local sg=Instance.new("ScreenGui",ps.LocalPlayer and ps.LocalPlayer:FindFirstChild("PlayerGui")or cg)
sg.Name="\0";sg.IgnoreGuiInset=true;sg.DisplayOrder=50
local tb=Instance.new("TextButton",sg)
tb.Name="\0";tb.AnchorPoint=Vector2.new(0.5,0);tb.Position=UDim2.new(0.5,0,0.02,0)
tb.Size=UDim2.new(0.05,0,0.06,0);tb.BackgroundColor3=Color3.fromRGB(40,40,40);tb.BorderSizePixel=0
tb.Font=Enum.Font.GothamBold;tb.TextSize=24;tb.TextColor3=Color3.fromRGB(200,200,200);tb.Text="v"
Instance.new("UICorner",tb).Name="\0";tb:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(1,0)
Instance.new("UIStroke",tb).Name="\0";tb:FindFirstChildOfClass("UIStroke").Color=Color3.fromRGB(70,70,70)
local fr=Instance.new("Frame",sg)
fr.Name="\0";fr.AnchorPoint=Vector2.new(0.5,0);fr.Position=UDim2.new(0.5,0,0.1,0)
fr.Size=UDim2.new(0.35,0,0.6,0);fr.BackgroundColor3=Color3.fromRGB(30,30,30);fr.BorderSizePixel=0;fr.Active=true;fr.Visible=false
Instance.new("UICorner",fr).Name="\0";fr:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0.05,0)
Instance.new("UIStroke",fr).Name="\0";fr:FindFirstChildOfClass("UIStroke").Color=Color3.fromRGB(70,70,70)
local tl=Instance.new("Frame",fr)
tl.Name="\0";tl.Size=UDim2.new(1,0,0.1,0);tl.Position=UDim2.new(0,0,0,0);tl.BackgroundColor3=Color3.fromRGB(40,40,40);tl.BorderSizePixel=0;tl.Active=true
Instance.new("UICorner",tl).Name="\0";tl:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0.05,0)
local lb=Instance.new("TextLabel",tl)
lb.Name="\0";lb.Size=UDim2.new(1,0,1,0);lb.BackgroundTransparency=1;lb.Font=Enum.Font.GothamBold;lb.TextSize=18;lb.TextColor3=Color3.fromRGB(220,220,220);lb.Text="Gradient Picker"
local draggingFr=false
local d0,fp
tl.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        draggingFr=true
        d0=i.Position
        fp=fr.Position
    end
end)
ui.InputChanged:Connect(function(i)
    if draggingFr then
        local d=i.Position-d0
        fr.Position=UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)
    end
end)
ui.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        draggingFr=false
    end
end)
local draggingSl=false
local cur
ui.InputChanged:Connect(function(i)
    if draggingSl and cur then
        local p,s=cur.track.AbsolutePosition,cur.track.AbsoluteSize
        local t=math.clamp((i.Position.X-p.X)/s.X,0,1)
        cur.set(t)
        refresh()
    end
end)
ui.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        draggingSl=false
    end
end)
local function mk(label,isV,getV,setV,getH)
    local idx=#sliders+1
    local y=0.15+(idx-1)*0.18
    local lt=Instance.new("TextLabel",fr)
    lt.Name="\0";lt.Size=UDim2.new(0.5,0,0.05,0);lt.Position=UDim2.new(0.05,0,y,0);lt.BackgroundTransparency=1;lt.Font=Enum.Font.Gotham;lt.TextSize=14;lt.TextColor3=Color3.fromRGB(200,200,200);lt.Text=label
    local tr=Instance.new("Frame",fr)
    tr.Name="\0";tr.Size=UDim2.new(0.9,0,0.05,0);tr.Position=UDim2.new(0.05,0,y+0.05,0);tr.Active=true;tr.BorderSizePixel=0;tr.BackgroundColor3=isV and Color3.fromHSV(getH(),1,getV()) or Color3.new(1,1,1)
    Instance.new("UICorner",tr).Name="\0";tr:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0.02,0)
    local gr=Instance.new("UIGradient",tr)
    gr.Name="\0"
    if isV then
        gr.Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.fromHSV(getH(),1,0)),
            ColorSequenceKeypoint.new(1,Color3.fromHSV(getH(),1,1)),
        }
    else
        local pts={}
        for _,v in ipairs(stops)do
            pts[#pts+1]=ColorSequenceKeypoint.new(v,Color3.fromHSV(v,1,1))
        end
        gr.Color=ColorSequence.new(pts)
    end
    local hd=Instance.new("Frame",tr)
    hd.Name="\0";hd.Size=UDim2.new(0.04,0,1,0);hd.BackgroundColor3=Color3.fromRGB(240,240,240);hd.Active=true
    Instance.new("UICorner",hd).Name="\0";hd:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0.5,0)
    Instance.new("UIStroke",hd).Name="\0";hd:FindFirstChildOfClass("UIStroke").Color=Color3.fromRGB(150,150,150)
    local entry={track=tr,grad=gr,handle=hd,isVal=isV,get=getV,set=setV,getHue=getH}
    sliders[#sliders+1]=entry
    local function beginDrag(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            draggingSl=true
            cur=entry
        end
    end
    hd.InputBegan:Connect(beginDrag)
    tr.InputBegan:Connect(beginDrag)
end

mk("Start Hue",false,function()return PT.data.start.h end,function(v)PT.data.start.h=v end,function()return PT.data.start.h end)
mk("Start Brightness",true,function()return PT.data.start.v end,function(v)PT.data.start.v=v end,function()return PT.data.start.h end)
mk("End Hue",false,function()return PT.data.finish.h end,function(v)PT.data.finish.h=v end,function()return PT.data.finish.h end)
mk("End Brightness",true,function()return PT.data.finish.v end,function(v)PT.data.finish.v=v end,function()return PT.data.finish.h end)
tb.Activated:Connect(function()
    fr.Visible=not fr.Visible
    tb.Text=fr.Visible and"^"or"v"
    if fr.Visible then refresh() end
end)
refresh()
