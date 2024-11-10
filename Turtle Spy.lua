local colorSettings =
	{
		["Main"] = {
			["HeaderColor"] = Color3.fromRGB(0, 168, 255),
			["HeaderShadingColor"] = Color3.fromRGB(0, 151, 230),
			["HeaderTextColor"] = Color3.fromRGB(47, 54, 64),
			["MainBackgroundColor"] = Color3.fromRGB(47, 54, 64),
			["InfoScrollingFrameBgColor"] = Color3.fromRGB(47, 54, 64),
			["ScrollBarImageColor"] = Color3.fromRGB(127, 143, 166)
		},
		["RemoteButtons"] = {
			["BorderColor"] = Color3.fromRGB(113, 128, 147),
			["BackgroundColor"] = Color3.fromRGB(53, 59, 72),
			["TextColor"] = Color3.fromRGB(220, 221, 225),
			["NumberTextColor"] = Color3.fromRGB(203, 204, 207)
		},
		["MainButtons"] = { 
			["BorderColor"] = Color3.fromRGB(113, 128, 147),
			["BackgroundColor"] = Color3.fromRGB(53, 59, 72),
			["TextColor"] = Color3.fromRGB(220, 221, 225)
		},
		['Code'] = {
			['BackgroundColor'] = Color3.fromRGB(35, 40, 48),
			['TextColor'] = Color3.fromRGB(220, 221, 225),
			['CreditsColor'] = Color3.fromRGB(108, 108, 108)
		},
	}

local buttonOffset = -25
local scrollSizeOffset = 287
local functionImage = "http://www.roblox.com/asset/?id=413369623"
local eventImage = "http://www.roblox.com/asset/?id=413369506"
local remotes = {}
local remoteArgs = {}
local remoteButtons = {}
local remoteScripts = {}
local IgnoreList = {}
local BlockList = {}
local IgnoreList = {}
local connections = {}
local unstacked = {}

local TurtleSpyGUI = Instance.new("ScreenGui")
local mainFrame = Instance.new("Frame")
local Header = Instance.new("Frame")
local HeaderShading = Instance.new("Frame")
local HeaderTextLabel = Instance.new("TextLabel")
local RemoteScrollFrame = Instance.new("ScrollingFrame")
local RemoteButton = Instance.new("TextButton")
local Number = Instance.new("TextLabel")
local RemoteName = Instance.new("TextLabel")
local RemoteIcon = Instance.new("ImageLabel")
local InfoFrame = Instance.new("Frame")
local InfoFrameHeader = Instance.new("Frame")
local InfoTitleShading = Instance.new("Frame")
local CodeFrame = Instance.new("ScrollingFrame")
local Code = Instance.new("TextLabel")
local InfoHeaderText = Instance.new("TextLabel")
local InfoButtonsScroll = Instance.new("ScrollingFrame")
local CopyCode = Instance.new("TextButton")
local RunCode = Instance.new("TextButton")
local CopyScriptPath = Instance.new("TextButton")
local CopyDecompiled = Instance.new("TextButton")
local IgnoreRemote = Instance.new("TextButton")
local BlockRemote = Instance.new("TextButton")
local WhileLoop = Instance.new("TextButton")
local CopyReturn = Instance.new("TextButton")
local Clear = Instance.new("TextButton")
local FrameDivider = Instance.new("Frame")
local CloseInfoFrame = Instance.new("TextButton")
local OpenInfoFrame = Instance.new("TextButton")
local Minimize = Instance.new("TextButton")
local DoNotStack = Instance.new("TextButton")
local ImageButton = Instance.new("ImageButton")

-- Remote browser
local BrowserHeader = Instance.new("Frame")
local BrowserHeaderFrame = Instance.new("Frame")
local BrowserHeaderText = Instance.new("TextLabel")
local CloseInfoFrame2 = Instance.new("TextButton")
local RemoteBrowserFrame = Instance.new("ScrollingFrame")
local RemoteButton2 = Instance.new("TextButton")
local RemoteName2 = Instance.new("TextLabel")
local RemoteIcon2 = Instance.new("ImageLabel")

TurtleSpyGUI.Name = "TurtleSpyGUI"

