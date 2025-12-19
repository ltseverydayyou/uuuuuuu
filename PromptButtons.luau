if not game:IsLoaded() then game.Loaded:Wait() end

local plrs = game:GetService("Players")
local pps = game:GetService("ProximityPromptService")
local uis = game:GetService("UserInputService")
local ts = game:GetService("TweenService")

local lp = plrs.LocalPlayer or plrs.PlayerAdded:Wait()

local function getPar()
	local ok, g
	if typeof(gethui) == "function" then
		ok, g = pcall(gethui)
		if ok and typeof(g) == "Instance" then
			return g
		end
	end
	local cg = game:FindFirstChildOfClass("CoreGui")
	if cg then
		return cg
	end
	return lp:WaitForChild("PlayerGui")
end

local cfg = {
	w = 260,
	h = 52,
	gap = 8,
	mode = getgenv().promptModeBtn or "auto",  -- "auto", "instant", "hold"
	defHold = 0.4
}

local gui = Instance.new("ScreenGui")
gui.Name = "NA_PromptOverlay"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = getPar()

local column = Instance.new("Frame")
column.Name = "PromptColumn"
column.AnchorPoint = Vector2.new(0.5, 1)
column.Position = UDim2.new(0.5, 0, 1, -70)
column.Size = UDim2.new(0, cfg.w, 1, 0)
column.BackgroundTransparency = 1
column.Parent = gui

local list = Instance.new("UIListLayout")
list.FillDirection = Enum.FillDirection.Vertical
list.HorizontalAlignment = Enum.HorizontalAlignment.Center
list.VerticalAlignment = Enum.VerticalAlignment.Bottom
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Padding = UDim.new(0, cfg.gap)
list.Parent = column

local map = {}
local order = 0

local function tw(o, t, props)
	ts:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function keyTxt(pr)
	local k = pr.KeyboardKeyCode
	if not k or k == Enum.KeyCode.Unknown then
		if uis.TouchEnabled and not uis.KeyboardEnabled then
			return "Tap"
		end
		return "Key"
	end
	local n = k.Name
	n = n:gsub("^Key", "")
	return n
end

local function titleTxt(pr)
	local o = pr.ObjectText or ""
	if o ~= "" then
		return o
	end
	local a = pr.ActionText or ""
	if a ~= "" then
		return a
	end
	return "Interact"
end

local function descTxt(pr)
	local a = pr.ActionText or ""
	if a ~= "" then
		return a
	end
	return ""
end

local function hDur(pr)
	local d = pr.HoldDuration or 0
	if cfg.mode == "instant" then
		return 0
	elseif cfg.mode == "hold" then
		if d > 0 then
			return d
		end
		return cfg.defHold
	else
		return d
	end
end

local function firePrompt(pr, hd)
	if not pr or not pr:IsDescendantOf(game) then
		return
	end
	if typeof(fireproximityprompt) == "function" then
		if hd > 0 then
			task.delay(hd, function()
				if pr and pr:IsDescendantOf(game) then
					pcall(function()
						fireproximityprompt(pr)
					end)
				end
			end)
		else
			pcall(function()
				fireproximityprompt(pr)
			end)
		end
	else
		if hd > 0 then
			pcall(function()
				pps:InputHoldBegin(pr)
				task.delay(hd, function()
					if pr and pr:IsDescendantOf(game) then
						pcall(function()
							pps:InputHoldEnd(pr)
						end)
					end
				end)
			end)
		else
			pcall(function()
				pps:InputHoldBegin(pr)
				task.delay(0.05, function()
					if pr and pr:IsDescendantOf(game) then
						pcall(function()
							pps:InputHoldEnd(pr)
						end)
					end
				end)
			end)
		end
	end
end

local function removePrompt(pr)
	local d = map[pr]
	if not d then
		return
	end
	map[pr] = nil
	if d.con then
		for _, c in ipairs(d.con) do
			pcall(function()
				c:Disconnect()
			end)
		end
	end
	if d.wrap and d.wrap.Parent then
		d.wrap:Destroy()
	end
end

