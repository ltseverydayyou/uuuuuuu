local theme = {
	bg = Color3.fromRGB(16, 17, 20),
	ac = Color3.fromRGB(26, 27, 31),
	sc = Color3.fromRGB(32, 34, 38),
	tx = Color3.fromRGB(235, 238, 245),
	td = Color3.fromRGB(164, 170, 186),
	br = Color3.fromRGB(58, 60, 66),
	ban_ac = Color3.fromRGB(56, 26, 30),
	ban_st = Color3.fromRGB(200, 64, 72),
	ver_ac = Color3.fromRGB(28, 36, 54),
	ver_st = Color3.fromRGB(64, 132, 255),
	toast = Color3.fromRGB(32, 36, 44),
	ok = Color3.fromRGB(48, 180, 120)
};
local function svc(n)
	local g = game.GetService;
	local r = cloneref or function(x)
		return x;
	end;
	return r(g(game, n));
end;
local IsOnMobile = (function()
	local platform = (svc("UserInputService")):GetPlatform();
	if platform == Enum.Platform.IOS or platform == Enum.Platform.Android or platform == Enum.Platform.AndroidTV or platform == Enum.Platform.Chromecast or platform == Enum.Platform.MetaOS then
		return true;
	end;
	if platform == Enum.Platform.None then
		return (svc("UserInputService")).TouchEnabled and (not ((svc("UserInputService")).KeyboardEnabled or (svc("UserInputService")).MouseEnabled));
	end;
	return false;
end)();
local Tween = svc("TweenService");
local Json = svc("HttpService");
local UIS = svc("UserInputService");
local Players = svc("Players");
local LP = Players.LocalPlayer;
local gui = Instance.new("ScreenGui");
gui.Name = "\000";
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
gui.DisplayOrder = 2147483647;
gui.ResetOnSpawn = false;
gui.IgnoreGuiInset = true;
if gethui then
	gui.Parent = gethui();
else
	gui.Parent = svc("CoreGui");
end;
local function mkText(p, t, c, max)
	local l = Instance.new("TextLabel");
	l.BackgroundTransparency = 1;
	l.Text = t or "";
	l.Font = Enum.Font.Gotham;
	l.TextColor3 = c or theme.tx;
	l.TextXAlignment = Enum.TextXAlignment.Left;
	l.TextYAlignment = Enum.TextYAlignment.Top;
	l.TextWrapped = true;
	l.TextScaled = true;
	local s = Instance.new("UITextSizeConstraint");
	s.MaxTextSize = max or 18;
	s.MinTextSize = 10;
	s.Parent = l;
	l.Parent = p;
	return l;
end;
local function mkBtn(t)
	local b = Instance.new("TextButton");
	b.AutoButtonColor = false;
	b.Size = UDim2.fromOffset(40, 40);
	b.BackgroundColor3 = theme.sc;
	b.Text = t;
	b.Font = Enum.Font.GothamBold;
	b.TextColor3 = theme.tx;
	b.TextScaled = true;
	local s = Instance.new("UITextSizeConstraint");
	s.MaxTextSize = 22;
	s.Parent = b;
	local c = Instance.new("UICorner");
	c.CornerRadius = UDim.new(0, 8);
	c.Parent = b;
	local st = Instance.new("UIStroke");
	st.Color = theme.br;
	st.Transparency = 0.55;
	st.Thickness = 1;
	st.Parent = b;
	return b;
end;
local function flash(b, col)
	local o = b.BackgroundColor3;
	(Tween:Create(b, TweenInfo.new(0.08), {
		BackgroundColor3 = col
	})):Play();
	task.delay(0.18, function()
		(Tween:Create(b, TweenInfo.new(0.18), {
			BackgroundColor3 = o
		})):Play();
	end);
end;
local root = Instance.new("Frame");
root.AnchorPoint = Vector2.new(0.5, 0.5);
root.Position = UDim2.fromScale(0.5, 0.5);
root.Size = UDim2.fromScale(0.96, 0.9);
root.BackgroundColor3 = theme.bg;
root.BorderSizePixel = 0;
root.Parent = gui;
(Instance.new("UICorner", root)).CornerRadius = UDim.new(0, 14);
local rst = Instance.new("UIStroke", root);
rst.Color = theme.br;
rst.Transparency = 0.4;
rst.Thickness = 1;
local top = Instance.new("Frame");
top.Size = UDim2.new(1, 0, 0, 64);
top.BackgroundColor3 = theme.ac;
top.Parent = root;
(Instance.new("UICorner", top)).CornerRadius = UDim.new(0, 14);
local function drag(ui, h)
	h = h or ui;
	local dragging, startPos, startUD;
	h.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true;
			startPos = i.Position;
			startUD = ui.Position;
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					dragging = false;
				end;
			end);
		end;
	end);
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startPos;
			ui.Position = UDim2.new(startUD.X.Scale, startUD.X.Offset + d.X, startUD.Y.Scale, startUD.Y.Offset + d.Y);
		end;
	end);
	ui.Active = true;
