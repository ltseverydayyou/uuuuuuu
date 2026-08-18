local ServiceResolverURL = "https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/ServiceResolver.luau"
local ServiceResolverLoader = loadstring(game:HttpGet(ServiceResolverURL))
assert(type(ServiceResolverLoader) == "function", "Failed to compile ServiceResolver.luau")

local SR = ServiceResolverLoader()
assert(type(SR) == "table", "ServiceResolver.luau did not return a table")

local RefFn = type(cloneref) == "function" and cloneref or function(value)
    return value
end

local Players = SR.cs("Players", RefFn) or SR.gs("Players")
local RunService = SR.gs("RunService")
local ReplicatedStorage = SR.gs("ReplicatedStorage")
local VirtualInputManager = SR.gs("VirtualInputManager")
local Workspace = SR.gs("Workspace")
local CoreGui = SR.cv(SR.gs("CoreGui"))

assert(Players, "ServiceResolver failed to resolve Players")
assert(RunService, "ServiceResolver failed to resolve RunService")
assert(ReplicatedStorage, "ServiceResolver failed to resolve ReplicatedStorage")
assert(VirtualInputManager, "ServiceResolver failed to resolve VirtualInputManager")
assert(Workspace, "ServiceResolver failed to resolve Workspace")
assert(CoreGui, "ServiceResolver failed to resolve CoreGui")

local LocalPlayer = Players.LocalPlayer
local Env = getgenv()

if Env.TSB_AutoCombat and type(Env.TSB_AutoCombat.Stop) == "function" then
    pcall(Env.TSB_AutoCombat.Stop)
end

local Bot = {
    Version = "1.5.1",
    BaseVersion = "1.3.0",
    UsingServiceResolver = true,
    MovementDriver = "Humanoid:Move",
    Enabled = true,
    Action = "IDLE",
    Target = nil,
    Connections = {},
    Stats = {
        M1 = 0,
        Skills = 0,
        Blocks = 0,
        Dodges = 0,
        Counters = 0,
        Ultimates = 0
    },
    Config = {
        TargetRadius = 120,
        ThreatRadius = 20,
        M1Range = 8.2,
        ApproachRange = 9.5,
        RetreatRange = 4.8,
        PlayersOnly = true,
        AutoMovement = true,
        AutoJump = true,
        AutoM1 = true,
        AutoSkills = true,
        AutoDefense = true,
        AutoUltimate = true,
        AutoCamera = true,
        CounterPriority = true,
        BlockChance = 0.42,
        DodgeChance = 0.58,
        DecisionRate = 1 / 30,
        M1Interval = 0.10,
        SkillInterval = 0.30,
        DashInterval = 0.62,
        BlockDuration = 0.28,
        CameraLead = 0.075,
        FacingLead = 0.055,
        ObstacleDistance = 4.25,
        JumpCooldown = 0.45,
        DodgeMoveDuration = 0.18
    }
}

Env.TSB_AutoCombat = Bot

local Character
local Humanoid
local Root
local FacingAttachment
local FacingAlign
local TargetHighlight
local Hud
local StateLabel
local TargetLabel
local StatsLabel
local LastDecision = 0
local LastM1 = 0
local LastSkill = 0
local LastDash = 0
local LastUltimate = 0
local LastHealth = 100
local StrafeSide = 1
local NextStrafeSwap = 0
local Blocking = false
local TargetSnapshots = {}
local DesiredMoveDirection = Vector3.zero
local MovementOverrideDirection = nil
local MovementOverrideUntil = 0
local LastObstacleJump = 0
local RenderBindName = "TSB_AutoCombat_Camera_" .. tostring(LocalPlayer.UserId)
local MovementBindName = "TSB_AutoCombat_Movement_" .. tostring(LocalPlayer.UserId)

local CounterNames = {
    ["Prey's Peril"] = true,
    ["Split Second Counter"] = true,
    ["Death Counter"] = true,
    ["Death Blow"] = true,
    ["Spiraling Storm"] = true,
    ["Crossfire"] = true
}

local ReservedSkillNames = {
    ["Infinity"] = true
}

for name in pairs(CounterNames) do
    ReservedSkillNames[name] = true
end

local CharacterProfiles = {
    Bald = {Name = "The Strongest Hero", Approach = 8.5, Retreat = 4.8, SkillRange = 14},
    Batter = {Name = "Brutal Demon", Approach = 9.5, Retreat = 5.0, SkillRange = 18},
    Blade = {Name = "Blade Master", Approach = 10.5, Retreat = 5.0, SkillRange = 18},
    Cyborg = {Name = "Destructive Cyborg", Approach = 13.5, Retreat = 7.0, SkillRange = 48},
    Esper = {Name = "Wild Psychic", Approach = 14.0, Retreat = 7.5, SkillRange = 34},
    Hunter = {Name = "Hero Hunter", Approach = 8.5, Retreat = 4.8, SkillRange = 16},
    KJ = {Name = "KJ", Approach = 9.5, Retreat = 5.0, SkillRange = 20},
    Monster = {Name = "Monster Form", Approach = 10.0, Retreat = 5.0, SkillRange = 28},
    Ninja = {Name = "Deadly Ninja", Approach = 10.5, Retreat = 5.5, SkillRange = 30},
    Purple = {Name = "Martial Artist", Approach = 9.5, Retreat = 5.0, SkillRange = 20},
    Tech = {Name = "Tech Prodigy", Approach = 15.0, Retreat = 8.0, SkillRange = 55},
    Zombie = {Name = "Undying Hero", Approach = 11.0, Retreat = 5.5, SkillRange = 24},
    Sorcerer = {Name = "Sorcerer", Approach = 18.0, Retreat = 9.0, SkillRange = 70},
    Pirate = {Name = "The Strongest Pirate", Approach = 10.0, Retreat = 5.0, SkillRange = 24}
}

