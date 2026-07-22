local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local env = getgenv()

if env.RaisePeter then
    env.RaisePeter.Running = false
    if env.RaisePeter.Gui then
        pcall(function()
            env.RaisePeter.Gui:Destroy()
        end)
    end
end

local state = {
    Running = true,
    AutoClick = true,
    AutoBuy = true,
    AutoCollect = true,
    AutoSave = true,
    AutoDelivery = true,
    AutoFood = true,
    LastPurchase = "None",
    LastAction = "Started",
    SaveStatus = "Waiting",
    Collected = 0,
    Unboxed = 0,
    FileName = "RaisePeter.lua"
}

env.RaisePeter = state

local safeItems = {
    ["Ammo Crate 1"] = true,
    ["Ammo Crate 2"] = true,
    ["Ammo Crate 3"] = true,
    ["Ammo Crate 4"] = true,
    ["Ammo Crate 5"] = true,
    ["Anti Theft Detector"] = true,
    ["Ball Pit"] = true,
    ["Cabinet 1"] = true,
    ["Cabinet 2"] = true,
    ["Cabinet 3"] = true,
    ["Carpet"] = true,
    ["Chair"] = true,
    ["Chicken Coop"] = true,
    ["Clock"] = true,
    ["Coffee Machine"] = true,
    ["Coop Food"] = true,
    ["Coop Stairs"] = true,
    ["Coop Straw"] = true,
    ["Coop Trough"] = true,
    ["Coop Upper Area"] = true,
    ["Couch"] = true,
    ["Counter 1"] = true,
    ["Counter 2"] = true,
    ["Counter 3"] = true,
    ["Counter 4"] = true,
    ["Fireplace"] = true,
    ["Fishing Rods"] = true,
    ["Fridge Top Shelf"] = true,
    ["Garden"] = true,
    ["Greenhouse"] = true,
    ["Kitchen Wallpaper"] = true,
    ["Lanterns"] = true,
    ["Lightning Rod"] = true,
    ["Living Room Wallpaper"] = true,
    ["Microwave"] = true,
    ["Military Tent"] = true,
    ["Net 1"] = true,
    ["Net 2"] = true,
    ["Oven"] = true,
    ["Phone"] = true,
    ["Pickaxe"] = true,
    ["Pier"] = true,
    ["Pier Roofing"] = true,
    ["Plant"] = true,
    ["Planter 1"] = true,
    ["Planter 2"] = true,
    ["Planter 3"] = true,
    ["Planter 4"] = true,
    ["Planter 5"] = true,
    ["Planter 6"] = true,
    ["Planter 7"] = true,
    ["Planter 8"] = true,
    ["Planter 9"] = true,
    ["Planter 10"] = true,
    ["Side Table"] = true,
    ["Sink"] = true,
    ["Siren"] = true,
    ["Speaker"] = true,
    ["Sprinklers"] = true,
    ["TV"] = true,
    ["Traffic Lights"] = true,
    ["Turret 1"] = true,
    ["Turret 2"] = true,
    ["Workbench"] = true
}

local function getDataValues()
    return workspace:FindFirstChild("DataValues")
end

local function getRoot()
    local character = LocalPlayer.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local character = LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function getValue(name)
    local dataValues = getDataValues()
    local value = dataValues and dataValues:FindFirstChild(name)
    return value and value.Value or 0
end

local function triggerPrompt(prompt)
    if not prompt or not prompt.Parent then
        return false
    end
    local ok = pcall(function()
        fireproximityprompt(prompt)
    end)
    return ok
end

local function triggerTouch(part)
    local root = getRoot()
    if not root or not part or not part.Parent then
        return false
    end
    local collected = part:FindFirstChild("Collected")
    if collected and collected.Value then
        return false
    end
    local ok = pcall(function()
        firetouchinterest(root, part, 0)
        task.wait()
        firetouchinterest(root, part, 1)
    end)
    if ok then
        state.Collected += 1
    end
    return ok
end

local shopData
local function refreshShopData()
    local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
    local getter = remotes and remotes:FindFirstChild("GetShopData")
    if getter then
        local ok, result = pcall(function()
            return getter:InvokeServer()
        end)
        if ok and type(result) == "table" then
            shopData = result
        end
    end
end

local function getOwnedValue(item)
    local dataValues = getDataValues()
    local folder = dataValues and dataValues:FindFirstChild(item.Folder)
    if not folder then
        return nil
    end
    return folder:FindFirstChild(item.Name .. "Owned")
