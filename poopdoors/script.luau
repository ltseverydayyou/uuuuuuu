local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/poopdoors/lib.luau'))()
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CurrentRooms = workspace:WaitForChild("CurrentRooms")
local guiParent = (gethui and gethui()) or game.CoreGui

plr.CharacterAdded:Connect(function(newchar)
    char = newchar
    hum = char:WaitForChild("Humanoid")
end)

if not fireproximityprompt then
    local msg = Instance.new("Message",workspace)
    msg.Text = "you have fireproximityprompt function bro get better executor"
    task.wait(6)
    msg:Destroy()
    error("no prox") 
end

function esp(what,color,core,name)
    local target = typeof(what) == "Instance" and what or core
    local model = target and target:IsA("Model") and target or nil
    local adorn = model and Instance.new("Highlight") or nil
    local box = nil
    local bill = nil
    local txt = nil
    local alive = true
    local ancestry

    if adorn then
        adorn.Adornee = model
        adorn.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        adorn.FillColor = color
        adorn.FillTransparency = 0.82
        adorn.OutlineColor = color
        adorn.OutlineTransparency = 0.05
        adorn.Parent = guiParent
    elseif core and core:IsA("BasePart") then
        box = Instance.new("BoxHandleAdornment")
        box.Size = core.Size
        box.AlwaysOnTop = true
        box.ZIndex = 1
        box.AdornCullingMode = Enum.AdornCullingMode.Never
        box.Color3 = color
        box.Transparency = 0.7
        box.Adornee = core
        box.Parent = guiParent
    end

    if core and core:IsA("BasePart") and name then
        bill = Instance.new("BillboardGui")
        bill.AlwaysOnTop = true
        bill.Size = UDim2.new(0,400,0,100)
        bill.Adornee = core
        bill.MaxDistance = 2000
        bill.StudsOffset = Vector3.new(0,2.5,0)
        bill.Parent = guiParent

        local mid = Instance.new("Frame",bill)
        mid.AnchorPoint = Vector2.new(0.5,0.5)
        mid.BackgroundColor3 = color
        mid.Size = UDim2.new(0,8,0,8)
        mid.Position = UDim2.new(0.5,0,0.5,0)
        Instance.new("UICorner",mid).CornerRadius = UDim.new(1,0)
        Instance.new("UIStroke",mid)

        txt = Instance.new("TextLabel",bill)
        txt.AnchorPoint = Vector2.new(0.5,0.5)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = color
        txt.Size = UDim2.new(1,0,0,20)
        txt.Position = UDim2.new(0.5,0,0.7,0)
        txt.Text = tostring(name)
        txt.TextScaled = true
        Instance.new("UIStroke",txt)
    end

    local root = model or core
    local function destroyVisuals()
        alive = false
        if ancestry then ancestry:Disconnect() end
        if adorn then
            adorn.Adornee = nil
            adorn:Destroy()
        end
        if box then
            box.Adornee = nil
            box.Visible = false
            box:Destroy()
        end
        if bill then
            bill.Adornee = nil
            bill.Enabled = false
            bill:Destroy()
        end
    end

    if root then
        ancestry = root.AncestryChanged:Connect(function(_,parent)
            if not parent then
                task.defer(destroyVisuals)
            end
        end)
    end

    local ret = {}
    ret.delete = destroyVisuals
    ret.settext = function(value)
        if txt and txt.Parent then txt.Text = tostring(value) end
    end
    ret.isalive = function()
        return alive and root and root:IsDescendantOf(workspace)
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
    noa90 = false,
    noscreech = false,
    getcode = false,
    roomsnolock = false,
    draweraura = false,
    itemaura = false,
    keyaura = false,
    itemfilter = "",
    itemallowlights = false,
    itemloot = true,
    itemlights = true,
    itemedible = true,
    itemutility = true,
    itemmisc = true,
    aurarange = 12,
    doorreach = false,
    doorreachrange = 0,
    doorreachdelay = 0.05,
    antidupe = false,
    snarebypass = false,
    autorooms = false,
}

local DELFLAGS = {}
for k,v in pairs(flags) do
    DELFLAGS[k] = v
