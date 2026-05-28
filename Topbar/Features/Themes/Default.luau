local __lt = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {}
	local sharedEnv = rawget(_G, "shared")
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil)
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver")
		if type(cached) == "table" then
			return cached
		end
	end
	local loader = loadstring or load
	if type(loader) ~= "function" then
		error("Service resolver loader unavailable")
	end
	local resolver =
		loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau")
	if type(resolver) ~= "function" then
		error("Service resolver failed to compile")
	end
	local loaded = resolver()
	if type(loaded) ~= "table" then
		error("Service resolver failed to load")
	end
	if cacheHost then
		cacheHost.__lt_service_resolver = loaded
	end
	return loaded
end)()

return {

	{ "IconCorners", "CornerRadius", UDim.new(1, 0) },
	{ "Selection", "RotationSpeed", 1 },
	{ "Selection", "Size", UDim2.new(1, 0, 1, 1) },
	{ "Selection", "Position", UDim2.new(0, 0, 0, 0) },
	{
		"SelectionGradient",
		"Color",
		ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(86, 86, 86)),
		}),
	},

	{ "IconImage", "Image", "", "Deselected" },
	{ "IconLabel", "Text", "", "Deselected" },
	{ "IconLabel", "Position", UDim2.fromOffset(0, 0), "Deselected" },
	{ "Widget", "DesiredWidth", 44, "Deselected" },
	{ "Widget", "MinimumWidth", 44, "Deselected" },
	{ "Widget", "MinimumHeight", 44, "Deselected" },
	{ "Widget", "BorderSize", 4, "Deselected" },
	{ "IconButton", "BackgroundColor3", Color3.fromRGB(18, 18, 21), "Deselected" },
	{ "IconButton", "BackgroundTransparency", 0.08, "Deselected" },
	{ "IconImageScale", "Value", 0.5, "Deselected" },
	{ "IconImageCorner", "CornerRadius", UDim.new(0, 0), "Deselected" },
	{ "IconImage", "ImageColor3", Color3.fromRGB(255, 255, 255), "Deselected" },
	{ "IconImage", "ImageTransparency", 0, "Deselected" },
	{ "IconImageRatio", "AspectRatio", 1, "Deselected" },
	{
		"IconLabel",
		"FontFace",
		Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		"Deselected",
	},
	{ "IconLabel", "TextSize", 16, "Deselected" },
	{ "IconSpot", "BackgroundTransparency", 1, "Deselected" },
	{ "IconOverlay", "BackgroundTransparency", 0.85, "Deselected" },
	{ "IconSpotGradient", "Enabled", false, "Deselected" },
	{ "IconGradient", "Enabled", false, "Deselected" },
	{ "ClickRegion", "Active", true, "Deselected" },
	{ "Menu", "Active", false, "Deselected" },
	{ "ContentsList", "HorizontalAlignment", Enum.HorizontalAlignment.Center, "Deselected" },
	{ "Dropdown", "BackgroundColor3", Color3.fromRGB(18, 18, 21), "Deselected" },
	{ "Dropdown", "BackgroundTransparency", 0.08, "Deselected" },
	{ "Dropdown", "MaxIcons", 4.5, "Deselected" },
	{ "Menu", "MaxIcons", 4, "Deselected" },
	{ "Notice", "Position", UDim2.new(1, -12, 0, -1), "Deselected" },
	{ "Notice", "Size", UDim2.new(0, 20, 0, 20), "Deselected" },
	{ "NoticeLabel", "TextSize", 13, "Deselected" },
	{ "PaddingLeft", "Size", UDim2.new(0, 9, 1, 0), "Deselected" },
	{ "PaddingRight", "Size", UDim2.new(0, 11, 1, 0), "Deselected" },

	{ "IconSpot", "BackgroundTransparency", 0.7, "Selected" },
	{ "IconSpot", "BackgroundColor3", Color3.fromRGB(255, 255, 255), "Selected" },
	{ "IconSpotGradient", "Enabled", true, "Selected" },
	{ "IconSpotGradient", "Rotation", 45, "Selected" },
	{
		"IconSpotGradient",
		"Color",
		ColorSequence.new(Color3.fromRGB(96, 98, 100), Color3.fromRGB(77, 78, 80)),
		"Selected",
	},
}