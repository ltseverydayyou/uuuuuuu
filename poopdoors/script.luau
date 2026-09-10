local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/poopdoors/lib.luau'))()
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")

if not fireproximityprompt then
    local msg = Instance.new("Message",workspace)
    msg.Text = "you have fireproximityprompt function bro get better executor"
    task.wait(6)
    msg:Destroy()
    error("no prox") 
end

function esp(what,color,core,name)
    local parts
    
    if typeof(what) == "Instance" then
        if what:IsA("Model") then
            parts = what:GetChildren()
        elseif what:IsA("BasePart") then
            parts = {what,table.unpack(what:GetChildren())}
        end
    elseif typeof(what) == "table" then
        parts = what
    end
    
    local bill
    local boxes = {}
    
    for i,v in pairs(parts) do
        if v:IsA("BasePart") then
            local box = Instance.new("BoxHandleAdornment")
            box.Size = v.Size
            box.AlwaysOnTop = true
            box.ZIndex = 1
            box.AdornCullingMode = Enum.AdornCullingMode.Never
            box.Color3 = color
            box.Transparency = 0.7
            box.Adornee = v
            box.Parent = game.CoreGui
            
            table.insert(boxes,box)
            
            task.spawn(function()
                while box.Parent do
                    if box.Adornee == nil or not box.Adornee:IsDescendantOf(workspace) then
                        box.Adornee = nil
                        box.Visible = false
                        box:Destroy()
                        break
                    end
                    task.wait()
                end
            end)
        end
    end
    
    if core and name then
        bill = Instance.new("BillboardGui",game.CoreGui)
        bill.AlwaysOnTop = true
        bill.Size = UDim2.new(0,400,0,100)
        bill.Adornee = core
        bill.MaxDistance = 2000
        
        local mid = Instance.new("Frame",bill)
        mid.AnchorPoint = Vector2.new(0.5,0.5)
        mid.BackgroundColor3 = color
        mid.Size = UDim2.new(0,8,0,8)
        mid.Position = UDim2.new(0.5,0,0.5,0)
        Instance.new("UICorner",mid).CornerRadius = UDim.new(1,0)
        Instance.new("UIStroke",mid)
        
        local txt = Instance.new("TextLabel",bill)
        txt.AnchorPoint = Vector2.new(0.5,0.5)
        txt.BackgroundTransparency = 1
        txt.BackgroundColor3 = color
        txt.TextColor3 = color
        txt.Size = UDim2.new(1,0,0,20)
        txt.Position = UDim2.new(0.5,0,0.7,0)
        txt.Text = name
        Instance.new("UIStroke",txt)
        
        task.spawn(function()
            while bill.Parent do
                if bill.Adornee == nil or not bill.Adornee:IsDescendantOf(workspace) then
                    bill.Enabled = false
                    bill.Adornee = nil
                    bill:Destroy()
                    break
                end
                task.wait()
            end
        end)
    end
    
    local ret = {}
    
    ret.delete = function()
        for i,v in pairs(boxes) do
            if v and v.Parent then
                v.Adornee = nil
                v.Visible = false
                v:Destroy()
            end
        end
        
        if bill and bill.Parent then
            bill.Enabled = false
            bill.Adornee = nil
            bill:Destroy()
        end
    end
    
    return ret 
end

local entityinfo = game.ReplicatedStorage:WaitForChild("RemotesFolder")
function message(text)
    local msg = Instance.new("Message",workspace)
    msg.Text = tostring(text)
    task.wait(5)
    msg:Destroy()
    
    --firesignal(entityinfo.Caption.OnClientEvent,tostring(text)) 
end

local flags = {
    speed = 0,
    espdoors = false,
    espkeys = false,
    espitems = false,
    espbooks = false,
    esprush = false,
    espchest = false,
    esplocker = false,
    esphumans = false,
    espgold = false,
    goldespvalue = 0,
    hintrush = false,
    light = false,
    instapp = false,
    noseek = false,
    nogates = false,
    nopuzzle = false,
    noa90 = false,
    noskeledoors = false,
    noscreech = false,
    getcode = false,
    roomsnolock = false,
    draweraura = false,
    autorooms = false,
}

local DELFLAGS = {}
for k,v in pairs(flags) do
    DELFLAGS[k] = v
end
local esptable = {doors={},keys={},items={},books={},entity={},chests={},lockers={},people={},gold={}}

