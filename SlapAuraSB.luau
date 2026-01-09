if game.GameId ~= 2380077519 then
	return;
end;
local Players = game:GetService("Players");
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");
local UserInputService = game:GetService("UserInputService");
local localPlayer = Players.LocalPlayer;
local attackRemotes, attackRemoteSet = {}, {};
local forbiddenNames = {
	disarmh = true,
	b = true,
	htstun = true
};
local function addRemote(v)
	if v:IsA("RemoteEvent") then
		local n = v.Name:lower();
		if n:find("hit") or forbiddenNames[n] then
			if not attackRemoteSet[v] then
				attackRemoteSet[v] = true;
				attackRemotes[(#attackRemotes) + 1] = v;
			end;
		end;
	end;
end;
local function removeRemote(v)
	if attackRemoteSet[v] then
		attackRemoteSet[v] = nil;
		for i = #attackRemotes, 1, -1 do
			if attackRemotes[i] == v then
				table.remove(attackRemotes, i);
			end;
		end;
	end;
end;
for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
	addRemote(d);
end;
ReplicatedStorage.DescendantAdded:Connect(addRemote);
ReplicatedStorage.DescendantRemoving:Connect(removeRemote);
local ghostRemote = ReplicatedStorage:WaitForChild("Ghostinvisibilityactivated");
local radius, delay = 17.5, 0.85;
local rootPart, aura;
local ignoreFriends = false;
local auraEnabled = false;
local loops = {};
local mode = "Enter";
local modeId = 0;
local allLoopActive = false;
local trackedPlayers, playersData, rootCache, friendsCache = {}, {}, {}, {};
local isFriend = setmetatable({}, {
	__call = function(_, uid)
		local v = friendsCache[uid];
		if v ~= nil then
			return v;
		end;
		local ok, res = pcall(function()
			return localPlayer:IsFriendsWith(uid);
		end);
		friendsCache[uid] = ok and res or false;
		return friendsCache[uid];
	end
});
local function getRootPart(ch)
	local rp = rootCache[ch];
	if rp and rp.Parent == ch then
		return rp;
	end;
	rp = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso");
	rootCache[ch] = rp;
	return rp;
end;
local function initPlayer(p)
	trackedPlayers[(#trackedPlayers) + 1] = p;
	playersData[p] = {
		inArena = false
	};
	local function setFlag(f)
		playersData[p].inArena = f and f.Value or false;
		if f then
			f.Changed:Connect(function()
				playersData[p].inArena = f.Value;
			end);
		end;
	end;
	p.CharacterAdded:Connect(function(ch)
		rootCache[ch] = nil;
		local f = ch:FindFirstChild("isInArena") or ch:FindFirstChild("IsInDefaultArena");
		setFlag(f);
	end);
	p.CharacterRemoving:Connect(function(ch)
		rootCache[ch] = nil;
	end);
	if p.Character then
		local ch = p.Character;
		rootCache[ch] = nil;
		local f = ch:FindFirstChild("isInArena") or ch:FindFirstChild("IsInDefaultArena");
		setFlag(f);
	end;
end;
for _, p in ipairs(Players:GetPlayers()) do
	initPlayer(p);
end;
Players.PlayerAdded:Connect(initPlayer);
Players.PlayerRemoving:Connect(function(p)
	for i = #trackedPlayers, 1, -1 do
		if trackedPlayers[i] == p then
			table.remove(trackedPlayers, i);
		end;
	end;
	playersData[p] = nil;
	loops[p] = nil;
end);
local function createAura()
	if aura then
		aura:Destroy();
	end;
	aura = Instance.new("Part");
	aura.Name = "Aura";
	aura.Shape = Enum.PartType.Ball;
	aura.Anchored = true;
	aura.CanCollide = false;
	aura.CastShadow = false;
	aura.Material = Enum.Material.ForceField;
	aura.Transparency = 0;
	aura.Size = Vector3.new(radius * 2, radius * 2, radius * 2);
	aura.Parent = workspace;
end;
local function onCharacterAdded(ch)
	local r = ch:WaitForChild("HumanoidRootPart", 5) or ch:WaitForChild("Torso", 5);
	if not r then
		return;
	end;
	rootPart = r;
	if auraEnabled then
		createAura();
	end;
end;
local function onCharacterRemoving()
	if aura then
		aura:Destroy();
	end;
	rootPart, aura = nil, nil;
	loops = {};
end;
localPlayer.CharacterAdded:Connect(onCharacterAdded);
localPlayer.CharacterRemoving:Connect(onCharacterRemoving);
if localPlayer.Character then
	onCharacterAdded(localPlayer.Character);
end;
local guiParent = type(gethui) == "function" and gethui() or game:GetService("CoreGui") or localPlayer:WaitForChild("PlayerGui");
local screenGui = Instance.new("ScreenGui");
screenGui.Name = "Sex Hub";
screenGui.IgnoreGuiInset = true;
screenGui.ResetOnSpawn = false;
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
screenGui.Parent = guiParent;
local toastRoot = Instance.new("Frame");
toastRoot.AnchorPoint = Vector2.new(0.5, 1);
toastRoot.Position = UDim2.new(0.5, 0, 1, -12);
toastRoot.Size = UDim2.new(0, 400, 0, 140);
toastRoot.BackgroundTransparency = 1;
toastRoot.Parent = screenGui;
local toastList = Instance.new("UIListLayout");
toastList.FillDirection = Enum.FillDirection.Vertical;
toastList.Padding = UDim.new(0, 8);
toastList.HorizontalAlignment = Enum.HorizontalAlignment.Center;
toastList.VerticalAlignment = Enum.VerticalAlignment.Bottom;
toastList.SortOrder = Enum.SortOrder.LayoutOrder;
toastList.Parent = toastRoot;
local function showToast(text, dur)
	local f = Instance.new("Frame");
	f.Size = UDim2.new(0, 280, 0, 40);
	f.BackgroundColor3 = Color3.fromRGB(26, 26, 32);
	f.BackgroundTransparency = 0.15;
	f.ClipsDescendants = true;
	f.Parent = toastRoot;
	local c = Instance.new("UICorner");
	c.CornerRadius = UDim.new(0, 12);
	c.Parent = f;
	local s = Instance.new("UIStroke");
	s.Thickness = 1;
	s.Color = Color3.fromRGB(86, 142, 255);
	s.Transparency = 0.5;
	s.Parent = f;
	local l = Instance.new("TextLabel");
	l.BackgroundTransparency = 1;
	l.Size = UDim2.new(1, -24, 1, 0);
	l.Position = UDim2.new(0, 12, 0, 0);
	l.Font = Enum.Font.Gotham;
	l.TextSize = 14;
	l.TextColor3 = Color3.fromRGB(235, 235, 245);
	l.TextWrapped = true;
	l.Text = tostring(text);
	l.Parent = f;
	f.Position = UDim2.new(0.5, 0, 1, 20);
	f.AnchorPoint = Vector2.new(0.5, 1);
	f.BackgroundTransparency = 1;
	l.TextTransparency = 1;
	s.Transparency = 1;
	(TweenService:Create(f, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 0.15
	})):Play();
	(TweenService:Create(l, TweenInfo.new(0.18), {
		TextTransparency = 0
	})):Play();
	(TweenService:Create(s, TweenInfo.new(0.18), {
		Transparency = 0.5
	})):Play();
	task.delay(dur or 2.5, function()
		local t1 = TweenService:Create(f, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 1, 20),
			BackgroundTransparency = 1
		});
		local t2 = TweenService:Create(l, TweenInfo.new(0.16), {
			TextTransparency = 1
		});
		local t3 = TweenService:Create(s, TweenInfo.new(0.16), {
			Transparency = 1
		});
		t1:Play();
		t2:Play();
		t3:Play();
		t1.Completed:Connect(function()
			f:Destroy();
		end);
	end);
end;
local container = Instance.new("Frame");
container.AnchorPoint = Vector2.new(0.5, 0);
container.Size = UDim2.new(0, 520, 0, 380);
container.Position = UDim2.new(0.5, 0, 0.12, 0);
container.BackgroundTransparency = 1;
container.ClipsDescendants = false;
container.Parent = screenGui;
local panelShadow = Instance.new("ImageLabel");
panelShadow.AnchorPoint = Vector2.new(0.5, 0.5);
panelShadow.Position = UDim2.fromScale(0.5, 0.5);
panelShadow.Size = UDim2.new(1, 110, 1, 110);
panelShadow.BackgroundTransparency = 1;
panelShadow.Image = "rbxassetid://5028857084";
panelShadow.ImageTransparency = 0.5;
panelShadow.ScaleType = Enum.ScaleType.Slice;
panelShadow.SliceCenter = Rect.new(24, 24, 276, 276);
panelShadow.ZIndex = 0;
panelShadow.Parent = container;
local panel = Instance.new("Frame");
panel.AnchorPoint = Vector2.new(0.5, 0.5);
panel.Position = UDim2.fromScale(0.5, 0.5);
panel.Size = UDim2.new(1, 0, 1, 0);
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 24);
panel.BackgroundTransparency = 0.04;
panel.ClipsDescendants = true;
panel.ZIndex = 1;
panel.Parent = container;
local stroke = Instance.new("UIStroke");
stroke.Thickness = 1;
stroke.Color = Color3.fromRGB(86, 142, 255);
stroke.Transparency = 0;
stroke.Parent = panel;
local corner = Instance.new("UICorner");
corner.CornerRadius = UDim.new(0, 16);
corner.Parent = panel;
local gradient = Instance.new("UIGradient");
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 30, 38)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 16))
});
gradient.Rotation = 90;
gradient.Parent = panel;
local padding = Instance.new("UIPadding");
padding.PaddingLeft = UDim.new(0, 18);
padding.PaddingRight = UDim.new(0, 18);
padding.PaddingTop = UDim.new(0, 14);
padding.PaddingBottom = UDim.new(0, 14);
padding.Parent = panel;
local header = Instance.new("Frame");
header.Size = UDim2.new(1, 0, 0, 40);
header.BackgroundTransparency = 1;
header.ZIndex = 3;
header.Parent = panel;
local title = Instance.new("TextLabel");
title.BackgroundTransparency = 1;
title.Size = UDim2.new(1, -120, 1, 0);
title.Text = "Sex Hub";
title.Font = Enum.Font.GothamSemibold;
title.TextColor3 = Color3.fromRGB(240, 240, 255);
title.TextSize = 18;
title.TextXAlignment = Enum.TextXAlignment.Left;
title.ZIndex = 3;
title.Parent = header;
local rgbStrokes = {
	stroke
};
local function ripple(parent)
	local m = UserInputService:GetMouseLocation();
	local rx = m.X - parent.AbsolutePosition.X;
	local ry = m.Y - parent.AbsolutePosition.Y;
	local r = Instance.new("Frame");
	r.BackgroundTransparency = 0.85;
	r.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	r.Size = UDim2.fromOffset(0, 0);
	r.AnchorPoint = Vector2.new(0.5, 0.5);
	r.Position = UDim2.fromOffset(rx, ry);
	r.ZIndex = 10;
	r.Parent = parent;
	local rc = Instance.new("UICorner");
	rc.CornerRadius = UDim.new(1, 0);
	rc.Parent = r;
	local maxd = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 1.6;
	(TweenService:Create(r, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(maxd, maxd),
		BackgroundTransparency = 1
	})):Play();
	task.delay(0.52, function()
		if r then
			r:Destroy();
		end;
	end);
