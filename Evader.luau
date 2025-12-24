local g = getgenv and getgenv() or _G
if g.evade_vyperia then return end
g.evade_vyperia = true

local srcUrl = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Evader.luau"

local srv = setmetatable({}, {
    __index = function(self, n)
        local ref = cloneref and type(cloneref) == "function" and cloneref or function(v) return v end
        local ok, s = pcall(function()
            return ref(game:GetService(n))
        end)
        if ok and s then
            rawset(self, n, s)
            return s
        end
    end
})

local function S(n)
    return srv[n]
end

local function qtp()
    local f = queueonteleport or queue_on_teleport or (syn and syn.queue_on_teleport)
    if not f then return end
    f(('loadstring(game:HttpGet("%s"))()'):format(srcUrl))
end

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Lib = loadstring(game:HttpGet(repo .. "Library.lua"))()
local Theme = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local Save = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Opt = Lib.Options
local Tog = Lib.Toggles

local foot = {
    "Try not to scream IRL.",
    "Certified nextbot juker.",
    "Mariah Carey is behind you.",
    "Evade now, question later.",
    "0 HP? Not on my watch.",
    "Oops, all jump scares.",
    "Respawn speedrun any%.",
    "Revive tax not included.",
    "Hitbox? I hardly know her.",
    "Bots fear this script.",
    "Evade.exe stopped responding.",
    "Skill issue mitigator.",
    "Powered by sheer panic.",
    "Walking L detector online.",
    "Sigma jukes enabled."
}

math.randomseed(tick())
local footer = foot[math.random(#foot)]

local win = Lib:CreateWindow({
    Title = "Evade - ltseverydayyou",
    Footer = footer,
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
    Center = true,
    AutoShow = true
})

Lib.ShowToggleFrameInKeybinds = true

local Tabs = {
    Main = win:AddTab("Main", "user"),
    Settings = win:AddTab("Settings", "settings")
}

local gbCore = Tabs.Main:AddLeftGroupbox("Core")
local gbESP = Tabs.Main:AddRightGroupbox("ESP")

gbCore:AddToggle("AutoRevive", {
    Text = "Auto Revive",
    Default = true,
    Tooltip = "Auto revives nearby downs."
})

gbCore:AddToggle("AutoSave", {
    Text = "Auto Save (Teleport)",
    Default = false,
    Tooltip = "TP under downs, then go back."
})

gbCore:AddToggle("AntiNextbot", {
    Text = "Anti Nextbot",
    Default = true,
    Tooltip = "Push away from nextbots."
})

gbCore:AddToggle("AutoRespawn", {
    Text = "Auto Respawn",
    Default = false,
    Tooltip = "Respawn at 0 HP."
})

gbCore:AddSlider("ReviveRange", {
    Text = "Revive Range",
    Min = 2,
    Max = 12,
    Default = 10,
    Rounding = 0
})

gbCore:AddSlider("NextbotRange", {
    Text = "Nextbot Distance",
    Min = 10,
    Max = 60,
    Default = 30,
    Rounding = 0
})

gbCore:AddSlider("SaveOffset", {
    Text = "Save Offset (Down)",
    Min = 3,
    Max = 10,
    Default = 6,
    Rounding = 0
})

gbCore:AddButton("Respawn", function()
    local rep = S("ReplicatedStorage")
    if not rep then return end
    local ev = rep:WaitForChild("Events"):WaitForChild("Player"):WaitForChild("ChangePlayerMode")
    ev:FireServer(true)
end)

gbESP:AddToggle("ESPPlayers", {
    Text = "Player ESP",
    Default = false,
    Tooltip = "ESP for alive players."
})

gbESP:AddToggle("ESPDead", {
    Text = "Downed ESP",
    Default = false,
    Tooltip = "ESP for downed players."
})

gbESP:AddToggle("ESPBots", {
    Text = "Nextbot ESP",
    Default = false,
    Tooltip = "ESP for nextbots."
})

gbESP:AddToggle("ESPShowDist", {
    Text = "Show Distance",
    Default = false,
    Tooltip = "Show studs on ESP."
})

gbESP:AddSlider("ESPTextSize", {
    Text = "Text Size",
    Min = 10,
    Max = 30,
    Default = 14,
    Rounding = 0
})

gbESP:AddSlider("ESPMaxDist", {
    Text = "ESP Max Distance",
    Min = 50,
    Max = 2000,
    Default = 500,
    Rounding = 0,
    Suffix = " studs"
})

gbESP:AddLabel("Player Color"):AddColorPicker("ESPPlayerColor", {
    Title = "Player Color",
    Default = Color3.fromRGB(0, 255, 0),
    Transparency = 0
})

gbESP:AddLabel("Downed Color"):AddColorPicker("ESPDeadColor", {
    Title = "Downed Color",
    Default = Color3.fromRGB(255, 0, 0),
    Transparency = 0
})

gbESP:AddLabel("Nextbot Color"):AddColorPicker("ESPBotColor", {
    Title = "Nextbot Color",
    Default = Color3.fromRGB(255, 255, 0),
    Transparency = 0
})

local gbScript = Tabs.Settings:AddLeftGroupbox("Script")
local gbUI = Tabs.Settings:AddRightGroupbox("Obsidian UI")

gbScript:AddToggle("RunOnTeleport", {
    Text = "Run on Teleport",
    Default = false,
    Tooltip = "Re-run script after teleport."
})

gbScript:AddLabel("Menu Bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu key"
})

gbScript:AddButton("Reload Run on Teleport", function()
    if Tog.RunOnTeleport and Tog.RunOnTeleport.Value then
        qtp()
    end
end)

gbScript:AddButton("Unload Script", function()
    Lib:Unload()
end)

gbUI:AddToggle("UICursor", {
    Text = "Custom Cursor",
    Default = true,
    Tooltip = "Toggle custom cursor.",
    Callback = function(v)
        Lib.ShowCustomCursor = v
    end
})

gbUI:AddToggle("UIWatermark", {
    Text = "FPS / Ping HUD",
    Default = true,
    Tooltip = "Show FPS and ping box."
})

gbUI:AddDropdown("NotifySide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Tooltip = "Where toasts appear.",
    Callback = function(v)
        if Lib.SetNotifySide then
            Lib:SetNotifySide(v)
        end
    end
})

