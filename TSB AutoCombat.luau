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
    Version = "1.7.0",
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
        TargetScanRate = 0.14,
        TargetSwitchAdvantage = 12,
        TargetLockTime = 0.60,
        ThreatRadius = 24,
        GlobalThreatRadius = 105,
        UltimateDangerRadius = 135,
        ThreatMemory = 0.34,
        RangedThreatMemory = 0.72,
        UltimateGrace = 1.25,
        FleeEnemyUltimates = true,
        MultiThreatAwareness = true,
        M1Range = 8.4,
        M1ComboLimit = 4,
        ApproachRange = 10,
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
        DecisionRate = 1 / 45,
        UIRate = 0.20,
        M1Interval = 0.085,
        SkillInterval = 0.22,
        DashInterval = 0.54,
        DefenseInterval = 0.075,
        BlockDuration = 0.20,
        CameraLead = 0.070,
        CameraSmoothing = 0.72,
        CameraUpdateRate = 1 / 60,
        MovementUpdateRate = 1 / 45,
        MovementSmoothing = 0.42,
        MovementModeHold = 0.14,
        FacingLead = 0.050,
        ObstacleDistance = 4.25,
        ObstacleCheckRate = 0.10,
        JumpCooldown = 0.42,
        DodgeDistance = 7.5,
        DodgeMoveDuration = 0.24,
        UltimateCheckRate = 0.25
    }
}

Env.TSB_AutoCombat = Bot

local CounterNames = {
    ["Prey's Peril"] = true,
    ["Split Second Counter"] = true,
    ["Death Counter"] = true,
    ["Death Blow"] = true,
    ["Spiraling Storm"] = true,
    ["Crossfire"] = true,
    ["Infinity"] = true
}

local ReservedSkillNames = {
    ["Infinity"] = true
}

for name in pairs(CounterNames) do
    ReservedSkillNames[name] = true
end

local CharacterProfiles = {
    Bald = {Name = "The Strongest Hero", Style = "Melee", Approach = 9.0, Retreat = 4.8, SkillRange = 16},
    Batter = {Name = "Brutal Demon", Style = "Melee", Approach = 10.0, Retreat = 5.0, SkillRange = 18},
    Blade = {Name = "Blade Master", Style = "Melee", Approach = 10.5, Retreat = 5.0, SkillRange = 18},
    Cyborg = {Name = "Destructive Cyborg", Style = "Ranged", Approach = 20.0, Retreat = 8.0, SkillRange = 65},
    Esper = {Name = "Wild Psychic", Style = "Ranged", Approach = 19.0, Retreat = 8.0, SkillRange = 38},
    Hunter = {Name = "Hero Hunter", Style = "Melee", Approach = 9.0, Retreat = 4.8, SkillRange = 16},
    KJ = {Name = "KJ", Style = "Melee", Approach = 10.0, Retreat = 5.0, SkillRange = 22},
    Monster = {Name = "Monster Form", Style = "Hybrid", Approach = 12.0, Retreat = 5.5, SkillRange = 34},
    Ninja = {Name = "Deadly Ninja", Style = "Hybrid", Approach = 14.0, Retreat = 6.0, SkillRange = 38},
    Purple = {Name = "Martial Artist", Style = "Melee", Approach = 10.0, Retreat = 5.0, SkillRange = 22},
    Tech = {Name = "Tech Prodigy", Style = "Ranged", Approach = 23.0, Retreat = 9.0, SkillRange = 70},
    Zombie = {Name = "Undying Hero", Style = "Hybrid", Approach = 12.0, Retreat = 5.5, SkillRange = 28},
    Sorcerer = {Name = "Sorcerer", Style = "Ranged", Approach = 24.0, Retreat = 10.0, SkillRange = 80},
    Pirate = {Name = "The Strongest Pirate", Style = "Hybrid", Approach = 11.0, Retreat = 5.0, SkillRange = 26},
    ["Crab Boss"] = {Name = "Crab Boss", Style = "Hybrid", Approach = 13.0, Retreat = 6.0, SkillRange = 36},
    Royale = {Name = "Royale", Style = "Hybrid", Approach = 12.0, Retreat = 5.5, SkillRange = 32}
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

local function horizontal(vector)
    return Vector3.new(vector.X, 0, vector.Z)
end

local function disconnectList(list)
    for i = #list, 1, -1 do
        local connection = list[i]
        list[i] = nil
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function addConnection(list, connection)
    list[#list + 1] = connection
    return connection
end

local CharacterConnections = {}
local TargetConnections = {}
local HotbarConnections = {}
local LiveConnections = {}
local ThreatConnectionsByModel = {}
local ThreatStates = {}

local Character
local Humanoid
local Root
local CharacterKey
local CurrentProfile
local FacingAttachment
local FacingAlign
local TargetHumanoid
local TargetRoot
local TargetAnimator
local LiveFolder
local LiveModels = {}
local HotbarRoot
local HotbarSlots = {}
local DesiredMoveDirection = Vector3.zero
local SmoothedMoveDirection = Vector3.zero
local MovementOverrideDirection
local MovementOverrideUntil = 0
local MovementMode = "IDLE"
local MovementModeUntil = 0
local CameraOverrideDirection
local CameraOverrideUntil = 0
local LastFacingDirection
local LastDecision = 0
local LastTargetScan = 0
local LastHudUpdate = 0
local LastM1 = 0
local LastSkill = 0
local LastDash = 0
local LastDefense = 0
local LastUltimate = 0
local LastUltimateCheck = 0
local UltimateReady = false
local LastObstacleJump = 0
local LastObstacleCheck = 0
local LastCameraUpdate = 0
local LastMovementApply = 0
local LastHotbarBind = 0
local LastHealth = 100
local NextStrafeSwap = 0
local StrafeSide = 1
local Blocking = false
local BlockUntil = 0
local MouseDown = false
local MouseReleaseAt = 0
local LastDefendedSerial = 0
local GeometryThreatAt = 0
local TargetDistance = math.huge
local LastTargetSwitch = 0
local RenderBindName = "TSB_AutoCombat_Camera_" .. tostring(LocalPlayer.UserId)
local MovementBindName = "TSB_AutoCombat_Movement_" .. tostring(LocalPlayer.UserId)

local Perf = {
    CombatSamples = 0,
    CombatTotalMs = 0,
    CombatAvgMs = 0,
    TargetScans = 0,
    ThreatEvents = 0,
    AnimationEvents = 0,
    HotbarUpdates = 0,
    ObservedPlayers = 0,
    GlobalThreatChecks = 0,
    UltimateThreats = 0
}
Bot.Perf = Perf

local Threat = {
    Level = 0,
    Until = 0,
    Serial = 0,
    Source = "NONE",
    AnimationId = "",
    At = 0,
    Model = nil,
    Root = nil,
    Distance = math.huge,
    Facing = 0,
    Ultimate = false,
    UltimateName = ""
}

local VibeUI
local Window
local StatusLabel
local TargetLabel
local CharacterLabel
local ThreatLabel
local PerfLabel
local StatsLabel

local function getCharacterProfile()
    local key = CharacterKey or (Character and Character:GetAttribute("Character"))
    local profile = CharacterProfiles[key]
    if profile then
        return profile
    end

    local skillset = key and Skillsets[key]
    return {
        Name = skillset and skillset.Name or tostring(key or "Unknown"),
        Style = "Hybrid",
        Approach = Bot.Config.ApproachRange,
        Retreat = Bot.Config.RetreatRange,
        SkillRange = 24
    }
end

local function getMoveProfile(name)
    local direct = MoveProfiles[name]
    if direct then
        return direct
    end

    local profile = CurrentProfile or getCharacterProfile()
    local maxRange = profile.SkillRange or 24
    return {
        Max = maxRange,
        Priority = 5,
        ComboMin = profile.Style == "Ranged" and 0 or 1,
        Opener = profile.Style == "Ranged" and maxRange > Bot.Config.M1Range
    }
end

Bot.CharacterProfiles = CharacterProfiles
Bot.MoveProfiles = MoveProfiles
Bot.CounterNames = CounterNames
Bot.Skillsets = Skillsets

local function releaseKey(key)
    pcall(function()
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end)
end

local function pressKey(key)
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, game)
    end)
end

local function pulseKey(key, holdTime)
    pressKey(key)
    task.delay(holdTime or 0.03, function()
        releaseKey(key)
    end)
end

local function releaseMouse()
    if not MouseDown then
        return
    end

    MouseDown = false
    pcall(function()
        local camera = Workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
        VirtualInputManager:SendMouseButtonEvent(
            math.floor(viewport.X * 0.5),
            math.floor(viewport.Y * 0.5),
            0,
            false,
            game,
            0
        )
    end)
end

