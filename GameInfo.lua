local c = {
    bg = Color3.fromRGB(20, 22, 28),
    ac = Color3.fromRGB(14, 15, 18),
    sc = Color3.fromRGB(36, 38, 46),
    tx = Color3.fromRGB(235, 238, 245),
    td = Color3.fromRGB(164, 170, 186),
    ux = Color3.fromRGB(64, 132, 255),
    gx = Color3.fromRGB(140, 99, 255),
    ok = Color3.fromRGB(52, 199, 89),
    warn = Color3.fromRGB(255, 186, 65),
    stop = Color3.fromRGB(232, 62, 67)
}

local function ClonedService(name)
    local Service = (game.GetService)
    local Reference = (cloneref) or function(r) return r end
    return Reference(Service(game, name))
end

local function protectUI(sGui)
    if sGui:IsA("ScreenGui") then
        sGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
        sGui.DisplayOrder = 2147483647
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

local TweenService = ClonedService("TweenService")
local TextService = ClonedService("TextService")
local HttpService = ClonedService("HttpService")
local UIS = ClonedService("UserInputService")
local MarketplaceService = ClonedService("MarketplaceService")

local function NAdrag(ui, dragui)
    dragui = dragui or ui
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        local s = ui.Parent.AbsoluteSize
        local nx = math.clamp(startPos.X.Scale + (startPos.X.Offset + delta.X)/s.X, 0, 1)
        local ny = math.clamp(startPos.Y.Scale + (startPos.Y.Offset + delta.Y)/s.Y, 0, 1)
        ui.Position = UDim2.new(nx, 0, ny, 0)
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
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
    ui.Active = true
end

local function ripple(btn)
    btn.ClipsDescendants = true
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local rel = Vector2.new(input.Position.X - btn.AbsolutePosition.X, input.Position.Y - btn.AbsolutePosition.Y)
            local c0 = Instance.new("Frame")
            c0.BackgroundColor3 = Color3.fromRGB(255,255,255)
            c0.BackgroundTransparency = 0.75
            c0.AnchorPoint = Vector2.new(0.5,0.5)
            c0.Position = UDim2.fromOffset(rel.X, rel.Y)
            c0.Size = UDim2.fromOffset(0,0)
            c0.ZIndex = 10
            c0.Parent = btn
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1,0)
            corner.Parent = c0
            local d = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2
            TweenService:Create(c0, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(d,d), BackgroundTransparency = 1}):Play()
            task.delay(0.4, function() c0:Destroy() end)
        end
    end)
end

local function lerpColor(a, b, t)
    return Color3.new(a.R + (b.R - a.R)*t, a.G + (b.G - a.G)*t, a.B + (b.B - a.B)*t)
end

local sg = Instance.new("ScreenGui")
sg.Name = "\0"
protectUI(sg)

local root = Instance.new("Frame")
root.AnchorPoint = Vector2.new(0.5,0.5)
root.Position = UDim2.fromScale(0.5,0.5)
root.Size = UDim2.fromScale(0.64,0.6)
root.BackgroundColor3 = c.bg
root.BorderSizePixel = 0
root.ClipsDescendants = true
root.Parent = sg

local rootCorner = Instance.new("UICorner")
rootCorner.CornerRadius = UDim.new(0,14)
rootCorner.Parent = root

local stroke = Instance.new("UIStroke")
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Color = Color3.fromRGB(64,66,74)
stroke.Transparency = 0.55
stroke.Thickness = 1
stroke.Parent = root

local topbar = Instance.new("Frame")
topbar.Size = UDim2.new(1,0,0,54)
topbar.BackgroundColor3 = c.ac
topbar.BorderSizePixel = 0
topbar.Parent = root

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0,14)
topCorner.Parent = topbar

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.new(0,16,0,0)
title.Size = UDim2.new(1,-200,1,0)
title.Font = Enum.Font.GothamBold
title.Text = "Game Information"
title.TextSize = 18
title.TextColor3 = c.tx
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topbar

