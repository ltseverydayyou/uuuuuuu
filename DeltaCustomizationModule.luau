local __lt = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {}
	local sharedEnv = rawget(_G, "shared")
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil)
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver")
		if type(cached) == "table" then
			return cached
		end
	end
	local loader = loadstring or load
	if type(loader) ~= "function" then
		error("Service resolver loader unavailable")
	end
	local resolver =
		loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau")
	if type(resolver) ~= "function" then
		error("Service resolver failed to compile")
	end
	local loaded = resolver()
	if type(loaded) ~= "table" then
		error("Service resolver failed to load")
	end
	if cacheHost then
		cacheHost.__lt_service_resolver = loaded
	end
	return loaded
end)()

if (identifyexecutor()):lower() ~= "delta" then
	return
end
local deltaEnv = type(getgenv) == "function" and getgenv() or _G
if type(deltaEnv) == "table" then
	if deltaEnv.__DeltaCustomizationModuleLoaded then
		return
	end
	deltaEnv.__DeltaCustomizationModuleLoaded = true
end
local _ref = cloneref and type(cloneref) == "function" and cloneref or function(v)
	return v
end
local SRV = setmetatable({}, {
	__index = function(self, n)
		local ok, s = pcall(function()
			return __lt.cs(n, _ref)
		end)
		if ok and s then
			rawset(self, n, s)
			return s
		end
	end,
})
local function Svc(n)
	return SRV[n]
end
local UIS = Svc("UserInputService")
local CG = Svc("CoreGui")
local HS = Svc("HttpService")
local RS = Svc("RunService")
local Stats = Svc("Stats")
local TS = Svc("TweenService")
local notifMod
local nt
local colorsPath = "DeltaCustom/Colors.json"
local colorConfig = {}
do
	if HS and type(isfile) == "function" and type(readfile) == "function" then
		if isfile(colorsPath) then
			local ok, data = pcall(readfile, colorsPath)
			if ok and data then
				local ok2, decoded = pcall(function()
					return __lt.cm("HttpService", "JSONDecode", data)
				end)
				if ok2 and type(decoded) == "table" then
					colorConfig = decoded
				end
			end
		end
	end
end
local settingsPath = "DeltaCustom/Settings.json"
local settingsConfig = {}
do
	if HS and type(isfile) == "function" and type(readfile) == "function" then
		if isfile(settingsPath) then
			local ok, data = pcall(readfile, settingsPath)
			if ok and data then
				local ok2, decoded = pcall(function()
					return __lt.cm("HttpService", "JSONDecode", data)
				end)
				if ok2 and type(decoded) == "table" then
					settingsConfig = decoded
				end
			end
		end
	end
end
do
	local n = nil
	local tries = 0
	repeat
		tries += 1
		local s, r = pcall(function()
			return (loadstring(
				game:HttpGet(
					"https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/NamelessAdminNotifications.lua"
				)
			))()
		end)
		if s and type(r) == "table" and type(r.Notify) == "function" then
			n = r
			notifMod = r
			nt = r.Notify
		else
			task.wait(0.5)
		end
	until n ~= nil or tries >= 5
end
local function notify(info)
	if not nt or type(info) ~= "table" then
		return
	end
	pcall(function()
		nt(info)
	end)
end
local _naConns = _naConns or {}
local NAlib = {}
function NAlib.disconnect(n)
	local t = _naConns[n]
	if t then
		for _, c in ipairs(t) do
			pcall(function()
				c:Disconnect()
			end)
		end
		_naConns[n] = nil
	end
end
function NAlib.connect(n, c)
	if not c then
		return
	end
	_naConns[n] = _naConns[n] or {}
	table.insert(_naConns[n], c)
	return c
end
function NAlib.isProperty(o, p)
	return pcall(function()
		return o[p]
	end)
end
function NAlib.setProperty(o, p, v)
	pcall(function()
		o[p] = v
	end)
end
local uiLib = {}
uiLib.draggerV2 = function(ui, dragui)
	dragui = dragui or ui
	local dragging, dragInput, dragStart, startPos
	local anchor = ui.AnchorPoint
	local sg = ui:FindFirstAncestorWhichIsA("ScreenGui") or ui.Parent
	local function sClamp(v, lo, hi)
		if hi < lo then
			hi = lo
		end
		return math.clamp(v, lo, hi)
	end
	local function upd(input)
		pcall(function()
			local p = sg.AbsoluteSize
			local s = ui.AbsoluteSize
			if p.X <= 0 or p.Y <= 0 then
				return
			end
			local sx = startPos.X.Scale * p.X + startPos.X.Offset
			local sy = startPos.Y.Scale * p.Y + startPos.Y.Offset
			local dx = input.Position.X - dragStart.X
			local dy = input.Position.Y - dragStart.Y
			local minX = anchor.X * s.X
			local maxX = p.X - (1 - anchor.X) * s.X
			local minY = anchor.Y * s.Y
			local maxY = p.Y - (1 - anchor.Y) * s.Y
			local nx = sClamp(sx + dx, minX, maxX)
			local ny = sClamp(sy + dy, minY, maxY)
			ui.Position = UDim2.new(nx / p.X, 0, ny / p.Y, 0)
		end)
	end
	local id = "DraggerV2_" .. ui:GetDebugId()
	NAlib.disconnect(id)
	NAlib.connect(
		id,
		dragui.InputBegan:Connect(function(input)
			pcall(function()
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					dragging = true
					dragStart = input.Position
					startPos = ui.Position
					local c = input.Changed:Connect(function()
						pcall(function()
							if input.UserInputState == Enum.UserInputState.End then
								dragging = false
							end
						end)
					end)
					NAlib.connect(id, c)
				end
			end)
		end)
	)
	NAlib.connect(
		id,
		dragui.InputChanged:Connect(function(input)
			pcall(function()
				if
					input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
				then
					dragInput = input
				end
			end)
		end)
	)
	NAlib.connect(
		id,
		UIS.InputChanged:Connect(function(input)
			pcall(function()
				if input == dragInput and dragging then
					upd(input)
				end
			end)
		end)
	)
	local function clampToView()
		pcall(function()
			local p = sg.AbsoluteSize
			local s = ui.AbsoluteSize
			if p.X <= 0 or p.Y <= 0 then
				return
			end
			local pos = ui.Position
			local ax = pos.X.Scale * p.X + pos.X.Offset
			local ay = pos.Y.Scale * p.Y + pos.Y.Offset
			local minX = anchor.X * s.X
			local maxX = p.X - (1 - anchor.X) * s.X
			local minY = anchor.Y * s.Y
			local maxY = p.Y - (1 - anchor.Y) * s.Y
			local nx = sClamp(ax, minX, maxX)
			local ny = sClamp(ay, minY, maxY)
			ui.Position = UDim2.new(nx / p.X, 0, ny / p.Y, 0)
		end)
	end
	NAlib.connect(id, (sg:GetPropertyChangedSignal("AbsoluteSize")):Connect(clampToView))
	if ui and ui.GetPropertyChangedSignal then
		NAlib.connect(id, (ui:GetPropertyChangedSignal("AbsoluteSize")):Connect(clampToView))
	end
	clampToView()
	if ui and NAlib.isProperty(ui, "Active") then
		NAlib.setProperty(ui, "Active", true)
	end
	if dragui and NAlib.isProperty(dragui, "Active") then
		NAlib.setProperty(dragui, "Active", true)
	end
end
local root = gethui and gethui() or CG
local function isGib(n)
	if typeof(n) ~= "string" or n == "" then
		return false
	end
	return not n:match("^[%w _%-]+$")
end
local function getMain()
	for _, g in ipairs(root:GetChildren()) do
		if g:IsA("ScreenGui") and isGib(g.Name) then
			if
				g:FindFirstChild("Executor", true)
				and g:FindFirstChild("Scripthub", true)
				and g:FindFirstChild("Sidebar", true)
			then
				return g
			end
		end
	end
end
local function getIconGui()
	local function chk(g)
		if not (g:IsA("ScreenGui") and isGib(g.Name)) then
			return
		end
		local kids = g:GetChildren()
		local img
		local cnt = 0
		for _, c in ipairs(kids) do
			if c:IsA("ImageButton") then
				cnt += 1
				img = c
			else
				return
			end
		end
		if cnt == 1 then
			return g, img
		end
	end
	for _, g in ipairs(root:GetChildren()) do
		local ig, ib = chk(g)
		if ig then
			return ig, ib
		end
	end
end
local mainGui = getMain()
local iconGui, iconBtn = getIconGui()
local iconStroke = iconBtn
	and (iconBtn:FindFirstChildOfClass("UIStroke") or iconBtn:FindFirstChildWhichIsA("UIStroke", true))
local iconBaseColor = iconStroke and iconStroke.Color
local iconBaseSize = iconBtn and iconBtn.Size
local iconSzLock = false
local iconColorUseCustom = false
local iconApplyBusy = false
local updateIconStatusUI
local function refreshIconRefs()
	local ig, ib = getIconGui()
	local changed = ig ~= iconGui or ib ~= iconBtn
	iconGui = ig
	iconBtn = ib
	iconStroke = iconBtn
		and (iconBtn:FindFirstChildOfClass("UIStroke") or iconBtn:FindFirstChildWhichIsA("UIStroke", true))
	if iconBtn then
		if changed or not iconBaseSize then
			iconBaseSize = iconBtn.Size
		end
		if iconStroke and not iconColorUseCustom and (changed or not iconBaseColor) then
			iconBaseColor = iconStroke.Color
		end
	end
	return changed
end
local function fsOk()
	return type(isfile) == "function" and type(writefile) == "function"
end
local function gaOk()
	return type(getcustomasset) == "function"
end
local function iconFsOk()
	return fsOk() and gaOk()
end
local function trim(s)
	if type(s) ~= "string" then
		return ""
	end
	return s:match("^%s*(.-)%s*$") or ""
end
local function sName(name)
	if type(name) ~= "string" then
		return nil
	end
	local t = trim(name)
	t = t:gsub("[^%w%._%-]", "_")
	t = t:gsub("_+", "_")
	t = t:gsub("^_+", "")
	t = t:gsub("_+$", "")
	if t == "" then
		return nil
	end
	return t
end
local function getName(path)
	if type(path) ~= "string" then
		return nil
	end
	local n = path:gsub("\\", "/")
	return n:match("([^/]+)$")
end
local function fileFromUrl(u)
	if type(u) ~= "string" then
		return nil
	end
	return u:match("/([^/%?]+)$")
end
local function iconPreUrl(u)
	if type(u) ~= "string" then
		return nil
	end
	local t = trim(u)
	if t == "" then
		return nil
	end
	t = t:gsub(" ", "%%20")
	local q = t:find("%?")
	local base = q and t:sub(1, q - 1) or t
	return t, base
end
local function iconNormUrl(u)
	local t, base = iconPreUrl(u)
	if not t then
		return nil
	end
	local owner, repo, kind, rest = base:match("^https?://github.com/([^/]+)/([^/]+)/([^/]+)/(.+)$")
	if owner and repo and kind and rest then
		local s = rest
		if s:sub(1, 11) == "refs/heads/" then
			s = s:sub(12)
		elseif s:sub(1, 10) == "refs/tags/" then
			s = s:sub(11)
		end
		local branch, path = s:match("^([^/]+)/(.+)$")
		if branch and path and (kind == "blob" or kind == "raw") then
			branch = branch:gsub("%%2[Ff]", "/")
			path = path:gsub("%%2[Ff]", "/")
			return string.format("https://raw.githubusercontent.com/%s/%s/%s/%s", owner, repo, branch, path)
		end
	end
	local rawDir = base:match("^https?://raw%.githubusercontent%.com/.+")
	if rawDir then
		return t
	end
	return t
end
local function ensureDir(path)
	if not fsOk() then
		return false
	end
	if type(isfolder) == "function" then
		local ok, ex = pcall(isfolder, path)
		if ok and ex then
			return true
		end
		if type(makefolder) ~= "function" then
			return false
		end
		local okMk = pcall(makefolder, path)
		return okMk == true
	end
	return true
end
local baseDir = "DeltaCustom"
local iconDir = baseDir .. "/DeltaIcons"
local cfgPath = baseDir .. "/delta_icon.json"
local dIcons = {
	entries = {},
	index = 0,
	enabled = false,
	localPath = "",
	assetId = "",
	defaultImage = "",
	pendingInput = "",
}
local function ensureIconDir()
	if not ensureDir(baseDir) then
		return false
	end
	return ensureDir(iconDir)
end
local function loadIconCfg()
	if not fsOk() or not HS then
		return
	end
	if type(isfolder) == "function" and type(makefolder) == "function" then
		local okB, exB = pcall(isfolder, baseDir)
		if not (okB and exB) then
			pcall(makefolder, baseDir)
		end
	end
	if type(isfile) == "function" and type(writefile) == "function" then
		if not isfile(cfgPath) then
			pcall(
				writefile,
				cfgPath,
				__lt.cm("HttpService", "JSONEncode", {
					enabled = false,
					assetId = "",
					localPath = "",
					index = 0,
				})
			)
		end
	end
	if type(isfile) ~= "function" or type(readfile) ~= "function" then
		return
	end
	if not isfile(cfgPath) then
		return
	end
	local ok, raw = pcall(readfile, cfgPath)
	if not (ok and type(raw) == "string") then
		return
	end
	local okD, dec = pcall(HS.JSONDecode, HS, raw)
	if not (okD and type(dec) == "table") then
		return
	end
	if type(dec.enabled) == "boolean" then
		dIcons.enabled = dec.enabled
	end
	if type(dec.assetId) == "string" then
		dIcons.assetId = dec.assetId
	end
	if type(dec.localPath) == "string" then
		dIcons.localPath = dec.localPath
	end
	if type(dec.index) == "number" then
		dIcons.index = dec.index
	end
end
local function saveIconCfg()
	if not fsOk() or not HS then
		return
	end
	local payload = {
		enabled = dIcons.enabled and true or false,
		assetId = type(dIcons.assetId) == "string" and dIcons.assetId or "",
		localPath = type(dIcons.localPath) == "string" and dIcons.localPath or "",
		index = tonumber(dIcons.index) or 0,
	}
	pcall(writefile, cfgPath, __lt.cm("HttpService", "JSONEncode", payload))
