local __lt = (function()
	local g = (getgenv and getgenv()) or _G or {}
	local sh = rawget(_G, "shared")
	local host = type(sh) == "table" and sh or (type(g) == "table" and g or nil)

	local function fb()
		return {
			cs = function(n, cr)
				local ok, svc = pcall(game.GetService, game, n)
				if not ok or not svc then
					return nil
				end
				if type(cr) == "function" then
					local ok2, v = pcall(cr, svc)
					if ok2 and v then
						return v
					end
				end
				return svc
			end,
			cm = function(s, m, ...)
				local obj = s
				if type(s) == "string" then
					local ok, svc = pcall(game.GetService, game, s)
					if not ok then
						return nil
					end
					obj = svc
				end
				if typeof(obj) ~= "Instance" and type(obj) ~= "table" then
					return nil
				end
				local fn = obj[m]
				if type(fn) ~= "function" then
					return nil
				end
				local ok, res = pcall(fn, obj, ...)
				if ok then
					return res
				end
				return nil
			end,
		}
	end

	if host then
		local c = rawget(host, "__lt_service_resolver")
		if type(c) == "table" then
			return c
		end
	end

	local out
	local ok = pcall(function()
		local ld = loadstring or load
		if type(ld) ~= "function" then
			error("loader unavailable")
		end
		local src = game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau")
		local fn = ld(src, "@ServiceResolver.luau")
		if type(fn) ~= "function" then
			error("compile failed")
		end
		local t = fn()
		if type(t) ~= "table" then
			error("resolver load failed")
		end
		out = t
	end)

	if not ok or type(out) ~= "table" then
		out = fb()
	end

	if host then
		host.__lt_service_resolver = out
	end

	return out
end)()

local g = (getgenv and getgenv()) or _G or {}
local sh = rawget(_G, "shared")
local host = type(sh) == "table" and sh or (type(g) == "table" and g or nil)

if host and type(host.__lt_af_ctx) == "table" and type(host.__lt_af_ctx.stop) == "function" then
	pcall(host.__lt_af_ctx.stop)
end

local ctx = {
	live = true,
	con = {},
}

if host then
	host.__lt_af_ctx = ctx
end

