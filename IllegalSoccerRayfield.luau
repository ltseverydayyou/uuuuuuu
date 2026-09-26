if setthreadidentity then setthreadidentity(8) end
local ENV = getgenv()
local KEY = "IllegalSoccer"
if ENV[KEY] and ENV[KEY].Unload then ENV[KEY]:Unload() end
assert(game.GameId == 10155360168, "This script is for Illegal Soccer.")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local ZERO, UP = Vector3.zero, Vector3.yAxis
local Hub = { Alive = true, Connections = {}, Patches = {}, Errors = {}, Controls = {}, Stats = {
    Actions = 0, Corrections = 0, Redirects = 0, Dives = 0, Dribbles = 0, Passes = 0,
} }
ENV[KEY] = Hub
local S = {
    AutoPlay = false, AutoDribble = false, KickPredictionThreshold = 0.15,
    AutoPass = false, TackleAssist = false, SmartDodge = false, AutoToolUse = false,
    AutoSprint = false, InfiniteStamina = false, NoBallSlowdown = false, NoKickSlow = false,
    SpeedBoost = false, SpeedMultiplier = 1.25, IgnorePositionCorrections = false,
    TackleSpeed = false, TackleSpeedMultiplier = 1.5, AutoJoinFriendTeam = false,
    LooseBallTeleport = false, ShotRedirect = false, AutoCurve = true, AdaptiveCurveStrength = 1,
    RedirectDistance = 60, SuperchargeRedirectDistance = 90, ShotTargetPicker = "Adaptive",
    ShotSide = "Best", ShotTargetMarker = false, VolleyAssist = false, VolleyAssistDistance = 60,
    FakeShotBait = false, AutoBicycleKick = false, BicycleKickChance = 35,
    AutoGoalkeeper = false, DiveTimingThreshold = 0.08, LooseBallDiveDistance = 15,
    SlowShotDiveThreshold = 0.25, BackwardDive = false, SilentAim = false,
    HitboxExpander = false, HitboxSize = 10, HitboxTransparency = 1,
    LandingPredictor = false, BallTrajectory = false, PredictionLength = 2,
    RedirectDistanceESP = false, TackleWarning = false, KeeperReach = false, SaveMarker = false,
    GoalEffect = "Default", BallSkin = "Default", Watermark = true, Keybinds = true,
    MenuKeybind = Enum.KeyCode.End,
}
Hub.Settings = S
local M, window, visuals, overlay, watermark, keylist, statusText
local originals = setmetatable({}, { __mode = "k" })
local highlights = {}
local disabledCorrections, disabledGoalEffects = {}, {}
local goalEffectRelay
local ballSkins = {}
local autoSnapshot, sprintSnapshot, shotInput, passInput, forcedPass, forcedShotTarget
local moveIntent, tackleIntent, diveIntent, pendingShot, smartDodgeIntent
local lastShot, lastVolley, lastDribble, lastJoin, lastDive = 0, 0, 0, 0, 0
local lastPass, lastTackle, lastToolUse, correctionScale = 0, 0, 0, 1
local cachedActors, trajectory, landing, savePlan, shotPlan, keeperAnticipation = {}, {}, nil, nil, nil, nil
local originalTackleDistance, originalTackleStartup
local sampleTime, sampleState, sampleWorld
local goalPauseUntil, ballOwnedSince, looseBallSince, lastLooseTeleport = 0, 0, nil, 0
local previousOwner, fakeBaitState, smartDodgeUntil = nil, nil, 0
local bicycleBusy, internalShot, autoToolSlot = false, false, 0
local toolActionId = math.floor(workspace:GetServerTimeNow() * 1000)
local function flat(v) return Vector3.new(v.X, 0, v.Z) end
local function unit(v, fallback) return v.Magnitude > 0.001 and v.Unit or fallback or Vector3.zAxis end
local function rootOf(ch) return ch and ch:FindFirstChild("HumanoidRootPart") end
local function root() return rootOf(LP.Character) end
local function connect(signal, callback)
    local connection = signal:Connect(function(...)
        local identity = getthreadidentity and getthreadidentity()
        if setthreadidentity then setthreadidentity(8) end
        local ok, err = xpcall(callback, debug.traceback, ...)
        if identity and setthreadidentity then setthreadidentity(identity) end
        if not ok then
            Hub.Errors.Callback = {Message = tostring(err), Time = os.clock()}
            warn("[IllegalSoccer] " .. tostring(err))
        end
    end)
    table.insert(Hub.Connections, connection)
    return connection
end
local function report(key, message)
    local previous = Hub.Errors[key]
    if not previous or os.clock() - previous.Time > 10 then
        Hub.Errors[key] = { Message = tostring(message), Time = os.clock() }
        warn("[Illegal Soccer / " .. key .. "] " .. tostring(message))
    end
end
local function safe(key, fn, ...)
    local result = table.pack(pcall(fn, ...))
    if not result[1] then report(key, result[2]); return nil end
    return table.unpack(result, 2, result.n)
end
local function patch(tbl, key, factory)
    assert(type(tbl[key]) == "function", "Missing game function: " .. key)
    local original = tbl[key]
    local replacement = factory(original)
    tbl[key] = replacement
    table.insert(Hub.Patches, { Table = tbl, Key = key, Original = original, Replacement = replacement })
end
local function module(path)
    local obj = RS
    for name in path:gmatch("[^.]+") do
        obj = obj:FindFirstChild(name)
        assert(obj, "Game module missing: " .. path)
    end
    return require(obj)
end
local function restoreHitboxes()
    for part, values in pairs(originals) do
        if part.Parent then
            safe("restore hitbox", function()
                part.Size, part.Transparency, part.CanCollide, part.Massless =
                    values.Size, values.Transparency, values.CanCollide, values.Massless
            end)
        end
        originals[part] = nil
    end
end
local function restoreCorrections()
    for _, connection in ipairs(disabledCorrections) do pcall(function() connection:Enable() end) end
    table.clear(disabledCorrections)
end
local function restoreGoalEffects()
    if goalEffectRelay then goalEffectRelay:Disconnect(); goalEffectRelay = nil end
    for _, connection in ipairs(disabledGoalEffects) do pcall(function() connection:Enable() end) end
    table.clear(disabledGoalEffects)
end
local function stopOwnedInputs()
    if not M then return end
    if shotInput then safe("cancel kick", M.Shoot.CancelCharge); shotInput = nil end
    if passInput then safe("cancel pass", M.Pass.CancelCharge); passInput = nil end
    forcedPass, pendingShot, moveIntent, tackleIntent, diveIntent = nil, nil, nil, nil, nil
    forcedShotTarget, smartDodgeIntent, fakeBaitState = nil, nil, nil
    local ch = LP.Character
    if ch then safe("stop movement", M.Controllers.SetMoveCommand, ch, ZERO, false) end
end
function Hub:Unload()
    if setthreadidentity then setthreadidentity(8) end
    if not self.Alive then return end
    self.Alive = false
    for _, connection in ipairs(self.Connections) do connection:Disconnect() end
    S.ShotRedirect, S.VolleyAssist, S.AutoPlay, S.AutoPass = false, false, false, false
    stopOwnedInputs()
    restoreCorrections()
    restoreGoalEffects()
    for i = #self.Patches, 1, -1 do
        local p = self.Patches[i]
        if p.Table[p.Key] == p.Replacement then p.Table[p.Key] = p.Original end
    end
    restoreHitboxes()
    if M then
        safe("stamina restore", M.Sprint.SetUnlimitedStamina, KEY, false)
        if sprintSnapshot ~= nil and M.Sprint.IsSprintButtonToggled() ~= sprintSnapshot then
            safe("sprint restore", M.Sprint.ToggleSprintButton)
        end
        if originalTackleDistance then
            M.Slide.Constants.Distance = originalTackleDistance
            M.Slide.Constants.StartupDashDistance = originalTackleStartup
        end
        for id, name in pairs(ballSkins) do safe("skin restore", M.Renderer.SetSkin, id, name) end
    end
    if visuals then visuals:Destroy() end
    if overlay then overlay:Destroy() end
    if setthreadidentity then setthreadidentity(8) end
    if window then
        local ok = pcall(window.Unload, window)
        if not ok then
            window.unloaded = true
            for _, connection in ipairs(window.connections or {}) do pcall(function() connection:Disconnect() end) end
            if setthreadidentity then setthreadidentity(8) end
            if window.screenGui then pcall(function() window.screenGui:Destroy() end) end
        end
    end
    if ENV[KEY] == self then ENV[KEY] = nil end
end

