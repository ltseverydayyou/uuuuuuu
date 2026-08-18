local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local NetworkClient = require(ReplicatedStorage:WaitForChild("Library"):WaitForChild("Client"):WaitForChild("Network"))
local Signals = require(ReplicatedStorage:WaitForChild("Library"):WaitForChild("Signals"))
local QuickTimeEvent = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Gameplay"):WaitForChild("QuickTimeEvent"))

local LocalPlayer = Players.LocalPlayer
local NetworkFolder = ReplicatedStorage:WaitForChild("Network")
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local GameFolders = Workspace:WaitForChild("GAMEFOLDERS")
local Items = Workspace:WaitForChild("ITEMS")
local WorldParts = Workspace:WaitForChild("WORLDPARTS")
local Interactables = Workspace:WaitForChild("INTERACTABLES")

local old = getgenv().BurgerzVibeHub
local PreviousState = type(old) == "table" and old or {}
if type(old) == "table" then
    old.Running = false
end

local State = {
    Running = true,
    AutoCook = PreviousState.AutoCook == true,
    AutoCookFries = PreviousState.AutoCookFries == true,
    AutoServe = PreviousState.AutoServe == true,
    AutoCollectCash = PreviousState.AutoCollectCash == true,
    AutoKillGrind = PreviousState.AutoKillGrind == true,
    AutoKillCops = PreviousState.AutoKillCops == true,
    AutoCustomKill = PreviousState.AutoCustomKill == true,
    CustomKillQuery = type(PreviousState.CustomKillQuery) == "string" and PreviousState.CustomKillQuery or "",
    AutoClean = PreviousState.AutoClean == true,
    AutoInspectorReward = PreviousState.AutoInspectorReward == true,
    AutoTrashBadMeat = PreviousState.AutoTrashBadMeat ~= false,
    AutoHideBodies = PreviousState.AutoHideBodies ~= false,
    AutoKillBosses = PreviousState.AutoKillBosses ~= false,
    InspectorSolveUntil = 0,
    LoopDelay = tonumber(PreviousState.LoopDelay) or 0.15,
}
getgenv().BurgerzVibeHub = State

local HealthInspectorMinigameRemote = NetworkFolder:FindFirstChild("HealthInspector_Minigame")
local HealthInspectorManualActive = false
local HealthInspectorMinigameBag = {}

local HealthInspectorMinigames = {
    ShrinkRing = function(difficulty)
        local score = 0
        for _ = 1, 4 do
            QuickTimeEvent.ShrinkRingAsync({
                Position = UDim2.fromScale(math.random(20, 80) / 100, math.random(20, 80) / 100),
                Speed = difficulty * 2.6 + 2.1,
                GracePeriod = math.max(0.08, 0.18 - difficulty * 0.08),
                OnSuccess = function()
                    score += 0.25
                end,
            })
            task.wait(math.max(0.08, 0.25 - difficulty * 0.12))
        end
        return math.clamp(score, 0, 1)
    end,

    TapCircles = function(difficulty)
        return QuickTimeEvent.TapCirclesAsync({
            MinScale = 0.18,
            TotalCircles = math.floor(difficulty * 3) + 8,
            SpawnInterval = math.max(0.14, 0.32 - difficulty * 0.1),
            LifeTime = math.max(1.35, 2.2 - difficulty * 0.45),
            OuterRadius = math.max(50, 74 - difficulty * 14),
        })
    end,

    Tracking = function(difficulty)
        local score = 0
        for _ = 1, 2 do
            QuickTimeEvent.TrackingAsync({
                StartProgress = 0.28,
                Position = UDim2.fromScale(math.random(25, 75) / 100, math.random(28, 72) / 100),
                TargetSize = 122 - difficulty * 32,
                TargetSpeed = difficulty * 85 + 120,
                Gravity = difficulty * 105 + 360,
                HoldForce = difficulty * 145 + 760,
                GainRate = 0.68 - difficulty * 0.03,
                LossRate = difficulty * 0.075 + 0.095,
                TimeLimit = 6.5 - difficulty,
                OnSuccess = function()
                    score += 0.5
                end,
            })
            task.wait(math.max(0.18, 0.65 - difficulty * 0.3))
        end
        return math.clamp(score, 0, 1)
    end,

    Overlap = function(difficulty)
        local score = 0
        for _ = 1, 5 do
            QuickTimeEvent.OverlapAsync({
                Position = UDim2.fromScale(math.random(20, 80) / 100, math.random(20, 80) / 100),
                ZoneSize = 90 - difficulty * 35,
                LineSpeed = difficulty * 160 + 320,
                Duration = 5 - difficulty * 2,
                GracePeriod = math.max(0.12, 0.35 - difficulty * 0.15),
                OnSuccess = function()
                    score += 0.2
                end,
            })
            task.wait(math.max(0.18, 0.7 - difficulty * 0.35))
        end
        return math.clamp(score, 0, 1)
    end,
}

local HealthInspectorMinigameNames = { "ShrinkRing", "TapCircles", "Tracking", "Overlap" }