local window_player = library.window("player")
local window_esp = library.window("esp")
local window_misc = library.window("misc")

window_player.toggle("client glow",false,function(val)
    flags.light = val
   
    if val then
        local l = Instance.new("PointLight")
        l.Range = 10000
        l.Brightness = 2
        l.Parent = char.PrimaryPart
       
        repeat task.wait() until not flags.light
        l:Destroy() 
    end
end)

window_player.toggle("instant use",false,function(val)
    flags.instapp = val
    
    local holdconnect
    holdconnect = game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(function(p)
		fireproximityprompt(p)
	end)
    
    repeat task.wait() until not flags.instapp
    holdconnect:Disconnect()
end)

local basewalkspeed = 15
local walkspeedslider = window_player.slider("walkspeed",16,21.5,0.5,16,function(val)
    flags.speed = val
    char:SetAttribute("SpeedBoost", val-basewalkspeed)
end)

window_esp.toggle("door esp",false,function(val)
    flags.espdoors = val
    
    if val then
        local function setup(room)
            local doormodel = room:FindFirstChild("Door") or room:WaitForChild("Door",2)
            local door = doormodel and doormodel:FindFirstChild("Door")
            
            if not door or not door:IsA("BasePart") then
                return
            end
            
            task.wait(0.1)
            local h = esp(door,Color3.fromRGB(255,240,0),door,"Door")
            table.insert(esptable.doors,h)
            
            local opensound = doormodel:FindFirstChild("Open")
            if opensound and opensound:IsA("Sound") then
                opensound.Played:Connect(function()
                    h.delete()
                end)
            end
            
            doormodel.AncestryChanged:Connect(function()
                h.delete()
            end)
        end
        
        local addconnect
        addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
            setup(room)
        end)
        
        for i,room in pairs(workspace.CurrentRooms:GetChildren()) do
            if room:FindFirstChild("Assets") then
                setup(room) 
            end
        end
        
        repeat task.wait() until not flags.espdoors
        addconnect:Disconnect()
        
        for i,v in pairs(esptable.doors) do
            v.delete()
        end 
    end
end)

window_esp.toggle("key/lever esp",false,function(val)
    flags.espkeys = val
    
    if val then
        local function check(v)
            if v:IsA("Model") and (v.Name == "LeverForGate" or v.Name == "KeyObtain") then
                task.wait(0.1)
                if v.Name == "KeyObtain" then
                    local hitbox = v.PrimaryPart or v:FindFirstChild("Hitbox")
                    
                    if hitbox and hitbox:IsA("BasePart") then
                        local h = esp(hitbox,Color3.fromRGB(90,255,40),hitbox,"Key")
                        table.insert(esptable.keys,h)
                    end
                    
                elseif v.Name == "LeverForGate" then
                    local core = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart",true)
                    if core then
                        local h = esp(v:GetDescendants(),Color3.fromRGB(90,255,40),core,"Lever")
                        table.insert(esptable.keys,h)
                        
                        local sound = core:FindFirstChild("SoundToPlay") or v:FindFirstChild("SoundToPlay",true)
                        if sound and sound:IsA("Sound") then
                            sound.Played:Connect(function()
                                h.delete()
                            end)
                        end
                    end
                end
            end
        end
        
        local function setup(room)
            local assets = room:WaitForChild("Assets")
            
            assets.DescendantAdded:Connect(function(v)
                check(v) 
            end)
                
            for i,v in pairs(assets:GetDescendants()) do
                check(v)
            end 
        end
        
        local addconnect
        addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
            setup(room)
        end)
        
        for i,room in pairs(workspace.CurrentRooms:GetChildren()) do
            if room:FindFirstChild("Assets") then
                setup(room) 
            end
        end
        
        repeat task.wait() until not flags.espkeys
        addconnect:Disconnect()
        
        for i,v in pairs(esptable.keys) do
            v.delete()
        end 
    end
end)

