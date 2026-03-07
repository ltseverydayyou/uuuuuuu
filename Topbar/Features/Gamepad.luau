local __lt_oldcloneref = type(cloneref) == "function" and cloneref or nil;
local function __lt_clone_service_value(value)
	if __lt_oldcloneref and typeof(value) == "Instance" then
		local ok, cloned = pcall(__lt_oldcloneref, value);
		if ok and cloned ~= nil then
			return cloned;
		end;
	end;
	return value;
end;
local function __lt_clone_service(name, refFn)
	if type(refFn) ~= "function" then
		return game:GetService(name);
	end;
	local ok, ref = pcall(function()
		return refFn(game:GetService(name));
	end);
	if ok and ref ~= nil then
		return ref;
	end;
	return game:GetService(name);
end;
local function __lt_call_service_method(name, method, ...)
	local service = game:GetService(name);
	local fn = service[method];
	if type(fn) ~= "function" then
		error(string.format("Service method %s.%s is not callable", tostring(name), tostring(method)));
	end;
	return fn(service, ...);
end;


local GamepadService = __lt_clone_service("GamepadService", cloneref)
local UserInputService = __lt_clone_service("UserInputService", cloneref)
local GuiService = __lt_clone_service("GuiService", cloneref)




local DEFAULT_HIGHLIGHT_KEY = Enum.KeyCode.DPadUp
local GAMEPAD_INPUT = Enum.PreferredInput.Gamepad
local Gamepad = {}
local Icon





function Gamepad.start(incomingIcon)


	Icon = incomingIcon
	Icon.highlightKey = if Icon.highlightKey ~= nil then Icon.highlightKey else DEFAULT_HIGHLIGHT_KEY
	Icon.highlightIcon = false



	task.delay(1, function()

		local iconsDict = Icon.iconsDictionary
		local function getIconFromSelectedObject()
			local clickRegion = GuiService.SelectedObject
			local iconUID = clickRegion and clickRegion:GetAttribute("CorrespondingIconUID")
			local icon = iconUID and iconsDict[iconUID]
			return icon
		end


		local previousHighlightedIcon
		local usedIndicatorOnce = DEFAULT_HIGHLIGHT_KEY ~= Icon.highlightKey
		local usedBOnce = DEFAULT_HIGHLIGHT_KEY ~= Icon.highlightKey
		local Selection = Import(script.Parent.Parent.Elements.Selection)
		local function updateSelectedObject()
			local icon = getIconFromSelectedObject()
			local isUsingGamepad = UserInputService.PreferredInput == GAMEPAD_INPUT
			if icon then
				if isUsingGamepad then
					local clickRegion = icon:getInstance("ClickRegion")
					local selection = icon.selection
					if not selection then
						selection = icon.janitor:add(Selection(Icon))
						selection:SetAttribute("IgnoreVisibilityUpdater", true)
						selection.Parent = icon.widget
						icon.selection = selection
						icon:refreshAppearance(selection)
					end
					clickRegion.SelectionImageObject = selection.Selection
				end
				if previousHighlightedIcon and previousHighlightedIcon ~= icon then
					previousHighlightedIcon:setIndicator()
				end
				local newIndicator = if isUsingGamepad and not usedBOnce and not icon.parentIconUID then Enum.KeyCode.ButtonB else nil
				previousHighlightedIcon = icon
				Icon.lastHighlightedIcon = icon
				icon:setIndicator(newIndicator)
			else
				local newIndicator = if isUsingGamepad and not usedIndicatorOnce then Icon.highlightKey else nil
				if not previousHighlightedIcon then
					previousHighlightedIcon = Gamepad.getIconToHighlight()
				end
				if newIndicator == Icon.highlightKey then


					usedIndicatorOnce = true
				else

				end
				if previousHighlightedIcon then
					previousHighlightedIcon:setIndicator(newIndicator)
				end
			end
		end
		__lt_call_service_method("GuiService", "GetPropertyChangedSignal", "SelectedObject"):Connect(updateSelectedObject)


		local function preferredInputChanged()
			local preferredInput = UserInputService.PreferredInput
			local isUsingGamepad = preferredInput == GAMEPAD_INPUT

			if not isUsingGamepad then
				usedIndicatorOnce = false
				usedBOnce = false
			end
			updateSelectedObject()
		end
		__lt_call_service_method("UserInputService", "GetPropertyChangedSignal", "PreferredInput"):Connect(preferredInputChanged)
		preferredInputChanged()




		UserInputService.InputBegan:Connect(function(input, touchingAnObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then



				local icon = getIconFromSelectedObject()
				if icon then
					GuiService.SelectedObject = nil
				end
				return
			end
			if input.KeyCode ~= Icon.highlightKey then
				return
			end
			local iconToHighlight = Gamepad.getIconToHighlight()
			if iconToHighlight then
				if GamepadService.GamepadCursorEnabled then
					task.wait(0.2)
					__lt_call_service_method("GamepadService", "DisableGamepadCursor")
				end
				local clickRegion = iconToHighlight:getInstance("ClickRegion")
				GuiService.SelectedObject = clickRegion
			end
		end)
	end)
end

function Gamepad.getIconToHighlight()


	local iconsDict = Icon.iconsDictionary
	local iconToHighlight = Icon.highlightIcon or Icon.lastHighlightedIcon
	if not iconToHighlight then
		local currentX
		for _, icon in pairs(iconsDict) do
			if icon.parentIconUID then
				continue
			end
			local thisX = icon.widget.AbsolutePosition.X
			if not currentX or thisX < currentX then
				iconToHighlight = icon
				currentX = iconToHighlight.widget.AbsolutePosition.X
			end
		end
	end
	return iconToHighlight
end


function Gamepad.registerButton(buttonInstance)




	local inputBegan = false
	buttonInstance.InputBegan:Connect(function(input)



		inputBegan = true
		task.wait()
		task.wait()
		inputBegan = false
	end)
	local connection = UserInputService.InputBegan:Connect(function(input)
		task.wait()
		if input.KeyCode == Enum.KeyCode.ButtonA and inputBegan then

			task.wait(0.2)
			__lt_call_service_method("GamepadService", "DisableGamepadCursor")
			GuiService.SelectedObject = buttonInstance
			return
		end
		local isSelected = GuiService.SelectedObject == buttonInstance
		local unselectKeyCodes = {"ButtonB", "ButtonSelect"}
		local keyName = input.KeyCode.Name
		if table.find(unselectKeyCodes, keyName) and isSelected then



			if not(keyName == "ButtonSelect" and not GamepadService.GamepadCursorEnabled) then
				GuiService.SelectedObject = nil
			end
		end
	end)
	buttonInstance.Destroying:Once(function()
		connection:Disconnect()
	end)
end



return Gamepad
