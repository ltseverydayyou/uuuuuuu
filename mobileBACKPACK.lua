if BACKPACKmobile then return end

pcall(function() getgenv().BACKPACKmobile = true end)

if not game:IsLoaded() then
	game.Loaded:Wait()
end

function SafeGetService(name)
	local service = game:GetService(name)
	return if cloneref then cloneref(service) else service
end

if not SafeGetService("UserInputService").TouchEnabled then
	return
end

function guiCHECKINGAHHHHH()
	return (gethui and gethui()) or SafeGetService("CoreGui"):FindFirstChild("RobloxGui") or SafeGetService("CoreGui") or SafeGetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
end

local p = SafeGetService("Players").LocalPlayer
local ts = SafeGetService("TweenService")

local swapping = false
local selectedSwapTool = nil
local selectedTool = nil
local toolButtons = {}
local collapsed = false

local gui = Instance.new("ScreenGui")
gui.Name = "InvUI"
gui.Parent = guiCHECKINGAHHHHH()
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.DisplayOrder = 999999999
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

local frameWrap = Instance.new("Frame")
frameWrap.AnchorPoint = Vector2.new(0.5, 1)
frameWrap.Position = UDim2.new(0.5, 0, 1, -10)
frameWrap.Size = UDim2.new(0, 650, 0, 60)
frameWrap.BackgroundTransparency = 1
frameWrap.Parent = gui

local qb = Instance.new("Frame")
qb.Name = "QB"
qb.Size = UDim2.new(0, 550, 0, 60)
qb.Position = UDim2.new(0.5, -275, 0, 0)
qb.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
qb.BackgroundTransparency = 0.4
qb.ClipsDescendants = true
qb.Parent = frameWrap
Instance.new("UICorner", qb).CornerRadius = UDim.new(0, 12)

local ql = Instance.new("UIGridLayout")
ql.FillDirection = Enum.FillDirection.Horizontal
ql.CellSize = UDim2.new(0, 50, 0, 50)
ql.CellPadding = UDim2.new(0, 5, 0, 5)
ql.SortOrder = Enum.SortOrder.LayoutOrder
ql.Parent = qb

local ex = Instance.new("TextButton")
ex.Name = "Ex"
ex.Size = UDim2.new(0, 40, 0, 40)
ex.Position = UDim2.new(0, 0, 0.5, -15)
ex.Text = "Open"
ex.Font = Enum.Font.GothamBold
ex.TextScaled = true
ex.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
ex.BackgroundTransparency = 0.3
ex.TextColor3 = Color3.fromRGB(255, 255, 255)
ex.Parent = frameWrap
Instance.new("UICorner", ex).CornerRadius = UDim.new(0, 10)

local swapBtn = Instance.new("TextButton")
swapBtn.Name = "SwapToggle"
swapBtn.Size = UDim2.new(0, 40, 0, 40)
swapBtn.Position = UDim2.new(1, -45, 0.5, -20)
swapBtn.Text = "Swap"
swapBtn.Font = Enum.Font.GothamBold
swapBtn.TextScaled = true
swapBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
swapBtn.BackgroundTransparency = 0.2
swapBtn.TextColor3 = Color3.new(1, 1, 1)
swapBtn.Parent = frameWrap

local swapCorner = Instance.new("UICorner")
swapCorner.CornerRadius = UDim.new(0, 10)
swapCorner.Parent = swapBtn

local dropAllBtn = Instance.new("TextButton")
dropAllBtn.Name = "DropAll"
dropAllBtn.Size = UDim2.new(0, 40, 0, 40)
dropAllBtn.Position = UDim2.new(1, -95, 0.5, -20)
dropAllBtn.Text = "Drop Tools"
dropAllBtn.Font = Enum.Font.GothamBold
dropAllBtn.TextScaled = true
dropAllBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
dropAllBtn.BackgroundTransparency = 0.2
dropAllBtn.TextColor3 = Color3.new(1, 1, 1)
dropAllBtn.Parent = frameWrap

local dropAllCorner = Instance.new("UICorner")
dropAllCorner.CornerRadius = UDim.new(0, 10)
dropAllCorner.Parent = dropAllBtn

