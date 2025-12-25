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
local Lib = loadstring(game:HttpGet(repo.."Library.lua"))()
local Theme = loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))()
local Save = loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))()

local Opt = Lib.Options
local Tog = Lib.Toggles

local foot = {
    "Try not to scream IRL",
    "Certified nextbot juker",
    "Mariah Carey is behind you",
    "Evade now, question later",
    "0 HP? Not on my watch",
    "Oops, all jump scares",
    "Respawn speedrun any%",
    "Revive tax not included",
    "Hitbox? I hardly know her",
    "Bots fear this script",
    "Evade.exe stopped responding",
    "Skill issue mitigator",
    "Powered by sheer panic",
    "Walking L detector online",
    "Sigma jukes enabled"
}

math.randomseed(tick())
local footer = foot[math.random(#foot)]

local win = Lib:CreateWindow({
    Title = "Evader",
    Footer = footer,
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
local gbInfo = Tabs.Main:AddRightGroupbox("Info")

gbCore:AddToggle("AutoRevive", {
    Text = "Auto Revive",
    Default = true,
    Tooltip = "Auto revives nearby downs"
})

gbCore:AddToggle("AutoSave", {
    Text = "Auto Save (Teleport)",
    Default = false,
    Tooltip = "TP under downs, then go back"
})

gbCore:AddToggle("AntiNextbot", {
    Text = "Anti Nextbot",
    Default = true,
    Tooltip = "Push away from nextbots"
})

gbCore:AddToggle("AntiSafeZone", {
    Text = "Anti SafeZone",
    Default = true,
    Tooltip = "Keep you out of SafeZones"
})

gbCore:AddToggle("AutoRespawn", {
    Text = "Auto Respawn",
    Default = false,
    Tooltip = "Respawn at 0 HP"
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

gbCore:AddSlider("SafeZoneDistance", {
    Text = "SafeZone Distance",
    Min = 3,
    Max = 25,
    Default = 8,
    Rounding = 0,
    Suffix = " studs"
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
    Tooltip = "ESP for alive players"
})

gbESP:AddToggle("ESPDead", {
    Text = "Downed ESP",
    Default = false,
    Tooltip = "ESP for downed players"
})

gbESP:AddToggle("ESPBots", {
    Text = "Nextbot ESP",
    Default = false,
    Tooltip = "ESP for nextbots"
})

gbESP:AddToggle("ESPSafeZones", {
    Text = "SafeZone ESP",
    Default = false,
    Tooltip = "Show SafeZone hitboxes"
})

gbESP:AddToggle("ESPShowDist", {
    Text = "Show Distance",
    Default = false,
    Tooltip = "Show studs on ESP"
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

local infoTimerLabel = gbInfo:AddLabel("Timer: 00:00")

local gbScript = Tabs.Settings:AddLeftGroupbox("Script")
local gbUI = Tabs.Settings:AddRightGroupbox("Obsidian UI")

gbScript:AddToggle("RunOnTeleport", {
    Text = "Run on Teleport",
    Default = false,
    Tooltip = "Re-run script after teleport"
})

gbScript:AddLabel("Menu Bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightControl",
    NoUI = true,
    Text = "Menu key"
})

gbScript:AddToggle("DebugLogs", {
    Text = "Debug Logs",
    Default = false,
    Tooltip = "Show debug notifications"
})

gbScript:AddButton("Reload Run on Teleport", function()
    if Tog.RunOnTeleport and Tog.RunOnTeleport.Value then
        qtp()
    end
end)

local running = true
local conns = {}
local espObjs = {}
local wmGui, wmLbl

local function addConn(sig, fn)
    local c = sig:Connect(fn)
    conns[#conns + 1] = c
    return c
end

gbScript:AddButton("Unload Script", function()
    running = false
    for _, c in ipairs(conns) do
        c:Disconnect()
    end
    conns = {}
    for _, info in pairs(espObjs) do
        if info.gui then
            info.gui:Destroy()
        end
    end
    espObjs = {}
    if wmGui then
        wmGui:Destroy()
        wmGui = nil
        wmLbl = nil
    end
    Lib:Unload()
    g.evade_vyperia = nil
end)

gbUI:AddToggle("UICursor", {
    Text = "Custom Cursor",
    Default = true,
    Tooltip = "Toggle custom cursor",
    Callback = function(v)
        Lib.ShowCustomCursor = v
    end
})

gbUI:AddToggle("UIWatermark", {
    Text = "FPS / Ping HUD",
    Default = false,
    Tooltip = "Show FPS and ping box"
})

gbUI:AddDropdown("NotifySide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Tooltip = "Where toasts appear",
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
    Tooltip = "Scale the UI",
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
    Tooltip = "Thin sidebar layout",
    Callback = function(v)
        if win.SetCompact then
            win:SetCompact(v)
        end
    end
})

Theme:SetLibrary(Lib)
Save:SetLibrary(Lib)
Save:IgnoreThemeSettings()
Save:SetFolder("Evader")
Save:SetSubFolder("Evade_"..tostring(game.PlaceId))
Save:BuildConfigSection(Tabs.Settings)
Theme:ApplyToTab(Tabs.Settings)
Save:LoadAutoloadConfig()

if Opt.MenuKeybind then
    Lib.ToggleKeybind = Opt.MenuKeybind
end

local autoRev = Tog.AutoRevive.Value
local autoSave = Tog.AutoSave.Value
local antiBot = Tog.AntiNextbot.Value
local antiSZ = Tog.AntiSafeZone and Tog.AntiSafeZone.Value or true
local autoResp = Tog.AutoRespawn.Value
local runTP = Tog.RunOnTeleport.Value
local debugOn = Tog.DebugLogs.Value

local revR = Opt.ReviveRange.Value
local botR = Opt.NextbotRange.Value
local saveOff = Opt.SaveOffset.Value
local szDist = Opt.SafeZoneDistance and Opt.SafeZoneDistance.Value or 8

local espPl = Tog.ESPPlayers.Value
local espDn = Tog.ESPDead.Value
local espBt = Tog.ESPBots.Value
local szEsp = Tog.ESPSafeZones and Tog.ESPSafeZones.Value or false
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
Tog.DebugLogs:OnChanged(function(v) debugOn = v end)

if Tog.AntiSafeZone then
    Tog.AntiSafeZone:OnChanged(function(v)
        antiSZ = v
    end)
end

Opt.ReviveRange:OnChanged(function(v) revR = v end)
Opt.NextbotRange:OnChanged(function(v) botR = v end)
Opt.SaveOffset:OnChanged(function(v) saveOff = v end)

if Opt.SafeZoneDistance then
    Opt.SafeZoneDistance:OnChanged(function(v)
        szDist = v
    end)
end

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
    if wmGui then
        wmGui.Enabled = v
    end
end)

local safeZoneParts = {}

local function dbg(msg)
    if not debugOn then return end
    local ok = true
    if Lib.Notify then
        ok = pcall(function()
            Lib:Notify({
                Title = "Evader Debug",
                Description = msg,
                Time = 4,
            })
        end)
    end
    if not ok then
        local sg = S("StarterGui")
        if sg then
            pcall(function()
                sg:SetCore("SendNotification", { Title = "Evader Debug", Text = msg, Duration = 4 })
            end)
        end
    end
end

if Tog.ESPSafeZones then
    Tog.ESPSafeZones:OnChanged(function(v)
        szEsp = v
        refreshSafeZones()
    end)
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
            if d:IsA("BasePart") then
                return d
            end
        end
        return nil
    end

    local function rebuild(ch, rec)
        local rp = { humanoidrootpart = 1, uppertorso = 2, lowertorso = 3, torso = 4 }
        local tp = { torso = 1, uppertorso = 2, lowertorso = 3, humanoidrootpart = 4 }
        local bestRoot, bestRootRank = nil, math.huge
        local bestTorso, bestTorsoRank = nil, math.huge
        local head, hum, fb = nil, nil, nil
        local partCount = 0
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
                    partCount += 1
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
        rec.partCount = partCount
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
addConn(rs.RenderStepped, function(dt)
    if not running then return end
    if dt > 0 then
        fps = fps + ((1 / dt) - fps) * 0.1
    end
end)

local function getPing()
    local ok, v = pcall(function()
        if not st then return 0 end
        local net = st:WaitForChild("Network")
        local serverItem = net:WaitForChild("ServerStatsItem")
        local pingItem = serverItem:WaitForChild("Data Ping")
        local s = pingItem:GetValueString()
        local num = tonumber(s:match("%d+")) or 0
        return num
    end)
    if ok and v then return v end
    return 0
end

wmGui = Instance.new("ScreenGui")
wmGui.Name = "EvadeStatsHUD"
wmGui.ResetOnSpawn = false
wmGui.IgnoreGuiInset = true
wmGui.Enabled = wmOn
wmGui.Parent = (gethui and gethui()) or cg

wmLbl = Instance.new("TextLabel")
wmLbl.Name = "StatsLabel"
wmLbl.Size = UDim2.new(0, 220, 0, 20)
wmLbl.AnchorPoint = Vector2.new(0.5, 0)
wmLbl.Position = UDim2.new(0.5, 0, 0, 10)
wmLbl.BackgroundTransparency = 0.35
wmLbl.BackgroundColor3 = Color3.new(0, 0, 0)
wmLbl.TextColor3 = Color3.new(1, 1, 1)
wmLbl.Font = Enum.Font.Code
wmLbl.TextSize = 14
wmLbl.TextXAlignment = Enum.TextXAlignment.Left
wmLbl.Text = ""
wmLbl.Active = true
wmLbl.Draggable = true
wmLbl.Parent = wmGui

Tog.UIWatermark:OnChanged(function(v)
    wmOn = v
    if wmGui then
        wmGui.Enabled = v
    end
end)

task.spawn(function()
    while running do
        if wmOn and wmGui and wmLbl then
            local pf = math.floor(fps + 0.5)
            local pg = math.floor(getPing() + 0.5)
            wmLbl.Text = ("FPS: %d | Ping: %dms"):format(pf, pg)
        end
        task.wait(0.5)
    end
end)

local gameStats
pcall(function()
    local gFolder = ws:WaitForChild("Game", 5)
    if gFolder then
        gameStats = gFolder:WaitForChild("Stats", 5)
    end
end)

task.spawn(function()
    if not gameStats or not infoTimerLabel then return end
    while running do
        local v = gameStats:GetAttribute("Timer")
        if typeof(v) == "number" then
            local sec = math.max(0, math.floor(v - 1))
            local m = math.floor(sec / 60)
            local s = sec % 60
            infoTimerLabel:SetText(("Timer: %02d:%02d"):format(m, s))
        end
        task.wait(1)
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
addConn(ps.PlayerAdded, function()
    if not running then return end
    updOthers()
end)

addConn(ps.PlayerRemoving, function()
    if not running then return end
    updOthers()
end)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.IgnoreWater = true

local function isPointInPart(part, pos)
    local rel = part.CFrame:PointToObjectSpace(pos)
    local s = part.Size * 0.5
    return math.abs(rel.X) <= s.X and math.abs(rel.Y) <= s.Y and math.abs(rel.Z) <= s.Z
end

local function isInSafeZone(pos)
    for i = 1, #safeZoneParts do
        local p = safeZoneParts[i]
        if p.Parent and isPointInPart(p, pos) then
            return true
        end
    end
    return false
end

local function isCharInSafeZone(ch)
    if not ch then return false end
    for _, part in ipairs(ch:GetDescendants()) do
        if part:IsA("BasePart") then
            local p = part.Position
            for i = 1, #safeZoneParts do
                local sz = safeZoneParts[i]
                if sz.Parent and isPointInPart(sz, p) then
                    return true
                end
            end
        end
    end
    return false
end

local function getCharSafeZoneContact(ch)
    if not ch then return nil, nil, nil end
    for _, part in ipairs(ch:GetDescendants()) do
        if part:IsA("BasePart") then
            local p = part.Position
            for i = 1, #safeZoneParts do
                local sz = safeZoneParts[i]
                if sz.Parent and isPointInPart(sz, p) then
                    return part, sz, p
                end
            end
        end
    end
    return nil, nil, nil
end

local function refreshSafeZones()
    for i = 1, #safeZoneParts do
        local part = safeZoneParts[i]
        if part and part:IsA("BasePart") then
            local sb = part:FindFirstChild("EvadeSafeZoneSB")
            if sb then
                sb:Destroy()
            end
        end
    end
    table.clear(safeZoneParts)
    local gFolder = ws:FindFirstChild("Game")
    if not gFolder then return end
    for _, inst in ipairs(gFolder:GetDescendants()) do
        if inst:IsA("Model") and inst.Name == "SafeZones" then
            for _, ch in ipairs(inst:GetDescendants()) do
                if ch:IsA("BasePart") then
                    safeZoneParts[#safeZoneParts + 1] = ch
                    if szEsp then
                        local sb = ch:FindFirstChild("EvadeSafeZoneSB")
                        if not sb then
                            sb = Instance.new("SelectionBox")
                            sb.Name = "EvadeSafeZoneSB"
                            sb.Adornee = ch
                            sb.LineThickness = 0.02
                            sb.Color3 = Color3.fromRGB(180, 0, 255)
                            sb.SurfaceColor3 = Color3.fromRGB(120, 0, 200)
                            sb.SurfaceTransparency = 0.85
                            sb.Parent = ch
                        end
                    end
                end
            end
        end
    end
end

refreshSafeZones()
task.spawn(function()
    while running do
        refreshSafeZones()
        task.wait(5)
    end
end)

if Tog.ESPSafeZones then
    Tog.ESPSafeZones:OnChanged(function(v)
        szEsp = v
        refreshSafeZones()
    end)
end

local function getDown(pos)
    local bestP, bestRoot
    local bestDist = math.huge
    for i = 1, #others do
        local p = others[i]
        local rec, mdl = NA_GRAB_BODY.ensure(p)
        if rec and rec.humanoid and (rec.partCount or 0) >= 3 then
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
    local bestRoot, bestDist, bestPos
    local kids = botFolder:GetChildren()
    for i = 1, #kids do
        local m = kids[i]
        if m:IsA("Model") then
            local pl = ps:GetPlayerFromCharacter(m)
            if not pl then
                local hit = m:FindFirstChild("Hitbox")
                local root
                if hit and hit:IsA("BasePart") then
                    root = hit
                else
                    local humRoot = m:FindFirstChild("HumanoidRootPart")
                    if humRoot and humRoot:IsA("BasePart") then
                        root = humRoot
                    else
                        local rec = NA_GRAB_BODY.ensure(m)
                        root = rec and (rec.root or NA_GRAB_BODY.firstPart(m)) or nil
                    end
                end
                if root then
                    local d = (pos - root.Position).Magnitude
                    if not bestDist or d < bestDist then
                        bestDist = d
                        bestRoot = root
                        bestPos = root.Position
                    end
                end
            end
        end
    end
    if not bestRoot then return end
    return bestRoot, bestDist, bestPos
end

local function buildFilter(ch)
    local list = { ch }
    for i = 1, #safeZoneParts do
        list[#list + 1] = safeZoneParts[i]
    end
    return list
end

local function getSafePos(curPos, ch, botPos, dist)
    rayParams.FilterDescendantsInstances = buildFilter(ch)
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
                local pos = Vector3.new(p.X, curPos.Y, p.Z)
                if not isInSafeZone(pos) then
                    return pos
                end
            end
        end
    end
    local fb = origin + away * dist * 0.5
    local fbPos = Vector3.new(fb.X, curPos.Y, fb.Z)
    if not isInSafeZone(fbPos) then
        return fbPos
    end
    return nil
end

local function attachToGround(pos, ch)
    rayParams.FilterDescendantsInstances = buildFilter(ch)
    local origin = pos + Vector3.new(0, 50, 0)
    local res = ws:Raycast(origin, Vector3.new(0, -500, 0), rayParams)
    if res then
        local p = Vector3.new(pos.X, res.Position.Y + 3, pos.Z)
        if not isInSafeZone(p) then
            return p
        end
    end
    return nil
end

local function pushOutOfSafeZone(ch, r)
    local hitPart, hitZone = getCharSafeZoneContact(ch)
    if not hitPart or not hitZone then return false end
    local rootPos = r.Position
    local rel = hitZone.CFrame:PointToObjectSpace(rootPos)
    local hs = hitZone.Size * 0.5
    local dx = hs.X - math.abs(rel.X)
    local dz = hs.Z - math.abs(rel.Z)
    local axis = dx < dz and "X" or "Z"
    local dirLocal
    if axis == "X" then
        dirLocal = Vector3.new(rel.X >= 0 and 1 or -1, 0, 0)
    else
        dirLocal = Vector3.new(0, 0, rel.Z >= 0 and 1 or -1)
    end
    local dirWorld = hitZone.CFrame:VectorToWorldSpace(dirLocal)
    local dir = Vector3.new(dirWorld.X, 0, dirWorld.Z)
    if dir.Magnitude < 1e-3 then
        dir = Vector3.new(1, 0, 0)
    end
    dir = dir.Unit
    local step = 2
    local maxPush = math.max(szDist, 8)
    local target
    for d = step, maxPush, step do
        local testPos = rootPos + dir * d
        if not isInSafeZone(testPos) then
            target = testPos
            break
        end
    end
    if not target then
        local alt = {30, -30, 60, -60, 90, -90, 150, -150, 180}
        local baseCF = CFrame.new(Vector3.zero, dir)
        for i = 1, #alt do
            local a = alt[i]
            local v = (baseCF * CFrame.Angles(0, math.rad(a), 0)).LookVector
            v = Vector3.new(v.X, 0, v.Z)
            if v.Magnitude > 1e-3 then
                v = v.Unit
                for d = step, maxPush, step do
                    local testPos = rootPos + v * d
                    if not isInSafeZone(testPos) then
                        target = testPos
                        break
                    end
                end
                if target then
                    break
                end
            end
        end
    end
    if target then
        local newPos = target + Vector3.new(0, 0.1, 0)
        r.CFrame = CFrame.new(newPos, newPos + r.CFrame.LookVector)
        r.AssemblyLinearVelocity = Vector3.new()
        r.AssemblyAngularVelocity = Vector3.new()
        dbg("SafeZone push")
        return true
    end
    return false
end

local revCd = 0.1
local respCd = 0.5
local revLast = 0
local respLast = 0
local saveActive = false
local savePos
local saveTarget
local lastSafePos

local espParent = Instance.new("ScreenGui")
espParent.Name = "EvadeESPContainer"
espParent.ResetOnSpawn = false
espParent.IgnoreGuiInset = true
espParent.Parent = (gethui and gethui()) or cg

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
        lbl.TextColor3 = col
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
    if not running then return end
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
            if rec and rec.root and rec.humanoid and (rec.partCount or 0) >= 3 then
                local hp = rec.humanoid.Health
                local dead = hp <= 0
                local root = rec.root or (mdl and NA_GRAB_BODY.firstPart(mdl))
                local ok = true
                local dt = ""
                local dist
                if selfPos and root then
                    dist = (selfPos - root.Position).Magnitude
                    if dist > maxD then
                        ok = false
                    else
                        if espShow then
                            dt = " | "..tostring(math.floor(dist))
                        end
                    end
                end
                local key = "pl_"..p.UserId
                local show = ok and ((dead and espDn) or ((not dead) and espPl))
                if show then
                    vis[key] = true
                    local t = dead and (p.Name.." [DOWN]") or (p.Name.." ["..math.floor(hp).."]")
                    t = t..dt
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
            if m:IsA("Model") then
                local pl = ps:GetPlayerFromCharacter(m)
                if not pl then
                    local hit = m:FindFirstChild("Hitbox")
                    local root
                    if hit and hit:IsA("BasePart") then
                        root = hit
                    else
                        local humRoot = m:FindFirstChild("HumanoidRootPart")
                        if humRoot and humRoot:IsA("BasePart") then
                            root = humRoot
                        else
                            local rec = NA_GRAB_BODY.ensure(m)
                            root = rec and (rec.root or NA_GRAB_BODY.firstPart(m)) or nil
                        end
                    end
                    if root then
                        local ok = true
                        local dt = ""
                        local dist
                        if selfPos then
                            dist = (selfPos - root.Position).Magnitude
                            if dist > maxD then
                                ok = false
                            else
                                if espShow then
                                    dt = " | "..tostring(math.floor(dist))
                                end
                            end
                        end
                        if ok then
                            local key = "nb_"..m:GetDebugId()
                            vis[key] = true
                            local t = m.Name..dt
                            setESP(key, root, t, colBt, maxD)
                        end
                    end
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
    while running do
        task.wait(0.2)
        updESP()
    end
end)

addConn(rs.Heartbeat, function()
    if not running then return end
    local ch = getChar()
    if not ch then return end
    local r = getRoot(ch)
    if not r then return end

    local recSelf = NA_GRAB_BODY.ensure(ps.LocalPlayer)
    local hum = recSelf and recSelf.humanoid
    local pos = r.Position
    local t = tick()
    local maxVoidDist = 800

    if autoResp and respEvt and t - respLast >= respCd then
        local need = false
        if hum then
            if hum.Health <= 0 then
                need = true
            end
        else
            need = true
        end
        if need then
            respLast = t
            respEvt:FireServer(true)
            dbg("Auto Respawn: fired")
        end
    end

    if hum and not saveActive then
        rayParams.FilterDescendantsInstances = buildFilter(ch)
        local groundHit = ws:Raycast(pos + Vector3.new(0, 5, 0), Vector3.new(0, -1000, 0), rayParams)
        if groundHit and not isCharInSafeZone(ch) then
            lastSafePos = groundHit.Position + Vector3.new(0, 3, 0)
        elseif not groundHit and lastSafePos then
            local dist = (pos - lastSafePos).Magnitude
            local drop = lastSafePos.Y - pos.Y
            local vy = -r.AssemblyLinearVelocity.Y
            if dist > maxVoidDist then
                lastSafePos = nil
            elseif drop > 60 or vy > 100 then
                r.CFrame = CFrame.new(lastSafePos, lastSafePos + r.CFrame.LookVector)
                r.AssemblyLinearVelocity = Vector3.new()
                r.AssemblyAngularVelocity = Vector3.new()
                dbg("Void fail-safe")
                return
            end
        end
    end

    if saveActive and not autoSave then
        if savePos then
            local back = attachToGround(savePos, ch) or savePos
            r.CFrame = CFrame.new(back, back + r.CFrame.LookVector)
        end
        r.AssemblyLinearVelocity = Vector3.new()
        r.AssemblyAngularVelocity = Vector3.new()
        saveActive = false
        savePos = nil
        saveTarget = nil
        dbg("Auto Save: cancelled")
    end

    if antiSZ then
        if pushOutOfSafeZone(ch, r) then
            return
        end
    end

    local downP, downRoot, downDist = getDown(pos)

    if autoRev and evt and revR > 0 and downP and downDist <= revR and t - revLast >= revCd then
        revLast = t
        evt:FireServer("Revive", true, downP.Name)
    end

    if autoRev and autoSave and downP and downRoot and not saveActive then
        saveActive = true
        savePos = lastSafePos or pos
        saveTarget = downP
        dbg("Auto Save: saving "..downP.Name)
    end

    if saveActive and saveTarget and autoSave then
        local recT, mdlT = NA_GRAB_BODY.ensure(saveTarget)
        local humT = recT and recT.humanoid
        local rootT = recT and (recT.root or (mdlT and NA_GRAB_BODY.firstPart(mdlT))) or nil
        if not humT or humT.Parent == nil or humT.Health > 0 or (recT.partCount or 0) < 3 then
            if savePos then
                local back = attachToGround(savePos, ch) or savePos
                r.CFrame = CFrame.new(back, back + r.CFrame.LookVector)
            end
            r.AssemblyLinearVelocity = Vector3.new()
            r.AssemblyAngularVelocity = Vector3.new()
            saveActive = false
            savePos = nil
            saveTarget = nil
            dbg("Auto Save: returned to start")
        else
            if rootT then
                local tpPos = rootT.Position - Vector3.new(0, saveOff, 0)
                if (r.Position - tpPos).Magnitude > 1 then
                    r.CFrame = CFrame.new(tpPos, tpPos + r.CFrame.LookVector)
                end
                r.AssemblyLinearVelocity = Vector3.new()
                r.AssemblyAngularVelocity = Vector3.new()
            end
        end
    end

    if antiBot and botR > 0 then
        local hit, dist, botPos = getBot(pos)
        if hit and dist and dist < botR then
            local safePos = getSafePos(pos, ch, botPos, botR)
            if safePos then
                rayParams.FilterDescendantsInstances = buildFilter(ch)
                local groundSafe = ws:Raycast(safePos + Vector3.new(0, 50, 0), Vector3.new(0, -200, 0), rayParams)
                if groundSafe then
                    local p = groundSafe.Position + Vector3.new(0, 3, 0)
                    if not isInSafeZone(p) and (p - pos).Magnitude > 1 then
                        r.CFrame = CFrame.new(p, p + r.CFrame.LookVector)
                        r.AssemblyLinearVelocity = Vector3.new()
                        r.AssemblyAngularVelocity = Vector3.new()
                    end
                end
            end
        end
    end
end)
