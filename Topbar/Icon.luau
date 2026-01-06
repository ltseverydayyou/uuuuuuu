local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Types = Import(script.Types)




export type Icon = Types.Icon






local iconModule = script
local Reference = Import(iconModule.Reference)
local referenceObject = Reference.getObject()
local leadPackage = referenceObject and referenceObject.Value
if leadPackage and leadPackage ~= iconModule then
	if typeof(leadPackage) == "Instance" then
		if leadPackage:IsA("ModuleScript") then
			local ok, mod = pcall(require, leadPackage)
			if ok and mod then
				return mod :: Types.StaticIcon
			end
		end
	elseif type(leadPackage) == "table" and rawget(leadPackage, "__path") then
		return Import(leadPackage) :: Types.StaticIcon
	elseif type(leadPackage) == "string" then
		return Import(leadPackage) :: Types.StaticIcon
	end
end
if not referenceObject then
	Reference.addToReplicatedStorage()
end




local Signal = Import(iconModule.Packages.GoodSignal)
local Janitor = Import(iconModule.Packages.Janitor)
local Utility = Import(iconModule.Utility)
local Themes = Import(iconModule.Features.Themes)
local Gamepad = Import(iconModule.Features.Gamepad)
local Overflow = Import(iconModule.Features.Overflow)
local Icon = {}
Icon.__index = Icon




local localPlayer = Players.LocalPlayer
local function isNode(value)
	return type(value) == "table" and rawget(value, "__path") ~= nil
end
local themes = iconModule.Features.Themes
local iconsDict = {}
local anyIconSelected = Signal.new()
local elements = iconModule.Elements
local totalCreatedIcons = 0
local preferredInput = {
	mobile = Enum.PreferredInput.Touch,
	desktop = Enum.PreferredInput.KeyboardAndMouse,
	console = Enum.PreferredInput.Gamepad
}




Icon.baseDisplayOrderChanged = Signal.new()
Icon.baseDisplayOrder = 10
Icon.baseTheme = Import(themes.Default)
Icon.isOldTopbar = false
Icon.iconsDictionary = iconsDict
Icon.insetHeightChanged = Signal.new()
Icon.container = Import(elements.Container)(Icon)
Icon.Features = iconModule.Features
Icon.Themes = themes
Icon.topbarEnabled = true
Icon.iconAdded = Signal.new()
Icon.iconRemoved = Signal.new()
Icon.iconChanged = Signal.new()




function Icon.getIcons()
	return Icon.iconsDictionary
end

function Icon.getIconByUID(UID)
	local match = Icon.iconsDictionary[UID]
	if match then
		return match
	end
	return nil
end

function Icon.getIcon(nameOrUID)
	local match = Icon.getIconByUID(nameOrUID)
	if match then
		return match
	end
	for _, icon in pairs(iconsDict) do
		if icon.name == nameOrUID then
			return icon
		end
	end
	return nil
end

function Icon.setTopbarEnabled(bool, isInternal)
	if typeof(bool) ~= "boolean" then
		bool = Icon.topbarEnabled
	end
	if not isInternal then
		Icon.topbarEnabled = bool
	end
	for _, screenGui in pairs(Icon.container) do
		screenGui.Enabled = bool
	end
end

function Icon.modifyBaseTheme(modifications)
	if isNode(modifications) then
		modifications = Import(modifications)
	end
	modifications = Themes.getModifications(modifications)
	for _, modification in pairs(modifications) do
		for _, detail in pairs(Icon.baseTheme) do
			Themes.merge(detail, modification)
		end
	end
	for _, icon in pairs(iconsDict) do
		icon:setTheme(Icon.baseTheme)
	end
end

function Icon.setDisplayOrder(int)
	Icon.baseDisplayOrder = int
	Icon.baseDisplayOrderChanged:Fire(int)
end




task.defer(Gamepad.start, Icon)
task.defer(Overflow.start, Icon)
task.defer(function()
	local function protectGui(g)
		if g:IsA("ScreenGui") then
			g.ZIndexBehavior = Enum.ZIndexBehavior.Global
			g.ResetOnSpawn = false
			g.IgnoreGuiInset = true
		end
		local coreGui = game:GetService("CoreGui")
		local lp = Players.LocalPlayer
		local function nap(obj, prop)
			if obj then
				if prop then
					obj[prop] = "\0"
				else
					obj.Name = "\0"
				end
				obj.Archivable = false
			end
		end
		if typeof(gethui) == "function" then
			nap(g)
			g.Parent = gethui()
			return g
		end
		if coreGui then
			nap(g)
			local robloxGui = coreGui:FindFirstChild("RobloxGui")
			if robloxGui then
				g.Parent = robloxGui
			else
				g.Parent = coreGui
			end
			return g
		end
		local playerGui = lp and lp:FindFirstChildWhichIsA("PlayerGui")
		if playerGui then
			nap(g)
			g.Parent = playerGui
			g.ResetOnSpawn = false
			return g
		end
		return nil
	end
	for _, screenGui in pairs(Icon.container) do
		protectGui(screenGui)
	end
end)




