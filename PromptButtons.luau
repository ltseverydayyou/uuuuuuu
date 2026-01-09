if not game:IsLoaded() then
	game.Loaded:Wait();
end;
local plrs = game:GetService("Players");
local pps = game:GetService("ProximityPromptService");
local uis = game:GetService("UserInputService");
local ts = game:GetService("TweenService");
local hs = game:GetService("HttpService");
local lp = plrs.LocalPlayer or plrs.PlayerAdded:Wait();
local function getPar()
	local ok, g;
	if typeof(gethui) == "function" then
		ok, g = pcall(gethui);
		if ok and typeof(g) == "Instance" then
			return g;
		end;
	end;
	local cg = game:FindFirstChildOfClass("CoreGui");
	if cg then
		return cg;
	end;
	return lp:WaitForChild("PlayerGui");
end;
local folder = "NA_PromptHelper";
local cfgFile = folder .. "/settings.json";
local keyFile = folder .. "/keys.json";
local function hasFS()
	return typeof(isfile) == "function" and typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(makefolder) == "function";
end;
if hasFS() then
	pcall(function()
		if not isfolder(folder) then
			makefolder(folder);
		end;
	end);
end;
local cfg = {
	w = 260,
	h = 44,
	gap = 8,
	mode = "hold",
	defHold = 0.4,
	corner = 14,
	bgColor = Color3.fromRGB(16, 16, 18),
	bgTrans = 0.12,
	strokeTrans = 0.35,
	showBar = true,
	fontScale = "medium",
	keySize = 14,
	titleSize = 14,
	descSize = 12,
	align = "center",
	yOffset = 70
};
local loadedKeyState = nil;
if hasFS() then
	pcall(function()
		if isfile(cfgFile) then
			local s = readfile(cfgFile);
			if s and s ~= "" then
				local t = hs:JSONDecode(s);
				if type(t) == "table" then
					for k, v in pairs(t) do
						if k == "bgColor" and type(v) == "table" then
							if #v >= 3 then
								cfg.bgColor = Color3.new(v[1], v[2], v[3]);
							end;
						elseif cfg[k] ~= nil and typeof(cfg[k]) ~= "Color3" then
							cfg[k] = v;
						end;
					end;
				end;
			end;
		end;
	end);
	pcall(function()
		if isfile(keyFile) then
			local s = readfile(keyFile);
			if s and s ~= "" then
				local t = hs:JSONDecode(s);
				if type(t) == "table" then
					loadedKeyState = t;
				end;
			end;
		end;
	end);
end;
local function applyFontScale()
	if cfg.fontScale == "small" then
		cfg.keySize = 12;
		cfg.titleSize = 13;
		cfg.descSize = 11;
	elseif cfg.fontScale == "large" then
		cfg.keySize = 16;
		cfg.titleSize = 17;
		cfg.descSize = 13;
	else
		cfg.keySize = 14;
		cfg.titleSize = 14;
		cfg.descSize = 12;
	end;