local function mouse1()
    if MouseDown then
        return
    end

    local camera = Workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(800, 600)
    MouseDown = true
    MouseReleaseAt = os.clock() + 0.018

    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(
            math.floor(viewport.X * 0.5),
            math.floor(viewport.Y * 0.5),
            0,
            true,
            game,
            0
        )
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

local function ensureFacing()
    if not Root or not Humanoid then
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
        FacingAlign.RigidityEnabled = false
        FacingAlign.Responsiveness = 72
        FacingAlign.MaxAngularVelocity = 32
        FacingAlign.MaxTorque = math.huge
        FacingAlign.Parent = Root
    end

    Humanoid.AutoRotate = false
end

local function setFacing(targetRoot)
    if not Bot.Config.AutoMovement or not Root or not targetRoot then
        return
    end

    ensureFacing()

    local predicted = targetRoot.Position + horizontal(targetRoot.AssemblyLinearVelocity) * Bot.Config.FacingLead
    local direction = horizontal(predicted - Root.Position)

    if direction.Magnitude > 0.001 and FacingAlign then
        local unit = direction.Unit
        if not LastFacingDirection or LastFacingDirection:Dot(unit) < 0.9994 then
            LastFacingDirection = unit
            FacingAlign.CFrame = CFrame.lookAt(Vector3.zero, unit)
        end
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

