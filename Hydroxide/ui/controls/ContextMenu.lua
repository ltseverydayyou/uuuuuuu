local function __betterGetService(name)
	local service = game:FindService(name)
	if service then
		return service
	end
	local ok, inst = pcall(Instance.new, name)
	if ok and inst and typeof(inst) == "Instance" then
		return inst
	end
	return nil
end
local Assets = import("rbxassetid://5042114982").Controls
local Storage = import("rbxassetid://11389137937").ContextMenus

local GuiService = __betterGetService("GuiService")
local UserInput = __betterGetService("UserInputService")
local TextService = __betterGetService("TextService")
local TweenService = __betterGetService("TweenService")

local ContextMenuButton = {}
local ContextMenu = {}

local currentContextMenu
local ignoreNextTouchEnd = false
local constants = {
    fadeLength = TweenInfo.new(0.15),
    textWidth = Vector2.new(1337420, 20)
}

function ContextMenuButton.new(icon, text)
    local contextMenuButton = {}
    local instance = Assets.ContextMenuButton:Clone()
    local label = instance.Label

    local enterAnimation = TweenService:Create(label, constants.fadeLength, { TextTransparency = 0 })
    local leaveAnimation = TweenService:Create(label, constants.fadeLength, { TextTransparency = 0.2 })

    label.Text = text
    instance.Icon.Image = icon

    instance.Activated:Connect(function()
        if contextMenuButton.Callback then
            contextMenuButton.Callback()
        end
    end)

    instance.MouseEnter:Connect(function()
        enterAnimation:Play()
    end)

    instance.MouseLeave:Connect(function()
        leaveAnimation:Play()
    end)

    contextMenuButton.Instance = instance
    contextMenuButton.SetIcon = ContextMenuButton.setIcon
    contextMenuButton.SetText = ContextMenuButton.setText
    contextMenuButton.SetCallback = ContextMenuButton.setCallback
    return contextMenuButton
end

function ContextMenuButton.setIcon(contextMenuButton, newIcon)
    contextMenuButton.Instance.Icon.Image = newIcon
end

function ContextMenuButton.setText(contextMenuButton, newText)
    contextMenuButton.Instance.Label.Text = newText
end

function ContextMenuButton.setCallback(contextMenuButton, callback)
    if not contextMenuButton.Callback then
        contextMenuButton.Callback = callback
    end
end

function ContextMenu.new(contextMenuButtons)
    local contextMenu = {}
    local instance = Assets.ContextMenu:Clone()
    local instanceWidth = 0
    local instanceHeight = 0

    instance.Parent = Storage
    
    for _i, contextMenuButton in pairs(contextMenuButtons) do
        local buttonInstance = contextMenuButton.Instance
        local textWidth = TextService:GetTextSize(buttonInstance.Label.Text, 18, "SourceSans", constants.textWidth).X

        buttonInstance.Parent = instance.List
        buttonInstance.TextWrapped = false

        local buttonWidth = buttonInstance.Icon.AbsoluteSize.X + textWidth + 16
        
        if buttonWidth > instanceWidth then
            instanceWidth = buttonWidth
        end

        instanceHeight = instanceHeight + buttonInstance.AbsoluteSize.Y
    end
    
    instance.Size = UDim2.new(0, instanceWidth, 0, instanceHeight)
    instance.Visible = false
    
    contextMenu.Instance = instance
    contextMenu.Visible = false
    contextMenu.Buttons = {}
    contextMenu.Show = ContextMenu.show
    contextMenu.Hide = ContextMenu.hide
    return contextMenu
end

function ContextMenu.add(contextMenu, contextMenuButton)
    table.insert(contextMenu.Buttons, contextMenuButton)
end

local function getRootGui(inst)
    if inst and inst.FindFirstAncestorOfClass then
        local root = inst:FindFirstAncestorOfClass("ScreenGui")
        if root then
            return root
        end
    end
    local cur = inst
    while cur do
        if cur:IsA("ScreenGui") then
            return cur
        end
        cur = cur.Parent
    end
    return nil
end

function ContextMenu.show(contextMenu)
    if currentContextMenu then
        currentContextMenu:Hide()
    end

    local instance = contextMenu.Instance

    instance.Visible = true
    local lastType = UserInput and UserInput.GetLastInputType and UserInput:GetLastInputType()
    local pos = UserInput:GetMouseLocation()
    local root = getRootGui(instance)
    if not root or not root.IgnoreGuiInset then
        local inset = GuiService and GuiService.GetGuiInset and GuiService:GetGuiInset()
        if inset then
            pos = pos - inset
        end
    end

    local parent = instance.Parent
    if parent and parent:IsA("GuiObject") then
        pos = pos - parent.AbsolutePosition
    end
    instance.Position = UDim2.new(0, pos.X, 0, pos.Y)
    
    contextMenu.Visible = true
    currentContextMenu = contextMenu

    ignoreNextTouchEnd = lastType == Enum.UserInputType.Touch
end

function ContextMenu.hide(contextMenu)
    contextMenu.Visible = false
    contextMenu.Instance.Visible = false
end

UserInput.InputEnded:Connect(function(input)
    if currentContextMenu and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        if input.UserInputType == Enum.UserInputType.Touch and ignoreNextTouchEnd then
            ignoreNextTouchEnd = false
            return
        end

        ignoreNextTouchEnd = false
        currentContextMenu:Hide()
        currentContextMenu = nil
    end
end)

return ContextMenu, ContextMenuButton