end
local esptable = {doors={},keys={},items={},books={},entity={},chests={},lockers={},people={},gold={},dupe={}}
local dupeConnections = {}
local snareConnections = {}
local snareStates = setmetatable({}, {__mode = "k"})

local promptRegistry = setmetatable({}, {__mode = "k"})
local promptLastFired = setmetatable({}, {__mode = "k"})
local promptConnections = {}
local promptAuraRunning = false

local lightSourceNames = {
    lighter = true,
    flashlight = true,
    glowstick = true,
    glowsticks = true,
    bulklight = true,
    straplight = true,
    shakelight = true,
    lantern = true,
    candle = true,
    candlejar = true,
    laserpointer = true,
}

local function getPromptModel(prompt)
    local current = prompt and prompt.Parent
    while current and current ~= workspace do
        if current:IsA("Model") then
            return current
        end
        current = current.Parent
    end
end

local function getPromptPosition(prompt,model)
    local parent = prompt and prompt.Parent
    if parent and parent:IsA("Attachment") then
        return parent.WorldPosition
    elseif parent and parent:IsA("BasePart") then
        return parent.Position
    elseif model then
        return model:GetPivot().Position
    end
end

local function getPromptLabel(prompt,model)
    local objectText = prompt.ObjectText or ""
    local modelName = model and model.Name or ""
    if objectText ~= "" then
        return objectText
    end
    return modelName:gsub("Obtain$", "")
end

local function normalizeText(value)
    return tostring(value or ""):lower():gsub("[%p%s]+", "")
end

local function isLightSource(prompt,model)
    local label = normalizeText(getPromptLabel(prompt,model))
    local modelName = normalizeText(model and model.Name or "")
    for name in pairs(lightSourceNames) do
        local normalized = normalizeText(name)
        if label:find(normalized,1,true) or modelName:find(normalized,1,true) then
            return true
        end
    end
    return false
end

local function itemMatchesFilter(prompt,model)
    local filter = tostring(flags.itemfilter or ""):lower()
    if filter:gsub("[%s,]", "") == "" then
        return true
    end
    local label = (getPromptLabel(prompt,model) .. " " .. (model and model.Name or "")):lower()
    for token in filter:gmatch("[^,]+") do
        token = token:gsub("^%s+", ""):gsub("%s+$", "")
        if token ~= "" and label:find(token,1,true) then
            return true
        end
    end
    return false
end

local function isKeyPrompt(prompt,model)
    if not prompt or not model then
        return false
    end
    local name = model.Name
    local objectText = tostring(prompt.ObjectText or ""):lower()
    return name == "KeyObtain" or model:GetAttribute("IsKey") == true or name == "LeverForGate" or objectText:find("key",1,true) ~= nil
end

local function isItemPrompt(prompt,model)
    if not prompt or not model or isKeyPrompt(prompt,model) then
        return false
    end
    if model.Name == "GoldPile" or model.Name:sub(1,8) == "ChestBox" or model.Name == "DrawerContainer" then
        return false
    end
    local action = tostring(prompt.ActionText or ""):lower()
    return prompt.Name == "ModulePrompt" or action == "obtain" or model.Name:sub(-6) == "Obtain"
end

local itemCategoryNames = {
    loot = {goldpile=true, gold=true, coins=true, coin=true, coinroll=true, treasure=true, tipjar=true, goldgun=true},
    light = {lighter=true, flashlight=true, glowstick=true, glowsticks=true, bulklight=true, straplight=true, shakelight=true, lantern=true, candle=true, candlejar=true, laserpointer=true},
    edible = {apple=true, banana=true, nanner=true, candy=true, chocolate=true, gummyflashlight=true, vitamins=true, vitamin=true, smoothie=true, donut=true, gweensoda=true, bread=true, cheese=true, pizza=true, starbottle=true, starjug=true, starvial=true, riftsmoothie=true, riftjar=true},
    utility = {lockpick=true, skeletonkey=true, crucifix=true, bandage=true, bandagepack=true, aloevera=true, batterypack=true, shears=true, plant=true, multitool=true, compass=true, pocketmirror=true},
}