local function tryAutoJump(direction, now)
    if not Bot.Config.AutoJump or not Character or not Humanoid or not Root then
        return
    end

    if now - LastObstacleCheck < Bot.Config.ObstacleCheckRate then
        return
    end
    LastObstacleCheck = now

    local flat = horizontal(direction)
    if flat.Magnitude < 0.15 then
        return
    end

    local filters = {Character}
    if Bot.Target then
        filters[#filters + 1] = Bot.Target
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = filters
    params.IgnoreWater = true

    local directionUnit = flat.Unit
    local lowerOrigin = Root.Position - Vector3.new(0, 0.85, 0)
    local lowerHit = Workspace:Raycast(
        lowerOrigin,
        directionUnit * Bot.Config.ObstacleDistance,
        params
    )

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
        return
    end

    if not Humanoid or Humanoid.Health <= 0 or not Root or not Root.Parent then
        return
    end

    local now = os.clock()
    if now - LastMovementApply < Bot.Config.MovementUpdateRate then
        return
    end
    LastMovementApply = now

    local direction = DesiredMoveDirection
    local hardOverride = false

    if MovementOverrideDirection and now < MovementOverrideUntil then
        direction = MovementOverrideDirection
        hardOverride = true
    elseif MovementOverrideDirection then
        MovementOverrideDirection = nil
        MovementOverrideUntil = 0
    end

    direction = horizontal(direction)
    if direction.Magnitude > 1 then
        direction = direction.Unit
    end

    if direction.Magnitude <= 0.03 then
        SmoothedMoveDirection = Vector3.zero
        Humanoid:Move(Vector3.zero, false)
        return
    end

    local targetDirection = direction.Unit
    if hardOverride or SmoothedMoveDirection.Magnitude <= 0.03 then
        SmoothedMoveDirection = targetDirection
    else
        local alpha = math.clamp(Bot.Config.MovementSmoothing, 0.08, 1)
        local blended = SmoothedMoveDirection:Lerp(targetDirection, alpha)
        SmoothedMoveDirection = blended.Magnitude > 0.03 and blended.Unit or targetDirection
    end

    Humanoid:Move(SmoothedMoveDirection, false)
    tryAutoJump(SmoothedMoveDirection, now)
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

local ThreatSerialCounter = 0

local function nextThreatSerial()
    ThreatSerialCounter += 1
    return ThreatSerialCounter
end

local function facingToUsFrom(enemyRoot)
    if not enemyRoot or not Root then
        return 0
    end

    local towardUs = horizontal(Root.Position - enemyRoot.Position)
    local look = horizontal(enemyRoot.CFrame.LookVector)

    if towardUs.Magnitude <= 0.001 or look.Magnitude <= 0.001 then
        return 0
    end

    return look.Unit:Dot(towardUs.Unit)
end

local function getThreatState(model)
    local state = ThreatStates[model]
    if not state then
        state = {
            Model = model,
            Root = nil,
            Humanoid = nil,
            Level = 0,
            Source = "NONE",
            Until = 0,
            Serial = 0,
            AnimationId = "",
            At = 0,
            UltimateUntil = 0,
            UltimateName = "",
            GeometryAt = 0
        }
        ThreatStates[model] = state
    end
    return state
end

local function ultimateWindow(model, now)
    if not model or model == Character or not model.Parent then
        return 0, ""
    end

    local duration = tonumber(model:GetAttribute("UltimateTime")) or 45
    duration = math.clamp(duration, 8, 90)

    local used = tonumber(model:GetAttribute("UsedUltimate"))
        or tonumber(model:GetAttribute("JustUlted"))

    local ultimateName = tostring(model:GetAttribute("UltimateName") or "ULTIMATE")
    local serverNow = Workspace:GetServerTimeNow()

    if model:GetAttribute("Ulted") == true then
        if used then
            local remaining = used + duration + Bot.Config.UltimateGrace - serverNow
            return now + math.max(0.5, remaining), ultimateName
        end
        return now + duration, ultimateName
    end

    if used then
        local remaining = used + duration + Bot.Config.UltimateGrace - serverNow
        if remaining > 0 then
            return now + remaining, ultimateName
        end
    end

    return 0, ultimateName
end

local function raiseThreat(model, level, source, ttl, animationId)
    if not Root or not model or model == Character or not model.Parent then
        return false
    end

    local humanoid, enemyRoot = getTargetParts(model)
    if not humanoid or not enemyRoot then
        return false
    end

    local distance = (enemyRoot.Position - Root.Position).Magnitude
    local maxRange = Bot.Config.ThreatRadius

    if source == "SKILL" or (source == "ANIMATION" and level >= 3) then
        maxRange = Bot.Config.GlobalThreatRadius
    elseif source == "ULTIMATE" then
        maxRange = Bot.Config.UltimateDangerRadius
    elseif source == "DASH" or source == "RUSH" then
        maxRange = math.max(Bot.Config.ThreatRadius, 28)
    elseif source == "M1" then
        maxRange = 14
    end

    if distance > maxRange then
        return false
    end

    local facing = facingToUsFrom(enemyRoot)
    if distance > Bot.Config.ThreatRadius
        and source ~= "ULTIMATE"
        and facing < -0.15 then
        return false
    end

    local now = os.clock()
    local state = getThreatState(model)
    state.Root = enemyRoot
    state.Humanoid = humanoid
    state.Level = math.max(level, now <= state.Until and state.Level or 0)
    state.Source = source or "UNKNOWN"
    state.Until = math.max(state.Until, now + (ttl or Bot.Config.ThreatMemory))
    state.Serial = nextThreatSerial()
    state.AnimationId = animationId or state.AnimationId
    state.At = now

    Perf.ThreatEvents += 1
    return true
end

local function markUltimateThreat(model)
    if not Bot.Config.FleeEnemyUltimates or not model or model == Character then
        return
    end

    local now = os.clock()
    local finish, ultimateName = ultimateWindow(model, now)
    if finish <= now then
        return
    end

    local state = getThreatState(model)
    local wasActive = state.UltimateUntil > now
    state.UltimateUntil = math.max(state.UltimateUntil, finish)
    state.UltimateName = ultimateName
    state.Level = 5
    state.Source = "ULTIMATE"
    state.Until = math.max(state.Until, finish)
    state.Serial = nextThreatSerial()
    state.At = now

    local humanoid, enemyRoot = getTargetParts(model)
    state.Humanoid = humanoid
    state.Root = enemyRoot

    if not wasActive then
        Perf.UltimateThreats += 1
    end
end

local function clearThreatState(model)
    ThreatStates[model] = nil
    if Threat.Model == model then
        Threat.Level = 0
        Threat.Until = 0
        Threat.Source = "NONE"
        Threat.AnimationId = ""
        Threat.Model = nil
        Threat.Root = nil
        Threat.Distance = math.huge
        Threat.Facing = 0
        Threat.Ultimate = false
        Threat.UltimateName = ""
    end
end

local function disconnectThreatModel(model)
    local list = ThreatConnectionsByModel[model]
    if list then
        disconnectList(list)
        ThreatConnectionsByModel[model] = nil
    end
    clearThreatState(model)

    local count = 0
    for _ in pairs(ThreatConnectionsByModel) do
        count += 1
    end
    Perf.ObservedPlayers = count
end

local function priorityThreat(priority)
    if priority == Enum.AnimationPriority.Action4 then
        return 4
    elseif priority == Enum.AnimationPriority.Action3 then
        return 3
    elseif priority == Enum.AnimationPriority.Action2 then
        return 2
    elseif priority == Enum.AnimationPriority.Action then
        return 1
    end
    return 0
end

local function bindThreatModel(model)
    if not model or not model.Parent or model == Character then
        return
    end

    local owner = Players:GetPlayerFromCharacter(model)
    if owner == LocalPlayer then
        return
    end

    if Bot.Config.PlayersOnly and not owner then
        return
    end

    disconnectThreatModel(model)

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local enemyRoot = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not enemyRoot then
        task.delay(0.15, function()
            if model.Parent and LiveModels[model] then
                bindThreatModel(model)
            end
        end)
        return
    end

    local list = {}
    ThreatConnectionsByModel[model] = list
    local state = getThreatState(model)
    state.Humanoid = humanoid
    state.Root = enemyRoot

    local boundAnimator
    local function attachAnimator(animator)
        if not animator or animator == boundAnimator or not animator:IsA("Animator") then
            return
        end
        boundAnimator = animator

        addConnection(list, animator.AnimationPlayed:Connect(function(track)
            local level = priorityThreat(track.Priority)
            if level <= 0 then
                return
            end
            Perf.AnimationEvents += 1

            local animation = track.Animation
            local animationId = animation and animation.AnimationId or ""
            local ttl = math.clamp(
                tonumber(track.Length) or Bot.Config.ThreatMemory,
                0.16,
                level >= 3 and Bot.Config.RangedThreatMemory or 0.55
            )

            raiseThreat(model, level, "ANIMATION", ttl, animationId)
        end))
    end

    attachAnimator(humanoid:FindFirstChildOfClass("Animator"))

    addConnection(list, humanoid.ChildAdded:Connect(function(child)
        if child:IsA("Animator") then
            attachAnimator(child)
        end
    end))

    local lastM1 = model:GetAttribute("LastM1Fire")
    local lastSkill = model:GetAttribute("LastSkill")
    local lastDash = model:GetAttribute("JustForwardDashed")
    local lastJustUlted = model:GetAttribute("JustUlted")
    local lastUsedUltimate = model:GetAttribute("UsedUltimate")
    local lastUlted = model:GetAttribute("Ulted")

    addConnection(list, model:GetAttributeChangedSignal("LastM1Fire"):Connect(function()
        local value = model:GetAttribute("LastM1Fire")
        if value == lastM1 then
            return
        end
        lastM1 = value
        raiseThreat(model, 3, "M1", 0.24)
    end))

    addConnection(list, model:GetAttributeChangedSignal("LastSkill"):Connect(function()
        local value = model:GetAttribute("LastSkill")
        if value == lastSkill then
            return
        end
        lastSkill = value
        raiseThreat(model, 4, "SKILL", Bot.Config.RangedThreatMemory)
    end))

    addConnection(list, model:GetAttributeChangedSignal("JustForwardDashed"):Connect(function()
        local value = model:GetAttribute("JustForwardDashed")
        if value == lastDash then
            return
        end
        lastDash = value
        raiseThreat(model, 3, "DASH", 0.32)
    end))

    addConnection(list, model:GetAttributeChangedSignal("JustUlted"):Connect(function()
        local value = model:GetAttribute("JustUlted")
        if value == lastJustUlted then
            return
        end
        lastJustUlted = value
        markUltimateThreat(model)
    end))

    addConnection(list, model:GetAttributeChangedSignal("UsedUltimate"):Connect(function()
        local value = model:GetAttribute("UsedUltimate")
        if value == lastUsedUltimate then
            return
        end
        lastUsedUltimate = value
        markUltimateThreat(model)
    end))

    addConnection(list, model:GetAttributeChangedSignal("Ulted"):Connect(function()
        local value = model:GetAttribute("Ulted")
        if value == lastUlted then
            return
        end
        lastUlted = value
        markUltimateThreat(model)
    end))

    addConnection(list, humanoid.Died:Connect(function()
        clearThreatState(model)
    end))

    addConnection(list, model.AncestryChanged:Connect(function(_, parent)
        if not parent then
            disconnectThreatModel(model)
        end
    end))

    markUltimateThreat(model)

    local count = 0
    for _ in pairs(ThreatConnectionsByModel) do
        count += 1
    end
    Perf.ObservedPlayers = count
end

local function clearTarget()
    disconnectList(TargetConnections)
    Bot.Target = nil
    TargetHumanoid = nil
    TargetRoot = nil
    TargetAnimator = nil
    TargetDistance = math.huge
end

local function bindTarget(model, humanoid, root)
    if Bot.Target == model and TargetHumanoid == humanoid and TargetRoot == root then
        return
    end

    disconnectList(TargetConnections)
    Bot.Target = model
    TargetHumanoid = humanoid
    TargetRoot = root
    TargetAnimator = humanoid:FindFirstChildOfClass("Animator")
    LastTargetSwitch = os.clock()

    addConnection(TargetConnections, humanoid.Died:Connect(function()
        if Bot.Target == model then
            clearTarget()
        end
    end))

    addConnection(TargetConnections, model.AncestryChanged:Connect(function(_, parent)
        if not parent and Bot.Target == model then
            clearTarget()
        end
    end))
end

local function refreshTarget(now, force)
    if not Root then
        clearTarget()
        return nil
    end

    local currentValid = Bot.Target and isValidTarget(
        Bot.Target,
        Bot.Config.TargetRadius + Bot.Config.TargetSwitchAdvantage
    )

    if currentValid
        and not force
        and now - LastTargetSwitch < Bot.Config.TargetLockTime then
        TargetDistance = TargetRoot and (TargetRoot.Position - Root.Position).Magnitude or TargetDistance
        return Bot.Target
    end

    if currentValid and not force and now - LastTargetScan < Bot.Config.TargetScanRate then
        return Bot.Target
    end

    if not currentValid and now - LastTargetScan < Bot.Config.TargetScanRate * 0.5 then
        return nil
    end

    LastTargetScan = now
    Perf.TargetScans += 1

    local nearest
    local nearestHumanoid
    local nearestRoot
    local nearestDistance = Bot.Config.TargetRadius

    for model in pairs(LiveModels) do
        if model ~= Character and model.Parent then
            if not Bot.Config.PlayersOnly or Players:GetPlayerFromCharacter(model) then
                local humanoid, root = getTargetParts(model)
                if humanoid and root then
                    local distance = (root.Position - Root.Position).Magnitude
                    if distance < nearestDistance then
                        nearest = model
                        nearestHumanoid = humanoid
                        nearestRoot = root
                        nearestDistance = distance
                    end
                end
            end
        end
    end

    if currentValid and Bot.Target and TargetRoot then
        local currentDistance = (TargetRoot.Position - Root.Position).Magnitude
        if not nearest
            or nearest == Bot.Target
            or nearestDistance + Bot.Config.TargetSwitchAdvantage >= currentDistance then
            TargetDistance = currentDistance
            return Bot.Target
        end
    end

    if nearest then
        bindTarget(nearest, nearestHumanoid, nearestRoot)
        TargetDistance = nearestDistance
        return nearest
    end

    clearTarget()
    return nil
end

local function bindLiveFolder(folder)
    disconnectList(LiveConnections)

    for model in pairs(ThreatConnectionsByModel) do
        disconnectThreatModel(model)
    end

    table.clear(LiveModels)
    LiveFolder = folder

    if not folder then
        return
    end

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            LiveModels[child] = true
            task.defer(bindThreatModel, child)
        end
    end

    addConnection(LiveConnections, folder.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            LiveModels[child] = true
            task.defer(bindThreatModel, child)
        end
    end))

    addConnection(LiveConnections, folder.ChildRemoved:Connect(function(child)
        LiveModels[child] = nil
        disconnectThreatModel(child)
        if child == Bot.Target then
            clearTarget()
        end
    end))
end

local function raiseHitThreat()
    if not Root then
        return
    end

    local bestModel
    local bestDistance = math.huge

    for model in pairs(LiveModels) do
        if model ~= Character and model.Parent then
            local humanoid, enemyRoot = getTargetParts(model)
            if humanoid and enemyRoot then
                local distance = (enemyRoot.Position - Root.Position).Magnitude
                if distance < bestDistance and distance <= 20 then
                    bestDistance = distance
                    bestModel = model
                end
            end
        end
    end

    if not bestModel then
        bestModel = Bot.Target
    end

    if bestModel then
        raiseThreat(bestModel, 4, "HIT", 0.30)
    end
end

local function isUsableSkillName(name)
    return type(name) == "string"
        and name ~= ""
        and name ~= "N/A"
        and name ~= "None"
        and name ~= "NONE"
        and name ~= "-"
end

