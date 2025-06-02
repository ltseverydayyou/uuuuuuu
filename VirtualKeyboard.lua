local function ClonedService(name)
    local Service = (game.GetService);
	local Reference = (cloneref) or function(reference) return reference end
	return Reference(Service(game, name));
end

local UIS = ClonedService("UserInputService")
local GuiS = ClonedService("GuiService")
local VIM = ClonedService("VirtualInputManager")
local TS = ClonedService("TextService")

local function protectUI(sGui)
    if sGui:IsA("ScreenGui") then
        sGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
		sGui.DisplayOrder = 999999999
		sGui.ResetOnSpawn = false
		sGui.IgnoreGuiInset = true
    end
    local cGUI = ClonedService("CoreGui")
    local lPlr = ClonedService("Players").LocalPlayer

    local function NAProtection(inst, var)
        if inst then
            if var then
                inst[var] = "\0"
                inst.Archivable = false
            else
                inst.Name = "\0"
                inst.Archivable = false
            end
        end
    end

    if gethui then
		NAProtection(sGui)
		sGui.Parent = gethui()
		return sGui
	elseif cGUI and cGUI:FindFirstChild("RobloxGui") then
		NAProtection(sGui)
		sGui.Parent = cGUI:FindFirstChild("RobloxGui")
		return sGui
	elseif cGUI then
		NAProtection(sGui)
		sGui.Parent = cGUI
		return sGui
	elseif lPlr and lPlr:FindFirstChildWhichIsA("PlayerGui") then
		NAProtection(sGui)
		sGui.Parent = lPlr:FindFirstChildWhichIsA("PlayerGui")
		sGui.ResetOnSpawn = false
		return sGui
	else
		return nil
	end
end

local themes = {
	Dark = {Bg = Color3.fromRGB(40, 40, 40), Btn = Color3.fromRGB(60, 60, 60), Acc = Color3.fromRGB(60, 180, 60), Txt = Color3.fromRGB(255, 255, 255)},
	Light = {Bg = Color3.fromRGB(245, 245, 245), Btn = Color3.fromRGB(220, 220, 220), Acc = Color3.fromRGB(100, 200, 255), Txt = Color3.fromRGB(0, 0, 0)},

	Red = {Bg = Color3.fromRGB(60, 0, 0), Btn = Color3.fromRGB(100, 0, 0), Acc = Color3.fromRGB(200, 30, 30), Txt = Color3.fromRGB(255, 255, 255)},
	Green = {Bg = Color3.fromRGB(0, 60, 0), Btn = Color3.fromRGB(0, 100, 0), Acc = Color3.fromRGB(50, 200, 50), Txt = Color3.fromRGB(255, 255, 255)},
	Blue = {Bg = Color3.fromRGB(0, 0, 60), Btn = Color3.fromRGB(0, 0, 100), Acc = Color3.fromRGB(50, 100, 255), Txt = Color3.fromRGB(255, 255, 255)},
	Yellow = {Bg = Color3.fromRGB(100, 100, 0), Btn = Color3.fromRGB(180, 180, 0), Acc = Color3.fromRGB(255, 255, 50), Txt = Color3.fromRGB(0, 0, 0)},
	Orange = {Bg = Color3.fromRGB(100, 50, 0), Btn = Color3.fromRGB(160, 80, 0), Acc = Color3.fromRGB(255, 140, 0), Txt = Color3.fromRGB(255, 255, 255)},
	Purple = {Bg = Color3.fromRGB(50, 0, 100), Btn = Color3.fromRGB(80, 0, 160), Acc = Color3.fromRGB(180, 50, 255), Txt = Color3.fromRGB(255, 255, 255)},
	Pink = {Bg = Color3.fromRGB(100, 0, 60), Btn = Color3.fromRGB(180, 0, 100), Acc = Color3.fromRGB(255, 105, 180), Txt = Color3.fromRGB(255, 255, 255)},
	Teal = {Bg = Color3.fromRGB(0, 60, 60), Btn = Color3.fromRGB(0, 100, 100), Acc = Color3.fromRGB(0, 200, 200), Txt = Color3.fromRGB(255, 255, 255)},
	Cyan = {Bg = Color3.fromRGB(0, 100, 100), Btn = Color3.fromRGB(0, 150, 150), Acc = Color3.fromRGB(0, 255, 255), Txt = Color3.fromRGB(0, 0, 0)},
	Indigo = {Bg = Color3.fromRGB(40, 0, 80), Btn = Color3.fromRGB(60, 0, 120), Acc = Color3.fromRGB(90, 70, 255), Txt = Color3.fromRGB(255, 255, 255)},
	Lime = {Bg = Color3.fromRGB(80, 100, 0), Btn = Color3.fromRGB(120, 180, 0), Acc = Color3.fromRGB(180, 255, 0), Txt = Color3.fromRGB(0, 0, 0)},
	Magenta = {Bg = Color3.fromRGB(80, 0, 80), Btn = Color3.fromRGB(140, 0, 140), Acc = Color3.fromRGB(255, 0, 255), Txt = Color3.fromRGB(255, 255, 255)},
	Maroon = {Bg = Color3.fromRGB(80, 0, 0), Btn = Color3.fromRGB(120, 0, 0), Acc = Color3.fromRGB(180, 20, 20), Txt = Color3.fromRGB(255, 255, 255)},
	Navy = {Bg = Color3.fromRGB(0, 0, 60), Btn = Color3.fromRGB(0, 0, 100), Acc = Color3.fromRGB(0, 0, 180), Txt = Color3.fromRGB(255, 255, 255)},
	Olive = {Bg = Color3.fromRGB(80, 80, 0), Btn = Color3.fromRGB(100, 100, 20), Acc = Color3.fromRGB(160, 160, 60), Txt = Color3.fromRGB(0, 0, 0)},
	Brown = {Bg = Color3.fromRGB(60, 30, 0), Btn = Color3.fromRGB(100, 50, 0), Acc = Color3.fromRGB(160, 80, 20), Txt = Color3.fromRGB(255, 255, 255)},
	Silver = {Bg = Color3.fromRGB(200, 200, 200), Btn = Color3.fromRGB(230, 230, 230), Acc = Color3.fromRGB(255, 255, 255), Txt = Color3.fromRGB(0, 0, 0)}
}