local MoveProfiles = {
    ["Normal Punch"] = {Max = 8.5, Priority = 3, ComboMin = 2},
    ["Consecutive Punches"] = {Max = 8.5, Priority = 1, ComboMin = 2},
    ["Shove"] = {Max = 9.5, Priority = 2, ComboMin = 2, BlockPunish = true},
    ["Uppercut"] = {Max = 8.5, Priority = 2, ComboMin = 2},
    ["Table Flip"] = {Max = 45, Priority = 1, Opener = true, BlockPunish = true},
    ["Serious Punch"] = {Max = 65, Priority = 1, Opener = true, BlockPunish = true},
    ["Omni Directional Punch"] = {Max = 13, Priority = 1, BlockPunish = true},

    ["Homerun"] = {Max = 11, Priority = 2, Opener = true, BlockPunish = true},
    ["Beatdown"] = {Max = 14, Priority = 1, Opener = true, BlockPunish = true},
    ["Grand Slam"] = {Max = 13, Priority = 2, BlockPunish = true},
    ["Foul Ball"] = {Max = 36, Priority = 3, Opener = true, BlockPunish = true},
    ["Savage Tornado"] = {Max = 14, Priority = 1, BlockPunish = true},
    ["Brutal Beatdown"] = {Max = 14, Priority = 1, BlockPunish = true},
    ["Strength Difference"] = {Max = 15, Priority = 2, BlockPunish = true},

    ["Quick Slice"] = {Max = 11, Priority = 2, ComboMin = 2},
    ["Atmos Cleave"] = {Max = 12, Priority = 2, ComboMin = 2},
    ["Pinpoint Cut"] = {Max = 13, Priority = 1, ComboMin = 2},
    ["Sunset"] = {Max = 16, Priority = 2},
    ["Solar Cleave"] = {Max = 18, Priority = 2},
    ["Sunrise"] = {Max = 16, Priority = 1},
    ["Atomic Slash"] = {Max = 20, Priority = 1, BlockPunish = true},

    ["Machine Gun Blows"] = {Max = 9, Priority = 2, ComboMin = 2},
    ["Ignition Burst"] = {Max = 20, Priority = 1, Opener = true},
    ["Blitz Shot"] = {Max = 42, Priority = 1, Opener = true},
    ["Jet Dive"] = {Max = 30, Priority = 2, Opener = true},
    ["Thunder Kick"] = {Max = 17, Priority = 2, Opener = true},
    ["Speedblitz Dropkick"] = {Max = 36, Priority = 1, Opener = true},
    ["Flamewave Cannon"] = {Max = 65, Priority = 1, Opener = true},
    ["Incinerate"] = {Max = 60, Priority = 1, Opener = true},

    ["Crushing Pull"] = {Max = 24, Priority = 1, Opener = true},
    ["Windstorm Fury"] = {Max = 13, Priority = 1, ComboMin = 1},
    ["Stone Coffin"] = {Max = 22, Priority = 2, PreferRagdoll = true},
    ["Expulsive Push"] = {Max = 22, Priority = 3},
    ["Cosmic Strike"] = {Max = 38, Priority = 1, Opener = true},
    ["Psychic Ricochet"] = {Max = 32, Priority = 2, Opener = true},
    ["Terrible Tornado"] = {Max = 30, Priority = 1},
    ["Sky Snatcher"] = {Max = 28, Priority = 1, Opener = true},

    ["Flowing Water"] = {Max = 9, Priority = 2, ComboMin = 2, BlockPunish = true},
    ["Lethal Whirlwind Stream"] = {Max = 9, Priority = 1, ComboMin = 2},
    ["Hunter's Grasp"] = {Max = 14, Priority = 1, PreferRagdoll = true, BlockPunish = true},
    ["Water Stream Cutting Fist"] = {Max = 9.5, Priority = 2},
    ["The Final Hunt"] = {Max = 10.5, Priority = 1, BlockPunish = true},
    ["Rock Splitting Fist"] = {Max = 10.5, Priority = 2},
    ["Crushed Rock"] = {Max = 16, Priority = 3},

    ["Ravage"] = {Max = 11, Priority = 2, ComboMin = 2},
    ["Swift Sweep"] = {Max = 11, Priority = 1, PreferRagdoll = true, BlockPunish = true},
    ["Collateral Ruin"] = {Max = 16, Priority = 2, BlockPunish = true},
    ["Stoic Bomb"] = {Max = 13, Priority = 2, PreferRagdoll = true},
    ["20-20-20 Dropkick"] = {Max = 42, Priority = 1, Opener = true},
    ["Five Seasons"] = {Max = 18, Priority = 1},
    ["Unlimited Flex Works"] = {Max = 20, Priority = 1, BlockPunish = true},

    ["Doom Dive"] = {Max = 22, Priority = 2, Opener = true},
    ["Crowd Buster"] = {Max = 12, Priority = 1, ComboMin = 2},
    ["Hammer Heel"] = {Max = 13, Priority = 1, PreferRagdoll = true},
    ["Binding Cloth"] = {Max = 20, Priority = 1, ComboMin = 1},
    ["Hunter's Mark"] = {Max = 22, Priority = 1, Opener = true},
    ["Great Fajin"] = {Max = 34, Priority = 1, Opener = true},
    ["God Slayer"] = {Max = 17, Priority = 1, BlockPunish = true},
    ["Sky Ripping Fist"] = {Max = 34, Priority = 2, Opener = true},

    ["Flash Strike"] = {Max = 22, Priority = 2, Opener = true},
    ["Whirlwind Kick"] = {Max = 10, Priority = 1, ComboMin = 2},
    ["Scatter"] = {Max = 14, Priority = 1, ComboMin = 2},
    ["Explosive Shuriken"] = {Max = 38, Priority = 2, Opener = true},
    ["Twinblade Rush"] = {Max = 28, Priority = 1, Opener = true},
    ["Straight On"] = {Max = 38, Priority = 1, Opener = true},
    ["Carnage"] = {Max = 16, Priority = 2},
    ["Fourfold Flashstrike"] = {Max = 24, Priority = 1, Opener = true, BlockPunish = true},

    ["Bullet Barrage"] = {Max = 9.5, Priority = 1, ComboMin = 2},
    ["Vanishing Kick"] = {Max = 20, Priority = 1, Opener = true},
    ["Whirlwind Drop"] = {Max = 11, Priority = 2, PreferRagdoll = true},
    ["Head First"] = {Max = 13, Priority = 2, PreferRagdoll = true},
    ["Grand Fissure"] = {Max = 17, Priority = 1},
    ["Twin Fangs"] = {Max = 13, Priority = 1, ComboMin = 1},
    ["Earth Splitting Strike"] = {Max = 20, Priority = 1, BlockPunish = true},
    ["Last Breath"] = {Max = 14, Priority = 1},

    ["Weboom"] = {Max = 26, Priority = 1, Opener = true},
    ["Plasma Cannon"] = {Max = 55, Priority = 2, Opener = true},
    ["Trinity Tear"] = {Max = 13, Priority = 1, ComboMin = 2},
    ["Twin Burst"] = {Max = 13, Priority = 1, ComboMin = 2},
    ["Photon Edge"] = {Max = 18, Priority = 1, BlockPunish = true},
    ["Photon Dive"] = {Max = 34, Priority = 1, Opener = true, BlockPunish = true},
    ["Conquest"] = {Max = 38, Priority = 1, Opener = true, BlockPunish = true},
    ["Missiles"] = {Max = 70, Priority = 1, Opener = true},

    ["Grave Maker"] = {Max = 11, Priority = 1, ComboMin = 2},
    ["Blast Breaker"] = {Max = 22, Priority = 2, Opener = true},
    ["Point Blank"] = {Max = 14, Priority = 1, Opener = true},

    ["Repulse"] = {Max = 70, Priority = 1, Opener = true, BlockPunish = true},
    ["Erase"] = {Max = 80, Priority = 1, Opener = true, BlockPunish = true},
    ["Attract"] = {Max = 42, Priority = 1, Opener = true, BlockPunish = true},

    ["Sweep"] = {Max = 11, Priority = 1, ComboMin = 2},
    ["Shatter"] = {Max = 14, Priority = 2},
    ["Blast Clutch"] = {Max = 22, Priority = 1, Opener = true},
    ["Tremmor"] = {Max = 22, Priority = 2},
    ["Spine Splitter"] = {Max = 11, Priority = 1, ComboMin = 2}
}

