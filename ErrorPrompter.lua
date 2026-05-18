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

local __NAUIProtector = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {}
	local sharedEnv = rawget(_G, "shared")
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil)

	if cacheHost then
		local cached = rawget(cacheHost, "__lt_ui_protector")
		if type(cached) == "table" then
			return cached
		end
	end

	local loader = loadstring or load
	if type(loader) ~= "function" then
		return nil
	end

	local okSource, source = pcall(function()
		return game:HttpGet("https://ltseverydayyou.github.io/UIprotector.luau")
	end)

	if not okSource or type(source) ~= "string" or source == "" then
		return nil
	end

	local chunk = loader(source, "@UIprotector.luau")
	if type(chunk) ~= "function" then
		return nil
	end

	local okLoaded, loaded = pcall(chunk)
	if okLoaded and type(loaded) == "table" then
		if cacheHost then
			cacheHost.__lt_ui_protector = loaded
		end

		return loaded
	end

	return nil
end)()

local __NAOriginalGetHui = gethui

local gethui = function()
	if __NAUIProtector and type(__NAUIProtector.huiGrabber) == "function" then
		local ok, ui = pcall(__NAUIProtector.huiGrabber)
		if ok and typeof(ui) == "Instance" then
			return ui
		end
	end

	if type(__NAOriginalGetHui) == "function" then
		local ok, ui = pcall(__NAOriginalGetHui)
		if ok and typeof(ui) == "Instance" then
			return ui
		end
	end

	return nil
end

local function __NAProtectUI(gui, opts)
	if __NAUIProtector and type(__NAUIProtector.protectUI) == "function" then
		local ok, protected = pcall(__NAUIProtector.protectUI, gui, opts)
		if ok and protected then
			return protected
		end
	end

	return nil
end

local cref = type(cloneref) == "function" and cloneref or nil

local Players = __lt.cs("Players", cref)
local TweenService = __lt.cs("TweenService", cref)
local ContextActionService = __lt.cs("ContextActionService", cref)
local GuiService = __lt.cs("GuiService", cref)
local UserInputService = __lt.cs("UserInputService", cref)
local TextService = __lt.cs("TextService", cref)
local VRService = __lt.cs("VRService", cref)

local LocalPlayer = Players.LocalPlayer

local function Create(cls)
	return function(props)
		local inst = Instance.new(cls)

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
		SLATE = Color3.fromRGB(35, 37, 39),
		DARK = Color3.fromRGB(70, 71, 74),
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

local Templates = {}

Templates.Default = function()
	return Create("Frame")({
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

		Create("UIListLayout")({
			Name = "PromptLayout",
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}),

		Create("UIScale")({
			Name = "PromptScale",
			Scale = 0,
		}),

		Create("Frame")({
			Name = "TitleFrame",
			LayoutOrder = 1,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, Constants.ERROR_TITLE_FRAME_HEIGHT.Default),
			BorderSizePixel = 0,
			ZIndex = 8,

			Create("UIPadding")({
				Name = "TitleFramePadding",
				PaddingBottom = UDim.new(0, 11),
				PaddingTop = UDim.new(0, 11),
			}),

			Create("TextLabel")({
				Name = "ErrorTitle",
				Text = "",
				TextColor3 = Constants.COLORS.WHITE,
				TextSize = 25,
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundTransparency = 1,
				Font = Enum.Font.SourceSansSemibold,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 8,
			}),
		}),

		Create("Frame")({
			Name = "SplitLine",
			LayoutOrder = 2,
			Size = UDim2.new(1, -2 * Constants.SIDE_PADDING, 0, Constants.SPLIT_LINE_THICKNESS),
			BackgroundColor3 = Constants.COLORS.PUMICE,
			BorderSizePixel = 0,
			ZIndex = 8,
		}),

		Create("Frame")({
			Name = "MessageArea",
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 1, -Constants.ERROR_TITLE_FRAME_HEIGHT.Default - Constants.SPLIT_LINE_THICKNESS),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 8,

			Create("UIPadding")({
				Name = "MessageAreaPadding",
				PaddingBottom = UDim.new(0, Constants.SIDE_PADDING),
				PaddingLeft = UDim.new(0, Constants.SIDE_PADDING),
				PaddingRight = UDim.new(0, Constants.SIDE_PADDING),
				PaddingTop = UDim.new(0, Constants.SIDE_PADDING),
			}),

			Create("Frame")({
				Name = "ErrorFrame",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				ZIndex = 8,

				Create("UIListLayout")({
					Name = "ErrorFrameLayout",
					Padding = UDim.new(0, Constants.LAYOUT_PADDING),
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				Create("TextLabel")({
					Name = "ErrorMessage",
					LayoutOrder = 1,
					Size = UDim2.new(1, 0, 1, -Constants.BUTTON_HEIGHT - Constants.LAYOUT_PADDING),
					Text = "",
					TextSize = 20,
					TextColor3 = Constants.COLORS.PUMICE,
					ZIndex = 8,
					BackgroundTransparency = 1,
					TextWrapped = true,
					Font = Enum.Font.SourceSans,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextYAlignment = Enum.TextYAlignment.Center,
				}),

				Create("Frame")({
					Name = "ButtonArea",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, Constants.BUTTON_HEIGHT),
					ZIndex = 8,
					LayoutOrder = 2,
					SelectionGroup = true,
					SelectionBehaviorUp = Enum.SelectionBehavior.Stop,
					SelectionBehaviorDown = Enum.SelectionBehavior.Stop,
					SelectionBehaviorLeft = Enum.SelectionBehavior.Stop,
					SelectionBehaviorRight = Enum.SelectionBehavior.Stop,

					Create("UIGridLayout")({
						Name = "ButtonLayout",
						CellPadding = UDim2.new(0, Constants.BUTTON_CELL_PADDING, 0, 0),
						CellSize = UDim2.new(1, 0, 0, Constants.BUTTON_HEIGHT),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
				}),
			}),
		}),
	})
end

local function isA(obj, cls)
	local ok, val = pcall(function()
		return typeof(obj) == "Instance" and obj:IsA(cls)
	end)

	return ok and val
end

local function mkGui(par)
	local sg = Instance.new("ScreenGui")
	sg.Name = "TrollErrorPromptGui"
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 999999
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local protected = __NAProtectUI(sg, {
		Name = "TrollErrorPromptGui",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 999999,
	})

	if typeof(protected) == "Instance" then
		sg = protected
	end

	if par and not sg.Parent then
		sg.Parent = par
	end

	return sg
end

local function getPg()
	if LocalPlayer then
		return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 2)
	end

	return nil
