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

local getgenv, getnamecallmethod, hookmetamethod, newcclosure, checkcaller, stringlower = getgenv, getnamecallmethod, hookmetamethod, newcclosure, checkcaller, string.lower;
local function ClonedService(name)
	local Service = function(_, serviceName) return __lt.gs(serviceName); end;
	local Reference = cloneref or function(reference)
		return reference;
	end;
	return __lt.cs(name, Reference);
end;
if (getgenv()).ED_AntiKick then
	return;
end;
local Players, StarterGui, OldNamecall = ClonedService("Players"), ClonedService("StarterGui");
(getgenv()).ED_AntiKick = {
	Enabled = true,
	SendNotifications = true,
	CheckCaller = true
};
OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
	if ((getgenv()).ED_AntiKick.CheckCaller and (not checkcaller()) or true) and stringlower(getnamecallmethod()) == "kick" and ED_AntiKick.Enabled then
		if (getgenv()).ED_AntiKick.SendNotifications then
			StarterGui:SetCore("SendNotification", {
				Title = "Exunys Developer",
				Text = "The script has successfully intercepted an attempted kick.",
				Icon = "rbxassetid://6238540373",
				Duration = 2
			});
		end;
		return nil;
	end;
	return OldNamecall(...);
end));
if (getgenv()).ED_AntiKick.SendNotifications then
	StarterGui:SetCore("SendNotification", {
		Title = "Exunys Developer",
		Text = "Anti-Kick script loaded!",
		Icon = "rbxassetid://6238537240",
		Duration = 3
	});
end;