local function addPrompt(pr)
	if not pr or map[pr] then
		return
	end

	-- New prompts get LOWER LayoutOrder so they appear ABOVE old ones
	order -= 1

	local wrap = Instance.new("Frame")
	wrap.Name = "PromptWrap"
	wrap.Size = UDim2.new(1, 0, 0, cfg.h)
	wrap.BackgroundTransparency = 1
	wrap.LayoutOrder = order
	wrap.Parent = column

	local btn = Instance.new("TextButton")
	btn.Name = "PromptBtn"
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.Position = UDim2.new(0.5, 0, 0.5, 0)
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
	btn.BackgroundTransparency = 0.12
	btn.Text = ""
	btn.Parent = wrap

	local cor = Instance.new("UICorner")
	cor.CornerRadius = UDim.new(0, 18)
	cor.Parent = btn

	local st = Instance.new("UIStroke")
	st.Thickness = 1.4
	st.Transparency = 0.35
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Parent = btn

	local keyL = Instance.new("TextLabel")
	keyL.Name = "Key"
	keyL.BackgroundTransparency = 1
	keyL.Position = UDim2.new(0, 14, 0, 6)
	keyL.Size = UDim2.new(0, 60, 0, 20)
	keyL.Font = Enum.Font.GothamBold
	keyL.TextSize = 18
	keyL.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyL.TextXAlignment = Enum.TextXAlignment.Left
	keyL.TextYAlignment = Enum.TextYAlignment.Center
	keyL.Parent = btn

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 80, 0, 6)
	title.Size = UDim2.new(1, -94, 0, 20)
	title.Font = Enum.Font.GothamSemibold
	title.TextSize = 18
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = btn

	local desc = Instance.new("TextLabel")
	desc.Name = "Desc"
	desc.BackgroundTransparency = 1
	desc.Position = UDim2.new(0, 14, 0, 26)
	desc.Size = UDim2.new(1, -28, 0, 20)
	desc.Font = Enum.Font.Gotham
	desc.TextSize = 14
	desc.TextColor3 = Color3.fromRGB(210, 210, 210)
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.TextYAlignment = Enum.TextYAlignment.Top
	desc.TextWrapped = true
	desc.Parent = btn

	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.Position = UDim2.new(0, 14, 1, -4)
	barBg.Size = UDim2.new(1, -28, 0, 3)
	barBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	barBg.BackgroundTransparency = 0.88
	barBg.Parent = btn

	local barCor = Instance.new("UICorner")
	barCor.CornerRadius = UDim.new(1, 0)
	barCor.Parent = barBg

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(0, 0, 1, 0)
	bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	bar.BackgroundTransparency = 0.2
	bar.Parent = barBg

	local barCor2 = Instance.new("UICorner")
	barCor2.CornerRadius = UDim.new(1, 0)
	barCor2.Parent = bar

	local busy = false
	local con = {}

	local function refresh()
		keyL.Text = keyTxt(pr)
		title.Text = titleTxt(pr)
		desc.Text = descTxt(pr)
		local hd = hDur(pr)
		barBg.Visible = hd > 0
		if hd <= 0 then
			bar.Size = UDim2.new(0, 0, 1, 0)
		end
	end

	local function activated()
		if busy then
			return
		end
		if not pr or not pr:IsDescendantOf(game) then
			removePrompt(pr)
			return
		end

		busy = true
		tw(btn, 0.08, {Size = UDim2.new(1, -10, 1, -4)})

		local hd = hDur(pr)
		if hd > 0 then
			bar.Size = UDim2.new(0, 0, 1, 0)
			barBg.Visible = true
			tw(bar, hd, {Size = UDim2.new(1, 0, 1, 0)})
		else
			barBg.Visible = false
			bar.Size = UDim2.new(1, 0, 1, 0)
			tw(bar, 0.12, {Size = UDim2.new(0, 0, 1, 0)})
		end

		firePrompt(pr, hd)

		task.delay(math.max(hd, 0.15), function()
			if btn.Parent then
				tw(btn, 0.12, {Size = UDim2.new(1, 0, 1, 0)})
			end
			busy = false
		end)
	end

	table.insert(con, btn.Activated:Connect(activated))
	table.insert(con, pr:GetPropertyChangedSignal("ActionText"):Connect(refresh))
	table.insert(con, pr:GetPropertyChangedSignal("ObjectText"):Connect(refresh))
	table.insert(con, pr:GetPropertyChangedSignal("KeyboardKeyCode"):Connect(refresh))
	table.insert(con, pr:GetPropertyChangedSignal("HoldDuration"):Connect(refresh))
	table.insert(con, pr.AncestryChanged:Connect(function()
		if not pr:IsDescendantOf(game) then
			removePrompt(pr)
		end
	end))

	map[pr] = {
		pr = pr,
		wrap = wrap,
		btn = btn,
		con = con,
		barBg = barBg,
		bar = bar
	}

	refresh()

	if pr.Style ~= Enum.ProximityPromptStyle.Custom then
		pcall(function()
			pr.Style = Enum.ProximityPromptStyle.Custom
		end)
	end
end

pps.PromptShown:Connect(function(pr)
	addPrompt(pr)
end)

pps.PromptHidden:Connect(function(pr)
	removePrompt(pr)
end)