end;
drag(root, top);
local title = mkText(top, "User Search", theme.tx, 34);
title.Position = UDim2.new(0, 16, 0, 10);
title.Size = UDim2.new(0.33, 0, 1, -20);
local statusLbl = mkText(top, "", theme.td, 20);
statusLbl.Position = UDim2.new(0.34, 0, 0, 12);
statusLbl.Size = UDim2.new(0.3, 0, 1, -24);
local actions = Instance.new("Frame");
actions.BackgroundTransparency = 1;
actions.Size = UDim2.new(0, 640, 1, 0);
actions.Position = UDim2.new(1, -652, 0, 0);
actions.Parent = top;
local aList = Instance.new("UIListLayout", actions);
aList.FillDirection = Enum.FillDirection.Horizontal;
aList.Padding = UDim.new(0, 8);
aList.HorizontalAlignment = Enum.HorizontalAlignment.Right;
aList.VerticalAlignment = Enum.VerticalAlignment.Center;
local searchBox = Instance.new("TextBox");
searchBox.Size = UDim2.fromOffset(380, 42);
searchBox.BackgroundColor3 = theme.sc;
searchBox.TextColor3 = theme.tx;
searchBox.PlaceholderText = "search username or id";
searchBox.PlaceholderColor3 = theme.td;
searchBox.Font = Enum.Font.Gotham;
searchBox.TextXAlignment = Enum.TextXAlignment.Left;
searchBox.TextWrapped = true;
searchBox.Text = "";
searchBox.TextSize = 24;
searchBox.TextScaled = false;
(Instance.new("UICorner", searchBox)).CornerRadius = UDim.new(0, 8);
(Instance.new("UIPadding", searchBox)).PaddingLeft = UDim.new(0, 10);
searchBox.Parent = actions;
local btnWear = mkBtn("WEAR");
btnWear.Parent = actions;
local btnSearch = mkBtn("🔎");
btnSearch.Parent = actions;
local btnClose = mkBtn("X");
btnClose.Parent = actions;
searchBox.Focused:Connect(function()
	searchBox.TextScaled = false;
	searchBox.TextSize = 24;
end);
searchBox.FocusLost:Connect(function()
	searchBox.TextScaled = true;
end);
local main = Instance.new("Frame");
main.BackgroundTransparency = 1;
main.Position = UDim2.new(0, 0, 0, 64);
main.Size = UDim2.new(1, 0, 1, -64);
main.Parent = root;
local left = Instance.new("Frame");
left.BackgroundColor3 = theme.ac;
left.Parent = main;
local leftStroke = Instance.new("UIStroke", left);
leftStroke.Color = theme.br;
leftStroke.Transparency = 0.5;
leftStroke.Thickness = 1;
local results = Instance.new("ScrollingFrame");
results.BackgroundTransparency = 1;
results.Size = UDim2.new(1, 0, 1, 0);
results.CanvasSize = UDim2.new();
results.ScrollBarThickness = 6;
results.ScrollBarImageColor3 = Color3.fromRGB(100, 102, 110);
results.Parent = left;
local rPad = Instance.new("UIPadding", results);
rPad.PaddingLeft = UDim.new(0, 10);
rPad.PaddingRight = UDim.new(0, 10);
rPad.PaddingTop = UDim.new(0, 10);
rPad.PaddingBottom = UDim.new(0, 10);
local rList = Instance.new("UIListLayout", results);
rList.SortOrder = Enum.SortOrder.LayoutOrder;
rList.Padding = UDim.new(0, 8);
(rList:GetPropertyChangedSignal("AbsoluteContentSize")):Connect(function()
	results.CanvasSize = UDim2.new(0, 0, 0, rList.AbsoluteContentSize.Y + 20);
end);
local right = Instance.new("Frame");
right.BackgroundTransparency = 1;
right.Parent = main;
local header = Instance.new("Frame");
header.BackgroundColor3 = theme.ac;
header.Size = UDim2.new(1, -20, 0, 316);
header.Position = UDim2.new(0, 10, 0, 10);
header.Parent = right;
local hSt = Instance.new("UIStroke", header);
hSt.Color = theme.br;
hSt.Transparency = 0.5;
hSt.Thickness = 1;
(Instance.new("UICorner", header)).CornerRadius = UDim.new(0, 10);
local headImg = Instance.new("ImageLabel");
headImg.BackgroundColor3 = theme.sc;
headImg.Size = UDim2.fromOffset(120, 120);
headImg.Position = UDim2.new(0, 12, 0, 12);
headImg.Image = "rbxassetid://0";
headImg.Parent = header;
(Instance.new("UICorner", headImg)).CornerRadius = UDim.new(0, 10);
local headVP = Instance.new("ViewportFrame");
headVP.BackgroundColor3 = theme.sc;
headVP.Visible = false;
headVP.Size = headImg.Size;
headVP.Position = headImg.Position;
headVP.Parent = header;
headVP.Ambient = Color3.fromRGB(240, 240, 240);
headVP.LightColor = Color3.fromRGB(255, 255, 255);
local headWM = Instance.new("WorldModel", headVP);
local nameRow = Instance.new("Frame");
nameRow.BackgroundTransparency = 1;
nameRow.Position = UDim2.new(0, 144, 0, 12);
nameRow.Size = UDim2.new(1, -156, 0, 40);
nameRow.Parent = header;
local disp = mkText(nameRow, "Display Name", theme.tx, 28);
disp.Size = UDim2.new(0.62, 0, 1, 0);
local btnCopyDN = mkBtn("COPY");
btnCopyDN.Size = UDim2.new(0, 90, 0, 34);
btnCopyDN.Position = UDim2.new(1, -284, 0, 3);
btnCopyDN.Parent = nameRow;
local tagRow = Instance.new("Frame");
tagRow.BackgroundTransparency = 1;
tagRow.Position = UDim2.new(0, 144, 0, 56);
tagRow.Size = UDim2.new(1, -156, 0, 34);
tagRow.Parent = header;
local handle = mkText(tagRow, "@username • ID: -", theme.td, 18);
handle.Size = UDim2.new(0.62, 0, 1, 0);
local btnCopyUN = mkBtn("COPY");
btnCopyUN.Size = UDim2.new(0, 90, 0, 34);
btnCopyUN.Position = UDim2.new(1, -284, 0, 0);
btnCopyUN.Parent = tagRow;
local prevBox = Instance.new("Frame");
prevBox.BackgroundTransparency = 1;
prevBox.Position = UDim2.new(0, 144, 0, 98);
prevBox.Size = UDim2.new(1, -156, 0, 200);
prevBox.Parent = header;
local fullBox = Instance.new("Frame");
fullBox.BackgroundColor3 = theme.sc;
fullBox.Size = UDim2.new(0.5, -6, 1, 0);
fullBox.Position = UDim2.new(0, 0, 0, 0);
fullBox.Parent = prevBox;
(Instance.new("UICorner", fullBox)).CornerRadius = UDim.new(0, 8);
local fullImg = Instance.new("ImageLabel");
fullImg.BackgroundTransparency = 1;
fullImg.AnchorPoint = Vector2.new(0.5, 0.5);
fullImg.Position = UDim2.fromScale(0.5, 0.5);
fullImg.Size = UDim2.fromScale(1, 1);
fullImg.Image = "rbxassetid://0";
fullImg.Parent = fullBox;
(Instance.new("UIAspectRatioConstraint", fullImg)).AspectRatio = 1;
local view = Instance.new("ViewportFrame");
view.BackgroundColor3 = theme.sc;
view.Size = UDim2.new(0.5, -6, 1, 0);
view.Position = UDim2.new(0.5, 12, 0, 0);
view.BorderSizePixel = 0;
view.Parent = prevBox;
(Instance.new("UICorner", view)).CornerRadius = UDim.new(0, 8);
view.Ambient = Color3.fromRGB(240, 240, 240);
view.LightColor = Color3.fromRGB(255, 255, 255);
local world = Instance.new("WorldModel", view);
local infoList = Instance.new("ScrollingFrame");
infoList.BackgroundTransparency = 1;
infoList.Position = UDim2.new(0, 10, 0, 336);
infoList.Size = UDim2.new(1, -20, 1, -346);
infoList.CanvasSize = UDim2.new();
infoList.ScrollBarThickness = 6;
infoList.ScrollBarImageColor3 = Color3.fromRGB(100, 102, 110);
infoList.Parent = right;
local il = Instance.new("UIListLayout", infoList);
il.SortOrder = Enum.SortOrder.LayoutOrder;
il.Padding = UDim.new(0, 10);
(il:GetPropertyChangedSignal("AbsoluteContentSize")):Connect(function()
	infoList.CanvasSize = UDim2.new(0, 0, 0, il.AbsoluteContentSize.Y + 10);
end);
local toast = Instance.new("TextLabel");
toast.BackgroundColor3 = theme.toast;
toast.TextColor3 = theme.tx;
toast.Font = Enum.Font.Gotham;
toast.TextScaled = true;
toast.Text = "";
toast.Visible = false;
toast.AnchorPoint = Vector2.new(1, 1);
toast.Size = UDim2.fromOffset(520, 72);
toast.Position = UDim2.fromScale(0.995, 0.985);
toast.Parent = root;
(Instance.new("UICorner", toast)).CornerRadius = UDim.new(0, 10);
local tsc = Instance.new("UITextSizeConstraint", toast);
tsc.MaxTextSize = 28;
local tp1 = Instance.new("UIPadding", toast);
local tp2 = Instance.new("UIPadding", toast);
local tp3 = Instance.new("UIPadding", toast);
local tp4 = Instance.new("UIPadding", toast);
tp1.PaddingLeft = UDim.new(0, 16);
tp2.PaddingRight = UDim.new(0, 16);
tp3.PaddingTop = UDim.new(0, 12);
tp4.PaddingBottom = UDim.new(0, 12);
local function notify(m)
	toast.Text = m;
	toast.Visible = true;
	toast.BackgroundTransparency = 1;
	toast.TextTransparency = 1;
	(Tween:Create(toast, TweenInfo.new(0.18), {
		BackgroundTransparency = 0.06,
		TextTransparency = 0
	})):Play();
	task.delay(1.35, function()
		(Tween:Create(toast, TweenInfo.new(0.22), {
			BackgroundTransparency = 1,
			TextTransparency = 1
		})):Play();
		task.wait(0.24);
		toast.Visible = false;
	end);
