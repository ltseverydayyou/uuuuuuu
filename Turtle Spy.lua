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
local __NAOriginalGetHui = gethui;
local gethui = function()
	if __NAUIProtector and type(__NAUIProtector.huiGrabber) == "function" then
		local ok, ui = pcall(__NAUIProtector.huiGrabber);
		if ok and typeof(ui) == "Instance" then
			return ui;
		end;
	end;
	if type(__NAOriginalGetHui) == "function" then
		local ok, ui = pcall(__NAOriginalGetHui);
		if ok then
			return ui;
		end;
	end;
	return nil;
end;
local function __NAProtectUI(gui, options)
	if __NAUIProtector and type(__NAUIProtector.protectUI) == "function" then
		local ok, protected = pcall(__NAUIProtector.protectUI, gui, options);
		if ok and protected then
			return protected;
		end;
	end;
	return nil;
end;

local colorSettings = {
	Main = {
		HeaderColor = Color3.fromRGB(0, 168, 255),
		HeaderShadingColor = Color3.fromRGB(0, 151, 230),
		HeaderTextColor = Color3.fromRGB(47, 54, 64),
		MainBackgroundColor = Color3.fromRGB(47, 54, 64),
		InfoScrollingFrameBgColor = Color3.fromRGB(47, 54, 64),
		ScrollBarImageColor = Color3.fromRGB(127, 143, 166)
	},
	RemoteButtons = {
		BorderColor = Color3.fromRGB(113, 128, 147),
		BackgroundColor = Color3.fromRGB(53, 59, 72),
		TextColor = Color3.fromRGB(220, 221, 225),
		NumberTextColor = Color3.fromRGB(203, 204, 207)
	},
	MainButtons = {
		BorderColor = Color3.fromRGB(113, 128, 147),
		BackgroundColor = Color3.fromRGB(53, 59, 72),
		TextColor = Color3.fromRGB(220, 221, 225)
	},
	Code = {
		BackgroundColor = Color3.fromRGB(35, 40, 48),
		TextColor = Color3.fromRGB(220, 221, 225),
		CreditsColor = Color3.fromRGB(108, 108, 108)
	}
};
local settings = {
	Keybind = "P"
};
if PROTOSMASHER_LOADED then
	(getgenv()).isfile = newcclosure(function(File)
		local Suc = pcall(readfile, File);
		if not Suc then
			return false;
		end;
		return true;
	end);
end;
local function ClonedService(name)
	local Service = function(_, serviceName) return __lt.gs(serviceName); end;
	local Reference = cloneref or function(reference)
		return reference;
	end;
	return __lt.cs(name, Reference);
end;
local HttpService = ClonedService("HttpService");
if not isfile("TurtleSpySettings.json") then
	writefile("TurtleSpySettings.json", __lt.cm("HttpService", "JSONEncode", settings));
elseif (__lt.cm("HttpService", "JSONDecode", readfile("TurtleSpySettings.json"))).Main then
	writefile("TurtleSpySettings.json", __lt.cm("HttpService", "JSONEncode", settings));
else
	settings = __lt.cm("HttpService", "JSONDecode", readfile("TurtleSpySettings.json"));
end;
local function isSynapse()
	if PROTOSMASHER_LOADED then
		return false;
	else
		return true;
	end;
end;
local client = (ClonedService("Players")).LocalPlayer;
local G = getgenv and getgenv() or _G;
G.__tspy = G.__tspy or {};
local tstate = G.__tspy;
tstate.RunService = ClonedService("RunService");
if tstate.cleanup then
	pcall(tstate.cleanup);
end;
tstate.enabled = true;
local pathMode = "dot";
local function toUnicode(stringValue)
	local codepoints = "utf8.char(";
	for _, v in utf8.codes(stringValue) do
		codepoints = codepoints .. v .. ", ";
	end;
	return codepoints:sub(1, -3) .. ")";
end;
local isA = game.IsA;
local clone = game.Clone;
local hookClone = clonefunction or function(fn)
	return fn
end;
local function setMetatableReadonly(mt, readonly)
	if type(setreadonly) == "function" then
		setreadonly(mt, readonly)
		return true
	end
	if readonly then
		if type(make_readonly) == "function" then
			make_readonly(mt)
			return true
		elseif type(makereadonly) == "function" then
			makereadonly(mt)
			return true
		end
	else
		if type(make_writeable) == "function" then
			make_writeable(mt)
			return true
		elseif type(makewritable) == "function" then
			makewritable(mt)
			return true
		elseif type(makewriteable) == "function" then
			makewriteable(mt)
			return true
		end
	end
	return false
end

local function safeCheckCaller()
	if type(checkcaller) ~= "function" then
		return false
	end
	local ok, result = pcall(checkcaller)
	return ok and result or false
end

local function buildHookMetaMethodFallback()
	if type(getrawmetatable) ~= "function" then
		return nil
	end
	if type(hookfunction) ~= "function" and type(setreadonly) ~= "function" and type(make_writeable) ~= "function" and type(makewritable) ~= "function" and type(makewriteable) ~= "function" then
		return nil
	end
	return function(obj, metamethod, func)
		local mt = getrawmetatable(obj)
		if type(mt) ~= "table" then
			return nil
		end
		local old = mt[metamethod]
		if type(hookfunction) == "function" and type(old) == "function" then
			return hookfunction(old, func)
		end
		setMetatableReadonly(mt, false)
		mt[metamethod] = func
		setMetatableReadonly(mt, true)
		return old
	end
end

local function MeasureText(text, size, font, bounds)
	local ts = ClonedService("TextService");
	local ok, v = pcall(function()
		return __lt.cm("TextService", "GetTextSize", text, size, font, bounds or Vector2.new(math.huge, math.huge));
	end);
	if ok then
		return v;
	end;
	return Vector2.new(0, 0);
end;
(ClonedService("StarterGui")).ResetPlayerGuiOnSpawn = false;
local mouse = (ClonedService("Players")).LocalPlayer:GetMouse();
local function formatChild(parentPath, inst)
	local name = inst.Name;
	local safe = name:match("^[%a_][%w_]*$");
	if pathMode == "dot" and safe then
		return parentPath .. "." .. name;
	end;
	local method = pathMode == "wait" and ":WaitForChild(" or ":FindFirstChild(";
	return parentPath .. method .. string.format("%q", name) .. ")";
end;
local getNilSource = "local function getNil(name, class)\n\tif type(getnilinstances) ~= \"function\" then\n\t\treturn nil\n\tend\n\tfor _, v in next, getnilinstances() do\n\t\tif typeof(v) == \"Instance\" and v.Parent == nil and v.ClassName == class and v.Name == name then\n\t\t\treturn v\n\t\tend\n\tend\nend\n\n";
local function getNilInstance(name, class)
	if type(getnilinstances) ~= "function" then
		return nil
	end
	local ok, list = pcall(getnilinstances)
	if not ok or type(list) ~= "table" then
		return nil
	end
	for _, v in next, list do
		if typeof(v) == "Instance" and v.Parent == nil and v.ClassName == class and v.Name == name then
			return v
		end
	end
	return nil
end
if type(G) == "table" and type(rawget(G, "getNil")) ~= "function" then
	G.getNil = getNilInstance
end
local function getNilInstancesSafe()
	if type(getnilinstances) ~= "function" then
		return {}
	end
	local ok, list = pcall(getnilinstances)
	if ok and type(list) == "table" then
		return list
	end
	return {}
end
local function nilPathForInstance(instance)
	return ("getNil(%q, %q)"):format(tostring(instance.Name or ""), tostring(instance.ClassName or "Instance"))
end
local function GetFullPathOfAnInstance(instance)
	if instance == game then
		return "game";
	end;
	if instance == workspace then
		return "workspace";
	end;
	local parent = instance.Parent;
	if not parent then
		return nilPathForInstance(instance);
	end;
	local parentPath = GetFullPathOfAnInstance(parent);
	if parent == game then
		local svcName = instance.ClassName;
		local ok, svc = pcall(function()
			return __lt.gs(svcName);
		end);
		if not ok or svc ~= instance then
			svcName = instance.Name;
			ok, svc = pcall(function()
				return __lt.gs(svcName);
			end);
		end;
		if ok and svc == instance then
			return string.format("game:GetService(%q)", svcName);
		end;
	end;
	local siblings = parent:GetChildren();
	local sameCount = 0;
	local sameIndex = 0;
	for i, child in siblings do
		if child.Name == instance.Name and child.ClassName == instance.ClassName then
			sameCount = sameCount + 1;
			sameIndex = i;
		end;
	end;
	if sameCount > 1 then
		return parentPath .. ":GetChildren()[" .. sameIndex .. "]";
	end;
	if instance == client and parent == ClonedService("Players") then
		return "game:GetService(\"Players\").LocalPlayer";
	end;
	return formatChild(parentPath, instance);
end;
local __NATurtleParent = gethui() or ClonedService("CoreGui");
if __NATurtleParent and __NATurtleParent:FindFirstChild("TurtleSpyGUI") then
	__NATurtleParent.TurtleSpyGUI:Destroy();
end;
local buttonOffset = -25;
local scrollSizeOffset = 287;
local functionImage = "http://www.roblox.com/asset/?id=413369623";
local eventImage = "http://www.roblox.com/asset/?id=413369506";
local remotes = {}
tstate.remotes = remotes

local remoteArgs = {}
tstate.remoteArgs = remoteArgs

local remoteButtons = {}
tstate.remoteButtons = remoteButtons

local remoteScripts = {}
tstate.remoteScripts = remoteScripts

local remoteLogs = {}
tstate.remoteLogs = remoteLogs

local IgnoreList = {}
tstate.IgnoreList = IgnoreList

local BlockList = {}
tstate.BlockList = BlockList

local connections = {}
tstate.connections = connections

local unstacked = {}
tstate.unstacked = unstacked

local clientEventConns = {}
tstate.clientEventConns = clientEventConns

local wrappedClientInvoke = {}
local wrappedInvokeCallbacks = {}
local _origClientInvoke = {}
tstate.wrappedClientInvoke = wrappedClientInvoke

local logClientEvents = false
tstate.logClientEvents = logClientEvents

local descAddedConn = nil
tstate.descAddedConn = descAddedConn
local descAddedInvokeConn = nil
tstate.descAddedInvokeConn = descAddedInvokeConn
tstate.adonisBypassed = tstate.adonisBypassed or false
local restoreFunction = restorefunction
local hookFunction = hookfunction
local hookMetaMethod = hookmetamethod or buildHookMetaMethodFallback()
local directHookState = {
	fireServer = false,
	unreliableFireServer = false,
	invokeServer = false
}
tstate.directHookState = directHookState

local _tmpRemoteEvent = Instance.new("RemoteEvent")
local _tmpRemoteFunction = Instance.new("RemoteFunction")
local _tmpUnreliableRemoteEvent
pcall(function()
	_tmpUnreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")
end)
local baseFireServer = _tmpRemoteEvent.FireServer
local baseInvokeServer = _tmpRemoteFunction.InvokeServer
local baseUnreliableFireServer = _tmpUnreliableRemoteEvent and _tmpUnreliableRemoteEvent.FireServer or nil
if baseUnreliableFireServer == baseFireServer then
	baseUnreliableFireServer = nil
end
_tmpRemoteEvent:Destroy()
_tmpRemoteFunction:Destroy()
if _tmpUnreliableRemoteEvent then
	_tmpUnreliableRemoteEvent:Destroy()
end

local function resolveAdonisEnv()
	local gc = getgc or (debug and debug.getgc)
	local hookf = hookfunction
	local env = getrenv
	local dbgInfo = (env and env().debug and env().debug.info) or (debug and debug.info)
	local newcc = newcclosure or function(fn)
		return fn
	end
	local typeOf = typeof or function(value)
		return type(value)
	end
	return gc, hookf, env, dbgInfo, newcc, typeOf
end

local function detectAdonis()
	local gc, hookf, env, dbgInfo, _, typeOf = resolveAdonisEnv()
	if not (gc and hookf and env and dbgInfo) then
		return false
	end

	for _, value in gc(true) do
		if typeOf(value) == "table" then
			local hasDetected = typeOf(rawget(value, "Detected")) == "function"
			local hasKill = typeOf(rawget(value, "Kill")) == "function"
			local hasVars = rawget(value, "Variables") ~= nil
			local hasProcess = rawget(value, "Process") ~= nil

			if hasDetected or (hasKill and hasVars and hasProcess) then
				return true
			end
		end
	end

	return false
end