window_esp.toggle("item esp",false,function(val)
    flags.espitems = val
    
    if val then
        local function check(v)
            if not v:IsA("Model") or v.Name == "KeyObtain" or v:GetAttribute("IsKey") then
                return
            end
            
            local prompt = v:FindFirstChild("ModulePrompt")
            local isobtain = prompt and prompt:IsA("ProximityPrompt") and (prompt.ActionText == "Obtain" or v.Name:sub(-6) == "Obtain")
            
            if isobtain then
                task.wait(0.1)
                local part = v.PrimaryPart or v:FindFirstChild("Hitbox") or v:FindFirstChildWhichIsA("BasePart",true)
                
                if part then
                    local label = prompt.ObjectText ~= "" and prompt.ObjectText or v.Name:gsub("Obtain$","")
                    local h = esp(v:GetDescendants(),Color3.fromRGB(160,190,255),part,label)
                    table.insert(esptable.items,h)
                end
            end
        end
        
        local function setup(room)
            local assets = room:WaitForChild("Assets")
            
            if assets then  
                local subaddcon
                subaddcon = assets.DescendantAdded:Connect(function(v)
                    check(v) 
                end)
                
                for i,v in pairs(assets:GetDescendants()) do
                    check(v)
                end
                
                task.spawn(function()
                    repeat task.wait() until not flags.espitems
                    subaddcon:Disconnect()  
                end) 
            end 
        end
        
        local addconnect
        addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
            setup(room)
        end)
        
        for i,room in pairs(workspace.CurrentRooms:GetChildren()) do
            if room:FindFirstChild("Assets") then
                setup(room) 
            end
        end
        
        repeat task.wait() until not flags.espitems
        addconnect:Disconnect()
        
        for i,v in pairs(esptable.items) do
            v.delete()
        end 
    end
end)

window_esp.toggle("book/breaker esp",false,function(val)
    flags.espbooks = val
    
    if val then
        local function check(v,room)
            if v:IsA("Model") and (v.Name == "LiveHintBook" or v.Name == "LiveBreakerPolePickup") then
                task.wait(0.1)
                
                local h = esp(v,Color3.fromRGB(160,190,255),v.PrimaryPart,"Book")
                table.insert(esptable.books,h)
                
                v.AncestryChanged:Connect(function()
                    if not v:IsDescendantOf(room) then
                        h.delete() 
                    end
                end)
            end
        end
        
        local function setup(room)
            if room.Name == "50" or room.Name == "100" then
                room.DescendantAdded:Connect(function(v)
                    check(v,room)
                end)
                
                for i,v in pairs(room:GetDescendants()) do
                    check(v,room)
                end
            end
        end
        
        local addconnect
        addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
            setup(room)
        end)
        
        for i,room in pairs(workspace.CurrentRooms:GetChildren()) do
            setup(room) 
        end
        
        repeat task.wait() until not flags.espbooks
        addconnect:Disconnect()
        
        for i,v in pairs(esptable.books) do
            v.delete()
        end 
    end
end)

local entitynames = {
    RushMoving = "Rush",
    AmbushMoving = "Ambush",
    Eyes = "Eyes",
    A60 = "A60",
    A120 = "A120",
    FigureRig = "Figure",
    GiggleCeiling = "Giggle",
    Snare = "Snare",
    Dread = "Dread",
    Blitz = "Blitz",
    Lookman = "Lookman",
    Surge = "Surge",
    Bramble = "Bramble",
    Groundskeeper = "Groundskeeper",
    Monument = "Monument",
    Gloombats = "Gloombats",
    Sally = "Sally",
    JeffTheKiller = "Jeff The Killer",
}

local function entitytarget(v)
    if not v:IsA("Model") then
        return
    end
    
    local display = entitynames[v.Name]
    if not display then
        return
    end
    
    local core = v.PrimaryPart or v:FindFirstChild("Base") or v:FindFirstChildWhichIsA("BasePart",true)
    if not core then
        return
    end
    
    return core,display
end