end;
local function section(t)
	local f = Instance.new("Frame");
	f.BackgroundColor3 = theme.ac;
	f.Size = UDim2.new(1, -20, 0, 90);
	f.Position = UDim2.new(0, 10, 0, 0);
	f.BorderSizePixel = 0;
	f.Parent = infoList;
	(Instance.new("UICorner", f)).CornerRadius = UDim.new(0, 10);
	local st = Instance.new("UIStroke", f);
	st.Thickness = 1;
	st.Transparency = 0.45;
	st.Color = theme.br;
	local ttl = mkText(f, t, theme.tx, 20);
	ttl.Position = UDim2.new(0, 10, 0, 8);
	ttl.Size = UDim2.new(1, -20, 0, 24);
	local holder = Instance.new("Frame");
	holder.BackgroundTransparency = 1;
	holder.Position = UDim2.new(0, 10, 0, 40);
	holder.Size = UDim2.new(1, -20, 0, 10);
	holder.AutomaticSize = Enum.AutomaticSize.Y;
	holder.Parent = f;
	local l = Instance.new("UIListLayout", holder);
	l.SortOrder = Enum.SortOrder.LayoutOrder;
	l.Padding = UDim.new(0, 8);
	local function fit()
		f.Size = UDim2.new(1, -20, 0, math.max(90, 40 + l.AbsoluteContentSize.Y + 10));
	end;
	(l:GetPropertyChangedSignal("AbsoluteContentSize")):Connect(fit);
	task.defer(fit);
	return f, holder;
end;
local function kv(h, k, v)
	local r = Instance.new("Frame");
	r.BackgroundTransparency = 1;
	r.AutomaticSize = Enum.AutomaticSize.Y;
	r.Size = UDim2.new(1, 0, 0, 28);
	r.Parent = h;
	local lk = mkText(r, tostring(k), theme.td, 16);
	lk.Size = UDim2.new(0.28, 0, 0, 24);
	local lv = mkText(r, tostring(v), theme.tx, 16);
	lv.Position = UDim2.new(0.3, 0, 0, 0);
	lv.Size = UDim2.new(0.7, 0, 0, 24);
end;
local function descRow(h, s)
	local r = Instance.new("Frame");
	r.BackgroundTransparency = 1;
	r.Size = UDim2.new(1, 0, 0, 46);
	r.AutomaticSize = Enum.AutomaticSize.Y;
	r.Parent = h;
	local l = Instance.new("TextLabel");
	l.BackgroundTransparency = 1;
	l.Font = Enum.Font.Gotham;
	l.TextColor3 = theme.tx;
	l.TextXAlignment = Enum.TextXAlignment.Left;
	l.TextYAlignment = Enum.TextYAlignment.Top;
	l.TextWrapped = true;
	l.TextScaled = false;
	l.TextSize = 16;
	l.Text = s or "";
	l.Size = UDim2.new(1, -110, 0, 0);
	l.AutomaticSize = Enum.AutomaticSize.Y;
	l.Parent = r;
	local b = mkBtn("COPY");
	b.Size = UDim2.new(0, 90, 0, 32);
	b.Position = UDim2.new(1, -96, 0, 4);
	b.Parent = r;
	b.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard(l.Text);
			flash(b, theme.ok);
			notify("Copied description");
		end;
	end);
end;
local clipboard = setclipboard or toclipboard or clipboard and clipboard.set;
local TryBaseDesc;
do
	local ok, d = pcall(Players.GetHumanoidDescriptionFromUserId, Players, LP.UserId);
	if ok and d then
		TryBaseDesc = d;
	else
		local hum = (LP.Character or LP.CharacterAdded:Wait()):WaitForChild("Humanoid");
		TryBaseDesc = hum:GetAppliedDescription();
	end;
end;
local tryCache = {};
local clothesMap = {
	GraphicTShirt = "ShirtGraphic",
	Shirt = "Shirt",
	Pants = "Pants"
};
local function getHumanoid()
	local ch = LP.Character or LP.CharacterAdded:Wait();
	return ch:WaitForChild("Humanoid"), ch;
end;
local function mapProp(t)
	if t:find("Animation") then
		local x = t:gsub("Animation", "");
		return x .. "Animation";
	end;
	if t == "TShirt" or t == "TShirtGraphic" then
		return "GraphicTShirt";
	end;
	if t == "Hat" then
		return "HatAccessory";
	end;
	return t;