local function bypassAdonis()
	local gc, hookf, env, dbgInfo, newcc, typeOf = resolveAdonisEnv()
	if not (gc and hookf and env and dbgInfo) then
		return false
	end

	local DetectedMeth, KillMeth

	for _, value in gc(true) do
		if typeOf(value) == "table" then
			local detected = rawget(value, "Detected")
			local kill = rawget(value, "Kill")

			if typeOf(detected) == "function" and not DetectedMeth then
				DetectedMeth = detected
				local old
				old = hookf(DetectedMeth, function(methodName, methodFunc)
					if methodName ~= "_" then end
					return true
				end)
			end

			if rawget(value, "Variables") and rawget(value, "Process") and typeOf(kill) == "function" and not KillMeth then
				KillMeth = kill
				local old
				old = hookf(KillMeth, function(killFunc) end)
			end

			if DetectedMeth and KillMeth then
				break
			end
		end
	end

	if DetectedMeth and dbgInfo then
		local old
		old = hookf(dbgInfo, newcc(function(...)
			local functionName = ...
			if functionName == DetectedMeth then
				return coroutine.yield(coroutine.running())
			end
			return old(...)
		end))
	end

	return DetectedMeth ~= nil
end

local function runAdonisBypass()
	if tstate.adonisBypassed then
		return
	end

	if detectAdonis() and bypassAdonis() then
		tstate.adonisBypassed = true
	end
end
local TurtleSpyGUI = Instance.new("ScreenGui");
local mainFrame = Instance.new("Frame");
local Header = Instance.new("Frame");
local HeaderShading = Instance.new("Frame");
local HeaderTextLabel = Instance.new("TextLabel");
local RemoteScrollFrame = Instance.new("ScrollingFrame");
local RemoteButton = Instance.new("TextButton");
local Number = Instance.new("TextLabel");
local RemoteName = Instance.new("TextLabel");
local RemoteIcon = Instance.new("ImageLabel");
local ExpandButton = Instance.new("TextButton");
local InfoFrame = Instance.new("Frame");
local InfoFrameHeader = Instance.new("Frame");
local InfoTitleShading = Instance.new("Frame");
local CodeFrame = Instance.new("ScrollingFrame");
local Code = Instance.new("TextBox");
local InfoHeaderText = Instance.new("TextLabel");
local InfoButtonsScroll = Instance.new("ScrollingFrame");
local CopyCode = Instance.new("TextButton");
local RunCode = Instance.new("TextButton");
local CopyScriptPath = Instance.new("TextButton");
local CopyDecompiled = Instance.new("TextButton");
local IgnoreRemote = Instance.new("TextButton");
local BlockRemote = Instance.new("TextButton");
local WhileLoop = Instance.new("TextButton");
local CopyReturn = Instance.new("TextButton");
tstate.SpamRemote = Instance.new("TextButton");
tstate.SpamDelayBox = Instance.new("TextBox");
tstate.SpamMode = Instance.new("TextButton");
local Clear = Instance.new("TextButton");
local FrameDivider = Instance.new("Frame");
local CloseInfoFrame = Instance.new("TextButton");
local OpenInfoFrame = Instance.new("TextButton");
local Minimize = Instance.new("TextButton");
local DoNotStack = Instance.new("TextButton");
local ImageButton = Instance.new("ImageButton");
local BrowserHeader = Instance.new("Frame");
local BrowserHeaderFrame = Instance.new("Frame");
local BrowserHeaderText = Instance.new("TextLabel");
local CloseInfoFrame2 = Instance.new("TextButton");
local RemoteBrowserFrame = Instance.new("ScrollingFrame");
local RemoteButton2 = Instance.new("TextButton");
local RemoteName2 = Instance.new("TextLabel");
local RemoteIcon2 = Instance.new("ImageLabel");
local BrowserSearch = Instance.new("TextBox");
local BrowseExecFrame = Instance.new("Frame");
local BrowseExecHeader = Instance.new("Frame");
local BrowseExecTitle = Instance.new("TextLabel");
local BrowseExecClose = Instance.new("TextButton");
local BrowseExecArgsLabel = Instance.new("TextLabel");
local BrowseExecArgsBox = Instance.new("TextBox");
local BrowseExecTimesLabel = Instance.new("TextLabel");
local BrowseExecTimesBox = Instance.new("TextBox");
local BrowseExecRun = Instance.new("TextButton");
local BrowseExecLoop = Instance.new("TextButton");
local CallsScroll = Instance.new("ScrollingFrame");
local CallButton = Instance.new("TextButton");
local ClientEventToggle = Instance.new("TextButton");
local PathModeBtn = Instance.new("TextButton");
TurtleSpyGUI.Name = "TurtleSpyGUI";
TurtleSpyGUI.Parent = __NATurtleParent or ClonedService("CoreGui");
TurtleSpyGUI.ResetOnSpawn = false;
TurtleSpyGUI.IgnoreGuiInset = true;
TurtleSpyGUI.DisplayOrder = 999999;
TurtleSpyGUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
mainFrame.Name = "mainFrame";
mainFrame.Parent = TurtleSpyGUI;
mainFrame.BackgroundColor3 = Color3.fromRGB(53, 59, 72);
mainFrame.BorderColor3 = Color3.fromRGB(53, 59, 72);
mainFrame.Position = UDim2.new(0.1, 0, 0.24, 0);
mainFrame.Size = UDim2.new(0, 207, 0, 35);
mainFrame.ZIndex = 8;
mainFrame.Active = true;
mainFrame.Draggable = true;
BrowserHeader.Name = "BrowserHeader";
BrowserHeader.Parent = TurtleSpyGUI;
BrowserHeader.BackgroundColor3 = colorSettings.Main.HeaderShadingColor;
BrowserHeader.BorderColor3 = colorSettings.Main.HeaderShadingColor;
BrowserHeader.Position = UDim2.new(0.7, 0, 0.34, 0);
BrowserHeader.Size = UDim2.new(0, 230, 0, 320);
BrowserHeader.ZIndex = 20;
BrowserHeader.Active = true;
BrowserHeader.Draggable = true;
BrowserHeader.Visible = false;
BrowserHeaderFrame.Name = "BrowserHeaderFrame";
BrowserHeaderFrame.Parent = BrowserHeader;
BrowserHeaderFrame.BackgroundColor3 = colorSettings.Main.HeaderColor;
BrowserHeaderFrame.BorderColor3 = colorSettings.Main.HeaderColor;
BrowserHeaderFrame.Position = UDim2.new(0, 0, 0, 0);
BrowserHeaderFrame.Size = UDim2.new(0, 230, 0, 26);
BrowserHeaderFrame.ZIndex = 21;
BrowserHeaderText.Name = "InfoHeaderText";
BrowserHeaderText.Parent = BrowserHeaderFrame;
BrowserHeaderText.BackgroundTransparency = 1;
BrowserHeaderText.Position = UDim2.new(0, 0, -0.002, 0);
BrowserHeaderText.Size = UDim2.new(0, 206, 0, 26);
BrowserHeaderText.ZIndex = 22;
BrowserHeaderText.Font = Enum.Font.SourceSans;
BrowserHeaderText.Text = "Remote Browser";
BrowserHeaderText.TextColor3 = colorSettings.Main.HeaderTextColor;
BrowserHeaderText.TextSize = 17;
CloseInfoFrame2.Name = "CloseInfoFrame";
CloseInfoFrame2.Parent = BrowserHeaderFrame;
CloseInfoFrame2.BackgroundColor3 = colorSettings.Main.HeaderColor;
CloseInfoFrame2.BorderColor3 = colorSettings.Main.HeaderColor;
CloseInfoFrame2.Position = UDim2.new(0, 208, 0, 2);
CloseInfoFrame2.Size = UDim2.new(0, 20, 0, 20);
CloseInfoFrame2.ZIndex = 38;
CloseInfoFrame2.Font = Enum.Font.SourceSansLight;
CloseInfoFrame2.Text = "X";
CloseInfoFrame2.TextColor3 = Color3.fromRGB(0, 0, 0);
CloseInfoFrame2.TextSize = 20;
BrowserSearch.Name = "BrowserSearch";
BrowserSearch.Parent = BrowserHeader;
BrowserSearch.BackgroundColor3 = Color3.fromRGB(47, 54, 64);
BrowserSearch.BorderColor3 = Color3.fromRGB(53, 59, 72);
BrowserSearch.Position = UDim2.new(0, 8, 0, 30);
BrowserSearch.Size = UDim2.new(0, 214, 0, 22);
BrowserSearch.ZIndex = 21;
BrowserSearch.Font = Enum.Font.SourceSans;
BrowserSearch.PlaceholderText = "Search remotes...";
BrowserSearch.Text = "";
BrowserSearch.TextColor3 = colorSettings.RemoteButtons.TextColor;
BrowserSearch.TextSize = 16;
BrowserSearch.ClearTextOnFocus = false;
RemoteBrowserFrame.Name = "RemoteBrowserFrame";
RemoteBrowserFrame.Parent = BrowserHeader;
RemoteBrowserFrame.Active = true;
RemoteBrowserFrame.BackgroundColor3 = Color3.fromRGB(47, 54, 64);
RemoteBrowserFrame.BorderColor3 = Color3.fromRGB(47, 54, 64);
RemoteBrowserFrame.Position = UDim2.new(0, 0, 0, 58);
RemoteBrowserFrame.Size = UDim2.new(0, 230, 0, 252);
RemoteBrowserFrame.ZIndex = 19;
RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, 252);
RemoteBrowserFrame.ScrollBarThickness = 8;
RemoteBrowserFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left;
RemoteBrowserFrame.ScrollBarImageColor3 = colorSettings.Main.ScrollBarImageColor;
RemoteButton2.Name = "RemoteButton";
RemoteButton2.Parent = RemoteBrowserFrame;
RemoteButton2.BackgroundColor3 = colorSettings.RemoteButtons.BackgroundColor;
RemoteButton2.BorderColor3 = colorSettings.RemoteButtons.BorderColor;
RemoteButton2.Position = UDim2.new(0, 17, 0, 10);
RemoteButton2.Size = UDim2.new(0, 196, 0, 26);
RemoteButton2.ZIndex = 20;
RemoteButton2.Selected = true;
RemoteButton2.Font = Enum.Font.SourceSans;
RemoteButton2.Text = "";
RemoteButton2.TextSize = 18;
RemoteButton2.TextStrokeTransparency = 123;
RemoteButton2.TextWrapped = true;
RemoteButton2.TextXAlignment = Enum.TextXAlignment.Left;
RemoteButton2.Visible = false;
RemoteName2.Name = "RemoteName2";
RemoteName2.Parent = RemoteButton2;
RemoteName2.BackgroundTransparency = 1;
RemoteName2.Position = UDim2.new(0, 5, 0, 0);
RemoteName2.Size = UDim2.new(0, 160, 0, 26);
RemoteName2.ZIndex = 21;
RemoteName2.Font = Enum.Font.SourceSans;
RemoteName2.Text = "RemoteEvent";
RemoteName2.TextColor3 = colorSettings.RemoteButtons.TextColor;
RemoteName2.TextSize = 16;
RemoteName2.TextXAlignment = Enum.TextXAlignment.Left;
RemoteName2.TextTruncate = 1;
RemoteIcon2.Name = "RemoteIcon2";
RemoteIcon2.Parent = RemoteButton2;
RemoteIcon2.BackgroundTransparency = 1;
RemoteIcon2.Position = UDim2.new(0.84, 0, 0.022, 0);
RemoteIcon2.Size = UDim2.new(0, 24, 0, 24);
RemoteIcon2.ZIndex = 21;
RemoteIcon2.Image = functionImage;
BrowseExecFrame.Name = "BrowseExecFrame";
BrowseExecFrame.Parent = TurtleSpyGUI;
BrowseExecFrame.BackgroundColor3 = colorSettings.Main.MainBackgroundColor;
BrowseExecFrame.BorderColor3 = colorSettings.Main.MainBackgroundColor;
BrowseExecFrame.Position = UDim2.new(0.7, 0, 0.34, 0);
BrowseExecFrame.Size = UDim2.new(0, 230, 0, 170);
BrowseExecFrame.ZIndex = 20;
BrowseExecFrame.Visible = false;
BrowseExecFrame.Active = true;
BrowseExecFrame.Draggable = true;
BrowseExecHeader.Name = "BrowseExecHeader";
BrowseExecHeader.Parent = BrowseExecFrame;
BrowseExecHeader.BackgroundColor3 = colorSettings.Main.HeaderColor;
BrowseExecHeader.BorderColor3 = colorSettings.Main.HeaderColor;
BrowseExecHeader.Size = UDim2.new(0, 230, 0, 24);
BrowseExecHeader.ZIndex = 21;
BrowseExecTitle.Name = "BrowseExecTitle";
BrowseExecTitle.Parent = BrowseExecHeader;
BrowseExecTitle.BackgroundTransparency = 1;
BrowseExecTitle.Position = UDim2.new(0, 5, 0, 0);
BrowseExecTitle.Size = UDim2.new(0, 200, 0, 24);
BrowseExecTitle.ZIndex = 22;
BrowseExecTitle.Font = Enum.Font.SourceSans;
BrowseExecTitle.Text = "Execute remote";
BrowseExecTitle.TextColor3 = colorSettings.Main.HeaderTextColor;
BrowseExecTitle.TextSize = 16;
BrowseExecTitle.TextXAlignment = Enum.TextXAlignment.Left;
BrowseExecClose.Name = "BrowseExecClose";
BrowseExecClose.Parent = BrowseExecHeader;
BrowseExecClose.BackgroundColor3 = colorSettings.Main.HeaderColor;
BrowseExecClose.BorderColor3 = colorSettings.Main.HeaderColor;
BrowseExecClose.Position = UDim2.new(0, 208, 0, 1);
BrowseExecClose.Size = UDim2.new(0, 20, 0, 20);
BrowseExecClose.ZIndex = 22;
BrowseExecClose.Font = Enum.Font.SourceSans;
BrowseExecClose.Text = "X";
BrowseExecClose.TextColor3 = Color3.fromRGB(0, 0, 0);
BrowseExecClose.TextSize = 16;
BrowseExecArgsLabel.Name = "BrowseExecArgsLabel";
BrowseExecArgsLabel.Parent = BrowseExecFrame;
BrowseExecArgsLabel.BackgroundTransparency = 1;
BrowseExecArgsLabel.Position = UDim2.new(0, 8, 0, 30);
BrowseExecArgsLabel.Size = UDim2.new(0, 214, 0, 18);
BrowseExecArgsLabel.ZIndex = 21;
BrowseExecArgsLabel.Font = Enum.Font.SourceSans;
BrowseExecArgsLabel.Text = "Args (Lua expression)";
BrowseExecArgsLabel.TextColor3 = colorSettings.RemoteButtons.TextColor;
BrowseExecArgsLabel.TextSize = 14;
BrowseExecArgsLabel.TextXAlignment = Enum.TextXAlignment.Left;
BrowseExecArgsBox.Name = "BrowseExecArgsBox";
BrowseExecArgsBox.Parent = BrowseExecFrame;
BrowseExecArgsBox.BackgroundColor3 = Color3.fromRGB(47, 54, 64);
BrowseExecArgsBox.BorderColor3 = Color3.fromRGB(53, 59, 72);
BrowseExecArgsBox.Position = UDim2.new(0, 8, 0, 48);
BrowseExecArgsBox.Size = UDim2.new(0, 214, 0, 22);
BrowseExecArgsBox.ZIndex = 21;
BrowseExecArgsBox.Font = Enum.Font.SourceSans;
BrowseExecArgsBox.Text = "";
BrowseExecArgsBox.TextColor3 = colorSettings.RemoteButtons.TextColor;
BrowseExecArgsBox.TextSize = 14;
BrowseExecArgsBox.ClearTextOnFocus = false;
BrowseExecTimesLabel.Name = "BrowseExecTimesLabel";
BrowseExecTimesLabel.Parent = BrowseExecFrame;
BrowseExecTimesLabel.BackgroundTransparency = 1;
BrowseExecTimesLabel.Position = UDim2.new(0, 8, 0, 76);
BrowseExecTimesLabel.Size = UDim2.new(0, 100, 0, 18);
BrowseExecTimesLabel.ZIndex = 21;
BrowseExecTimesLabel.Font = Enum.Font.SourceSans;
BrowseExecTimesLabel.Text = "Times";
BrowseExecTimesLabel.TextColor3 = colorSettings.RemoteButtons.TextColor;
BrowseExecTimesLabel.TextSize = 14;
BrowseExecTimesLabel.TextXAlignment = Enum.TextXAlignment.Left;
BrowseExecTimesBox.Name = "BrowseExecTimesBox";
BrowseExecTimesBox.Parent = BrowseExecFrame;
BrowseExecTimesBox.BackgroundColor3 = Color3.fromRGB(47, 54, 64);
BrowseExecTimesBox.BorderColor3 = Color3.fromRGB(53, 59, 72);
BrowseExecTimesBox.Position = UDim2.new(0, 8, 0, 94);
BrowseExecTimesBox.Size = UDim2.new(0, 80, 0, 22);
BrowseExecTimesBox.ZIndex = 21;
BrowseExecTimesBox.Font = Enum.Font.SourceSans;
BrowseExecTimesBox.Text = "1";
BrowseExecTimesBox.TextColor3 = colorSettings.RemoteButtons.TextColor;
BrowseExecTimesBox.TextSize = 14;
BrowseExecTimesBox.ClearTextOnFocus = false;
BrowseExecRun.Name = "BrowseExecRun";
BrowseExecRun.Parent = BrowseExecFrame;
BrowseExecRun.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
BrowseExecRun.BorderColor3 = colorSettings.MainButtons.BorderColor;
BrowseExecRun.Position = UDim2.new(0, 8, 0, 126);
BrowseExecRun.Size = UDim2.new(0, 100, 0, 26);
BrowseExecRun.ZIndex = 21;
BrowseExecRun.Font = Enum.Font.SourceSans;
BrowseExecRun.Text = "Run";
BrowseExecRun.TextColor3 = Color3.fromRGB(250, 251, 255);
BrowseExecRun.TextSize = 16;
BrowseExecLoop.Name = "BrowseExecLoop";
BrowseExecLoop.Parent = BrowseExecFrame;
BrowseExecLoop.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
BrowseExecLoop.BorderColor3 = colorSettings.MainButtons.BorderColor;
BrowseExecLoop.Position = UDim2.new(0, 122, 0, 126);
BrowseExecLoop.Size = UDim2.new(0, 100, 0, 26);
BrowseExecLoop.ZIndex = 21;
BrowseExecLoop.Font = Enum.Font.SourceSans;
BrowseExecLoop.Text = "Loop: OFF";
BrowseExecLoop.TextColor3 = Color3.fromRGB(250, 251, 255);
BrowseExecLoop.TextSize = 16;
local browsedButtonOffset = 10;
local browseRemotes = {};
local browseSelRemote;
local browseLoop = false;
local browseLoopToken = 0;
local function parseArgsText(txt)
	txt = txt or "";
	txt = txt:match("^%s*(.-)%s*$");
	if txt == "" then
		return table.pack();
	end;
	if typeof(loadstring) == "function" then
		local src = "return " .. txt;
		local ok, fn = pcall(loadstring, src);
		if ok and type(fn) == "function" then
			local ok2, r1, r2, r3, r4, r5 = pcall(fn);
			if ok2 then
				return table.pack(r1, r2, r3, r4, r5);
			end;
		end;
	end;
	return table.pack(txt);
