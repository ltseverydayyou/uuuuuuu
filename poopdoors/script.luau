local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
local rayWindow = Rayfield:CreateWindow({
    name = "DOORS",
    subtitle = "Rayfield Gen2",
    sidebarLayout = true,
})
local library = {tabs = {}}
function library.window(name)
    local key = tostring(name):lower()
    if library.tabs[key] then
        return library.tabs[key]
    end
    local tab = rayWindow:CreateTab({name = tostring(name)})
    local wrapper = {}
    function wrapper.toggle(label,default,callback)
        return tab:CreateToggle({name = label,value = default == true,callback = callback})
    end
    function wrapper.slider(label,min,max,step,default,callback)
        return tab:CreateSlider({name = label,range = {min,max},increment = step,value = default,callback = callback})
    end
    function wrapper.button(label,callback)
        return tab:CreateButton({name = label,callback = callback})
    end
    function wrapper.textbox(label,callback)
        return tab:CreateInput({name = label,value = "",callback = callback})
    end
    function wrapper.dropdown(label,options,default,multi,callback)
        return tab:CreateDropdown({name = label,options = options,value = default or (multi and {} or nil),multiSelect = multi == true,callback = callback})
    end
    function wrapper.label(text)
        return tab:CreateButton({name = tostring(text),callback = function() end})
    end
    library.tabs[key] = wrapper
    return wrapper
end
function library.delete()
    pcall(function() rayWindow:Destroy() end)
end
local scriptEnvironment = type(getgenv) == "function" and getgenv() or _G
local plr = game.Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CurrentRooms = workspace:WaitForChild("CurrentRooms")
local guiParent = (gethui and gethui()) or game.CoreGui
local runtime = {}
runtime.originalFireProximityPrompt = type(fireproximityprompt) == "function" and fireproximityprompt or nil
runtime.promptFireStates = setmetatable({}, {__mode = "k"})

function runtime.getFirePromptPart(prompt)
    if not prompt then
        return nil
    end
    local parent = prompt.Parent
    if parent then
        if parent:IsA("Attachment") and parent.Parent and parent.Parent:IsA("BasePart") then
            return parent.Parent
        elseif parent:IsA("BasePart") then
            return parent
        end
    end
    local model = prompt:FindFirstAncestorWhichIsA("Model")
    if model then
        return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
    end
    return prompt:FindFirstAncestorWhichIsA("BasePart")
end

function runtime.firePromptOne(prompt,options)
    if not (prompt and prompt.Parent and prompt:IsA("ProximityPrompt")) then
        return false
    end
    local state = runtime.promptFireStates[prompt]
    if state and state.inFlight then
        return false
    end
    state = {
        inFlight = true,
        enabled = prompt.Enabled,
        hold = prompt.HoldDuration,
        los = prompt.RequiresLineOfSight,
        distance = prompt.MaxActivationDistance,
        exclusivity = prompt.Exclusivity,
        parent = prompt.Parent,
    }
    runtime.promptFireStates[prompt] = state
    local opts = typeof(options) == "table" and options or {hold = tonumber(options) or 0}
    local proxy
    local ok = pcall(function()
        prompt.HoldDuration = 0
        if opts.disableLoS ~= false then
            prompt.RequiresLineOfSight = false
        end
        prompt.MaxActivationDistance = tonumber(opts.distance) or 1000000000
        prompt.Exclusivity = opts.exclusivity or Enum.ProximityPromptExclusivity.AlwaysShow
        if opts.forceEnable ~= false then
            prompt.Enabled = true
        end

        local camera = workspace.CurrentCamera
        local part = runtime.getFirePromptPart(prompt)
        local shouldProxy = opts.relocate ~= false
        if shouldProxy and camera and part then
            local viewport,onScreen = camera:WorldToViewportPoint(part.Position)
            local direction = part.Position-camera.CFrame.Position
            shouldProxy = viewport.Z <= 0 or not onScreen or direction.Magnitude <= 0 or direction.Unit:Dot(camera.CFrame.LookVector) < 0.05
        end
        if shouldProxy and camera then
            proxy = Instance.new("Part")
            proxy.Name = "_doorsPromptProxy"
            proxy.Size = Vector3.new(0.05,0.05,0.05)
            proxy.Anchored = true
            proxy.CanCollide = false
            proxy.CanTouch = false
            proxy.CanQuery = false
            proxy.CastShadow = false
            proxy.Transparency = 1
            local distance = math.clamp(tonumber(opts.relocateDistance) or 5,1,50)
            local position = camera.CFrame.Position + camera.CFrame.LookVector*distance - camera.CFrame.UpVector*0.35
            proxy.CFrame = CFrame.new(position,position+camera.CFrame.LookVector)
            proxy.Parent = workspace
            prompt.Enabled = false
            prompt.Parent = proxy
            task.wait()
            if opts.forceEnable ~= false then
                prompt.Enabled = true
            end
        end

        prompt:InputHoldBegin()
        local hold = tonumber(opts.hold) or 0
        if hold > 0 then
            task.wait(hold)
        else
            RunService.Heartbeat:Wait()
        end
        prompt:InputHoldEnd()
        RunService.Heartbeat:Wait()
    end)

    pcall(function()
        if prompt and state.parent and state.parent.Parent then
            prompt.Parent = state.parent
        end
    end)
    if proxy then
        pcall(proxy.Destroy,proxy)
    end
    if prompt and prompt.Parent then
        pcall(function()
            prompt.Enabled = state.enabled
            prompt.HoldDuration = state.hold
            prompt.RequiresLineOfSight = state.los
            prompt.MaxActivationDistance = state.distance
            prompt.Exclusivity = state.exclusivity
        end)
    end
    runtime.promptFireStates[prompt] = nil

    if not ok and runtime.originalFireProximityPrompt then
        return pcall(runtime.originalFireProximityPrompt,prompt,0,true)
    end
    return ok