local gui = Instance.new("ScreenGui")
gui.Name = "VKB"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
protectUI(gui)

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 650, 0, 250)
Main.Position = UDim2.new(0.5, -325, 0.8, -125)
Main.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Main.BorderSizePixel = 0
Main.Parent = gui

local c1 = Instance.new("UICorner")
c1.CornerRadius = UDim.new(0, 10)
c1.Parent = Main

local Title = Instance.new("Frame")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Title.BorderSizePixel = 0
Title.Parent = Main

local c2 = Instance.new("UICorner")
c2.CornerRadius = UDim.new(0, 10)
c2.Parent = Title

local TLabel = Instance.new("TextLabel")
TLabel.Size = UDim2.new(1, -200, 1, 0)
TLabel.Position = UDim2.new(0, 10, 0, 0)
TLabel.BackgroundTransparency = 1
TLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TLabel.TextSize = 16
TLabel.Font = Enum.Font.SourceSansBold
TLabel.Text = "Virtual Keyboard"
TLabel.TextXAlignment = Enum.TextXAlignment.Left
TLabel.Parent = Title

local Close = Instance.new("TextButton")
Close.Name = "Close"
Close.Size = UDim2.new(0, 40, 0, 25)
Close.Position = UDim2.new(1, -85, 0, 2.5)
Close.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.Text = "X"
Close.TextSize = 16
Close.Font = Enum.Font.SourceSansBold
Close.Parent = Title
local c3 = Instance.new("UICorner")
c3.CornerRadius = UDim.new(0, 5)
c3.Parent = Close

local AddBTN = Instance.new("TextButton")
AddBTN.Name = "Add"
AddBTN.Size = UDim2.new(0, 40, 0, 25)
AddBTN.Position = UDim2.new(1, -45, 0, 2.5)
AddBTN.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
AddBTN.TextColor3 = Color3.fromRGB(255, 255, 255)
AddBTN.Text = "+"
AddBTN.TextSize = 16
AddBTN.Font = Enum.Font.SourceSansBold
AddBTN.Parent = Title
local c4 = Instance.new("UICorner")
c4.CornerRadius = UDim.new(0, 5)
c4.Parent = AddBTN

