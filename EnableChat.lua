local __lt = { cr = type(cloneref) == "function" and cloneref or nil };
function __lt.cv(value)
	if __lt.cr and typeof(value) == "Instance" then
		local ok, cloned = pcall(__lt.cr, value);
		if ok and cloned ~= nil then
			return cloned;
		end;
	end;
	return value;
end;
function __lt.cs(name, refFn)
	if type(refFn) ~= "function" then
		return game:GetService(name);
	end;
	local ok, ref = pcall(function()
		return refFn(game:GetService(name));
	end);
	if ok and ref ~= nil then
		return ref;
	end;
	return game:GetService(name);
end;
function __lt.ig(method)
	return method == "FindFirstChild"
		or method == "WaitForChild"
		or method == "FindFirstChildOfClass"
		or method == "FindFirstChildWhichIsA"
		or method == "FindFirstAncestor"
		or method == "FindFirstAncestorOfClass"
		or method == "FindFirstAncestorWhichIsA"
		or method == "GetChildren"
		or method == "GetDescendants"
		or method == "QueryDescendants";
end;
function __lt.cm(name, method, ...)
	local service = __lt.ig(method)
		and __lt.cs(name, __lt.cr)
		or game:GetService(name);
	local fn = service[method];
	if type(fn) ~= "function" then
		error(string.format("Service method %s.%s is not callable", tostring(name), tostring(method)));
	end;
	return fn(service, ...);
end;


pcall(function()
	local function ClonedService(name)
		local Service = game.GetService;
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
