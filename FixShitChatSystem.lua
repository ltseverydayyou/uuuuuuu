local _env = (getgenv and getgenv()) or _G or {}
local _shared = rawget(_G, "shared")

local function AlreadyLoaded()
	if _env and (_env.ltseverydayyou_chatFix or _env.chatFixLoaded) then
		return true
	end
	if _shared and (_shared.ltseverydayyou_chatFix or _shared.chatFixLoaded) then
		return true
	end
	return false
end

if AlreadyLoaded() then
	return
end

pcall(function()
	if _env then
		_env.ltseverydayyou_chatFix = true
		_env.chatFixLoaded = true
	end
	if _shared then
		_shared.ltseverydayyou_chatFix = true
		_shared.chatFixLoaded = true
	end
end)

local function svc(n)
	local ok, s = pcall(game.GetService, game, n)
	if not ok or not s then
		return nil
	end
	if cloneref and type(cloneref) == "function" then
		local ok2, c = pcall(cloneref, s)
		if ok2 and c then
			return c
		end
	end
	return s
end

local function wchild(p, n, t)
	if not p then return nil end
	local st = os.clock()
	local c = p:FindFirstChild(n)
	while not c and (not t or os.clock() - st < t) do
		if not p.Parent and not p:IsDescendantOf(game) then
			return nil
		end
		task.wait(0.03)
		c = p:FindFirstChild(n)
	end
	return c
end

local cg = svc("CoreGui")
if not cg then return end

local ec = wchild(cg, "ExperienceChat", 30)
if not ec then return end

local function isLockRow(lbl)
	if not lbl or not lbl:IsA("TextLabel") then return false end
	if lbl.Name ~= "BodyText" then return false end

	local txt = ""
	pcall(function()
		txt = lbl.ContentText
	end)
	if txt == "" then
		txt = lbl.Text or ""
	end
	if txt == "" then return false end

	txt = txt:gsub("^%s+", "")
	return txt:match("^🔒%s*:") ~= nil
end

local hooked = setmetatable({}, { __mode = "k" })
local watched = setmetatable({}, { __mode = "k" })

local function keepHidden(inst)
	if not inst or watched[inst] then return end
	watched[inst] = true

	local conn
	conn = inst:GetPropertyChangedSignal("Visible"):Connect(function()
		if not inst or not inst.Parent then
			if conn then
				conn:Disconnect()
				conn = nil
			end
			watched[inst] = nil
			return
		end
		if inst.Visible then
			inst.Visible = false
		end
	end)

	if inst.Visible then
		inst.Visible = false
	end
end

local function hookCont(cont)
	if not cont or hooked[cont] then return end
	hooked[cont] = true

	local function getRow(body)
		local p = body
		while p and p ~= cont do
			local pr = p.Parent
			if pr == cont then
				return p
			end
			p = pr
		end
		return nil
	end

	local function handleBody(body)
		if not isLockRow(body) then return end
		if not body.Parent then return end

		local row = getRow(body)
		if row and row.Parent then
			row.Visible = false
			keepHidden(row)
		else
			body.Visible = false
			keepHidden(body)
		end
	end

	for _, row in ipairs(cont:GetChildren()) do
		local tm = row:FindFirstChild("TextMessage")
		if tm then
			local body = tm:FindFirstChild("BodyText")
			if body then
				handleBody(body)
			end
		end
	end

	local dConn
	dConn = cont.DescendantAdded:Connect(function(inst)
		if not cont.Parent then
			if dConn then
				dConn:Disconnect()
				dConn = nil
			end
			hooked[cont] = nil
			return
		end
		if inst:IsA("TextLabel") and inst.Name == "BodyText" then
			handleBody(inst)
		end
	end)
end

for _, inst in ipairs(ec:GetDescendants()) do
	if inst.Name == "RCTScrollContentView" then
		hookCont(inst)
	end
end

local ecConn
ecConn = ec.DescendantAdded:Connect(function(inst)
	if not ec.Parent then
		if ecConn then
			ecConn:Disconnect()
			ecConn = nil
		end
		return
	end
	if inst.Name == "RCTScrollContentView" then
		hookCont(inst)
	end
end)
