local CCAimbotV2 = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local BottomFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local Page3 = Instance.new("ScrollingFrame")
local C1 = Instance.new("TextLabel")
local UIListLayout = Instance.new("UIListLayout")
local C2 = Instance.new("Frame")
local UICorner_2 = Instance.new("UICorner")
local Text = Instance.new("TextLabel")
local UICorner_3 = Instance.new("UICorner")
local SwitchFrame = Instance.new("Frame")
local UICorner_4 = Instance.new("UICorner")
local SwitchButton = Instance.new("Frame")
local UICorner_5 = Instance.new("UICorner")
local SwitchButtonLit = Instance.new("Frame")
local UICorner_6 = Instance.new("UICorner")
local SwitchButtonActivator = Instance.new("TextButton")
local UICorner_7 = Instance.new("UICorner")
local C3 = Instance.new("Frame")
local UICorner_8 = Instance.new("UICorner")
local Text_2 = Instance.new("TextLabel")
local UICorner_9 = Instance.new("UICorner")
local SwitchFrame_2 = Instance.new("Frame")
local UICorner_10 = Instance.new("UICorner")
local SwitchButton_2 = Instance.new("Frame")
local UICorner_11 = Instance.new("UICorner")
local SwitchButtonLit_2 = Instance.new("Frame")
local UICorner_12 = Instance.new("UICorner")
local SwitchButtonActivator_2 = Instance.new("TextButton")
local UICorner_13 = Instance.new("UICorner")
local C4 = Instance.new("Frame")
local UICorner_14 = Instance.new("UICorner")
local Text_3 = Instance.new("TextLabel")
local UICorner_15 = Instance.new("UICorner")
local SwitchFrame_3 = Instance.new("Frame")
local UICorner_16 = Instance.new("UICorner")
local SwitchButton_3 = Instance.new("Frame")
local UICorner_17 = Instance.new("UICorner")
local SwitchButtonLit_3 = Instance.new("Frame")
local UICorner_18 = Instance.new("UICorner")
local SwitchButtonActivator_3 = Instance.new("TextButton")
local UICorner_19 = Instance.new("UICorner")
local Page1 = Instance.new("ScrollingFrame")
local C1_2 = Instance.new("TextLabel")
local C2_2 = Instance.new("TextLabel")
local UICorner_20 = Instance.new("UICorner")
local C3_2 = Instance.new("TextLabel")
local UICorner_21 = Instance.new("UICorner")
local C4_2 = Instance.new("TextLabel")
local UICorner_22 = Instance.new("UICorner")
local UIListLayout_2 = Instance.new("UIListLayout")
local Page2 = Instance.new("ScrollingFrame")
local C1_3 = Instance.new("TextLabel")
local C3_3 = Instance.new("TextLabel")
local UICorner_23 = Instance.new("UICorner")
local UIListLayout_3 = Instance.new("UIListLayout")
local C2_3 = Instance.new("Frame")
local UICorner_24 = Instance.new("UICorner")
local Text_4 = Instance.new("TextLabel")
local UICorner_25 = Instance.new("UICorner")
local SwitchFrame_4 = Instance.new("Frame")
local UICorner_26 = Instance.new("UICorner")
local SwitchButton_4 = Instance.new("Frame")
local UICorner_27 = Instance.new("UICorner")
local SwitchButtonLit_4 = Instance.new("Frame")
local UICorner_28 = Instance.new("UICorner")
local SwitchButtonActivator_4 = Instance.new("TextButton")
local UICorner_29 = Instance.new("UICorner")
local Menu = Instance.new("ScrollingFrame")
local C1_4 = Instance.new("TextLabel")
local UIListLayout_4 = Instance.new("UIListLayout")
local C2_4 = Instance.new("Frame")
local UICorner_30 = Instance.new("UICorner")
local Text_5 = Instance.new("TextLabel")
local UICorner_31 = Instance.new("UICorner")
local SwitchFrame_5 = Instance.new("Frame")
local UICorner_32 = Instance.new("UICorner")
local SwitchButtonActivator_5 = Instance.new("TextButton")
local UICorner_33 = Instance.new("UICorner")
local C3_4 = Instance.new("Frame")
local UICorner_34 = Instance.new("UICorner")
local Text_6 = Instance.new("TextLabel")
local UICorner_35 = Instance.new("UICorner")
local SwitchFrame_6 = Instance.new("Frame")
local UICorner_36 = Instance.new("UICorner")
local SwitchButtonActivator_6 = Instance.new("TextButton")
local UICorner_37 = Instance.new("UICorner")
local C4_3 = Instance.new("Frame")
local UICorner_38 = Instance.new("UICorner")
local Text_7 = Instance.new("TextLabel")
local UICorner_39 = Instance.new("UICorner")
local SwitchFrame_7 = Instance.new("Frame")
local UICorner_40 = Instance.new("UICorner")
local SwitchButtonActivator_7 = Instance.new("TextButton")
local UICorner_41 = Instance.new("UICorner")
local TopFrame = Instance.new("Frame")
local UICorner_42 = Instance.new("UICorner")
local Title = Instance.new("TextLabel")
local Minimize = Instance.new("TextButton")
local Menu_2 = Instance.new("TextButton")

local function ClonedService(name)
    local Service = (game.GetService);
	local Reference = (cloneref) or function(reference) return reference end
	return Reference(Service(game, name));
end

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

CCAimbotV2.Name = math.random(1,99999999)
protectUI(CCAimbotV2)
CCAimbotV2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

MainFrame.Name = "MainFrame"
MainFrame.Parent = CCAimbotV2
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BackgroundTransparency = 1.000
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 195, 0, 160)

BottomFrame.Name = "BottomFrame"
BottomFrame.Parent = MainFrame
BottomFrame.AnchorPoint = Vector2.new(0.5, 0.5)
BottomFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
BottomFrame.BorderSizePixel = 0
BottomFrame.ClipsDescendants = true
BottomFrame.Position = UDim2.new(0.5, 0, -1.5, 0)
BottomFrame.Size = UDim2.new(1, 0, 1, 0)

UICorner.CornerRadius = UDim.new(0, 5)
UICorner.Parent = BottomFrame

Page3.Name = "Page3"
Page3.Parent = BottomFrame
Page3.Active = true
Page3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Page3.BackgroundTransparency = 1.000
Page3.BorderColor3 = Color3.fromRGB(27, 42, 53)
Page3.BorderSizePixel = 0
Page3.Position = UDim2.new(1.10000002, 0, 0.169, 0)
Page3.Size = UDim2.new(1, 0, 0.829999983, 0)
Page3.CanvasSize = UDim2.new(0, 0, 0.5, 0)
Page3.ScrollBarThickness = 3

C1.Name = "C1"
C1.Parent = Page3
C1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
C1.BackgroundTransparency = 1.000
C1.BorderSizePixel = 0
C1.ClipsDescendants = true
C1.Position = UDim2.new(0.0307692308, 0, 0, 0)
C1.Size = UDim2.new(0, 183, 0, 20)
C1.Font = Enum.Font.GothamBold
C1.Text = "Player"
C1.TextColor3 = Color3.fromRGB(255, 255, 255)
C1.TextScaled = true
C1.TextSize = 14.000
C1.TextWrapped = true
C1.TextXAlignment = Enum.TextXAlignment.Left

UIListLayout.Parent = Page3
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.Padding = UDim.new(0.0299999993, 0)

C2.Name = "C2"
C2.Parent = Page3
C2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
C2.BorderSizePixel = 0
C2.Position = UDim2.new(0.0307692308, 0, 0.585116267, 0)
C2.Selectable = true
C2.Size = UDim2.new(0, 183, 0, 31)

UICorner_2.CornerRadius = UDim.new(0, 5)
UICorner_2.Parent = C2

