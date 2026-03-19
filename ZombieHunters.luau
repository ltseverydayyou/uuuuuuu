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

if game.GameId == 5170973975 then
	local function ClonedService(name)
		local Service = function(_, serviceName) return __lt.gs(serviceName); end;
		local Reference = cloneref or function(reference)
			return reference;
		end;
		return __lt.cs(name, Reference);
	end;
	repeat
		wait();
	until (ClonedService("Players")).LocalPlayer.PlayerGui.AreaGui.Enabled == true;
	(getgenv()).zombieslol = not (getgenv()).zombieslol;
	while (getgenv()).zombieslol and task.wait() do
		pcall(function()
			for i, v in pairs((ClonedService("Workspace")).Stage_Monster:GetChildren()) do
				local args = {
					[1] = {
						CF = CFrame.new(4.875078201293945, 24.025789260864258, 11.118204116821289) * CFrame.Angles(0.01760457269847393, (-0.02762647345662117), 0.00048634063568897545),
						Part = v.Head,
						Owner = (__lt.cs("Players", cloneref)).LocalPlayer,
						TargetHead = false,
						Character = (__lt.cs("Players", cloneref)).LocalPlayer.Character,
						Hit = v.Head,
						Target = v,
						position = Vector3.new(5.695760726928711, 24.54859733581543, -18.57601547241211),
						normal = Vector3.new(-0.012950442731380463, -0.3850027620792389, 0.9228245615959167),
						Damage = 99
					}
				};
				(__lt.cs("ReplicatedStorage", cloneref)).Remote.CastRemote:FireServer(unpack(args));
			end;
			for _, j in pairs((ClonedService("Workspace")).Temp_Item:GetChildren()) do
				spawn(function()
					fireproximityprompt(j.Base.Attachment.ProximityPrompt);
				end);
			end;
		end);
	end;
end;
