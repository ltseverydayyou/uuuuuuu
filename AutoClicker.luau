cloneref = cloneref or function(legshot)
	return legshot;
end;
local Players = cloneref(game:GetService("Players"));
local RunService = cloneref(game:GetService("RunService"));
local UserInputService = cloneref(game:GetService("UserInputService"));
local VirtualInputManager = cloneref(game:GetService("VirtualInputManager"));
local TweenService = cloneref(game:GetService("TweenService"));
local LocalPlayer = Players.LocalPlayer;
local CoreGui = game:GetService("CoreGui");
local parentUI = gethui and gethui() or CoreGui or LocalPlayer:WaitForChild("PlayerGui");
local ui = Instance.new("ScreenGui");
ui.IgnoreGuiInset = true;
ui.ResetOnSpawn = false;
ui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
ui.Parent = parentUI;
local root = Instance.new("Frame");
root.Size = UDim2.new(0.22, 0, 0.3, 0);
root.Position = UDim2.new(0.06, 0, 0.12, 0);
root.BackgroundColor3 = Color3.fromRGB(24, 25, 28);
root.Active = true;
root.Parent = ui;
local rootCorner = Instance.new("UICorner", root);
rootCorner.CornerRadius = UDim.new(0, 12);
local rootGrad = Instance.new("UIGradient", root);
rootGrad.Color = ColorSequence.new(Color3.fromRGB(30, 31, 36), Color3.fromRGB(20, 20, 24));
local header = Instance.new("Frame");
header.Size = UDim2.new(1, 0, 0.14, 0);
header.BackgroundColor3 = Color3.fromRGB(28, 29, 34);
header.ZIndex = 50;
header.Active = true;
header.Parent = root;
local headerCorner = Instance.new("UICorner", header);
headerCorner.CornerRadius = UDim.new(0, 12);
local title = Instance.new("TextLabel");
title.BackgroundTransparency = 1;
title.Size = UDim2.new(0.6, 0, 1, 0);
title.Position = UDim2.new(0.04, 0, 0, 0);
title.Text = "Auto Clicker";
title.TextColor3 = Color3.fromRGB(235, 235, 240);
title.Font = Enum.Font.GothamBold;
title.TextScaled = true;
title.ZIndex = 51;
title.Parent = header;
local titleMax = Instance.new("UITextSizeConstraint", title);
titleMax.MaxTextSize = 20;
local right = Instance.new("Frame");
right.BackgroundTransparency = 1;
right.AnchorPoint = Vector2.new(1, 0);
right.Position = UDim2.new(0.985, 0, 0, 0);
right.Size = UDim2.new(0.34, 0, 1, 0);
right.ZIndex = 51;
right.Parent = header;
local rightLayout = Instance.new("UIListLayout", right);
rightLayout.FillDirection = Enum.FillDirection.Horizontal;
rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right;
rightLayout.VerticalAlignment = Enum.VerticalAlignment.Center;
rightLayout.Padding = UDim.new(0.03, 0);
local btnMin = Instance.new("TextButton");
btnMin.Size = UDim2.new(0.28, 0, 0.68, 0);
btnMin.BackgroundColor3 = Color3.fromRGB(40, 40, 46);
btnMin.Text = "-";
btnMin.Font = Enum.Font.GothamBold;
btnMin.TextScaled = true;
btnMin.TextColor3 = Color3.fromRGB(220, 220, 225);
btnMin.AutoButtonColor = true;
btnMin.ZIndex = 52;
btnMin.Parent = right;
local btnMinCorner = Instance.new("UICorner", btnMin);
btnMinCorner.CornerRadius = UDim.new(0, 8);
local btnMinMax = Instance.new("UITextSizeConstraint", btnMin);
btnMinMax.MaxTextSize = 18;
local btnClose = Instance.new("TextButton");
btnClose.Size = UDim2.new(0.28, 0, 0.68, 0);
btnClose.BackgroundColor3 = Color3.fromRGB(58, 30, 34);
btnClose.Text = "X";
btnClose.Font = Enum.Font.GothamBold;
btnClose.TextScaled = true;
btnClose.TextColor3 = Color3.fromRGB(255, 180, 185);
btnClose.AutoButtonColor = true;
btnClose.ZIndex = 52;
btnClose.Parent = right;
local btnCloseCorner = Instance.new("UICorner", btnClose);
btnCloseCorner.CornerRadius = UDim.new(0, 8);
local btnCloseMax = Instance.new("UITextSizeConstraint", btnClose);
btnCloseMax.MaxTextSize = 18;
local content = Instance.new("Frame");
content.BackgroundTransparency = 1;
content.Size = UDim2.new(1, 0, 0.86, 0);
content.Position = UDim2.new(0, 0, 0.14, 0);
content.ZIndex = 10;
content.Parent = root;
local pad = Instance.new("UIPadding", content);
pad.PaddingTop = UDim.new(0.06, 0);
pad.PaddingBottom = UDim.new(0.06, 0);
pad.PaddingLeft = UDim.new(0.06, 0);
pad.PaddingRight = UDim.new(0.06, 0);
local vlist = Instance.new("UIListLayout", content);
vlist.FillDirection = Enum.FillDirection.Vertical;
vlist.Padding = UDim.new(0.04, 0);
vlist.SortOrder = Enum.SortOrder.LayoutOrder;
vlist.HorizontalAlignment = Enum.HorizontalAlignment.Center;
local function card(p, h)
	local f = Instance.new("Frame");
	f.BackgroundColor3 = Color3.fromRGB(33, 34, 38);
	f.Size = UDim2.new(1, 0, h or 0.24, 0);
	f.ZIndex = 11;
	f.Parent = p;
	local c = Instance.new("UICorner", f);
	c.CornerRadius = UDim.new(0, 10);
	local g = Instance.new("UIGradient", f);
	g.Color = ColorSequence.new(Color3.fromRGB(38, 39, 44), Color3.fromRGB(30, 31, 36));
	return f;