end
local function scanIcons()
	dIcons.entries = {}
	dIcons.index = 0
	if not (fsOk() and type(listfiles) == "function") then
		return
	end
	if not ensureIconDir() then
		return
	end
	local ok, items = pcall(listfiles, iconDir)
	if not (ok and type(items) == "table") then
		return
	end
	local list = {}
	for _, full in ipairs(items) do
		local n = getName(full)
		if n then
			list[#list + 1] = { file = n }
		end
	end
	dIcons.entries = list
	if type(dIcons.localPath) == "string" and dIcons.localPath ~= "" then
		local cur = getName(dIcons.localPath)
		if cur then
			for i, e in ipairs(list) do
				if e.file == cur then
					dIcons.index = i
					if updateIconStatusUI then
						updateIconStatusUI()
					end
					return
				end
			end
		end
	end
	if #list > 0 then
		dIcons.index = 1
	end
	if updateIconStatusUI then
		updateIconStatusUI()
	end
end
local function formatIconStatus()
	local list = dIcons.entries
	local n = #list
	if n == 0 then
		return "No custom icons installed"
	end
	if n == 1 then
		return "1 custom icon installed"
	end
	return tostring(n) .. " custom icons installed"
end
local function resolveIconAsset(full)
	if not gaOk() or type(full) ~= "string" or full == "" then
		return nil
	end
	local tried = {}
	local function tryPath(path)
		if type(path) ~= "string" or path == "" or tried[path] then
			return nil
		end
		tried[path] = true
		local okA, asset = pcall(getcustomasset, path)
		if okA and type(asset) == "string" and asset ~= "" then
			return asset
		end
		return nil
	end
	local asset = tryPath(full)
	if asset then
		return asset
	end
	local slash = full:gsub("\\", "/")
	if slash ~= full then
		asset = tryPath(slash)
		if asset then
			return asset
		end
	end
	local back = full:gsub("/", "\\")
	if back ~= full then
		asset = tryPath(back)
		if asset then
			return asset
		end
	end
	local name = getName(full)
	if name then
		asset = tryPath(iconDir .. "/" .. name) or tryPath(iconDir .. "\\" .. name) or tryPath(name)
		if asset then
			return asset
		end
	end
	return nil
end
local function iconHttpGetBinary(url, headers)
	if type(url) ~= "string" or url == "" then
		return nil
	end
	local function tryRequest(hdr)
		if type(rq) ~= "function" then
			return nil
		end
		local h = {}
		if type(hdr) == "table" then
			for k, v in pairs(hdr) do
				h[k] = v
			end
		end
		h["User-Agent"] = h["User-Agent"] or "Roblox/Http/1.1"
		h["Accept"] = h["Accept"] or "*/*"
		local ok, res = pcall(rq, {
			Url = url,
			Method = "GET",
			Headers = h,
		})
		if ok and res then
			local code = res.StatusCode or res.Status or res.status_code or 0
			local body = res.Body or res.body
			if (code == 0 or (code >= 200 and code < 300)) and type(body) == "string" and body ~= "" then
				return body
			end
		end
		return nil
	end
	local data = tryRequest(headers)
	if type(data) == "string" and data ~= "" then
		return data
	end
	local ok2, body2 = pcall(function()
		return game:HttpGet(url)
	end)
	if ok2 and type(body2) == "string" and body2 ~= "" then
		return body2
	end
	return tryRequest(nil)
end
local function iconSaveFromUrl(url)
	if not iconFsOk() then
		return false, "Custom icons require file support and getcustomasset."
	end
	if not ensureIconDir() then
		return false, "Unable to prepare DeltaIcons folder."
	end
	local norm = iconNormUrl(url)
	if not norm then
		return false, "Enter a valid image URL or asset id."
	end
	local data = iconHttpGetBinary(norm)
	if not (type(data) == "string" and data ~= "") then
		return false, "Unable to download icon image."
	end
	local remote = fileFromUrl(norm) or "DeltaIcon.png"
	local safe = sName(remote) or "icon_" .. tostring(os.time()) .. ".png"
	local full = iconDir .. "/" .. safe
	local okW, errW = pcall(writefile, full, data)
	if not okW then
		return false, errW or "Unable to save icon image."
	end
	local asset = resolveIconAsset(full)
	if not asset then
		return false, "Unable to load icon image."
	end
	dIcons.localPath = full
	local list = dIcons.entries
	local idx
	for i, e in ipairs(list) do
		if e.file == safe then
			idx = i
			break
		end
	end
	if not idx then
		list[#list + 1] = { file = safe }
		idx = #list
	end
	dIcons.entries = list
	dIcons.index = idx
	if updateIconStatusUI then
		updateIconStatusUI()
	end
	return true, asset
end
local function applyIcon()
	refreshIconRefs()
	if not iconBtn or (not iconBtn:IsA("ImageButton")) then
		return false
	end
	local img
	if dIcons.enabled and type(dIcons.assetId) == "string" and dIcons.assetId ~= "" then
		img = dIcons.assetId
	elseif type(dIcons.defaultImage) == "string" and dIcons.defaultImage ~= "" then
		img = dIcons.defaultImage
	end
	iconApplyBusy = true
	if img and img ~= "" then
		iconBtn.Image = img
		iconApplyBusy = false
		return true
	else
		iconBtn.Image = ""
	end
	iconApplyBusy = false
	return false
end
local function setIconEnabled(flag)
	if not iconFsOk() then
		return false, "Custom icon requires file support and getcustomasset."
	end
	flag = flag and true or false
	if flag and (not dIcons.assetId or dIcons.assetId == "") then
		return false, "Add an asset id or image URL before enabling."
	end
	dIcons.enabled = flag
	applyIcon()
	saveIconCfg()
	return true
end
local function setIconAsset(input, opts)
	opts = opts or {}
	if not iconFsOk() then
		return false, "Custom icon requires file support and getcustomasset."
	end
	local raw = type(input) == "string" and input or tostring(input)
	if type(raw) ~= "string" then
		return false, "Enter a valid asset id or image URL."
	end
	raw = trim(raw)
	if raw == "" then
		return false, "Enter a valid asset id or image URL."
	end
	local digits = raw:match("^rbxassetid://(%d+)$") or raw:match("id=(%d+)") or raw:match("^(%d+)$")
	local newAsset
	dIcons.localPath = ""
	if digits then
		newAsset = "rbxassetid://" .. digits
	else
		local okIcon, res = iconSaveFromUrl(raw)
		if not okIcon then
			return false, res or "Unable to save custom icon."
		end
		newAsset = res
		scanIcons()
	end
	dIcons.assetId = newAsset
	if opts.autoEnable ~= false then
		dIcons.enabled = true
	end
	applyIcon()
	saveIconCfg()
	if digits then
		return true, digits
	end
	return true, raw
end
local function cycleIcon(delta)
	local list = dIcons.entries
	if #list == 0 then
		return
	end
	delta = delta or 1
	local idx = dIcons.index or 1
	if idx < 1 or idx > #list then
		idx = 1
	end
	idx = (idx - 1 + delta) % #list + 1
	local e = list[idx]
	if not e or not e.file then
		return
	end
	local full = iconDir .. "/" .. e.file
	if fsOk() and type(isfile) == "function" then
		local okEx, ex = pcall(isfile, full)
		if not (okEx and ex) then
			scanIcons()
			return
		end
	end
	local asset = resolveIconAsset(full)
	if not asset then
		return
	end
	dIcons.localPath = full
	dIcons.assetId = asset
	dIcons.index = idx
	dIcons.enabled = true
	applyIcon()
	saveIconCfg()
	if updateIconStatusUI then
		updateIconStatusUI()
	end
end
local function delIconFile(name)
	if type(name) ~= "string" or name == "" then
		return
	end
	if not (fsOk() and type(delfile) == "function" and type(isfile) == "function") then
		return
	end
	local full = iconDir .. "/" .. name
	local okEx, ex = pcall(isfile, full)
	if okEx and ex then
		pcall(delfile, full)
	end
end
local function clearIfCurrent(name)
	if type(name) ~= "string" or name == "" then
		return
	end
	local full = iconDir .. "/" .. name
	if dIcons.localPath == full then
		dIcons.localPath = ""
		dIcons.assetId = ""
		dIcons.index = 0
		dIcons.enabled = false
		applyIcon()
		saveIconCfg()
	end
end
local function removeIconEntry(entry)
	if not (entry and entry.file) then
		return
	end
	delIconFile(entry.file)
	clearIfCurrent(entry.file)
	scanIcons()
end
local function removeAllIcons()
	local list = dIcons.entries or {}
	for _, e in ipairs(list) do
		if e and e.file then
			delIconFile(e.file)
		end
	end
	dIcons.entries = {}
	dIcons.index = 0
	dIcons.localPath = ""
	dIcons.assetId = ""
	dIcons.enabled = false
	applyIcon()
	saveIconCfg()
	scanIcons()
end
refreshIconRefs()
if iconBtn and type(iconBtn.Image) == "string" and iconBtn.Image ~= "" then
	dIcons.defaultImage = iconBtn.Image
end
loadIconCfg()
scanIcons()
local function refreshIconFromPath()
	if not iconFsOk() then
		return
	end
	if type(dIcons.localPath) ~= "string" or dIcons.localPath == "" then
		return
	end
	local full = dIcons.localPath
	local okEx, ex = pcall(isfile, full)
	if not (okEx and ex) then
		dIcons.localPath = ""
		dIcons.assetId = ""
		dIcons.enabled = false
		saveIconCfg()
		return
	end
	local asset = resolveIconAsset(full)
	if not asset then
		dIcons.assetId = ""
		dIcons.enabled = false
		saveIconCfg()
		return
	end
	dIcons.assetId = asset
	saveIconCfg()
end
refreshIconFromPath()
if dIcons.enabled and type(dIcons.assetId) == "string" and dIcons.assetId ~= "" then
	applyIcon()
end
local function bindIconButtonWatcher()
	NAlib.disconnect("DeltaIcon_ImageWatcher")
	if not (iconBtn and iconBtn:IsA("ImageButton")) then
		return
	end
	NAlib.connect(
		"DeltaIcon_ImageWatcher",
		iconBtn:GetPropertyChangedSignal("Image"):Connect(function()
			if iconApplyBusy then
				return
			end
			if
				dIcons.enabled
				and type(dIcons.assetId) == "string"
				and dIcons.assetId ~= ""
				and iconBtn.Image ~= dIcons.assetId
			then
				task.defer(applyIcon)
			end
		end)
	)
end
local function refreshIconButtonState()
	local changed = refreshIconRefs()
	if iconBtn and type(iconBtn.Image) == "string" and iconBtn.Image ~= "" then
		if
			not (
				dIcons.enabled
				and type(dIcons.assetId) == "string"
				and dIcons.assetId ~= ""
				and iconBtn.Image == dIcons.assetId
			)
		then
			dIcons.defaultImage = iconBtn.Image
		end
	end
	bindIconButtonWatcher()
	if changed and dIcons.enabled and type(dIcons.assetId) == "string" and dIcons.assetId ~= "" then
		task.defer(applyIcon)
	end
end
refreshIconButtonState()
NAlib.disconnect("DeltaIcon_RootChildAdded")
NAlib.connect(
	"DeltaIcon_RootChildAdded",
	root.ChildAdded:Connect(function()
		task.defer(refreshIconButtonState)
	end)
)
local deltaIconApi = {
	status = formatIconStatus,
	setEnabled = setIconEnabled,
	setAsset = setIconAsset,
	cycle = cycleIcon,
	scan = scanIcons,
	removeEntry = removeIconEntry,
	removeAll = removeAllIcons,
	data = dIcons,
}
deltaEnv.DeltaIcon = deltaIconApi
task.defer(function()
	while not mainGui do
		mainGui = getMain()
		if mainGui then
			break
		end
		task.wait(0.1)
	end
	if not mainGui then
		notify({
			Title = "Delta Customization",
			Description = "Failed to find Delta UI.",
			Duration = 4,
		})
		return
	end
	pcall(function()
		mainGui.IgnoreGuiInset = true
	end)
	local execFrame = mainGui:FindFirstChild("Executor")
	if not (execFrame and execFrame:IsA("Frame")) then
		notify({
			Title = "Delta Customization",
			Description = "Executor frame not found.",
			Duration = 4,
		})
		return
	end
	local execImage = execFrame:FindFirstChild("Executor")
	if not (execImage and execImage:IsA("ImageLabel")) then
		notify({
			Title = "Delta Customization",
			Description = "Executor image not found.",
			Duration = 4,
		})
		return
	end
	local overlay = execImage:FindFirstChild("Overlay")
	if not overlay then
		notify({
			Title = "Delta Customization",
			Description = "Overlay frame not found.",
			Duration = 4,
		})
		return
	end
	local sidebar = mainGui:FindFirstChild("Sidebar", true)
	local toggleUIBtn = sidebar and sidebar:FindFirstChild("ToggleUI", true)
	local activeColorValue = sidebar and sidebar:FindFirstChild("ActiveColor")
	local inactiveColorValue = sidebar and sidebar:FindFirstChild("InactiveColor")
	local darkOverlay = mainGui:FindFirstChild("DarkOverlay")
	local sidebarGradient = nil
	local sidebarGrad1 = nil
	local sidebarGrad2 = nil
	local sidebarClosedPos = UDim2.new(1.08, 0, 0.5, 0)
	local sidebarOpenPos = UDim2.new(1, 0, 0.5, 0)
	local sidebarNormalizeBusy = false
	local function normalizeSidebarGeometry()
		if sidebarNormalizeBusy or not (sidebar and sidebar:IsA("GuiObject")) then
			return
		end
		sidebarNormalizeBusy = true
		pcall(function()
			if sidebar.Size.Y.Scale ~= 1 or sidebar.Size.Y.Offset ~= 0 then
				sidebar.Size = UDim2.new(sidebar.Size.X.Scale, sidebar.Size.X.Offset, 1, 0)
			end
			if sidebar.Position.Y.Scale ~= 0.5 or sidebar.Position.Y.Offset ~= 0 then
				sidebar.Position = UDim2.new(sidebar.Position.X.Scale, sidebar.Position.X.Offset, 0.5, 0)
			end
		end)
		sidebarNormalizeBusy = false
	end
	local function setSidebarPosition(targetPos)
		if not (sidebar and sidebar:IsA("GuiObject")) then
			return
		end
		sidebar.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, 0.5, 0)
	end
	if sidebar and sidebar:IsA("GuiObject") then
		normalizeSidebarGeometry()
		NAlib.disconnect("Sidebar_NormalizeGeometry")
		NAlib.connect(
			"Sidebar_NormalizeGeometry",
			sidebar:GetPropertyChangedSignal("Size"):Connect(function()
				task.defer(normalizeSidebarGeometry)
			end)
		)
		NAlib.connect(
			"Sidebar_NormalizeGeometry",
			sidebar:GetPropertyChangedSignal("Position"):Connect(function()
				task.defer(normalizeSidebarGeometry)
			end)
		)
	end
	if iconGui and iconGui:IsA("ScreenGui") then
		pcall(function()
			iconGui.IgnoreGuiInset = true
		end)
	end
	if iconBtn then
		pcall(function()
			iconBtn.Draggable = false
		end)
		uiLib.draggerV2(iconBtn, iconBtn)
	end
	if darkOverlay then
		darkOverlay.Visible = false
		NAlib.connect(
			"DarkOverlay_Hide",
			darkOverlay:GetPropertyChangedSignal("Visible"):Connect(function()
				darkOverlay.Visible = false
			end)
		)
	end
	local settingsFrame
	do
		local cand = mainGui:FindFirstChild("Settings", true)
		if cand and cand:IsA("Frame") and cand:FindFirstChild("Holder") then
			settingsFrame = cand
		end
	end
	local settingsHolder = settingsFrame and settingsFrame:FindFirstChild("Holder")
	local settingTemplate
	local function setupAutoScroll(sf, fixRows)
		if not (sf and sf:IsA("ScrollingFrame")) then
			return
		end
		pcall(function()
			sf.AutomaticCanvasSize = Enum.AutomaticSize.None
			sf.CanvasSize = UDim2.new(0, 0, 0, 0)
		end)
		local lay = sf:FindFirstChildWhichIsA("UIListLayout") or sf:FindFirstChildWhichIsA("UIGridLayout")
		if not lay then
			return
		end
		local id = "CanvasAuto_" .. sf:GetDebugId()
		NAlib.disconnect(id)
		local function isVisibleInScroll(gui)
			local cur = gui
			while cur and cur ~= sf do
				if cur:IsA("GuiObject") and not cur.Visible then
					return false
				end
				cur = cur.Parent
			end
			return cur == sf
		end
		local function descendantBounds()
			local maxX = 0
			local maxY = 0
			local canvasPos = sf.CanvasPosition
			for _, desc in ipairs(sf:GetDescendants()) do
				if desc:IsA("GuiObject") and isVisibleInScroll(desc) then
					local relX = (desc.AbsolutePosition.X - sf.AbsolutePosition.X) + canvasPos.X
					local relY = (desc.AbsolutePosition.Y - sf.AbsolutePosition.Y) + canvasPos.Y
					maxX = math.max(maxX, relX + desc.AbsoluteSize.X)
					maxY = math.max(maxY, relY + desc.AbsoluteSize.Y)
				end
			end
			return maxX, maxY
		end
		local function applyRows()
			if not fixRows then
				return
			end
			for _, ch in ipairs(sf:GetChildren()) do
				if
					ch:IsA("GuiObject")
					and not ch:IsA("UIListLayout")
					and not ch:IsA("UIGridLayout")
					and not ch:IsA("UIPadding")
				then
					local s = ch.Size
					if s.Y.Scale ~= 0 or s.Y.Offset ~= 50 then
						ch.Size = UDim2.new(s.X.Scale, s.X.Offset, 0, 50)
					end
				end
			end
		end
		local function upd()
			applyRows()
			local size = lay.AbsoluteContentSize
			local descX, descY = descendantBounds()
			local x = math.max(0, math.floor(math.max(size.X, descX) + 0.5))
			local y = math.max(0, math.floor(math.max(size.Y + 12.5, descY + 12.5) + 0.5))
			pcall(function()
				sf.CanvasSize = UDim2.new(0, x, 0, y)
			end)
		end
		local function bindGui(gui)
			if not (gui and gui:IsA("GuiObject")) then
				return
			end
			NAlib.connect(
				id,
				gui:GetPropertyChangedSignal("Visible"):Connect(function()
					task.defer(upd)
				end)
			)
			NAlib.connect(
				id,
				gui:GetPropertyChangedSignal("Size"):Connect(function()
					task.defer(upd)
				end)
			)
			NAlib.connect(
				id,
				gui:GetPropertyChangedSignal("Position"):Connect(function()
					task.defer(upd)
				end)
			)
			NAlib.connect(
				id,
				gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					task.defer(upd)
				end)
			)
		end
		for _, desc in ipairs(sf:GetDescendants()) do
			bindGui(desc)
		end
		upd()
		NAlib.connect(id, lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(upd))
		NAlib.connect(
			id,
			sf.DescendantAdded:Connect(function(desc)
				bindGui(desc)
				task.defer(upd)
			end)
		)
		NAlib.connect(
			id,
			sf.DescendantRemoving:Connect(function()
				task.defer(upd)
			end)
		)
		NAlib.connect(
			id,
			sf:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				task.defer(upd)
			end)
		)
	end
	local function mkDock(fr)
		local d = Instance.new("Frame")
		d.Name = "Dock"
		d.BackgroundTransparency = 1
		d.AnchorPoint = Vector2.new(1, 0.5)
		d.Position = UDim2.new(1, -14, 0.5, 0)
		d.Size = UDim2.new(0, 320, 0, 18)
		d.Parent = fr
		local l = Instance.new("UIListLayout")
		l.FillDirection = Enum.FillDirection.Horizontal
		l.HorizontalAlignment = Enum.HorizontalAlignment.Right
		l.VerticalAlignment = Enum.VerticalAlignment.Center
		l.Padding = UDim.new(0, 8)
		l.Parent = d
		return d
	end
	local function mkTog(par)
		local t = Instance.new("TextButton")
		t.Name = "Toggle"
		t.Size = UDim2.new(0, 18, 0, 18)
		t.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		t.BorderSizePixel = 0
		t.Font = Enum.Font.GothamBold
		t.TextSize = 11
		t.TextColor3 = Color3.new(1, 1, 1)
		t.Text = "C"
		t.Parent = par
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = t
		return t
	end
	local function mkBox(par)
		local b = Instance.new("TextBox")
		b.Name = "ValueBox"
		b.Size = UDim2.new(0, 70, 0, 18)
		b.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		b.BorderSizePixel = 0
		b.ClearTextOnFocus = false
		b.TextXAlignment = Enum.TextXAlignment.Center
		b.Font = Enum.Font.Gotham
		b.TextSize = 12
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Parent = par
		return b
	end
	local function mkSl(par, w)
		local s = Instance.new("Frame")
		s.Name = "Slider"
		s.BackgroundTransparency = 1
		s.Size = UDim2.new(0, w or 150, 0, 18)
		s.Parent = par
		local bar = Instance.new("Frame")
		bar.Name = "Bar"
		bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		bar.BorderSizePixel = 0
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.new(0.5, 0, 0.5, 0)
		bar.Size = UDim2.new(1, 0, 0, 6)
		bar.Parent = s
		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(0, 3)
		bc.Parent = bar
		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BorderSizePixel = 0
		fill.AnchorPoint = Vector2.new(0, 0.5)
		fill.Position = UDim2.new(0, 0, 0.5, 0)
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.Parent = bar
		local fc = Instance.new("UICorner")
		fc.CornerRadius = UDim.new(0, 3)
		fc.Parent = fill
		local kb = Instance.new("Frame")
		kb.Name = "Knob"
		kb.Size = UDim2.new(0, 12, 0, 12)
		kb.AnchorPoint = Vector2.new(0.5, 0.5)
		kb.BackgroundColor3 = Color3.new(1, 1, 1)
		kb.BorderSizePixel = 0
		kb.Parent = bar
		local kc = Instance.new("UICorner")
		kc.CornerRadius = UDim.new(1, 0)
		kc.Parent = kb
		return s, bar, fill, kb
	end
	if settingsHolder then
		for _, c in ipairs(settingsHolder:GetChildren()) do
			if c:IsA("Frame") and c.Name == "Button" then
				settingTemplate = c
				break
			end
		end
	end
	if settingsHolder and settingTemplate then
		local function makeSectionTitle(text, order, isCustom)
			local f = settingTemplate:Clone()
			f.Name = isCustom and "Section_Customization" or "Section_Delta"
			f.Parent = settingsHolder
			f.LayoutOrder = order
			for _, d in ipairs(f:GetDescendants()) do
				if d:IsA("LocalScript") then
					d:Destroy()
				end
			end
			local btn = f:FindFirstChild("Button", true)
			if btn then
				btn:Destroy()
			end
			local tLabel = f:FindFirstChild("Title", true)
			local dLabel = f:FindFirstChild("Desc", true)
			local baseCol = isCustom and Color3.fromRGB(79, 164, 242) or Color3.fromRGB(112, 118, 132)
			local fillCol = Color3.fromRGB(25, 28, 35)
			local edgeCol = isCustom and Color3.fromRGB(88, 152, 223) or Color3.fromRGB(63, 68, 80)
			f.BackgroundColor3 = fillCol
			local outline = f:FindFirstChildWhichIsA("UIStroke", true)
			if outline then
				outline.Color = edgeCol
				outline.Transparency = 0.34
				outline.Thickness = 1
			end
			local panelGrad = f:FindFirstChildWhichIsA("UIGradient", true)
			if panelGrad then
				panelGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 31, 38)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(23, 25, 31)),
				})
				panelGrad.Rotation = 0
			else
				panelGrad = Instance.new("UIGradient")
				panelGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(28, 31, 38)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(23, 25, 31)),
				})
				panelGrad.Rotation = 0
				panelGrad.Parent = f
			end
			if tLabel then
				tLabel.Text = isCustom and "Customization" or "Delta settings"
				tLabel.AnchorPoint = Vector2.new(0, 0.5)
				tLabel.Position = UDim2.new(0, 16, 0.5, 0)
				tLabel.Size = UDim2.new(1, -32, 0, 18)
				tLabel.TextColor3 = Color3.fromRGB(236, 240, 247)
				tLabel.TextYAlignment = Enum.TextYAlignment.Center
				if isCustom then
					local textGrad = tLabel:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
					textGrad.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(
							0,
							activeColorValue and activeColorValue.Value or Color3.fromRGB(79, 164, 242)
						),
						ColorSequenceKeypoint.new(0.5, Color3.fromRGB(235, 244, 255)),
						ColorSequenceKeypoint.new(
							1,
							inactiveColorValue and inactiveColorValue.Value or Color3.fromRGB(63, 72, 92)
						),
					})
					textGrad.Offset = Vector2.new(-0.8, 0)
					textGrad.Parent = tLabel
					local function refreshCustomSectionColors()
						local activeCol = activeColorValue and activeColorValue.Value or Color3.fromRGB(79, 164, 242)
						local inactiveCol = inactiveColorValue and inactiveColorValue.Value
							or Color3.fromRGB(63, 72, 92)
						textGrad.Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, activeCol),
							ColorSequenceKeypoint.new(0.5, Color3.fromRGB(235, 244, 255)),
							ColorSequenceKeypoint.new(1, inactiveCol),
						})
						if panelGrad then
							panelGrad.Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, activeCol:Lerp(Color3.fromRGB(14, 16, 22), 0.74)),
								ColorSequenceKeypoint.new(1, inactiveCol:Lerp(Color3.fromRGB(14, 16, 22), 0.8)),
							})
						end
					end
					refreshCustomSectionColors()
					if activeColorValue then
						activeColorValue:GetPropertyChangedSignal("Value"):Connect(refreshCustomSectionColors)
					end
					if inactiveColorValue then
						inactiveColorValue:GetPropertyChangedSignal("Value"):Connect(refreshCustomSectionColors)
					end
					if TS then
						local alive = true
						f.Destroying:Connect(function()
							alive = false
						end)
						local function animateTextGradient()
							if not alive or not textGrad.Parent then
								return
							end
							textGrad.Offset = Vector2.new(-0.8, 0)
							local tw = TS:Create(
								textGrad,
								TweenInfo.new(1.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
								{
									Offset = Vector2.new(0.8, 0),
								}
							)
							tw:Play()
							tw.Completed:Connect(function()
								if alive then
									task.delay(0.12, animateTextGradient)
								end
							end)
						end
						local function animateBackground()
							if not alive or not f.Parent then
								return
							end
							local activeCol = activeColorValue and activeColorValue.Value
								or Color3.fromRGB(79, 164, 242)
							local inactiveCol = inactiveColorValue and inactiveColorValue.Value
								or Color3.fromRGB(63, 72, 92)
							local a = activeCol:Lerp(Color3.fromRGB(12, 14, 18), 0.78)
							local b = inactiveCol:Lerp(Color3.fromRGB(12, 14, 18), 0.78)
							local tw1 =
								TS:Create(f, TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
									BackgroundColor3 = a,
								})
							tw1:Play()
							tw1.Completed:Connect(function()
								if not alive or not f.Parent then
									return
								end
								local tw2 = TS:Create(
									f,
									TweenInfo.new(1.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
									{
										BackgroundColor3 = b,
									}
								)
								tw2:Play()
								tw2.Completed:Connect(function()
									if alive then
										animateBackground()
									end
								end)
							end)
						end
						animateTextGradient()
						animateBackground()
					end
				end
			end
			if dLabel then
				dLabel.Text = ""
				dLabel.Visible = false
			end
			return f
		end
		makeSectionTitle("Customization", -3, true)
		makeSectionTitle("Delta settings", -1, false)
	end
	if sidebar then
		local existingGrad = sidebar:FindFirstChildOfClass("UIGradient")
		local c1
		local c2
		if existingGrad then
			local kps = existingGrad.Color.Keypoints
			c1 = kps[1] and kps[1].Value or Color3.fromRGB(79, 164, 242)
			c2 = kps[#kps] and kps[#kps].Value or Color3.fromRGB(28, 34, 46)
			sidebarGradient = existingGrad
		else
			c1 = Color3.fromRGB(79, 164, 242)
			c2 = Color3.fromRGB(28, 34, 46)
			sidebarGradient = Instance.new("UIGradient")
			sidebarGradient.Name = "DeltaCustomGradient"
			sidebarGradient.Parent = sidebar
		end
		sidebarGradient.Rotation = 100
		sidebarGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, c1),
			ColorSequenceKeypoint.new(1, c2),
		})
		sidebarGrad1 = Instance.new("Color3Value")
		sidebarGrad1.Name = "SidebarGradientColor1"
		sidebarGrad1.Value = c1
		sidebarGrad2 = Instance.new("Color3Value")
		sidebarGrad2.Name = "SidebarGradientColor2"
		sidebarGrad2.Value = c2
		local sidebarSnapPending = false
		(sidebar:GetPropertyChangedSignal("Position")):Connect(function()
			local p = sidebar.Position
			if p.X.Scale > sidebarOpenPos.X.Scale and not sidebarSnapPending then
				sidebarSnapPending = true
				task.spawn(function()
					local last = p
					local stable = 0
					local step = 0.05
					while stable < 0.1 do
						task.wait(step)
						local cur = sidebar.Position
						if cur ~= last then
							last = cur
							stable = 0
						else
							stable += step
						end
					end
					sidebarSnapPending = false
					if sidebar.Parent and sidebar.Position.X.Scale > sidebarOpenPos.X.Scale then
						setSidebarPosition(sidebarClosedPos)
						normalizeSidebarGeometry()
					end
				end)
			end
		end)
	end
	local iconColorValue
	if iconStroke then
		iconColorValue = Instance.new("Color3Value")
		iconColorValue.Name = "IconColorValue"
		iconColorValue.Value = iconBaseColor or iconStroke.Color
		NAlib.connect(
			"IconColorValue_Changed",
			iconColorValue.Changed:Connect(function()
				if not iconColorUseCustom then
					return
				end
				pcall(function()
					iconStroke.Color = iconColorValue.Value
				end)
			end)
		)
	end
	local iconSizeValue
	if iconBtn and iconBaseSize then
		iconSizeValue = Instance.new("NumberValue")
		iconSizeValue.Name = "IconSizeValue"
		iconSizeValue.Value = 1
		local sizeCfg = settingsConfig.IconSize
		if type(sizeCfg) == "table" and type(sizeCfg.value) == "number" then
			iconSizeValue.Value = math.clamp(sizeCfg.value, 0.5, 5)
		end
		local function applyIconSize(v)
			v = math.clamp(v, 0.5, 5)
			if not iconBtn or not iconBaseSize then
				return
			end
			iconSzLock = true
			iconBtn.Size = UDim2.new(
				iconBaseSize.X.Scale * v,
				iconBaseSize.X.Offset * v,
				iconBaseSize.Y.Scale * v,
				iconBaseSize.Y.Offset * v
			)
			iconSzLock = false
		end
		if iconBtn and iconBtn.GetPropertyChangedSignal and mainGui and mainGui.GetPropertyChangedSignal then
			NAlib.connect(
				"IconSizeRebase",
				(mainGui:GetPropertyChangedSignal("AbsoluteSize")):Connect(function()
					task.defer(function()
						if iconBtn and iconSizeValue and not iconSzLock then
							local v = math.clamp(iconSizeValue.Value, 0.5, 5)
							local s = iconBtn.Size
							iconBaseSize = UDim2.new(s.X.Scale / v, s.X.Offset / v, s.Y.Scale / v, s.Y.Offset / v)
							applyIconSize(v)
						end
					end)
				end)
			)
		end
		NAlib.connect(
			"IconSizeValue_Changed",
			iconSizeValue.Changed:Connect(function()
				applyIconSize(iconSizeValue.Value)
				if HS and type(writefile) == "function" then
					settingsConfig.IconSize = { value = math.clamp(iconSizeValue.Value, 0.5, 5) }
					local ok, encoded = pcall(function()
						return __lt.cm("HttpService", "JSONEncode", settingsConfig)
					end)
					if ok and encoded then
						pcall(writefile, settingsPath, encoded)
					end
				end
			end)
		)
		applyIconSize(iconSizeValue.Value)
	end
	local iconRgbSpeedValue
	if iconStroke then
		iconRgbSpeedValue = Instance.new("NumberValue")
		iconRgbSpeedValue.Name = "IconRgbSpeedValue"
		local sp = 0.2
		local spCfg = settingsConfig.IconRgbSpeed
		if type(spCfg) == "table" and type(spCfg.value) == "number" then
			sp = math.clamp(spCfg.value, 0.05, 2)
		end
		iconRgbSpeedValue.Value = sp
	end
	local iconVisible = true
	do
		local cfg = settingsConfig.IconVisible
		if type(cfg) == "table" and cfg.enabled ~= nil then
			iconVisible = cfg.enabled and true or false
		end
	end
	local tabNotifEnabled = true
	do
		local cfg = settingsConfig.TabNotifications
		if type(cfg) == "table" and cfg.enabled ~= nil then
			tabNotifEnabled = cfg.enabled and true or false
		end
	end
	local function tweenIconVisual(imgT, bgT, instant)
		if not iconBtn then
			return
		end
		if TS and not instant then
			pcall(function()
				(__lt.cm(
					"TweenService",
					"Create",
					iconBtn,
					TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						ImageTransparency = imgT,
						BackgroundTransparency = bgT,
					}
				)):Play()
			end)
		else
			pcall(function()
				iconBtn.ImageTransparency = imgT
				iconBtn.BackgroundTransparency = bgT
			end)
		end
	end
	local function applyIconUserVisibility(instant)
		if not iconBtn then
			return
		end
		if iconVisible then
			tweenIconVisual(0, 0, instant)
			if iconStroke then
				iconStroke.Enabled = true
			end
		else
			tweenIconVisual(1, 1, instant)
			if iconStroke then
				iconStroke.Enabled = false
			end
		end
	end
	local function setIconForcedHidden(hidden)
		if not iconBtn then
			return
		end
		if hidden then
			tweenIconVisual(1, 1, false)
			if iconStroke then
				iconStroke.Enabled = false
			end
		else
			applyIconUserVisibility(false)
		end
	end
	applyIconUserVisibility(true)
	local scriptHubHolder
	local homeHolder
	do
		local sh = mainGui:FindFirstChild("Scripthub")
		if sh then
			scriptHubHolder = sh:FindFirstChild("Holder")
		end
		local ho = mainGui:FindFirstChild("Home")
		if ho then
			homeHolder = ho:FindFirstChild("Holder")
		end
	end
	setupAutoScroll(settingsHolder, true)
	setupAutoScroll(scriptHubHolder, false)
	setupAutoScroll(homeHolder, true)
	local function makeColorSlider(id, tt, dt, cVal)
		if not (settingsHolder and settingTemplate and cVal) then
			return
		end
		local key = id or tt or "Color_" .. tostring(math.random(1, 1000000000))
		local slId = "ColorSlider_" .. key
		local isIc = id == "IconColor" and iconStroke ~= nil
		local fr = settingTemplate:Clone()
		fr.Parent = settingsHolder
		fr.Visible = true
		fr.LayoutOrder = -2
		for _, d in ipairs(fr:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		local tL = fr:FindFirstChild("Title", true)
		local dL = fr:FindFirstChild("Desc", true)
		if tL then
			tL.Text = tt
		end
		if dL then
			dL.Text = dt
		end
		local ob = fr:FindFirstChild("Button", true)
		local ord = 0
		if ob then
			ord = ob.LayoutOrder
			ob:Destroy()
		end
		local pad = 14
		local vbW = 74
		local tgW = 20
		local slW = 190
		local sl = Instance.new("Frame")
		sl.Name = "ColorSlider"
		sl.BackgroundTransparency = 1
		sl.Size = UDim2.new(0, slW, 1, 0)
		sl.AnchorPoint = Vector2.new(1, 0.5)
		sl.LayoutOrder = ord
		sl.Parent = fr
		local vb = Instance.new("TextBox")
		vb.Name = "ColorValue"
		vb.Size = UDim2.new(0, vbW, 0, 18)
		vb.AnchorPoint = Vector2.new(1, 0.5)
		vb.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		vb.BorderSizePixel = 0
		vb.ClearTextOnFocus = false
		vb.TextXAlignment = Enum.TextXAlignment.Center
		vb.Font = Enum.Font.Gotham
		vb.TextSize = 12
		vb.TextColor3 = Color3.new(1, 1, 1)
		vb.Parent = fr
		local tg = Instance.new("TextButton")
		tg.Name = "Toggle"
		tg.Size = UDim2.new(0, tgW, 0, 18)
		tg.AnchorPoint = Vector2.new(1, 0.5)
		tg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		tg.BorderSizePixel = 0
		tg.Font = Enum.Font.GothamBold
		tg.TextSize = 11
		tg.TextColor3 = Color3.new(1, 1, 1)
		tg.Text = "C"
		tg.Parent = fr
		local tgc = Instance.new("UICorner")
		tgc.CornerRadius = UDim.new(0, 4)
		tgc.Parent = tg
		local function lay()
			local y = 0.5
			vb.Position = UDim2.new(1, -pad, y, 0)
			tg.Position = UDim2.new(1, -(pad + vbW + 8), y, 0)
			sl.Position = UDim2.new(1, -(pad + vbW + 8 + tgW + 8), y, 0)
		end
		lay();
		(fr:GetPropertyChangedSignal("AbsoluteSize")):Connect(lay)
		local function mkBar(nm, yy)
			local b = Instance.new("Frame")
			b.Name = nm
			b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			b.BorderSizePixel = 0
			b.AnchorPoint = Vector2.new(0.5, 0)
			b.Position = UDim2.new(0.5, 0, yy, 0)
			b.Size = UDim2.new(1, 0, 0, 5)
			b.Active = true
			b.Parent = sl
			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(0, 3)
			bc.Parent = b
			local k = Instance.new("Frame")
			k.Name = "Knob"
			k.Size = UDim2.new(0, 9, 0, 9)
			k.AnchorPoint = Vector2.new(0.5, 0.5)
			k.Position = UDim2.new(0, 0, 0.5, 0)
			k.BackgroundColor3 = Color3.new(1, 1, 1)
			k.BorderSizePixel = 0
			k.Parent = b
			local kc = Instance.new("UICorner")
			kc.CornerRadius = UDim.new(1, 0)
			kc.Parent = k
			return b, k
		end
		local bH, kH = mkBar("Hue", 0.2)
		local bS, kS = mkBar("Sat", 0.5)
		local bV, kV = mkBar("Val", 0.8)
		local gH = Instance.new("UIGradient")
		gH.Rotation = 0
		gH.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
		})
		gH.Parent = bH
		local gS = Instance.new("UIGradient")
		gS.Rotation = 0
		gS.Parent = bS
		local gV = Instance.new("UIGradient")
		gV.Rotation = 0
		gV.Parent = bV
		local defC = cVal.Value or Color3.new(1, 1, 1)
		local cOn = true
		local lastC = defC
		local sv = colorConfig[key]
		if type(sv) == "table" then
			if type(sv.customColor) == "table" and #sv.customColor == 3 then
				lastC = Color3.new(sv.customColor[1], sv.customColor[2], sv.customColor[3])
			end
			if sv.useCustom ~= nil then
				cOn = sv.useCustom and true or false
			end
		end
		local h, s, v = Color3.toHSV(lastC)
		local function boxC(c)
			vb.Text = string.format(
				"%d,%d,%d",
				math.floor(c.R * 255 + 0.5),
				math.floor(c.G * 255 + 0.5),
				math.floor(c.B * 255 + 0.5)
			)
		end
		local function save()
			if not (HS and type(writefile) == "function") then
				return
			end
			colorConfig[key] = {
				useCustom = cOn,
				customColor = { lastC.R, lastC.G, lastC.B },
			}
			local ok, enc = pcall(function()
				return __lt.cm("HttpService", "JSONEncode", colorConfig)
			end)
			if ok and enc then
				pcall(writefile, colorsPath, enc)
			end
		end
		local function updGrad()
			gS.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(h, 0, v)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, v)),
			})
			gV.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(h, s, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(h, s, 1)),
			})
		end
		local function setVis()
			kH.Position = UDim2.new(h, 0, 0.5, 0)
			kS.Position = UDim2.new(s, 0, 0.5, 0)
			kV.Position = UDim2.new(v, 0, 0.5, 0)
			updGrad()
			boxC(Color3.fromHSV(h, s, v))
		end
		local function applyC(col, st)
			if cVal then
				cVal.Value = col
			end
			if st then
				lastC = col
			end
			save()
		end
		local function setHSV(nh, ns, nv, st)
			h = math.clamp(nh, 0, 1)
			s = math.clamp(ns, 0, 1)
			v = math.clamp(nv, 0, 1)
			setVis()
			applyC(Color3.fromHSV(h, s, v), st)
		end
		local function syncFromC(col)
			h, s, v = Color3.toHSV(col)
			setVis()
		end
		if cOn then
			if isIc then
				iconColorUseCustom = true
			end
			syncFromC(lastC)
			applyC(lastC, false)
			tg.Text = "C"
		else
			if isIc then
				iconColorUseCustom = false
				if iconStroke then
					pcall(function()
						iconStroke.Color = iconBaseColor or iconStroke.Color
					end)
				end
			end
			syncFromC(defC)
			applyC(defC, false)
			tg.Text = "D"
		end
		local drag = nil
		local function relX(bar, inp)
			local w = bar.AbsoluteSize.X
			if w <= 1 then
				return nil
			end
			local x = (inp.Position.X - bar.AbsolutePosition.X) / w
			if x ~= x then
				x = 0
			end
			return math.clamp(x, 0, 1)
		end
		local function useDrag(inp)
			if not drag then
				return
			end
			local a = relX(drag, inp)
			if not a then
				return
			end
			cOn = true
			tg.Text = "C"
			if isIc then
				iconColorUseCustom = true
			end
			if drag == bH then
				setHSV(a, s, v, true)
			elseif drag == bS then
				setHSV(h, a, v, true)
			elseif drag == bV then
				setHSV(h, s, a, true)
			end
		end
		local function beg(bar, inp)
			if
				inp.UserInputType ~= Enum.UserInputType.MouseButton1
				and inp.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end
			drag = bar
			useDrag(inp)
		end
		bH.InputBegan:Connect(function(i)
			beg(bH, i)
		end)
		bS.InputBegan:Connect(function(i)
			beg(bS, i)
		end)
		bV.InputBegan:Connect(function(i)
			beg(bV, i)
		end)
		NAlib.disconnect(slId)
		NAlib.connect(
			slId,
			UIS.InputChanged:Connect(function(i)
				if not drag then
					return
				end
				if
					i.UserInputType == Enum.UserInputType.MouseMovement
					or i.UserInputType == Enum.UserInputType.Touch
				then
					useDrag(i)
				end
			end)
		)
		NAlib.connect(
			slId,
			UIS.InputEnded:Connect(function(i)
				if
					i.UserInputType == Enum.UserInputType.MouseButton1
					or i.UserInputType == Enum.UserInputType.Touch
				then
					drag = nil
				end
			end)
		)
		fr.Destroying:Connect(function()
			NAlib.disconnect(slId)
		end)
		vb.FocusLost:Connect(function()
			local txt = vb.Text or ""
			local r, g, b = txt:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
			r, g, b = tonumber(r), tonumber(g), tonumber(b)
			if r and g and b then
				local col =
					Color3.new(math.clamp(r, 0, 255) / 255, math.clamp(g, 0, 255) / 255, math.clamp(b, 0, 255) / 255)
				cOn = true
				tg.Text = "C"
				if isIc then
					iconColorUseCustom = true
				end
				syncFromC(col)
				applyC(col, true)
			else
				boxC(cVal.Value)
			end
		end)
		tg.MouseButton1Click:Connect(function()
			if cOn then
				cOn = false
				tg.Text = "D"
				if isIc then
					iconColorUseCustom = false
					if iconStroke then
						pcall(function()
							iconStroke.Color = iconBaseColor or iconStroke.Color
						end)
					end
				end
				syncFromC(defC)
				applyC(defC, false)
			else
				cOn = true
				tg.Text = "C"
				if isIc then
					iconColorUseCustom = true
				end
				syncFromC(lastC or defC)
				applyC(lastC or defC, true)
			end
			save()
		end)
	end
	local function makeSizeSlider(id, titleText, descText, numValue, minV, maxV)
		if not (settingsHolder and settingTemplate and numValue) then
			return
		end
		local key = id or titleText or "Size_" .. tostring(math.random(1, 1000000000))
		local slId = "SizeSlider_" .. key
		minV = minV or 0.5
		maxV = maxV or 5
		local fr = settingTemplate:Clone()
		fr.Parent = settingsHolder
		fr.Visible = true
		fr.LayoutOrder = -2
		local tl = fr:FindFirstChild("Title", true)
		local dl = fr:FindFirstChild("Desc", true)
		if tl then
			tl.Text = titleText
		end
		if dl then
			dl.Text = descText
		end
		local ob = fr:FindFirstChild("Button", true)
		if ob then
			ob:Destroy()
		end
		local dock = mkDock(fr)
		local vb = mkBox(dock)
		local sl, bar, fill, kb = mkSl(dock, 150)
		local sv = settingsConfig[key]
		if type(sv) == "table" and type(sv.value) == "number" then
			numValue.Value = math.clamp(sv.value, minV, maxV)
		end
		local function save(v)
			if not (HS and type(writefile) == "function") then
				return
			end
			settingsConfig[key] = { value = v }
			local ok, enc = pcall(function()
				return __lt.cm("HttpService", "JSONEncode", settingsConfig)
			end)
			if ok and enc then
				pcall(writefile, settingsPath, enc)
			end
		end
		local function setVis(v)
			v = math.clamp(v, minV, maxV)
			local a = (v - minV) / (maxV - minV)
			fill.Size = UDim2.new(a, 0, 1, 0)
			kb.Position = UDim2.new(a, 0, 0.5, 0)
			vb.Text = string.format("%.2f", v)
		end
		local function apply(v)
			v = math.clamp(v, minV, maxV)
			numValue.Value = v
			setVis(v)
			save(v)
		end
		setVis(numValue.Value)
		local drag = false
		local function fromIn(input)
			local rel = 0
			pcall(function()
				rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
			end)
			rel = math.clamp(rel, 0, 1)
			apply(minV + (maxV - minV) * rel)
		end
		bar.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				drag = true
				fromIn(input)
			end
		end)
		NAlib.disconnect(slId)
		NAlib.connect(
			slId,
			UIS.InputChanged:Connect(function(input)
				if not drag then
					return
				end
				if
					input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
				then
					fromIn(input)
				end
			end)
		)
		NAlib.connect(
			slId,
			UIS.InputEnded:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					drag = false
				end
			end)
		)
		fr.Destroying:Connect(function()
			NAlib.disconnect(slId)
		end)
		vb.FocusLost:Connect(function()
			local v = tonumber(vb.Text or "")
			if v then
				apply(v)
			else
				setVis(numValue.Value)
			end
		end)
		local function updDock()
			local w = math.clamp(math.floor(fr.AbsoluteSize.X * 0.46), 240, 380)
			dock.Size = UDim2.new(0, w, 0, 18)
			local sw = math.clamp(w - 78, 140, 280)
			sl.Size = UDim2.new(0, sw, 0, 18)
		end
		updDock();
		(fr:GetPropertyChangedSignal("AbsoluteSize")):Connect(function()
			task.defer(updDock)
		end)
	end
	local function makeIconRgbToggle()
		if not (settingsHolder and settingTemplate and iconBtn and iconStroke) then
			return
		end
		local key = "IconRGB"
		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "RGB icon"
		end
		if dLabel then
			dLabel.Text = "Rainbow outline on the Delta icon."
		end
		local btnFrame = frame:FindFirstChild("Button", true)
		if not btnFrame then
			return
		end
		local btnLabel = btnFrame:FindFirstChildWhichIsA("TextLabel")
		if btnLabel then
			btnLabel.Text = "Toggle"
		end
		local clickable = btnFrame:FindFirstChildWhichIsA("GuiButton") or btnFrame
		local saved = settingsConfig[key]
		local enabled = false
		if type(saved) == "table" and saved.enabled ~= nil then
			enabled = saved.enabled and true or false
		end
		local hue = 0
		local function saveState()
			if not (HS and type(writefile) == "function") then
				return
			end
			settingsConfig[key] = { enabled = enabled }
			local ok, encoded = pcall(function()
				return __lt.cm("HttpService", "JSONEncode", settingsConfig)
			end)
			if ok and encoded then
				pcall(writefile, settingsPath, encoded)
			end
		end
		local function setVisualToggle()
			btnFrame.BackgroundColor3 = enabled and Color3.fromRGB(79, 164, 242) or Color3.fromRGB(30, 30, 30)
		end
		local function startLoop()
			NAlib.disconnect("IconRGB_Loop")
			NAlib.connect(
				"IconRGB_Loop",
				RS.Heartbeat:Connect(function(dt)
					local spd = iconRgbSpeedValue and math.clamp(iconRgbSpeedValue.Value, 0.05, 2) or 0.2
					hue = (hue + dt * spd) % 1
					pcall(function()
						iconStroke.Color = Color3.fromHSV(hue, 1, 1)
					end)
				end)
			)
		end
		local function stopLoop()
			NAlib.disconnect("IconRGB_Loop")
			pcall(function()
				if iconColorUseCustom and iconColorValue then
					iconStroke.Color = iconColorValue.Value
				else
					iconStroke.Color = iconBaseColor or iconStroke.Color
				end
			end)
		end
		local function applyState()
			setVisualToggle()
			if enabled then
				startLoop()
			else
				stopLoop()
			end
			saveState()
		end
		applyState()
		local function toggleClick()
			enabled = not enabled
			applyState()
		end
		if clickable:IsA("GuiButton") then
			clickable.MouseButton1Click:Connect(toggleClick)
		else
			clickable.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					toggleClick()
				end
			end)
		end
	end
	local function makeIconVisibilityToggle()
		if not (settingsHolder and settingTemplate and iconBtn) then
			return
		end
		local key = "IconVisible"
		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "Icon visibility"
		end
		if dLabel then
			dLabel.Text = "Makes the Delta icon invisible"
		end
		local btnFrame = frame:FindFirstChild("Button", true)
		if not btnFrame then
			return
		end
		local btnLabel = btnFrame:FindFirstChildWhichIsA("TextLabel")
		if btnLabel then
			btnLabel.Text = "Toggle"
		end
		local clickable = btnFrame:FindFirstChildWhichIsA("GuiButton") or btnFrame
		local function saveState()
			if not (HS and type(writefile) == "function") then
				return
			end
			settingsConfig[key] = { enabled = iconVisible }
			local ok, encoded = pcall(function()
				return __lt.cm("HttpService", "JSONEncode", settingsConfig)
			end)
			if ok and encoded then
				pcall(writefile, settingsPath, encoded)
			end
		end
		local function setVisual()
			btnFrame.BackgroundColor3 = iconVisible and Color3.fromRGB(79, 164, 242) or Color3.fromRGB(30, 30, 30)
		end
		setVisual()
		local function toggleClick()
			iconVisible = not iconVisible
			applyIconUserVisibility(false)
			setVisual()
			saveState()
		end
		if clickable:IsA("GuiButton") then
			clickable.MouseButton1Click:Connect(toggleClick)
		else
			clickable.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					toggleClick()
				end
			end)
		end
	end
	local function makeTabNotifToggle()
		if not (settingsHolder and settingTemplate) then
			return
		end
		local key = "TabNotifications"
		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "Tab notifications"
		end
		if dLabel then
			dLabel.Text = "Show info popups about saved tabs"
		end
		local btnFrame = frame:FindFirstChild("Button", true)
		if not btnFrame then
			return
		end
		local btnLabel = btnFrame:FindFirstChildWhichIsA("TextLabel")
		if btnLabel then
			btnLabel.Text = "Toggle"
		end
		local clickable = btnFrame:FindFirstChildWhichIsA("GuiButton") or btnFrame
		local function saveState()
			if not (HS and type(writefile) == "function") then
				return
			end
			settingsConfig[key] = { enabled = tabNotifEnabled }
			local ok, encoded = pcall(function()
				return __lt.cm("HttpService", "JSONEncode", settingsConfig)
			end)
			if ok and encoded then
				pcall(writefile, settingsPath, encoded)
			end
		end
		local function setVisual()
			btnFrame.BackgroundColor3 = tabNotifEnabled and Color3.fromRGB(79, 164, 242) or Color3.fromRGB(30, 30, 30)
		end
		setVisual()
		local function toggleClick()
			tabNotifEnabled = not tabNotifEnabled
			setVisual()
			saveState()
		end
		if clickable:IsA("GuiButton") then
			clickable.MouseButton1Click:Connect(toggleClick)
		else
			clickable.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					toggleClick()
				end
			end)
		end
	end
	local function makeDestroyUIButton()
		if not (settingsHolder and settingTemplate) then
			return
		end
		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "Destroy Delta UI"
			tLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		end
		if dLabel then
			dLabel.Text = "Deletes Delta's UI and icon until you rejoin."
			dLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
		end
		local btnFrame = frame:FindFirstChild("Button", true)
		if not btnFrame then
			return
		end
		local btnLabel = btnFrame:FindFirstChildWhichIsA("TextLabel")
		if btnLabel then
			btnLabel.Text = "KILL"
		end
		btnFrame.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
		local clickable = btnFrame:FindFirstChildWhichIsA("GuiButton") or btnFrame
		local function click()
			if iconGui then
				pcall(function()
					iconGui:Destroy()
				end)
				iconGui = nil
			end
			if mainGui then
				pcall(function()
					mainGui:Destroy()
				end)
				mainGui = nil
			end
		end
		if clickable:IsA("GuiButton") then
			clickable.MouseButton1Click:Connect(click)
		else
			clickable.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					click()
				end
			end)
		end
	end
	local function makeIconEnableToggle()
		if not (settingsHolder and settingTemplate and iconBtn) then
			return
		end
		local key = "IconEnabled"
		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "Use custom icon"
		end
		if dLabel then
			dLabel.Text = iconFsOk() and "Toggle between default and custom Delta icon"
				or "Requires file system + getcustomasset support"
		end
		local btnFrame = frame:FindFirstChild("Button", true)
		if not btnFrame then
			return
		end
		local btnLabel = btnFrame:FindFirstChildWhichIsA("TextLabel")
		if btnLabel then
			btnLabel.Text = "Toggle"
		end
		local clickable = btnFrame:FindFirstChildWhichIsA("GuiButton") or btnFrame
		local enabled = dIcons.enabled and true or false
		local function setVisual()
			btnFrame.BackgroundColor3 = enabled and Color3.fromRGB(79, 164, 242) or Color3.fromRGB(30, 30, 30)
		end
		setVisual()
		local function toggleClick()
			local target = not enabled
			local ok, err = setIconEnabled(target)
			if not ok then
				notify({
					Title = "Delta Icon",
					Description = err or "Failed to toggle custom icon.",
					Duration = 5,
				})
				return
			end
			enabled = target
			setVisual()
		end
		if clickable:IsA("GuiButton") then
			clickable.MouseButton1Click:Connect(toggleClick)
		else
			clickable.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					toggleClick()
				end
			end)
		end
	end
	local function makeIconInputRow()
		if not (settingsHolder and settingTemplate and iconBtn) then
			return
		end
		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "Icon source"
		end
		if dLabel then
			dLabel.Text = "Asset id or image URL (GitHub/External supported)"
		end
		local oldBtn = frame:FindFirstChild("Button", true)
		local pos
		if oldBtn then
			pos = oldBtn.Position
			oldBtn:Destroy()
		end
		local basePos = pos or UDim2.new(1, -160, 0.5, 0)
		local bx, bo = basePos.X.Scale, basePos.X.Offset
		local by, byo = basePos.Y.Scale, basePos.Y.Offset
		local box = Instance.new("TextBox")
		box.Name = "IconInput"
		box.Size = UDim2.new(0, 160, 0, 18)
		box.AnchorPoint = Vector2.new(1, 0.5)
		box.Position = UDim2.new(bx, bo, by, byo)
		box.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		box.BorderSizePixel = 0
		box.ClearTextOnFocus = true
		box.TextXAlignment = Enum.TextXAlignment.Center
		box.Font = Enum.Font.Gotham
		box.TextSize = 12
		box.TextColor3 = Color3.new(1, 1, 1)
		box.Text = ""
		box.PlaceholderText = "ID or image URL"
		box.Parent = frame
		local setBtn = Instance.new("TextButton")
		setBtn.Name = "Apply"
		setBtn.Size = UDim2.new(0, 50, 0, 18)
		setBtn.AnchorPoint = Vector2.new(1, 0.5)
		setBtn.Position = UDim2.new(bx, bo - 170, by, byo)
		setBtn.BackgroundColor3 = Color3.fromRGB(79, 164, 242)
		setBtn.BorderSizePixel = 0
		setBtn.Font = Enum.Font.GothamBold
		setBtn.TextSize = 11
		setBtn.TextColor3 = Color3.new(1, 1, 1)
		setBtn.Text = "SET"
		setBtn.Parent = frame
		local setCorner = Instance.new("UICorner")
		setCorner.CornerRadius = UDim.new(0, 4)
		setCorner.Parent = setBtn
		local defBtn = Instance.new("TextButton")
		defBtn.Name = "Default"
		defBtn.Size = UDim2.new(0, 50, 0, 18)
		defBtn.AnchorPoint = Vector2.new(1, 0.5)
		defBtn.Position = UDim2.new(bx, bo - 230, by, byo)
		defBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		defBtn.BorderSizePixel = 0
		defBtn.Font = Enum.Font.GothamBold
		defBtn.TextSize = 11
		defBtn.TextColor3 = Color3.new(1, 1, 1)
		defBtn.Text = "DEF"
		defBtn.Parent = frame
		local defCorner = Instance.new("UICorner")
		defCorner.CornerRadius = UDim.new(0, 4)
		defCorner.Parent = defBtn
		local function applyInput()
			if not iconFsOk() then
				notify({
					Title = "Delta Icon",
					Description = "Custom icons require file system + getcustomasset.",
					Duration = 5,
				})
				return
			end
			local txt = trim(box.Text or "")
			if txt == "" then
				notify({
					Title = "Delta Icon",
					Description = "Enter an asset id or image URL.",
					Duration = 4,
				})
				return
			end
			local ok, msg = setIconAsset(txt, { autoEnable = true })
			if not ok then
				notify({
					Title = "Delta Icon",
					Description = msg or "Failed to set custom icon.",
					Duration = 5,
				})
				return
			end
			if updateIconStatusUI then
				updateIconStatusUI()
			end
			box.Text = ""
			notify({
				Title = "Delta Icon",
				Description = "Custom icon updated.",
				Duration = 4,
			})
		end
		local function resetDefault()
			dIcons.enabled = false
			dIcons.assetId = ""
			dIcons.localPath = ""
			applyIcon()
			saveIconCfg()
			if updateIconStatusUI then
				updateIconStatusUI()
			end
			notify({
				Title = "Delta Icon",
				Description = "Reverted to default icon.",
				Duration = 4,
			})
		end
		setBtn.MouseButton1Click:Connect(applyInput)
		defBtn.MouseButton1Click:Connect(resetDefault)
		box.FocusLost:Connect(function(enter)
			if enter then
				applyInput()
			end
		end)
	end
	local function makeIconManagerRow()
		if not (settingsHolder and settingTemplate) then
			return
		end
		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "Icon manager"
		end
		if dLabel then
			dLabel.Text = iconFsOk() and formatIconStatus() or "File system/getcustomasset not supported."
		end
		local oldBtn = frame:FindFirstChild("Button", true)
		local pos
		if oldBtn then
			pos = oldBtn.Position
			oldBtn:Destroy()
		end
		local basePos = pos or UDim2.new(1, -160, 0.5, 0)
		local bx, bo = basePos.X.Scale, basePos.X.Offset
		local by, byo = basePos.Y.Scale, basePos.Y.Offset
		local function mkMgrBtn(nm, w, xOff, bgColor, txt)
			local b = Instance.new("TextButton")
			b.Name = nm
			b.Size = UDim2.new(0, w, 0, 18)
			b.AnchorPoint = Vector2.new(1, 0.5)
			b.Position = UDim2.new(bx, bo + xOff, by, byo)
			b.BackgroundColor3 = bgColor
			b.BorderSizePixel = 0
			b.Font = Enum.Font.GothamBold
			b.TextSize = 11
			b.TextColor3 = Color3.new(1, 1, 1)
			b.Text = txt
			b.Parent = frame
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 4)
			c.Parent = b
			return b
		end
		local gray = Color3.fromRGB(30, 30, 30)
		local prevBtn = mkMgrBtn("Prev", 24, -210, gray, "<")
		local nextBtn = mkMgrBtn("Next", 24, -180, gray, ">")
		local delBtn = mkMgrBtn("Del", 32, -140, Color3.fromRGB(80, 40, 40), "DEL")
		local clrBtn = mkMgrBtn("Clr", 36, -95, Color3.fromRGB(60, 30, 30), "CLR")
		local statusLabel = Instance.new("TextLabel")
		statusLabel.Name = "Status"
		statusLabel.Size = UDim2.new(0, 60, 0, 18)
		statusLabel.AnchorPoint = Vector2.new(1, 0.5)
		statusLabel.Position = UDim2.new(bx, bo, by, byo)
		statusLabel.BackgroundTransparency = 1
		statusLabel.Font = Enum.Font.Gotham
		statusLabel.TextSize = 11
		statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		statusLabel.TextXAlignment = Enum.TextXAlignment.Right
		statusLabel.Text = "-/-"
		statusLabel.Parent = frame
		function updateIconStatusUI()
			if not statusLabel then
				return
			end
			local n = #dIcons.entries
			local idx = dIcons.index
			if dLabel then
				dLabel.Text = iconFsOk() and formatIconStatus() or "File system/getcustomasset not supported."
			end
			if n <= 0 then
				statusLabel.Text = "-/-"
			else
				if idx < 1 or idx > n then
					idx = 1
				end
				statusLabel.Text = tostring(idx) .. "/" .. tostring(n)
			end
		end
		updateIconStatusUI()
		local function chkFs()
			if iconFsOk() then
				return true
			end
			notify({
				Title = "Delta Icon",
				Description = "Custom icon manager requires file system + getcustomasset.",
				Duration = 5,
			})
			return false
		end
		prevBtn.MouseButton1Click:Connect(function()
			if not chkFs() then
				return
			end
			if #dIcons.entries == 0 then
				notify({ Title = "Delta Icon", Description = "No custom icons to cycle.", Duration = 4 })
				return
			end
			cycleIcon(-1)
		end)
		nextBtn.MouseButton1Click:Connect(function()
			if not chkFs() then
				return
			end
			if #dIcons.entries == 0 then
				notify({ Title = "Delta Icon", Description = "No custom icons to cycle.", Duration = 4 })
				return
			end
			cycleIcon(1)
		end)
		delBtn.MouseButton1Click:Connect(function()
			if not chkFs() then
				return
			end
			local list = dIcons.entries
			local idx = dIcons.index
			if #list == 0 or idx < 1 or idx > #list then
				notify({ Title = "Delta Icon", Description = "No icon selected to delete.", Duration = 4 })
				return
			end
			local e = list[idx]
			if not e or not e.file then
				return
			end
			removeIconEntry(e)
			if updateIconStatusUI then
				updateIconStatusUI()
			end
		end)
		clrBtn.MouseButton1Click:Connect(function()
			if not chkFs() then
				return
			end
			if #dIcons.entries == 0 then
				notify({ Title = "Delta Icon", Description = "No custom icons to clear.", Duration = 4 })
				return
			end
			removeAllIcons()
			if updateIconStatusUI then
				updateIconStatusUI()
			end
			notify({ Title = "Delta Icon", Description = "Cleared all custom icons.", Duration = 4 })
		end)
	end
	local sidebarGestureEnabled = false
	local sidebarGestureVisible = true
	local sidebarGestureWidth = 18
	local sidebarGestureHeight = 120
	local sidebarGestureFrame
	local sidebarDragActive = false
	local sidebarDragStartX = 0
	local sidebarDragStartAlpha = 0
	local sidebarDragAlpha = 0
	local sidebarCurrentSection = nil
	local autoCloseOnLoad = true
	local sectionsList = { "Executor", "Home", "Scripthub", "Settings", "Console" }
	local gestureWidthValue = Instance.new("NumberValue")
	gestureWidthValue.Name = "GestureWidthValue"
	gestureWidthValue.Value = sidebarGestureWidth
	local gestureHeightValue = Instance.new("NumberValue")
	gestureHeightValue.Name = "GestureHeightValue"
	gestureHeightValue.Value = sidebarGestureHeight
	do
		local cfg = settingsConfig.GestureWidth
		if type(cfg) == "table" and type(cfg.value) == "number" then
			gestureWidthValue.Value = math.clamp(cfg.value, 6, 80)
		end
	end
	do
		local cfg = settingsConfig.GestureHeight
		if type(cfg) == "table" and type(cfg.value) == "number" then
			gestureHeightValue.Value = math.clamp(cfg.value, 60, 400)
		end
	end
	do
		local cfg = settingsConfig.SidebarGesture
		if type(cfg) == "table" and cfg.enabled ~= nil then
			sidebarGestureEnabled = cfg.enabled and true or false
		end
	end
	do
		local cfg = settingsConfig.SidebarGestureVisible
		if type(cfg) == "table" and cfg.enabled ~= nil then
			sidebarGestureVisible = cfg.enabled and true or false
		end
	end
	do
		local cfg = settingsConfig.AutoCloseOnLoad
		if type(cfg) == "table" and cfg.enabled ~= nil then
			autoCloseOnLoad = cfg.enabled and true or false
		end
	end
	local gestCol = Instance.new("Color3Value")
	gestCol.Name = "GestureColorValue"
	gestCol.Value = Color3.fromRGB(255, 255, 255)
	gestCol.Changed:Connect(function()
		if sidebarGestureFrame then
			sidebarGestureFrame.BackgroundColor3 = gestCol.Value
		end
	end)
	local function closeDeltaSidebar()
		if sidebar then
			setSidebarPosition(sidebarClosedPos)
			normalizeSidebarGeometry()
		end
		if mainGui then
			for _, n in ipairs(sectionsList) do
				local fr = mainGui:FindFirstChild(n)
				if fr and fr:IsA("GuiObject") then
					fr.Visible = false
				end
			end
		end
		if iconGui then
			iconGui.Enabled = true
		end
		setIconForcedHidden(false)
	end
	local function saveSidebarGesture()
		if not (HS and type(writefile) == "function") then
			return
		end
		settingsConfig.SidebarGesture = { enabled = sidebarGestureEnabled }
		local ok, encoded = pcall(function()
			return __lt.cm("HttpService", "JSONEncode", settingsConfig)
		end)
		if ok and encoded then
			pcall(writefile, settingsPath, encoded)
		end
	end
	local function saveSidebarGestureVisible()
		if not (HS and type(writefile) == "function") then
			return
		end
		settingsConfig.SidebarGestureVisible = { enabled = sidebarGestureVisible }
		local ok, encoded = pcall(function()
			return __lt.cm("HttpService", "JSONEncode", settingsConfig)
		end)
		if ok and encoded then
			pcall(writefile, settingsPath, encoded)
		end
	end
	local function applyGestureVisual()
		if sidebarGestureFrame then
			sidebarGestureFrame.BackgroundTransparency = sidebarGestureVisible and 0.4 or 1
		end
	end
	local function applyGestureSize()
		if not sidebarGestureFrame then
			return
		end
		local h = math.clamp(gestureHeightValue and gestureHeightValue.Value or sidebarGestureHeight, 60, 400)
		local w = math.clamp(gestureWidthValue and gestureWidthValue.Value or sidebarGestureWidth, 6, 80)
		if UIS and UIS.TouchEnabled then
			w = math.floor(w * 1.6)
		end
		sidebarGestureFrame.Size = UDim2.new(0, w, 0, h)
	end
	gestureWidthValue.Changed:Connect(function()
		if sidebarGestureFrame then
			applyGestureSize()
		end
	end)
	gestureHeightValue.Changed:Connect(function()
		if sidebarGestureFrame then
			applyGestureSize()
		end
	end)
	local function ensureSidebarGestureFrame()
		if sidebarGestureFrame or not (sidebar and mainGui) then
			return
		end
		local f = Instance.new("Frame")
		sidebarGestureFrame = f
		f.Name = "SidebarGestureZone"
		f.BackgroundColor3 = gestCol.Value
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(1, 0.5)
		f.Position = UDim2.new(1, 0, 0.5, 0)
		f.Size = UDim2.new(0, sidebarGestureWidth, 0, sidebarGestureHeight)
		f.Active = false
		f.Visible = false
		f.Parent = mainGui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = f
		applyGestureSize()
		applyGestureVisual()
	end
	local function makeSidebarGestureToggle()
		if not (settingsHolder and settingTemplate and sidebar) then
			return
		end
		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "Sidebar gesture"
		end
		if dLabel then
			dLabel.Text = "Drag from the right edge to open/close the sidebar"
		end
		local btnFrame = frame:FindFirstChild("Button", true)
		if not btnFrame then
			return
		end
		local btnLabel = btnFrame:FindFirstChildWhichIsA("TextLabel")
		if btnLabel then
			btnLabel.Text = "Toggle"
		end
		local clickable = btnFrame:FindFirstChildWhichIsA("GuiButton") or btnFrame
		local function setVisual()
			btnFrame.BackgroundColor3 = sidebarGestureEnabled and Color3.fromRGB(79, 164, 242)
				or Color3.fromRGB(30, 30, 30)
		end
		setVisual()
		local function toggleClick()
			sidebarGestureEnabled = not sidebarGestureEnabled
			setVisual()
			saveSidebarGesture()
			if not sidebarGestureEnabled then
				if iconGui then
					iconGui.Enabled = true
				end
				setIconForcedHidden(false)
			end
			task.defer(function()
				if applySidebarGestureState then
					applySidebarGestureState()
				end
			end)
		end
		if clickable:IsA("GuiButton") then
			clickable.MouseButton1Click:Connect(toggleClick)
		else
			clickable.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					toggleClick()
				end
			end)
		end
	end
	local function makeSidebarGestureBarVisibilityToggle()
		if not (settingsHolder and settingTemplate) then
			return
		end
		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "Gesture bar visible"
		end
		if dLabel then
			dLabel.Text = "Hide the sidebar gesture bar but keep it usable"
		end
		local btnFrame = frame:FindFirstChild("Button", true)
		if not btnFrame then
			return
		end
		local btnLabel = btnFrame:FindFirstChildWhichIsA("TextLabel")
		if btnLabel then
			btnLabel.Text = "Toggle"
		end
		local clickable = btnFrame:FindFirstChildWhichIsA("GuiButton") or btnFrame
		local function setVisual()
			btnFrame.BackgroundColor3 = sidebarGestureVisible and Color3.fromRGB(79, 164, 242)
				or Color3.fromRGB(30, 30, 30)
		end
		setVisual()
		applyGestureVisual()
		local function toggleClick()
			sidebarGestureVisible = not sidebarGestureVisible
			setVisual()
			applyGestureVisual()
			saveSidebarGestureVisible()
		end
		if clickable:IsA("GuiButton") then
			clickable.MouseButton1Click:Connect(toggleClick)
		else
			clickable.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					toggleClick()
				end
			end)
		end
	end
	local function makeAutoCloseToggle()
		if not (settingsHolder and settingTemplate and sidebar) then
			return
		end
		local key = "AutoCloseOnLoad"
		local frame = settingTemplate:Clone()
		frame.Parent = settingsHolder
		frame.Visible = true
		frame.LayoutOrder = -2
		for _, d in ipairs(frame:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			end
		end
		local tLabel = frame:FindFirstChild("Title", true)
		local dLabel = frame:FindFirstChild("Desc", true)
		if tLabel then
			tLabel.Text = "Auto-close on load"
		end
		if dLabel then
			dLabel.Text = "Close the Delta sidebar right after it loads"
		end
		local btnFrame = frame:FindFirstChild("Button", true)
		if not btnFrame then
			return
		end
		local btnLabel = btnFrame:FindFirstChildWhichIsA("TextLabel")
		if btnLabel then
			btnLabel.Text = "Toggle"
		end
		local clickable = btnFrame:FindFirstChildWhichIsA("GuiButton") or btnFrame
		local function saveState()
			if not (HS and type(writefile) == "function") then
				return
			end
			settingsConfig[key] = { enabled = autoCloseOnLoad }
			local ok, encoded = pcall(function()
				return __lt.cm("HttpService", "JSONEncode", settingsConfig)
			end)
			if ok and encoded then
				pcall(writefile, settingsPath, encoded)
			end
		end
		local function setVisual()
			btnFrame.BackgroundColor3 = autoCloseOnLoad and Color3.fromRGB(79, 164, 242) or Color3.fromRGB(30, 30, 30)
		end
		setVisual()
		local function toggleClick()
			autoCloseOnLoad = not autoCloseOnLoad
			setVisual()
			saveState()
		end
		if clickable:IsA("GuiButton") then
			clickable.MouseButton1Click:Connect(toggleClick)
		else
			clickable.InputBegan:Connect(function(input)
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				then
					toggleClick()
				end
			end)
		end
	end
	local function getCurrentSectionName()
		if not mainGui then
			return nil
		end
		local cur
		for _, name in ipairs(sectionsList) do
			local fr = mainGui:FindFirstChild(name)
			if fr and fr:IsA("GuiObject") and fr.Visible then
				cur = name
			end
		end
		return cur
	end
	function applySidebarGestureState()
		if not sidebar then
			sidebarGestureEnabled = false
			saveSidebarGesture()
			return
		end
		ensureSidebarGestureFrame()
		if not sidebarGestureFrame then
			sidebarGestureEnabled = false
			saveSidebarGesture()
			return
		end
		if toggleUIBtn and toggleUIBtn:IsA("ImageButton") then
			pcall(function()
				toggleUIBtn.Visible = not sidebarGestureEnabled
			end)
		end
		NAlib.disconnect("SidebarGesture")
		sidebarGestureFrame.Active = false
		sidebarGestureFrame.Visible = false
		if not sidebarGestureEnabled then
			saveSidebarGesture()
			return
		end
		sidebarGestureFrame.Active = true
		sidebarGestureFrame.Visible = true
		applyGestureVisual()
		applyGestureSize()
		local id = "SidebarGesture"
		local function recalcGesturePosition()
			if not (mainGui and sidebar and sidebarGestureFrame) then
				return
			end
			local sgSize = mainGui.AbsoluteSize
			if sgSize.X <= 0 or sgSize.Y <= 0 then
				return
			end
			local sbPos = sidebar.AbsolutePosition
			local sbSize = sidebar.AbsoluteSize
			local px = sbPos.X - 8
			sidebarGestureFrame.Position = UDim2.new(px / sgSize.X, 0, 0.5, 0)
		end
		local function getSidebarAlpha()
			if not sidebar then
				return 0
			end
			local sx = sidebar.Position.X.Scale
			local denom = sidebarClosedPos.X.Scale - sidebarOpenPos.X.Scale
			if denom == 0 then
				return 0
			end
			return math.clamp((sidebarClosedPos.X.Scale - sx) / denom, 0, 1)
		end
		recalcGesturePosition()
		NAlib.connect(id, (sidebar:GetPropertyChangedSignal("Position")):Connect(recalcGesturePosition))
		if sidebar.GetPropertyChangedSignal then
			NAlib.connect(id, (sidebar:GetPropertyChangedSignal("Size")):Connect(recalcGesturePosition))
		end
		if mainGui and mainGui.GetPropertyChangedSignal then
			NAlib.connect(id, (mainGui:GetPropertyChangedSignal("AbsoluteSize")):Connect(recalcGesturePosition))
		end
		local function updateSidebarFromInput(input)
			if not sidebar or not mainGui then
				return
			end
			local dx = input.Position.X - sidebarDragStartX
			local guiSize = mainGui.AbsoluteSize
			local dist = guiSize.X * math.abs(sidebarClosedPos.X.Scale - sidebarOpenPos.X.Scale)
			if dist <= 0 then
				dist = 100
			end
			local alpha = math.clamp(sidebarDragStartAlpha - dx / dist, 0, 1)
			sidebarDragAlpha = alpha
			setSidebarPosition(
				UDim2.new(
					sidebarClosedPos.X.Scale + (sidebarOpenPos.X.Scale - sidebarClosedPos.X.Scale) * alpha,
					0,
					0.5,
					0
				)
			)
		end
		NAlib.connect(
			id,
			sidebarGestureFrame.InputBegan:Connect(function(input)
				if not sidebarGestureEnabled then
					return
				end
				if
					input.UserInputType ~= Enum.UserInputType.MouseButton1
					and input.UserInputType ~= Enum.UserInputType.Touch
				then
					return
				end
				sidebarDragAlpha = getSidebarAlpha()
				sidebarDragStartAlpha = sidebarDragAlpha
				sidebarDragStartX = input.Position.X
				sidebarDragActive = true
			end)
		)
		NAlib.connect(
			id,
			UIS.InputChanged:Connect(function(input)
				if not sidebarDragActive or not sidebarGestureEnabled then
					return
				end
				if
					input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch
				then
					updateSidebarFromInput(input)
				end
			end)
		)
		NAlib.connect(
			id,
			UIS.InputEnded:Connect(function(input)
				if not sidebarDragActive or not sidebarGestureEnabled then
					return
				end
				if
					input.UserInputType ~= Enum.UserInputType.MouseButton1
					and input.UserInputType ~= Enum.UserInputType.Touch
				then
					return
				end
				sidebarDragActive = false
				local curSec = getCurrentSectionName()
				if curSec then
					sidebarCurrentSection = curSec
				end
				local targetPos = sidebarDragAlpha > 0.5 and sidebarOpenPos or sidebarClosedPos
				if TS and sidebar then
					local tw = __lt.cm(
						"TweenService",
						"Create",
						sidebar,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{
							Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, 0.5, 0),
						}
					)
					tw:Play()
				elseif sidebar then
					setSidebarPosition(targetPos)
				end
				if targetPos == sidebarOpenPos then
					if not sidebarCurrentSection then
						sidebarCurrentSection = getCurrentSectionName()
					end
					if iconGui then
						iconGui.Enabled = false
					end
					setIconForcedHidden(true)
					if mainGui and sidebarCurrentSection then
						for _, n in ipairs(sectionsList) do
							local fr = mainGui:FindFirstChild(n)
							if fr and fr:IsA("GuiObject") then
								fr.Visible = n == sidebarCurrentSection
							end
						end
					end
				else
					if mainGui then
						if curSec then
							sidebarCurrentSection = curSec
						end
						for _, n in ipairs(sectionsList) do
							local fr = mainGui:FindFirstChild(n)
							if fr and fr:IsA("GuiObject") then
								fr.Visible = false
							end
						end
					end
					if iconGui then
						iconGui.Enabled = true
					end
					setIconForcedHidden(false)
				end
			end)
		)
		saveSidebarGesture()
	end
	if toggleUIBtn and toggleUIBtn:IsA("GuiButton") then
		toggleUIBtn.MouseButton1Click:Connect(function()
			if iconGui then
				iconGui.Enabled = true
			end
			setIconForcedHidden(false)
		end)
	end
	if activeColorValue then
		makeColorSlider("ActiveColor", "Active Color", "Sidebar active button color", activeColorValue)
	end
	if inactiveColorValue then
		makeColorSlider("InactiveColor", "Inactive Color", "Sidebar inactive button color", inactiveColorValue)
	end
	if iconColorValue then
		makeColorSlider("IconColor", "Icon Color", "Custom color for the Delta icon", iconColorValue)
	end
	if iconSizeValue then
		makeSizeSlider("IconSize", "Icon Size", "Scale the Delta icon size", iconSizeValue, 0.5, 5)
	end
	if iconRgbSpeedValue then
		makeSizeSlider("IconRgbSpeed", "RGB Speed", "Speed of the RGB icon effect", iconRgbSpeedValue, 0.05, 2)
	end
	if sidebarGrad1 and sidebarGrad2 and sidebarGradient then
		makeColorSlider("SidebarGradient1", "Sidebar Gradient 1", "First sidebar gradient color", sidebarGrad1)
		makeColorSlider("SidebarGradient2", "Sidebar Gradient 2", "Second sidebar gradient color", sidebarGrad2)
		local function updateSidebarGradient()
			sidebarGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, sidebarGrad1.Value),
				ColorSequenceKeypoint.new(1, sidebarGrad2.Value),
			})
		end
		updateSidebarGradient();
		(sidebarGrad1:GetPropertyChangedSignal("Value")):Connect(updateSidebarGradient);
		(sidebarGrad2:GetPropertyChangedSignal("Value")):Connect(updateSidebarGradient)
	end
	makeIconVisibilityToggle()
	makeIconRgbToggle()
	makeTabNotifToggle()
	makeIconEnableToggle()
	makeIconInputRow()
	makeIconManagerRow()
	makeColorSlider("GestureColor", "Gesture Color", "Color of the sidebar gesture bar", gestCol)
	makeSidebarGestureToggle()
	makeSidebarGestureBarVisibilityToggle()
	if gestureWidthValue then
		makeSizeSlider("GestureWidth", "Gesture width", "Width of the sidebar gesture area", gestureWidthValue, 6, 80)
	end
	if gestureHeightValue then
		makeSizeSlider(
			"GestureHeight",
			"Gesture height",
			"Height of the sidebar gesture area",
			gestureHeightValue,
			60,
			400
		)
	end
	makeAutoCloseToggle()
	makeDestroyUIButton()
	task.defer(function()
		task.wait()
		pcall(function()
			capUi()
			apRad()
			apPan()
			apStk()
			fxSync()
		end)
	end)
	applySidebarGestureState()
	if autoCloseOnLoad and sidebar then
		task.defer(function()
			task.wait(1.5)
			closeDeltaSidebar()
		end)
	end
	local sidemenu = execFrame:FindFirstChild("Sidemenu", true)
	if sidemenu then
		local oldCard = sidemenu:FindFirstChild("Script", true)
		if oldCard and oldCard:IsA("ImageLabel") then
			local parent = oldCard.Parent
			local newCard = oldCard:Clone()
			oldCard:Destroy()
			newCard.Parent = parent
			newCard.Name = "Script"
			local labs = {}
			for _, d in ipairs(newCard:GetDescendants()) do
				if d:IsA("TextLabel") then
					table.insert(labs, d)
				end
			end
			if #labs >= 3 then
				table.sort(labs, function(a, b)
					return a.AbsolutePosition.Y < b.AbsolutePosition.Y
				end)
				local bigHeader = labs[1]
				local subTitle = labs[2]
				local desc = labs[3]
				if bigHeader then
					bigHeader.Text = "Featured"
				end
				if subTitle then
					subTitle.Text = "Nameless Admin"
				end
				if desc then
					desc.Text =
						"continuation of Nameless Admin with advanced features, fixed commands and lots of customization."
				end
			end
			local clickable = nil
			for _, d in ipairs(newCard:GetDescendants()) do
				if d:IsA("LocalScript") then
					d:Destroy()
				elseif d:IsA("TextButton") then
					clickable = d
				end
			end
			if not clickable then
				clickable = newCard:FindFirstChildWhichIsA("GuiButton")
					or newCard:FindFirstChildWhichIsA("GuiButton", true)
					or newCard
			end
			local function runNA()
				pcall(function()
					(loadstring(
						game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/Source.lua")
					))()
				end)
			end
			if clickable:IsA("GuiButton") then
				clickable.MouseButton1Click:Connect(runNA)
			else
				clickable.InputBegan:Connect(function(input)
					if
						input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch
					then
						runNA()
					end
				end)
			end
		end
	end
	local pingLabel
	do
		local nFrame = sidemenu and sidemenu:FindFirstChild("Network", true)
		if nFrame then
			local overlayNet = nFrame:FindFirstChild("Overlay", true)
			local holderNet = overlayNet and overlayNet:FindFirstChild("Holder", true)
			local infoNet = holderNet and holderNet:FindFirstChild("Information", true)
			pingLabel = infoNet and infoNet:FindFirstChild("Ping")
		end
	end
	if pingLabel and Stats and RS then
		local net = Stats.Network
		local item = net and net.ServerStatsItem and net.ServerStatsItem["Data Ping"]
		if item then
			pingLabel.RichText = true
			local pingId = "DeltaCustom_Ping"
			NAlib.disconnect(pingId)
			local function updatePing()
				local v = 0
				pcall(function()
					if item.GetValue then
						v = item:GetValue()
					elseif item.Value ~= nil then
						v = item.Value
					end
				end)
				pingLabel.Text = string.format('<font color="#4FA4F2">%d</font> MS Ping', math.floor(tonumber(v) or 0))
			end
			updatePing()
			local pingAccum = 0
			NAlib.connect(
				pingId,
				RS.Heartbeat:Connect(function(dt)
					pingAccum += dt
					if pingAccum < 0.5 then
						return
					end
					pingAccum = 0
					updatePing()
				end)
			)
		end
	end
	local tabs = overlay:FindFirstChild("Tabs", true)
	local codeSf = overlay:FindFirstChild("Code", true)
	if not tabs then
		notify({ Title = "Delta Customization", Description = "Tabs frame not found.", Duration = 4 })
		return
	end
	if not codeSf then
		notify({ Title = "Delta Customization", Description = "Code frame not found.", Duration = 4 })
		return
	end
	local btns = overlay:FindFirstChild("Buttons", true)
	if btns then
		local bl = {}
		for _, v in ipairs(btns:GetChildren()) do
			if v:IsA("ImageButton") or v:IsA("TextButton") then
				table.insert(bl, v)
			end
		end
		local tpl = btns:FindFirstChild("ExecuteClipboard") or btns:FindFirstChild("Execute") or bl[1]
		if tpl then
			local cp = tpl:Clone()
			cp.Name = "CopyCode"
			local tl = cp:FindFirstChild("Title", true) or cp:FindFirstChildWhichIsA("TextLabel")
			if tl then
				tl.Text = "COPY CODE"
			end
			cp.Parent = btns
			table.insert(bl, cp)
			local cnt = #bl
			if cnt > 0 then
				local w = cnt == 4 and 0.22 or (1 / cnt)
				for _, b in ipairs(bl) do
					b.Size = UDim2.new(w, 0, 1, 0)
				end
			end
			cp.MouseButton1Click:Connect(function()
				if type(setclipboard) ~= "function" then
					return
				end
				local cur
				for _, tb in ipairs(codeSf:GetDescendants()) do
					if tb:IsA("TextBox") and tb.Visible then
						cur = tb
						break
					end
				end
				if cur then
					setclipboard(cur.Text or "")
					notify({
						Title = "Delta Customization",
						Description = "Copied code from the selected tab.",
						Duration = 4,
					})
				end
			end)
		end
	end
	local hasFS = type(isfolder) == "function"
		and type(makefolder) == "function"
		and type(isfile) == "function"
		and type(writefile) == "function"
		and type(readfile) == "function"
		and type(listfiles) == "function"
	if not hasFS then
		notify({
			Title = "Delta Customization",
			Description = "Your executor does not support saving tabs.",
			Duration = 5,
		})
		return
	end
	local rootDir = "DeltaCustom"
	local tabsDir = rootDir .. "/DeltaTabs"
	if not isfolder(rootDir) then
		pcall(makefolder, rootDir)
	end
	if not isfolder(tabsDir) then
		pcall(makefolder, tabsDir)
	end
	local function parseIndex(nm)
		return tonumber(nm:match("^script(%d+)%.lua$"))
	end
	local function isScriptName(nm)
		return parseIndex(nm) ~= nil
	end
	local function getCodeBoxes()
		local t = {}
		for _, c in ipairs(codeSf:GetDescendants()) do
			if c:IsA("TextBox") and isScriptName(c.Name) then
				table.insert(t, c)
			end
		end
		table.sort(t, function(a, b)
			return (parseIndex(a.Name) or 0) < (parseIndex(b.Name) or 0)
		end)
		return t
	end
	local function getSavedNames()
		local list = {}
		for _, p in ipairs(listfiles(tabsDir)) do
			local nm = p:match("([^/\\]+)$")
			if nm and isScriptName(nm) then
				table.insert(list, nm)
			end
		end
		table.sort(list, function(a, b)
			return (parseIndex(a) or 0) < (parseIndex(b) or 0)
		end)
		return list
	end
	local saved = getSavedNames()
	local boxes = getCodeBoxes()
	if tabNotifEnabled then
		if #saved > 0 then
			local desc
			if #saved > #boxes then
				desc = "Saved tabs: "
					.. tostring(#saved)
					.. "\nCreate your tabs in Delta and the saved code will load automatically."
			else
				desc = "Saved tabs: "
					.. tostring(#saved)
					.. "\nYour saved code will load into matching tabs automatically."
			end
			notify({ Title = "Delta Customization", Description = desc, Duration = 8 })
		else
			notify({
				Title = "Delta Customization",
				Description = "No saved tabs yet. Anything you type will be saved automatically.",
				Duration = 6,
			})
		end
	end
	local hooked = {}
	local function hookBox(box)
		if not box or hooked[box] then
			return
		end
		hooked[box] = true
		local ready = false
		local function setupForName(nm)
			if ready then
				return
			end
			if not isScriptName(nm) then
				return
			end
			ready = true
			local path = tabsDir .. "/" .. nm
			if isfile(path) then
				local ok, data = pcall(readfile, path)
				if ok and type(data) == "string" then
					box.Text = data
				end
			end
			local last = 0
			(box:GetPropertyChangedSignal("Text")):Connect(function()
				last = tick()
				local id = last
				task.delay(0.4, function()
					if id ~= last then
						return
					end
					local txt = box.Text
					pcall(writefile, path, txt)
				end)
			end)
		end
		setupForName(box.Name);
		(box:GetPropertyChangedSignal("Name")):Connect(function()
			setupForName(box.Name)
		end)
	end
	for _, b in ipairs(boxes) do
		hookBox(b)
	end
	codeSf.DescendantAdded:Connect(function(obj)
		if obj:IsA("TextBox") then
			task.wait(0.05)
			hookBox(obj)
		end
	end)
	codeSf.DescendantRemoving:Connect(function(obj)
		if not (obj:IsA("TextBox") and isScriptName(obj.Name) and type(delfile) == "function") then
			return
		end
		local txt = ""
		pcall(function()
			txt = obj.Text
		end)
		if type(txt) ~= "string" or txt:match("^%s*$") then
			local path = tabsDir .. "/" .. obj.Name
			if isfile(path) then
				pcall(delfile, path)
			end
		end
	end)
end)

-- visual upgrade patch

local _dvp = (getgenv and getgenv()) or _G
if type(_dvp) == "table" and not _dvp.__DeltaVisualPatchLoaded then
	_dvp.__DeltaVisualPatchLoaded = true
	task.defer(function()
		if (identifyexecutor and identifyexecutor() or ""):lower() ~= "delta" then
			return
		end
		local function S(n)
			local ok, s = pcall(function()
				return __lt.cs(n, cloneref and cloneref or function(v)
					return v
				end)
			end)
			if ok then
				return s
			end
		end
		local HS = S("HttpService")
		local TS = S("TweenService")
		local LG = S("Lighting")
		local CG = S("CoreGui")
		local root = gethui and gethui() or CG
		local function isGib(n)
			if typeof(n) ~= "string" or n == "" then
				return false
			end
			return not n:match("^[%w _%-]+$")
		end
		local function getMain()
			for _, g in ipairs(root:GetChildren()) do
				if g:IsA("ScreenGui") and isGib(g.Name) then
					if
						g:FindFirstChild("Executor", true)
						and g:FindFirstChild("Scripthub", true)
						and g:FindFirstChild("Sidebar", true)
					then
						return g
					end
				end
			end
		end
		local mainGui = getMain()
		if not mainGui then
			return
		end
		local sectionsList = { "Executor", "Home", "Scripthub", "Settings", "Console", "Music" }
		local settingsPath = "DeltaCustom/Settings.json"
		local settingsConfig = {}
		if HS and type(isfile) == "function" and type(readfile) == "function" and isfile(settingsPath) then
			local ok, data = pcall(readfile, settingsPath)
			if ok and data then
				local ok2, dec = pcall(function()
					return __lt.cm("HttpService", "JSONDecode", data)
				end)
				if ok2 and type(dec) == "table" then
					settingsConfig = dec
				end
			end
		end
		local function saveCfg(k, t)
			if not (HS and type(writefile) == "function") then
				return
			end
			settingsConfig[k] = t
			local ok, enc = pcall(function()
				return __lt.cm("HttpService", "JSONEncode", settingsConfig)
			end)
			if ok and enc then
				pcall(writefile, settingsPath, enc)
			end
		end
		local darkOverlay = mainGui:FindFirstChild("DarkOverlay")
		NAlib.disconnect("DarkOverlay_Hide")
		local dimFr = darkOverlay
		if not dimFr then
			dimFr = Instance.new("Frame")
			dimFr.Name = "DarkOverlay"
			dimFr.BackgroundColor3 = Color3.new(0, 0, 0)
			dimFr.BorderSizePixel = 0
			dimFr.Position = UDim2.fromScale(0, 0)
			dimFr.Size = UDim2.fromScale(1, 1)
			dimFr.ZIndex = 1
			dimFr.Visible = false
			dimFr.Active = true
			dimFr.Parent = mainGui
		end
		pcall(function()
			dimFr.BackgroundColor3 = Color3.new(0, 0, 0)
			dimFr.BorderSizePixel = 0
			dimFr.Position = UDim2.fromScale(0, 0)
			dimFr.Size = UDim2.fromScale(1, 1)
			dimFr.ZIndex = 1
			dimFr.Active = true
		end)
		local blurFx
		if LG then
			blurFx = LG:FindFirstChild("DeltaBlur")
			if not blurFx then
				blurFx = Instance.new("BlurEffect")
				blurFx.Name = "DeltaBlur"
				blurFx.Size = 0
				blurFx.Enabled = false
				blurFx.Parent = LG
			end
		end
		local base = { cor = {}, pan = {}, str = {}, got = false }
		local okNm = {
			Sidebar = true,
			Overlay = true,
			Popup = true,
			Searchbar = true,
			Script = true,
			Network = true,
			Information = true,
			RobloxConsole = true,
			RConsole = true,
			Source = true,
			Title = true,
			Executor = true,
			Console = true,
			Home = true,
			Scripthub = true,
			Settings = true,
			Dropdown = true,
			SettingDropdown = true,
			SettingTextbox = true,
			SettingSwitch = true,
			SettingSwitchOn = true,
			Button = true,
			InputText = true,
			LT_ScriptHub = true,
			LT_Music = true,
			Top = true,
			Bottom = true,
			List = true,
			Card = true,
			Card1 = true,
		}
		local skip = {
			Knob = true,
			Hue = true,
			Sat = true,
			Val = true,
			Fill = true,
			DarkOverlay = true,
			SidebarGestureZone = true,
		}
		local function capUi()
			if not mainGui then
				return
			end
			for _, o in ipairs(mainGui:GetDescendants()) do
				if o:IsA("UICorner") then
					local p = o.Parent
					if p and p:IsA("GuiObject") and not skip[p.Name] then
						local s = p.AbsoluteSize
						if okNm[p.Name] or (s.X >= 44 and s.Y >= 18) then
							if base.cor[o] == nil then
								base.cor[o] = o.CornerRadius
							end
						end
					end
				elseif o:IsA("UIStroke") then
					if base.str[o] == nil then
						base.str[o] = o.Thickness
					end
				elseif
					o:IsA("Frame")
					or o:IsA("ImageLabel")
					or o:IsA("TextBox")
					or o:IsA("TextButton")
					or o:IsA("ImageButton")
					or o:IsA("ScrollingFrame")
				then
					if not skip[o.Name] then
						local s = o.AbsoluteSize
						if okNm[o.Name] or s.X >= 120 or s.Y >= 28 then
							local pr = (o:IsA("ImageLabel") or o:IsA("ImageButton")) and "ImageTransparency"
								or "BackgroundTransparency"
							if base.pan[o] == nil then
								base.pan[o] = { pr, o[pr] }
							end
						end
					end
				end
			end
			base.got = true
		end
		local radVal = Instance.new("NumberValue")
		radVal.Value = type(settingsConfig.UiRound) == "table" and math.clamp(settingsConfig.UiRound.value or 0, 0, 18)
			or 0
		local panVal = Instance.new("NumberValue")
		panVal.Value = type(settingsConfig.UiAlpha) == "table"
				and math.clamp(settingsConfig.UiAlpha.value or 0, 0, 0.35)
			or 0
		local stkVal = Instance.new("NumberValue")
		stkVal.Value = type(settingsConfig.UiStroke) == "table"
				and math.clamp(settingsConfig.UiStroke.value or 1, 0, 2.5)
			or 1
		local dimVal = Instance.new("NumberValue")
		dimVal.Value = type(settingsConfig.UiDim) == "table" and math.clamp(settingsConfig.UiDim.value or 0.28, 0, 0.65)
			or 0.28
		local blrVal = Instance.new("NumberValue")
		blrVal.Value = type(settingsConfig.UiBlurSize) == "table"
				and math.clamp(settingsConfig.UiBlurSize.value or 18, 0, 40)
			or 18
		local blrOn = type(settingsConfig.UiBlur) == "table"
				and settingsConfig.UiBlur.enabled ~= nil
				and settingsConfig.UiBlur.enabled
			or false
		local dimDesiredVisible = false
		local dimDesiredTransparency = 1
		local dimEnforceConn
		local function stopDimEnforce()
			if dimEnforceConn then
				dimEnforceConn:Disconnect()
				dimEnforceConn = nil
			end
		end
		local function applyDimState(force)
			pcall(function()
				if force or dimFr.Visible ~= dimDesiredVisible then
					dimFr.Visible = dimDesiredVisible
				end
				if force or math.abs(dimFr.BackgroundTransparency - dimDesiredTransparency) > 0.001 then
					dimFr.BackgroundTransparency = dimDesiredTransparency
				end
				if force or dimFr.Active ~= true then
					dimFr.Active = true
				end
				if force or dimFr.BackgroundColor3 ~= Color3.new(0, 0, 0) then
					dimFr.BackgroundColor3 = Color3.new(0, 0, 0)
				end
			end)
		end
		local function syncDimLoop()
			if dimDesiredVisible and RS then
				if not dimEnforceConn then
					dimEnforceConn = RS.Heartbeat:Connect(function()
						applyDimState(false)
					end)
				end
			else
				stopDimEnforce()
			end
		end
		local function apRad()
			capUi()
			local v = math.floor(math.clamp(radVal.Value, 0, 18) + 0.5)
			for o, b in pairs(base.cor) do
				if o and o.Parent then
					pcall(function()
						o.CornerRadius = UDim.new(b.Scale, math.max(b.Offset, v))
					end)
				end
			end
		end
		local function apPan()
			capUi()
			local a = math.clamp(panVal.Value, 0, 0.35)
			for o, b in pairs(base.pan) do
				if o and o.Parent then
					pcall(function()
						o[b[1]] = math.clamp(b[2] + a, 0, 1)
					end)
				end
			end
		end
		local function apStk()
			capUi()
			local m = math.clamp(stkVal.Value, 0, 2.5)
			for o, b in pairs(base.str) do
				if o and o.Parent then
					pcall(function()
						o.Thickness = b * m
					end)
				end
			end
		end
		local function uiOpen()
			for _, n in ipairs(sectionsList) do
				local fr = mainGui:FindFirstChild(n)
				if fr and fr:IsA("GuiObject") and fr.Visible then
					return true
				end
			end
			return false
		end
		local function fxSync()
			local on = uiOpen()
			if blurFx then
				blurFx.Enabled = blrOn and on and blrVal.Value > 0.05
				blurFx.Size = blurFx.Enabled and math.clamp(blrVal.Value, 0, 40) or 0
			end
			dimDesiredVisible = on and dimVal.Value > 0.01
			dimDesiredTransparency = 1 - math.clamp(dimVal.Value, 0, 0.85)
			applyDimState(true)
			syncDimLoop()
		end
		capUi()
		apRad()
		apPan()
		apStk()
		fxSync()
		radVal.Changed:Connect(function()
			apRad()
			saveCfg("UiRound", { value = math.clamp(radVal.Value, 0, 18) })
		end)
		panVal.Changed:Connect(function()
			apPan()
			saveCfg("UiAlpha", { value = math.clamp(panVal.Value, 0, 0.35) })
		end)
		stkVal.Changed:Connect(function()
			apStk()
			saveCfg("UiStroke", { value = math.clamp(stkVal.Value, 0, 2.5) })
		end)
		dimVal.Changed:Connect(function()
			fxSync()
			saveCfg("UiDim", { value = math.clamp(dimVal.Value, 0, 0.65) })
		end)
		blrVal.Changed:Connect(function()
			fxSync()
			saveCfg("UiBlurSize", { value = math.clamp(blrVal.Value, 0, 40) })
		end)
		for _, n in ipairs(sectionsList) do
			local fr = mainGui:FindFirstChild(n)
			if fr and fr.GetPropertyChangedSignal then
				fr:GetPropertyChangedSignal("Visible"):Connect(function()
					task.defer(fxSync)
				end)
			end
		end
		local settings = mainGui:FindFirstChild("Settings", true)
		local holder = settings and settings:FindFirstChild("Holder")
		local template
		if holder then
			for _, c in ipairs(holder:GetChildren()) do
				if c:IsA("Frame") and c.Name == "Button" then
					template = c
					break
				end
			end
		end
		if holder and template then
			local function mkDock(fr)
				local d = Instance.new("Frame")
				d.Name = "Dock"
				d.BackgroundTransparency = 1
				d.AnchorPoint = Vector2.new(1, 0.5)
				d.Position = UDim2.new(1, -14, 0.5, 0)
				d.Size = UDim2.new(0, 320, 0, 18)
				d.Parent = fr
				local l = Instance.new("UIListLayout")
				l.FillDirection = Enum.FillDirection.Horizontal
				l.HorizontalAlignment = Enum.HorizontalAlignment.Right
				l.VerticalAlignment = Enum.VerticalAlignment.Center
				l.Padding = UDim.new(0, 8)
				l.Parent = d
				return d
			end
			local function mkBox(par)
				local b = Instance.new("TextBox")
				b.Name = "ValueBox"
				b.Size = UDim2.new(0, 70, 0, 18)
				b.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
				b.BorderSizePixel = 0
				b.ClearTextOnFocus = false
				b.TextXAlignment = Enum.TextXAlignment.Center
				b.Font = Enum.Font.Gotham
				b.TextSize = 12
				b.TextColor3 = Color3.new(1, 1, 1)
				b.Parent = par
				return b
			end
			local function mkSl(par, w)
				local s = Instance.new("Frame")
				s.Name = "Slider"
				s.BackgroundTransparency = 1
				s.Size = UDim2.new(0, w or 150, 0, 18)
				s.Parent = par
				local bar = Instance.new("Frame")
				bar.Name = "Bar"
				bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				bar.BorderSizePixel = 0
				bar.AnchorPoint = Vector2.new(0.5, 0.5)
				bar.Position = UDim2.new(0.5, 0, 0.5, 0)
				bar.Size = UDim2.new(1, 0, 0, 6)
				bar.Parent = s
				local bc = Instance.new("UICorner")
				bc.CornerRadius = UDim.new(0, 3)
				bc.Parent = bar
				local fill = Instance.new("Frame")
				fill.Name = "Fill"
				fill.BorderSizePixel = 0
				fill.AnchorPoint = Vector2.new(0, 0.5)
				fill.Position = UDim2.new(0, 0, 0.5, 0)
				fill.Size = UDim2.new(0, 0, 1, 0)
				fill.Parent = bar
				local fc = Instance.new("UICorner")
				fc.CornerRadius = UDim.new(0, 3)
				fc.Parent = fill
				local kb = Instance.new("Frame")
				kb.Name = "Knob"
				kb.Size = UDim2.new(0, 12, 0, 12)
				kb.AnchorPoint = Vector2.new(0.5, 0.5)
				kb.BackgroundColor3 = Color3.new(1, 1, 1)
				kb.BorderSizePixel = 0
				kb.Parent = bar
				local kc = Instance.new("UICorner")
				kc.CornerRadius = UDim.new(1, 0)
				kc.Parent = kb
				return s, bar, fill, kb
			end
			local function makeSizeSlider(id, titleText, descText, numValue, minV, maxV)
				local fr = template:Clone()
				fr.Parent = holder
				fr.Visible = true
				fr.LayoutOrder = -2
				local tl = fr:FindFirstChild("Title", true)
				local dl = fr:FindFirstChild("Desc", true)
				if tl then
					tl.Text = titleText
				end
				if dl then
					dl.Text = descText
				end
				local ob = fr:FindFirstChild("Button", true)
				if ob then
					ob:Destroy()
				end
				local dock = mkDock(fr)
				local vb = mkBox(dock)
				local sl, bar, fill, kb = mkSl(dock, 150)
				local function setVis(v)
					v = math.clamp(v, minV, maxV)
					local a = (v - minV) / (maxV - minV)
					fill.Size = UDim2.new(a, 0, 1, 0)
					kb.Position = UDim2.new(a, 0, 0.5, 0)
					vb.Text = string.format("%.2f", v)
				end
				local function apply(v)
					v = math.clamp(v, minV, maxV)
					numValue.Value = v
					setVis(v)
					saveCfg(id, { value = v })
				end
				setVis(numValue.Value)
				local drag = false
				local function fromIn(input)
					local rel = 0
					pcall(function()
						rel = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
					end)
					rel = math.clamp(rel, 0, 1)
					apply(minV + (maxV - minV) * rel)
				end
				bar.InputBegan:Connect(function(input)
					if
						input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch
					then
						drag = true
						fromIn(input)
					end
				end)
				local ui = S("UserInputService")
				if ui then
					ui.InputChanged:Connect(function(input)
						if
							drag
							and (
								input.UserInputType == Enum.UserInputType.MouseMovement
								or input.UserInputType == Enum.UserInputType.Touch
							)
						then
							fromIn(input)
						end
					end)
					ui.InputEnded:Connect(function(input)
						if
							input.UserInputType == Enum.UserInputType.MouseButton1
							or input.UserInputType == Enum.UserInputType.Touch
						then
							drag = false
						end
					end)
				end
				vb.FocusLost:Connect(function()
					local v = tonumber(vb.Text or "")
					if v then
						apply(v)
					else
						setVis(numValue.Value)
					end
				end)
				local function updDock()
					local w = math.clamp(math.floor(fr.AbsoluteSize.X * 0.46), 240, 380)
					dock.Size = UDim2.new(0, w, 0, 18)
					local sw = math.clamp(w - 78, 140, 280)
					sl.Size = UDim2.new(0, sw, 0, 18)
				end
				updDock()
				fr:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					task.defer(updDock)
				end)
			end
			makeSizeSlider("UiRound", "UI roundness", "Adds extra roundness to panels and cards", radVal, 0, 18)
			makeSizeSlider(
				"UiAlpha",
				"Panel transparency",
				"Makes the heavy panels cleaner and less chunky",
				panVal,
				0,
				0.35
			)
			makeSizeSlider("UiStroke", "Stroke scale", "Scales borders and outlines across Delta", stkVal, 0, 2.5)
			makeSizeSlider("UiDim", "Open dim", "Darkens the game behind Delta while it is open", dimVal, 0, 0.65)
			if blurFx then
				local fr = template:Clone()
				fr.Parent = holder
				fr.Visible = true
				fr.LayoutOrder = -2
				local tl = fr:FindFirstChild("Title", true)
				local dl = fr:FindFirstChild("Desc", true)
				if tl then
					tl.Text = "UI blur"
				end
				if dl then
					dl.Text = "Blur the game behind Delta while it is open"
				end
				local btn = fr:FindFirstChild("Button", true)
				local lb = btn and btn:FindFirstChildWhichIsA("TextLabel")
				if lb then
					lb.Text = "Toggle"
				end
				local click = btn and (btn:FindFirstChildWhichIsA("GuiButton") or btn)
				local function vis()
					btn.BackgroundColor3 = blrOn and Color3.fromRGB(79, 164, 242) or Color3.fromRGB(30, 30, 30)
				end
				vis()
				if click then
					if click:IsA("GuiButton") then
						click.MouseButton1Click:Connect(function()
							blrOn = not blrOn
							vis()
							saveCfg("UiBlur", { enabled = blrOn })
							fxSync()
						end)
					end
				end
				makeSizeSlider("UiBlurSize", "Blur strength", "Blur amount while Delta is open", blrVal, 0, 40)
			end
		end
	end)
