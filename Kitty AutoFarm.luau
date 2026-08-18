local Env = getgenv()
local PreviousFarm = Env.KittyAutoFarm

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local Game = ReplicatedStorage:WaitForChild("Game")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local Interacts = require(Modules:WaitForChild("Interacts"))
local Tools = require(Modules:WaitForChild("Tools"))
local Fuc = require(Modules:WaitForChild("fuc"))

local VibeUI = loadstring(game:HttpGet("https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"))()

local State = {
    Running = true,
    Enabled = true,
    AutoCollect = true,
    AutoInteract = true,
    AutoExit = true,
    AutoInventory = true,
    Delay = 0.2,
    Status = "Starting...",
    Map = nil,
    MapName = "Waiting for map",
    RequiredCount = 0,
    LastNoKey = setmetatable({}, { __mode = "k" }),
    LastNoKeyTime = setmetatable({}, { __mode = "k" }),
    OneShot = setmetatable({}, { __mode = "k" }),
    LastExitTouch = 0,
    Busy = false,
}

local StatusLabel
local MapLabel
local RequiredLabel
local MasterToggle

local ResolvedStatuses = {
    success = true,
    succes = true,
    succeeded = true,
    completed = true,
    complete = true,
    done = true,
}

local RepeatableNoKey = {
    LeverRobot = true,
}

local OneShotNoKey = {
    Door = true,
    DoorUp = true,
    DoubleDoorUp = true,
    Switch = true,
    GruaPuzzle = true,
}

local function SetStatus(text)
    text = tostring(text)
    if State.Status == text then
        return
    end

    State.Status = text

    if StatusLabel then
        pcall(function()
            StatusLabel:SetText(text)
        end)
    end
end

local function SetMapText(text)
    text = tostring(text)
    if State.MapName == text then
        return
    end

    State.MapName = text

    if MapLabel then
        pcall(function()
            MapLabel:SetText("Map: " .. text)
        end)
    end
end

local function SetRequiredCount(count)
    count = tonumber(count) or 0
    if State.RequiredCount == count then
        return
    end

    State.RequiredCount = count

    if RequiredLabel then
        pcall(function()
            RequiredLabel:SetText("Required items: " .. tostring(count))
        end)
    end
end

local function GetMap()
    local ok, map = pcall(function()
        return Fuc:IsMap()
    end)

    if ok and map and map.Parent then
        return map
    end

    local mapRoot = Workspace:FindFirstChild("Map")
    if not mapRoot then
        return nil
    end

    for _, child in ipairs(mapRoot:GetChildren()) do
        if child:FindFirstChild("Interacts") and child:FindFirstChild("Tools") then
            return child
        end
    end

    return nil
end

local function ResetMapCaches(map)
    State.Map = map
    State.LastNoKey = setmetatable({}, { __mode = "k" })
    State.LastNoKeyTime = setmetatable({}, { __mode = "k" })
    State.OneShot = setmetatable({}, { __mode = "k" })
    State.LastExitTouch = 0
    SetMapText(map and map.Name or "Waiting for map")
end

local function GetStatus(object)
    if not object or not object.Parent then
        return nil
    end

    local settings = object:FindFirstChild("Settings")
    local status = settings and settings:FindFirstChild("Status")

    if status and status:IsA("StringValue") then
        return status.Value
    end

    return nil
end

local function IsResolved(object)
    local status = GetStatus(object)

    if not status then
        return false
    end

    return ResolvedStatuses[string.lower(status)] == true
end