function Icon.new()
	local self = {}
	setmetatable(self, Icon)


	local janitor = Janitor.new()
	self.janitor = janitor
	self.themesJanitor = janitor:add(Janitor.new())
	self.singleClickJanitor = janitor:add(Janitor.new())
	self.captionJanitor = janitor:add(Janitor.new())
	self.joinJanitor = janitor:add(Janitor.new())
	self.menuJanitor = janitor:add(Janitor.new())
	self.dropdownJanitor = janitor:add(Janitor.new())


	local iconUID = Utility.generateUID()
	iconsDict[iconUID] = self
	janitor:add(function()
		iconsDict[iconUID] = nil
	end)


	self.selected = janitor:add(Signal.new())
	self.deselected = janitor:add(Signal.new())
	self.toggled = janitor:add(Signal.new())
	self.viewingStarted = janitor:add(Signal.new())
	self.viewingEnded = janitor:add(Signal.new())
	self.stateChanged = janitor:add(Signal.new())
	self.notified = janitor:add(Signal.new())
	self.noticeStarted = janitor:add(Signal.new())
	self.noticeChanged = janitor:add(Signal.new())
	self.endNotices = janitor:add(Signal.new())
	self.toggleKeyAdded = janitor:add(Signal.new())
	self.fakeToggleKeyChanged = janitor:add(Signal.new())
	self.alignmentChanged = janitor:add(Signal.new())
	self.updateSize = janitor:add(Signal.new())
	self.resizingComplete = janitor:add(Signal.new())
	self.joinedParent = janitor:add(Signal.new())
	self.menuSet = janitor:add(Signal.new())
	self.dropdownSet = janitor:add(Signal.new())
	self.updateMenu = janitor:add(Signal.new())
	self.startMenuUpdate = janitor:add(Signal.new())
	self.childThemeModified = janitor:add(Signal.new())
	self.indicatorSet = janitor:add(Signal.new())
	self.dropdownChildAdded = janitor:add(Signal.new())
	self.menuChildAdded = janitor:add(Signal.new())


	self.iconModule = iconModule
	self.UID = iconUID
	self.isEnabled = true
	self.enabled = self.isEnabled
	self.isSelected = false
	self.isViewing = false
	self.joinedFrame = false
	self.parentIconUID = false
	self.deselectWhenOtherIconSelected = true
	self.totalNotices = 0
	self.activeState = "Deselected"
	self.alignment = ""
	self.originalAlignment = ""
	self.appliedTheme = {}
	self.appearance = {}
	self.cachedInstances = {}
	self.cachedNamesToInstances = {}
	self.cachedCollectives = {}
	self.bindedToggleKeys = {}
	self.customBehaviours = {}
	self.toggleItems = {}
	self.bindedEvents = {}
	self.notices = {}
	self.menuIcons = {}
	self.dropdownIcons = {}
	self.childIconsDict = {}
	self.creationTime = os.clock()


	local widget = janitor:add(Import(elements.Widget)(self, Icon))
	self.widget = widget
	self:setAlignment()



	totalCreatedIcons += 1
	local ourOrder = 1+(totalCreatedIcons*0.01)
	self:setOrder(ourOrder, "deselected")
	self:setOrder(ourOrder, "selected")


	self:setTheme(Icon.baseTheme)


	local clickRegion = self:getInstance("ClickRegion")
	local hasUsedMouseButton1Click = false
	local lastToggleTime = 0
	local DEBOUNCE_TIME = 0.1

	local function handleToggle()
		if self.locked then
			return
		end


		local currentTime = tick()
		if currentTime - lastToggleTime < DEBOUNCE_TIME then
			return
		end
		lastToggleTime = currentTime

		if self.isSelected then
			self:deselect("User", self)
		else
			self:select("User", self)
		end
	end

	clickRegion.MouseButton1Click:Connect(function()
		hasUsedMouseButton1Click = true
		handleToggle()
	end)

	clickRegion.TouchTap:Connect(function()






		if not hasUsedMouseButton1Click then
			handleToggle()
		end
	end)


	janitor:add(UserInputService.InputBegan:Connect(function(input, touchingAnObject)
		if self.locked then
			return
		end
		if self.bindedToggleKeys[input.KeyCode] and not touchingAnObject then
			handleToggle()
		end
	end))




	local function viewingStarted(dontSetState)
		if self.locked then
			return
		end
		self.isViewing = true
		self.viewingStarted:Fire(true)
		if not dontSetState then
			self:setState("Viewing", "User", self)
		end
	end
	local function viewingEnded()
		if self.locked then
			return
		end
		self.isViewing = false
		self.viewingEnded:Fire(true)
		self:setState(nil, "User", self)
	end
	self.joinedParent:Connect(function()
		if self.isViewing then
			viewingEnded()
		end
	end)
	clickRegion.MouseEnter:Connect(function()
		local dontSetState = UserInputService.PreferredInput ~= preferredInput.desktop
		viewingStarted(dontSetState)
	end)
	local touchCount = 0
	janitor:add(UserInputService.TouchEnded:Connect(viewingEnded))
	clickRegion.MouseLeave:Connect(viewingEnded)
	clickRegion.SelectionGained:Connect(viewingStarted)
	clickRegion.SelectionLost:Connect(viewingEnded)
	clickRegion.MouseButton1Down:Connect(function()
		if not self.locked and UserInputService.PreferredInput == preferredInput.mobile then
			touchCount += 1
			local myTouchCount = touchCount
			task.delay(0.2, function()
				if myTouchCount == touchCount then
					viewingStarted()
				end
			end)
		end
	end)
	clickRegion.MouseButton1Up:Connect(function()
		touchCount += 1
	end)


	local iconOverlay = self:getInstance("IconOverlay")
	self.viewingStarted:Connect(function()
		iconOverlay.Visible = not self.overlayDisabled
	end)
	self.viewingEnded:Connect(function()
		iconOverlay.Visible = false
	end)


	janitor:add(anyIconSelected:Connect(function(incomingIcon)
		if incomingIcon ~= self and self.deselectWhenOtherIconSelected and incomingIcon.deselectWhenOtherIconSelected then
			self:deselect("AutoDeselect", incomingIcon)
		end
	end))






	local source =  debug.info(2, "s")
	local sourcePath = string.split(source, ".")
	local origin = game
	local originsScreenGui
	for i, sourceName in pairs(sourcePath) do
		origin = origin:FindFirstChild(sourceName)
		if not origin then
			break
		end
		if origin:IsA("ScreenGui") then
			originsScreenGui = origin
		end
	end
	if origin and originsScreenGui and originsScreenGui.ResetOnSpawn == true then
		self.originsScreenGui = originsScreenGui
		Utility.localPlayerRespawned(function()
			self:destroy()
		end)
	end


	self.toggled:Connect(function(isSelected)
		self.noticeChanged:Fire(self.totalNotices)
		for childIconUID, _ in pairs(self.childIconsDict) do
			local childIcon = Icon.getIconByUID(childIconUID)
			childIcon.noticeChanged:Fire(childIcon.totalNotices)
			if not isSelected and childIcon.isSelected then


				for _, _ in pairs(childIcon.childIconsDict) do
					childIcon:deselect("HideParentFeature", self)
				end
			end
		end
	end)









	self.selected:Connect(function()
		local isDropdown = #self.dropdownIcons > 0
		if isDropdown then
			if StarterGui:GetCore("ChatActive") and self.alignment ~= "Right" then
				self.chatWasPreviouslyActive = true
				StarterGui:SetCore("ChatActive", false)
			end
			if StarterGui:GetCoreGuiEnabled("PlayerList") and self.alignment ~= "Left" then
				self.playerlistWasPreviouslyActive = true
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			end
		end
	end)
	self.deselected:Connect(function()
		if self.chatWasPreviouslyActive then
			self.chatWasPreviouslyActive = nil
			StarterGui:SetCore("ChatActive", true)
		end
		if self.playerlistWasPreviouslyActive then
			self.playerlistWasPreviouslyActive = nil
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		end
	end)




	task.delay(0.1, function()
		if self.activeState == "Deselected" then
			self.stateChanged:Fire("Deselected")
			self:refresh()
		end
	end)


	Icon.iconAdded:Fire(self)

	return self
