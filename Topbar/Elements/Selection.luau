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