end

-- scripthub + music patch

local __lt = (function()
	local g = (getgenv and getgenv()) or _G or {}
	local s = rawget(_G, "shared")
	local h = type(s) == "table" and s or (type(g) == "table" and g or nil)
	if h then
		local c = rawget(h, "__lt_service_resolver")
		if type(c) == "table" then
			return c
		end
	end
	local ld = loadstring or load
	if type(ld) ~= "function" then
		error("resolver loader unavailable")
	end
	local rs = ld(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau")
	if type(rs) ~= "function" then
		error("resolver failed to compile")
	end
	local ok = rs()
	if type(ok) ~= "table" then
		error("resolver failed to load")
	end
	if h then
		h.__lt_service_resolver = ok
	end
	return ok
end)()

if (identifyexecutor and identifyexecutor() or ""):lower() ~= "delta" then
	return
end

local env = type(getgenv) == "function" and getgenv() or _G
if type(env) ~= "table" then
	return
end

if env.__DeltaHubMusicPatch and type(env.__DeltaHubMusicPatch.stop) == "function" then
	pcall(env.__DeltaHubMusicPatch.stop)
end

local ref = cloneref and type(cloneref) == "function" and cloneref or function(v)
	return v
end

local srv = setmetatable({}, {
	__index = function(t, k)
		local ok, v = pcall(function()
			return __lt.cs(k, ref)
		end)
		if ok and v then
			rawset(t, k, v)
			return v
		end
	end,
})

local function S(n)
	return srv[n]
end

local UIS = S("UserInputService")
local TS = S("TweenService")
local RS = S("RunService")
local SS = S("SoundService")
local HS = S("HttpService")
local CG = S("CoreGui")

local root = gethui and gethui() or CG
local rq = request or http_request or syn and syn.request

local st = {
	con = {},
	pg = {},
	snd = nil,
	muted = {},
	gui = nil,
}

local function con(c)
	if c then
		st.con[#st.con + 1] = c
	end
	return c
end

local function disc()
	for _, c in ipairs(st.con) do
		pcall(function()
			c:Disconnect()
		end)
	end
	st.con = {}
end

local function stop()
	disc()
	if st.snd then
		pcall(function()
			st.snd:Destroy()
		end)
		st.snd = nil
	end
	if st.pg.music then
		pcall(function()
			st.pg.music:Destroy()
		end)
	end
	if st.pg.sh and st.pg.sh:FindFirstChild("LT_ScriptHub") then
		pcall(function()
			st.pg.sh.LT_ScriptHub:Destroy()
		end)
	end
	for o, v in pairs(st.muted) do
		if o and o.Parent then
			pcall(function()
				o.Visible = v
			end)
		end
	end
	st.muted = {}
	env.__DeltaHubMusicPatch = nil
end

env.__DeltaHubMusicPatch = {
	stop = stop,
}

local function trim(s)
	if type(s) ~= "string" then
		return ""
	end
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function isg(s)
	if typeof(s) ~= "string" or s == "" then
		return false
	end
	return not s:match("^[%w _%-]+$")
end

local function getMain()
	for _, g in ipairs(root:GetChildren()) do
		if g:IsA("ScreenGui") and isg(g.Name) then
			if
				g:FindFirstChild("Executor", true)
				and g:FindFirstChild("Scripthub", true)
				and g:FindFirstChild("Sidebar", true)
			then
				return g
			end
		end
	end
end

local gui = getMain()
if not gui then
	return
end
st.gui = gui

local sb = gui:FindFirstChild("Sidebar", true)
local sh = gui:FindFirstChild("Scripthub")
local ex = gui:FindFirstChild("Executor")
local hm = gui:FindFirstChild("Home")
local se = gui:FindFirstChild("Settings")
local co = gui:FindFirstChild("Console")

if not (sb and sh) then
	return
end

st.pg.sh = sh

local sec = {
	"Executor",
	"Home",
	"Scripthub",
	"Settings",
	"Console",
	"Music",
}

local musOpenPos = UDim2.new(0.476246715, 0, 0.508232415, 0)
local musClosedPos = UDim2.new(0.400000006, 0, 0.508232415, 0)
local musTw
local music
local syncTabColors
local function tweenMusic(toPos, show, hideAfter)
	if not music then
		return
	end
	if musTw then
		pcall(function()
			musTw:Cancel()
		end)
		musTw = nil
	end
	if show then
		music.Visible = true
	end
	if TS then
		music.Position = music.Position
		musTw = TS:Create(music, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = toPos,
		})
		if hideAfter then
			con(musTw.Completed:Connect(function()
				if music then
					music.Visible = false
				end
			end))
		end
		musTw:Play()
	else
		music.Position = toPos
		if hideAfter then
			music.Visible = false
		end
	end
end

local function openMusic()
	if not music then
		return
	end
	activeTab = "Music"
	for _, n in ipairs(sec) do
		local p = gui:FindFirstChild(n)
		if p and p:IsA("GuiObject") and p ~= music then
			p.Visible = false
		end
	end
	music.Position = musClosedPos
	tweenMusic(musOpenPos, true, false)
	task.defer(function()
		syncTabColors("Music")
	end)
end

local function closeMusic(anim)
	if not music then
		return
	end
	if not music.Visible then
		music.Position = musClosedPos
		return
	end
	if anim then
		tweenMusic(musClosedPos, false, true)
	else
		music.Position = musClosedPos
		music.Visible = false
	end
end

local function hideAll(exn)
	if exn == "Music" then
		activeTab = "Music"
		openMusic()
		return
	end
	activeTab = exn
	closeMusic(true)
	for _, n in ipairs(sec) do
		local p = gui:FindFirstChild(n)
		if p and p:IsA("GuiObject") and n ~= "Music" then
			p.Visible = n == exn
		end
	end
	task.defer(function()
		syncTabColors(exn)
	end)
end

local function txtOf(o)
	for _, d in ipairs(o:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			return d
		end
	end
end

local function gbtn(nm)
	for _, d in ipairs(sb:GetDescendants()) do
		if d:IsA("GuiButton") and d.Name == nm then
			return d
		end
	end
end

local homeBtn = gbtn("Home")
local shBtn = gbtn("Scripthub")
local setBtn = gbtn("Settings")
local exBtn = gbtn("Executor")
local conBtn = gbtn("Console")
local togBtn = gbtn("ToggleUI")
local acv = sb:FindFirstChild("ActiveColor")
local icv = sb:FindFirstChild("InactiveColor")

local function imgOf(btn)
	if not btn then
		return nil
	end
	return btn:FindFirstChildWhichIsA("ImageLabel")
end

local function improveSidebarTouch(btn)
	if not (btn and btn:IsA("GuiButton") and UIS and UIS.TouchEnabled) then
		return btn
	end
	if btn:GetAttribute("LT_TouchSized") then
		return btn
	end
	btn:SetAttribute("LT_TouchSized", true)
	pcall(function()
		btn.Size = UDim2.new(
			btn.Size.X.Scale,
			btn.Size.X.Offset + 8,
			btn.Size.Y.Scale,
			btn.Size.Y.Offset + 14
		)
	end)
	return btn
end

local offBg = shBtn and shBtn.BackgroundColor3 or Color3.fromRGB(41, 45, 58)
local offImg = imgOf(shBtn) and imgOf(shBtn).ImageColor3 or Color3.fromRGB(138, 145, 164)
local onImg = Color3.new(1, 1, 1)

improveSidebarTouch(homeBtn)
improveSidebarTouch(shBtn)
improveSidebarTouch(setBtn)
improveSidebarTouch(exBtn)
improveSidebarTouch(conBtn)
improveSidebarTouch(togBtn)

local function bgOn()
	return acv and acv.Value or col.ac
end

local function bgOff()
	return icv and icv.Value or offBg
end

local function applyBtnState(btn, on)
	if not btn then
		return
	end
	local targetBg = on and bgOn() or bgOff()
	local targetImg = on and onImg or offImg
	local img = imgOf(btn)
	if TS then
		pcall(function()
			TS:Create(btn, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = targetBg,
			}):Play()
		end)
		if img then
			pcall(function()
				TS:Create(img, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					ImageColor3 = targetImg,
				}):Play()
			end)
		end
	else
		pcall(function()
			btn.BackgroundColor3 = targetBg
		end)
		if img then
			pcall(function()
				img.ImageColor3 = targetImg
			end)
		end
	end
