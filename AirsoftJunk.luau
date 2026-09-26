local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local State = {
    AimPart = "Head",
    AimFov = 250,
    SilentAim = false,
    Wallbang = false,
    NoRecoil = false,
    InfiniteAmmo = false,
    NoSpread = false,
    NoDrop = false,
    RapidFire = false,
    RapidFireRate = 1800,
    WalkSpeed = 16,
    JumpPower = 50,
    Hitbox = false,
    HitboxPart = "Head",
    HitboxSize = 6,
    HitboxTransparency = 0.65,
    TeamCheck = true,
    Unloaded = false,
}

local Connections = {}
local HitboxOriginals = setmetatable({}, { __mode = "k" })
local Originals = {
    recoil = setmetatable({}, { __mode = "k" }),
    spread = setmetatable({}, { __mode = "k" }),
    drop = setmetatable({}, { __mode = "k" }),
    fireRate = setmetatable({}, { __mode = "k" }),
}

local AmmoContext = {
    Tool = nil,
    Shoot = nil,
    Value = nil,
}

local MovementKeys = {
    "NormalWalkSpeed",
    "RunWalkSpeed",
    "AimWalkSpeed",
    "CrouchWalkSpeed",
    "ProneWalksSpeed",
    "JumpPower",
}

local ACSConfig
local MovementOriginals = {}

pcall(function()
    ACSConfig = require(ReplicatedStorage:WaitForChild("ACS_Engine"):WaitForChild("GameRules"):WaitForChild("Config"))
    for _, key in ipairs(MovementKeys) do
        MovementOriginals[key] = ACSConfig[key]
    end
end)

local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(Connections, c)
    return c
end

local function isEnemy(player)
    if player == LocalPlayer then
        return false
    end
    if not State.TeamCheck then
        return true
    end
    local a = LocalPlayer:GetAttribute("Team")
    local b = player:GetAttribute("Team")
    if a ~= nil and b ~= nil then
        return a ~= b
    end
    if LocalPlayer.Team ~= nil and player.Team ~= nil then
        return LocalPlayer.Team ~= player.Team
    end
    return true
end

local function getAimPart(character, name)
    if not character then
        return nil
    end
    return character:FindFirstChild(name)
        or character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
end

local function canSee(part)
    if State.Wallbang then
        return true
    end
    local camera = Workspace.CurrentCamera
    if not camera then
        return false
    end
    local origin = camera.CFrame.Position
    local delta = part.Position - origin
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { LocalPlayer.Character, camera }
    params.IgnoreWater = true
    local result = Workspace:Raycast(origin, delta, params)
    return not result or result.Instance:IsDescendantOf(part.Parent)
end

local function getClosest(radius)
    local camera = Workspace.CurrentCamera
    if not camera then
        return nil
    end
    local mouse = UserInputService:GetMouseLocation()
    local bestPlayer, bestDistance = nil, radius or math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if isEnemy(player) then
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local part = getAimPart(character, State.AimPart)
            if humanoid and humanoid.Health > 0 and part then
                local pos, visible = camera:WorldToViewportPoint(part.Position)
                if visible then
                    local distance = (Vector2.new(pos.X, pos.Y) - mouse).Magnitude
                    if distance < bestDistance and canSee(part) then
                        bestDistance = distance
                        bestPlayer = player
                    end
                end
            end
        end
    end
    return bestPlayer
end

local function descendantsOfClass(root, className)
    if not root then
        return {}
    end
    local ok, result = pcall(function()
        if root.QueryDescendants then
            return root:QueryDescendants(className)
        end
    end)
    if ok and type(result) == "table" then
        return result
    end
    local out = {}
    for _, inst in ipairs(root:GetDescendants()) do
        if inst:IsA(className) then
            table.insert(out, inst)
        end
    end
    return out
end

local function remember(mode, tbl, key)
    local bucket = Originals[mode]
    local entry = bucket[tbl]
    if not entry then
        entry = {}
        bucket[tbl] = entry
    end
    if entry[key] == nil then
        entry[key] = { value = tbl[key] }
    end
end

