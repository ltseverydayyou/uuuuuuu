local ui=nil
local Gui = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/srs%20UI.lua"))()
local COREGUI= (game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"))
local connect,copyCon,fireCon,smallButton=nil,nil,nil,nil
local rPlayer = game:GetService("Players"):FindFirstChildWhichIsA("Player")
local con=nil
local con1=nil
local order=0
local coreGuiProtection = {}
ui=Gui
function cursed()
	local length = math.random(10,20)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end
if get_hidden_gui or gethui then
	local hiddenUI = get_hidden_gui or gethui
	local Main = Gui
	Main.Name = cursed()
	Main.Parent = hiddenUI()
	ui = Main
elseif (not is_sirhurt_closure) and (syn and syn.protect_gui) then
	local Main = Gui
	Main.Name = cursed()
	syn.protect_gui(Main)
	Main.Parent = COREGUI
	ui = Main
elseif COREGUI:FindFirstChild('RobloxGui') then
	pcall(function()
		for i, v in pairs(ui:GetDescendants()) do
			coreGuiProtection[v] = rPlayer.Name
		end
		ui.DescendantAdded:Connect(function(v)
			coreGuiProtection[v] = rPlayer.Name
		end)
		coreGuiProtection[ui] = rPlayer.Name

		local meta = getrawmetatable(game)
		local tostr = meta.__tostring
		setreadonly(meta, false)
		meta.__tostring = newcclosure(function(t)
			if coreGuiProtection[t] and not checkcaller() then
				return coreGuiProtection[t]
			end
			return tostr(t)
		end)
	end)
	if not game:GetService("RunService"):IsStudio() then
		local newGui = game:GetService("CoreGui"):FindFirstChildWhichIsA("ScreenGui")
		newGui.DescendantAdded:Connect(function(v)
			coreGuiProtection[v] = rPlayer.Name
		end)
		for i, v in pairs(ui:GetChildren()) do
			v.Parent = newGui
		end
		ui = newGui
	end
else
	local Main = Gui
	Main.Name = cursed()
	Main.Parent = COREGUI
	ui = Main
end

local SRSFrame = ui:FindFirstChildWhichIsA("Frame")
local SRSList = SRSFrame.Container.Logs
local SRSresult = SRSFrame.result.answer
local SRSresulter = SRSFrame.result
local SRStxt = SRSresult:FindFirstChildWhichIsA("TextLabel")
local SRSExample = SRSList:FindFirstChildWhichIsA("TextButton")
local copySignalBtn=SRSresulter.copySignal
local fireSignalBtn=SRSresulter.fireSignal
SRSExample.Parent = nil

Draggable = function(ui, dragui)
	if not dragui then dragui = ui end
	local UserInputService = game:GetService("UserInputService")

	local dragging
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		ui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	dragui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = ui.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragui.InputChanged:Connect(function(input)
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
tweeny = function(obj, style, direction, duration, goal)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle[style], Enum.EasingDirection[direction])
	local tween = game:GetService("TweenService"):Create(obj, tweenInfo, goal)
	tween:Play()
	return tween
end
menustuff = function(menu)
	local exit = menu:FindFirstChild("Exit", true)
	local mini = menu:FindFirstChild("Minimize", true)
	local clear = menu:FindFirstChild("Clear", true);
	local minimized = false
	local sizeX, sizeY = Instance.new("IntValue", menu), Instance.new("IntValue", menu)
	if mini then
		mini.MouseButton1Click:Connect(function()
			minimized = not minimized
			if minimized then
				sizeX.Value = menu.Size.X.Offset
				sizeY.Value = menu.Size.Y.Offset
				tweeny(menu, "Quart", "Out", 0.5, {Size = UDim2.new(0, 283, 0, 25)})
			else
				tweeny(menu, "Quart", "Out", 0.5, {Size = UDim2.new(0, sizeX.Value, 0, sizeY.Value)})
			end
		end)
	end
	if exit then
		exit.MouseButton1Click:Connect(function()
			if con then con:Disconnect() con=nil end
			if con1 then con1:Disconnect() con1=nil end
			if connect then connect:Disconnect() connect=nil end
			if copyCon then copyCon:Disconnect() copyCon=nil end
			if fireCon then fireCon:Disconnect() fireCon=nil end
			if smallButton then smallButton:Disconnect() smallButton=nil end
			ui:Destroy()
		end)
	end
	if clear then 
		clear.MouseButton1Click:Connect(function()
			local t=menu:FindFirstChild("Container",true):FindFirstChildOfClass("ScrollingFrame"):FindFirstChildOfClass("UIListLayout",true)
			for _,v in ipairs(t.Parent:GetChildren()) do
				if v:IsA("TextLabel") or v:IsA("TextButton") then
					v:Destroy()
				end
			end
			SRStxt.Text=". . ."
			_G.SRSclass,_G.SRSargs,_G.SRSpath=nil,nil,nil
			order=0
		end)
	end
	Draggable(menu, menu.Topbar)
end

function updTxtScale()
	local width = SRStxt.AbsoluteSize.X
	local text = SRStxt.Text
	local font = SRStxt.Font
	local textSize = SRStxt.TextSize
	local textBounds = game:GetService("TextService"):GetTextSize(text, textSize, font, Vector2.new(width, math.huge))
	SRStxt.Size = UDim2.new(1, 0, 0, textBounds.Y)
end

--[[function PathInstance(instance)
	local path = {}
	local current = instance
	while current and current ~= game do
		local name = current.Name
		if name:sub(1, 4) == "Game" then
			name = "game" .. name:sub(5)
		end
		table.insert(path, 1, name)
		current = current.Parent
	end
	return table.concat(path, ".")
end]]

local function GetInstancePath(obj)
	local path = {}

	function b(obj)
		return obj.Parent == game and obj ~= game
	end

	if b(obj) then
		table.insert(path, string.format('game:GetService("%s")',obj.ClassName))
	else
		while obj and obj.Parent do
			local name = obj.Name
			if name:match("^[%a_][%w_]*$") then
				table.insert(path, 1, "."..name)
			else
				table.insert(path, 1, '["'..name:gsub('"', '\\"')..'"]')
			end

			if b(obj.Parent) then
				table.insert(path, 1, string.format('game:GetService("%s")', obj.Parent.ClassName))
				break
			end

			obj = obj.Parent
		end
	end

	return table.concat(path):gsub("^%.", "")
end

local function GetChildPath(obj)
	local path = {}

	local function b(obj)
		return obj.Parent == game and obj ~= game
	end

	if b(obj) then
		table.insert(path, string.format('game:GetService("%s")', obj.ClassName))
	else
		while obj and obj.Parent do
			local name = obj.Name
			if name:match("^[%a_][%w_]*$") then
				table.insert(path, 1, ":FindFirstChild(\"" .. name .. "\")")
			else
				table.insert(path, 1, '["' .. name:gsub('"', '\\"') .. '"]')
			end

			if b(obj.Parent) then
				table.insert(path, 1, string.format('game:GetService("%s")', obj.Parent.ClassName))
				break
			end

			obj = obj.Parent
		end
	end

	return table.concat(path):gsub("^%.", "")
end

function formatValue(value)
	if typeof(value) == "string" then
		return string.format("%q", value)
	elseif typeof(value) == "number" then
		return tostring(value)
	elseif typeof(value) == "boolean" then
		return value and "true" or "false"
	elseif typeof(value) == "Instance" then
		return GetInstancePath(value)
	elseif typeof(value) == "table" then
		local result = "{ "
		for k, v in pairs(value) do
			result = result .. string.format("[%s] = %s; \n", formatValue(k), formatValue(v))
		end
		result = result:sub(1, -2)
		return result .. "}"
	else
		return string.format("%q", tostring(value))
	end
end

function Format(args)
	local formattedArgs = {}
	for i, arg in ipairs(args) do
		formattedArgs[i] = string.format("%s", formatValue(arg))
	end
	return formattedArgs
end

function handleRemote(remote)
	--[[local path = {}
	local current = remote
	while current and current.Parent ~= game do
		local name = current.Name
		if name:sub(1, 4) == "Game" then
			name = "game" .. name:sub(5)
		end
		table.insert(path, 1, name)
		current = current.Parent
	end]]
	local fullPath = GetInstancePath(remote) --table.concat(path, ".")
	local findChildPath = GetChildPath(remote)
	if remote:IsA("RemoteEvent") then
		remote.OnClientEvent:Connect(function(...)
			local args = {...}
			local argsFormatted = Format(args)
			local argsString = table.concat(argsFormatted, ", ")
			local replacer = ''
			
			if argsString~='' then
				replacer = ", "..argsString
			else
				argsString='nil'
			end

			_G.Code = string.format("RemoteEvent: [%s]\nreturned: %s", fullPath, argsString)
			local template = SRSExample
			local list = SRSList
			local btn = template:Clone()
			--order=order-1
			btn.Parent=list
			btn.Name=cursed()
			btn.Text=_G.Code
			--btn.LayoutOrder=order
			btn.MouseButton1Click:connect(function()
				SRStxt.Text=btn.Text
				_G.SRSclass,_G.SRSargs,_G.SRSpath=".OnClientEvent",replacer,findChildPath
			end)

			return ...
		end)
	elseif remote:IsA("RemoteFunction") then
		remote.OnClientInvoke = function(...)
			local args = {...}
			local argsFormatted = Format(args)
			local argsString = table.concat(argsFormatted, ", ")
			local replacer = ''
			
			if argsString~='' then
				replacer = ", "..argsString
			else
				argsString='nil'
			end

			_G.Code = string.format("RemoteFunction: [%s]\nreturned: %s", fullPath, argsString)
			local template = SRSExample
			local list = SRSList
			local btn = template:Clone()
			--order=order-1
			btn.Parent=list
			btn.Name=cursed()
			btn.Text=_G.Code
			--btn.LayoutOrder=order
			btn.MouseButton1Click:connect(function()
				SRStxt.Text=btn.Text
				_G.SRSclass,_G.SRSargs,_G.SRSpath=".OnClientInvoke",replacer,findChildPath
			end)

			return ...
		end
	end
end

function wrapRemotes()
	for _, obj in ipairs(game:GetDescendants()) do
		if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
			handleRemote(obj)
		end
	end
	con=game.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("RemoteEvent") or descendant:IsA("RemoteFunction") then
			handleRemote(descendant)
		end
	end)