local function refreshSlot(index)
    local cached = HotbarSlots[index]
    if not cached then
        return
    end

    local base = cached.Base
    local toolName = base and base:FindFirstChild("ToolName")
    cached.Name = toolName and toolName:IsA("TextLabel") and toolName.Text or ""
    cached.Ready = base ~= nil
        and base:FindFirstChild("Cooldown") == nil
        and isUsableSkillName(cached.Name)
    Perf.HotbarUpdates += 1
end

local function bindHotbar()
    local now = os.clock()
    if now - LastHotbarBind < 0.4 then
        return
    end
    LastHotbarBind = now

    disconnectList(HotbarConnections)
    table.clear(HotbarSlots)
    HotbarRoot = nil

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local backpack = playerGui
        and playerGui:FindFirstChild("Hotbar")
        and playerGui.Hotbar:FindFirstChild("Backpack")
    local hotbar = backpack and backpack:FindFirstChild("Hotbar")

    if not hotbar then
        return
    end

    HotbarRoot = hotbar

    for i = 1, 13 do
        local slot = hotbar:FindFirstChild(tostring(i))
        local base = slot and slot:FindFirstChild("Base")

        if base then
            local entry = {
                Index = i,
                Base = base,
                Name = "",
                Ready = false
            }
            HotbarSlots[i] = entry
            refreshSlot(i)

            local toolName = base:FindFirstChild("ToolName")
            if toolName and toolName:IsA("TextLabel") then
                addConnection(HotbarConnections, toolName:GetPropertyChangedSignal("Text"):Connect(function()
                    refreshSlot(i)
                end))
            end

            addConnection(HotbarConnections, base.ChildAdded:Connect(function(child)
                if child.Name == "Cooldown" or child.Name == "ToolName" then
                    refreshSlot(i)
                end
            end))

            addConnection(HotbarConnections, base.ChildRemoved:Connect(function(child)
                if child.Name == "Cooldown" or child.Name == "ToolName" then
                    refreshSlot(i)
                end
            end))
        end
    end

    addConnection(HotbarConnections, hotbar.ChildAdded:Connect(function()
        task.defer(bindHotbar)
    end))

    addConnection(HotbarConnections, hotbar.ChildRemoved:Connect(function()
        task.defer(bindHotbar)
    end))
end

local function ensureHotbar()
    if not HotbarRoot or not HotbarRoot.Parent then
        bindHotbar()
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
    if not slot or not slot.Ready or slot.Name == "" then
        return false
    end

    local key = keyForSlot(slot.Index)
    if not key then
        return false
    end

    pulseKey(key, 0.035)
    Bot.Action = action or ("SKILL " .. tostring(slot.Index))
    Bot.Stats.Skills += 1
    LastSkill = os.clock()
    return true
end

local function getCounterSkill(distance)
    ensureHotbar()

    local best
    for i = 1, 13 do
        local slot = HotbarSlots[i]
        if slot and slot.Ready and CounterNames[slot.Name] then
            local move = getMoveProfile(slot.Name)
            if distance <= (move.Max or 16) + 2 then
                if not best or slot.Index < best.Index then
                    best = slot
                end
            end
        end
    end
    return best
end

local function targetFacingUs(enemyRoot)
    return facingToUsFrom(enemyRoot or TargetRoot)
end

local function scoreThreatCandidate(model, enemyRoot, level, source, distance, facing, ultimate)
    local score = level * 100
    score -= distance * (ultimate and 0.18 or 0.55)
    score += math.max(facing, -0.5) * 18

    if source == "ULTIMATE" then
        score += 1000
    elseif source == "SKILL" then
        score += 42
    elseif source == "HIT" then
        score += 36
    elseif source == "M1" then
        score += 18
    elseif source == "DASH" or source == "RUSH" then
        score += 24
    end

    if model == Bot.Target then
        score += 6
    end

    return score
end

local function detectThreat(now)
    if not Root then
        return nil
    end

    Perf.GlobalThreatChecks += 1

    local best
    local bestScore = -math.huge

    local function consider(model, state, level, source, serial, ultimate, ultimateName)
        if not model or model == Character or not model.Parent then
            return
        end

        if not Bot.Config.MultiThreatAwareness and model ~= Bot.Target and not ultimate then
            return
        end

        local humanoid, enemyRoot = getTargetParts(model)
        if not humanoid or not enemyRoot then
            return
        end

        local distance = (enemyRoot.Position - Root.Position).Magnitude
        local maxRange = ultimate and Bot.Config.UltimateDangerRadius or Bot.Config.GlobalThreatRadius
        if distance > maxRange then
            return
        end

        local facing = facingToUsFrom(enemyRoot)
        local score = scoreThreatCandidate(model, enemyRoot, level, source, distance, facing, ultimate)

        if score > bestScore then
            bestScore = score
            best = {
                Model = model,
                Root = enemyRoot,
                Humanoid = humanoid,
                Level = level,
                Source = source,
                Serial = serial,
                Distance = distance,
                Facing = facing,
                Ultimate = ultimate,
                UltimateName = ultimateName or "",
                State = state
            }
        end
    end

    for model, state in pairs(ThreatStates) do
        if not model.Parent then
            ThreatStates[model] = nil
        else
            local finish, ultimateName = ultimateWindow(model, now)
            if Bot.Config.FleeEnemyUltimates and finish > now then
                if finish > state.UltimateUntil then
                    state.UltimateUntil = finish
                    state.UltimateName = ultimateName
                    state.Serial = nextThreatSerial()
                end
            end

            if Bot.Config.FleeEnemyUltimates and state.UltimateUntil > now then
                consider(model, state, 5, "ULTIMATE", state.Serial, true, state.UltimateName)
            elseif state.Until > now and state.Level > 0 then
                consider(model, state, state.Level, state.Source, state.Serial, false, "")
            end
        end
    end

    for model in pairs(LiveModels) do
        if model ~= Character and model.Parent then
            local humanoid, enemyRoot = getTargetParts(model)
            if humanoid and enemyRoot then
                local distance = (enemyRoot.Position - Root.Position).Magnitude
                if distance <= math.max(Bot.Config.ThreatRadius, 18) then
                    local towardUs = horizontal(Root.Position - enemyRoot.Position)
                    local velocity = horizontal(enemyRoot.AssemblyLinearVelocity)
                    local facing = facingToUsFrom(enemyRoot)

                    if towardUs.Magnitude > 0.001 and velocity.Magnitude > 0.001 then
                        local closingSpeed = velocity:Dot(towardUs.Unit)
                        if closingSpeed > 20 and distance <= 16 and facing > 0.12 then
                            local state = getThreatState(model)
                            if now - state.GeometryAt > 0.25 then
                                state.GeometryAt = now
                                state.Serial = nextThreatSerial()
                            end
                            consider(model, state, 3, "RUSH", state.Serial, false, "")
                        elseif closingSpeed > 12 and distance <= 11 and facing > 0.45 then
                            local state = getThreatState(model)
                            if now - state.GeometryAt > 0.30 then
                                state.GeometryAt = now
                                state.Serial = nextThreatSerial()
                            end
                            consider(model, state, 2, "CLOSING", state.Serial, false, "")
                        end
                    end

                    if distance <= 8.5 and facing > 0.75 then
                        local state = getThreatState(model)
                        if now - state.GeometryAt > 0.32 then
                            state.GeometryAt = now
                            state.Serial = nextThreatSerial()
                        end
                        consider(model, state, 1, "PRESSURE", state.Serial, false, "")
                    end
                end
            end
        end
    end

    if best then
        Threat.Level = best.Level
        Threat.Until = best.Ultimate and (best.State and best.State.UltimateUntil or now + 0.5)
            or (best.State and best.State.Until or now + Bot.Config.ThreatMemory)
        Threat.Serial = best.Serial
        Threat.Source = best.Source
        Threat.AnimationId = best.State and best.State.AnimationId or ""
        Threat.At = now
        Threat.Model = best.Model
        Threat.Root = best.Root
        Threat.Distance = best.Distance
        Threat.Facing = best.Facing
        Threat.Ultimate = best.Ultimate
        Threat.UltimateName = best.UltimateName
        return best
    end

    Threat.Level = 0
    Threat.Until = 0
    Threat.Source = "NONE"
    Threat.AnimationId = ""
    Threat.Model = nil
    Threat.Root = nil
    Threat.Distance = math.huge
    Threat.Facing = 0
    Threat.Ultimate = false
    Threat.UltimateName = ""
    return nil
end

local function canAct()
    if not Character or not Humanoid or Humanoid.Health <= 0 then
        return false
    end

    if Character:GetAttribute("Ragdoll")
        or Character:GetAttribute("Freeze")
        or Character:GetAttribute("Slowed")
        or Character:GetAttribute("GlobalStun") then
        Bot.Action = "STUNNED / RAGDOLLED"
        return false
    end

    return true