end

local musb
local activeTab
local function visibleTab()
	for _, n in ipairs(sec) do
		local p = gui:FindFirstChild(n)
		if p and p:IsA("GuiObject") and p.Visible then
			return n
		end
	end
end

function syncTabColors(forceTab)
	local curTab = forceTab or visibleTab()
	local map = {
		Home = homeBtn,
		Executor = exBtn,
		Scripthub = shBtn,
		Settings = setBtn,
		Console = conBtn,
		Music = musb,
	}
	for n, b in pairs(map) do
		applyBtnState(b, curTab == n)
	end
end

local function muteObj(d)
	if not (d and d:IsA("GuiObject")) then
		return
	end
	local keep = false
	if d == sh then
		keep = true
	elseif d:FindFirstAncestor("LT_ScriptHub") then
		keep = true
	end
	if keep then
		return
	end
	if st.muted[d] == nil then
		st.muted[d] = d.Visible
	end
	pcall(function()
		d.Visible = false
	end)
	if d.GetPropertyChangedSignal then
		con(d:GetPropertyChangedSignal("Visible"):Connect(function()
			if d.Parent and not d:FindFirstAncestor("LT_ScriptHub") then
				pcall(function()
					d.Visible = false
				end)
			end
		end))
	end
end

local function muteSh()
	st.muted = {}
	for _, d in ipairs(sh:GetDescendants()) do
		muteObj(d)
	end
