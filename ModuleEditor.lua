local __lt = {
	cr = type(cloneref) == "function" and cloneref or nil,
	svc = {
		cache = {},
		fallback = {},
		invalid = {},
	}
}

function __lt.sv(value)
	return typeof(value) == "Instance"
end

function __lt.fs(name)
	local ok, service = pcall(function()
		return game:FindService(name)
	end)
	if ok and __lt.sv(service) then
		return service
	end
	return nil
end

function __lt.ns(name)
	local ok, service = pcall(Instance.new, name)
	if ok and __lt.sv(service) then
		return service
	end
	return nil
end

function __lt.gs(name)
	local cached = __lt.svc.cache[name]
	local isFallback = __lt.svc.fallback[name] == true
	if __lt.sv(cached) and not isFallback then
		return cached
	end
	local service = __lt.fs(name)
	if __lt.sv(service) then
		__lt.svc.invalid[name] = nil
		__lt.svc.cache[name] = service
		__lt.svc.fallback[name] = nil
		return service
	end
	if __lt.sv(cached) and isFallback then
		return cached
	end
	if __lt.svc.invalid[name] then
		return nil
	end
	service = __lt.ns(name)
	if __lt.sv(service) then
		__lt.svc.cache[name] = service
		__lt.svc.fallback[name] = true
		return service
	end
	__lt.svc.invalid[name] = true
	return nil
end

function __lt.cs(name, refFn)
	if type(refFn) ~= "function" then
		return __lt.gs(name)
	end
	local ok, ref = pcall(function()
		return refFn(game:FindService(name))
	end)
	if ok and __lt.sv(ref) then
		return ref
	end
	local service = __lt.fs(name)
	if __lt.sv(service) then
		return service
	end
	if __lt.svc.invalid[name] then
		return nil
	end
	local fallbackOk, fallbackRef = pcall(function()
		return refFn(Instance.new(name))
	end)
	if fallbackOk and __lt.sv(fallbackRef) then
		return fallbackRef
	end
	service = __lt.ns(name)
	if __lt.sv(service) then
		return service
	end
	__lt.svc.invalid[name] = true
	return nil
end

local players = __lt.cs("Players", __lt.cr)
local workspaceRef = __lt.cs("Workspace", __lt.cr)
local replicatedStorage = __lt.cs("ReplicatedStorage", __lt.cr)
local replicatedFirst = __lt.cs("ReplicatedFirst", __lt.cr)
local uis = __lt.cs("UserInputService", __lt.cr)
local run = __lt.cs("RunService", __lt.cr)
local gs = __lt.cs("GuiService", __lt.cr)
local cg = __lt.cs("CoreGui", __lt.cr)
local starterGui = __lt.cs("StarterGui", __lt.cr)
local http = __lt.cs("HttpService", __lt.cr)
local scriptContext = __lt.cs("ScriptContext", __lt.cr)

local plr = players.LocalPlayer
local cam = workspaceRef.CurrentCamera
local pg = plr:WaitForChild("PlayerGui")
local tag = "ModEditTag"
local playerModule = pg:FindFirstChild("PlayerModule", true)
local chatScript = nil

local roots = {
	workspaceRef,
	replicatedStorage,
	replicatedFirst,
	players
}
local rootfilter = "all"

local function huigrab()
	return (gethui and gethui())
		or (gethiddenui and gethiddenui())
		or (gethiddengui and gethiddengui())
		or (get_hidden_ui and get_hidden_ui())
		or (get_hidden_gui and get_hidden_gui())
		or nil
end

local function guiroot()
	return huigrab()
		or cg
		or plr:FindFirstChildWhichIsA("PlayerGui")
		or pg
end

for _, root in ipairs({huigrab(), cg, pg}) do
	if typeof(root) == "Instance" then
		for _, v in ipairs(root:GetDescendants()) do
			if v:IsA("ScreenGui") and v:GetAttribute(tag) == true then
				v:Destroy()
			end
		end
	end
end

local function uiname()
	local ok, id = pcall(function()
		return http:GenerateGUID(false)
	end)
	if ok and type(id) == "string" and id ~= "" then
		return id
	end
	return "\0"
end

local gui = Instance.new("ScreenGui")
gui.Name = uiname()
gui:SetAttribute(tag, true)
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local cons = {}
local dead = false
local mods = {}
local curm
local stk = {}
local mode = "mods"
local qry = ""
local sid = 0
local dragged = false
local minimized = false
local pmb
local reqcap
local reqmsg
local showps = false

local function execname()
	local fn = identifyexecutor or getexecutorname
	if type(fn) ~= "function" then
		return "Unknown"
	end

	local ok, a, b = pcall(fn)
	if not ok then
		return "Unknown"
	end
	if type(a) == "string" and type(b) == "string" and b ~= "" then
		return a .. " " .. b
	end
	if type(a) == "string" and a ~= "" then
		return a
	end
	return "Unknown"
end

local exname = execname()

local function prenoreq(err)
	local s = string.lower(tostring(err))
	return string.find(s, "cannot require", 1, true) ~= nil
		or string.find(s, "can't require", 1, true) ~= nil
		or string.find(s, "require not supported", 1, true) ~= nil
		or string.find(s, "require is not supported", 1, true) ~= nil
		or string.find(s, "unsupported require", 1, true) ~= nil
		or string.find(s, "module loading is not supported", 1, true) ~= nil
		or string.find(s, "modules are not supported", 1, true) ~= nil
end

local function notifyunsupported(msg)
	task.spawn(function()
		for _ = 1, 8 do
			local ok = pcall(function()
				starterGui:SetCore("SendNotification", {
					Title = "Module Editor",
					Text = msg,
					Duration = 6,
				})
			end)
			if ok then
				return
			end
			task.wait(0.2)
		end
	end)
end

local function findplayersprobe()
	local all = players:GetDescendants()
	for i = 1, #all do
		local v = all[i]
		if v:IsA("ModuleScript") then
			return v
		end
	end
	return nil
end

local function bootstraprequire()
	if type(require) ~= "function" then
		return false
	end
	local probe = findplayersprobe()
	if not probe then
		return true
	end
	local ok, res = pcall(require, probe)
	if ok then
		return true
	end
	if prenoreq(res) then
		return false
	end
	return true
end

if not bootstraprequire() then
	reqcap = false
	reqmsg = exname ~= "Unknown"
		and ("Executor/environment " .. exname .. " cannot require ModuleScripts.")
		or "This executor/environment cannot require ModuleScripts."
	notifyunsupported(reqmsg)
	return
end

reqcap = true