end;
applyFontScale();
local gui = Instance.new("ScreenGui");
gui.Name = "NA_PromptOverlay";
gui.ResetOnSpawn = false;
gui.IgnoreGuiInset = true;
gui.Parent = getPar();
local col = Instance.new("Frame");
col.Name = "PromptColumn";
col.AnchorPoint = Vector2.new(0.5, 1);
col.Position = UDim2.new(0.5, 0, 1, -cfg.yOffset);
col.Size = UDim2.new(0, cfg.w, 1, 0);
col.BackgroundTransparency = 1;
col.Parent = gui;
local lst = Instance.new("UIListLayout");
lst.FillDirection = Enum.FillDirection.Vertical;
lst.HorizontalAlignment = Enum.HorizontalAlignment.Center;
lst.VerticalAlignment = Enum.VerticalAlignment.Bottom;
lst.SortOrder = Enum.SortOrder.LayoutOrder;
lst.Padding = UDim.new(0, cfg.gap);
lst.Parent = col;
local dim = Instance.new("Frame");
dim.Name = "Dim";
dim.Size = UDim2.fromScale(1, 1);
dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0);
dim.BackgroundTransparency = 1;
dim.Visible = false;
dim.Parent = gui;
local men = Instance.new("Frame");
men.Name = "KeyMenu";
men.AnchorPoint = Vector2.new(0.5, 0.5);
men.Position = UDim2.fromScale(0.5, 0.5);
men.Size = UDim2.new(0, 360, 0, 300);
men.BackgroundColor3 = Color3.fromRGB(14, 14, 16);
men.BackgroundTransparency = 0.05;
men.Visible = false;
men.Parent = gui;
local mc = Instance.new("UICorner");
mc.CornerRadius = UDim.new(0, 16);
mc.Parent = men;
local ms = Instance.new("UIStroke");
ms.Thickness = 1.5;
ms.Transparency = 0.4;
ms.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
ms.Parent = men;
local top = Instance.new("Frame");
top.Name = "Top";
top.BackgroundTransparency = 1;
top.Position = UDim2.new(0, 14, 0, 10);
top.Size = UDim2.new(1, -28, 0, 52);
top.Parent = men;
local ttl = Instance.new("TextLabel");
ttl.Name = "Title";
ttl.BackgroundTransparency = 1;
ttl.Position = UDim2.new(0, 0, 0, 0);
ttl.Size = UDim2.new(1, -40, 0, 22);
ttl.Font = Enum.Font.GothamBold;
ttl.TextSize = 18;
ttl.TextColor3 = Color3.fromRGB(255, 255, 255);
ttl.TextXAlignment = Enum.TextXAlignment.Left;
ttl.TextYAlignment = Enum.TextYAlignment.Center;
ttl.Text = "Prompt helper";
ttl.Parent = top;
local sub = Instance.new("TextLabel");
sub.Name = "Sub";
sub.BackgroundTransparency = 1;
sub.Position = UDim2.new(0, 0, 0, 22);
sub.Size = UDim2.new(1, -40, 0, 18);
sub.Font = Enum.Font.Gotham;
sub.TextSize = 13;
sub.TextColor3 = Color3.fromRGB(200, 200, 200);
sub.TextXAlignment = Enum.TextXAlignment.Left;
sub.TextYAlignment = Enum.TextYAlignment.Center;
sub.Text = "Filter keybinds and tweak prompt UI.";
sub.Parent = top;
local xbtn = Instance.new("TextButton");
xbtn.Name = "X";
xbtn.AnchorPoint = Vector2.new(1, 0);
xbtn.Position = UDim2.new(1, 0, 0, 0);
xbtn.Size = UDim2.new(0, 34, 0, 34);
xbtn.AutoButtonColor = false;
xbtn.BackgroundColor3 = Color3.fromRGB(26, 26, 30);
xbtn.BackgroundTransparency = 0.1;
xbtn.Text = "×";
xbtn.Font = Enum.Font.GothamBold;
xbtn.TextSize = 20;
xbtn.TextColor3 = Color3.fromRGB(255, 255, 255);
xbtn.Parent = top;
local xc = Instance.new("UICorner");
xc.CornerRadius = UDim.new(0, 12);
xc.Parent = xbtn;
local xs = Instance.new("UIStroke");
xs.Thickness = 1.2;
xs.Transparency = 0.55;
xs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
xs.Parent = xbtn;
local tabs = Instance.new("Frame");
tabs.Name = "Tabs";
tabs.BackgroundTransparency = 1;
tabs.Position = UDim2.new(0, 14, 0, 64);
tabs.Size = UDim2.new(1, -28, 0, 30);
tabs.Parent = men;
local tabsLay = Instance.new("UIListLayout");
tabsLay.FillDirection = Enum.FillDirection.Horizontal;
tabsLay.HorizontalAlignment = Enum.HorizontalAlignment.Left;
tabsLay.VerticalAlignment = Enum.VerticalAlignment.Center;
tabsLay.Padding = UDim.new(0, 6);
tabsLay.Parent = tabs;
local function makeTab(text)
	local b = Instance.new("TextButton");
	b.AutoButtonColor = false;
	b.BackgroundColor3 = Color3.fromRGB(26, 26, 30);
	b.BackgroundTransparency = 0.1;
	b.Size = UDim2.new(0.5, -3, 1, 0);
	b.Font = Enum.Font.GothamSemibold;
	b.TextSize = 14;
	b.TextColor3 = Color3.fromRGB(220, 220, 220);
	b.Text = text;
	b.Parent = tabs;
	local c = Instance.new("UICorner");
	c.CornerRadius = UDim.new(0, 10);
	c.Parent = b;
	local s = Instance.new("UIStroke");
	s.Thickness = 1.1;
	s.Transparency = 0.6;
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	s.Parent = b;
	return b, s;
end;
local tabKey, tabKeyStroke = makeTab("Keybinds");
local tabSet, tabSetStroke = makeTab("Settings");
local pKey = Instance.new("Frame");
pKey.Name = "PageKeybinds";
pKey.BackgroundTransparency = 1;
pKey.Position = UDim2.new(0, 0, 0, 96);
pKey.Size = UDim2.new(1, 0, 1, -96);
pKey.Parent = men;
local pSet = Instance.new("ScrollingFrame");
pSet.Name = "PageSettings";
pSet.BackgroundTransparency = 1;
pSet.BorderSizePixel = 0;
pSet.Position = pKey.Position;
pSet.Size = pKey.Size;
pSet.Visible = false;
pSet.CanvasSize = UDim2.new(0, 0, 0, 0);
pSet.ScrollBarThickness = 6;
pSet.ScrollingDirection = Enum.ScrollingDirection.Y;
pSet.Parent = men;
local srh = Instance.new("TextBox");
srh.Name = "Search";
srh.Position = UDim2.new(0, 14, 0, 8);
srh.Size = UDim2.new(1, -28, 0, 32);
srh.BackgroundColor3 = Color3.fromRGB(20, 20, 24);
srh.BackgroundTransparency = 0.08;
srh.ClearTextOnFocus = false;
srh.Text = "";
srh.PlaceholderText = "Search keys (E, F, Shift...)";
srh.Font = Enum.Font.Gotham;
srh.TextSize = 14;
srh.TextColor3 = Color3.fromRGB(255, 255, 255);
srh.PlaceholderColor3 = Color3.fromRGB(160, 160, 160);
srh.TextXAlignment = Enum.TextXAlignment.Left;
srh.Parent = pKey;
local sc = Instance.new("UICorner");
sc.CornerRadius = UDim.new(0, 12);
sc.Parent = srh;
local ss = Instance.new("UIStroke");
ss.Thickness = 1.2;
ss.Transparency = 0.6;
ss.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
ss.Parent = srh;
local sp = Instance.new("UIPadding");
sp.PaddingLeft = UDim.new(0, 10);
sp.PaddingRight = UDim.new(0, 10);
sp.Parent = srh;
local row = Instance.new("Frame");
row.Name = "Row";
row.BackgroundTransparency = 1;
row.Position = UDim2.new(0, 14, 0, 46);
row.Size = UDim2.new(1, -28, 0, 26);
row.Parent = pKey;
local rlay = Instance.new("UIListLayout");
rlay.FillDirection = Enum.FillDirection.Horizontal;
rlay.HorizontalAlignment = Enum.HorizontalAlignment.Left;
rlay.VerticalAlignment = Enum.VerticalAlignment.Center;
rlay.Padding = UDim.new(0, 8);
rlay.Parent = row;
local function mkPill(text)
	local b = Instance.new("TextButton");
	b.AutoButtonColor = false;
	b.BackgroundColor3 = Color3.fromRGB(26, 26, 30);
	b.BackgroundTransparency = 0.08;
	b.Size = UDim2.new(0, 72, 0, 24);
	b.Font = Enum.Font.GothamSemibold;
	b.TextSize = 13;
	b.TextColor3 = Color3.fromRGB(255, 255, 255);
	b.Text = text;
	b.Parent = row;
	local c = Instance.new("UICorner");
	c.CornerRadius = UDim.new(0, 999);
	c.Parent = b;
	local s = Instance.new("UIStroke");
	s.Thickness = 1.1;
	s.Transparency = 0.6;
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	s.Parent = b;
	return b;
