local env = (getgenv and getgenv()) or _G or {}
local sh = rawget(_G, "shared")

local function loaded()
	if env and (env.ltseverydayyou_chatFix or env.chatFixLoaded) then
		return true
	end
	if sh and (sh.ltseverydayyou_chatFix or sh.chatFixLoaded) then
		return true
	end
	return false
end

if loaded() then
	return
end

pcall(function()
	if env then
		env.ltseverydayyou_chatFix = true
		env.chatFixLoaded = true
	end
	if sh then
		sh.ltseverydayyou_chatFix = true
		sh.chatFixLoaded = true
	end
end)

local function getCg()
	local ok, s = pcall(function()
		return game:GetService("CoreGui")
	end)
	if not ok or not s then
		return nil
	end
	if cloneref and type(cloneref) == "function" then
		local ok2, r = pcall(cloneref, s)
		if ok2 and r then
			return r
		end
	end
	return s
end

local cg = getCg()
if not cg then
	return
end

local ec = cg:FindFirstChild("ExperienceChat") or cg:WaitForChild("ExperienceChat", 30)
if not ec then
	return
end

local live = true
local cons = {}
local done = setmetatable({}, { __mode = "k" })
local pend = setmetatable({}, { __mode = "k" })

local function bind(sig, fn)
	local c = sig:Connect(fn)
	cons[#cons + 1] = c
	return c
end

local function stop()
	if not live then
		return
	end
	live = false
	for i = #cons, 1, -1 do
		local c = cons[i]
		if c then
			c:Disconnect()
		end
		cons[i] = nil
	end
	table.clear(done)
	table.clear(pend)
end

local function txtOf(lbl)
	local ok, v = pcall(function()
		return lbl.ContentText
	end)
	if ok and type(v) == "string" and v ~= "" then
		return v
	end
	v = lbl.Text
	if type(v) == "string" then
		return v
	end
	return ""
end

local function isLockTxt(s)
	return s:match("^%s*🔒%s*:") ~= nil
end

local function getRow(body)
	local p = body
	for _ = 1, 8 do
		if not p or p == ec then
			break
		end

		local pr = p.Parent
		if not pr then
			break
		end

		if pr.Name == "RCTScrollContentView" and p:IsA("GuiObject") then
			return p
		end

		if pr.Name == "TextMessage" then
			local row = pr.Parent
			if row and row:IsA("GuiObject") then
				return row
			end
		end

		p = pr
	end
	return body
end

local function hide(body)
	if not live or not body or not body.Parent then
		return true
	end
	if not body:IsA("TextLabel") or body.Name ~= "BodyText" then
		return true
	end
	if done[body] then
		return true
	end
	if not body:IsDescendantOf(ec) then
		return true
	end

	local s = txtOf(body)
	if s == "" or not isLockTxt(s) then
		return false
	end

	local row = getRow(body)
	if row and row:IsA("GuiObject") and row.Parent then
		row.Visible = false
		done[row] = true
	else
		body.Visible = false
	end

	done[body] = true
	return true
end

local function sched(body)
	if not live or not body or pend[body] or done[body] then
		return
	end
	if not body:IsA("TextLabel") or body.Name ~= "BodyText" then
		return
	end

	pend[body] = true

	task.spawn(function()
		local waits = {0, 0.05, 0.15, 0.35, 0.75}
		for i = 1, #waits do
			local dt = waits[i]
			if dt > 0 then
				task.wait(dt)
			end
			if not live or not body or not body.Parent or done[body] then
				break
			end
			if hide(body) then
				break
			end
		end
		pend[body] = nil
	end)
end

for _, inst in ipairs(ec:GetDescendants()) do
	if inst.Name == "BodyText" and inst:IsA("TextLabel") then
		sched(inst)
	end
end

bind(ec.DescendantAdded, function(inst)
	if not live then
		return
	end
	if inst.Name == "BodyText" and inst:IsA("TextLabel") then
		sched(inst)
	end
end)

bind(ec.AncestryChanged, function(_, par)
	if par == nil then
		stop()
	end
end)

task.spawn(function()
	while live do
		task.wait(300)
		if not live then
			break
		end
		table.clear(done)
	end
end)