end;
local function button(text, parent, w, h)
	local b = Instance.new("TextButton");
	b.AutoButtonColor = false;
	b.Size = UDim2.new(0, w or 160, 0, h or 36);
	b.BackgroundColor3 = Color3.fromRGB(32, 32, 42);
	b.Text = text;
	b.Font = Enum.Font.Gotham;
	b.TextSize = 14;
	b.TextColor3 = Color3.fromRGB(235, 235, 245);
	b.ZIndex = 2;
	b.ClipsDescendants = true;
	b.Parent = parent;
	local bc = Instance.new("UICorner");
	bc.CornerRadius = UDim.new(0, 12);
	bc.Parent = b;
	local bs = Instance.new("UIStroke");
	bs.Thickness = 1;
	bs.Color = Color3.fromRGB(86, 142, 255);
	bs.Transparency = 0.25;
	bs.Parent = b;
	table.insert(rgbStrokes, bs);
	b.MouseEnter:Connect(function()
		(TweenService:Create(b, TweenInfo.new(0.14), {
			BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		})):Play();
		(TweenService:Create(b, TweenInfo.new(0.14), {
			Size = UDim2.new(0, (w or 160) + 2, 0, h or 36)
		})):Play();
	end);
	b.MouseLeave:Connect(function()
		(TweenService:Create(b, TweenInfo.new(0.16), {
			BackgroundColor3 = Color3.fromRGB(32, 32, 42)
		})):Play();
		(TweenService:Create(b, TweenInfo.new(0.16), {
			Size = UDim2.new(0, w or 160, 0, h or 36)
		})):Play();
	end);
	b.MouseButton1Down:Connect(function()
		ripple(b);
		b:TweenSize(UDim2.new(0, (w or 160) - 2, 0, h or 36), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.06, true, function()
			b:TweenSize(UDim2.new(0, w or 160, 0, h or 36), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.18, true);
		end);
	end);
	return b;
