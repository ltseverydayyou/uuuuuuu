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
local __NAUIProtector = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {};
	local sharedEnv = rawget(_G, "shared");
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil);
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_ui_protector");
		if type(cached) == "table" then
			return cached;
		end;
	end;
	local loader = loadstring or load;
	if type(loader) ~= "function" then
		return nil;
	end;
	local okSource, source = pcall(function()
		return game:HttpGet("https://ltseverydayyou.github.io/UIprotector.luau");
	end);
	if not okSource or type(source) ~= "string" or source == "" then
		return nil;
	end;
	local chunk = loader(source, "@UIprotector.luau");
	if type(chunk) ~= "function" then
		return nil;
	end;
	local okLoaded, loaded = pcall(chunk);
	if okLoaded and type(loaded) == "table" then
		if cacheHost then
			cacheHost.__lt_ui_protector = loaded;
		end;
		return loaded;
	end;
	return nil;
end)();
local function __NAProtectUI(gui, options)
	if __NAUIProtector and type(__NAUIProtector.protectUI) == "function" then
		local ok, protected = pcall(__NAUIProtector.protectUI, gui, options);
		if ok and protected then
			return protected;
		end;
	end;
	return nil;
end;

local P = __lt.cs("Players", cloneref);
local T = __lt.cs("TweenService", cloneref);
local M = __lt.cs("MarketplaceService", cloneref);
local U = __lt.cs("UserInputService", cloneref);
local R = __lt.cs("RunService", cloneref);
local pl = P.LocalPlayer;
local pg = pl:WaitForChild("PlayerGui");
local sg = Instance.new("ScreenGui");
sg.ResetOnSpawn = false;
sg.IgnoreGuiInset = true;
sg.ZIndexBehavior = Enum.ZIndexBehavior.Global;
sg.DisplayOrder = 1000;
if not __NAProtectUI(sg, { keepName = false }) then
	sg.Parent = pg;
