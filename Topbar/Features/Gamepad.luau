local __lt = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {};
	local sharedEnv = rawget(_G, "shared");
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil);
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver");
		if type(cached) == "table" then
			return cached;
		end;
	end;
	local loader = loadstring or load;
	if type(loader) ~= "function" then
		error("Service resolver loader unavailable");
	end;
	local resolver = loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau");
	if type(resolver) ~= "function" then
		error("Service resolver failed to compile");
	end;
	local loaded = resolver();
	if type(loaded) ~= "table" then
		error("Service resolver failed to load");
	end;
	if cacheHost then
		cacheHost.__lt_service_resolver = loaded;
	end;
	return loaded;
end)();

local GamepadService = __lt.cs("GamepadService", cloneref)
local UserInputService = __lt.cs("UserInputService", cloneref)
local GuiService = __lt.cs("GuiService", cloneref)




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
		__lt.cm("GuiService", "GetPropertyChangedSignal", "SelectedObject"):Connect(updateSelectedObject)


		local function preferredInputChanged()
			local preferredInput = UserInputService.PreferredInput
			local isUsingGamepad = preferredInput == GAMEPAD_INPUT

			if not isUsingGamepad then
				usedIndicatorOnce = false
				usedBOnce = false
			end
			updateSelectedObject()
		end
		__lt.cm("UserInputService", "GetPropertyChangedSignal", "PreferredInput"):Connect(preferredInputChanged)
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
					__lt.cm("GamepadService", "DisableGamepadCursor")
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
			__lt.cm("GamepadService", "DisableGamepadCursor")
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