local ctrl = Instance.new("Frame")
ctrl.BackgroundTransparency = 1
ctrl.Size = UDim2.new(0,180,1,0)
ctrl.Position = UDim2.new(1,-188,0,0)
ctrl.Parent = topbar

local ctrlList = Instance.new("UIListLayout")
ctrlList.FillDirection = Enum.FillDirection.Horizontal
ctrlList.HorizontalAlignment = Enum.HorizontalAlignment.Right
ctrlList.VerticalAlignment = Enum.VerticalAlignment.Center
ctrlList.Padding = UDim.new(0,8)
ctrlList.Parent = ctrl

local function makeTextButton(txt, baseColor)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.Size = UDim2.fromOffset(34,34)
    b.BackgroundColor3 = baseColor
    b.Font = Enum.Font.GothamBold
    b.Text = txt
    b.TextSize = 16
    b.TextColor3 = c.tx
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,8); cr.Parent = b
    local st = Instance.new("UIStroke"); st.Thickness = 1; st.Transparency = 0.5; st.Color = lerpColor(baseColor, Color3.new(0,0,0), 0.5); st.Parent = b
    b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = lerpColor(baseColor, Color3.new(1,1,1), 0.06)}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = baseColor}):Play() end)
    ripple(b)
    return b
end

local btnRefresh = makeTextButton("🔃", c.ux); btnRefresh.Parent = ctrl
local btnMin = makeTextButton("V", c.warn); btnMin.Parent = ctrl
local btnClose = makeTextButton("X", c.stop); btnClose.Parent = ctrl

local header = Instance.new("Frame")
header.BackgroundTransparency = 1
header.ClipsDescendants = true
header.Position = UDim2.new(0,0,0,54)
header.Size = UDim2.new(1,0,0,96)
header.Parent = root

local gIcon = Instance.new("ImageLabel")
gIcon.BackgroundTransparency = 1
gIcon.Size = UDim2.fromOffset(78,78)
gIcon.Position = UDim2.new(0,18,0.5,-39)
gIcon.Image = "rbxassetid://0"
gIcon.Parent = header

local gName = Instance.new("TextLabel")
gName.BackgroundTransparency = 1
gName.Position = UDim2.new(0,110,0,12)
gName.Size = UDim2.new(1,-130,0,34)
gName.Font = Enum.Font.GothamMedium
gName.Text = "Game Name"
gName.TextSize = 20
gName.TextColor3 = c.tx
gName.TextXAlignment = Enum.TextXAlignment.Left
gName.Parent = header

local gOwner = Instance.new("TextLabel")
gOwner.BackgroundTransparency = 1
gOwner.Position = UDim2.new(0,110,0,48)
gOwner.Size = UDim2.new(1,-130,0,28)
gOwner.Font = Enum.Font.Gotham
gOwner.Text = "Owned by: Owner"
gOwner.TextSize = 14
gOwner.TextColor3 = c.td
gOwner.TextXAlignment = Enum.TextXAlignment.Left
gOwner.Parent = header

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.new(0,0,0,150)
content.Size = UDim2.new(1,0,1,-150)
content.Parent = root

local listContainer = Instance.new("ScrollingFrame")
listContainer.BackgroundTransparency = 1
listContainer.BorderSizePixel = 0
listContainer.Size = UDim2.fromScale(1,1)
listContainer.CanvasSize = UDim2.new()
listContainer.ScrollBarThickness = 6
listContainer.ScrollBarImageColor3 = Color3.fromRGB(100,102,110)
listContainer.Parent = content

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0,16)
pad.PaddingRight = UDim.new(0,16)
pad.PaddingTop = UDim.new(0,14)
pad.PaddingBottom = UDim.new(0,14)
pad.Parent = listContainer

local vlist = Instance.new("UIListLayout")
vlist.SortOrder = Enum.SortOrder.LayoutOrder
vlist.Padding = UDim.new(0,10)
vlist.Parent = listContainer

vlist:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    listContainer.CanvasSize = UDim2.new(0,0,0,vlist.AbsoluteContentSize.Y + pad.PaddingTop.Offset + pad.PaddingBottom.Offset)
end)

