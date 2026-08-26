local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local Blueprints = ReplicatedStorage:WaitForChild("Blueprints")
local Tools = ReplicatedStorage:WaitForChild("Tools")
local Helpers = ReplicatedStorage:WaitForChild("Helpers")
local Functions = ReplicatedStorage:WaitForChild("Functions")
local IDs = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("IDs"))
local GetModelBoundaryPart = require(Functions:WaitForChild("GetModelBoundaryPart"))
local GetRebirthPrice = require(Functions:WaitForChild("getRebirthPrice"))

local Data = LocalPlayer:WaitForChild("PlayerDataFolder")
local Builds = Workspace:WaitForChild("Builds")
local Baseplates = Workspace:WaitForChild("MapBuild"):WaitForChild("Baseplates")

local VIBE_URL = "https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"

local previous = getgenv().BuildingSimFarm
local previousStates = previous and previous.States

if previous and type(previous.Stop) == "function" then
    pcall(previous.Stop)
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
    HitDelay = tonumber(prior("HitDelay", 0.01)) or 0.01,
    AutoPlace = prior("AutoPlace", true),
    AutoUnlock = prior("AutoUnlock", true),
    AutoTools = prior("AutoTools", true),
    AutoBuyHelpers = prior("AutoBuyHelpers", false),
    AutoEquipHelpers = prior("AutoEquipHelpers", true),
    AutoLevelHelpers = prior("AutoLevelHelpers", false),
    AutoRebirth = prior("AutoRebirth", false),
    BuildStrategy = prior("BuildStrategy", "Best Value"),
}

local Stats = {
    HitsSent = 0,
    BuildsCompleted = 0,
    Placements = 0,
    BlueprintsUnlocked = 0,
    ToolsBought = 0,
    HelpersBought = 0,
    Rebirths = 0,
}

local Farm = {
    Alive = true,
    States = States,
    Stats = Stats,
}

local function ownedByMe(build)
    local owner = build:FindFirstChild("Owner")
    return owner and owner.Value == LocalPlayer
end

local function unfinishedBuild()
    for _, build in ipairs(Builds:GetChildren()) do
        local done = build:FindFirstChild("Done")
        if done and not done.Value and ownedByMe(build) then
            return build
        end
    end
end

local function ownedBlueprint(name)
    return Data.Blueprints:FindFirstChild(name) ~= nil
end

local function blueprintScore(bp)
    local value = bp:FindFirstChild("Value")
    local hp = bp:FindFirstChild("HitPointsMax")
    local valueNum = value and value.Value or 0
    local hpNum = hp and math.max(hp.Value, 1) or 1

    if States.BuildStrategy == "Fastest Build" then
        return -hpNum
    elseif States.BuildStrategy == "Best Efficiency" then
        return valueNum / hpNum
    end

    return valueNum
end

local function getBestOwnedBlueprint()
    local best
    local bestScore = -math.huge

    for _, bp in ipairs(Blueprints:GetChildren()) do
        if bp:IsA("Model") and ownedBlueprint(bp.Name) then
            local score = blueprintScore(bp)
            if score > bestScore then
                best = bp
                bestScore = score
            end
        end
    end

    return best
end

local function canUnlock(bp)
    if not bp:IsA("Model") or ownedBlueprint(bp.Name) then
        return false
    end

    local requires = bp:FindFirstChild("Requires")
    local price = bp:FindFirstChild("Price")

    if not price or price.Value < 0 or price.Value > Data.Money.Value then
        return false
    end

    if requires and requires.Value ~= "" and not ownedBlueprint(requires.Value) then
        return false
    end

    return true
end

local function unlockNextBlueprint()
    local candidates = {}

    for _, bp in ipairs(Blueprints:GetChildren()) do
        if canUnlock(bp) then
            table.insert(candidates, bp)
        end
    end

    table.sort(candidates, function(a, b)
        return a.Price.Value < b.Price.Value
    end)

    local bp = candidates[1]
    if bp then
        Events.UnlockBlueprint:FireServer(bp)
        Stats.BlueprintsUnlocked += 1
        return true
    end

    return false
