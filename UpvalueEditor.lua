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
local uis = __lt.cs("UserInputService", __lt.cr)
local run = __lt.cs("RunService", __lt.cr)
local gs = __lt.cs("GuiService", __lt.cr)
local cg = __lt.cs("CoreGui", __lt.cr)
local starterGui = __lt.cs("StarterGui", __lt.cr)
local http = __lt.cs("HttpService", __lt.cr)

local plr = players.LocalPlayer
local cam = workspaceRef.CurrentCamera
local pg = plr and plr:FindFirstChildOfClass("PlayerGui")
if not pg and plr then
	pg = plr:WaitForChild("PlayerGui")
end
local playerModule = pg and pg:FindFirstChild("PlayerModule", true) or nil
local chatScript = nil

local dbg = debug
local rawGetGc = getgc or get_gc_objects
local rawGetInfo = (dbg and dbg.getinfo) or getinfo
local rawGetUpvalue = (dbg and dbg.getupvalue) or getupvalue or getupval
local rawSetUpvalue = (dbg and dbg.setupvalue) or setupvalue or setupval
local rawGetUpvalues = (dbg and dbg.getupvalues) or getupvalues or getupvals
local rawGetConstants = (dbg and dbg.getconstants) or getconstants or getconsts
local setClipboard = setclipboard
	or writeclipboard
	or toclipboard
	or set_clipboard
	or (Clipboard and Clipboard.set)
	or (clipboard and clipboard.set)
local isXClosure = is_synapse_function
	or issentinelclosure
	or is_protosmasher_closure
	or is_sirhurt_closure
	or iselectronfunction
	or istempleclosure
	or checkclosure
	or function()
		return false
	end
local isLClosure = islclosure
	or is_l_closure
	or (iscclosure and function(f)
		return not iscclosure(f)
	end)

if type(rawGetGc) ~= "function"
	or type(rawGetInfo) ~= "function"
	or type(rawGetUpvalue) ~= "function"
	or type(rawSetUpvalue) ~= "function"
	or type(rawGetUpvalues) ~= "function" then
	pcall(function()
		starterGui:SetCore("SendNotification", {
			Title = "Upvalue Editor",
			Text = "Missing getgc/debug upvalue methods in this executor.",
			Duration = 7,
		})
	end)
	return
end

local function getUpvalueCompat(closure, index)
	if type(closure) == "table" and closure.Data then
		return rawGetUpvalue(closure.Data, index)
	end
	return rawGetUpvalue(closure, index)
end

local function getUpvaluesCompat(closure)
	if type(closure) == "table" and closure.Data then
		return rawGetUpvalues(closure.Data)
	end
	return rawGetUpvalues(closure)
end

local function setUpvalueCompat(closure, index, value)
	if type(closure) == "table" and closure.Data then
		return rawSetUpvalue(closure.Data, index, value)
	end
	return rawSetUpvalue(closure, index, value)
end

local tag = "UpvalueEditTag"

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
		or (plr and plr:FindFirstChildWhichIsA("PlayerGui"))
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
local dragged = false
local minimized = false
local sid = 0
local pmb

local closures = {}
local selectedClosure
local selectedUpvalue
local deepSearch = false
local showps = false
local showAllUpvalues = false
local showAllElements = false
local mode = "closures"
local statusText = ""
local lastScanQuery = ""
local lastSkippedPS = 0
local loopLocks = {}
local closureScript

local tempColors = {
	card = Color3.fromRGB(34, 20, 20),
	border = Color3.fromRGB(56, 28, 28),
}

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
		if pg then
			g.Parent = pg
		end
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

local function notify(msg)
	task.spawn(function()
		for _ = 1, 6 do
			local ok = pcall(function()
				starterGui:SetCore("SendNotification", {
					Title = "Upvalue Editor",
					Text = tostring(msg),
					Duration = 5,
				})
			end)
			if ok then
				return
			end
			task.wait(0.2)
		end
	end)
end

local function low(s)
	return string.lower(tostring(s))
end

local function has(txt, q)
	return string.find(low(txt), low(q), 1, true) ~= nil
end

local function trim(s)
	return (tostring(s):match("^%s*(.-)%s*$"))
end

local function cut(s, n)
	s = tostring(s)
	if #s <= n then
		return s
	end
	return string.sub(s, 1, n - 3) .. "..."
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