local function card(h, borderColor)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = c.sc
    f.Size = UDim2.new(1,0,0,h)
    f.BorderSizePixel = 0
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,12); cr.Parent = f
    local st = Instance.new("UIStroke"); st.Thickness = 1; st.Transparency = 0.45; st.Color = borderColor or Color3.fromRGB(64,66,74); st.Parent = f
    return f
end

local function autoRowHeight(row, kLbl, vLbl, leftScale)
    local w = row.AbsoluteSize.X - 24
    local lw = math.floor(w * leftScale)
    local rw = w - lw - 12
    local kh = TextService:GetTextSize(kLbl.Text, kLbl.TextSize, kLbl.Font, Vector2.new(lw, 1e6)).Y
    local vh = TextService:GetTextSize(vLbl.Text, vLbl.TextSize, vLbl.Font, Vector2.new(rw, 1e6)).Y
    local h = math.max(kh, vh) + 16
    row.Size = UDim2.new(1,0,0,h)
end

local accent = c.ux

local function addRow(k, v)
    local r = card(44, lerpColor(accent, Color3.new(0,0,0), 0.35))
    r.Parent = listContainer
    r.Visible = false
    local inner = Instance.new("Frame")
    inner.BackgroundTransparency = 1
    inner.Position = UDim2.new(0,12,0,8)
    inner.Size = UDim2.new(1,-24,1,-16)
    inner.Parent = r
    local hlist = Instance.new("UIListLayout")
    hlist.FillDirection = Enum.FillDirection.Horizontal
    hlist.HorizontalAlignment = Enum.HorizontalAlignment.Left
    hlist.VerticalAlignment = Enum.VerticalAlignment.Top
    hlist.Padding = UDim.new(0,12)
    hlist.Parent = inner
    local kLbl = Instance.new("TextLabel")
    kLbl.BackgroundTransparency = 1
    kLbl.Size = UDim2.new(0.35,0,1,0)
    kLbl.Font = Enum.Font.GothamMedium
    kLbl.Text = tostring(k)
    kLbl.TextSize = 14
    kLbl.TextColor3 = c.td
    kLbl.TextXAlignment = Enum.TextXAlignment.Left
    kLbl.TextWrapped = true
    kLbl.Parent = inner
    local vLbl = Instance.new("TextLabel")
    vLbl.BackgroundTransparency = 1
    vLbl.Size = UDim2.new(0.65,0,1,0)
    vLbl.Font = Enum.Font.Gotham
    vLbl.Text = typeof(v) == "table" and HttpService:JSONEncode(v) or tostring(v)
    vLbl.TextSize = 14
    vLbl.TextColor3 = c.tx
    vLbl.TextXAlignment = Enum.TextXAlignment.Left
    vLbl.TextWrapped = true
    vLbl.Parent = inner
    task.defer(function()
        autoRowHeight(r, kLbl, vLbl, 0.35)
        r:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() autoRowHeight(r, kLbl, vLbl, 0.35) end)
        kLbl:GetPropertyChangedSignal("Text"):Connect(function() autoRowHeight(r, kLbl, vLbl, 0.35) end)
        vLbl:GetPropertyChangedSignal("Text"):Connect(function() autoRowHeight(r, kLbl, vLbl, 0.35) end)
        r.Visible = true
        r.BackgroundTransparency = 1
        TweenService:Create(r, TweenInfo.new(0.18), {BackgroundTransparency = 0}):Play()
    end)
end

