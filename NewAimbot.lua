local conns = {}

local function svc(n)
    local S = (game.GetService)
    local R = (cloneref) or function(r) return r end
    return R(S(game, n))
end

local Players = svc("Players")
local RunService = svc("RunService")
local UIS = svc("UserInputService")
local TS = svc("TweenService")
local CAS = svc("ContextActionService")
local LS = svc("LocalizationService")
local MPS = svc("MarketplaceService")
local HS = svc("HttpService")
local uiRoot = (gethui and gethui()) or (svc("CoreGui") or svc("Players").LocalPlayer:WaitForChild("PlayerGui"))

local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera
local ms = plr:GetMouse()

local isLock = false
local dragging = false
local dragStart = nil
local startPos = nil
local mode = "FFA"
local lastMode = nil
local capMode = false
local capCooldownUntil = 0

local gui = nil
local frm = nil
local uiMin = false
local toastHolder = nil
local toastIdx = 0
local topBtn = nil

local espMap = {}
local startUnix = DateTime.now().UnixTimestamp

_G.isEnabled      = _G.isEnabled      or false
_G.lockToHead     = _G.lockToHead     or false
_G.espEnabled     = _G.espEnabled     or false
_G.lockToNearest  = _G.lockToNearest  or false
_G.aliveCheck     = _G.aliveCheck     or false
_G.teamCheck      = _G.teamCheck      or false
_G.wallCheck      = _G.wallCheck      or false
_G.aimTween       = _G.aimTween       or false
_G.aimSmooth      = _G.aimSmooth      or 0.15
_G.fovEnabled     = _G.fovEnabled     or false
_G.fovValue       = _G.fovValue       or 70
_G.espShowName    = (_G.espShowName ~= nil) and _G.espShowName or true
_G.espShowHP      = (_G.espShowHP   ~= nil) and _G.espShowHP   or true
_G.espShowTeam    = (_G.espShowTeam ~= nil) and _G.espShowTeam or true
_G.espTeamColor   = (_G.espTeamColor~= nil) and _G.espTeamColor or true
_G.triggerBot     = _G.triggerBot     or false
_G.tbCPS          = _G.tbCPS          or 8
_G.aimPredict     = _G.aimPredict     or false
_G.aimLead        = _G.aimLead        or 0.12
_G.toggleKeys     = _G.toggleKeys     or {"RightAlt","LeftAlt","P","RightControl"}

local MainName = "Aervanix-Aimbot"
local cfgFile = MainName.."/config.json"

local UI = {
    bg1 = Color3.fromRGB(14, 14, 18),
    bg2 = Color3.fromRGB(22, 24, 30),
    panel = Color3.fromRGB(30, 32, 40),
    bar1 = Color3.fromRGB(28, 30, 36),
    bar2 = Color3.fromRGB(20, 22, 28),
    stroke = Color3.fromRGB(70, 74, 88),
    stroke2 = Color3.fromRGB(52, 56, 72),
    knob = Color3.fromRGB(244, 244, 248),
    text = Color3.fromRGB(235, 236, 244),
    sub = Color3.fromRGB(170, 174, 189),
    acc = Color3.fromRGB(255, 110, 80),
    acc2 = Color3.fromRGB(98, 180, 255),
    ok = Color3.fromRGB(88, 205, 120),
    warn = Color3.fromRGB(255, 190, 72),
    danger = Color3.fromRGB(255, 95, 90),
    fallback = Color3.fromRGB(128, 0, 255)
}

local function cleanup()
    for _, g in pairs(uiRoot:GetChildren()) do
        if g:IsA("ScreenGui") and g.Name == "AervanixBot" then
            g:Destroy()
        end
    end
end

