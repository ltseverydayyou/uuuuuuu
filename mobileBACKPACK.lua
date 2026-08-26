-- Reworked from Satchel backpack by Ryan Lua (@WinnersTakesAll): https://github.com/ryanlua/satchel
local SR = (function()
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

local function __NAFallbackRoot()
	if __NAUIProtector and type(__NAUIProtector.huiGrabber) == "function" then
		local ok, root = pcall(__NAUIProtector.huiGrabber)
		if ok and typeof(root) == "Instance" then
			return root
		end
	end
	if type(gethui) == "function" then
		local ok, root = pcall(gethui)
		if ok and typeof(root) == "Instance" then
			return root
		end
	end
	local okCore, coreGui = pcall(SR.cs, "CoreGui", cloneref)
	if okCore and coreGui then
		return coreGui:FindFirstChild("RobloxGui") or coreGui
	end
	local players = SR.cs("Players", cloneref)
	local player = players and players.LocalPlayer
	return player and player:FindFirstChildOfClass("PlayerGui")
end

local function __NAProtectUI(gui)
	if __NAUIProtector and type(__NAUIProtector.protectUI) == "function" then
		local ok, protected = pcall(__NAUIProtector.protectUI, gui)
		if ok and typeof(protected) == "Instance" then
			return protected
		end
	end
	if not gui.Parent then
		gui.Parent = __NAFallbackRoot()
	end
	return gui
end

do
	local env = (getgenv and getgenv()) or _G
	if type(env) == "table" then
		if env.BPX then
			return
		end
		env.BPX = true
	end
end












local ContextActionService = assert(SR.cs("ContextActionService", cloneref), "ContextActionService unavailable")
local TextChatService = assert(SR.cs("TextChatService", cloneref), "TextChatService unavailable")
local UserInputService = assert(SR.cs("UserInputService", cloneref), "UserInputService unavailable")
local StarterGui = assert(SR.cs("StarterGui", cloneref), "StarterGui unavailable")
local GuiService = assert(SR.cs("GuiService", cloneref), "GuiService unavailable")
local RunService = assert(SR.cs("RunService", cloneref), "RunService unavailable")
local TweenService = assert(SR.cs("TweenService", cloneref), "TweenService unavailable")
local VRService = assert(SR.cs("VRService", cloneref), "VRService unavailable")
local Players = assert(SR.cs("Players", cloneref), "Players unavailable")
local PlayerGui: Instance = Players.LocalPlayer:WaitForChild("PlayerGui")

local BackpackScript = {}

BackpackScript.OpenClose = nil :: any
BackpackScript.IsOpen = false :: boolean
BackpackScript.StateChanged = Instance.new("BindableEvent") :: BindableEvent

BackpackScript.ModuleName = "Backpack" :: string
BackpackScript.KeepVRTopbarOpen = true :: boolean
BackpackScript.VRIsExclusive = true :: boolean
BackpackScript.VRClosesNonExclusive = true :: boolean

BackpackScript.BackpackEmpty = Instance.new("BindableEvent") :: BindableEvent
BackpackScript.BackpackEmpty.Name = "BackpackEmpty"

BackpackScript.BackpackItemAdded = Instance.new("BindableEvent") :: BindableEvent
BackpackScript.BackpackItemAdded.Name = "BackpackAdded"

BackpackScript.BackpackItemRemoved = Instance.new("BindableEvent") :: BindableEvent
BackpackScript.BackpackItemRemoved.Name = "BackpackRemoved"

local __SatchelAttributes = {
	BackgroundColor3 = Color3.new(25 / 255, 27 / 255, 29 / 255),
	BackgroundTransparency = 0.3,
	CornerRadius = UDim.new(0, 8),
	EquipBorderColor3 = Color3.new(1, 1, 1),
	EquipBorderSizePixel = 5,
	InsetIconPadding = true,
	OutlineEquipBorder = true,
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 16,
	TextStrokeColor3 = Color3.new(0, 0, 0),
	TextStrokeTransparency = 0.5,
}
local targetScript: any = {}
function targetScript:GetAttribute(name: string): any
	return __SatchelAttributes[name]
end




local PREFERRED_TRANSPARENCY: number = GuiService.PreferredTransparency or 1


local LEGACY_EDGE_ENABLED: boolean = not targetScript:GetAttribute("OutlineEquipBorder") or false
local LEGACY_PADDING_ENABLED: boolean = targetScript:GetAttribute("InsetIconPadding")


local BACKGROUND_TRANSPARENCY_DEFAULT: number = targetScript:GetAttribute("BackgroundTransparency") or 0.3
local BACKGROUND_TRANSPARENCY: number = BACKGROUND_TRANSPARENCY_DEFAULT * PREFERRED_TRANSPARENCY
local BACKGROUND_CORNER_RADIUS: UDim = UDim.new(0, 8)
local BACKGROUND_COLOR: Color3 = targetScript:GetAttribute("BackgroundColor3")
	or Color3.new(25 / 255, 27 / 255, 29 / 255)


local SLOT_EQUIP_COLOR: Color3 = targetScript:GetAttribute("EquipBorderColor3") or Color3.new(0 / 255, 162 / 255, 1)
local SLOT_LOCKED_TRANSPARENCY_DEFAULT: number = targetScript:GetAttribute("BackgroundTransparency") or 0.3
local SLOT_LOCKED_TRANSPARENCY: number = SLOT_LOCKED_TRANSPARENCY_DEFAULT * PREFERRED_TRANSPARENCY
local SLOT_EQUIP_THICKNESS: number = targetScript:GetAttribute("EquipBorderSizePixel") or 5
local SLOT_CORNER_RADIUS: UDim = targetScript:GetAttribute("CornerRadius") or UDim.new(0, 8)
local SLOT_BORDER_COLOR: Color3 = Color3.new(1, 1, 1)


local TOOLTIP_CORNER_RADIUS: UDim = SLOT_CORNER_RADIUS - UDim.new(0, 5) or UDim.new(0, 3)
local TOOLTIP_BACKGROUND_COLOR: Color3 = targetScript:GetAttribute("BackgroundColor3")
	or Color3.new(25 / 255, 27 / 255, 29 / 255)
local TOOLTIP_PADDING: number = 4
local TOOLTIP_HEIGHT: number = 16
local TOOLTIP_OFFSET: number = -5


local ARROW_IMAGE_OPEN: string = "rbxasset://textures/ui/TopBar/inventoryOn.png"
local ARROW_IMAGE_CLOSE: string = "rbxasset://textures/ui/TopBar/inventoryOff.png"



local HOTBAR_SLOTS_FULL: number = 10
local HOTBAR_SLOTS_VR: number = 6
local HOTBAR_SLOTS_MINI: number = 6
local HOTBAR_SLOTS_WIDTH_CUTOFF: number = 1024

local INVENTORY_ROWS_FULL: number = 4
local INVENTORY_ROWS_VR: number = 3
local INVENTORY_ROWS_MINI: number = 2
local INVENTORY_HEADER_SIZE: number = 40
local INVENTORY_ARROWS_BUFFER_VR: number = 40


local TEXT_COLOR: Color3 = targetScript:GetAttribute("TextColor3") or Color3.new(1, 1, 1)
local TEXT_STROKE_TRANSPARENCY: number = targetScript:GetAttribute("TextStrokeTransparency") or 0.5
local TEXT_STROKE_COLOR: Color3 = targetScript:GetAttribute("TextStrokeColor3") or Color3.new(0, 0, 0)


local SEARCH_BACKGROUND_COLOR: Color3 = Color3.new(25 / 255, 27 / 255, 29 / 255)
local SEARCH_BACKGROUND_TRANSPARENCY_DEFAULT: number = 0.2
local SEARCH_BACKGROUND_TRANSPARENCY: number = SEARCH_BACKGROUND_TRANSPARENCY_DEFAULT * PREFERRED_TRANSPARENCY
local SEARCH_BORDER_COLOR: Color3 = Color3.new(1, 1, 1)
local SEARCH_BORDER_TRANSPARENCY: number = 0.8
local SEARCH_BORDER_THICKNESS: number = 1
local SEARCH_TEXT_PLACEHOLDER: string = "Search"
local SEARCH_TEXT_OFFSET: number = 8
local SEARCH_TEXT: string = ""
local SEARCH_CORNER_RADIUS: UDim = UDim.new(0, 3)
local SEARCH_IMAGE_X: string = "rbxasset://textures/ui/InspectMenu/x.png"
local SEARCH_BUFFER_PIXELS: number = 5
local SEARCH_WIDTH_PIXELS: number = 200


local FONT_FAMILY: Font = targetScript:GetAttribute("FontFace")
	or Font.new("rbxasset://fonts/families/BuilderSans.json")
local FONT_SIZE: number = targetScript:GetAttribute("TextSize") or 16
local DROP_HOTKEY_VALUE: number = Enum.KeyCode.Backspace.Value
local ZERO_KEY_VALUE: number = Enum.KeyCode.Zero.Value
local DOUBLE_CLICK_TIME: number = 0.5
local ICON_BUFFER_PIXELS: number = 5
local ICON_SIZE_PIXELS: number = 60

local MOUSE_INPUT_TYPES: { [Enum.UserInputType]: boolean } =
	{
		[Enum.UserInputType.MouseButton1] = true,
		[Enum.UserInputType.MouseButton2] = true,
		[Enum.UserInputType.MouseButton3] = true,
		[Enum.UserInputType.MouseMovement] = true,
		[Enum.UserInputType.MouseWheel] = true,
	}

local GAMEPAD_INPUT_TYPES: { [Enum.UserInputType]: boolean } =
	{
		[Enum.UserInputType.Gamepad1] = true,
		[Enum.UserInputType.Gamepad2] = true,
		[Enum.UserInputType.Gamepad3] = true,
		[Enum.UserInputType.Gamepad4] = true,
		[Enum.UserInputType.Gamepad5] = true,
		[Enum.UserInputType.Gamepad6] = true,
		[Enum.UserInputType.Gamepad7] = true,
		[Enum.UserInputType.Gamepad8] = true,
	}


local BackpackEnabled: boolean = true


local inventoryIcon: any = { enabled = true }
function inventoryIcon:lock(): () end
function inventoryIcon:unlock(): () end
function inventoryIcon:deselect(): () end
function inventoryIcon:setEnabled(enabled: boolean): ()
	self.enabled = enabled
end

local BackpackGui: ScreenGui = Instance.new("ScreenGui")
BackpackGui.DisplayOrder = 120
BackpackGui.IgnoreGuiInset = true
BackpackGui.ResetOnSpawn = false
BackpackGui.Name = "BackpackGui"
BackpackGui = __NAProtectUI(BackpackGui) :: any
if not BackpackGui.Parent then
	BackpackGui.Parent = PlayerGui
end

local IsTenFootInterface: boolean = GuiService:IsTenFootInterface()
if IsTenFootInterface then
	ICON_SIZE_PIXELS = 100
	FONT_SIZE = 24
end

local GamepadActionsBound: boolean = false

local IS_PHONE: boolean = UserInputService.TouchEnabled
	and workspace.CurrentCamera.ViewportSize.X < HOTBAR_SLOTS_WIDTH_CUTOFF

local Player: Player = Players.LocalPlayer

local MainFrame: Frame = nil
local HotbarFrame: Frame = nil
local InventoryFrame: Frame = nil
local VRInventorySelector: any = nil
local ScrollingFrame: ScrollingFrame = nil
local UIGridFrame: Frame = nil
local UIGridLayout: UIGridLayout = nil
local ScrollUpInventoryButton: any = nil
local ScrollDownInventoryButton: any = nil
local changeToolFunc: any = nil

local Character: Model = Player.Character or Player.CharacterAdded:Wait()
local Humanoid: any = Character:WaitForChild("Humanoid")
local Backpack: Instance = Player:WaitForChild("Backpack")

local Slots = {}
local LowestEmptySlot: any = nil
local SlotsByTool = {}
local HotkeyFns = {}
local Dragging: { boolean } = {}
local FullHotbarSlots: number = 0
local ActiveHopper = nil
local StarterToolFound: boolean = false
local WholeThingEnabled: boolean = false
local TextBoxFocused: boolean = false
local ViewingSearchResults: boolean = false

local CharConns: { RBXScriptConnection } = {}
local GamepadEnabled: boolean = false

local IsVR: boolean = VRService.VREnabled
local NumberOfHotbarSlots: number = IsVR and HOTBAR_SLOTS_VR or (IS_PHONE and HOTBAR_SLOTS_MINI or HOTBAR_SLOTS_FULL)
local NumberOfInventoryRows: number = IsVR and INVENTORY_ROWS_VR
	or (IS_PHONE and INVENTORY_ROWS_MINI or INVENTORY_ROWS_FULL)
local BackpackPanel = nil
local lastEquippedSlot: any = nil


local BPX = {}
BPX.MultiMode = false
BPX.SelectedTool = nil
BPX.Collapsed = false
BPX.Unloaded = false
BPX.RuntimeConnections = {}
BPX.ActiveTweens = {}
BPX.InventoryRestPosition = nil
BPX.InventoryAnimationId = 0
BPX.ControlsWasVisible = false
BPX.OPEN_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
BPX.CLOSE_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
BPX.POP_TWEEN = TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
BPX.CONTROL_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
BPX.PRESS_IN_TWEEN = TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
BPX.PRESS_OUT_TWEEN = TweenInfo.new(0.13, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
function BPX.TrackConnection(connection)
	if connection then
		table.insert(BPX.RuntimeConnections, connection)
	end
	return connection
end
function BPX.Tween(instance, info, properties)
	local old = BPX.ActiveTweens[instance]
	if old then
		pcall(function()
			old:Cancel()
		end)
	end
	local ok, tween = pcall(function()
		return TweenService:Create(instance, info, properties)
	end)
	if not ok or not tween then
		return nil
	end
	BPX.ActiveTweens[instance] = tween
	tween.Completed:Once(function()
		if BPX.ActiveTweens[instance] == tween then
			BPX.ActiveTweens[instance] = nil
		end
	end)
	tween:Play()
	return tween
end
BPX.UpdateControls = function() end

local function EvaluateBackpackPanelVisibility(enabled: boolean): boolean
	return enabled and inventoryIcon.enabled and BackpackEnabled and VRService.VREnabled
end

local function ShowVRBackpackPopup(): ()
	if BackpackPanel and EvaluateBackpackPanelVisibility(true) then
		BackpackPanel:ForceShowForSeconds(2)
	end
end

local function FindLowestEmpty(): number?
	for i: number = 1, NumberOfHotbarSlots do
		local slot: any = Slots[i]
		if not slot.Tool then
			return slot
		end
	end
	return nil
end

local function isInventoryEmpty(): boolean
	for i: number = NumberOfHotbarSlots + 1, #Slots do
		local slot: any = Slots[i]
		if slot and slot.Tool then
			return false
		end
	end
	return true
end

BackpackScript.IsInventoryEmpty = isInventoryEmpty

local function UseGazeSelection(): boolean
	return false
end

local function AdjustHotbarFrames(): ()
	local inventoryOpen: boolean = BackpackScript.IsOpen
	local visualTotal: number = inventoryOpen and NumberOfHotbarSlots or FullHotbarSlots
	local visualIndex: number = 0

	for i: number = 1, NumberOfHotbarSlots do
		local slot: any = Slots[i]
		if slot.Tool or inventoryOpen then
			visualIndex = visualIndex + 1
			slot:Readjust(visualIndex, visualTotal)
			slot.Frame.Visible = true
		else
			slot.Frame.Visible = false
		end
	end
end

local function UpdateScrollingFrameCanvasSize(): ()
	local countX: number = math.floor(ScrollingFrame.AbsoluteSize.X / (ICON_SIZE_PIXELS + ICON_BUFFER_PIXELS))
	local maxRow: number = math.ceil((#UIGridFrame:GetChildren() - 1) / countX)
	local canvasSizeY: number = maxRow * (ICON_SIZE_PIXELS + ICON_BUFFER_PIXELS) + ICON_BUFFER_PIXELS
	ScrollingFrame.CanvasSize = UDim2.fromOffset(0, canvasSizeY)
end

local function AdjustInventoryFrames(): ()
	for i: number = NumberOfHotbarSlots + 1, #Slots do
		local slot: any = Slots[i]
		slot.Frame.LayoutOrder = slot.Index
		slot.Frame.Visible = (slot.Tool ~= nil)
	end
	UpdateScrollingFrameCanvasSize()
end

local function UpdateBackpackLayout(): ()
	HotbarFrame.Size = UDim2.new(
		0,
		ICON_BUFFER_PIXELS + (NumberOfHotbarSlots * (ICON_SIZE_PIXELS + ICON_BUFFER_PIXELS)),
		0,
		ICON_BUFFER_PIXELS + ICON_SIZE_PIXELS + ICON_BUFFER_PIXELS
	)
	HotbarFrame.Position = UDim2.new(0.5, -HotbarFrame.Size.X.Offset / 2, 1, -HotbarFrame.Size.Y.Offset)
	InventoryFrame.Size = UDim2.new(
		0,
		HotbarFrame.Size.X.Offset,
		0,
		(HotbarFrame.Size.Y.Offset * NumberOfInventoryRows)
			+ INVENTORY_HEADER_SIZE
			+ (IsVR and 2 * INVENTORY_ARROWS_BUFFER_VR or 0)
	)
	InventoryFrame.Position = UDim2.new(
		0.5,
		-InventoryFrame.Size.X.Offset / 2,
		1,
		HotbarFrame.Position.Y.Offset - InventoryFrame.Size.Y.Offset
	)

	ScrollingFrame.Size = UDim2.new(
		1,
		ScrollingFrame.ScrollBarThickness + 1,
		1,
		-INVENTORY_HEADER_SIZE - (IsVR and 2 * INVENTORY_ARROWS_BUFFER_VR or 0)
	)
	ScrollingFrame.Position = UDim2.fromOffset(0, INVENTORY_HEADER_SIZE + (IsVR and INVENTORY_ARROWS_BUFFER_VR or 0))
	AdjustHotbarFrames()
	AdjustInventoryFrames()
end

local function Clamp(low: number, high: number, num: number): number
	return math.min(high, math.max(low, num))
end

local function CheckBounds(guiObject: GuiObject, x: number, y: number): boolean
	local pos: Vector2 = guiObject.AbsolutePosition
	local size: Vector2 = guiObject.AbsoluteSize
	return (x > pos.X and x <= pos.X + size.X and y > pos.Y and y <= pos.Y + size.Y)
end

local function GetOffset(guiObject: GuiObject, point: Vector2): number
	local centerPoint: Vector2 = guiObject.AbsolutePosition + (guiObject.AbsoluteSize / 2)
	return (centerPoint - point).Magnitude
end

local function DisableActiveHopper(): ()
	ActiveHopper:ToggleSelect()
	SlotsByTool[ActiveHopper]:UpdateEquipView()
	ActiveHopper = nil :: any
end

local function UnequipAllTools(): ()
	if Humanoid then
		Humanoid:UnequipTools()
		if ActiveHopper then
			DisableActiveHopper()
		end
	end
end

local function EquipNewTool(tool: Tool): ()
	UnequipAllTools()
	Humanoid:EquipTool(tool)

end

local function IsEquipped(tool: Tool): boolean
	return tool and tool.Parent == Character
end


local function MakeSlot(parent: Instance, initIndex: number?): GuiObject
	local index: number = initIndex or (#Slots + 1)



	local slot: any = {}
	slot.Tool = nil :: any
	slot.Index = index :: number
	slot.Frame = nil :: any

	local SlotFrame: any = nil
	local SlotScale: UIScale = nil
	local FakeSlotFrame: Frame = nil
	local ToolIcon: ImageLabel = nil
	local ToolName: TextLabel = nil
	local ToolChangeConn: any = nil
	local HighlightFrame: any = nil
	local SelectionObj: ImageLabel = nil


	local ToolTip: TextLabel = nil
	local SlotNumber: TextLabel = nil




	local function UpdateSlotFading(): ()
		SlotFrame.SelectionImageObject = nil
		SlotFrame.BackgroundTransparency = SlotFrame.Draggable and 0 or SLOT_LOCKED_TRANSPARENCY
	end


	function slot:Readjust(visualIndex: number, visualTotal: number): ...any
		local centered: number = HotbarFrame.Size.X.Offset / 2
		local sizePlus: number = ICON_BUFFER_PIXELS + ICON_SIZE_PIXELS
		local midpointish: number = (visualTotal / 2) + 0.5
		local factor: number = visualIndex - midpointish
		SlotFrame.Position =
			UDim2.fromOffset(centered - (ICON_SIZE_PIXELS / 2) + (sizePlus * factor), ICON_BUFFER_PIXELS)
	end


	function slot:Fill(tool: Tool): ...any

		if not tool then
			return self:Clear()
		end

		self.Tool = tool :: Tool


		local function assignToolData(): ()
			local icon: string = tool.TextureId
			ToolIcon.Image = icon

			if icon ~= "" then

				ToolName.Visible = false
			else
				ToolName.Visible = true
			end

			ToolName.Text = tool.Name


			if ToolTip and tool:IsA("Tool") then
				ToolTip.Text = tool.ToolTip
				ToolTip.Size = UDim2.fromOffset(0, TOOLTIP_HEIGHT)
				ToolTip.Position = UDim2.new(0.5, 0, 0, TOOLTIP_OFFSET)
			end
		end
		assignToolData()


		if ToolChangeConn then
			ToolChangeConn:Disconnect()
			ToolChangeConn = nil
		end


		ToolChangeConn = tool.Changed:Connect(function(property: string): ()
			if property == "TextureId" or property == "Name" or property == "ToolTip" then
				assignToolData()
			end
		end)

		local hotbarSlot: boolean = (self.Index <= NumberOfHotbarSlots)
		local inventoryOpen: boolean = InventoryFrame.Visible

		if (not hotbarSlot or inventoryOpen) and not UserInputService.VREnabled then
			SlotFrame.Draggable = true
		end

		self:UpdateEquipView()

		if hotbarSlot then
			FullHotbarSlots = FullHotbarSlots + 1

			if WholeThingEnabled and FullHotbarSlots >= 1 and not GamepadActionsBound then

				GamepadActionsBound = true
				ContextActionService:BindAction(
					"BackpackHotbarEquip",
					changeToolFunc,
					false,
					Enum.KeyCode.ButtonL1,
					Enum.KeyCode.ButtonR1
				)
			end
		end

		SlotsByTool[tool] = self
		LowestEmptySlot = FindLowestEmpty()
		if SlotScale and not BPX.Unloaded then
			SlotScale.Scale = 0.82
			BPX.Tween(SlotScale, BPX.POP_TWEEN, { Scale = 1 })
		end
	end


	function slot:Clear(): ...any
		if not self.Tool then
			return
		end


		if ToolChangeConn then
			ToolChangeConn:Disconnect()
			ToolChangeConn = nil
		end

		ToolIcon.Image = ""
		ToolName.Text = ""
		if ToolTip then
			ToolTip.Text = ""
			ToolTip.Visible = false
		end
		SlotFrame.Draggable = false

		self:UpdateEquipView(true)

		if self.Index <= NumberOfHotbarSlots then
			FullHotbarSlots = FullHotbarSlots - 1
			if FullHotbarSlots < 1 then

				GamepadActionsBound = false
				ContextActionService:UnbindAction("BackpackHotbarEquip")
			end
		end

		SlotsByTool[self.Tool] = nil
		self.Tool = nil
		LowestEmptySlot = FindLowestEmpty()
	end

	function slot:UpdateEquipView(unequippedOverride: boolean?): ...any
		local override = unequippedOverride or false
		if not override and IsEquipped(self.Tool) then
			lastEquippedSlot = slot
			if not HighlightFrame then
				HighlightFrame = Instance.new("UIStroke")
				HighlightFrame.Name = "Border"
				HighlightFrame.Thickness = SLOT_EQUIP_THICKNESS
				HighlightFrame.Color = SLOT_EQUIP_COLOR
				HighlightFrame.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			end
			if LEGACY_EDGE_ENABLED == true then
				HighlightFrame.Parent = ToolIcon
			else
				HighlightFrame.Parent = SlotFrame
			end
		else
			if HighlightFrame then
				HighlightFrame.Parent = nil
			end
		end
		UpdateSlotFading()
	end

	function slot:IsEquipped(): boolean
		return IsEquipped(self.Tool)
	end

	function slot:Delete(): ...any
		SlotFrame:Destroy()
		table.remove(Slots, self.Index)
		local newSize: number = #Slots


		for slotIndex: number = self.Index :: number, newSize :: number do
			Slots[slotIndex]:SlideBack()
		end

		UpdateScrollingFrameCanvasSize()
	end

	function slot:Swap(targetSlot: any): ...any
		local myTool: any, otherTool: any = self.Tool, targetSlot.Tool
		self:Clear()
		if otherTool then
			targetSlot:Clear()
			self:Fill(otherTool)
		end
		if myTool then
			targetSlot:Fill(myTool)
		else
			targetSlot:Clear()
		end
	end

	function slot:SlideBack(): ...any
		self.Index = self.Index - 1
		SlotFrame.Name = self.Index
		SlotFrame.LayoutOrder = self.Index
	end

	function slot:TurnNumber(on: boolean): ...any
		if SlotNumber then
			SlotNumber.Visible = on
		end
	end

	function slot:SetClickability(on: boolean): ...any
		if self.Tool then
			if UserInputService.VREnabled then
				SlotFrame.Draggable = false
			else
				SlotFrame.Draggable = not on
			end
			UpdateSlotFading()
		end
	end

	function slot:CheckTerms(terms: any): number
		local hits: number = 0
		local function checkEm(str: string, term: any): ()
			local _, n: number = str:lower():gsub(term, "")
			hits = hits + n
		end
		local tool: Tool = self.Tool
		if tool then
			for term: any in pairs(terms) do
				checkEm(ToolName.Text, term)
				if tool:IsA("Tool") then
					local toolTipText: string = ToolTip and ToolTip.Text or ""
					checkEm(toolTipText, term)
				end
			end
		end
		return hits
	end


	function slot:Select(): ...any
		local tool: Tool = slot.Tool
		if tool then
			BPX.SelectedTool = tool
			if BPX.MultiMode then
				if tool.Parent == Character then
					tool.Parent = Backpack
				elseif tool.Parent == Backpack then
					tool.Parent = Character
				end
				BPX.UpdateControls()
				return
			end
			if IsEquipped(tool) then
				UnequipAllTools()
			elseif tool.Parent == Backpack then
				EquipNewTool(tool)
			end
			BPX.UpdateControls()
		end
	end



	SlotFrame = Instance.new("TextButton")
	SlotFrame.Name = tostring(index)
	SlotFrame.BackgroundColor3 = BACKGROUND_COLOR
	SlotFrame.BorderColor3 = SLOT_BORDER_COLOR
	SlotFrame.Text = ""
	SlotFrame.BorderSizePixel = 0
	SlotFrame.Size = UDim2.fromOffset(ICON_SIZE_PIXELS, ICON_SIZE_PIXELS)
	SlotFrame.Active = true
	SlotFrame.Draggable = false
	SlotFrame.BackgroundTransparency = SLOT_LOCKED_TRANSPARENCY
	SlotScale = Instance.new("UIScale")
	SlotScale.Scale = 1
	SlotScale.Parent = SlotFrame
	SlotFrame.MouseButton1Click:Connect(function(): ()
		changeSlot(slot)
	end)
	local searchFrameCorner: UICorner = Instance.new("UICorner")
	searchFrameCorner.Name = "Corner"
	searchFrameCorner.CornerRadius = SLOT_CORNER_RADIUS
	searchFrameCorner.Parent = SlotFrame
	slot.Frame = SlotFrame

	do
		local selectionObjectClipper: Frame = Instance.new("Frame")
		selectionObjectClipper.Name = "SelectionObjectClipper"
		selectionObjectClipper.BackgroundTransparency = 1
		selectionObjectClipper.Visible = false
		selectionObjectClipper.Parent = SlotFrame

		SelectionObj = Instance.new("ImageLabel")
		SelectionObj.Name = "Selector"
		SelectionObj.BackgroundTransparency = 1
		SelectionObj.Size = UDim2.fromScale(1, 1)
		SelectionObj.Image = "rbxasset://textures/ui/Keyboard/key_selection_9slice.png"
		SelectionObj.ScaleType = Enum.ScaleType.Slice
		SelectionObj.SliceCenter = Rect.new(12, 12, 52, 52)
		SelectionObj.Parent = selectionObjectClipper
	end

	ToolIcon = Instance.new("ImageLabel")
	ToolIcon.BackgroundTransparency = 1
	ToolIcon.Name = "Icon"
	ToolIcon.Size = UDim2.fromScale(1, 1)
	ToolIcon.Position = UDim2.fromScale(0.5, 0.5)
	ToolIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	if LEGACY_PADDING_ENABLED == true then
		ToolIcon.Size = UDim2.new(1, -SLOT_EQUIP_THICKNESS * 2, 1, -SLOT_EQUIP_THICKNESS * 2)
	else
		ToolIcon.Size = UDim2.fromScale(1, 1)
	end
	ToolIcon.Parent = SlotFrame

	local ToolIconCorner: UICorner = Instance.new("UICorner")
	ToolIconCorner.Name = "Corner"
	if LEGACY_PADDING_ENABLED == true then
		ToolIconCorner.CornerRadius = SLOT_CORNER_RADIUS - UDim.new(0, SLOT_EQUIP_THICKNESS)
	else
		ToolIconCorner.CornerRadius = SLOT_CORNER_RADIUS
	end
	ToolIconCorner.Parent = ToolIcon

	ToolName = Instance.new("TextLabel")
	ToolName.BackgroundTransparency = 1
	ToolName.Name = "ToolName"
	ToolName.Text = ""
	ToolName.TextColor3 = TEXT_COLOR
	ToolName.TextStrokeTransparency = TEXT_STROKE_TRANSPARENCY
	ToolName.TextStrokeColor3 = TEXT_STROKE_COLOR
	ToolName.FontFace = Font.new(FONT_FAMILY.Family, Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	ToolName.TextSize = FONT_SIZE
	ToolName.Size = UDim2.new(1, -SLOT_EQUIP_THICKNESS * 2, 1, -SLOT_EQUIP_THICKNESS * 2)
	ToolName.Position = UDim2.fromScale(0.5, 0.5)
	ToolName.AnchorPoint = Vector2.new(0.5, 0.5)
	ToolName.TextWrapped = true
	ToolName.TextTruncate = Enum.TextTruncate.AtEnd
	ToolName.Parent = SlotFrame

	slot.Frame.LayoutOrder = slot.Index

	if index <= NumberOfHotbarSlots then

		ToolTip = Instance.new("TextLabel")
		ToolTip.Name = "ToolTip"
		ToolTip.Text = ""
		ToolTip.Size = UDim2.fromScale(1, 1)
		ToolTip.TextColor3 = TEXT_COLOR
		ToolTip.TextStrokeTransparency = TEXT_STROKE_TRANSPARENCY
		ToolTip.TextStrokeColor3 = TEXT_STROKE_COLOR
		ToolTip.FontFace = Font.new(FONT_FAMILY.Family, Enum.FontWeight.Medium, Enum.FontStyle.Normal)
		ToolTip.TextSize = FONT_SIZE
		ToolTip.ZIndex = 2
		ToolTip.TextWrapped = false
		ToolTip.TextYAlignment = Enum.TextYAlignment.Center
		ToolTip.BackgroundColor3 = TOOLTIP_BACKGROUND_COLOR
		ToolTip.BackgroundTransparency = SLOT_LOCKED_TRANSPARENCY
		ToolTip.AnchorPoint = Vector2.new(0.5, 1)
		ToolTip.BorderSizePixel = 0
		ToolTip.Visible = false
		ToolTip.AutomaticSize = Enum.AutomaticSize.X
		ToolTip.Parent = SlotFrame

		local ToolTipCorner: UICorner = Instance.new("UICorner")
		ToolTipCorner.Name = "Corner"
		ToolTipCorner.CornerRadius = TOOLTIP_CORNER_RADIUS
		ToolTipCorner.Parent = ToolTip

		local ToolTipPadding: UIPadding = Instance.new("UIPadding")
		ToolTipPadding.PaddingLeft = UDim.new(0, TOOLTIP_PADDING)
		ToolTipPadding.PaddingRight = UDim.new(0, TOOLTIP_PADDING)
		ToolTipPadding.PaddingTop = UDim.new(0, TOOLTIP_PADDING)
		ToolTipPadding.PaddingBottom = UDim.new(0, TOOLTIP_PADDING)
		ToolTipPadding.Parent = ToolTip
		SlotFrame.MouseEnter:Connect(function(): ()
			if ToolTip.Text ~= "" then
				ToolTip.Visible = true
			end
		end)
		SlotFrame.MouseLeave:Connect(function(): ()
			ToolTip.Visible = false
		end)

		function slot:MoveToInventory(): ...any
			if slot.Index <= NumberOfHotbarSlots then
				local tool: any = slot.Tool
				self:Clear()
				local newSlot: any = MakeSlot(UIGridFrame)
				newSlot:Fill(tool)
				if IsEquipped(tool) then
					UnequipAllTools()
				end

				if ViewingSearchResults then
					newSlot.Frame.Visible = false
					newSlot.Parent = InventoryFrame
				end
			end
		end


		if index < 10 or index == NumberOfHotbarSlots then
			local slotNum: number = (index < 10) and index or 0
			SlotNumber = Instance.new("TextLabel")
			SlotNumber.BackgroundTransparency = 1
			SlotNumber.Name = "Number"
			SlotNumber.TextColor3 = TEXT_COLOR
			SlotNumber.TextStrokeTransparency = TEXT_STROKE_TRANSPARENCY
			SlotNumber.TextStrokeColor3 = TEXT_STROKE_COLOR
			SlotNumber.TextSize = FONT_SIZE
			SlotNumber.Text = tostring(slotNum)
			SlotNumber.FontFace = Font.new(FONT_FAMILY.Family, Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
			SlotNumber.Size = UDim2.fromScale(0.4, 0.4)
			SlotNumber.Visible = false
			SlotNumber.Parent = SlotFrame
			HotkeyFns[ZERO_KEY_VALUE + slotNum] = slot.Select
		end
	end

	do
		local startPoint: UDim2 = SlotFrame.Position
		local lastUpTime: number = 0
		local startParent: any = nil

		SlotFrame.DragBegin:Connect(function(dragPoint: UDim2): ()
			Dragging[SlotFrame] = true
			startPoint = dragPoint

			SlotFrame.BorderSizePixel = 2
			inventoryIcon:lock()


			SlotFrame.ZIndex = 2
			ToolIcon.ZIndex = 2
			ToolName.ZIndex = 2
			SlotFrame.Parent.ZIndex = 2
			if SlotNumber then
				SlotNumber.ZIndex = 2
			end








			startParent = SlotFrame.Parent
			if startParent == UIGridFrame then
				local newPosition: UDim2 = UDim2.new(
					0,
					SlotFrame.AbsolutePosition.X - InventoryFrame.AbsolutePosition.X,
					0,
					SlotFrame.AbsolutePosition.Y - InventoryFrame.AbsolutePosition.Y
				)
				SlotFrame.Parent = InventoryFrame
				SlotFrame.Position = newPosition

				FakeSlotFrame = Instance.new("Frame")
				FakeSlotFrame.Name = "FakeSlot"
				FakeSlotFrame.LayoutOrder = SlotFrame.LayoutOrder
				FakeSlotFrame.Size = SlotFrame.Size
				FakeSlotFrame.BackgroundTransparency = 1
				FakeSlotFrame.Parent = UIGridFrame
			end
		end)

		SlotFrame.DragStopped:Connect(function(x: number, y: number): ()
			if FakeSlotFrame then
				FakeSlotFrame:Destroy()
			end

			local now: number = os.clock()

			SlotFrame.Position = startPoint
			SlotFrame.Parent = startParent

			SlotFrame.BorderSizePixel = 0
			inventoryIcon:unlock()


			SlotFrame.ZIndex = 1
			ToolIcon.ZIndex = 1
			ToolName.ZIndex = 1
			startParent.ZIndex = 1

			if SlotNumber then
				SlotNumber.ZIndex = 1
			end







			Dragging[SlotFrame] = nil


			if not slot.Tool then
				return
			end


			if CheckBounds(InventoryFrame, x, y) then
				if slot.Index <= NumberOfHotbarSlots then
					slot:MoveToInventory()
				end

				if slot.Index > NumberOfHotbarSlots and now - lastUpTime < DOUBLE_CLICK_TIME then
					if LowestEmptySlot then
						local myTool: any = slot.Tool
						slot:Clear()
						LowestEmptySlot:Fill(myTool)
						slot:Delete()
					end
					now = 0
				end
			elseif CheckBounds(HotbarFrame, x, y) then
				local closest: { number } = { math.huge, nil :: any }
				for i: number = 1, NumberOfHotbarSlots do
					local otherSlot: any = Slots[i]
					local offset: number = GetOffset(otherSlot.Frame, Vector2.new(x, y))
					if offset < closest[1] then
						closest = { offset, otherSlot }
					end
				end
				local closestSlot: any = closest[2]
				if closestSlot ~= slot then
					slot:Swap(closestSlot)
					if slot.Index > NumberOfHotbarSlots then
						local tool: Tool = slot.Tool
						if not tool then
							slot:Delete()
						else
							if IsEquipped(tool) then
								UnequipAllTools()
							end

							if ViewingSearchResults then
								slot.Frame.Visible = false
								slot.Frame.Parent = InventoryFrame
							end
						end
					end
				end
			else





				if slot.Index <= NumberOfHotbarSlots then
					slot:MoveToInventory()
				end
			end

			lastUpTime = now
		end)
	end


	SlotFrame.Parent = parent
	Slots[index] = slot

	if index > NumberOfHotbarSlots then
		UpdateScrollingFrameCanvasSize()

		if InventoryFrame.Visible and not ViewingSearchResults then
			local offset: number = ScrollingFrame.CanvasSize.Y.Offset - ScrollingFrame.AbsoluteSize.Y
			ScrollingFrame.CanvasPosition = Vector2.new(0, math.max(0, offset))
		end
	end

	return slot
end

local function OnChildAdded(child: Instance): ()
	if not child:IsA("Tool") and not child:IsA("HopperBin") then
		if child:IsA("Humanoid") and child.Parent == Character then
			Humanoid = child
		end
		return
	end
	local tool: any = child

	if tool.Parent == Character then
		ShowVRBackpackPopup()
	end

	if ActiveHopper and tool.Parent == Character then
		DisableActiveHopper()
	end


	if not StarterToolFound and tool.Parent == Character and not SlotsByTool[tool] then
		local starterGear: Instance? = Player:FindFirstChild("StarterGear")
		if starterGear then
			if starterGear:FindFirstChild(tool.Name) then
				StarterToolFound = true
				local slot: any = LowestEmptySlot or MakeSlot(UIGridFrame)
				for i: number = slot.Index, 1, -1 do
					local curr = Slots[i]
					local pIndex: number = i - 1
					if pIndex > 0 then
						local prev = Slots[pIndex]
						prev:Swap(curr)
					else
						curr:Fill(tool)
					end
				end

				for _, children: Instance in pairs(Character:GetChildren()) do
					if children:IsA("Tool") and children ~= tool then
						children.Parent = Backpack
					end
				end
				AdjustHotbarFrames()
				return
			end
		end
	end


	local slot: any = SlotsByTool[tool]
	if slot then
		slot:UpdateEquipView()
	else
		slot = LowestEmptySlot or MakeSlot(UIGridFrame)
		slot:Fill(tool)
		if slot.Index <= NumberOfHotbarSlots and not InventoryFrame.Visible then
			AdjustHotbarFrames()
		end
		if tool:IsA("HopperBin") then
			if tool.Active then
				UnequipAllTools()
				ActiveHopper = tool
			end
		end
	end

	BackpackScript.BackpackItemAdded:Fire()
end

local function OnChildRemoved(child: Instance): ()
	if not child:IsA("Tool") and not child:IsA("HopperBin") then
		return
	end
	local tool: Tool | any = child

	ShowVRBackpackPopup()


	local newParent: any = tool.Parent
	if newParent == Character or newParent == Backpack then
		return
	end

	local slot: any = SlotsByTool[tool]
	if slot then
		slot:Clear()
		if slot.Index > NumberOfHotbarSlots then
			slot:Delete()
		elseif not InventoryFrame.Visible then
			AdjustHotbarFrames()
		end
	end

	if tool :: any == ActiveHopper then
		ActiveHopper = nil :: any
	end

	BackpackScript.BackpackItemRemoved:Fire()
	if isInventoryEmpty() then
		BackpackScript.BackpackEmpty:Fire()
	end
end

local function OnCharacterAdded(character: Model): ()

	for i: number = #Slots, 1, -1 do
		local slot = Slots[i]
		if slot.Tool then
			slot:Clear()
		end
		if i > NumberOfHotbarSlots then
			slot:Delete()
		end
	end
	ActiveHopper = nil :: any


	for _, conn: RBXScriptConnection in pairs(CharConns) do
		conn:Disconnect()
	end
	CharConns = {}


	Character = character
	table.insert(CharConns, character.ChildRemoved:Connect(OnChildRemoved))
	table.insert(CharConns, character.ChildAdded:Connect(OnChildAdded))
	for _, child: Instance in pairs(character:GetChildren()) do
		OnChildAdded(child)
	end



	Backpack = Player:WaitForChild("Backpack")
	table.insert(CharConns, Backpack.ChildRemoved:Connect(OnChildRemoved))
	table.insert(CharConns, Backpack.ChildAdded:Connect(OnChildAdded))
	for _, child: Instance in pairs(Backpack:GetChildren()) do
		OnChildAdded(child)
	end

	AdjustHotbarFrames()
end

local function OnInputBegan(input: InputObject, isProcessed: boolean): ()
	local ChatInputBarConfiguration =
		TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration") :: ChatInputBarConfiguration

	if
		input.UserInputType == Enum.UserInputType.Keyboard
		and not TextBoxFocused
		and not ChatInputBarConfiguration.IsFocused
		and (WholeThingEnabled or input.KeyCode.Value == DROP_HOTKEY_VALUE)
	then
		local hotkeyBehavior: any = HotkeyFns[input.KeyCode.Value]
		if hotkeyBehavior then
			hotkeyBehavior(isProcessed)
		end
	end

	local inputType: Enum.UserInputType = input.UserInputType
	if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
		if BackpackScript.IsOpen and not BPX.Unloaded and not BPX.Confirm.Visible then
			local position = input.Position
			local x, y = position.X, position.Y
			local insideBackpack = CheckBounds(InventoryFrame, x, y)
				or CheckBounds(HotbarFrame, x, y)
				or (BPX.Controls.Visible and CheckBounds(BPX.Controls, x, y))
				or (BPX.MiniButton.Visible and CheckBounds(BPX.MiniButton, x, y))
			if not insideBackpack and BackpackScript.OpenClose then
				BackpackScript.OpenClose()
			end
		end
	end
end

local function OnUISChanged(): ()

	if UserInputService:GetLastInputType() == Enum.UserInputType.Touch then
		for i: number = 1, NumberOfHotbarSlots do
			Slots[i]:TurnNumber(false)
		end
		return
	end


	if UserInputService:GetLastInputType() == Enum.UserInputType.Keyboard then
		for i: number = 1, NumberOfHotbarSlots do
			Slots[i]:TurnNumber(true)
		end
		return
	end


	for _, mouse: any in pairs(MOUSE_INPUT_TYPES) do
		if UserInputService:GetLastInputType() == mouse then
			for i: number = 1, NumberOfHotbarSlots do
				Slots[i]:TurnNumber(true)
			end
			return
		end
	end


	for _, gamepad: any in pairs(GAMEPAD_INPUT_TYPES) do
		if UserInputService:GetLastInputType() == gamepad then
			for i: number = 1, NumberOfHotbarSlots do
				Slots[i]:TurnNumber(false)
			end
			return
		end
	end
end

local lastChangeToolInputObject: InputObject = nil
local lastChangeToolInputTime: number = nil
local maxEquipDeltaTime: number = 0.06
local noOpFunc = function() end


function unbindAllGamepadEquipActions(): ()
	ContextActionService:UnbindAction("BackpackHasGamepadFocus")
	ContextActionService:UnbindAction("BackpackCloseInventory")
end








































































changeToolFunc = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): ()
	if inputState ~= Enum.UserInputState.Begin then
		return
	end

	if lastChangeToolInputObject then
		if
			(
				lastChangeToolInputObject.KeyCode == Enum.KeyCode.ButtonR1
				and inputObject.KeyCode == Enum.KeyCode.ButtonL1
			)
			or (
				lastChangeToolInputObject.KeyCode == Enum.KeyCode.ButtonL1
				and inputObject.KeyCode == Enum.KeyCode.ButtonR1
			)
		then
			if (os.clock() - lastChangeToolInputTime) <= maxEquipDeltaTime then
				UnequipAllTools()
				lastChangeToolInputObject = inputObject
				lastChangeToolInputTime = os.clock()
				return
			end
		end
	end

	lastChangeToolInputObject = inputObject
	lastChangeToolInputTime = os.clock()

	task.delay(maxEquipDeltaTime, function(): ()
		if lastChangeToolInputObject ~= inputObject then
			return
		end

		local moveDirection: number = 0
		if inputObject.KeyCode == Enum.KeyCode.ButtonL1 then
			moveDirection = -1
		else
			moveDirection = 1
		end

		for i: number = 1, NumberOfHotbarSlots do
			local hotbarSlot: any = Slots[i]
			if hotbarSlot:IsEquipped() then
				local newSlotPosition: number = moveDirection + i
				local hitEdge: boolean = false
				if newSlotPosition > NumberOfHotbarSlots then
					newSlotPosition = 1
					hitEdge = true
				elseif newSlotPosition < 1 then
					newSlotPosition = NumberOfHotbarSlots
					hitEdge = true
				end

				local origNewSlotPos: number = newSlotPosition
				while not Slots[newSlotPosition].Tool do
					newSlotPosition = newSlotPosition + moveDirection
					if newSlotPosition == origNewSlotPos then
						return
					end

					if newSlotPosition > NumberOfHotbarSlots then
						newSlotPosition = 1
						hitEdge = true
					elseif newSlotPosition < 1 then
						newSlotPosition = NumberOfHotbarSlots
						hitEdge = true
					end
				end

				if hitEdge then
					UnequipAllTools()
					lastEquippedSlot = nil
				else
					Slots[newSlotPosition]:Select()
				end
				return
			end
		end

		if lastEquippedSlot and lastEquippedSlot.Tool then
			lastEquippedSlot:Select()
			return
		end

		local startIndex: number = moveDirection == -1 and NumberOfHotbarSlots or 1
		local endIndex: number = moveDirection == -1 and 1 or NumberOfHotbarSlots
		for i: number = startIndex, endIndex, moveDirection do
			if Slots[i].Tool then
				Slots[i]:Select()
				return
			end
		end
	end)
end

function getGamepadSwapSlot(): any
	for i: number = 1, #Slots do
		if Slots[i].Frame.BorderSizePixel > 0 then
			return Slots[i]
		end
	end
	return
end


function changeSlot(slot: any): ()
	local swapInVr: boolean = not VRService.VREnabled or InventoryFrame.Visible

	if slot.Frame == GuiService.SelectedObject and swapInVr then
		local currentlySelectedSlot: any = getGamepadSwapSlot()

		if currentlySelectedSlot then
			currentlySelectedSlot.Frame.BorderSizePixel = 0
			if currentlySelectedSlot ~= slot then
				slot:Swap(currentlySelectedSlot)
				VRInventorySelector.SelectionImageObject.Visible = false

				if slot.Index > NumberOfHotbarSlots and not slot.Tool then
					if GuiService.SelectedObject == slot.Frame then
						GuiService.SelectedObject = currentlySelectedSlot.Frame
					end
					slot:Delete()
				end

				if currentlySelectedSlot.Index > NumberOfHotbarSlots and not currentlySelectedSlot.Tool then
					if GuiService.SelectedObject == currentlySelectedSlot.Frame then
						GuiService.SelectedObject = slot.Frame
					end
					currentlySelectedSlot:Delete()
				end
			end
		else
			local startSize: UDim2 = slot.Frame.Size
			local startPosition: UDim2 = slot.Frame.Position
			slot.Frame:TweenSizeAndPosition(
				startSize + UDim2.fromOffset(10, 10),
				startPosition - UDim2.fromOffset(5, 5),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.1,
				true,
				function(): ()
					slot.Frame:TweenSizeAndPosition(
						startSize,
						startPosition,
						Enum.EasingDirection.In,
						Enum.EasingStyle.Quad,
						0.1,
						true
					)
				end
			)
			slot.Frame.BorderSizePixel = 3
			VRInventorySelector.SelectionImageObject.Visible = true
		end
	else
		slot:Select()
		VRInventorySelector.SelectionImageObject.Visible = false
	end
end

function vrMoveSlotToInventory(): ()
	if not VRService.VREnabled then
		return
	end

	local currentlySelectedSlot: any = getGamepadSwapSlot()
	if currentlySelectedSlot and currentlySelectedSlot.Tool then
		currentlySelectedSlot.Frame.BorderSizePixel = 0
		currentlySelectedSlot:MoveToInventory()
		VRInventorySelector.SelectionImageObject.Visible = false
	end
end

function enableGamepadInventoryControl(): ()
	local goBackOneLevel = function(): ()




		local selectedSlot: any = getGamepadSwapSlot()
		if selectedSlot then

			local selectedSlot: any = getGamepadSwapSlot()
			if selectedSlot then
				selectedSlot.Frame.BorderSizePixel = 0
				return
			end
		elseif InventoryFrame.Visible then
			inventoryIcon:deselect()
		end
	end

	ContextActionService:BindAction("BackpackHasGamepadFocus", noOpFunc, false, Enum.UserInputType.Gamepad1)
	ContextActionService:BindAction(
		"BackpackCloseInventory",
		goBackOneLevel,
		false,
		Enum.KeyCode.ButtonB,
		Enum.KeyCode.ButtonStart
	)


	if not UseGazeSelection() then
		GuiService.SelectedObject = HotbarFrame:FindFirstChild("1")
	end
end

function disableGamepadInventoryControl(): ()
	unbindAllGamepadEquipActions()

	for i: number = 1, NumberOfHotbarSlots do
		local hotbarSlot: any = Slots[i]
		if hotbarSlot and hotbarSlot.Frame then
			hotbarSlot.Frame.BorderSizePixel = 0
		end
	end

	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(MainFrame) then
		GuiService.SelectedObject = nil
	end
end

local function bindBackpackHotbarAction(): ()
	if WholeThingEnabled and not GamepadActionsBound then
		GamepadActionsBound = true
		ContextActionService:BindAction(
			"BackpackHotbarEquip",
			changeToolFunc,
			false,
			Enum.KeyCode.ButtonL1,
			Enum.KeyCode.ButtonR1
		)
	end
end

local function unbindBackpackHotbarAction(): ()
	disableGamepadInventoryControl()
	GamepadActionsBound = false
	ContextActionService:UnbindAction("BackpackHotbarEquip")
end

function gamepadDisconnected(): ()
	GamepadEnabled = false
	disableGamepadInventoryControl()
end

function gamepadConnected(): ()
	GamepadEnabled = true
	GuiService:AddSelectionParent("BackpackSelection", MainFrame)

	if FullHotbarSlots >= 1 then
		bindBackpackHotbarAction()
	end

	if InventoryFrame.Visible then
		enableGamepadInventoryControl()
	end
end

local function OnIconChanged(enabled: boolean): ()

	local success, _topbarEnabled = pcall(function()
		return enabled and StarterGui:GetCore("TopbarEnabled")
	end)

	if not success then
		return
	end

	WholeThingEnabled = enabled
	MainFrame.Visible = enabled










	if enabled then
		if FullHotbarSlots >= 1 then
			bindBackpackHotbarAction()
		end
	else
		unbindBackpackHotbarAction()
	end
end

local function MakeVRRoundButton(name: string, image: string): (ImageButton, ImageLabel, ImageLabel)
	local newButton: ImageButton = Instance.new("ImageButton")
	newButton.BackgroundTransparency = 1
	newButton.Name = name
	newButton.Size = UDim2.fromOffset(40, 40)
	newButton.Image = "rbxasset://textures/ui/Keyboard/close_button_background.png"

	local buttonIcon: ImageLabel = Instance.new("ImageLabel")
	buttonIcon.Name = "Icon"
	buttonIcon.BackgroundTransparency = 1
	buttonIcon.Size = UDim2.fromScale(0.5, 0.5)
	buttonIcon.Position = UDim2.fromScale(0.25, 0.25)
	buttonIcon.Image = image
	buttonIcon.Parent = newButton

	local buttonSelectionObject: ImageLabel = Instance.new("ImageLabel")
	buttonSelectionObject.BackgroundTransparency = 1
	buttonSelectionObject.Name = "Selection"
	buttonSelectionObject.Size = UDim2.fromScale(0.9, 0.9)
	buttonSelectionObject.Position = UDim2.fromScale(0.05, 0.05)
	buttonSelectionObject.Image = "rbxasset://textures/ui/Keyboard/close_button_selection.png"
	newButton.SelectionImageObject = buttonSelectionObject

	return newButton, buttonIcon, buttonSelectionObject
end


MainFrame = Instance.new("Frame")
MainFrame.BackgroundTransparency = 1
MainFrame.Name = "Backpack"
MainFrame.Size = UDim2.fromScale(1, 1)
MainFrame.Visible = false
MainFrame.Parent = BackpackGui


HotbarFrame = Instance.new("Frame")
HotbarFrame.BackgroundTransparency = 1
HotbarFrame.Name = "Hotbar"
HotbarFrame.Size = UDim2.fromScale(1, 1)
HotbarFrame.Parent = MainFrame


for index: number = 1, NumberOfHotbarSlots do
	local slot: any = MakeSlot(HotbarFrame, index)
	slot.Frame.Visible = false

	if not LowestEmptySlot then
		LowestEmptySlot = slot
	end
end

local LeftBumperButton: ImageLabel = Instance.new("ImageLabel")
LeftBumperButton.BackgroundTransparency = 1
LeftBumperButton.Name = "LeftBumper"
LeftBumperButton.Size = UDim2.fromOffset(40, 40)
LeftBumperButton.Position = UDim2.new(0, -LeftBumperButton.Size.X.Offset, 0.5, -LeftBumperButton.Size.Y.Offset / 2)

local RightBumperButton: ImageLabel = Instance.new("ImageLabel")
RightBumperButton.BackgroundTransparency = 1
RightBumperButton.Name = "RightBumper"
RightBumperButton.Size = UDim2.fromOffset(40, 40)
RightBumperButton.Position = UDim2.new(1, 0, 0.5, -RightBumperButton.Size.Y.Offset / 2)


InventoryFrame = Instance.new("Frame")
InventoryFrame.Name = "Inventory"
InventoryFrame.Size = UDim2.fromScale(1, 1)
InventoryFrame.BackgroundTransparency = BACKGROUND_TRANSPARENCY
InventoryFrame.BackgroundColor3 = BACKGROUND_COLOR
InventoryFrame.Active = true
InventoryFrame.Visible = false
InventoryFrame.Parent = MainFrame


local corner: UICorner = Instance.new("UICorner")
corner.Name = "Corner"
corner.CornerRadius = BACKGROUND_CORNER_RADIUS
corner.Parent = InventoryFrame

VRInventorySelector = Instance.new("TextButton")
VRInventorySelector.Name = "VRInventorySelector"
VRInventorySelector.Position = UDim2.new(0, 0, 0, 0)
VRInventorySelector.Size = UDim2.fromScale(1, 1)
VRInventorySelector.BackgroundTransparency = 1
VRInventorySelector.Text = ""
VRInventorySelector.Parent = InventoryFrame

local selectorImage: ImageLabel = Instance.new("ImageLabel")
selectorImage.BackgroundTransparency = 1
selectorImage.Name = "Selector"
selectorImage.Size = UDim2.fromScale(1, 1)
selectorImage.Image = "rbxasset://textures/ui/Keyboard/key_selection_9slice.png"
selectorImage.ScaleType = Enum.ScaleType.Slice
selectorImage.SliceCenter = Rect.new(12, 12, 52, 52)
selectorImage.Visible = false
VRInventorySelector.SelectionImageObject = selectorImage

VRInventorySelector.MouseButton1Click:Connect(function(): ()
	vrMoveSlotToInventory()
end)


ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.Name = "ScrollingFrame"
ScrollingFrame.Size = UDim2.fromScale(1, 1)
ScrollingFrame.Selectable = false
ScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.ScrollBarThickness = 8
ScrollingFrame.ScrollBarImageColor3 = Color3.new(1, 1, 1)
ScrollingFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.Parent = InventoryFrame

UIGridFrame = Instance.new("Frame")
UIGridFrame.BackgroundTransparency = 1
UIGridFrame.Name = "UIGridFrame"
UIGridFrame.Selectable = false
UIGridFrame.Size = UDim2.new(1, -(ICON_BUFFER_PIXELS * 2), 1, 0)
UIGridFrame.Position = UDim2.fromOffset(ICON_BUFFER_PIXELS, 0)
UIGridFrame.Parent = ScrollingFrame

UIGridLayout = Instance.new("UIGridLayout")
UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIGridLayout.CellSize = UDim2.fromOffset(ICON_SIZE_PIXELS, ICON_SIZE_PIXELS)
UIGridLayout.CellPadding = UDim2.fromOffset(ICON_BUFFER_PIXELS, ICON_BUFFER_PIXELS)
UIGridLayout.Parent = UIGridFrame

ScrollUpInventoryButton = MakeVRRoundButton("ScrollUpButton", "rbxasset://textures/ui/Backpack/ScrollUpArrow.png")
ScrollUpInventoryButton.Size = UDim2.fromOffset(34, 34)
ScrollUpInventoryButton.Position =
	UDim2.new(0.5, -ScrollUpInventoryButton.Size.X.Offset / 2, 0, INVENTORY_HEADER_SIZE + 3)
ScrollUpInventoryButton.Icon.Position = ScrollUpInventoryButton.Icon.Position - UDim2.fromOffset(0, 2)
ScrollUpInventoryButton.MouseButton1Click:Connect(function(): ()
	ScrollingFrame.CanvasPosition = Vector2.new(
		ScrollingFrame.CanvasPosition.X,
		Clamp(
			0,
			ScrollingFrame.CanvasSize.Y.Offset - ScrollingFrame.AbsoluteWindowSize.Y,
			ScrollingFrame.CanvasPosition.Y - (ICON_BUFFER_PIXELS + ICON_SIZE_PIXELS)
		)
	)
end)

ScrollDownInventoryButton = MakeVRRoundButton("ScrollDownButton", "rbxasset://textures/ui/Backpack/ScrollUpArrow.png")
ScrollDownInventoryButton.Rotation = 180
ScrollDownInventoryButton.Icon.Position = ScrollDownInventoryButton.Icon.Position - UDim2.fromOffset(0, 2)
ScrollDownInventoryButton.Size = UDim2.fromOffset(34, 34)
ScrollDownInventoryButton.Position =
	UDim2.new(0.5, -ScrollDownInventoryButton.Size.X.Offset / 2, 1, -ScrollDownInventoryButton.Size.Y.Offset - 3)
ScrollDownInventoryButton.MouseButton1Click:Connect(function(): ()
	ScrollingFrame.CanvasPosition = Vector2.new(
		ScrollingFrame.CanvasPosition.X,
		Clamp(
			0,
			ScrollingFrame.CanvasSize.Y.Offset - ScrollingFrame.AbsoluteWindowSize.Y,
			ScrollingFrame.CanvasPosition.Y + (ICON_BUFFER_PIXELS + ICON_SIZE_PIXELS)
		)
	)
end)

ScrollingFrame.Changed:Connect(function(prop: string): ()
	if prop == "AbsoluteWindowSize" or prop == "CanvasPosition" or prop == "CanvasSize" then
		local canScrollUp: boolean = ScrollingFrame.CanvasPosition.Y ~= 0
		local canScrollDown: boolean = ScrollingFrame.CanvasPosition.Y
			< ScrollingFrame.CanvasSize.Y.Offset - ScrollingFrame.AbsoluteWindowSize.Y

		ScrollUpInventoryButton.Visible = canScrollUp
		ScrollDownInventoryButton.Visible = canScrollDown
	end
end)


UpdateBackpackLayout()


BPX.CONTROL_HEIGHT = 38
BPX.Controls = Instance.new("Frame")
BPX.Controls.Name = "BPXControls"
BPX.Controls.AnchorPoint = Vector2.new(0.5, 1)
BPX.Controls.AutomaticSize = Enum.AutomaticSize.X
BPX.Controls.Size = UDim2.fromOffset(0, BPX.CONTROL_HEIGHT)
BPX.Controls.Position = UDim2.new(0.5, 0, 1, HotbarFrame.Position.Y.Offset - 6)
BPX.Controls.BackgroundColor3 = BACKGROUND_COLOR
BPX.Controls.BackgroundTransparency = BACKGROUND_TRANSPARENCY
BPX.Controls.BorderSizePixel = 0
BPX.Controls.ZIndex = 20
BPX.Controls.Parent = MainFrame
BPX.ControlsScale = Instance.new("UIScale")
BPX.ControlsScale.Scale = 1
BPX.ControlsScale.Parent = BPX.Controls

BPX.ControlsCorner = Instance.new("UICorner")
BPX.ControlsCorner.CornerRadius = BACKGROUND_CORNER_RADIUS
BPX.ControlsCorner.Parent = BPX.Controls

BPX.ControlsPadding = Instance.new("UIPadding")
BPX.ControlsPadding.PaddingLeft = UDim.new(0, 4)
BPX.ControlsPadding.PaddingRight = UDim.new(0, 4)
BPX.ControlsPadding.PaddingTop = UDim.new(0, 4)
BPX.ControlsPadding.PaddingBottom = UDim.new(0, 4)
BPX.ControlsPadding.Parent = BPX.Controls

BPX.ControlsLayout = Instance.new("UIListLayout")
BPX.ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
BPX.ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
BPX.ControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
BPX.ControlsLayout.Padding = UDim.new(0, 5)
BPX.ControlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
BPX.ControlsLayout.Parent = BPX.Controls

function BPX.MakeButton(name: string, text: string, width: number): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.fromOffset(width, 30)
	button.BackgroundColor3 = Color3.new(42 / 255, 42 / 255, 46 / 255)
	button.BackgroundTransparency = 0.1
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = TEXT_COLOR
	button.TextSize = 13
	button.FontFace = Font.new(FONT_FAMILY.Family, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	button.ZIndex = 21
	button.Parent = BPX.Controls
	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = button
	button.MouseButton1Down:Connect(function()
		BPX.Tween(scale, BPX.PRESS_IN_TWEEN, { Scale = 0.94 })
	end)
	button.MouseButton1Up:Connect(function()
		BPX.Tween(scale, BPX.PRESS_OUT_TWEEN, { Scale = 1 })
	end)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 7)
	c.Parent = button
	return button
end

BPX.MultiButton = BPX.MakeButton("Multi", "Multi", 48)
BPX.OpenButton = BPX.MakeButton("Open", "Open", 48)
BPX.DropButton = BPX.MakeButton("Drop", "Drop(0)", 62)
BPX.FavoriteButton = BPX.MakeButton("Favorite", "☆", 34)
BPX.LockButton = BPX.MakeButton("Lock", "Lock", 44)
BPX.UnloadButton = BPX.MakeButton("Unload", "Unload", 54)
BPX.CollapseButton = BPX.MakeButton("Collapse", "–", 32)
BPX.DropButton.BackgroundColor3 = Color3.new(205 / 255, 60 / 255, 60 / 255)

BPX.MiniButton = Instance.new("TextButton")
BPX.MiniButton.Name = "BPXMini"
BPX.MiniButton.AnchorPoint = Vector2.new(0.5, 1)
BPX.MiniButton.Position = UDim2.new(0.5, 0, 1, -ICON_BUFFER_PIXELS)
BPX.MiniButton.Size = UDim2.fromOffset(72, 34)
BPX.MiniButton.BackgroundColor3 = BACKGROUND_COLOR
BPX.MiniButton.BackgroundTransparency = 0.08
BPX.MiniButton.BorderSizePixel = 0
BPX.MiniButton.Text = "Open"
BPX.MiniButton.TextColor3 = TEXT_COLOR
BPX.MiniButton.TextSize = 14
BPX.MiniButton.FontFace = Font.new(FONT_FAMILY.Family, Enum.FontWeight.Bold, Enum.FontStyle.Normal)
BPX.MiniButton.Visible = false
BPX.MiniButton.ZIndex = 25
BPX.MiniButton.Parent = MainFrame
BPX.MiniCorner = Instance.new("UICorner")
BPX.MiniCorner.CornerRadius = BACKGROUND_CORNER_RADIUS
BPX.MiniCorner.Parent = BPX.MiniButton


InventoryFrame.Position = InventoryFrame.Position - UDim2.fromOffset(0, BPX.CONTROL_HEIGHT + 10)
BPX.InventoryRestPosition = InventoryFrame.Position
function BPX.AnimateInventory(open: boolean): ()
	BPX.InventoryAnimationId += 1
	local animationId = BPX.InventoryAnimationId
	local restPosition = BPX.InventoryRestPosition or InventoryFrame.Position
	local hiddenPosition = restPosition + UDim2.fromOffset(0, 18)
	if open then
		local wasVisible = InventoryFrame.Visible
		InventoryFrame.Visible = true
		if not wasVisible then
			InventoryFrame.Position = hiddenPosition
		end
		BPX.Tween(InventoryFrame, BPX.OPEN_TWEEN, { Position = restPosition })
		return
	end
	local tween = BPX.Tween(InventoryFrame, BPX.CLOSE_TWEEN, { Position = hiddenPosition })
	local function finish(): ()
		if animationId ~= BPX.InventoryAnimationId or BPX.Unloaded or BackpackScript.IsOpen then
			return
		end
		InventoryFrame.Visible = false
		InventoryFrame.Position = restPosition
		AdjustHotbarFrames()
	end
	if tween then
		tween.Completed:Once(finish)
	else
		finish()
	end
end

BPX.Confirm = Instance.new("Frame")
BPX.Confirm.Name = "BPXDropConfirm"
BPX.Confirm.AnchorPoint = Vector2.new(0.5, 0.5)
BPX.Confirm.Position = UDim2.fromScale(0.5, 0.5)
BPX.Confirm.Size = UDim2.fromOffset(300, 78)
BPX.Confirm.BackgroundColor3 = BACKGROUND_COLOR
BPX.Confirm.BackgroundTransparency = 0.05
BPX.Confirm.BorderSizePixel = 0
BPX.Confirm.Visible = false
BPX.Confirm.ZIndex = 100
BPX.Confirm.Parent = MainFrame
BPX.ConfirmCorner = Instance.new("UICorner")
BPX.ConfirmCorner.CornerRadius = BACKGROUND_CORNER_RADIUS
BPX.ConfirmCorner.Parent = BPX.Confirm
BPX.ConfirmText = Instance.new("TextLabel")
BPX.ConfirmText.BackgroundTransparency = 1
BPX.ConfirmText.Position = UDim2.fromOffset(12, 10)
BPX.ConfirmText.Size = UDim2.new(1, -144, 1, -20)
BPX.ConfirmText.Text = "Drop all unlocked tools?"
BPX.ConfirmText.TextColor3 = TEXT_COLOR
BPX.ConfirmText.TextWrapped = true
BPX.ConfirmText.TextSize = 15
BPX.ConfirmText.FontFace = Font.new(FONT_FAMILY.Family, Enum.FontWeight.Medium, Enum.FontStyle.Normal)
BPX.ConfirmText.ZIndex = 101
BPX.ConfirmText.Parent = BPX.Confirm
BPX.ConfirmYes = BPX.MakeButton("DropYes", "Yes", 56)
BPX.ConfirmYes.Parent = BPX.Confirm
BPX.ConfirmYes.Position = UDim2.new(1, -126, 0.5, -15)
BPX.ConfirmYes.BackgroundColor3 = Color3.new(205 / 255, 60 / 255, 60 / 255)
BPX.ConfirmYes.ZIndex = 101
BPX.ConfirmNo = BPX.MakeButton("DropNo", "No", 54)
BPX.ConfirmNo.Parent = BPX.Confirm
BPX.ConfirmNo.Position = UDim2.new(1, -64, 0.5, -15)
BPX.ConfirmNo.ZIndex = 101

function BPX.CountDroppable(): number
	local count = 0
	for _, slot in ipairs(Slots) do
		local tool = slot.Tool
		if tool and tool:IsA("Tool") and tool.CanBeDropped and not tool:GetAttribute("BP_Lock") then
			count += 1
		end
	end
	return count
end

function BPX.HasAnyTool(): boolean
	for _, slot in ipairs(Slots) do
		if slot.Tool then
			return true
		end
	end
	return false
end

BPX.UpdateControls = function(): ()
	local selected = BPX.SelectedTool
	local valid = selected ~= nil and SlotsByTool[selected] ~= nil
	local hasTools = BPX.HasAnyTool()
	BPX.MultiButton.BackgroundColor3 = BPX.MultiMode and SLOT_EQUIP_COLOR or Color3.new(42 / 255, 42 / 255, 46 / 255)
	BPX.OpenButton.Text = BackpackScript.IsOpen and "Close" or "Open"
	BPX.DropButton.Text = "Drop(" .. tostring(BPX.CountDroppable()) .. ")"
	BPX.FavoriteButton.Text = valid and selected:GetAttribute("BP_Fav") and "★" or "☆"
	BPX.LockButton.Text = valid and selected:GetAttribute("BP_Lock") and "Unlock" or "Lock"
	BPX.FavoriteButton.TextTransparency = valid and 0 or 0.55
	BPX.LockButton.TextTransparency = valid and 0 or 0.55
	local showControls = not BPX.Unloaded and hasTools and not BPX.Collapsed
	local showTouchOpen = not BPX.Unloaded and IS_PHONE and not hasTools
	BPX.Controls.Visible = showControls
	HotbarFrame.Visible = not BPX.Unloaded and not BPX.Collapsed and (hasTools or BackpackScript.IsOpen)
	BPX.MiniButton.Visible = (not BPX.Unloaded and hasTools and BPX.Collapsed) or showTouchOpen
	BPX.MiniButton.Text = BackpackScript.IsOpen and "Close" or "Open"
	if showTouchOpen then
		BPX.MiniButton.Position = UDim2.new(0.5, 0, 1, HotbarFrame.Position.Y.Offset - 6)
	else
		BPX.MiniButton.Position = UDim2.new(0.5, 0, 1, -ICON_BUFFER_PIXELS)
	end
	if showControls and not BPX.ControlsWasVisible then
		BPX.ControlsScale.Scale = 0.9
		BPX.Tween(BPX.ControlsScale, BPX.CONTROL_TWEEN, { Scale = 1 })
	end
	BPX.ControlsWasVisible = showControls
end

function BPX.Unload(): boolean
	if BPX.Unloaded then
		return true
	end
	BPX.Unloaded = true
	BPX.Collapsed = false
	BPX.InventoryAnimationId += 1
	BackpackScript.IsOpen = false
	BackpackEnabled = false
	for instance, tween in pairs(BPX.ActiveTweens) do
		pcall(function()
			tween:Cancel()
		end)
		BPX.ActiveTweens[instance] = nil
	end
	pcall(function()
		inventoryIcon:setEnabled(false)
	end)
	pcall(function()
		ContextActionService:UnbindAction("BackpackHotbarEquip")
		ContextActionService:UnbindAction("BackpackHasGamepadFocus")
		ContextActionService:UnbindAction("BackpackCloseInventory")
		ContextActionService:UnbindAction("BackpackRemoveSlot")
	end)
	pcall(function()
		GuiService:RemoveSelectionGroup("BackpackSelection")
	end)
	for i = #BPX.RuntimeConnections, 1, -1 do
		local connection = BPX.RuntimeConnections[i]
		if connection then
			pcall(connection.Disconnect, connection)
		end
		BPX.RuntimeConnections[i] = nil
	end
	for i = #CharConns, 1, -1 do
		local connection = CharConns[i]
		if connection then
			pcall(connection.Disconnect, connection)
		end
		CharConns[i] = nil
	end
	for _, slot in ipairs(Slots) do
		if slot.Tool then
			pcall(slot.Clear, slot)
		end
	end
	pcall(function()
		BackpackScript.StateChanged:Destroy()
		BackpackScript.BackpackEmpty:Destroy()
		BackpackScript.BackpackItemAdded:Destroy()
		BackpackScript.BackpackItemRemoved:Destroy()
	end)
	BackpackScript.OpenClose = nil
	pcall(function()
		BackpackGui:Destroy()
	end)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end)
	local env = (getgenv and getgenv()) or _G
	if type(env) == "table" then
		env.BPX = false
		env.__NA_MobileBackpackUnload = nil
	end
	return true
end

do
	local env = (getgenv and getgenv()) or _G
	if type(env) == "table" then
		env.__NA_MobileBackpackUnload = BPX.Unload
	end
end

BPX.MultiButton.MouseButton1Click:Connect(function(): ()
	BPX.MultiMode = not BPX.MultiMode
	BPX.UpdateControls()
end)

BPX.OpenButton.MouseButton1Click:Connect(function(): ()
	if BackpackScript.OpenClose then
		BackpackScript.OpenClose()
	end
end)

BPX.DropButton.MouseButton1Click:Connect(function(): ()
	if BPX.CountDroppable() > 0 then
		BPX.Confirm.Visible = true
	end
end)

BPX.FavoriteButton.MouseButton1Click:Connect(function(): ()
	local tool = BPX.SelectedTool
	if tool and SlotsByTool[tool] then
		tool:SetAttribute("BP_Fav", not tool:GetAttribute("BP_Fav"))
		BPX.UpdateControls()
	end
end)

BPX.LockButton.MouseButton1Click:Connect(function(): ()
	local tool = BPX.SelectedTool
	if tool and SlotsByTool[tool] then
		tool:SetAttribute("BP_Lock", not tool:GetAttribute("BP_Lock"))
		BPX.UpdateControls()
	end
end)

BPX.UnloadButton.MouseButton1Click:Connect(function(): ()
	BPX.Unload()
end)

BPX.CollapseButton.MouseButton1Click:Connect(function(): ()
	if BackpackScript.IsOpen and BackpackScript.OpenClose then
		BackpackScript.OpenClose()
	end
	BPX.Collapsed = true
	BPX.UpdateControls()
end)

BPX.MiniButton.MouseButton1Click:Connect(function(): ()
	if BPX.Collapsed then
		BPX.Collapsed = false
		BPX.UpdateControls()
		AdjustHotbarFrames()
		return
	end
	if IS_PHONE and not BPX.HasAnyTool() and BackpackScript.OpenClose then
		BackpackScript.OpenClose()
	end
end)

BPX.ConfirmNo.MouseButton1Click:Connect(function(): ()
	BPX.Confirm.Visible = false
end)

BPX.ConfirmYes.MouseButton1Click:Connect(function(): ()
	BPX.Confirm.Visible = false
	local list = {}
	for _, slot in ipairs(Slots) do
		local tool = slot.Tool
		if tool and tool:IsA("Tool") and tool.CanBeDropped and not tool:GetAttribute("BP_Lock") then
			table.insert(list, tool)
		end
	end
	UnequipAllTools()
	for _, tool in ipairs(list) do
		if tool.Parent and tool.Parent ~= workspace then
			if tool.Parent ~= Character then
				tool.Parent = Character
				task.wait()
			end
			tool.Parent = workspace
			task.wait()
		end
	end
	BPX.SelectedTool = nil
	BPX.UpdateControls()
end)

BackpackScript.StateChanged.Event:Connect(function(): ()
	BPX.UpdateControls()
end)
BackpackScript.BackpackItemAdded.Event:Connect(function(): ()
	BPX.UpdateControls()
end)
BackpackScript.BackpackItemRemoved.Event:Connect(function(): ()
	BPX.UpdateControls()
end)
BackpackScript.BackpackEmpty.Event:Connect(function(): ()
	BPX.SelectedTool = nil
	BPX.UpdateControls()
end)
BPX.UpdateControls()


local gamepadHintsFrame: Frame = Instance.new("Frame")
gamepadHintsFrame.Name = "GamepadHintsFrame"
gamepadHintsFrame.Size = UDim2.fromOffset(HotbarFrame.Size.X.Offset, (IsTenFootInterface and 95 or 60))
gamepadHintsFrame.BackgroundTransparency = BACKGROUND_TRANSPARENCY
gamepadHintsFrame.BackgroundColor3 = BACKGROUND_COLOR
gamepadHintsFrame.Visible = false
gamepadHintsFrame.Parent = MainFrame

local gamepadHintsFrameLayout: UIListLayout = Instance.new("UIListLayout")
gamepadHintsFrameLayout.Name = "Layout"
gamepadHintsFrameLayout.Padding = UDim.new(0, 25)
gamepadHintsFrameLayout.FillDirection = Enum.FillDirection.Horizontal
gamepadHintsFrameLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gamepadHintsFrameLayout.SortOrder = Enum.SortOrder.LayoutOrder
gamepadHintsFrameLayout.Parent = gamepadHintsFrame

local gamepadHintsFrameCorner: UICorner = Instance.new("UICorner")
gamepadHintsFrameCorner.Name = "Corner"
gamepadHintsFrameCorner.CornerRadius = BACKGROUND_CORNER_RADIUS
gamepadHintsFrameCorner.Parent = gamepadHintsFrame

local function addGamepadHint(hintImageString: string, hintTextString: string): ()
	local hintFrame: Frame = Instance.new("Frame")
	hintFrame.Name = "HintFrame"
	hintFrame.AutomaticSize = Enum.AutomaticSize.XY
	hintFrame.BackgroundTransparency = 1
	hintFrame.Parent = gamepadHintsFrame

	local hintLayout: UIListLayout = Instance.new("UIListLayout")
	hintLayout.Name = "Layout"
	hintLayout.Padding = (IsTenFootInterface and UDim.new(0, 20) or UDim.new(0, 12))
	hintLayout.FillDirection = Enum.FillDirection.Horizontal
	hintLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hintLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hintLayout.Parent = hintFrame

	local hintImage: ImageLabel = Instance.new("ImageLabel")
	hintImage.Name = "HintImage"
	hintImage.Size = (IsTenFootInterface and UDim2.fromOffset(60, 60) or UDim2.fromOffset(30, 30))
	hintImage.BackgroundTransparency = 1
	hintImage.Image = hintImageString
	hintImage.Parent = hintFrame

	local hintText: TextLabel = Instance.new("TextLabel")
	hintText.Name = "HintText"
	hintText.AutomaticSize = Enum.AutomaticSize.XY
	hintText.FontFace = Font.new(FONT_FAMILY.Family, Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	hintText.TextSize = (IsTenFootInterface and 32 or 19)
	hintText.BackgroundTransparency = 1
	hintText.Text = hintTextString
	hintText.TextColor3 = Color3.new(1, 1, 1)
	hintText.TextXAlignment = Enum.TextXAlignment.Left
	hintText.TextYAlignment = Enum.TextYAlignment.Center
	hintText.TextWrapped = true
	hintText.Parent = hintFrame

	local textSizeConstraint: UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	textSizeConstraint.MaxTextSize = hintText.TextSize
	textSizeConstraint.Parent = hintText
end

addGamepadHint(UserInputService:GetImageForKeyCode(Enum.KeyCode.ButtonX), "Remove From Hotbar")
addGamepadHint(UserInputService:GetImageForKeyCode(Enum.KeyCode.ButtonA), "Select/Swap")
addGamepadHint(UserInputService:GetImageForKeyCode(Enum.KeyCode.ButtonB), "Close Backpack")

local function resizeGamepadHintsFrame(): ()
	gamepadHintsFrame.Size =
		UDim2.new(HotbarFrame.Size.X.Scale, HotbarFrame.Size.X.Offset, 0, (IsTenFootInterface and 95 or 60))
	gamepadHintsFrame.Position = UDim2.new(
		HotbarFrame.Position.X.Scale,
		HotbarFrame.Position.X.Offset,
		InventoryFrame.Position.Y.Scale,
		InventoryFrame.Position.Y.Offset - gamepadHintsFrame.Size.Y.Offset - ICON_BUFFER_PIXELS
	)

	local spaceTaken: number = 0

	local gamepadHints: { Instance } = gamepadHintsFrame:GetChildren()
	local filteredGamepadHints: any = {}

	for _, child: Instance in pairs(gamepadHints) do
		if child:IsA("GuiObject") then
			table.insert(filteredGamepadHints, child)
		end
	end


	for guiObjects = 1, #filteredGamepadHints do
		if filteredGamepadHints[guiObjects]:IsA("GuiObject") then
			filteredGamepadHints[guiObjects].Size = UDim2.new(1, 0, 1, -5)
			filteredGamepadHints[guiObjects].Position = UDim2.new(0, 0, 0, 0)
			spaceTaken = spaceTaken
				+ (
					filteredGamepadHints[guiObjects].HintText.Position.X.Offset
					+ filteredGamepadHints[guiObjects].HintText.TextBounds.X
				)
		end
	end


	local spaceBetweenElements: number = (gamepadHintsFrame.AbsoluteSize.X - spaceTaken) / (#filteredGamepadHints - 1)
	for i: number = 1, #filteredGamepadHints do
		filteredGamepadHints[i].Position = (
			i == 1 and UDim2.new(0, 0, 0, 0)
			or UDim2.new(
				0,
				filteredGamepadHints[i - 1].Position.X.Offset
					+ filteredGamepadHints[i - 1].Size.X.Offset
					+ spaceBetweenElements,
				0,
				0
			)
		)
		filteredGamepadHints[i].Size = UDim2.new(
			0,
			(filteredGamepadHints[i].HintText.Position.X.Offset + filteredGamepadHints[i].HintText.TextBounds.X),
			1,
			-5
		)
	end
end

local searchFrame: Frame = Instance.new("Frame")
do
	searchFrame.Name = "Search"
	searchFrame.BackgroundColor3 = SEARCH_BACKGROUND_COLOR
	searchFrame.BackgroundTransparency = SEARCH_BACKGROUND_TRANSPARENCY
	searchFrame.Size = UDim2.new(
		0,
		SEARCH_WIDTH_PIXELS - (SEARCH_BUFFER_PIXELS * 2),
		0,
		INVENTORY_HEADER_SIZE - (SEARCH_BUFFER_PIXELS * 2)
	)
	searchFrame.Position = UDim2.new(1, -searchFrame.Size.X.Offset - SEARCH_BUFFER_PIXELS, 0, SEARCH_BUFFER_PIXELS)
	searchFrame.Parent = InventoryFrame

	local searchFrameCorner: UICorner = Instance.new("UICorner")
	searchFrameCorner.Name = "Corner"
	searchFrameCorner.CornerRadius = SEARCH_CORNER_RADIUS
	searchFrameCorner.Parent = searchFrame

	local searchFrameBorder: UIStroke = Instance.new("UIStroke")
	searchFrameBorder.Name = "Border"
	searchFrameBorder.Color = SEARCH_BORDER_COLOR
	searchFrameBorder.Thickness = SEARCH_BORDER_THICKNESS
	searchFrameBorder.Transparency = SEARCH_BORDER_TRANSPARENCY
	searchFrameBorder.Parent = searchFrame

	local searchBox: TextBox = Instance.new("TextBox")
	searchBox.BackgroundTransparency = 1
	searchBox.Name = "TextBox"
	searchBox.Text = ""
	searchBox.TextColor3 = TEXT_COLOR
	searchBox.TextStrokeTransparency = TEXT_STROKE_TRANSPARENCY
	searchBox.TextStrokeColor3 = TEXT_STROKE_COLOR
	searchBox.FontFace = Font.new(FONT_FAMILY.Family, Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	searchBox.PlaceholderText = SEARCH_TEXT_PLACEHOLDER
	searchBox.TextColor3 = TEXT_COLOR
	searchBox.TextTransparency = TEXT_STROKE_TRANSPARENCY
	searchBox.TextStrokeColor3 = TEXT_STROKE_COLOR
	searchBox.ClearTextOnFocus = false
	searchBox.TextTruncate = Enum.TextTruncate.AtEnd
	searchBox.TextSize = FONT_SIZE
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.TextYAlignment = Enum.TextYAlignment.Center
	searchBox.Size = UDim2.new(
		0,
		(SEARCH_WIDTH_PIXELS - (SEARCH_BUFFER_PIXELS * 2)) - (SEARCH_TEXT_OFFSET * 2) - 20,
		0,
		INVENTORY_HEADER_SIZE - (SEARCH_BUFFER_PIXELS * 2) - (SEARCH_TEXT_OFFSET * 2)
	)
	searchBox.AnchorPoint = Vector2.new(0, 0.5)
	searchBox.Position = UDim2.new(0, SEARCH_TEXT_OFFSET, 0.5, 0)
	searchBox.ZIndex = 2
	searchBox.Parent = searchFrame

	local xButton: TextButton = Instance.new("TextButton")
	xButton.Name = "X"
	xButton.Text = ""
	xButton.Size = UDim2.fromOffset(30, 30)
	xButton.Position = UDim2.new(1, -xButton.Size.X.Offset, 0.5, -xButton.Size.Y.Offset / 2)
	xButton.ZIndex = 4
	xButton.Visible = false
	xButton.BackgroundTransparency = 1
	xButton.Parent = searchFrame

	local xImage: ImageButton = Instance.new("ImageButton")
	xImage.Name = "X"
	xImage.Image = SEARCH_IMAGE_X
	xImage.BackgroundTransparency = 1
	xImage.Size = UDim2.new(
		0,
		searchFrame.Size.Y.Offset - (SEARCH_BUFFER_PIXELS * 4),
		0,
		searchFrame.Size.Y.Offset - (SEARCH_BUFFER_PIXELS * 4)
	)
	xImage.AnchorPoint = Vector2.new(0.5, 0.5)
	xImage.Position = UDim2.fromScale(0.5, 0.5)
	xImage.ZIndex = 1
	xImage.BorderSizePixel = 0
	xImage.Parent = xButton

	local function search(): ()
		local terms: { [string]: boolean } = {}
		for word: string in searchBox.Text:gmatch("%S+") do
			terms[word:lower()] = true
		end

		local hitTable = {}
		for i: number = NumberOfHotbarSlots + 1, #Slots do
			local slot = Slots[i]
			local hits: any = slot:CheckTerms(terms)
			table.insert(hitTable, { slot, hits })
			slot.Frame.Visible = false
			slot.Frame.Parent = InventoryFrame
		end

		table.sort(hitTable, function(left: any, right: any): boolean
			return left[2] > right[2]
		end)
		ViewingSearchResults = true

		local hitCount: number = 0
		for _, data in ipairs(hitTable) do
			local slot, hits: any = data[1], data[2]
			if hits > 0 then
				slot.Frame.Visible = true
				slot.Frame.Parent = UIGridFrame
				slot.Frame.LayoutOrder = NumberOfHotbarSlots + hitCount
				hitCount = hitCount + 1
			end
		end

		ScrollingFrame.CanvasPosition = Vector2.new(0, 0)
		UpdateScrollingFrameCanvasSize()

		xButton.ZIndex = 3
	end

	local function clearResults(): ()
		if xButton.ZIndex > 0 then
			ViewingSearchResults = false
			for i: number = NumberOfHotbarSlots + 1, #Slots do
				local slot = Slots[i]
				slot.Frame.LayoutOrder = slot.Index
				slot.Frame.Parent = UIGridFrame
				slot.Frame.Visible = true
			end
			xButton.ZIndex = 0
		end
		UpdateScrollingFrameCanvasSize()
	end

	local function reset(): ()
		clearResults()
		searchBox.Text = ""
	end

	local function onChanged(property: string): ()
		if property == "Text" then
			local text: string = searchBox.Text
			if text == "" then
				searchBox.TextTransparency = TEXT_STROKE_TRANSPARENCY
				clearResults()
			elseif text ~= SEARCH_TEXT then
				searchBox.TextTransparency = 0
				search()
			end
			xButton.Visible = text ~= "" and text ~= SEARCH_TEXT
		end
	end

	local function focusLost(enterPressed: boolean): ()
		if enterPressed then

			search()
		end
	end

	xButton.MouseButton1Click:Connect(reset)
	searchBox.Changed:Connect(onChanged)
	searchBox.FocusLost:Connect(focusLost)

	BackpackScript.StateChanged.Event:Connect(function(isNowOpen: boolean): ()


		if not isNowOpen then
			reset()
		end
	end)

	HotkeyFns[Enum.KeyCode.Escape.Value] = function(isProcessed: any): ()
		if isProcessed then
			reset()
		end
	end
	local function detectGamepad(lastInputType: Enum.UserInputType): ()
		if lastInputType == Enum.UserInputType.Gamepad1 and not UserInputService.VREnabled then
			searchFrame.Visible = false
		else
			searchFrame.Visible = true
		end
	end
	BPX.TrackConnection(UserInputService.LastInputTypeChanged:Connect(detectGamepad))
end


BPX.TrackConnection(GuiService.MenuOpened:Connect(function(): ()
	BackpackGui.Enabled = false
	inventoryIcon:setEnabled(false)
end))


BPX.TrackConnection(GuiService.MenuClosed:Connect(function(): ()
	BackpackGui.Enabled = true
	inventoryIcon:setEnabled(true)
end))

do

	local removeHotBarSlot = function(name: string, state: Enum.UserInputState, input: InputObject): ()
		if state ~= Enum.UserInputState.Begin then
			return
		end
		if not GuiService.SelectedObject then
			return
		end

		for i: number = 1, NumberOfHotbarSlots do
			if Slots[i].Frame == GuiService.SelectedObject and Slots[i].Tool then
				Slots[i]:MoveToInventory()
				return
			end
		end
	end

	local function openClose(): ()
		if next(Dragging) then
			return
		end
		local nowOpen: boolean = not BackpackScript.IsOpen
		BackpackScript.IsOpen = nowOpen
		BPX.AnimateInventory(nowOpen)
		AdjustHotbarFrames()
		HotbarFrame.Active = not HotbarFrame.Active
		for i: number = 1, NumberOfHotbarSlots do
			Slots[i]:SetClickability(not nowOpen)
		end

		if nowOpen then
			if GamepadEnabled then
				if GAMEPAD_INPUT_TYPES[UserInputService:GetLastInputType()] then
					resizeGamepadHintsFrame()
					gamepadHintsFrame.Visible = not UserInputService.VREnabled
				end
				enableGamepadInventoryControl()
			end
			if BackpackPanel and VRService.VREnabled then
				BackpackPanel:SetVisible(true)
				BackpackPanel:RequestPositionUpdate()
			end
		else
			if GamepadEnabled then
				gamepadHintsFrame.Visible = false
			end
			disableGamepadInventoryControl()
		end

		if nowOpen then
			ContextActionService:BindAction("BackpackRemoveSlot", removeHotBarSlot, false, Enum.KeyCode.ButtonX)
		else
			ContextActionService:UnbindAction("BackpackRemoveSlot")
		end

		BackpackScript.StateChanged:Fire(nowOpen)
	end

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	BackpackScript.OpenClose = openClose
	HotkeyFns[Enum.KeyCode.Backquote.Value] = function(): ()
		openClose()
	end
end




while not Player do
	task.wait()
	Player = Players.LocalPlayer
end


BPX.TrackConnection(Player.CharacterAdded:Connect(OnCharacterAdded))
if Player.Character then
	OnCharacterAdded(Player.Character)
end

do

	BPX.TrackConnection(UserInputService.InputBegan:Connect(OnInputBegan))


	BPX.TrackConnection(UserInputService.TextBoxFocused:Connect(function(): ()
		TextBoxFocused = true
	end))
	BPX.TrackConnection(UserInputService.TextBoxFocusReleased:Connect(function(): ()
		TextBoxFocused = false
	end))


	HotkeyFns[DROP_HOTKEY_VALUE] = function(): ()
		if ActiveHopper then
			UnequipAllTools()
		end
	end


	BPX.TrackConnection(UserInputService.LastInputTypeChanged:Connect(OnUISChanged))
	OnUISChanged()


	if UserInputService:GetGamepadConnected(Enum.UserInputType.Gamepad1) then
		gamepadConnected()
	end
	BPX.TrackConnection(UserInputService.GamepadConnected:Connect(function(gamepadEnum: Enum.UserInputType): ()
		if gamepadEnum == Enum.UserInputType.Gamepad1 then
			gamepadConnected()
		end
	end))
	BPX.TrackConnection(UserInputService.GamepadDisconnected:Connect(function(gamepadEnum: Enum.UserInputType): ()
		if gamepadEnum == Enum.UserInputType.Gamepad1 then
			gamepadDisconnected()
		end
	end))
end


function BackpackScript:SetBackpackEnabled(Enabled: boolean): ()
	BackpackEnabled = Enabled
end


function BackpackScript:IsOpened(): boolean
	return BackpackScript.IsOpen
end


function BackpackScript:GetBackpackEnabled(): boolean
	return BackpackEnabled
end


function BackpackScript:GetStateChangedEvent(): BindableEvent
	return BackpackScript.StateChanged
end


BPX.LastControlRefresh = 0
BPX.TrackConnection(RunService.Heartbeat:Connect(function(): ()
	OnIconChanged(BackpackEnabled)
	BPX.LastControlRefresh += 1
	if BPX.LastControlRefresh >= 30 then
		BPX.LastControlRefresh = 0
		BPX.UpdateControls()
	end
end))


local function OnPreferredTransparencyChanged(): ()
	local preferredTransparency: number = GuiService.PreferredTransparency

	BACKGROUND_TRANSPARENCY = BACKGROUND_TRANSPARENCY_DEFAULT * preferredTransparency
	InventoryFrame.BackgroundTransparency = BACKGROUND_TRANSPARENCY

	SLOT_LOCKED_TRANSPARENCY = SLOT_LOCKED_TRANSPARENCY_DEFAULT * preferredTransparency
	for _, slot in ipairs(Slots) do
		slot.Frame.BackgroundTransparency = SLOT_LOCKED_TRANSPARENCY
	end

	SEARCH_BACKGROUND_TRANSPARENCY = SEARCH_BACKGROUND_TRANSPARENCY_DEFAULT * preferredTransparency
	searchFrame.BackgroundTransparency = SEARCH_BACKGROUND_TRANSPARENCY
end
BPX.TrackConnection(GuiService:GetPropertyChangedSignal("PreferredTransparency"):Connect(OnPreferredTransparencyChanged))

return BackpackScript