end

local function getCurrencyAmount(currency)
    if currency == "Feather" or currency == "Feathers" then
        return getValue("Feather")
    end
    return getValue("Money")
end

local function buyNextSafeItem()
    if type(shopData) ~= "table" then
        refreshShopData()
    end
    if type(shopData) ~= "table" then
        return
    end
    local candidates = {}
    for _, item in pairs(shopData) do
        if type(item) == "table" and safeItems[item.Name] and type(item.Price) == "number" then
            local owned = getOwnedValue(item)
            if owned and not owned.Value and getCurrencyAmount(item.Currency) >= item.Price then
                table.insert(candidates, item)
            end
        end
    end
    table.sort(candidates, function(a, b)
        return a.Price < b.Price
    end)
    local item = candidates[1]
    if not item then
        return
    end
    local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
    local purchase = remotes and remotes:FindFirstChild("Purchase")
    if not purchase then
        return
    end
    local ok, success = pcall(function()
        return purchase:InvokeServer(item.Name)
    end)
    if ok and success then
        state.LastPurchase = item.Name
        state.LastAction = "Purchased " .. item.Name
    end
end

local function findPeterClickDetector()
    local interactables = workspace:FindFirstChild("Interactables")
    local peterFolder = interactables and interactables:FindFirstChild("Peter")
    local peter = peterFolder and peterFolder:FindFirstChild("Peter")
    local clickable = peter and peter:FindFirstChild("Clickable")
    return clickable and clickable:FindFirstChild("DropMoney")
end

local function collectMoney()
    local interactables = workspace:FindFirstChild("Interactables")
    if not interactables then
        return
    end
    local bills = interactables:FindFirstChild("MoneyBills")
    if bills then
        for _, part in ipairs(bills:GetChildren()) do
            if part:IsA("BasePart") then
                triggerTouch(part)
            end
        end
    end
    local bagFolder = interactables:FindFirstChild("BagFolder")
    local bag = bagFolder and bagFolder:FindFirstChild("Bag")
    if bag and bag:IsA("BasePart") then
        triggerTouch(bag)
    end
end

local function getDeliveryBoxes()
    local boxes = {}
    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "DeliveryBox" and child:IsA("Model") then
            table.insert(boxes, child)
        end
    end
    return boxes
end

local unboxing = setmetatable({}, {__mode = "k"})
local function handleDeliveries()
    local boxes = getDeliveryBoxes()
    if #boxes == 0 then
        return
    end
    local interactables = workspace:FindFirstChild("Interactables")
    local objects = interactables and interactables:FindFirstChild("Objects")
    local frontDoor = objects and objects:FindFirstChild("FrontDoor")
    local doors = frontDoor and frontDoor:FindFirstChild("Doors")
    local interactionPart = doors and doors:FindFirstChild("InteractionPart")
    local attachment = interactionPart and interactionPart:FindFirstChild("DoorAttachment")
    local doorPrompt = attachment and attachment:FindFirstChildOfClass("ProximityPrompt")
    if doorPrompt and doorPrompt.Enabled and doorPrompt.ActionText == "Open" then
        triggerPrompt(doorPrompt)
        state.LastAction = "Opened front door"
    end
    for _, box in ipairs(boxes) do
        if not unboxing[box] then
            local prompt = box:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and prompt.Enabled and prompt.ActionText == "Unbox" then
                unboxing[box] = true
                if triggerPrompt(prompt) then
                    state.Unboxed += 1
                    state.LastAction = "Unboxed delivery"
                end
            end
        end
    end
end

local function getBorgirTools()
    local tools = {}
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local character = LocalPlayer.Character
    for _, container in ipairs({backpack, character}) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Tool") and child.Name == "Borgir" and child:GetAttribute("Radiation") ~= true then
                    table.insert(tools, child)
                end
            end
        end
    end
    return tools
end

local function equipTool(tool)
    local humanoid = getHumanoid()
    if humanoid and tool and tool.Parent then
        pcall(function()
            humanoid:EquipTool(tool)
        end)
        task.wait(0.15)
        return tool.Parent == LocalPlayer.Character
    end
    return false
end

