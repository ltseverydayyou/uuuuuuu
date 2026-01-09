local function ClonedService(n)
	local S = game.GetService;
	local R = cloneref or function(x)
		return x;
	end;
	return R(S(game, n));
end;
local uis = ClonedService("UserInputService");
local vim = ClonedService("VirtualInputManager");
local ts = ClonedService("TextService");
local rs = ClonedService("RunService");
local function protectUI(g)
	if g:IsA("ScreenGui") then
		g.ZIndexBehavior = Enum.ZIndexBehavior.Global;
		g.DisplayOrder = 999999999;
		g.ResetOnSpawn = false;
		g.IgnoreGuiInset = true;
	end;
	local cg = ClonedService("CoreGui");
	local lp = (ClonedService("Players")).LocalPlayer;
	local function NA(x, v)
		if x then
			if v then
				x[v] = "\000";
				x.Archivable = false;
			else
				x.Name = "\000";
				x.Archivable = false;
			end;
		end;
	end;
	if gethui then
		NA(g);
		g.Parent = gethui();
		return g;
	elseif cg and cg:FindFirstChild("RobloxGui") then
		NA(g);
		g.Parent = cg.RobloxGui;
		return g;
	elseif cg then
		NA(g);
		g.Parent = cg;
		return g;
	elseif lp and lp:FindFirstChildWhichIsA("PlayerGui") then
		NA(g);
		g.Parent = lp:FindFirstChildWhichIsA("PlayerGui");
		g.ResetOnSpawn = false;
		return g;
	else
		return nil;
	end;
end;
local themes = {
	Dark = {
		Bg = Color3.fromRGB(28, 30, 34),
		Btn = Color3.fromRGB(50, 52, 60),
		Acc = Color3.fromRGB(80, 180, 120),
		Txt = Color3.fromRGB(255, 255, 255)
	},
	Light = {
		Bg = Color3.fromRGB(245, 245, 245),
		Btn = Color3.fromRGB(220, 220, 220),
		Acc = Color3.fromRGB(80, 160, 250),
		Txt = Color3.fromRGB(0, 0, 0)
	},
	Blue = {
		Bg = Color3.fromRGB(18, 24, 48),
		Btn = Color3.fromRGB(36, 48, 96),
		Acc = Color3.fromRGB(90, 130, 255),
		Txt = Color3.fromRGB(255, 255, 255)
	},
	Purple = {
		Bg = Color3.fromRGB(36, 24, 44),
		Btn = Color3.fromRGB(58, 36, 76),
		Acc = Color3.fromRGB(180, 100, 255),
		Txt = Color3.fromRGB(255, 255, 255)
	},
	Green = {
		Bg = Color3.fromRGB(18, 36, 24),
		Btn = Color3.fromRGB(28, 56, 36),
		Acc = Color3.fromRGB(60, 200, 120),
		Txt = Color3.fromRGB(255, 255, 255)
	}
};
local function shade(c, p)
	return p < 0 and c:Lerp(Color3.new(0, 0, 0), (-p)) or c:Lerp(Color3.new(1, 1, 1), p);
end;
local function lum(c)
	return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B;