end

local col = {
	bg = Color3.fromRGB(20, 22, 26),
	bg2 = Color3.fromRGB(30, 33, 40),
	cd = Color3.fromRGB(26, 29, 36),
	st = Color3.fromRGB(70, 75, 85),
	ac = Color3.fromRGB(79, 164, 242),
	tx = Color3.fromRGB(255, 255, 255),
	td = Color3.fromRGB(186, 192, 205),
	su = Color3.fromRGB(52, 211, 153),
	wa = Color3.fromRGB(255, 179, 71),
	er = Color3.fromRGB(244, 63, 94),
}

local function mk(class, props, kids)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	for _, c in ipairs(kids or {}) do
		c.Parent = o
	end
	return o
end

local function req(u)
	local body
	if type(rq) == "function" then
		local ok, r = pcall(rq, {
			Url = u,
			Method = "GET",
			Headers = {
				["User-Agent"] = "Roblox/Http/1.1",
				["Accept"] = "*/*",
			},
		})
		if ok and r then
			body = r.Body or r.body
		end
	end
	if type(body) ~= "string" or body == "" then
		local ok2, r2 = pcall(function()
			return game:HttpGet(u)
		end)
		if ok2 and type(r2) == "string" and r2 ~= "" then
			body = r2
		end
	end
	if type(body) ~= "string" or body == "" then
		return nil
	end
	local ok3, dec = pcall(function()
		return __lt.cm("HttpService", "JSONDecode", body)
	end)
	if ok3 then
		return dec
	end