window_player.label("credits: zoophiliaphobic#6287\noh my dayyzz",20)
window_esp.toggle("entity esp",false,function(val)
    flags.esprush = val
    
    if val then
        local connections = {}
        local seen = {}
        
        local function check(v)
            if seen[v] then
                return
            end
            
            local core,display = entitytarget(v)
            if core then
                seen[v] = true
                task.wait(0.05)
                if not v:IsDescendantOf(workspace) then
                    return
                end
                local h = esp(v:GetDescendants(),Color3.fromRGB(255,25,25),core,display)
                table.insert(esptable.entity,h)
            end
        end
        
        table.insert(connections,workspace.ChildAdded:Connect(check))
        
        local liveentities = workspace:FindFirstChild("LiveEntities")
        if liveentities then
            table.insert(connections,liveentities.ChildAdded:Connect(check))
            for _,v in pairs(liveentities:GetChildren()) do
                check(v)
            end
        end
        
        local function setup(room)
            table.insert(connections,room.DescendantAdded:Connect(check))
            for _,v in pairs(room:GetDescendants()) do
                check(v)
            end
        end
        
        table.insert(connections,workspace.CurrentRooms.ChildAdded:Connect(setup))
        
        for _,v in pairs(workspace:GetChildren()) do
            check(v)
        end
        for _,room in pairs(workspace.CurrentRooms:GetChildren()) do
            setup(room)
        end
        
        repeat task.wait() until not flags.esprush
        for _,connection in pairs(connections) do
            connection:Disconnect()
        end
        
        for _,v in pairs(esptable.entity) do
            v.delete()
        end
        table.clear(esptable.entity)
    end
end)

window_esp.toggle("locker esp",false,function(val)
    flags.esplocker = val
    
    if val then
        local function check(v)
            if v:IsA("Model") then
                task.wait(0.1)
                if v.Name == "Wardrobe" then
                    local h = esp(v.PrimaryPart,Color3.fromRGB(145,100,25),v.PrimaryPart,"Closet")
                    table.insert(esptable.lockers,h) 
                elseif (v.Name == "Rooms_Locker" or v.Name == "Rooms_Locker_Fridge") then
                    local h = esp(v.PrimaryPart,Color3.fromRGB(145,100,25),v.PrimaryPart,"Locker")
                    table.insert(esptable.lockers,h) 
                end
            end
        end
        
        local function setup(room)
            local assets = room:WaitForChild("Assets")
            
            if assets then
                local subaddcon
                subaddcon = assets.DescendantAdded:Connect(function(v)
                    check(v) 
                end)
                
                for i,v in pairs(assets:GetDescendants()) do
                    check(v)
                end
                
                task.spawn(function()
                    repeat task.wait() until not flags.esplocker
                    subaddcon:Disconnect()  
                end) 
            end 
        end
        
        local addconnect
        addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
            setup(room)
        end)
        
        for i,v in pairs(workspace.CurrentRooms:GetChildren()) do
            setup(v)
        end
        
        repeat task.wait() until not flags.esplocker
        addconnect:Disconnect()
        
        for i,v in pairs(esptable.lockers) do
            v.delete()
        end 
    end
end)

window_esp.toggle("chest esp",false,function(val)
    flags.espchest = val
    
    if val then
        local function check(v)
            if v:IsA("Model") then
                task.wait(0.1)
                if v.Name == "ChestBox" then
                    warn(v.Name)
                    local h = esp(v,Color3.fromRGB(205,120,255),v.PrimaryPart,"Chest")
                    table.insert(esptable.chests,h) 
                elseif v.Name == "ChestBoxLocked" then
                    local h = esp(v,Color3.fromRGB(255,120,205),v.PrimaryPart,"Locked Chest")
                    table.insert(esptable.chests,h) 
                end
            end
        end
        
        local function setup(room)
            local subaddcon
            subaddcon = room.DescendantAdded:Connect(function(v)
                check(v) 
            end)
            
            for i,v in pairs(room:GetDescendants()) do
                check(v)
            end
            
            task.spawn(function()
                repeat task.wait() until not flags.espchest
                subaddcon:Disconnect()  
            end)  
        end
        
        local addconnect
        addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
            setup(room)
        end)
        
        for i,room in pairs(workspace.CurrentRooms:GetChildren()) do
            if room:FindFirstChild("Assets") then
                setup(room) 
            end
        end
        
        repeat task.wait() until not flags.espchest
        addconnect:Disconnect()
        
        for i,v in pairs(esptable.chests) do
            v.delete()
        end 
    end
end)