end;
local keyCard = card(content);
local keyTitle = Instance.new("TextLabel", keyCard);
keyTitle.BackgroundTransparency = 1;
keyTitle.Size = UDim2.new(0.9, 0, 0.45, 0);
keyTitle.Position = UDim2.new(0.05, 0, 0.06, 0);
keyTitle.Text = "Toggle Key";
keyTitle.TextColor3 = Color3.fromRGB(210, 210, 220);
keyTitle.Font = Enum.Font.Gotham;
keyTitle.TextScaled = true;
keyTitle.ZIndex = 12;
local keyTitleMax = Instance.new("UITextSizeConstraint", keyTitle);
keyTitleMax.MaxTextSize = 18;
local keyButton = Instance.new("TextButton", keyCard);
keyButton.Size = UDim2.new(0.9, 0, 0.35, 0);
keyButton.Position = UDim2.new(0.05, 0, 0.58, 0);
keyButton.BackgroundColor3 = Color3.fromRGB(48, 49, 56);
keyButton.Text = "";
keyButton.TextColor3 = Color3.fromRGB(240, 240, 240);
keyButton.Font = Enum.Font.Gotham;
keyButton.TextScaled = true;
keyButton.ZIndex = 12;
local keyCorner = Instance.new("UICorner", keyButton);
keyCorner.CornerRadius = UDim.new(0, 8);
local keyLabel = Instance.new("TextLabel", keyButton);
keyLabel.BackgroundTransparency = 1;
keyLabel.Size = UDim2.new(1, 0, 1, 0);
keyLabel.Text = "";
keyLabel.TextColor3 = Color3.fromRGB(235, 235, 240);
keyLabel.Font = Enum.Font.GothamMedium;
keyLabel.TextScaled = true;
keyLabel.ZIndex = 13;
local keyLabelMax = Instance.new("UITextSizeConstraint", keyLabel);
keyLabelMax.MaxTextSize = 16;
local delayCard = card(content);
local delayTitle = Instance.new("TextLabel", delayCard);
delayTitle.BackgroundTransparency = 1;
delayTitle.Size = UDim2.new(0.9, 0, 0.45, 0);
delayTitle.Position = UDim2.new(0.05, 0, 0.06, 0);
delayTitle.Text = "Start After (seconds)";
delayTitle.TextColor3 = Color3.fromRGB(210, 210, 220);
delayTitle.Font = Enum.Font.Gotham;
delayTitle.TextScaled = true;
delayTitle.ZIndex = 12;
local delayTitleMax = Instance.new("UITextSizeConstraint", delayTitle);
delayTitleMax.MaxTextSize = 18;
local delayBox = Instance.new("TextBox", delayCard);
delayBox.Size = UDim2.new(0.9, 0, 0.35, 0);
delayBox.Position = UDim2.new(0.05, 0, 0.58, 0);
delayBox.BackgroundColor3 = Color3.fromRGB(48, 49, 56);
delayBox.Text = "";
delayBox.PlaceholderText = "0";
delayBox.PlaceholderColor3 = Color3.fromRGB(160, 160, 170);
delayBox.TextColor3 = Color3.fromRGB(240, 240, 240);
delayBox.ClearTextOnFocus = false;
delayBox.Font = Enum.Font.Gotham;
delayBox.TextScaled = true;
delayBox.ZIndex = 12;
local delayCorner = Instance.new("UICorner", delayBox);
delayCorner.CornerRadius = UDim.new(0, 8);
local delayMax = Instance.new("UITextSizeConstraint", delayBox);
delayMax.MaxTextSize = 16;
local intervalCard = card(content);
local intervalTitle = Instance.new("TextLabel", intervalCard);
intervalTitle.BackgroundTransparency = 1;
intervalTitle.Size = UDim2.new(0.9, 0, 0.45, 0);
intervalTitle.Position = UDim2.new(0.05, 0, 0.06, 0);
intervalTitle.Text = "Click Delay (seconds)";
intervalTitle.TextColor3 = Color3.fromRGB(210, 210, 220);
intervalTitle.Font = Enum.Font.Gotham;
intervalTitle.TextScaled = true;
intervalTitle.ZIndex = 12;
local intervalTitleMax = Instance.new("UITextSizeConstraint", intervalTitle);
intervalTitleMax.MaxTextSize = 18;
local intervalBox = Instance.new("TextBox", intervalCard);
intervalBox.Size = UDim2.new(0.9, 0, 0.35, 0);
intervalBox.Position = UDim2.new(0.05, 0, 0.58, 0);
intervalBox.BackgroundColor3 = Color3.fromRGB(48, 49, 56);
intervalBox.Text = "";
intervalBox.PlaceholderText = "0  (0 = fastest)";
intervalBox.PlaceholderColor3 = Color3.fromRGB(160, 160, 170);
intervalBox.TextColor3 = Color3.fromRGB(240, 240, 240);
intervalBox.ClearTextOnFocus = false;
intervalBox.Font = Enum.Font.Gotham;
intervalBox.TextScaled = true;
intervalBox.ZIndex = 12;
local intervalCorner = Instance.new("UICorner", intervalBox);
intervalCorner.CornerRadius = UDim.new(0, 8);
local intervalMax = Instance.new("UITextSizeConstraint", intervalBox);
intervalMax.MaxTextSize = 16;
local statusCard = card(content, 0.2);
statusCard.LayoutOrder = 99;
local statusTitle = Instance.new("TextLabel", statusCard);
statusTitle.BackgroundTransparency = 1;
statusTitle.Size = UDim2.new(0.9, 0, 0.5, 0);
statusTitle.Position = UDim2.new(0.05, 0, 0.05, 0);
statusTitle.Text = "Status";
statusTitle.TextColor3 = Color3.fromRGB(210, 210, 220);
statusTitle.Font = Enum.Font.Gotham;
statusTitle.TextScaled = true;
statusTitle.ZIndex = 12;
local statusTitleMax = Instance.new("UITextSizeConstraint", statusTitle);
statusTitleMax.MaxTextSize = 18;
local statusLabel = Instance.new("TextLabel", statusCard);
statusLabel.BackgroundTransparency = 1;
statusLabel.Size = UDim2.new(0.9, 0, 0.4, 0);
statusLabel.Position = UDim2.new(0.05, 0, 0.55, 0);
statusLabel.Text = "Idle";
statusLabel.TextColor3 = Color3.fromRGB(220, 235, 220);
statusLabel.Font = Enum.Font.GothamMedium;
statusLabel.TextScaled = true;
statusLabel.ZIndex = 12;
local statusLabelMax = Instance.new("UITextSizeConstraint", statusLabel);
statusLabelMax.MaxTextSize = 18;
local controls = Instance.new("Frame", content);
controls.BackgroundTransparency = 1;
controls.Size = UDim2.new(1, 0, 0.16, 0);
controls.ZIndex = 12;
local controlsLayout = Instance.new("UIListLayout", controls);
controlsLayout.FillDirection = Enum.FillDirection.Horizontal;
controlsLayout.Padding = UDim.new(0.04, 0);
controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center;
local startBtn = Instance.new("TextButton", controls);
startBtn.Size = UDim2.new(0.46, 0, 1, 0);
startBtn.BackgroundColor3 = Color3.fromRGB(42, 90, 60);
startBtn.Text = "Start";
startBtn.Font = Enum.Font.GothamBold;
startBtn.TextScaled = true;
startBtn.TextColor3 = Color3.fromRGB(220, 255, 230);
startBtn.ZIndex = 13;
local startCorner = Instance.new("UICorner", startBtn);
startCorner.CornerRadius = UDim.new(0, 8);
local startMax = Instance.new("UITextSizeConstraint", startBtn);
startMax.MaxTextSize = 18;
local stopBtn = Instance.new("TextButton", controls);
stopBtn.Size = UDim2.new(0.46, 0, 1, 0);
stopBtn.BackgroundColor3 = Color3.fromRGB(90, 42, 52);
stopBtn.Text = "Stop";
stopBtn.Font = Enum.Font.GothamBold;
stopBtn.TextScaled = true;
stopBtn.TextColor3 = Color3.fromRGB(255, 230, 235);
stopBtn.ZIndex = 13;
local stopCorner = Instance.new("UICorner", stopBtn);
stopCorner.CornerRadius = UDim.new(0, 8);
local stopMax = Instance.new("UITextSizeConstraint", stopBtn);
stopMax.MaxTextSize = 18;
local dockBar = Instance.new("Frame");
dockBar.Size = UDim2.new(0, 0, 0, 0);
dockBar.Position = UDim2.new(0.5, 0, 0, 0);
dockBar.AnchorPoint = Vector2.new(0.5, 0);
dockBar.BackgroundColor3 = Color3.fromRGB(28, 29, 34);
dockBar.Visible = false;
dockBar.Parent = ui;
local dockCorner = Instance.new("UICorner", dockBar);
dockCorner.CornerRadius = UDim.new(0, 10);
local dockTitle = Instance.new("TextLabel", dockBar);
dockTitle.BackgroundTransparency = 1;
dockTitle.Text = "Auto Clicker";
dockTitle.Font = Enum.Font.GothamSemibold;
dockTitle.TextScaled = true;
dockTitle.TextColor3 = Color3.fromRGB(235, 235, 240);
dockTitle.Size = UDim2.new(0.38, 0, 1, 0);
dockTitle.Position = UDim2.new(0.04, 0, 0, 0);
local dockTitleMax = Instance.new("UITextSizeConstraint", dockTitle);
dockTitleMax.MaxTextSize = 16;
local dockStatus = Instance.new("TextLabel", dockBar);
dockStatus.BackgroundTransparency = 1;
dockStatus.Text = "OFF [P]";
dockStatus.Font = Enum.Font.GothamMedium;
dockStatus.TextScaled = true;
dockStatus.TextColor3 = Color3.fromRGB(200, 200, 210);
dockStatus.Size = UDim2.new(0.28, 0, 1, 0);
dockStatus.Position = UDim2.new(0.46, 0, 0, 0);
local dockStatusMax = Instance.new("UITextSizeConstraint", dockStatus);
dockStatusMax.MaxTextSize = 14;
local dockBtns = Instance.new("Frame", dockBar);
dockBtns.BackgroundTransparency = 1;
dockBtns.AnchorPoint = Vector2.new(1, 0);
dockBtns.Position = UDim2.new(0.96, 0, 0, 0);
dockBtns.Size = UDim2.new(0.26, 0, 1, 0);
local dockLayout = Instance.new("UIListLayout", dockBtns);
dockLayout.FillDirection = Enum.FillDirection.Horizontal;
dockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right;
dockLayout.VerticalAlignment = Enum.VerticalAlignment.Center;
dockLayout.Padding = UDim.new(0.04, 0);
local dockRestore = Instance.new("TextButton", dockBtns);
dockRestore.Size = UDim2.new(0.48, 0, 0.75, 0);
dockRestore.BackgroundColor3 = Color3.fromRGB(40, 40, 46);
dockRestore.Text = "Open";
dockRestore.Font = Enum.Font.GothamBold;
dockRestore.TextScaled = true;
dockRestore.TextColor3 = Color3.fromRGB(230, 230, 235);
local dockRestoreCorner = Instance.new("UICorner", dockRestore);
dockRestoreCorner.CornerRadius = UDim.new(0, 8);
local dockRestoreMax = Instance.new("UITextSizeConstraint", dockRestore);
dockRestoreMax.MaxTextSize = 14;
local dockClose = Instance.new("TextButton", dockBtns);
dockClose.Size = UDim2.new(0.48, 0, 0.75, 0);
dockClose.BackgroundColor3 = Color3.fromRGB(58, 30, 34);
dockClose.Text = "Close";
dockClose.Font = Enum.Font.GothamBold;
dockClose.TextScaled = true;
dockClose.TextColor3 = Color3.fromRGB(255, 180, 185);
local dockCloseCorner = Instance.new("UICorner", dockClose);
dockCloseCorner.CornerRadius = UDim.new(0, 8);
local dockCloseMax = Instance.new("UITextSizeConstraint", dockClose);
dockCloseMax.MaxTextSize = 14;
local toggleKey = Enum.KeyCode.P;
local listening = false;
local clicking = false;
local pending = false;
local startDeadline = 0;
local startDelay = 0;
local clickInterval = 0;
local nextClickTime = 0;
local minimized = false;
local storedPos = root.Position;
local storedSize = root.Size;
local clickConn = nil;
local Burst = 8;
local function refreshKeyLabel()
	keyLabel.Text = "[" .. toggleKey.Name .. "]";