local function initialize()
    M = {
        Renderer = module("Client.Gameplay.Ball.Renderer"), Physics = module("Modules.Ball.Physics"),
        Field = module("Modules.Gameplay.FieldSettings"), Actors = module("Modules.Characters.Actors"),
        Teams = module("Client.Gameplay.ActorTeams"), Motion = module("Modules.Characters.CharacterMotion"),
        Controllers = module("Modules.Characters.CharacterControllers"), Controls = module("Modules.Gameplay.Controls"),
        Shoot = module("Client.Gameplay.Actions.Shoot"), Shot = module("Modules.Actions.Shoot"),
        Pass = module("Client.Gameplay.Actions.Pass"), Dodge = module("Client.Gameplay.Actions.Dodge"),
        SlideInput = module("Client.Gameplay.Actions.SlideTackleInput"), Slide = module("Modules.Actions.SlideTackle"),
        Sprint = module("Client.Gameplay.Player.Sprint"), Movement = module("Client.Gameplay.Player.Movement"),
        ActionMovement = module("Modules.Actions.ActionMovement"), Commands = module("Modules.Actions.ActionCommands"),
        Protocol = module("Modules.Actions.ActionRemoteProtocol"), Volley = module("Client.Gameplay.Actions.VolleyOpportunity"),
        Keeper = module("Client.Gameplay.Player.GoalkeeperRole"), Dive = module("Modules.Actions.GoalkeeperDive"),
        Powerups = module("Modules.Actions.KickPowerups"), Charge = module("Modules.Actions.ActionChargeState"),
        Bicycle = module("Modules.Actions.BicycleKick"), Catalog = module("Modules.Cosmetics.Catalog"),
        GoalEffect = module("Client.Gameplay.Visual.GoalEffect"), GoalReplay = module("Client.Gameplay.Replay.GoalReplay"),
        ItemCommands = module("Modules.Items.ItemCommands"), ItemUse = module("Client.Gameplay.ItemUseState"),
        Match = module("Modules.Gameplay.MatchSettings"), Smooth = module("Client.Player.CharacterMotionSmoothing"),
        Curves = module("Modules.CurvedKicks"),
    }
    Hub.Runtime = M
    originalTackleDistance = M.Slide.Constants.Distance
    originalTackleStartup = M.Slide.Constants.StartupDashDistance

    local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()
    window = Rayfield:CreateWindow({ name = "Illegal Soccer", subtitle = "Rayfield Gen2",
        sidebarLayout = true, theme = "cobalt", showName = "Soccer", profile = "Original client assists",
        configuration = { autoSave = false, autoLoad = false, customFolder = "IllegalSoccer", fileName = "Settings" },
    })
    Hub.Window = window
    visuals = Instance.new("Folder")
    visuals.Name = "IllegalSoccerVisuals"
    visuals.Parent = workspace
    overlay = Instance.new("ScreenGui")
    overlay.Name, overlay.ResetOnSpawn, overlay.IgnoreGuiInset = "IllegalSoccerOverlay", false, true
    overlay.DisplayOrder = 20
    overlay.Parent = LP:WaitForChild("PlayerGui")
    local function label(name, position, size)
        local text = Instance.new("TextLabel")
        text.Name, text.Position, text.Size = name, position, size
        text.BackgroundColor3, text.BackgroundTransparency = Color3.fromRGB(13, 19, 32), 0.15
        text.TextColor3, text.TextSize, text.Font = Color3.fromRGB(219, 232, 255), 14, Enum.Font.Code
        text.BorderSizePixel, text.TextXAlignment = 0, Enum.TextXAlignment.Left
        text.Parent = overlay
        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 7); corner.Parent = text
        local padding = Instance.new("UIPadding"); padding.PaddingLeft = UDim.new(0, 10); padding.Parent = text
        return text
    end
    watermark = label("Watermark", UDim2.fromOffset(15, 15), UDim2.fromOffset(385, 30))
    keylist = label("Keybinds", UDim2.fromOffset(15, 54), UDim2.fromOffset(240, 92))
    local function part(name, shape)
        local p = Instance.new("Part")
        p.Name, p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = name, true, false, false, false
        p.CastShadow, p.Material, p.Transparency = false, Enum.Material.Neon, 1
        if shape then p.Shape = shape end
        p.Parent = visuals
        return p
    end
    local segments, ring = {}, {}
    for i = 1, 70 do segments[i] = part("Trajectory") end
    for i = 1, 32 do ring[i] = part("LandingRing") end
    local rangeLine, shotMarker, keeperZone, saveMarker = part("Range"), part("Shot", Enum.PartType.Ball), part("Reach"), part("Save", Enum.PartType.Ball)
    local saveBillboard = Instance.new("BillboardGui")
    saveBillboard.Size, saveBillboard.StudsOffset, saveBillboard.AlwaysOnTop = UDim2.fromOffset(160, 40), Vector3.new(0, 2, 0), true
    saveBillboard.Parent = saveMarker
    local saveText = Instance.new("TextLabel")
    saveText.Size, saveText.BackgroundTransparency, saveText.TextColor3 = UDim2.fromScale(1, 1), 1, Color3.new(1, 1, 1)
    saveText.TextSize, saveText.Font, saveText.Parent = 15, Enum.Font.Code, saveBillboard
    local BLUE, GREEN, RED, GOLD = Color3.fromRGB(90, 180, 255), Color3.fromRGB(65, 240, 165), Color3.fromRGB(255, 85, 95), Color3.fromRGB(255, 202, 80)
    local function line(p, a, b, width, color)
        local length = (b - a).Magnitude
        if length < 0.01 then p.Transparency = 1; return end
        p.Size, p.CFrame, p.Color, p.Transparency = Vector3.new(width, width, length), CFrame.lookAt((a + b) / 2, b), color, 0.15
    end
    local function myTeam() return M.Teams.GetActorTeamName(LP) end
    local function goals()
        local data = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Data")
        local team = myTeam()
        if not data or (team ~= "Team1" and team ~= "Team2") then return nil end
        local own, opponent = data:FindFirstChild(team), data:FindFirstChild(team == "Team1" and "Team2" or "Team1")
        return own and own:FindFirstChild("Goal"), opponent and opponent:FindFirstChild("Goal")
    end
    local function ballPosition() return M.Renderer.GetPosition() end
    local function owner() return M.Renderer.GetOwnedUserId() end
    local function ownBall() return owner() == LP.UserId end
    local function activeRange()
        return M.Powerups.GetMultiplier(LP) > 1 and S.SuperchargeRedirectDistance or S.RedirectDistance
    end
    local function refreshActors()
        local team = myTeam()
        table.clear(cachedActors)
        for _, ch in ipairs(M.Actors.GetAllCharacterModels()) do
            local rp, hum = rootOf(ch), ch:FindFirstChildOfClass("Humanoid")
            local actor = M.Actors.GetFromCharacter(ch)
            local actorTeam = actor and M.Teams.GetActorTeamName(actor)
            if ch ~= LP.Character and rp and hum and hum.Health > 0 and actorTeam then
                table.insert(cachedActors, { Character = ch, Root = rp, Actor = actor,
                    Id = M.Actors.GetUserId(actor), Team = actorTeam, Enemy = team ~= nil and actorTeam ~= team,
                    Keeper = ch:GetAttribute("ActiveGoalkeeper") == true,
                })
            end
        end
    end
    local function opponentKeeper(goal)
        local best, distance = nil, math.huge
        for _, actor in ipairs(cachedActors) do
            if actor.Enemy and actor.Keeper then
                local d = (actor.Root.Position - goal.Position).Magnitude
                if d < distance then best, distance = actor, d end
            end
        end
        return best
    end
    local function pickTarget(origin, goal)
        local keeper = opponentKeeper(goal)
        local estimate = keeper and (keeper.Root.Position + M.Motion.GetVelocity(keeper.Character) * math.clamp((goal.Position - origin).Magnitude / 115, 0, 1.2))
        local half = goal.Size * 0.5
        local xs = S.ShotSide == "Left" and {half.X - 2} or S.ShotSide == "Right" and {-half.X + 2} or {-half.X + 2, half.X - 2}
        local ys = S.ShotTargetPicker == "Low" and {-half.Y + 2} or S.ShotTargetPicker == "High" and {half.Y - 2} or {-half.Y + 2, half.Y - 2}
        if S.ShotTargetPicker == "Center" then xs, ys = {0}, {0} end
        local best, bestScore
        for _, x in ipairs(xs) do for _, y in ipairs(ys) do
            local candidate = goal.CFrame:PointToWorldSpace(Vector3.new(x, y, -half.Z + 0.5))
            local score = estimate and (candidate - estimate).Magnitude or -(candidate - origin).Magnitude * 0.01
            if not bestScore or score > bestScore then best, bestScore = candidate, score end
        end end
        return best, keeper
    end
    local function flightCrossing(origin, velocity, spin, goal)
        local normal = goal.CFrame.LookVector
        local plane = goal.Position + normal * (goal.Size.Z * 0.5)
        local prev, prevD = origin, (origin - plane):Dot(normal)
        local closest, closestError, closestTime = origin, math.huge, 0
        for t = 0.04, 4, 0.04 do
            local p = M.Physics.GetAirFlight(origin, velocity, spin, t)
            local d = (p - plane):Dot(normal)
            if math.abs(d) < closestError then closest, closestError, closestTime = p, math.abs(d), t end
            if d <= 0 and prevD > 0 then return prev:Lerp(p, prevD / (prevD - d)), t end
            if p.Y < M.Field.GetGroundYAt(p) then break end
            prev, prevD = p, d
        end
        return closest, closestTime
    end
    local function planShot(charge)
        local rp, origin = root(), ballPosition()
        local _, goal = goals()
        if not rp or not origin or not goal then return nil end
        local desired, keeper = pickTarget(origin, goal)
        local horizontal, vertical = M.Powerups.GetVelocityMultipliers(M.Powerups.GetMultiplier(LP))
        local curves = {0}
        if S.AutoCurve and M.Curves.IsEnabled() and S.AdaptiveCurveStrength > 0 then
            local strength = S.AdaptiveCurveStrength * math.clamp((desired - origin).Magnitude / 110, 0.15, 1)
            curves = {0, -strength, strength}
        end
        local best
        for _, curve in ipairs(curves) do
            local aimTarget, crossing, flight, velocity, spin = desired
            for _ = 1, 4 do
                local facing = unit(flat(aimTarget - origin))
                velocity = M.Shot.GetVelocity(LP.Character, charge, nil, origin, horizontal, vertical, nil, nil, facing, aimTarget, nil, nil, curve)
                if not velocity then break end
                spin = M.Shot.GetSpin(LP.Character, velocity, nil, curve, charge)
                crossing, flight = flightCrossing(origin, velocity, spin, goal)
                local error = desired - crossing
                if error.Magnitude < 0.35 then break end
                aimTarget += Vector3.new(error.X, math.clamp(error.Y, -3, 3), error.Z) * 0.85
            end
            if crossing then
                local error = (crossing - desired).Magnitude
                local clearance = keeper and (crossing - keeper.Root.Position - M.Motion.GetVelocity(keeper.Character) * flight).Magnitude or 8
                local score = clearance - error * 8 - math.abs(curve) * 0.05
                if error < 8 and (not best or score > best.Score) then
                    best = { Target = aimTarget, Display = desired, Curve = curve, Score = score,
                        Charge = charge, Built = os.clock(), Keeper = keeper, Flight = flight,
                        Origin = origin, Velocity = velocity, Spin = spin, Crossing = crossing }
                end
            end
        end
        return best
    end
    local function redirectCommand(command)
        if not Hub.Alive or command.PassType ~= M.Commands.PassTypes.Shot then return command end
        if forcedShotTarget then
            local origin, target = ballPosition(), forcedShotTarget
            forcedShotTarget = nil
            if origin and target then
                command = table.clone(command)
                command.AimDirection, command.TargetPosition = nil, target
                command.KickDirection, command.Curve = unit(flat(target - origin)), 0
            end
            return command
        end
        local volley = command.Mode == M.Commands.Modes.Volley
        if not ((S.ShotRedirect and not volley) or (S.VolleyAssist and volley)) then return command end
        local _, goal = goals()
        local origin = ballPosition()
        if not goal or not origin then return command end
        if (origin - goal.Position).Magnitude > (volley and S.VolleyAssistDistance or activeRange()) then return command end
        local charge = command.ChargeSeconds or M.Shot.Constants.Kick.MaximumChargeSeconds
        if not shotPlan or os.clock() - shotPlan.Built > 0.18 or math.abs(shotPlan.Charge - charge) > 0.07 or (shotPlan.Origin - origin).Magnitude > 3 then
            shotPlan = planShot(charge)
        end
        if shotPlan then
            command = table.clone(command)
            command.AimDirection, command.TargetPosition = nil, shotPlan.Target
            command.KickDirection, command.Curve = unit(flat(shotPlan.Target - origin)), shotPlan.Curve
            Hub.Stats.Redirects += 1
        end
        return command
    end
    for _, name in ipairs({"Kick", "TackleKick", "Volley"}) do
        patch(M.Commands, name, function(original)
            return function(...) return redirectCommand(original(...)) end
        end)
    end
    local function speedBonus() return S.SpeedBoost and 16 * (S.SpeedMultiplier - 1) * correctionScale or 0 end
    for _, name in ipairs({"GetJogWalkSpeed", "GetRunWalkSpeed"}) do
        patch(M.ActionMovement, name, function(original)
            return function(base, carrying)
                return original(base, carrying and not S.NoBallSlowdown) + speedBonus()
            end
        end)
    end
    patch(M.ActionMovement, "GetChargingWalkSpeed", function(original)
        return function(base, carrying)
            if S.NoKickSlow then
                return M.Sprint.IsSprinting() and M.ActionMovement.GetRunWalkSpeed(base, carrying) or M.ActionMovement.GetJogWalkSpeed(base, carrying)
            end
            return original(base, carrying)
        end
    end)
    patch(M.Controllers, "SetMoveCommand", function(original)
        return function(ch, direction, ...)
            if Hub.Alive and ch == LP.Character then
                if smartDodgeIntent and os.clock() < smartDodgeUntil then
                    direction = smartDodgeIntent
                elseif moveIntent and S.AutoPlay then
                    direction = moveIntent
                end
            end
            return original(ch, direction, ...)
        end
    end)
    local function tackleDirection()
        local rp, pos = root(), ballPosition()
        if not rp or not pos then return nil end
        local ballOwner = owner()
        for _, actor in ipairs(cachedActors) do
            if actor.Id == ballOwner then
                if not actor.Enemy then return nil end
                pos = actor.Root.Position + M.Motion.GetVelocity(actor.Character) * 0.18
                break
            end
        end
        return unit(flat(pos - rp.Position))
    end
    patch(M.Controllers, "GetMoveCommand", function(original)
        return function(ch, ...)
            if Hub.Alive and ch == LP.Character then
                if diveIntent then return diveIntent end
                if smartDodgeIntent and os.clock() < smartDodgeUntil then return smartDodgeIntent end
                if S.TackleAssist and (tackleIntent or M.SlideInput.IsSlideTackling()) then
                    return tackleDirection() or original(ch, ...)
                end
                if S.AutoPlay and moveIntent then return moveIntent end
            end
            return original(ch, ...)
        end
    end)
    patch(M.SlideInput, "HandleInputBegan", function(original)
        return function(input, processed, ...)
            tackleIntent = S.TackleAssist and not processed and M.Controls.IsInput("Tackle", input)
            local result = table.pack(pcall(original, input, processed, ...))
            tackleIntent = nil
            if not result[1] then error(result[2]) end
            return table.unpack(result, 2, result.n)
        end
    end)
    local function silentRay(ray, itemId)
        if not S.SilentAim or type(ray) ~= "table" or typeof(ray.Origin) ~= "Vector3" then return ray end
        if itemId ~= "flintlock" and itemId ~= "freezeGun" and itemId ~= "shotgun" and itemId ~= "rocketPunch" then return ray end
        local camera = workspace.CurrentCamera
        if not camera then return ray end
        local mouse, target, best = UserInputService:GetMouseLocation(), nil, math.huge
        for _, actor in ipairs(cachedActors) do
            if actor.Enemy then
                local p, visible = camera:WorldToViewportPoint(actor.Root.Position)
                if visible then
                    local distance = (Vector2.new(p.X, p.Y) - mouse).Magnitude
                    if distance < best then target, best = actor, distance end
                end
            end
        end
        if not target then return ray end
        local copy = table.clone(ray)
        local lead = itemId == "rocketPunch" and math.clamp((target.Root.Position - ray.Origin).Magnitude / 160, 0, 0.5) or 0
        copy.Direction = unit(target.Root.Position + M.Motion.GetVelocity(target.Character) * lead - ray.Origin)
        copy.ClientHit, copy.TargetPosition = nil, nil
        return copy
    end
    patch(M.ItemCommands, "FireEquipped", function(original)
        return function(ray, shotTime, actionId, itemId, ...)
            return original(silentRay(ray, itemId), shotTime, actionId, itemId, ...)
        end
    end)
    patch(M.ItemCommands, "ContinueGunSequence", function(original)
        return function(ray, shotTime, actionId, shotIndex, itemId, ...)
            return original(silentRay(ray, itemId), shotTime, actionId, shotIndex, itemId, ...)
        end
    end)
    local goalRemote = RS.Remotes.Ball:FindFirstChild("GoalAnnouncement")
    if goalRemote then
        connect(goalRemote.OnClientEvent, function()
            goalPauseUntil = os.clock() + math.max(3.5, safe("goal replay duration", M.Match.GetGoalReplaySeconds) or 3.5)
            fakeBaitState, smartDodgeIntent, forcedShotTarget = nil, nil, nil
            stopOwnedInputs()
            moveIntent = ZERO
            local ch = LP.Character
            if ch then safe("goal movement stop", M.Controllers.SetMoveCommand, ch, ZERO, false) end
        end)
    end
    local function updateGoalEffectRelay()
        restoreGoalEffects()
        if S.GoalEffect == "Default" then return end
        assert(goalRemote and type(getconnections) == "function", "Goal effect listener control is unavailable")
        local callbacks = {}
        for _, connection in ipairs(getconnections(goalRemote.OnClientEvent)) do
            local fn = connection.Function
            local ok, scriptEnv = pcall(function() return fn and getfenv(fn) end)
            if ok and scriptEnv and scriptEnv.script == RS.Client.Gameplay.Gameplay and connection.Enabled ~= false then
                connection:Disable()
                table.insert(disabledGoalEffects, connection)
                table.insert(callbacks, fn)
            end
        end
        assert(#callbacks > 0, "Goal announcement listener could not be identified")
        goalEffectRelay = connect(goalRemote.OnClientEvent, function(data)
            if type(data) == "table" and S.GoalEffect ~= "Default" and
                (data.ScorerUserId == LP.UserId or data.ScorerName == LP.Name or data.ScorerName == LP.DisplayName) then
                data = table.clone(data)
                data.EffectName = S.GoalEffect
            end
            for _, callback in ipairs(callbacks) do safe("goal effect", callback, data) end
        end)
    end
    local correctionRemote = RS.Remotes.Characters:FindFirstChild("MovementCorrection")
    if correctionRemote then
        connect(correctionRemote.OnClientEvent, function(ch)
            if ch == LP.Character then
                Hub.Stats.Corrections += 1
                if not S.IgnorePositionCorrections then correctionScale = math.max(0, correctionScale - 0.25) end
            end
        end)
    end
    local function updateCorrectionBlock(enabled)
        restoreCorrections()
        if not enabled or not correctionRemote then return end
        assert(type(getconnections) == "function", "This executor does not support correction listener control")
        for _, connection in ipairs(getconnections(correctionRemote.OnClientEvent)) do
            local fn = connection.Function
            local ok, scriptEnv = pcall(function() return fn and getfenv(fn) end)
            if ok and scriptEnv and scriptEnv.script == RS.Client.Player.CharacterReplication and connection.Enabled ~= false then
                connection:Disable()
                table.insert(disabledCorrections, connection)
            end
        end
        assert(#disabledCorrections > 0, "Movement correction listener could not be identified")
    end
    local autoKeys = {"AutoDribble", "AutoPass", "TackleAssist", "AutoSprint", "InfiniteStamina", "NoBallSlowdown", "NoKickSlow", "SpeedBoost", "TackleSpeed", "ShotRedirect", "VolleyAssist", "AutoGoalkeeper"}
    local function change(key, value)
        if not Hub.Alive then return end
        if key == "AutoPlay" and value ~= S.AutoPlay then
            if value then
                autoSnapshot = {}
                for _, name in ipairs(autoKeys) do autoSnapshot[name] = S[name]; Hub:Set(name, true) end
            else
                stopOwnedInputs()
                if autoSnapshot then
                    local snapshot = autoSnapshot; autoSnapshot = nil
                    for name, old in pairs(snapshot) do Hub:Set(name, old) end
                end
            end
        end
        if key == "AutoSprint" and value ~= S.AutoSprint then
            if value then sprintSnapshot = M.Sprint.IsSprintButtonToggled()
            elseif sprintSnapshot ~= nil then
                if M.Sprint.IsSprintButtonToggled() ~= sprintSnapshot then M.Sprint.ToggleSprintButton() end
                sprintSnapshot = nil
            end
        end
        S[key] = value
        shotPlan = nil
        if key == "InfiniteStamina" then M.Sprint.SetUnlimitedStamina(KEY, value) end
        if key == "GoalEffect" then
            local ok, err = pcall(updateGoalEffectRelay)
            if not ok then
                restoreGoalEffects(); S.GoalEffect = "Default"
                if Hub.Controls.GoalEffect then Hub.Controls.GoalEffect:Set("Default", true) end
                report(key, err)
            end
        end
        if key == "IgnorePositionCorrections" then
            local ok, err = pcall(updateCorrectionBlock, value)
            if not ok then S[key] = false; if Hub.Controls[key] then Hub.Controls[key]:Set(false, true) end; report(key, err) end
        end
        if key == "HitboxExpander" and not value then restoreHitboxes() end
        if key == "TackleSpeed" or key == "TackleSpeedMultiplier" then
            local mult = S.TackleSpeed and S.TackleSpeedMultiplier or 1
            M.Slide.Constants.Distance, M.Slide.Constants.StartupDashDistance = originalTackleDistance * mult, originalTackleStartup * mult
        end
    end
    function Hub:Set(key, value)
        if setthreadidentity then setthreadidentity(8) end
        assert(S[key] ~= nil, "Unknown setting: " .. tostring(key))
        change(key, value)
        if setthreadidentity then setthreadidentity(8) end
        if self.Controls[key] then self.Controls[key]:Set(S[key], true) end
    end
    local function toggle(tab, name, key, description)
        Hub.Controls[key] = tab:CreateToggle({ name = name, flag = key, value = S[key], description = description,
            callback = function(value) safe(key, change, key, value) end })
    end
    local function slider(tab, name, key, min, max, step, suffix)
        Hub.Controls[key] = tab:CreateSlider({ name = name, flag = key, value = S[key], range = { min, max }, increment = step, suffix = suffix,
            callback = function(value) safe(key, change, key, value) end })
    end
    local function dropdown(tab, name, key, options)
        Hub.Controls[key] = tab:CreateDropdown({ name = name, flag = key, value = S[key], options = options,
            callback = function(value) safe(key, change, key, value) end })
    end
    local ballTab = window:CreateTab({name = "Ball Control"})
    toggle(ballTab, "Auto Play", "AutoPlay", "Joins a team and controls movement and ball actions. Restores assist settings when stopped.")
    toggle(ballTab, "Auto Dribble", "AutoDribble")
    slider(ballTab, "Kick Prediction Threshold", "KickPredictionThreshold", 0, 0.3, 0.01, "s")
    toggle(ballTab, "Auto Pass", "AutoPass", "Responds to teammate requests and lobs over blocked lanes.")
    toggle(ballTab, "Tackle Assist", "TackleAssist")
    toggle(ballTab, "Smart Dodge", "SmartDodge", "Dodges approaching tackles and steers away from the threat.")
    toggle(ballTab, "Join Friend Team", "AutoJoinFriendTeam", "Prefers a friend's team when joining; falls back to the other team if it is full.")
    toggle(ballTab, "Recover Loose Ball", "LooseBallTeleport", "Recovers a slow, unowned stuck ball after a short delay.")
    local movementTab = window:CreateTab({name = "Movement"})
    toggle(movementTab, "Auto Sprint", "AutoSprint")
    toggle(movementTab, "Infinite Stamina", "InfiniteStamina")
    toggle(movementTab, "No Ball Slowdown", "NoBallSlowdown")
    toggle(movementTab, "No Kick Slow", "NoKickSlow")
    toggle(movementTab, "Speed Boost", "SpeedBoost")
    slider(movementTab, "Speed Multiplier", "SpeedMultiplier", 1, 2, 0.05, "x")
    toggle(movementTab, "Ignore Position Corrections", "IgnorePositionCorrections", "Disables the identified client correction listener; server validation remains active.")
    toggle(movementTab, "Tackle Speed", "TackleSpeed")
    slider(movementTab, "Tackle Speed Multiplier", "TackleSpeedMultiplier", 1, 1.5, 0.05, "x")
    local shooting = window:CreateTab({name = "Shooting"})
    toggle(shooting, "Shot Redirect", "ShotRedirect")
    toggle(shooting, "Auto Curve", "AutoCurve")
    slider(shooting, "Adaptive Curve Strength", "AdaptiveCurveStrength", 0, 1, 0.05)
    slider(shooting, "Redirect Distance", "RedirectDistance", 1, 300, 1, " studs")
    slider(shooting, "Supercharge Redirect Distance", "SuperchargeRedirectDistance", 1, 300, 1, " studs")
    dropdown(shooting, "Shot Target Picker", "ShotTargetPicker", {"Adaptive", "Low", "High", "Center"})
    dropdown(shooting, "Shot Side", "ShotSide", {"Best", "Left", "Right"})
    toggle(shooting, "Shot Target Marker", "ShotTargetMarker")
    toggle(shooting, "Volley Assist", "VolleyAssist")
    slider(shooting, "Volley Assist Distance", "VolleyAssistDistance", 1, 300, 1, " studs")
    toggle(shooting, "Fake Shot Bait", "FakeShotBait", "Banks the first shot off a nearby wall, then takes the real shot after you regain possession.")
    toggle(shooting, "Automatic Bicycle Kick", "AutoBicycleKick", "Chance-based rainbow flick, jump and volley when a shot is requested.")
    slider(shooting, "Bicycle Kick Chance", "BicycleKickChance", 0, 100, 1, "%")
    local keeperTab = window:CreateTab({name = "Goalkeeper"})
    toggle(keeperTab, "Auto Goalkeeper", "AutoGoalkeeper")
    slider(keeperTab, "Dive Timing Threshold", "DiveTimingThreshold", 0.04, 0.2, 0.01, "s")
    slider(keeperTab, "Loose Ball Dive Distance", "LooseBallDiveDistance", 0, 30, 1, " studs")
    slider(keeperTab, "Slow Shot Dive Threshold", "SlowShotDiveThreshold", 0.1, 0.6, 0.01, "s")
    toggle(keeperTab, "Backward Dive", "BackwardDive")
    local aimTab = window:CreateTab({name = "Silent Aim"})
    toggle(aimTab, "Silent Aim", "SilentAim", "Uses the nearest on-screen opponent for guns and Rocket Punch.")
    local hitboxTab = window:CreateTab({name = "Hitbox Expander"})
    toggle(hitboxTab, "Hitbox Expander", "HitboxExpander")
    slider(hitboxTab, "HumanoidRootPart Size", "HitboxSize", 2, 30, 1, " studs")
    slider(hitboxTab, "Hitbox Transparency", "HitboxTransparency", 0, 1, 0.05)
    local predictionTab = window:CreateTab({name = "Ball Prediction"})
    toggle(predictionTab, "Landing Predictor", "LandingPredictor")
    toggle(predictionTab, "Ball Trajectory", "BallTrajectory")
    slider(predictionTab, "Prediction Length", "PredictionLength", 0.5, 5, 0.1, "s")
    local pitchTab = window:CreateTab({name = "On the Pitch"})
    toggle(pitchTab, "Redirect Distance ESP", "RedirectDistanceESP")
    toggle(pitchTab, "Tackle Warning", "TackleWarning")
    toggle(pitchTab, "Keeper Reach", "KeeperReach")
    toggle(pitchTab, "Save Marker", "SaveMarker")
    local itemTab = window:CreateTab({name = "Items"})
    toggle(itemTab, "Auto Use Tools", "AutoToolUse", "Automatically equips available item slots and activates the equipped item.")
    local function catalog(category)
        local choices = {"Default"}
        for _, asset in ipairs(M.Catalog.GetFolder(category):GetChildren()) do
            if asset.Name ~= "Default" then table.insert(choices, asset.Name) end
        end
        table.sort(choices)
        return choices
    end
    local effectTab = window:CreateTab({name = "Goal Effect"})
    dropdown(effectTab, "Goal Effect", "GoalEffect", catalog(M.Catalog.Categories.GoalEffects))
    effectTab:CreateText({text = "Cosmetic changes are visible on your client."})
    local skinTab = window:CreateTab({name = "Ball Skin"})
    dropdown(skinTab, "Ball Skin", "BallSkin", catalog(M.Catalog.Categories.Balls))
    local menuTab = window:CreateTab({name = "Menu"})
    Hub.Controls.MenuKeybind = menuTab:CreateKeybind({ name = "Menu Keybind", flag = "MenuKeybind", value = Enum.KeyCode.End,
        callback = function() window:ToggleHide() end, onChanged = function(key) S.MenuKeybind = key end })
    menuTab:CreateButton({name = "Save Settings", callback = function() window:Save() end})
    menuTab:CreateButton({name = "Load Settings", callback = function() window:Load() end})
    menuTab:CreateButton({name = "Unload", callback = function() Hub:Unload() end})
    statusText = menuTab:CreateText({name = "Client Status", text = "Initializing"})
    local interfaceTab = window:CreateTab({name = "Interface"})
    toggle(interfaceTab, "Watermark", "Watermark")
    toggle(interfaceTab, "Keybinds", "Keybinds")
    local binds = {{"Auto Play", "AutoPlay", Enum.KeyCode.F6}, {"Shot Redirect", "ShotRedirect", Enum.KeyCode.F7}, {"Auto Goalkeeper", "AutoGoalkeeper", Enum.KeyCode.F8}}
    local bindHandles = {}
    for _, entry in ipairs(binds) do
        bindHandles[entry[2]] = interfaceTab:CreateKeybind({name = entry[1] .. " Key", value = entry[3], flag = entry[2] .. "Key",
            callback = function() Hub:Set(entry[2], not S[entry[2]]) end })
    end

    local function canAct(name)
        return M.Controls.IsAvailable(name) and not M.Controls.IsOnCooldown(name)
    end
    local function beginShot(volley, duration, target)
        if shotInput or M.Shoot.IsCharging() or not canAct("Kick") then return false end
        local input = M.Controls.CreateInput("Kick")
        shotInput = input
        if target then forcedShotTarget = target end
        internalShot = true
        local ok, err = pcall(M.Shoot.HandleInputBegan, input, false)
        internalShot = false
        if not ok then
            shotInput = nil
            if target and forcedShotTarget == target then forcedShotTarget = nil end
            error(err)
        end
        duration = duration or (volley and 0.08 or M.Shot.Constants.Kick.MaximumChargeSeconds)
        task.delay(duration, function()
            if Hub.Alive and shotInput == input then
                safe("kick release", M.Shoot.HandleInputEnded, input)
                shotInput = nil
            end
            if target and forcedShotTarget == target then forcedShotTarget = nil end
        end)
        Hub.Stats.Actions += 1
        return true
    end
    local function tryBicycleKick()
        if not S.AutoBicycleKick or bicycleBusy or not ownBall() or M.Keeper.IsGoalkeeper() or M.GoalReplay.IsActive() then return false end
        if S.BicycleKickChance <= 0 or math.random(1, 100) > S.BicycleKickChance or not canAct("Kick") then return false end
        local rp = root()
        if not rp then return false end
        local camera = workspace.CurrentCamera
        local direction = unit(flat(rp.CFrame.LookVector))
        local command = M.Commands.RainbowFlick({
            ShotTime = M.Smooth.GetSmoothedServerTime(),
            AimDirection = {
                Origin = rp.Position,
                Direction = direction,
                CameraCFrame = camera and camera.CFrame or rp.CFrame,
                IsAirborne = false,
            },
        })
        local ok, err = pcall(M.Protocol.Send, command)
        if not ok then report("bicycle flick", err); return false end
        bicycleBusy = true
        task.spawn(function()
            task.wait(0.12)
            if not Hub.Alive or not S.AutoBicycleKick then bicycleBusy = false; return end
            safe("bicycle jump", M.Movement.Jump)
            local deadline = os.clock() + 1.25
            repeat task.wait(0.03) until not Hub.Alive or M.Volley.IsAvailable(LP.Character) or os.clock() >= deadline
            if Hub.Alive and S.AutoBicycleKick and M.Volley.IsAvailable(LP.Character) then
                safe("bicycle volley", beginShot, true, 0.12)
            end
            task.delay(0.35, function() bicycleBusy = false end)
        end)
        return true
    end
    patch(M.Shoot, "HandleInputBegan", function(original)
        return function(input, processed, ...)
            if not internalShot and not processed and S.AutoBicycleKick and ownBall() and tryBicycleKick() then return end
            return original(input, processed, ...)
        end
    end)
    local function passTo(actor)
        if not actor or not actor.Root.Parent or actor.Enemy or not ownBall() or shotInput or passInput or M.Shoot.IsCharging() or not canAct("Pass") then return end
        if os.clock() - lastPass < 1.1 then return end
        local origin, target = ballPosition(), actor.Root.Position + M.Motion.GetVelocity(actor.Character) * 0.3
        if not origin then return end
        local direction = target - origin
        if direction.Magnitude < 4 then return end
        local blocked = false
        for _, other in ipairs(cachedActors) do
            if other.Enemy then
                local along = math.clamp((other.Root.Position - origin):Dot(direction) / direction:Dot(direction), 0, 1)
                if (other.Root.Position - origin - direction * along).Magnitude < 5 then blocked = true; break end
            end
        end
        forcedPass = {Actor = actor, Target = target, Lob = blocked}
        local input = M.Controls.CreateInput(blocked and "Lob" or "Pass")
        passInput, lastPass = input, os.clock()
        M.Pass.HandleInputBegan(input, false)
        task.delay(blocked and 0.55 or 0.2, function()
            if Hub.Alive and passInput == input then
                safe("pass release", M.Pass.HandleInputEnded, input)
                passInput, forcedPass = nil, nil
            end
        end)
        Hub.Stats.Passes += 1
    end
    patch(M.Commands, "AssistedPass", function(original)
        return function(data)
            if forcedPass then
                data = table.clone(data or {})
                data.TargetUserId, data.TargetPosition = forcedPass.Actor.Id, forcedPass.Target
                data.TargetData = {TargetUserId = forcedPass.Actor.Id, IsGuaranteedClosePass = false}
            end
            return original(data)
        end
    end)
    patch(M.Commands, "Kick", function(original)
        return function(data)
            if forcedPass and data and data.PassType ~= M.Commands.PassTypes.Shot then
                data = table.clone(data)
                local origin = ballPosition() or root().Position
                data.TargetUserId, data.TargetPosition = forcedPass.Actor.Id, forcedPass.Target
                data.TargetData = {TargetUserId = forcedPass.Actor.Id, IsGuaranteedClosePass = false}
                data.AimDirection = {Origin = origin, Direction = unit(forcedPass.Target - origin + (forcedPass.Lob and Vector3.new(0, 14, 0) or ZERO))}
            end
            return original(data)
        end
    end)
    local passRemote = RS.Remotes.Ball:FindFirstChild("CallForPass")
    if passRemote then
        connect(passRemote.OnClientEvent, function(userId)
            if not S.AutoPass or not ownBall() then return end
            for _, actor in ipairs(cachedActors) do
                if actor.Id == userId and not actor.Enemy then
                    task.delay(0.18, function() if Hub.Alive and S.AutoPass then safe("auto pass", passTo, actor) end end)
                    break
                end
            end
        end)
    end
    local function threatScore(actor)
        local rp = root()
        if not rp or not actor.Enemy then return nil end
        local relative = actor.Root.Position - rp.Position
        if relative.Magnitude > 24 then return nil end
        local relativeVelocity = M.Motion.GetVelocity(actor.Character) - M.Motion.GetVelocity(LP.Character)
        local predicted = relative + relativeVelocity * math.max(S.KickPredictionThreshold, 0.18)
        local sliding = M.Slide.GetSlidingUntil(actor.Character) ~= nil
        local charging = M.Charge.IsCharging(actor.Actor)
        local approaching = relative:Dot(relativeVelocity) < -4
        if not sliding and not charging and not (approaching and relative.Magnitude < 9) then return nil end
        if predicted.Magnitude > 18 and not sliding then return nil end
        return (24 - math.min(24, predicted.Magnitude)) + (sliding and 12 or 0) + (charging and 6 or 0) + (approaching and 3 or 0)
    end
    local function threat(actor) return threatScore(actor) ~= nil end
    local function smartDodge(actor, now)
        local rp = root()
        if not rp or not actor then return end
        local away = unit(flat(rp.Position - actor.Root.Position))
        local side = Vector3.new(-away.Z, 0, away.X)
        local velocity = flat(M.Motion.GetVelocity(actor.Character))
        if velocity.Magnitude > 1 and side:Dot(velocity) > 0 then side = -side end
        smartDodgeIntent = unit(away * 0.78 + side * 0.62, away)
        smartDodgeUntil = now + 0.55
        local input = M.Controls.CreateInput("Dribble")
        safe("smart dodge", M.Dodge.HandleInputBegan, input, false)
        task.delay(0.12, function()
            if Hub.Alive then safe("smart dodge release", M.Dodge.HandleInputEnded, input) end
        end)
        lastDribble = now
        Hub.Stats.Dribbles += 1
    end
    local function updatePrediction()
        table.clear(trajectory)
        landing, savePlan, sampleState = nil, nil, nil
        if not (S.BallTrajectory or S.LandingPredictor or S.AutoGoalkeeper or S.AutoPlay) then return end
        local state, world = M.Renderer.GetAuthoritativeMovementState()
        if not state then return end
        local now = M.Smooth.GetSmoothedServerTime()
        sampleState = M.Physics.GetStateAtTime(table.clone(state), now, world)
        sampleTime, sampleWorld = now, world
        local horizon = math.max(S.PredictionLength, S.AutoGoalkeeper and 2 or 0)
        local step = horizon / 64
        local simulated = table.clone(sampleState)
        for i = 0, 64 do
            if i > 0 then simulated = M.Physics.GetStateAtTime(simulated, now + i * step, world) end
            trajectory[i + 1] = { Position = simulated.Position, Time = i * step, Velocity = simulated.Velocity }
            if not landing and simulated.Mode ~= "Airborne" then landing = simulated.Position end
        end
        if S.LandingPredictor and not landing then
            local hit = M.Physics.GetLanding(table.clone(sampleState), world, now, 5)
            if hit then landing = hit.Position end
        end
    end
    local function predictShooterTarget(goal)
        local ballOwner = owner()
        if not ballOwner then return nil end
        local shooter
        for _, actor in ipairs(cachedActors) do
            if actor.Id == ballOwner and actor.Enemy then shooter = actor; break end
        end
        if not shooter then return nil end
        local origin = shooter.Root.Position + Vector3.new(0, 1.5, 0)
        local distance = (goal.Position - origin).Magnitude
        local charging = M.Charge.IsCharging(shooter.Actor)
        if not charging and distance > 70 then return nil end
        local toGoal = unit(flat(goal.Position - origin))
        local facing = unit(flat(shooter.Root.CFrame.LookVector), toGoal)
        local velocity = flat(M.Motion.GetVelocity(shooter.Character))
        if velocity.Magnitude > 3 then facing = unit(facing * 0.82 + velocity.Unit * 0.18, toGoal) end
        local direction = unit(facing * (charging and 0.9 or 0.68) + toGoal * (charging and 0.1 or 0.32), toGoal)
        local localOrigin = goal.CFrame:PointToObjectSpace(origin)
        local localDirection = goal.CFrame:VectorToObjectSpace(direction)
        if math.abs(localDirection.Z) < 0.001 then return nil end
        local targetZ = localOrigin.Z >= 0 and goal.Size.Z * 0.5 or -goal.Size.Z * 0.5
        local t = (targetZ - localOrigin.Z) / localDirection.Z
        if t <= 0 then return nil end
        local hit = localOrigin + localDirection * t
        local x = math.clamp(hit.X, -goal.Size.X * 0.45, goal.Size.X * 0.45)
        local y = math.clamp(hit.Y, -goal.Size.Y * 0.42, goal.Size.Y * 0.42)
        return goal.CFrame:PointToWorldSpace(Vector3.new(x, y, targetZ))
    end
    local function updateKeeper()
        if not S.AutoGoalkeeper or not M.Keeper.IsGoalkeeper() or ownBall() then keeperAnticipation = nil; return end
        local rp, ownGoal = root(), goals()
        if not rp or not ownGoal then keeperAnticipation = nil; return end
        keeperAnticipation = predictShooterTarget(ownGoal)
        if not sampleState then return end
        local incoming = false
        for _, point in ipairs(trajectory) do
            local p = ownGoal.CFrame:PointToObjectSpace(point.Position)
            if math.abs(p.X) < ownGoal.Size.X / 2 + 1 and math.abs(p.Y) < ownGoal.Size.Y / 2 + 1 and math.abs(p.Z) < ownGoal.Size.Z / 2 + 2 then incoming = true; break end
        end
        local now, best = os.clock(), nil
        for _, point in ipairs(trajectory) do
            if point.Time > 0.03 and point.Time <= M.Dive.Constants.SaveWindowSeconds then
                local offset = point.Position - rp.Position
                local distance = flat(offset).Magnitude
                local backward = flat(offset):Dot(flat(rp.CFrame.LookVector)) < -1
                local ground = M.Field.GetGroundYAt(point.Position)
                local canReach = distance <= M.Dive.Constants.Distance + M.Dive.Constants.SaveReachStuds and point.Position.Y - ground <= M.Dive.Constants.MaximumSaveHeight
                if canReach and (incoming or distance <= S.LooseBallDiveDistance) and (S.BackwardDive or not backward) then
                    local needed = math.clamp(distance / (M.Dive.Constants.Distance / M.Dive.Constants.DurationSeconds), 0.03, 0.8)
                    local margin = point.Time - needed
                    local anticipationError = keeperAnticipation and flat(point.Position - keeperAnticipation).Magnitude or 0
                    local score = point.Time + anticipationError * 0.002
                    if margin >= -0.14 and (not best or score < best.Score) then
                        best = {Position = point.Position, Time = point.Time, Margin = margin, Direction = unit(flat(offset)), Incoming = incoming, Score = score}
                    end
                end
            end
        end
        savePlan = best
        if not best or now - lastDive < M.Dive.Constants.RepeatDelaySeconds then return end
        local slow = sampleState.Velocity.Magnitude < 40
        local threshold = slow and S.SlowShotDiveThreshold or math.max(S.DiveTimingThreshold, best.Incoming and 0.1 or S.DiveTimingThreshold)
        if best.Margin <= threshold then
            if best.Position.Y - rp.Position.Y > 4 and best.Time > 0.16 then safe("keeper jump", M.Movement.Jump) end
            diveIntent = best.Direction
            local success = M.Keeper.Dive()
            diveIntent = nil
            if success then lastDive = now; Hub.Stats.Dives += 1 end
        end
    end
    local function pickJoinTeam()
        local counts = {Team1 = 0, Team2 = 0}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP then
                local teamName = M.Teams.GetActorTeamName(player)
                if counts[teamName] then counts[teamName] += 1 end
            end
        end
        if S.AutoJoinFriendTeam then
            local maximum = M.Match.Constants.MaximumRealTeamMembers or 5
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP then
                    local ok, isFriend = pcall(LP.IsFriendsWith, LP, player.UserId)
                    if ok and isFriend then
                        local friendTeam = M.Teams.GetActorTeamName(player)
                        if counts[friendTeam] then
                            if counts[friendTeam] < maximum then return friendTeam end
                            return friendTeam == "Team1" and "Team2" or "Team1"
                        end
                    end
                end
            end
        end
        return counts.Team1 <= counts.Team2 and "Team1" or "Team2"
    end
    local function updateAutoTool(now)
        if not S.AutoToolUse or now - lastToolUse < 0.75 or M.GoalReplay.IsActive() then return end
        lastToolUse = now
        if M.ItemUse.IsEquipped() then
            safe("tool hold", M.ItemUse.BeginActivationHold)
            task.delay(0.06, function()
                if Hub.Alive and S.AutoToolUse then
                    safe("tool activate", M.ItemUse.ActivateEquipped)
                    safe("tool release", M.ItemUse.ReleaseActivationHold)
                end
            end)
            return
        end
        autoToolSlot = autoToolSlot % M.ItemCommands.Constants.SlotCount + 1
        toolActionId += 1
        safe("tool equip", RS.Remotes.Items.Request.FireServer, RS.Remotes.Items.Request, M.ItemCommands.UseSlot(autoToolSlot, toolActionId))
        task.delay(0.16, function()
            if Hub.Alive and S.AutoToolUse and M.ItemUse.IsEquipped() then
                safe("tool hold", M.ItemUse.BeginActivationHold)
                task.delay(0.06, function()
                    if Hub.Alive and S.AutoToolUse then
                        safe("tool activate", M.ItemUse.ActivateEquipped)
                        safe("tool release", M.ItemUse.ReleaseActivationHold)
                    end
                end)
            end
        end)
    end
    local function updateLooseBall(now)
        local ballOwner = owner()
        if ballOwner ~= nil then looseBallSince = nil; return end
        if not looseBallSince then looseBallSince = now; return end
        if not S.LooseBallTeleport or now - looseBallSince < 0.75 or now - lastLooseTeleport < 1.5 then return end
        local rp = root()
        if not rp then return end
        local state = M.Renderer.GetMovementState()
        if state and state.Velocity and state.Velocity.Magnitude > 8 then return end
        local remote = RS.Remotes.Ball:FindFirstChild("DebugTeleport")
        if not remote then return end
        lastLooseTeleport = now
        local target = rp.Position + unit(flat(rp.CFrame.LookVector)) * 3 + Vector3.new(0, 2, 0)
        safe("loose ball recover", remote.FireServer, remote, target)
    end
    local function findWallTarget(origin, ownGoal, opponentGoal)
        local forward = unit(flat(opponentGoal.Position - ownGoal.Position))
        local side = Vector3.new(-forward.Z, 0, forward.X)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LP.Character, visuals, M.Renderer.GetBall()}
        local best
        for _, sign in ipairs({-1, 1}) do
            local direction = side * sign
            local result = workspace:Raycast(origin + Vector3.new(0, 1, 0), direction * 180, params)
            if result and result.Distance > 8 and (not best or result.Distance < best.Distance) then
                best = {Position = result.Position - direction * 1.5, Distance = result.Distance}
            end
        end
        return best and best.Position or origin + side * 40
    end
    local function updateAutomation()
        local rp, now, team = root(), os.clock(), myTeam()
        if not rp then return end

        local ballOwner = owner()
        if ballOwner ~= previousOwner then
            previousOwner = ballOwner
            if ballOwner == LP.UserId then
                ballOwnedSince = now
                looseBallSince = nil
            elseif ballOwner == nil then
                looseBallSince = now
            else
                looseBallSince = nil
            end
        end

        if not team then
            if S.AutoPlay then
                moveIntent = ZERO
                M.Controllers.SetMoveCommand(LP.Character, ZERO, false)
            end
            if (S.AutoPlay or S.AutoJoinFriendTeam) and now - lastJoin > 5 then
                lastJoin = now
                RS.Remotes.Match.Action:FireServer(M.Match.Constants.NewModeName, pickJoinTeam())
            end
            return
        end

        if now < goalPauseUntil or M.GoalReplay.IsActive() then
            if S.AutoPlay then
                moveIntent = ZERO
                M.Controllers.SetMoveCommand(LP.Character, ZERO, false)
            end
            return
        end

        updateAutoTool(now)
        updateLooseBall(now)

        if S.AutoSprint and not M.Keeper.IsGoalkeeper() and M.Sprint.IsSprintButtonUsable() and not M.Sprint.IsSprintButtonToggled() then M.Sprint.ToggleSprintButton() end

        if (S.AutoDribble or S.SmartDodge) and ownBall() and now - lastDribble > 0.2 and canAct("Dribble") then
            local best, score
            for _, actor in ipairs(cachedActors) do
                local value = threatScore(actor)
                if value and (not score or value > score) then best, score = actor, value end
            end
            if best then smartDodge(best, now) end
        end

        if S.VolleyAssist and not ownBall() and now - lastVolley > 0.8 and M.Volley.IsAvailable(LP.Character) then
            lastVolley = now
            beginShot(true)
        end

        if fakeBaitState then
            if ballOwner ~= LP.UserId then fakeBaitState.Released = true end
            if now - fakeBaitState.Started > 5 then
                fakeBaitState = nil
            elseif fakeBaitState.Released and ballOwner == LP.UserId and now - ballOwnedSince > 0.28 and not shotInput then
                fakeBaitState = nil
                lastShot = now
                if not tryBicycleKick() then beginShot(false) end
                return
            end
        end

        if not S.AutoPlay then return end
        local pos = ballPosition()
        local ownGoal, opponentGoal = goals()
        if not pos or not opponentGoal then moveIntent = ZERO; return end
        local destination
        if M.Keeper.IsGoalkeeper() then
            local tracked = keeperAnticipation or pos
            local localTarget = ownGoal.CFrame:PointToObjectSpace(tracked)
            destination = ownGoal.CFrame:PointToWorldSpace(Vector3.new(math.clamp(localTarget.X, -ownGoal.Size.X * 0.44, ownGoal.Size.X * 0.44), 0, -ownGoal.Size.Z / 2 - 4))
            if savePlan then destination = savePlan.Position end
            if ownBall() and now - lastPass > 2 then
                for _, actor in ipairs(cachedActors) do
                    if not actor.Enemy and not actor.Keeper then passTo(actor); break end
                end
            end
        elseif ownBall() then
            destination = opponentGoal.Position
            local readyToShoot = now - ballOwnedSince > 0.65 and not shotInput and not bicycleBusy
            if readyToShoot and not fakeBaitState and (pos - opponentGoal.Position).Magnitude < activeRange() and now - lastShot > 1.4 then
                lastShot = now
                if S.FakeShotBait then
                    local target = findWallTarget(pos, ownGoal, opponentGoal)
                    fakeBaitState = {Started = now, Released = false}
                    if not beginShot(false, 0.18, target) then fakeBaitState = nil end
                elseif not tryBicycleKick() then
                    beginShot(false)
                end
            end
            if not shotInput and not fakeBaitState then
                local nearest, score
                for _, actor in ipairs(cachedActors) do
                    if not actor.Enemy and not actor.Keeper and (actor.Root.Position - opponentGoal.Position).Magnitude + 20 < (rp.Position - opponentGoal.Position).Magnitude then
                        local value = (actor.Root.Position - opponentGoal.Position).Magnitude
                        if not score or value < score then nearest, score = actor, value end
                    end
                end
                if nearest and now - lastPass > 3 then passTo(nearest) end
            end
        else
            destination = pos
            if sampleState then
                local travel = math.clamp((pos - rp.Position).Magnitude / 26, 0, 1.2)
                local predicted = M.Physics.GetStateAtTime(table.clone(sampleState), sampleTime + travel, sampleWorld)
                destination = predicted.Position
            end
            if (pos - rp.Position).Magnitude < 19 and ballOwner and now - lastTackle > 3 and canAct("Tackle") then
                for _, actor in ipairs(cachedActors) do if actor.Id == ballOwner and actor.Enemy then
                    M.SlideInput.HandleInputBegan(M.Controls.CreateInput("Tackle"), false); lastTackle = now; break
                end end
            end
        end
        local delta = flat(destination - rp.Position)
        moveIntent = delta.Magnitude > 2 and delta.Unit or ZERO
        M.Controllers.SetMoveCommand(LP.Character, moveIntent, false)
    end
    local function updateCosmetics()
        local id = M.Renderer.GetMatchBallId()
        if S.BallSkin ~= "Default" and ownBall() then
            if not ballSkins[id] then ballSkins[id] = M.Renderer.GetSkinName(id) end
            if M.Renderer.GetSkinName(id) ~= S.BallSkin then M.Renderer.SetSkin(id, S.BallSkin) end
        else
            for ballId, name in pairs(ballSkins) do M.Renderer.SetSkin(ballId, name); ballSkins[ballId] = nil end
        end
    end
    local function updateHitboxes()
        local active = {}
        for _, actor in ipairs(cachedActors) do
            if S.HitboxExpander and actor.Enemy then
                local p = actor.Root
                active[p] = true
                if not originals[p] then originals[p] = {Size = p.Size, Transparency = p.Transparency, CanCollide = p.CanCollide, Massless = p.Massless} end
                p.Size, p.Transparency, p.CanCollide, p.Massless = Vector3.one * S.HitboxSize, S.HitboxTransparency, false, true
            end
        end
        for p, saved in pairs(originals) do
            if not active[p] then
                if p.Parent then p.Size, p.Transparency, p.CanCollide, p.Massless = saved.Size, saved.Transparency, saved.CanCollide, saved.Massless end
                originals[p] = nil
            end
        end
    end
    local function updateVisuals()
        for i, p in ipairs(segments) do
            local a, b = trajectory[i], trajectory[i + 1]
            if S.BallTrajectory and a and b and b.Time <= S.PredictionLength + 0.01 then line(p, a.Position, b.Position, 0.1, BLUE) else p.Transparency = 1 end
        end
        for i, p in ipairs(ring) do
            if S.LandingPredictor and landing then
                local center = M.Field.GetGroundPosition(landing, 0.12)
                local a, b = (i - 1) * math.pi / 16, i * math.pi / 16
                line(p, center + Vector3.new(math.cos(a) * 2.2, 0, math.sin(a) * 2.2), center + Vector3.new(math.cos(b) * 2.2, 0, math.sin(b) * 2.2), 0.1, GREEN)
            else p.Transparency = 1 end
        end
        local rp, pos = root(), ballPosition()
        local _, goal = goals()
        rangeLine.Transparency, shotMarker.Transparency, keeperZone.Transparency, saveMarker.Transparency = 1, 1, 1, 1
        if goal and rp then
            local origin = ownBall() and pos or rp.Position
            if origin and S.RedirectDistanceESP then
                line(rangeLine, M.Field.GetGroundPosition(origin, 0.12), M.Field.GetGroundPosition(goal.Position, 0.12), 0.16, (origin - goal.Position).Magnitude <= activeRange() and GREEN or RED)
            end
            if pos and S.ShotTargetMarker then
                local target = shotPlan and shotPlan.Display or pickTarget(pos, goal)
                shotMarker.Position, shotMarker.Size, shotMarker.Color, shotMarker.Transparency = target, Vector3.one * 0.85, GOLD, 0.1
            end
            if S.KeeperReach and S.ShotRedirect and M.Shoot.IsCharging() then
                local keeper = opponentKeeper(goal)
                if keeper then
                    local localPos = goal.CFrame:PointToObjectSpace(keeper.Root.Position)
                    local radius = math.min(goal.Size.X / 2, M.Dive.Constants.Distance + M.Dive.Constants.SaveReachStuds)
                    local left, right = math.max(-goal.Size.X / 2, localPos.X - radius), math.min(goal.Size.X / 2, localPos.X + radius)
                    keeperZone.Size, keeperZone.CFrame = Vector3.new(math.max(0.1, right - left), math.min(goal.Size.Y, M.Dive.Constants.MaximumSaveHeight), 0.12), goal.CFrame * CFrame.new((left + right) / 2, -1, -goal.Size.Z / 2)
                    keeperZone.Color, keeperZone.Transparency = RED, 0.72
                end
            end
        end
        if S.SaveMarker and S.AutoGoalkeeper and savePlan then
            saveMarker.Position, saveMarker.Size, saveMarker.Color, saveMarker.Transparency = savePlan.Position, Vector3.one, GREEN, 0.2
            saveText.Text = string.format("SAVE  %.2fs", savePlan.Time)
        else saveText.Text = "" end
        local seen = {}
        if S.TackleWarning and ownBall() then
            for _, actor in ipairs(cachedActors) do if threat(actor) then
                local h = highlights[actor.Character]
                if not h then
                    h = Instance.new("Highlight"); h.Adornee, h.FillColor, h.OutlineColor = actor.Character, RED, GOLD
                    h.FillTransparency, h.DepthMode, h.Parent = 0.65, Enum.HighlightDepthMode.AlwaysOnTop, visuals
                    highlights[actor.Character] = h
                end
                h.Enabled, seen[actor.Character] = true, true
            end end
        end
        for ch, h in pairs(highlights) do
            if not ch.Parent then h:Destroy(); highlights[ch] = nil else h.Enabled = seen[ch] == true end
        end
    end
    local elapsed, actorsElapsed, hudElapsed, frames, fps = 0, 0, 0, 0, 60
    connect(RunService.Heartbeat, function(dt)
        if not Hub.Alive then return end
        if window.unloaded then Hub:Unload(); return end
        elapsed += dt; actorsElapsed += dt; hudElapsed += dt; frames += 1
        correctionScale = math.min(1, correctionScale + dt * 0.025)
        if actorsElapsed >= 0.3 then
            actorsElapsed = 0
            safe("actors", refreshActors)
            safe("hitboxes", updateHitboxes)
            safe("cosmetics", updateCosmetics)
        end
        if elapsed >= 0.075 then
            elapsed = 0
            safe("prediction", updatePrediction)
            safe("goalkeeper", updateKeeper)
            safe("automation", updateAutomation)
            safe("visuals", updateVisuals)
        end
        if hudElapsed >= 0.5 then
            fps = math.floor(frames / hudElapsed + 0.5); frames, hudElapsed = 0, 0
            local teamName = myTeam() or "Lobby"
            if setthreadidentity then setthreadidentity(8) end
            watermark.Visible, keylist.Visible = S.Watermark, S.Keybinds
            watermark.Text = string.format("Illegal Soccer  |  %d FPS  |  %s", fps, teamName)
            local rows = {}
            for _, entry in ipairs(binds) do
                local handle = bindHandles[entry[2]]
                table.insert(rows, string.format("%s  %s  [%s]", handle.value and handle.value.Name or "-", entry[1], S[entry[2]] and "ON" or "OFF"))
            end
            keylist.Text = table.concat(rows, "\n")
            local count = 0; for _ in pairs(Hub.Errors) do count += 1 end
            statusText:Set(string.format("Place %d | %s | %d corrections | %d diagnostic errors", game.PlaceVersion, teamName, Hub.Stats.Corrections, count))
        end
    end)
    function Hub:Status()
        return {Alive = self.Alive, Version = game.PlaceVersion, Team = myTeam(), Stats = self.Stats,
            Errors = self.Errors, Actors = #cachedActors, Predictions = #trajectory, Landing = landing,
            SavePlan = savePlan, ShotPlan = shotPlan, KeeperAnticipation = keeperAnticipation,
            CorrectionListenersDisabled = #disabledCorrections}
    end
    Hub.PlanShot = planShot
    refreshActors()
    print("[IllegalSoccer] Ready. End: menu. F6: Auto Play. F7: Shot Redirect. F8: Auto Goalkeeper.")
end

local ok, failure = xpcall(initialize, debug.traceback)
if not ok then
    Hub:Unload()
    error("Illegal Soccer initialization failed: " .. tostring(failure))
end
return Hub