local function refillHealthInspectorMinigameBag()
    table.clear(HealthInspectorMinigameBag)
    for _, name in ipairs(HealthInspectorMinigameNames) do
        table.insert(HealthInspectorMinigameBag, name)
    end
    for i = #HealthInspectorMinigameBag, 2, -1 do
        local j = math.random(1, i)
        HealthInspectorMinigameBag[i], HealthInspectorMinigameBag[j] = HealthInspectorMinigameBag[j], HealthInspectorMinigameBag[i]
    end
end

local function getHealthInspectorMinigame(name)
    if type(name) == "string" and HealthInspectorMinigames[name] then
        return HealthInspectorMinigames[name]
    end
    if #HealthInspectorMinigameBag == 0 then
        refillHealthInspectorMinigameBag()
    end
    local randomName = table.remove(HealthInspectorMinigameBag)
    return HealthInspectorMinigames[randomName]
end

local function runManualHealthInspectorMinigame(difficulty, minigameName)
    if HealthInspectorManualActive then
        return 0
    end

    HealthInspectorManualActive = true
    local amount = math.clamp(tonumber(difficulty) or 0, 0, 1)
    local run = getHealthInspectorMinigame(minigameName)
    Signals.Fire("ShowMouseIcon", "HealthInspectorMinigame")
    local ok, result = pcall(run, amount)
    Signals.Fire("HideMouseIcon", "HealthInspectorMinigame")
    HealthInspectorManualActive = false

    if ok then
        return tonumber(result) or 0
    end

    warn("[Burgerz Hub] Health Inspector minigame error:", result)
    return 0
end

local function healthInspectorMinigameHandler(difficulty, minigameName)
    local hub = getgenv().BurgerzVibeHub
    if type(hub) == "table" and hub.Running then
        local solveUntil = tonumber(hub.InspectorSolveUntil) or 0
        if hub.AutoClean or os.clock() < solveUntil then
            return 1
        end
    end

    return runManualHealthInspectorMinigame(difficulty, minigameName)
end

local function installHealthInspectorMinigameSolver()
    if HealthInspectorMinigameRemote and HealthInspectorMinigameRemote:IsA("RemoteFunction") then
        HealthInspectorMinigameRemote.OnClientInvoke = healthInspectorMinigameHandler
    end
end

installHealthInspectorMinigameSolver()

local function safeWait(seconds)
    local deadline = os.clock() + seconds
    repeat
        task.wait(math.min(0.05, seconds))
    until not State.Running or os.clock() >= deadline
end

local function fireNetwork(name, ...)
    local remote = NetworkFolder:FindFirstChild(name)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(...)
        return true
    end
    return false
end

local function fireNetworkAny(name, ...)
    if fireNetwork(name, ...) then
        return true
    end
    local ok = pcall(NetworkClient.Fire, name, ...)
    return ok
end

local function invokeNetwork(name, ...)
    local remote = NetworkFolder:FindFirstChild(name)
    if remote and remote:IsA("RemoteFunction") then
        return pcall(remote.InvokeServer, remote, ...)
    end
    return false, nil
end

local function fireRemote(name, ...)
    local remote = RemotesFolder:FindFirstChild(name)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(...)
        return true
    end
    return false
end

local function getHumanoidModelPart(model)
    if not model or not model:IsA("Model") then
        return nil, nil
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return humanoid, nil
    end
    return humanoid,
        model:FindFirstChild("BodyHitbox")
        or model:FindFirstChild("HeadHitbox")
        or model:FindFirstChild("Head")
        or model:FindFirstChild("Torso")
        or model.PrimaryPart
end

local function hitModel(model)
    local humanoid, part = getHumanoidModelPart(model)
    if not humanoid or not part then
        return false
    end
    fireNetwork("MeleeHitEvent", part, part.Position, Vector3.yAxis, 26)
    return true
end

local function killModel(model)
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return false
    end
    local deadline = os.clock() + 3
    while State.Running and model.Parent and humanoid.Health > 0 and os.clock() < deadline do
        if not hitModel(model) then
            break
        end
        safeWait(math.max(State.LoopDelay, 0.08))
    end
    return humanoid.Health <= 0
end

local function isBadMeat(meat)
    if not meat or not meat:IsA("Model") then
        return true
    end
    return meat:GetAttribute("Infested") == true or meat:GetAttribute("MeatState") == "Overcooked"
end

local TrashBusy = {}

local function trashMeat(meat)
    if not meat or not meat.Parent or not meat:IsA("Model") or TrashBusy[meat] then
        return false
    end
    if not isBadMeat(meat) then
        return false
    end
    local trashCan = WorldParts:FindFirstChild("TrashCan")
    local touchPart = trashCan and trashCan:FindFirstChild("TouchPart")
    if not touchPart or not touchPart:IsA("BasePart") or not meat.PrimaryPart then
        return false
    end

    TrashBusy[meat] = true
    local ok = pcall(function()
        fireNetworkAny("PickupItem", meat)
        safeWait(0.12)
        if meat.Parent and meat.PrimaryPart then
            meat:PivotTo(touchPart.CFrame)
            meat.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
            if type(firetouchinterest) == "function" then
                pcall(firetouchinterest, meat.PrimaryPart, touchPart, 0)
                pcall(firetouchinterest, meat.PrimaryPart, touchPart, 1)
            end
        end
        safeWait(0.08)
        if meat.Parent then
            fireNetworkAny("DropItem", meat, Vector3.zero)
        end
        safeWait(0.18)
    end)
    TrashBusy[meat] = nil
    return ok and meat.Parent == nil