end;
local ui = Instance.new("ScreenGui");
ui.Name = "VKB";
ui.ResetOnSpawn = false;
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
protectUI(ui);
local IsOnMobile = (function()
	local platform = (ClonedService("UserInputService")):GetPlatform();
	if platform == Enum.Platform.IOS or platform == Enum.Platform.Android or platform == Enum.Platform.AndroidTV or platform == Enum.Platform.Chromecast or platform == Enum.Platform.MetaOS then
		return true;
	end;
	if platform == Enum.Platform.None then
		return (ClonedService("UserInputService")).TouchEnabled and (not ((ClonedService("UserInputService")).KeyboardEnabled or (ClonedService("UserInputService")).MouseEnabled));
	end;
	return false;
end)();
local mainFrm = Instance.new("Frame");
mainFrm.Name = "Main";
mainFrm.Size = UDim2.new(IsOnMobile and 0.85 or 0.46, 0, IsOnMobile and 0.56 or 0.4, 0);
mainFrm.Position = UDim2.new(0.5, 0, 1, -8);
mainFrm.AnchorPoint = Vector2.new(0.5, 1);
mainFrm.BackgroundColor3 = themes.Dark.Bg;
mainFrm.BorderSizePixel = 0;
mainFrm.Parent = ui;
local c1 = Instance.new("UICorner");
c1.CornerRadius = UDim.new(0, 12);
c1.Parent = mainFrm;
local titleBar = Instance.new("Frame");
titleBar.Size = UDim2.new(1, 0, 0, 30);
titleBar.BackgroundColor3 = themes.Dark.Btn;
titleBar.BorderSizePixel = 0;
titleBar.Parent = mainFrm;
local c2 = Instance.new("UICorner");
c2.CornerRadius = UDim.new(0, 12);
c2.Parent = titleBar;
local titleLbl = Instance.new("TextLabel");
titleLbl.Size = UDim2.new(1, -420, 1, 0);
titleLbl.Position = UDim2.new(0, 10, 0, 0);
titleLbl.BackgroundTransparency = 1;
titleLbl.TextColor3 = themes.Dark.Txt;
titleLbl.Text = "Virtual Keyboard";
titleLbl.Font = Enum.Font.SourceSansBold;
titleLbl.TextScaled = true;
local tlc = Instance.new("UITextSizeConstraint", titleLbl);
tlc.MaxTextSize = 16;
tlc.MinTextSize = 10;
titleLbl.Parent = titleBar;
local function newTopBtn(name, xoff, w, text, bg)
	local b = Instance.new("TextButton");
	b.Name = name;
	b.Size = UDim2.new(0, w, 0, 24);
	b.Position = UDim2.new(1, xoff, 0, 3);
	b.BackgroundColor3 = bg;
	b.TextColor3 = themes.Dark.Txt;
	b.Text = text;
	b.Font = Enum.Font.SourceSansBold;
	b.TextScaled = true;
	local cc = Instance.new("UITextSizeConstraint", b);
	cc.MaxTextSize = 14;
	cc.MinTextSize = 10;
	b.Parent = titleBar;
	local r = Instance.new("UICorner");
	r.CornerRadius = UDim.new(0, 8);
	r.Parent = b;
	return b;
end;
local closeBtn = newTopBtn("Close", -42, 36, "×", Color3.fromRGB(200, 60, 60));
local addBtn = newTopBtn("Add", -88, 40, "+", themes.Dark.Acc);
local themeBtn = newTopBtn("Theme", -170, 74, "Dark", themes.Dark.Btn);
local rgbBtn = newTopBtn("RGB", -246, 74, "Rainbow", shade(themes.Dark.Acc, 0.2));
local colorBtn = newTopBtn("Palette", -328, 74, "Palette", themes.Dark.Btn);
local modeBtn = newTopBtn("Mode", -410, 74, "QWERTY", themes.Dark.Btn);
local keysScroll = Instance.new("ScrollingFrame");
keysScroll.Name = "KeysScroll";
keysScroll.Size = UDim2.new(1, -12, 1, -44);
keysScroll.Position = UDim2.new(0, 6, 0, 34);
keysScroll.BackgroundTransparency = 1;
keysScroll.BorderSizePixel = 0;
keysScroll.CanvasSize = UDim2.new(0, 0, 0, 0);
keysScroll.ScrollBarThickness = 6;
keysScroll.Parent = mainFrm;
local vlist = Instance.new("UIListLayout");
vlist.FillDirection = Enum.FillDirection.Vertical;
vlist.Padding = UDim.new(0, 8);
vlist.SortOrder = Enum.SortOrder.LayoutOrder;
vlist.Parent = keysScroll;
(vlist:GetPropertyChangedSignal("AbsoluteContentSize")):Connect(function()
	keysScroll.CanvasSize = UDim2.new(0, 0, 0, vlist.AbsoluteContentSize.Y + 10);
end);
local toggleBtn = Instance.new("TextButton");
toggleBtn.Name = "Toggle";
toggleBtn.Size = UDim2.new(0, 46, 0, 46);
toggleBtn.Position = UDim2.new(0, 16, 1, -66);
toggleBtn.AnchorPoint = Vector2.new(0, 1);
toggleBtn.BackgroundColor3 = themes.Dark.Btn;
toggleBtn.TextColor3 = themes.Dark.Txt;
toggleBtn.Text = "⌨️";
toggleBtn.Font = Enum.Font.SourceSansBold;
toggleBtn.TextScaled = true;
local tc = Instance.new("UITextSizeConstraint", toggleBtn);
tc.MaxTextSize = 18;
tc.MinTextSize = 12;
toggleBtn.Parent = ui;
local c6 = Instance.new("UICorner");
c6.CornerRadius = UDim.new(0, 12);
c6.Parent = toggleBtn;
local function labelFromKC(kc)
	local name = (tostring(kc)):gsub("^Enum%.KeyCode%.", "");
	local map = {
		One = "1",
		Two = "2",
		Three = "3",
		Four = "4",
		Five = "5",
		Six = "6",
		Seven = "7",
		Eight = "8",
		Nine = "9",
		Zero = "0",
		Minus = "-",
		Equals = "=",
		LeftBracket = "[",
		RightBracket = "]",
		BackSlash = "\\",
		Semicolon = ";",
		Quote = "'",
		Comma = ",",
		Period = ".",
		Slash = "/",
		Backquote = "`",
		Return = "Enter",
		Backspace = "Bksp",
		Delete = "Del",
		Tab = "Tab",
		CapsLock = "Caps",
		LeftShift = "LShift",
		RightShift = "RShift",
		LeftControl = "LCtrl",
		RightControl = "RCtrl",
		LeftAlt = "LAlt",
		RightAlt = "RAlt",
		LeftMeta = "LWin",
		RightMeta = "RWin",
		Insert = "Ins",
		PageUp = "PgUp",
		PageDown = "PgDn",
		Print = "PrtSc",
		ScrollLock = "ScrLk",
		Pause = "Pause",
		NumLock = "NumLk",
		Escape = "Esc",
		Space = "Space",
		ButtonA = "A",
		ButtonB = "B",
		ButtonX = "X",
		ButtonY = "Y",
		ButtonL1 = "L1",
		ButtonR1 = "R1",
		ButtonL2 = "L2",
		ButtonR2 = "R2",
		ButtonL3 = "L3",
		ButtonR3 = "R3",
		DPadLeft = "◀",
		DPadRight = "▶",
		DPadUp = "▲",
		DPadDown = "▼",
		Thumbstick1 = "LS",
		Thumbstick2 = "RS",
		Home = "Home",
		End = "End",
		Up = "Up",
		Down = "Down",
		Left = "Left",
		Right = "Right"
	};
	return map[name] or name;
