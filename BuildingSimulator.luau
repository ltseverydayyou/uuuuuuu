local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local Blueprints = ReplicatedStorage:WaitForChild("Blueprints")
local Tools = ReplicatedStorage:WaitForChild("Tools")
local Helpers = ReplicatedStorage:WaitForChild("Helpers")
local Values = ReplicatedStorage:WaitForChild("Values")
local Functions = ReplicatedStorage:WaitForChild("Functions")
local IDs = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("IDs"))
local GetModelBoundaryPart = require(Functions:WaitForChild("GetModelBoundaryPart"))
local GetRebirthPrice = require(Functions:WaitForChild("getRebirthPrice"))
local round = require(Functions:WaitForChild("round"))
local Data = LocalPlayer:WaitForChild("PlayerDataFolder")
local Builds = Workspace:WaitForChild("Builds")
local IdleBuilds = Workspace:WaitForChild("IdleBuilds")
local Baseplates = Workspace:WaitForChild("MapBuild"):WaitForChild("Baseplates")

local VIBE_URL = "https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"

local previous = getgenv().BuildingSimFarm
local previousStates = previous and previous.States

if previous and type(previous.Stop) == "function" then
    pcall(previous.Stop)
end

local legacyMobileButton = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("BuildingSimFarmMobile")
if legacyMobileButton then
    legacyMobileButton:Destroy()
end

local function prior(name, default)
    if previousStates and previousStates[name] ~= nil then
        return previousStates[name]
    end
    return default
end

local States = {
    AutoBuild = prior("AutoBuild", true),
    InstantBuild = prior("InstantBuild", true),
    HitDelay = math.clamp(tonumber(prior("HitDelay", 0.02)) or 0.02, 0.01, 0.2),
    AutoPlace = prior("AutoPlace", true),
    PlacementCooldown = math.clamp(tonumber(prior("PlacementCooldown", 0.75)) or 0.75, 0.25, 3),
    PlacementTimeout = math.clamp(tonumber(prior("PlacementTimeout", 5)) or 5, 2, 15),
    MaxPlacementChecks = math.clamp(math.floor(tonumber(prior("MaxPlacementChecks", 48)) or 48), 12, 144),
    AutoUnlock = prior("AutoUnlock", true),
    AutoTools = prior("AutoTools", true),
    AutoBuyHelpers = prior("AutoBuyHelpers", false),
    AutoEquipHelpers = prior("AutoEquipHelpers", true),
    AutoLevelHelpers = prior("AutoLevelHelpers", false),
    HelperTargetCount = math.clamp(math.floor(tonumber(prior("HelperTargetCount", 4)) or 4), 1, 12),
    AutoRebirth = prior("AutoRebirth", false),
    RebirthPercent = math.clamp(tonumber(prior("RebirthPercent", 115)) or 115, 100, 250),
    AutoIdleBuilds = prior("AutoIdleBuilds", false),
    AutoTurnGold = prior("AutoTurnGold", true),
    BuildStrategy = prior("BuildStrategy", "Income / Second"),
    EnableHookGuards = prior("EnableHookGuards", false),
}

if previous and previous.HookGuardRevision ~= 3 then
    States.EnableHookGuards = false
end

local Stats = {
    HitsSent = 0,
    RemoteBlocked = 0,
    BuildsCompleted = 0,
    Placements = 0,
    PlacementRequests = 0,
    BlueprintsUnlocked = 0,
    ToolsBought = 0,
    HelpersBought = 0,
    HelperChanges = 0,
    HelperLevels = 0,
    Rebirths = 0,
    IdlePulls = 0,
    IdlePlacements = 0,
    GoldConversions = 0,
}

local Farm = {
    Alive = true,
    States = States,
    Stats = Stats,
    Events = Events,
    Connections = {},
    BuildConnections = {},
    BoundaryParts = {},
    BaseplateParts = {},
    BoundaryPrototypes = setmetatable({}, { __mode = "k" }),
    PlacementCursor = 1,
    PlacementPending = false,
    PendingPlacementStartedAt = 0,
    PendingBlueprint = nil,
    PendingPlacementKind = nil,
    CurrentBuild = nil,
    ManualBuildTarget = nil,
    NextHitAt = 0,
    LastRemoteHitAt = 0,
    NextPlacementAt = 0,
    NextActionAt = {},
    Hooks = {
        Namecall = false,
        Boundary = false,
    },
    HookGuardRevision = 3,
}

getgenv().BuildingSimFarm = Farm

local function track(connection)
    table.insert(Farm.Connections, connection)
    return connection
end

local function ownedByMe(build)
    local owner = build:FindFirstChild("Owner")
    return owner and owner.Value == LocalPlayer
end

local function ownedBlueprint(name)
    return Data.Blueprints:FindFirstChild(name) ~= nil or Data.GoldBlueprints:FindFirstChild(name) ~= nil
end