end;
local cons, alive = {}, true;
local function on(sig, fn)
	if not alive or not sig then
		return nil;
	end;
	local c = sig:Connect(fn);
	cons[#cons + 1] = c;
	return c;
end;
local function off()
	for i = 1, #cons do
		local c = cons[i];
		if c then
			pcall(function()
				c:Disconnect();
			end);
			cons[i] = nil;
		end;
	end;
end;
local function gone()
	return not alive or not sg or sg.Parent == nil;
end;
local function setProps(inst, props)
	for key, value in props do
		inst[key] = value;
	end;
	return inst;
end;
local function make(className, parent, props)
	local inst = Instance.new(className);
	if props then
		setProps(inst, props);
	end;
	inst.Parent = parent;
	return inst;
end;
local function corner(parent, radius)
	local c = make("UICorner", parent, {});
	c.CornerRadius = UDim.new(0, radius or 6);
	return c;
end;
local function stroke(parent, transparency)
	local s = make("UIStroke", parent, {});
	s.Thickness = 1;
	s.Color = Color3.fromRGB(90, 90, 90);
	s.Transparency = transparency or 0.35;
	return s;
end;

local function fitButtonText(button, maxSize)
	if typeof(button) ~= "Instance" or not button:IsA("TextButton") then
		return button;
	end;
	button.TextScaled = true;
	button.TextWrapped = false;
	button.TextTruncate = Enum.TextTruncate.AtEnd;
	local limit = make("UITextSizeConstraint", button, {});
	limit.MinTextSize = 9;
	limit.MaxTextSize = maxSize or 14;
	return button;
end;
local function tween(inst, info, props)
	local ok, tw = pcall(function()
		return T:Create(inst, info, props);
	end);
	if ok and tw then
		tw:Play();
	end;
	return tw;
end;

local function NAdrag(ui, dragui)
	dragui = dragui or ui;
	local dragging, dragInput, dragStart, startPos;
	local function update(input)
		local parent = ui.Parent;
		if not parent then
			return;
		end;
		local delta = input.Position - dragStart;
		local newXOffset = startPos.X.Offset + delta.X;
		local newYOffset = startPos.Y.Offset + delta.Y;
		local sz = parent.AbsoluteSize;
		local newXScale = startPos.X.Scale + newXOffset / math.max(sz.X, 1);
		local newYScale = startPos.Y.Scale + newYOffset / math.max(sz.Y, 1);
		ui.Position = UDim2.new(newXScale, 0, newYScale, 0);
	end;
	on(dragui.InputBegan, function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true;
			dragStart = i.Position;
			startPos = ui.Position;
			on(i.Changed, function()
				if i.UserInputState == Enum.UserInputState.End then
					dragging = false;
				end;
			end);
		end;
	end);
	on(dragui.InputChanged, function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
			dragInput = i;
		end;
	end);
	on(U.InputChanged, function(i)
		if dragging and i == dragInput then
			update(i);
		end;
	end);
	ui.Active = true;
end;

local main = make("Frame", sg, {
	AnchorPoint = Vector2.new(0.5, 0);
	Position = UDim2.new(0.5, 0, 0.025, 0);
	Size = UDim2.new(0, 660, 0, 455);
	BackgroundColor3 = Color3.fromRGB(23, 23, 23);
	BorderSizePixel = 0;
});
corner(main, 10);
stroke(main, 0.25);

local header = make("Frame", main, {
	Size = UDim2.new(1, 0, 0, 40);
	BackgroundColor3 = Color3.fromRGB(30, 30, 30);
	BorderSizePixel = 0;
});
corner(header, 10);
local title = make("TextLabel", header, {
	Size = UDim2.new(1, -130, 1, 0);
	Position = UDim2.new(0, 14, 0, 0);
	BackgroundTransparency = 1;
	Font = Enum.Font.SourceSansBold;
	Text = "AnimPlayer Rework";
	TextColor3 = Color3.fromRGB(245, 245, 245);
	TextSize = 20;
	TextXAlignment = Enum.TextXAlignment.Left;
});
local refreshBtn = make("TextButton", header, {
	Size = UDim2.new(0, 62, 0, 26);
	Position = UDim2.new(1, -96, 0, 7);
	BackgroundColor3 = Color3.fromRGB(55, 55, 55);
	BorderSizePixel = 0;
	AutoButtonColor = true;
	Font = Enum.Font.SourceSansBold;
	Text = "Refresh";
	TextColor3 = Color3.new(1, 1, 1);
	TextSize = 14;
});
corner(refreshBtn, 6);
fitButtonText(refreshBtn, 14);
local closeBtn = make("TextButton", header, {
	Size = UDim2.new(0, 26, 0, 26);
	Position = UDim2.new(1, -30, 0, 7);
	BackgroundColor3 = Color3.fromRGB(65, 45, 45);
	BorderSizePixel = 0;
	AutoButtonColor = true;
	Font = Enum.Font.SourceSansBold;
	Text = "X";
	TextColor3 = Color3.new(1, 1, 1);
	TextSize = 16;
});
corner(closeBtn, 6);
fitButtonText(closeBtn, 16);

local tabs = make("Frame", main, {
	Position = UDim2.new(0, 10, 0, 48);
	Size = UDim2.new(1, -20, 0, 31);
	BackgroundTransparency = 1;
});
local tabLayout = make("UIListLayout", tabs, {});
tabLayout.FillDirection = Enum.FillDirection.Horizontal;
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder;
tabLayout.Padding = UDim.new(0, 5);

local left = make("Frame", main, {
	Position = UDim2.new(0, 10, 0, 88);
	Size = UDim2.new(0, 288, 1, -118);
	BackgroundColor3 = Color3.fromRGB(18, 18, 18);
	BorderSizePixel = 0;
});
corner(left, 8);
stroke(left, 0.55);

local search = make("TextBox", left, {
	Position = UDim2.new(0, 8, 0, 8);
	Size = UDim2.new(1, -16, 0, 28);
	BackgroundColor3 = Color3.fromRGB(35, 35, 35);
	BorderSizePixel = 0;
	ClearTextOnFocus = false;
	Font = Enum.Font.SourceSans;
	PlaceholderText = "Search animations / IDs / paths";
	Text = "";
	TextColor3 = Color3.fromRGB(245, 245, 245);
	PlaceholderColor3 = Color3.fromRGB(155, 155, 155);
	TextSize = 15;
	TextXAlignment = Enum.TextXAlignment.Left;
});
corner(search, 6);

local countLabel = make("TextLabel", left, {
	Position = UDim2.new(0, 8, 0, 40);
	Size = UDim2.new(1, -16, 0, 20);
	BackgroundTransparency = 1;
	Font = Enum.Font.SourceSans;
	Text = "Scanning...";
	TextColor3 = Color3.fromRGB(190, 190, 190);
	TextSize = 14;
	TextXAlignment = Enum.TextXAlignment.Left;
});

local list = make("ScrollingFrame", left, {
	Position = UDim2.new(0, 8, 0, 64);
	Size = UDim2.new(1, -16, 1, -72);
	BackgroundTransparency = 1;
	BorderSizePixel = 0;
	ScrollBarThickness = 5;
	CanvasSize = UDim2.new(0, 0, 0, 0);
});
local listLayout = make("UIListLayout", list, {});
listLayout.SortOrder = Enum.SortOrder.LayoutOrder;
listLayout.Padding = UDim.new(0, 5);
on(listLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
	if gone() then
		return;
	end;
	list.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4);
end);