TurtleSpyGUI.Parent=game.StarterGui

mainFrame.Name = "mainFrame"
mainFrame.Parent = TurtleSpyGUI
mainFrame.BackgroundColor3 = Color3.fromRGB(53, 59, 72)
mainFrame.BorderColor3 = Color3.fromRGB(53, 59, 72)
mainFrame.Position = UDim2.new(0.100000001, 0, 0.239999995, 0)
mainFrame.Size = UDim2.new(0, 207, 0, 35)
mainFrame.ZIndex = 8
mainFrame.Active = true
mainFrame.Draggable = true

-- Remote browser properties

BrowserHeader.Name = "BrowserHeader"
BrowserHeader.Parent = TurtleSpyGUI
BrowserHeader.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
BrowserHeader.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
BrowserHeader.Position = UDim2.new(0.712152421, 0, 0.339464903, 0)
BrowserHeader.Size = UDim2.new(0, 207, 0, 33)
BrowserHeader.ZIndex = 20
BrowserHeader.Active = true
BrowserHeader.Draggable = true
BrowserHeader.Visible = false

BrowserHeaderFrame.Name = "BrowserHeaderFrame"
BrowserHeaderFrame.Parent = BrowserHeader
BrowserHeaderFrame.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
BrowserHeaderFrame.BorderColor3 = colorSettings["Main"]["HeaderColor"]
BrowserHeaderFrame.Position = UDim2.new(0, 0, -0.0202544238, 0)
BrowserHeaderFrame.Size = UDim2.new(0, 207, 0, 26)
BrowserHeaderFrame.ZIndex = 21

BrowserHeaderText.Name = "InfoHeaderText"
BrowserHeaderText.Parent = BrowserHeaderFrame
BrowserHeaderText.BackgroundTransparency = 1.000
BrowserHeaderText.Position = UDim2.new(0, 0, -0.00206991332, 0)
BrowserHeaderText.Size = UDim2.new(0, 206, 0, 33)
BrowserHeaderText.ZIndex = 22
BrowserHeaderText.Font = Enum.Font.SourceSans
BrowserHeaderText.Text = "Remote Browser"
BrowserHeaderText.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
BrowserHeaderText.TextSize = 17.000

CloseInfoFrame2.Name = "CloseInfoFrame"
CloseInfoFrame2.Parent = BrowserHeaderFrame
CloseInfoFrame2.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
CloseInfoFrame2.BorderColor3 = colorSettings["Main"]["HeaderColor"]
CloseInfoFrame2.Position = UDim2.new(0, 185, 0, 2)
CloseInfoFrame2.Size = UDim2.new(0, 22, 0, 22)
CloseInfoFrame2.ZIndex = 38
CloseInfoFrame2.Font = Enum.Font.SourceSansLight
CloseInfoFrame2.Text = "X"
CloseInfoFrame2.TextColor3 = Color3.fromRGB(0, 0, 0)
CloseInfoFrame2.TextSize = 20.000
CloseInfoFrame2.MouseButton1Click:Connect(function()
	BrowserHeader.Visible = not BrowserHeader.Visible
end)

RemoteBrowserFrame.Name = "RemoteBrowserFrame"
RemoteBrowserFrame.Parent = BrowserHeader
RemoteBrowserFrame.Active = true
RemoteBrowserFrame.BackgroundColor3 = Color3.fromRGB(47, 54, 64)
RemoteBrowserFrame.BorderColor3 = Color3.fromRGB(47, 54, 64)
RemoteBrowserFrame.Position = UDim2.new(-0.004540205, 0, 1.03504682, 0)
RemoteBrowserFrame.Size = UDim2.new(0, 207, 0, 286)
RemoteBrowserFrame.ZIndex = 19
RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, 287)
RemoteBrowserFrame.ScrollBarThickness = 8
RemoteBrowserFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
RemoteBrowserFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