gbUI:AddDropdown("DPIScale", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Tooltip = "Scale the UI.",
    Callback = function(v)
        if Lib.SetDPIScale then
            local n = tonumber(v:gsub("%%", ""))
            if n then
                Lib:SetDPIScale(n)
            end
        end
    end
})

gbUI:AddToggle("CompactSidebar", {
    Text = "Compact Sidebar",
    Default = false,
    Tooltip = "Thin sidebar layout.",
    Callback = function(v)
        if win.SetCompact then
            win:SetCompact(v)
        end
    end
})

Theme:SetLibrary(Lib)
Save:SetLibrary(Lib)
Save:IgnoreThemeSettings()
Save:SetFolder("NamelessAdmin")
Save:SetSubFolder("Evade_" .. tostring(game.PlaceId))
Save:BuildConfigSection(Tabs.Settings)
Theme:ApplyToTab(Tabs.Settings)
Save:LoadAutoloadConfig()

if Opt.MenuKeybind then
    Lib.ToggleKeybind = Opt.MenuKeybind
end

local autoRev = Tog.AutoRevive.Value
local autoSave = Tog.AutoSave.Value
local antiBot = Tog.AntiNextbot.Value
local autoResp = Tog.AutoRespawn.Value
local runTP = Tog.RunOnTeleport.Value

local revR = Opt.ReviveRange.Value
local botR = Opt.NextbotRange.Value
local saveOff = Opt.SaveOffset.Value

local espPl = Tog.ESPPlayers.Value
local espDn = Tog.ESPDead.Value
local espBt = Tog.ESPBots.Value
local espShow = Tog.ESPShowDist.Value
local espSize = Opt.ESPTextSize.Value
local espMax = Opt.ESPMaxDist.Value
local colPl = Opt.ESPPlayerColor.Value
local colDn = Opt.ESPDeadColor.Value
local colBt = Opt.ESPBotColor.Value