local function round(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = r or UDim.new(0, 0)
    return c
end

local function shadow(p)
    local s = Instance.new("ImageLabel")
    s.Name = "Shadow"
    s.BackgroundTransparency = 1
    s.Image = "rbxassetid://5028857476"
    s.ImageColor3 = Color3.fromRGB(0, 0, 0)
    s.ImageTransparency = 0.42
    s.ScaleType = Enum.ScaleType.Slice
    s.SliceCenter = Rect.new(24, 24, 276, 276)
    s.Size = UDim2.new(1, 44, 1, 44)
    s.Position = UDim2.new(0.5, 0, 0.5, 8)
    s.AnchorPoint = Vector2.new(0.5, 0.5)
    s.ZIndex = 0
    s.Parent = p
end

local function stroke(p, t, c, tr)
    local s = Instance.new("UIStroke")
    s.Thickness = t or 1
    s.Color = c or UI.stroke
    s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function grad(p, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 90
    g.Parent = p
    return g
end

local function styleTog(bg, btn)
    bg.BackgroundColor3 = UI.bar2
    stroke(bg, 1, UI.stroke2, 0.2)
    local g = grad(bg, UI.bar2, UI.bg2, 90)
    g.Name = "Grad"
    btn.BackgroundColor3 = UI.knob
    stroke(btn, 1, Color3.fromRGB(205, 208, 220), 0.35)
end

local function styleWin(frame, bar, title, btnX, btnMin)
    frame.BackgroundColor3 = UI.panel
    frame.BackgroundTransparency = 0.04
    shadow(frame)
    stroke(frame, 1, UI.stroke, 0.22)
    grad(frame, UI.bg2, UI.bg1, 90)
    bar.BackgroundColor3 = UI.bar1
    stroke(bar, 1, UI.stroke2, 0.26)
    grad(bar, UI.bar1, UI.bar2, 90)
    title.TextColor3 = UI.text
    local function winBtn(b, base)
        b.BackgroundColor3 = base
        stroke(b, 1, Color3.fromRGB(0,0,0), 0.82)
        local e = b.MouseEnter:Connect(function()
            TS:Create(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = base:Lerp(Color3.new(1,1,1), 0.18)}):Play()
        end)
        local l = b.MouseLeave:Connect(function()
            TS:Create(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {BackgroundColor3 = base}):Play()
        end)
        table.insert(conns, e)
        table.insert(conns, l)
    end
    winBtn(btnX, UI.danger)
    winBtn(btnMin, UI.warn)
end

local function goodPart(p)
    if not p or not p:IsA("BasePart") then return false end
    if p.Transparency >= 0.95 then return false end
    if p.CanQuery == false then return false end
    if p.CanCollide == false then return false end
    return true
end

local function clearLOS(targetPart)
    if not targetPart then return false end
    local origin = cam.CFrame.Position
    local dir = targetPart.Position - origin
    local ignore = {plr.Character, targetPart.Parent}
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true
    local maxHops = 10
    local curOrigin = origin
    local remaining = dir
    for _ = 1, maxHops do
        local r = workspace:Raycast(curOrigin, remaining, params)
        if not r then return true end
        local hit = r.Instance
        if not goodPart(hit) or hit:IsDescendantOf(targetPart.Parent) then
            table.insert(ignore, hit)
            params.FilterDescendantsInstances = ignore
            curOrigin = r.Position + remaining.Unit * 0.01
            remaining = origin + dir - curOrigin
        else
            return false
        end
    end
    return false
end

local function getTeamColor(p)
    if _G.espTeamColor then
        if p.Team and p.Team.TeamColor then
            local bc = p.Team.TeamColor
            if typeof(bc) == "BrickColor" then return bc.Color end
        end
        if p.TeamColor then
            local bc = p.TeamColor
            if typeof(bc) == "BrickColor" then return bc.Color end
        end
    end
    return UI.fallback
end

local function sanitizeNumber(txt, min, max, def)
    local s = tostring(txt or "")
    local out, dot = {}, false
    for i = 1, #s do
        local ch = s:sub(i,i)
        if ch:match("%d") then
            table.insert(out, ch)
        elseif ch == "." and not dot then
            table.insert(out, ch); dot = true
        end
    end
    local num = tonumber(table.concat(out, ""))
    if not num then num = def end
    if min then num = math.max(min, num) end
    if max then num = math.min(max, num) end
    return num
end

local function toast(msg)
    if not gui then return end
    toastIdx += 1
    local n = Instance.new("Frame")
    n.Name = "Toast_"..toastIdx
    n.Size = UDim2.new(0, 360, 0, 46)
    n.BackgroundColor3 = UI.panel
    n.BackgroundTransparency = 0.1
    n.BorderSizePixel = 0
    n.Parent = toastHolder
    n.LayoutOrder = toastIdx
    round(n, UDim.new(0.2, 0))
    stroke(n, 1, UI.stroke2, 0.25)
    grad(n, UI.bg2, UI.bg1, 90)
    local side = Instance.new("Frame", n)
    side.Size = UDim2.new(0, 4, 1, 0)
    side.Position = UDim2.new(0, 0, 0, 0)
    side.BackgroundColor3 = UI.acc
    side.BorderSizePixel = 0
    round(side, UDim.new(0, 4))
    grad(side, UI.acc, UI.acc2, 90)
    local t = Instance.new("TextLabel", n)
    t.Size = UDim2.new(1, -24, 1, 0)
    t.Position = UDim2.new(0, 12, 0, 0)
    t.Text = msg
    t.TextColor3 = UI.text
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamMedium
    t.TextSize = 14
    t.TextWrapped = true
    n.AnchorPoint = Vector2.new(0.5, 1)
    n.Position = UDim2.new(0.5, 0, 1, 0)
    TS:Create(n, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.08}):Play()
    task.delay(3, function()
        TS:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
        task.delay(0.35, function() if n and n.Parent then n:Destroy() end end)
    end)
end

local function saveCfg()
    if not writefile or not HS then return end
    local okFolder = true
    if isfolder and not isfolder(MainName) then
        if makefolder then
            local s, e = pcall(makefolder, MainName)
            okFolder = s and e == nil or s
        else
            okFolder = false
        end
    end
    if not okFolder then return end
    local data = {
        isEnabled=_G.isEnabled,lockToHead=_G.lockToHead,espEnabled=_G.espEnabled,lockToNearest=_G.lockToNearest,
        aliveCheck=_G.aliveCheck,teamCheck=_G.teamCheck,wallCheck=_G.wallCheck,aimTween=_G.aimTween,aimSmooth=_G.aimSmooth,
        fovEnabled=_G.fovEnabled,fovValue=_G.fovValue,espShowName=_G.espShowName,espShowHP=_G.espShowHP,espShowTeam=_G.espShowTeam,
        espTeamColor=_G.espTeamColor,triggerBot=_G.triggerBot,tbCPS=_G.tbCPS,aimPredict=_G.aimPredict,aimLead=_G.aimLead,
        toggleKeys=_G.toggleKeys
    }
    local ok, enc = pcall(function() return HS:JSONEncode(data) end)
    if ok and enc then pcall(writefile, cfgFile, enc) end
end

local function loadCfg()
    if not readfile or not isfile or not HS then return end
    if not isfile(cfgFile) then return end
    local ok, txt = pcall(readfile, cfgFile)
    if not ok or not txt or txt == "" then return end
    local ok2, obj = pcall(function() return HS:JSONDecode(txt) end)
    if not ok2 or type(obj) ~= "table" then return end
    for k,v in pairs(obj) do
        if _G[k] ~= nil then _G[k] = v end
    end
end

loadCfg()

local camFOVCon, camSwapCon
local function bindFOV()
    if camFOVCon then camFOVCon:Disconnect() camFOVCon = nil end
    if not cam then return end
    camFOVCon = cam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        if _G.fovEnabled and math.abs((cam.FieldOfView or 70) - (_G.fovValue or 70)) > 0.01 then
            cam.FieldOfView = _G.fovValue
        end
    end)
end

local function hookCamera()
    cam = workspace.CurrentCamera
    if camSwapCon then camSwapCon:Disconnect() end
    camSwapCon = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        cam = workspace.CurrentCamera
        bindFOV()
        if _G.fovEnabled and cam then cam.FieldOfView = _G.fovValue end
    end)
    bindFOV()
end
hookCamera()

local function getHumanoid(m)
    if not m then return nil end
    local h = m:FindFirstChildOfClass("Humanoid")
    if h then return h end
    for _, d in ipairs(m:GetDescendants()) do
        if d:IsA("Humanoid") then return d end
    end
    return nil
