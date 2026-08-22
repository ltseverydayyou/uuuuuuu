local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayerCharacter = Remotes:WaitForChild("PlayerCharacter")

local ENV = getgenv()
if ENV.DuelingAutoEverything and ENV.DuelingAutoEverything.Cleanup then
    pcall(ENV.DuelingAutoEverything.Cleanup)
end

local State = {
    Alive = true,
    Connections = {},
    EnemyRecords = {},
    CurrentTarget = nil,
    CurrentTargetHandler = nil,
    LastTargetRefresh = 0,
    LastAttack = 0,
    LastEquip = 0,
    LastCritical = 0,
    LastDebugToast = 0,
    ForcedMoveUntil = 0,
    ForcedMoveDirection = Vector3.zero,
    MovementOverride = false,
    BlockHoldUntil = 0,
    ParryToken = 0,
    AttackCounter = 0,
    LocalHandler = nil,
    LocalParryConnection = nil,
    ImpactDefenseToken = 0,
    DefenseBusyUntil = 0,
    AntiParryUntil = 0,
    AntiParryAttacker = nil,
    AntiParryRetreatPoint = nil,
    AntiParryToken = 0,
    LastQueuedAttackAt = 0,
    LastQueuedAttackTarget = nil,
    LastParryStaggerAction = nil,
}

local function disconnect(conn)
    if conn then
        pcall(function()
            conn:Disconnect()
        end)
    end
end