local function bind(c)
	if c then
		ctx.con[#ctx.con + 1] = c
	end
	return c
end

local function cut(c)
	if c then
		pcall(function()
			c:Disconnect()
		end)
	end
end

local function gt(n)
	local ok, svc = pcall(function()
		return __lt.cs(n, cloneref)
	end)
	if ok and svc then
		return svc
	end
	local ok2, svc2 = pcall(game.GetService, game, n)
	if ok2 then
		if type(cloneref) == "function" then
			local ok3, v = pcall(cloneref, svc2)
			if ok3 and v then
				return v
			end
		end
		return svc2
	end
	return nil
end

local Plr = gt("Players")
local Wsp = gt("Workspace")
local Rsp = gt("ReplicatedStorage")
local Run = gt("RunService")
local Uis = gt("UserInputService")
local Sgui = gt("StarterGui")
local Guis = gt("GuiService")
local Cgui = gt("CoreGui")
local LP = Plr and Plr.LocalPlayer or nil
local MP = Wsp and (Wsp:FindFirstChild("Multiplayer") or Wsp:WaitForChild("Multiplayer", 10)) or nil

local TPD = 0.05
local BTD = 0.05
local SCI = 0.05
local VDY = -50
local EXP = Vector3.new(50, -1, 50)
local JMP = Vector3.new(0, 100, 0)
local PSZ = Vector3.new(24, 2, 24)
local ESY = 5
local LFG = Vector3.new(0, 0, 100)
local RRP = 5
local RRG = 0.3
local EXM = 50

local on = false
local cur = nil
local tok = 0
local aVc
local nCc
local nCd1
local nCd2
local chC
local gui
local btn
local plt
local drag = false
local dPos
local bPos
local cTab = {}

local function alive()
	return ctx.live and LP and LP.Parent and Run ~= nil
end

local function killPlat()
	if plt and plt.Parent then
		pcall(function()
			plt:Destroy()
		end)
	end
	plt = nil
end

local function stop()
	if not ctx.live then
		return
	end
	ctx.live = false
	on = false
	cut(aVc)
	cut(nCc)
	cut(nCd1)
	cut(nCd2)
	cut(chC)
	aVc = nil
	nCc = nil
	nCd1 = nil
	nCd2 = nil
	chC = nil
	for _, c in ipairs(ctx.con) do
		cut(c)
	end
	ctx.con = {}
	cTab = {}
	killPlat()
	if gui and gui.Parent then
		pcall(function()
			gui:Destroy()
		end)
	end
	gui = nil
	btn = nil
end

ctx.stop = stop

local function descOf(obj)
	if not obj then
		return {}
	end
	local q = obj.QueryDescendants
	if type(q) == "function" then
		local ok, res = pcall(q, obj, "Instance")
		if ok and type(res) == "table" then
			return res
		end
	end
	local ok, res = pcall(obj.GetDescendants, obj)
	if ok and type(res) == "table" then
		return res
	end
	return {}
end

local function ffc(obj, n, rec)
	if not obj then
		return nil
	end
	local ok, res = pcall(obj.FindFirstChild, obj, n, rec)
	if ok then
		return res
	end
	return nil
end

local function uiPar()
	if type(gethui) == "function" then
		local ok, ui = pcall(gethui)
		if ok and typeof(ui) == "Instance" then
			return ui
		end
	end
	return Cgui or (LP and LP:FindFirstChildOfClass("PlayerGui")) or nil
end

local Cls = LP and LP:FindFirstChild("PlayerScripts") or nil
local Clm = Cls and Cls:FindFirstChild("CL_MAIN_GameScript") or nil
local cenv = nil

if Clm and type(getsenv) == "function" then
	local ok, env = pcall(getsenv, Clm)
	if ok and type(env) == "table" then
		cenv = env
	end
end

local alert = cenv and cenv.newAlert or nil

local function note(msg)
	msg = tostring(msg)

	if type(alert) == "function" then
		local ok = pcall(alert, msg, nil, nil, "rainbow")
		if ok then
			return
		end
		alert = nil
	end

	if Sgui then
		for _ = 1, 3 do
			local ok = pcall(function()
				Sgui:SetCore("SendNotification", {
					Title = "AutoFarm",
					Text = msg,
					Duration = 3,
				})
			end)
			if ok then
				return
			end
			task.wait(0.15)
		end
	end

	if Guis and type(Guis.SetCore) == "function" then
		pcall(function()
			Guis:SetCore("SendNotification", {
				Title = "AutoFarm",
				Text = msg,
				Duration = 3,
			})
		end)
	end
end

local Lift = nil
do
	local ok, r = pcall(function()
		local rem = Rsp and Rsp:FindFirstChild("Remote")
		if not rem then
			return nil
		end
		return rem:FindFirstChild("dKgyIXnLdhwvSyEorkEWJJAkgUslGCtR") or rem:FindFirstChild("AddedWaiting")
	end)
	Lift = ok and r or nil
end

local function chr(w)
	if not LP then
		return nil
	end
	local c = LP.Character
	if c then
		return c
	end
	if w then
		local ok, res = pcall(function()
			return LP.CharacterAdded:Wait()
		end)
		if ok then
			return res
		end
	end
	return nil
end

local function rh(w)
	local c = chr(w)
	if not c then
		return nil, nil, nil
	end
	local r = c:FindFirstChild("HumanoidRootPart")
	local h = c:FindFirstChildOfClass("Humanoid")
	if w then
		if not r then
			r = c:WaitForChild("HumanoidRootPart", 10)
		end
		if not h then
			h = c:WaitForChild("Humanoid", 10)
		end
	end
	return r, h, c
end

local function inState(nm)
	local r = select(1, rh(false))
	if not r then
		return false
	end
	if nm == "InLift" then
		return r.Position.X < 50 and r.Position.Z > 70
	elseif nm == "InGame" then
		return r.Position.X > 50
	end
	return false
end

local function isRand(s)
	if type(s) ~= "string" or #s == 0 then
		return false
	end
	for i = 1, #s do
		local c = s:sub(i, i)
		if c:lower() == c then
			return false
		end
	end
	return true
end

local function mkPlat(r)
	local c = chr(false)
	if not c or not r or not r.Parent then
		return
	end
	local ok, cf, sz = pcall(c.GetBoundingBox, c)
	if not ok or not cf or not sz then
		return
	end
	local y = cf.Position.Y - sz.Y / 2
	if not (plt and plt.Parent) then
		local p = Instance.new("Part")
		p.Name = "AF_SafePlatform"
		p.Size = PSZ
		p.Anchored = true
		p.CanCollide = true
		p.Transparency = 1
		p.CFrame = CFrame.new(r.Position.X, y - PSZ.Y / 2 - 0.05, r.Position.Z)
		p.Parent = Wsp
		plt = p
	else
		plt.CFrame = CFrame.new(r.Position.X, y - PSZ.Y / 2 - 0.05, r.Position.Z)
	end
end

local function anyPart(obj)
	if not obj then
		return nil
	end
	if obj:IsA("BasePart") then
		return obj
	end
	if obj:IsA("Model") then
		if obj.PrimaryPart then
			return obj.PrimaryPart
		end
		for _, d in ipairs(descOf(obj)) do
			if d:IsA("BasePart") then
				return d
			end
		end
	end
	return nil
end

local function moveTo(obj, r)
	if not obj or not r or not r.Parent then
		return
	end
	local p = anyPart(obj)
	if not p then
		return
	end
	if obj:IsA("Model") then
		pcall(function()
			if obj.PrimaryPart then
				obj:SetPrimaryPartCFrame(r.CFrame)
			else
				obj:PivotTo(r.CFrame)
			end
		end)
	else
		p.CFrame = r.CFrame
	end
end

local function findLow(map, name)
	name = tostring(name):lower()
	for _, obj in ipairs(descOf(map)) do
		local nm = obj.Name
		if type(nm) == "string" and nm:lower() == name then
			return obj
		end
	end
	return nil
end

local function scanBtns(map)
	local t = {}
	for _, obj in ipairs(descOf(map)) do
		if obj.ClassName == "Model" and isRand(obj.Name) then
			local hit = nil
			for _, ch in ipairs(obj:GetChildren()) do
				if ch:IsA("BasePart") and tostring(ch.BrickColor) ~= "Medium stone grey" then
					hit = ch
					break
				end
			end
			if hit and isRand(hit.Name) then
				hit.Name = "Hitbox"
				t[#t + 1] = obj
			end
		end
	end
	return t
end

local function addNc(obj)
	if obj and obj:IsA("BasePart") then
		cTab[obj] = true
	end
end

local function clrNc()
	cTab = {}
	cut(nCd1)
	cut(nCd2)
	nCd1 = nil
	nCd2 = nil
end

local function bindNc(c)
	clrNc()
	if not c then
		return
	end
	addNc(c)
	for _, d in ipairs(descOf(c)) do
		addNc(d)
	end
	nCd1 = c.DescendantAdded:Connect(function(d)
		addNc(d)
	end)
	nCd2 = c.DescendantRemoving:Connect(function(d)
		cTab[d] = nil
	end)
end

local function setNc(v)
	cut(nCc)
	nCc = nil
	clrNc()
	if not v or not Run or not LP then
		return
	end
	bindNc(LP.Character)
	nCc = Run.PreSimulation:Connect(function()
		if not on then
			return
		end
		for p in pairs(cTab) do
			if p and p.Parent then
				p.CanCollide = false
			else
				cTab[p] = nil
			end
		end
	end)
end

local function pushLift()
	local r = select(1, rh(true))
	if not r then
		return
	end
	pcall(function()
		r.CFrame = r.CFrame + Vector3.new(0, 5, 0)
	end)
	while alive() and on and not inState("InLift") do
		task.wait(0.1)
		local rr = select(1, rh(false))
		if not rr then
			continue
		end
		rr.AssemblyLinearVelocity = LFG
		mkPlat(rr)
	end
end

local function doLift()
	if not Lift then
		return
	end
	pcall(function()
		Lift:FireServer()
	end)
	task.spawn(function()
		local ok, err = xpcall(pushLift, debug.traceback)
		if not ok then
			warn(err)
		end
	end)
end

local function antiVoid(getMap)
	cut(aVc)
	aVc = nil
	if not Run then
		return
	end
	aVc = Run.Heartbeat:Connect(function()
		if not on then
			return
		end
		local r = select(1, rh(false))
		if not r then
			return
		end
		if r.Position.Y >= VDY then
			return
		end
		local map = nil
		local ok, res = pcall(getMap)
		if ok then
			map = res
		end
		if map and map.Parent then
			local ok2, cf, sz = pcall(map.GetBoundingBox, map)
			if ok2 and cf and sz then
				pcall(function()
					r.CFrame = CFrame.new(cf.Position + Vector3.new(0, sz.Y / 2 + 8, 0))
				end)
				mkPlat(r)
				note("Recovered from void")
			end
		end
	end)
end

local function setBtn()
	if not btn then
		return
	end
	btn.Text = on and "Stop AutoFarm" or "Start AutoFarm"
	btn.BackgroundColor3 = on and Color3.fromRGB(180, 60, 60) or Color3.fromRGB(60, 180, 60)
end

local function toggle(v)
	on = v and true or false
	setBtn()
	note(on and "Enabled" or "Disabled")
	setNc(on)

	if not on then
		local r = select(1, rh(false))
		if r then
			pcall(function()
				r.Anchored = false
			end)
		end
		killPlat()
		return
	end

	doLift()
end

local function onChar(c)
	if not alive() then
		return
	end
	bindNc(c)
	task.spawn(function()
		if Lift then
			for _ = 1, RRP do
				if not alive() then
					return
				end
				pcall(function()
					Lift:FireServer()
				end)
				task.wait(RRG)
			end
		end
	end)
	if on then
		task.spawn(function()
			local ok, err = xpcall(pushLift, debug.traceback)
			if not ok then
				warn(err)
			end
		end)
	end
end

local function onMap(map, id)
	local hp
	local ok, err = xpcall(function()
		local r, h = rh(true)
		if not r or not h or not map or not map.Parent then
			return
		end

		local st = ffc(map, "Settings", false)
		local nm = nil
		if st then
			local ok2, v = pcall(function()
				return st:GetAttribute("MapName")
			end)
			if ok2 then
				nm = v
			end
		end
		if not nm then
			nm = map.Name
		end

		note("Map Loaded! " .. tostring(nm))

		if not inState("InGame") then
			note("Skipping due to InGame == false.")
			return
		end

		local btns = {}
		local ok2, res = pcall(scanBtns, map)
		if ok2 and type(res) == "table" then
			btns = res
		end

		local pg = findLow(map, "_lostpage")
		if pg then
			moveTo(pg, r)
			task.wait(TPD)
			note("Got Lost Page.")
		end

		local ct = findLow(map, "contact")
		if not ct then
			local npc = findLow(map, "npc")
			if npc and npc.Parent then
				ct = npc.Parent:FindFirstChild("Contact") or findLow(map, "contact")
			end
		end
		if ct then
			moveTo(ct, r)
			task.wait(TPD)
			note("Got Escapee.")
		end

		note("Commencing Auto Farm")

		hp = h:GetPropertyChangedSignal("Health"):Connect(function()
			pcall(function()
				if h.Parent and h.Health < 1000 then
					h.Health = 1000
				end
			end)
		end)

		local tr = 0

		while alive() and on and cur == map and map.Parent and inState("InGame") and tok == id do
			task.wait(SCI)

			r, h = rh(false)
			if not r or not h then
				continue
			end

			pcall(function()
				h.Jump = true
			end)

			local ex = ffc(map, "ExitRegion", true)

			if not ex then
				for _, b in ipairs(btns) do
					if not (alive() and on and cur == map and map.Parent and tok == id) then
						break
					end

					local hit = ffc(b, "Hitbox", false)
					if hit then
						local ti = ffc(b, "TouchInterest", true)
						local gg = b:FindFirstChildWhichIsA("BillboardGui", true)
						if ti and gg then
							r, h = rh(false)
							if not r or not h then
								break
							end
							pcall(function()
								r.Anchored = false
								r.CFrame = CFrame.new(hit.Position)
								h:ChangeState(Enum.HumanoidStateType.Jumping)
								r.Velocity = JMP
							end)
							task.wait(TPD)
							pcall(function()
								r.CFrame = CFrame.new(hit.Position + Vector3.new(0, ESY, 0))
								r.Anchored = true
							end)
							task.wait(BTD)
						end
					end
				end
			else
				pcall(function()
					r.Anchored = false
				end)
				if tr < EXM then
					tr += 1
					pcall(function()
						r.CFrame = ex.CFrame
						h:ChangeState(Enum.HumanoidStateType.Landed)
						r.Velocity = EXP
					end)
					mkPlat(r)
					task.wait(TPD)
					if (r.Position - ex.Position).Magnitude <= 5 then
						tr += 1
					end
				else
					tr = 0
					mkPlat(r)
					task.wait(TPD)
				end
			end
		end
	end, debug.traceback)

	cut(hp)

	if not ok then
		warn(err)
		note("Map handler error; continuing")
	end

	local r = select(1, rh(false))
	if r then
		mkPlat(r)
	end

	if not (alive() and on) then
		return
	end

	note("Complete. Waiting for next map..")

	while alive() and on do
		task.wait(0.2)
		local m = MP and MP:FindFirstChild("Map") or nil
		local rr = select(1, rh(false))
		if rr then
			mkPlat(rr)
		end
		if m and m ~= map then
			break
		end
	end
end

local function curMap()
	if not MP or not MP.Parent then
		MP = Wsp and (Wsp:FindFirstChild("Multiplayer") or Wsp:WaitForChild("Multiplayer", 3)) or nil
	end
	return MP and MP:FindFirstChild("Map") or nil
end

local function mkUi()
	local par = uiPar()
	if not par then
		return
	end

	local old = ffc(par, "AF_Toggle", false)
	if old then
		pcall(function()
			old:Destroy()
		end)
	end

	gui = Instance.new("ScreenGui")
	gui.Name = "AF_Toggle"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = par

	btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 160, 0, 50)
	btn.Position = UDim2.new(0.5, -80, 0, 10)
	btn.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextSize = 20
	btn.Text = "Start AutoFarm"
	btn.Active = true
	btn.Parent = gui

	bind(btn.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			drag = true
			dPos = i.Position
			bPos = btn.Position
		end
	end))

	if Uis then
		bind(Uis.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				drag = false
			end
		end))

		bind(Uis.InputChanged:Connect(function(i)
			if not drag then
				return
			end
			if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			if not dPos or not bPos or not btn then
				return
			end
			local d = i.Position - dPos
			btn.Position = UDim2.new(bPos.X.Scale, bPos.X.Offset + d.X, bPos.Y.Scale, bPos.Y.Offset + d.Y)
		end))
	end

	bind(btn.MouseButton1Click:Connect(function()
		toggle(not on)
	end))

	setBtn()
end

mkUi()

if LP then
	chC = LP.CharacterAdded:Connect(onChar)
	if LP.Character then
		task.spawn(onChar, LP.Character)
	end
end

antiVoid(curMap)
note("Ready")

task.spawn(function()
	while alive() do
		local ok, err = xpcall(function()
			task.wait(SCI)
			if not on then
				return
			end
			local m = curMap()
			if m and m ~= cur then
				cur = m
				tok += 1
				local id = tok
				note("New Map")
				onMap(m, id)
			elseif not m then
				cur = nil
			end
		end, debug.traceback)

		if not ok then
			warn(err)
			note("Loop error; continuing")
			task.wait(0.25)
		end
	end
end)