end

local function getPart(m, name)
    if not m then return nil end
    local p = m:FindFirstChild(name, true)
    if p and p:IsA("BasePart") then return p end
    local h = getHumanoid(m)
    if h and h.RootPart and (name == "HumanoidRootPart" or name == "RootPart") then return h.RootPart end
    local fallback = {"HumanoidRootPart","UpperTorso","LowerTorso","Torso","Head"}
    for _, n in ipairs(fallback) do
        local q = m:FindFirstChild(n, true)
        if q and q:IsA("BasePart") then
            if name == "Head" and q.Name ~= "Head" then
            else
                return q
            end
        end
    end
    return nil
end

local function topAimPart(m)
    if _G.lockToHead then
        local h = getPart(m,"Head")
        if h then return h end
    end
    local hrp = getPart(m,"HumanoidRootPart")
    if hrp then return hrp end
    local h = getPart(m,"Head")
    if h then return h end
    return nil
end

local function isEnemy(op)
    if not _G.teamCheck then return true end
    if mode == "FFA" then
        return true
    else
        return op.Team ~= nil and plr.Team ~= nil and op.Team ~= plr.Team
    end
end

local function isAlive(ch)
    if not _G.aliveCheck then return true end
    if not ch then return false end
    local hum = getHumanoid(ch)
    return hum and hum.Health > 0
end

local function findTarget()
    local near = nil
    local minD = math.huge
    for _, op in pairs(Players:GetPlayers()) do
        if op ~= plr and op.Character and isEnemy(op) then
            local ch = op.Character
            if not isAlive(ch) then
                continue
            end
            local part = topAimPart(ch)
            local hum = getHumanoid(ch)
            if part and hum and hum.Health > 0 then
                local scr, on = cam:WorldToScreenPoint(part.Position)
                if on then
                    if _G.wallCheck and not clearLOS(part) then
                        continue
                    end
                    local dist = (part.Position - cam.CFrame.Position).Magnitude
                    local mp = Vector2.new(ms.X, ms.Y)
                    local sdist = (Vector2.new(scr.X, scr.Y) - mp).Magnitude
                    if _G.lockToNearest then
                        if dist < minD then
                            minD = dist
                            near = ch
                        end
                    else
                        if sdist < 150 and sdist < minD then
                            minD = sdist
                            near = ch
                        end
                    end
                end
            end
        end
    end
    return near
end

local function updateESPText(p)
    local rec = espMap[p]
    if not rec or not rec.tx then return end
    local nameStr = _G.espShowName and p.Name or ""
    local hpStr = ""
    local ch = p.Character
    local hum = ch and getHumanoid(ch)
    if _G.espShowHP and hum then hpStr = "HP: " .. math.floor(hum.Health) end
    local teamStr = ""
    if _G.espShowTeam and p.Team then
        teamStr = p.Team.Name
    end
    local lines = {}
    if nameStr ~= "" then table.insert(lines, nameStr) end
    if hpStr ~= "" then table.insert(lines, hpStr) end
    if teamStr ~= "" then table.insert(lines, teamStr) end
    rec.tx.Text = table.concat(lines, "\n")
end

local function espDetach(p)
    local rec = espMap[p]
    if not rec then return end
    if rec.conns then
        for _, cc in ipairs(rec.conns) do
            if typeof(cc) == "RBXScriptConnection" and cc.Connected then cc:Disconnect() end
        end
    end
    if rec.hi and rec.hi.Parent then rec.hi:Destroy() end
    if rec.bb and rec.bb.Parent then rec.bb:Destroy() end
    espMap[p] = nil
end

local function getTeamColorSafe(p)
    if mode == "FFA" then
        return UI.fallback
    end
    return getTeamColor(p)
end

local function espAttach(p)
    if not _G.espEnabled then return end
    if p == plr then return end
    if espMap[p] then espDetach(p) end
    local ch = p.Character
    if not ch then return end
    local hum = getHumanoid(ch)
    if _G.teamCheck and not isEnemy(p) then return end
    if _G.aliveCheck and (not hum or hum.Health <= 0) then return end
    local hi = Instance.new("Highlight")
    local col = getTeamColorSafe(p)
    hi.FillColor = col
    hi.OutlineColor = col:lerp(Color3.new(1,1,1), 0.25)
    hi.FillTransparency = 0.3
    hi.OutlineTransparency = 0.1
    hi.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hi.Adornee = ch
    hi.Parent = gui
    local head = getPart(ch,"Head") or getPart(ch,"HumanoidRootPart")
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 140, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.Adornee = head
    bb.AlwaysOnTop = true
    bb.Parent = gui
    local tx = Instance.new("TextLabel", bb)
    tx.Size = UDim2.new(1, 0, 1, 0)
    tx.BackgroundTransparency = 1
    tx.TextColor3 = Color3.fromRGB(255, 255, 255)
    tx.TextStrokeTransparency = 0.5
    tx.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tx.Font = Enum.Font.GothamBold
    tx.TextSize = 14
    local rconns = {}
    if hum then
        local hc = hum.HealthChanged:Connect(function()
            updateESPText(p)
            if _G.aliveCheck and hum.Health <= 0 then
                espDetach(p)
            end
        end)
        table.insert(rconns, hc)
    end
    local teamC = p:GetPropertyChangedSignal("Team"):Connect(function()
        local c = getTeamColorSafe(p)
        if hi then
            hi.FillColor = c
            hi.OutlineColor = c:lerp(Color3.new(1,1,1), 0.25)
        end
        updateESPText(p)
    end)
    table.insert(rconns, teamC)
    espMap[p] = {hi = hi, bb = bb, tx = tx, conns = rconns}
    updateESPText(p)
end

local function updateESP()
    if not gui then return end
    if not _G.espEnabled then
        for p, _ in pairs(espMap) do espDetach(p) end
        espMap = {}
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= plr then
            if _G.teamCheck and not isEnemy(p) then
                espDetach(p)
            else
                espAttach(p)
            end
        end
    end
    for p, _ in pairs(espMap) do
        if not table.find(Players:GetPlayers(), p) then espDetach(p) end
    end