end




function Icon:setName(name)
	self.widget.Name = name
	self.name = name
	return self
end

function Icon:setState(incomingStateName, fromSource, sourceIcon)



	if not incomingStateName then
		incomingStateName = (self.isSelected and "Selected") or "Deselected"
	end
	local stateName = Utility.formatStateName(incomingStateName)
	local previousStateName = self.activeState
	if previousStateName == stateName then
		return
	end
	local currentIsSelected = self.isSelected
	self.activeState = stateName
	if stateName == "Deselected" then
		self.isSelected = false
		if currentIsSelected then
			self.toggled:Fire(false, fromSource, sourceIcon)
			self.deselected:Fire(fromSource, sourceIcon)
		end
		self:_setToggleItemsVisible(false, fromSource, sourceIcon)
	elseif stateName == "Selected" then
		self.isSelected = true
		if not currentIsSelected then
			self.toggled:Fire(true, fromSource, sourceIcon)
			self.selected:Fire(fromSource, sourceIcon)
			anyIconSelected:Fire(self, fromSource, sourceIcon)
		end
		self:_setToggleItemsVisible(true, fromSource, sourceIcon)
	end
	self.stateChanged:Fire(stateName, fromSource, sourceIcon)
end

function Icon:getInstance(name)



	local instance = self.cachedNamesToInstances[name]
	if instance then
		return instance
	end
	local function cacheInstance(childName, child)
		local currentCache = self.cachedInstances[child]
		if not currentCache then
			local collectiveName = child:GetAttribute("Collective")
			local cachedCollective = collectiveName and self.cachedCollectives[collectiveName]
			if cachedCollective then
				table.insert(cachedCollective, child)
			end
			self.cachedNamesToInstances[childName] = child
			self.cachedInstances[child] = true
			child.Destroying:Once(function()
				self.cachedNamesToInstances[childName] = nil
				self.cachedInstances[child] = nil
			end)
		end
	end
	local widget = self.widget
	cacheInstance("Widget", widget)
	if name == "Widget" then
		return widget
	end

	local returnChild
	local function scanChildren(parentInstance)
		for _, child in pairs(parentInstance:GetChildren()) do
			local widgetUID = child:GetAttribute("WidgetUID")
			if widgetUID and widgetUID ~= self.UID then


				continue
			end


			local realChild = Themes.getRealInstance(child)
			if realChild then
				child = realChild
			end

			scanChildren(child)
			if child:IsA("GuiBase") or child:IsA("UIBase") or child:IsA("ValueBase") then
				local childName = child.Name
				cacheInstance(childName, child)
				if childName == name then
					returnChild = child
				end
			end
		end
	end
	scanChildren(widget)
	return returnChild
