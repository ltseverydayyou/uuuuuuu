local Players = game:GetService("Players");
local Workspace = game:GetService("Workspace");
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local UserInputService = game:GetService("UserInputService");
local player = Players.LocalPlayer;
local radius = 150;
local CLONE_RATE = 0.2;
local zoomDist, zoomHeight, headOff = 35, 30, 3;
local rayEnabled, overhead = true, false;
local teleportMode = false;
local elapsed = 0;
local clones = {};
local function getRoot()
	local c = player.Character;
	if not c then
		return;
	end;
	local hrp = c:FindFirstChild("HumanoidRootPart");
	if hrp then
		return hrp;
	end;
	if c.PrimaryPart then
		return c.PrimaryPart;
	end;
	for _, v in ipairs(c:GetChildren()) do
		if v:IsA("BasePart") then
			return v;
		end;
	end;
end;
local guiParent = gethui and gethui() or player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui");
local screenGui = Instance.new("ScreenGui");
screenGui.Name = "MiniMapGui";
screenGui.ResetOnSpawn = false;
screenGui.IgnoreGuiInset = true;
screenGui.Parent = guiParent;
local container = Instance.new("Frame");
container.Name = "MiniMapContainer";
container.AnchorPoint = Vector2.new(1, 0);
container.Position = UDim2.new(0.95, 0, 0.05, 0);
container.Size = UDim2.new(0, 200, 0, 200);
container.BackgroundColor3 = Color3.fromRGB(18, 18, 18);
container.BackgroundTransparency = 0.05;
container.BorderSizePixel = 0;
container.ClipsDescendants = false;
container.Active = true;
container.Parent = screenGui;
local corner = Instance.new("UICorner");
corner.CornerRadius = UDim.new(0, 8);
corner.Parent = container;
local stroke = Instance.new("UIStroke");
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
stroke.Thickness = 2;
stroke.Transparency = 0.25;
stroke.Parent = container;
local viewport = Instance.new("ViewportFrame");
viewport.Name = "MiniMapViewport";
viewport.Size = UDim2.new(1, -8, 1, -32);
viewport.Position = UDim2.new(0, 4, 0, 28);
viewport.BackgroundTransparency = 1;
viewport.LightColor = Color3.new(1, 1, 1);
viewport.Ambient = Color3.fromRGB(180, 180, 180);
viewport.BorderSizePixel = 0;
viewport.Parent = container;
local aspect = Instance.new("UIAspectRatioConstraint");
aspect.AspectRatio = 1;
aspect.Parent = viewport;
local worldModel = Instance.new("WorldModel");
worldModel.Parent = viewport;
local cloneRoot = Instance.new("Model");
cloneRoot.Name = "CloneRoot";
cloneRoot.Parent = worldModel;
local camera = Instance.new("Camera");
camera.FieldOfView = 70;
camera.Parent = viewport;
viewport.CurrentCamera = camera;
local lightPart = Instance.new("Part");
lightPart.Size = Vector3.new(1, 1, 1);
lightPart.Transparency = 1;
lightPart.Anchored = true;
lightPart.CanCollide = false;
lightPart.Parent = worldModel;
local pointLight = Instance.new("PointLight");
pointLight.Brightness = 2;
pointLight.Range = 200;
pointLight.Parent = lightPart;
local marker = Instance.new("Part");
marker.Size = Vector3.new(1, 2, 1);
marker.Anchored = true;
marker.CanCollide = false;
marker.Material = Enum.Material.Neon;
marker.Color = Color3.new(1, 0, 0);
marker.Parent = worldModel;
local msh = Instance.new("SpecialMesh");
msh.MeshType = Enum.MeshType.Sphere;
msh.Scale = Vector3.new(0.4, 0.8, 0.4);
msh.Parent = marker;
local rayParams = RaycastParams.new();
rayParams.FilterType = Enum.RaycastFilterType.Blacklist;
rayParams.IgnoreWater = true;
local overlapParams = OverlapParams.new();
overlapParams.FilterType = Enum.RaycastFilterType.Whitelist;
overlapParams.FilterDescendantsInstances = {
	Workspace
};
local function refreshRayFilter()
	local char = player.Character;
	if char then
		rayParams.FilterDescendantsInstances = {
			char
		};
	else
		rayParams.FilterDescendantsInstances = {};
	end;