end;
local function applyTry()
	local hum, char = getHumanoid();
	local d = TryBaseDesc:Clone();
	for id, prop in pairs(tryCache) do
		local num = tonumber(id);
		if clothesMap[prop] or prop == "Face" or prop == "Head" or prop == "Torso" or prop == "LeftArm" or prop == "RightArm" or prop == "LeftLeg" or prop == "RightLeg" then
			d[prop] = num;
		elseif prop == "WalkAnimation" or prop == "RunAnimation" or prop == "JumpAnimation" or prop == "FallAnimation" or prop == "ClimbAnimation" or prop == "SwimAnimation" or prop == "IdleAnimation" then
			d[prop] = num;
		else
			local cur = tostring(d[prop] or "");
			local add = tostring(num);
			if cur == "" then
				d[prop] = add;
			else
				d[prop] = cur .. "," .. add;
			end;
		end;
	end;
	for _, prop in pairs(tryCache) do
		local cls = clothesMap[prop];
		if cls then
			for _, inst in ipairs(char:GetChildren()) do
				if inst.ClassName == cls then
					inst:Destroy();
				end;
			end;
		end;
	end;
	if hum.ApplyDescriptionClientServer then
		hum:ApplyDescriptionClientServer(d);
	else
		hum:ApplyDescription(d);
	end;
end;
local function mkItemRow(h, id, name, typ, prop, canTry)
	local row = Instance.new("Frame");
	row.BackgroundTransparency = 1;
	row.Size = UDim2.new(1, 0, 0, 70);
	row.Parent = h;
	local im = Instance.new("ImageLabel");
	im.BackgroundColor3 = theme.sc;
	im.Size = UDim2.fromOffset(48, 48);
	im.Position = UDim2.new(0, 0, 0, 10);
	im.Image = "rbxthumb://type=Asset&id=" .. id .. "&w=150&h=150";
	im.Parent = row;
	(Instance.new("UICorner", im)).CornerRadius = UDim.new(0, 6);
	local nm = mkText(row, (name or "Item") .. "  •  " .. (typ or "Asset"), theme.tx, 16);
	nm.Position = UDim2.new(0, 56, 0, 6);
	nm.Size = UDim2.new(0.5, 0, 0, 26);
	local idLbl = mkText(row, tostring(id), theme.td, 16);
	idLbl.Position = UDim2.new(0.56, 0, 0, 6);
	idLbl.Size = UDim2.new(0.12, 0, 0, 26);
	local btnURL = mkBtn("URL");
	btnURL.AnchorPoint = Vector2.new(1, 0);
	btnURL.Size = UDim2.new(0, 84, 0, 32);
	btnURL.Position = UDim2.new(1, -6, 0, 6);
	btnURL.Parent = row;
	local btnID = mkBtn("ID");
	btnID.AnchorPoint = Vector2.new(1, 0);
	btnID.Size = UDim2.new(0, 84, 0, 32);
	btnID.Position = UDim2.new(1, -96, 0, 6);
	btnID.Parent = row;
	local btnTRY = nil;
	if canTry then
		btnTRY = mkBtn("TRY");
		btnTRY.AnchorPoint = Vector2.new(1, 0);
		btnTRY.Size = UDim2.new(0, 94, 0, 32);
		btnTRY.Position = UDim2.new(1, -196, 0, 6);
		btnTRY.Parent = row;
	end;
	btnID.MouseButton1Click:Connect(function()
		if clipboard then
			clipboard(tostring(id));
			flash(btnID, theme.ok);
			notify("Copied " .. id);
		end;
	end);
	btnURL.MouseButton1Click:Connect(function()
		local slug = ((tostring(name or "Item")):gsub("[^%w%s%-_]", "")):gsub("%s+", "-");
		local url = "https://www.roblox.com/catalog/" .. id .. "/" .. slug;
		if clipboard then
			clipboard(url);
			flash(btnURL, theme.ok);
			notify("Copied URL");
		end;
	end);
	if btnTRY then
		local key = tostring(id);
		local function label()
			btnTRY.Text = tryCache[key] ~= nil and "TAKE OFF" or "TRY";
		end;
		label();
		btnTRY.MouseButton1Click:Connect(function()
			if tryCache[key] then
				tryCache[key] = nil;
			else
				tryCache[key] = prop;
			end;
			label();
			flash(btnTRY, theme.ok);
			statusLbl.Text = "Applying try-on";
			applyTry();
			statusLbl.Text = "";
		end);
	end;
end;
local req = syn and syn.request or request or http_request or http and http.request or krnl and krnl.request or krnl_request or fluxus and fluxus.request;
local function httpJSON(m, u, b)
	if not req then
		return nil;
	end;
	local body = b and Json:JSONEncode(b) or nil;
	local ok, r = pcall(function()
		return req({
			Url = u,
			Method = m,
			Headers = {
				Accept = "application/json",
				["Content-Type"] = body and "application/json" or nil,
				["Cache-Control"] = "no-cache",
				Pragma = "no-cache",
				["User-Agent"] = "Roblox-Client"
			},
			Body = body
		});
	end);
	if not ok or (not r) or type(r.Body) ~= "string" then
		return nil;
	end;
	local ok2, d = pcall(function()
		return Json:JSONDecode(r.Body);
	end);
	if not ok2 then
		return nil;
	end;
	return d;
end;
local function jreq(m, u, b, t)
	for i = 1, t or 3 do
		local d = httpJSON(m, u, b);
		if d then
			return d;
		end;
		task.wait(0.33);
	end;
	return nil;
end;
local function jget(u)
	return jreq("GET", u, nil, 3);
end;
local function jpost(u, b)
	return jreq("POST", u, b, 3);
end;
local function headshotUrl(uid)
	local t = jget("https://thumbnails.roproxy.com/v1/users/headshot?userIds=" .. uid .. "&size=420x420&format=Png&isCircular=false");
	return t and t.data and t.data[1] and t.data[1].imageUrl;
end;
local function setProp(d, p, v)
	pcall(function()
		d[p] = v;
	end);