end

function Icon:getCollective(name)






	local collective = self.cachedCollectives[name]
	if collective then
		return collective
	end
	collective = {}
	for instance, _ in pairs(self.cachedInstances) do
		if instance:GetAttribute("Collective") == name then
			table.insert(collective, instance)
		end
	end
	self.cachedCollectives[name] = collective
	return collective
end

function Icon:getInstanceOrCollective(collectiveOrInstanceName)


	local instances = {}
	local instance = self:getInstance(collectiveOrInstanceName)
	if instance then
		table.insert(instances, instance)
	end
	if #instances == 0 then
		instances = self:getCollective(collectiveOrInstanceName)
	end
	return instances
end

function Icon:getStateGroup(iconState)
	local chosenState = iconState or self.activeState
	local stateGroup = self.appearance[chosenState]
	if not stateGroup then
		stateGroup = {}
		self.appearance[chosenState] = stateGroup
	end
	return stateGroup
end

function Icon:refreshAppearance(instance, specificProperty)
	Themes.refresh(self, instance, specificProperty)
	return self
end

function Icon:refresh()
	self:refreshAppearance(self.widget)
	self.updateSize:Fire()
	return self
end

function Icon:updateParent()
	local parentIcon = Icon.getIconByUID(self.parentIconUID)
	if parentIcon then
		parentIcon.updateSize:Fire()
	end
end

function Icon:setBehaviour(collectiveOrInstanceName, property, callback, refreshAppearance)


	local key = collectiveOrInstanceName.."-"..property
	self.customBehaviours[key] = callback
	if refreshAppearance then
		local instances = self:getInstanceOrCollective(collectiveOrInstanceName)
		for _, instance in pairs(instances) do
			self:refreshAppearance(instance, property)
		end
	end
end

function Icon:modifyTheme(modifications, customModificationUID)
	local modificationUID = Themes.modify(self, modifications, customModificationUID)
	return self, modificationUID
end

function Icon:modifyChildTheme(modifications, modificationUID)


	self.childModifications = modifications
	self.childModificationsUID = modificationUID
	for childIconUID, _ in pairs(self.childIconsDict) do
		local childIcon = Icon.getIconByUID(childIconUID)
		childIcon:modifyTheme(modifications, modificationUID)
	end
	self.childThemeModified:Fire()
	return self
end

function Icon:removeModification(modificationUID)
	Themes.remove(self, modificationUID)
	return self
end

function Icon:removeModificationWith(instanceName, property, state)
	Themes.removeWith(self, instanceName, property, state)
	return self
end

function Icon:setTheme(theme)
	Themes.set(self, theme)
	return self
end

function Icon:setEnabled(bool)
	self.isEnabled = bool
	self.enabled = self.isEnabled
	self.widget.Visible = bool
	self:updateParent()
	return self
end

function Icon:select(fromSource, sourceIcon)
	self:setState("Selected", fromSource, sourceIcon)
	return self
end

function Icon:deselect(fromSource, sourceIcon)
	self:setState("Deselected", fromSource, sourceIcon)
	return self
end

