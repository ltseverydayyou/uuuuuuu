local ScreenGui = Instance.new("ScreenGui")
local SRS = Instance.new("Frame")
local Container = Instance.new("Frame")
local Logs = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")
local mrlabel = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")
local UIGradient = Instance.new("UIGradient")
local UICorner_2 = Instance.new("UICorner")
local UIGradient_2 = Instance.new("UIGradient")
local Topbar = Instance.new("Frame")
local Exit = Instance.new("TextButton")
local TopBar = Instance.new("Frame")
local ImageLabel = Instance.new("ImageLabel")
local ImageLabel_2 = Instance.new("ImageLabel")
local Title = Instance.new("TextLabel")
local Clear = Instance.new("TextButton")
local ImageLabel_3 = Instance.new("ImageLabel")
local result = Instance.new("Frame")
local answer = Instance.new("ScrollingFrame")
local UIListLayout_2 = Instance.new("UIListLayout")
local txt = Instance.new("TextLabel")
local UICorner_3 = Instance.new("UICorner")
local UIGradient_3 = Instance.new("UIGradient")
local copySignal = Instance.new("TextButton")
local UICorner_4 = Instance.new("UICorner")
local fireSignal = Instance.new("TextButton")
local UICorner_5 = Instance.new("UICorner")
local UIStroke = Instance.new("UIStroke")
local UIStroke_2 = Instance.new("UIStroke")

ScreenGui.Name = "SRS"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false

SRS.Name = "SRS"
SRS.Parent = ScreenGui
SRS.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
SRS.BackgroundTransparency = 0.1
SRS.BorderColor3 = Color3.fromRGB(139, 139, 139)
SRS.BorderSizePixel = 0
SRS.Position = UDim2.new(0.290851444, 0, 0.541700661, 0)
SRS.Size = UDim2.new(0, 318, 0, 286)

Container.Name = "Container"
Container.Parent = SRS
Container.AnchorPoint = Vector2.new(0.5, 1)
Container.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Container.BackgroundTransparency = 0.2
Container.BorderColor3 = Color3.fromRGB(255, 255, 255)
Container.BorderSizePixel = 0
Container.ClipsDescendants = true
Container.Position = UDim2.new(0.5, 0, 1, -5)
Container.Size = UDim2.new(1, -10, 1.01153851, -30)

Logs.Name = "Logs"
Logs.Parent = Container
Logs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Logs.BackgroundTransparency = 1
Logs.BorderColor3 = Color3.fromRGB(16, 16, 16)
Logs.BorderSizePixel = 0
Logs.Size = UDim2.new(1, 0, 1, 0)
Logs.BottomImage = "rbxassetid://6889586589"
Logs.CanvasSize = UDim2.new(0, 0, 0, 0)
Logs.MidImage = "rbxassetid://6889586589"
Logs.ScrollBarThickness = 4
Logs.TopImage = "rbxassetid://6889586589"

UIListLayout.Parent = Logs
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 4)

mrlabel.Name = "mrlabel"
mrlabel.Parent = Logs
mrlabel.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
mrlabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
mrlabel.BorderSizePixel = 0
mrlabel.Size = UDim2.new(1, -8, 0, 50)
mrlabel.Font = Enum.Font.Gotham
mrlabel.Text = "rem"
mrlabel.TextColor3 = Color3.fromRGB(255, 255, 255)
mrlabel.TextScaled = true
mrlabel.TextSize = 14
mrlabel.TextWrapped = true

UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = mrlabel

UICorner_2.CornerRadius = UDim.new(0, 9)
UICorner_2.Parent = Container

UIGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(12, 4, 20)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(20, 10, 30)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(12, 4, 20))}
UIGradient.Parent = Container

UICorner_2.CornerRadius = UDim.new(0, 9)
UICorner_2.Parent = SRS

UIGradient_2.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(20, 10, 30)), ColorSequenceKeypoint.new(0.52, Color3.fromRGB(15, 15, 25)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(20, 10, 30))}
UIGradient_2.Parent = SRS

Topbar.Name = "Topbar"
Topbar.Parent = SRS
Topbar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Topbar.BackgroundTransparency = 1
Topbar.BorderColor3 = Color3.fromRGB(27, 42, 53)
Topbar.Size = UDim2.new(1, 0, 0, 25)