local wmOn = Tog.UIWatermark.Value

Tog.AutoRevive:OnChanged(function(v) autoRev = v end)
Tog.AutoSave:OnChanged(function(v) autoSave = v end)
Tog.AntiNextbot:OnChanged(function(v) antiBot = v end)
Tog.AutoRespawn:OnChanged(function(v) autoResp = v end)

Tog.RunOnTeleport:OnChanged(function(v)
    runTP = v
    if v then
        qtp()
    end
end)

Opt.ReviveRange:OnChanged(function(v) revR = v end)
Opt.NextbotRange:OnChanged(function(v) botR = v end)
Opt.SaveOffset:OnChanged(function(v) saveOff = v end)

Tog.ESPPlayers:OnChanged(function(v) espPl = v end)
Tog.ESPDead:OnChanged(function(v) espDn = v end)
Tog.ESPBots:OnChanged(function(v) espBt = v end)
Tog.ESPShowDist:OnChanged(function(v) espShow = v end)

Opt.ESPTextSize:OnChanged(function(v) espSize = v end)
Opt.ESPMaxDist:OnChanged(function(v) espMax = v end)
Opt.ESPPlayerColor:OnChanged(function(v) colPl = v end)
Opt.ESPDeadColor:OnChanged(function(v) colDn = v end)
Opt.ESPBotColor:OnChanged(function(v) colBt = v end)

Tog.UIWatermark:OnChanged(function(v)
    wmOn = v
end)

if runTP then
    qtp()
end

local NA_GRAB_BODY = (function()
    local T = {}
    local cache = _rp_cache or setmetatable({}, { __mode = "k" })

    local function asChar(o)
        if not o or typeof(o) ~= "Instance" then return nil end
        if o:IsA("Player") then return o.Character end
        if o:IsA("Model") then return o end
        return nil
    end

    local function firstPart(m)
        for _, d in ipairs(m:GetDescendants()) do
            if d:IsA("BasePart") then return d end
        end
        return nil
    end

    local function rebuild(ch, rec)
        local rp = { humanoidrootpart = 1, uppertorso = 2, lowertorso = 3, torso = 4 }
        local tp = { torso = 1, uppertorso = 2, lowertorso = 3, humanoidrootpart = 4 }
        local bestRoot, bestRootRank = nil, math.huge
        local bestTorso, bestTorsoRank = nil, math.huge
        local head, hum, fb = nil, nil, nil
        local q = { ch }
        local i = 1
        while i <= #q do
            local n = q[i]
            i = i + 1
            local kids = n:GetChildren()
            for k = 1, #kids do
                local c = kids[k]
                if not fb and c:IsA("BasePart") then
                    fb = c
                end
                if not hum and c:IsA("Humanoid") then
                    hum = c
                end
                if c:IsA("BasePart") then
                    local nm = string.lower(c.Name)
                    local rnk = rp[nm]
                    if rnk and rnk < bestRootRank then
                        bestRootRank = rnk
                        bestRoot = c
                    end
                    local tr = tp[nm]
                    if tr and tr < bestTorsoRank then
                        bestTorsoRank = tr
                        bestTorso = c
                    end
                    if not head and nm == "head" then
                        head = c
                    end
                end
                q[#q + 1] = c
            end
        end
        if not bestRoot then bestRoot = fb end
        if not bestTorso then bestTorso = fb end
        if not head then head = fb end
        rec.root = bestRoot
        rec.torso = bestTorso
        rec.head = head
        rec.humanoid = hum
        rec.dirty = false
    end

    local function ensure(ch)
        local m = asChar(ch)
        if not m then return nil end
        local rec = cache[m]
        if not rec then
            rec = { dirty = true }
            cache[m] = rec
            rec.a = m.DescendantAdded:Connect(function()
                rec.dirty = true
            end)
            rec.r = m.DescendantRemoving:Connect(function()
                rec.dirty = true
            end)
            rec.c = m.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    if rec.a then rec.a:Disconnect() end
                    if rec.r then rec.r:Disconnect() end
                    if rec.c then rec.c:Disconnect() end
                    cache[m] = nil
                end
            end)
        end
        if rec.dirty or (rec.humanoid and rec.humanoid.Parent == nil) then
            rebuild(m, rec)
        end
        return rec, m
    end

    T.ensure = ensure
    T.firstPart = firstPart

    return T
end)()