end

local tabs = {}
local function setTab(name)
    for k, t in pairs(tabs) do
        t.page.Visible = (k == name)
        TS:Create(t.btn, TweenInfo.new(0.15), {TextColor3 = k == name and UI.text or UI.sub}):Play()
        if k == name and t.scroll then
            t.scroll.CanvasPosition = Vector2.new(0, 0)
        end
    end
end

local function addRowToggle(parent, labelText, var, desc)
    local row = Instance.new("Frame", parent)
    row.Name = "Row_"..labelText
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, -20, 0, desc and 56 or 32)
    local lbl = Instance.new("TextLabel", row)
    lbl.Size = UDim2.new(1, -180, 0, 20)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = labelText
    lbl.TextColor3 = UI.sub
    if desc then
        local dl = Instance.new("TextLabel", row)
        dl.BackgroundTransparency = 1
        dl.Text = desc
        dl.TextColor3 = UI.sub
        dl.TextTransparency = 0.2
        dl.Font = Enum.Font.Gotham
        dl.TextSize = 12
        dl.TextXAlignment = Enum.TextXAlignment.Left
        dl.Position = UDim2.new(0, 0, 0, 22)
        dl.Size = UDim2.new(1, -180, 0, 18)
    end
    local bg = Instance.new("Frame", row)
    bg.Size = UDim2.new(0, 56, 0, 28)
    bg.Position = UDim2.new(1, -56, 0.5, -14)
    bg.BackgroundColor3 = UI.bar2
    bg.BorderSizePixel = 0
    local btn = Instance.new("TextButton", bg)
    btn.Size = UDim2.new(0, 26, 0, 26)
    btn.Position = UDim2.new(0, 1, 0.5, -13)
    btn.BackgroundColor3 = UI.knob
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    styleTog(bg, btn); round(bg, UDim.new(1,0)); round(btn, UDim.new(1,0))
    if _G[var] then
        btn.Position = UDim2.new(1, -27, 0.5, -13)
        bg.BackgroundColor3 = UI.ok
        local g = bg:FindFirstChild("Grad"); if g then g.Color = ColorSequence.new(UI.ok, UI.acc2) end
        local st = bg:FindFirstChildOfClass("UIStroke"); if st then st.Color = UI.acc2 st.Transparency = 0 end
    end
    local c = btn.MouseButton1Click:Connect(function()
        _G[var] = not _G[var]
        TS:Create(btn, TweenInfo.new(0.22), {Position = _G[var] and UDim2.new(1, -27, 0.5, -13) or UDim2.new(0, 1, 0.5, -13)}):Play()
        TS:Create(bg, TweenInfo.new(0.18), {BackgroundColor3 = _G[var] and UI.ok or UI.bar2}):Play()
        local g = bg:FindFirstChild("Grad")
        if g then g.Color = _G[var] and ColorSequence.new(UI.ok, UI.acc2) or ColorSequence.new(UI.bar2, UI.bg2) end
        local st = bg:FindFirstChildOfClass("UIStroke")
        if st then st.Color = _G[var] and UI.acc2 or UI.stroke2 st.Transparency = _G[var] and 0 or 0.2 end
        if var == "espEnabled" or var == "teamCheck" or var == "aliveCheck" or var == "espShowName" or var == "espShowHP" or var == "espShowTeam" or var == "espTeamColor" then
            updateESP()
        elseif var == "fovEnabled" then
            if _G.fovEnabled and cam then cam.FieldOfView = _G.fovValue end
        end
        saveCfg()
    end)
    table.insert(conns, c)
    return row
end

local function addRowToggleSlider(parent, labelText, varToggle, valueVar, min, max, decimals, desc)
    local row = addRowToggle(parent, labelText, varToggle, desc)
    local track = Instance.new("Frame", row)
    track.BackgroundColor3 = UI.bar2
    track.BorderSizePixel = 0
    track.Size = UDim2.new(0, 220, 0, 8)
    track.Position = UDim2.new(1, -(56 + 12 + 220), 0.5, -4)
    round(track, UDim.new(0,4))
    stroke(track, 1, UI.stroke2, 0.3)
    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = UI.acc2
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(0, 0, 1, 0)
    round(fill, UDim.new(0,4))
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, -7, 0.5, -7)
    knob.BackgroundColor3 = UI.knob
    knob.BorderSizePixel = 0
    round(knob, UDim.new(1,0))
    stroke(knob, 1, UI.stroke2, 0.15)
    local valLbl = Instance.new("TextLabel", row)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = Enum.Font.Gotham
    valLbl.TextSize = 13
    valLbl.TextColor3 = UI.text
    valLbl.Size = UDim2.new(0, 64, 0, 20)
    valLbl.Position = UDim2.new(1, -(56 + 12 + 220 + 8 + 64), 0.5, -10)
    local function fmt(n)
        local m = decimals or 0
        if m <= 0 then return tostring(math.floor(n+0.5)) end
        local p = 10^m
        return tostring(math.floor(n*p+0.5)/p)
    end
    local function setVal(n, fromDrag)
        n = math.clamp(n, min, max)
        _G[valueVar] = n
        valLbl.Text = fmt(n)
        local alpha = (n - min) / (max - min)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, -7, 0.5, -7)
        if valueVar == "fovValue" and _G.fovEnabled and cam then cam.FieldOfView = n end
        saveCfg()
        if not fromDrag then
            TS:Create(knob, TweenInfo.new(0.08), {BackgroundColor3 = UI.knob}):Play()
        end
    end
    setVal(_G[valueVar] or min)
    local draggingS = false
    local function posToVal(x)
        local ax = math.clamp(x - track.AbsolutePosition.X, 0, track.AbsoluteSize.X)
        local a = ax / track.AbsoluteSize.X
        return min + a*(max - min)
    end
    local tb = track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingS = true
            setVal(posToVal(i.Position.X), true)
            TS:Create(knob, TweenInfo.new(0.06), {BackgroundColor3 = UI.acc2}):Play()
        end
    end)
    local te = track.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingS = false
            TS:Create(knob, TweenInfo.new(0.1), {BackgroundColor3 = UI.knob}):Play()
        end
    end)
    local tc = UIS.InputChanged:Connect(function(i)
        if draggingS and i.UserInputType == Enum.UserInputType.MouseMovement then
            setVal(posToVal(i.Position.X), true)
        end
    end)
    table.insert(conns, tb); table.insert(conns, te); table.insert(conns, tc)
    return row