end

local function bestOwnedTool()
    local best
    local bestPower = -math.huge

    for _, tool in ipairs(Tools:GetChildren()) do
        local owned = Data.UnlockedTools:FindFirstChild(tool.Name)
        local power = tool:FindFirstChild("Power")
        if owned and power and power.Value > bestPower then
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
        local power = tool:FindFirstChild("Power")
        local price = tool:FindFirstChild("Price")
        if power and price
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
    local buy = bestAffordableUnownedTool()
    if buy then
        Events.BuyTool:FireServer(buy)
        Stats.ToolsBought += 1
        task.wait(0.12)
    end

    local best = bestOwnedTool()
    if best and Data.EquippedTool.Value ~= best.Name then
        Events.EquipTool:FireServer(best)
    end
end

local function helperPower(helper)
    local power = helper:FindFirstChild("Power")
    return power and power.Value or 0
end

local function ownedHelpersSorted()
    local list = Data.Helpers:GetChildren()

    table.sort(list, function(a, b)
        return helperPower(a) > helperPower(b)
    end)

    return list
end

local function equipBestHelpers()
    local list = ownedHelpersSorted()
    local slots = Data.InfiniteHelpers.Value and math.huge or Data.HelperSlots.Value

    for i, helper in ipairs(list) do
        local equipped = helper:FindFirstChild("Equipped")
        if equipped then
            local shouldEquip = i <= slots
            if equipped.Value ~= shouldEquip then
                Events.EquipHelper:FireServer(helper)
                task.wait(0.08)
            end
        end
    end
end

local function bestAffordableHelperDef()
    local best
    local bestPower = -math.huge
    local money = Data.Money.Value

    for _, helper in ipairs(Helpers:GetChildren()) do
        local price = helper:FindFirstChild("Price")
        local power = helper:FindFirstChild("Power")
        if price and power
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

local function buyHelper()
    local helper = bestAffordableHelperDef()
    if helper then
        local before = #Data.Helpers:GetChildren()
        Events.BuyHelper:FireServer(helper)
        task.wait(0.15)
        if #Data.Helpers:GetChildren() > before then
            Stats.HelpersBought += 1
            return true
        end
    end
    return false
end

local function levelHelpers()
    local money = Data.Money.Value
    local candidates = {}

    for _, helper in ipairs(Data.Helpers:GetChildren()) do
        local typeValue = helper:FindFirstChild("Type")
        local levelValue = helper:FindFirstChild("Level")
        if typeValue and levelValue then
            local typePrices = IDs.HelperLevelUps and IDs.HelperLevelUps[typeValue.Value]
            local price = typePrices and typePrices[levelValue.Value]
            if price and price <= money then
                table.insert(candidates, {
                    Helper = helper,
                    Price = price,
                    Power = helperPower(helper),
                })
            end
        end
    end

    table.sort(candidates, function(a, b)
        if a.Power == b.Power then
            return a.Price < b.Price
        end
        return a.Power > b.Power
    end)

    local pick = candidates[1]
    if pick then
        Events.LevelUpHelper:FireServer(pick.Helper)
        return true
    end

    return false
end

local function boundaryOverlaps(cf, size)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Include

    local boundaries = {}
    for _, build in ipairs(Builds:GetChildren()) do
        local boundary = build:FindFirstChild("Boundary")
        if boundary and boundary:IsA("BasePart") then
            table.insert(boundaries, boundary)
        end
    end

    local idleBuilds = Workspace:FindFirstChild("IdleBuilds")
    if idleBuilds then
        for _, build in ipairs(idleBuilds:GetChildren()) do
            local boundary = build:FindFirstChild("Boundary")
            if boundary and boundary:IsA("BasePart") then
                table.insert(boundaries, boundary)
            end
        end
    end

    if #boundaries == 0 then
        return false
    end

    params.FilterDescendantsInstances = boundaries
    return #Workspace:GetPartBoundsInBox(cf, size, params) > 0