local rs = S("RunService")
local ps = S("Players")
local rep = S("ReplicatedStorage")
local ws = S("Workspace")
local cg = S("CoreGui")
local st = S("Stats")

local lp = ps.LocalPlayer
repeat task.wait() lp = ps.LocalPlayer until lp

local fps = 60
rs.RenderStepped:Connect(function(dt)
    if dt > 0 then
        fps = fps + ((1 / dt) - fps) * 0.1
    end
end)

local function getPing()
    local ok, v = pcall(function()
        if not st then return end
        local net = st:FindFirstChild("Network")
        if not net then return end
        local srv = net:FindFirstChild("ServerStatsItem")
        if not srv then return end
        local ping = srv:FindFirstChild("Data Ping") or srv:FindFirstChild("DataPing")
        if ping and ping.Value then
            return ping.Value
        end
    end)
    if ok and v then return v end
    return 0
end

local wmGui = Instance.new("ScreenGui")
wmGui.Name = "EvadeStatsHUD"
wmGui.ResetOnSpawn = false
wmGui.IgnoreGuiInset = true
wmGui.Enabled = wmOn
wmGui.Parent = (gethui and gethui()) or cg

local wmLbl = Instance.new("TextLabel")
wmLbl.Name = "StatsLabel"
wmLbl.Size = UDim2.new(0, 220, 0, 20)
wmLbl.Position = UDim2.new(0, 10, 0, 10)
wmLbl.BackgroundTransparency = 0.35
wmLbl.BackgroundColor3 = Color3.new(0, 0, 0)
wmLbl.TextColor3 = Color3.new(1, 1, 1)
wmLbl.Font = Enum.Font.Code
wmLbl.TextSize = 14
wmLbl.TextXAlignment = Enum.TextXAlignment.Left
wmLbl.Text = ""
wmLbl.Parent = wmGui

Tog.UIWatermark:OnChanged(function(v)
    wmOn = v
    wmGui.Enabled = v
end)

task.spawn(function()
    while true do
        if wmOn then
            local pf = math.floor(fps + 0.5)
            local pg = math.floor(getPing() + 0.5)
            wmLbl.Text = ("FPS: %d | Ping: %dms"):format(pf, pg)
        else
            wmLbl.Text = ""
        end
        task.wait(0.5)
    end
end)

local evt = rep:WaitForChild("Events"):WaitForChild("Character"):WaitForChild("Interact")
local respEvt = rep:WaitForChild("Events"):WaitForChild("Player"):WaitForChild("ChangePlayerMode")
local botFolder = ws:WaitForChild("Game"):WaitForChild("Players")

local function getChar()
    local rec, mdl = NA_GRAB_BODY.ensure(ps.LocalPlayer)
    if not rec then return nil end
    return mdl
end

local function getRoot(o)
    local rec, mdl = NA_GRAB_BODY.ensure(o)
    if not rec then return nil end
    return rec.root or (mdl and NA_GRAB_BODY.firstPart(mdl)) or nil
end

local others = {}