local Skillsets = {}
pcall(function()
    local info = require(ReplicatedStorage:WaitForChild("Info"))
    if type(info) == "table" and type(info.Skillsets) == "table" then
        Skillsets = info.Skillsets
    end
end)

local function getCharacterKey()
    return Character and Character:GetAttribute("Character") or nil
end

local function getCharacterProfile()
    local key = getCharacterKey()
    return CharacterProfiles[key] or {
        Name = tostring(key or "Unknown"),
        Approach = Bot.Config.ApproachRange,
        Retreat = Bot.Config.RetreatRange,
        SkillRange = 14
    }
end

local function getMoveProfile(name)
    local direct = MoveProfiles[name]
    if direct then
        return direct
    end

    local profile = getCharacterProfile()
    return {
        Max = profile.SkillRange or 14,
        Priority = 5,
        ComboMin = 1
    }
end

Bot.CharacterProfiles = CharacterProfiles
Bot.MoveProfiles = MoveProfiles
Bot.CounterNames = CounterNames
Bot.Skillsets = Skillsets

local function disconnectAll()
    for _, connection in ipairs(Bot.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(Bot.Connections)
end

local function releaseKey(key)
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end)
end

local function cleanupFacing()
    if FacingAlign then
        pcall(function()
            FacingAlign:Destroy()
        end)
        FacingAlign = nil
    end
    if FacingAttachment then
        pcall(function()
            FacingAttachment:Destroy()
        end)
        FacingAttachment = nil
    end
end

local function ensureCharacter()
    Character = LocalPlayer.Character
    if not Character or not Character.Parent then
        Humanoid = nil
        Root = nil
        cleanupFacing()
        return false
    end

    Humanoid = Character:FindFirstChildOfClass("Humanoid")
    Root = Character:FindFirstChild("HumanoidRootPart")

    if not Humanoid or not Root or Humanoid.Health <= 0 then
        cleanupFacing()
        return false
    end

    return true
end

