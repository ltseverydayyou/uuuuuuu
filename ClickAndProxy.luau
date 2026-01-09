local function GetServ(n)
	local s = game:GetService(n);
	return cloneref and cloneref(s) or s;
end;
local coreGui = GetServ("CoreGui");
local userInput = GetServ("UserInputService");
local runService = GetServ("RunService");
local players = GetServ("Players");
local localPlayer = players.LocalPlayer;
local clicksEnabled = false;
local promptsEnabled = false;
local distanceCheck = false;
local waitTime = 0;
local clickDetectors = {};
local proximityPrompts = {};
local selectedClickNames = {};
local selectedPromptNames = {};
local activeClickIdxList = {};
local activePromptIdxList = {};
local activeClickPtr = 1;
local activePromptPtr = 1;
local function onAdded(o)
	if o:IsA("ClickDetector") then
		clickDetectors[(#clickDetectors) + 1] = o;
	elseif o:IsA("ProximityPrompt") then
		proximityPrompts[(#proximityPrompts) + 1] = o;
	end;
end;
local function onRemoved(o)
	if o:IsA("ClickDetector") then
		for i, v in ipairs(clickDetectors) do
			if v == o then
				table.remove(clickDetectors, i);
				break;
			end;
		end;
	elseif o:IsA("ProximityPrompt") then
		for i, v in ipairs(proximityPrompts) do
			if v == o then
				table.remove(proximityPrompts, i);
				break;
			end;
		end;
	end;
end;
for _, o in ipairs(workspace:GetDescendants()) do
	onAdded(o);
end;
workspace.DescendantAdded:Connect(onAdded);
workspace.DescendantRemoving:Connect(onRemoved);
local function resolveHolder(inst)
	if not inst then
		return nil;
	end;
	local p = inst.Parent;
	if p and (p:IsA("Model") or p:IsA("BasePart")) then
		return p;
	end;
	local mdl = inst:FindFirstAncestorOfClass("Model");
	if mdl then
		return mdl;
	end;
	local bp = inst:FindFirstAncestorOfClass("BasePart");
	if bp then
		return bp;
	end;
	return p;
end;
local function resolveDistancePart(inst)
	local holder = resolveHolder(inst);
	if not holder then
		return nil;
	end;
	if holder:IsA("Model") then
		if holder.PrimaryPart then
			return holder.PrimaryPart;
		end;
		return holder:FindFirstChildWhichIsA("BasePart", true);
	else
		return holder;
	end;
end;
local function holderNameFor(inst)
	local h = resolveHolder(inst);
	return h and h.Name or "unknown";
end;
local function getHRP()
	local ch = localPlayer.Character or localPlayer.CharacterAdded:Wait();
	if not ch then
		return nil;
	end;
	return ch:FindFirstChild("HumanoidRootPart", true) or ch:FindFirstChild("UpperTorso", true) or ch:FindFirstChild("Torso", true) or ch:FindFirstChildWhichIsA("BasePart", true);
end;
local function withinRangeWith(hrpPos, obj, max)
	if not distanceCheck then
		return true;
	end;
	if not hrpPos then
		return true;
	end;
	local tp = resolveDistancePart(obj);
	if not tp or (not tp.Position) then
		return true;
	end;
	local lim = tonumber(max);
	if not lim or lim <= 0 then
		return true;
	end;
	return (hrpPos - tp.Position).Magnitude <= lim + 5;
end;
local function rebuildActiveSets()
	table.clear(activeClickIdxList);
	table.clear(activePromptIdxList);
	if next(selectedClickNames) == nil then
		for i, v in ipairs(clickDetectors) do
			if v and v.Parent then
				activeClickIdxList[(#activeClickIdxList) + 1] = i;
			end;
		end;
	else
		for i, v in ipairs(clickDetectors) do
			if v and v.Parent and selectedClickNames[holderNameFor(v)] then
				activeClickIdxList[(#activeClickIdxList) + 1] = i;
			end;
		end;
	end;
	if next(selectedPromptNames) == nil then
		for i, v in ipairs(proximityPrompts) do
			if v and v.Parent then
				activePromptIdxList[(#activePromptIdxList) + 1] = i;
			end;
		end;
	else
		for i, v in ipairs(proximityPrompts) do
			if v and v.Parent and selectedPromptNames[holderNameFor(v)] then
				activePromptIdxList[(#activePromptIdxList) + 1] = i;
			end;
		end;
	end;
	if activeClickPtr > (#activeClickIdxList) then
		activeClickPtr = 1;
	end;
	if activePromptPtr > (#activePromptIdxList) then
		activePromptPtr = 1;
	end;
end;
rebuildActiveSets();
local heartbeatConn = nil;
local loopRun = false;
local tokenClicks = 0;
local tokenPrompts = 0;
local function stepClicks(hrpPos, quota)
	local fired = 0;
	local n = #activeClickIdxList;
	if n == 0 then
		return 0;
	end;
	local start = activeClickPtr;
	while fired < quota do
		local idx = activeClickPtr;
		activeClickPtr = idx + 1;
		if activeClickPtr > n then
			activeClickPtr = 1;
		end;
		local ci = activeClickIdxList[idx];
		local v = ci and clickDetectors[ci];
		if v and v.Parent then
			if withinRangeWith(hrpPos, v, v.MaxActivationDistance) then
				pcall(fireclickdetector, v);
				fired = fired + 1;
			end;
		end;
		if activeClickPtr == start then
			break;
		end;
	end;
	return fired;
end;
local function stepPrompts(hrpPos, quota)
	local fired = 0;
	local n = #activePromptIdxList;
	if n == 0 then
		return 0;
	end;
	local start = activePromptPtr;
	while fired < quota do
		local idx = activePromptPtr;
		activePromptPtr = idx + 1;
		if activePromptPtr > n then
			activePromptPtr = 1;
		end;
		local pi = activePromptIdxList[idx];
		local v = pi and proximityPrompts[pi];
		if v and v.Parent then
			if withinRangeWith(hrpPos, v, v.MaxActivationDistance) then
				pcall(fireproximityprompt, v);
				fired = fired + 1;
			end;
		end;
		if activePromptPtr == start then
			break;
		end;
	end;
	return fired;
end;
local function stopScheduler()
	if heartbeatConn then
		heartbeatConn:Disconnect();
		heartbeatConn = nil;
	end;
	loopRun = false;
end;
local function startScheduler()
	stopScheduler();
	if waitTime <= 0 then
		heartbeatConn = runService.Heartbeat:Connect(function(dt)
			local hrp = getHRP();
			local pos = hrp and hrp.Position or nil;
			local targetRate = math.clamp(((#activeClickIdxList) + (#activePromptIdxList)) * 10, 120, 4000);
			tokenClicks = tokenClicks + targetRate * dt * 0.5;
			tokenPrompts = tokenPrompts + targetRate * dt * 0.5;
			local maxPerFrame = 96;
			if clicksEnabled and tokenClicks >= 1 then
				local ops = math.min(math.floor(tokenClicks), maxPerFrame);
				tokenClicks = tokenClicks - ops;
				stepClicks(pos, ops);
			end;
			if promptsEnabled and tokenPrompts >= 1 then
				local ops = math.min(math.floor(tokenPrompts), maxPerFrame);
				tokenPrompts = tokenPrompts - ops;
				stepPrompts(pos, ops);
			end;
		end);
	else
		if loopRun then
			return;
		end;
		loopRun = true;
		task.spawn(function()
			while loopRun do
				local hrp = getHRP();
				local pos = hrp and hrp.Position or nil;
				local burst = waitTime <= 0.1;
				local baseOps = math.max(1, math.floor(((#activeClickIdxList) + (#activePromptIdxList)) / 20));
				local clickOps = burst and (#activeClickIdxList) or baseOps;
				local promptOps = burst and (#activePromptIdxList) or baseOps;
				if clicksEnabled and clickOps > 0 then
					stepClicks(pos, clickOps);
				end;
				if promptsEnabled and promptOps > 0 then
					stepPrompts(pos, promptOps);
				end;
				task.wait(waitTime);
			end;
		end);
	end;
end;
startScheduler();
local screenGui = Instance.new("ScreenGui");
screenGui.Name = "CUI_Floats_V16";
screenGui.ResetOnSpawn = false;
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
screenGui.IgnoreGuiInset = true;
screenGui.Parent = coreGui;
local uiScale = Instance.new("UIScale", screenGui);
uiScale.Scale = 1;
local DragController = {
	activeGui = nil,
	input = nil,
	startPos = nil,
	guiStart = nil
};
function DragController:attachHandle(targetGui, handle)
	handle.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and (not self.activeGui) then
			self.activeGui = targetGui;
			self.input = input;
			self.startPos = input.Position;
			self.guiStart = targetGui.Position;
		end;
	end);
end;
userInput.InputChanged:Connect(function(input)
	local dc = DragController;
	if dc.activeGui and input == dc.input then
		local d = input.Position - dc.startPos;
		dc.activeGui.Position = UDim2.new(dc.guiStart.X.Scale, dc.guiStart.X.Offset + d.X, dc.guiStart.Y.Scale, dc.guiStart.Y.Offset + d.Y);
	end;
end);
userInput.InputEnded:Connect(function(input)
	local dc = DragController;
	if dc.activeGui and input == dc.input then
		dc.activeGui = nil;
		dc.input = nil;
		dc.startPos = nil;
		dc.guiStart = nil;
	end;
end);
local function pill(parent, text, w, h)
	local b = Instance.new("TextButton");
	b.AutoButtonColor = true;
	b.Size = UDim2.new(0, w, 0, h);
	b.BackgroundColor3 = Color3.fromRGB(44, 44, 50);
	b.BorderSizePixel = 0;
	b.TextColor3 = Color3.fromRGB(255, 255, 255);
	b.Font = Enum.Font.GothamSemibold;
	b.TextScaled = true;
	b.Text = text;
	local c = Instance.new("UICorner", b);
	c.CornerRadius = UDim.new(1, 12);
	local tsc = Instance.new("UITextSizeConstraint", b);
	tsc.MaxTextSize = 16;
	b.Parent = parent;
	return b;
end;
local function glow(btn, on)
	local s = btn:FindFirstChild("GStroke") or Instance.new("UIStroke");
	s.Name = "GStroke";
	s.Thickness = 2;
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	s.Parent = btn;
	s.Enabled = on and true or false;
	s.Color = on and Color3.fromRGB(60, 200, 120) or Color3.fromRGB(0, 0, 0);
	btn.BackgroundColor3 = on and Color3.fromRGB(50, 110, 70) or Color3.fromRGB(60, 60, 68);
end;
local function dropdownFrame(parent, title, w, h)
	local f = Instance.new("Frame");
	f.Size = UDim2.new(0, w, 0, h);
	f.BackgroundColor3 = Color3.fromRGB(28, 28, 32);
	f.BorderSizePixel = 0;
	f.ClipsDescendants = true;
	local c = Instance.new("UICorner", f);
	c.CornerRadius = UDim.new(0, 10);
	f.Parent = parent;
	local bar = Instance.new("Frame", f);
	bar.Size = UDim2.new(1, 0, 0, 28);
	bar.BackgroundColor3 = Color3.fromRGB(34, 34, 38);
	bar.BorderSizePixel = 0;
	local bc = Instance.new("UICorner", bar);
	bc.CornerRadius = UDim.new(0, 10);
	local tl = Instance.new("TextLabel", bar);
	tl.BackgroundTransparency = 1;
	tl.Size = UDim2.new(1, -100, 1, 0);
	tl.Position = UDim2.new(0, 10, 0, 0);
	tl.Font = Enum.Font.GothamSemibold;
	tl.TextColor3 = Color3.fromRGB(240, 240, 240);
	tl.TextScaled = true;
	tl.Text = title;
	local tsc = Instance.new("UITextSizeConstraint", tl);
	tsc.MaxTextSize = 16;
	local close = Instance.new("TextButton", bar);
	close.Size = UDim2.new(0, 28, 0, 22);
	close.Position = UDim2.new(1, -34, 0.5, -11);
	close.BackgroundColor3 = Color3.fromRGB(70, 70, 78);
	close.BorderSizePixel = 0;
	close.Text = "X";
	close.TextScaled = true;
	close.TextColor3 = Color3.fromRGB(255, 255, 255);
	local cc = Instance.new("UICorner", close);
	cc.CornerRadius = UDim.new(1, 8);
	local unselect = Instance.new("TextButton", bar);
	unselect.Size = UDim2.new(0, 64, 0, 22);
	unselect.Position = UDim2.new(1, -104, 0.5, -11);
	unselect.BackgroundColor3 = Color3.fromRGB(90, 90, 100);
	unselect.BorderSizePixel = 0;
	unselect.Text = "Unselect";
	unselect.TextScaled = true;
	unselect.TextColor3 = Color3.fromRGB(255, 255, 255);
	local uc = Instance.new("UICorner", unselect);
	uc.CornerRadius = UDim.new(1, 8);
	local body = Instance.new("ScrollingFrame", f);
	body.Size = UDim2.new(1, -10, 1, -40);
	body.Position = UDim2.new(0, 5, 0, 34);
	body.BackgroundTransparency = 1;
	body.BorderSizePixel = 0;
	body.ScrollBarThickness = 6;
	body.ScrollingEnabled = true;
	body.AutomaticCanvasSize = Enum.AutomaticSize.Y;
	local ul = Instance.new("UIListLayout", body);
	ul.FillDirection = Enum.FillDirection.Vertical;
	ul.Padding = UDim.new(0, 6);
	ul.HorizontalAlignment = Enum.HorizontalAlignment.Left;
	close.Activated:Connect(function()
		f.Visible = false;
	end);
	return f, bar, body, unselect;
end;
local function listRow(parent, text, active, onToggle)
	local b = Instance.new("TextButton");
	b.Size = UDim2.new(1, -8, 0, 28);
	b.Position = UDim2.fromOffset(4, 0);
	b.BackgroundColor3 = active and Color3.fromRGB(50, 110, 70) or Color3.fromRGB(60, 60, 68);
	b.BorderSizePixel = 0;
	b.Text = "  " .. text;
	b.TextScaled = true;
	b.TextXAlignment = Enum.TextXAlignment.Left;
	b.TextColor3 = Color3.fromRGB(255, 255, 255);
	b.Font = Enum.Font.Gotham;
	local rc = Instance.new("UICorner", b);
	rc.CornerRadius = UDim.new(1, 8);
	local tsc = Instance.new("UITextSizeConstraint", b);
	tsc.MaxTextSize = 14;
	glow(b, active);
	b.Parent = parent;
	b.Activated:Connect(function()
		onToggle(b);
	end);
	return b;
end;
local function groupFrame(w)
	local g = Instance.new("Frame");
	g.Size = UDim2.new(0, w, 0, 40);
	g.BackgroundTransparency = 1;
	g.Parent = screenGui;
	return g;
end;
local groupInterval = groupFrame(150);
groupInterval.AnchorPoint = Vector2.new(0, 0);
local btnDelay = pill(groupInterval, "Interval: " .. tostring(waitTime) .. "s", 150, 36);
local groupDistance = groupFrame(170);
groupDistance.AnchorPoint = Vector2.new(1, 0);
local btnDist = pill(groupDistance, "Distance Check: Off", 170, 36);
local groupClicks = groupFrame(300);
groupClicks.AnchorPoint = Vector2.new(1, 0);
local btnCD = pill(groupClicks, "ClickDetectors: Off", 170, 36);
btnCD.Position = UDim2.fromOffset(0, 2);
local btnCDSel = pill(groupClicks, "Select", 120, 36);
btnCDSel.Position = UDim2.fromOffset(180, 2);
local ddClicks, ddBar, ddClicksBody, btnUnselClicks = dropdownFrame(groupClicks, "Clicks", 300, 260);
ddClicks.Position = UDim2.fromOffset(0, 44);
ddClicks.Visible = false;
local groupPrompts = groupFrame(300);
groupPrompts.AnchorPoint = Vector2.new(0, 0);
local btnPP = pill(groupPrompts, "Prompts: Off", 170, 36);
btnPP.Position = UDim2.fromOffset(0, 2);
local btnPPSel = pill(groupPrompts, "Select", 120, 36);
btnPPSel.Position = UDim2.fromOffset(180, 2);
local ddPrompts, ddPBar, ddPromptsBody, btnUnselPrompts = dropdownFrame(groupPrompts, "Prompts", 300, 260);
ddPrompts.Position = UDim2.fromOffset(0, 44);
ddPrompts.Visible = false;
for _, h in ipairs({
	groupClicks,
	btnCD,
	btnCDSel,
	ddBar
}) do
	DragController:attachHandle(groupClicks, h);
end;
for _, h in ipairs({
	groupPrompts,
	btnPP,
	btnPPSel,
	ddPBar
}) do
	DragController:attachHandle(groupPrompts, h);
end;
for _, h in ipairs({
	groupInterval,
	btnDelay
}) do
	DragController:attachHandle(groupInterval, h);
end;
for _, h in ipairs({
	groupDistance,
	btnDist
}) do
	DragController:attachHandle(groupDistance, h);
end;
local topPaddingButtons = 44;
local topPaddingUtilities = 128;
local centerGap = 56;
local function placeTop()
	local cam = workspace.CurrentCamera;
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720);
	local margin = 10;
	groupClicks.Position = UDim2.new(0.5, -math.floor((centerGap / 2)), 0, topPaddingButtons);
	groupPrompts.Position = UDim2.new(0.5, math.floor(centerGap / 2), 0, topPaddingButtons);
	groupInterval.Position = UDim2.new(0, margin, 0, topPaddingUtilities);
	groupDistance.Position = UDim2.new(1, -margin, 0, topPaddingUtilities);
	uiScale.Scale = math.clamp(math.min(vp.X, vp.Y) / 1100, 0.74, 1.02);
end;
if workspace.CurrentCamera then
	(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize")):Connect(placeTop);
end;
task.defer(placeTop);
btnDist.Activated:Connect(function()
	distanceCheck = not distanceCheck;
	btnDist.Text = distanceCheck and "Distance Check: On" or "Distance Check: Off";
	btnDist.BackgroundColor3 = distanceCheck and Color3.fromRGB(50, 110, 70) or Color3.fromRGB(44, 44, 50);
end);
btnDelay.Activated:Connect(function()
	local box = Instance.new("TextBox");
	box.Size = btnDelay.Size;
	local ap = btnDelay.AbsolutePosition;
	box.Position = UDim2.fromOffset(ap.X, ap.Y);
	box.BackgroundColor3 = Color3.fromRGB(70, 70, 78);
	box.BorderSizePixel = 0;
	box.TextColor3 = Color3.fromRGB(255, 255, 255);
	box.Font = Enum.Font.Gotham;
	box.TextScaled = true;
	box.Text = "";
	box.PlaceholderText = tostring(waitTime);
	box.ClearTextOnFocus = true;
	local c = Instance.new("UICorner", box);
	c.CornerRadius = UDim.new(1, 12);
	local tsc = Instance.new("UITextSizeConstraint", box);
	tsc.MaxTextSize = 16;
	box.Parent = screenGui;
	DragController:attachHandle(groupInterval, box);
	box:CaptureFocus();
	box.FocusLost:Connect(function(enter)
		if enter then
			local v = tonumber(box.Text);
			if v and v >= 0 then
				waitTime = v;
				startScheduler();
			end;
		end;
		btnDelay.Text = "Interval: " .. tostring(waitTime) .. "s";
		box:Destroy();
	end);
end);
btnCD.Activated:Connect(function()
	clicksEnabled = not clicksEnabled;
	btnCD.Text = clicksEnabled and "ClickDetectors: On" or "ClickDetectors: Off";
	btnCD.BackgroundColor3 = clicksEnabled and Color3.fromRGB(50, 110, 70) or Color3.fromRGB(44, 44, 50);
end);
btnPP.Activated:Connect(function()
	promptsEnabled = not promptsEnabled;
	btnPP.Text = promptsEnabled and "Prompts: On" or "Prompts: Off";
	btnPP.BackgroundColor3 = promptsEnabled and Color3.fromRGB(50, 110, 70) or Color3.fromRGB(44, 44, 50);
end);
local function clearChildren(p)
	for _, c in ipairs(p:GetChildren()) do
		if not c:IsA("UIListLayout") then
			c:Destroy();
		end;
	end;
end;
local function rebuildClicksList()
	clearChildren(ddClicksBody);
	local seen = {};
	for _, cd in ipairs(clickDetectors) do
		if cd and cd.Parent then
			seen[holderNameFor(cd)] = true;
		end;
	end;
	for k, _ in pairs(selectedClickNames) do
		seen[k] = seen[k] or false;
	end;
	for label, _ in pairs(seen) do
		local act = selectedClickNames[label] and true or false;
		listRow(ddClicksBody, label, act, function(btn)
			local ns = not (selectedClickNames[label] and true or false);
			if not ns and seen[label] == false then
				selectedClickNames[label] = nil;
				btn:Destroy();
			else
				selectedClickNames[label] = ns or nil;
				glow(btn, ns);
			end;
			rebuildActiveSets();
		end);
	end;
end;
local function rebuildPromptsList()
	clearChildren(ddPromptsBody);
	local seen = {};
	for _, pp in ipairs(proximityPrompts) do
		if pp and pp.Parent then
			seen[holderNameFor(pp)] = true;
		end;
	end;
	for k, _ in pairs(selectedPromptNames) do
		seen[k] = seen[k] or false;
	end;
	for label, _ in pairs(seen) do
		local act = selectedPromptNames[label] and true or false;
		listRow(ddPromptsBody, label, act, function(btn)
			local ns = not (selectedPromptNames[label] and true or false);
			if not ns and seen[label] == false then
				selectedPromptNames[label] = nil;
				btn:Destroy();
			else
				selectedPromptNames[label] = ns or nil;
				glow(btn, ns);
			end;
			rebuildActiveSets();
		end);
	end;
end;
local clicksRefreshRunning = false;
local promptsRefreshRunning = false;
local function ensureAutoRefreshClicks()
	if clicksRefreshRunning then
		return;
	end;
	clicksRefreshRunning = true;
	task.spawn(function()
		while ddClicks.Visible do
			rebuildClicksList();
			task.wait(0.35);
		end;
		clicksRefreshRunning = false;
	end);
end;
local function ensureAutoRefreshPrompts()
	if promptsRefreshRunning then
		return;
	end;
	promptsRefreshRunning = true;
	task.spawn(function()
		while ddPrompts.Visible do
			rebuildPromptsList();
			task.wait(0.35);
		end;
		promptsRefreshRunning = false;
	end);
end;
btnUnselClicks.Activated:Connect(function()
	table.clear(selectedClickNames);
	rebuildActiveSets();
	rebuildClicksList();
end);
btnUnselPrompts.Activated:Connect(function()
	table.clear(selectedPromptNames);
	rebuildActiveSets();
	rebuildPromptsList();
end);
btnCDSel.Activated:Connect(function()
	ddPrompts.Visible = false;
	ddClicks.Visible = not ddClicks.Visible;
	if ddClicks.Visible then
		ensureAutoRefreshClicks();
	else
		clicksRefreshRunning = false;
	end;
end);
btnPPSel.Activated:Connect(function()
	ddClicks.Visible = false;
	ddPrompts.Visible = not ddPrompts.Visible;
	if ddPrompts.Visible then
		ensureAutoRefreshPrompts();
	else
		promptsRefreshRunning = false;
	end;
end);
workspace.DescendantAdded:Connect(function(o)
	if o:IsA("ClickDetector") then
		table.insert(clickDetectors, o);
	elseif o:IsA("ProximityPrompt") then
		table.insert(proximityPrompts, o);
	end;
	rebuildActiveSets();
end);
workspace.DescendantRemoving:Connect(function(o)
	if o:IsA("ClickDetector") then
		for i, v in ipairs(clickDetectors) do
			if v == o then
				table.remove(clickDetectors, i);
				break;
			end;
		end;
	elseif o:IsA("ProximityPrompt") then
		for i, v in ipairs(proximityPrompts) do
			if v == o then
				table.remove(proximityPrompts, i);
				break;
			end;
		end;
	end;
	rebuildActiveSets();
end);
task.defer(placeTop);