end;
local function buildDesc(av)
	local d = Instance.new("HumanoidDescription");
	if av and av.bodyColors then
		local bc = av.bodyColors;
		setProp(d, "HeadColor", (BrickColor.new(bc.headColorId)).Color);
		setProp(d, "TorsoColor", (BrickColor.new(bc.torsoColorId)).Color);
		setProp(d, "LeftArmColor", (BrickColor.new(bc.leftArmColorId)).Color);
		setProp(d, "RightArmColor", (BrickColor.new(bc.rightArmColorId)).Color);
		setProp(d, "LeftLegColor", (BrickColor.new(bc.leftLegColorId)).Color);
		setProp(d, "RightLegColor", (BrickColor.new(bc.rightLegColorId)).Color);
	end;
	local lists = {
		HairAccessory = {},
		FaceAccessory = {},
		NeckAccessory = {},
		ShoulderAccessory = {},
		FrontAccessory = {},
		BackAccessory = {},
		WaistAccessory = {},
		HatAccessory = {}
	};
	if av and av.assets then
		for _, a in ipairs(av.assets) do
			local t = a.assetType and (a.assetType.name or a.assetType.id) or "";
			local prop = mapProp(t);
			if prop:find("Animation") then
				setProp(d, prop, a.id);
			elseif lists[prop] then
				table.insert(lists[prop], tostring(a.id));
			elseif prop == "Shirt" then
				setProp(d, "Shirt", a.id);
			elseif prop == "Pants" then
				setProp(d, "Pants", a.id);
			elseif prop == "Face" then
				setProp(d, "Face", a.id);
			elseif prop == "GraphicTShirt" then
				setProp(d, "GraphicTShirt", a.id);
			elseif prop == "Head" or prop == "Torso" or prop == "LeftArm" or prop == "RightArm" or prop == "LeftLeg" or prop == "RightLeg" then
				setProp(d, prop, a.id);
			end;
		end;
	end;
	for k, v in pairs(lists) do
		if #v > 0 then
			setProp(d, k, table.concat(v, ","));
		end;
	end;
	if av and av.scales then
		local s = av.scales;
		setProp(d, "HeightScale", s.height);
		setProp(d, "WidthScale", s.width);
		setProp(d, "HeadScale", s.head);
		setProp(d, "DepthScale", s.depth);
		setProp(d, "BodyTypeScale", s.bodyType);
		setProp(d, "ProportionScale", s.proportion);
	end;
	return d;
end;
local function camBody(model)
	local cam = Instance.new("Camera");
	cam.Parent = view;
	view.CurrentCamera = cam;
	local cf, sz = model:GetBoundingBox();
	local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart;
	if hrp then
		hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.pi, 0);
	end;
	local focus = hrp and hrp.Position or cf.Position;
	local yOff = sz.Y * 0.18;
	local dist = math.max(sz.X, sz.Y, sz.Z) * 1.15 + 0.6;
	cam.CFrame = CFrame.new(focus + Vector3.new(0, yOff, dist), focus + Vector3.new(0, (-sz.Y) * 0.05, 0));
end;
local function camHead(model)
	local cam = Instance.new("Camera");
	cam.Parent = headVP;
	headVP.CurrentCamera = cam;
	local head = model:FindFirstChild("Head") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart");
	if head then
		local p = head.Position;
		cam.CFrame = CFrame.new(p + Vector3.new(0, 0.1, 2.2), p + Vector3.new(0, 0.1, 0));
	end;
end;
local function tintTop(banned, verified)
	if banned then
		top.BackgroundColor3 = theme.ban_ac;
		header.BackgroundColor3 = theme.ban_ac;
		left.BackgroundColor3 = theme.ban_ac;
		hSt.Color = theme.ban_st;
		leftStroke.Color = theme.ban_st;
		rst.Color = theme.ban_st;
	elseif verified then
		top.BackgroundColor3 = theme.ver_ac;
		header.BackgroundColor3 = theme.ver_ac;
		left.BackgroundColor3 = theme.ver_ac;
		hSt.Color = theme.ver_st;
		leftStroke.Color = theme.ver_st;
		rst.Color = theme.ver_st;
	else
		top.BackgroundColor3 = theme.ac;
		header.BackgroundColor3 = theme.ac;
		left.BackgroundColor3 = theme.ac;
		hSt.Color = theme.br;
		leftStroke.Color = theme.br;
		rst.Color = theme.br;
	end;
end;
local curToken, searchToken, curUserId, curAvatar, curProfile = nil, nil, nil, nil, nil;
local copyDNConn, copyUNConn = nil, nil;
local function setHead(uid, banned, tok, av)
	if not banned then
		headVP.Visible = false;
		headImg.Visible = true;
		local u = headshotUrl(uid);
		if curToken ~= tok then
			return;
		end;
		headImg.Image = u or "rbxthumb://type=AvatarHeadShot&id=" .. uid .. "&w=420&h=420";
	else
		headImg.Visible = false;
		headVP.Visible = true;
		headWM:ClearAllChildren();
		local a = av or jget("https://avatar.roproxy.com/v1/users/" .. uid .. "/avatar");
		if curToken ~= tok then
			return;
		end;
		local d = buildDesc(a);
		local mdl = Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R6);
		mdl.Parent = headWM;
		camHead(mdl);
	end;
end;
local function clearInfo()
	for _, ch in ipairs(infoList:GetChildren()) do
		if ch:IsA("Frame") then
			ch:Destroy();
		end;
	end;
end;
local function addInventory(title, types, lim)
	local d = jget("https://inventory.roproxy.com/v2/users/" .. tostring(curUserId) .. "/inventory?assetTypes=" .. types .. "&limit=" .. tostring((lim or 24)) .. "&sortOrder=Desc");
	if not d or (not d.data) or #d.data == 0 then
		return;
	end;
	local f, h = section(title);
	local grid = Instance.new("Frame");
	grid.BackgroundTransparency = 1;
	grid.Parent = h;
	grid.Size = UDim2.new(1, 0, 0, 10);
	grid.AutomaticSize = Enum.AutomaticSize.Y;
	local gl = Instance.new("UIGridLayout", grid);
	gl.CellPadding = UDim2.fromOffset(8, 8);
	gl.CellSize = UDim2.new(0.24, 0, 0, 138);
	for _, it in ipairs(d.data) do
		local cell = Instance.new("Frame");
		cell.BackgroundTransparency = 1;
		cell.Parent = grid;
		local im = Instance.new("ImageLabel");
		im.BackgroundColor3 = theme.sc;
		im.Size = UDim2.new(1, 0, 0, 96);
		im.Image = "rbxthumb://type=Asset&id=" .. it.assetId .. "&w=150&h=150";
		im.Parent = cell;
		(Instance.new("UICorner", im)).CornerRadius = UDim.new(0, 6);
		local nm = mkText(cell, tostring(it.name or "Item"), theme.tx, 14);
		nm.Position = UDim2.new(0, 0, 0, 100);
		nm.Size = UDim2.new(1, 0, 0, 18);
		local row = Instance.new("Frame");
		row.BackgroundTransparency = 1;
		row.Position = UDim2.new(0, 0, 0, 120);
		row.Size = UDim2.new(1, 0, 0, 16);
		row.Parent = cell;
		local b1 = mkBtn("ID");
		b1.Size = UDim2.new(0.48, -2, 1, 0);
		b1.Parent = row;
		local b2 = mkBtn("URL");
		b2.Size = UDim2.new(0.48, -2, 1, 0);
		b2.Position = UDim2.new(0.52, 0, 0, 0);
		b2.Parent = row;
		b1.MouseButton1Click:Connect(function()
			if clipboard then
				clipboard(tostring(it.assetId));
				flash(b1, theme.ok);
				notify("Copied " .. it.assetId);
			end;
		end);
		b2.MouseButton1Click:Connect(function()
			local slug = ((tostring(it.name or "Item")):gsub("[^%w%s%-_]", "")):gsub("%s+", "-");
			local url = "https://www.roblox.com/catalog/" .. it.assetId .. "/" .. slug;
			if clipboard then
				clipboard(url);
				flash(b2, theme.ok);
				notify("Copied URL");
			end;
		end);
	end;