local function bind(sig, fn)
	local c = sig:Connect(fn)
	cons[#cons + 1] = c
	return c
end

local function protectui(g)
	local inv = uiname()
	local maxdo = 0x7FFFFFFF
	local target = guiroot()
	if not target then
		g.Parent = pg
		return
	end

	pcall(function()
		g.Archivable = false
	end)
	g.Name = inv
	g.Parent = target
	if g:IsA("ScreenGui") then
		g.ZIndexBehavior = Enum.ZIndexBehavior.Global
		g.DisplayOrder = maxdo
		g.ResetOnSpawn = false
		g.IgnoreGuiInset = true
	end

	local props = {
		Parent = target,
		Archivable = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		DisplayOrder = maxdo,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
	}

	for prop, val in pairs(props) do
		bind(g:GetPropertyChangedSignal(prop), function()
			if dead then
				return
			end
			if g[prop] ~= val then
				pcall(function()
					g[prop] = val
				end)
			end
		end)
	end

	bind(g.AncestryChanged, function()
		if dead then
			return
		end
		if g.Parent ~= target then
			pcall(function()
				g.Parent = target
			end)
		end
	end)

	task.spawn(function()
		while not dead and g and g.Parent do
			task.wait(0.75)
			for prop, val in pairs(props) do
				if g[prop] ~= val then
					pcall(function()
						g[prop] = val
					end)
				end
			end
		end
	end)
end

protectui(gui)

local function kill()
	if dead then
		return
	end
	dead = true
	sid += 1
	for i = #cons, 1, -1 do
		pcall(function()
			cons[i]:Disconnect()
		end)
	end
	table.clear(cons)
	gui:Destroy()
end

bind(gui.AncestryChanged, function(_, par)
	if not par then
		kill()
	end
end)

local function mk(cls, prop)
	local o = Instance.new(cls)
	for k, v in pairs(prop) do
		o[k] = v
	end
	o.Name = uiname()
	return o
end

local function fmt(v)
	local t = typeof(v)
	if t == "string" then
		return v
	end
	if t == "boolean" then
		return v and "true" or "false"
	end
	if t == "Instance" then
		if v:IsA("Animation") then
			return v.AnimationId
		end
		if v:IsA("ValueBase") then
			return fmt(v.Value)
		end
		return v.ClassName
	end
	if t == "Vector2" then
		return string.format("Vector2.new(%.9g, %.9g)", v.X, v.Y)
	end
	if t == "Vector3" then
		return string.format("Vector3.new(%.9g, %.9g, %.9g)", v.X, v.Y, v.Z)
	end
	if t == "Color3" then
		return string.format(
			"Color3.fromRGB(%d, %d, %d)",
			math.clamp(math.floor(v.R * 255 + 0.5), 0, 255),
			math.clamp(math.floor(v.G * 255 + 0.5), 0, 255),
			math.clamp(math.floor(v.B * 255 + 0.5), 0, 255)
		)
	end
	if t == "UDim" then
		return string.format("UDim.new(%.9g, %.9g)", v.Scale, v.Offset)
	end
	if t == "UDim2" then
		return string.format(
			"UDim2.new(%.9g, %.9g, %.9g, %.9g)",
			v.X.Scale,
			v.X.Offset,
			v.Y.Scale,
			v.Y.Offset
		)
	end
	if t == "BrickColor" then
		return string.format("BrickColor.new(%q)", v.Name)
	end
	if t == "NumberRange" then
		return string.format("NumberRange.new(%.9g, %.9g)", v.Min, v.Max)
	end
	if t == "Rect" then
		return string.format(
			"Rect.new(%.9g, %.9g, %.9g, %.9g)",
			v.Min.X,
			v.Min.Y,
			v.Max.X,
			v.Max.Y
		)
	end
	if t == "CFrame" then
		local c = {v:GetComponents()}
		for i = 1, #c do
			c[i] = string.format("%.9g", c[i])
		end
		return "CFrame.new(" .. table.concat(c, ", ") .. ")"
	end
	if t == "EnumItem" then
		return tostring(v)
	end
	return tostring(v)
end

local function trim(s)
	return (tostring(s):match("^%s*(.-)%s*$"))
end

local function readnums(txt)
	local out = {}
	local i = 1
	local len = #txt

	while i <= len do
		local ch = string.sub(txt, i, i)
		if string.match(ch, "[%+%-%d%.]") then
			local j = i
			local seenDigit = false
			local seenExp = false

			while j <= len do
				local c = string.sub(txt, j, j)
				if string.match(c, "%d") then
					seenDigit = true
					j += 1
				elseif c == "." then
					j += 1
				elseif (c == "e" or c == "E") and seenDigit and not seenExp then
					seenExp = true
					j += 1
					local nx = string.sub(txt, j, j)
					if nx == "+" or nx == "-" then
						j += 1
					end
				elseif (c == "+" or c == "-") and j == i then
					j += 1
				else
					break
				end
			end

			local n = tonumber(string.sub(txt, i, j - 1))
			if n ~= nil then
				out[#out + 1] = n
			end
			i = j
		else
			i += 1
		end
	end

	return out
end

local function isinstedit(v)
	if typeof(v) ~= "Instance" then
		return false
	end
	if v:IsA("Animation") then
		return true
	end
	return v:IsA("ValueBase")
end

local function isedit(v)
	local t = typeof(v)
	return t == "number"
		or t == "string"
		or t == "boolean"
		or t == "Vector2"
		or t == "Vector3"
		or t == "Color3"
		or t == "UDim"
		or t == "UDim2"
		or t == "BrickColor"
		or t == "NumberRange"
		or t == "Rect"
		or t == "CFrame"
		or t == "EnumItem"
		or isinstedit(v)
end

local function hint(v)
	local t = typeof(v)
	if t == "Instance" then
		if v:IsA("Animation") then
			return "use asset id or rbxassetid://123"
		end
		if v:IsA("ValueBase") then
			return hint(v.Value)
		end
	end
	if t == "Vector2" then
		return "use x, y"
	end
	if t == "Vector3" then
		return "use x, y, z"
	end
	if t == "Color3" then
		return "use r, g, b | 0-1 values | #RRGGBB"
	end
	if t == "UDim" then
		return "use scale, offset"
	end
	if t == "UDim2" then
		return "use xScale, xOffset, yScale, yOffset"
	end
	if t == "BrickColor" then
		return "use a BrickColor name"
	end
	if t == "NumberRange" then
		return "use min, max"
	end
	if t == "Rect" then
		return "use minX, minY, maxX, maxY"
	end
	if t == "CFrame" then
		return "use 3 numbers for position or 12 full components"
	end
	if t == "EnumItem" then
		return "use Enum.Type.Item or just the item name"
	end
	return nil
end

local function edittype(v)
	if typeof(v) == "Instance" then
		if v:IsA("Animation") then
			return "AnimationId"
		end
		if v:IsA("ValueBase") then
			return typeof(v.Value)
		end
		return v.ClassName
	end
	return typeof(v)
end

local function editvalue(v)
	if typeof(v) == "Instance" then
		if v:IsA("Animation") then
			return v.AnimationId
		end
		if v:IsA("ValueBase") then
			return v.Value
		end
	end
	return v
end

local function setvalue(t, k, nv)
	local cur = t[k]
	if typeof(cur) == "Instance" then
		if cur:IsA("Animation") then
			local ok, err = pcall(function()
				cur.AnimationId = nv
			end)
			return ok, err
		end
		if cur:IsA("ValueBase") then
			local ok, err = pcall(function()
				cur.Value = nv
			end)
			return ok, err
		end
	end
	local ok, err = pcall(function()
		t[k] = nv
	end)
	return ok, err
end

local function isreadonlyerr(err)
	local s = string.lower(tostring(err))
	return string.find(s, "readonly", 1, true) ~= nil
		or string.find(s, "read-only", 1, true) ~= nil
		or string.find(s, "frozen", 1, true) ~= nil
end

local function cloneplain(t)
	if type(table.clone) == "function" then
		local ok, cp = pcall(table.clone, t)
		if ok and type(cp) == "table" then
			return cp
		end
	end
	local cp = {}
	for k, v in pairs(t) do
		cp[k] = v
	end
	local mt = getmetatable(t)
	if mt ~= nil then
		setmetatable(cp, mt)
	end
	return cp
end

local function low(s)
	return string.lower(tostring(s))
end

local function has(txt, q)
	return string.find(low(txt), q, 1, true) ~= nil
end

local function noreq(err)
	local s = low(err)
	return has(s, "cannot require")
		or has(s, "can't require")
		or has(s, "require not supported")
		or has(s, "require is not supported")
		or has(s, "unsupported require")
		or has(s, "module loading is not supported")
		or has(s, "modules are not supported")
end

local function setnoreq(msg)
	reqcap = false
	reqmsg = msg
		or (
			exname ~= "Unknown"
			and ("Executor/environment " .. exname .. " cannot require ModuleScripts.")
			or "This executor/environment cannot require ModuleScripts."
		)
end

local function canrequire()
	if reqcap ~= nil then
		return reqcap
	end
	if type(require) ~= "function" then
		setnoreq()
		return false
	end
	reqcap = true
	return true
end

local function cut(s, n)
	s = tostring(s)
	if #s <= n then
		return s
	end
	return string.sub(s, 1, n - 3) .. "..."
end

local function isfilteredmodule(v)
	if showps or typeof(v) ~= "Instance" then
		return false
	end
	if not playerModule then
		local ps = plr:FindFirstChild("PlayerScripts")
		if ps then
			playerModule = ps:FindFirstChild("PlayerModule", true)
			chatScript = chatScript or ps:FindFirstChild("ChatScript", true)
		end
	end
	if not chatScript then
		local ps = plr:FindFirstChild("PlayerScripts")
		if ps then
			chatScript = ps:FindFirstChild("ChatScript", true)
		end
	end
	if playerModule and v:IsDescendantOf(playerModule) then
		return true
	end
	if chatScript and v:IsDescendantOf(chatScript) then
		return true
	end
	return false
end

local function updatepmb()
	pmb.Text = showps and "PS On" or "PS Off"
	pmb.BackgroundColor3 = showps and Color3.fromRGB(36, 62, 92) or Color3.fromRGB(28, 28, 28)
end

local function srt(a, b)
	return tostring(a) < tostring(b)
end

local function klist(t, fn)
	if type(t) ~= "table" then
		return {}
	end

	local out = {}
	local seen = {}

	local function add(k, v)
		if not fn or fn(k, v) then
			if seen[k] then
				return
			end
			seen[k] = true
			out[#out + 1] = k
		end
	end

	for k, v in pairs(t) do
		add(k, v)
	end

	local mt = getmetatable(t)
	local idx = mt and mt.__index
	if type(idx) == "table" then
		for k in pairs(idx) do
			local v = rawget(t, k)
			if v == nil then
				local ok, res = pcall(function()
					return t[k]
				end)
				if ok then
					v = res
					pcall(rawset, t, k, res)
				end
			end
			add(k, v)
		end
	elseif type(idx) == "function" then
		local ups
		if type(getupvalues) == "function" then
			pcall(function()
				ups = getupvalues(idx)
			end)
		elseif debug and type(debug.getupvalues) == "function" then
			pcall(function()
				ups = debug.getupvalues(idx)
			end)
		end

		if type(ups) == "table" then
			for _, up in pairs(ups) do
				if type(up) == "table" then
					for k in pairs(up) do
						local v = rawget(t, k)
						if v == nil then
							local ok, res = pcall(function()
								return t[k]
							end)
							if ok then
								v = res
								pcall(rawset, t, k, res)
							end
						end
						add(k, v)
					end
				end
			end
		end
	end

	table.sort(out, srt)
	return out
end

local bg = mk("Frame", {
	Parent = gui,
	BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1)
})

local frm = mk("Frame", {
	Parent = gui,
	BackgroundColor3 = Color3.fromRGB(14, 14, 14),
	BorderSizePixel = 0
})

mk("UICorner", {
	Parent = frm,
	CornerRadius = UDim.new(0, 14)
})

local top = mk("Frame", {
	Parent = frm,
	BackgroundColor3 = Color3.fromRGB(18, 18, 18),
	BorderSizePixel = 0
})

mk("UICorner", {
	Parent = top,
	CornerRadius = UDim.new(0, 14)
})

local top2 = mk("Frame", {
	Parent = top,
	BackgroundColor3 = Color3.fromRGB(18, 18, 18),
	BorderSizePixel = 0
})

local ttl = mk("TextLabel", {
	Parent = top,
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "Module Editor",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left
})

local back = mk("TextButton", {
	Parent = top,
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(28, 28, 28),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "Back",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13
})

mk("UICorner", {
	Parent = back,
	CornerRadius = UDim.new(0, 8)
})

local scanb = mk("TextButton", {
	Parent = top,
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(28, 28, 28),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "Scan",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13
})

mk("UICorner", {
	Parent = scanb,
	CornerRadius = UDim.new(0, 8)
})

local cls = mk("TextButton", {
	Parent = top,
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(50, 20, 20),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "X",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13
})

mk("UICorner", {
	Parent = cls,
	CornerRadius = UDim.new(0, 8)
})

local minb = mk("TextButton", {
	Parent = top,
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(28, 28, 28),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "-",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 16
})

mk("UICorner", {
	Parent = minb,
	CornerRadius = UDim.new(0, 8)
})

pmb = mk("TextButton", {
	Parent = top,
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(28, 28, 28),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "PS Off",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13
})

mk("UICorner", {
	Parent = pmb,
	CornerRadius = UDim.new(0, 8)
})

local srh = mk("TextBox", {
	Parent = frm,
	BackgroundColor3 = Color3.fromRGB(20, 20, 20),
	BorderSizePixel = 0,
	ClearTextOnFocus = false,
	Font = Enum.Font.Gotham,
	PlaceholderColor3 = Color3.fromRGB(140, 140, 140),
	PlaceholderText = "Search modules, keys, paths...",
	Text = "",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left
})

mk("UICorner", {
	Parent = srh,
	CornerRadius = UDim.new(0, 10)
})

local tabf = mk("Frame", {
	Parent = frm,
	BackgroundTransparency = 1,
	BorderSizePixel = 0
})

local tabs = {}
local roottabs = {}
local rootf = mk("Frame", {
	Parent = frm,
	BackgroundTransparency = 1,
	BorderSizePixel = 0
})

local function mktab(txt, key)
	local b = mk("TextButton", {
		Parent = tabf,
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(24, 24, 24),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = txt,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 13
	})
	mk("UICorner", {
		Parent = b,
		CornerRadius = UDim.new(0, 9)
	})
	tabs[key] = b
	return b
end

mktab("Modules", "mods")
mktab("Entries", "ents")
mktab("Fields", "flds")

local function mkrtab(txt, key)
	local b = mk("TextButton", {
		Parent = rootf,
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(24, 24, 24),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = txt,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 12
	})
	mk("UICorner", {
		Parent = b,
		CornerRadius = UDim.new(0, 9)
	})
	roottabs[key] = b
	return b
end

mkrtab("All", "all")
mkrtab("Workspace", "workspace")
mkrtab("ReplicatedStorage", "replicatedstorage")
mkrtab("ReplicatedFirst", "replicatedfirst")
mkrtab("Players", "players")

local path = mk("TextLabel", {
	Parent = frm,
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "",
	TextColor3 = Color3.fromRGB(200, 200, 200),
	TextSize = 12,
	TextWrapped = false,
	TextXAlignment = Enum.TextXAlignment.Left
})

local stat = mk("TextLabel", {
	Parent = frm,
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "",
	TextColor3 = Color3.fromRGB(170, 170, 170),
	TextSize = 12,
	TextWrapped = false,
	TextXAlignment = Enum.TextXAlignment.Right
})

local body = mk("ScrollingFrame", {
	Parent = frm,
	BackgroundColor3 = Color3.fromRGB(18, 18, 18),
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.None
})

mk("UICorner", {
	Parent = body,
	CornerRadius = UDim.new(0, 12)
})

mk("UIPadding", {
	Parent = body,
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8)
})

local listc = mk("Frame", {
	Parent = body,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 0)
})