end

local function onBaseplate(position)
    local origin = position + Vector3.new(0, 100, 0)
    local direction = Vector3.new(0, -250, 0)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = { Baseplates }

    local hit = Workspace:Raycast(origin, direction, params)
    return hit ~= nil
end

local function getPlacementCFrame(bp)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return nil
    end

    local ok, boundary = pcall(GetModelBoundaryPart, bp)
    if not ok or not boundary then
        return nil
    end

    local size = boundary.Size
    boundary:Destroy()

    local center = hrp.Position
    local radii = { 25, 35, 45, 55, 70, 85, 100, 120, 140 }
    local steps = 24

    for _, radius in ipairs(radii) do
        for i = 0, steps - 1 do
            local angle = (i / steps) * math.pi * 2
            local x = center.X + math.cos(angle) * radius
            local z = center.Z + math.sin(angle) * radius
            local pos = Vector3.new(x, 0.05, z)

            if (Vector3.new(x, center.Y, z) - center).Magnitude <= 155 and onBaseplate(pos) then
                local cf = CFrame.new(pos)
                local inflated = Vector3.new(
                    math.max(size.X - 0.1, 0.1),
                    math.max(size.Y, 0.1),
                    math.max(size.Z - 0.1, 0.1)
                )

                if not boundaryOverlaps(cf, inflated) then
                    return cf
                end
            end
        end
    end
end

local function placeBest()
    if unfinishedBuild() then
        return false
    end

    local bp = getBestOwnedBlueprint()
    if not bp then
        return false
    end

    local cf = getPlacementCFrame(bp)
    if not cf then
        return false
    end

    Events.PlaceBlueprint:FireServer(bp, cf)
    Stats.Placements += 1
    return true
end

local function completeCurrent()
    local build = unfinishedBuild()
    if not build then
        return false
    end

    local done = build:FindFirstChild("Done")
    if not done then
        return false
    end

    local wasDone = done.Value

    while Farm.Alive and build.Parent and not done.Value do
        Events.HitBuild:FireServer(build)
        Stats.HitsSent += 1
        task.wait(States.InstantBuild and math.max(States.HitDelay, 0.001) or 0.175)
    end

    if not wasDone and done.Value then
        Stats.BuildsCompleted += 1
    end

    return done.Value
end

local function tryRebirth()
    local price = GetRebirthPrice(Data.Rebirths.Value)
    if price and Data.Money.Value >= price then
        local old = Data.Rebirths.Value
        Events.Rebirth:FireServer()
        task.wait(0.25)
        if Data.Rebirths.Value > old then
            Stats.Rebirths += 1
            return true
        end
    end
    return false
end

function Farm.Stop()
    Farm.Alive = false
end

getgenv().BuildingSimFarm = Farm

task.spawn(function()
    while Farm.Alive do
        if States.AutoBuild then
            local build = unfinishedBuild()
            if build then
                local done = build:FindFirstChild("Done")
                if done and not done.Value then
                    Events.HitBuild:FireServer(build)
                    Stats.HitsSent += 1
                end
            end
        end

        task.wait(
            States.AutoBuild
                and (States.InstantBuild and math.max(States.HitDelay, 0.001) or 0.175)
                or 0.1
        )
    end
end)

task.spawn(function()
    while Farm.Alive do
        if States.AutoUnlock then
            unlockNextBlueprint()
        end

        if States.AutoTools then
            progressTools()
        end

        if States.AutoBuyHelpers then
            buyHelper()
        end

        if States.AutoEquipHelpers then
            equipBestHelpers()
        end

        if States.AutoLevelHelpers then
            levelHelpers()
        end

        if States.AutoRebirth then
            tryRebirth()
        end

        task.wait(0.25)
    end
end)

