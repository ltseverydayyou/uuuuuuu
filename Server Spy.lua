local ui=nil
local Gui = game:GetObjects("rbxassetid://18266429159")[1]
local COREGUI= (game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"))
local connect=nil
local rPlayer = game:GetService("Players"):FindFirstChildWhichIsA("Player")
local con=nil
local con1=nil
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

local SRSFrame = ui.SRS
local SRSList = SRSFrame.Container.Logs
local SRSresult = SRSFrame.result.answer
local SRStxt = SRSresult.txt
local SRSExample = SRSList.mrlabel
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
	exit.MouseButton1Click:Connect(function()
		if con then con:Disconnect() con=nil end
		if con1 then con1:Disconnect() con1=nil end
		if connect then connect:Disconnect() connect=nil end
		ui:Destroy()
	end)
	if clear then 
		clear.MouseButton1Click:Connect(function()
			local t=menu:FindFirstChild("Container",true):FindFirstChildOfClass("ScrollingFrame"):FindFirstChildOfClass("UIListLayout",true)
			for _,v in ipairs(t.Parent:GetChildren()) do
				if v:IsA("TextLabel") or v:IsA("TextButton") then
					v:Destroy()
				end
			end
			SRStxt.Text=". . ."
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

function PathInstance(instance)
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
end

function formatValue(value)
    if typeof(value) == "string" then
        return string.format("%q", value)
    elseif typeof(value) == "number" then
        return tostring(value)
    elseif typeof(value) == "boolean" then
        return value and "true" or "false"
    elseif typeof(value) == "Instance" then
        return PathInstance(value)
    elseif typeof(value) == "table" then
        local result = "{ "
        for k, v in pairs(value) do
            result = result .. string.format("[%s] = %s;\n", formatValue(k), formatValue(v))
        end
        result = result:sub(1, -2)
        return result .. " }"
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
	local fullPath = remote:GetFullName() --table.concat(path, ".")
	if remote:IsA("RemoteEvent") then
		remote.OnClientEvent:Connect(function(...)
			local args = {...}
			local argsFormatted = Format(args)
			local argsString = table.concat(argsFormatted, ", ")

			_G.Code = string.format("RemoteEvent: [game.%s]\nreturned: %s", fullPath, argsString)
			local template = SRSExample
			local list = SRSList
			local btn = template:Clone()
			btn.Parent=list
			btn.Name=cursed()
			btn.Text=_G.Code
			btn.MouseButton1Click:connect(function()
				SRStxt.Text=btn.Text
			end)

			return ...
		end)
	elseif remote:IsA("RemoteFunction") then
		remote.OnClientInvoke = function(...)
			local args = {...}
			local argsFormatted = Format(args)
			local argsString = table.concat(argsFormatted, ", ")

			_G.Code = string.format("RemoteFunction: [game.%s]\nreturned: %s", fullPath, argsString)
			local template = SRSExample
			local list = SRSList
			local btn = template:Clone()
			btn.Parent=list
			btn.Name=cursed()
			btn.Text=_G.Code
			btn.MouseButton1Click:connect(function()
				SRStxt.Text=btn.Text
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

connect = game:GetService("RunService").Stepped:Connect(function()
	SRSList.CanvasSize = UDim2.new(0, 0, 0, SRSList:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y)
	SRSresult.CanvasSize = UDim2.new(0, 0, 0, SRSresult:FindFirstChildOfClass("UIListLayout").AbsoluteContentSize.Y)
end)