end;
local tabBar = Instance.new("Frame");
tabBar.Size = UDim2.new(1, 0, 0, 42);
tabBar.Position = UDim2.new(0, 0, 0, 44);
tabBar.BackgroundTransparency = 1;
tabBar.Parent = panel;
local tabBg = Instance.new("Frame");
tabBg.Size = UDim2.new(0, 360, 0, 36);
tabBg.AnchorPoint = Vector2.new(0, 0.5);
tabBg.Position = UDim2.new(0, 0, 0.5, 0);
tabBg.BackgroundColor3 = Color3.fromRGB(32, 32, 42);
tabBg.Parent = tabBar;
local tabCorner = Instance.new("UICorner");
tabCorner.CornerRadius = UDim.new(0, 12);
tabCorner.Parent = tabBg;
local tabStroke = Instance.new("UIStroke");
tabStroke.Thickness = 1;
tabStroke.Color = Color3.fromRGB(86, 142, 255);
tabStroke.Transparency = 0.25;
tabStroke.Parent = tabBg;
table.insert(rgbStrokes, tabStroke);
local tabSelector = Instance.new("Frame");
tabSelector.BackgroundColor3 = Color3.fromRGB(86, 142, 255);
tabSelector.BackgroundTransparency = 0.1;
tabSelector.Size = UDim2.new(0, 112, 1, 0);
tabSelector.Position = UDim2.new(0, 0, 0, 0);
tabSelector.Parent = tabBg;
local tabSelCorner = Instance.new("UICorner");
tabSelCorner.CornerRadius = UDim.new(0, 12);
tabSelCorner.Parent = tabSelector;
local tabButtons = Instance.new("Frame");
tabButtons.BackgroundTransparency = 1;
tabButtons.Size = UDim2.new(1, 0, 1, 0);
tabButtons.Parent = tabBg;
local tabList = Instance.new("UIListLayout");
tabList.FillDirection = Enum.FillDirection.Horizontal;
tabList.Padding = UDim.new(0, 12);
tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center;
tabList.VerticalAlignment = Enum.VerticalAlignment.Center;
tabList.Parent = tabButtons;
local function makeTabButton(txt)
	local b = Instance.new("TextButton");
	b.AutoButtonColor = false;
	b.Size = UDim2.new(0, 112, 1, 0);
	b.BackgroundTransparency = 1;
	b.Text = txt;
	b.Font = Enum.Font.GothamMedium;
	b.TextSize = 13;
	b.TextColor3 = Color3.fromRGB(220, 220, 235);
	b.Parent = tabButtons;
	return b;
