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


if game.GameId == 5170973975 then
	local function ClonedService(name)
		local Service = game.GetService;
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