local collapseBtn = Instance.new("TextButton")
collapseBtn.Name = "Collapse"
collapseBtn.Size = UDim2.new(0, 40, 0, 40)
collapseBtn.Position = UDim2.new(1, -145, 0.5, -20)
collapseBtn.Text = "-"
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.TextScaled = true
collapseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
collapseBtn.BackgroundTransparency = 0.2
collapseBtn.TextColor3 = Color3.new(1, 1, 1)
collapseBtn.Parent = frameWrap

local collapseCorner = Instance.new("UICorner")
collapseCorner.CornerRadius = UDim.new(0, 10)
collapseCorner.Parent = collapseBtn

local full = Instance.new("ScrollingFrame")
full.Name = "Full"
full.Size = UDim2.new(0, 550, 0, 0)
full.AnchorPoint = Vector2.new(0.5, 1)
full.Position = UDim2.new(0.5, 0, 1, -70)
full.CanvasSize = UDim2.new(0, 0, 0, 0)
full.ScrollBarThickness = 4
full.ScrollingDirection = Enum.ScrollingDirection.Y
full.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
full.BackgroundTransparency = 0.4
full.BorderSizePixel = 0
full.Visible = true
full.ClipsDescendants = true
full.Parent = gui
Instance.new("UICorner", full).CornerRadius = UDim.new(0, 12)

local fl = Instance.new("UIGridLayout")
fl.CellSize = UDim2.new(0, 50, 0, 50)
fl.CellPadding = UDim2.new(0, 5, 0, 5)
fl.Parent = full

local tOrder = {}

local function makeBtn(t)
	local hasImg = t.TextureId and t.TextureId ~= ""
	local b = hasImg and Instance.new("ImageButton") or Instance.new("TextButton")
	if not hasImg then
		b.Text = t.Name
		b.TextScaled = true
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		b.Image = t.TextureId
	end
	b.Name = t.Name
	b.Active = true
	b.Size = UDim2.new(0, 50, 0, 50)
	b.BackgroundColor3 = (swapping and selectedSwapTool == t)
		and Color3.fromRGB(0, 180, 50)
		or (selectedTool == t and Color3.fromRGB(30, 90, 255))
		or Color3.fromRGB(40, 40, 40)
	b.AutoButtonColor = false
	Instance.new("UICorner", b).CornerRadius = UDim.new(0.2, 0)

	toolButtons[b] = t

	b.MouseButton1Click:Connect(function()
		if swapping then
			if not selectedSwapTool then
				selectedSwapTool = t
				refresh()
			elseif selectedSwapTool == t then
				selectedSwapTool = nil
				refresh()
			else
				local i1, i2
				for i, v in ipairs(tOrder) do
					if v == selectedSwapTool then i1 = i end
					if v == t then i2 = i end
				end
				if i1 and i2 then
					tOrder[i1], tOrder[i2] = tOrder[i2], tOrder[i1]
				end
				selectedSwapTool = nil
				refresh()
			end
		else
			local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				if selectedTool == t then
					hum:UnequipTools()
					selectedTool = nil
				else
					hum:EquipTool(t)
					selectedTool = t
				end
				refresh()
			end
		end
	end)

	if t.CanBeDropped then
		local dropBtn = Instance.new("TextButton")
		dropBtn.Size = UDim2.new(0, 16, 0, 16)
		dropBtn.Position = UDim2.new(1, -4, 1, -4)
		dropBtn.AnchorPoint = Vector2.new(1, 1)
		dropBtn.Text = "D"
		dropBtn.TextScaled = true
		dropBtn.TextColor3 = Color3.new(1, 1, 1)
		dropBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
		dropBtn.BackgroundTransparency = 0.1
		dropBtn.BorderSizePixel = 0
		dropBtn.ZIndex = 2
		dropBtn.Parent = b

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = dropBtn

		dropBtn.MouseButton1Click:Connect(function()
			local char = p.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and char then
				t.Parent = char
				task.wait(0.05)
				t.Parent = SafeGetService("Workspace")
			end
			refresh()
		end)
	end

	return b
end

function updateCollapseState()
	local isCollapsed = collapsed

	local targetSize = isCollapsed and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 650, 0, 60)
	ts:Create(frameWrap, TweenInfo.new(0.25), { Size = targetSize }):Play()

	for _, child in ipairs(frameWrap:GetChildren()) do
		if child:IsA("GuiButton") and child ~= collapseBtn then
			child.Visible = not isCollapsed
		end
	end

	collapseBtn.Position = isCollapsed
		and UDim2.new(0.5, -20, 1, -20)
		or UDim2.new(1, -145, 0.5, -20)

	collapseBtn.Text = isCollapsed and "+" or "-"