local function storePaidBurger(tool)
    if not tool or not tool.Parent or tool:GetAttribute("NotBought") == true then
        return false
    end
    local interactables = workspace:FindFirstChild("Interactables")
    local objects = interactables and interactables:FindFirstChild("Objects")
    local fridge = objects and objects:FindFirstChild("Fridge")
    if not fridge then
        return false
    end
    local maxFood = fridge:FindFirstChild("MaxFood")
    if maxFood and getValue("Food") >= maxFood.Value then
        return false
    end
    if not equipTool(tool) then
        return false
    end
    local doors = fridge:FindFirstChild("Doors")
    local interactionPart = doors and doors:FindFirstChild("InteractionPart")
    local doorAttachment = interactionPart and interactionPart:FindFirstChild("DoorAttachment")
    local refillAttachment = interactionPart and interactionPart:FindFirstChild("RefillAttachment")
    local openPrompt = doorAttachment and doorAttachment:FindFirstChild("ProximityPromptOpen")
    local refillPrompt = refillAttachment and refillAttachment:FindFirstChild("ProximityPromptRefill")
    if openPrompt and openPrompt.Enabled and openPrompt.ActionText == "Open" then
        triggerPrompt(openPrompt)
        task.wait(0.25)
    end
    if refillPrompt and refillPrompt.Enabled then
        local before = getValue("Food")
        triggerPrompt(refillPrompt)
        task.wait(0.35)
        if getValue("Food") > before or not tool.Parent then
            state.LastAction = "Stored burger in fridge"
            return true
        end
    end
    return false
end

local function payForBurger(tool)
    if not tool or not tool.Parent or tool:GetAttribute("NotBought") ~= true or getValue("Money") < 25 then
        return false
    end
    if not equipTool(tool) then
        return false
    end
    local scenery = workspace:FindFirstChild("Scenery")
    local gasStation = scenery and scenery:FindFirstChild("GasStation")
    local store = gasStation and gasStation:FindFirstChild("GasStationStore")
    local carl = store and store:FindFirstChild("Carl")
    local decalpart = carl and carl:FindFirstChild("Decalpart")
    local attachment = decalpart and decalpart:FindFirstChild("Attachment")
    local prompt = attachment and attachment:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        return false
    end
    local before = getValue("Money")
    triggerPrompt(prompt)
    task.wait(0.35)
    if tool.Parent and tool:GetAttribute("NotBought") ~= true then
        state.LastAction = "Paid $25 for burger"
        return true
    end
    if getValue("Money") <= before - 25 then
        state.LastAction = "Paid $25 for burger"
        return true
    end
    return false
end

local function pickUpBurger()
    if getValue("Money") < 25 then
        return false
    end
    local shop = workspace:FindFirstChild("Shop")
    local burgers = shop and shop:FindFirstChild("Burgers")
    if not burgers then
        return false
    end
    for _, item in ipairs(burgers:GetChildren()) do
        local prompt = item:FindFirstChildOfClass("ProximityPrompt")
        if prompt and prompt.Enabled and prompt.ActionText == "Pick Up" then
            local before = #getBorgirTools()
            triggerPrompt(prompt)
            task.wait(0.25)
            if #getBorgirTools() > before then
                state.LastAction = "Picked up burger"
                return true
            end
        end
    end
    return false
end

local function handleFood()
    local interactables = workspace:FindFirstChild("Interactables")
    local objects = interactables and interactables:FindFirstChild("Objects")
    local fridge = objects and objects:FindFirstChild("Fridge")
    local maxFood = fridge and fridge:FindFirstChild("MaxFood")
    if not fridge or not maxFood or getValue("Food") >= maxFood.Value then
        return
    end
    local tools = getBorgirTools()
    for _, tool in ipairs(tools) do
        if tool:GetAttribute("NotBought") ~= true and storePaidBurger(tool) then
            return
        end
    end
    for _, tool in ipairs(tools) do
        if tool:GetAttribute("NotBought") == true then
            if getValue("Money") >= 25 then
                payForBurger(tool)
            else
                local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
                if backpack and tool.Parent == LocalPlayer.Character then
                    tool.Parent = backpack
                end
                state.LastAction = "Waiting for $25 to buy burger"
            end
            return
        end
    end
    pickUpBurger()
end

local guiParent = CoreGui
pcall(function()
    if gethui then
        guiParent = gethui()
    end
end)

local oldGui = guiParent:FindFirstChild("RaisePeter")
if oldGui then
    oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "RaisePeter"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = guiParent