Text.Name = "Text"
Text.Parent = C2
Text.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Text.BorderSizePixel = 0
Text.ClipsDescendants = true
Text.Position = UDim2.new(0.322404385, 0, 0, 0)
Text.Size = UDim2.new(0.677595615, 0, 1, 0)
Text.Font = Enum.Font.GothamBold
Text.Text = "Fly"
Text.TextColor3 = Color3.fromRGB(255, 255, 255)
Text.TextSize = 15.000
Text.TextWrapped = true
Text.TextXAlignment = Enum.TextXAlignment.Left

UICorner_3.CornerRadius = UDim.new(0, 5)
UICorner_3.Parent = Text

SwitchFrame.Name = "SwitchFrame"
SwitchFrame.Parent = C2
SwitchFrame.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SwitchFrame.BorderSizePixel = 0
SwitchFrame.Position = UDim2.new(0.150000006, 0, 0.5, 0)
SwitchFrame.Size = UDim2.new(0.248549104, 0, 0.73299998, 0)

UICorner_4.CornerRadius = UDim.new(0, 5)
UICorner_4.Parent = SwitchFrame

SwitchButton.Name = "SwitchButton"
SwitchButton.Parent = SwitchFrame
SwitchButton.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButton.BackgroundColor3 = Color3.fromRGB(255, 71, 71)
SwitchButton.BorderSizePixel = 0
SwitchButton.Position = UDim2.new(0.239999995, 0, 0.5, 0)
SwitchButton.Size = UDim2.new(0.379000008, 0, 0.758000016, 0)

UICorner_5.CornerRadius = UDim.new(0, 5)
UICorner_5.Parent = SwitchButton

SwitchButtonLit.Name = "SwitchButtonLit"
SwitchButtonLit.Parent = SwitchButton
SwitchButtonLit.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButtonLit.BackgroundColor3 = Color3.fromRGB(101, 255, 90)
SwitchButtonLit.BackgroundTransparency = 1.000
SwitchButtonLit.BorderColor3 = Color3.fromRGB(27, 42, 53)
SwitchButtonLit.BorderSizePixel = 0
SwitchButtonLit.Position = UDim2.new(0.5, 0, 0.5, 0)
SwitchButtonLit.Size = UDim2.new(1, 0, 1, 0)

UICorner_6.CornerRadius = UDim.new(0, 5)
UICorner_6.Parent = SwitchButtonLit

SwitchButtonActivator.Name = "SwitchButtonActivator"
SwitchButtonActivator.Parent = SwitchFrame
SwitchButtonActivator.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButtonActivator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SwitchButtonActivator.BackgroundTransparency = 1.000
SwitchButtonActivator.BorderSizePixel = 0
SwitchButtonActivator.Position = UDim2.new(0.5, 0, 0.5, 0)
SwitchButtonActivator.Size = UDim2.new(1, 0, 1, 0)
SwitchButtonActivator.Font = Enum.Font.Gotham
SwitchButtonActivator.Text = ""
SwitchButtonActivator.TextColor3 = Color3.fromRGB(255, 255, 255)
SwitchButtonActivator.TextSize = 12.000

UICorner_7.CornerRadius = UDim.new(0, 5)
UICorner_7.Parent = SwitchButtonActivator

C3.Name = "C3"
C3.Parent = Page3
C3.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
C3.BorderSizePixel = 0
C3.Position = UDim2.new(0.0307692308, 0, 0.585116267, 0)
C3.Selectable = true
C3.Size = UDim2.new(0, 183, 0, 31)

UICorner_8.CornerRadius = UDim.new(0, 5)
UICorner_8.Parent = C3

Text_2.Name = "Text"
Text_2.Parent = C3
Text_2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Text_2.BorderSizePixel = 0
Text_2.ClipsDescendants = true
Text_2.Position = UDim2.new(0.322404385, 0, 0, 0)
Text_2.Size = UDim2.new(0.677595615, 0, 1, 0)
Text_2.Font = Enum.Font.GothamBold
Text_2.Text = "Noclip"
Text_2.TextColor3 = Color3.fromRGB(255, 255, 255)
Text_2.TextSize = 15.000
Text_2.TextWrapped = true
Text_2.TextXAlignment = Enum.TextXAlignment.Left

UICorner_9.CornerRadius = UDim.new(0, 5)
UICorner_9.Parent = Text_2

SwitchFrame_2.Name = "SwitchFrame"
SwitchFrame_2.Parent = C3
SwitchFrame_2.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchFrame_2.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SwitchFrame_2.BorderSizePixel = 0
SwitchFrame_2.Position = UDim2.new(0.150000006, 0, 0.5, 0)
SwitchFrame_2.Size = UDim2.new(0.248549104, 0, 0.73299998, 0)

UICorner_10.CornerRadius = UDim.new(0, 5)
UICorner_10.Parent = SwitchFrame_2

SwitchButton_2.Name = "SwitchButton"
SwitchButton_2.Parent = SwitchFrame_2
SwitchButton_2.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButton_2.BackgroundColor3 = Color3.fromRGB(255, 71, 71)
SwitchButton_2.BorderSizePixel = 0
SwitchButton_2.Position = UDim2.new(0.239999995, 0, 0.5, 0)
SwitchButton_2.Size = UDim2.new(0.379000008, 0, 0.758000016, 0)

UICorner_11.CornerRadius = UDim.new(0, 5)
UICorner_11.Parent = SwitchButton_2

SwitchButtonLit_2.Name = "SwitchButtonLit"
SwitchButtonLit_2.Parent = SwitchButton_2
SwitchButtonLit_2.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButtonLit_2.BackgroundColor3 = Color3.fromRGB(101, 255, 90)
SwitchButtonLit_2.BackgroundTransparency = 1.000
SwitchButtonLit_2.BorderColor3 = Color3.fromRGB(27, 42, 53)
SwitchButtonLit_2.BorderSizePixel = 0
SwitchButtonLit_2.Position = UDim2.new(0.5, 0, 0.5, 0)
SwitchButtonLit_2.Size = UDim2.new(1, 0, 1, 0)

UICorner_12.CornerRadius = UDim.new(0, 5)
UICorner_12.Parent = SwitchButtonLit_2

SwitchButtonActivator_2.Name = "SwitchButtonActivator"
SwitchButtonActivator_2.Parent = SwitchFrame_2
SwitchButtonActivator_2.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButtonActivator_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SwitchButtonActivator_2.BackgroundTransparency = 1.000
SwitchButtonActivator_2.BorderSizePixel = 0
SwitchButtonActivator_2.Position = UDim2.new(0.5, 0, 0.5, 0)
SwitchButtonActivator_2.Size = UDim2.new(1, 0, 1, 0)
SwitchButtonActivator_2.Font = Enum.Font.Gotham
SwitchButtonActivator_2.Text = ""
SwitchButtonActivator_2.TextColor3 = Color3.fromRGB(255, 255, 255)
SwitchButtonActivator_2.TextSize = 12.000

UICorner_13.CornerRadius = UDim.new(0, 5)
UICorner_13.Parent = SwitchButtonActivator_2

C4.Name = "C4"
C4.Parent = Page3
C4.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
C4.BorderSizePixel = 0
C4.Position = UDim2.new(0.0307692308, 0, 0.585116267, 0)
C4.Selectable = true
C4.Size = UDim2.new(0, 183, 0, 31)

UICorner_14.CornerRadius = UDim.new(0, 5)
UICorner_14.Parent = C4

Text_3.Name = "Text"
Text_3.Parent = C4
Text_3.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Text_3.BorderSizePixel = 0
Text_3.ClipsDescendants = true
Text_3.Position = UDim2.new(0.322404385, 0, 0, 0)
Text_3.Size = UDim2.new(0.677595615, 0, 1, 0)
Text_3.Font = Enum.Font.GothamBold
Text_3.Text = "Infinite Jump"
Text_3.TextColor3 = Color3.fromRGB(255, 255, 255)
Text_3.TextSize = 15.000
Text_3.TextWrapped = true
Text_3.TextXAlignment = Enum.TextXAlignment.Left

UICorner_15.CornerRadius = UDim.new(0, 5)
UICorner_15.Parent = Text_3