Exit.Name = "Exit"
Exit.Parent = Topbar
Exit.BackgroundColor3 = Color3.fromRGB(30, 10, 40)
Exit.BackgroundTransparency = 0.2
Exit.BorderColor3 = Color3.fromRGB(27, 42, 53)
Exit.BorderSizePixel = 0
Exit.Position = UDim2.new(0.927672744, -42, -0.0800012201, 2)
Exit.Size = UDim2.new(0.036327038, 40, 0.994000018, -10)
Exit.Font = Enum.Font.GothamBold
Exit.Text = "X"
Exit.TextColor3 = Color3.fromRGB(255, 255, 255)
Exit.TextScaled = true
Exit.TextSize = 13
Exit.TextWrapped = true

TopBar.Name = "TopBar"
TopBar.Parent = Topbar
TopBar.BackgroundColor3 = Color3.fromRGB(30, 10, 40)
TopBar.BackgroundTransparency = 0.2
TopBar.BorderColor3 = Color3.fromRGB(27, 42, 53)
TopBar.BorderSizePixel = 0
TopBar.Position = UDim2.new(0.21977897, 0, -7.62939436e-08, 0)
TopBar.Size = UDim2.new(0.204437152, 82, 0.994254291, -10)

ImageLabel.Parent = TopBar
ImageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageLabel.BackgroundTransparency = 1
ImageLabel.BorderColor3 = Color3.fromRGB(27, 42, 53)
ImageLabel.Position = UDim2.new(1.00000012, 0, 0.000329111295, 0)
ImageLabel.Size = UDim2.new(0, 14, 0, 16)
ImageLabel.Image = "rbxassetid://8650484523"
ImageLabel.ImageColor3 = Color3.fromRGB(30, 10, 40)
ImageLabel.ImageTransparency = 0.2

ImageLabel_2.Parent = TopBar
ImageLabel_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageLabel_2.BackgroundTransparency = 1
ImageLabel_2.BorderColor3 = Color3.fromRGB(27, 42, 53)
ImageLabel_2.Position = UDim2.new(-0.108781718, 0, 0, 0)
ImageLabel_2.Size = UDim2.new(0, 15, 0, 16)
ImageLabel_2.Image = "rbxassetid://10555881849"
ImageLabel_2.ImageColor3 = Color3.fromRGB(30, 10, 40)
ImageLabel_2.ImageTransparency = 0.2

Title.Name = "Title"
Title.Parent = TopBar
Title.AnchorPoint = Vector2.new(0, 0.5)
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1
Title.BorderColor3 = Color3.fromRGB(27, 42, 53)
Title.BorderSizePixel = 0
Title.Position = UDim2.new(0, 0, 0.5, 0)
Title.Size = UDim2.new(1, 0, 1.48117876, -7)
Title.Font = Enum.Font.GothamBold
Title.Text = "Server Remote Spy"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextScaled = true
Title.TextSize = 17
Title.TextWrapped = true

Clear.Name = "Clear"
Clear.Parent = Topbar
Clear.BackgroundColor3 = Color3.fromRGB(30, 10, 40)
Clear.BackgroundTransparency = 0.2
Clear.BorderColor3 = Color3.fromRGB(27, 42, 53)
Clear.BorderSizePixel = 0
Clear.Position = UDim2.new(0.260221332, -69, -0.040004883, 2)
Clear.Size = UDim2.new(0.0365409181, 25, 0.994256616, -10)
Clear.Font = Enum.Font.GothamBold
Clear.Text = "Clear"
Clear.TextColor3 = Color3.fromRGB(255, 255, 255)
Clear.TextScaled = true
Clear.TextSize = 13
Clear.TextWrapped = true

ImageLabel_3.Parent = Clear
ImageLabel_3.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
ImageLabel_3.BackgroundTransparency = 1
ImageLabel_3.BorderColor3 = Color3.fromRGB(27, 42, 53)
ImageLabel_3.Position = UDim2.new(1.00000012, 0, 0, 0)
ImageLabel_3.Size = UDim2.new(0, 8, 0, 14)
ImageLabel_3.Image = "rbxassetid://8650484523"
ImageLabel_3.ImageColor3 = Color3.fromRGB(30, 10, 40)
ImageLabel_3.ImageTransparency = 0.2

