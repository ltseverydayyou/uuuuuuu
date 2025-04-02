local c = {
    bg = Color3.fromRGB(30, 30, 35),
    ac = Color3.fromRGB(0, 0, 0),
    sc = Color3.fromRGB(45, 45, 50),
    tx = Color3.fromRGB(255, 255, 255),
    td = Color3.fromRGB(180, 180, 180),
    su = Color3.fromRGB(40, 180, 99),
    wa = Color3.fromRGB(255, 153, 51),
    er = Color3.fromRGB(220, 53, 69)
}

function protectUI(sGui)
    local function blankfunction(...)
        return ...
    end

    local cloneref = cloneref or blankfunction

    local function SafeGetService(service)
        return cloneref(game:GetService(service)) or game:GetService(service)
    end

    local cGUI = SafeGetService("CoreGui")
    local rPlr = SafeGetService("Players"):FindFirstChildWhichIsA("Player")
    local cGUIProtect = {}
    local rService = SafeGetService("RunService")
    local lPlr = SafeGetService("Players").LocalPlayer

    local function NAProtection(inst, var)
        if inst then
            if var then
                inst[var] = "\0"
                inst.Archivable = false
            else
                inst.Name = "\0"
                inst.Archivable = false
            end
        end
    end

    if (get_hidden_gui or gethui) then
        local hiddenUI = (get_hidden_gui or gethui)
        NAProtection(sGui)
        sGui.Parent = hiddenUI()
        return sGui
    elseif (not is_sirhurt_closure) and (syn and syn.protect_gui) then
        NAProtection(sGui)
        syn.protect_gui(sGui)
        sGui.Parent = cGUI
        return sGui
    elseif cGUI:FindFirstChildWhichIsA("ScreenGui") then
        pcall(function()
            for _, v in pairs(sGui:GetDescendants()) do
                cGUIProtect[v] = rPlr.Name
            end
            sGui.DescendantAdded:Connect(function(v)
                cGUIProtect[v] = rPlr.Name
            end)
            cGUIProtect[sGui] = rPlr.Name

            local meta = getrawmetatable(game)
            local tostr = meta.__tostring
            setreadonly(meta, false)
            meta.__tostring = newcclosure(function(t)
                if cGUIProtect[t] and not checkcaller() then
                    return cGUIProtect[t]
                end
                return tostr(t)
            end)
        end)
        if not rService:IsStudio() then
            local newGui = cGUI:FindFirstChildWhichIsA("ScreenGui")
            newGui.DescendantAdded:Connect(function(v)
                cGUIProtect[v] = rPlr.Name
            end)
            for _, v in pairs(sGui:GetChildren()) do
                v.Parent = newGui
            end
            sGui = newGui
        end
        return sGui
    elseif cGUI then
        NAProtection(sGui)
        sGui.Parent = cGUI
        return sGui
    elseif lPlr and lPlr:FindFirstChild("PlayerGui") then
        NAProtection(sGui)
        sGui.Parent = lPlr:FindFirstChild("PlayerGui")
        return sGui
    else
        return nil
    end
end

NAdrag=function(ui, dragui)
    if not dragui then dragui = ui end
    local UserInputService = game:GetService("UserInputService")

    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        local newXOffset = startPos.X.Offset + delta.X
        local newYOffset = startPos.Y.Offset + delta.Y
        
        local screenSize = ui.Parent.AbsoluteSize
        local newXScale = startPos.X.Scale + (newXOffset / screenSize.X)
        local newYScale = startPos.Y.Scale + (newYOffset / screenSize.Y)
    
        ui.Position = UDim2.new(newXScale, 0, newYScale, 0)
    end

    dragui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = ui.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
    ui.Active=true
end

local sg = Instance.new("ScreenGui")
sg.Name = "GameInfoUI"
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
protectUI(sg)

local m = Instance.new("Frame")
m.Name = "MainFrame"
m.Size = UDim2.new(0, 600, 0, 500)
m.Position = UDim2.new(0.5, -300, 0.5, -250)
m.BackgroundColor3 = c.bg
m.BorderSizePixel = 0
m.Active = true
m.ClipsDescendants = true
m.Parent = sg

