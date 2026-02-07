local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local function Create(className)
	return function(props)
		local inst = Instance.new(className)
		for k, v in pairs(props) do
			if typeof(k) == "number" then
				v.Parent = inst
			else
				inst[k] = v
			end
		end
		return inst
	end
end

local Constants = {
	COLORS = {
		FLINT = Color3.fromRGB(48, 49, 53),
		WHITE = Color3.fromRGB(255, 255, 255),
		PUMICE = Color3.fromRGB(214, 214, 214),
		SLATE = Color3.fromRGB(163, 162, 165),
	},
	ERROR_PROMPT_MAX_WIDTH = { Default = 420 },
	ERROR_PROMPT_MIN_WIDTH = { Default = 360 },
	ERROR_PROMPT_HEIGHT = { Default = 190 },
	ERROR_PROMPT_MIN_HEIGHT = { Default = 170 },
	ERROR_TITLE_FRAME_HEIGHT = { Default = 46 },
	SPLIT_LINE_THICKNESS = 1,
	SIDE_PADDING = 24,
	SIDE_MARGIN = 24,
	VERTICAL_MARGIN = 24,
	BUTTON_HEIGHT = 44,
	BUTTON_CELL_PADDING = 12,
	LAYOUT_PADDING = 10,
}

local Create_ = Create

local Templates = {}