end;
local function kcFromLabel(t)
	local r = {
		["1"] = Enum.KeyCode.One,
		["2"] = Enum.KeyCode.Two,
		["3"] = Enum.KeyCode.Three,
		["4"] = Enum.KeyCode.Four,
		["5"] = Enum.KeyCode.Five,
		["6"] = Enum.KeyCode.Six,
		["7"] = Enum.KeyCode.Seven,
		["8"] = Enum.KeyCode.Eight,
		["9"] = Enum.KeyCode.Nine,
		["0"] = Enum.KeyCode.Zero,
		["-"] = Enum.KeyCode.Minus,
		["="] = Enum.KeyCode.Equals,
		["["] = Enum.KeyCode.LeftBracket,
		["]"] = Enum.KeyCode.RightBracket,
		["\\"] = Enum.KeyCode.BackSlash,
		[";"] = Enum.KeyCode.Semicolon,
		["'"] = Enum.KeyCode.Quote,
		[","] = Enum.KeyCode.Comma,
		["."] = Enum.KeyCode.Period,
		["/"] = Enum.KeyCode.Slash,
		["`"] = Enum.KeyCode.Backquote,
		Bksp = Enum.KeyCode.Backspace,
		Tab = Enum.KeyCode.Tab,
		Caps = Enum.KeyCode.CapsLock,
		Enter = Enum.KeyCode.Return,
		LShift = Enum.KeyCode.LeftShift,
		RShift = Enum.KeyCode.RightShift,
		LCtrl = Enum.KeyCode.LeftControl,
		RCtrl = Enum.KeyCode.RightControl,
		LAlt = Enum.KeyCode.LeftAlt,
		RAlt = Enum.KeyCode.RightAlt,
		LWin = Enum.KeyCode.LeftMeta,
		RWin = Enum.KeyCode.RightMeta,
		Ins = Enum.KeyCode.Insert,
		PgUp = Enum.KeyCode.PageUp,
		PgDn = Enum.KeyCode.PageDown,
		PrtSc = Enum.KeyCode.Print,
		ScrLk = Enum.KeyCode.ScrollLock,
		Pause = Enum.KeyCode.Pause,
		NumLk = Enum.KeyCode.NumLock,
		Esc = Enum.KeyCode.Escape,
		Space = Enum.KeyCode.Space,
		Del = Enum.KeyCode.Delete,
		Home = Enum.KeyCode.Home,
		End = Enum.KeyCode.End,
		Up = Enum.KeyCode.Up,
		Down = Enum.KeyCode.Down,
		Left = Enum.KeyCode.Left,
		Right = Enum.KeyCode.Right,
		A = Enum.KeyCode.ButtonA,
		B = Enum.KeyCode.ButtonB,
		X = Enum.KeyCode.ButtonX,
		Y = Enum.KeyCode.ButtonY,
		L1 = Enum.KeyCode.ButtonL1,
		R1 = Enum.KeyCode.ButtonR1,
		L2 = Enum.KeyCode.ButtonL2,
		R2 = Enum.KeyCode.ButtonR2,
		L3 = Enum.KeyCode.ButtonL3,
		R3 = Enum.KeyCode.ButtonR3,
		["◀"] = Enum.KeyCode.DPadLeft,
		["▶"] = Enum.KeyCode.DPadRight,
		["▲"] = Enum.KeyCode.DPadUp,
		["▼"] = Enum.KeyCode.DPadDown,
		LS = Enum.KeyCode.Thumbstick1,
		RS = Enum.KeyCode.Thumbstick2
	};
	if r[t] then
		return r[t];
	end;
	if #t == 1 and t:match("%a") and Enum.KeyCode[t:upper()] then
		return Enum.KeyCode[t:upper()];
	end;
	if Enum.KeyCode[t] then
		return Enum.KeyCode[t];
	end;
	return nil;
