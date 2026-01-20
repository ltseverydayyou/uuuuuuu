local srv = setmetatable({}, {
	__index = function(self, n)
		local ref = cloneref and type(cloneref) == "function" and cloneref or function(x)
			return x;
		end;
		local ok, s = pcall(function()
			return ref(game:GetService(n));
		end);
		if ok and s then
			rawset(self, n, s);
			return s;
		end;
	end
});
local function S(n)
	return srv[n];
end;
local function protectUI(g)
	if g:IsA("ScreenGui") then
		g.ZIndexBehavior = Enum.ZIndexBehavior.Global;
		g.DisplayOrder = 999999999;
		g.ResetOnSpawn = false;
		g.IgnoreGuiInset = true;
	end;
	local cg = S("CoreGui");
	local function npt(i, v)
		if i then
			if v then
				i[v] = "\000";
			else
				i.Name = "\000";
			end;
			i.Archivable = false;
		end;
	end;
	if gethui then
		npt(g);
		g.Parent = gethui();
	elseif cg and cg:FindFirstChild("RobloxGui") then
		npt(g);
		g.Parent = cg.RobloxGui;
	elseif cg then
		npt(g);
		g.Parent = cg;
	else
		local lp = (S("Players")).LocalPlayer;
		local pg = lp and lp:FindFirstChildWhichIsA("PlayerGui");
		if pg then
			npt(g);
			g.Parent = pg;
			g.ResetOnSpawn = false;
		end;
	end;
	return g;
end;
local tw = S("TweenService");
local uis = S("UserInputService");
local hs = S("HttpService");
local ts = S("TextService");
local srvBases = {
	"https://games.roblox.com",
	"https://games.roproxy.com",
	"https://roxytheproxy.com/games.roblox.com"
};
local srvWorker = "https://solaraserverhop.ltseverydayyou.workers.dev";
local cam = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera");
local req = request or http_request or syn and syn.request or function()
end;
local gui = protectUI(Instance.new("ScreenGui"));
local win = Instance.new("Frame");
win.Name = "ServerWin";
win.Parent = gui;
win.AnchorPoint = Vector2.new(0, 0);
win.Size = UDim2.new(0, 560, 0, 380);
win.BackgroundColor3 = Color3.fromRGB(10, 10, 12);
win.BackgroundTransparency = 0.06;
win.BorderSizePixel = 0;
win.ZIndex = 10;
win.Active = true;
do
	local v = cam and cam.ViewportSize or Vector2.new(1280, 720);
	local cx = (v.X - win.Size.X.Offset) * 0.5;
	local cy = (v.Y - win.Size.Y.Offset) * 0.5;
	win.Position = UDim2.fromOffset(cx, cy);
