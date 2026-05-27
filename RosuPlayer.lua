local ap = {}

ap.has = {
    cloneref = type(cloneref) == "function",
    loadstring = type(loadstring) == "function"
}

ap.clear = function(t)
    if type(t) ~= "table" then
        return
    end

    if type(table.clear) == "function" then
        table.clear(t)
        return
    end

    for k in pairs(t) do
        t[k] = nil
    end
end

ap.clock = function()
    if type(os) == "table" and type(os.clock) == "function" then
        return os.clock()
    end

    return tick()
end

ap.svc = function(n)
    if type(cloneref) == "function" then
        local ok, v = pcall(function()
            return cloneref(game:GetService(n))
        end)

        if ok and v then
            return v
        end
    end

    local ok, v = pcall(function()
        return game:GetService(n)
    end)

    if ok then
        return v
    end

    return nil
end

ap.trygc = function()
    return nil
end

ap.http = function(url)
    if type(game.HttpGet) == "function" then
        local ok, res = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and type(res) == "string" then
            return res
        end
    end

    if type(httpget) == "function" then
        local ok, res = pcall(httpget, url)
        if ok and type(res) == "string" then
            return res
        end
    end

    return nil
end

ap.load = function(url)
    if type(loadstring) ~= "function" then
        return nil
    end

    local src = ap.http(url)
    if not src then
        return nil
    end

    local ok, res = pcall(function()
        return loadstring(src)()
    end)

    if ok then
        return res
    end

    warn("[autoplayer] failed to load " .. tostring(url) .. ": " .. tostring(res))
    return nil
end


do
    local ok, sh = pcall(function()
        return shared
    end)

    if ok and type(sh) == "table" then
        local old = rawget(sh, "__rosu_ap")
        if type(old) == "table" and type(old.stop) == "function" then
            pcall(old.stop)
        end
        rawset(sh, "__rosu_ap", ap)
    end
end

ap.cfg = {
    on = true,
    hold = true,
    new = true,
    win = 0.07,
    hwin = 0.08,
    lead = -0.065,
    rlead = 0,
    holdlate = 0.02,
    tap = 0.045,
    pulse = 0.025,
    autorescan = true
}

ap.con = {}
ap.down = {}
ap.hold = {}
ap.hit = setmetatable({}, { __mode = "k" })
ap.seen = setmetatable({}, { __mode = "k" })
ap.bind = "ap_" .. tostring(math.random(10000, 99999))

ap.plrs = ap.svc("Players")
ap.rs = ap.svc("ReplicatedStorage")
ap.run = ap.svc("RunService")
ap.uis = ap.svc("UserInputService")
ap.lp = ap.plrs and ap.plrs.LocalPlayer

if not ap.plrs or not ap.rs or not ap.run or not ap.uis or not ap.lp then
    warn("[autoplayer] missing required Roblox services")
    return
end

pcall(function()
    ap.vim = Instance.new("VirtualInputManager")
end)

if not ap.vim then
    pcall(function()
        ap.vim = ap.svc("VirtualInputManager")
    end)
end

ap.def = {
    Enum.KeyCode.D,
    Enum.KeyCode.F,
    Enum.KeyCode.J,
    Enum.KeyCode.K
}

ap.num = {
    ["1"] = "One",
    ["2"] = "Two",
    ["3"] = "Three",
    ["4"] = "Four",
    ["5"] = "Five",
    ["6"] = "Six",
    ["7"] = "Seven",
    ["8"] = "Eight",
    ["9"] = "Nine",
    ["0"] = "Zero"
}