end;
local curTheme, selectMode = "Dark", false;
local rainbowOn, rainbowConn, hue = false, nil, 0;
local activeKeys = {};
local function setBase(btn, col)
	btn:SetAttribute("BaseColor", col);
	btn.BackgroundColor3 = col;
	btn.TextColor3 = lum(col) > 0.6 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1);
end;
local function pressConn(btn, kc)
	local down = false;
	btn.MouseButton1Down:Connect(function()
		local base = btn:GetAttribute("BaseColor") or themes[curTheme].Btn;
		btn.BackgroundColor3 = shade(base, -0.25);
		down = true;
		if kc and (not selectMode) then
			vim:SendKeyEvent(true, kc, false, game);
		end;
	end);
	btn.MouseButton1Up:Connect(function()
		down = false;
		local base = btn:GetAttribute("BaseColor") or themes[curTheme].Btn;
		btn.BackgroundColor3 = base;
		if kc and (not selectMode) then
			vim:SendKeyEvent(false, kc, false, game);
		end;
	end);
	btn.MouseLeave:Connect(function()
		if down and kc and (not selectMode) then
			vim:SendKeyEvent(false, kc, false, game);
			down = false;
			local base = btn:GetAttribute("BaseColor") or themes[curTheme].Btn;
			btn.BackgroundColor3 = base;
		end;
	end);
end;
local function makeDrag(obj, handle)
	local dragging, dInput, start, startPos = false, nil, nil, nil;
	handle.Active = true;
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true;
			start = input.Position;
			startPos = obj.Position;
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false;
				end;
			end);
		end;
	end);
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dInput = input;
		end;
	end);
	uis.InputChanged:Connect(function(input)
		if input == dInput and dragging then
			local delta = input.Position - start;
			obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y);
		end;
	end);
end;
local function makeFloatKey(lbl, kc)
	local size = IsOnMobile and 72 or 64;
	local wrap = Instance.new("Frame");
	wrap.Name = "Float_" .. lbl;
	wrap.Size = UDim2.new(0, size, 0, size);
	wrap.Position = UDim2.new(0.5, (-size) / 2, 0.5, (-size) / 2);
	wrap.BackgroundTransparency = 1;
	wrap.ZIndex = 100;
	wrap.Parent = ui;
	local keyBtn = Instance.new("TextButton");
	keyBtn.Name = "Key";
	keyBtn.Size = UDim2.new(1, 0, 1, 0);
	keyBtn.Position = UDim2.new(0, 0, 0, 0);
	keyBtn.Text = lbl;
	keyBtn.TextScaled = true;
	local tsz = Instance.new("UITextSizeConstraint", keyBtn);
	tsz.MaxTextSize = 28;
	tsz.MinTextSize = 12;
	keyBtn.Font = Enum.Font.SourceSansBold;
	keyBtn.BorderSizePixel = 0;
	keyBtn.ZIndex = 101;
	keyBtn.Parent = wrap;
	local ic = Instance.new("UICorner");
	ic.CornerRadius = UDim.new(0.4, 0);
	ic.Parent = keyBtn;
	local st = Instance.new("UIStroke");
	st.Thickness = 2;
	st.Color = Color3.fromRGB(0, 0, 0);
	st.Transparency = 0.45;
	st.Parent = keyBtn;
	setBase(keyBtn, themes[curTheme] and themes[curTheme].Btn or Color3.fromRGB(60, 60, 60));
	pressConn(keyBtn, kc);
	local dragOverlay = Instance.new("Frame");
	dragOverlay.Size = UDim2.new(1, 0, 1, 0);
	dragOverlay.BackgroundTransparency = 1;
	dragOverlay.ZIndex = 102;
	dragOverlay.Parent = wrap;
	local close = Instance.new("TextButton");
	close.Name = "Close";
	close.Size = UDim2.new(0, 22, 0, 22);
	close.Position = UDim2.new(1, -10, 0, -10);
	close.BackgroundColor3 = Color3.fromRGB(200, 60, 60);
	close.Text = "×";
	close.TextScaled = true;
	local cts = Instance.new("UITextSizeConstraint", close);
	cts.MaxTextSize = 16;
	cts.MinTextSize = 10;
	close.Font = Enum.Font.SourceSansBold;
	close.TextColor3 = Color3.fromRGB(255, 255, 255);
	close.ZIndex = 103;
	close.Parent = wrap;
	local cc = Instance.new("UICorner");
	cc.CornerRadius = UDim.new(0, 10);
	cc.Parent = close;
	makeDrag(wrap, dragOverlay);
	makeDrag(wrap, keyBtn);
	close.MouseButton1Click:Connect(function()
		if wrap then
			wrap:Destroy();
		end;
	end);