SwitchFrame_3.Name = "SwitchFrame"
SwitchFrame_3.Parent = C4
SwitchFrame_3.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchFrame_3.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SwitchFrame_3.BorderSizePixel = 0
SwitchFrame_3.Position = UDim2.new(0.150000006, 0, 0.5, 0)
SwitchFrame_3.Size = UDim2.new(0.248549104, 0, 0.73299998, 0)

UICorner_16.CornerRadius = UDim.new(0, 5)
UICorner_16.Parent = SwitchFrame_3

SwitchButton_3.Name = "SwitchButton"
SwitchButton_3.Parent = SwitchFrame_3
SwitchButton_3.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButton_3.BackgroundColor3 = Color3.fromRGB(255, 71, 71)
SwitchButton_3.BorderSizePixel = 0
SwitchButton_3.Position = UDim2.new(0.239999995, 0, 0.5, 0)
SwitchButton_3.Size = UDim2.new(0.379000008, 0, 0.758000016, 0)

UICorner_17.CornerRadius = UDim.new(0, 5)
UICorner_17.Parent = SwitchButton_3

SwitchButtonLit_3.Name = "SwitchButtonLit"
SwitchButtonLit_3.Parent = SwitchButton_3
SwitchButtonLit_3.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButtonLit_3.BackgroundColor3 = Color3.fromRGB(101, 255, 90)
SwitchButtonLit_3.BackgroundTransparency = 1.000
SwitchButtonLit_3.BorderColor3 = Color3.fromRGB(27, 42, 53)
SwitchButtonLit_3.BorderSizePixel = 0
SwitchButtonLit_3.Position = UDim2.new(0.5, 0, 0.5, 0)
SwitchButtonLit_3.Size = UDim2.new(1, 0, 1, 0)

UICorner_18.CornerRadius = UDim.new(0, 5)
UICorner_18.Parent = SwitchButtonLit_3

SwitchButtonActivator_3.Name = "SwitchButtonActivator"
SwitchButtonActivator_3.Parent = SwitchFrame_3
SwitchButtonActivator_3.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButtonActivator_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SwitchButtonActivator_3.BackgroundTransparency = 1.000
SwitchButtonActivator_3.BorderSizePixel = 0
SwitchButtonActivator_3.Position = UDim2.new(0.5, 0, 0.5, 0)
SwitchButtonActivator_3.Size = UDim2.new(1, 0, 1, 0)
SwitchButtonActivator_3.Font = Enum.Font.Gotham
SwitchButtonActivator_3.Text = ""
SwitchButtonActivator_3.TextColor3 = Color3.fromRGB(255, 255, 255)
SwitchButtonActivator_3.TextSize = 12.000

UICorner_19.CornerRadius = UDim.new(0, 5)
UICorner_19.Parent = SwitchButtonActivator_3

Page1.Name = "Page1"
Page1.Parent = BottomFrame
Page1.Active = true
Page1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Page1.BackgroundTransparency = 1.000
Page1.BorderColor3 = Color3.fromRGB(27, 42, 53)
Page1.BorderSizePixel = 0
Page1.Position = UDim2.new(0, 0, 0.169, 0)
Page1.Size = UDim2.new(1, 0, 0.829999983, 0)
Page1.CanvasSize = UDim2.new(0, 0, 0.5, 0)
Page1.ScrollBarThickness = 3

C1_2.Name = "C1"
C1_2.Parent = Page1
C1_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
C1_2.BackgroundTransparency = 1.000
C1_2.BorderSizePixel = 0
C1_2.ClipsDescendants = true
C1_2.Position = UDim2.new(0.0307692308, 0, 0, 0)
C1_2.Size = UDim2.new(0, 183, 0, 20)
C1_2.Font = Enum.Font.GothamBold
C1_2.Text = "Aimbot"
C1_2.TextColor3 = Color3.fromRGB(255, 255, 255)
C1_2.TextScaled = true
C1_2.TextSize = 14.000
C1_2.TextWrapped = true
C1_2.TextXAlignment = Enum.TextXAlignment.Left

C2_2.Name = "C2"
C2_2.Parent = Page1
C2_2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
C2_2.BorderSizePixel = 0
C2_2.ClipsDescendants = true
C2_2.Position = UDim2.new(0.0307692308, 0, 0, 0)
C2_2.Size = UDim2.new(0, 183, 0, 20)
C2_2.Font = Enum.Font.GothamBold
C2_2.Text = "Press E to Lock into Someone"
C2_2.TextColor3 = Color3.fromRGB(255, 255, 255)
C2_2.TextSize = 12.000
C2_2.TextWrapped = true
C2_2.TextXAlignment = Enum.TextXAlignment.Left

UICorner_20.CornerRadius = UDim.new(0, 5)
UICorner_20.Parent = C2_2

C3_2.Name = "C3"
C3_2.Parent = Page1
C3_2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
C3_2.BorderSizePixel = 0
C3_2.ClipsDescendants = true
C3_2.Position = UDim2.new(0.0307692308, 0, 0, 0)
C3_2.Size = UDim2.new(0, 183, 0, 20)
C3_2.Font = Enum.Font.GothamBold
C3_2.Text = "Press U to toggle Team-Check"
C3_2.TextColor3 = Color3.fromRGB(255, 255, 255)
C3_2.TextSize = 12.000
C3_2.TextWrapped = true
C3_2.TextXAlignment = Enum.TextXAlignment.Left

UICorner_21.CornerRadius = UDim.new(0, 5)
UICorner_21.Parent = C3_2

C4_2.Name = "C4"
C4_2.Parent = Page1
C4_2.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
C4_2.BorderSizePixel = 0
C4_2.ClipsDescendants = true
C4_2.Position = UDim2.new(0.0307692308, 0, 0, 0)
C4_2.Size = UDim2.new(0, 183, 0, 20)
C4_2.Font = Enum.Font.GothamBold
C4_2.Text = "Team-Check : true"
C4_2.TextColor3 = Color3.fromRGB(255, 255, 255)
C4_2.TextSize = 12.000
C4_2.TextWrapped = true

UICorner_22.CornerRadius = UDim.new(0, 5)
UICorner_22.Parent = C4_2

UIListLayout_2.Parent = Page1
UIListLayout_2.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout_2.Padding = UDim.new(0.0399999991, 0)

Page2.Name = "Page2"
Page2.Parent = BottomFrame
Page2.Active = true
Page2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Page2.BackgroundTransparency = 1.000
Page2.BorderColor3 = Color3.fromRGB(27, 42, 53)
Page2.BorderSizePixel = 0
Page2.Position = UDim2.new(1.10000002, 0, 0.169, 0)
Page2.Size = UDim2.new(1, 0, 0.829999983, 0)
Page2.CanvasSize = UDim2.new(0, 0, 0.5, 0)
Page2.ScrollBarThickness = 3

C1_3.Name = "C1"
C1_3.Parent = Page2
C1_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
C1_3.BackgroundTransparency = 1.000
C1_3.BorderSizePixel = 0
C1_3.ClipsDescendants = true
C1_3.Position = UDim2.new(0.0307692308, 0, 0, 0)
C1_3.Size = UDim2.new(0, 183, 0, 20)
C1_3.Font = Enum.Font.GothamBold
C1_3.Text = "Visuals"
C1_3.TextColor3 = Color3.fromRGB(255, 255, 255)
C1_3.TextScaled = true
C1_3.TextSize = 14.000
C1_3.TextWrapped = true
C1_3.TextXAlignment = Enum.TextXAlignment.Left

C3_3.Name = "C3"
C3_3.Parent = Page2
C3_3.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
C3_3.BorderSizePixel = 0
C3_3.ClipsDescendants = true
C3_3.Position = UDim2.new(0.0307692308, 0, 0, 0)
C3_3.Size = UDim2.new(0, 183, 0, 20)
C3_3.Font = Enum.Font.GothamBold
C3_3.Text = "Press T to Refresh ESP"
C3_3.TextColor3 = Color3.fromRGB(255, 255, 255)
C3_3.TextSize = 12.000
C3_3.TextWrapped = true
C3_3.TextXAlignment = Enum.TextXAlignment.Left