local function itemCategory(prompt,model)
    local values = {
        model and model:GetAttribute("ItemType"),
        model and model:GetAttribute("Category"),
        model and model:GetAttribute("ItemCategory"),
        prompt and prompt:GetAttribute("ItemType"),
        prompt and prompt:GetAttribute("Category"),
    }
    for _,value in ipairs(values) do
        local normalized = normalizeText(value)
        if normalized == "lightsource" or normalized == "light" then
            return "light"
        elseif normalized == "edible" or normalized == "food" or normalized == "consumable" then
            return "edible"
        elseif normalized == "loot" or normalized == "treasure" then
            return "loot"
        elseif normalized == "utility" or normalized == "tool" then
            return "utility"
        end
    end

    local label = normalizeText(getPromptLabel(prompt,model))
    local name = normalizeText(model and model.Name or ""):gsub("obtain$", "")
    local function matches(names)
        for token in pairs(names) do
            if label == token or name == token then
                return true
            end
        end
        return false
    end
    if isLightSource(prompt,model) or matches(itemCategoryNames.light) then
        return "light"
    elseif matches(itemCategoryNames.edible) then
        return "edible"
    elseif matches(itemCategoryNames.utility) then
        return "utility"
    elseif matches(itemCategoryNames.loot) then
        return "loot"
    end
    if model and model.Name == "GoldPile" then
        return "loot"
    end
    if isLightSource(prompt,model) then
        return "light"
    end
    return "misc"
end

local itemCategoryColors = {
    loot = Color3.fromRGB(255,205,60),
    light = Color3.fromRGB(255,245,145),
    edible = Color3.fromRGB(110,255,130),
    utility = Color3.fromRGB(100,190,255),
    misc = Color3.fromRGB(210,180,255),
}

local function itemCategoryEnabled(category)
    return (category == "loot" and flags.itemloot)
        or (category == "light" and flags.itemlights)
        or (category == "edible" and flags.itemedible)
        or (category == "utility" and flags.itemutility)
        or (category == "misc" and flags.itemmisc)
end

local function registerPrompt(instance)
    if instance:IsA("ProximityPrompt") then
        promptRegistry[instance] = true
    end
end

local function bindPromptRoot(root)
    if not root then
        return
    end
    for _,instance in ipairs(root:GetDescendants()) do
        registerPrompt(instance)
    end
    table.insert(promptConnections,root.DescendantAdded:Connect(registerPrompt))
end

local function stopPromptRegistry()
    for _,connection in ipairs(promptConnections) do
        connection:Disconnect()
    end
    table.clear(promptConnections)
    table.clear(promptRegistry)
    table.clear(promptLastFired)
    promptAuraRunning = false
end

local function startPromptRegistry()
    if promptAuraRunning then
        return
    end
    promptAuraRunning = true
    bindPromptRoot(CurrentRooms)
    table.insert(promptConnections,CurrentRooms.ChildAdded:Connect(function(room)
        bindPromptRoot(room)
    end))
    table.insert(promptConnections,ProximityPromptService.PromptShown:Connect(registerPrompt))
    task.spawn(function()
        while flags.itemaura or flags.keyaura do
            local now = os.clock()
            for prompt in pairs(promptRegistry) do
                if not prompt.Parent then
                    promptRegistry[prompt] = nil
                elseif prompt.Enabled then
                    local model = getPromptModel(prompt)
                    local item = flags.itemaura and isItemPrompt(prompt,model)
                    local key = flags.keyaura and isKeyPrompt(prompt,model)
                    local allowed = item or key
                    if item and not flags.itemallowlights and isLightSource(prompt,model) then
                        allowed = false
                    end
                    if item and allowed and not itemMatchesFilter(prompt,model) then
                        allowed = false
                    end
                    local position = allowed and getPromptPosition(prompt,model) or nil
                    local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
                    local inRange = position and root and (flags.aurarange <= 0 or (root.Position-position).Magnitude <= flags.aurarange)
                    if allowed and inRange and now-(promptLastFired[prompt] or 0) >= 0.35 then
                        promptLastFired[prompt] = now
                        pcall(fireproximityprompt,prompt)
                    end
                end
            end
            task.wait(0.12)
        end
        stopPromptRegistry()
    end)