local right = make("Frame", main, {
	Position = UDim2.new(0, 306, 0, 88);
	Size = UDim2.new(1, -316, 1, -118);
	BackgroundColor3 = Color3.fromRGB(18, 18, 18);
	BorderSizePixel = 0;
});
corner(right, 8);
stroke(right, 0.55);

local selectedTitle = make("TextLabel", right, {
	Position = UDim2.new(0, 10, 0, 6);
	Size = UDim2.new(1, -20, 0, 22);
	BackgroundTransparency = 1;
	Font = Enum.Font.SourceSansBold;
	Text = "No animation selected";
	TextColor3 = Color3.fromRGB(245, 245, 245);
	TextSize = 17;
	TextXAlignment = Enum.TextXAlignment.Left;
	TextTruncate = Enum.TextTruncate.AtEnd;
});
local selectedMeta = make("TextLabel", right, {
	Position = UDim2.new(0, 10, 0, 29);
	Size = UDim2.new(1, -20, 0, 42);
	BackgroundTransparency = 1;
	Font = Enum.Font.SourceSans;
	Text = "Pick an animation from the left.";
	TextColor3 = Color3.fromRGB(190, 190, 190);
	TextSize = 12;
	TextWrapped = true;
	TextXAlignment = Enum.TextXAlignment.Left;
	TextYAlignment = Enum.TextYAlignment.Top;
});

local btnRow = make("Frame", right, {
	Position = UDim2.new(0, 10, 0, 76);
	Size = UDim2.new(1, -20, 0, 30);
	BackgroundTransparency = 1;
});
local btnLayout = make("UIListLayout", btnRow, {});
btnLayout.FillDirection = Enum.FillDirection.Horizontal;
btnLayout.SortOrder = Enum.SortOrder.LayoutOrder;
btnLayout.Padding = UDim.new(0, 6);
local function smallButton(parent, text, width)
	local b = make("TextButton", parent, {
		Size = UDim2.new(0, width, 1, 0);
		BackgroundColor3 = Color3.fromRGB(54, 54, 54);
		BorderSizePixel = 0;
		AutoButtonColor = true;
		Font = Enum.Font.SourceSansBold;
		Text = text;
		TextColor3 = Color3.new(1, 1, 1);
		TextSize = 14;
	});
	corner(b, 6);
	fitButtonText(b, 14);
	return b;
end;
local playBtn = smallButton(btnRow, "Play", 58);
local stopBtn = smallButton(btnRow, "Stop", 58);
local stopAllBtn = smallButton(btnRow, "Stop All", 74);
local copyBtn = smallButton(btnRow, "Copy ID", 74);

local controls = make("Frame", right, {
	Position = UDim2.new(0, 10, 0, 114);
	Size = UDim2.new(1, -20, 0, 132);
	BackgroundTransparency = 1;
});
local controlY = 0;

local cfg = {
	speed = 1;
	weight = 1;
	point = 0;
	loopStart = 0;
	loopEnd = 100;
	trackLoop = false;
	sectionLoop = false;
	overlay = false;
	autoStop = true;
	priorityIndex = 4;
};

local controlApis = {};
local cur, sel = nil, nil;
local scanToken = 0;
local entries, idSet = {}, {};
local activeTab = "all";
local categoryNames = {
	all = "All";
	character = "Character";
	playing = "Playing";
	npc = "NPC/Rig";
	workspace = "Workspace";
	ids = "IDs";
	game = "Game";
};

local function fmtNum(value)
	local rounded = math.floor(value * 100 + 0.5) / 100;
	local text = tostring(rounded);
	return text;
end;

local function clampStep(value, minValue, maxValue, step)
	local n = tonumber(value) or minValue;
	local s = tonumber(step) or 1;
	n = math.floor((n / s) + 0.5) * s;
	return math.clamp(n, minValue, maxValue);
end;

local function applyTrackOptions()
	if not cur then
		return;
	end;
	pcall(function()
		cur.Looped = cfg.trackLoop;
	end);
	pcall(function()
		cur:AdjustSpeed(cfg.speed);
	end);
	pcall(function()
		cur:AdjustWeight(cfg.weight, 0.05);
	end);
end;