end;
local tabActions = makeTabButton("Actions");
local tabSettings = makeTabButton("Settings");
local tabCombat = makeTabButton("Combat");
local activeTab = tabActions;
local content = Instance.new("Frame");
content.Size = UDim2.new(1, 0, 1, -(44 + 42 + 16));
content.Position = UDim2.new(0, 0, 0, 44 + 42 + 12);
content.BackgroundTransparency = 1;
content.ClipsDescendants = true;
content.Parent = panel;
local function makePage()
	local p = Instance.new("Frame");
	p.Size = UDim2.new(1, 0, 1, 0);
	p.BackgroundTransparency = 1;
	p.Visible = false;
	p.Parent = content;
	return p;
end;
local pageActions = makePage();
local pageSettings = makePage();
local pageCombat = makePage();
local function moveTabSelector(toBtn, animate)
	activeTab = toBtn;
	local relX = toBtn.AbsolutePosition.X - tabBg.AbsolutePosition.X;
	local w = toBtn.AbsoluteSize.X;
	if animate then
		(TweenService:Create(tabSelector, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, relX, 0, 0),
			Size = UDim2.new(0, w, 1, 0)
		})):Play();
	else
		tabSelector.Position = UDim2.new(0, relX, 0, 0);
		tabSelector.Size = UDim2.new(0, w, 1, 0);
	end;
	for _, b in ipairs({
		tabActions,
		tabSettings,
		tabCombat
	}) do
		(TweenService:Create(b, TweenInfo.new(0.12), {
			TextColor3 = b == toBtn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(220, 220, 235)
		})):Play();
	end;
end;
local function showPage(pg)
	pageActions.Visible = false;
	pageSettings.Visible = false;
	pageCombat.Visible = false;
	pg.Visible = true;
end;
tabActions.MouseButton1Click:Connect(function()
	ripple(tabBg);
	moveTabSelector(tabActions, true);
	showPage(pageActions);
end);
tabSettings.MouseButton1Click:Connect(function()
	ripple(tabBg);
	moveTabSelector(tabSettings, true);
	showPage(pageSettings);
end);
tabCombat.MouseButton1Click:Connect(function()
	ripple(tabBg);
	moveTabSelector(tabCombat, true);
	showPage(pageCombat);
end);
task.defer(function()
	moveTabSelector(tabActions, false);
	showPage(pageActions);
end);
RunService.RenderStepped:Connect(function()
	if activeTab and tabSelector.Parent == tabBg then
		tabSelector.Position = UDim2.new(0, activeTab.AbsolutePosition.X - tabBg.AbsolutePosition.X, 0, 0);
		tabSelector.Size = UDim2.new(0, activeTab.AbsoluteSize.X, 1, 0);
	end;
end);
local actionsList = Instance.new("UIListLayout");
actionsList.FillDirection = Enum.FillDirection.Vertical;
actionsList.Padding = UDim.new(0, 12);
actionsList.Parent = pageActions;
local ghostBtn = button("Ghost Invis", pageActions, 180, 40);
local setList = Instance.new("UIListLayout");
setList.FillDirection = Enum.FillDirection.Vertical;
setList.Padding = UDim.new(0, 10);
setList.Parent = pageSettings;
local function toggleControl(parent, labelText, initial)
	local holder = Instance.new("Frame");
	holder.Size = UDim2.new(1, 0, 0, 36);
	holder.BackgroundTransparency = 1;
	holder.Parent = parent;
	local lbl = Instance.new("TextLabel");
	lbl.BackgroundTransparency = 1;
	lbl.Size = UDim2.new(1, -80, 1, 0);
	lbl.Text = labelText;
	lbl.TextColor3 = Color3.fromRGB(210, 210, 225);
	lbl.TextXAlignment = Enum.TextXAlignment.Left;
	lbl.Font = Enum.Font.Gotham;
	lbl.TextSize = 14;
	lbl.Parent = holder;
	local t = Instance.new("TextButton");
	t.AutoButtonColor = false;
	t.Size = UDim2.new(0, 66, 0, 30);
	t.Position = UDim2.new(1, -66, 0.5, -15);
	t.BackgroundColor3 = initial and Color3.fromRGB(72, 128, 255) or Color3.fromRGB(50, 50, 60);
	t.Text = "";
	t.Parent = holder;
	local tc = Instance.new("UICorner");
	tc.CornerRadius = UDim.new(1, 0);
	tc.Parent = t;
	local ts = Instance.new("UIStroke");
	ts.Thickness = 1;
	ts.Color = Color3.fromRGB(86, 142, 255);
	ts.Transparency = 0.2;
	ts.Parent = t;
	table.insert(rgbStrokes, ts);
	local knob = Instance.new("Frame");
	knob.Size = UDim2.new(0, 26, 0, 26);
	knob.Position = initial and UDim2.new(1, (-28), 0.5, (-13)) or UDim2.new(0, 2, 0.5, (-13));
	knob.BackgroundColor3 = Color3.fromRGB(245, 245, 255);
	knob.Parent = t;
	local kc = Instance.new("UICorner");
	kc.CornerRadius = UDim.new(1, 0);
	kc.Parent = knob;
	local state = initial;
	local function setState(v)
		state = v;
		local goalBg = v and Color3.fromRGB(72, 128, 255) or Color3.fromRGB(50, 50, 60);
		local goalPos = v and UDim2.new(1, (-28), 0.5, (-13)) or UDim2.new(0, 2, 0.5, (-13));
		(TweenService:Create(t, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = goalBg
		})):Play();
		(TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = goalPos
		})):Play();
	end;
	t.MouseButton1Click:Connect(function()
		setState(not state);
	end);
	return {
		Get = function()
			return state;
		end,
		Set = setState,
		Button = t
	};