end;
local scl = Instance.new("UIScale");
scl.Parent = win;
scl.Scale = 1;
local winCorner = Instance.new("UICorner");
winCorner.Parent = win;
winCorner.CornerRadius = UDim.new(0, 14);
local winStroke = Instance.new("UIStroke");
winStroke.Parent = win;
winStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border;
winStroke.Color = Color3.fromRGB(255, 255, 255);
winStroke.Thickness = 1;
winStroke.Transparency = 0.86;
winStroke.ZIndex = 11;
local winGrad = Instance.new("UIGradient");
winGrad.Rotation = 90;
winGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 24)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 10))
});
winGrad.Parent = win;
local winPad = Instance.new("UIPadding");
winPad.Parent = win;
winPad.PaddingTop = UDim.new(0, 12);
winPad.PaddingBottom = UDim.new(0, 12);
winPad.PaddingLeft = UDim.new(0, 12);
winPad.PaddingRight = UDim.new(0, 12);
local top = Instance.new("Frame");
top.Parent = win;
top.BackgroundTransparency = 1;
top.Position = UDim2.new(0, 0, 0, 0);
top.Size = UDim2.new(1, 0, 0, 32);
top.ZIndex = 12;
local title = Instance.new("TextLabel");
title.Parent = top;
title.BackgroundTransparency = 1;
title.Size = UDim2.new(1, -32, 1, 0);
title.Position = UDim2.new(0, 0, 0, 0);
title.Font = Enum.Font.GothamSemibold;
title.Text = "Server Lister";
title.TextSize = 18;
title.TextColor3 = Color3.fromRGB(255, 255, 255);
title.TextXAlignment = Enum.TextXAlignment.Left;
title.ZIndex = 999;
local close = Instance.new("ImageButton");
close.Parent = top;
close.BackgroundTransparency = 1;
close.Size = UDim2.new(0, 20, 0, 20);
close.Position = UDim2.new(1, -20, 0, 6);
close.Image = "rbxassetid://56290972";
close.ImageColor3 = Color3.fromRGB(255, 90, 90);
close.ZIndex = 14;
local row1 = Instance.new("Frame");
row1.Parent = win;
row1.BackgroundTransparency = 1;
row1.Position = UDim2.new(0, 0, 0, 40);
row1.Size = UDim2.new(1, 0, 0, 32);
row1.ZIndex = 12;
local r1l = Instance.new("UIListLayout");
r1l.Parent = row1;
r1l.FillDirection = Enum.FillDirection.Horizontal;
r1l.SortOrder = Enum.SortOrder.LayoutOrder;
r1l.Padding = UDim.new(0, 8);
r1l.VerticalAlignment = Enum.VerticalAlignment.Center;
local idBox = Instance.new("TextBox");
idBox.Parent = row1;
idBox.BackgroundColor3 = Color3.fromRGB(18, 18, 22);
idBox.BackgroundTransparency = 0.02;
idBox.BorderSizePixel = 0;
idBox.Size = UDim2.new(1, -144, 1, 0);
idBox.Font = Enum.Font.Gotham;
idBox.Text = tostring(game.PlaceId);
idBox.TextSize = 14;
idBox.TextColor3 = Color3.fromRGB(255, 255, 255);
idBox.TextXAlignment = Enum.TextXAlignment.Left;
idBox.ClearTextOnFocus = false;
idBox.ZIndex = 13;
idBox.LayoutOrder = 1;
local idPad = Instance.new("UIPadding");
idPad.Parent = idBox;
idPad.PaddingLeft = UDim.new(0, 10);
idPad.PaddingRight = UDim.new(0, 10);
local idCorner = Instance.new("UICorner");
idCorner.Parent = idBox;
idCorner.CornerRadius = UDim.new(0, 8);
local idStroke = Instance.new("UIStroke");
idStroke.Parent = idBox;
idStroke.Color = Color3.fromRGB(80, 80, 95);
idStroke.Transparency = 0.25;
idStroke.Thickness = 1;
idStroke.ZIndex = 14;
local refBtn = Instance.new("TextButton");
refBtn.Parent = row1;
refBtn.BackgroundColor3 = Color3.fromRGB(235, 235, 235);
refBtn.BorderSizePixel = 0;
refBtn.Size = UDim2.new(0, 132, 1, 0);
refBtn.Font = Enum.Font.GothamSemibold;
refBtn.Text = "Refresh";
refBtn.TextSize = 14;
refBtn.TextColor3 = Color3.fromRGB(10, 10, 10);
refBtn.AutoButtonColor = false;
refBtn.ZIndex = 13;
refBtn.LayoutOrder = 2;
local refCorner = Instance.new("UICorner");
refCorner.Parent = refBtn;
refCorner.CornerRadius = UDim.new(0, 8);
local refStroke = Instance.new("UIStroke");
refStroke.Parent = refBtn;
refStroke.Color = Color3.fromRGB(180, 180, 180);
refStroke.Transparency = 0.25;
refStroke.Thickness = 1;
refStroke.ZIndex = 14;
local row2 = Instance.new("Frame");
row2.Parent = win;
row2.BackgroundTransparency = 1;
row2.Position = UDim2.new(0, 0, 0, 80);
row2.Size = UDim2.new(1, 0, 0, 26);
row2.ZIndex = 12;
local hdr = Instance.new("Frame");
hdr.Parent = row2;
hdr.BackgroundColor3 = Color3.fromRGB(14, 14, 18);
hdr.BackgroundTransparency = 0.12;
hdr.BorderSizePixel = 0;
hdr.Size = UDim2.new(1, 0, 1, 0);
hdr.ZIndex = 13;
local hdrCorner = Instance.new("UICorner");
hdrCorner.Parent = hdr;
hdrCorner.CornerRadius = UDim.new(0, 10);
local hdrStroke = Instance.new("UIStroke");
hdrStroke.Parent = hdr;
hdrStroke.Color = Color3.fromRGB(60, 60, 70);
hdrStroke.Transparency = 0.45;
hdrStroke.Thickness = 1;
hdrStroke.ZIndex = 14;
local hdrPad = Instance.new("UIPadding");
hdrPad.Parent = hdr;
hdrPad.PaddingLeft = UDim.new(0, 12);
hdrPad.PaddingRight = UDim.new(0, 12);
local hdrList = Instance.new("UIListLayout");
hdrList.Parent = hdr;
hdrList.FillDirection = Enum.FillDirection.Horizontal;
hdrList.SortOrder = Enum.SortOrder.LayoutOrder;
hdrList.Padding = UDim.new(0, 8);
hdrList.VerticalAlignment = Enum.VerticalAlignment.Center;
local function mkHdr(t, s)
	local b = Instance.new("TextButton");
	b.Parent = hdr;
	b.BackgroundTransparency = 1;
	b.BorderSizePixel = 0;
	b.Size = UDim2.new(s, 0, 1, 0);
	b.Font = Enum.Font.GothamSemibold;
	b.Text = t;
	b.TextSize = 13;
	b.TextColor3 = Color3.fromRGB(255, 255, 255);
	b.TextXAlignment = Enum.TextXAlignment.Left;
	b.AutoButtonColor = false;
	b.ZIndex = 15;
	return b;