local function zeroLike(value)
    local t = typeof(value)
    if t == "number" then
        return 0
    elseif t == "Vector2" then
        return Vector2.zero
    elseif t == "Vector3" then
        return Vector3.zero
    elseif t == "CFrame" then
        return CFrame.new()
    end
    if type(value) == "table" then
        local out = {}
        for k, v in pairs(value) do
            if type(v) == "number" then
                out[k] = 0
            elseif typeof(v) == "Vector2" then
                out[k] = Vector2.zero
            elseif typeof(v) == "Vector3" then
                out[k] = Vector3.zero
            else
                out[k] = v
            end
        end
        return out
    end
    return value
end

local function patchTable(tbl, seen)
    if type(tbl) ~= "table" then
        return
    end
    seen = seen or {}
    if seen[tbl] then
        return
    end
    seen[tbl] = true
    for key, value in pairs(tbl) do
        local name = tostring(key):lower()
        if State.NoRecoil and (name:find("recoil", 1, true) or name:find("punch", 1, true) or name:find("sway", 1, true)) then
            remember("recoil", tbl, key)
            tbl[key] = zeroLike(value)
        end
        if State.NoSpread and (name:find("spread", 1, true) or name:find("inaccuracy", 1, true) or name:find("bloom", 1, true)) then
            remember("spread", tbl, key)
            tbl[key] = zeroLike(value)
        end
        if State.NoDrop then
            if name:find("gravity", 1, true) or name:find("bulletdrop", 1, true) or name == "drop" or name:find("drag", 1, true) then
                remember("drop", tbl, key)
                tbl[key] = zeroLike(value)
            elseif (name:find("bulletspeed", 1, true) or name == "bspeed" or name:find("projectilespeed", 1, true) or name:find("shellspeed", 1, true) or name:find("muzzlevelocity", 1, true)) and type(value) == "number" then
                remember("drop", tbl, key)
                tbl[key] = math.max(value, 1000000)
            end
        end
        if type(value) == "table" then
            patchTable(value, seen)
        end
    end
end

local function restoreMode(mode)
    local bucket = Originals[mode]
    for tbl, values in pairs(bucket) do
        for key, saved in pairs(values) do
            pcall(function()
                tbl[key] = saved.value
            end)
        end
        bucket[tbl] = nil
    end
end

local function equippedTool()
    local character = LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Tool")
end

local function currentSettings()
    local tool = equippedTool()
    local module = tool and tool:FindFirstChild("ACS_Settings")
    if not module or not module:IsA("ModuleScript") then
        return nil, tool
    end
    local ok, settings = pcall(require, module)
    if ok and type(settings) == "table" then
        return settings, tool
    end
    return nil, tool
end

local function collectWeaponTables()
    local tables = {}
    local seenModules = {}
    local function addModule(module)
        if not module or seenModules[module] or not module:IsA("ModuleScript") then
            return
        end
        seenModules[module] = true
        local ok, result = pcall(require, module)
        if ok and type(result) == "table" then
            table.insert(tables, result)
        end
    end

    local tool = equippedTool()
    if tool then
        for _, module in ipairs(descendantsOfClass(tool, "ModuleScript")) do
            local n = module.Name:lower()
            if n:find("setting", 1, true) or n:find("config", 1, true) or n:find("weapon", 1, true) or n:find("gun", 1, true) then
                addModule(module)
            end
        end
    end

    local acs = ReplicatedStorage:FindFirstChild("ACS_Engine")
    if acs and tool then
        for _, module in ipairs(descendantsOfClass(acs, "ModuleScript")) do
            local n = module.Name:lower()
            if module.Name == tool.Name or n == "settings" or n == "acs_settings" then
                addModule(module)
            end
        end
    end

    local modules = ReplicatedStorage:FindFirstChild("Modules")
    if modules then
        local projectile = modules:FindFirstChild("Projectile")
        local shoot = projectile and projectile:FindFirstChild("ShootModule")
        addModule(shoot)
    end

    return tables
end

local function applyWeaponMods()
    for _, tbl in ipairs(collectWeaponTables()) do
        pcall(patchTable, tbl)
    end
end

local function getFrameworkEnvironment()
    local character = LocalPlayer.Character
    local client = character and character:FindFirstChild("ACS_Client")
    local framework = client and client:FindFirstChild("ACS_Framework")
    if not framework or not getsenv then
        return nil
    end
    local ok, env = pcall(getsenv, framework)
    if ok and type(env) == "table" then
        return env
    end
    return nil