end;
local auraToggle = toggleControl(pageSettings, "Aura", false);
local ignoreToggle = toggleControl(pageSettings, "Ignore Friends", false);
local combatList = Instance.new("UIListLayout");
combatList.FillDirection = Enum.FillDirection.Vertical;
combatList.Padding = UDim.new(0, 12);
combatList.Parent = pageCombat;
local function slider(parent, labelText, minV, maxV, startV, decimals)
	local holder = Instance.new("Frame");
	holder.Size = UDim2.new(1, 0, 0, 48);
	holder.BackgroundTransparency = 1;
	holder.Parent = parent;
	local top = Instance.new("Frame");
	top.Size = UDim2.new(1, 0, 0, 18);
	top.BackgroundTransparency = 1;
	top.Parent = holder;
	local lbl = Instance.new("TextLabel");
	lbl.BackgroundTransparency = 1;
	lbl.Size = UDim2.new(1, -84, 1, 0);
	lbl.Text = labelText;
	lbl.TextColor3 = Color3.fromRGB(210, 210, 225);
	lbl.TextXAlignment = Enum.TextXAlignment.Left;
	lbl.Font = Enum.Font.Gotham;
	lbl.TextSize = 13;
	lbl.Parent = top;
	local valueLabel = Instance.new("TextLabel");
	valueLabel.BackgroundTransparency = 1;
	valueLabel.Size = UDim2.new(0, 84, 1, 0);
	valueLabel.Position = UDim2.new(1, -84, 0, 0);
	valueLabel.Text = tostring(startV);
	valueLabel.TextColor3 = Color3.fromRGB(180, 180, 195);
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right;
	valueLabel.Font = Enum.Font.Gotham;
	valueLabel.TextSize = 13;
	valueLabel.Parent = top;
	local track = Instance.new("Frame");
	track.Size = UDim2.new(1, 0, 0, 8);
	track.Position = UDim2.new(0, 0, 0, 24);
	track.BackgroundColor3 = Color3.fromRGB(45, 45, 56);
	track.ClipsDescendants = true;
	track.Parent = holder;
	local tc = Instance.new("UICorner");
	tc.CornerRadius = UDim.new(1, 0);
	tc.Parent = track;
	local fill = Instance.new("Frame");
	fill.Size = UDim2.new((startV - minV) / (maxV - minV), 0, 1, 0);
	fill.Position = UDim2.new(0, 0, 0, 0);
	fill.BackgroundColor3 = Color3.fromRGB(86, 142, 255);
	fill.Parent = track;
	local fc = Instance.new("UICorner");
	fc.CornerRadius = UDim.new(1, 0);
	fc.Parent = fill;
	local thumb = Instance.new("Frame");
	thumb.Size = UDim2.new(0, 18, 0, 18);
	thumb.AnchorPoint = Vector2.new(0.5, 0.5);
	thumb.Position = UDim2.new((startV - minV) / (maxV - minV), 0, 0.5, 0);
	thumb.BackgroundColor3 = Color3.fromRGB(240, 240, 255);
	thumb.Parent = track;
	local thC = Instance.new("UICorner");
	thC.CornerRadius = UDim.new(1, 0);
	thC.Parent = thumb;
	local thS = Instance.new("UIStroke");
	thS.Thickness = 1;
	thS.Color = Color3.fromRGB(190, 190, 210);
	thS.Transparency = 0.1;
	thS.Parent = thumb;
	table.insert(rgbStrokes, thS);
	local dragging = false;
	local value = startV;
	local function setFromAlpha(a, tween)
		a = math.clamp(a, 0, 1);
		value = minV + a * (maxV - minV);
		if decimals == 0 then
			value = math.floor(value + 0.5);
		else
			local m = 10 ^ (decimals or 2);
			value = math.floor((value * m + 0.5)) / m;
		end;
		valueLabel.Text = tostring(value);
		local ti = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);
		if tween then
			(TweenService:Create(fill, ti, {
				Size = UDim2.new(a, 0, 1, 0)
			})):Play();
			(TweenService:Create(thumb, ti, {
				Position = UDim2.new(a, 0, 0.5, 0)
			})):Play();
		else
			fill.Size = UDim2.new(a, 0, 1, 0);
			thumb.Position = UDim2.new(a, 0, 0.5, 0);
		end;
	end;
	local function alphaFromInput(x)
		local abs = track.AbsoluteSize.X;
		local startX = track.AbsolutePosition.X;
		if abs <= 0 then
			return 0;
		end;
		return (x - startX) / abs;
	end;
	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true;
			setFromAlpha(alphaFromInput(inp.Position.X), true);
			ripple(track);
		end;
	end);
	track.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false;
		end;
	end);
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			setFromAlpha(alphaFromInput(inp.Position.X), false);
		end;
	end);
	return {
		Get = function()
			return value;
		end,
		Set = function(v)
			v = math.clamp(v, minV, maxV);
			setFromAlpha((v - minV) / (maxV - minV), true);
		end
	};