end;
player.CharacterAdded:Connect(refreshRayFilter);
if player.Character then
	refreshRayFilter();
end;
local function addClone(p)
	if clones[p] then
		return;
	end;
	if not p:IsDescendantOf(Workspace) then
		return;
	end;
	p.Archivable = true;
	local ok, cp = pcall(p.Clone, p);
	if not ok or (not cp) then
		return;
	end;
	cp.Parent = cloneRoot;
	if cp:IsA("BasePart") then
		cp.Anchored = true;
		cp.CanCollide = false;
	end;
	clones[p] = cp;
end;
local function removeClone(p)
	local cp = clones[p];
	if cp then
		cp:Destroy();
	end;
	clones[p] = nil;
end;
local function refreshClones()
	local root = getRoot();
	if not root then
		return;
	end;
	local rootPos = root.Position;
	local nearbyParts = Workspace:GetPartBoundsInRadius(rootPos, radius, overlapParams);
	local valid = {};
	for _, part in ipairs(nearbyParts) do
		if part:IsA("BasePart") and part.Parent then
			valid[part] = true;
			if not clones[part] then
				addClone(part);
			end;
		end;
	end;
	for p, cp in pairs(clones) do
		if not p.Parent or (not valid[p]) then
			removeClone(p);
		elseif cp:IsA("BasePart") then
			cp.CFrame = p.CFrame;
		end;
	end;
end;
local renderLabel = Instance.new("TextLabel");
renderLabel.Name = "RadiusLabel";
renderLabel.Size = UDim2.new(0.4, 0, 0, 20);
renderLabel.Position = UDim2.new(0.02, 0, 1, -22);
renderLabel.BackgroundTransparency = 1;
renderLabel.TextColor3 = Color3.new(1, 1, 1);
renderLabel.TextXAlignment = Enum.TextXAlignment.Left;
renderLabel.Font = Enum.Font.GothamSemibold;
renderLabel.TextScaled = true;
renderLabel.Text = "R: " .. radius;
renderLabel.Parent = container;
local function styleButton(b)
	b.BackgroundColor3 = Color3.fromRGB(35, 35, 35);
	b.TextColor3 = Color3.new(1, 1, 1);
	b.Font = Enum.Font.GothamSemibold;
	b.TextScaled = true;
	b.AutoButtonColor = true;
	b.BorderSizePixel = 0;
	local c = Instance.new("UICorner");
	c.CornerRadius = UDim.new(0, 4);
	c.Parent = b;
	local s = Instance.new("UIStroke");
	s.Thickness = 1;
	s.Transparency = 0.5;
	s.Parent = b;
