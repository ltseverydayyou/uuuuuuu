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

--[[
	Save Instance App Module
	
	Revival of the old dex's Save Instance
]] 

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Console, SettingsWindow, ThemeManager, Notebook -- Major Apps
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
	Console = Apps.Console
	SettingsWindow = Apps.SettingsWindow
	ThemeManager = Apps.ThemeManager
	Notebook = Apps.Notebook
end

local function trackConn(conn)
	if Main and Main.TrackConn then
		return Main.TrackConn(conn)
	end
	return conn
end
local function main()
	local SettingsWindow = {}
	local window, ListFrame
	local applyLiveSettings = function() end
	local windowSizePersistToken = 0

	local function setWindowTitleSuffix(text, duration)
		if not window then
			return
		end

		window:SetTitle("Settings - "..text)
		task.delay(duration or 1.5, function()
			if window and not window.Closed then
				window:SetTitle("Settings")
			end
		end)
	end
	
	local function makeRow(title, width, height)
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.BackgroundTransparency = 1
		frame.Gui.Size = UDim2.new(1, -8, 0, height or 26)
		local label = Lib.Label.new()
		label.Gui.Parent = frame.Gui
		label.Gui.Size = UDim2.new(1, -(width or 0) - 10, 1, 0)
		label.Gui.Text = title
		label.Gui.TextTruncate = Enum.TextTruncate.AtEnd
		Lib.BindTheme(label.Gui, {TextColor3 = "Text"})
		return frame.Gui
	end
	local function AddCheckbox(title, default)
		local row = makeRow(title, 18)
		local box = Lib.Checkbox.new()
		box.Gui.Size = UDim2.new(0, 18, 0, 18)
		box.Gui.Position = UDim2.new(1, -18, 0.5, -9)
		box.Gui.Parent = row
		box:SetState(default == true)
		return box
	end
	local function AddTextbox(title, default, sizeX)
		local width = math.max(60, sizeX or 70)
		local row = makeRow(title, width)
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(0, width, 0, 22)
		box.Position = UDim2.new(1, -width, 0.5, -11)
		box.ClearTextOnFocus = false
		box.Font = Lib.GetUIFont()
		box.TextSize = 14
		box.Text = default == nil and "" or tostring(default)
		Lib.BindTheme(box, {BackgroundColor3 = "TextBox", TextColor3 = "Text", BorderColor3 = "Outline3"})
		box.Parent = row
		return box
	end
	local function AddDropdown(title, options, default, allowEmpty, sizeX)
		local width = math.max(80, sizeX or 100)
		local row = makeRow(title, width)
		local box = Lib.DropDown.new()
		box.CanBeEmpty = allowEmpty ~= false
		box.Size = UDim2.new(0, width, 0, 22)
		box.Position = UDim2.new(1, -width, 0.5, -11)
		box:SetOptions(options)
		if default then box:SetSelected(default) end
		box.Gui.Parent = row
		return box
	end
	local function AddButton(title, buttonText, sizeX)
		local width = math.max(60, sizeX or 70)
		local row = makeRow(title, width)
		local btn = Lib.Button.new()
		btn.Size = UDim2.new(0, width, 0, 22)
		btn.Position = UDim2.new(1, -width, 0.5, -11)
		btn.Text = buttonText or "Run"
		btn.Gui.Parent = row
		return btn
	end
	local function AddSeperator(title)
		local row = makeRow(title, 0, 28)
		return row
	end
	local function AddText(text)
		local row = makeRow("", 0, 36)
		local label = Lib.Label.new()
		label.Gui.Parent = row
		label.Size = UDim2.new(1, 0, 1, 0)
		label.Text = text
		label.Gui.TextWrapped = true
		Lib.BindTheme(label.Gui, {TextColor3 = "PlaceholderText"})
		return label
	end

	local function persistSettings()
		if Main and Main.ValidateSettings then
			pcall(Main.ValidateSettings)
		end
		pcall(applyLiveSettings)

		local saved = false
		if Main and Main.SaveCurrentSettings then
			local okSave, result = pcall(Main.SaveCurrentSettings)
			saved = okSave and result == true
			if saved then
				return true
			end
		end

		local writeFn = (env and env.writefile) or writefile
		if Main and Main.ExportSettings and type(writeFn) == "function" then
			local ok, encoded = pcall(Main.ExportSettings)
			if ok and encoded then
				local settingsPath = (Main and Main.SettingsFile) or "DexPlusSettings.json"
				local okWrite = pcall(writeFn, settingsPath, encoded)
				saved = okWrite
			end
		end

		return saved
	end

	local function persistUserSettings()
		if Main and Main.SaveUserSettings then
			pcall(Main.SaveUserSettings)
			return
		end

		local writeFn = (env and env.writefile) or writefile
		if type(writeFn) == "function" and Main and Main.UserSettings and service and service.HttpService then
			local ok, encoded = pcall(service.HttpService.JSONEncode, service.HttpService, Main.UserSettings)
			if ok and encoded then
				local fileName = (Main and Main.UserSettingsFile) or "DexPlusUserSettings.json"
				pcall(writeFn, fileName, encoded)
			end
		end
	end
	
	SettingsWindow.ReloadPrompt = function()		
		local win = ScriptViewer.ReloadPromptWindow
		if not win then
			win = Lib.Window.new()
			win.Alignable = false
			win.Resizable = false
			win:SetTitle("Apply Current Settings")
			win:SetSize(300,115)

			local reloadButton = Lib.Button.new()
			local nameLabel = Lib.Label.new()
			nameLabel.Text = "By applying current settings requires reload.\nAny unsaved progress will be lost.\nAre you sure?"
			nameLabel.Position = UDim2.new(0,30,0,20)
			nameLabel.Size = UDim2.new(0,40,0,20)
			win:Add(nameLabel)

			local cancelButton = Lib.Button.new()
			cancelButton.AnchorPoint = Vector2.new(1,1)
			cancelButton.Text = "Apply Later"
			cancelButton.Position = UDim2.new(1,-5,1,-5)
			cancelButton.Size = UDim2.new(0.5,-10,0,20)
			Main.Connect(cancelButton.OnClick, function()
				win:Close()
			end)
			win:Add(cancelButton)

			reloadButton.Text = "Apply Now"
			reloadButton.AnchorPoint = Vector2.new(0,1)
			reloadButton.Position = UDim2.new(0,5,1,-5)
			reloadButton.Size = UDim2.new(0.5,-5,0,20)
			Main.Connect(reloadButton.OnClick, function()
				if SettingsWindow.__Reloading then
					return
				end

				SettingsWindow.__Reloading = true
				reloadButton.Text = "Restarting..."

				task.defer(function()
					if Main and Main.Reinit then
						Main.Reinit()
					elseif Main and Main.Exit and Main.Init then
						Main.Exit(true)
						task.wait()
						Main.Init()
					end
				end)
			end)

			win:Add(reloadButton,"reloadButton")

			SettingsWindow.ReloadPromptWindow = win
		end
		win:Show()
	end
	
	SettingsWindow.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Settings")
		local w, h = Lib.FitSize(Settings.Window.SettingsWidth or 380, Settings.Window.SettingsHeight or 520)
		window.MinX = math.min(340, w)
		window.MinY = math.min(280, h)
		window:Resize(w, h)
		SettingsWindow.Window = window

		Main.Connect(window.GuiElems.Main:GetPropertyChangedSignal("Size"), function()
			if not window or window.Closed then
				return
			end

			local sizeX = math.floor(tonumber(window.SizeX) or window.GuiElems.Main.AbsoluteSize.X or Settings.Window.SettingsWidth or 250)
			local sizeY = math.floor(tonumber(window.SizeY) or window.GuiElems.Main.AbsoluteSize.Y or Settings.Window.SettingsHeight or 375)
			sizeX = math.clamp(sizeX, 340, 800)
			sizeY = math.clamp(sizeY, 280, 700)

			Settings.Window.SettingsWidth = sizeX
			Settings.Window.SettingsHeight = sizeY

			windowSizePersistToken = windowSizePersistToken + 1
			local token = windowSizePersistToken
			task.delay(0.35, function()
				if token ~= windowSizePersistToken or not window or window.Closed then
					return
				end
				persistSettings()
			end)
		end)

		local sectionAnchors = {}
		local quickTabButtons = {}
		local currentSectionName = "UI"

		local tabsFrame = Instance.new("Frame")
		tabsFrame.Parent = window.GuiElems.Content
		tabsFrame.BackgroundTransparency = 1
		tabsFrame.Size = UDim2.new(1, 0, 0, 28)
		tabsFrame.ZIndex = 3

		local tabsScroller = Instance.new("ScrollingFrame")
		tabsScroller.Parent = tabsFrame
		tabsScroller.Active = true
		tabsScroller.BackgroundTransparency = 1
		tabsScroller.BorderSizePixel = 0
		tabsScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
		tabsScroller.AutomaticCanvasSize = Enum.AutomaticSize.X
		tabsScroller.ScrollingDirection = Enum.ScrollingDirection.X
		tabsScroller.ScrollBarThickness = 0
		tabsScroller.Size = UDim2.new(1, 0, 1, 0)
		tabsScroller.ZIndex = 3

		local tabsPadding = Instance.new("UIPadding")
		tabsPadding.Parent = tabsScroller
		tabsPadding.PaddingLeft = UDim.new(0, 6)
		tabsPadding.PaddingRight = UDim.new(0, 6)
		tabsPadding.PaddingTop = UDim.new(0, 4)
		tabsPadding.PaddingBottom = UDim.new(0, 4)

		local tabsLayout = Instance.new("UIListLayout")
		tabsLayout.Parent = tabsScroller
		tabsLayout.FillDirection = Enum.FillDirection.Horizontal
		tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
		tabsLayout.Padding = UDim.new(0, 4)

		-- ListFrame
		ListFrame = Instance.new("ScrollingFrame")
		ListFrame.Parent = window.GuiElems.Content
		ListFrame.Size = UDim2.new(1, 0,1, -48)
		ListFrame.Position = UDim2.new(0, 0, 0, 28)
		ListFrame.BackgroundTransparency = 1
		ListFrame.CanvasSize = UDim2.new(0,0,0,0)
		ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		ListFrame.ScrollBarThickness = 6
		ListFrame.BottomImage = ""
		ListFrame.TopImage = ""
		ListFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
		ListFrame.ScrollBarImageTransparency = 0
		ListFrame.ZIndex = 2
		ListFrame.BorderSizePixel = 0
		
		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Parent = ListFrame
		ListLayout.Padding = UDim.new(0, 5)
		
		local Padding = Instance.new("UIPadding")
		Padding.Parent = ListFrame
		Padding.PaddingBottom = UDim.new(0, 5)
		Padding.PaddingLeft = UDim.new(0, 10)
		Padding.PaddingRight = UDim.new(0, 10)
		Padding.PaddingTop = UDim.new(0, 5)

		local function applyExplorerRefresh(alsoReconnect)
			if not Explorer then return end
			if alsoReconnect and Explorer.SetupConnections then
				pcall(Explorer.SetupConnections)
			end
			if Explorer.Update then
				pcall(Explorer.Update)
			end
			if Explorer.Refresh then
				pcall(Explorer.Refresh)
			end
			if Explorer.UpdateView then
				pcall(Explorer.UpdateView)
			end
		end

		local function applyPropertiesRefresh(rebuildList)
			if not Properties then return end
			if rebuildList and Properties.ShowExplorerProps then
				pcall(Properties.ShowExplorerProps)
				return
			end
			if Properties.Refresh then
				pcall(Properties.Refresh)
			end
		end

		applyLiveSettings = function()
			if Lib and Lib.RefreshTheme then
				pcall(Lib.RefreshTheme)
			end
			if Properties and Properties.ApplySettings then
				pcall(Properties.ApplySettings)
			end
		end

		SettingsWindow.ApplyLiveSettings = function()
			pcall(applyLiveSettings)
		end

		local function updateQuickTabState(selectedName)
			currentSectionName = selectedName
			for name, button in quickTabButtons do
				if name == selectedName then
					button.BackgroundColor3 = Settings.Theme.ListSelection
				else
					button.BackgroundColor3 = Settings.Theme.Button
				end
			end
		end

		local function scrollToSection(sectionName)
			local anchor = sectionAnchors[sectionName]
			if not anchor then
				return
			end

			updateQuickTabState(sectionName)

			Main.UserSettings = Main.UserSettings or {}
			if Main.UserSettings.RememberLastSettingsTab ~= false and Main.UserSettings.SettingsLastTab ~= sectionName then
				Main.UserSettings.SettingsLastTab = sectionName
				persistUserSettings()
			end

			local anchorGui = typeof(anchor) == "Instance" and anchor or anchor.Gui
			local maxY = math.max(0, ListFrame.AbsoluteCanvasSize.Y - ListFrame.AbsoluteWindowSize.Y)
			local targetY = ListFrame.CanvasPosition.Y + (anchorGui.AbsolutePosition.Y - ListFrame.AbsolutePosition.Y) - 4
			ListFrame.CanvasPosition = Vector2.new(ListFrame.CanvasPosition.X, math.clamp(targetY, 0, maxY))
		end

		local function createQuickTab(sectionName)
			local button = Instance.new("TextButton")
			button.Parent = tabsScroller
			button.AutoButtonColor = false
			button.BackgroundColor3 = Settings.Theme.Button
			button.BorderColor3 = Settings.Theme.Outline2
			button.BorderSizePixel = 0
			button.Size = UDim2.new(0, 78, 1, -8)
			button.Font = Enum.Font.SourceSans
			button.Text = sectionName
			button.TextColor3 = Settings.Theme.Text
			button.TextSize = 14
			button.ZIndex = 4
			Main.Connect(button.MouseButton1Click, function()
				scrollToSection(sectionName)
			end)
			quickTabButtons[sectionName] = button
		end
		
		-- Options
		
		sectionAnchors.UI = AddSeperator("UI")
		AddText("Use the tabs above to jump between sections.")
		
		local titleonmiddle = AddCheckbox("Window Title On Middle", Settings.Window.TitleOnMiddle)
		Main.Connect(titleonmiddle.OnInput, function()
			Settings.Window.TitleOnMiddle = titleonmiddle.Toggled
			persistSettings()
		end)
		
		local bgTransparency = AddTextbox("Background Transparency", tostring(Settings.Window.Transparency), 15)
		Main.Connect(bgTransparency.FocusLost, function()
			local input = tonumber(bgTransparency.Text)
			if input == nil then
				bgTransparency.Text = tostring(Settings.Window.Transparency)
				return
			end

			input = math.clamp(input, 0, 1)
			Settings.Window.Transparency = input
			bgTransparency.Text = tostring(input)
			persistSettings()

			if Lib and Lib.RefreshTheme then
				pcall(Lib.RefreshTheme)
			end
		end)
		
		local textSize = AddTextbox("UI Text Size", Settings.Window.TextSize, 60)
		Main.Connect(textSize.FocusLost, function()
			Settings.Window.TextSize = math.clamp(math.floor(tonumber(textSize.Text) or Settings.Window.TextSize), 12, 20)
			textSize.Text = tostring(Settings.Window.TextSize)
			persistSettings()
		end)
		local radius = AddTextbox("Corner Radius", Settings.Window.CornerRadius, 60)
		Main.Connect(radius.FocusLost, function()
			Settings.Window.CornerRadius = math.clamp(math.floor(tonumber(radius.Text) or Settings.Window.CornerRadius), 0, 12)
			radius.Text = tostring(Settings.Window.CornerRadius)
			persistSettings()
		end)
		local motion = AddCheckbox("Reduced Motion", Settings.Window.ReducedMotion)
		Main.Connect(motion.OnInput, function()
			Settings.Window.ReducedMotion = motion.Toggled
			persistSettings()
		end)

		local classIcon = AddDropdown("Class Icons", {"NewDark", "Vanilla3", "Old"}, Settings.ClassIcon, false, 100)
		Main.Connect(classIcon.OnSelect, function()
			Settings.ClassIcon = classIcon.Selected
			persistSettings()
		end)

		local uiFonts = {"SourceSans", "Gotham", "GothamMedium", "GothamSemibold", "GothamBold", "RobotoMono", "Code", "Ubuntu"}
		if not table.find(uiFonts, Settings.Window.Font) then
			Settings.Window.Font = "SourceSans"
		end
		local uiFont = AddDropdown("UI Font", uiFonts, Settings.Window.Font, false, 120)
		Main.Connect(uiFont.OnSelect, function()
			Settings.Window.Font = uiFont.Selected
			persistSettings()
			if Lib and Lib.RefreshTheme then
				pcall(Lib.RefreshTheme)
			end
		end)

		Settings.Explorer = Settings.Explorer or {}
		local guiSelectionBox = AddCheckbox("GUI Selection Box", Settings.Explorer.GuiSelectionBox)
		Main.Connect(guiSelectionBox.OnInput, function()
			Settings.Explorer.GuiSelectionBox = guiSelectionBox.Toggled
			persistSettings()
			if Explorer and Explorer.UpdateSelectionVisuals then
				pcall(Explorer.UpdateSelectionVisuals)
			end
		end)

		local selectorScopes = {"PlayerGui", "CoreGui", "gethui", "All"}
		local selectorScope = Settings.Explorer.GuiSelectorScope
		if not table.find(selectorScopes, selectorScope) then
			selectorScope = "PlayerGui"
			Settings.Explorer.GuiSelectorScope = selectorScope
		end
		local guiSelectorScope = AddDropdown("GUI Selector Source", selectorScopes, selectorScope, false, 90)
		Main.Connect(guiSelectorScope.OnSelect, function()
			Settings.Explorer.GuiSelectorScope = guiSelectorScope.Selected
			persistSettings()
		end)

		local ignoreInvisibleUI = AddCheckbox("Ignore Invisible UI", Settings.Explorer.IgnoreInvisibleUI ~= false)
		Main.Connect(ignoreInvisibleUI.OnInput, function()
			Settings.Explorer.IgnoreInvisibleUI = ignoreInvisibleUI.Toggled
			persistSettings()
		end)

		AddText("Resize this window directly; the size is saved automatically.")

		Main.UserSettings = Main.UserSettings or {}
		local rememberLastTab = AddCheckbox("Remember Last Settings Tab", Main.UserSettings.RememberLastSettingsTab ~= false)
		Main.Connect(rememberLastTab.OnInput, function()
			Main.UserSettings.RememberLastSettingsTab = rememberLastTab.Toggled
			if rememberLastTab.Toggled then
				Main.UserSettings.SettingsLastTab = currentSectionName
			end
			persistUserSettings()
		end)
		AddText("Changing class icons requires restart.")

		sectionAnchors.Startup = AddSeperator("Startup")
		AddText("These options apply the next time Dex starts or restarts.")

		Settings.Startup = Settings.Startup or {}

		local explorerStartupSide = AddDropdown("Explorer Window Side", {"Left", "Right"}, Settings.Startup.ExplorerSide or "Right", false, 90)
		Main.Connect(explorerStartupSide.OnSelect, function()
			Settings.Startup.ExplorerSide = explorerStartupSide.Selected
			persistSettings()
		end)

		local propertiesStartupSide = AddDropdown("Properties Window Side", {"Left", "Right"}, Settings.Startup.PropertiesSide or "Right", false, 90)
		Main.Connect(propertiesStartupSide.OnSelect, function()
			Settings.Startup.PropertiesSide = propertiesStartupSide.Selected
			persistSettings()
		end)

		local openExplorerOnStartup = AddCheckbox("Open Explorer On Startup", Settings.Startup.OpenExplorer ~= false)
		Main.Connect(openExplorerOnStartup.OnInput, function()
			Settings.Startup.OpenExplorer = openExplorerOnStartup.Toggled
			persistSettings()
		end)

		local openPropertiesOnStartup = AddCheckbox("Open Properties On Startup", Settings.Startup.OpenProperties ~= false)
		Main.Connect(openPropertiesOnStartup.OnInput, function()
			Settings.Startup.OpenProperties = openPropertiesOnStartup.Toggled
			persistSettings()
		end)

		AddText("You can start with both, one, or neither window open.")
		
		sectionAnchors.Explorer = AddSeperator("Explorer")

		local sorting = AddCheckbox("Sorting", Settings.Explorer.Sorting)
		Main.Connect(sorting.OnInput, function()
			Settings.Explorer.Sorting = sorting.Toggled
			if Explorer and Explorer.SetSortingEnabled then
				pcall(Explorer.SetSortingEnabled, sorting.Toggled)
			end
			persistSettings()
			applyExplorerRefresh()
		end)
		
		local clickRename = AddCheckbox("Click to Rename", Settings.Explorer.ClickToRename)
		Main.Connect(clickRename.OnInput, function()
			Settings.Explorer.ClickToRename = clickRename.Toggled
			persistSettings()
		end)

		local autoUpdateSearch = AddCheckbox("Auto Update Search", Settings.Explorer.AutoUpdateSearch)
		Main.Connect(autoUpdateSearch.OnInput, function()
			Settings.Explorer.AutoUpdateSearch = autoUpdateSearch.Toggled
			if Explorer and Explorer.SetAutoUpdateSearch then
				pcall(Explorer.SetAutoUpdateSearch, autoUpdateSearch.Toggled)
			end
			persistSettings()
		end)

		local showNilInstances = AddCheckbox("Show Nil Instances Folder", Settings.Explorer.ShowNilInstances == true)
		Main.Connect(showNilInstances.OnInput, function()
			Settings.Explorer.ShowNilInstances = showNilInstances.Toggled
			if not showNilInstances.Toggled then
				Settings.Explorer.SearchNilInstances = false
			end
			persistSettings()
			if Explorer and Explorer.SetNilInstancesEnabled then
				pcall(Explorer.SetNilInstancesEnabled, showNilInstances.Toggled)
			else
				applyExplorerRefresh()
			end
		end)

		local searchNilInstances = AddCheckbox("Search Nil Instances", Settings.Explorer.SearchNilInstances == true)
		Main.Connect(searchNilInstances.OnInput, function()
			Settings.Explorer.SearchNilInstances = searchNilInstances.Toggled
			if searchNilInstances.Toggled then
				Settings.Explorer.ShowNilInstances = true
				if Explorer and Explorer.SetNilInstancesEnabled then
					pcall(Explorer.SetNilInstancesEnabled, true)
				end
			end
			persistSettings()
			applyExplorerRefresh()
		end)

		AddText("Nil instance scanning calls getnilinstances only after enabling it.")

		local freezeNilInstances = AddCheckbox("Freeze Nil Instances", Settings.Explorer.FreezeNilInstances == true)
		Main.Connect(freezeNilInstances.OnInput, function()
			Settings.Explorer.FreezeNilInstances = freezeNilInstances.Toggled
			persistSettings()
			if not freezeNilInstances.Toggled and Settings.Explorer.ShowNilInstances == true and Explorer and Explorer.RefreshNilInstances then
				pcall(Explorer.RefreshNilInstances)
			end
		end)

		local freezeSearchEnabled = AddCheckbox("Freeze Search", Settings.Explorer.FreezeSearchEnabled == true)
		Main.Connect(freezeSearchEnabled.OnInput, function()
			Settings.Explorer.FreezeSearchEnabled = freezeSearchEnabled.Toggled
			persistSettings()
		end)

		local freezeSearchTerm = AddTextbox("Freeze Search Term", Settings.Explorer.FreezeSearchTerm or "", 120)
		Main.Connect(freezeSearchTerm.FocusLost, function()
			Settings.Explorer.FreezeSearchTerm = freezeSearchTerm.Text or ""
			persistSettings()
		end)

		local freezeSearchClassName = AddCheckbox("Freeze Search Matches ClassName", Settings.Explorer.FreezeSearchClassName == true)
		Main.Connect(freezeSearchClassName.OnInput, function()
			Settings.Explorer.FreezeSearchClassName = freezeSearchClassName.Toggled
			persistSettings()
		end)

		local advancedPropertySearch = AddCheckbox("Advanced Property Search", Settings.Explorer.AdvancedPropertySearch ~= false)
		Main.Connect(advancedPropertySearch.OnInput, function()
			Settings.Explorer.AdvancedPropertySearch = advancedPropertySearch.Toggled
			persistSettings()
		end)

		local dragReparenting = AddCheckbox("Drag Reparenting", Settings.Explorer.DragReparenting ~= false)
		Main.Connect(dragReparenting.OnInput, function()
			Settings.Explorer.DragReparenting = dragReparenting.Toggled
			persistSettings()
		end)

		local pinnedObjects = AddCheckbox("Pinned Objects", Settings.Explorer.PinnedObjects ~= false)
		Main.Connect(pinnedObjects.OnInput, function()
			Settings.Explorer.PinnedObjects = pinnedObjects.Toggled
			persistSettings()
			applyExplorerRefresh()
		end)

		local stickyExplorerHeader = AddCheckbox("Sticky Explorer Header", Settings.Explorer.StickyExplorerHeader ~= false)
		Main.Connect(stickyExplorerHeader.OnInput, function()
			Settings.Explorer.StickyExplorerHeader = stickyExplorerHeader.Toggled
			persistSettings()
			applyExplorerRefresh()
		end)

		local cameraFollowSelection = AddCheckbox("Camera Follow Selection", Settings.Explorer.CameraFollowSelection == true)
		Main.Connect(cameraFollowSelection.OnInput, function()
			Settings.Explorer.CameraFollowSelection = cameraFollowSelection.Toggled
			persistSettings()
			if Explorer and Explorer.UpdateCameraFollow then
				pcall(Explorer.UpdateCameraFollow)
			end
		end)

		local keyboardShortcuts = AddCheckbox("Keyboard Shortcuts", Settings.Explorer.KeyboardShortcuts ~= false)
		Main.Connect(keyboardShortcuts.OnInput, function()
			Settings.Explorer.KeyboardShortcuts = keyboardShortcuts.Toggled
			persistSettings()
		end)

		local autoUpdateModeLabels = {
			[0] = "Default",
			[1] = "Quiet Refresh",
			[2] = "Manual Tree",
			[3] = "Frozen",
		}
		local autoUpdateMode = AddDropdown("Auto Update Mode", {"Default", "Quiet Refresh", "Manual Tree", "Frozen"}, autoUpdateModeLabels[tonumber(Settings.Explorer.AutoUpdateMode) or 0] or "Default", false, 110)
		Main.Connect(autoUpdateMode.OnSelect, function()
			local mapped = 0
			if autoUpdateMode.Selected == "Quiet Refresh" then
				mapped = 1
			elseif autoUpdateMode.Selected == "Manual Tree" then
				mapped = 2
			elseif autoUpdateMode.Selected == "Frozen" then
				mapped = 3
			end
			Settings.Explorer.AutoUpdateMode = mapped
			persistSettings()
			applyExplorerRefresh(true)
		end)
		AddText("Quiet Refresh keeps data fresh but stops auto-redrawing the tree.")
		
		local partSelectionBox = AddCheckbox("Part Selection Box", Settings.Explorer.PartSelectionBox)
		Main.Connect(partSelectionBox.OnInput, function()
			Settings.Explorer.PartSelectionBox = partSelectionBox.Toggled
			persistSettings()
			if Explorer and Explorer.UpdateSelectionVisuals then
				pcall(Explorer.UpdateSelectionVisuals)
			end
		end)

		local copypathUseChildren = AddCheckbox("Use GetChildren to Copy Path", Settings.Explorer.CopyPathUseGetChildren)
		Main.Connect(copypathUseChildren.OnInput, function()
			Settings.Explorer.CopyPathUseGetChildren = copypathUseChildren.Toggled
			persistSettings()
		end)

		local useNameWidth = AddCheckbox("Use Name Width", Settings.Explorer.UseNameWidth)
		Main.Connect(useNameWidth.OnInput, function()
			Settings.Explorer.UseNameWidth = useNameWidth.Toggled
			persistSettings()
			applyExplorerRefresh(true)
		end)

		local maxSelectionBoxes = AddTextbox("Max Selection Boxes", tostring(Settings.Explorer.MaxSelectionBoxes), 70)
		Main.Connect(maxSelectionBoxes.FocusLost, function()
			local n = tonumber(maxSelectionBoxes.Text)
			if not n then
				maxSelectionBoxes.Text = tostring(Settings.Explorer.MaxSelectionBoxes)
				return
			end
			n = math.clamp(math.floor(n), 0, 5000)
			Settings.Explorer.MaxSelectionBoxes = n
			maxSelectionBoxes.Text = tostring(n)
			persistSettings()
			if Explorer and Explorer.UpdateSelectionVisuals then
				pcall(Explorer.UpdateSelectionVisuals)
			end
		end)

		local writeRemoteAttr = AddCheckbox("Write Remote Block Attr", Settings.RemoteBlockWriteAttribute)
		Main.Connect(writeRemoteAttr.OnInput, function()
			Settings.RemoteBlockWriteAttribute = writeRemoteAttr.Toggled
			persistSettings()
		end)

		local function bindOffsetTextbox(label, axis)
			local curOffset = Settings.Explorer.TeleportToOffset
			local curValue = (axis == "X" and curOffset.X) or (axis == "Y" and curOffset.Y) or curOffset.Z
			local tb = AddTextbox(label, tostring(curValue), 70)
			Main.Connect(tb.FocusLost, function()
				local n = tonumber(tb.Text)
				if n == nil then
					local offset = Settings.Explorer.TeleportToOffset
					local axisValue = (axis == "X" and offset.X) or (axis == "Y" and offset.Y) or offset.Z
					tb.Text = tostring(axisValue)
					return
				end
				local offset = Settings.Explorer.TeleportToOffset
				local x, y, z = offset.X, offset.Y, offset.Z
				if axis == "X" then
					x = n
				elseif axis == "Y" then
					y = n
				elseif axis == "Z" then
					z = n
				end
				Settings.Explorer.TeleportToOffset = Vector3.new(x, y, z)
				tb.Text = tostring(n)
				persistSettings()
			end)
		end
		bindOffsetTextbox("Teleport Offset X", "X")
		bindOffsetTextbox("Teleport Offset Y", "Y")
		bindOffsetTextbox("Teleport Offset Z", "Z")
		
		sectionAnchors.Properties = AddSeperator("Properties")

		local showDeprecated = AddCheckbox("Show Deprecated", Settings.Properties.ShowDeprecated)
		Main.Connect(showDeprecated.OnInput, function()
			Settings.Properties.ShowDeprecated = showDeprecated.Toggled
			persistSettings()
			applyPropertiesRefresh(true)
		end)
		
		local showHidden = AddCheckbox("Show Hidden", Settings.Properties.ShowHidden)
		Main.Connect(showHidden.OnInput, function()
			Settings.Properties.ShowHidden = showHidden.Toggled
			persistSettings()
			applyPropertiesRefresh(true)
		end)
		
		local showAttributes = AddCheckbox("Show Attributes", Settings.Properties.ShowAttributes)
		Main.Connect(showAttributes.OnInput, function()
			Settings.Properties.ShowAttributes = showAttributes.Toggled
			persistSettings()
			applyPropertiesRefresh(true)
		end)

		local clearOnFocus = AddCheckbox("Clear On Focus", Settings.Properties.ClearOnFocus)
		Main.Connect(clearOnFocus.OnInput, function()
			Settings.Properties.ClearOnFocus = clearOnFocus.Toggled
			persistSettings()
		end)

		local loadstringInput = AddCheckbox("Loadstring Input", Settings.Properties.LoadstringInput)
		Main.Connect(loadstringInput.OnInput, function()
			Settings.Properties.LoadstringInput = loadstringInput.Toggled
			persistSettings()
		end)

		local maxConflictCheck = AddTextbox("Max Conflict Check", tostring(Settings.Properties.MaxConflictCheck), 70)
		Main.Connect(maxConflictCheck.FocusLost, function()
			local n = tonumber(maxConflictCheck.Text)
			if not n then
				maxConflictCheck.Text = tostring(Settings.Properties.MaxConflictCheck)
				return
			end
			n = math.clamp(math.floor(n), 1, 5000)
			Settings.Properties.MaxConflictCheck = n
			maxConflictCheck.Text = tostring(n)
			persistSettings()
			applyPropertiesRefresh(true)
		end)

		local maxAttributes = AddTextbox("Max Attributes", tostring(Settings.Properties.MaxAttributes), 70)
		Main.Connect(maxAttributes.FocusLost, function()
			local n = tonumber(maxAttributes.Text)
			if not n then
				maxAttributes.Text = tostring(Settings.Properties.MaxAttributes)
				return
			end
			n = math.clamp(math.floor(n), 0, 1000)
			Settings.Properties.MaxAttributes = n
			maxAttributes.Text = tostring(n)
			persistSettings()
			applyPropertiesRefresh(true)
		end)

		local numberRounding = AddTextbox("Number Rounding", tostring(Settings.Properties.NumberRounding), 70)
		Main.Connect(numberRounding.FocusLost, function()
			local n = tonumber(numberRounding.Text)
			if not n then
				numberRounding.Text = tostring(Settings.Properties.NumberRounding)
				return
			end
			n = math.clamp(math.floor(n), 0, 10)
			Settings.Properties.NumberRounding = n
			numberRounding.Text = tostring(n)
			persistSettings()
			applyPropertiesRefresh()
		end)

		local scaleTypeLabel = (tonumber(Settings.Properties.ScaleType) == 1) and "Equal Halves" or "Full Name"
		local scaleType = AddDropdown("Scale Type", {"Full Name", "Equal Halves"}, scaleTypeLabel, false, 100)
		Main.Connect(scaleType.OnSelect, function()
			Settings.Properties.ScaleType = (scaleType.Selected == "Equal Halves") and 1 or 0
			persistSettings()
			applyPropertiesRefresh()
		end)
		
		sectionAnchors.Viewer = AddSeperator("Script Viewer")
		
		local showMoreInfo = AddCheckbox("Show Decompiled Script Info", Settings.ScriptViewer.ShowMoreInfo)
		Main.Connect(showMoreInfo.OnInput, function()
			Settings.ScriptViewer.ShowMoreInfo = showMoreInfo.Toggled
			persistSettings()
			if ScriptViewer and ScriptViewer.RefreshCurrentView then
				pcall(ScriptViewer.RefreshCurrentView)
			end
		end)

		local defaultTextSize = (Main and Main.UserSettings and Main.UserSettings.ScriptViewerTextSize) or 16
		local scriptTextSize = AddTextbox("Editor Text Size", tostring(defaultTextSize), 60)
		Main.Connect(scriptTextSize.FocusLost, function()
			local n = tonumber(scriptTextSize.Text)
			if not n then
				n = (Main and Main.UserSettings and Main.UserSettings.ScriptViewerTextSize) or 16
				scriptTextSize.Text = tostring(n)
				return
			end
			n = math.clamp(math.floor(n), 1, 64)
			Main.UserSettings = Main.UserSettings or {}
			Main.UserSettings.ScriptViewerTextSize = n
			scriptTextSize.Text = tostring(n)
			if ScriptViewer and ScriptViewer.SetTextSize then
				pcall(ScriptViewer.SetTextSize, n)
			else
				persistUserSettings()
			end
		end)
		AddText("Editor text size updates live.")

		sectionAnchors.Console = AddSeperator("Console")
		Main.UserSettings = Main.UserSettings or {}
		Main.UserSettings.ConsoleFilters = Main.UserSettings.ConsoleFilters or {
			Output = true,
			Info = true,
			Warn = true,
			Error = true,
			Listen = true,
		}

		local function bindConsoleFilter(filterName, label)
			local checkbox = AddCheckbox(label, Main.UserSettings.ConsoleFilters[filterName] ~= false)
			Main.Connect(checkbox.OnInput, function()
				Main.UserSettings.ConsoleFilters[filterName] = checkbox.Toggled
				persistUserSettings()
			end)
		end
		bindConsoleFilter("Output", "Output Messages")
		bindConsoleFilter("Info", "Info Messages")
		bindConsoleFilter("Warn", "Warning Messages")
		bindConsoleFilter("Error", "Error Messages")
		bindConsoleFilter("Listen", "Remote Listener")

		local consoleTextSize = AddTextbox("Console Text Size", tostring(Main.UserSettings.ConsoleTextSize or 15), 60)
		Main.Connect(consoleTextSize.FocusLost, function()
			local n = tonumber(consoleTextSize.Text)
			if not n then
				consoleTextSize.Text = tostring(Main.UserSettings.ConsoleTextSize or 15)
				return
			end
			n = math.clamp(math.floor(n), 1, 64)
			Main.UserSettings.ConsoleTextSize = n
			consoleTextSize.Text = tostring(n)
			if Console and Console.SetTextSize then
				pcall(Console.SetTextSize, n)
			else
				persistUserSettings()
			end
		end)

		local consoleOutputLimit = AddTextbox("Console Output Limit", tostring(Main.UserSettings.ConsoleOutputLimit or 500), 60)
		Main.Connect(consoleOutputLimit.FocusLost, function()
			local n = tonumber(consoleOutputLimit.Text)
			if not n then
				consoleOutputLimit.Text = tostring(Main.UserSettings.ConsoleOutputLimit or 500)
				return
			end
			n = math.clamp(math.floor(n), 10, 5000)
			Main.UserSettings.ConsoleOutputLimit = n
			consoleOutputLimit.Text = tostring(n)
			if Console and Console.SetOutputLimit then
				pcall(Console.SetOutputLimit, n)
			else
				persistUserSettings()
			end
		end)

		local consoleCtrlScroll = AddCheckbox("Ctrl + Wheel Resizes Output", Main.UserSettings.ConsoleCtrlScroll == true)
		Main.Connect(consoleCtrlScroll.OnInput, function()
			Main.UserSettings.ConsoleCtrlScroll = consoleCtrlScroll.Toggled
			if Console and Console.SetCtrlScrollEnabled then
				pcall(Console.SetCtrlScrollEnabled, consoleCtrlScroll.Toggled)
			else
				persistUserSettings()
			end
		end)

		local consoleAutoScroll = AddCheckbox("Auto Scroll New Output", Main.UserSettings.ConsoleAutoScroll == true)
		Main.Connect(consoleAutoScroll.OnInput, function()
			Main.UserSettings.ConsoleAutoScroll = consoleAutoScroll.Toggled
			if Console and Console.SetAutoScrollEnabled then
				pcall(Console.SetAutoScrollEnabled, consoleAutoScroll.Toggled)
			else
				persistUserSettings()
			end
		end)

		AddText("Console filters apply fully after reloading Dex.")
		
		sectionAnchors.Decompiler = AddSeperator("Decompiler")
		AddText("If executor does not support decompile, it will use the fallback option.")
		AddText("Enable 'Prefer Fallback Decompiler' to force fallback first even when built-in decompile exists.")
		AddText("'getscriptbytecode' is mandatory to use fallback decompilers.")
		local decompilerOption = {"lua.expert", "Luacid", "Konstant"}
		local decompiler = AddDropdown("Decompiler Fallback", decompilerOption, Settings.Decompiler.DecompilerFallback, false, 125)
		Main.Connect(decompiler.OnSelect, function()
			Settings.Decompiler.DecompilerFallback = decompiler.Selected
			persistSettings()
		end)

		local preferFallback = AddCheckbox("Prefer Fallback Decompiler", Settings.Decompiler.PreferDecompilerFallback)
		Main.Connect(preferFallback.OnInput, function()
			Settings.Decompiler.PreferDecompilerFallback = preferFallback.Toggled
			persistSettings()
		end)

		sectionAnchors.Themes = AddSeperator("Themes")
		AddText("Use Theme Manager for color-by-color customization.")

		local openThemeManagerButton = AddButton("Theme Manager", "Open", 70)
		Main.Connect(openThemeManagerButton.OnClick, function()
			if ThemeManager and ThemeManager.Window then
				ThemeManager.Window:Show()
			else
				setWindowTitleSuffix("Theme Manager Missing", 2)
			end
		end)

		local saveThemeButton = AddButton("Save Current Theme", "Save", 70)
		Main.Connect(saveThemeButton.OnClick, function()
			if Main and Main.SaveThemeSettings then
				local ok, err = Main.SaveThemeSettings()
				setWindowTitleSuffix(ok and "Theme Saved" or (err or "Save Failed"))
			end
		end)

		local reloadThemeButton = AddButton("Reload Theme File", "Load", 70)
		Main.Connect(reloadThemeButton.OnClick, function()
			if Main and Main.LoadThemeSettings then
				local ok, err = Main.LoadThemeSettings()
				if not ok then setWindowTitleSuffix(err or "Load Failed") return end
				if Lib and Lib.RefreshTheme then
					pcall(Lib.RefreshTheme)
				end
				setWindowTitleSuffix("Theme Reloaded")
			end
		end)

		sectionAnchors.Files = AddSeperator("Files")
		AddText("Filename tokens: {placeName} {placeId} {className} {name} {timestamp} {date} {time} {unix} {index} {count}")
		AddText("Save Instance uses the place format. Explorer and Model Viewer 'Save to File' use the object format.")

		local saveInstanceFormat = AddTextbox("Save Instance Name", Settings.Files.SaveInstanceNameFormat, 180)
		Main.Connect(saveInstanceFormat.FocusLost, function()
			local value = tostring(saveInstanceFormat.Text or "")
			if value == "" then
				value = "{placeName}_{timestamp}"
			end
			Settings.Files.SaveInstanceNameFormat = value
			saveInstanceFormat.Text = value
			persistSettings()
		end)

		local objectSaveFormat = AddTextbox("Object Save Name", Settings.Files.ObjectSaveNameFormat, 180)
		Main.Connect(objectSaveFormat.FocusLost, function()
			local value = tostring(objectSaveFormat.Text or "")
			if value == "" then
				value = "{className}_{name}_{timestamp}"
			end
			Settings.Files.ObjectSaveNameFormat = value
			objectSaveFormat.Text = value
			persistSettings()
		end)

		AddText("The restart button below saves settings, then reloads Dex.")

		local saveSettingsButton = AddButton("Write Settings File", "Save", 70)
		Main.Connect(saveSettingsButton.OnClick, function()
			if persistSettings() then
				setWindowTitleSuffix("Settings Saved")
			else
				setWindowTitleSuffix("Save Failed", 2)
			end
		end)

		local saveUserButton = AddButton("Write User Prefs", "Save", 70)
		Main.Connect(saveUserButton.OnClick, function()
			persistUserSettings()
			setWindowTitleSuffix("User Prefs Saved")
		end)

		for _, sectionName in {"UI", "Startup", "Explorer", "Properties", "Viewer", "Console", "Decompiler", "Themes", "Files"} do
			createQuickTab(sectionName)
		end

		task.defer(function()
			local lastTab = "UI"
			if Main.UserSettings and Main.UserSettings.RememberLastSettingsTab ~= false then
				lastTab = Main.UserSettings.SettingsLastTab or "UI"
			end
			if not sectionAnchors[lastTab] then
				lastTab = "UI"
			end
			scrollToSection(lastTab)
		end)
		
		-- Save buttons below
		local BackgroundreloadButton = Lib.Frame.new()
		BackgroundreloadButton.Gui.Parent = window.GuiElems.Content
		BackgroundreloadButton.Size = UDim2.new(1,0, 0,20)
		BackgroundreloadButton.Position = UDim2.new(0,0, 1,-20)
		
		local LabelreloadButton = Lib.Label.new()
		LabelreloadButton.Gui.Parent = window.GuiElems.Content
		LabelreloadButton.Size = UDim2.new(1,0, 0,20)
		LabelreloadButton.Position = UDim2.new(0,0, 1,-20)
		LabelreloadButton.Gui.Text = "Restart"
		LabelreloadButton.Gui.TextXAlignment = Enum.TextXAlignment.Center
		
		local reloadButton = Instance.new("TextButton")
		reloadButton.Parent = BackgroundreloadButton.Gui
		reloadButton.Size = UDim2.new(1,0, 1,0)
		reloadButton.Position = UDim2.new(0,0, 0,0)
		reloadButton.BackgroundTransparency = 1
		
		Main.Connect(reloadButton.MouseButton1Click, function()
			window:SetTitle("Settings - Saving")

			persistUserSettings()
			if Main and Main.SaveThemeSettings then
				pcall(Main.SaveThemeSettings)
			end

			local saved = persistSettings()
			if not saved then
				window:SetTitle("Settings - Save Failed")
				task.wait(2)
				window:SetTitle("Settings")
				return
			end
			
			window:SetTitle("Settings - Saved")
			SettingsWindow.ReloadPrompt()
			task.wait(3)
			
			window:SetTitle("Settings")
		end)

		SettingsWindow.ApplyLiveSettings()
		task.delay(0.5, function()
			if SettingsWindow.ApplyLiveSettings then
				SettingsWindow.ApplyLiveSettings()
			end
		end)
	end

	return SettingsWindow
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
