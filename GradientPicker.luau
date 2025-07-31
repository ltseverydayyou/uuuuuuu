local cg=game:GetService("CoreGui")
local gh=type(gethui)=="function" and gethui()
local ps=game:GetService("Players")
local pg=ps.LocalPlayer and ps.LocalPlayer:FindFirstChild("PlayerGui")
local parent=gh or cg or pg
local ui=game:GetService("UserInputService")
local http=game:GetService("HttpService")

local wfile=writefile or write_file or writeFile
local rfile=readfile or read_file or readFile
local isf=isfile or is_file or isFile
local isd=isfolder or is_folder or isFolder
local mkd=makefolder or make_folder or makeFolder
local hasFS=wfile and rfile and isf and isd and mkd
local cfg="GradientPicker/settings.json"

local sH,sV,eH,eV=0.8,1,0,1
if hasFS then
    if not isd("GradientPicker") then mkd("GradientPicker") end
    if isf(cfg) then
        local ok,d=pcall(rfile,cfg)
        if ok then
            local succ,obj=pcall(http.JSONDecode,http,d)
            if succ and type(obj)=="table" then
                sH=obj.startHue or sH
                sV=obj.startVal or sV
                eH=obj.endHue or eH
                eV=obj.endVal or eV
            end
        end
    end
end

local stops={0,1/6,2/6,3/6,4/6,5/6,1}
local sls={}

local function upd()
    local seq=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromHSV(sH,1,sV)),
        ColorSequenceKeypoint.new(1,Color3.fromHSV(eH,1,eV)),
    }
    for _,o in ipairs(cg:GetDescendants())do
        if o:IsA("ImageLabel") and not(gh and o:IsDescendantOf(gh))then
            local old=o:FindFirstChildOfClass("UIGradient")
            if old then old:Destroy() end
            local ug=Instance.new("UIGradient",o)
            ug.Name="\0";ug.Color,ug.Rotation=seq,45
        end
    end
    for _,s in ipairs(sls)do
        local t=s.get()
        s.h.Position=UDim2.new(t*(1-s.h.Size.X.Scale),0,0,0)
        if s.v then
            local hue=s.gh()
            s.g.Color=ColorSequence.new{
                ColorSequenceKeypoint.new(0,Color3.fromHSV(hue,1,0)),
                ColorSequenceKeypoint.new(1,Color3.fromHSV(hue,1,1)),
            }
            s.t.BackgroundColor3=Color3.fromHSV(hue,1,t)
        else
            s.t.BackgroundColor3=Color3.fromRGB(255,255,255)
            local arr={}
            for _,v in ipairs(stops)do arr[#arr+1]=ColorSequenceKeypoint.new(v,Color3.fromHSV(v,1,1))end
            s.g.Color=ColorSequence.new(arr)
        end
    end
end

upd()
cg.DescendantAdded:Connect(function(o)
    if o:IsA("ImageLabel") and not(gh and o:IsDescendantOf(gh))then
        local ug=Instance.new("UIGradient",o)
        ug.Name="\0"
        ug.Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.fromHSV(sH,1,sV)),
            ColorSequenceKeypoint.new(1,Color3.fromHSV(eH,1,eV)),
        }
        ug.Rotation=45
    end
end)

local sg=Instance.new("ScreenGui",parent)
sg.Name="\0";sg.IgnoreGuiInset=true;sg.DisplayOrder=10

local tb=Instance.new("TextButton",sg)
tb.Name="\0";tb.AnchorPoint, tb.Position=Vector2.new(0.5,0),UDim2.new(0.5,0,0.02,0)
tb.Size,tb.BackgroundColor3,tb.BorderSizePixel=UDim2.new(0.05,0,0.06,0),Color3.fromRGB(40,40,40),0
tb.Font,tb.TextSize,tb.TextColor3,tb.Text=Enum.Font.GothamBold,24,Color3.fromRGB(200,200,200),"v"
local c1=Instance.new("UICorner",tb);c1.Name="\0";c1.CornerRadius=UDim.new(1,0)
local s1=Instance.new("UIStroke",tb);s1.Name="\0";s1.Color=Color3.fromRGB(70,70,70)

local fr=Instance.new("Frame",sg)
fr.Name="\0";fr.AnchorPoint,fr.Position=Vector2.new(0.5,0),UDim2.new(0.5,0,0.1,0)
fr.Size,fr.BackgroundColor3,fr.BorderSizePixel=UDim2.new(0.35,0,0.6,0),Color3.fromRGB(30,30,30),0
fr.Active,fr.Visible=true,false
local c2=Instance.new("UICorner",fr);c2.Name="\0";c2.CornerRadius=UDim.new(0.05,0)
local s2=Instance.new("UIStroke",fr);s2.Name="\0";s2.Color=Color3.fromRGB(70,70,70)

