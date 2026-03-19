local __lt = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {};
	local sharedEnv = rawget(_G, "shared");
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil);
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver");
		if type(cached) == "table" then
			return cached;
		end;
	end;
	local loader = loadstring or load;
	if type(loader) ~= "function" then
		error("Service resolver loader unavailable");
	end;
	local resolver = loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau");
	if type(resolver) ~= "function" then
		error("Service resolver failed to compile");
	end;
	local loaded = resolver();
	if type(loaded) ~= "table" then
		error("Service resolver failed to load");
	end;
	if cacheHost then
		cacheHost.__lt_service_resolver = loaded;
	end;
	return loaded;
end)();

pcall(function()
	local function ClonedService(name)
		local Service = function(_, serviceName) return __lt.gs(serviceName); end;
		local Reference = cloneref or function(reference)
			return reference;
		end;
		return __lt.cs(name, Reference);
	end;
	local TextChatService = ClonedService("TextChatService");
	local Players = ClonedService("Players");
	local LocalPlayer = Players.LocalPlayer;
	local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui");
	local chatWindowConfiguration = __lt.cm("TextChatService", "FindFirstChildOfClass", "ChatWindowConfiguration");
	local chatBarConfiguration = __lt.cm("TextChatService", "FindFirstChildOfClass", "ChatBarConfiguration");
	if chatWindowConfiguration then
		chatWindowConfiguration.Enabled = true;
	end;
	if chatBarConfiguration then
		chatBarConfiguration.Enabled = true;
	end;
	local chatFrame = PlayerGui.Chat and PlayerGui.Chat:FindFirstChild("Frame");
	if chatFrame then
		local chatChannelParentFrame = chatFrame:FindFirstChild("ChatChannelParentFrame");
		local chatBarParentFrame = chatFrame:FindFirstChild("ChatBarParentFrame");
		if chatChannelParentFrame and chatBarParentFrame then
			chatChannelParentFrame.Visible = true;
			chatBarParentFrame.Position = chatChannelParentFrame.Position + UDim2.new(0, 0, chatChannelParentFrame.Size.Y.Scale, chatChannelParentFrame.Size.Y.Offset);
		end;
	end;
end);
