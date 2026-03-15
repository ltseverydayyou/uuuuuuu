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
local CoreGui = __betterGetService("CoreGui")
local UserInput = __betterGetService("UserInputService")
local HttpService = __betterGetService("HttpService")

local Interface = import("rbxassetid://11389137937")

if oh.Cache["ui/main"] then
	return Interface
end

import("ui/controls/TabSelector")
local MessageBox, MessageType = import("ui/controls/MessageBox")

local RemoteSpy
local ClosureSpy
local ScriptScanner
local ModuleScanner
local UpvalueScanner
local ConstantScanner

xpcall(function()
	RemoteSpy = import("ui/modules/RemoteSpy")
	ClosureSpy = import("ui/modules/ClosureSpy")
	ScriptScanner = import("ui/modules/ScriptScanner")
	ModuleScanner = import("ui/modules/ModuleScanner")
	UpvalueScanner = import("ui/modules/UpvalueScanner")
	ConstantScanner = import("ui/modules/ConstantScanner")
end, function(err)
	local message
	if err:find("valid member") then
		message = "The UI has updated, please rejoin and restart. If you get this message more than once, screenshot this message and report it in the Hydroxide server.\n\n" .. err
	else
		message = "Report this error in Hydroxide's server:\n\n" .. err
	end

	MessageBox.Show("An error has occurred", message, MessageType.OK, function()
		Interface:Destroy() 
	end)
end)

local constants = {
	reveal = UDim2.new(0.5, -15, 0, 20),
	conceal = UDim2.new(0.5, -15, 0, -75)
}

local Open = Interface.Open
local Base = Interface.Base
local Drag = Base.Drag
local Status = Base.Status
local Collapse = Drag.Collapse

function oh.setStatus(text)
	Status.Text = '• Status: ' .. text
end

function oh.getStatus()
	return Status.Text:gsub('• Status: ', '')
end

local dragging
local dragStart
local startPos
local dragInput
local collapsed = false

local function updateDrag(input)
	local delta = input.Position - dragStart
	Base.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Drag.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local dragEnded 

		dragging = true
		dragStart = input.Position
		startPos = Base.Position
		dragInput = input

		dragEnded = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				dragEnded:Disconnect()
			end
		end)
	end
end)

Drag.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

oh.Events.Drag = UserInput.InputChanged:Connect(function(input)
	if dragging and input == dragInput then
		updateDrag(input)
	end
end)

local function getOpenedPos()
	local height = Base.AbsoluteSize.Y
	if not height or height <= 0 then
		height = 350
	end
	return UDim2.new(0.5, -325, 0.5, -math.floor(height / 2))
end

local function getClosedPos()
	local height = Base.AbsoluteSize.Y
	if not height or height <= 0 then
		height = 350
	end
	return UDim2.new(0.5, -325, 0, -height - 20)
end

Open.Activated:Connect(function()
	collapsed = false
	Base.Visible = true
	Open:TweenPosition(constants.conceal, "Out", "Quad", 0.15)
	Base:TweenPosition(getOpenedPos(), "Out", "Quad", 0.15)
end)

Collapse.Activated:Connect(function()
	collapsed = true
	Base:TweenPosition(getClosedPos(), "Out", "Quad", 0.15)
	Open:TweenPosition(constants.reveal, "Out", "Quad", 0.15)
	Delay(0.18, function()
		if collapsed then
			Base.Visible = false
		end
	end)
end)

Interface.Name = HttpService:GenerateGUID(false)
if getHui then
	Interface.Parent = getHui()
else
	if syn then
		syn.protect_gui(Interface)
	end

	Interface.Parent = CoreGui
end

return Interface