end

local function makeTabBar(parent)
    local bar = Instance.new("Frame")
    bar.Name = "Tabs"
    bar.Parent = parent
    bar.Size = UDim2.new(1, -20, 0, 28)
    bar.Position = UDim2.new(0, 10, 0, 42)
    bar.BackgroundTransparency = 1
    local list = Instance.new("UIListLayout", bar)
    list.FillDirection = Enum.FillDirection.Horizontal
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    local function makeBtn(txt, order)
        local b = Instance.new("TextButton")
        b.Name = "Tab_"..txt
        b.Parent = bar
        b.LayoutOrder = order or 1
        b.AutoButtonColor = false
        b.BackgroundTransparency = 1
        b.Size = UDim2.new(0, 120, 1, 0)
        b.Font = Enum.Font.GothamSemibold
        b.TextSize = 14
        b.Text = txt
        b.TextColor3 = UI.sub
        return b
    end
    local content = Instance.new("ScrollingFrame", parent)
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -110)
    content.Position = UDim2.new(0, 10, 0, 74)
    content.BackgroundColor3 = UI.bg2
    content.BorderSizePixel = 0
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ScrollBarThickness = 6
    content.ScrollBarImageTransparency = 0.2
    content.ScrollBarImageColor3 = UI.stroke
    round(content, UDim.new(0.05,0))
    stroke(content, 1, UI.stroke2, 0.22)
    grad(content, UI.bg2, UI.bg1, 90)
    local function makePage()
        local p = Instance.new("Frame")
        p.BackgroundTransparency = 1
        p.Size = UDim2.new(1, -20, 0, 0)
        p.Position = UDim2.new(0, 10, 0, 10)
        p.AutomaticSize = Enum.AutomaticSize.Y
        p.Parent = content
        local lay = Instance.new("UIListLayout", p)
        lay.Padding = UDim.new(0, 8)
        lay.FillDirection = Enum.FillDirection.Vertical
        lay.SortOrder = Enum.SortOrder.LayoutOrder
        return p
    end
    local btnAim = makeBtn("aim", 1)
    local btnTarget = makeBtn("target", 2)
    local btnESP = makeBtn("esp", 3)
    local btnStatus = makeBtn("status", 4)
    local btnSettings = makeBtn("settings", 5)
    local pgAim = makePage()
    local pgTarget = makePage()
    local pgESP = makePage()
    local pgStatus = makePage()
    local pgSettings = makePage()
    tabs = {
        aim = {btn = btnAim, page = pgAim, scroll = content},
        target = {btn = btnTarget, page = pgTarget, scroll = content},
        esp = {btn = btnESP, page = pgESP, scroll = content},
        status = {btn = btnStatus, page = pgStatus, scroll = content},
        settings = {btn = btnSettings, page = pgSettings, scroll = content},
    }
    for name, t in pairs(tabs) do
        local c = t.btn.MouseButton1Click:Connect(function() setTab(name) end)
        table.insert(conns, c)
    end
    setTab("aim")
    return tabs
end

local lastClickT = 0
local function triggerLoop()
    local conn = RunService.RenderStepped:Connect(function()
        if not _G.triggerBot then return end
        local now = time()
        local needInt = 1/math.max(1,_G.tbCPS or 8)
        if now - lastClickT < needInt then return end
        local hit = ms.Target
        if not hit then return end
        local cur = hit
        local mdl = nil
        while cur and cur ~= workspace do
            if cur:IsA("Model") then
                local hum = cur:FindFirstChildOfClass("Humanoid")
                if hum then mdl = cur break end
            end
            cur = cur.Parent
        end
        if not mdl then return end
        local hum = mdl:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return end
        local owner = Players:GetPlayerFromCharacter(mdl)
        if not owner or owner == plr then return end
        if not isEnemy(owner) then return end
        if _G.wallCheck then
            local part = topAimPart(mdl)
            if part and not clearLOS(part) then return end
        end
        if mouse1click then
            mouse1click()
        elseif mouse1press and mouse1release then
            mouse1press()
            task.defer(mouse1release)
        end
        lastClickT = now
    end)
    table.insert(conns, conn)
end

local function showTopBtn(state)
    if not topBtn then return end
    topBtn.Visible = state
    if state then
        TS:Create(topBtn, TweenInfo.new(0.2), {Position = UDim2.new(0.5, -70, 0, 6)}):Play()
    else
        TS:Create(topBtn, TweenInfo.new(0.2), {Position = UDim2.new(0.5, -70, -0.2, 0)}):Play()
    end
end

local function openUI()
    if not frm or not frm.Parent then return end
    TS:Create(frm, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -350, 0.08, 0)}):Play()
    uiMin = false
    showTopBtn(false)
end

local function closeUI()
    if not frm or not frm.Parent then return end
    TS:Create(frm, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -350, -1.4, 0)}):Play()
    uiMin = true
    showTopBtn(true)
    toast("UI minimized")
end

local function makeKeyChip(parent, keyName, onRemove)
    local chip = Instance.new("Frame", parent)
    chip.BackgroundColor3 = UI.bar2
    chip.Size = UDim2.new(0, 120, 0, 24)
    chip.BorderSizePixel = 0
    round(chip, UDim.new(0.15,0))
    stroke(chip, 1, UI.stroke2, 0.25)
    local tl = Instance.new("TextLabel", chip)
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.new(1, -30, 1, 0)
    tl.Position = UDim2.new(0, 8, 0, 0)
    tl.Font = Enum.Font.Gotham
    tl.TextSize = 13
    tl.TextColor3 = UI.text
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.TextTruncate = Enum.TextTruncate.AtEnd
    tl.Text = keyName
    task.defer(function()
        local w = math.clamp(tl.TextBounds.X + 36, 96, 200)
        chip.Size = UDim2.new(0, w, 0, 24)
    end)
    local rm = Instance.new("TextButton", chip)
    rm.Size = UDim2.new(0, 24, 0, 24)
    rm.Position = UDim2.new(1, -24, 0, 0)
    rm.BackgroundColor3 = UI.danger
    rm.Text = "x"
    rm.TextColor3 = Color3.new(1,1,1)
    rm.Font = Enum.Font.GothamSemibold
    rm.TextSize = 12
    rm.AutoButtonColor = false
    round(rm, UDim.new(0,6))
    local c = rm.MouseButton1Click:Connect(function()
        if onRemove then onRemove(keyName, chip) end
    end)
    table.insert(conns, c)
    return chip