end

local function trashBadMeatPass()
    local folder = Items:FindFirstChild("Meat")
    if not folder then
        return 0
    end
    local removed = 0
    for _, meat in ipairs(folder:GetChildren()) do
        if not State.Running then
            break
        end
        if meat:IsA("Model") and isBadMeat(meat) and trashMeat(meat) then
            removed += 1
        end
    end
    return removed
end

local function cookMeat(meat)
    if not meat or not meat:IsA("Model") or not meat:IsDescendantOf(Workspace) or isBadMeat(meat) then
        return false
    end
    local state = meat:GetAttribute("MeatState")
    if state == "Cooked" then
        return true
    end
    if state == "Overcooked" then
        return false
    end
    for _ = 1, 3 do
        fireNetwork("AddTimeToMeat", meat, 10)
        safeWait(0.08)
        state = meat:GetAttribute("MeatState")
        if state == "Cooked" then
            return true
        elseif state == "Overcooked" then
            return false
        end
    end
    return meat:GetAttribute("MeatState") == "Cooked"
end

local function cookAllMeat()
    local folder = Items:FindFirstChild("Meat")
    if not folder then
        return
    end
    for _, meat in ipairs(folder:GetChildren()) do
        if not State.Running then
            return
        end
        if meat:IsA("Model") then
            cookMeat(meat)
        end
    end
end

local function cookAllFries()
    local remote = NetworkFolder:FindFirstChild("AddTimeToFries")
    if not remote then
        return
    end
    for _, obj in ipairs(Items:GetDescendants()) do
        if not State.Running then
            return
        end
        if obj:IsA("Model") and obj.Name == "Fries" then
            local fryState = obj:GetAttribute("FryState")
            if fryState ~= "Cooked" and fryState ~= "Overcooked" then
                remote:FireServer(obj, 10)
            end
        end
    end
end

local function getSack()
    local character = LocalPlayer.Character
    return (character and character:FindFirstChild("Sack")) or LocalPlayer.Backpack:FindFirstChild("Sack")
end

local function unloadSackAtGrinder()
    local sack = getSack()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local harvest = WorldParts:FindFirstChild("Harvest") and WorldParts.Harvest:FindFirstChild("HarvestPart")
    if not sack or not hrp or not harvest then
        return false
    end

    local amount = sack:GetAttribute("StoringAmount") or 0
    if amount <= 0 then
        return true
    end

    local oldCFrame = hrp.CFrame
    hrp.CFrame = harvest.CFrame * CFrame.new(0, 0, -1)
    safeWait(0.15)

    local guard = 0
    while State.Running and (sack:GetAttribute("StoringAmount") or 0) > 0 and guard < 10 do
        guard += 1
        fireNetwork("UnstoreFromSack", sack)
        safeWait(0.35)
    end

    if hrp.Parent then
        hrp.CFrame = oldCFrame
    end
    return true
end

local function storeCorpse(body)
    local sack = getSack()
    if not sack or not body or not body.Parent then
        return false
    end

    if (sack:GetAttribute("StoringAmount") or 0) >= (sack:GetAttribute("StoreCapacity") or math.huge) then
        unloadSackAtGrinder()
    end

    local before = sack:GetAttribute("StoringAmount") or 0
    safeWait(0.25)
    for _ = 1, 7 do
        if not State.Running or not body.Parent then
            break
        end
        fireNetwork("StoreInSack", sack, body)
        safeWait(0.25)
        if (sack:GetAttribute("StoringAmount") or 0) > before then
            return true
        end
    end

    return (sack:GetAttribute("StoringAmount") or 0) > before
end

local CorpseBusy = {}

local function getDeadFolders()
    local folders = {}
    local customers = GameFolders:FindFirstChild("Customers")
    local customerDead = customers and customers:FindFirstChild("Dead")
    if customerDead then
        table.insert(folders, customerDead)
    end
    local npcs = GameFolders:FindFirstChild("NPCs")
    local npcDead = npcs and npcs:FindFirstChild("Dead")
    if npcDead then
        table.insert(folders, npcDead)
    end
    return folders
end

local function hideExistingCorpses(grindAfter)
    local handled = false
    for _, dead in ipairs(getDeadFolders()) do
        for _, body in ipairs(dead:GetChildren()) do
            if not State.Running then
                break
            end
            if body:IsA("Model") and body:FindFirstChildOfClass("Humanoid") and not CorpseBusy[body] then
                CorpseBusy[body] = true
                local stored = storeCorpse(body)
                CorpseBusy[body] = nil
                if stored then
                    handled = true
                end
            end
        end
    end

    local sack = getSack()
    if grindAfter and sack and (sack:GetAttribute("StoringAmount") or 0) > 0 then
        unloadSackAtGrinder()
        handled = true
    end
    return handled
end

local function grindExistingCorpses()
    return hideExistingCorpses(true)
end