end

local function getShootFunction()
    local env = getFrameworkEnvironment()
    local shoot = env and env.Shoot
    if type(shoot) == "function" then
        return shoot, env
    end
    return nil, env
end

local function getUpvalueValue(fn, index)
    if not fn or not debug or not debug.getupvalue then
        return nil
    end
    local ok, a, b = pcall(debug.getupvalue, fn, index)
    if not ok then
        return nil
    end
    if b ~= nil then
        return b
    end
    return a
end

local function setUpvalueValue(fn, index, value)
    if not fn or not debug or not debug.setupvalue then
        return false
    end
    return pcall(debug.setupvalue, fn, index, value)
end

local function applyInfiniteAmmo()
    if not State.InfiniteAmmo then
        return
    end
    local shoot = getShootFunction()
    local settings, tool = currentSettings()
    if not shoot or not settings or not tool then
        return
    end
    local current = getUpvalueValue(shoot, 6)
    if typeof(current) ~= "number" then
        return
    end
    if AmmoContext.Tool ~= tool or AmmoContext.Shoot ~= shoot then
        AmmoContext.Tool = tool
        AmmoContext.Shoot = shoot
        AmmoContext.Value = current
    end
    setUpvalueValue(shoot, 6, 999999)
end

local function restoreInfiniteAmmo()
    local shoot = getShootFunction()
    if shoot and AmmoContext.Shoot == shoot and typeof(AmmoContext.Value) == "number" then
        setUpvalueValue(shoot, 6, AmmoContext.Value)
    end
    AmmoContext.Tool = nil
    AmmoContext.Shoot = nil
    AmmoContext.Value = nil
end

local function applyRapidFire()
    if not State.RapidFire then
        return
    end
    local settings = currentSettings()
    if not settings or type(settings.ShootRate) ~= "number" then
        return
    end
    if Originals.fireRate[settings] == nil then
        Originals.fireRate[settings] = {
            ShootRate = { value = settings.ShootRate }
        }
    end
    settings.ShootRate = math.max(60, State.RapidFireRate)
end

local function resetShotDelay()
    local shoot = getShootFunction()
    if not shoot then
        return
    end
    local timing = getUpvalueValue(shoot, 4)
    if type(timing) == "table" then
        timing.NextShot = 0
        timing.NextMobileShot = 0
    end
end

local function applyMovement()
    if ACSConfig then
        ACSConfig.NormalWalkSpeed = State.WalkSpeed
        ACSConfig.RunWalkSpeed = State.WalkSpeed
        ACSConfig.AimWalkSpeed = State.WalkSpeed
        ACSConfig.CrouchWalkSpeed = State.WalkSpeed
        ACSConfig.ProneWalksSpeed = State.WalkSpeed
        ACSConfig.JumpPower = State.JumpPower
    end
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = State.WalkSpeed
        humanoid.JumpPower = State.JumpPower
    end
    local env = getFrameworkEnvironment()
    if env and type(env.setWalkSpeed) == "function" then
        pcall(env.setWalkSpeed)
        if humanoid then
            humanoid.WalkSpeed = State.WalkSpeed
            humanoid.JumpPower = State.JumpPower
        end
    end
end

local function restoreMovement()
    if ACSConfig then
        for key, value in pairs(MovementOriginals) do
            ACSConfig[key] = value
        end
    end
    local env = getFrameworkEnvironment()
    if env and type(env.setWalkSpeed) == "function" then
        pcall(env.setWalkSpeed)
    end
end

local function restoreHitboxes()
    for part, data in pairs(HitboxOriginals) do
        if part and part.Parent then
            pcall(function()
                part.Size = data.Size
                part.Transparency = data.Transparency
                part.CanCollide = data.CanCollide
                part.Massless = data.Massless
            end)
        end
        HitboxOriginals[part] = nil
    end
end

local function applyHitboxes()
    if not State.Hitbox then
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if isEnemy(player) then
            local part = getAimPart(player.Character, State.HitboxPart)
            if part and part:IsA("BasePart") then
                if not HitboxOriginals[part] then
                    HitboxOriginals[part] = {
                        Size = part.Size,
                        Transparency = part.Transparency,
                        CanCollide = part.CanCollide,
                        Massless = part.Massless,
                    }
                end
                pcall(function()
                    part.Size = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
                    part.Transparency = State.HitboxTransparency
                    part.CanCollide = false
                    part.Massless = true
                end)
            end
        end
    end
