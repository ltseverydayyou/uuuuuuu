local ctx = {}

ctx.plrs = game:GetService("Players")
ctx.rs = game:GetService("ReplicatedStorage")
ctx.uis = game:GetService("UserInputService")
ctx.run = game:GetService("RunService")
ctx.ws = game:GetService("Workspace")
ctx.http = game:GetService("HttpService")
ctx.gui = game:GetService("GuiService")
ctx.lp = ctx.plrs.LocalPlayer
ctx.name = "killaura"
ctx.max = 32
ctx.on = false
ctx.idx = 1
ctx.dead = false
ctx.cons = {}
ctx.rate = 0.00075
ctx.scanRate = 0.01
ctx.burst = 1
ctx.maxFly = 16
ctx.fly = 0
ctx.loopYield = 0.001
ctx.maxDebt = 0.08
ctx.auraId = 0
ctx.nextHit = os.clock()
ctx.nextScan = 0
ctx.tar = nil
ctx.auraBusy = false
ctx.mineOn = false
ctx.mineHeld = false
ctx.mineRate = 0.035
ctx.nextMineAttempt = 0
ctx.mineAttempting = false
ctx.mineDefaultHotbarSlot = 1
ctx.curSlot = 1
ctx.mineTries = 8
ctx.chunkOn = false
ctx.chunkSizes = { 1, 3, 5, 6, 9 }
ctx.chunkIdx = 1
ctx.chunkBurst = 18
ctx.offCache = {}
ctx.badPos = Vector3.new(-1, -1, -1)
ctx.pt = {
	GreedyMeshingPart = "GreedyMeshingPart",
	CubePart = "CubePart"
}
ctx.noMineIds = {
	[0] = true,
	[25] = true,
	[26] = true,
	[27] = true
}
ctx.keys = {
	aura = Enum.KeyCode.K,
	mine = Enum.KeyCode.M
}
ctx.hotKeys = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
	[Enum.KeyCode.Nine] = 9
}

ctx.par = (function()
	local ok, res

	if type(gethui) == "function" then
		ok, res = pcall(gethui)
		if ok and typeof(res) == "Instance" then
			return res
		end
	end

	ok, res = pcall(function()
		return game:GetService("CoreGui")
	end)

	if ok and typeof(res) == "Instance" then
		return res
	end

	return ctx.lp:WaitForChild("PlayerGui")
end)()

ctx.find = function()
	local a = ctx.rs:FindFirstChild("Systems")
	a = a and a:FindFirstChild("ActionsSystem")
	a = a and a:FindFirstChild("Network")
	a = a and a:FindFirstChild("Attack")
	return a
end

ctx.remote = ctx.find()

ctx.rmcon = function(con)
	for i = #ctx.cons, 1, -1 do
		if ctx.cons[i] == con then
			table.remove(ctx.cons, i)
			return
		end
	end
end

ctx.bind = function(sig, fn)
	local con = sig:Connect(fn)
	ctx.cons[#ctx.cons + 1] = con
	return con
end

ctx.clean = function()
	if ctx.dead then
		return
	end

	ctx.dead = true
	ctx.on = false
	ctx.mineOn = false
	ctx.mineHeld = false
	ctx.chunkOn = false

	for i = 1, #ctx.cons do
		local con = ctx.cons[i]
		if con then
			con:Disconnect()
			ctx.cons[i] = nil
		end
	end

	if ctx.sg then
		ctx.sg:Destroy()
	end
end

do
	local old = ctx.par:FindFirstChild(ctx.name)
	if old then
		local ev = old:FindFirstChild("__cleanup")
		if ev and ev:IsA("BindableEvent") then
			pcall(function()
				ev:Fire()
			end)
		end

		pcall(function()
			old:Destroy()
		end)
	end
end

ctx.sg = Instance.new("ScreenGui")
ctx.sg.Name = ctx.name
ctx.sg.ResetOnSpawn = false
ctx.sg.IgnoreGuiInset = true
ctx.sg.DisplayOrder = 2147483647
ctx.sg.Parent = ctx.par

ctx.ev = Instance.new("BindableEvent")
ctx.ev.Name = "__cleanup"
ctx.ev.Parent = ctx.sg

ctx.f = Instance.new("Frame")
ctx.f.Size = UDim2.new(0, 220, 0, 96)
ctx.f.Position = UDim2.new(0.78, 0, 0.62, 0)
ctx.f.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ctx.f.BorderSizePixel = 0
ctx.f.Active = true
ctx.f.Parent = ctx.sg

ctx.fc = Instance.new("UICorner")
ctx.fc.CornerRadius = UDim.new(0, 12)
ctx.fc.Parent = ctx.f

ctx.mkbtn = function(txt, x, y, w, h, size)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, w, 0, h)
	b.Position = UDim2.new(0, x, 0, y)
	b.BackgroundColor3 = Color3.fromRGB(70, 125, 210)
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamBold
	b.Text = txt
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.TextSize = size or 14
	b.TextWrapped = true
	b.Parent = ctx.f

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = b

	return b