end;
local allBtn = mkPill("Select all");
local noneBtn = mkPill("Clear");
local invBtn = mkPill("Invert");
local scr = Instance.new("ScrollingFrame");
scr.Name = "Keys";
scr.BackgroundTransparency = 1;
scr.BorderSizePixel = 0;
scr.Position = UDim2.new(0, 14, 0, 76);
scr.Size = UDim2.new(1, -28, 1, -84);
scr.CanvasSize = UDim2.new(0, 0, 0, 0);
scr.ScrollBarThickness = 6;
scr.ScrollingDirection = Enum.ScrollingDirection.Y;
scr.Parent = pKey;
local grd = Instance.new("UIGridLayout");
grd.CellPadding = UDim2.new(0, 8, 0, 8);
grd.SortOrder = Enum.SortOrder.LayoutOrder;
grd.Parent = scr;
local function setGrid()
	local w = scr.AbsoluteSize.X;
	local cols = math.max(3, math.min(5, math.floor((w + 8) / 84)));
	local cw = math.floor((w - (cols - 1) * 8) / cols);
	grd.CellSize = UDim2.new(0, cw, 0, 28);
end;
(scr:GetPropertyChangedSignal("AbsoluteSize")):Connect(setGrid);
(grd:GetPropertyChangedSignal("AbsoluteContentSize")):Connect(function()
	scr.CanvasSize = UDim2.new(0, 0, 0, grd.AbsoluteContentSize.Y + 8);
end);
local setList = Instance.new("UIListLayout");
setList.FillDirection = Enum.FillDirection.Vertical;
setList.HorizontalAlignment = Enum.HorizontalAlignment.Left;
setList.VerticalAlignment = Enum.VerticalAlignment.Top;
setList.Padding = UDim.new(0, 6);
setList.Parent = pSet;
(setList:GetPropertyChangedSignal("AbsoluteContentSize")):Connect(function()
	pSet.CanvasSize = UDim2.new(0, 0, 0, setList.AbsoluteContentSize.Y + 10);
end);
local vs = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080);
local tog = Instance.new("TextButton");
tog.Name = "KeyMenuToggle";
tog.AnchorPoint = Vector2.new(0, 0);
tog.Position = UDim2.fromOffset(14, vs.Y - 58);
tog.Size = UDim2.new(0, 44, 0, 44);
tog.AutoButtonColor = false;
tog.BackgroundColor3 = Color3.fromRGB(14, 14, 16);
tog.BackgroundTransparency = 0.05;
tog.Text = "";
tog.Parent = gui;
local tgc = Instance.new("UICorner");
tgc.CornerRadius = UDim.new(1, 0);
tgc.Parent = tog;
local tgs = Instance.new("UIStroke");
tgs.Thickness = 1.6;
tgs.Transparency = 0.35;
tgs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
tgs.Parent = tog;
local ico = Instance.new("TextLabel");
ico.Name = "Ico";
ico.BackgroundTransparency = 1;
ico.Size = UDim2.fromScale(1, 1);
ico.Font = Enum.Font.GothamBold;
ico.TextSize = 18;
ico.TextColor3 = Color3.fromRGB(255, 255, 255);
ico.Text = "K";
ico.Parent = tog;
(ts:Create(tog, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {
	BackgroundTransparency = 0.12
})):Play();
local map = {};
local ord = 0;
local kst = {};
local anySel = false;
local kbtn = {};
local klist = {};
local function encodeCfg()
	local t = {};
	for k, v in pairs(cfg) do
		local tv = typeof(v);
		if tv == "Color3" then
			t[k] = {
				v.R,
				v.G,
				v.B
			};
		else
			t[k] = v;
		end;
	end;
	return t;