local function dragger(ui, dragui)
	dragui = dragui or ui

	local dragging = false
	local dragStart
	local startPos
	local dragPointer
	local pendingInput
	local moveConn
	local endConn
	local stepConn

	local function disconnectlive()
		if moveConn then
			moveConn:Disconnect()
			moveConn = nil
		end
		if endConn then
			endConn:Disconnect()
			endConn = nil
		end
		if stepConn then
			stepConn:Disconnect()
			stepConn = nil
		end
		pendingInput = nil
	end

	local function stopdrag()
		dragging = false
		dragPointer = nil
		pendingInput = nil
		disconnectlive()
	end

	local function getorder(g)
		local z = g.ZIndex or 0
		local lc = g:FindFirstAncestorWhichIsA("LayerCollector")
		local d = 0
		if lc and lc:IsA("ScreenGui") then
			d = lc.DisplayOrder or 0
		end
		return d * 10000 + z
	end

	local function istopmost(root, input)
		local pos = input.Position
		local list
		local ok = pcall(function()
			list = gs:GetGuiObjectsAtPosition(pos.X, pos.Y)
		end)
		if not ok or not list or #list == 0 then
			return true
		end
		local topg
		local topo
		for _, g in ipairs(list) do
			local o = getorder(g)
			if not topg or o > topo then
				topg = g
				topo = o
			end
		end
		if not topg then
			return true
		end
		return topg == root or topg:IsDescendantOf(root)
	end

	local function update(input)
		if not ui or not ui.Parent then
			return
		end
		local delta = input.Position - dragStart
		local screenSize = ui.Parent.AbsoluteSize
		if not screenSize or screenSize.X <= 0 or screenSize.Y <= 0 then
			return
		end
		local newXScale = startPos.X.Scale + (startPos.X.Offset + delta.X) / screenSize.X
		local newYScale = startPos.Y.Scale + (startPos.Y.Offset + delta.Y) / screenSize.Y
		ui.Position = UDim2.new(newXScale, 0, newYScale, 0)
		dragged = true
	end

	bind(dragui.InputBegan, function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
			and istopmost(dragui, input) then
			dragging = true
			dragPointer = input
			dragStart = input.Position
			startPos = ui.Position
			disconnectlive()

			moveConn = uis.InputChanged:Connect(function(changedInput)
				if not dragging then
					return
				end
				local inputType = changedInput.UserInputType
				if inputType == Enum.UserInputType.MouseMovement then
					pendingInput = changedInput
					return
				end
				if inputType == Enum.UserInputType.Touch and changedInput == dragPointer then
					pendingInput = changedInput
				end
			end)

			endConn = uis.InputEnded:Connect(function(endedInput)
				if not dragging then
					return
				end
				local inputType = endedInput.UserInputType
				if inputType == Enum.UserInputType.MouseButton1
					or (inputType == Enum.UserInputType.Touch and endedInput == dragPointer) then
					stopdrag()
				end
			end)

			stepConn = run.RenderStepped:Connect(function()
				local frameInput = pendingInput
				if not frameInput then
					return
				end
				pendingInput = nil
				if not dragging then
					return
				end
				update(frameInput)
			end)
		end
	end)

	pcall(function()
		ui.Active = true
	end)
	pcall(function()
		dragui.Active = true
	end)