local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0, 10)
mc.Parent = m

local sh = Instance.new("ImageLabel")
sh.Name = "Shadow"
sh.AnchorPoint = Vector2.new(0.5, 0.5)
sh.BackgroundTransparency = 1
sh.Position = UDim2.new(0.5, 0, 0.5, 0)
sh.Size = UDim2.new(1, 40, 1, 40)
sh.ZIndex = -1
sh.Image = "rbxassetid://5554236805"
sh.ImageColor3 = Color3.fromRGB(0, 0, 0)
sh.ImageTransparency = 0.4
sh.ScaleType = Enum.ScaleType.Slice
sh.SliceCenter = Rect.new(23, 23, 277, 277)
sh.Parent = m

local tb = Instance.new("Frame")
tb.Name = "TitleBar"
tb.Size = UDim2.new(1, 0, 0, 50)
tb.BackgroundColor3 = c.ac
tb.BorderSizePixel = 0
tb.Parent = m

local tbc = Instance.new("UICorner")
tbc.CornerRadius = UDim.new(0, 10)
tbc.Parent = tb

local t = Instance.new("TextLabel")
t.Name = "Title"
t.Size = UDim2.new(1, -120, 1, 0)
t.Position = UDim2.new(0, 15, 0, 0)
t.BackgroundTransparency = 1
t.Font = Enum.Font.GothamBold
t.Text = "Game Information"
t.TextColor3 = c.tx
t.TextSize = 20
t.TextXAlignment = Enum.TextXAlignment.Left
t.Parent = tb

local cb = Instance.new("ImageButton")
cb.Name = "CloseButton"
cb.Size = UDim2.new(0, 24, 0, 24)
cb.Position = UDim2.new(1, -32, 0.5, -12)
cb.AnchorPoint = Vector2.new(0.5, 0.5)
cb.BackgroundTransparency = 1
cb.Image = "rbxassetid://6031094678"
cb.ImageColor3 = c.tx
cb.Parent = tb

local gIcon = Instance.new("ImageLabel")
gIcon.Name = "GameIcon"
gIcon.Size = UDim2.new(0, 100, 0, 100)
gIcon.Position = UDim2.new(0, 20, 0, 60)
gIcon.BackgroundTransparency = 1
gIcon.Image = "rbxassetid://0"
gIcon.Parent = m

local gName = Instance.new("TextLabel")
gName.Name = "GameName"
gName.Size = UDim2.new(1, -140, 0, 50)
gName.Position = UDim2.new(0, 140, 0, 60)
gName.BackgroundTransparency = 1
gName.Font = Enum.Font.GothamBold
gName.Text = "Game Name"
gName.TextColor3 = c.tx
gName.TextSize = 18
gName.TextXAlignment = Enum.TextXAlignment.Left
gName.Parent = m

local gOwner = Instance.new("TextLabel")
gOwner.Name = "GameOwner"
gOwner.Size = UDim2.new(1, -140, 0, 30)
gOwner.Position = UDim2.new(0, 140, 0, 110)
gOwner.BackgroundTransparency = 1
gOwner.Font = Enum.Font.Gotham
gOwner.Text = "Owned by: Owner"
gOwner.TextColor3 = c.td
gOwner.TextSize = 14
gOwner.TextXAlignment = Enum.TextXAlignment.Left
gOwner.Parent = m

local rc = Instance.new("Frame")
rc.Name = "ContentFrame"
rc.Size = UDim2.new(1, -40, 1, -180)
rc.Position = UDim2.new(0, 20, 0, 180)
rc.BackgroundTransparency = 1
rc.BorderSizePixel = 0
rc.Parent = m

local sf = Instance.new("ScrollingFrame")
sf.Name = "ScrollingFrame"
sf.Size = UDim2.new(1, 0, 1, 0)
sf.BackgroundTransparency = 1
sf.BorderSizePixel = 0
sf.ScrollBarThickness = 6
sf.ScrollBarImageColor3 = c.ac
sf.CanvasSize = UDim2.new(0, 0, 0, 0)
sf.Parent = rc