end

local function chooseDodgeDirection(threatRoot)
    if not Root then
        return nil, "NONE"
    end

    threatRoot = threatRoot or TargetRoot
    if not threatRoot then
        return nil, "NONE"
    end

    local toward = horizontal(threatRoot.Position - Root.Position)
    if toward.Magnitude <= 0.001 then
        return nil, "NONE"
    end
    toward = toward.Unit

    local right = Vector3.new(-toward.Z, 0, toward.X)
    local back = -toward
    local candidates = {
        {Name = "RIGHT", Direction = right},
        {Name = "LEFT", Direction = -right},
        {Name = "BACK-RIGHT", Direction = (back + right * 0.68).Unit},
        {Name = "BACK-LEFT", Direction = (back - right * 0.68).Unit},
        {Name = "BACK", Direction = back}
    }

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {Character}
    params.IgnoreWater = true

    local predictedEnemy = threatRoot.Position + horizontal(threatRoot.AssemblyLinearVelocity) * 0.18
    local best
    local bestScore = -math.huge
    local now = os.clock()

    for _, candidate in ipairs(candidates) do
        local direction = candidate.Direction
        local hit = Workspace:Raycast(
            Root.Position + Vector3.new(0, 0.5, 0),
            direction * Bot.Config.DodgeDistance,
            params
        )

        local endpoint = Root.Position + direction * Bot.Config.DodgeDistance
        local score = (horizontal(endpoint - predictedEnemy)).Magnitude * 1.8

        if hit and hit.Instance and hit.Instance:IsA("BasePart") and hit.Instance.CanCollide then
            score -= 55
        else
            score += 12
        end

        local nearestOther = math.huge
        for model in pairs(LiveModels) do
            if model ~= Character and model.Parent then
                local _, otherRoot = getTargetParts(model)
                if otherRoot then
                    local separation = horizontal(endpoint - otherRoot.Position).Magnitude
                    nearestOther = math.min(nearestOther, separation)

                    local state = ThreatStates[model]
                    if state and state.UltimateUntil > now then
                        score += math.min(separation, 60) * 0.42
                    end
                end
            end
        end

        if nearestOther < math.huge then
            score += math.min(nearestOther, 24) * 0.26
        end

        if candidate.Name == "RIGHT" and StrafeSide > 0 then
            score += 1.5
        elseif candidate.Name == "LEFT" and StrafeSide < 0 then
            score += 1.5
        end

        if score > bestScore then
            bestScore = score
            best = candidate
        end
    end

    return best and best.Direction or nil, best and best.Name or "NONE"
end

local function doDodge(level, threatRoot)
    local now = os.clock()
    if now - LastDash < Bot.Config.DashInterval then
        return false
    end

    if not Humanoid or not Root then
        return false
    end

    local direction, name = chooseDodgeDirection(threatRoot)
    if not direction then
        return false
    end

    LastDash = now
    MovementOverrideDirection = direction
    MovementOverrideUntil = now + Bot.Config.DodgeMoveDuration
    CameraOverrideDirection = direction
    CameraOverrideUntil = now + 0.16
    setDesiredMovement(direction)
    SmoothedMoveDirection = direction
    Bot.Action = "DODGE: " .. name
    Bot.Stats.Dodges += 1

    task.delay(0.025, function()
        if not Bot.Enabled then
            return
        end

        if level >= 4 and math.random() < 0.18 then
            requestJump()
        end

        pulseKey(Enum.KeyCode.Q, 0.035)
    end)

    return true
end

local function doBlock(level, threatRoot)
    if not Bot.Enabled then
        return false
    end

    local now = os.clock()
    local duration = Bot.Config.BlockDuration

    if level >= 4 then
        duration = math.max(duration, 0.31)
    elseif level <= 1 then
        duration = math.min(duration, 0.15)
    end

    if threatRoot and Root then
        setFacing(threatRoot)
        local towardThreat = horizontal(threatRoot.Position - Root.Position)
        if towardThreat.Magnitude > 0.001 then
            CameraOverrideDirection = towardThreat.Unit
            CameraOverrideUntil = now + math.max(duration, 0.16)
        end
    end

    if not Blocking then
        pressKey(Enum.KeyCode.F)
        Blocking = true
        Bot.Stats.Blocks += 1
    end

    BlockUntil = math.max(BlockUntil, now + duration)
    Bot.Action = "BLOCK"
    return true
end

local function defend(threat)
    if not Bot.Config.AutoDefense or not threat or threat.Level <= 0 then
        return false
    end

    local now = os.clock()
    if now - LastDefense < Bot.Config.DefenseInterval then
        return false
    end

    if threat.Serial == LastDefendedSerial and threat.Source ~= "HIT" then
        return false
    end

    LastDefense = now
    LastDefendedSerial = threat.Serial

    local level = threat.Level
    local source = threat.Source
    local distance = threat.Distance
    local facing = threat.Facing
    local threatRoot = threat.Root

    if threatRoot then
        setFacing(threatRoot)
    end

    if Bot.Config.CounterPriority
        and level >= 4
        and threat.Model == Bot.Target then
        local counter = getCounterSkill(distance)
        if counter and now - LastSkill >= Bot.Config.SkillInterval then
            if useSlot(counter, "COUNTER: " .. counter.Name) then
                Bot.Stats.Counters += 1
                return true
            end
        end
    end

    if source == "M1" and distance <= 10 and facing > 0.20 then
        return doBlock(level, threatRoot)
    end

    if source == "DASH" or source == "RUSH" then
        if doDodge(level, threatRoot) then
            return true
        end
        return doBlock(level, threatRoot)
    end

    if level >= 4 then
        if doDodge(level, threatRoot) then
            return true
        end
        return doBlock(level, threatRoot)
    end

    if level == 3 then
        if distance <= 8.5 and facing > 0.42 then
            return doBlock(level, threatRoot)
        end
        if doDodge(level, threatRoot) then
            return true
        end
        return doBlock(level, threatRoot)
    end

    if facing > 0.55 and distance <= 9 then
        return doBlock(level, threatRoot)
    end

    return false
end

local function fleeUltimate(threat, now)
    if not Bot.Config.FleeEnemyUltimates
        or not threat
        or not threat.Ultimate
        or not threat.Root
        or not Root then
        return false
    end

    local away = horizontal(Root.Position - threat.Root.Position)
    if away.Magnitude <= 0.001 then
        away = -horizontal(threat.Root.CFrame.LookVector)
    end
    if away.Magnitude <= 0.001 then
        return false
    end

    away = away.Unit
    local right = Vector3.new(-away.Z, 0, away.X)
    local escape = away + right * StrafeSide * 0.24
    escape = escape.Magnitude > 0.001 and escape.Unit or away

    MovementMode = "ULTIMATE_ESCAPE"
    MovementModeUntil = now + 0.25
    MovementOverrideDirection = escape
    MovementOverrideUntil = now + 0.14
    CameraOverrideDirection = escape
    CameraOverrideUntil = now + 0.22
    setDesiredMovement(escape)

    local name = threat.UltimateName ~= "" and threat.UltimateName or "ULTIMATE"
    Bot.Action = string.format("FLEE ULT: %s", name)

    if threat.Distance <= 70 then
        doDodge(5, threat.Root)
    end

    return true
end

local function checkUltimateReady(now)
    if now - LastUltimateCheck < Bot.Config.UltimateCheckRate then
        return UltimateReady
    end
    LastUltimateCheck = now

    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    local bar = playerGui and playerGui:FindFirstChild("Bar")
    local magic = bar and bar:FindFirstChild("MagicHealth")
    local ult = magic and magic:FindFirstChild("Ult")

    UltimateReady = ult ~= nil and ult:IsA("GuiObject") and ult.Visible
    return UltimateReady
end

local function useUltimateIfReady(now)
    if not Bot.Config.AutoUltimate or now - LastUltimate < 4 then
        return false
    end

    if not checkUltimateReady(now) then
        return false
    end

    local profile = CurrentProfile or getCharacterProfile()
    local maxActivationRange = profile.Style == "Ranged" and 38 or 24
    if TargetDistance > maxActivationRange then
        return false
    end

    pulseKey(Enum.KeyCode.G, 0.04)
    LastUltimate = now
    Bot.Stats.Ultimates += 1
    Bot.Action = "ULTIMATE"
    return true
end