local function unfinishedBuild()
    for _, build in ipairs(Builds:GetChildren()) do
        local done = build:FindFirstChild("Done")
        if done and done:IsA("BoolValue") and not done.Value and ownedByMe(build) then
            return build
        end
    end
    return nil
end

local function equippedBuildPower()
    local total = 0
    local tool = Tools:FindFirstChild(Data.EquippedTool.Value)
    local toolPower = tool and tool:FindFirstChild("Power")
    if toolPower then
        total += toolPower.Value
    end

    for _, helper in ipairs(Data.Helpers:GetChildren()) do
        local equipped = helper:FindFirstChild("Equipped")
        local power = helper:FindFirstChild("Power")
        if equipped and equipped.Value and power then
            total += power.Value
        end
    end

    return math.max(total, 1)
end

local function blueprintScore(blueprint)
    local value = blueprint:FindFirstChild("Value")
    local hitPoints = blueprint:FindFirstChild("HitPointsMax")
    local valueNumber = value and value.Value or 0
    local hitPointNumber = hitPoints and math.max(hitPoints.Value, 1) or 1

    if States.BuildStrategy == "Fastest Build" then
        return -hitPointNumber
    end

    if States.BuildStrategy == "Best Efficiency" then
        return valueNumber / hitPointNumber
    end

    if States.BuildStrategy == "Income / Second" then
        return valueNumber * equippedBuildPower() / hitPointNumber
    end

    return valueNumber
end

local function getBestOwnedBlueprint()
    local best
    local bestScore = -math.huge

    for _, blueprint in ipairs(Blueprints:GetChildren()) do
        if blueprint:IsA("Model") and ownedBlueprint(blueprint.Name) then
            local score = blueprintScore(blueprint)
            if score > bestScore then
                best = blueprint
                bestScore = score
            end
        end
    end

    return best
end

local function canUnlock(blueprint)
    if not blueprint:IsA("Model") or ownedBlueprint(blueprint.Name) then
        return false
    end

    local requires = blueprint:FindFirstChild("Requires")
    local price = blueprint:FindFirstChild("Price")
    if not price or price.Value < 0 or price.Value > Data.Money.Value then
        return false
    end

    return not requires or requires.Value == "" or ownedBlueprint(requires.Value)
end

local function actionReady(name, cooldown)
    local now = os.clock()
    if (Farm.NextActionAt[name] or 0) > now then
        return false
    end
    Farm.NextActionAt[name] = now + cooldown
    return true
end

local function unlockNextBlueprint()
    if not actionReady("Unlock", 0.75) then
        return false
    end

    local candidates = {}
    for _, blueprint in ipairs(Blueprints:GetChildren()) do
        if canUnlock(blueprint) then
            table.insert(candidates, blueprint)
        end
    end

    table.sort(candidates, function(a, b)
        return a.Price.Value < b.Price.Value
    end)

    local blueprint = candidates[1]
    if not blueprint then
        return false
    end

    Events.UnlockBlueprint:FireServer(blueprint)
    Stats.BlueprintsUnlocked += 1
    return true
end

local function bestOwnedTool()
    local best
    local bestPower = -math.huge

    for _, tool in ipairs(Tools:GetChildren()) do
        local power = tool:FindFirstChild("Power")
        if Data.UnlockedTools:FindFirstChild(tool.Name) and power and power.Value > bestPower then
            best = tool
            bestPower = power.Value
        end
    end

    return best
end

local function bestAffordableUnownedTool()
    local best
    local bestPower = -math.huge
    local money = Data.Money.Value

    for _, tool in ipairs(Tools:GetChildren()) do
        local price = tool:FindFirstChild("Price")
        local power = tool:FindFirstChild("Power")
        if price
            and power
            and price.Value >= 0
            and price.Value <= money
            and not Data.UnlockedTools:FindFirstChild(tool.Name)
            and power.Value > bestPower
        then
            best = tool
            bestPower = power.Value
        end
    end

    return best
end

local function progressTools()
    if not actionReady("Tool", 0.7) then
        return false
    end

    local purchase = bestAffordableUnownedTool()
    if purchase then
        Events.BuyTool:FireServer(purchase)
        Stats.ToolsBought += 1
        return true
    end

    local best = bestOwnedTool()
    if best and Data.EquippedTool.Value ~= best.Name then
        Events.EquipTool:FireServer(best)
        return true
    end

    return false
end

local function helperPower(helper)
    local power = helper:FindFirstChild("Power")
    return power and power.Value or 0
end

local function rankedHelpers()
    local list = {}
    for _, helper in ipairs(Data.Helpers:GetChildren()) do
        if helper:IsA("StringValue") and helper:FindFirstChild("Power") and helper:FindFirstChild("Equipped") then
            table.insert(list, helper)
        end
    end

    table.sort(list, function(a, b)
        local aPower = helperPower(a)
        local bPower = helperPower(b)
        if aPower == bPower then
            return a.Name < b.Name
        end
        return aPower > bPower
    end)

    return list