end

local function createUI()
    cleanup()
    gui = Instance.new("ScreenGui", uiRoot)
    gui.Name = "AervanixBot"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn = false

    toastHolder = Instance.new("Frame", gui)
    toastHolder.Name = "ToastHolder"
    toastHolder.AnchorPoint = Vector2.new(0.5, 1)
    toastHolder.Position = UDim2.new(0.5, 0, 1, -16)
    toastHolder.Size = UDim2.new(0, 360, 0, 0)
    toastHolder.BackgroundTransparency = 1
    local tLayout = Instance.new("UIListLayout", toastHolder)
    tLayout.Padding = UDim.new(0, 8)
    tLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

    topBtn = Instance.new("TextButton", gui)
    topBtn.Name = "TopToggle"
    topBtn.Size = UDim2.new(0, 140, 0, 24)
    topBtn.Position = UDim2.new(0.5, -70, -0.2, 0)
    topBtn.BackgroundColor3 = UI.bar1
    topBtn.TextColor3 = UI.text
    topBtn.Text = "Open UI"
    topBtn.Font = Enum.Font.GothamSemibold
    topBtn.TextSize = 14
    topBtn.AutoButtonColor = false
    topBtn.Visible = false
    round(topBtn, UDim.new(0.2,0))
    stroke(topBtn, 1, UI.stroke2, 0.25)

    local frame = Instance.new("Frame", gui)
    frame.Name = "Root"
    frame.Size = UDim2.new(0, 700, 0, 520)
    frame.Position = UDim2.new(0.5, -350, 0.08, 0)
    frame.BackgroundColor3 = UI.panel
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frm = frame
    round(frame, UDim.new(0.06, 0))

    local bar = Instance.new("Frame", frame)
    bar.Name = "Bar"
    bar.Size = UDim2.new(1, 0, 0, 40)
    bar.Position = UDim2.new(0, 0, 0, 0)
    bar.BackgroundColor3 = UI.bar1
    bar.BorderSizePixel = 0
    round(bar, UDim.new(0.06, 0))

    local title = Instance.new("TextLabel", bar)
    title.Name = "Title"
    title.Size = UDim2.new(0, 260, 1, 0)
    title.Position = UDim2.new(0, 14, 0, 0)
    title.Text = "Aimbot - ltseverydayyou"
    title.TextColor3 = UI.text
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left

    local btnX = Instance.new("TextButton", bar)
    btnX.Name = "Close"
    btnX.Size = UDim2.new(0, 16, 0, 16)
    btnX.Position = UDim2.new(1, -22, 0.5, -8)
    btnX.Text = ""
    btnX.BackgroundColor3 = UI.danger
    btnX.BorderSizePixel = 0
    btnX.AutoButtonColor = false

    local btnMin = Instance.new("TextButton", bar)
    btnMin.Name = "Min"
    btnMin.Size = UDim2.new(0, 16, 0, 16)
    btnMin.Position = UDim2.new(1, -44, 0.5, -8)
    btnMin.Text = ""
    btnMin.BackgroundColor3 = UI.warn
    btnMin.BorderSizePixel = 0
    btnMin.AutoButtonColor = false

    round(btnX, UDim.new(1, 0)); round(btnMin, UDim.new(1, 0))
    styleWin(frame, bar, title, btnX, btnMin)

    local tabObjs = makeTabBar(frame)
    local pgAim = tabObjs.aim.page
    local pgTarget = tabObjs.target.page
    local pgESP = tabObjs.esp.page
    local pgStatus = tabObjs.status.page
    local pgSettings = tabObjs.settings.page

    addRowToggle(pgAim, "lock to torso", "isEnabled")
    addRowToggle(pgAim, "lock to head", "lockToHead")
    addRowToggle(pgAim, "lock to nearest", "lockToNearest")
    addRowToggle(pgAim, "wall check", "wallCheck")
    addRowToggleSlider(pgAim, "tween aim", "aimTween", "aimSmooth", 0.05, 0.2, 2, "smoothly rotate camera to target")
    addRowToggleSlider(pgAim, "aim prediction", "aimPredict", "aimLead", 0.01, 1, 2, "Predict enemy movement")
    addRowToggleSlider(pgAim, "lock fov", "fovEnabled", "fovValue", 1, 120, 0, "changes FOV :P")
    addRowToggleSlider(pgAim, "trigger bot", "triggerBot", "tbCPS", 1, 100, 0, "fires a click when hovering over enemy")

    addRowToggle(pgTarget, "team check", "teamCheck")
    addRowToggle(pgTarget, "alive check", "aliveCheck")

    addRowToggle(pgESP, "enable esp", "espEnabled")
    addRowToggle(pgESP, "team color", "espTeamColor")
    addRowToggle(pgESP, "show name", "espShowName")
    addRowToggle(pgESP, "show health", "espShowHP")
    addRowToggle(pgESP, "show team", "espShowTeam")

    local function addRow(parent, labelText, valueText, copyFn)
        local row = Instance.new("Frame", parent)
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, -20, 0, 26)
        local lbl = Instance.new("TextLabel", row)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = UI.sub
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Position = UDim2.new(0, 0, 0, 0)
        lbl.Size = UDim2.new(0, 220, 1, 0)
        local reserve = copyFn and 70 or 0
        local val = Instance.new("TextLabel", row)
        val.BackgroundTransparency = 1
        val.Text = valueText or ""
        val.TextColor3 = UI.text
        val.Font = Enum.Font.Gotham
        val.TextSize = 14
        val.TextXAlignment = Enum.TextXAlignment.Left
        val.Position = UDim2.new(0, 230, 0, 0)
        val.Size = UDim2.new(1, -(240 + reserve), 1, 0)
        if copyFn then
            local b = Instance.new("TextButton", row)
            b.Text = "copy"
            b.Font = Enum.Font.GothamSemibold
            b.TextSize = 12
            b.TextColor3 = UI.text
            b.AutoButtonColor = false
            b.BackgroundColor3 = UI.bar2
            b.Size = UDim2.new(0, 60, 0, 22)
            b.AnchorPoint = Vector2.new(1, 0.5)
            b.Position = UDim2.new(1, -4, 0.5, 0)
            stroke(b, 1, UI.stroke2, 0.25)
            round(b, UDim.new(0.15,0))
            local c = b.MouseButton1Click:Connect(function()
                local v = tostring(copyFn())
                if setclipboard then setclipboard(v) end
                toast("copied")
            end)
            table.insert(conns, c)
        end
        return val
    end

    local vPlayers = addRow(pgStatus, "players", "")
    local vTime = addRow(pgStatus, "time playing", "")
    local vNow = addRow(pgStatus, "current time", "")
    local vGame = addRow(pgStatus, "game name", game.Name or "unknown")
    local vPlace = addRow(pgStatus, "place id", tostring(game.PlaceId), function() return game.PlaceId end)
    local vGameId = addRow(pgStatus, "game id", tostring(game.GameId), function() return game.GameId end)
    local vJobId = addRow(pgStatus, "job id", tostring(game.JobId), function() return game.JobId end)
    local vDevice = addRow(pgStatus, "device", (UIS:GetPlatform() and UIS:GetPlatform().Name) or "unknown")
    local vLocale = addRow(pgStatus, "locale", (LS.RobloxLocaleId or "unknown").." / "..(LS.SystemLocaleId or "unknown"))
    local vExec = addRow(pgStatus, "executor", (identifyexecutor and identifyexecutor()) or (identifyexec and identifyexec()) or "Unknown")

    task.spawn(function()
        local ok, info = pcall(function() return MPS:GetProductInfo(game.PlaceId) end)
        if ok and info and info.Name then
            vGame.Text = info.Name
        end
    end)

    local setLbl = Instance.new("TextLabel", pgSettings)
    setLbl.BackgroundTransparency = 1
    setLbl.Text = "toggle keys"
    setLbl.TextColor3 = UI.sub
    setLbl.Font = Enum.Font.GothamMedium
    setLbl.TextSize = 14
    setLbl.TextXAlignment = Enum.TextXAlignment.Left
    setLbl.Size = UDim2.new(1, -20, 0, 24)

    local chips = Instance.new("Frame", pgSettings)
    chips.Name = "Keys"
    chips.BackgroundTransparency = 1
    chips.Size = UDim2.new(1, -20, 0, 32)
    local chipsLayout = Instance.new("UIListLayout", chips)
    chipsLayout.FillDirection = Enum.FillDirection.Horizontal
    chipsLayout.Padding = UDim.new(0, 6)
    chipsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    chipsLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local keysSet = {}
    for _, k in ipairs(_G.toggleKeys) do keysSet[k] = true end
    local function rebuildChips()
        for _, c in ipairs(chips:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
        for k,_ in pairs(keysSet) do
            makeKeyChip(chips, k, function(name, chip)
                keysSet[name] = nil
                if chip and chip.Parent then chip:Destroy() end
                local list = {}
                for n,_ in pairs(keysSet) do table.insert(list, n) end
                _G.toggleKeys = list
                saveCfg()
            end)
        end
    end
    rebuildChips()

    local addKey = Instance.new("TextButton", pgSettings)
    addKey.Text = "add key"
    addKey.Font = Enum.Font.GothamSemibold
    addKey.TextSize = 13
    addKey.TextColor3 = UI.text
    addKey.AutoButtonColor = false
    addKey.BackgroundColor3 = UI.ok
    addKey.Size = UDim2.new(0, 80, 0, 26)
    round(addKey, UDim.new(0.15,0))
    stroke(addKey, 1, UI.stroke2, 0.15)

    local clrKey = Instance.new("TextButton", pgSettings)
    clrKey.Text = "clear"
    clrKey.Font = Enum.Font.GothamSemibold
    clrKey.TextSize = 13
    clrKey.TextColor3 = UI.text
    clrKey.AutoButtonColor = false
    clrKey.BackgroundColor3 = UI.danger
    clrKey.Size = UDim2.new(0, 80, 0, 26)
    round(clrKey, UDim.new(0.15,0))
    stroke(clrKey, 1, UI.stroke2, 0.15)

    local btnRow = Instance.new("Frame", pgSettings)
    btnRow.BackgroundTransparency = 1
    btnRow.Size = UDim2.new(1, -20, 0, 4)

    local capConn

    local function stopCap()
        capMode = false
        capCooldownUntil = time() + 0.3
        if capConn and capConn.Connected then capConn:Disconnect() end
        capConn = nil
    end

    local addCon = addKey.MouseButton1Click:Connect(function()
        if capMode then return end
        capMode = true
        toast("press a key")
        capConn = UIS.InputBegan:Connect(function(i, gp)
            if gp then return end
            if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
            local kc = i.KeyCode
            if kc == Enum.KeyCode.Unknown then stopCap() return end
            local name = kc.Name
            if not keysSet[name] then
                keysSet[name] = true
                local list = {}
                for n,_ in pairs(keysSet) do table.insert(list, n) end
                _G.toggleKeys = list
                rebuildChips()
                saveCfg()
            end
            stopCap()
        end)
    end)
    table.insert(conns, addCon)

    local clrCon = clrKey.MouseButton1Click:Connect(function()
        keysSet = {}
        _G.toggleKeys = {}
        rebuildChips()
        saveCfg()
    end)
    table.insert(conns, clrCon)

    local statusLoop = RunService.Heartbeat:Connect(function()
        local num = Players.NumPlayers or #Players:GetPlayers()
        local max = Players.MaxPlayers or 0
        vPlayers.Text = tostring(num).." / "..tostring(max)
        local elapsed = DateTime.now().UnixTimestamp - startUnix
        local h = math.floor(elapsed/3600)
        local m = math.floor((elapsed%3600)/60)
        local s = elapsed%60
        vTime.Text = string.format("%02d:%02d:%02d", h, m, s)
        vNow.Text = os.date("%Y-%m-%d %H:%M:%S")
        vPlace.Text = tostring(game.PlaceId)
        vGameId.Text = tostring(game.GameId)
        vJobId.Text = tostring(game.JobId)
        vDevice.Text = (UIS:GetPlatform() and UIS:GetPlatform().Name) or "unknown"
        vLocale.Text = (LS.RobloxLocaleId or "unknown").." / "..(LS.SystemLocaleId or "unknown")
        vExec.Text = (identifyexecutor and identifyexecutor()) or (identifyexec and identifyexec()) or "Unknown"
    end)
    table.insert(conns, statusLoop)

    local minCon = btnMin.MouseButton1Click:Connect(function()
        if uiMin then openUI() else closeUI() end
    end)
    table.insert(conns, minCon)

    local topCon = topBtn.MouseButton1Click:Connect(function()
        if uiMin then openUI() end
    end)
    table.insert(conns, topCon)

    local closeCon = btnX.MouseButton1Click:Connect(function()
        for _, c in pairs(conns) do
            if typeof(c) == "RBXScriptConnection" and c.Connected then c:Disconnect() end
        end
        conns = {}
        isLock = false
        _G.isEnabled = false
        _G.lockToHead = false
        _G.espEnabled = false
        _G.lockToNearest = false
        _G.aliveCheck = false
        _G.teamCheck = false
        _G.wallCheck = false
        _G.triggerBot = false
        for p, _ in pairs(espMap) do espDetach(p) end
        espMap = {}
        CAS:UnbindAction("AervanixBot")
        toast("Aimbot unloaded")
        task.delay(0.5, function() if gui and gui.Parent then gui:Destroy() end end)
    end)
    table.insert(conns, closeCon)

    local barBegan = bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = frame.Position
        end
    end)
    table.insert(conns, barBegan)

    local barEnd = bar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    table.insert(conns, barEnd)

    local changedCon = UIS.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local d = i.Position - dragStart
            TS:Create(frame, TweenInfo.new(0.1), {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)}):Play()
        end
    end)
    table.insert(conns, changedCon)

    frame.Position = UDim2.new(0.5, -350, -0.5, 0)
    TS:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -350, 0.08, 0)}):Play()
    return frame