end

function runtime.customFireProximityPrompt(target,options)
    if typeof(target) == "Instance" and target:IsA("ProximityPrompt") then
        task.spawn(runtime.firePromptOne,target,options)
        return true
    elseif typeof(target) == "table" then
        local fired = false
        for _,prompt in ipairs(target) do
            if typeof(prompt) == "Instance" and prompt:IsA("ProximityPrompt") then
                fired = true
                task.spawn(runtime.firePromptOne,prompt,options)
            end
        end
        return fired
    end
    return false
end

rawset(scriptEnvironment,"fireproximityprompt",runtime.customFireProximityPrompt)
fireproximityprompt = runtime.customFireProximityPrompt

plr.CharacterAdded:Connect(function(newchar)
    char = newchar
    hum = char:WaitForChild("Humanoid")
end)

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
    godmode = false,
    autoprompts = false,
    ladderbypass = true,
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
    itemhealing = true,
    itemobjective = true,
    itemutility = true,
    itemmagical = true,
    itembattle = true,
    itemmisc = true,
    itemexcludedcategories = {},
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

local promptRegistry = {list = {}, idx = setmetatable({}, {__mode = "k"})}
local promptLastFired = setmetatable({}, {__mode = "k"})
local promptFireBusy = setmetatable({}, {__mode = "k"})
local promptConnections = {}
local promptAuraRunning = false
local promptCursor = 0
local promptMaxFiresPerBatch = 18
local promptScanPerBatch = 64
local itemVisualsByRoot = setmetatable({}, {__mode = "k"})
local autoPromptExactTargets = {
    goldpile=true, lock=true, door=true, toolbox=true, lever=true, bandage=true, button=true,
    metal=true, knobs=true, knob=true, livebreakerpolepickup=true, drawerdoors=true, hole=true,
    rolltopcontainer=true, lockpick=true, chestbox=true, crucifix=true, skeletonkey=true, plant=true,
    shears=true, cellar=true, cuttablevines=true, skulllock=true, wheel=true, starvial=true,
    starbottle=true, livehintbook=true, libraryhintpaper=true, pizza=true,
}
local autoPromptFindTargets = {"stardust","fuse","keyobtain","lotus"}


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
    riftcandle = true,
}

local function getPromptModel(prompt)
    local current = prompt and prompt.Parent
    while current and current ~= workspace do
        if current:IsA("Model") or current:IsA("Tool") then
            return current
        end
        current = current.Parent
    end
end

local function isInDropsFolder(instance)
    local current = instance
    while current and current ~= workspace do
        if current.Name == "Drops" then
            return true
        end
        current = current.Parent
    end
    return false
end

local function getPromptPosition(prompt,model)
    local parent = prompt and prompt.Parent
    if parent and parent:IsA("Attachment") then
        return parent.WorldPosition
    elseif parent and parent:IsA("BasePart") then
        return parent.Position
    elseif model then
        local part = model:IsA("BasePart") and model or model:FindFirstChildWhichIsA("BasePart",true)
        if part then
            return part.Position
        end
        local ok,pivot = pcall(model.GetPivot,model)
        if ok then
            return pivot.Position
        end
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

local function getItemAttribute(model,name)
    if not model then
        return nil
    end
    local value = model:GetAttribute(name)
    if value ~= nil then
        return value
    end
    return model:GetAttribute("Tool_" .. name)
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
    local modelLabel = getItemAttribute(model,"Pickup") or getItemAttribute(model,"NameSingular")
        or (model and model.Name or "")
    -- Admin-panel prompts can retain a generic/stale ObjectText. Prefer the
    -- model's catalog identity whenever it is available.
    local label = (tostring(modelLabel) .. " " .. (model and model.Name or "")):lower()
    if not model then
        label = getPromptLabel(prompt,model):lower()
    end
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
    healing = {bandagepack=true, aloevera=true, vitamins=true, vitamin=true},
    objective = {libraryhintpaperhard=true, keyretro=true, holygrenade=true, keyelectrical=true, key=true, skeletonkey=true, keybackdoor=true, keyiron=true, hintbook=true, libraryhintpaper=true, generatorfuse=true},
    utility = {lockpick=true, skeletonkey=true, crucifix=true, bandage=true, bandagepack=true, aloevera=true, batterypack=true, shears=true, plant=true, multitool=true, compass=true, pocketmirror=true},
    magical = {starbottle=true, starjug=true, starvial=true, riftcandle=true, riftsmoothie=true, riftjar=true},
    battle = {goldgun=true, bigbomb=true, bigproptool=true, bomb=true, knockbomb=true, nanner=true, nannerpeel=true, snakebox=true, stopsign=true, boxinggloves=true},
}

