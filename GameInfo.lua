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

local function ClonedService(name)
    local Service = (game.GetService);
	local Reference = (cloneref) or function(reference) return reference end
	return Reference(Service(game, name));
end

local function protectUI(sGui)
    if sGui:IsA("ScreenGui") then
        sGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
		sGui.DisplayOrder = 999999999
		sGui.ResetOnSpawn = false
		sGui.IgnoreGuiInset = true
    end
    local cGUI = ClonedService("CoreGui")
    local lPlr = ClonedService("Players").LocalPlayer

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

    if gethui then
		NAProtection(sGui)
		sGui.Parent = gethui()
		return sGui
	elseif cGUI and cGUI:FindFirstChild("RobloxGui") then
		NAProtection(sGui)
		sGui.Parent = cGUI:FindFirstChild("RobloxGui")
		return sGui
	elseif cGUI then
		NAProtection(sGui)
		sGui.Parent = cGUI
		return sGui
	elseif lPlr and lPlr:FindFirstChildWhichIsA("PlayerGui") then
		NAProtection(sGui)
		sGui.Parent = lPlr:FindFirstChildWhichIsA("PlayerGui")
		sGui.ResetOnSpawn = false
		return sGui
	else
		return nil
	end
end

NAdrag = function(ui, dragui)
    if not dragui then dragui = ui end
    local UserInputService = ClonedService("UserInputService")
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
    ui.Active = true
end

local sg = Instance.new("ScreenGui")
sg.Name = "GameInfoUI"
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
protectUI(sg)

local m = Instance.new("Frame")
m.Name = "MainFrame"
m.Size = UDim2.new(0.9, 0, 0.9, 0)
m.Position = UDim2.new(0.05, 0, 0.05, 0)
m.BackgroundColor3 = c.bg
m.BorderSizePixel = 0
m.Active = true
m.ClipsDescendants = true
m.Parent = sg

local originalSize = m.Size

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
t.Size = UDim2.new(1, -140, 1, 0)
t.Position = UDim2.new(0, 15, 0, 0)
t.BackgroundTransparency = 1
t.Font = Enum.Font.GothamBold
t.Text = "Game Information"
t.TextColor3 = c.tx
t.TextSize = 20
t.TextXAlignment = Enum.TextXAlignment.Left
t.Parent = tb

local mb = Instance.new("TextButton")
mb.Name = "MinimizeButton"
mb.Size = UDim2.new(0, 24, 0, 24)
mb.Position = UDim2.new(1, -60, 0.5, -12)
mb.AnchorPoint = Vector2.new(0.5, 0.5)
mb.BackgroundTransparency = 1
mb.Text = "_"
mb.TextColor3 = c.tx
mb.Font = Enum.Font.GothamBold
mb.TextSize = 14
mb.Parent = tb

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

local minimized = false
mb.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        gIcon.Visible = false
        gName.Visible = false
        gOwner.Visible = false
        rc.Visible = false
        m:TweenSize(UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 50), "Out", "Quad", 0.3, true)
        mb.Text = "+"
    else
        gIcon.Visible = true
        gName.Visible = true
        gOwner.Visible = true
        rc.Visible = true
        m:TweenSize(originalSize, "Out", "Quad", 0.3, true)
        mb.Text = "_"
    end
end)

NAdrag(m, tb)

local function updTxtScale(lbl)
    local width = lbl.AbsoluteSize.X
    local text = lbl.Text
    local font = lbl.Font
    local textSize = lbl.TextSize
    local textBounds = ClonedService("TextService"):GetTextSize(text, textSize, font, Vector2.new(width, math.huge))
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
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundTransparency = 1
    header.Parent = container
    local headerLbl = Instance.new("TextLabel")
    headerLbl.Size = UDim2.new(1, -40, 1, 0)
    headerLbl.Position = UDim2.new(0, 10, 0, 0)
    headerLbl.BackgroundTransparency = 1
    headerLbl.Font = Enum.Font.Gotham
    headerLbl.Text = key
    headerLbl.TextColor3 = c.tx
    headerLbl.TextSize = 14
    headerLbl.TextXAlignment = Enum.TextXAlignment.Left
    headerLbl.Parent = header
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 30, 0, 30)
    btn.Position = UDim2.new(1, -35, 0.5, -15)
    btn.BackgroundColor3 = c.ac
    btn.Text = "+"
    btn.TextColor3 = c.tx
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = header
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    local content = Instance.new("Frame")
    content.Name = "DropdownContent"
    content.Size = UDim2.new(1, 0, 0, 0)
    content.Position = UDim2.new(0, 0, 0.2, 0)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true
    content.Parent = container
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content
    local expanded = false
    btn.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            btn.Text = "-"
            for subKey, subValue in pairs(tbl) do
                local subContainer = Instance.new("Frame")
                subContainer.Size = UDim2.new(1, -20, 0, 30)
                subContainer.BackgroundColor3 = c.sc
                subContainer.BorderSizePixel = 0
                subContainer.Parent = content
                local subCorner = Instance.new("UICorner")
                subCorner.CornerRadius = UDim.new(0, 8)
                subCorner.Parent = subContainer
                local subLbl = Instance.new("TextLabel")
                subLbl.Size = UDim2.new(1, -10, 1, 0)
                subLbl.Position = UDim2.new(0, 5, 0, 0)
                subLbl.BackgroundTransparency = 1
                subLbl.Font = Enum.Font.Gotham
                subLbl.Text = subKey..": "..tostring(subValue)
                subLbl.TextColor3 = c.td
                subLbl.TextSize = 12
                subLbl.TextXAlignment = Enum.TextXAlignment.Left
                subLbl.TextWrapped = true
                subLbl.Parent = subContainer
            end
            wait()
            local contentHeight = layout.AbsoluteContentSize.Y
            content.Size = UDim2.new(1, 0, 0, contentHeight)
            container.Size = UDim2.new(1, 0, 0, 50 + contentHeight)
        else
            btn.Text = "+"
            for _, child in pairs(content:GetChildren()) do
                if child:IsA("Frame") then
                    child:Destroy()
                end
            end
            content.Size = UDim2.new(1, 0, 0, 0)
            container.Size = UDim2.new(1, 0, 0, 50)
        end
        sf.CanvasSize = UDim2.new(0, 0, 0, ul.AbsoluteContentSize.Y)
    end)
end

local function displayGameInfo()
    local gameInfo = ClonedService("MarketplaceService"):GetProductInfo(game.PlaceId)
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