local function ensureFacing()
    if not Root then
        return
    end

    if FacingAttachment and FacingAttachment.Parent ~= Root then
        cleanupFacing()
    end

    if not FacingAttachment then
        FacingAttachment = Instance.new("Attachment")
        FacingAttachment.Name = "TSBAutoCombatFacingAttachment"
        FacingAttachment.Parent = Root
    end

    if not FacingAlign then
        FacingAlign = Instance.new("AlignOrientation")
        FacingAlign.Name = "TSBAutoCombatFacing"
        FacingAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
        FacingAlign.Attachment0 = FacingAttachment
        FacingAlign.RigidityEnabled = true
        FacingAlign.Responsiveness = 200
        FacingAlign.MaxTorque = math.huge
        FacingAlign.Parent = Root
    end

    Humanoid.AutoRotate = false
end

local function makeHud()
    pcall(function()
        local old = CoreGui:FindFirstChild("TSBAutoCombatHUD")
        if old then
            old:Destroy()
        end
    end)

    local parent = CoreGui
    local ok = pcall(function()
        local test = Instance.new("Folder")
        test.Name = "_TSBHudTest"
        test.Parent = CoreGui
        test:Destroy()
    end)

    if not ok then
        parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    Hud = Instance.new("ScreenGui")
    Hud.Name = "TSBAutoCombatHUD"
    Hud.ResetOnSpawn = false
    Hud.IgnoreGuiInset = true
    Hud.Parent = parent

    local frame = Instance.new("Frame")
    frame.Name = "Main"
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position = UDim2.fromScale(0.5, 0.03)
    frame.Size = UDim2.fromOffset(330, 98)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    frame.BackgroundTransparency = 0.18
    frame.BorderSizePixel = 0
    frame.Parent = Hud

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(8, 5)
    title.Size = UDim2.new(1, -16, 0, 22)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "TSB AUTO COMBAT " .. Bot.Version
    title.Parent = frame

    StateLabel = Instance.new("TextLabel")
    StateLabel.BackgroundTransparency = 1
    StateLabel.Position = UDim2.fromOffset(8, 29)
    StateLabel.Size = UDim2.new(1, -16, 0, 19)
    StateLabel.Font = Enum.Font.Gotham
    StateLabel.TextSize = 13
    StateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StateLabel.TextXAlignment = Enum.TextXAlignment.Left
    StateLabel.Text = "STATE: IDLE"
    StateLabel.Parent = frame

    TargetLabel = Instance.new("TextLabel")
    TargetLabel.BackgroundTransparency = 1
    TargetLabel.Position = UDim2.fromOffset(8, 49)
    TargetLabel.Size = UDim2.new(1, -16, 0, 19)
    TargetLabel.Font = Enum.Font.Gotham
    TargetLabel.TextSize = 13
    TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
    TargetLabel.Text = "TARGET: NONE"
    TargetLabel.Parent = frame

    StatsLabel = Instance.new("TextLabel")
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Position = UDim2.fromOffset(8, 69)
    StatsLabel.Size = UDim2.new(1, -16, 0, 19)
    StatsLabel.Font = Enum.Font.Gotham
    StatsLabel.TextSize = 12
    StatsLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatsLabel.Text = "M1 0 | SKILL 0 | BLOCK 0 | DODGE 0 | COUNTER 0 | ULT 0"
    StatsLabel.Parent = frame

    TargetHighlight = Instance.new("Highlight")
    TargetHighlight.Name = "TSBAutoCombatTarget"
    TargetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    TargetHighlight.FillTransparency = 0.75
    TargetHighlight.OutlineTransparency = 0
    TargetHighlight.Enabled = false
    TargetHighlight.Parent = Hud
end

local function updateHud()
    if StateLabel then
        StateLabel.Text = "STATE: " .. tostring(Bot.Action)
    end

    if TargetLabel then
        if Bot.Target and Bot.Target.Parent and Root then
            local targetRoot = Bot.Target:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                TargetLabel.Text = string.format("TARGET: %s | %.1f STUDS", Bot.Target.Name, (targetRoot.Position - Root.Position).Magnitude)
            else
                TargetLabel.Text = "TARGET: NONE"
            end
        else
            TargetLabel.Text = "TARGET: NONE"
        end
    end

    if StatsLabel then
        local s = Bot.Stats
        StatsLabel.Text = string.format(
            "M1 %d | SKILL %d | BLOCK %d | DODGE %d | COUNTER %d | ULT %d",
            s.M1,
            s.Skills,
            s.Blocks,
            s.Dodges,
            s.Counters,
            s.Ultimates
        )
    end

    if TargetHighlight then
        if Bot.Target and Bot.Target.Parent then
            TargetHighlight.Adornee = Bot.Target
            TargetHighlight.Enabled = true
        else
            TargetHighlight.Adornee = nil
            TargetHighlight.Enabled = false
        end
    end
end

local function horizontal(vector)
    return Vector3.new(vector.X, 0, vector.Z)
end

local function getTargetParts(model)
    if not model or not model.Parent then
        return nil
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root or humanoid.Health <= 0 then
        return nil
    end

    if model:FindFirstChildOfClass("ForceField") then
        return nil
    end

    return humanoid, root
end

local function isValidTarget(model, maxDistance)
    if not Root or not model or model == Character then
        return false
    end

    local humanoid, root = getTargetParts(model)
    if not humanoid or not root then
        return false
    end

    if Bot.Config.PlayersOnly and not Players:GetPlayerFromCharacter(model) then
        return false
    end

    return (root.Position - Root.Position).Magnitude <= maxDistance