end

local function fit()
	local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
	local mobile = uis.TouchEnabled and vp.X <= 900
	local padX = mobile and math.max(18, math.floor(vp.X * 0.06)) or 16
	local padY = mobile and math.max(28, math.floor(vp.Y * 0.08)) or 16
	local maxW = mobile and math.floor(vp.X * 0.88) or (vp.X - padX * 2)
	local maxH = mobile and math.floor(vp.Y * 0.78) or (vp.Y - padY * 2)
	local minW = mobile and math.min(280, maxW) or 320
	local minH = mobile and math.min(320, maxH) or 360
	local w = math.clamp(maxW, minW, 1100)
	local h = math.clamp(maxH, minH, 820)
	local bodyH = minimized and 42 or h
	frm.Size = UDim2.fromOffset(w, h)
	if minimized then
		frm.Size = UDim2.fromOffset(w, bodyH)
	end
	if not dragged then
		local useH = minimized and bodyH or h
		frm.Position = UDim2.fromOffset(math.floor((vp.X - w) * 0.5), math.floor((vp.Y - useH) * 0.5))
	end

	top.Size = UDim2.new(1, 0, 0, 42)
	top2.Size = UDim2.new(1, 0, 0, 14)
	top2.Position = UDim2.new(0, 0, 1, -14)

	ttl.Position = UDim2.fromOffset(10, 0)

	local bw = math.max(52, math.floor(w * 0.1))
	local cw = math.max(42, math.floor(w * 0.07))
	local pw = math.max(72, math.floor(w * 0.11))

	cls.Size = UDim2.fromOffset(cw, 26)
	cls.Position = UDim2.new(1, -cw - 10, 0.5, -13)

	minb.Size = UDim2.fromOffset(cw, 26)
	minb.Position = UDim2.new(1, -cw * 2 - 18, 0.5, -13)

	pmb.Size = UDim2.fromOffset(pw, 26)
	pmb.Position = UDim2.new(1, -(cw * 2 + pw + 26), 0.5, -13)

	scanb.Size = UDim2.fromOffset(math.max(56, bw), 26)
	scanb.Position = UDim2.new(1, -(cw * 2 + pw + bw + 34), 0.5, -13)

	back.Size = UDim2.fromOffset(math.max(56, bw), 26)
	back.Position = UDim2.new(1, -(cw * 2 + pw + bw * 2 + 42), 0.5, -13)

	ttl.Size = UDim2.new(1, -(back.Size.X.Offset + scanb.Size.X.Offset + pmb.Size.X.Offset + minb.Size.X.Offset + cls.Size.X.Offset + 62), 1, 0)

	srh.Visible = not minimized
	tabf.Visible = not minimized
	rootf.Visible = not minimized
	path.Visible = not minimized
	stat.Visible = not minimized
	body.Visible = not minimized

	srh.Position = UDim2.fromOffset(8, 50)
	srh.Size = UDim2.new(1, -16, 0, 34)

	tabf.Position = UDim2.fromOffset(8, 90)
	tabf.Size = UDim2.new(1, -16, 0, 34)

	local tw = math.floor((w - 32) / 3)
	local x = 0
	for _, k in ipairs({"mods", "ents", "flds"}) do
		local b = tabs[k]
		b.Position = UDim2.fromOffset(x, 0)
		b.Size = UDim2.new(0, tw - 4, 1, 0)
		x += tw
	end

	rootf.Position = UDim2.fromOffset(8, 130)
	rootf.Size = UDim2.new(1, -16, 0, 34)

	local rw = math.floor((w - 32) / 5)
	local rx = 0
	for _, k in ipairs({"all", "workspace", "replicatedstorage", "replicatedfirst", "players"}) do
		local b = roottabs[k]
		b.Position = UDim2.fromOffset(rx, 0)
		b.Size = UDim2.new(0, rw - 4, 1, 0)
		rx += rw
	end

	path.Position = UDim2.fromOffset(10, 170)
	path.Size = UDim2.new(0.64, -10, 0, 22)

	stat.Position = UDim2.new(0.64, 0, 0, 170)
	stat.Size = UDim2.new(0.36, -10, 0, 22)

	body.Position = UDim2.fromOffset(8, 196)
	body.Size = UDim2.new(1, -16, 1, -204)
end

fit()
dragger(frm, top)
updatepmb()

bind(cam:GetPropertyChangedSignal("ViewportSize"), fit)

local function clear()
	for _, v in ipairs(listc:GetChildren()) do
		if not v:IsA("UICorner") then
			v:Destroy()
		end
	end
end

