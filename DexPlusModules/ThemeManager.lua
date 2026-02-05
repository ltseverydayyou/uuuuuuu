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

		-- Color editor
		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "ColorList"
		scroll.Size = UDim2.new(1,-16,1,-120)
		scroll.Position = UDim2.new(0,8,0,120)
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
