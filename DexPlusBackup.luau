local _g = (getgenv and getgenv()) or _G
if _g.__DEXPP and _g.__DEXPP.Main and _g.__DEXPP.Main.Exit then
	pcall(function()
		if _g.__DEXPP.Main.SetMainGuiOpen then
			_g.__DEXPP.Main.SetMainGuiOpen(true)
		end
	end)
	return _g.__DEXPP
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
local Main, Explorer, Properties, ScriptViewer, Console, SaveInstance, ModelViewer, SettingsWindow, ThemeManager--[[, SecretServicePanel]], DefaultSettings, Notebook, Serializer, Lib
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
			AutoUpdateSearch = true,
			AutoUpdateMode = 0, -- 0 Default, 1 no tree update, 2 no descendant events, 3 frozen
			PartSelectionBox = true,
			GuiSelectionBox = true,
			CopyPathUseGetChildren = true,
			UseNameWidth = false
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
			Transparency = .2
		},
		Decompiler = {
			DecompilerFallback = "Konstant", -- Konstant, Shiny, AdvancedDecompiler
			PreferDecompilerFallback = false,
			ShinyDecompilerPort = 3000,
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
	local serv = cref(game:GetService(name))
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

	for _, method in ipairs(methods) do
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
	for i,v in pairs(data) do insts[v[1]] = Instance.new(v[2]) end

	for _,v in pairs(data) do
		for prop,val in pairs(v[3]) do
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
		for k,v in pairs(obj) do
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
	Main.TrackGui = function(gui)
		if gui and gui.Destroy then
			table.insert(Main.GuiList, gui)
		end
	end
	Main.TrackConn = function(c)
		if typeof(c) == "RBXScriptConnection" then
			table.insert(Main.ConnList, c)
		end
		return c
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
		}
	}
	Main.ThemeSettings = {}

	Main.ModuleList = {"Explorer","Properties","ScriptViewer","Console","SaveInstance","ModelViewer","SettingsWindow","ThemeManager"}
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
	}
	Main.IconSourceBaseUrl = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/main/DexPlusIcons/"

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

		local Detected, Kill

		setthreadidentity(2)

		for i, v in getgc(true) do
			if typeof(v) == "table" then
				local DetectFunc = rawget(v, "Detected")
				local KillFunc = rawget(v, "Kill")

				if typeof(DetectFunc) == "function" and not Detected then
					Detected = DetectFunc

					local Old; Old = hookfunction(Detected, function(Action, Info, NoCrash)
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
					local Old; Old = hookfunction(Kill, function(Info)
						if DEBUG then
							warn(`Adonis AntiCheat tried to kill (fallback): {Info}`)
						end
					end)

					table.insert(Hooked, Kill)
				end
			end
		end

		local Old; Old = hookfunction(getrenv().debug.info, newcclosure(function(...)
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
			if env and env.makefolder then
				pcall(env.makefolder,"DexPlusPlus")
				pcall(env.makefolder,"DexPlusPlus/assets")
			end

			local function ensureFile()
				if env and env.isfile and env.isfile(path) then
					return true
				end
				if not (env and env.writefile) then
					return false
				end
				local url = Main.IconSourceBaseUrl .. override
				local ok, bytes = pcall(oldgame.HttpGet, game, url)
				if ok and type(bytes) == "string" then
					local okWrite = pcall(env.writefile, path, bytes)
					return okWrite
				end
				return false
			end

			if ensureFile() and getter then
				local ok, result = pcall(getter, path)
				if ok and result then
					return result
				end
			end
		end
		return assetId
	end

	Main.SecureGui = function(gui)
		gui.Name = Main.GetRandomString()
		if Main.TrackGui then
			Main.TrackGui(gui)
		end

		if gethui then
			gui.Parent = gethui()
		elseif syn and syn.protect_gui then
			syn.protect_gui(gui)
			gui.Parent = service.CoreGui
		elseif protect_gui then
			protect_gui(gui)
			gui.Parent = service.CoreGui
		elseif protectgui then
			protectgui(gui)
			gui.Parent = service.CoreGui
		else
			if Main.Elevated then
				gui.Parent = service.CoreGui
			else
				gui.Parent = service.Players.LocalPlayer:WaitForChild("PlayerGui")
			end
		end
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

	Main.FetchRepoFile = function(path)
		local branch = Main.GitRepoBranch or "main"
		local apiUrl = ("https://api.github.com/repos/%s/contents/%s?ref=%s"):format(Main.GitRepoName, path, branch)
		local base64Error
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
						return false, rawBody
					end
				end

				if payload.message then
					return false, payload.message
				end
			else
				return false, "Failed to decode GitHub metadata: "..tostring(payload)
			end
		else
			return false, body
		end

		local rawUrl = ("https://raw.githubusercontent.com/%s/%s/%s"):format(Main.GitRepoName, branch, path)
		local rawSuccess, rawBody = pcall(oldgame.HttpGet, game, rawUrl)
		if rawSuccess then
			return true, rawBody
		end

		return false, rawBody or base64Error or body or "Unknown error fetching "..path
	end

	Main.LoadModule = function(name)
		if Main.Elevated then -- If you don't have filesystem api then ur outta luck tbh
			local control

			if EmbeddedModules then -- Offline Modules
				control = EmbeddedModules[name]()

				if not control then Main.Error("Missing Embedded Module: "..name) end
			elseif _G.DebugLoadModel then -- Load Debug Model File
				local model = Main.DebugModel
				if not model then model = oldgame:GetObjects(getsynasset("AfterModules.rbxm"))[1] end

				control = loadstring(model.Modules[name].Source)()
				print("Locally Loaded Module",name,control)
			else
				local modulePathLocal = (Main.GitModulesPath or "Modules").."/"..name..".lua"
				if env and env.readfile and env.isfile and pcall(env.isfile, modulePathLocal) then
					local okLocal, moduleStrLocal = pcall(env.readfile, modulePathLocal)
					if okLocal and type(moduleStrLocal) == "string" then
						control = loadstring(moduleStrLocal)()
					end
				end

				if not control then
					local modulePath = (Main.GitModulesPath or "Modules").."/"..name..".lua"
					local okRemote, moduleStr = Main.FetchRepoFile(modulePath)
					if okRemote and type(moduleStr) == "string" then
						if env.writefile then
							pcall(env.writefile, "DexPlusPlus/ModuleCache/"..name..".lua", moduleStr)
						end
						control = loadstring(moduleStr)()
					end
				end

				if not control then
					local filePath = "DexPlusPlus/ModuleCache/"..name..".lua"
					local readSuccess, readResult = pcall(env.readfile, filePath)
					if readSuccess and type(readResult) == "string" then
						control = loadstring(readResult)()
					end
				end

				if not control then
					Main.Error("Failed to get external module data of "..name.." (no local, remote, or cached copy)")
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

	Main.LoadModules = function()
		for i,v in pairs(Main.ModuleList) do
			local s,e = pcall(Main.LoadModule,v)
			if not s then
				Main.Error("FAILED LOADING " .. v .. " CAUSE " .. e)
			end
		end

		-- Init Major Apps and define them in modules
		Explorer = Apps.Explorer
		Properties = Apps.Properties
		ScriptViewer = Apps.ScriptViewer
		Console = Apps.Console
		SaveInstance = Apps.SaveInstance
		ModelViewer = Apps.ModelViewer
		SettingsWindow = Apps.SettingsWindow
		ThemeManager = Apps.ThemeManager
		Notebook = Apps.Notebook

		--SecretServicePanel = Apps.SecretServicePanel
		local appTable = {
			Explorer = Explorer,
			Properties = Properties,
			ScriptViewer = ScriptViewer,
			Console = Console,
			SaveInstance = SaveInstance,
			ModelViewer = ModelViewer,
			SettingsWindow = SettingsWindow,
			ThemeManager = ThemeManager,
			Notebook = Notebook,

			--SecretServicePanel = SecretServicePanel,
		}

		Main.AppControls.Lib.InitAfterMain(appTable)
		for i,v in pairs(Main.ModuleList) do
			local control = Main.AppControls[v]
			if control then
				control.InitAfterMain(appTable)
			end
		end
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
		for _, fileName in pairs(Main.IconOverrides) do
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
			end

			if not needDownload and env.isfile then
				local ok, exists = pcall(env.isfile, path)
				needDownload = not (ok and exists)
			end

			if needDownload then
				local url = Main.IconSourceBaseUrl .. fileName
				local ok, data = pcall(oldgame.HttpGet, game, url)
				if ok and type(data) == "string" then
					pcall(env.writefile, path, data)
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

		env.isonmobile = game:GetService("UserInputService").TouchEnabled

		env.loadstring = (pcall(loadstring,"local a = 1") and loadstring) or (game:GetService("RunService"):IsStudio() and script.Modules:FindFirstChild("Loadstring") and require(script.Modules:FindFirstChild("Loadstring")))

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
		env.saveinstance = saveinstance or (function()
			--warn("No built-in saveinstance exists, using SynSaveInstance and wrapper...")
			if game:GetService("RunService"):IsStudio() then return function() error("Cannot run in Roblox Studio!") end end
			local Params = {
				RepoURL = "https://raw.githubusercontent.com/luau/SynSaveInstance/main/",
				SSI = "saveinstance",
			}
			local synsaveinstance = loadstring(oldgame:HttpGet(Params.RepoURL .. Params.SSI .. ".luau", true), Params.SSI)()

			local function wrappedsaveinstance(obj, filepath, options)
				options["FilePath"] = filepath
				--options["ReadMe"] = false
				options["Object"] = obj
				return synsaveinstance(options)
			end

			getgenv().saveinstance = wrappedsaveinstance
			return wrappedsaveinstance
		end)()

		env.parsefile = function(name)
			return tostring(name):gsub("[*\\?:<>|]+", ""):sub(1, 175)
		end

		-- debug
		env.getupvalues = debug.getupvalues or getupvalues or getupvals
		env.getconstants = debug.getconstants or getconstants or getconsts
		env.islclosure = islclosure or is_l_closure
		env.checkcaller = checkcaller
		env.getreg = getreg
		env.getgc = getgc

		-- hooks
		env.hookfunction = hookfunction
		env.hookmetamethod = hookmetamethod

		-- other
		env.getscriptbytecode = getscriptbytecode
		env.setfflag = setfflag
		env.protectgui = protect_gui or (syn and syn.protect_gui)
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

		local function getNativeDecompiler()
			if type(decompile) == "function" then
				return decompile
			end
			if type(decompile_script) == "function" then
				return decompile_script
			end
			if type(decompilescript) == "function" then
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

		local advancedDecCache
		local advancedDecTried = false
		local function getAdvancedDecompiler()
			if advancedDecTried then
				return advancedDecCache
			end
			advancedDecTried = true
			local ok, dec = pcall(function()
				local src = oldgame:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/AdvancedDecompV3.lua")
				local loader = loadstring(src)
				if type(loader) ~= "function" then
					return nil
				end
				return loader()
			end)
			if ok and type(dec) == "function" then
				advancedDecCache = dec
			end
			return advancedDecCache
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

		local function shinyDecompile(scriptInstance)
			if not env.request then
				return nil, "Shiny fallback unavailable: request function is missing."
			end
			if type(crypt) ~= "table" or type(crypt.base64encode) ~= "function" then
				return nil, "Shiny fallback unavailable: crypt.base64encode is missing."
			end
			local okBytecode, bytecode = pcall(env.getscriptbytecode, scriptInstance)
			if not okBytecode then
				return nil, "Shiny fallback failed to get bytecode: "..tostring(bytecode)
			end
			if type(bytecode) ~= "string" or bytecode == "" then
				return nil, "Shiny fallback bytecode is empty."
			end
			local encoded = crypt.base64encode(bytecode)
			local port = (Settings and Settings.Decompiler and Settings.Decompiler.ShinyDecompilerPort) or DefaultSettings.Decompiler.ShinyDecompilerPort
			local response = env.request({
				Url = "http://127.0.0.1:"..tostring(port).."/luau/decompile",
				Method = "POST",
				Body = encoded
			})
			if type(response) ~= "table" then
				return nil, "Shiny fallback returned an invalid HTTP response."
			end
			if response.StatusCode and response.StatusCode ~= 200 then
				return nil, "Shiny fallback HTTP error ("..tostring(response.StatusCode).."): "..tostring(response.Body)
			end
			if type(response.Body) ~= "string" or response.Body == "" then
				return nil, "Shiny fallback returned an empty response body."
			end
			return response.Body
		end

		env.decompile = function(...)
			local preferFallback = Settings and Settings.Decompiler and Settings.Decompiler.PreferDecompilerFallback
			local builtInDecompiler = getNativeDecompiler()
			local fallbackMode = (Settings and Settings.Decompiler and Settings.Decompiler.DecompilerFallback) or "Konstant"
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
				if mode == "Konstant" then
					queueAttempt("Konstant", fallbackDecompile)
				elseif mode == "Shiny" then
					queueAttempt("Shiny", shinyDecompile)
				elseif mode == "AdvancedDecompiler" then
					queueAttempt("AdvancedDecompiler", function(...)
						local adv = getAdvancedDecompiler()
						if type(adv) ~= "function" then
							return nil, "AdvancedDecompiler could not be loaded."
						end
						return adv(...)
					end)
				end
			end

			if preferFallback then
				queueFallback(fallbackMode)
				queueAttempt("Built-in", builtInDecompiler)
			else
				queueAttempt("Built-in", builtInDecompiler)
				queueFallback(fallbackMode)
			end

			queueFallback("Konstant")
			queueFallback("Shiny")
			queueFallback("AdvancedDecompiler")
			queueAttempt("Built-in", builtInDecompiler)

			for _, attempt in ipairs(attempts) do
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
				ggv().decompile = env.decompile
			end)
		end

		if identifyexecutor then
			Main.Executor = identifyexecutor()
		end

		env.getcustomasset = getcustomasset or getsynasset or env.getcustomasset

		Main.GuiHolder = Main.Elevated and service.CoreGui or plr:FindFirstChildOfClass("PlayerGui")

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
			for i, v in pairs(tbl) do
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
				for k,v in pairs(decoded) do
					Main.UserSettings[k] = v
				end
			end
		end
	end

	Main.SaveThemeSettings = function()
		if not (env and env.writefile) then return end
		local function recur(tbl)
			local newTbl = {}
			for i, v in pairs(tbl) do
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
					for k,v in pairs(tbl) do
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
		if type(explorer.PartSelectionBox) ~= "boolean" then
			explorer.PartSelectionBox = defaultExplorer.PartSelectionBox
		end
		if type(explorer.GuiSelectionBox) ~= "boolean" then
			explorer.GuiSelectionBox = defaultExplorer.GuiSelectionBox
		end
		if type(explorer.CopyPathUseGetChildren) ~= "boolean" then
			explorer.CopyPathUseGetChildren = defaultExplorer.CopyPathUseGetChildren
		end
		if type(explorer.UseNameWidth) ~= "boolean" then
			explorer.UseNameWidth = defaultExplorer.UseNameWidth
		end
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

		if type(Settings.ScriptViewer) ~= "table" then
			Settings.ScriptViewer = {}
		end
		if type(Settings.ScriptViewer.ShowMoreInfo) ~= "boolean" then
			Settings.ScriptViewer.ShowMoreInfo = DefaultSettings.ScriptViewer.ShowMoreInfo
		end

		if type(Settings.RemoteBlockWriteAttribute) ~= "boolean" then
			Settings.RemoteBlockWriteAttribute = DefaultSettings.RemoteBlockWriteAttribute
		end

		if type(Settings.Decompiler) ~= "table" then
			Settings.Decompiler = {}
		end
		local fallbackMode = Settings.Decompiler.DecompilerFallback
		if fallbackMode ~= "Konstant" and fallbackMode ~= "Shiny" and fallbackMode ~= "AdvancedDecompiler" then
			Settings.Decompiler.DecompilerFallback = DefaultSettings.Decompiler.DecompilerFallback
		end
		if type(Settings.Decompiler.PreferDecompilerFallback) ~= "boolean" then
			Settings.Decompiler.PreferDecompilerFallback = DefaultSettings.Decompiler.PreferDecompilerFallback
		end
		local shinyPort = tonumber(Settings.Decompiler.ShinyDecompilerPort)
		if shinyPort == nil then
			shinyPort = DefaultSettings.Decompiler.ShinyDecompilerPort
		end
		Settings.Decompiler.ShinyDecompilerPort = math.clamp(math.floor(shinyPort), 1, 65535)
		if Settings.ClassIcon == "Old" then
			Settings.ClassIcon = "NewDark"
		end
		if Settings.ClassIcon ~= "NewDark" and Settings.ClassIcon ~= "Vanilla3" then
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
					for i, v in pairs(tbl) do
						if typeof(v) == "table" then
							newTbl[i] = deserialize(recur(v))
						else
							newTbl[i] = deserialize(v)
						end
					end
					return newTbl
				end

				local deserializedData = recur(decoded)
				for k, v in pairs(deserializedData) do
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




	Main.ResetSettings = function()
		for k in pairs(Settings) do Settings[k] = nil end
		local function copyInto(dest, src)
			for key, val in pairs(src) do
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

		for _,class in pairs(api.Classes) do
			local newClass = {}
			newClass.Name = class.Name
			newClass.Superclass = class.Superclass
			newClass.Properties = {}
			newClass.Functions = {}
			newClass.Events = {}
			newClass.Callbacks = {}
			newClass.Tags = {}

			if class.Tags then for c,tag in pairs(class.Tags) do newClass.Tags[tag] = true end end
			for __,member in pairs(class.Members) do
				local newMember = {}
				newMember.Name = member.Name
				newMember.Class = class.Name
				newMember.Security = member.Security
				newMember.Tags ={}
				if member.Tags then for c,tag in pairs(member.Tags) do newMember.Tags[tag] = true end end

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
					for c,param in pairs(member.Parameters) do
						table.insert(newMember.Parameters,{Name = param.Name, Type = param.Type.Name})
					end
					table.insert(newClass.Functions,newMember)
				elseif mType == "Event" then
					newMember.Parameters = {}
					for c,param in pairs(member.Parameters) do
						table.insert(newMember.Parameters,{Name = param.Name, Type = param.Type.Name})
					end
					table.insert(newClass.Events,newMember)
				end
			end

			classes[class.Name] = newClass
		end

		for _,class in pairs(classes) do
			class.Superclass = classes[class.Superclass]
		end

		for _,enum in pairs(api.Enums) do
			local newEnum = {}
			newEnum.Name = enum.Name
			newEnum.Items = {}
			newEnum.Tags = {}

			if enum.Tags then for c,tag in pairs(enum.Tags) do newEnum.Tags[tag] = true end end
			for __,item in pairs(enum.Items) do
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
				for _,entry in pairs(currentClass[member]) do
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

		for _, class in pairs(classList) do
			local className = ""
			for _, child in pairs(class.children) do
				if child.tag == "Properties" then
					local data = {Properties = {}, Functions = {}}
					local props = child.children
					for _, prop in pairs(props) do
						local name = prop.attrs.name
						name = name:sub(1,1):upper()..name:sub(2)
						data[name] = prop.children[1].text
					end
					className = data.Name
					classes[className] = data
				elseif child.attrs.class == "ReflectionMetadataProperties" then
					local members = child.children
					for _, member in pairs(members) do
						if member.attrs.class == "ReflectionMetadataMember" then
							local data = {}
							if member.children[1].tag == "Properties" then
								local props = member.children[1].children
								for _, prop in pairs(props) do
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
					for _, member in pairs(members) do
						if member.attrs.class == "ReflectionMetadataMember" then
							local data = {}
							if member.children[1].tag == "Properties" then
								local props = member.children[1].children
								for _, prop in pairs(props) do
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

		for _, enum in pairs(enumList) do
			local enumName = ""
			for _, child in pairs(enum.children) do
				if child.tag == "Properties" then
					local data = {Items = {}}
					local props = child.children
					for _, prop in pairs(props) do
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
						for _, prop in pairs(props) do
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
			tweenVal.Changed:Connect(func)
			local tween = tweenS:Create(tweenVal,ti,{Value = n})
			tween:Play()
			tween.Completed:Connect(function()
				tweenVal:Destroy()
			end)
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
			if type(iconIndex) == "number" then
				data.IconMap:Display(app.Main.Icon,iconIndex)
			elseif type(iconIndex) == "string" then
				data.IconMap:DisplayByKey(app.Main.Icon,iconIndex)
			end
		elseif type(iconIndex) == "string" then
			app.Main.Icon.Image = iconIndex
		else
			app.Main.Icon.Image = ""
		end

		local function updateState()
			app.Main.BackgroundTransparency = data.Open and 0 or (Lib.CheckMouseInGui(app.Main) and 0 or 1)
			app.Main.Highlight.Visible = data.Open
		end

		local function enable(silent)
			if data.Open then return end
			data.Open = true
			updateState()
			if not silent then
				if data.Window then data.Window:Show() end
				if data.OnClick then data.OnClick(data.Open) end
			end
		end

		local function disable(silent)
			if not data.Open then return end
			data.Open = false
			updateState()
			if not silent then
				if data.Window then data.Window:Hide() end
				if data.OnClick then data.OnClick(data.Open) end
			end
		end

		updateState()

		local ySize = service.TextService:GetTextSize(data.Name,14,Enum.Font.SourceSans,Vector2.new(62,999999)).Y
		app.Main.Size = UDim2.new(1,0,0,math.clamp(46+ySize,60,74))
		app.Main.AppName.Text = data.Name

		app.Main.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				app.Main.BackgroundTransparency = 0
				app.Main.BackgroundColor3 = Settings.Theme.ButtonHover
			end
		end)


		app.Main.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				app.Main.BackgroundTransparency = data.Open and 0 or 1
				app.Main.BackgroundColor3 = Settings.Theme.Button
			end
		end)

		app.Main.MouseButton1Click:Connect(function()
			if data.Open then disable() else enable() end
		end)

		local window = data.Window
		if window then
			window.OnActivate:Connect(function() enable(true) end)
			window.OnDeactivate:Connect(function() disable(true) end)
		end

		app.Visible = true
		app.Parent = Main.AppsContainer
		Main.AppsFrame.CanvasSize = UDim2.new(0,0,0,Main.AppsContainerGrid.AbsoluteCellCount.Y*82 + 8)

		control.Enable = enable
		control.Disable = disable
		Main.MenuApps[data.Name] = control
		return control
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

	Main.Exit = function()
		if Main.MainGuiMouseEvent then
			pcall(function()
				Main.MainGuiMouseEvent:Disconnect()
			end)
			Main.MainGuiMouseEvent = nil
		end

		if Main.ConnList then
			for i,c in ipairs(Main.ConnList) do
				pcall(function()
					if c then
						c:Disconnect()
					end
				end)
			end
			table.clear(Main.ConnList)
		end

		if Main.GuiList then
			for i,g in ipairs(Main.GuiList) do
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
		Main.Apps = {}
		Main.AppControls = {}
		Main.Plugins = {}
		Main.MenuApps = {}

		Explorer = nil
		Properties = nil
		ScriptViewer = nil
		Console = nil
		SaveInstance = nil
		ModelViewer = nil
		SettingsWindow = nil
		ThemeManager = nil
		Notebook = nil

		if _g and _g.__DEXPP then
			_g.__DEXPP = nil
		end
	end

	Main.Reinit = function()
		Main.Exit()
		task.wait()
		Main.Init()
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

		openButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				service.TweenService:Create(Main.MainGui.OpenButton,TweenInfo.new(0,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency = 0}):Play()
			end
		end)

		openButton.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				service.TweenService:Create(Main.MainGui.OpenButton,TweenInfo.new(0,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency = Main.MainGuiOpen and 0 or 0.2}):Play()
			end
		end)

		local infoDexIntro, isInfoCD

		if SettingsWindow and SettingsWindow.Window then
			openButton.MainFrame.BottomFrame.Settings.Visible = true
			openButton.MainFrame.BottomFrame.Settings.MouseButton1Click:Connect(function()
				if not SettingsWindow.Window.Closed then
					SettingsWindow.Window:Hide()
				else
					SettingsWindow.Window:Show()
				end
			end)
		else
			openButton.MainFrame.BottomFrame.Settings.Visible = false
		end

		openButton.MainFrame.BottomFrame.Information.MouseButton1Click:Connect(function()
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
						for i, text in ipairs(Infos) do
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
		end)

		-- Create Main Apps
		Main.CreateApp({Name = "Explorer", IconMap = Main.LargeIcons, Icon = "Explorer", Open = true, Window = Explorer.Window})

		Main.CreateApp({Name = "Properties", IconMap = Main.LargeIcons, Icon = "Properties", Open = true, Window = Properties.Window})

		local cptsOnMouseClick = nil
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
			else if cptsOnMouseClick ~= nil then cptsOnMouseClick:Disconnect() cptsOnMouseClick = nil end end
		end})

		Main.CreateApp({Name = "Executor", IconMap = Main.LargeIcons, Icon = "Script_Viewer", Window = ScriptViewer.Window, OnClick = function(isOpen)
			if isOpen and ScriptViewer and ScriptViewer.ShowExecutor then
				ScriptViewer.ShowExecutor()
			elseif isOpen and ScriptViewer and ScriptViewer.Window then
				ScriptViewer.Window:SetTitle("Executor")
			end
		end})

		Main.CreateApp({Name = "Console", IconMap = Main.LargeIcons, Icon = "Output", Window = Console.Window})

		Main.CreateApp({Name = "Save Instance", IconMap = Main.LargeIcons, Icon = "Watcher", Window = SaveInstance.Window})

		Main.CreateApp({Name = "3D Viewer", IconMap = Explorer.LegacyClassIcons, Icon = 54, Window = ModelViewer.Window})

		if ThemeManager and ThemeManager.Window then
			Main.CreateApp({Name = "Theme Manager", IconMap = Explorer.LegacyClassIcons, Icon = 83, Window = ThemeManager.Window})
		end

		for _, loadedPlugin in pairs(Main.Plugins) do
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

		Main.CreateApp({Name = "Exit Dex", IconMap = Explorer.LegacyClassIcons, Icon = 37, OnClick = function(isOpen)
			if isOpen then
				Main.Exit()
			end
		end})

		--Main.CreateApp({Name = "Secret Service Panel", IconMap = Main.LargeIcons, Icon = "Output", Window = SecretServicePanel.Window})


		Lib.ShowGui(gui)
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
		Main.MenuApps = {}
		Main.Apps = {}
		Main.AppControls = {}
		Main.Plugins = {}

		Main.Elevated = pcall(function() local a = game:GetService("CoreGui"):GetFullName() end)

		if writefile and isfile and Main.SettingsFile and not isfile(Main.SettingsFile) then
			writefile(Main.SettingsFile, Main.ExportSettings())
		end

		Main.InitEnv()
		Main.LoadSettings()
		Main.LoadUserSettings()
		Main.LoadThemeSettings()

		Main.SetupFilesystem()

		-- Load Lib
		local intro = Main.CreateIntro("Initializing Library")
		Lib = Main.LoadModule("Lib")
		Lib.FastWait()

		if (env and (env.getcustomasset or getcustomasset or getsynasset)) then
			intro.SetProgress("Loading Icons",0.3)
			Main.EnsureAllIcons(true)
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
			Explorer = 0, Properties = 1, Script_Viewer = 2, Watcher = 3, Output = 4, Paper = 5, Book = 6
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
		Main.LoadModules()
		Main.ApplyPatches()
		Lib.FastWait()

		-- Init other modules
		intro.SetProgress("Initializing Modules",0.9)
		Explorer.Init()
		Properties.Init()
		ScriptViewer.Init()
		Console.Init()
		SaveInstance.Init()
		ModelViewer.Init()
		if SettingsWindow and SettingsWindow.Init then
			SettingsWindow.Init()
		end
		if ThemeManager and ThemeManager.Init then
			ThemeManager.Init()
		end

		local listfilesFn = (env and env.listfiles) or listfiles
		if env and env.readfile and type(listfilesFn) == "function" then
			local okList, pluginFiles = pcall(listfilesFn, "DexPlusPlus/plugins")
			if okList and type(pluginFiles) == "table" and #pluginFiles > 0 then
				intro.SetProgress("Loading Plugin Files",0.92)
				for _, pluginPath in pairs(pluginFiles) do
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
		Explorer.Window:Show({Align = "right", Pos = 1, Size = 0.5, Silent = true})
		Properties.Window:Show({Align = "right", Pos = 2, Size = 0.5, Silent = true})

		Lib.DeferFunc(function() Lib.Window.ToggleSide("right") end)
	end

	return Main
end)()

-- Start
_g.__DEXPP = _g.__DEXPP or {}
_g.__DEXPP.Main = Main

Main.Init()

--for i,v in pairs(Main.MissingEnv) do print(i,v) end