RemoteButton2.Name = "RemoteButton"
RemoteButton2.Parent = RemoteBrowserFrame
RemoteButton2.BackgroundColor3 = colorSettings["RemoteButtons"]["BackgroundColor"]
RemoteButton2.BorderColor3 = colorSettings["RemoteButtons"]["BorderColor"]
RemoteButton2.Position = UDim2.new(0, 17, 0, 10)
RemoteButton2.Size = UDim2.new(0, 182, 0, 26)
RemoteButton2.ZIndex = 20
RemoteButton2.Selected = true
RemoteButton2.Font = Enum.Font.SourceSans
RemoteButton2.Text = ""
RemoteButton2.TextSize = 18.000
RemoteButton2.TextStrokeTransparency = 123.000
RemoteButton2.TextWrapped = true
RemoteButton2.TextXAlignment = Enum.TextXAlignment.Left
RemoteButton2.Visible = false

RemoteName2.Name = "RemoteName2"
RemoteName2.Parent = RemoteButton2
RemoteName2.BackgroundTransparency = 1.000
RemoteName2.Position = UDim2.new(0, 5, 0, 0)
RemoteName2.Size = UDim2.new(0, 155, 0, 26)
RemoteName2.ZIndex = 21
RemoteName2.Font = Enum.Font.SourceSans
RemoteName2.Text = "RemoteEventaasdadad"
RemoteName2.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
RemoteName2.TextSize = 16.000
RemoteName2.TextXAlignment = Enum.TextXAlignment.Left
RemoteName2.TextTruncate = 1


RemoteIcon2.Name = "RemoteIcon2"
RemoteIcon2.Parent = RemoteButton2
RemoteIcon2.BackgroundTransparency = 1.000
RemoteIcon2.Position = UDim2.new(0.840260386, 0, 0.0225472748, 0)
RemoteIcon2.Size = UDim2.new(0, 24, 0, 24)
RemoteIcon2.ZIndex = 21
RemoteIcon2.Image = functionImage

local browsedRemotes = {}
local browsedConnections = {}
local browsedButtonOffset = 10
local browserCanvasSize = 286

ImageButton.Parent = Header
ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ImageButton.BackgroundTransparency = 1.000
ImageButton.Position = UDim2.new(0, 8, 0, 8)
ImageButton.Size = UDim2.new(0, 18, 0, 18)
ImageButton.ZIndex = 9
ImageButton.Image = "rbxassetid://169476802"
ImageButton.ImageColor3 = Color3.fromRGB(53, 53, 53)

Header.Name = "Header"
Header.Parent = mainFrame
Header.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
Header.BorderColor3 = colorSettings["Main"]["HeaderColor"]
Header.Size = UDim2.new(0, 207, 0, 26)
Header.ZIndex = 9

HeaderShading.Name = "HeaderShading"
HeaderShading.Parent = Header
HeaderShading.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
HeaderShading.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
HeaderShading.Position = UDim2.new(1.46719131e-07, 0, 0.285714358, 0)
HeaderShading.Size = UDim2.new(0, 207, 0, 27)
HeaderShading.ZIndex = 8

HeaderTextLabel.Name = "HeaderTextLabel"
HeaderTextLabel.Parent = HeaderShading
HeaderTextLabel.BackgroundTransparency = 1.000
HeaderTextLabel.Position = UDim2.new(-0.00507604145, 0, -0.202857122, 0)
HeaderTextLabel.Size = UDim2.new(0, 215, 0, 29)
HeaderTextLabel.ZIndex = 10
HeaderTextLabel.Font = Enum.Font.SourceSans
HeaderTextLabel.Text = "Turtle Spy"
HeaderTextLabel.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
HeaderTextLabel.TextSize = 17.000

RemoteScrollFrame.Name = "RemoteScrollFrame"
RemoteScrollFrame.Parent = mainFrame
RemoteScrollFrame.Active = true
RemoteScrollFrame.BackgroundColor3 = Color3.fromRGB(47, 54, 64)
RemoteScrollFrame.BorderColor3 = Color3.fromRGB(47, 54, 64)
RemoteScrollFrame.Position = UDim2.new(0, 0, 1.02292562, 0)
RemoteScrollFrame.Size = UDim2.new(0, 207, 0, 286)
RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 287)
RemoteScrollFrame.ScrollBarThickness = 8
RemoteScrollFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
RemoteScrollFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

