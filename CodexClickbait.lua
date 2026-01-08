if type(_G.CodexUiCustomSettings) ~= "table" then
	_G.CodexUiCustomSettings = {
		CodexSpooferImage = 17120020964,
		CodexSpooferText = "ScriptWare",
		CodexSpooferPoweredBy = "Powered by Vyperia",
		FloatingIconColor = Color3.fromRGB(0, 51, 102),
		MainUiBackground = Color3.fromRGB(0, 51, 102),
		IconsOn = Color3.fromRGB(0, 128, 255),
		IconsOff = Color3.fromRGB(255, 255, 255),
		Fade = false
	};
end;
local settings = _G.CodexUiCustomSettings;
local defaultFloating = Color3.fromRGB(0, 51, 102);
local defaultMainBg = Color3.fromRGB(0, 51, 102);
local defaultImage = 17120020964;
local defaultText = "ScriptWare";
local defaultPowered = "Powered by Vyperia";
local defaultIconsOn = Color3.fromRGB(0, 128, 255);
local defaultIconsOff = Color3.fromRGB(255, 255, 255);
local floatingColor = typeof(settings.FloatingIconColor) == "Color3" and settings.FloatingIconColor or defaultFloating;
local MainUiBackground = typeof(settings.MainUiBackground) == "Color3" and settings.MainUiBackground or defaultMainBg;
local image = (type(settings.CodexSpooferImage) == "number" or type(settings.CodexSpooferImage) == "string") and settings.CodexSpooferImage or defaultImage;
local text = type(settings.CodexSpooferText) == "string" and settings.CodexSpooferText or defaultText;
local powered = type(settings.CodexSpooferPoweredBy) == "string" and settings.CodexSpooferPoweredBy or defaultPowered;
local Fadeobject = settings.Fade;
if Fadeobject == nil then
	Fadeobject = true;
end;
local IconsOn = typeof(settings.IconsOn) == "Color3" and settings.IconsOn or defaultIconsOn;
local IconsOff = typeof(settings.IconsOff) == "Color3" and settings.IconsOff or defaultIconsOff;
local targetR, targetG, targetB = 235, 69, 69;
local function isNearRed(col)
	if typeof(col) ~= "Color3" then
		return false;
	end;
	local r = math.floor(col.R * 255 + 0.5);
	local g = math.floor(col.G * 255 + 0.5);
	local b = math.floor(col.B * 255 + 0.5);
	local dr, dg, db = r - targetR, g - targetG, b - targetB;
	return dr * dr + dg * dg + db * db <= 35 * 35;
end;
_G.LoadedCodexSwitcher = {
	settings,
	tick(),
	math.random(0, 10000)
};
local patch = _G.LoadedCodexSwitcher;
local iconConnections = {};
local uiRoot;
pcall(function()
	if gethui then
		uiRoot = gethui();
	end;
end);
if not uiRoot then
	uiRoot = game:GetService("CoreGui");
end;
repeat
	task.wait();
until uiRoot:FindFirstChild("Codex");
local CodexFolder = uiRoot:FindFirstChild("Codex");
if not CodexFolder then
	return warn("Codex folder not found");
end;
local curUi = CodexFolder:FindFirstChild("gui");
local CodexUi = CodexFolder;
local gui = nil;
if _G.Codex_gui_Object and typeof(_G.Codex_gui_Object) == "Instance" and _G.Codex_gui_Object.Parent then
	gui = _G.Codex_gui_Object;
elseif curUi and typeof(curUi) == "Instance" then
	gui = curUi;
end;
if not gui then
	return warn("unable to find codex gui");
end;
_G.Codex_gui_Object = gui;
local function HideForever(object)
	if not (object and object:IsA("GuiObject")) then
		return;
	end;
	object.Visible = false;
	local conn;
	conn = (object:GetPropertyChangedSignal("Visible")):Connect(function()
		if conn and _G.LoadedCodexSwitcher ~= patch then
			conn:Disconnect();
			conn = nil;
			return;
		end;
		object.Visible = false;
	end);
end;
if Fadeobject and gui:FindFirstChild("fade") then
	HideForever(gui.fade);
end;
local tabs = gui:FindFirstChild("tabs");
if tabs and tabs:FindFirstChild("editor") and tabs.editor:FindFirstChild("contentContainer") then
	local inputBox = tabs.editor.contentContainer:FindFirstChild("inputBox");
	if inputBox and inputBox:IsA("TextBox") then
		inputBox.MultiLine = true;
	end;
