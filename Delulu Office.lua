local ENV = (getgenv and getgenv()) or _G
local KEY = "__vyperia_reworked"

local old = type(ENV) == "table" and rawget(ENV, KEY)
if type(old) == "table" and type(old.clean) == "function" then
	pcall(old.clean)
end

local st = {
	alive = true,
	cons = {},
	objs = {},
	ths = {},
}

if type(ENV) == "table" then
	ENV[KEY] = st
end

local function add(c)
	if c then
		st.cons[#st.cons + 1] = c
	end
	return c
end

local function obj(o)
	if o then
		st.objs[#st.objs + 1] = o
	end
	return o
end

local function go(fn)
	local th = task.spawn(function()
		local ok, er = pcall(fn)
		if not ok then
			warn(er)
		end
	end)
	st.ths[#st.ths + 1] = th
	return th
end

local function dc(c)
	pcall(function()
		if c and c.Connected ~= false then
			c:Disconnect()
		end
	end)
end

local function cleanTbl(t)
	for i = #t, 1, -1 do
		local v = t[i]
		t[i] = nil
		if typeof(v) == "RBXScriptConnection" then
			dc(v)
		elseif typeof(v) == "Instance" then
			pcall(function()
				v:Destroy()
			end)
		elseif type(v) == "thread" then
			pcall(task.cancel, v)
		end
	end
end

function st.clean()
	if not st.alive then
		return
	end
	st.alive = false
	local hk = type(ENV) == "table" and rawget(ENV, "__vyperia_dmg_hook")
	if type(hk) == "table" then
		hk.d = nil
	end
	cleanTbl(st.cons)
	cleanTbl(st.objs)
	cleanTbl(st.ths)
	if type(ENV) == "table" and rawget(ENV, KEY) == st then
		ENV[KEY] = nil
	end
end

local function resolver()
	local sharedEnv = rawget(_G, "shared")
	local host = type(sharedEnv) == "table" and sharedEnv or (type(ENV) == "table" and ENV or nil)
	if host then
		local cached = rawget(host, "__lt_service_resolver")
		if type(cached) == "table" then
			return cached
		end
	end
	local loader = loadstring or load
	if type(loader) ~= "function" then
		return nil
	end
	local ok, src = pcall(function()
		return game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau")
	end)
	if not ok or type(src) ~= "string" then
		return nil
	end
	local ok2, fn = pcall(loader, src, "@ServiceResolver.luau")
	if not ok2 or type(fn) ~= "function" then
		return nil
	end
	local ok3, ret = pcall(fn)
	if ok3 and type(ret) == "table" then
		if host then
			host.__lt_service_resolver = ret
		end
		return ret
	end
	return nil
end

local __lt = resolver()

local function S(n)
	if __lt and type(__lt.cs) == "function" then
		local ok, r = pcall(__lt.cs, n, cloneref)
		if ok and r then
			return r
		end
	end
	local ok, r = pcall(game.GetService, game, n)
	if ok then
		return r
	end
end

local function CM(s, m, ...)
	if __lt and type(__lt.cm) == "function" then
		local ok, r = pcall(__lt.cm, s, m, ...)
		if ok then
			return r
		end
	end
	local svc = S(s)
	if svc and type(svc[m]) == "function" then
		local ok, r = pcall(svc[m], svc, ...)
		if ok then
			return r
		end
	end
end

local G = 6352299542
if game.GameId ~= G then
	st.clean()
	return
end

local RS = S("ReplicatedStorage")
local PS = S("Players")
local RV = S("RunService")
local UIS = S("UserInputService")
local TS = S("TweenService")
local CG = S("CoreGui")
local P = PS and (PS.LocalPlayer or PS.PlayerAdded:Wait())
if not P then
	st.clean()
	return
end

local GUI = P:FindFirstChild("PlayerGui") or P:WaitForChild("PlayerGui", 10)
local C = P.Character
local rem
local D
local E
local I = -99999999999

local function par()
	local ok, r = pcall(function()
		return gethui and gethui()
	end)
	if ok and r then
		return r
	end
	return CG or GUI
end

local function tw(o, t, p)
	if not TS or not o then
		return
	end
	local ok, tr = pcall(function()
		return TS:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p)
	end)
	if ok and tr then
		tr:Play()
		return tr
	end
end

local function rems()
	if rem and rem.Parent then
		return rem
	end
	rem = CM("ReplicatedStorage", "FindFirstChild", "Remotes") or (RS and RS:FindFirstChild("Remotes"))
	return rem
end

local function upRem()
	local r = rems()
	if r then
		if not D or not D.Parent then
			D = r:FindFirstChild("DamageCall")
		end
		if not E or not E.Parent then
			E = r:FindFirstChild("EditValueCall")
		end
	end
	local hk = type(ENV) == "table" and rawget(ENV, "__vyperia_dmg_hook")
	if type(hk) == "table" then
		hk.d = D
		hk.i = I
	end
end

local function char()
	C = P.Character or C
	return C
end

local function stopGuiBits()
	if not GUI then
		return
	end
	local rg = GUI:FindFirstChild("ResetOnSpawnGui")
	if rg then
		rg.Enabled = false
		rg.ResetOnSpawn = false
	end
	local mg = GUI:FindFirstChild("MainGui")
	local th = mg and mg:FindFirstChild("MainTextHolder")
	local tg = th and th:FindFirstChild("TextGenerator")
	if tg then
		tg.Disabled = true
	end
end

stopGuiBits()
add(P.CharacterAdded:Connect(function(c)
	C = c
	task.defer(stopGuiBits)
end))

if type(ENV) == "table" and not rawget(ENV, "__vyperia_dmg_hook") then
	local hk = { d = nil, i = I }
	ENV.__vyperia_dmg_hook = hk
	if hookmetamethod and checkcaller and getnamecallmethod then
		local oldNc
		oldNc = hookmetamethod(game, "__namecall", function(self, ...)
			local h = rawget(ENV, "__vyperia_dmg_hook")
			if type(h) == "table" and h.d and not checkcaller() and self == h.d then
				local m = tostring(getnamecallmethod()):lower()
				if m == "fireserver" or m == "invokeserver" then
					local a = { ... }
					a[1] = h.i or I
					return oldNc(self, table.unpack(a))
				end
			end
			return oldNc(self, ...)
		end)
		hk.old = oldNc
	end
end

upRem()

go(function()
	while st.alive do
		upRem()
		if E then
			pcall(E.FireServer, E, "health", 10000000000000000)
		end
		if D then
			pcall(D.FireServer, D, I)
		end
		task.wait(0.12)
	end
end)

go(function()
	local pscr = P:WaitForChild("PlayerScripts", 10)
	if not pscr or not st.alive then
		return
	end
	local scr = pscr:WaitForChild("ScreenControls", 10)
	local cm = scr and scr:WaitForChild("CameraManagementMain", 10)
	local o = cm and cm:WaitForChild("CameraCFrameOverwrite", 10)
	if not o then
		return
	end
	add(RV.RenderStepped:Connect(function()
		if st.alive and o.Parent then
			o.Value = 0
		end
	end))
end)

local function safeClamp(v, mn, mx)
	if mn > mx then
		return (mn + mx) / 2
	end
	return math.clamp(v, mn, mx)
end

local function makeBtn(txt, w)
	local b = Instance.new("TextButton")
	b.Name = "\0"
	b.Size = UDim2.new(0, w, 1, -12)
	b.BackgroundColor3 = Color3.fromRGB(42, 45, 53)
	b:SetAttribute("BaseColor", b.BackgroundColor3)
	b.TextColor3 = Color3.fromRGB(245, 247, 255)
	b.Text = txt
	b.TextSize = 13
	b.Font = Enum.Font.GothamMedium
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.ClipsDescendants = true
	obj(b)
	local c = Instance.new("UICorner")
	c.Name = "\0"
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = b
	local s = Instance.new("UIStroke")
	s.Name = "\0"
	s.Thickness = 1
	s.Transparency = 0.55
	s.Color = Color3.fromRGB(130, 140, 165)
	s.Parent = b
	add(b.MouseEnter:Connect(function()
		tw(b, 0.12, { BackgroundColor3 = Color3.fromRGB(55, 59, 70) })
	end))
	add(b.MouseLeave:Connect(function()
		tw(b, 0.12, { BackgroundColor3 = b:GetAttribute("BaseColor") or Color3.fromRGB(42, 45, 53) })
	end))
	return b
end

go(function()
	local top = Instance.new("ScreenGui")
	top.Name = "\0"
	top.Enabled = true
	top.ResetOnSpawn = false
	top.DisplayOrder = 2147483647
	top.IgnoreGuiInset = true
	top.Parent = par()
	obj(top)

	local bar = Instance.new("Frame")
	bar.Name = "\0"
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 8)
	bar.Size = UDim2.new(0, 430, 0, 44)
	bar.BackgroundColor3 = Color3.fromRGB(22, 24, 31)
	bar.BackgroundTransparency = 0.05
	bar.BorderSizePixel = 0
	bar.Parent = top
	obj(bar)

	local bc = Instance.new("UICorner")
	bc.Name = "\0"
	bc.CornerRadius = UDim.new(0, 14)
	bc.Parent = bar

	local bs = Instance.new("UIStroke")
	bs.Name = "\0"
	bs.Thickness = 1
	bs.Transparency = 0.35
	bs.Color = Color3.fromRGB(105, 115, 145)
	bs.Parent = bar

	local pad = Instance.new("UIPadding")
	pad.Name = "\0"
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent = bar

	local lay = Instance.new("UIListLayout")
	lay.Name = "\0"
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.VerticalAlignment = Enum.VerticalAlignment.Center
	lay.Padding = UDim.new(0, 8)
	lay.Parent = bar

	local title = Instance.new("TextLabel")
	title.Name = "\0"
	title.Size = UDim2.new(0, 74, 1, -12)
	title.BackgroundTransparency = 1
	title.Text = "Vyperia"
	title.TextColor3 = Color3.fromRGB(210, 217, 240)
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.LayoutOrder = 1
	title.Parent = bar
	obj(title)

	local akBtn = makeBtn("Auto Kick: OFF", 116)
	akBtn.LayoutOrder = 2
	akBtn.Parent = bar

	local fxBtn = makeBtn("Anchor Stuck Fix", 132)
	fxBtn.LayoutOrder = 3
	fxBtn.Parent = bar

	local ulBtn = makeBtn("Unload", 64)
	ulBtn.LayoutOrder = 4
	ulBtn.Parent = bar

	local function fit()
		local cam = workspace.CurrentCamera
		local vw = cam and cam.ViewportSize.X or 800
		local w = math.max(260, math.min(430, vw - 20))
		bar.Size = UDim2.new(0, w, 0, 44)
		if w < 380 then
			title.Size = UDim2.new(0, 0, 1, -12)
			title.Visible = false
			akBtn.Size = UDim2.new(0, 110, 1, -12)
			fxBtn.Size = UDim2.new(0, 116, 1, -12)
			ulBtn.Size = UDim2.new(0, 56, 1, -12)
		else
			title.Size = UDim2.new(0, 74, 1, -12)
			title.Visible = true
			akBtn.Size = UDim2.new(0, 116, 1, -12)
			fxBtn.Size = UDim2.new(0, 132, 1, -12)
			ulBtn.Size = UDim2.new(0, 64, 1, -12)
		end
	end
	fit()
	if workspace.CurrentCamera then
		add(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit))
	end
	add(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		task.defer(fit)
	end))

	local dragging = false
	local dragInput
	local dragStart
	local startPos

	add(bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragInput = input
			dragStart = input.Position
			startPos = bar.Position
		end
	end))
	add(bar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end))
	add(UIS.InputEnded:Connect(function(input)
		if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
	add(UIS.InputChanged:Connect(function(input)
		if not dragging or input ~= dragInput then
			return
		end
		local cam = workspace.CurrentCamera
		local vs = cam and cam.ViewportSize or Vector2.new(800, 600)
		local d = input.Position - dragStart
		local nx = safeClamp(startPos.X.Offset + d.X, -(vs.X / 2) + (bar.AbsoluteSize.X / 2), (vs.X / 2) - (bar.AbsoluteSize.X / 2))
		local ny = safeClamp(startPos.Y.Offset + d.Y, 0, math.max(0, vs.Y - bar.AbsoluteSize.Y))
		bar.Position = UDim2.new(0.5, nx, 0, ny)
	end))

	local ak = false
	local tok = 0

	local function setAk(on)
		if ak == on then
			return
		end
		ak = on
		tok += 1
		akBtn.Text = ak and "Auto Kick: ON" or "Auto Kick: OFF"
		akBtn:SetAttribute("BaseColor", ak and Color3.fromRGB(35, 130, 72) or Color3.fromRGB(42, 45, 53))
		tw(akBtn, 0.15, { BackgroundColor3 = akBtn:GetAttribute("BaseColor") })
		if not ak then
			return
		end
		local id = tok
		go(function()
			while st.alive and ak and tok == id do
				local c = char()
				local mc = c and c:FindFirstChild("MainControls")
				local sf = mc and mc:FindFirstChild("ScriptsForCall")
				local kr = sf and sf:FindFirstChild("KickRemote")
				local rl = c and (c:FindFirstChild("Right Leg") or c:FindFirstChild("RightLowerLeg"))
				local fa = rl and (rl:FindFirstChild("RightFootAttachment") or rl:FindFirstChildWhichIsA("Attachment"))
				if kr and fa then
					pcall(kr.FireServer, kr, false, fa)
					pcall(kr.FireServer, kr, 0, fa)
				end
				task.wait(0.06)
			end
		end)
	end

	add(akBtn.Activated:Connect(function()
		setAk(not ak)
	end))

	local function prompt()
		if st.pr and st.pr.Parent then
			st.pr:Destroy()
			st.pr = nil
		end
		local pg = Instance.new("ScreenGui")
		pg.Name = "\0"
		pg.ResetOnSpawn = false
		pg.DisplayOrder = 2147483647
		pg.IgnoreGuiInset = true
		pg.Parent = par()
		st.pr = pg
		obj(pg)

		local fr = Instance.new("Frame")
		fr.Size = UDim2.new(0, 320, 0, 154)
		fr.AnchorPoint = Vector2.new(0.5, 0.5)
		fr.Position = UDim2.new(0.5, 0, 0.5, 0)
		fr.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
		fr.BorderSizePixel = 0
		fr.Parent = pg
		local fc = Instance.new("UICorner")
		fc.CornerRadius = UDim.new(0, 14)
		fc.Parent = fr
		local fs = Instance.new("UIStroke")
		fs.Thickness = 1
		fs.Transparency = 0.35
		fs.Color = Color3.fromRGB(110, 120, 150)
		fs.Parent = fr

		local lb = Instance.new("TextLabel")
		lb.Size = UDim2.new(1, -28, 0, 76)
		lb.Position = UDim2.new(0, 14, 0, 14)
		lb.BackgroundTransparency = 1
		lb.Text = "Only run this if you're completely stuck in the void."
		lb.TextWrapped = true
		lb.TextColor3 = Color3.fromRGB(245, 247, 255)
		lb.Font = Enum.Font.GothamMedium
		lb.TextSize = 16
		lb.Parent = fr

		local yes = makeBtn("Yes", 126)
		yes.Position = UDim2.new(0, 32, 1, -46)
		yes.Size = UDim2.new(0, 126, 0, 34)
		yes.BackgroundColor3 = Color3.fromRGB(34, 135, 76)
		yes:SetAttribute("BaseColor", yes.BackgroundColor3)
		yes.Parent = fr

		local no = makeBtn("No", 126)
		no.Position = UDim2.new(1, -158, 1, -46)
		no.Size = UDim2.new(0, 126, 0, 34)
		no.BackgroundColor3 = Color3.fromRGB(130, 45, 55)
		no:SetAttribute("BaseColor", no.BackgroundColor3)
		no.Parent = fr

		add(no.Activated:Connect(function()
			if pg.Parent then
				pg:Destroy()
			end
		end))
		add(yes.Activated:Connect(function()
			if pg.Parent then
				pg:Destroy()
			end
			go(function()
				local r = rems()
				local tp = r and r:FindFirstChild("EntityTpObbyCall")
				if not tp then
					return
				end
				pcall(tp.FireServer, tp, false)
				task.wait()
				pcall(tp.FireServer, tp, true)
				task.wait()
				pcall(tp.FireServer, tp, false)
				for _ = 1, 60 do
					if not st.alive then
						return
					end
					task.wait(0.1)
				end
				local exit = workspace:FindFirstChild("ExitPart", true)
				if exit and exit:IsA("BasePart") then
					local c = char()
					local pp = c and (c.PrimaryPart or c:FindFirstChild("HumanoidRootPart"))
					if pp then
						pcall(c.PivotTo, c, exit.CFrame * CFrame.new(0, 1, 0))
					end
				end
			end)
		end))
	end

	add(fxBtn.Activated:Connect(prompt))
	add(ulBtn.Activated:Connect(function()
		st.clean()
	end))
end)

go(function()
	local function kill(x)
		if x and x:IsA("Sound") and x.Name:lower() == "kicksound" then
			pcall(function()
				x:Destroy()
			end)
		end
	end
	local list = workspace:GetDescendants()
	for i = 1, #list do
		if not st.alive then
			return
		end
		kill(list[i])
		if i % 350 == 0 then
			task.wait()
		end
	end
	add(workspace.DescendantAdded:Connect(function(x)
		task.defer(function()
			if st.alive then
				kill(x)
			end
		end)
	end))
end)
