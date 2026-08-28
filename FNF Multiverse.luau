local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local GameEvent = ReplicatedStorage:WaitForChild("GameEvent")

local env = getgenv()
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
					return getsenv(obj)
				end)
				if okEnv and type(scriptEnv) == "table" and type(scriptEnv.Began) == "function" then
					local lane = obj.Parent
					local holding = obj:FindFirstChild("Holding")
					lanes[#lanes + 1] = {
						Script = obj,
						Env = scriptEnv,
						Root = lane,
						Note = note,
						Holding = holding,
						Busy = false,
					}
				end
			end
		end
	end
	State.Lanes = lanes
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

local function releaseLane(lane)
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
	lane.Busy = false
end

local function findLong(lane)
	local best, bestDistance
	for _, child in ipairs(lane.Root:GetChildren()) do
		if child:IsA("GuiObject") and child.Visible and string.find(child.Name, "Long") then
			local delta = child:GetAttribute("HitDelta")
			local total = child:GetAttribute("TotalLength")
			if type(delta) == "number" and type(total) == "number" and total > 0 then
				local distance = math.abs(delta - total)
				if not bestDistance or distance < bestDistance then
					best = child
					bestDistance = distance
				end
			end
		end
	end
	return best
end

local function holdAndRelease(lane)
	local long = State.HoldNotes and findLong(lane) or nil
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
		local maxLifetime = math.max(0.35, (tonumber(long:GetAttribute("TotalLength")) or 0) + 0.75)
		while State.Running and lane.Busy and long.Parent and long.Visible do
			local delta = long:GetAttribute("HitDelta")
			if type(delta) ~= "number" or delta <= 0 then
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
			local delta = child:GetAttribute("HitDelta")
			if type(delta) == "number" and delta >= -0.14 and delta <= 0.25 then
				if not bestDelta or delta < bestDelta then
					best = child
					bestDelta = delta
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

	local ok = pcall(lane.Env.Began)
	if not ok then
		lane.Busy = false
		if lane.Holding and lane.Holding.Parent then
			lane.Holding.Value = false
		end
		return
	end

	State.Hits += 1
	holdAndRelease(lane)
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

AutoSection:Paragraph({
	Name = "Method",
	Content = "Uses the game's active Controls LocalScripts and their native Began() hit routine. Supports variable key counts and game-specific note behavior.",
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
	Content = "Special note handling is left to the game's own Began() routine. Harmful notes can be skipped separately.",
})

local function resetStats()
	State.Hits = 0
	State.Holds = 0
	State.Skipped = 0
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
	end
end))

task.spawn(function()
	while State.Running do
		local laneCount = #State.Lanes
		pcall(function()
			Watermark:SetText(
				string.format(
					"FNF Auto • %s • %d lanes • Hits %d • Holds %d • Skipped %d",
					tostring(State.ControlSet),
					laneCount,
					State.Hits,
					State.Holds,
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