end

local ShootModule
local OriginalShoot
pcall(function()
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local projectile = modules and modules:FindFirstChild("Projectile")
    local shoot = projectile and projectile:FindFirstChild("ShootModule")
    if shoot then
        ShootModule = require(shoot)
    end
end)

if ShootModule and type(ShootModule.fire) == "function" and hookfunction then
    OriginalShoot = hookfunction(ShootModule.fire, function(self, origin, direction, data, ...)
        if not State.Unloaded and (State.SilentAim or State.Wallbang) and typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
            local target = getClosest(State.AimFov)
            local part = target and getAimPart(target.Character, State.AimPart)
            if part then
                local delta = part.Position - origin
                if State.Wallbang then
                    origin = part.Position - direction.Unit * 0.05
                    delta = part.Position - origin
                end
                if delta.Magnitude > 0 then
                    direction = delta.Unit
                end
            end
        end
        if not State.Unloaded and State.NoDrop and type(data) == "table" then
            data.shellSpeed = math.max(tonumber(data.shellSpeed) or 0, 1000000)
            data.shellMaxDist = math.max(tonumber(data.shellMaxDist) or 0, 1000000)
        end
        return OriginalShoot(self, origin, direction, data, ...)
    end)
end

connect(RunService.RenderStepped, function()
    if State.Unloaded then
        return
    end
    Camera = Workspace.CurrentCamera or Camera
    applyMovement()
    if State.InfiniteAmmo then
        applyInfiniteAmmo()
    end
end)

local hitboxClock = 0
local weaponClock = 0
connect(RunService.Heartbeat, function(dt)
    if State.Unloaded then
        return
    end
    hitboxClock += dt
    weaponClock += dt
    if hitboxClock >= 0.2 then
        hitboxClock = 0
        if State.Hitbox then
            applyHitboxes()
        end
    end
    if weaponClock >= 0.1 then
        weaponClock = 0
        if State.NoRecoil or State.NoSpread or State.NoDrop then
            applyWeaponMods()
        end
        if State.InfiniteAmmo then
            applyInfiniteAmmo()
        end
        if State.RapidFire then
            applyRapidFire()
        end
    end
end)

connect(LocalPlayer.CharacterAdded, function()
    task.wait(0.75)
    restoreHitboxes()
    AmmoContext.Tool = nil
    AmmoContext.Shoot = nil
    AmmoContext.Value = nil
    applyMovement()
    applyWeaponMods()
    applyRapidFire()
end)

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
local Window = Rayfield:CreateWindow({
    name = "Airsoft Battles",
    subtitle = "Rayfield Gen2",
    sidebarLayout = true,
    configuration = {
        autoSave = true,
        autoLoad = true,
        fileName = "AirsoftBattles",
    },
})

local Combat = Window:CreateTab({ name = "Combat" })
local Weapon = Window:CreateTab({ name = "Weapon" })
local PlayerTab = Window:CreateTab({ name = "Player" })
local Hitbox = Window:CreateTab({ name = "Hitbox" })

Combat:CreateToggle({
    name = "Silent Aim",
    flag = "SilentAim",
    value = State.SilentAim,
    callback = function(v) State.SilentAim = v end,
})
Combat:CreateToggle({
    name = "Wallbang",
    flag = "Wallbang",
    value = State.Wallbang,
    callback = function(v) State.Wallbang = v end,
})
Combat:CreateToggle({
    name = "Team Check",
    flag = "TeamCheck",
    value = State.TeamCheck,
    callback = function(v) State.TeamCheck = v end,
})
Combat:CreateDropdown({
    name = "Target Body Part",
    flag = "AimPart",
    options = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg" },
    value = State.AimPart,
    callback = function(v) State.AimPart = v end,
})
Combat:CreateSlider({
    name = "Target FOV",
    flag = "AimFov",
    range = { 25, 800 },
    increment = 5,
    value = State.AimFov,
    suffix = " px",
    callback = function(v) State.AimFov = v end,
})

