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
	local resolver =
		loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau")
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

local hasBecomeOldTheme = false
local previousInsetHeight = 0
return function(Icon)
	local CoreGui = __lt.gs("CoreGui")
	local GuiService = __lt.gs("GuiService")
	local Players = __lt.gs("Players")
	local UserInputService = __lt.gs("UserInputService")
	local container = {}
	local Signal = Import(script.Parent.Parent.Packages.GoodSignal)
	local insetChanged = Signal.new()
	local guiInset = GuiService:GetGuiInset()
	local startInset = 0
	local iconPadding = 0
	local yDownOffset = 0
	local ySizeOffset = 0
	local checkCount = 0
	local isConsoleScreen = false
	local isUsingVR = false
	local function getCoreGuiLeftInset()
		local robloxGui = CoreGui:FindFirstChild("RobloxGui")
		if not robloxGui then
			return 0
		end
		local topbarHeight = math.max(GuiService.TopbarInset.Height, guiInset.Y, 50)
		local maxRight = 0
		for _, instance in ipairs(robloxGui:GetDescendants()) do
			if instance:IsA("GuiObject") and instance.Visible then
				local screenGui = instance:FindFirstAncestorOfClass("ScreenGui")
				local screenGuiName = screenGui and screenGui.Name
				local isTopbarContainer = screenGuiName == "TopbarStandard"
					or screenGuiName == "TopbarCentered"
					or screenGuiName == "TopbarStandardClipped"
					or screenGuiName == "TopbarCenteredClipped"
				if not isTopbarContainer then
					local position = instance.AbsolutePosition
					local size = instance.AbsoluteSize
					local rightEdge = position.X + size.X
					local isLeftTopbarObject = position.Y < topbarHeight
						and position.X >= 0
						and position.X < 260
						and size.X > 0
						and size.Y > 0
						and size.X <= 260
						and size.Y <= topbarHeight + 8
					if isLeftTopbarObject then
						maxRight = math.max(maxRight, rightEdge)
					end
				end
			end
		end
		return if maxRight > 0 then maxRight + 8 else 0
	end
	local function checkInset(status)
		local currentHeight = GuiService.TopbarInset.Height
		local isOldTopbar = currentHeight <= 36

		isConsoleScreen = GuiService:IsTenFootInterface()
		isUsingVR = UserInputService.VREnabled
		Icon.isOldTopbar = isOldTopbar
		checkCount += 1
		if currentHeight == 0 and status == nil then
			task.defer(function()
				task.wait(8)
				checkInset("ForceConvertToOld")
			end)
		elseif checkCount == 1 then
			task.delay(5, function()
				local localPlayer = Players.LocalPlayer
				localPlayer:WaitForChild("PlayerGui")
				if checkCount == 1 then
					checkInset()
				end
			end)
		end

		if
			Icon.isOldTopbar
			and not isConsoleScreen
			and not isUsingVR
			and hasBecomeOldTheme == false
			and (currentHeight ~= 0 or status == "ForceConvertToOld")
		then
			hasBecomeOldTheme = true
			task.defer(function()
				local themes = script.Parent.Parent.Features.Themes
				local Classic = Import(themes.Classic)
				Icon.modifyBaseTheme(Classic)

				local function decideToHideTopbar()
					if GuiService.MenuIsOpen then
						Icon.setTopbarEnabled(false, true)
					else
						Icon.setTopbarEnabled()
					end
				end
				GuiService:GetPropertyChangedSignal("MenuIsOpen"):Connect(decideToHideTopbar)
				decideToHideTopbar()
			end)
		end

		guiInset = GuiService:GetGuiInset()
		iconPadding = if isOldTopbar then 12 else math.max(guiInset.Y - 50, 8)
		startInset = if isOldTopbar then 12 else math.max(guiInset.X, guiInset.Y, iconPadding, getCoreGuiLeftInset())
		yDownOffset = if isOldTopbar then 2 else 0
		ySizeOffset = -2
		if isConsoleScreen then
			startInset = 10
			iconPadding = 10
			yDownOffset = 0
		end
		if GuiService.TopbarInset.Height == 0 and not hasBecomeOldTheme then
			yDownOffset += 13
			ySizeOffset = 50
		end

		insetChanged:Fire(guiInset)
		local insetHeight = guiInset.Y
		if insetHeight ~= previousInsetHeight then
			previousInsetHeight = insetHeight
			task.defer(function()
				Icon.insetHeightChanged:Fire(insetHeight)
			end)
		end
	end
	local function queueInsetRefresh(delayTime)
		task.delay(delayTime, function()
			checkInset("CoreGuiRefresh")
		end)
	end
	local robloxGui = CoreGui:FindFirstChild("RobloxGui")
	if robloxGui then
		local queued = false
		local function queueCoreGuiRefresh()
			if queued then
				return
			end
			queued = true
			task.defer(function()
				queued = false
				checkInset("CoreGuiRefresh")
			end)
		end
		robloxGui.DescendantAdded:Connect(queueCoreGuiRefresh)
		robloxGui.DescendantRemoving:Connect(queueCoreGuiRefresh)
	end
	CoreGui.ChildAdded:Connect(function(child)
		if child.Name == "RobloxGui" then
			queueInsetRefresh(0)
		end
	end)
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(checkInset)
	checkInset("FirstTime")
	queueInsetRefresh(1)
	queueInsetRefresh(3)

	local screenGui = Instance.new("ScreenGui")
	insetChanged:Connect(function()
		screenGui:SetAttribute("StartInset", startInset)
	end)
	screenGui.Name = "TopbarStandard"
	screenGui.Enabled = true
	screenGui.DisplayOrder = Icon.baseDisplayOrder
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets
	container[screenGui.Name] = screenGui
	Icon.baseDisplayOrderChanged:Connect(function()
		screenGui.DisplayOrder = Icon.baseDisplayOrder
	end)

	local holders = Instance.new("Frame")
	holders.Name = "Holders"
	holders.BackgroundTransparency = 1
	insetChanged:Connect(function()
		local holderY = if isUsingVR then 36 else math.max(GuiService.TopbarInset.Height + ySizeOffset, 50)
		holders.Position = UDim2.new(0, 0, 0, yDownOffset)
		holders.Size = UDim2.new(1, 0, 0, holderY)
	end)
	holders.Visible = true
	holders.ZIndex = 1
	holders.Parent = screenGui

	local screenGuiCenter = screenGui:Clone()
	local holdersCenter = screenGuiCenter.Holders
	local function updateCenteredHoldersHeight()
		holdersCenter.Size = UDim2.new(1, 0, 0, GuiService.TopbarInset.Height + ySizeOffset)
	end
	screenGuiCenter.Name = "TopbarCentered"
	screenGuiCenter.DisplayOrder = Icon.baseDisplayOrder
	screenGuiCenter.ScreenInsets = Enum.ScreenInsets.None
	Icon.baseDisplayOrderChanged:Connect(function()
		screenGuiCenter.DisplayOrder = Icon.baseDisplayOrder
	end)
	container[screenGuiCenter.Name] = screenGuiCenter

	insetChanged:Connect(updateCenteredHoldersHeight)
	updateCenteredHoldersHeight()

	local screenGuiClipped = screenGui:Clone()
	screenGuiClipped.Name = screenGuiClipped.Name .. "Clipped"
	screenGuiClipped.DisplayOrder = (Icon.baseDisplayOrder + 1)
	Icon.baseDisplayOrderChanged:Connect(function()
		screenGuiClipped.DisplayOrder = (Icon.baseDisplayOrder + 1)
	end)
	container[screenGuiClipped.Name] = screenGuiClipped

	local screenGuiCenterClipped = screenGuiCenter:Clone()
	screenGuiCenterClipped.Name = screenGuiCenterClipped.Name .. "Clipped"
	screenGuiCenterClipped.DisplayOrder = (Icon.baseDisplayOrder + 1)
	Icon.baseDisplayOrderChanged:Connect(function()
		screenGuiCenterClipped.DisplayOrder = (Icon.baseDisplayOrder + 1)
	end)
	container[screenGuiCenterClipped.Name] = screenGuiCenterClipped

	local holderReduction = -24
	local left = Instance.new("ScrollingFrame")
	left:SetAttribute("IsAHolder", true)
	left.Name = "Left"
	insetChanged:Connect(function()
		left.Position = UDim2.fromOffset(startInset, 0)
		left.Size = UDim2.new(1, holderReduction - startInset, 1, 0)
	end)
	left.Size = UDim2.new(1, holderReduction, 1, 0)
	left.BackgroundTransparency = 1
	left.Visible = true
	left.ZIndex = 1
	left.Active = false
	left.ClipsDescendants = true
	left.HorizontalScrollBarInset = Enum.ScrollBarInset.None
	left.CanvasSize = UDim2.new(0, 0, 1, -1)
	left.AutomaticCanvasSize = Enum.AutomaticSize.X
	left.ScrollingDirection = Enum.ScrollingDirection.X
	left.ScrollBarThickness = 0
	left.BorderSizePixel = 0
	left.Selectable = false
	left.ScrollingEnabled = false
	left.ElasticBehavior = Enum.ElasticBehavior.Never
	left.Parent = holders

	local UIListLayout = Instance.new("UIListLayout")
	insetChanged:Connect(function()
		UIListLayout.Padding = UDim.new(0, iconPadding)
	end)
	UIListLayout.FillDirection = Enum.FillDirection.Horizontal
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	UIListLayout.Parent = left

	local center = left:Clone()
	insetChanged:Connect(function()
		center.UIListLayout.Padding = UDim.new(0, iconPadding)
	end)
	center.ScrollingEnabled = false
	center.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	center.Name = "Center"
	center.Parent = holdersCenter

	local right = left:Clone()
	insetChanged:Connect(function()
		right.UIListLayout.Padding = UDim.new(0, iconPadding)
	end)
	right.UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	right.Name = "Right"
	right.AnchorPoint = Vector2.new(1, 0)
	right.Position = UDim2.new(1, -12, 0, 0)
	right.Parent = holders

	insetChanged:Fire(guiInset)

	return container
end