local function chooseOffensiveSkill(distance, target)
    if not Bot.Config.AutoSkills or os.clock() - LastSkill < Bot.Config.SkillInterval then
        return false
    end

    ensureHotbar()
    if not HotbarRoot then
        return false
    end

    local targetRagdolled = target:GetAttribute("Ragdoll") == true
    local targetBlocking = target:GetAttribute("Blocking") == true
    local combo = tonumber(Character:GetAttribute("Combo")) or 0
    local profile = CurrentProfile or getCharacterProfile()

    local best
    local bestScore = math.huge

    for i = 1, 13 do
        local slot = HotbarSlots[i]
        if slot and slot.Ready and slot.Name ~= "" and not ReservedSkillNames[slot.Name] then
            local move = getMoveProfile(slot.Name)
            local minRange = move.Min or 0
            local maxRange = move.Max or profile.SkillRange or 24
            local comboMin = move.ComboMin or 0

            if distance >= minRange and distance <= maxRange then
                local allowed = true

                if combo < comboMin and not move.Opener and not targetRagdolled then
                    allowed = false
                end

                if move.RagdollOnly and not targetRagdolled then
                    allowed = false
                end

                if targetBlocking and not move.BlockPunish and distance <= Bot.Config.M1Range + 1 then
                    allowed = false
                end

                if allowed then
                    local score = (move.Priority or 5) * 10 + slot.Index

                    if move.PreferRagdoll and targetRagdolled then
                        score -= 26
                    end

                    if move.Opener and distance > Bot.Config.M1Range then
                        score -= 22
                    end

                    if move.BlockPunish and targetBlocking then
                        score -= 28
                    end

                    if combo >= 2 and combo >= comboMin and not move.Opener then
                        score -= math.min(combo, 4) * 4
                    end

                    if profile.Style == "Ranged" and maxRange >= 25 and distance >= 10 then
                        score -= 8
                    end

                    if targetRagdolled and not move.PreferRagdoll then
                        score += 3
                    end

                    local rangeFit = math.abs(distance - math.min(maxRange * 0.62, maxRange - 1))
                    score += rangeFit * 0.08

                    if score < bestScore then
                        bestScore = score
                        best = slot
                    end
                end
            end
        end
    end

    if best then
        return useSlot(best, "SKILL " .. best.Index .. ": " .. best.Name)
    end

    return false
end

local function doM1(distance, target)
    if not Bot.Config.AutoM1 or distance > Bot.Config.M1Range then
        return false
    end

    local now = os.clock()
    if now - LastM1 < Bot.Config.M1Interval then
        return false
    end

    if Character:GetAttribute("M1Ready") == false then
        return false
    end

    if target:GetAttribute("Blocking") or target:GetAttribute("Ragdoll") then
        return false
    end

    LastM1 = now
    mouse1()
    Bot.Stats.M1 += 1
    Bot.Action = "M1"
    return true
end

local function tacticalRanges()
    local profile = CurrentProfile or getCharacterProfile()
    local approach = profile.Approach or Bot.Config.ApproachRange
    local retreat = profile.Retreat or Bot.Config.RetreatRange

    if profile.Style == "Ranged" then
        ensureHotbar()
        for i = 1, 13 do
            local slot = HotbarSlots[i]
            if slot and slot.Ready and slot.Name ~= "" and not ReservedSkillNames[slot.Name] then
                local move = getMoveProfile(slot.Name)
                if move.Opener and (move.Max or 0) >= 24 then
                    approach = math.max(approach, math.min(26, (move.Max or 24) * 0.42))
                    break
                end
            end
        end
    end

    return approach, retreat
end

local function moveCombat(now)
    if not Bot.Config.AutoMovement or not Humanoid or not Root or not TargetRoot then
        return
    end

    setFacing(TargetRoot)

    local delta = horizontal(TargetRoot.Position - Root.Position)
    if delta.Magnitude <= 0.001 then
        MovementMode = "IDLE"
        setDesiredMovement(Vector3.zero)
        return
    end

    local approachRange, retreatRange = tacticalRanges()
    local toward = delta.Unit
    local targetBlocking = Bot.Target and Bot.Target:GetAttribute("Blocking") == true
    local requestedMode

    if targetBlocking and TargetDistance < Bot.Config.M1Range + 1 then
        requestedMode = "RETREAT"
    elseif MovementMode == "APPROACH" and TargetDistance > approachRange - 0.65 then
        requestedMode = "APPROACH"
    elseif MovementMode == "RETREAT" and TargetDistance < retreatRange + 0.85 then
        requestedMode = "RETREAT"
    elseif TargetDistance > approachRange + 0.45 then
        requestedMode = "APPROACH"
    elseif TargetDistance < retreatRange - 0.15 then
        requestedMode = "RETREAT"
    else
        requestedMode = "STRAFE"
    end

    if requestedMode ~= MovementMode and now < MovementModeUntil then
        requestedMode = MovementMode
    elseif requestedMode ~= MovementMode then
        MovementMode = requestedMode
        MovementModeUntil = now + Bot.Config.MovementModeHold
    end

    if MovementMode == "APPROACH" then
        Bot.Action = "APPROACH"
        setDesiredMovement(toward)
        return
    end

    if MovementMode == "RETREAT" then
        Bot.Action = targetBlocking and "RESET VS BLOCK" or "RETREAT"
        setDesiredMovement(-toward)
        return
    end

    if now >= NextStrafeSwap then
        StrafeSide = -StrafeSide
        NextStrafeSwap = now + 0.72 + math.random() * 0.30
    end

    local right = Vector3.new(-toward.Z, 0, toward.X)
    local pressure = toward * ((CurrentProfile and CurrentProfile.Style == "Ranged") and 0.07 or 0.18)
    local strafe = right * StrafeSide
    local movement = strafe + pressure

    if movement.Magnitude > 0.001 then
        movement = movement.Unit
    end

    MovementMode = "STRAFE"
    Bot.Action = "PRESSURE / STRAFE"
    setDesiredMovement(movement)
end

local function updateCamera()
    if not Bot.Enabled or not Bot.Config.AutoCamera then
        return
    end

    if not Root or not Root.Parent then
        return
    end

    local now = os.clock()
    if now - LastCameraUpdate < Bot.Config.CameraUpdateRate then
        return
    end
    LastCameraUpdate = now

    local camera = Workspace.CurrentCamera
    if not camera then
        return
    end

    local position = camera.CFrame.Position
    local focus

    if CameraOverrideDirection and now < CameraOverrideUntil then
        local direction = horizontal(CameraOverrideDirection)
        if direction.Magnitude > 0.001 then
            focus = position + direction.Unit * 55 + Vector3.new(0, 1.1, 0)
        end
    elseif CameraOverrideDirection then
        CameraOverrideDirection = nil
        CameraOverrideUntil = 0
    end

    if not focus then
        if not TargetRoot or not TargetRoot.Parent then
            return
        end
        local predicted = TargetRoot.Position + TargetRoot.AssemblyLinearVelocity * Bot.Config.CameraLead
        focus = predicted + Vector3.new(0, 1.35, 0)
    end

    local delta = focus - position
    if delta.Magnitude <= 0.001 then
        return
    end

    local desired = CFrame.lookAt(position, focus, Vector3.yAxis)
    local alpha = math.clamp(Bot.Config.CameraSmoothing, 0.05, 1)
    camera.CFrame = camera.CFrame:Lerp(desired, alpha)
end

local function processInputState(now)
    if MouseDown and now >= MouseReleaseAt then
        releaseMouse()
    end

    if Blocking and now >= BlockUntil then
        releaseKey(Enum.KeyCode.F)
        Blocking = false
        BlockUntil = 0
    end
end

local function updateHud(now)
    if not VibeUI or now - LastHudUpdate < Bot.Config.UIRate then
        return
    end
    LastHudUpdate = now

    local targetName = Bot.Target and Bot.Target.Parent and Bot.Target.Name or "NONE"
    local profile = CurrentProfile or getCharacterProfile()
    local s = Bot.Stats

    pcall(function()
        if StatusLabel then
            StatusLabel:Set("State: " .. tostring(Bot.Action))
        end
        if TargetLabel then
            if targetName ~= "NONE" and TargetDistance < math.huge then
                TargetLabel:Set(string.format("Target: %s | %.1f studs", targetName, TargetDistance))
            else
                TargetLabel:Set("Target: NONE")
            end
        end
        if CharacterLabel then
            CharacterLabel:Set(string.format(
                "Character: %s | %s",
                profile.Name or tostring(CharacterKey or "Unknown"),
                profile.Style or "Hybrid"
            ))
        end
        if ThreatLabel then
            local threatName = Threat.Model and Threat.Model.Parent and Threat.Model.Name or "NONE"
            local threatSource = now <= Threat.Until and Threat.Source or "NONE"
            if Threat.Ultimate and Threat.UltimateName ~= "" then
                threatSource = "ULT: " .. Threat.UltimateName
            end
            ThreatLabel:Set(string.format(
                "Threat: %d | %s | %s | %.0f studs",
                now <= Threat.Until and Threat.Level or 0,
                threatSource,
                threatName,
                Threat.Distance < math.huge and Threat.Distance or 0
            ))
        end
        if PerfLabel then
            PerfLabel:Set(string.format(
                "Logic: %.3f ms avg | targets %d | anim %d | threats %d | watching %d",
                Perf.CombatAvgMs,
                Perf.TargetScans,
                Perf.AnimationEvents,
                Perf.ThreatEvents,
                Perf.ObservedPlayers
            ))
        end
        if StatsLabel then
            StatsLabel:Set(string.format(
                "M1 %d | Skills %d | Blocks %d | Dodges %d | Counters %d | Ults %d",
                s.M1,
                s.Skills,
                s.Blocks,
                s.Dodges,
                s.Counters,
                s.Ultimates
            ))
        end
    end)