local function addDropdown(titleText, tbl)
    local container = card(56, lerpColor(accent, Color3.new(0,0,0), 0.35))
    container.Parent = listContainer
    local headerRow = Instance.new("Frame")
    headerRow.BackgroundTransparency = 1
    headerRow.Position = UDim2.new(0,12,0,0)
    headerRow.Size = UDim2.new(1,-24,0,56)
    headerRow.Parent = container
    local hl = Instance.new("TextLabel")
    hl.BackgroundTransparency = 1
    hl.Size = UDim2.new(1,-44,1,0)
    hl.Font = Enum.Font.GothamMedium
    hl.Text = titleText
    hl.TextSize = 15
    hl.TextColor3 = c.tx
    hl.TextXAlignment = Enum.TextXAlignment.Left
    hl.Parent = headerRow
    local toggle = makeTextButton("V", c.warn)
    toggle.Size = UDim2.fromOffset(32,32)
    toggle.Position = UDim2.new(1,-32,0.5,-16)
    toggle.Parent = headerRow
    local contentFrame = Instance.new("Frame")
    contentFrame.BackgroundTransparency = 1
    contentFrame.ClipsDescendants = true
    contentFrame.Position = UDim2.new(0,12,0,56)
    contentFrame.Size = UDim2.new(1,-24,0,0)
    contentFrame.Parent = container
    local subList = Instance.new("UIListLayout")
    subList.SortOrder = Enum.SortOrder.LayoutOrder
    subList.Padding = UDim.new(0,8)
    subList.Parent = contentFrame
    local expanded = false
    local function rowKV(parent, k, v)
        local r = Instance.new("Frame")
        r.BackgroundTransparency = 1
        r.Size = UDim2.new(1,0,0,24)
        r.Parent = parent
        local hlist = Instance.new("UIListLayout")
        hlist.FillDirection = Enum.FillDirection.Horizontal
        hlist.HorizontalAlignment = Enum.HorizontalAlignment.Left
        hlist.VerticalAlignment = Enum.VerticalAlignment.Top
        hlist.Padding = UDim.new(0,12)
        hlist.Parent = r
        local kLbl = Instance.new("TextLabel")
        kLbl.BackgroundTransparency = 1
        kLbl.Size = UDim2.new(0.35,0,1,0)
        kLbl.Font = Enum.Font.Gotham
        kLbl.Text = tostring(k)
        kLbl.TextSize = 13
        kLbl.TextColor3 = c.td
        kLbl.TextXAlignment = Enum.TextXAlignment.Left
        kLbl.TextWrapped = true
        kLbl.Parent = r
        local vLbl = Instance.new("TextLabel")
        vLbl.BackgroundTransparency = 1
        vLbl.Size = UDim2.new(0.65,0,1,0)
        vLbl.Font = Enum.Font.Gotham
        if typeof(v) == "table" then
            local n=0; local isArray=true; local maxk=0
            for kk in pairs(v) do
                n+=1
                if typeof(kk)~="number" then isArray=false else if kk>maxk then maxk=kk end end
            end
            if n==0 then return end
            if isArray and maxk==n then
                local parts={}
                for i=1,#v do parts[i]=tostring(v[i]) end
                vLbl.Text = table.concat(parts,", ")
            else
                vLbl.Text = HttpService:JSONEncode(v)
            end
        else
            vLbl.Text = tostring(v)
        end
        vLbl.TextSize = 13
        vLbl.TextColor3 = c.tx
        vLbl.TextXAlignment = Enum.TextXAlignment.Left
        vLbl.TextWrapped = true
        vLbl.Parent = r
        task.defer(function()
            autoRowHeight(r, kLbl, vLbl, 0.35)
            r:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() autoRowHeight(r, kLbl, vLbl, 0.35) end)
            kLbl:GetPropertyChangedSignal("Text"):Connect(function() autoRowHeight(r, kLbl, vLbl, 0.35) end)
            vLbl:GetPropertyChangedSignal("Text"):Connect(function() autoRowHeight(r, kLbl, vLbl, 0.35) end)
        end)
    end
    local function rebuild()
        for _, ch in ipairs(contentFrame:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        local keys = {}
        for k in pairs(tbl) do table.insert(keys, k) end
        table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)
        for _, k in ipairs(keys) do
            rowKV(contentFrame, k, tbl[k])
        end
        task.defer(function()
            local h = subList.AbsoluteContentSize.Y
            TweenService:Create(contentFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1,-24,0,h)}):Play()
            TweenService:Create(container, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1,0,0,56 + h)}):Play()
        end)
    end
    toggle.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            TweenService:Create(toggle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 180}):Play()
            rebuild()
        else
            TweenService:Create(toggle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 0}):Play()
            TweenService:Create(contentFrame, TweenInfo.new(0.2), {Size = UDim2.new(1,-24,0,0)}):Play()
            TweenService:Create(container, TweenInfo.new(0.2), {Size = UDim2.new(1,0,0,56)}):Play()
        end
    end)