UICorner_23.CornerRadius = UDim.new(0, 5)
UICorner_23.Parent = C3_3

UIListLayout_3.Parent = Page2
UIListLayout_3.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout_3.Padding = UDim.new(0.0399999991, 0)

C2_3.Name = "C2"
C2_3.Parent = Page2
C2_3.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
C2_3.BorderSizePixel = 0
C2_3.Position = UDim2.new(0.0307692308, 0, 0.585116267, 0)
C2_3.Selectable = true
C2_3.Size = UDim2.new(0, 183, 0, 31)

UICorner_24.CornerRadius = UDim.new(0, 5)
UICorner_24.Parent = C2_3

Text_4.Name = "Text"
Text_4.Parent = C2_3
Text_4.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Text_4.BorderSizePixel = 0
Text_4.ClipsDescendants = true
Text_4.Position = UDim2.new(0.322404385, 0, 0, 0)
Text_4.Size = UDim2.new(0.677595615, 0, 1, 0)
Text_4.Font = Enum.Font.GothamBold
Text_4.Text = "ESP"
Text_4.TextColor3 = Color3.fromRGB(255, 255, 255)
Text_4.TextSize = 15.000
Text_4.TextWrapped = true
Text_4.TextXAlignment = Enum.TextXAlignment.Left

UICorner_25.CornerRadius = UDim.new(0, 5)
UICorner_25.Parent = Text_4

SwitchFrame_4.Name = "SwitchFrame"
SwitchFrame_4.Parent = C2_3
SwitchFrame_4.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchFrame_4.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SwitchFrame_4.BorderSizePixel = 0
SwitchFrame_4.Position = UDim2.new(0.150000006, 0, 0.5, 0)
SwitchFrame_4.Size = UDim2.new(0.248549104, 0, 0.73299998, 0)

UICorner_26.CornerRadius = UDim.new(0, 5)
UICorner_26.Parent = SwitchFrame_4

SwitchButton_4.Name = "SwitchButton"
SwitchButton_4.Parent = SwitchFrame_4
SwitchButton_4.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButton_4.BackgroundColor3 = Color3.fromRGB(255, 71, 71)
SwitchButton_4.BorderSizePixel = 0
SwitchButton_4.Position = UDim2.new(0.239999995, 0, 0.5, 0)
SwitchButton_4.Size = UDim2.new(0.379000008, 0, 0.758000016, 0)

UICorner_27.CornerRadius = UDim.new(0, 5)
UICorner_27.Parent = SwitchButton_4

SwitchButtonLit_4.Name = "SwitchButtonLit"
SwitchButtonLit_4.Parent = SwitchButton_4
SwitchButtonLit_4.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButtonLit_4.BackgroundColor3 = Color3.fromRGB(101, 255, 90)
SwitchButtonLit_4.BackgroundTransparency = 1.000
SwitchButtonLit_4.BorderColor3 = Color3.fromRGB(27, 42, 53)
SwitchButtonLit_4.BorderSizePixel = 0
SwitchButtonLit_4.Position = UDim2.new(0.5, 0, 0.5, 0)
SwitchButtonLit_4.Size = UDim2.new(1, 0, 1, 0)

UICorner_28.CornerRadius = UDim.new(0, 5)
UICorner_28.Parent = SwitchButtonLit_4

SwitchButtonActivator_4.Name = "SwitchButtonActivator"
SwitchButtonActivator_4.Parent = SwitchFrame_4
SwitchButtonActivator_4.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButtonActivator_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SwitchButtonActivator_4.BackgroundTransparency = 1.000
SwitchButtonActivator_4.BorderSizePixel = 0
SwitchButtonActivator_4.Position = UDim2.new(0.5, 0, 0.5, 0)
SwitchButtonActivator_4.Size = UDim2.new(1, 0, 1, 0)
SwitchButtonActivator_4.Font = Enum.Font.Gotham
SwitchButtonActivator_4.Text = ""
SwitchButtonActivator_4.TextColor3 = Color3.fromRGB(255, 255, 255)
SwitchButtonActivator_4.TextSize = 12.000

UICorner_29.CornerRadius = UDim.new(0, 5)
UICorner_29.Parent = SwitchButtonActivator_4

Menu.Name = "Menu"
Menu.Parent = BottomFrame
Menu.Active = true
Menu.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Menu.BackgroundTransparency = 1.000
Menu.BorderColor3 = Color3.fromRGB(27, 42, 53)
Menu.BorderSizePixel = 0
Menu.Position = UDim2.new(1.10000002, 0, 0.169, 0)
Menu.Size = UDim2.new(1, 0, 0.829999983, 0)
Menu.CanvasSize = UDim2.new(0, 0, 0.5, 0)
Menu.ScrollBarThickness = 3

C1_4.Name = "C1"
C1_4.Parent = Menu
C1_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
C1_4.BackgroundTransparency = 1.000
C1_4.BorderSizePixel = 0
C1_4.ClipsDescendants = true
C1_4.Position = UDim2.new(0.0307692308, 0, 0, 0)
C1_4.Size = UDim2.new(0, 183, 0, 20)
C1_4.Font = Enum.Font.GothamBold
C1_4.Text = "Menu"
C1_4.TextColor3 = Color3.fromRGB(255, 255, 255)
C1_4.TextScaled = true
C1_4.TextSize = 14.000
C1_4.TextWrapped = true
C1_4.TextXAlignment = Enum.TextXAlignment.Left

UIListLayout_4.Parent = Menu
UIListLayout_4.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout_4.Padding = UDim.new(0.0299999993, 0)

C2_4.Name = "C2"
C2_4.Parent = Menu
C2_4.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
C2_4.BorderSizePixel = 0
C2_4.Position = UDim2.new(0, 0, 0.607706606, 0)
C2_4.Selectable = true
C2_4.Size = UDim2.new(0, 183, 0, 31)

UICorner_30.CornerRadius = UDim.new(0, 5)
UICorner_30.Parent = C2_4

Text_5.Name = "Text"
Text_5.Parent = C2_4
Text_5.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Text_5.BorderSizePixel = 0
Text_5.ClipsDescendants = true
Text_5.Position = UDim2.new(0.191256836, 0, 0, 0)
Text_5.Size = UDim2.new(0.808743179, 0, 1, 0)
Text_5.Font = Enum.Font.GothamBold
Text_5.Text = "Aimbot"
Text_5.TextColor3 = Color3.fromRGB(255, 255, 255)
Text_5.TextSize = 15.000
Text_5.TextWrapped = true
Text_5.TextXAlignment = Enum.TextXAlignment.Left

UICorner_31.CornerRadius = UDim.new(0, 5)
UICorner_31.Parent = Text_5

SwitchFrame_5.Name = "SwitchFrame"
SwitchFrame_5.Parent = C2_4
SwitchFrame_5.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchFrame_5.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SwitchFrame_5.BorderSizePixel = 0
SwitchFrame_5.Position = UDim2.new(0.0879999995, 0, 0.5, 0)
SwitchFrame_5.Size = UDim2.new(0.125, 0, 0.73299998, 0)

UICorner_32.CornerRadius = UDim.new(0, 5)
UICorner_32.Parent = SwitchFrame_5

SwitchButtonActivator_5.Name = "SwitchButtonActivator"
SwitchButtonActivator_5.Parent = SwitchFrame_5
SwitchButtonActivator_5.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButtonActivator_5.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SwitchButtonActivator_5.BackgroundTransparency = 1.000
SwitchButtonActivator_5.BorderSizePixel = 0
SwitchButtonActivator_5.Position = UDim2.new(0.5, 0, 0.5, 0)
SwitchButtonActivator_5.Size = UDim2.new(1, 0, 1, 0)
SwitchButtonActivator_5.Font = Enum.Font.Gotham
SwitchButtonActivator_5.Text = "<"
SwitchButtonActivator_5.TextColor3 = Color3.fromRGB(255, 255, 255)
SwitchButtonActivator_5.TextSize = 14.000