end

local function bindCharacter(character)
    disconnectList(CharacterConnections)
    clearTarget()
    cleanupFacing()
    releaseKey(Enum.KeyCode.F)
    releaseKey(Enum.KeyCode.Q)
    releaseMouse()

    Character = character
    Humanoid = nil
    Root = nil
    CharacterKey = nil
    CurrentProfile = nil
    LastHealth = 100
    Blocking = false
    BlockUntil = 0

    if not character then
        return
    end

    Humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
    Root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)

    if not Humanoid or not Root then
        return
    end

    CharacterKey = character:GetAttribute("Character")
    CurrentProfile = getCharacterProfile()
    LastHealth = Humanoid.Health

    addConnection(CharacterConnections, character:GetAttributeChangedSignal("Character"):Connect(function()
        CharacterKey = character:GetAttribute("Character")
        CurrentProfile = getCharacterProfile()
        bindHotbar()
    end))

    addConnection(CharacterConnections, Humanoid.HealthChanged:Connect(function(health)
        if health < LastHealth - 0.05 then
            raiseHitThreat()
        end
        LastHealth = health
    end))

    addConnection(CharacterConnections, Humanoid.Died:Connect(function()
        Bot.Action = "DEAD"
        setDesiredMovement(Vector3.zero)
        clearTarget()
        cleanupFacing()
    end))

    task.defer(bindHotbar)
end

local function combatStep()
    if not Bot.Enabled then
        return
    end

    local start = os.clock()
    local now = start

    processInputState(now)

    if now - LastDecision < Bot.Config.DecisionRate then
        updateHud(now)
        return
    end
    LastDecision = now

    if not Character or not Character.Parent or not Humanoid or Humanoid.Health <= 0 or not Root or not Root.Parent then
        Bot.Action = "NO CHARACTER"
        setDesiredMovement(Vector3.zero)
        updateHud(now)
        return
    end

    local activeThreat = detectThreat(now)

    if activeThreat and activeThreat.Ultimate then
        if fleeUltimate(activeThreat, now) then
            updateHud(now)
            return
        end
    end

    if not canAct() then
        updateHud(now)
        return
    end

    if Blocking then
        updateHud(now)
        return
    end

    if activeThreat and defend(activeThreat) then
        updateHud(now)
        return
    end

    local target = refreshTarget(now, false)
    if not target or not TargetRoot or not TargetHumanoid then
        Bot.Action = activeThreat and ("EVADE: " .. activeThreat.Source) or "IDLE"
        setDesiredMovement(Vector3.zero)
        updateHud(now)
        return
    end

    TargetDistance = (TargetRoot.Position - Root.Position).Magnitude
    moveCombat(now)

    if useUltimateIfReady(now) then
        updateHud(now)
        return
    end

    local combo = tonumber(Character:GetAttribute("Combo")) or 0
    local targetRagdolled = target:GetAttribute("Ragdoll") == true
    local targetBlocking = target:GetAttribute("Blocking") == true

    if TargetDistance <= Bot.Config.M1Range
        and combo <= 1
        and not targetRagdolled
        and not targetBlocking then
        if doM1(TargetDistance, target) then
            updateHud(now)
            return
        end
    end

    if chooseOffensiveSkill(TargetDistance, target) then
        updateHud(now)
        return
    end

    if combo < Bot.Config.M1ComboLimit then
        doM1(TargetDistance, target)
    end

    local elapsed = (os.clock() - start) * 1000
    Perf.CombatSamples += 1
    Perf.CombatTotalMs += elapsed
    if Perf.CombatSamples >= 90 then
        Perf.CombatAvgMs = Perf.CombatTotalMs / Perf.CombatSamples
        Perf.CombatSamples = 0
        Perf.CombatTotalMs = 0
    end

    updateHud(now)
end

function Bot.SetEnabled(state)
    Bot.Enabled = state ~= false

    if not Bot.Enabled then
        Bot.Action = "DISABLED"
        setDesiredMovement(Vector3.zero)
        MovementOverrideDirection = nil
        MovementOverrideUntil = 0
        SmoothedMoveDirection = Vector3.zero
        MovementMode = "IDLE"
        MovementModeUntil = 0
        CameraOverrideDirection = nil
        CameraOverrideUntil = 0

        if Humanoid then
            Humanoid:Move(Vector3.zero, false)
            Humanoid.AutoRotate = true
        end

        releaseKey(Enum.KeyCode.F)
        releaseKey(Enum.KeyCode.Q)
        releaseMouse()
        Blocking = false
        cleanupFacing()
    else
        Bot.Action = "IDLE"
    end

    updateHud(os.clock())
end

