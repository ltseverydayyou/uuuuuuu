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
		
		checkbox:SetState(default or false)
		
		return checkbox
	end
	
	local function AddTextbox(title, default, sizeX)
		default = default and tostring(default) or ""
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

		return textbox
	end
	
	local function AddDropdown(title, options, default, allowEmpty, sizeX)
		if allowEmpty == nil then allowEmpty = true end
		
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
		local dropdown = Lib.DropDown.new()
		dropdown.CanBeEmpty = allowEmpty
		dropdown.Size = UDim2.new(0,sizeX or 75,0,15)
		dropdown:SetOptions(options)
		if default then dropdown:SetSelected(default) end
		dropdown.Gui.Parent = frame.Gui

		frame.Gui.AutomaticSize = Enum.AutomaticSize.X

		-- Label
		local label = Lib.Label.new()

		label.Parent = frame.Gui
		label.Size = UDim2.new(1, 0,1, -15)
		label.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd
		
		return dropdown
	end

	local function AddButton(title, buttonText, sizeX)
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,24)

		local listlayout = Instance.new("UIListLayout")
		listlayout.Parent = frame.Gui
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.Padding = UDim.new(0, 10)

		local button = Lib.Button.new()
		button.Gui.Parent = frame.Gui
		button.Size = UDim2.new(0,sizeX or 70,0,20)
		button.Text = buttonText or "Run"

		local label = Lib.Label.new()
		label.Gui.Parent = frame.Gui
		label.Gui.Size = UDim2.new(1, 0,1, -20)
		label.Gui.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd

		return button
	end
	
	local function AddSeperator(title)

		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,20)
		
		-- Label
		local label = Lib.Label.new()

		label.Parent = frame.Gui
		--label.AnchorPoint = Vector2.new(0,1)
		--label.Position = UDim2.new(0,0,0,0)
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
		frame.Gui.Size = UDim2.new(1,0,0,15)

		-- Label
		local label = Lib.Label.new()

		label.Parent = frame.Gui
		--label.AnchorPoint = Vector2.new(0,1)
		--label.Position = UDim2.new(0,0,0,0)
		label.Size = UDim2.new(1, 0,1, 0)
		label.TextColor3 = Color3.fromRGB(185,185,185)
		label.Text = text
		label.TextSize = 14
		label.TextTruncate = Enum.TextTruncate.AtEnd

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
			cancelButton.OnClick:Connect(function()
				win:Close()
			end)
			win:Add(cancelButton)

			reloadButton.Text = "Apply Now"
			reloadButton.AnchorPoint = Vector2.new(0,1)
			reloadButton.Position = UDim2.new(0,5,1,-5)
			reloadButton.Size = UDim2.new(0.5,-5,0,20)
			reloadButton.OnClick:Connect(function()
				if Main and Main.Reinit then
					Main.Reinit()
				elseif Main and Main.Exit and Main.Init then
					Main.Exit()
					task.wait()
					Main.Init()
				end
			end)

			win:Add(reloadButton,"reloadButton")

			SettingsWindow.ReloadPromptWindow = win
		end
		win:Show()
	end
	
	SettingsWindow.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Settings")
		window:Resize(Settings.Window.SettingsWidth or 250, Settings.Window.SettingsHeight or 375)
		SettingsWindow.Window = window

		window.GuiElems.Main:GetPropertyChangedSignal("Size"):Connect(function()
			if not window or window.Closed then
				return
			end

			local sizeX = math.floor(tonumber(window.SizeX) or window.GuiElems.Main.AbsoluteSize.X or Settings.Window.SettingsWidth or 250)
			local sizeY = math.floor(tonumber(window.SizeY) or window.GuiElems.Main.AbsoluteSize.Y or Settings.Window.SettingsHeight or 375)
			sizeX = math.clamp(sizeX, 220, 550)
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
		ListFrame.ScrollBarThickness = 16
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

		local function updateQuickTabState(selectedName)
			currentSectionName = selectedName
			for name, button in pairs(quickTabButtons) do
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

			local anchorGui = anchor.Gui or anchor
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
			button.MouseButton1Click:Connect(function()
				scrollToSection(sectionName)
			end)
			quickTabButtons[sectionName] = button
		end
		
		-- Options
		
		sectionAnchors.UI = AddSeperator("UI")
		AddText("Use the tabs above to jump between sections.")
		
		local titleonmiddle = AddCheckbox("Window Title On Middle", Settings.Window.TitleOnMiddle)
		titleonmiddle.OnInput:Connect(function()
			Settings.Window.TitleOnMiddle = titleonmiddle.Toggled
			persistSettings()
		end)
		
		local bgTransparency = AddTextbox("Background Transparency", tostring(Settings.Window.Transparency), 15)
		bgTransparency.FocusLost:Connect(function()
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
		
		local classIcon = AddDropdown("Class Icons", {"NewDark", "Vanilla3", "Old"}, Settings.ClassIcon, false, 100)
		classIcon.OnSelect:Connect(function()
			Settings.ClassIcon = classIcon.Selected
			persistSettings()
		end)
		AddText("Resize this window directly; the size is saved automatically.")

		Main.UserSettings = Main.UserSettings or {}
		local rememberLastTab = AddCheckbox("Remember Last Settings Tab", Main.UserSettings.RememberLastSettingsTab ~= false)
		rememberLastTab.OnInput:Connect(function()
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
		explorerStartupSide.OnSelect:Connect(function()
			Settings.Startup.ExplorerSide = explorerStartupSide.Selected
			persistSettings()
		end)

		local propertiesStartupSide = AddDropdown("Properties Window Side", {"Left", "Right"}, Settings.Startup.PropertiesSide or "Right", false, 90)
		propertiesStartupSide.OnSelect:Connect(function()
			Settings.Startup.PropertiesSide = propertiesStartupSide.Selected
			persistSettings()
		end)

		local openExplorerOnStartup = AddCheckbox("Open Explorer On Startup", Settings.Startup.OpenExplorer ~= false)
		openExplorerOnStartup.OnInput:Connect(function()
			Settings.Startup.OpenExplorer = openExplorerOnStartup.Toggled
			persistSettings()
		end)

		local openPropertiesOnStartup = AddCheckbox("Open Properties On Startup", Settings.Startup.OpenProperties ~= false)
		openPropertiesOnStartup.OnInput:Connect(function()
			Settings.Startup.OpenProperties = openPropertiesOnStartup.Toggled
			persistSettings()
		end)

		AddText("You can start with both, one, or neither window open.")
		
		sectionAnchors.Explorer = AddSeperator("Explorer")

		local sorting = AddCheckbox("Sorting", Settings.Explorer.Sorting)
		sorting.OnInput:Connect(function()
			Settings.Explorer.Sorting = sorting.Toggled
			if Explorer and Explorer.SetSortingEnabled then
				pcall(Explorer.SetSortingEnabled, sorting.Toggled)
			end
			persistSettings()
			applyExplorerRefresh()
		end)
		
		local clickRename = AddCheckbox("Click to Rename", Settings.Explorer.ClickToRename)
		clickRename.OnInput:Connect(function()
			Settings.Explorer.ClickToRename = clickRename.Toggled
			persistSettings()
		end)

		local autoUpdateSearch = AddCheckbox("Auto Update Search", Settings.Explorer.AutoUpdateSearch)
		autoUpdateSearch.OnInput:Connect(function()
			Settings.Explorer.AutoUpdateSearch = autoUpdateSearch.Toggled
			if Explorer and Explorer.SetAutoUpdateSearch then
				pcall(Explorer.SetAutoUpdateSearch, autoUpdateSearch.Toggled)
			end
			persistSettings()
		end)

		local autoUpdateModeLabels = {
			[0] = "Default",
			[1] = "Quiet Refresh",
			[2] = "Manual Tree",
			[3] = "Frozen",
		}
		local autoUpdateMode = AddDropdown("Auto Update Mode", {"Default", "Quiet Refresh", "Manual Tree", "Frozen"}, autoUpdateModeLabels[tonumber(Settings.Explorer.AutoUpdateMode) or 0] or "Default", false, 110)
		autoUpdateMode.OnSelect:Connect(function()
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
		partSelectionBox.OnInput:Connect(function()
			Settings.Explorer.PartSelectionBox = partSelectionBox.Toggled
			persistSettings()
			if Explorer and Explorer.UpdateSelectionVisuals then
				pcall(Explorer.UpdateSelectionVisuals)
			end
		end)

		local guiSelectionBox = AddCheckbox("GUI Selection Box", Settings.Explorer.GuiSelectionBox)
		guiSelectionBox.OnInput:Connect(function()
			Settings.Explorer.GuiSelectionBox = guiSelectionBox.Toggled
			persistSettings()
			if Explorer and Explorer.UpdateSelectionVisuals then
				pcall(Explorer.UpdateSelectionVisuals)
			end
		end)
		
		local copypathUseChildren = AddCheckbox("Use GetChildren to Copy Path", Settings.Explorer.CopyPathUseGetChildren)
		copypathUseChildren.OnInput:Connect(function()
			Settings.Explorer.CopyPathUseGetChildren = copypathUseChildren.Toggled
			persistSettings()
		end)

		local useNameWidth = AddCheckbox("Use Name Width", Settings.Explorer.UseNameWidth)
		useNameWidth.OnInput:Connect(function()
			Settings.Explorer.UseNameWidth = useNameWidth.Toggled
			persistSettings()
			applyExplorerRefresh(true)
		end)

		local maxSelectionBoxes = AddTextbox("Max Selection Boxes", tostring(Settings.Explorer.MaxSelectionBoxes), 70)
		maxSelectionBoxes.FocusLost:Connect(function()
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
		writeRemoteAttr.OnInput:Connect(function()
			Settings.RemoteBlockWriteAttribute = writeRemoteAttr.Toggled
			persistSettings()
		end)

		local function bindOffsetTextbox(label, axis)
			local curOffset = Settings.Explorer.TeleportToOffset
			local curValue = (axis == "X" and curOffset.X) or (axis == "Y" and curOffset.Y) or curOffset.Z
			local tb = AddTextbox(label, tostring(curValue), 70)
			tb.FocusLost:Connect(function()
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
		showDeprecated.OnInput:Connect(function()
			Settings.Properties.ShowDeprecated = showDeprecated.Toggled
			persistSettings()
			applyPropertiesRefresh(true)
		end)
		
		local showHidden = AddCheckbox("Show Hidden", Settings.Properties.ShowHidden)
		showHidden.OnInput:Connect(function()
			Settings.Properties.ShowHidden = showHidden.Toggled
			persistSettings()
			applyPropertiesRefresh(true)
		end)
		
		local showAttributes = AddCheckbox("Show Attributes", Settings.Properties.ShowAttributes)
		showAttributes.OnInput:Connect(function()
			Settings.Properties.ShowAttributes = showAttributes.Toggled
			persistSettings()
			applyPropertiesRefresh(true)
		end)

		local clearOnFocus = AddCheckbox("Clear On Focus", Settings.Properties.ClearOnFocus)
		clearOnFocus.OnInput:Connect(function()
			Settings.Properties.ClearOnFocus = clearOnFocus.Toggled
			persistSettings()
		end)

		local loadstringInput = AddCheckbox("Loadstring Input", Settings.Properties.LoadstringInput)
		loadstringInput.OnInput:Connect(function()
			Settings.Properties.LoadstringInput = loadstringInput.Toggled
			persistSettings()
		end)

		local maxConflictCheck = AddTextbox("Max Conflict Check", tostring(Settings.Properties.MaxConflictCheck), 70)
		maxConflictCheck.FocusLost:Connect(function()
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
		maxAttributes.FocusLost:Connect(function()
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
		numberRounding.FocusLost:Connect(function()
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
		scaleType.OnSelect:Connect(function()
			Settings.Properties.ScaleType = (scaleType.Selected == "Equal Halves") and 1 or 0
			persistSettings()
			applyPropertiesRefresh()
		end)
		
		sectionAnchors.Viewer = AddSeperator("Script Viewer")
		
		local showMoreInfo = AddCheckbox("Show Decompiled Script Info", Settings.ScriptViewer.ShowMoreInfo)
		showMoreInfo.OnInput:Connect(function()
			Settings.ScriptViewer.ShowMoreInfo = showMoreInfo.Toggled
			persistSettings()
			if ScriptViewer and ScriptViewer.RefreshCurrentView then
				pcall(ScriptViewer.RefreshCurrentView)
			end
		end)

		local defaultTextSize = (Main and Main.UserSettings and Main.UserSettings.ScriptViewerTextSize) or 16
		local scriptTextSize = AddTextbox("Editor Text Size", tostring(defaultTextSize), 60)
		scriptTextSize.FocusLost:Connect(function()
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
			checkbox.OnInput:Connect(function()
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
		consoleTextSize.FocusLost:Connect(function()
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
		consoleOutputLimit.FocusLost:Connect(function()
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
		consoleCtrlScroll.OnInput:Connect(function()
			Main.UserSettings.ConsoleCtrlScroll = consoleCtrlScroll.Toggled
			if Console and Console.SetCtrlScrollEnabled then
				pcall(Console.SetCtrlScrollEnabled, consoleCtrlScroll.Toggled)
			else
				persistUserSettings()
			end
		end)

		local consoleAutoScroll = AddCheckbox("Auto Scroll New Output", Main.UserSettings.ConsoleAutoScroll == true)
		consoleAutoScroll.OnInput:Connect(function()
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
		AddText("'getbytecode' is mandatory to use fallback decompilers.")
		local decompilerOption = {"Konstant", "AdvancedDecompiler", "Shiny"}
		local decompiler = AddDropdown("Decompiler Fallback", decompilerOption, Settings.Decompiler.DecompilerFallback, false, 125)
		decompiler.OnSelect:Connect(function()
			Settings.Decompiler.DecompilerFallback = decompiler.Selected
			persistSettings()
		end)
		
		local ShinyPort = AddTextbox("Shiny Decompiler Port", tostring(Settings.Decompiler.ShinyDecompilerPort), 50)
		ShinyPort.FocusLost:Connect(function()
			local portinput = tonumber(ShinyPort.Text)
			if not portinput then
				ShinyPort.Text = tostring(Settings.Decompiler.ShinyDecompilerPort)
			else
				if portinput > 0 and portinput <= 65535 then
					Settings.Decompiler.ShinyDecompilerPort = math.floor(portinput)
					ShinyPort.Text = tostring(Settings.Decompiler.ShinyDecompilerPort)
					persistSettings()
				else
					ShinyPort.Text = tostring(Settings.Decompiler.ShinyDecompilerPort)
				end
			end
		end)
		
		local preferFallback = AddCheckbox("Prefer Fallback Decompiler", Settings.Decompiler.PreferDecompilerFallback)
		preferFallback.OnInput:Connect(function()
			Settings.Decompiler.PreferDecompilerFallback = preferFallback.Toggled
			persistSettings()
		end)

		sectionAnchors.Themes = AddSeperator("Themes")
		AddText("Use Theme Manager for color-by-color customization.")

		local openThemeManagerButton = AddButton("Theme Manager", "Open", 70)
		openThemeManagerButton.OnClick:Connect(function()
			if ThemeManager and ThemeManager.Window then
				ThemeManager.Window:Show()
			else
				setWindowTitleSuffix("Theme Manager Missing", 2)
			end
		end)

		local saveThemeButton = AddButton("Save Current Theme", "Save", 70)
		saveThemeButton.OnClick:Connect(function()
			if Main and Main.SaveThemeSettings then
				pcall(Main.SaveThemeSettings)
				setWindowTitleSuffix("Theme Saved")
			end
		end)

		local reloadThemeButton = AddButton("Reload Theme File", "Load", 70)
		reloadThemeButton.OnClick:Connect(function()
			if Main and Main.LoadThemeSettings then
				pcall(Main.LoadThemeSettings)
				if Lib and Lib.RefreshTheme then
					pcall(Lib.RefreshTheme)
				end
				setWindowTitleSuffix("Theme Reloaded")
			end
		end)

		sectionAnchors.Files = AddSeperator("Files")
		AddText("The restart button below saves settings, then reloads Dex.")

		local saveSettingsButton = AddButton("Write Settings File", "Save", 70)
		saveSettingsButton.OnClick:Connect(function()
			if persistSettings() then
				setWindowTitleSuffix("Settings Saved")
			else
				setWindowTitleSuffix("Save Failed", 2)
			end
		end)

		local saveUserButton = AddButton("Write User Prefs", "Save", 70)
		saveUserButton.OnClick:Connect(function()
			persistUserSettings()
			setWindowTitleSuffix("User Prefs Saved")
		end)

		for _, sectionName in ipairs({"UI", "Startup", "Explorer", "Properties", "Viewer", "Console", "Decompiler", "Themes", "Files"}) do
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
		
		reloadButton.MouseButton1Click:Connect(function()
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
	end

	return SettingsWindow
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
