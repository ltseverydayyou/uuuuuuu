local function ClonedService(name)
	local Service = game.GetService;
	local Reference = cloneref or function(reference)
		return reference;
	end;
	return Reference(Service(game, name));
end;
local TweenService = ClonedService("TweenService");
local RunService = ClonedService("RunService");
local player = (ClonedService("Players")).LocalPlayer;
local gui = Instance.new("ScreenGui");
local signals = {};
local function bind(conn)
	table.insert(signals, conn);
	return conn;
end;
local function NAdragSmooth(ui, dragui)
	if not dragui then
		dragui = ui;
	end;
	local UserInputService = ClonedService("UserInputService");
	local dragging, dragInput, dragStart, startPos, dragTween;
	local function smoothTo(pos)
		if dragTween then
			dragTween:Cancel();
		end;
		dragTween = TweenService:Create(ui, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = pos
		});
		dragTween:Play();
	end;
	local function toScale(pos, start, startUDim)
		local screenSize = ui.Parent.AbsoluteSize;
		local d = pos - start;
		local nx = startUDim.X.Scale + (startUDim.X.Offset + d.X) / screenSize.X;
		local ny = startUDim.Y.Scale + (startUDim.Y.Offset + d.Y) / screenSize.Y;
		return UDim2.new(nx, 0, ny, 0);
	end;
	bind(dragui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true;
			dragStart = input.Position;
			startPos = ui.Position;
			bind(input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false;
				end;
			end));
		end;
	end));
	bind(dragui.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input;
		end;
	end));
	bind(UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			smoothTo(toScale(input.Position, dragStart, startPos));
		end;
	end));
	ui.Active = true;
end;
local function protectUI(sGui)
	if sGui:IsA("ScreenGui") then
		sGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
		sGui.DisplayOrder = 999999999;
		sGui.ResetOnSpawn = false;
		sGui.IgnoreGuiInset = true;
	end;
	local cGUI = ClonedService("CoreGui");
	local lPlr = (ClonedService("Players")).LocalPlayer;
	local function NAProtection(inst, var)
		if inst then
			if var then
				inst[var] = "\000";
				inst.Archivable = false;
			else
				inst.Name = "\000";
				inst.Archivable = false;
			end;
		end;
	end;
	if gethui then
		NAProtection(sGui);
		sGui.Parent = gethui();
		return sGui;
	elseif cGUI and cGUI:FindFirstChild("RobloxGui") then
		NAProtection(sGui);
		sGui.Parent = cGUI:FindFirstChild("RobloxGui");
		return sGui;
	elseif cGUI then
		NAProtection(sGui);
		sGui.Parent = cGUI;
		return sGui;
	elseif lPlr and lPlr:FindFirstChildWhichIsA("PlayerGui") then
		NAProtection(sGui);
		sGui.Parent = lPlr:FindFirstChildWhichIsA("PlayerGui");
		sGui.ResetOnSpawn = false;
		return sGui;
	else
		return nil;
	end;
end;
protectUI(gui);
local root = Instance.new("Frame");
root.Name = "Panel";
root.Parent = gui;
root.Size = UDim2.fromOffset(56, 56);
root.Position = UDim2.new(0.5, 0, 0.12, 0);
root.AnchorPoint = Vector2.new(0.5, 0);
root.BackgroundColor3 = Color3.fromRGB(24, 24, 27);
root.BackgroundTransparency = 0.05;
root.ClipsDescendants = true;
local rootCorner = Instance.new("UICorner");
rootCorner.CornerRadius = UDim.new(1, 0);
rootCorner.Parent = root;
local strokes = {};
local function newStroke(parent, thickness)
	local s = Instance.new("UIStroke");
	s.Thickness = thickness or 1;
	s.Transparency = 0.35;
	s.Color = Color3.fromRGB(255, 255, 255);
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual;
	s.Parent = parent;
	table.insert(strokes, s);
	return s;