end;
local function render(uid)
	curUserId = uid;
	curToken = Json:GenerateGUID(false);
	local tok = curToken;
	statusLbl.Text = "Loading: profile";
	clearInfo();
	fullImg.Image = "rbxassetid://0";
	world:ClearAllChildren();
	headWM:ClearAllChildren();
	local profile = jget("https://users.roproxy.com/v1/users/" .. uid);
	if not profile or profile.errors then
		task.wait(0.25);
		profile = jget("https://users.roproxy.com/v1/users/" .. uid);
	end;
	if not profile or profile.errors then
		disp.Text = "User not found";
		handle.Text = "";
		statusLbl.Text = "";
		return;
	end;
	curProfile = profile;
	tintTop(profile.isBanned == true, profile.hasVerifiedBadge == true);
	disp.Text = tostring(profile.displayName or profile.name or "");
	handle.Text = "@" .. tostring((profile.name or "")) .. " • ID: " .. tostring(profile.id);
	if copyDNConn then
		copyDNConn:Disconnect();
	end;
	if copyUNConn then
		copyUNConn:Disconnect();
	end;
	copyDNConn = btnCopyDN.MouseButton1Click:Connect(function()
		if clipboard and curProfile then
			clipboard(tostring(curProfile.displayName or curProfile.name or ""));
			flash(btnCopyDN, theme.ok);
			notify("Copied DisplayName");
		end;
	end);
	copyUNConn = btnCopyUN.MouseButton1Click:Connect(function()
		if clipboard and curProfile then
			clipboard(tostring(curProfile.name or ""));
			flash(btnCopyUN, theme.ok);
			notify("Copied Username");
		end;
	end);
	local av = jget("https://avatar.roproxy.com/v1/users/" .. uid .. "/avatar");
	curAvatar = av;
	world:ClearAllChildren();
	local d = buildDesc(av or {});
	local mdl = Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R6);
	mdl.Parent = world;
	camBody(mdl);
	setHead(profile.id, profile.isBanned == true, tok, av);
	fullImg.Image = "rbxthumb://type=Avatar&id=" .. uid .. "&w=420&h=420";
	local ov, oh = section("Overview");
	kv(oh, "Has Verified Badge", profile.hasVerifiedBadge);
	kv(oh, "Is Banned", profile.isBanned);
	kv(oh, "Created", (function(s)
		if type(s) ~= "string" then
			return tostring(s or "");
		end;
		local y, m, d, H, M, S = s:match("^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)");
		y, m, d, H, M, S = tonumber(y), tonumber(m), tonumber(d), tonumber(H), tonumber(M), tonumber(S);
		if not y then
			return s;
		end;
		local t = os.time({
			year = y,
			month = m,
			day = d,
			hour = H,
			min = M,
			sec = S
		});
		local mo = {
			"Jan",
			"Feb",
			"Mar",
			"Apr",
			"May",
			"Jun",
			"Jul",
			"Aug",
			"Sep",
			"Oct",
			"Nov",
			"Dec"
		};
		local tm = os.date("*t", t);
		return string.format("%s %02d, %04d  %02d:%02d:%02d", mo[tm.month], tm.day, tm.year, tm.hour, tm.min, tm.sec);
	end)(profile.created or ""));
	local desc = tostring(profile.description or "");
	if desc ~= "" then
		local ds, dh = section("Description");
		descRow(dh, desc);
	end;
	local st = jget("https://users.roproxy.com/v1/users/" .. uid .. "/status");
	if st and (not st.errors) and st.status and st.status ~= "" then
		local f, h = section("Status");
		descRow(h, st.status);
	end;
	local h1 = jget("https://users.roproxy.com/v1/users/" .. uid .. "/username-history?limit=100&sortOrder=Asc");
	local h2 = jget("https://users.roproxy.com/v1/users/" .. uid .. "/username-history?limit=100&sortOrder=Desc");
	local seen, arr = {}, {};
	local function push(hx)
		if hx and hx.data then
			for _, it in ipairs(hx.data) do
				local n = it.name or it.username;
				if n and (not seen[n]) then
					seen[n] = true;
					table.insert(arr, {
						n = n,
						t = it.created or ""
					});
				end;
			end;
		end;
	end;
	push(h1);
	push(h2);
	if #arr > 0 then
		table.sort(arr, function(a, b)
			return a.t < b.t;
		end);
		local f, h = section("Previous Usernames");
		for _, x in ipairs(arr) do
			local r = Instance.new("Frame");
			r.BackgroundTransparency = 1;
			r.Size = UDim2.new(1, 0, 0, 34);
			r.Parent = h;
			local v = mkText(r, (function(s)
				if type(s) ~= "string" then
					return tostring(s or "");
				end;
				local y, m, d, H, M, S = s:match("^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)");
				y, m, d, H, M, S = tonumber(y), tonumber(m), tonumber(d), tonumber(H), tonumber(M), tonumber(S);
				if not y then
					return s;
				end;
				local t = os.time({
					year = y,
					month = m,
					day = d,
					hour = H,
					min = M,
					sec = S
				});
				local mo = {
					"Jan",
					"Feb",
					"Mar",
					"Apr",
					"May",
					"Jun",
					"Jul",
					"Aug",
					"Sep",
					"Oct",
					"Nov",
					"Dec"
				};
				local tm = os.date("*t", t);
				return string.format("%s %02d, %04d", mo[tm.month], tm.day, tm.year);
			end)(x.t) .. "  •  " .. x.n, theme.tx, 16);
			v.Size = UDim2.new(0.8, 0, 1, 0);
			v.TextXAlignment = Enum.TextXAlignment.Left;
			local b = mkBtn("COPY");
			b.Size = UDim2.new(0, 90, 0, 30);
			b.Position = UDim2.new(1, -96, 0, 2);
			b.Parent = r;
			b.MouseButton1Click:Connect(function()
				if clipboard then
					clipboard(x.n);
					flash(b, theme.ok);
					notify("Copied " .. x.n);
				end;
			end);
		end;
	end;
	if av and (not av.errors) then
		local aS, aH = section("Avatar");
		kv(aH, "Player Avatar Type", av.playerAvatarType or "");
		local sS, sH = section("Body Scales");
		for _, k in ipairs({
			"height",
			"width",
			"head",
			"depth",
			"proportion",
			"bodyType"
		}) do
			local v = av.scales and av.scales[k];
			if v ~= nil then
				kv(sH, (k:sub(1, 1)):upper() .. k:sub(2), math.floor(v * 100) / 100);
			end;
		end;
		local cS, cH = section("Body Colors");
		local col = av.bodyColors or {};
		local function colorRow(part, id)
			if not id then
				return;
			end;
			local r = Instance.new("Frame");
			r.BackgroundTransparency = 1;
			r.AutomaticSize = Enum.AutomaticSize.Y;
			r.Size = UDim2.new(1, 0, 0, 28);
			r.Parent = cH;
			(mkText(r, part, theme.td, 16)).Size = UDim2.new(0.22, 0, 0, 24);
			local bc = BrickColor.new(id);
			local sw = Instance.new("Frame");
			sw.BackgroundColor3 = bc.Color;
			sw.Size = UDim2.fromOffset(28, 20);
			sw.Position = UDim2.new(0.24, 0, 0, 2);
			sw.Parent = r;
			(Instance.new("UICorner", sw)).CornerRadius = UDim.new(0, 4);
			local r255 = math.floor(bc.Color.R * 255 + 0.5) .. "," .. math.floor(bc.Color.G * 255 + 0.5) .. "," .. math.floor(bc.Color.B * 255 + 0.5);
			local hex = string.format("#%02X%02X%02X", math.floor(bc.Color.R * 255 + 0.5), math.floor(bc.Color.G * 255 + 0.5), math.floor(bc.Color.B * 255 + 0.5));
			local v = mkText(r, bc.Name .. " (" .. id .. ")  •  RGB(" .. r255 .. ")  •  " .. hex, theme.tx, 16);
			v.Position = UDim2.new(0.24, 34, 0, 0);
			v.Size = UDim2.new(0.76, -34, 0, 24);
		end;
		colorRow("Head", col.headColorId);
		colorRow("Torso", col.torsoColorId);
		colorRow("Left Arm", col.leftArmColorId);
		colorRow("Right Arm", col.rightArmColorId);
		colorRow("Left Leg", col.leftLegColorId);
		colorRow("Right Leg", col.rightLegColorId);
		local animS, animH = section("Animations");
		local bodyS, bodyH = section("Body Parts");
		local accS, accH = section("Accessories");
		local function put(dst, a, try)
			local t = a.assetType and a.assetType.name or "Asset";
			local prop = mapProp(t);
			mkItemRow(dst, a.id, a.name and #a.name > 0 and a.name or t, t, prop, try);
		end;
		if av.assets then
			for _, a in ipairs(av.assets) do
				local t = a.assetType and a.assetType.name or "Asset";
				if t == "Emote" then
				elseif t:find("Animation") then
					put(animH, a, true);
				elseif t == "Head" or t == "Torso" or t == "LeftArm" or t == "RightArm" or t == "LeftLeg" or t == "RightLeg" or t == "Face" or t == "Shirt" or t == "Pants" or t == "TShirt" then
					put(bodyH, a, true);
				else
					put(accH, a, true);
				end;
			end;
		end;
		local eS, eH = section("Emotes");
		if av.emotes and #av.emotes > 0 then
			for _, e in ipairs(av.emotes) do
				mkItemRow(eH, e.assetId, e.assetName or "Emote", "Emote", "", false);
			end;
		else
			kv(eH, "Empty", "No emotes");
		end;
	end;
	local promo = jget("https://users.roproxy.com/v1/users/" .. uid .. "/promotion-channels");
	if promo and (not promo.errors) then
		local keep = {};
		for k, v in pairs(promo) do
			if v and v ~= "" then
				keep[k] = v;
			end;
		end;
		if next(keep) then
			local f, h = section("Promotion Channels");
			for k, v in pairs(keep) do
				kv(h, k, v);
			end;
		end;
	end;
	local meta = jget("https://users.roproxy.com/v1/users/" .. uid .. "/metadata");
	if meta and (not meta.errors) then
		local f, h = section("User Metadata");
		for k, v in pairs(meta) do
			kv(h, k, v);
		end;
	end;
	addInventory("Inventory • Accessories", "Hat,HairAccessory,FaceAccessory,NeckAccessory,ShoulderAccessory,FrontAccessory,BackAccessory,WaistAccessory", 24);
	addInventory("Inventory • Clothing", "TShirt,Shirt,Pants,Jacket,Sweater,Shorts,DressSkirt", 24);
	statusLbl.Text = "";
end;
local function clearResults()
	for _, ch in ipairs(results:GetChildren()) do
		if ch:IsA("Frame") then
			ch:Destroy();
		end;
	end;
end;
local selectedRow = nil;
local function tintRow(row, banned, verified)
	local st = row:FindFirstChildOfClass("UIStroke");
	if banned then
		row.BackgroundColor3 = theme.ban_ac;
		if st then
			st.Color = theme.ban_st;
		end;
	elseif verified then
		row.BackgroundColor3 = theme.ver_ac;
		if st then
			st.Color = theme.ver_st;
		end;
	else
		row.BackgroundColor3 = theme.sc;
		if st then
			st.Color = theme.br;
		end;
	end;
end;
local function addRow(u, full, tok)
	if searchToken ~= tok then
		return;
	end;
	local row = Instance.new("Frame");
	row.BackgroundColor3 = theme.sc;
	row.Size = UDim2.new(1, 0, 0, 78);
	row.Parent = results;
	(Instance.new("UICorner", row)).CornerRadius = UDim.new(0, 10);
	local st = Instance.new("UIStroke", row);
	st.Color = theme.br;
	st.Transparency = 0.55;
	local banned = full and full.isBanned == true;
	local verified = not banned and (u.hasVerifiedBadge == true or full and full.hasVerifiedBadge);
	tintRow(row, banned, verified);
	row:SetAttribute("Banned", banned);
	row:SetAttribute("Verified", verified);
	local im = Instance.new("ImageLabel");
	im.BackgroundColor3 = theme.ac;
	im.Size = UDim2.fromOffset(56, 56);
	im.Position = UDim2.new(0, 8, 0.5, -28);
	im.Image = "rbxthumb://type=AvatarHeadShot&id=" .. u.id .. "&w=150&h=150";
	im.Parent = row;
	(Instance.new("UICorner", im)).CornerRadius = UDim.new(0, 8);
	local n = Instance.new("Frame");
	n.BackgroundTransparency = 1;
	n.Position = UDim2.new(0, 72, 0, 8);
	n.Size = UDim2.new(1, -80, 0, 28);
	n.Parent = row;
	(mkText(n, tostring(u.displayName or u.name), theme.tx, 18)).Size = UDim2.fromScale(1, 1);
	local s = Instance.new("Frame");
	s.BackgroundTransparency = 1;
	s.Position = UDim2.new(0, 72, 0, 40);
	s.Size = UDim2.new(1, -80, 0, 24);
	s.Parent = row;
	(mkText(s, "@" .. tostring(u.name) .. " • " .. (banned and "Banned" or (verified and "✓ Verified" or "User")) .. " • " .. tostring(u.id), banned and theme.ban_st or (verified and theme.ver_st or theme.td), 14)).Size = UDim2.fromScale(1, 1);
	local click = Instance.new("TextButton");
	click.Text = "";
	click.BackgroundTransparency = 1;
	click.Size = UDim2.fromScale(1, 1);
	click.Parent = row;
	click.MouseButton1Click:Connect(function()
		if selectedRow and selectedRow ~= row then
			tintRow(selectedRow, selectedRow:GetAttribute("Banned"), selectedRow:GetAttribute("Verified"));
		end;
		selectedRow = row;
		(Tween:Create(row, TweenInfo.new(0.08), {
			BackgroundColor3 = Color3.fromRGB(44, 46, 52)
		})):Play();
		statusLbl.Text = "Loading: preview";
		render(u.id);
	end);
end;
local function enrich(rows, tok)
	for _, inf in ipairs(rows) do
		if searchToken ~= tok then
			return;
		end;
		local full = jget("https://users.roproxy.com/v1/users/" .. inf.id);
		addRow(inf.basic, full, tok);
		task.wait(0.02);
	end;
end;
local function runSearch(q)
	searchToken = Json:GenerateGUID(false);
	local tok = searchToken;
	statusLbl.Text = "Loading: search";
	clearResults();
	q = ((tostring(q or "")):gsub("^%s+", "")):gsub("%s+$", "");
	if q == "" then
		statusLbl.Text = "";
		return;
	end;
	local rows = {};
	if q:match("^%d+$") then
		local u = jget("https://users.roproxy.com/v1/users/" .. q);
		if u and (not u.errors) then
			table.insert(rows, {
				id = u.id,
				basic = {
					id = u.id,
					name = u.name,
					displayName = u.displayName,
					hasVerifiedBadge = u.hasVerifiedBadge
				}
			});
		end;
	else
		local res = jget("https://users.roproxy.com/v1/users/search?keyword=" .. Json:UrlEncode(q) .. "&limit=25");
		if res and (not res.errors) and res.data then
			for _, u in ipairs(res.data) do
				table.insert(rows, {
					id = u.id,
					basic = u
				});
			end;
		end;
		local ex = jpost("https://users.roproxy.com/v1/usernames/users", {
			usernames = {
				q
			},
			excludeBannedUsers = false
		});
		local d = ex and ex.data and ex.data[1];
		if d and d.id then
			local seen = false;
			for _, r in ipairs(rows) do
				if r.id == d.id then
					seen = true;
					break;
				end;
			end;
			if not seen then
				table.insert(rows, 1, {
					id = d.id,
					basic = {
						id = d.id,
						name = d.requestedUsername or d.name,
						displayName = d.displayName or d.name,
						hasVerifiedBadge = d.hasVerifiedBadge
					}
				});
			end;
		end;
	end;
	if searchToken ~= tok then
		return;
	end;
	if #rows > 0 then
		enrich(rows, tok);
	end;
	statusLbl.Text = "";
end;
btnSearch.MouseButton1Click:Connect(function()
	runSearch(searchBox.Text);
end);
searchBox.FocusLost:Connect(function(enter)
	if enter then
		runSearch(searchBox.Text);
	end;
end);
btnClose.MouseButton1Click:Connect(function()
	(Tween:Create(root, TweenInfo.new(0.12), {
		BackgroundTransparency = 1
	})):Play();
	(Tween:Create(rst, TweenInfo.new(0.12), {
		Transparency = 1
	})):Play();
	task.wait(0.13);
	gui:Destroy();
end);
btnWear.MouseButton1Click:Connect(function()
	if not curUserId then
		notify("No user selected");
		return;
	end;
	local hum, char = getHumanoid();
	for _, cls in ipairs({
		"Shirt",
		"Pants",
		"ShirtGraphic"
	}) do
		for _, inst in ipairs(char:GetChildren()) do
			if inst.ClassName == cls then
				inst:Destroy();
			end;
		end;
	end;
	if curProfile and curProfile.isBanned == true then
		if not curAvatar then
			notify("No avatar data");
			return;
		end;
		local d = buildDesc(curAvatar);
		if hum.ApplyDescriptionClientServer then
			hum:ApplyDescriptionClientServer(d);
		else
			hum:ApplyDescription(d);
		end;
	else
		local ok, desc = pcall(Players.GetHumanoidDescriptionFromUserId, Players, curUserId);
		if not ok or (not desc) then
			notify("Failed to load avatar");
			return;
		end;
		if hum.ApplyDescriptionClientServer then
			hum:ApplyDescriptionClientServer(desc);
		else
			hum:ApplyDescription(desc);
		end;
	end;
	notify("Applied once");
end);
local function layout()
	local cam = workspace.CurrentCamera;
	local vs = cam and cam.ViewportSize or Vector2.new(1280, 720);
	local lw = math.floor(math.clamp(vs.X * (IsOnMobile and 0.38 or 0.3), 220, 420));
	left.Size = UDim2.new(0, lw, 1, 0);
	right.Size = UDim2.new(1, -lw, 1, 0);
	right.Position = UDim2.new(0, lw, 0, 0);
	searchBox.Size = UDim2.fromOffset(math.clamp(vs.X * 0.28, 260, 540), 42);
end;
layout();
local cam = workspace.CurrentCamera;
if cam then
	(cam:GetPropertyChangedSignal("ViewportSize")):Connect(layout);
end;
root.BackgroundTransparency = 1;
rst.Transparency = 1;
root.Size = UDim2.fromScale(0.94, 0.88);
(Tween:Create(root, TweenInfo.new(0.22), {
	BackgroundTransparency = 0,
	Size = UDim2.fromScale(0.96, 0.9)
})):Play();
(Tween:Create(rst, TweenInfo.new(0.2), {
	Transparency = 0.4
})):Play();