end

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
                        local h = esp(v,Color3.fromRGB(90,255,40),core,"Lever")
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
            
            local prompt = v:FindFirstChildWhichIsA("ProximityPrompt",true)
            local isobtain = prompt and (isItemPrompt(prompt,v) or v.Name == "GoldPile" or v:GetAttribute("IsItem") == true)
            
            if isobtain and itemCategoryEnabled(itemCategory(prompt,v)) then
                task.wait(0.1)
                local part = v.PrimaryPart or v:FindFirstChild("Hitbox") or v:FindFirstChildWhichIsA("BasePart",true)
                
                if part then
                    local category = itemCategory(prompt,v)
                    local label = prompt.ObjectText ~= "" and prompt.ObjectText or v.Name:gsub("Obtain$","")
                    local h = esp(v,itemCategoryColors[category] or itemCategoryColors.misc,part,"["..category:upper().."] "..label)
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
    Rush = "Rush",
    RushMovingEntity = "Rush",
    AmbushMoving = "Ambush",
    Ambush = "Ambush",
    AmbushMovingEntity = "Ambush",
    Eyes = "Eyes",
    A60 = "A60",
    A120 = "A120",
    FigureRig = "Figure",
    Figure = "Figure",
    FigureRagdoll = "Figure",
    GiggleCeiling = "Giggle",
    Giggle = "Giggle",
    Snare = "Snare",
    Dread = "Dread",
    Blitz = "Blitz",
    BlitzMoving = "Blitz",
    BlitzMovingEntity = "Blitz",
    BackdoorRush = "Blitz",
    Lookman = "Lookman",
    BackdoorLookman = "Lookman",
    Surge = "Surge",
    SurgeWarning = "Surge",
    SurgeMoving = "Surge",
    Bramble = "Bramble",
    Groundskeeper = "Groundskeeper",
    Monument = "Monument",
    Gloombats = "Gloombats",
    GloombatSwarm = "Gloombats",
    LiveEntityBramble = "Bramble",
    BrambleSnare = "Snare",
    MonumentEntity = "Monument",
    Sally = "Sally",
    SallyLingering = "Sally",
    JeffTheKiller = "Jeff The Killer",
    Screech = "Screech",
    Halt = "Halt",
    SeekMoving = "Seek",
    Seek = "Seek",
    Jack = "Jack",
    Grumble = "Grumble",
    QueenGrumble = "Queen Grumble",
}

local entityattributes = {
    EntityName = true,
    Entity = true,
    EntityType = true,
}

local function resolveEntityName(v)
    local exact = entitynames[v.Name]
    if exact then
        return exact
    end
    for attribute in pairs(entityattributes) do
        local value = v:GetAttribute(attribute)
        if typeof(value) == "string" then
            local attributeName = entitynames[value]
            if attributeName then
                return attributeName
            end
        end
    end
end

local function entitytarget(v)
    if not v:IsA("Model") then
        return
    end
    
    local display = resolveEntityName(v)
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
                local h = esp(v,Color3.fromRGB(255,25,25),core,display)
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

window_esp.toggle("loot item esp",true,function(val)
    flags.itemloot = val
end)

window_esp.toggle("light source item esp",true,function(val)
    flags.itemlights = val
end)

window_esp.toggle("edible item esp",true,function(val)
    flags.itemedible = val
end)

window_esp.toggle("utility item esp",true,function(val)
    flags.itemutility = val
end)

window_esp.toggle("misc item esp",true,function(val)
    flags.itemmisc = val
end)

local function getRootPart(instance)
    if not instance then
        return
    end
    if instance:IsA("BasePart") then
        return instance
    end
    return instance.PrimaryPart or instance:FindFirstChild("Hitbox") or instance:FindFirstChildWhichIsA("BasePart",true)
end

local function getDoorPosition(door)
    local part = getRootPart(door)
    if part then
        return part.Position
    end
    local ok,pivot = pcall(door.GetPivot,door)
    return ok and pivot.Position or nil
end

local function isFakeDoor(instance)
    local current = instance
    while current and current ~= workspace do
        if current.Name == "DoorFake" then
            return true
        end
        current = current.Parent
    end
    return false
