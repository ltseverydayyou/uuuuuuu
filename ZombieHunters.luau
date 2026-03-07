local __lt_oldcloneref = type(cloneref) == "function" and cloneref or nil;
local function __lt_clone_service_value(value)
	if __lt_oldcloneref and typeof(value) == "Instance" then
		local ok, cloned = pcall(__lt_oldcloneref, value);
		if ok and cloned ~= nil then
			return cloned;
		end;
	end;
	return value;
end;
local function __lt_clone_service(name, refFn)
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
local function __lt_call_service_method(name, method, ...)
	local service = game:GetService(name);
	local fn = service[method];
	if type(fn) ~= "function" then
		error(string.format("Service method %s.%s is not callable", tostring(name), tostring(method)));
	end;
	return fn(service, ...);
end;


if game.GameId == 5170973975 then
	local function ClonedService(name)
		local Service = game.GetService;
		local Reference = cloneref or function(reference)
			return reference;
		end;
		return __lt_clone_service(name, Reference);
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
						Owner = (__lt_clone_service("Players", cloneref)).LocalPlayer,
						TargetHead = false,
						Character = (__lt_clone_service("Players", cloneref)).LocalPlayer.Character,
						Hit = v.Head,
						Target = v,
						position = Vector3.new(5.695760726928711, 24.54859733581543, -18.57601547241211),
						normal = Vector3.new(-0.012950442731380463, -0.3850027620792389, 0.9228245615959167),
						Damage = 99
					}
				};
				(__lt_clone_service("ReplicatedStorage", cloneref)).Remote.CastRemote:FireServer(unpack(args));
			end;
			for _, j in pairs((ClonedService("Workspace")).Temp_Item:GetChildren()) do
				spawn(function()
					fireproximityprompt(j.Base.Attachment.ProximityPrompt);
				end);
			end;
		end);
	end;
end;
