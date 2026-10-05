--!nonstrict
local task, coroutine, TweenInfo = task, coroutine, TweenInfo
local unpack = table.unpack or unpack
local loadstring = loadstring or load
local newproxy = newproxy or function()
	return setmetatable({}, {
		__tostring = function()
			return "userdata: 0x0"
		end,
	})
end

--[[
	Theme Manager Module
]]
local Main,Lib,Apps,Settings

local function initDeps(data)
	Main = data.Main
	task = Main.Tasks or task
	coroutine = Main.Coroutine or coroutine
	TweenInfo = Main.TweenInfo or TweenInfo
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings
end

local function initAfterMain() end

local function trackConn(conn)
	if Main and Main.TrackConn then
		return Main.TrackConn(conn)
	end
	return conn
end
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

	presets[#presets + 1] = {name = "Light", apply = function()
		local t = Settings.Theme
		t.Main1 = Color3.fromRGB(246,247,250)
		t.Main2 = Color3.fromRGB(230,232,238)
		t.Outline1 = Color3.fromRGB(194,198,210)
		t.Outline2 = Color3.fromRGB(176,182,196)
		t.Outline3 = Color3.fromRGB(150,158,176)
		t.TextBox = Color3.fromRGB(255,255,255)
		t.Menu = Color3.fromRGB(238,240,245)
		t.Button = Color3.fromRGB(218,224,236)
		t.ButtonHover = Color3.fromRGB(198,212,234)
		t.ButtonPress = Color3.fromRGB(178,198,228)
		t.Text = Color3.fromRGB(24,30,42)
		t.PlaceholderText = Color3.fromRGB(90,98,116)
		t.ListSelection = Color3.fromRGB(138,182,242)
		t.Highlight = Color3.fromRGB(206,218,240)
		t.Important = Color3.fromRGB(180,24,48)
		local s = t.Syntax
		s.Background = Color3.fromRGB(250,251,253)
		s.Text = t.Text
		s.Operator = t.Text
		s.Selection = t.Text
		s.SelectionBack = t.ListSelection
		s.Number = Color3.fromRGB(152,92,12)
		s.String = Color3.fromRGB(38,120,46)
		s.Comment = Color3.fromRGB(104,110,126)
		s.Keyword = Color3.fromRGB(144,38,132)
		s.BuiltIn = Color3.fromRGB(22,102,156)
		s.Error = t.Important
		s.CurrentLine = Color3.fromRGB(230,236,246)
		s.FunctionName = Color3.fromRGB(120,72,20)
		s.LocalMethod = s.FunctionName
		s.LocalProperty = s.BuiltIn
		s.Nil = s.Number
		s.Bool = s.Number
		s.Function = s.Keyword
		s.Local = s.Keyword
		s.Self = s.Keyword
		s.Bracket = t.Text
		s.FindBackground = Color3.fromRGB(248,220,132)
		s.MatchingWord = Color3.fromRGB(202,216,240)
	end}
	local undo = {}
	local tab = "Presets"
	local rows, tabs = {}, {}
	local scroll, search, status, active, picker, activeKey, nameBox, autoBtn
	local function clone(src)
		local out = {}
		for key, val in src do out[key] = type(val) == "table" and clone(val) or val end
		return out
	end
	local function getColor(src, path)
		for key in path:gmatch("[^.]+") do src = type(src) == "table" and src[key] or nil end
		return src
	end
	local function message(text, bad)
		if not status then return end
		status.Text = text
		Lib.BindTheme(status, {TextColor3 = bad and "Important" or "PlaceholderText"})
	end
	local function save()
		local ok, err = Main.SaveThemeSettings()
		message(ok and "Theme saved" or (err or "Could not save theme"), not ok)
		return ok
	end
	local function remember()
		undo[#undo + 1] = {Theme = clone(Settings.Theme), Name = Main.ThemeSettings.Name}
		if #undo > 30 then table.remove(undo, 1) end
	end
	local function changed(name)
		Main.ApplyTheme(Settings.Theme, name or "Custom")
		if Main.ThemeSettings.AutoSave then save() else message("Unsaved changes") end
		if refreshRows then refreshRows() end
	end
	local function setColor(path, col)
		if typeof(col) ~= "Color3" or getColor(Settings.Theme, path) == col then return end
		remember()
		local parts = string.split(path, ".")
		local ref = Settings.Theme
		for i = 1, #parts - 1 do ref = ref[parts[i]] end
		ref[parts[#parts]] = col
		changed()
	end
	local function parseHex(text)
		local hex = text:gsub("%s+", ""):gsub("^#", "")
		if hex:match("^%x%x%x$") then hex = hex:gsub("(.)", "%1%1") end
		if not hex:match("^%x%x%x%x%x%x$") then return nil end
		return Color3.fromRGB(tonumber(hex:sub(1,2),16), tonumber(hex:sub(3,4),16), tonumber(hex:sub(5,6),16))
	end
	local function create(class, parent, props, theme)
		local obj = Instance.new(class)
		for key, val in props do obj[key] = val end
		if theme then Lib.BindTheme(obj, theme) end
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			if obj.Name ~= "Hex" then obj:SetAttribute("DexUIFont", true) end
		end
		obj.Parent = parent
		return obj
	end
	local function corner(obj)
		create("UICorner", obj, {CornerRadius = UDim.new(0, Settings.Window.CornerRadius or 4)})
	end
	local function button(parent, text, size, pos, fn)
		local obj = create("TextButton", parent, {Text = text, Name = text, Size = size, Position = pos or UDim2.new(), BorderSizePixel = 0, Font = Lib.GetUIFont(), TextSize = 14, AutoButtonColor = false}, {BackgroundColor3 = "Button", TextColor3 = "Text"})
		corner(obj)
		trackConn(obj.Activated:Connect(fn))
		trackConn(obj.MouseEnter:Connect(function() Lib.BindTheme(obj, {BackgroundColor3 = "ButtonHover"}) end))
		trackConn(obj.MouseLeave:Connect(function() Lib.BindTheme(obj, {BackgroundColor3 = tabs[obj.Text] == obj and obj.Text == tab and "ListSelection" or "Button"}) end))
		return obj
	end
	local function row(key, section, height)
		local obj = create("Frame", scroll, {Name = key, BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, height or 34), LayoutOrder = #rows + 1})
		rows[#rows + 1] = {Gui = obj, Key = key, Tab = section}
		return obj, rows[#rows]
	end
	local function label(parent, text, size, pos)
		return create("TextLabel", parent, {BackgroundTransparency = 1, Text = text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Font = Lib.GetUIFont(), TextSize = 14, Size = size, Position = pos or UDim2.new()}, {TextColor3 = "Text"})
	end
	local function rebuildSaved()
		for i = #rows, 1, -1 do
			if rows[i].Tab == "Saved" and rows[i].Saved then rows[i].Gui:Destroy() table.remove(rows, i) end
		end
		local names = {}
		for name in Main.ThemeSettings.Saved do names[#names + 1] = name end
		table.sort(names)
		for _, name in names do
			local frame, data = row(name, "Saved")
			data.Saved = true
			button(frame, name, UDim2.new(1, -82, 1, 0), nil, function()
				remember()
				Main.ApplyTheme(Main.ThemeSettings.Saved[name], name)
				changed(name)
			end)
			button(frame, "Delete", UDim2.new(0, 76, 1, 0), UDim2.new(1, -76, 0, 0), function()
				Main.ThemeSettings.Saved[name] = nil
				save()
				rebuildSaved()
				refreshRows()
			end)
		end
	end
	refreshRows = function()
		if not window or Main.__DexExiting then return end
		local query = search.Text:lower()
		for _, data in rows do
			data.Gui.Visible = data.Tab == tab and (data.Always or query == "" or data.Key:lower():find(query, 1, true) ~= nil)
			if data.Path then
				local col = getColor(Settings.Theme, data.Path)
				data.Swatch.BackgroundColor3 = col
				if not data.Hex:IsFocused() then data.Hex.Text = "#" .. col:ToHex():upper() end
			end
		end
		for name, obj in tabs do Lib.BindTheme(obj, {BackgroundColor3 = name == tab and "ListSelection" or "Button"}) end
		active.Text = "Current: " .. (Main.ThemeSettings.Name or "Custom")
		if autoBtn then autoBtn.Text = "Auto save changes: " .. (Main.ThemeSettings.AutoSave and "On" or "Off") end
	end
	ThemeManager.ApplyTheme = function()
		if refreshRows then refreshRows() end
	end
	ThemeManager.Destroy = function()
		activeKey = nil
		table.clear(rows)
		table.clear(tabs)
		table.clear(undo)
		refreshRows = nil
	end
	ThemeManager.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Themes")
		local w, h = Lib.FitSize(500, 580)
		window.MinX = math.min(360, w)
		window.MinY = math.min(400, h)
		window:Resize(w, h)
		ThemeManager.Window = window
		local content = window.GuiElems.Content
		picker = Lib.ColorPicker.new()
		local actions = create("Frame", content, {BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 30), Position = UDim2.new(0, 8, 0, 8)})
		local funcs = {
			{"Save", save},
			{"Reload", function()
				local snap = {Theme = clone(Settings.Theme), Name = Main.ThemeSettings.Name}
				local ok, err = Main.LoadThemeSettings()
				if ok then
					undo[#undo + 1] = snap
					if #undo > 30 then table.remove(undo, 1) end
					rebuildSaved()
					refreshRows()
				end
				message(ok and "Theme reloaded" or err, not ok)
			end},
			{"Reset", function() remember() Main.ResetTheme() changed("Default") end},
			{"Undo", function()
				local snap = table.remove(undo)
				if not snap then message("Nothing to undo") return end
				Main.ApplyTheme(snap.Theme, snap.Name)
				changed(snap.Name)
			end}
		}
		for i, data in funcs do button(actions, data[1], UDim2.new(0.25, -5, 1, 0), UDim2.new((i-1)/4, i == 1 and 0 or 2, 0, 0), data[2]) end
		active = label(content, "", UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 0, 44))
		status = label(content, "Choose a preset or edit individual colors", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 69))
		Lib.BindTheme(status, {TextColor3 = "PlaceholderText"})
		local bar = create("Frame", content, {BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 28), Position = UDim2.new(0, 8, 0, 96)})
		for i, name in {"Presets", "Colors", "Saved", "Options"} do
			tabs[name] = button(bar, name, UDim2.new(0.25, -4, 1, 0), UDim2.new((i-1)/4, 0, 0, 0), function()
				tab = name
				scroll.CanvasPosition = Vector2.zero
				refreshRows()
			end)
		end
		search = create("TextBox", content, {Name = "SearchThemes", Size = UDim2.new(1, -16, 0, 28), Position = UDim2.new(0, 8, 0, 132), Text = "", PlaceholderText = "Search presets, colors or saved themes", ClearTextOnFocus = false, Font = Lib.GetUIFont(), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0}, {BackgroundColor3 = "TextBox", TextColor3 = "Text", PlaceholderColor3 = "PlaceholderText"})
		corner(search)
		create("UIPadding", search, {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
		scroll = create("ScrollingFrame", content, {Name = "ThemeContent", Size = UDim2.new(1, -16, 1, -176), Position = UDim2.new(0, 8, 0, 168), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ScrollBarThickness = 6}, {ScrollBarImageColor3 = "ButtonHover"})
		create("UIListLayout", scroll, {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})
		create("UIPadding", scroll, {PaddingBottom = UDim.new(0, 8)})
		trackConn(search:GetPropertyChangedSignal("Text"):Connect(refreshRows))
		for _, preset in presets do
			local frame = row(preset.name, "Presets", 42)
			local base = Settings.Theme
			Settings.Theme = clone(base)
			preset.apply()
			local palette = clone(Settings.Theme)
			Settings.Theme = base
			local btn = button(frame, "", UDim2.new(1, 0, 1, 0), nil, function()
				remember()
				Main.ApplyTheme(palette, preset.name)
				changed(preset.name)
			end)
			btn.Name = preset.name
			label(btn, preset.name, UDim2.new(1, -150, 1, 0), UDim2.new(0, 10, 0, 0))
			for i, key in {"Main1", "Main2", "ListSelection", "Text"} do
				local swatch = create("Frame", btn, {Name = "ColorSwatch", Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -130 + (i-1)*30, 0.5, -12), BackgroundColor3 = palette[key], BorderSizePixel = 0})
				swatch:SetAttribute("DexColorLiteral", true)
			end
		end
		local keys = {}
		for key, val in Main.DefaultTheme do
			if typeof(val) == "Color3" then keys[#keys + 1] = key end
		end
		table.sort(keys)
		local syntax = {}
		for key, val in Main.DefaultTheme.Syntax do
			if typeof(val) == "Color3" then syntax[#syntax + 1] = "Syntax." .. key end
		end
		table.sort(syntax)
		for _, path in syntax do keys[#keys + 1] = path end
		for _, path in keys do
			local frame, data = row(path, "Colors")
			data.Path = path
			label(frame, path, UDim2.new(1, -126, 1, 0))
			local swatch = create("TextButton", frame, {Name = "ColorSwatch", Text = "", AutoButtonColor = false, Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -120, 0, 2), BackgroundColor3 = getColor(Settings.Theme, path), BorderSizePixel = 1}, {BorderColor3 = "Outline2"})
			swatch:SetAttribute("DexColorLiteral", true)
			local hex = create("TextBox", frame, {Name = "Hex", Size = UDim2.new(0, 84, 0, 30), Position = UDim2.new(1, -84, 0, 2), Text = "", ClearTextOnFocus = false, Font = Enum.Font.RobotoMono, TextSize = 13, BorderSizePixel = 0}, {BackgroundColor3 = "TextBox", TextColor3 = "Text"})
			data.Swatch, data.Hex = swatch, hex
			trackConn(swatch.Activated:Connect(function() activeKey = path picker:SetColor(getColor(Settings.Theme, path)) picker:Show() end))
			trackConn(swatch.MouseButton2Click:Connect(function() setColor(path, getColor(Main.DefaultTheme, path)) end))
			trackConn(hex.FocusLost:Connect(function()
				local col = parseHex(hex.Text)
				if col then setColor(path, col) else message("Use a hex color such as #4C8DFF", true) end
				hex.Text = "#" .. getColor(Settings.Theme, path):ToHex():upper()
			end))
		end
		local frame, data = row("Save named theme", "Saved", 34)
		data.Always = true
		nameBox = create("TextBox", frame, {Name = "ThemeName", Size = UDim2.new(1, -98, 1, 0), Text = "", PlaceholderText = "Name for this theme", ClearTextOnFocus = false, Font = Lib.GetUIFont(), TextSize = 14, BorderSizePixel = 0}, {BackgroundColor3 = "TextBox", TextColor3 = "Text", PlaceholderColor3 = "PlaceholderText"})
		button(frame, "Save as", UDim2.new(0, 90, 1, 0), UDim2.new(1, -90, 0, 0), function()
			local name = nameBox.Text:match("^%s*(.-)%s*$")
			if #name == 0 or #name > 48 then message("Use a name between 1 and 48 characters", true) return end
			local count = 0
			for _ in Main.ThemeSettings.Saved do count += 1 end
			if count >= 50 and not Main.ThemeSettings.Saved[name] then message("You can save up to 50 themes", true) return end
			Main.ThemeSettings.Saved[name] = clone(Settings.Theme)
			Main.ThemeSettings.Name = name
			save()
			rebuildSaved()
			refreshRows()
		end)
		local auto = row("Auto save changes", "Options")
		autoBtn = button(auto, "", UDim2.new(1, 0, 1, 0), nil, function()
			Main.ThemeSettings.AutoSave = not Main.ThemeSettings.AutoSave
			autoBtn.Text = "Auto save changes: " .. (Main.ThemeSettings.AutoSave and "On" or "Off")
			save()
		end)
		autoBtn.Text = "Auto save changes: " .. (Main.ThemeSettings.AutoSave and "On" or "Off")
		local note = row("Color controls", "Options", 70)
		local text = label(note, "Enter #RGB or #RRGGBB colors, or tap a swatch to open the picker. Right click a swatch to restore its default color. Reset changes only the theme.", UDim2.new(1, 0, 1, 0))
		text.TextWrapped = true
		text.TextTruncate = Enum.TextTruncate.None
		trackConn(picker.OnSelect:Connect(function(col)
			if activeKey then setColor(activeKey, col) activeKey = nil end
		end))
		rebuildSaved()
		refreshRows()
	end

	return ThemeManager
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