end;
local topBar = Instance.new("Frame");
topBar.Size = UDim2.new(1, -8, 0, 24);
topBar.Position = UDim2.new(0, 4, 0, 4);
topBar.BackgroundTransparency = 1;
topBar.Parent = container;
local topLayout = Instance.new("UIListLayout");
topLayout.FillDirection = Enum.FillDirection.Horizontal;
topLayout.VerticalAlignment = Enum.VerticalAlignment.Center;
topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
topLayout.Padding = UDim.new(0, 4);
topLayout.Parent = topBar;
local dragBtn = Instance.new("TextButton");
dragBtn.Name = "DragButton";
dragBtn.Size = UDim2.new(0, 24, 1, 0);
dragBtn.Text = "↕";
dragBtn.Parent = topBar;
styleButton(dragBtn);
local menuBtn = Instance.new("TextButton");
menuBtn.Name = "MenuButton";
menuBtn.Size = UDim2.new(0, 24, 1, 0);
menuBtn.Text = "≡";
menuBtn.Parent = topBar;
styleButton(menuBtn);
local closeBtn = Instance.new("TextButton");
closeBtn.Name = "CloseButton";
closeBtn.Size = UDim2.new(0, 24, 1, 0);
closeBtn.Text = "×";
closeBtn.Parent = topBar;
styleButton(closeBtn);
closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy();
end);
local specs = {
	{
		"+",
		function()
			zoomDist = math.max(5, zoomDist - 5);
			zoomHeight = math.max(5, zoomHeight - 5);
		end
	},
	{
		"–",
		function()
			zoomDist = zoomDist + 5;
			zoomHeight = zoomHeight + 5;
		end
	},
	{
		"Ray:On",
		function(b)
			rayEnabled = not rayEnabled;
			b.Text = rayEnabled and "Ray:On" or "Ray:Off";
		end
	},
	{
		"3D",
		function(b)
			overhead = not overhead;
			b.Text = overhead and "Top" or "3D";
		end
	},
	{
		"TP",
		function(b)
			teleportMode = not teleportMode;
			b.Text = teleportMode and "TP*" or "TP";
		end
	},
	{
		"S+",
		function()
			local size = container.Size;
			local target = UDim2.new(size.X.Scale, size.X.Offset + 40, size.Y.Scale, size.Y.Offset + 40);
			(TweenService:Create(container, TweenInfo.new(0.15), {
				Size = target
			})):Play();
		end
	},
	{
		"S-",
		function()
			local size = container.Size;
			local w = math.max(120, size.X.Offset - 40);
			local h = math.max(120, size.Y.Offset - 40);
			local target = UDim2.new(size.X.Scale, w, size.Y.Scale, h);
			(TweenService:Create(container, TweenInfo.new(0.15), {
				Size = target
			})):Play();
		end
	},
	{
		"R+",
		function()
			radius = radius + 25;
			renderLabel.Text = "R: " .. radius;
		end
	},
	{
		"R-",
		function()
			radius = math.max(25, radius - 25);
			renderLabel.Text = "R: " .. radius;
		end
	}
};
local buttonsHolder = Instance.new("Frame");
buttonsHolder.BackgroundTransparency = 1;
buttonsHolder.Size = UDim2.new(0, 0, 0, 0);
buttonsHolder.Position = UDim2.new(1, 0, 0.5, 0);
buttonsHolder.AnchorPoint = Vector2.new(0, 0.5);
buttonsHolder.Parent = container;
local buttonsLayout = Instance.new("UIListLayout");
buttonsLayout.FillDirection = Enum.FillDirection.Vertical;
buttonsLayout.Padding = UDim.new(0, 4);
buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
buttonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center;
buttonsLayout.Parent = buttonsHolder;
local buttons = {};
local function setupHold(button, fn)
	local holding = false;
	local repeatDelay = 0.4;
	local repeatStep = 0.08;
	button.MouseButton1Down:Connect(function()
		holding = true;
		fn(button);
		task.spawn(function()
			task.wait(repeatDelay);
			while holding do
				fn(button);
				task.wait(repeatStep);
			end;
		end);
	end);
	button.MouseButton1Up:Connect(function()
		holding = false;
	end);
	button.MouseLeave:Connect(function()
		holding = false;
	end);
end;
for _, sp in ipairs(specs) do
	local label = sp[1];
	local b = Instance.new("TextButton");
	b.Size = UDim2.new(0, 40, 0, 24);
	b.Text = label;
	b.Visible = false;
	styleButton(b);
	b.Parent = buttonsHolder;
	if label == "+" or label == "–" or label == "R+" or label == "R-" then
		setupHold(b, sp[2]);
	else
		b.MouseButton1Click:Connect(function()
			sp[2](b);
		end);
	end;
	table.insert(buttons, b);
end;
local buttonsVisible = false;
local function setButtonsVisible(state)
	if buttonsVisible == state then
		return;
	end;
	buttonsVisible = state;
	for _, b in ipairs(buttons) do
		if state then
			b.Visible = true;
			b.TextTransparency = 1;
			b.BackgroundTransparency = 1;
			(TweenService:Create(b, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 0,
				BackgroundTransparency = 0
			})):Play();
		else
			local t = TweenService:Create(b, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				TextTransparency = 1,
				BackgroundTransparency = 1
			});
			t.Completed:Connect(function()
				if not buttonsVisible then
					b.Visible = false;
				end;
			end);
			t:Play();
		end;
	end;