end;
local function saveCfg()
	if not hasFS() then
		return;
	end;
	local ok, s = pcall(function()
		return hs:JSONEncode(encodeCfg());
	end);
	if ok then
		pcall(function()
			writefile(cfgFile, s);
		end);
	end;
end;
local function saveKeys()
	if not hasFS() then
		return;
	end;
	local t = {};
	for k, v in pairs(kst) do
		if v then
			t[k] = true;
		end;
	end;
	local ok, s = pcall(function()
		return hs:JSONEncode(t);
	end);
	if ok then
		pcall(function()
			writefile(keyFile, s);
		end);
	end;
end;
local function tw(obj, t, props)
	(ts:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)):Play();
end;
local function low(s)
	return (s or ""):lower();
end;
local function hdur(pr)
	if cfg.mode == "instant" then
		return 0;
	end;
	local d = pr.HoldDuration or 0;
	if d > 0 then
		return d;
	end;
	return cfg.defHold;
end;
local function recAny()
	local v = false;
	for _, b in pairs(kst) do
		if b then
			v = true;
			break;
		end;
	end;
	anySel = v;
end;
local function okKey(k)
	if not anySel then
		return true;
	end;
	if not k then
		return false;
	end;
	return kst[k] == true;
end;
local function refVis()
	for _, d in pairs(map) do
		local ok = okKey(d.key);
		if d.w then
			if ok then
				d.w.Visible = true;
				d.w.Size = UDim2.new(1, 0, 0, cfg.h);
			else
				d.w.Visible = false;
				d.w.Size = UDim2.new(1, 0, 0, 0);
			end;
		end;
	end;
end;
local function restylePrompt(d)
	if not d.w or (not d.b) then
		return;
	end;
	if d.w.Visible then
		d.w.Size = UDim2.new(1, 0, 0, cfg.h);
	else
		d.w.Size = UDim2.new(1, 0, 0, 0);
	end;
	d.b.BackgroundColor3 = cfg.bgColor;
	d.b.BackgroundTransparency = cfg.bgTrans;
	if d.stroke then
		d.stroke.Transparency = cfg.strokeTrans;
	end;
	if d.corner then
		d.corner.CornerRadius = UDim.new(0, cfg.corner);
	end;
	if d.keyLbl then
		d.keyLbl.TextSize = cfg.keySize;
	end;
	if d.titleLbl then
		d.titleLbl.TextSize = cfg.titleSize;
	end;
	if d.descLbl then
		d.descLbl.TextSize = cfg.descSize;
	end;
	if d.barBg then
		local h = d.hd or 0;
		d.barBg.Visible = cfg.showBar and h > 0;
	end;
end;
local function applyAllStyle()
	local y = -cfg.yOffset;
	if cfg.align == "left" then
		col.AnchorPoint = Vector2.new(0, 1);
		col.Position = UDim2.new(0, 16, 1, y);
	elseif cfg.align == "right" then
		col.AnchorPoint = Vector2.new(1, 1);
		col.Position = UDim2.new(1, -16, 1, y);
	else
		col.AnchorPoint = Vector2.new(0.5, 1);
		col.Position = UDim2.new(0.5, 0, 1, y);
	end;
	col.Size = UDim2.new(0, cfg.w, 1, 0);
	lst.Padding = UDim.new(0, cfg.gap);
	for _, d in pairs(map) do
		restylePrompt(d);
	end;
end;
local function updK(n)
	local b = kbtn[n];
	if not b then
		return;
	end;
	local on = kst[n] == true;
	if on then
		b.BackgroundColor3 = Color3.fromRGB(84, 84, 110);
		b.TextTransparency = 0;
		b.TextColor3 = Color3.fromRGB(255, 255, 255);
	else
		b.BackgroundColor3 = Color3.fromRGB(26, 26, 30);
		b.TextTransparency = 0.15;
		b.TextColor3 = Color3.fromRGB(230, 230, 230);
	end;
end;
local function mkK(n)
	if kbtn[n] then
		return;
	end;
	table.insert(klist, n);
	local b = Instance.new("TextButton");
	b.Name = "K_" .. n;
	b.AutoButtonColor = false;
	b.BackgroundColor3 = Color3.fromRGB(26, 26, 30);
	b.BackgroundTransparency = 0.08;
	b.Font = Enum.Font.GothamSemibold;
	b.TextSize = 13;
	b.TextColor3 = Color3.fromRGB(240, 240, 240);
	b.Text = n;
	b.Parent = scr;
	local c = Instance.new("UICorner");
	c.CornerRadius = UDim.new(0, 10);
	c.Parent = b;
	local s = Instance.new("UIStroke");
	s.Thickness = 1.1;
	s.Transparency = 0.6;
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	s.Parent = b;
	if loadedKeyState and loadedKeyState[n] then
		kst[n] = true;
	end;
	kbtn[n] = b;
	updK(n);
	b.Activated:Connect(function()
		kst[n] = not kst[n];
		recAny();
		updK(n);
		refVis();
		saveKeys();
	end);
end;
for _, kc in ipairs(Enum.KeyCode:GetEnumItems()) do
	if kc ~= Enum.KeyCode.Unknown then
		local n = kc.Name:gsub("^Key", "");
		if n ~= "" then
			mkK(n);
		end;
	end;