local function killAndGrindOneCustomer()
    local customers = GameFolders:FindFirstChild("Customers")
    local alive = customers and customers:FindFirstChild("Alive")
    local dead = customers and customers:FindFirstChild("Dead")
    if not alive or not dead then
        return false
    end

    if #dead:GetChildren() > 0 or (getSack() and (getSack():GetAttribute("StoringAmount") or 0) > 0) then
        if grindExistingCorpses() then
            return true
        end
    end

    local target
    for _, model in ipairs(alive:GetChildren()) do
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 and not model:GetAttribute("Non_Killable") then
            target = model
            break
        end
    end
    if not target then
        if (getSack() and (getSack():GetAttribute("StoringAmount") or 0) > 0) then
            unloadSackAtGrinder()
        end
        return false
    end

    killModel(target)
    local deadline = os.clock() + 2
    repeat
        safeWait(0.05)
    until not State.Running or target.Parent == dead or os.clock() >= deadline

    if target.Parent == dead and storeCorpse(target) then
        unloadSackAtGrinder()
        return true
    end
    return false
end

local function isInDeadFolder(instance)
    local current = instance
    while current and current ~= Workspace do
        if current.Name == "Dead" then
            return true
        end
        current = current.Parent
    end
    return false
end

local RaidNpcNames = {
    revolver = true,
    shotgun = true,
    armoredshotgun = true,
    fbi = true,
    swat = true,
    sniper = true,
    riotshield = true,
    cop = true,
    copwitharmor = true,
    searchcop = true,
    undercovercopnormal = true,
}

local function isRaidNpcModel(model)
    if not model or not model:IsA("Model") then
        return false
    end
    local compactName = string.lower(model.Name):gsub("[%s_%-%.]", "")
    return RaidNpcNames[compactName] == true
        or compactName:find("swat", 1, true) ~= nil
        or compactName:find("riotshield", 1, true) ~= nil
end

local function getLiveRaidModels()
    local npcs = GameFolders:FindFirstChild("NPCs")
    if not npcs then
        return {}
    end

    local results = {}
    local seen = {}
    for _, descendant in ipairs(npcs:GetDescendants()) do
        if descendant:IsA("Humanoid") and descendant.Health > 0 then
            local model = descendant.Parent
            if model
                and model:IsA("Model")
                and not seen[model]
                and not isInDeadFolder(model)
                and not model:GetAttribute("Non_Killable")
                and isRaidNpcModel(model)
            then
                seen[model] = true
                table.insert(results, model)
            end
        end
    end
    return results
end

local function killCopsPass(force)
    for _, model in ipairs(getLiveRaidModels()) do
        if not State.Running or (not force and not State.AutoKillCops) then
            return
        end
        hitModel(model)
    end
end

local function getBossHitPart(model)
    if not model or not model:IsA("Model") then
        return nil
    end
    return model:FindFirstChild("BodyHitbox", true)
        or model:FindFirstChild("HeadHitbox", true)
        or model:FindFirstChild("HumanoidRootPart", true)
        or model:FindFirstChild("Main", true)
        or model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart", true)
end

local function isBossModel(model)
    if not model or not model:IsA("Model") or isInDeadFolder(model) then
        return false
    end
    local compactName = string.lower(model.Name):gsub("[%s_%-%.]", "")
    if compactName:find("tank", 1, true) or compactName:find("boss", 1, true) or compactName:find("giantrat", 1, true) then
        return true
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 and (compactName == "rat" or model:GetAttribute("Type") == "Rat") then
        if humanoid.MaxHealth > 25 then
            return true
        end
        local ok, size = pcall(function()
            return model:GetExtentsSize()
        end)
        if ok and size.Magnitude > 12 then
            return true
        end
    end
    return false
end

local function getLiveBossModels()
    local results = {}
    local seen = {}

    local function consider(model)
        if not model or seen[model] or not model:IsA("Model") then
            return
        end
        if isBossModel(model) then
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health > 0 then
                seen[model] = true
                table.insert(results, model)
            end
        end
    end

    for _, child in ipairs(Workspace:GetChildren()) do
        consider(child)
    end

    local npcs = GameFolders:FindFirstChild("NPCs")
    if npcs then
        for _, descendant in ipairs(npcs:GetDescendants()) do
            if descendant:IsA("Model") then
                consider(descendant)
            end
        end
    end

    local customers = GameFolders:FindFirstChild("Customers")
    local aliveCustomers = customers and customers:FindFirstChild("Alive")
    if aliveCustomers then
        for _, child in ipairs(aliveCustomers:GetChildren()) do
            consider(child)
        end
    end

    local events = Interactables:FindFirstChild("Events")
    if events then
        for _, descendant in ipairs(events:GetDescendants()) do
            if descendant:IsA("Model") then
                consider(descendant)
            end
        end
    end

    return results
end

local function hitBoss(model)
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        return hitModel(model)
    end
    local part = getBossHitPart(model)
    if not part or not part:IsA("BasePart") then
        return false
    end
    return fireNetworkAny("MeleeHitEvent", part, part.Position, Vector3.yAxis, 26)
end

local BossBusy = {}

