local G = (getgenv and getgenv()) or _G
if G.DeltaRhythmAutoplayer and type(G.DeltaRhythmAutoplayer.Unload) == "function" then
	pcall(G.DeltaRhythmAutoplayer.Unload)
end
local L = loadstring or load
assert(type(L) == "function", "loadstring/load unavailable")
local HAS_FIRESIGNAL = type(firesignal) == "function"
local SR = L(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau")()
local R = cloneref or function(v)
	return v
end
local Players = SR.cs("Players", R)
local RunService = SR.cs("RunService", R)
local VIM = SR.cs("VirtualInputManager", R)
local UIS = SR.cs("UserInputService", R)
local lp = Players.LocalPlayer
local sg = lp:WaitForChild("PlayerGui"):WaitForChild("ScreenGui")
local gf = sg:WaitForChild("GAMEFRAME")
local you = gf:WaitForChild("YOU")
local mobile = sg:WaitForChild("Mobile")
local binds = sg:WaitForChild("SETTI"):WaitForChild("ScrollingFrame"):WaitForChild("Keybinds")
local AP = {
	Enabled = false,
	Mode = "Virtual Input",
	TapRelease = 0.035,
	Generation = 0,
	Unloaded = false,
	Connections = {},
	Bound = setmetatable({}, { __mode = "k" }),
	ContainerConnections = setmetatable({}, { __mode = "k" }),
	Tokens = setmetatable({}, { __mode = "k" }),
	ActiveLanes = {},
	PC = nil,
	Stats = {
		Lanes = 0,
		Containers = 0,
		Notes = 0,
		ReusedNotes = 0,
		TapNotes = 0,
		HoldNotes = 0,
		Presses = 0,
		Releases = 0,
		InputFailures = 0,
		ExpiredUnpressed = 0,
	},
}
G.DeltaRhythmAutoplayer = AP
local LF = { L2 = "Lane_L2", L = "Lane_L", R = "Lane_R", R2 = "Lane_R2" }
local FL = { Lane_L2 = "L2", Lane_L = "L", Lane_R = "R", Lane_R2 = "R2" }
local function cn(s, f)
	local c = s:Connect(f)
	AP.Connections[#AP.Connections + 1] = c
	return c
end
local function norm(s)
	return string.lower(tostring(s or "")):gsub("[%s_%-]", "")
end
local KN = {}
for _, k in ipairs(Enum.KeyCode:GetEnumItems()) do
	KN[norm(k.Name)] = k
end
local DA = {
	["0"] = Enum.KeyCode.Zero,
	["1"] = Enum.KeyCode.One,
	["2"] = Enum.KeyCode.Two,
	["3"] = Enum.KeyCode.Three,
	["4"] = Enum.KeyCode.Four,
	["5"] = Enum.KeyCode.Five,
	["6"] = Enum.KeyCode.Six,
	["7"] = Enum.KeyCode.Seven,
	["8"] = Enum.KeyCode.Eight,
	["9"] = Enum.KeyCode.Nine,
}
local KA = {
	spacebar = Enum.KeyCode.Space,
	lshift = Enum.KeyCode.LeftShift,
	rshift = Enum.KeyCode.RightShift,
	lctrl = Enum.KeyCode.LeftControl,
	rctrl = Enum.KeyCode.RightControl,
	lalt = Enum.KeyCode.LeftAlt,
	ralt = Enum.KeyCode.RightAlt,
	esc = Enum.KeyCode.Escape,
	enter = Enum.KeyCode.Return,
	backtick = Enum.KeyCode.Backquote,
}
local function ek(s, d)
	local n = norm(s)
	return DA[n] or KA[n] or KN[n] or d or Enum.KeyCode.Unknown
end
local function lc(l)
	local f = you:FindFirstChild(LF[l])
	local v = f and f:FindFirstChild("LaneViewport")
	return v and v:FindFirstChild("LaneContent")
end
local function nc(l)
	local c = lc(l)
	return c and c:FindFirstChild("NotesContainer")
end
local function is4()
	return nc("L2") ~= nil or nc("R2") ~= nil
end
local function key(l)
	if is4() then
		local f = binds:FindFirstChild("4Key")
		local m =
			{ L2 = { "4KL2", Enum.KeyCode.D }, L = { "4KL", Enum.KeyCode.F }, R = { "4KR", Enum.KeyCode.J }, R2 = {
				"4KR2",
				Enum.KeyCode.K,
			} }
		local e = m[l]
		local b = f and e and f:FindFirstChild(e[1])
		return ek(b and b.Text, e and e[2])
	end
	local f = binds:FindFirstChild("Frame")
	local m = { L = { "Z", Enum.KeyCode.Z }, R = { "X", Enum.KeyCode.X } }
	local e = m[l]
	local b = f and e and f:FindFirstChild(e[1])
	return ek(b and b.Text, e and e[2])
end
local function sig()
	return { L2 = lc("L2"), L = lc("L"), R = lc("R"), R2 = lc("R2") }
end
local function same(s)
	local n = sig()
	return s and s.L2 == n.L2 and s.L == n.L and s.R == n.R and s.R2 == n.R2
end
local function info(f)
	local g = debug and debug.getinfo or getinfo
	if type(g) ~= "function" then
		return
	end
	local o, v = pcall(g, f)
	if o and type(v) == "table" then
		return v
	end
end
local function ups(f)
	local g = debug and debug.getupvalues or getupvalues
	if type(g) ~= "function" then
		return
	end
	local o, v = pcall(g, f)
	if o and type(v) == "table" then
		return v
	end
end
local function src(i)
	local s = i and (i.source or i.short_src or i.Source)
	return type(s) == "string" and s:find("GAMEFRAME.YOU.LocalScript", 1, true) ~= nil
end
local function livecount(u)
	local n = 0
	if type(u) ~= "table" then
		return 0
	end
	for _, a in pairs(u) do
		if type(a) == "table" then
			for _, v in pairs(a) do
				if typeof(v) == "Instance" and v.Name == "LaneContent" then
					local o, x = pcall(v.IsDescendantOf, v, you)
					if o and x then
						n += 1
					end
				end
			end
		end
	end
	return n
end
local function has(u, x)
	if type(u) == "table" then
		for _, v in pairs(u) do
			if v == x then
				return true
			end
		end
	end
	return false
end
local function firsttab(u)
	if type(u) == "table" then
		for _, v in pairs(u) do
			if type(v) == "table" then
				return v
			end
		end
	end
end
local function refreshPC()
	if type(getgc) ~= "function" then
		return false
	end
	local o, g = pcall(getgc, true)
	if not o or type(g) ~= "table" then
		o, g = pcall(getgc)
	end
	if not o or type(g) ~= "table" then
		return false
	end
	local hit, best = nil, 0
	for _, f in ipairs(g) do
		if type(f) == "function" then
			local i = info(f)
			if i and src(i) and (i.name or i.Name) == "hitLane" then
				local c = livecount(ups(f))
				if c > best then
					best, hit = c, f
				end
			end
		end
	end
	if not hit or best < 2 then
		return false
	end
	local press, km
	for _, f in ipairs(g) do
		if type(f) == "function" then
			local i = info(f)
			local a = i and (i.numparams or i.nparams or i.Arity)
			if i and src(i) and a == 2 then
				local u = ups(f)
				if has(u, hit) then
					press, km = f, firsttab(u)
					break
				end
			end
		end
	end
	if not press or type(km) ~= "table" then
		return false
	end
	local rel
	for _, f in ipairs(g) do
		if type(f) == "function" and f ~= press then
			local i = info(f)
			local a = i and (i.numparams or i.nparams or i.Arity)
			if i and src(i) and a == 2 then
				local u = ups(f)
				if firsttab(u) == km then
					for _, v in pairs(u or {}) do
						if type(v) == "function" and v ~= hit then
							rel = f
							break
						end
					end
					if rel then
						break
					end
				end
			end
		end
	end
	if not rel then
		return false
	end
	AP.PC = { Press = press, Release = rel, Sig = sig() }
	return true
end
local function ensurePC()
	return AP.PC and same(AP.PC.Sig) or (refreshPC())
end
local function input(k, st)
	return {
		KeyCode = k,
		UserInputType = Enum.UserInputType.Keyboard,
		UserInputState = st,
		Position = Vector3.zero,
		Delta = Vector3.zero,
	}
end
local function pc(kind, l)
	if type(firesignal) ~= "function" then
		return false
	end
	local k = key(l)
	if k == Enum.KeyCode.Unknown then
		return false
	end
	for _ = 1, 2 do
		if not ensurePC() then
			return false
		end
		local be = Instance.new("BindableEvent")
		local ok2 = false
		local c = be.Event:Connect(function(q)
			local f = kind == "press" and AP.PC.Press or AP.PC.Release
			ok2 = pcall(f, q, false)
		end)
		local ok = pcall(
			firesignal,
			be.Event,
			input(k, kind == "press" and Enum.UserInputState.Begin or Enum.UserInputState.End)
		)
		c:Disconnect()
		be:Destroy()
		if ok and ok2 then
			return true, k
		end
		AP.PC = nil
	end
	return false, k
end
local function mb(kind, l)
	local m = mobile:FindFirstChild(is4() and "4K" or "2K")
	local b = m and m:FindFirstChild(l)
	if not b or type(firesignal) ~= "function" then
		return false
	end
	local q = {
		UserInputType = Enum.UserInputType.MouseButton1,
		UserInputState = kind == "press" and Enum.UserInputState.Begin or Enum.UserInputState.End,
	}
	return pcall(firesignal, kind == "press" and b.InputBegan or b.InputEnded, q)
end
local function press(mode, l)
	if mode == "firesignal" then
		if UIS.KeyboardEnabled then
			return pc("press", l)
		else
			return mb("press", l), nil
		end
	end
	local k = key(l)
	if k == Enum.KeyCode.Unknown then
		return false
	end
	return pcall(VIM.SendKeyEvent, VIM, true, k, false, game), k
end
local function release(mode, l, k)
	if mode == "firesignal" then
		if UIS.KeyboardEnabled then
			return pc("release", l)
		else
			return mb("release", l)
		end
	end
	k = k or key(l)
	if not k or k == Enum.KeyCode.Unknown then
		return false
	end
	return pcall(VIM.SendKeyEvent, VIM, false, k, false, game)
end
local function cy(x)
	return x.AbsolutePosition.Y + x.AbsoluteSize.Y * 0.5
end
local function valid(n, c, t, g)
	return AP.Enabled and not AP.Unloaded and AP.Generation == g and AP.Tokens[n] == t and n.Parent == c
end
local function relLane(l, n, t)
	local a = AP.ActiveLanes[l]
	if not a or a.Note ~= n or a.Token ~= t then
		return
	end
	AP.ActiveLanes[l] = nil
	if release(a.Mode, l, a.Key) then
		AP.Stats.Releases += 1
	else
		AP.Stats.InputFailures += 1
	end
end
local function relAll()
	local p = {}
	for l, a in pairs(AP.ActiveLanes) do
		p[#p + 1] = { l, a }
	end
	table.clear(AP.ActiveLanes)
	for _, e in ipairs(p) do
		pcall(release, e[2].Mode, e[1], e[2].Key)
	end
end
local function seq(n, c, l, h, t, g)
	if not valid(n, c, t, g) or not n:IsA("GuiObject") then
		return
	end
	local pd, py, dir, last, approach = nil, nil, nil, math.huge, false
	local trig = false
	while valid(n, c, t, g) and h.Parent do
		if not n.Visible or not c.Visible then
			RunService.RenderStepped:Wait()
			continue
		end
		local y = cy(n)
		local d = y - cy(h)
		local a = math.abs(d)
		if py and not dir then
			local z = y - py
			if math.abs(z) > 0.05 then
				dir = z > 0 and 1 or -1
			end
		end
		if a < last then
			approach = true
		end
		local cross = pd and ((pd <= 0 and d >= 0) or (pd >= 0 and d <= 0))
		if cross or a <= math.max(2, h.AbsoluteSize.Y * 0.08) or (approach and a > last and last <= 8) then
			trig = true
			break
		end
		pd, py, last = d, y, a
		RunService.RenderStepped:Wait()
	end
	if not trig or not valid(n, c, t, g) then
		if AP.Tokens[n] == t and n.Parent ~= c then
			AP.Stats.ExpiredUnpressed += 1
		end
		return
	end
	local old = AP.ActiveLanes[l]
	if old then
		relLane(l, old.Note, old.Token)
	end
	local hold = n:FindFirstChild("HOLDNOTE")
	local ih = hold and hold:IsA("GuiObject") and hold.AbsoluteSize.Y > 1
	if ih then
		AP.Stats.HoldNotes += 1
	else
		AP.Stats.TapNotes += 1
	end
	local m = AP.Mode
	local ok, k = press(m, l)
	if not ok then
		AP.Stats.InputFailures += 1
		return
	end
	AP.Stats.Presses += 1
	local a = { Note = n, Token = t, Mode = m, Key = k, Hold = ih }
	AP.ActiveLanes[l] = a
	if ih then
		while valid(n, c, t, g) and AP.ActiveLanes[l] == a do
			if not hold.Parent or hold.AbsoluteSize.Y <= 1 or not n.Visible then
				break
			end
			RunService.RenderStepped:Wait()
		end
		relLane(l, n, t)
	else
		task.wait(AP.TapRelease)
		relLane(l, n, t)
	end
end
local function lane(c)
	local x = c and c.Parent
	local v = x and x.Parent
	local f = v and v.Parent
	return f and FL[f.Name], x and x:FindFirstChild("HITPOS")
end
local function queue(n, c)
	if not AP.Enabled or AP.Unloaded or not n:IsA("GuiObject") or n.Name ~= "NOTE" then
		return
	end
	local l, h = lane(c)
	if not l or not h then
		return
	end
	local t = (AP.Tokens[n] or 0) + 1
	AP.Tokens[n] = t
	AP.Stats.Notes += 1
	if t > 1 then
		AP.Stats.ReusedNotes += 1
	end
	task.defer(seq, n, c, l, h, t, AP.Generation)
end
local function bind(c)
	if not c or c.Name ~= "NotesContainer" or AP.Bound[c] then
		return
	end
	local l = lane(c)
	if not l then
		return
	end
	AP.Bound[c] = true
	AP.Stats.Containers += 1
	AP.Stats.Lanes += 1
	AP.PC = nil
	AP.ContainerConnections[c] = c.ChildAdded:Connect(function(n)
		queue(n, c)
	end)
	if AP.Enabled then
		for _, n in ipairs(c:GetChildren()) do
			queue(n, c)
		end
	end
end
local function bindall()
	for _, l in ipairs({ "L2", "L", "R", "R2" }) do
		bind(nc(l))
	end
end
local function enabled(v)
	AP.Enabled = v == true
	AP.Generation += 1
	relAll()
	if AP.Enabled then
		bindall()
		for _, l in ipairs({ "L2", "L", "R", "R2" }) do
			local c = nc(l)
			if c then
				for _, n in ipairs(c:GetChildren()) do
					queue(n, c)
				end
			end
		end
	end
end
AP.SetEnabled = enabled
AP.SetMode = function(v)
	if v == "firesignal" and not HAS_FIRESIGNAL then
		v = "Virtual Input"
	end
	if v == "Virtual Input" or (v == "firesignal" and HAS_FIRESIGNAL) then
		relAll()
		AP.Mode = v
		AP.PC = nil
	end
end
cn(you.DescendantAdded, function(x)
	if x.Name == "NotesContainer" then
		bind(x)
	elseif FL[x.Name] then
		AP.PC = nil
	end
end)
cn(you.DescendantRemoving, function(x)
	if x.Name == "NotesContainer" or FL[x.Name] then
		AP.PC = nil
	end
end)
bindall()
function AP.Unload()
	if AP.Unloaded then
		return
	end
	AP.Unloaded = true
	AP.Enabled = false
	AP.Generation += 1
	relAll()
	for _, c in ipairs(AP.Connections) do
		pcall(c.Disconnect, c)
	end
	for c, k in pairs(AP.ContainerConnections) do
		AP.ContainerConnections[c] = nil
		pcall(k.Disconnect, k)
	end
	if AP.UI then
		pcall(AP.UI.Unload, AP.UI)
	end
	if G.DeltaRhythmAutoplayer == AP then
		G.DeltaRhythmAutoplayer = nil
	end
end
task.wait()
local UI =
	L(game:HttpGet("https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"), "@VibeUI.luau")()
AP.UI = UI
local W = UI:Window({ Title = "DeltaRhythm Autoplayer", Keybind = Enum.KeyCode.RightControl })
local T = W:Tab({ Name = "Autoplayer", Columns = 1 })
local M = T:Section({ Name = "Main", Side = 1 })
AP.Controls = {}
AP.Controls.Enabled =
	M:Toggle({ Name = "Enabled", Flag = "DeltaRhythmAutoplayerEnabled", Default = false, Callback = enabled })
if HAS_FIRESIGNAL then
	AP.Controls.Mode = M:Dropdown({
		Name = "Input Mode",
		Flag = "DeltaRhythmAutoplayerMode",
		Items = { "Virtual Input", "firesignal" },
		Default = "Virtual Input",
		Callback = AP.SetMode,
	})
else
	AP.Mode = "Virtual Input"
	AP.Controls.Mode = nil
end
AP.Controls.Tap = M:Slider({
	Name = "Tap Release",
	Flag = "DeltaRhythmTapRelease",
	Min = 10,
	Max = 80,
	Default = 35,
	Suffix = " ms",
	Callback = function(v)
		AP.TapRelease = v / 1000
	end,
})
UI:CreateSettingsPage(W)
UI:Notification({
	Title = "Autoplayer loaded",
	Description = HAS_FIRESIGNAL and "Live Lane_* tracking with per-round input refresh."
		or "Virtual Input mode enabled; firesignal is unavailable on this executor.",
	Type = "success",
})