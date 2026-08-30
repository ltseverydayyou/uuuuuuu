local ENV = (getgenv and getgenv()) or _G

if type(ENV.__FunkyFridayVibeAutoplayer) == "table" and type(ENV.__FunkyFridayVibeAutoplayer.Unload) == "function" then
	pcall(function()
		ENV.__FunkyFridayVibeAutoplayer:Unload()
	end)
end

local __lt = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {}
	local sharedEnv = rawget(_G, "shared")
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil)
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver")
		if type(cached) == "table" then
			return cached
		end
	end
	local loader = loadstring or load
	if type(loader) ~= "function" then
		error("Service resolver loader unavailable")
	end
	local resolver = loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau")
	if type(resolver) ~= "function" then
		error("Service resolver failed to compile")
	end
	local loaded = resolver()
	if type(loaded) ~= "table" then
		error("Service resolver failed to load")
	end
	if cacheHost then
		cacheHost.__lt_service_resolver = loaded
	end
	return loaded
end)()

local Players = __lt.cs("Players", cloneref)
local RunService = __lt.cs("RunService", cloneref)
local VirtualInputManager = __lt.cs("VirtualInputManager", cloneref)
local UserInputService = __lt.cs("UserInputService", cloneref)
local Client = Players.LocalPlayer
local PlayerGui = Client:WaitForChild("PlayerGui")
local IsDesktop = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
local HasFireSignal = type(firesignal) == "function"
local HasVirtualInput = VirtualInputManager ~= nil

local HasScriptableInput = pcall(function()
	local binding = Instance.new("InputBinding")
	binding.Type = Enum.InputBindingType.Scriptable
	binding:Destroy()
end)

local IsExternal = IsDesktop and not HasFireSignal