local function makeUI()
    local url = "https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"
    local loader = loadstring(game:HttpGet(url))
    assert(type(loader) == "function", "Failed to compile VibeUI")
    VibeUI = loader()
    assert(type(VibeUI) == "table", "VibeUI did not return a table")

    Window = VibeUI:Window({
        Title = "TSB Auto Combat " .. Bot.Version,
        Keybind = Enum.KeyCode.RightControl,
        Size = UDim2.fromOffset(760, 560)
    })

    local CombatTab = Window:Tab({Name = "Combat", Columns = 2})
    local Main = CombatTab:Section({Name = "Automation", Side = 1})
    local Defense = CombatTab:Section({Name = "Defense", Side = 1})
    local Movement = CombatTab:Section({Name = "Movement", Side = 2})
    local Tuning = CombatTab:Section({Name = "Tuning", Side = 2})

    Main:Toggle({
        Name = "Auto Combat",
        Flag = "TSB_Enabled",
        Default = Bot.Enabled,
        Info = "Master combat loop. Right Ctrl toggles the VibeUI window.",
        InfoType = "tip",
        Callback = function(value)
            Bot.SetEnabled(value)
        end
    })

    Main:Toggle({
        Name = "Auto M1",
        Flag = "TSB_AutoM1",
        Default = Bot.Config.AutoM1,
        Callback = function(value)
            Bot.Config.AutoM1 = value
        end
    })

    Main:Toggle({
        Name = "Auto Skills",
        Flag = "TSB_AutoSkills",
        Default = Bot.Config.AutoSkills,
        Callback = function(value)
            Bot.Config.AutoSkills = value
        end
    })

    Main:Toggle({
        Name = "Auto Ultimate",
        Flag = "TSB_AutoUltimate",
        Default = Bot.Config.AutoUltimate,
        Callback = function(value)
            Bot.Config.AutoUltimate = value
        end
    })

    Defense:Toggle({
        Name = "Auto Defense",
        Flag = "TSB_AutoDefense",
        Default = Bot.Config.AutoDefense,
        Callback = function(value)
            Bot.Config.AutoDefense = value
        end
    })

    Defense:Toggle({
        Name = "Counter Priority",
        Flag = "TSB_CounterPriority",
        Default = Bot.Config.CounterPriority,
        Info = "Uses character counter moves first on high-confidence skill threats.",
        InfoType = "info",
        Callback = function(value)
            Bot.Config.CounterPriority = value
        end
    })

    Defense:Toggle({
        Name = "Multi-Threat Awareness",
        Flag = "TSB_MultiThreatAwareness",
        Default = Bot.Config.MultiThreatAwareness,
        Info = "Observes every player character for attacks instead of only the selected combat target.",
        InfoType = "tip",
        Callback = function(value)
            Bot.Config.MultiThreatAwareness = value
        end
    })

    Defense:Toggle({
        Name = "Flee Enemy Ultimates",
        Flag = "TSB_FleeEnemyUltimates",
        Default = Bot.Config.FleeEnemyUltimates,
        Info = "Uses TSB's UsedUltimate/JustUlted/UltimateTime attributes to keep distance from awakened players.",
        InfoType = "warning",
        Callback = function(value)
            Bot.Config.FleeEnemyUltimates = value
        end
    })


    Defense:Slider({
        Name = "Threat Radius",
        Flag = "TSB_ThreatRadius",
        Min = 8,
        Max = 40,
        Default = Bot.Config.ThreatRadius,
        Decimals = 1,
        Suffix = " studs",
        Callback = function(value)
            Bot.Config.ThreatRadius = value
        end
    })

    Defense:Slider({
        Name = "Ranged Threat Radius",
        Flag = "TSB_GlobalThreatRadius",
        Min = 40,
        Max = 180,
        Default = Bot.Config.GlobalThreatRadius,
        Decimals = 1,
        Suffix = " studs",
        Callback = function(value)
            Bot.Config.GlobalThreatRadius = value
        end
    })

    Defense:Slider({
        Name = "Ultimate Danger Radius",
        Flag = "TSB_UltimateDangerRadius",
        Min = 60,
        Max = 220,
        Default = Bot.Config.UltimateDangerRadius,
        Decimals = 1,
        Suffix = " studs",
        Callback = function(value)
            Bot.Config.UltimateDangerRadius = value
        end
    })


    Defense:Slider({
        Name = "Block Hold",
        Flag = "TSB_BlockDuration",
        Min = 0.10,
        Max = 0.45,
        Default = Bot.Config.BlockDuration,
        Decimals = 0.01,
        Suffix = "s",
        Callback = function(value)
            Bot.Config.BlockDuration = value
        end
    })

    Movement:Toggle({
        Name = "Auto Movement",
        Flag = "TSB_AutoMovement",
        Default = Bot.Config.AutoMovement,
        Callback = function(value)
            Bot.Config.AutoMovement = value
            if not value then
                setDesiredMovement(Vector3.zero)
                cleanupFacing()
                if Humanoid then
                    Humanoid.AutoRotate = true
                end
            end
        end
    })

    Movement:Toggle({
        Name = "Auto Camera",
        Flag = "TSB_AutoCamera",
        Default = Bot.Config.AutoCamera,
        Callback = function(value)
            Bot.Config.AutoCamera = value
        end
    })

    Movement:Toggle({
        Name = "Auto Jump",
        Flag = "TSB_AutoJump",
        Default = Bot.Config.AutoJump,
        Callback = function(value)
            Bot.Config.AutoJump = value
        end
    })

    Movement:Slider({
        Name = "Camera Update Rate",
        Flag = "TSB_CameraHz",
        Min = 30,
        Max = 144,
        Default = math.floor(1 / Bot.Config.CameraUpdateRate + 0.5),
        Decimals = 1,
        Suffix = " Hz",
        Callback = function(value)
            Bot.Config.CameraUpdateRate = 1 / math.max(1, value)
        end
    })

    Movement:Slider({
        Name = "Movement Update Rate",
        Flag = "TSB_MovementHz",
        Min = 30,
        Max = 120,
        Default = math.floor(1 / Bot.Config.MovementUpdateRate + 0.5),
        Decimals = 1,
        Suffix = " Hz",
        Callback = function(value)
            Bot.Config.MovementUpdateRate = 1 / math.max(1, value)
        end
    })

    Movement:Slider({
        Name = "Movement Smoothing",
        Flag = "TSB_MovementSmoothing",
        Min = 0.10,
        Max = 1.00,
        Default = Bot.Config.MovementSmoothing,
        Decimals = 0.01,
        Callback = function(value)
            Bot.Config.MovementSmoothing = value
        end
    })


    Movement:Slider({
        Name = "Target Radius",
        Flag = "TSB_TargetRadius",
        Min = 20,
        Max = 250,
        Default = Bot.Config.TargetRadius,
        Decimals = 1,
        Suffix = " studs",
        Callback = function(value)
            Bot.Config.TargetRadius = value
        end
    })

    Tuning:Slider({
        Name = "Decision Rate",
        Flag = "TSB_DecisionHz",
        Min = 15,
        Max = 60,
        Default = math.floor(1 / Bot.Config.DecisionRate + 0.5),
        Decimals = 1,
        Suffix = " Hz",
        Callback = function(value)
            Bot.Config.DecisionRate = 1 / math.max(1, value)
        end
    })

    Tuning:Slider({
        Name = "Target Scan Rate",
        Flag = "TSB_TargetScanRate",
        Min = 0.05,
        Max = 0.50,
        Default = Bot.Config.TargetScanRate,
        Decimals = 0.01,
        Suffix = "s",
        Callback = function(value)
            Bot.Config.TargetScanRate = value
        end
    })

    Tuning:Slider({
        Name = "M1 Interval",
        Flag = "TSB_M1Interval",
        Min = 0.06,
        Max = 0.20,
        Default = Bot.Config.M1Interval,
        Decimals = 0.005,
        Suffix = "s",
        Callback = function(value)
            Bot.Config.M1Interval = value
        end
    })

    Tuning:Slider({
        Name = "Skill Interval",
        Flag = "TSB_SkillInterval",
        Min = 0.10,
        Max = 0.70,
        Default = Bot.Config.SkillInterval,
        Decimals = 0.01,
        Suffix = "s",
        Callback = function(value)
            Bot.Config.SkillInterval = value
        end
    })

    local InfoTab = Window:Tab({Name = "Info", Columns = 1})
    local Status = InfoTab:Section({Name = "Live Status", Side = 1})
    local Details = InfoTab:Section({Name = "Performance", Side = 1})

    StatusLabel = Status:Label("State: IDLE")
    TargetLabel = Status:Label("Target: NONE")
    CharacterLabel = Status:Label("Character: Unknown")
    ThreatLabel = Status:Label("Threat: 0 | NONE")

    PerfLabel = Details:Label("Logic: 0.000 ms avg")
    StatsLabel = Details:Label("M1 0 | Skills 0 | Blocks 0 | Dodges 0 | Counters 0 | Ults 0")
    Details:Paragraph({
        Name = "Optimization",
        Content = "Threat detection is event-driven across every observed player: AnimationPlayed + attack/ultimate attributes, with no GetPlayingAnimationTracks polling. Enemy ultimate windows are tracked from UsedUltimate/JustUlted/UltimateTime, ranged skills can trigger defense without target-lock, and movement uses hysteresis + direction smoothing to avoid micro-jitter."
    })

    VibeUI:CreateSettingsPage(Window)
    Bot.UI = {Library = VibeUI, Window = Window}

    VibeUI:Notification({
        Title = "TSB Auto Combat",
        Description = "Loaded " .. Bot.Version .. " with global threat awareness, ultimate escape, and stabilized movement.",
        Type = "success",
        Duration = 4
    })
end

function Bot.Stop()
    Bot.Enabled = false
    Bot.Action = "STOPPED"
    setDesiredMovement(Vector3.zero)
    MovementOverrideDirection = nil
    MovementOverrideUntil = 0
    SmoothedMoveDirection = Vector3.zero
    CameraOverrideDirection = nil
    CameraOverrideUntil = 0

    pcall(function()
        RunService:UnbindFromRenderStep(RenderBindName)
    end)

    pcall(function()
        RunService:UnbindFromRenderStep(MovementBindName)
    end)

    disconnectList(Bot.Connections)
    disconnectList(CharacterConnections)
    disconnectList(TargetConnections)
    disconnectList(HotbarConnections)
    disconnectList(LiveConnections)
    for model in pairs(ThreatConnectionsByModel) do
        disconnectThreatModel(model)
    end

    if Humanoid then
        pcall(function()
            Humanoid:Move(Vector3.zero, false)
            Humanoid.AutoRotate = true
        end)
    end

    releaseKey(Enum.KeyCode.F)
    releaseKey(Enum.KeyCode.Q)
    releaseMouse()
    cleanupFacing()

    if VibeUI then
        pcall(function()
            VibeUI:Unload()
        end)
    end
end

bindLiveFolder(Workspace:FindFirstChild("Live"))
bindCharacter(LocalPlayer.Character)
makeUI()

addConnection(Bot.Connections, Workspace.ChildAdded:Connect(function(child)
    if child.Name == "Live" and child:IsA("Folder") then
        bindLiveFolder(child)
    end
end))

addConnection(Bot.Connections, LocalPlayer.CharacterAdded:Connect(function(character)
    task.defer(function()
        bindCharacter(character)
    end)
end))

addConnection(Bot.Connections, RunService.Heartbeat:Connect(combatStep))

pcall(function()
    RunService:UnbindFromRenderStep(MovementBindName)
end)
RunService:BindToRenderStep(MovementBindName, Enum.RenderPriority.Last.Value - 1, applyMovement)

pcall(function()
    RunService:UnbindFromRenderStep(RenderBindName)
end)
RunService:BindToRenderStep(RenderBindName, Enum.RenderPriority.Camera.Value + 1, updateCamera)

print("[TSB AutoCombat] v" .. Bot.Version .. " enabled | global event-driven threats + ultimate escape + smoothed movement + VibeUI")