local function seekTrackToPercent(percent)
	if not cur then
		return;
	end;
	pcall(function()
		local len = tonumber(cur.Length) or 0;
		if len > 0 then
			cur.TimePosition = math.clamp(percent, 0, 100) / 100 * len;
		end;
	end);
end;

local function numberControl(labelText, field, minValue, maxValue, step, suffix)
	local row = make("Frame", controls, {
		Position = UDim2.new(0, 0, 0, controlY);
		Size = UDim2.new(1, 0, 0, 24);
		BackgroundTransparency = 1;
	});
	controlY += 26;
	local label = make("TextLabel", row, {
		Size = UDim2.new(0, 84, 1, 0);
		BackgroundTransparency = 1;
		Font = Enum.Font.SourceSans;
		Text = labelText;
		TextColor3 = Color3.fromRGB(230, 230, 230);
		TextSize = 14;
		TextXAlignment = Enum.TextXAlignment.Left;
	});
	local minus = smallButton(row, "-", 24);
	minus.Position = UDim2.new(0, 90, 0, 0);
	local valueBox = make("TextBox", row, {
		Position = UDim2.new(0, 120, 0, 0);
		Size = UDim2.new(0, 66, 1, 0);
		BackgroundColor3 = Color3.fromRGB(35, 35, 35);
		BorderSizePixel = 0;
		ClearTextOnFocus = false;
		Font = Enum.Font.SourceSansBold;
		Text = fmtNum(cfg[field]) .. (suffix or "");
		TextColor3 = Color3.new(1, 1, 1);
		TextSize = 14;
		TextXAlignment = Enum.TextXAlignment.Center;
	});
	corner(valueBox, 6);
	local plus = smallButton(row, "+", 24);
	plus.Position = UDim2.new(0, 192, 0, 0);
	local api = {};
	function api:Set(value)
		cfg[field] = clampStep(value, minValue, maxValue, step);
		valueBox.Text = fmtNum(cfg[field]) .. (suffix or "");
		if field == "point" then
			seekTrackToPercent(cfg.point);
		elseif field == "loopStart" then
			if cfg.loopStart > cfg.loopEnd then
				cfg.loopEnd = cfg.loopStart;
				if controlApis.loopEnd then
					controlApis.loopEnd:Refresh();
				end;
			end;
		elseif field == "loopEnd" then
			if cfg.loopEnd < cfg.loopStart then
				cfg.loopStart = cfg.loopEnd;
				if controlApis.loopStart then
					controlApis.loopStart:Refresh();
				end;
			end;
		else
			applyTrackOptions();
		end;
	end;
	function api:Refresh()
		valueBox.Text = fmtNum(cfg[field]) .. (suffix or "");
	end;
	on(minus.MouseButton1Click, function()
		api:Set(cfg[field] - step);
	end);
	on(plus.MouseButton1Click, function()
		api:Set(cfg[field] + step);
	end);
	on(valueBox.FocusLost, function()
		local text = valueBox.Text:gsub("%%", "");
		api:Set(tonumber(text) or cfg[field]);
	end);
	controlApis[field] = api;
	return api;
end;

numberControl("Speed", "speed", 0, 6, 0.1, "");
numberControl("Weight", "weight", 0, 5, 0.1, "");
numberControl("Point", "point", 0, 100, 1, "%");
numberControl("Loop Start", "loopStart", 0, 100, 1, "%");
numberControl("Loop End", "loopEnd", 0, 100, 1, "%");

local toggles = make("Frame", right, {
	Position = UDim2.new(0, 10, 0, 244);
	Size = UDim2.new(1, -20, 0, 62);
	BackgroundTransparency = 1;
});
local toggleLayout = make("UIGridLayout", toggles, {});
toggleLayout.CellSize = UDim2.new(0.5, -4, 0, 28);
toggleLayout.CellPadding = UDim2.new(0, 8, 0, 6);
toggleLayout.SortOrder = Enum.SortOrder.LayoutOrder;
local function toggleButton(text, field)
	local b = make("TextButton", toggles, {
		BackgroundColor3 = Color3.fromRGB(50, 50, 50);
		BorderSizePixel = 0;
		AutoButtonColor = true;
		Font = Enum.Font.SourceSansBold;
		TextColor3 = Color3.new(1, 1, 1);
		TextSize = 13;
	});
	corner(b, 6);
	local function refresh()
		local onValue = cfg[field] == true;
		b.Text = text .. ": " .. (onValue and "ON" or "OFF");
		b.BackgroundColor3 = onValue and Color3.fromRGB(45, 85, 55) or Color3.fromRGB(50, 50, 50);
	end;
	on(b.MouseButton1Click, function()
		cfg[field] = not cfg[field];
		refresh();
		applyTrackOptions();
	end);
	fitButtonText(b, 13);
	refresh();
	return b;