end

--[[local services = {
	game:GetService("ReplicatedStorage"),
	game:GetService("StarterGui"),
	game:GetService("StarterPack"),
	game:GetService("StarterPlayer"),
	game:GetService("Players"),
	game:GetService("Workspace")
}
]]
--for _, folder in ipairs(services) do
wrapRemotes()
--end

menustuff(SRSFrame)
SRSFrame.Position = UDim2.new(0.5, -283/2+5, 0.5, -260/2+5)

con1=SRStxt:GetPropertyChangedSignal("Text"):Connect(updTxtScale)
spawn(updTxtScale)

connect = game:GetService("RunService").Stepped:Connect(function()
	SRSList.CanvasSize = UDim2.new(0, 0, 0, SRSList:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y)
	SRSresult.CanvasSize = UDim2.new(0, 0, 0, SRSresult:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y)
end)

copyCon = copySignalBtn.MouseButton1Click:Connect(function()
	if setclipboard then 
		if (_G.SRSclass~=nil and _G.SRSargs~=nil and _G.SRSpath~=nil) then
			local thingy = string.format("firesignal(%s)",_G.SRSpath.._G.SRSclass.._G.SRSargs)
			setclipboard(thingy)
		end
	else
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Missing Variable";Text = "setclipboard";Duration = 5;})
	end
end)