UICorner_33.CornerRadius = UDim.new(0, 5)
UICorner_33.Parent = SwitchButtonActivator_5

C3_4.Name = "C3"
C3_4.Parent = Menu
C3_4.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
C3_4.BorderSizePixel = 0
C3_4.Position = UDim2.new(0, 0, 0.607706606, 0)
C3_4.Selectable = true
C3_4.Size = UDim2.new(0, 183, 0, 31)

UICorner_34.CornerRadius = UDim.new(0, 5)
UICorner_34.Parent = C3_4

Text_6.Name = "Text"
Text_6.Parent = C3_4
Text_6.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Text_6.BorderSizePixel = 0
Text_6.ClipsDescendants = true
Text_6.Position = UDim2.new(0.191256836, 0, 0, 0)
Text_6.Size = UDim2.new(0.808743179, 0, 1, 0)
Text_6.Font = Enum.Font.GothamBold
Text_6.Text = "Visuals"
Text_6.TextColor3 = Color3.fromRGB(255, 255, 255)
Text_6.TextSize = 15.000
Text_6.TextWrapped = true
Text_6.TextXAlignment = Enum.TextXAlignment.Left

UICorner_35.CornerRadius = UDim.new(0, 5)
UICorner_35.Parent = Text_6

SwitchFrame_6.Name = "SwitchFrame"
SwitchFrame_6.Parent = C3_4
SwitchFrame_6.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchFrame_6.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SwitchFrame_6.BorderSizePixel = 0
SwitchFrame_6.Position = UDim2.new(0.0879999995, 0, 0.5, 0)
SwitchFrame_6.Size = UDim2.new(0.125, 0, 0.73299998, 0)

UICorner_36.CornerRadius = UDim.new(0, 5)
UICorner_36.Parent = SwitchFrame_6

SwitchButtonActivator_6.Name = "SwitchButtonActivator"
SwitchButtonActivator_6.Parent = SwitchFrame_6
SwitchButtonActivator_6.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButtonActivator_6.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SwitchButtonActivator_6.BackgroundTransparency = 1.000
SwitchButtonActivator_6.BorderSizePixel = 0
SwitchButtonActivator_6.Position = UDim2.new(0.5, 0, 0.5, 0)
SwitchButtonActivator_6.Size = UDim2.new(1, 0, 1, 0)
SwitchButtonActivator_6.Font = Enum.Font.Gotham
SwitchButtonActivator_6.Text = "<"
SwitchButtonActivator_6.TextColor3 = Color3.fromRGB(255, 255, 255)
SwitchButtonActivator_6.TextSize = 14.000

UICorner_37.CornerRadius = UDim.new(0, 5)
UICorner_37.Parent = SwitchButtonActivator_6

C4_3.Name = "C4"
C4_3.Parent = Menu
C4_3.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
C4_3.BorderSizePixel = 0
C4_3.Position = UDim2.new(0, 0, 0.607706606, 0)
C4_3.Selectable = true
C4_3.Size = UDim2.new(0, 183, 0, 31)

UICorner_38.CornerRadius = UDim.new(0, 5)
UICorner_38.Parent = C4_3

Text_7.Name = "Text"
Text_7.Parent = C4_3
Text_7.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Text_7.BorderSizePixel = 0
Text_7.ClipsDescendants = true
Text_7.Position = UDim2.new(0.191256836, 0, 0, 0)
Text_7.Size = UDim2.new(0.808743179, 0, 1, 0)
Text_7.Font = Enum.Font.GothamBold
Text_7.Text = "Player"
Text_7.TextColor3 = Color3.fromRGB(255, 255, 255)
Text_7.TextSize = 15.000
Text_7.TextWrapped = true
Text_7.TextXAlignment = Enum.TextXAlignment.Left

UICorner_39.CornerRadius = UDim.new(0, 5)
UICorner_39.Parent = Text_7

SwitchFrame_7.Name = "SwitchFrame"
SwitchFrame_7.Parent = C4_3
SwitchFrame_7.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchFrame_7.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SwitchFrame_7.BorderSizePixel = 0
SwitchFrame_7.Position = UDim2.new(0.0879999995, 0, 0.5, 0)
SwitchFrame_7.Size = UDim2.new(0.125, 0, 0.73299998, 0)

UICorner_40.CornerRadius = UDim.new(0, 5)
UICorner_40.Parent = SwitchFrame_7

SwitchButtonActivator_7.Name = "SwitchButtonActivator"
SwitchButtonActivator_7.Parent = SwitchFrame_7
SwitchButtonActivator_7.AnchorPoint = Vector2.new(0.5, 0.5)
SwitchButtonActivator_7.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SwitchButtonActivator_7.BackgroundTransparency = 1.000
SwitchButtonActivator_7.BorderSizePixel = 0
SwitchButtonActivator_7.Position = UDim2.new(0.5, 0, 0.5, 0)
SwitchButtonActivator_7.Size = UDim2.new(1, 0, 1, 0)
SwitchButtonActivator_7.Font = Enum.Font.Gotham
SwitchButtonActivator_7.Text = "<"
SwitchButtonActivator_7.TextColor3 = Color3.fromRGB(255, 255, 255)
SwitchButtonActivator_7.TextSize = 14.000

UICorner_41.CornerRadius = UDim.new(0, 5)
UICorner_41.Parent = SwitchButtonActivator_7

TopFrame.Name = "TopFrame"
TopFrame.Parent = MainFrame
TopFrame.AnchorPoint = Vector2.new(0.5, 0)
TopFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
TopFrame.BorderSizePixel = 0
TopFrame.ClipsDescendants = true
TopFrame.Size = UDim2.new(0, 0, 0, 25)

UICorner_42.CornerRadius = UDim.new(0, 5)
UICorner_42.Parent = TopFrame