end;
local hPl = mkHdr("Players", 0.34);
local hPg = mkHdr("Ping", 0.33);
local hFp = mkHdr("FPS", 0.33);
local list = Instance.new("ScrollingFrame");
list.Parent = win;
list.Active = true;
list.BackgroundColor3 = Color3.fromRGB(14, 14, 18);
list.BackgroundTransparency = 0.08;
list.BorderSizePixel = 0;
list.Position = UDim2.new(0, 0, 0, 116);
list.Size = UDim2.new(1, 0, 1, -160);
list.ScrollBarThickness = 3;
list.ZIndex = 12;
list.CanvasSize = UDim2.new(0, 0, 0, 0);
list.ClipsDescendants = true;
pcall(function()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y;
end);
local listCorner = Instance.new("UICorner");
listCorner.Parent = list;
listCorner.CornerRadius = UDim.new(0, 12);
local listStroke = Instance.new("UIStroke");
listStroke.Parent = list;
listStroke.Color = Color3.fromRGB(55, 55, 65);
listStroke.Transparency = 0.4;
listStroke.Thickness = 1;
listStroke.ZIndex = 13;
local listPad = Instance.new("UIPadding");
listPad.Parent = list;
listPad.PaddingTop = UDim.new(0, 8);
listPad.PaddingBottom = UDim.new(0, 8);
listPad.PaddingLeft = UDim.new(0, 8);
listPad.PaddingRight = UDim.new(0, 8);
local listLayout = Instance.new("UIListLayout");
listLayout.Parent = list;
listLayout.SortOrder = Enum.SortOrder.LayoutOrder;
listLayout.Padding = UDim.new(0, 6);
local bottom = Instance.new("Frame");
bottom.Parent = win;
bottom.BackgroundTransparency = 1;
bottom.AnchorPoint = Vector2.new(0, 1);
bottom.Position = UDim2.new(0, 0, 1, -10);
bottom.Size = UDim2.new(1, 0, 0, 32);
bottom.ZIndex = 12;
local bList = Instance.new("UIListLayout");
bList.Parent = bottom;
bList.FillDirection = Enum.FillDirection.Horizontal;
bList.SortOrder = Enum.SortOrder.LayoutOrder;
bList.Padding = UDim.new(0, 8);
bList.VerticalAlignment = Enum.VerticalAlignment.Center;
local function mkBtn(txt, w)
	local b = Instance.new("TextButton");
	b.Parent = bottom;
	b.BackgroundColor3 = Color3.fromRGB(18, 18, 22);
	b.BackgroundTransparency = 0.02;
	b.BorderSizePixel = 0;
	b.Size = UDim2.new(0, w, 1, 0);
	b.Font = Enum.Font.Gotham;
	b.Text = txt;
	b.TextSize = 14;
	b.TextColor3 = Color3.fromRGB(255, 255, 255);
	b.AutoButtonColor = false;
	b.ZIndex = 13;
	local c = Instance.new("UICorner");
	c.CornerRadius = UDim.new(0, 8);
	c.Parent = b;
	local s = Instance.new("UIStroke");
	s.Parent = b;
	s.Color = Color3.fromRGB(80, 80, 90);
	s.Transparency = 0.3;
	s.Thickness = 1;
	s.ZIndex = 14;
	return b;
