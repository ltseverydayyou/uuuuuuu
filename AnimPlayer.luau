local P = game:GetService("Players")
local T = game:GetService("TweenService")
local M = game:GetService("MarketplaceService")
local U = game:GetService("UserInputService")
local pl = P.LocalPlayer
local g = (gethui and gethui()) or pl:WaitForChild("PlayerGui")
local sg = Instance.new("ScreenGui", g)
sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
sg.DisplayOrder   = 1000

local function NAdrag(ui, dragui)
    if not dragui then dragui = ui end
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        local newXOffset = startPos.X.Offset + delta.X
        local newYOffset = startPos.Y.Offset + delta.Y
        local sz = ui.Parent.AbsoluteSize
        local newXScale = startPos.X.Scale + (newXOffset / sz.X)
        local newYScale = startPos.Y.Scale + (newYOffset / sz.Y)
        ui.Position = UDim2.new(newXScale, 0, newYScale, 0)
    end
    dragui.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = ui.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    dragui.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
            dragInput = i
        end
    end)
    U.InputChanged:Connect(function(i)
        if dragging and i == dragInput then
            update(i)
        end
    end)
    ui.Active = true
end

local f = Instance.new("Frame", sg)
f.AnchorPoint     = Vector2.new(0.5, 0)
f.Position        = UDim2.new(0.5, 0, 0.02, 0)
f.Size            = UDim2.new(0, 260, 0, 60)
f.BackgroundColor3= Color3.fromRGB(30, 30, 30)
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke",  f).Thickness      = 1

local dragBtn = Instance.new("TextButton", f)
dragBtn.Size               = UDim2.new(0, 30, 0, 30)
dragBtn.Position           = UDim2.new(0, 5, 0, 5)
dragBtn.BackgroundColor3   = Color3.fromRGB(50, 50, 50)
dragBtn.AutoButtonColor    = true
dragBtn.Font               = Enum.Font.SourceSansBold
dragBtn.TextSize           = 20
dragBtn.TextColor3         = Color3.new(1,1,1)
dragBtn.Text               = "≡"
Instance.new("UICorner", dragBtn).CornerRadius = UDim.new(0,4)

local tb = Instance.new("TextButton", f)
tb.Size               = UDim2.new(0,110,0,30)
tb.Position           = UDim2.new(0, 40, 0, 5)
tb.BackgroundTransparency = 1
tb.AutoButtonColor    = false
tb.Font               = Enum.Font.SourceSansBold
tb.TextSize           = 18
tb.TextColor3         = Color3.new(1,1,1)
tb.Text               = "Animations ▼"

local cancelBtn = Instance.new("TextButton", f)
cancelBtn.Size         = UDim2.new(0,80,0,30)
cancelBtn.Position     = UDim2.new(0,155,0,5)
cancelBtn.BackgroundColor3 = Color3.fromRGB(65,65,65)
cancelBtn.AutoButtonColor  = false
cancelBtn.Font              = Enum.Font.SourceSans
cancelBtn.TextSize          = 16
cancelBtn.TextColor3        = Color3.new(1,1,1)
cancelBtn.Text              = "Cancel"
Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0,8)

local closeBtn = Instance.new("TextButton", f)
closeBtn.Size         = UDim2.new(0,20,0,20)
closeBtn.Position     = UDim2.new(0,240,0,10)
closeBtn.BackgroundColor3 = Color3.fromRGB(65,65,65)
closeBtn.AutoButtonColor  = false
closeBtn.Font              = Enum.Font.SourceSansBold
closeBtn.TextSize          = 18
closeBtn.TextColor3        = Color3.new(1,1,1)
closeBtn.Text              = "X"
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,4)

local ld = Instance.new("TextLabel", f)
ld.Size              = UDim2.new(1,0,0,20)
ld.Position          = UDim2.new(0,0,0,40)
ld.BackgroundTransparency = 1
ld.Font              = Enum.Font.SourceSans
ld.TextSize          = 14
ld.TextColor3        = Color3.new(1,1,1)
ld.TextXAlignment    = Enum.TextXAlignment.Center
ld.Text              = "Loading... 0%"

local sf = Instance.new("ScrollingFrame", f)
sf.Size              = UDim2.new(1,0,0,0)
sf.Position          = UDim2.new(0,0,0,60)
sf.BackgroundColor3  = Color3.fromRGB(20,20,20)
sf.BorderSizePixel   = 0
sf.ScrollingEnabled  = true
sf.ScrollBarThickness = 6
Instance.new("UICorner", sf).CornerRadius = UDim.new(0,8)
local ly = Instance.new("UIListLayout", sf)
ly.SortOrder, ly.Padding = Enum.SortOrder.LayoutOrder, UDim.new(0,4)
ly:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sf.CanvasSize = UDim2.new(0,0,0, ly.AbsoluteContentSize.Y)
end)

local of = Instance.new("Frame", f)
of.Position         = UDim2.new(1,0,0,0)
of.AnchorPoint      = Vector2.new(0,0)
of.Size             = UDim2.new(0,0,0,0)
of.BackgroundColor3 = Color3.fromRGB(25,25,25)
of.Visible          = false
Instance.new("UICorner", of).CornerRadius = UDim.new(0,8)

local playBtn = Instance.new("TextButton", of)
playBtn.Size             = UDim2.new(1,-20,0,30)
playBtn.Position         = UDim2.new(0,10,0,10)
playBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
playBtn.Font             = Enum.Font.SourceSans
playBtn.TextSize         = 16
playBtn.TextColor3       = Color3.new(1,1,1)
playBtn.Text             = "Play"
Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0,4)