Templates.Default = function()
	local frame = Create_("Frame")({
		Name = "ErrorPrompt",
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		BackgroundColor3 = Constants.COLORS.FLINT,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, Constants.ERROR_PROMPT_MAX_WIDTH.Default, 0, Constants.ERROR_PROMPT_HEIGHT.Default),
		Visible = false,
		AutoLocalize = false,
		ZIndex = 8,
	})

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Name = "PromptLayout"
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = frame

	local scale = Instance.new("UIScale")
	scale.Name = "PromptScale"
	scale.Scale = 0
	scale.Parent = frame

	local titleFrame = Instance.new("Frame")
	titleFrame.Name = "TitleFrame"
	titleFrame.LayoutOrder = 1
	titleFrame.BackgroundTransparency = 1
	titleFrame.Size = UDim2.new(1, 0, 0, Constants.ERROR_TITLE_FRAME_HEIGHT.Default)
	titleFrame.BorderSizePixel = 0
	titleFrame.ZIndex = 8
	titleFrame.Parent = frame

	local titlePadding = Instance.new("UIPadding")
	titlePadding.Name = "TitleFramePadding"
	titlePadding.PaddingBottom = UDim.new(0, 11)
	titlePadding.PaddingTop = UDim.new(0, 11)
	titlePadding.PaddingLeft = UDim.new(0, Constants.SIDE_PADDING)
	titlePadding.PaddingRight = UDim.new(0, Constants.SIDE_PADDING)
	titlePadding.Parent = titleFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "ErrorTitle"
	titleLabel.TextColor3 = Constants.COLORS.WHITE
	titleLabel.TextSize = 25
	titleLabel.Size = UDim2.new(1, 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.SourceSansSemibold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Center
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.ZIndex = 8
	titleLabel.Text = ""
	titleLabel.Parent = titleFrame

	local splitLine = Instance.new("Frame")
	splitLine.Name = "SplitLine"
	splitLine.LayoutOrder = 2
	splitLine.Size = UDim2.new(1, -2 * Constants.SIDE_PADDING, 0, Constants.SPLIT_LINE_THICKNESS)
	splitLine.BackgroundColor3 = Constants.COLORS.PUMICE
	splitLine.BorderSizePixel = 0
	splitLine.ZIndex = 8
	splitLine.Parent = frame

	local messageArea = Instance.new("Frame")
	messageArea.Name = "MessageArea"
	messageArea.LayoutOrder = 3
	messageArea.Size = UDim2.new(1, 0, 1, -Constants.ERROR_TITLE_FRAME_HEIGHT.Default - Constants.SPLIT_LINE_THICKNESS)
	messageArea.BackgroundTransparency = 1
	messageArea.BorderSizePixel = 0
	messageArea.ZIndex = 8
	messageArea.Parent = frame

	local messagePadding = Instance.new("UIPadding")
	messagePadding.Name = "MessageAreaPadding"
	messagePadding.PaddingBottom = UDim.new(0, Constants.SIDE_PADDING)
	messagePadding.PaddingLeft = UDim.new(0, Constants.SIDE_PADDING)
	messagePadding.PaddingRight = UDim.new(0, Constants.SIDE_PADDING)
	messagePadding.PaddingTop = UDim.new(0, Constants.SIDE_PADDING)
	messagePadding.Parent = messageArea

	local errorFrame = Instance.new("Frame")
	errorFrame.Name = "ErrorFrame"
	errorFrame.BackgroundTransparency = 1
	errorFrame.Size = UDim2.new(1, 0, 1, 0)
	errorFrame.ZIndex = 8
	errorFrame.Parent = messageArea

	local errorLayout = Instance.new("UIListLayout")
	errorLayout.Name = "ErrorFrameLayout"
	errorLayout.Padding = UDim.new(0, Constants.LAYOUT_PADDING)
	errorLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	errorLayout.SortOrder = Enum.SortOrder.LayoutOrder
	errorLayout.Parent = errorFrame

	local errorMessage = Instance.new("TextLabel")
	errorMessage.Name = "ErrorMessage"
	errorMessage.LayoutOrder = 1
	errorMessage.Size = UDim2.new(1, 0, 1, -Constants.BUTTON_HEIGHT - Constants.LAYOUT_PADDING)
	errorMessage.TextSize = 20
	errorMessage.TextColor3 = Constants.COLORS.PUMICE
	errorMessage.ZIndex = 8
	errorMessage.BackgroundTransparency = 1
	errorMessage.TextWrapped = true
	errorMessage.Font = Enum.Font.SourceSans
	errorMessage.TextXAlignment = Enum.TextXAlignment.Center
	errorMessage.TextYAlignment = Enum.TextYAlignment.Top
	errorMessage.Text = ""
	errorMessage.Parent = errorFrame

	local buttonArea = Instance.new("Frame")
	buttonArea.Name = "ButtonArea"
	buttonArea.BackgroundTransparency = 1
	buttonArea.Size = UDim2.new(1, 0, 0, Constants.BUTTON_HEIGHT)
	buttonArea.ZIndex = 8
	buttonArea.LayoutOrder = 2
	buttonArea.SelectionGroup = true
	buttonArea.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
	buttonArea.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
	buttonArea.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	buttonArea.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	buttonArea.Parent = errorFrame

	local buttonLayout = Instance.new("UIGridLayout")
	buttonLayout.Name = "ButtonLayout"
	buttonLayout.CellPadding = UDim2.new(0, Constants.BUTTON_CELL_PADDING, 0, 0)
	buttonLayout.CellSize = UDim2.new(1, 0, 0, Constants.BUTTON_HEIGHT)
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buttonLayout.Parent = buttonArea

	return frame
end

local function makeButton(text, layoutOrder, primary)
	local button = Instance.new("ImageButton")
	button.Name = text .. "Button"
	button.BackgroundTransparency = 0
	if primary then
		button.BackgroundColor3 = Constants.COLORS.WHITE
	else
		button.BackgroundColor3 = Color3.fromRGB(70, 71, 74)
	end
	button.BorderSizePixel = 0
	button.ScaleType = Enum.ScaleType.Stretch
	button.ImageTransparency = 1
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Size = UDim2.new(1, 0, 1, 0)
	button.LayoutOrder = layoutOrder or 1
	button.ZIndex = 8

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	local label = Instance.new("TextLabel")
	label.Name = "ButtonText"
	label.Text = text
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSans
	label.TextSize = 20
	if primary then
		label.TextColor3 = Color3.fromRGB(35, 37, 39)
	else
		label.TextColor3 = Constants.COLORS.PUMICE
	end
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = 8
	label.Parent = button

	return button
end

local TrollErrorPrompt = {}
TrollErrorPrompt.__index = TrollErrorPrompt

local TweenInfo_ = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, false, 0)