end

local function clearBody()
    for _, ch in ipairs(listContainer:GetChildren()) do
        if ch:IsA("Frame") then ch:Destroy() end
    end
end

local originalSize = root.Size
local minimized = false

btnMin.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(btnMin, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 180}):Play()
        TweenService:Create(gIcon, TweenInfo.new(0.12), {Size = UDim2.fromOffset(0,0)}):Play()
        TweenService:Create(gName, TweenInfo.new(0.12), {TextTransparency = 1}):Play()
        TweenService:Create(gOwner, TweenInfo.new(0.12), {TextTransparency = 1}):Play()
        task.wait(0.12)
        header.Visible = false
        TweenService:Create(content, TweenInfo.new(0.18), {Size = UDim2.new(1,0,0,0)}):Play()
        TweenService:Create(root, TweenInfo.new(0.18), {Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 54)}):Play()
    else
        header.Visible = true
        TweenService:Create(root, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = originalSize}):Play()
        TweenService:Create(content, TweenInfo.new(0.22), {Size = UDim2.new(1,0,1,-150)}):Play()
        TweenService:Create(gIcon, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(78,78)}):Play()
        TweenService:Create(gName, TweenInfo.new(0.18), {TextTransparency = 0}):Play()
        TweenService:Create(gOwner, TweenInfo.new(0.18), {TextTransparency = 0}):Play()
        TweenService:Create(btnMin, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 0}):Play()
    end
end)

