--!nonstrict
local task, coroutine, TweenInfo = task, coroutine, TweenInfo
local unpack = table.unpack or unpack
local loadstring = loadstring or load
local newproxy = newproxy or function()
	return setmetatable({}, {
		__tostring = function()
			return "userdata: 0x0"
		end,
	})
end

local __lt = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {};
	local sharedEnv = rawget(_G, "shared");
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil);
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver");
		if type(cached) == "table" then
			return cached;
		end;
	end;
	local loader = loadstring or load;
	if type(loader) ~= "function" then
		error("Service resolver loader unavailable");
	end;
	local resolver = loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau");
	if type(resolver) ~= "function" then
		error("Service resolver failed to compile");
	end;
	local loaded = resolver();
	if type(loaded) ~= "table" then
		error("Service resolver failed to load");
	end;
	if cacheHost then
		cacheHost.__lt_service_resolver = loaded;
	end;
	return loaded;
end)();

--[[
	Save Instance App Module
	
	Revival of the old dex's Save Instance
]] 

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, SaveInstance, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	task = Main.Tasks or task
	coroutine = Main.Coroutine or coroutine
	TweenInfo = Main.TweenInfo or TweenInfo
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	SaveInstance = Apps.SaveInstance
	Notebook = Apps.Notebook
end

local function trackConn(conn)
	if Main and Main.TrackConn then
		return Main.TrackConn(conn)
	end
	return conn
