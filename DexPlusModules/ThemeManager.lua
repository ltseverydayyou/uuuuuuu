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
		window:Resize(300,160)
		ThemeManager.Window = window

		local apply = Instance.new("TextButton", window.GuiElems.Content)
		apply.Size = UDim2.new(1,-20,0,30)
		apply.Position = UDim2.new(0,10,0,10)
		apply.Text = "Reload Theme File"
		apply.TextColor3 = Color3.new(1,1,1)
		apply.BackgroundTransparency = 0.2
		apply.BackgroundColor3 = Settings.Theme.Button
		Lib.ButtonAnim(apply,{PressColor = Settings.Theme.ButtonPress})

		apply.MouseButton1Click:Connect(function()
			Main.LoadThemeSettings()
			Lib.RefreshTheme()
		end)

		local save = apply:Clone()
		save.Parent = window.GuiElems.Content
		save.Position = UDim2.new(0,10,0,50)
		save.Text = "Save Current Theme"
		save.MouseButton1Click:Connect(function()
			Main.SaveThemeSettings()
		end)

		local reset = apply:Clone()
		reset.Parent = window.GuiElems.Content
		reset.Position = UDim2.new(0,10,0,90)
		reset.Text = "Reset to Default"
		reset.MouseButton1Click:Connect(function()
			Main.ResetSettings()
			Main.SaveThemeSettings()
			Lib.RefreshTheme()
		end)
	end

	return ThemeManager
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
