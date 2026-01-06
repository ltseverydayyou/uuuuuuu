local Utility = {}
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer




function Utility.createStagger(delayTime, callback, delayInitially)








	local staggerActive = false
	local multipleCalls = false
	if not delayTime or delayTime == 0 then


		delayTime = 0.01
	end
	local function staggeredCallback(...)
		if staggerActive then
			multipleCalls = true
			return
		end
		local packedArgs = table.pack(...)
		staggerActive = true
		multipleCalls = false
		task.spawn(function()
			if delayInitially then
				task.wait(delayTime)
			end
			callback(table.unpack(packedArgs))
		end)
		task.delay(delayTime, function()
			staggerActive = false
			if multipleCalls then


				staggeredCallback(table.unpack(packedArgs))
			end
		end)
	end
	return staggeredCallback
end

function Utility.round(n)

	return math.floor(n + 0.5)
end

function Utility.reverseTable(t)
	for i = 1, math.floor(#t/2) do
		local j = #t - i + 1
		t[i], t[j] = t[j], t[i]
	end
end

function Utility.copyTable(t)

	assert(type(t) == "table", "First argument must be a table")
	local tCopy = table.create(#t)
	for k,v in pairs(t) do
		if (type(v) == "table") then
			tCopy[k] = Utility.copyTable(v)
		else
			tCopy[k] = v
		end
	end
	return tCopy
end

local validCharacters = {"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","1","2","3","4","5","6","7","8","9","0","<",">","?","@","{","}","[","]","!","(",")","=","+","~","#"}
function Utility.generateUID(length)
	length = length or 8
	local UID = ""
	local list = validCharacters
	local total = #list
	for i = 1, length do
		local randomCharacter = list[math.random(1, total)]
		UID = UID..randomCharacter
	end
	return UID
end

local instanceTrackers = {}
function Utility.setVisible(instance, bool, sourceUID)




	local tracker = instanceTrackers[instance]
	if not tracker then
		tracker = {}
		instanceTrackers[instance] = tracker
		instance.Destroying:Once(function()
			instanceTrackers[instance] = nil
		end)
	end
	if not bool then
		tracker[sourceUID] = true
	else
		tracker[sourceUID] = nil
	end
	local isVisible = bool
	if bool then
		for sourceUID, _ in pairs(tracker) do
			isVisible = false
			break
		end
	end
	instance.Visible = isVisible
end

function Utility.formatStateName(incomingStateName)
	return string.upper(string.sub(incomingStateName, 1, 1))..string.lower(string.sub(incomingStateName, 2))
end

function Utility.localPlayerRespawned(callback)






	localPlayer.CharacterRemoving:Connect(callback)
end

function Utility.getClippedContainer(screenGui)
	if not screenGui then
		return nil
	end
	local clippedContainer = screenGui:FindFirstChild("ClippedContainer")
	if not clippedContainer then
		clippedContainer = Instance.new("Folder")
		clippedContainer.Name = "ClippedContainer"
		clippedContainer.Parent = screenGui
	end
	return clippedContainer
end

local Janitor = Import(script.Parent.Packages.Janitor)
local GuiService = game:GetService("GuiService")
function Utility.clipOutside(icon, instance)
	local cloneJanitor = icon.janitor:add(Janitor.new())
	instance.Destroying:Once(function()
		cloneJanitor:Destroy()
	end)
	icon.janitor:add(instance)

	local originalParent = instance.Parent
	local clone = cloneJanitor:add(Instance.new("Frame"))
	clone:SetAttribute("IsAClippedClone", true)
	clone.Name = instance.Name
	clone.AnchorPoint = instance.AnchorPoint
	clone.Size = instance.Size
	clone.Position = instance.Position
	clone.BackgroundTransparency = 1
	clone.LayoutOrder = instance.LayoutOrder
	clone.Parent = originalParent

	local valueInstance = Instance.new("ObjectValue")
	valueInstance.Name = "OriginalInstance"
	valueInstance.Value = instance
	valueInstance.Parent = clone

	local valueInstanceCopy = valueInstance:Clone()
	instance:SetAttribute("HasAClippedClone", true)
	valueInstanceCopy.Name = "ClippedClone"
	valueInstanceCopy.Value = clone
	valueInstanceCopy.Parent = instance

	local screenGui
	local Icon = Import(icon.iconModule)
	local container = Icon.container
	local function updateScreenGui()
		local originalScreenGui = originalParent:FindFirstAncestorWhichIsA("ScreenGui")
		if not originalScreenGui then
			return
		end
		screenGui = if string.match(originalScreenGui.Name, "Clipped") then originalScreenGui else container[originalScreenGui.Name.."Clipped"]
		if not screenGui then
			return
		end
		instance.AnchorPoint = Vector2.new(0, 0)
		local clippedContainer = Utility.getClippedContainer(screenGui)
		if clippedContainer then
			instance.Parent = clippedContainer
		end
	end
	cloneJanitor:add(icon.alignmentChanged:Connect(updateScreenGui))
	updateScreenGui()


	for _, child in pairs(instance:GetChildren()) do
		if child:IsA("UIAspectRatioConstraint") then
			child:Clone().Parent = clone
		end
	end




	local widget = icon.widget
	local isOutsideParent = false
	local ignoreVisibilityUpdater = instance:GetAttribute("IgnoreVisibilityUpdater")
	local function updateVisibility()
		if ignoreVisibilityUpdater then
			return
		end
		local isVisible = widget.Visible
		if isOutsideParent then
			isVisible = false
		end
		Utility.setVisible(instance, isVisible, "ClipHandler")
	end
	cloneJanitor:add(widget:GetPropertyChangedSignal("Visible"):Connect(updateVisibility))

	local previousScroller
	local function checkIfOutsideParentXBounds()

		task.defer(function()


			local parentInstance
			local ourUID = icon.UID
			local nextIconUID = ourUID
			local shouldClipToParent = instance:GetAttribute("ClipToJoinedParent")
			if shouldClipToParent then
				for i = 1, 10 do
					local nextIcon = Icon.getIconByUID(nextIconUID)
					if not nextIcon then
						break
					end
					local nextParentInstance = nextIcon.joinedFrame
					nextIconUID = nextIcon.parentIconUID
					if not nextParentInstance then
						break
					end
					parentInstance = nextParentInstance
					if parentInstance and parentInstance.Name == "DropdownScroller" then
						break
					end
				end
			end
			if not parentInstance then
				isOutsideParent = false
				updateVisibility()
				return
			end
			local pos = instance.AbsolutePosition
			local halfSize = instance.AbsoluteSize/2
			local parentPos = parentInstance.AbsolutePosition
			local parentSize = parentInstance.AbsoluteSize
			local posHalf = (pos + halfSize)
			local exceededLeft = posHalf.X < parentPos.X
			local exceededRight = posHalf.X > (parentPos.X + parentSize.X)
			local exceededTop = posHalf.Y < parentPos.Y
			local exceededBottom = posHalf.Y > (parentPos.Y + parentSize.Y)
			local hasExceeded = exceededLeft or exceededRight or exceededTop or exceededBottom
			if hasExceeded ~= isOutsideParent then
				isOutsideParent = hasExceeded
				updateVisibility()
			end
			if parentInstance:IsA("ScrollingFrame") and previousScroller ~= parentInstance then
				previousScroller = parentInstance
				local connection = parentInstance:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
					checkIfOutsideParentXBounds()
				end)
				cloneJanitor:add(connection, "Disconnect", "TrackUtilityScroller-"..ourUID)
			end
		end)
	end

	local camera = workspace.CurrentCamera
	local additionalOffsetX = instance:GetAttribute("AdditionalOffsetX") or 0
	local function trackProperty(property)
		local absoluteProperty = "Absolute"..property
		local function updateProperty()
			if not clone or not instance then
				return
			end
			if not instance:IsA("GuiObject") or not clone:IsA("GuiObject") then
				return
			end
			local cloneValue = clone[absoluteProperty]
			if not cloneValue then
				return
			end
			local absoluteValue = UDim2.fromOffset(cloneValue.X, cloneValue.Y)
			if property == "Position" then


				local SIDE_PADDING = 4
				local limitX = camera.ViewportSize.X - instance.AbsoluteSize.X - SIDE_PADDING
				local inputX = absoluteValue.X.Offset
				if inputX < SIDE_PADDING then
					inputX = SIDE_PADDING
				elseif inputX > limitX then
					inputX = limitX
				end
				absoluteValue = UDim2.fromOffset(inputX, absoluteValue.Y.Offset)



				local topbarInset = GuiService.TopbarInset
				local viewportWidth = workspace.CurrentCamera.ViewportSize.X
				local guiWidth = screenGui.AbsoluteSize.X
				local guiOffset = screenGui.AbsolutePosition.X

				local oldTopbarCenterOffset = 0
				local offsetX = if Icon.isOldTopbar then guiOffset else viewportWidth - guiWidth - oldTopbarCenterOffset


				offsetX -= additionalOffsetX
				absoluteValue += UDim2.fromOffset(-offsetX, topbarInset.Height)


				checkIfOutsideParentXBounds()

			end
			instance[property] = absoluteValue
		end


		local updatePropertyStaggered = Utility.createStagger(0.01, updateProperty)
		cloneJanitor:add(clone:GetPropertyChangedSignal(absoluteProperty):Connect(updatePropertyStaggered))
		cloneJanitor:add(clone:GetAttributeChangedSignal("ForceUpdate"):Connect(function()
			updatePropertyStaggered()
		end))









		local updatePropertyPatch = Utility.createStagger(0.5, updateProperty, true)
		if clone and clone.GetPropertyChangedSignal then
			cloneJanitor:add(clone:GetPropertyChangedSignal(absoluteProperty):Connect(updatePropertyPatch))
		end




		if property == "Position" then
			if screenGui and screenGui.GetPropertyChangedSignal then
				cloneJanitor:add(screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					updatePropertyStaggered()
				end))
			end
		end

	end
	task.delay(0.1, checkIfOutsideParentXBounds)
	checkIfOutsideParentXBounds()
	updateVisibility()
	trackProperty("Position")


	if instance and instance.GetPropertyChangedSignal then
		cloneJanitor:add(instance:GetPropertyChangedSignal("Visible"):Connect(function()
		end))
	end


	local shouldTrackCloneSize = instance:GetAttribute("TrackCloneSize")
	if shouldTrackCloneSize then
		trackProperty("Size")
	else
		if instance and instance.GetPropertyChangedSignal then
			cloneJanitor:add(instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				if not instance or not clone or not instance:IsA("GuiObject") then
					return
				end
				local absolute = instance.AbsoluteSize
				if absolute then
					clone.Size = UDim2.fromOffset(absolute.X, absolute.Y)
				end
			end))
		end
	end

	return clone