end;
mkK("Tap");
mkK("Key");
setGrid();
recAny();
refVis();
local function refSearch()
	local q = low(srh.Text);
	if q == "" then
		for _, n in ipairs(klist) do
			local b = kbtn[n];
			if b then
				b.Visible = true;
			end;
		end;
		return;
	end;
	for _, n in ipairs(klist) do
		local b = kbtn[n];
		if b then
			b.Visible = (low(n)):find(q, 1, true) ~= nil;
		end;
	end;
end;
(srh:GetPropertyChangedSignal("Text")):Connect(refSearch);
allBtn.Activated:Connect(function()
	for _, n in ipairs(klist) do
		kst[n] = true;
		updK(n);
	end;
	recAny();
	refVis();
	saveKeys();
end);
noneBtn.Activated:Connect(function()
	for _, n in ipairs(klist) do
		kst[n] = nil;
		updK(n);
	end;
	recAny();
	refVis();
	saveKeys();
end);
invBtn.Activated:Connect(function()
	for _, n in ipairs(klist) do
		kst[n] = not (kst[n] == true);
		updK(n);
	end;
	recAny();
	refVis();
	saveKeys();
end);
local function selectTab(which)
	if which == "key" then
		pKey.Visible = true;
		pSet.Visible = false;
		tabKey.BackgroundColor3 = Color3.fromRGB(60, 60, 90);
		tabKeyStroke.Transparency = 0.4;
		tabKey.TextColor3 = Color3.fromRGB(255, 255, 255);
		tabSet.BackgroundColor3 = Color3.fromRGB(26, 26, 30);
		tabSetStroke.Transparency = 0.7;
		tabSet.TextColor3 = Color3.fromRGB(210, 210, 210);
	else
		pKey.Visible = false;
		pSet.Visible = true;
		tabSet.BackgroundColor3 = Color3.fromRGB(60, 60, 90);
		tabSetStroke.Transparency = 0.4;
		tabSet.TextColor3 = Color3.fromRGB(255, 255, 255);
		tabKey.BackgroundColor3 = Color3.fromRGB(26, 26, 30);
		tabKeyStroke.Transparency = 0.7;
		tabKey.TextColor3 = Color3.fromRGB(210, 210, 210);
	end;
end;
tabKey.Activated:Connect(function()
	selectTab("key");
end);
tabSet.Activated:Connect(function()
	selectTab("settings");
end);
selectTab("key");
local function makeSetting(label, getText, onNext)
	local f = Instance.new("Frame");
	f.BackgroundTransparency = 1;
	f.Size = UDim2.new(1, -28, 0, 30);
	f.Parent = pSet;
	local lbl = Instance.new("TextLabel");
	lbl.BackgroundTransparency = 1;
	lbl.Position = UDim2.new(0, 14, 0, 0);
	lbl.Size = UDim2.new(0.55, -14, 1, 0);
	lbl.Font = Enum.Font.Gotham;
	lbl.TextSize = 14;
	lbl.TextColor3 = Color3.fromRGB(220, 220, 220);
	lbl.TextXAlignment = Enum.TextXAlignment.Left;
	lbl.TextYAlignment = Enum.TextYAlignment.Center;
	lbl.Text = label;
	lbl.Parent = f;
	local btn = Instance.new("TextButton");
	btn.AnchorPoint = Vector2.new(1, 0.5);
	btn.Position = UDim2.new(1, -14, 0.5, 0);
	btn.Size = UDim2.new(0.4, 0, 0, 24);
	btn.AutoButtonColor = false;
	btn.BackgroundColor3 = Color3.fromRGB(26, 26, 30);
	btn.BackgroundTransparency = 0.08;
	btn.Font = Enum.Font.GothamSemibold;
	btn.TextSize = 13;
	btn.TextColor3 = Color3.fromRGB(230, 230, 230);
	btn.Text = getText();
	btn.Parent = f;
	local c = Instance.new("UICorner");
	c.CornerRadius = UDim.new(0, 999);
	c.Parent = btn;
	local s = Instance.new("UIStroke");
	s.Thickness = 1.1;
	s.Transparency = 0.6;
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	s.Parent = btn;
	btn.Activated:Connect(function()
		onNext();
		btn.Text = getText();
		applyFontScale();
		applyAllStyle();
		saveCfg();
	end);
end;
local modeList = {
	"instant",
	"hold"
};
local modeIdx = 1;
for i, v in ipairs(modeList) do
	if v == cfg.mode then
		modeIdx = i;
		break;
	end;