end;
local navbar = gui:FindFirstChild("navbar");
local background = gui:FindFirstChild("background");
if navbar then
	local main = navbar:FindFirstChild("main");
	local floatingIcon = navbar:FindFirstChild("floatingIcon");
	if floatingIcon and floatingIcon:IsA("GuiObject") then
		floatingIcon.BackgroundColor3 = floatingColor;
	end;
	if floatingIcon then
		local codexIcon2 = floatingIcon:FindFirstChild("codexIcon2");
		if codexIcon2 and (codexIcon2:IsA("ImageLabel") or codexIcon2:IsA("ImageButton")) then
			local targetImage = "rbxassetid://" .. image;
			codexIcon2.Image = targetImage;
			local codexConn;
			codexConn = (codexIcon2:GetPropertyChangedSignal("Image")):Connect(function()
				if codexConn and _G.LoadedCodexSwitcher ~= patch then
					codexConn:Disconnect();
					codexConn = nil;
					return;
				end;
				if codexIcon2.Image ~= targetImage then
					codexIcon2.Image = targetImage;
				end;
			end);
			table.insert(iconConnections, codexConn);
		end;
	end;
	if main and main:IsA("Frame") then
		main.BackgroundColor3 = MainUiBackground;
		local codexIcon = main:FindFirstChild("codexIcon");
		if codexIcon and codexIcon:IsA("ImageLabel") then
			codexIcon.Image = "rbxassetid://" .. image;
		end;
		local titleLabel = main:FindFirstChild("title");
		if titleLabel and titleLabel:IsA("TextLabel") then
			titleLabel.Text = text;
		end;
	end;
end;
if background and background:IsA("Frame") then
	background.BackgroundColor3 = MainUiBackground;
end;
if _G.LoadedCodexSwitcherHooks and type(_G.LoadedCodexSwitcherHooks) == "table" then
	for _, v in pairs(_G.LoadedCodexSwitcherHooks) do
		if typeof(v) == "RBXScriptConnection" then
			pcall(function()
				v:Disconnect();
			end);
		elseif type(v) == "table" then
			for _, c in pairs(v) do
				if typeof(c) == "RBXScriptConnection" then
					pcall(function()
						c:Disconnect();
					end);
				end;
			end;
		end;
	end;
	_G.LoadedCodexSwitcherHooks = {};
end;
local function ChangeIcon(object)
	if not (object and object:IsA("GuiButton")) then
		return;
	end;
	local icon = object:FindFirstChild("icon");
	if not (icon and icon:IsA("ImageLabel")) then
		return;
	end;
	local iconConnection;
	iconConnection = (icon:GetPropertyChangedSignal("ImageColor3")):Connect(function()
		if _G.LoadedCodexSwitcher ~= patch then
			if iconConnection then
				iconConnection:Disconnect();
				iconConnection = nil;
			end;
			return;
		end;
		if icon.ImageColor3 == Color3.fromRGB(151, 158, 189) then
			icon.ImageColor3 = IconsOff;
		elseif icon.ImageColor3 == IconsOff or icon.ImageColor3 == IconsOn then
			return;
		else
			icon.ImageColor3 = IconsOn;
		end;
	end);
	table.insert(iconConnections, iconConnection);
	icon.ImageColor3 = IconsOff;
end;
local function HookEditorButton(btn)
	if not (btn and btn:IsA("TextButton")) then
		return;
	end;
	local function apply(obj)
		if obj:IsA("TextButton") or obj:IsA("Frame") then
			if isNearRed(obj.BackgroundColor3) then
				obj.BackgroundColor3 = IconsOn;
			end;
		end;
	end;
	apply(btn);
	for _, d in ipairs(btn:GetDescendants()) do
		apply(d);
	end;
	local function hookObj(obj)
		if not (obj:IsA("TextButton") or obj:IsA("Frame")) then
			return;
		end;
		local conn;
		conn = (obj:GetPropertyChangedSignal("BackgroundColor3")):Connect(function()
			if conn and _G.LoadedCodexSwitcher ~= patch then
				conn:Disconnect();
				conn = nil;
				return;
			end;
			apply(obj);
		end);
		table.insert(iconConnections, conn);
		apply(obj);
	end;
	hookObj(btn);
	for _, d in ipairs(btn:GetDescendants()) do
		hookObj(d);
	end;
	local descConn;
	descConn = btn.DescendantAdded:Connect(function(ch)
		if descConn and _G.LoadedCodexSwitcher ~= patch then
			descConn:Disconnect();
			descConn = nil;
			return;
		end;
		apply(ch);
		hookObj(ch);
	end);
	table.insert(iconConnections, descConn);
