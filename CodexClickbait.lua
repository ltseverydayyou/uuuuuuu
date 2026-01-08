if not _G.CodexUiCustomSettings then
	_G.CodexUiCustomSettings = {
		CodexSpooferImage = 9524079125,
		CodexSpooferText = "Synapse X",
		CodexSpooferPoweredBy = "Powered by Nameless Admin",
		FloatingIconColor = Color3.fromRGB(59, 59, 59),
		MainUiBackground = Color3.fromRGB(20, 20, 20),
		Icons = Color3.fromRGB(170, 85, 127),
		IconsOff = Color3.fromRGB(0, 0, 0),
		Fade = true
	};
end;
_G.LoadedCodexSwitcher = {
	_G.CodexUiCustomSettings,
	tick(),
	math.random(0, 10000)
};
local patch = _G.LoadedCodexSwitcher;
local floatingColor = _G.CodexUiCustomSettings.FloatingIconColor or Color3.fromRGB(59, 59, 59);
local MainUiBackground = _G.CodexUiCustomSettings.MainUiBackground or Color3.fromRGB(20, 20, 20);
local image = _G.CodexUiCustomSettings.CodexSpooferImage or 9524079125;
local text = _G.CodexUiCustomSettings.CodexSpooferText or "Synapse X";
local powered = _G.CodexUiCustomSettings.CodexSpooferPoweredBy or "Powered by Nameless Admin";
local Fadeobject = _G.CodexUiCustomSettings.Fade or true;
local IconsOn = _G.CodexUiCustomSettings.IconsOn or Color3.fromRGB(170, 85, 127);
local IconsOff = _G.CodexUiCustomSettings.IconsOff or Color3.fromRGB(0, 0, 0);
repeat
	task.wait();
until gethui():FindFirstChild("Codex");
local CodexFolder = gethui():FindFirstChild("Codex");
local curUi = (gethui():FindFirstChild("Codex")).gui;
local CodexUi = (gethui():WaitForChild("Codex"));
local gui = nil;
if CodexUi or _G.Codex_gui_Object then
	gui = _G.Codex_gui_Object or curUi;
end;
if not gui then
	return warn("unable to find codex");
end;
_G.Codex_gui_Object = gui;
local function HideForever(object)
	object.Visible = false;
	Patch1 = (object:GetPropertyChangedSignal("Visible")):Connect(function()
		if Patch1 and _G.LoadedCodexSwitcher ~= patch then
			Patch1:Disconnect();
		end;
		object.Visible = false;
	end);
end;
if Fadeobject then
	HideForever(gui:WaitForChild("fade"));
end;
gui.tabs.editor.contentContainer.inputBox.MultiLine = true;
gui.navbar.floatingIcon.codexIcon2.Image = "http://www.roblox.com/asset/?id=" .. image;
gui.navbar.main.codexIcon.Image = "http://www.roblox.com/asset/?id=" .. image;
gui.navbar.main.title.Text = text;
if _G.LoadedCodexSwitcherHooks then
	for i, v in pairs(_G.LoadedCodexSwitcherHooks) do
		if v then
			pcall(function()
				v:Disconnect();
			end);
		end;
	end;
	_G.LoadedCodexSwitcherHooks = {};
end;
local iconConnections = {};
local function ChangeIcon(object)
	local iconConnection;
	local icon = object:WaitForChild("icon");
	iconConnection = (icon:GetPropertyChangedSignal("ImageColor3")):Connect(function()
		if Color3.fromRGB(151, 158, 189) == icon.ImageColor3 then
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
gui.navbar.floatingIcon.BackgroundColor3 = floatingColor;
gui.navbar.main.BackgroundColor3 = MainUiBackground;
gui.background.BackgroundColor3 = MainUiBackground;
for i, v in pairs(gui.navbar.main.container:GetChildren()) do
	if v:IsA("TextButton") then
		task.spawn(function()
			ChangeIcon(v);
		end);
	end;
end;
ChangeIcon(gui.navbar.main.settings);
for i, v in pairs(gui.tabs:GetChildren()) do
	if v:FindFirstChild("buttons") then
		for i, v in pairs(v.buttons:GetChildren()) do
			if v:IsA("TextButton") then
				task.spawn(function()
					ChangeIcon(v);
				end);
			end;
		end;
	end;
end;
title = (gui.navbar.main.title:GetPropertyChangedSignal("Text")):Connect(function()
	if title and _G.LoadedCodexSwitcher ~= patch then
		title:Disconnect();
	end;
	gui.navbar.main.title.Text = text;
end);
title1 = (gui.navbar.main.poweredBy:GetPropertyChangedSignal("Text")):Connect(function()
	if title1 and _G.LoadedCodexSwitcher ~= patch then
		title1:Disconnect();
	end;
	gui.navbar.main.poweredBy.Text = powered;
end);
gui.navbar.main.poweredBy.Text = powered;
_G.LoadedCodexSwitcherHooks = {
	Icons = iconConnections
};