end

local function acquireTarget()
    if Bot.Target and isValidTarget(Bot.Target, Bot.Config.TargetRadius + 12) then
        return Bot.Target
    end

    local live = workspace:FindFirstChild("Live")
    if not live then
        Bot.Target = nil
        return nil
    end

    local nearest
    local nearestDistance = Bot.Config.TargetRadius

    for _, model in ipairs(live:GetChildren()) do
        if model:IsA("Model") and model ~= Character then
            if not Bot.Config.PlayersOnly or Players:GetPlayerFromCharacter(model) then
                local humanoid, root = getTargetParts(model)
                if humanoid and root then
                    local distance = (root.Position - Root.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearest = model
                    end
                end
            end
        end
    end

    Bot.Target = nearest
    return nearest
end

local function setFacing(targetRoot)
    if not Bot.Config.AutoMovement or not Root or not targetRoot then
        return
    end

    ensureFacing()

    local predicted = targetRoot.Position + horizontal(targetRoot.AssemblyLinearVelocity) * Bot.Config.FacingLead
    local direction = horizontal(predicted - Root.Position)

    if direction.Magnitude > 0.001 and FacingAlign then
        FacingAlign.CFrame = CFrame.lookAt(Vector3.zero, direction.Unit)
    end
end

local function updateCamera()
    if not Bot.Enabled or not Bot.Config.AutoCamera then
        return
    end

    if not ensureCharacter() then
        return
    end

    local target = acquireTarget()
    if not target then
        return
    end

    local _, targetRoot = getTargetParts(target)
    local camera = Workspace.CurrentCamera

    if not targetRoot or not camera then
        return
    end

    local predicted = targetRoot.Position + targetRoot.AssemblyLinearVelocity * Bot.Config.CameraLead
    local focus = predicted + Vector3.new(0, 1.35, 0)
    local position = camera.CFrame.Position
    local delta = focus - position

    if delta.Magnitude > 0.001 then
        camera.CFrame = CFrame.lookAt(position, focus, Vector3.yAxis)
    end
end

local function setDesiredMovement(direction)
    direction = horizontal(direction)

    if direction.Magnitude > 1 then
        direction = direction.Unit
    end

    DesiredMoveDirection = direction
end

local function requestJump()
    if not Bot.Config.AutoJump or not Humanoid or Humanoid.Health <= 0 then
        return false
    end

    local now = os.clock()
    if now - LastObstacleJump < Bot.Config.JumpCooldown then
        return false
    end

    local state = Humanoid:GetState()
    if Humanoid.FloorMaterial == Enum.Material.Air
        or state == Enum.HumanoidStateType.Jumping
        or state == Enum.HumanoidStateType.Freefall
        or state == Enum.HumanoidStateType.FallingDown
        or state == Enum.HumanoidStateType.Ragdoll then
        return false
    end

    LastObstacleJump = now
    Humanoid.Jump = true

    pcall(function()
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end)

    return true
end

local function tryAutoJump(direction)
    if not Bot.Config.AutoJump or not Character or not Humanoid or not Root then
        return
    end

    local flat = horizontal(direction)
    if flat.Magnitude < 0.15 then
        return
    end

    local filters = {Character}
    if Bot.Target then
        table.insert(filters, Bot.Target)
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = filters
    params.IgnoreWater = true

    local directionUnit = flat.Unit
    local castDistance = Bot.Config.ObstacleDistance
    local lowerOrigin = Root.Position - Vector3.new(0, 0.85, 0)
    local lowerHit = Workspace:Raycast(lowerOrigin, directionUnit * castDistance, params)

    if not lowerHit then
        return
    end

    local hit = lowerHit.Instance
    if hit and hit:IsA("BasePart") and not hit.CanCollide then
        return
    end

    requestJump()
end

local function applyMovement()
    if not Bot.Enabled or not Bot.Config.AutoMovement then
        if Humanoid then
            Humanoid:Move(Vector3.zero, false)
        end
        return
    end

    if not ensureCharacter() then
        return
    end

    local now = os.clock()
    local direction = DesiredMoveDirection

    if MovementOverrideDirection and now < MovementOverrideUntil then
        direction = MovementOverrideDirection
    elseif MovementOverrideDirection then
        MovementOverrideDirection = nil
        MovementOverrideUntil = 0
    end

    direction = horizontal(direction)

    if direction.Magnitude > 1 then
        direction = direction.Unit
    end

    Humanoid:Move(direction, false)
    tryAutoJump(direction)
end

local function moveCombat(targetRoot, distance)
    if not Bot.Config.AutoMovement or not Humanoid or not Root or not targetRoot then
        return
    end

    setFacing(targetRoot)

    local delta = horizontal(targetRoot.Position - Root.Position)
    if delta.Magnitude <= 0.001 then
        setDesiredMovement(Vector3.zero)
        return
    end

    local profile = getCharacterProfile()
    local approachRange = profile.Approach or Bot.Config.ApproachRange
    local retreatRange = profile.Retreat or Bot.Config.RetreatRange
    local toward = delta.Unit

    if distance > approachRange then
        Bot.Action = "APPROACH " .. Bot.Target.Name
        setDesiredMovement(toward)
        return
    end

    if distance < retreatRange then
        Bot.Action = "RETREAT " .. Bot.Target.Name
        setDesiredMovement(-toward)
        return
    end

    if os.clock() >= NextStrafeSwap then
        StrafeSide = -StrafeSide
        NextStrafeSwap = os.clock() + 0.72 + math.random() * 0.22
    end

    local right = Vector3.new(-toward.Z, 0, toward.X)
    local pressure = toward * 0.22
    local strafe = right * StrafeSide
    local move = strafe + pressure

    if move.Magnitude > 0.001 then
        move = move.Unit
    end

    Bot.Action = "PRESSURE/STRAFE " .. Bot.Target.Name
    setDesiredMovement(move)
end

local function tapKey(key, holdTime)
    holdTime = holdTime or 0.035

    task.spawn(function()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, key, false, game)
        end)
        task.wait(holdTime)
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, key, false, game)
        end)
    end)
