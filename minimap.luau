local genv = (getgenv and getgenv()) or _G or {}
local sh = rawget(_G, "shared")
local host = type(sh) == "table" and sh or (type(genv) == "table" and genv or nil)

local rsv = (function()
	if host then
		local old = rawget(host, "__lt_service_resolver")
		if type(old) == "table" then
			return old
		end
	end
	local ld = loadstring or load
	if type(ld) ~= "function" then
		error("Service resolver loader unavailable")
	end
	local ch = ld(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau")
	if type(ch) ~= "function" then
		error("Service resolver failed to compile")
	end
	local out = ch()
	if type(out) ~= "table" then
		error("Service resolver failed to load")
	end
	if host then
		host.__lt_service_resolver = out
	end
	return out
end)()

local Plrs = rsv.cs("Players", cloneref)
local Ws = rsv.cs("Workspace", cloneref)
local Run = rsv.cs("RunService", cloneref)
local Tween = rsv.cs("TweenService", cloneref)
local Input = rsv.cs("UserInputService", cloneref)
local Http = rsv.cs("HttpService", cloneref)

local key = "__lt_minimap_state"
if host and type(rawget(host, key)) == "table" then
	local old = rawget(host, key)
	if type(old.destroy) == "function" then
		pcall(old.destroy)
	end
	host[key] = nil
end

local plr = Plrs.LocalPlayer
local dead = false
local maid = {}
local parts = {}
local dyn = {}
local rigs = {}
local you = nil
local btns = {}
local ign = {}
local camOk = false
local btnOpen = false
local visTok = 0
local scanT = 0
local rigT = 0
local lastPos
local lastRad = -1
local lastQual = ""
local gui
local box
local vp
local wm
local mapRoot
local rigRoot
local youRoot
local cam
local lightPart
local youTag

local defs = {
	pos = {0.95, 0, 0.05, 0},
	size = {220, 220},
	rad = 120,
	zd = 35,
	zh = 30,
	hoff = 3,
	ray = true,
	top = false,
	tp = false,
	render = true,
	qual = "Auto"
}

local cfg = {}
for k, v in pairs(defs) do
	if type(v) == "table" then
		local t = {}
		for i = 1, #v do
			t[i] = v[i]
		end
		cfg[k] = t
	else
		cfg[k] = v
	end
end

local qset = {
	Low = {scan = 0.34, max = 180, qry = 260, sz = 1.7, move = 11, rigs = 8},
	Med = {scan = 0.24, max = 320, qry = 460, sz = 1.15, move = 8, rigs = 12},
	High = {scan = 0.17, max = 520, qry = 760, sz = 0.75, move = 6, rigs = 18},
	Ultra = {scan = 0.12, max = 760, qry = 1100, sz = 0.45, move = 4, rigs = 24}
}
local qord = {"Auto", "Low", "Med", "High", "Ultra"}
local qix = 1
local perf = {dt = 1 / 60, lag = 0}

local dir = "ltseverydayyou"
local file = dir .. "/minimap_cfg.json"
local saveTok = 0

local function give(v)
	maid[#maid + 1] = v
	return v
end

local function clean()
	for i = #maid, 1, -1 do
		local v = maid[i]
		maid[i] = nil
		if typeof(v) == "RBXScriptConnection" then
			pcall(function()
				v:Disconnect()
			end)
		elseif typeof(v) == "Instance" then
			pcall(function()
				v:Destroy()
			end)
		elseif type(v) == "function" then
			pcall(v)
		elseif type(v) == "table" and type(v.Cancel) == "function" then
			pcall(function()
				v:Cancel()
			end)
		elseif type(v) == "table" and type(v.Destroy) == "function" then
			pcall(function()
				v:Destroy()
			end)
		end
	end
end

local function canFs()
	return type(isfolder) == "function"
		and type(isfile) == "function"
		and type(makefolder) == "function"
		and type(readfile) == "function"
		and type(writefile) == "function"
end

local function fit(v, lo, hi)
	if v < lo then
		return lo
	elseif v > hi then
		return hi
	end
	return v
end

local function loadCfg()
	local raw
	if canFs() then
		pcall(function()
			if not isfolder(dir) then
				makefolder(dir)
			end
			if isfile(file) then
				raw = readfile(file)
			end
		end)
	elseif host and type(rawget(host, "__lt_minimap_cfg")) == "table" then
		raw = Http:JSONEncode(rawget(host, "__lt_minimap_cfg"))
	end
	if type(raw) ~= "string" or raw == "" then
		return
	end
	local ok, data = pcall(function()
		return Http:JSONDecode(raw)
	end)
	if not ok or type(data) ~= "table" then
		return
	end
	if type(data.pos) == "table" and #data.pos >= 4 then
		cfg.pos = {
			tonumber(data.pos[1]) or cfg.pos[1],
			tonumber(data.pos[2]) or cfg.pos[2],
			tonumber(data.pos[3]) or cfg.pos[3],
			tonumber(data.pos[4]) or cfg.pos[4]
		}
	end
	if type(data.size) == "table" and #data.size >= 2 then
		cfg.size = {
			fit(tonumber(data.size[1]) or cfg.size[1], 140, 520),
			fit(tonumber(data.size[2]) or cfg.size[2], 140, 520)
		}
	end
	cfg.rad = fit(tonumber(data.rad) or cfg.rad, 25, 400)
	cfg.zd = fit(tonumber(data.zd) or cfg.zd, 5, 120)
	cfg.zh = fit(tonumber(data.zh) or cfg.zh, 5, 120)
	cfg.hoff = tonumber(data.hoff) or cfg.hoff
	cfg.ray = data.ray == nil and cfg.ray or not not data.ray
	cfg.top = data.top == nil and cfg.top or not not data.top
	cfg.tp = data.tp == nil and cfg.tp or not not data.tp
	cfg.render = data.render == nil and cfg.render or not not data.render
	if type(data.qual) == "string" then
		for i = 1, #qord do
			if qord[i] == data.qual then
				cfg.qual = data.qual
				qix = i
				break
			end
		end
	end
end

local function rawCfg()
	return {
		pos = cfg.pos,
		size = cfg.size,
		rad = cfg.rad,
		zd = cfg.zd,
		zh = cfg.zh,
		hoff = cfg.hoff,
		ray = cfg.ray,
		top = cfg.top,
		tp = cfg.tp,
		render = cfg.render,
		qual = cfg.qual
	}
end

local function saveCfg()
	saveTok = saveTok + 1
	local tok = saveTok
	task.delay(0.1, function()
		if dead or tok ~= saveTok then
			return
		end
		local data = rawCfg()
		if host then
			host.__lt_minimap_cfg = data
		end
		if canFs() then
			pcall(function()
				if not isfolder(dir) then
					makefolder(dir)
				end
				writefile(file, Http:JSONEncode(data))
			end)
		end
	end)
end

loadCfg()

local function getRoot(obj)
	obj = obj or plr.Character
	if not obj then
		return
	end
	local hrp = obj:FindFirstChild("HumanoidRootPart")
	if hrp then
		return hrp
	end
	if obj.PrimaryPart then
		return obj.PrimaryPart
	end
	for _, v in ipairs(obj:GetChildren()) do
		if v:IsA("BasePart") then
			return v
		end
	end
end

local function isChar(obj)
	if not obj then
		return false
	end
	local mdl = obj:IsA("Model") and obj or obj:FindFirstAncestorOfClass("Model")
	return mdl and mdl:FindFirstChildOfClass("Humanoid") ~= nil
end

local function refIgn()
	for k in pairs(ign) do
		ign[k] = nil
	end
	local c = plr.Character
	if not c then
		return
	end
	for _, v in ipairs(c:GetDescendants()) do
		if v:IsA("BasePart") then
			ign[v] = true
		end
	end
end

local function relPath(root, obj)
	local list = {}
	local cur = obj
	while cur and cur ~= root do
		list[#list + 1] = cur.Name
		cur = cur.Parent
	end
	if cur ~= root then
		return
	end
	local out = ""
	for i = #list, 1, -1 do
		if out == "" then
			out = list[i]
		else
			out = out .. "/" .. list[i]
		end
	end
	return out
end

local mapKeep = {
	Decal = true,
	Texture = true,
	SpecialMesh = true,
	BlockMesh = true,
	CylinderMesh = true,
	FileMesh = true,
	SurfaceAppearance = true,
	PointLight = true,
	SpotLight = true,
	SurfaceLight = true,
	Attachment = true
}

local rigKeep = {
	Decal = true,
	Texture = true,
	SpecialMesh = true,
	BlockMesh = true,
	CylinderMesh = true,
	FileMesh = true,
	SurfaceAppearance = true,
	PointLight = true,
	SpotLight = true,
	SurfaceLight = true,
	Attachment = true,
	Accessory = true,
	Humanoid = true,
	Shirt = true,
	Pants = true,
	ShirtGraphic = true,
	BodyColors = true,
	CharacterMesh = true,
	WrapLayer = true,
	WrapTarget = true,
	Motor6D = true,
	Weld = true,
	WeldConstraint = true,
	Bone = true
}

local visDesc = {
	Decal = true,
	Texture = true,
	SpecialMesh = true,
	BlockMesh = true,
	CylinderMesh = true,
	FileMesh = true,
	SurfaceAppearance = true,
	PointLight = true,
	SpotLight = true,
	SurfaceLight = true
}

local function hasVis(part)
	for _, v in ipairs(part:GetChildren()) do
		if visDesc[v.ClassName] then
			return true
		end
		if v:IsA("Attachment") then
			for _, d in ipairs(v:GetChildren()) do
				if visDesc[d.ClassName] then
					return true
				end
			end
		end
	end
	return false
end

local function prepMapPart(part)
	pcall(function()
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part.CastShadow = false
	end)
end

local function prepRigModel(mdl)
	for _, v in ipairs(mdl:GetDescendants()) do
		if v:IsA("BasePart") then
			pcall(function()
				v.Anchored = true
				v.CanCollide = false
				v.CanTouch = false
				v.CanQuery = false
				v.Massless = true
				v.CastShadow = false
			end)
		elseif v:IsA("BaseScript") or v:IsA("Sound") or v:IsA("Animator") or v:IsA("AnimationController") then
			v:Destroy()
		end
	end
end

local function shouldTrack(part, q)
	if not part or not part.Parent then
		return false
	end
	if ign[part] then
		return false
	end
	if isChar(part) then
		return false
	end
	if part.LocalTransparencyModifier and part.LocalTransparencyModifier >= 1 and part.Transparency >= 1 and not hasVis(part) then
		return false
	end
	if part.Transparency >= 1 and not hasVis(part) then
		return false
	end
	if part.Size.Magnitude < q.sz and not hasVis(part) then
		return false
	end
	return true
end

local function syncPart(src, cp, full)
	cp.CFrame = src.CFrame
	if cp.Size ~= src.Size then
		cp.Size = src.Size
	end
	if full then
		if cp.Color ~= src.Color then
			cp.Color = src.Color
		end
		if cp.Material ~= src.Material then
			cp.Material = src.Material
		end
		if cp.Transparency ~= src.Transparency then
			cp.Transparency = src.Transparency
		end
		if cp.Reflectance ~= src.Reflectance then
			cp.Reflectance = src.Reflectance
		end
		if cp:IsA("Part") then
			cp.Shape = src.Shape
		end
	end
end

local function cloneMapPart(src)
	local oldA = src.Archivable
	local okA = pcall(function()
		src.Archivable = true
	end)
	local ok, cp = pcall(function()
		return src:Clone()
	end)
	if okA then
		pcall(function()
			src.Archivable = oldA
		end)
	end
	if not ok or not cp then
		return
	end
	for _, d in ipairs(cp:GetDescendants()) do
		if d ~= cp and not mapKeep[d.ClassName] then
			d:Destroy()
		end
	end
	if cp:IsA("BasePart") then
		prepMapPart(cp)
	end
	cp.Parent = mapRoot
	return cp
end

local function isDyn(src)
	if not src.Parent then
		return false
	end
	if not src.Anchored then
		return true
	end
	local lv = src.AssemblyLinearVelocity
	local av = src.AssemblyAngularVelocity
	if lv.Magnitude > 0.05 or av.Magnitude > 0.05 then
		return true
	end
	return false
end

local function ensurePart(src)
	local it = parts[src]
	if it then
		return it
	end
	local cp = cloneMapPart(src)
	if not cp then
		return
	end
	it = {
		src = src,
		cp = cp,
		keep = true,
		full = 0,
		dyn = false
	}
	parts[src] = it
	syncPart(src, cp, true)
	return it
end

local function killPart(src)
	local it = parts[src]
	if not it then
		return
	end
	if it.cp then
		it.cp:Destroy()
	end
	parts[src] = nil
end

local function distSq(a, b)
	local dx = a.X - b.X
	local dy = a.Y - b.Y
	local dz = a.Z - b.Z
	return dx * dx + dy * dy + dz * dz
end

local function getQ()
	if cfg.qual ~= "Auto" then
		return qset[cfg.qual] or qset.Med
	end
	local fps = 1 / math.max(perf.dt, 1 / 240)
	if fps < 28 or perf.lag > 10 then
		return qset.Low
	elseif fps < 40 or perf.lag > 4 then
		return qset.Med
	elseif fps < 70 then
		return qset.High
	end
	return qset.Ultra
end

local function scanMap(rootPos, q)
	for _, it in pairs(parts) do
		it.keep = false
	end
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Whitelist
	op.FilterDescendantsInstances = {Ws}
	op.MaxParts = q.qry
	local found = Ws:GetPartBoundsInRadius(rootPos, cfg.rad, op)
	if #found > 1 then
		table.sort(found, function(a, b)
			return distSq(a.Position, rootPos) < distSq(b.Position, rootPos)
		end)
	end
	local dn = {}
	local n = 0
	for i = 1, #found do
		local src = found[i]
		if src:IsA("BasePart") and shouldTrack(src, q) then
			local it = ensurePart(src)
			if it then
				n = n + 1
				it.keep = true
				local wasDyn = it.dyn
				it.dyn = isDyn(src)
				if it.dyn then
					it.full = 0
					syncPart(src, it.cp, true)
					dn[#dn + 1] = it
				elseif wasDyn or it.cp.CFrame ~= src.CFrame or it.cp.Size ~= src.Size or it.cp.Transparency ~= src.Transparency then
					syncPart(src, it.cp, true)
				end
				if n >= q.max then
					break
				end
			end
		end
	end
	local kill = {}
	for src, it in pairs(parts) do
		if not it.keep or not src.Parent then
			kill[#kill + 1] = src
		end
	end
	for i = 1, #kill do
		killPart(kill[i])
	end
	dyn = dn
	lastPos = rootPos
	lastRad = cfg.rad
	lastQual = cfg.qual
end

local function upDyn(now)
	local full = math.floor(now * 5)
	local kill
	for i = 1, #dyn do
		local it = dyn[i]
		local src = it.src
		local cp = it.cp
		if not src.Parent or not cp.Parent then
			kill = kill or {}
			kill[#kill + 1] = src
		else
			local isFull = full ~= it.full
			it.full = full
			syncPart(src, cp, isFull)
		end
	end
	if kill then
		for i = 1, #kill do
			killPart(kill[i])
		end
	end
end

local function killRig(tab, src)
	local it = tab[src]
	if not it then
		return
	end
	if it.mdl then
		it.mdl:Destroy()
	end
	tab[src] = nil
end

local function mkRig(src, par, name)
	local oldA = src.Archivable
	local okA = pcall(function()
		src.Archivable = true
	end)
	local ok, cp = pcall(function()
		return src:Clone()
	end)
	if okA then
		pcall(function()
			src.Archivable = oldA
		end)
	end
	if not ok or not cp then
		return
	end
	for _, d in ipairs(cp:GetDescendants()) do
		if d ~= cp and not rigKeep[d.ClassName] and not d:IsA("BasePart") then
			d:Destroy()
		end
	end
	prepRigModel(cp)
	cp.Name = name or src.Name
	cp.Parent = par
	local map = {}
	for _, d in ipairs(cp:GetDescendants()) do
		local path = relPath(cp, d)
		if path then
			map[path] = d
		end
	end
	local refs = {}
	local cnt = 0
	for _, d in ipairs(src:GetDescendants()) do
		if d:IsA("BasePart") then
			local path = relPath(src, d)
			local dst = path and map[path]
			if dst and dst:IsA("BasePart") then
				refs[d] = dst
				cnt = cnt + 1
			end
		end
	end
	return {
		src = src,
		mdl = cp,
		map = refs,
		full = 0,
		cnt = cnt,
		keep = true
	}
end

local function ensureYou()
	local c = plr.Character
	if not c or not c.Parent then
		if you then
			if you.mdl then
				you.mdl:Destroy()
			end
			you = nil
		end
		return
	end
	if you and you.src == c and you.mdl and you.mdl.Parent then
		return you
	end
	if you and you.mdl then
		you.mdl:Destroy()
	end
	you = mkRig(c, youRoot, "You")
	return you
end

local function ensureRig(src, name)
	local it = rigs[src]
	if it and it.mdl and it.mdl.Parent then
		return it
	end
	it = mkRig(src, rigRoot, name)
	if not it then
		return
	end
	rigs[src] = it
	return it
end

local function upRig(it, now)
	if not it or not it.src or not it.src.Parent or not it.mdl or not it.mdl.Parent then
		return false
	end
	local full = math.floor(now * 5)
	local isFull = full ~= it.full
	it.full = full
	local ok = false
	for src, cp in pairs(it.map) do
		if src.Parent and cp.Parent then
			cp.CFrame = src.CFrame
			if cp.Size ~= src.Size then
				cp.Size = src.Size
			end
			if cp.Transparency ~= src.Transparency then
				cp.Transparency = src.Transparency
			end
			if isFull then
				if cp.Color ~= src.Color then
					cp.Color = src.Color
				end
				if cp.Material ~= src.Material then
					cp.Material = src.Material
				end
			end
			ok = true
		end
	end
	return ok
end

local function scanRigs(rootPos, q)
	for _, it in pairs(rigs) do
		it.keep = false
	end
	local list = {}
	for _, op in ipairs(Plrs:GetPlayers()) do
		if op ~= plr then
			local ch = op.Character
			local rp = ch and getRoot(ch)
			if ch and rp and (rp.Position - rootPos).Magnitude <= cfg.rad + 40 then
				list[#list + 1] = {plr = op, ch = ch, d = distSq(rp.Position, rootPos)}
			end
		end
	end
	if #list > 1 then
		table.sort(list, function(a, b)
			return a.d < b.d
		end)
	end
	local lim = q.rigs
	for i = 1, math.min(#list, lim) do
		local info = list[i]
		local it = ensureRig(info.ch, info.plr.DisplayName or info.plr.Name)
		if it then
			it.keep = true
		end
	end
	local kill = {}
	for src, it in pairs(rigs) do
		if not it.keep or not src.Parent then
			kill[#kill + 1] = src
		end
	end
	for i = 1, #kill do
		killRig(rigs, kill[i])
	end
end

local rayP = RaycastParams.new()
rayP.FilterType = Enum.RaycastFilterType.Blacklist
rayP.IgnoreWater = true

local function refRay()
	local c = plr.Character
	if c then
		rayP.FilterDescendantsInstances = {c}
	else
		rayP.FilterDescendantsInstances = {}
	end
end

local pg = gethui and gethui() or plr:FindFirstChildOfClass("PlayerGui") or plr:WaitForChild("PlayerGui")
gui = Instance.new("ScreenGui")
gui.Name = "MiniMapGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = pg
give(gui)

box = Instance.new("Frame")
box.Name = "MiniMapContainer"
box.AnchorPoint = Vector2.new(1, 0)
box.Position = UDim2.new(cfg.pos[1], cfg.pos[2], cfg.pos[3], cfg.pos[4])
box.Size = UDim2.new(0, cfg.size[1], 0, cfg.size[2])
box.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
box.BackgroundTransparency = 0.05
box.BorderSizePixel = 0
box.ClipsDescendants = false
box.Active = true
box.Parent = gui

local cor = Instance.new("UICorner")
cor.CornerRadius = UDim.new(0, 10)
cor.Parent = box

local str = Instance.new("UIStroke")
str.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
str.Thickness = 2
str.Transparency = 0.25
str.Parent = box

vp = Instance.new("ViewportFrame")
vp.Name = "MiniMapViewport"
vp.Size = UDim2.new(1, -8, 1, -32)
vp.Position = UDim2.new(0, 4, 0, 28)
vp.BackgroundTransparency = 1
vp.LightColor = Color3.new(1, 1, 1)
vp.Ambient = Color3.fromRGB(195, 195, 195)
vp.BorderSizePixel = 0
vp.Visible = cfg.render
vp.Parent = box

local asp = Instance.new("UIAspectRatioConstraint")
asp.AspectRatio = 1
asp.Parent = vp

wm = Instance.new("WorldModel")
wm.Parent = vp

mapRoot = Instance.new("Model")
mapRoot.Name = "MapRoot"
mapRoot.Parent = wm

rigRoot = Instance.new("Model")
rigRoot.Name = "RigRoot"
rigRoot.Parent = wm

youRoot = Instance.new("Model")
youRoot.Name = "YouRoot"
youRoot.Parent = wm

cam = Instance.new("Camera")
cam.FieldOfView = 70
cam.Parent = vp
vp.CurrentCamera = cam

lightPart = Instance.new("Part")
lightPart.Size = Vector3.new(1, 1, 1)
lightPart.Transparency = 1
lightPart.Anchored = true
lightPart.CanCollide = false
lightPart.CastShadow = false
lightPart.Parent = wm

local plight = Instance.new("PointLight")
plight.Brightness = 2
plight.Range = 220
plight.Parent = lightPart

youTag = Instance.new("Part")
youTag.Size = Vector3.new(1, 2, 1)
youTag.Anchored = true
youTag.CanCollide = false
youTag.Material = Enum.Material.Neon
youTag.Color = Color3.new(1, 0, 0)
youTag.CastShadow = false
youTag.Parent = wm

local tagMesh = Instance.new("SpecialMesh")
tagMesh.MeshType = Enum.MeshType.Sphere
tagMesh.Scale = Vector3.new(0.42, 0.82, 0.42)
tagMesh.Parent = youTag

local info = Instance.new("TextLabel")
info.Name = "Info"
info.Size = UDim2.new(0.82, 0, 0, 20)
info.Position = UDim2.new(0.02, 0, 1, -22)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.new(1, 1, 1)
info.TextXAlignment = Enum.TextXAlignment.Left
info.Font = Enum.Font.GothamSemibold
info.TextScaled = true
info.Text = "R: " .. cfg.rad .. " | " .. cfg.qual
info.Parent = box

local function style(b)
	b.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamSemibold
	b.TextScaled = true
	b.AutoButtonColor = true
	b.BorderSizePixel = 0
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = b
	local s = Instance.new("UIStroke")
	s.Thickness = 1
	s.Transparency = 0.5
	s.Parent = b
end

local top = Instance.new("Frame")
top.Size = UDim2.new(1, -8, 0, 24)
top.Position = UDim2.new(0, 4, 0, 4)
top.BackgroundTransparency = 1
top.Parent = box

local lay = Instance.new("UIListLayout")
lay.FillDirection = Enum.FillDirection.Horizontal
lay.VerticalAlignment = Enum.VerticalAlignment.Center
lay.HorizontalAlignment = Enum.HorizontalAlignment.Left
lay.Padding = UDim.new(0, 4)
lay.Parent = top

local drag = Instance.new("TextButton")
drag.Size = UDim2.new(0, 24, 1, 0)
drag.Text = "↕"
drag.Parent = top
style(drag)

local menu = Instance.new("TextButton")
menu.Size = UDim2.new(0, 24, 1, 0)
menu.Text = "≡"
menu.Parent = top
style(menu)

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 24, 1, 0)
close.Text = "×"
close.Parent = top
style(close)

local hold = Instance.new("Frame")
hold.BackgroundTransparency = 1
hold.Size = UDim2.new(0, 0, 0, 0)
hold.Position = UDim2.new(1, 0, 0.5, 0)
hold.AnchorPoint = Vector2.new(0, 0.5)
hold.Parent = box

local hlay = Instance.new("UIListLayout")
hlay.FillDirection = Enum.FillDirection.Vertical
hlay.Padding = UDim.new(0, 4)
hlay.HorizontalAlignment = Enum.HorizontalAlignment.Left
hlay.VerticalAlignment = Enum.VerticalAlignment.Center
hlay.Parent = hold

local function refInfo()
	local mode = cfg.top and "Top" or "3D"
	info.Text = "R: " .. cfg.rad .. " | " .. cfg.qual .. " | " .. mode
end

local function setBtns(on)
	if dead or btnOpen == on then
		return
	end
	btnOpen = on
	visTok = visTok + 1
	local tok = visTok
	for i = 1, #btns do
		local b = btns[i]
		if on then
			b.Visible = true
			b.TextTransparency = 1
			b.BackgroundTransparency = 1
			Tween:Create(b, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextTransparency = 0,
				BackgroundTransparency = 0
			}):Play()
		else
			Tween:Create(b, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				TextTransparency = 1,
				BackgroundTransparency = 1
			}):Play()
		end
	end
	if not on then
		task.delay(0.17, function()
			if dead or btnOpen or tok ~= visTok then
				return
			end
			for i = 1, #btns do
				btns[i].Visible = false
			end
		end)
	end
end

local function clampBox()
	local p = box.Parent
	if not p then
		return
	end
	local s = p.AbsoluteSize
	local w = box.AbsoluteSize.X
	local h = box.AbsoluteSize.Y
	local x = fit(box.Position.X.Scale, 0, 1)
	local y = fit(box.Position.Y.Scale, 0, 1)
	local px = x * s.X + box.Position.X.Offset
	local py = y * s.Y + box.Position.Y.Offset
	px = fit(px, w, s.X)
	py = fit(py, 0, math.max(0, s.Y - h))
	box.Position = UDim2.new(px / math.max(s.X, 1), 0, py / math.max(s.Y, 1), 0)
	cfg.pos = {box.Position.X.Scale, box.Position.X.Offset, box.Position.Y.Scale, box.Position.Y.Offset}
end

local function setSize(w, h)
	w = fit(w, 140, 520)
	h = fit(h, 140, 520)
	box.Size = UDim2.new(0, w, 0, h)
	cfg.size = {w, h}
	clampBox()
	saveCfg()
end

local function nextQual()
	qix = qix + 1
	if qix > #qord then
		qix = 1
	end
	cfg.qual = qord[qix]
	refInfo()
	saveCfg()
end

local spec = {
	{ "+", function()
		cfg.zd = math.max(5, cfg.zd - 5)
		cfg.zh = math.max(5, cfg.zh - 5)
		saveCfg()
	end },
	{ "–", function()
		cfg.zd = cfg.zd + 5
		cfg.zh = cfg.zh + 5
		saveCfg()
	end },
	{ "Ray:On", function(b)
		cfg.ray = not cfg.ray
		b.Text = cfg.ray and "Ray:On" or "Ray:Off"
		saveCfg()
	end },
	{ "3D", function(b)
		cfg.top = not cfg.top
		b.Text = cfg.top and "Top" or "3D"
		refInfo()
		saveCfg()
	end },
	{ "TP", function(b)
		cfg.tp = not cfg.tp
		b.Text = cfg.tp and "TP*" or "TP"
		saveCfg()
	end },
	{ "S+", function()
		setSize(cfg.size[1] + 40, cfg.size[2] + 40)
	end },
	{ "S-", function()
		setSize(cfg.size[1] - 40, cfg.size[2] - 40)
	end },
	{ "R+", function()
		cfg.rad = math.min(400, cfg.rad + 25)
		refInfo()
		saveCfg()
	end },
	{ "R-", function()
		cfg.rad = math.max(25, cfg.rad - 25)
		refInfo()
		saveCfg()
	end },
	{ "Ren:On", function(b)
		cfg.render = not cfg.render
		b.Text = cfg.render and "Ren:On" or "Ren:Off"
		vp.Visible = cfg.render
		saveCfg()
	end },
	{ cfg.qual, function(b)
		nextQual()
		b.Text = cfg.qual
	end }
}

local function bindHold(b, fn)
	local on = false
	local tok = 0
	local function stop()
		on = false
		tok = tok + 1
	end
	give(b.MouseButton1Down:Connect(function()
		if dead or on then
			return
		end
		on = true
		tok = tok + 1
		local my = tok
		fn(b)
		task.spawn(function()
			task.wait(0.32)
			while not dead and on and tok == my do
				fn(b)
				task.wait(0.08)
			end
		end)
	end))
	give(b.MouseButton1Up:Connect(stop))
	give(b.MouseLeave:Connect(stop))
end

for i = 1, #spec do
	local sp = spec[i]
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 58, 0, 24)
	b.Text = sp[1]
	b.Visible = false
	b.Parent = hold
	style(b)
	if sp[1] == "+" or sp[1] == "–" or sp[1] == "R+" or sp[1] == "R-" then
		bindHold(b, sp[2])
	else
		give(b.MouseButton1Click:Connect(function()
			sp[2](b)
		end))
	end
	btns[#btns + 1] = b
end

btns[3].Text = cfg.ray and "Ray:On" or "Ray:Off"
btns[4].Text = cfg.top and "Top" or "3D"
btns[5].Text = cfg.tp and "TP*" or "TP"
btns[10].Text = cfg.render and "Ren:On" or "Ren:Off"
btns[11].Text = cfg.qual
refInfo()

give(menu.MouseButton1Click:Connect(function()
	setBtns(not btnOpen)
end))

local drg = false
local dInp
local dSt
local dPos

give(drag.InputBegan:Connect(function(i)
	if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	drg = true
	dInp = i
	dSt = i.Position
	dPos = box.Position
end))

give(drag.InputChanged:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
		dInp = i
	end
end))

give(Input.InputChanged:Connect(function(i)
	if dead or not drg or i ~= dInp then
		return
	end
	local p = box.Parent
	if not p then
		return
	end
	local s = p.AbsoluteSize
	local d = i.Position - dSt
	box.Position = UDim2.new(
		dPos.X.Scale + d.X / math.max(s.X, 1),
		dPos.X.Offset,
		dPos.Y.Scale + d.Y / math.max(s.Y, 1),
		dPos.Y.Offset
	)
	clampBox()
end))

give(Input.InputEnded:Connect(function(i)
	if i == dInp then
		drg = false
		dInp = nil
		saveCfg()
	end
end))

local state = {}
local function destroy()
	if dead then
		return
	end
	dead = true
	for src in pairs(parts) do
		killPart(src)
	end
	for src in pairs(rigs) do
		killRig(rigs, src)
	end
	if you and you.mdl then
		you.mdl:Destroy()
		you = nil
	end
	clean()
	if host and rawget(host, key) == state then
		host[key] = nil
	end
end
state.destroy = destroy
if host then
	host[key] = state
end

give(gui.AncestryChanged:Connect(function(_, p)
	if not p then
		destroy()
	end
end))

give(close.MouseButton1Click:Connect(destroy))

give(plr.CharacterAdded:Connect(function()
	refIgn()
	refRay()
	ensureYou()
	lastPos = nil
end))

give(plr.CharacterRemoving:Connect(function()
	for k in pairs(ign) do
		ign[k] = nil
	end
	if you and you.mdl then
		you.mdl:Destroy()
		you = nil
	end
	lastPos = nil
end))

refIgn()
refRay()
ensureYou()

give(vp.InputBegan:Connect(function(inp)
	if dead or not cfg.tp then
		return
	end
	if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local root = getRoot()
	if not root then
		return
	end
	local ap = vp.AbsolutePosition
	local as = vp.AbsoluteSize
	local mx = inp.Position.X
	local my = inp.Position.Y
	if mx < ap.X or mx > ap.X + as.X or my < ap.Y or my > ap.Y + as.Y then
		return
	end
	local u = (mx - ap.X) / as.X
	local v = (my - ap.Y) / as.Y
	local nx = (u - 0.5) * 2
	local ny = (-(v - 0.5)) * 2
	local f = math.tan(math.rad(cam.FieldOfView / 2))
	local dirCam = Vector3.new(nx * f, ny * f, -1).Unit
	local org = cam.CFrame.Position
	local dirW = cam.CFrame:VectorToWorldSpace(dirCam)
	if math.abs(dirW.Y) < 0.0001 then
		return
	end
	local rootPos = root.Position
	local py = rootPos.Y
	local t = (py - org.Y) / dirW.Y
	if t <= 0 then
		return
	end
	local trg = org + dirW * t
	local dx = trg.X - rootPos.X
	local dz = trg.Z - rootPos.Z
	local d = math.sqrt(dx * dx + dz * dz)
	if d > cfg.rad then
		local s = cfg.rad / d
		trg = Vector3.new(rootPos.X + dx * s, py, rootPos.Z + dz * s)
	end
	root.CFrame = CFrame.new(trg + Vector3.new(0, cfg.hoff, 0))
end))

local function aLerp(spd, dt)
	return 1 - math.exp(-spd * dt)
end

give(Run.RenderStepped:Connect(function(dt)
	if dead then
		return
	end
	perf.dt = perf.dt * 0.9 + dt * 0.1
	if dt > 1 / 24 then
		perf.lag = perf.lag + 1
	else
		perf.lag = math.max(0, perf.lag - 0.25)
	end
	if not cfg.render then
		return
	end
	local root = getRoot()
	local wcam = Ws.CurrentCamera
	if not root or not wcam then
		return
	end
	local q = getQ()
	local now = os.clock()
	local rootPos = root.Position
	scanT = scanT + dt
	rigT = rigT + dt
	if not lastPos or scanT >= q.scan or lastRad ~= cfg.rad or lastQual ~= cfg.qual or (rootPos - lastPos).Magnitude >= q.move then
		scanMap(rootPos, q)
		scanRigs(rootPos, q)
		scanT = 0
		rigT = 0
	elseif rigT >= 0.25 then
		scanRigs(rootPos, q)
		rigT = 0
	end
	upDyn(now)
	local okYou = false
	local y = ensureYou()
	if y then
		okYou = upRig(y, now)
	end
	youTag.Transparency = okYou and 1 or 0
	youTag.CFrame = CFrame.new(rootPos + Vector3.new(0, 1.1, 0))
	for src, it in pairs(rigs) do
		if not src.Parent then
			killRig(rigs, src)
		else
			upRig(it, now)
		end
	end
	lightPart.CFrame = CFrame.new(rootPos + Vector3.new(0, 18, 0))
	local focus = rootPos + Vector3.new(0, cfg.hoff, 0)
	local tar
	if cfg.top then
		local look = wcam.CFrame.LookVector
		look = Vector3.new(look.X, 0, look.Z)
		if look.Magnitude < 0.001 then
			look = Vector3.new(0, 0, -1)
		else
			look = look.Unit
		end
		local pos = focus + Vector3.new(0, cfg.zh, 0)
		tar = CFrame.lookAt(pos, focus + look)
	else
		local dir = wcam.CFrame.LookVector
		dir = Vector3.new(dir.X, 0, dir.Z)
		if dir.Magnitude < 0.001 then
			dir = Vector3.new(0, 0, -1)
		else
			dir = dir.Unit
		end
		local want = focus - dir * cfg.zd + Vector3.new(0, cfg.zh, 0)
		local pos = want
		if cfg.ray then
			local hit = Ws:Raycast(focus, want - focus, rayP)
			if hit then
				pos = hit.Position + hit.Normal * 0.55
			end
		end
		tar = CFrame.lookAt(pos, focus)
	end
	if camOk then
		cam.CFrame = cam.CFrame:Lerp(tar, aLerp(16, dt))
	else
		cam.CFrame = tar
		camOk = true
	end
end))

saveCfg()