local function keep(conn)
    State.Connections[#State.Connections + 1] = conn
    return conn
end

local oldIdentity = getthreadidentity and getthreadidentity() or nil
if setthreadidentity then
    pcall(setthreadidentity, 2)
end

local GameManager = require(ReplicatedStorage:WaitForChild("GameManager"))
local CharacterController = GameManager:GetController("CharacterController")
local TargetLockController = GameManager:GetController("TargetLockController")
local InputController = GameManager:GetController("PlayerInputController")
local MatchController = GameManager:GetController("MatchController")

if setthreadidentity and oldIdentity then
    pcall(setthreadidentity, oldIdentity)
end

local VibeUI = loadstring(game:HttpGet(
    "https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"
))()

local Window = VibeUI:Window({
    Title = "Dueling Grounds • Auto Everything",
    Keybind = Enum.KeyCode.RightControl,
})

local CombatTab = Window:Tab({ Name = "Combat", Columns = 2 })
local DefenseTab = Window:Tab({ Name = "Defense", Columns = 2 })
local MovementTab = Window:Tab({ Name = "Movement", Columns = 2 })
local MiscTab = Window:Tab({ Name = "Misc", Columns = 2 })

local MasterSection = CombatTab:Section({ Name = "Master", Side = 1 })
MasterSection:Toggle({
    Name = "Auto Everything",
    Flag = "DG_Master",
    Default = true,
    Info = "Master switch for target, offense, defense and movement automation.",
    InfoType = "tip",
})
MasterSection:Toggle({
    Name = "Pause In Safe Zone",
    Flag = "DG_PauseSafe",
    Default = true,
})
MasterSection:Toggle({
    Name = "Ignore Safe Zone Targets",
    Flag = "DG_IgnoreSafeTargets",
    Default = true,
})
MasterSection:Toggle({
    Name = "Debug Notifications",
    Flag = "DG_Debug",
    Default = false,
})

local TargetSection = CombatTab:Section({ Name = "Targeting", Side = 1 })
TargetSection:Toggle({
    Name = "Auto Target",
    Flag = "DG_AutoTarget",
    Default = true,
})
TargetSection:Dropdown({
    Name = "Target Priority",
    Flag = "DG_TargetMode",
    Items = { "Nearest", "Lowest Health", "Lowest Posture" },
    Default = "Nearest",
})
TargetSection:Slider({
    Name = "Target Range",
    Flag = "DG_TargetRange",
    Min = 10,
    Max = 250,
    Default = 100,
    Decimals = 1,
    Suffix = " studs",
})

local OffenseSection = CombatTab:Section({ Name = "Offense", Side = 2 })
OffenseSection:Toggle({
    Name = "Auto Equip",
    Flag = "DG_AutoEquip",
    Default = true,
})
OffenseSection:Toggle({
    Name = "Auto Attack",
    Flag = "DG_AutoAttack",
    Default = true,
})
OffenseSection:Dropdown({
    Name = "Attack Mode",
    Flag = "DG_AttackMode",
    Items = { "Smart", "Light", "Heavy", "Mixed" },
    Default = "Smart",
})
OffenseSection:Slider({
    Name = "Attack Range",
    Flag = "DG_AttackRange",
    Min = 3,
    Max = 25,
    Default = 10,
    Decimals = 0.5,
    Suffix = " studs",
})
OffenseSection:Slider({
    Name = "Attack Retry",
    Flag = "DG_AttackRetry",
    Min = 0.02,
    Max = 0.5,
    Default = 0.06,
    Decimals = 0.01,
    Suffix = "s",
})
OffenseSection:Toggle({
    Name = "Auto Critical Strike",
    Flag = "DG_AutoCritical",
    Default = true,
})
OffenseSection:Toggle({
    Name = "Auto Ultimate",
    Flag = "DG_AutoUltimate",
    Default = true,
})

local DefenseMain = DefenseTab:Section({ Name = "Reactive Defense", Side = 1 })
DefenseMain:Toggle({
    Name = "Auto Dodge",
    Flag = "DG_AutoDodge",
    Default = true,
})
DefenseMain:Toggle({
    Name = "Auto Parry",
    Flag = "DG_AutoParry",
    Default = true,
})
DefenseMain:Dropdown({
    Name = "Defense Mode",
    Flag = "DG_DefenseMode",
    Items = { "Hybrid", "Parry", "Dodge" },
    Default = "Hybrid",
})
DefenseMain:Slider({
    Name = "Threat Range",
    Flag = "DG_ThreatRange",
    Min = 4,
    Max = 35,
    Default = 18,
    Decimals = 0.5,
    Suffix = " studs",
})
DefenseMain:Slider({
    Name = "Parry Lead",
    Flag = "DG_ParryLead",
    Min = 20,
    Max = 220,
    Default = 105,
    Decimals = 5,
    Suffix = " ms",
})
DefenseMain:Slider({
    Name = "Block Hold",
    Flag = "DG_BlockHold",
    Min = 100,
    Max = 450,
    Default = 220,
    Decimals = 10,
    Suffix = " ms",
})

local DefenseExtra = DefenseTab:Section({ Name = "Threat Rules", Side = 2 })
DefenseExtra:Toggle({
    Name = "Dodge Heavy Attacks",
    Flag = "DG_DodgeHeavy",
    Default = false,
    Info = "Hybrid mode normally parries regular attacks. Enable to dodge heavies too.",
    InfoType = "info",
})
DefenseExtra:Toggle({
    Name = "Always Dodge Ultimates",
    Flag = "DG_DodgeUltimate",
    Default = true,
})
DefenseExtra:Toggle({
    Name = "React To Off-Target Attackers",
    Flag = "DG_MultiThreat",
    Default = true,
    Info = "Defends against nearby attackers even when they are not your selected target.",
    InfoType = "tip",
})
DefenseExtra:Toggle({
    Name = "Impact Defense Fallback",
    Flag = "DG_ImpactDefense",
    Default = true,
    Info = "Uses the game's incoming impact registration as a last-moment parry/dodge fallback.",
    InfoType = "tip",
})
DefenseExtra:Toggle({
    Name = "Dodge Unknown Attack Animations",
    Flag = "DG_UnknownActionDodge",
    Default = true,
    Info = "If an enemy Action animation is not in its weapon attack map, dodge it instead of ignoring it.",
    InfoType = "info",
})
DefenseExtra:Toggle({
    Name = "Anti-Parry Safety",
    Flag = "DG_AntiParry",
    Default = true,
    Info = "Stops attacking into a fresh enemy parry and defends immediately if they successfully parry you.",
    InfoType = "tip",
})
DefenseExtra:Slider({
    Name = "Fresh Guard Avoid",
    Flag = "DG_FreshGuardAvoid",
    Min = 0.12,
    Max = 0.45,
    Default = 0.28,
    Decimals = 0.01,
    Suffix = "s",
})
DefenseExtra:Slider({
    Name = "Parried Recovery",
    Flag = "DG_ParriedRecovery",
    Min = 0.35,
    Max = 1.5,
    Default = 0.9,
    Decimals = 0.05,
    Suffix = "s",
})
DefenseExtra:Slider({
    Name = "Anti-Parry Retreat",
    Flag = "DG_AntiParryRetreat",
    Min = 3,
    Max = 18,
    Default = 9,
    Decimals = 0.5,
    Suffix = " studs",
})
DefenseExtra:Toggle({
    Name = "Auto Counter After Parry",
    Flag = "DG_AutoCounter",
    Default = true,
})
DefenseExtra:Dropdown({
    Name = "Counter Attack",
    Flag = "DG_CounterAttack",
    Items = { "Light", "Heavy" },
    Default = "Heavy",
})
DefenseExtra:Slider({
    Name = "Counter Delay",
    Flag = "DG_CounterDelay",
    Min = 0,
    Max = 0.4,
    Default = 0.03,
    Decimals = 0.01,
    Suffix = "s",
})

local MovementMain = MovementTab:Section({ Name = "Auto Movement", Side = 1 })
MovementMain:Toggle({
    Name = "Auto Chase",
    Flag = "DG_AutoChase",
    Default = true,
})
MovementMain:Slider({
    Name = "Preferred Distance",
    Flag = "DG_PreferredDistance",
    Min = 3,
    Max = 18,
    Default = 7,
    Decimals = 0.5,
    Suffix = " studs",
})
MovementMain:Toggle({
    Name = "Auto Strafe In Range",
    Flag = "DG_AutoStrafe",
    Default = true,
})
MovementMain:Slider({
    Name = "Strafe Speed",
    Flag = "DG_StrafeScale",
    Min = 0.2,
    Max = 1,
    Default = 0.7,
    Decimals = 0.05,
})

local DodgeMovement = MovementTab:Section({ Name = "Dodge Movement", Side = 2 })
DodgeMovement:Dropdown({
    Name = "Dodge Direction",
    Flag = "DG_DodgeDirection",
    Items = { "Away", "Side", "Random Side" },
    Default = "Away",
})
DodgeMovement:Slider({
    Name = "Dodge Input Hold",
    Flag = "DG_DodgeInputHold",
    Min = 0.05,
    Max = 0.3,
    Default = 0.12,
    Decimals = 0.01,
    Suffix = "s",
})

local MiscSection = MiscTab:Section({ Name = "Utilities", Side = 1 })
MiscSection:Paragraph({
    Name = "Engine",
    Content = "Event-driven attack recognition. Uses equipped-weapon animation IDs and exact impact markers; no GetDescendants/GetPlayingAnimationTracks polling.",
})

local function flag(name, fallback)
    local value = VibeUI.Flags[name]
    if value == nil then
        return fallback
    end
    return value
end

local function notify(title, desc, kind, duration)
    pcall(function()
        VibeUI:Notification({
            Title = title,
            Description = desc,
            Type = kind or "info",
            Duration = duration or 3,
        })
    end)
end

local function debugNotify(text)
    if not flag("DG_Debug", false) then
        return
    end
    if os.clock() - State.LastDebugToast < 0.35 then
        return
    end
    State.LastDebugToast = os.clock()
    notify("Auto Combat", text, "info", 2)
end

local function getLocalHandler()
    local handler = CharacterController:GetLocalCharacterHandler()
    if handler then
        State.LocalHandler = handler
    end
    return State.LocalHandler
end

local function localPaused(handler)
    if not State.Alive or not flag("DG_Master", true) then
        return true
    end
    handler = handler or getLocalHandler()
    if not handler or not handler.OriginalModel or not handler.Root then
        return true
    end
    if handler.OriginalModel:GetAttribute("IsDead") then
        return true
    end
    if flag("DG_PauseSafe", true) and handler.OriginalModel:GetAttribute("InSafeZone") then
        return true
    end
    return false
end

local function isEnemy(handler)
    if not handler or handler.Player == LocalPlayer then
        return false
    end
    local model = handler.OriginalModel
    if not model then
        return false
    end

    local uid = model:GetAttribute("UserId")
    if uid and uid == LocalPlayer.UserId then
        return false
    end

    if MatchController then
        local ok, result = pcall(function()
            return MatchController:IsCharacterEnemyOfLocalPlayer(model)
        end)
        if ok and result ~= nil then
            return result == true
        end
    end

    return true
end

local function modelAlive(model)
    if not model or model.Parent == nil then
        return false
    end
    if model:GetAttribute("IsDead") then
        return false
    end
    local health = model:GetAttribute("Health")
    return health == nil or health > 0
end

local function handlerDistance(a, b)
    if not a or not b or not a.Root or not b.Root then
        return math.huge
    end
    return (a.Root.Position - b.Root.Position).Magnitude
end

local function releaseBlock(handler)
    if not handler or not handler.ActionManager then
        return
    end

    local queue = handler._blockInputQueue
    if queue then
        for i = #queue, 1, -1 do
            local item = queue[i]
            if item.clearedByAction then
                table.remove(queue, i)
            elseif item.state == true then
                item.state = 0.13333333333333333
            end
        end
    end

    local block = handler.ActionManager.BlockAction
    if block then
        block._wantsToRelease = true
    end
end

local function pressParry()
    local handler = getLocalHandler()
    if localPaused(handler) or not flag("DG_AutoParry", true) then
        return false
    end

    local manager = handler.ActionManager
    if not manager then
        return false
    end

    local canBlock = true
    if manager.CanStartBlock then
        local ok, result = pcall(manager.CanStartBlock, manager)
        canBlock = ok and result == true
    end
    if not canBlock then
        return false
    end

    local queue = handler._blockInputQueue
    if not queue then
        return false
    end

    if #queue < 2 and not manager.BlockAction then
        table.insert(queue, { state = true })
    end

    local hold = flag("DG_BlockHold", 220) / 1000
    State.BlockHoldUntil = math.max(State.BlockHoldUntil, os.clock() + hold)
    State.ParryToken += 1
    local token = State.ParryToken

    task.delay(hold, function()
        if not State.Alive then
            return
        end
        if token ~= State.ParryToken and os.clock() < State.BlockHoldUntil then
            return
        end
        if os.clock() >= State.BlockHoldUntil - 0.01 then
            releaseBlock(getLocalHandler())
        end
    end)

    return true
end

local function computeDodgeDirection(attacker)
    local handler = getLocalHandler()
    if not handler or not handler.Root then
        return Vector3.zero
    end

    local mode = flag("DG_DodgeDirection", "Away")
    local root = handler.Root
    local attackerRoot = attacker and attacker.Root
    local away

    if attackerRoot then
        local delta = root.Position - attackerRoot.Position
        away = Vector3.new(delta.X, 0, delta.Z)
    else
        local look = root.CFrame.LookVector
        away = Vector3.new(-look.X, 0, -look.Z)
    end

    if away.Magnitude < 0.001 then
        away = Vector3.new(0, 0, 1)
    else
        away = away.Unit
    end

    if mode == "Side" or mode == "Random Side" then
        local side = Vector3.new(-away.Z, 0, away.X)
        if mode == "Random Side" and math.random() < 0.5 then
            side = -side
        end
        return side
    end

    return away
end

local function dodge(attacker)
    local handler = getLocalHandler()
    if localPaused(handler) or not flag("DG_AutoDodge", true) then
        return false
    end

    local manager = handler.ActionManager
    if not manager then
        return false
    end

    if manager.CanStartDodge then
        local ok, can = pcall(manager.CanStartDodge, manager)
        if not ok or not can then
            return false
        end
    end

    local dir = computeDodgeDirection(attacker)
    local isReverse = false

    if handler.TargetLock or handler.AimingWithCamera then
        local camera = workspace.CurrentCamera
        if camera and camera.CFrame:VectorToObjectSpace(dir).Z > 0.85 then
            isReverse = true
        end
    end

    if manager._clearQueuedAction then
        pcall(manager._clearQueuedAction, manager)
    end
    handler._desiredDodge = nil

    local ok, action = pcall(manager.SwitchToAction, manager, "Dodge", {
        direction = dir,
        isReverse = isReverse,
        dodgeStamina = manager._dodgeStamina,
    })

    return ok and action ~= nil
end

local function attackImpactInfo(attackInfo)
    if type(attackInfo) ~= "table" or type(attackInfo.impacts) ~= "table" then
        return nil, nil
    end

    local earliest = math.huge
    local selected

    for _, impact in pairs(attackInfo.impacts) do
        local marker = impact.markerTime
        if type(marker) == "number" and marker < earliest then
            earliest = marker
            selected = impact
        end
    end

    if earliest == math.huge then
        return nil, nil
    end

    local speed = attackInfo.attackSpeedMultiplier or 1
    if speed <= 0 then
        speed = 1
    end

    return earliest / speed, selected
end

local function normalizeAnimationId(id)
    if not id then
        return nil
    end
    local digits = tostring(id):match("(%d+)")
    return digits
end

local function refreshAttackMap(record)
    if not record or not record.handler then
        return
    end

    record.attackMap = {}

    local ok, weaponHandler = pcall(function()
        return record.handler:GetEquippedWeaponHandler()
    end)
    if not ok or not weaponHandler or not weaponHandler.WeaponInfo then
        return
    end

    local attackTypes = weaponHandler.WeaponInfo.BasicAttackTypes
    if type(attackTypes) ~= "table" then
        return
    end

    for attackName, attackInfo in pairs(attackTypes) do
        local anim = attackInfo.animation
        local animId = anim and normalizeAnimationId(anim.AnimationId)
        if animId then
            local bucket = record.attackMap[animId]
            if not bucket then
                bucket = {}
                record.attackMap[animId] = bucket
            end
            bucket[#bucket + 1] = {
                Name = tostring(attackName),
                Info = attackInfo,
            }
        end
    end
end

local function chooseAttackDefinition(bucket)
    if type(bucket) ~= "table" or #bucket == 0 then
        return nil
    end

    local best
    local bestDelay = math.huge

    for _, def in ipairs(bucket) do
        local delay = attackImpactInfo(def.Info)
        if delay and delay < bestDelay then
            bestDelay = delay
            best = def
        end
    end

    return best or bucket[1]
end

local function shouldReactTo(record)
    if not record or not record.handler or not isEnemy(record.handler) then
        return false
    end
    local localHandler = getLocalHandler()
    if localPaused(localHandler) then
        return false
    end
    if not modelAlive(record.handler.OriginalModel) then
        return false
    end

    if not flag("DG_MultiThreat", true) and State.CurrentTargetHandler ~= record.handler then
        return false
    end

    return handlerDistance(localHandler, record.handler) <= flag("DG_ThreatRange", 18)
end

local function scheduleDefense(record, attackDef)
    if not attackDef or not attackDef.Info then
        return
    end

    local impactDelay, impactEntry = attackImpactInfo(attackDef.Info)
    if not impactDelay then
        return
    end

    local name = attackDef.Name or ""
    local lowerName = string.lower(name)
    local impactWeight = impactEntry
        and impactEntry.impactInfo
        and impactEntry.impactInfo.weight
    local isHeavy = impactWeight == "Heavy" or string.find(lowerName, "heavy", 1, true) ~= nil
    local isUltimate = string.find(lowerName, "ultimate", 1, true) ~= nil

    local lead = flag("DG_ParryLead", 105) / 1000
    local delay = math.max(0, impactDelay - lead)

    task.delay(delay, function()
        if not State.Alive or not shouldReactTo(record) then
            return
        end

        State.DefenseBusyUntil = math.max(State.DefenseBusyUntil, os.clock() + 0.35)

        local mode = flag("DG_DefenseMode", "Hybrid")
        local acted = false

        if isUltimate and flag("DG_DodgeUltimate", true) and flag("DG_AutoDodge", true) then
            acted = dodge(record.handler)
        elseif mode == "Dodge" then
            acted = dodge(record.handler)
        elseif mode == "Parry" then
            acted = pressParry()
            if not acted and flag("DG_AutoDodge", true) then
                acted = dodge(record.handler)
            end
        else
            if isHeavy and flag("DG_DodgeHeavy", false) and flag("DG_AutoDodge", true) then
                acted = dodge(record.handler)
            else
                acted = pressParry()
                if not acted and flag("DG_AutoDodge", true) then
                    acted = dodge(record.handler)
                end
            end
        end

        if acted then
            debugNotify(
                string.format("%s: %s (impact %.0fms)",
                    isUltimate and "ULT dodge" or (isHeavy and "Heavy defense" or "Defense"),
                    name,
                    impactDelay * 1000
                )
            )
        end
    end)
end

local function applyImpactDefense(impactData)
    if not State.Alive
        or not flag("DG_Master", true)
        or not flag("DG_ImpactDefense", true)
    then
        return false
    end

    local handler = getLocalHandler()
    if localPaused(handler) or not handler then
        return false
    end

    local autoParry = flag("DG_AutoParry", true)
    local autoDodge = flag("DG_AutoDodge", true)
    if not autoParry and not autoDodge then
        return false
    end

    local sourceName = ""
    if type(impactData) == "table" and impactData.sourceModule then
        sourceName = string.lower(tostring(impactData.sourceModule.Name or impactData.sourceModule))
    end

    local mode = flag("DG_DefenseMode", "Hybrid")
    local isUltimate = string.find(sourceName, "ultimate", 1, true) ~= nil
    local isHeavy = string.find(sourceName, "heavy", 1, true) ~= nil
    local useDodge = false

    if isUltimate and flag("DG_DodgeUltimate", true) and autoDodge then
        useDodge = true
    elseif mode == "Dodge" then
        useDodge = autoDodge
    elseif mode == "Parry" then
        useDodge = not autoParry and autoDodge
    elseif isHeavy and flag("DG_DodgeHeavy", false) and autoDodge then
        useDodge = true
    elseif not autoParry and autoDodge then
        useDodge = true
    end

    State.DefenseBusyUntil = math.max(State.DefenseBusyUntil, os.clock() + 0.3)
    handler._desiredQueuedAction = nil
    handler._desiredQueuedActionDuration = nil

    State.ImpactDefenseToken += 1
    local token = State.ImpactDefenseToken

    if useDodge then
        handler.IsDodging = true
    else
        handler.IsParrying = true
    end

    task.delay(0.09, function()
        if not State.Alive or token ~= State.ImpactDefenseToken then
            return
        end

        local current = getLocalHandler()
        if current ~= handler then
            return
        end

        if useDodge then
            local action = handler.ActionManager and handler.ActionManager.CurrentAction
            if not (action and action.ActionType == "Dodge" and action.Started) then
                handler.IsDodging = nil
            end
        else
            local block = handler.ActionManager and handler.ActionManager.BlockAction
            if not (block and block.Started) then
                handler.IsParrying = false
            end
        end
    end)

    debugNotify(useDodge and "Impact dodge" or "Impact parry")
    return true
end

local function cancelQueuedOffense(handler)
    handler = handler or getLocalHandler()
    if not handler then
        return
    end

    handler._desiredQueuedAction = nil
    handler._desiredQueuedActionDuration = nil

    local manager = handler.ActionManager
    if manager and manager._clearQueuedAction then
        pcall(manager._clearQueuedAction, manager)
    end
end

local function isParryStaggerAction(action)
    if not action or action.ActionType ~= "Stagger" then
        return false
    end

    local properties = action.Properties
    local staggerType = properties and properties.staggerType
    if staggerType and string.find(string.lower(tostring(staggerType)), "parry", 1, true) then
        return true
    end

    return false
end

local function recordInFreshParryWindow(record)
    if not flag("DG_AntiParry", true) or not record then
        return false
    end

    local now = os.clock()
    return now < (record.guardDangerUntil or 0)
        or now < (record.parryPunishUntil or 0)
end

local function beginAntiParryRecovery(record, reason)
    if not State.Alive or not flag("DG_AntiParry", true) then
        return
    end

    local handler = getLocalHandler()
    if localPaused(handler) or not handler then
        return
    end

    local attacker = record and record.handler or State.LastQueuedAttackTarget or State.CurrentTargetHandler
    local now = os.clock()
    local recovery = flag("DG_ParriedRecovery", 0.9)

    State.AntiParryUntil = math.max(State.AntiParryUntil, now + recovery)
    State.AntiParryAttacker = attacker
    State.DefenseBusyUntil = math.max(State.DefenseBusyUntil, State.AntiParryUntil)

    if record then
        record.parryPunishUntil = math.max(record.parryPunishUntil or 0, State.AntiParryUntil)
    end

    cancelQueuedOffense(handler)

    if handler.Root and attacker and attacker.Root then
        local away = handler.Root.Position - attacker.Root.Position
        away = Vector3.new(away.X, 0, away.Z)
        if away.Magnitude > 0.001 then
            State.AntiParryRetreatPoint = handler.Root.Position
                + away.Unit * flag("DG_AntiParryRetreat", 9)
        end
    end

    State.AntiParryToken += 1
    local token = State.AntiParryToken

    task.spawn(function()
        while State.Alive
            and token == State.AntiParryToken
            and os.clock() < State.AntiParryUntil
        do
            local current = getLocalHandler()
            if localPaused(current) or current ~= handler then
                return
            end

            cancelQueuedOffense(current)

            local manager = current.ActionManager
            local action = manager and manager.CurrentAction

            if isParryStaggerAction(action) then
                local acted = false

                if flag("DG_AutoParry", true) then
                    acted = pressParry()
                end

                if not acted and flag("DG_AutoDodge", true) then
                    acted = dodge(attacker)
                end

                if acted then
                    State.DefenseBusyUntil = math.max(State.DefenseBusyUntil, os.clock() + 0.4)
                    return
                end
            elseif action and action.ActionType == "BasicAttack" and action.CanCancel then
                if flag("DG_AutoDodge", true) and dodge(attacker) then
                    State.DefenseBusyUntil = math.max(State.DefenseBusyUntil, os.clock() + 0.4)
                    return
                end
            elseif not action then
                local acted = false

                if flag("DG_AutoParry", true) then
                    acted = pressParry()
                end

                if not acted and flag("DG_AutoDodge", true) then
                    acted = dodge(attacker)
                end

                if acted then
                    State.DefenseBusyUntil = math.max(State.DefenseBusyUntil, os.clock() + 0.4)
                    return
                end
            end

            task.wait(0.025)
        end
    end)

    debugNotify("Anti-parry: " .. tostring(reason or "enemy parry"))
end

local function markFreshEnemyGuard(record)
    if not record or not flag("DG_AntiParry", true) then
        return
    end

    local now = os.clock()
    local avoid = flag("DG_FreshGuardAvoid", 0.28)
    record.guardStartedAt = now
    record.guardDangerUntil = math.max(record.guardDangerUntil or 0, now + avoid)

    local localHandler = getLocalHandler()
    local recentlyAttacked = State.LastQueuedAttackTarget == record.handler
        and now - State.LastQueuedAttackAt <= 0.8
    local selected = State.CurrentTargetHandler == record.handler

    if (recentlyAttacked or selected)
        and localHandler
        and handlerDistance(localHandler, record.handler) <= flag("DG_AttackRange", 10) + 4
    then
        cancelQueuedOffense(localHandler)
        State.DefenseBusyUntil = math.max(State.DefenseBusyUntil, record.guardDangerUntil)

        local action = localHandler.ActionManager and localHandler.ActionManager.CurrentAction
        if action
            and action.ActionType == "BasicAttack"
            and action.CanCancel
            and flag("DG_AutoDodge", true)
        then
            dodge(record.handler)
        end

        debugNotify("Avoiding fresh enemy parry")
    end
end

local function enemyParryLikelyOurs(record)
    if not record or not record.handler then
        return false
    end

    local handler = getLocalHandler()
    if not handler then
        return false
    end

    local action = handler.ActionManager and handler.ActionManager.CurrentAction
    if isParryStaggerAction(action) then
        return true
    end

    local now = os.clock()
    return State.LastQueuedAttackTarget == record.handler
        and now - State.LastQueuedAttackAt <= 1.1
        and handlerDistance(handler, record.handler) <= flag("DG_AttackRange", 10) + 6
end

local function pollLocalParryStagger()
    if not flag("DG_AntiParry", true) then
        State.LastParryStaggerAction = nil
        return
    end

    local handler = getLocalHandler()
    local action = handler and handler.ActionManager and handler.ActionManager.CurrentAction

    if action == State.LastParryStaggerAction then
        return
    end

    if isParryStaggerAction(action) then
        State.LastParryStaggerAction = action

        local attacker = State.LastQueuedAttackTarget or State.CurrentTargetHandler
        local record = attacker and State.EnemyRecords[attacker] or nil
        beginAntiParryRecovery(record, "you were parried")
    elseif not action then
        State.LastParryStaggerAction = nil
    end
end

local function untrackEnemy(handler)
    local record = State.EnemyRecords[handler]
    if not record then
        return
    end

    for _, conn in ipairs(record.connections) do
        disconnect(conn)
    end

    State.EnemyRecords[handler] = nil

    if State.CurrentTargetHandler == handler then
        State.CurrentTarget = nil
        State.CurrentTargetHandler = nil
    end
end

local function trackEnemy(handler)
    if not State.Alive or not handler or State.EnemyRecords[handler] or not isEnemy(handler) then
        return
    end

    local record = {
        handler = handler,
        model = handler.OriginalModel,
        attackMap = {},
        connections = {},
        guardStartedAt = 0,
        guardDangerUntil = 0,
        parryPunishUntil = 0,
    }
    State.EnemyRecords[handler] = record

    refreshAttackMap(record)

    if handler.EquippedWeaponChanged and handler.EquippedWeaponChanged.Connect then
        record.connections[#record.connections + 1] = handler.EquippedWeaponChanged:Connect(function()
            task.defer(refreshAttackMap, record)
        end)
    end

    local model = record.model
    if model then
        if model:GetAttribute("IsBlocking") then
            markFreshEnemyGuard(record)
        end

        record.connections[#record.connections + 1] = model:GetAttributeChangedSignal("IsBlocking"):Connect(function()
            if model:GetAttribute("IsBlocking") then
                markFreshEnemyGuard(record)
            end
        end)

        record.connections[#record.connections + 1] = model:GetAttributeChangedSignal("ParriedEvent"):Connect(function()
            if enemyParryLikelyOurs(record) then
                beginAntiParryRecovery(record, "enemy landed a parry")
            end
        end)
    end

    if handler.Animator and handler.Animator.AnimationPlayed then
        record.connections[#record.connections + 1] = handler.Animator.AnimationPlayed:Connect(function(track)
            if not State.Alive or not shouldReactTo(record) then
                return
            end

            local anim = track and track.Animation
            local id = anim and normalizeAnimationId(anim.AnimationId)
            if not id then
                return
            end

            local bucket = record.attackMap[id]
            if not bucket then
                refreshAttackMap(record)
                bucket = record.attackMap[id]
            end

            local attackDef = chooseAttackDefinition(bucket)
            if attackDef then
                scheduleDefense(record, attackDef)
            elseif flag("DG_UnknownActionDodge", true)
                and flag("DG_AutoDodge", true)
                and track
                and track.Priority == Enum.AnimationPriority.Action
            then
                local now = os.clock()
                if now - (record.lastUnknownDefense or 0) >= 0.14 then
                    record.lastUnknownDefense = now
                    State.DefenseBusyUntil = math.max(State.DefenseBusyUntil, now + 0.32)
                    dodge(record.handler)
                    debugNotify("Unknown Action dodge: " .. tostring(id))
                end
            end
        end)
    end

    if handler.Destroyed and handler.Destroyed.Connect then
        record.connections[#record.connections + 1] = handler.Destroyed:Connect(function()
            untrackEnemy(handler)
        end)
    end
end

local function bindLocalHandler(handler)
    State.LocalHandler = handler

    disconnect(State.LocalParryConnection)
    State.LocalParryConnection = nil

    if not handler or not handler.Parried or not handler.Parried.Connect then
        return
    end

    State.LocalParryConnection = handler.Parried:Connect(function()
        if not State.Alive or localPaused(handler) or not flag("DG_AutoCounter", true) then
            return
        end

        local delay = flag("DG_CounterDelay", 0.03)
        task.delay(delay, function()
            if not State.Alive or localPaused(getLocalHandler()) then
                return
            end

            local h = getLocalHandler()
            if not h then
                return
            end

            local counter = flag("DG_CounterAttack", "Heavy")
            h._desiredQueuedAction = counter == "Heavy" and "HeavyAttack" or "LightAttack"
            h._desiredQueuedActionDuration = nil
            debugNotify("Countered after parry")
        end)
    end)
end

local function targetScore(handler, mode, localHandler)
    local model = handler.OriginalModel
    local dist = handlerDistance(localHandler, handler)

    if mode == "Lowest Health" then
        return model:GetAttribute("Health") or math.huge
    elseif mode == "Lowest Posture" then
        return model:GetAttribute("Posture") or math.huge
    end

    return dist
end

local function selectTarget()
    local localHandler = getLocalHandler()
    if not localHandler or not localHandler.Root then
        return nil
    end

    local maxRange = flag("DG_TargetRange", 100)
    local mode = flag("DG_TargetMode", "Nearest")
    local bestHandler, bestScore

    for handler in pairs(State.EnemyRecords) do
        local model = handler.OriginalModel
        if isEnemy(handler)
            and modelAlive(model)
            and handler.Root
            and handlerDistance(localHandler, handler) <= maxRange
        then
            local safe = model:GetAttribute("InSafeZone")
            if not (flag("DG_IgnoreSafeTargets", true) and safe) then
                local score = targetScore(handler, mode, localHandler)
                if bestScore == nil or score < bestScore then
                    bestScore = score
                    bestHandler = handler
                end
            end
        end
    end

    return bestHandler
end

local function setTarget(handler)
    if State.CurrentTargetHandler == handler then
        return
    end

    State.CurrentTargetHandler = handler
    State.CurrentTarget = handler and handler.Root or nil

    pcall(function()
        TargetLockController:SetForcedTargetLock(State.CurrentTarget)
        TargetLockController:SetTarget(State.CurrentTarget)
    end)

    if handler and handler.Player then
        debugNotify("Target: " .. handler.Player.Name)
    end
end

local function clearForcedTarget()
    pcall(function()
        TargetLockController:SetForcedTargetLock(nil)
    end)
end

local function targetDistance()
    local localHandler = getLocalHandler()
    local target = State.CurrentTargetHandler
    return handlerDistance(localHandler, target)
end

local function tryCritical()
    if not flag("DG_AutoCritical", true) then
        return false
    end

    local critical = TargetLockController.CriticalStrikeTarget
    if not critical or os.clock() - State.LastCritical < 0.35 then
        return false
    end

    local parent = critical.Parent
    if not parent then
        return false
    end

    local localHandler = getLocalHandler()
    local targetHandler = CharacterController:GetCharacterHandler(parent)
    if targetHandler and handlerDistance(localHandler, targetHandler) > flag("DG_AttackRange", 10) + 4 then
        return false
    end

    State.LastCritical = os.clock()
    PlayerCharacter.Request.CriticalStrike:FireServer(parent)
    debugNotify("Critical strike")
    return true
end

local function tryAttack()
    local handler = getLocalHandler()
    local target = State.CurrentTargetHandler

    if localPaused(handler)
        or not flag("DG_AutoAttack", true)
        or not target
        or not target.Root
        or not modelAlive(target.OriginalModel)
    then
        return
    end

    local now = os.clock()
    if now < State.DefenseBusyUntil then
        return
    end

    local record = State.EnemyRecords[target]
    if recordInFreshParryWindow(record)
        or (flag("DG_AntiParry", true)
            and State.AntiParryAttacker == target
            and now < State.AntiParryUntil)
    then
        cancelQueuedOffense(handler)
        return
    end

    if handlerDistance(handler, target) > flag("DG_AttackRange", 10) then
        return
    end

    if tryCritical() then
        return
    end

    if flag("DG_AutoUltimate", true)
        and (handler.OriginalModel:GetAttribute("UltimateEnergy") or 0) >= 100
    then
        handler._desiredQueuedAction = "Ultimate"
        handler._desiredQueuedActionDuration = nil
        State.LastQueuedAttackAt = os.clock()
        State.LastQueuedAttackTarget = target
        return
    end

    local mode = flag("DG_AttackMode", "Smart")
    local desired

    if mode == "Light" then
        desired = "LightAttack"
    elseif mode == "Heavy" then
        desired = "HeavyAttack"
    elseif mode == "Mixed" then
        State.AttackCounter += 1
        desired = State.AttackCounter % 4 == 0 and "HeavyAttack" or "LightAttack"
    else
        local targetBlocking = target.OriginalModel:GetAttribute("IsBlocking")
            or target.OriginalModel:GetAttribute("ClientIsBlocking")
        local targetPosture = target.OriginalModel:GetAttribute("Posture")
        local targetMaxPosture = target.OriginalModel:GetAttribute("MaxPosture")
        if targetBlocking
            or (targetPosture and targetMaxPosture and targetPosture <= targetMaxPosture * 0.3)
        then
            desired = "HeavyAttack"
        else
            desired = "LightAttack"
        end
    end

    handler._desiredQueuedAction = desired
    handler._desiredQueuedActionDuration = nil
    State.LastQueuedAttackAt = os.clock()
    State.LastQueuedAttackTarget = target
end

local function tryEquip()
    local handler = getLocalHandler()
    if localPaused(handler) or not flag("DG_AutoEquip", true) then
        return
    end

    if handler.EquippedWeapon == nil and os.clock() - State.LastEquip >= 0.8 then
        State.LastEquip = os.clock()
        PlayerCharacter.Request.SetEquippedWeapon:FireServer(true)
    end
end

local function updateMovement()
    local handler = getLocalHandler()
    if not handler then
        return
    end

    if localPaused(handler) then
        handler.DesiredMoveTo = nil
        State.MovementOverride = false
        return
    end

    local now = os.clock()
    if flag("DG_AntiParry", true) and now < State.AntiParryUntil then
        local point = State.AntiParryRetreatPoint
        if point and handler.Root then
            handler.DesiredMoveTo = point
            State.MovementOverride = true
            return
        end
    elseif State.AntiParryRetreatPoint then
        State.AntiParryRetreatPoint = nil
        State.AntiParryAttacker = nil
    end

    if not flag("DG_AutoChase", true) then
        handler.DesiredMoveTo = nil
        State.MovementOverride = false
        return
    end

    local target = State.CurrentTargetHandler
    if not target or not target.Root or not handler.Root then
        handler.DesiredMoveTo = nil
        State.MovementOverride = false
        return
    end

    local delta = target.Root.Position - handler.Root.Position
    local flat = Vector3.new(delta.X, 0, delta.Z)
    if flat.Magnitude < 0.01 then
        handler.DesiredMoveTo = nil
        State.MovementOverride = false
        return
    end

    local preferred = flag("DG_PreferredDistance", 7)

    if flat.Magnitude > preferred then
        handler.DesiredMoveTo = target.Root.Position
        State.MovementOverride = true
    elseif flag("DG_AutoStrafe", true) then
        local side = Vector3.new(-flat.Z, 0, flat.X).Unit
        local sign = (math.floor(os.clock() * 1.35) % 2 == 0) and 1 or -1
        local radius = math.max(2, preferred * flag("DG_StrafeScale", 0.7))
        handler.DesiredMoveTo = handler.Root.Position + side * sign * radius
        State.MovementOverride = true
    else
        handler.DesiredMoveTo = nil
        State.MovementOverride = false
    end
end

for _, model in ipairs(CollectionService:GetTagged("CustomCharacter")) do
    local handler = CharacterController:GetCharacterHandler(model)
    if handler and isEnemy(handler) then
        trackEnemy(handler)
    end
end

keep(CharacterController.CharacterLoaded:Connect(function(handler)
    task.defer(trackEnemy, handler)
end))

keep(CharacterController.LocalCharacterLoaded:Connect(function(handler)
    bindLocalHandler(handler)
end))

bindLocalHandler(getLocalHandler())

keep(PlayerCharacter.Update.RegisterImpact.OnClientEvent:Connect(function(_, impactData)
    applyImpactDefense(impactData)
end))

keep(RunService.Heartbeat:Connect(function()
    if not State.Alive then
        return
    end

    local now = os.clock()

    if flag("DG_Master", true) and flag("DG_AutoTarget", true) then
        if now - State.LastTargetRefresh >= 0.12 then
            State.LastTargetRefresh = now
            local selected = selectTarget()
            setTarget(selected)
        end
    else
        if State.CurrentTargetHandler then
            State.CurrentTargetHandler = nil
            State.CurrentTarget = nil
        end
        clearForcedTarget()
    end

    pollLocalParryStagger()
    tryEquip()

    local retry = flag("DG_AttackRetry", 0.06)
    if now - State.LastAttack >= retry then
        State.LastAttack = now
        tryAttack()
    end

    updateMovement()
end))

local function cleanup()
    if not State.Alive then
        return
    end

    State.Alive = false

    for _, conn in ipairs(State.Connections) do
        disconnect(conn)
    end
    table.clear(State.Connections)

    disconnect(State.LocalParryConnection)
    State.LocalParryConnection = nil

    for handler in pairs(State.EnemyRecords) do
        untrackEnemy(handler)
    end

    local handler = getLocalHandler()
    if handler then
        releaseBlock(handler)
        handler.IsDodging = nil
        handler.IsParrying = false
    end

    if handler then
        handler.DesiredMoveTo = nil
    end

    State.AntiParryToken += 1
    State.AntiParryUntil = 0
    State.AntiParryAttacker = nil
    State.AntiParryRetreatPoint = nil
    State.LastQueuedAttackTarget = nil

    if InputController and InputController.CurrentInput and State.MovementOverride then
        InputController.CurrentInput.MoveDirection = Vector3.zero
    end

    clearForcedTarget()

    if ENV.DuelingAutoEverything == State then
        ENV.DuelingAutoEverything = nil
    end
end

State.Cleanup = cleanup
ENV.DuelingAutoEverything = State

local row = MiscSection:Button()
row:Add("Rescan Fighters", function()
    for _, model in ipairs(CollectionService:GetTagged("CustomCharacter")) do
        local handler = CharacterController:GetCharacterHandler(model)
        if handler and isEnemy(handler) then
            trackEnemy(handler)
        end
    end
    notify("Auto Combat", "Fighter cache refreshed.", "success", 2)
end)
row:Add("Unload", function()
    cleanup()
    VibeUI:Unload()
end)

pcall(function()
    VibeUI:CreateSettingsPage(Window)
end)

notify(
    "Dueling Grounds Automation",
    "Loaded. Timed defense + incoming-impact fallback are active; safe-zone pause is ON.",
    "success",
    4
)