end

local SCRIPTBLOX_BASE = "https://scriptblox.com"
local RSCRIPTS_BASE = "https://rscripts.net"
local IMAGE_CACHE_DIR = "DeltaCustom/ScriptHubImages"

local function sanitizeFileName(str)
	return tostring(str or ""):gsub("[^%w%._%-]", "_")
end

local function hashString(str)
	local h = 0
	for i = 1, #str do
		h = (h * 31 + string.byte(str, i)) % 4294967296
	end
	return string.format("%08x", h)
end

local function clearImageCache()
	if
		type(isfolder) ~= "function"
		or type(listfiles) ~= "function"
		or type(isfile) ~= "function"
		or type(delfile) ~= "function"
	then
		return false
	end
	local okExists, exists = pcall(isfolder, IMAGE_CACHE_DIR)
	if not okExists or not exists then
		return false
	end
	local okList, files = pcall(listfiles, IMAGE_CACHE_DIR)
	if not okList or type(files) ~= "table" then
		return false
	end
	for _, path in ipairs(files) do
		if type(path) == "string" and path ~= "" then
			pcall(delfile, path)
		end
	end
	return true
end

local function ensureImageFolder()
	if type(isfolder) ~= "function" or type(makefolder) ~= "function" then
		return false
	end
	local ok, ex = pcall(isfolder, IMAGE_CACHE_DIR)
	if ok and ex then
		return true
	end
	return pcall(makefolder, IMAGE_CACHE_DIR) == true
end

local function deriveImageFileName(url)
	local name = url:match("/([^/%?#]+)") or "image"
	name = name:match("([^?#]+)") or name
	local base = sanitizeFileName(name:match("(.+)%.") or name)
	return string.format("%s_%s.bin", base ~= "" and base or "image", hashString(url))
end

clearImageCache()

local function normalizeImageUrl(url, base)
	if type(url) ~= "string" or url == "" then
		return nil
	end
	local t = trim(url)
	if t == "" then
		return nil
	end
	if t:match("^rbxassetid://") or t:match("^rbxthumb://") then
		return nil
	end
	if t:match("^https?://") then
		return t
	end
	if t:sub(1, 2) == "//" then
		return "https:" .. t
	end
	if t:sub(1, 1) == "/" then
		return (base or "") .. t
	end
	return base and (base .. "/" .. t) or t
end

local function isMeaningfulImageUrl(url)
	if type(url) ~= "string" or url == "" then
		return false
	end
	return not url:lower():find("no%-script")
end

local function httpGetBinary(url, headers)
	if type(url) ~= "string" or url == "" then
		return nil
	end
	local function tryRequest(hdr)
		if type(rq) ~= "function" then
			return nil
		end
		local h = {}
		if type(hdr) == "table" then
			for k, v in pairs(hdr) do
				h[k] = v
			end
		end
		h["User-Agent"] = h["User-Agent"] or "Roblox/Http/1.1"
		h["Accept"] = h["Accept"] or "*/*"
		local ok, res = pcall(rq, {
			Url = url,
			Method = "GET",
			Headers = h,
		})
		if ok and res then
			local code = res.StatusCode or res.Status or res.status_code or 0
			local body = res.Body or res.body
			if (code == 0 or code >= 200 and code < 300) and type(body) == "string" and body ~= "" then
				return body
			end
		end
		return nil
	end
	local data = tryRequest(headers)
	if type(data) == "string" and data ~= "" then
		return data
	end
	local ok2, body2 = pcall(function()
		return game:HttpGet(url)
	end)
	if ok2 and type(body2) == "string" and body2 ~= "" then
		return body2
	end
	return tryRequest(nil)
end

local function downloadImageAsset(url)
	if type(url) ~= "string" or url == "" then
		return nil
	end
	if type(getcustomasset) ~= "function" or type(writefile) ~= "function" or type(isfile) ~= "function" then
		return nil
	end
	if not ensureImageFolder() then
		return nil
	end
	local full = IMAGE_CACHE_DIR .. "/" .. deriveImageFileName(url)
	local okEx, ex = pcall(isfile, full)
	if not (okEx and ex) then
		local host = url:match("^https?://([^/]+)") or ""
		local hdr
		if host:find("rscripts%.net") then
			hdr = { Referer = RSCRIPTS_BASE }
		elseif host:find("rbxcdn%.com") then
			hdr = { Referer = "https://www.roblox.com/" }
		end
		local data = httpGetBinary(url, hdr)
		if not (type(data) == "string" and data ~= "") then
			return nil
		end
		local okW = pcall(writefile, full, data)
		if not okW then
			return nil
		end
	end
	local okA, asset = pcall(getcustomasset, full)
	if okA and type(asset) == "string" and asset ~= "" then
		return asset
	end
	return nil
end

local function resolveScriptBloxImage(d)
	if not d then
		return nil
	end
	local function pick(vals)
		for _, v in ipairs(vals) do
			local n = normalizeImageUrl(v, SCRIPTBLOX_BASE)
			if n and isMeaningfulImageUrl(n) then
				return n
			end
		end
	end
	return pick({
		d.image,
		d.imageUrl,
		d.thumbnail,
		d.coverImage,
		d.icon,
		d.game and d.game.imageUrl,
		d.game and d.game.thumbnail,
		d.game and d.game.image,
		d.game and d.game.coverImage,
		d.game and d.game.icon,
	})
end

local function resolveRScriptsImage(d)
	if not d then
		return nil
	end
	local function pick(vals)
		for _, v in ipairs(vals) do
			local n = normalizeImageUrl(v, RSCRIPTS_BASE)
			if n then
				return n
			end
		end
	end
	return pick({
		d.image,
		d.imageUrl,
		d.thumbnail,
		d.cover,
		d.banner,
		d.img,
		d.game and d.game.imgurl,
		d.game and d.game.imageUrl,
		d.game and d.game.image,
		d.game and d.game.thumbnail,
		d.game and d.game.cover,
		d.game and d.game.banner,
		d.game and d.game.gameLogo,
	})
end

local function buildRobloxThumbnail(placeId)
	local id = tostring(placeId or "")
	if id == "" or id == "0" then
		return nil
	end
	return "https://www.roblox.com/Thumbs/PlaceThumbnail.ashx?width=420&height=270&format=png&placeId=" .. id
end

local function toast(a, b)
	if type(env.Notify) == "function" then
		pcall(env.Notify, {
			Title = a,
			Description = b,
			Duration = 4,
		})
		return
	end
	if type(env.nt) == "function" then
		pcall(env.nt, {
			Title = a,
			Description = b,
			Duration = 4,
		})
	end
end

local hub = sh:FindFirstChild("LT_ScriptHub")
if hub then
	hub:Destroy()
end

muteSh()

hub = mk("Frame", {
	Name = "LT_ScriptHub",
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 1, 0),
	Visible = true,
	ZIndex = 50,
	Parent = sh,
}, {
	mk("UIPadding", {
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}),
})

local top = mk("Frame", {
	Name = "Top",
	BackgroundColor3 = col.bg2,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 42),
	Parent = hub,
	ZIndex = 51,
}, {
	mk("UICorner", {
		CornerRadius = UDim.new(0, 10),
	}),
	mk("UIStroke", {
		Color = col.st,
		Transparency = 0.35,
	}),
})

local engb = mk("TextButton", {
	Name = "Engine",
	BackgroundColor3 = col.bg,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 148, 1, 0),
	Text = "Engine: ScriptBlox",
	TextColor3 = col.tx,
	Font = Enum.Font.GothamSemibold,
	TextSize = 13,
	Parent = top,
	ZIndex = 52,
}, {
	mk("UICorner", {
		CornerRadius = UDim.new(0, 8),
	}),
	mk("UIStroke", {
		Color = col.st,
		Transparency = 0.3,
	}),
})

local fltb = mk("TextButton", {
	Name = "Filter",
	BackgroundColor3 = col.bg,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 88, 1, 0),
	Position = UDim2.new(1, -176, 0, 0),
	Text = "All",
	TextColor3 = col.tx,
	Font = Enum.Font.GothamSemibold,
	TextSize = 13,
	Parent = top,
	ZIndex = 52,
}, {
	mk("UICorner", {
		CornerRadius = UDim.new(0, 8),
	}),
	mk("UIStroke", {
		Color = col.st,
		Transparency = 0.3,
	}),
})

local gob = mk("TextButton", {
	Name = "Go",
	BackgroundColor3 = col.ac,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 80, 1, 0),
	Position = UDim2.new(1, -80, 0, 0),
	Text = "Search",
	TextColor3 = col.tx,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	Parent = top,
	ZIndex = 52,
}, {
	mk("UICorner", {
		CornerRadius = UDim.new(0, 8),
	}),
})

local sbox = mk("TextBox", {
	Name = "Search",
	BackgroundColor3 = col.bg,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -332, 1, 0),
	Position = UDim2.new(0, 156, 0, 0),
	ClearTextOnFocus = false,
	Text = "",
	PlaceholderText = "Search for scripts (scriptblox.com)",
	TextColor3 = col.tx,
	PlaceholderColor3 = col.td,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.Gotham,
	TextSize = 13,
	Parent = top,
	ZIndex = 52,
}, {
	mk("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}),
	mk("UICorner", {
		CornerRadius = UDim.new(0, 8),
	}),
	mk("UIStroke", {
		Color = col.st,
		Transparency = 0.3,
	}),
})

local list = mk("ScrollingFrame", {
	Name = "List",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 1, -92),
	Position = UDim2.new(0, 0, 0, 50),
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollBarThickness = 4,
	Parent = hub,
	ZIndex = 51,
}, {
	mk("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local bot = mk("Frame", {
	Name = "Bottom",
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 32),
	Position = UDim2.new(0, 0, 1, -32),
	Parent = hub,
	ZIndex = 51,
})

local prev = mk("TextButton", {
	BackgroundColor3 = col.bg,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 72, 1, 0),
	Text = "Prev",
	TextColor3 = col.tx,
	Font = Enum.Font.GothamSemibold,
	TextSize = 12,
	Parent = bot,
	ZIndex = 52,
}, {
	mk("UICorner", {
		CornerRadius = UDim.new(0, 8),
	}),
	mk("UIStroke", {
		Color = col.st,
		Transparency = 0.35,
	}),
})

local nextb = mk("TextButton", {
	BackgroundColor3 = col.bg,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 72, 1, 0),
	Position = UDim2.new(1, -72, 0, 0),
	Text = "Next",
	TextColor3 = col.tx,
	Font = Enum.Font.GothamSemibold,
	TextSize = 12,
	Parent = bot,
	ZIndex = 52,
}, {
	mk("UICorner", {
		CornerRadius = UDim.new(0, 8),
	}),
	mk("UIStroke", {
		Color = col.st,
		Transparency = 0.35,
	}),
})

local pgt = mk("TextLabel", {
	BackgroundTransparency = 1,
	Size = UDim2.new(1, -160, 1, 0),
	Position = UDim2.new(0, 80, 0, 0),
	Text = "Page 1 / 1",
	TextColor3 = col.td,
	Font = Enum.Font.Gotham,
	TextSize = 12,
	Parent = bot,
	ZIndex = 52,
})

local eng = "ScriptBlox"
local flt = "all"
local cur = 1
local maxp = 1
local q = ""
local tr = true
local busy = false
local data = {}

local function pass(d)
	local v = eng == "ScriptBlox" and d.key or d.keySystem
	local k = false
	if type(v) == "boolean" then
		k = v
	elseif type(v) == "number" then
		k = v ~= 0
	elseif type(v) == "string" then
		local s = v:lower()
		if
			s ~= ""
			and s ~= "false"
			and s ~= "0"
			and s ~= "none"
			and s ~= "n/a"
			and not s:find("no key", 1, true)
			and not s:find("keyless", 1, true)
		then
			k = true
		end
	elseif v ~= nil and v ~= false then
		k = true
	end
	if flt == "all" then
		return true
	elseif flt == "keyless" then
		return not k
	else
		return k
	end
end

local function shClr()
	for _, c in ipairs(list:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function shMsg(t, c3)
	local lb = mk("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 40),
		Text = t,
		TextColor3 = c3 or col.td,
		Font = Enum.Font.GothamSemibold,
		TextSize = 14,
		Parent = list,
	})
	return lb
end

local function mkb(par, tx, c3)
	return mk("TextButton", {
		BackgroundColor3 = c3,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 88, 0, 28),
		Text = tx,
		TextColor3 = col.tx,
		Font = Enum.Font.GothamSemibold,
		TextSize = 12,
		Parent = par,
	}, {
		mk("UICorner", {
			CornerRadius = UDim.new(0, 7),
		}),
	})
end

local function getRw(d)
	return eng == "ScriptBlox" and d.script or d.rawScript or d.scriptLink or d.raw or ""
end

local function getTi(d)
	return d.title or d.name or "Untitled Script"
end

local function getGa(d)
	if eng == "ScriptBlox" then
		return d.game and d.game.name or "Unknown Game"
	end
	return d.game and d.game.title or "Unknown Game"
end

local function keyReq(d)
	local v = eng == "ScriptBlox" and d.key or d.keySystem
	local k = false
	if type(v) == "boolean" then
		k = v
	elseif type(v) == "number" then
		k = v ~= 0
	elseif type(v) == "string" then
		local s = v:lower()
		if
			s ~= ""
			and s ~= "false"
			and s ~= "0"
			and s ~= "none"
			and s ~= "n/a"
			and not s:find("no key", 1, true)
			and not s:find("keyless", 1, true)
		then
			k = true
		end
	elseif v ~= nil and v ~= false then
		k = true
	end
	return k
end

local function getInfo(d)
	local v = tostring(d.views or d.viewCount or 0)
	local l = tostring(d.likeCount or 0)
	local k = keyReq(d) and "Key" or "Keyless"
	local s = d.isPatched and "Patched" or "Working"
	local info = string.format("%s | Views %s | Likes %s | %s", k, v, l, s)
	if eng == "RScripts" and d.discord and d.discord ~= "" then
		info = info .. " | Discord"
	end
	return info
end

local function mkRow()
	return mk("Frame", {
		Name = "Row",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 124),
		Parent = list,
		ZIndex = 51,
	}, {
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

local function mkCard(par, i, d)
	local rw = getRw(d)
	local placeId
	if eng == "ScriptBlox" then
		placeId = d.game and d.game.gameId
	else
		placeId = d.game and (d.game.placeId or d.game.gameLink and d.game.gameLink:match("/games/(%d+)"))
	end
	placeId = tonumber(placeId)

	local bgUrl = eng == "ScriptBlox" and resolveScriptBloxImage(d) or resolveRScriptsImage(d)
	if not bgUrl and placeId then
		bgUrl = buildRobloxThumbnail(placeId)
	end
	local bgAsset = bgUrl and downloadImageAsset(bgUrl) or nil
	local bgImg = bgAsset or bgUrl

	local cd = mk("Frame", {
		Name = "Card" .. tostring(i),
		BackgroundColor3 = col.cd,
		BorderSizePixel = 0,
		Size = UDim2.new(0.333333343, -7, 1, 0),
		LayoutOrder = i,
		ClipsDescendants = true,
		Parent = par,
	}, {
		mk("UICorner", {
			CornerRadius = UDim.new(0, 10),
		}),
		mk("UIStroke", {
			Color = col.st,
			Transparency = 0.35,
		}),
	})

	if bgImg then
		mk("ImageLabel", {
			Name = "Cover",
			BackgroundColor3 = Color3.fromRGB(12, 14, 22),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Image = bgImg,
			ImageTransparency = 0.1,
			ScaleType = Enum.ScaleType.Crop,
			Parent = cd,
			ZIndex = 0,
		}, {
			mk("UICorner", {
				CornerRadius = UDim.new(0, 10),
			}),
		})
		mk("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Parent = cd,
			ZIndex = 1,
		}, {
			mk("UICorner", {
				CornerRadius = UDim.new(0, 10),
			}),
			mk("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.08),
					NumberSequenceKeypoint.new(1, 0.45),
				}),
			}),
		})
	end

	mk("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, 20),
		Position = UDim2.new(0, 8, 0, 8),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = col.tx,
		Text = getTi(d),
		Parent = cd,
		ZIndex = 2,
	})

	mk("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, 18),
		Position = UDim2.new(0, 8, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Font = Enum.Font.GothamSemibold,
		TextSize = 12,
		TextColor3 = col.ac,
		Text = getGa(d),
		Parent = cd,
		ZIndex = 2,
	})

	mk("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, 30),
		Position = UDim2.new(0, 8, 0, 50),
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = col.td,
		Text = getInfo(d),
		Parent = cd,
		ZIndex = 2,
	})

	local row = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, 28),
		Position = UDim2.new(0, 8, 1, -36),
		Parent = cd,
		ZIndex = 2,
	}, {
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
		}),
	})

	local run = mkb(row, "Run", col.su)
	run.ZIndex = 3
	local cp = setclipboard and mkb(row, "Copy", Color3.fromRGB(57, 63, 75)) or nil
	if cp then
		cp.ZIndex = 3
	end
	local dc = eng == "RScripts"
			and d.discord
			and d.discord ~= ""
			and setclipboard
			and mkb(row, "Discord", Color3.fromRGB(28, 116, 224))
		or nil
	if dc then
		dc.ZIndex = 3
	end

	con(run.MouseButton1Click:Connect(function()
		local ok, er = pcall(function()
			if eng == "ScriptBlox" then
				(loadstring(rw))()
			else
				(loadstring(game:HttpGet(rw)))()
			end
		end)
		if ok then
			toast("ScriptHub", "Executed script.")
		else
			toast("ScriptHub", tostring(er))
		end
	end))

	if cp then
		con(cp.MouseButton1Click:Connect(function()
			pcall(function()
				if eng == "ScriptBlox" then
					setclipboard(rw)
				else
					setclipboard(game:HttpGet(rw))
				end
			end)
			cp.Text = "Copied"
			task.delay(0.8, function()
				if cp and cp.Parent then
					cp.Text = "Copy"
				end
			end)
		end))
	end

	if dc then
		con(dc.MouseButton1Click:Connect(function()
			pcall(function()
				setclipboard(d.discord)
			end)
			dc.Text = "Copied"
			task.delay(0.8, function()
				if dc and dc.Parent then
					dc.Text = "Discord"
				end
			end)
		end))
	end
end