local function fmt(v)
	local t = typeof(v)
	if t == "string" then
		return v
	end
	if t == "boolean" then
		return v and "true" or "false"
	end
	if t == "nil" then
		return "nil"
	end
	if t == "Instance" then
		if v:IsA("Animation") then
			return v.AnimationId
		end
		if v:IsA("ValueBase") then
			return fmt(v.Value)
		end
		return v:GetFullName()
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
		return string.format("UDim2.new(%.9g, %.9g, %.9g, %.9g)", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
	end
	if t == "BrickColor" then
		return string.format("BrickColor.new(%q)", v.Name)
	end
	if t == "NumberRange" then
		return string.format("NumberRange.new(%.9g, %.9g)", v.Min, v.Max)
	end
	if t == "Rect" then
		return string.format("Rect.new(%.9g, %.9g, %.9g, %.9g)", v.Min.X, v.Min.Y, v.Max.X, v.Max.Y)
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
	if t == "table" then
		return "table"
	end
	return tostring(v)
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
	local s = low(err)
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
		end
		local item = old.EnumType[s]
		if item ~= nil then
			return item, true
		end
		return nil, false
	end
	return nil, false
end

local function sortkeys(t)
	local out = {}
	for k in pairs(t) do
		out[#out + 1] = k
	end
	table.sort(out, function(a, b)
		local ta, tb = typeof(a), typeof(b)
		if ta == tb then
			if ta == "number" then
				return a < b
			end
			return tostring(a) < tostring(b)
		end
		if ta == "number" then
			return true
		end
		if tb == "number" then
			return false
		end
		return ta < tb
	end)
	return out
end

local function tablecount(t)
	local n = 0
	for _ in pairs(t) do
		n += 1
	end
	return n
end

local function getInstancePath(instance)
	if typeof(instance) ~= "Instance" then
		return "nil"
	end
	if instance == game then
		return "game"
	end

	local chain = {}
	local obj = instance
	while obj and obj ~= game do
		local name = obj.Name
		if string.match(name, "^[%a_][%w_]*$") then
			chain[#chain + 1] = "." .. name
		else
			chain[#chain + 1] = "[" .. string.format("%q", name) .. "]"
		end
		obj = obj.Parent
	end

	local parts = {"game"}
	for i = #chain, 1, -1 do
		parts[#parts + 1] = chain[i]
	end
	return table.concat(parts)
end

local function normalizeCopyPath(path)
	if type(path) ~= "string" then
		return path
	end

	if string.sub(path, 1, 28) == "game:GetService(\"Workspace\")" then
		path = string.gsub(path, "game:GetService%(\"Workspace\"%)", "workspace", 1)
	end

	if plr and string.sub(path, 1, 10 + #plr.Name) == "workspace." .. plr.Name then
		path = string.gsub(
			path,
			"workspace%." .. plr.Name,
			"game:GetService(\"Players\").LocalPlayer.Character",
			1
		)
	end

	if plr and string.sub(path, 1, 27 + #plr.Name) == "game:GetService(\"Players\")." .. plr.Name then
		path = string.gsub(
			path,
			"game:GetService%(\"Players\"%)." .. plr.Name,
			"game:GetService(\"Players\").LocalPlayer",
			1
		)
	end

	return path
end

local function getCopiedInstancePath(obj)
	if typeof(obj) ~= "Instance" then
		return "nil"
	end

	local path = ""
	local current = obj

	while current do
		if current == game then
			path = "game" .. path
			break
		end

		local className = current.ClassName
		local currentName = tostring(current)
		local indexName

		if string.match(currentName, "^[%a_][%w_]*$") then
			indexName = "." .. currentName
		else
			indexName = "[" .. string.format("%q", currentName) .. "]"
		end

		local parent = current.Parent
		if parent then
			local firstChild = parent:FindFirstChild(currentName)
			if firstChild and firstChild ~= current then
				local siblings = parent:GetChildren()
				local childIndex = table.find(siblings, current)
				if childIndex then
					indexName = ":GetChildren()[" .. childIndex .. "]"
				end
			elseif parent == game then
				indexName = ":GetService(\"" .. className .. "\")"
			end
		else
			indexName = ("local getNil = function(name, class) for _, v in next, getnilinstances() do if v.ClassName == class and v.Name == name then return v end end end\n\ngetNil(%q, %q)"):format(current.Name, className)
		end

		path = indexName .. path
		current = parent
	end

	return normalizeCopyPath(path)
end

local function valuepreview(v)
	local ty = typeof(v)
	if ty == "function" then
		local ok, info = pcall(rawGetInfo, v)
		local name = ok and info and info.name or ""
		return name ~= "" and name or "Unnamed function"
	end
	if ty == "table" then
		return tablecount(v) .. " entries"
	end
	if ty == "Instance" and not isinstedit(v) then
		return v.ClassName .. " | " .. getInstancePath(v)
	end
	return cut(fmt(editvalue(v)), 100)
end

local Closure = {}
local closureCache = {}

function Closure.new(data)
	if closureCache[data] then
		return closureCache[data]
	end

	local info = rawGetInfo(data)
	local name = info and info.name or ""
	local closure = {
		Name = (name ~= "" and name) or "Unnamed function",
		Data = data,
		Environment = getfenv(data),
		Upvalues = {},
		Constants = {},
		TemporaryUpvalues = {},
		TemporaryConstants = {},
	}

	closureCache[data] = closure
	return closure
end

local Upvalue = {}

function Upvalue.new(closure, index, value)
	local upvalue = {
		Closure = closure,
		Index = index,
		Value = value,
		Set = Upvalue.set,
		Update = Upvalue.update,
	}
	return upvalue
end

function Upvalue.set(upvalue, value)
	setUpvalueCompat(upvalue.Closure, upvalue.Index, value)
	upvalue.Value = value
end

function Upvalue.update(upvalue, newValue)
	local value = newValue
	if value == nil then
		value = getUpvalueCompat(upvalue.Closure, upvalue.Index)
	end
	local scanned = upvalue.Scanned

	upvalue.Value = value

	if type(value) ~= "table" and scanned then
		upvalue.Scanned = nil
		upvalue.TemporaryElements = nil
	elseif scanned then
		for i in pairs(scanned) do
			scanned[i] = value[i]
		end
	end
end

local function compareQuery(query, value, ignoreNumber)
	local valueType = type(value)
	local queryLower = low(query)

	if valueType == "string" then
		return value == query or has(value, query)
	end
	if valueType == "number" and not ignoreNumber then
		return tonumber(query) == value or string.format("%.2f", value) == query
	end
	if valueType == "boolean" then
		return queryLower == tostring(value)
	end
	if valueType == "userdata" then
		if typeof(value) == "Instance" then
			return value.Name == query
				or has(value.Name, query)
				or has(value.ClassName, query)
				or has(getInstancePath(value), query)
		end
		return has(tostring(value), query)
	end
	if valueType == "function" then
		local ok, info = pcall(rawGetInfo, value)
		local name = ok and info and info.name or ""
		return query == name or has(name, query)
	end
	return has(tostring(value), query)
end

local function isfilteredclosure(closure)
	if showps then
		return false
	end

	if not playerModule then
		local ps = plr and plr:FindFirstChild("PlayerScripts")
		if ps then
			playerModule = ps:FindFirstChild("PlayerModule", true)
			chatScript = chatScript or ps:FindFirstChild("ChatScript", true)
		end
	end

	if not chatScript then
		local ps = plr and plr:FindFirstChild("PlayerScripts")
		if ps then
			chatScript = ps:FindFirstChild("ChatScript", true)
		end
	end

	local script = closureScript and closureScript(closure)
	if typeof(script) ~= "Instance" then
		return false
	end
	if playerModule and script:IsDescendantOf(playerModule) then
		return true
	end
	if chatScript and script:IsDescendantOf(chatScript) then
		return true
	end
	return false
end

local function scanUpvalues(query, deep)
	local found = {}
	local blocked = {}
	local skipped = 0

	for _, closureData in pairs(rawGetGc()) do
		if type(closureData) == "function"
			and not isXClosure(closureData)
			and (not isLClosure or isLClosure(closureData)) then
			local ok, upvalues = pcall(getUpvaluesCompat, closureData)
			if ok and type(upvalues) == "table" then
				for index, value in pairs(upvalues) do
					local valueType = type(value)
					if valueType ~= "table" and compareQuery(query, value) then
						local closure = found[closureData]
						if not closure and not blocked[closureData] then
							closure = Closure.new(closureData)
							if isfilteredclosure(closure) then
								blocked[closureData] = true
								skipped += 1
							else
								found[closureData] = closure
							end
						end
						if found[closureData] then
							closure.Upvalues[index] = Upvalue.new(closure, index, value)
						end
					elseif deep and valueType == "table" then
						local closure = found[closureData]
						local tableUpvalue
						for i, v in pairs(value) do
							if (i ~= value and v ~= value) and (compareQuery(query, i, true) or compareQuery(query, v)) then
								if not closure and not blocked[closureData] then
									closure = Closure.new(closureData)
									if isfilteredclosure(closure) then
										blocked[closureData] = true
										skipped += 1
										break
									else
										found[closureData] = closure
									end
								end
								if not found[closureData] then
									break
								end
								if not tableUpvalue then
									tableUpvalue = Upvalue.new(closure, index, value)
									tableUpvalue.Scanned = {}
									closure.Upvalues[index] = tableUpvalue
								end
								tableUpvalue.Scanned[i] = v
							end
						end
					end
				end
			end
		end
	end

	local list = {}
	for _, closure in pairs(found) do
		list[#list + 1] = closure
	end

	table.sort(list, function(a, b)
		if a.Name == b.Name then
			return getInstancePath(rawget(a.Environment, "script")) < getInstancePath(rawget(b.Environment, "script"))
		end
		return a.Name < b.Name
	end)

	return list, skipped
end

local function ensureAllUpvalues(closure)
	if not closure then
		return
	end
	local ok, values = pcall(getUpvaluesCompat, closure)
	if not ok or type(values) ~= "table" then
		statusText = "failed to read upvalues"
		return
	end
	for index, value in pairs(values) do
		if not closure.Upvalues[index] and not closure.TemporaryUpvalues[index] then
			local upvalue = Upvalue.new(closure, index, value)
			if type(value) == "table" then
				upvalue.Scanned = {}
			end
			upvalue.Temporary = true
			closure.TemporaryUpvalues[index] = upvalue
		end
	end
end

local function ensureAllElements(upvalue)
	if not upvalue or type(upvalue.Value) ~= "table" then
		return
	end
	local scanned = upvalue.Scanned or {}
	upvalue.Scanned = scanned
	local temporary = upvalue.TemporaryElements or {}
	for index, value in pairs(upvalue.Value) do
		if scanned[index] == nil and temporary[index] == nil then
			temporary[index] = value
		end
	end
	upvalue.TemporaryElements = temporary
end

local function clearAllUpvalues(closure)
	if closure then
		closure.TemporaryUpvalues = {}
	end
end

local function clearAllElements(upvalue)
	if upvalue then
		upvalue.TemporaryElements = nil
	end
end

local function setElementValue(upvalue, key, newValue)
	local tbl = upvalue and upvalue.Value
	if type(tbl) ~= "table" then
		return false, "upvalue is not a table"
	end

	local ok, err = setvalue(tbl, key, newValue)
	if ok then
		if upvalue.Scanned and upvalue.Scanned[key] ~= nil then
			upvalue.Scanned[key] = tbl[key]
		end
		if upvalue.TemporaryElements and upvalue.TemporaryElements[key] ~= nil then
			upvalue.TemporaryElements[key] = tbl[key]
		end
		return true
	end

	if not isreadonlyerr(err) then
		return false, err
	end

	local clone = cloneplain(tbl)
	local wrote, writeErr = setvalue(clone, key, newValue)
	if not wrote then
		return false, writeErr or err
	end

	local setOk, setErr = pcall(function()
		upvalue:Set(clone)
	end)
	if not setOk then
		return false, setErr
	end

	if upvalue.Scanned and upvalue.Scanned[key] ~= nil then
		upvalue.Scanned[key] = clone[key]
	end
	if upvalue.TemporaryElements and upvalue.TemporaryElements[key] ~= nil then
		upvalue.TemporaryElements[key] = clone[key]
	end
	return true
end

local function closureRef(closure)
	if type(closure) == "table" and closure.Data then
		return closure.Data
	end
	return closure
end

local function sameUpvalueRef(a, b)
	return a ~= nil
		and b ~= nil
		and a.Index == b.Index
		and closureRef(a.Closure) == closureRef(b.Closure)
end

local function findLoopLock(target)
	if not target or not target.upvalue then
		return nil
	end

	for index, lock in ipairs(loopLocks) do
		if lock.kind == target.kind and sameUpvalueRef(lock.upvalue, target.upvalue) then
			if lock.kind ~= "element" or lock.key == target.key then
				lock.upvalue = target.upvalue
				return lock, index
			end
		end
	end
	return nil
end

local function setLoopLock(target, value, labelText)
	local lock = findLoopLock(target)
	if not lock then
		lock = {
			kind = target.kind,
			upvalue = target.upvalue,
			key = target.key,
		}
		loopLocks[#loopLocks + 1] = lock
	end

	lock.value = value
	lock.label = labelText
	lock.upvalue = target.upvalue
end

local function clearLoopLock(target)
	local _, index = findLoopLock(target)
	if index then
		table.remove(loopLocks, index)
		return true
	end
	return false
end

local function codelit(v)
	local t = typeof(v)
	if t == "string" then
		return string.format("%q", v)
	end
	if t == "number" then
		if v ~= v then
			return "0/0"
		end
		if v == math.huge then
			return "math.huge"
		end
		if v == -math.huge then
			return "-math.huge"
		end
		return string.format("%.17g", v)
	end
	if t == "boolean" then
		return v and "true" or "false"
	end
	if t == "nil" then
		return "nil"
	end
	if t == "Vector2" then
		return string.format("Vector2.new(%.17g, %.17g)", v.X, v.Y)
	end
	if t == "Vector3" then
		return string.format("Vector3.new(%.17g, %.17g, %.17g)", v.X, v.Y, v.Z)
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
		return string.format("UDim.new(%.17g, %.17g)", v.Scale, v.Offset)
	end
	if t == "UDim2" then
		return string.format("UDim2.new(%.17g, %.17g, %.17g, %.17g)", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
	end
	if t == "BrickColor" then
		return string.format("BrickColor.new(%q)", v.Name)
	end
	if t == "NumberRange" then
		return string.format("NumberRange.new(%.17g, %.17g)", v.Min, v.Max)
	end
	if t == "Rect" then
		return string.format("Rect.new(%.17g, %.17g, %.17g, %.17g)", v.Min.X, v.Min.Y, v.Max.X, v.Max.Y)
	end
	if t == "CFrame" then
		local c = {v:GetComponents()}
		for i = 1, #c do
			c[i] = string.format("%.17g", c[i])
		end
		return "CFrame.new(" .. table.concat(c, ", ") .. ")"
	end
	if t == "EnumItem" then
		return tostring(v)
	end
	if t == "Instance" then
		if v.Parent == nil and v ~= game then
			return nil, "cannot serialize detached Instance"
		end
		return getCopiedInstancePath(v)
	end
	return nil, "unsupported value type: " .. t
end

local function tablecodelit(data, root, indent)
	local dataType = type(data)

	if dataType == "string" or dataType == "number" or dataType == "boolean" or data == nil then
		return codelit(data)
	end
	if dataType == "userdata" then
		if typeof(data) == "Instance" then
			return getCopiedInstancePath(data)
		end
		return "placeholderUserdataConstant"
	end
	if dataType ~= "table" then
		return tostring(data)
	end

	indent = indent or 1
	root = root or data

	local lines = {"{"}
	local prefix = string.rep("\t", indent)
	local hadAny = false

	for k, v in pairs(data) do
		hadAny = true
		local keyCode
		local valueCode

		if k == root or v == root then
			keyCode = "\"OH_CYCLIC_PROTECTION\""
			valueCode = "\"OH_CYCLIC_PROTECTION\""
		else
			keyCode = tablecodelit(k, root, indent + 1)
			valueCode = tablecodelit(v, root, indent + 1)
		end

		lines[#lines + 1] = ("%s[%s] = %s,"):format(prefix, keyCode, valueCode)
	end

	if not hadAny then
		return "{}"
	end

	lines[#lines + 1] = string.rep("\t", indent - 1) .. "}"
	return table.concat(lines, "\n")
end

local function buildCopyCode(loopTarget, newValue, forceLoop)
	if not loopTarget or not loopTarget.upvalue then
		return nil, "missing target"
	end

	local closure = loopTarget.upvalue.Closure
	local closureData = closure and closure.Data
	if type(closureData) ~= "function" then
		return nil, "invalid closure"
	end

	local valueCode, valueErr = codelit(newValue)
	if not valueCode then
		return nil, valueErr
	end

	local keyCode = loopTarget.kind == "element" and codelit(loopTarget.key) or nil
	if loopTarget.kind == "element" and not keyCode then
		return nil, "unsupported table key type"
	end

	local currentConstants = {}
	local currentIndex = 0
	if type(rawGetConstants) == "function" then
		local ok, constants = pcall(rawGetConstants, closureData)
		if ok and type(constants) == "table" then
			for idx, constant in pairs(constants) do
				if currentIndex > 5 then
					break
				elseif type(constant) ~= "function" then
					currentConstants[idx] = constant
					currentIndex += 1
				end
			end
		end
	end

	local scriptObj = closureScript(closure)
	local scriptPath = scriptObj and getCopiedInstancePath(scriptObj) or nil
	local scriptPathExpr = scriptPath or "nil"
	local constantsCode = next(currentConstants) and tablecodelit(currentConstants) or "nil"
	local loopEnabled = forceLoop
	if loopEnabled == nil then
		loopEnabled = findLoopLock(loopTarget) ~= nil
	end

	local generated = {
		"-- Generated by Upvalue Editor",
		"local dbg = debug",
		"local runService = game:GetService(\"RunService\")",
		"local rawGetGc = getgc or get_gc_objects",
		"local getInfo = (dbg and dbg.getinfo) or getinfo",
		"local getUpvalue = (dbg and dbg.getupvalue) or getupvalue or getupval",
		"local getConstants = (dbg and dbg.getconstants) or getconstants or getconsts",
		"local setUpvalue = (dbg and dbg.setupvalue) or setupvalue or setupval",
		"local isXClosure = is_synapse_function or issentinelclosure or is_protosmasher_closure or is_sirhurt_closure or istempleclosure or checkclosure",
		"local isLClosure = islclosure or is_l_closure or (iscclosure and function(f) return not iscclosure(f) end)",
		"local placeholderUserdataConstant = newproxy(false)",
		"assert(type(rawGetGc) == \"function\", \"missing getgc\")",
		"assert(type(getInfo) == \"function\", \"missing debug.getinfo\")",
		"assert(type(getUpvalue) == \"function\", \"missing debug.getupvalue\")",
		"assert(type(getConstants) == \"function\", \"missing debug.getconstants\")",
		"assert(type(setUpvalue) == \"function\", \"missing debug.setupvalue\")",
		"assert(type(isXClosure) == \"function\", \"missing xclosure detector\")",
		"",
		"local closureName = " .. string.format("%q", closure.Name),
		"local upvalueIndex = " .. tostring(loopTarget.upvalue.Index),
		"local closureConstants = " .. constantsCode,
		"local value = " .. valueCode,
		"local loopValue = " .. tostring(loopEnabled),
	}

	if keyCode then
		generated[#generated + 1] = "local elementIndex = " .. keyCode
	end

	generated[#generated + 1] = ""
	generated[#generated + 1] = "local function getTargetScript()"
	if scriptPath then
		generated[#generated + 1] = "\treturn " .. scriptPathExpr
	else
		generated[#generated + 1] = "\treturn nil"
	end
	generated[#generated + 1] = "end"
	generated[#generated + 1] = ""
	generated[#generated + 1] = "local function matchConstants(func, list)"
	generated[#generated + 1] = "\tif not list then"
	generated[#generated + 1] = "\t\treturn true"
	generated[#generated + 1] = "\tend"
	generated[#generated + 1] = "\tlocal constants = getConstants(func)"
	generated[#generated + 1] = "\tfor index, constant in pairs(list) do"
	generated[#generated + 1] = "\t\tif constants[index] ~= constant and constant ~= placeholderUserdataConstant then"
	generated[#generated + 1] = "\t\t\treturn false"
	generated[#generated + 1] = "\t\tend"
	generated[#generated + 1] = "\tend"
	generated[#generated + 1] = "\treturn true"
	generated[#generated + 1] = "end"
	generated[#generated + 1] = ""
	generated[#generated + 1] = "local function searchClosure(targetScript)"
	generated[#generated + 1] = "\tfor _, func in pairs(rawGetGc()) do"
	generated[#generated + 1] = "\t\tif type(func) == \"function\" and (not isLClosure or isLClosure(func)) and not isXClosure(func) then"
	generated[#generated + 1] = "\t\t\tlocal okEnv, env = pcall(getfenv, func)"
	generated[#generated + 1] = "\t\t\tlocal parentScript = okEnv and env and rawget(env, \"script\") or nil"
	generated[#generated + 1] = "\t\t\tlocal validScript = (targetScript == nil and (typeof(parentScript) ~= \"Instance\" or parentScript.Parent == nil)) or parentScript == targetScript"
	generated[#generated + 1] = "\t\t\tif validScript and pcall(getUpvalue, func, upvalueIndex) then"
	generated[#generated + 1] = "\t\t\t\tlocal info = getInfo(func)"
	generated[#generated + 1] = "\t\t\t\tif (((closureName and closureName ~= \"Unnamed function\") and info.name == closureName) or (not closureName or closureName == \"Unnamed function\")) and matchConstants(func, closureConstants) then"
	generated[#generated + 1] = "\t\t\t\t\treturn func"
	generated[#generated + 1] = "\t\t\t\tend"
	generated[#generated + 1] = "\t\t\tend"
	generated[#generated + 1] = "\t\tend"
	generated[#generated + 1] = "\tend"
	generated[#generated + 1] = "end"
	generated[#generated + 1] = ""
	generated[#generated + 1] = "local cachedScript"
	generated[#generated + 1] = "local cachedClosure"
	generated[#generated + 1] = ""
	generated[#generated + 1] = "local function resolveClosure()"
	generated[#generated + 1] = "\tlocal targetScript = getTargetScript()"
	generated[#generated + 1] = "\tif cachedClosure and cachedScript == targetScript and pcall(getUpvalue, cachedClosure, upvalueIndex) then"
	generated[#generated + 1] = "\t\treturn cachedClosure"
	generated[#generated + 1] = "\tend"
	generated[#generated + 1] = "\tcachedScript = targetScript"
	generated[#generated + 1] = "\tcachedClosure = searchClosure(targetScript)"
	generated[#generated + 1] = "\treturn assert(cachedClosure, \"target closure not found\")"
	generated[#generated + 1] = "end"
	generated[#generated + 1] = ""
	generated[#generated + 1] = "local function apply()"
	generated[#generated + 1] = "\tlocal closure = resolveClosure()"

	if keyCode then
		generated[#generated + 1] = "\tgetUpvalue(closure, upvalueIndex)[elementIndex] = value"
	else
		generated[#generated + 1] = "\tsetUpvalue(closure, upvalueIndex, value)"
	end

	generated[#generated + 1] = "end"
	generated[#generated + 1] = ""
	generated[#generated + 1] = "apply()"

	if loopEnabled then
		generated[#generated + 1] = ""
		generated[#generated + 1] = "runService.PreSimulation:Connect(function()"
		generated[#generated + 1] = "\tpcall(apply)"
		generated[#generated + 1] = "end)"
	end

	return table.concat(generated, "\n")
end

local function applyLoopLock(lock)
	if lock.kind == "element" then
		return setElementValue(lock.upvalue, lock.key, lock.value)
	end

	local ok, err = pcall(function()
		lock.upvalue:Set(lock.value)
	end)
	if ok then
		return true
	end
	return false, err
end

local function enforceLoopLocks()
	if dead or #loopLocks == 0 then
		return
	end

	local removedStatus

	for index = #loopLocks, 1, -1 do
		local lock = loopLocks[index]
		local ok, wrote, err = pcall(applyLoopLock, lock)
		if not ok then
			table.remove(loopLocks, index)
			removedStatus = "loop removed: " .. tostring(lock.label) .. " (" .. tostring(wrote) .. ")"
		elseif not wrote then
			table.remove(loopLocks, index)
			removedStatus = "loop removed: " .. tostring(lock.label) .. " (" .. tostring(err) .. ")"
		end
	end

	if removedStatus then
		statusText = removedStatus
	end
end

local bg = mk("Frame", {
	Parent = gui,
	BackgroundColor3 = Color3.fromRGB(8, 8, 8),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
})

local frm = mk("Frame", {
	Parent = gui,
	BackgroundColor3 = Color3.fromRGB(14, 14, 14),
	BorderSizePixel = 0,
})

mk("UICorner", {
	Parent = frm,
	CornerRadius = UDim.new(0, 14),
})

local top = mk("Frame", {
	Parent = frm,
	BackgroundColor3 = Color3.fromRGB(18, 18, 18),
	BorderSizePixel = 0,
})

mk("UICorner", {
	Parent = top,
	CornerRadius = UDim.new(0, 14),
})

local top2 = mk("Frame", {
	Parent = top,
	BackgroundColor3 = Color3.fromRGB(18, 18, 18),
	BorderSizePixel = 0,
})

local ttl = mk("TextLabel", {
	Parent = top,
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "Upvalue Editor",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local back = mk("TextButton", {
	Parent = top,
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(28, 28, 28),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "Back",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13,
})

mk("UICorner", {
	Parent = back,
	CornerRadius = UDim.new(0, 8),
})

local scanb = mk("TextButton", {
	Parent = top,
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(28, 28, 28),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "Scan",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13,
})

mk("UICorner", {
	Parent = scanb,
	CornerRadius = UDim.new(0, 8),
})

local allb = mk("TextButton", {
	Parent = top,
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(28, 28, 28),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "All Off",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13,
})

mk("UICorner", {
	Parent = allb,
	CornerRadius = UDim.new(0, 8),
})

pmb = mk("TextButton", {
	Parent = top,
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(28, 28, 28),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "PS Off",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13,
})

mk("UICorner", {
	Parent = pmb,
	CornerRadius = UDim.new(0, 8),
})

local deepb = mk("TextButton", {
	Parent = top,
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(28, 28, 28),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "Deep Off",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13,
})

mk("UICorner", {
	Parent = deepb,
	CornerRadius = UDim.new(0, 8),
})

local cls = mk("TextButton", {
	Parent = top,
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(50, 20, 20),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "X",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 13,
})

mk("UICorner", {
	Parent = cls,
	CornerRadius = UDim.new(0, 8),
})

local minb = mk("TextButton", {
	Parent = top,
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(28, 28, 28),
	BorderSizePixel = 0,
	Font = Enum.Font.GothamBold,
	Text = "-",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 16,
})

mk("UICorner", {
	Parent = minb,
	CornerRadius = UDim.new(0, 8),
})

local srh = mk("TextBox", {
	Parent = frm,
	BackgroundColor3 = Color3.fromRGB(20, 20, 20),
	BorderSizePixel = 0,
	ClearTextOnFocus = false,
	Font = Enum.Font.Gotham,
	PlaceholderColor3 = Color3.fromRGB(140, 140, 140),
	PlaceholderText = "Search upvalues, elements, function names...",
	Text = "",
	TextColor3 = Color3.new(1, 1, 1),
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
})

mk("UICorner", {
	Parent = srh,
	CornerRadius = UDim.new(0, 10),
})

local tabf = mk("Frame", {
	Parent = frm,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
})

local tabs = {}

local function mktab(txt, key)
	local b = mk("TextButton", {
		Parent = tabf,
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(24, 24, 24),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		Text = txt,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 13,
	})
	mk("UICorner", {
		Parent = b,
		CornerRadius = UDim.new(0, 9),
	})
	tabs[key] = b
	return b
end

mktab("Closures", "closures")
mktab("Upvalues", "upvalues")
mktab("Elements", "elements")

local path = mk("TextLabel", {
	Parent = frm,
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "",
	TextColor3 = Color3.fromRGB(200, 200, 200),
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local stat = mk("TextLabel", {
	Parent = frm,
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "",
	TextColor3 = Color3.fromRGB(170, 170, 170),
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Right,
})

local body = mk("ScrollingFrame", {
	Parent = frm,
	BackgroundColor3 = Color3.fromRGB(18, 18, 18),
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.None,
})

mk("UICorner", {
	Parent = body,
	CornerRadius = UDim.new(0, 12),
})

mk("UIPadding", {
	Parent = body,
	PaddingTop = UDim.new(0, 8),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
})

local listc = mk("Frame", {
	Parent = body,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 0),
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
	local minW = mobile and math.min(300, maxW) or 360
	local minH = mobile and math.min(320, maxH) or 360
	local w = math.clamp(maxW, minW, 1120)
	local h = math.clamp(maxH, minH, 820)
	local bodyH = minimized and 42 or h
	frm.Size = UDim2.fromOffset(w, bodyH)
	if not dragged then
		frm.Position = UDim2.fromOffset(math.floor((vp.X - w) * 0.5), math.floor((vp.Y - bodyH) * 0.5))
	end

	top.Size = UDim2.new(1, 0, 0, 42)
	top2.Size = UDim2.new(1, 0, 0, 14)
	top2.Position = UDim2.new(0, 0, 1, -14)

	ttl.Position = UDim2.fromOffset(10, 0)

	local bw = math.max(52, math.floor(w * 0.08))
	local cw = math.max(42, math.floor(w * 0.06))
	local tw = math.max(74, math.floor(w * 0.09))
	local pw = math.max(72, math.floor(w * 0.1))

	cls.Size = UDim2.fromOffset(cw, 26)
	cls.Position = UDim2.new(1, -cw - 10, 0.5, -13)

	minb.Size = UDim2.fromOffset(cw, 26)
	minb.Position = UDim2.new(1, -cw * 2 - 18, 0.5, -13)

	pmb.Size = UDim2.fromOffset(pw, 26)
	pmb.Position = UDim2.new(1, -(cw * 2 + pw + 26), 0.5, -13)

	deepb.Size = UDim2.fromOffset(tw, 26)
	deepb.Position = UDim2.new(1, -(cw * 2 + pw + tw + 34), 0.5, -13)

	allb.Size = UDim2.fromOffset(tw, 26)
	allb.Position = UDim2.new(1, -(cw * 2 + pw + tw * 2 + 42), 0.5, -13)

	scanb.Size = UDim2.fromOffset(math.max(56, bw), 26)
	scanb.Position = UDim2.new(1, -(cw * 2 + pw + tw * 2 + bw + 50), 0.5, -13)

	back.Size = UDim2.fromOffset(math.max(56, bw), 26)
	back.Position = UDim2.new(1, -(cw * 2 + pw + tw * 2 + bw * 2 + 58), 0.5, -13)

	ttl.Size = UDim2.new(1, -(back.Size.X.Offset + scanb.Size.X.Offset + allb.Size.X.Offset + deepb.Size.X.Offset + pmb.Size.X.Offset + minb.Size.X.Offset + cls.Size.X.Offset + 78), 1, 0)

	srh.Visible = not minimized
	tabf.Visible = not minimized
	path.Visible = not minimized
	stat.Visible = not minimized
	body.Visible = not minimized

	srh.Position = UDim2.fromOffset(8, 50)
	srh.Size = UDim2.new(1, -16, 0, 34)

	tabf.Position = UDim2.fromOffset(8, 90)
	tabf.Size = UDim2.new(1, -16, 0, 34)

	local tabw = math.floor((w - 32) / 3)
	local x = 0
	for _, key in ipairs({"closures", "upvalues", "elements"}) do
		local b = tabs[key]
		b.Position = UDim2.fromOffset(x, 0)
		b.Size = UDim2.new(0, tabw - 4, 1, 0)
		x += tabw
	end

	path.Position = UDim2.fromOffset(10, 132)
	path.Size = UDim2.new(0.64, -10, 0, 22)

	stat.Position = UDim2.new(0.64, 0, 0, 132)
	stat.Size = UDim2.new(0.36, -10, 0, 22)

	body.Position = UDim2.fromOffset(8, 158)
	body.Size = UDim2.new(1, -16, 1, -166)
end

fit()

local function card(parent, y, h, temporary)
	local f = mk("Frame", {
		Parent = parent,
		BackgroundColor3 = temporary and tempColors.card or Color3.fromRGB(24, 24, 24),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, h),
	})
	mk("UICorner", {
		Parent = f,
		CornerRadius = UDim.new(0, 10),
	})
	if temporary then
		local stroke = mk("UIStroke", {
			Parent = f,
			Color = tempColors.border,
			Thickness = 1,
			Transparency = 0.2,
		})
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end
	return f
end

local function clear()
	for _, v in ipairs(listc:GetChildren()) do
		v:Destroy()
	end
end

closureScript = function(closure)
	local env = closure and closure.Environment
	local scr = env and rawget(env, "script")
	if typeof(scr) == "Instance" and scr.Parent ~= nil then
		return scr
	end
	return nil
end

local function currentPath()
	if mode == "closures" then
		return "Closures"
	end
	if mode == "upvalues" and selectedClosure then
		local scr = closureScript(selectedClosure)
		local suffix = scr and (" | " .. getInstancePath(scr)) or ""
		return selectedClosure.Name .. suffix
	end
	if mode == "elements" and selectedClosure and selectedUpvalue then
		return selectedClosure.Name .. " .upvalue[" .. tostring(selectedUpvalue.Index) .. "]"
	end
	return "Closures"
end

local draw

local function updateButtons()
	back.BackgroundColor3 = mode == "closures" and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(28, 28, 28)
	back.TextColor3 = mode == "closures" and Color3.fromRGB(120, 120, 120) or Color3.new(1, 1, 1)

	pmb.Text = showps and "PS On" or "PS Off"
	pmb.BackgroundColor3 = showps and Color3.fromRGB(36, 62, 92) or Color3.fromRGB(28, 28, 28)

	deepb.Text = deepSearch and "Deep On" or "Deep Off"
	deepb.BackgroundColor3 = deepSearch and Color3.fromRGB(36, 62, 92) or Color3.fromRGB(28, 28, 28)

	if mode == "upvalues" then
		allb.Text = showAllUpvalues and "All On" or "All Off"
		allb.BackgroundColor3 = showAllUpvalues and Color3.fromRGB(60, 40, 24) or Color3.fromRGB(28, 28, 28)
		allb.TextColor3 = selectedClosure and Color3.new(1, 1, 1) or Color3.fromRGB(120, 120, 120)
	elseif mode == "elements" then
		allb.Text = showAllElements and "All On" or "All Off"
		allb.BackgroundColor3 = showAllElements and Color3.fromRGB(60, 40, 24) or Color3.fromRGB(28, 28, 28)
		allb.TextColor3 = selectedUpvalue and Color3.new(1, 1, 1) or Color3.fromRGB(120, 120, 120)
	else
		allb.Text = "Matches"
		allb.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		allb.TextColor3 = Color3.fromRGB(120, 120, 120)
	end

	for key, button in pairs(tabs) do
		local on = key == mode
		button.BackgroundColor3 = on and Color3.fromRGB(235, 235, 235) or Color3.fromRGB(24, 24, 24)
		button.TextColor3 = on and Color3.fromRGB(10, 10, 10) or Color3.new(1, 1, 1)
	end
end

local function filtered(text, query)
	return query == "" or has(text, query)
end

local function rowButton(parent, callback)
	local b = mk("TextButton", {
		Parent = parent,
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Text = "",
	})
	if callback then
		bind(b.Activated, callback)
	end
	return b
end

local function actionButton(parent, text, x, y, w, callback, color)
	local b = mk("TextButton", {
		Parent = parent,
		AutoButtonColor = false,
		BackgroundColor3 = color or Color3.fromRGB(40, 40, 40),
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, 34),
		Font = Enum.Font.GothamBold,
		Text = text,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 12,
	})
	mk("UICorner", {
		Parent = b,
		CornerRadius = UDim.new(0, 8),
	})
	bind(b.Activated, callback)
	return b
end

local function showmsg(y, a, b)
	local f = card(listc, y, 70, false)
	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.new(1, -20, 0, 22),
		Font = Enum.Font.GothamBold,
		Text = a,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
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
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	return 70
end

local function closureRow(y, closure)
	local upvalueCount = tablecount(closure.Upvalues)
	local tempCount = tablecount(closure.TemporaryUpvalues)
	local script = closureScript(closure)
	local f = card(listc, y, 68, false)

	if selectedClosure == closure and mode ~= "closures" then
		f.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	end

	rowButton(f, function()
		selectedClosure = closure
		selectedUpvalue = nil
		showAllElements = false
		mode = "upvalues"
		srh.Text = ""
		draw()
	end)

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -84, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = closure.Name,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 28),
		Size = UDim2.new(1, -20, 0, 16),
		Font = Enum.Font.Gotham,
		Text = cut(script and getInstancePath(script) or "Detached / unknown script", 96),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 46),
		Size = UDim2.new(1, -20, 0, 14),
		Font = Enum.Font.Gotham,
		Text = upvalueCount .. " matched" .. (tempCount > 0 and (" | +" .. tempCount .. " extra") or ""),
		TextColor3 = Color3.fromRGB(140, 200, 255),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	if setClipboard and script then
		local copyButton = actionButton(f, "Copy", 0, 17, 64, function()
			pcall(setClipboard, getInstancePath(script))
			statusText = "script path copied"
			draw()
		end)
		copyButton.Position = UDim2.new(1, -74, 0, 17)
	end

	return 68
end

local function tableCounts(upvalue)
	local total = type(upvalue.Value) == "table" and tablecount(upvalue.Value) or 0
	local matched = upvalue.Scanned and tablecount(upvalue.Scanned) or 0
	local extra = upvalue.TemporaryElements and tablecount(upvalue.TemporaryElements) or 0
	return total, matched, extra
end

local function openUpvalue(upvalue)
	selectedUpvalue = upvalue
	showAllElements = false
	mode = "elements"
	srh.Text = ""
	draw()
end

local function valueRow(y, labelText, value, applyFn, temporary, loopTarget)
	local raw = editvalue(value)
	local ty = edittype(value)
	local h = typeof(raw) == "boolean" and 72 or 146
	local f = card(listc, y, h, temporary)

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -80, 0, 18),
		Font = Enum.Font.GothamBold,
		Text = labelText,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
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
		TextXAlignment = Enum.TextXAlignment.Right,
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
			TextSize = 13,
		})
		mk("UICorner", {
			Parent = tog,
			CornerRadius = UDim.new(0, 8),
		})
		bind(tog.Activated, function()
			local ok, err = applyFn(not raw)
			if not ok then
				statusText = "failed: " .. tostring(err)
			end
			draw()
		end)
	else
		local loopLock = loopTarget and findLoopLock(loopTarget) or nil
		local box = mk("TextBox", {
			Parent = f,
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			Position = UDim2.fromOffset(10, 32),
			Size = UDim2.new(1, -20, 0, 34),
			Font = Enum.Font.Code,
			Text = fmt(loopLock and loopLock.value or value),
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		mk("UICorner", {
			Parent = box,
			CornerRadius = UDim.new(0, 8),
		})

		local function parseInput()
			local newValue, ok = parse(box.Text, value)
			if not ok then
				local msg = "bad value"
				local hx = hint(value)
				if hx then
					msg ..= " (" .. hx .. ")"
				end
				statusText = msg
				box.Text = fmt(loopLock and loopLock.value or value)
				return nil
			end
			return newValue
		end

		local function apply()
			local newValue = parseInput()
			if newValue == nil then
				return
			end
			local wrote, err = applyFn(newValue)
			if not wrote then
				statusText = "failed: " .. tostring(err)
				box.Text = fmt(loopLock and loopLock.value or value)
				return
			end
			if loopTarget then
				local activeLock = findLoopLock(loopTarget)
				if activeLock then
					activeLock.value = newValue
				end
			end
			statusText = labelText .. " = " .. cut(fmt(newValue), 80)
			draw()
		end

		local function toggleLoop()
			if not loopTarget then
				return
			end

			local activeLock = findLoopLock(loopTarget)
			if activeLock then
				clearLoopLock(loopTarget)
				statusText = "loop off: " .. labelText
				draw()
				return
			end

			local newValue = parseInput()
			if newValue == nil then
				return
			end

			local wrote, err = applyFn(newValue)
			if not wrote then
				statusText = "failed: " .. tostring(err)
				box.Text = fmt(loopLock and loopLock.value or value)
				return
			end

			setLoopLock(loopTarget, newValue, labelText)
			statusText = "loop on: " .. labelText .. " = " .. cut(fmt(newValue), 80)
			draw()
		end

		local function copyCode(forceLoop)
			local ok, success, err = pcall(function()
				local newValue = parseInput()
				if newValue == nil then
					return false, "bad value"
				end

				local code, err = buildCopyCode(loopTarget, newValue, forceLoop)
				if not code then
					return false, err
				end
				if not setClipboard then
					return false, "clipboard unavailable"
				end

				local copied, clipErr = pcall(setClipboard, code)
				if not copied then
					return false, clipErr
				end
				return true
			end)

			if not ok then
				statusText = "copy failed: " .. tostring(success)
				notify(statusText)
				draw()
				return
			end

			if not success then
				if tostring(err) ~= "bad value" then
					statusText = "copy failed: " .. tostring(err)
					notify(statusText)
					draw()
				end
				return
			end

			statusText = (forceLoop and "copied loop code for " or "copied code for ") .. labelText
			notify((forceLoop and "Copied loop code for " or "Copied code for ") .. labelText)
			draw()
		end

		local copyButton = actionButton(
			f,
			"Copy Code",
			10,
			74,
			64,
			function()
				copyCode(false)
			end,
			Color3.fromRGB(54, 46, 30)
		)
		copyButton.Size = UDim2.new(0.5, -15, 0, 28)

		local copyLoopButton = actionButton(
			f,
			"Copy Code Loop",
			0,
			74,
			64,
			function()
				copyCode(true)
			end,
			Color3.fromRGB(62, 52, 34)
		)
		copyLoopButton.Position = UDim2.new(0.5, 5, 0, 74)
		copyLoopButton.Size = UDim2.new(0.5, -15, 0, 28)

		local loopButton = actionButton(
			f,
			loopLock and "Loop On" or "Loop Off",
			10,
			108,
			64,
			toggleLoop,
			loopLock and Color3.fromRGB(48, 78, 42) or Color3.fromRGB(40, 40, 40)
		)
		loopButton.Size = UDim2.new(0.5, -15, 0, 28)

		local applyButton = actionButton(f, "Apply", 0, 108, 64, apply)
		applyButton.Position = UDim2.new(0.5, 5, 0, 108)
		applyButton.Size = UDim2.new(0.5, -15, 0, 28)
		bind(box.FocusLost, function(enterPressed)
			if enterPressed then
				apply()
			end
		end)
	end

	return h
end

local function otherRow(y, labelText, value, temporary, openFn, subtext)
	local h = openFn and 72 or 62
	local f = card(listc, y, h, temporary)

	if openFn then
		rowButton(f, openFn)
	end

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -80, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = labelText,
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -70, 0, 6),
		Size = UDim2.fromOffset(60, 18),
		Font = Enum.Font.Gotham,
		Text = typeof(value),
		TextColor3 = Color3.fromRGB(170, 170, 170),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	mk("TextLabel", {
		Parent = f,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 30),
		Size = UDim2.new(1, openFn and -96 or -20, 0, 16),
		Font = Enum.Font.Code,
		Text = cut(subtext or valuepreview(value), 108),
		TextColor3 = Color3.fromRGB(175, 175, 175),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	if openFn then
		local openButton = actionButton(f, "Open", 0, 19, 64, openFn)
		openButton.Position = UDim2.new(1, -74, 0, 19)
	end

	return h
end

local function collectRows()
	local items = {}
	local q = trim(srh.Text)

	if mode == "closures" then
		if #closures == 0 then
			items[#items + 1] = {kind = "msg", a = "No closures scanned", b = "Enter a query and press Scan."}
			stat.Text = statusText ~= "" and statusText or "0 results"
			return items
		end

		local applyNameFilter = q ~= "" and q ~= lastScanQuery
		local shown = 0
		for _, closure in ipairs(closures) do
			local script = closureScript(closure)
			local scriptPath = script and getInstancePath(script) or "detached"
			if not applyNameFilter or filtered(closure.Name, q) or filtered(scriptPath, q) then
				items[#items + 1] = {kind = "closure", closure = closure}
				shown += 1
			end
		end
		if shown == 0 then
			items[#items + 1] = {kind = "msg", a = "No closures found", b = "Try a different filter or run a new scan."}
		end
		stat.Text = statusText ~= "" and statusText or (shown .. " shown / " .. #closures .. " scanned")
		return items
	end

	if mode == "upvalues" then
		if not selectedClosure then
			items[#items + 1] = {kind = "msg", a = "No closure selected", b = "Pick one from the Closures tab."}
			stat.Text = statusText ~= "" and statusText or ""
			return items
		end

		local merged = {}
		for index, upvalue in pairs(selectedClosure.Upvalues) do
			merged[index] = upvalue
		end
		if showAllUpvalues then
			ensureAllUpvalues(selectedClosure)
			for index, upvalue in pairs(selectedClosure.TemporaryUpvalues) do
				merged[index] = upvalue
			end
		end

		local keys = sortkeys(merged)
		for _, index in ipairs(keys) do
			local upvalue = merged[index]
			local value = upvalue.Value
			local labelText = "upvalue[" .. tostring(index) .. "]"
			local preview = valuepreview(value)
			local temp = upvalue.Temporary == true
			if filtered(labelText, q) or filtered(preview, q) or filtered(typeof(value), q) then
				if type(value) == "table" then
					local total, matched, extra = tableCounts(upvalue)
					items[#items + 1] = {
						kind = "table",
						label = labelText,
						value = value,
						temporary = temp,
						open = function()
							openUpvalue(upvalue)
						end,
						subtext = total .. " entries | " .. matched .. " matched" .. (extra > 0 and (" | +" .. extra .. " extra") or ""),
					}
				elseif isedit(value) then
					items[#items + 1] = {
						kind = "editable",
						label = labelText,
						value = value,
						temporary = temp,
						loopTarget = {
							kind = "upvalue",
							upvalue = upvalue,
						},
						apply = function(newValue)
							local ok, err = pcall(function()
								upvalue:Set(newValue)
							end)
							if ok then
								return true
							end
							return false, err
						end,
					}
				else
					items[#items + 1] = {
						kind = "other",
						label = labelText,
						value = value,
						temporary = temp,
					}
				end
			end
		end

		if #items == 0 then
			items[#items + 1] = {kind = "msg", a = "No upvalues visible", b = showAllUpvalues and "Try another filter." or "Toggle All to include non-matching upvalues."}
		end

		local totalCount = tablecount(selectedClosure.Upvalues) + (showAllUpvalues and tablecount(selectedClosure.TemporaryUpvalues) or 0)
		stat.Text = statusText ~= "" and statusText or (totalCount .. " upvalues")
		return items
	end

	if mode == "elements" then
		if not selectedUpvalue or type(selectedUpvalue.Value) ~= "table" then
			items[#items + 1] = {kind = "msg", a = "No table upvalue selected", b = "Pick a table from the Upvalues tab."}
			stat.Text = statusText ~= "" and statusText or ""
			return items
		end

		local merged = {}
		if selectedUpvalue.Scanned then
			for index, value in pairs(selectedUpvalue.Scanned) do
				merged[index] = {value = value}
			end
		end
		if showAllElements then
			ensureAllElements(selectedUpvalue)
			for index, value in pairs(selectedUpvalue.TemporaryElements or {}) do
				merged[index] = {value = value, temporary = true}
			end
		end

		local keys = sortkeys(merged)
		for _, index in ipairs(keys) do
			local data = merged[index]
			local value = data.value
			local labelText = "[" .. tostring(index) .. "]"
			local preview = valuepreview(value)
			if filtered(labelText, q) or filtered(preview, q) or filtered(typeof(value), q) then
				if type(value) == "table" then
					items[#items + 1] = {
						kind = "other",
						label = labelText,
						value = value,
						temporary = data.temporary,
					}
				elseif isedit(value) then
					local parentUpvalue = selectedUpvalue
					items[#items + 1] = {
						kind = "editable",
						label = labelText,
						value = value,
						temporary = data.temporary,
						loopTarget = {
							kind = "element",
							upvalue = parentUpvalue,
							key = index,
						},
						apply = function(newValue)
							return setElementValue(parentUpvalue, index, newValue)
						end,
					}
				else
					items[#items + 1] = {
						kind = "other",
						label = labelText,
						value = value,
						temporary = data.temporary,
					}
				end
			end
		end

		if #items == 0 then
			items[#items + 1] = {kind = "msg", a = "No elements visible", b = showAllElements and "Try another filter." or "Toggle All to include non-matching elements."}
		end

		local total, matched, extra = tableCounts(selectedUpvalue)
		stat.Text = statusText ~= "" and statusText or (total .. " entries | " .. matched .. " matched" .. (showAllElements and (" | +" .. extra .. " extra") or ""))
		return items
	end

	return items
end

draw = function()
	if dead then
		return
	end

	updateButtons()
	path.Text = cut(currentPath(), 120)
	clear()

	if mode == "closures" then
		srh.PlaceholderText = "Search upvalues, elements, function names..."
	elseif mode == "upvalues" then
		srh.PlaceholderText = "Filter selected upvalues..."
	else
		srh.PlaceholderText = "Filter selected table elements..."
	end

	local items = collectRows()
	local y = 0
	for _, item in ipairs(items) do
		local h = 0
		if item.kind == "msg" then
			h = showmsg(y, item.a, item.b)
		elseif item.kind == "closure" then
			h = closureRow(y, item.closure)
		elseif item.kind == "editable" then
			h = valueRow(y, item.label, item.value, item.apply, item.temporary, item.loopTarget)
		elseif item.kind == "other" then
			h = otherRow(y, item.label, item.value, item.temporary)
		elseif item.kind == "table" then
			h = otherRow(y, item.label, item.value, item.temporary, item.open, item.subtext)
		end
		y += h + 8
	end

	local total = y > 0 and (y - 8) or 0
	listc.Size = UDim2.new(1, 0, 0, total)
	body.CanvasSize = UDim2.fromOffset(0, total + 16)
end

local function goBack()
	statusText = ""
	if mode == "elements" then
		mode = "upvalues"
		selectedUpvalue = nil
	elseif mode == "upvalues" then
		mode = "closures"
		selectedClosure = nil
	end
	srh.Text = ""
	draw()
end

local function runScan(queryOverride)
	local query = trim(queryOverride or srh.Text)
	if query == "" and lastScanQuery ~= "" then
		query = lastScanQuery
	end
	if query:gsub("%s+", "") == "" then
		statusText = "query is empty"
		draw()
		return
	end
	if not tonumber(query) and #query <= 1 then
		statusText = "query is too short"
		draw()
		return
	end

	local token = sid + 1
	sid = token
	lastScanQuery = query
	lastSkippedPS = 0
	statusText = "scanning..."
	mode = "closures"
	selectedClosure = nil
	selectedUpvalue = nil
	showAllUpvalues = false
	showAllElements = false
	draw()

	task.spawn(function()
		local ok, result, skipped = pcall(scanUpvalues, query, deepSearch)
		if dead or sid ~= token then
			return
		end
		if not ok then
			closures = {}
			lastSkippedPS = 0
			statusText = "scan failed: " .. tostring(result)
			draw()
			return
		end
		closures = result
		lastSkippedPS = skipped or 0
		if lastSkippedPS > 0 and not showps then
			statusText = "scan finished | hid " .. lastSkippedPS .. " PlayerScripts"
		else
			statusText = "scan finished"
		end
		draw()
	end)
end

bind(back.Activated, goBack)
bind(scanb.Activated, runScan)
bind(pmb.Activated, function()
	showps = not showps
	statusText = ""
	runScan(lastScanQuery)
end)
bind(cls.Activated, kill)
bind(minb.Activated, function()
	minimized = not minimized
	fit()
	draw()
end)

bind(allb.Activated, function()
	if mode == "upvalues" and selectedClosure then
		showAllUpvalues = not showAllUpvalues
		if showAllUpvalues then
			ensureAllUpvalues(selectedClosure)
		else
			clearAllUpvalues(selectedClosure)
		end
		statusText = ""
		draw()
	elseif mode == "elements" and selectedUpvalue then
		showAllElements = not showAllElements
		if showAllElements then
			ensureAllElements(selectedUpvalue)
		else
			clearAllElements(selectedUpvalue)
		end
		statusText = ""
		draw()
	end
end)

bind(deepb.Activated, function()
	deepSearch = not deepSearch
	statusText = deepSearch and "deep search enabled" or "deep search disabled"
	draw()
end)

for key, button in pairs(tabs) do
	bind(button.Activated, function()
		if key == "closures" then
			mode = "closures"
			selectedUpvalue = nil
			statusText = ""
			draw()
		elseif key == "upvalues" then
			if selectedClosure then
				mode = "upvalues"
				selectedUpvalue = nil
				statusText = ""
				draw()
			else
				notify("Pick a closure first.")
			end
		elseif key == "elements" then
			if selectedUpvalue and type(selectedUpvalue.Value) == "table" then
				mode = "elements"
				statusText = ""
				draw()
			else
				notify("Pick a table upvalue first.")
			end
		end
	end)
end

bind(srh.FocusLost, function(enterPressed)
	if enterPressed then
		if mode == "closures" or selectedClosure == nil then
			runScan()
		else
			statusText = ""
			draw()
		end
	end
end)

bind(srh:GetPropertyChangedSignal("Text"), function()
	if mode ~= "closures" then
		statusText = ""
		draw()
	end
end)

dragger(frm, top)
bind(cam:GetPropertyChangedSignal("ViewportSize"), fit)
bind(run.PreSimulation, function()
	enforceLoopLocks()
end)

local refreshClock = 0
bind(run.Heartbeat, function(dt)
	refreshClock += dt
	if refreshClock < 0.35 or dead then
		return
	end
	refreshClock = 0

	local focused = uis:GetFocusedTextBox()
	if focused and focused:IsDescendantOf(gui) then
		return
	end

	if selectedClosure then
		local ok, values = pcall(getUpvaluesCompat, selectedClosure)
		if ok and type(values) == "table" then
			for index, value in pairs(values) do
				local upvalue = selectedClosure.Upvalues[index] or selectedClosure.TemporaryUpvalues[index]
				if upvalue then
					upvalue:Update(value)
				end
			end
			if selectedUpvalue and type(selectedUpvalue.Value) ~= "table" and mode == "elements" then
				mode = "upvalues"
				selectedUpvalue = nil
			end
			draw()
		end
	end
end)

notify("Enter a query and press Scan.")
draw()
