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


local replicatedStorage = __lt.cs("ReplicatedStorage", cloneref);
local Reference = {};
Reference.objectName = "TopbarPlusReference_LTS";
function Reference.addToReplicatedStorage()
	local existingItem = __lt.cm("ReplicatedStorage", "FindFirstChild", Reference.objectName);
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
	local objectValue = __lt.cm("ReplicatedStorage", "FindFirstChild", Reference.objectName);
	if objectValue then
		return objectValue;
	end;
	return false;
end;
return Reference;