local function updOthers()
    table.clear(others)
    for _, p in ipairs(ps:GetPlayers()) do
        if p ~= lp then
            others[#others + 1] = p
        end
    end
end

updOthers()
ps.PlayerAdded:Connect(updOthers)
ps.PlayerRemoving:Connect(updOthers)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.IgnoreWater = true

local function getDown(pos)
    local bestP, bestRoot
    local bestDist = math.huge
    for i = 1, #others do
        local p = others[i]
        local rec, mdl = NA_GRAB_BODY.ensure(p)
        if rec and rec.humanoid then
            local hp = rec.humanoid.Health
            if hp <= 0 then
                local r2 = rec.root or (mdl and NA_GRAB_BODY.firstPart(mdl))
                if r2 then
                    local d = (pos - r2.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestP = p
                        bestRoot = r2
                    end
                end
            end
        end
    end
    return bestP, bestRoot, bestDist
end

local function getBot(pos)
    if not botFolder then return end
    local bestHit, bestDist, bestPos
    local kids = botFolder:GetChildren()
    for i = 1, #kids do
        local m = kids[i]
        local h = m:FindFirstChild("Hitbox")
        if h and h:IsA("BasePart") then
            local d = (pos - h.Position).Magnitude
            if not bestDist or d < bestDist then
                bestDist = d
                bestHit = h
                bestPos = h.Position
            end
        end
    end
    if not bestHit then return end
    return bestHit, bestDist, bestPos
end

local function getSafePos(curPos, ch, botPos, dist)
    rayParams.FilterDescendantsInstances = { ch }
    local away = Vector3.new(curPos.X - botPos.X, 0, curPos.Z - botPos.Z)
    local mag = away.Magnitude
    if mag < 1e-3 then
        away = Vector3.new(1, 0, 0)
        mag = 1
    end
    away = away / mag
    local baseCF = CFrame.new(Vector3.zero, away)
    local angs = { 0, 30, -30, 60, -60, 90, -90, 150, -150, 180 }
    local origin = botPos + Vector3.new(0, 2, 0)
    for i = 1, #angs do
        local ang = angs[i]
        local dir = (baseCF * CFrame.Angles(0, math.rad(ang), 0)).LookVector
        dir = Vector3.new(dir.X, 0, dir.Z)
        local dmag = dir.Magnitude
        if dmag > 1e-3 then
            dir = dir / dmag
            local res = ws:Raycast(origin, dir * dist, rayParams)
            local useDist = dist
            if res then
                useDist = res.Distance - 2
                if useDist < dist * 0.5 then
                    useDist = nil
                end
            end
            if useDist then
                local p = origin + dir * useDist
                return Vector3.new(p.X, curPos.Y, p.Z)
            end
        end
    end
    local fb = origin + away * dist * 0.5
    return Vector3.new(fb.X, curPos.Y, fb.Z)
end

local revCd = 0.1
local respCd = 0.5
local revLast = 0
local respLast = 0
local saveActive = false
local savePos
local saveTarget

local espParent = (gethui and gethui()) or cg
local espObjs = {}

local function setESP(key, adornee, txt, col, maxDist)
    local info = espObjs[key]
    if not adornee then
        if info and info.gui then
            info.gui:Destroy()
        end
        espObjs[key] = nil
        return
    end
    local gui = info and info.gui
    local lbl = info and info.lbl
    if not gui then
        gui = Instance.new("BillboardGui")
        gui.Name = "EvadeESP"
        gui.Adornee = adornee
        gui.Size = UDim2.new(0, 200, 0, 40)
        gui.AlwaysOnTop = true
        gui.MaxDistance = maxDist
        gui.LightInfluence = 0
        gui.Parent = espParent
        lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.TextStrokeTransparency = 0.5
        lbl.TextScaled = false
        lbl.TextSize = espSize
        lbl.Font = Enum.Font.GothamBold
        lbl.Parent = gui
        info = { gui = gui, lbl = lbl }
        espObjs[key] = info
    end
    gui.Adornee = adornee
    gui.MaxDistance = maxDist
    lbl.Text = txt
    lbl.TextColor3 = col
    lbl.TextSize = espSize
end

local function updESP()
    if not (espPl or espDn or espBt) then
        for _, info in pairs(espObjs) do
            if info.gui then info.gui:Destroy() end
        end
        table.clear(espObjs)
        return
    end
    local vis = {}
    local selfCh = getChar()
    local selfRoot = selfCh and getRoot(selfCh)
    local selfPos = selfRoot and selfRoot.Position or nil
    local maxD = espMax

    if espPl or espDn then
        for i = 1, #others do
            local p = others[i]
            local rec, mdl = NA_GRAB_BODY.ensure(p)
            if rec and rec.root and rec.humanoid then
                local hp = rec.humanoid.Health
                local dead = hp <= 0
                local root = rec.root or (mdl and NA_GRAB_BODY.firstPart(mdl))
                local ok = true
                local dt = ""
                if selfPos and root then
                    local d = (selfPos - root.Position).Magnitude
                    if d > maxD then
                        ok = false
                    else
                        if espShow then
                            dt = " [" .. tostring(math.floor(d)) .. "u]"
                        end
                    end
                end
                local key = "pl_" .. p.UserId
                local show = ok and ((dead and espDn) or ((not dead) and espPl))
                if show then
                    vis[key] = true
                    local t = dead and (p.Name .. " [DOWN]") or (p.Name .. " [" .. math.floor(hp) .. "]")
                    t = t .. dt
                    local c = dead and colDn or colPl
                    setESP(key, root, t, c, maxD)
                end
            end
        end
    end

    if espBt and botFolder then
        local kids = botFolder:GetChildren()
        for i = 1, #kids do
            local m = kids[i]
            local h = m:FindFirstChild("Hitbox")
            if h and h:IsA("BasePart") then
                local root = h
                local ok = true
                local dt = ""
                if selfPos and root then
                    local d = (selfPos - root.Position).Magnitude
                    if d > maxD then
                        ok = false
                    else
                        if espShow then
                            dt = " [" .. tostring(math.floor(d)) .. "u]"
                        end
                    end
                end
                if ok then
                    local key = "nb_" .. m:GetDebugId()
                    vis[key] = true
                    local t = m.Name .. dt
                    setESP(key, root, t, colBt, maxD)
                end
            end
        end
    end

    for k, info in pairs(espObjs) do
        if not vis[k] then
            if info.gui then info.gui:Destroy() end
            espObjs[k] = nil
        end
    end
end

task.spawn(function()
    while true do
        task.wait(0.2)
        updESP()
    end
end)

rs.Heartbeat:Connect(function()
    local ch = getChar()
    if not ch then return end
    local r = getRoot(ch)
    if not r then return end

    local recSelf = NA_GRAB_BODY.ensure(ps.LocalPlayer)
    local hum = recSelf and recSelf.humanoid
    local pos = r.Position
    local t = tick()

    local downP, downRoot, downDist = getDown(pos)

    if autoRev and evt and revR > 0 and downP and downDist <= revR and t - revLast >= revCd then
        revLast = t
        evt:FireServer("Revive", true, downP.Name)
    end

    if autoRev and autoSave and downP and downRoot and not saveActive then
        saveActive = true
        savePos = pos
        saveTarget = downP
    end

    if saveActive and saveTarget then
        local recT, mdlT = NA_GRAB_BODY.ensure(saveTarget)
        local humT = recT and recT.humanoid
        local rootT = recT and (recT.root or (mdlT and NA_GRAB_BODY.firstPart(mdlT))) or nil
        if not humT or humT.Parent == nil or humT.Health > 0 then
            if savePos then
                r.CFrame = CFrame.new(savePos, savePos + r.CFrame.LookVector)
            end
            saveActive = false
            savePos = nil
            saveTarget = nil
        else
            if rootT then
                local tpPos = rootT.Position - Vector3.new(0, saveOff, 0)
                if (r.Position - tpPos).Magnitude > 1 then
                    r.CFrame = CFrame.new(tpPos, tpPos + r.CFrame.LookVector)
                end
            end
        end
    end

    if autoResp and respEvt and hum and hum.Health <= 0 and t - respLast >= respCd then
        respLast = t
        respEvt:FireServer(true)
    end

    if antiBot and botR > 0 then
        local hit, dist, botPos = getBot(pos)
        if hit and dist and dist < botR then
            local safePos = getSafePos(pos, ch, botPos, botR)
            if safePos and (safePos - pos).Magnitude > 1 then
                r.CFrame = CFrame.new(safePos, safePos + r.CFrame.LookVector)
            end
        end
    end
end)