Title.Name = "Title"
Title.Parent = TopFrame
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1.000
Title.BorderSizePixel = 0
Title.ClipsDescendants = true
Title.Position = UDim2.new(0.0350000001, 0, 0, 0)
Title.Size = UDim2.new(0.430769295, 0, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "CC Aimbot"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14.000
Title.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
Title.TextWrapped = true
Title.TextXAlignment = Enum.TextXAlignment.Left

Minimize.Name = "Minimize"
Minimize.Parent = TopFrame
Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Minimize.BackgroundTransparency = 1.000
Minimize.BorderSizePixel = 0
Minimize.Position = UDim2.new(0.902564108, 0, 0, 0)
Minimize.Size = UDim2.new(-0.0307692308, 25, 1, 0)
Minimize.Selected = true
Minimize.Font = Enum.Font.Gotham
Minimize.Text = "-"
Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
Minimize.TextScaled = true
Minimize.TextSize = 14.000
Minimize.TextWrapped = true

Menu_2.Name = "Menu"
Menu_2.Parent = TopFrame
Menu_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Menu_2.BackgroundTransparency = 1.000
Menu_2.BorderSizePixel = 0
Menu_2.Position = UDim2.new(0.805128217, 0, 0, 0)
Menu_2.Size = UDim2.new(-0.0307692308, 25, 1, 0)
Menu_2.Selected = true
Menu_2.Font = Enum.Font.GothamBold
Menu_2.Text = "v"
Menu_2.TextColor3 = Color3.fromRGB(255, 255, 255)
Menu_2.TextSize = 14.000
Menu_2.TextWrapped = true

local function DIPONU_fake_script() -- SwitchFrame.SwitchButtonSystem 
	local script = Instance.new('LocalScript', SwitchFrame)

	flying = false
	lplayer = ClonedService("Players").LocalPlayer
	speedget = 1
	speedfly = 1
	Mouse = lplayer:GetMouse()
	-- Switches --
	local TweenService = ClonedService("TweenService")
	local time = 0.5 --this will tell you how much it would take for the tween to finish
	-- ColorFade --
	local SwitchButtonFade = TweenService:Create(script.Parent.SwitchButton, TweenInfo.new(time), {BackgroundTransparency = 0})
	local SwitchButtonFadeOut = TweenService:Create(script.Parent.SwitchButton, TweenInfo.new(time), {BackgroundTransparency = 1})
	local SwitchButtonLitFade = TweenService:Create(script.Parent.SwitchButton.SwitchButtonLit, TweenInfo.new(time), {BackgroundTransparency = 0})
	local SwitchButtonLitFadeOut = TweenService:Create(script.Parent.SwitchButton.SwitchButtonLit, TweenInfo.new(time), {BackgroundTransparency = 1})
	
	local Toggle = false
	
	script.Parent.SwitchButtonActivator.MouseButton1Click:connect(function()
		if flying == false then
			flying = true
			script.Parent.SwitchButton:TweenPosition(UDim2.new(0.775,0,0.5,0), "Out", "Quad", 0.5, true)
			SwitchButtonFadeOut:Play()
			SwitchButtonLitFade:Play()
			repeat wait() until lplayer and lplayer.Character and lplayer.Character:FindFirstChild('HumanoidRootPart') and lplayer.Character:FindFirstChild('Humanoid')
			repeat wait() until Mouse
	
			local T = lplayer.Character.HumanoidRootPart
			local CONTROL = {F = 0, B = 0, L = 0, R = 0}
			local lCONTROL = {F = 0, B = 0, L = 0, R = 0}
			local SPEED = speedget
	
			local function fly()
				flying = true
				local BG = Instance.new('BodyGyro', T)
				local BV = Instance.new('BodyVelocity', T)
				BG.P = 9e4
				BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
				BG.cframe = T.CFrame
				BV.velocity = Vector3.new(0, 0.1, 0)
				BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
				spawn(function()
					repeat wait()
						lplayer.Character.Humanoid.PlatformStand = true
						if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 then
							SPEED = 50
						elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0) and SPEED ~= 0 then
							SPEED = 0
						end
						if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 then
							BV.velocity = ((ClonedService("Workspace").CurrentCamera.CoordinateFrame.lookVector * (CONTROL.F + CONTROL.B)) + ((ClonedService("Workspace").CurrentCamera.CoordinateFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B) * 0.2, 0).p) - ClonedService("Workspace").CurrentCamera.CoordinateFrame.p)) * SPEED
							lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
						elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and SPEED ~= 0 then
							BV.velocity = ((ClonedService("Workspace").CurrentCamera.CoordinateFrame.lookVector * (lCONTROL.F + lCONTROL.B)) + ((ClonedService("Workspace").CurrentCamera.CoordinateFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B) * 0.2, 0).p) - ClonedService("Workspace").CurrentCamera.CoordinateFrame.p)) * SPEED
						else
							BV.velocity = Vector3.new(0, 0.1, 0)
						end
						BG.cframe = ClonedService("Workspace").CurrentCamera.CoordinateFrame
					until not flying
					CONTROL = {F = 0, B = 0, L = 0, R = 0}
					lCONTROL = {F = 0, B = 0, L = 0, R = 0}
					SPEED = 0
					BG:destroy()
					BV:destroy()
					lplayer.Character.Humanoid.PlatformStand = false
				end)
			end
			Mouse.KeyDown:connect(function(KEY)
				if KEY:lower() == 'w' then
					CONTROL.F = speedfly
				elseif KEY:lower() == 's' then
					CONTROL.B = -speedfly
				elseif KEY:lower() == 'a' then
					CONTROL.L = -speedfly 
				elseif KEY:lower() == 'd' then 
					CONTROL.R = speedfly
				end
			end)
			Mouse.KeyUp:connect(function(KEY)
				if KEY:lower() == 'w' then
					CONTROL.F = 0
				elseif KEY:lower() == 's' then
					CONTROL.B = 0
				elseif KEY:lower() == 'a' then
					CONTROL.L = 0
				elseif KEY:lower() == 'd' then
					CONTROL.R = 0
				end
			end)
			fly()
		else
			flying = false
			script.Parent.SwitchButton:TweenPosition(UDim2.new(0.24,0,0.5,0), "Out", "Quad", 0.5, true)
			SwitchButtonFade:Play()
			SwitchButtonLitFadeOut:Play()
			flying = false
			lplayer.Character.Humanoid.PlatformStand = false
		end
	end)
	
	
end
coroutine.wrap(DIPONU_fake_script)()
local function UOOREXU_fake_script() -- SwitchFrame_3.SwitchButtonSystem 
	local script = Instance.new('LocalScript', SwitchFrame_3)

	local InfiniteJump = false
	-- Switches --
	local TweenService = ClonedService("TweenService")
	local time = 0.5 --this will tell you how much it would take for the tween to finish
	-- ColorFade --
	local SwitchButtonFade = TweenService:Create(script.Parent.SwitchButton, TweenInfo.new(time), {BackgroundTransparency = 0})
	local SwitchButtonFadeOut = TweenService:Create(script.Parent.SwitchButton, TweenInfo.new(time), {BackgroundTransparency = 1})
	local SwitchButtonLitFade = TweenService:Create(script.Parent.SwitchButton.SwitchButtonLit, TweenInfo.new(time), {BackgroundTransparency = 0})
	local SwitchButtonLitFadeOut = TweenService:Create(script.Parent.SwitchButton.SwitchButtonLit, TweenInfo.new(time), {BackgroundTransparency = 1})
	
	script.Parent.SwitchButtonActivator.MouseButton1Click:connect(function()
		if InfiniteJump == false then
			InfiniteJump = true
			script.Parent.SwitchButton:TweenPosition(UDim2.new(0.775,0,0.5,0), "Out", "Quad", 0.5, true)
			SwitchButtonFadeOut:Play()
			SwitchButtonLitFade:Play()
		else
			InfiniteJump = false
			script.Parent.SwitchButton:TweenPosition(UDim2.new(0.24,0,0.5,0), "Out", "Quad", 0.5, true)
			SwitchButtonFade:Play()
			SwitchButtonLitFadeOut:Play()
		end
	end)
	
	ClonedService("UserInputService").JumpRequest:connect(function()
		if InfiniteJump == true then
			ClonedService("Players").LocalPlayer.Character:FindFirstChildOfClass'Humanoid':ChangeState("Jumping")
		end
	end)