function Icon:notify(customClearSignal, noticeId)




	local notice = self.notice
	if not notice then
		notice = Import(elements.Notice)(self, Icon)
		self.notice = notice
	end
	self.noticeStarted:Fire(customClearSignal, noticeId)
	return self
end

function Icon:clearNotices()
	self.endNotices:Fire()
	return self
end

function Icon:disableOverlay(bool)
	self.overlayDisabled = bool
	return self
end
Icon.disableStateOverlay = Icon.disableOverlay

function Icon:setImage(imageId, iconState)
	local useBuilderFont = iconState == true
	local state = useBuilderFont and nil or iconState

	if useBuilderFont then
		local builderFont = Font.new("rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json")
		self:modifyTheme({"IconImage", "Image", "", state})
		self:modifyTheme({"IconImage", "ImageTransparency", 1, state})
		self:modifyTheme({"IconLabel", "FontFace", builderFont, state})
		self:modifyTheme({"IconLabel", "TextScaled", true, state})
		self:modifyTheme({"IconLabel", "TextSize", 24, state})
		self:modifyTheme({"IconLabel", "Text", tostring(imageId or ""), state})
	else
		self:modifyTheme({"IconImage", "ImageTransparency", 0, state})
		self:modifyTheme({"IconLabel", "Text", "", state})
		self:modifyTheme({"IconImage", "Image", imageId, state})

		task.spawn(function()
			local newIdContent = if tonumber(imageId) then `rbxassetid://{imageId}` else imageId
			local initialAssetFetchStatus = ContentProvider:GetAssetFetchStatus(newIdContent)
			if initialAssetFetchStatus ~= Enum.AssetFetchStatus.Success then
				pcall(ContentProvider.PreloadAsync, ContentProvider, { newIdContent })
			end
		end)
	end

	return self
end

function Icon:setLabel(text, iconState)
	self:modifyTheme({"IconLabel", "Text", text, iconState})
	return self
end

function Icon:setOrder(int, iconState)


	local newInt = int*100
	self:modifyTheme({"IconSpot", "LayoutOrder", newInt, iconState})
	self:modifyTheme({"Widget", "LayoutOrder", newInt, iconState})
	return self
end

function Icon:setCornerRadius(udim, iconState)
	self:modifyTheme({"IconCorners", "CornerRadius", udim, iconState})
	return self
end

function Icon:align(leftCenterOrRight, isFromParentIcon)

	local direction = tostring(leftCenterOrRight):lower()
	if direction == "mid" or direction == "centre" then
		direction = "center"
	end
	if direction ~= "left" and direction ~= "center" and direction ~= "right" then
		direction = "left"
	end
	local screenGui = (direction == "center" and Icon.container.TopbarCentered) or Icon.container.TopbarStandard
	local holders = screenGui.Holders
	local finalDirection = string.upper(string.sub(direction, 1, 1))..string.sub(direction, 2)
	if not isFromParentIcon then
		self.originalAlignment = finalDirection
	end
	local joinedFrame = self.joinedFrame
	local alignmentHolder = holders[finalDirection]
	self.screenGui = screenGui
	self.alignmentHolder = alignmentHolder
	if not self.isDestroyed then
		self.widget.Parent = joinedFrame or alignmentHolder
	end
	self.alignment = finalDirection
	self.alignmentChanged:Fire(finalDirection)
	Icon.iconChanged:Fire(self)
	return self
end
Icon.setAlignment = Icon.align

function Icon:setLeft()
	self:setAlignment("Left")
	return self
end

function Icon:setMid()
	self:setAlignment("Center")
	return self
end

function Icon:setRight()
	self:setAlignment("Right")
	return self
end

function Icon:setWidth(offsetMinimum, iconState)



	self:modifyTheme({"Widget", "DesiredWidth", offsetMinimum, iconState})
	return self
end

function Icon:setImageScale(number, iconState)
	self:modifyTheme({"IconImageScale", "Value", number, iconState})
	return self
end

function Icon:setImageRatio(number, iconState)
	self:modifyTheme({"IconImageRatio", "AspectRatio", number, iconState})
	return self
end

function Icon:setTextSize(number, iconState)
	self:modifyTheme({"IconLabel", "TextSize", number, iconState})
	return self
end

function Icon:setTextFont(font, fontWeight, fontStyle, iconState)
	fontWeight = fontWeight or Enum.FontWeight.Regular
	fontStyle = fontStyle or Enum.FontStyle.Normal
	local fontFace
	local fontType = typeof(font)
	if fontType == "number" then
		fontFace = Font.fromId(font, fontWeight, fontStyle)
	elseif fontType == "EnumItem" then
		fontFace = Font.fromEnum(font)
	elseif fontType == "string" then
		if not font:match("rbxasset") then
			fontFace = Font.fromName(font, fontWeight, fontStyle)
		end
	end
	if not fontFace then
		fontFace = Font.new(font, fontWeight, fontStyle)
	end
	self:modifyTheme({"IconLabel", "FontFace", fontFace, iconState})
	return self