end;
local function fireRemoteNow(r, argsPack)
	if not r then
		return
	end
	if table.find(BlockList, r) then
		return
	end

	local a = argsPack or table.pack()
	local n = a.n or #a

	if r:IsA("RemoteEvent") or r:IsA("UnreliableRemoteEvent") then
		r:FireServer(table.unpack(a, 1, n))
	elseif r:IsA("RemoteFunction") then
		r:InvokeServer(table.unpack(a, 1, n))
	end
end
local function openBrowseRunner(r)
	browseSelRemote = r;
	if not r then
		return;
	end;
	BrowseExecFrame.Visible = true;
	BrowseExecTitle.Text = "Execute: " .. (r.Name or "Remote");
end;
local function refreshBrowserList(filter)
	for _, child in RemoteBrowserFrame:GetChildren() do
		if child:IsA("TextButton") and child ~= RemoteButton2 then
			child:Destroy()
		end
	end

	browsedButtonOffset = 10
	filter = filter and filter:lower() or ""

	for _, r in browseRemotes do
		local name = r.Name or ""
		if filter == "" or name:lower():find(filter, 1, true) then
			local btn = RemoteButton2:Clone()
			btn.Parent = RemoteBrowserFrame
			btn.Visible = true
			btn.Position = UDim2.new(0, 17, 0, browsedButtonOffset)

			if r:IsA("RemoteEvent") or r:IsA("UnreliableRemoteEvent") then
				btn.RemoteIcon2.Image = eventImage
			else
				btn.RemoteIcon2.Image = functionImage
			end

			btn.RemoteName2.Text = name

			btn.MouseButton1Click:Connect(function()
				openBrowseRunner(r)
			end)

			browsedButtonOffset = browsedButtonOffset + 35
		end
	end

	if browsedButtonOffset > 252 then
		RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, browsedButtonOffset)
	else
		RemoteBrowserFrame.CanvasSize = UDim2.new(0, 0, 0, 252)
	end
end
BrowserSearch:GetPropertyChangedSignal("Text"):Connect(function()
	if BrowserHeader.Visible then
		refreshBrowserList(BrowserSearch.Text);
	end;
end);
BrowseExecClose.MouseButton1Click:Connect(function()
	browseLoopToken = browseLoopToken + 1
	browseLoop = false
	BrowseExecFrame.Visible = false
end)
BrowseExecLoop.MouseButton1Click:Connect(function()
	local r = browseSelRemote
	if not r then
		return
	end

	if not browseLoop then
		browseLoop = true
		browseLoopToken = browseLoopToken + 1
		local token = browseLoopToken

		BrowseExecLoop.Text = "Loop: ON"
		BrowseExecLoop.TextColor3 = Color3.fromRGB(76, 209, 55)

		local argsPack = parseArgsText(BrowseExecArgsBox.Text)
		local times = tonumber(BrowseExecTimesBox.Text) or 1
		if times < 1 then
			times = 1
		end

		task.spawn(function()
			while browseLoop and token == browseLoopToken and tstate.enabled do
				for i = 1, times do
					fireRemoteNow(r, argsPack)
				end
				task.wait()
			end
		end)
	else
		browseLoop = false
		browseLoopToken = browseLoopToken + 1
		BrowseExecLoop.Text = "Loop: OFF"
		BrowseExecLoop.TextColor3 = Color3.fromRGB(250, 251, 255)
	end
end)

