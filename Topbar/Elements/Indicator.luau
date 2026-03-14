local __lt = {
	cr = type(cloneref) == "function" and cloneref or nil;
	svc = {
		cache = {};
		fallback = {};
		invalid = {};
	};
};
function __lt.sv(value)
	return typeof(value) == "Instance";
end;
function __lt.fs(name)
	local ok, service = pcall(function()
		return game:FindService(name);
	end);
	if ok and __lt.sv(service) then
		return service;
	end;
	return nil;
end;
function __lt.ns(name)
	local ok, service = pcall(Instance.new, name);
	if ok and __lt.sv(service) then
		return service;
	end;
	return nil;
end;
function __lt.gs(name)
	local cached = __lt.svc.cache[name];
	local isFallback = __lt.svc.fallback[name] == true;
	if __lt.sv(cached) and not isFallback then
		return cached;
	end;
	local service = __lt.fs(name);
	if __lt.sv(service) then
		__lt.svc.invalid[name] = nil;
		__lt.svc.cache[name] = service;
		__lt.svc.fallback[name] = nil;
		return service;
	end;
	if __lt.sv(cached) and isFallback then
		return cached;
	end;
	if __lt.svc.invalid[name] then
		return nil;
	end;
	service = __lt.ns(name);
	if __lt.sv(service) then
		__lt.svc.cache[name] = service;
		__lt.svc.fallback[name] = true;
		return service;
	end;
	__lt.svc.invalid[name] = true;
	return nil;
end;
function __lt.cv(value)
	if __lt.cr and typeof(value) == "Instance" then
		local ok, cloned = pcall(__lt.cr, value);
		if ok and cloned ~= nil then
			return cloned;
		end;
	end;
	return value;
end;
function __lt.cs(name, refFn)
	if type(refFn) ~= "function" then
		return __lt.gs(name);
	end;
	local ok, ref = pcall(function()
		return refFn(game:FindService(name));
	end);
	if ok and __lt.sv(ref) then
		return ref;
	end;
	local service = __lt.fs(name);
	if __lt.sv(service) then
		return service;
	end;
	if __lt.svc.invalid[name] then
		return nil;
	end;
	local fallbackOk, fallbackRef = pcall(function()
		return refFn(Instance.new(name));
	end);
	if fallbackOk and __lt.sv(fallbackRef) then
		return fallbackRef;
	end;
	service = __lt.ns(name);
	if __lt.sv(service) then
		return service;
	end;
	__lt.svc.invalid[name] = true;
	return nil;
end;
function __lt.ig(method)
	return method == "FindFirstChild"
		or method == "WaitForChild"
		or method == "FindFirstChildOfClass"
		or method == "FindFirstChildWhichIsA"
		or method == "FindFirstAncestor"
		or method == "FindFirstAncestorOfClass"
		or method == "FindFirstAncestorWhichIsA"
		or method == "GetChildren"
		or method == "GetDescendants"
		or method == "QueryDescendants";
end;
function __lt.cm(name, method, ...)
	local service = __lt.cs(name, __lt.cr);
	if not __lt.sv(service) then
		error(string.format("Service %s could not be resolved", tostring(name)));
	end;
	local fn = service[method];
	if type(fn) ~= "function" then
		error(string.format("Service method %s.%s is not callable", tostring(name), tostring(method)));
	end;
	return fn(service, ...);
end;

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