end

ctx.b = ctx.mkbtn("K", 8, 8, 48, 38, 22)
ctx.mb = ctx.mkbtn("Mine", 60, 8, 54, 38, 13)
ctx.cb = ctx.mkbtn("Chunk", 118, 8, 58, 38, 13)
ctx.sb = ctx.mkbtn("1x1", 180, 8, 32, 38, 12)
ctx.slb = ctx.mkbtn("S:1", 8, 52, 48, 34, 13)

ctx.info = Instance.new("TextLabel")
ctx.info.Size = UDim2.new(0, 152, 0, 34)
ctx.info.Position = UDim2.new(0, 60, 0, 52)
ctx.info.BackgroundTransparency = 1
ctx.info.Font = Enum.Font.GothamBold
ctx.info.TextColor3 = Color3.fromRGB(235, 235, 235)
ctx.info.TextSize = 12
ctx.info.TextWrapped = true
ctx.info.Text = "K: Aura | M: Mine"
ctx.info.Parent = ctx.f

ctx.updateUi = function()
	if ctx.b then
		ctx.b.Text = ctx.on and "ON" or "K"
		ctx.b.BackgroundColor3 = ctx.on and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(200, 60, 60)
	end

	if ctx.mb then
		ctx.mb.Text = ctx.mineOn and "Mine\nON" or "Mine"
		ctx.mb.BackgroundColor3 = ctx.mineOn and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(70, 125, 210)
	end

	if ctx.cb then
		ctx.cb.Text = ctx.chunkOn and "Chunk\nON" or "Chunk"
		ctx.cb.BackgroundColor3 = ctx.chunkOn and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(70, 125, 210)
	end

	if ctx.sb then
		local s = ctx.chunkSizes[ctx.chunkIdx] or 1
		ctx.sb.Text = tostring(s) .. "x" .. tostring(s)
	end

	if ctx.slb then
		ctx.slb.Text = "S:" .. tostring(ctx.curSlot)
	end

	if ctx.info then
		ctx.info.Text = "K: Aura | M: Mine"
	end
end

ctx.startAura = function()
	ctx.auraId += 1
	ctx.tar = nil
	ctx.auraBusy = false
end

ctx.stopAura = function()
	ctx.auraId += 1
	ctx.fly = 0
	ctx.tar = nil
	ctx.auraBusy = false
end

ctx.set = function(v)
	local on = v == true

	if ctx.on == on then
		return
	end

	ctx.on = on
	ctx.nextHit = os.clock()
	ctx.nextScan = 0
	ctx.tar = nil

	if ctx.on then
		ctx.startAura()
	else
		ctx.stopAura()
	end

	ctx.updateUi()
end

ctx.toggle = function()
	ctx.set(not ctx.on)
end

ctx.setMineStatus = function(text, color)
	if not ctx.mb then
		return
	end

	ctx.mb.Text = text or (ctx.mineOn and "Mine\nON" or "Mine")
	ctx.mb.BackgroundColor3 = color or (ctx.mineOn and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(70, 125, 210))
end

ctx.setMine = function(v)
	ctx.mineOn = v == true
	ctx.mineHeld = false
	ctx.nextMineAttempt = 0
	ctx.mineAttempting = false
	ctx.updateUi()
end

ctx.toggleMine = function()
	ctx.setMine(not ctx.mineOn)
end

ctx.toggleChunk = function()
	ctx.chunkOn = not ctx.chunkOn
	ctx.updateUi()
end