local function sinkInput(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end

function TrollErrorPrompt.new(styleName, options)
	local self = setmetatable({}, TrollErrorPrompt)

	local frame = Templates.Default()
	self._frame = frame
	self._screenGui = nil
	self._isOpen = false
	self._buttonCount = 0
	self._primaryButton = nil
	self._playAnimation = true
	self._hideErrorCode = false
	self._menuIsOpenKey = "ErrorPrompt"

	if options then
		if options.PlayAnimation ~= nil then
			self._playAnimation = options.PlayAnimation
		end
		if options.HideErrorCode ~= nil then
			self._hideErrorCode = options.HideErrorCode
		end
		if options.MenuIsOpenKey ~= nil then
			self._menuIsOpenKey = options.MenuIsOpenKey
		end
		frame.MessageArea.ErrorFrame.ErrorMessage.TextScaled = options.MessageTextScaled or false
	end

	self._openAnimation = TweenService:Create(frame.PromptScale, TweenInfo_, { Scale = 1 })
	self._closeAnimation = TweenService:Create(frame.PromptScale, TweenInfo_, { Scale = 0 })

	if not UserInputService.VREnabled and UserInputService.GamepadEnabled then
		GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
			if self._isOpen and GuiService.SelectedObject == nil then
				GuiService.SelectedObject = self._frame.MessageArea.ErrorFrame.ButtonArea
			end
		end)
	end

	return self
end

function TrollErrorPrompt:setParent(parent)
	if parent and parent:IsA("PlayerGui") then
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "TrollErrorPromptGui"
		screenGui.IgnoreGuiInset = true
		screenGui.ResetOnSpawn = false
		screenGui.DisplayOrder = 999999
		screenGui.Parent = parent
		self._screenGui = screenGui
		self._frame.Parent = screenGui
	elseif parent and parent:IsA("GuiBase2d") then
		self._screenGui = parent
		self._frame.Parent = parent
	else
		self._frame.Parent = parent
	end
end

function TrollErrorPrompt:_resizeWidth(screenWidth)
	local offset = self._frame.Size.X.Offset
	local target = screenWidth - 2 * Constants.SIDE_MARGIN
	if Constants.ERROR_PROMPT_MAX_WIDTH.Default < target then
		if offset == Constants.ERROR_PROMPT_MAX_WIDTH.Default then return end
		target = Constants.ERROR_PROMPT_MAX_WIDTH.Default
	end
	if target < Constants.ERROR_PROMPT_MIN_WIDTH.Default then
		if offset == Constants.ERROR_PROMPT_MIN_WIDTH.Default then return end
		target = Constants.ERROR_PROMPT_MIN_WIDTH.Default
	end
	self._frame.Size = UDim2.new(0, target, 0, self._frame.Size.Y.Offset)
end

function TrollErrorPrompt:_resizeHeight(screenHeight)
	local msg = self._frame.MessageArea.ErrorFrame.ErrorMessage
	local width = self._frame.Size.X.Offset - 2 * Constants.SIDE_PADDING
	local textSize = TextService:GetTextSize(msg.Text, msg.TextSize, msg.Font, Vector2.new(width, 1000))
	local total = Constants.ERROR_TITLE_FRAME_HEIGHT.Default
	total = total + textSize.Y
	total = total + Constants.SPLIT_LINE_THICKNESS
	total = total + Constants.BUTTON_HEIGHT
	total = total + Constants.LAYOUT_PADDING
	total = total + 2 * Constants.SIDE_PADDING + 1
	local maxHeight = screenHeight - 2 * Constants.VERTICAL_MARGIN
	local clamped = math.max(math.min(total, maxHeight), Constants.ERROR_PROMPT_MIN_HEIGHT.Default)
	self._frame.Size = UDim2.new(0, self._frame.Size.X.Offset, 0, clamped)
end

function TrollErrorPrompt:resizeWidthAndHeight()
	local w, h = 800, 600
	if self._screenGui and self._screenGui.AbsoluteSize then
		w = self._screenGui.AbsoluteSize.X
		h = self._screenGui.AbsoluteSize.Y
	end
	self:_resizeWidth(w)
	self:_resizeHeight(h)
	self:_relayout()
