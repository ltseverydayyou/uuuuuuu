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
local function __NADexProtectOptions(options)
	local merged = {}
	if type(options) == "table" then
		for key, value in next, options do
			merged[key] = value
		end
	end

	if merged.ignoreGuiInset == nil then
		merged.ignoreGuiInset = false
	end
	if merged.IgnoreGuiInset == nil then
		merged.IgnoreGuiInset = merged.ignoreGuiInset
	end
	if merged.forceIgnoreGuiInset == nil then
		merged.forceIgnoreGuiInset = merged.ignoreGuiInset
	end
	if merged.enforceIgnoreGuiInset == nil then
		merged.enforceIgnoreGuiInset = merged.ignoreGuiInset
	end
	if merged.setIgnoreGuiInset == nil then
		merged.setIgnoreGuiInset = merged.ignoreGuiInset
	end
	if merged.autoEnable == nil then
		merged.autoEnable = false
	end
	if merged.autoEnabled == nil then
		merged.autoEnabled = merged.autoEnable
	end
	if merged.forceEnabled == nil then
		merged.forceEnabled = merged.autoEnable
	end
	if merged.enforceEnabled == nil then
		merged.enforceEnabled = merged.autoEnable
	end
	if merged.lockEnabled == nil then
		merged.lockEnabled = merged.autoEnable
	end
	if merged.enabledLoop == nil then
		merged.enabledLoop = merged.autoEnable
	end
	return merged
end

local function __NAApplyDexScreenGuiOptions(gui, options)
	if typeof(gui) ~= "Instance" then
		return gui
	end
	options = type(options) == "table" and options or {}

	local screenGui = nil
	if gui:IsA("ScreenGui") then
		screenGui = gui
	else
		local parent = gui.Parent
		if typeof(parent) == "Instance" and parent:IsA("ScreenGui") then
			screenGui = parent
		end
	end

	if screenGui then
		if options.autoEnable == true or options.autoEnabled == true or options.forceEnabled == true or options.enforceEnabled == true or options.lockEnabled == true or options.enabledLoop == true then
			pcall(function()
				screenGui.Enabled = true
			end)
		end
		if options.ignoreGuiInset == true or options.IgnoreGuiInset == true then
			return gui
		end
		pcall(function()
			screenGui.IgnoreGuiInset = false
		end)
		pcall(function()
			screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
		end)
	end

	return gui
end

local function __NAProtectUI(gui, options)
	if __NAUIProtector and type(__NAUIProtector.protectUI) == "function" then
		local protectOptions = __NADexProtectOptions(options)
		if protectOptions.enforceParent == false or protectOptions.lockParent == false or protectOptions.parentLock == false then
			if type(__NAUIProtector.nativeProtect) == "function" then
				pcall(__NAUIProtector.nativeProtect, gui)
			end
			__NAApplyDexScreenGuiOptions(gui, protectOptions)
			local okHui, hui = pcall(gethui)
			if okHui and typeof(hui) == "Instance" then
				gui.Parent = hui
				return gui
			end
			return nil
		end
		local ok, protected = pcall(__NAUIProtector.protectUI, gui, protectOptions);
		if ok and protected then
			__NAApplyDexScreenGuiOptions(gui, protectOptions)
			__NAApplyDexScreenGuiOptions(protected, protectOptions)
			return protected;
		end;
	end;
	return nil;
end;

local DEXPP_STATE_KEY = "__DEXPP_STATE"
local DEXPP_LEGACY_KEY = "__DEXPP"
local globalStores = {}

do
	local seen = {}
	local function addStore(store)
		if type(store) == "table" and not seen[store] then
			seen[store] = true
			table.insert(globalStores, store)
		end
	end

	local okGenv, genv = pcall(function()
		return (getgenv and getgenv()) or nil
	end)
	if okGenv then
		addStore(genv)
	end
	addStore(_G)
end

local function syncDexStateReferences(state)
	for _, store in globalStores do
		rawset(store, DEXPP_STATE_KEY, state)
		rawset(store, DEXPP_LEGACY_KEY, state)
	end
	return state
end

local function getDexState(create)
	for _, store in globalStores do
		local state = rawget(store, DEXPP_STATE_KEY)
		if type(state) == "table" then
			return syncDexStateReferences(state)
		end

		local legacyState = rawget(store, DEXPP_LEGACY_KEY)
		if type(legacyState) == "table" then
			return syncDexStateReferences(legacyState)
		end
	end

	if not create then
		return nil
	end

	return syncDexStateReferences({})
end

local function clearDexState(state)
	for _, store in globalStores do
		if rawget(store, DEXPP_STATE_KEY) == state then
			rawset(store, DEXPP_STATE_KEY, nil)
		end
		if rawget(store, DEXPP_LEGACY_KEY) == state then
			rawset(store, DEXPP_LEGACY_KEY, nil)
		end
	end
end

local function isLiveDexState(state)
	if type(state) ~= "table" then
		return false
	end

	local main = rawget(state, "Main")
	if type(main) ~= "table" or type(main.Exit) ~= "function" then
		return false
	end

	local gui = rawget(main, "MainGui")
	if typeof(gui) == "Instance" then
		local okParent, parent = pcall(function()
			return gui.Parent
		end)
		if okParent and parent then
			local okOpenButton, openButton = pcall(function()
				return gui:FindFirstChild("OpenButton")
			end)
			if okOpenButton and openButton then
				return true
			end
		end
	end

	if rawget(main, "__DexInitStarted") == true then
		local startedAt = tonumber(rawget(state, "StartedAt"))
		if startedAt and (os.clock() - startedAt) <= 30 then
			return true
		end
	end

	return false
end

do
	local existingState = getDexState(false)
	if existingState and isLiveDexState(existingState) then
		pcall(function()
			local existingMain = existingState.Main
			if existingMain and existingMain.__DexLoaded and existingMain.SetMainGuiOpen then
				existingMain.SetMainGuiOpen(true)
			end
		end)
		return existingState
	elseif existingState then
		clearDexState(existingState)
	end
end

local oldgame = oldgame or game

local function cref(x)
	local f = cloneref
	if type(f) == "function" then
		local ok, y = pcall(f, x)
		if ok and y then
			return y
		end
	end
	return x
end

local isFsSupported = readfile and writefile and isfile and isfolder and listfiles and delfile and delfolder

-- Main vars
local Main, Explorer, Properties, ScriptViewer, Console, SaveInstance, ModelViewer, SettingsWindow, ThemeManager, EnvExplorer, DataExplorer, DebugExplorer--[[, SecretServicePanel]], DefaultSettings, Notebook, Serializer, Lib
local ggv = getgenv
local API, RMD

-- Default Settings
DefaultSettings = (function()
	local rgb = Color3.fromRGB

	return {
		Explorer = {
			_Recurse = true,
			Sorting = true,
			TeleportToOffset = Vector3.new(0,0,0),
			ClickToRename = true,
			AutoUpdateSearch = false,
			KeyboardShortcuts = true,
			AutoUpdateMode = 0, -- 0 Default, 1 no tree update, 2 no descendant events, 3 frozen
			PartSelectionBox = true,
			GuiSelectionBox = true,
			GuiSelectorScope = "PlayerGui",
			IgnoreInvisibleUI = true,
			CopyPathUseGetChildren = true,
			UseNameWidth = false,
			MaxSelectionBoxes = 1000
		},
		Properties = {
			_Recurse = true,
			MaxConflictCheck = 50,
			ShowDeprecated = true,
			ShowHidden = false,
			ClearOnFocus = false,
			LoadstringInput = true,
			NumberRounding = 3,
			ShowAttributes = true,
			MaxAttributes = 50,
			ScaleType = 0 -- 0 Full Name Shown, 1 Equal Halves
		},
		Theme = {
			_Recurse = true,
			Main1 = rgb(52,52,52),
			Main2 = rgb(45,45,45),
			Outline1 = rgb(33,33,33), -- Mainly frames
			Outline2 = rgb(55,55,55), -- Mainly button
			Outline3 = rgb(30,30,30), -- Mainly textbox
			TextBox = rgb(38,38,38),
			Menu = rgb(32,32,32),
			ListSelection = rgb(11,90,175),
			Button = rgb(60,60,60),
			ButtonHover = rgb(68,68,68),
			ButtonPress = rgb(40,40,40),
			Highlight = rgb(75,75,75),
			Text = rgb(255,255,255),
			PlaceholderText = rgb(100,100,100),
			Important = rgb(255,0,0),
			ExplorerIconMap = "",
			MiscIconMap = "",
			Syntax = {
				Text = rgb(204,204,204),
				Background = rgb(36,36,36),
				Selection = rgb(255,255,255),
				SelectionBack = rgb(11,90,175),
				Operator = rgb(204,204,204),
				Number = rgb(255,198,0),
				String = rgb(173,241,149),
				Comment = rgb(102,102,102),
				Keyword = rgb(248,109,124),
				Error = rgb(255,0,0),
				FindBackground = rgb(141,118,0),
				MatchingWord = rgb(85,85,85),
				BuiltIn = rgb(132,214,247),
				CurrentLine = rgb(45,50,65),
				LocalMethod = rgb(253,251,172),
				LocalProperty = rgb(97,161,241),
				Nil = rgb(255,198,0),
				Bool = rgb(255,198,0),
				Function = rgb(248,109,124),
				Local = rgb(248,109,124),
				Self = rgb(248,109,124),
				FunctionName = rgb(253,251,172),
				Bracket = rgb(204,204,204)
			},
		},
		ScriptViewer = {
			ShowMoreInfo = true
		},
		Window = {
			TitleOnMiddle = false,
			Transparency = .2,
			Font = "SourceSans",
			SettingsWidth = 250,
			SettingsHeight = 375
		},
		Startup = {
			_Recurse = true,
			ExplorerSide = "Right",
			PropertiesSide = "Right",
			OpenExplorer = true,
			OpenProperties = true
		},
		Decompiler = {
			DecompilerFallback = "lua.expert", -- lua.expert, Konstant
			PreferDecompilerFallback = false,
		},
		Files = {
			_Recurse = true,
			SaveInstanceNameFormat = "{placeName}_{timestamp}",
			ObjectSaveNameFormat = "{className}_{name}_{timestamp}"
		},
		RemoteBlockWriteAttribute = false, -- writes attribute to remote instance if remote is blocked/unblocked
		ClassIcon = "NewDark",
		-- What available icons:
		-- > Vanilla3
		-- > Old
		-- > NewDark
	}
end)()

local service = setmetatable({},{__index = function(self,name)
	local serv
	serv = __lt.cs(name, cref)
	self[name] = serv
	return serv
end})


local function decodeBase64(data)
	data = (data or ""):gsub("%s+", "")

	local methods = {
		function(str)
			if service.HttpService and service.HttpService.Base64Decode then
				return service.HttpService:Base64Decode(str)
			end
			error("HttpService.Base64Decode unavailable")
		end,
		function(str)
			if syn and syn.crypt and syn.crypt.base64 and syn.crypt.base64.decode then
				return syn.crypt.base64.decode(str)
			end
			error("syn.crypt.base64.decode unavailable")
		end,
		function(str)
			if crypt and crypt.base64decode then
				return crypt.base64decode(str)
			end
			error("crypt.base64decode unavailable")
		end,
		function(str)
			local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
			str = str:gsub('[^'..b..'=]', '')
			return (str:gsub('.', function(x)
				if x == '=' then return '' end
				local r, f = '', (b:find(x) - 1)
				for i = 6, 1, -1 do
					r = r .. ((f % 2^i - f % 2^(i - 1) > 0) and '1' or '0')
				end
				return r
			end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
				if #x ~= 8 then return '' end
				local c = 0
				for i = 1, 8 do
					if x:sub(i, i) == '1' then
						c = c + 2^(8 - i)
					end
				end
				return string.char(c)
			end))
		end,
	}

	for _, method in methods do
		local ok, result = pcall(method, data)
		if ok and type(result) == "string" then
			return true, result
		end
	end

	return false, "Base64 decode failed"
end
local plr = service.Players.LocalPlayer or service.Players.PlayerAdded:Wait()

local create = function(data)
	local insts = {}
	for i,v in data do insts[v[1]] = Instance.new(v[2]) end

	for _,v in data do
		for prop,val in v[3] do
			if type(val) == "table" then
				insts[v[1]][prop] = insts[val[1]]
			else
				insts[v[1]][prop] = val
			end
		end
	end

	return insts[1]
end

local createSimple = function(class,props)
	local inst = Instance.new(class)
	for i,v in next,props do
		inst[i] = v
	end
	return inst
end

local function deepCopy(obj)
	local objType = typeof(obj)
	if objType == "Color3" then
		return Color3.new(obj.R, obj.G, obj.B)
	elseif objType == "Vector3" then
		return Vector3.new(obj.X, obj.Y, obj.Z)
	elseif type(obj) == "table" then
		local t = {}
		for k,v in obj do
			t[k] = deepCopy(v)
		end
		return t
	else
		return obj
	end
end