end;
local function updateDockStatus()
	local state = clicking and "ON" or (pending and "ARMED" or "OFF");
	dockStatus.Text = state .. " [" .. toggleKey.Name .. "]";
end;
local function pointInGui(obj, px, py)
	if not obj.Visible then
		return false;
	end;
	local p = obj.AbsolutePosition;
	local s = obj.AbsoluteSize;
	return px >= p.X and px <= p.X + s.X and py >= p.Y and py <= p.Y + s.Y;
end;
local function overOwnUI()
	local pos = UserInputService:GetMouseLocation();
	for _, o in ipairs(ui:GetDescendants()) do
		if o:IsA("GuiObject") and pointInGui(o, pos.X, pos.Y) then
			return true;
		end;
	end;
	return false;
end;
local function doClick()
	local pos = UserInputService:GetMouseLocation();
	if VirtualInputManager and VirtualInputManager.SendMouseButtonEvent then
		VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0);
		VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0);
	elseif mouse1click then
		mouse1click();
	end;
end;
local function startFastLoop()
	if clickConn then
		clickConn:Disconnect();
		clickConn = nil;
	end;
	clickConn = RunService.Heartbeat:Connect(function()
		if pending then
			local remain = math.max(0, startDeadline - os.clock());
			if remain > 0 then
				statusLabel.Text = "Starting in " .. string.format("%.1f", remain) .. "s";
				updateDockStatus();
				return;
			else
				pending = false;
				clicking = true;
				nextClickTime = os.clock();
				statusLabel.Text = "Active";
				updateDockStatus();
			end;
		end;
		if not clicking then
			return;
		end;
		if overOwnUI() then
			return;
		end;
		if clickInterval <= 0 then
			for i = 1, Burst do
				doClick();
			end;
		else
			local now = os.clock();
			while now >= nextClickTime do
				doClick();
				nextClickTime = nextClickTime + clickInterval;
				now = os.clock();
			end;
		end;
	end);
