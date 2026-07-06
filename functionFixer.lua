--!nonstrict

type RuntimeState = {
	alive: boolean,
	cleanup: (() -> ())?,
}

type PromptOptions = {
	hold: number?,
	requireLoS: boolean?,
	disableLoS: boolean?,
	distance: number?,
	autoDistance: boolean?,
	exclusivity: Enum.ProximityPromptExclusivity?,
	forceEnable: boolean?,
	relocate: boolean?,
	proxyAlways: boolean?,
	relocateDistance: number?,
	relocateUp: number?,
	relocateRight: number?,
	showTimeout: number?,
	stagger: number?,
}

type PromptState = {
	E: boolean,
	H: number,
	R: boolean,
	D: number,
	X: Enum.ProximityPromptExclusivity,
	ref: number,
	inFlight: boolean,
	proxy: { BasePart }?,
}

type TouchSnapshot = {
	CF: CFrame,
	VEL: Vector3,
	ANG: Vector3,
	CT: boolean,
	CQ: boolean,
	CC: boolean,
	CG: number?,
	AN: boolean?,
	MS: boolean?,
}

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
	local resolver = loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau")
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

local _env = getgenv and getgenv() or _G or {}
if type(_env.__NAFunctionFixerRuntime) == "table" and type(_env.__NAFunctionFixerRuntime.cleanup) == "function" then
	pcall(_env.__NAFunctionFixerRuntime.cleanup)
end
local _runtime: RuntimeState = {
	alive = true
}
_env.__NAFunctionFixerRuntime = _runtime
local RunService = __lt.cs("RunService", cloneref)
local HttpService = __lt.cs("HttpService", cloneref)
local Wait = task.wait
local Delay = task.delay
local Spawn = task.spawn
local Insert = table.insert
local Concat = table.concat

local promptPartCache: { [Instance]: BasePart | false } = {}

local glitchMarks = {
	"̶",
	"̷",
	"̸",
	"̹",
	"̺",
	"̻",
	"͓",
	"͔",
	"͘",
	"͜",
	"͞",
	"͟",
	"͢"
}

local hparts: { [BasePart]: number } = {}
local hconn: RBXScriptConnection?
_runtime.cleanup = function()
	if not _runtime.alive then
		return
	end
	_runtime.alive = false
	if hconn then
		pcall(function()
			hconn:Disconnect()
		end)
		hconn = nil
	end
	hparts = {}
	if _env.__NAFunctionFixerRuntime == _runtime then
		_env.__NAFunctionFixerRuntime = nil
	end
end

local function hb(n: number?)
	for i = 1, n or 1 do
		RunService.Heartbeat:Wait()
	end
end

local function regHp(p: BasePart?)
	if not p then
		return
	end
	hparts[p] = tick()
	if hconn then
		return
	end
	hconn = RunService.Heartbeat:Connect(function()
		local now = tick()
		for part, t0 in hparts do
			if (not part) or (not part.Parent) or (now - t0 > 10) then
				hparts[part] = nil
				if part then
					pcall(function()
						part:Destroy()
					end)
				end
			end
		end
		if not next(hparts) and hconn then
			hconn:Disconnect()
			hconn = nil
		end
	end)
end

local function getExecutorName(): string
	if typeof(identifyexecutor) ~= "function" then
		return ""
	end

	local ok, name = pcall(identifyexecutor)
	if ok and typeof(name) == "string" then
		return string.lower(name)
	end

	return ""
end

local executorName = getExecutorName()
local isLimitedExecutor = executorName == "solara" or executorName == "xeno" or typeof(firetouchinterest) ~= "function"