btnClose.MouseButton1Click:Connect(function()
    TweenService:Create(root, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
    TweenService:Create(stroke, TweenInfo.new(0.12), {Transparency = 1}):Play()
    task.wait(0.13)
    sg:Destroy()
end)

NAdrag(root, topbar)

local function applyAccent(col)
    accent = col
    topbar.BackgroundColor3 = lerpColor(col, c.ac, 0.25)
    stroke.Color = lerpColor(col, Color3.new(0,0,0), 0.5)
    listContainer.ScrollBarImageColor3 = lerpColor(col, Color3.new(1,1,1), 0.1)
    btnRefresh.BackgroundColor3 = col
    btnMin.BackgroundColor3 = c.warn
    btnClose.BackgroundColor3 = c.stop
end

local req = (syn and syn.request) or request or http_request or (http and http.request) or (fluxus and fluxus.request) or (krnl and krnl.request) or krnl_request

local function jget(url)
    if req then
        local ok, r = pcall(function()
            return req({
                Url = url,
                Method = "GET",
                Headers = {
                    ["Accept"] = "application/json",
                    ["Cache-Control"] = "no-cache",
                    ["Pragma"] = "no-cache",
                    ["User-Agent"] = "Roblox-Client"
                }
            })
        end)
        if not ok or not r or (r.StatusCode ~= 200 and r.StatusCode ~= 201) or type(r.Body) ~= "string" then
            return nil
        end
        local ok2, data = pcall(function() return HttpService:JSONDecode(r.Body) end)
        if not ok2 then return nil end
        return data
    else
        local ok, res = pcall(function() return HttpService:GetAsync(url, true) end)
        if not ok or type(res) ~= "string" then return nil end
        local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
        if not ok2 then return nil end
        return data
    end
end

local function displayGameInfo()
    clearBody()
    local universeId = tostring(game.GameId)
    local placeId = game.PlaceId

    local gi
    do
        local ok, res = pcall(function()
            return MarketplaceService:GetProductInfo(placeId)
        end)
        if ok and typeof(res) == "table" then gi = res end
    end

    if gi and gi.IconImageAssetId and gi.IconImageAssetId > 0 then
        gIcon.Image = "https://assetgame.roblox.com/Game/Tools/ThumbnailAsset.ashx?aid="..tostring(gi.IconImageAssetId).."&fmt=png&wd=420&ht=420"
    end

    local gjson = jget("https://games.roproxy.com/v1/games?universeIds="..universeId)
    local gdata = gjson and gjson.data and gjson.data[1]

    if gdata and gdata.name then
        gName.Text = tostring(gdata.name)
    elseif gi and gi.Name then
        gName.Text = tostring(gi.Name)
    else
        gName.Text = "Experience"
    end

    local creator = (gdata and gdata.creator) or {}
    local cType = tostring(creator.type or (gi and gi.Creator and gi.Creator.CreatorType) or ""):lower()
    local cName = tostring(creator.name or (gi and gi.Creator and gi.Creator.Name) or "N/A")
    gOwner.Text = "Owned by: "..cName
    if cType == "group" then applyAccent(c.gx) else applyAccent(c.ux) end

    local seen = {}
    local function mark(k) seen[string.lower(k)] = true end
    local function seenKey(k) return seen[string.lower(k)] == true end

    local function stringify(v)
        if typeof(v) == "table" then
            local n=0; local isArray=true; local maxk=0
            for kk in pairs(v) do
                n+=1
                if typeof(kk)~="number" then isArray=false else if kk>maxk then maxk=kk end end
            end
            if n==0 then return nil end
            if isArray and maxk==n then
                local parts={}
                for i=1,#v do parts[i]=tostring(v[i]) end
                return table.concat(parts,", ")
            else
                return HttpService:JSONEncode(v)
            end
        end
        return v
    end

    local function addKV(k, v)
        if v == nil then return end
        if typeof(v) == "string" and v == "" then return end
        if seenKey(k) then return end
        local sv = stringify(v)
        if sv == nil then return end
        addRow(k, sv)
        mark(k)
    end

    if gdata then
        for k, v in pairs(gdata) do
            if k ~= "creator" then
                addKV(k, v)
            end
        end
    end

    if gi then
        for k, v in pairs(gi) do
            if k ~= "Creator" and k ~= "ProductId" then
                addKV(k, v)
            end
        end
    end

    local cdrop = {}
    if creator then
        for ck, cv in pairs(creator) do cdrop[ck] = cv end
    end
    if next(cdrop) == nil and gi and typeof(gi.Creator) == "table" then
        for ck, cv in pairs(gi.Creator) do cdrop[ck] = cv end
    end
    if next(cdrop) ~= nil then
        addDropdown("Creator", cdrop)
    end

    local vjson = jget("https://games.roproxy.com/v1/games/votes?universeIds="..universeId)
    local votes = vjson and vjson.data and vjson.data[1]
    if votes then
        local up = votes.upVotes or 0
        local down = votes.downVotes or 0
        local total = up + down
        local ratio = total > 0 and math.floor((up/total)*1000)/10 or 0
        addDropdown("Votes", {upVotes = up, downVotes = down, total = total, likeRatioPercent = ratio})
    end

    local socials = jget("https://games.roproxy.com/v1/games/"..universeId.."/social-links/list")
    if socials and socials.data and #socials.data > 0 then
        local stbl = {}
        for _, s in ipairs(socials.data) do
            stbl[(s.type or "Link").." ("..(s.title or "")..")"] = s.url or ""
        end
        addDropdown("Social Links", stbl)
    end
end

btnRefresh.MouseButton1Click:Connect(function()
    TweenService:Create(btnRefresh, TweenInfo.new(0.32, Enum.EasingStyle.Linear), {Rotation = btnRefresh.Rotation + 360}):Play()
    task.defer(displayGameInfo)
end)

displayGameInfo()

root.BackgroundTransparency = 1
stroke.Transparency = 1
root.Size = UDim2.fromScale(0.6,0.56)
TweenService:Create(root, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Size = UDim2.fromScale(0.64,0.6)}):Play()
TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.55}):Play()