end

local function mouse1()
    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
    local x = math.floor(viewport.X * 0.5)
    local y = math.floor(viewport.Y * 0.5)

    task.spawn(function()
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
        end)
        task.wait(0.018)
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
    end)
end

local function canAct()
    if not Character or not Humanoid or Humanoid.Health <= 0 then
        return false
    end

    if Character:GetAttribute("Ragdoll") then
        Bot.Action = "STUNNED / RAGDOLLED"
        return false
    end

    if Character:GetAttribute("Freeze") or Character:GetAttribute("Slowed") or Character:GetAttribute("GlobalStun") then
        Bot.Action = "STUNNED / RAGDOLLED"
        return false
    end

    return true
end

local function hotbar()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local hotbarGui = playerGui
        and playerGui:FindFirstChild("Hotbar")
        and playerGui.Hotbar:FindFirstChild("Backpack")
        and playerGui.Hotbar.Backpack:FindFirstChild("Hotbar")

    if not hotbarGui then
        return {}
    end

    local result = {}

    for i = 1, 13 do
        local slot = hotbarGui:FindFirstChild(tostring(i))
        local base = slot and slot:FindFirstChild("Base")
        local toolName = base and base:FindFirstChild("ToolName")
        local cooldown = base and base:FindFirstChild("Cooldown")

        if base and toolName and toolName:IsA("TextLabel") then
            table.insert(result, {
                Index = i,
                Name = toolName.Text,
                Ready = cooldown == nil
            })
        end
    end

    return result
end

local function findSkillByName(name)
    for _, slot in ipairs(hotbar()) do
        if slot.Name == name and slot.Ready then
            return slot
        end
    end
end

local function keyForSlot(index)
    local map = {
        [1] = Enum.KeyCode.One,
        [2] = Enum.KeyCode.Two,
        [3] = Enum.KeyCode.Three,
        [4] = Enum.KeyCode.Four,
        [5] = Enum.KeyCode.Five,
        [6] = Enum.KeyCode.Six,
        [7] = Enum.KeyCode.Seven,
        [8] = Enum.KeyCode.Eight,
        [9] = Enum.KeyCode.Nine,
        [10] = Enum.KeyCode.Zero
    }

    return map[index]
end

local function useSlot(slot, action)
    if not slot or not slot.Ready then
        return false
    end

    local key = keyForSlot(slot.Index)
    if not key then
        return false
    end

    tapKey(key)
    Bot.Action = action or ("SKILL " .. tostring(slot.Index))
    Bot.Stats.Skills += 1
    LastSkill = os.clock()
    return true
end

local function getCounterSkill()
    for _, slot in ipairs(hotbar()) do
        if slot.Ready and CounterNames[slot.Name] then
            return slot
        end
    end
end

local function getAnimationThreat(targetHumanoid)
    local threat = 0

    pcall(function()
        local animator = targetHumanoid:FindFirstChildOfClass("Animator")
        if not animator then
            return
        end

        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            if track.IsPlaying then
                local priority = track.Priority
                if priority == Enum.AnimationPriority.Action4 then
                    threat = math.max(threat, 4)
                elseif priority == Enum.AnimationPriority.Action3 then
                    threat = math.max(threat, 3)
                elseif priority == Enum.AnimationPriority.Action2 then
                    threat = math.max(threat, 2)
                elseif priority == Enum.AnimationPriority.Action then
                    threat = math.max(threat, 1)
                end
            end
        end
    end)

    return threat
end

local function detectThreat(target, targetHumanoid, targetRoot, distance)
    if distance > Bot.Config.ThreatRadius then
        TargetSnapshots[target] = nil
        return 0
    end

    local snapshot = TargetSnapshots[target]
    if not snapshot then
        snapshot = {
            LastM1Fire = target:GetAttribute("LastM1Fire"),
            LastSkill = target:GetAttribute("LastSkill"),
            JustForwardDashed = target:GetAttribute("JustForwardDashed")
        }
        TargetSnapshots[target] = snapshot
    end

    local threat = getAnimationThreat(targetHumanoid)
    local currentM1 = target:GetAttribute("LastM1Fire")
    local currentSkill = target:GetAttribute("LastSkill")
    local currentDash = target:GetAttribute("JustForwardDashed")

    if currentM1 ~= nil and currentM1 ~= snapshot.LastM1Fire then
        threat = math.max(threat, distance <= 9.5 and 3 or 2)
        snapshot.LastM1Fire = currentM1
    end

    if currentSkill ~= nil and currentSkill ~= snapshot.LastSkill then
        threat = math.max(threat, 4)
        snapshot.LastSkill = currentSkill
    end

    if currentDash ~= nil and currentDash ~= snapshot.JustForwardDashed then
        threat = math.max(threat, 3)
        snapshot.JustForwardDashed = currentDash
    end

    local towardUs = horizontal(Root.Position - targetRoot.Position)
    local enemyLook = horizontal(targetRoot.CFrame.LookVector)

    if towardUs.Magnitude > 0.001 and enemyLook.Magnitude > 0.001 then
        local facingDot = enemyLook.Unit:Dot(towardUs.Unit)
        if facingDot < 0.25 then
            threat = math.max(0, threat - 1)
        elseif facingDot > 0.72 and distance <= 10 then
            threat = math.max(threat, 1)
        end
    end

    local health = Humanoid.Health
    if health < LastHealth - 0.1 then
        threat = math.max(threat, 4)
    end
    LastHealth = health

    return threat
