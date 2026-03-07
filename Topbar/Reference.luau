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


local replicatedStorage = __lt_clone_service("ReplicatedStorage", cloneref);
local Reference = {};
Reference.objectName = "TopbarPlusReference_LTS";
function Reference.addToReplicatedStorage()
	local existingItem = __lt_call_service_method("ReplicatedStorage", "FindFirstChild", Reference.objectName);
	if existingItem then
		return false;
	end;
	local objectValue = Instance.new("ObjectValue");
	objectValue.Name = Reference.objectName;
	local parent = script.Parent;
	if typeof(parent) == "Instance" then
		objectValue.Value = parent;
	end;
	objectValue.Parent = replicatedStorage;
	return objectValue;
end;
function Reference.getObject()
	local objectValue = __lt_call_service_method("ReplicatedStorage", "FindFirstChild", Reference.objectName);
	if objectValue then
		return objectValue;
	end;
	return false;
end;
return Reference;