end

local function getCurrentDoor()
    local gameData = game.ReplicatedStorage:FindFirstChild("GameData")
    local latestRoom = gameData and gameData:FindFirstChild("LatestRoom")
    local room = latestRoom and CurrentRooms:FindFirstChild(tostring(latestRoom.Value))
    local door = room and room:FindFirstChild("Door")
    local remote = door and door:FindFirstChild("ClientOpen")
    if remote and remote:IsA("RemoteEvent") and not isFakeDoor(door) then
        return door,remote
    end
end

local doorReachConnection
local function stopDoorReach()
    if doorReachConnection then
        doorReachConnection:Disconnect()
        doorReachConnection = nil
    end
end

local function startDoorReach()
    stopDoorReach()
    doorReachConnection = RunService.Heartbeat:Connect(function()
        if not flags.doorreach then
            return
        end
        local door,remote = getCurrentDoor()
        if not door or not remote then
            return
        end
        local range = tonumber(flags.doorreachrange) or 0
        if range > 0 then
            local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
            local position = getDoorPosition(door)
            if not root or not position or (root.Position - position).Magnitude > range then
                return
            end
        end
        local now = os.clock()
        if now - (flags._lastDoorReach or 0) < math.max(0.01,tonumber(flags.doorreachdelay) or 0.05) then
            return
        end
        flags._lastDoorReach = now
        pcall(remote.FireServer,remote)
    end)
end

window_misc.toggle("door reach",false,function(val)
    flags.doorreach = val
    if val then
        startDoorReach()
    else
        stopDoorReach()
    end
end)

window_misc.slider("door reach range (0 = infinite)",0,1000,5,0,function(value)
    flags.doorreachrange = value
end)

window_misc.slider("door reach delay",0.01,0.5,0.01,0.05,function(value)
    flags.doorreachdelay = value
end)

local dupePromptStates = setmetatable({}, {__mode = "k"})
local dupeVisuals = setmetatable({}, {__mode = "k"})

local function findFakeDoor(instance)
    local current = instance
    while current and current ~= workspace do
        if current.Name == "DoorFake" then
            return current
        end
        current = current.Parent
    end
end

local function markFakeDoor(fake)
    if not flags.antidupe or not fake or not fake.Parent then
        return
    end
    for _,instance in ipairs(fake:GetDescendants()) do
        if instance:IsA("ProximityPrompt") then
            if dupePromptStates[instance] == nil then
                dupePromptStates[instance] = instance.Enabled
            end
            instance.Enabled = false
        end
    end
    if not dupeVisuals[fake] then
        local core = getRootPart(fake)
        if core then
            dupeVisuals[fake] = esp(fake,Color3.fromRGB(255,120,50),core,"FAKE DOOR")
        end
    end
end

local function restoreFakeDoors()
    for prompt,enabled in pairs(dupePromptStates) do
        if prompt and prompt.Parent then
            prompt.Enabled = enabled
        end
        dupePromptStates[prompt] = nil
    end
    for fake,visual in pairs(dupeVisuals) do
        if visual then
            visual.delete()
        end
        dupeVisuals[fake] = nil
    end
end

local function stopAntiDupe()
    for _,connection in ipairs(dupeConnections) do
        connection:Disconnect()
    end
    table.clear(dupeConnections)
    restoreFakeDoors()
end

local function startAntiDupe()
    stopAntiDupe()
    local function check(instance)
        local fake = findFakeDoor(instance)
        if fake then
            markFakeDoor(fake)
        end
    end
    for _,room in ipairs(CurrentRooms:GetChildren()) do
        for _,instance in ipairs(room:GetDescendants()) do
            check(instance)
        end
    end
    table.insert(dupeConnections,CurrentRooms.DescendantAdded:Connect(check))
end

window_misc.toggle("anti dupe doors",false,function(val)
    flags.antidupe = val
    if val then
        startAntiDupe()
    else
        stopAntiDupe()
    end
end)

local function findSnareRoot(instance)
    local current = instance
    while current and current ~= workspace do
        if current.Name == "Snare" or current.Name == "BrambleSnare" then
            return current
        end
        current = current.Parent
    end