end;
menuBtn.MouseButton1Click:Connect(function()
	setButtonsVisible(not buttonsVisible);
end);
do
	local dragging = false;
	local inputRef;
	local startPos;
	local startUDim;
	dragBtn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true;
			inputRef = i;
			startPos = i.Position;
			startUDim = container.Position;
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					dragging = false;
				end;
			end);
		end;
	end);
	dragBtn.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			inputRef = i;
		end;
	end);
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i == inputRef then
			local parent = container.Parent;
			if not parent then
				return;
			end;
			local parentSize = parent.AbsoluteSize;
			local delta = i.Position - startPos;
			local newX = startUDim.X.Scale + delta.X / parentSize.X;
			local newY = startUDim.Y.Scale + delta.Y / parentSize.Y;
			container.Position = UDim2.new(newX, startUDim.X.Offset, newY, startUDim.Y.Offset);
		end;
	end);
end;
viewport.InputBegan:Connect(function(input)
	if not teleportMode then
		return;
	end;
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return;
	end;
	local root = getRoot();
	if not root then
		return;
	end;
	local absPos = viewport.AbsolutePosition;
	local absSize = viewport.AbsoluteSize;
	local mx, my = input.Position.X, input.Position.Y;
	if mx < absPos.X or mx > absPos.X + absSize.X or my < absPos.Y or my > absPos.Y + absSize.Y then
		return;
	end;
	local u = (mx - absPos.X) / absSize.X;
	local v = (my - absPos.Y) / absSize.Y;
	local nx = (u - 0.5) * 2;
	local ny = (-(v - 0.5)) * 2;
	local f = math.tan(math.rad(camera.FieldOfView / 2));
	local dirCam = (Vector3.new(nx * f, ny * f, -1)).Unit;
	local origin = camera.CFrame.Position;
	local dirWorld = camera.CFrame:VectorToWorldSpace(dirCam);
	if math.abs(dirWorld.Y) < 0.0001 then
		return;
	end;
	local rootPos = root.Position;
	local planeY = rootPos.Y;
	local t = (planeY - origin.Y) / dirWorld.Y;
	if t <= 0 then
		return;
	end;
	local target = origin + dirWorld * t;
	local dx = target.X - rootPos.X;
	local dz = target.Z - rootPos.Z;
	local dist = math.sqrt(dx * dx + dz * dz);
	if dist > radius then
		local s = radius / dist;
		target = Vector3.new(rootPos.X + dx * s, planeY, rootPos.Z + dz * s);
	end;
	local charRoot = getRoot();
	if charRoot then
		charRoot.CFrame = CFrame.new(target + Vector3.new(0, headOff, 0));
	end;
end);
RunService.RenderStepped:Connect(function(dt)
	elapsed = elapsed + dt;
	if elapsed >= CLONE_RATE then
		refreshClones();
		elapsed = 0;
	end;
	local root = getRoot();
	local currentCam = Workspace.CurrentCamera;
	if not root or (not currentCam) then
		return;
	end;
	local rootPos = root.Position;
	marker.CFrame = CFrame.new(rootPos + Vector3.new(0, 1, 0));
	local bboxCFrame = cloneRoot:GetBoundingBox();
	lightPart.CFrame = bboxCFrame;
	local focus = rootPos + Vector3.new(0, headOff, 0);
	if overhead then
		local look = currentCam.CFrame.LookVector;
		look = Vector3.new(look.X, 0, look.Z);
		if look.Magnitude < 0.001 then
			look = Vector3.new(0, 0, -1);
		else
			look = look.Unit;
		end;
		local camPos = focus + Vector3.new(0, zoomHeight, 0);
		camera.CFrame = CFrame.lookAt(camPos, focus + look);
	else
		local dir = currentCam.CFrame.LookVector;
		dir = Vector3.new(dir.X, 0, dir.Z);
		if dir.Magnitude < 0.001 then
			dir = Vector3.new(0, 0, -1);
		else
			dir = dir.Unit;
		end;
		local desired = focus - dir * zoomDist + Vector3.new(0, zoomHeight, 0);
		local camPos = desired;
		if rayEnabled then
			local result = Workspace:Raycast(focus, desired - focus, rayParams);
			if result then
				camPos = result.Position + result.Normal * 0.5;
			end;
		end;
		camera.CFrame = CFrame.lookAt(camPos, focus);
	end;
end);
