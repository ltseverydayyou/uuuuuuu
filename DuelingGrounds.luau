local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayerCharacter = Remotes:WaitForChild("PlayerCharacter")

local ENV = (type(getgenv) == "function" and getgenv()) or _G
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
    AntiParryActive = false,
    AntiParryStartedAt = 0,
    AntiParryHardStop = 0,
    AntiParryReadySince = 0,
    AntiParryPostureAtStart = nil,
    AntiParryPostureMax = nil,
    AntiParryLastDefense = 0,
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

local Compat = {
    External = false,
    NativeControllers = false,
    VirtualInput = nil,
    PressedKeys = {},
    KeyTokens = {},
    HandlerCache = setmetatable({}, { __mode = "k" }),
    WeaponInfoCache = {},
    MovementKeys = {
        W = false,
        A = false,
        S = false,
        D = false,
    },
}

local function cleanWeaponName(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    if string.sub(name, 1, 1) == "*" then
        name = string.sub(name, 2)
    end
    return name ~= "" and name or nil
end

local function externalVisualModel(model)
    if not model then
        return nil
    end

    local uid = model:GetAttribute("UserId")
    if model == LocalPlayer.Character or uid == LocalPlayer.UserId then
        local camera = workspace.CurrentCamera
        local subject = camera and camera.CameraSubject
        local subjectModel = subject and subject:FindFirstAncestorWhichIsA("Model")
        if subjectModel and subjectModel:IsDescendantOf(workspace) then
            return subjectModel
        end

        local clientModel = workspace:FindFirstChild(model.Name .. "_Client")
        if clientModel and clientModel:IsA("Model") then
            return clientModel
        end
    end

    return model
end

local function externalRoot(model)
    local visual = externalVisualModel(model)
    if not visual then
        return nil
    end
    return visual:FindFirstChild("HumanoidRootPart") or visual.PrimaryPart
end

local function externalAnimator(model)
    local visual = externalVisualModel(model)
    if not visual then
        return nil
    end
    local humanoid = visual:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid:FindFirstChildOfClass("Animator") or nil
end

local function externalPlayer(model)
    if not model then
        return nil
    end
    local uid = model:GetAttribute("UserId")
    if type(uid) == "number" then
        return Players:GetPlayerByUserId(uid)
    end
    return nil
end

local function getExternalWeaponInfo(weaponName)
    weaponName = cleanWeaponName(weaponName)
    if not weaponName then
        return nil
    end

    if Compat.WeaponInfoCache[weaponName] ~= nil then
        return Compat.WeaponInfoCache[weaponName] or nil
    end

    local weaponModules = ReplicatedStorage:FindFirstChild("WeaponModulesShared")
    local weaponModule = weaponModules and weaponModules:FindFirstChild(weaponName)
    local attacksFolder = weaponModule and weaponModule:FindFirstChild("BasicAttackTypes")
    if not attacksFolder then
        Compat.WeaponInfoCache[weaponName] = false
        return nil
    end

    local attacks = {}
    if type(require) == "function" then
        for _, child in ipairs(attacksFolder:GetChildren()) do
            if child:IsA("ModuleScript") then
                local ok, info = pcall(require, child)
                if ok and type(info) == "table" then
                    attacks[child.Name] = info
                end
            end
        end
    end

    local wrapped = {
        WeaponInfo = {
            BasicAttackTypes = attacks,
        },
    }
    Compat.WeaponInfoCache[weaponName] = wrapped
    return wrapped
end

local ExternalHandlerMethods = {}

function ExternalHandlerMethods:GetEquippedWeaponHandler()
    return getExternalWeaponInfo(self.OriginalModel and self.OriginalModel:GetAttribute("EquippedWeapon"))
end

local function makeExternalHandler(model)
    if not model then
        return nil
    end

    local cached = Compat.HandlerCache[model]
    if cached then
        return cached
    end

    local handler = {
        OriginalModel = model,
        External = true,
    }

    setmetatable(handler, {
        __index = function(self, key)
            local method = ExternalHandlerMethods[key]
            if method then
                return method
            end
            if key == "Root" then
                return externalRoot(model)
            elseif key == "Animator" then
                return externalAnimator(model)
            elseif key == "Player" then
                return externalPlayer(model)
            elseif key == "EquippedWeapon" then
                return cleanWeaponName(model:GetAttribute("EquippedWeapon"))
            elseif key == "EquippedWeaponChanged" then
                return model:GetAttributeChangedSignal("EquippedWeapon")
            elseif key == "Destroyed" then
                return model.Destroying
            elseif key == "Parried" then
                return model:GetAttributeChangedSignal("ParriedEvent")
            end
            return rawget(self, key)
        end,
    })

    Compat.HandlerCache[model] = handler
    return handler
end

local function getInputActionsRoot()
    local controllers = ReplicatedStorage:FindFirstChild("Controllers")
    local inputControllerModule = controllers and controllers:FindFirstChild("PlayerInputController")
    return inputControllerModule and inputControllerModule:FindFirstChild("InputActions") or nil
end

local function getInputAction(kind)
    local root = getInputActionsRoot()
    if not root then
        return nil
    end

    local character = root:FindFirstChild("CharacterGameplayContext")
    local camera = root:FindFirstChild("CameraGameplayContext")
    local equipped = character and character:FindFirstChild("EquippedWeaponContext")

    if kind == "Light" then
        return equipped and equipped:FindFirstChild("LightAttackAction")
    elseif kind == "Heavy" then
        return equipped and equipped:FindFirstChild("HeavyAttackAction")
    elseif kind == "Guard" then
        return equipped and equipped:FindFirstChild("GuardAction")
    elseif kind == "Dodge" then
        return character and character:FindFirstChild("DodgeAction")
    elseif kind == "Ultimate" then
        local ultimateContext = equipped and equipped:FindFirstChild("UltimateAvailableContext")
        return ultimateContext and ultimateContext:FindFirstChild("UltimateAbility")
    elseif kind == "Lock" then
        return camera and camera:FindFirstChild("LockToTarget")
    end

    return nil
end

local DefaultActionKeys = {
    Light = Enum.KeyCode.MouseLeftButton,
    Heavy = Enum.KeyCode.MouseRightButton,
    Guard = Enum.KeyCode.F,
    Dodge = Enum.KeyCode.Q,
    Ultimate = Enum.KeyCode.R,
    Lock = Enum.KeyCode.T,
}

local function externalActionKey(kind)
    local action = getInputAction(kind)
    if action then
        for _, bindingName in ipairs({ "KeyboardBinding", "KeyboardBinding2" }) do
            local binding = action:FindFirstChild(bindingName)
            if binding and binding:IsA("InputBinding") then
                local bound = binding:GetAttribute("CustomBoundKeyCode")
                if typeof(bound) ~= "EnumItem" then
                    local ok, value = pcall(function()
                        return binding.KeyCode
                    end)
                    if ok then
                        bound = value
                    end
                end
                if typeof(bound) == "EnumItem"
                    and bound ~= Enum.KeyCode.Unknown
                    and bound ~= Enum.KeyCode.None
                then
                    return bound
                end
            end
        end
    end

    return DefaultActionKeys[kind]
end

local function externalSendKey(keyCode, isDown)
    if not Compat.VirtualInput or not keyCode then
        return false
    end

    local ok = pcall(function()
        if keyCode == Enum.KeyCode.MouseLeftButton
            or keyCode == Enum.KeyCode.MouseRightButton
            or keyCode == Enum.KeyCode.MouseMiddleButton
        then
            local camera = workspace.CurrentCamera
            local size = camera and camera.ViewportSize or Vector2.new(800, 600)
            local button = keyCode == Enum.KeyCode.MouseLeftButton and 0
                or keyCode == Enum.KeyCode.MouseRightButton and 1
                or 2
            Compat.VirtualInput:SendMouseButtonEvent(
                math.floor(size.X * 0.5),
                math.floor(size.Y * 0.5),
                button,
                isDown,
                game,
                0
            )
        else
            Compat.VirtualInput:SendKeyEvent(isDown, keyCode, false, game)
        end
    end)

    if ok then
        Compat.PressedKeys[keyCode] = isDown or nil
    end
    return ok
end

local function externalTap(kind, hold)
    local key = externalActionKey(kind)
    if not key then
        return false
    end

    Compat.KeyTokens[key] = (Compat.KeyTokens[key] or 0) + 1
    local token = Compat.KeyTokens[key]
    if not externalSendKey(key, true) then
        return false
    end

    task.delay(hold or 0.035, function()
        if Compat.KeyTokens[key] == token then
            externalSendKey(key, false)
        end
    end)
    return true
end

local function externalReleaseAction(kind)
    local key = externalActionKey(kind)
    if key then
        Compat.KeyTokens[key] = (Compat.KeyTokens[key] or 0) + 1
        externalSendKey(key, false)
    end
end

local function externalSetMovementKey(name, down)
    local key = Enum.KeyCode[name]
    if not key or Compat.MovementKeys[name] == down then
        return
    end
    Compat.MovementKeys[name] = down
    externalSendKey(key, down)
end

local function externalReleaseMovement()
    externalSetMovementKey("W", false)
    externalSetMovementKey("A", false)
    externalSetMovementKey("S", false)
    externalSetMovementKey("D", false)
end

local function externalMoveDirection(direction)
    if not direction or direction.Magnitude < 0.05 then
        externalReleaseMovement()
        return
    end

    local camera = workspace.CurrentCamera
    local cf = camera and camera.CFrame or CFrame.new()
    local forward = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
    local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
    if forward.Magnitude < 0.001 or right.Magnitude < 0.001 then
        externalReleaseMovement()
        return
    end

    forward = forward.Unit
    right = right.Unit
    local flat = Vector3.new(direction.X, 0, direction.Z)
    if flat.Magnitude < 0.001 then
        externalReleaseMovement()
        return
    end
    flat = flat.Unit

    local f = flat:Dot(forward)
    local r = flat:Dot(right)
    externalSetMovementKey("W", f > 0.28)
    externalSetMovementKey("S", f < -0.28)
    externalSetMovementKey("D", r > 0.28)
    externalSetMovementKey("A", r < -0.28)
end

local GameManager
local CharacterController
local TargetLockController
local InputController
local MatchController

local oldIdentity = getthreadidentity and getthreadidentity() or nil
if setthreadidentity then
    pcall(setthreadidentity, 2)
end

do
    local nativeOk = false
    if type(require) == "function" then
        local okManager, manager = pcall(require, ReplicatedStorage:WaitForChild("GameManager"))
        if okManager and type(manager) == "table" then
            local okCharacter, characterController = pcall(manager.GetController, manager, "CharacterController")
            if okCharacter and characterController then
                GameManager = manager
                CharacterController = characterController
                local okTarget, targetController = pcall(manager.GetController, manager, "TargetLockController")
                local okInput, inputController = pcall(manager.GetController, manager, "PlayerInputController")
                local okMatch, matchController = pcall(manager.GetController, manager, "MatchController")
                TargetLockController = okTarget and targetController or nil
                InputController = okInput and inputController or nil
                MatchController = okMatch and matchController or nil
                nativeOk = true
            end
        end
    end

    Compat.NativeControllers = nativeOk
    Compat.External = not nativeOk
end

if setthreadidentity and oldIdentity then
    pcall(setthreadidentity, oldIdentity)
end

if Compat.External then
    pcall(function()
        Compat.VirtualInput = Instance.new("VirtualInputManager")
    end)

    CharacterController = {
        GetLocalCharacterHandler = function()
            return makeExternalHandler(LocalPlayer.Character)
        end,
        GetCharacterHandler = function(_, model)
            return makeExternalHandler(model)
        end,
    }

    CharacterController.CharacterLoaded = {
        Connect = function(_, callback)
            return CollectionService:GetInstanceAddedSignal("CustomCharacter"):Connect(function(model)
                callback(makeExternalHandler(model))
            end)
        end,
    }

    CharacterController.LocalCharacterLoaded = {
        Connect = function(_, callback)
            return LocalPlayer.CharacterAdded:Connect(function(model)
                task.defer(callback, makeExternalHandler(model))
            end)
        end,
    }

    TargetLockController = {
        _Target = nil,
        _ForcedTarget = nil,
        SetForcedTargetLock = function(self, target)
            self._ForcedTarget = target
            if target == nil then
                self._Target = nil
                pcall(function()
                    PlayerCharacter.Request.SetTargetLock:FireServer(nil)
                end)
            end
        end,
        SetTarget = function(self, target)
            if self._Target == target then
                return
            end
            self._Target = target
            pcall(function()
                PlayerCharacter.Request.SetTargetLock:FireServer(target)
            end)
        end,
    }

    InputController = {
        CurrentInput = {
            MoveDirection = Vector3.zero,
        },
    }

    MatchController = {
        IsCharacterEnemyOfLocalPlayer = function(_, model)
            if not model then
                return true
            end
            local uid = model:GetAttribute("UserId")
            if uid and uid == LocalPlayer.UserId then
                return false
            end

            local localModel = LocalPlayer.Character
            local localTeam = localModel and localModel:GetAttribute("TeamGroup")
            local targetTeam = model:GetAttribute("TeamGroup")
            if localTeam and targetTeam and localTeam == targetTeam then
                return false
            end
            return true
        end,
    }
end

local loadSource = loadstring or load
assert(type(loadSource) == "function", "Executor does not provide loadstring/load")

local okVibeSource, vibeSource = pcall(function()
    return game:HttpGet("https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau")
end)
assert(okVibeSource and type(vibeSource) == "string", "Executor does not provide a working game:HttpGet")

local vibeChunk, vibeCompileError = loadSource(vibeSource)
assert(type(vibeChunk) == "function", "Failed to compile VibeUI: " .. tostring(vibeCompileError))
local VibeUI = vibeChunk()

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
    Name = "Parried Recovery Max",
    Flag = "DG_ParriedRecovery",
    Min = 0.75,
    Max = 5,
    Default = 2.5,
    Decimals = 0.05,
    Suffix = "s",
})
DefenseExtra:Slider({
    Name = "Recovery Posture",
    Flag = "DG_RecoveryPosture",
    Min = 0.5,
    Max = 1,
    Default = 0.9,
    Decimals = 0.05,
    Suffix = " ratio",
})
DefenseExtra:Slider({
    Name = "Recovery Stable",
    Flag = "DG_RecoveryStable",
    Min = 0.1,
    Max = 0.5,
    Default = 0.2,
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
    Content = (Compat.External and "External VM compatibility mode. " or "Native controller mode. ")
        .. "Event-driven attack recognition uses equipped-weapon animation IDs and exact impact markers; no GetDescendants/GetPlayingAnimationTracks polling.",
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
    if Compat.External then
        externalReleaseAction("Guard")
        return
    end

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

    if Compat.External then
        if not handler.EquippedWeapon then
            return false
        end

        local key = externalActionKey("Guard")
        if not key or not externalSendKey(key, true) then
            return false
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
                externalReleaseAction("Guard")
            end
        end)

        return true
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

    if Compat.External then
        local dir = computeDodgeDirection(attacker)
        local hold = flag("DG_DodgeInputHold", 0.12)
        State.ForcedMoveDirection = dir
        State.ForcedMoveUntil = math.max(State.ForcedMoveUntil, os.clock() + hold)
        externalMoveDirection(dir)
        return externalTap("Dodge", 0.04)
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

        if State.AntiParryActive then
            local now = os.clock()
            State.DefenseBusyUntil = math.max(State.DefenseBusyUntil, now + 0.18)
            if flag("DG_AutoDodge", true)
                and now - (State.AntiParryLastDefense or 0) >= 0.14
            then
                if dodge(record.handler) then
                    State.AntiParryLastDefense = now
                end
            end
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

    if State.AntiParryActive and autoDodge then
        useDodge = true
    end

    State.DefenseBusyUntil = math.max(State.DefenseBusyUntil, os.clock() + 0.3)

    if Compat.External then
        local acted
        if useDodge then
            acted = dodge(nil)
        else
            acted = pressParry()
            if not acted and autoDodge then
                acted = dodge(nil)
            end
        end
        if acted then
            debugNotify(useDodge and "Impact dodge" or "Impact parry")
        end
        return acted == true
    end

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

    if Compat.External then
        externalReleaseAction("Light")
        externalReleaseAction("Heavy")
        externalReleaseAction("Ultimate")
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

local function getRecoveryPosture(handler)
    local model = handler and handler.OriginalModel
    if not model then
        return nil, nil
    end

    local posture = model:GetAttribute("Posture")
    local maxPosture = model:GetAttribute("MaxPosture")
    if type(posture) ~= "number"
        or type(maxPosture) ~= "number"
        or maxPosture <= 0
    then
        return nil, nil
    end

    return posture, maxPosture
end

local function antiParryShieldRecovered(handler, now)
    now = now or os.clock()

    local startedAt = State.AntiParryStartedAt or now
    if now - startedAt < 0.55 then
        State.AntiParryReadySince = 0
        return false
    end

    local posture, maxPosture = getRecoveryPosture(handler)
    if not posture or not maxPosture then
        local fallback = tonumber(flag("DG_ParriedRecovery", 2.5)) or 2.5
        return now - startedAt >= math.max(0.75, fallback)
    end

    local threshold = tonumber(flag("DG_RecoveryPosture", 0.9)) or 0.9
    if threshold < 0.5 then
        threshold = 0.5
    elseif threshold > 1 then
        threshold = 1
    end

    if posture < maxPosture * threshold then
        State.AntiParryReadySince = 0
        return false
    end

    if not State.AntiParryReadySince or State.AntiParryReadySince == 0 then
        State.AntiParryReadySince = now
        return false
    end

    local stable = tonumber(flag("DG_RecoveryStable", 0.2)) or 0.2
    return now - State.AntiParryReadySince >= math.max(0.05, stable)
end

local function finishAntiParryRecovery()
    if not State.AntiParryActive then
        return
    end

    local attacker = State.AntiParryAttacker
    local record = attacker and State.EnemyRecords[attacker]
    if record then
        record.parryPunishUntil = 0
    end

    State.AntiParryActive = false
    State.AntiParryStartedAt = 0
    State.AntiParryHardStop = 0
    State.AntiParryReadySince = 0
    State.AntiParryPostureAtStart = nil
    State.AntiParryPostureMax = nil
    State.AntiParryUntil = 0
    State.AntiParryAttacker = nil
    State.AntiParryRetreatPoint = nil
    State.AntiParryToken += 1
    State.DefenseBusyUntil = math.max(State.DefenseBusyUntil, os.clock() + 0.12)
    debugNotify("Anti-parry recovery complete")
end

local function refreshAntiParryRetreatPoint(handler)
    if not State.AntiParryActive
        or not handler
        or not handler.Root
    then
        return
    end

    local attacker = State.AntiParryAttacker
    local attackerRoot = attacker and attacker.Root
    local away

    if attackerRoot then
        away = handler.Root.Position - attackerRoot.Position
        away = Vector3.new(away.X, 0, away.Z)
    end

    if not away or away.Magnitude < 0.001 then
        away = computeDodgeDirection(attacker)
    end

    if away.Magnitude < 0.001 then
        return
    end

    local point = State.AntiParryRetreatPoint
    if not point or (point - handler.Root.Position).Magnitude < 2 then
        State.AntiParryRetreatPoint = handler.Root.Position
            + away.Unit * math.max(8, flag("DG_AntiParryRetreat", 9))
    end
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
    local alreadyRecovering = State.AntiParryActive
        and now < (State.AntiParryHardStop or 0)

    if not alreadyRecovering then
        State.AntiParryStartedAt = now
        State.AntiParryReadySince = 0
        State.AntiParryPostureAtStart, State.AntiParryPostureMax =
            getRecoveryPosture(handler)
    else
        State.AntiParryReadySince = 0
    end

    State.AntiParryActive = true
    State.AntiParryAttacker = attacker

    local recoveryMax = tonumber(flag("DG_ParriedRecovery", 2.5)) or 2.5
    recoveryMax = math.max(0.75, recoveryMax)
    State.AntiParryHardStop = math.max(
        State.AntiParryHardStop or 0,
        now + recoveryMax
    )
    State.AntiParryUntil = State.AntiParryHardStop
    State.DefenseBusyUntil = math.max(State.DefenseBusyUntil, State.AntiParryUntil)

    if record then
        record.parryPunishUntil = math.max(
            record.parryPunishUntil or 0,
            State.AntiParryUntil
        )
    end

    cancelQueuedOffense(handler)
    releaseBlock(handler)
    refreshAntiParryRetreatPoint(handler)

    State.AntiParryToken += 1
    local token = State.AntiParryToken

    task.spawn(function()
        while State.Alive
            and token == State.AntiParryToken
            and State.AntiParryActive
            and os.clock() < State.AntiParryHardStop
        do
            local current = getLocalHandler()
            if not current or current ~= handler then
                return
            end

            if localPaused(current) then
                finishAntiParryRecovery()
                return
            end

            local now = os.clock()
            if antiParryShieldRecovered(current, now) then
                finishAntiParryRecovery()
                return
            end

            cancelQueuedOffense(current)

            local manager = current.ActionManager
            local action = manager and manager.CurrentAction
            local canDodge = flag("DG_AutoDodge", true)
                and now - (State.AntiParryLastDefense or 0) >= 0.16

            if canDodge and (
                isParryStaggerAction(action)
                or (
                    action
                    and action.ActionType == "BasicAttack"
                    and action.CanCancel
                )
            ) then
                if dodge(attacker) then
                    State.AntiParryLastDefense = now
                end
            end

            task.wait(0.025)
        end

        if State.Alive
            and token == State.AntiParryToken
            and State.AntiParryActive
        then
            finishAntiParryRecovery()
            debugNotify("Anti-parry recovery timeout")
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
        if Compat.External
            and handler.OriginalModel
            and not handler.OriginalModel:GetAttribute("ParriedEvent")
        then
            return
        end
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
            if Compat.External then
                externalTap(counter == "Heavy" and "Heavy" or "Light", 0.04)
            else
                h._desiredQueuedAction = counter == "Heavy" and "HeavyAttack" or "LightAttack"
                h._desiredQueuedActionDuration = nil
            end
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

    local critical
    if Compat.External then
        local target = State.CurrentTargetHandler
        critical = target and target.Root or nil
        if critical and not critical:GetAttribute("OpenForCritical") then
            critical = nil
        end
    else
        critical = TargetLockController.CriticalStrikeTarget
    end

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
    if State.AntiParryActive
        or recordInFreshParryWindow(record)
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
        if Compat.External then
            externalTap("Ultimate", 0.04)
        else
            handler._desiredQueuedAction = "Ultimate"
            handler._desiredQueuedActionDuration = nil
        end
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

    if Compat.External then
        externalTap(desired == "HeavyAttack" and "Heavy" or "Light", 0.04)
    else
        handler._desiredQueuedAction = desired
        handler._desiredQueuedActionDuration = nil
    end
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
        if Compat.External then
            externalReleaseMovement()
        end
        return
    end

    if localPaused(handler) then
        if Compat.External then
            externalReleaseMovement()
        else
            handler.DesiredMoveTo = nil
        end
        State.MovementOverride = false
        return
    end

    local now = os.clock()

    if Compat.External then
        if State.AntiParryActive then
            refreshAntiParryRetreatPoint(handler)
        end

        if now < State.ForcedMoveUntil and State.ForcedMoveDirection.Magnitude > 0.01 then
            externalMoveDirection(State.ForcedMoveDirection)
            State.MovementOverride = true
            return
        end

        if State.AntiParryActive and now < State.AntiParryUntil then
            refreshAntiParryRetreatPoint(handler)
            local point = State.AntiParryRetreatPoint
            if point and handler.Root then
                local retreat = point - handler.Root.Position
                externalMoveDirection(retreat)
                State.MovementOverride = true
                return
            end
        elseif State.AntiParryRetreatPoint then
            State.AntiParryRetreatPoint = nil
            State.AntiParryAttacker = nil
        end

        if not flag("DG_AutoChase", true) then
            externalReleaseMovement()
            State.MovementOverride = false
            return
        end

        local target = State.CurrentTargetHandler
        if not target or not target.Root or not handler.Root then
            externalReleaseMovement()
            State.MovementOverride = false
            return
        end

        local delta = target.Root.Position - handler.Root.Position
        local flat = Vector3.new(delta.X, 0, delta.Z)
        if flat.Magnitude < 0.01 then
            externalReleaseMovement()
            State.MovementOverride = false
            return
        end

        local preferred = flag("DG_PreferredDistance", 7)
        if flat.Magnitude > preferred then
            externalMoveDirection(flat)
            State.MovementOverride = true
        elseif flag("DG_AutoStrafe", true) then
            local side = Vector3.new(-flat.Z, 0, flat.X).Unit
            local sign = (math.floor(now * 1.35) % 2 == 0) and 1 or -1
            externalMoveDirection(side * sign)
            State.MovementOverride = true
        else
            externalReleaseMovement()
            State.MovementOverride = false
        end
        return
    end

    if State.AntiParryActive and now < State.AntiParryUntil then
        refreshAntiParryRetreatPoint(handler)
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

    if Compat.External then
        externalReleaseMovement()
        externalReleaseAction("Light")
        externalReleaseAction("Heavy")
        externalReleaseAction("Guard")
        externalReleaseAction("Dodge")
        externalReleaseAction("Ultimate")
        for key in pairs(Compat.PressedKeys) do
            externalSendKey(key, false)
        end
    elseif handler then
        handler.DesiredMoveTo = nil
    end

    State.AntiParryActive = false
    State.AntiParryToken += 1
    State.AntiParryUntil = 0
    State.AntiParryHardStop = 0
    State.AntiParryAttacker = nil
    State.AntiParryRetreatPoint = nil
    State.LastQueuedAttackTarget = nil

    if not Compat.External
        and InputController
        and InputController.CurrentInput
        and State.MovementOverride
    then
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
    (Compat.External and "Loaded in external compatibility mode. " or "Loaded with native controllers. ")
        .. "Timed defense + incoming-impact fallback are active; safe-zone pause is ON.",
    Compat.External and (Compat.VirtualInput and "success" or "warning") or "success",
    4
)