end;
local cpBtn = mkBtn("Copy players", 150);
cpBtn.LayoutOrder = 1;
local hideBtn = mkBtn("Hide full: OFF", 140);
hideBtn.LayoutOrder = 2;
local autoBtn = mkBtn("Auto ping sort: OFF", 180);
autoBtn.LayoutOrder = 3;
local pill = Instance.new("TextButton");
pill.Parent = gui;
pill.BackgroundColor3 = Color3.fromRGB(16, 16, 20);
pill.BackgroundTransparency = 0.06;
pill.BorderSizePixel = 0;
pill.AnchorPoint = Vector2.new(0.5, 0);
pill.Position = UDim2.new(0.5, 0, 0.1, 0);
pill.Size = UDim2.new(0, 150, 0, 34);
pill.Font = Enum.Font.GothamSemibold;
pill.Text = "Server Lister";
pill.TextSize = 14;
pill.TextColor3 = Color3.fromRGB(255, 255, 255);
pill.TextStrokeColor3 = Color3.fromRGB(0, 0, 0);
pill.TextStrokeTransparency = 0.5;
pill.AutoButtonColor = false;
pill.ZIndex = 30;
pill.Active = true;
local pillCorner = Instance.new("UICorner");
pillCorner.Parent = pill;
pillCorner.CornerRadius = UDim.new(1, 0);
local pillStroke = Instance.new("UIStroke");
pillStroke.Parent = pill;
pillStroke.Color = Color3.fromRGB(95, 95, 110);
pillStroke.Transparency = 0.45;
pillStroke.Thickness = 1;
pillStroke.ZIndex = 31;
local function tbg(b, c)
	(tw:Create(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = c
	})):Play();
end;
refBtn.MouseEnter:Connect(function()
	tbg(refBtn, Color3.fromRGB(250, 250, 250));
end);
refBtn.MouseLeave:Connect(function()
	tbg(refBtn, Color3.fromRGB(235, 235, 235));
end);
cpBtn.MouseEnter:Connect(function()
	tbg(cpBtn, Color3.fromRGB(26, 26, 30));
end);
cpBtn.MouseLeave:Connect(function()
	tbg(cpBtn, Color3.fromRGB(18, 18, 22));
end);
hideBtn.MouseEnter:Connect(function()
	tbg(hideBtn, Color3.fromRGB(26, 26, 30));
end);
hideBtn.MouseLeave:Connect(function()
	tbg(hideBtn, Color3.fromRGB(18, 18, 22));
end);
autoBtn.MouseEnter:Connect(function()
	tbg(autoBtn, Color3.fromRGB(26, 26, 30));
end);
autoBtn.MouseLeave:Connect(function()
	tbg(autoBtn, Color3.fromRGB(18, 18, 22));
end);
pill.MouseEnter:Connect(function()
	tbg(pill, Color3.fromRGB(26, 26, 32));
end);
pill.MouseLeave:Connect(function()
	tbg(pill, Color3.fromRGB(16, 16, 20));
end);
local open = true;
local hideFull = false;
local autoPing = false;
local function clampWin()
	if not cam then
		return;
	end;
	local v = cam.ViewportSize;
	local s = win.AbsoluteSize;
	local p = win.Position;
	local minX, maxX = 8, v.X - s.X - 8;
	local minY, maxY = 8, v.Y - s.Y - 8;
	local newX = math.clamp(p.X.Offset, minX, maxX);
	local newY = math.clamp(p.Y.Offset, minY, maxY);
	win.Position = UDim2.fromOffset(newX, newY);