end

local function doBlock(level)
    if Blocking then
        return
    end

    Blocking = true
    Bot.Action = "BLOCK / PARRY"
    Bot.Stats.Blocks += 1

    local duration = Bot.Config.BlockDuration
    if level >= 4 then
        duration = math.max(duration, 0.36)
    elseif level <= 2 then
        duration = math.min(duration, 0.22)
    end

    task.spawn(function()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        end)
        task.wait(duration)
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
        Blocking = false
    end)
end

local function doDodge(targetRoot, level)
    if os.clock() - LastDash < Bot.Config.DashInterval then
        return false
    end

    if not Humanoid or not Root or not targetRoot then
        return false
    end

    local relative = horizontal(targetRoot.Position - Root.Position)
    if relative.Magnitude <= 0.001 then
        return false
    end

    LastDash = os.clock()

    local toward = relative.Unit
    local right = Vector3.new(-toward.Z, 0, toward.X)
    local choice
    local dodgeDirection

    local roll = math.random()
    if level >= 4 and roll < 0.35 then
        choice = "BACK"
        dodgeDirection = -toward
    elseif StrafeSide > 0 then
        choice = "RIGHT"
        dodgeDirection = right
    else
        choice = "LEFT"
        dodgeDirection = -right
    end

    dodgeDirection = horizontal(dodgeDirection)
    if dodgeDirection.Magnitude <= 0.001 then
        return false
    end

    dodgeDirection = dodgeDirection.Unit
    MovementOverrideDirection = dodgeDirection
    MovementOverrideUntil = os.clock() + Bot.Config.DodgeMoveDuration

    Bot.Action = "ESCAPE: " .. choice
    Bot.Stats.Dodges += 1

    Humanoid:Move(dodgeDirection, false)

    task.spawn(function()
        if level >= 4 and math.random() < 0.28 then
            requestJump()
        end

        task.wait(0.025)
        tapKey(Enum.KeyCode.Q, 0.03)
    end)

    return true
end

local function defend(targetRoot, threat)
    if not Bot.Config.AutoDefense or threat <= 0 then
        return false
    end

    if Bot.Config.CounterPriority and threat >= 3 then
        local counter = getCounterSkill()
        if counter and os.clock() - LastSkill >= Bot.Config.SkillInterval then
            if useSlot(counter, "COUNTER: " .. counter.Name) then
                Bot.Stats.Counters += 1
                return true
            end
        end
    end

    local dodgeWeight = Bot.Config.DodgeChance
    local blockWeight = Bot.Config.BlockChance
    local total = math.max(0.001, dodgeWeight + blockWeight)

    if math.random() < dodgeWeight / total then
        if doDodge(targetRoot, threat) then
            return true
        end
        doBlock(threat)
        return true
    end

    doBlock(threat)
    return true
end

local function useUltimateIfReady(distance)
    if not Bot.Config.AutoUltimate or distance > 18 then
        return false
    end

    if os.clock() - LastUltimate < 3 then
        return false
    end

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local bar = playerGui and playerGui:FindFirstChild("Bar")
    local magic = bar and bar:FindFirstChild("MagicHealth")
    local ult = magic and magic:FindFirstChild("Ult")

    if ult and ult:IsA("GuiObject") and ult.Visible then
        tapKey(Enum.KeyCode.G, 0.04)
        LastUltimate = os.clock()
        Bot.Stats.Ultimates += 1
        Bot.Action = "ULTIMATE"
        return true
    end

    return false
end

local function chooseOffensiveSkill(distance, target)
    if not Bot.Config.AutoSkills or os.clock() - LastSkill < Bot.Config.SkillInterval then
        return false
    end

    local slots = hotbar()
    if #slots == 0 then
        return false
    end

    local targetRagdolled = target:GetAttribute("Ragdoll") == true
    local targetBlocking = target:GetAttribute("Blocking") == true
    local combo = tonumber(Character:GetAttribute("Combo")) or 0
    local candidates = {}

    for _, slot in ipairs(slots) do
        if slot.Ready and not ReservedSkillNames[slot.Name] then
            local move = getMoveProfile(slot.Name)
            local minRange = move.Min or 0
            local maxRange = move.Max or getCharacterProfile().SkillRange or 14
            local comboMin = move.ComboMin or 0

            if distance >= minRange and distance <= maxRange then
                local allowed = true

                if combo < comboMin and not move.Opener and not targetRagdolled then
                    allowed = false
                end

                if move.RagdollOnly and not targetRagdolled then
                    allowed = false
                end

                if targetBlocking and not move.BlockPunish and distance <= Bot.Config.M1Range then
                    allowed = false
                end

                if allowed then
                    local score = (move.Priority or 5) * 10 + slot.Index

                    if move.PreferRagdoll and targetRagdolled then
                        score -= 24
                    end

                    if move.Opener and distance > Bot.Config.M1Range then
                        score -= 18
                    end

                    if move.BlockPunish and targetBlocking then
                        score -= 22
                    end

                    if combo >= 2 and not move.Opener then
                        score -= math.min(combo, 3) * 3
                    end

                    if targetRagdolled and not move.PreferRagdoll then
                        score += 3
                    end

                    table.insert(candidates, {
                        Slot = slot,
                        Score = score
                    })
                end
            end
        end
    end

    table.sort(candidates, function(a, b)
        if a.Score == b.Score then
            return a.Slot.Index < b.Slot.Index
        end
        return a.Score < b.Score
    end)

    if candidates[1] then
        local slot = candidates[1].Slot
        return useSlot(slot, "SKILL " .. slot.Index .. ": " .. slot.Name)
    end

    return false