window_esp.toggle("player esp",false,function(val)
    flags.esphumans = val
    
    if val then
        local function personesp(v)
            v.CharacterAdded:Connect(function(vc)
                local vh = vc:WaitForChild("Humanoid")
                local torso = vc:WaitForChild("UpperTorso")
                task.wait(0.1)
                
                local h = esp(vc,Color3.fromRGB(255,255,255),torso,v.DisplayName)
                table.insert(esptable.people,h) 
            end)
            
            if v.Character then
                local vc = v.Character
                local vh = vc:WaitForChild("Humanoid")
                local torso = vc:WaitForChild("UpperTorso")
                task.wait(0.1)
                
                local h = esp(vc,Color3.fromRGB(255,255,255),torso,v.DisplayName)
                table.insert(esptable.people,h) 
            end
        end
        
        local addconnect
        addconnect = game.Players.PlayerAdded:Connect(function(v)
            if v ~= plr then
                personesp(v)
            end
        end)
        
        for i,v in pairs(game.Players:GetPlayers()) do
            if v ~= plr then
                personesp(v) 
            end
        end
        
        repeat task.wait() until not flags.esphumans
        addconnect:Disconnect()
        
        for i,v in pairs(esptable.people) do
            v.delete()
        end 
    end
end)

window_esp.toggle("goldpile esp",false,function(val)
    flags.espgold = val
    
    if val then
        local function check(v)
            if v:IsA("Model") then
                task.wait(0.1)
                local goldvalue = v:GetAttribute("GoldValue")
                
                if goldvalue and goldvalue >= flags.goldespvalue then
                    local hitbox = v:WaitForChild("Hitbox")
                    local h = esp(hitbox:GetChildren(),Color3.fromRGB(255,255,0),hitbox,"GoldPile [".. tostring(goldvalue).."]")
                    table.insert(esptable.gold,h)
                end
            end
        end
        
        local function setup(room)
            local assets = room:WaitForChild("Assets")
            
            local subaddcon
            subaddcon = assets.DescendantAdded:Connect(function(v)
                check(v) 
            end)
            
            for i,v in pairs(assets:GetDescendants()) do
                check(v)
            end
            
            task.spawn(function()
                repeat task.wait() until not flags.espgold
                subaddcon:Disconnect()  
            end)  
        end
        
        local addconnect
        addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
            setup(room)
        end)
        
        for i,room in pairs(workspace.CurrentRooms:GetChildren()) do
            if room:FindFirstChild("Assets") then
                setup(room) 
            end
        end
        
        repeat task.wait() until not flags.espgold
        addconnect:Disconnect()
        
        for i,v in pairs(esptable.gold) do
            v.delete()
        end 
    end
end)

window_esp.slider("minimum gold value",5,150,5,25,function(val)
    flags.goldespvalue = val
end)

window_misc.toggle("notify entities",false,function(val)
    flags.hintrush = val
    
    if val then
        local connections = {}
        local warningnames = {RushMoving=true,AmbushMoving=true,A60=true,A120=true,Blitz=true,Surge=true}
        
        local function check(v)
            if not warningnames[v.Name] then
                return
            end
            
            task.spawn(function()
                local core = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart",true)
                if not core then
                    return
                end
                
                repeat task.wait() until plr:DistanceFromCharacter(core.Position) < 1000 or not v:IsDescendantOf(workspace) or not flags.hintrush
                
                if flags.hintrush and v:IsDescendantOf(workspace) then
                    message((entitynames[v.Name] or v.Name):lower().." is coming go hide")
                end
            end)
        end
        
        table.insert(connections,workspace.ChildAdded:Connect(check))
        local liveentities = workspace:FindFirstChild("LiveEntities")
        if liveentities then
            table.insert(connections,liveentities.ChildAdded:Connect(check))
        end
        
        repeat task.wait() until not flags.hintrush
        for _,connection in pairs(connections) do
            connection:Disconnect()
        end
    end
end)

window_misc.toggle("disable seek chase",false,function(val)
    flags.noseek = val
    
    if val then
        local addconnect
        addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
            local trigger = room:WaitForChild("TriggerEventCollision",2)
            
            if trigger then
                trigger:Destroy() 
            end
        end)
        
        repeat task.wait() until not flags.noseek
        addconnect:Disconnect()
    end
end)

window_misc.toggle("delete gates",false,function(val)
    flags.nogates = val
    
    if val then
        local addconnect
        addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
            local gate = room:WaitForChild("Gate",2)
            
            if gate then
                local door = gate:WaitForChild("ThingToOpen",2)
                
                if door then
                    door:Destroy() 
                end
            end
        end)
        
        repeat task.wait() until not flags.nogates
        addconnect:Disconnect()
    end
end)