local ThemeBtn = Instance.new("TextButton")
ThemeBtn.Name = "Theme"
ThemeBtn.Size = UDim2.new(0, 80, 0, 25)
ThemeBtn.Position = UDim2.new(1, -170, 0, 2.5)
ThemeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
ThemeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ThemeBtn.Text = "Dark"
ThemeBtn.TextSize = 14
ThemeBtn.Font = Enum.Font.SourceSansBold
ThemeBtn.Parent = Title
local c5 = Instance.new("UICorner")
c5.CornerRadius = UDim.new(0, 5)
c5.Parent = ThemeBtn

local Keys = Instance.new("Frame")
Keys.Name = "Keys"
Keys.Size = UDim2.new(1, -20, 1, -40)
Keys.Position = UDim2.new(0, 10, 0, 35)
Keys.BackgroundTransparency = 1
Keys.Parent = Main

local Toggle = Instance.new("TextButton")
Toggle.Name = "Toggle"
Toggle.Size = UDim2.new(0, 50, 0, 50)
Toggle.Position = UDim2.new(0, 20, 0.5, -25)
Toggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.Text = "⌨️"
Toggle.TextSize = 20
Toggle.Font = Enum.Font.SourceSansBold
Toggle.Parent = gui
local c6 = Instance.new("UICorner")
c6.CornerRadius = UDim.new(0, 10)
c6.Parent = Toggle

local function applyTheme(name)
	local t = themes[name]
	if not t then return end
	Main.BackgroundColor3 = t.Bg
	Title.BackgroundColor3 = t.Btn
	Keys.BackgroundColor3 = t.Bg
	Toggle.BackgroundColor3 = t.Btn
	AddBTN.BackgroundColor3 = isSel and t.Acc or t.Btn
	Close.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	ThemeBtn.BackgroundColor3 = t.Btn
	TLabel.TextColor3 = t.Txt
	AddBTN.TextColor3 = t.Txt
	Close.TextColor3 = t.Txt
	Toggle.TextColor3 = t.Txt
	ThemeBtn.TextColor3 = t.Txt
	for _, k in ipairs(Keys:GetChildren()) do
		if k:IsA("TextButton") then
			k.BackgroundColor3 = t.Btn
			k.TextColor3 = t.Txt
		end
	end
end