end;
local gradients = {};
local rootStroke = newStroke(root, 1);
local rootGrad = Instance.new("UIGradient");
rootGrad.Color = ColorSequence.new(Color3.fromRGB(32, 32, 36), Color3.fromRGB(18, 18, 20));
rootGrad.Rotation = 90;
rootGrad.Parent = root;
table.insert(gradients, rootGrad);
local launcherIcon = Instance.new("TextLabel");
launcherIcon.Parent = root;
launcherIcon.BackgroundTransparency = 1;
launcherIcon.Size = UDim2.fromScale(1, 1);
launcherIcon.Text = "●";
launcherIcon.TextScaled = true;
launcherIcon.Font = Enum.Font.GothamBold;
launcherIcon.TextColor3 = Color3.fromRGB(230, 230, 236);
local header = Instance.new("Frame");
header.Parent = root;
header.Size = UDim2.new(1, -16, 0, 48);
header.Position = UDim2.new(0, 8, 0, 8);
header.BackgroundColor3 = Color3.fromRGB(34, 34, 38);
header.BackgroundTransparency = 0.2;
header.Visible = false;
local headerCorner = Instance.new("UICorner");
headerCorner.CornerRadius = UDim.new(0, 10);
headerCorner.Parent = header;
local headerStroke = newStroke(header, 1);
local title = Instance.new("TextLabel");
title.Parent = header;
title.Size = UDim2.new(1, -120, 1, 0);
title.Position = UDim2.new(0, 8, 0, 0);
title.BackgroundTransparency = 1;
title.Text = "Utilities";
title.TextColor3 = Color3.fromRGB(235, 235, 240);
title.Font = Enum.Font.GothamBold;
title.TextXAlignment = Enum.TextXAlignment.Left;
title.TextSize = 18;
local titleScale = Instance.new("UIScale");
titleScale.Parent = title;
bind(title.MouseEnter:Connect(function()
	(TweenService:Create(titleScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Scale = 1.02
	})):Play();
end));
bind(title.MouseLeave:Connect(function()
	(TweenService:Create(titleScale, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Scale = 1
	})):Play();
end));
local sheen = Instance.new("UIGradient");
sheen.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255));
sheen.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.45, 1),
	NumberSequenceKeypoint.new(0.5, 0.8),
	NumberSequenceKeypoint.new(0.55, 1),
	NumberSequenceKeypoint.new(1, 1)
});
sheen.Rotation = 20;
sheen.Parent = header;
local controls = Instance.new("Frame");
controls.Parent = header;
controls.BackgroundTransparency = 1;
controls.Size = UDim2.fromOffset(110, 36);
controls.Position = UDim2.new(1, -110, 0.5, -18);
local uiListC = Instance.new("UIListLayout");
uiListC.Parent = controls;
uiListC.FillDirection = Enum.FillDirection.Horizontal;
uiListC.HorizontalAlignment = Enum.HorizontalAlignment.Right;
uiListC.Padding = UDim.new(0, 8);
local function headerBtn(txt)
	local b = Instance.new("TextButton");
	b.AutoButtonColor = false;
	b.Text = txt;
	b.Font = Enum.Font.GothamBold;
	b.TextSize = 16;
	b.TextColor3 = Color3.fromRGB(230, 230, 236);
	b.BackgroundColor3 = Color3.fromRGB(45, 45, 50);
	b.Size = UDim2.fromOffset(34, 34);
	b.Parent = controls;
	local c = Instance.new("UICorner", b);
	c.CornerRadius = UDim.new(1, 0);
	newStroke(b, 1);
	local s = Instance.new("UIScale", b);
	bind(b.MouseEnter:Connect(function()
		(TweenService:Create(s, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = 1.05
		})):Play();
	end));
	bind(b.MouseLeave:Connect(function()
		(TweenService:Create(s, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = 1
		})):Play();
	end));
	return b;
end;
local minimizeBtn = headerBtn("—");
local closeBtn = headerBtn("×");
local body = Instance.new("Frame");
body.Parent = root;
body.Size = UDim2.new(1, -16, 1, -68);
body.Position = UDim2.new(0, 8, 0, 60);
body.BackgroundTransparency = 1;
body.Visible = false;
local list = Instance.new("UIListLayout");
list.Parent = body;
list.Padding = UDim.new(0, 10);
list.HorizontalAlignment = Enum.HorizontalAlignment.Center;
list.SortOrder = Enum.SortOrder.LayoutOrder;
local function ripple(target)
	local r = Instance.new("Frame");
	r.Parent = target;
	r.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	r.BackgroundTransparency = 0.7;
	r.Size = UDim2.fromOffset(0, 0);
	r.Position = UDim2.fromScale(0.5, 0.5);
	r.AnchorPoint = Vector2.new(0.5, 0.5);
	r.ZIndex = target.ZIndex + 1;
	local rc = Instance.new("UICorner");
	rc.CornerRadius = UDim.new(1, 0);
	rc.Parent = r;
	(TweenService:Create(r, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(target.AbsoluteSize.X + 10, target.AbsoluteSize.Y + 10),
		BackgroundTransparency = 1
	})):Play();
	task.delay(0.42, function()
		r:Destroy();
	end);
