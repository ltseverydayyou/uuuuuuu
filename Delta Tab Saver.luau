if not (identifyexecutor()):lower() == "delta" then
	return;
end;
local deltaEnv = type(getgenv) == "function" and getgenv() or _G;
if type(deltaEnv) == "table" then
	if deltaEnv.__DeltaTabSaverLoaded then
		return;
	end;
	deltaEnv.__DeltaTabSaverLoaded = true;
end;
local SRV = setmetatable({}, {
	__index = function(self, n)
		local ref = cloneref and type(cloneref) == "function" and cloneref or function(v)
			return v;
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
local function Svc(n)
	return SRV[n];
end;
local UIS = Svc("UserInputService");
local CG = Svc("CoreGui");
local notifMod;
local nt;
do
	local n = nil;
	local tries = 0;
	repeat
		tries += 1;
		local s, r = pcall(function()
			return (loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/NamelessAdminNotifications.lua")))();
		end);
		if s and type(r) == "table" and type(r.Notify) == "function" then
			n = r;
			notifMod = r;
			nt = r.Notify;
		else
			task.wait(0.5);
		end;
	until n ~= nil or tries >= 5;
end;
local function notify(info)
	if not nt or type(info) ~= "table" then
		return;
	end;
	pcall(function()
		nt(info);
	end);
end;
local _naConns = _naConns or {};
local NAlib = {};
function NAlib.disconnect(n)
	local t = _naConns[n];
	if t then
		for _, c in ipairs(t) do
			pcall(function()
				c:Disconnect();
			end);
		end;
		_naConns[n] = nil;
	end;
end;
function NAlib.connect(n, c)
	if not c then
		return;
	end;
	_naConns[n] = _naConns[n] or {};
	table.insert(_naConns[n], c);
	return c;
end;
function NAlib.isProperty(o, p)
	return pcall(function()
		return o[p];
	end);
end;
function NAlib.setProperty(o, p, v)
	pcall(function()
		o[p] = v;
	end);
end;
local uiLib = {};
uiLib.draggerV2 = function(ui, dragui)
	dragui = dragui or ui;
	local dragging, dragInput, dragStart, startPos;
	local anchor = ui.AnchorPoint;
	local sg = ui:FindFirstAncestorWhichIsA("ScreenGui") or ui.Parent;
	local function sClamp(v, lo, hi)
		if hi < lo then
			hi = lo;
		end;
		return math.clamp(v, lo, hi);
	end;
	local function upd(input)
		pcall(function()
			local p = sg.AbsoluteSize;
			local s = ui.AbsoluteSize;
			if p.X <= 0 or p.Y <= 0 then
				return;
			end;
			local sx = startPos.X.Scale * p.X + startPos.X.Offset;
			local sy = startPos.Y.Scale * p.Y + startPos.Y.Offset;
			local dx = input.Position.X - dragStart.X;
			local dy = input.Position.Y - dragStart.Y;
			local minX = anchor.X * s.X;
			local maxX = p.X - (1 - anchor.X) * s.X;
			local minY = anchor.Y * s.Y;
			local maxY = p.Y - (1 - anchor.Y) * s.Y;
			local nx = sClamp(sx + dx, minX, maxX);
			local ny = sClamp(sy + dy, minY, maxY);
			ui.Position = UDim2.new(nx / p.X, 0, ny / p.Y, 0);
		end);
	end;
	local id = "DraggerV2_" .. ui:GetDebugId();
	NAlib.disconnect(id);
	NAlib.connect(id, dragui.InputBegan:Connect(function(input)
		pcall(function()
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true;
				dragStart = input.Position;
				startPos = ui.Position;
				local c = input.Changed:Connect(function()
					pcall(function()
						if input.UserInputState == Enum.UserInputState.End then
							dragging = false;
						end;
					end);
				end);
				NAlib.connect(id, c);
			end;
		end);
	end));
	NAlib.connect(id, dragui.InputChanged:Connect(function(input)
		pcall(function()
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input;
			end;
		end);
	end));
	NAlib.connect(id, UIS.InputChanged:Connect(function(input)
		pcall(function()
			if input == dragInput and dragging then
				upd(input);
			end;
		end);
	end));
	local function clampToView()
		pcall(function()
			local p = sg.AbsoluteSize;
			local s = ui.AbsoluteSize;
			if p.X <= 0 or p.Y <= 0 then
				return;
			end;
			local pos = ui.Position;
			local ax = pos.X.Scale * p.X + pos.X.Offset;
			local ay = pos.Y.Scale * p.Y + pos.Y.Offset;
			local minX = anchor.X * s.X;
			local maxX = p.X - (1 - anchor.X) * s.X;
			local minY = anchor.Y * s.Y;
			local maxY = p.Y - (1 - anchor.Y) * s.Y;
			local nx = sClamp(ax, minX, maxX);
			local ny = sClamp(ay, minY, maxY);
			ui.Position = UDim2.new(nx / p.X, 0, ny / p.Y, 0);
		end);
	end;
	NAlib.connect(id, (sg:GetPropertyChangedSignal("AbsoluteSize")):Connect(clampToView));
	if ui and ui.GetPropertyChangedSignal then
		NAlib.connect(id, (ui:GetPropertyChangedSignal("AbsoluteSize")):Connect(clampToView));
	end;
	clampToView();
	if ui and NAlib.isProperty(ui, "Active") then
		NAlib.setProperty(ui, "Active", true);
	end;
	if dragui and NAlib.isProperty(dragui, "Active") then
		NAlib.setProperty(dragui, "Active", true);
	end;
end;
local root = gethui and gethui() or CG;
local function isGib(n)
	if typeof(n) ~= "string" or n == "" then
		return false;
	end;
	return not n:match("^[%w _%-]+$");
end;
local function getMain()
	for _, g in ipairs(root:GetChildren()) do
		if g:IsA("ScreenGui") and isGib(g.Name) then
			if g:FindFirstChild("Executor", true) and g:FindFirstChild("Scripthub", true) and g:FindFirstChild("Sidebar", true) then
				return g;
			end;
		end;
	end;
end;
local function getIconGui()
	local function chk(g)
		if not (g:IsA("ScreenGui") and isGib(g.Name)) then
			return;
		end;
		local kids = g:GetChildren();
		local img;
		local cnt = 0;
		for _, c in ipairs(kids) do
			if c:IsA("ImageButton") then
				cnt += 1;
				img = c;
			else
				return;
			end;
		end;
		if cnt == 1 then
			return g, img;
		end;
	end;
	for _, g in ipairs(root:GetChildren()) do
		local ig, ib = chk(g);
		if ig then
			return ig, ib;
		end;
	end;
end;
local mainGui = getMain();
local iconGui, iconBtn = getIconGui();
if iconGui and iconGui:IsA("ScreenGui") then
	pcall(function()
		iconGui.IgnoreGuiInset = true;
	end);
end;
if iconBtn then
	pcall(function()
		iconBtn.Draggable = false;
	end);
	uiLib.draggerV2(iconBtn, iconBtn);
end;
task.defer(function()
	while not mainGui do
		mainGui = getMain();
		if mainGui then
			break;
		end;
		task.wait(0.1);
	end;
	if not mainGui then
		notify({
			Title = "Delta Tabs",
			Description = "Failed to find Delta UI.",
			Duration = 4
		});
		return;
	end;
	local execFrame = mainGui:FindFirstChild("Executor");
	if not (execFrame and execFrame:IsA("Frame")) then
		notify({
			Title = "Delta Tabs",
			Description = "Executor frame not found.",
			Duration = 4
		});
		return;
	end;
	local execImage = execFrame:FindFirstChild("Executor");
	if not (execImage and execImage:IsA("ImageLabel")) then
		notify({
			Title = "Delta Tabs",
			Description = "Executor image not found.",
			Duration = 4
		});
		return;
	end;
	local overlay = execImage:FindFirstChild("Overlay");
	if not overlay then
		notify({
			Title = "Delta Tabs",
			Description = "Overlay frame not found.",
			Duration = 4
		});
		return;
	end;
	local sidemenu = execFrame:FindFirstChild("Sidemenu", true);
	if sidemenu then
		local oldBtn = sidemenu:FindFirstChild("Script", true);
		if oldBtn and oldBtn:IsA("ImageLabel") then
			local parent = oldBtn.Parent;
			local newBtn = oldBtn:Clone();
			oldBtn:Destroy();
			newBtn.Parent = parent;
			newBtn.Name = "Script";
			local labs = {};
			for _, d in ipairs(newBtn:GetDescendants()) do
				if d:IsA("TextLabel") then
					table.insert(labs, d);
				end;
			end;
			if #labs >= 3 then
				table.sort(labs, function(a, b)
					return a.AbsolutePosition.Y < b.AbsolutePosition.Y;
				end);
				local bigHeader = labs[1];
				local subTitle = labs[2];
				local desc = labs[3];
				if bigHeader then
					bigHeader.Text = "Featured";
				end;
				if subTitle then
					subTitle.Text = "Nameless Admin";
				end;
				if desc then
					desc.Text = "continuation of Nameless Admin with advanced features, fixed commands and lots of customization.";
				end;
			end;
			for _, d in ipairs(newBtn:GetDescendants()) do
				if d:IsA("LocalScript") then
					d:Destroy();
				end;
			end;
			local clickable = newBtn:FindFirstChildWhichIsA("GuiButton") or newBtn;
			local function runNA()
				pcall(function()
					(loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua")))();
				end);
			end;
			if clickable:IsA("GuiButton") then
				clickable.MouseButton1Click:Connect(runNA);
			else
				clickable.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						runNA();
					end;
				end);
			end;
		end;
	end;
	local tabs = overlay:FindFirstChild("Tabs", true);
	local codeSf = overlay:FindFirstChild("Code", true);
	if not tabs then
		notify({
			Title = "Delta Tabs",
			Description = "Tabs frame not found.",
			Duration = 4
		});
		return;
	end;
	if not codeSf then
		notify({
			Title = "Delta Tabs",
			Description = "Code frame not found.",
			Duration = 4
		});
		return;
	end;
	local btns = overlay:FindFirstChild("Buttons", true);
	if btns then
		local bl = {};
		for _, v in ipairs(btns:GetChildren()) do
			if v:IsA("ImageButton") or v:IsA("TextButton") then
				table.insert(bl, v);
			end;
		end;
		local tpl = btns:FindFirstChild("ExecuteClipboard") or btns:FindFirstChild("Execute") or bl[1];
		if tpl then
			local cp = tpl:Clone();
			cp.Name = "CopyCode";
			local tl = cp:FindFirstChild("Title", true) or cp:FindFirstChildWhichIsA("TextLabel");
			if tl then
				tl.Text = "Copy Code";
			end;
			cp.Parent = btns;
			table.insert(bl, cp);
			local cnt = #bl;
			if cnt > 0 then
				local w;
				if cnt == 4 then
					w = 0.22;
				else
					w = 1 / cnt;
				end;
				for _, b in ipairs(bl) do
					b.Size = UDim2.new(w, 0, 1, 0);
				end;
			end;
			cp.MouseButton1Click:Connect(function()
				if type(setclipboard) ~= "function" then
					return;
				end;
				local cur;
				for _, tb in ipairs(codeSf:GetDescendants()) do
					if tb:IsA("TextBox") and tb.Visible then
						cur = tb;
						break;
					end;
				end;
				if cur then
					setclipboard(cur.Text or "");
					notify({
						Title = "Delta Tabs",
						Description = "Copied code from the selected tab.",
						Duration = 4
					});
				end;
			end);
		end;
	end;
	local hasFS = type(isfolder) == "function" and type(makefolder) == "function" and type(isfile) == "function" and type(writefile) == "function" and type(readfile) == "function" and type(listfiles) == "function";
	if not hasFS then
		notify({
			Title = "Delta Tabs",
			Description = "Your executor does not support saving tabs.",
			Duration = 5
		});
		return;
	end;
	local dir = "DeltaTabs";
	if not isfolder(dir) then
		pcall(function()
			makefolder(dir);
		end);
	end;
	local function parseIndex(nm)
		local n = nm:match("^script(%d+)%.lua$");
		return tonumber(n);
	end;
	local function isScriptName(nm)
		return parseIndex(nm) ~= nil;
	end;
	local function getCodeBoxes()
		local t = {};
		for _, c in ipairs(codeSf:GetDescendants()) do
			if c:IsA("TextBox") and isScriptName(c.Name) then
				table.insert(t, c);
			end;
		end;
		table.sort(t, function(a, b)
			return (parseIndex(a.Name) or 0) < (parseIndex(b.Name) or 0);
		end);
		return t;
	end;
	local function getSavedNames()
		local list = {};
		for _, p in ipairs(listfiles(dir)) do
			local nm = p:match("([^/\\]+)$");
			if nm and isScriptName(nm) then
				table.insert(list, nm);
			end;
		end;
		table.sort(list, function(a, b)
			return (parseIndex(a) or 0) < (parseIndex(b) or 0);
		end);
		return list;
	end;
	local saved = getSavedNames();
	local boxes = getCodeBoxes();
	if #saved > 0 then
		local desc;
		if #saved > (#boxes) then
			desc = "Saved tabs: " .. tostring(#saved) .. "\nCreate your tabs in Delta and the saved code will load automatically.";
		else
			desc = "Saved tabs: " .. tostring(#saved) .. "\nYour saved code will load into matching tabs automatically.";
		end;
		notify({
			Title = "Delta Tabs",
			Description = desc,
			Duration = 8
		});
	else
		notify({
			Title = "Delta Tabs",
			Description = "No saved tabs yet. Anything you type will be saved automatically.",
			Duration = 6
		});
	end;
	local hooked = {};
	local function hookBox(box)
		if not box or hooked[box] then
			return;
		end;
		hooked[box] = true;
		local ready = false;
		local function setupForName(nm)
			if ready then
				return;
			end;
			if not isScriptName(nm) then
				return;
			end;
			ready = true;
			local nameForFile = nm;
			local path = dir .. "/" .. nameForFile;
			if isfile(path) then
				local ok, data = pcall(readfile, path);
				if ok and type(data) == "string" then
					box.Text = data;
				end;
			end;
			local last = 0;
			(box:GetPropertyChangedSignal("Text")):Connect(function()
				last = tick();
				local id = last;
				task.delay(0.4, function()
					if id ~= last then
						return;
					end;
					local txt = box.Text;
					pcall(function()
						writefile(path, txt);
					end);
				end);
			end);
		end;
		setupForName(box.Name);
		(box:GetPropertyChangedSignal("Name")):Connect(function()
			setupForName(box.Name);
		end);
	end;
	for _, b in ipairs(boxes) do
		hookBox(b);
	end;
	codeSf.DescendantAdded:Connect(function(obj)
		if obj:IsA("TextBox") then
			task.wait(0.05);
			hookBox(obj);
		end;
	end);
	codeSf.DescendantRemoving:Connect(function(obj)
		if obj:IsA("TextBox") and isScriptName(obj.Name) and type(delfile) == "function" then
			local path = dir .. "/" .. obj.Name;
			if isfile(path) then
				pcall(function()
					delfile(path);
				end);
			end;
		end;
	end);
end);