window_misc.toggle("delete puzzle door",false,function(val)
    flags.nopuzzle = val
    
    if val then
        local addconnect
        addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
            local assets = room:WaitForChild("Assets")
            local paintings = assets:WaitForChild("Paintings",2)
            
            if paintings then
                local door = paintings:WaitForChild("MovingDoor",2)
            
                if door then
                    door:Destroy() 
                end 
            end
        end)
        
        repeat task.wait() until not flags.nopuzzle
        addconnect:Disconnect()
    end
end)

local screechdisable = game.ReplicatedStorage:WaitForChild("GameData"):FindFirstChild("EntityDisableScreech")

if screechdisable then
    window_misc.toggle("harmless screech",false,function(val)
        flags.noscreech = val
        
        if val then
            local oldvalue = screechdisable.Value
            screechdisable.Value = true
            repeat
                task.wait(0.1)
                if flags.noscreech and not screechdisable.Value then
                    screechdisable.Value = true
                end
            until not flags.noscreech
            screechdisable.Value = oldvalue
        end
    end)
end

window_misc.toggle("no skeleton doors",false,function(val)
    flags.noskeledoors = val
    
    if val then
        local addconnect
        addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
            local door = room:WaitForChild("Wax_Door",2)
            
            if door then
                door:Destroy() 
            end
        end)
        
        repeat task.wait() until not flags.noskeledoors
        addconnect:Disconnect()
    end
end)

window_misc.toggle("auto library code",false,function(val)
    flags.getcode = val
    
    if val then
        local function deciphercode()
        local paper = char:FindFirstChild("LibraryHintPaper")
        local hints = plr.PlayerGui:WaitForChild("PermUI"):WaitForChild("Hints")
        
        local code = {[1]="_",[2]="_",[3]="_",[4]="_",[5]="_"}
            
            if paper then
                for i,v in pairs(paper:WaitForChild("UI"):GetChildren()) do
                    if v:IsA("ImageLabel") and v.Name ~= "Image" then
                        for i,img in pairs(hints:GetChildren()) do
                            if img:IsA("ImageLabel") and img.Visible and v.ImageRectOffset == img.ImageRectOffset then
                                local num = img:FindFirstChild("TextLabel").Text
                                
                                code[tonumber(v.Name)] = num 
                            end
                        end
                    end
                end 
            end
            
            return code
        end
        
        local addconnect
        addconnect = char.ChildAdded:Connect(function(v)
            if v:IsA("Tool") and v.Name == "LibraryHintPaper" then
                task.wait()
                
                local code = table.concat(deciphercode())
                
                if code:find("_") then
                    message("get all hints first")
                else
                    message("the code is ".. code)
                end
            end
        end)
        
        repeat task.wait() until not flags.getcode
        addconnect:Disconnect()
    end
end)

window_misc.toggle("A-000 door no locks",false,function(val)
    flags.roomsnolock = val
    
    if val then
        local function check(room)
            local door = room:WaitForChild("RoomsDoor_Entrance",2)
            
            if door then
                local prompt = door:WaitForChild("Door"):WaitForChild("EnterPrompt")
                prompt.Enabled = true
            end 
        end
        
        local addconnect
        addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
            check(room)
        end)
        
        for i,v in pairs(workspace.CurrentRooms:GetChildren()) do
            check(v)
        end
        
        repeat task.wait() until not flags.roomsnolock
        addconnect:Disconnect()
    end
end)

