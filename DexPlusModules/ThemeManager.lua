--[[
	Theme Manager Module
]]
local Main,Lib,Apps,Settings

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings
end

local function initAfterMain() end

local function main()
	local ThemeManager = {}
	local window

	ThemeManager.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Themes")
		window:Resize(360,360)
		ThemeManager.Window = window
		
		local content = window.GuiElems.Content
		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0,8)
		padding.PaddingLeft = UDim.new(0,8)
		padding.PaddingRight = UDim.new(0,8)
		padding.Parent = content

		local function makeButton(text, posY, onClick)
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1,-16,0,28)
			btn.Position = UDim2.new(0,8,0,posY)
			btn.Text = text
			btn.TextColor3 = Color3.new(1,1,1)
			btn.BackgroundTransparency = 0.2
			btn.BackgroundColor3 = Settings.Theme.Button
			Lib.ButtonAnim(btn,{PressColor = Settings.Theme.ButtonPress})
			btn.Parent = content
			btn.MouseButton1Click:Connect(onClick)
			return btn
		end

		makeButton("Reload Theme File",10,function()
			Main.LoadThemeSettings()
			Lib.RefreshTheme()
		end)

		makeButton("Save Current Theme",44,function()
			Main.SaveThemeSettings()
		end)

		makeButton("Reset to Default",78,function()
			Main.ResetSettings()
			Main.SaveThemeSettings()
			Lib.RefreshTheme()
		end)

		-- Color editor
		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "ColorList"
		scroll.Size = UDim2.new(1,-16,1,-168)
		scroll.Position = UDim2.new(0,8,0,120)
		scroll.BackgroundTransparency = 0.1
		scroll.BackgroundColor3 = Settings.Theme.Main1
		scroll.CanvasSize = UDim2.new(0,0,0,0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ScrollBarThickness = 6
		scroll.Parent = content

		local list = Instance.new("UIListLayout", scroll)
		list.Padding = UDim.new(0,6)

		local themeKeys = {
			"Main1","Main2","Outline1","Outline2","TextBox","Menu",
			"ListSelection","Button","ButtonHover","ButtonPress","Highlight",
			"Text","PlaceholderText","Important"
		}

		local rows = {}
		local activeKey

		local function colorToText(c)
			return string.format("%d,%d,%d", math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
		end

		local colorPicker = Lib.ColorPicker.new()
		colorPicker.OnSelect:Connect(function(col)
			if not activeKey then return end
			for _, row in ipairs(rows) do
				if row.key == activeKey then
					row.preview.BackgroundColor3 = col
					row.box.Text = colorToText(col)
					Settings.Theme[row.key] = col
					break
				end
			end
			Main.SaveThemeSettings()
			Lib.RefreshTheme()
			activeKey = nil
		end)

		local function parseColor(str)
			if not str or str == "" then return nil end
			str = str:gsub("#","")
			if #str == 6 and str:match("^[0-9a-fA-F]+$") then
				local r = tonumber(str:sub(1,2),16)
				local g = tonumber(str:sub(3,4),16)
				local b = tonumber(str:sub(5,6),16)
				if r and g and b then return Color3.fromRGB(r,g,b) end
			end
			local r,g,b = str:match("^(%d+)%s*,%s*(%d+)%s*,%s*(%d+)$")
			r,g,b = tonumber(r), tonumber(g), tonumber(b)
			if r and g and b then
				return Color3.fromRGB(math.clamp(r,0,255), math.clamp(g,0,255), math.clamp(b,0,255))
			end
			return nil
		end

		for _, key in ipairs(themeKeys) do
			local row = Instance.new("Frame")
			row.Name = key
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1,0,0,24)
			row.Parent = scroll

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Text = key
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextColor3 = Color3.new(1,1,1)
			label.Font = Enum.Font.SourceSans
			label.TextSize = 14
			label.Size = UDim2.new(0,120,1,0)
			label.Parent = row

			local preview = Instance.new("Frame")
			preview.BorderSizePixel = 0
			preview.Size = UDim2.new(0,24,0,24)
			preview.Position = UDim2.new(0,124,0,0)
			preview.BackgroundColor3 = Settings.Theme[key] or Color3.fromRGB(60,60,60)
			preview.Parent = row

			local pickBtn = Instance.new("TextButton")
			pickBtn.BackgroundTransparency = 1
			pickBtn.Text = ""
			pickBtn.Size = preview.Size
			pickBtn.Position = preview.Position
			pickBtn.Parent = row

			local box = Instance.new("TextBox")
			box.Text = colorToText(preview.BackgroundColor3)
			box.PlaceholderText = "r,g,b or #RRGGBB"
			box.TextColor3 = Color3.new(1,1,1)
			box.BackgroundColor3 = Settings.Theme.TextBox
			box.BorderSizePixel = 0
			box.Size = UDim2.new(1,-180,1,0)
			box.Position = UDim2.new(0,154,0,0)
			box.TextSize = 14
			box.Parent = row

			rows[#rows+1] = {key=key, box=box, preview=preview}

			pickBtn.MouseButton1Click:Connect(function()
				activeKey = key
				colorPicker:SetColor(preview.BackgroundColor3)
				colorPicker:Show()
			end)
		end

		local applyColorsBtn = makeButton("Apply Colors",0,function()
			for _, row in ipairs(rows) do
				local col = parseColor(row.box.Text)
				if col then
					Settings.Theme[row.key] = col
					row.preview.BackgroundColor3 = col
				end
			end
			Main.SaveThemeSettings()
			Lib.RefreshTheme()
		end)
		applyColorsBtn.Position = UDim2.new(0,8,1,-36)
		applyColorsBtn.AnchorPoint = Vector2.new(0,1)
	end

	return ThemeManager
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