end;
local radiusSlider = slider(pageCombat, "Radius", 0, 20, math.clamp(radius, 0, 20), 1);
local delaySlider = slider(pageCombat, "Delay", 0, 3, math.clamp(delay, 0, 3), 2);
local modeWrap = Instance.new("Frame");
modeWrap.Size = UDim2.new(1, 0, 0, 42);
modeWrap.BackgroundTransparency = 1;
modeWrap.Parent = pageCombat;
local seg = Instance.new("Frame");
seg.Size = UDim2.new(0, 240, 1, 0);
seg.BackgroundColor3 = Color3.fromRGB(32, 32, 42);
seg.Parent = modeWrap;
local segCorner = Instance.new("UICorner");
segCorner.CornerRadius = UDim.new(0, 12);
segCorner.Parent = seg;
local segStroke = Instance.new("UIStroke");
segStroke.Thickness = 1;
segStroke.Color = Color3.fromRGB(86, 142, 255);
segStroke.Transparency = 0.25;
segStroke.Parent = seg;
table.insert(rgbStrokes, segStroke);
local selector = Instance.new("Frame");
selector.BackgroundColor3 = Color3.fromRGB(86, 142, 255);
selector.BackgroundTransparency = 0.1;
selector.Size = UDim2.new(0, 114, 1, 0);
selector.Parent = seg;
local selCorner = Instance.new("UICorner");
selCorner.CornerRadius = UDim.new(0, 12);
selCorner.Parent = selector;
local btnHolder = Instance.new("Frame");
btnHolder.BackgroundTransparency = 1;
btnHolder.Size = UDim2.new(1, 0, 1, 0);
btnHolder.Parent = seg;
local segList = Instance.new("UIListLayout");
segList.FillDirection = Enum.FillDirection.Horizontal;
segList.Padding = UDim.new(0, 12);
segList.HorizontalAlignment = Enum.HorizontalAlignment.Center;
segList.VerticalAlignment = Enum.VerticalAlignment.Center;
segList.Parent = btnHolder;
local function segButton(txt)
	local b = Instance.new("TextButton");
	b.AutoButtonColor = false;
	b.Size = UDim2.new(0, 114, 1, 0);
	b.BackgroundTransparency = 1;
	b.Text = txt;
	b.Font = Enum.Font.GothamMedium;
	b.TextSize = 13;
	b.TextColor3 = Color3.fromRGB(220, 220, 235);
	b.Parent = btnHolder;
	return b;
end;
local enterBtn = segButton("Enter");
local allBtn = segButton("All");
local selectedModeBtn = enterBtn;
local function moveModeSelector(toBtn, animate)
	selectedModeBtn = toBtn;
	local relX = toBtn.AbsolutePosition.X - seg.AbsolutePosition.X;
	local w = toBtn.AbsoluteSize.X;
	if animate then
		(TweenService:Create(selector, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, relX, 0, 0),
			Size = UDim2.new(0, w, 1, 0)
		})):Play();
	else
		selector.Position = UDim2.new(0, relX, 0, 0);
		selector.Size = UDim2.new(0, w, 1, 0);
	end;
	for _, b in ipairs({
		enterBtn,
		allBtn
	}) do
		(TweenService:Create(b, TweenInfo.new(0.12), {
			TextColor3 = b == toBtn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(220, 220, 235)
		})):Play();
	end;