end;
local function toggleRow(text)
	local row = Instance.new("Frame");
	row.Size = UDim2.new(1, 0, 0, 50);
	row.BackgroundColor3 = Color3.fromRGB(30, 30, 34);
	row.BackgroundTransparency = 0.15;
	row.LayoutOrder = (#body:GetChildren()) + 1;
	row.ClipsDescendants = true;
	local rowCorner = Instance.new("UICorner");
	rowCorner.CornerRadius = UDim.new(0, 10);
	rowCorner.Parent = row;
	local rowStroke = newStroke(row, 1);
	local rowScale = Instance.new("UIScale");
	rowScale.Parent = row;
	bind(row.MouseEnter:Connect(function()
		(TweenService:Create(rowScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = 1.02
		})):Play();
	end));
	bind(row.MouseLeave:Connect(function()
		(TweenService:Create(rowScale, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = 1
		})):Play();
	end));
	local label = Instance.new("TextLabel");
	label.Parent = row;
	label.BackgroundTransparency = 1;
	label.Size = UDim2.new(1, -100, 1, 0);
	label.Position = UDim2.new(0, 14, 0, 0);
	label.Text = text;
	label.TextColor3 = Color3.fromRGB(230, 230, 236);
	label.Font = Enum.Font.GothamMedium;
	label.TextSize = 16;
	label.TextXAlignment = Enum.TextXAlignment.Left;
	local track = Instance.new("TextButton");
	track.Parent = row;
	track.AutoButtonColor = false;
	track.BackgroundColor3 = Color3.fromRGB(45, 45, 50);
	track.Size = UDim2.fromOffset(64, 30);
	track.Position = UDim2.new(1, (-16) - 64, 0.5, -15);
	track.Text = "";
	track.ZIndex = 2;
	track.ClipsDescendants = true;
	local trackCorner = Instance.new("UICorner");
	trackCorner.CornerRadius = UDim.new(1, 0);
	trackCorner.Parent = track;
	local trackStroke = newStroke(track, 1);
	local trackGrad = Instance.new("UIGradient");
	trackGrad.Color = ColorSequence.new(Color3.fromRGB(52, 52, 58), Color3.fromRGB(38, 38, 44));
	trackGrad.Rotation = 90;
	trackGrad.Parent = track;
	table.insert(gradients, trackGrad);
	local knob = Instance.new("Frame");
	knob.Parent = track;
	knob.BackgroundColor3 = Color3.fromRGB(240, 240, 245);
	knob.Size = UDim2.fromOffset(26, 26);
	knob.Position = UDim2.new(0, 2, 0.5, -13);
	knob.ZIndex = 3;
	local knobCorner = Instance.new("UICorner");
	knobCorner.CornerRadius = UDim.new(1, 0);
	knobCorner.Parent = knob;
	local knobStroke = newStroke(knob, 1);
	local knobScale = Instance.new("UIScale");
	knobScale.Scale = 1;
	knobScale.Parent = knob;
	local state = false;
	local function setState(on)
		state = on;
		local ti = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		local destX = on and 64 - 26 - 2 or 2;
		local colorOnA = Color3.fromRGB(88, 170, 255);
		local colorOnB = Color3.fromRGB(134, 96, 255);
		local colorOffA = Color3.fromRGB(52, 52, 58);
		local colorOffB = Color3.fromRGB(38, 38, 44);
		(TweenService:Create(knob, ti, {
			Position = UDim2.new(0, destX, 0.5, -13)
		})):Play();
		(TweenService:Create(knobScale, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1.08
		})):Play();
		task.delay(0.12, function()
			(TweenService:Create(knobScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = 1
			})):Play();
		end);
		(TweenService:Create(track, ti, {
			BackgroundColor3 = on and Color3.fromRGB(55, 60, 75) or Color3.fromRGB(45, 45, 50)
		})):Play();
		trackGrad.Color = ColorSequence.new(on and colorOnA or colorOffA, on and colorOnB or colorOffB);
		trackStroke.Transparency = on and 0.15 or 0.35;
		ripple(track);
	end;
	bind(track.MouseButton1Click:Connect(function()
		setState(not state);
	end));
	row.Parent = body;
	return {
		row = row,
		set = setState,
		get = function()
			return state;
		end,
		button = track
	};
end;
local moneyFarmEnabled = false;
local monitorEnabled = false;
local shutterEnabled = false;
local alive = true;
local isOpen = false;
local openSize = Vector2.new(380, 230);
local miniSize = Vector2.new(56, 56);
local moneyRow = toggleRow("Money Farm");
local monitorRow = toggleRow("Monitor Farm");
local shutterRow = toggleRow("Janitor Body Farm");
bind(moneyRow.button.MouseButton1Click:Connect(function()
	moneyFarmEnabled = not moneyFarmEnabled;
end));
bind(monitorRow.button.MouseButton1Click:Connect(function()
	monitorEnabled = not monitorEnabled;
end));
bind(shutterRow.button.MouseButton1Click:Connect(function()
	shutterEnabled = not shutterEnabled;
end));
local function openUI()
	isOpen = true;
	launcherIcon.Visible = false;
	header.Visible = true;
	body.Visible = true;
	(TweenService:Create(rootCorner, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CornerRadius = UDim.new(0, 14)
	})):Play();
	(TweenService:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(openSize.X, openSize.Y)
	})):Play();