end

local function helperTargetCount()
    local slots = Data.InfiniteHelpers.Value and States.HelperTargetCount or Data.HelperSlots.Value
    return math.max(1, math.min(States.HelperTargetCount, slots))
end

local function bestHelpfulPurchase()
    local ranked = rankedHelpers()
    local targetCount = helperTargetCount()
    local weakestPower = #ranked >= targetCount and helperPower(ranked[targetCount]) or -math.huge
    local best
    local bestPower = weakestPower
    local money = Data.Money.Value

    for _, helper in ipairs(Helpers:GetChildren()) do
        local price = helper:FindFirstChild("Price")
        local power = helper:FindFirstChild("Power")
        if price
            and power
            and price.Value >= 0
            and price.Value <= money
            and power.Value > bestPower
        then
            best = helper
            bestPower = power.Value
        end
    end

    return best
end

local function buyHelpfulHelper()
    if not actionReady("HelperBuy", 1) then
        return false
    end

    local helper = bestHelpfulPurchase()
    if not helper then
        return false
    end

    Events.BuyHelper:FireServer(helper)
    Stats.HelpersBought += 1
    return true
end

local function reconcileHelpers()
    if not actionReady("HelperEquip", 0.4) then
        return false
    end

    local ranked = rankedHelpers()
    local wanted = {}
    local targetCount = helperTargetCount()
    for index = 1, math.min(targetCount, #ranked) do
        wanted[ranked[index]] = true
    end

    for _, helper in ipairs(ranked) do
        local equipped = helper:FindFirstChild("Equipped")
        if equipped and equipped.Value and not wanted[helper] then
            Events.EquipHelper:FireServer(helper)
            Stats.HelperChanges += 1
            return true
        end
    end

    for helper in pairs(wanted) do
        local equipped = helper:FindFirstChild("Equipped")
        if equipped and not equipped.Value then
            Events.EquipHelper:FireServer(helper)
            Stats.HelperChanges += 1
            return true
        end
    end

    return false
end

local function levelBestHelper()
    if not actionReady("HelperLevel", 0.8) then
        return false
    end

    local candidate
    local candidateScore = -math.huge
    local money = Data.Money.Value

    for _, helper in ipairs(rankedHelpers()) do
        local typeValue = helper:FindFirstChild("Type")
        local levelValue = helper:FindFirstChild("Level")
        if typeValue and levelValue then
            local prices = IDs.HelperLevelUps and IDs.HelperLevelUps[typeValue.Value]
            local price = prices and prices[levelValue.Value]
            if price and price <= money then
                local score = helperPower(helper) / math.max(price, 1)
                if score > candidateScore then
                    candidate = helper
                    candidateScore = score
                end
            end
        end
    end

    if not candidate then
        return false
    end

    Events.LevelUpHelper:FireServer(candidate)
    Stats.HelperLevels += 1
    return true
end

local function refreshBoundaryCache()
    local boundaries = {}
    for _, parent in ipairs({ Builds, IdleBuilds }) do
        for _, build in ipairs(parent:GetChildren()) do
            local boundary = build:FindFirstChild("Boundary")
            if boundary and boundary:IsA("BasePart") then
                table.insert(boundaries, boundary)
            end
        end
    end

    Farm.BoundaryParts = boundaries
    if not Farm.BoundaryParams then
        Farm.BoundaryParams = OverlapParams.new()
        Farm.BoundaryParams.FilterType = Enum.RaycastFilterType.Include
    end
    Farm.BoundaryParams.FilterDescendantsInstances = boundaries
end

local function refreshBaseplateCache()
    local baseplates = {}
    for _, part in ipairs(Baseplates:GetChildren()) do
        if part:IsA("BasePart") then
            table.insert(baseplates, part)
        end
    end
    Farm.BaseplateParts = baseplates
end

local function positionIsOnBaseplate(position)
    for _, baseplate in ipairs(Farm.BaseplateParts) do
        if baseplate.Parent then
            local localPosition = baseplate.CFrame:PointToObjectSpace(position)
            local halfSize = baseplate.Size * 0.5
            if math.abs(localPosition.X) <= halfSize.X and math.abs(localPosition.Z) <= halfSize.Z then
                return true
            end
        end
    end
    return false
end

local function boundaryOverlaps(cframe, size)
    if #Farm.BoundaryParts == 0 then
        return false
    end
    return #Workspace:GetPartBoundsInBox(cframe, size, Farm.BoundaryParams) > 0
end

local placementOffsets = {}
for _, radius in ipairs({ 25, 35, 45, 55, 70, 85, 100, 120, 140 }) do
    for index = 0, 15 do
        local angle = index / 16 * math.pi * 2
        table.insert(placementOffsets, Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius))
    end
end