local function attackBossUntilDead(model, force)
    if not model or BossBusy[model] then
        return false
    end

    BossBusy[model] = true
    task.spawn(function()
        local deadline = os.clock() + 30
        while State.Running
            and model.Parent
            and (force or State.AutoKillBosses)
            and os.clock() < deadline do

            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health <= 0 then
                break
            end

            if not hitBoss(model) then
                break
            end

            safeWait(math.max(State.LoopDelay, 0.08))
        end
        BossBusy[model] = nil
    end)

    return true
end

local function killBossesPass(force)
    local foundAny = false
    for _, model in ipairs(getLiveBossModels()) do
        if not State.Running or (not force and not State.AutoKillBosses) then
            return foundAny
        end
        if attackBossUntilDead(model, force) then
            foundAny = true
        end
    end
    return foundAny
end

local function customKillPass(force)
    local query = string.lower(State.CustomKillQuery or "")
    if query == "" then
        return false
    end

    local hitAny = false
    local seen = {}
    for _, descendant in ipairs(GameFolders:GetDescendants()) do
        if not State.Running or (not force and not State.AutoCustomKill) then
            return hitAny
        end
        if descendant:IsA("Humanoid") and descendant.Health > 0 then
            local model = descendant.Parent
            if model
                and model:IsA("Model")
                and not seen[model]
                and not isInDeadFolder(model)
                and model ~= LocalPlayer.Character
                and not model:GetAttribute("Non_Killable")
                and string.find(string.lower(model.Name), query, 1, true)
            then
                seen[model] = true
                hitModel(model)
                hitAny = true
            end
        end
    end
    return hitAny
end

local unsupportedOrderIngredients = {
    FriesCup = true,
    Fries = true,
    DrinkCup = true,
    Ice = true,
    Soda = true,
    DrinkLid = true,
}

local function requestOrderBoard()
    local ok, board = invokeNetwork("RequestOrderBoard")
    if ok and type(board) == "table" then
        return board
    end
    return {}
end

local function isSimpleBurgerOrder(order)
    if type(order) ~= "table" or type(order.OrderTable) ~= "table" then
        return false
    end
    local hasPlate = false
    for _, ingredient in ipairs(order.OrderTable) do
        if ingredient == "Plate" then
            hasPlate = true
        elseif unsupportedOrderIngredients[ingredient] then
            return false
        end
    end
    return hasPlate
end

local function hasUsableMeat()
    local folder = Items:FindFirstChild("Meat")
    if not folder then
        return false
    end
    for _, meat in ipairs(folder:GetChildren()) do
        if meat:IsA("Model") and not isBadMeat(meat) then
            local restricted = meat:GetAttribute("PlayerRestricted")
            if restricted == nil or restricted == LocalPlayer.Name then
                return true
            end
        end
    end
    return false
end

local function canSourceIngredient(ingredient)
    if ingredient == "Plate" then
        local stands = WorldParts:FindFirstChild("EndlessFoodStands")
        return stands and stands:FindFirstChild("EndlessPlateGrab") ~= nil
    end
    if ingredient == "Meat" then
        return hasUsableMeat()
    end
    if unsupportedOrderIngredients[ingredient] then
        return false
    end
    local stands = WorldParts:FindFirstChild("EndlessFoodStands")
    return stands and stands:FindFirstChild("Endless" .. ingredient:gsub("%s+", "") .. "Grab") ~= nil
end

local function canCompleteOrder(order)
    if not isSimpleBurgerOrder(order) then
        return false
    end
    for _, ingredient in ipairs(order.OrderTable) do
        if not canSourceIngredient(ingredient) then
            return false
        end
    end
    return true
end

local function findOrderById(board, orderId)
    for _, order in ipairs(board) do
        if order.OrderID == orderId then
            return order
        end
    end
end