task.spawn(function()
    while Farm.Alive do
        if States.AutoPlace and not unfinishedBuild() then
            placeBest()
        end
        task.wait(0.2)
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
    Callback = function(v)
        States.AutoBuild = v
    end,
})

BuildSection:Toggle({
    Name = "Instant Build",
    Flag = "BS_InstantBuild",
    Default = States.InstantBuild,
    Callback = function(v)
        States.InstantBuild = v
    end,
})

BuildSection:Slider({
    Name = "Hit Delay",
    Flag = "BS_HitDelay",
    Min = 0.005,
    Max = 0.05,
    Default = States.HitDelay,
    Decimals = 0.005,
    Suffix = "s",
    Callback = function(v)
        States.HitDelay = tonumber(v) or 0.01
    end,
})

BuildSection:Toggle({
    Name = "Auto Place Building",
    Flag = "BS_AutoPlace",
    Default = States.AutoPlace,
    Callback = function(v)
        States.AutoPlace = v
    end,
})

BuildSection:Dropdown({
    Name = "Build Strategy",
    Flag = "BS_BuildStrategy",
    Items = { "Best Value", "Best Efficiency", "Fastest Build" },
    Default = States.BuildStrategy,
    Callback = function(v)
        States.BuildStrategy = v
    end,
})

local buildButtons = BuildSection:Button()
buildButtons:Add("Place Best Now", function()
    local ok = placeBest()
    VibeUI:Notification({
        Title = ok and "Placed" or "Placement skipped",
        Description = ok and "Placed the selected best blueprint." or "No valid placement was available.",
        Type = ok and "success" or "warning",
        Duration = 3,
    })
end)

buildButtons:Add("Complete Current", function()
    task.spawn(function()
        local ok = completeCurrent()
        VibeUI:Notification({
            Title = ok and "Build complete" or "No unfinished build",
            Type = ok and "success" or "info",
            Duration = 3,
        })
    end)
end)

ProgressSection:Toggle({
    Name = "Auto Unlock Blueprints",
    Flag = "BS_AutoUnlock",
    Default = States.AutoUnlock,
    Callback = function(v)
        States.AutoUnlock = v
    end,
})

ProgressSection:Toggle({
    Name = "Auto Buy / Equip Best Tool",
    Flag = "BS_AutoTools",
    Default = States.AutoTools,
    Callback = function(v)
        States.AutoTools = v
    end,
})

ProgressSection:Toggle({
    Name = "Auto Buy Helpers",
    Flag = "BS_AutoBuyHelpers",
    Default = States.AutoBuyHelpers,
    Callback = function(v)
        States.AutoBuyHelpers = v
    end,
})

ProgressSection:Toggle({
    Name = "Auto Equip Best Helpers",
    Flag = "BS_AutoEquipHelpers",
    Default = States.AutoEquipHelpers,
    Callback = function(v)
        States.AutoEquipHelpers = v
    end,
})

ProgressSection:Toggle({
    Name = "Auto Level Helpers",
    Flag = "BS_AutoLevelHelpers",
    Default = States.AutoLevelHelpers,
    Callback = function(v)
        States.AutoLevelHelpers = v
    end,
})

ProgressSection:Toggle({
    Name = "Auto Rebirth",
    Flag = "BS_AutoRebirth",
    Default = States.AutoRebirth,
    Callback = function(v)
        States.AutoRebirth = v
    end,
})

local manualButtons = ProgressSection:Button()
manualButtons:Add("Unlock Next", function()
    unlockNextBlueprint()
end)
manualButtons:Add("Upgrade Tool", function()
    progressTools()
end)

local helperButtons = ProgressSection:Button()
helperButtons:Add("Buy Helper", function()
    buyHelper()
end)
helperButtons:Add("Equip Best", function()
    equipBestHelpers()
end)

VibeUI:CreateSettingsPage(Window)

VibeUI:Notification({
    Title = "Building Simulator Autofarm",
    Description = "Loaded. Right Ctrl toggles the UI.",
    Type = "success",
    Duration = 4,
})