end

local function binds()
    local b1 = UIS.InputBegan:Connect(function(i, gp)
        if UIS:GetFocusedTextBox() then return end
        if i.UserInputType == Enum.UserInputType.MouseButton2 and _G.isEnabled then
            isLock = true
            if _G.fovEnabled and cam then cam.FieldOfView = _G.fovValue end
            lockCamera()
            return
        end
        if i.UserInputType == Enum.UserInputType.Keyboard then
            if capMode or time() < capCooldownUntil then return end
            local name = i.KeyCode.Name
            if table.find(_G.toggleKeys, name) then
                if not frm or not frm.Parent then return end
                if uiMin then openUI() else closeUI() end
            end
        end
    end)
    table.insert(conns, b1)
    local b2 = UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton2 then
            isLock = false
        end
    end)
    table.insert(conns, b2)
end

local lockActive = false
function lockCamera()
    if lockActive then return end
    lockActive = true
    local loop
    loop = RunService.RenderStepped:Connect(function()
        if not isLock or not _G.isEnabled then
            loop:Disconnect()
            lockActive = false
            return
        end
        local ch = findTarget()
        if ch then
            local part = topAimPart(ch)
            if part then
                local tgtPos = part.Position
                if _G.aimPredict then
                    local v = part.AssemblyLinearVelocity or part.Velocity or Vector3.zero
                    tgtPos = part.Position + v * (_G.aimLead or 0.12)
                end
                local cf = CFrame.new(cam.CFrame.Position, tgtPos)
                if _G.aimTween then
                    TS:Create(cam, TweenInfo.new(math.clamp(_G.aimSmooth or 0.15, 0.05, 0.2)), {CFrame = cf}):Play()
                else
                    cam.CFrame = cf
                end
            end
        end
    end)
    table.insert(conns, loop)