ThemeBtn.MouseButton1Click:Connect(function()
	local opts = {
		"Dark", "Light", "Red", "Green", "Blue", "Yellow", "Orange", "Purple", "Pink",
		"Teal", "Cyan", "Indigo", "Lime", "Magenta", "Maroon", "Navy", "Olive", "Brown", "Silver"
	}
	local idx = table.find(opts, ThemeBtn.Text) or 1
	local next = opts[idx % #opts + 1]
	ThemeBtn.Text = next
	applyTheme(next)
end)

applyTheme("Dark")

local keyboardLayout = {
    {"1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "Backspace"},
    {"Tab", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "[", "]", "\\"},
    {"Caps", "A", "S", "D", "F", "G", "H", "J", "K", "L", ";", "'", "Enter"},
    {"Shift", "Z", "X", "C", "V", "B", "N", "M", ",", ".", "/", "Shift"},
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
    ["Q"] = Enum.KeyCode.Q,
    ["W"] = Enum.KeyCode.W,
    ["E"] = Enum.KeyCode.E,
    ["R"] = Enum.KeyCode.R,
    ["T"] = Enum.KeyCode.T,
    ["Y"] = Enum.KeyCode.Y,
    ["U"] = Enum.KeyCode.U,
    ["I"] = Enum.KeyCode.I,
    ["O"] = Enum.KeyCode.O,
    ["P"] = Enum.KeyCode.P,
    ["["] = Enum.KeyCode.LeftBracket,
    ["]"] = Enum.KeyCode.RightBracket,
    ["\\"] = Enum.KeyCode.BackSlash,
    ["Caps"] = Enum.KeyCode.CapsLock,
    ["A"] = Enum.KeyCode.A,
    ["S"] = Enum.KeyCode.S,
    ["D"] = Enum.KeyCode.D,
    ["F"] = Enum.KeyCode.F,
    ["G"] = Enum.KeyCode.G,
    ["H"] = Enum.KeyCode.H,
    ["J"] = Enum.KeyCode.J,
    ["K"] = Enum.KeyCode.K,
    ["L"] = Enum.KeyCode.L,
    [";"] = Enum.KeyCode.Semicolon,
    ["'"] = Enum.KeyCode.Quote,
    ["Enter"] = Enum.KeyCode.Return,
    ["Shift"] = Enum.KeyCode.LeftShift,
    ["Z"] = Enum.KeyCode.Z,
    ["X"] = Enum.KeyCode.X,
    ["C"] = Enum.KeyCode.C,
    ["V"] = Enum.KeyCode.V,
    ["B"] = Enum.KeyCode.B,
    ["N"] = Enum.KeyCode.N,
    ["M"] = Enum.KeyCode.M,
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
    ["Shift"] = 2.25,
    ["Ctrl"] = 1.5,
    ["Win"] = 1.25,
    ["Alt"] = 1.25,
    ["Space"] = 6,
    ["Fn"] = 1.25
}

local function createKey(text, row, col, width)
    local key = Instance.new("TextButton")
    key.Name = "Key_"..text
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
            VIM:SendKeyEvent(true, keyCode, false, game)
        end
    end)

    key.MouseButton1Up:Connect(function()
        key.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        isHolding = false

        if keyCode then
            VIM:SendKeyEvent(false, keyCode, false, game)
        end
    end)

    key.MouseLeave:Connect(function()
        if isHolding and keyCode then
            VIM:SendKeyEvent(false, keyCode, false, game)
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
        key.Parent = Keys

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

    UIS.InputChanged:Connect(function(input)
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

makeDraggable(Main, Title)
makeDraggable(Toggle, Toggle)

local isSelectionMode = false

AddBTN.MouseButton1Click:Connect(function()
    isSelectionMode = not isSelectionMode
    AddBTN.BackgroundColor3 = isSelectionMode and Color3.fromRGB(180, 60, 60) or Color3.fromRGB(60, 180, 60)
end)

local function createFloatingKey(text)
	local sz = TS:GetTextSize(text, 20, Enum.Font.SourceSansBold, Vector2.new(math.huge, math.huge))

	local btn = Instance.new("TextButton")
	btn.Name = "FloatingKey_" .. text
	btn.Size = UDim2.new(0, sz.X + 20, 0, sz.Y + 20)
	btn.Position = UDim2.new(0.5, -((sz.X + 20) / 2), 0.5, -((sz.Y + 20) / 2))
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text
	btn.TextSize = 20
	btn.Font = Enum.Font.SourceSansBold
	btn.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = btn

	local remove = Instance.new("TextButton")
	remove.Name = "Remove"
	remove.Size = UDim2.new(0, 20, 0, 20)
	remove.Position = UDim2.new(1, -25, 0, -5)
	remove.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	remove.Text = "X"
	remove.TextColor3 = Color3.fromRGB(255, 255, 255)
	remove.TextSize = 16
	remove.Font = Enum.Font.SourceSansBold
	remove.Parent = btn

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 10)
	rCorner.Parent = remove

	local isDown = false
	local keyCode = keyToEnum[text]

	btn.MouseButton1Down:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		isDown = true
		if keyCode then VIM:SendKeyEvent(true, keyCode, false, game) end
	end)

	btn.MouseButton1Up:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		isDown = false
		if keyCode then VIM:SendKeyEvent(false, keyCode, false, game) end
	end)

	btn.MouseLeave:Connect(function()
		if isDown and keyCode then
			VIM:SendKeyEvent(false, keyCode, false, game)
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			isDown = false
		end
	end)

	remove.MouseButton1Click:Connect(function()
		btn:Destroy()
	end)

	makeDraggable(btn, btn)
end

for _, key in ipairs(Keys:GetChildren()) do
    if key:IsA("TextButton") then
        key.MouseButton1Click:Connect(function()
            if isSelectionMode then
                createFloatingKey(key.Text)
                isSelectionMode = false
                AddBTN.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
            end
        end)
    end
end

Close.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

Toggle.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
    Toggle.BackgroundColor3 = Main.Visible and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(60, 60, 60)
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.F2 then
        Main.Visible = not Main.Visible
        Toggle.BackgroundColor3 = Main.Visible and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(60, 60, 60)
    end
end)