RemoteButton.Name = "RemoteButton"
RemoteButton.Parent = RemoteScrollFrame
RemoteButton.BackgroundColor3 = colorSettings["RemoteButtons"]["BackgroundColor"]
RemoteButton.BorderColor3 = colorSettings["RemoteButtons"]["BorderColor"]
RemoteButton.Position = UDim2.new(0, 17, 0, 10)
RemoteButton.Size = UDim2.new(0, 182, 0, 26)
RemoteButton.Selected = true
RemoteButton.Font = Enum.Font.SourceSans
RemoteButton.Text = ""
RemoteButton.TextColor3 = Color3.fromRGB(220, 221, 225)
RemoteButton.TextSize = 18.000
RemoteButton.TextStrokeTransparency = 123.000
RemoteButton.TextWrapped = true
RemoteButton.TextXAlignment = Enum.TextXAlignment.Left
RemoteButton.Visible = false

Number.Name = "Number"
Number.Parent = RemoteButton
Number.BackgroundTransparency = 1.000
Number.Position = UDim2.new(0, 5, 0, 0)
Number.Size = UDim2.new(0, 300, 0, 26)
Number.ZIndex = 2
Number.Font = Enum.Font.SourceSans
Number.Text = "1"
Number.TextColor3 = colorSettings["RemoteButtons"]["NumberTextColor"]
Number.TextSize = 16.000
Number.TextWrapped = true
Number.TextXAlignment = Enum.TextXAlignment.Left

RemoteName.Name = "RemoteName"
RemoteName.Parent = RemoteButton
RemoteName.BackgroundTransparency = 1.000
RemoteName.Position = UDim2.new(0, 20, 0, 0)
RemoteName.Size = UDim2.new(0, 134, 0, 26)
RemoteName.Font = Enum.Font.SourceSans
RemoteName.Text = "RemoteEvent"
RemoteName.TextColor3 = colorSettings["RemoteButtons"]["TextColor"]
RemoteName.TextSize = 16.000
RemoteName.TextXAlignment = Enum.TextXAlignment.Left
RemoteName.TextTruncate = 1

RemoteIcon.Name = "RemoteIcon"
RemoteIcon.Parent = RemoteButton
RemoteIcon.BackgroundTransparency = 1.000
RemoteIcon.Position = UDim2.new(0.840260386, 0, 0.0225472748, 0)
RemoteIcon.Size = UDim2.new(0, 24, 0, 24)
RemoteIcon.Image = "http://www.roblox.com/asset/?id=413369506"

InfoFrame.Name = "InfoFrame"
InfoFrame.Parent = mainFrame
InfoFrame.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"]
InfoFrame.BorderColor3 = colorSettings["Main"]["MainBackgroundColor"]
InfoFrame.Position = UDim2.new(0.368141592, 0, -5.58035717e-05, 0)
InfoFrame.Size = UDim2.new(0, 357, 0, 322)
InfoFrame.Visible = false
InfoFrame.ZIndex = 6

InfoFrameHeader.Name = "InfoFrameHeader"
InfoFrameHeader.Parent = InfoFrame
InfoFrameHeader.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
InfoFrameHeader.BorderColor3 = colorSettings["Main"]["HeaderColor"]
InfoFrameHeader.Size = UDim2.new(0, 357, 0, 26)
InfoFrameHeader.ZIndex = 14

InfoTitleShading.Name = "InfoTitleShading"
InfoTitleShading.Parent = InfoFrame
InfoTitleShading.BackgroundColor3 = colorSettings["Main"]["HeaderShadingColor"]
InfoTitleShading.BorderColor3 = colorSettings["Main"]["HeaderShadingColor"]
InfoTitleShading.Position = UDim2.new(-0.00280881394, 0, 0, 0)
InfoTitleShading.Size = UDim2.new(0, 358, 0, 34)
InfoTitleShading.ZIndex = 13