window_misc.toggle("loot aura",false,function(val)
    flags.draweraura = val
    
    if val then
        local function setup(room)
            local function check(v)
                if v:IsA("Model") then
                    if v.Name == "DrawerContainer" then
                        local knob = v:WaitForChild("Knobs")
                        
                        if knob then
                            local prompt = knob:WaitForChild("ActivateEventPrompt")
                            local interactions = prompt:GetAttribute("Interactions")
                            
                            if not interactions then
                                task.spawn(function()
                                    repeat task.wait(0.1)
                                        if plr:DistanceFromCharacter(knob.Position) <= 12 then
                                            fireproximityprompt(prompt)
                                        end
                                    until prompt:GetAttribute("Interactions") or not flags.draweraura
                                end)
                            end
                        end
                    elseif v.Name == "GoldPile" then
                        local prompt = v:WaitForChild("LootPrompt")
                        local interactions = prompt:GetAttribute("Interactions")
                            
                        if not interactions then
                            task.spawn(function()
                                repeat task.wait(0.1)
                                    if plr:DistanceFromCharacter(v.PrimaryPart.Position) <= 12 then
                                        fireproximityprompt(prompt) 
                                    end
                                until prompt:GetAttribute("Interactions") or not flags.draweraura
                            end)
                        end
                    elseif v.Name:sub(1,8) == "ChestBox" then
                        local prompt = v:WaitForChild("ActivateEventPrompt")
                        local interactions = prompt:GetAttribute("Interactions")
                        
                        if not interactions then
                            task.spawn(function()
                                repeat task.wait(0.1)
                                    if plr:DistanceFromCharacter(v.PrimaryPart.Position) <= 12 then
                                        fireproximityprompt(prompt)
                                    end
                                until prompt:GetAttribute("Interactions") or not flags.draweraura
                            end)
                        end
                    elseif v.Name == "RolltopContainer" then
                        local prompt = v:WaitForChild("ActivateEventPrompt")
                        local interactions = prompt:GetAttribute("Interactions")
                        
                        if not interactions then
                            task.spawn(function()
                                repeat task.wait(0.1)
                                    if plr:DistanceFromCharacter(v.PrimaryPart.Position) <= 12 then
                                        fireproximityprompt(prompt)
                                    end
                                until prompt:GetAttribute("Interactions") or not flags.draweraura
                            end)
                        end
                    end 
                end
            end
    
            local subaddcon
            subaddcon = room.DescendantAdded:Connect(function(v)
                check(v) 
            end)
            
            for i,v in pairs(room:GetDescendants()) do
                check(v)
            end
            
            task.spawn(function()
                repeat task.wait() until not flags.draweraura
                subaddcon:Disconnect() 
            end)
        end
        
        local addconnect
        addconnect = workspace.CurrentRooms.ChildAdded:Connect(function(room)
            setup(room)
        end)
        
        for i,room in pairs(workspace.CurrentRooms:GetChildren()) do
            if room:FindFirstChild("Assets") then
                setup(room) 
            end
        end
        
        repeat task.wait() until not flags.draweraura
        addconnect:Disconnect()
    end
end)

window_misc.toggle("harmless Ransom/A90",false,function(val)
    flags.noa90 = val
    
    if val then
        local oldvalue = plr:GetAttribute("Invincibility")
        plr:SetAttribute("Invincibility",true)
        repeat
            task.wait(0.1)
            if flags.noa90 and plr:GetAttribute("Invincibility") ~= true then
                plr:SetAttribute("Invincibility",true)
            end
        until not flags.noa90
        plr:SetAttribute("Invincibility",oldvalue)
    end
end)

if game.ReplicatedStorage:WaitForChild("GameData"):WaitForChild("Floor").Value == "Rooms" then
    local window_rooms = library.window("the rooms")
    
    window_rooms.toggle("auto a-1000",false,function(val)
        flags.autorooms = val
        
        if val then
            local hide = false

            local function getrecentroom(index)
                local rooms = workspace.CurrentRooms:GetChildren() 
                table.sort(rooms,function(a,b)
                    return tonumber(a.Name) > tonumber(b.Name) 
                end)
                
                return rooms[index]
            end
            
            local entconnections = {}
            local function watchentity(v)
                if v:IsA("Model") and (v.Name == "A60" or v.Name == "A120") then
                    task.spawn(function()
                        hide = true
                        repeat task.wait() until not v:IsDescendantOf(workspace) or not flags.autorooms
                        hide = false
                    end)
                end
            end
            table.insert(entconnections,workspace.ChildAdded:Connect(watchentity))
            local liveentities = workspace:FindFirstChild("LiveEntities")
            if liveentities then
                table.insert(entconnections,liveentities.ChildAdded:Connect(watchentity))
            end
            
            while flags.autorooms do
                local room = getrecentroom(2)
                local door = room:WaitForChild("Door")
                local dpos = door:GetPivot()
                
                if hide then
                    repeat task.wait()
                        char:PivotTo(dpos+Vector3.new(0,150,0))
                    until not hide
                else
                    repeat task.wait()
                        char:PivotTo(dpos)
                    until lastroom ~= room or not flags.autorooms
                end
                
                task.wait()
            end
            for _,connection in pairs(entconnections) do
                connection:Disconnect()
            end
        end
    end)
end

window_misc.button("close gui",function()
    for k,v in pairs(DELFLAGS) do
        flags[k] = v
    end
    
    char:SetAttribute("SpeedBoost",0)
    task.wait()
    library.delete()
end)