end

function Utility.joinFeature(originalIcon, parentIcon, iconsArray, scrollingFrameOrFrame)

	local joinJanitor = originalIcon.joinJanitor
	if not joinJanitor or not (joinJanitor.clean or joinJanitor.Clean or joinJanitor.Cleanup) then
		local Janitor = Import(script.Parent.Packages.Janitor)
		joinJanitor = Janitor.new()
		originalIcon.joinJanitor = joinJanitor
	end
	local cleanFn = joinJanitor.clean or joinJanitor.Clean or joinJanitor.Cleanup
	if cleanFn then
		cleanFn(joinJanitor)
	end
	if not scrollingFrameOrFrame then
		originalIcon:leave()
		return
	end
	originalIcon.parentIconUID = parentIcon.UID
	originalIcon.joinedFrame = scrollingFrameOrFrame
	local function updateAlignent()
		local parentAlignment = parentIcon.alignment
		if parentAlignment == "Center" then
			parentAlignment = "Left"
		end
		originalIcon:setAlignment(parentAlignment, true)
	end
	joinJanitor:add(parentIcon.alignmentChanged:Connect(updateAlignent))
	updateAlignent()
	originalIcon:modifyTheme({"IconButton", "BackgroundTransparency", 1}, "JoinModification")
	originalIcon:modifyTheme({"ClickRegion", "Active", false}, "JoinModification")
	if parentIcon.childModifications then



		task.defer(function()
			originalIcon:modifyTheme(parentIcon.childModifications, parentIcon.childModificationsUID)
		end)
	end

	local clickRegion = originalIcon:getInstance("ClickRegion")
	local function makeSelectable()
		clickRegion.Selectable = parentIcon.isSelected
	end
	joinJanitor:add(parentIcon.toggled:Connect(makeSelectable))
	task.defer(makeSelectable)
	joinJanitor:add(function()
		clickRegion.Selectable = true
	end)




	local originalIconUID = originalIcon.UID
	table.insert(iconsArray, originalIconUID)
	parentIcon:autoDeselect(false)
	parentIcon.childIconsDict[originalIconUID] = true
	if not parentIcon.isEnabled then
		parentIcon:setEnabled(true)
	end
	originalIcon.joinedParent:Fire(parentIcon)



	joinJanitor:add(function()
		local joinedFrame = originalIcon.joinedFrame
		if not joinedFrame then
			return
		end
		for i, iconUID in pairs(iconsArray) do
			if iconUID == originalIconUID then
				table.remove(iconsArray, i)
				break
			end
		end
		local Icon = Import(originalIcon.iconModule)
		local parentIcon = Icon.getIconByUID(originalIcon.parentIconUID)
		if not parentIcon then
			return
		end
		originalIcon:setAlignment(originalIcon.originalAlignment)
		originalIcon.parentIconUID = false
		originalIcon.joinedFrame = false

		originalIcon:removeModification("JoinModification")

		local parentHasNoChildren = true
		local parentChildIcons = parentIcon.childIconsDict
		parentChildIcons[originalIconUID] = nil
		for childIconUID, _ in pairs(parentChildIcons) do
			parentHasNoChildren = false
			break
		end
		if parentHasNoChildren and not parentIcon.isAnOverflow then
			parentIcon:setEnabled(false)
		end
		updateAlignent()

	end)

end



return Utility
