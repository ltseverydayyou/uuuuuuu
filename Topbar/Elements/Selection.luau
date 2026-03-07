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


return function(Icon)
	local selectionContainer = Instance.new("Frame");
	selectionContainer.Name = "SelectionContainer";
	selectionContainer.Visible = false;
	local selection = Instance.new("Frame");
	selection.Name = "Selection";
	selection.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	selection.BackgroundTransparency = 1;
	selection.BorderColor3 = Color3.fromRGB(0, 0, 0);
	selection.BorderSizePixel = 0;
	selection.Parent = selectionContainer;
	local UIStroke = Instance.new("UIStroke");
	UIStroke.Name = "UIStroke";
	UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	UIStroke.Color = Color3.fromRGB(255, 255, 255);
	UIStroke.Thickness = 3;
	UIStroke.Parent = selection;
	local selectionGradient = Instance.new("UIGradient");
	selectionGradient.Name = "SelectionGradient";
	selectionGradient.Parent = UIStroke;
	local UICorner = Instance.new("UICorner");
	UICorner:SetAttribute("Collective", "IconCorners");
	UICorner.Name = "UICorner";
	UICorner.CornerRadius = UDim.new(1, 0);
	UICorner.Parent = selection;
	local RunService = __lt_clone_service("RunService", cloneref);
	local GuiService = __lt_clone_service("GuiService", cloneref);
	local rotationSpeed = 1;
	(selection:GetAttributeChangedSignal("RotationSpeed")):Connect(function()
		rotationSpeed = selection:GetAttribute("RotationSpeed");
	end);
	RunService.Heartbeat:Connect(function()
		if not GuiService.SelectedObject then
			return;
		end;
		selectionGradient.Rotation = os.clock() * rotationSpeed * 100 % 360;
	end);
	return selectionContainer;
end;
