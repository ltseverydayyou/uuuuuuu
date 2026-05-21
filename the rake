local __lt = (function()
	local globalEnv = _G or {};
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

---@diagnostic disable: undefined-global
if game.GameId == 847722000 then
	local genv = _G

	local function addScriptEnv(list, seen, env)
		if type(env) == "table" and env ~= _G and not seen[env] then
			seen[env] = true
			list[#list + 1] = env
		end
	end

	local function getScriptEnvs()
		local list = {}
		local seen = {}
		if type(getfenv) == "function" then
			for i = 0, 6 do
				pcall(function()
					addScriptEnv(list, seen, getfenv(i))
				end)
			end
		end
		if type(getrenv) == "function" then
			pcall(function()
				local env = getrenv()
				addScriptEnv(list, seen, env)
				if type(env) == "table" then
					addScriptEnv(list, seen, rawget(env, "_G"))
					addScriptEnv(list, seen, rawget(env, "shared"))
				end
			end)
		end
		return list
	end

	local function getScriptGlobal(k)
		local envs = getScriptEnvs()
		for i = 1, #envs do
			local env = envs[i]
			local ok, v = pcall(rawget, env, k)
			if ok and v ~= nil then
				return v, env
			end
		end
		return rawget(_G, k), _G
	end

	local function setScriptGlobal(k, v)
		local hit = false
		local envs = getScriptEnvs()
		for i = 1, #envs do
			local env = envs[i]
			local ok, old = pcall(rawget, env, k)
			if ok and old ~= nil then
				pcall(function()
					env[k] = v
				end)
				hit = true
			end
		end
		if not hit then
			local env = envs[1] or _G
			pcall(function()
				env[k] = v
			end)
		end
	end

	local function getScriptTable(k)
		local v = getScriptGlobal(k)
		if type(v) ~= "table" then
			v = {}
			setScriptGlobal(k, v)
		end
		return v
	end
	local Http = game:GetService("HttpService")
	local cfgFolder = "ProjectTheRake"
	local fileApi = type(readfile) == "function" and type(writefile) == "function"
	local hasFile = type(isfile) == "function"
	local folderApi = type(makefolder) == "function"
	local cfgFile = folderApi and (cfgFolder .. "/ProjectState.json") or "ProjectTheRake_ProjectState.json"
	local hasFolder = type(isfolder) == "function"
	local saved = {}

	local function makeCfgFolder()
		if not folderApi then
			return
		end
		pcall(function()
			if not hasFolder or not isfolder(cfgFolder) then
				makefolder(cfgFolder)
			end
		end)
	end

	local function loadCfg()
		if not fileApi then
			return {}
		end
		local ok, res = pcall(function()
			if hasFile and not isfile(cfgFile) then
				return {}
			end
			local raw = readfile(cfgFile)
			if type(raw) ~= "string" or raw == "" then
				return {}
			end
			local dec = Http:JSONDecode(raw)
			return type(dec) == "table" and dec or {}
		end)
		return ok and res or {}
	end

	local function saveCfg(tbl)
		if not fileApi then
			return false
		end
		makeCfgFolder()
		local out = {}
		for k, v in pairs(tbl or {}) do
			local tv = typeof(v)
			if tv == "boolean" or tv == "number" or tv == "string" then
				out[k] = v
			end
		end
		local ok = pcall(function()
			writefile(cfgFile, Http:JSONEncode(out))
		end)
		return ok
	end

	local saveQueued = false
	local saveDirty = false

	local function saveLater()
		if not fileApi then
			return
		end
		saveDirty = true
		if saveQueued then
			return
		end
		saveQueued = true
		if type(task) ~= "table" or type(task.delay) ~= "function" then
			saveQueued = false
			saveDirty = false
			saveCfg(saved)
			return
		end
		task.delay(0.6, function()
			saveQueued = false
			if saveDirty then
				saveDirty = false
				saveCfg(saved)
			end
		end)
	end

	saved = loadCfg()
	local st = genv.RakeGuiState
	if type(st) ~= "table" then
		st = {}
		genv.RakeGuiState = st
	end

	local function cfgGet(k, def)
		if saved[k] ~= nil then
			return saved[k]
		end
		if st[k] ~= nil then
			return st[k]
		end
		return def
	end

	local function cfgSet(k, v)
		st[k] = v
		saved[k] = v
		saveLater()
	end

	local function cfgBool(k, def)
		return cfgGet(k, def) == true
	end

	local function cfgNum(k, def, min, max)
		local n = tonumber(cfgGet(k, def)) or def
		if min and max then
			n = math.clamp(n, min, max)
		end
		return n
	end

	local function uiKeyCode(v, def)
		if typeof(v) == "EnumItem" then
			return v
		end
		local s = tostring(v or "")
		s = s:gsub("^Enum%%.KeyCode%%.", ""):gsub("^KeyCode%%.", "")
		local ok, key = pcall(function()
			return Enum.KeyCode[s]
		end)
		if ok and key then
			return key
		end
		return def or Enum.KeyCode.RightControl
	end

	local function uiKeyName(v, def)
		if typeof(v) == "EnumItem" then
			return v.Name
		end
		local key = uiKeyCode(v, nil)
		if key then
			return key.Name
		end
		return tostring(def or "RightControl")
	end

	local function uiBoolSet(k, v)
		cfgSet(k, v == true)
	end

	st.fov = cfgNum("fov", tonumber(_G.FieldOfView) or 70, 1, 120)
	st.fovOn = cfgBool("fovOn", _G.enableFOV == true)
	st.fovUiFix = cfgBool("fovUiFix", true)
	st.spd = cfgNum("spd", tonumber(_G.WalkSpeedd) or 16, 0, 30)
	st.spdOn = cfgBool("spdOn", _G.enableSpeed == true)
	st.freeCam = false
	st.freeCamSpeed = 0.2
	st.noFog = cfgBool("noFog", false)
	st.infStamina = cfgBool("infStamina", false)
	st.infNight = cfgBool("infNight", false)
	st.rakeAura = cfgBool("rakeAura", false)
	st.rakeAuraRange = cfgNum("rakeAuraRange", 12, 6, 30)
	st.rakeAuraDelay = cfgNum("rakeAuraDelay", 0.12, 0.05, 0.6)
	st.rakeAuraAutoEquip = cfgBool("rakeAuraAutoEquip", true)
	st.rakeChams = cfgBool("rakeChams", false)
	st.playerEsp = cfgBool("playerEsp", false)
	st.showDist = cfgBool("showDist", false)
	st.flareEsp = cfgBool("flareEsp", false)
	st.dropEsp = cfgBool("dropEsp", false)
	st.locEsp = cfgBool("locEsp", false)
	st.scrapEsp = cfgBool("scrapEsp", false)
	st.trapEsp = cfgBool("trapEsp", false)
	st.hide = false
	st.noFall = cfgBool("noFall", false)
	st.instaDrop = cfgBool("instaDrop", false)
	st.instaTrap = cfgBool("instaTrap", false)
	st.espSize = cfgNum("espSize", 12, 8, 24)
	st.espScan = cfgNum("espScan", 0.75, 0.2, 3)
	st.espMax = cfgNum("espMax", 0, 0, 5000)
	st.espOutline = false
	st.espChams = cfgBool("espChams", true)
	st.espDist = cfgBool("espDist", false)
	st.uiBind = uiKeyName(cfgGet("uiBind", "RightControl"), "RightControl")
	st.uiCursor = cfgBool("uiCursor", true)
	st.uiDragLock = cfgBool("uiDragLock", false)
	st.uiCompact = cfgBool("uiCompact", false)
	st.uiResizable = cfgBool("uiResizable", true)
	st.uiMobileButtons = cfgBool("uiMobileButtons", true)
	st.uiMobileRight = cfgBool("uiMobileRight", false)
	st.uiUnlockMouse = cfgBool("uiUnlockMouse", true)
	st.uiSearchBar = cfgBool("uiSearchBar", true)
	st.uiGlobalSearch = cfgBool("uiGlobalSearch", false)
	st.uiSidebarResize = cfgBool("uiSidebarResize", true)
	st.uiCompacting = cfgBool("uiCompacting", true)
	st.uiNoSnap = cfgBool("uiNoSnap", false)
	st.uiToggleFrames = cfgBool("uiToggleFrames", true)
	st.uiCorner = cfgNum("uiCorner", 4, 0, 20)
	st.uiDpi = cfgNum("uiDpi", 100, 50, 200)
	st.infoBubble = cfgBool("infoBubble", true)
	st.radioSounds = cfgBool("radioSounds", true)
	st.radioNotifications = cfgBool("radioNotifications", false)
	st.disableDeathFx = cfgBool("disableDeathFx", false)
	st.disableMotionBlur = cfgBool("disableMotionBlur", false)
	st.disableMenuFx = cfgBool("disableMenuFx", false)
	st.introBypass = cfgBool("introBypass", false)
	st.promptBypass = cfgBool("promptBypass", false)
	st.promptDistance = cfgNum("promptDistance", 25, 5, 100)
	st.disableShadows = cfgBool("disableShadows", false)
	st.forceChat = cfgBool("forceChat", false)
	st.muteGameMusic = cfgBool("muteGameMusic", false)
	st.muteChaseMusic = cfgBool("muteChaseMusic", false)
	st.enableNametags = cfgBool("enableNametags", false)
	st.enableSixthSense = cfgBool("enableSixthSense", false)
	st.muteMovementSounds = cfgBool("muteMovementSounds", false)
	st.muteFootsteps = cfgBool("muteFootsteps", false)
	st.muteJumpLand = cfgBool("muteJumpLand", false)
	st.muteWaterFall = cfgBool("muteWaterFall", false)
	st.muteDeathSounds = cfgBool("muteDeathSounds", false)
	st.hidePromptUi = cfgBool("hidePromptUi", false)
	st.freezeLookAngles = cfgBool("freezeLookAngles", false)
	st.hideDeathMessages = cfgBool("hideDeathMessages", false)
	st.blockFavoritePrompts = cfgBool("blockFavoritePrompts", false)
	st.blockGroupPrompts = cfgBool("blockGroupPrompts", false)
	st.forcePcDevice = cfgBool("forcePcDevice", false)
	st.flashlightNoShadows = cfgBool("flashlightNoShadows", false)
	st.flashlightBoost = cfgBool("flashlightBoost", false)
	st.disableMenuReopen = cfgBool("disableMenuReopen", false)
	st.forceBackpack = cfgBool("forceBackpack", false)
	st.forceMouseIcon = cfgBool("forceMouseIcon", false)
	st.forceTopbar = cfgBool("forceTopbar", false)
	st.disableCameraShake = cfgBool("disableCameraShake", false)
	st.disableCameraBobbing = cfgBool("disableCameraBobbing", false)
	st.disableVisualFx = cfgBool("disableVisualFx", false)
	st.hideLocationPopups = cfgBool("hideLocationPopups", false)
	st.hideScrapPopups = cfgBool("hideScrapPopups", false)
	st.hideTrapGui = cfgBool("hideTrapGui", false)
	st.knownPromptBypass = cfgBool("knownPromptBypass", false)
	st.noDowned = cfgBool("noDowned", false)
	st.noMoveLock = cfgBool("noMoveLock", false)
	st.noTrapLock = cfgBool("noTrapLock", false)
	st.noJumpCooldown = cfgBool("noJumpCooldown", false)
	st.noJumpscareCam = cfgBool("noJumpscareCam", false)
	st.noChaseStatic = cfgBool("noChaseStatic", false)
	st.safeRecover = cfgBool("safeRecover", false)
	st.fullbright = cfgBool("fullbright", false)
	st.autoDropPrompts = false
	st.autoSafePrompts = false
	st.autoTowerPrompts = false
	st.autoPowerPrompts = false
	st.adonisBypass = cfgBool("adonisBypass", true)
	_G.FieldOfView = st.fov
	_G.enableFOV = st.fovOn
	_G.RakeFovUiFix = st.fovUiFix
	_G.WalkSpeedd = st.spd
	_G.enableSpeed = st.spdOn
	_G.FreeCam = false
	_G.FreeCamSpeed = st.freeCamSpeed
	_G.NoFog = st.noFog
	_G.InfStamina = st.infStamina
	_G.InfNightVision = st.infNight
	_G.RakeKillAura = st.rakeAura
	_G.RakeAuraRange = st.rakeAuraRange
	_G.RakeAuraDelay = st.rakeAuraDelay
	_G.RakeAuraAutoEquip = st.rakeAuraAutoEquip
	_G.RakeChams = st.rakeChams
	_G.PlayerESP = st.playerEsp
	_G.PlayerESPShowDistance = st.showDist
	_G.FlareGunESP = st.flareEsp
	_G.SupplyDropESP = st.dropEsp
	_G.LocationESP = st.locEsp
	_G.ScrapESP = st.scrapEsp
	_G.RakeTrapESP = st.trapEsp
	_G.NoFallDMG = st.noFall
	_G.InstaOpenSupplyDrop = st.instaDrop
	_G.InstaCloseRakeTrap = st.instaTrap
	_G.RakeDisableDeathFx = st.disableDeathFx
	_G.RakeDisableMotionBlur = st.disableMotionBlur
	_G.RakeDisableMenuFx = st.disableMenuFx
	_G.RakeIntroBypass = st.introBypass
	_G.RakePromptBypass = st.promptBypass
	_G.RakeDisableShadows = st.disableShadows
	_G.RakeForceChat = st.forceChat
	_G.RakeForceNametags = st.enableNametags
	_G.RakeForceSixthSense = st.enableSixthSense
	_G.RakeMuteMovementSounds = st.muteMovementSounds
	_G.RakeMuteFootsteps = st.muteFootsteps
	_G.RakeMuteJumpLand = st.muteJumpLand
	_G.RakeMuteWaterFall = st.muteWaterFall
	_G.RakeMuteDeathSounds = st.muteDeathSounds
	_G.RakeHidePromptUi = st.hidePromptUi
	_G.RakeFreezeLookAngles = st.freezeLookAngles
	_G.RakeHideDeathMessages = st.hideDeathMessages
	_G.RakeBlockFavoritePrompts = st.blockFavoritePrompts
	_G.RakeBlockGroupPrompts = st.blockGroupPrompts
	_G.RakeFlashlightNoShadows = st.flashlightNoShadows
	_G.RakeFlashlightBoost = st.flashlightBoost
	_G.RakeDisableMenuReopen = st.disableMenuReopen
	_G.RakeForceBackpack = st.forceBackpack
	_G.RakeForceMouseIcon = st.forceMouseIcon
	_G.RakeForceTopbar = st.forceTopbar
	_G.RakeDisableCameraShake = st.disableCameraShake
	_G.RakeDisableCameraBobbing = st.disableCameraBobbing
	_G.RakeDisableVisualFx = st.disableVisualFx
	_G.RakeHideLocationPopups = st.hideLocationPopups
	_G.RakeHideScrapPopups = st.hideScrapPopups
	_G.RakeHideTrapGui = st.hideTrapGui
	_G.RakeKnownPromptBypass = st.knownPromptBypass
	_G.RakeNoDowned = st.noDowned
	_G.RakeNoMoveLock = st.noMoveLock
	_G.RakeNoTrapLock = st.noTrapLock
	_G.RakeNoJumpCooldown = st.noJumpCooldown
	_G.RakeNoJumpscareCam = st.noJumpscareCam
	_G.RakeNoChaseStatic = st.noChaseStatic
	_G.RakeSafeRecover = st.safeRecover
	_G.RakeFullbright = st.fullbright
	_G.RakeAutoDropPrompts = false
	_G.RakeAutoSafePrompts = false
	_G.RakeAutoTowerPrompts = false
	_G.RakeAutoPowerPrompts = false
	if genv.RakeGui then
		return
	end

	local svc = {}
	local ref = cloneref or function(v) return v end

	local function ClonedService(name)
		local c = svc[name]
		if c then
			return c
		end
		local ok, res = pcall(function()
			return __lt.cs(name, ref)
		end)
		if ok and res then
			svc[name] = res
			return res
		end
		local raw = __lt.gs(name)
		local out = raw and ref(raw) or raw
		svc[name] = out
		return out
	end

	local function resolveAdonisEnv()
		local gc = getgc or (debug and debug.getgc)
		local hookf = hookfunction
		local env = getrenv
		local renv = nil
		if type(env) == "function" then
			pcall(function()
				renv = env()
			end)
		end
		local dbgInfo = (type(renv) == "table" and renv.debug and renv.debug.info) or (debug and debug.info)
		local newcc = newcclosure or function(fn)
			return fn
		end
		local typeOf = typeof or function(value)
			return type(value)
		end
		return gc, hookf, env, dbgInfo, newcc, typeOf
	end

	local function eachAdonisGc(fn)
		local gc = getgc or (debug and debug.getgc)
		if type(gc) ~= "function" then
			return false
		end
		local ok, list = pcall(gc, true)
		if not ok or type(list) ~= "table" then
			return false
		end
		for _, value in next, list do
			local stop = fn(value)
			if stop then
				return true
			end
		end
		return true
	end

	local function detectAdonis()
		local gc, hookf, env, dbgInfo, _, typeOf = resolveAdonisEnv()
		if not (type(gc) == "function" and type(hookf) == "function" and type(env) == "function" and type(dbgInfo) == "function") then
			return false
		end
		local found = false
		eachAdonisGc(function(value)
			if typeOf(value) == "table" then
				local hasDetected = typeOf(rawget(value, "Detected")) == "function"
				local hasKill = typeOf(rawget(value, "Kill")) == "function"
				local hasVars = rawget(value, "Variables") ~= nil
				local hasProcess = rawget(value, "Process") ~= nil
				if hasDetected or (hasKill and hasVars and hasProcess) then
					found = true
					return true
				end
			end
		end)
		return found
	end

	local function bypassAdonis()
		local gc, hookf, env, dbgInfo, newcc, typeOf = resolveAdonisEnv()
		if not (type(gc) == "function" and type(hookf) == "function" and type(env) == "function" and type(dbgInfo) == "function") then
			return false
		end
		local DetectedMeth, KillMeth
		eachAdonisGc(function(value)
			if typeOf(value) == "table" then
				local detected = rawget(value, "Detected")
				local kill = rawget(value, "Kill")
				if typeOf(detected) == "function" and not DetectedMeth then
					DetectedMeth = detected
					pcall(function()
						hookf(DetectedMeth, function(methodName, methodFunc)
							if methodName ~= "_" then end
							return true
						end)
					end)
				end
				if rawget(value, "Variables") and rawget(value, "Process") and typeOf(kill) == "function" and not KillMeth then
					KillMeth = kill
					pcall(function()
						hookf(KillMeth, function(killFunc) end)
					end)
				end
				if DetectedMeth and KillMeth then
					return true
				end
			end
		end)
		if DetectedMeth and dbgInfo then
			local old
			pcall(function()
				old = hookf(dbgInfo, newcc(function(...)
					local functionName = ...
					if functionName == DetectedMeth then
						return coroutine.yield(coroutine.running())
					end
					return old(...)
				end))
			end)
		end
		return DetectedMeth ~= nil
	end

	local function runAdonisBypass(force)
		if st.adonisBypass ~= true and force ~= true then
			return false
		end
		if genv.RakeAdonisBypassed then
			return true
		end
		local ok, detected = pcall(detectAdonis)
		if ok and detected and bypassAdonis() then
			genv.RakeAdonisBypassed = true
			return true
		end
		return false
	end

	_G.RakeAdonisBypass = st.adonisBypass
	task.spawn(runAdonisBypass)



	local Me = {
		LocalPlayer = ClonedService("Players").LocalPlayer,
		Character = ClonedService("Players").LocalPlayer.Character,
	}




	local AllowRunService = true

	local Run = ClonedService("RunService")
	local Ws = ClonedService("Workspace")
	local Plrs = ClonedService("Players")
	local Rep = ClonedService("ReplicatedStorage")
	local Lit = ClonedService("Lighting")
	local Tws = ClonedService("TweenService")
	local wait = task and task.wait or wait
	local conns = {}
	local wipeFog
	local cleanupEsp
	local esp

	local function bind(sig, fn)
		if not sig or type(fn) ~= "function" then
			return nil
		end
		local ok, c = pcall(function()
			return sig:Connect(fn)
		end)
		if ok and c then
			conns[#conns + 1] = c
			return c
		end
		return nil
	end

	local function wipeConns()
		for i = #conns, 1, -1 do
			local c = conns[i]
			if c then
				pcall(function()
					c:Disconnect()
				end)
			end
			conns[i] = nil
		end
	end

	local function safeDestroy(v)
		if v then
			pcall(function()
				v:Destroy()
			end)
		end
	end

	local function safeDrawRemove(v)
		if v then
			pcall(function()
				v.Visible = false
				if type(v.Remove) == "function" then
					v:Remove()
				elseif type(v.Destroy) == "function" then
					v:Destroy()
				end
			end)
		end
	end

	local function kids(v)
		if not v then
			return {}
		end
		local ok, res = pcall(function()
			return v:GetChildren()
		end)
		return ok and res or {}
	end

	local function desc(v)
		if not v then
			return {}
		end
		local ok, res = pcall(function()
			return v:QueryDescendants("Instance")
		end)
		if ok and res then
			return res
		end
		ok, res = pcall(function()
			return v:GetDescendants()
		end)
		return ok and res or {}
	end

	local function addEnv(list, seen, env)
		if type(env) == "table" and not seen[env] then
			seen[env] = true
			list[#list + 1] = env
		end
	end

	local function getModuleEnvList()
		local list = {}
		local seen = {}
		addEnv(list, seen, _G)
		pcall(function()
			addEnv(list, seen, shared)
		end)
		pcall(function()
			addEnv(list, seen, rawget(_G, "shared"))
		end)
		local envs = getScriptEnvs()
		for i = 1, #envs do
			local env = envs[i]
			addEnv(list, seen, env)
			pcall(function()
				addEnv(list, seen, rawget(env, "_G"))
				addEnv(list, seen, rawget(env, "shared"))
			end)
		end
		return list
	end

	local function isLiveInst(obj)
		if typeof(obj) ~= "Instance" then
			return false
		end
		local ok, par = pcall(function()
			return obj.Parent
		end)
		if not ok or par == nil then
			return false
		end
		local ok2, live = pcall(function()
			return obj:IsDescendantOf(game)
		end)
		return ok2 and live == true
	end

	local function isLiveMod(mod)
		return isLiveInst(mod) and mod:IsA("ModuleScript")
	end

	local function safeReq(mod)
		if type(require) ~= "function" then
			return false
		end
		if not isLiveMod(mod) then
			return false
		end
		return pcall(require, mod)
	end

	local function ffc(v, name)
		if not v then
			return nil
		end
		local ok, res = pcall(function()
			return v:FindFirstChild(name)
		end)
		return ok and res or nil
	end

	local function ffcr(v, name)
		if not v then
			return nil
		end
		local ok, res = pcall(function()
			return v:FindFirstChild(name, true)
		end)
		return ok and res or nil
	end

	local function ffca(v, class)
		if not v then
			return nil
		end
		local ok, res = pcall(function()
			return v:FindFirstChildWhichIsA(class, true)
		end)
		return ok and res or nil
	end

	local zeroVelocity = Vector3.new(0, 0, 0)

	local function isPlayerCharacterPart(part)
		local model = part and part:FindFirstAncestorOfClass("Model")
		while model do
			local ok, player = pcall(function()
				return Plrs:GetPlayerFromCharacter(model)
			end)
			if ok and player then
				return true
			end
			local parent = model.Parent
			model = parent and parent:FindFirstAncestorOfClass("Model") or nil
		end
		return false
	end

	local function zeroBasePartVelocity(obj)
		if not obj or not obj:IsA("BasePart") or isPlayerCharacterPart(obj) then
			return
		end
		pcall(function()
			if obj.AssemblyLinearVelocity ~= zeroVelocity then
				obj.AssemblyLinearVelocity = zeroVelocity
			end
		end)
	end

	local function zeroWorkspaceBasePartVelocities()
		local ok, objects = pcall(function()
			return Ws:GetDescendants()
		end)
		for _, obj in pairs(ok and objects or {}) do
			zeroBasePartVelocity(obj)
		end
	end

	bind(Ws.DescendantAdded, function(obj)
		zeroBasePartVelocity(obj)
	end)

	bind(Ws.DescendantRemoving, function(obj)
		zeroBasePartVelocity(obj)
	end)

	if type(task) == "table" and type(task.defer) == "function" then
		task.defer(zeroWorkspaceBasePartVelocities)
	else
		zeroWorkspaceBasePartVelocities()
	end

	local function valOf(v, def)
		if not v then
			return def
		end
		local ok, res = pcall(function()
			return v.Value
		end)
		if ok and res ~= nil then
			return res
		end
		return def
	end

	local function eachGc(fn)
		if type(getgc) ~= "function" then
			return false
		end
		local ok, res = pcall(getgc, true)
		if not ok or type(res) ~= "table" then
			return false
		end
		for _, v in pairs(res) do
			pcall(fn, v)
		end
		return true
	end

	local infSys = {
		tabs = setmetatable({}, { __mode = "k" }),
		token = 0,
		fast = 1,
		scan = 2.5,
	}

	local function patchInfTab(v)
		if type(v) ~= "table" then
			return false
		end

		local hit = false
		if st.infStamina == true and rawget(v, "STAMINA_REGEN") ~= nil then
			v.STAMINA_REGEN = 100
			v.JUMP_STAMINA = 0
			v.JUMP_COOLDOWN = 0
			v.STAMINA_TAKE = 0
			v.stamina = 100
			hit = true
		end

		if st.infNight == true and rawget(v, "NVG_TAKE") ~= nil then
			v.NVG_TAKE = 0
			v.NVG_REGEN = 100
			hit = true
		end

		if hit then
			infSys.tabs[v] = true
		end
		return hit
	end

	local function applyInfTabs(scan)
		if st.infStamina ~= true and st.infNight ~= true then
			return
		end

		for v in pairs(infSys.tabs) do
			pcall(patchInfTab, v)
		end

		if scan == true then
			eachGc(patchInfTab)
		end
	end

	local function queueInfTabs(loops)
		if st.infStamina ~= true and st.infNight ~= true then
			return
		end

		infSys.token += 1
		local token = infSys.token
		task.spawn(function()
			for i = 1, loops or 12 do
				if token ~= infSys.token or AllowRunService ~= true then
					return
				end
				applyInfTabs(i == 1)
				task.wait(i <= 4 and 0.25 or 0.75)
			end
		end)
	end

	-- Stamina Table
    --[[
    for i,v in pairs(getgc(true)) do
        if type(v) == "table" then
            if rawget(v,"stamina") then
                _G.StaminaTable = v
            end
        end
    end
    ]]

	local HidePart
	local HidePartHightLight

	
	local curChar
	local curHum
	local curHrp
	local charConns = {}

	local function wipeCharConns()
		for i = #charConns, 1, -1 do
			local c = charConns[i]
			if c then
				pcall(function()
					c:Disconnect()
				end)
			end
			charConns[i] = nil
		end
	end

	local function bindChar(sig, fn)
		if not sig or type(fn) ~= "function" then
			return nil
		end
		local ok, c = pcall(function()
			return sig:Connect(fn)
		end)
		if ok and c then
			charConns[#charConns + 1] = c
			return c
		end
		return nil
	end

	local function getChar()
		local lp = Plrs.LocalPlayer
		local ch = lp and lp.Character
		if ch then
			curChar = ch
		end
		return curChar
	end

	local function getHum()
		if curHum and curHum.Parent then
			return curHum
		end
		local ch = getChar()
		if not ch then
			return nil
		end
		local hum = ffca(ch, "Humanoid")
		if hum then
			curHum = hum
			return hum
		end
		return nil
	end
	
	local function GET_HRP()
		local ch = getChar()
		if not ch then
			return nil
		end
		if curHrp and curHrp.Parent == ch then
			return curHrp
		end
		local r = ffcr(ch, "HumanoidRootPart")
		if r then
			curHrp = r
		end
		return r
	end

	local function SET_HRP_CFRAME(cframer : CFrame)
		local r = GET_HRP()
		if r then
			r.CFrame = cframer
			return true
		end
		return false
	end

	local function SET_HRP_ANCHORED(v)
		local r = GET_HRP()
		if r then
			r.Anchored = v == true
			return true
		end
		return false
	end

	local clientBypass = {}
	clientBypass.originals = {}
	clientBypass.mutedSounds = setmetatable({}, { __mode = "k" })
	clientBypass.prompts = setmetatable({}, { __mode = "k" })
	clientBypass.promptHold = setmetatable({}, { __mode = "k" })
	clientBypass.ch = setmetatable({}, { __mode = "k" })
	clientBypass.chT = 3
	clientBypass.fullbrightOn = false
	clientBypass.lastSafe = nil
	clientBypass.fovUiCache = setmetatable({}, { __mode = "k" })
	clientBypass.fovUiScanned = false
	clientBypass.bobFns = setmetatable({}, { __mode = "k" })
	clientBypass.uiState = setmetatable({}, { __mode = "k" })
	clientBypass.stamMods = setmetatable({}, { __mode = "k" })
	clientBypass.mainMods = setmetatable({}, { __mode = "k" })
	clientBypass.modRoots = setmetatable({}, { __mode = "k" })
	clientBypass.stamTk = setmetatable({}, { __mode = "k" })
	clientBypass.stamScanT = 12
	clientBypass.gstmnaOwned = false
	clientBypass.gstmnaInst = nil
	clientBypass.gstmnaFn = function()
		return 100
	end
	clientBypass.noop = function() end

	function clientBypass.getCamera()
		return Ws.CurrentCamera or workspace.CurrentCamera
	end

	function clientBypass.getPlayerGui()
		local lp = Plrs.LocalPlayer
		return lp and ffc(lp, "PlayerGui") or nil
	end

	function clientBypass.getGSettings()
		local gs = getScriptTable("GSettings")
		return gs
	end

	function clientBypass.setCoreGuiEnabled(kind, enabled)
		local starter = ClonedService("StarterGui")
		pcall(function()
			starter:SetCoreGuiEnabled(kind, enabled == true)
		end)
	end

	function clientBypass.restoreCoreGui()
		local starter = ClonedService("StarterGui")
		pcall(function()
			starter:SetCore("TopbarEnabled", true)
		end)
		pcall(function()
			starter:SetCore("ResetButtonCallback", true)
		end)
		clientBypass.setCoreGuiEnabled(Enum.CoreGuiType.Health, true)
		clientBypass.setCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
		clientBypass.setCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
		clientBypass.setCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
		pcall(function()
			ClonedService("UserInputService").MouseIconEnabled = true
		end)
	end

	function clientBypass.forceCoreParts()
		if st.forceTopbar == true then
			pcall(function()
				ClonedService("StarterGui"):SetCore("TopbarEnabled", true)
			end)
		end
		if st.forceBackpack == true then
			clientBypass.setCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
		end
		if st.forceMouseIcon == true then
			pcall(function()
				ClonedService("UserInputService").MouseIconEnabled = true
			end)
		end
	end

	function clientBypass.destroyCameraEffects(match)
		local cam = clientBypass.getCamera()
		if not cam then
			return 0
		end
		local removed = 0
		for _, v in pairs(kids(cam)) do
			if match(v) then
				removed += 1
				safeDestroy(v)
			end
		end
		return removed
	end

	function clientBypass.applyMotionBlurBypass()
		if st.disableMotionBlur ~= true then
			return 0
		end
		local gs = clientBypass.getGSettings()
		gs.MotionBlur = false
		setScriptGlobal("GSettings", gs)
		return clientBypass.destroyCameraEffects(function(v)
			return (v:IsA("BlurEffect") and (v.Name == "MotionBlur" or v.Name == "ESCB"))
				or (v:IsA("ColorCorrectionEffect") and v.Name == "ESCC")
		end)
	end

	function clientBypass.applyMenuFxBypass()
		if st.disableMenuFx ~= true then
			return 0
		end
		return clientBypass.destroyCameraEffects(function(v)
			return (v:IsA("BlurEffect") and v.Name == "ESCB")
				or (v:IsA("ColorCorrectionEffect") and v.Name == "ESCC")
		end)
	end

	function clientBypass.fireSettingsChanged(name, value)
		pcall(function()
			local ev = ffc(Rep, "SettingsChangedEvent")
			if ev and ev.Fire then
				ev:Fire(name, value)
			end
		end)
	end

	function clientBypass.defaultOriginal(key, value)
		if clientBypass.originals[key] == nil then
			clientBypass.originals[key] = value
		end
		return clientBypass.originals[key]
	end

	function clientBypass.setSoundVolume(name, muted)
		local ss = ClonedService("SoundService")
		local snd = ss and ffc(ss, name)
		if not snd then
			return false
		end
		local key = "SoundVolume_" .. tostring(name)
		local original = clientBypass.defaultOriginal(key, snd.Volume)
		if muted ~= true and (tonumber(original) or 0) <= 0 and (name == "GameMusic" or name == "ChaseMusic") then
			original = 1
			clientBypass.originals[key] = original
		end
		pcall(function()
			snd.Volume = muted == true and 0 or original
		end)
		return true
	end

	function clientBypass.ensureLocalPlayerMarker(name, enabled, className)
		local lp = Plrs.LocalPlayer
		if not lp then
			return nil
		end
		local marker = ffc(lp, name)
		if enabled ~= true then
			if marker and marker:GetAttribute("RakeAdminMarker") == true then
				safeDestroy(marker)
			end
			return nil
		end
		if not marker then
			local ok, obj = pcall(function()
				return Instance.new(className or "BoolValue")
			end)
			if not ok or not obj then
				return nil
			end
			obj.Name = name
			obj:SetAttribute("RakeAdminMarker", true)
			obj.Parent = lp
			marker = obj
		end
		pcall(function()
			if marker:IsA("BoolValue") then
				marker.Value = true
			end
		end)
		return marker
	end

	function clientBypass.applyGameSettingOverrides()
		local gs = clientBypass.getGSettings()
		gs.MotionBlur = st.disableMotionBlur == true and false or clientBypass.defaultOriginal("GSettings_MotionBlur", gs.MotionBlur ~= false)
		gs.Shadows = st.disableShadows == true and false or clientBypass.defaultOriginal("GSettings_Shadows", gs.Shadows ~= false)
		gs.Chat = st.forceChat == true and true or clientBypass.defaultOriginal("GSettings_Chat", gs.Chat ~= false)
		gs.GameMusic = st.muteGameMusic == true and false or clientBypass.defaultOriginal("GSettings_GameMusic", gs.GameMusic ~= false)
		gs.ChaseMusic = st.muteChaseMusic == true and false or clientBypass.defaultOriginal("GSettings_ChaseMusic", gs.ChaseMusic ~= false)
		gs.Nametags = st.enableNametags == true and true or clientBypass.defaultOriginal("GSettings_Nametags", gs.Nametags ~= false)
		pcall(function()
			local original = clientBypass.defaultOriginal("Lighting_GlobalShadows", Lit.GlobalShadows)
			Lit.GlobalShadows = st.disableShadows == true and false or original
		end)
		pcall(function()
			ClonedService("Chat").BubbleChatEnabled = gs.Chat == true
		end)
		clientBypass.setCoreGuiEnabled(Enum.CoreGuiType.Chat, gs.Chat == true)
		clientBypass.setSoundVolume("GameMusic", st.muteGameMusic == true)
		clientBypass.setSoundVolume("ChaseMusic", st.muteChaseMusic == true)
		if st.enableSixthSense == true then
			clientBypass.ensureLocalPlayerMarker("SixthSenseGamepass", true, "BoolValue")
			gs.SixthSense = true
		else
			clientBypass.ensureLocalPlayerMarker("SixthSenseGamepass", false, "BoolValue")
			gs.SixthSense = clientBypass.defaultOriginal("GSettings_SixthSense", gs.SixthSense == true)
		end
		setScriptGlobal("GSettings", gs)
	end

	function clientBypass.applyDeathFxBypass()
		if st.disableDeathFx ~= true then
			return 0
		end
		pcall(function()
			local died = ffc(Rep, "DiedEvent")
			if died and died.Fire then
				died:Fire(false, true)
			end
		end)
		return clientBypass.destroyCameraEffects(function(v)
			return (v:IsA("BlurEffect") and (v.Name == "Blur" or v.Name == "BlurEffect"))
				or (v:IsA("ColorCorrectionEffect") and (v.Name == "ColorCorrection" or v.Name == "ColorCorrectionEffect"))
		end)
	end

	function clientBypass.removeIntroGui()
		local pg = clientBypass.getPlayerGui()
		if not pg then
			return 0
		end
		local removed = 0
		for _, gui in pairs(kids(pg)) do
			if gui:IsA("ScreenGui") and (gui.Name == "IntroGUI" or (ffc(gui, "LoadingFrame") and ffc(gui, "MenuFrame"))) then
				removed += 1
				safeDestroy(gui)
			end
		end
		return removed
	end

	function clientBypass.applyIntroBypass()
		if st.introBypass ~= true then
			return 0
		end
		setScriptGlobal("IsLoading", nil)
		setScriptGlobal("SLoaded", true)
		local lp = Plrs.LocalPlayer
		pcall(function()
			if lp then
				lp:SetAttribute("Started", true)
			end
		end)
		clientBypass.restoreCoreGui()
		local removed = clientBypass.removeIntroGui()
		pcall(function()
			local died = ffc(Rep, "DiedEvent")
			if died and died.Fire then
				died:Fire(false, true)
			end
		end)
		return removed
	end

	function clientBypass.invokeStartRemote(mode)
		local remote = ffc(Rep, "StartRemote")
		if not remote or not remote.InvokeServer then
			return false
		end
		local ok, res = pcall(function()
			return remote:InvokeServer(mode)
		end)
		return ok, res
	end

	function clientBypass.isHoldRequiredPrompt(prompt)
		if not prompt or not prompt:IsA("ProximityPrompt") then
			return false
		end
		local map = ffc(Ws, "Map")
		if not map then
			return false
		end
		local ps = ffc(map, "PowerStation")
		local ot = ffc(map, "ObservationTower")
		local ok, res = pcall(function()
			return (ps and prompt:IsDescendantOf(ps)) or (ot and prompt:IsDescendantOf(ot))
		end)
		return ok and res == true
	end

	function clientBypass.cachePromptHold(prompt)
		if not prompt or not prompt:IsA("ProximityPrompt") then
			return
		end
		if clientBypass.promptHold[prompt] then
			return
		end
		pcall(function()
			local hold = tonumber(prompt.HoldDuration)
			if hold and hold > 0 then
				clientBypass.promptHold[prompt] = hold
			end
		end)
	end

	function clientBypass.restorePromptHold(prompt)
		if not prompt or not prompt:IsA("ProximityPrompt") then
			return
		end
		pcall(function()
			local hold = tonumber(clientBypass.promptHold[prompt]) or tonumber(prompt:GetAttribute("ActivateTime")) or tonumber(prompt:GetAttribute("HoldDuration")) or tonumber(prompt:GetAttribute("OHoldDuration"))
			if not hold or hold <= 0 then
				hold = 1
			end
			if prompt.HoldDuration <= 0 then
				prompt.HoldDuration = hold
			end
		end)
	end

	function clientBypass.unlockPrompt(prompt)
		if not prompt or not prompt:IsA("ProximityPrompt") then
			return false
		end
		clientBypass.prompts[prompt] = true
		clientBypass.cachePromptHold(prompt)
		local keepHold = clientBypass.isHoldRequiredPrompt(prompt)
		local dist = math.clamp(tonumber(st.promptDistance) or 25, 5, 100)
		pcall(function()
			prompt.Enabled = true
			if keepHold then
				clientBypass.restorePromptHold(prompt)
			else
				prompt.HoldDuration = 0
			end
			prompt.RequiresLineOfSight = false
			prompt.ClickablePrompt = true
			prompt.MaxActivationDistance = dist
			prompt:SetAttribute("ODistance", dist)
		end)
		pcall(function()
			prompt:SetAttribute("Busy", false)
			prompt:SetAttribute("Busy2", false)
			prompt:SetAttribute("Unavailable", false)
			prompt:SetAttribute("Unavailable2", false)
		end)
		return true
	end

	function clientBypass.applyPromptBypass()
		if st.promptBypass ~= true then
			return 0
		end
		local n = 0
		for _, obj in pairs(desc(Ws)) do
			if clientBypass.unlockPrompt(obj) then
				n += 1
			end
		end
		return n
	end

	function clientBypass.applyKnownPromptBypass()
		if st.promptBypass ~= true then
			return 0
		end
		local n = 0
		for prompt in pairs(clientBypass.prompts) do
			if prompt and prompt.Parent then
				if clientBypass.unlockPrompt(prompt) then
					n += 1
				end
			else
				clientBypass.prompts[prompt] = nil
			end
		end
		return n
	end

	function clientBypass.muteSound(sound)
		if not sound or not sound:IsA("Sound") then
			return false
		end
		pcall(function()
			if sound:GetAttribute("RakeAdminOriginalVolume") == nil then
				sound:SetAttribute("RakeAdminOriginalVolume", sound.Volume)
			end
			sound:SetAttribute("RakeAdminMuted", true)
			sound.Volume = 0
			sound.Playing = false
			sound.TimePosition = 0
			clientBypass.mutedSounds[sound] = true
		end)
		return true
	end

	function clientBypass.restoreMutedSounds()
		local n = 0
		for obj in pairs(clientBypass.mutedSounds) do
			if not obj or not obj.Parent then
				clientBypass.mutedSounds[obj] = nil
			elseif obj:IsA("Sound") and obj:GetAttribute("RakeAdminMuted") == true and not clientBypass.shouldMuteSound(obj) then
				pcall(function()
					local original = obj:GetAttribute("RakeAdminOriginalVolume")
					if type(original) == "number" then
						obj.Volume = original
					end
					obj:SetAttribute("RakeAdminMuted", false)
					clientBypass.mutedSounds[obj] = nil
					n += 1
				end)
			end
		end
		return n
	end

	function clientBypass.soundKind(sound)
		local name = tostring(sound and sound.Name or ""):lower()
		if name == "running" or name == "climbing" or name == "swimming" or name == "freefalling" then
			return "movement"
		end
		if name == "jumping" or name == "landhard" or name:find("land", 1, true) or name:find("jump", 1, true) then
			return "jumpLand"
		end
		if name:find("splash", 1, true) or name:find("swim", 1, true) or name:find("freefall", 1, true) then
			return "waterFall"
		end
		if name:find("death", 1, true) or name:find("died", 1, true) then
			return "death"
		end
		local parent = sound and sound.Parent
		if parent and (parent.Name == "HumanoidRootPart" or parent == clientBypass.getCamera()) then
			return "footstep"
		end
		return "other"
	end

	function clientBypass.shouldMuteSound(sound)
		local kind = clientBypass.soundKind(sound)
		return (st.muteMovementSounds == true and kind == "movement")
			or (st.muteFootsteps == true and kind == "footstep")
			or (st.muteJumpLand == true and kind == "jumpLand")
			or (st.muteWaterFall == true and kind == "waterFall")
			or (st.muteDeathSounds == true and kind == "death")
	end

	function clientBypass.scanSoundContainer(root)
		if not root then
			return 0
		end
		local n = 0
		for _, obj in pairs(desc(root)) do
			if obj:IsA("Sound") and clientBypass.shouldMuteSound(obj) then
				if clientBypass.muteSound(obj) then
					n += 1
				end
			end
		end
		return n
	end

	function clientBypass.applySoundBypasses()
		if not (st.muteMovementSounds or st.muteFootsteps or st.muteJumpLand or st.muteWaterFall or st.muteDeathSounds) then
			clientBypass.restoreMutedSounds()
			return 0
		end
		local n = 0
		local cam = clientBypass.getCamera()
		n += clientBypass.scanSoundContainer(cam)
		local lp = Plrs.LocalPlayer
		for _, p in pairs(kids(Plrs)) do
			n += clientBypass.scanSoundContainer(p.Character)
		end
		if lp and lp.Character then
			n += clientBypass.scanSoundContainer(lp.Character)
		end
		n += clientBypass.scanSoundContainer(ffcr(Ws, "Rake"))
		clientBypass.restoreMutedSounds()
		return n
	end

	function clientBypass.applyPromptUiBypass()
		local pg = clientBypass.getPlayerGui()
		local gui = pg and ffc(pg, "ProximityPrompts")
		if gui and gui:IsA("ScreenGui") then
			gui.Enabled = st.hidePromptUi ~= true
		end
		return gui ~= nil
	end

	function clientBypass.applyLookFreeze()
		if st.freezeLookAngles ~= true then
			return false
		end
		pcall(function()
			local remote = ffc(Rep, "SetLookAngles")
			if remote and remote.FireServer then
				remote:FireServer(0, 0)
			end
		end)
		return true
	end

	function clientBypass.applyDeathMessageBypass()
		local active = st.hideDeathMessages == true or st.muteDeathSounds == true
		if not active and clientBypass.deathMsgApplied ~= true then
			return 0
		end
		local pg = clientBypass.getPlayerGui()
		if not pg then
			return 0
		end
		local n = 0
		for _, obj in pairs(desc(pg)) do
			if obj.Name == "DeathMsg" and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then
				obj.Visible = st.hideDeathMessages ~= true
				if st.hideDeathMessages == true then
					obj.TextTransparency = 1
					obj.TextStrokeTransparency = 1
					clientBypass.deathMsgApplied = true
					n += 1
				end
			elseif obj:IsA("Sound") and obj.Name == "Boom" and st.muteDeathSounds == true then
				if clientBypass.muteSound(obj) then
					n += 1
				end
			end
		end
		if not active then
			clientBypass.deathMsgApplied = false
		end
		return n
	end

	function clientBypass.cleanupPromptModals()
		local pg = clientBypass.getPlayerGui()
		if not pg then
			return 0
		end
		local n = 0
		for _, gui in pairs(kids(pg)) do
			if gui:IsA("ScreenGui") and ((st.blockFavoritePrompts == true and gui.Name == "_fav") or (st.blockGroupPrompts == true and gui.Name == "_fav2")) then
				n += 1
				safeDestroy(gui)
			end
		end
		return n
	end

	function clientBypass.applyDeviceSpoof()
		if st.forcePcDevice ~= true then
			return false
		end
		setScriptGlobal("deviceType", "PC")
		setScriptGlobal("deviceType2", nil)
		setScriptGlobal("inputType", "PC")
		pcall(function()
			local ev = getScriptGlobal("InputTypeChangeEvent")
			if ev and ev.Fire then
				ev:Fire("PC")
			end
		end)
		return true
	end

	function clientBypass.applyLightToolBypasses()
		if not (st.flashlightNoShadows == true or st.flashlightBoost == true) then
			return 0
		end
		local n = 0
		local function scan(root)
			if not root then
				return
			end
			for _, obj in pairs(desc(root)) do
				if obj:IsA("Light") then
					if st.flashlightNoShadows == true then
						pcall(function()
							obj.Shadows = false
						end)
					end
					if st.flashlightBoost == true and not obj:GetAttribute("RakeAdminBoosted") then
						pcall(function()
							obj:SetAttribute("RakeAdminBoosted", true)
							obj:SetAttribute("RakeAdminBrightness", obj.Brightness)
							obj.Brightness = math.clamp((tonumber(obj.Brightness) or 1) * 2, 0, 20)
							if obj:IsA("SpotLight") then
								obj.Angle = math.clamp((tonumber(obj.Angle) or 45) * 1.1, 0, 180)
							end
						end)
					end
					n += 1
				elseif obj:IsA("BasePart") and st.flashlightNoShadows == true and (obj.Name == "LShadow1" or obj.Name == "LShadow2") then
					pcall(function()
						obj.Transparency = 1
					end)
					n += 1
				end
			end
		end
		for _, p in pairs(kids(Plrs)) do
			scan(p.Character)
		end
		scan(ffcr(Ws, "Rake"))
		return n
	end


	function clientBypass.patchMovementModule(mod, enabled)
		if type(mod) ~= "table" then
			return false
		end
		local cur = rawget(mod, "Movement")
		if enabled == true then
			if clientBypass.bobFns[mod] == nil and type(cur) == "function" then
				clientBypass.bobFns[mod] = cur
				mod.Movement = clientBypass.noop
				return true
			end
			return clientBypass.bobFns[mod] ~= nil
		end
		local old = clientBypass.bobFns[mod]
		if old then
			pcall(function()
				mod.Movement = old
			end)
			clientBypass.bobFns[mod] = nil
			return true
		end
		return false
	end

	function clientBypass.restoreMovementPatches()
		local n = 0
		for mod, old in pairs(clientBypass.bobFns) do
			if type(mod) == "table" and type(old) == "function" then
				pcall(function()
					mod.Movement = old
				end)
				n += 1
			end
			clientBypass.bobFns[mod] = nil
		end
		return n
	end

	function clientBypass.setGuiHidden(obj, hide)
		if typeof(obj) ~= "Instance" then
			return false
		end
		local prop
		if obj:IsA("LayerCollector") then
			prop = "Enabled"
		elseif obj:IsA("GuiObject") then
			prop = "Visible"
		else
			return false
		end
		local state = clientBypass.uiState[obj]
		if not state then
			state = {}
			clientBypass.uiState[obj] = state
		end
		local ok = pcall(function()
			if state[prop] == nil then
				state[prop] = obj[prop]
			end
			if hide == true then
				obj[prop] = false
			elseif state[prop] ~= nil then
				obj[prop] = state[prop]
			end
		end)
		return ok
	end

	function clientBypass.restoreHiddenUi()
		local n = 0
		for obj, state in pairs(clientBypass.uiState) do
			if typeof(obj) == "Instance" and obj.Parent and type(state) == "table" then
				pcall(function()
					if state.Enabled ~= nil and obj:IsA("LayerCollector") then
						obj.Enabled = state.Enabled
					end
					if state.Visible ~= nil and obj:IsA("GuiObject") then
						obj.Visible = state.Visible
					end
				end)
				n += 1
			end
			clientBypass.uiState[obj] = nil
		end
		return n
	end

	function clientBypass.isTrapBarGui(gui)
		return typeof(gui) == "Instance" and gui:IsA("ScreenGui") and gui.Name == "BarGUI" and ffc(gui, "Frame2") ~= nil
	end

	function clientBypass.applyClientPopupBypasses()
		local n = 0
		for ch in pairs(clientBypass.ch) do
			if clientBypass.isCH(ch) then
				local frames = rawget(ch, "frames")
				local lbl = type(frames) == "table" and rawget(frames, "locationLabel") or nil
				if clientBypass.setGuiHidden(lbl, st.hideLocationPopups == true) then
					n += 1
				end
			end
		end
		local pg = clientBypass.getPlayerGui()
		if pg then
			for _, gui in pairs(kids(pg)) do
				if gui:IsA("ScreenGui") and gui.Name == "ScrapGUI" then
					if clientBypass.setGuiHidden(gui, st.hideScrapPopups == true) then
						n += 1
					end
				elseif clientBypass.isTrapBarGui(gui) then
					if clientBypass.setGuiHidden(gui, st.hideTrapGui == true) then
						n += 1
					end
				end
			end
		end
		return n
	end

	function clientBypass.path(root, list)
		local cur = root
		for i = 1, #list do
			if not cur then
				return nil
			end
			cur = ffc(cur, list[i])
		end
		return cur
	end

	function clientBypass.unlockPromptIn(obj)
		if typeof(obj) ~= "Instance" then
			return false
		end
		if obj:IsA("ProximityPrompt") then
			return clientBypass.unlockPrompt(obj)
		end
		return clientBypass.unlockPrompt(ffca(obj, "ProximityPrompt"))
	end

	function clientBypass.unlockPromptPath(root, list)
		return clientBypass.unlockPromptIn(clientBypass.path(root, list))
	end

	function clientBypass.applyKnownGamePrompts()
		if st.knownPromptBypass ~= true then
			return 0
		end
		local n = 0
		local map = ffc(Ws, "Map")
		local paths = {
			{ "SafeHouse", "Door", "DoorLever", "DoorGUIPart" },
			{ "SafeHouse", "Door", "LightLever", "LightGUIPart" },
			{ "SafeHouse", "Door", "Door", "DoorGUIPart" },
			{ "SafeHouse", "Door", "PowerBox", "GUIPart" },
			{ "SafeHouse", "Giver", "WalkieTalkie", "Attachment" },
			{ "PowerStation", "StationFolder", "StationGUIPart" },
			{ "Shack", "ShopPart" },
			{ "ObservationTower", "Lights", "LightLever", "LightGUIPart" },
			{ "ObservationTower", "Door", "DoorLever", "DoorGUIPart" },
			{ "ObservationTower", "Door", "DoorLever2", "DoorGUIPart2" },
			{ "ObservationTower", "Radar", "Lever", "RadarGUIPart" },
			{ "ObservationTower", "LadderPart", "Attachment" },
			{ "ObservationTower", "Door", "DoorModel", "Door", "KnockA" },
		}
		if map then
			for i = 1, #paths do
				if clientBypass.unlockPromptPath(map, paths[i]) then
					n += 1
				end
			end
		end
		local debris = ffc(Ws, "Debris")
		local drops = debris and (ffc(debris, "SupplyCrates") or ffc(debris, "SupplyCreates"))
		if drops then
			for _, obj in pairs(desc(drops)) do
				if obj.Name == "Box" or obj.Name == "GUIPart" or obj:IsA("ProximityPrompt") then
					if clientBypass.unlockPromptIn(obj) then
						n += 1
					end
				end
			end
		end
		local traps = debris and ffc(debris, "Traps")
		if traps then
			for _, trap in pairs(kids(traps)) do
				if trap.Name == "RakeTrapModel" and clientBypass.unlockPromptIn(trap) then
					n += 1
				end
			end
		end
		return n
	end

	function clientBypass.cfgVal(cfg, k, def)
		local ok, res = pcall(function()
			return cfg[k]
		end)
		if ok and res ~= nil then
			return res
		end
		return def
	end

	function clientBypass.fillStamina(ch)
		if type(ch) ~= "table" then
			return false
		end
		local vars = rawget(ch, "vars")
		if type(vars) ~= "table" then
			return false
		end
		local cfg = rawget(ch, "CONFIG")
		local max = clientBypass.cfgVal(cfg, "MAX_STAMINA", 100)
		pcall(function()
			vars.stamina = max
			vars.can_jump = true
			vars.can_jump2 = true
			vars.lastJump = 0
			vars.handlingSRegen = false
			vars.regeningS = false
			vars.breathing = false
			vars.GT_VTZ = true
			local fov = rawget(ch, "sprintFovV")
			if typeof(fov) == "Instance" and fov:IsA("NumberValue") and fov.Value < 0 then
				fov.Value = 0
			end
		end)
		if clientBypass.isCH and clientBypass.isCH(ch) then
			clientBypass.ch[ch] = true
		end
		return true
	end

	function clientBypass.fillNvg(ch)
		if type(ch) ~= "table" then
			return false
		end
		local nvg = rawget(ch, "nvg")
		if type(nvg) ~= "table" then
			return false
		end
		local cfg = rawget(ch, "CONFIG")
		pcall(function()
			nvg.power = clientBypass.cfgVal(cfg, "MAX_NVG_P", 100)
			nvg.cooldown = false
			nvg.s = tick()
		end)
		if clientBypass.isCH and clientBypass.isCH(ch) then
			clientBypass.ch[ch] = true
		end
		return true
	end

	function clientBypass.stamCap(ch)
		if st.infStamina == true then
			clientBypass.fillStamina(ch)
		end
		if st.infNight == true then
			clientBypass.fillNvg(ch)
		end
	end

	function clientBypass.patchStaminaModule(mod)
		if not isLiveMod(mod) then
			return false
		end
		if clientBypass.stamMods[mod] then
			return true
		end
		if mod.Name ~= "M_H" then
			return false
		end
		local ok, lib = safeReq(mod)
		if not ok or type(lib) ~= "table" then
			return false
		end
		if type(rawget(lib, "TakeStamina")) ~= "function" and type(rawget(lib, "Update")) ~= "function" then
			return false
		end
		local old = {}
		for _, name in pairs({ "CanSprintCheck", "JumpHandler", "TakeStamina", "StaminaDrain", "DoRegenStamina", "RegenStaminaHandler", "Update" }) do
			local fn = rawget(lib, name)
			if type(fn) == "function" then
				old[name] = fn
			end
		end
		clientBypass.stamMods[mod] = { lib = lib, old = old }
		if old.CanSprintCheck then
			lib.CanSprintCheck = function(ch, ...)
				if st.infStamina == true then
					clientBypass.fillStamina(ch)
					local vars = type(ch) == "table" and rawget(ch, "vars")
					local hum = type(ch) == "table" and rawget(ch, "hum")
					return type(vars) == "table" and vars.canMove ~= false and vars.canMove2 ~= false and (typeof(hum) ~= "Instance" or hum.Health > 0)
				end
				return old.CanSprintCheck(ch, ...)
			end
		end
		if old.JumpHandler then
			lib.JumpHandler = function(ch, state, ...)
				if st.infStamina == true and state == false then
					clientBypass.fillStamina(ch)
					state = true
				end
				return old.JumpHandler(ch, state, ...)
			end
		end
		if old.TakeStamina then
			lib.TakeStamina = function(ch, amount, ...)
				if st.infStamina == true and type(amount) == "number" and amount > 0 then
					clientBypass.fillStamina(ch)
					return
				end
				local a, b, c = old.TakeStamina(ch, amount, ...)
				clientBypass.stamCap(ch)
				return a, b, c
			end
		end
		if old.StaminaDrain then
			lib.StaminaDrain = function(ch, ...)
				if st.infStamina == true then
					clientBypass.fillStamina(ch)
					return
				end
				return old.StaminaDrain(ch, ...)
			end
		end
		if old.DoRegenStamina then
			lib.DoRegenStamina = function(ch, ...)
				if st.infStamina == true then
					clientBypass.fillStamina(ch)
					return
				end
				return old.DoRegenStamina(ch, ...)
			end
		end
		if old.RegenStaminaHandler then
			lib.RegenStaminaHandler = function(ch, ...)
				if st.infStamina == true then
					clientBypass.fillStamina(ch)
					return
				end
				return old.RegenStaminaHandler(ch, ...)
			end
		end
		if old.Update then
			lib.Update = function(ch, ...)
				clientBypass.stamCap(ch)
				local a, b, c = old.Update(ch, ...)
				clientBypass.stamCap(ch)
				return a, b, c
			end
		end
		return true
	end

	function clientBypass.restoreStaminaModules()
		for mod, data in pairs(clientBypass.stamMods) do
			pcall(function()
				local lib = data.lib
				for name, fn in pairs(data.old or {}) do
					lib[name] = fn
				end
			end)
			clientBypass.stamMods[mod] = nil
		end
	end

	function clientBypass.fetchRootModule()
		local envs = getModuleEnvList()
		for i = 1, #envs do
			local env = envs[i]
			local box = type(env) == "table" and rawget(env, "C09KOPGRE09430989PSD39090W3R") or nil
			local fn = type(box) == "table" and rawget(box, "POKDS908") or nil
			if type(fn) == "function" then
				local ok, mod = pcall(fn, "2390WE890OFD-0F")
				if ok and isLiveMod(mod) then
					clientBypass.modRoots[mod] = true
					return mod
				end
			end
		end
		return nil
	end

	function clientBypass.captureCH(ch)
		if clientBypass.addCH(ch) then
			clientBypass.patchCH(ch)
			return true
		end
		return false
	end

	function clientBypass.patchMainClientModule(mod)
		if not isLiveMod(mod) then
			return false
		end
		if clientBypass.mainMods[mod] then
			return true
		end
		local ok, lib = safeReq(mod)
		if not ok or type(lib) ~= "table" then
			return false
		end
		local old = {}
		for _, name in pairs({ "new", "UpdateHB", "UpdateRS", "Update" }) do
			local fn = rawget(lib, name)
			if type(fn) == "function" then
				old[name] = fn
			end
		end
		if not next(old) then
			return false
		end
		clientBypass.mainMods[mod] = { lib = lib, old = old }
		if old.new then
			lib.new = function(...)
				local a, b, c = old.new(...)
				clientBypass.captureCH(a)
				return a, b, c
			end
		end
		for _, name in pairs({ "UpdateHB", "UpdateRS", "Update" }) do
			local fn = old[name]
			if fn then
				lib[name] = function(ch, ...)
					clientBypass.captureCH(ch)
					clientBypass.stamCap(ch)
					local a, b, c = fn(ch, ...)
					clientBypass.stamCap(ch)
					return a, b, c
				end
			end
		end
		return true
	end

	function clientBypass.restoreMainClientModules()
		for mod, data in pairs(clientBypass.mainMods) do
			pcall(function()
				local lib = data.lib
				for name, fn in pairs(data.old or {}) do
					lib[name] = fn
				end
			end)
			clientBypass.mainMods[mod] = nil
		end
	end

	function clientBypass.addModuleCandidate(obj, seen, list)
		if isLiveMod(obj) and obj.Name == "M_H" and not seen[obj] then
			seen[obj] = true
			list[#list + 1] = obj
		end
	end

	function clientBypass.findStaminaModules()
		local seen = {}
		local list = {}
		local root = clientBypass.fetchRootModule()
		if isLiveMod(root) then
			clientBypass.patchMainClientModule(root)
			for _, obj in pairs(desc(root)) do
				clientBypass.addModuleCandidate(obj, seen, list)
			end
		end
		for rootMod in pairs(clientBypass.modRoots) do
			if isLiveMod(rootMod) then
				clientBypass.patchMainClientModule(rootMod)
				for _, obj in pairs(desc(rootMod)) do
					clientBypass.addModuleCandidate(obj, seen, list)
				end
			else
				clientBypass.modRoots[rootMod] = nil
			end
		end
		if type(getloadedmodules) == "function" then
			pcall(function()
				for _, mod in pairs(getloadedmodules()) do
					clientBypass.addModuleCandidate(mod, seen, list)
				end
			end)
		end
		if type(getnilinstances) == "function" then
			pcall(function()
				for _, obj in pairs(getnilinstances()) do
					clientBypass.addModuleCandidate(obj, seen, list)
				end
			end)
		end
		local lp = Plrs.LocalPlayer
		for _, root in pairs({ lp, lp and ffc(lp, "PlayerScripts"), lp and ffc(lp, "PlayerGui"), lp and ffc(lp, "Backpack"), Rep }) do
			for _, obj in pairs(desc(root)) do
				clientBypass.addModuleCandidate(obj, seen, list)
			end
		end
		return list
	end

	function clientBypass.applyStaminaModuleBypass()
		if st.infStamina ~= true and st.infNight ~= true then
			return 0
		end
		local n = 0
		local root = clientBypass.fetchRootModule()
		if isLiveMod(root) and clientBypass.patchMainClientModule(root) then
			n += 1
		end
		for _, mod in pairs(clientBypass.findStaminaModules()) do
			if clientBypass.patchStaminaModule(mod) then
				n += 1
			end
		end
		return n
	end

	function clientBypass.restoreStaminaSignals()
		for c in pairs(clientBypass.stamTk) do
			pcall(function()
				if type(c.Enable) == "function" then
					c:Enable()
				elseif c.Enabled ~= nil then
					c.Enabled = true
				end
			end)
			clientBypass.stamTk[c] = nil
		end
		local gst = clientBypass.gstmnaInst
		if clientBypass.gstmnaOwned == true and gst and gst.Parent and gst:IsA("BindableFunction") then
			pcall(function()
				gst.OnInvoke = nil
			end)
		end
		clientBypass.gstmnaOwned = false
		clientBypass.gstmnaInst = nil
	end

	function clientBypass.applyStaminaSignals()
		local gst = ffc(Rep, "GSTMNA")
		if gst and gst:IsA("BindableFunction") then
			if st.infStamina == true then
				pcall(function()
					gst.OnInvoke = clientBypass.gstmnaFn
					clientBypass.gstmnaOwned = true
					clientBypass.gstmnaInst = gst
				end)
			elseif clientBypass.gstmnaOwned == true and clientBypass.gstmnaInst == gst then
				pcall(function()
					gst.OnInvoke = nil
				end)
				clientBypass.gstmnaOwned = false
				clientBypass.gstmnaInst = nil
			end
		end
		local tk = ffc(Rep, "TKSMNA")
		if not (tk and tk:IsA("BindableEvent") and type(getconnections) == "function") then
			if st.infStamina ~= true then
				clientBypass.restoreStaminaSignals()
			end
			return false
		end
		local ok, cons = pcall(getconnections, tk.Event)
		if not ok or type(cons) ~= "table" then
			return false
		end
		for _, c in pairs(cons) do
			if st.infStamina == true then
				pcall(function()
					if type(c.Disable) == "function" then
						c:Disable()
						clientBypass.stamTk[c] = true
					elseif c.Enabled ~= nil then
						c.Enabled = false
						clientBypass.stamTk[c] = true
					end
				end)
			elseif clientBypass.stamTk[c] then
				pcall(function()
					if type(c.Enable) == "function" then
						c:Enable()
					elseif c.Enabled ~= nil then
						c.Enabled = true
					end
				end)
				clientBypass.stamTk[c] = nil
			end
		end
		return true
	end

	function clientBypass.applyFullbright()
		if st.fullbright ~= true then
			if clientBypass.fullbrightOn == true then
				clientBypass.fullbrightOn = false
				pcall(function()
					local o = clientBypass.originals
					if o.Lighting_Brightness ~= nil then Lit.Brightness = o.Lighting_Brightness end
					if o.Lighting_ClockTime ~= nil then Lit.ClockTime = o.Lighting_ClockTime end
					if o.Lighting_Ambient ~= nil then Lit.Ambient = o.Lighting_Ambient end
					if o.Lighting_OutdoorAmbient ~= nil then Lit.OutdoorAmbient = o.Lighting_OutdoorAmbient end
					if o.Lighting_FogStart ~= nil then Lit.FogStart = o.Lighting_FogStart end
					if o.Lighting_FogEnd ~= nil then Lit.FogEnd = o.Lighting_FogEnd end
					if o.Lighting_GlobalShadows ~= nil then Lit.GlobalShadows = o.Lighting_GlobalShadows end
				end)
			end
			return false
		end
		pcall(function()
			clientBypass.fullbrightOn = true
			local o = clientBypass.originals
			if o.Lighting_Brightness == nil then o.Lighting_Brightness = Lit.Brightness end
			if o.Lighting_ClockTime == nil then o.Lighting_ClockTime = Lit.ClockTime end
			if o.Lighting_Ambient == nil then o.Lighting_Ambient = Lit.Ambient end
			if o.Lighting_OutdoorAmbient == nil then o.Lighting_OutdoorAmbient = Lit.OutdoorAmbient end
			if o.Lighting_FogStart == nil then o.Lighting_FogStart = Lit.FogStart end
			if o.Lighting_FogEnd == nil then o.Lighting_FogEnd = Lit.FogEnd end
			if o.Lighting_GlobalShadows == nil then o.Lighting_GlobalShadows = Lit.GlobalShadows end
			Lit.Brightness = 3
			Lit.ClockTime = 14
			Lit.Ambient = Color3.new(1, 1, 1)
			Lit.OutdoorAmbient = Color3.new(1, 1, 1)
			Lit.FogStart = 0
			Lit.FogEnd = 9e9
			Lit.GlobalShadows = false
		end)
		return true
	end

	function clientBypass.applyCharBypasses()
		local hum = getHum()
		local ch = getChar()
		if not ch or not hum then
			return false
		end
		if st.noDowned == true then
			pcall(function()
				local d = ffc(ch, "Downed")
				if d and d:IsA("BoolValue") then
					d.Value = false
				end
				local rt = ffc(ch, "RagdollTime")
				local sw = rt and ffc(rt, "RagdollSwitch")
				if sw and sw:IsA("BoolValue") then
					sw.Value = false
				end
			end)
		end
		if st.noTrapLock == true then
			pcall(function()
				hum:SetAttribute("iTRPED", nil)
				hum:SetAttribute("iTRPED3", nil)
				hum:SetAttribute("TrapPos", nil)
				hum:SetAttribute("TrapRelease", true)
				Run:UnbindFromRenderStep("YawBind")
			end)
		end
		if st.noDowned == true or st.noMoveLock == true or st.noTrapLock == true then
			pcall(function()
				hum.PlatformStand = false
				hum.Sit = false
				hum.AutoRotate = true
			end)
		end
		if st.noMoveLock == true then
			pcall(function()
				local ws = math.clamp(tonumber(st.spd) or 16, 1, 30)
				if hum.WalkSpeed <= 1 then
					hum.WalkSpeed = ws
				end
				if hum.UseJumpPower ~= false and hum.JumpPower <= 1 then
					hum.JumpPower = 35
				elseif hum.UseJumpPower == false and hum.JumpHeight <= 1 then
					hum.JumpHeight = 7.2
				end
			end)
		end
		return true
	end

	function clientBypass.applySafeRecover()
		if st.safeRecover ~= true then
			return false
		end
		local hum = getHum()
		local root = GET_HRP()
		if not hum or not root then
			return false
		end
		local y = root.Position.Y
		local lim = tonumber(Ws.FallenPartsDestroyHeight) or -500
		local grounded = hum.FloorMaterial ~= Enum.Material.Air and hum.Health > 0 and y > lim + 35
		if grounded then
			clientBypass.lastSafe = root.CFrame
			return true
		end
		local vel = root.AssemblyLinearVelocity
		if y <= lim + 30 or vel.Y <= -175 then
			local cf = clientBypass.lastSafe
			if cf then
				pcall(function()
					root.CFrame = cf + Vector3.new(0, 4, 0)
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
				end)
				return true
			end
		end
		return false
	end

	function clientBypass.pathHas(obj, a, b)
		local ok, path = pcall(function()
			return obj:GetFullName():lower()
		end)
		if not ok or type(path) ~= "string" then
			return false
		end
		return path:find(a, 1, true) ~= nil or (b and path:find(b, 1, true) ~= nil)
	end


	function clientBypass.isCH(t)
		return type(t) == "table"
			and rawget(t, "plr") == Plrs.LocalPlayer
			and type(rawget(t, "vars")) == "table"
			and type(rawget(t, "funcs")) == "table"
			and rawget(t, "CONFIG") ~= nil
	end

	function clientBypass.addCH(t)
		if clientBypass.isCH(t) then
			clientBypass.ch[t] = true
			return true
		end
		return false
	end

	function clientBypass.scanCH()
		if type(filtergc) == "function" then
			pcall(function()
				local one = filtergc("table", {
					Keys = { "plr", "vars", "funcs", "CONFIG" },
				}, true)
				clientBypass.addCH(one)
			end)
		end
		if type(getgc) == "function" then
			local ok, list = pcall(getgc, true)
			if ok and type(list) == "table" then
				for _, t in pairs(list) do
					clientBypass.addCH(t)
				end
			end
		end
	end

	function clientBypass.resetFx(x, hard)
		if typeof(x) ~= "Instance" then
			return false
		end
		pcall(function()
			if x:IsA("BlurEffect") then
				x.Size = 0
				x.Enabled = false
			elseif x:IsA("ColorCorrectionEffect") then
				if hard == true then
					x.Brightness = 0
					x.Contrast = 0
					x.Saturation = 0
					x.TintColor = Color3.new(1, 1, 1)
				end
				x.Enabled = false
			end
		end)
		return true
	end

	function clientBypass.stopShake(x)
		if not x then
			return false
		end
		pcall(function()
			if type(x.StopSustained) == "function" then
				x:StopSustained(0)
			end
		end)
		pcall(function()
			if type(x.Stop) == "function" then
				x:Stop()
			end
		end)
		return true
	end

	function clientBypass.zeroSpring(x)
		if type(x) ~= "table" then
			return false
		end
		pcall(function()
			x.p = Vector3.zero
			x.v = Vector3.zero
			x.t = Vector3.zero
		end)
		return true
	end

	function clientBypass.clearTab(t)
		if type(t) ~= "table" then
			return
		end
		if table.clear then
			table.clear(t)
			return
		end
		for k in pairs(t) do
			t[k] = nil
		end
	end

	function clientBypass.patchCH(t)
		if not clientBypass.isCH(t) then
			clientBypass.ch[t] = nil
			return false
		end
		local vars = rawget(t, "vars")
		local cfg = rawget(t, "CONFIG")
		if st.infStamina == true and type(vars) == "table" then
			clientBypass.fillStamina(t)
		end
		if st.infNight == true then
			clientBypass.fillNvg(t)
		end
		if type(vars) == "table" then
			if st.noDowned == true then
				pcall(function()
					vars.downed = false
					vars.lastDowned = false
					vars.downedupbusy = false
					t.dead = false
					local d = rawget(vars, "downedV")
					if typeof(d) == "Instance" and d:IsA("BoolValue") then
						d.Value = false
					end
				end)
			end
			if st.noTrapLock == true then
				pcall(function()
					vars.rTrapped = false
					vars.trapCamTurn = false
					vars.trapCamPos = nil
					vars.sTrap = nil
					vars.interactHold = false
					vars.TTakeStamina = false
					Run:UnbindFromRenderStep("YawBind")
				end)
			end
			if st.noMoveLock == true or st.noJumpCooldown == true then
				pcall(function()
					vars.canMove = true
					vars.can_jump = true
					vars.can_jump2 = true
					vars.lastJump = 0
					vars.handlingSRegen = false
					vars.regeningS = false
					if st.noJumpCooldown == true then
						vars.stamina = clientBypass.cfgVal(cfg, "MAX_STAMINA", 100)
					end
				end)
			end
		end
		if st.noJumpscareCam == true then
			pcall(function()
				Run:UnbindFromRenderStep("JMPSCR")
				t.dead = false
				if type(t.sc) == "table" then
					t.sc.db = true
					t.sc.fov = 0
				end
				local cam = clientBypass.getCamera()
				if cam then
					cam.CameraType = Enum.CameraType.Custom
					if t.hum then
						cam.CameraSubject = t.hum
					end
				end
				clientBypass.restoreCoreGui()
			end)
		end
		if st.disableCameraBobbing == true then
			pcall(function()
				local camH = rawget(t, "camH")
				if type(camH) == "table" then
					clientBypass.patchMovementModule(rawget(camH, "DataModule"), true)
				end
				clientBypass.zeroSpring(rawget(t, "cameraspring"))
				clientBypass.zeroSpring(rawget(t, "cameraspring2"))
			end)
		else
			pcall(function()
				local camH = rawget(t, "camH")
				if type(camH) == "table" then
					clientBypass.patchMovementModule(rawget(camH, "DataModule"), false)
				end
			end)
		end
		if st.noChaseStatic == true then
			local rc = rawget(t, "rc")
			if type(rc) == "table" then
				pcall(function()
					rc.chasePlaying = false
					rc.spotted = false
					rc.spotted2 = false
					rc.turn = false
					rc.lastChaseT = 0
					rc.lastStaticFactor = 0
					if rc.fovV then rc.fovV.Value = 0 end
					for _, snd in pairs({ rc.static, rc.chase, rc.heartbeat }) do
						if typeof(snd) == "Instance" and snd:IsA("Sound") then
							snd.Volume = 0
							snd.Playing = false
						end
					end
				end)
			end
		end
		if st.disableMotionBlur == true or st.disableDeathFx == true or st.disableVisualFx == true or st.noChaseStatic == true then
			if type(vars) == "table" then
				clientBypass.resetFx(rawget(vars, "downBlur"), true)
				clientBypass.resetFx(rawget(vars, "downCC"), true)
			end
			local vi = rawget(t, "visualInstances")
			if type(vi) == "table" then
				for name, it in pairs(vi) do
					if type(it) == "table" then
						local hard = st.disableVisualFx == true or (st.disableDeathFx == true and (name == "Death" or name == "Susto"))
						if st.disableMotionBlur == true or hard then
							clientBypass.resetFx(rawget(it, "blur"), hard)
						end
						if hard then
							clientBypass.resetFx(rawget(it, "colorcorrection"), true)
						end
					end
				end
			end
		end
		if st.disableCameraShake == true then
			clientBypass.zeroSpring(rawget(t, "cameraspring"))
			clientBypass.zeroSpring(rawget(t, "cameraspring2"))
			clientBypass.stopShake(rawget(t, "lowHpShake"))
			clientBypass.stopShake(rawget(t, "staticShake"))
			clientBypass.stopShake(rawget(t, "vibrateShake"))
			clientBypass.clearTab(rawget(t, "vibrationShakesTable"))
			t.vibrationShakeRunning = false
		end
		if st.hideLocationPopups == true or st.hideScrapPopups == true or st.hideTrapGui == true then
			clientBypass.applyClientPopupBypasses()
		end
		clientBypass.forceCoreParts()
		return true
	end

	function clientBypass.applyCH(scan)
		local any = st.infStamina == true
			or st.infNight == true
			or st.disableMotionBlur == true
			or st.disableDeathFx == true
			or st.disableVisualFx == true
			or st.disableCameraShake == true
			or st.disableCameraBobbing == true
			or st.hideLocationPopups == true
			or st.forceBackpack == true
			or st.forceMouseIcon == true
			or st.forceTopbar == true
			or st.noDowned == true
			or st.noMoveLock == true
			or st.noTrapLock == true
			or st.noJumpCooldown == true
			or st.noJumpscareCam == true
			or st.noChaseStatic == true
		if any ~= true then
			return 0
		end
		if scan == true then
			clientBypass.scanCH()
		end
		local n = 0
		for t in pairs(clientBypass.ch) do
			if clientBypass.patchCH(t) then
				n += 1
			end
		end
		return n
	end

	function clientBypass.removeIntroClones()
		if st.disableMenuReopen ~= true then
			return 0
		end
		local lp = Plrs.LocalPlayer
		local ps = lp and ffc(lp, "PlayerScripts")
		if not ps then
			return 0
		end
		local n = 0
		for _, obj in pairs(kids(ps)) do
			if obj.Name == "IntroHandler" then
				n += 1
				safeDestroy(obj)
			end
		end
		return n
	end

	local function onNewDesc(obj)
		if st.promptBypass == true and obj:IsA("ProximityPrompt") then
			task.defer(clientBypass.unlockPrompt, obj)
		end
		if obj:IsA("Sound") and clientBypass.shouldMuteSound(obj) then
			task.defer(clientBypass.muteSound, obj)
		end
		if st.knownPromptBypass == true and obj:IsA("ProximityPrompt") then
			task.defer(clientBypass.applyKnownGamePrompts)
		end
		if (st.hideScrapPopups == true or st.hideTrapGui == true or st.hideLocationPopups == true) and (obj:IsA("ScreenGui") or obj:IsA("GuiObject")) then
			task.defer(clientBypass.applyClientPopupBypasses)
		end
		if (obj:IsA("Light") or obj:IsA("BasePart")) and (st.flashlightNoShadows == true or st.flashlightBoost == true) then
			task.defer(clientBypass.applyLightToolBypasses)
		end
		if st.fovUiFix == true and obj:IsA("BillboardGui") and type(clientBypass.patchFovUi) == "function" then
			task.defer(clientBypass.patchFovUi, obj)
		end
	end

	bind(Ws.DescendantAdded, onNewDesc)
	local curPg = clientBypass.getPlayerGui()
	if curPg then
		bind(curPg.DescendantAdded, onNewDesc)
	end

	bind(Ws:GetPropertyChangedSignal("CurrentCamera"), function()
		task.defer(function()
			clientBypass.applyMotionBlurBypass()
			clientBypass.applyMenuFxBypass()
			clientBypass.applyDeathFxBypass()
		end)
	end)




	local function openhousedoor()
		for i = 1,1 do
			local lastpos = Plrs.LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame

			SET_HRP_CFRAME(Ws.Map.SafeHouse.Door.Door.CFrame+Vector3.new(0,-7,0))
			wait()
			SET_HRP_ANCHORED(true)
			wait(.4)
			local ohString1 = "Door"

			workspace.Map.SafeHouse.Door.RemoteEvent:FireServer(ohString1)
			wait(.4)
			SET_HRP_CFRAME(lastpos)
			wait()
			SET_HRP_ANCHORED(false)
			wait(.4)
		end
	end

	local function MOUSETP()
		local mouse = Plrs.LocalPlayer:GetMouse()

		local tweenService = Tws
		local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0)
		local part = Plrs.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
		local goal = {CFrame = CFrame.new(mouse.Hit.Position)}
		local tween = __lt.cm("TweenService", "Create", part, tweenInfo, goal)
		tween:Play()
	end

	local function opencrate()
		local ohString1 = "Open"
		local ohBoolean2 = true

		Rep.SupplyClientEvent:FireServer(ohString1, ohBoolean2)
	end

	local function dropRoot()
		local debris = ffc(Ws, "Debris")
		if not debris then
			return nil
		end
		return ffc(debris, "SupplyCrates") or ffc(debris, "SupplyCreates")
	end

	local function isDropBox(v)
		return v and v.Name == "Box" and v:IsA("Model")
	end

	local function eachDrop(fn)
		local root = dropRoot()
		if not root or type(fn) ~= "function" then
			return 0
		end
		local n = 0
		local hit = {}
		local function run(box)
			if box and not hit[box] and isDropBox(box) then
				hit[box] = true
				n += 1
				pcall(fn, box)
			end
		end
		run(ffc(root, "Box"))
		for _, box in pairs(kids(root)) do
			run(box)
		end
		if n <= 0 then
			for _, box in pairs(desc(root)) do
				run(box)
			end
		end
		return n
	end

	local function eachTrap(fn)
		local debris = ffc(Ws, "Debris")
		local traps = debris and ffc(debris, "Traps")
		if not traps or type(fn) ~= "function" then
			return 0
		end
		local n = 0
		for _, trap in pairs(kids(traps)) do
			if trap and trap.Name == "RakeTrapModel" then
				n += 1
				pcall(fn, trap)
			end
		end
		return n
	end

	local function fastPrompt(prompt, attrs)
		if not prompt then
			return false
		end
		local ok = pcall(function()
			if not prompt:IsA("ProximityPrompt") then
				error("bad prompt")
			end
			clientBypass.cachePromptHold(prompt)
			local keepHold = clientBypass.isHoldRequiredPrompt(prompt)
			local dist = math.clamp(tonumber(st.promptDistance) or 25, 5, 100)
			prompt.Enabled = true
			if keepHold then
				clientBypass.restorePromptHold(prompt)
			else
				prompt.HoldDuration = 0
			end
			prompt.RequiresLineOfSight = false
			prompt.ClickablePrompt = true
			prompt.MaxActivationDistance = dist
			prompt:SetAttribute("ODistance", dist)
		end)
		if ok and attrs == true then
			pcall(function()
				prompt:SetAttribute("Busy", false)
				prompt:SetAttribute("Busy2", false)
				prompt:SetAttribute("Unavailable", false)
				prompt:SetAttribute("Unavailable2", false)
			end)
		end
		return ok
	end

	local function fastDrop(box)
		local gui = ffc(box, "GUIPart")
		local ok = fastPrompt(gui and ffca(gui, "ProximityPrompt"), true)
		if not ok then
			fastPrompt(ffca(box, "ProximityPrompt"), true)
		end
		local unlock = ffc(box, "UnlockValue")
		if unlock then
			unlock.Value = 100
		end
	end

	local function trapPrompt(prompt)
		if fastPrompt(prompt, false) then
			return true
		end
		return false
	end

	local function fastTrap(trap)
		local hit = ffcr(trap, "HitBox")
		local att = hit and ffcr(hit, "Attachment")
		local prompt = att and ffca(att, "ProximityPrompt")
		if not prompt and trap then
			prompt = ffca(trap, "ProximityPrompt")
		end
		trapPrompt(prompt)
	end

	local function fastDoorLever()
		local map = ffc(Ws, "Map")
		local safe = map and ffc(map, "SafeHouse")
		local door = safe and ffc(safe, "Door")
		local lever = door and ffc(door, "DoorLever")
		local gui = lever and ffcr(lever, "DoorGUIPart")
		local prompt = gui and ffca(gui, "ProximityPrompt") or ffca(lever, "ProximityPrompt")
		if prompt then
			pcall(function()
				prompt.RequiresLineOfSight = false
				prompt.MaxActivationDistance = 10
			end)
		end
	end

	local function aigoto(pos : Vector3)
		local path = __lt.cm("PathfindingService", "CreatePath")

		path:ComputeAsync(Plrs.LocalPlayer.Character:WaitForChild("HumanoidRootPart").Position,pos)

		local waypoints = path:GetWaypoints()

		for i,v in pairs(waypoints) do
			getHum():MoveTo(v.Position)
		end
	end


	local function restorepower()
		local lastpos = Plrs.LocalPlayer.Character:WaitForChild("HumanoidRootPart").CFrame
		wait()
		for i = 1,1000 do
			SET_HRP_CFRAME(CFrame.new(-280.808014, 20.3924561, -212.159821, -0.10549771, -1.16743761e-08, -0.994419575, 9.45945828e-08, 1, -2.17754046e-08, 0.994419575, -9.63639621e-08, -0.10549771))
		end
		SET_HRP_ANCHORED(true)
		wait()
		local ohString1 = "StationStart"

		workspace.Map.PowerStation.StationFolder.RemoteEvent:FireServer(ohString1)
		wait(20)
		SET_HRP_ANCHORED(false)
	end



	local function airdropchams(mode)
		if tostring(mode) == "Enable" then
			eachDrop(function(box)
				if not ffc(box, "SleepyDropChams") then
					local chams = Instance.new("Highlight")
					chams.FillColor = Color3.new(0.317647, 1, 0)
					chams.OutlineColor = Color3.new(0, 1, 0.250980)
					chams.Parent = box
					chams.Adornee = box
					chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					chams.OutlineTransparency = 0
					chams.FillTransparency = 1
					chams.Name = "SleepyDropChams"
				end
			end)
		elseif tostring(mode) == "Disable" then
			local root = dropRoot()
			for _, v in pairs(desc(root)) do
				if v.Name == "SleepyDropChams" then
					v:Destroy()
				end
			end
		end

	end

	local function rakechams()
		local rk = ffcr(Ws, "Rake")
		if rk then
			if ffcr(rk, "SleepyRakeChams") then

			else
				local chams = Instance.new("Highlight")
				chams.FillColor = Color3.new(170, 0, 0)
				chams.OutlineColor = Color3.fromRGB(255,255,255)
				chams.Parent = rk
				chams.Adornee = rk
				chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				chams.OutlineTransparency = .9
				chams.FillTransparency = 0.5
				chams.Name = "SleepyRakeChams"
			end

		end

	end

	local function disablerakechams()
		local rk = ffcr(Ws, "Rake")
		local chams = ffcr(rk, "SleepyRakeChams")
		safeDestroy(chams)
	end



	clientBypass.buildUi = function()
	local RunService = ClonedService("RunService")
	local InputService = ClonedService("UserInputService")
	local FreeCamPart





	pcall(function() genv.RakeGui = true end)


	local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
	local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
	local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
	Library.ShowCustomCursor = st.uiCursor == true
	Library.ShowToggleFrameInKeybinds = st.uiToggleFrames == true
	Library.CantDragForced = st.uiDragLock == true
	local Options = Library.Options
	local Toggles = Library.Toggles
	local canCfg = fileApi
	local Obsidian = {}
	local uiNum = 0

	local function uiKey(flag, name)
		uiNum += 1
		local key = tostring(flag or name or ("Item" .. uiNum)):gsub("%s+", "_"):gsub("[^%w_]", "")
		if key == "" then
			key = "Item" .. uiNum
		end
		return "Rake_" .. key .. "_" .. tostring(uiNum)
	end

	local function uiPrec(v)
		local n = tonumber(v) or 0
		if n <= 0 then
			return 0
		end
		local s = tostring(n)
		local p = s:find(".", 1, true)
		if not p then
			return 0
		end
		return math.clamp(#s - p, 0, 4)
	end


	local function uiWrap(obj)
		return setmetatable({ _obj = obj }, {
			__index = function(t, k)
				if k == "Set" then
					return function(_, v)
						local o = rawget(t, "_obj")
						pcall(function()
							if o and o.SetValue then
								o:SetValue(v)
							elseif o and o.Set then
								o:Set(v)
							elseif o and o.SetText then
								o:SetText(tostring(v))
							end
						end)
					end
				end
				if k == "SetText" then
					return function(_, v)
						local o = rawget(t, "_obj")
						pcall(function()
							if o and o.SetText then
								o:SetText(tostring(v))
							elseif o and o.Set then
								o:Set(tostring(v))
							end
						end)
					end
				end
				local o = rawget(t, "_obj")
				local v = o and o[k]
				if type(v) == "function" then
					return function(_, ...)
						return v(o, ...)
					end
				end
				return v
			end
		})
	end

	local function makeUiTab(tab, group)
		local t = { __tab = tab, __group = group }

		function t:CreateLabel(text)
			local id = uiKey(nil, text)
			local ok, obj = pcall(function()
				return group:AddLabel(tostring(text or ""), true, id)
			end)
			return uiWrap((ok and obj) or Options[id])
		end

		function t:CreateDivider()
			pcall(function()
				group:AddDivider()
			end)
			return uiWrap(nil)
		end

		function t:CreateButton(info)
			info = type(info) == "table" and info or { Name = tostring(info or "Button") }
			local text = tostring(info.Name or info.Text or "Button")
			local cb = info.Callback or info.Func
			local ok, obj = pcall(function()
				return group:AddButton({
					Text = text,
					Func = function()
						if cb then
							cb()
						end
					end,
					DoubleClick = false,
				})
			end)
			if not ok then
				pcall(function()
					obj = group:AddButton(text, function()
						if cb then
							cb()
						end
					end)
				end)
			end
			return uiWrap(obj)
		end

		function t:CreateToggle(info)
			info = type(info) == "table" and info or {}
			local id = uiKey(info.Flag, info.Name)
			local cb = info.Callback
			pcall(function()
				group:AddToggle(id, {
					Text = tostring(info.Name or info.Text or "Toggle"),
					Default = info.CurrentValue == true or info.Default == true,
					Callback = function(v)
						if cb then
							cb(v)
						end
					end,
				})
			end)
			return uiWrap(Toggles[id] or Options[id])
		end

		function t:CreateSlider(info)
			info = type(info) == "table" and info or {}
			local range = type(info.Range) == "table" and info.Range or { 0, 100 }
			local min = tonumber(range[1]) or 0
			local max = tonumber(range[2]) or 100
			local id = uiKey(info.Flag, info.Name)
			local cb = info.Callback
			pcall(function()
				group:AddSlider(id, {
					Text = tostring(info.Name or info.Text or "Slider"),
					Default = tonumber(info.CurrentValue or info.Default) or min,
					Min = min,
					Max = max,
					Rounding = uiPrec(info.Increment),
					Callback = function(v)
						if cb then
							cb(v)
						end
					end,
				})
			end)
			return uiWrap(Options[id])
		end

		function t:CreateDropdown(info)
			info = type(info) == "table" and info or {}
			local vals = type(info.Values) == "table" and info.Values or {}
			local id = uiKey(info.Flag, info.Name)
			local cb = info.Callback
			local def = info.CurrentOption or info.CurrentValue or info.Default or vals[1]
			pcall(function()
				group:AddDropdown(id, {
					Values = vals,
					Default = def,
					Multi = info.Multi == true,
					Text = tostring(info.Name or info.Text or "Dropdown"),
					Searchable = info.Searchable == true,
					Callback = function(v)
						if cb then
							cb(v)
						end
					end,
				})
			end)
			return uiWrap(Options[id])
		end

		function t:CreateKeybind(info)
			info = type(info) == "table" and info or {}
			local id = uiKey(info.Flag, info.Name)
			local cb = info.Callback
			local label
			pcall(function()
				label = group:AddLabel(tostring(info.Name or "Keybind"))
			end)
			local obj
			pcall(function()
				obj = label:AddKeyPicker(id, {
					Default = tostring(info.CurrentKeybind or info.Default or "None"),
					Mode = tostring(info.Mode or (info.HoldToInteract and "Hold" or "Press")),
					Text = tostring(info.Name or "Keybind"),
					NoUI = info.NoUI == true,
					Callback = function(v)
						if cb then
							cb(v)
						end
					end,
				})
			end)
			local wrapped = uiWrap(Options[id] or obj)
			wrapped.__id = id
			return wrapped
		end

		return t
	end

	function Obsidian:Notify(info)
		info = type(info) == "table" and info or {}
		pcall(function()
			Library:Notify({
				Title = tostring(info.Title or "Notification"),
				Description = tostring(info.Content or info.Description or info.Text or ""),
				Time = tonumber(info.Duration or info.Time) or 3,
			})
		end)
	end

	function Obsidian:Destroy()
		pcall(function()
			Library:Unload()
		end)
	end

	function Obsidian:LoadConfiguration()
		return nil
	end

	function Obsidian:CreateWindow(info)
		info = type(info) == "table" and info or {}
		local raw = Library:CreateWindow({
			Title = tostring(info.Name or info.Title or "Project [The Rake]"),
			Footer = tostring(info.LoadingSubtitle or "Sleepy Hub"),
			NotifySide = "Right",
			ShowCustomCursor = st.uiCursor == true,
			AutoShow = true,
			Center = true,
			Resizable = st.uiResizable == true,
			ToggleKeybind = uiKeyCode(st.uiBind, Enum.KeyCode.RightControl),
			ShowMobileButtons = st.uiMobileButtons == true,
			MobileButtonsSide = st.uiMobileRight == true and "Right" or "Left",
			UnlockMouseWhileOpen = st.uiUnlockMouse == true,
			DisableSearch = st.uiSearchBar ~= true,
			GlobalSearch = st.uiGlobalSearch == true,
			EnableSidebarResize = st.uiSidebarResize == true,
			EnableCompacting = st.uiCompacting == true,
			DisableCompactingSnap = st.uiNoSnap == true,
			SidebarCompacted = st.uiCompact == true,
			CornerRadius = st.uiCorner or 4,
		})
		Obsidian.RawWindow = raw
		local icons = {
			Main = "user",
			Settings = "settings",
			Radio = "radio",
		}
		local w = { __window = raw }
		function w:CreateTab(name, icon, noGroup)
			local iconName = icons[tostring(name)] or (type(icon) == "string" and icon) or "circle"
			local rawTab = raw:AddTab(tostring(name or "Tab"), iconName)
			if noGroup == true then
				return { __tab = rawTab }
			end
			local group = rawTab:AddLeftGroupbox(tostring(name or "Tab"), iconName)
			return makeUiTab(rawTab, group)
		end
		return w
	end

	local Window = Obsidian:CreateWindow({
		Name = "Project [The Rake]",
		LoadingSubtitle = "Sleepy Hub",
	})

	pcall(function()
		Library:SetDPIScale(st.uiDpi or 100)
	end)

	--Tabs
	local MainTab = Window:CreateTab("Main", 11252440515, true)
	local RadioTab = Window:CreateTab("Radio", "radio", true)
	local SettingsTab = Window:CreateTab("Settings", 11252440305)
	local PlayerTab = MainTab
	local ClientTab = MainTab
	local ExploitsTab = MainTab

	if MainTab and MainTab.__tab then
		local rawMain = MainTab.__tab
		local okPlayer, playerGroup = pcall(function()
			return rawMain:AddLeftGroupbox("Player", "user")
		end)
		local okClient, clientGroup = pcall(function()
			return rawMain:AddRightGroupbox("Client", "monitor")
		end)
		local okExploits, exploitsGroup = pcall(function()
			return rawMain:AddLeftGroupbox("Exploits", "skull")
		end)

		if okPlayer and playerGroup then
			PlayerTab = makeUiTab(rawMain, playerGroup)
		end
		if okClient and clientGroup then
			ClientTab = makeUiTab(rawMain, clientGroup)
		end
		if okExploits and exploitsGroup then
			ExploitsTab = makeUiTab(rawMain, exploitsGroup)
		end
	end

	local ObsidianSettingsTab

	pcall(function()
		ThemeManager:SetLibrary(Library)
		ThemeManager:SetFolder("ProjectTheRake")
		if SettingsTab and SettingsTab.__tab then
			ThemeManager:ApplyToTab(SettingsTab.__tab)
			ObsidianSettingsTab = makeUiTab(SettingsTab.__tab, SettingsTab.__tab:AddRightGroupbox("Obsidian UI", "settings"))
		end
	end)

	ObsidianSettingsTab = ObsidianSettingsTab or SettingsTab

	local function blankObj()
		return setmetatable({}, {
			__index = function()
				return function() end
			end
		})
	end

	local function safeTab(tab, name)
		return setmetatable({}, {
			__index = function(_, k)
				local v = tab and tab[k]
				if type(v) == "function" then
					return function(_, ...)
						local ok, res = pcall(v, tab, ...)
						if ok then
							return res or blankObj()
						end
						pcall(warn, "[RakeGui] " .. tostring(name) .. "." .. tostring(k) .. " failed:", res)
						return blankObj()
					end
				end
				return v
			end
		})
	end

	MainTab = safeTab(MainTab, "Main")
	PlayerTab = safeTab(PlayerTab, "Player")
	ClientTab = safeTab(ClientTab, "Client")
	ExploitsTab = safeTab(ExploitsTab, "Exploits")
	SettingsTab = safeTab(SettingsTab, "Settings")
	ObsidianSettingsTab = safeTab(ObsidianSettingsTab, "ObsidianSettings")

	local radioRows = {}
	local radioList
	local radioLayout
	local radioEmpty
	local radioEmptyText = "Waiting for radio messages..."
	local radioMaxRows = 200
	local radioSounds = {
		"rbxassetid://103856279160788",
		"rbxassetid://88017109520003",
		"rbxassetid://131718170793766",
		"rbxassetid://103338553714052",
	}

	local function richEscape(v)
		local s = tostring(v or "")
		s = s:gsub("&", "&amp;")
		s = s:gsub("<", "&lt;")
		s = s:gsub(">", "&gt;")
		return s
	end

	local function radioName(sender)
		if typeof(sender) == "Instance" and sender:IsA("Player") then
			local username = tostring(sender.Name or "Unknown")
			local display = tostring(sender.DisplayName or username)
			if display == username then
				return "@" .. username
			end
			return display .. " (@" .. username .. ")"
		end
		return tostring(sender or "Unknown")
	end

	local function radioStoredName(name)
		local username = tostring(name or "")
		username = username:gsub("%s*:+%s*$", "")
		if username == "" then
			return ""
		end
		local player = ffc(Plrs, username)
		if player and player:IsA("Player") then
			return radioName(player)
		end
		return username
	end

	local function updateRadioCanvas()
		if not radioList or not radioLayout then
			return
		end
		local function apply()
			if not radioList or not radioLayout then
				return
			end
			local h = radioLayout.AbsoluteContentSize.Y + 8
			radioList.CanvasSize = UDim2.new(0, 0, 0, h)
			radioList.CanvasPosition = Vector2.new(0, math.max(0, h - radioList.AbsoluteWindowSize.Y))
		end
		if type(task) == "table" and type(task.defer) == "function" then
			task.defer(apply)
		else
			apply()
		end
	end

	local function clearRadioMessages()
		for i = #radioRows, 1, -1 do
			safeDestroy(radioRows[i])
			radioRows[i] = nil
		end
		if radioList and not radioEmpty then
			radioEmpty = Instance.new("TextLabel")
			radioEmpty.Name = "Empty"
			radioEmpty.BackgroundTransparency = 1
			radioEmpty.Font = Enum.Font.SourceSans
			radioEmpty.Text = radioEmptyText
			radioEmpty.TextColor3 = Color3.fromRGB(180, 180, 180)
			radioEmpty.TextSize = 18
			radioEmpty.Size = UDim2.new(1, -8, 0, 32)
			radioEmpty.Position = UDim2.new(0, 4, 0, 8)
			radioEmpty.Parent = radioList
		end
		updateRadioCanvas()
	end

	local function pushRadioLine(name, message)
		if not radioList then
			return
		end
		if radioEmpty then
			safeDestroy(radioEmpty)
			radioEmpty = nil
		end
		name = tostring(name or "")
		message = tostring(message or "")
		if name == "" and message == "" then
			return
		end

		local row = Instance.new("Frame")
		row.Name = "RadioMessage"
		row.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
		row.BackgroundTransparency = 0.12
		row.BorderColor3 = Color3.fromRGB(28, 28, 28)
		row.Size = UDim2.new(1, -8, 0, 36)
		row.Parent = radioList

		local text = Instance.new("TextLabel")
		text.Name = "Text"
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.SourceSans
		text.RichText = true
		text.TextColor3 = Color3.fromRGB(245, 245, 245)
		text.TextSize = 24
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.TextYAlignment = Enum.TextYAlignment.Center
		text.TextTruncate = Enum.TextTruncate.AtEnd
		text.Size = UDim2.new(1, -10, 1, 0)
		text.Position = UDim2.new(0, 6, 0, 0)
		text.Text = "<b>" .. richEscape(name) .. ":</b> " .. richEscape(message)
		text.Parent = row

		radioRows[#radioRows + 1] = row
		while #radioRows > radioMaxRows do
			local old = table.remove(radioRows, 1)
			safeDestroy(old)
		end
		updateRadioCanvas()
	end

	local function pushRadioMessage(sender, message)
		pushRadioLine(radioName(sender), message)
	end

	local function notifyRadioMessage(sender, message)
		if st.radioNotifications ~= true then
			return
		end
		Obsidian:Notify({
			Title = "Radio",
			Content = radioName(sender) .. ": " .. tostring(message or ""),
			Duration = 4,
		})
	end

	local function playRadioSound()
		if st.radioSounds ~= true or #radioSounds <= 0 then
			return
		end
		local sound = Instance.new("Sound")
		sound.Name = "RakeRadioMessageSound"
		sound.SoundId = radioSounds[math.random(1, #radioSounds)]
		sound.Volume = 1
		sound.Parent = Ws
		sound.Ended:Connect(function()
			safeDestroy(sound)
		end)
		pcall(function()
			sound:Play()
		end)
		if type(task) == "table" and type(task.delay) == "function" then
			task.delay(8, function()
				safeDestroy(sound)
			end)
		end
	end

	local function getRadioValue(line, valueName)
		local value = line and ffc(line, valueName)
		return tostring(valOf(value, "") or "")
	end

	local function hydrateRadioChannel()
		local channel = ffc(Rep, "RadioChannel")
		if not channel then
			return
		end
		clearRadioMessages()
		for i = 1, 7 do
			local line = ffc(channel, "Line" .. tostring(i))
			local name = getRadioValue(line, "Name")
			local msg = getRadioValue(line, "Msg")
			if name ~= "" or msg ~= "" then
				pushRadioLine(radioStoredName(name), msg)
			end
		end
	end

	local function makeRadioPanel()
		local root = Instance.new("Frame")
		root.Name = "RadioPanel"
		root.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
		root.BackgroundTransparency = 0.05
		root.BorderColor3 = Color3.fromRGB(24, 24, 24)
		root.Size = UDim2.new(1, 0, 0, 390)

		local header = Instance.new("TextLabel")
		header.Name = "Header"
		header.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		header.BackgroundTransparency = 0.15
		header.BorderColor3 = Color3.fromRGB(16, 16, 16)
		header.Font = Enum.Font.SourceSansBold
		header.Text = "RADIO"
		header.TextColor3 = Color3.fromRGB(255, 255, 255)
		header.TextSize = 30
		header.Size = UDim2.new(1, -8, 0, 40)
		header.Position = UDim2.new(0, 4, 0, 4)
		header.Parent = root

		radioList = Instance.new("ScrollingFrame")
		radioList.Name = "Messages"
		radioList.Active = true
		radioList.BackgroundTransparency = 1
		radioList.BorderSizePixel = 0
		radioList.BottomImage = ""
		radioList.CanvasSize = UDim2.new(0, 0, 0, 0)
		radioList.MidImage = ""
		radioList.ScrollBarThickness = 5
		radioList.Size = UDim2.new(1, -8, 1, -52)
		radioList.Position = UDim2.new(0, 4, 0, 48)
		radioList.TopImage = ""
		radioList.Parent = root

		radioLayout = Instance.new("UIListLayout")
		radioLayout.Padding = UDim.new(0, 6)
		radioLayout.SortOrder = Enum.SortOrder.LayoutOrder
		radioLayout.Parent = radioList

		radioEmpty = Instance.new("TextLabel")
		radioEmpty.Name = "Empty"
		radioEmpty.BackgroundTransparency = 1
		radioEmpty.Font = Enum.Font.SourceSans
		radioEmpty.Text = radioEmptyText
		radioEmpty.TextColor3 = Color3.fromRGB(180, 180, 180)
		radioEmpty.TextSize = 18
		radioEmpty.Size = UDim2.new(1, -8, 0, 32)
		radioEmpty.Position = UDim2.new(0, 4, 0, 8)
		radioEmpty.Parent = radioList

		return root
	end

	local function applyRadioFullWidth()
		local tab = RadioTab and RadioTab.__tab
		local sides = tab and tab.Sides
		local left = sides and sides[1]
		local right = sides and sides[2]
		if left then
			left.Visible = true
			left.Size = UDim2.new(1, 0, 1, 0)
		end
		if right then
			right.Visible = false
			right.Size = UDim2.new(0, 0, 1, 0)
		end
	end

	pcall(function()
		if RadioTab and RadioTab.__tab then
			local refreshSides = RadioTab.__tab.RefreshSides
			if type(refreshSides) == "function" then
				RadioTab.__tab.RefreshSides = function(tab, ...)
					local result = refreshSides(tab, ...)
					applyRadioFullWidth()
					return result
				end
			end
			applyRadioFullWidth()
			local group = RadioTab.__tab:AddLeftGroupbox("Radio", "radio")
			local panel = makeRadioPanel()
			group:AddUIPassthrough("RadioLog", {
				Instance = panel,
				Height = 400,
				Visible = true,
			})
			group:AddToggle("Rake_RadioSounds", {
				Text = "Message sounds",
				Default = st.radioSounds == true,
				Callback = function(v)
					st.radioSounds = v == true
					cfgSet("radioSounds", st.radioSounds)
				end,
			})
			group:AddToggle("Rake_RadioNotifications", {
				Text = "Message notifications",
				Default = st.radioNotifications == true,
				Callback = function(v)
					st.radioNotifications = v == true
					cfgSet("radioNotifications", st.radioNotifications)
				end,
			})
			applyRadioFullWidth()
		end
	end)

	local radioRemote
	local function attachRadioRemote(remote)
		if radioRemote == remote or not remote or not remote:IsA("RemoteEvent") then
			return
		end
		radioRemote = remote
		bind(remote.OnClientEvent, function(sender, message)
			pushRadioMessage(sender, message)
			playRadioSound()
			notifyRadioMessage(sender, message)
		end)
	end

	attachRadioRemote(ffc(Rep, "RadioChatEvent"))
	bind(Rep.ChildAdded, function(child)
		if child.Name == "RadioChatEvent" then
			attachRadioRemote(child)
		end
	end)
	hydrateRadioChannel()
	bind(Rep.ChildAdded, function(child)
		if child.Name == "RadioChannel" then
			hydrateRadioChannel()
		end
	end)

	local infoBubble
	local infoLbl
	local infoRoot
	local infoDrag
	local infoTgt = "Rake's Target : ?"
	local infoTime = "Time Until Day : ?"
	local infoPower = "Power : ?"

	local function fmtTime(v)
		v = math.max(0, math.floor(tonumber(v) or 0))
		local h = math.floor(v / 3600)
		local m = math.floor((v % 3600) / 60)
		local s = v % 60
		if h > 0 then
			return string.format("%d:%02d:%02d", h, m, s)
		end
		return string.format("%d:%02d", m, s)
	end

	local function fmtPower(v)
		local pct = math.max(0, (tonumber(v) or 1000) / 10)
		if pct % 1 == 0 then
			return tostring(math.floor(pct))
		end
		return string.format("%.1f", pct)
	end

	local function infoText()
		return infoTgt .. "\n" .. infoTime .. "\n" .. infoPower
	end

	local function bubbleParent()
		local ok, hui = pcall(function()
			if type(gethui) == "function" then
				return gethui()
			end
		end)
		if ok and typeof(hui) == "Instance" then
			return hui
		end
		local pg = clientBypass.getPlayerGui()
		if pg then
			return pg
		end
		local ok2, cg = pcall(function()
			return ClonedService("CoreGui")
		end)
		if ok2 and cg then
			return cg
		end
		return nil
	end

	local function makeBubble()
		if infoRoot and infoRoot.Parent and infoLbl and infoLbl.Parent then
			return infoRoot
		end
		local par = bubbleParent()
		if not par then
			return nil
		end
		local gui = par:FindFirstChild("__RakeInfoBubbleGui")
		if not gui then
			gui = Instance.new("ScreenGui")
			gui.Name = "__RakeInfoBubbleGui"
			gui.ResetOnSpawn = false
			gui.IgnoreGuiInset = true
			gui.DisplayOrder = 999999
			gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			gui.Parent = par
		end
		local root = gui:FindFirstChild("Bubble")
		if not root then
			root = Instance.new("Frame")
			root.Name = "Bubble"
			root.Size = UDim2.fromOffset(210, 72)
			root.Position = UDim2.fromOffset(94, 96)
			root.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
			root.BackgroundTransparency = 0.12
			root.BorderSizePixel = 0
			root.Active = true
			root.Visible = st.infoBubble == true
			root.Parent = gui
			local cr = Instance.new("UICorner")
			cr.CornerRadius = UDim.new(0, 8)
			cr.Parent = root
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 1
			stroke.Transparency = 0.55
			stroke.Color = Color3.fromRGB(140, 95, 255)
			stroke.Parent = root
			local pad = Instance.new("UIPadding")
			pad.PaddingTop = UDim.new(0, 8)
			pad.PaddingBottom = UDim.new(0, 8)
			pad.PaddingLeft = UDim.new(0, 10)
			pad.PaddingRight = UDim.new(0, 10)
			pad.Parent = root
		end
		local lbl = root:FindFirstChild("Text")
		if not lbl then
			lbl = Instance.new("TextLabel")
			lbl.Name = "Text"
			lbl.BackgroundTransparency = 1
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.Font = Enum.Font.Code
			lbl.TextSize = 14
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextYAlignment = Enum.TextYAlignment.Top
			lbl.TextColor3 = Color3.fromRGB(235, 235, 240)
			lbl.TextStrokeTransparency = 0.75
			lbl.TextWrapped = false
			lbl.RichText = false
			lbl.Parent = root
		end
		infoBubble = gui
		infoRoot = root
		infoLbl = lbl
		if not infoDrag or infoDrag.root ~= root then
			infoDrag = {on = false, root = root}
			bind(root.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					infoDrag.on = true
					infoDrag.input = input
					infoDrag.start = input.Position
					infoDrag.pos = root.Position
				end
			end)
			bind(root.InputEnded, function(input)
				if input == infoDrag.input then
					infoDrag.on = false
					infoDrag.input = nil
				end
			end)
			bind(InputService.InputChanged, function(input)
				if infoDrag.on ~= true or not infoDrag.input then
					return
				end
				if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
					return
				end
				local delta = input.Position - infoDrag.start
				root.Position = UDim2.new(infoDrag.pos.X.Scale, infoDrag.pos.X.Offset + delta.X, infoDrag.pos.Y.Scale, infoDrag.pos.Y.Offset + delta.Y)
			end)
		end
		return root
	end

	local function setBubbleVisible(v)
		local root = makeBubble()
		if root then
			root.Visible = v == true
		end
	end

	local function syncBubble()
		makeBubble()
		if infoLbl and infoLbl.Parent then
			infoLbl.Text = infoText()
		end
		setBubbleVisible(st.infoBubble)
	end

	local function setInfoTarget(txt)
		local v = tostring(txt or "Rake's Target : ?")
		if v == infoTgt then
			return
		end
		infoTgt = v
		syncBubble()
	end

	local function setInfoTime(txt)
		local v = tostring(txt or "Time Until Day : ?")
		if v == infoTime then
			return
		end
		infoTime = v
		syncBubble()
	end

	local function setInfoPower(txt)
		local v = tostring(txt or "Power : ?")
		if v == infoPower then
			return
		end
		infoPower = v
		syncBubble()
	end

	task.defer(function()
		syncBubble()
	end)


	local function saveNow()
		saveDirty = false
		return saveCfg(saved)
	end

	local function eachEspDraw(fn)
		if not esp then
			return
		end
		for _, it in pairs({ esp.flare, esp.rake }) do
			if it and it.d then
				pcall(fn, it.d)
			end
		end
		for _, bucket in pairs({ esp.players, esp.drops, esp.scraps }) do
			for _, it in pairs(bucket) do
				if it and it.d then
					pcall(fn, it.d)
				end
			end
		end
		for _, d in pairs(esp.locs) do
			if d then
				pcall(fn, d)
			end
		end
	end

	local function refreshEspStyle()
		eachEspDraw(function(d)
			d.Size = st.espSize
			d.Outline = false
		end)
	end

	local function rawWin()
		return Window and Window.__window or Obsidian.RawWindow
	end

	local function applyLayout()
		local w = rawWin()
		pcall(function()
			if w and w.ApplyLayout then
				w:ApplyLayout()
			end
		end)
	end

	local menuBind = ObsidianSettingsTab:CreateKeybind({
		Name = "UI Toggle Keybind",
		CurrentKeybind = st.uiBind,
		Flag = "Obsidian_MenuToggle",
		Mode = "Toggle",
		NoUI = true,
	})

	pcall(function()
		local opt = Options[menuBind.__id]
		if opt then
			Library.ToggleKeybind = opt
			opt:OnChanged(function()
				st.uiBind = uiKeyName(opt.Value, st.uiBind)
				cfgSet("uiBind", st.uiBind)
			end)
		end
	end)

	ObsidianSettingsTab:CreateToggle({
		Name = "Custom Cursor",
		CurrentValue = st.uiCursor,
		Flag = "Obsidian_CustomCursor",
		Callback = function(v)
			st.uiCursor = v == true
			uiBoolSet("uiCursor", st.uiCursor)
			Library.ShowCustomCursor = st.uiCursor
		end,
	})

	ObsidianSettingsTab:CreateToggle({
		Name = "Lock Window Dragging",
		CurrentValue = st.uiDragLock,
		Flag = "Obsidian_DragLock",
		Callback = function(v)
			st.uiDragLock = v == true
			uiBoolSet("uiDragLock", st.uiDragLock)
			Library.CantDragForced = st.uiDragLock
		end,
	})

	ObsidianSettingsTab:CreateToggle({
		Name = "Compact Sidebar",
		CurrentValue = st.uiCompact,
		Flag = "Obsidian_CompactSidebar",
		Callback = function(v)
			st.uiCompact = v == true
			uiBoolSet("uiCompact", st.uiCompact)
			pcall(function()
				local w = rawWin()
				if w and w.SetCompact then
					w:SetCompact(st.uiCompact)
				end
			end)
		end,
	})

	ObsidianSettingsTab:CreateToggle({
		Name = "Sidebar Resize Handle",
		CurrentValue = st.uiSidebarResize,
		Flag = "Obsidian_SidebarResize",
		Callback = function(v)
			st.uiSidebarResize = v == true
			uiBoolSet("uiSidebarResize", st.uiSidebarResize)
			local w = rawWin()
			pcall(function()
				if w then
					w.EnableSidebarResize = st.uiSidebarResize
				end
			end)
			applyLayout()
		end,
	})

	ObsidianSettingsTab:CreateToggle({
		Name = "Sidebar Compacting",
		CurrentValue = st.uiCompacting,
		Flag = "Obsidian_SidebarCompacting",
		Callback = function(v)
			st.uiCompacting = v == true
			uiBoolSet("uiCompacting", st.uiCompacting)
			local w = rawWin()
			pcall(function()
				if w then
					w.EnableCompacting = st.uiCompacting
				end
			end)
			applyLayout()
		end,
	})

	ObsidianSettingsTab:CreateToggle({
		Name = "Disable Compact Snap",
		CurrentValue = st.uiNoSnap,
		Flag = "Obsidian_NoCompactSnap",
		Callback = function(v)
			st.uiNoSnap = v == true
			uiBoolSet("uiNoSnap", st.uiNoSnap)
			local w = rawWin()
			pcall(function()
				if w then
					w.DisableCompactingSnap = st.uiNoSnap
				end
			end)
		end,
	})

	ObsidianSettingsTab:CreateToggle({
		Name = "Resizable Window",
		CurrentValue = st.uiResizable,
		Flag = "Obsidian_ResizableWindow",
		Callback = function(v)
			st.uiResizable = v == true
			uiBoolSet("uiResizable", st.uiResizable)
		end,
	})

	ObsidianSettingsTab:CreateToggle({
		Name = "Mobile Toggle/Lock Buttons",
		CurrentValue = st.uiMobileButtons,
		Flag = "Obsidian_MobileButtons",
		Callback = function(v)
			st.uiMobileButtons = v == true
			uiBoolSet("uiMobileButtons", st.uiMobileButtons)
		end,
	})

	ObsidianSettingsTab:CreateToggle({
		Name = "Mobile Buttons On Right",
		CurrentValue = st.uiMobileRight,
		Flag = "Obsidian_MobileRight",
		Callback = function(v)
			st.uiMobileRight = v == true
			uiBoolSet("uiMobileRight", st.uiMobileRight)
		end,
	})

	ObsidianSettingsTab:CreateToggle({
		Name = "Unlock Mouse While Open",
		CurrentValue = st.uiUnlockMouse,
		Flag = "Obsidian_UnlockMouse",
		Callback = function(v)
			st.uiUnlockMouse = v == true
			uiBoolSet("uiUnlockMouse", st.uiUnlockMouse)
		end,
	})

	ObsidianSettingsTab:CreateToggle({
		Name = "Search Bar",
		CurrentValue = st.uiSearchBar,
		Flag = "Obsidian_SearchBar",
		Callback = function(v)
			st.uiSearchBar = v == true
			uiBoolSet("uiSearchBar", st.uiSearchBar)
		end,
	})

	ObsidianSettingsTab:CreateToggle({
		Name = "Global Search",
		CurrentValue = st.uiGlobalSearch,
		Flag = "Obsidian_GlobalSearch",
		Callback = function(v)
			st.uiGlobalSearch = v == true
			uiBoolSet("uiGlobalSearch", st.uiGlobalSearch)
			Library.GlobalSearch = st.uiGlobalSearch
		end,
	})

	ObsidianSettingsTab:CreateToggle({
		Name = "Toggle Frames In Keybinds",
		CurrentValue = st.uiToggleFrames,
		Flag = "Obsidian_ToggleFrames",
		Callback = function(v)
			st.uiToggleFrames = v == true
			uiBoolSet("uiToggleFrames", st.uiToggleFrames)
			Library.ShowToggleFrameInKeybinds = st.uiToggleFrames
		end,
	})

	local dpiVals = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }
	local dpiNums = { 50, 75, 100, 125, 150, 175, 200 }

	local function dpiNum(v)
		if type(v) == "table" then
			local tv = v[1] or v.Value or v.Option
			if tv == nil then
				for k, on in next, v do
					if on then
						tv = k
						break
					end
				end
			end
			v = tv
		end

		local s = tostring(v or "")
		s = s:gsub("%%", "")
		s = s:match("[-%d%.]+") or ""
		return math.clamp(tonumber(s) or 100, 50, 200)
	end

	local function dpiOpt(v)
		local n = dpiNum(v)
		local best = 100
		local dist = math.huge
		for _, x in ipairs(dpiNums) do
			local d = math.abs(n - x)
			if d < dist then
				dist = d
				best = x
			end
		end
		return tostring(best) .. "%"
	end

	ObsidianSettingsTab:CreateDropdown({
		Name = "DPI Scale",
		Values = dpiVals,
		CurrentOption = dpiOpt(st.uiDpi),
		Flag = "Obsidian_DpiScale",
		Callback = function(v)
			local n = dpiNum(v)
			st.uiDpi = n
			cfgSet("uiDpi", n)
			pcall(function()
				Library:SetDPIScale(n)
			end)
		end,
	})

	ObsidianSettingsTab:CreateSlider({
		Name = "Corner Radius",
		Range = {0, 20},
		Increment = 1,
		CurrentValue = st.uiCorner,
		Flag = "Obsidian_CornerRadius",
		Callback = function(v)
			st.uiCorner = math.clamp(tonumber(v) or 4, 0, 20)
			cfgSet("uiCorner", st.uiCorner)
			pcall(function()
				local w = rawWin()
				if w and w.SetCornerRadius then
					w:SetCornerRadius(st.uiCorner)
				end
			end)
		end,
	})

	SettingsTab:CreateLabel("Config Saving : " .. (fileApi and "Enabled" or "Unavailable"))

	SettingsTab:CreateButton({
		Name = "Save Settings Now",
		Callback = function()
			local ok = saveNow()
			pcall(function()
				Obsidian:Notify({
					Title = "Settings",
					Content = ok and "Saved settings." or "Executor file API is missing, settings cannot be saved.",
					Duration = 3,
					Image = 4483362458,
				})
			end)
		end,
	})

	SettingsTab:CreateButton({
		Name = "Reset Saved Settings",
		Callback = function()
			saved = {}
			for k in pairs(st) do
				st[k] = nil
			end
			pcall(function()
				if type(delfile) == "function" and (not hasFile or isfile(cfgFile)) then
					delfile(cfgFile)
				end
			end)
			pcall(function()
				Obsidian:Notify({
					Title = "Settings",
					Content = "Reset saved settings. Reload the script to apply defaults.",
					Duration = 3,
					Image = 4483362458,
				})
			end)
		end,
	})

	SettingsTab:CreateDivider()

	SettingsTab:CreateToggle({
		Name = "Adonis Bypass",
		CurrentValue = st.adonisBypass,
		Flag = "Settings_AdonisBypass",
		Callback = function(v)
			st.adonisBypass = v == true
			_G.RakeAdonisBypass = st.adonisBypass
			cfgSet("adonisBypass", st.adonisBypass)
			if st.adonisBypass then
				task.spawn(function()
					runAdonisBypass(true)
				end)
			end
		end,
	})

	SettingsTab:CreateSlider({
		Name = "ESP Text Size",
		Range = {8, 24},
		Increment = 1,
		CurrentValue = st.espSize,
		Flag = "Settings_ESPTextSize",
		Callback = function(v)
			st.espSize = math.clamp(tonumber(v) or 12, 8, 24)
			cfgSet("espSize", st.espSize)
			refreshEspStyle()
		end,
	})

	SettingsTab:CreateSlider({
		Name = "ESP Scan Delay",
		Range = {0.2, 3},
		Increment = 0.05,
		CurrentValue = st.espScan,
		Flag = "Settings_ESPScanDelay",
		Callback = function(v)
			st.espScan = math.clamp(tonumber(v) or 0.75, 0.2, 3)
			cfgSet("espScan", st.espScan)
		end,
	})

	SettingsTab:CreateSlider({
		Name = "ESP Max Distance",
		Range = {0, 5000},
		Increment = 50,
		CurrentValue = st.espMax,
		Flag = "Settings_ESPMaxDistance",
		Callback = function(v)
			st.espMax = math.clamp(tonumber(v) or 0, 0, 5000)
			cfgSet("espMax", st.espMax)
		end,
	})

	SettingsTab:CreateToggle({
		Name = "ESP Highlights",
		CurrentValue = st.espChams,
		Flag = "Settings_ESPHighlights",
		Callback = function(v)
			st.espChams = v == true
			cfgSet("espChams", st.espChams)
			if cleanupEsp then
				cleanupEsp("flare")
				cleanupEsp("rake")
				cleanupEsp("players")
				cleanupEsp("scraps")
				cleanupEsp("traps")
			end
		end,
	})

	SettingsTab:CreateToggle({
		Name = "ESP Show Distance",
		CurrentValue = st.espDist,
		Flag = "Settings_ESPShowDistance",
		Callback = function(v)
			st.espDist = v == true
			cfgSet("espDist", st.espDist)
		end,
	})

	SettingsTab:CreateDivider()

	SettingsTab:CreateButton({
		Name = "Unload Script",
		Callback = function()
			if typeof(DestroyUI) == "function" then
				DestroyUI()
				return
			end
			AllowRunService = false
			saveNow()
			pcall(function()
				if cleanupEsp then
					cleanupEsp()
				end
			end)
			wipeCharConns()
			if clientBypass and clientBypass.wipeFovConns then
				clientBypass.wipeFovConns()
			end
			if clientBypass and clientBypass.restoreMovementPatches then
				clientBypass.restoreMovementPatches()
			end
			if clientBypass and clientBypass.restoreHiddenUi then
				clientBypass.restoreHiddenUi()
			end
			if wipeFog then
				wipeFog()
			end
			wipeConns()
			safeDestroy(FreeCamPart)
			safeDestroy(HidePartHightLight)
			safeDestroy(HidePart)
			safeDestroy(infoBubble)
			infoBubble = nil
			infoRoot = nil
			infoLbl = nil
			pcall(function() genv.RakeGui = false end)
			pcall(function() Obsidian:Destroy() end)
		end,
	})

	local fogCons = {}
	local fogLast = nil

	wipeFog = function()
		for i = #fogCons, 1, -1 do
			local c = fogCons[i]
			if c then
				pcall(function()
					c:Disconnect()
				end)
			end
			fogCons[i] = nil
		end
	end

	local function bindFog(sig, fn)
		if not sig or type(fn) ~= "function" then
			return nil
		end
		local ok, c = pcall(function()
			return sig:Connect(fn)
		end)
		if ok and c then
			fogCons[#fogCons + 1] = c
			return c
		end
		return nil
	end

	local function setFogOff()
		if not Lit then
			return
		end
		if fogLast == nil then
			fogLast = tonumber(Lit.FogEnd) or 75
		end
		if Lit.FogEnd ~= 9e9 then
			Lit.FogEnd = 9e9
		end
	end

	local function watchFog()
		wipeFog()
		if _G.NoFog ~= true or not Lit then
			return
		end
		setFogOff()
		bindFog(Lit:GetPropertyChangedSignal("FogEnd"), function()
			if _G.NoFog == true then
				setFogOff()
			end
		end)
	end

	ClientTab:CreateToggle({
		Name = "No Fog",
		CurrentValue = st.noFog,
		Flag = "NoFog",
		Callback = function(state)
			_G.NoFog = state == true
			st.noFog = _G.NoFog
			cfgSet("noFog", st.noFog)
			if _G.NoFog == true then
				watchFog()
			else
				wipeFog()
				if Lit then
					Lit.FogEnd = fogLast or 75
				end
			end
		end,
	})

	watchFog()

	ClientTab:CreateToggle({
		Name = "Bypass Death / Intro FX",
		CurrentValue = st.disableDeathFx,
		Flag = "BypassDeathIntroFx",
		Callback = function(state)
			st.disableDeathFx = state == true
			_G.RakeDisableDeathFx = st.disableDeathFx
			cfgSet("disableDeathFx", st.disableDeathFx)
			if st.disableDeathFx then
				clientBypass.applyDeathFxBypass()
				clientBypass.applyCH(true)
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Disable Motion Blur",
		CurrentValue = st.disableMotionBlur,
		Flag = "DisableMotionBlur",
		Callback = function(state)
			st.disableMotionBlur = state == true
			_G.RakeDisableMotionBlur = st.disableMotionBlur
			cfgSet("disableMotionBlur", st.disableMotionBlur)
			if st.disableMotionBlur then
				clientBypass.applyMotionBlurBypass()
				clientBypass.applyCH(true)
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Disable Esc/Menu FX",
		CurrentValue = st.disableMenuFx,
		Flag = "DisableEscMenuFx",
		Callback = function(state)
			st.disableMenuFx = state == true
			_G.RakeDisableMenuFx = st.disableMenuFx
			cfgSet("disableMenuFx", st.disableMenuFx)
			if st.disableMenuFx then
				clientBypass.applyMenuFxBypass()
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Intro Bypass / Restore UI",
		CurrentValue = st.introBypass,
		Flag = "IntroBypassRestoreUi",
		Callback = function(state)
			st.introBypass = state == true
			_G.RakeIntroBypass = st.introBypass
			cfgSet("introBypass", st.introBypass)
			if st.introBypass then
				clientBypass.applyIntroBypass()
			else
				_G.RakeIntroBypass = false
			end
		end,
	})

	ClientTab:CreateButton({
		Name = "Restore CoreGui",
		Callback = function()
			clientBypass.restoreCoreGui()
			Obsidian:Notify({
				Title = "Client",
				Content = "Topbar, reset, backpack, player list, chat, and mouse icon restored.",
				Duration = 3,
				Image = 4483362458,
			})
		end,
	})

	ClientTab:CreateButton({
		Name = "Remove Intro GUI",
		Callback = function()
			local removed = clientBypass.removeIntroGui()
			setScriptGlobal("IsLoading", nil)
			setScriptGlobal("SLoaded", true)
			clientBypass.restoreCoreGui()
			Obsidian:Notify({
				Title = "Intro",
				Content = "Removed intro GUI count: " .. tostring(removed),
				Duration = 3,
				Image = 4483362458,
			})
		end,
	})

	ClientTab:CreateToggle({
		Name = "Disable Shadows",
		CurrentValue = st.disableShadows,
		Flag = "DisableShadows",
		Callback = function(state)
			st.disableShadows = state == true
			_G.RakeDisableShadows = st.disableShadows
			cfgSet("disableShadows", st.disableShadows)
			clientBypass.fireSettingsChanged("Shadows", not st.disableShadows)
			clientBypass.applyGameSettingOverrides()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Force Chat Enabled",
		CurrentValue = st.forceChat,
		Flag = "ForceChatEnabled",
		Callback = function(state)
			st.forceChat = state == true
			_G.RakeForceChat = st.forceChat
			cfgSet("forceChat", st.forceChat)
			clientBypass.fireSettingsChanged("Chat", st.forceChat)
			clientBypass.applyGameSettingOverrides()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Mute Game Music",
		CurrentValue = st.muteGameMusic,
		Flag = "MuteGameMusic",
		Callback = function(state)
			st.muteGameMusic = state == true
			cfgSet("muteGameMusic", st.muteGameMusic)
			clientBypass.fireSettingsChanged("GameMusic", not st.muteGameMusic)
			clientBypass.applyGameSettingOverrides()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Mute Chase Music",
		CurrentValue = st.muteChaseMusic,
		Flag = "MuteChaseMusic",
		Callback = function(state)
			st.muteChaseMusic = state == true
			cfgSet("muteChaseMusic", st.muteChaseMusic)
			clientBypass.fireSettingsChanged("ChaseMusic", not st.muteChaseMusic)
			clientBypass.applyGameSettingOverrides()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Force Nametags",
		CurrentValue = st.enableNametags,
		Flag = "ForceNametags",
		Callback = function(state)
			st.enableNametags = state == true
			_G.RakeForceNametags = st.enableNametags
			cfgSet("enableNametags", st.enableNametags)
			clientBypass.fireSettingsChanged("Nametags", st.enableNametags)
			clientBypass.applyGameSettingOverrides()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Force Sixth Sense",
		CurrentValue = st.enableSixthSense,
		Flag = "ForceSixthSense",
		Callback = function(state)
			st.enableSixthSense = state == true
			_G.RakeForceSixthSense = st.enableSixthSense
			cfgSet("enableSixthSense", st.enableSixthSense)
			clientBypass.fireSettingsChanged("SixthSense", st.enableSixthSense)
			clientBypass.applyGameSettingOverrides()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Mute Movement Loops",
		CurrentValue = st.muteMovementSounds,
		Flag = "MuteMovementSounds",
		Callback = function(state)
			st.muteMovementSounds = state == true
			_G.RakeMuteMovementSounds = st.muteMovementSounds
			cfgSet("muteMovementSounds", st.muteMovementSounds)
			if st.muteMovementSounds then
				clientBypass.applySoundBypasses()
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Mute Footsteps",
		CurrentValue = st.muteFootsteps,
		Flag = "MuteFootsteps",
		Callback = function(state)
			st.muteFootsteps = state == true
			_G.RakeMuteFootsteps = st.muteFootsteps
			cfgSet("muteFootsteps", st.muteFootsteps)
			if st.muteFootsteps then
				clientBypass.applySoundBypasses()
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Mute Jump/Land Sounds",
		CurrentValue = st.muteJumpLand,
		Flag = "MuteJumpLandSounds",
		Callback = function(state)
			st.muteJumpLand = state == true
			_G.RakeMuteJumpLand = st.muteJumpLand
			cfgSet("muteJumpLand", st.muteJumpLand)
			if st.muteJumpLand then
				clientBypass.applySoundBypasses()
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Mute Water/Freefall Sounds",
		CurrentValue = st.muteWaterFall,
		Flag = "MuteWaterFreefallSounds",
		Callback = function(state)
			st.muteWaterFall = state == true
			_G.RakeMuteWaterFall = st.muteWaterFall
			cfgSet("muteWaterFall", st.muteWaterFall)
			if st.muteWaterFall then
				clientBypass.applySoundBypasses()
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Mute Death Sounds",
		CurrentValue = st.muteDeathSounds,
		Flag = "MuteDeathSounds",
		Callback = function(state)
			st.muteDeathSounds = state == true
			_G.RakeMuteDeathSounds = st.muteDeathSounds
			cfgSet("muteDeathSounds", st.muteDeathSounds)
			if st.muteDeathSounds then
				clientBypass.applySoundBypasses()
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Hide Prompt UI",
		CurrentValue = st.hidePromptUi,
		Flag = "HidePromptUi",
		Callback = function(state)
			st.hidePromptUi = state == true
			_G.RakeHidePromptUi = st.hidePromptUi
			cfgSet("hidePromptUi", st.hidePromptUi)
			clientBypass.applyPromptUiBypass()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Freeze Look Angles",
		CurrentValue = st.freezeLookAngles,
		Flag = "FreezeLookAngles",
		Callback = function(state)
			st.freezeLookAngles = state == true
			_G.RakeFreezeLookAngles = st.freezeLookAngles
			cfgSet("freezeLookAngles", st.freezeLookAngles)
			if st.freezeLookAngles then
				clientBypass.applyLookFreeze()
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Hide Death Messages",
		CurrentValue = st.hideDeathMessages,
		Flag = "HideDeathMessages",
		Callback = function(state)
			st.hideDeathMessages = state == true
			_G.RakeHideDeathMessages = st.hideDeathMessages
			cfgSet("hideDeathMessages", st.hideDeathMessages)
			clientBypass.applyDeathMessageBypass()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Block Favorite Prompts",
		CurrentValue = st.blockFavoritePrompts,
		Flag = "BlockFavoritePrompts",
		Callback = function(state)
			st.blockFavoritePrompts = state == true
			_G.RakeBlockFavoritePrompts = st.blockFavoritePrompts
			cfgSet("blockFavoritePrompts", st.blockFavoritePrompts)
			clientBypass.cleanupPromptModals()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Block Group Prompts",
		CurrentValue = st.blockGroupPrompts,
		Flag = "BlockGroupPrompts",
		Callback = function(state)
			st.blockGroupPrompts = state == true
			_G.RakeBlockGroupPrompts = st.blockGroupPrompts
			cfgSet("blockGroupPrompts", st.blockGroupPrompts)
			clientBypass.cleanupPromptModals()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Force PC Device",
		CurrentValue = st.forcePcDevice,
		Flag = "ForcePcDevice",
		Callback = function(state)
			st.forcePcDevice = state == true
			cfgSet("forcePcDevice", st.forcePcDevice)
			clientBypass.applyDeviceSpoof()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Flashlight No Shadows",
		CurrentValue = st.flashlightNoShadows,
		Flag = "FlashlightNoShadows",
		Callback = function(state)
			st.flashlightNoShadows = state == true
			_G.RakeFlashlightNoShadows = st.flashlightNoShadows
			cfgSet("flashlightNoShadows", st.flashlightNoShadows)
			clientBypass.applyLightToolBypasses()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Flashlight Boost",
		CurrentValue = st.flashlightBoost,
		Flag = "FlashlightBoost",
		Callback = function(state)
			st.flashlightBoost = state == true
			_G.RakeFlashlightBoost = st.flashlightBoost
			cfgSet("flashlightBoost", st.flashlightBoost)
			clientBypass.applyLightToolBypasses()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Block Menu Reopen",
		CurrentValue = st.disableMenuReopen,
		Flag = "BlockMenuReopen",
		Callback = function(state)
			st.disableMenuReopen = state == true
			_G.RakeDisableMenuReopen = st.disableMenuReopen
			cfgSet("disableMenuReopen", st.disableMenuReopen)
			clientBypass.removeIntroClones()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Force Backpack Enabled",
		CurrentValue = st.forceBackpack,
		Flag = "ForceBackpackEnabled",
		Callback = function(state)
			st.forceBackpack = state == true
			_G.RakeForceBackpack = st.forceBackpack
			cfgSet("forceBackpack", st.forceBackpack)
			clientBypass.forceCoreParts()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Force Mouse Icon",
		CurrentValue = st.forceMouseIcon,
		Flag = "ForceMouseIcon",
		Callback = function(state)
			st.forceMouseIcon = state == true
			_G.RakeForceMouseIcon = st.forceMouseIcon
			cfgSet("forceMouseIcon", st.forceMouseIcon)
			clientBypass.forceCoreParts()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Force Topbar Enabled",
		CurrentValue = st.forceTopbar,
		Flag = "ForceTopbarEnabled",
		Callback = function(state)
			st.forceTopbar = state == true
			_G.RakeForceTopbar = st.forceTopbar
			cfgSet("forceTopbar", st.forceTopbar)
			clientBypass.forceCoreParts()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Disable Visual FX",
		CurrentValue = st.disableVisualFx,
		Flag = "DisableVisualFX",
		Callback = function(state)
			st.disableVisualFx = state == true
			_G.RakeDisableVisualFx = st.disableVisualFx
			cfgSet("disableVisualFx", st.disableVisualFx)
			clientBypass.applyCH(true)
		end,
	})

	ClientTab:CreateToggle({
		Name = "Disable Camera Shake",
		CurrentValue = st.disableCameraShake,
		Flag = "DisableCameraShake",
		Callback = function(state)
			st.disableCameraShake = state == true
			_G.RakeDisableCameraShake = st.disableCameraShake
			cfgSet("disableCameraShake", st.disableCameraShake)
			clientBypass.applyCH(true)
		end,
	})

	ClientTab:CreateToggle({
		Name = "Disable Camera Bobbing",
		CurrentValue = st.disableCameraBobbing,
		Flag = "DisableCameraBobbing",
		Callback = function(state)
			st.disableCameraBobbing = state == true
			_G.RakeDisableCameraBobbing = st.disableCameraBobbing
			cfgSet("disableCameraBobbing", st.disableCameraBobbing)
			if st.disableCameraBobbing then
				clientBypass.applyCH(true)
			else
				clientBypass.restoreMovementPatches()
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Hide Location Popups",
		CurrentValue = st.hideLocationPopups,
		Flag = "HideLocationPopups",
		Callback = function(state)
			st.hideLocationPopups = state == true
			_G.RakeHideLocationPopups = st.hideLocationPopups
			cfgSet("hideLocationPopups", st.hideLocationPopups)
			clientBypass.applyCH(true)
			clientBypass.applyClientPopupBypasses()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Hide Scrap Popups",
		CurrentValue = st.hideScrapPopups,
		Flag = "HideScrapPopups",
		Callback = function(state)
			st.hideScrapPopups = state == true
			_G.RakeHideScrapPopups = st.hideScrapPopups
			cfgSet("hideScrapPopups", st.hideScrapPopups)
			clientBypass.applyClientPopupBypasses()
		end,
	})

	ClientTab:CreateToggle({
		Name = "Hide Trap Struggle UI",
		CurrentValue = st.hideTrapGui,
		Flag = "HideTrapStruggleUI",
		Callback = function(state)
			st.hideTrapGui = state == true
			_G.RakeHideTrapGui = st.hideTrapGui
			cfgSet("hideTrapGui", st.hideTrapGui)
			clientBypass.applyClientPopupBypasses()
		end,
	})

	ClientTab:CreateToggle({
		Name = "No Downed / Ragdoll",
		CurrentValue = st.noDowned,
		Flag = "NoDownedRagdoll",
		Callback = function(state)
			st.noDowned = state == true
			_G.RakeNoDowned = st.noDowned
			cfgSet("noDowned", st.noDowned)
			clientBypass.applyCharBypasses()
			clientBypass.applyCH(true)
		end,
	})

	ClientTab:CreateToggle({
		Name = "No Movement Lock",
		CurrentValue = st.noMoveLock,
		Flag = "NoMovementLock",
		Callback = function(state)
			st.noMoveLock = state == true
			_G.RakeNoMoveLock = st.noMoveLock
			cfgSet("noMoveLock", st.noMoveLock)
			clientBypass.applyCharBypasses()
			clientBypass.applyCH(true)
		end,
	})

	ClientTab:CreateToggle({
		Name = "No Trap Lock",
		CurrentValue = st.noTrapLock,
		Flag = "NoTrapLock",
		Callback = function(state)
			st.noTrapLock = state == true
			_G.RakeNoTrapLock = st.noTrapLock
			cfgSet("noTrapLock", st.noTrapLock)
			clientBypass.applyCharBypasses()
			clientBypass.applyCH(true)
		end,
	})

	ClientTab:CreateToggle({
		Name = "No Jumpscare Camera",
		CurrentValue = st.noJumpscareCam,
		Flag = "NoJumpscareCamera",
		Callback = function(state)
			st.noJumpscareCam = state == true
			_G.RakeNoJumpscareCam = st.noJumpscareCam
			cfgSet("noJumpscareCam", st.noJumpscareCam)
			clientBypass.applyCH(true)
		end,
	})

	ClientTab:CreateToggle({
		Name = "No Chase Static",
		CurrentValue = st.noChaseStatic,
		Flag = "NoChaseStatic",
		Callback = function(state)
			st.noChaseStatic = state == true
			_G.RakeNoChaseStatic = st.noChaseStatic
			cfgSet("noChaseStatic", st.noChaseStatic)
			clientBypass.applyCH(true)
		end,
	})

	ClientTab:CreateToggle({
		Name = "Fullbright",
		CurrentValue = st.fullbright,
		Flag = "Fullbright",
		Callback = function(state)
			st.fullbright = state == true
			_G.RakeFullbright = st.fullbright
			cfgSet("fullbright", st.fullbright)
			clientBypass.applyFullbright()
		end,
	})

	ClientTab:CreateButton({
		Name = "Third Person",
		Callback = function()
			Plrs.LocalPlayer.Character.RagdollTime.RagdollSwitch.Value = true
			Plrs.LocalPlayer.Character.RagdollTime.RagdollSwitch.Value = false
		end,
	})



	PlayerTab:CreateToggle({
		Name = "Inf Stamina",
		CurrentValue = st.infStamina,
		Flag = "InfStamina",
		Callback = function(state)
			_G.InfStamina = state == true
			st.infStamina = _G.InfStamina
			cfgSet("infStamina", st.infStamina)
			if st.infStamina == true then
				applyInfTabs(true)
				queueInfTabs(12)
				pcall(clientBypass.applyStaminaModuleBypass)
				pcall(clientBypass.applyStaminaSignals)
				clientBypass.applyCH(true)
			else
				pcall(clientBypass.applyStaminaSignals)
			end
		end,
	})

	PlayerTab:CreateToggle({
		Name = "Inf Night Vision",
		CurrentValue = st.infNight,
		Flag = "InfNightVision",
		Callback = function(state)
			_G.InfNightVision = state == true
			st.infNight = _G.InfNightVision
			cfgSet("infNight", st.infNight)
			if st.infNight == true then
				applyInfTabs(true)
				queueInfTabs(12)
				clientBypass.applyStaminaModuleBypass()
				clientBypass.applyCH(true)
			end
		end,
	})

	local RakeKillauraToggle = ExploitsTab:CreateToggle({
		Name = "Rake Killaura",
		CurrentValue = st.rakeAura,
		Flag = "RakeAura",
		Callback = function(state)
			_G.RakeKillAura = state == true
			st.rakeAura = _G.RakeKillAura
			cfgSet("rakeAura", st.rakeAura)
			Obsidian:Notify({
				Title = "Rake Killaura",
				Content = "Rake Killaura : "..tostring(_G.RakeKillAura),
				Duration = 1,
				Image = 4483362458,
			})
		end,
	})

	ExploitsTab:CreateSlider({
		Name = "Killaura Range",
		Range = {6, 30},
		Increment = 1,
		CurrentValue = st.rakeAuraRange,
		Flag = "RakeAuraRange",
		Callback = function(v)
			st.rakeAuraRange = math.clamp(tonumber(v) or 12, 6, 30)
			_G.RakeAuraRange = st.rakeAuraRange
			cfgSet("rakeAuraRange", st.rakeAuraRange)
		end,
	})

	ExploitsTab:CreateSlider({
		Name = "Killaura Delay",
		Range = {0.05, 0.6},
		Increment = 0.01,
		CurrentValue = st.rakeAuraDelay,
		Flag = "RakeAuraDelay",
		Callback = function(v)
			st.rakeAuraDelay = math.clamp(tonumber(v) or 0.12, 0.05, 0.6)
			_G.RakeAuraDelay = st.rakeAuraDelay
			cfgSet("rakeAuraDelay", st.rakeAuraDelay)
		end,
	})

	ExploitsTab:CreateToggle({
		Name = "Killaura Auto Equip",
		CurrentValue = st.rakeAuraAutoEquip,
		Flag = "RakeAuraAutoEquip",
		Callback = function(state)
			st.rakeAuraAutoEquip = state == true
			_G.RakeAuraAutoEquip = st.rakeAuraAutoEquip
			cfgSet("rakeAuraAutoEquip", st.rakeAuraAutoEquip)
		end,
	})

	local auraT = 0
	local aura = {
		rk = nil,
		rr = nil,
		rh = nil,
		stick = nil,
		ev = nil,
		hp = nil,
		bp = nil,
	}

	local function auraClearRake()
		aura.rk = nil
		aura.rr = nil
		aura.rh = nil
	end

	local function auraClearStick()
		aura.stick = nil
		aura.ev = nil
		aura.hp = nil
	end

	local function auraIsStick(v)
		if not (v and v:IsA("Tool")) then
			return false
		end
		local n = string.lower(v.Name)
		return n == "stunstick" or (string.find(n, "stun", 1, true) and string.find(n, "stick", 1, true)) ~= nil
	end

	local function auraGetRake()
		local rk = aura.rk
		if not (rk and rk.Parent) then
			rk = ffc(Ws, "Rake")
			aura.rk = rk
			aura.rr = nil
			aura.rh = nil
		end
		if not rk then
			return nil
		end
		local rh = aura.rh
		if not (rh and rh.Parent) then
			rh = ffc(rk, "Monster") or ffca(rk, "Humanoid")
			aura.rh = rh
		end
		if rh and rh.Health and rh.Health <= 0 then
			return nil
		end
		local rr = aura.rr
		if not (rr and rr.Parent) then
			rr = ffc(rk, "HumanoidRootPart") or ffcr(rk, "HumanoidRootPart")
			aura.rr = rr
		end
		if not rr then
			return nil
		end
		return rk, rr, rh
	end

	local function auraGetPart(rk, rr, pos)
		local best = rr
		local bd = rr and (rr.Position - pos).Magnitude or math.huge
		local names = { "Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart" }
		for i = 1, #names do
			local v = ffc(rk, names[i])
			if v and v:IsA("BasePart") then
				local d = (v.Position - pos).Magnitude
				if d < bd then
					best = v
					bd = d
				end
			end
		end
		return best
	end

	local function auraGetStick()
		local ch = getChar()
		if not ch then
			return nil
		end
		local s = aura.stick
		if not (s and s.Parent) then
			s = nil
			for _, v in pairs(kids(ch)) do
				if auraIsStick(v) then
					s = v
					break
				end
			end
			if not s then
				local bp = aura.bp
				if not (bp and bp.Parent) then
					local lp = Plrs.LocalPlayer
					bp = lp and ffc(lp, "Backpack") or nil
					aura.bp = bp
				end
				if bp then
					for _, v in pairs(kids(bp)) do
						if auraIsStick(v) then
							s = v
							break
						end
					end
				end
				if s and _G.RakeAuraAutoEquip == true then
					local hum = getHum()
					if hum then
						pcall(function()
							hum:EquipTool(s)
						end)
					end
					return nil
				end
			end
			aura.stick = s
			aura.ev = nil
			aura.hp = nil
		end
		if not (s and s.Parent == ch) then
			if s and _G.RakeAuraAutoEquip == true then
				local hum = getHum()
				if hum then
					pcall(function()
						hum:EquipTool(s)
					end)
				end
				auraClearStick()
			end
			return nil
		end
		local ev = aura.ev
		if not (ev and ev.Parent) then
			ev = ffc(s, "Event") or ffcr(s, "Event")
			aura.ev = ev
		end
		local hp = aura.hp
		if not (hp and hp.Parent) then
			hp = ffc(s, "HitPart") or ffcr(s, "HitPart")
			aura.hp = hp
		end
		return s, ev, hp
	end

	local function auraHasPower()
		local p = ffc(Rep, "StationPower")
		if p and p.Value ~= true then
			return false
		end
		return true
	end

	local function auraHasStamina()
		if st.infStamina == true or _G.InfStamina == true then
			return true
		end
		local g = ffc(Rep, "GSTMNA")
		if not g then
			return true
		end
		local ok, val = pcall(function()
			return g:Invoke()
		end)
		return not ok or not val or val >= 12
	end

	local function auraTakeStamina()
		if st.infStamina == true or _G.InfStamina == true then
			return
		end
		local tks = ffc(Rep, "TKSMNA")
		if tks then
			pcall(function()
				tks:Fire(12)
			end)
		end
	end

	local function auraPrepHitpart(hp)
		if not hp then
			return
		end
		pcall(function()
			hp.CanTouch = true
			hp.CanQuery = true
		end)
	end

	local function auraSwing(ev, hit)
		if not (ev and hit) then
			return
		end
		pcall(function()
			ev:FireServer("S")
		end)
		auraTakeStamina()
		pcall(function()
			ev:FireServer("H", hit)
		end)
	end

	bind(Ws.ChildAdded, function(obj)
		if obj and obj.Name == "Rake" then
			auraClearRake()
			aura.rk = obj
		end
	end)

	bind(Ws.ChildRemoved, function(obj)
		if obj == aura.rk or obj.Name == "Rake" then
			auraClearRake()
		end
	end)

	bind(Plrs.LocalPlayer.CharacterAdded, function()
		auraClearStick()
	end)

	bind(Run.Heartbeat, function(dt)
		if AllowRunService ~= true or _G.RakeKillAura ~= true then
			auraT = 0
			return
		end
		auraT += dt
		pcall(function()
			local root = GET_HRP()
			if not root then
				return
			end
			local rk, rr = auraGetRake()
			if not (rk and rr) then
				return
			end
			local range = math.clamp(tonumber(_G.RakeAuraRange) or 12, 6, 30)
			if (rr.Position - root.Position).Magnitude > range then
				return
			end
			local stick, ev, hp = auraGetStick()
			if not (stick and ev) then
				return
			end
			local hit = auraGetPart(rk, rr, root.Position)
			if not hit or (hit.Position - root.Position).Magnitude > range then
				return
			end
			auraPrepHitpart(hp)
			local delay = math.clamp(tonumber(_G.RakeAuraDelay) or 0.12, 0.05, 0.6)
			if auraT >= delay and auraHasPower() and auraHasStamina() then
				auraT = 0
				auraSwing(ev, hit)
			end
		end)
	end)



	-- rake killaura bind

	ExploitsTab:CreateKeybind({
		Name = "Toggle Killaura",
		CurrentKeybind = "R",
		HoldToInteract = false,
		Flag = "KillAuraKeybind",
		Callback = function(state)
			if _G.RakeKillAura == true then
				RakeKillauraToggle:Set(false)
			elseif _G.RakeKillAura == false then
				RakeKillauraToggle:Set(true)
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Rake Chams",
		CurrentValue = st.rakeChams,
		Flag = "RakeChams",
		Callback = function(state)
			_G.RakeChams = state == true
			st.rakeChams = _G.RakeChams
			cfgSet("rakeChams", st.rakeChams)
			if not state and cleanupEsp then
				cleanupEsp("rake")
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Rake Info Bubble",
		CurrentValue = st.infoBubble,
		Flag = "RakeInfoBubble",
		Callback = function(state)
			st.infoBubble = state == true
			cfgSet("infoBubble", st.infoBubble)
			setBubbleVisible(st.infoBubble)
		end,
	})

	ClientTab:CreateToggle({
		Name = "Player ESP",
		CurrentValue = st.playerEsp,
		Flag = "PlrEsp",
		Callback = function(state)
			_G.PlayerESP = state == true
			st.playerEsp = _G.PlayerESP
			cfgSet("playerEsp", st.playerEsp)
			if not state and cleanupEsp then
				cleanupEsp("players")
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Show Distance Travelled",
		CurrentValue = st.showDist,
		Flag = "ShowDistanceTravelled",
		Callback = function(state)
			_G.PlayerESPShowDistance = state == true
			st.showDist = _G.PlayerESPShowDistance
			cfgSet("showDist", st.showDist)
		end,
	})

	ExploitsTab:CreateButton({
		Name = "Bring Scraps",
		Callback = function()
			for i,v in pairs(Ws.Filter.ScrapSpawns:QueryDescendants("Instance")) do
				if v.Name:lower() == "scrap" then
					v:PivotTo(Plrs.LocalPlayer.Character:GetPivot())
				end
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Flare Gun ESP",
		CurrentValue = st.flareEsp,
		Flag = "FlareGunESP",
		Callback = function(state)
			_G.FlareGunESP = state == true
			st.flareEsp = _G.FlareGunESP
			cfgSet("flareEsp", st.flareEsp)
			if not state and cleanupEsp then
				cleanupEsp("flare")
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "SupplyDrop ESP",
		CurrentValue = st.dropEsp,
		Flag = "SupplyDropESP",
		Callback = function(state)
			_G.SupplyDropESP = state == true
			st.dropEsp = _G.SupplyDropESP
			cfgSet("dropEsp", st.dropEsp)
			if not state and cleanupEsp then
				cleanupEsp("drops")
			end
		end,
	})



	esp = {
		flare = nil,
		rake = nil,
		drops = {},
		locs = {},
		players = {},
		scraps = {},
		scrapRoot = nil,
		traps = {},
	}

	esp.getLocFolder = function()
		local filter = ffc(Ws, "Filter")
		return filter and ffc(filter, "LocationPoints") or nil
	end

	esp.locName = function(obj)
		local n = tostring(obj and obj.Name or "Location")
		n = n:gsub("MSG$", "")
		n = n:gsub("_", " ")
		n = n:gsub("(%l)(%u)", "%1 %2")
		return n
	end

	esp.locPos = function(obj)
		if not obj then
			return nil
		end
		if obj:IsA("BasePart") then
			return obj.Position
		end
		if obj:IsA("Model") then
			local ok, cf = pcall(function()
				return obj:GetPivot()
			end)
			return ok and cf and cf.Position or nil
		end
		if obj:IsA("CFrameValue") then
			return obj.Value.Position
		end
		if obj:IsA("Vector3Value") then
			return obj.Value
		end
		return nil
	end

	clientBypass.fovUiMult = function()
		return 1
	end

	esp.drawTxt = function(txt, col)
		if not Drawing or not Drawing.new then
			return nil
		end
		local ok, d = pcall(function()
			return Drawing.new("Text")
		end)
		if not ok or not d then
			return nil
		end
		d.Text = txt or ""
		d.Color = col or Color3.fromRGB(255, 255, 255)
		d.Outline = false
		d.Center = true
		d.Font = 2
		d.Size = st.espSize or 12
		d.Visible = false
		return d
	end

	esp.cham = function(par, name, fill, out, trans)
		if not par or st.espChams ~= true then
			return nil
		end
		local h = ffc(par, name)
		if h and h:IsA("Highlight") then
			h.Enabled = true
			return h
		end
		h = Instance.new("Highlight")
		h.Name = name
		h.Adornee = par
		h.FillColor = fill or Color3.fromRGB(255, 255, 255)
		h.OutlineColor = out or Color3.fromRGB(170, 170, 170)
		h.FillTransparency = trans or 0.3
		h.OutlineTransparency = 0.8
		h.Parent = par
		return h
	end

	esp.posOf = function(obj)
		if not obj then
			return nil
		end
		if obj:IsA("BasePart") then
			return obj.Position
		end
		if obj:IsA("Model") then
			local pp = obj.PrimaryPart or ffcr(obj, "HumanoidRootPart") or ffcr(obj, "Head") or ffcr(obj, "HitBox") or ffcr(obj, "Scrap")
			if pp and pp:IsA("BasePart") then
				return pp.Position
			end
			local ok, cf = pcall(function()
				return obj:GetPivot()
			end)
			if ok and cf then
				return cf.Position
			end
		end
		return nil
	end

	esp.show = function(d, pos, txt)
		if not d or not pos then
			if d then d.Visible = false end
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then
			d.Visible = false
			return
		end
		local me = GET_HRP()
		local dist
		if me then
			dist = (pos - me.Position).Magnitude
			if (tonumber(st.espMax) or 0) > 0 and dist > st.espMax then
				d.Visible = false
				return
			end
		end
		local p, on = cam:WorldToViewportPoint(pos)
		if on then
			local text = txt or d.Text
			if st.espDist == true and dist then
				text = tostring(text) .. " [" .. tostring(math.floor(dist + 0.5)) .. "m]"
			end
			if d.Text ~= text then
				d.Text = text
			end
			local size = st.espSize or d.Size
			if d.Size ~= size then
				d.Size = size
			end
			if d.Outline ~= false then
				d.Outline = false
			end
			local pos2 = Vector2.new(p.X, p.Y)
			if d.Position ~= pos2 then
				d.Position = pos2
			end
			if d.Visible ~= true then
				d.Visible = true
			end
		else
			if d.Visible ~= false then
				d.Visible = false
			end
		end
	end

	esp.itemVal = function(root, name)
		local cur = root
		for _ = 1, 5 do
			if not cur then
				break
			end
			local v = ffc(cur, name)
			if v then
				return valOf(v, "?")
			end
			local ok, attr = pcall(function()
				return cur:GetAttribute(name)
			end)
			if ok and attr ~= nil then
				return attr
			end
			cur = cur.Parent
		end
		return "?"
	end

	esp.scrapTxt = function(part)
		local root = part and part.Parent
		local pts = esp.itemVal(root, "PointsVal")
		local lvl = esp.itemVal(root, "LevelVal")
		return "Scrap, Points "..tostring(pts)..", Level "..tostring(lvl)
	end

	esp.clearOne = function(tab, key)
		local it = tab[key]
		if not it then
			return
		end
		safeDrawRemove(it.d)
		safeDestroy(it.h)
		tab[key] = nil
	end

	cleanupEsp = function(kind)
		if not kind or kind == "flare" then
			if esp.flare then
				safeDrawRemove(esp.flare.d)
				safeDestroy(esp.flare.h)
				esp.flare = nil
			end
		end
		if not kind or kind == "rake" then
			if esp.rake then
				safeDrawRemove(esp.rake.d)
				safeDestroy(esp.rake.h)
				esp.rake = nil
			end
		end
		if not kind or kind == "players" then
			for k in pairs(esp.players) do
				esp.clearOne(esp.players, k)
			end
		end
		if not kind or kind == "drops" then
			for k in pairs(esp.drops) do
				esp.clearOne(esp.drops, k)
			end
		end
		if not kind or kind == "locs" then
			for k, d in pairs(esp.locs) do
				safeDrawRemove(d)
				esp.locs[k] = nil
			end
		end
		if not kind or kind == "scraps" then
			for k in pairs(esp.scraps) do
				esp.clearOne(esp.scraps, k)
			end
		end
		if not kind or kind == "traps" then
			for k in pairs(esp.traps) do
				esp.clearOne(esp.traps, k)
			end
		end
	end

	ClientTab:CreateToggle({
		Name = "Location ESP",
		CurrentValue = st.locEsp,
		Flag = "LocationESP",
		Callback = function(state)
			_G.LocationESP = state == true
			st.locEsp = _G.LocationESP
			cfgSet("locEsp", st.locEsp)
			if not state and cleanupEsp then
				cleanupEsp("locs")
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Scrap ESP",
		CurrentValue = st.scrapEsp,
		Flag = "ScrapESP",
		Callback = function(state)
			_G.ScrapESP = state == true
			st.scrapEsp = _G.ScrapESP
			cfgSet("scrapEsp", st.scrapEsp)
			if state then
				esp.scrapRoot = nil
			elseif cleanupEsp then
				cleanupEsp("scraps")
			end
		end,
	})

	ClientTab:CreateToggle({
		Name = "Rake Trap ESP",
		CurrentValue = st.trapEsp,
		Flag = "RakeTrapESP",
		Callback = function(state)
			_G.RakeTrapESP = state == true
			st.trapEsp = _G.RakeTrapESP
			cfgSet("trapEsp", st.trapEsp)
			if not state and cleanupEsp then
				cleanupEsp("traps")
			end
		end,
	})

	esp.scanT = 1
	esp.updT = 0

	esp.espAny = function()
		return _G.FlareGunESP == true or _G.RakeChams == true or _G.PlayerESP == true or _G.SupplyDropESP == true or _G.LocationESP == true or _G.ScrapESP == true or _G.RakeTrapESP == true
	end

	esp.scanEsp = function()
		if _G.FlareGunESP == true then
			local fl = ffcr(Ws, "FlareGunPickUp")
			if fl then
				if not esp.flare or esp.flare.o ~= fl then
					cleanupEsp("flare")
					esp.flare = {
						o = fl,
						d = esp.drawTxt("Flare Gun", Color3.fromRGB(0, 225, 255)),
						h = esp.cham(fl, "FlareGunChams", Color3.fromRGB(255, 0, 0), Color3.fromRGB(170, 170, 170), 0.3),
					}
				end
			else
				cleanupEsp("flare")
			end
		else
			cleanupEsp("flare")
		end

		if _G.RakeChams == true then
			local rk = ffcr(Ws, "Rake")
			if rk then
				if not esp.rake or esp.rake.o ~= rk then
					cleanupEsp("rake")
					esp.rake = {
						o = rk,
						d = esp.drawTxt("Rake", Color3.fromRGB(255, 0, 0)),
						h = esp.cham(rk, "RakeChams", Color3.fromRGB(170, 0, 0), Color3.fromRGB(255, 255, 255), 0.3),
					}
				end
			else
				cleanupEsp("rake")
			end
		else
			cleanupEsp("rake")
		end

		if _G.PlayerESP == true then
			for _, p in pairs(Plrs:GetPlayers()) do
				if p ~= Plrs.LocalPlayer and p.Character then
					local ch = p.Character
					if not esp.players[p] or esp.players[p].o ~= ch then
						esp.clearOne(esp.players, p)
						esp.players[p] = {
							o = ch,
							d = esp.drawTxt(p.Name, Color3.fromRGB(0, 255, 34)),
							h = esp.cham(ch, "PlayerChams", Color3.fromRGB(0, 11, 170), Color3.fromRGB(170, 170, 170), 0.3),
						}
					end
				end
			end
			for p, it in pairs(esp.players) do
				if not p.Parent or not p.Character or p.Character ~= it.o then
					esp.clearOne(esp.players, p)
				end
			end
		else
			cleanupEsp("players")
		end

		if _G.SupplyDropESP == true then
			eachDrop(function(box)
				if not esp.drops[box] then
					esp.drops[box] = {
						o = box,
						d = esp.drawTxt("Supply Drop", Color3.fromRGB(251, 255, 0)),
						h = nil,
					}
				end
			end)
			for box in pairs(esp.drops) do
				if not box.Parent then
					esp.clearOne(esp.drops, box)
				end
			end
		else
			cleanupEsp("drops")
		end

		if _G.ScrapESP == true then
			local filter = ffc(Ws, "Filter")
			local root = filter and ffc(filter, "ScrapSpawns")
			if root ~= esp.scrapRoot then
				esp.scrapRoot = root
				cleanupEsp("scraps")
				for _, v in pairs(desc(root)) do
					if v.Name == "Scrap" and v:IsA("BasePart") and not esp.scraps[v] then
						esp.scraps[v] = {
							o = v,
							d = esp.drawTxt(esp.scrapTxt(v), Color3.fromRGB(77, 35, 1)),
							h = esp.cham(v, "ScrapChams", Color3.fromRGB(77, 35, 1), Color3.fromRGB(170, 170, 170), 0),
						}
					end
				end
			end
			for v in pairs(esp.scraps) do
				if not v.Parent then
					esp.clearOne(esp.scraps, v)
				end
			end
		else
			esp.scrapRoot = nil
			cleanupEsp("scraps")
		end

		if _G.RakeTrapESP == true then
			local debris = ffc(Ws, "Debris")
			local root = debris and ffc(debris, "Traps")
			if root then
				for _, v in pairs(kids(root)) do
					if v.Name == "RakeTrapModel" and v:IsA("Model") and not esp.traps[v] then
						esp.traps[v] = {
							o = v,
							d = esp.drawTxt("Rake Trap", Color3.fromRGB(255, 85, 0)),
							h = esp.cham(v, "RakeTrapChams", Color3.fromRGB(255, 85, 0), Color3.fromRGB(255, 255, 255), 0.3),
						}
					end
				end
			end
			for v in pairs(esp.traps) do
				if not v.Parent or v.Parent ~= root then
					esp.clearOne(esp.traps, v)
				end
			end
		else
			cleanupEsp("traps")
		end
	end

	bind(Ws.DescendantAdded, function(obj)
		if _G.ScrapESP == true and obj.Name == "Scrap" and obj:IsA("BasePart") then
			local filter = ffc(Ws, "Filter")
			local root = filter and ffc(filter, "ScrapSpawns")
			if root and obj:IsDescendantOf(root) and not esp.scraps[obj] then
				esp.scrapRoot = root
				esp.scraps[obj] = {
					o = obj,
					d = esp.drawTxt(esp.scrapTxt(obj), Color3.fromRGB(77, 35, 1)),
					h = esp.cham(obj, "ScrapChams", Color3.fromRGB(77, 35, 1), Color3.fromRGB(170, 170, 170), 0),
				}
			end
		end
	end)

	bind(Run.Heartbeat, function(dt)
		if AllowRunService ~= true then
			cleanupEsp()
			return
		end

		if not esp.espAny() then
			return
		end

		esp.scanT += dt
		esp.updT += dt

		if esp.scanT >= (tonumber(st.espScan) or 0.75) then
			esp.scanT = 0
			esp.scanEsp()
		end

		if esp.updT < 0.08 then
			return
		end
		esp.updT = 0

		if _G.LocationESP == true then
			local root = esp.getLocFolder()
			local alive = {}
			if root then
				for _, obj in pairs(kids(root)) do
					local pos = esp.locPos(obj)
					if pos then
						alive[obj] = true
						local name = esp.locName(obj)
						local d = esp.locs[obj]
						if not d then
							d = esp.drawTxt("[LOCATION] "..name, Color3.fromRGB(255, 136, 0))
							esp.locs[obj] = d
						end
						esp.show(d, pos, "[LOCATION] "..name)
					end
				end
			end
			for obj, d in pairs(esp.locs) do
				if not alive[obj] or not obj.Parent then
					safeDrawRemove(d)
					esp.locs[obj] = nil
				end
			end
		else
			cleanupEsp("locs")
		end

		if esp.flare then
			local fl = esp.flare.o
			local part = fl and (ffcr(fl, "FlareGun") or fl)
			esp.show(esp.flare.d, _G.FlareGunESP and esp.posOf(part), "Flare Gun")
		end

		if esp.rake then
			local rk = esp.rake.o
			local mons = rk and ffcr(rk, "Monster")
			local hp = valOf(mons and ffcr(mons, "Health"), nil)
			if hp == nil and rk then
				local hum = ffca(rk, "Humanoid")
				hp = hum and hum.Health or hp
			end
			esp.show(esp.rake.d, _G.RakeChams and esp.posOf(ffcr(rk, "Head") or rk), "Rake, Health : "..tostring(hp or "?"))
		end

		for p, it in pairs(esp.players) do
			local ch = it.o
			local head = ch and ffcr(ch, "Head")
			local txt = p.Name
			if _G.PlayerESPShowDistance == true then
				txt = p.Name.." [Distance Travelled : "..tostring(valOf(ffc(p, "DistanceTravelled"), "?")).."]"
			end
			esp.show(it.d, _G.PlayerESP and esp.posOf(head or ch), txt)
		end

		for box, it in pairs(esp.drops) do
			esp.show(it.d, _G.SupplyDropESP and esp.posOf(ffcr(box, "HitBox") or box), "Supply Drop")
		end

		for v, it in pairs(esp.scraps) do
			esp.show(it.d, _G.ScrapESP and esp.posOf(v), esp.scrapTxt(v))
		end

		for v, it in pairs(esp.traps) do
			esp.show(it.d, _G.RakeTrapESP and esp.posOf(v), "Rake Trap")
		end
	end)

	clientBypass.noFall = {
		haystackSize = Vector3.new(100000, 100000, 100000),
		applyToken = 0,
		env = _G,
	}

	clientBypass.noFall.getHaystack = function()
		local ws = game:GetService("Workspace")
		local filter = ffc(ws, "Filter")
		return filter and ffc(filter, "Haystack") or nil
	end

	clientBypass.noFall.applyHaystack = function(enabled)
		clientBypass.noFall.applyToken = clientBypass.noFall.applyToken + 1
		local token = clientBypass.noFall.applyToken

		task.spawn(function()
			for _ = 1, 40 do
				if token ~= clientBypass.noFall.applyToken then
					return
				end

				local haystack = clientBypass.noFall.getHaystack()
				if haystack then
					pcall(function()
						if clientBypass.noFall.env.__rakeHaystackOriginalSize == nil and haystack.Size ~= clientBypass.noFall.haystackSize then
							clientBypass.noFall.env.__rakeHaystackOriginalSize = haystack.Size
						end

						if enabled == true then
							haystack.Size = clientBypass.noFall.haystackSize
						elseif clientBypass.noFall.env.__rakeHaystackOriginalSize then
							haystack.Size = clientBypass.noFall.env.__rakeHaystackOriginalSize
						end
					end)
					return
				end

				task.wait(0.25)
			end
		end)
	end

	PlayerTab:CreateToggle({
		Name = "No Fall Damage",
		CurrentValue = st.noFall,
		Flag = "NoFallDamage",
		Callback = function(state)
			_G.NoFallDMG = state == true
			st.noFall = _G.NoFallDMG
			cfgSet("noFall", st.noFall)
			clientBypass.noFall.applyHaystack(_G.NoFallDMG)
		end,
	})

	PlayerTab:CreateToggle({
		Name = "Safe Position Recovery",
		CurrentValue = st.safeRecover,
		Flag = "SafePositionRecovery",
		Callback = function(state)
			st.safeRecover = state == true
			_G.RakeSafeRecover = st.safeRecover
			cfgSet("safeRecover", st.safeRecover)
			clientBypass.applySafeRecover()
		end,
	})

	PlayerTab:CreateToggle({
		Name = "No Jump Cooldown",
		CurrentValue = st.noJumpCooldown,
		Flag = "NoJumpCooldown",
		Callback = function(state)
			st.noJumpCooldown = state == true
			_G.RakeNoJumpCooldown = st.noJumpCooldown
			cfgSet("noJumpCooldown", st.noJumpCooldown)
			clientBypass.applyCH(true)
		end,
	})

	clientBypass.noFall.applyHaystack(st.noFall)


	clientBypass.lastCam = nil
	clientBypass.lastFov = nil
	clientBypass.fovConns = {}

	clientBypass.fovUiMult = function()
		if st.fovUiFix ~= true or st.fovOn ~= true then
			return 1
		end
		local fov = math.clamp(tonumber(st.fov) or 70, 1, 120)
		if fov <= 70 then
			return 1
		end
		return math.clamp(math.tan(math.rad(fov) * 0.5) / math.tan(math.rad(70) * 0.5), 1, 2.75)
	end

	clientBypass.mulDim2 = function(v, m)
		return UDim2.new(v.X.Scale * m, math.floor(v.X.Offset * m + 0.5), v.Y.Scale * m, math.floor(v.Y.Offset * m + 0.5))
	end

	clientBypass.isTextGui = function(obj)
		return obj and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox"))
	end

	clientBypass.patchFovUiText = function(obj, rec, m)
		if not rec.text then
			rec.text = setmetatable({}, { __mode = "k" })
		end
		for _, ui in pairs(desc(obj)) do
			if clientBypass.isTextGui(ui) then
				local tr = rec.text[ui]
				if not tr then
					tr = { size = ui.TextSize, scaled = ui.TextScaled }
					rec.text[ui] = tr
				end
				pcall(function()
					if tr.scaled == true then
						ui.TextScaled = true
					else
						ui.TextScaled = false
						ui.TextSize = math.clamp(math.floor((tonumber(tr.size) or ui.TextSize or 14) * m + 0.5), 8, 72)
					end
				end)
			end
		end
	end

	function clientBypass.patchFovUi(obj)
		if not obj or not obj.Parent or not obj:IsA("BillboardGui") then
			return false
		end
		local rec = clientBypass.fovUiCache[obj]
		if not rec then
			rec = { size = obj.Size }
			clientBypass.fovUiCache[obj] = rec
		end
		local m = clientBypass.fovUiMult()
		pcall(function()
			obj.Size = clientBypass.mulDim2(rec.size, m)
		end)
		clientBypass.patchFovUiText(obj, rec, m)
		return true
	end

	function clientBypass.applyFovUiFix(scan)
		if st.fovUiFix ~= true then
			return 0
		end
		local n = 0
		for obj in pairs(clientBypass.fovUiCache) do
			if obj and obj.Parent then
				if clientBypass.patchFovUi(obj) then
					n += 1
				end
			else
				clientBypass.fovUiCache[obj] = nil
			end
		end
		if scan == true and clientBypass.fovUiScanned ~= true then
			clientBypass.fovUiScanned = true
			for _, root in pairs({ Ws, clientBypass.getPlayerGui() }) do
				for _, obj in pairs(desc(root)) do
					if obj:IsA("BillboardGui") and clientBypass.patchFovUi(obj) then
						n += 1
					end
				end
			end
		end
		return n
	end

	function clientBypass.restoreFovUiFix()
		for obj, rec in pairs(clientBypass.fovUiCache) do
			if obj and obj.Parent and rec and rec.size then
				pcall(function()
					obj.Size = rec.size
				end)
			end
			if rec and rec.text then
				for ui, tr in pairs(rec.text) do
					if ui and ui.Parent and tr then
						pcall(function()
							ui.TextScaled = tr.scaled == true
							ui.TextSize = tr.size or ui.TextSize
						end)
					end
				end
			end
		end
		clientBypass.fovUiCache = setmetatable({}, { __mode = "k" })
		clientBypass.fovUiScanned = false
	end

	clientBypass.wipeFovConns = function()
		for i = #clientBypass.fovConns, 1, -1 do
			local c = clientBypass.fovConns[i]
			if c then
				pcall(function()
					c:Disconnect()
				end)
			end
			clientBypass.fovConns[i] = nil
		end
	end

	clientBypass.applyFov = function(force)
		if not AllowRunService or st.fovOn ~= true then
			return
		end
		local cam = Ws.CurrentCamera or workspace.CurrentCamera
		if not cam then
			return
		end
		local num = math.clamp(tonumber(st.fov) or 70, 1, 120)
		if force or clientBypass.lastCam ~= cam or clientBypass.lastFov ~= num or cam.FieldOfView ~= num then
			clientBypass.lastCam = cam
			clientBypass.lastFov = num
			pcall(function()
				cam.FieldOfView = num
			end)
			pcall(clientBypass.applyFovUiFix, true)
		end
	end

	clientBypass.bindFovCam = function(cam)
		clientBypass.wipeFovConns()
		if not cam then
			return
		end
		clientBypass.lastCam = nil
		local ok, c = pcall(function()
			return cam:GetPropertyChangedSignal("FieldOfView"):Connect(function()
				if AllowRunService == true and st.fovOn == true then
					task.defer(function()
						clientBypass.applyFov(true)
					end)
				end
			end)
		end)
		if ok and c then
			clientBypass.fovConns[#clientBypass.fovConns + 1] = c
		end
		clientBypass.applyFov(true)
	end

	clientBypass.applySpeed = function(force)
		if not AllowRunService or st.spdOn ~= true then
			return
		end
		local hum = getHum()
		if not hum or not hum.Parent then
			return
		end
		local spd = math.clamp(tonumber(st.spd) or 16, 0, 30)
		if force or hum.WalkSpeed ~= spd then
			pcall(function()
				hum.WalkSpeed = spd
			end)
		end
	end

	clientBypass.onChar = function(ch)
		wipeCharConns()
		curChar = ch
		curHum = nil
		curHrp = nil
		clientBypass.lastSafe = nil
		if not ch then
			return
		end
		if st.infStamina == true or st.infNight == true then
			queueInfTabs(14)
		end
		task.spawn(function()
			local hum = ffca(ch, "Humanoid") or ch:WaitForChild("Humanoid", 10)
			if hum then
				curHum = hum
				clientBypass.applySpeed(true)
				pcall(clientBypass.applyCharBypasses)
				pcall(clientBypass.applySafeRecover)
				if st.infStamina == true or st.infNight == true then
					applyInfTabs(true)
				end
				bindChar(hum:GetPropertyChangedSignal("WalkSpeed"), function()
					clientBypass.applySpeed(true)
				end)
			end
		end)
	end

	clientBypass.lp = Plrs.LocalPlayer
	if clientBypass.lp then
		if clientBypass.lp.Character then
			task.defer(clientBypass.onChar, clientBypass.lp.Character)
		end
		bind(clientBypass.lp.CharacterAdded, clientBypass.onChar)
	end

	PlayerTab:CreateSlider({
		Name = "Field Of View",
		Range = {1, 120},
		Increment = 1,
		CurrentValue = st.fov,
		Flag = "FOV",
		Callback = function(state)
			st.fov = math.clamp(tonumber(state) or st.fov, 1, 120)
			_G.FieldOfView = st.fov
			cfgSet("fov", st.fov)
			clientBypass.applyFov(true)
			clientBypass.applyFovUiFix(true)
		end,
	})

	PlayerTab:CreateToggle({
		Name = "Toggle FOV",
		CurrentValue = st.fovOn,
		Flag = "tglFOV",
		Callback = function(state)
			st.fovOn = state == true
			_G.enableFOV = st.fovOn
			cfgSet("fovOn", st.fovOn)
			clientBypass.lastCam = nil
			clientBypass.bindFovCam(Ws.CurrentCamera or workspace.CurrentCamera)
			clientBypass.applyFov(true)
			if st.fovOn ~= true then
				clientBypass.restoreFovUiFix()
			end
		end,
	})

	PlayerTab:CreateToggle({
		Name = "Fix High FOV UI Scale",
		CurrentValue = st.fovUiFix,
		Flag = "FixHighFovUiScale",
		Callback = function(state)
			st.fovUiFix = state == true
			_G.RakeFovUiFix = st.fovUiFix
			cfgSet("fovUiFix", st.fovUiFix)
			if st.fovUiFix then
				clientBypass.applyFovUiFix(true)
			else
				clientBypass.restoreFovUiFix()
			end
		end,
	})
	
	PlayerTab:CreateSlider({
		Name = "WalkSpeed",
		Range = {0, 30},
		Increment = 1,
		CurrentValue = st.spd,
		Flag = "walkspeed",
		Callback = function(state)
			st.spd = math.clamp(tonumber(state) or st.spd, 0, 30)
			_G.WalkSpeedd = st.spd
			cfgSet("spd", st.spd)
			clientBypass.applySpeed(true)
		end,
	})

	PlayerTab:CreateToggle({
		Name = "Toggle WalkSpeed",
		CurrentValue = st.spdOn,
		Flag = "tglSpeed",
		Callback = function(state)
			st.spdOn = state == true
			_G.enableSpeed = st.spdOn
			cfgSet("spdOn", st.spdOn)
			clientBypass.applySpeed(true)
		end,
	})


	ExploitsTab:CreateToggle({
		Name = "Insta Open SupplyDrop",
		CurrentValue = st.instaDrop,
		Flag = "InstaOpenSupplyDrop",
		Callback = function(state)
			_G.InstaOpenSupplyDrop = state == true
			st.instaDrop = _G.InstaOpenSupplyDrop
			cfgSet("instaDrop", st.instaDrop)
		end,
	})

	ExploitsTab:CreateToggle({
		Name = "Insta Close RakeTrap",
		CurrentValue = st.instaTrap,
		Flag = "InstaCloseRakeTrap",
		Callback = function(state)
			_G.InstaCloseRakeTrap = state == true
			st.instaTrap = _G.InstaCloseRakeTrap
			cfgSet("instaTrap", st.instaTrap)
		end,
	})

	ExploitsTab:CreateToggle({
		Name = "Known Object Prompt Bypass",
		CurrentValue = st.knownPromptBypass,
		Flag = "KnownObjectPromptBypass",
		Callback = function(state)
			st.knownPromptBypass = state == true
			_G.RakeKnownPromptBypass = st.knownPromptBypass
			cfgSet("knownPromptBypass", st.knownPromptBypass)
			if st.knownPromptBypass then
				local n = clientBypass.applyKnownGamePrompts()
				Obsidian:Notify({
					Title = "Known Prompts",
					Content = "Unlocked known prompts: " .. tostring(n),
					Duration = 2,
					Image = 4483362458,
				})
			end
		end,
	})

	ExploitsTab:CreateToggle({
		Name = "Prompt Bypass",
		CurrentValue = st.promptBypass,
		Flag = "PromptBypass",
		Callback = function(state)
			st.promptBypass = state == true
			_G.RakePromptBypass = st.promptBypass
			cfgSet("promptBypass", st.promptBypass)
			if st.promptBypass then
				local n = clientBypass.applyPromptBypass()
				Obsidian:Notify({
					Title = "Prompt Bypass",
					Content = "Unlocked prompts: " .. tostring(n),
					Duration = 2,
					Image = 4483362458,
				})
			end
		end,
	})

	ExploitsTab:CreateSlider({
		Name = "Prompt Distance",
		Range = {5, 100},
		Increment = 1,
		CurrentValue = st.promptDistance,
		Flag = "PromptBypassDistance",
		Callback = function(v)
			st.promptDistance = math.clamp(tonumber(v) or 25, 5, 100)
			cfgSet("promptDistance", st.promptDistance)
			if st.promptBypass then
				clientBypass.applyKnownPromptBypass()
			end
		end,
	})


	ExploitsTab:CreateButton({
		Name = "Unlock Prompts Once",
		Callback = function()
			local old = st.promptBypass
			st.promptBypass = true
			local n = clientBypass.applyPromptBypass()
			st.promptBypass = old
			Obsidian:Notify({
				Title = "Prompts",
				Content = "Unlocked prompts: " .. tostring(n),
				Duration = 2,
				Image = 4483362458,
			})
		end,
	})

	ExploitsTab:CreateButton({
		Name = "StartRemote Play",
		Callback = function()
			local ok, res = clientBypass.invokeStartRemote("Play")
			if ok then
				setScriptGlobal("IsLoading", nil)
				setScriptGlobal("SLoaded", true)
				clientBypass.restoreCoreGui()
			end
			Obsidian:Notify({
				Title = "StartRemote",
				Content = ok and ("Play returned: " .. tostring(res)) or "StartRemote was not available.",
				Duration = 3,
				Image = 4483362458,
			})
		end,
	})

	ExploitsTab:CreateButton({
		Name = "StartRemote LoadData",
		Callback = function()
			local ok, res = clientBypass.invokeStartRemote("LoadData")
			Obsidian:Notify({
				Title = "StartRemote",
				Content = ok and ("LoadData returned: " .. tostring(res)) or "StartRemote was not available.",
				Duration = 3,
				Image = 4483362458,
			})
		end,
	})

	ExploitsTab:CreateButton({
		Name = "StartRemote JoinOld",
		Callback = function()
			local ok, res = clientBypass.invokeStartRemote("JoinOld")
			Obsidian:Notify({
				Title = "StartRemote",
				Content = ok and ("JoinOld returned: " .. tostring(res)) or "StartRemote was not available.",
				Duration = 3,
				Image = 4483362458,
			})
		end,
	})

	clientBypass.promptT = 1
	clientBypass.promptBypassT = 1
	clientBypass.clientBypassT = 1
	clientBypass.knownPromptT = 1
	clientBypass.soundT = 1
	clientBypass.lightT = 5
	clientBypass.deathMsgT = 2
	clientBypass.fastBypassT = 0

	bind(Run.Heartbeat, function(dt)
		if AllowRunService ~= true then
			return
		end
		clientBypass.promptT += dt
		if clientBypass.promptT < 0.35 then
			return
		end
		clientBypass.promptT = 0
		pcall(function()
			fastDoorLever()
			if _G.InstaOpenSupplyDrop == true then
				eachDrop(fastDrop)
			end
			if _G.InstaCloseRakeTrap == true then
				eachTrap(fastTrap)
			end
		end)
	end)

	bind(Run.Heartbeat, function(dt)
		if AllowRunService ~= true then
			return
		end
		clientBypass.promptBypassT += dt
		clientBypass.clientBypassT += dt
		clientBypass.soundT += dt
		clientBypass.lightT += dt
		clientBypass.knownPromptT += dt
		clientBypass.deathMsgT += dt
		clientBypass.chT += dt
		clientBypass.stamScanT += dt
		if (st.infStamina == true or st.infNight == true) and clientBypass.stamScanT >= 12 then
			clientBypass.stamScanT = 0
			pcall(clientBypass.applyStaminaModuleBypass)
		end
		if st.promptBypass == true and clientBypass.promptInitScan ~= true then
			clientBypass.promptInitScan = true
			clientBypass.promptBypassT = 0
			pcall(clientBypass.applyPromptBypass)
		elseif st.promptBypass ~= true then
			clientBypass.promptInitScan = false
		elseif clientBypass.promptBypassT >= 5 then
			clientBypass.promptBypassT = 0
			pcall(clientBypass.applyKnownPromptBypass)
		end
		if clientBypass.knownPromptT >= 1.25 then
			clientBypass.knownPromptT = 0
			pcall(clientBypass.applyKnownGamePrompts)
			pcall(clientBypass.applyClientPopupBypasses)
		end
		if clientBypass.clientBypassT >= 0.75 then
			clientBypass.clientBypassT = 0
			pcall(clientBypass.applyMotionBlurBypass)
			pcall(clientBypass.applyMenuFxBypass)
			pcall(clientBypass.applyDeathFxBypass)
			pcall(clientBypass.applyIntroBypass)
			pcall(clientBypass.applyGameSettingOverrides)
			pcall(clientBypass.applyPromptUiBypass)
			pcall(clientBypass.applyLookFreeze)
			pcall(clientBypass.cleanupPromptModals)
			pcall(clientBypass.applyDeviceSpoof)
			pcall(clientBypass.applyCharBypasses)
			pcall(clientBypass.applySafeRecover)
			pcall(clientBypass.applyFullbright)
			pcall(clientBypass.applyClientPopupBypasses)
			pcall(clientBypass.applyFovUiFix, false)
			pcall(clientBypass.removeIntroClones)
			pcall(clientBypass.forceCoreParts)
			pcall(clientBypass.applyStaminaSignals)
			if clientBypass.chBootScan ~= true then
				clientBypass.chBootScan = true
				pcall(clientBypass.applyCH, true)
			else
				pcall(clientBypass.applyCH, false)
			end
		end
		if clientBypass.deathMsgT >= 2 then
			clientBypass.deathMsgT = 0
			pcall(clientBypass.applyDeathMessageBypass)
		end
		if clientBypass.lightT >= 5 then
			clientBypass.lightT = 0
			pcall(clientBypass.applyLightToolBypasses)
		end
		if clientBypass.soundT >= 2.5 then
			clientBypass.soundT = 0
			pcall(clientBypass.applySoundBypasses)
		end
	end)

	bind(Run.Heartbeat, function()
		if AllowRunService ~= true then
			return
		end
		if st.fovOn == true then
			clientBypass.applyFov(false)
		end
		if _G.NoFog == true then
			setFogOff()
		end
		pcall(clientBypass.applySafeRecover)
		pcall(clientBypass.applyCharBypasses)
		pcall(clientBypass.applyFullbright)
		pcall(clientBypass.applyCH, false)
	end)

	clientBypass.bindFovCam(Ws.CurrentCamera or workspace.CurrentCamera)
	pcall(clientBypass.applyFovUiFix, true)
	pcall(clientBypass.fetchRootModule)
	pcall(clientBypass.applyStaminaModuleBypass)
	pcall(clientBypass.applyStaminaSignals)

	pcall(function()
		bind(Ws:GetPropertyChangedSignal("CurrentCamera"), function()
			task.defer(function()
				clientBypass.bindFovCam(Ws.CurrentCamera or workspace.CurrentCamera)
			end)
		end)
	end)
	
	clientBypass.spdT = 0

	bind(Run.Heartbeat, function(dt)
		if AllowRunService ~= true or st.spdOn ~= true then
			return
		end
		clientBypass.spdT += dt
		if clientBypass.spdT >= 0.5 then
			clientBypass.spdT = 0
			clientBypass.applySpeed(false)
		end
	end)

	bind(Run.Heartbeat, function(dt)
		if AllowRunService ~= true or (st.infStamina ~= true and st.infNight ~= true) then
			return
		end

		infSys.fast += dt
		infSys.scan += dt
		if infSys.fast < 0.75 then
			return
		end

		infSys.fast = 0
		applyInfTabs(false)
		pcall(clientBypass.applyStaminaSignals)
	end)

	function DestroyUI()
		AllowRunService = false
		saveNow()
		wipeCharConns()
		clientBypass.wipeFovConns()
		clientBypass.restoreMovementPatches()
		clientBypass.restoreStaminaModules()
		clientBypass.restoreMainClientModules()
		clientBypass.restoreStaminaSignals()
		clientBypass.restoreHiddenUi()
		wipeFog()
		if cleanupEsp then
			cleanupEsp()
		end
		wipeConns()
		safeDestroy(FreeCamPart)
		safeDestroy(HidePartHightLight)
		safeDestroy(HidePart)
		safeDestroy(infoBubble)
		infoBubble = nil
		infoRoot = nil
		infoLbl = nil
		genv.RakeGui = false
		pcall(function()
			Obsidian:Destroy()
		end)
	end

	clientBypass.RakeTargetCounter = {
		Set = function(_, txt)
			setInfoTarget(txt)
		end,
	}
	clientBypass.TimeUntilDayCounter = {
		Set = function(_, txt)
			setInfoTime(txt)
		end,
	}
	clientBypass.PowerCounter = {
		Set = function(_, txt)
			setInfoPower(txt)
		end,
	}

	-- update time until day label

	clientBypass.infoT = 1

	bind(Run.Heartbeat, function(dt)
		if AllowRunService ~= true then
			return
		end
		clientBypass.infoT += dt
		if clientBypass.infoT < 1 then
			return
		end
		clientBypass.infoT = 0
		pcall(function()
			local sec = fmtTime(valOf(ffc(Rep, "Timer"), 0))
			if valOf(ffc(Rep, "Night"), false) == true then
				clientBypass.TimeUntilDayCounter:Set("Time Until Day : "..sec)
			else
				clientBypass.TimeUntilDayCounter:Set("Time Until Night : "..sec)
			end
			local powerValues = ffc(Rep, "PowerValues")
			local powerLevel = valOf(powerValues and ffc(powerValues, "PowerLevel"), 1000)

			clientBypass.PowerCounter:Set("Power : "..fmtPower(powerLevel).."%")
		end)
	end)

	-- update rakes targetlabel


	clientBypass.tarT = 0.25

	bind(Run.Heartbeat, function(dt)
		if AllowRunService ~= true then
			return
		end
		clientBypass.tarT += dt
		if clientBypass.tarT < 0.25 then
			return
		end
		clientBypass.tarT = 0
		pcall(function()
			local rk = ffcr(Ws, "Rake")
			local tv = ffcr(rk, "TargetVal")
			local val = tv and tv.Value
			if val and val.Parent then
				clientBypass.RakeTargetCounter:Set("Rake's Target : " .. tostring(val.Parent))
			else
				clientBypass.RakeTargetCounter:Set("Rake's Target : none")
			end
		end)
	end)


	-- alert if blood hour

	clientBypass.bhT = 1

	bind(Run.Heartbeat, function(dt)
		if AllowRunService ~= true then
			return
		end
		clientBypass.bhT += dt
		if clientBypass.bhT < 1 then
			return
		end
		clientBypass.bhT = 0
		local bh = ffc(Rep, "InitiateBloodHour")
		if bh and bh.Value == true then
			Obsidian:Notify({
				Title = "ALERT",
				Content = "HOLY JESUS BLOOD HOUR IS COMING NOW",
				Duration = 5,
				Image = 4483362458,
			})
			bh.Value = false
		end
	end)

	if canCfg then
		pcall(function()
			Obsidian:LoadConfiguration()
		end)
	end
	end

	clientBypass.buildUi()
end