CodeFrame.Name = "CodeFrame"
CodeFrame.Parent = InfoFrame
CodeFrame.Active = true
CodeFrame.BackgroundColor3 = colorSettings["Code"]["BackgroundColor"]
CodeFrame.BorderColor3 = colorSettings["Code"]["BackgroundColor"]
CodeFrame.Position = UDim2.new(0.0391303748, 0, 0.141156405, 0)
CodeFrame.Size = UDim2.new(0, 329, 0, 63)
CodeFrame.ZIndex = 16
CodeFrame.CanvasSize = UDim2.new(0, 670, 2, 0)
CodeFrame.ScrollBarThickness = 8
CodeFrame.ScrollingDirection = 1
CodeFrame.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

Code.Name = "Code"
Code.Parent = CodeFrame
Code.BackgroundTransparency = 1.000
Code.Position = UDim2.new(0.00888902973, 0, 0.0394801199, 0)
Code.Size = UDim2.new(0, 100000, 0, 25)
Code.ZIndex = 18
Code.Font = Enum.Font.SourceSans
Code.Text = "Thanks for using Turtle Spy! :D"
Code.TextColor3 = colorSettings["Code"]["TextColor"]
Code.TextSize = 14.000
Code.TextWrapped = true
Code.TextXAlignment = Enum.TextXAlignment.Left

InfoHeaderText.Name = "InfoHeaderText"
InfoHeaderText.Parent = InfoFrame
InfoHeaderText.BackgroundTransparency = 1.000
InfoHeaderText.Position = UDim2.new(0.0391303934, 0, -0.00206972216, 0)
InfoHeaderText.Size = UDim2.new(0, 342, 0, 35)
InfoHeaderText.ZIndex = 18
InfoHeaderText.Font = Enum.Font.SourceSans
InfoHeaderText.Text = "Info: RemoteFunction"
InfoHeaderText.TextColor3 = colorSettings["Main"]["HeaderTextColor"]
InfoHeaderText.TextSize = 17.000

InfoButtonsScroll.Name = "InfoButtonsScroll"
InfoButtonsScroll.Parent = InfoFrame
InfoButtonsScroll.Active = true
InfoButtonsScroll.BackgroundColor3 = colorSettings["Main"]["MainBackgroundColor"]
InfoButtonsScroll.BorderColor3 = colorSettings["Main"]["MainBackgroundColor"]
InfoButtonsScroll.Position = UDim2.new(0.0391303748, 0, 0.355857909, 0)
InfoButtonsScroll.Size = UDim2.new(0, 329, 0, 199)
InfoButtonsScroll.ZIndex = 11
InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 1, 0)
InfoButtonsScroll.ScrollBarThickness = 8
InfoButtonsScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left
InfoButtonsScroll.ScrollBarImageColor3 = colorSettings["Main"]["ScrollBarImageColor"]

CopyCode.Name = "CopyCode"
CopyCode.Parent = InfoButtonsScroll
CopyCode.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
CopyCode.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
CopyCode.Position = UDim2.new(0.0645, 0, 0, 10)
CopyCode.Size = UDim2.new(0, 294, 0, 26)
CopyCode.ZIndex = 15
CopyCode.Font = Enum.Font.SourceSans
CopyCode.Text = "Copy code"
CopyCode.TextColor3 = Color3.fromRGB(250, 251, 255)
CopyCode.TextSize = 16.000

RunCode.Name = "RunCode"
RunCode.Parent = InfoButtonsScroll
RunCode.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
RunCode.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
RunCode.Position = UDim2.new(0.0645, 0, 0, 45)
RunCode.Size = UDim2.new(0, 294, 0, 26)
RunCode.ZIndex = 15
RunCode.Font = Enum.Font.SourceSans
RunCode.Text = "Execute"
RunCode.TextColor3 = Color3.fromRGB(250, 251, 255)
RunCode.TextSize = 16.000

CopyScriptPath.Name = "CopyScriptPath"
CopyScriptPath.Parent = InfoButtonsScroll
CopyScriptPath.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
CopyScriptPath.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
CopyScriptPath.Position = UDim2.new(0.0645, 0, 0, 80)
CopyScriptPath.Size = UDim2.new(0, 294, 0, 26)
CopyScriptPath.ZIndex = 15
CopyScriptPath.Font = Enum.Font.SourceSans
CopyScriptPath.Text = "Copy script path"
CopyScriptPath.TextColor3 = Color3.fromRGB(250, 251, 255)
CopyScriptPath.TextSize = 16.000