end

local function doM1(distance, target)
    if not Bot.Config.AutoM1 or distance > Bot.Config.M1Range then
        return false
    end

    if os.clock() - LastM1 < Bot.Config.M1Interval then
        return false
    end

    if Character:GetAttribute("M1Ready") == false then
        return false
    end

    if target:GetAttribute("Blocking") then
        return false
    end

    LastM1 = os.clock()
    mouse1()
    Bot.Stats.M1 += 1
    Bot.Action = "M1"
    return true
end

local function combatStep()
    if not Bot.Enabled then
        return
    end

    if os.clock() - LastDecision < Bot.Config.DecisionRate then
        return
    end
    LastDecision = os.clock()

    if not ensureCharacter() then
        Bot.Action = "NO CHARACTER"
        Bot.Target = nil
        setDesiredMovement(Vector3.zero)
        updateHud()
        return
    end

    local target = acquireTarget()
    if not target then
        Bot.Action = "IDLE"
        Bot.Target = nil
        setDesiredMovement(Vector3.zero)
        updateHud()
        return
    end

    local targetHumanoid, targetRoot = getTargetParts(target)
    if not targetHumanoid or not targetRoot then
        Bot.Target = nil
        Bot.Action = "IDLE"
        setDesiredMovement(Vector3.zero)
        updateHud()
        return
    end

    local distance = (targetRoot.Position - Root.Position).Magnitude
    setFacing(targetRoot)
    moveCombat(targetRoot, distance)

    if not canAct() then
        updateHud()
        return
    end

    local threat = detectThreat(target, targetHumanoid, targetRoot, distance)
    if threat > 0 and defend(targetRoot, threat) then
        updateHud()
        return
    end

    if useUltimateIfReady(distance) then
        updateHud()
        return
    end

    local combo = tonumber(Character:GetAttribute("Combo")) or 0
    local targetRagdolled = target:GetAttribute("Ragdoll") == true
    local targetBlocking = target:GetAttribute("Blocking") == true

    if distance <= Bot.Config.M1Range and combo < 3 and not targetRagdolled and not targetBlocking then
        if doM1(distance, target) then
            updateHud()
            return
        end
    end

    if chooseOffensiveSkill(distance, target) then
        updateHud()
        return
    end

    doM1(distance, target)
    updateHud()
end

function Bot.SetEnabled(state)
    Bot.Enabled = state ~= false

    if not Bot.Enabled then
        Bot.Action = "DISABLED"
        DesiredMoveDirection = Vector3.zero
        MovementOverrideDirection = nil
        MovementOverrideUntil = 0
        if Humanoid then
            Humanoid:Move(Vector3.zero, false)
            Humanoid.AutoRotate = true
        end
        releaseKey(Enum.KeyCode.F)
        releaseKey(Enum.KeyCode.Q)
        cleanupFacing()
    end

    updateHud()
end

function Bot.Stop()
    Bot.Enabled = false
    DesiredMoveDirection = Vector3.zero
    MovementOverrideDirection = nil
    MovementOverrideUntil = 0

    pcall(function()
        RunService:UnbindFromRenderStep(RenderBindName)
    end)

    pcall(function()
        RunService:UnbindFromRenderStep(MovementBindName)
    end)

    disconnectAll()

    if Humanoid then
        pcall(function()
            Humanoid:Move(Vector3.zero, false)
            Humanoid.AutoRotate = true
        end)
    end

    releaseKey(Enum.KeyCode.F)
    releaseKey(Enum.KeyCode.Q)

    cleanupFacing()

    if TargetHighlight then
        pcall(function()
            TargetHighlight:Destroy()
        end)
    end

    if Hud then
        pcall(function()
            Hud:Destroy()
        end)
    end

    Bot.Action = "STOPPED"
end

makeHud()
ensureCharacter()

table.insert(Bot.Connections, RunService.Heartbeat:Connect(combatStep))

pcall(function()
    RunService:UnbindFromRenderStep(MovementBindName)
end)

RunService:BindToRenderStep(MovementBindName, Enum.RenderPriority.Last.Value - 1, applyMovement)

pcall(function()
    RunService:UnbindFromRenderStep(RenderBindName)
end)

RunService:BindToRenderStep(RenderBindName, Enum.RenderPriority.Camera.Value + 1, updateCamera)

table.insert(Bot.Connections, LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.15)
    cleanupFacing()
    ensureCharacter()
    LastHealth = Humanoid and Humanoid.Health or 100
end))

print("[TSB AutoCombat] v" .. Bot.Version .. " enabled | base " .. Bot.BaseVersion .. " | ServiceResolver + late Humanoid:Move + auto-jump + universal profiles + camera lock")
