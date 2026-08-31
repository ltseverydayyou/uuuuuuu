local re=game:GetService("Workspace")
local _Name="Telekinesis V6"
local uis=game:GetService("UserInputService")
local _Ins, _CF_new, _VTR_new=Instance.new, CFrame.new, Vector3.new
local con=getfenv().sethiddenproperty
local w=wait
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

Tool0=_Ins("Tool")
Part1=_Ins("Part")
local selectionbox=Instance.new("SelectionBox", LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
selectionbox.LineThickness=0.03
selectionbox.Color3=Color3.fromRGB(255, 255, 255)	

re=game:GetService("RunService")
Tool0.Name=_Name
Tool0.Parent=LocalPlayer.Backpack
Tool0.Grip=_CF_new(0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1)
Tool0.GripPos=_VTR_new(0, 0, 1)
Tool0.RequiresHandle = true
Tool0.CanBeDropped = false

Part1.Name="Handle"
Part1.Parent=Tool0
local changed="Changed"
Part1.CFrame=_CF_new(-3.5, 5.30000019, -3.5, 1, 0, 0, 0, -1, 0, 0, 0, -1)
Part1.Orientation=_VTR_new(0, 180, 180)
Part1.Position=_VTR_new(-3.5, 5.300000190734863, -3.5)
Part1.Rotation=_VTR_new(-180, 0, 0)
Part1.Color=Color3.new(0.972549, 0.972549, 0.972549)
Part1.Transparency=1
local cam=re.RenderStepped
Part1.Size=_VTR_new(1, 1, 1)
Part1.BottomSurface=Enum.SurfaceType.Smooth
Part1.BrickColor=BrickColor.new("Institutional white")
Part1.Locked=true
local speed=31
local mb=uis.TouchEnabled
Part1.TopSurface=Enum.SurfaceType.Smooth
Part1.brickColor=BrickColor.new("Institutional white")

local Sound=_Ins("Sound", game.Workspace)
Sound.SoundId="rbxassetid://1092093337"
Sound.Volume = 0.3
Sound:Play()

pcall(function()
    cam:Connect(function() 
        if con then 
            pcall(function() 
                con(LocalPlayer, changed, speed) 
            end) 
        end 
    end)
end)

changed="SimulationRadius"

local ScreenGui = _Ins("ScreenGui")
ScreenGui.Name = "TelekinesisGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = _Ins("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
MainFrame.BorderSizePixel = 1
MainFrame.Position = UDim2.new(1, -210, 0.5, -180)
MainFrame.Size = UDim2.new(0, 200, 0, 360)

local Title = _Ins("TextLabel")
Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.BorderSizePixel = 0
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Font = Enum.Font.Code
Title.Text = "TELEKINESIS V6"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14

local ScrollFrame = _Ins("ScrollingFrame")
ScrollFrame.Name = "ControlsList"
ScrollFrame.Parent = MainFrame
ScrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.Position = UDim2.new(0, 0, 0, 30)
ScrollFrame.Size = UDim2.new(1, 0, 1, -30)
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

local UIListLayout = _Ins("UIListLayout")
UIListLayout.Parent = ScrollFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 2)
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 5)
end)

local UIPadding = _Ins("UIPadding")
UIPadding.Parent = ScrollFrame
UIPadding.PaddingTop = UDim.new(0, 5)
UIPadding.PaddingLeft = UDim.new(0, 8)
UIPadding.PaddingRight = UDim.new(0, 8)

local function createControlLabel(keyText, actionText, descText, layoutOrder)
    local ControlFrame = _Ins("Frame")
    ControlFrame.Name = "Control"
    ControlFrame.Parent = ScrollFrame
    ControlFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    ControlFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    ControlFrame.BorderSizePixel = 1
    ControlFrame.Size = UDim2.new(1, -10, 0, 40)
    ControlFrame.LayoutOrder = layoutOrder
    
    local KeyLabel = _Ins("TextLabel")
    KeyLabel.Name = "Key"
    KeyLabel.Parent = ControlFrame
    KeyLabel.BackgroundTransparency = 1
    KeyLabel.Position = UDim2.new(0, 5, 0, 3)
    KeyLabel.Size = UDim2.new(0, 20, 0, 15)
    KeyLabel.Font = Enum.Font.Code
    KeyLabel.Text = keyText
    KeyLabel.TextColor3 = Color3.fromRGB(120, 180, 255)
    KeyLabel.TextSize = 13
    KeyLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local ActionLabel = _Ins("TextLabel")
    ActionLabel.Name = "Action"
    ActionLabel.Parent = ControlFrame
    ActionLabel.BackgroundTransparency = 1
    ActionLabel.Position = UDim2.new(0, 28, 0, 3)
    ActionLabel.Size = UDim2.new(1, -33, 0, 15)
    ActionLabel.Font = Enum.Font.Code
    ActionLabel.Text = actionText
    ActionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ActionLabel.TextSize = 12
    ActionLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local DescLabel = _Ins("TextLabel")
    DescLabel.Name = "Description"
    DescLabel.Parent = ControlFrame
    DescLabel.BackgroundTransparency = 1
    DescLabel.Position = UDim2.new(0, 5, 0, 20)
    DescLabel.Size = UDim2.new(1, -10, 0, 15)
    DescLabel.Font = Enum.Font.Code
    DescLabel.Text = descText
    DescLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
    DescLabel.TextSize = 10
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    return ControlFrame
end

