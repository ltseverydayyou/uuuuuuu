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
		ReadMe = true,
		SafeMode = true,
		KillAllScripts = true,
		BoostFPS = false,
		ShutdownWhenDone = false,
		AntiIdle = true,
		Anonymous = false,
		ShowStatus = true,
		mode = "optimized",
		Decompile = true,
		scriptcache = true,
		DecompileTimeout = 10,
		DecompileJobless = false,
		SaveBytecode = false,
		DecompileIgnore = {"Chat", "CoreGui", "CorePackages"},
		IgnoreList = {"CoreGui", "CorePackages"},
		IgnoreProperties = {},
		SaveCacheInterval = 0x1600 * 10,
		AvoidFileOverwrite = true,
		NilInstances = false,
		IgnoreDefaultProperties = true,
		IgnoreNotArchivable = true,
		IgnorePropertiesOfNotScriptsOnScriptsMode = false,
		IgnoreSpecialProperties = false,
		IsolateStarterPlayer = true,
		IsolatePlayers = false,
		IsolateLocalPlayer = false,
		IsolateLocalPlayerCharacter = false,
		SavePlayerCharacters = false,
		SaveNotCreatable = false,
		AlternativeWritefile = true,
		IgnoreDefaultPlayerScripts = true,
		IgnoreSharedStrings = true,
		SharedStringOverwrite = false,
		TreatUnionsAsParts = false,
		NotCreatableFixes = {"Player", "PlayerScripts", "PlayerGui", "TouchTransmitter"}
	}
	local ExtraOptionsJson = ""
	
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
		for _, entry in ipairs(string.split(tostring(text or ""), ",")) do
			local clean = tostring(entry):gsub("^%s+", ""):gsub("%s+$", "")
			if clean ~= "" then
				table.insert(result, clean)
			end
		end
		return result
	end

	local function cloneOptions(options)
		local cloned = {}
		for key, value in pairs(options) do
			if type(value) == "table" then
				local copy = {}
				for subKey, subValue in pairs(value) do
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

			for key, value in pairs(decoded) do
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
		
		ListFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
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
		SafeMode.OnInput:Connect(function()
			SaveInstanceArgs.SafeMode = SafeMode.Toggled
		end)

		local KillAllScripts = AddCheckbox("Kill All Scripts", SaveInstanceArgs.KillAllScripts)
		KillAllScripts.OnInput:Connect(function()
			SaveInstanceArgs.KillAllScripts = KillAllScripts.Toggled
		end)

		local BoostFPS = AddCheckbox("Boost FPS", SaveInstanceArgs.BoostFPS)
		BoostFPS.OnInput:Connect(function()
			SaveInstanceArgs.BoostFPS = BoostFPS.Toggled
		end)

		local AntiIdle = AddCheckbox("Anti Idle", SaveInstanceArgs.AntiIdle)
		AntiIdle.OnInput:Connect(function()
			SaveInstanceArgs.AntiIdle = AntiIdle.Toggled
		end)

		local ShutdownWhenDone = AddCheckbox("Shutdown When Done", SaveInstanceArgs.ShutdownWhenDone)
		ShutdownWhenDone.OnInput:Connect(function()
			SaveInstanceArgs.ShutdownWhenDone = ShutdownWhenDone.Toggled
		end)

		local ShowStat = AddCheckbox("Show Status", SaveInstanceArgs.ShowStatus)
		ShowStat.OnInput:Connect(function()
			SaveInstanceArgs.ShowStatus = ShowStat.Toggled
		end)

		local ReadMe = AddCheckbox("Write ReadMe", SaveInstanceArgs.ReadMe)
		ReadMe.OnInput:Connect(function()
			SaveInstanceArgs.ReadMe = ReadMe.Toggled
		end)

		local DebugMode = AddCheckbox("Debug Mode", SaveInstanceArgs.__DEBUG_MODE)
		DebugMode.OnInput:Connect(function()
			SaveInstanceArgs.__DEBUG_MODE = DebugMode.Toggled
		end)

		local Anonymous = AddCheckbox("Anonymous", SaveInstanceArgs.Anonymous)
		Anonymous.OnInput:Connect(function()
			SaveInstanceArgs.Anonymous = Anonymous.Toggled
		end)

		AddSeperator("Decompile")

		local Mode = AddDropdown("Save Mode", {"optimized", "full", "scripts"}, SaveInstanceArgs.mode, false, 90)
		Mode.OnSelect:Connect(function()
			SaveInstanceArgs.mode = Mode.Selected or "optimized"
		end)

		local Decompile = AddCheckbox("Decompile Scripts (LocalScript and ModuleScript)", SaveInstanceArgs.Decompile)
		Decompile.OnInput:Connect(function()
			SaveInstanceArgs.Decompile = Decompile.Toggled
		end)

		local ScriptCache = AddCheckbox("Use Script Cache", SaveInstanceArgs.scriptcache)
		ScriptCache.OnInput:Connect(function()
			SaveInstanceArgs.scriptcache = ScriptCache.Toggled
		end)
		
		local decompileTimeout = AddTextbox("Decompile Timeout (s)", SaveInstanceArgs.DecompileTimeout, 15)
		decompileTimeout.TextBox.FocusLost:Connect(function()
			SaveInstanceArgs.DecompileTimeout = tonumber(decompileTimeout.TextBox.Text)
		end)

		local DecompileJobless = AddCheckbox("Decompile Jobless", SaveInstanceArgs.DecompileJobless)
		DecompileJobless.OnInput:Connect(function()
			SaveInstanceArgs.DecompileJobless = DecompileJobless.Toggled
		end)

		local SaveBytecode = AddCheckbox("Save Bytecode", SaveInstanceArgs.SaveBytecode)
		SaveBytecode.OnInput:Connect(function()
			SaveInstanceArgs.SaveBytecode = SaveBytecode.Toggled
		end)
		
		local decompileIgnore = AddTextbox("Decompile Ignore", table.concat(SaveInstanceArgs.DecompileIgnore, ","), 50)
		decompileIgnore.TextBox.FocusLost:Connect(function()
			SaveInstanceArgs.DecompileIgnore = parseSimpleList(decompileIgnore.TextBox.Text)
		end)

		local IgnoreList = AddTextbox("Ignore List", table.concat(SaveInstanceArgs.IgnoreList, ","), 50)
		IgnoreList.TextBox.FocusLost:Connect(function()
			SaveInstanceArgs.IgnoreList = parseSimpleList(IgnoreList.TextBox.Text)
		end)

		local IgnoreProperties = AddTextbox("Ignore Properties", table.concat(SaveInstanceArgs.IgnoreProperties, ","), 70)
		IgnoreProperties.TextBox.FocusLost:Connect(function()
			SaveInstanceArgs.IgnoreProperties = parseSimpleList(IgnoreProperties.TextBox.Text)
		end)

		AddSeperator("Instances")

		local saveCacheInterval = AddTextbox("Save Cache Interval", SaveInstanceArgs.SaveCacheInterval, 55)
		saveCacheInterval.TextBox.FocusLost:Connect(function()
			SaveInstanceArgs.SaveCacheInterval = tonumber(saveCacheInterval.TextBox.Text)
		end)

		local AvoidFileOverwrite = AddCheckbox("Avoid File Overwrite", SaveInstanceArgs.AvoidFileOverwrite)
		AvoidFileOverwrite.OnInput:Connect(function()
			SaveInstanceArgs.AvoidFileOverwrite = AvoidFileOverwrite.Toggled
		end)

		local NilObj = AddCheckbox("Save Nil Instances", SaveInstanceArgs.NilInstances)
		NilObj.OnInput:Connect(function()
			SaveInstanceArgs.NilInstances = NilObj.Toggled
		end)

		local IgnoreDefaultProperties = AddCheckbox("Ignore Default Properties", SaveInstanceArgs.IgnoreDefaultProperties)
		IgnoreDefaultProperties.OnInput:Connect(function()
			SaveInstanceArgs.IgnoreDefaultProperties = IgnoreDefaultProperties.Toggled
		end)

		local IgnoreNotArchivable = AddCheckbox("Ignore Not Archivable", SaveInstanceArgs.IgnoreNotArchivable)
		IgnoreNotArchivable.OnInput:Connect(function()
			SaveInstanceArgs.IgnoreNotArchivable = IgnoreNotArchivable.Toggled
		end)

		local IgnorePropsScriptsMode = AddCheckbox("Ignore Non-Script Props In Scripts Mode", SaveInstanceArgs.IgnorePropertiesOfNotScriptsOnScriptsMode)
		IgnorePropsScriptsMode.OnInput:Connect(function()
			SaveInstanceArgs.IgnorePropertiesOfNotScriptsOnScriptsMode = IgnorePropsScriptsMode.Toggled
		end)

		local IgnoreSpecialProperties = AddCheckbox("Ignore Special Properties", SaveInstanceArgs.IgnoreSpecialProperties)
		IgnoreSpecialProperties.OnInput:Connect(function()
			SaveInstanceArgs.IgnoreSpecialProperties = IgnoreSpecialProperties.Toggled
		end)

		local IsolateStarterPlr = AddCheckbox("Isolate StarterPlayer", SaveInstanceArgs.IsolateStarterPlayer)
		IsolateStarterPlr.OnInput:Connect(function()
			SaveInstanceArgs.IsolateStarterPlayer = IsolateStarterPlr.Toggled
		end)

		local IsolatePlayers = AddCheckbox("Isolate Players", SaveInstanceArgs.IsolatePlayers)
		IsolatePlayers.OnInput:Connect(function()
			SaveInstanceArgs.IsolatePlayers = IsolatePlayers.Toggled
		end)

		local IsolateLocalPlayer = AddCheckbox("Isolate Local Player", SaveInstanceArgs.IsolateLocalPlayer)
		IsolateLocalPlayer.OnInput:Connect(function()
			SaveInstanceArgs.IsolateLocalPlayer = IsolateLocalPlayer.Toggled
		end)

		local IsolateLocalPlayerCharacter = AddCheckbox("Isolate Local Player Character", SaveInstanceArgs.IsolateLocalPlayerCharacter)
		IsolateLocalPlayerCharacter.OnInput:Connect(function()
			SaveInstanceArgs.IsolateLocalPlayerCharacter = IsolateLocalPlayerCharacter.Toggled
		end)

		local SavePlayerCharacters = AddCheckbox("Save Player Characters", SaveInstanceArgs.SavePlayerCharacters)
		SavePlayerCharacters.OnInput:Connect(function()
			SaveInstanceArgs.SavePlayerCharacters = SavePlayerCharacters.Toggled
		end)

		local SaveNotCreatable = AddCheckbox("Save Not Creatable", SaveInstanceArgs.SaveNotCreatable)
		SaveNotCreatable.OnInput:Connect(function()
			SaveInstanceArgs.SaveNotCreatable = SaveNotCreatable.Toggled
		end)

		local AlternativeWritefile = AddCheckbox("Alternative Writefile", SaveInstanceArgs.AlternativeWritefile)
		AlternativeWritefile.OnInput:Connect(function()
			SaveInstanceArgs.AlternativeWritefile = AlternativeWritefile.Toggled
		end)

		local IgnoreDefaultPlayerScripts = AddCheckbox("Ignore Default PlayerScripts", SaveInstanceArgs.IgnoreDefaultPlayerScripts)
		IgnoreDefaultPlayerScripts.OnInput:Connect(function()
			SaveInstanceArgs.IgnoreDefaultPlayerScripts = IgnoreDefaultPlayerScripts.Toggled
		end)

		local IgnoreSharedStrings = AddCheckbox("Ignore SharedStrings", SaveInstanceArgs.IgnoreSharedStrings)
		IgnoreSharedStrings.OnInput:Connect(function()
			SaveInstanceArgs.IgnoreSharedStrings = IgnoreSharedStrings.Toggled
		end)

		local SharedStringOverwrite = AddCheckbox("SharedString Overwrite", SaveInstanceArgs.SharedStringOverwrite)
		SharedStringOverwrite.OnInput:Connect(function()
			SaveInstanceArgs.SharedStringOverwrite = SharedStringOverwrite.Toggled
		end)

		local TreatUnionsAsParts = AddCheckbox("Treat Unions As Parts", SaveInstanceArgs.TreatUnionsAsParts)
		TreatUnionsAsParts.OnInput:Connect(function()
			SaveInstanceArgs.TreatUnionsAsParts = TreatUnionsAsParts.Toggled
		end)

		local NotCreatableFixes = AddTextbox("Not Creatable Fixes", table.concat(SaveInstanceArgs.NotCreatableFixes, ","), 90)
		NotCreatableFixes.TextBox.FocusLost:Connect(function()
			SaveInstanceArgs.NotCreatableFixes = parseSimpleList(NotCreatableFixes.TextBox.Text)
		end)

		AddSeperator("File")

		local FileNameFormat = AddTextbox("File Name Format", getSaveInstanceFormat(), 140)
		FileNameFormat.TextBox.FocusLost:Connect(function()
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

		AddText("Extra Options JSON can override top-level USSI options like Anonymous tables or custom IgnoreList maps.")
		local ExtraOptions = AddTextbox("Extra Options JSON", ExtraOptionsJson, 180)
		ExtraOptions.TextBox.FocusLost:Connect(function()
			ExtraOptionsJson = tostring(ExtraOptions.TextBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
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
		Button.MouseButton1Click:Connect(function()
			local fileName = Main.FormatFileName(FilenameTextBox.TextBox.Text)
			local saveOptions, optionsErr = buildSaveOptions()
			if not saveOptions then
				window:SetTitle("Save Instance - "..tostring(optionsErr))
				task.wait(2)
				window:SetTitle("Save Instance")
				return
			end
			window:SetTitle("Save Instance - Saving")
			local s, result = pcall(env.saveinstance, game, fileName, saveOptions)
			if s then
				window:SetTitle("Save Instance - Saved")
			else
				window:SetTitle("Save Instance - Error")
				task.spawn(error("Failed to save the game: "..result))
			end
			task.wait(5)
			window:SetTitle("Save Instance")
			---env.saveinstance(game, fileName, SaveInstanceArgs)
		end)
	end

return SaveInstance
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