local function getPlacementCFrame(blueprint)
    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end

    local ok, boundary = pcall(GetModelBoundaryPart, blueprint)
    if not ok or not boundary then
        return nil
    end

    local size = boundary.Size
    boundary:Destroy()
    local count = math.min(States.MaxPlacementChecks, #placementOffsets)

    for step = 0, count - 1 do
        local offsetIndex = (Farm.PlacementCursor + step - 2) % #placementOffsets + 1
        local position = root.Position + placementOffsets[offsetIndex]
        position = Vector3.new(position.X, 0.05, position.Z)

        if positionIsOnBaseplate(position) then
            local cframe = CFrame.new(position)
            local paddedSize = Vector3.new(
                math.max(size.X - 0.1, 0.1),
                math.max(size.Y, 0.1),
                math.max(size.Z - 0.1, 0.1)
            )
            if not boundaryOverlaps(cframe, paddedSize) then
                Farm.PlacementCursor = (offsetIndex % #placementOffsets) + 1
                return cframe
            end
        end
    end

    Farm.PlacementCursor = (Farm.PlacementCursor + count - 1) % #placementOffsets + 1
    return nil
end

local function clearPendingPlacement()
    Farm.PlacementPending = false
    Farm.PendingBlueprint = nil
    Farm.PendingPlacementStartedAt = 0
    Farm.PendingPlacementKind = nil
end

local function requestPlacement(blueprint, cframe, kind)
    local now = os.clock()
    Farm.PlacementPending = true
    Farm.PendingBlueprint = blueprint.Name
    Farm.PendingPlacementKind = kind
    Farm.PendingPlacementStartedAt = now
    Farm.NextPlacementAt = now + States.PlacementCooldown

    if kind == "idle" then
        Events.PlaceBlueprint:FireServer(blueprint, cframe, true)
    else
        Events.PlaceBlueprint:FireServer(blueprint, cframe)
    end

    if not (Farm.Hooks.Namecall and States.EnableHookGuards) then
        Stats.PlacementRequests += 1
    end

    if kind == "idle" then
        Stats.IdlePlacements += 1
    else
        Stats.Placements += 1
    end

    task.delay(States.PlacementTimeout, function()
        if Farm.Alive and Farm.PlacementPending and os.clock() - Farm.PendingPlacementStartedAt >= States.PlacementTimeout then
            clearPendingPlacement()
            Farm.NextPlacementAt = os.clock() + States.PlacementCooldown
        end
    end)

    return true
end

local function placeBest()
    local now = os.clock()
    if Farm.PlacementPending or now < Farm.NextPlacementAt or unfinishedBuild() then
        return false
    end

    local blueprint = getBestOwnedBlueprint()
    if not blueprint then
        return false
    end

    local cframe = getPlacementCFrame(blueprint)
    if not cframe then
        return false
    end

    return requestPlacement(blueprint, cframe, "normal")
end

local function getIdleBuildPrice()
    local factor = Values:FindFirstChild("IdleBuildPriceFactor")
    if not factor then
        return nil
    end
    return round(GetRebirthPrice(Data.Rebirths.Value) * factor.Value)
end

local function placePulledIdleBuild()
    if Farm.PlacementPending or os.clock() < Farm.NextPlacementAt then
        return false
    end

    if #Data.ActiveIdleBuilds:GetChildren() >= Data.IdleBuildSlots.Value then
        return false
    end

    local name = Data.LastPulledIdleBuild.Value
    local blueprint = name ~= "" and Blueprints:FindFirstChild(name)
    if not blueprint then
        return false
    end

    local cframe = getPlacementCFrame(blueprint)
    if not cframe then
        return false
    end

    return requestPlacement(blueprint, cframe, "idle")
end

local function pullIdleBuild()
    if not actionReady("IdlePull", 1.5)
        or Data.LastPulledIdleBuild.Value ~= ""
        or #Data.ActiveIdleBuilds:GetChildren() >= Data.IdleBuildSlots.Value
    then
        return false
    end

    local price = getIdleBuildPrice()
    if not price or Data.Money.Value < price then
        return false
    end

    local success, result = pcall(function()
        return Events.PullIdleBuild:InvokeServer()
    end)

    if success and result then
        if not (Farm.Hooks.Namecall and States.EnableHookGuards) then
            Stats.IdlePulls += 1
        end
        return true
    end

    return false
end

local function processIdleBuilds()
    if Data.LastPulledIdleBuild.Value ~= "" then
        return placePulledIdleBuild()
    end
    return pullIdleBuild()
end

local function turnEligibleGoldBlueprint()
    if not actionReady("Gold", 0.75) then
        return false
    end

    for _, blueprint in ipairs(Blueprints:GetChildren()) do
        local requirement = blueprint:FindFirstChild("RebirthsForGold")
        if Data.Blueprints:FindFirstChild(blueprint.Name)
            and not Data.GoldBlueprints:FindFirstChild(blueprint.Name)
            and requirement
            and requirement.Value <= Data.Rebirths.Value
        then
            Events.TurnGold:FireServer(blueprint)
            if not (Farm.Hooks.Namecall and States.EnableHookGuards) then
                Stats.GoldConversions += 1
            end
            return true
        end
    end

    return false
end

function Farm:GetHitDelay()
    return States.InstantBuild and States.HitDelay or 0.175
end

local function fireHit(build)
    if not build or not build.Parent then
        return false
    end

    local now = os.clock()
    if now < Farm.NextHitAt then
        return false
    end

    Farm.CurrentBuild = build
    Farm.NextHitAt = now + Farm:GetHitDelay()
    Events.HitBuild:FireServer(build)
    if not (Farm.Hooks.Namecall and States.EnableHookGuards) then
        Farm.LastRemoteHitAt = now
        Stats.HitsSent += 1
    end
    return true
end

local function tryRebirth()
    if not actionReady("Rebirth", 1.5) or Farm.PlacementPending or unfinishedBuild() then
        return false
    end

    local price = GetRebirthPrice(Data.Rebirths.Value)
    local threshold = price * States.RebirthPercent / 100
    if not price or Data.Money.Value < threshold then
        return false
    end

    local previousRebirths = Data.Rebirths.Value
    Events.Rebirth:FireServer()
    task.delay(0.8, function()
        if Farm.Alive and Data.Rebirths.Value > previousRebirths then
            Stats.Rebirths += 1
        end
    end)
    return true
end

local function formatNumber(number)
    number = math.floor(number or 0)
    if number >= 1000000000 then
        return string.format("%.2fB", number / 1000000000)
    end
    if number >= 1000000 then
        return string.format("%.2fM", number / 1000000)
    end
    if number >= 1000 then
        return string.format("%.1fK", number / 1000)
    end
    return tostring(number)
end

function Farm:GetStatus()
    local build = unfinishedBuild()
    local nextRebirth = GetRebirthPrice(Data.Rebirths.Value)
    local idle = Data.LastPulledIdleBuild.Value ~= "" and Data.LastPulledIdleBuild.Value or "none"
    return string.format(
        "Build: %s | Blueprint: %s | Idle: %s (%d/%d) | Money: %s | Helpers: %d/%d | Rebirth: %s | Hits: %d | Blocked: %d",
        build and build.Name or "waiting",
        getBestOwnedBlueprint() and getBestOwnedBlueprint().Name or "none",
        idle,
        #Data.ActiveIdleBuilds:GetChildren(),
        Data.IdleBuildSlots.Value,
        formatNumber(Data.Money.Value),
        #Data.Helpers:GetChildren(),
        helperTargetCount(),
        nextRebirth and formatNumber(nextRebirth) or "n/a",
        Stats.HitsSent,
        Stats.RemoteBlocked
    )
end

function Farm:Stop()
    if not self.Alive then
        return
    end

    self.Alive = false
    self.ManualBuildTarget = nil
    clearPendingPlacement()

    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(self.Connections)

    for build, connection in pairs(self.BuildConnections) do
        pcall(function()
            connection:Disconnect()
        end)
        self.BuildConnections[build] = nil
    end

    if self.MobileGui then
        pcall(function()
            self.MobileGui:Destroy()
        end)
        self.MobileGui = nil
    end

    if self.VibeUI and type(self.VibeUI.Unload) == "function" then
        pcall(function()
            self.VibeUI:Unload()
        end)
    elseif self.Window and type(self.Window.Destroy) == "function" then
        pcall(function()
            self.Window:Destroy()
        end)
    end

    local shared = getgenv().BuildingSimFarmSharedHooks
    if shared and shared.Farm == self then
        shared.Farm = nil
        if shared.NamecallInstalled and shared.OldNamecall then
            pcall(function()
                hookmetamethod(game, "__namecall", shared.OldNamecall)
            end)
        end
        if shared.BoundaryInstalled and shared.OldBoundary then
            pcall(function()
                hookfunction(GetModelBoundaryPart, shared.OldBoundary)
            end)
        end
        table.clear(shared)
    end

    if getgenv().BuildingSimFarm == self then
        getgenv().BuildingSimFarm = nil
    end
end

local sharedHooks = getgenv().BuildingSimFarmSharedHooks
if not sharedHooks then
    sharedHooks = {}
    getgenv().BuildingSimFarmSharedHooks = sharedHooks
end

local HOOK_VERSION = 2
if sharedHooks.Installed and sharedHooks.Version ~= HOOK_VERSION then
    if sharedHooks.NamecallInstalled and sharedHooks.OldNamecall then
        pcall(function()
            hookmetamethod(game, "__namecall", sharedHooks.OldNamecall)
        end)
    end
    if sharedHooks.BoundaryInstalled and sharedHooks.OldBoundary then
        pcall(function()
            hookfunction(GetModelBoundaryPart, sharedHooks.OldBoundary)
        end)
    end
    table.clear(sharedHooks)
end

sharedHooks.Farm = Farm

local function callerIsExecutor()
    return type(checkcaller) ~= "function" or checkcaller()
end

local function installHooks()
    if sharedHooks.Installed then
        Farm.Hooks.Namecall = sharedHooks.NamecallInstalled == true
        Farm.Hooks.Boundary = sharedHooks.BoundaryInstalled == true
        return
    end

    sharedHooks.Installed = true
    sharedHooks.Version = HOOK_VERSION
    local wrap = type(newcclosure) == "function" and newcclosure or function(callback)
        return callback
    end

    local okNamecall, oldNamecall = pcall(function()
        return hookmetamethod(game, "__namecall", wrap(function(self, ...)
            local activeFarm = sharedHooks.Farm
            if activeFarm and activeFarm.Alive and activeFarm.States.EnableHookGuards and callerIsExecutor() then
                local method = getnamecallmethod()
                if method == "FireServer" and self == activeFarm.Events.HitBuild then
                    local build = select(1, ...)
                    local now = os.clock()
                    if build == activeFarm.CurrentBuild and now - activeFarm.LastRemoteHitAt < activeFarm:GetHitDelay() * 0.8 then
                        activeFarm.Stats.RemoteBlocked += 1
                    end
                    activeFarm.LastRemoteHitAt = now
                    activeFarm.Stats.HitsSent += 1
                elseif method == "FireServer" and self == activeFarm.Events.PlaceBlueprint then
                    activeFarm.Stats.PlacementRequests += 1
                elseif method == "InvokeServer" and self == activeFarm.Events.PullIdleBuild then
                    activeFarm.Stats.IdlePulls += 1
                elseif method == "FireServer" and self == activeFarm.Events.TurnGold then
                    activeFarm.Stats.GoldConversions += 1
                end
            end
            return sharedHooks.OldNamecall(self, ...)
        end))
    end)

    if okNamecall and type(oldNamecall) == "function" then
        sharedHooks.OldNamecall = oldNamecall
        sharedHooks.NamecallInstalled = true
        Farm.Hooks.Namecall = true
    end

    local okBoundary, oldBoundary = pcall(function()
        return hookfunction(GetModelBoundaryPart, wrap(function(model, ...)
            local activeFarm = sharedHooks.Farm
            if activeFarm and activeFarm.Alive and activeFarm.States.EnableHookGuards and callerIsExecutor() then
                local cached = activeFarm.BoundaryPrototypes[model]
                if cached and cached.Parent == nil then
                    return cached:Clone()
                end

                local boundary = sharedHooks.OldBoundary(model, ...)
                if boundary then
                    local prototype = boundary:Clone()
                    prototype.Parent = nil
                    activeFarm.BoundaryPrototypes[model] = prototype
                end
                return boundary
            end
            return sharedHooks.OldBoundary(model, ...)
        end))
    end)

    if okBoundary and type(oldBoundary) == "function" then
        sharedHooks.OldBoundary = oldBoundary
        sharedHooks.BoundaryInstalled = true
        Farm.Hooks.Boundary = true
    end
end

installHooks()

local function watchBuild(build)
    if Farm.BuildConnections[build] or not ownedByMe(build) then
        return
    end

    local done = build:FindFirstChild("Done")
    if not done or not done:IsA("BoolValue") then
        return
    end

    Farm.BuildConnections[build] = done:GetPropertyChangedSignal("Value"):Connect(function()
        if done.Value then
            Stats.BuildsCompleted += 1
            if Farm.ManualBuildTarget == build then
                Farm.ManualBuildTarget = nil
            end
        end
    end)
end

refreshBoundaryCache()
refreshBaseplateCache()

for _, build in ipairs(Builds:GetChildren()) do
    watchBuild(build)
end

track(Builds.ChildAdded:Connect(function(build)
    task.defer(function()
        if not Farm.Alive then
            return
        end
        refreshBoundaryCache()
        if ownedByMe(build) then
            watchBuild(build)
            if Farm.PlacementPending and Farm.PendingPlacementKind == "normal" then
                clearPendingPlacement()
            end
        end
    end)
end))

track(Builds.ChildRemoved:Connect(function(build)
    local connection = Farm.BuildConnections[build]
    if connection then
        connection:Disconnect()
        Farm.BuildConnections[build] = nil
    end
    task.defer(refreshBoundaryCache)
end))

track(IdleBuilds.ChildAdded:Connect(function()
    task.defer(refreshBoundaryCache)
end))

track(IdleBuilds.ChildRemoved:Connect(function()
    task.defer(refreshBoundaryCache)
end))

track(Data.ActiveIdleBuilds.ChildAdded:Connect(function()
    if Farm.PlacementPending and Farm.PendingPlacementKind == "idle" then
        clearPendingPlacement()
    end
end))

track(Baseplates.ChildAdded:Connect(function()
    task.defer(refreshBaseplateCache)
end))

track(Baseplates.ChildRemoved:Connect(function()
    task.defer(refreshBaseplateCache)
end))

task.spawn(function()
    while Farm.Alive do
        local build = unfinishedBuild()
        if build and (States.AutoBuild or Farm.ManualBuildTarget == build) then
            fireHit(build)
        elseif Farm.ManualBuildTarget and Farm.ManualBuildTarget ~= build then
            Farm.ManualBuildTarget = nil
        end
        task.wait(math.min(Farm:GetHitDelay(), 0.05))
    end
end)

task.spawn(function()
    while Farm.Alive do
        if States.AutoIdleBuilds then
            processIdleBuilds()
        end
        task.wait(0.4)
    end
end)

task.spawn(function()
    while Farm.Alive do
        if States.AutoPlace and not unfinishedBuild() then
            placeBest()
        end
        task.wait(0.15)
    end
end)

task.spawn(function()
    while Farm.Alive do
        local didAction = false
        if States.AutoUnlock then
            didAction = unlockNextBlueprint()
        end
        if not didAction and States.AutoTools then
            didAction = progressTools()
        end
        if not didAction and States.AutoBuyHelpers then
            didAction = buyHelpfulHelper()
        end
        if not didAction and States.AutoEquipHelpers then
            didAction = reconcileHelpers()
        end
        if not didAction and States.AutoLevelHelpers then
            didAction = levelBestHelper()
        end
        if not didAction and States.AutoTurnGold then
            didAction = turnEligibleGoldBlueprint()
        end
        if not didAction and States.AutoRebirth then
            tryRebirth()
        end
        task.wait(0.3)
    end
end)

local VibeUI = loadstring(game:HttpGet(VIBE_URL))()
Farm.VibeUI = VibeUI

local Window = VibeUI:Window({
    Title = "Building Simulator | Autofarm",
    Keybind = Enum.KeyCode.RightControl,
})

Farm.Window = Window

local FarmTab = Window:Tab({ Name = "Farm", Columns = 2 })
local BuildSection = FarmTab:Section({ Name = "Building", Side = 1 })
local ProgressSection = FarmTab:Section({ Name = "Progression", Side = 2 })

BuildSection:Toggle({
    Name = "Auto Build",
    Flag = "BS_AutoBuild",
    Default = States.AutoBuild,
    Callback = function(value)
        States.AutoBuild = value
    end,
})

BuildSection:Toggle({
    Name = "Instant Build",
    Flag = "BS_InstantBuild",
    Default = States.InstantBuild,
    Callback = function(value)
        States.InstantBuild = value
    end,
})

BuildSection:Slider({
    Name = "Hit Delay",
    Flag = "BS_HitDelay",
    Min = 0.01,
    Max = 0.2,
    Default = States.HitDelay,
    Decimals = 0.01,
    Suffix = "s",
    Callback = function(value)
        States.HitDelay = math.clamp(tonumber(value) or 0.02, 0.01, 0.2)
    end,
})

BuildSection:Toggle({
    Name = "Auto Place Building",
    Flag = "BS_AutoPlace",
    Default = States.AutoPlace,
    Callback = function(value)
        States.AutoPlace = value
    end,
})

BuildSection:Slider({
    Name = "Placement Cooldown",
    Flag = "BS_PlacementCooldown",
    Min = 0.25,
    Max = 3,
    Default = States.PlacementCooldown,
    Decimals = 0.05,
    Suffix = "s",
    Callback = function(value)
        States.PlacementCooldown = math.clamp(tonumber(value) or 0.75, 0.25, 3)
    end,
})

BuildSection:Slider({
    Name = "Placement Search Budget",
    Flag = "BS_MaxPlacementChecks",
    Min = 12,
    Max = 144,
    Default = States.MaxPlacementChecks,
    Decimals = 1,
    Callback = function(value)
        States.MaxPlacementChecks = math.clamp(math.floor(tonumber(value) or 48), 12, 144)
    end,
})

BuildSection:Dropdown({
    Name = "Build Strategy",
    Flag = "BS_BuildStrategy",
    Items = { "Income / Second", "Best Value", "Best Efficiency", "Fastest Build" },
    Default = States.BuildStrategy,
    Callback = function(value)
        States.BuildStrategy = value
    end,
})

local buildButtons = BuildSection:Button()
buildButtons:Add("Place Best Now", function()
    local placed = placeBest()
    VibeUI:Notification({
        Title = placed and "Placement sent" or "Placement skipped",
        Description = placed and "Waiting for the server to create your build." or "A build is active, placement is pending, or no valid spot was found.",
        Type = placed and "success" or "warning",
        Duration = 3,
    })
end)

buildButtons:Add("Complete Current", function()
    local build = unfinishedBuild()
    if build then
        Farm.ManualBuildTarget = build
        Farm.NextHitAt = 0
        VibeUI:Notification({
            Title = "Build queued",
            Description = "The single build worker is finishing " .. build.Name .. ".",
            Type = "success",
            Duration = 3,
        })
    else
        VibeUI:Notification({
            Title = "No unfinished build",
            Type = "info",
            Duration = 3,
        })
    end
end)

ProgressSection:Toggle({
    Name = "Auto Unlock Blueprints",
    Flag = "BS_AutoUnlock",
    Default = States.AutoUnlock,
    Callback = function(value)
        States.AutoUnlock = value
    end,
})

ProgressSection:Toggle({
    Name = "Auto Buy / Equip Best Tool",
    Flag = "BS_AutoTools",
    Default = States.AutoTools,
    Callback = function(value)
        States.AutoTools = value
    end,
})

ProgressSection:Toggle({
    Name = "Auto Buy Useful Helpers",
    Flag = "BS_AutoBuyHelpers",
    Default = States.AutoBuyHelpers,
    Callback = function(value)
        States.AutoBuyHelpers = value
    end,
})

ProgressSection:Toggle({
    Name = "Auto Equip Best Helpers",
    Flag = "BS_AutoEquipHelpers",
    Default = States.AutoEquipHelpers,
    Callback = function(value)
        States.AutoEquipHelpers = value
    end,
})

ProgressSection:Toggle({
    Name = "Auto Level Helpers",
    Flag = "BS_AutoLevelHelpers",
    Default = States.AutoLevelHelpers,
    Callback = function(value)
        States.AutoLevelHelpers = value
    end,
})

ProgressSection:Slider({
    Name = "Helper Target Count",
    Flag = "BS_HelperTargetCount",
    Min = 1,
    Max = 12,
    Default = States.HelperTargetCount,
    Decimals = 1,
    Callback = function(value)
        States.HelperTargetCount = math.clamp(math.floor(tonumber(value) or 4), 1, 12)
    end,
})

ProgressSection:Toggle({
    Name = "Auto Rebirth",
    Flag = "BS_AutoRebirth",
    Default = States.AutoRebirth,
    Callback = function(value)
        States.AutoRebirth = value
    end,
})

ProgressSection:Toggle({
    Name = "Auto Idle Builds",
    Flag = "BS_AutoIdleBuilds",
    Default = States.AutoIdleBuilds,
    Callback = function(value)
        States.AutoIdleBuilds = value
    end,
})

ProgressSection:Toggle({
    Name = "Auto Turn Gold Blueprints",
    Flag = "BS_AutoTurnGold",
    Default = States.AutoTurnGold,
    Callback = function(value)
        States.AutoTurnGold = value
    end,
})

ProgressSection:Slider({
    Name = "Rebirth Threshold",
    Flag = "BS_RebirthPercent",
    Min = 100,
    Max = 250,
    Default = States.RebirthPercent,
    Decimals = 5,
    Suffix = "%",
    Callback = function(value)
        States.RebirthPercent = math.clamp(tonumber(value) or 115, 100, 250)
    end,
})

local progressButtons = ProgressSection:Button()
progressButtons:Add("Unlock Next", function()
    unlockNextBlueprint()
end)
progressButtons:Add("Upgrade Tool", function()
    progressTools()
end)
progressButtons:Add("Buy Helpful Helper", function()
    buyHelpfulHelper()
end)
progressButtons:Add("Reconcile Helpers", function()
    reconcileHelpers()
end)
progressButtons:Add("Pull Idle Build", function()
    pullIdleBuild()
end)
progressButtons:Add("Place Pulled Idle", function()
    placePulledIdleBuild()
end)
progressButtons:Add("Turn Eligible Gold", function()
    turnEligibleGoldBlueprint()
end)

local SystemTab = Window:Tab({ Name = "System", Columns = 1 })
local SystemSection = SystemTab:Section({ Name = "Status & Safety", Side = 1 })

SystemSection:Toggle({
    Name = "Hook Guards",
    Flag = "BS_EnableHookGuardsV3",
    Default = false,
    Callback = function(value)
        States.EnableHookGuards = value
    end,
})
States.EnableHookGuards = false

local systemButtons = SystemSection:Button()
systemButtons:Add("Show Status", function()
    VibeUI:Notification({
        Title = "Building Simulator Farm",
        Description = Farm:GetStatus(),
        Type = "info",
        Duration = 6,
    })
end)

systemButtons:Add("Unload", function()
    Farm:Stop()
end)

VibeUI:CreateSettingsPage(Window)

VibeUI:Notification({
    Title = "Building Simulator Autofarm",
    Description = string.format("Loaded. Hooks: %s / %s.", Farm.Hooks.Namecall and "namecall" or "fallback", Farm.Hooks.Boundary and "boundary" or "fallback"),
    Type = "success",
    Duration = 5,
})