BrowseExecRun.MouseButton1Click:Connect(function()
	local r = browseSelRemote
	if not r then
		return
	end

	local argsPack = parseArgsText(BrowseExecArgsBox.Text)
	local times = tonumber(BrowseExecTimesBox.Text) or 1
	if times < 1 then
		times = 1
	end

	for i = 1, times do
		fireRemoteNow(r, argsPack)
	end
end)
Header.Name = "Header";
Header.Parent = mainFrame;
Header.BackgroundColor3 = colorSettings.Main.HeaderColor;
Header.BorderColor3 = colorSettings.Main.HeaderColor;
Header.Size = UDim2.new(0, 207, 0, 26);
Header.ZIndex = 9;
HeaderShading.Name = "HeaderShading";
HeaderShading.Parent = Header;
HeaderShading.BackgroundColor3 = colorSettings.Main.HeaderShadingColor;
HeaderShading.BorderColor3 = colorSettings.Main.HeaderShadingColor;
HeaderShading.Position = UDim2.new(0, 0, 0.286, 0);
HeaderShading.Size = UDim2.new(0, 207, 0, 27);
HeaderShading.ZIndex = 8;
HeaderTextLabel.Name = "HeaderTextLabel";
HeaderTextLabel.Parent = HeaderShading;
HeaderTextLabel.BackgroundTransparency = 1;
HeaderTextLabel.Position = UDim2.new(-0.005, 0, -0.203, 0);
HeaderTextLabel.Size = UDim2.new(0, 215, 0, 29);
HeaderTextLabel.ZIndex = 10;
HeaderTextLabel.Font = Enum.Font.SourceSans;
HeaderTextLabel.Text = "Turtle Spy";
HeaderTextLabel.TextColor3 = colorSettings.Main.HeaderTextColor;
HeaderTextLabel.TextSize = 17;
ImageButton.Parent = Header;
ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255);
ImageButton.BackgroundTransparency = 1;
ImageButton.Position = UDim2.new(0, 8, 0, 8);
ImageButton.Size = UDim2.new(0, 18, 0, 18);
ImageButton.ZIndex = 9;
ImageButton.Image = "rbxassetid://169476802";
ImageButton.ImageColor3 = Color3.fromRGB(53, 53, 53);
RemoteScrollFrame.Name = "RemoteScrollFrame";
RemoteScrollFrame.Parent = mainFrame;
RemoteScrollFrame.Active = true;
RemoteScrollFrame.BackgroundColor3 = Color3.fromRGB(47, 54, 64);
RemoteScrollFrame.BorderColor3 = Color3.fromRGB(47, 54, 64);
RemoteScrollFrame.Position = UDim2.new(0, 0, 1.0229, 0);
RemoteScrollFrame.Size = UDim2.new(0, 207, 0, 286);
RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 287);
RemoteScrollFrame.ScrollBarThickness = 8;
RemoteScrollFrame.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left;
RemoteScrollFrame.ScrollBarImageColor3 = colorSettings.Main.ScrollBarImageColor;
RemoteButton.Name = "RemoteButton";
RemoteButton.Parent = RemoteScrollFrame;
RemoteButton.BackgroundColor3 = colorSettings.RemoteButtons.BackgroundColor;
RemoteButton.BorderColor3 = colorSettings.RemoteButtons.BorderColor;
RemoteButton.Position = UDim2.new(0, 17, 0, 10);
RemoteButton.Size = UDim2.new(0, 182, 0, 26);
RemoteButton.Selected = true;
RemoteButton.Font = Enum.Font.SourceSans;
RemoteButton.Text = "";
RemoteButton.TextColor3 = Color3.fromRGB(220, 221, 225);
RemoteButton.TextSize = 18;
RemoteButton.TextStrokeTransparency = 123;
RemoteButton.TextWrapped = true;
RemoteButton.TextXAlignment = Enum.TextXAlignment.Left;
RemoteButton.Visible = false;
Number.Name = "Number";
Number.Parent = RemoteButton;
Number.BackgroundTransparency = 1;
Number.Position = UDim2.new(0, 5, 0, 0);
Number.Size = UDim2.new(0, 300, 0, 26);
Number.ZIndex = 2;
Number.Font = Enum.Font.SourceSans;
Number.Text = "1";
Number.TextColor3 = colorSettings.RemoteButtons.NumberTextColor;
Number.TextSize = 16;
Number.TextWrapped = true;
Number.TextXAlignment = Enum.TextXAlignment.Left;
RemoteName.Name = "RemoteName";
RemoteName.Parent = RemoteButton;
RemoteName.BackgroundTransparency = 1;
RemoteName.Position = UDim2.new(0, 20, 0, 0);
RemoteName.Size = UDim2.new(0, 120, 0, 26);
RemoteName.Font = Enum.Font.SourceSans;
RemoteName.Text = "RemoteEvent";
RemoteName.TextColor3 = colorSettings.RemoteButtons.TextColor;
RemoteName.TextSize = 16;
RemoteName.TextXAlignment = Enum.TextXAlignment.Left;
RemoteName.TextTruncate = 1;
RemoteIcon.Name = "RemoteIcon";
RemoteIcon.Parent = RemoteButton;
RemoteIcon.BackgroundTransparency = 1;
RemoteIcon.Position = UDim2.new(0.78, 0, 0.022, 0);
RemoteIcon.Size = UDim2.new(0, 24, 0, 24);
RemoteIcon.Image = eventImage;
ExpandButton.Name = "Expand";
ExpandButton.Parent = RemoteButton;
ExpandButton.BackgroundTransparency = 1;
ExpandButton.Position = UDim2.new(0.9, 0, 0, 0);
ExpandButton.Size = UDim2.new(0, 20, 0, 26);
ExpandButton.ZIndex = 3;
ExpandButton.Font = Enum.Font.SourceSansBold;
ExpandButton.Text = "+";
ExpandButton.TextColor3 = colorSettings.RemoteButtons.TextColor;
ExpandButton.TextSize = 18;
InfoFrame.Name = "InfoFrame";
InfoFrame.Parent = mainFrame;
InfoFrame.BackgroundColor3 = colorSettings.Main.MainBackgroundColor;
InfoFrame.BorderColor3 = colorSettings.Main.MainBackgroundColor;
InfoFrame.Position = UDim2.new(0, 207, 0, 0);
InfoFrame.Size = UDim2.new(0, 553, 0, 322);
InfoFrame.Visible = false;
InfoFrame.ZIndex = 6;
InfoFrameHeader.Name = "InfoFrameHeader";
InfoFrameHeader.Parent = InfoFrame;
InfoFrameHeader.BackgroundColor3 = colorSettings.Main.HeaderColor;
InfoFrameHeader.BorderColor3 = colorSettings.Main.HeaderColor;
InfoFrameHeader.Size = UDim2.new(0, 553, 0, 26);
InfoFrameHeader.ZIndex = 14;
InfoTitleShading.Name = "InfoTitleShading";
InfoTitleShading.Parent = InfoFrame;
InfoTitleShading.BackgroundColor3 = colorSettings.Main.HeaderShadingColor;
InfoTitleShading.BorderColor3 = colorSettings.Main.HeaderShadingColor;
InfoTitleShading.Position = UDim2.new(-0.0028, 0, 0, 0);
InfoTitleShading.Size = UDim2.new(0, 554, 0, 34);
InfoTitleShading.ZIndex = 13;
CodeFrame.Name = "CodeFrame";
CodeFrame.Parent = InfoFrame;
CodeFrame.Active = true;
CodeFrame.BackgroundColor3 = colorSettings.Code.BackgroundColor;
CodeFrame.BorderColor3 = colorSettings.Code.BackgroundColor;
CodeFrame.Position = UDim2.new(0, 14, 0, 43);
CodeFrame.Size = UDim2.new(0, 525, 0, 154);
CodeFrame.ZIndex = 16;
CodeFrame.CanvasSize = UDim2.new(0, 525, 0, 154);
CodeFrame.ScrollBarThickness = 6;
CodeFrame.ScrollingDirection = Enum.ScrollingDirection.XY;
CodeFrame.ScrollBarImageColor3 = colorSettings.Main.ScrollBarImageColor;
Code.Name = "Code";
Code.Parent = CodeFrame;
Code.BackgroundTransparency = 1;
Code.ClearTextOnFocus = false;
Code.MultiLine = true;
Code.Position = UDim2.new(0, 8, 0, 6);
Code.Size = UDim2.new(0, 509, 0, 138);
Code.ZIndex = 18;
Code.Font = Enum.Font.Code;
Code.Text = "Thanks for using Turtle Spy! :D";
Code.TextColor3 = colorSettings.Code.TextColor;
Code.TextSize = 14;
Code.TextWrapped = false;
Code.TextXAlignment = Enum.TextXAlignment.Left;
Code.TextYAlignment = Enum.TextYAlignment.Top;
InfoHeaderText.Name = "InfoHeaderText";
InfoHeaderText.Parent = InfoFrame;
InfoHeaderText.BackgroundTransparency = 1;
InfoHeaderText.Position = UDim2.new(0, 14, 0, -1);
InfoHeaderText.Size = UDim2.new(0, 520, 0, 35);
InfoHeaderText.ZIndex = 18;
InfoHeaderText.Font = Enum.Font.SourceSans;
InfoHeaderText.Text = "Info: RemoteFunction";
InfoHeaderText.TextColor3 = colorSettings.Main.HeaderTextColor;
InfoHeaderText.TextSize = 17;
InfoButtonsScroll.Name = "InfoButtonsScroll";
InfoButtonsScroll.Parent = InfoFrame;
InfoButtonsScroll.Active = true;
InfoButtonsScroll.BackgroundColor3 = colorSettings.Main.MainBackgroundColor;
InfoButtonsScroll.BorderColor3 = colorSettings.Main.MainBackgroundColor;
InfoButtonsScroll.Position = UDim2.new(0, 14, 0, 205);
InfoButtonsScroll.Size = UDim2.new(0, 525, 0, 105);
InfoButtonsScroll.ZIndex = 11;
InfoButtonsScroll.CanvasSize = UDim2.new(0, 0, 0, 190);
InfoButtonsScroll.ScrollBarThickness = 6;
InfoButtonsScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left;
InfoButtonsScroll.ScrollBarImageColor3 = colorSettings.Main.ScrollBarImageColor;
CopyCode.Name = "CopyCode";
CopyCode.Parent = InfoButtonsScroll;
CopyCode.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
CopyCode.BorderColor3 = colorSettings.MainButtons.BorderColor;
CopyCode.Position = UDim2.new(0, 10, 0, 6);
CopyCode.Size = UDim2.new(0, 248, 0, 22);
CopyCode.ZIndex = 15;
CopyCode.Font = Enum.Font.SourceSans;
CopyCode.Text = "Copy code";
CopyCode.TextColor3 = Color3.fromRGB(250, 251, 255);
CopyCode.TextSize = 14;
RunCode.Name = "RunCode";
RunCode.Parent = InfoButtonsScroll;
RunCode.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
RunCode.BorderColor3 = colorSettings.MainButtons.BorderColor;
RunCode.Position = UDim2.new(0, 267, 0, 6);
RunCode.Size = UDim2.new(0, 248, 0, 22);
RunCode.ZIndex = 15;
RunCode.Font = Enum.Font.SourceSans;
RunCode.Text = "Execute";
RunCode.TextColor3 = Color3.fromRGB(250, 251, 255);
RunCode.TextSize = 14;
CopyScriptPath.Name = "CopyScriptPath";
CopyScriptPath.Parent = InfoButtonsScroll;
CopyScriptPath.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
CopyScriptPath.BorderColor3 = colorSettings.MainButtons.BorderColor;
CopyScriptPath.Position = UDim2.new(0, 10, 0, 32);
CopyScriptPath.Size = UDim2.new(0, 248, 0, 22);
CopyScriptPath.ZIndex = 15;
CopyScriptPath.Font = Enum.Font.SourceSans;
CopyScriptPath.Text = "Copy script path";
CopyScriptPath.TextColor3 = Color3.fromRGB(250, 251, 255);
CopyScriptPath.TextSize = 14;
CopyDecompiled.Name = "CopyDecompiled";
CopyDecompiled.Parent = InfoButtonsScroll;
CopyDecompiled.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
CopyDecompiled.BorderColor3 = colorSettings.MainButtons.BorderColor;
CopyDecompiled.Position = UDim2.new(0, 267, 0, 32);
CopyDecompiled.Size = UDim2.new(0, 248, 0, 22);
CopyDecompiled.ZIndex = 15;
CopyDecompiled.Font = Enum.Font.SourceSans;
CopyDecompiled.Text = "Copy decompiled script";
CopyDecompiled.TextColor3 = Color3.fromRGB(250, 251, 255);
CopyDecompiled.TextSize = 14;
IgnoreRemote.Name = "IgnoreRemote";
IgnoreRemote.Parent = InfoButtonsScroll;
IgnoreRemote.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
IgnoreRemote.BorderColor3 = colorSettings.MainButtons.BorderColor;
IgnoreRemote.Position = UDim2.new(0, 267, 0, 58);
IgnoreRemote.Size = UDim2.new(0, 248, 0, 22);
IgnoreRemote.ZIndex = 15;
IgnoreRemote.Font = Enum.Font.SourceSans;
IgnoreRemote.Text = "Ignore remote";
IgnoreRemote.TextColor3 = Color3.fromRGB(250, 251, 255);
IgnoreRemote.TextSize = 14;
BlockRemote.Name = "Block Remote";
BlockRemote.Parent = InfoButtonsScroll;
BlockRemote.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
BlockRemote.BorderColor3 = colorSettings.MainButtons.BorderColor;
BlockRemote.Position = UDim2.new(0, 10, 0, 84);
BlockRemote.Size = UDim2.new(0, 248, 0, 22);
BlockRemote.ZIndex = 15;
BlockRemote.Font = Enum.Font.SourceSans;
BlockRemote.Text = "Block remote from firing";
BlockRemote.TextColor3 = Color3.fromRGB(250, 251, 255);
BlockRemote.TextSize = 14;
DoNotStack.Name = "DoNotStack";
DoNotStack.Parent = InfoButtonsScroll;
DoNotStack.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
DoNotStack.BorderColor3 = colorSettings.MainButtons.BorderColor;
DoNotStack.Position = UDim2.new(0, 10, 0, 58);
DoNotStack.Size = UDim2.new(0, 248, 0, 22);
DoNotStack.ZIndex = 15;
DoNotStack.Font = Enum.Font.SourceSans;
DoNotStack.Text = "Unstack new args";
DoNotStack.TextColor3 = Color3.fromRGB(250, 251, 255);
DoNotStack.TextSize = 14;
Clear.Name = "Clear";
Clear.Parent = InfoButtonsScroll;
Clear.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
Clear.BorderColor3 = colorSettings.MainButtons.BorderColor;
Clear.Position = UDim2.new(0, 267, 0, 84);
Clear.Size = UDim2.new(0, 248, 0, 22);
Clear.ZIndex = 15;
Clear.Font = Enum.Font.SourceSans;
Clear.Text = "Clear logs";
Clear.TextColor3 = Color3.fromRGB(250, 251, 255);
Clear.TextSize = 14;
CopyReturn.Name = "CopyReturn";
CopyReturn.Parent = InfoButtonsScroll;
CopyReturn.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
CopyReturn.BorderColor3 = colorSettings.MainButtons.BorderColor;
CopyReturn.Position = UDim2.new(0, 10, 0, 136);
CopyReturn.Size = UDim2.new(0, 248, 0, 22);
CopyReturn.ZIndex = 15;
CopyReturn.Font = Enum.Font.SourceSans;
CopyReturn.Text = "Execute and copy return value";
CopyReturn.TextColor3 = Color3.fromRGB(250, 251, 255);
CopyReturn.TextSize = 14;
CopyReturn.Visible = false
tstate.SpamRemote.Name = "SpamRemote";
tstate.SpamRemote.Parent = InfoButtonsScroll;
tstate.SpamRemote.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
tstate.SpamRemote.BorderColor3 = colorSettings.MainButtons.BorderColor;
tstate.SpamRemote.Position = UDim2.new(0, 10, 0, 136);
tstate.SpamRemote.Size = UDim2.new(0, 248, 0, 22);
tstate.SpamRemote.ZIndex = 15;
tstate.SpamRemote.Font = Enum.Font.SourceSans;
tstate.SpamRemote.Text = "Spam Remote: OFF";
tstate.SpamRemote.TextColor3 = Color3.fromRGB(250, 251, 255);
tstate.SpamRemote.TextSize = 14;
tstate.SpamDelayBox.Name = "SpamDelayBox";
tstate.SpamDelayBox.Parent = InfoButtonsScroll;
tstate.SpamDelayBox.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
tstate.SpamDelayBox.BorderColor3 = colorSettings.MainButtons.BorderColor;
tstate.SpamDelayBox.Position = UDim2.new(0, 267, 0, 136);
tstate.SpamDelayBox.Size = UDim2.new(0, 248, 0, 22);
tstate.SpamDelayBox.ZIndex = 15;
tstate.SpamDelayBox.Font = Enum.Font.SourceSans;
tstate.SpamDelayBox.PlaceholderText = "Spam delay seconds";
tstate.SpamDelayBox.Text = "0";
tstate.SpamDelayBox.TextColor3 = Color3.fromRGB(250, 251, 255);
tstate.SpamDelayBox.TextSize = 14;
tstate.SpamDelayBox.ClearTextOnFocus = false;
tstate.SpamMode.Name = "SpamMode";
tstate.SpamMode.Parent = InfoButtonsScroll;
tstate.SpamMode.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
tstate.SpamMode.BorderColor3 = colorSettings.MainButtons.BorderColor;
tstate.SpamMode.Position = UDim2.new(0, 10, 0, 162);
tstate.SpamMode.Size = UDim2.new(0, 505, 0, 22);
tstate.SpamMode.ZIndex = 15;
tstate.SpamMode.Font = Enum.Font.SourceSans;
tstate.SpamMode.Text = "Spam Mode: PreSimulation";
tstate.SpamMode.TextColor3 = Color3.fromRGB(250, 251, 255);
tstate.SpamMode.TextSize = 14;
ClientEventToggle.Name = "ClientEventToggle";
ClientEventToggle.Parent = InfoButtonsScroll;
ClientEventToggle.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
ClientEventToggle.BorderColor3 = colorSettings.MainButtons.BorderColor;
ClientEventToggle.Position = UDim2.new(0, 10, 0, 110);
ClientEventToggle.Size = UDim2.new(0, 248, 0, 22);
ClientEventToggle.ZIndex = 15;
ClientEventToggle.Font = Enum.Font.SourceSans;
ClientEventToggle.Text = "Log OnClientEvent: OFF";
ClientEventToggle.TextColor3 = Color3.fromRGB(250, 251, 255);
ClientEventToggle.TextSize = 14;
PathModeBtn.Name = "PathModeBtn";
PathModeBtn.Parent = InfoButtonsScroll;
PathModeBtn.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
PathModeBtn.BorderColor3 = colorSettings.MainButtons.BorderColor;
PathModeBtn.Position = UDim2.new(0, 267, 0, 110);
PathModeBtn.Size = UDim2.new(0, 248, 0, 22);
PathModeBtn.ZIndex = 15;
PathModeBtn.Font = Enum.Font.SourceSans;
PathModeBtn.Text = "Path: .";
PathModeBtn.TextColor3 = Color3.fromRGB(250, 251, 255);
PathModeBtn.TextSize = 14;
FrameDivider.Name = "FrameDivider";
FrameDivider.Parent = InfoFrame;
FrameDivider.BackgroundColor3 = Color3.fromRGB(53, 59, 72);
FrameDivider.BorderColor3 = Color3.fromRGB(53, 59, 72);
FrameDivider.Position = UDim2.new(0, 3, 0, 0);
FrameDivider.Size = UDim2.new(0, 4, 0, 322);
FrameDivider.ZIndex = 7;
local InfoFrameOpen = false;
CloseInfoFrame.Name = "CloseInfoFrame";
CloseInfoFrame.Parent = InfoFrame;
CloseInfoFrame.BackgroundColor3 = colorSettings.Main.HeaderColor;
CloseInfoFrame.BorderColor3 = colorSettings.Main.HeaderColor;
CloseInfoFrame.Position = UDim2.new(0, 529, 0, 2);
CloseInfoFrame.Size = UDim2.new(0, 22, 0, 22);
CloseInfoFrame.ZIndex = 18;
CloseInfoFrame.Font = Enum.Font.SourceSansLight;
CloseInfoFrame.Text = "X";
CloseInfoFrame.TextColor3 = Color3.fromRGB(0, 0, 0);
CloseInfoFrame.TextSize = 20;
OpenInfoFrame.Name = "OpenInfoFrame";
OpenInfoFrame.Parent = mainFrame;
OpenInfoFrame.BackgroundColor3 = colorSettings.Main.HeaderColor;
OpenInfoFrame.BorderColor3 = colorSettings.Main.HeaderColor;
OpenInfoFrame.Position = UDim2.new(0, 185, 0, 2);
OpenInfoFrame.Size = UDim2.new(0, 22, 0, 22);
OpenInfoFrame.ZIndex = 18;
OpenInfoFrame.Font = Enum.Font.SourceSans;
OpenInfoFrame.Text = ">";
OpenInfoFrame.TextColor3 = Color3.fromRGB(0, 0, 0);
OpenInfoFrame.TextSize = 16;
Minimize.Name = "Minimize";
Minimize.Parent = mainFrame;
Minimize.BackgroundColor3 = colorSettings.Main.HeaderColor;
Minimize.BorderColor3 = colorSettings.Main.HeaderColor;
Minimize.Position = UDim2.new(0, 164, 0, 2);
Minimize.Size = UDim2.new(0, 22, 0, 22);
Minimize.ZIndex = 18;
Minimize.Font = Enum.Font.SourceSans;
Minimize.Text = "_";
Minimize.TextColor3 = Color3.fromRGB(0, 0, 0);
Minimize.TextSize = 16;
CallsScroll.Name = "CallsScroll";
CallsScroll.Parent = InfoFrame;
CallsScroll.Active = true;
CallsScroll.BackgroundColor3 = colorSettings.Main.MainBackgroundColor;
CallsScroll.BorderColor3 = colorSettings.Main.MainBackgroundColor;
CallsScroll.Position = InfoButtonsScroll.Position;
CallsScroll.Size = InfoButtonsScroll.Size;
CallsScroll.ZIndex = 30;
CallsScroll.CanvasSize = UDim2.new(0, 0, 0, 0);
CallsScroll.ScrollBarThickness = 6;
CallsScroll.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left;
CallsScroll.ScrollBarImageColor3 = colorSettings.Main.ScrollBarImageColor;
CallsScroll.Visible = false;
CallButton.Name = "CallButton";
CallButton.Parent = CallsScroll;
CallButton.BackgroundColor3 = colorSettings.MainButtons.BackgroundColor;
CallButton.BorderColor3 = colorSettings.MainButtons.BorderColor;
CallButton.Position = UDim2.new(0, 10, 0, 10);
CallButton.Size = UDim2.new(0, 505, 0, 24);
CallButton.ZIndex = 31;
CallButton.Font = Enum.Font.SourceSans;
CallButton.Text = "Call #1";
CallButton.TextColor3 = Color3.fromRGB(250, 251, 255);
CallButton.TextSize = 14;
CallButton.Visible = false;
__NAProtectUI(TurtleSpyGUI);
local defaultButtonState = {}
local function ButtonEffect(textlabel, text)
	if not textlabel then
		return
	end
	local state = defaultButtonState[textlabel]
	if not state then
		state = {
			text = textlabel.Text,
			color = textlabel.TextColor3
		}
		defaultButtonState[textlabel] = state
	end
	local msg = text or "Copied!"
	textlabel.Text = msg
	textlabel.TextColor3 = Color3.fromRGB(76, 209, 55)
	task.delay(0.8, function()
		if defaultButtonState[textlabel] == state and textlabel.Parent then
			textlabel.Text = state.text
			textlabel.TextColor3 = state.color
		end
	end)