local InputModes = {}
if IsDesktop and HasScriptableInput then
	InputModes[#InputModes + 1] = IsExternal and "Scriptable Input" or "firesignal"
elseif HasFireSignal then
	InputModes[#InputModes + 1] = "firesignal"
end
if HasVirtualInput then
	InputModes[#InputModes + 1] = "Virtual Input"
end
if #InputModes == 0 then
	error("No supported input method found")
end

local DefaultInputMode = InputModes[1]

local connections = {
	_list = {},
	add = function(self, signal, cb)
		local conn = signal:Connect(cb)
		self._list[#self._list + 1] = conn
		return conn
	end,
	disconnect = function(self)
		for _, conn in self._list do
			if typeof(conn) == "RBXScriptConnection" then
				pcall(function()
					conn:Disconnect()
				end)
			end
		end
		table.clear(self._list)
	end
}

local st = {
	auto = true,
	inMode = DefaultInputMode,
	accuracy = 100,
	off = 0,
	baseMs = 230,
	tapMs = 35,
	relMs = 0,
	holdTick = 0.015,
	maxHold = 8,
	alive = true,
	boundWindow = nil,
	laneDown = {},
	laneCount = {},
	Session = {},
	VibeUI = nil,
	FieldWatch = nil,
	ActiveTasks = 0,
	ScriptBindings = setmetatable({}, {__mode = "k"}),
	ConfigWatch = nil,
	SpecialPageWatch = nil,
	Capabilities = {
		External = IsExternal,
		FireSignal = HasFireSignal,
		VirtualInput = HasVirtualInput,
		ScriptableInput = HasScriptableInput,
	},
	SpecialNotes = {
		Death = {
			Images = {
				["rbxassetid://135247410719619"] = true,
				["rbxassetid://97859679023673"] = true,
				["rbxassetid://117950128749630"] = true,
				["rbxassetid://100522630100836"] = true,
				["rbxassetid://120077286622596"] = true,
				["rbxassetid://125973904904727"] = true,
				["rbxassetid://88815830295612"] = true,
				["rbxassetid://125614392730801"] = true,
				["rbxassetid://83024668935378"] = true,
				["rbxassetid://88623923653538"] = true,
				["rbxassetid://98258294634474"] = true,
				["rbxassetid://139899676689264"] = true,
				["rbxassetid://77051531406087"] = true,
				["rbxassetid://110522238640680"] = true,
				["rbxassetid://90996043647752"] = true,
				["rbxassetid://81712944045829"] = true,
			},
			Signatures = {}
		},
		Poison = {
			Images = {
				["rbxassetid://111487370594144"] = true,
				["rbxassetid://131745893889601"] = true,
				["rbxassetid://100742885063153"] = true,
				["rbxassetid://77685821387703"] = true,
				["rbxassetid://111041789521373"] = true,
				["rbxassetid://116314392120560"] = true,
				["rbxassetid://113965432917318"] = true,
				["rbxassetid://70953070004200"] = true,
				["rbxassetid://140256897187364"] = true,
				["rbxassetid://90821649912069"] = true,
				["rbxassetid://74368611517676"] = true,
				["rbxassetid://78030893318791"] = true,
				["rbxassetid://88103203842978"] = true,
				["rbxassetid://99615237411475"] = true,
				["rbxassetid://102776439587029"] = true,
				["rbxassetid://73919843476639"] = true,
			},
			Signatures = {}
		},
		Ready = true,
		Refreshing = false,
	}
}

ENV.__FunkyFridayVibeAutoplayer = st

local function getLaneKeyCode(action)
	if not action then
		return nil
	end
	for _, child in ipairs(action:GetChildren()) do
		if child:IsA("InputBinding") then
			local keyCode = child.KeyCode
			if keyCode and keyCode ~= Enum.KeyCode.Unknown then
				return keyCode
			end
		end
	end
	return nil
end

local function getScriptBinding(action)
	if not action then
		return nil
	end

	local binding = st.ScriptBindings[action]
	if binding and binding.Parent == action then
		return binding
	end

	binding = Instance.new("InputBinding")
	binding.Name = "SexyPlayerScriptBinding"
	binding.Type = Enum.InputBindingType.Scriptable
	binding.Parent = action
	st.ScriptBindings[action] = binding

	return binding
end

local function fireAction(action, down)
	if not action then
		return false
	end

	if IsDesktop and HasScriptableInput then
		local binding = getScriptBinding(action)
		if not binding then
			return false
		end
		return pcall(function()
			binding:Fire(down)
		end)
	end

	if not HasFireSignal then
		return false
	end

	return pcall(firesignal, down and action.Pressed or action.Released)
end

local function pressLane(name, action)
	if st.inMode ~= "Virtual Input" then
		fireAction(action, true)
		return
	end

	local keyCode = getLaneKeyCode(action)
	if keyCode and HasVirtualInput then
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
		end)
	end
end

local function releaseLane(name, action)
	if st.inMode ~= "Virtual Input" then
		fireAction(action, false)
		return
	end

	local keyCode = getLaneKeyCode(action)
	if keyCode and HasVirtualInput then
		pcall(function()
			VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
		end)
	end
end

local function getHoldTail(Arrow)
	if not Arrow then
		return nil
	end
	for _, child in ipairs(Arrow:GetChildren()) do
		if child:IsA("GuiObject") and child.ZIndex == 1 then
			return child
		end
	end
	return nil
end

local function isHold(Arrow)
	local tail = getHoldTail(Arrow)
	return tail and tail.Parent and tail.Visible and math.abs(tail.AbsoluteSize.Y) > 0.5 or false
end

local function imageSignature(imageObject)
	if not imageObject then
		return nil
	end

	local image = imageObject.Image
	if not image or image == "" then
		return nil
	end

	local color = imageObject.ImageColor3
	return table.concat({
		image,
		tostring(math.round(color.R * 255)),
		tostring(math.round(color.G * 255)),
		tostring(math.round(color.B * 255)),
	}, "|")
end

local function collectSpecialPreview(root)
	local data = {
		Images = {},
		Signatures = {},
	}

	if not root then
		return data
	end

	for _, direction in ipairs({"Left", "Down", "Up", "Right"}) do
		local frame = root:FindFirstChild(direction)
		local layered = frame and frame:FindFirstChild("LayeredSprite")

		if layered then
			for _, imageObject in ipairs(layered:GetChildren()) do
				if imageObject:IsA("ImageLabel") or imageObject:IsA("ImageButton") then
					local image = imageObject.Image
					local signature = imageSignature(imageObject)

					if image and image ~= "" then
						data.Images[image] = true
					end

					if signature then
						data.Signatures[signature] = true
					end
				end
			end
		end
	end

	return data
end

local function withGameIdentity(callback)
	local oldIdentity
	local canSet = type(setthreadidentity) == "function"

	if type(getthreadidentity) == "function" then
		pcall(function()
			oldIdentity = getthreadidentity()
		end)
	end

	if canSet then
		pcall(setthreadidentity, 2)
	end

	local results = table.pack(pcall(callback))

	if canSet and oldIdentity ~= nil then
		pcall(setthreadidentity, oldIdentity)
	end

	return table.unpack(results, 1, results.n)
end

local function clickSettingsButton(button)
	if not button then
		return false
	end

	if HasFireSignal then
		local ok = withGameIdentity(function()
			firesignal(button.MouseButton1Click)
		end)
		return ok == true
	end

	if not HasVirtualInput or not button:IsA("GuiButton") or not button.Visible then
		return false
	end

	local pos = button.AbsolutePosition
	local size = button.AbsoluteSize
	local x = math.floor(pos.X + size.X * 0.5)
	local y = math.floor(pos.Y + size.Y * 0.5)
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize

	if size.X <= 0 or size.Y <= 0 or x < 0 or y < 0 then
		return false
	end
	if viewport and (x > viewport.X or y > viewport.Y) then
		return false
	end

	local ok = pcall(function()
		VirtualInputManager:SendMouseMoveEvent(x, y, game)
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
		RunService.RenderStepped:Wait()
		VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
	end)

	return ok
end

local function getSpecialSettingsUi()
	local gameGui = PlayerGui:FindFirstChild("GameGui")
	local windows = gameGui and gameGui:FindFirstChild("Windows")
	local configuration = windows and windows:FindFirstChild("Configuration")
	local frame = configuration and configuration:FindFirstChild("Frame")
	local body = frame and frame:FindFirstChild("Body")
	local content = body and body:FindFirstChild("Content")
	local arrows = content and content:FindFirstChild("Arrows")
	local arrowsContent = arrows and arrows:FindFirstChild("Content")
	local notesPage = arrowsContent and arrowsContent:FindFirstChild("Notes")
	local notesList = notesPage and notesPage:FindFirstChild("Notes")
	local scrolling = notesList and notesList:FindFirstChild("ScrollingFrame")
	local options = notesPage and notesPage:FindFirstChild("Options")
	local bottom = options and options:FindFirstChild("Bottom")
	local arrowsPreview = bottom and bottom:FindFirstChild("Arrows")
	local inner = arrowsPreview and arrowsPreview:FindFirstChild("Inner")
	local previewRoot = inner and inner:FindFirstChild("Arrows")
	local top = options and options:FindFirstChild("Top")
	local title = top and top:FindFirstChild("Title")

	return {
		Configuration = configuration,
		Death = scrolling and scrolling:FindFirstChild("Death"),
		Poison = scrolling and scrolling:FindFirstChild("Poison"),
		Preview = previewRoot,
		Title = title,
		NotesPage = notesPage,
	}
end

local function ensureSpecialSettingsInitialized(ui)
	if not ui or not ui.Configuration then
		return false, false
	end

	if ui.Preview then
		for _, child in ipairs(ui.Preview:GetChildren()) do
			if child:FindFirstChild("LayeredSprite") then
				return true, false
			end
		end
	end

	local topBar = PlayerGui:FindFirstChild("TopBar")
	local topFrame = topBar and topBar:FindFirstChild("Frame")
	local left = topFrame and topFrame:FindFirstChild("Left")
	local configButton = left and left:FindFirstChild("Configuration")

	if not configButton then
		return false, false
	end

	local wasVisible = ui.Configuration.Visible

	if not wasVisible then
		clickSettingsButton(configButton)
		RunService.RenderStepped:Wait()
		RunService.RenderStepped:Wait()
	end

	local ready = false
	if ui.Preview then
		for _, child in ipairs(ui.Preview:GetChildren()) do
			if child:FindFirstChild("LayeredSprite") then
				ready = true
				break
			end
		end
	end

	return ready, not wasVisible
end

local function refreshSpecialNoteSkins()
	if st.SpecialNotes.Refreshing or not st.alive then
		return st.SpecialNotes.Ready
	end

	st.SpecialNotes.Refreshing = true

	local ui = getSpecialSettingsUi()
	local ready, openedByUs = ensureSpecialSettingsInitialized(ui)

	if not ready then
		st.SpecialNotes.Refreshing = false
		return false
	end

	local originalTitle = ui.Title and ui.Title.Text or ""
	local originalSelection

	if string.find(originalTitle, "Poison", 1, true) then
		originalSelection = "Poison"
	elseif string.find(originalTitle, "Death", 1, true) then
		originalSelection = "Death"
	end

	local function capture(name)
		local button = ui[name]
		if not button or not clickSettingsButton(button) then
			return nil
		end

		RunService.RenderStepped:Wait()
		return collectSpecialPreview(ui.Preview)
	end

	local death = capture("Death")
	local poison = capture("Poison")

	if death and next(death.Images) then
		st.SpecialNotes.Death = death
	end

	if poison and next(poison.Images) then
		st.SpecialNotes.Poison = poison
	end

	if originalSelection and ui[originalSelection] then
		clickSettingsButton(ui[originalSelection])
		RunService.RenderStepped:Wait()
	end

	if openedByUs then
		local topBar = PlayerGui:FindFirstChild("TopBar")
		local topFrame = topBar and topBar:FindFirstChild("Frame")
		local left = topFrame and topFrame:FindFirstChild("Left")
		local configButton = left and left:FindFirstChild("Configuration")

		if configButton and ui.Configuration.Visible then
			clickSettingsButton(configButton)
		end
	end

	st.SpecialNotes.Ready =
		next(st.SpecialNotes.Death.Images) ~= nil
		and next(st.SpecialNotes.Poison.Images) ~= nil

	st.SpecialNotes.Refreshing = false
	return st.SpecialNotes.Ready
end

local function getSpecialNoteType(Arrow)
	if not Arrow then
		return nil
	end

	local head
	for _, child in ipairs(Arrow:GetChildren()) do
		if child:IsA("GuiObject") and child.ZIndex == 2 then
			head = child
			break
		end
	end

	if not head then
		return nil
	end

	local death = st.SpecialNotes.Death
	local poison = st.SpecialNotes.Poison

	for _, imageObject in ipairs(head:GetChildren()) do
		if imageObject:IsA("ImageLabel") or imageObject:IsA("ImageButton") then
			local image = imageObject.Image
			local signature = imageSignature(imageObject)

			if signature and death.Signatures[signature] then
				return "Death"
			end

			if signature and poison.Signatures[signature] then
				return "Poison"
			end

			local inDeath = image and death.Images[image] or false
			local inPoison = image and poison.Images[image] or false

			if inDeath and not inPoison then
				return "Death"
			end

			if inPoison and not inDeath then
				return "Poison"
			end
		end
	end

	return nil
end

local function playSeq(Holder, Arrow, keyCode, AutoCtx)
	task.spawn(function()
		st.ActiveTasks += 1
		local delayTime = math.max(0, (AutoCtx.baseOffset or 0) + (AutoCtx.offsetMs or 0) / 1000)
		if delayTime > 0 then
			task.wait(delayTime)
		end
		if not AutoCtx.enabled then
			st.ActiveTasks -= 1
			return
		end
		if not Arrow or not Arrow.Parent or not Arrow.Visible then
			st.ActiveTasks -= 1
			return
		end
		if AutoCtx.laneDown[Holder] then
			AutoCtx.release(Holder.Name, keyCode)
		end
		AutoCtx.press(Holder.Name, keyCode)
		AutoCtx.laneDown[Holder] = true
		AutoCtx.laneCount[Holder] = (AutoCtx.laneCount[Holder] or 0) + 1
		local untilTime = os.clock() + math.max(0.05, AutoCtx.maxHold or 8)
		if isHold(Arrow) then
			while Arrow and Arrow.Parent and Arrow.Visible and AutoCtx.enabled and os.clock() <= untilTime do
				if not isHold(Arrow) then
					break
				end
				task.wait(math.max(0.005, AutoCtx.holdTick or 0.015))
			end
		else
			task.wait(math.max(0, AutoCtx.tapMs or 35) / 1000)
		end
		if AutoCtx.relMs and AutoCtx.relMs > 0 then
			task.wait(AutoCtx.relMs / 1000)
		end
		AutoCtx.laneCount[Holder] = math.max((AutoCtx.laneCount[Holder] or 1) - 1, 0)
		if AutoCtx.laneCount[Holder] <= 0 then
			AutoCtx.laneCount[Holder] = 0
			if AutoCtx.laneDown[Holder] then
				AutoCtx.release(Holder.Name, keyCode)
				AutoCtx.laneDown[Holder] = false
			end
		end
		st.ActiveTasks -= 1
	end)
end

local function releaseAll()
	for Holder, down in st.laneDown do
		if down then
			local action = st.Session[Holder.Name]
			if action then
				releaseLane(Holder.Name, action)
			end
			st.laneDown[Holder] = false
		end
	end
	for Holder in st.laneCount do
		st.laneCount[Holder] = 0
	end
end

local function pickLocalField(fields)
	local best
	local bestScore
	for _, sideName in ipairs({"Left", "Right"}) do
		local side = fields:FindFirstChild(sideName)
		local inner = side and side:FindFirstChild("Inner")
		local lane1 = inner and inner:FindFirstChild("Lane1")
		if side and lane1 then
			local score = (side.ZIndex or 0) * 100000 + lane1.AbsoluteSize.X
			if not bestScore or score > bestScore then
				best = side
				bestScore = score
			end
		end
	end
	return best
end

local function clearSongConnections()
	local keep = {}
	for _, conn in connections._list do
		if conn and conn.Connected then
			pcall(function()
				conn:Disconnect()
			end)
		end
	end
	table.clear(connections._list)
	table.clear(st.Session)
	releaseAll()
end

local function bindSong()
	clearSongConnections()

	local context = PlayerGui:FindFirstChild("VSRGContext")
	local window = PlayerGui:FindFirstChild("Window")
	local gameFrame = window and window:FindFirstChild("Game")
	local fields = gameFrame and gameFrame:FindFirstChild("Fields")
	if not (context and fields) then
		return false
	end

	local localField = pickLocalField(fields)
	local inner = localField and localField:FindFirstChild("Inner")
	if not inner then
		return false
	end

	local IncomingNotes = {}
	for i = 1, 12 do
		local Holder = inner:FindFirstChild("Lane" .. i)
		local action = context:FindFirstChild("Lane" .. i)
		local notes = Holder and Holder:FindFirstChild("Notes")
		if Holder and action and notes then
			st.Session[Holder.Name] = action
			IncomingNotes[#IncomingNotes + 1] = {
				Holder = Holder,
				Notes = notes
			}
		end
	end

	local AutoCtx = {
		enabled = true,
		offsetMs = st.off,
		baseOffset = st.baseMs / 1000,
		tapMs = st.tapMs,
		relMs = st.relMs,
		holdTick = st.holdTick,
		maxHold = st.maxHold,
		laneDown = st.laneDown,
		laneCount = st.laneCount,
		press = pressLane,
		release = releaseLane
	}

	for _, entry in IncomingNotes do
		local Holder = entry.Holder
		local Notes = entry.Notes
		connections:add(Notes.ChildAdded, function(Arrow)
			task.defer(function()
				if not Arrow or not Arrow.Visible then
					return
				end
				if not st.SpecialNotes.Ready then
					refreshSpecialNoteSkins()
				end
				if getSpecialNoteType(Arrow) then
					return
				end
				if not st.auto then
					return
				end
				if math.random(1, 10000) > math.floor(math.clamp(st.accuracy, 0, 100) * 100) then
					return
				end
				local keyCode = st.Session[Holder.Name]
				if not keyCode then
					return
				end
				AutoCtx.enabled = st.auto
				AutoCtx.offsetMs = st.off
				AutoCtx.baseOffset = st.baseMs / 1000
				AutoCtx.tapMs = st.tapMs
				AutoCtx.relMs = st.relMs
				AutoCtx.holdTick = st.holdTick
				AutoCtx.maxHold = st.maxHold
				playSeq(Holder, Arrow, keyCode, AutoCtx)
			end)
		end)
	end

	st.boundWindow = window
	return #IncomingNotes > 0
end

local function fieldWatch()
	if not st.alive then
		return
	end

	local window = PlayerGui:FindFirstChild("Window")
	local context = PlayerGui:FindFirstChild("VSRGContext")

	if window ~= st.boundWindow then
		st.boundWindow = window
		if window and context then
			task.defer(bindSong)
		else
			releaseAll()
		end
	elseif window and context and next(st.Session) == nil then
		task.defer(bindSong)
	end

	if not st.auto then
		releaseAll()
	end
end

function st:Unload()
	if not self.alive then
		return
	end
	self.alive = false
	self.auto = false
	releaseAll()
	connections:disconnect()
	if self.FieldWatch then
		pcall(function()
			self.FieldWatch:Disconnect()
		end)
		self.FieldWatch = nil
	end
	if self.ConfigWatch then
		pcall(function()
			self.ConfigWatch:Disconnect()
		end)
		self.ConfigWatch = nil
	end
	if self.SpecialPageWatch then
		pcall(function()
			self.SpecialPageWatch:Disconnect()
		end)
		self.SpecialPageWatch = nil
	end
	for _, binding in pairs(self.ScriptBindings or {}) do
		if binding and binding.Parent then
			pcall(function()
				binding:Destroy()
			end)
		end
	end
	table.clear(self.ScriptBindings)
	if self.VibeUI then
		pcall(function()
			self.VibeUI:Unload()
		end)
	end
	if ENV.__FunkyFridayVibeAutoplayer == self then
		ENV.__FunkyFridayVibeAutoplayer = nil
	end
end

local VibeUI = loadstring(game:HttpGet("https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"))()
st.VibeUI = VibeUI
VibeUI.Config.MobileToggle = true

local Window = VibeUI:Window({
	Title = "Funky Friday Autoplayer",
	Size = UDim2.fromOffset(680, 470),
	Keybind = Enum.KeyCode.RightControl,
	Layout = "Side",
	Resizable = true
})

local Main = Window:Tab({
	Name = "Autoplayer",
	Columns = 2
})

local Controls = Main:Section({
	Name = "Playback",
	Side = 1
})

Controls:Toggle({
	Name = "Autoplay",
	Flag = "FF_Autoplay",
	Default = true,
	Callback = function(value)
		st.auto = value
		if not value then
			releaseAll()
		end
	end
})

if #InputModes > 1 then
	Controls:Dropdown({
		Name = "Input Mode",
		Flag = IsExternal and "FF_ExternalInputMode" or "FF_InputMode",
		Items = InputModes,
		Default = DefaultInputMode,
		Callback = function(value)
			releaseAll()
			if table.find(InputModes, value) then
				st.inMode = value
			else
				st.inMode = DefaultInputMode
			end
		end
	})
end

if IsDesktop then
	Controls:Paragraph({
		Name = "PC Warning",
		Content = "Funky Friday stops reading gameplay inputs whenever Roblox loses focus. If you tab out or click another window, the autoplayer won’t work until Roblox is focused again."
	})
end

if IsExternal then
	Controls:Paragraph({
		Name = "External Executor",
		Content = "Some executor-only input methods aren’t available here, so the autoplayer only shows the input modes this executor can actually use."
	})
end

Controls:Slider({
	Name = "Hit Accuracy",
	Flag = "FF_Accuracy",
	Min = 0,
	Max = 100,
	Default = 100,
	Decimals = 1,
	Suffix = "%",
	Callback = function(value)
		st.accuracy = math.clamp(tonumber(value) or 100, 0, 100)
	end
})

Controls:Slider({
	Name = "Timing Offset",
	Flag = "FF_TimingOffset",
	Min = -100,
	Max = 100,
	Default = 0,
	Decimals = 1,
	Suffix = "ms",
	Callback = function(value)
		st.off = tonumber(value) or 0
	end
})

Controls:Slider({
	Name = "Spawn-to-Hit Delay",
	Flag = "FF_BaseDelay",
	Min = 150,
	Max = 320,
	Default = 230,
	Decimals = 1,
	Suffix = "ms",
	Callback = function(value)
		st.baseMs = math.clamp(tonumber(value) or 230, 100, 500)
	end
})

Controls:Slider({
	Name = "Tap Hold Time",
	Flag = "FF_TapMs",
	Min = 5,
	Max = 100,
	Default = 35,
	Decimals = 1,
	Suffix = "ms",
	Callback = function(value)
		st.tapMs = math.clamp(tonumber(value) or 35, 5, 250)
	end
})

local Runtime = Main:Section({
	Name = "Runtime",
	Side = 2
})

local Buttons = Runtime:Button()
Buttons:Add("Rebind Song", function()
	task.defer(bindSong)
end)

local Unload = Runtime:Button()
Unload:Add("Unload", function()
	st:Unload()
end)

VibeUI:CreateSettingsPage(Window)

task.defer(refreshSpecialNoteSkins)

local specialUi = getSpecialSettingsUi()
if specialUi.Configuration then
	st.ConfigWatch = specialUi.Configuration:GetPropertyChangedSignal("Visible"):Connect(function()
		if not specialUi.Configuration.Visible then
			task.defer(refreshSpecialNoteSkins)
		end
	end)
end
if specialUi.NotesPage then
	st.SpecialPageWatch = specialUi.NotesPage:GetPropertyChangedSignal("Visible"):Connect(function()
		if specialUi.NotesPage.Visible then
			task.defer(refreshSpecialNoteSkins)
		end
	end)
end

bindSong()
st.FieldWatch = RunService.Heartbeat:Connect(fieldWatch)

VibeUI:Notification({
	Title = "Funky Friday Autoplayer",
	Description = IsExternal and "External executor support loaded." or "Autoplayer loaded.",
	Type = "success",
	Duration = 4
})