end

function callCLOSE()
	collapsed = not collapsed
	updateCollapseState()

	local tween = ts:Create(full, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 550, 0, 0)
	})
	tween:Play()
	ex.Text = "Open"
	open = false
end

function refresh()
	local bp = p:FindFirstChild("Backpack")
	if not bp then return end

	for _, c in ipairs(qb:GetChildren()) do
		if c:IsA("GuiButton") then c:Destroy() end
	end
	for _, c in ipairs(full:GetChildren()) do
		if c:IsA("GuiButton") then c:Destroy() end
	end
	table.clear(toolButtons)

	local toolsMap = {}
	for _, container in {bp, p.Character} do
		if container then
			for _, t in ipairs(container:GetChildren()) do
				if t:IsA("Tool") then
					toolsMap[t] = true
				end
			end
		end
	end

	local tools = {}
	for tool in pairs(toolsMap) do
		table.insert(tools, tool)
	end

	for _, t in ipairs(tools) do
		if not table.find(tOrder, t) then
			table.insert(tOrder, t)
		end
	end

	for i = #tOrder, 1, -1 do
		if not toolsMap[tOrder[i]] then
			table.remove(tOrder, i)
		end
	end

	selectedTool = p.Character and p.Character:FindFirstChildOfClass("Tool")

	for i, t in ipairs(tOrder) do
		if toolsMap[t] then
			local btn = makeBtn(t)
			if i <= 8 then btn.Parent = qb else btn.Parent = full end
		end
	end

	local row = math.ceil((#tOrder - 8) / 10)
	full.CanvasSize = UDim2.new(0, 0, 0, (55 * row))
end

swapBtn.MouseButton1Click:Connect(function()
	local bp = p:FindFirstChild("Backpack")
	local count = 0
	for _, item in ipairs(bp:GetChildren()) do
		if item:IsA("Tool") then count += 1 end
	end
	if count < 2 then return end

	swapping = not swapping
	selectedSwapTool = nil
	swapBtn.Text = swapping and "X" or "Swap"
	refresh()
end)

dropAllBtn.MouseButton1Click:Connect(function()
	local tools = {}

	for _, container in {p.Backpack, p.Character} do
		if container then
			for _, t in ipairs(container:GetChildren()) do
				if t:IsA("Tool") and t.CanBeDropped then
					table.insert(tools, t)
				end
			end
		end
	end

	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	local char = p.Character

	for _, tool in ipairs(tools) do
		if tool.Parent ~= char then
			tool.Parent = char
			tool.Parent = SafeGetService("Workspace")
		elseif tool.Parent == char then
			tool.Parent = SafeGetService("Workspace")
		end
	end

	if hum then hum:UnequipTools() end
	refresh()
end)

ex.MouseButton1Click:Connect(function()
	open = not open
	local h = open and 250 or 0
	local tween = ts:Create(full, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 550, 0, h)
	})
	tween:Play()
	ex.Text = open and "Close" or "Open"
end)

collapseBtn.MouseButton1Click:Connect(callCLOSE)

local toolConnections = {}

local function disconnectToolTracking()
	for _, conn in ipairs(toolConnections) do
		if conn and conn.Disconnect then conn:Disconnect() end
	end
	table.clear(toolConnections)
end

local function setupToolTracking()
	disconnectToolTracking()
	local bp = p:FindFirstChild("Backpack")
	if bp then
		table.insert(toolConnections, bp.ChildAdded:Connect(refresh))
		table.insert(toolConnections, bp.ChildRemoved:Connect(refresh))
	end
	if p.Character then
		table.insert(toolConnections, p.Character.ChildAdded:Connect(refresh))
		table.insert(toolConnections, p.Character.ChildRemoved:Connect(refresh))
	end
end

p.CharacterAdded:Connect(function()
	task.wait(0.1)
	refresh()
	setupToolTracking()
end)

setupToolTracking()
refresh()

SafeGetService("RunService").RenderStepped:Connect(function()
	SafeGetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)