CopyDecompiled.Name = "CopyDecompiled"
CopyDecompiled.Parent = InfoButtonsScroll
CopyDecompiled.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
CopyDecompiled.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
CopyDecompiled.Position = UDim2.new(0.0645, 0, 0, 115)
CopyDecompiled.Size = UDim2.new(0, 294, 0, 26)
CopyDecompiled.ZIndex = 15
CopyDecompiled.Font = Enum.Font.SourceSans
CopyDecompiled.Text = "Copy decompiled script"
CopyDecompiled.TextColor3 = Color3.fromRGB(250, 251, 255)
CopyDecompiled.TextSize = 16.000

IgnoreRemote.Name = "IgnoreRemote"
IgnoreRemote.Parent = InfoButtonsScroll
IgnoreRemote.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
IgnoreRemote.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
IgnoreRemote.Position = UDim2.new(0.0645, 0, 0, 185)
IgnoreRemote.Size = UDim2.new(0, 294, 0, 26)
IgnoreRemote.ZIndex = 15
IgnoreRemote.Font = Enum.Font.SourceSans
IgnoreRemote.Text = "Ignore remote"
IgnoreRemote.TextColor3 = Color3.fromRGB(250, 251, 255)
IgnoreRemote.TextSize = 16.000

BlockRemote.Name = "Block Remote"
BlockRemote.Parent = InfoButtonsScroll
BlockRemote.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
BlockRemote.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
BlockRemote.Position = UDim2.new(0.0645, 0, 0, 220)
BlockRemote.Size = UDim2.new(0, 294, 0, 26)
BlockRemote.ZIndex = 15
BlockRemote.Font = Enum.Font.SourceSans
BlockRemote.Text = "Block remote from firing"
BlockRemote.TextColor3 = Color3.fromRGB(250, 251, 255)
BlockRemote.TextSize = 16.000

WhileLoop.Name = "WhileLoop"
WhileLoop.Parent = InfoButtonsScroll
WhileLoop.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
WhileLoop.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
WhileLoop.Position = UDim2.new(0.0645, 0, 0, 290)
WhileLoop.Size = UDim2.new(0, 294, 0, 26)
WhileLoop.ZIndex = 15
WhileLoop.Font = Enum.Font.SourceSans
WhileLoop.Text = "Generate while loop script"
WhileLoop.TextColor3 = Color3.fromRGB(250, 251, 255)
WhileLoop.TextSize = 16.000

Clear.Name = "Clear"
Clear.Parent = InfoButtonsScroll
Clear.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
Clear.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
Clear.Position = UDim2.new(0.0645, 0, 0, 255)
Clear.Size = UDim2.new(0, 294, 0, 26)
Clear.ZIndex = 15
Clear.Font = Enum.Font.SourceSans
Clear.Text = "Clear logs"
Clear.TextColor3 = Color3.fromRGB(250, 251, 255)
Clear.TextSize = 16.000

CopyReturn.Name = "CopyReturn"
CopyReturn.Parent = InfoButtonsScroll
CopyReturn.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
CopyReturn.BorderColor3 = colorSettings["MainButtons"]["BorderColor"]
CopyReturn.Position = UDim2.new(0.0645, 0, 0, 325)
CopyReturn.Size = UDim2.new(0, 294, 0, 26)
CopyReturn.ZIndex = 15
CopyReturn.Font = Enum.Font.SourceSans
CopyReturn.Text = "Execute and copy return value"
CopyReturn.TextColor3 = Color3.fromRGB(250, 251, 255)
CopyReturn.TextSize = 16.000

DoNotStack.Name = "CopyReturn"
DoNotStack.Parent = InfoButtonsScroll
DoNotStack.BackgroundColor3 = colorSettings["MainButtons"]["BackgroundColor"]
DoNotStack.BorderColor3 =  colorSettings["MainButtons"]["BorderColor"]
DoNotStack.Position = UDim2.new(0.0645, 0, 0, 150)
DoNotStack.Size = UDim2.new(0, 294, 0, 26)
DoNotStack.ZIndex = 15
DoNotStack.Font = Enum.Font.SourceSans
DoNotStack.Text = "Unstack remote when fired with new args"
DoNotStack.TextColor3 = Color3.fromRGB(250, 251, 255)
DoNotStack.TextSize = 16.000