end

function TrollErrorPrompt:_relayout()
	local buttonArea = self._frame.MessageArea.ErrorFrame.ButtonArea
	if self._buttonCount == 0 then
		buttonArea.Visible = false
	else
		buttonArea.Visible = true
		if self._buttonCount == 1 then
			buttonArea.ButtonLayout.CellSize = UDim2.new(1, 0, 0, Constants.BUTTON_HEIGHT)
		else
			local width = (self._frame.Size.X.Offset - (self._buttonCount - 1) * Constants.BUTTON_CELL_PADDING - 2 * Constants.SIDE_PADDING) / self._buttonCount
			buttonArea.ButtonLayout.CellSize = UDim2.new(0, width, 0, Constants.BUTTON_HEIGHT)
		end
	end
end

function TrollErrorPrompt:clearButtons()
	self._primaryButton = nil
	for _, v in pairs(self._frame.MessageArea.ErrorFrame.ButtonArea:GetChildren()) do
		if v.Name ~= "ButtonLayout" then
			v:Destroy()
		end
	end
	self._buttonCount = 0
	self:_relayout()
end

function TrollErrorPrompt:updateButtons(buttons)
	self:clearButtons()
	if not buttons then
		return
	end
	local count = 0
	for _, info in ipairs(buttons) do
		local btn = makeButton(info.Text or "OK", info.LayoutOrder or 1, info.Primary or false)
		btn.Parent = self._frame.MessageArea.ErrorFrame.ButtonArea
		if info.Callback then
			btn.Activated:Connect(info.Callback)
		end
		if info.Primary then
			self._primaryButton = btn
		end
		count += 1
	end
	self._buttonCount = count
	self:_relayout()
end

function TrollErrorPrompt:setErrorText(message, errorCode, extra)
	local msg = message or ""
	if not self._hideErrorCode then
		local codePart = errorCode and ("Error Code: " .. tostring(errorCode)) or "Error Code: -1"
		if extra and extra ~= "" then
			msg = string.format("%s\n(%s, %s)", msg, codePart, extra)
		else
			msg = string.format("%s\n(%s)", msg, codePart)
		end
	end
	self._frame.MessageArea.ErrorFrame.ErrorMessage.Text = msg
end

function TrollErrorPrompt:setErrorTitle(text)
	self._frame.TitleFrame.ErrorTitle.Text = text or "Disconnected"
end

function TrollErrorPrompt:_open(message, errorCode, extra)
	self:setErrorText(message, errorCode, extra)
	local h = 720
	if self._screenGui and self._screenGui.AbsoluteSize then
		h = self._screenGui.AbsoluteSize.Y
	end
	self:_resizeHeight(h)
	if not self._isOpen then
		self._isOpen = true
		self._frame.Visible = true
		if self._playAnimation then
			self._openAnimation:Play()
			self._openAnimation.Completed:Wait()
			self._frame.PromptScale.Scale = 1
		else
			self._frame.PromptScale.Scale = 1
		end
	end
	if self._isOpen and (UserInputService.VREnabled or UserInputService.GamepadEnabled) then
		GuiService.SelectedObject = self._frame.MessageArea.ErrorFrame.ButtonArea
	end
	ContextActionService:BindAction("TrollErrorPromptSink", sinkInput, false, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonStart)
end

function TrollErrorPrompt:_close()
	if not self._isOpen then
		return
	end
	self._isOpen = false
	if self._playAnimation then
		self._closeAnimation:Play()
		self._closeAnimation.Completed:Wait()
	else
		self._frame.PromptScale.Scale = 0
	end
	self._frame.Visible = false
	ContextActionService:UnbindAction("TrollErrorPromptSink")
end

function TrollErrorPrompt:onErrorChanged(message, errorCode, extra)
	if not message or message == "" then
		self:_close()
	else
		self:_open(message, errorCode, extra)
	end
end

function TrollErrorPrompt:Destroy()
	self:_close()
	self._frame:Destroy()
end

return TrollErrorPrompt
