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
			name = "Tokyo",
			apply = function()
				Settings.Theme = Settings.Theme or {}
				local t = Settings.Theme
				local s = t.Syntax or {}
				t.Main1 = Color3.fromRGB(26,22,32)
				t.Main2 = Color3.fromRGB(18,14,26)
				t.Outline1 = Color3.fromRGB(40,24,50)
				t.Outline2 = Color3.fromRGB(70,36,90)
				t.Outline3 = Color3.fromRGB(16,10,24)
				t.TextBox = Color3.fromRGB(32,24,44)
				t.Menu = Color3.fromRGB(24,18,36)
				t.ListSelection = Color3.fromRGB(255,105,180)
				t.Button = Color3.fromRGB(46,32,70)
				t.ButtonHover = Color3.fromRGB(60,40,90)
				t.ButtonPress = Color3.fromRGB(30,20,50)
				t.Highlight = Color3.fromRGB(80,50,100)
				t.Text = Color3.fromRGB(245,235,255)
				t.PlaceholderText = Color3.fromRGB(170,140,190)
				t.Important = Color3.fromRGB(255,90,130)

				s.Text = Color3.fromRGB(235,225,245)
				s.Background = Color3.fromRGB(22,16,32)
				s.Selection = Color3.fromRGB(255,255,255)
				s.SelectionBack = Color3.fromRGB(255,105,180)
				s.Operator = Color3.fromRGB(235,225,245)
				s.Number = Color3.fromRGB(255,210,120)
				s.String = Color3.fromRGB(190,250,170)
				s.Comment = Color3.fromRGB(130,110,160)
				s.Keyword = Color3.fromRGB(255,150,200)
				s.Error = Color3.fromRGB(255,110,150)
				s.FindBackground = Color3.fromRGB(200,120,180)
				s.MatchingWord = Color3.fromRGB(90,70,120)
				s.BuiltIn = Color3.fromRGB(150,210,255)
				s.CurrentLine = Color3.fromRGB(38,26,60)
				s.LocalMethod = Color3.fromRGB(255,252,190)
				s.LocalProperty = Color3.fromRGB(150,190,255)
				s.Nil = Color3.fromRGB(255,210,120)
				s.Bool = Color3.fromRGB(255,210,120)
				s.Function = Color3.fromRGB(255,150,200)
				s.Local = Color3.fromRGB(255,150,200)
				s.Self = Color3.fromRGB(255,150,200)
				s.FunctionName = Color3.fromRGB(255,252,190)
				s.Bracket = Color3.fromRGB(235,225,245)

				t.Syntax = s
			end
		},
		{
			name = "Cyberpunk",
			apply = function()
				Settings.Theme = Settings.Theme or {}
				local t = Settings.Theme
				local s = t.Syntax or {}
				t.Main1 = Color3.fromRGB(8,8,18)
				t.Main2 = Color3.fromRGB(4,4,10)
				t.Outline1 = Color3.fromRGB(20,20,40)
				t.Outline2 = Color3.fromRGB(30,16,60)
				t.Outline3 = Color3.fromRGB(6,6,18)
				t.TextBox = Color3.fromRGB(20,16,38)
				t.Menu = Color3.fromRGB(14,10,30)
				t.ListSelection = Color3.fromRGB(0,255,255)
				t.Button = Color3.fromRGB(24,20,44)
				t.ButtonHover = Color3.fromRGB(40,30,70)
				t.ButtonPress = Color3.fromRGB(16,12,30)
				t.Highlight = Color3.fromRGB(80,10,110)
				t.Text = Color3.fromRGB(230,240,255)
				t.PlaceholderText = Color3.fromRGB(130,150,190)
				t.Important = Color3.fromRGB(255,40,120)

				s.Text = Color3.fromRGB(220,230,250)
				s.Background = Color3.fromRGB(6,6,16)
				s.Selection = Color3.fromRGB(255,255,255)
				s.SelectionBack = Color3.fromRGB(0,255,255)
				s.Operator = Color3.fromRGB(230,240,255)
				s.Number = Color3.fromRGB(255,220,120)
				s.String = Color3.fromRGB(180,255,180)
				s.Comment = Color3.fromRGB(110,120,150)
				s.Keyword = Color3.fromRGB(255,80,190)
				s.Error = Color3.fromRGB(255,70,110)
				s.FindBackground = Color3.fromRGB(40,220,200)
				s.MatchingWord = Color3.fromRGB(40,60,120)
				s.BuiltIn = Color3.fromRGB(120,210,255)
				s.CurrentLine = Color3.fromRGB(20,20,36)
				s.LocalMethod = Color3.fromRGB(255,252,200)
				s.LocalProperty = Color3.fromRGB(130,190,255)
				s.Nil = Color3.fromRGB(255,220,120)
				s.Bool = Color3.fromRGB(255,220,120)
				s.Function = Color3.fromRGB(255,80,190)
				s.Local = Color3.fromRGB(255,80,190)
				s.Self = Color3.fromRGB(255,80,190)
				s.FunctionName = Color3.fromRGB(255,252,200)
				s.Bracket = Color3.fromRGB(220,230,250)

				t.Syntax = s
			end
		},
		{
			name = "ULTRAKILL",
			apply = function()
				Settings.Theme = Settings.Theme or {}
				local t = Settings.Theme
				local s = t.Syntax or {}
				t.Main1 = Color3.fromRGB(24,10,10)
				t.Main2 = Color3.fromRGB(14,4,4)
				t.Outline1 = Color3.fromRGB(40,10,10)
				t.Outline2 = Color3.fromRGB(80,20,20)
				t.Outline3 = Color3.fromRGB(14,4,4)
				t.TextBox = Color3.fromRGB(30,10,10)
				t.Menu = Color3.fromRGB(22,8,8)
				t.ListSelection = Color3.fromRGB(255,40,40)
				t.Button = Color3.fromRGB(50,18,18)
				t.ButtonHover = Color3.fromRGB(70,24,24)
				t.ButtonPress = Color3.fromRGB(30,10,10)
				t.Highlight = Color3.fromRGB(110,30,30)
				t.Text = Color3.fromRGB(250,230,230)
				t.PlaceholderText = Color3.fromRGB(170,120,120)
				t.Important = Color3.fromRGB(255,80,80)

				s.Text = Color3.fromRGB(240,220,220)
				s.Background = Color3.fromRGB(18,8,8)
				s.Selection = Color3.fromRGB(255,255,255)
				s.SelectionBack = Color3.fromRGB(255,60,60)
				s.Operator = Color3.fromRGB(250,230,230)
				s.Number = Color3.fromRGB(255,210,110)
				s.String = Color3.fromRGB(220,255,190)
				s.Comment = Color3.fromRGB(150,110,110)
				s.Keyword = Color3.fromRGB(255,120,120)
				s.Error = Color3.fromRGB(255,100,100)
				s.FindBackground = Color3.fromRGB(200,60,60)
				s.MatchingWord = Color3.fromRGB(90,40,40)
				s.BuiltIn = Color3.fromRGB(255,210,150)
				s.CurrentLine = Color3.fromRGB(40,16,16)
				s.LocalMethod = Color3.fromRGB(255,250,190)
				s.LocalProperty = Color3.fromRGB(255,200,160)
				s.Nil = Color3.fromRGB(255,210,110)
				s.Bool = Color3.fromRGB(255,210,110)
				s.Function = Color3.fromRGB(255,120,120)
				s.Local = Color3.fromRGB(255,120,120)
				s.Self = Color3.fromRGB(255,120,120)
				s.FunctionName = Color3.fromRGB(255,250,190)
				s.Bracket = Color3.fromRGB(240,220,220)

				t.Syntax = s
			end
		},
		{
			name = "Emo",
			apply = function()
				Settings.Theme = Settings.Theme or {}
				local t = Settings.Theme
				local s = t.Syntax or {}
				t.Main1 = Color3.fromRGB(20,20,24)
				t.Main2 = Color3.fromRGB(12,12,16)
				t.Outline1 = Color3.fromRGB(40,40,46)
				t.Outline2 = Color3.fromRGB(60,60,70)
				t.Outline3 = Color3.fromRGB(16,16,20)
				t.TextBox = Color3.fromRGB(22,22,28)
				t.Menu = Color3.fromRGB(18,18,22)
				t.ListSelection = Color3.fromRGB(200,120,220)
				t.Button = Color3.fromRGB(34,34,42)
				t.ButtonHover = Color3.fromRGB(46,46,56)
				t.ButtonPress = Color3.fromRGB(24,24,30)
				t.Highlight = Color3.fromRGB(70,40,90)
				t.Text = Color3.fromRGB(235,235,245)
				t.PlaceholderText = Color3.fromRGB(150,150,170)
				t.Important = Color3.fromRGB(255,90,140)

				s.Text = Color3.fromRGB(225,225,240)
				s.Background = Color3.fromRGB(14,14,18)
				s.Selection = Color3.fromRGB(255,255,255)
				s.SelectionBack = Color3.fromRGB(200,120,220)
				s.Operator = Color3.fromRGB(225,225,240)
				s.Number = Color3.fromRGB(255,210,120)
				s.String = Color3.fromRGB(200,245,190)
				s.Comment = Color3.fromRGB(140,140,160)
				s.Keyword = Color3.fromRGB(255,150,210)
				s.Error = Color3.fromRGB(255,110,160)
				s.FindBackground = Color3.fromRGB(180,120,200)
				s.MatchingWord = Color3.fromRGB(70,70,100)
				s.BuiltIn = Color3.fromRGB(160,210,255)
				s.CurrentLine = Color3.fromRGB(30,30,40)
				s.LocalMethod = Color3.fromRGB(255,252,200)
				s.LocalProperty = Color3.fromRGB(150,190,255)
				s.Nil = Color3.fromRGB(255,210,120)
				s.Bool = Color3.fromRGB(255,210,120)
				s.Function = Color3.fromRGB(255,150,210)
				s.Local = Color3.fromRGB(255,150,210)
				s.Self = Color3.fromRGB(255,150,210)
				s.FunctionName = Color3.fromRGB(255,252,200)
				s.Bracket = Color3.fromRGB(225,225,240)

				t.Syntax = s
			end
		},
		{
			name = "Ocean",
			apply = function()
				Settings.Theme = Settings.Theme or {}
				local t = Settings.Theme
				local s = t.Syntax or {}
				t.Main1 = Color3.fromRGB(10,28,34)
				t.Main2 = Color3.fromRGB(6,18,24)
				t.Outline1 = Color3.fromRGB(12,40,50)
				t.Outline2 = Color3.fromRGB(20,70,90)
				t.Outline3 = Color3.fromRGB(6,24,30)
				t.TextBox = Color3.fromRGB(12,32,40)
				t.Menu = Color3.fromRGB(8,26,34)
				t.ListSelection = Color3.fromRGB(0,180,200)
				t.Button = Color3.fromRGB(16,40,50)
				t.ButtonHover = Color3.fromRGB(22,60,70)
				t.ButtonPress = Color3.fromRGB(10,30,38)
				t.Highlight = Color3.fromRGB(30,90,110)
				t.Text = Color3.fromRGB(220,240,245)
				t.PlaceholderText = Color3.fromRGB(140,180,190)
				t.Important = Color3.fromRGB(255,120,120)

				s.Text = Color3.fromRGB(210,235,240)
				s.Background = Color3.fromRGB(6,20,26)
				s.Selection = Color3.fromRGB(255,255,255)
				s.SelectionBack = Color3.fromRGB(0,180,200)
				s.Operator = Color3.fromRGB(210,235,240)
				s.Number = Color3.fromRGB(255,220,130)
				s.String = Color3.fromRGB(190,255,210)
				s.Comment = Color3.fromRGB(110,150,160)
				s.Keyword = Color3.fromRGB(110,220,255)
				s.Error = Color3.fromRGB(255,120,140)
				s.FindBackground = Color3.fromRGB(40,160,190)
				s.MatchingWord = Color3.fromRGB(40,80,100)
				s.BuiltIn = Color3.fromRGB(140,220,255)
				s.CurrentLine = Color3.fromRGB(14,34,44)
				s.LocalMethod = Color3.fromRGB(255,252,200)
				s.LocalProperty = Color3.fromRGB(150,210,255)
				s.Nil = Color3.fromRGB(255,220,130)
				s.Bool = Color3.fromRGB(255,220,130)
				s.Function = Color3.fromRGB(110,220,255)
				s.Local = Color3.fromRGB(110,220,255)
				s.Self = Color3.fromRGB(110,220,255)
				s.FunctionName = Color3.fromRGB(255,252,200)
				s.Bracket = Color3.fromRGB(210,235,240)

				t.Syntax = s
			end
		},
		{
			name = "Midnight Purple",
			apply = function()
				Settings.Theme = Settings.Theme or {}
				local t = Settings.Theme
				local s = t.Syntax or {}
				t.Main1 = Color3.fromRGB(18,10,32)
				t.Main2 = Color3.fromRGB(10,6,24)
				t.Outline1 = Color3.fromRGB(30,16,54)
				t.Outline2 = Color3.fromRGB(56,28,96)
				t.Outline3 = Color3.fromRGB(12,8,26)
				t.TextBox = Color3.fromRGB(22,14,40)
				t.Menu = Color3.fromRGB(16,10,30)
				t.ListSelection = Color3.fromRGB(200,120,255)
				t.Button = Color3.fromRGB(32,18,60)
				t.ButtonHover = Color3.fromRGB(46,26,80)
				t.ButtonPress = Color3.fromRGB(22,12,44)
				t.Highlight = Color3.fromRGB(80,40,120)
				t.Text = Color3.fromRGB(235,225,255)
				t.PlaceholderText = Color3.fromRGB(170,140,210)
				t.Important = Color3.fromRGB(255,100,170)

				s.Text = Color3.fromRGB(230,220,245)
				s.Background = Color3.fromRGB(12,8,24)
				s.Selection = Color3.fromRGB(255,255,255)
				s.SelectionBack = Color3.fromRGB(200,120,255)
				s.Operator = Color3.fromRGB(230,220,245)
				s.Number = Color3.fromRGB(255,215,130)
				s.String = Color3.fromRGB(200,250,190)
				s.Comment = Color3.fromRGB(140,120,170)
				s.Keyword = Color3.fromRGB(255,150,220)
				s.Error = Color3.fromRGB(255,110,170)
				s.FindBackground = Color3.fromRGB(190,120,220)
				s.MatchingWord = Color3.fromRGB(80,60,120)
				s.BuiltIn = Color3.fromRGB(160,210,255)
				s.CurrentLine = Color3.fromRGB(26,18,50)
				s.LocalMethod = Color3.fromRGB(255,252,200)
				s.LocalProperty = Color3.fromRGB(160,200,255)
				s.Nil = Color3.fromRGB(255,215,130)
				s.Bool = Color3.fromRGB(255,215,130)
				s.Function = Color3.fromRGB(255,150,220)
				s.Local = Color3.fromRGB(255,150,220)
				s.Self = Color3.fromRGB(255,150,220)
				s.FunctionName = Color3.fromRGB(255,252,200)
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
			if refreshRows then
				refreshRows()
			end
			Main.SaveThemeSettings()
			Lib.RefreshTheme()
		end)

		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "ThemeContent"
		scroll.Size = UDim2.new(1,-16,1,-120)
		scroll.Position = UDim2.new(0,8,0,120)
		scroll.BackgroundTransparency = 0.1
		scroll.BackgroundColor3 = Settings.Theme.Main1
		scroll.CanvasSize = UDim2.new(0,0,0,0)
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ScrollBarThickness = 6
		scroll.Parent = content

		local innerPad = Instance.new("UIPadding")
		innerPad.PaddingTop = UDim.new(0,6)
		innerPad.PaddingLeft = UDim.new(0,4)
		innerPad.PaddingRight = UDim.new(0,4)
		innerPad.Parent = scroll

		local list = Instance.new("UIListLayout", scroll)
		list.Padding = UDim.new(0,6)
		list.SortOrder = Enum.SortOrder.LayoutOrder

		local pLabel = Instance.new("TextLabel")
		pLabel.BackgroundTransparency = 1
		pLabel.Text = "Presets"
		pLabel.TextXAlignment = Enum.TextXAlignment.Left
		pLabel.TextColor3 = Color3.new(1,1,1)
		pLabel.Font = Enum.Font.SourceSans
		pLabel.TextSize = 14
		pLabel.Size = UDim2.new(1,0,0,18)
		pLabel.LayoutOrder = 1
		pLabel.Parent = scroll

		for i,p in ipairs(presets) do
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1,0,0,24)
			b.BackgroundTransparency = 0
			b.BackgroundColor3 = Settings.Theme.Button
			b.Text = p.name
			b.TextColor3 = Color3.new(1,1,1)
			b.Font = Enum.Font.SourceSans
			b.TextSize = 14
			b.AutoButtonColor = false
			b.LayoutOrder = 10 + i
			b.Parent = scroll
			Lib.ButtonAnim(b,{PressColor = Settings.Theme.ButtonPress})
			b.MouseButton1Click:Connect(function()
				p.apply()
				if refreshRows then
					refreshRows()
				end
				Main.SaveThemeSettings()
				Lib.RefreshTheme()
			end)
		end

		local sep = Instance.new("Frame")
		sep.BackgroundColor3 = Color3.fromRGB(80,80,80)
		sep.BorderSizePixel = 0
		sep.Size = UDim2.new(1,0,0,1)
		sep.LayoutOrder = 100
		sep.Parent = scroll

		local cLabel = Instance.new("TextLabel")
		cLabel.BackgroundTransparency = 1
		cLabel.Text = "Colors"
		cLabel.TextXAlignment = Enum.TextXAlignment.Left
		cLabel.TextColor3 = Color3.new(1,1,1)
		cLabel.Font = Enum.Font.SourceSans
		cLabel.TextSize = 14
		cLabel.Size = UDim2.new(1,0,0,18)
		cLabel.LayoutOrder = 101
		cLabel.Parent = scroll

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

		for i,path in ipairs(themeEntries) do
			local keyLabel = table.concat(path,".")
			local row = Instance.new("Frame")
			row.Name = keyLabel
			row.BackgroundTransparency = 1
			row.Size = UDim2.new(1,0,0,24)
			row.LayoutOrder = 200 + i
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