local function card(parent, y, h)
	local f = mk("Frame", {
		Parent = parent,
		BackgroundColor3 = Color3.fromRGB(24, 24, 24),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, h)
	})
	mk("UICorner", {
		Parent = f,
		CornerRadius = UDim.new(0, 10)
	})
	return f
end

local function infof(a, b)
	path.Text = a or ""
	stat.Text = b or ""
end

local function rootname(obj)
	for _, v in ipairs(roots) do
		if obj == v then
			return v.Name
		end
	end
	return obj.Name
end

local function rootkey(obj)
	return string.lower(rootname(obj))
end

local function curp()
	if not curm then
		return "No module selected"
	end
	local p = curm.p
	if #stk == 0 then
		return p
	end
	local s = p
	for _, v in ipairs(stk) do
		s ..= "." .. tostring(v)
	end
	return s
end

local function pathat(depth)
	if not curm then
		return "No module selected"
	end
	local p = curm.p
	for i = 1, math.min(depth, #stk) do
		p ..= "." .. tostring(stk[i])
	end
	return p
end

local function gettbl(depth)
	if not curm or curm.st ~= "ok" or type(curm.val) ~= "table" then
		return nil
	end
	local t = curm.val
	local lim = depth or #stk
	for i = 1, lim do
		local k = stk[i]
		if type(t) ~= "table" then
			return nil
		end
		local v = rawget(t, k)
		if v == nil then
			local ok, res = pcall(function()
				return t[k]
			end)
			if not ok then
				return nil
			end
			v = res
			pcall(rawset, t, k, res)
		end
		t = v
	end
	if type(t) ~= "table" then
		return nil
	end
	return t
end

local function gettablechain()
	if not curm or curm.st ~= "ok" or type(curm.val) ~= "table" then
		return nil
	end
	local chain = {curm.val}
	local t = curm.val
	for i = 1, #stk do
		local k = stk[i]
		if type(t) ~= "table" then
			return nil
		end
		local v = rawget(t, k)
		if v == nil then
			local ok, res = pcall(function()
				return t[k]
			end)
			if not ok then
				return nil
			end
			v = res
			pcall(rawset, t, k, res)
		end
		chain[#chain + 1] = v
		t = v
	end
	return chain
end

local function setpathvalue(k, nv)
	local t = gettbl()
	if not t then
		return false, "path is no longer valid"
	end

	local ok, err = setvalue(t, k, nv)
	if ok then
		return true
	end
	if not isreadonlyerr(err) then
		return false, err
	end
	if #stk <= 0 or type(t) ~= "table" then
		return false, err
	end

	local chain = gettablechain()
	if not chain or chain[#chain] ~= t then
		return false, err
	end

	local child = cloneplain(t)
	local wrote, writeErr = setvalue(child, k, nv)
	if not wrote then
		return false, writeErr or err
	end

	for depth = #stk, 1, -1 do
		local parent = chain[depth]
		local parentKey = stk[depth]
		local assignOk, assignErr = pcall(function()
			parent[parentKey] = child
		end)
		if assignOk then
			return true
		end
		if not isreadonlyerr(assignErr) then
			return false, assignErr
		end
		local parentClone = cloneplain(parent)
		local linkOk, linkErr = pcall(function()
			parentClone[parentKey] = child
		end)
		if not linkOk then
			return false, linkErr
		end
		child = parentClone
	end

	return false, err
end

local function iscycletable(v, depth)
	if type(v) ~= "table" or not curm or type(curm.val) ~= "table" then
		return false
	end
	if v == curm.val then
		return true
	end
	local lim = depth or #stk
	local t = curm.val
	for i = 1, lim do
		local k = stk[i]
		if type(t) ~= "table" then
			return false
		end
		local nx = rawget(t, k)
		if nx == nil then
			local ok, res = pcall(function()
				return t[k]
			end)
			if not ok then
				return false
			end
			nx = res
		end
		if nx == v then
			return true
		end
		t = nx
	end
	return false
end

local function haschildtables(t)
	if type(t) ~= "table" then
		return false
	end
	for _, v in pairs(t) do
		if type(v) == "table" and not iscycletable(v) then
			return true
		end
	end
	return false
end

local function entctx()
	local depth = #stk
	local t = gettbl(depth)
	while depth > 0 and not haschildtables(t) do
		depth -= 1
		t = gettbl(depth)
	end
	return depth, t, pathat(depth)
end

local function tcnt(t)
	local a = 0
	local b = 0
	local c = 0
	for _, k in ipairs(klist(t)) do
		local v = t[k]
		local ty = typeof(v)
		if ty == "table" and not iscycletable(v) then
			a += 1
		elseif isedit(v) then
			b += 1
		else
			c += 1
		end
	end
	return a, b, c
end

local function pickmode(t)
	if type(t) ~= "table" then
		return "mods"
	end

	local a, b = tcnt(t)
	if a > 0 then
		return "ents"
	end
	if b > 0 then
		return "flds"
	end
	return "ents"
end

local function parse(txt, old)
	local ty = typeof(old)
	if ty == "number" then
		local n = tonumber(txt)
		if n == nil then
			return nil, false
		end
		return n, true
	elseif ty == "boolean" then
		local s = low((txt:gsub("%s+", "")))
		if s == "true" or s == "1" or s == "yes" or s == "on" then
			return true, true
		end
		if s == "false" or s == "0" or s == "no" or s == "off" then
			return false, true
		end
		return nil, false
	elseif ty == "string" then
		return txt, true
	elseif ty == "Instance" then
		if old:IsA("Animation") then
			local s = trim(txt)
			local id = string.match(s, "^rbxassetid://(%d+)$") or string.match(s, "^(%d+)$")
			if id then
				return "rbxassetid://" .. id, true
			end
			return nil, false
		end
		if old:IsA("ValueBase") then
			return parse(txt, old.Value)
		end
		return nil, false
	elseif ty == "Vector2" then
		local n = readnums(txt)
		if #n == 2 then
			return Vector2.new(n[1], n[2]), true
		end
		return nil, false
	elseif ty == "Vector3" then
		local n = readnums(txt)
		if #n == 3 then
			return Vector3.new(n[1], n[2], n[3]), true
		end
		return nil, false
	elseif ty == "Color3" then
		local s = trim(txt)
		local hex = string.match(s, "^#?(%x%x%x%x%x%x)$")
		if hex then
			local r = tonumber(string.sub(hex, 1, 2), 16)
			local g = tonumber(string.sub(hex, 3, 4), 16)
			local b = tonumber(string.sub(hex, 5, 6), 16)
			return Color3.fromRGB(r, g, b), true
		end

		local n = readnums(txt)
		if #n == 3 then
			if string.find(low(s), "fromrgb", 1, true) or n[1] > 1 or n[2] > 1 or n[3] > 1 then
				return Color3.fromRGB(
					math.clamp(math.floor(n[1] + 0.5), 0, 255),
					math.clamp(math.floor(n[2] + 0.5), 0, 255),
					math.clamp(math.floor(n[3] + 0.5), 0, 255)
				), true
			end
			return Color3.new(n[1], n[2], n[3]), true
		end
		return nil, false
	elseif ty == "UDim" then
		local n = readnums(txt)
		if #n == 2 then
			return UDim.new(n[1], n[2]), true
		end
		return nil, false
	elseif ty == "UDim2" then
		local n = readnums(txt)
		if #n == 4 then
			return UDim2.new(n[1], n[2], n[3], n[4]), true
		end
		return nil, false
	elseif ty == "BrickColor" then
		local s = trim(txt)
		local q = string.match(s, "^['\"](.-)['\"]$")
		if q then
			s = q
		end
		local ok, res = pcall(BrickColor.new, s)
		if ok then
			return res, true
		end
		return nil, false
	elseif ty == "NumberRange" then
		local n = readnums(txt)
		if #n == 1 then
			return NumberRange.new(n[1]), true
		end
		if #n == 2 then
			return NumberRange.new(n[1], n[2]), true
		end
		return nil, false
	elseif ty == "Rect" then
		local n = readnums(txt)
		if #n == 4 then
			return Rect.new(n[1], n[2], n[3], n[4]), true
		end
		return nil, false
	elseif ty == "CFrame" then
		local n = readnums(txt)
		if #n == 3 then
			return CFrame.new(n[1], n[2], n[3]), true
		end
		if #n == 12 then
			return CFrame.new(table.unpack(n)), true
		end
		return nil, false
	elseif ty == "EnumItem" then
		local s = trim(txt)
		local full = tostring(old)
		if s == full then
			return old, true
		end

		local enumName = old.EnumType.Name
		local prefix = "Enum." .. enumName .. "."
		if string.sub(s, 1, #prefix) == prefix then
			s = string.sub(s, #prefix + 1)
		elseif string.sub(s, 1, 5) == "Enum." then
			local parts = {}
			for part in string.gmatch(s, "[^%.]+") do
				parts[#parts + 1] = part
			end
			if #parts >= 3 then
				s = parts[#parts]
			end
		end

		local item = old.EnumType[s]
		if item ~= nil then
			return item, true
		end
		return nil, false
	end
	return nil, false
end

local draw

local function yieldboundary(err)
	local s = string.lower(tostring(err))
	return string.find(s, "yield across metamethod", 1, true) ~= nil
		or string.find(s, "yield across c-call boundary", 1, true) ~= nil
end

local function requireraw(mod, timeout)
	local done = false
	local ok = false
	local res
	local ec

	if typeof(scriptContext) == "Instance" then
		ec = scriptContext.Error:Connect(function(msg, _, src)
			if done then
				return
			end
			if src == mod then
				ok = false
				res = tostring(msg)
				done = true
			end
		end)
	end

	task.spawn(function()
		local out = require(mod)
		if done then
			return
		end
		ok = true
		res = out
		done = true
	end)

	local t0 = os.clock()
	while not dead and not done and os.clock() - t0 < timeout do
		task.wait()
	end

	if ec then
		ec:Disconnect()
	end

	return done, ok, res
end

local function loadm(ent)
	if not ent then
		return false
	end
	if ent.st == "ok" then
		return true
	end
	if ent.st == "type" then
		return false
	end
	if not canrequire() then
		ent.st = "noreq"
		ent.err = reqmsg
		draw()
		return false
	end
	ent.st = "load"
	draw()

	local done = false
	local ok, res

	task.spawn(function()
		ok, res = pcall(require, ent.m)
		done = true
	end)

	local t0 = os.clock()
	while not dead and not done and os.clock() - t0 < 2.5 do
		task.wait()
	end

	if dead then
		return false
	end

	if not done then
		ent.st = "time"
		ent.err = "require timeout"
		draw()
		return false
	end

	if not ok then
		local err = tostring(res)
		if yieldboundary(err) then
			local rawDone, rawOk, rawRes = requireraw(ent.m, 2.5)
			if not rawDone then
				ent.st = "time"
				ent.err = "require timeout"
				draw()
				return false
			end
			if rawOk then
				ok = true
				res = rawRes
			else
				err = tostring(rawRes)
			end
		end
	end

	if not ok then
		local err = tostring(res)
		if noreq(err) then
			setnoreq()
			ent.st = "noreq"
			ent.err = reqmsg
			draw()
			return false
		end
		ent.st = "bad"
		ent.err = err
		draw()
		return false
	end

	ent.val = res

	if type(res) == "table" then
		ent.st = "ok"
	else
		ent.st = "type"
		ent.err = typeof(res)
	end

	draw()
	return ent.st == "ok"
end

local function modrow(parent, y, ent)
	local f = card(parent, y, 68)

	local b = mk("TextButton", {
		Parent = f,
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Text = ""
	})

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -20, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = ent.n,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 28),
		Size = UDim2.new(1, -120, 0, 16),
		Font = Enum.Font.Gotham,
		Text = cut(ent.p, 90),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	local s = ent.st
	local tx = "idle"
	local cl = Color3.fromRGB(180, 180, 180)

	if s == "ok" then
		tx = "table"
		cl = Color3.fromRGB(140, 255, 160)
	elseif s == "load" then
		tx = "loading"
		cl = Color3.fromRGB(255, 230, 140)
	elseif s == "bad" then
		tx = "error"
		cl = Color3.fromRGB(255, 140, 140)
	elseif s == "noreq" then
		tx = "no require"
		cl = Color3.fromRGB(255, 170, 120)
	elseif s == "time" then
		tx = "timeout"
		cl = Color3.fromRGB(255, 140, 140)
	elseif s == "type" then
		tx = ent.err or "value"
		cl = Color3.fromRGB(140, 200, 255)
	end

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -104, 0, 0),
		Size = UDim2.fromOffset(94, 28),
		Font = Enum.Font.GothamBold,
		Text = tx,
		TextColor3 = cl,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right
	})

	if curm == ent then
		f.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
	end

	bind(b.Activated, function()
		curm = ent
		table.clear(stk)
		qry = ""
		srh.Text = ""
		local ok = loadm(ent)
		if ok then
			mode = pickmode(curm.val)
		else
			mode = "ents"
		end
		draw()
	end)

	return f
end

local function entrow(parent, y, baseDepth, k, v)
	local f = card(parent, y, 62)

	local b = mk("TextButton", {
		Parent = f,
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Text = ""
	})

	local t1, t2, t3 = tcnt(v)

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -20, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = tostring(k),
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 30),
		Size = UDim2.new(1, -20, 0, 16),
		Font = Enum.Font.Gotham,
		Text = t1 .. " tables  |  " .. t2 .. " values  |  " .. t3 .. " other",
		TextColor3 = Color3.fromRGB(175, 175, 175),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	bind(b.Activated, function()
		if iscycletable(v, baseDepth) then
			stat.Text = tostring(k) .. " points to the current/ancestor table"
			return
		end
		while #stk > baseDepth do
			table.remove(stk, #stk)
		end
		stk[#stk + 1] = k
		mode = pickmode(v)
		draw()
	end)

	return f
end

local function otherpreview(v)
	local ty = typeof(v)
	if ty == "function" then
		return "function"
	end
	if ty == "Instance" then
		return v.ClassName
	end
	if ty == "table" then
		return "table"
	end
	return cut(fmt(v), 100)
end

local function otherrow(parent, y, k, v)
	local f = card(parent, y, 62)

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -80, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = tostring(k),
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -70, 0, 6),
		Size = UDim2.fromOffset(60, 18),
		Font = Enum.Font.Gotham,
		Text = typeof(v),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right
	})

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 30),
		Size = UDim2.new(1, -20, 0, 16),
		Font = Enum.Font.Code,
		Text = otherpreview(v),
		TextColor3 = Color3.fromRGB(175, 175, 175),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	return f