local tl=Instance.new("Frame",fr)
tl.Name="\0";tl.Size,tl.Position,tl.BackgroundColor3,tl.BorderSizePixel,tl.Active=
    UDim2.new(1,0,0.1,0),UDim2.new(0,0,0,0),Color3.fromRGB(40,40,40),0,true
local c3=Instance.new("UICorner",tl);c3.Name="\0";c3.CornerRadius=UDim.new(0.05,0)
local lb=Instance.new("TextLabel",tl)
lb.Name="\0";lb.Size,lb.BackgroundTransparency,lb.Font,lb.TextSize,lb.TextColor3,lb.Text=
    UDim2.new(1,0,1,0),1,Enum.Font.GothamBold,18,Color3.fromRGB(220,220,220),"Gradient Picker"

local dragS,dragF=false,false
local cur,dp,fp

ui.InputChanged:Connect(function(i)
    if dragS and cur then
        local p,s=cur.t.AbsolutePosition,cur.t.AbsoluteSize
        local v=math.clamp((i.Position.X-p.X)/s.X,0,1)
        cur.set(v);upd()
    end
    if dragF and dp then
        local d=i.Position-dp
        fr.Position=UDim2.new(fp.X.Scale,fp.X.Offset+d.X,fp.Y.Scale,fp.Y.Offset+d.Y)
    end
end)
ui.InputEnded:Connect(function(i)
    if dragS and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch)then
        dragS=false
        if hasFS then pcall(wfile,cfg,http:JSONEncode{startHue=sH,startVal=sV,endHue=eH,endVal=eV}) end
    end
    if dragF and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch)then
        dragF=false
    end
end)

local function mk(txt,isV,getVal,setVal,getHue)
    local idx=#sls+1
    local y=0.15+(idx-1)*0.18
    local lt=Instance.new("TextLabel",fr)
    lt.Name="\0";lt.Size,lt.Position,lt.BackgroundTransparency,lt.Font,lt.TextSize,lt.TextColor3,lt.Text=
        UDim2.new(0.5,0,0.05,0),UDim2.new(0.05,0,y,0),1,Enum.Font.Gotham,14,Color3.fromRGB(200,200,200),txt
    local tr=Instance.new("Frame",fr)
    tr.Name="\0";tr.Size,tr.Position,tr.Active,tr.BorderSizePixel=
        UDim2.new(0.9,0,0.05,0),UDim2.new(0.05,0,y+0.05,0),true,0
    tr.BackgroundColor3=isV and Color3.fromHSV(getHue(),1,getVal()) or Color3.fromRGB(255,255,255)
    local c4=Instance.new("UICorner",tr);c4.Name="\0";c4.CornerRadius=UDim.new(0.02,0)
    local gr=Instance.new("UIGradient",tr);gr.Name="\0"
    if isV then
        gr.Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.fromHSV(getHue(),1,0)),
            ColorSequenceKeypoint.new(1,Color3.fromHSV(getHue(),1,1)),
        }
    else
        local arr={}
        for _,v in ipairs(stops)do arr[#arr+1]=ColorSequenceKeypoint.new(v,Color3.fromHSV(v,1,1))end
        gr.Color=ColorSequence.new(arr)
    end
    local hd=Instance.new("Frame",tr)
    hd.Name="\0";hd.Size,hd.Active,hd.BackgroundColor3=UDim2.new(0.04,0,1,0),true,Color3.fromRGB(240,240,240)
    local c5=Instance.new("UICorner",hd);c5.Name="\0";c5.CornerRadius=UDim.new(0.5,0)
    local s5=Instance.new("UIStroke",hd);s5.Name="\0";s5.Color=Color3.fromRGB(150,150,150)
    local e={t=tr,g=gr,h=hd,v=isV,get=getVal,set=setVal,gh=getHue}
    sls[#sls+1]=e
    local function bs(i2)
        if i2.UserInputType==Enum.UserInputType.MouseButton1 or i2.UserInputType==Enum.UserInputType.Touch then
            dragS=true;cur=e
        end
    end
    hd.InputBegan:Connect(bs);tr.InputBegan:Connect(bs)
end

mk("Start Hue",false,function()return sH end,function(v)sH=v end,function()return sH end)
mk("Start Brightness",true,function()return sV end,function(v)sV=v end,function()return sH end)
mk("End Hue",false,function()return eH end,function(v)eH=v end,function()return eH end)
mk("End Brightness",true,function()return eV end,function(v)eV=v end,function()return eH end)

tl.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragF=true;dp=i.Position;fp=fr.Position
    end
end)

tb.Activated:Connect(function()
    fr.Visible=not fr.Visible
    tb.Text=fr.Visible and"^"or"v"
    if fr.Visible then upd() end
end)