end;
local function makeKey(t)
	local kc = kcFromLabel(t);
	local b = Instance.new("TextButton");
	b.Name = "Key_" .. t;
	b.Text = t;
	b.TextScaled = true;
	local cst = Instance.new("UITextSizeConstraint", b);
	cst.MaxTextSize = 18;
	cst.MinTextSize = 10;
	b.Font = Enum.Font.SourceSans;
	b.AutoButtonColor = true;
	b.BorderSizePixel = 0;
	local cor = Instance.new("UICorner");
	cor.CornerRadius = UDim.new(0, 8);
	cor.Parent = b;
	setBase(b, themes[curTheme].Btn);
	pressConn(b, kc);
	b.MouseButton1Click:Connect(function()
		if selectMode then
			makeFloatKey(t, kc);
			selectMode = false;
			addBtn.BackgroundColor3 = rainbowOn and Color3.fromHSV(hue, 0.85, 1) or themes[curTheme].Acc;
		end;
	end);
	table.insert(activeKeys, b);
	return b;
end;
local function spacer(w)
	local f = Instance.new("Frame");
	f.BackgroundTransparency = 1;
	return {
		f,
		w or 1
	};
end;
local function clearKeys()
	activeKeys = {};
	for _, c in ipairs(keysScroll:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy();
		end;
	end;
end;
local function newRow(h, order)
	local r = Instance.new("Frame");
	r.BackgroundTransparency = 1;
	r.Size = UDim2.new(1, 0, 0, h);
	r.LayoutOrder = order or 0;
	r.Parent = keysScroll;
	local hl = Instance.new("UIListLayout");
	hl.FillDirection = Enum.FillDirection.Horizontal;
	hl.Padding = UDim.new(0, 8);
	hl.SortOrder = Enum.SortOrder.LayoutOrder;
	hl.HorizontalAlignment = Enum.HorizontalAlignment.Left;
	hl.Parent = r;
	return r;
end;
local function addWeighted(r, items)
	local pad, tot = 8, 0;
	for _, it in ipairs(items) do
		tot += typeof(it) == "table" and it[2] or 1;
	end;
	local i = 1;
	for _, it in ipairs(items) do
		local inst, w;
		if typeof(it) == "table" then
			inst, w = typeof(it[1]) == "Instance" and it[1] or makeKey(it[1]), it[2] or 1;
		elseif typeof(it) == "Instance" then
			inst, w = it, 1;
		else
			inst, w = makeKey(it), 1;
		end;
		inst.Size = UDim2.new(w / tot, -pad, 1, 0);
		inst.LayoutOrder = i;
		i += 1;
		inst.Parent = r;
	end;
end;
local function layQWERTY()
	clearKeys();
	local rows, h = 6, math.max(28, math.floor((keysScroll.AbsoluteSize.Y - (6 - 1) * 8) / 6));
	local r1 = newRow(h, 1);
	addWeighted(r1, {
		{
			"Esc",
			1
		},
		"F1",
		"F2",
		"F3",
		"F4",
		"F5",
		"F6",
		"F7",
		"F8",
		"F9",
		"F10",
		"F11",
		"F12"
	});
	local r2 = newRow(h, 2);
	addWeighted(r2, {
		"`",
		"1",
		"2",
		"3",
		"4",
		"5",
		"6",
		"7",
		"8",
		"9",
		"0",
		"-",
		"=",
		{
			"Bksp",
			2
		}
	});
	local r3 = newRow(h, 3);
	addWeighted(r3, {
		{
			"Tab",
			1.5
		},
		"Q",
		"W",
		"E",
		"R",
		"T",
		"Y",
		"U",
		"I",
		"O",
		"P",
		"[",
		"]",
		"\\"
	});
	local r4 = newRow(h, 4);
	addWeighted(r4, {
		{
			"Caps",
			1.75
		},
		"A",
		"S",
		"D",
		"F",
		"G",
		"H",
		"J",
		"K",
		"L",
		";",
		"'",
		{
			"Enter",
			2.25
		}
	});
	local r5 = newRow(h, 5);
	addWeighted(r5, {
		{
			"LShift",
			2.25
		},
		"Z",
		"X",
		"C",
		"V",
		"B",
		"N",
		"M",
		",",
		".",
		"/",
		{
			"RShift",
			2.25
		}
	});
	local r6 = newRow(h, 6);
	addWeighted(r6, {
		{
			"LAlt",
			1.25
		},
		{
			"LCtrl",
			1.5
		},
		{
			"LWin",
			1.25
		},
		{
			"Space",
			6
		},
		{
			"RAlt",
			1.25
		},
		{
			"RWin",
			1.25
		},
		{
			"RCtrl",
			1.5
		}
	});
end;
local function layFunction()
	clearKeys();
	local rows, h = 2, math.max(28, math.floor((keysScroll.AbsoluteSize.Y - (2 - 1) * 8) / 2));
	local r1 = newRow(h, 1);
	addWeighted(r1, {
		{
			"Esc",
			1
		},
		"F1",
		"F2",
		"F3",
		"F4",
		"F5",
		"F6",
		"F7",
		"F8",
		"F9",
		"F10",
		"F11",
		"F12"
	});
	local r2 = newRow(h, 2);
	addWeighted(r2, {
		"PrtSc",
		"ScrLk",
		"Pause"
	});
end;
local function layNav()
	clearKeys();
	local rows, h = 2, math.max(28, math.floor((keysScroll.AbsoluteSize.Y - (2 - 1) * 8) / 2));
	local r1 = newRow(h, 1);
	addWeighted(r1, {
		"Ins",
		"Home",
		"PgUp"
	});
	local r2 = newRow(h, 2);
	addWeighted(r2, {
		"Del",
		"End",
		"PgDn"
	});
end;
local function layArrows()
	clearKeys();
	local rows, h = 2, math.max(28, math.floor((keysScroll.AbsoluteSize.Y - (2 - 1) * 8) / 2));
	local rt = newRow(h, 1);
	addWeighted(rt, {
		spacer(1),
		{
			"Up",
			1
		},
		spacer(1)
	});
	local rb = newRow(h, 2);
	addWeighted(rb, {
		"Left",
		"Down",
		"Right"
	});
end;
local function layConsole()
	clearKeys();
	local rows, h = 5, math.max(28, math.floor((keysScroll.AbsoluteSize.Y - (5 - 1) * 8) / 5));
	local r1 = newRow(h, 1);
	addWeighted(r1, {
		{
			"L1",
			1
		},
		spacer(8),
		{
			"R1",
			1
		}
	});
	local r2 = newRow(h, 2);
	addWeighted(r2, {
		{
			"L2",
			1
		},
		spacer(8),
		{
			"R2",
			1
		}
	});
	local r3 = newRow(h, 3);
	addWeighted(r3, {
		spacer(2),
		{
			"▲",
			1
		},
		spacer(5),
		{
			"Y",
			1
		},
		spacer(2)
	});
	local r4 = newRow(h, 4);
	addWeighted(r4, {
		{
			"◀",
			1
		},
		{
			"▼",
			1
		},
		{
			"▶",
			1
		},
		spacer(3),
		{
			"X",
			1
		},
		{
			"A",
			1
		},
		{
			"B",
			1
		}
	});
	local r5 = newRow(h, 5);
	addWeighted(r5, {
		{
			"LS",
			1
		},
		{
			"L3",
			1
		},
		spacer(4),
		{
			"R3",
			1
		},
		{
			"RS",
			1
		}
	});
end;
local function layAll()
	clearKeys();
	local per, h = IsOnMobile and 12 or 16, 32;
	local items = Enum.KeyCode:GetEnumItems();
	local row, count = nil, 0;
	for _, kc in ipairs(items) do
		if kc ~= Enum.KeyCode.Unknown then
			if count % per == 0 then
				row = newRow(h, 100 + math.floor(count / per));
			end;
			local lbl = labelFromKC(kc);
			local k = makeKey(lbl);
			k.Size = UDim2.new(1 / per, -8, 1, 0);
			k.LayoutOrder = count % per + 1;
			k.Parent = row;
			count += 1;
		end;
	end;
end;
local sections = {
	"QWERTY",
	"Function",
	"Navigation",
	"Arrows",
	"Console",
	"All"
};
local curSection = "QWERTY";
local function applyScheme(s)
	mainFrm.BackgroundColor3 = s.Bg;
	titleBar.BackgroundColor3 = s.Btn;
	toggleBtn.BackgroundColor3 = s.Btn;
	toggleBtn.TextColor3 = s.Txt;
	themeBtn.BackgroundColor3 = s.Btn;
	themeBtn.TextColor3 = s.Txt;
	modeBtn.BackgroundColor3 = s.Btn;
	modeBtn.TextColor3 = s.Txt;
	colorBtn.BackgroundColor3 = s.Btn;
	colorBtn.TextColor3 = s.Txt;
	rgbBtn.BackgroundColor3 = shade(s.Acc, 0.2);
	rgbBtn.TextColor3 = s.Txt;
	addBtn.BackgroundColor3 = selectMode and Color3.fromRGB(180, 60, 60) or s.Acc;
	addBtn.TextColor3 = s.Txt;
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60);
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255);
	titleLbl.TextColor3 = s.Txt;
	for _, k in ipairs(activeKeys) do
		setBase(k, s.Btn);
	end;
