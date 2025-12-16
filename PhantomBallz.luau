if getgenv().__na_aex then return end
getgenv().__na_aex = true
if game.GameId ~= 4538598064 then return end

local Plrs  = game:GetService("Players")
local RS    = game:GetService("RunService")
local SS    = game:GetService("SoundService")
local TS    = game:GetService("TweenService")
local RSrv  = game:GetService("ReplicatedStorage")
local WS    = workspace
local UIS   = game:GetService("UserInputService")

local Net = require(RSrv.TS.Network.Network).Network
local Def = require(RSrv.TS.Abilities.DeflectAbility).DeflectAbility
local PNotif = RSrv:WaitForChild("PromptNotification")

task.spawn(function() PNotif:Fire("super scuffed autoparry loaded 💀💀💀", true) end)

local oAvail;oAvail=hookfunction(Def.IsAvailable,function(self,...)return true end)
local oSend;oSend=hookfunction(Net.CSendEvent,function(self,router,evt,...)
	if router==4.6848415795802784e76 then
		return oSend(self,router,2.933813859058389e76,...)
	end
	return oSend(self,router,evt,...)
end)

local function sendParry()
	if not Net then return end
	Net:CSendEvent(4.6848415795802784e76, 6.8467442838735085e75)
end

local function NADrag(ui, dragui)
	if not dragui then dragui = ui end
	local UISvc = game:GetService("UserInputService")
	local drag
	local dragInput
	local dragStart
	local startPos
	local function upd(input)
		local d = input.Position - dragStart
		local sz = ui.Parent.AbsoluteSize
		local nx = startPos.X.Scale + (d.X / sz.X)
		local ny = startPos.Y.Scale + (d.Y / sz.Y)
		ui.Position = UDim2.new(nx, 0, ny, 0)
	end
	dragui.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			drag = true
			dragStart = input.Position
			startPos = ui.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					drag = false
				end
			end)
		end
	end)
	dragui.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UISvc.InputChanged:Connect(function(input)
		if input == dragInput and drag then
			upd(input)
		end
	end)
	ui.Active = true
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

	local spamOn = false
	local spamConn
	local mobBtn

	local function setSpam(v)
		if spamOn == v then return end
		spamOn = v
		if spamOn then
			if not spamConn and Net then
				spamConn = RS.Stepped:Connect(function()
					sendParry()
				end)
			end
		else
			if spamConn then
				spamConn:Disconnect()
				spamConn = nil
			end
		end
		if mobBtn then
			if spamOn then
				mobBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
				mobBtn.Text = "Parry spam: ON"
			else
				mobBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
				mobBtn.Text = "Parry spam: OFF"
			end
		end
	end

	UIS.InputBegan:Connect(function(inp, gpe)
		if gpe then return end
		if inp.KeyCode == Enum.KeyCode.X then
			setSpam(not spamOn)
		end
	end)

	task.spawn(function()
		if not UIS.TouchEnabled then return end
		local hui = (gethui and gethui()) or game:GetService("CoreGui") or Plrs.LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if not hui then return end

		local gui = Instance.new("ScreenGui")
		gui.Name = "__na_parry_mobile"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = hui

		local holder = Instance.new("Frame")
		holder.Name = "Holder"
		holder.Size = UDim2.fromOffset(200, 48)
		holder.Position = UDim2.new(0.5, -100, 0.75, 0)
		holder.BackgroundTransparency = 1
		holder.Parent = gui

		local b = Instance.new("TextButton")
		b.Name = "Toggle"
		b.Size = UDim2.fromScale(1, 1)
		b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 14
		b.AutoButtonColor = false
		b.Text = "Parry spam: OFF"
		b.Parent = holder

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 18)
		c.Parent = b

		NADrag(holder, b)

		b.MouseButton1Click:Connect(function()
			setSpam(not spamOn)
		end)

		mobBtn = b
	end)

	local hb
	local function bind(ch)
		if hb then hb:Disconnect() hb = nil end
		local hrp = ch:WaitForChild("HumanoidRootPart", 9e9)

		local ring = Instance.new("Part")
		ring.Name = "__ltseverydayyou__VISUALIZER__"
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanTouch = false
		ring.CanQuery = false
		ring.Material = Enum.Material.ForceField
		ring.Transparency = 0.5
		ring.Color = Color3.fromRGB(255, 255, 255)
		ring.Shape = Enum.PartType.Ball
		ring.Size = Vector3.new(10, 10, 10)
		ring.Parent = WS

		local lastPos, lastT = nil, nil
		local vel = Vector3.zero
		local tau = 0.05
		local minR, maxR = 9, 90
		local cd = 0.3
		local lastFire = 0
		local flashT = 0

		hb = RS.Heartbeat:Connect(function(dt)
			if not (ch and ch.Parent and hrp and hrp.Parent) then return end

			local b = getBall()
			if not (b and b.Parent) then
				ring.Color = spamOn and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
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

			local baseWin = 0.32
			local baseOff = 6
			local rad = spd * baseWin + baseOff
			if rad < minR then rad = minR end
			if rad > maxR then rad = maxR end

			local pre = 8
			local parryRad = rad + pre

			ring.Size = Vector3.new(rad * 2, rad * 2, rad * 2)
			ring.CFrame = CFrame.new(hrpPos)

			local d = (bp - hrpPos).Magnitude
			local dot = vel:Dot(hrpPos - bp)
			local app = dot > 0
			local tgt = tgtOn()
			local ok = tgt

			local tImp = 1e6
			if spd > 1 then
				tImp = d / spd
			end

			local can = ok and app and spd > 5 and d <= parryRad and tImp <= 0.35

			if spamOn then
				ring.Color = Color3.fromRGB(255, 0, 0)
			else
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
			end

			if can and (now - lastFire) >= cd then
				sendParry()
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

do
	local del = {"ballhit","slasheffect"}
	local function chk(inst)
		if not inst:IsDescendantOf(workspace) then return end
		local n = inst.Name
		if type(n) ~= "string" then return end
		local l = n:lower()
		for _, k in ipairs(del) do
			if l:find(k, 1, true) then
				pcall(function() inst:Destroy() end)
				break
			end
		end
	end

	for _, d in ipairs(workspace:GetDescendants()) do
		task.defer(chk, d)
	end

	workspace.DescendantAdded:Connect(function(inst)
		task.defer(chk, inst)
	end)
end