end

function Icon:setTextColor(Color, iconState)
	if Color == nil or Color == "" or (type(Color) ~= "userdata" or typeof(Color) ~= "Color3") then
		if Color ~= nil and Color ~= "" then
			warn("setTextColor item must be a Color3 value! Changed the color to white.")
		end
		Color = Color3.fromRGB(255, 255, 255)
	end

	self:modifyTheme({"IconLabel", "TextColor3", Color, iconState})
	return self
end

function Icon:bindToggleItem(guiObjectOrLayerCollector)
	if not guiObjectOrLayerCollector:IsA("GuiObject") and not guiObjectOrLayerCollector:IsA("LayerCollector") then
		error("Toggle item must be a GuiObject or LayerCollector!")
	end
	self.toggleItems[guiObjectOrLayerCollector] = true
	self:_updateSelectionInstances()
	return self
end

function Icon:unbindToggleItem(guiObjectOrLayerCollector)
	self.toggleItems[guiObjectOrLayerCollector] = nil
	self:_updateSelectionInstances()
	return self
end

function Icon:_updateSelectionInstances()


	for guiObjectOrLayerCollector, _ in pairs(self.toggleItems) do
		local buttonInstancesArray = {}
		for _, instance in pairs(guiObjectOrLayerCollector:GetDescendants()) do
			if (instance:IsA("TextButton") or instance:IsA("ImageButton")) and instance.Active then
				table.insert(buttonInstancesArray, instance)
			end
		end
		self.toggleItems[guiObjectOrLayerCollector] = buttonInstancesArray
	end
end

function Icon:_setToggleItemsVisible(bool, fromSource, sourceIcon)
	for toggleItem, _ in pairs(self.toggleItems) do
		if not sourceIcon or sourceIcon == self or sourceIcon.toggleItems[toggleItem] == nil then
			local property = "Visible"
			if toggleItem:IsA("LayerCollector") then
				property = "Enabled"
			end
			toggleItem[property] = bool
		end
	end
end

function Icon:bindEvent(iconEventName, eventFunction)
	local event = self[iconEventName]
	assert(event and typeof(event) == "table" and event.Connect, "argument[1] must be a valid topbarplus icon event name!")
	assert(typeof(eventFunction) == "function", "argument[2] must be a function!")
	self.bindedEvents[iconEventName] = event:Connect(function(...)
		eventFunction(self, ...)
	end)
	return self
end

function Icon:unbindEvent(iconEventName)
	local eventConnection = self.bindedEvents[iconEventName]
	if eventConnection then
		eventConnection:Disconnect()
		self.bindedEvents[iconEventName] = nil
	end
	return self
end

function Icon:bindToggleKey(keyCodeEnum)
	assert(typeof(keyCodeEnum) == "EnumItem", "argument[1] must be a KeyCode EnumItem!")
	self.bindedToggleKeys[keyCodeEnum] = true
	self.toggleKeyAdded:Fire(keyCodeEnum)
	self:setCaption("_hotkey_")
	return self
end

function Icon:unbindToggleKey(keyCodeEnum)
	assert(typeof(keyCodeEnum) == "EnumItem", "argument[1] must be a KeyCode EnumItem!")
	self.bindedToggleKeys[keyCodeEnum] = nil
	return self
end

function Icon:call(callback, ...)
	local packedArgs = table.pack(...)
	task.spawn(function()
		callback(self, table.unpack(packedArgs))
	end)
	return self
end

function Icon:addToJanitor(callback, methodName, index)
	self.janitor:add(callback, methodName, index)
	return self
end

function Icon:lock()

	local clickRegion = self:getInstance("ClickRegion")
	clickRegion.Visible = false
	self.locked = true
	return self
end

function Icon:unlock()
	local clickRegion = self:getInstance("ClickRegion")
	clickRegion.Visible = true
	self.locked = false
	return self
end

function Icon:debounce(seconds)
	self:lock()
	task.wait(seconds)
	self:unlock()
	return self
end

function Icon:autoDeselect(bool)


	if bool == nil then
		bool = true
	end
	self.deselectWhenOtherIconSelected = bool
	return self
end

