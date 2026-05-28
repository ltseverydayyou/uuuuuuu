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
	{ "Selection", "Size", UDim2.new(1, -6, 1, -5) },
	{ "Selection", "Position", UDim2.new(0, 3, 0, 3) },

	{ "Widget", "MinimumWidth", 32, "Deselected" },
	{ "Widget", "MinimumHeight", 32, "Deselected" },
	{ "Widget", "BorderSize", 0, "Deselected" },
	{ "IconCorners", "CornerRadius", UDim.new(0, 9), "Deselected" },
	{ "IconButton", "BackgroundTransparency", 0.5, "Deselected" },
	{ "IconLabel", "TextSize", 14, "Deselected" },
	{ "Dropdown", "BackgroundTransparency", 0.5, "Deselected" },
	{ "Notice", "Position", UDim2.new(1, -12, 0, -3), "Deselected" },
	{ "Notice", "Size", UDim2.new(0, 15, 0, 15), "Deselected" },
	{ "NoticeLabel", "TextSize", 11, "Deselected" },

	{ "IconSpot", "BackgroundColor3", Color3.fromRGB(0, 0, 0), "Selected" },
	{ "IconSpot", "BackgroundTransparency", 0.702, "Selected" },
	{ "IconSpotGradient", "Enabled", false, "Selected" },
	{ "IconOverlay", "BackgroundTransparency", 0.97, "Selected" },
}