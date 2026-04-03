local gEnv = getgenv and getgenv()
if type(gEnv) ~= "table" then
	gEnv = _G
end

local __lt = (function()
	local globalEnv = gEnv or _G or {}
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

if gEnv.__na_aex then
	return
end
gEnv.__na_aex = true

if game.GameId ~= 4538598064 then
	return
end

local Plrs = __lt.cs("Players", cloneref)
local Run = __lt.cs("RunService", cloneref)
local SS = __lt.cs("SoundService", cloneref)
local TS = __lt.cs("TweenService", cloneref)
local RSrv = __lt.cs("ReplicatedStorage", cloneref)
local UIS = __lt.cs("UserInputService", cloneref)
local SG = __lt.cs("StarterGui", cloneref)
local WS = workspace

local lp = Plrs.LocalPlayer
if not lp then
	gEnv.__na_aex = nil
	return
end

local Net = (require(RSrv.TS.Network.Network)).Network
local Def = (require(RSrv.TS.Abilities.DeflectAbility)).DeflectAbility
local PNotif = __lt.cm("ReplicatedStorage", "FindFirstChild", "PromptNotification")

local PARRY_ROUTER = 46848415795802784000000000000000000000000000000000000000000000000000000000000
local PARRY_EVT = 6846744283873508500000000000000000000000000000000000000000000000000000000000

local oAvail
oAvail = hookfunction(Def.IsAvailable, function(self, ...)
	return true
end)

local oSend
oSend = hookfunction(Net.CSendEvent, function(self, router, evt, ...)
	if router == PARRY_ROUTER then
		return oSend(self, router, 29338138590583890000000000000000000000000000000000000000000000000000000000000, ...)
	end
	return oSend(self, router, evt, ...)
end)

local function notify(txt, okv)
	task.defer(function()
		if PNotif then
			local ok = pcall(function()
				PNotif:Fire(txt, okv)
			end)
			if ok then
				return
			end
		end
		pcall(function()
			SG:SetCore("SendNotification", {
				Title = "Nameless Admin",
				Text = tostring(txt),
				Duration = 4
			})
		end)
	end)
end

local function sendParry()
	if not Net then
		return
	end
	pcall(function()
		Net:CSendEvent(PARRY_ROUTER, PARRY_EVT)
	end)
end

notify("super scuffed autoparry loaded 💀💀💀", true)

do
	local mas = __lt.cm("SoundService", "FindFirstChild", "Master")
	local mus = mas and mas:FindFirstChild("Music")
	local gam = mus and mus:FindFirstChild("Game")
	local lob = mus and mus:FindFirstChild("Lobby")
	local main = lob and lob:FindFirstChild("Main")

	if mus and gam and main then
		for _, v in ipairs(gam:GetChildren()) do
			if v:IsA("Sound") then
				pcall(function()
					v:Destroy()
				end)
			end
		end

		local ids = {
			"rbxassetid://15448175657",
			"rbxassetid://15448189246",
			"rbxassetid://15492387259",
			"rbxassetid://15492384385",
			"rbxassetid://15619382428",
			"rbxassetid://15619385373",
			"rbxassetid://15933457903"
		}

		local spd = {1, 1.1, 1, 1, 1, 1, 1}
		local MAXV = 1
		local FADE = 0.35
		local vars = table.create(#ids)

		for i = 1, #ids do
			local s = Instance.new("Sound")
			s.Name = "Variant" .. i
			s.SoundId = ids[i]
			s.SoundGroup = mus
			s.Looped = false
			s.RollOffMode = Enum.RollOffMode.InverseTapered
			s.PlaybackSpeed = spd[i]
			pcall(function()
				s.Pitch = spd[i]
			end)
			s.Volume = 0
			s.Parent = gam
			vars[i] = s
		end

		local function isPlay(s)
			if not s or not s.Parent then
				return false
			end
			local ok, v = pcall(function()
				return s.IsPlaying
			end)
			if ok then
				return v
			end
			ok, v = pcall(function()
				return s.Playing
			end)
			return ok and v or false
		end

		local tws = {}

		local function twVol(s, v, t)
			if not (s and s.Parent) then
				return
			end

			local old = tws[s]
			if old then
				pcall(function()
					old:Cancel()
				end)
			end

			local ok, tw = pcall(function()
				return TS:Create(s, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Volume = v
				})
			end)

			if ok and tw then
				tws[s] = tw
				tw.Completed:Once(function()
					if tws[s] == tw then
						tws[s] = nil
					end
				end)
				tw:Play()
			else
				pcall(function()
					s.Volume = v
				end)
			end
		end

		local function stopFade(s, t)
			if not (s and s.Parent) then
				return
			end
			twVol(s, 0, t)
			task.delay(t, function()
				if not (s and s.Parent) then
					return
				end
				pcall(function()
					s:Stop()
				end)
				pcall(function()
					s.Volume = 0
				end)
			end)
		end

		local rng = Random.new()
		local cur, curI, con, tok = nil, nil, nil, 0

		local function clearEnded()
			if con then
				con:Disconnect()
				con = nil
			end
		end

		local function pickNext(lastI)
			if #vars <= 1 then
				return 1
			end
			local i
			repeat
				i = rng:NextInteger(1, #vars)
			until i ~= lastI
			return i
		end

		local function playRand()
			tok += 1
			local my = tok
			clearEnded()

			local i = pickNext(curI)
			curI = i
			local s = vars[i]
			cur = s

			if not (s and s.Parent) then
				cur = nil
				return
			end

			pcall(function()
				s:Stop()
				s.TimePosition = 0
				s.Volume = 0
				s:Play()
			end)

			twVol(s, MAXV, 0.45)

			con = s.Ended:Connect(function()
				if tok ~= my then
					return
				end
				if main.Parent and not isPlay(main) then
					playRand()
				else
					cur = nil
				end
			end)
		end

		task.spawn(function()
			while main.Parent do
				if isPlay(main) then
					tok += 1
					clearEnded()

					if cur then
						local s = cur
						cur = nil
						stopFade(s, FADE)
					end

					repeat
						task.wait(0.1)
					until not (main.Parent and isPlay(main))
				else
					if not (cur and cur.Parent and isPlay(cur)) then
						playRand()
					end
					task.wait(0.05)
				end
			end

			tok += 1
			clearEnded()
			if cur then
				stopFade(cur, 0.25)
			end
		end)
	end
end

local gi
do
	local ok, mod = pcall(function()
		return require((__lt.cm("ReplicatedStorage", "WaitForChild", "TS")):WaitForChild("GameInfo"))
	end)
	if ok and mod and mod.GameInfo then
		gi = mod.GameInfo
	end
end

local br
do
	local ok, mod = pcall(function()
		return require(((__lt.cm("ReplicatedStorage", "WaitForChild", "TS")):WaitForChild("BallReplicator")):WaitForChild("BallReplicator"))
	end)
	if ok and mod and mod.BallReplicator then
		br = mod.BallReplicator
	end
end

local cfg = {
	spam = false,
	vis = true,
	fx = true
}

local white = Color3.fromRGB(255, 255, 255)
local red = Color3.fromRGB(255, 0, 0)
local softRed = Color3.fromRGB(255, 60, 60)
local green = Color3.fromRGB(60, 255, 120)
local yellow = Color3.fromRGB(255, 200, 60)

local simConn
local spamConn
local ancConn
local charConn
local fxConn
local ring
local mob
local syncIcon = false
local bindId = 0
local dead = false

local delMap = {
	ballhit = true,
	slasheffect = true
}

local function disc(c)
	if c then
		c:Disconnect()
	end
	return nil
end

local function kill(o)
	if o then
		pcall(function()
			o:Destroy()
		end)
	end
	return nil
end

local function getBall()
	local bm = gi and gi.BallModel
	if bm and bm.Parent then
		return bm
	end
	return WS:FindFirstChild("GameBall", true) or WS:FindFirstChild("GameBall")
end

local function tgtOn(ch)
	if ch and ch:FindFirstChild("Highlight") then
		return true
	end

	local t = WS:GetAttribute("GameBallTarget")
	if t == lp.UserId then
		return true
	end

	local sd = br and br.syncData
	if sd and sd.HighlightTargetPlayerID == lp.UserId then
		return true
	end

	return false
end

local function setRingOn(v)
	if ring and ring.Parent then
		ring.Transparency = v and 0.5 or 1
	end
end

local function updIcons()
	if not mob then
		return
	end

	syncIcon = true

	if mob.spam then
		mob.spam:setLabel(cfg.spam and "Spam: ON" or "Spam: OFF")
		if cfg.spam then
			mob.spam:select("Sync", mob.spam)
		else
			mob.spam:deselect("Sync", mob.spam)
		end
	end

	if mob.vis then
		mob.vis:setLabel(cfg.vis and "Visualizer: ON" or "Visualizer: OFF")
		if cfg.vis then
			mob.vis:select("Sync", mob.vis)
		else
			mob.vis:deselect("Sync", mob.vis)
		end
	end

	if mob.fx then
		mob.fx:setLabel(cfg.fx and "FX Clean: ON" or "FX Clean: OFF")
		if cfg.fx then
			mob.fx:select("Sync", mob.fx)
		else
			mob.fx:deselect("Sync", mob.fx)
		end
	end

	setRingOn(cfg.vis)

	syncIcon = false
end

local function setSpam(v)
	if cfg.spam == v then
		updIcons()
		return
	end

	cfg.spam = v

	if cfg.spam then
		if not spamConn then
			spamConn = Run.PreSimulation:Connect(function()
				sendParry()
			end)
		end
	else
		spamConn = disc(spamConn)
	end

	updIcons()
end

local function setVis(v)
	cfg.vis = v and true or false
	setRingOn(cfg.vis)
	updIcons()
end

local function setFx(v)
	cfg.fx = v and true or false
	updIcons()
end

local function clearBind()
	bindId += 1
	simConn = disc(simConn)
	ancConn = disc(ancConn)
	ring = kill(ring)
end

local function makeRing()
	local p = Instance.new("Part")
	p.Name = "__ltseverydayyou__VISUALIZER__"
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = Enum.Material.ForceField
	p.Transparency = cfg.vis and 0.5 or 1
	p.Color = white
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(10, 10, 10)
	p.Parent = WS
	return p
end

local function bind(ch)
	clearBind()

	if dead or not (ch and ch.Parent) then
		return
	end

	local myId = bindId
	local hrp = ch:FindFirstChild("HumanoidRootPart") or ch:WaitForChild("HumanoidRootPart", 9e9)
	if myId ~= bindId or not (hrp and hrp.Parent) then
		return
	end

	ring = makeRing()

	local lastPos
	local lastT
	local vel = Vector3.zero
	local tau = 0.05
	local minR = 9
	local maxR = 90
	local cd = 0.3
	local lastFire = 0
	local flashT = 0

	local ball
	local ballAt = 0
	local ballCd = 0.03

	simConn = Run.PreSimulation:Connect(function(dt)
		if dead or myId ~= bindId then
			return
		end

		if not (ch.Parent and hrp.Parent and ring and ring.Parent) then
			clearBind()
			return
		end

		local now = os.clock()

		if not (ball and ball.Parent) or now - ballAt >= ballCd then
			ball = getBall()
			ballAt = now
		end

		if not (ball and ball.Parent) then
			ring.Color = cfg.spam and red or white
			ring.CFrame = CFrame.new(hrp.Position)
			return
		end

		local bp = ball.Position
		local raw
		local okVel, av = pcall(function()
			return ball.AssemblyLinearVelocity
		end)

		if okVel and typeof(av) == "Vector3" and av.Magnitude > 0.1 then
			raw = av
			vel = av
			lastPos = bp
			lastT = now
		else
			if lastPos and lastT then
				local dtt = now - lastT
				if dtt > 0 then
					raw = (bp - lastPos) / dtt
					local a = dt / (tau + dt)
					vel = vel + (raw - vel) * a
				end
			end
			lastPos = bp
			lastT = now
		end

		local hrpPos = hrp.Position
		local spd = vel.Magnitude
		local rad = spd * 0.32 + 6

		if rad < minR then
			rad = minR
		elseif rad > maxR then
			rad = maxR
		end

		local parryRad = rad + 8
		ring.Size = Vector3.new(rad * 2, rad * 2, rad * 2)
		ring.CFrame = CFrame.new(hrpPos)

		local off = hrpPos - bp
		local d = off.Magnitude
		local app = vel:Dot(off) > 0
		local ok = tgtOn(ch)

		local tImp = 1e6
		if spd > 1 then
			tImp = d / spd
		end

		local can = ok and app and spd > 5 and d <= parryRad and tImp <= 0.35

		if cfg.spam then
			ring.Color = red
		elseif now - flashT <= 0.12 then
			ring.Color = softRed
		elseif not ok then
			ring.Color = white
		elseif d <= rad then
			ring.Color = green
		else
			ring.Color = yellow
		end

		if can and now - lastFire >= cd then
			lastFire = now
			flashT = now
			task.defer(sendParry)
		end
	end)

	ancConn = ch.AncestryChanged:Connect(function(_, p)
		if not p then
			clearBind()
		end
	end)
end

UIS.InputBegan:Connect(function(inp, gpe)
	if gpe then
		return
	end

	local kc = inp.KeyCode
	if kc == Enum.KeyCode.X then
		setSpam(not cfg.spam)
	elseif kc == Enum.KeyCode.Z then
		setVis(not cfg.vis)
	elseif kc == Enum.KeyCode.C then
		setFx(not cfg.fx)
	end
end)

task.spawn(function()
	local ok, Icon = pcall(function()
		return (loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Icon.luau")))()
	end)

	if not ok or not Icon then
		warn("Failed to load topbar icons")
		return
	end

	local root = Icon.new()
		:setName("AEXRoot")
		:setLabel("Auto Parry")
		:autoDeselect(false)

	local spam = Icon.new()
		:setName("ParrySpam")
		:setLabel("Spam: OFF")
		:autoDeselect(false)

	local vis = Icon.new()
		:setName("ParryVis")
		:setLabel("Visualizer: ON")
		:autoDeselect(false)

	local fx = Icon.new()
		:setName("ParryFx")
		:setLabel("FX Clean: ON")
		:autoDeselect(false)

	root:setDropdown({
		spam,
		vis,
		fx
	})

	spam.selected:Connect(function()
		if syncIcon then
			return
		end
		setSpam(true)
	end)

	spam.deselected:Connect(function()
		if syncIcon then
			return
		end
		setSpam(false)
	end)

	vis.selected:Connect(function()
		if syncIcon then
			return
		end
		setVis(true)
	end)

	vis.deselected:Connect(function()
		if syncIcon then
			return
		end
		setVis(false)
	end)

	fx.selected:Connect(function()
		if syncIcon then
			return
		end
		setFx(true)
	end)

	fx.deselected:Connect(function()
		if syncIcon then
			return
		end
		setFx(false)
	end)

	if root.addToJanitor then
		root:addToJanitor(function()
			dead = true
			clearBind()
			spamConn = disc(spamConn)
			charConn = disc(charConn)
			fxConn = disc(fxConn)
		end)
	end

	mob = {
		root = root,
		spam = spam,
		vis = vis,
		fx = fx
	}

	updIcons()
end)

charConn = lp.CharacterAdded:Connect(function(ch)
	task.defer(bind, ch)
end)

if lp.Character then
	task.defer(bind, lp.Character)
end

do
	local function chk(inst)
		if dead or not cfg.fx then
			return
		end

		if not inst or not inst.Parent then
			return
		end

		if not inst:IsDescendantOf(WS) then
			return
		end

		local n = inst.Name
		if type(n) ~= "string" or n == "" then
			return
		end

		local l = n:lower()
		if delMap[l] or l:find("ballhit", 1, true) or l:find("slasheffect", 1, true) then
			pcall(function()
				inst:Destroy()
			end)
		end
	end

	for _, d in ipairs(WS:GetDescendants()) do
		task.defer(chk, d)
	end

	fxConn = WS.DescendantAdded:Connect(function(inst)
		task.defer(chk, inst)
	end)
end