end

local function valrow(parent, y, k, v)
	local raw = editvalue(v)
	local ty = edittype(v)
	local h = typeof(raw) == "boolean" and 72 or 78
	local f = card(parent, y, h)

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -80, 0, 18),
		Font = Enum.Font.GothamBold,
		Text = tostring(k),
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -70, 0, 6),
		Size = UDim2.fromOffset(60, 18),
		Font = Enum.Font.Gotham,
		Text = ty,
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right
	})

	if typeof(raw) == "boolean" then
		local tog = mk("TextButton", {
			Parent = f,
			AutoButtonColor = false,
			BackgroundColor3 = raw and Color3.fromRGB(26, 70, 36) or Color3.fromRGB(58, 26, 26),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(10, 32),
			Size = UDim2.new(1, -20, 0, 30),
			Font = Enum.Font.GothamBold,
			Text = raw and "true" or "false",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 13
		})

		mk("UICorner", {
			Parent = tog,
			CornerRadius = UDim.new(0, 8)
		})

		bind(tog.Activated, function()
			local t = gettbl()
			if not t then
				return
			end
			local ok, err = setpathvalue(k, not editvalue(t[k]))
			if not ok then
				stat.Text = "failed to set " .. tostring(k) .. ": " .. tostring(err)
				return
			end
			draw()
		end)
	else
		local box = mk("TextBox", {
			Parent = f,
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Position = UDim2.fromOffset(10, 32),
			Size = UDim2.new(1, -92, 0, 34),
			Font = Enum.Font.Code,
			Text = fmt(v),
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left
		})

		mk("UICorner", {
			Parent = box,
			CornerRadius = UDim.new(0, 8)
		})

		local ap = mk("TextButton", {
			Parent = f,
			AutoButtonColor = false,
			BackgroundColor3 = Color3.fromRGB(40, 40, 40),
			BorderSizePixel = 0,
			Position = UDim2.new(1, -74, 0, 32),
			Size = UDim2.fromOffset(64, 34),
			Font = Enum.Font.GothamBold,
			Text = "Apply",
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 12
		})

		mk("UICorner", {
			Parent = ap,
			CornerRadius = UDim.new(0, 8)
		})

		local function apply()
			local t = gettbl()
			if not t then
				return
			end
			local nv, ok = parse(box.Text, t[k])
			if not ok then
				local msg = "bad value for " .. tostring(k)
				local hx = hint(t[k])
				if hx then
					msg ..= " (" .. hx .. ")"
				end
				stat.Text = msg
				box.Text = fmt(t[k])
				return
			end
			local wrote, err = setpathvalue(k, nv)
			if not wrote then
				stat.Text = "failed to set " .. tostring(k) .. ": " .. tostring(err)
				box.Text = fmt(t[k])
				return
			end
			stat.Text = tostring(k) .. " = " .. fmt(t[k])
			box.Text = fmt(t[k])
		end

		bind(ap.Activated, apply)
		bind(box.FocusLost, function(ent)
			if ent then
				apply()
			end
		end)
	end

	return f