local copyBtn = Instance.new("TextButton", of)
copyBtn.Size             = UDim2.new(1,-20,0,30)
copyBtn.Position         = UDim2.new(0,10,0,50)
copyBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
copyBtn.Font             = Enum.Font.SourceSans
copyBtn.TextSize         = 16
copyBtn.TextColor3       = Color3.new(1,1,1)
copyBtn.Text             = "Copy ID"
Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0,4)

local anims, idSet, sel, cur, exp = {}, {}, nil, nil, false

local function stopCur()
    if cur then cur:Stop() cur = nil end
end

local function bindH(h)
    h.Running:Connect(function(s) if s > 0 then stopCur() end end)
    h.Jumping:Connect(stopCur)
    h.StateChanged:Connect(function(_, ns)
        if ns == Enum.HumanoidStateType.Climbing
        or ns == Enum.HumanoidStateType.Freefall
        or ns == Enum.HumanoidStateType.Swimming then
            stopCur()
        end
    end)
end

if pl.Character then bindH(pl.Character:WaitForChild("Humanoid")) end
pl.CharacterAdded:Connect(function(c) bindH(c:WaitForChild("Humanoid")) end)

NAdrag(f, dragBtn)

tb.MouseButton1Click:Connect(function()
    exp = not exp
    tb.Text = exp and "Animations ▲" or "Animations ▼"
    local H = math.clamp(ly.AbsoluteContentSize.Y, 0, 176)
    T:Create(sf, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = exp and UDim2.new(1,0,0,H) or UDim2.new(1,0,0,0)
    }):Play()
    T:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = exp and UDim2.new(0,260,0,60+H) or UDim2.new(0,260,0,60)
    }):Play()
    if not exp then
        of.Visible = false
        T:Create(of, TweenInfo.new(0.2), { Size = UDim2.new(0,0,0,0) }):Play()
    end
end)

cancelBtn.MouseButton1Click:Connect(function()
    if pl.Character then
        local h = pl.Character:FindFirstChildOfClass("Humanoid")
        for _, t in ipairs((h and h:GetPlayingAnimationTracks()) or {}) do t:Stop() end
    end
    if exp then
        exp = false
        tb.Text = "Animations ▼"
        T:Create(sf, TweenInfo.new(0.3), { Size = UDim2.new(1,0,0,0) }):Play()
        T:Create(f, TweenInfo.new(0.3), { Size = UDim2.new(0,260,0,60) }):Play()
        of.Visible = false
        T:Create(of, TweenInfo.new(0.2), { Size = UDim2.new(0,0,0,0) }):Play()
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    sg.Enabled = false
end)

playBtn.MouseButton1Click:Connect(function()
    if sel and pl.Character then
        local h = pl.Character:FindFirstChildOfClass("Humanoid")
        if h then
            for _, t in ipairs(h:GetPlayingAnimationTracks()) do t:Stop() end
            cur = h:LoadAnimation(sel.anim)
            cur:Play()
        end
    end
    exp = false
    tb.Text = "Animations ▼"
    T:Create(sf, TweenInfo.new(0.3), { Size = UDim2.new(1,0,0,0) }):Play()
    T:Create(f, TweenInfo.new(0.3), { Size = UDim2.new(0,260,0,60) }):Play()
    of.Visible = false
    T:Create(of, TweenInfo.new(0.2), { Size = UDim2.new(0,0,0,0) }):Play()
end)

copyBtn.MouseButton1Click:Connect(function()
    if sel then
        local id = sel.anim.AnimationId:match("%d+") or ""
        if setclipboard then setclipboard(id) end
        if syn and syn.set_clipboard then syn.set_clipboard(id) end
    end
    exp = false
    tb.Text = "Animations ▼"
    T:Create(sf, TweenInfo.new(0.3), { Size = UDim2.new(1,0,0,0) }):Play()
    T:Create(f, TweenInfo.new(0.3), { Size = UDim2.new(0,260,0,60) }):Play()
    of.Visible = false
    T:Create(of, TweenInfo.new(0.2), { Size = UDim2.new(0,0,0,0) }):Play()
end)

task.spawn(function()
    local D, tot = game:GetDescendants(), #game:GetDescendants()
    for i, inst in ipairs(D) do
        local aid
        if inst:IsA("Animation") then
            local m = inst.AnimationId:match("%d+")
            if m then aid = tonumber(m) end
        elseif (inst:IsA("NumberValue") or inst:IsA("IntValue")) and typeof(inst.Value) == "number" then
            aid = inst.Value
        end
        if aid and not idSet[aid] then
            idSet[aid] = true
            if inst:IsA("Animation") then
                table.insert(anims, {name = inst.Name, anim = inst})
            else
                local ok, info = pcall(function()
                    return M:GetProductInfo(aid, Enum.InfoType.Asset)
                end)
                if ok and info.AssetTypeId == Enum.AssetType.Animation.Value then
                    local a = Instance.new("Animation")
                    a.Name        = info.Name
                    a.AnimationId = "rbxassetid://"..aid
                    table.insert(anims, {name = info.Name, anim = a})
                end
            end
        end
        ld.Text = "Loading... "..math.floor(i/tot*100).."%"
    end
    ld:Destroy()
    for i, d in ipairs(anims) do
        local b = Instance.new("TextButton", sf)
        b.Name            = "Btn"..i
        b.Text            = d.name
        b.Size            = UDim2.new(1,0,0,32)
        b.BackgroundColor3= Color3.fromRGB(50,50,50)
        b.BorderSizePixel = 0
        b.Font            = Enum.Font.SourceSans
        b.TextSize        = 16
        b.TextColor3      = Color3.new(1,1,1)
        b.LayoutOrder     = i
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
        b.MouseButton1Click:Connect(function()
            sel = d
            of.Visible = true
            T:Create(of, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 120, 0, 90)
            }):Play()
        end)
    end
end)