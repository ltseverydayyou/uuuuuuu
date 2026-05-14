local ctx = {}

ctx.plrs = game:GetService("Players")
ctx.rs = game:GetService("ReplicatedStorage")
ctx.uis = game:GetService("UserInputService")
ctx.run = game:GetService("RunService")
ctx.lp = ctx.plrs.LocalPlayer
ctx.name = "killaura"
ctx.max = 32
ctx.on = false
ctx.idx = 1
ctx.dead = false
ctx.cons = {}
ctx.rate = 0.035
ctx.scanRate = 0.045
ctx.burst = 6
ctx.maxFly = 3
ctx.fly = 0
ctx.nextHit = os.clock()
ctx.nextScan = 0
ctx.tar = nil

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
ctx.f.Size = UDim2.new(0, 80, 0, 80)
ctx.f.Position = UDim2.new(0.85, 0, 0.7, 0)
ctx.f.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ctx.f.BorderSizePixel = 0
ctx.f.Active = true
ctx.f.Parent = ctx.sg

ctx.fc = Instance.new("UICorner")
ctx.fc.CornerRadius = UDim.new(0, 12)
ctx.fc.Parent = ctx.f

ctx.b = Instance.new("TextButton")
ctx.b.Size = UDim2.new(0.8, 0, 0.8, 0)
ctx.b.Position = UDim2.new(0.1, 0, 0.1, 0)
ctx.b.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
ctx.b.BorderSizePixel = 0
ctx.b.Font = Enum.Font.GothamBold
ctx.b.Text = "K"
ctx.b.TextColor3 = Color3.fromRGB(255, 255, 255)
ctx.b.TextSize = 28
ctx.b.Parent = ctx.f

ctx.bc = Instance.new("UICorner")
ctx.bc.CornerRadius = UDim.new(0, 8)
ctx.bc.Parent = ctx.b

ctx.set = function(v)
	ctx.on = v == true
	ctx.nextHit = os.clock()
	ctx.nextScan = 0
	ctx.tar = nil

	if ctx.b then
		ctx.b.Text = ctx.on and "ON" or "K"
		ctx.b.BackgroundColor3 = ctx.on and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(200, 60, 60)
	end
end

ctx.toggle = function()
	ctx.set(not ctx.on)
end

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

ctx.near = function()
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

	local fold = workspace:FindFirstChild("Entities")
	if fold then
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
	end

	return best
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

	if isEvent then
		pcall(function()
			r:FireServer(t, idx)
		end)
		return
	end

	ctx.fly += 1

	task.spawn(function()
		pcall(function()
			r:InvokeServer(t, idx)
		end)

		ctx.fly = math.max(ctx.fly - 1, 0)
	end)
end

ctx.pulse = function()
	local now = os.clock()

	if now >= ctx.nextScan or not ctx.goodtar(ctx.tar) then
		ctx.nextScan = now + ctx.scanRate
		ctx.tar = ctx.near()
	end

	local n = 0

	while ctx.on and not ctx.dead and now >= ctx.nextHit and n < ctx.burst do
		if ctx.goodtar(ctx.tar) then
			ctx.hit(ctx.tar)
		else
			ctx.tar = ctx.near()
			if ctx.goodtar(ctx.tar) then
				ctx.hit(ctx.tar)
			end
		end

		ctx.nextHit += ctx.rate
		n += 1
	end

	if now - ctx.nextHit > 1 then
		ctx.nextHit = now
	end
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

ctx.bind(ctx.ev.Event, ctx.clean)

ctx.bind(ctx.b.Activated, ctx.toggle)

ctx.bind(ctx.uis.InputBegan, function(i, gp)
	if gp then
		return
	end

	if i.KeyCode == Enum.KeyCode.K then
		ctx.toggle()
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

ctx.bind(ctx.run.PreSimulation, function()
	if not ctx.on or ctx.dead then
		return
	end

	ctx.pulse()
end)

ctx.set(false)