end
coroutine.wrap(UOOREXU_fake_script)()
local function EGFWXE_fake_script() -- Page1.Aimbot 
	local script = Instance.new('LocalScript', Page1)

	local gui_hide_button = {Enum.KeyCode.LeftControl, "h"}
	local plrs = ClonedService("Players")
	local lplr = ClonedService("Players").LocalPlayer
	local TeamBased = true ; local teambasedswitch = "u"
	local presskeytoaim = true; local aimkey = "e"
	aimbothider = false; aimbothiderspeed = .5
	local Aim_Assist = false ; Aim_Assist_Key = {Enum.KeyCode.LeftControl, "z"}
	local abs = math.abs
	local mouselock = false
	local canaimat = true
	local lockaim = true; local lockangle = 5
	local ver = "2"
	local cam = ClonedService("Workspace").CurrentCamera
	local BetterDeathCount = true
	
	
	local mouse = lplr:GetMouse()
	local switch = false
	local key = "k"
	local aimatpart = nil
	
	-- Scripts:
	local uis = ClonedService("UserInputService")
	local bringall = false
	local hided2 = false
	mouse.KeyDown:Connect(function(a)
		if a == "u" then
			--print("worked1")
			if mouselock == false then
				mouselock = true
			else
				mouselock = false
			end
		elseif a == "y" then
			if aimbothider == false then
				aimbothider = true
				if aimbothider == true then
					return
				end
			end
		elseif a == Aim_Assist_Key[2] and uis:IsKeyDown(Aim_Assist_Key[1]) then
			if Aim_Assist == true then
				Aim_Assist = false
				--print("disabled")
			else
				Aim_Assist = true
			end
		end
		if a == "j" then
			if mouse.Target then
				mouse.Target:Destroy()
			end
		end
		if a == key then
			if switch == false then
				switch = true
			else
				switch = false
				if aimatpart ~= nil then
					aimatpart = nil
				end
			end
		elseif a == teambasedswitch then
			if TeamBased == true then
				TeamBased = false
				script.Parent.C4.Text = "Team-Check : "..tostring(TeamBased)
			else
				TeamBased = true
				script.Parent.C4.Text = "Team-Check : "..tostring(TeamBased)
			end
		elseif a == aimkey then
			if not aimatpart then
				local maxangle = math.rad(20)
				for i, plr in pairs(plrs:GetChildren()) do
					if plr.Name ~= lplr.Name and plr.Character and plr.Character.Head and plr.Character.Humanoid and plr.Character.Humanoid.Health > 1 then
						if TeamBased == true then
							if plr.Team.Name ~= lplr.Team.Name then
								local an = checkfov(plr.Character.Head)
								if an < maxangle then
									maxangle = an
									aimatpart = plr.Character.Head
								end
							end
						else
							local an = checkfov(plr.Character.Head)
							if an < maxangle then
								maxangle = an
								aimatpart = plr.Character.Head
							end
							--print(plr)
						end
						local old = aimatpart
						plr.Character.Humanoid.Died:Connect(function()
							--print("died")
							if aimatpart and aimatpart == old then
								aimatpart = nil
							end
						end)
						
					end
				end
			else
				aimatpart = nil
				canaimat = false
				delay(1.1, function()
					canaimat = true
				end)
			end
		end
	end)
	
	function getfovxyz (p0, p1, deg)
		local x1, y1, z1 = p0:ToOrientation()
		local cf = CFrame.new(p0.p, p1.p)
		local x2, y2, z2 = cf:ToOrientation()
		local d = math.deg
		if deg then
			return Vector3.new(d(x1-x2), d(y1-y2), d(z1-z2))
		else
			return Vector3.new((x1-x2), (y1-y2), (z1-z2))
		end
	end
	
	
	function aimat(part)
		if part then
			if aimbothider == true or Aim_Assist == true then
				cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.p, part.CFrame.p), aimbothiderspeed)
			else
				
				cam.CFrame = CFrame.new(cam.CFrame.p, part.CFrame.p)
			end
		end
	end
	function checkfov (part)
		local fov = getfovxyz(ClonedService("Workspace").CurrentCamera.CFrame, part.CFrame)
		local angle = math.abs(fov.X) + math.abs(fov.Y)
		return angle
	end
	pcall(function()
		delay(0, function()
			while wait(.4) do
				if Aim_Assist and not aimatpart and canaimat and lplr.Character and lplr.Character.Humanoid and lplr.Character.Humanoid.Health > 0 then
					for i, plr in pairs(plrs:GetChildren()) do
						
						
						local minangle = math.rad(5.5)
						local lastpart = nil
						local function gg(plr)
							pcall(function()
								if plr.Name ~= lplr.Name and plr.Character and plr.Character.Humanoid and plr.Character.Humanoid.Health > 0 and plr.Character.Head then
									local raycasted = false
									local cf1 = CFrame.new(cam.CFrame.p, plr.Character.Head.CFrame.p) * CFrame.new(0, 0, -4)
									local r1 = Ray.new(cf1.p, cf1.LookVector * 9000)
									local obj, pos = ClonedService("Workspace"):FindPartOnRayWithIgnoreList(r1,  {lplr.Character.Head})
									local dist = (plr.Character.Head.CFrame.p- pos).magnitude
									if dist < 4 then
										raycasted = true
									end
									if raycasted == true then
										local an1 = getfovxyz(cam.CFrame, plr.Character.Head.CFrame)
										local an = abs(an1.X) + abs(an1.Y)
										if an < minangle then
											minangle = an
											lastpart = plr.Character.Head
										end
									end
								end
							end)
						end
						if TeamBased then
							if plr.Team.Name ~= lplr.Team.Name then
								gg(plr)
							end
						else
							gg(plr)
						end
						--print(math.deg(minangle))
						if lastpart then
							aimatpart = lastpart
							aimatpart.Parent.Humanoid.Died:Connect(function()
								if aimatpart == lastpart then
									aimatpart = nil
								end
							end)
							
						end
					end
				end
			end
		end)
	end)
	local oldheadpos
	local lastaimapart
	ClonedService("RunService").RenderStepped:Connect(function()
		if aimatpart and lplr.Character and lplr.Character.Head then
			if BetterDeathCount and lastaimapart and lastaimapart == aimatpart then
				local dist = (oldheadpos - aimatpart.CFrame.p).magnitude
				if dist > 40 then
					aimatpart = nil
				end
			end
			lastaimapart = aimatpart
			oldheadpos = lastaimapart.CFrame.p
			do
				if aimatpart.Parent == plrs.LocalPlayer.Character then
					aimatpart = nil
				end
				aimat(aimatpart)
				pcall(function()
					if Aim_Assist == true then
						local cf1 = CFrame.new(cam.CFrame.p, aimatpart.CFrame.p) * CFrame.new(0, 0, -4)
						local r1 = Ray.new(cf1.p, cf1.LookVector * 1000)
						local obj, pos = ClonedService("Workspace"):FindPartOnRayWithIgnoreList(r1,  {lplr.Character.Head})
						local dist = (aimatpart.CFrame.p- pos).magnitude
						if obj then
							--print(obj:GetFullName())
						end
						if not obj or dist > 6 then
							aimatpart = nil
							--print("ooof")
						end
						canaimat = false
						delay(.5, function()
							canaimat = true
						end)
					end
				end)
			end
			
			
			
		end
	end)