function Icon:oneClick(callbackOrBool)
	local enable = callbackOrBool
	local callback = nil
	if type(callbackOrBool) == "function" then
		enable = true
		callback = callbackOrBool
	elseif callbackOrBool == nil then
		enable = true
	end
	local singleClickJanitor = self.singleClickJanitor
	if not singleClickJanitor or not (singleClickJanitor.clean or singleClickJanitor.Clean or singleClickJanitor.Cleanup) then
		local Janitor = Import(self.iconModule.Packages.Janitor)
		singleClickJanitor = Janitor.new()
		self.singleClickJanitor = singleClickJanitor
	end
	local cleaner = singleClickJanitor.clean or singleClickJanitor.Clean or singleClickJanitor.Cleanup
	if cleaner then
		cleaner(singleClickJanitor)
	end
	if enable then
		local addFn = singleClickJanitor.add or singleClickJanitor.Add
		local connFn = function()
			if callback then
				callback(self)
			end
			self:deselect("OneClick", self)
		end
		if addFn then
			addFn(singleClickJanitor, self.selected:Connect(connFn))
		else
			self.selected:Connect(connFn)
		end
	end
	self.oneClickEnabled = true
	return self
end

function Icon:setCaption(text)
	if text == "_hotkey_" and (self.captionText) then
		return self
	end
	local captionJanitor = self.captionJanitor
	if not captionJanitor or not (captionJanitor.clean or captionJanitor.Clean or captionJanitor.Cleanup) then
		local Janitor = Import(self.iconModule.Packages.Janitor)
		captionJanitor = Janitor.new()
		self.captionJanitor = captionJanitor
	end
	local cleaner = captionJanitor.clean or captionJanitor.Clean or captionJanitor.Cleanup
	if cleaner then
		cleaner(captionJanitor)
	end
	if not text or text == "" then
		self.caption = nil
		self.captionText = nil
		return self
	end
	local caption = captionJanitor:add(Import(elements.Caption)(self))
	caption:SetAttribute("CaptionText", text)
	self.caption = caption
	self.captionText = text
	return self
end

function Icon:setCaptionHint(keyCodeOrText)
	if typeof(keyCodeOrText) == "EnumItem" then
		self.fakeToggleKey = keyCodeOrText
		self.fakeToggleKeyChanged:Fire(keyCodeOrText)
		self:setCaption("_hotkey_")
	elseif type(keyCodeOrText) == "string" then
		self.fakeToggleKey = nil
		self.fakeToggleKeyChanged:Fire(nil)
		self:setCaption(keyCodeOrText)
	elseif keyCodeOrText == nil then
		self.fakeToggleKey = nil
		self.fakeToggleKeyChanged:Fire(nil)
	end
	return self
end

function Icon:leave()
	local joinJanitor = self.joinJanitor
	joinJanitor:clean()
	return self
end

function Icon:joinMenu(parentIcon)
	Utility.joinFeature(self, parentIcon, parentIcon.menuIcons, parentIcon:getInstance("Menu"))
	parentIcon.menuChildAdded:Fire(self)
	return self
end

function Icon:addMenu()
	local parentIcon = self
	parentIcon:getInstance("Menu")
	local builder = {}
	function builder:new()
		local child = Icon.new()
		child:joinMenu(parentIcon)
		return child
	end
	return builder
end

function Icon:setMenu(arrayOfIcons)
	self.menuSet:Fire(arrayOfIcons)
	return self
end

function Icon:setFixedMenu(arrayOfIcons)
	self:freezeMenu(arrayOfIcons)
	self:setMenu(arrayOfIcons)
end
Icon.setFrozenMenu = Icon.setFixedMenu

function Icon:freezeMenu()


	self:select("FrozenMenu", self)
	self:bindEvent("deselected", function(icon)
		icon:select("FrozenMenu", self)
	end)
	self:modifyTheme({"IconSpot", "Visible", false})
end

function Icon:joinDropdown(parentIcon)
	parentIcon:getDropdown()
	Utility.joinFeature(self, parentIcon, parentIcon.dropdownIcons, parentIcon:getInstance("DropdownScroller"))
	self:removeModification("JoinModification")
	local cr = self:getInstance("ClickRegion")
	if cr then
		cr.Active = true
		cr.Selectable = true
	end
	parentIcon.dropdownChildAdded:Fire(self)
	return self
end

function Icon:addDropdown()
	local parentIcon = self
	parentIcon:getDropdown()
	local builder = {}
	function builder:new()
		local child = Icon.new()
		child:joinDropdown(parentIcon)
		return child
	end
	return builder
end

function Icon:getDropdown()
	local dropdown = self.dropdown
	if not dropdown then
		dropdown = Import(elements.Dropdown)(self)
		self.dropdown = dropdown
		if self.widget then
			self.widget.ClipsDescendants = false
		end
		local iconButton = self:getInstance("IconButton")
		if iconButton then
			iconButton.ClipsDescendants = false
		end
	end
	return dropdown
end

function Icon:setDropdown(arrayOfIcons)
	self:getDropdown()
	self.dropdownSet:Fire(arrayOfIcons)
	return self
end

function Icon:clipOutside(instance)





	local instanceClone = Utility.clipOutside(self, instance)
	self:refreshAppearance(instance)
	return self, instanceClone
end