createControlLabel("LMB", "Grab", "Click to grab objects", 1)
createControlLabel("F", "Freeze", "Lock object in place", 2)
createControlLabel("E", "Pull In", "Decrease distance by 5", 3)
createControlLabel("Q", "Push Out", "Increase distance by 5", 4)
createControlLabel("X", "Close", "Set distance to 15", 5)
createControlLabel("Y", "Throw", "Set distance to 100", 6)
createControlLabel("J", "Launch", "Set distance to 5000", 7)
createControlLabel("L", "Lock Spin", "Stop object rotation", 8)
createControlLabel("U", "Spin", "Apply rotation force", 9)
createControlLabel("P", "Lift", "Apply upward force", 10)

ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frozenObjects = {}
local heldObjects = {}
local activeLines = {}

local LineConnect=function(part1,part2,parent)
    local line=_Ins("Part")
    line.TopSurface=0
    line.BottomSurface=0
    line.Reflectance=.5
    line.Name="Laser"
    line.Locked=true
    line.CanCollide=false
    line.Anchored=true
    line.formFactor=0
    line.Size=_VTR_new(1,1,1)
    local mesh=_Ins("BlockMesh")
    mesh.Parent=line
    
    local connection
    connection = game:GetService("RunService").RenderStepped:Connect(function()
        if not part1 or not part2 or not part1.Parent or not part2.Parent then
            pcall(function() line:Destroy() end)
            if connection then connection:Disconnect() end
            return
        end
        
        local lv=_CF_new(part1.Position,part2.Position)
        local dist=(part1.Position-part2.Position).magnitude
        line.Parent=parent
        line.BrickColor=Part1.BrickColor
        line.Reflectance=Part1.Reflectance
        line.Transparency=Part1.Transparency
        line.CFrame=_CF_new(part1.Position+lv.lookVector*dist/2)
        line.CFrame=_CF_new(line.Position,part2.Position)
        mesh.Scale=_VTR_new(.25,.25,dist)
    end)
    
    table.insert(activeLines, {line=line, connection=connection})
    return line, connection
end

local tool=Tool0
local object=nil
local mousedown=false
local found=false
local dist=nil
local point=_Ins("Part")
point.Locked=true
point.Anchored=true
point.formFactor=0
point.Shape=0
point.BrickColor=BrickColor.Blue() 
point.Size=_VTR_new(1,1,1)
point.CanCollide=false
local mesh=_Ins("SpecialMesh")
mesh.MeshType="Sphere"
mesh.Scale=_VTR_new(.7,.7,.7)
mesh.Parent=point
local handle=tool.Handle
local front=tool.Handle
local color=tool.Handle

local onButton1Down=function(mouse)
    if (mousedown==true) then return end
    mousedown=true
    
    coroutine.resume(coroutine.create(function()
        local p=point:clone()
        p.Parent=tool
        local lineObj, lineConn = LineConnect(front,p,workspace)
        
        while (mousedown==true) do
            p.Parent=tool
            if (object==nil) then
                if (mouse.Target==nil) then
                    local lv=_CF_new(front.Position,mouse.Hit.p)
                    p.CFrame=_CF_new(front.Position+(lv.lookVector*1000))
                else
                    p.CFrame=_CF_new(mouse.Hit.p)
                end
            else
                LineConnect(front,object,workspace)
                break
            end
            w()
        end
        
        if lineConn then lineConn:Disconnect() end
        pcall(function() p:Destroy() end)
    end))
    
    while (mousedown==true) do
        if (mouse.Target~=nil) then
            local t=mouse.Target
            if (t.Anchored==false) then
                object=t
                selectionbox.Adornee=object
                dist=(object.Position-front.Position).magnitude
                break
            end
        end
        w()
    end
    
    local currentBP = _Ins("BodyPosition")
    currentBP.maxForce=_VTR_new(math.huge*math.huge,math.huge*math.huge,math.huge*math.huge)
    currentBP.P=currentBP.P*3
    
    if object then
        heldObjects[object] = {BP = currentBP, dist = dist}
    end
    
    while (mousedown==true) do
        if (object==nil or object.Parent==nil) then break end
        local lv=_CF_new(front.Position,mouse.Hit.p)
        currentBP.Parent=object
        currentBP.position=front.Position+lv.lookVector*dist
        w()
    end
    
    if object and not frozenObjects[object] then
        pcall(function() currentBP:Destroy() end)
        heldObjects[object] = nil
        object=nil
        selectionbox.Adornee=nil
    end
end