end;
local conns = {};
local function bind(sig, fn)
	local c = sig:Connect(fn);
	table.insert(conns, c);
	return c;
end;
refreshKeyLabel();
updateDockStatus();
statusLabel.Text = "Idle";
delayBox.Text = "";
delayBox.PlaceholderText = "0";
intervalBox.Text = "";
intervalBox.PlaceholderText = "0  (0 = fastest)";
bind(keyButton.MouseButton1Click, function()
	listening = true;
	keyLabel.Text = "[Press a key]";
end);
bind(delayBox.FocusLost, function()
	local v = tonumber(delayBox.Text);
	if v and v >= 0 then
		startDelay = v;
	end;
	delayBox.Text = "";
	delayBox.PlaceholderText = tostring(startDelay);
end);
bind(intervalBox.FocusLost, function()
	local v = tonumber(intervalBox.Text);
	if v and v >= 0 then
		clickInterval = v;
	end;
	intervalBox.Text = "";
	intervalBox.PlaceholderText = clickInterval == 0 and "0  (0 = fastest)" or tostring(clickInterval);
end);
bind(startBtn.MouseButton1Click, function()
	if clicking or pending then
		return;
	end;
	startDeadline = os.clock() + startDelay;
	pending = true;
	if not clickConn then
		startFastLoop();
	end;
	if startDelay <= 0 then
		pending = false;
		clicking = true;
		nextClickTime = os.clock();
		statusLabel.Text = "Active";
	else
		statusLabel.Text = "Starting in " .. string.format("%.1f", startDelay) .. "s";
	end;
	updateDockStatus();
end);
bind(stopBtn.MouseButton1Click, function()
	clicking = false;
	pending = false;
	nextClickTime = math.huge;
	statusLabel.Text = "Idle";
	updateDockStatus();
end);
bind(UserInputService.InputBegan, function(input, processed)
	if listening and input.UserInputType == Enum.UserInputType.Keyboard then
		toggleKey = input.KeyCode;
		listening = false;
		refreshKeyLabel();
		updateDockStatus();
		return;
	end;
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == toggleKey and (not processed) then
		if not clicking and (not pending) then
			startDeadline = os.clock() + startDelay;
			pending = true;
			if not clickConn then
				startFastLoop();
			end;
			if startDelay <= 0 then
				pending = false;
				clicking = true;
				nextClickTime = os.clock();
				statusLabel.Text = "Active";
			else
				statusLabel.Text = "Starting in " .. string.format("%.1f", startDelay) .. "s";
			end;
		else
			clicking = false;
			pending = false;
			nextClickTime = math.huge;
			statusLabel.Text = "Idle";
		end;
		updateDockStatus();
	end;
end);
local dragging = false;
local baseScale = nil;
local startMouse = nil;
local function beginDrag()
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080);
	dragging = true;
	baseScale = Vector2.new(root.Position.X.Scale, root.Position.Y.Scale);
	startMouse = UserInputService:GetMouseLocation();
	root.Position = UDim2.new(baseScale.X, 0, baseScale.Y, 0);