Main = (function()
	local Main = {}
	Main.GuiList = Main.GuiList or {}
	Main.ConnList = Main.ConnList or {}
	Main.ConnSet = Main.ConnSet or {}
	Main.TrackGui = function(gui)
		if gui and gui.Destroy then
			table.insert(Main.GuiList, gui)
		end
	end
	Main.TrackConn = function(c)
		if not c then
			return c
		end
		if Main.__DexExiting then
			pcall(function()
				if c.Disconnect then
					c:Disconnect()
				elseif c.disconnect then
					c:disconnect()
				end
			end)
			return c
		end
		if Main.ConnSet[c] then
			return c
		end
		Main.ConnSet[c] = true
		table.insert(Main.ConnList, c)
		return c
	end
	local function trackConn(c)
		return Main.TrackConn(c)
	end
	local Settings = deepCopy(DefaultSettings)
	local Apps = {}
	local env = {}
	local DefaultSettingsOrig = deepCopy(DefaultSettings)

	Main.UserSettings = {
		ConsoleFilters = {
			Output = true,
			Info = true,
			Warn = true,
			Error = true,
			Listen = true,
		},
		ConsoleCtrlScroll = false,
		ConsoleAutoScroll = false,
		ConsoleOutputLimit = 500,
		ConsoleTextSize = 15,
		RememberLastSettingsTab = true,
		SettingsLastTab = "UI"
	}
	Main.ThemeSettings = {}

	Main.StartupModuleList = {"Explorer","Properties","ScriptViewer"}
	Main.DeferredModuleList = {"Console","SaveInstance","ModelViewer","ThemeManager","SettingsWindow"}
	Main.ModuleList = {"Explorer","Properties","ScriptViewer","Console","SaveInstance","ModelViewer","SettingsWindow","ThemeManager"}
	Main.OptionalModuleList = {"EnvExplorer","DataExplorer","DebugExplorer"}
	Main.Elevated = false
	Main.AllowDraggableOnMobile = true
	Main.MissingEnv = {}
	Main.Version = "2.3"
	Main.Mouse = plr:GetMouse()
	Main.AppControls = {}
	Main.Apps = Apps
	Main.MenuApps = {}
	Main.Plugins = {}
	Main.GitRepoName = "ltseverydayyou/uuuuuuu"
	Main.GitRepoBranch = "main"
	Main.GitModulesPath = "DexPlusModules"
	Main.ModuleHashData = {} -- prevent remote hash fetch; prefer local modules
	Main.ModuleForceRefresh = false
	Main.ModuleCacheVersion = "2026-06-12-safe-user-tostring"
	Main.ModuleRefreshFlagFile = "DexPlusPlus/RefreshModules.txt"
	Main.SettingsFile = "DexPlusSettings.json"
	Main.UserSettingsFile = "DexPlusUserSettings.json"
	Main.ThemeFile = "DexPlusTheme.json"
	Main.IconOverrides = {
		["rbxassetid://6511490623"] = "NewestIcons.png",
		["rbxassetid://129589545519436"] = "icons.png",
		["rbxassetid://6578933307"] = "info.png",
		["rbxassetid://6578871732"] = "settings.png",
		["rbxassetid://1427967925"] = "borders.png",
		["rbxassetid://2764171053"] = "2.png",
		["rbxassetid://5642383285"] = "Test_Icons.png",
		["rbxassetid://5034718129"] = "search2.png",
		["rbxassetid://5642310344"] = "refresh-icon3.png",
		["rbxassetid://5034718180"] = "settings2.png",
		["rbxassetid://5054663650"] = "close3.png",
		["rbxassetid://5034768003"] = "minimize2.png",
		["rbxassetid://5060023708"] = "arrow3.png",
		["rbxassetid://5448127505"] = "squares_icon2.png",
		["rbxassetid://6234266378"] = "checkmark.png",
		["rbxassetid://6401617475"] = "checkmark2.png",
		["rbxassetid://6425281788"] = "luvlies.png",
		["rbxassetid://1281023007"] = "honey_icon.png",
		["rbxassetid://1072518406"] = "colors.png",
		["rbxassetid://1072518502"] = "colorstrip.png",
		["rbxassetid://135148380892747"] = "Texture.png",
		["rbxassetid://114851699900089"] = "Vanilla3.png",
		["DexPlusIconDraft"] = "icondraft.png",
	}
	Main.IconSourceBaseUrl = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/main/DexPlusIcons/"
	Main.ResolvedAssetCache = {}
	Main.IconFileReady = {}
	Main.IconFoldersReady = false

	Main.DisplayOrders = {
		SideWindow = 2147483628,
		Window = 2147483629,
		Menu = 2147483630,
		Core = 2147483631
	}

	--[[Main.LoadAdonisBypass = function()
		-- skidded off reddit :pensive:
		local getinfo = getinfo or debug.getinfo
		local DEBUG = false
		local Hooked = {}
		local hookCallable = env.GetHookFunction and env.GetHookFunction()

		local Detected, Kill

		setthreadidentity(2)

		for i, v in getgc(true) do
			if typeof(v) == "table" then
				local DetectFunc = rawget(v, "Detected")
				local KillFunc = rawget(v, "Kill")

				if typeof(DetectFunc) == "function" and not Detected then
					Detected = DetectFunc

					local Old; Old = hookCallable(Detected, function(Action, Info, NoCrash)
						if Action ~= "_" then
							if DEBUG then
								warn(`Adonis AntiCheat flagged\nMethod: {Action}\nInfo: {Info}`)
							end
						end

						return true
					end)

					table.insert(Hooked, Detected)
				end

				if rawget(v, "Variables") and rawget(v, "Process") and typeof(KillFunc) == "function" and not Kill then
					Kill = KillFunc
					local Old; Old = hookCallable(Kill, function(Info)
						if DEBUG then
							warn(`Adonis AntiCheat tried to kill (fallback): {Info}`)
						end
					end)

					table.insert(Hooked, Kill)
				end
			end
		end

		local Old; Old = hookCallable(getrenv().debug.info, newcclosure(function(...)
			local LevelOrFunc, Info = ...

			if Detected and LevelOrFunc == Detected then
				if DEBUG then
					warn(`Adonis AntiCheat sanity check detected and broken`)
				end

				return coroutine.yield(coroutine.running())
			end

			return Old(...)
		end))
		-- setthreadidentity(9)
		setthreadidentity(7)
	end
	
	Main.LoadGCBypass = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/secretisadev/Babyhamsta_Backup/refs/heads/main/Universal/Bypasses.lua", true))()
	end]]

	Main.GetRandomString = function()
		local hs = service.HttpService
		if hs and hs.GenerateGUID then
			return hs:GenerateGUID(false)
		end
		return tostring(math.random(1, 1e9))
	end

	Main.ResolveAsset = function(assetId)
		local override = Main.IconOverrides and Main.IconOverrides[assetId]
		if override then
			local getter = (env and env.getcustomasset) or getcustomasset or getsynasset
			local path = "DexPlusPlus/assets/"..override
			local cached = Main.ResolvedAssetCache and Main.ResolvedAssetCache[path]
			if cached then
				return cached
			end

			if env and env.makefolder and not Main.IconFoldersReady then
				pcall(env.makefolder,"DexPlusPlus")
				pcall(env.makefolder,"DexPlusPlus/assets")
				Main.IconFoldersReady = true
			end

			local function ensureFile()
				if Main.IconFileReady[path] then
					return true
				end
				if env and env.isfile then
					local okExists, exists = pcall(env.isfile, path)
					if okExists and exists then
						Main.IconFileReady[path] = true
						return true
					end
				end
				if not (env and env.writefile) then
					return false
				end
				local url = Main.IconSourceBaseUrl .. override
				local ok, bytes = pcall(oldgame.HttpGet, game, url)
				if ok and type(bytes) == "string" then
					local okWrite = pcall(env.writefile, path, bytes)
					if okWrite then
						Main.IconFileReady[path] = true
						return true
					end
				end
				return false
			end

			if ensureFile() and getter then
				local ok, result = pcall(getter, path)
				if ok and result then
					Main.ResolvedAssetCache[path] = result
					return result
				end
			end
		end
		return assetId
	end

	Main.SecureGui = function(gui, options)
		if typeof(gui) ~= "Instance" then
			return nil
		end

		gui.Name = Main.GetRandomString()
		if Main.TrackGui then
			Main.TrackGui(gui)
		end

		local protected = __NAProtectUI(gui, options)
		if protected then
			return protected
		end

		local okHui, hui = pcall(gethui)
		if okHui and typeof(hui) == "Instance" then
			gui.Parent = hui
			return gui
		end

		-- Last-resort fallback only when UIprotector/gethui failed to load.
		local playerGui = plr and plr:FindFirstChildOfClass("PlayerGui")
		local holder = (Main.GuiHolder and typeof(Main.GuiHolder) == "Instance" and Main.GuiHolder)
			or (Main.Elevated and service.CoreGui)
			or playerGui
		if holder then
			gui.Parent = holder
			return gui
		end
		return nil
	end

	Main.GetInitDeps = function()
		return {
			Main = Main,
			Lib = Lib,
			Apps = Apps,
			Settings = Settings,

			API = API,
			RMD = RMD,
			env = env,
			service = service,
			plr = plr,
			create = create,
			createSimple = createSimple
		}
	end

	Main.Error = function(str)
		if rconsoleprint then
			rconsoleprint("DEX ERROR: "..tostring(str).."\n")
		end
		error(str)
	end

	Main.SanitizeFileNamePart = function(value, fallback)
		value = tostring(value or "")
		value = value:gsub("[%c\\/:*?\"<>|]", "_")
		value = value:gsub("%s+", " ")
		value = value:gsub("^%s+", ""):gsub("%s+$", "")

		if value == "" then
			return fallback or "Unnamed"
		end

		return value
	end

	Main.GetPlaceDisplayName = function()
		if type(Main.PlaceDisplayName) == "string" and Main.PlaceDisplayName ~= "" then
			return Main.PlaceDisplayName
		end

		local placeName = "UnknownPlace"
		local marketplaceService = __lt.cs("MarketplaceService", cloneref)
		local okInfo, info = pcall(marketplaceService.GetProductInfo, marketplaceService, game.PlaceId)
		if okInfo and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
			placeName = info.Name
		end

		Main.PlaceDisplayName = Main.SanitizeFileNamePart(placeName, "UnknownPlace")
		return Main.PlaceDisplayName
	end

	Main.FormatFileName = function(template, extraTokens)
		local formatText = tostring(template or "")
		if formatText == "" then
			formatText = "{placeName}_{timestamp}"
		end

		local tokens = {}
		if type(extraTokens) == "table" then
			for key, value in extraTokens do
				tokens[key] = value
			end
		end

		if tokens.timestamp == nil then
			tokens.timestamp = os.date("%d-%m-%Y_%H-%M-%S")
		end
		if tokens.date == nil then
			tokens.date = os.date("%d-%m-%Y")
		end
		if tokens.time == nil then
			tokens.time = os.date("%H-%M-%S")
		end
		if tokens.unix == nil then
			tokens.unix = tostring(os.time())
		end
		if tokens.placeId == nil then
			tokens.placeId = tostring(game.PlaceId)
		end
		if tokens.placeName == nil and formatText:find("{placeName}", 1, true) then
			tokens.placeName = Main.GetPlaceDisplayName()
		end
		if tokens.name == nil and formatText:find("{name}", 1, true) then
			tokens.name = "Instance"
		end
		if tokens.className == nil and formatText:find("{className}", 1, true) then
			tokens.className = "Instance"
		end
		if tokens.index == nil and formatText:find("{index}", 1, true) then
			tokens.index = 1
		end
		if tokens.count == nil and formatText:find("{count}", 1, true) then
			tokens.count = 1
		end
		tokens.TIMESTAMP = tokens.TIMESTAMP or tokens.timestamp
		tokens.DATE = tokens.DATE or tokens.date
		tokens.TIME = tokens.TIME or tokens.time
		tokens.UNIX = tokens.UNIX or tokens.unix
		tokens.PLACEID = tokens.PLACEID or tokens.placeId
		tokens.PLACENAME = tokens.PLACENAME or tokens.placeName
		tokens.NAME = tokens.NAME or tokens.name
		tokens.CLASSNAME = tokens.CLASSNAME or tokens.className
		tokens.INDEX = tokens.INDEX or tokens.index
		tokens.COUNT = tokens.COUNT or tokens.count

		local resolved = formatText:gsub("{([%w_]+)}", function(token)
			local value = tokens[token]
			if value == nil then
				return "{"..token.."}"
			end
			return Main.SanitizeFileNamePart(value, "Unnamed")
		end)

		return Main.SanitizeFileNamePart(resolved, "File_"..tostring(tokens.timestamp or os.time()))
	end

	Main.FetchRepoFile = function(path)
		local branch = Main.GitRepoBranch or "main"
		local apiUrl = ("https://api.github.com/repos/%s/contents/%s?ref=%s"):format(Main.GitRepoName, path, branch)
		local base64Error
		local apiError
		local success, body = pcall(oldgame.HttpGet, game, apiUrl)
		if success then
			local ok, payload = pcall(service.HttpService.JSONDecode, service.HttpService, body)
			if ok and type(payload) == "table" then
				base64Error = nil
				if payload.content and payload.encoding == "base64" then
					local decodeSuccess, decoded = decodeBase64(payload.content)
					if decodeSuccess then
						return true, decoded
					else
						base64Error = decoded
					end
				end

				if payload.download_url then
					local rawSuccess, rawBody = pcall(oldgame.HttpGet, game, payload.download_url)
					if rawSuccess then
						return true, rawBody
					else
						apiError = tostring(rawBody)
					end
				end

				if payload.message then
					apiError = tostring(payload.message)
				end
			else
				apiError = "Failed to decode GitHub metadata: "..tostring(payload)
			end
		else
			apiError = tostring(body)
		end

		local rawUrl = ("https://raw.githubusercontent.com/%s/%s/%s"):format(Main.GitRepoName, branch, path)
		local rawSuccess, rawBody = pcall(oldgame.HttpGet, game, rawUrl)
		if rawSuccess then
			return true, rawBody
		end

		return false, tostring(rawBody or apiError or base64Error or body or ("Unknown error fetching "..path))
	end

	Main.LoadModule = function(name)
		if Main.Elevated then -- If you don't have filesystem api then ur outta luck tbh
			local control
			local function loadControlFromSource(source, sourceName)
				if type(source) ~= "string" then
					return nil, sourceName .. " source is not a string"
				end
				local chunk, compileErr = loadstring(source)
				if type(chunk) ~= "function" then
					return nil, sourceName .. " compile failed: " .. tostring(compileErr)
				end
				local okRun, result = pcall(chunk)
				if not okRun then
					return nil, sourceName .. " runtime failed: " .. tostring(result)
				end
				if type(result) ~= "table" then
					return nil, sourceName .. " returned " .. type(result) .. " (expected table)"
				end
				return result
			end

			if EmbeddedModules then -- Offline Modules
				local embed = EmbeddedModules[name]
				if type(embed) == "function" then
					control = embed()
				end

				if not control then Main.Error("Missing Embedded Module: "..name) end
			elseif _G.DebugLoadModel then -- Load Debug Model File
				local model = Main.DebugModel
				if not model then model = oldgame:GetObjects(getsynasset("AfterModules.rbxm"))[1] end

				local loadedControl, loadErr = loadControlFromSource(model.Modules[name].Source, "Debug model module "..name)
				if loadedControl then
					control = loadedControl
				else
					Main.Error(loadErr)
				end
				print("Locally Loaded Module",name,control)
			else
				local modulePathLocal = (Main.GitModulesPath or "Modules").."/"..name..".lua"
				local cacheFolder = "DexPlusPlus/ModuleCache/"..tostring(Main.ModuleCacheVersion or "default")
				local cachePath = cacheFolder.."/"..name..".lua"
				local loadErrors = {}

				local function addLoadError(label, err)
					if err ~= nil and tostring(err) ~= "" then
						table.insert(loadErrors, tostring(label)..": "..tostring(err))
					end
				end

				local function tryFile(path, label)
					if not (env and env.readfile and type(path) == "string") then
						return false, nil, "readfile unavailable"
					end

					if type(env.isfile) == "function" then
						local okExists, exists = pcall(env.isfile, path)
						if not okExists or not exists then
							return false, nil, nil
						end
					end

					local okRead, source = pcall(env.readfile, path)
					if not okRead or type(source) ~= "string" then
						return true, nil, tostring(label).." read failed: "..tostring(source)
					end

					local loadedControl, loadErr = loadControlFromSource(source, tostring(label).." "..path)
					if loadedControl then
						return true, loadedControl, nil
					end

					return true, nil, loadErr
				end

				local localExists, localControl, localErr = tryFile(modulePathLocal, "Local module")

				if localControl then
					control = localControl
				elseif localExists then
					addLoadError("local", localErr)
				end

				if not control then
					local modulePath = modulePathLocal
					local okRemote, moduleStr = Main.FetchRepoFile(modulePath)
					if okRemote and type(moduleStr) == "string" then
						local loadedControl, loadErr = loadControlFromSource(moduleStr, "Remote module "..modulePath)
						if loadedControl then
							control = loadedControl
							if env and env.writefile then
								if env.makefolder then
									pcall(env.makefolder, "DexPlusPlus")
									pcall(env.makefolder, "DexPlusPlus/ModuleCache")
									pcall(env.makefolder, cacheFolder)
								end
								pcall(env.writefile, cachePath, moduleStr)
							end
						else
							addLoadError("remote", loadErr)
						end
					else
						addLoadError("remote", moduleStr)
					end
				end

				if not control then
					local cacheExists, cacheControl, cacheErr = tryFile(cachePath, "Cached module")
					if cacheControl then
						control = cacheControl
					elseif cacheExists then
						addLoadError("cache", cacheErr)
					end
				end

				if not control then
					local suffix = #loadErrors > 0 and (" | " .. table.concat(loadErrors, " | ")) or ""
					Main.Error("Failed to get external module data of "..name.." (no valid local, cached, or remote copy)" .. suffix)
				end
			end

			Main.AppControls[name] = control
			control.InitDeps(Main.GetInitDeps())

			local moduleData = control.Main()
			Apps[name] = moduleData
			return moduleData
		else
			local module = script:WaitForChild("Modules"):WaitForChild(name,2)
			if not module then Main.Error("CANNOT FIND MODULE "..name) end

			local control = require(module)
			Main.AppControls[name] = control
			control.InitDeps(Main.GetInitDeps())

			local moduleData = control.Main()
			Apps[name] = moduleData
			return moduleData
		end
	end

	Main.LoadPluginFile = function(pluginPath)
		if not (env and env.readfile) then
			return nil, "readfile is unavailable"
		end

		local isfileFn = (env and env.isfile) or isfile
		if type(isfileFn) ~= "function" then
			return nil, "isfile is unavailable"
		end

		local okIsFile, exists = pcall(isfileFn, pluginPath)
		if not okIsFile or not exists then
			return nil, "plugin file not found"
		end

		local chunkLoader
		if type(loadfile) == "function" then
			local okLoad, loader = pcall(loadfile, pluginPath)
			if okLoad and type(loader) == "function" then
				chunkLoader = loader
			end
		end

		if not chunkLoader then
			local okRead, src = pcall(env.readfile, pluginPath)
			if not okRead or type(src) ~= "string" then
				return nil, "failed to read plugin file"
			end
			local okChunk, loader = pcall(loadstring, src)
			if not okChunk or type(loader) ~= "function" then
				return nil, "failed to compile plugin file"
			end
			chunkLoader = loader
		end

		local okControl, control = pcall(chunkLoader)
		if not okControl or type(control) ~= "table" then
			return nil, "plugin entry returned invalid control object"
		end

		if type(control.InitDeps) == "function" then
			local okDeps, depsErr = pcall(control.InitDeps, Main.GetInitDeps())
			if not okDeps then
				return nil, "plugin InitDeps() failed: "..tostring(depsErr)
			end
		end
		if type(control.Main) ~= "function" then
			return nil, "plugin control missing Main()"
		end

		local okMain, moduleData = pcall(control.Main)
		if not okMain or type(moduleData) ~= "table" then
			return nil, "plugin Main() failed"
		end

		Apps[pluginPath] = moduleData
		Main.AppControls[pluginPath] = control
		moduleData.PluginData = control.PluginData or moduleData.PluginData

		return moduleData
	end

	Main.RefreshLoadedAppRefs = function()
		Explorer = Apps.Explorer
		Properties = Apps.Properties
		ScriptViewer = Apps.ScriptViewer
		Console = Apps.Console
		SaveInstance = Apps.SaveInstance
		ModelViewer = Apps.ModelViewer
		SettingsWindow = Apps.SettingsWindow
		ThemeManager = Apps.ThemeManager
		EnvExplorer = Apps.EnvExplorer
		DataExplorer = Apps.DataExplorer
		DebugExplorer = Apps.DebugExplorer
		Notebook = Apps.Notebook

		return {
			Explorer = Explorer,
			Properties = Properties,
			ScriptViewer = ScriptViewer,
			Console = Console,
			SaveInstance = SaveInstance,
			ModelViewer = ModelViewer,
			SettingsWindow = SettingsWindow,
			ThemeManager = ThemeManager,
			EnvExplorer = EnvExplorer,
			DataExplorer = DataExplorer,
			DebugExplorer = DebugExplorer,
			Notebook = Notebook,
		}
	end

	Main.SyncModuleDependencies = function()
		local appTable = Main.RefreshLoadedAppRefs()

		if Main.AppControls.Lib and type(Main.AppControls.Lib.InitAfterMain) == "function" then
			Main.AppControls.Lib.InitAfterMain(appTable)
		end

		for _, control in Main.AppControls do
			if control and type(control.InitAfterMain) == "function" then
				if control ~= Main.AppControls.Lib then
					control.InitAfterMain(appTable)
				end
			end
		end

		return appTable
	end

	Main.LoadModules = function(moduleList)
		local modulesToLoad = moduleList or Main.ModuleList
		for _, v in modulesToLoad do
			local s,e = pcall(Main.LoadModule,v)
			if not s then
				Main.Error("FAILED LOADING " .. v .. " CAUSE " .. e)
			end
		end

		return Main.SyncModuleDependencies()
	end

	Main.InitAppModule = function(moduleData, moduleName)
		if type(moduleData) ~= "table" or moduleData.__DexInitDone then
			return moduleData
		end

		if type(moduleData.Init) == "function" then
			local okInit, initErr = pcall(moduleData.Init)
			if not okInit then
				Main.Error("FAILED INITIALIZING " .. tostring(moduleName or "MODULE") .. " CAUSE " .. tostring(initErr))
			end
		end

		moduleData.__DexInitDone = true
		return moduleData
	end

	local function patchContextMenu(context)
		if context and type(context.AddRegistered) == "function" and not context.__dexSafeAddRegistered then
			local originalAdd = context.AddRegistered
			context.AddRegistered = function(self,name,disabled)
				if not name then
					return
				end
				if not (self.Registered and self.Registered[name]) then
					warn("[Dex] Context action '"..tostring(name).."' is not registered")
					return
				end
				return originalAdd(self,name,disabled)
			end
			context.__dexSafeAddRegistered = true
		end
	end

	Main.ApplyPatches = function()
		if Lib and Lib.ContextMenu and type(Lib.ContextMenu.new) == "function" and not Main.ContextMenuPatched then
			Main.ContextMenuPatched = true
			local originalNew = Lib.ContextMenu.new
			Lib.ContextMenu.new = function(...)
				local context = originalNew(...)
				patchContextMenu(context)
				return context
			end
		end

		if Explorer and Explorer.RightClickContext then
			patchContextMenu(Explorer.RightClickContext)
		end
	end

	Main.EnsureAllIcons = function(forceRefresh)
		if not (env and env.writefile and env.makefolder and ((env.getcustomasset) or getcustomasset or getsynasset)) then
			return false
		end
		local force = forceRefresh == true
		local deleteFn = (env and env.delfile) or delfile
		local processed = {}
		pcall(env.makefolder,"DexPlusPlus")
		pcall(env.makefolder,"DexPlusPlus/assets")
		Main.IconFoldersReady = true
		if force then
			if table.clear then
				table.clear(Main.ResolvedAssetCache)
			else
				Main.ResolvedAssetCache = {}
			end
		else
			Main.ResolvedAssetCache = Main.ResolvedAssetCache or {}
		end
		for _, fileName in Main.IconOverrides do
			if processed[fileName] then
				continue
			end
			processed[fileName] = true

			local path = "DexPlusPlus/assets/"..fileName
			local needDownload = force

			if force and env.isfile and deleteFn then
				local okExists, exists = pcall(env.isfile, path)
				if okExists and exists then
					pcall(deleteFn, path)
				end
				Main.IconFileReady[path] = nil
			end

			if not needDownload and env.isfile then
				local ok, exists = pcall(env.isfile, path)
				local fileExists = ok and exists
				if fileExists then
					Main.IconFileReady[path] = true
				end
				needDownload = not fileExists
			end

			if needDownload then
				local url = Main.IconSourceBaseUrl .. fileName
				local ok, data = pcall(oldgame.HttpGet, game, url)
				if ok and type(data) == "string" then
					local okWrite = pcall(env.writefile, path, data)
					if okWrite then
						Main.IconFileReady[path] = true
					end
				end
			end
		end
		return true
	end

	Main.InitEnv = function()
		setmetatable(env,{__newindex = function(self,name,func)
			if not func then Main.MissingEnv[#Main.MissingEnv+1] = name return end
			rawset(self,name,func)
		end})

		env.isonmobile = __lt.cs("UserInputService", cloneref).TouchEnabled

		env.loadstring = (pcall(loadstring,"local a = 1") and loadstring) or (__lt.cs("RunService", cloneref):IsStudio() and script.Modules:FindFirstChild("Loadstring") and require(script.Modules:FindFirstChild("Loadstring")))

		-- file
		env.isfile = isfile
		env.isfolder = isfolder
		env.readfile = readfile
		env.writefile = writefile
		env.appendfile = appendfile
		env.makefolder = makefolder
		env.delfile = delfile
		env.delfolder = delfolder
		env.listfiles = listfiles
		env.loadfile = loadfile
		env.native_saveinstance = saveinstance
		env.saveinstance = (function()
			if __lt.cs("RunService", cloneref):IsStudio() then return function() error("Cannot run in Roblox Studio!") end end

			local cacheHost = (getgenv and getgenv()) or _G
			local cacheKey = "__dex_ussi_saveinstance_v3"
			local cached = type(cacheHost) == "table" and rawget(cacheHost, cacheKey)
			if type(cached) == "function" then
				return cached
			end

			local Params = {
				RepoURL = "https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/main/",
				SSI = "saveinstance",
			}
			local source = oldgame:HttpGet(Params.RepoURL .. Params.SSI .. ".luau", true)
			source = source:gsub("StatusGui%.Parent = global_container%.gethui%(%)", [[
			local cacheHost = (getgenv and getgenv()) or _G
			local uiProtector = type(cacheHost) == "table" and rawget(cacheHost, "__lt_ui_protector") or nil
			local protectedOk = false
			if type(uiProtector) == "table" and type(uiProtector.protectUI) == "function" then
				local okProtected, protected = pcall(uiProtector.protectUI, StatusGui)
				protectedOk = okProtected and protected ~= nil
			end
			if not protectedOk then
				local huiOk, hui = pcall(global_container.gethui)
				if huiOk and typeof(hui) == "Instance" then
					StatusGui.Parent = hui
				end
			end
			]], 1)
			local synsaveinstance = loadstring(source, Params.SSI)()

			local function applySavedSaveInstanceOptions(finalOptions)
				local saveState = Settings and Settings.SaveInstance
				if type(saveState) ~= "table" then
					return finalOptions
				end

				local savedOptions = saveState.Options
				if type(savedOptions) == "table" then
					for key, value in savedOptions do
						if finalOptions[key] == nil then
							if type(value) == "table" then
								local copy = {}
								for subKey, subValue in value do
									copy[subKey] = subValue
								end
								finalOptions[key] = copy
							else
								finalOptions[key] = value
							end
						end
					end
				end

				local extraOptionsJson = saveState.ExtraOptionsJson
				if type(extraOptionsJson) == "string" and extraOptionsJson:match("%S") then
					local okDecode, decoded = pcall(service.HttpService.JSONDecode, service.HttpService, extraOptionsJson)
					if okDecode and type(decoded) == "table" then
						for key, value in decoded do
							if finalOptions[key] == nil then
								finalOptions[key] = value
							end
						end
					end
				end

				return finalOptions
			end

			local function mergeOptions(target, sourceOptions)
				if type(sourceOptions) ~= "table" then
					return
				end

				for key, value in sourceOptions do
					target[key] = value
				end
			end

			local function getLocalHumanoid()
				local ok, player = pcall(function()
					return __lt.cs("Players", cloneref).LocalPlayer
				end)
				local character = ok and player and player.Character
				if character then
					return character:FindFirstChildOfClass("Humanoid")
				end
			end

			local function captureClientState()
				local state = {}

				pcall(function()
					local camera = workspace.CurrentCamera
					state.Camera = camera
					if camera then
						state.CameraType = camera.CameraType
						state.CameraSubject = camera.CameraSubject
					end
				end)

				pcall(function()
					local userInput = __lt.cs("UserInputService", cloneref)
					state.UserInput = userInput
					state.MouseBehavior = userInput.MouseBehavior
					state.MouseIconEnabled = userInput.MouseIconEnabled
				end)

				return state
			end

			local function restoreClientState(state)
				if type(state) ~= "table" then
					return
				end

				pcall(function()
					local userInput = state.UserInput or __lt.cs("UserInputService", cloneref)
					if state.MouseBehavior then
						userInput.MouseBehavior = state.MouseBehavior
					end
					if state.MouseIconEnabled ~= nil then
						userInput.MouseIconEnabled = state.MouseIconEnabled
					end
				end)

				pcall(function()
					local runService = __lt.cs("RunService", cloneref)
					if runService and runService.Set3dRenderingEnabled then
						runService:Set3dRenderingEnabled(true)
					end
				end)

				pcall(function()
					local camera = state.Camera
					if not camera or camera.Parent == nil then
						camera = workspace.CurrentCamera
					end
					if not camera then
						return
					end

					local subject = state.CameraSubject
					if not subject or subject.Parent == nil then
						subject = getLocalHumanoid()
					end

					if subject then
						camera.CameraSubject = subject
					end

					if state.CameraType then
						camera.CameraType = state.CameraType
					elseif subject then
						camera.CameraType = Enum.CameraType.Custom
					end
				end)
			end

			local function wrappedsaveinstance(obj, filepath, options)
				local finalOptions = {}
				applySavedSaveInstanceOptions(finalOptions)

				if type(obj) == "table" and filepath == nil and options == nil then
					options = obj
					obj = nil
				elseif type(filepath) == "table" and options == nil then
					options = filepath
					filepath = options.FilePath or options.FileName
				end

				mergeOptions(finalOptions, options)

				if filepath ~= nil then
					finalOptions.FilePath = filepath
				end

				if typeof(obj) == "Instance" then
					finalOptions.Object = obj
				end

				local clientState = captureClientState()
				local ok, result = pcall(synsaveinstance, finalOptions)
				restoreClientState(clientState)
				task.defer(restoreClientState, clientState)
				task.delay(1, restoreClientState, clientState)

				if not ok then
					error(result, 0)
				end

				return result
			end

			if type(cacheHost) == "table" then
				rawset(cacheHost, cacheKey, wrappedsaveinstance)
				rawset(cacheHost, "__dex_ussi_saveinstance", wrappedsaveinstance)
				rawset(cacheHost, "saveinstance", wrappedsaveinstance)
			end
			return wrappedsaveinstance
		end)()

		env.parsefile = function(name)
			return tostring(name):gsub("[*\\?:<>|]+", ""):sub(1, 175)
		end

		-- debug
		env.getupvalues = debug.getupvalues or getupvalues or getupvals
		env.setupvalues = debug.setupvalues or setupvalues or setupvals
		env.setupvalue = debug.setupvalue or setupvalue or setupval
		env.getconstants = debug.getconstants or getconstants or getconsts
		env.setconstants = debug.setconstants or setconstants or setconsts
		env.setconstant = debug.setconstant or setconstant or setconst
		env.getprotos = debug.getprotos or getprotos
		env.getproto = debug.getproto or getproto
		env.getinfo = (debug and (debug.getinfo or debug.info)) or getinfo
		env.islclosure = islclosure or is_l_closure
		env.iscclosure = iscclosure or is_c_closure
		env.isourclosure = isourclosure
		env.checkcaller = checkcaller
		env.getreg = getreg
		env.getgc = getgc
		env.getgenv = getgenv
		env.getrenv = getrenv
		env.getsenv = getsenv
		env.getscripts = getscripts
		env.getconnections = getconnections
		env.getfunctionhash = getfunctionhash
		env.restorefunction = restorefunction

		-- hooks
		env.ResolveExecutorFunction = function(name)
			local value
			if type(getgenv) == "function" then
				local ok, genv = pcall(getgenv)
				if ok and type(genv) == "table" then
					value = rawget(genv, name)
					if value ~= nil then return value end
				end
			end
			if type(getrenv) == "function" then
				local ok, renv = pcall(getrenv)
				if ok and type(renv) == "table" then
					value = rawget(renv, name)
					if value ~= nil then return value end
				end
			end
			return rawget(_G, name)
		end

		env.GetHookFunction = function()
			local fn = env.ResolveExecutorFunction("hookfunction")
			return type(fn) == "function" and fn or nil
		end

		env.GetHookMetamethod = function()
			local fn = env.ResolveExecutorFunction("hookmetamethod")
			return type(fn) == "function" and fn or nil
		end

		env.HasHookFunction = function()
			return env.GetHookFunction() ~= nil
		end

		env.HasHookMetamethod = function()
			return env.GetHookMetamethod() ~= nil
		end

		env.hookfunction = function(...)
			local fn = env.GetHookFunction()
			if not fn then return nil end
			return fn(...)
		end

		env.hookmetamethod = function(...)
			local fn = env.GetHookMetamethod()
			if not fn then return nil end
			return fn(...)
		end

		-- other
		env.getscriptbytecode = getscriptbytecode
		env.setfflag = setfflag
		local nativeProtectGui = protect_gui or (syn and syn.protect_gui)
		env.protectgui = function(gui, options)
			local protected = __NAProtectUI(gui, options)
			if protected then
				return protected
			end
			if type(nativeProtectGui) == "function" then
				local ok, result = pcall(nativeProtectGui, gui)
				if ok then
					return result or gui
				end
			end
			return nil
		end
		env.gethui = gethui
		env.setclipboard = setclipboard
		env.getnilinstances = getnilinstances or get_nil_instances
		env.getloadedmodules = getloadedmodules

		env.isViableDecompileScript = function(obj)
			if obj:IsA("ModuleScript") then
				return true
			elseif obj:IsA("LocalScript") and (obj.RunContext == Enum.RunContext.Client or obj.RunContext == Enum.RunContext.Legacy) then
				return true
			elseif obj:IsA("Script") and obj.RunContext == Enum.RunContext.Client then
				return true
			end
			return false
		end
		env.request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

		local nativeDecompile = (type(decompile) == "function" and decompile) or nil
		local nativeDecompileScript = (type(decompile_script) == "function" and decompile_script) or nil
		local nativeDecompileScriptAlt = (type(decompilescript) == "function" and decompilescript) or nil

		local function getNativeDecompiler()
			if type(nativeDecompile) == "function" and nativeDecompile ~= env.decompile then
				return nativeDecompile
			end
			if type(nativeDecompileScript) == "function" and nativeDecompileScript ~= env.decompile then
				return nativeDecompileScript
			end
			if type(nativeDecompileScriptAlt) == "function" and nativeDecompileScriptAlt ~= env.decompile then
				return nativeDecompileScriptAlt
			end
			if type(decompile) == "function" and decompile ~= env.decompile then
				return decompile
			end
			if type(decompile_script) == "function" and decompile_script ~= env.decompile then
				return decompile_script
			end
			if type(decompilescript) == "function" and decompilescript ~= env.decompile then
				return decompilescript
			end
			return nil
		end

		env.isdecompile = function()
			return type(getNativeDecompiler()) == "function" or type(getscriptbytecode) == "function"
		end

		env.isdecompilefallback = function()
			return type(getNativeDecompiler()) ~= "function" and type(getscriptbytecode) == "function"
		end

		local fallbackDecompile = (function()
			-- by lovrewe
			if not env.getscriptbytecode then --[[warn('Konstant decompiler is not supported. "getscriptbytecode" is missing.')]] return end

			local API = "http://api.plusgiant5.com"

			local last_call = 0

			local request = env.request
			if type(request) ~= "function" then
				return
			end

			local function call(konstantType, scriptPath)
				local success, bytecode = pcall(env.getscriptbytecode, scriptPath)

				if (not success) then
					return nil, "Failed to get script bytecode: "..tostring(bytecode)
				end
				if type(bytecode) ~= "string" or bytecode == "" then
					return nil, "Script bytecode is empty."
				end

				local time_elapsed = os.clock() - last_call
				if time_elapsed <= .5 then
					task.wait(.5 - time_elapsed)
				end

				local httpResult = request({
					Url = API .. konstantType,
					Body = bytecode,
					Method = "POST",
					Headers = {
						["Content-Type"] = "text/plain"
					}
				})

				last_call = os.clock()

				if type(httpResult) ~= "table" then
					return nil, "Invalid response from Konstant API request."
				end
				if (httpResult.StatusCode ~= 200) then
					return nil, "Konstant API error ("..tostring(httpResult.StatusCode).."): "..tostring(httpResult.Body)
				end
				if type(httpResult.Body) ~= "string" or httpResult.Body == "" then
					return nil, "Konstant API returned an empty response body."
				end
				return httpResult.Body
			end

			local function decompileFallback(scriptPath)
				return call("/konstant/decompile", scriptPath)
			end

			return decompileFallback
		end)()

		local luaExpertDecompile = (function()
			if not env.getscriptbytecode then
				return
			end
			local request = env.request
			if type(request) ~= "function" then
				return
			end

			local last_call = 0

			local function base64Encode(data)
				local encoder = env.base64_encode or base64_encode
				if type(encoder) == "function" then
					local ok, encoded = pcall(encoder, data)
					if ok and type(encoded) == "string" then
						return encoded
					end
				end

				local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
				return ((data:gsub(".", function(char)
					local bits, byte = "", char:byte()
					for i = 8, 1, -1 do
						bits = bits .. (byte % 2 ^ i - byte % 2 ^ (i - 1) > 0 and "1" or "0")
					end
					return bits
				end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(bits)
					if #bits < 6 then
						return ""
					end
					local index = 0
					for i = 1, 6 do
						index = index + (bits:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
					end
					return alphabet:sub(index + 1, index + 1)
				end) .. ({ "", "==", "=" })[#data % 3 + 1])
			end

			return function(scriptInstance)
				local okBytecode, bytecode = pcall(env.getscriptbytecode, scriptInstance)
				if not okBytecode then
					return nil, "lua.expert fallback failed to get bytecode: "..tostring(bytecode)
				end
				if type(bytecode) ~= "string" or bytecode == "" then
					return nil, "lua.expert fallback bytecode is empty."
				end

				local time_elapsed = os.clock() - last_call
				if time_elapsed < .6 then
					task.wait(.6 - time_elapsed)
				end

				local okPayload, payload = pcall(service.HttpService.JSONEncode, service.HttpService, {
					script = base64Encode(bytecode)
				})
				if not okPayload then
					return nil, "lua.expert fallback failed to encode request body: "..tostring(payload)
				end

				local response = request({
					Url = "https://api.lua.expert/decompile",
					Method = "POST",
					Headers = {
						["content-type"] = "application/json"
					},
					Body = payload
				})

				last_call = os.clock()

				if type(response) ~= "table" then
					return nil, "lua.expert fallback returned an invalid HTTP response."
				end
				if response.StatusCode and response.StatusCode ~= 200 then
					return nil, "lua.expert fallback HTTP error ("..tostring(response.StatusCode).."): "..tostring(response.Body)
				end
				if type(response.Body) ~= "string" or response.Body == "" then
					return nil, "lua.expert fallback returned an empty response body."
				end
				return response.Body
			end
		end)()

		env.decompile = function(...)
			local builtInDecompiler = getNativeDecompiler()
			local fallbackMode = (Settings and Settings.Decompiler and Settings.Decompiler.DecompilerFallback) or "lua.expert"
			local preferFallback = (Settings and Settings.Decompiler and Settings.Decompiler.PreferDecompilerFallback) == true
			local attempts = {}
			local included = {}
			local lastError

			local function queueAttempt(name, fn)
				if type(fn) ~= "function" or included[name] then
					return
				end
				included[name] = true
				table.insert(attempts, {Name = name, Fn = fn})
			end

			local function queueFallback(mode)
				if mode == "lua.expert" then
					queueAttempt("lua.expert", luaExpertDecompile)
				elseif mode == "Konstant" then
					queueAttempt("Konstant", fallbackDecompile)
				end
			end

			if preferFallback then
				queueFallback(fallbackMode)
				queueAttempt("Built-in", builtInDecompiler)
			else
				queueAttempt("Built-in", builtInDecompiler)
				queueFallback(fallbackMode)
			end

			for _, mode in {"lua.expert", "Konstant"} do
				if mode ~= fallbackMode then
					queueFallback(mode)
				end
			end

			if preferFallback then
				queueFallback(fallbackMode)
			else
				queueAttempt("Built-in", builtInDecompiler)
			end

			for _, attempt in attempts do
				local ok, result, err = pcall(attempt.Fn, ...)
				if ok and result ~= nil and result ~= false then
					return result
				end
				local reason = ok and (err or "No output returned.") or result
				lastError = "["..attempt.Name.."] "..tostring(reason)
			end

			return nil, (lastError or "No compatible decompiler is available.")
		end

		if ggv then
			pcall(function()
				local genv = ggv()
				if type(genv.decompile) ~= "function" then
					genv.decompile = env.decompile
				end
			end)
		end

		if identifyexecutor then
			Main.Executor = identifyexecutor()
		end

		env.getcustomasset = getcustomasset or getsynasset or env.getcustomasset

		local okGuiHolder, guiHolder = pcall(gethui)
		Main.GuiHolder = (okGuiHolder and typeof(guiHolder) == "Instance" and guiHolder) or (Main.Elevated and service.CoreGui or plr:FindFirstChildOfClass("PlayerGui"))

		setmetatable(env,nil)
	end

	local function serialize(val)
		if typeof(val) == "Color3" then
			local serializedColor = {}
			serializedColor.R = val.R
			serializedColor.G = val.G
			serializedColor.B = val.B
			return serializedColor
		elseif typeof(val) == "Vector3" then
			return {
				__type = "Vector3",
				X = val.X,
				Y = val.Y,
				Z = val.Z
			}
		else
			return val
		end
	end

	local function deserialize(val)
		if typeof(val) == "table" then
			if val.__type == "Vector3" then
				return Vector3.new(val.X or 0, val.Y or 0, val.Z or 0)
			elseif val.R and val.G and val.B then
				return Color3.new(val.R, val.G, val.B)
			else
				return val
			end
		else
			return val
		end
	end

	Main.ExportSettings = function()
		local rawData = Settings or DefaultSettings

		local function recur(tbl)
			local newTbl = {}
			for i, v in tbl do
				if typeof(v) == "table" then
					newTbl[i] = recur(v)
				else
					newTbl[i] = serialize(v)
				end
			end
			return newTbl
		end

		-- serialize color3 sebelum encode
		local serializedData = recur(rawData)

		local s, json = pcall(service.HttpService.JSONEncode, service.HttpService, serializedData)
		if s and json then
			return json
		end
		if not s then
			warn("[Dex] Failed to encode settings JSON: "..tostring(json))
		end
	end

	Main.SaveUserSettings = function()
		if not (env and env.writefile) then return end
		local ok, encoded = pcall(service.HttpService.JSONEncode, service.HttpService, Main.UserSettings)
		if ok and encoded then
			pcall(env.writefile, Main.UserSettingsFile, encoded)
		end
	end

	Main.LoadUserSettings = function()
		local fileData
		if env and env.readfile then
			local s, data = pcall(env.readfile, Main.UserSettingsFile)
			if s and data and #data > 0 then
				fileData = data
			end
		end
		if fileData then
			local ok, decoded = pcall(service.HttpService.JSONDecode, service.HttpService, fileData)
			if ok and type(decoded) == "table" then
				for k,v in decoded do
					Main.UserSettings[k] = v
				end
			end
		end
		if Main.ValidateUserSettings then
			Main.ValidateUserSettings()
		end
	end

	Main.ValidateUserSettings = function()
		Main.UserSettings = Main.UserSettings or {}
		local userSettings = Main.UserSettings
		local filters = userSettings.ConsoleFilters
		if type(filters) ~= "table" then
			filters = {}
			userSettings.ConsoleFilters = filters
		end

		local filterDefaults = {
			Output = true,
			Info = true,
			Warn = true,
			Error = true,
			Listen = true,
		}

		for key, defaultValue in filterDefaults do
			if type(filters[key]) ~= "boolean" then
				filters[key] = defaultValue
			end
		end

		if type(userSettings.ConsoleCtrlScroll) ~= "boolean" then
			userSettings.ConsoleCtrlScroll = false
		end
		if type(userSettings.ConsoleAutoScroll) ~= "boolean" then
			userSettings.ConsoleAutoScroll = false
		end

		local outputLimit = math.floor(tonumber(userSettings.ConsoleOutputLimit) or 500)
		userSettings.ConsoleOutputLimit = math.clamp(outputLimit, 10, 5000)

		local textSize = math.floor(tonumber(userSettings.ConsoleTextSize) or 15)
		userSettings.ConsoleTextSize = math.clamp(textSize, 1, 64)

		if type(userSettings.RememberLastSettingsTab) ~= "boolean" then
			userSettings.RememberLastSettingsTab = true
		end
		if type(userSettings.SettingsLastTab) ~= "string" or userSettings.SettingsLastTab == "" then
			userSettings.SettingsLastTab = "UI"
		end
	end

	Main.SaveThemeSettings = function()
		if not (env and env.writefile) then return end
		local function recur(tbl)
			local newTbl = {}
			for i, v in tbl do
				if typeof(v) == "table" then
					newTbl[i] = recur(v)
				else
					newTbl[i] = serialize(v)
				end
			end
			return newTbl
		end

		local themePayload = recur({
			Theme = Settings and Settings.Theme or {}
		})
		local ok, encoded = pcall(service.HttpService.JSONEncode, service.HttpService, themePayload)
		if ok and encoded then
			pcall(env.writefile, Main.ThemeFile, encoded)
		end
	end

	Main.LoadThemeSettings = function()
		local fileData
		if env and env.readfile then
			local s, data = pcall(env.readfile, Main.ThemeFile)
			if s and data and #data > 0 then
				fileData = data
			end
		end
		if fileData then
			local ok, decoded = pcall(service.HttpService.JSONDecode, service.HttpService, fileData)
			if ok and type(decoded) == "table" then
				local function recur(tbl)
					local newTbl = {}
					for k,v in tbl do
						if typeof(v) == "table" and v.R and v.G and v.B then
							newTbl[k] = deserialize(v)
						elseif typeof(v) == "table" then
							newTbl[k] = recur(v)
						else
							newTbl[k] = deserialize(v)
						end
					end
					return newTbl
				end

				if decoded.Theme and type(decoded.Theme) == "table" then
					Settings.Theme = recur(decoded.Theme)
				end
			end
		end
	end

	Main.SaveCurrentSettings = function()
		if not (env and env.writefile) then
			return false
		end
		local ok, encoded = pcall(Main.ExportSettings)
		if ok and encoded then
			local wrote = pcall(env.writefile, Main.SettingsFile, encoded)
			if not wrote then
				warn("[Dex] Failed writing settings file: "..tostring(Main.SettingsFile))
			end
			return wrote
		elseif not ok then
			warn("[Dex] SaveCurrentSettings failed: "..tostring(encoded))
		else
			warn("[Dex] SaveCurrentSettings failed: encoded settings were empty")
		end
		return false
	end


	--warn(Main.ExportSettings())

	Main.ValidateSettings = function()
		local explorer = Settings.Explorer
		if type(explorer) ~= "table" then
			explorer = {}
			Settings.Explorer = explorer
		end

		local defaultExplorer = DefaultSettings and DefaultSettings.Explorer or {}
		local defaultOffset = defaultExplorer.TeleportToOffset or Vector3.new()

		if typeof(explorer.TeleportToOffset) ~= "Vector3" then
			explorer.TeleportToOffset = defaultOffset
		end
		if type(explorer.Sorting) ~= "boolean" then
			explorer.Sorting = defaultExplorer.Sorting
		end
		if type(explorer.ClickToRename) ~= "boolean" then
			explorer.ClickToRename = defaultExplorer.ClickToRename
		end
		if type(explorer.AutoUpdateSearch) ~= "boolean" then
			explorer.AutoUpdateSearch = defaultExplorer.AutoUpdateSearch
		end
		if type(explorer.KeyboardShortcuts) ~= "boolean" then
			explorer.KeyboardShortcuts = defaultExplorer.KeyboardShortcuts
		end
		if type(explorer.PartSelectionBox) ~= "boolean" then
			explorer.PartSelectionBox = defaultExplorer.PartSelectionBox
		end
		if type(explorer.GuiSelectionBox) ~= "boolean" then
			explorer.GuiSelectionBox = defaultExplorer.GuiSelectionBox
		end
		if explorer.GuiSelectorScope ~= "PlayerGui" and explorer.GuiSelectorScope ~= "CoreGui" and explorer.GuiSelectorScope ~= "gethui" and explorer.GuiSelectorScope ~= "All" then
			explorer.GuiSelectorScope = defaultExplorer.GuiSelectorScope or "PlayerGui"
		end
		if type(explorer.CopyPathUseGetChildren) ~= "boolean" then
			explorer.CopyPathUseGetChildren = defaultExplorer.CopyPathUseGetChildren
		end
		if type(explorer.UseNameWidth) ~= "boolean" then
			explorer.UseNameWidth = defaultExplorer.UseNameWidth
		end
		local maxSelectionBoxes = math.floor(tonumber(explorer.MaxSelectionBoxes) or defaultExplorer.MaxSelectionBoxes or 1000)
		explorer.MaxSelectionBoxes = math.clamp(maxSelectionBoxes, 0, 5000)
		local autoUpdateMode = math.floor(tonumber(explorer.AutoUpdateMode) or defaultExplorer.AutoUpdateMode or 0)
		explorer.AutoUpdateMode = math.clamp(autoUpdateMode, 0, 3)

		if type(Settings.Properties) ~= "table" then
			Settings.Properties = {}
		end
		local properties = Settings.Properties
		local defaultProperties = DefaultSettings and DefaultSettings.Properties or {}
		if type(properties.ShowDeprecated) ~= "boolean" then
			properties.ShowDeprecated = defaultProperties.ShowDeprecated
		end
		if type(properties.ShowHidden) ~= "boolean" then
			properties.ShowHidden = defaultProperties.ShowHidden
		end
		if type(properties.ClearOnFocus) ~= "boolean" then
			properties.ClearOnFocus = defaultProperties.ClearOnFocus
		end
		if type(properties.LoadstringInput) ~= "boolean" then
			properties.LoadstringInput = defaultProperties.LoadstringInput
		end
		if type(properties.ShowAttributes) ~= "boolean" then
			properties.ShowAttributes = defaultProperties.ShowAttributes
		end
		local maxConflict = math.floor(tonumber(properties.MaxConflictCheck) or defaultProperties.MaxConflictCheck or 50)
		properties.MaxConflictCheck = math.clamp(maxConflict, 1, 5000)
		local maxAttrs = math.floor(tonumber(properties.MaxAttributes) or defaultProperties.MaxAttributes or 50)
		properties.MaxAttributes = math.clamp(maxAttrs, 0, 1000)
		local roundNum = math.floor(tonumber(properties.NumberRounding) or defaultProperties.NumberRounding or 3)
		properties.NumberRounding = math.clamp(roundNum, 0, 10)
		local scaleType = tonumber(properties.ScaleType)
		if scaleType ~= 0 and scaleType ~= 1 then
			scaleType = defaultProperties.ScaleType
		end
		properties.ScaleType = (scaleType == 1) and 1 or 0

		if type(Settings.Window) ~= "table" then
			Settings.Window = {}
		end
		if type(Settings.Window.TitleOnMiddle) ~= "boolean" then
			Settings.Window.TitleOnMiddle = DefaultSettings.Window.TitleOnMiddle
		end
		local transp = tonumber(Settings.Window.Transparency)
		if transp == nil then
			transp = DefaultSettings.Window.Transparency
		end
		Settings.Window.Transparency = math.clamp(transp, 0, 1)
		local fontName = Settings.Window.Font
		if fontName ~= "SourceSans" and fontName ~= "Gotham" and fontName ~= "GothamMedium" and fontName ~= "GothamSemibold" and fontName ~= "GothamBold" and fontName ~= "RobotoMono" and fontName ~= "Code" and fontName ~= "Ubuntu" then
			Settings.Window.Font = DefaultSettings.Window.Font or "SourceSans"
		end
		local settingsWidth = math.floor(tonumber(Settings.Window.SettingsWidth) or DefaultSettings.Window.SettingsWidth or 250)
		Settings.Window.SettingsWidth = math.clamp(settingsWidth, 220, 550)
		local settingsHeight = math.floor(tonumber(Settings.Window.SettingsHeight) or DefaultSettings.Window.SettingsHeight or 375)
		Settings.Window.SettingsHeight = math.clamp(settingsHeight, 280, 700)

		if type(Settings.Startup) ~= "table" then
			Settings.Startup = {}
		end
		local startup = Settings.Startup
		local defaultStartup = DefaultSettings and DefaultSettings.Startup or {}
		local explorerSide = startup.ExplorerSide
		if explorerSide ~= "Left" and explorerSide ~= "Right" then
			explorerSide = defaultStartup.ExplorerSide
		end
		startup.ExplorerSide = (explorerSide == "Left") and "Left" or "Right"
		local propertiesSide = startup.PropertiesSide
		if propertiesSide ~= "Left" and propertiesSide ~= "Right" then
			propertiesSide = defaultStartup.PropertiesSide
		end
		startup.PropertiesSide = (propertiesSide == "Left") and "Left" or "Right"
		if type(startup.OpenExplorer) ~= "boolean" then
			startup.OpenExplorer = defaultStartup.OpenExplorer
		end
		if type(startup.OpenProperties) ~= "boolean" then
			startup.OpenProperties = defaultStartup.OpenProperties
		end

		if type(Settings.ScriptViewer) ~= "table" then
			Settings.ScriptViewer = {}
		end
		if type(Settings.ScriptViewer.ShowMoreInfo) ~= "boolean" then
			Settings.ScriptViewer.ShowMoreInfo = DefaultSettings.ScriptViewer.ShowMoreInfo
		end

		if type(Settings.Files) ~= "table" then
			Settings.Files = {}
		end
		local files = Settings.Files
		local defaultFiles = DefaultSettings and DefaultSettings.Files or {}
		if type(files.SaveInstanceNameFormat) ~= "string" or files.SaveInstanceNameFormat == "" then
			files.SaveInstanceNameFormat = defaultFiles.SaveInstanceNameFormat or "{placeName}_{timestamp}"
		end
		if type(files.ObjectSaveNameFormat) ~= "string" or files.ObjectSaveNameFormat == "" then
			files.ObjectSaveNameFormat = defaultFiles.ObjectSaveNameFormat or "{className}_{name}_{timestamp}"
		end

		if type(Settings.RemoteBlockWriteAttribute) ~= "boolean" then
			Settings.RemoteBlockWriteAttribute = DefaultSettings.RemoteBlockWriteAttribute
		end

		if type(Settings.Decompiler) ~= "table" then
			Settings.Decompiler = {}
		end
		local fallbackMode = Settings.Decompiler.DecompilerFallback
		if fallbackMode ~= "lua.expert" and fallbackMode ~= "Konstant" then
			Settings.Decompiler.DecompilerFallback = DefaultSettings.Decompiler.DecompilerFallback
		end
		if type(Settings.Decompiler.PreferDecompilerFallback) ~= "boolean" then
			Settings.Decompiler.PreferDecompilerFallback = DefaultSettings.Decompiler.PreferDecompilerFallback
		end
		if Settings.ClassIcon ~= "NewDark" and Settings.ClassIcon ~= "Vanilla3" and Settings.ClassIcon ~= "Old" then
			Settings.ClassIcon = DefaultSettings.ClassIcon
		end
	end

	Main.LoadSettings = function()
		local s, data = pcall(env.readfile or error, Main.SettingsFile)
		if s and data and data ~= "" then
			local s, decoded = pcall(service.HttpService.JSONDecode, service.HttpService, data)
			if s and decoded then

				local function recur(tbl)
					local newTbl = {}
					for i, v in tbl do
						if typeof(v) == "table" then
							newTbl[i] = deserialize(recur(v))
						else
							newTbl[i] = deserialize(v)
						end
					end
					return newTbl
				end

				local deserializedData = recur(decoded)
				for k, v in deserializedData do
					Settings[k] = v
				end
				Main.ValidateSettings()

			else
				warn("failed to decode settings json")
			end
		else
			Main.ResetSettings()
		end
	end

	Main.ApplySettingsMigrations = function()
		Main.UserSettings = Main.UserSettings or {}
		local migrationKey = "ExplorerAutoUpdateSearchDefaultOff20260627"
		if Main.UserSettings[migrationKey] then
			return
		end

		if type(Settings.Explorer) ~= "table" then
			Settings.Explorer = {}
		end
		Settings.Explorer.AutoUpdateSearch = false
		Main.UserSettings[migrationKey] = true
		if Main.SaveUserSettings then Main.SaveUserSettings() end
		if Main.SaveCurrentSettings then Main.SaveCurrentSettings() end
	end




	Main.ResetSettings = function()
		for k in Settings do Settings[k] = nil end
		local function copyInto(dest, src)
			for key, val in src do
				if type(val) == "table" then
					dest[key] = copyInto({}, val)
				else
					dest[key] = deepCopy(val)
				end
			end
			return dest
		end
		copyInto(Settings, DefaultSettingsOrig)
		Main.ValidateSettings()
		if Lib and Lib.RefreshTheme then
			pcall(Lib.RefreshTheme)
		end
	end

	Main.FetchAPI = function(callbackiflong, callbackiftoolong, XD)
		local downloaded = false
		local api,rawAPI
		local timeoutSeconds = 30
		local function skipAPI(reason)
			downloaded = true
			warn("[Dex] "..reason)
			return {
				Classes = {},
				Enums = {},
				CategoryOrder = {},
				GetMember = function()
					return {}
				end,
				Skipped = true,
				Reason = reason
			}
		end
		if Main.Elevated then
			if Main.LocalDepsUpToDate() then
				local localAPI = Lib.ReadFile("DexPlusPlus/rbx_api.dat")
				if localAPI then 
					rawAPI = localAPI
				else
					Main.DepsVersionData[1] = ""
				end
			end
			task.spawn(function()
				task.wait(10)
				if not downloaded and callbackiflong then callbackiflong() end

				task.wait(20) -- 30
				if not downloaded and callbackiftoolong then callbackiftoolong() end

				task.wait(30) -- 60
				if not downloaded and XD then XD() end
			end)
			if not rawAPI then
				local requestCompleted = false
				local requestSucceeded = false
				local requestData
				task.spawn(function()
					local ok, response = pcall(oldgame.HttpGet, game, "http://setup.roblox.com/"..Main.RobloxVersion.."-API-Dump.json")
					requestCompleted = true
					requestSucceeded = ok
					requestData = response
				end)

				local start = os.clock()
				while not requestCompleted and os.clock() - start < timeoutSeconds do
					task.wait(0.25)
				end

				if not requestCompleted then
					return skipAPI(("API request timed out after %d seconds; continuing without API data."):format(timeoutSeconds))
				end

				if not requestSucceeded then
					return skipAPI("API request failed: "..tostring(requestData))
				end

				rawAPI = requestData
			end
		else
			if script:FindFirstChild("API") then
				rawAPI = require(script.API)
			else
				error("NO API EXISTS")
			end
		end

		if not rawAPI then
			return skipAPI("API data unavailable; continuing without API data.")
		end

		downloaded = true

		Main.RawAPI = rawAPI
		api = service.HttpService:JSONDecode(rawAPI)

		local classes,enums = {},{}
		local categoryOrder,seenCategories = {},{}

		local function insertAbove(t,item,aboveItem)
			local findPos = table.find(t,item)
			if not findPos then return end
			table.remove(t,findPos)

			local pos = table.find(t,aboveItem)
			if not pos then return end
			table.insert(t,pos,item)
		end

		for _,class in api.Classes do
			local newClass = {}
			newClass.Name = class.Name
			newClass.Superclass = class.Superclass
			newClass.Properties = {}
			newClass.Functions = {}
			newClass.Events = {}
			newClass.Callbacks = {}
			newClass.Tags = {}

			if class.Tags then for c,tag in class.Tags do newClass.Tags[tag] = true end end
			for __,member in class.Members do
				local newMember = {}
				newMember.Name = member.Name
				newMember.Class = class.Name
				newMember.Security = member.Security
				newMember.Tags ={}
				if member.Tags then for c,tag in member.Tags do newMember.Tags[tag] = true end end

				local mType = member.MemberType
				if mType == "Property" then
					local propCategory = member.Category or "Other"
					propCategory = propCategory:match("^%s*(.-)%s*$")
					if not seenCategories[propCategory] then
						categoryOrder[#categoryOrder+1] = propCategory
						seenCategories[propCategory] = true
					end
					newMember.ValueType = member.ValueType
					newMember.Category = propCategory
					newMember.Serialization = member.Serialization
					table.insert(newClass.Properties,newMember)
				elseif mType == "Function" then
					newMember.Parameters = {}
					newMember.ReturnType = member.ReturnType.Name
					for c,param in member.Parameters do
						table.insert(newMember.Parameters,{Name = param.Name, Type = param.Type.Name})
					end
					table.insert(newClass.Functions,newMember)
				elseif mType == "Event" then
					newMember.Parameters = {}
					for c,param in member.Parameters do
						table.insert(newMember.Parameters,{Name = param.Name, Type = param.Type.Name})
					end
					table.insert(newClass.Events,newMember)
				end
			end

			classes[class.Name] = newClass
		end

		for _,class in classes do
			class.Superclass = classes[class.Superclass]
		end

		for _,enum in api.Enums do
			local newEnum = {}
			newEnum.Name = enum.Name
			newEnum.Items = {}
			newEnum.Tags = {}

			if enum.Tags then for c,tag in enum.Tags do newEnum.Tags[tag] = true end end
			for __,item in enum.Items do
				local newItem = {}
				newItem.Name = item.Name
				newItem.Value = item.Value
				table.insert(newEnum.Items,newItem)
			end

			enums[enum.Name] = newEnum
		end

		local function getMember(class,member)
			if not classes[class] or not classes[class][member] then return end
			local result = {}

			local currentClass = classes[class]
			while currentClass do
				for _,entry in currentClass[member] do
					result[#result+1] = entry
				end
				currentClass = currentClass.Superclass
			end

			table.sort(result,function(a,b) return a.Name < b.Name end)
			return result
		end

		insertAbove(categoryOrder,"Behavior","Tuning")
		insertAbove(categoryOrder,"Appearance","Data")
		insertAbove(categoryOrder,"Attachments","Axes")
		insertAbove(categoryOrder,"Cylinder","Slider")
		insertAbove(categoryOrder,"Localization","Jump Settings")
		insertAbove(categoryOrder,"Surface","Motion")
		insertAbove(categoryOrder,"Surface Inputs","Surface")
		insertAbove(categoryOrder,"Part","Surface Inputs")
		insertAbove(categoryOrder,"Assembly","Surface Inputs")
		insertAbove(categoryOrder,"Character","Controls")
		categoryOrder[#categoryOrder+1] = "Unscriptable"
		categoryOrder[#categoryOrder+1] = "Attributes"

		local categoryOrderMap = {}
		for i = 1,#categoryOrder do
			categoryOrderMap[categoryOrder[i]] = i
		end

		return {
			Classes = classes,
			Enums = enums,
			CategoryOrder = categoryOrderMap,
			GetMember = getMember
		}
	end

	Main.FetchRMD = function()
		local function skipRMD(reason)
			warn("[Dex] "..tostring(reason))
			return {
				Classes = {},
				Enums = {},
				PropertyOrders = {},
				Skipped = true,
				Reason = reason,
			}
		end

		local ok, rawXML = pcall(function()
			local xml

			if Main.Elevated then
				if Main.LocalDepsUpToDate() then
					local localRMD = Lib.ReadFile("DexPlusPlus/rbx_rmd.dat")
					if localRMD then
						xml = localRMD
					else
						if Main.DepsVersionData then
							Main.DepsVersionData[1] = ""
						end
					end
				end

				if not xml then
					local httpOk, httpBody = pcall(oldgame.HttpGet, oldgame, "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/refs/heads/roblox/ReflectionMetadata.xml")
					if not httpOk or type(httpBody) ~= "string" or httpBody == "" then
						error("HTTP error while fetching RMD: "..tostring(httpBody))
					end
					xml = httpBody
				end
			else
				if script:FindFirstChild("RMD") then
					xml = require(script.RMD)
				else
					error("NO RMD EXISTS")
				end
			end

			return xml
		end)

		if not ok or not rawXML or rawXML == "" then
			return skipRMD("Failed to fetch RMD: "..tostring(rawXML))
		end

		Main.RawRMD = rawXML

		local okParse, parsed = pcall(Lib.ParseXML, rawXML)
		if not okParse or not parsed or not parsed.children or not parsed.children[1] then
			return skipRMD("Failed to parse RMD XML")
		end

		local classList = parsed.children[1].children[1].children
		local enumList = parsed.children[1].children[2].children
		local propertyOrders = {}

		local classes, enums = {}, {}

		for _, class in classList do
			local className = ""
			for _, child in class.children do
				if child.tag == "Properties" then
					local data = {Properties = {}, Functions = {}}
					local props = child.children
					for _, prop in props do
						local name = prop.attrs.name
						name = name:sub(1,1):upper()..name:sub(2)
						data[name] = prop.children[1].text
					end
					className = data.Name
					classes[className] = data
				elseif child.attrs.class == "ReflectionMetadataProperties" then
					local members = child.children
					for _, member in members do
						if member.attrs.class == "ReflectionMetadataMember" then
							local data = {}
							if member.children[1].tag == "Properties" then
								local props = member.children[1].children
								for _, prop in props do
									if prop.attrs then
										local name = prop.attrs.name
										name = name:sub(1,1):upper()..name:sub(2)
										data[name] = prop.children[1].text
									end
								end
								if data.PropertyOrder then
									local orders = propertyOrders[className]
									if not orders then
										orders = {}
										propertyOrders[className] = orders
									end
									orders[data.Name] = tonumber(data.PropertyOrder)
								end
								classes[className].Properties[data.Name] = data
							end
						end
					end
				elseif child.attrs.class == "ReflectionMetadataFunctions" then
					local members = child.children
					for _, member in members do
						if member.attrs.class == "ReflectionMetadataMember" then
							local data = {}
							if member.children[1].tag == "Properties" then
								local props = member.children[1].children
								for _, prop in props do
									if prop.attrs then
										local name = prop.attrs.name
										name = name:sub(1,1):upper()..name:sub(2)
										data[name] = prop.children[1].text
									end
								end
								classes[className].Functions[data.Name] = data
							end
						end
					end
				end
			end
		end

		for _, enum in enumList do
			local enumName = ""
			for _, child in enum.children do
				if child.tag == "Properties" then
					local data = {Items = {}}
					local props = child.children
					for _, prop in props do
						local name = prop.attrs.name
						name = name:sub(1,1):upper()..name:sub(2)
						data[name] = prop.children[1].text
					end
					enumName = data.Name
					enums[enumName] = data
				elseif child.attrs.class == "ReflectionMetadataEnumItem" then
					local data = {}
					if child.children[1].tag == "Properties" then
						local props = child.children[1].children
						for _, prop in props do
							local name = prop.attrs.name
							name = name:sub(1,1):upper()..name:sub(2)
							data[name] = prop.children[1].text
						end
						enums[enumName].Items[data.Name] = data
					end
				end
			end
		end

		return {
			Classes = classes,
			Enums = enums,
			PropertyOrders = propertyOrders,
		}
	end

	Main.ShowGui = Main.SecureGui

	Main.CreateIntro = function(initStatus)
		local gui = create({
			{1,"ScreenGui",{Name="Intro",}},
			{2,"Frame",{Active=true,BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="Main",Parent={1},Position=UDim2.new(0.5,-175,0.5,-100),Size=UDim2.new(0,350,0,200),}},
			{3,"Frame",{BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,ClipsDescendants=true,Name="Holder",Parent={2},Size=UDim2.new(1,0,1,0),}},
			{4,"UIGradient",{Parent={3},Rotation=30,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{5,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=4,Name="Title",Parent={3},Position=UDim2.new(0,-190,0,15),Size=UDim2.new(0,100,0,50),Text="Dex++",TextColor3=Color3.new(1,1,1),TextSize=50,TextTransparency=1,}},
			{6,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Desc",Parent={3},Position=UDim2.new(0,-230,0,60),Size=UDim2.new(0,180,0,25),Text="Ultimate Debugging Suite",TextColor3=Color3.new(1,1,1),TextSize=18,TextTransparency=1,}},
			{7,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="StatusText",Parent={3},Position=UDim2.new(0,20,0,110),Size=UDim2.new(0,180,0,25),Text="Fetching API",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=1,}},
			{8,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="ProgressBar",Parent={3},Position=UDim2.new(0,110,0,145),Size=UDim2.new(0,0,0,4),}},
			{9,"Frame",{BackgroundColor3=Color3.new(0.2392156869173,0.56078433990479,0.86274510622025),BorderSizePixel=0,Name="Bar",Parent={8},Size=UDim2.new(0,0,1,0),}},
			{10,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=Main.ResolveAsset("rbxassetid://2764171053"),ImageColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),Parent={8},ScaleType=1,Size=UDim2.new(1,0,1,0),SliceCenter=Rect.new(2,2,254,254),}},
			{11,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Creator",Parent={2},Position=UDim2.new(0,10,1,-42),Size=UDim2.new(0,220,0,32),Text="Developed by Chillz\nUpdated by ltseverydayyou",TextColor3=Color3.new(1,1,1),TextSize=12,TextXAlignment=0,TextWrapped=true,TextYAlignment=0}},
			{12,"UIGradient",{Parent={11},Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{13,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Version",Parent={2},Position=UDim2.new(1,-110,1,-35),Size=UDim2.new(0,105,0,20),Text=Main.Version,TextColor3=Color3.new(1,1,1),TextSize=14,TextXAlignment=1,}},
			{14,"UIGradient",{Parent={13},Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{15,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Image=Main.ResolveAsset("rbxassetid://1427967925"),Name="Outlines",Parent={2},Position=UDim2.new(0,-5,0,-5),ScaleType=1,Size=UDim2.new(1,10,1,10),SliceCenter=Rect.new(6,6,25,25),TileSize=UDim2.new(0,20,0,20),}},
			{16,"UIGradient",{Parent={15},Rotation=-30,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{17,"UIGradient",{Parent={2},Rotation=-30,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1,0),NumberSequenceKeypoint.new(1,1,0),}),}},
			{18,"UIDragDetector", {Parent={2}}}
		})
		Main.ShowGui(gui)
		local backGradient = gui.Main.UIGradient
		local outlinesGradient = gui.Main.Outlines.UIGradient
		local holderGradient = gui.Main.Holder.UIGradient
		local titleText = gui.Main.Holder.Title
		local descText = gui.Main.Holder.Desc
		local versionText = gui.Main.Version
		local versionGradient = versionText.UIGradient
		local creatorText = gui.Main.Creator
		local creatorGradient = creatorText.UIGradient
		local statusText = gui.Main.Holder.StatusText
		local progressBar = gui.Main.Holder.ProgressBar
		local tweenS = service.TweenService
		local theme = Settings and Settings.Theme or DefaultSettings.Theme or {}
		local defaultBarColor = Color3.new(0.2392156869173,0.56078433990479,0.86274510622025)
		local defaultStatusColor = Color3.new(1,1,1)

		local function applyTheme()
			gui.Main.BackgroundColor3 = theme.Main2 or gui.Main.BackgroundColor3
			gui.Main.Holder.BackgroundColor3 = theme.Main1 or gui.Main.Holder.BackgroundColor3
			progressBar.BackgroundColor3 = theme.TextBox or progressBar.BackgroundColor3
			progressBar.Bar.BackgroundColor3 = theme.ListSelection or defaultBarColor
			titleText.TextColor3 = theme.Text or titleText.TextColor3
			descText.TextColor3 = theme.Text or descText.TextColor3
			statusText.TextColor3 = theme.Text or statusText.TextColor3
			versionText.TextColor3 = theme.Text or versionText.TextColor3
			creatorText.TextColor3 = theme.Text or creatorText.TextColor3
		end

		applyTheme()

		local rs = service.RunService
		local fastwait = function(t)
			if not t then
				return rs.RenderStepped:Wait()
			end
			local st = tick()
			repeat rs.RenderStepped:Wait() until (tick() - st) >= t
		end

		statusText.Text = initStatus

		local function tweenNumber(n,ti,func)
			local tweenVal = Instance.new("IntValue")
			tweenVal.Value = 0
			trackConn(tweenVal.Changed:Connect(func))
			local tween = tweenS:Create(tweenVal,ti,{Value = n})
			tween:Play()
			trackConn(tween.Completed:Connect(function()
				tweenVal:Destroy()
			end))
		end

		local ti = TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
		tweenNumber(100,ti,function(val)
			val = val/200
			local start = NumberSequenceKeypoint.new(0,0)
			local a1 = NumberSequenceKeypoint.new(val,0)
			local a2 = NumberSequenceKeypoint.new(math.min(0.5,val+math.min(0.05,val)),1)
			if a1.Time == a2.Time then a2 = a1 end
			local b1 = NumberSequenceKeypoint.new(1-val,0)
			local b2 = NumberSequenceKeypoint.new(math.max(0.5,1-val-math.min(0.05,val)),1)
			if b1.Time == b2.Time then b2 = b1 end
			local goal = NumberSequenceKeypoint.new(1,0)
			backGradient.Transparency = NumberSequence.new({start,a1,a2,b2,b1,goal})
			outlinesGradient.Transparency = NumberSequence.new({start,a1,a2,b2,b1,goal})
		end)

		fastwait(0.4)

		tweenNumber(100,ti,function(val)
			val = val/166.66
			local start = NumberSequenceKeypoint.new(0,0)
			local a1 = NumberSequenceKeypoint.new(val,0)
			local a2 = NumberSequenceKeypoint.new(val+0.01,1)
			local goal = NumberSequenceKeypoint.new(1,1)
			holderGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
		end)

		tweenS:Create(titleText,ti,{Position = UDim2.new(0,60,0,15), TextTransparency = 0}):Play()
		tweenS:Create(descText,ti,{Position = UDim2.new(0,20,0,60), TextTransparency = 0}):Play()

		local function rightTextTransparency(obj)
			tweenNumber(100,ti,function(val)
				val = val/100
				local a1 = NumberSequenceKeypoint.new(1-val,0)
				local a2 = NumberSequenceKeypoint.new(math.max(0,1-val-0.01),1)
				if a1.Time == a2.Time then a2 = a1 end
				local start = NumberSequenceKeypoint.new(0,a1 == a2 and 0 or 1)
				local goal = NumberSequenceKeypoint.new(1,0)
				obj.Transparency = NumberSequence.new({start,a2,a1,goal})
			end)
		end
		rightTextTransparency(versionGradient)
		rightTextTransparency(creatorGradient)

		fastwait(0.9)

		local progressTI = TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)

		tweenS:Create(statusText,progressTI,{Position = UDim2.new(0,20,0,120), TextTransparency = 0}):Play()
		tweenS:Create(progressBar,progressTI,{Position = UDim2.new(0,60,0,145), Size = UDim2.new(0,100,0,4)}):Play()

		fastwait(0.25)

		local function setProgress(text,n)
			statusText.Text = text
			statusText.TextColor3 = theme.Text or defaultStatusColor
			progressBar.Bar.BackgroundColor3 = theme.ListSelection or defaultBarColor
			tweenS:Create(progressBar.Bar,progressTI,{Size = UDim2.new(n,0,1,0)}):Play()
		end

		local function setError(text)
			statusText.Text = text
			statusText.TextColor3 = theme.Important or Color3.new(1,0,0)
			progressBar.Bar.BackgroundColor3 = theme.Important or Color3.new(1,0,0)
		end

		local function close()
			tweenS:Create(titleText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(descText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(versionText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(creatorText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(statusText,progressTI,{TextTransparency = 1}):Play()
			tweenS:Create(progressBar,progressTI,{BackgroundTransparency = 1}):Play()
			tweenS:Create(progressBar.Bar,progressTI,{BackgroundTransparency = 1}):Play()
			tweenS:Create(progressBar.ImageLabel,progressTI,{ImageTransparency = 1}):Play()

			tweenNumber(100,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.In),function(val)
				val = val/250
				local start = NumberSequenceKeypoint.new(0,0)
				local a1 = NumberSequenceKeypoint.new(0.6+val,0)
				local a2 = NumberSequenceKeypoint.new(math.min(1,0.601+val),1)
				if a1.Time == a2.Time then a2 = a1 end
				local goal = NumberSequenceKeypoint.new(1,a1 == a2 and 0 or 1)
				holderGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
			end)

			fastwait(0.5)
			gui.Main.BackgroundTransparency = 1
			outlinesGradient.Rotation = 30

			tweenNumber(100,ti,function(val)
				val = val/100
				local start = NumberSequenceKeypoint.new(0,1)
				local a1 = NumberSequenceKeypoint.new(val,1)
				local a2 = NumberSequenceKeypoint.new(math.min(1,val+math.min(0.05,val)),0)
				if a1.Time == a2.Time then a2 = a1 end
				local goal = NumberSequenceKeypoint.new(1,a1 == a2 and 1 or 0)
				outlinesGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
				holderGradient.Transparency = NumberSequence.new({start,a1,a2,goal})
			end)

			fastwait(0.45)
			gui:Destroy()
		end

		return {SetProgress = setProgress, SetError = setError, Close = close, Object = gui}
	end

	Main.CreateApp = function(data)
		local baseName = data.Name or "App"
		local finalName = baseName
		local suffix = 2
		while Main.MenuApps[finalName] do
			finalName = string.format("%s (%d)", baseName, suffix)
			suffix = suffix + 1
		end
		if finalName ~= baseName then
			warn(("[Dex] App name conflict: '%s' already exists, using '%s' instead."):format(baseName, finalName))
		end
		data.Name = finalName
		local control = {}

		local app = Main.AppTemplate:Clone()

		if data.IconMap == Explorer.LegacyClassIcons and data.Icon == nil then
			data.Icon = 38
		end

		local iconIndex = data.Icon
		if data.IconMap and iconIndex then
			if data.IconMap == Explorer.LegacyClassIcons and type(iconIndex) == "number" then
				app.Main.Icon.Image = data.IconMap.MapId
				app.Main.Icon.ImageRectOffset = Vector2.new(16 * iconIndex,0)
				app.Main.Icon.ImageRectSize = Vector2.new(16,16)
				app.Main.Icon.ScaleType = Enum.ScaleType.Fit
				app.Main.Icon.Size = UDim2.new(0,32,0,32)
				app.Main.Icon.Position = UDim2.new(0.5,-16,0,4)
			elseif type(iconIndex) == "number" then
				data.IconMap:Display(app.Main.Icon,iconIndex)
			elseif type(iconIndex) == "string" then
				data.IconMap:DisplayByKey(app.Main.Icon,iconIndex)
			end
			if data.IconSize or data.IconPosition then
				app.Main.Icon.Size = data.IconSize or app.Main.Icon.Size
				app.Main.Icon.Position = data.IconPosition or app.Main.Icon.Position
			elseif data.IconMap == Explorer.LegacyClassIcons then
				app.Main.Icon.Size = UDim2.new(0,32,0,32)
				app.Main.Icon.Position = UDim2.new(0.5,-16,0,4)
				app.Main.Icon.ScaleType = Enum.ScaleType.Fit
			end
		elseif type(iconIndex) == "string" then
			app.Main.Icon.Image = iconIndex
			app.Main.Icon.ImageRectOffset = Vector2.new(0,0)
			app.Main.Icon.ImageRectSize = Vector2.new(0,0)
			app.Main.Icon.ScaleType = Enum.ScaleType.Fit
			app.Main.Icon.Size = data.IconSize or UDim2.new(0,16,0,16)
			app.Main.Icon.Position = data.IconPosition or UDim2.new(0.5,-8,0,12)
			if data.ImageRectOffset then
				app.Main.Icon.ImageRectOffset = data.ImageRectOffset
			end
			if data.ImageRectSize then
				app.Main.Icon.ImageRectSize = data.ImageRectSize
			end
		else
			app.Main.Icon.Image = ""
			app.Main.Icon.ImageRectOffset = Vector2.new(0,0)
			app.Main.Icon.ImageRectSize = Vector2.new(0,0)
		end

		local function updateState()
			app.Main.BackgroundTransparency = data.Open and 0 or (Lib.CheckMouseInGui(app.Main) and 0 or 1)
			app.Main.Highlight.Visible = data.Open
		end

		local function enable(silent)
			if Main.__DexExiting then return end
			if data.Open then return end
			data.Open = true
			updateState()
			if not silent then
				if data.Window then data.Window:Show(data.WindowShowData) end
				if data.OnClick then data.OnClick(data.Open) end
			end
		end

		local function disable(silent)
			if Main.__DexExiting then return end
			if not data.Open then return end
			data.Open = false
			updateState()
			if not silent then
				if data.Window then data.Window:Hide() end
				if data.OnClick then data.OnClick(data.Open) end
			end
		end

		local boundWindow
		local function bindWindow(window)
			if not window or boundWindow == window then
				return
			end
			boundWindow = window
			trackConn(window.OnActivate:Connect(function() enable(true) end))
			trackConn(window.OnDeactivate:Connect(function() disable(true) end))
		end

		updateState()

		local ySize = service.TextService:GetTextSize(data.Name,14,Enum.Font.SourceSans,Vector2.new(62,999999)).Y
		app.Main.Size = UDim2.new(1,0,0,math.clamp(46+ySize,60,74))
		app.Main.AppName.Text = data.Name

		trackConn(app.Main.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				app.Main.BackgroundTransparency = 0
				app.Main.BackgroundColor3 = Settings.Theme.ButtonHover
			end
		end))


		trackConn(app.Main.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				app.Main.BackgroundTransparency = data.Open and 0 or 1
				app.Main.BackgroundColor3 = Settings.Theme.Button
			end
		end))

		trackConn(app.Main.MouseButton1Click:Connect(function()
			if data.Open then disable() else enable() end
		end))

		bindWindow(data.Window)

		app.Visible = true
		app.Parent = Main.AppsContainer
		Main.AppsFrame.CanvasSize = UDim2.new(0,0,0,Main.AppsContainerGrid.AbsoluteCellCount.Y*82 + 8)

		control.Enable = enable
		control.Disable = disable
		control.SetWindow = function(window)
			data.Window = window
			bindWindow(window)
		end
		Main.MenuApps[data.Name] = control
		return control
	end

	Main.UpdateSettingsButton = function()
		local mainGui = Main.MainGui
		if not mainGui or not mainGui:FindFirstChild("OpenButton") then
			return
		end

		local settingsButton = mainGui.OpenButton.MainFrame.BottomFrame.Settings
		local settingsWindow = SettingsWindow and SettingsWindow.Window
		settingsButton.Visible = settingsWindow ~= nil

		if settingsWindow and not Main.SettingsButtonBound then
			Main.SettingsButtonBound = true
			trackConn(settingsButton.MouseButton1Click:Connect(function()
				local activeWindow = SettingsWindow and SettingsWindow.Window
				if not activeWindow then
					return
				end

				if not activeWindow.Closed then
					activeWindow:Hide()
				else
					activeWindow:Show()
				end
			end))
		end
	end

	Main.RegisterDeferredApps = function()
		Main.UpdateSettingsButton()

		if not Main.MainGui then
			return
		end

		if Console and Console.Window and not Main.MenuApps["Console"] then
			Main.CreateApp({Name = "Console", IconMap = Main.LargeIcons, Icon = "Output", Window = Console.Window})
		end

		if SaveInstance and SaveInstance.Window and not Main.MenuApps["Save Instance"] then
			Main.CreateApp({Name = "Save Instance", IconMap = Main.LargeIcons, Icon = "Watcher", Window = SaveInstance.Window})
		end

		if ModelViewer and ModelViewer.Window and not Main.MenuApps["3D Viewer"] then
			Main.CreateApp({Name = "3D Viewer", IconMap = Main.LargeIcons, Icon = "Object", Window = ModelViewer.Window})
		end

		if ThemeManager and ThemeManager.Window and not Main.MenuApps["Theme Manager"] then
			Main.CreateApp({Name = "Theme Manager", Icon = Main.ResolveAsset("rbxassetid://1072518406"), IconSize = UDim2.new(0,32,0,32), IconPosition = UDim2.new(0.5,-16,0,4), Window = ThemeManager.Window})
		end
	end

	Main.LoadDeferredModules = function()
		if Main.DeferredModulesStarted then
			return
		end
		if not Main.MainGui then
			return
		end
		Main.DeferredModulesStarted = true

		for _, moduleName in Main.DeferredModuleList or {} do
			if not Main.MainGui then
				return
			end

			if not Apps[moduleName] then
				local okLoad, loadErr = pcall(Main.LoadModules, {moduleName})
				if not okLoad then
					warn("[Dex] Failed loading deferred module '"..tostring(moduleName).."': "..tostring(loadErr))
				end
			end

			local moduleData = Apps[moduleName]
			if moduleData then
				local okInit, initErr = pcall(Main.InitAppModule, moduleData, moduleName)
				if not okInit then
					warn("[Dex] Failed initializing deferred module '"..tostring(moduleName).."': "..tostring(initErr))
				end
			end
		end

		Main.RegisterDeferredApps()
	end

	Main.LoadOptionalModule = function(moduleName)
		if not moduleName then
			return nil
		end
		if Apps[moduleName] then
			return Apps[moduleName]
		end

		local okLoad, loadErr = pcall(Main.LoadModules, {moduleName})
		if not okLoad then
			warn("[Dex] Failed loading optional module '"..tostring(moduleName).."': "..tostring(loadErr))
			return nil
		end

		local moduleData = Apps[moduleName]
		if moduleData then
			local okInit, initErr = pcall(Main.InitAppModule, moduleData, moduleName)
			if not okInit then
				warn("[Dex] Failed initializing optional module '"..tostring(moduleName).."': "..tostring(initErr))
				return nil
			end
			if moduleData.Window then
				moduleData.Window.RestoreLastSide = false
				if not moduleData.Window.Closed then
					moduleData.Window:Hide()
				end
			end
			Main.SyncModuleDependencies()
		end

		return moduleData
	end

	Main.SetMainGuiOpen = function(val)
		if not Main.MainGui or not Main.MainGui:FindFirstChild("OpenButton") then
			return
		end

		local openButton = Main.MainGui.OpenButton
		Main.MainGuiOpen = val

		openButton.Text = val and "Close" or "Dex++"
		if val then openButton.MainFrame.Visible = true end
		openButton.MainFrame:TweenSize(val and UDim2.new(0,224,0,200) or UDim2.new(0,0,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.2,true)
		service.TweenService:Create(openButton,TweenInfo.new(0.2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency = val and 0 or (Lib.CheckMouseInGui(openButton) and 0 or 0.2)}):Play()

		if Main.MainGuiMouseEvent then
			pcall(function()
				Main.MainGuiMouseEvent:Disconnect()
			end)
			Main.MainGuiMouseEvent = nil
		end

		if not val then
			local startTime = tick()
			Main.MainGuiCloseTime = startTime
			coroutine.wrap(function()
				Lib.FastWait(0.2)
				if not Main.MainGuiOpen and startTime == Main.MainGuiCloseTime and openButton and openButton.MainFrame then
					openButton.MainFrame.Visible = false
				end
			end)()
		else
			Main.MainGuiMouseEvent = Main.TrackConn(service.UserInputService.InputBegan:Connect(function(input)
				if not Main.MainGui or not openButton then
					return
				end
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
					and not Lib.CheckMouseInGui(openButton)
					and not Lib.CheckMouseInGui(openButton.MainFrame) then

					Main.SetMainGuiOpen(false)
				end
			end))
		end
	end

	Main.Exit = function(keepDexState)
		if Main.__DexExiting and keepDexState ~= true then
			return
		end
		Main.__DexExiting = true
		Main.__DexLoaded = false
		Main.__DexInitStarted = keepDexState == true

		if Main.MainGuiMouseEvent then
			pcall(function()
				Main.MainGuiMouseEvent:Disconnect()
			end)
			Main.MainGuiMouseEvent = nil
		end

		if Main.ConnList then
			for i,c in Main.ConnList do
				pcall(function()
					if c then
						if c.Disconnect then
							c:Disconnect()
						elseif c.disconnect then
							c:disconnect()
						end
					end
				end)
			end
			table.clear(Main.ConnList)
			table.clear(Main.ConnSet)
		end

		if Lib and Lib.Window and type(Lib.Window.Shutdown) == "function" then
			pcall(Lib.Window.Shutdown)
		end

		if Main.GuiList then
			for i,g in Main.GuiList do
				pcall(function()
					if g and g.Destroy then
						g:Destroy()
					end
				end)
			end
			table.clear(Main.GuiList)
		end

		if Main.MainGui then
			pcall(function()
				Main.MainGui:Destroy()
			end)
			Main.MainGui = nil
		end

		Main.MainGuiOpen = false
		table.clear(Apps)
		Main.Apps = Apps
		Main.AppControls = {}
		Main.Plugins = {}
		Main.MenuApps = {}
		Main.SettingsButtonBound = false
		Main.DeferredModulesStarted = false

		Explorer = nil
		Properties = nil
		ScriptViewer = nil
		Console = nil
		SaveInstance = nil
		ModelViewer = nil
		SettingsWindow = nil
		ThemeManager = nil
		EnvExplorer = nil
		DataExplorer = nil
		DebugExplorer = nil
		Notebook = nil

		if Main.__DexState then
			if keepDexState == true then
				Main.__DexState.Main = Main
				Main.__DexState.State = "reloading"
				Main.__DexState.StartedAt = os.clock()
				if Main.SessionId then
					Main.__DexState.SessionId = Main.SessionId
				end
				syncDexStateReferences(Main.__DexState)
			else
				Main.__DexState.State = "dead"
				clearDexState(Main.__DexState)
				Main.__DexState = nil
			end
		end
	end

	Main.Reinit = function()
		local dexState = Main.__DexState or getDexState(true)
		Main.__DexState = dexState
		Main.__DexLoaded = false
		Main.__DexInitStarted = true

		dexState.Main = Main
		dexState.State = "reloading"
		dexState.StartedAt = os.clock()
		if Main.SessionId then
			dexState.SessionId = Main.SessionId
		end
		syncDexStateReferences(dexState)

		Main.Exit(true)
		task.wait()
		local okInit, initErr = pcall(Main.Init)
		if okInit then
			Main.__DexLoaded = true
			Main.__DexInitStarted = false
			dexState.Main = Main
			dexState.State = "ready"
			dexState.StartedAt = os.clock()
			if Main.SessionId then
				dexState.SessionId = Main.SessionId
			end
			syncDexStateReferences(dexState)
		else
			Main.__DexLoaded = false
			Main.__DexInitStarted = false
			dexState.State = "dead"
			clearDexState(dexState)
			Main.__DexState = nil
			error(initErr)
		end
	end

	Main.CreateMainGui = function()
		local gui = create({
			{1,"ScreenGui",{IgnoreGuiInset=true,Name="MainMenu",}},
			{2,"TextButton",{AnchorPoint=Vector2.new(0.5,0),AutoButtonColor=false,BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),BorderSizePixel=0,Font=4,Name="OpenButton",Parent={1},Position=UDim2.new(0.5,0,0,2),Size=UDim2.new(0,55,0,32),Text="Dex++",TextColor3=Color3.new(1,1,1),TextSize=16,TextTransparency=0.20000000298023,}},
			{3,"UICorner",{CornerRadius=UDim.new(0,4),Parent={2},}},
			{4,"Frame",{AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.new(0.17647059261799,0.17647059261799,0.17647059261799),ClipsDescendants=true,Name="MainFrame",Parent={2},Position=UDim2.new(0.5,0,1,-4),Size=UDim2.new(0,224,0,200),}},
			{5,"UICorner",{CornerRadius=UDim.new(0,4),Parent={4},}},
			{6,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),Name="BottomFrame",Parent={4},Position=UDim2.new(0,0,1,-24),Size=UDim2.new(1,0,0,24),}},
			{7,"UICorner",{CornerRadius=UDim.new(0,4),Parent={6},}},
			{8,"Frame",{BackgroundColor3=Color3.new(0.20392157137394,0.20392157137394,0.20392157137394),BorderSizePixel=0,Name="CoverFrame",Parent={6},Size=UDim2.new(1,0,0,4),}},
			{9,"Frame",{BackgroundColor3=Color3.new(0.1294117718935,0.1294117718935,0.1294117718935),BorderSizePixel=0,Name="Line",Parent={8},Position=UDim2.new(0,0,0,-1),Size=UDim2.new(1,0,0,1),}},
			{10,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Settings",Parent={6},Position=UDim2.new(1,-48,0,0),Size=UDim2.new(0,24,1,0),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
			{11,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=Main.ResolveAsset("rbxassetid://6578871732"),ImageTransparency=0.20000000298023,Name="Icon",Parent={10},Position=UDim2.new(0,4,0,4),Size=UDim2.new(0,16,0,16),}},
			{12,"TextButton",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Font=3,Name="Information",Parent={6},Position=UDim2.new(1,-24,0,0),Size=UDim2.new(0,24,1,0),Text="",TextColor3=Color3.new(1,1,1),TextSize=14,}},
			{13,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=Main.ResolveAsset("rbxassetid://6578933307"),ImageTransparency=0.20000000298023,Name="Icon",Parent={12},Position=UDim2.new(0,4,0,4),Size=UDim2.new(0,16,0,16),}},
			{14,"ScrollingFrame",{Active=true,AnchorPoint=Vector2.new(0.5,0),BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderColor3=Color3.new(0.1294117718935,0.1294117718935,0.1294117718935),BorderSizePixel=0,Name="AppsFrame",Parent={4},Position=UDim2.new(0.5,0,0,0),ScrollBarImageColor3=Color3.new(0,0,0),ScrollBarThickness=4,Size=UDim2.new(0,222,1,-25),}},
			{15,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="Container",Parent={14},Position=UDim2.new(0,7,0,8),Size=UDim2.new(1,-14,0,2),}},
			{16,"UIGridLayout",{CellSize=UDim2.new(0,66,0,74),Parent={15},SortOrder=2,}},
			{17,"Frame",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Name="App",Parent={1},Size=UDim2.new(0,100,0,100),Visible=false,}},
			{18,"TextButton",{AutoButtonColor=false,BackgroundColor3=Color3.new(0.2352941185236,0.2352941185236,0.2352941185236),BorderSizePixel=0,Font=3,Name="Main",Parent={17},Size=UDim2.new(1,0,0,60),Text="",TextColor3=Color3.new(0,0,0),TextSize=14,}},
			{19,"ImageLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,Image=Main.ResolveAsset("rbxassetid://129589545519436"),ImageRectSize=Vector2.new(32,32),Name="Icon",Parent={18},Position=UDim2.new(0.5,-16,0,4),ScaleType=4,Size=UDim2.new(0,32,0,32),}},
			{20,"TextLabel",{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=1,BorderSizePixel=0,Font=3,Name="AppName",Parent={18},Position=UDim2.new(0,2,0,38),Size=UDim2.new(1,-4,1,-40),Text="Explorer",TextColor3=Color3.new(1,1,1),TextSize=14,TextTransparency=0.10000000149012,TextTruncate=1,TextWrapped=true,TextYAlignment=0,}},
			{21,"Frame",{BackgroundColor3=Color3.new(0,0.66666668653488,1),BorderSizePixel=0,Name="Highlight",Parent={18},Position=UDim2.new(0,0,1,-2),Size=UDim2.new(1,0,0,2),}},
		})
		pcall(function()
			gui:SetAttribute("DexPlusLoaded", true)
			if Main.SessionId then
				gui:SetAttribute("DexPlusSessionId", Main.SessionId)
			end
		end)
		Main.MainGui = gui
		Main.AppsFrame = gui.OpenButton.MainFrame.AppsFrame
		Main.AppsContainer = Main.AppsFrame.Container
		Main.AppsContainerGrid = Main.AppsContainer.UIGridLayout
		Main.AppTemplate = gui.App
		Main.MainGuiOpen = false

		local openButton = gui.OpenButton
		openButton.BackgroundTransparency = 0.2
		openButton.MainFrame.Size = UDim2.new(0,0,0,0)
		openButton.MainFrame.Visible = false
		Main.TrackConn(openButton.MouseButton1Click:Connect(function()
			Main.SetMainGuiOpen(not Main.MainGuiOpen)
		end))

		trackConn(openButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				service.TweenService:Create(Main.MainGui.OpenButton,TweenInfo.new(0,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency = 0}):Play()
			end
		end))

		trackConn(openButton.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				service.TweenService:Create(Main.MainGui.OpenButton,TweenInfo.new(0,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency = Main.MainGuiOpen and 0 or 0.2}):Play()
			end
		end))

		local infoDexIntro, isInfoCD

		openButton.MainFrame.BottomFrame.Settings.Visible = false
		Main.UpdateSettingsButton()

		trackConn(openButton.MainFrame.BottomFrame.Information.MouseButton1Click:Connect(function()
			local duration = 1
			local Infos = {
				"Contributors >>",
				"Chillz (Dex++ Creator)",
				"Moon (Dex OG)",
				"Cazan (3D Preview)",
				"ltseverydayyou (Updates)",
			}

			if isInfoCD then return end
			isInfoCD = true
			if not infoDexIntro then
				infoDexIntro = Main.CreateIntro("Running")

				coroutine.wrap(function()
					while infoDexIntro do
						for i, text in Infos do
							if not infoDexIntro then break end
							infoDexIntro.SetProgress(text,(1 / #Infos) * i)
							task.wait(duration)
						end
					end
				end)()

				Lib.FastWait(1.5)
				isInfoCD = false
			else
				coroutine.wrap(function()
					infoDexIntro.Close()
					infoDexIntro = nil

					Lib.FastWait(1.5)
					isInfoCD = false
				end)()
			end
		end))

		-- Create Main Apps
		local startupSettings = (Settings and Settings.Startup) or (DefaultSettings and DefaultSettings.Startup) or {}
		local openExplorerByDefault = startupSettings.OpenExplorer ~= false
		local openPropertiesByDefault = startupSettings.OpenProperties ~= false
		local function startupWindowShowData(sideName, pos)
			return {
				Align = (sideName == "Left") and "left" or "right",
				Pos = pos,
				Size = 0.5
			}
		end

		Main.CreateApp({Name = "Explorer", IconMap = Main.LargeIcons, Icon = "Explorer", Open = openExplorerByDefault, Window = Explorer.Window, WindowShowData = startupWindowShowData(startupSettings.ExplorerSide, 1)})

		Main.CreateApp({Name = "Properties", IconMap = Main.LargeIcons, Icon = "Properties", Open = openPropertiesByDefault, Window = Properties.Window, WindowShowData = startupWindowShowData(startupSettings.PropertiesSide, 2)})

		local cptsOnMouseClick = nil
		local cgtsBegan = nil
		local cgtsChanged = nil
		local cgtsEnded = nil
		local cgtsInput = nil
		local cgtsStart = nil
		local cgtsMoved = false
		local cgtsCycleX = nil
		local cgtsCycleY = nil
		local cgtsCycleIndex = 0
		local cgtsCycleLast = 0

		local guiSelectorScopes = {"PlayerGui", "CoreGui", "gethui", "All"}

		local function getGuiSelectorScope()
			local scope = Settings.Explorer and Settings.Explorer.GuiSelectorScope or "PlayerGui"
			if not table.find(guiSelectorScopes, scope) then
				scope = "PlayerGui"
				if Settings.Explorer then
					Settings.Explorer.GuiSelectorScope = scope
				end
			end
			return scope
		end

		local function isDexGui(obj)
			if typeof(obj) ~= "Instance" then
				return false
			end
			local list = Main.GuiList
			if type(list) == "table" then
				for _, gui in list do
					local ok, res = pcall(function()
						return gui and (obj == gui or obj:IsDescendantOf(gui))
					end)
					if ok and res then
						return true
					end
				end
			end
			return false
		end

		local function addHolder(list, seen, holder)
			if typeof(holder) ~= "Instance" or seen[holder] then
				return
			end
			seen[holder] = true
			list[#list + 1] = holder
		end

		local function getLayer(obj)
			local cur = obj
			while cur do
				local ok, res = pcall(function()
					return cur:IsA("LayerCollector")
				end)
				if ok and res then
					return cur
				end
				cur = cur.Parent
			end
		end

		local function guiScore(obj, ind)
			local layer = getLayer(obj)
			local order = 0
			local z = 0
			local areaScore = 0
			pcall(function()
				order = layer and layer.DisplayOrder or 0
			end)
			pcall(function()
				z = obj.ZIndex or 0
			end)
			pcall(function()
				local size = obj.AbsoluteSize
				local area = math.max(1, size.X * size.Y)
				areaScore = math.floor(1000000 / area)
			end)
			return order * 1000000000 + z * 1000000 + areaScore * 10 - ind
		end

		local function getIgnoreInvisibleUI()
			return not (Settings.Explorer and Settings.Explorer.IgnoreInvisibleUI == false)
		end

		local function isShown(obj)
			local ignoreInvisible = getIgnoreInvisibleUI()
			local ok, shown = pcall(function()
				local size = obj.AbsoluteSize
				if size.X <= 0 or size.Y <= 0 then
					return false
				end
				if ignoreInvisible and obj.Visible == false then
					return false
				end
				return true
			end)
			if not ok or not shown or not getLayer(obj) then
				return false
			end
			local cur = obj.Parent
			while cur do
				local okObj, isObj = pcall(function()
					return cur:IsA("GuiObject")
				end)
				if okObj and isObj then
					if ignoreInvisible then
						local okVis, vis = pcall(function()
							return cur.Visible
						end)
						if okVis and vis == false then
							return false
						end
					end
					local okSize, size = pcall(function()
						return cur.AbsoluteSize
					end)
					if okSize and (size.X <= 0 or size.Y <= 0) then
						return false
					end
				else
					local okLayer, isLayer = pcall(function()
						return cur:IsA("LayerCollector")
					end)
					if okLayer and isLayer and ignoreInvisible then
						local okEn, en = pcall(function()
							return cur.Enabled
						end)
						if okEn and en == false then
							return false
						end
					end
				end
				cur = cur.Parent
			end
			return true
		end

		local function hasPaint(obj)
			local okBase, base = pcall(function()
				return (obj.BackgroundTransparency or 1) < 1 or (obj.BorderSizePixel or 0) > 0
			end)
			if okBase and base then
				return true
			end
			local okText, text = pcall(function()
				return (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) and obj.Text ~= "" and ((obj.TextTransparency or 1) < 1 or (obj.TextStrokeTransparency or 1) < 1)
			end)
			if okText and text then
				return true
			end
			local okImage, image = pcall(function()
				return (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and obj.Image ~= "" and (obj.ImageTransparency or 1) < 1
			end)
			if okImage and image then
				return true
			end
			local okScroll, scroll = pcall(function()
				return obj:IsA("ScrollingFrame") and (obj.ScrollBarThickness or 0) > 0 and (obj.ScrollBarImageTransparency or 1) < 1
			end)
			if okScroll and scroll then
				return true
			end
			local okView, view = pcall(function()
				return obj:IsA("ViewportFrame")
			end)
			if okView and view then
				return true
			end
			local okStroke, stroke = pcall(function()
				for _, child in obj:GetChildren() do
					if child:IsA("UIStroke") and child.Enabled ~= false and (child.Transparency or 1) < 1 and (child.Thickness or 0) > 0 then
						return true
					end
				end
				return false
			end)
			return okStroke and stroke
		end

		local function guiPrimary(obj)
			return typeof(obj) == "Instance" and obj:IsA("GuiObject") and nodes[obj] and not isDexGui(obj) and isShown(obj) and ((not getIgnoreInvisibleUI()) or hasPaint(obj))
		end

		local function addScopeHolders(holders, seen, scope)
			if scope == "All" or scope == "PlayerGui" then
				addHolder(holders, seen, plr:FindFirstChildWhichIsA("PlayerGui"))
			end
			if (scope == "All" or scope == "gethui") and env.gethui then
				local ok, hui = pcall(env.gethui)
				if ok then
					addHolder(holders, seen, hui)
				end
			end
			if scope == "All" or scope == "CoreGui" then
				addHolder(holders, seen, service.CoreGui)
			end
		end

		local function pointInObj(obj, x, y)
			local ok, res = pcall(function()
				if not obj:IsA("GuiObject") or not isShown(obj) then
					return false
				end
				local p = obj.AbsolutePosition
				local s = obj.AbsoluteSize
				return x >= p.X and y >= p.Y and x <= p.X + s.X and y <= p.Y + s.Y
			end)
			return ok and res
		end

		local function isDescendantOf(obj, ancestor)
			local cur = obj
			while cur do
				if cur == ancestor then
					return true
				end
				cur = cur.Parent
			end
			return false
		end

		local function isPointOnDexGui(x, y)
			x = math.floor(tonumber(x) or 0)
			y = math.floor(tonumber(y) or 0)
			local list = Main.GuiList
			if type(list) == "table" then
				for _, gui in list do
					if typeof(gui) == "Instance" then
						local ok, res = pcall(function()
							if gui.Name == "ExplorerSelections" then
								return false
							end
							if gui:IsA("GuiObject") and pointInObj(gui, x, y) then
								return true
							end
							if gui:IsA("LayerCollector") then
								local hitList = gui:GetGuiObjectsAtPosition(x, y)
								if type(hitList) == "table" then
									for _, obj in hitList do
										if isDescendantOf(obj, gui) then
											return true
										end
									end
								end
							end
							return false
						end)
						if ok and res then
							return true
						end
					end
				end
			end
			return false
		end

		local function addGuiCandidate(candidates, seen, obj, score, fallback)
			if seen[obj] then
				return
			end
			seen[obj] = true
			candidates[#candidates + 1] = {
				Obj = obj,
				Score = score,
				Fallback = fallback and 1 or 0
			}
		end

		local function addGuiAncestorCandidates(candidates, seen, obj, score)
			local cur = obj and obj.Parent
			while cur do
				local okGui, isGui = pcall(function()
					return cur:IsA("GuiObject")
				end)
				if not okGui or not isGui then
					break
				end
				if guiPrimary(cur) then
					addGuiCandidate(candidates, seen, cur, score - 1, true)
				end
				cur = cur.Parent
			end
		end

		local function scanGuiNodeCandidates(candidates, seenCandidates, holder, x, y, maxCandidates)
			for obj in nodes do
				if #candidates >= maxCandidates then
					break
				end
				if typeof(obj) == "Instance" then
					local ok, valid = pcall(function()
						return obj:IsA("GuiObject") and (obj == holder or obj:IsDescendantOf(holder)) and pointInObj(obj, x, y)
					end)
					if ok and valid then
						local score = guiScore(obj, #candidates + 1)
						if guiPrimary(obj) then
							addGuiCandidate(candidates, seenCandidates, obj, score, true)
						else
							addGuiAncestorCandidates(candidates, seenCandidates, obj, score)
						end
					end
				end
			end
		end

		local function getGuiCandidates(x, y)
			x = math.floor(tonumber(x) or 0)
			y = math.floor(tonumber(y) or 0)
			local holders, seenHolders = {}, {}
			local candidates, seenCandidates = {}, {}
			local maxGuiHits = 160
			local maxCandidates = 80
			addScopeHolders(holders, seenHolders, getGuiSelectorScope())
			for _, holder in holders do
				local usedHitList = false
				local ok, guis = pcall(function()
					return holder:GetGuiObjectsAtPosition(x, y)
				end)
				if ok and type(guis) == "table" then
					usedHitList = true
					for i = 1, math.min(#guis, maxGuiHits) do
						local obj = guis[i]
						local score = guiScore(obj, i)
						if guiPrimary(obj) then
							addGuiCandidate(candidates, seenCandidates, obj, score, false)
						else
							addGuiAncestorCandidates(candidates, seenCandidates, obj, score)
						end
						if #candidates >= maxCandidates then
							break
						end
					end
				end
				if not usedHitList or #candidates == 0 then
					scanGuiNodeCandidates(candidates, seenCandidates, holder, x, y, maxCandidates)
				end
			end
			table.sort(candidates, function(a, b)
				if a.Fallback ~= b.Fallback then
					return a.Fallback < b.Fallback
				end
				return a.Score > b.Score
			end)
			return candidates
		end

		local function getGuiAt(x, y)
			local candidates = getGuiCandidates(x, y)
			return candidates[1] and candidates[1].Obj
		end

		Main.CreateApp({Name = "Click part to select", IconMap = Main.LargeIcons, Icon = 6, OnClick = function(callback)
			if callback then
				local mouse = Main.Mouse
				cptsOnMouseClick = Main.TrackConn(mouse.Button1Down:Connect(function()
					pcall(function()
						local object = mouse.Target
						if nodes[object] then
							selection:Set(nodes[object])
							Explorer.ViewNode(nodes[object])
						end
					end)
				end))
			elseif cptsOnMouseClick ~= nil then
				cptsOnMouseClick:Disconnect()
				cptsOnMouseClick = nil
			end
		end})

		local function guiSelInput(input)
			return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
		end

		local function guiSelPos(input)
			local pos = input.Position
			local x, y = pos.X, pos.Y
			if Main.Mouse and x == 0 and y == 0 then
				x, y = Main.Mouse.X, Main.Mouse.Y
			end
			return x, y
		end

		local function guiSelStop()
			if cgtsBegan then
				cgtsBegan:Disconnect()
			end
			if cgtsChanged then
				cgtsChanged:Disconnect()
			end
			if cgtsEnded then
				cgtsEnded:Disconnect()
			end
			cgtsBegan = nil
			cgtsChanged = nil
			cgtsEnded = nil
			cgtsInput = nil
			cgtsStart = nil
			cgtsMoved = false
			cgtsCycleX = nil
			cgtsCycleY = nil
			cgtsCycleIndex = 0
			cgtsCycleLast = 0
		end

		local function guiSelPick(x, y)
			if isPointOnDexGui(x, y) then
				return
			end
			local candidates = getGuiCandidates(x, y)
			if #candidates == 0 then
				cgtsCycleX = nil
				cgtsCycleY = nil
				cgtsCycleIndex = 0
				return
			end
			local now = os.clock()
			local sameSpot = cgtsCycleX and ((x - cgtsCycleX) * (x - cgtsCycleX) + (y - cgtsCycleY) * (y - cgtsCycleY) <= 144) and now - cgtsCycleLast <= 4
			if sameSpot then
				cgtsCycleIndex = (cgtsCycleIndex % #candidates) + 1
			else
				cgtsCycleIndex = 1
			end
			cgtsCycleX = x
			cgtsCycleY = y
			cgtsCycleLast = now
			local obj = candidates[cgtsCycleIndex] and candidates[cgtsCycleIndex].Obj or getGuiAt(x, y)
			local node = obj and nodes[obj]
			if node then
				selection:Set(node)
				Explorer.ViewNode(node)
			end
		end

		Main.CreateApp({Name = "Click GUI to select", IconMap = Main.MiscIcons, Icon = "SelectChildren", IconSize = UDim2.new(0,32,0,32), IconPosition = UDim2.new(0.5,-16,0,4), OnClick = function(callback)
			if callback then
				guiSelStop()
				cgtsBegan = Main.TrackConn(service.UserInputService.InputBegan:Connect(function(input)
					if not guiSelInput(input) then
						return
					end
					local x, y = guiSelPos(input)
					if isPointOnDexGui(x, y) then
						cgtsInput = nil
						cgtsStart = nil
						return
					end
					cgtsInput = input
					cgtsStart = Vector2.new(x, y)
					cgtsMoved = false
				end))
				cgtsChanged = Main.TrackConn(service.UserInputService.InputChanged:Connect(function(input)
					if not cgtsStart then
						return
					end
					local touchMove = cgtsInput and cgtsInput.UserInputType == Enum.UserInputType.Touch and input == cgtsInput
					local mouseMove = cgtsInput and cgtsInput.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement
					if not touchMove and not mouseMove then
						return
					end
					local x, y = guiSelPos(input)
					local dx = x - cgtsStart.X
					local dy = y - cgtsStart.Y
					if dx * dx + dy * dy > 100 then
						cgtsMoved = true
					end
				end))
				cgtsEnded = Main.TrackConn(service.UserInputService.InputEnded:Connect(function(input)
					if input ~= cgtsInput then
						return
					end
					local x, y = guiSelPos(input)
					local moved = cgtsMoved
					cgtsInput = nil
					cgtsStart = nil
					cgtsMoved = false
					if not moved then
						pcall(guiSelPick, x, y)
					end
				end))
			else
				guiSelStop()
			end
		end})
		Main.CreateApp({Name = "Executor", IconMap = Main.LargeIcons, Icon = "Script_Viewer", Window = ScriptViewer.Window, OnClick = function(isOpen)
			if isOpen and ScriptViewer and ScriptViewer.ShowExecutor then
				ScriptViewer.ShowExecutor()
			elseif isOpen and ScriptViewer and ScriptViewer.Window then
				ScriptViewer.Window:SetTitle("Executor")
			end
		end})

		local function toggleOptionalExplorer(moduleName, appName, isOpen, onShow)
			local moduleData = Apps[moduleName]
			local appControl = Main.MenuApps[appName]
			if isOpen then
				moduleData = moduleData or Main.LoadOptionalModule(moduleName)
				if not moduleData then
					if appControl and appControl.Disable then
						appControl.Disable(true)
					end
					return
				end
				if appControl and appControl.SetWindow and moduleData.Window then
					appControl.SetWindow(moduleData.Window)
				end
				if type(onShow) == "function" and onShow(moduleData) == true then
					return
				end
				if moduleData.Window then
					moduleData.Window:Show()
				end
			elseif moduleData and moduleData.Window then
				moduleData.Window:Hide()
			end
		end

		Main.CreateApp({Name = "Environment Explorer", IconMap = Main.MiscIcons, Icon = "ExploreData", IconSize = UDim2.new(0,32,0,32), IconPosition = UDim2.new(0.5,-16,0,4), OnClick = function(isOpen)
			toggleOptionalExplorer("EnvExplorer", "Environment Explorer", isOpen, function(moduleData)
				local selected = Explorer and Explorer.Selection and Explorer.Selection.List[1]
				local obj = selected and selected.Obj
				if obj and obj:IsA("LuaSourceContainer") and type(moduleData.ViewEnvironment) == "function" then
					moduleData.ViewEnvironment(obj)
					return true
				end
				return false
			end)
		end})

		Main.CreateApp({Name = "Data Explorer", IconMap = Main.LargeIcons, Icon = "Honey", OnClick = function(isOpen)
			toggleOptionalExplorer("DataExplorer", "Data Explorer", isOpen)
		end})

		Main.CreateApp({Name = "Debug Explorer", IconMap = Main.LargeIcons, Icon = "ScriptEdit", OnClick = function(isOpen)
			toggleOptionalExplorer("DebugExplorer", "Debug Explorer", isOpen)
		end})

		Main.RegisterDeferredApps()

		for _, loadedPlugin in Main.Plugins do
			if loadedPlugin and loadedPlugin.Window then
				local pluginData = loadedPlugin.PluginData or {}
				local windowTitle = loadedPlugin.Window.GuiElems and loadedPlugin.Window.GuiElems.Title and loadedPlugin.Window.GuiElems.Title.Text
				local friendlyName = pluginData.FriendlyName or pluginData.Name or windowTitle or "Plugin"
				Main.CreateApp({
					Name = friendlyName,
					IconMap = (Explorer and Explorer.ClassIcons) or (Explorer and Explorer.LegacyClassIcons),
					Icon = "Attachment",
					Window = loadedPlugin.Window
				})
			end
		end

		Main.CreateApp({Name = "Exit Dex", Icon = Main.ResolveAsset("DexPlusIconDraft"), ImageRectOffset = Vector2.new(166,221), ImageRectSize = Vector2.new(14,13), IconSize = UDim2.new(0,32,0,30), IconPosition = UDim2.new(0.5,-16,0,5), OnClick = function(isOpen)
			if isOpen then
				Main.Exit()
			end
		end})

		--Main.CreateApp({Name = "Secret Service Panel", IconMap = Main.LargeIcons, Icon = "Output", Window = SecretServicePanel.Window})


		Lib.ShowGui(gui, {
			ignoreGuiInset = true,
			IgnoreGuiInset = true,
			forceIgnoreGuiInset = true,
			enforceIgnoreGuiInset = true,
			setIgnoreGuiInset = true,
			autoEnable = true,
			autoEnabled = true,
			forceEnabled = true,
			enforceEnabled = true,
			lockEnabled = true,
			enabledLoop = true
		})
	end

	Main.SetupFilesystem = function()
		if not env.writefile or not env.makefolder then return end

		local writefile,makefolder = env.writefile,env.makefolder

		makefolder("DexPlusPlus")
		makefolder("DexPlusPlus/assets")
		makefolder("DexPlusPlus/saved")
		makefolder("DexPlusPlus/plugins")
		makefolder("DexPlusPlus/ModuleCache")
		makefolder("DexPlusPlus/assets")
		if not (env.isfile and env.isfile(Main.UserSettingsFile)) then
			Main.SaveUserSettings()
		end
		if not (env.isfile and env.isfile(Main.ThemeFile)) then
			Main.SaveThemeSettings()
		end
	end

	Main.LocalDepsUpToDate = function()
		return Main.DepsVersionData and tostring(Main.ClientVersion) == tostring(Main.DepsVersionData[1])
	end

	Main.Init = function()
		Main.__DexExiting = false
		Main.MenuApps = {}
		table.clear(Apps)
		Main.Apps = Apps
		Main.AppControls = {}
		Main.Plugins = {}

		Main.Elevated = pcall(function() local a = __lt.cs("CoreGui", cloneref):GetFullName() end)

		if writefile and isfile and Main.SettingsFile and not isfile(Main.SettingsFile) then
			writefile(Main.SettingsFile, Main.ExportSettings())
		end

		Main.InitEnv()
		Main.LoadSettings()
		Main.LoadUserSettings()
		Main.ApplySettingsMigrations()
		Main.LoadThemeSettings()

		Main.SetupFilesystem()

		-- Load Lib
		local intro = Main.CreateIntro("Initializing Library")
		Lib = Main.LoadModule("Lib")
		Lib.FastWait()

		if (env and (env.getcustomasset or getcustomasset or getsynasset)) then
			intro.SetProgress("Preparing Icons",0.3)
		end

		-- Init icons
		Main.MiscIcons = Lib.IconMap.new(Main.ResolveAsset("rbxassetid://6511490623"),256,256,16,16)
		Main.MiscIcons:SetDict({
			Reference = 0,             Cut = 1,                         Cut_Disabled = 2,      Copy = 3,               Copy_Disabled = 4,    Paste = 5,                Paste_Disabled = 6,
			Delete = 7,                Delete_Disabled = 8,             Group = 9,             Group_Disabled = 10,    Ungroup = 11,         Ungroup_Disabled = 12,    TeleportTo = 13,
			Rename = 14,               JumpToParent = 15,               ExploreData = 16,      Save = 17,              CallFunction = 18,    CallRemote = 19,          Undo = 20,
			Undo_Disabled = 21,        Redo = 22,                       Redo_Disabled = 23,    Expand_Over = 24,       Expand = 25,          Collapse_Over = 26,       Collapse = 27,
			SelectChildren = 28,       SelectChildren_Disabled = 29,    InsertObject = 30,     ViewScript = 31,        AddStar = 32,         RemoveStar = 33,          Script_Disabled = 34,
			LocalScript_Disabled = 35, Play = 36,                       Pause = 37,            Rename_Disabled = 38,   Empty = 1000
		})
		Main.LargeIcons = Lib.IconMap.new(Main.ResolveAsset("rbxassetid://129589545519436"),256,256,32,32)
		Main.LargeIcons:SetDict({
			Explorer = 0, Properties = 1, Script_Viewer = 2, Watcher = 3, Output = 4, Paper = 5, ScriptEdit = 5, Book = 6, Executor = 7, Object = 8, Honey = 9
		})

		--[[ Loading bypasses
		intro.SetProgress("Loading Adonis Bypass",0.1)
		pcall(Main.LoadAdonisBypass)
		
		intro.SetProgress("Loading GC Bypass",0.2)
		pcall(Main.LoadGCBypass)]]

		-- Fetch version if needed
		intro.SetProgress("Fetching Roblox Version",0.3)
		if Main.Elevated then
			local fileVer = Lib.ReadFile("DexPlusPlus/deps_version.dat")
			Main.ClientVersion = (type(Version) == "function" and Version()) or (type(identifyexecutor) == "function" and identifyexecutor()) or "unknown"
			if fileVer then
				Main.DepsVersionData = string.split(fileVer,"\n")
				if Main.LocalDepsUpToDate() then
					Main.RobloxVersion = Main.DepsVersionData[2]
				end
			end

			Main.RobloxVersion = Main.RobloxVersion or oldgame:HttpGet("https://clientsettings.roblox.com/v2/client-version/WindowsStudio64/channel/LIVE"):match("(version%-[%w]+)")
		end

		-- Fetch external deps
		intro.SetProgress("Fetching API",0.35)
		API = Main.FetchAPI(
			function()
				intro.SetProgress("Fetching API, Please Wait.",0.4)
			end,
			function()
				intro.SetProgress("Fetching API, Please Wait Due To Huge API File To Download.",0.45)
			end,
			function()
				intro.SetProgress("Fetching API, LOL STILL DOWNlOADING? bad wifi xD",0.475)
			end
		)
		Lib.FastWait()
		intro.SetProgress("Fetching RMD",0.5)
		RMD = Main.FetchRMD()
		Lib.FastWait()
		if RMD and RMD.Skipped then
			intro.SetError("Failed to fetch RMD, continuing without.")
			Lib.FastWait(0.75)
		end

		-- Save external deps locally if needed
		if Main.Elevated and env.writefile and not Main.LocalDepsUpToDate() then
			env.writefile("DexPlusPlus/deps_version.dat",Main.ClientVersion.."\n"..Main.RobloxVersion)
			if Main.RawAPI then
				env.writefile("DexPlusPlus/rbx_api.dat",Main.RawAPI)
			end
			if Main.RawRMD then
				env.writefile("DexPlusPlus/rbx_rmd.dat",Main.RawRMD)
			end
		end

		-- Load other modules
		intro.SetProgress("Loading Modules",0.75)
		Main.AppControls.Lib.InitDeps(Main.GetInitDeps()) -- Missing deps now available
		Main.LoadModules(Main.StartupModuleList)
		Main.ApplyPatches()

		-- Init other modules
		intro.SetProgress("Initializing Modules",0.9)
		Main.InitAppModule(Explorer, "Explorer")
		if Explorer.SetAutoUpdateSearch then
			pcall(Explorer.SetAutoUpdateSearch, Settings.Explorer.AutoUpdateSearch)
		end
		Main.InitAppModule(Properties, "Properties")
		Main.InitAppModule(ScriptViewer, "ScriptViewer")

		local listfilesFn = (env and env.listfiles) or listfiles
		if env and env.readfile and type(listfilesFn) == "function" then
			local okList, pluginFiles = pcall(listfilesFn, "DexPlusPlus/plugins")
			if okList and type(pluginFiles) == "table" and #pluginFiles > 0 then
				intro.SetProgress("Loading Plugin Files",0.92)
				for _, pluginPath in pluginFiles do
					local pathStr = tostring(pluginPath)
					local lowerPath = string.lower(pathStr)
					if lowerPath:sub(-4) == ".lua" or lowerPath:sub(-5) == ".luau" then
						local moduleData, loadErr = Main.LoadPluginFile(pathStr)
						if moduleData then
							moduleData.PluginData = moduleData.PluginData or {}
							local titleText = moduleData.Window and moduleData.Window.GuiElems and moduleData.Window.GuiElems.Title and moduleData.Window.GuiElems.Title.Text
							local pluginFriendlyName = moduleData.PluginData.FriendlyName or titleText or "Unnamed Plugin"
							local pluginName = moduleData.PluginData.Name or tostring(pluginFriendlyName):gsub("%s+", "") or "unnamedPlugin"

							intro.SetProgress("Initializing Plugin: "..pluginFriendlyName,0.95)

							moduleData.PluginData.Name = pluginName
							moduleData.PluginData.FriendlyName = pluginFriendlyName

							if type(moduleData.Init) == "function" then
								local okInit, initErr = pcall(moduleData.Init)
								if not okInit then
									warn("[Dex] Failed initializing plugin '"..pluginFriendlyName.."': "..tostring(initErr))
								else
									table.insert(Main.Plugins, moduleData)
								end
							else
								table.insert(Main.Plugins, moduleData)
							end
						else
							warn("[Dex] Failed loading plugin '"..pathStr.."': "..tostring(loadErr))
						end
					end
				end
			end
		end

		--SecretServicePanel.Init()

		Lib.FastWait()

		-- Done
		intro.SetProgress("Complete",1)
		coroutine.wrap(function()
			Lib.FastWait(1.25)
			intro.Close()
		end)()

		-- Init window system, create main menu, show explorer and properties
		Lib.Window.Init()
		Main.CreateMainGui()
		local startupSettings = (Settings and Settings.Startup) or (DefaultSettings and DefaultSettings.Startup) or {}
		local startupWindows = {}

		local function queueStartupWindow(windowRef, isOpen, sideName)
			if not windowRef or not isOpen then
				return
			end

			local align = (sideName == "Left") and "left" or "right"
			startupWindows[align] = startupWindows[align] or {}
			table.insert(startupWindows[align], windowRef)
		end

		queueStartupWindow(Explorer.Window, startupSettings.OpenExplorer ~= false, startupSettings.ExplorerSide)
		queueStartupWindow(Properties.Window, startupSettings.OpenProperties ~= false, startupSettings.PropertiesSide)

		for _, align in {"left", "right"} do
			local windowsOnSide = startupWindows[align]
			if windowsOnSide then
				local windowSize = (#windowsOnSide > 1) and 0.5 or 1
				for index, startupWindow in windowsOnSide do
					startupWindow:Show({Align = align, Pos = index, Size = windowSize, Silent = true})
				end
			end
		end

		Lib.DeferFunc(function()
			for _, align in {"left", "right"} do
				if startupWindows[align] and #startupWindows[align] > 0 then
					Lib.Window.SetSideVisible(align, true)
				end
			end
		end)

		task.defer(function()
			Main.LoadDeferredModules()
		end)
	end

	return Main
end)()

-- Start
local dexState = getDexState(true)
Main.__DexState = dexState
Main.__DexLoaded = false
Main.__DexInitStarted = true
Main.SessionId = Main.SessionId or ((Main.GetRandomString and Main.GetRandomString()) or tostring(math.random(1, 1e9)))

dexState.Main = Main
dexState.State = "loading"
dexState.StartedAt = os.clock()
dexState.SessionId = Main.SessionId

local okInit, initErr = pcall(Main.Init)
if okInit then
	Main.__DexLoaded = true
	Main.__DexInitStarted = false
	dexState.State = "ready"
else
	Main.__DexLoaded = false
	Main.__DexInitStarted = false
	dexState.State = "dead"
	clearDexState(dexState)
	error(initErr)
end

--for i,v in Main.MissingEnv do print(i,v) end