end;
if cam then
	(cam:GetPropertyChangedSignal("ViewportSize")):Connect(clampWin);
end;
local function setOpen(v)
	open = v;
	if v then
		win.Visible = true;
		scl.Scale = 0.9;
		win.BackgroundTransparency = 1;
		(tw:Create(scl, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = 1
		})):Play();
		(tw:Create(win, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.06
		})):Play();
	else
		local t1 = tw:Create(scl, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = 0.9
		});
		local t2 = tw:Create(win, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		});
		t1:Play();
		t2:Play();
		t2.Completed:Connect(function()
			if not open then
				win.Visible = false;
			end;
		end);
	end;
end;
close.MouseButton1Down:Connect(function()
	gui:Destroy();
end);
local function mkDrag(handle, root, clamp)
	local dragging = false;
	local startPos;
	local startInput;
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true;
			startInput = i.Position;
			startPos = root.Position;
		end;
	end);
	handle.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false;
			if clamp then
				clamp();
			end;
		end;
	end);
	uis.InputChanged:Connect(function(i)
		if not dragging then
			return;
		end;
		if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then
			return;
		end;
		local d = i.Position - startInput;
		root.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y);
	end);
end;
local function mkDragClick(handle, root, cb)
	local dragging = false;
	local startPos;
	local startInput;
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true;
			startInput = i.Position;
			startPos = root.Position;
		end;
	end);
	handle.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			local dist = (i.Position - startInput).Magnitude;
			dragging = false;
			if dist <= 6 and cb then
				cb();
			end;
		end;
	end);
	uis.InputChanged:Connect(function(i)
		if not dragging then
			return;
		end;
		if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then
			return;
		end;
		local d = i.Position - startInput;
		root.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y);
	end);
end;
mkDrag(top, win, clampWin);
mkDragClick(pill, pill, function()
	setOpen(not open);
end);
if uis.KeyboardEnabled then
	uis.InputBegan:Connect(function(i, gpe)
		if gpe then
			return;
		end;
		if i.KeyCode == Enum.KeyCode.L then
			setOpen(not open);
		end;
	end);
end;
local function wipe()
	for _, v in ipairs(list:GetChildren()) do
		if v:IsA("Frame") and v.Name == "row" then
			v:Destroy();
		end;
	end;