ap.add = function(c)
    if c then
        ap.con[#ap.con + 1] = c
    end
    return c
end

ap.live = function(x)
    return typeof(x) == "Instance" and x.Parent ~= nil
end

ap.vis = function(x)
    if not ap.live(x) then
        return false
    end

    local y = x
    while y and y ~= ap.pg do
        if y:IsA("GuiObject") and y.Visible == false then
            return false
        end
        y = y.Parent
    end

    return true
end

ap.nvis = function(n)
    if not ap.live(n) then
        return false
    end

    if n:IsA("GuiObject") then
        return n.Visible ~= false
    end

    local h = n:FindFirstChild("Head")
    local t = n:FindFirstChild("Tail")
    local b = n:FindFirstChild("Body")

    if h or t or b then
        if h and h:IsA("GuiObject") and h.Visible ~= false then
            return true
        end
        if t and t:IsA("GuiObject") and t.Visible ~= false then
            return true
        end
        if b and b:IsA("GuiObject") and b.Visible ~= false then
            return true
        end
        return true
    end

    return true
end

ap.upscroll = function()
    local cfg = ap.rs:FindFirstChild("Configuration")
    local up = cfg and cfg:FindFirstChild("LaneUpscroll")
    return up and up:IsA("BoolValue") and up.Value == true
end

ap.maplane = function(i)
    if ap.upscroll() then
        return 5 - i
    end

    return i
end

ap.badframe = function(v)
    local y = v
    while y and y ~= ap.pg do
        local n = y.Name
        if n == "Preview" or n == "SkinMechanics" or n == "SkinsFrame" or n == "MENUS" then
            return true
        end
        y = y.Parent
    end
    return false
end

ap.goodroot = function(r)
    return r
        and r:FindFirstChild("DebugFrame")
        and r:FindFirstChild("FailedFrame")
        and r:FindFirstChild("RankingScreen")
end

ap.findroot = function()
    if ap.root and ap.goodroot(ap.root) then
        return ap.root
    end

    ap.pg = ap.lp and ap.lp:FindFirstChildOfClass("PlayerGui")
    if not ap.pg then
        return nil
    end

    for _, r in ipairs(ap.pg:GetChildren()) do
        if r:FindFirstChild("MENUS") and r:FindFirstChild("GameplayFrame") and ap.goodroot(r) then
            ap.root = r
            return r
        end
    end

    return nil
end

ap.startscan = function()
    if ap.dead or not ap.cfg.autorescan then
        return
    end

    ap.g = nil
    ap.root = ap.findroot() or ap.root
    ap.inp = nil
    ap.ctx = nil
    ap.reset(true)
    ap.defer(0.05)

    local delays = { 0.45, 1.25, 2.5, 4.5, 7.5, 11, 15.5 }

    for _, d in ipairs(delays) do
        task.delay(d, function()
            if ap.dead or not ap.cfg.autorescan then
                return
            end

            if ap.g and ap.active(ap.g) and ap.isinp(ap.inp) then
                return
            end

            ap.g = nil
            ap.inp = nil
            ap.ctx = nil
            ap.defer(0.01)
        end)
    end
end

ap.ui = function()
    ap.pg = ap.lp and ap.lp:FindFirstChildOfClass("PlayerGui")
    if not ap.pg then
        return
    end

    local root = ap.findroot()
    local g = root and root:FindFirstChild("GameplayFrame")

    if g and g:IsA("GuiObject") and not ap.badframe(g) then
        local tr = g:FindFirstChild("Tracks")
        local tb = g:FindFirstChild("TriggerButtons")
        if tr and tb and ap.vis(g) then
            ap.root = root
            return g
        end
    end

    local fb = nil

    for _, v in ipairs(ap.pg:GetDescendants()) do
        if v:IsA("GuiObject") and v.Name == "GameplayFrame" and not ap.badframe(v) then
            local tr = v:FindFirstChild("Tracks")
            local tb = v:FindFirstChild("TriggerButtons")
            local root = v.Parent

            if tr and tb and ap.vis(v) then
                if ap.goodroot(root) then
                    ap.root = root
                    return v
                end

                if not fb then
                    fb = v
                end
            end
        end
    end

    if fb then
        ap.root = fb.Parent
    end

    return fb
end

ap.active = function(g)
    if not g or not ap.vis(g) then
        return false
    end

    local tr = g:FindFirstChild("Tracks")
    local tb = g:FindFirstChild("TriggerButtons")

    if not tr or not tb then
        return false
    end

    local y = g.Position.Y.Scale
    if y > 2 or y < -1 then
        return false
    end

    if ap.root then
        local ff = ap.root:FindFirstChild("FailedFrame")
        local rs = ap.root:FindFirstChild("RankingScreen")

        if ff and ff:IsA("GuiObject") and ff.Visible then
            return false
        end

        if rs and rs:IsA("GuiObject") and rs.Visible then
            return false
        end
    end

    return true
end

ap.key = function(i)
    local idx = ap.maplane(i)
    local cfg = ap.rs:FindFirstChild("Configuration")
    local kb = cfg and cfg:FindFirstChild("Keybinds")
    local val = kb and kb:FindFirstChild("Track" .. idx)
    local txt = val and tostring(val.Value) or ""
    txt = txt:gsub("Enum.KeyCode.", ""):gsub("%s+", "")
    local nam = ap.num[txt] or txt
    return Enum.KeyCode[nam] or ap.def[idx] or ap.def[i]
end

ap.isinp = function(v)
    return false
end

ap.findinp = function(force)
    return nil
end

ap.kdn = function(k)
    if not ap.vim then
        return false
    end

    local ok = pcall(function()
        ap.vim:SendKeyEvent(true, k, false, game)
    end)

    if ok then
        return true, "vim"
    end

    return false
end

ap.kup = function(k, mode)
    if ap.vim then
        pcall(function()
            ap.vim:SendKeyEvent(false, k, false, game)
        end)
    end

    return true
end

ap.dn = function(i, force)
    if ap.down[i] then
        if not force then
            return
        end
        ap.up(i)
    end

    local k = ap.key(i)
    local ok, mode = ap.kdn(k)
    if ok then
        ap.down[i] = { key = k, mode = mode, t = ap.clock() }
    end
end

ap.up = function(i)
    local d = ap.down[i]
    if not d then
        return
    end

    ap.down[i] = nil
    ap.hold[i] = nil
    ap.kup(d.key or d, d.mode)
end

ap.rel = function(force)
    for i = 1, 4 do
        ap.up(i)
    end
end

ap.reset = function(full)
    ap.rel(true)
    ap.clear(ap.down)
    ap.clear(ap.hold)
    ap.hit = setmetatable({}, { __mode = "k" })
    ap.seen = setmetatable({}, { __mode = "k" })

    if full then
        ap.g = nil
        ap.root = nil
        ap.inp = nil
        ap.ctx = nil
        ap.nextinp = 0
    end
end

ap.defer = function(delay)
    if not ap.cfg.autorescan or ap.dead then
        return
    end

    local t = ap.clock() + (delay or 0.15)

    if not ap.needscan or t < ap.needscan then
        ap.needscan = t
    end
end

ap.watch = function(g)
    if ap.watched == g then
        return
    end

    ap.watched = g

    if ap.watchcon then
        for _, c in ipairs(ap.watchcon) do
            pcall(function()
                c:Disconnect()
            end)
        end
    end

    ap.watchcon = {}

    local root = g and g.Parent
    ap.root = root

    local function add(c)
        if c then
            ap.watchcon[#ap.watchcon + 1] = c
        end
    end

    if root then
        local ff = root:FindFirstChild("FailedFrame")
        local rs = root:FindFirstChild("RankingScreen")

        if ff and ff:IsA("GuiObject") then
            add(ff:GetPropertyChangedSignal("Visible"):Connect(function()
                ap.rel(true)
                if not ff.Visible then
                    ap.defer(0.2)
                end
            end))
        end

        if rs and rs:IsA("GuiObject") then
            add(rs:GetPropertyChangedSignal("Visible"):Connect(function()
                ap.rel(true)
                if not rs.Visible then
                    ap.defer(0.2)
                end
            end))
        end

        add(root.ChildAdded:Connect(function(ch)
            if ch.Name == "GameplayFrame" or ch.Name == "FailedFrame" or ch.Name == "RankingScreen" then
                ap.defer(0.1)
            end
        end))
    end
end

ap.setupwatch = function()
    ap.pg = ap.lp and ap.lp:FindFirstChildOfClass("PlayerGui")
    if not ap.pg then
        return
    end

    local root = ap.findroot()

    if root then
        local menus = root:FindFirstChild("MENUS")
        local sel = menus and menus:FindFirstChild("SelectionFrame")
        local start = menus and menus:FindFirstChild("StartFrame")
        local msg = root:FindFirstChild("Message")

        if sel and sel:IsA("GuiObject") then
            ap.add(sel:GetPropertyChangedSignal("Visible"):Connect(function()
                if not sel.Visible then
                    ap.startscan()
                end
            end))
        end

        if start and start:IsA("GuiObject") then
            ap.add(start:GetPropertyChangedSignal("Visible"):Connect(function()
                if not start.Visible and (not sel or not sel.Visible) then
                    ap.startscan()
                end
            end))
        end

        if msg and msg:IsA("GuiObject") then
            ap.add(msg:GetPropertyChangedSignal("Visible"):Connect(function()
                if not msg.Visible and (not sel or not sel.Visible) then
                    ap.g = nil
                    ap.inp = nil
                    ap.ctx = nil
                    ap.defer(0.05)
                end
            end))
        end
    end

    ap.add(ap.pg.DescendantAdded:Connect(function(v)
        if not ap.cfg.autorescan or ap.dead then
            return
        end

        local n = v.Name
        if n == "GameplayFrame" or n == "Tracks" or n == "TriggerButtons" or n == "FailedFrame" or n == "RankingScreen" then
            ap.defer(0.2)
        end
    end))
end

ap.tap = function(i)
    if ap.hold[i] then
        return
    end

    ap.dn(i, true)

    task.delay(math.max(ap.cfg.tap, ap.cfg.pulse), function()
        if not ap.hold[i] then
            ap.up(i)
        end
    end)
end

ap.kind = function(n)
    if not ap.live(n) then
        return
    end

    local nm = string.lower(n.Name)

    if nm == "noteproto" or nm == "note" then
        return "tap"
    end

    if nm == "heldnoteproto" or nm == "heldnote" then
        return "hold"
    end

    if n:FindFirstChild("Head") and n:FindFirstChild("Tail") then
        return "hold"
    end

    if nm:find("held") then
        return "hold"
    end

    if nm:find("note") and not nm:find("track") then
        return "tap"
    end
end

ap.scl = function(g)
    if g and g:IsA("GuiObject") then
        return g.Position.Y.Scale
    end
end

ap.hd = function(n)
    local h = n:FindFirstChild("Head")
    local t = n:FindFirstChild("Tail")
    local b = n:FindFirstChild("Body")

    local hy = h and h:IsA("GuiObject") and ap.scl(h) or nil
    local ty = t and t:IsA("GuiObject") and ap.scl(t) or nil

    if hy or ty then
        return hy or ty, ty or hy, h or b or n, t or b or n, b
    end

    local y = ap.scl(n)
    return y, y, n, n, nil
end

ap.tar = function()
    return 1 - ap.cfg.lead
end

ap.was = function(n, y, span, life)
    local r = ap.seen[n]
    if not r then
        return false
    end

    if ap.clock() - r.t > (life or 0.35) then
        ap.seen[n] = nil
        return false
    end

    return math.abs((y or 0) - (r.y or 0)) <= (span or 0.2)
end

ap.mark = function(n, y)
    ap.seen[n] = {
        y = y or 0,
        t = ap.clock()
    }
end

ap.hready = function(n)
    local h = n and n:FindFirstChild("Head")
    if h and h:IsA("GuiObject") then
        return h.Visible ~= false
    end
    return true
end

ap.tapok = function(n)
    local y = ap.scl(n)
    if not y then
        return false, math.huge
    end

    if ap.was(n, y, 0.18, 0.25) then
        return false, math.huge
    end

    local d = math.abs(y - ap.tar())
    return d <= ap.cfg.win, d
end

ap.holdok = function(n)
    if not ap.hready(n) then
        return false, math.huge
    end

    local h = ap.hd(n)
    if not h then
        return false, math.huge
    end

    if ap.was(n, h, 0.18, 0.4) then
        return false, math.huge
    end

    local d = math.abs(h - ap.tar())
    return d <= ap.cfg.hwin, d
end

ap.rtar = function()
    local v = 1 - ap.cfg.rlead
    if v > 1 then
        return 1
    end
    if v < 0 then
        return 0
    end
    return v
end

ap.hrelok = function(hd, now)
    local n = hd and hd.n
    if not n then
        return false
    end

    local _, t = ap.hd(n)
    if not t then
        return false
    end

    if not hd.lasttail then
        hd.lasttail = t
    end

    local target = ap.rtar()
    local crossed = t >= target or (hd.lasttail < target and t >= target)
    hd.lasttail = t

    if crossed then
        if ap.cfg.holdlate <= 0 then
            return true
        end
        hd.ready = hd.ready or now
        return now - hd.ready >= ap.cfg.holdlate
    end

    hd.ready = nil
    return false
end

ap.best = function(tr)
    local ht = nil
    local hd = math.huge
    local tp = nil
    local td = math.huge

    for _, n in ipairs(tr:GetChildren()) do
        if ap.nvis(n) then
            local k = ap.kind(n)

            if k == "hold" then
                local ok, d = ap.holdok(n)
                if d < hd and d <= ap.cfg.hwin * 3 then
                    ht = n
                    hd = d
                end
            elseif k == "tap" then
                local ok, d = ap.tapok(n)
                if d < td and d <= ap.cfg.win * 3 then
                    tp = n
                    td = d
                end
            end
        end
    end

    if ht and hd <= ap.cfg.hwin then
        return ht, "hold"
    end

    if tp and td <= ap.cfg.win then
        return tp, "tap"
    end
end

ap.sync = function()
    local cfg = ap.rs:FindFirstChild("Configuration")
    if not cfg then
        return
    end

    if ap.cfg.new then
        local v = cfg:FindFirstChild("UseNewInput")
        if v and v:IsA("BoolValue") and v.Value == false then
            v.Value = true
        end
    end
end

ap.step = function()
    if ap.dead or not ap.cfg.on then
        return
    end

    local now = ap.clock()

    if ap.needscan and now >= ap.needscan then
        ap.needscan = nil
        ap.reset(true)
        ap.g = ap.ui()
    elseif not ap.g or not ap.live(ap.g) then
        if now >= (ap.nextui or 0) then
            ap.nextui = now + 3
            ap.rel(true)
            ap.g = ap.ui()
        end
    end

    if not ap.g or not ap.active(ap.g) then
        if not ap.idle then
            ap.idle = true
            ap.rel(true)
        end
        return
    end

    ap.idle = false


    if ap.lastg ~= ap.g then
        ap.lastg = ap.g
        ap.reset(false)
        ap.watch(ap.g)
    end

    ap.sync()

    local trf = ap.g:FindFirstChild("Tracks")
    if not trf then
        return
    end

    for i = 1, 4 do
        local tr = trf:FindFirstChild("Track" .. i)

        if not tr then
            ap.up(i)
            continue
        end

        local hd = ap.hold[i]

        if hd then
            local hn = hd.n or hd

            if ap.nvis(hn) then
                ap.dn(i)

                if ap.hrelok(hd, now) then
                    local _, ty = ap.hd(hn)
                    ap.mark(hn, ty)
                    ap.up(i)
                end

                continue
            end

            local _, ty = ap.hd(hn)
            ap.mark(hn, ty)
            ap.up(i)
        end

        local n, k = ap.best(tr)

        if n then
            if k == "hold" and ap.cfg.hold then
                local hy = ap.hd(n)
                ap.dn(i, true)
                if ap.down[i] then
                    ap.mark(n, hy)
                    ap.hold[i] = {
                        n = n,
                        ready = nil,
                        started = now
                    }
                end
            else
                local y = ap.scl(n)
                ap.mark(n, y)
                ap.tap(i)
            end
        elseif not ap.hold[i] then
            ap.up(i)
        end
    end
end

ap.ntf = function(t, d)
    if ap.lib and type(ap.lib.Notify) == "function" then
        pcall(function()
            ap.lib:Notify({
                Title = t,
                Description = d,
                Time = 3
            })
        end)
    else
        warn("[autoplayer] " .. tostring(d or t))
    end
end
ap.capmsg = function()
    local parts = {}
    parts[#parts + 1] = "input=VirtualInputManager"
    parts[#parts + 1] = "vim=" .. tostring(ap.vim ~= nil)
    parts[#parts + 1] = "loadstring=" .. tostring(type(loadstring) == "function")
    parts[#parts + 1] = "cloneref=" .. tostring(type(cloneref) == "function")
    return table.concat(parts, " | ")
end


ap.stop = function()
    if ap.dead then
        return
    end

    ap.dead = true
    ap.cfg.on = false

    pcall(function()
        ap.run:UnbindFromRenderStep(ap.bind)
    end)

    ap.rel(true)

    if ap.watchcon then
        for _, c in ipairs(ap.watchcon) do
            pcall(function()
                c:Disconnect()
            end)
        end
        ap.clear(ap.watchcon)
    end

    for _, c in ipairs(ap.con) do
        pcall(function()
            c:Disconnect()
        end)
    end

    ap.clear(ap.con)
    ap.clear(ap.down)
    ap.clear(ap.hold)

    if ap.lib and not ap.uic then
        ap.uic = true
        pcall(function()
            ap.lib:Unload()
        end)
    end

    warn("[autoplayer] unloaded")
end

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local lib = ap.load(repo .. "Library.lua")
local tm = ap.load(repo .. "addons/ThemeManager.lua")
local sm = ap.load(repo .. "addons/SaveManager.lua")

if not lib then
    warn("[autoplayer] Obsidian failed to load. loadstring/HttpGet is required for the UI.")
    return
end

ap.lib = lib

local tog = lib.Toggles
local opt = lib.Options

lib.ForceCheckbox = false
lib.ShowToggleFrameInKeybinds = false

local win = lib:CreateWindow({
    Title = "rosu!mania Autoplayer",
    NotifySide = "Right",
    ShowCustomCursor = true,
    AutoShow = true
})

local tabs = {
    Main = win:AddTab("Main", "music"),
    Settings = win:AddTab("Settings", "settings")
}

local main = tabs.Main:AddLeftGroupbox("Autoplayer", "play")
local tune = tabs.Main:AddRightGroupbox("Timing", "sliders")
local act = tabs.Main:AddRightGroupbox("Actions", "wrench")

main:AddToggle("ApEnabled", {
    Text = "Enabled",
    Default = ap.cfg.on
})

main:AddToggle("ApHold", {
    Text = "Hold Notes",
    Default = ap.cfg.hold
})



tune:AddSlider("ApWin", {
    Text = "Tap Window",
    Default = ap.cfg.win,
    Min = 0.01,
    Max = 0.18,
    Rounding = 3,
    Suffix = " scale"
})

tune:AddSlider("ApHWin", {
    Text = "Hold Start Window",
    Default = ap.cfg.hwin,
    Min = 0.01,
    Max = 0.16,
    Rounding = 3,
    Suffix = " scale"
})

tune:AddSlider("ApLead", {
    Text = "Hit Lead",
    Default = ap.cfg.lead,
    Min = -0.12,
    Max = 0.12,
    Rounding = 3,
    Suffix = " scale"
})

tune:AddSlider("ApRLead", {
    Text = "Hold Tail Target",
    Default = ap.cfg.rlead,
    Min = 0,
    Max = 0.12,
    Rounding = 3,
    Suffix = " scale"
})

tune:AddSlider("ApHoldLate", {
    Text = "Hold Extra Time",
    Default = ap.cfg.holdlate,
    Min = 0,
    Max = 0.16,
    Rounding = 3,
    Suffix = "s"
})

tune:AddSlider("ApTap", {
    Text = "Tap Duration",
    Default = ap.cfg.tap,
    Min = 0.01,
    Max = 0.18,
    Rounding = 3,
    Suffix = "s"
})

tune:AddSlider("ApPulse", {
    Text = "Minimum Key Hold",
    Default = ap.cfg.pulse,
    Min = 0.01,
    Max = 0.18,
    Rounding = 3,
    Suffix = "s"
})






act:AddButton({
    Text = "Print Keybinds",
    Func = function()
        local cfg = ap.rs:FindFirstChild("Configuration")
        local kb = cfg and cfg:FindFirstChild("Keybinds")
        if not kb then
            ap.ntf("Autoplayer", "Keybinds folder not found")
            return
        end

        local msg = ""
        for i = 1, 4 do
            local v = kb:FindFirstChild("Track" .. i)
            msg = msg .. "Track" .. i .. "=" .. tostring(v and v.Value or "nil") .. (i < 4 and " | " or "")
        end
        ap.ntf("Keybinds", msg)
    end
})

act:AddButton({
    Text = "Print Compatibility",
    Func = function()
        ap.ntf("Compatibility", ap.capmsg())
    end
})

act:AddButton({
    Text = "Rescan Gameplay",
    Func = function()
        ap.reset(true)
        ap.ntf("Autoplayer", "Gameplay cache reset")
    end
})

act:AddButton({
    Text = "Release Inputs",
    Func = function()
        ap.rel(true)
        ap.ntf("Autoplayer", "Released all inputs")
    end
})

act:AddButton({
    Text = "Unload",
    Func = function()
        ap.stop()
    end,
    DoubleClick = true
})

tog.ApEnabled:OnChanged(function()
    ap.cfg.on = tog.ApEnabled.Value

    if not ap.cfg.on then
        ap.rel()
    end

    ap.ntf("Autoplayer", ap.cfg.on and "Enabled" or "Disabled")
end)

tog.ApHold:OnChanged(function()
    ap.cfg.hold = tog.ApHold.Value

    if not ap.cfg.hold then
        ap.rel()
    end
end)




opt.ApWin:OnChanged(function()
    ap.cfg.win = opt.ApWin.Value
end)

opt.ApHWin:OnChanged(function()
    ap.cfg.hwin = opt.ApHWin.Value
end)

opt.ApLead:OnChanged(function()
    ap.cfg.lead = opt.ApLead.Value
end)

opt.ApRLead:OnChanged(function()
    ap.cfg.rlead = opt.ApRLead.Value
end)

opt.ApHoldLate:OnChanged(function()
    ap.cfg.holdlate = opt.ApHoldLate.Value
end)

opt.ApTap:OnChanged(function()
    ap.cfg.tap = opt.ApTap.Value
end)

opt.ApPulse:OnChanged(function()
    ap.cfg.pulse = opt.ApPulse.Value
end)

if tm and sm then
    tm:SetLibrary(lib)
    sm:SetLibrary(lib)
    sm:IgnoreThemeSettings()
    sm:SetIgnoreIndexes({})
    tm:SetFolder("rosu_autoplayer")
    sm:SetFolder("rosu_autoplayer/config")
    sm:BuildConfigSection(tabs.Settings)
    tm:ApplyToTab(tabs.Settings)
    sm:LoadAutoloadConfig()
end

ap.setupwatch()
ap.defer(0.05)

ap.run:BindToRenderStep(ap.bind, Enum.RenderPriority.Input.Value, ap.step)

ap.ntf("Autoplayer", "Loaded | " .. ap.capmsg())