end

local function suppressSnare(snare)
    if not flags.snarebypass or not snare or not snare.Parent then
        return
    end
    local function suppress(instance)
        if not instance:IsA("BasePart") then
            return
        end
        if not snareStates[instance] then
            snareStates[instance] = {
                cancollide = instance.CanCollide,
                cantouch = instance.CanTouch,
                canquery = instance.CanQuery,
                transparency = instance.LocalTransparencyModifier,
            }
        end
        instance.CanCollide = false
        instance.CanTouch = false
        instance.CanQuery = false
        instance.LocalTransparencyModifier = 1
    end
    suppress(snare)
    for _,instance in ipairs(snare:GetDescendants()) do
        suppress(instance)
        if instance:IsA("ParticleEmitter") or instance:IsA("Beam") or instance:IsA("Trail") then
            instance.Enabled = false
        end
    end
end

local function restoreSnares()
    for instance,state in pairs(snareStates) do
        if instance and instance.Parent then
            instance.CanCollide = state.cancollide
            instance.CanTouch = state.cantouch
            instance.CanQuery = state.canquery
            instance.LocalTransparencyModifier = state.transparency
        end
        snareStates[instance] = nil
    end
end

local function stopSnareBypass()
    for _,connection in ipairs(snareConnections) do
        connection:Disconnect()
    end
    table.clear(snareConnections)
    restoreSnares()
end

local function startSnareBypass()
    stopSnareBypass()
    local function check(instance)
        local snare = findSnareRoot(instance)
        if snare then
            suppressSnare(snare)
        end
    end
    for _,room in ipairs(CurrentRooms:GetChildren()) do
        for _,instance in ipairs(room:GetDescendants()) do
            check(instance)
        end
    end
    table.insert(snareConnections,CurrentRooms.DescendantAdded:Connect(check))
    local liveEntities = workspace:FindFirstChild("LiveEntities")
    if liveEntities then
        table.insert(snareConnections,liveEntities.DescendantAdded:Connect(check))
    end
end

window_misc.toggle("snare bypass",false,function(val)
    flags.snarebypass = val
    if val then
        startSnareBypass()
    else
        stopSnareBypass()
    end
end)

local screechdisable = game.ReplicatedStorage:WaitForChild("GameData"):FindFirstChild("EntityDisableScreech")

if screechdisable then
    window_misc.toggle("harmless screech",false,function(val)
        flags.noscreech = val
        
        if val then
            local oldvalue = screechdisable.Value
            local connections = {}
            local function removeScreech(instance)
                if not flags.noscreech or not instance:IsA("Model") then
                    return
                end
                local lower = instance.Name:lower()
                if lower == "screech" or lower:find("screech",1,true) then
                    pcall(instance.Destroy,instance)
                end
            end
            local function reinforce()
                if flags.noscreech and screechdisable.Parent and screechdisable.Value ~= true then
                    screechdisable.Value = true
                end
            end
            screechdisable.Value = true
            table.insert(connections,screechdisable.Changed:Connect(reinforce))
            table.insert(connections,workspace.DescendantAdded:Connect(removeScreech))
            task.spawn(function()
                while flags.noscreech and screechdisable.Parent do
                    reinforce()
                    task.wait(0.05)
                end
            end)
            repeat task.wait() until not flags.noscreech
            for _,connection in ipairs(connections) do
                connection:Disconnect()
            end
            if screechdisable.Parent then
                screechdisable.Value = oldvalue
            end
        end
    end)
end

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

window_misc.toggle("item prompt aura",false,function(val)
    flags.itemaura = val
    if val then
        startPromptRegistry()
    end
end)

window_misc.toggle("key prompt aura",false,function(val)
    flags.keyaura = val
    if val then
        startPromptRegistry()
    end
end)

window_misc.toggle("include light source items",false,function(val)
    flags.itemallowlights = val
end)

window_misc.textbox("item names, comma separated; blank = all",function(value)
    flags.itemfilter = tostring(value or "")
end)

window_misc.slider("item/key aura range",0,100,1,12,function(value)
    flags.aurarange = value
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