state.Gui = gui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(290, 390)
main.Position = UDim2.new(0.5, -145, 0.5, -195)
main.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.65
stroke.Thickness = 1
stroke.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -52, 0, 42)
title.Position = UDim2.fromOffset(14, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "Raise a Peter"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(34, 34)
close.Position = UDim2.new(1, -40, 0, 4)
close.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
close.BorderSizePixel = 0
close.Font = Enum.Font.GothamBold
close.Text = "×"
close.TextColor3 = Color3.fromRGB(255, 255, 255)
close.TextSize = 20
close.Parent = main
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 9)

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -24, 0, 1)
divider.Position = UDim2.fromOffset(12, 42)
divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
divider.BackgroundTransparency = 0.75
divider.BorderSizePixel = 0
divider.Parent = main

local keys = {
    {"Auto Click Peter", "AutoClick"},
    {"Auto Buy Upgrades", "AutoBuy"},
    {"Auto Collect Money", "AutoCollect"},
    {"Auto Save", "AutoSave"},
    {"Auto Delivery + Unbox", "AutoDelivery"},
    {"Auto Food", "AutoFood"}
}

local buttons = {}
for index, entry in ipairs(keys) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -24, 0, 38)
    button.Position = UDim2.fromOffset(12, 50 + (index - 1) * 43)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamMedium
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 14
    button.Parent = main
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 9)
    buttons[entry[2]] = {Button = button, Label = entry[1]}
    button.MouseButton1Click:Connect(function()
        state[entry[2]] = not state[entry[2]]
    end)
end

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 76)
status.Position = UDim2.fromOffset(12, 314)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Code
status.TextColor3 = Color3.fromRGB(220, 220, 220)
status.TextSize = 12
status.TextWrapped = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Parent = main

local dragging = false
local dragStart
local startPosition
local dragInput

main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

main.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
    end
end)

close.MouseButton1Click:Connect(function()
    state.Running = false
    gui:Destroy()
end)

state.Stop = function()
    state.Running = false
    if gui and gui.Parent then
        gui:Destroy()
    end
end

refreshShopData()

task.spawn(function()
    while state.Running do
        if state.AutoClick then
            local detector = findPeterClickDetector()
            if detector then
                pcall(function()
                    fireclickdetector(detector)
                end)
            end
        end
        task.wait(0.08)
    end
end)

task.spawn(function()
    while state.Running do
        if state.AutoCollect then
            collectMoney()
        end
        task.wait(0.2)
    end
end)

task.spawn(function()
    while state.Running do
        if state.AutoBuy then
            buyNextSafeItem()
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while state.Running do
        if state.AutoDelivery then
            handleDeliveries()
        end
        task.wait(0.35)
    end
end)

task.spawn(function()
    while state.Running do
        if state.AutoFood then
            handleFood()
        end
        task.wait(0.65)
    end
end)

task.spawn(function()
    while state.Running do
        if state.AutoSave then
            local remotes = ReplicatedStorage:FindFirstChild("RemoteEvents")
            local save = remotes and remotes:FindFirstChild("Save")
            if save then
                local ok = pcall(function()
                    save:FireServer()
                end)
                state.SaveStatus = ok and "Game saved" or "Save failed"
                if ok then
                    state.LastAction = "Game saved"
                end
            end
        end
        task.wait(30)
    end
end)

task.spawn(function()
    while state.Running and gui.Parent do
        for key, data in pairs(buttons) do
            local enabled = state[key]
            data.Button.Text = data.Label .. ": " .. (enabled and "ON" or "OFF")
            data.Button.BackgroundColor3 = enabled and Color3.fromRGB(55, 55, 55) or Color3.fromRGB(24, 24, 24)
        end
        local fridge
        local interactables = workspace:FindFirstChild("Interactables")
        local objects = interactables and interactables:FindFirstChild("Objects")
        fridge = objects and objects:FindFirstChild("Fridge")
        local maxFood = fridge and fridge:FindFirstChild("MaxFood")
        status.Text = string.format(
            "Money: %s | Feathers: %s | Food: %s/%s\nLast purchase: %s\nAction: %s\nSaved file: %s",
            tostring(getValue("Money")),
            tostring(getValue("Feather")),
            tostring(getValue("Food")),
            tostring(maxFood and maxFood.Value or "?"),
            tostring(state.LastPurchase),
            tostring(state.LastAction),
            state.FileName
        )
        task.wait(0.25)
    end
end)