end;
makeSetting("Prompt mode", function()
	return string.upper(string.sub(cfg.mode, 1, 1)) .. string.sub(cfg.mode, 2);
end, function()
	modeIdx = modeIdx + 1;
	if modeIdx > (#modeList) then
		modeIdx = 1;
	end;
	cfg.mode = modeList[modeIdx];
end);
local heightList = {
	36,
	44,
	52
};
local hIdx = 1;
for i, v in ipairs(heightList) do
	if v == cfg.h then
		hIdx = i;
		break;
	end;
end;
makeSetting("Button height", function()
	return tostring(cfg.h) .. " px";
end, function()
	hIdx = hIdx + 1;
	if hIdx > (#heightList) then
		hIdx = 1;
	end;
	cfg.h = heightList[hIdx];
end);
local widthList = {
	220,
	260,
	300
};
local wIdx = 1;
for i, v in ipairs(widthList) do
	if v == cfg.w then
		wIdx = i;
		break;
	end;
end;
makeSetting("Button width", function()
	return tostring(cfg.w) .. " px";
end, function()
	wIdx = wIdx + 1;
	if wIdx > (#widthList) then
		wIdx = 1;
	end;
	cfg.w = widthList[wIdx];
end);
local gapList = {
	4,
	8,
	12
};
local gIdx = 1;
for i, v in ipairs(gapList) do
	if v == cfg.gap then
		gIdx = i;
		break;
	end;
end;
makeSetting("Vertical gap", function()
	return tostring(cfg.gap) .. " px";
end, function()
	gIdx = gIdx + 1;
	if gIdx > (#gapList) then
		gIdx = 1;
	end;
	cfg.gap = gapList[gIdx];
end);
local cornerList = {
	8,
	14,
	20
};
local cIdx = 1;
for i, v in ipairs(cornerList) do
	if v == cfg.corner then
		cIdx = i;
		break;
	end;
end;
makeSetting("Corner radius", function()
	return tostring(cfg.corner) .. " px";
end, function()
	cIdx = cIdx + 1;
	if cIdx > (#cornerList) then
		cIdx = 1;
	end;
	cfg.corner = cornerList[cIdx];
end);
local themeList = {
	"Dark",
	"Glass",
	"Solid"
};
local tIdx = 1;
makeSetting("Background style", function()
	return themeList[tIdx];
end, function()
	tIdx = tIdx + 1;
	if tIdx > (#themeList) then
		tIdx = 1;
	end;
	local v = themeList[tIdx];
	if v == "Dark" then
		cfg.bgColor = Color3.fromRGB(16, 16, 18);
		cfg.bgTrans = 0.12;
		cfg.strokeTrans = 0.35;
	elseif v == "Glass" then
		cfg.bgColor = Color3.fromRGB(12, 12, 14);
		cfg.bgTrans = 0.25;
		cfg.strokeTrans = 0.55;
	else
		cfg.bgColor = Color3.fromRGB(20, 20, 22);
		cfg.bgTrans = 0.05;
		cfg.strokeTrans = 0.25;
	end;
end);
makeSetting("Progress bar", function()
	return cfg.showBar and "Enabled" or "Disabled";
end, function()
	cfg.showBar = not cfg.showBar;
end);
local fontList = {
	"small",
	"medium",
	"large"
};
local fIdx = 1;
for i, v in ipairs(fontList) do
	if v == cfg.fontScale then
		fIdx = i;
		break;
	end;
end;
makeSetting("Font scale", function()
	return string.upper(string.sub(cfg.fontScale, 1, 1)) .. string.sub(cfg.fontScale, 2);
end, function()
	fIdx = fIdx + 1;
	if fIdx > (#fontList) then
		fIdx = 1;
	end;
	cfg.fontScale = fontList[fIdx];
end);
local alignList = {
	"left",
	"center",
	"right"
};
local aIdx = 1;
for i, v in ipairs(alignList) do
	if v == cfg.align then
		aIdx = i;
		break;
	end;
end;
makeSetting("Column align", function()
	return string.upper(string.sub(cfg.align, 1, 1)) .. string.sub(cfg.align, 2);
end, function()
	aIdx = aIdx + 1;
	if aIdx > (#alignList) then
		aIdx = 1;
	end;
	cfg.align = alignList[aIdx];
end);
local offsetList = {
	40,
	70,
	100,
	140
};
local oIdx = 1;
for i, v in ipairs(offsetList) do
	if v == cfg.yOffset then
		oIdx = i;
		break;
	end;
end;
makeSetting("Column offset", function()
	return tostring(cfg.yOffset) .. " px";
end, function()
	oIdx = oIdx + 1;
	if oIdx > (#offsetList) then
		oIdx = 1;
	end;
	cfg.yOffset = offsetList[oIdx];
end);
applyAllStyle();
saveCfg();
local function firePrompt(pr, hd)
	if not pr or (not pr:IsDescendantOf(game)) then
		return;
	end;
	if typeof(fireproximityprompt) == "function" then
		if hd > 0 then
			task.delay(hd, function()
				if pr and pr:IsDescendantOf(game) then
					pcall(function()
						fireproximityprompt(pr);
					end);
				end;
			end);
		else
			pcall(function()
				fireproximityprompt(pr);
			end);
		end;
	elseif hd > 0 then
		pcall(function()
			pps:InputHoldBegin(pr);
		end);
		task.delay(hd, function()
			if pr and pr:IsDescendantOf(game) then
				pcall(function()
					pps:InputHoldEnd(pr);
				end);
			end;
		end);
	else
		pcall(function()
			pps:InputHoldBegin(pr);
		end);
		task.delay(0.05, function()
			if pr and pr:IsDescendantOf(game) then
				pcall(function()
					pps:InputHoldEnd(pr);
				end);
			end;
		end);
	end;
end;
local function rm(pr)
	local d = map[pr];
	if not d then
		return;
	end;
	map[pr] = nil;
	if d.c then
		for _, x in ipairs(d.c) do
			pcall(function()
				x:Disconnect();
			end);
		end;
	end;
	if d.w and d.w.Parent then
		d.w:Destroy();
	end;
end;
local function add(pr)
	if not pr or map[pr] then
		return;
	end;
	ord = ord - 1;
	local w = Instance.new("Frame");
	w.Name = "PromptWrap";
	w.Size = UDim2.new(1, 0, 0, cfg.h);
	w.BackgroundTransparency = 1;
	w.LayoutOrder = ord;
	w.Parent = col;
	local b = Instance.new("TextButton");
	b.Name = "PromptBtn";
	b.AnchorPoint = Vector2.new(0.5, 0.5);
	b.Position = UDim2.new(0.5, 0, 0.5, 0);
	b.Size = UDim2.new(1, 0, 1, 0);
	b.AutoButtonColor = false;
	b.BackgroundColor3 = cfg.bgColor;
	b.BackgroundTransparency = cfg.bgTrans;
	b.Text = "";
	b.Parent = w;
	local bc = Instance.new("UICorner");
	bc.CornerRadius = UDim.new(0, cfg.corner);
	bc.Parent = b;
	local bs = Instance.new("UIStroke");
	bs.Thickness = 1.2;
	bs.Transparency = cfg.strokeTrans;
	bs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
	bs.Parent = b;
	local kl = Instance.new("TextLabel");
	kl.Name = "Key";
	kl.BackgroundTransparency = 1;
	kl.Position = UDim2.new(0, 12, 0, 3);
	kl.Size = UDim2.new(0, 58, 0, 16);
	kl.Font = Enum.Font.GothamBold;
	kl.TextSize = cfg.keySize;
	kl.TextColor3 = Color3.fromRGB(255, 255, 255);
	kl.TextXAlignment = Enum.TextXAlignment.Left;
	kl.TextYAlignment = Enum.TextYAlignment.Center;
	kl.Parent = b;
	local tl = Instance.new("TextLabel");
	tl.Name = "Title";
	tl.BackgroundTransparency = 1;
	tl.Position = UDim2.new(0, 70, 0, 3);
	tl.Size = UDim2.new(1, -82, 0, 16);
	tl.Font = Enum.Font.GothamSemibold;
	tl.TextSize = cfg.titleSize;
	tl.TextColor3 = Color3.fromRGB(255, 255, 255);
	tl.TextXAlignment = Enum.TextXAlignment.Left;
	tl.TextYAlignment = Enum.TextYAlignment.Center;
	tl.TextTruncate = Enum.TextTruncate.AtEnd;
	tl.Parent = b;
	local dl = Instance.new("TextLabel");
	dl.Name = "Desc";
	dl.BackgroundTransparency = 1;
	dl.Position = UDim2.new(0, 12, 0, 19);
	dl.Size = UDim2.new(1, -24, 0, 16);
	dl.Font = Enum.Font.Gotham;
	dl.TextSize = cfg.descSize;
	dl.TextColor3 = Color3.fromRGB(210, 210, 210);
	dl.TextXAlignment = Enum.TextXAlignment.Left;
	dl.TextYAlignment = Enum.TextYAlignment.Top;
	dl.TextWrapped = true;
	dl.Parent = b;
	local bg = Instance.new("Frame");
	bg.Name = "BarBg";
	bg.Position = UDim2.new(0, 12, 1, -3);
	bg.Size = UDim2.new(1, -24, 0, 2);
	bg.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	bg.BackgroundTransparency = 0.88;
	bg.Parent = b;
	local bgc = Instance.new("UICorner");
	bgc.CornerRadius = UDim.new(1, 0);
	bgc.Parent = bg;
	local br = Instance.new("Frame");
	br.Name = "Bar";
	br.Size = UDim2.new(0, 0, 1, 0);
	br.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
	br.BackgroundTransparency = 0.2;
	br.Parent = bg;
	local brc = Instance.new("UICorner");
	brc.CornerRadius = UDim.new(1, 0);
	brc.Parent = br;
	local con = {};
	local busy = false;
	map[pr] = {
		pr = pr,
		w = w,
		b = b,
		c = con,
		key = "",
		keyLbl = kl,
		titleLbl = tl,
		descLbl = dl,
		barBg = bg,
		bar = br,
		stroke = bs,
		corner = bc,
		hd = 0
	};
	local function ktxtLocal()
		local k = pr.KeyboardKeyCode;
		if not k or k == Enum.KeyCode.Unknown then
			if uis.TouchEnabled and (not uis.KeyboardEnabled) then
				return "Tap";
			end;
			return "Key";
		end;
		return k.Name:gsub("^Key", "");
	end;
	local function ttxtLocal()
		local o = pr.ObjectText or "";
		if o ~= "" then
			return o;
		end;
		local a = pr.ActionText or "";
		if a ~= "" then
			return a;
		end;
		return "Interact";
	end;
	local function dtxtLocal()
		local a = pr.ActionText or "";
		if a ~= "" then
			return a;
		end;
		return "";
	end;
	local function refresh()
		local keyName = ktxtLocal();
		local d = map[pr];
		if not d then
			return;
		end;
		d.key = keyName;
		kl.Text = keyName;
		tl.Text = ttxtLocal();
		dl.Text = dtxtLocal();
		if not kbtn[keyName] then
			mkK(keyName);
		end;
		local hd = hdur(pr);
		d.hd = hd;
		if cfg.showBar and hd > 0 then
			bg.Visible = true;
		else
			bg.Visible = false;
		end;
		if hd <= 0 then
			br.Size = UDim2.new(0, 0, 1, 0);
		end;
		local ok = okKey(keyName);
		if ok then
			w.Visible = true;
			w.Size = UDim2.new(1, 0, 0, cfg.h);
		else
			w.Visible = false;
			w.Size = UDim2.new(1, 0, 0, 0);
		end;
	end;
	local function activated()
		if busy then
			return;
		end;
		if not pr or (not pr:IsDescendantOf(game)) then
			rm(pr);
			return;
		end;
		if not okKey(map[pr].key) then
			return;
		end;
		busy = true;
		tw(b, 0.08, {
			Size = UDim2.new(1, -10, 1, -4)
		});
		local hd = hdur(pr);
		if hd > 0 then
			br.Size = UDim2.new(0, 0, 1, 0);
			bg.Visible = cfg.showBar;
			if cfg.showBar then
				tw(br, hd, {
					Size = UDim2.new(1, 0, 1, 0)
				});
			end;
		else
			bg.Visible = false;
			br.Size = UDim2.new(1, 0, 1, 0);
			tw(br, 0.12, {
				Size = UDim2.new(0, 0, 1, 0)
			});
		end;
		firePrompt(pr, hd);
		task.delay(math.max(hd, 0.15), function()
			if b.Parent then
				tw(b, 0.12, {
					Size = UDim2.new(1, 0, 1, 0)
				});
			end;
			busy = false;
		end);
	end;
	table.insert(con, b.Activated:Connect(activated));
	table.insert(con, (pr:GetPropertyChangedSignal("ActionText")):Connect(refresh));
	table.insert(con, (pr:GetPropertyChangedSignal("ObjectText")):Connect(refresh));
	table.insert(con, (pr:GetPropertyChangedSignal("KeyboardKeyCode")):Connect(refresh));
	table.insert(con, (pr:GetPropertyChangedSignal("HoldDuration")):Connect(refresh));
	table.insert(con, pr.AncestryChanged:Connect(function()
		if not pr:IsDescendantOf(game) then
			rm(pr);
		end;
	end));
	refresh();
	if pr.Style ~= Enum.ProximityPromptStyle.Custom then
		pcall(function()
			pr.Style = Enum.ProximityPromptStyle.Custom;
		end);
	end;
end;
pps.PromptShown:Connect(add);
pps.PromptHidden:Connect(rm);
local function openMen(open)
	if open then
		dim.Visible = true;
		men.Visible = true;
		tog.Visible = false;
		dim.BackgroundTransparency = 1;
		men.BackgroundTransparency = 1;
		local target = UDim2.fromScale(0.5, 0.5);
		men.Position = UDim2.new(target.X.Scale, target.X.Offset, target.Y.Scale, target.Y.Offset + 10);
		men.Size = UDim2.new(0, 340, 0, 280);
		tw(dim, 0.2, {
			BackgroundTransparency = 0.45
		});
		tw(men, 0.2, {
			BackgroundTransparency = 0.05,
			Position = target,
			Size = UDim2.new(0, 360, 0, 300)
		});
	else
		if not men.Visible then
			return;
		end;
		tog.Visible = true;
		local p0 = men.Position;
		tw(dim, 0.15, {
			BackgroundTransparency = 1
		});
		tw(men, 0.15, {
			BackgroundTransparency = 1,
			Position = UDim2.new(p0.X.Scale, p0.X.Offset, p0.Y.Scale, p0.Y.Offset + 10),
			Size = UDim2.new(0, 340, 0, 280)
		});
		task.delay(0.16, function()
			if dim then
				dim.Visible = false;
			end;
			if men then
				men.Visible = false;
			end;
		end);
	end;
end;
xbtn.Activated:Connect(function()
	openMen(false);
end);
dim.InputBegan:Connect(function(i)
	if not men.Visible then
		return;
	end;
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
		local pos = i.Position;
		local p = Vector2.new(pos.X, pos.Y);
		local mPos = men.AbsolutePosition;
		local mSize = men.AbsoluteSize;
		local inside = p.X >= mPos.X and p.X <= mPos.X + mSize.X and p.Y >= mPos.Y and p.Y <= mPos.Y + mSize.Y;
		if not inside then
			openMen(false);
		end;
	end;
end);
do
	local dragging = false;
	local moved = false;
	local active = nil;
	local dragStart;
	local startPos;
	local threshold = 6;
	tog.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true;
			moved = false;
			active = input;
			dragStart = input.Position;
			startPos = tog.Position;
		end;
	end);
	uis.InputChanged:Connect(function(input)
		if not dragging or input ~= active then
			return;
		end;
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return;
		end;
		local delta = input.Position - dragStart;
		if not moved and math.abs(delta.X) + math.abs(delta.Y) < threshold then
			return;
		end;
		moved = true;
		local cam = workspace.CurrentCamera;
		local v = cam and cam.ViewportSize or Vector2.new(1920, 1080);
		local sz = tog.AbsoluteSize;
		local x = startPos.X.Offset + delta.X;
		local y = startPos.Y.Offset + delta.Y;
		local minX = 0;
		local maxX = v.X - sz.X;
		local minY = 0;
		local maxY = v.Y - sz.Y;
		x = math.clamp(x, minX, maxX);
		y = math.clamp(y, minY, maxY);
		tog.Position = UDim2.fromOffset(x, y);
	end);
	uis.InputEnded:Connect(function(input)
		if input ~= active then
			return;
		end;
		dragging = false;
		active = nil;
		if not moved then
			openMen(not men.Visible);
		end;
	end);
end;