ctx.cycleChunk = function()
	ctx.chunkIdx += 1
	if ctx.chunkIdx > #ctx.chunkSizes then
		ctx.chunkIdx = 1
	end
	ctx.updateUi()
end

ctx.cycleSlot = function()
	ctx.curSlot += 1
	if ctx.curSlot > 9 then
		ctx.curSlot = 1
	end
	ctx.updateUi()
end

ctx.loadMineModules = function()
	if ctx.mineReady and ctx.mineBreakRemote and ctx.mineBreakRemote.Parent then
		return true
	end

	local systems = ctx.rs:FindFirstChild("Systems")
	local actions = systems and systems:FindFirstChild("ActionsSystem")
	local network = actions and actions:FindFirstChild("Network")

	ctx.mineBreakRemote = network and network:FindFirstChild("Break")

	if not (ctx.mineBreakRemote and ctx.mineBreakRemote:IsA("RemoteFunction")) then
		warn("[SexCraft] Mine failed:", "missing ActionsSystem.Network.Break")
		return false
	end

	ctx.mineReady = true
	return true
end

ctx.rnd = function(v)
	return math.floor(v + 0.5)
end

ctx.coordinatesFromWorkspaceVector3 = function(pos)
	local v = pos / 4
	return Vector3.new(ctx.rnd(v.X), ctx.rnd(v.Y), ctx.rnd(v.Z))
end

ctx.regionGridFromCoordinates = function(pos)
	return math.floor(pos.X / 256), math.floor(pos.Z / 256)
end

ctx.chunkGridFromCoordinates = function(pos)
	return math.floor((pos.X % 256) / 16), math.floor((pos.Z % 256) / 16)
end

ctx.blockGridFromCoordinates = function(pos)
	return pos.X % 16, pos.Y % 256, pos.Z % 16
end

ctx.regionNameFromCoordinates = function(pos)
	local x, z = ctx.regionGridFromCoordinates(pos)
	return tostring(x) .. "." .. tostring(z)
end

ctx.chunkNameFromCoordinates = function(pos)
	local x, z = ctx.chunkGridFromCoordinates(pos)
	return tostring(x + 16 * z)
end

ctx.blockNameFromCoordinates = function(pos)
	local x, y, z = ctx.blockGridFromCoordinates(pos)
	return tostring(y + 256 * z + 4096 * x)
end

ctx.coordinatesOffsetFromRegionName = function(name)
	local x, z = string.match(tostring(name), "^([^%.]+)%.(.+)$")
	x = tonumber(x)
	z = tonumber(z)

	if not x or not z then
		return
	end

	return Vector3.new(x, 0, z) * 256
end

ctx.coordinatesOffsetFromChunkName = function(name)
	local n = tonumber(name)

	if not n then
		return
	end

	local x = n % 16
	return Vector3.new(x, 0, (n - x) / 16) * 16
end

ctx.coordinatesOffsetFromBlockName = function(name)
	local n = tonumber(name)

	if not n then
		return
	end

	local y = n % 256
	local z = ((n - y) % 4096) / 256
	local x = (n - y - z * 256) / 4096

	if x < 0 or x >= 16 or y < 0 or y >= 256 or z < 0 or z >= 16 then
		return
	end

	return Vector3.new(x, y, z)
end

ctx.coordinatesFromNames = function(r, c, b)
	local ro = ctx.coordinatesOffsetFromRegionName(r)
	local co = ctx.coordinatesOffsetFromChunkName(c)
	local bo = ctx.coordinatesOffsetFromBlockName(b)

	if not ro or not co or not bo then
		return
	end

	return ro + co + bo
end

ctx.getNamesFromCoordinates = function(pos)
	return ctx.regionNameFromCoordinates(pos), ctx.chunkNameFromCoordinates(pos), ctx.blockNameFromCoordinates(pos)
end

ctx.coordsFromInst = function(inst)
	if typeof(inst) ~= "Instance" or not inst.Parent then
		return
	end

	local r, c = string.match(inst.Parent.Name, "^(.+)_(.+)$")

	if not r or not c then
		return
	end

	return ctx.coordinatesFromNames(r, c, inst.Name)
end

ctx.goodMinePos = function(pos)
	return typeof(pos) == "Vector3" and pos ~= ctx.badPos and pos.X == pos.X and pos.Y == pos.Y and pos.Z == pos.Z and pos.Y >= 0 and pos.Y < 256
