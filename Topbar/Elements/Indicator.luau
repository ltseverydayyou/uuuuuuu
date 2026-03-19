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

return function(icon, Icon)
	local widget = icon.widget;
	local contents = icon:getInstance("Contents");
	local indicator = Instance.new("Frame");
	indicator.Name = "Indicator";
	indicator.LayoutOrder = 9999999;
	indicator.ZIndex = 6;
	indicator.Size = UDim2.new(0, 42, 0, 42);
	indicator.BorderColor3 = Color3.fromRGB(0, 0, 0);
	indicator.BackgroundTransparency = 1;
	indicator.Position = UDim2.new(1, 0, 0.5, 0);
	indicator.BorderSizePixel = 0;
	indicator.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
	indicator.Parent = contents;
	local indicatorButton = Instance.new("Frame");
	indicatorButton.Name = "IndicatorButton";
	indicatorButton.BorderColor3 = Color3.fromRGB(0, 0, 0);
	indicatorButton.AnchorPoint = Vector2.new(0.5, 0.5);
	indicatorButton.BorderSizePixel = 0;
	indicatorButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
	indicatorButton.Parent = indicator;
	local GuiService = __lt.cs("GuiService", cloneref);
	local GamepadService = __lt.cs("GamepadService", cloneref);
	local ourClickRegion = icon:getInstance("ClickRegion");
	local function selectionChanged()
		local selectedClickRegion = GuiService.SelectedObject;
		if selectedClickRegion == ourClickRegion then
			indicatorButton.BackgroundTransparency = 1;
			indicatorButton.Position = UDim2.new(0.5, -2, 0.5, 0);
			indicatorButton.Size = UDim2.fromScale(1.2, 1.2);
		else
			indicatorButton.BackgroundTransparency = 0.75;
			indicatorButton.Position = UDim2.new(0.5, 2, 0.5, 0);
			indicatorButton.Size = UDim2.fromScale(1, 1);
		end;
	end;
	icon.janitor:add((__lt.cm("GuiService", "GetPropertyChangedSignal", "SelectedObject")):Connect(selectionChanged));
	selectionChanged();
	local imageLabel = Instance.new("ImageLabel");
	imageLabel.LayoutOrder = 2;
	imageLabel.ZIndex = 15;
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5);
	imageLabel.Size = UDim2.new(0.5, 0, 0.5, 0);
	imageLabel.BackgroundTransparency = 1;
	imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0);
	imageLabel.Image = "rbxasset://textures/ui/Controls/XboxController/DPadUp@2x.png";
	imageLabel.Parent = indicatorButton;
	local UICorner = Instance.new("UICorner");
	UICorner.CornerRadius = UDim.new(1, 0);
	UICorner.Parent = indicatorButton;
	local UserInputService = __lt.cs("UserInputService", cloneref);
	local function setIndicatorVisible(visibility)
		if visibility == nil then
			visibility = indicator.Visible;
		end;
		if GamepadService.GamepadCursorEnabled then
			visibility = false;
		end;
		if visibility then
			icon:modifyTheme({
				"PaddingRight",
				"Size",
				UDim2.new(0, 0, 1, 0)
			}, "IndicatorPadding");
		elseif indicator.Visible then
			icon:removeModification("IndicatorPadding");
		end;
		icon:modifyTheme({
			"Indicator",
			"Visible",
			visibility
		});
		icon.updateSize:Fire();
	end;
	icon.janitor:add((__lt.cm("GamepadService", "GetPropertyChangedSignal", "GamepadCursorEnabled")):Connect(setIndicatorVisible));
	icon.indicatorSet:Connect(function(keyCode)
		local visibility = false;
		if keyCode then
			if typeof(keyCode) == "EnumItem" then
				imageLabel.Image = __lt.cm("UserInputService", "GetImageForKeyCode", keyCode);
				visibility = true;
			else
				local id = tostring(keyCode);
				imageLabel.Image = id;
				visibility = true;
			end;
		end;
		setIndicatorVisible(visibility);
	end);
	local function updateSize()
		local ySize = widget.AbsoluteSize.Y * 0.96;
		indicator.Size = UDim2.new(0, ySize, 0, ySize);
	end;
	(widget:GetPropertyChangedSignal("AbsoluteSize")):Connect(updateSize);
	updateSize();
	return indicator;
end;