function Icon:setIndicator(keyCode)



	local indicator = self.indicator
	if not indicator then
		indicator = self.janitor:add(Import(elements.Indicator)(self, Icon))
		self.indicator = indicator
	end
	self.indicatorSet:Fire(keyCode)
end

function Icon:convertLabelToNumberSpinner(numberSpinner, callback)
	task.defer(function()

		local label = self:getInstance("IconLabel")
		label.Transparency = 1
		numberSpinner.Parent = label.Parent
		numberSpinner.Size = UDim2.fromScale(1, 1)
		numberSpinner.AnchorPoint = Vector2.new(0.5, 0.5)
		numberSpinner.Position = UDim2.new(0.5, 0, 0.5, 0)
		numberSpinner.TextXAlignment = Enum.TextXAlignment.Center
		numberSpinner.ClipsDescendants = false

		local propertiesToChangeLabel = {
			"FontFace",
			"BorderSizePixel",
			"BorderColor3",
			"Rotation",
			"TextStrokeTransparency",
			"TextStrokeColor3",
			"TextStrokeTransparency",
			"TextColor3",
		}
		for _, property in ipairs(propertiesToChangeLabel) do
			numberSpinner[property] = label[property]
			self:addToJanitor(label:GetPropertyChangedSignal(property):Connect(function()
				numberSpinner[property] = label[property]
			end))
		end

		local minDigits = 0
		local maxDigits = 8
		local function getSpinnerSizeAndDigitCount()
			local TotalSize = 0
			local numOfDigits = 0
			for i, child in numberSpinner.Frame:GetChildren() do
				local name = string.lower(child.Name)
				if name == "digit" then
					TotalSize += child.AbsoluteSize.X
					numOfDigits += 1
				elseif name == "prefix" or name == "suffix" or name == "comma" then
					if child.Text ~= "" then
						TotalSize += child.AbsoluteSize.X
						numOfDigits += 1
					end
				end
			end
			return TotalSize, numOfDigits
		end

		local function getLabelParentContainerXSize()
			local firstParent = label.Parent
			local nextParent = firstParent and firstParent.Parent
			if nextParent == nil then
				return 0
			end
			if nextParent.IconImage.Visible == true then
				return numberSpinner.Frame.AbsoluteSize.X + label.Parent.Parent.IconImage.AbsoluteSize.X
			else
				return nextParent.AbsoluteSize.X
			end
		end
		local function getNumberSpinnerXSize()
			return numberSpinner.Frame.AbsoluteSize.X
		end

		local function adjustSize()
			local totalDigitXSize, numOfDigits = getSpinnerSizeAndDigitCount()
			if numOfDigits < 18 then
				self:setLabel(numberSpinner.Value)
			end

			local NumberSpinnerXSize = getNumberSpinnerXSize()

			while totalDigitXSize < NumberSpinnerXSize and self.isDestroyed ~= true do
				task.wait(0.05)
				if numOfDigits > minDigits and numOfDigits < maxDigits then
					numberSpinner.TextSize = label.TextSize
					break
				else
					numberSpinner.TextSize += 1
				end

				NumberSpinnerXSize = getNumberSpinnerXSize()
				totalDigitXSize, numOfDigits = getSpinnerSizeAndDigitCount()
			end

			local labelParentContainerXSize = getLabelParentContainerXSize()
			while totalDigitXSize > labelParentContainerXSize and self.isDestroyed ~= true do
				task.wait(0.05)
				if numOfDigits < maxDigits and numOfDigits > minDigits then
					numberSpinner.TextSize = label.TextSize
					break
				else
					numberSpinner.TextSize -= 1
				end

				labelParentContainerXSize = getLabelParentContainerXSize()
				totalDigitXSize, numOfDigits = getSpinnerSizeAndDigitCount()
			end
		end

		self:addToJanitor(numberSpinner.Frame.ChildAdded:Connect(adjustSize))
		self:addToJanitor(numberSpinner.Frame.ChildRemoved:Connect(adjustSize))
		self:addToJanitor(self.iconAdded:Connect(function()
			task.wait(1)
			adjustSize()
		end))

		self:updateParent()


		numberSpinner.Name = "LabelSpinner"
		numberSpinner.Prefix = "$"
		numberSpinner.Commas = true
		numberSpinner.Decimals = 0
		numberSpinner.Duration = 0.25
		numberSpinner.Value = 10
		task.wait(0.2)

		if typeof(callback) == "function" then
			callback()
		end

	end)
	return self
end




function Icon:destroy()
	if self.isDestroyed then
		return
	end
	self:clearNotices()
	if self.parentIconUID then
		self:leave()
	end
	self.isDestroyed = true
	self.janitor:clean()
	Icon.iconRemoved:Fire(self)
end
Icon.Destroy = Icon.destroy

return Icon :: Types.StaticIcon