FrameDivider.Name = "FrameDivider"
FrameDivider.Parent = InfoFrame
FrameDivider.BackgroundColor3 = Color3.fromRGB(53, 59, 72)
FrameDivider.BorderColor3 = Color3.fromRGB(53, 59, 72)
FrameDivider.Position = UDim2.new(0, 3, 0, 0)
FrameDivider.Size = UDim2.new(0, 4, 0, 322)
FrameDivider.ZIndex = 7

local InfoFrameOpen = false
CloseInfoFrame.Name = "CloseInfoFrame"
CloseInfoFrame.Parent = InfoFrame
CloseInfoFrame.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
CloseInfoFrame.BorderColor3 = colorSettings["Main"]["HeaderColor"]
CloseInfoFrame.Position = UDim2.new(0, 333, 0, 2)
CloseInfoFrame.Size = UDim2.new(0, 22, 0, 22)
CloseInfoFrame.ZIndex = 18
CloseInfoFrame.Font = Enum.Font.SourceSansLight
CloseInfoFrame.Text = "X"
CloseInfoFrame.TextColor3 = Color3.fromRGB(0, 0, 0)
CloseInfoFrame.TextSize = 20.000
CloseInfoFrame.MouseButton1Click:Connect(function()
	InfoFrame.Visible = false
	InfoFrameOpen = false
	mainFrame.Size = UDim2.new(0, 207, 0, 35)
end)

OpenInfoFrame.Name = "OpenInfoFrame"
OpenInfoFrame.Parent = mainFrame
OpenInfoFrame.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
OpenInfoFrame.BorderColor3 = colorSettings["Main"]["HeaderColor"]
OpenInfoFrame.Position = UDim2.new(0, 185, 0, 2)
OpenInfoFrame.Size = UDim2.new(0, 22, 0, 22)
OpenInfoFrame.ZIndex = 18
OpenInfoFrame.Font = Enum.Font.SourceSans
OpenInfoFrame.Text = ">"
OpenInfoFrame.TextColor3 = Color3.fromRGB(0, 0, 0)
OpenInfoFrame.TextSize = 16.000
OpenInfoFrame.MouseButton1Click:Connect(function()
	if not InfoFrame.Visible then
		mainFrame.Size = UDim2.new(0, 565, 0, 35)
		OpenInfoFrame.Text = "<"
	elseif RemoteScrollFrame.Visible then
		mainFrame.Size = UDim2.new(0, 207, 0, 35)
		OpenInfoFrame.Text = ">"
	end
	InfoFrame.Visible = not InfoFrame.Visible
	InfoFrameOpen = not InfoFrameOpen
end)

Minimize.Name = "Minimize"
Minimize.Parent = mainFrame
Minimize.BackgroundColor3 = colorSettings["Main"]["HeaderColor"]
Minimize.BorderColor3 = colorSettings["Main"]["HeaderColor"]
Minimize.Position = UDim2.new(0, 164, 0, 2)
Minimize.Size = UDim2.new(0, 22, 0, 22)
Minimize.ZIndex = 18
Minimize.Font = Enum.Font.SourceSans
Minimize.Text = "_"
Minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
Minimize.TextSize = 16.000
Minimize.MouseButton1Click:Connect(function()
	-- Close
	if RemoteScrollFrame.Visible then
		mainFrame.Size = UDim2.new(0, 207, 0, 35)
		OpenInfoFrame.Text = "<"
		InfoFrame.Visible = false
	else
		--Open
		if InfoFrameOpen then
			mainFrame.Size = UDim2.new(0, 565, 0, 35)
			OpenInfoFrame.Text = "<"
			InfoFrame.Visible = true
		else
			mainFrame.Size = UDim2.new(0, 207, 0, 35)
			OpenInfoFrame.Text = ">"
			InfoFrame.Visible = false
		end
	end
	RemoteScrollFrame.Visible = not RemoteScrollFrame.Visible
end)