end

local function showmsg(parent, y, a, b)
	local f = card(parent, y, 70)

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 0, 22),
		Font = Enum.Font.GothamBold,
		Text = a,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 34),
		Size = UDim2.new(1, -20, 0, 18),
		Font = Enum.Font.Gotham,
		Text = b or "",
		TextColor3 = Color3.fromRGB(175, 175, 175),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	return f
end

local renderitems = {}
local rowgap = 8
local renderlist
local renderqueued = false
local pendingrenderforce = false
local firstrendered = 0
local lastrendered = 0
local renderedrows = {}

local function rowh(kind, v)
	if kind == "mod" then
		return 68
	end
	if kind == "ent" or kind == "other" then
		return 62
	end
	if kind == "msg" then
		return 70
	end
	if kind == "val" then
		return typeof(editvalue(v)) == "boolean" and 72 or 78
	end
	return 62
end

local function clearrows()
	for idx, row in pairs(renderedrows) do
		if row then
			row:Destroy()
		end
		renderedrows[idx] = nil
	end
end

local function setitems(items)
	renderitems = items or {}
	local y = 0
	for i = 1, #renderitems do
		local item = renderitems[i]
		item.y = y
		y += item.h + rowgap
	end
	local total = y > 0 and (y - rowgap) or 0
	listc.Size = UDim2.new(1, 0, 0, total)
	body.CanvasSize = UDim2.fromOffset(0, total + 16)
	if body.CanvasPosition.Y > math.max(0, total - body.AbsoluteSize.Y) then
		body.CanvasPosition = Vector2.new(0, math.max(0, total - body.AbsoluteSize.Y))
	end
	firstrendered = 0
	lastrendered = 0
	clearrows()
	if renderlist then
		renderlist(true)
	end
end

local function renderitem(item)
	if item.kind == "mod" then
		return modrow(listc, item.y, item.ent)
	elseif item.kind == "ent" then
		return entrow(listc, item.y, item.baseDepth, item.key, item.val)
	elseif item.kind == "other" then
		return otherrow(listc, item.y, item.key, item.val)
	elseif item.kind == "val" then
		return valrow(listc, item.y, item.key, item.val)
	elseif item.kind == "msg" then
		return showmsg(listc, item.y, item.a, item.b)
	end
end

local function findfirstvisible(topY)
	local lo = 1
	local hi = #renderitems
	local ans = #renderitems + 1
	while lo <= hi do
		local mid = math.floor((lo + hi) * 0.5)
		local item = renderitems[mid]
		if item.y + item.h >= topY then
			ans = mid
			hi = mid - 1
		else
			lo = mid + 1
		end
	end
	return ans
end

renderlist = function(force)
	if minimized or not body.Visible or #renderitems == 0 then
		firstrendered = 0
		lastrendered = 0
		clearrows()
		return
	end
	local overscan = 120
	local topY = math.max(0, body.CanvasPosition.Y - overscan)
	local botY = body.CanvasPosition.Y + body.AbsoluteSize.Y + overscan
	local first = findfirstvisible(topY)
	local last = first - 1
	local i = first
	while i <= #renderitems do
		local item = renderitems[i]
		if item.y > botY then
			break
		end
		last = i
		i += 1
	end
	if not force and first == firstrendered and last == lastrendered then
		return
	end
	firstrendered = first
	lastrendered = last
	for idx, row in pairs(renderedrows) do
		if idx < first or idx > last then
			row:Destroy()
			renderedrows[idx] = nil
		end
	end
	for idx = first, last do
		if not renderedrows[idx] then
			renderedrows[idx] = renderitem(renderitems[idx])
		end
	end
end

local function queuerender(force)
	pendingrenderforce = pendingrenderforce or force or false
	if renderqueued then
		return
	end
	renderqueued = true
	task.defer(function()
		renderqueued = false
		local forceNow = pendingrenderforce
		pendingrenderforce = false
		if dead or not renderlist or #renderitems <= 0 then
			return
		end
		renderlist(forceNow)
	end)
end

bind(body:GetPropertyChangedSignal("CanvasPosition"), function()
	if #renderitems > 0 then
		queuerender(false)
	end
end)

bind(body:GetPropertyChangedSignal("AbsoluteSize"), function()
	if #renderitems > 0 then
		queuerender(true)
	end
end)