end;
toggleButton("Track Loop", "trackLoop");
toggleButton("Section Loop", "sectionLoop");
toggleButton("Overlay", "overlay");
toggleButton("Auto Stop", "autoStop");

local priorityList = {};
for _, priorityName in { "Core", "Idle", "Movement", "Action", "Action2", "Action3", "Action4" } do
	local ok, priorityValue = pcall(function()
		return Enum.AnimationPriority[priorityName];
	end);
	if ok and priorityValue then
		priorityList[#priorityList + 1] = {
			name = priorityName;
			value = priorityValue;
		};
	end;
end;
if #priorityList == 0 then
	priorityList[1] = {
		name = "Action";
		value = Enum.AnimationPriority.Action;
	};
end;
cfg.priorityIndex = math.clamp(cfg.priorityIndex, 1, #priorityList);
local priorityBtn = make("TextButton", right, {
	Position = UDim2.new(0, 10, 0, 308);
	Size = UDim2.new(1, -20, 0, 28);
	BackgroundColor3 = Color3.fromRGB(48, 48, 48);
	BorderSizePixel = 0;
	AutoButtonColor = true;
	Font = Enum.Font.SourceSansBold;
	TextColor3 = Color3.new(1, 1, 1);
	TextSize = 14;
});
corner(priorityBtn, 6);
fitButtonText(priorityBtn, 14);
local function refreshPriority()
	local rec = priorityList[cfg.priorityIndex] or priorityList[1];
	priorityBtn.Text = "Priority: " .. rec.name;
	if cur then
		pcall(function()
			cur.Priority = rec.value;
		end);
	end;
end;
on(priorityBtn.MouseButton1Click, function()
	cfg.priorityIndex += 1;
	if cfg.priorityIndex > #priorityList then
		cfg.priorityIndex = 1;
	end;
	refreshPriority();
end);
refreshPriority();

local status = make("TextLabel", main, {
	Position = UDim2.new(0, 10, 1, -22);
	Size = UDim2.new(1, -20, 0, 18);
	BackgroundTransparency = 1;
	Font = Enum.Font.SourceSans;
	Text = "Ready.";
	TextColor3 = Color3.fromRGB(170, 170, 170);
	TextSize = 13;
	TextXAlignment = Enum.TextXAlignment.Left;
});

NAdrag(main, header);

local function copyText(text)
	if type(setclipboard) == "function" then
		pcall(setclipboard, text);
	end;
	if syn and type(syn.set_clipboard) == "function" then
		pcall(syn.set_clipboard, text);
	end;
end;

local function animationIdOf(value)
	if typeof(value) == "Instance" and value:IsA("Animation") then
		local found = tostring(value.AnimationId or ""):match("%d+");
		return found and tonumber(found) or nil;
	end;
	if type(value) == "string" then
		local found = value:match("%d+");
		return found and tonumber(found) or nil;
	end;
	if type(value) == "number" then
		local fixed = math.floor(value + 0.5);
		if fixed > 0 then
			return fixed;
		end;
	end;
	return nil;
end;

local function pathOf(inst)
	if typeof(inst) ~= "Instance" then
		return "runtime";
	end;
	local stack = {};
	local current = inst;
	while current and current ~= game do
		stack[#stack + 1] = current.Name;
		current = current.Parent;
	end;
	local out = {};
	for i = #stack, 1, -1 do
		out[#out + 1] = stack[i];
	end;
	return table.concat(out, ".");
end;

local function query(root, className)
	if typeof(root) ~= "Instance" or type(root.QueryDescendants) ~= "function" then
		return {};
	end;
	local ok, results = pcall(function()
		return root:QueryDescendants(className);
	end);
	if ok and type(results) == "table" then
		return results;
	end;
	return {};
end;

local function getCharacter()
	return pl.Character;
end;
local function getHumanoid()
	local char = getCharacter();
	return char and char:FindFirstChildOfClass("Humanoid") or nil;
end;
local function getAnimator()
	local hum = getHumanoid();
	if not hum then
		return nil, nil;
	end;
	local animator = hum:FindFirstChildOfClass("Animator");
	if not animator then
		animator = Instance.new("Animator");
		animator.Parent = hum;
	end;
	return animator, hum;
end;

local function isRigModel(model)
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return false;
	end;
	if model:FindFirstChildOfClass("Humanoid") then
		return true;
	end;
	if model:FindFirstChildOfClass("AnimationController") then
		return true;
	end;
	if model:FindFirstChildOfClass("Animator") then
		return true;
	end;
	return false;
end;
local function findRig(inst)
	local current = typeof(inst) == "Instance" and inst.Parent or nil;
	while current and current ~= game do
		if isRigModel(current) then
			return current;
		end;
		current = current.Parent;
	end;
	return nil;
end;
local function categoryFor(inst, idOnly)
	local char = getCharacter();
	if char and typeof(inst) == "Instance" and inst:IsDescendantOf(char) then
		return "character";
	end;
	local rig = findRig(inst);
	if rig and rig ~= char then
		return "npc";
	end;
	if idOnly then
		return "ids";
	end;
	if typeof(inst) == "Instance" and inst:IsDescendantOf(workspace) then
		return "workspace";
	end;
	return "game";
end;

local function makeAnimation(aid, name)
	local anim = Instance.new("Animation");
	anim.Name = name or ("Animation " .. tostring(aid));
	anim.AnimationId = "rbxassetid://" .. tostring(aid);
	return anim;
end;

local function addEntry(category, aid, name, anim, source, kind)
	aid = animationIdOf(aid);
	if not aid then
		return nil;
	end;
	local key = category .. ":" .. tostring(aid);
	if idSet[key] then
		return nil;
	end;
	idSet[key] = true;
	local entry = {
		category = category;
		aid = aid;
		name = type(name) == "string" and name ~= "" and name or ("Animation " .. tostring(aid));
		anim = typeof(anim) == "Instance" and anim:IsA("Animation") and anim or makeAnimation(aid, name);
		source = source or "runtime";
		kind = kind or "Animation";
	};
	entries[#entries + 1] = entry;
	return entry;
end;

local function stopCurrent()
	if cur then
		pcall(function()
			cur:Stop(0.1);
		end);
		cur = nil;
	end;
end;
local function stopAllTracks()
	local hum = getHumanoid();
	if hum then
		local tracks = hum:GetPlayingAnimationTracks();
		for _, track in tracks do
			pcall(function()
				track:Stop(0.1);
			end);
		end;
	end;
	cur = nil;
end;

local humanoidWatch = nil;
local function clearHumanoidWatch()
	if humanoidWatch then
		for i = 1, #humanoidWatch do
			local c = humanoidWatch[i];
			if c then
				pcall(function()
					c:Disconnect();
				end);
			end;
			humanoidWatch[i] = nil;
		end;
	end;
	humanoidWatch = {};
end;
local function watchHumanoid(hum)
	clearHumanoidWatch();
	if not hum then
		return;
	end;
	local function stopForMovement()
		if cfg.autoStop and not cfg.overlay then
			stopCurrent();
		end;
	end;
	humanoidWatch[#humanoidWatch + 1] = hum.Running:Connect(function(speed)
		if speed > 0 then
			stopForMovement();
		end;
	end);
	humanoidWatch[#humanoidWatch + 1] = hum.Jumping:Connect(stopForMovement);
	humanoidWatch[#humanoidWatch + 1] = hum.StateChanged:Connect(function(_, state)
		if state == Enum.HumanoidStateType.Climbing or state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Swimming then
			stopForMovement();
		end;
	end);
end;
if pl.Character then
	watchHumanoid(pl.Character:FindFirstChildOfClass("Humanoid") or pl.Character:WaitForChild("Humanoid", 5));
end;
on(pl.CharacterAdded, function(char)
	watchHumanoid(char:WaitForChild("Humanoid", 5));
end);

local tabButtons = {};
local function setStatus(text)
	if status and status.Parent then
		status.Text = text;
	end;
end;
local function updateSelected()
	if not sel then
		selectedTitle.Text = "No animation selected";
		selectedMeta.Text = "Pick an animation from the left.";
		return;
	end;
	selectedTitle.Text = sel.name;
	selectedMeta.Text = "[" .. (categoryNames[sel.category] or sel.category) .. "] " .. tostring(sel.aid) .. "\n" .. tostring(sel.source);
end;
local function clearRows()
	local children = list:GetChildren();
	for _, child in children do
		if child ~= listLayout then
			child:Destroy();
		end;
	end;
end;
local function refreshTabs()
	for id, btn in tabButtons do
		local isActive = id == activeTab;
		btn.BackgroundColor3 = isActive and Color3.fromRGB(70, 92, 135) or Color3.fromRGB(48, 48, 48);
	end;
end;

local function entryMatches(entry, queryText)
	if activeTab ~= "all" and entry.category ~= activeTab then
		return false;
	end;
	if queryText == "" then
		return true;
	end;
	local hay = (entry.name .. " " .. tostring(entry.aid) .. " " .. tostring(entry.source) .. " " .. (categoryNames[entry.category] or entry.category)):lower();
	return hay:find(queryText, 1, true) ~= nil;
end;
local function rebuildList()
	if gone() then
		return;
	end;
	clearRows();
	local queryText = tostring(search.Text or ""):lower();
	local shown = 0;
	for i = 1, #entries do
		local entry = entries[i];
		if entryMatches(entry, queryText) then
			shown += 1;
			local row = make("TextButton", list, {
				Name = "AnimRow" .. tostring(shown);
				Size = UDim2.new(1, -4, 0, 48);
				BackgroundColor3 = Color3.fromRGB(38, 38, 38);
				BorderSizePixel = 0;
				AutoButtonColor = true;
				Font = Enum.Font.SourceSansBold;
				Text = "";
				TextColor3 = Color3.new(1, 1, 1);
				LayoutOrder = shown;
			});
			corner(row, 6);
			make("TextLabel", row, {
				Position = UDim2.new(0, 8, 0, 3);
				Size = UDim2.new(1, -16, 0, 22);
				BackgroundTransparency = 1;
				Font = Enum.Font.SourceSansBold;
				Text = entry.name;
				TextColor3 = Color3.fromRGB(245, 245, 245);
				TextSize = 15;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextTruncate = Enum.TextTruncate.AtEnd;
			});
			make("TextLabel", row, {
				Position = UDim2.new(0, 8, 0, 24);
				Size = UDim2.new(1, -16, 0, 18);
				BackgroundTransparency = 1;
				Font = Enum.Font.SourceSans;
				Text = (categoryNames[entry.category] or entry.category) .. "  •  " .. tostring(entry.aid);
				TextColor3 = Color3.fromRGB(175, 175, 175);
				TextSize = 12;
				TextXAlignment = Enum.TextXAlignment.Left;
				TextTruncate = Enum.TextTruncate.AtEnd;
			});
			on(row.MouseButton1Click, function()
				sel = entry;
				updateSelected();
				setStatus("Selected " .. entry.name);
			end);
		end;
	end;
	countLabel.Text = tostring(shown) .. " shown / " .. tostring(#entries) .. " loaded";
end;

for index, rec in {
	{ id = "all", text = "All", width = 48 };
	{ id = "character", text = "Character", width = 78 };
	{ id = "playing", text = "Playing", width = 66 };
	{ id = "npc", text = "NPC/Rig", width = 64 };
	{ id = "workspace", text = "Workspace", width = 80 };
	{ id = "ids", text = "IDs", width = 42 };
	{ id = "game", text = "Game", width = 50 };
} do
	local b = make("TextButton", tabs, {
		Size = UDim2.new(0, rec.width, 1, 0);
		BackgroundColor3 = Color3.fromRGB(48, 48, 48);
		BorderSizePixel = 0;
		AutoButtonColor = true;
		Font = Enum.Font.SourceSansBold;
		Text = rec.text;
		TextColor3 = Color3.new(1, 1, 1);
		TextSize = 13;
		LayoutOrder = index;
	});
	corner(b, 6);
	fitButtonText(b, 13);
	tabButtons[rec.id] = b;
	on(b.MouseButton1Click, function()
		activeTab = rec.id;
		refreshTabs();
		rebuildList();
	end);
end;
refreshTabs();

local function addPlayingTracks()
	local hum = getHumanoid();
	if not hum then
		return;
	end;
	local tracks = hum:GetPlayingAnimationTracks();
	for _, track in tracks do
		local anim = nil;
		pcall(function()
			anim = track.Animation;
		end);
		local aid = animationIdOf(anim);
		if aid then
			local name = typeof(anim) == "Instance" and anim.Name or tostring(track.Name or "Playing Animation");
			addEntry("playing", aid, name, anim, "Current character track", "Track");
		end;
	end;
end;

local function scanAnimations(token)
	entries = {};
	idSet = {};
	sel = nil;
	updateSelected();
	setStatus("Scanning running tracks...");
	addPlayingTracks();
	if token ~= scanToken or gone() then
		return;
	end;
	local animationList = query(game, "Animation");
	local numberList = query(game, "NumberValue");
	local intList = query(game, "IntValue");
	local total = #animationList + #numberList + #intList;
	local done = 0;
	for _, inst in animationList do
		if token ~= scanToken or gone() then
			return;
		end;
		done += 1;
		local aid = animationIdOf(inst);
		if aid then
			addEntry(categoryFor(inst, false), aid, inst.Name, inst, pathOf(inst), inst.ClassName);
		end;
		if done % 40 == 0 then
			setStatus("Scanning animations... " .. tostring(math.floor(done / math.max(total, 1) * 100)) .. "%");
			task.wait();
		end;
	end;
	local function scanValueList(values, label)
		for _, inst in values do
			if token ~= scanToken or gone() then
				return false;
			end;
			done += 1;
			local aid = animationIdOf(inst.Value);
			if aid and not idSet["ids:" .. tostring(aid)] then
				local ok, info = pcall(function()
					return M:GetProductInfo(aid, Enum.InfoType.Asset);
				end);
				if ok and info and tonumber(info.AssetTypeId) == Enum.AssetType.Animation.Value then
					addEntry("ids", aid, tostring(info.Name or inst.Name), makeAnimation(aid, tostring(info.Name or inst.Name)), pathOf(inst), label);
				end;
			end;
			if done % 20 == 0 then
				setStatus("Checking animation IDs... " .. tostring(math.floor(done / math.max(total, 1) * 100)) .. "%");
				task.wait();
			end;
		end;
		return true;
	end;
	if not scanValueList(numberList, "NumberValue") then
		return;
	end;
	if not scanValueList(intList, "IntValue") then
		return;
	end;
	if token ~= scanToken or gone() then
		return;
	end;
	setStatus("Loaded " .. tostring(#entries) .. " animations.");
	rebuildList();
end;

local function refreshScan()
	scanToken += 1;
	local token = scanToken;
	countLabel.Text = "Scanning...";
	clearRows();
	task.spawn(function()
		scanAnimations(token);
	end);
end;

local function playSelected()
	if not sel then
		setStatus("Select an animation first.");
		return;
	end;
	local animator, hum = getAnimator();
	if not animator or not hum then
		setStatus("No Humanoid/Animator found on your character.");
		return;
	end;
	if not cfg.overlay then
		stopAllTracks();
	else
		stopCurrent();
	end;
	local rec = priorityList[cfg.priorityIndex] or priorityList[1];
	local ok, track = pcall(function()
		return animator:LoadAnimation(sel.anim);
	end);
	if not ok or not track then
		setStatus("Failed to load animation " .. tostring(sel.aid));
		return;
	end;
	cur = track;
	pcall(function()
		cur.Priority = rec.value;
	end);
	pcall(function()
		cur.Looped = cfg.trackLoop;
	end);
	local played = pcall(function()
		cur:Play(0.1, cfg.weight, cfg.speed);
	end);
	if not played then
		pcall(function()
			cur:Play();
		end);
	end;
	applyTrackOptions();
	task.defer(function()
		if cur == track then
			seekTrackToPercent(cfg.point);
		end;
	end);
	setStatus("Playing " .. sel.name .. " at " .. fmtNum(cfg.speed) .. "x / weight " .. fmtNum(cfg.weight));
end;

on(playBtn.MouseButton1Click, playSelected);
on(stopBtn.MouseButton1Click, function()
	stopCurrent();
	setStatus("Stopped current animation.");
end);
on(stopAllBtn.MouseButton1Click, function()
	stopAllTracks();
	setStatus("Stopped all character animations.");
end);
on(copyBtn.MouseButton1Click, function()
	if not sel then
		setStatus("Select an animation first.");
		return;
	end;
	copyText(tostring(sel.aid));
	setStatus("Copied " .. tostring(sel.aid));
end);
on(refreshBtn.MouseButton1Click, refreshScan);
on(search:GetPropertyChangedSignal("Text"), rebuildList);
on(R.Heartbeat, function()
	if gone() then
		return;
	end;
	if not cfg.sectionLoop or not cur then
		return;
	end;
	pcall(function()
		local len = tonumber(cur.Length) or 0;
		if len <= 0 then
			return;
		end;
		local startTime = math.clamp(cfg.loopStart, 0, 100) / 100 * len;
		local endPercent = math.max(cfg.loopStart + 0.01, cfg.loopEnd);
		local endTime = math.clamp(endPercent, 0, 100) / 100 * len;
		if cur.TimePosition < startTime or cur.TimePosition >= endTime then
			cur.TimePosition = startTime;
		end;
	end);
end);

local function kill()
	if not alive then
		return;
	end;
	alive = false;
	scanToken += 1;
	stopCurrent();
	clearHumanoidWatch();
	off();
	if sg then
		pcall(function()
			sg:Destroy();
		end);
	end;
end;
on(closeBtn.MouseButton1Click, kill);

refreshScan();