end

local function setupPlayerMonitoring()
    local function hook(pp)
        local ca = pp.CharacterAdded:Connect(function()
            task.wait(0.1)
            if _G.espEnabled then espAttach(pp) end
        end)
        table.insert(conns, ca)
    end
    for _, pp in ipairs(Players:GetPlayers()) do
        if pp ~= plr then hook(pp) end
    end
    local a = Players.PlayerAdded:Connect(function(pp)
        hook(pp)
        if _G.espEnabled then task.defer(function() espAttach(pp) end) end
    end)
    table.insert(conns, a)
    local r = Players.PlayerRemoving:Connect(function(pp)
        espDetach(pp)
    end)
    table.insert(conns, r)
    local c = plr.CharacterAdded:Connect(function()
        if not gui or not gui.Parent then
            frm = createUI()
            binds()
        end
        if _G.espEnabled then updateESP() end
    end)
    table.insert(conns, c)
end

frm = createUI()
binds()
setupPlayerMonitoring()
triggerLoop()
if _G.espEnabled then updateESP() end
toast("Aimbot loaded")
saveCfg()

local function chkMode()
    local newMode
    if #Players:GetPlayers() > 0 and Players.LocalPlayer.Team == nil then
        newMode = "FFA"
    else
        newMode = "Team"
    end
    if newMode ~= mode then
        mode = newMode
        lastMode = mode
        updateESP()
    end
end

local teamCon = RunService.RenderStepped:Connect(function() chkMode() end)
table.insert(conns, teamCon)

return function()
    for _, c in pairs(conns) do
        if typeof(c) == "RBXScriptConnection" and c.Connected then
            c:Disconnect()
        end
    end
    for p, _ in pairs(espMap) do espDetach(p) end
    if gui and gui.Parent then gui:Destroy() end
end