result.Name = "result"
result.Parent = SRS
result.AnchorPoint = Vector2.new(0.5, 1)
result.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
result.BackgroundTransparency = 0.15
result.BorderColor3 = Color3.fromRGB(255, 255, 255)
result.BorderSizePixel = 0
result.ClipsDescendants = true
result.Position = UDim2.new(1.48233211, 0, 1.01748252, -5)
result.Size = UDim2.new(1, -10, 1.08391607, -30)

answer.Name = "answer"
answer.Parent = result
answer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
answer.BackgroundTransparency = 1
answer.BorderColor3 = Color3.fromRGB(16, 16, 16)
answer.BorderSizePixel = 0
answer.Size = UDim2.new(1, 0, 0.853571475, 0)
answer.BottomImage = "rbxassetid://6889586589"
answer.CanvasSize = UDim2.new(0, 0, 0, 0)
answer.MidImage = "rbxassetid://6889586589"
answer.ScrollBarThickness = 4
answer.TopImage = "rbxassetid://6889586589"

UIListLayout_2.Parent = answer
UIListLayout_2.Padding = UDim.new(0, 4)

txt.Name = "txt"
txt.Parent = answer
txt.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
txt.BackgroundTransparency = 1
txt.BorderColor3 = Color3.fromRGB(0, 0, 0)
txt.BorderSizePixel = 0
txt.Size = UDim2.new(1, 0, 0.174999997, 0)
txt.Font = Enum.Font.Gotham
txt.Text = ". . ."
txt.TextColor3 = Color3.fromRGB(255, 255, 255)
txt.TextScaled = true
txt.TextSize = 14
txt.TextWrapped = true
txt.TextYAlignment = Enum.TextYAlignment.Top

UICorner_3.CornerRadius = UDim.new(0, 9)
UICorner_3.Parent = result

UIGradient_3.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(20, 10, 30)), ColorSequenceKeypoint.new(0.50, Color3.fromRGB(20, 10, 30)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(20, 10, 30))}
UIGradient_3.Parent = result

copySignal.Name = "copySignal"
copySignal.Parent = result
copySignal.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
copySignal.BorderColor3 = Color3.fromRGB(0, 0, 0)
copySignal.BorderSizePixel = 0
copySignal.Position = UDim2.new(0, 0, 0.853571415, 0)
copySignal.Size = UDim2.new(0.5, 0, -0.032142859, 50)
copySignal.Font = Enum.Font.GothamBold
copySignal.Text = "Copy Signal"
copySignal.TextColor3 = Color3.fromRGB(255, 255, 255)
copySignal.TextScaled = true
copySignal.TextSize = 14
copySignal.TextWrapped = true
copySignal.TextXAlignment = Enum.TextXAlignment.Center

UICorner_4.CornerRadius = UDim.new(0, 9)
UICorner_4.Parent = copySignal

fireSignal.Name = "fireSignal"
fireSignal.Parent = result
fireSignal.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
fireSignal.BorderColor3 = Color3.fromRGB(0, 0, 0)
fireSignal.BorderSizePixel = 0
fireSignal.Position = UDim2.new(0.5, 0, 0.853571415, 0)
fireSignal.Size = UDim2.new(0.5, 0, -0.032142859, 50)
fireSignal.Font = Enum.Font.GothamBold
fireSignal.Text = "Execute Signal"
fireSignal.TextColor3 = Color3.fromRGB(255, 255, 255)
fireSignal.TextScaled = true
fireSignal.TextSize = 14
fireSignal.TextWrapped = true
fireSignal.TextXAlignment = Enum.TextXAlignment.Center

UICorner_5.CornerRadius = UDim.new(0, 9)
UICorner_5.Parent = fireSignal

UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Color = Color3.fromRGB(100, 50, 150)
UIStroke.Thickness = 1.2
UIStroke.Parent = SRS

UIStroke_2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke_2.Color = Color3.fromRGB(100, 50, 150)
UIStroke_2.Thickness = 1.2
UIStroke_2.Parent = result

return ScreenGui