end

ctx.chunkBurst = 81

ctx.addMineTarget = function(list, seen, pos, obj, norm, id)
	if not ctx.goodMinePos(pos) then
		return
	end

	local x = ctx.rnd(pos.X)
	local y = ctx.rnd(pos.Y)
	local z = ctx.rnd(pos.Z)
	local key = tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)

	if seen[key] then
		return
	end

	seen[key] = true
	list[#list + 1] = {
		pos = Vector3.new(x, y, z),
		obj = obj,
		norm = norm,
		id = id
	}
end

ctx.getGuiInset = function()
	local ok, a = pcall(function()
		return ctx.gui:GetGuiInset()
	end)

	if ok and typeof(a) == "Vector2" then
		return a
	end

	return Vector2.zero
end

ctx.idFromState = function(state)
	if state == nil then
		return
	end

	if type(state) == "number" then
		return state
	end

	if type(state) == "string" then
		return tonumber(string.match(state, "^%-?%d+"))
	end
end

ctx.idFromObj = function(obj)
	if typeof(obj) ~= "Instance" then
		return
	end

	local id = tonumber(obj:GetAttribute("i"))

	if id ~= nil then
		return id
	end

	id = ctx.idFromState(obj:GetAttribute("b"))

	if id ~= nil then
		return id
	end

	if obj:IsA("Model") then
		local p = obj.PrimaryPart or obj:FindFirstChild("Hitbox") or obj:FindFirstChildWhichIsA("BasePart", true)

		if p then
			id = tonumber(p:GetAttribute("i"))

			if id ~= nil then
				return id
			end

			id = ctx.idFromState(p:GetAttribute("b"))

			if id ~= nil then
				return id
			end
		end
	end
end

ctx.getBlockInstanceAt = function(pos)
	local map = workspace:FindFirstChild("Map")

	if not map then
		return
	end

	local r, c, b = ctx.getNamesFromCoordinates(pos)
	local folder = map:FindFirstChild(r .. "_" .. c)

	if not folder then
		return
	end

	return folder:FindFirstChild(b)
end

ctx.getBlockId = function(pos, obj)
	local inst = ctx.getBlockInstanceAt(pos)
	local id = ctx.idFromObj(inst)

	if id ~= nil then
		return id
	end

	id = ctx.idFromObj(obj)

	if id ~= nil then
		return id
	end

	if inst and inst:IsA("Model") then
		local p = inst.PrimaryPart or inst:FindFirstChild("Hitbox") or inst:FindFirstChildWhichIsA("BasePart", true)

		if p then
			return ctx.idFromObj(p)
		end
	end
end

ctx.coordsFromObjHit = function(obj, hit)
	if typeof(obj) ~= "Instance" then
		return
	end

	local pos = ctx.coordsFromInst(obj)

	if pos then
		return pos
	end

	if obj:IsA("BasePart") and obj.Parent and obj.Parent:IsA("Model") then
		pos = ctx.coordsFromInst(obj.Parent)

		if pos then
			return pos
		end
	end

	if obj:IsA("Model") then
		local p = obj.PrimaryPart or obj:FindFirstChild("Hitbox") or obj:FindFirstChildWhichIsA("BasePart", true)

		if p then
			pos = ctx.coordsFromInst(p)

			if pos then
				return pos
			end
		end
	end

	if hit then
		if obj:GetAttribute("PartType") == ctx.pt.GreedyMeshingPart then
			return ctx.coordinatesFromWorkspaceVector3(hit.Position - hit.Normal * 0.05)
		end

		return ctx.coordinatesFromWorkspaceVector3(hit.Position - hit.Normal * 0.001)
	end

	if obj:IsA("BasePart") then
		return ctx.coordinatesFromWorkspaceVector3(obj.Position)
	end

	if obj:IsA("Model") then
		local p = obj.PrimaryPart or obj:FindFirstChild("Hitbox") or obj:FindFirstChildWhichIsA("BasePart", true)

		if p then
			return ctx.coordinatesFromWorkspaceVector3(p.Position)
		end
	end
end