end;
local function endDrag()
	dragging = false;
end;
bind(header.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginDrag();
	end;
end);
bind(title.InputBegan, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		beginDrag();
	end;
end);
bind(UserInputService.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		endDrag();
	end;
end);
bind(UserInputService.InputChanged, function(input)
	if not dragging then
		return;
	end;
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080);
		local pos = UserInputService:GetMouseLocation();
		local dx = (pos.X - startMouse.X) / math.max(1, vp.X);
		local dy = (pos.Y - startMouse.Y) / math.max(1, vp.Y);
		root.Position = UDim2.new(baseScale.X + dx, 0, baseScale.Y + dy, 0);
	end;
end);
local function showDock()
	dockBar.Visible = true;
	dockBar.Size = UDim2.new(0, 0, 0, 0);
	dockTitle.Visible = false;
	dockStatus.Visible = false;
	dockBtns.Visible = false;
	dockBar.Position = UDim2.new(0.5, 0, 0, 0);
	(TweenService:Create(dockBar, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.26, 0, 0.045, 0)
	})):Play();
	task.delay(0.18, function()
		dockTitle.Visible = true;
		dockStatus.Visible = true;
		dockBtns.Visible = true;
	end);
end;
local function hideDock()
	dockTitle.Visible = false;
	dockStatus.Visible = false;
	dockBtns.Visible = false;
	(TweenService:Create(dockBar, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 0, 0, 0)
	})):Play();
	task.delay(0.16, function()
		dockBar.Visible = false;
	end);
end;
bind(btnMin.MouseButton1Click, function()
	if not minimized then
		minimized = true;
		storedPos = root.Position;
		storedSize = root.Size;
		root.Visible = false;
		showDock();
	else
		minimized = false;
		hideDock();
		root.Visible = true;
		root.Position = storedPos;
		root.Size = storedSize;
	end;
end);
bind(dockRestore.MouseButton1Click, function()
	if minimized then
		minimized = false;
		hideDock();
		root.Visible = true;
		root.Position = storedPos;
		root.Size = storedSize;
	end;
end);
local function cleanup()
	clicking = false;
	pending = false;
	nextClickTime = math.huge;
	updateDockStatus();
	if clickConn then
		clickConn:Disconnect();
		clickConn = nil;
	end;
	for _, c in ipairs(conns) do
		pcall(function()
			c:Disconnect();
		end);
	end;
	conns = {};
	ui:Destroy();
end;
bind(dockClose.MouseButton1Click, cleanup);
bind(btnClose.MouseButton1Click, cleanup);
refreshKeyLabel();
updateDockStatus();
