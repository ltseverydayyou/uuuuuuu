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
local cfg="GradientPicker/settings.json"
local sH,sV,eH,eV=0.8,1,0,1
if fsok then
    if not isd("GradientPicker")then mkd("GradientPicker")end
    if isf(cfg)then
        local ok,raw=pcall(rf,cfg)
        if ok then
            local ok2,obj=pcall(hs.JSONDecode,hs,raw)
            if ok2 and type(obj)=="table"then
                sH=obj.sH or sH;sV=obj.sV or sV
                eH=obj.eH or eH;eV=obj.eV or eV
            end
        end
    end
end
local stops={0,1/6,2/6,3/6,4/6,5/6,1}
local sliders={}
local function applyGrad(o)
    if not(o:IsA("ImageLabel")or o:IsA("ImageButton"))then return end
    local id=o.Image or o.Texture or o.TextureId
    if not id then return end
    local sc,idx=id:match("img_set_(%dx)_(%d+)%.png$")
    if not sc or not idx then return end
    local sn=tonumber(sc:sub(1,-2))
    local inum=tonumber(idx)
    if sn<1 or sn>10 or inum<0 or inum>50 then return end
    local seq=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromHSV(sH,1,sV)),
        ColorSequenceKeypoint.new(1,Color3.fromHSV(eH,1,eV)),
    }
    local old=o:FindFirstChildOfClass("UIGradient")
    if old then old:Destroy() end
    local ug=Instance.new("UIGradient",o)
    ug.Name="\0";ug.Color=seq;ug.Rotation=45
end
local function fixText(o)
    if type(o.Text)=="string"and o.Text:find("Connection")then
        o.Text=o.Text:gsub("Connections","Friends"):gsub("Connection","Friend")
    end
end
for _,o in ipairs(cg:GetDescendants())do
    applyGrad(o)
    if o:IsA("TextLabel")or o:IsA("TextButton")or o:IsA("TextBox")then fixText(o)end
end
cg.DescendantAdded:Connect(function(o)
    applyGrad(o)
    if o:IsA("TextLabel")or o:IsA("TextButton")or o:IsA("TextBox")then fixText(o)end
    for _,c in ipairs(o:GetDescendants())do
        applyGrad(c)
        if c:IsA("TextLabel")or c:IsA("TextButton")or c:IsA("TextBox")then fixText(c)end
    end
end)
local function refreshAll()
    for _,o in ipairs(cg:GetDescendants())do applyGrad(o)end
    if fsok then pcall(wf,cfg,hs:JSONEncode{ sH=sH,sV=sV,eH=eH,eV=eV })end
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
            for _,v in ipairs(stops)do pts[#pts+1]=ColorSequenceKeypoint.new(v,Color3.fromHSV(v,1,1))end
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
local draggingFr=false;local d0,fp
tl.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then draggingFr=true;d0=i.Position;fp=fr.Position end end)
ui.InputChanged:Connect(function(i)if draggingFr then local d=i.Position-d0;fr.Position=UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)end end)
ui.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then draggingFr=false end end)
local draggingSl=false;local cur
ui.InputChanged:Connect(function(i)if draggingSl and cur then local p,s=cur.track.AbsolutePosition,cur.track.AbsoluteSize;local t=math.clamp((i.Position.X-p.X)/s.X,0,1);cur.set(t);refreshAll()end end)
ui.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then draggingSl=false end end)
local function mk(label,isV,getV,setV,getH)
    local idx=#sliders+1;local y=0.15+(idx-1)*0.18
    local lt=Instance.new("TextLabel",fr);lt.Name="\0";lt.Size=UDim2.new(0.5,0,0.05,0);lt.Position=UDim2.new(0.05,0,y,0);lt.BackgroundTransparency=1;lt.Font=Enum.Font.Gotham;lt.TextSize=14;lt.TextColor3=Color3.fromRGB(200,200,200);lt.Text=label
    local tr=Instance.new("Frame",fr);tr.Name="\0";tr.Size=UDim2.new(0.9,0,0.05,0);tr.Position=UDim2.new(0.05,0,y+0.05,0);tr.Active=true;tr.BorderSizePixel=0;tr.BackgroundColor3=isV and Color3.fromHSV(getH(),1,getV()) or Color3.new(1,1,1);Instance.new("UICorner",tr).Name="\0";tr:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0.02,0)
    local gr=Instance.new("UIGradient",tr);gr.Name="\0";if isV then gr.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.fromHSV(getH(),1,0)),ColorSequenceKeypoint.new(1,Color3.fromHSV(getH(),1,1))}else local pts={}for _,v in ipairs(stops)do pts[#pts+1]=ColorSequenceKeypoint.new(v,Color3.fromHSV(v,1,1))end gr.Color=ColorSequence.new(pts)end
    local hd=Instance.new("Frame",tr);hd.Name="\0";hd.Size=UDim2.new(0.04,0,1,0);hd.BackgroundColor3=Color3.fromRGB(240,240,240);hd.Active=true;Instance.new("UICorner",hd).Name="\0";hd:FindFirstChildOfClass("UICorner").CornerRadius=UDim.new(0.5,0);Instance.new("UIStroke",hd).Name="\0";hd:FindFirstChildOfClass("UIStroke").Color=Color3.fromRGB(150,150,150)
    local entry={track=tr,grad=gr,handle=hd,isVal=isV,get=getV,set=setV,getHue=getH}
    sliders[#sliders+1]=entry
    local function bd(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then draggingSl=true;cur=entry end end
    hd.InputBegan:Connect(bd);tr.InputBegan:Connect(bd)
end
mk("Start Hue",false,function()return sH end,function(v)sH=v end,function()return sH end)
mk("Start Brightness",true,function()return sV end,function(v)sV=v end,function()return sH end)
mk("End Hue",false,function()return eH end,function(v)eH=v end,function()return eH end)
mk("End Brightness",true,function()return eV end,function(v)eV=v end,function()return eH end)
tb.Activated:Connect(function()fr.Visible=not fr.Visible;tb.Text=fr.Visible and"^"or"v";if fr.Visible then refreshAll()end end)