local function ren()
	shClr()
	pgt.Text = string.format("Page %d / %d", cur, maxp)
	if not data or #data == 0 then
		shMsg("No scripts found", col.wa)
		return
	end
	local n = 0
	local row
	local coln = 0
	for _, d in ipairs(data) do
		if pass(d) then
			if not row or coln >= 3 then
				row = mkRow()
				coln = 0
			end
			n += 1
			coln += 1
			mkCard(row, n, d)
		end
	end
	if n == 0 then
		if flt == "keyless" then
			shMsg("No keyless scripts found on this page", col.wa)
		elseif flt == "key" then
			shMsg("No key-required scripts found on this page", col.wa)
		else
			shMsg("No scripts found", col.wa)
		end
	end
end

local function setBusy(v)
	busy = v and true or false
	gob.Active = not busy
	prev.Active = not busy
	nextb.Active = not busy
	gob.Text = busy and "Loading" or "Search"
end

local function fetch(q2, tr2, p2)
	if busy then
		return
	end
	clearImageCache()
	q2 = trim(q2 or "")
	tr2 = eng == "ScriptBlox" and tr2 == true or false
	p2 = math.max(tonumber(p2) or 1, 1)
	q = q2
	tr = tr2
	cur = p2
	maxp = 1
	data = {}
	setBusy(true)
	shClr()
	shMsg("Loading...", col.td)
	local enc = __lt.cm("HttpService", "UrlEncode", q2)
	local u
	if eng == "RScripts" then
		u = string.format("https://rscripts.net/api/v2/scripts?page=%d&orderBy=date&sort=desc", p2)
		if q2 ~= "" then
			u = u .. "&q=" .. enc
		end
	elseif tr2 then
		u = string.format("https://scriptblox.com/api/script/fetch?page=%d", p2)
	else
		u = string.format("https://scriptblox.com/api/script/search?q=%s&page=%d", enc, p2)
	end
	local dec = req(u)
	shClr()
	if not dec then
		shMsg("Request failed", col.er)
		setBusy(false)
		return
	end
	local arr
	if eng == "RScripts" then
		arr = dec.scripts
		maxp = math.max(dec.info and dec.info.maxPages or 1, 1)
	else
		local r = dec.result or {}
		arr = r.scripts
		maxp = math.max(r.totalPages or 1, 1)
	end
	data = arr or {}
	if #data == 0 then
		shMsg("No scripts found", col.wa)
		pgt.Text = string.format("Page %d / %d", cur, maxp)
		setBusy(false)
		return
	end
	ren()
	setBusy(false)
end

con(engb.MouseButton1Click:Connect(function()
	if eng == "ScriptBlox" then
		eng = "RScripts"
		engb.Text = "Engine: RScripts"
		sbox.PlaceholderText = "Search for scripts (rscripts.net)"
		engb.BackgroundColor3 = Color3.fromRGB(45, 49, 58)
		toast("ScriptHub", "Switched to RScripts")
	else
		eng = "ScriptBlox"
		engb.Text = "Engine: ScriptBlox"
		sbox.PlaceholderText = "Search for scripts (scriptblox.com)"
		engb.BackgroundColor3 = col.bg
		toast("ScriptHub", "Switched to ScriptBlox")
	end
	data = {}
	cur = 1
	maxp = 1
	pgt.Text = "Page 1 / 1"
	shClr()
	shMsg("Press Search to load scripts", col.td)
end))

con(fltb.MouseButton1Click:Connect(function()
	if flt == "all" then
		flt = "keyless"
		fltb.Text = "Keyless"
	elseif flt == "keyless" then
		flt = "key"
		fltb.Text = "Key"
	else
		flt = "all"
		fltb.Text = "All"
	end
	ren()
end))

con(gob.MouseButton1Click:Connect(function()
	local t = trim(sbox.Text)
	if t ~= "" then
		fetch(t, false, 1)
	else
		if eng == "ScriptBlox" then
			fetch("", true, 1)
		else
			fetch("", false, 1)
		end
	end
end))

con(sbox.FocusLost:Connect(function(ent)
	if ent then
		local t = trim(sbox.Text)
		if t ~= "" then
			fetch(t, false, 1)
		else
			if eng == "ScriptBlox" then
				fetch("", true, 1)
			else
				fetch("", false, 1)
			end
		end
	end
end))

con(prev.MouseButton1Click:Connect(function()
	if busy then
		return
	end
	if cur > 1 then
		fetch(q, tr, cur - 1)
	end
end))

con(nextb.MouseButton1Click:Connect(function()
	if busy then
		return
	end
	if cur < maxp then
		fetch(q, tr, cur + 1)
	end
end))

shClr()
shMsg("Press Search to load scripts", col.td)
con(sh.DescendantAdded:Connect(function(d)
	muteObj(d)
end))

local function buildMusicTab()
	music = gui:FindFirstChild("Music")
	if music then
		pcall(function()
			music:Destroy()
		end)
	end

	local tpl = sh or hm or se or ex or co
	if tpl and tpl:IsA("GuiObject") then
		music = tpl:Clone()
		music.Name = "Music"
		music.Visible = false
		music.Parent = gui
		pcall(function()
			music.AnchorPoint = Vector2.new(0.5, 0.5)
			music.Position = musClosedPos
			music.Size = sh.Size
			music.ZIndex = sh.ZIndex
		end)
		for _, d in ipairs(music:GetDescendants()) do
			if d:IsA("LocalScript") then
				d:Destroy()
			elseif d:IsA("GuiObject") and d ~= music then
				pcall(function()
					d.Visible = false
				end)
			end
		end
	else
		music = mk("Frame", {
			Name = "Music",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = musClosedPos,
			Size = sh and sh.Size or UDim2.new(0.848344803, 0, 0.892481446, 0),
			Visible = false,
			Parent = gui,
			ZIndex = sh and sh.ZIndex or 100,
		})
	end

	st.pg.music = music

	local mr = mk("ScrollingFrame", {
		Name = "LT_Music",
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(0, 0, 0, 550),
		ElasticBehavior = Enum.ElasticBehavior.Never,
		HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarImageColor3 = col.st,
		ScrollBarThickness = 4,
		TopImage = "",
		MidImage = "",
		BottomImage = "",
		VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.94, 0, 0.88, 0),
		Visible = true,
		ZIndex = 50,
		Parent = music,
	})

	local function mkPanel(name, pos, size, fill, stroke, z)
		return mk("Frame", {
			Name = name,
			BackgroundColor3 = fill or col.bg2,
			BorderSizePixel = 0,
			Position = pos,
			Size = size,
			Parent = mr,
			ZIndex = z or 51,
		}, {
			mk("UICorner", {
				CornerRadius = UDim.new(0, 12),
			}),
			mk("UIStroke", {
				Color = stroke or col.st,
				Transparency = 0.28,
			}),
		})
	end

	local function mkCtl(par, name, text, width, bg, strokeCol)
		return mk("TextButton", {
			Name = name,
			BackgroundColor3 = bg,
			BorderSizePixel = 0,
			Size = UDim2.new(0, width, 0, 34),
			Text = text,
			TextColor3 = col.tx,
			Font = Enum.Font.GothamBold,
			TextSize = 13,
			Parent = par,
			ZIndex = 54,
		}, {
			mk("UICorner", {
				CornerRadius = UDim.new(0, 9),
			}),
			mk("UIStroke", {
				Color = strokeCol or bg:Lerp(Color3.new(1, 1, 1), 0.12),
				Transparency = 0.45,
			}),
		})
	end

	local function mkSlider(parent, y, titleText, accent, defaultScale)
		local title = mk("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 16, 0, y),
			Size = UDim2.new(1, -32, 0, 16),
			Text = titleText,
			TextColor3 = col.td,
			Font = Enum.Font.GothamSemibold,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = parent,
			ZIndex = 54,
		})
		local bar = mk("Frame", {
			BackgroundColor3 = Color3.fromRGB(43, 47, 58),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 16, 0, y + 24),
			Size = UDim2.new(1, -32, 0, 10),
			Parent = parent,
			ZIndex = 54,
		}, {
			mk("UICorner", {
				CornerRadius = UDim.new(0, 999),
			}),
		})
		local fill = mk("Frame", {
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Size = UDim2.new(defaultScale or 0, 0, 1, 0),
			Parent = bar,
			ZIndex = 55,
		}, {
			mk("UICorner", {
				CornerRadius = UDim.new(0, 999),
			}),
		})
		local knob = mk("Frame", {
			BackgroundColor3 = Color3.fromRGB(245, 247, 250),
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(defaultScale or 0, 0, 0.5, 0),
			Size = UDim2.new(0, 14, 0, 14),
			Parent = bar,
			ZIndex = 56,
		}, {
			mk("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			mk("UIStroke", {
				Color = accent,
				Transparency = 0.35,
			}),
		})
		return title, bar, fill, knob
	end

	local hero = mkPanel(
		"Hero",
		UDim2.new(0, 0, 0, 0),
		UDim2.new(1, 0, 0, 118),
		Color3.fromRGB(18, 22, 31),
		Color3.fromRGB(62, 72, 92),
		51
	)
	hero.ClipsDescendants = true
	local heroGrad = Instance.new("UIGradient")
	heroGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 21, 31)),
		ColorSequenceKeypoint.new(0.52, Color3.fromRGB(23, 29, 44)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 14, 21)),
	})
	heroGrad.Rotation = 12
	heroGrad.Parent = hero

	mk("Frame", {
		Name = "OrbA",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, -18),
		Size = UDim2.new(0, 96, 0, 96),
		BackgroundColor3 = Color3.fromRGB(79, 164, 242),
		BackgroundTransparency = 0.8,
		BorderSizePixel = 0,
		Parent = hero,
		ZIndex = 51,
	}, {
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	mk("Frame", {
		Name = "OrbB",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, -10, 1, 18),
		Size = UDim2.new(0, 72, 0, 72),
		BackgroundColor3 = Color3.fromRGB(52, 211, 153),
		BackgroundTransparency = 0.86,
		BorderSizePixel = 0,
		Parent = hero,
		ZIndex = 51,
	}, {
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local heroTag = mk("TextLabel", {
		BackgroundColor3 = Color3.fromRGB(32, 45, 71),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 16, 0, 14),
		Size = UDim2.new(0, 118, 0, 20),
		Text = "CUSTOM PLAYER",
		TextColor3 = Color3.fromRGB(223, 238, 255),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		Parent = hero,
		ZIndex = 53,
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 999) }),
	})

	local mt = mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 47),
		Size = UDim2.new(1, -146, 0, 28),
		Text = "Music Studio",
		TextColor3 = col.tx,
		Font = Enum.Font.GothamBold,
		TextSize = 24,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = hero,
		ZIndex = 53,
	})

	local heroStatus = mk("TextLabel", {
		Name = "HeroStatus",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 14),
		Size = UDim2.new(0, 108, 0, 24),
		BackgroundColor3 = Color3.fromRGB(28, 32, 42),
		BorderSizePixel = 0,
		Text = "IDLE",
		TextColor3 = Color3.fromRGB(199, 208, 221),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		Parent = hero,
		ZIndex = 53,
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 999) }),
		mk("UIStroke", {
			Color = Color3.fromRGB(70, 75, 85),
			Transparency = 0.35,
		}),
	})

	local assetChip = mk("TextLabel", {
		Name = "AssetChip",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 46),
		Size = UDim2.new(0, 126, 0, 20),
		BackgroundColor3 = Color3.fromRGB(22, 26, 35),
		BorderSizePixel = 0,
		Text = "No asset",
		TextColor3 = Color3.fromRGB(151, 160, 176),
		Font = Enum.Font.GothamSemibold,
		TextSize = 10,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = hero,
		ZIndex = 53,
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 999) }),
	})

	local inputCard = mkPanel("InputCard", UDim2.new(0, 0, 0, 132), UDim2.new(1, 0, 0, 78), col.bg2, col.st, 51)
	local inputTitle = mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 10),
		Size = UDim2.new(1, -32, 0, 14),
		Text = "Load audio",
		TextColor3 = col.tx,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = inputCard,
		ZIndex = 53,
	})

	local mb = mk("TextBox", {
		Name = "IdBox",
		BackgroundColor3 = col.bg,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -156, 0, 40),
		Position = UDim2.new(0, 16, 0, 28),
		ClearTextOnFocus = false,
		Text = "",
		PlaceholderText = "Asset id, full URL, or rbxassetid://id",
		TextColor3 = col.tx,
		PlaceholderColor3 = col.td,
		TextXAlignment = Enum.TextXAlignment.Left,
		Font = Enum.Font.Gotham,
		TextSize = 14,
		Parent = inputCard,
		ZIndex = 53,
	}, {
		mk("UIPadding", {
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
		}),
		mk("UICorner", {
			CornerRadius = UDim.new(0, 10),
		}),
		mk("UIStroke", {
			Color = col.st,
			Transparency = 0.28,
		}),
	})

	local loadb = mkCtl(inputCard, "Load", "Load Track", 124, col.ac, Color3.fromRGB(116, 192, 255))
	loadb.Position = UDim2.new(1, -140, 0, 28)
	loadb.ZIndex = 53

	local controlCard = mkPanel("ControlCard", UDim2.new(0, 0, 0, 224), UDim2.new(1, 0, 0, 158), col.bg2, col.st, 51)
	local controlLabel = mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 12),
		Size = UDim2.new(1, -32, 0, 14),
		Text = "Playback",
		TextColor3 = col.tx,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = controlCard,
		ZIndex = 53,
	})

	local now = mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 32),
		Size = UDim2.new(1, -152, 0, 24),
		Text = "No track loaded",
		TextColor3 = col.tx,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = controlCard,
		ZIndex = 53,
	})

	local stat = mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 56),
		Size = UDim2.new(1, -32, 0, 18),
		Text = "Stopped",
		TextColor3 = col.td,
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = controlCard,
		ZIndex = 53,
	})

	local row = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 82),
		Size = UDim2.new(1, -32, 0, 34),
		Parent = controlCard,
		ZIndex = 53,
	}, {
		mk("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})

	local playb = mkCtl(row, "Play", "Play", 92, col.su, Color3.fromRGB(103, 233, 186))
	local pauseb = mkCtl(row, "Pause", "Pause", 92, Color3.fromRGB(57, 63, 75), Color3.fromRGB(105, 115, 133))
	local stopb = mkCtl(row, "Stop", "Stop", 92, Color3.fromRGB(80, 40, 40), Color3.fromRGB(132, 74, 74))
	local loopb = mkCtl(row, "Loop", "Loop Off", 112, Color3.fromRGB(45, 50, 61), Color3.fromRGB(94, 105, 121))

	local progressInfo = mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 124),
		Size = UDim2.new(1, -32, 0, 14),
		Text = "00:00 / 00:00",
		TextColor3 = Color3.fromRGB(142, 151, 166),
		Font = Enum.Font.GothamSemibold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = controlCard,
		ZIndex = 53,
	})

	local pbar = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(41, 45, 56),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 16, 0, 142),
		Size = UDim2.new(1, -32, 0, 8),
		Parent = controlCard,
		ZIndex = 54,
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 999) }),
	})

	local pfill = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(79, 164, 242),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = pbar,
		ZIndex = 55,
	}, {
		mk("UICorner", { CornerRadius = UDim.new(0, 999) }),
	})

	local pkn = mk("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 12, 0, 12),
		Parent = pbar,
		ZIndex = 56,
	}, {
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }),
		mk("UIStroke", {
			Color = Color3.fromRGB(79, 164, 242),
			Transparency = 0.35,
		}),
	})

	local mixCard = mkPanel("MixCard", UDim2.new(0, 0, 0, 396), UDim2.new(1, 0, 0, 138), col.bg2, col.st, 51)
	local mixTitle = mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 0, 12),
		Size = UDim2.new(1, -32, 0, 14),
		Text = "Mixer",
		TextColor3 = col.tx,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = mixCard,
		ZIndex = 53,
	})

	local vt, vbar, vfill, vkn = mkSlider(mixCard, 34, "Volume", col.ac, 0.5)
	local spLabel, sbar, sfill, skn = mkSlider(mixCard, 84, "Playback speed", Color3.fromRGB(52, 211, 153), 0.333333)

	local helper = mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 16, 1, -18),
		Size = UDim2.new(1, -32, 0, 14),
		Text = "Seek tracks with the progress bar. Volume and speed apply live.",
		TextColor3 = Color3.fromRGB(124, 132, 145),
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = mixCard,
		ZIndex = 53,
	})

	local vl = 0.5
	local spd = 1
	local function formatTime(sec)
		sec = tonumber(sec) or 0
		if sec < 0 or sec ~= sec or sec == math.huge then
			sec = 0
		end
		local total = math.floor(sec + 0.5)
		local m = math.floor(total / 60)
		local s = total % 60
		return string.format("%02d:%02d", m, s)
	end

	local function setStatusText(text, accent)
		stat.Text = text
		heroStatus.Text = string.upper(text)
		if accent then
			heroStatus.BackgroundColor3 = accent
			heroStatus.TextColor3 = Color3.fromRGB(245, 247, 250)
		else
			heroStatus.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
			heroStatus.TextColor3 = Color3.fromRGB(199, 208, 221)
		end
	end

	local function setProgress(alpha, pos, len)
		alpha = math.clamp(alpha or 0, 0, 1)
		pfill.Size = UDim2.new(alpha, 0, 1, 0)
		pkn.Position = UDim2.new(alpha, 0, 0.5, 0)
		progressInfo.Text = string.format("%s / %s", formatTime(pos or 0), formatTime(len or 0))
	end

	local function syncLoopButton()
		local on = st.snd and st.snd.Looped
		loopb.Text = on and "Loop On" or "Loop Off"
		loopb.BackgroundColor3 = on and Color3.fromRGB(45, 93, 73) or Color3.fromRGB(45, 50, 61)
	end

	local function apVol(v)
		vl = math.clamp(v, 0, 1)
		vfill.Size = UDim2.new(vl, 0, 1, 0)
		vkn.Position = UDim2.new(vl, 0, 0.5, 0)
		vt.Text = string.format("Volume  %.2f", vl)
		if st.snd then
			st.snd.Volume = vl
		end
	end

	local function apSpeed(v)
		spd = math.clamp(v, 0.5, 2)
		local alpha = (spd - 0.5) / 1.5
		sfill.Size = UDim2.new(alpha, 0, 1, 0)
		skn.Position = UDim2.new(alpha, 0, 0.5, 0)
		spLabel.Text = string.format("Playback speed  %.2fx", spd)
		if st.snd then
			st.snd.PlaybackSpeed = spd
		end
	end

	apVol(0.5)
	apSpeed(1)
	setStatusText("Stopped")
	setProgress(0, 0, 0)

	local dragging = false
	local speedDragging = false
	local progressDragging = false

	local function setBar(inp)
		local x = (inp.Position.X - vbar.AbsolutePosition.X) / math.max(vbar.AbsoluteSize.X, 1)
		apVol(x)
	end

	local function setSpeedBar(inp)
		local x = (inp.Position.X - sbar.AbsolutePosition.X) / math.max(sbar.AbsoluteSize.X, 1)
		apSpeed(0.5 + math.clamp(x, 0, 1) * 1.5)
	end

	local function setProgressBar(inp)
		if not (st.snd and st.snd.TimeLength and st.snd.TimeLength > 0) then
			return
		end
		local x = (inp.Position.X - pbar.AbsolutePosition.X) / math.max(pbar.AbsoluteSize.X, 1)
		x = math.clamp(x, 0, 1)
		local len = st.snd.TimeLength
		local pos = len * x
		pcall(function()
			st.snd.TimePosition = pos
		end)
		setProgress(x, pos, len)
	end

	con(vbar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setBar(inp)
		end
	end))

	con(sbar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			speedDragging = true
			setSpeedBar(inp)
		end
	end))

	con(pbar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			progressDragging = true
			setProgressBar(inp)
		end
	end))

	con(UIS.InputChanged:Connect(function(inp)
		if
			dragging
			and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch)
		then
			setBar(inp)
		end
		if
			speedDragging
			and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch)
		then
			setSpeedBar(inp)
		end
		if
			progressDragging
			and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch)
		then
			setProgressBar(inp)
		end
	end))

	con(UIS.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			speedDragging = false
			progressDragging = false
		end
	end))

	if RS then
		con(RS.Heartbeat:Connect(function()
			local snd = st.snd
			if not snd then
				return
			end
			local len = snd.TimeLength or 0
			local pos = snd.TimePosition or 0
			local alpha = 0
			if len > 0 then
				alpha = math.clamp(pos / len, 0, 1)
			end
			if not progressDragging then
				setProgress(alpha, pos, len)
			end
		end))
	end

	local function getId(t)
		t = trim(t)
		if t == "" then
			return nil
		end
		local n = t:match("^rbxassetid://(%d+)$") or t:match("id=(%d+)") or t:match("^(%d+)$")
		if n then
			return "rbxassetid://" .. n, n
		end
		return t, t
	end

	local function mkSnd(id, raw)
		if st.snd then
			pcall(function()
				st.snd:Destroy()
			end)
		end
		local s = Instance.new("Sound")
		s.Name = "LT_MusicSound"
		s.SoundId = id
		s.Volume = vl
		s.Looped = false
		s.PlaybackSpeed = spd
		s.Parent = SS or workspace
		st.snd = s
		now.Text = tostring(raw)
		assetChip.Text = tostring(raw)
		setStatusText("Loaded", Color3.fromRGB(53, 83, 125))
		setProgress(0, 0, 0)
		syncLoopButton()
		con(s.Loaded:Connect(function()
			setStatusText("Loaded", Color3.fromRGB(53, 83, 125))
			setProgress(0, s.TimePosition or 0, s.TimeLength or 0)
		end))
		con(s.Ended:Connect(function()
			setStatusText("Ended", Color3.fromRGB(88, 64, 48))
		end))
		con(s.Played:Connect(function()
			setStatusText("Playing", Color3.fromRGB(52, 211, 153))
		end))
		con(s.Paused:Connect(function()
			setStatusText("Paused", Color3.fromRGB(92, 105, 123))
		end))
		con(s.Stopped:Connect(function()
			setStatusText("Stopped")
			setProgress(0, 0, s.TimeLength or 0)
		end))
	end

	local function loadCurrentTrack()
		local sid, raw = getId(mb.Text)
		if not sid then
			toast("Music", "Enter a valid asset id.")
			return false
		end
		mkSnd(sid, raw)
		toast("Music", "Loaded audio.")
		return true
	end

	con(loadb.MouseButton1Click:Connect(loadCurrentTrack))

	con(mb.FocusLost:Connect(function(enter)
		if enter then
			loadCurrentTrack()
		end
	end))

	con(playb.MouseButton1Click:Connect(function()
		if st.snd then
			pcall(function()
				st.snd:Play()
			end)
		end
	end))

	con(pauseb.MouseButton1Click:Connect(function()
		if st.snd then
			pcall(function()
				st.snd:Pause()
			end)
		end
	end))

	con(stopb.MouseButton1Click:Connect(function()
		if st.snd then
			pcall(function()
				st.snd:Stop()
			end)
		end
	end))

	con(loopb.MouseButton1Click:Connect(function()
		if not st.snd then
			return
		end
		st.snd.Looped = not st.snd.Looped
		syncLoopButton()
	end))
end

buildMusicTab()

local MUSIC_BTN_SHEET_URL = "https://raw.githubusercontent.com/ltseverydayyou/Nameless-Admin/main/NAimages/sheet.png"
local MUSIC_BTN_SHEET_ASSET = downloadImageAsset(MUSIC_BTN_SHEET_URL)
local MUSIC_BTN_RECT_OFFSET = Vector2.new(371, 806)
local MUSIC_BTN_RECT_SIZE = Vector2.new(23, 33)

musb = gbtn("Music")
if musb then
	pcall(function()
		musb:Destroy()
	end)
end

local src = conBtn or shBtn or homeBtn or setBtn or exBtn
if src then
	musb = src:Clone()
	musb.Name = "Music"
	musb.Parent = src.Parent
	local tl = txtOf(musb)
	if tl then
		tl.Text = "Music"
	end
	pcall(function()
		if togBtn and togBtn:IsA("GuiButton") then
			local to = togBtn.LayoutOrder or 999
			for _, d in ipairs(sb:GetChildren()) do
				if d:IsA("GuiButton") and d ~= musb and d.LayoutOrder and d.LayoutOrder >= to then
					d.LayoutOrder += 1
				end
			end
			musb.LayoutOrder = to
		else
			local lo = 0
			for _, d in ipairs(sb:GetChildren()) do
				if d:IsA("GuiButton") and d ~= musb then
					lo = math.max(lo, d.LayoutOrder or 0)
				end
			end
			musb.LayoutOrder = lo + 1
		end
	end)
	local img = imgOf(musb)
	if img then
		pcall(function()
			if MUSIC_BTN_SHEET_ASSET then
				img.Image = MUSIC_BTN_SHEET_ASSET
				img.ImageRectOffset = MUSIC_BTN_RECT_OFFSET
				img.ImageRectSize = MUSIC_BTN_RECT_SIZE
				img.ScaleType = Enum.ScaleType.Fit
			end
			img.ImageColor3 = offImg
		end)
	end
	pcall(function()
		musb.BackgroundColor3 = bgOff()
	end)
end

