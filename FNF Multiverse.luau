local env = getgenv()
local ServiceResolverURL = "https://raw.githubusercontent.com/ltseverydayyou/ltseverydayyou.github.io/refs/heads/main/ServiceResolver.luau"

local function loadServiceResolver()
	local cached = rawget(env, "__lt_service_resolver") or rawget(env, "ServiceResolver")
	if cached then
		return cached
	end
	local globalCached = rawget(_G, "ServiceResolver")
	if globalCached then
		return globalCached
	end
	local okSource, source = pcall(function()
		return game:HttpGet(ServiceResolverURL)
	end)
	if not okSource or type(source) ~= "string" or #source == 0 then
		error("ServiceResolver could not be downloaded")
	end
	local okCompile, factory = pcall(loadstring, source)
	if not okCompile or type(factory) ~= "function" then
		error("ServiceResolver could not be compiled")
	end
	local okResolver, resolver = pcall(factory)
	if not okResolver or type(resolver) ~= "table" then
		error("ServiceResolver could not be initialized")
	end
	pcall(rawset, env, "__lt_service_resolver", resolver)
	return resolver
end

local SR = loadServiceResolver()

local function getService(name)
	if type(SR.cs) == "function" and type(cloneref) == "function" then
		local ok, service = pcall(function()
			return SR.cs(name, cloneref)
		end)
		if ok and service then
			return service
		end
	end
	if type(SR.gs) == "function" then
		local ok, service = pcall(function()
			return SR.gs(name)
		end)
		if ok and service then
			return service
		end
	end
	if type(SR.GetService) == "function" then
		local ok, service = pcall(function()
			return SR:GetService(name)
		end)
		if ok and service then
			return service
		end
	end
	return nil
end

local Players = assert(getService("Players"), "Players service unavailable")
local ReplicatedStorage = assert(getService("ReplicatedStorage"), "ReplicatedStorage service unavailable")
local RunService = assert(getService("RunService"), "RunService service unavailable")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local GameEvent = ReplicatedStorage:WaitForChild("GameEvent")