draw = function()
	if dead then
		return
	end

	for k, b in pairs(tabs) do
		local on = k == mode
		b.BackgroundColor3 = on and Color3.fromRGB(235, 235, 235) or Color3.fromRGB(24, 24, 24)
		b.TextColor3 = on and Color3.fromRGB(10, 10, 10) or Color3.new(1, 1, 1)
	end

	for k, b in pairs(roottabs) do
		local on = k == rootfilter
		b.BackgroundColor3 = on and Color3.fromRGB(235, 235, 235) or Color3.fromRGB(24, 24, 24)
		b.TextColor3 = on and Color3.fromRGB(10, 10, 10) or Color3.new(1, 1, 1)
	end

	path.Text = cut(curp(), 110)

	if mode == "mods" then
		local q = low(qry)
		local cnt = 0
		local items = {}
		for _, ent in ipairs(mods) do
			local rootok = rootfilter == "all" or ent.rootk == rootfilter
			local searchok = q == "" or has(ent.n, q) or has(ent.p, q) or has(ent.root, q)
			if rootok and searchok then
				items[#items + 1] = {
					kind = "mod",
					h = rowh("mod"),
					ent = ent,
				}
				cnt += 1
			end
		end
		infof("Modules", cnt .. " shown / " .. #mods .. " total")
		if cnt == 0 then
			items[#items + 1] = {
				kind = "msg",
				h = rowh("msg"),
				a = "No modules found",
				b = "Try a different search or press Scan.",
			}
		end
		setitems(items)
		return
	end

	if not curm then
		infof("No module selected", "")
		setitems({
			{
				kind = "msg",
				h = rowh("msg"),
				a = "Pick a module first",
				b = "Open the Modules tab and select a ModuleScript.",
			},
		})
		return
	end

	if curm.st == "idle" then
		loadm(curm)
	end

	if curm.st == "load" then
		infof(curp(), "loading")
		setitems({
			{
				kind = "msg",
				h = rowh("msg"),
				a = "Loading...",
				b = "This module is being required now.",
			},
		})
		return
	end

	if curm.st == "bad" then
		infof(curp(), "error")
		setitems({
			{
				kind = "msg",
				h = rowh("msg"),
				a = "Require failed",
				b = curm.err or "unknown error",
			},
		})
		return
	end

	if curm.st == "noreq" then
		infof(curp(), "unsupported")
		setitems({
			{
				kind = "msg",
				h = rowh("msg"),
				a = "Executor cannot require modules",
				b = curm.err or "This executor does not support require(ModuleScript).",
			},
		})
		return
	end

	if curm.st == "time" then
		infof(curp(), "timeout")
		setitems({
			{
				kind = "msg",
				h = rowh("msg"),
				a = "Require timed out",
				b = "This module probably yields forever or takes too long to return.",
			},
		})
		return
	end

	if curm.st == "type" then
		infof(curp(), curm.err or "value")
		setitems({
			{
				kind = "msg",
				h = rowh("msg"),
				a = "Module did not return a table",
				b = "Returned type: " .. tostring(curm.err),
			},
		})
		return
	end

	local t = gettbl()
	if not t then
		infof(curp(), "invalid")
		setitems({
			{
				kind = "msg",
				h = rowh("msg"),
				a = "Path is no longer valid",
				b = "The selected nested table path could not be resolved.",
			},
		})
		return
	end

	if mode == "ents" then
		local q = low(qry)
		local depth, entt, entp = entctx()
		if not entt then
			infof(curp(), "invalid")
			setitems({
				{
					kind = "msg",
					h = rowh("msg"),
					a = "Path is no longer valid",
					b = "The selected nested table path could not be resolved.",
				},
			})
			return
		end
		local pathhit = q == "" or has(entp, q)
		local ks = klist(entt, function(k, v)
			if type(v) ~= "table" then
				return false
			end
			if iscycletable(v, depth) then
				return false
			end
			return pathhit or has(k, q)
		end)
		local oks = klist(entt, function(k, v)
			return type(v) ~= "table" and not isedit(v) and (pathhit or has(k, q))
		end)

		local a, b, c = tcnt(entt)
		infof(entp, a .. " tables / " .. b .. " values / " .. c .. " other")
		local items = {}

		if #ks == 0 then
			if #oks > 0 then
				items[#items + 1] = {
					kind = "msg",
					h = rowh("msg"),
					a = "No nested tables here",
					b = "Showing read-only members from this level.",
				}
				for _, k in ipairs(oks) do
					items[#items + 1] = {
						kind = "other",
						h = rowh("other"),
						key = k,
						val = entt[k],
					}
				end
				setitems(items)
				return
			end
			items[#items + 1] = {
				kind = "msg",
				h = rowh("msg"),
				a = "No nested tables here",
				b = "Switch to Fields to edit supported values.",
			}
			setitems(items)
			return
		end

		for _, k in ipairs(ks) do
			items[#items + 1] = {
				kind = "ent",
				h = rowh("ent"),
				baseDepth = depth,
				key = k,
				val = entt[k],
			}
		end
		setitems(items)
		return
	end

	if mode == "flds" then
		local q = low(qry)
		local pathhit = q == "" or has(curp(), q)
		local ks = klist(t, function(k, v)
			return isedit(v) and (pathhit or has(k, q))
		end)

		local a, b, c = tcnt(t)
		infof(curp(), a .. " tables / " .. b .. " values / " .. c .. " other")
		local items = {}

		if #ks == 0 then
			items[#items + 1] = {
				kind = "msg",
				h = rowh("msg"),
				a = "No editable fields",
				b = "This table has no supported editable values.",
			}
			setitems(items)
			return
		end

		for _, k in ipairs(ks) do
			items[#items + 1] = {
				kind = "val",
				h = rowh("val", t[k]),
				key = k,
				val = t[k],
			}
		end
		setitems(items)
	end
end

local function scan()
	sid += 1
	local id = sid
	mods = {}
	curm = nil
	table.clear(stk)
	mode = "mods"
	draw()
	stat.Text = "scanning..."

	task.spawn(function()
		local seen = {}
		local count = 0
		local skipped = 0

		for ri, root in ipairs(roots) do
			if dead or id ~= sid then
				return
			end

			local all = root:GetDescendants()
			local tot = #all
			local rootn = rootname(root)

			for i, v in ipairs(all) do
				if dead or id ~= sid then
					return
				end

				if v:IsA("ModuleScript") and not seen[v] then
					seen[v] = true
					if isfilteredmodule(v) then
						skipped += 1
					else
						count += 1
						mods[#mods + 1] = {
							m = v,
							n = v.Name,
							p = v:GetFullName(),
							root = rootn,
							rootk = rootkey(root),
							st = "idle"
						}
					end
				end

				if i % 250 == 0 then
					stat.Text = "scanning " .. rootn .. " (" .. i .. "/" .. tot .. ") | " .. count .. " modules"
					task.wait()
				end
			end

			stat.Text = "finished " .. rootn .. " (" .. ri .. "/" .. #roots .. ") | " .. count .. " modules"
			task.wait()
		end

		table.sort(mods, function(a, b)
			if a.root == b.root then
				return a.p < b.p
			end
			return a.root < b.root
		end)

		if dead or id ~= sid then
			return
		end

		if skipped > 0 and not showps then
			stat.Text = "found " .. #mods .. " modules | hid " .. skipped .. " PlayerScripts"
		else
			stat.Text = "found " .. #mods .. " modules"
		end
		draw()
	end)
end

bind(back.Activated, function()
	if mode == "mods" then
		return
	end

	if #stk > 0 then
		table.remove(stk, #stk)
		if mode ~= "ents" and mode ~= "flds" then
			mode = "flds"
		end
		draw()
		return
	end

	if curm then
		mode = "mods"
		draw()
	end
end)

bind(scanb.Activated, scan)
bind(pmb.Activated, function()
	showps = not showps
	updatepmb()
	scan()
end)
bind(minb.Activated, function()
	local pos = frm.Position
	minimized = not minimized
	minb.Text = minimized and "+" or "-"
	fit()
	frm.Position = pos
end)
bind(cls.Activated, kill)

bind(srh:GetPropertyChangedSignal("Text"), function()
	qry = srh.Text or ""
	draw()
end)

for k, b in pairs(tabs) do
	bind(b.Activated, function()
		mode = k
		draw()
	end)
end

for k, b in pairs(roottabs) do
	bind(b.Activated, function()
		if rootfilter == k then
			return
		end
		rootfilter = k
		body.CanvasPosition = Vector2.new(0, 0)
		draw()
	end)
end

scan()
