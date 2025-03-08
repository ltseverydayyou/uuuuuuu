local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local function getGuiParent()
    if syn and syn.protect_gui then
        local protectedGui = Instance.new("ScreenGui")
        syn.protect_gui(protectedGui)
        protectedGui.Parent = game:GetService("CoreGui")
        return protectedGui
    elseif gethui then
        return gethui()
    else
        return game:GetService("CoreGui")
    end
end

local KeyboardGui = Instance.new("ScreenGui")
KeyboardGui.Name = "VirtualKeyboard"
KeyboardGui.ResetOnSpawn = false
KeyboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
KeyboardGui.Parent = getGuiParent()

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 650, 0, 250)
MainFrame.Position = UDim2.new(0.5, -325, 0.8, -125)
MainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = KeyboardGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 30)
TitleBar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Text = "Virtual Keyboard"
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 40, 0, 25)
CloseButton.Position = UDim2.new(1, -45, 0, 2.5)
CloseButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Text = "X"
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 5)
CloseCorner.Parent = CloseButton

local KeysContainer = Instance.new("Frame")
KeysContainer.Name = "KeysContainer"
KeysContainer.Size = UDim2.new(1, -20, 1, -40)
KeysContainer.Position = UDim2.new(0, 10, 0, 35)
KeysContainer.BackgroundTransparency = 1
KeysContainer.Parent = MainFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "KeyboardToggle"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0, 20, 0.5, -25)
ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Text = "⌨️"
ToggleButton.TextSize = 20
ToggleButton.Font = Enum.Font.SourceSansBold
ToggleButton.Parent = KeyboardGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 10)
ToggleCorner.Parent = ToggleButton

local keyboardLayout = {
    {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "Backspace"},
    {"Tab", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]", "\\"},
    {"Caps", "a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'", "Enter"},
    {"Shift", "z", "x", "c", "v", "b", "n", "m", ",", ".", "/", "Shift"},
    {"Ctrl", "Win", "Alt", "Space", "Alt", "Fn", "Ctrl"}
}

local keyToEnum = {
    ["1"] = Enum.KeyCode.One,
    ["2"] = Enum.KeyCode.Two,
    ["3"] = Enum.KeyCode.Three,
    ["4"] = Enum.KeyCode.Four,
    ["5"] = Enum.KeyCode.Five,
    ["6"] = Enum.KeyCode.Six,
    ["7"] = Enum.KeyCode.Seven,
    ["8"] = Enum.KeyCode.Eight,
    ["9"] = Enum.KeyCode.Nine,
    ["0"] = Enum.KeyCode.Zero,
    ["-"] = Enum.KeyCode.Minus,
    ["="] = Enum.KeyCode.Equals,
    ["Backspace"] = Enum.KeyCode.Backspace,
    ["Tab"] = Enum.KeyCode.Tab,
    ["q"] = Enum.KeyCode.Q,
    ["w"] = Enum.KeyCode.W,
    ["e"] = Enum.KeyCode.E,
    ["r"] = Enum.KeyCode.R,
    ["t"] = Enum.KeyCode.T,
    ["y"] = Enum.KeyCode.Y,
    ["u"] = Enum.KeyCode.U,
    ["i"] = Enum.KeyCode.I,
    ["o"] = Enum.KeyCode.O,
    ["p"] = Enum.KeyCode.P,
    ["["] = Enum.KeyCode.LeftBracket,
    ["]"] = Enum.KeyCode.RightBracket,
    ["\\"] = Enum.KeyCode.BackSlash,
    ["Caps"] = Enum.KeyCode.CapsLock,
    ["a"] = Enum.KeyCode.A,
    ["s"] = Enum.KeyCode.S,
    ["d"] = Enum.KeyCode.D,
    ["f"] = Enum.KeyCode.F,
    ["g"] = Enum.KeyCode.G,
    ["h"] = Enum.KeyCode.H,
    ["j"] = Enum.KeyCode.J,
    ["k"] = Enum.KeyCode.K,
    ["l"] = Enum.KeyCode.L,
    [";"] = Enum.KeyCode.Semicolon,
    ["'"] = Enum.KeyCode.Quote,
    ["Enter"] = Enum.KeyCode.Return,
    ["Shift"] = Enum.KeyCode.LeftShift,
    ["z"] = Enum.KeyCode.Z,
    ["x"] = Enum.KeyCode.X,
    ["c"] = Enum.KeyCode.C,
    ["v"]= Enum.KeyCode.V,
    ["b"] = Enum.KeyCode.B,
    ["n"] = Enum.KeyCode.N,
    ["m"] = Enum.KeyCode.M,
    [","] = Enum.KeyCode.Comma,
    ["."] = Enum.KeyCode.Period,
    ["/"] = Enum.KeyCode.Slash,
    ["Ctrl"] = Enum.KeyCode.LeftControl,
    ["Win"] = Enum.KeyCode.LeftMeta,
    ["Alt"] = Enum.KeyCode.LeftAlt,
    ["Space"] = Enum.KeyCode.Space,
    ["Fn"] = Enum.KeyCode.F1
}