local function randomString(): string
	if HttpService and HttpService.GenerateGUID then
		return __lt.cm("HttpService", "GenerateGUID", false)
	end
	local length = math.random(10, 20)
	local result = {}
	for i = 1, length do
		local char = string.char(math.random(32, 126))
		Insert(result, char)
		if math.random() < 0.5 then
			local numGlitches = math.random(1, 4)
			for j = 1, numGlitches do
				Insert(result, glitchMarks[math.random(#glitchMarks)])
			end
		end
	end
	if math.random() < 0.3 then
		Insert(result, utf8.char(math.random(768, 879)))
	end
	if math.random() < 0.1 then
		Insert(result, "\000")
	end
	if math.random() < 0.1 then
		Insert(result, string.rep("43", math.random(5, 20)))
	end
	if math.random() < 0.2 then
		Insert(result, utf8.char(8238))
	end
	return Concat(result)
end

local function getPromptPart(pp: ProximityPrompt?): BasePart?
	if not pp then
		return nil
	end
	local c = promptPartCache[pp]
	if c ~= nil then
		if c == false then
			return nil
		end
		return c
	end
	local parent = pp.Parent
	local part
	if parent then
		if parent:IsA("Attachment") then
			local p = parent.Parent
			if p and p:IsA("BasePart") then
				part = p
			end
		elseif parent:IsA("BasePart") then
			part = parent
		end
	end
	if not part then
		local model = pp:FindFirstAncestorWhichIsA("Model")
		if model then
			if model.PrimaryPart then
				part = model.PrimaryPart
			else
				part = model:FindFirstChildWhichIsA("BasePart", true)
			end
		end
	end
	if not part then
		part = pp:FindFirstAncestorWhichIsA("BasePart")
	end
	promptPartCache[pp] = part or false
	return part
end

if isLimitedExecutor then
	local ProximityPromptService = __lt.cs("ProximityPromptService", cloneref)

	local function toOpts(o: any): PromptOptions
		if typeof(o) == "number" then
			return {
				hold = o
			}
		end
		return typeof(o) == "table" and o or {}
	end

	local state: { [ProximityPrompt]: PromptState } = {}

	local function snapshot(pp: ProximityPrompt): PromptState
		return {
			E = pp.Enabled,
			H = pp.HoldDuration,
			R = pp.RequiresLineOfSight,
			D = pp.MaxActivationDistance,
			X = pp.Exclusivity
		}
	end

	local function cleanProxies(s: PromptState?)
		local list = s and s.proxy
		if not list then
			return
		end
		for i = 1, #list do
			local p = list[i]
			if p and p.Parent then
				pcall(function()
					p:Destroy()
				end)
			end
			list[i] = nil
		end
		s.proxy = nil
	end

	local function begin(pp: ProximityPrompt, o: PromptOptions): boolean
		if not (pp and pp.Parent) then
			return false
		end

		local s = state[pp]
		if not s then
			s = snapshot(pp)
			s.ref = 0
			s.inFlight = false
			s.proxy = nil
			state[pp] = s
		end

		if s.inFlight then
			return false
		end

		s.inFlight = true
		s.ref += 1

		pp.HoldDuration = 0

		if o.requireLoS ~= nil then
			pp.RequiresLineOfSight = o.requireLoS and true or false
		elseif o.disableLoS ~= false then
			pp.RequiresLineOfSight = false
		end

		if o.distance ~= nil then
			pp.MaxActivationDistance = o.distance
		elseif o.autoDistance ~= false then
			pp.MaxActivationDistance = 1000000000
		end

		if o.exclusivity ~= nil then
			pp.Exclusivity = o.exclusivity
		else
			pp.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
		end

		if o.forceEnable ~= false then
			pp.Enabled = true
		end

		return true
	end

	local function finish(pp: ProximityPrompt)
		local s = state[pp]
		if not s then
			return
		end

		s.ref -= 1
		s.inFlight = false

		if s.ref <= 0 and pp and pp.Parent then
			pp.Enabled = s.E
			pp.HoldDuration = s.H
			pp.RequiresLineOfSight = s.R
			pp.MaxActivationDistance = s.D
			pp.Exclusivity = s.X
			cleanProxies(s)
			state[pp] = nil
		elseif s.ref <= 0 then
			cleanProxies(s)
			state[pp] = nil
		end
	end

	local function rstep(n: number?)
		for i = 1, n or 1 do
			pcall(function()
				RunService.RenderStepped:Wait()
			end)
			RunService.Heartbeat:Wait()
		end
	end

	local function shouldProxy(pp: ProximityPrompt, o: PromptOptions): boolean
		if o.relocate == false then
			return false
		end

		if o.proxyAlways == true then
			return true
		end

		local cam = workspace.CurrentCamera
		local part = getPromptPart(pp)

		if not cam or not part then
			return true
		end

		local vp, on = cam:WorldToViewportPoint(part.Position)
		if vp.Z <= 0 or not on then
			return true
		end

		local dir = part.Position - cam.CFrame.Position
		if dir.Magnitude <= 0 then
			return true
		end

		return dir.Unit:Dot(cam.CFrame.LookVector) < 0.05
	end

	local function makeProxy(pp: ProximityPrompt, o: PromptOptions)
		local cam = workspace.CurrentCamera
		if not cam then
			return nil
		end

		local shown = false
		local con

		pcall(function()
			con = ProximityPromptService.PromptShown:Connect(function(p)
				if p == pp then
					shown = true
				end
			end)
		end)

		local cf = cam.CFrame
		local dist = tonumber(o.relocateDistance) or 5
		local up = o.relocateUp ~= nil and tonumber(o.relocateUp) or -0.35
		local right = o.relocateRight ~= nil and tonumber(o.relocateRight) or 0

		if not up then
			up = -0.35
		end

		if not right then
			right = 0
		end

		dist = math.clamp(dist, 1, 50)

		local pos = cf.Position + cf.LookVector * dist + cf.UpVector * up + cf.RightVector * right
		local old = pp.Parent

		local ok, proxy = pcall(function()
			local p = Instance.new("Part")
			p.Name = randomString and randomString() or "\000"
			p.Size = Vector3.new(0.05, 0.05, 0.05)
			p.Anchored = true
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			p.CastShadow = false
			p.Transparency = 1
			p.CFrame = CFrame.new(pos, pos + cf.LookVector)
			p.Parent = workspace
			return p
		end)

		if not ok or not proxy then
			if con then
				pcall(function()
					con:Disconnect()
				end)
			end
			return nil
		end

		regHp(proxy)

		local s = state[pp]
		if s then
			s.proxy = s.proxy or {}
			table.insert(s.proxy, proxy)
		end

		pcall(function()
			pp.Enabled = false
		end)

		pcall(function()
			pp.Parent = proxy
		end)

		rstep(1)

		if o.forceEnable ~= false then
			pcall(function()
				pp.Enabled = true
			end)
		end

		local dead = false

		local function closeCon()
			if con then
				pcall(function()
					con:Disconnect()
				end)
				con = nil
			end
		end

		local function waitShow(lim: number?)
			lim = tonumber(lim) or 0.12
			local t0 = tick()

			repeat
				rstep(1)
			until shown or dead or tick() - t0 >= lim or not (pp and pp.Parent)

			closeCon()
		end

		local function restore()
			dead = true
			closeCon()

			if pp then
				pcall(function()
					pp.Parent = old
				end)
			end

			if proxy and proxy.Parent then
				pcall(function()
					proxy:Destroy()
				end)
			end
		end

		return restore, waitShow
	end

	local function fireOne(pp: ProximityPrompt, o: PromptOptions)
		if not begin(pp, o) then
			return
		end

		local restorePos
		local waitShow

		local ok, err = pcall(function()
			if shouldProxy(pp, o) then
				restorePos, waitShow = makeProxy(pp, o)
				if waitShow then
					waitShow(o.showTimeout)
				else
					rstep(2)
				end
			else
				rstep(1)
			end

			pp:InputHoldBegin()

			local t = o.hold ~= nil and tonumber(o.hold) or 0
			if t and t > 0 then
				Wait(t)
			else
				rstep(1)
			end

			pp:InputHoldEnd()
			rstep(1)
		end)

		if restorePos then
			pcall(restorePos)
		end

		finish(pp)

		if not ok then
			warn(("[fireproximityprompt] %s"):format(err))
		end
	end

	_env.fireproximityprompt = function(target, opts)
		local o = toOpts(opts)
		local list = {}

		if typeof(target) == "Instance" and target:IsA("ProximityPrompt") then
			list[1] = target
		elseif typeof(target) == "table" then
			for _, v in target do
				if typeof(v) == "Instance" and v:IsA("ProximityPrompt") then
					Insert(list, v)
				end
			end
		else
			return false
		end

		local stagger = tonumber(o.stagger) or 0
		stagger = math.max(0, stagger)
		if stagger <= 0 and #list > 1 then
			stagger = 0.02
		end

		for i, pp in list do
			local d = stagger * (i - 1)
			if d > 0 then
				Delay(d, function()
					fireOne(pp, o)
				end)
			else
				Spawn(fireOne, pp, o)
			end
		end

		return #list > 0
	end
end

if isLimitedExecutor then
	local Players = __lt.cs("Players", cloneref)
	local touchState: { [BasePart]: { [BasePart]: any } } = setmetatable({}, {
		__mode = "k"
	})

	local function snapshot(part: BasePart): TouchSnapshot
		local vel, ang = Vector3.zero, Vector3.zero
		pcall(function()
			vel = part.AssemblyLinearVelocity
			ang = part.AssemblyAngularVelocity
		end)
		local cg = nil
		pcall(function()
			cg = part.CollisionGroupId
		end)
		local anchored = nil
		pcall(function()
			anchored = part.Anchored
		end)
		local massless = nil
		pcall(function()
			massless = part.Massless
		end)
		return {
			CF = part.CFrame,
			VEL = vel,
			ANG = ang,
			CT = part.CanTouch,
			CQ = part.CanQuery,
			CC = part.CanCollide,
			CG = cg,
			AN = anchored,
			MS = massless
		}
	end

	local function restore(part: BasePart?, snap: TouchSnapshot?)
		if not (snap and part and part.Parent) then
			return
		end
		pcall(function()
			part.CFrame = snap.CF
			part.AssemblyLinearVelocity = snap.VEL
			part.AssemblyAngularVelocity = snap.ANG
			part.CanTouch = snap.CT
			part.CanQuery = snap.CQ
			part.CanCollide = snap.CC
			if snap.AN ~= nil then
				part.Anchored = snap.AN
			end
			if snap.MS ~= nil then
				part.Massless = snap.MS
			end
			if snap.CG then
				part.CollisionGroupId = snap.CG
			end
		end)
	end

	local function restoreTouchProps(part: BasePart?, snap: TouchSnapshot?)
		if not (snap and part and part.Parent) then
			return
		end
		pcall(function()
			part.CanTouch = snap.CT
			part.CanQuery = snap.CQ
		end)
	end

	local function getPart(p: any): BasePart?
		if typeof(p) ~= "Instance" or (not p:IsA("BasePart")) then
			return nil
		end
		return p
	end

	local function getRoot(p: BasePart?): BasePart?
		if not p then
			return nil
		end
		local root = nil
		pcall(function()
			root = p.AssemblyRootPart
		end)
		return root or p
	end

	local function getPair(partA: BasePart, partB: BasePart, create: boolean)
		local map = touchState[partA]
		if not map and create then
			map = setmetatable({}, {
				__mode = "k"
			})
			touchState[partA] = map
		end
		return map and map[partB], map
	end

	local function isLocalCharacterPart(part: BasePart): boolean?
		local lp = Players and Players.LocalPlayer
		local char = lp and lp.Character
		return char and part:IsDescendantOf(char)
	end

	local function chooseMover(partA: BasePart, partB: BasePart): (BasePart, BasePart)
		local aLocal = isLocalCharacterPart(partA)
		local bLocal = isLocalCharacterPart(partB)
		if aLocal and not bLocal then
			return partB, partA
		end
		if bLocal and not aLocal then
			return partA, partB
		end
		return partA, partB
	end

	local function setTouchProps(part: BasePart)
		pcall(function()
			if part.CanTouch == false then
				part.CanTouch = true
			end
			if part.CanQuery == false then
				part.CanQuery = true
			end
		end)
	end

	local function moveIntoTouch(mover: BasePart, target: BasePart)
		local root = getRoot(mover)
		if not root then
			return nil
		end
		local rootSnap = snapshot(root)
		local moverSnap = mover == root and rootSnap or snapshot(mover)
		local targetSnap = snapshot(target)
		local offset = root.CFrame:ToObjectSpace(mover.CFrame)
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
		pcall(function()
			root.CanCollide = false
		end)
		pcall(function()
			mover.CanCollide = false
		end)
		setTouchProps(root)
		setTouchProps(mover)
		setTouchProps(target)
		pcall(function()
			root.CFrame = target.CFrame * offset:Inverse()
		end)
		return {
			root = root,
			mover = mover,
			target = target,
			rootSnap = rootSnap,
			moverSnap = moverSnap,
			targetSnap = targetSnap
		}
	end

	_env.firetouchinterest = function(partA, partB, state)
		partA = getPart(partA)
		partB = getPart(partB)
		if not partA or (not partB) then
			return false
		end
		state = tonumber(state) or 0
		state = state == 1 and 1 or 0
		local st, map = getPair(partA, partB, state == 0)
		if state == 0 then
			if not st then
				local mover, target = chooseMover(partA, partB)
				st = moveIntoTouch(mover, target)
				if not st then
					return false
				end
				st.partA = partA
				st.partB = partB
				st.ref = 0
				map[partB] = st
			end
			st.ref += 1
			hb(1)
		else
			if st then
				st.ref -= 1
				if st.ref <= 0 then
					restore(st.root, st.rootSnap)
					if st.mover ~= st.root then
						restore(st.mover, st.moverSnap)
					end
					restoreTouchProps(st.target, st.targetSnap)
					map[partB] = nil
				end
			else
				local reverse, reverseMap = getPair(partB, partA, false)
				if reverse then
					reverse.ref -= 1
					if reverse.ref <= 0 then
						restore(reverse.root, reverse.rootSnap)
						if reverse.mover ~= reverse.root then
							restore(reverse.mover, reverse.moverSnap)
						end
						restoreTouchProps(reverse.target, reverse.targetSnap)
						reverseMap[partA] = nil
					end
				end
			end
			hb(1)
		end
		return true
	end
end