local function AddKey(output, seen, value)
    if type(value) == "string" then
        if value ~= "" and not seen[value] then
            seen[value] = true
            output[#output + 1] = value
        end
        return
    end

    if type(value) ~= "table" then
        return
    end

    for key, item in pairs(value) do
        if type(item) == "string" then
            AddKey(output, seen, item)
        elseif type(key) == "string" and (item == true or type(item) == "number") then
            AddKey(output, seen, key)
        end
    end
end

local function GetRequiredKeys(object)
    local output = {}
    local seen = {}

    if not object or not object.Parent then
        return output
    end

    local settings = object:FindFirstChild("Settings")

    if settings then
        local currentTool = settings:FindFirstChild("CurrentTool")
        if currentTool and currentTool:IsA("StringValue") then
            AddKey(output, seen, currentTool.Value)
        end
    end

    local definition = Interacts[object.Name]

    if definition then
        AddKey(output, seen, definition.Key)
    end

    local status = GetStatus(object)

    if status == "Craft" and settings then
        local statusUnlocked = settings:FindFirstChild("StatusUnlocked")

        if statusUnlocked and statusUnlocked:IsA("StringValue") and statusUnlocked.Value ~= "" then
            local recipe = Interacts[statusUnlocked.Value]

            if recipe and type(recipe.RecipeTools) == "table" then
                AddKey(output, seen, recipe.RecipeTools)
            end
        end
    end

    return output
end

local function GetTargets(map)
    local targets = {}
    local seen = {}

    local function Add(object, isPuzzle)
        if not object or seen[object] or not object.Parent then
            return
        end

        if not object:FindFirstChild("Settings") then
            return
        end

        seen[object] = true
        targets[#targets + 1] = {
            Object = object,
            IsPuzzle = isPuzzle,
        }
    end

    local interactsFolder = map:FindFirstChild("Interacts")

    if interactsFolder then
        for _, object in ipairs(interactsFolder:GetChildren()) do
            Add(object, false)

            local puzzles = object:FindFirstChild("Puzzles")
            if puzzles then
                for _, puzzle in ipairs(puzzles:GetChildren()) do
                    Add(puzzle, true)
                end
            end
        end
    end

    local puzzlesFolder = map:FindFirstChild("Puzzles")

    if puzzlesFolder then
        for _, puzzle in ipairs(puzzlesFolder:GetChildren()) do
            Add(puzzle, true)
        end
    end

    return targets
end

local function GetSlots()
    local slots = {}
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    local slotFolder = inventory and inventory:FindFirstChild("Slots")

    if not slotFolder then
        return slots
    end

    for _, slot in ipairs(slotFolder:GetChildren()) do
        if slot:IsA("ObjectValue") then
            slots[#slots + 1] = slot
        end
    end

    table.sort(slots, function(a, b)
        local ai = tonumber(string.match(a.Name, "%d+")) or math.huge
        local bi = tonumber(string.match(b.Name, "%d+")) or math.huge
        return ai < bi
    end)

    return slots
end

local function GetSlotIndex(slot)
    return tonumber(string.match(slot.Name, "%d+"))
end

local function FindOwned(name)
    for _, slot in ipairs(GetSlots()) do
        if slot.Value and slot.Value.Name == name then
            return slot, GetSlotIndex(slot), slot.Value
        end
    end

    return nil
end

local function IsInventoryFull()
    local slots = GetSlots()

    if #slots == 0 then
        return false
    end

    for _, slot in ipairs(slots) do
        if not slot.Value then
            return false
        end
    end

    return true
end

local function GetHeldNames()
    local names = {}

    for _, slot in ipairs(GetSlots()) do
        if slot.Value then
            names[slot.Value.Name] = true
        end
    end

    return names
end

local function EquipSlot(slot, index)
    local inventory = LocalPlayer:FindFirstChild("Inventory")
    local equip = inventory and inventory:FindFirstChild("Equip")

    if not slot or not index or not slot.Value then
        return false
    end

    if equip and equip.Value == slot then
        return true
    end

    Events.ToolAction:FireServer(index)

    local deadline = os.clock() + 0.35

    while os.clock() < deadline do
        if not State.Running then
            return false
        end

        if equip and equip.Value == slot then
            return true
        end

        task.wait()
    end

    return equip == nil or equip.Value == slot
end

local function GatherRequirements(targets)
    local required = {}
    local count = 0

    for _, entry in ipairs(targets) do
        local object = entry.Object

        if object.Parent and not IsResolved(object) then
            for _, key in ipairs(GetRequiredKeys(object)) do
                if not required[key] then
                    required[key] = true
                    count += 1
                end
            end
        end
    end

    SetRequiredCount(count)
    return required
end

local function FindMapTool(map, name)
    local folder = map:FindFirstChild("Tools")

    if not folder then
        return nil
    end

    for _, tool in ipairs(folder:GetChildren()) do
        if tool.Name == name and tool:IsA("Model") and tool.PrimaryPart then
            return tool
        end
    end

    return nil
end

local function DropBlocker(required)
    if not State.AutoInventory then
        return false
    end

    local slots = GetSlots()

    for _, slot in ipairs(slots) do
        local item = slot.Value

        if item and not required[item.Name] then
            local index = GetSlotIndex(slot)

            if EquipSlot(slot, index) then
                SetStatus("Dropping blocker: " .. item.Name)
                Events.DropTool:FireServer()
                task.wait(0.12)
                return true
            end
        end
    end

    return false
end


local function GetObjectCFrame(object)
    if not object or not object.Parent then
        return nil
    end

    if object:IsA("BasePart") then
        return object.CFrame
    end

    if object:IsA("Model") then
        local part = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
        if part then
            return part.CFrame
        end

        local ok, pivot = pcall(object.GetPivot, object)
        if ok then
            return pivot
        end
    end

    local part = object:FindFirstChildWhichIsA("BasePart", true)
    return part and part.CFrame or nil
end

local function MoveNear(object)
    local character = LocalPlayer.Character
    local target = GetObjectCFrame(object)

    if not character or not target then
        return false
    end

    local root = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end

    if (root.Position - target.Position).Magnitude > 10 then
        pcall(function()
            character:PivotTo(target * CFrame.new(0, 3, 0))
        end)
        task.wait(0.18)
    end

    return true
end

local function TryCollectRequired(map, required)
    if not State.AutoCollect then
        return false
    end

    local held = GetHeldNames()

    for name in pairs(required) do
        if not held[name] then
            local tool = FindMapTool(map, name)

            if tool then
                if IsInventoryFull() then
                    if DropBlocker(required) then
                        return true
                    end

                    SetStatus("Inventory full; processing held objectives")
                    return false
                end

                SetStatus("Collecting " .. name)

                if MoveNear(tool) then
                    Events.GetTool:FireServer(tool)
                    task.wait(0.25)
                    return true
                end
            end
        end
    end

    return false
end

local function TryOwnedRequirement(targets)
    if not State.AutoInteract then
        return false
    end

    for _, entry in ipairs(targets) do
        local object = entry.Object

        if object.Parent and not IsResolved(object) then
            for _, key in ipairs(GetRequiredKeys(object)) do
                local slot, index = FindOwned(key)

                if slot and index then
                    SetStatus("Using " .. key .. " on " .. object.Name)

                    if EquipSlot(slot, index) and MoveNear(object) then
                        Events.Interact:FireServer(object)
                        task.wait(0.25)
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function HasResolvedChildPuzzle(object)
    local puzzles = object:FindFirstChild("Puzzles")

    if not puzzles then
        return false
    end

    local found = false

    for _, puzzle in ipairs(puzzles:GetChildren()) do
        if puzzle:FindFirstChild("Settings") then
            found = true

            if not IsResolved(puzzle) then
                return false
            end
        end
    end

    return found
end

local function ShouldNoKeyInteract(entry)
    local object = entry.Object

    if not object.Parent or IsResolved(object) then
        return false
    end

    if #GetRequiredKeys(object) > 0 then
        return false
    end

    local status = GetStatus(object)

    if not status or status == "" or status == "Wait" then
        return false
    end

    if object.Name == "ActiveButton" and HasResolvedChildPuzzle(object) then
        return false
    end

    if (object.Name == "Door" or object.Name == "DoorUp" or object.Name == "DoubleDoorUp") and status == "Open" then
        return false
    end

    if OneShotNoKey[object.Name] then
        return not State.OneShot[object]
    end

    if RepeatableNoKey[object.Name] then
        local last = State.LastNoKeyTime[object] or 0
        return os.clock() - last >= 0.7
    end

    return State.LastNoKey[object] ~= status
end

local function TryNoKeyInteraction(targets)
    if not State.AutoInteract then
        return false
    end

    for _, entry in ipairs(targets) do
        local object = entry.Object

        if ShouldNoKeyInteract(entry) then
            local status = GetStatus(object) or ""

            SetStatus("Interacting: " .. object.Name)

            if not MoveNear(object) then
                return false
            end

            Events.Interact:FireServer(object)

            State.LastNoKey[object] = status
            State.LastNoKeyTime[object] = os.clock()

            if OneShotNoKey[object.Name] then
                State.OneShot[object] = true
            end

            task.wait(0.1)
            return true
        end
    end

    return false
end

local function GetWinPart()
    local win = Game:FindFirstChild("Win") and Game.Win.Value

    if not win or not win.Parent then
        return nil
    end

    if win:IsA("BasePart") then
        return win
    end

    if win:IsA("Model") then
        return win.PrimaryPart or win:FindFirstChildWhichIsA("BasePart", true)
    end

    return win:FindFirstChildWhichIsA("BasePart", true)
end

local function TryExit()
    if not State.AutoExit then
        return false
    end

    local winPart = GetWinPart()

    if not winPart then
        return false
    end

    if os.clock() - State.LastExitTouch < 1.5 then
        return true
    end

    local character = LocalPlayer.Character
    local root = character and (character.PrimaryPart or character:FindFirstChild("HumanoidRootPart"))

    if not character or not root then
        return false
    end

    State.LastExitTouch = os.clock()
    SetStatus("Finishing map")

    pcall(function()
        character:PivotTo(winPart.CFrame + Vector3.new(0, 1.5, 0))
    end)

    if type(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(root, winPart, 0)
            task.wait()
            firetouchinterest(root, winPart, 1)
        end)
    end

    return true
end

local function FarmStep()
    if State.Busy or not State.Running or not State.Enabled then
        return
    end

    State.Busy = true

    local ok, err = pcall(function()
        local map = GetMap()

        if map ~= State.Map then
            ResetMapCaches(map)
        end

        if not map then
            SetRequiredCount(0)
            SetStatus("Waiting for map")
            return
        end

        if TryExit() then
            return
        end

        local targets = GetTargets(map)

        if TryOwnedRequirement(targets) then
            return
        end

        if TryNoKeyInteraction(targets) then
            return
        end

        local required = GatherRequirements(targets)

        if TryCollectRequired(map, required) then
            return
        end

        SetStatus("Waiting for next puzzle/tool")
    end)

    State.Busy = false

    if not ok then
        SetStatus("Farm error: " .. tostring(err))
    end
end

local function Stop()
    State.Running = false
    State.Enabled = false
    SetStatus("Stopped")
end

local API = {
    State = State,
}

function API.Start()
    State.Running = true
    State.Enabled = true

    if MasterToggle then
        pcall(function()
            MasterToggle:Set(true)
        end)
    end
end

function API.Stop()
    Stop()
end

function API.Step()
    task.spawn(FarmStep)
end

function API.GetStatus()
    return State.Status
end

function API.GetMap()
    return State.Map
end

local Window = VibeUI:Window({
    Title = "Kitty AutoFarm",
    Keybind = Enum.KeyCode.RightControl,
})

local FarmTab = Window:Tab({
    Name = "AutoFarm",
    Columns = 2,
})

local AutomationSection = FarmTab:Section({
    Name = "Automation",
    Side = 1,
})

MasterToggle = AutomationSection:Toggle({
    Name = "Auto Farm",
    Flag = "KittyAutoFarmEnabled",
    Default = true,
    Info = "Master switch for automatic map completion.",
    InfoType = "tip",
    Callback = function(value)
        State.Enabled = value
        if value then
            State.Running = true
            SetStatus("Resuming")
        else
            SetStatus("Paused")
        end
    end,
})

AutomationSection:Toggle({
    Name = "Auto Collect Required Items",
    Flag = "KittyAutoCollect",
    Default = true,
    Info = "Collects progression items needed by unresolved objectives instead of filling both slots with junk.",
    InfoType = "info",
    Callback = function(value)
        State.AutoCollect = value
    end,
})

AutomationSection:Toggle({
    Name = "Auto Interact",
    Flag = "KittyAutoInteract",
    Default = true,
    Info = "Uses equipped progression items and activates map interactions automatically.",
    InfoType = "info",
    Callback = function(value)
        State.AutoInteract = value
    end,
})

AutomationSection:Toggle({
    Name = "Auto Finish Map",
    Flag = "KittyAutoExit",
    Default = true,
    Info = "Touches the unlocked completion target as soon as Game.Win becomes available.",
    InfoType = "tip",
    Callback = function(value)
        State.AutoExit = value
    end,
})

AutomationSection:Toggle({
    Name = "Auto Manage Inventory",
    Flag = "KittyAutoInventory",
    Default = true,
    Info = "Drops non-required blockers when all inventory slots are occupied.",
    InfoType = "warning",
    Callback = function(value)
        State.AutoInventory = value
    end,
})

AutomationSection:Slider({
    Name = "Farm Delay",
    Flag = "KittyFarmDelay",
    Min = 0.05,
    Max = 1,
    Default = 0.2,
    Decimals = 0.05,
    Suffix = "s",
    Callback = function(value)
        State.Delay = math.max(0.05, tonumber(value) or 0.2)
    end,
})

local StatusSection = FarmTab:Section({
    Name = "Status",
    Side = 2,
})

MapLabel = StatusSection:Label("Map: Waiting for map")
RequiredLabel = StatusSection:Label("Required items: 0")
StatusLabel = StatusSection:Label("Starting...")

StatusSection:Divider()

local ControlRow = StatusSection:Button()
ControlRow:Add("Run Step", function()
    task.spawn(FarmStep)
end)
ControlRow:Add("Rescan Map", function()
    ResetMapCaches(nil)
    SetStatus("Rescanning")
end)

local ControlRow2 = StatusSection:Button()
ControlRow2:Add("Pause", function()
    State.Enabled = false

    if MasterToggle then
        pcall(function()
            MasterToggle:Set(false)
        end)
    end

    SetStatus("Paused")
end)
ControlRow2:Add("Unload", function()
    Stop()
    VibeUI:Unload()
end)

if PreviousFarm and PreviousFarm ~= API and type(PreviousFarm.Stop) == "function" then
    pcall(PreviousFarm.Stop)
end

Env.KittyAutoFarm = API

task.spawn(function()
    while State.Running do
        if State.Enabled then
            FarmStep()
        end

        task.wait(State.Delay)
    end
end)

task.spawn(FarmStep)