local function claimBurgerOrder()
    local current = LocalPlayer:GetAttribute("CurrentOrderID")
    local board = requestOrderBoard()
    if current then
        local currentOrder = findOrderById(board, current)
        if currentOrder and canCompleteOrder(currentOrder) then
            return currentOrder
        end
        fireNetwork("UnlinkPlayerFromOrder", current)
        local deadline = os.clock() + 0.75
        repeat
            safeWait(0.05)
        until not State.Running or LocalPlayer:GetAttribute("CurrentOrderID") == nil or os.clock() >= deadline
        return nil
    end

    for _, order in ipairs(board) do
        if canCompleteOrder(order) then
            local playersWorking = order.PlayersWorking
            local employeesWorking = order.EmployeesWorking
            if (type(playersWorking) ~= "table" or #playersWorking == 0)
                and (type(employeesWorking) ~= "table" or #employeesWorking == 0) then
                fireNetwork("LinkPlayerToOrder", order.OrderID)
                local deadline = os.clock() + 1
                repeat
                    safeWait(0.05)
                    if LocalPlayer:GetAttribute("CurrentOrderID") == order.OrderID then
                        return order
                    end
                until not State.Running or os.clock() >= deadline
            end
        end
    end
end

local function findServePart(customerPart)
    if typeof(customerPart) ~= "Instance" then
        return nil
    end
    local customer = customerPart.Parent
    if not customer then
        return nil
    end
    local seats = WorldParts:FindFirstChild("CustomerSeats")
    if not seats then
        return nil
    end
    for _, seatFolder in ipairs(seats:GetChildren()) do
        for _, spot in ipairs(seatFolder:GetChildren()) do
            local seat = spot:FindFirstChild("Seat")
            if seat and seat:IsA("Seat") and seat.Occupant and seat.Occupant.Parent == customer then
                return spot:FindFirstChild("ServePart")
            end
        end
    end
end

local function snapshotModels()
    local set = {}
    for _, obj in ipairs(Items:GetDescendants()) do
        if obj:IsA("Model") then
            set[obj] = true
        end
    end
    return set
end

local function waitForNewItem(name, before, timeout)
    local deadline = os.clock() + timeout
    repeat
        for _, obj in ipairs(Items:GetDescendants()) do
            if obj:IsA("Model") and obj.Name == name and not before[obj] then
                local restricted = obj:GetAttribute("PlayerRestricted")
                if restricted == nil or restricted == LocalPlayer.Name then
                    return obj
                end
            end
        end
        safeWait(0.04)
    until not State.Running or os.clock() >= deadline
end

local function spawnStandItem(ingredient)
    local stands = WorldParts:FindFirstChild("EndlessFoodStands")
    if not stands then
        return nil
    end
    local stand = stands:FindFirstChild("Endless" .. ingredient:gsub("%s+", "") .. "Grab")
    if not stand then
        return nil
    end
    local before = snapshotModels()
    fireRemote("SpecialCall", stand)
    return waitForNewItem(ingredient, before, 1.25)
end

local function findCookableMeat()
    local meatFolder = Items:FindFirstChild("Meat")
    if not meatFolder then
        return nil
    end
    for _, meat in ipairs(meatFolder:GetChildren()) do
        if meat:IsA("Model") and not isBadMeat(meat) then
            local restricted = meat:GetAttribute("PlayerRestricted")
            if restricted == nil or restricted == LocalPlayer.Name then
                if cookMeat(meat) and not isBadMeat(meat) then
                    fireRemote("PickupItem", meat)
                    safeWait(0.12)
                    return meat
                end
            end
        end
    end
end

local function countPlateIngredient(plate, ingredient)
    local count = 0
    for _, child in ipairs(plate:GetChildren()) do
        if child.Name == ingredient then
            count += 1
        end
    end
    return count
end

local function waitIngredientAttached(plate, item, ingredient, beforeCount, timeout)
    local deadline = os.clock() + timeout
    repeat
        if not plate.Parent then
            return false
        end
        if countPlateIngredient(plate, ingredient) > beforeCount then
            return true
        end
        if not item.Parent or item.Parent == plate then
            return true
        end
        safeWait(0.04)
    until not State.Running or os.clock() >= deadline
    return plate.Parent ~= nil and countPlateIngredient(plate, ingredient) > beforeCount
end

local function addIngredient(plate, ingredient)
    local item
    if ingredient == "Meat" then
        item = findCookableMeat()
    else
        item = spawnStandItem(ingredient)
    end
    if not item then
        return false
    end
    local beforeCount = countPlateIngredient(plate, ingredient)
    fireNetwork("TryAddIngredientToPlate", plate, item)
    return waitIngredientAttached(plate, item, ingredient, beforeCount, 1)
end

local function servePlate(plate, order)
    local servePart = findServePart(order.CustomerPart)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not plate or not plate.PrimaryPart or not servePart or not hrp then
        return false
    end

    local oldCFrame = hrp.CFrame
    hrp.CFrame = plate.PrimaryPart.CFrame * CFrame.new(0, 0, 3)
    safeWait(0.1)
    fireRemote("PickupItem", plate)
    safeWait(0.12)

    hrp.CFrame = servePart.CFrame * CFrame.new(0, 0, 3)
    plate:PivotTo(servePart.CFrame * CFrame.new(0, 1.1, 0))
    if plate.PrimaryPart then
        plate.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
        if type(firetouchinterest) == "function" then
            pcall(firetouchinterest, plate.PrimaryPart, servePart, 0)
            pcall(firetouchinterest, plate.PrimaryPart, servePart, 1)
        end
    end
    safeWait(0.1)
    fireRemote("DropItem", plate, Vector3.zero)
    safeWait(0.6)

    if hrp.Parent then
        hrp.CFrame = oldCFrame
    end
    return true
end

local collectCashPass

local function autoServeOneOrder()
    if LocalPlayer:GetAttribute("CurrentOrderID") then
        local board = requestOrderBoard()
        if not findOrderById(board, LocalPlayer:GetAttribute("CurrentOrderID")) then
            return false
        end
    end

    local order = claimBurgerOrder()
    if not order or not isSimpleBurgerOrder(order) then
        return false
    end

    local plate = spawnStandItem("Plate")
    if not plate then
        return false
    end

    for _, ingredient in ipairs(order.OrderTable) do
        if not State.Running or not State.AutoServe then
            return false
        end
        if ingredient ~= "Plate" then
            if not addIngredient(plate, ingredient) then
                return false
            end
        end
    end

    safeWait(0.15)
    local served = servePlate(plate, order)
    if served then
        task.delay(0.75, function()
            if State.Running then
                pcall(collectCashPass)
            end
        end)
    end
    return served
end

local CashCollecting = {}

collectCashPass = function()
    local collected = 0
    for _, item in ipairs(Items:GetChildren()) do
        local dropId = item:GetAttribute("DropId")
        if dropId ~= nil and not CashCollecting[dropId] then
            CashCollecting[dropId] = true
            if fireNetwork("AddMoney", dropId) then
                collected += 1
            end
            task.delay(0.75, function()
                CashCollecting[dropId] = nil
            end)
            safeWait(0.03)
        end
    end
    return collected
end

local function cleanInspectorPass(forceSolve)
    local events = Interactables:FindFirstChild("Events")
    local inspector = events and events:FindFirstChild("HealthInspector")
    if not inspector or type(fireproximityprompt) ~= "function" then
        return
    end

    if forceSolve then
        State.InspectorSolveUntil = os.clock() + 8
    end

    installHealthInspectorMinigameSolver()

    for _, obj in ipairs(inspector:GetChildren()) do
        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and prompt.Enabled then
            pcall(fireproximityprompt, prompt)
            safeWait(0.18)
        end
    end
end

local function claimInspectorReward()
    local invoke = NetworkFolder:FindFirstChild("HealthInspector_ClaimRewards_Invoke")
    if invoke and invoke:IsA("RemoteFunction") then
        pcall(invoke.InvokeServer, invoke)
    end
    fireNetwork("HealthInspector_ClaimRewards")
end

task.spawn(function()
    while State.Running do
        if State.AutoTrashBadMeat then
            trashBadMeatPass()
        end
        if State.AutoCook then
            cookAllMeat()
        end
        if State.AutoCookFries then
            cookAllFries()
        end
        if State.AutoClean then
            cleanInspectorPass()
        end
        safeWait(0.2)
    end
end)

task.spawn(function()
    while State.Running do
        if State.AutoKillCops then
            killCopsPass(false)
        end
        if State.AutoKillBosses then
            killBossesPass(false)
        end
        if State.AutoCustomKill then
            customKillPass(false)
        end
        safeWait(math.max(State.LoopDelay, 0.1))
    end
end)

task.spawn(function()
    while State.Running do
        if State.AutoHideBodies then
            hideExistingCorpses(true)
        end
        safeWait(0.12)
    end
end)

task.spawn(function()
    while State.Running do
        if State.AutoKillGrind then
            killAndGrindOneCustomer()
        end
        safeWait(0.25)
    end
end)

task.spawn(function()
    while State.Running do
        if State.AutoServe then
            pcall(autoServeOneOrder)
        end
        safeWait(0.65)
    end
end)

task.spawn(function()
    while State.Running do
        if State.AutoCollectCash or State.AutoServe then
            pcall(collectCashPass)
        end
        safeWait(0.15)
    end
end)

task.spawn(function()
    while State.Running do
        if State.AutoInspectorReward then
            claimInspectorReward()
        end
        safeWait(3)
    end
end)

local VibeUI = loadstring(game:HttpGet("https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"))()
local Window = VibeUI:Window({
    Title = "Burgerz Hub",
    Size = UDim2.fromOffset(760, 540),
    Keybind = Enum.KeyCode.RightControl,
})

local AutomationTab = Window:Tab({ Name = "Automation", Columns = 2 })
local Kitchen = AutomationTab:Section({ Name = "Kitchen", Side = 1 })
local Customers = AutomationTab:Section({ Name = "Customers", Side = 2 })

Kitchen:Toggle({
    Name = "Auto Cook Patties",
    Flag = "BurgerzAutoCook",
    Default = State.AutoCook,
    Callback = function(value)
        State.AutoCook = value
    end,
})

Kitchen:Toggle({
    Name = "Auto Cook Fries",
    Flag = "BurgerzAutoCookFries",
    Default = State.AutoCookFries,
    Callback = function(value)
        State.AutoCookFries = value
    end,
})

Kitchen:Toggle({
    Name = "Auto Trash Bad Meat",
    Flag = "BurgerzAutoTrashBadMeat",
    Default = State.AutoTrashBadMeat,
    Info = "Immediately trashes bug-infested or overcooked patties and prevents them from being served.",
    Callback = function(value)
        State.AutoTrashBadMeat = value
        if value then
            task.spawn(trashBadMeatPass)
        end
    end,
})

Kitchen:Toggle({
    Name = "Auto Serve Burger Orders",
    Flag = "BurgerzAutoServe",
    Default = State.AutoServe,
    Info = "Claims and completes plate-based burger orders automatically.",
    Callback = function(value)
        State.AutoServe = value
    end,
})

local kitchenButtons = Kitchen:Button()
kitchenButtons:Add("Cook All Now", function()
    cookAllMeat()
    cookAllFries()
end)
kitchenButtons:Add("Trash Bad Meat", trashBadMeatPass)

Customers:Toggle({
    Name = "Auto Kill + Grind Customers",
    Flag = "BurgerzAutoKillGrind",
    Default = State.AutoKillGrind,
    Info = "Kills customers, stores corpses in the Sack, then unloads them into the grinder.",
    Callback = function(value)
        State.AutoKillGrind = value
    end,
})

Customers:Toggle({
    Name = "Auto Hide + Grind Bodies",
    Flag = "BurgerzAutoHideBodies",
    Default = State.AutoHideBodies,
    Info = "Immediately sacks exposed customer/NPC corpses and drains the Sack through the grinder so police searches cannot find bodies.",
    Callback = function(value)
        State.AutoHideBodies = value
        if value then
            task.spawn(function()
                hideExistingCorpses(true)
            end)
        end
    end,
})

Customers:Toggle({
    Name = "Auto Collect Cash + Tips",
    Flag = "BurgerzAutoCollectCash",
    Default = State.AutoCollectCash,
    Info = "Collects customer Bill, Gold, Diamond and Special payment drops. Auto Serve also collects them automatically.",
    Callback = function(value)
        State.AutoCollectCash = value
        if value then
            task.spawn(collectCashPass)
        end
    end,
})

local customerButtons = Customers:Button()
customerButtons:Add("Collect Cash Now", collectCashPass)
customerButtons:Add("Hide Bodies Now", function()
    hideExistingCorpses(true)
end)

Customers:Slider({
    Name = "Attack Delay",
    Flag = "BurgerzAttackDelay",
    Min = 0.08,
    Max = 1,
    Default = State.LoopDelay,
    Decimals = 0.01,
    Suffix = "s",
    Callback = function(value)
        State.LoopDelay = value
    end,
})

local CombatTab = Window:Tab({ Name = "Combat", Columns = 2 })
local Combat = CombatTab:Section({ Name = "Raid Automation", Side = 1 })
local CustomCombat = CombatTab:Section({ Name = "Custom Kill", Side = 2 })

Combat:Toggle({
    Name = "Auto Kill Raid NPCs",
    Flag = "BurgerzAutoKillCops",
    Default = State.AutoKillCops,
    Info = "Targets every live hostile raid NPC under GAMEFOLDERS.NPCs, including SWAT, FBI and RIOTSHIELD.",
    Callback = function(value)
        State.AutoKillCops = value
    end,
})

Combat:Toggle({
    Name = "Auto Kill Bosses",
    Flag = "BurgerzAutoKillBosses",
    Default = State.AutoKillBosses,
    Info = "Continuously kills TankBoss, Giant Rat and other obvious live bosses, including event bosses under INTERACTABLES.Events. Normal 25 HP rats are ignored.",
    Callback = function(value)
        State.AutoKillBosses = value
    end,
})

local raidButtons = Combat:Button()
raidButtons:Add("Kill Raid NPCs Now", function()
    killCopsPass(true)
end)
raidButtons:Add("Kill Bosses Now", function()
    killBossesPass(true)
end)

CustomCombat:Textbox({
    Name = "Target Name",
    Flag = "BurgerzCustomKillQuery",
    Placeholder = "FBI / SWAT / RIOTSHIELD / customer name",
    Default = State.CustomKillQuery,
    Finished = true,
    Callback = function(value)
        State.CustomKillQuery = tostring(value or "")
    end,
})

CustomCombat:Toggle({
    Name = "Auto Kill Matching Target",
    Flag = "BurgerzAutoCustomKill",
    Default = State.AutoCustomKill,
    Info = "Case-insensitive name substring match across live humanoid models in GAMEFOLDERS.",
    Callback = function(value)
        State.AutoCustomKill = value
    end,
})

local customButtons = CustomCombat:Button()
customButtons:Add("Kill Matching Now", function()
    customKillPass(true)
end)

local EventsTab = Window:Tab({ Name = "Events", Columns = 2 })
local Inspector = EventsTab:Section({ Name = "Health Inspector", Side = 1 })
local Utility = EventsTab:Section({ Name = "Utility", Side = 2 })

Inspector:Toggle({
    Name = "Auto Clean Restaurant",
    Flag = "BurgerzAutoClean",
    Default = State.AutoClean,
    Info = "Cleans every inspection spot and auto-completes ShrinkRing, TapCircles, Tracking and Overlap QTEs with a perfect score.",
    Callback = function(value)
        State.AutoClean = value
    end,
})

Inspector:Toggle({
    Name = "Auto Claim Inspector Reward",
    Flag = "BurgerzAutoInspectorReward",
    Default = State.AutoInspectorReward,
    Callback = function(value)
        State.AutoInspectorReward = value
    end,
})

local inspectorButtons = Inspector:Button()
inspectorButtons:Add("Clean Now", function()
    cleanInspectorPass(true)
end)
inspectorButtons:Add("Claim Reward", claimInspectorReward)

local utilityButtons = Utility:Button()
utilityButtons:Add("Grind Sack Now", unloadSackAtGrinder)
utilityButtons:Add("Stop Hub", function()
    State.Running = false
    State.AutoCook = false
    State.AutoCookFries = false
    State.AutoServe = false
    State.AutoCollectCash = false
    State.AutoKillGrind = false
    State.AutoKillCops = false
    State.AutoCustomKill = false
    State.AutoClean = false
    State.AutoInspectorReward = false
    State.AutoTrashBadMeat = false
    State.AutoHideBodies = false
    State.AutoKillBosses = false
    State.InspectorSolveUntil = 0

    if HealthInspectorMinigameRemote and HealthInspectorMinigameRemote:IsA("RemoteFunction") then
        HealthInspectorMinigameRemote.OnClientInvoke = runManualHealthInspectorMinigame
    end
end)