ctx.raycastMineTargets = function(list, seen)
	local cam = workspace.CurrentCamera
	local map = workspace:FindFirstChild("Map")

	if not cam or not map then
		return
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { map }

	pcall(function()
		params.CollisionGroup = "Default"
	end)

	local inset = ctx.getGuiInset()
	local ray = cam:ScreenPointToRay(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2 - inset.Y, 0)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 20, params)

	if not hit or not hit.Instance then
		return
	end

	if hit.Instance.Name == "BarrierChunk" or hit.Instance:FindFirstAncestor("Skybox") then
		return
	end

	if not hit.Instance:IsDescendantOf(map) then
		return
	end

	local obj = hit.Instance

	if obj.Parent and obj.Parent:IsA("Model") and obj.Parent:IsDescendantOf(map) then
		obj = obj.Parent
	end

	local id = ctx.idFromObj(obj)
	local p1 = ctx.coordsFromObjHit(obj, hit)
	local p2 = ctx.coordinatesFromWorkspaceVector3(hit.Position - hit.Normal * 0.001)
	local p3 = ctx.coordinatesFromWorkspaceVector3(hit.Position - hit.Normal * 0.05)
	local p4 = ctx.coordinatesFromWorkspaceVector3(hit.Position - hit.Normal)

	ctx.addMineTarget(list, seen, p1, obj, hit.Normal, id)
	ctx.addMineTarget(list, seen, p2, obj, hit.Normal, id)
	ctx.addMineTarget(list, seen, p3, obj, hit.Normal, id)
	ctx.addMineTarget(list, seen, p4, obj, hit.Normal, id)
end

ctx.getMineTargets = function()
	local list = {}
	local seen = {}

	ctx.raycastMineTargets(list, seen)

	return list
end

ctx.getAxes = function(norm)
	norm = typeof(norm) == "Vector3" and norm or Vector3.yAxis

	local x = math.abs(norm.X)
	local y = math.abs(norm.Y)
	local z = math.abs(norm.Z)

	if y >= x and y >= z then
		return Vector3.xAxis, Vector3.zAxis
	end

	if x >= z then
		return Vector3.yAxis, Vector3.zAxis
	end

	return Vector3.xAxis, Vector3.yAxis
end

ctx.getOffsets = function(size)
	if ctx.offCache[size] then
		return ctx.offCache[size]
	end

	local list = {}
	local a = -math.floor((size - 1) / 2)
	local b = a + size - 1

	for x = a, b do
		for y = a, b do
			list[#list + 1] = {
				x = x,
				y = y,
				d = x * x + y * y
			}
		end
	end

	table.sort(list, function(a2, b2)
		if a2.d == b2.d then
			if a2.x == b2.x then
				return a2.y < b2.y
			end

			return a2.x < b2.x
		end

		return a2.d < b2.d
	end)

	ctx.offCache[size] = list
	return list
end

ctx.expandMineTargets = function(base)
	if not ctx.chunkOn then
		return base
	end

	local size = ctx.chunkSizes[ctx.chunkIdx] or 1

	if size <= 1 or not base[1] then
		return base
	end

	local center = base[1]
	local ax, ay = ctx.getAxes(center.norm)
	local offs = ctx.getOffsets(size)
	local list = {}
	local seen = {}

	for i = 1, #offs do
		local o = offs[i]
		ctx.addMineTarget(
			list,
			seen,
			center.pos + ax * o.x + ay * o.y,
			center.obj,
			center.norm,
			center.id
		)
	end

	return list
end

ctx.getMineTarget = function()
	local list = ctx.getMineTargets()
	local item = list[1]
	return item and item.pos
end

ctx.getInv = function()
	local raw = ctx.lp:GetAttribute("inventory")

	if type(raw) ~= "string" or raw == "" then
		return
	end

	local ok, inv = pcall(function()
		return ctx.http:JSONDecode(raw)
	end)

	if ok and type(inv) == "table" then
		return inv
	end
end

ctx.getSlots = function()
	return { ctx.curSlot or ctx.mineDefaultHotbarSlot or 1 }
end

ctx.nearMineDist = function(pos)
	local ch = ctx.lp.Character
	local root = ch and (ch.PrimaryPart or ch:FindFirstChild("HumanoidRootPart"))

	if not root then
		return false
	end

	return (root.Position - pos * 4).Magnitude <= 32
end