end;
local function refreshTheme()
	if rainbowOn then
		local base = Color3.fromHSV(hue, 0.85, 1);
		local s = {
			Bg = shade(base, -0.65),
			Btn = shade(base, -0.25),
			Acc = base,
			Txt = lum(shade(base, -0.25)) > 0.6 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
		};
		applyScheme(s);
	else
		local s = themes[curTheme] or themes.Dark;
		applyScheme(s);
	end;
end;
local function render()
	if curSection == "QWERTY" then
		layQWERTY();
	elseif curSection == "Function" then
		layFunction();
	elseif curSection == "Navigation" then
		layNav();
	elseif curSection == "Arrows" then
		layArrows();
	elseif curSection == "Console" then
		layConsole();
	elseif curSection == "All" then
		layAll();
	end;
	refreshTheme();
end;
local function setTheme(name)
	if name == "Custom" and themes.Custom then
		curTheme = "Custom";
	elseif themes[name] then
		curTheme = name;
	else
		curTheme = "Dark";
	end;
	themeBtn.Text = curTheme;
	refreshTheme();
end;
local function startRainbow()
	if rainbowConn then
		rainbowConn:Disconnect();
		rainbowConn = nil;
	end;
	rainbowConn = rs.RenderStepped:Connect(function(dt)
		hue = (hue + dt * 0.08) % 1;
		refreshTheme();
	end);