end
local function main()
	local SaveInstance = {}
	local window, ListFrame, FilenameTextBox

	local function getSaveInstanceFormat()
		return (Settings and Settings.Files and Settings.Files.SaveInstanceNameFormat) or "{placeName}_{timestamp}"
	end

	local function buildSaveInstanceFileName(placeNameOverride)
		return Main.FormatFileName(getSaveInstanceFormat(), {
			placeName = placeNameOverride,
			placeId = game.PlaceId
		})
	end

	local fileName = buildSaveInstanceFileName("UnknownPlace")
	
	local SaveInstanceArgs = {
		__DEBUG_MODE = false,
		Debug = false,
		ReadMe = true,
		SafeMode = true,
		ShutdownWhenDone = false,
		AntiIdle = true,
		Anonymous = false,
		ShowStatus = true,
		mode = "optimized",
		noscripts = false,
		scriptcache = true,
		timeout = 10,
		DecompileJobless = false,
		SaveBytecode = false,
		DecompileIgnore = {"Chat", "CoreGui", "CorePackages"},
		IgnoreList = {"CoreGui", "CorePackages"},
		IgnoreProperties = {},
		SaveCacheInterval = 0x1600 * 10,
		NilInstances = false,
		IgnoreDefaultProperties = true,
		IgnoreNotArchivable = true,
		IgnorePropertiesOfNotScriptsOnScriptsMode = false,
		IgnoreSpecialProperties = false,
		UseUGCValidationService = true,
		IsolateStarterPlayer = true,
		IsolatePlayers = false,
		IsolateLocalPlayer = false,
		IsolateLocalPlayerCharacter = false,
		RemovePlayerCharacters = true,
		SaveNotCreatable = false,
		AlternativeWritefile = true,
		IgnoreDefaultPlayerScripts = true,
		IgnoreSharedStrings = true,
		SharedStringOverwrite = false,
		TreatUnionsAsParts = false,
		NotCreatableFixes = {"Player", "PlayerScripts", "PlayerGui", "TouchTransmitter"},
		SetStreaming = false,
		StreamingAreaSize = 10000,
		StreamingRadius = 1024,
		StreamingTimeout = 20,
		StreamingConcurrency = false,
		StreamingSlices = 2,
		StreamingMaxTime = false,
		StreamingChunkWait = 12,
		StreamingSettleTime = 5,
		NeutralizeLighting = false,
		ExportObj = false,
		DecompilePrepass = false,
		PrepassConcurrency = 24,
		PrepassRateGap = 0.12,
		PrepassApiUrl = "https://api.lua.expert/decompile",
		PrepassMaxScripts = 6000
	}
	local ExtraOptionsJson = ""
	local cloneOptions

	local function loadPersistedConfig()
		local savedState = Settings and Settings.SaveInstance
		if type(savedState) ~= "table" then
			return
		end

		local savedOptions = savedState.Options
		if type(savedOptions) == "table" then
			for key, value in savedOptions do
				if SaveInstanceArgs[key] ~= nil then
					SaveInstanceArgs[key] = value
				end
			end
		end

		if type(savedState.ExtraOptionsJson) == "string" then
			ExtraOptionsJson = savedState.ExtraOptionsJson
		end
	end

	local function persistSaveConfig()
		Settings.SaveInstance = Settings.SaveInstance or {}
		Settings.SaveInstance.Options = cloneOptions(SaveInstanceArgs)
		Settings.SaveInstance.ExtraOptionsJson = ExtraOptionsJson

		if Main and Main.SaveCurrentSettings then
			pcall(Main.SaveCurrentSettings)
		end
	end

	loadPersistedConfig()
	
	local function AddCheckbox(title, default)
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,20)
		
		local listlayout = Instance.new("UIListLayout")
		listlayout.Parent = frame.Gui
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.Padding = UDim.new(0, 10)
		
		-- Checkbox
		local checkbox = Lib.Checkbox.new()
		
		checkbox.Gui.Parent = frame.Gui
		checkbox.Gui.Size = UDim2.new(0,15,0,15)
		
		-- Label
		local label = Lib.Label.new()
		
		label.Gui.Parent = frame.Gui
		label.Gui.Size = UDim2.new(1, 0,1, -15)
		label.Gui.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd
		
		checkbox:SetState(default)
		
		return checkbox
	end
	
	local function AddTextbox(title, default, sizeX)
		default = tostring(default)
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,20)

		local listlayout = Instance.new("UIListLayout")
		listlayout.Parent = frame.Gui
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.Padding = UDim.new(0, 10)

		-- Textbox
		local textbox = Instance.new("TextBox") -- replaced cuz why Moon make every inputs only work on mouse/pc users >:( 
		textbox.BackgroundColor3 = Settings.Theme.TextBox
		textbox.BorderColor3 = Settings.Theme.Outline3
		textbox.ClearTextOnFocus = false
		textbox.TextColor3 = Settings.Theme.Text
		textbox.Font = Enum.Font.SourceSans
		textbox.TextSize = 14
		textbox.ZIndex = 2

		textbox.Parent = frame.Gui
		if sizeX and type(sizeX) == "number" then
			textbox.Size = UDim2.new(0,sizeX,0,15)
		else
			textbox.Size = UDim2.new(0,45,0,15)
		end
		
		frame.Gui.AutomaticSize = Enum.AutomaticSize.X
		textbox.AutomaticSize = Enum.AutomaticSize.X

		-- Label
		local label = Lib.Label.new()

		label.Parent = frame.Gui
		label.Size = UDim2.new(1, 0,1, -15)
		label.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd

		textbox.Text = default

		return {TextBox = textbox}
	end

	local function AddDropdown(title, options, default, allowEmpty, sizeX)
		if allowEmpty == nil then
			allowEmpty = true
		end

		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,20)

		local listlayout = Instance.new("UIListLayout")
		listlayout.Parent = frame.Gui
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.Padding = UDim.new(0, 10)

		local dropdown = Lib.DropDown.new()
		dropdown.CanBeEmpty = allowEmpty
		dropdown.Size = UDim2.new(0,sizeX or 90,0,15)
		dropdown:SetOptions(options)
		if default then
			dropdown:SetSelected(default)
		end
		dropdown.Gui.Parent = frame.Gui

		frame.Gui.AutomaticSize = Enum.AutomaticSize.X

		local label = Lib.Label.new()
		label.Parent = frame.Gui
		label.Size = UDim2.new(1, 0,1, -15)
		label.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd

		return dropdown
	end

	local function AddSeperator(title)
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,20)

		local label = Lib.Label.new()
		label.Parent = frame.Gui
		label.Size = UDim2.new(1, 0,1, 0)
		label.Text = title
		label.TextSize = 16
		label.TextTruncate = Enum.TextTruncate.AtEnd

		return frame
	end

	local function AddText(text)
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,32)

		local label = Lib.Label.new()
		label.Parent = frame.Gui
		label.Size = UDim2.new(1, 0,1, 0)
		label.Text = text
		label.TextWrapped = true
		label.TextYAlignment = Enum.TextYAlignment.Top

		return label
	end

	local function parseSimpleList(text)
		local result = {}
		for _, entry in string.split(tostring(text or ""), ",") do
			local clean = tostring(entry):gsub("^%s+", ""):gsub("%s+$", "")
			if clean ~= "" then
				table.insert(result, clean)
			end
		end
		return result
	end

	local function parseAutoNumber(text, current)
		local clean = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
		if clean == "" or clean == "auto" or clean == "false" then
			return false
		end
		return tonumber(clean) or current
	end

	cloneOptions = function(options)
		local cloned = {}
		for key, value in options do
			if type(value) == "table" then
				local copy = {}
				for subKey, subValue in value do
					copy[subKey] = subValue
				end
				cloned[key] = copy
			else
				cloned[key] = value
			end
		end
		return cloned
	end

	local function buildSaveOptions()
		local options = cloneOptions(SaveInstanceArgs)
		options.MaxThreads = nil

		if ExtraOptionsJson ~= "" then
			local okDecode, decoded = pcall(service.HttpService.JSONDecode, service.HttpService, ExtraOptionsJson)
			if not okDecode or type(decoded) ~= "table" then
				return nil, "Extra Options JSON is invalid"
			end

			for key, value in decoded do
				options[key] = value
			end
		end

		return options
	end

	local function refreshFileNamePreview(force, placeNameOverride)
		local suggestedName = buildSaveInstanceFileName(placeNameOverride)
		local currentText = (FilenameTextBox and FilenameTextBox.TextBox.Text) or fileName
		if force or currentText == "" or currentText == fileName then
			if FilenameTextBox then
				FilenameTextBox.TextBox.Text = suggestedName
			end
		end
		fileName = suggestedName
	end
	
	SaveInstance.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Save Instance")
		window:Resize(350,350)
		SaveInstance.Window = window
		
		-- ListFrame
		
		-- Fake ScrollBar dex, because its too advanced
		ListFrame = Instance.new("ScrollingFrame")
		ListFrame.Parent = window.GuiElems.Content
		ListFrame.Size = UDim2.new(1, 0,1, -40)
		ListFrame.Position = UDim2.new(0, 0, 0, 0)
		ListFrame.Transparency = 1
		ListFrame.CanvasSize = UDim2.new(0,0,0,0)
		ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		ListFrame.ScrollBarThickness = 16
		ListFrame.BottomImage = ""
		ListFrame.TopImage = ""
		ListFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
		ListFrame.ScrollBarImageTransparency = 0
		ListFrame.ZIndex = 2
		ListFrame.BorderSizePixel = 0
		
		local scrollbar = Lib.ScrollBar.new()
		scrollbar.Gui.Parent = window.GuiElems.Content
		scrollbar.Gui.Size = UDim2.new(1, 0,1, -40)
		scrollbar.Gui.Up.ZIndex = 3
		scrollbar.Gui.Down.ZIndex = 3
		
		Main.Connect(ListFrame:GetPropertyChangedSignal("AbsoluteWindowSize"), function()
			if ListFrame.AbsoluteCanvasSize ~= ListFrame.AbsoluteWindowSize then
				scrollbar.Gui.Visible = true
			else
				scrollbar.Gui.Visible = false
			end
		end)
		
		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Parent = ListFrame
		ListLayout.Padding = UDim.new(0, 5)
		
		local Padding = Instance.new("UIPadding")
		Padding.Parent = ListFrame
		Padding.PaddingBottom = UDim.new(0, 5)
		Padding.PaddingLeft = UDim.new(0, 10)
		Padding.PaddingRight = UDim.new(0, 10)
		Padding.PaddingTop = UDim.new(0, 5)
		
		-- Options
		AddSeperator("Protection")

		local SafeMode = AddCheckbox("Safe Mode", SaveInstanceArgs.SafeMode)
		Main.Connect(SafeMode.OnInput, function()
			SaveInstanceArgs.SafeMode = SafeMode.Toggled
			persistSaveConfig()
		end)

		local AntiIdle = AddCheckbox("Anti Idle", SaveInstanceArgs.AntiIdle)
		Main.Connect(AntiIdle.OnInput, function()
			SaveInstanceArgs.AntiIdle = AntiIdle.Toggled
			persistSaveConfig()
		end)

		local ShutdownWhenDone = AddCheckbox("Shutdown When Done", SaveInstanceArgs.ShutdownWhenDone)
		Main.Connect(ShutdownWhenDone.OnInput, function()
			SaveInstanceArgs.ShutdownWhenDone = ShutdownWhenDone.Toggled
			persistSaveConfig()
		end)

		local ShowStat = AddCheckbox("Show Status", SaveInstanceArgs.ShowStatus)
		Main.Connect(ShowStat.OnInput, function()
			SaveInstanceArgs.ShowStatus = ShowStat.Toggled
			persistSaveConfig()
		end)

		local ReadMe = AddCheckbox("Write ReadMe", SaveInstanceArgs.ReadMe)
		Main.Connect(ReadMe.OnInput, function()
			SaveInstanceArgs.ReadMe = ReadMe.Toggled
			persistSaveConfig()
		end)

		local DebugMode = AddCheckbox("Debug Mode", SaveInstanceArgs.__DEBUG_MODE)
		Main.Connect(DebugMode.OnInput, function()
			SaveInstanceArgs.__DEBUG_MODE = DebugMode.Toggled
			persistSaveConfig()
		end)

		local DetailedDebug = AddCheckbox("Write Detailed Debug Log", SaveInstanceArgs.Debug)
		Main.Connect(DetailedDebug.OnInput, function()
			SaveInstanceArgs.Debug = DetailedDebug.Toggled
			persistSaveConfig()
		end)

		local Anonymous = AddCheckbox("Anonymous", SaveInstanceArgs.Anonymous)
		Main.Connect(Anonymous.OnInput, function()
			SaveInstanceArgs.Anonymous = Anonymous.Toggled
			persistSaveConfig()
		end)

		AddSeperator("Decompile")

		local Mode = AddDropdown("Save Mode", {"optimized", "full", "scripts"}, SaveInstanceArgs.mode, false, 90)
		Main.Connect(Mode.OnSelect, function()
			SaveInstanceArgs.mode = Mode.Selected or "optimized"
			persistSaveConfig()
		end)

		local Decompile = AddCheckbox("Decompile Scripts", not SaveInstanceArgs.noscripts)
		Main.Connect(Decompile.OnInput, function()
			SaveInstanceArgs.noscripts = not Decompile.Toggled
			persistSaveConfig()
		end)

		local ScriptCache = AddCheckbox("Use Script Cache", SaveInstanceArgs.scriptcache)
		Main.Connect(ScriptCache.OnInput, function()
			SaveInstanceArgs.scriptcache = ScriptCache.Toggled
			persistSaveConfig()
		end)

		local decompileTimeout = AddTextbox("Decompile Timeout (s)", SaveInstanceArgs.timeout, 40)
		Main.Connect(decompileTimeout.TextBox.FocusLost, function()
			SaveInstanceArgs.timeout = tonumber(decompileTimeout.TextBox.Text) or SaveInstanceArgs.timeout
			decompileTimeout.TextBox.Text = tostring(SaveInstanceArgs.timeout)
			persistSaveConfig()
		end)

		local DecompileJobless = AddCheckbox("Decompile Jobless", SaveInstanceArgs.DecompileJobless)
		Main.Connect(DecompileJobless.OnInput, function()
			SaveInstanceArgs.DecompileJobless = DecompileJobless.Toggled
			persistSaveConfig()
		end)

		local SaveBytecode = AddCheckbox("Save Bytecode", SaveInstanceArgs.SaveBytecode)
		Main.Connect(SaveBytecode.OnInput, function()
			SaveInstanceArgs.SaveBytecode = SaveBytecode.Toggled
			persistSaveConfig()
		end)

		local DecompilePrepass = AddCheckbox("Decompile Prepass", SaveInstanceArgs.DecompilePrepass)
		Main.Connect(DecompilePrepass.OnInput, function()
			SaveInstanceArgs.DecompilePrepass = DecompilePrepass.Toggled
			persistSaveConfig()
		end)

		local PrepassConcurrency = AddTextbox("Prepass Concurrency", SaveInstanceArgs.PrepassConcurrency, 40)
		Main.Connect(PrepassConcurrency.TextBox.FocusLost, function()
			SaveInstanceArgs.PrepassConcurrency = tonumber(PrepassConcurrency.TextBox.Text) or SaveInstanceArgs.PrepassConcurrency
			PrepassConcurrency.TextBox.Text = tostring(SaveInstanceArgs.PrepassConcurrency)
			persistSaveConfig()
		end)

		local PrepassRateGap = AddTextbox("Prepass Rate Gap", SaveInstanceArgs.PrepassRateGap, 45)
		Main.Connect(PrepassRateGap.TextBox.FocusLost, function()
			SaveInstanceArgs.PrepassRateGap = tonumber(PrepassRateGap.TextBox.Text) or SaveInstanceArgs.PrepassRateGap
			PrepassRateGap.TextBox.Text = tostring(SaveInstanceArgs.PrepassRateGap)
			persistSaveConfig()
		end)

		local PrepassMaxScripts = AddTextbox("Prepass Max Scripts", SaveInstanceArgs.PrepassMaxScripts, 55)
		Main.Connect(PrepassMaxScripts.TextBox.FocusLost, function()
			SaveInstanceArgs.PrepassMaxScripts = tonumber(PrepassMaxScripts.TextBox.Text) or SaveInstanceArgs.PrepassMaxScripts
			PrepassMaxScripts.TextBox.Text = tostring(SaveInstanceArgs.PrepassMaxScripts)
			persistSaveConfig()
		end)

		local PrepassApiUrl = AddTextbox("Prepass API URL", SaveInstanceArgs.PrepassApiUrl, 180)
		Main.Connect(PrepassApiUrl.TextBox.FocusLost, function()
			local value = tostring(PrepassApiUrl.TextBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
			if value ~= "" then
				SaveInstanceArgs.PrepassApiUrl = value
			else
				PrepassApiUrl.TextBox.Text = SaveInstanceArgs.PrepassApiUrl
			end
			persistSaveConfig()
		end)

		local decompileIgnore = AddTextbox("Decompile Ignore", table.concat(SaveInstanceArgs.DecompileIgnore, ","), 90)
		Main.Connect(decompileIgnore.TextBox.FocusLost, function()
			SaveInstanceArgs.DecompileIgnore = parseSimpleList(decompileIgnore.TextBox.Text)
			persistSaveConfig()
		end)

		AddSeperator("Instances")

		local IgnoreList = AddTextbox("Ignore List", table.concat(SaveInstanceArgs.IgnoreList, ","), 90)
		Main.Connect(IgnoreList.TextBox.FocusLost, function()
			SaveInstanceArgs.IgnoreList = parseSimpleList(IgnoreList.TextBox.Text)
			persistSaveConfig()
		end)

		local IgnoreProperties = AddTextbox("Ignore Properties", table.concat(SaveInstanceArgs.IgnoreProperties, ","), 90)
		Main.Connect(IgnoreProperties.TextBox.FocusLost, function()
			SaveInstanceArgs.IgnoreProperties = parseSimpleList(IgnoreProperties.TextBox.Text)
			persistSaveConfig()
		end)

		local saveCacheInterval = AddTextbox("Save Cache Interval", SaveInstanceArgs.SaveCacheInterval, 70)
		Main.Connect(saveCacheInterval.TextBox.FocusLost, function()
			SaveInstanceArgs.SaveCacheInterval = tonumber(saveCacheInterval.TextBox.Text) or SaveInstanceArgs.SaveCacheInterval
			saveCacheInterval.TextBox.Text = tostring(SaveInstanceArgs.SaveCacheInterval)
			persistSaveConfig()
		end)

		local NilObj = AddCheckbox("Save Nil Instances", SaveInstanceArgs.NilInstances)
		Main.Connect(NilObj.OnInput, function()
			SaveInstanceArgs.NilInstances = NilObj.Toggled
			persistSaveConfig()
		end)

		local IgnoreDefaultProperties = AddCheckbox("Ignore Default Properties", SaveInstanceArgs.IgnoreDefaultProperties)
		Main.Connect(IgnoreDefaultProperties.OnInput, function()
			SaveInstanceArgs.IgnoreDefaultProperties = IgnoreDefaultProperties.Toggled
			persistSaveConfig()
		end)

		local IgnoreNotArchivable = AddCheckbox("Ignore Not Archivable", SaveInstanceArgs.IgnoreNotArchivable)
		Main.Connect(IgnoreNotArchivable.OnInput, function()
			SaveInstanceArgs.IgnoreNotArchivable = IgnoreNotArchivable.Toggled
			persistSaveConfig()
		end)

		local IgnorePropsScriptsMode = AddCheckbox("Ignore Non-Script Props In Scripts Mode", SaveInstanceArgs.IgnorePropertiesOfNotScriptsOnScriptsMode)
		Main.Connect(IgnorePropsScriptsMode.OnInput, function()
			SaveInstanceArgs.IgnorePropertiesOfNotScriptsOnScriptsMode = IgnorePropsScriptsMode.Toggled
			persistSaveConfig()
		end)

		local IgnoreSpecialProperties = AddCheckbox("Ignore Special Properties", SaveInstanceArgs.IgnoreSpecialProperties)
		Main.Connect(IgnoreSpecialProperties.OnInput, function()
			SaveInstanceArgs.IgnoreSpecialProperties = IgnoreSpecialProperties.Toggled
			persistSaveConfig()
		end)

		local UseUGCValidationService = AddCheckbox("Use UGC Validation Fallback", SaveInstanceArgs.UseUGCValidationService)
		Main.Connect(UseUGCValidationService.OnInput, function()
			SaveInstanceArgs.UseUGCValidationService = UseUGCValidationService.Toggled
			persistSaveConfig()
		end)

		local IsolateStarterPlr = AddCheckbox("Isolate StarterPlayer", SaveInstanceArgs.IsolateStarterPlayer)
		Main.Connect(IsolateStarterPlr.OnInput, function()
			SaveInstanceArgs.IsolateStarterPlayer = IsolateStarterPlr.Toggled
			persistSaveConfig()
		end)

		local IsolatePlayers = AddCheckbox("Isolate Players", SaveInstanceArgs.IsolatePlayers)
		Main.Connect(IsolatePlayers.OnInput, function()
			SaveInstanceArgs.IsolatePlayers = IsolatePlayers.Toggled
			persistSaveConfig()
		end)

		local IsolateLocalPlayer = AddCheckbox("Isolate Local Player", SaveInstanceArgs.IsolateLocalPlayer)
		Main.Connect(IsolateLocalPlayer.OnInput, function()
			SaveInstanceArgs.IsolateLocalPlayer = IsolateLocalPlayer.Toggled
			persistSaveConfig()
		end)

		local IsolateLocalPlayerCharacter = AddCheckbox("Isolate Local Player Character", SaveInstanceArgs.IsolateLocalPlayerCharacter)
		Main.Connect(IsolateLocalPlayerCharacter.OnInput, function()
			SaveInstanceArgs.IsolateLocalPlayerCharacter = IsolateLocalPlayerCharacter.Toggled
			persistSaveConfig()
		end)

		local RemovePlayerCharacters = AddCheckbox("Remove Player Characters", SaveInstanceArgs.RemovePlayerCharacters)
		Main.Connect(RemovePlayerCharacters.OnInput, function()
			SaveInstanceArgs.RemovePlayerCharacters = RemovePlayerCharacters.Toggled
			persistSaveConfig()
		end)

		local SaveNotCreatable = AddCheckbox("Save Not Creatable", SaveInstanceArgs.SaveNotCreatable)
		Main.Connect(SaveNotCreatable.OnInput, function()
			SaveInstanceArgs.SaveNotCreatable = SaveNotCreatable.Toggled
			persistSaveConfig()
		end)

		local AlternativeWritefile = AddCheckbox("Alternative Writefile", SaveInstanceArgs.AlternativeWritefile)
		Main.Connect(AlternativeWritefile.OnInput, function()
			SaveInstanceArgs.AlternativeWritefile = AlternativeWritefile.Toggled
			persistSaveConfig()
		end)

		local IgnoreDefaultPlayerScripts = AddCheckbox("Ignore Default PlayerScripts", SaveInstanceArgs.IgnoreDefaultPlayerScripts)
		Main.Connect(IgnoreDefaultPlayerScripts.OnInput, function()
			SaveInstanceArgs.IgnoreDefaultPlayerScripts = IgnoreDefaultPlayerScripts.Toggled
			persistSaveConfig()
		end)

		local IgnoreSharedStrings = AddCheckbox("Ignore SharedStrings", SaveInstanceArgs.IgnoreSharedStrings)
		Main.Connect(IgnoreSharedStrings.OnInput, function()
			SaveInstanceArgs.IgnoreSharedStrings = IgnoreSharedStrings.Toggled
			persistSaveConfig()
		end)

		local SharedStringOverwrite = AddCheckbox("SharedString Overwrite", SaveInstanceArgs.SharedStringOverwrite)
		Main.Connect(SharedStringOverwrite.OnInput, function()
			SaveInstanceArgs.SharedStringOverwrite = SharedStringOverwrite.Toggled
			persistSaveConfig()
		end)

		local TreatUnionsAsParts = AddCheckbox("Treat Unions As Parts", SaveInstanceArgs.TreatUnionsAsParts)
		Main.Connect(TreatUnionsAsParts.OnInput, function()
			SaveInstanceArgs.TreatUnionsAsParts = TreatUnionsAsParts.Toggled
			persistSaveConfig()
		end)

		local NotCreatableFixes = AddTextbox("Not Creatable Fixes", table.concat(SaveInstanceArgs.NotCreatableFixes, ","), 110)
		Main.Connect(NotCreatableFixes.TextBox.FocusLost, function()
			SaveInstanceArgs.NotCreatableFixes = parseSimpleList(NotCreatableFixes.TextBox.Text)
			persistSaveConfig()
		end)

		AddSeperator("Streaming")

		local SetStreaming = AddCheckbox("Capture Entire Streaming Map", SaveInstanceArgs.SetStreaming)
		Main.Connect(SetStreaming.OnInput, function()
			SaveInstanceArgs.SetStreaming = SetStreaming.Toggled
			persistSaveConfig()
		end)

		local StreamingAreaSize = AddTextbox("Streaming Area Size", SaveInstanceArgs.StreamingAreaSize, 55)
		Main.Connect(StreamingAreaSize.TextBox.FocusLost, function()
			SaveInstanceArgs.StreamingAreaSize = tonumber(StreamingAreaSize.TextBox.Text) or SaveInstanceArgs.StreamingAreaSize
			StreamingAreaSize.TextBox.Text = tostring(SaveInstanceArgs.StreamingAreaSize)
			persistSaveConfig()
		end)

		local StreamingRadius = AddTextbox("Streaming Radius", SaveInstanceArgs.StreamingRadius, 55)
		Main.Connect(StreamingRadius.TextBox.FocusLost, function()
			SaveInstanceArgs.StreamingRadius = tonumber(StreamingRadius.TextBox.Text) or SaveInstanceArgs.StreamingRadius
			StreamingRadius.TextBox.Text = tostring(SaveInstanceArgs.StreamingRadius)
			persistSaveConfig()
		end)

		local StreamingTimeout = AddTextbox("Streaming Request Timeout", SaveInstanceArgs.StreamingTimeout, 45)
		Main.Connect(StreamingTimeout.TextBox.FocusLost, function()
			SaveInstanceArgs.StreamingTimeout = tonumber(StreamingTimeout.TextBox.Text) or SaveInstanceArgs.StreamingTimeout
			StreamingTimeout.TextBox.Text = tostring(SaveInstanceArgs.StreamingTimeout)
			persistSaveConfig()
		end)

		local StreamingConcurrency = AddTextbox("Streaming Concurrency", SaveInstanceArgs.StreamingConcurrency or "auto", 45)
		Main.Connect(StreamingConcurrency.TextBox.FocusLost, function()
			SaveInstanceArgs.StreamingConcurrency = parseAutoNumber(StreamingConcurrency.TextBox.Text, SaveInstanceArgs.StreamingConcurrency)
			StreamingConcurrency.TextBox.Text = SaveInstanceArgs.StreamingConcurrency == false and "auto" or tostring(SaveInstanceArgs.StreamingConcurrency)
			persistSaveConfig()
		end)

		local StreamingSlices = AddTextbox("Streaming Slices", SaveInstanceArgs.StreamingSlices, 35)
		Main.Connect(StreamingSlices.TextBox.FocusLost, function()
			SaveInstanceArgs.StreamingSlices = tonumber(StreamingSlices.TextBox.Text) or SaveInstanceArgs.StreamingSlices
			StreamingSlices.TextBox.Text = tostring(SaveInstanceArgs.StreamingSlices)
			persistSaveConfig()
		end)

		local StreamingMaxTime = AddTextbox("Streaming Max Time", SaveInstanceArgs.StreamingMaxTime or "auto", 45)
		Main.Connect(StreamingMaxTime.TextBox.FocusLost, function()
			SaveInstanceArgs.StreamingMaxTime = parseAutoNumber(StreamingMaxTime.TextBox.Text, SaveInstanceArgs.StreamingMaxTime)
			StreamingMaxTime.TextBox.Text = SaveInstanceArgs.StreamingMaxTime == false and "auto" or tostring(SaveInstanceArgs.StreamingMaxTime)
			persistSaveConfig()
		end)

		local StreamingChunkWait = AddTextbox("Streaming Chunk Wait", SaveInstanceArgs.StreamingChunkWait, 40)
		Main.Connect(StreamingChunkWait.TextBox.FocusLost, function()
			SaveInstanceArgs.StreamingChunkWait = tonumber(StreamingChunkWait.TextBox.Text) or SaveInstanceArgs.StreamingChunkWait
			StreamingChunkWait.TextBox.Text = tostring(SaveInstanceArgs.StreamingChunkWait)
			persistSaveConfig()
		end)

		local StreamingSettleTime = AddTextbox("Streaming Settle Time", SaveInstanceArgs.StreamingSettleTime, 40)
		Main.Connect(StreamingSettleTime.TextBox.FocusLost, function()
			SaveInstanceArgs.StreamingSettleTime = tonumber(StreamingSettleTime.TextBox.Text) or SaveInstanceArgs.StreamingSettleTime
			StreamingSettleTime.TextBox.Text = tostring(SaveInstanceArgs.StreamingSettleTime)
			persistSaveConfig()
		end)

		AddSeperator("Output")

		local NeutralizeLighting = AddCheckbox("Neutralize Lighting", SaveInstanceArgs.NeutralizeLighting)
		Main.Connect(NeutralizeLighting.OnInput, function()
			SaveInstanceArgs.NeutralizeLighting = NeutralizeLighting.Toggled
			persistSaveConfig()
		end)

		local ExportObj = AddCheckbox("Export MeshParts To OBJ", SaveInstanceArgs.ExportObj)
		Main.Connect(ExportObj.OnInput, function()
			SaveInstanceArgs.ExportObj = ExportObj.Toggled
			persistSaveConfig()
		end)
		AddSeperator("File")

		local FileNameFormat = AddTextbox("File Name Format", getSaveInstanceFormat(), 140)
		Main.Connect(FileNameFormat.TextBox.FocusLost, function()
			local newFormat = tostring(FileNameFormat.TextBox.Text or "")
			if newFormat == "" then
				newFormat = "{placeName}_{timestamp}"
			end

			Settings.Files = Settings.Files or {}
			Settings.Files.SaveInstanceNameFormat = newFormat
			FileNameFormat.TextBox.Text = newFormat
			if Main and Main.SaveCurrentSettings then
				pcall(Main.SaveCurrentSettings)
			end

			refreshFileNamePreview(true, "UnknownPlace")
			task.spawn(function()
				refreshFileNamePreview(false, Main.GetPlaceDisplayName())
			end)
		end)

		AddText("Extra Options JSON can override top-level SaveInstance420 options like Anonymous tables or custom IgnoreList maps.")
		local ExtraOptions = AddTextbox("Extra Options JSON", ExtraOptionsJson, 180)
		Main.Connect(ExtraOptions.TextBox.FocusLost, function()
			ExtraOptionsJson = tostring(ExtraOptions.TextBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
			persistSaveConfig()
		end)
		
		
		-- Decompile buttons below
		FilenameTextBox = Lib.ViewportTextBox.new()
		FilenameTextBox.Gui.Parent = window.GuiElems.Content
		FilenameTextBox.Size = UDim2.new(1,0, 0,20)
		FilenameTextBox.Position = UDim2.new(0,0, 1,-40)
		
		local textpadding = Instance.new("UIPadding")
		textpadding.Parent = FilenameTextBox.Gui
		textpadding.PaddingLeft = UDim.new(0, 5)
		textpadding.PaddingRight = UDim.new(0, 5)
		
		local BackgroundButton = Lib.Frame.new()
		BackgroundButton.Gui.Parent = window.GuiElems.Content
		BackgroundButton.Size = UDim2.new(1,0, 0,20)
		BackgroundButton.Position = UDim2.new(0,0, 1,-20)
		
		local LabelButton = Lib.Label.new()
		LabelButton.Gui.Parent = window.GuiElems.Content
		LabelButton.Size = UDim2.new(1,0, 0,20)
		LabelButton.Position = UDim2.new(0,0, 1,-20)
		LabelButton.Gui.Text = "Save"
		LabelButton.Gui.TextXAlignment = Enum.TextXAlignment.Center
		
		local Button = Instance.new("TextButton")
		Button.Parent = BackgroundButton.Gui
		Button.Size = UDim2.new(1,0, 1,0)
		Button.Position = UDim2.new(0,0, 0,0)
		Button.Transparency = 1
		
		FilenameTextBox.TextBox.Text = fileName
		task.spawn(function()
			refreshFileNamePreview(false, Main.GetPlaceDisplayName())
		end)
		Main.Connect(Button.MouseButton1Click, function()
			local fileName = Main.FormatFileName(FilenameTextBox.TextBox.Text)
			persistSaveConfig()
			local saveOptions, optionsErr = buildSaveOptions()
			if not saveOptions then
				window:SetTitle("Save Instance - "..tostring(optionsErr))
				task.wait(2)
				window:SetTitle("Save Instance")
				return
			end
			window:SetTitle("Save Instance - Saving")
			saveOptions.FilePath = fileName
			local s, result = pcall(env.saveinstance, saveOptions)
			if s then
				window:SetTitle("Save Instance - Saved")
			else
				window:SetTitle("Save Instance - Error")
				task.spawn(error("Failed to save the game: "..result))
			end
			task.wait(5)
			window:SetTitle("Save Instance")
		end)
	end

return SaveInstance
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
