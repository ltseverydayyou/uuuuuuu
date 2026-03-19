local __lt = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {};
	local sharedEnv = rawget(_G, "shared");
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil);
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver");
		if type(cached) == "table" then
			return cached;
		end;
	end;
	local loader = loadstring or load;
	if type(loader) ~= "function" then
		error("Service resolver loader unavailable");
	end;
	local resolver = loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau");
	if type(resolver) ~= "function" then
		error("Service resolver failed to compile");
	end;
	local loaded = resolver();
	if type(loaded) ~= "table" then
		error("Service resolver failed to load");
	end;
	if cacheHost then
		cacheHost.__lt_service_resolver = loaded;
	end;
	return loaded;
end)();

local MK = "__ESP"

local plrs = __lt.cs("Players", cloneref)
local rs = __lt.cs("RunService", cloneref)
local lp = plrs.LocalPlayer

local map = {}
local hooked = {}

local colTools = Color3.new(1, 1, 1)
local colInteracts = Color3.new(1, 0, 0)

local function canDraw()
	local ok = pcall(function()
		return Drawing and Drawing.new
	end)
	return ok and Drawing and type(Drawing.new) == "function"
end

local function newDraw(t)
	if not canDraw() then
		return
	end
	local ok, obj = pcall(Drawing.new, t)
	if ok and obj then
		return obj
	end
end

local function ador(o)
	if o:IsA("BasePart") then
		return o
	end
	if o:IsA("Model") then
		if o.PrimaryPart then
			return o.PrimaryPart
		end
		return o:FindFirstChildWhichIsA("BasePart", true)
	end
end

local function clr(o)
	local d = map[o]
	if d then
		if d.line then
			pcall(function()
				d.line.Visible = false
				d.line:Remove()
			end)
		end
		if d.dot then
			pcall(function()
				d.dot.Visible = false
				d.dot:Remove()
			end)
		end
		map[o] = nil
	end
	local f = o:FindFirstChild(MK)
	if f then
		f:Destroy()
	end
end

local function mk(o, cfg)
	if not o or not (o:IsA("Model") or o:IsA("BasePart")) then
		return
	end

	clr(o)

	local f = Instance.new("Folder")
	f.Name = MK
	f.Parent = o

	local c = cfg.color or Color3.new(1, 1, 1)

	if cfg.kind == "interacts" then
		local h = Instance.new("Highlight")
		h.Name = "HL"
		h.FillColor = c
		h.OutlineColor = c
		h.FillTransparency = 0.75
		h.OutlineTransparency = 0
		h.Adornee = o
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = f
		return
	end

	local a = ador(o)
	if not a then
		f:Destroy()
		return
	end

	local b = Instance.new("BillboardGui")
	b.Name = "BB"
	b.Adornee = a
	b.Size = UDim2.fromOffset(110, 20)
	b.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	b.AlwaysOnTop = true
	b.LightInfluence = 0
	b.MaxDistance = 500
	b.Parent = f

	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.SourceSansSemibold
	t.TextScaled = false
	t.TextSize = 13
	t.TextColor3 = c
	t.TextStrokeTransparency = 0.35
	t.Text = "[ " .. o.Name .. " ]"
	t.ZIndex = 10
	t.Parent = b

	local h = Instance.new("Highlight")
	h.Name = "HL"
	h.FillColor = c
	h.OutlineColor = c
	h.FillTransparency = 0.75
	h.OutlineTransparency = 0
	h.Adornee = o
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = f

	local line = newDraw("Line")
	if line then
		line.Visible = false
		line.Thickness = 1.5
		line.Color = c
	end

	local dot = newDraw("Circle")
	if dot then
		dot.Visible = false
		dot.Thickness = 1.5
		dot.Filled = true
		dot.Radius = 4
		dot.Color = c
	end

	map[o] = {
		a = a,
		t = t,
		line = line,
		dot = dot
	}
end

local function hk(root, cfg)
	if hooked[root] then
		return
	end
	hooked[root] = true

	local function add(i)
		if i:IsA("Model") or i:IsA("BasePart") then
			mk(i, cfg)
		end
	end

	local function rem(i)
		if i:IsA("Model") or i:IsA("BasePart") then
			clr(i)
		end
	end

	root.DescendantAdded:Connect(add)
	root.DescendantRemoving:Connect(rem)

	for _, i in ipairs(root:GetDescendants()) do
		add(i)
	end
end

local function hookByName(i)
	if i.Name == "Tools" then
		hk(i, { kind = "tools", color = colTools })
	elseif i.Name == "Interacts" then
		hk(i, { kind = "interacts", color = colInteracts })
	end
end

for _, i in ipairs(workspace:GetDescendants()) do
	hookByName(i)
end

workspace.DescendantAdded:Connect(hookByName)

local function getHRP()
	if not lp then
		return
	end
	local ch = lp.Character
	if not ch then
		return
	end
	return ch:FindFirstChild("HumanoidRootPart")
		or ch:FindFirstChild("Torso")
		or ch:FindFirstChild("UpperTorso")
end

local cam = workspace.CurrentCamera

__lt.cm("RunService", "BindToRenderStep", MK .. "_Update", Enum.RenderPriority.Camera.Value + 1, function()
	if cam ~= workspace.CurrentCamera then
		cam = workspace.CurrentCamera
	end
	if not cam then
		return
	end

	local hrp = getHRP()
	local vs = cam.ViewportSize
	local base = Vector2.new(vs.X * 0.5, 0)

	for o, d in pairs(map) do
		local a = d.a
		local t = d.t
		local line = d.line
		local dot = d.dot

		if not (o and o.Parent and a and a.Parent and t and t.Parent) then
			clr(o)
		else
			if hrp then
				local dist = (hrp.Position - a.Position).Magnitude
				t.Text = "[ " .. o.Name .. " | " .. string.format("%.0f", dist) .. " ]"
			else
				t.Text = "[ " .. o.Name .. " ]"
			end

			if line or dot then
				local pos, on = cam:WorldToViewportPoint(a.Position)
				if on and pos.Z > 0 then
					local p2 = Vector2.new(pos.X, pos.Y)
					if line then
						line.Visible = true
						line.From = base
						line.To = p2
					end
					if dot then
						dot.Visible = true
						dot.Position = p2
					end
				else
					if line then
						line.Visible = false
					end
					if dot then
						dot.Visible = false
					end
				end
			end
		end
	end
end)