end;
local function stopRainbow()
	if rainbowConn then
		rainbowConn:Disconnect();
		rainbowConn = nil;
	end;
	refreshTheme();
end;
themeBtn.MouseButton1Click:Connect(function()
	local opts = {
		"Dark",
		"Light",
		"Blue",
		"Purple",
		"Green"
	};
	local i = table.find(opts, themeBtn.Text) or table.find(opts, curTheme) or 1;
	setTheme(opts[i % (#opts) + 1]);
end);
rgbBtn.MouseButton1Click:Connect(function()
	rainbowOn = not rainbowOn;
	if rainbowOn then
		if rainbowConn then
			rainbowConn:Disconnect();
		end;
		rainbowConn = rs.RenderStepped:Connect(function(dt)
			hue = (hue + dt * 0.08) % 1;
			refreshTheme();
		end);
	else
		if rainbowConn then
			rainbowConn:Disconnect();
			rainbowConn = nil;
		end;
		refreshTheme();
	end;
	rgbBtn.Text = rainbowOn and "Rainbow ✓" or "Rainbow";
end);
modeBtn.MouseButton1Click:Connect(function()
	local i = table.find(sections, curSection) or 1;
	curSection = sections[i % (#sections) + 1];
	modeBtn.Text = curSection;
	render();
end);
local function makeDragBtn(f)
	makeDrag(f, f);
end;
makeDrag(mainFrm, titleBar);
makeDragBtn(toggleBtn);
addBtn.MouseButton1Click:Connect(function()
	selectMode = not selectMode;
	addBtn.BackgroundColor3 = selectMode and Color3.fromRGB(180, 60, 60) or (rainbowOn and Color3.fromHSV(hue, 0.85, 1) or themes[curTheme].Acc);
end);
closeBtn.MouseButton1Click:Connect(function()
	if rainbowConn then
		rainbowConn:Disconnect();
	end;
	ui:Destroy();
end);
toggleBtn.MouseButton1Click:Connect(function()
	mainFrm.Visible = not mainFrm.Visible;
	local acc = rainbowOn and Color3.fromHSV(hue, 0.85, 1) or themes[curTheme].Acc;
	toggleBtn.BackgroundColor3 = mainFrm.Visible and shade(acc, 0.1) or (rainbowOn and shade(acc, (-0.25)) or themes[curTheme].Btn);
end);
(keysScroll:GetPropertyChangedSignal("AbsoluteSize")):Connect(render);
local palette = Instance.new("Frame");
palette.Name = "Palette";
palette.Size = UDim2.new(0, 280, 0, 180);
palette.Position = UDim2.new(1, -330, 0, 34);
palette.BackgroundColor3 = themes.Dark.Bg;
palette.Visible = false;
palette.Parent = mainFrm;
local pc = Instance.new("UICorner");
pc.CornerRadius = UDim.new(0, 10);
pc.Parent = palette;
local pg = Instance.new("UIGridLayout");
pg.CellPadding = UDim2.new(0, 6, 0, 6);
pg.CellSize = UDim2.new(0, 64, 0, 28);
pg.FillDirectionMaxCells = 4;
pg.Parent = palette;
local namedColors = {
	{
		"Red",
		Color3.fromRGB(220, 70, 70)
	},
	{
		"Orange",
		Color3.fromRGB(245, 140, 60)
	},
	{
		"Amber",
		Color3.fromRGB(240, 180, 70)
	},
	{
		"Yellow",
		Color3.fromRGB(250, 220, 90)
	},
	{
		"Lime",
		Color3.fromRGB(170, 220, 60)
	},
	{
		"Green",
		Color3.fromRGB(60, 200, 120)
	},
	{
		"Teal",
		Color3.fromRGB(50, 200, 200)
	},
	{
		"Cyan",
		Color3.fromRGB(60, 200, 250)
	},
	{
		"Sky",
		Color3.fromRGB(90, 170, 255)
	},
	{
		"Blue",
		Color3.fromRGB(90, 130, 255)
	},
	{
		"Indigo",
		Color3.fromRGB(100, 110, 255)
	},
	{
		"Violet",
		Color3.fromRGB(150, 100, 255)
	},
	{
		"Purple",
		Color3.fromRGB(180, 100, 255)
	},
	{
		"Magenta",
		Color3.fromRGB(220, 90, 220)
	},
	{
		"Pink",
		Color3.fromRGB(255, 120, 160)
	},
	{
		"Brown",
		Color3.fromRGB(150, 100, 70)
	},
	{
		"Slate",
		Color3.fromRGB(110, 120, 140)
	},
	{
		"Silver",
		Color3.fromRGB(210, 210, 220)
	},
	{
		"Dark",
		Color3.fromRGB(60, 60, 70)
	},
	{
		"Black",
		Color3.fromRGB(0, 0, 0)
	},
	{
		"White",
		Color3.fromRGB(255, 255, 255)
	}
};
local function applyBaseColor(base)
	if rainbowConn then
		rainbowConn:Disconnect();
		rainbowConn = nil;
	end;
	rainbowOn = false;
	hue = 0;
	local s = {
		Bg = shade(base, -0.65),
		Btn = shade(base, -0.25),
		Acc = base,
		Txt = lum(shade(base, -0.25)) > 0.6 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
	};
	themes.Custom = s;
	setTheme("Custom");
end;
for _, pair in ipairs(namedColors) do
	local n, c = pair[1], pair[2];
	local sw = Instance.new("TextButton");
	sw.Text = n;
	sw.TextScaled = true;
	local sct = Instance.new("UITextSizeConstraint", sw);
	sct.MaxTextSize = 14;
	sct.MinTextSize = 10;
	sw.Font = Enum.Font.SourceSansBold;
	sw.BackgroundColor3 = c;
	sw.TextColor3 = lum(c) > 0.6 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1);
	sw.Parent = palette;
	local sc = Instance.new("UICorner");
	sc.CornerRadius = UDim.new(0, 6);
	sc.Parent = sw;
	sw.MouseButton1Click:Connect(function()
		applyBaseColor(c);
		palette.Visible = false;
	end);
end;
colorBtn.MouseButton1Click:Connect(function()
	palette.Visible = not palette.Visible;
end);
setTheme("Dark");
render();
