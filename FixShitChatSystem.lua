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

local cg = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
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

local function bind(sig, fn)
	local c = sig:Connect(fn)
	cons[#cons + 1] = c
	return c
end

local function wipe()
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

local function lockTxt(s)
	if s == "" then
		return false
	end
	s = s:match("^%s*(.-)$") or s
	if s == "" then
		return false
	end
	local a = s:byte(1)
	if a ~= 240 and s:sub(1, 1) ~= "🔒" then
		return false
	end
	return s:match("^🔒%s*:") ~= nil
end

local function hideRow(body)
	if not live or not body or done[body] then
		return
	end
	if not body:IsA("TextLabel") or body.Name ~= "BodyText" then
		return
	end
	if not body:IsDescendantOf(ec) then
		return
	end
	if not lockTxt(txtOf(body)) then
		return
	end

	local row = body
	for _ = 1, 4 do
		local p = row.Parent
		if not p or p == ec then
			break
		end
		if p.Name == "TextMessage" then
			row = p.Parent or body
			break
		end
		row = p
	end

	if row and row:IsA("GuiObject") and row.Parent then
		row.Visible = false
		done[row] = true
		done[body] = true
	else
		body.Visible = false
		done[body] = true
	end
end

local function scan(root)
	for _, inst in ipairs(root:GetDescendants()) do
		if inst.Name == "BodyText" and inst:IsA("TextLabel") then
			hideRow(inst)
		end
	end
end

scan(ec)

bind(ec.DescendantAdded, function(inst)
	if not live then
		return
	end
	if inst.Name ~= "BodyText" or not inst:IsA("TextLabel") then
		return
	end
	task.defer(hideRow, inst)
end)

bind(ec.AncestryChanged, function(_, par)
	if par == nil then
		wipe()
	end
end)

bind(game:GetService("Players").LocalPlayer.CharacterRemoving, function()
	table.clear(done)
end)