local specialKeySizes = {
    ["Backspace"] = 2,
    ["Tab"] = 1.5,
    ["Caps"] = 1.75,
    ["Enter"] = 1.75,
    ["Shift"]= 2.25,
    ["Ctrl"] = 1.5,
    ["Win"] = 1.25,
    ["Alt"] = 1.25,
    ["Space"] = 6,
    ["Fn"] = 1.25
}

local function createKey(text, row, col, width)
    local key = Instance.new("TextButton")
    key.Name = "Key_" .. text
    key.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    key.BorderSizePixel = 0
    key.TextColor3 = Color3.fromRGB(255, 255, 255)
    key.Text = text
    key.TextSize = 16
    key.Font = Enum.Font.SourceSans
    key.AutoButtonColor = true
    
    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 5)
    keyCorner.Parent = key
    
    local isHolding = false
    local keyCode = keyToEnum[text]
    
    key.MouseButton1Down:Connect(function()
        key.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        isHolding = true
        
        if keyCode then
            VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        end
    end)
    
    key.MouseButton1Up:Connect(function()
        key.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        isHolding = false
        
        if keyCode then
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
        end
    end)
    
    key.MouseLeave:Connect(function()
        if isHolding and keyCode then
            VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
            isHolding = false
            key.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
    end)
    
    return key
end

local rowHeight = 1 / #keyboardLayout
local currentY = 0

for rowIndex, row in ipairs(keyboardLayout) do
    local totalWidth = 0
    for _, key in ipairs(row) do
        totalWidth = totalWidth + (specialKeySizes[key] or 1)
    end
    
    local currentX = 0
    for keyIndex, keyText in ipairs(row) do
        local keyWidth = specialKeySizes[keyText] or 1
        local relativeWidth = keyWidth / totalWidth
        
        local key = createKey(keyText, rowIndex, keyIndex, keyWidth)
        key.Size = UDim2.new(relativeWidth, -2, rowHeight, -2)
        key.Position = UDim2.new(currentX, 1, currentY, 1)
        key.Parent = KeysContainer
        
        currentX = currentX + relativeWidth
    end
    
    currentY = currentY + rowHeight
end

local function makeDraggable(frame, handle)
    local isDragging = false
    local dragInput
    local dragStart
    local startPos
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and isDragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(MainFrame, TitleBar)
makeDraggable(ToggleButton, ToggleButton)

CloseButton.MouseButton1Click:Connect(function()
    KeyboardGui:Destroy()
end)

ToggleButton.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    ToggleButton.BackgroundColor3 = MainFrame.Visible and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(60, 60, 60)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F2 then
        MainFrame.Visible = not MainFrame.Visible
        ToggleButton.BackgroundColor3 = MainFrame.Visible and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(60, 60, 60)
    end
end)