Weapon:CreateToggle({
    name = "No Recoil",
    flag = "NoRecoil",
    value = State.NoRecoil,
    callback = function(v)
        State.NoRecoil = v
        if v then applyWeaponMods() else restoreMode("recoil") end
    end,
})
Weapon:CreateToggle({
    name = "Infinite Ammo",
    flag = "InfiniteAmmo",
    value = State.InfiniteAmmo,
    callback = function(v)
        State.InfiniteAmmo = v
        if v then
            applyInfiniteAmmo()
        else
            restoreInfiniteAmmo()
        end
    end,
})
Weapon:CreateToggle({
    name = "Rapid Fire",
    flag = "RapidFire",
    value = State.RapidFire,
    callback = function(v)
        State.RapidFire = v
        if v then
            applyRapidFire()
            resetShotDelay()
        else
            restoreMode("fireRate")
            resetShotDelay()
        end
    end,
})
Weapon:CreateSlider({
    name = "Fire Rate",
    description = "Rounds per minute",
    flag = "RapidFireRate",
    range = { 60, 6000 },
    increment = 10,
    value = State.RapidFireRate,
    suffix = " RPM",
    callback = function(v)
        State.RapidFireRate = v
        if State.RapidFire then
            applyRapidFire()
            resetShotDelay()
        end
    end,
})
Weapon:CreateToggle({
    name = "No Spread",
    flag = "NoSpread",
    value = State.NoSpread,
    callback = function(v)
        State.NoSpread = v
        if v then applyWeaponMods() else restoreMode("spread") end
    end,
})
Weapon:CreateToggle({
    name = "No Bullet Drop",
    description = "Raises projectile velocity and removes exposed drop values",
    flag = "NoDrop",
    value = State.NoDrop,
    callback = function(v)
        State.NoDrop = v
        if v then applyWeaponMods() else restoreMode("drop") end
    end,
})

PlayerTab:CreateSlider({
    name = "WalkSpeed",
    flag = "WalkSpeed",
    range = { 0, 150 },
    increment = 1,
    value = State.WalkSpeed,
    callback = function(v)
        State.WalkSpeed = v
        applyMovement()
    end,
})
PlayerTab:CreateSlider({
    name = "JumpPower",
    flag = "JumpPower",
    range = { 0, 200 },
    increment = 1,
    value = State.JumpPower,
    callback = function(v)
        State.JumpPower = v
        applyMovement()
    end,
})

Hitbox:CreateToggle({
    name = "Hitbox Expander",
    flag = "HitboxEnabled",
    value = State.Hitbox,
    callback = function(v)
        State.Hitbox = v
        if not v then restoreHitboxes() end
    end,
})
Hitbox:CreateDropdown({
    name = "Body Part",
    flag = "HitboxPart",
    options = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg" },
    value = State.HitboxPart,
    callback = function(v)
        restoreHitboxes()
        State.HitboxPart = v
    end,
})
Hitbox:CreateSlider({
    name = "Hitbox Size",
    flag = "HitboxSize",
    range = { 1, 30 },
    increment = 0.5,
    value = State.HitboxSize,
    callback = function(v) State.HitboxSize = v end,
})
Hitbox:CreateSlider({
    name = "Hitbox Transparency",
    flag = "HitboxTransparency",
    range = { 0, 1 },
    increment = 0.05,
    value = State.HitboxTransparency,
    callback = function(v) State.HitboxTransparency = v end,
})

PlayerTab:CreateButton({
    name = "Unload",
    callback = function()
        State.Unloaded = true
        State.SilentAim = false
        State.Wallbang = false
        State.NoRecoil = false
        State.InfiniteAmmo = false
        State.NoSpread = false
        State.NoDrop = false
        State.RapidFire = false
        State.Hitbox = false
        restoreInfiniteAmmo()
        restoreHitboxes()
        restoreMode("recoil")
        restoreMode("spread")
        restoreMode("drop")
        restoreMode("fireRate")
        restoreMovement()
        for _, c in ipairs(Connections) do
            pcall(function() c:Disconnect() end)
        end
        pcall(function() Window:Destroy() end)
    end,
})

applyMovement()
applyWeaponMods()
applyRapidFire()