end;
local function mkRow(t)
	if hideFull and t.playing >= t.maxPlayers then
		return;
	end;
	local row = Instance.new("Frame");
	row.Parent = list;
	row.Name = "row";
	row.BackgroundColor3 = Color3.fromRGB(18, 18, 24);
	row.BackgroundTransparency = 0.08;
	row.BorderSizePixel = 0;
	row.Size = UDim2.new(1, 0, 0, 46);
	row.ZIndex = 13;
	local rc = Instance.new("UICorner");
	rc.Parent = row;
	rc.CornerRadius = UDim.new(0, 10);
	local rs = Instance.new("UIStroke");
	rs.Parent = row;
	rs.Color = Color3.fromRGB(55, 55, 70);
	rs.Transparency = 0.45;
	rs.Thickness = 1;
	rs.ZIndex = 14;
	local btn = Instance.new("TextButton");
	btn.Parent = row;
	btn.BackgroundColor3 = Color3.fromRGB(235, 235, 235);
	btn.BorderSizePixel = 0;
	btn.Position = UDim2.new(0, 10, 0, 9);
	btn.Size = UDim2.new(0, 90, 0, 28);
	btn.Font = Enum.Font.GothamSemibold;
	btn.Text = "Join";
	btn.TextSize = 14;
	btn.TextColor3 = Color3.fromRGB(10, 10, 10);
	btn.AutoButtonColor = false;
	btn.ZIndex = 15;
	local bc = Instance.new("UICorner");
	bc.Parent = btn;
	bc.CornerRadius = UDim.new(0, 8);
	local bs = Instance.new("UIStroke");
	bs.Parent = btn;
	bs.Color = Color3.fromRGB(180, 180, 180);
	bs.Transparency = 0.25;
	bs.Thickness = 1;
	bs.ZIndex = 16;
	local cap = Instance.new("TextLabel");
	cap.Parent = row;
	cap.Name = "cap";
	cap.BackgroundTransparency = 1;
	cap.Position = UDim2.new(0.38, 0, 0, 0);
	cap.Size = UDim2.new(0.18, 0, 1, 0);
	cap.Font = Enum.Font.Gotham;
	cap.Text = tostring(t.playing) .. "/" .. tostring(t.maxPlayers);
	cap.TextSize = 14;
	cap.TextColor3 = Color3.fromRGB(255, 255, 255);
	cap.TextXAlignment = Enum.TextXAlignment.Center;
	cap.ZIndex = 15;
	local ping = Instance.new("TextLabel");
	ping.Parent = row;
	ping.Name = "pg";
	ping.BackgroundTransparency = 1;
	ping.Position = UDim2.new(0.58, 0, 0, 0);
	ping.Size = UDim2.new(0.2, 0, 1, 0);
	ping.Font = Enum.Font.Gotham;
	ping.Text = tostring(t.ping) .. " ms";
	ping.TextSize = 14;
	ping.TextColor3 = Color3.fromRGB(255, 255, 255);
	ping.TextXAlignment = Enum.TextXAlignment.Center;
	ping.ZIndex = 15;
	local fps = Instance.new("TextLabel");
	fps.Parent = row;
	fps.Name = "fp";
	fps.BackgroundTransparency = 1;
	fps.Position = UDim2.new(0.8, 0, 0, 0);
	fps.Size = UDim2.new(0.2, -10, 1, 0);
	fps.Font = Enum.Font.Gotham;
	fps.Text = tostring((string.split(tostring(t.fps), "."))[1] or t.fps);
	fps.TextSize = 14;
	fps.TextColor3 = Color3.fromRGB(255, 255, 255);
	fps.TextXAlignment = Enum.TextXAlignment.Center;
	fps.ZIndex = 15;
	btn.MouseEnter:Connect(function()
		tbg(btn, Color3.fromRGB(255, 255, 255));
	end);
	btn.MouseLeave:Connect(function()
		tbg(btn, Color3.fromRGB(235, 235, 235));
	end);
	btn.MouseButton1Down:Connect(function()
		local pl = (S("Players")).LocalPlayer;
		local job = t.id;
		local pid = idBox.Text;
		(S("TeleportService")):TeleportToPlaceInstance(pid, job, pl);
	end);
	row.MouseEnter:Connect(function()
		(tw:Create(row, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.02
		})):Play();
	end);
	row.MouseLeave:Connect(function()
		(tw:Create(row, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.08
		})):Play();
	end);
end;
local function pull(url)
	local r = req({
		Url = url,
		Method = "GET"
	});
	if not r or (not r.Body) then
		return nil;
	end;
	if typeof(r.StatusCode) == "number" and (r.StatusCode < 200 or r.StatusCode >= 300) then
		return nil;
	end;
	local body = r.Body;
	if type(body) ~= "string" or #body == 0 then
		return nil;
	end;
	local ok, d = pcall(function()
		return hs:JSONDecode(body);
	end);
	if not ok or type(d) ~= "table" then
		return nil;
	end;
	return d;
