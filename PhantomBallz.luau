if getgenv().__na_aex then return end
getgenv().__na_aex = true
if game.GameId ~= 4538598064 then return end

local Plrs  = game:GetService("Players")
local RS    = game:GetService("RunService")
local SS    = game:GetService("SoundService")
local TS    = game:GetService("TweenService")
local VIM   = game:GetService("VirtualInputManager")
local RSrv  = game:GetService("ReplicatedStorage")
local WS    = workspace
local Stats = game:GetService("Stats")

local function getPing()
	local net = Stats.Network
	if not net or not net.ServerStatsItem then return 0 end
	local stat = net.ServerStatsItem["Data Ping"] or net.ServerStatsItem["Data Ping (ms)"]
	if not stat then return 0 end
	local ok, v = pcall(function() return stat:GetValue() end)
	if not ok or type(v) ~= "number" then return 0 end
	if v < 0 then v = 0 end
	return v
end

do
	local mas = SS:FindFirstChild("Master")
	local mus = mas and mas:FindFirstChild("Music")
	local gam = mus and mus:FindFirstChild("Game")
	local lob = mus and mus:FindFirstChild("Lobby")
	local main = lob and lob:FindFirstChild("Main")
	if mus and gam and main then
		for _, v in ipairs(gam:GetChildren()) do
			if v:IsA("Sound") then v:Destroy() end
		end

		local ids = {
			"rbxassetid://15448175657",
			"rbxassetid://15448189246",
			"rbxassetid://15492387259",
			"rbxassetid://15492384385",
			"rbxassetid://15619382428",
			"rbxassetid://15619385373",
			"rbxassetid://15933457903",
		}

		local spd = {1, 1.1, 1, 1, 1, 1, 1}
		local MAXV, FADE = 1, 0.35

		local vars = table.create(7)
		for i = 1, 7 do
			local s = Instance.new("Sound")
			s.Name = "Variant" .. i
			s.SoundId = ids[i]
			s.SoundGroup = mus
			s.Looped = false
			s.RollOffMode = Enum.RollOffMode.InverseTapered
			s.PlaybackSpeed = spd[i]
			pcall(function() s.Pitch = spd[i] end)
			s.Volume = 0
			s.Parent = gam
			vars[i] = s
		end

		local function isPlay(s)
			local ok, v = pcall(function() return s.IsPlaying end)
			if ok then return v end
			ok, v = pcall(function() return s.Playing end)
			return ok and v or false
		end

		local tws = setmetatable({}, {__mode = "k"})
		local function twVol(s, v, t)
			if not (s and s.Parent) then return end
			if tws[s] then pcall(function() tws[s]:Cancel() end) end
			local ok, tw = pcall(function()
				return TS:Create(s, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Volume = v})
			end)
			if ok and tw then
				tws[s] = tw
				tw:Play()
			else
				pcall(function() s.Volume = v end)
			end
		end

		local function stopFade(s, t)
			if not (s and s.Parent) then return end
			twVol(s, 0, t)
			task.delay(t, function()
				if not (s and s.Parent) then return end
				pcall(function() s:Stop() end)
				pcall(function() s.Volume = 0 end)
			end)
		end

		local rng = Random.new()
		local function pickNext(lastI)
			if #vars <= 1 then return 1 end
			local i
			repeat i = rng:NextInteger(1, #vars) until i ~= lastI
			return i
		end

		local cur, curI, con, tok = nil, nil, nil, 0

		local function playRand()
			tok += 1
			local my = tok
			if con then con:Disconnect() con = nil end
			local i = pickNext(curI)
			curI = i
			local s = vars[i]
			cur = s
			if not (s and s.Parent) then cur = nil return end
			pcall(function() s:Stop() end)
			pcall(function() s.TimePosition = 0 end)
			pcall(function() s.Volume = 0 end)
			pcall(function() s:Play() end)
			twVol(s, MAXV, 0.45)
			con = s.Ended:Connect(function()
				if tok ~= my then return end
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
					if con then con:Disconnect() con = nil end
					if cur then
						local s = cur
						cur = nil
						stopFade(s, FADE)
					end
					while main.Parent and isPlay(main) do
						task.wait(0.1)
					end
				else
					if not (cur and cur.Parent and isPlay(cur)) then
						playRand()
					end
					task.wait(0.05)
				end
			end
			tok += 1
			if con then con:Disconnect() end
			if cur then stopFade(cur, 0.25) end
		end)
	end
end

do
	local gi
	do
		local ok, mod = pcall(function()
			return require(RSrv:WaitForChild("TS"):WaitForChild("GameInfo"))
		end)
		if ok and mod and mod.GameInfo then
			gi = mod.GameInfo
		end
	end

	local br
	do
		local ok, mod = pcall(function()
			return require(RSrv:WaitForChild("TS"):WaitForChild("BallReplicator"):WaitForChild("BallReplicator"))
		end)
		if ok and mod and mod.BallReplicator then
			br = mod.BallReplicator
		end
	end

	local lp = Plrs.LocalPlayer

	local function getBall()
		if gi and gi.BallModel and gi.BallModel.Parent then
			return gi.BallModel
		end
		return WS:FindFirstChild("GameBall", true) or WS:FindFirstChild("GameBall")
	end

	local function tgtOn()
		local ch = lp.Character
		if ch and ch:FindFirstChild("Highlight") then
			return true
		end
		local t = WS:GetAttribute("GameBallTarget")
		if t == lp.UserId then
			return true
		end
		if br and br.syncData and br.syncData.HighlightTargetPlayerID == lp.UserId then
			return true
		end
		return false
	end

	local function hasHl(obj)
		if not obj then return false end
		local h = obj:FindFirstChildWhichIsA("Highlight", true)
		return h and h.Enabled or false
	end

	local hb
	local function bind(ch)
		if hb then hb:Disconnect() hb = nil end
		local hrp = ch:WaitForChild("HumanoidRootPart", 9e9)

		local ring = Instance.new("Part")
		ring.Name = "__na_ring"
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanTouch = false
		ring.CanQuery = false
		ring.Material = Enum.Material.ForceField
		ring.Transparency = 0.65
		ring.Color = Color3.fromRGB(255, 255, 255)
		ring.Shape = Enum.PartType.Ball
		ring.Size = Vector3.new(10, 10, 10)
		ring.Parent = WS

		local lastPos, lastT = nil, nil
		local vel = Vector3.zero
		local tau = 0.05
		local minR = 9
		local cd = 0.3
		local lastFire = 0
		local flashT = 0

		hb = RS.Heartbeat:Connect(function(dt)
			if not (ch and ch.Parent and hrp and hrp.Parent) then return end

			local b = getBall()
			if not (b and b.Parent) then
				ring.Color = Color3.fromRGB(255, 255, 255)
				return
			end

			local now = tick()
			local bp = b.Position

			local raw
			local okVel, av = pcall(function() return b.AssemblyLinearVelocity end)
			if okVel and typeof(av) == "Vector3" and av.Magnitude > 0.1 then
				raw = av
				vel = av
			else
				if not lastT then
					lastT, lastPos = now, bp
				else
					local dtt = now - lastT
					if dtt > 0 then
						raw = (bp - lastPos) / dtt
						local a = dt / (tau + dt)
						vel = vel + (raw - vel) * a
						lastT, lastPos = now, bp
					end
				end
			end

			local hrpPos = hrp.Position
			local spd = vel.Magnitude

			local pingMs = getPing()
			local pingS = pingMs / 1000
			local lag = math.clamp(pingS, 0, 0.45)

			local baseWin = 0.28
			local win = baseWin + lag
			if spd > 150 then win = win + 0.09 end
			if spd > 300 then win = win + 0.09 end

			local rad = spd * win + 4
			if rad < minR then rad = minR end

			local pre = 5 + math.clamp(pingS * 10, 0, 8)
			local parryRad = rad + pre

			ring.Size = Vector3.new(rad * 2, rad * 2, rad * 2)
			ring.CFrame = CFrame.new(hrpPos)

			local d = (bp - hrpPos).Magnitude
			local dot = vel:Dot(hrpPos - bp)
			local app = dot > 0
			local tgt = tgtOn()
			local ballHl = hasHl(b)
			local ok = tgt and ballHl

			local can = ok and app and spd > 5 and d <= parryRad

			if now - flashT <= 0.12 then
				ring.Color = Color3.fromRGB(255, 60, 60)
			else
				if not ok then
					ring.Color = Color3.fromRGB(255, 255, 255)
				elseif d <= rad then
					ring.Color = Color3.fromRGB(60, 255, 120)
				else
					ring.Color = Color3.fromRGB(255, 200, 60)
				end
			end

			if can and (now - lastFire) >= cd then
				VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)
				VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
				lastFire = now
				flashT = now
			end
		end)

		ch.AncestryChanged:Connect(function(_, p)
			if not p then
				if hb then hb:Disconnect() hb = nil end
				if ring then ring:Destroy() end
			end
		end)
	end

	local lp = Plrs.LocalPlayer
	lp.CharacterAdded:Connect(bind)
	if lp.Character then bind(lp.Character) end
end