fireCon = fireSignalBtn.MouseButton1Click:Connect(function()
	if firesignal then 
		if (_G.SRSclass~=nil and _G.SRSargs~=nil and _G.SRSpath~=nil) then
			local thingy = string.format("firesignal(%s)",_G.SRSpath.._G.SRSclass.._G.SRSargs)
			assert(loadstring(thingy))()
		end
	else
		game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Missing Variable";Text = "firesignal";Duration = 5;})
	end	
end)

local TextLabelLabel=Instance.new("TextButton")
local UICorner=Instance.new("UICorner")
local open=false
TextLabelLabel.Parent=ui
TextLabelLabel.BackgroundColor3=Color3.fromRGB(30, 30, 30)
TextLabelLabel.BackgroundTransparency=0.14
TextLabelLabel.AnchorPoint=Vector2.new(0.5,0.5)
TextLabelLabel.Position=UDim2.new(0.5,0,0,0)
TextLabelLabel.Size=UDim2.new(0,2,0,33)
TextLabelLabel.Font=Enum.Font.SourceSansBold
TextLabelLabel.Text="Toggle UI"
TextLabelLabel.TextColor3=Color3.fromRGB(255,255,255)
TextLabelLabel.TextSize=20.000
TextLabelLabel.TextWrapped=true
TextLabelLabel.ZIndex=9999
TextLabelLabel.BackgroundTransparency=0.14
TextLabelLabel.Active=true
TextLabelLabel.Draggable=true

UICorner.CornerRadius=UDim.new(1,0)
UICorner.Parent=TextLabelLabel

local textWidth=game:GetService("TextService"):GetTextSize(TextLabelLabel.Text,TextLabelLabel.TextSize,TextLabelLabel.Font,Vector2.new(math.huge,math.huge)).X
local newSize=UDim2.new(0,textWidth+69,0,33)

TextLabelLabel:TweenSize(newSize,"Out","Quint",1,true)
TextLabelLabel:TweenPosition(UDim2.new(0.5,0,0,0),"Out","Quint",1,true)

smallButton=TextLabelLabel.MouseButton1Click:Connect(function()
	if open == false then
		open = true
		SRSFrame.Visible = false
	else
		open = false
		SRSFrame.Visible = true
	end
end)