-- Mirrors the live admin-panel catalog. This takes priority over generic
-- attributes because some items intentionally carry another system's flags
-- (for example Shears has a LightSource flag but belongs under Utility).
local itemAdminCategories = {
    lighter="light", straplight="light", shakelight="light", candle="light",
    glowsticks="light", bulklight="light", flashlight="light", lantern="light",
    bandagepack="healing", vitamins="healing", aloevera="healing",
    batterypack="utility", lockpick="utility", laserpointer="utility", shears="utility",
    alarmclock="utility", tipjar="utility", multitool="utility", compass="utility",
    pocketmirror="utility", crucifix="utility",
    smoothie="edible", donut="edible", gweensoda="edible", bread="edible",
    cheese="edible", pizza="edible",
    starbottle="magical", starjug="magical", starvial="magical", riftcandle="magical",
    riftsmoothie="magical", riftjar="magical",
    goldgun="battle", bigbomb="battle", bigproptool="battle", bomb="battle",
    knockbomb="battle", nanner="battle", nannerpeel="battle", snakebox="battle",
    stopsign="battle", boxinggloves="battle",
    libraryhintpaperhard="objective", keyretro="objective", holygrenade="objective",
    keyelectrical="objective", key="objective", skeletonkey="objective",
    keybackdoor="objective", keyiron="objective", hintbook="objective",
    libraryhintpaper="objective", generatorfuse="objective",
    coinroll="loot",
    knockbackstick="misc",
}

local function itemCategory(prompt,model)
    local label = normalizeText(getPromptLabel(prompt,model))
    local name = normalizeText(model and model.Name or ""):gsub("obtain$", "")
    local adminCategory = itemAdminCategories[name] or itemAdminCategories[label]
    if adminCategory then
        return adminCategory
    end

    local values = {
        getItemAttribute(model,"ItemType"),
        getItemAttribute(model,"Category"),
        getItemAttribute(model,"ItemCategory"),
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

    if model then
        if getItemAttribute(model,"LightSource") == true or getItemAttribute(model,"LightSourceBeam") == true then
            return "light"
        end
        if getItemAttribute(model,"Essential") == true
            or getItemAttribute(model,"ToolModuleName") == "Key"
            or getItemAttribute(model,"LockID") ~= nil
        then
            return "objective"
        end
    end

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
    elseif matches(itemCategoryNames.objective) then
        return "objective"
    elseif matches(itemCategoryNames.edible) then
        return "edible"
    elseif matches(itemCategoryNames.healing) then
        return "healing"
    elseif matches(itemCategoryNames.utility) then
        return "utility"
    elseif matches(itemCategoryNames.magical) then
        return "magical"
    elseif matches(itemCategoryNames.battle) then
        return "battle"
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
    healing = Color3.fromRGB(100,255,190),
    objective = Color3.fromRGB(255,150,80),
    utility = Color3.fromRGB(100,190,255),
    magical = Color3.fromRGB(210,120,255),
    battle = Color3.fromRGB(255,90,90),
    misc = Color3.fromRGB(210,180,255),
}

local function itemCategoryEnabled(category)
    if flags.itemexcludedcategories and flags.itemexcludedcategories[category] then
        return false
    end
    return (category == "loot" and flags.itemloot)
        or (category == "light" and flags.itemlights)
        or (category == "edible" and flags.itemedible)
        or (category == "healing" and flags.itemhealing)
        or (category == "objective" and flags.itemobjective)
        or (category == "utility" and flags.itemutility)
        or (category == "magical" and flags.itemmagical)
        or (category == "battle" and flags.itembattle)
        or (category == "misc" and flags.itemmisc)
end

local function isAutoPromptTarget(prompt)
    if not prompt or isInDropsFolder(prompt) then
        return false
    end
    local current = prompt
    while current and current ~= workspace do
        local name = tostring(current.Name or ""):lower()
        if autoPromptExactTargets[name] then
            return true
        end
        for _,term in ipairs(autoPromptFindTargets) do
            if name:find(term,1,true) then
                return true
            end
        end
        current = current.Parent
    end
    return false
end