end;
task.defer(function()
	moveModeSelector(enterBtn, false);
end);
RunService.RenderStepped:Connect(function()
	if selectedModeBtn and selector.Parent == seg then
		selector.Position = UDim2.new(0, selectedModeBtn.AbsolutePosition.X - seg.AbsolutePosition.X, 0, 0);
		selector.Size = UDim2.new(0, selectedModeBtn.AbsoluteSize.X, 1, 0);
	end;
end);
enterBtn.MouseButton1Click:Connect(function()
	ripple(seg);
	mode = "Enter";
	modeId += 1;
	loops = {};
	allLoopActive = false;
	moveModeSelector(enterBtn, true);
end);
allBtn.MouseButton1Click:Connect(function()
	ripple(seg);
	mode = "All";
	modeId += 1;
	loops = {};
	moveModeSelector(allBtn, true);
end);
local minimized = false;
local dockButton = Instance.new("ImageButton");
dockButton.Visible = false;
dockButton.AnchorPoint = Vector2.new(0.5, 0.5);
dockButton.Size = UDim2.new(0, 56, 0, 56);
dockButton.Position = container.Position;
dockButton.BackgroundTransparency = 1;
dockButton.Image = "rbxassetid://1095708";
dockButton.ImageTransparency = 1;
dockButton.ZIndex = 5;
dockButton.Parent = screenGui;
local miniCircle = Instance.new("Frame");
miniCircle.Size = UDim2.new(0, 56, 0, 56);
miniCircle.AnchorPoint = Vector2.new(0.5, 0.5);
miniCircle.Position = UDim2.fromScale(0.5, 0.5);
miniCircle.BackgroundColor3 = Color3.fromRGB(86, 142, 255);
miniCircle.Parent = dockButton;
local miniCorner = Instance.new("UICorner");
miniCorner.CornerRadius = UDim.new(1, 0);
miniCorner.Parent = miniCircle;
local miniStroke = Instance.new("UIStroke");
miniStroke.Color = Color3.fromRGB(86, 142, 255);
miniStroke.Transparency = 0;
miniStroke.Parent = miniCircle;
table.insert(rgbStrokes, miniStroke);
local miniText = Instance.new("TextLabel");
miniText.BackgroundTransparency = 1;
miniText.Size = UDim2.new(1, 0, 1, 0);
miniText.Text = "69";
miniText.Font = Enum.Font.GothamBold;
miniText.TextSize = 18;
miniText.TextColor3 = Color3.fromRGB(255, 255, 255);
miniText.Parent = miniCircle;
local chevron = button("Minimize", header, 98, 32);
chevron.AnchorPoint = Vector2.new(1, 0.5);
chevron.Position = UDim2.new(1, 0, 0.5, 0);
local function minimizeToCircle()
	minimized = true;
	dockButton.Position = container.Position;
	dockButton.Visible = true;
	dockButton.ImageTransparency = 1;
	(TweenService:Create(panel, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1
	})):Play();
	(TweenService:Create(panelShadow, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		ImageTransparency = 1
	})):Play();
	(TweenService:Create(container, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 64, 0, 64)
	})):Play();
	task.delay(0.22, function()
		panel.Visible = false;
		panelShadow.Visible = false;
		(TweenService:Create(miniCircle, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 56, 0, 56)
		})):Play();
		(TweenService:Create(dockButton, TweenInfo.new(0.24), {
			ImageTransparency = 0.5
		})):Play();
	end);
end;
local function restoreFromCircle()
	minimized = false;
	panel.Visible = true;
	panelShadow.Visible = true;
	container.Position = dockButton.Position;
	(TweenService:Create(dockButton, TweenInfo.new(0.16), {
		ImageTransparency = 1
	})):Play();
	(TweenService:Create(container, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 520, 0, 380)
	})):Play();
	(TweenService:Create(panel, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.04
	})):Play();
	(TweenService:Create(panelShadow, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		ImageTransparency = 0.5
	})):Play();
	task.delay(0.26, function()
		dockButton.Visible = false;
	end);
end;
chevron.MouseButton1Click:Connect(minimizeToCircle);
dockButton.MouseButton1Click:Connect(restoreFromCircle);
do
	local dragging = false;
	local dragInput;
	local dragStart;
	local startPos;
	header.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true;
			dragStart = inp.Position;
			startPos = container.Position;
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then
					dragging = false;
				end;
			end);
		end;
	end);
	header.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
			dragInput = inp;
		end;
	end);
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp == dragInput then
			local delta = inp.Position - dragStart;
			local target = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y);
			(TweenService:Create(container, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = target
			})):Play();
			if minimized then
				dockButton.Position = target;
			end;
		end;
	end);
end;
do
	local dragging = false;
	local dragInput;
	local dragStart;
	local startPos;
	dockButton.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true;
			dragStart = inp.Position;
			startPos = dockButton.Position;
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then
					dragging = false;
				end;
			end);
		end;
	end);
	dockButton.InputChanged:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
			dragInput = inp;
		end;
	end);
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp == dragInput then
			local delta = inp.Position - dragStart;
			dockButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y);
		end;
	end);
