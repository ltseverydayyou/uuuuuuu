pcall(function()
	local function has(inst, prop)
		if not inst then return false end
		local ok = pcall(function() return inst[prop] end)
		return ok
	end
	local function set(inst, prop, value)
		if inst and has(inst, prop) then pcall(function() inst[prop] = value end) end
	end
	local function ref(s)
		local gs = game.GetService
		local cr = cloneref or function(r) return r end
		return cr(gs(game, s))
	end

	local TCS = ref("TextChatService")
	local StarterGui = ref("StarterGui")

	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true) end)
	if has(TCS, "ChatVersion") then TCS.ChatVersion = Enum.ChatVersion.TextChatService end
	if has(TCS, "CreateDefaultTextChannels") then TCS.CreateDefaultTextChannels = true end

	local Channels = TCS:FindFirstChild("TextChannels") or TCS:WaitForChild("TextChannels", 10)
	local RBXGeneral = Channels and Channels:FindFirstChild("RBXGeneral") or nil

	local Window = TCS:FindFirstChildOfClass("ChatWindowConfiguration")
	local InputBar = TCS:FindFirstChildOfClass("ChatInputBarConfiguration")
	local Bubbles = TCS:FindFirstChildOfClass("BubbleChatConfiguration")
	local Tabs = TCS:FindFirstChildOfClass("ChannelTabsConfiguration")

	if Window then
		set(Window, "Enabled", true)
		if has(Window, "FontFace") then pcall(function() Window.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json") end) end
		set(Window, "TextSize", 16)
		set(Window, "TextColor3", Color3.fromRGB(235,235,235))
		set(Window, "TextStrokeColor3", Color3.new(0,0,0))
		set(Window, "TextStrokeTransparency", 0.5)
		set(Window, "BackgroundColor3", Color3.fromRGB(25,27,29))
		set(Window, "BackgroundTransparency", 0.2)
		set(Window, "HorizontalAlignment", Enum.HorizontalAlignment.Left)
		set(Window, "VerticalAlignment", Enum.VerticalAlignment.Top)
		set(Window, "WidthScale", 1)
		set(Window, "HeightScale", 1)
	end

	if Tabs then
		set(Tabs, "Enabled", true)
		if has(Tabs, "FontFace") then pcall(function() Tabs.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json") end) end
		set(Tabs, "TextSize", 18)
		set(Tabs, "BackgroundTransparency", 0)
		set(Tabs, "TextColor3", Color3.new(1,1,1))
		set(Tabs, "SelectedTabTextColor3", Color3.fromRGB(170,255,170))
		set(Tabs, "UnselectedTabTextColor3", Color3.fromRGB(200,200,200))
	end

	if InputBar then
		set(InputBar, "Enabled", true)
		if RBXGeneral and has(InputBar, "TargetTextChannel") then set(InputBar, "TargetTextChannel", RBXGeneral) end
		set(InputBar, "AutocompleteEnabled", true)
		if has(InputBar, "FontFace") then pcall(function() InputBar.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json") end) end
		set(InputBar, "KeyboardKeyCode", Enum.KeyCode.Slash)
		set(InputBar, "TextSize", 16)
		set(InputBar, "TextColor3", Color3.new(1,1,1))
		set(InputBar, "TextStrokeTransparency", 0.5)
		set(InputBar, "BackgroundTransparency", 0.2)
	end

	if Bubbles then
		set(Bubbles, "Enabled", true)
		if has(Bubbles, "MaxDistance") then set(Bubbles, "MaxDistance", math.max(Bubbles.MaxDistance or 0, 100)) end
		if has(Bubbles, "MinimizeDistance") then set(Bubbles, "MinimizeDistance", (Bubbles.MinimizeDistance == nil and 20) or Bubbles.MinimizeDistance) end
		if has(Bubbles, "TextSize") then set(Bubbles, "TextSize", math.max(Bubbles.TextSize or 0, 14)) end
		if has(Bubbles, "BubblesSpacing") then set(Bubbles, "BubblesSpacing", (Bubbles.BubblesSpacing == nil and 4) or Bubbles.BubblesSpacing) end
		set(Bubbles, "BackgroundTransparency", 0.1)
		set(Bubbles, "TailVisible", true)
	end

	local function reconfigure()
		task.wait(0.1)
		Channels = TCS:FindFirstChild("TextChannels") or Channels
		RBXGeneral = Channels and Channels:FindFirstChild("RBXGeneral") or RBXGeneral
		Window = TCS:FindFirstChildOfClass("ChatWindowConfiguration") or Window
		InputBar = TCS:FindFirstChildOfClass("ChatInputBarConfiguration") or InputBar
		Bubbles = TCS:FindFirstChildOfClass("BubbleChatConfiguration") or Bubbles
		Tabs = TCS:FindFirstChildOfClass("ChannelTabsConfiguration") or Tabs
		if InputBar and RBXGeneral and has(InputBar, "TargetTextChannel") then set(InputBar, "TargetTextChannel", RBXGeneral) end
	end

	if TCS then TCS.DescendantAdded:Connect(reconfigure) end
end)