local ul = Instance.new("UIListLayout")
ul.SortOrder = Enum.SortOrder.LayoutOrder
ul.Padding = UDim.new(0, 10)
ul.Parent = sf

cb.MouseButton1Click:Connect(function()
    sg:Destroy()
end)

NAdrag(m, tb)

local function updTxtScale(lbl)
    local width = lbl.AbsoluteSize.X
    local text = lbl.Text
    local font = lbl.Font
    local textSize = lbl.TextSize
    local textBounds = game:GetService("TextService"):GetTextSize(text, textSize, font, Vector2.new(width, math.huge))
    lbl.Size = UDim2.new(1, -20, 0, textBounds.Y + 10)
    lbl.Parent.Size = UDim2.new(1, 0, 0, textBounds.Y + 20)
end

local function addInfo(key, value)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = c.sc
    container.BorderSizePixel = 0
    container.Parent = sf

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.Text = key..": "..tostring(value)
    lbl.TextColor3 = c.tx
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = container

    updTxtScale(lbl)
end

local function addDropdown(key, tbl)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundColor3 = c.sc
    container.BorderSizePixel = 0
    container.Parent = sf

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = container

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -40, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.Text = key
    lbl.TextColor3 = c.tx
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 30, 0, 30)
    btn.Position = UDim2.new(1, -35, 0.5, -15)
    btn.BackgroundColor3 = c.ac
    btn.Text = "+"
    btn.TextColor3 = c.tx
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = container

    local cornerBtn = Instance.new("UICorner")
    cornerBtn.CornerRadius = UDim.new(0, 8)
    cornerBtn.Parent = btn

    local expanded = false
    local subFrames = {}

    btn.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            btn.Text = "-"
            for subKey, subValue in pairs(tbl) do
                local subContainer = Instance.new("Frame")
                subContainer.Size = UDim2.new(0.9, 0, 0, 30)
                subContainer.Position = UDim2.new(0.1, 0, 0, 0)
                subContainer.BackgroundColor3 = c.sc
                subContainer.BorderSizePixel = 0
                subContainer.Parent = sf
                subContainer.Name = key.."_SubFrame"

                local subCorner = Instance.new("UICorner")
                subCorner.CornerRadius = UDim.new(0, 8)
                subCorner.Parent = subContainer

                local subLbl = Instance.new("TextLabel")
                subLbl.Size = UDim2.new(1, -20, 1, 0)
                subLbl.Position = UDim2.new(0, 10, 0, 0)
                subLbl.BackgroundTransparency = 1
                subLbl.Font = Enum.Font.Gotham
                subLbl.Text = subKey..": "..tostring(subValue)
                subLbl.TextColor3 = c.td
                subLbl.TextSize = 12
                subLbl.TextXAlignment = Enum.TextXAlignment.Left
                subLbl.TextWrapped = true
                subLbl.Parent = subContainer

                table.insert(subFrames, subContainer)
            end
        else
            btn.Text = "+"
            for _, subFrame in ipairs(subFrames) do
                subFrame:Destroy()
            end
            subFrames = {}
        end
        sf.CanvasSize = UDim2.new(0, 0, 0, ul.AbsoluteContentSize.Y)
    end)
end

local function displayGameInfo()
    local gameInfo = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    gIcon.Image = "https://assetgame.roblox.com/Game/Tools/ThumbnailAsset.ashx?aid="..gameInfo.IconImageAssetId.."&fmt=png&wd=1920&ht=1080"
    gName.Text = gameInfo.Name
    gOwner.Text = "Owned by: "..gameInfo.Creator.Name

    for key, value in pairs(gameInfo) do
        if key ~= "Creator" and key ~= "ProductId" then
            addInfo(key, value)
        end
    end

    addDropdown("Creator", gameInfo.Creator)

    sf.CanvasSize = UDim2.new(0, 0, 0, ul.AbsoluteContentSize.Y)
end

displayGameInfo()