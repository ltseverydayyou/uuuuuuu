local __lt = {
	cr = type(cloneref) == "function" and cloneref or nil;
	svc = {
		cache = {};
		fallback = {};
		invalid = {};
	};
};
function __lt.sv(value)
	return typeof(value) == "Instance";
end;
function __lt.fs(name)
	local ok, service = pcall(function()
		return game:FindService(name);
	end);
	if ok and __lt.sv(service) then
		return service;
	end;
	return nil;
end;
function __lt.ns(name)
	local ok, service = pcall(Instance.new, name);
	if ok and __lt.sv(service) then
		return service;
	end;
	return nil;
end;
function __lt.gs(name)
	local cached = __lt.svc.cache[name];
	local isFallback = __lt.svc.fallback[name] == true;
	if __lt.sv(cached) and not isFallback then
		return cached;
	end;
	local service = __lt.fs(name);
	if __lt.sv(service) then
		__lt.svc.invalid[name] = nil;
		__lt.svc.cache[name] = service;
		__lt.svc.fallback[name] = nil;
		return service;
	end;
	if __lt.sv(cached) and isFallback then
		return cached;
	end;
	if __lt.svc.invalid[name] then
		return nil;
	end;
	service = __lt.ns(name);
	if __lt.sv(service) then
		__lt.svc.cache[name] = service;
		__lt.svc.fallback[name] = true;
		return service;
	end;
	__lt.svc.invalid[name] = true;
	return nil;
end;
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
		return __lt.gs(name);
	end;
	local ok, ref = pcall(function()
		return refFn(game:FindService(name));
	end);
	if ok and __lt.sv(ref) then
		return ref;
	end;
	local service = __lt.fs(name);
	if __lt.sv(service) then
		return service;
	end;
	if __lt.svc.invalid[name] then
		return nil;
	end;
	local fallbackOk, fallbackRef = pcall(function()
		return refFn(Instance.new(name));
	end);
	if fallbackOk and __lt.sv(fallbackRef) then
		return fallbackRef;
	end;
	service = __lt.ns(name);
	if __lt.sv(service) then
		return service;
	end;
	__lt.svc.invalid[name] = true;
	return nil;
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
	local service = __lt.cs(name, __lt.cr);
	if not __lt.sv(service) then
		error(string.format("Service %s could not be resolved", tostring(name)));
	end;
	local fn = service[method];
	if type(fn) ~= "function" then
		error(string.format("Service method %s.%s is not callable", tostring(name), tostring(method)));
	end;
	return fn(service, ...);
end;

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
