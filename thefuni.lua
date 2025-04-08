task.spawn(function()
	pcall(function()
		task.wait(math.random(65, 120))
		
		local Canvas = Instance.new("ScreenGui")
		Canvas.Name = "Canvas"
		Canvas.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		Canvas.ResetOnSpawn = false
		Canvas.IgnoreGuiInset = true
		Canvas.DisplayOrder = 100

		local UIScale = Instance.new("UIScale")
		UIScale.Parent = Canvas

		local function updateScale()
			local camera = workspace.CurrentCamera
			if camera then
				local viewport = camera.ViewportSize
				local designWidth, designHeight = 1920, 1080
				local scaleFactor = math.min(viewport.X / designWidth, viewport.Y / designHeight)
				UIScale.Scale = scaleFactor
			end
		end

		updateScale()
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

		local Background = Instance.new("ImageLabel")
		local Holder = Instance.new("Frame")
		local ByfronLogo = Instance.new("ImageLabel")
		local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		local RobloxLogo = Instance.new("ImageLabel")
		local UIAspectRatioConstraint_2 = Instance.new("UIAspectRatioConstraint")
		local TitleInfo = Instance.new("TextLabel")
		local DescriptionInfo = Instance.new("TextLabel")
		local TitleReason = Instance.new("TextLabel")
		local DescriptionReason = Instance.new("TextLabel")
		local TitleReason_2 = Instance.new("TextLabel")
		local DescriptionReason_2 = Instance.new("TextLabel")
		local TitleLoading = Instance.new("TextLabel")
		local HelpLink = Instance.new("TextLabel")

		Background.Name = "Background"
		Background.Parent = Canvas
		Background.AnchorPoint = Vector2.new(0.5, 0.5)
		Background.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
		Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Background.BorderSizePixel = 0
		Background.Position = UDim2.new(0.5, 0, 0.5, 0)
		Background.Size = UDim2.new(1.01999998, 0, 1.01999998, 0)
		Background.Image = "http://www.roblox.com/asset/?id=16725745473"
		Background.ScaleType = Enum.ScaleType.Slice

		Holder.Name = "Holder"
		Holder.Parent = Background
		Holder.BackgroundColor3 = Color3.fromRGB(9, 9, 9)
		Holder.BackgroundTransparency = 0.050
		Holder.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Holder.BorderSizePixel = 0
		Holder.Size = UDim2.new(0.467999995, 0, 1, 0)

		ByfronLogo.Name = "Byfron - Logo"
		ByfronLogo.Parent = Holder
		ByfronLogo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ByfronLogo.BackgroundTransparency = 1.000
		ByfronLogo.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ByfronLogo.BorderSizePixel = 0
		ByfronLogo.Position = UDim2.new(0.384972781, 0, 0.0298051033, 0)
		ByfronLogo.Size = UDim2.new(0.228287876, 0, 0.0962187126, 0)
		ByfronLogo.Image = "http://www.roblox.com/asset/?id=16729985705"

		UIAspectRatioConstraint.Parent = ByfronLogo
		UIAspectRatioConstraint.AspectRatio = 2.142

		RobloxLogo.Name = "Roblox - Logo"
		RobloxLogo.Parent = Holder
		RobloxLogo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		RobloxLogo.BackgroundTransparency = 1.000
		RobloxLogo.BorderColor3 = Color3.fromRGB(0, 0, 0)
		RobloxLogo.BorderSizePixel = 0
		RobloxLogo.Position = UDim2.new(0.396267831, 0, 0.921765745, 0)
		RobloxLogo.Size = UDim2.new(0.205697745, 0, 0.050733842, 0)
		RobloxLogo.Image = "rbxassetid://13851601289"

		UIAspectRatioConstraint_2.Parent = RobloxLogo
		UIAspectRatioConstraint_2.AspectRatio = 4.063

		TitleInfo.Name = "Title - Info"
		TitleInfo.Parent = Holder
		TitleInfo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TitleInfo.BackgroundTransparency = 1.000
		TitleInfo.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TitleInfo.BorderSizePixel = 0
		TitleInfo.Position = UDim2.new(0.0396083519, 0, 0.253472209, 0)
		TitleInfo.Size = UDim2.new(0.924179912, 0, 0.0347222425, 0)
		TitleInfo.Font = Enum.Font.GothamBold
		TitleInfo.Text = "· What is Byfron?"
		TitleInfo.TextColor3 = Color3.fromRGB(230, 230, 230)
		TitleInfo.TextScaled = true
		TitleInfo.TextSize = 13.000
		TitleInfo.TextWrapped = true
		TitleInfo.TextXAlignment = Enum.TextXAlignment.Left

		DescriptionInfo.Name = "Description - Info"
		DescriptionInfo.Parent = Holder
		DescriptionInfo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		DescriptionInfo.BackgroundTransparency = 1
		DescriptionInfo.BorderColor3 = Color3.fromRGB(0, 0, 0)
		DescriptionInfo.BorderSizePixel = 0
		DescriptionInfo.Position = UDim2.new(0.0624849685, 0, 0.288194448, 0)
		DescriptionInfo.Size = UDim2.new(0.893371046, 0, 0.187499985, 0)
		DescriptionInfo.Font = Enum.Font.GothamMedium
		DescriptionInfo.Text = "As passionate gamers, we started Byfron <font color=\"rgb(133, 230, 116)\">as a team of engineers and hackers</font> with an ambitious goal to improve the lives of gamers through software security. We are proud of what we have accomplished. <font color=\"rgb(133, 230, 116)\">Hyperion is a leading software</font> solution aimed at tackling the difficult challenges associated with <font color=\"rgb(133, 230, 116)\">anti-cheat security</font>."
		DescriptionInfo.TextColor3 = Color3.fromRGB(210, 210, 210)
		DescriptionInfo.TextScaled = true
		DescriptionInfo.TextSize = 12.000
		DescriptionInfo.TextWrapped = true
		DescriptionInfo.TextXAlignment = Enum.TextXAlignment.Left
		DescriptionInfo.TextYAlignment = Enum.TextYAlignment.Top
		DescriptionInfo.RichText = true
		
		TitleReason.Name = "Title - Reason"
		TitleReason.Parent = Holder
		TitleReason.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TitleReason.BackgroundTransparency = 1.000
		TitleReason.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TitleReason.BorderSizePixel = 0
		TitleReason.Position = UDim2.new(0.0396083631, 0, 0.488247633, 0)
		TitleReason.Size = UDim2.new(0.924179912, 0, 0.0347222164, 0)
		TitleReason.Font = Enum.Font.GothamBold
		TitleReason.Text = "· Why is this screen being shown?"
		TitleReason.TextColor3 = Color3.fromRGB(230, 230, 230)
		TitleReason.TextScaled = true
		TitleReason.TextSize = 13.000
		TitleReason.TextWrapped = true
		TitleReason.TextXAlignment = Enum.TextXAlignment.Left

		DescriptionReason.Name = "Description - Reason"
		DescriptionReason.Parent = Holder
		DescriptionReason.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		DescriptionReason.BackgroundTransparency = 1
		DescriptionReason.BorderColor3 = Color3.fromRGB(0, 0, 0)
		DescriptionReason.BorderSizePixel = 0
		DescriptionReason.Position = UDim2.new(0.0624849312, 0, 0.522969902, 0)
		DescriptionReason.Size = UDim2.new(0.89891988, 0, 0.0883596614, 0)
		DescriptionReason.Font = Enum.Font.GothamMedium
		DescriptionReason.Text = "You have been detected by our anti-tamper security software for <font color=\"rgb(133, 230, 116)\">the usage of third party applications</font> that modify the Roblox client."
		DescriptionReason.TextColor3 = Color3.fromRGB(210, 210, 210)
		DescriptionReason.TextScaled = true
		DescriptionReason.TextSize = 12.000
		DescriptionReason.TextWrapped = true
		DescriptionReason.TextXAlignment = Enum.TextXAlignment.Left
		DescriptionReason.TextYAlignment = Enum.TextYAlignment.Top
		DescriptionReason.RichText = true
		
		TitleReason_2.Name = "Title - Reason"
		TitleReason_2.Parent = Holder
		TitleReason_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TitleReason_2.BackgroundTransparency = 1.000
		TitleReason_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TitleReason_2.BorderSizePixel = 0
		TitleReason_2.Position = UDim2.new(0.0396083631, 0, 0.630499542, 0)
		TitleReason_2.Size = UDim2.new(0.924179912, 0, 0.0347222239, 0)
		TitleReason_2.Font = Enum.Font.GothamBold
		TitleReason_2.Text = "· How do i hide this screen?"
		TitleReason_2.TextColor3 = Color3.fromRGB(230, 230, 230)
		TitleReason_2.TextScaled = true
		TitleReason_2.TextSize = 13.000
		TitleReason_2.TextWrapped = true
		TitleReason_2.TextXAlignment = Enum.TextXAlignment.Left

		DescriptionReason_2.Name = "Description - Reason"
		DescriptionReason_2.Parent = Holder
		DescriptionReason_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		DescriptionReason_2.BackgroundTransparency = 1
		DescriptionReason_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
		DescriptionReason_2.BorderSizePixel = 0
		DescriptionReason_2.Position = UDim2.new(0.062485043, 0, 0.665221751, 0)
		DescriptionReason_2.Size = UDim2.new(0.89891988, 0, 0.0793514848, 0)
		DescriptionReason_2.Font = Enum.Font.GothamMedium
		DescriptionReason_2.Text = "The only way to hide this screen is to uninstall the third party application you have on your device, and re-launching the Roblox Client."
		DescriptionReason_2.TextColor3 = Color3.fromRGB(210, 210, 210)
		DescriptionReason_2.TextScaled = true
		DescriptionReason_2.TextSize = 12.000
		DescriptionReason_2.TextWrapped = true
		DescriptionReason_2.TextXAlignment = Enum.TextXAlignment.Left
		DescriptionReason_2.TextYAlignment = Enum.TextYAlignment.Top
		DescriptionReason_2.RichText = true
		
		TitleLoading.Name = "Title - Loading"
		TitleLoading.Parent = Holder
		TitleLoading.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TitleLoading.BackgroundTransparency = 1.000
		TitleLoading.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TitleLoading.BorderSizePixel = 0
		TitleLoading.Position = UDim2.new(0.0396083519, 0, 0.164930537, 0)
		TitleLoading.Size = UDim2.new(0.924179912, 0, 0.038194485, 0)
		TitleLoading.Font = Enum.Font.GothamBold
		TitleLoading.Text = "Please read."
		TitleLoading.TextColor3 = Color3.fromRGB(250, 255, 146)
		TitleLoading.TextScaled = true
		TitleLoading.TextSize = 14.000
		TitleLoading.TextWrapped = true
		TitleLoading.TextXAlignment = Enum.TextXAlignment.Left

		HelpLink.Name = "Help - Link"
		HelpLink.Parent = Background
		HelpLink.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		HelpLink.BackgroundTransparency = 1
		HelpLink.BorderColor3 = Color3.fromRGB(0, 0, 0)
		HelpLink.BorderSizePixel = 0
		HelpLink.Position = UDim2.new(0.468000025, 0, 0.96543473, 0)
		HelpLink.Size = UDim2.new(0.522000015, 0, 0.0242999997, 0)
		HelpLink.Font = Enum.Font.GothamMedium
		HelpLink.Text = "https://devforum.roblox.com/t/hyperion-related-solutions/2322367"
		HelpLink.TextColor3 = Color3.fromRGB(0, 128, 255)
		HelpLink.TextScaled = true
		HelpLink.TextSize = 12.000
		HelpLink.TextTransparency = 0.500
		HelpLink.TextWrapped = true
		HelpLink.TextYAlignment = Enum.TextYAlignment.Top

		local Players = game:GetService("Players")
		
		Canvas:GetPropertyChangedSignal("Enabled"):Connect(function()
			Canvas.Enabled = true
		end)

		Background:GetPropertyChangedSignal("Visible"):Connect(function()
			Background.Visible = true
		end)

		local Success, Result = pcall(function()
			Canvas.Parent = game:GetService("CoreGui")
		end)

		if not Success then
			Canvas.Parent = Players.LocalPlayer.PlayerGui
		end
		
		task.wait(math.random(5,50))
		Players.LocalPlayer:Kick()
	end)
end)