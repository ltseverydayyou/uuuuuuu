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
	local RunService = __lt.cs("RunService", cloneref);
	local GuiService = __lt.cs("GuiService", cloneref);
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