local BackendAvailability = {
	Native = type(getsenv) == "function",
	VirtualInput = getService("VirtualInputManager") ~= nil,
	FireSignal = type(firesignal) == "function",
	GetGc = type(getgc) == "function",
}
local AvailableInputMethods = {}
if BackendAvailability.Native then
	AvailableInputMethods[#AvailableInputMethods + 1] = "Native"
end
if BackendAvailability.VirtualInput then
	AvailableInputMethods[#AvailableInputMethods + 1] = "Virtual Input"
	AvailableInputMethods[#AvailableInputMethods + 1] = "External"
end
if BackendAvailability.FireSignal then
	AvailableInputMethods[#AvailableInputMethods + 1] = "firesignal"
end
if BackendAvailability.GetGc then
	AvailableInputMethods[#AvailableInputMethods + 1] = "getgc"
end
if #AvailableInputMethods == 0 then
	AvailableInputMethods[1] = "Native"
end

local DefaultInputMethod = type(getsenv) == "function" and "Native" or (BackendAvailability.VirtualInput and "External" or AvailableInputMethods[1])

if env.__FNFMultiverseAutoplayer and env.__FNFMultiverseAutoplayer.Unload then
	pcall(env.__FNFMultiverseAutoplayer.Unload)
end

local State = {
	Enabled = true,
	AvoidHarmful = true,
	HoldNotes = true,
	Preset = "Perfect",
	TimingOffset = 0,
	Jitter = 0,
	CustomDeviation = 20,
	MissChance = 0,
	TapHold = 28,
	Lanes = {},
	Processed = setmetatable({}, {__mode = "k"}),
	Hits = 0,
	Holds = 0,
	Skipped = 0,
	Running = true,
	LastResolve = 0,
	ControlSet = "?",
	InputMethod = DefaultInputMethod,
	BackendAvailability = BackendAvailability,
	AvailableInputMethods = AvailableInputMethods,
	AutoModActions = true,
	AutoDodge = true,
	AutoAttackActions = true,
	AutoSpecialNotes = true,
	ActionOffset = 0,
	SustainBuffer = 0,
	StrictHoldMatching = true,
	ModEvents = {},
	ModCursor = 1,
	ModChart = nil,
	ModAudio = nil,
	ModBpm = nil,
	ModLastTime = nil,
	ModSkipped = 0,
	ModHits = 0,
	GcDodge = nil,
	ControlNames = {},
	CharacterAnimationCharacter = nil,
	CharacterAnimationModule = nil,
	CharacterAnimationController = nil,
}

local Connections = {}

local function addConnection(c)
	Connections[#Connections + 1] = c
	return c
end

local function disconnectAll()
	for _, c in ipairs(Connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(Connections)
end

local function getPlayerChart()
	local folder = workspace:FindFirstChild("ChartsFolder")
	if not folder then
		return nil
	end
	local chart = folder:FindFirstChild("Chart1")
	if chart and chart:GetAttribute("UserId") ~= LocalPlayer.UserId then
		chart = folder:FindFirstChild("Chart2")
	end
	return chart
end

local function resolveControlSet()
	local chart = getPlayerChart()
	if not chart then
		return nil, nil
	end
	local okChart, chartData = pcall(require, chart)
	if not okChart or type(chartData) ~= "table" then
		return nil, nil
	end
	local gameplay = chartData.Gameplay
	if type(gameplay) ~= "table" then
		return nil, nil
	end
	local controlSet = gameplay.Controls
	if type(controlSet) ~= "string" then
		return nil, nil
	end
	local okGui, gui = pcall(require, ReplicatedStorage.Assets.Constants.Gui)
	if not okGui or type(gui) ~= "table" then
		return nil, nil
	end
	local config = gui[controlSet]
	if type(config) ~= "table" or type(config.Names) ~= "table" then
		return controlSet, nil
	end
	return controlSet, config.Names
end

local function isExpectedNote(names, note)
	if not names then
		return true
	end
	return table.find(names, note) ~= nil
end

local function resolveLanes()
	State.LastResolve = os.clock()
	local controlSet, names = resolveControlSet()
	if controlSet then
		State.ControlSet = controlSet
	end
	State.ControlNames = names or {}

	local gameGui = PlayerGui:FindFirstChild("Game")
	local songWindow = gameGui and gameGui:FindFirstChild("SongWindow")
	if not songWindow then
		State.Lanes = {}
		return
	end

	local lanes = {}
	for _, obj in ipairs(songWindow:GetDescendants()) do
		if obj:IsA("LocalScript") and obj.Name == "Controls" then
			local note = obj:GetAttribute("Note")
			if type(note) == "string" and isExpectedNote(names, note) then
				local okEnv, scriptEnv = pcall(function()
					if type(getsenv) == "function" then
						return getsenv(obj)
					end
					return {}
				end)
				if not okEnv or type(scriptEnv) ~= "table" then
					scriptEnv = {}
				end
				local lane = obj.Parent
				local holding = obj:FindFirstChild("Holding")
				lanes[#lanes + 1] = {
					Script = obj,
					Env = scriptEnv,
					Root = lane,
					Note = note,
					Main = lane:FindFirstChild("Main"),
					Hit = lane:FindFirstChild("Hit"),
					Miss = lane:FindFirstChild("Miss"),
					Holding = holding,
					Ended = type(scriptEnv.Ended) == "function" and scriptEnv.Ended or nil,
					Busy = false,
				}
			end
		end
	end
	State.Lanes = lanes
	for _, lane in ipairs(State.Lanes) do
		lane.GcBegan = nil
	end
end

local function findCharacterAnimationController()
	local character = LocalPlayer.Character
	if not character then
		return nil, nil
	end

	local handlers = character:FindFirstChild("AnimHandlers")
	if not handlers then
		return nil, nil
	end

	local animationModule
	local animationPack
	for _, candidate in ipairs(handlers:GetChildren()) do
		if candidate:IsA("ModuleScript") and candidate:FindFirstChild("Active") then
			if candidate:FindFirstChild("ControllerEvent") or candidate:FindFirstChild("Server") then
				local okPack, pack = pcall(require, candidate)
				if okPack and type(pack) == "table" and pack.Active then
					animationModule = candidate
					animationPack = pack
					break
				end
			end
		end
	end
	if not animationModule or not animationPack then
		return nil, nil
	end

	if type(getgc) ~= "function" or type(debug) ~= "table" or type(debug.getupvalues) ~= "function" then
		return nil, animationModule
	end

	local okObjects, objects = pcall(getgc, true)
	if not okObjects or type(objects) ~= "table" then
		okObjects, objects = pcall(getgc)
	end
	if not okObjects or type(objects) ~= "table" then
		return nil, animationModule
	end

	for _, object in ipairs(objects) do
		if type(object) == "table" then
			local okMethods, began, ended = pcall(function()
				return object.Began, object.Ended
			end)
			if okMethods and type(began) == "function" and type(ended) == "function" then
				local okUpvalues, upvalues = pcall(debug.getupvalues, began)
				if okUpvalues and type(upvalues) == "table" then
					for _, upvalue in pairs(upvalues) do
						if upvalue == animationPack then
							return object, animationModule
						end
					end
				end
			end
		end
	end

	return nil, animationModule
end

local function resolveCharacterAnimationController()
	local character = LocalPlayer.Character
	if not character then
		return nil
	end

	if State.CharacterAnimationCharacter ~= character then
		State.CharacterAnimationCharacter = character
		State.CharacterAnimationModule = nil
		State.CharacterAnimationController = nil
	end
	if State.CharacterAnimationController then
		return State.CharacterAnimationController
	end

	local controller, animationModule = findCharacterAnimationController()
	State.CharacterAnimationModule = animationModule
	State.CharacterAnimationController = controller
	return controller
end

local function getCharacterAnimationIndex(lane)
	if not lane or type(State.ControlNames) ~= "table" then
		return nil
	end
	return table.find(State.ControlNames, lane.Note)
end

local function beginCharacterAnimation(lane, unit)
	if not lane or lane.InputMethod == "Virtual Input" or lane.InputMethod == "External" then
		return
	end
	if unit and string.find(unit.Name, "Punch") then
		return
	end

	local controller = resolveCharacterAnimationController()
	local index = getCharacterAnimationIndex(lane)
	if not controller or not index then
		return
	end

	lane.CharacterAnimationController = controller
	lane.CharacterAnimationIndex = index
	lane.CharacterAnimating = true
	task.spawn(function()
		local ok = pcall(function()
			controller:Began(index)
		end)
		if not ok and State.CharacterAnimationController == controller then
			State.CharacterAnimationController = nil
		end
	end)
end

local function endCharacterAnimation(lane)
	if not lane or not lane.CharacterAnimating then
		return
	end

	local controller = lane.CharacterAnimationController
	local index = lane.CharacterAnimationIndex
	lane.CharacterAnimating = false
	lane.CharacterAnimationController = nil
	lane.CharacterAnimationIndex = nil
	if not controller or not index then
		return
	end

	task.spawn(function()
		pcall(function()
			controller:Ended(index)
		end)
	end)
end

local function getDeviationMs()
	if State.Preset == "Perfect" then
		return 0
	elseif State.Preset == "Sick" then
		return math.random(-35, 35)
	elseif State.Preset == "Humanized" then
		local roll = math.random(1, 100)
		local magnitude
		if roll <= 72 then
			magnitude = math.random(4, 38)
		elseif roll <= 95 then
			magnitude = math.random(40, 82)
		else
			magnitude = math.random(85, 118)
		end
		return math.random(0, 1) == 0 and -magnitude or magnitude
	else
		local d = math.max(0, State.CustomDeviation)
		return math.random(-d, d)
	end
end

local function getControlKeyName(lane)
	local controls = LocalPlayer:FindFirstChild("Controls")
	local controlSet = controls and controls:FindFirstChild(State.ControlSet)
	local binding = controlSet and controlSet:FindFirstChild(lane.Note)
	if not binding or type(binding.Value) ~= "string" then
		return nil
	end

	local keyName
	for token in string.gmatch(binding.Value, "%S+") do
		if token ~= "None" and Enum.KeyCode[token] then
			keyName = token
			break
		end
	end
	return keyName
end

local function sendVirtualKey(keyName, isDown)
	if type(keyName) ~= "string" then
		return false
	end

	local keyCode = Enum.KeyCode[keyName]
	if not keyCode then
		return false
	end

	local virtualInputManager = getService("VirtualInputManager")
	if not virtualInputManager then
		return false
	end
	local ok = pcall(function()
		virtualInputManager:SendKeyEvent(isDown, keyCode, false, game)
	end)
	if ok then
		return true
	end

	local fallback = isDown and keypress or keyrelease
	if type(fallback) == "function" then
		local fallbackOk = pcall(fallback, keyCode.Value)
		if fallbackOk then
			return true
		end
		fallbackOk = pcall(fallback, keyCode)
		if fallbackOk then
			return true
		end
	end

	return false
end

local function getMobileButton(action)
	local mobileControls = PlayerGui:FindFirstChild("MobileControls")
	if not mobileControls then
		return nil
	end
	return mobileControls:FindFirstChild(action) or (action == "Dodge" and mobileControls:FindFirstChild("Middle"))
end

local function beginExternalLane(lane, method)
	local keyName = getControlKeyName(lane)
	if keyName and sendVirtualKey(keyName, true) then
		lane.InputMethod = method or "External"
		lane.KeyName = keyName
		return true
	end
	return false
end

local function ensureLaneAnimation(lane, unit)
	if not unit or unit.Name ~= "Unit" then
		return
	end
	if not lane.Main or not lane.Hit or not lane.Holding or not lane.Main.Parent then
		return
	end
	if not lane.Main.Visible then
		return
	end
	local functions = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Functions")
	local animateModule = functions and functions:FindFirstChild("AnimateInput")
	if not animateModule then
		return
	end
	local okAnimate, animateInput = pcall(require, animateModule)
	if okAnimate and type(animateInput) == "function" then
		pcall(animateInput, lane.Main, lane.Hit, lane.Holding)
	end
end

local function resolveGcBegan(lane)
	if lane.GcBegan then
		return lane.GcBegan
	end
	if type(getgc) ~= "function" then
		return lane.Env.Began
	end

	local ok, objects = pcall(getgc, true)
	if not ok or type(objects) ~= "table" then
		ok, objects = pcall(getgc)
	end
	if ok and type(objects) == "table" then
		for _, object in ipairs(objects) do
			if object == lane.Env.Began then
				lane.GcBegan = object
				return object
			end
		end
	end

	return lane.Env.Began
end

local function beginLane(lane)
	local method = State.InputMethod
	if method == "Virtual Input" or method == "External" then
		if beginExternalLane(lane, method) then
			return true
		end
	elseif method == "firesignal" and type(firesignal) == "function" then
		local button = getMobileButton(lane.Note)
		if button then
			local ok = pcall(firesignal, button.MouseEnter)
			if ok then
				lane.InputMethod = method
				lane.MobileButton = button
				return true
			end
		end
	elseif method == "getgc" then
		local began = resolveGcBegan(lane)
		if type(began) == "function" then
			local ok = pcall(began)
			if ok then
				lane.InputMethod = method
				return true
			end
		end
	elseif lane.Env and type(lane.Env.Began) == "function" then
		local ok = pcall(lane.Env.Began)
		if ok then
			lane.InputMethod = method
			return true
		end
	end

	if lane.Env and type(lane.Env.Began) == "function" then
		local fallbackOk = pcall(lane.Env.Began)
		if fallbackOk then
			lane.InputMethod = "Native"
			return true
		end
	end
	local externalOk = beginExternalLane(lane, "External")
	if externalOk and method ~= "External" then
		State.InputMethod = "External"
	end
	return externalOk
end

local function releaseLane(lane)
	endCharacterAnimation(lane)
	if (lane.InputMethod == "Virtual Input" or lane.InputMethod == "External") and lane.KeyName then
		sendVirtualKey(lane.KeyName, false)
	elseif lane.InputMethod == "firesignal" and lane.MobileButton and type(firesignal) == "function" then
		pcall(firesignal, lane.MobileButton.MouseLeave)
	end

	if lane.Holding and lane.Holding.Parent then
		lane.Holding.Value = false
	end

	pcall(function()
		GameEvent:FireServer({
			f = "Note",
			State = "Release",
			Note = lane.Note,
		})
	end)
	lane.InputMethod = nil
	lane.KeyName = nil
	lane.MobileButton = nil
	lane.Busy = false
end

local function findLong(lane, unit)
	local unitDelta = tonumber(unit and unit:GetAttribute("HitDelta"))
	local best, bestScore
	for _, child in ipairs(lane.Root:GetChildren()) do
		if child:IsA("GuiObject") and child.Visible and string.find(child.Name, "Long") then
			local delta = child:GetAttribute("HitDelta")
			local totalLength = tonumber(child:GetAttribute("TotalLength"))
			if type(delta) == "number" and totalLength and totalLength > 0 and delta >= -0.14 then
				local score = unitDelta and math.abs((delta - totalLength) - unitDelta) or math.abs(delta - totalLength)
				if (not State.StrictHoldMatching or score <= 0.05) and (not bestScore or score < bestScore) then
					best = child
					bestScore = score
				end
			end
		end
	end
	return best
end

local function holdAndRelease(lane, unit)
	local long = State.HoldNotes and findLong(lane, unit) or nil
	if not long then
		task.delay(math.max(0.005, State.TapHold / 1000), function()
			if State.Running and lane.Busy then
				releaseLane(lane)
			end
		end)
		return
	end

	State.Holds += 1
	task.spawn(function()
		local started = os.clock()
		local totalLength = tonumber(long:GetAttribute("TotalLength")) or 0
		local maxLifetime = math.max(0.75, totalLength + 0.75)
		while State.Running and lane.Busy and long.Parent and long.Visible do
			local delta = long:GetAttribute("HitDelta")
			if type(delta) ~= "number" then
				break
			end
			if delta <= State.SustainBuffer / 1000 then
				break
			end
			if os.clock() - started > maxLifetime then
				break
			end
			RunService.Heartbeat:Wait()
		end
		if State.Running and lane.Busy then
			releaseLane(lane)
		end
	end)
end

local function findCandidate(lane)
	local best, bestDelta
	for _, child in ipairs(lane.Root:GetChildren()) do
		if child:IsA("GuiObject") and child.Visible and string.find(child.Name, "Unit") then
			if State.AutoSpecialNotes or not string.find(child.Name, "Punch") then
				local delta = child:GetAttribute("HitDelta")
				if type(delta) == "number" and delta >= -0.14 and delta <= 0.25 then
					if not bestDelta or delta < bestDelta then
						best = child
						bestDelta = delta
					end
				end
			end
		end
	end
	return best, bestDelta
end

local function trigger(lane, unit)
	if State.Processed[unit] or lane.Busy then
		return
	end
	State.Processed[unit] = true

	if State.AvoidHarmful and unit:GetAttribute("Harmful") then
		State.Skipped += 1
		return
	end

	if State.MissChance > 0 and math.random() * 100 < State.MissChance then
		State.Skipped += 1
		return
	end

	lane.Busy = true
	if lane.Holding and lane.Holding.Parent then
		lane.Holding.Value = true
	end

	local ok = beginLane(lane)
	if not ok then
		lane.Busy = false
		if lane.Holding and lane.Holding.Parent then
			lane.Holding.Value = false
		end
		return
	end
	ensureLaneAnimation(lane, unit)
	beginCharacterAnimation(lane, unit)

	State.Hits += 1
	holdAndRelease(lane, unit)
end

local function getSongAudio()
	local folder = workspace:FindFirstChild("AudioFolder")
	if not folder then
		return nil
	end

	local best
	local bestScore = -math.huge
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Sound") and child.Playing then
			local score = (tonumber(child.Volume) or 0) * 1000
			if child.PlaybackLoudness and child.PlaybackLoudness > 0 then
				score += 10
			end
			if child.TimeLength and child.TimeLength > 0 then
				score += 1
			end
			if score >= bestScore then
				best = child
				bestScore = score
			end
		end
	end
	return best
end

local function addModEvent(events, time, action, eventName, usesVisualOffset)
	if type(time) == "number" and time >= 0 and type(action) == "string" then
		events[#events + 1] = {
			Time = time,
			Action = action,
			Name = eventName,
			UsesVisualOffset = usesVisualOffset == true,
		}
	end
end

local function getEventTime(entry)
	if type(entry) == "number" then
		return entry
	end
	if type(entry) ~= "table" then
		return nil
	end
	return tonumber(entry.t or entry.time or entry.Time)
end

local function getEventDuration(entry)
	if type(entry) ~= "table" then
		return 0
	end
	return math.max(0, tonumber(entry.d or entry.duration or entry.Duration) or 0)
end

local function getModAction(eventName)
	local normalized = string.lower(tostring(eventName)):gsub("[%s_%-]", "")
	if normalized == "heavypunch" or normalized == "punchnote" then
		return nil
	end
	if normalized == "bluebonealert" then
		return "Dodge"
	end
	if normalized == "dodge" or normalized == "dodgenote" or normalized == "space" or normalized == "dodgeevent" then
		return "Dodge"
	end
	if normalized == "atk1" or normalized == "attack1" or normalized == "attackone" then
		return "Atk1"
	end
	if normalized == "atk2" or normalized == "attack2" or normalized == "attacktwo" then
		return "Atk2"
	end
	if string.find(normalized, "dodge") and not string.find(normalized, "alert") then
		return "Dodge"
	end
	if string.find(normalized, "attack1") or string.find(normalized, "atk1") then
		return "Atk1"
	end
	if string.find(normalized, "attack2") or string.find(normalized, "atk2") then
		return "Atk2"
	end
	return nil
end

local function refreshModEvents(chart)
	State.ModEvents = {}
	State.ModCursor = 1
	State.ModChart = chart
	State.ModAudio = nil
	State.ModLastTime = nil
	State.GcDodge = nil

	if not chart then
		return
	end

	local ok, data = pcall(require, chart)
	if not ok or type(data) ~= "table" then
		return
	end

	local audio = getSongAudio()
	local bpm = tonumber(audio and audio:GetAttribute("Bpm")) or tonumber(data.Bpm) or 0
	local events = {}
	local chartEvents = type(data.Events) == "table" and data.Events or {}

	local heavyPunches = chartEvents.HeavyPunch
	if type(heavyPunches) == "table" and bpm > 0 then
		for _, entry in ipairs(heavyPunches) do
			if type(entry) == "table" and getEventTime(entry) then
				local count = math.max(1, tonumber(entry.count) or 1)
				local interval = tonumber(entry.interval) or 4
				local step = 30 / bpm * interval
				for index = 1, count do
					addModEvent(events, getEventTime(entry) + (index - 1) * step, "Dodge", "HeavyPunch")
				end
			end
		end
	end

	for eventName, eventList in pairs(chartEvents) do
		if type(eventList) == "table" then
			for _, entry in ipairs(eventList) do
				local time = getEventTime(entry)
				local entryName = type(entry) == "table" and entry.f or nil
				local sourceName = entryName or eventName
				local normalized = string.lower(tostring(sourceName)):gsub("[%s_%-]", "")
				local action = getModAction(sourceName)
				if not action then
					action = getModAction(eventName)
				end
				if action and time then
					local offset = 0
					if normalized == "bluebonealert" then
						offset = math.max(0.025, getEventDuration(entry) * 0.35)
					end
					addModEvent(events, time + offset, action, sourceName, normalized == "bluebonealert")
				end
			end
		end
	end

	if type(data.Chart) == "table" then
		for _, entry in ipairs(data.Chart) do
			if type(entry) == "table" and type(entry.f) == "string" then
				local normalized = string.lower(entry.f):gsub("[%s_%-]", "")
				local action = getModAction(entry.f)
				if action then
					local offset = 0
					if normalized == "bluebonealert" then
						offset = math.max(0.025, getEventDuration(entry) * 0.35)
					end
					local time = getEventTime(entry)
					if time then
						addModEvent(events, time + offset, action, entry.f, normalized == "bluebonealert")
					end
				end
			end
		end
	end

	table.sort(events, function(a, b)
		return a.Time < b.Time
	end)

	local deduplicated = {}
	local seen = {}
	for _, event in ipairs(events) do
		local key = event.Action .. ":" .. string.format("%.4f", event.Time)
		if not seen[key] then
			seen[key] = true
			deduplicated[#deduplicated + 1] = event
		end
	end

	State.ModEvents = deduplicated
	State.ModAudio = audio
	State.ModBpm = bpm
end

local function getActionKeyName(action)
	local controls = LocalPlayer:FindFirstChild("Controls")
	local indieCross = controls and controls:FindFirstChild("IndieCross")
	local binding = indieCross and indieCross:FindFirstChild(action)
	if not binding or type(binding.Value) ~= "string" then
		return nil
	end

	local keyName
	for token in string.gmatch(binding.Value, "%S+") do
		keyName = token
	end
	return keyName
end

local function resolveGcDodge()
	if State.GcDodge ~= nil then
		return State.GcDodge or nil
	end
	if type(getgc) ~= "function" or type(debug) ~= "table" or type(debug.getinfo) ~= "function" or type(debug.getupvalues) ~= "function" then
		State.GcDodge = false
		return nil
	end

	local ok, objects = pcall(getgc, true)
	if not ok or type(objects) ~= "table" then
		ok, objects = pcall(getgc)
	end
	if not ok or type(objects) ~= "table" then
		State.GcDodge = false
		return nil
	end

	local firstTime = State.ModEvents[1] and State.ModEvents[1].Time
	for _, object in ipairs(objects) do
		if type(object) == "function" then
			local infoOk, info = pcall(debug.getinfo, object)
			if infoOk and info and info.name == "hit" then
				local upOk, upvalues = pcall(debug.getupvalues, object)
				if upOk and type(upvalues) == "table" then
					local matched = false
					if firstTime then
						for _, upvalue in pairs(upvalues) do
							if type(upvalue) == "table" then
								for _, item in ipairs(upvalue) do
									if type(item) == "table" and type(item[1]) == "number" and math.abs(item[1] - firstTime) < 0.5 then
										matched = true
										break
									end
								end
							end
							if matched then
								break
							end
						end
					end
					if matched then
						State.GcDodge = object
						return object
					end
				end
			end
		end
	end

	State.GcDodge = false
	return nil
end

local function pressAction(action)
	if action == "Dodge" and State.InputMethod == "getgc" then
		local dodge = resolveGcDodge()
		if dodge then
			local ok = pcall(dodge)
			if ok then
				return true
			end
		end
	end

	if State.InputMethod == "firesignal" and type(firesignal) == "function" then
		local button = getMobileButton(action)
		if button then
			local ok = pcall(firesignal, button.MouseEnter)
			if ok then
				task.delay(0.035, function()
					pcall(firesignal, button.MouseLeave)
				end)
				return true
			end
		end
	end

	local keyName = getActionKeyName(action)
	if keyName and sendVirtualKey(keyName, true) then
		task.delay(0.035, function()
			sendVirtualKey(keyName, false)
		end)
		return true
	end

	return false
end

local function processModEvents()
	if not State.Enabled or not State.AutoModActions then
		return
	end

	local chart = getPlayerChart()
	local audio = getSongAudio()
	if chart ~= State.ModChart or audio ~= State.ModAudio then
		refreshModEvents(chart)
	end
	if not audio or not audio.Playing then
		return
	end

	local bpm = tonumber(audio:GetAttribute("Bpm")) or 0
	if bpm > 0 and bpm ~= State.ModBpm then
		refreshModEvents(chart)
	end
	if #State.ModEvents == 0 then
		return
	end

	local playbackSpeed = math.max(0.001, tonumber(audio.PlaybackSpeed) or 1)
	local audioOffset = tonumber(audio:GetAttribute("Offset")) or 0
	local settings = LocalPlayer:FindFirstChild("Settings")
	local timingOffset = settings and settings:FindFirstChild("Offset")
	local visualOffset = settings and settings:FindFirstChild("VisualOffset")
	local now = audio.TimePosition / playbackSpeed - audioOffset
	local actionOffset = (tonumber(State.ActionOffset) or 0) / 1000

	if State.ModLastTime and now < State.ModLastTime - 1 then
		State.ModCursor = 1
	end
	State.ModLastTime = now

	while State.ModEvents[State.ModCursor] and State.ModEvents[State.ModCursor].Time + actionOffset < now - 0.12 do
		State.ModSkipped += 1
		State.ModCursor += 1
	end

	while State.ModEvents[State.ModCursor] do
		local event = State.ModEvents[State.ModCursor]
		local target = event.Time + actionOffset + ((timingOffset and tonumber(timingOffset.Value)) or 0)
		if event.UsesVisualOffset then
			target += (visualOffset and tonumber(visualOffset.Value)) or 0
		end
		if target > now + 0.02 then
			break
		end
		local enabled = event.Action ~= "Dodge" or State.AutoDodge
		if event.Action == "Atk1" or event.Action == "Atk2" then
			enabled = State.AutoAttackActions
		end
		if enabled and pressAction(event.Action) then
			State.ModHits += 1
		end
		State.ModCursor += 1
	end
end

local laneTargets = setmetatable({}, {__mode = "k"})

local function updateLane(lane)
	if lane.Busy or not lane.Script.Parent or not lane.Root.Parent then
		return
	end

	local unit, delta = findCandidate(lane)
	if not unit or type(delta) ~= "number" then
		return
	end

	local target = laneTargets[unit]
	if target == nil then
		local deviation = getDeviationMs()
		local jitter = State.Jitter > 0 and math.random(-State.Jitter, State.Jitter) or 0
		target = (State.TimingOffset + deviation + jitter) / 1000
		laneTargets[unit] = target
	end

	if delta <= target then
		trigger(lane, unit)
	end
end

local VibeUI = loadstring(game:HttpGet("https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"))()
VibeUI.Config.MobileToggle = true

local Window = VibeUI:Window({
	Title = "FNF Multiverse Autoplayer",
	Size = UDim2.fromOffset(720, 520),
	Keybind = Enum.KeyCode.RightControl,
	Layout = "Side",
	Resizable = true,
})

local Watermark = VibeUI:Watermark("FNF Auto • waiting for chart")

local MainTab = Window:Tab({Name = "Autoplayer", Columns = 2})
local AutoSection = MainTab:Section({Name = "Autoplay", Side = 1})
local TimingSection = MainTab:Section({Name = "Timing", Side = 2})
local ExtraSection = MainTab:Section({Name = "Behavior", Side = 1})
local UtilitySection = MainTab:Section({Name = "Utility", Side = 2})

AutoSection:Toggle({
	Name = "Enabled",
	Flag = "FNF_Auto_Enabled",
	Default = true,
	Callback = function(v)
		State.Enabled = v
	end,
})

AutoSection:Toggle({
	Name = "Hold Notes",
	Flag = "FNF_Auto_Holds",
	Default = true,
	Callback = function(v)
		State.HoldNotes = v
	end,
})

AutoSection:Toggle({
	Name = "Avoid Harmful Notes",
	Flag = "FNF_Auto_AvoidHarmful",
	Default = true,
	Callback = function(v)
		State.AvoidHarmful = v
	end,
})

AutoSection:Toggle({
	Name = "Auto Special Notes",
	Flag = "FNF_Auto_SpecialNotes",
	Default = true,
	Callback = function(v)
		State.AutoSpecialNotes = v
	end,
})

AutoSection:Toggle({
	Name = "Auto Mod Actions",
	Flag = "FNF_Auto_ModActions",
	Default = true,
	Callback = function(v)
		State.AutoModActions = v
	end,
})

AutoSection:Toggle({
	Name = "Auto Dodge",
	Flag = "FNF_Auto_Dodge",
	Default = true,
	Callback = function(v)
		State.AutoDodge = v
	end,
})

AutoSection:Toggle({
	Name = "Auto Attack Actions",
	Flag = "FNF_Auto_AttackActions",
	Default = true,
	Callback = function(v)
		State.AutoAttackActions = v
	end,
})

AutoSection:Dropdown({
	Name = "Input Method",
	Flag = "FNF_Auto_InputMethod",
	Items = AvailableInputMethods,
	Default = DefaultInputMethod,
	Callback = function(v)
		if not table.find(AvailableInputMethods, v) then
			v = DefaultInputMethod
		end
		State.InputMethod = v
		State.GcDodge = nil
		for _, lane in ipairs(State.Lanes) do
			lane.GcBegan = nil
		end
	end,
})

AutoSection:Paragraph({
	Name = "Method",
	Content = "Only input methods supported by this executor are shown. External uses VirtualInputManager key events and does not require getsenv, firesignal, or getgc.",
})

TimingSection:Dropdown({
	Name = "Accuracy Preset",
	Flag = "FNF_Auto_Preset",
	Items = {"Perfect", "Sick", "Humanized", "Custom"},
	Default = "Perfect",
	Callback = function(v)
		State.Preset = v
	end,
})

TimingSection:Slider({
	Name = "Timing Offset",
	Flag = "FNF_Auto_Offset",
	Min = -120,
	Max = 120,
	Default = 0,
	Decimals = 1,
	Suffix = " ms",
	Callback = function(v)
		State.TimingOffset = v
	end,
})

TimingSection:Slider({
	Name = "Jitter",
	Flag = "FNF_Auto_Jitter",
	Min = 0,
	Max = 40,
	Default = 0,
	Decimals = 1,
	Suffix = " ms",
	Callback = function(v)
		State.Jitter = v
	end,
})

TimingSection:Slider({
	Name = "Custom Deviation",
	Flag = "FNF_Auto_CustomDeviation",
	Min = 0,
	Max = 120,
	Default = 20,
	Decimals = 1,
	Suffix = " ms",
	Callback = function(v)
		State.CustomDeviation = v
	end,
})

TimingSection:Slider({
	Name = "Sustain Buffer",
	Flag = "FNF_Auto_SustainBuffer",
	Min = -40,
	Max = 40,
	Default = 0,
	Decimals = 1,
	Suffix = " ms",
	Callback = function(v)
		State.SustainBuffer = v
	end,
})

TimingSection:Slider({
	Name = "Action Offset",
	Flag = "FNF_Auto_ActionOffset",
	Min = -120,
	Max = 120,
	Default = 0,
	Decimals = 1,
	Suffix = " ms",
	Callback = function(v)
		State.ActionOffset = v
	end,
})

ExtraSection:Slider({
	Name = "Miss Chance",
	Flag = "FNF_Auto_MissChance",
	Min = 0,
	Max = 25,
	Default = 0,
	Decimals = 0.1,
	Suffix = "%",
	Callback = function(v)
		State.MissChance = v
	end,
})

ExtraSection:Slider({
	Name = "Tap Hold Time",
	Flag = "FNF_Auto_TapHold",
	Min = 5,
	Max = 100,
	Default = 28,
	Decimals = 1,
	Suffix = " ms",
	Callback = function(v)
		State.TapHold = v
	end,
})

ExtraSection:Paragraph({
	Name = "Special Notes",
	Content = "Arrow heads are matched first. Sustain tails are only attached when their TotalLength and timing match that exact head.",
})

ExtraSection:Toggle({
	Name = "Strict Hold Matching",
	Flag = "FNF_Auto_StrictHolds",
	Default = true,
	Callback = function(v)
		State.StrictHoldMatching = v
	end,
})

local function resetStats()
	State.Hits = 0
	State.Holds = 0
	State.Skipped = 0
	State.ModHits = 0
	State.ModSkipped = 0
end

local function unload()
	if not State.Running then
		return
	end
	State.Running = false
	State.Enabled = false
	for _, lane in ipairs(State.Lanes) do
		if lane.Busy then
			pcall(releaseLane, lane)
		end
	end
	disconnectAll()
	pcall(function()
		Watermark:SetVisibility(false)
	end)
	pcall(function()
		VibeUI:Unload()
	end)
	env.__FNFMultiverseAutoplayer = nil
end

local row1 = UtilitySection:Button()
row1:Add("Refresh Lanes", function()
	pcall(resolveLanes)
end)
row1:Add("Reset Stats", resetStats)

local row2 = UtilitySection:Button()
row2:Add("Unload", unload)

UtilitySection:Paragraph({
	Name = "Status",
	Content = "Lane detection refreshes automatically when a song starts.",
})

VibeUI:CreateSettingsPage(Window, Watermark)

env.__FNFMultiverseAutoplayer = {
	State = State,
	Unload = unload,
	Refresh = resolveLanes,
	VibeUI = VibeUI,
}

addConnection(RunService.Heartbeat:Connect(function()
	if not State.Running then
		return
	end

	if os.clock() - State.LastResolve > 0.5 then
		local needsResolve = #State.Lanes == 0
		if not needsResolve then
			for _, lane in ipairs(State.Lanes) do
				if not lane.Script.Parent or not lane.Root.Parent then
					needsResolve = true
					break
				end
			end
		end
		if needsResolve then
			pcall(resolveLanes)
		else
			State.LastResolve = os.clock()
		end
	end

	if State.Enabled then
		for _, lane in ipairs(State.Lanes) do
			pcall(updateLane, lane)
		end
		pcall(processModEvents)
	end
end))

task.spawn(function()
	while State.Running do
		local laneCount = #State.Lanes
		pcall(function()
			Watermark:SetText(
				string.format(
					"FNF Auto • %s • %s • %d lanes • Hits %d • Holds %d • Actions %d • Skipped %d",
					tostring(State.ControlSet),
					tostring(State.InputMethod),
					laneCount,
					State.Hits,
					State.Holds,
					State.ModHits,
					State.Skipped
				)
			)
		end)
		task.wait(0.2)
	end
end)

pcall(resolveLanes)

VibeUI:Notification({
	Title = "FNF Autoplayer",
	Description = "Loaded. Waiting for an active chart if no lanes are present.",
	Type = "success",
	Duration = 4,
})