end

local function makeButton(text, order, primary)
	local btn = Create("ImageButton")({
		Name = tostring(text) .. "Button",
		BackgroundTransparency = 0,
		BackgroundColor3 = primary and Constants.COLORS.WHITE or Constants.COLORS.DARK,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		ImageTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1, 0, 1, 0),
		LayoutOrder = order or 1,
		ZIndex = 8,

		Create("UICorner")({
			CornerRadius = UDim.new(0, 8),
		}),

		Create("TextLabel")({
			Name = "ButtonText",
			Text = tostring(text),
			Size = UDim2.new(1, 0, 1, 0),
			TextColor3 = primary and Constants.COLORS.SLATE or Constants.COLORS.PUMICE,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Font = Enum.Font.SourceSans,
			TextSize = 20,
			ZIndex = 8,
		}),
	})

	return btn
end

local function sinkInput()
	return Enum.ContextActionResult.Sink
end

local TrollErrorPrompt = {}
TrollErrorPrompt.__index = TrollErrorPrompt

local TwInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, false, 0)

function TrollErrorPrompt.new(_, opts)
	local self = setmetatable({}, TrollErrorPrompt)
	local frame = Templates.Default()

	self._frame = frame
	self._screenGui = nil
	self._ownGui = false
	self._isOpen = false
	self._buttonCount = 0
	self._primaryButton = nil
	self._playAnimation = true
	self._hideErrorCode = false
	self._menuIsOpenKey = "ErrorPrompt"
	self._usingCore = false
	self._cons = {}
	self._btnCons = {}

	if opts then
		if opts.PlayAnimation ~= nil then
			self._playAnimation = opts.PlayAnimation
		end

		if opts.HideErrorCode ~= nil then
			self._hideErrorCode = opts.HideErrorCode
		end

		if opts.MenuIsOpenKey ~= nil then
			self._menuIsOpenKey = opts.MenuIsOpenKey
		end

		frame.MessageArea.ErrorFrame.ErrorMessage.TextScaled = opts.MessageTextScaled or false
	end

	self._openAnimation = TweenService:Create(frame.PromptScale, TwInfo, {
		Scale = 1,
	})

	self._closeAnimation = TweenService:Create(frame.PromptScale, TwInfo, {
		Scale = 0,
	})

	if not VRService.VREnabled and UserInputService.GamepadEnabled then
		local con = GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
			if self._isOpen and GuiService.SelectedObject == nil then
				GuiService.SelectedObject = self._frame.MessageArea.ErrorFrame.ButtonArea
			end
		end)

		self._cons[#self._cons + 1] = con
	end

	return self
end

function TrollErrorPrompt:setParent(par)
	if self._ownGui and self._screenGui then
		self._screenGui:Destroy()
		self._screenGui = nil
		self._ownGui = false
	end

	par = par or gethui() or getPg()

	if not par or typeof(par) ~= "Instance" then
		return nil
	end

	if isA(par, "ScreenGui") then
		self._screenGui = par
		self._ownGui = false
		self._frame.Parent = par
		return par
	end

	if isA(par, "Folder") or isA(par, "BasePlayerGui") then
		local sg = mkGui(par)
		self._screenGui = sg
		self._ownGui = true
		self._frame.Parent = sg
		return sg
	end

	if isA(par, "GuiBase2d") then
		self._screenGui = par:FindFirstAncestorOfClass("ScreenGui")
		self._ownGui = false
		self._frame.Parent = par
		return par
	end

	self._frame.Parent = par
	return par
end

function TrollErrorPrompt:_size()
	local gui = self._screenGui
	if gui and gui.AbsoluteSize then
		local sz = gui.AbsoluteSize
		if sz.X > 0 and sz.Y > 0 then
			return sz.X, sz.Y
		end
	end

	local par = self._frame.Parent
	if par and par.AbsoluteSize then
		local sz = par.AbsoluteSize
		if sz.X > 0 and sz.Y > 0 then
			return sz.X, sz.Y
		end
	end

	return 800, 600
end

function TrollErrorPrompt:_resizeWidth(w)
	local cur = self._frame.Size.X.Offset
	local target = w - 2 * Constants.SIDE_MARGIN

	if Constants.ERROR_PROMPT_MAX_WIDTH.Default < target then
		if cur == Constants.ERROR_PROMPT_MAX_WIDTH.Default then
			return
		end

		target = Constants.ERROR_PROMPT_MAX_WIDTH.Default
	end

	if target < Constants.ERROR_PROMPT_MIN_WIDTH.Default then
		if cur == Constants.ERROR_PROMPT_MIN_WIDTH.Default then
			return
		end

		target = Constants.ERROR_PROMPT_MIN_WIDTH.Default
	end

	self._frame.Size = UDim2.new(0, target, 0, self._frame.Size.Y.Offset)
end

function TrollErrorPrompt:_resizeHeight(h)
	local msg = self._frame.MessageArea.ErrorFrame.ErrorMessage
	local width = self._frame.Size.X.Offset - 2 * Constants.SIDE_PADDING
	local sz = TextService:GetTextSize(msg.Text, msg.TextSize, msg.Font, Vector2.new(width, 1000))

	local total = Constants.ERROR_TITLE_FRAME_HEIGHT.Default
	total += sz.Y
	total += Constants.SPLIT_LINE_THICKNESS
	total += Constants.BUTTON_HEIGHT
	total += Constants.LAYOUT_PADDING
	total += 2 * Constants.SIDE_PADDING + 1

	local maxH = h - 2 * Constants.VERTICAL_MARGIN
	local final = math.max(math.min(total, maxH), Constants.ERROR_PROMPT_MIN_HEIGHT.Default)

	self._frame.Size = UDim2.new(0, self._frame.Size.X.Offset, 0, final)
end

function TrollErrorPrompt:_relayout()
	local area = self._frame.MessageArea.ErrorFrame.ButtonArea

	if self._buttonCount == 0 then
		area.Visible = false
		return
	end

	area.Visible = true

	local width = self._frame.Size.X.Offset
	width -= (self._buttonCount - 1) * Constants.BUTTON_CELL_PADDING
	width -= 2 * Constants.SIDE_PADDING
	width /= self._buttonCount

	area.ButtonLayout.CellSize = UDim2.new(0, width, 0, Constants.BUTTON_HEIGHT)
end

function TrollErrorPrompt:resizeWidthAndHeight(w, h)
	if not w or not h then
		w, h = self:_size()
	end

	self:_resizeWidth(w)
	self:_resizeHeight(h)
	self:_relayout()
end

function TrollErrorPrompt:clearButtons()
	self._primaryButton = nil

	for i = 1, #self._btnCons do
		local con = self._btnCons[i]
		if con then
			con:Disconnect()
			self._btnCons[i] = nil
		end
	end

	local area = self._frame.MessageArea.ErrorFrame.ButtonArea

	for _, v in pairs(area:GetChildren()) do
		if v.Name ~= "ButtonLayout" then
			v:Destroy()
		end
	end

	self._buttonCount = 0
	self:_relayout()
end

function TrollErrorPrompt:updateButtons(btns)
	self:clearButtons()

	if not btns then
		return
	end

	local count = 0
	local area = self._frame.MessageArea.ErrorFrame.ButtonArea

	for _, info in pairs(btns) do
		local text = info.Text or "OK"
		local btn = makeButton(text, info.LayoutOrder or 1, info.Primary == true)

		btn.Parent = area

		if info.Primary then
			self._primaryButton = btn
		end

		if type(info.Callback) == "function" then
			local con = btn.Activated:Connect(info.Callback)
			self._btnCons[#self._btnCons + 1] = con
		end

		count += 1
	end

	self._buttonCount = count
	self:_relayout()
end

function TrollErrorPrompt:_code(err)
	if err == nil then
		return -1
	end

	if typeof(err) == "Instance" then
		local ok, val = pcall(function()
			return err.Value
		end)

		if ok and val ~= nil then
			return val
		end
	end

	if type(err) == "table" and err.Value ~= nil then
		return err.Value
	end

	return err
end

function TrollErrorPrompt:setErrorText(text, err, extra)
	local msg = tostring(text or "")

	if self._hideErrorCode then
		self._frame.MessageArea.ErrorFrame.ErrorMessage.Text = msg
		return
	end

	local code = self:_code(err)
	local codeText = ("Error Code: %s"):format(tostring(code))

	if extra and extra ~= "" then
		msg = ("%s\n(%s, %s)"):format(msg, codeText, tostring(extra))
	else
		msg = ("%s\n(%s)"):format(msg, codeText)
	end

	self._frame.MessageArea.ErrorFrame.ErrorMessage.Text = msg
end

function TrollErrorPrompt:setErrorTitle(text)
	self._frame.TitleFrame.ErrorTitle.Text = text or "Disconnected"
end

function TrollErrorPrompt:_setMenu(on)
	pcall(function()
		GuiService:SetMenuIsOpen(on, self._menuIsOpenKey)
	end)
end

function TrollErrorPrompt:_bind()
	local ok = pcall(function()
		ContextActionService:BindCoreAction(
			"TrollErrorPromptSink",
			sinkInput,
			false,
			Enum.KeyCode.ButtonSelect,
			Enum.KeyCode.ButtonStart
		)
	end)

	self._usingCore = ok

	if not ok then
		pcall(function()
			ContextActionService:BindAction(
				"TrollErrorPromptSink",
				sinkInput,
				false,
				Enum.KeyCode.ButtonSelect,
				Enum.KeyCode.ButtonStart
			)
		end)
	end
end

function TrollErrorPrompt:_unbind()
	if self._usingCore then
		pcall(function()
			ContextActionService:UnbindCoreAction("TrollErrorPromptSink")
		end)
	else
		pcall(function()
			ContextActionService:UnbindAction("TrollErrorPromptSink")
		end)
	end

	self._usingCore = false
end

function TrollErrorPrompt:_select()
	if self._isOpen and (VRService.VREnabled or UserInputService.GamepadEnabled) then
		pcall(function()
			GuiService.SelectedObject = self._frame.MessageArea.ErrorFrame.ButtonArea
		end)
	end
end

function TrollErrorPrompt:_open(text, err, extra)
	if not self._frame.Parent then
		self:setParent()
	end

	self:setErrorText(text, err, extra)
	self:resizeWidthAndHeight()

	if not self._isOpen then
		self._isOpen = true
		self._frame.Visible = true
		self:_setMenu(true)

		if self._playAnimation then
			self._closeAnimation:Cancel()
			self._openAnimation:Play()
			self._openAnimation.Completed:Wait()
		end

		self._frame.PromptScale.Scale = 1
	end

	self:_select()
	self:_bind()
end

function TrollErrorPrompt:_close()
	if not self._isOpen then
		return
	end

	self._isOpen = false
	self:_setMenu(false)

	if self._playAnimation then
		self._openAnimation:Cancel()
		self._closeAnimation:Play()
		self._closeAnimation.Completed:Wait()
	else
		self._frame.PromptScale.Scale = 0
	end

	self._frame.PromptScale.Scale = 0
	self._frame.Visible = false
	self:_unbind()
end

function TrollErrorPrompt:onErrorChanged(text, err, extra)
	if not text or text == "" then
		self:_close()
		return
	end

	self:_open(text, err, extra)
end

function TrollErrorPrompt:primaryShimmerPlay() end

function TrollErrorPrompt:primaryShimmerStop() end

function TrollErrorPrompt:Destroy()
	self:_close()
	self:clearButtons()

	for i = 1, #self._cons do
		local con = self._cons[i]
		if con then
			con:Disconnect()
			self._cons[i] = nil
		end
	end

	if self._ownGui and self._screenGui then
		self._screenGui:Destroy()
	elseif self._frame then
		self._frame:Destroy()
	end

	self._screenGui = nil
	self._frame = nil
end

return TrollErrorPrompt