ctx.mineBlock = function(pos, obj, id)
	if not ctx.goodMinePos(pos) or not ctx.nearMineDist(pos) then
		return false
	end

	local blockId = ctx.getBlockId(pos, obj) or id

	if blockId == nil or ctx.noMineIds[blockId] then
		return false
	end

	local r, c, b = ctx.getNamesFromCoordinates(pos)
	local slots = ctx.getSlots()

	for i = 1, #slots do
		local slot = slots[i]

		local ok, broke = pcall(function()
			return ctx.mineBreakRemote:InvokeServer(r, c, b, blockId, slot)
		end)

		if ok and broke == true then
			return true
		end
	end

	return false
end

ctx.tryMineTarget = function(force)
	if not ctx.mineOn or ctx.dead then
		return
	end

	local now = os.clock()

	if not force and now < ctx.nextMineAttempt then
		return
	end

	if ctx.mineAttempting then
		return
	end

	ctx.nextMineAttempt = now + ctx.mineRate
	ctx.mineAttempting = true

	task.spawn(function()
		if not ctx.loadMineModules() then
			ctx.mineOn = false
			ctx.mineHeld = false
			ctx.mineAttempting = false
			ctx.setMineStatus("Mine\nError", Color3.fromRGB(190, 70, 70))

			task.delay(1, function()
				if not ctx.dead then
					ctx.updateUi()
				end
			end)

			return
		end

		local targets = ctx.expandMineTargets(ctx.getMineTargets())
		local broke = false
		local maxTry = ctx.chunkOn and ctx.chunkBurst or ctx.mineTries
		local tries = math.min(#targets, maxTry)

		for i = 1, tries do
			local item = targets[i]

			if item and ctx.mineBlock(item.pos, item.obj, item.id) then
				broke = true

				if not ctx.chunkOn then
					break
				end
			end
		end

		if not broke and force then
			ctx.setMineStatus(#targets > 0 and "No\nBreak" or "No\nTarget", Color3.fromRGB(190, 70, 70))

			task.delay(0.45, function()
				if not ctx.dead then
					ctx.updateUi()
				end
			end)
		end

		ctx.mineAttempting = false
	end)
end

ctx.instantMine = ctx.toggleMine

ctx.valid = function(m)
	if typeof(m) ~= "Instance" or not m:IsA("Model") then
		return
	end

	local h = m:FindFirstChildOfClass("Humanoid")
	if not h or h.Health <= 0 then
		return
	end

	local r = m:FindFirstChild("HumanoidRootPart")
	if not r or not r:IsA("BasePart") then
		return
	end

	return h, r
end

ctx.dist = function(a, b)
	local v = a - b
	return v.X * v.X + v.Y * v.Y + v.Z * v.Z
end

ctx.nearPlayer = function()
	local ch = ctx.lp.Character
	local _, root = ctx.valid(ch)

	if not root then
		return
	end

	local pos = root.Position
	local best = nil
	local bdist = ctx.max * ctx.max
	local list = ctx.plrs:GetPlayers()

	for i = 1, #list do
		local p = list[i]
		if p ~= ctx.lp then
			local t = p.Character
			local _, r = ctx.valid(t)

			if r then
				local d = ctx.dist(r.Position, pos)
				if d < bdist then
					best = t
					bdist = d
				end
			end
		end
	end

	return best
end

ctx.nearEntity = function()
	local ch = ctx.lp.Character
	local _, root = ctx.valid(ch)

	if not root then
		return
	end

	local fold = workspace:FindFirstChild("Entities")
	if not fold then
		return
	end

	local pos = root.Position
	local best = nil
	local bdist = ctx.max * ctx.max
	local ents = fold:GetChildren()

	for i = 1, #ents do
		local e = ents[i]
		local _, r = ctx.valid(e)

		if r then
			local d = ctx.dist(r.Position, pos)
			if d < bdist then
				best = e
				bdist = d
			end
		end
	end

	return best
end

ctx.near = function()
	return ctx.nearPlayer() or ctx.nearEntity()
end

ctx.goodtar = function(t)
	if not t then
		return false
	end

	local ch = ctx.lp.Character
	local _, root = ctx.valid(ch)
	local _, tr = ctx.valid(t)

	if not root or not tr then
		return false
	end

	return ctx.dist(root.Position, tr.Position) <= ctx.max * ctx.max
end

ctx.hit = function(t)
	if not t or ctx.fly >= ctx.maxFly then
		return
	end

	local r = ctx.remote
	if not r or not r.Parent then
		r = ctx.find()
		ctx.remote = r
	end

	if not r then
		return
	end

	local isFunc = r:IsA("RemoteFunction")
	local isEvent = r:IsA("RemoteEvent")

	if not isFunc and not isEvent then
		return
	end

	local idx = ctx.idx
	ctx.idx = ctx.idx == 1 and 2 or 1

	ctx.fly += 1

	task.spawn(function()
		if isEvent then
			pcall(function()
				r:FireServer(t, idx)
			end)
		else
			pcall(function()
				r:InvokeServer(t, idx)
			end)
		end

		ctx.fly = math.max(ctx.fly - 1, 0)
	end)
end

ctx.pulse = function()
	if not ctx.on or ctx.dead then
		return
	end

	local t = ctx.near()
	ctx.tar = t

	if ctx.goodtar(t) then
		ctx.hit(t)
	end
end

ctx.stepAura = function()
	if not ctx.on or ctx.dead or ctx.auraBusy then
		return
	end

	ctx.auraBusy = true

	task.defer(function()
		ctx.auraBusy = false

		if not ctx.on or ctx.dead then
			return
		end

		task.spawn(ctx.pulse)
	end)
end

ctx.drag = false
ctx.din = nil
ctx.ds = nil
ctx.sp = nil

ctx.okdrag = function(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

ctx.okmove = function(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

ctx.okmine = function(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

ctx.overFrame = function(i)
	if not ctx.f or not i.Position then
		return false
	end

	local p = i.Position
	local pos = ctx.f.AbsolutePosition
	local size = ctx.f.AbsoluteSize

	return p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
end

ctx.bind(ctx.ev.Event, ctx.clean)

ctx.bind(ctx.b.Activated, ctx.toggle)
ctx.bind(ctx.mb.Activated, ctx.toggleMine)
ctx.bind(ctx.cb.Activated, ctx.toggleChunk)
ctx.bind(ctx.sb.Activated, ctx.cycleChunk)
ctx.bind(ctx.slb.Activated, ctx.cycleSlot)

ctx.bind(ctx.uis.InputBegan, function(i, gp)
	if ctx.dead then
		return
	end

	local slot = ctx.hotKeys[i.KeyCode]
	if slot then
		ctx.curSlot = slot
		ctx.updateUi()
	end

	if not gp then
		if i.KeyCode == ctx.keys.aura then
			ctx.toggle()
			return
		end

		if i.KeyCode == ctx.keys.mine then
			ctx.toggleMine()
			return
		end
	end

	if gp or not ctx.mineOn or not ctx.okmine(i) or ctx.overFrame(i) then
		return
	end

	ctx.mineHeld = true
	ctx.tryMineTarget(true)
end)

ctx.bind(ctx.uis.InputEnded, function(i)
	if ctx.okmine(i) then
		ctx.mineHeld = false
	end
end)

ctx.bind(ctx.f.InputBegan, function(i)
	if not ctx.okdrag(i) then
		return
	end

	ctx.drag = true
	ctx.ds = i.Position
	ctx.sp = ctx.f.Position

	local con
	con = i.Changed:Connect(function()
		if i.UserInputState == Enum.UserInputState.End then
			ctx.drag = false

			if con then
				con:Disconnect()
				ctx.rmcon(con)
				con = nil
			end
		end
	end)

	ctx.cons[#ctx.cons + 1] = con
end)

ctx.bind(ctx.f.InputChanged, function(i)
	if ctx.okmove(i) then
		ctx.din = i
	end
end)

ctx.bind(ctx.uis.InputChanged, function(i)
	if not ctx.drag or i ~= ctx.din or not ctx.ds or not ctx.sp then
		return
	end

	local d = i.Position - ctx.ds
	ctx.f.Position = UDim2.new(ctx.sp.X.Scale, ctx.sp.X.Offset + d.X, ctx.sp.Y.Scale, ctx.sp.Y.Offset + d.Y)
end)

ctx.bind(ctx.run.Heartbeat, function()
	if ctx.dead then
		return
	end

	if ctx.on then
		ctx.stepAura()
	end

	if ctx.mineOn and ctx.mineHeld then
		ctx.tryMineTarget(false)
	end
end)

ctx.set(false)
ctx.setMine(false)
ctx.updateUi()