end;
local function HookTabsFolder(f)
	if not (f and f:IsA("Folder")) then
		return;
	end;
	local function apply(o)
		if o:IsA("Frame") or o:IsA("TextButton") then
			if isNearRed(o.BackgroundColor3) then
				o.BackgroundColor3 = IconsOn;
			end;
		elseif o:IsA("UIStroke") then
			if isNearRed(o.Color) then
				o.Color = IconsOn;
			end;
		end;
	end;
	local function hookObj(o)
		if o:IsA("Frame") or o:IsA("TextButton") then
			local c1;
			c1 = (o:GetPropertyChangedSignal("BackgroundColor3")):Connect(function()
				if c1 and _G.LoadedCodexSwitcher ~= patch then
					c1:Disconnect();
					c1 = nil;
					return;
				end;
				apply(o);
			end);
			table.insert(iconConnections, c1);
			apply(o);
		elseif o:IsA("UIStroke") then
			local c2;
			c2 = (o:GetPropertyChangedSignal("Color")):Connect(function()
				if c2 and _G.LoadedCodexSwitcher ~= patch then
					c2:Disconnect();
					c2 = nil;
					return;
				end;
				apply(o);
			end);
			table.insert(iconConnections, c2);
			apply(o);
		end;
	end;
	for _, o in ipairs(f:GetDescendants()) do
		apply(o);
		hookObj(o);
	end;
	local dConn;
	dConn = f.DescendantAdded:Connect(function(o)
		if dConn and _G.LoadedCodexSwitcher ~= patch then
			dConn:Disconnect();
			dConn = nil;
			return;
		end;
		apply(o);
		hookObj(o);
	end);
	table.insert(iconConnections, dConn);
end;
if navbar then
	local main = navbar:FindFirstChild("main");
	if main and main:IsA("Frame") then
		local container = main:FindFirstChild("container");
		if container and container:IsA("Frame") then
			for _, v in ipairs(container:GetChildren()) do
				if v:IsA("TextButton") then
					task.spawn(ChangeIcon, v);
				end;
			end;
		end;
		local settingsBtn = main:FindFirstChild("settings");
		if settingsBtn and settingsBtn:IsA("TextButton") then
			ChangeIcon(settingsBtn);
		end;
		local titleLabel = main:FindFirstChild("title");
		local poweredByLabel = main:FindFirstChild("poweredBy");
		if titleLabel and titleLabel:IsA("TextLabel") then
			local titleConn;
			titleConn = (titleLabel:GetPropertyChangedSignal("Text")):Connect(function()
				if titleConn and _G.LoadedCodexSwitcher ~= patch then
					titleConn:Disconnect();
					titleConn = nil;
					return;
				end;
				titleLabel.Text = text;
			end);
			table.insert(iconConnections, titleConn);
			titleLabel.Text = text;
		end;
		if poweredByLabel and poweredByLabel:IsA("TextLabel") then
			local poweredConn;
			poweredConn = (poweredByLabel:GetPropertyChangedSignal("Text")):Connect(function()
				if poweredConn and _G.LoadedCodexSwitcher ~= patch then
					poweredConn:Disconnect();
					poweredConn = nil;
					return;
				end;
				poweredByLabel.Text = powered;
			end);
			table.insert(iconConnections, poweredConn);
			poweredByLabel.Text = powered;
		end;
	end;
end;
if tabs then
	for _, tab in ipairs(tabs:GetChildren()) do
		local buttons = tab:FindFirstChild("buttons");
		if buttons and buttons:IsA("Frame") then
			for _, v in ipairs(buttons:GetChildren()) do
				if v:IsA("TextButton") then
					task.spawn(ChangeIcon, v);
				end;
			end;
		end;
	end;
	local editor = tabs:FindFirstChild("editor");
	local localScripts = tabs:FindFirstChild("localScripts");
	local exploitSettings = tabs:FindFirstChild("exploitSettings");
	if editor and editor:IsA("Frame") then
		local edButtons = editor:FindFirstChild("buttons");
		if edButtons and edButtons:IsA("Frame") then
			for _, v in ipairs(edButtons:GetChildren()) do
				if v:IsA("TextButton") then
					task.spawn(HookEditorButton, v);
				end;
			end;
		end;
		local tabButtons = editor:FindFirstChild("tabButtons");
		if tabButtons and tabButtons:IsA("ScrollingFrame") then
			for _, v in ipairs(tabButtons:GetChildren()) do
				if v:IsA("TextButton") then
					task.spawn(HookEditorButton, v);
				end;
			end;
		end;
	end;
	if localScripts and localScripts:IsA("Frame") then
		local tbBtns = localScripts:FindFirstChild("tabButtons");
		if tbBtns and tbBtns:IsA("ScrollingFrame") then
			for _, v in ipairs(tbBtns:GetChildren()) do
				if v:IsA("TextButton") then
					task.spawn(HookEditorButton, v);
				end;
			end;
		end;
		local lsTabs = localScripts:FindFirstChild("tabs");
		if lsTabs and lsTabs:IsA("Folder") then
			HookTabsFolder(lsTabs);
		end;
	end;
	if exploitSettings and exploitSettings:IsA("Frame") then
		local tbBtns = exploitSettings:FindFirstChild("tabButtons");
		if tbBtns and tbBtns:IsA("ScrollingFrame") then
			for _, v in ipairs(tbBtns:GetChildren()) do
				if v:IsA("TextButton") then
					task.spawn(HookEditorButton, v);
				end;
			end;
		end;
		local exTabs = exploitSettings:FindFirstChild("tabs");
		if exTabs and exTabs:IsA("Folder") then
			HookTabsFolder(exTabs);
		end;
	end;
end;
_G.LoadedCodexSwitcherHooks = {
	Icons = iconConnections
};