end;
panel.BackgroundTransparency = 1;
panelShadow.ImageTransparency = 1;
container.Size = UDim2.new(0, 500, 0, 360);
(TweenService:Create(panel, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	BackgroundTransparency = 0.04
})):Play();
(TweenService:Create(panelShadow, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
	ImageTransparency = 0.5
})):Play();
(TweenService:Create(container, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, 520, 0, 380)
})):Play();
local hue = 0;
RunService.RenderStepped:Connect(function(dt)
	hue = (hue + dt * 0.25) % 1;
	local c = Color3.fromHSV(hue, 0.8, 1);
	for i = #rgbStrokes, 1, -1 do
		local st = rgbStrokes[i];
		if st and st.Parent then
			st.Color = c;
		else
			table.remove(rgbStrokes, i);
		end;
	end;
end);
RunService.RenderStepped:Connect(function()
	if rootPart and aura then
		aura.CFrame = rootPart.CFrame;
	end;
end);
local function validTarget(p)
	if not rootPart then
		return false;
	end;
	if not p or p == localPlayer then
		return false;
	end;
	if ignoreFriends and isFriend(p.UserId) then
		return false;
	end;
	if not p.Character then
		return false;
	end;
	local rp = getRootPart(p.Character);
	if not rp then
		return false;
	end;
	local otherInArena = playersData[p] and playersData[p].inArena;
	local withinLobby = (rp.Position - rootPart.Position).Magnitude <= radius;
	return otherInArena or withinLobby;
end;
local tempList = {};
local function inRangePlayers(out)
	local n = 0;
	for i = 1, #trackedPlayers do
		local p = trackedPlayers[i];
		if validTarget(p) then
			n += 1;
			out[n] = p;
		end;
	end;
	for i = n + 1, #out do
		out[i] = nil;
	end;
	return n;
end;
local function fireOnPlayer(p)
	local ch = p and p.Character;
	local tp = ch and getRootPart(ch);
	if not tp then
		return;
	end;
	for i = 1, #attackRemotes do
		attackRemotes[i]:FireServer(tp);
	end;
end;
ghostBtn.MouseButton1Click:Connect(function()
	local stats = localPlayer:FindFirstChild("leaderstats");
	local slaps = stats and stats:FindFirstChild("Slaps");
	if slaps and slaps.Value >= 666 then
		local cd;
		local lobby = workspace:FindFirstChild("Lobby");
		local ghost = lobby and lobby:FindFirstChild("Ghost");
		cd = ghost and ghost:FindFirstChildOfClass("ClickDetector");
		if cd then
			pcall(function()
				fireclickdetector(cd);
			end);
		end;
		ghostRemote:FireServer();
		showToast("Ghost activated");
	else
		showToast("Requires 666 slaps");
	end;
end);
auraToggle.Button.MouseButton1Click:Connect(function()
	auraEnabled = not auraEnabled;
	modeId += 1;
	loops = {};
	allLoopActive = false;
	if auraEnabled then
		if rootPart then
			createAura();
		end;
	elseif aura then
		aura:Destroy();
	end;
end);
ignoreToggle.Button.MouseButton1Click:Connect(function()
	ignoreFriends = not ignoreFriends;
end);
local accumulator, checkInterval = 0, 0.1;
RunService.Heartbeat:Connect(function(dt)
	accumulator += dt;
	if accumulator < checkInterval or (not rootPart) then
		return;
	end;
	accumulator = 0;
	radius = math.clamp(radiusSlider.Get(), 0, 20);
	delay = math.clamp(delaySlider.Get(), 0, 3);
	if auraEnabled and aura then
		local goal = Vector3.new(radius * 2, radius * 2, radius * 2);
		if (aura.Size - goal).Magnitude > 0.01 then
			(TweenService:Create(aura, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = goal
			})):Play();
		end;
	end;
	if not auraEnabled then
		return;
	end;
	if mode == "Enter" then
		for i = 1, #trackedPlayers do
			local other = trackedPlayers[i];
			if validTarget(other) then
				if not loops[other] then
					loops[other] = true;
					local myId = modeId;
					task.spawn(function()
						while loops[other] and auraEnabled and mode == "Enter" and modeId == myId do
							if not validTarget(other) then
								break;
							end;
							fireOnPlayer(other);
							task.wait(delay);
						end;
						loops[other] = nil;
					end);
				end;
			else
				loops[other] = nil;
			end;
		end;
	else
		for k, _ in pairs(loops) do
			loops[k] = nil;
		end;
		if not allLoopActive then
			local myId = modeId;
			allLoopActive = true;
			task.spawn(function()
				while auraEnabled and mode == "All" and modeId == myId do
					local count = inRangePlayers(tempList);
					for i = 1, count do
						fireOnPlayer(tempList[i]);
					end;
					task.wait(delay);
				end;
				allLoopActive = false;
			end);
		end;
	end;
end);