end;
local hasCur = false;
local cur = nil;
local function scrapePage(first)
	local pid = tostring(idBox.Text);
	local q = "?sortOrder=Asc&limit=100";
	if not first and cur then
		q = q .. "&cursor=" .. hs:UrlEncode(tostring(cur));
	end;
	local d = nil;
	for _, b in ipairs(srvBases) do
		local url = b .. "/v1/games/" .. pid .. "/servers/Public" .. q;
		d = pull(url);
		if d and type(d.data) == "table" then
			break;
		end;
	end;
	if not d or type(d.data) ~= "table" then
		local wq = "placeId=" .. pid;
		if not first and cur then
			wq = wq .. "&cursor=" .. hs:UrlEncode(tostring(cur));
		end;
		local wurl = srvWorker .. "/servers?" .. wq;
		d = pull(wurl);
	end;
	if not d or type(d.data) ~= "table" then
		return false;
	end;
	cur = d.nextPageCursor;
	hasCur = cur ~= nil;
	for _, t in pairs(d.data) do
		mkRow(t);
	end;
	return true;
end;
local function sortList(kind, up)
	for _, r in ipairs(list:GetChildren()) do
		if r:IsA("Frame") and r.Name == "row" then
			local v = 0;
			if kind == "p" then
				local lb = r:FindFirstChild("cap");
				if lb and lb:IsA("TextLabel") then
					v = tonumber((string.split(lb.Text, "/"))[1]) or 0;
				end;
			elseif kind == "g" then
				local lb = r:FindFirstChild("pg");
				if lb and lb:IsA("TextLabel") then
					v = tonumber((string.split(lb.Text, " "))[1]) or 0;
				end;
			elseif kind == "f" then
				local lb = r:FindFirstChild("fp");
				if lb and lb:IsA("TextLabel") then
					v = tonumber(lb.Text) or 0;
				end;
			end;
			r.LayoutOrder = up and v or (-v);
		end;
	end;
end;
local pUp, gUp, fUp = true, true, true;
local function updHdr()
	hPl.Text = "Players " .. (pUp and "▲" or "▼");
	hPg.Text = "Ping " .. (gUp and "▲" or "▼");
	hFp.Text = "FPS " .. (fUp and "▲" or "▼");
end;
updHdr();
hPl.MouseButton1Down:Connect(function()
	pUp = not pUp;
	updHdr();
	sortList("p", pUp);
end);
hPg.MouseButton1Down:Connect(function()
	gUp = not gUp;
	updHdr();
	sortList("g", gUp);
end);
hFp.MouseButton1Down:Connect(function()
	fUp = not fUp;
	updHdr();
	sortList("f", fUp);
end);
if list.AutomaticCanvasSize ~= Enum.AutomaticSize.Y then
	local function updCanvas()
		task.wait();
		list.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 16);
	end;
	updCanvas();
	list.ChildAdded:Connect(updCanvas);
	list.ChildRemoved:Connect(updCanvas);
end;
local function doScrape()
	wipe();
	cur = nil;
	hasCur = false;
	scrapePage(true);
	while hasCur do
		if not scrapePage(false) then
			break;
		end;
	end;
	if autoPing then
		gUp = true;
		updHdr();
		sortList("g", true);
	end;
end;
refBtn.MouseButton1Down:Connect(doScrape);
cpBtn.MouseButton1Down:Connect(function()
	local plrs = (S("Players")):GetPlayers();
	local s = "";
	for i = 1, #plrs do
		s = s .. "\n" .. plrs[i].Name;
	end;
	if setclipboard then
		setclipboard(s);
	end;
end);
hideBtn.MouseButton1Down:Connect(function()
	hideFull = not hideFull;
	hideBtn.Text = "Hide full: " .. (hideFull and "ON" or "OFF");
	doScrape();
end);
autoBtn.MouseButton1Down:Connect(function()
	autoPing = not autoPing;
	autoBtn.Text = "Auto ping sort: " .. (autoPing and "ON" or "OFF");
	doScrape();
end);
setOpen(true);
doScrape();