local function registerPrompt(instance)
    if not (instance and instance:IsA("ProximityPrompt")) or promptRegistry.idx[instance] then
        return
    end
    promptRegistry.list[#promptRegistry.list+1] = instance
    promptRegistry.idx[instance] = #promptRegistry.list
end

local function removePrompt(instance)
    local index = promptRegistry.idx[instance]
    if not index then return end
    local last = promptRegistry.list[#promptRegistry.list]
    promptRegistry.list[index] = last
    promptRegistry.list[#promptRegistry.list] = nil
    promptRegistry.idx[instance] = nil
    if last and last ~= instance then
        promptRegistry.idx[last] = index
    end
    promptLastFired[instance] = nil
    promptFireBusy[instance] = nil
end

local function bindPromptRoot(root)
    if not root then return end
    for _,instance in ipairs(root:GetDescendants()) do
        if instance:IsA("ProximityPrompt") then
            registerPrompt(instance)
        end
    end
    table.insert(promptConnections,root.DescendantAdded:Connect(function(instance)
        if instance:IsA("ProximityPrompt") then
            registerPrompt(instance)
        end
    end))
    table.insert(promptConnections,root.DescendantRemoving:Connect(function(instance)
        if promptRegistry.idx[instance] then
            removePrompt(instance)
        end
    end))
end

local function promptAllowedByJobs(prompt,model)
    local auto = flags.autoprompts and isAutoPromptTarget(prompt)
    local item = flags.itemaura and isItemPrompt(prompt,model)
    local key = flags.keyaura and isKeyPrompt(prompt,model)
    if item and isInDropsFolder(model) then
        item = false
    end
    if item and not flags.itemallowlights and isLightSource(prompt,model) then
        item = false
    end
    if item and not itemMatchesFilter(prompt,model) then
        item = false
    end
    if item and not itemCategoryEnabled(itemCategory(prompt,model)) then
        item = false
    end
    return auto,item,key
end

local function dispatchPromptFire(prompt,now)
    if promptFireBusy[prompt] then return false end
    promptFireBusy[prompt] = true
    promptLastFired[prompt] = now
    task.spawn(function()
        pcall(runtime.customFireProximityPrompt,prompt)
        promptFireBusy[prompt] = nil
    end)
    return true
end

local function runPromptBatch()
    local tracked = promptRegistry.list
    local count = #tracked
    if count == 0 then
        promptCursor = 0
        return
    end
    local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
    local now = os.clock()
    local scanBudget = math.min(count,math.max(promptMaxFiresPerBatch,promptScanPerBatch))
    local fired = 0
    local stale = {}
    for step = 1,scanBudget do
        if fired >= promptMaxFiresPerBatch then break end
        local index = ((promptCursor + step - 1) % count) + 1
        local prompt = tracked[index]
        if not (prompt and prompt.Parent) then
            if prompt then stale[#stale+1] = prompt end
        elseif prompt.Enabled then
            local model = getPromptModel(prompt)
            local auto,item,key = promptAllowedByJobs(prompt,model)
            local allowed = auto or item or key
            local inRange = auto
            if allowed and not auto then
                local position = getPromptPosition(prompt,model)
                inRange = position and root and (flags.aurarange <= 0 or (root.Position-position).Magnitude <= flags.aurarange)
            end
            local cooldown = auto and 0.1 or 0.35
            if allowed and inRange and not promptFireBusy[prompt] and now-(promptLastFired[prompt] or 0) >= cooldown then
                if dispatchPromptFire(prompt,now) then
                    fired += 1
                end
            end
        end
    end
    promptCursor = (promptCursor + scanBudget) % math.max(1,count)
    for _,prompt in ipairs(stale) do
        removePrompt(prompt)
    end
end

local function stopPromptRegistry()
    for _,connection in ipairs(promptConnections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(promptConnections)
    table.clear(promptRegistry.list)
    promptRegistry.idx = setmetatable({}, {__mode = "k"})
    table.clear(promptLastFired)
    promptFireBusy = setmetatable({}, {__mode = "k"})
    promptAuraRunning = false
    promptCursor = 0
end

local function startPromptRegistry()
    if promptAuraRunning then return end
    promptAuraRunning = true
    bindPromptRoot(workspace)
    table.insert(promptConnections,ProximityPromptService.PromptShown:Connect(registerPrompt))
    task.spawn(function()
        while promptAuraRunning and (flags.itemaura or flags.keyaura or flags.autoprompts) do
            runPromptBatch()
            task.wait(0.05)
        end
        if promptAuraRunning then
            stopPromptRegistry()
        end
    end)
end

runtime.doorSpeed = {
    max = 60,
    interval = 0.1,
    bindName = "DoorsScript_DoorsSpeedOffset",
    externalTeleportDistance = 4,
    godOffset = Vector3.new(0,-3,0),
    value = 0,
}

function runtime.getRoot()
    local current = plr.Character
    return current and (current.PrimaryPart or current:FindFirstChild("HumanoidRootPart"))
end

function runtime.getHumanoid()
    local current = plr.Character
    return current and current:FindFirstChildOfClass("Humanoid")
end

function runtime.doorSpeedCFrameNear(a,b,distance)
    return typeof(a) == "CFrame" and typeof(b) == "CFrame" and (a.Position-b.Position).Magnitude <= (distance or 0.05)
end

function runtime.getReplicatedOffsetCFrame(baseCFrame)
    if typeof(baseCFrame) ~= "CFrame" then
        return baseCFrame
    end
    if flags.godmode then
        return baseCFrame + runtime.doorSpeed.godOffset
    end
    return baseCFrame
end

function runtime.adoptDoorSpeedExternalCFrame(root,observed)
    local state = runtime.doorSpeed
    if not root or typeof(observed) ~= "CFrame" then
        return false
    end
    if typeof(state.localCFrame) ~= "CFrame" then
        state.localCFrame = observed
        state.serverCFrame = observed
        state.lastBurst = os.clock()
        state.lastWriteCFrame = runtime.getReplicatedOffsetCFrame(observed)
        return true
    end
    local written = state.lastWriteCFrame or runtime.getReplicatedOffsetCFrame(state.serverCFrame)
    if runtime.doorSpeedCFrameNear(observed,written) then
        return false
    end
    if (observed.Position-state.localCFrame.Position).Magnitude < state.externalTeleportDistance then
        return false
    end
    state.localCFrame = observed
    state.serverCFrame = observed
    state.lastBurst = os.clock()
    state.lastWriteCFrame = runtime.getReplicatedOffsetCFrame(observed)
    return true
end

function runtime.stopDoorOffsetReplication()
    local state = runtime.doorSpeed
    local localCFrame = state.localCFrame
    state.active = false
    if state.heartbeat then
        state.heartbeat:Disconnect()
        state.heartbeat = nil
    end
    pcall(RunService.UnbindFromRenderStep,RunService,state.bindName)
    local root = runtime.getRoot()
    if root and typeof(localCFrame) == "CFrame" then
        pcall(function() root.CFrame = localCFrame end)
    end
    local currentHum = runtime.getHumanoid()
    if currentHum and tonumber(state.originalWalkSpeed) then
        pcall(function() currentHum.WalkSpeed = state.originalWalkSpeed end)
    end
    state.root = nil
    state.humanoid = nil
    state.originalWalkSpeed = nil
    state.localCFrame = nil
    state.serverCFrame = nil
    state.lastBurst = nil
    state.lastWriteCFrame = nil
    state.value = 0
end

function runtime.ensureDoorOffsetReplication()
    local state = runtime.doorSpeed
    local root = runtime.getRoot()
    local currentHum = runtime.getHumanoid()
    if not (root and currentHum) then
        return nil
    end
    if not state.active then
        state.root = root
        state.humanoid = currentHum
        state.localCFrame = root.CFrame
        state.serverCFrame = root.CFrame
        state.lastBurst = os.clock()
        state.lastWriteCFrame = runtime.getReplicatedOffsetCFrame(root.CFrame)
        state.active = true
    end
    if state.heartbeat then
        state.heartbeat:Disconnect()
    end
    pcall(RunService.UnbindFromRenderStep,RunService,state.bindName)
    state.heartbeat = RunService.Heartbeat:Connect(function()
        if not state.active then
            return
        end
        local currentRoot = runtime.getRoot()
        local currentHumanoid = runtime.getHumanoid()
        if not (currentRoot and currentHumanoid) then
            return
        end
        if state.root ~= currentRoot then
            state.root = currentRoot
            state.humanoid = currentHumanoid
            state.localCFrame = currentRoot.CFrame
            state.serverCFrame = currentRoot.CFrame
            state.lastBurst = os.clock()
            state.lastWriteCFrame = runtime.getReplicatedOffsetCFrame(currentRoot.CFrame)
            if (tonumber(state.value) or 0) > 0 then
                state.originalWalkSpeed = currentHumanoid.WalkSpeed
            else
                state.originalWalkSpeed = nil
            end
        end
        local speed = tonumber(state.value) or 0
        if speed > 0 then
            currentHumanoid.WalkSpeed = speed
        end
        local observed = currentRoot.CFrame
        local written = state.lastWriteCFrame or runtime.getReplicatedOffsetCFrame(state.serverCFrame)
        if not runtime.doorSpeedCFrameNear(observed,written) then
            runtime.adoptDoorSpeedExternalCFrame(currentRoot,observed)
        end
        written = state.lastWriteCFrame or runtime.getReplicatedOffsetCFrame(state.serverCFrame)
        if not runtime.doorSpeedCFrameNear(observed,written) then
            state.localCFrame = observed
        end
        local now = os.clock()
        if speed <= 0 and flags.godmode then
            state.serverCFrame = state.localCFrame or observed
            state.lastBurst = now
        elseif now-(state.lastBurst or 0) >= math.max(0.1,tonumber(state.interval) or 0.1) then
            state.serverCFrame = state.localCFrame or observed
            state.lastBurst = now
        end
        local serverCFrame = state.serverCFrame or observed
        local replicatedCFrame = runtime.getReplicatedOffsetCFrame(serverCFrame)
        state.lastWriteCFrame = replicatedCFrame
        pcall(function() currentRoot.CFrame = replicatedCFrame end)
    end)
    RunService:BindToRenderStep(state.bindName,Enum.RenderPriority.First.Value,function()
        if not state.active then
            return
        end
        local currentRoot = runtime.getRoot()
        if not currentRoot then
            return
        end
        local observed = currentRoot.CFrame
        local written = state.lastWriteCFrame or runtime.getReplicatedOffsetCFrame(state.serverCFrame)
        if not runtime.doorSpeedCFrameNear(observed,written) then
            runtime.adoptDoorSpeedExternalCFrame(currentRoot,observed)
        end
        local localCFrame = state.localCFrame or observed
        state.localCFrame = localCFrame
        pcall(function() currentRoot.CFrame = localCFrame end)
    end)
    return true
end

function runtime.stopDoorSpeed()
    local state = runtime.doorSpeed
    state.value = 0
    local currentHum = runtime.getHumanoid()
    if currentHum and tonumber(state.originalWalkSpeed) then
        pcall(function() currentHum.WalkSpeed = state.originalWalkSpeed end)
    end
    state.originalWalkSpeed = nil
    if flags.godmode then
        runtime.ensureDoorOffsetReplication()
    else
        runtime.stopDoorOffsetReplication()
    end
end

function runtime.startDoorSpeed(value)
    local state = runtime.doorSpeed
    local speed = math.clamp(tonumber(value) or 0,0,state.max)
    if speed <= 0 then
        runtime.stopDoorSpeed()
        return 0
    end
    local currentHum = runtime.getHumanoid()
    if not currentHum then
        return nil
    end
    if (tonumber(state.value) or 0) <= 0 then
        state.originalWalkSpeed = currentHum.WalkSpeed
    end
    state.value = speed
    runtime.ensureDoorOffsetReplication()
    currentHum.WalkSpeed = speed
    return speed
end

function runtime.setGodMode(enabled)
    flags.godmode = enabled == true
    local state = runtime.doorSpeed
    if flags.godmode then
        runtime.ensureDoorOffsetReplication()
        local root = runtime.getRoot()
        if root and typeof(state.localCFrame) ~= "CFrame" then
            state.localCFrame = root.CFrame
            state.serverCFrame = root.CFrame
        end
        return true
    end
    state.lastWriteCFrame = state.serverCFrame
    if (tonumber(state.value) or 0) > 0 then
        runtime.ensureDoorOffsetReplication()
        return false
    end
    runtime.stopDoorOffsetReplication()
    return false
end

runtime.ladder = {connections = {}}

function runtime.stopLadderBypass()
    for _,connection in ipairs(runtime.ladder.connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end
    table.clear(runtime.ladder.connections)
end

function runtime.dropFromLadder(currentChar)
    if not (flags.ladderbypass and currentChar and currentChar.Parent) then
        return
    end
    local currentHum = currentChar:FindFirstChildOfClass("Humanoid")
    local root = currentChar.PrimaryPart or currentChar:FindFirstChild("HumanoidRootPart")
    currentChar:SetAttribute("Climbing",false)
    if root then
        root.Anchored = false
        root.Velocity = Vector3.new()
        root.CFrame = root.CFrame*CFrame.new(0,0,-3)
    end
    if currentHum then
        currentHum:ChangeState(Enum.HumanoidStateType.Running)
        local animator = currentHum:FindFirstChildOfClass("Animator") or currentHum
        for _,track in ipairs(animator:GetPlayingAnimationTracks()) do
            if tostring(track.Name or ""):lower():find("climb",1,true) then
                track:Stop()
            end
        end
    end
end

function runtime.bindLadderCharacter(currentChar)
    if not (flags.ladderbypass and currentChar) then
        return
    end
    table.insert(runtime.ladder.connections,currentChar:GetAttributeChangedSignal("Climbing"):Connect(function()
        if flags.ladderbypass and currentChar:GetAttribute("Climbing") == true then
            task.defer(runtime.dropFromLadder,currentChar)
        end
    end))
    if currentChar:GetAttribute("Climbing") == true then
        task.defer(runtime.dropFromLadder,currentChar)
    end
end

function runtime.startLadderBypass()
    runtime.stopLadderBypass()
    runtime.bindLadderCharacter(plr.Character)
    table.insert(runtime.ladder.connections,plr.CharacterAdded:Connect(function(currentChar)
        task.defer(runtime.bindLadderCharacter,currentChar)
    end))
end

runtime.figure = {running = false}

function runtime.figureSlotIndex(image)
    if not image or not image:IsA("ImageLabel") then
        return nil
    end
    local offset = image.ImageRectOffset
    local index = math.floor((offset.X or 0)/50+0.5)
    if index >= 0 and index <= 7 then
        return index
    end
end

function runtime.readFigureCode()
    local pg = plr:FindFirstChildOfClass("PlayerGui")
    local perm = pg and pg:FindFirstChild("PermUI")
    local hints = perm and perm:FindFirstChild("Hints")
    local map = {}
    if hints then
        for _,icon in ipairs(hints:GetChildren()) do
            if icon.Name == "Icon" and icon:IsA("ImageLabel") then
                local index = runtime.figureSlotIndex(icon)
                local label = icon:FindFirstChild("TextLabel")
                local digit = label and tonumber(label.Text)
                if index ~= nil and digit and digit >= 0 and digit <= 9 then
                    map[index] = tostring(math.floor(digit))
                end
            elseif icon:IsA("ImageLabel") then
                local index = runtime.figureSlotIndex(icon)
                local label = icon:FindFirstChild("TextLabel")
                local digit = label and tonumber(label.Text)
                if icon.Visible and index ~= nil and digit and digit >= 0 and digit <= 9 then
                    map[index] = tostring(math.floor(digit))
                end
            end
        end
    end
    local currentChar = plr.Character
    local paper = currentChar and currentChar:FindFirstChild("LibraryHintPaper")
    if not paper then
        local workspacePlayer = workspace:FindFirstChild(plr.Name)
        paper = workspacePlayer and workspacePlayer:FindFirstChild("LibraryHintPaper")
    end
    local ui = paper and paper:FindFirstChild("UI")
    if not ui then
        return nil
    end
    local code = {}
    for i = 1,5 do
        local image = ui:FindFirstChild(tostring(i))
        local index = runtime.figureSlotIndex(image)
        if index == nil or map[index] == nil then
            return nil
        end
        code[i] = map[index]
    end
    return table.concat(code)
end

function runtime.trySolveFigure()
    local state = runtime.figure
    if state.busy then
        return
    end
    local room = CurrentRooms:FindFirstChild("50")
    local door = room and room:FindFirstChild("Door")
    local padlock = door and door:FindFirstChild("Padlock")
    local locked = padlock and padlock:FindFirstChild("Padlocked")
    if not (room and padlock and locked and locked.Value == true) then
        return
    end
    local code = runtime.readFigureCode()
    if not code then
        return
    end
    if code == state.lastCode and state.lastRoom == room and os.clock()-(state.lastAttempt or 0) < 5 then
        return
    end
    local remotes = game.ReplicatedStorage:FindFirstChild("RemotesFolder")
    local remote = remotes and remotes:FindFirstChild("PL")
    if not (remote and remote:IsA("RemoteEvent")) then
        return
    end
    state.busy = true
    state.lastAttempt = os.clock()
    state.lastRoom = room
    state.lastCode = code
    pcall(function()
        local prompt = padlock:FindFirstChild("ActivateEventPrompt")
        local pg = plr:FindFirstChildOfClass("PlayerGui")
        local main = pg and pg:FindFirstChild("MainUI")
        local backout = main and main:FindFirstChild("MinigameBackout")
        if prompt and prompt.Enabled and not (backout and backout.Visible) then
            runtime.customFireProximityPrompt(prompt)
            task.wait(0.2)
        end
        remote:FireServer(code)
    end)
    state.busy = false
end

function runtime.stopFigureSolver()
    runtime.figure.running = false
    runtime.figure.busy = false
end

function runtime.startFigureSolver()
    local state = runtime.figure
    if state.running then
        return
    end
    state.running = true
    state.lastRoom = nil
    state.lastCode = nil
    state.lastAttempt = 0
    state.busy = false
    task.spawn(function()
        while state.running and flags.getcode do
            runtime.trySolveFigure()
            task.wait(0.5)
        end
    end)
    runtime.trySolveFigure()
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
local walkspeedslider = window_player.slider("walkspeed",0,60,0.5,16,function(val)
    flags.speed = val
    if char and char.Parent then
        char:SetAttribute("SpeedBoost", math.max(0,val-basewalkspeed))
    end
    if val <= 0 then
        runtime.stopDoorSpeed()
    else
        runtime.startDoorSpeed(val)
    end
end)

window_player.toggle("God Mode",false,function(val)
    runtime.setGodMode(val)
end)

window_player.toggle("ladder anti-cheat bypass",true,function(val)
    flags.ladderbypass = val
    if val then
        runtime.startLadderBypass()
    else
        runtime.stopLadderBypass()
    end
end)
runtime.startLadderBypass()

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
            if not (v:IsA("Model") or v:IsA("Tool")) or v.Name == "KeyObtain" or v:GetAttribute("IsKey") then
                return
            end
            
            local prompt = v:FindFirstChildWhichIsA("ProximityPrompt",true)
            if prompt and getPromptModel(prompt) ~= v then
                return
            end
            local isobtain = prompt and (isItemPrompt(prompt,v) or v.Name == "GoldPile" or v:GetAttribute("IsItem") == true)
            
            if isobtain and itemCategoryEnabled(itemCategory(prompt,v)) then
                task.wait(0.1)
                local previous = itemVisualsByRoot[v]
                if previous and previous.isalive() then
                    return
                end
                local part = (v:IsA("Model") and v.PrimaryPart)
                    or v:FindFirstChild("Hitbox")
                    or v:FindFirstChildWhichIsA("BasePart",true)
                
                if part then
                    local category = itemCategory(prompt,v)
                    local label = getItemAttribute(v,"NameSingular") or getItemAttribute(v,"Pickup")
                        or (prompt.ObjectText ~= "" and prompt.ObjectText)
                        or v.Name:gsub("Obtain$","")
                    local h = esp(v,itemCategoryColors[category] or itemCategoryColors.misc,part,"["..category:upper().."] "..label)
                    itemVisualsByRoot[v] = h
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

        local worldconnect = workspace.DescendantAdded:Connect(function(v)
            if v:IsA("ProximityPrompt") then
                local root = getPromptModel(v)
                if root then
                    task.defer(check,root)
                end
            elseif v:IsA("Model") or v:IsA("Tool") then
                task.defer(check,v)
            end
        end)

        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("Model") or v:IsA("Tool") then
                check(v)
            end
        end
        
        repeat task.wait() until not flags.espitems
        addconnect:Disconnect()
        worldconnect:Disconnect()
        
        for i,v in pairs(esptable.items) do
            v.delete()
        end 
        table.clear(itemVisualsByRoot)
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

window_esp.dropdown("exclude item categories",{
    "loot","light","edible","healing","objective","utility","magical","battle","misc"
},{},true,function(selected)
    local excluded = {}
    for _,category in ipairs(selected or {}) do
        excluded[tostring(category):lower()] = true
    end
    flags.itemexcludedcategories = excluded
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

local screechRuntime = {connections = {}, originalFlag = nil, flag = nil, hookedRemote = false}
local function getMainGameModules()
    local pg = plr:FindFirstChildOfClass("PlayerGui")
    local mainUI = pg and pg:FindFirstChild("MainUI")
    local initiator = mainUI and mainUI:FindFirstChild("Initiator")
    local mainGame = initiator and initiator:FindFirstChild("Main_Game")
    local remoteListener = mainGame and mainGame:FindFirstChild("RemoteListener")
    return remoteListener and remoteListener:FindFirstChild("Modules")
end
local function disconnectScreechConnections()
    for _,connection in ipairs(screechRuntime.connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(screechRuntime.connections)
end
local function fixScreech()
    local gameData = game.ReplicatedStorage:FindFirstChild("GameData")
    local flag = gameData and gameData:FindFirstChild("EntityDisableScreech")
    if flag and flag:IsA("BoolValue") then
        if screechRuntime.flag ~= flag then
            screechRuntime.flag = flag
            screechRuntime.originalFlag = flag.Value
            table.insert(screechRuntime.connections,flag:GetPropertyChangedSignal("Value"):Connect(function()
                if flags.noscreech and flag.Parent and flag.Value ~= true then
                    task.defer(function()
                        if flags.noscreech and flag.Parent and flag.Value ~= true then
                            pcall(function() flag.Value = true end)
                        end
                    end)
                end
            end))
        end
        if flag.Value ~= true then
            pcall(function() flag.Value = true end)
        end
        return true
    end
    local modules = getMainGameModules()
    if not modules then return false end
    local screech = modules:FindFirstChild("Screech") or modules:FindFirstChild("Screech_Noob")
    if screech and screech.Name ~= "Screech_Noob" then
        screech.Name = "Screech_Noob"
    end
    return screech ~= nil
end
local function hookScreechRemote()
    if screechRuntime.hookedRemote then return end
    local remotes = game.ReplicatedStorage:FindFirstChild("RemotesFolder")
    local remote = remotes and remotes:FindFirstChild("Screech")
    if not (remote and remote:IsA("RemoteEvent")) then return end
    table.insert(screechRuntime.connections,remote.OnClientEvent:Connect(function()
        if flags.noscreech then
            pcall(function() remote:FireServer(true) end)
        end
    end))
    screechRuntime.hookedRemote = true
end
local function startScreechBypass()
    disconnectScreechConnections()
    screechRuntime.hookedRemote = false
    fixScreech()
    hookScreechRemote()
    local pg = plr:FindFirstChildOfClass("PlayerGui")
    if pg then
        table.insert(screechRuntime.connections,pg.DescendantAdded:Connect(function(inst)
            if flags.noscreech and (inst.Name == "Modules" or inst.Name == "Screech") then
                task.defer(fixScreech)
                task.defer(hookScreechRemote)
            end
        end))
    end
end
local function stopScreechBypass()
    local flag = screechRuntime.flag
    local original = screechRuntime.originalFlag
    disconnectScreechConnections()
    screechRuntime.hookedRemote = false
    if flag and flag.Parent and type(original) == "boolean" then
        pcall(function() flag.Value = original end)
    end
    screechRuntime.flag = nil
    screechRuntime.originalFlag = nil
end
window_misc.toggle("harmless screech",false,function(val)
    flags.noscreech = val
    if val then
        startScreechBypass()
    else
        stopScreechBypass()
    end
end)

window_misc.toggle("auto library code",false,function(val)
    flags.getcode = val
    if val then
        runtime.startFigureSolver()
    else
        runtime.stopFigureSolver()
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

window_misc.toggle("doors auto prompts",false,function(val)
    flags.autoprompts = val
    if val then
        startPromptRegistry()
    elseif not flags.itemaura and not flags.keyaura then
        stopPromptRegistry()
    end
end)

window_misc.toggle("item prompt aura",false,function(val)
    flags.itemaura = val
    if val then
        startPromptRegistry()
    elseif not flags.keyaura and not flags.autoprompts then
        stopPromptRegistry()
    end
end)

window_misc.toggle("key prompt aura",false,function(val)
    flags.keyaura = val
    if val then
        startPromptRegistry()
    elseif not flags.itemaura and not flags.autoprompts then
        stopPromptRegistry()
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

local scriptCleaned = false
local function cleanupScript()
    if scriptCleaned then
        return
    end
    scriptCleaned = true
    for k,v in pairs(DELFLAGS) do
        flags[k] = v
    end
    pcall(stopPromptRegistry)
    pcall(stopDoorReach)
    pcall(stopAntiDupe)
    pcall(stopSnareBypass)
    pcall(runtime.stopDoorOffsetReplication)
    pcall(runtime.stopLadderBypass)
    pcall(runtime.stopFigureSolver)
    pcall(stopScreechBypass)
    if rawget(scriptEnvironment,"fireproximityprompt") == runtime.customFireProximityPrompt then
        rawset(scriptEnvironment,"fireproximityprompt",runtime.originalFireProximityPrompt)
        fireproximityprompt = runtime.originalFireProximityPrompt
    end
    for _,bucket in pairs(esptable) do
        for _,visual in pairs(bucket) do
            pcall(visual.delete)
        end
        table.clear(bucket)
    end
    if char then
        char:SetAttribute("SpeedBoost",0)
    end
    rawset(scriptEnvironment,"DoorsScriptCleanup",nil)
end
rawset(scriptEnvironment,"DoorsScriptCleanup",cleanupScript)

window_misc.button("close gui",function()
    cleanupScript()
    task.wait()
    library.delete()
end)