end;
local function minimizeUI()
	isOpen = false;
	header.Visible = false;
	body.Visible = false;
	(TweenService:Create(rootCorner, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CornerRadius = UDim.new(1, 0)
	})):Play();
	(TweenService:Create(root, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(miniSize.X, miniSize.Y)
	})):Play();
	task.delay(0.08, function()
		launcherIcon.Visible = true;
	end);
end;
bind(root.InputBegan:Connect(function(input)
	if not isOpen and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
		ripple(root);
		openUI();
	end;
end));
bind(minimizeBtn.MouseButton1Click:Connect(function()
	ripple(minimizeBtn);
	minimizeUI();
end));
local monitorCds = {};
local trashCds = {};
for _, m in ipairs(workspace:GetDescendants()) do
	if m.Name:lower() == "monitor" then
		local cd = m:FindFirstChildWhichIsA("ClickDetector", true);
		if cd then
			table.insert(monitorCds, cd);
		end;
	end;
end;
for _, t in ipairs(workspace:GetDescendants()) do
	if t.Name:lower() == "trashcan" then
		local cd = t:FindFirstChildWhichIsA("ClickDetector", true);
		if cd then
			table.insert(trashCds, cd);
		end;
	end;
end;
local t0 = os.clock();
local renderConn = bind(RunService.RenderStepped:Connect(function()
	local t = (os.clock() - t0) * 0.15;
	for i, s in ipairs(strokes) do
		local h = (t + i * 0.08) % 1;
		s.Color = Color3.fromHSV(h, 0.85, 1);
		s.Transparency = 0.22 + 0.12 * (0.5 + 0.5 * math.sin((t * 6 + i)));
		s.Thickness = 1 + 0.25 * (0.5 + 0.5 * math.sin((t * 5 + i * 0.6)));
	end;
	for i, g in ipairs(gradients) do
		g.Rotation = 90 + math.sin((t * 8 + i * 0.5)) * 20;
	end;
	sheen.Offset = Vector2.new(t * 0.9 % 2 - 1, 0);
end));
task.spawn(function()
	while alive do
		task.wait(0.1);
		if monitorEnabled then
			pcall(function()
				for _, cd in ipairs(monitorCds) do
					fireclickdetector(cd);
				end;
			end);
		end;
	end;
end);
task.spawn(function()
	while alive do
		task.wait(0.1);
		if moneyFarmEnabled then
			local p = (ClonedService("Players")).LocalPlayer;
			local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart");
			local mh = (ClonedService("Workspace")).Buildings.DeadBurger.DumpsterMoneyMaker:FindFirstChild("MoneyHitbox");
			if hrp and mh then
				local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut);
				local tween1 = TweenService:Create(mh, tweenInfo, {
					CFrame = hrp.CFrame
				});
				local tween2 = TweenService:Create(mh, tweenInfo, {
					CFrame = hrp.CFrame + Vector3.new(0, 20, 0)
				});
				tween1:Play();
				tween1.Completed:Wait();
				tween2:Play();
				tween2.Completed:Wait();
			end;
			local bp = p:FindFirstChild("Backpack");
			if bp then
				local tool = bp:FindFirstChild("Garbage Bag");
				if tool then
					p.Character.Humanoid:EquipTool(tool);
				end;
			end;
			for _, cd in ipairs(trashCds) do
				fireclickdetector(cd);
			end;
		end;
	end;
end);
task.spawn(function()
	while alive do
		task.wait(0.1);
		if shutterEnabled then
			pcall(function()
				local s = (ClonedService("Workspace")).Model.Shutter.Root:FindFirstChildWhichIsA("ClickDetector", true);
				if s then
					fireclickdetector(s);
				end;
			end);
		end;
	end;
end);
bind(closeBtn.MouseButton1Click:Connect(function()
	ripple(closeBtn);
	moneyFarmEnabled = false;
	monitorEnabled = false;
	shutterEnabled = false;
	alive = false;
	for _, c in ipairs(signals) do
		pcall(function()
			c:Disconnect();
		end);
	end;
	monitorCds = {};
	trashCds = {};
	(TweenService:Create(root, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(0, 0)
	})):Play();
	task.delay(0.2, function()
		gui:Destroy();
	end);
end));
NAdragSmooth(root, root);
NAdragSmooth(root, header);