end
coroutine.wrap(EGFWXE_fake_script)()
local function UBACA_fake_script() -- SwitchFrame_4.SwitchButtonSystem 
	local script = Instance.new('LocalScript', SwitchFrame_4)

	-- Switches --
	local TweenService = ClonedService("TweenService")
	local time = 0.5 --this will tell you how much it would take for the tween to finish
	-- ColorFade --
	local SwitchButtonFade = TweenService:Create(script.Parent.SwitchButton, TweenInfo.new(time), {BackgroundTransparency = 0})
	local SwitchButtonFadeOut = TweenService:Create(script.Parent.SwitchButton, TweenInfo.new(time), {BackgroundTransparency = 1})
	local SwitchButtonLitFade = TweenService:Create(script.Parent.SwitchButton.SwitchButtonLit, TweenInfo.new(time), {BackgroundTransparency = 0})
	local SwitchButtonLitFadeOut = TweenService:Create(script.Parent.SwitchButton.SwitchButtonLit, TweenInfo.new(time), {BackgroundTransparency = 1})
	
	local Toggle = false
	local ESPToggle = false
	
	script.Parent.SwitchButtonActivator.MouseButton1Click:connect(function()
		if Toggle == false then
			Toggle = true
			script.Parent.SwitchButton:TweenPosition(UDim2.new(0.775,0,0.5,0), "Out", "Quad", 0.5, true)
			SwitchButtonFadeOut:Play()
			SwitchButtonLitFade:Play()
			ESPToggle = true
			pcall(ClearESP)
			pcall(MakeESP)
		else
			Toggle = false
			script.Parent.SwitchButton:TweenPosition(UDim2.new(0.24,0,0.5,0), "Out", "Quad", 0.5, true)
			SwitchButtonFade:Play()
			SwitchButtonLitFadeOut:Play()
			ESPToggle = false
			pcall(ClearESP)
		end
	end)
	-- ESP --
	local Mouse = ClonedService("Players").LocalPlayer:GetMouse()
	
	local plrs = ClonedService("Players")
	local faces = {"Back","Bottom","Front","Left","Right","Top"}
	function MakeESP()
		if ESPToggle == true then
		for _, v in pairs(game:FindFirstChildWhichIsA("Players"):GetChildren()) do if v.Name ~= ClonedService("Players").LocalPlayer.Name then
				local bgui = Instance.new("BillboardGui",v.Character.Head)
				bgui.Name = ("EGUI")
				bgui.AlwaysOnTop = true
				bgui.ExtentsOffset = Vector3.new(0,2,0)
				bgui.Size = UDim2.new(0,200,0,50)
				local nam = Instance.new("TextLabel",bgui)
				nam.Text = v.Name
				nam.BackgroundTransparency = 1
				nam.TextSize = 15
				nam.Font = ("GothamBold")
				nam.TextColor3 = Color3.new(v.TeamColor.r, v.TeamColor.g, v.TeamColor.b)
				nam.Size = UDim2.new(0,200,0,50)
				for _, p in pairs(v.Character:GetChildren()) do
					if p.Name == ("Head") or p.Name == ("Torso") or p.Name == ("Right Arm") or p.Name == ("Right Leg") or p.Name == ("Left Arm") or p.Name == ("Left Leg") then 
						for _, f in pairs(faces) do
							local m = Instance.new("SurfaceGui",p)
							m.Name = ("EGUI")
							m.Face = f
							m.AlwaysOnTop = true
							local mf = Instance.new("Frame",m)
							mf.Size = UDim2.new(1,0,1,0)
							mf.BorderSizePixel = 0
							mf.BackgroundTransparency = 0.5
							mf.BackgroundColor3 = Color3.new(v.TeamColor.r, v.TeamColor.g, v.TeamColor.b)
						end
					end
				end
			end
		end
		end
		end
	
	function ClearESP()
		for _, v in pairs(ClonedService("Workspace"):GetDescendants()) do
			if v.Name == ("EGUI") then
				v:Remove()
			end
		end
	end
	
	Mouse.KeyDown:Connect(function(k)
		if k == "t" then
			if ESPToggle == true then
				wait(1)
				pcall(ClearESP)
				pcall(MakeESP)
			end
		end
	end)
	
	ClonedService("Players").PlayerAdded:Connect(function(v)
		if ESPToggle == true then
			wait(1)
			pcall(ClearESP)
			pcall(MakeESP)
		end
	end)
	
	ClonedService("Players").PlayerRemoving:Connect(function(v)
		if ESPToggle == true then
			wait(1)
			pcall(ClearESP)
			pcall(MakeESP)
		end
	end)
	
	pcall(ClearESP)
	pcall(MakeESP)
	
	while wait(60) do
		if ESPToggle == true then
			wait(1)
			pcall(ClearESP)
			pcall(MakeESP)
		end
	end
end
coroutine.wrap(UBACA_fake_script)()
local function YNNKEQ_fake_script() -- SwitchFrame_5.SwitchButtonSystem 
	local script = Instance.new('LocalScript', SwitchFrame_5)

	script.Parent.SwitchButtonActivator.MouseButton1Click:connect(function()
		script.Parent.Parent.Parent.Parent.Page1:TweenPosition(UDim2.new(0,0,0.169,0), "Out", "Quad", 0.5, true)
		script.Parent.Parent.Parent.Parent.Menu:TweenPosition(UDim2.new(1.1,0,0.169,0), "Out", "Quad", 0.5, true)
		script.Parent.Parent.Parent.Parent.Page2:TweenPosition(UDim2.new(1.1,0,0.169,0), "Out", "Quad", 0.5, true)
		script.Parent.Parent.Parent.Parent.Page3:TweenPosition(UDim2.new(1.1,0,0.169,0), "Out", "Quad", 0.5, true)
	end)
end
coroutine.wrap(YNNKEQ_fake_script)()
local function QQOZMVW_fake_script() -- SwitchFrame_6.SwitchButtonSystem 
	local script = Instance.new('LocalScript', SwitchFrame_6)

	script.Parent.SwitchButtonActivator.MouseButton1Click:connect(function()
		script.Parent.Parent.Parent.Parent.Page2:TweenPosition(UDim2.new(0,0,0.169,0), "Out", "Quad", 0.5, true)
		script.Parent.Parent.Parent.Parent.Menu:TweenPosition(UDim2.new(1.1,0,0.169,0), "Out", "Quad", 0.5, true)
		script.Parent.Parent.Parent.Parent.Page1:TweenPosition(UDim2.new(1.1,0,0.169,0), "Out", "Quad", 0.5, true)
		script.Parent.Parent.Parent.Parent.Page3:TweenPosition(UDim2.new(1.1,0,0.169,0), "Out", "Quad", 0.5, true)
	end)
end
coroutine.wrap(QQOZMVW_fake_script)()
local function SVWBPQ_fake_script() -- SwitchFrame_7.SwitchButtonSystem 
	local script = Instance.new('LocalScript', SwitchFrame_7)

	script.Parent.SwitchButtonActivator.MouseButton1Click:connect(function()
		script.Parent.Parent.Parent.Parent.Page3:TweenPosition(UDim2.new(0,0,0.169,0), "Out", "Quad", 0.5, true)
		script.Parent.Parent.Parent.Parent.Menu:TweenPosition(UDim2.new(1.1,0,0.169,0), "Out", "Quad", 0.5, true)
		script.Parent.Parent.Parent.Parent.Page2:TweenPosition(UDim2.new(1.1,0,0.169,0), "Out", "Quad", 0.5, true)
		script.Parent.Parent.Parent.Parent.Page1:TweenPosition(UDim2.new(1.1,0,0.169,0), "Out", "Quad", 0.5, true)
	end)
end
coroutine.wrap(SVWBPQ_fake_script)()
local function XXBWPH_fake_script() -- MainFrame.Functionaries 
	local script = Instance.new('LocalScript', MainFrame)

	local Minimize = false
	
	script.Parent.TopFrame.Minimize.MouseButton1Click:connect(function()
			if Minimize == false then
			Minimize = true
			script.Parent.BottomFrame:TweenPosition(UDim2.new(0.5,0,-1.5,0), "Out", "Quad", 0.5, true)
		else
			Minimize = false
			script.Parent.BottomFrame:TweenPosition(UDim2.new(0.5,0,0.5,0), "Out", "Quad", 0.5, true)
		end
	end)
	
	script.Parent.TopFrame.Menu.MouseButton1Click:connect(function()
		script.Parent.BottomFrame.Menu:TweenPosition(UDim2.new(0,0,0.169,0), "Out", "Quad", 0.5, true)
		script.Parent.BottomFrame.Page1:TweenPosition(UDim2.new(1.1,0,0.169,0), "Out", "Quad", 0.5, true)
		script.Parent.BottomFrame.Page2:TweenPosition(UDim2.new(1.1,0,0.169,0), "Out", "Quad", 0.5, true)
		script.Parent.BottomFrame.Page3:TweenPosition(UDim2.new(1.1,0,0.169,0), "Out", "Quad", 0.5, true)
	end)
	
	-- Dragging
	local UserInputService = ClonedService("UserInputService")
	
	local gui = script.Parent
	
	local dragging
	local dragInput
	local dragStart
	local startPos
	
	local function update(input)
		local delta = input.Position - dragStart
		gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	
	gui.TopFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = gui.Position
	
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	
	gui.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end
coroutine.wrap(XXBWPH_fake_script)()
local function OTKOWZS_fake_script() -- MainFrame.LocalScript 
	local script = Instance.new('LocalScript', MainFrame)

	wait(2)
	script.Parent.TopFrame:TweenSize(UDim2.new(0,195,0,25), "Out", "Quad", 0.5, true)
	script.Parent.TopFrame:TweenPosition(UDim2.new(0.5,0,0,0), "Out", "Quad", 0.5, true)
	wait(1)
	script.Parent.BottomFrame:TweenPosition(UDim2.new(0.5,0,0.5,0), "Out", "Quad", 0.5, true)
end
coroutine.wrap(OTKOWZS_fake_script)()
