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
	local refreshRows

	local presets = {
		{
			name = "Default",
			apply = function()
				Settings.Theme = Settings.Theme or {}
				local t = Settings.Theme
				local s = t.Syntax or {}
				t.Main1 = Color3.fromRGB(52,52,52)
				t.Main2 = Color3.fromRGB(45,45,45)
				t.Outline1 = Color3.fromRGB(33,33,33)
				t.Outline2 = Color3.fromRGB(55,55,55)
				t.Outline3 = Color3.fromRGB(30,30,30)
				t.TextBox = Color3.fromRGB(38,38,38)
				t.Menu = Color3.fromRGB(32,32,32)
				t.ListSelection = Color3.fromRGB(11,90,175)
				t.Button = Color3.fromRGB(60,60,60)
				t.ButtonHover = Color3.fromRGB(68,68,68)
				t.ButtonPress = Color3.fromRGB(40,40,40)
				t.Highlight = Color3.fromRGB(75,75,75)
				t.Text = Color3.fromRGB(255,255,255)
				t.PlaceholderText = Color3.fromRGB(100,100,100)
				t.Important = Color3.fromRGB(255,0,0)

				s.Text = Color3.fromRGB(204,204,204)
				s.Background = Color3.fromRGB(36,36,36)
				s.Selection = Color3.fromRGB(255,255,255)
				s.SelectionBack = Color3.fromRGB(11,90,175)
				s.Operator = Color3.fromRGB(204,204,204)
				s.Number = Color3.fromRGB(255,198,0)
				s.String = Color3.fromRGB(173,241,149)
				s.Comment = Color3.fromRGB(102,102,102)
				s.Keyword = Color3.fromRGB(248,109,124)
				s.Error = Color3.fromRGB(255,0,0)
				s.FindBackground = Color3.fromRGB(141,118,0)
				s.MatchingWord = Color3.fromRGB(85,85,85)
				s.BuiltIn = Color3.fromRGB(132,214,247)
				s.CurrentLine = Color3.fromRGB(45,50,65)
				s.LocalMethod = Color3.fromRGB(253,251,172)
				s.LocalProperty = Color3.fromRGB(97,161,241)
				s.Nil = Color3.fromRGB(255,198,0)
				s.Bool = Color3.fromRGB(255,198,0)
				s.Function = Color3.fromRGB(248,109,124)
				s.Local = Color3.fromRGB(248,109,124)
				s.Self = Color3.fromRGB(248,109,124)
				s.FunctionName = Color3.fromRGB(253,251,172)
				s.Bracket = Color3.fromRGB(204,204,204)

				t.Syntax = s
			end
		},
		{
			name = "Midnight",
			apply = function()
				Settings.Theme = Settings.Theme or {}
				local t = Settings.Theme
				local s = t.Syntax or {}
				t.Main1 = Color3.fromRGB(18,18,26)
				t.Main2 = Color3.fromRGB(12,12,20)
				t.Outline1 = Color3.fromRGB(10,10,18)
				t.Outline2 = Color3.fromRGB(30,30,40)
				t.Outline3 = Color3.fromRGB(6,6,12)
				t.TextBox = Color3.fromRGB(20,20,30)
				t.Menu = Color3.fromRGB(16,16,24)
				t.ListSelection = Color3.fromRGB(40,120,220)
				t.Button = Color3.fromRGB(30,30,42)
				t.ButtonHover = Color3.fromRGB(40,40,56)
				t.ButtonPress = Color3.fromRGB(20,20,30)
				t.Highlight = Color3.fromRGB(50,50,70)
				t.Text = Color3.fromRGB(230,230,240)
				t.PlaceholderText = Color3.fromRGB(120,120,150)
				t.Important = Color3.fromRGB(255,80,80)

				s.Text = Color3.fromRGB(210,210,225)
				s.Background = Color3.fromRGB(14,14,22)
				s.Selection = Color3.fromRGB(255,255,255)
				s.SelectionBack = Color3.fromRGB(40,120,220)
				s.Operator = Color3.fromRGB(230,230,240)
				s.Number = Color3.fromRGB(255,208,90)
				s.String = Color3.fromRGB(170,235,150)
				s.Comment = Color3.fromRGB(110,110,140)
				s.Keyword = Color3.fromRGB(250,120,150)
				s.Error = Color3.fromRGB(255,90,90)
				s.FindBackground = Color3.fromRGB(150,120,30)
				s.MatchingWord = Color3.fromRGB(70,70,100)
				s.BuiltIn = Color3.fromRGB(130,210,250)
				s.CurrentLine = Color3.fromRGB(30,34,56)
				s.LocalMethod = Color3.fromRGB(250,248,180)
				s.LocalProperty = Color3.fromRGB(110,180,250)
				s.Nil = Color3.fromRGB(255,208,90)
				s.Bool = Color3.fromRGB(255,208,90)
				s.Function = Color3.fromRGB(250,120,150)
				s.Local = Color3.fromRGB(250,120,150)
				s.Self = Color3.fromRGB(250,120,150)
				s.FunctionName = Color3.fromRGB(250,248,180)
				s.Bracket = Color3.fromRGB(210,210,225)

				t.Syntax = s
			end
		},
		{
			name = "Purple",
			apply = function()
				Settings.Theme = Settings.Theme or {}
				local t = Settings.Theme
				local s = t.Syntax or {}
				t.Main1 = Color3.fromRGB(28,20,40)
				t.Main2 = Color3.fromRGB(20,14,32)
				t.Outline1 = Color3.fromRGB(16,10,28)
				t.Outline2 = Color3.fromRGB(46,32,70)
				t.Outline3 = Color3.fromRGB(12,8,20)
				t.TextBox = Color3.fromRGB(30,22,50)
				t.Menu = Color3.fromRGB(24,18,40)
				t.ListSelection = Color3.fromRGB(190,80,255)
				t.Button = Color3.fromRGB(40,30,70)
				t.ButtonHover = Color3.fromRGB(54,40,90)
				t.ButtonPress = Color3.fromRGB(26,18,44)
				t.Highlight = Color3.fromRGB(60,44,100)
				t.Text = Color3.fromRGB(240,230,255)
				t.PlaceholderText = Color3.fromRGB(150,130,190)
				t.Important = Color3.fromRGB(255,90,140)

				s.Text = Color3.fromRGB(230,220,245)
				s.Background = Color3.fromRGB(22,16,34)
				s.Selection = Color3.fromRGB(255,255,255)
				s.SelectionBack = Color3.fromRGB(190,80,255)
				s.Operator = Color3.fromRGB(230,220,245)
				s.Number = Color3.fromRGB(255,210,110)
				s.String = Color3.fromRGB(190,250,170)
				s.Comment = Color3.fromRGB(130,110,170)
				s.Keyword = Color3.fromRGB(255,130,190)
				s.Error = Color3.fromRGB(255,100,150)
				s.FindBackground = Color3.fromRGB(180,120,160)
				s.MatchingWord = Color3.fromRGB(90,70,130)
				s.BuiltIn = Color3.fromRGB(150,210,255)
				s.CurrentLine = Color3.fromRGB(40,30,70)
				s.LocalMethod = Color3.fromRGB(255,252,190)
				s.LocalProperty = Color3.fromRGB(130,190,255)
				s.Nil = Color3.fromRGB(255,210,110)
				s.Bool = Color3.fromRGB(255,210,110)
				s.Function = Color3.fromRGB(255,130,190)
				s.Local = Color3.fromRGB(255,130,190)
				s.Self = Color3.fromRGB(255,130,190)
				s.FunctionName = Color3.fromRGB(255,252,190)
				s.Bracket = Color3.fromRGB(230,220,245)

				t.Syntax = s
			end
		}
	}

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
			btn.AutoButtonColor = false
			btn.BackgroundTransparency = 0
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
			refreshRows()
			Main.SaveThemeSettings()
			Lib.RefreshTheme()
		end)

		local pLabel = Instance.new("TextLabel")
		pLabel.BackgroundTransparency = 1
		pLabel.Text = "Presets"
		pLabel.TextXAlignment = Enum.TextXAlignment.Left
		pLabel.TextColor3 = Color3.new(1,1,1)
		pLabel.Font = Enum.Font.SourceSans
		pLabel.TextSize = 14
		pLabel.Size = UDim2.new(1,-16,0,18)
		pLabel.Position = UDim2.new(0,8,0,112)
		pLabel.Parent = content

		local pFrame = Instance.new("Frame")
		pFrame.BackgroundTransparency = 1
		pFrame.Size = UDim2.new(1,-16,0,32)
		pFrame.Position = UDim2.new(0,8,0,136)
		pFrame.Parent = content

		local pList = Instance.new("UIListLayout")
		pList.FillDirection = Enum.FillDirection.Horizontal
		pList.Padding = UDim.new(0,6)
		pList.Parent = pFrame

		for _, p in ipairs(presets) do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0,100,1,0)
			b.Text = p.name
			b.TextColor3 = Color3.new(1,1,1)
			b.BackgroundTransparency = 0
			b.BackgroundColor3 = Settings.Theme.Button
			b.AutoButtonColor = false
			b.Font = Enum.Font.SourceSans
			b.TextSize = 14
			Lib.ButtonAnim(b,{PressColor = Settings.Theme.ButtonPress})
			b.Parent = pFrame
			b.MouseButton1Click:Connect(function()
				p.apply()
				if refreshRows then
					refreshRows()
				end
				Main.SaveThemeSettings()
				Lib.RefreshTheme()
			end)
		end

		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "ColorList"
		scroll.Size = UDim2.new(1,-16,1,-184)
		scroll.Position = UDim2.new(0,8,0,176)
		scroll.BackgroundTransparency = 0.1
		scroll.BackgroundColor3 = Settings.Theme.Main1
		scroll.CanvasSize = UDim2.new(0,0,0,0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ScrollBarThickness = 6
		scroll.Parent = content

		local list = Instance.new("UIListLayout", scroll)
		list.Padding = UDim.new(0,6)

		local themeEntries = {
			{"Main1"},{"Main2"},{"Outline1"},{"Outline2"},{"Outline3"},{"TextBox"},{"Menu"},
			{"ListSelection"},{"Button"},{"ButtonHover"},{"ButtonPress"},{"Highlight"},
			{"Text"},{"PlaceholderText"},{"Important"},
			{"Syntax","Text"},{"Syntax","Background"},{"Syntax","Selection"},{"Syntax","SelectionBack"},
			{"Syntax","Operator"},{"Syntax","Number"},{"Syntax","String"},{"Syntax","Comment"},
			{"Syntax","Keyword"},{"Syntax","Error"},{"Syntax","FindBackground"},{"Syntax","MatchingWord"},
			{"Syntax","BuiltIn"},{"Syntax","CurrentLine"},{"Syntax","LocalMethod"},{"Syntax","LocalProperty"},
			{"Syntax","Nil"},{"Syntax","Bool"},{"Syntax","Function"},{"Syntax","Local"},{"Syntax","Self"},
			{"Syntax","FunctionName"},{"Syntax","Bracket"}
		}

		local rows = {}
		local activeKey

		local colorPicker = Lib.ColorPicker.new()
		local function getThemeColor(path)
			local ref = Settings.Theme
			for i = 1,#path do
				if type(ref) ~= "table" then return nil end
				ref = ref[path[i]]
			end
			return ref
		end

		local function setThemeColor(path, col)
			local ref = Settings.Theme
			for i = 1,#path-1 do
				if type(ref[path[i]]) ~= "table" then ref[path[i]] = {} end
				ref = ref[path[i]]
			end
			ref[path[#path]] = col
		end

		function refreshRows()
			for _, row in ipairs(rows) do
				local col = getThemeColor(row.path) or Color3.fromRGB(60,60,60)
				row.preview.BackgroundColor3 = col
			end
		end

		for _, path in ipairs(themeEntries) do
			local keyLabel = table.concat(path,".")
			local row = Instance.new("Frame")
			row.Name = keyLabel
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1,0,0,24)
			row.Parent = scroll

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Text = keyLabel
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
			preview.BackgroundColor3 = getThemeColor(path) or Color3.fromRGB(60,60,60)
			preview.Parent = row

			local pickBtn = Instance.new("TextButton")
			pickBtn.BackgroundTransparency = 1
			pickBtn.Text = ""
			pickBtn.Size = preview.Size
			pickBtn.Position = preview.Position
			pickBtn.Parent = row
			rows[#rows+1] = {key=keyLabel, path=path, preview=preview}

			pickBtn.MouseButton1Click:Connect(function()
				activeKey = path
				colorPicker:SetColor(preview.BackgroundColor3)
				colorPicker:Show()
			end)
		end

		colorPicker.OnSelect:Connect(function(col)
			if not activeKey then return end
			setThemeColor(activeKey, col)
			for _, row in ipairs(rows) do
				if row.path == activeKey then
					row.preview.BackgroundColor3 = col
					break
				end
			end
			Main.SaveThemeSettings()
			Lib.RefreshTheme()
			activeKey = nil
			refreshRows()
		end)

		refreshRows()
	end

	return ThemeManager
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