local onKeyDown=function(key,mouse) 
    local key=key:lower() 
    
    if (key=="q") then 
        if (dist and dist>=5) then 
            dist=dist-5
            if heldObjects[object] then
                heldObjects[object].dist = dist
            end
        end 
    end
    
    if (key=="u") then 
        if (object and dist ~=1) then 
            local BX=_Ins("BodyGyro")
            BX.MaxTorque=_VTR_new(math.huge,0,math.huge)
            BX.CFrame=BX.CFrame * CFrame.Angles(0, math.rad(45), 0)
            BX.D=0
            BX.Parent=object
        end 
    end 
    
    if (key=="p") then 
        if (object and dist ~=1) then
            local BX=_Ins("BodyVelocity")
            BX.maxForce=_VTR_new(0,math.huge,0)
            BX.velocity=_VTR_new(0,1,0)
            BX.Parent=object
        end 
    end 
    
    if key == "l" then 
        if (object==nil) then return end 
        
        for _,v in pairs(object:GetChildren()) do 
            if v.ClassName == "BodyGyro" then 
                return nil 
            end 
        end 
        
        local BG=_Ins("BodyGyro") 
        BG.maxTorque=_VTR_new(math.huge,math.huge,math.huge) 
        BG.cframe=_CF_new(object.CFrame.p) 
        BG.Parent=object 
        
        repeat w() until(object.CFrame == _CF_new(object.CFrame.p))
        
        BG.Parent=nil 
        
        if (object==nil) then return end 
        
        for _,v in pairs(object:GetChildren()) do 
            if v.ClassName == "BodyGyro" then 
                v.Parent=nil 
            end 
        end 
        
        object.Velocity=_VTR_new(0,0,0) 
        object.RotVelocity=_VTR_new(0,0,0) 
    end 
    
    if (key=="y") then 
        if (dist ~=100) then 
            dist=100
            if heldObjects[object] then
                heldObjects[object].dist = dist
            end
        end 
    end 
    
    if (key=="j") then 
        if (dist~=5000) then 
            dist=5000
            if heldObjects[object] then
                heldObjects[object].dist = dist
            end
        end 
    end
    
    if (key=="e") then
        if dist then
            dist=dist+5
            if heldObjects[object] then
                heldObjects[object].dist = dist
            end
        end
    end
    
    if (key=="x") then 
        if dist ~= 15 then 
            dist=15
            if heldObjects[object] then
                heldObjects[object].dist = dist
            end
        end 
    end 
    
    if (key=="f") then 
        if (object==nil) then return end 
        
        if frozenObjects[object] then
            local frozenData = frozenObjects[object]
            if frozenData.BP then
                pcall(function() frozenData.BP:Destroy() end)
            end
            if frozenData.selectionBox then
                pcall(function() frozenData.selectionBox:Destroy() end)
            end
            frozenObjects[object] = nil
        else
            local holdData = heldObjects[object]
            if not holdData then return end
            
            local freezeBP = holdData.BP
            
            local freezeBox = _Ins("SelectionBox")
            freezeBox.LineThickness = 0.03
            freezeBox.Color3 = Color3.fromRGB(0, 255, 0)
            freezeBox.Adornee = object
            freezeBox.Parent = object
            
            frozenObjects[object] = {
                BP = freezeBP,
                selectionBox = freezeBox,
                object = object
            }
            
            heldObjects[object] = nil
            
            object = nil
            selectionbox.Adornee = nil
        end
    end
end

local onEquipped=function(mouse)
    local char=tool.Parent
    local human=char:FindFirstChildOfClass("Humanoid")
    
    if human then
        human.Changed:connect(function() 
            if (human.Health==0) then 
                mousedown=false 
                point:Remove() 
                tool:Remove() 
            end 
        end)
    end
    
    mouse.Button1Down:connect(function() onButton1Down(mouse) end)
    mouse.KeyDown:connect(function(key) onKeyDown(key,mouse) end)
    mouse.Icon="rbxasset://textures\\GunCursor.png"
    
    if mb then
        uis.TouchLongPress:Connect(function() onKeyDown("y",mouse) end)
        uis.TouchEnded:Connect(function() mousedown=false end)
    else
        mouse.Button1Up:connect(function() mousedown=false end)
    end
end

local function cleanup()
    mousedown=false 
    
    for _, lineData in pairs(activeLines) do
        if lineData.connection then lineData.connection:Disconnect() end
        if lineData.line then pcall(function() lineData.line:Destroy() end) end
    end
    activeLines = {}
    
    for obj, data in pairs(heldObjects) do
        if data.BP then pcall(function() data.BP:Destroy() end) end
    end
    heldObjects = {}
    
    if object then
        object = nil
        selectionbox.Adornee = nil
    end
end

Tool0.Equipped:connect(onEquipped)
Tool0.Unequipped:connect(cleanup)

LocalPlayer.CharacterAdded:Connect(function()
    cleanup()
    
    for obj, data in pairs(frozenObjects) do
        if data.BP then pcall(function() data.BP:Destroy() end) end
        if data.selectionBox then pcall(function() data.selectionBox:Destroy() end) end
    end
    frozenObjects = {}
    
    w(0.1)
    selectionbox = Instance.new("SelectionBox", LocalPlayer.Character)
    selectionbox.LineThickness=0.03
    selectionbox.Color3=Color3.fromRGB(255, 255, 255)
end)