end
local function len(t)
	local n = 0;
	for _ in t do
		n = n + 1;
	end;
	return n;
end;
local hasBuffer = type(buffer) == "table" and type(buffer.fromstring) == "function";
local function quoteString(str)
	str = tostring(str or "")
	local out = {
		"\""
	}
	for i = 1, #str do
		local b = string.byte(str, i)
		if b == 34 then
			out[#out + 1] = "\\\""
		elseif b == 92 then
			out[#out + 1] = "\\\\"
		elseif b == 10 then
			out[#out + 1] = "\\n"
		elseif b == 13 then
			out[#out + 1] = "\\r"
		elseif b == 9 then
			out[#out + 1] = "\\t"
		elseif b >= 32 and b <= 126 then
			out[#out + 1] = string.char(b)
		else
			out[#out + 1] = string.format("\\%03d", b)
		end
	end
	out[#out + 1] = "\""
	return table.concat(out)
end
local function isBufferValue(value)
	if not hasBuffer then
		return false
	end
	if typeof(value) == "buffer" then
		return true
	end
	if type(buffer.len) == "function" then
		local ok = pcall(buffer.len, value)
		return ok
	end
	return false
end
local function bufferLiteral(value)
	if type(buffer.tostring) == "function" then
		local ok, str = pcall(buffer.tostring, value)
		if ok and type(str) == "string" then
			return "buffer.fromstring(" .. quoteString(str) .. ")"
		end
	end
	if type(buffer.len) == "function" and type(buffer.readu8) == "function" then
		local okLen, len = pcall(buffer.len, value)
		if okLen and type(len) == "number" then
			local bytes = {}
			for i = 0, len - 1 do
				local okByte, byte = pcall(buffer.readu8, value, i)
				bytes[#bytes + 1] = tostring((okByte and type(byte) == "number") and byte or 0)
			end
			return "buffer.fromstring(string.char(" .. table.concat(bytes, ",") .. "))"
		end
	end
	return "buffer.fromstring(\"\")"
end
local function isArray(tbl)
	local max = 0;
	local c = 0;
	for k in tbl do
		if type(k) ~= "number" then
			return false;
		end;
		if k > max then
			max = k;
		end;
		c = c + 1;
	end;
	return max == c;
end;
local function serializeValue(v, depth)
	depth = depth or 0;
	local t = typeof(v);
	if t == "Instance" then
		return GetFullPathOfAnInstance(v);
	elseif isBufferValue(v) then
		return bufferLiteral(v);
	elseif t == "Vector3" then
		return string.format("Vector3.new(%s, %s, %s)", v.X, v.Y, v.Z);
	elseif t == "Vector2" then
		return string.format("Vector2.new(%s, %s)", v.X, v.Y);
	elseif t == "CFrame" then
		local comps = {
			v:GetComponents()
		};
		return "CFrame.new(" .. table.concat(comps, ", ") .. ")";
	elseif t == "Color3" then
		return string.format("Color3.new(%s, %s, %s)", v.R, v.G, v.B);
	elseif t == "BrickColor" then
		return string.format("BrickColor.new(%q)", v.Name);
	elseif t == "EnumItem" then
		return tostring(v);
	end;
	if type(v) == "string" then
		return quoteString(v);
	elseif type(v) == "number" or type(v) == "boolean" then
		return tostring(v);
	elseif type(v) == "table" then
		return convertTableToString(v, depth);
	elseif type(v) == "userdata" then
		return "(" .. tostring(v) .. ")";
	else
		return tostring(v);
	end;
end;
function convertTableToString(tbl, depth)
	depth = depth or 0;
	local indent = string.rep("\t", depth);
	if type(tbl) ~= "table" then
		return serializeValue(tbl, depth);
	end;
	local parts = {};
	local innerIndent = indent .. "\t";
	if isArray(tbl) then
		for i = 1, #tbl do
			parts[(#parts) + 1] = innerIndent .. serializeValue(tbl[i], depth + 1);
		end;
	else
		local keys = {};
		for k in tbl do
			keys[(#keys) + 1] = k;
		end;
		table.sort(keys, function(a, b)
			return tostring(a) < tostring(b);
		end);
		for _, k in keys do
			local keyStr;
			if type(k) == "string" and k:match("^[%a_][%w_]*$") then
				keyStr = k .. " = ";
			else
				keyStr = "[" .. serializeValue(k, depth + 1) .. "] = ";
			end;
			parts[(#parts) + 1] = innerIndent .. keyStr .. serializeValue(tbl[k], depth + 1);
		end;
	end;
	if #parts == 0 then
		return "{}";
	end;
	return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}";
end;
local function buildNamedListTable(name, list)
	if type(list) ~= "table" then
		list = {
			list
		};
	end;
	local lines = {};
	local n = list.n or #list
	lines[(#lines) + 1] = "local " .. name .. " = {";
	for i = 1, n do
		lines[(#lines) + 1] = "\t[" .. i .. "] = " .. serializeValue(list[i], 1) .. ",";
	end;
	lines[(#lines) + 1] = "\tn = " .. tostring(n) .. ",";
	lines[(#lines) + 1] = "}";
	lines[(#lines) + 1] = "";
	return table.concat(lines, "\n");
end;
local function buildArgsTable(args)
	args = args or {};
	local n = args.n or #args;
	if n == 0 then
		return "";
	end;
	return buildNamedListTable("args", args);
end;
local function buildResultTable(results)
	return buildNamedListTable("result", results or {});
end;
local function codeSize(text)
	text = tostring(text or ""):gsub("\r\n", "\n"):gsub("\r", "\n"):gsub("\t", "    ")
	local char = MeasureText("M", Code.TextSize, Code.Font, Vector2.new(1000, 1000))
	local cw = math.max(char.X, 8)
	local lh = math.max(char.Y + 2, 16)
	local lines = 0
	local longest = 0
	for line in (text .. "\n"):gmatch("(.-)\n") do
		lines = lines + 1
		if #line > longest then
			longest = #line
		end
	end
	if lines < 1 then
		lines = 1
	end
	local minW = math.max(CodeFrame.AbsoluteSize.X - 16, 509)
	local minH = math.max(CodeFrame.AbsoluteSize.Y - 16, 138)
	return math.max(longest * cw + 20, minW), math.max(lines * lh + 12, minH)
end
local function fitCode()
	local w, h = codeSize(Code.Text)
	Code.Size = UDim2.new(0, w, 0, h)
	CodeFrame.CanvasSize = UDim2.new(0, w + 16, 0, h + 12)
end
local function updateCodeDisplay(remote, args, isClientEvent, callType)
	if not remote then
		return
	end
	args = args or {}
	local ok, codeText = pcall(function()
		local path = GetFullPathOfAnInstance(remote)
		local okDesc, inGame = pcall(function()
			return remote:IsDescendantOf(game)
		end)
		local needsNil = not (okDesc and inGame)
		local n = args.n or #args
		local text
		if callType == "OnClientInvoke" then
			text = buildArgsTable(args) .. path .. ".OnClientInvoke = function(...)\n\treturn nil\nend"
		elseif isClientEvent or callType == "OnClientEvent" then
			local evtPath = path .. ".OnClientEvent"
			if n == 0 then
				text = "firesignal(" .. evtPath .. ")"
			else
				text = buildArgsTable(args) .. "firesignal(" .. evtPath .. ", unpack(args, 1, args.n or #args))"
			end
		else
			local call = (callType == "InvokeServer" and ":InvokeServer") or ":FireServer"
			if callType == nil and isA(remote, "RemoteFunction") then
				call = ":InvokeServer"
			end
			if n == 0 then
				text = path .. call .. "()"
			else
				text = buildArgsTable(args) .. path .. call .. "(unpack(args, 1, args.n or #args))"
			end
		end
		if needsNil then
			text = getNilSource .. text
		end
		return text
	end)
	local finalText
	if not ok then
		local pathOk, path = pcall(GetFullPathOfAnInstance, remote)
		finalText = "-- Turtle Spy render error: " .. tostring(codeText) .. "\n" .. tostring(pathOk and path or remote)
	else
		finalText = codeText
	end
	local okSet = pcall(function()
		Code.Text = finalText
	end)
	if not okSet then
		Code.Text = "-- Turtle Spy text render error. The args contained invalid text bytes.\n" .. tostring(remote)
	end
	Code.TextWrapped = false
	fitCode()
end
Code:GetPropertyChangedSignal("Text"):Connect(fitCode)
CodeFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitCode)
local function isRemoteEvent(obj)
	return isA(obj, "RemoteEvent") or isA(obj, "UnreliableRemoteEvent");
end;
local function isRemoteInstance(obj)
	return typeof(obj) == "Instance" and (isRemoteEvent(obj) or isA(obj, "RemoteFunction"))
end
local function getRemoteInstances()
	local out = {}
	local seen = {}
	for _, v in game:QueryDescendants("Instance") do
		if isRemoteInstance(v) and not seen[v] then
			seen[v] = true
			out[#out + 1] = v
		end
	end
	for _, v in next, getNilInstancesSafe() do
		if isRemoteInstance(v) and v.Parent == nil and not seen[v] then
			seen[v] = true
			out[#out + 1] = v
		end
	end
	return out
end
local lookingAt
local lookingAtArgs
local lookingAtButton
local lookingAtIsClientEvent
local callLocked = false
tstate.spamRemote = {
	modes = { "RenderStepped", "PreSimulation", "Heartbeat" },
	modeIndex = 2,
	enabled = false,
	delay = 0,
	elapsed = 0
}

tstate.spamRemote.refreshControls = function()
	tstate.SpamRemote.Text = "Spam Remote: " .. (tstate.spamRemote.enabled and "ON" or "OFF")
	tstate.SpamRemote.TextColor3 = tstate.spamRemote.enabled and Color3.fromRGB(76, 209, 55) or Color3.fromRGB(250, 251, 255)
	tstate.SpamMode.Text = "Spam Mode: " .. tstate.spamRemote.modes[tstate.spamRemote.modeIndex]
	tstate.SpamDelayBox.Text = ("%g"):format(tstate.spamRemote.delay)
end

tstate.spamRemote.disconnect = function()
	if tstate.spamRemote.connection then
		pcall(function()
			tstate.spamRemote.connection:Disconnect()
		end)
		tstate.spamRemote.connection = nil
	end
end

tstate.spamRemote.runLookingAt = function()
	if not lookingAt or table.find(BlockList, lookingAt) then
		return false
	end

	local args = lookingAtArgs or {}
	local ok = pcall(function()
		if lookingAtIsClientEvent and isRemoteEvent(lookingAt) then
			if firesignal then
				firesignal(lookingAt.OnClientEvent, unpack(args))
			end
		elseif isA(lookingAt, "RemoteFunction") then
			lookingAt:InvokeServer(unpack(args))
		elseif isRemoteEvent(lookingAt) then
			lookingAt:FireServer(unpack(args))
		end
	end)

	return ok
end

tstate.spamRemote.connect = function()
	tstate.spamRemote.disconnect()
	tstate.spamRemote.elapsed = 0

	local mode = tstate.spamRemote.modes[tstate.spamRemote.modeIndex]
	local signal = tstate.RunService[mode] or tstate.RunService.Heartbeat
	tstate.spamRemote.connection = signal:Connect(function(dt)
		if not tstate.spamRemote.enabled then
			return
		end

		if tstate.spamRemote.delay <= 0 then
			tstate.spamRemote.runLookingAt()
			return
		end

		tstate.spamRemote.elapsed = tstate.spamRemote.elapsed + (dt or 0)
		if tstate.spamRemote.elapsed >= tstate.spamRemote.delay then
			tstate.spamRemote.elapsed = 0
			tstate.spamRemote.runLookingAt()
		end
	end)
end

tstate.spamRemote.setEnabled = function(enabled)
	tstate.spamRemote.enabled = enabled == true
	if tstate.spamRemote.enabled then
		tstate.spamRemote.connect()
	else
		tstate.spamRemote.disconnect()
	end
	tstate.spamRemote.refreshControls()
end

local function attachClientLogger(re)
	if clientEventConns[re] then
		return
	end
	clientEventConns[re] = re.OnClientEvent:Connect(function(...)
		if logClientEvents and not table.find(BlockList, re) and not table.find(IgnoreList, re) then
			local args = table.pack(...)
			addToList(true, re, args, nil, "OnClientEvent")
		end
	end)
	table.insert(connections, clientEventConns[re])
end

local function wrapOnClientInvokeCallback(rf, callback)
	if type(callback) ~= "function" then
		return callback
	end
	if wrappedInvokeCallbacks[callback] then
		return callback
	end
	wrappedInvokeCallbacks[callback] = rf
	local invoking = false
	return function(...)
		if invoking then
			return callback(...)
		end
		invoking = true
		local args = table.pack(...)
		local ok, results = pcall(function()
			return table.pack(callback(table.unpack(args, 1, args.n or #args)))
		end)
		invoking = false
		if not ok then
			addToList(false, rf, args, { results }, "OnClientInvoke")
			error(results)
		end
		addToList(false, rf, args, results, "OnClientInvoke")
		return table.unpack(results, 1, results.n or #results)
	end
end

local function wrapClientInvoke(rf)
	if wrappedClientInvoke[rf] then
		return
	end
	wrappedClientInvoke[rf] = true

	local current
	if getcallbackmember then
		local ok, cb = pcall(getcallbackmember, rf, "OnClientInvoke")
		if ok and type(cb) == "function" then
			current = cb
		end
	end
	if not current then
		local ok, cb = pcall(function()
			return rf.OnClientInvoke
		end)
		if ok and type(cb) == "function" then
			current = cb
		end
	end

	if type(current) == "function" then
		_origClientInvoke[rf] = current
		local ok = pcall(function()
			rf.OnClientInvoke = wrapOnClientInvokeCallback(rf, current)
		end)
		if not ok then
			wrappedClientInvoke[rf] = nil
		end
	end
end
local function setClientEventLogging(on)
	logClientEvents = on;
	if on then
		for _, v in getRemoteInstances() do
			if isRemoteEvent(v) then
				attachClientLogger(v);
			end;
		end;
		if not descAddedConn then
			descAddedConn = game.DescendantAdded:Connect(function(o)
				if logClientEvents and isRemoteEvent(o) then
					attachClientLogger(o);
				end;
			end);
			table.insert(connections, descAddedConn);
		end;
	else
		for remote, c in clientEventConns do
			pcall(function()
				c:Disconnect();
			end);
			clientEventConns[remote] = nil
		end;
	end;
end;

local function initClientInvokeLogging()
	for _, v in getRemoteInstances() do
		if isA(v, "RemoteFunction") then
			wrapClientInvoke(v)
		end
	end
	if not descAddedInvokeConn then
		descAddedInvokeConn = game.DescendantAdded:Connect(function(o)
			if isA(o, "RemoteFunction") then
				wrapClientInvoke(o)
			end
		end)
		table.insert(connections, descAddedInvokeConn)
	end
end
local function disableIncomingHooks()
	setClientEventLogging(false)
	if descAddedInvokeConn then
		pcall(function()
			descAddedInvokeConn:Disconnect()
		end)
		descAddedInvokeConn = nil
	end
	if tstate.oldNewIndex then
		local restored = hookMetaMethod and pcall(function()
			hookMetaMethod(game, "__newindex", tstate.oldNewIndex)
		end)
		if restored then
			tstate.newIndexHooked = false
			tstate.oldNewIndex = nil
		end
	end
	for remote, callback in _origClientInvoke do
		pcall(function()
			remote.OnClientInvoke = callback
		end)
		_origClientInvoke[remote] = nil
	end
	wrappedClientInvoke = {}
	wrappedInvokeCallbacks = {}
	tstate.wrappedClientInvoke = wrappedClientInvoke
end

local function enableIncomingHooks()
	setClientEventLogging(true)
	initClientInvokeLogging()
	if not tstate.newIndexHooked and hookMetaMethod then
		local oldNewIndex
		local ok, previous = pcall(hookMetaMethod, game, "__newindex", function(self, k, v)
			if tstate.enabled and logClientEvents and not safeCheckCaller() and typeof(self) == "Instance" and self:IsA("RemoteFunction") and k == "OnClientInvoke" and type(v) == "function" then
				wrapClientInvoke(self)
				return oldNewIndex(self, k, wrapOnClientInvokeCallback(self, v))
			end
			return oldNewIndex(self, k, v)
		end)
		if ok and previous then
			oldNewIndex = previous
			tstate.newIndexHooked = true
			tstate.oldNewIndex = tstate.oldNewIndex or previous
		end
	end
end
CopyCode.MouseButton1Click:Connect(function()
	if not lookingAt then
		return;
	end;
	setclipboard(Code.Text);
	ButtonEffect(CopyCode);
end);
RunCode.MouseButton1Click:Connect(function()
	if not lookingAt then
		return
	end
	if table.find(BlockList, lookingAt) then
		ButtonEffect(RunCode, "Blocked")
		return
	end
	if lookingAtIsClientEvent and isRemoteEvent(lookingAt) then
		if firesignal then
			firesignal(lookingAt.OnClientEvent, unpack(lookingAtArgs or {}))
		end
	else
		if isA(lookingAt, "RemoteFunction") then
			lookingAt:InvokeServer(unpack(lookingAtArgs or {}))
		elseif isRemoteEvent(lookingAt) then
			lookingAt:FireServer(unpack(lookingAtArgs or {}))
		end
	end
end)
tstate.SpamRemote.MouseButton1Click:Connect(function()
	if not lookingAt then
		return
	end
	tstate.spamRemote.setEnabled(not tstate.spamRemote.enabled)
end)
tstate.SpamDelayBox.FocusLost:Connect(function()
	local value = tonumber(tstate.SpamDelayBox.Text) or 0
	if value < 0 then
		value = 0
	end
	tstate.spamRemote.delay = value
	tstate.spamRemote.elapsed = 0
	tstate.spamRemote.refreshControls()
end)
tstate.SpamMode.MouseButton1Click:Connect(function()
	tstate.spamRemote.modeIndex = tstate.spamRemote.modeIndex + 1
	if tstate.spamRemote.modeIndex > #tstate.spamRemote.modes then
		tstate.spamRemote.modeIndex = 1
	end
	if tstate.spamRemote.enabled then
		tstate.spamRemote.connect()
	end
	tstate.spamRemote.refreshControls()
end)
tstate.spamRemote.refreshControls()
CopyScriptPath.MouseButton1Click:Connect(function()
	local remoteIdx = nil;
	if lookingAt then
		if table.find(unstacked, lookingAt) then
			for i, v in remotes do
				if v == lookingAt and remoteArgs[i] == lookingAtArgs then
					remoteIdx = i;
					break;
				end;
			end;
		else
			remoteIdx = table.find(remotes, lookingAt);
		end;
	end;
	if remoteIdx and lookingAt then
		setclipboard(GetFullPathOfAnInstance(remoteScripts[remoteIdx]));
		ButtonEffect(CopyScriptPath);
	end;
end);
local decompiling;
CopyDecompiled.MouseButton1Click:Connect(function()
	local remoteIdx = nil;
	if lookingAt then
		if table.find(unstacked, lookingAt) then
			for i, v in remotes do
				if v == lookingAt and remoteArgs[i] == lookingAtArgs then
					remoteIdx = i;
					break;
				end;
			end;
		else
			remoteIdx = table.find(remotes, lookingAt);
		end;
	end;
	if not isSynapse() then
		CopyDecompiled.Text = "This exploit doesn't support decompilation!";
		CopyDecompiled.TextColor3 = Color3.fromRGB(232, 65, 24);
		task.wait(1.6);
		CopyDecompiled.Text = "Copy decompiled script";
		CopyDecompiled.TextColor3 = Color3.fromRGB(250, 251, 255);
		return;
	end;
	if not decompiling and remoteIdx and lookingAt then
		decompiling = true;
		task.spawn(function()
			while decompiling do
				CopyDecompiled.Text = "Decompiling.";
				task.wait(0.8);
				if not decompiling then
					break;
				end;
				CopyDecompiled.Text = "Decompiling..";
				task.wait(0.8);
				if not decompiling then
					break;
				end;
				CopyDecompiled.Text = "Decompiling...";
				task.wait(0.8);
			end;
		end);
		local success = {
			pcall(function()
				setclipboard(decompile(remoteScripts[remoteIdx]));
			end)
		};
		decompiling = false;
		if success[1] then
			CopyDecompiled.Text = "Copied decompilation!";
			CopyDecompiled.TextColor3 = Color3.fromRGB(76, 209, 55);
		else
			warn(success[2], success[3]);
			CopyDecompiled.Text = "Decompilation error! Check F9 to see the error.";
			CopyDecompiled.TextColor3 = Color3.fromRGB(232, 65, 24);
		end;
		task.wait(1.6);
		CopyDecompiled.Text = "Copy decompiled script";
		CopyDecompiled.TextColor3 = Color3.fromRGB(250, 251, 255);
	end;
end);
BlockRemote.MouseButton1Click:Connect(function()
	local idx = table.find(BlockList, lookingAt)
	if lookingAt and not idx then
		table.insert(BlockList, lookingAt)
		BlockRemote.Text = "Unblock remote"
		BlockRemote.TextColor3 = Color3.fromRGB(251, 197, 49)
		local rIndex = table.find(remotes, lookingAt)
		if rIndex then
			local num = remoteButtons[rIndex]
			if num and num.Parent then
				local rn = num.Parent:FindFirstChild("RemoteName")
				if rn then
					rn.TextColor3 = Color3.fromRGB(225, 177, 44)
				end
			end
		end
	elseif lookingAt and idx then
		table.remove(BlockList, idx)
		BlockRemote.Text = "Block remote from firing"
		BlockRemote.TextColor3 = Color3.fromRGB(250, 251, 255)
		local rIndex = table.find(remotes, lookingAt)
		if rIndex then
			local num = remoteButtons[rIndex]
			if num and num.Parent then
				local rn = num.Parent:FindFirstChild("RemoteName")
				if rn then
					rn.TextColor3 = Color3.fromRGB(245, 246, 250)
				end
			end
		end
	end
end)
IgnoreRemote.MouseButton1Click:Connect(function()
	local idx = table.find(IgnoreList, lookingAt);
	if lookingAt and (not idx) then
		table.insert(IgnoreList, lookingAt);
		IgnoreRemote.Text = "Stop ignoring remote";
		IgnoreRemote.TextColor3 = Color3.fromRGB(127, 143, 166);
		local rIndex = table.find(remotes, lookingAt);
		if rIndex then
			local num = remoteButtons[rIndex];
			if num and num.Parent then
				local rn = num.Parent:FindFirstChild("RemoteName");
				if rn then
					rn.TextColor3 = Color3.fromRGB(127, 143, 166);
				end;
			end;
		end;
	elseif lookingAt and idx then
		table.remove(IgnoreList, idx);
		IgnoreRemote.Text = "Ignore remote";
		IgnoreRemote.TextColor3 = Color3.fromRGB(250, 251, 255);
		local rIndex = table.find(remotes, lookingAt);
		if rIndex then
			local num = remoteButtons[rIndex];
			if num and num.Parent then
				local rn = num.Parent:FindFirstChild("RemoteName");
				if rn then
					rn.TextColor3 = Color3.fromRGB(245, 246, 250);
				end;
			end;
		end;
	end;
end);
WhileLoop.MouseButton1Click:Connect(function()
	if not lookingAt then
		return;
	end;
	setclipboard("while task.wait() do\n   " .. Code.Text .. "\nend");
	ButtonEffect(WhileLoop);
end);
Clear.MouseButton1Click:Connect(function()
	for i, v in RemoteScrollFrame:GetChildren() do
		if i > 1 and v:IsA("TextButton") then
			v:Destroy();
		end;
	end;
	for _, v in connections do
		pcall(function()
			v:Disconnect();
		end);
	end;
	buttonOffset = -25;
	scrollSizeOffset = 0;
	remotes = {};
	remoteArgs = {};
	remoteButtons = {};
	remoteScripts = {};
	remoteLogs = {};
	IgnoreList = {};
	BlockList = {};
	unstacked = {};
	connections = {};
	RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 287);
	ButtonEffect(Clear, "Cleared!");
end);
DoNotStack.MouseButton1Click:Connect(function()
	if lookingAt then
		local isUnstacked = table.find(unstacked, lookingAt);
		if isUnstacked then
			table.remove(unstacked, isUnstacked);
			DoNotStack.Text = "Unstack new args";
			DoNotStack.TextColor3 = Color3.fromRGB(245, 246, 250);
		else
			table.insert(unstacked, lookingAt);
			DoNotStack.Text = "Stack remote";
			DoNotStack.TextColor3 = Color3.fromRGB(251, 197, 49);
		end;
	end;
end);
local function showCallsForRemote(remote, idx, button)
	local function callTypeLabel(entry)
		local t = entry and entry.callType
		if not t or t == "" then
			if entry and entry.isClientEvent then
				t = "OnClientEvent"
			elseif isA(remote, "RemoteFunction") then
				t = "InvokeServer"
			else
				t = "FireServer"
			end
		end
		return t
	end
	CallsScroll.Visible = true
	for _, c in CallsScroll:GetChildren() do
		if c:IsA("TextButton") and c ~= CallButton then
			c:Destroy()
		end
	end
	local list = remoteLogs[idx] or {}
	local offset = 10
	for i, data in list do
		local btn = CallButton:Clone()
		btn.Name = "CallItem"
		btn.Parent = CallsScroll
		btn.Visible = true
		btn.Position = UDim2.new(0, 10, 0, offset)
		btn.Text = ("Call #%d [%s]"):format(i, callTypeLabel(data))
		btn.MouseButton1Click:Connect(function()
			InfoHeaderText.Text = "Info: " .. remote.Name .. " #" .. i
			lookingAt = remote
			lookingAtArgs = data.args
			lookingAtIsClientEvent = data.isClientEvent
			lookingAtButton = button.Number
			callLocked = true
			updateCodeDisplay(remote, data.args, data.isClientEvent, data.callType)
			CallsScroll.Visible = false
		end)
		offset = offset + 30
	end
	CallsScroll.CanvasSize = UDim2.new(0, 0, 0, offset)
end
RemoteScrollFrame.ChildAdded:Connect(function(child)
	if not child:IsA("TextButton") then
		return
	end
	local idx = #remotes
	local remote = remotes[idx]
	local event = true
	if isA(remote, "RemoteFunction") then
		event = false
	end
	local connection = child.MouseButton1Click:Connect(function()
		InfoHeaderText.Text = "Info: " .. remote.Name
		mainFrame.Size = UDim2.new(0, 760, 0, 35)
		OpenInfoFrame.Text = "<"
		InfoFrame.Visible = true
		local list = remoteLogs[idx]
		local last = list and list[#list] or nil
		lookingAt = remote
		lookingAtArgs = last and last.args or remoteArgs[idx]
		lookingAtIsClientEvent = last and last.isClientEvent or false
		lookingAtButton = child.Number
		callLocked = false
		updateCodeDisplay(remote, lookingAtArgs, lookingAtIsClientEvent, last and last.callType or nil)
		local blocked = table.find(BlockList, remote)
		if blocked then
			BlockRemote.Text = "Unblock remote"
			BlockRemote.TextColor3 = Color3.fromRGB(251, 197, 49)
		else
			BlockRemote.Text = "Block remote from firing"
			BlockRemote.TextColor3 = Color3.fromRGB(250, 251, 255)
		end
		local iRemote = table.find(IgnoreList, lookingAt)
		if iRemote then
			IgnoreRemote.Text = "Stop ignoring remote"
			IgnoreRemote.TextColor3 = Color3.fromRGB(127, 143, 166)
		else
			IgnoreRemote.Text = "Ignore remote"
			IgnoreRemote.TextColor3 = Color3.fromRGB(250, 251, 255)
		end
		InfoFrameOpen = true
	end)
	table.insert(connections, connection)
	local expand = child:FindFirstChild("Expand")
	if expand then
		expand.MouseButton1Click:Connect(function()
			showCallsForRemote(remote, idx, child)
		end)
	end
end)
local function FindRemote(remote, args)
	local get_identity = syn and syn.get_thread_identity or getidentity or getthreadidentity or function()
		return 2;
	end;
	local set_identity = syn and syn.set_thread_identity or setidentity or setthreadidentity or function()
	end;
	local currentIdentity = get_identity();
	set_identity(7);
	local foundIndex = nil;
	if table.find(unstacked, remote) then
		for index, value in remotes do
			if value == remote and remoteArgs[index] == args then
				foundIndex = index;
				break;
			end;
		end;
	else
		foundIndex = table.find(remotes, remote);
	end;
	set_identity(currentIdentity);
	return foundIndex;
end;
function addToList(event, remote, argsPack, results, callType)
	local get_identity = syn and syn.get_thread_identity or getidentity or getthreadidentity or function()
		return 2
	end
	local set_identity = syn and syn.set_thread_identity or setidentity or setthreadidentity or function()
	end
	local currentId = get_identity()
	set_identity(7)
	if not remote then
		set_identity(currentId)
		return
	end
	local args = {}
	if type(argsPack) == "table" then
		local n = argsPack.n or #argsPack
		args.n = n
		for i = 1, n do
			args[i] = argsPack[i]
		end
	end
	local isClientEvent = event and results == nil
	local name = remote.Name
	local i = FindRemote(remote, args)
	if not i then
		table.insert(remotes, remote)
		local rButton = clone(RemoteButton)
		remoteButtons[#remotes] = rButton.Number
		remoteArgs[#remotes] = args
		remoteScripts[#remotes] = isSynapse() and getcallingscript() or rawget(getfenv(0), "script")
		remoteLogs[#remotes] = { { args = args, results = results, isClientEvent = isClientEvent, callType = callType } }
		rButton.Parent = RemoteScrollFrame
		rButton.Visible = true
		local numberTextsize = MeasureText(rButton.Number.Text, rButton.Number.TextSize, rButton.Number.Font)
		rButton.RemoteName.Position = UDim2.new(0, numberTextsize.X + 10, 0, 0)
		if name then
			rButton.RemoteName.Text = name
		end
		if not event then
			rButton.RemoteIcon.Image = functionImage
		end
		buttonOffset = buttonOffset + 35
		rButton.Position = UDim2.new(0.0912, 0, 0, buttonOffset)
		if #remotes > 8 then
			scrollSizeOffset = scrollSizeOffset + 35
			RemoteScrollFrame.CanvasSize = UDim2.new(0, 0, 0, scrollSizeOffset)
		end
	else
		local list = remoteLogs[i]
		if not list then
			list = {}
			remoteLogs[i] = list
		end
		table.insert(list, { args = args, results = results, isClientEvent = isClientEvent, callType = callType })
		remoteButtons[i].Text = tostring(#list)
		local numberTextsize = MeasureText(remoteButtons[i].Text, remoteButtons[i].TextSize, remoteButtons[i].Font)
		if remoteButtons[i].Parent then
			remoteButtons[i].Parent.RemoteName.Position = UDim2.new(0, numberTextsize.X + 10, 0, 0)
			remoteButtons[i].Parent.RemoteName.Size = UDim2.new(0, 149 - numberTextsize.X, 0, 26)
		end
		remoteArgs[i] = args
		if not callLocked and lookingAt and lookingAt == remote and lookingAtButton == remoteButtons[i] and InfoFrame.Visible then
			local last = list[#list]
			if last then
				lookingAtArgs = last.args
				lookingAtIsClientEvent = last.isClientEvent
				updateCodeDisplay(remote, lookingAtArgs, lookingAtIsClientEvent, last.callType)
			else
				updateCodeDisplay(remote, remoteArgs[i], false, nil)
			end
		end
	end
	set_identity(currentId)
end
local pathModeList = {
	"dot",
	"wait",
	"find"
};
ClientEventToggle.MouseButton1Click:Connect(function()
	if logClientEvents then
		disableIncomingHooks();
		ClientEventToggle.Text = "Log OnClientEvent: OFF";
		ClientEventToggle.TextColor3 = Color3.fromRGB(250, 251, 255);
	else
		enableIncomingHooks();
		ClientEventToggle.Text = "Log OnClientEvent: ON";
		ClientEventToggle.TextColor3 = Color3.fromRGB(76, 209, 55);
	end;
end);
PathModeBtn.MouseButton1Click:Connect(function()
	local idx = table.find(pathModeList, pathMode) or 1;
	idx = idx % (#pathModeList) + 1;
	pathMode = pathModeList[idx];
	if pathMode == "dot" then
		PathModeBtn.Text = "Path: .";
	elseif pathMode == "wait" then
		PathModeBtn.Text = "Path: WaitForChild";
	else
		PathModeBtn.Text = "Path: FindFirstChild";
	end;
	if lookingAt then
		updateCodeDisplay(lookingAt, lookingAtArgs, lookingAtIsClientEvent, nil);
	end;
end);
ImageButton.MouseButton1Click:Connect(function()
	BrowserHeader.Visible = not BrowserHeader.Visible;
	if not BrowserHeader.Visible then
		return;
	end;
	browseRemotes = {};
	for _, v in getRemoteInstances() do
		browseRemotes[#browseRemotes + 1] = v;
	end;
	refreshBrowserList(BrowserSearch.Text);
end);
CloseInfoFrame2.MouseButton1Click:Connect(function()
	BrowserHeader.Visible = false
end)
CloseInfoFrame.MouseButton1Click:Connect(function()
	if tstate and tstate.cleanup then
		tstate.cleanup();
	end;
end);
OpenInfoFrame.MouseButton1Click:Connect(function()
	if not InfoFrame.Visible then
		mainFrame.Size = UDim2.new(0, 760, 0, 35);
		OpenInfoFrame.Text = "<";
	elseif RemoteScrollFrame.Visible then
		mainFrame.Size = UDim2.new(0, 207, 0, 35);
		OpenInfoFrame.Text = ">";
	end;
	InfoFrame.Visible = not InfoFrame.Visible;
	InfoFrameOpen = not InfoFrameOpen;
end);
Minimize.MouseButton1Click:Connect(function()
	if RemoteScrollFrame.Visible then
		mainFrame.Size = UDim2.new(0, 207, 0, 35);
		OpenInfoFrame.Text = "<";
		InfoFrame.Visible = false;
	elseif InfoFrameOpen then
		mainFrame.Size = UDim2.new(0, 760, 0, 35);
		OpenInfoFrame.Text = "<";
		InfoFrame.Visible = true;
	else
		mainFrame.Size = UDim2.new(0, 207, 0, 35);
		OpenInfoFrame.Text = ">";
		InfoFrame.Visible = false;
	end;
	RemoteScrollFrame.Visible = not RemoteScrollFrame.Visible;
end);
table.insert(connections, mouse.KeyDown:Connect(function(key)
	if key:lower() == settings.Keybind:lower() then
		TurtleSpyGUI.Enabled = not TurtleSpyGUI.Enabled;
	end;
end));
if not tstate.hooked and hookMetaMethod then
	local old
	local ok, previous = pcall(hookMetaMethod, game, "__namecall", function(self, ...)
		local method = ((getnamecallmethod and getnamecallmethod()) or ""):lower()
		if tstate.enabled then
			if not safeCheckCaller() and (method == "fireserver" or method == "invokeserver") then
				if table.find(BlockList, self) then
					if method == "invokeserver" then
						return nil
					else
						return
					end
				end
				local args = table.pack(...)
				local results = table.pack(old(self, ...))
				if tstate.handler then
					task.spawn(function()
						pcall(tstate.handler, self, method, args, results)
					end)
				end
				return table.unpack(results, 1, results.n)
			end
		end
		return old(self, ...)
	end)
	if ok and previous then
		old = previous
		tstate.hooked = true
		tstate.old = tstate.old or previous
	end
end
if not directHookState.fireServer and hookFunction then
	local oldFireServer
	local hookedFireServer = hookClone(function(self, ...)
		if tstate.enabled and typeof(self) == "Instance" and isRemoteEvent(self) and not safeCheckCaller() then
			if table.find(BlockList, self) then
				return
			end
			local args = table.pack(...)
			local results = table.pack(oldFireServer(self, ...))
			if tstate.handler then
				task.spawn(function()
					pcall(tstate.handler, self, "fireserver", args, results)
				end)
			end
			return table.unpack(results, 1, results.n)
		end
		return oldFireServer(self, ...)
	end)
	local ok, previous = pcall(hookFunction, baseFireServer, hookedFireServer)
	if ok and previous then
		oldFireServer = previous
		tstate.oldFireServer = tstate.oldFireServer or previous
		directHookState.fireServer = true
	end
end
if not directHookState.unreliableFireServer and hookFunction and type(baseUnreliableFireServer) == "function" then
	local oldUnreliableFireServer
	local hookedUnreliableFireServer = hookClone(function(self, ...)
		if tstate.enabled and typeof(self) == "Instance" and isRemoteEvent(self) and not safeCheckCaller() then
			if table.find(BlockList, self) then
				return
			end
			local args = table.pack(...)
			local results = table.pack(oldUnreliableFireServer(self, ...))
			if tstate.handler then
				task.spawn(function()
					pcall(tstate.handler, self, "fireserver", args, results)
				end)
			end
			return table.unpack(results, 1, results.n)
		end
		return oldUnreliableFireServer(self, ...)
	end)
	local ok, previous = pcall(hookFunction, baseUnreliableFireServer, hookedUnreliableFireServer)
	if ok and previous then
		oldUnreliableFireServer = previous
		tstate.oldUnreliableFireServer = tstate.oldUnreliableFireServer or previous
		directHookState.unreliableFireServer = true
	end
end
if not directHookState.invokeServer and hookFunction then
	local oldInvokeServer
	local hookedInvokeServer = hookClone(function(self, ...)
		if tstate.enabled and typeof(self) == "Instance" and isA(self, "RemoteFunction") and not safeCheckCaller() then
			if table.find(BlockList, self) then
				return nil
			end
			local args = table.pack(...)
			local results = table.pack(oldInvokeServer(self, ...))
			if tstate.handler then
				task.spawn(function()
					pcall(tstate.handler, self, "invokeserver", args, results)
				end)
			end
			return table.unpack(results, 1, results.n)
		end
		return oldInvokeServer(self, ...)
	end)
	local ok, previous = pcall(hookFunction, baseInvokeServer, hookedInvokeServer)
	if ok and previous then
		oldInvokeServer = previous
		tstate.oldInvokeServer = tstate.oldInvokeServer or previous
		directHookState.invokeServer = true
	end
end
tstate.handler = function(self, method, args, results)
	if method == "fireserver" and isRemoteEvent(self) then
		if not table.find(BlockList, self) and not table.find(IgnoreList, self) then
			addToList(true, self, args, results, "FireServer")
		end
	elseif method == "invokeserver" and isA(self, "RemoteFunction") then
		if not table.find(BlockList, self) and not table.find(IgnoreList, self) then
			addToList(false, self, args, results, "InvokeServer")
		end
	end
end
runAdonisBypass()
tstate.cleanup = function()
	tstate.enabled = false;
	tstate.spamRemote.disconnect()
	for _, c in connections do
		pcall(function()
			c:Disconnect()
		end)
	end
	for _, c in clientEventConns do
		pcall(function()
			c:Disconnect()
		end)
	end
	if descAddedInvokeConn then
		pcall(function()
			descAddedInvokeConn:Disconnect()
		end)
		descAddedInvokeConn = nil
	end
	if descAddedConn then
		pcall(function()
			descAddedConn:Disconnect()
		end)
		descAddedConn = nil
	end
	if tstate.old and hookMetaMethod then
		local restored = pcall(function()
			hookMetaMethod(game, "__namecall", tstate.old)
		end)
		if restored then
			tstate.hooked = false
		end
	end
	if directHookState.fireServer and tstate.oldFireServer then
		local restored = false
		if type(restoreFunction) == "function" then
			restored = pcall(function()
				restoreFunction(baseFireServer)
			end)
		end
		if not restored then
			restored = pcall(function()
				hookFunction(baseFireServer, tstate.oldFireServer)
			end)
		end
		if restored then
			directHookState.fireServer = false
		end
	end
	if directHookState.unreliableFireServer and tstate.oldUnreliableFireServer and type(baseUnreliableFireServer) == "function" then
		local restored = false
		if type(restoreFunction) == "function" then
			restored = pcall(function()
				restoreFunction(baseUnreliableFireServer)
			end)
		end
		if not restored then
			restored = pcall(function()
				hookFunction(baseUnreliableFireServer, tstate.oldUnreliableFireServer)
			end)
		end
		if restored then
			directHookState.unreliableFireServer = false
		end
	end
	if directHookState.invokeServer and tstate.oldInvokeServer then
		local restored = false
		if type(restoreFunction) == "function" then
			restored = pcall(function()
				restoreFunction(baseInvokeServer)
			end)
		end
		if not restored then
			restored = pcall(function()
				hookFunction(baseInvokeServer, tstate.oldInvokeServer)
			end)
		end
		if restored then
			directHookState.invokeServer = false
		end
	end
	if tstate.oldNewIndex and hookMetaMethod then
		local restored = pcall(function()
			hookMetaMethod(game, "__newindex", tstate.oldNewIndex)
		end)
		if restored then
			tstate.newIndexHooked = false
		end
	end
	connections = {}
	clientEventConns = {}
	wrappedClientInvoke = {}
	wrappedInvokeCallbacks = {}
	_origClientInvoke = {}
	if TurtleSpyGUI and TurtleSpyGUI.Parent then
		pcall(function()
			TurtleSpyGUI:Destroy()
		end)
	end
end;