local function placeMusicBtn()
	if not (musb and togBtn and musb.Parent == togBtn.Parent) then
		return
	end
	pcall(function()
		if togBtn:GetAttribute("LT_OrigPosXS") == nil then
			togBtn:SetAttribute("LT_OrigPosXS", togBtn.Position.X.Scale)
			togBtn:SetAttribute("LT_OrigPosXO", togBtn.Position.X.Offset)
			togBtn:SetAttribute("LT_OrigPosYS", togBtn.Position.Y.Scale)
			togBtn:SetAttribute("LT_OrigPosYO", togBtn.Position.Y.Offset)
			togBtn:SetAttribute("LT_OrigLay", togBtn.LayoutOrder or 0)
		end
		local op = UDim2.new(
			togBtn:GetAttribute("LT_OrigPosXS") or togBtn.Position.X.Scale,
			togBtn:GetAttribute("LT_OrigPosXO") or togBtn.Position.X.Offset,
			togBtn:GetAttribute("LT_OrigPosYS") or togBtn.Position.Y.Scale,
			togBtn:GetAttribute("LT_OrigPosYO") or togBtn.Position.Y.Offset
		)
		togBtn.Position = op
		local togLo = togBtn:GetAttribute("LT_OrigLay") or togBtn.LayoutOrder or 0
		togBtn.LayoutOrder = togLo
		local above
		local ay = -math.huge
		local ty = op.Y.Scale + op.Y.Offset / 100000
		for _, d in ipairs(togBtn.Parent:GetChildren()) do
			if d:IsA("GuiButton") and d ~= togBtn and d ~= musb then
				local py = d.Position.Y.Scale + d.Position.Y.Offset / 100000
				if py < ty and py > ay then
					ay = py
					above = d
				end
			end
		end
		local gapS = 0.11
		local gapO = 0
		if above then
			gapS = op.Y.Scale - above.Position.Y.Scale
			gapO = op.Y.Offset - above.Position.Y.Offset
		end
		musb.Position = op
		musb.LayoutOrder = togLo - 1
		togBtn.Position = UDim2.new(op.X.Scale, op.X.Offset, op.Y.Scale + gapS, op.Y.Offset + gapO)
		togBtn.LayoutOrder = togLo + 1
	end)
end

placeMusicBtn()

local function bindHide(b, nm)
	improveSidebarTouch(b)
	if b and b:IsA("GuiButton") then
		con(b.MouseButton1Click:Connect(function()
			closeMusic(true)
			task.defer(function()
				syncTabColors(nm or b.Name)
			end)
		end))
	end
end

bindHide(homeBtn, "Home")
bindHide(shBtn, "Scripthub")
bindHide(setBtn, "Settings")
bindHide(exBtn, "Executor")
bindHide(conBtn, "Console")

improveSidebarTouch(musb)
if musb and musb:IsA("GuiButton") then
	con(musb.MouseButton1Click:Connect(function()
		openMusic()
		task.defer(function()
			syncTabColors("Music")
		end)
	end))
end

for _, n in ipairs(sec) do
	local p = gui:FindFirstChild(n)
	if p and p:IsA("GuiObject") and p.GetPropertyChangedSignal then
		con(p:GetPropertyChangedSignal("Visible"):Connect(function()
			task.defer(syncTabColors)
		end))
	end
end

if acv and acv.Changed then
	con(acv.Changed:Connect(function()
		task.defer(syncTabColors)
	end))
end

if icv and icv.Changed then
	con(icv.Changed:Connect(function()
		task.defer(syncTabColors)
	end))
end

task.defer(syncTabColors)

local _dta = (getgenv and getgenv()) or _G
if type(_dta) == "table" and not _dta.__DeltaThemeMenuPatchLoaded then
	_dta.__DeltaThemeMenuPatchLoaded = true
	task.defer(function()
		if (identifyexecutor and identifyexecutor() or ""):lower() ~= "delta" then
			return
		end

		local function S(n)
			local ok, s = pcall(function()
				return __lt.cs(n, cloneref and cloneref or function(v)
					return v
				end)
			end)
			if ok then
				return s
			end
		end

		local HS = S("HttpService")
		local CG = S("CoreGui")
		local root = gethui and gethui() or CG
		if not root then
			return
		end

		local function isGib(n)
			if typeof(n) ~= "string" or n == "" then
				return false
			end
			return not n:match("^[%w _%-]+$")
		end

		local function getMain()
			for _, g in ipairs(root:GetChildren()) do
				if g:IsA("ScreenGui") and isGib(g.Name) then
					if
						g:FindFirstChild("Executor", true)
						and g:FindFirstChild("Scripthub", true)
						and g:FindFirstChild("Sidebar", true)
					then
						return g
					end
				end
			end
		end

		local mainGui = getMain()
		if not mainGui then
			return
		end

		local settingsPath = "DeltaCustom/Settings.json"
		local cfg = {}
		if HS and type(isfile) == "function" and type(readfile) == "function" and isfile(settingsPath) then
			local ok, data = pcall(readfile, settingsPath)
			if ok and type(data) == "string" and data ~= "" then
				local ok2, dec = pcall(function()
					return __lt.cm("HttpService", "JSONDecode", data)
				end)
				if ok2 and type(dec) == "table" then
					cfg = dec
				end
			end
		end

		local function saveCfg(k, v)
			if not (HS and type(writefile) == "function") then
				return
			end
			cfg[k] = v
			local ok, enc = pcall(function()
				return __lt.cm("HttpService", "JSONEncode", cfg)
			end)
			if ok and enc then
				pcall(writefile, settingsPath, enc)
			end
		end

		local base = {
			bg = {},
			txt = {},
			st = {},
			img = {},
			got = false,
		}

		local function isAccent(c)
			local h, s, v = Color3.toHSV(c)
			return s >= 0.35 and v >= 0.25 and h >= 0.50 and h <= 0.68
		end

		local function capBase()
			if base.got then
				return
			end
			for _, o in ipairs(mainGui:GetDescendants()) do
				if
					o:IsA("Frame")
					or o:IsA("ImageButton")
					or o:IsA("TextButton")
					or o:IsA("TextBox")
					or o:IsA("ScrollingFrame")
					or o:IsA("ImageLabel")
				then
					base.bg[o] = o.BackgroundColor3
				end
				if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
					base.txt[o] = o.TextColor3
				end
				if o:IsA("UIStroke") then
					base.st[o] = o.Color
				end
				if o:IsA("ImageLabel") or o:IsA("ImageButton") then
					base.img[o] = o.ImageColor3
				end
			end
			base.got = true
		end

		local execRoot = mainGui:FindFirstChild("Executor")
		local function inExec(o)
			return execRoot and o and o.Parent and o:IsDescendantOf(execRoot)
		end

		local function lightBgFor(o)
			local n = (o.Name or ""):lower()
			local big = false
			pcall(function()
				local s = o.AbsoluteSize
				big = s.X >= 180 or s.Y >= 60
			end)
			if n:find("sidebar") then
				return Color3.fromRGB(214, 214, 214)
			end
			if
				n:find("overlay")
				or n:find("settings")
				or n:find("console")
				or n:find("home")
				or n:find("scripthub")
				or n:find("music")
			then
				return Color3.fromRGB(220, 220, 220)
			end
			if n:find("dropdown") or big then
				return Color3.fromRGB(216, 216, 216)
			end
			if
				n:find("button")
				or n:find("card")
				or n:find("script")
				or n:find("search")
				or n:find("top")
				or n:find("bottom")
				or n:find("list")
			then
				return Color3.fromRGB(210, 210, 210)
			end
			return Color3.fromRGB(215, 215, 215)
		end

		local function amoledBgFor(o)
			local n = (o.Name or ""):lower()
			local big = false
			pcall(function()
				local s = o.AbsoluteSize
				big = s.X >= 180 or s.Y >= 60
			end)
			if n:find("sidebar") then
				return Color3.fromRGB(5, 5, 7)
			end
			if
				n:find("overlay")
				or n:find("settings")
				or n:find("console")
				or n:find("home")
				or n:find("scripthub")
				or n:find("music")
			then
				return Color3.fromRGB(0, 0, 0)
			end
			if n:find("dropdown") or big then
				return Color3.fromRGB(4, 4, 5)
			end
			if
				n:find("button")
				or n:find("card")
				or n:find("script")
				or n:find("search")
				or n:find("top")
				or n:find("bottom")
				or n:find("list")
			then
				return Color3.fromRGB(10, 10, 12)
			end
			return Color3.fromRGB(8, 8, 10)
		end

		local function lightTxtFor(o, c)
			if isAccent(c) then
				return c
			end
			local n = (o.Name or ""):lower()
			if n == "desc" or n:find("placeholder") then
				return Color3.fromRGB(102, 112, 130)
			end
			return Color3.fromRGB(32, 39, 52)
		end

		local function amoledTxtFor(o, c)
			if isAccent(c) then
				return c
			end
			local n = (o.Name or ""):lower()
			if n == "desc" or n:find("placeholder") then
				return Color3.fromRGB(137, 144, 155)
			end
			return Color3.fromRGB(245, 247, 250)
		end

		local function lightStrokeFor(c)
			if isAccent(c) then
				return Color3.fromRGB(91, 147, 225)
			end
			return Color3.fromRGB(206, 214, 226)
		end

		local function amoledStrokeFor(c)
			if isAccent(c) then
				return c
			end
			return Color3.fromRGB(24, 24, 28)
		end

		local function lightImgFor(o, c)
			if isAccent(c) then
				return c
			end
			local h, s, v = Color3.toHSV(c)
			local n = (o.Name or ""):lower()
			if n == "checked" then
				return Color3.fromRGB(79, 164, 242)
			end
			if s >= 0.30 then
				return Color3.fromHSV(h, math.clamp(s * 0.65, 0, 1), math.clamp(math.min(v, 0.60) + 0.08, 0, 1))
			end
			if v >= 0.70 then
				return Color3.fromRGB(78, 88, 104)
			end
			return Color3.fromRGB(102, 111, 126)
		end

		local function amoledImgFor(o, c)
			if isAccent(c) then
				return c
			end
			local h, s, v = Color3.toHSV(c)
			local n = (o.Name or ""):lower()
			if n == "checked" then
				return Color3.fromRGB(79, 164, 242)
			end
			if s >= 0.30 then
				return Color3.fromHSV(h, math.clamp(s * 0.75, 0, 1), math.clamp(math.max(v, 0.82), 0, 1))
			end
			if v <= 0.35 then
				return Color3.fromRGB(232, 236, 241)
			end
			return Color3.fromRGB(214, 220, 228)
		end

		local function setBg(o, c)
			if o and o.Parent and c then
				pcall(function()
					o.BackgroundColor3 = c
				end)
			end
		end

		local function setTxt(o, c)
			if o and o.Parent and c and (o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")) then
				pcall(function()
					o.TextColor3 = c
				end)
			end
		end

		local function setStroke(o, c)
			if o and o.Parent and c and o:IsA("UIStroke") then
				pcall(function()
					o.Color = c
				end)
			end
		end

		local function setImg(o, c)
			if o and o.Parent and c and (o:IsA("ImageLabel") or o:IsA("ImageButton")) then
				pcall(function()
					o.ImageColor3 = c
				end)
			end
		end

		local function restoreAll()
			for o, c in pairs(base.bg) do
				if o and o.Parent then
					setBg(o, c)
				end
			end
			for o, c in pairs(base.txt) do
				if o and o.Parent then
					setTxt(o, c)
				end
			end
			for o, c in pairs(base.st) do
				if o and o.Parent then
					setStroke(o, c)
				end
			end
			for o, c in pairs(base.img) do
				if o and o.Parent then
					setImg(o, c)
				end
			end
		end

		local function restoreExec()
			for o, c in pairs(base.bg) do
				if inExec(o) then
					setBg(o, c)
				end
			end
			for o, c in pairs(base.txt) do
				if inExec(o) then
					setTxt(o, c)
				end
			end
			for o, c in pairs(base.st) do
				if inExec(o) then
					setStroke(o, c)
				end
			end
			for o, c in pairs(base.img) do
				if inExec(o) then
					setImg(o, c)
				end
			end
		end

		local function eachDesc(rootObj, fn)
			if not rootObj then
				return
			end
			for _, d in ipairs(rootObj:GetDescendants()) do
				fn(d)
			end
		end

		local function isCustomSettingPart(o)
			if not (o and o.Parent) then
				return false
			end
			local nm = o.Name or ""
			if
				nm == "Dock"
				or nm == "ValueBox"
				or nm == "Slider"
				or nm == "Bar"
				or nm == "Fill"
				or nm == "Knob"
				or nm == "ColorSlider"
				or nm == "ColorValue"
				or nm == "Hue"
				or nm == "Sat"
				or nm == "Val"
			then
				return true
			end
			local p = o.Parent
			while p and p ~= mainGui do
				local pn = p.Name or ""
				if pn == "Dock" or pn == "ColorSlider" or pn == "Slider" then
					return true
				end
				p = p.Parent
			end
			return false
		end

		local function findText(rootObj, nm)
			if not rootObj then
				return
			end
			for _, d in ipairs(rootObj:GetDescendants()) do
				if d:IsA("TextLabel") and d.Name == nm then
					return d
				end
			end
		end

		local function styleCard(card, mainCol, mutedCol, innerCol)
			if not card then
				return
			end
			setBg(card, innerCol)
			eachDesc(card, function(d)
				if d:IsA("TextLabel") then
					local nm = (d.Name or ""):lower()
					if nm == "title" then
						setTxt(d, mainCol)
					elseif nm == "description" or nm == "desc" then
						setTxt(d, mutedCol)
					elseif nm == "memory" or nm == "ping" or nm == "players" then
						setTxt(d, mutedCol)
					end
				elseif d:IsA("TextButton") then
					setBg(d, innerCol)
				end
			end)
		end

		local function syncThemeChecks(themeName)
			local ex = mainGui:FindFirstChild("Executor", true)
			local over = ex and ex:FindFirstChild("Overlay", true)
			local menu = over and over:FindFirstChild("Menu", true)
			local dd = menu and menu:FindFirstChild("Dropdown", true)
			local map = { Option1 = "Default", Option2 = "Light", Option3 = "Amoled" }
			for key, nm in pairs(map) do
				local opt = dd and dd:FindFirstChild(key)
				local chk = opt and opt:FindFirstChild("Checked", true)
				if chk and chk:IsA("GuiObject") then
					pcall(function()
						chk.Visible = nm:lower() == themeName:lower()
					end)
				end
			end
		end

		local function styleExecutorTheme(themeName)
			restoreExec()
			if not execRoot or themeName:lower() == "default" then
				syncThemeChecks(themeName)
				return
			end

			local exImage = execRoot:FindFirstChild("Executor")
			local over = exImage and exImage:FindFirstChild("Overlay")
			local menu = over and over:FindFirstChild("Menu", true)
			local dd = menu and menu:FindFirstChild("Dropdown", true)
			local tabs = over and over:FindFirstChild("Tabs", true)
			local btns = over and over:FindFirstChild("Buttons", true)
			local code = over and over:FindFirstChild("Code", true)
			local side = execRoot:FindFirstChild("Sidemenu", true)
			local net = side and side:FindFirstChild("Network", true)
			local feat = side and side:FindFirstChild("Script", true)

			local p
			if themeName:lower() == "light" then
				p = {
					card = Color3.fromRGB(220, 220, 220),
					card2 = Color3.fromRGB(212, 212, 212),
					main = Color3.fromRGB(29, 36, 49),
					muted = Color3.fromRGB(103, 112, 126),
					tabBar = Color3.fromRGB(223, 223, 223),
					tab = Color3.fromRGB(214, 214, 214),
					tabTxt = Color3.fromRGB(69, 77, 92),
					menu = Color3.fromRGB(218, 218, 218),
					menuIcon = Color3.fromRGB(86, 95, 110),
					drop = Color3.fromRGB(224, 224, 224),
					div = Color3.fromRGB(218, 223, 232),
					stroke = Color3.fromRGB(206, 214, 226),
					accent = Color3.fromRGB(79, 164, 242),
				}
			else
				p = {
					card = Color3.fromRGB(0, 0, 0),
					card2 = Color3.fromRGB(8, 8, 10),
					main = Color3.fromRGB(245, 247, 250),
					muted = Color3.fromRGB(142, 148, 158),
					tabBar = Color3.fromRGB(0, 0, 0),
					tab = Color3.fromRGB(9, 9, 12),
					tabTxt = Color3.fromRGB(232, 236, 241),
					menu = Color3.fromRGB(5, 5, 7),
					menuIcon = Color3.fromRGB(220, 224, 230),
					drop = Color3.fromRGB(7, 7, 9),
					div = Color3.fromRGB(22, 22, 28),
					stroke = Color3.fromRGB(24, 24, 28),
					accent = Color3.fromRGB(79, 164, 242),
				}
			end

			if net then
				setBg(net, p.card)
				local info = net:FindFirstChild("Information", true)
				if info then
					setBg(info, p.card2)
				end
				styleCard(net, p.main, p.muted, p.card)
			end
			if feat then
				setBg(feat, p.card)
				styleCard(feat, p.main, p.muted, p.card)
				local show = feat:FindFirstChild("Showcase", true)
				if show then
					setBg(show, p.card)
					local tt = findText(show, "Title")
					local ds = findText(show, "Description")
					setTxt(tt, p.main)
					setTxt(ds, p.muted)
				end
			end

			eachDesc(execRoot, function(d)
				if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and not isCustomSettingPart(d) then
					local c = base.img[d] or d.ImageColor3
					if themeName:lower() == "light" then
						setImg(d, lightImgFor(d, c))
					else
						setImg(d, amoledImgFor(d, c))
					end
				end
			end)

			if menu then
				setBg(menu, p.menu)
				eachDesc(menu, function(d)
					if
						(d:IsA("ImageButton") or d:IsA("ImageLabel"))
						and d ~= menu
						and not d.Name:match("^Option%d+$")
						and d.Name ~= "Checked"
					then
						setImg(d, p.menuIcon)
					end
				end)
			end
			if dd then
				setBg(dd, p.drop)
				for _, ch in ipairs(dd:GetChildren()) do
					if ch:IsA("Frame") and ch.Name == "Divider" then
						setBg(ch, p.div)
					elseif ch:IsA("ImageButton") and ch.Name:match("^Option%d+$") then
						setBg(ch, p.drop)
						setTxt(findText(ch, "Title"), p.main)
						local ck = ch:FindFirstChild("Checked", true)
						if ck then
							setImg(ck, p.accent)
						end
					end
				end
			end

			if tabs then
				setBg(tabs, p.tabBar)
				eachDesc(tabs, function(d)
					if d:IsA("ImageButton") then
						if d.Name == "AddTab" or d.Name:match("^script%d+%.lua$") then
							setBg(d, p.tab)
						end
						if d ~= tabs and d.Name ~= "AddTab" and not d.Name:match("^script%d+%.lua$") then
							setImg(d, p.menuIcon)
						end
					elseif d:IsA("TextLabel") and d.Name == "Title" then
						setTxt(d, p.tabTxt)
					end
				end)
			end

			if btns then
				eachDesc(btns, function(d)
					if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
						local c = base.txt[d]
						if c then
							setTxt(d, c)
						end
					elseif d:IsA("Frame") or d:IsA("ImageButton") or d:IsA("ImageLabel") then
						local c = base.bg[d]
						if c then
							setBg(d, c)
						end
						local ic = base.img[d]
						if ic then
							setImg(d, ic)
						end
					elseif d:IsA("UIStroke") then
						local c = base.st[d]
						if c then
							setStroke(d, c)
						end
					end
				end)
			end

			if code then
				eachDesc(code, function(d)
					if d:IsA("TextBox") or d:IsA("TextLabel") then
						local c = base.txt[d]
						if c then
							setTxt(d, c)
						end
					elseif d:IsA("Frame") or d:IsA("ImageButton") or d:IsA("ImageLabel") or d:IsA("ScrollingFrame") then
						local c = base.bg[d]
						if c then
							setBg(d, c)
						end
						local ic = base.img[d]
						if ic then
							setImg(d, ic)
						end
					end
				end)
			end

			syncThemeChecks(themeName)
		end

		local function applyTheme(name)
			capBase()
			if not name or name == "" then
				name = "Default"
			end
			curTheme = name
			if name:lower() == "default" then
				restoreAll()
			elseif name:lower() == "light" then
				for o, c in pairs(base.bg) do
					if o and o.Parent and not inExec(o) then
						pcall(function()
							if isCustomSettingPart(o) then
								o.BackgroundColor3 = c
							else
								o.BackgroundColor3 = isAccent(c) and c or lightBgFor(o)
							end
						end)
					end
				end
				for o, c in pairs(base.txt) do
					if o and o.Parent and not inExec(o) then
						pcall(function()
							if isCustomSettingPart(o) then
								o.TextColor3 = c
							else
								o.TextColor3 = lightTxtFor(o, c)
							end
						end)
					end
				end
				for o, c in pairs(base.st) do
					if o and o.Parent and not inExec(o) then
						pcall(function()
							if isCustomSettingPart(o) then
								o.Color = c
							else
								o.Color = lightStrokeFor(c)
							end
						end)
					end
				end
				for _, o in ipairs(mainGui:GetDescendants()) do
					if (o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.Parent and not inExec(o) then
						local c = base.img[o] or o.ImageColor3
						pcall(function()
							if isCustomSettingPart(o) then
								o.ImageColor3 = c
							else
								o.ImageColor3 = lightImgFor(o, c)
							end
						end)
					end
				end
			elseif name:lower() == "amoled" then
				for o, c in pairs(base.bg) do
					if o and o.Parent and not inExec(o) then
						pcall(function()
							if isCustomSettingPart(o) then
								o.BackgroundColor3 = c
							else
								o.BackgroundColor3 = isAccent(c) and c or amoledBgFor(o)
							end
						end)
					end
				end
				for o, c in pairs(base.txt) do
					if o and o.Parent and not inExec(o) then
						pcall(function()
							if isCustomSettingPart(o) then
								o.TextColor3 = c
							else
								o.TextColor3 = amoledTxtFor(o, c)
							end
						end)
					end
				end
				for o, c in pairs(base.st) do
					if o and o.Parent and not inExec(o) then
						pcall(function()
							if isCustomSettingPart(o) then
								o.Color = c
							else
								o.Color = amoledStrokeFor(c)
							end
						end)
					end
				end
				for _, o in ipairs(mainGui:GetDescendants()) do
					if (o:IsA("ImageLabel") or o:IsA("ImageButton")) and o.Parent and not inExec(o) then
						local c = base.img[o] or o.ImageColor3
						pcall(function()
							if isCustomSettingPart(o) then
								o.ImageColor3 = c
							else
								o.ImageColor3 = amoledImgFor(o, c)
							end
						end)
					end
				end
			end
			styleExecutorTheme(name)
			saveCfg("DeltaTheme", { name = name })
		end

		local function trim(s)
			if type(s) ~= "string" then
				return ""
			end
			return (s:gsub("^%s+", ""):gsub("%s+$", ""))
		end

		local function findThemeButtons()
			local ex = mainGui:FindFirstChild("Executor", true)
			local over = ex and ex:FindFirstChild("Overlay", true)
			local menu = over and over:FindFirstChild("Menu", true)
			local dd = menu and menu:FindFirstChild("Dropdown", true)
			if not (dd and dd:IsA("GuiObject")) then
				return
			end
			local out = {}
			for _, o in ipairs(dd:GetChildren()) do
				if o:IsA("ImageButton") and o.Name:match("^Option%d+$") then
					local txt = ""
					for _, d in ipairs(o:GetDescendants()) do
						if d:IsA("TextLabel") and trim(d.Text or "") ~= "" then
							txt = trim(d.Text)
							break
						end
					end
					if txt == "" then
						local map = { Option1 = "Default", Option2 = "Light", Option3 = "Amoled" }
						txt = map[o.Name] or o.Name
					end
					out[#out + 1] = { btn = o, name = txt }
				end
			end
			return dd, out
		end

		local dd, opts = findThemeButtons()
		if not dd or not opts or #opts == 0 then
			return
		end

		local curTheme = "Default"
		local hooked = {}
		local function bindOpt(b, name)
			if hooked[b] then
				return
			end
			hooked[b] = true
			b.MouseButton1Click:Connect(function()
				applyTheme(name)
			end)
		end
		for _, v in ipairs(opts) do
			bindOpt(v.btn, v.name)
		end

		local themeReapplyPending = false
		mainGui.DescendantAdded:Connect(function(o)
			task.defer(function()
				if not (o and o.Parent) then
					return
				end
				if o:IsA("ImageButton") and o.Name:match("^Option%d+$") then
					local p = o.Parent
					if p and p.Name == "Dropdown" and p:FindFirstAncestor("Menu") then
						local txt = ""
						for _, d in ipairs(o:GetDescendants()) do
							if d:IsA("TextLabel") and trim(d.Text or "") ~= "" then
								txt = trim(d.Text)
								break
							end
						end
						if txt == "" then
							local map = { Option1 = "Default", Option2 = "Light", Option3 = "Amoled" }
							txt = map[o.Name] or o.Name
						end
						bindOpt(o, txt)
					end
				end
				if curTheme and curTheme:lower() ~= "default" then
					if not themeReapplyPending then
						themeReapplyPending = true
						task.delay(0.05, function()
							themeReapplyPending = false
							applyTheme(curTheme)
						end)
					end
				end
			end)
		end)

		if type(cfg.DeltaTheme) == "table" and type(cfg.DeltaTheme.name) == "string" and cfg.DeltaTheme.name ~= "" then
			curTheme = cfg.DeltaTheme.name
		end
		task.defer(function()
			applyTheme(curTheme)
		end)
	end)
end
