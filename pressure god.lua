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

if (getgenv()).PressureBallsLoaded then
	return;
end;
pcall(function()
	(getgenv()).PressureBallsLoaded = true;
end);
local function ClonedService(name)
	local Service = function(_, serviceName) return __lt.gs(serviceName); end;
	local Reference = cloneref or function(reference)
		return reference;
	end;
	return __lt.cs(name, Reference);
end;
local ScreenGui = Instance.new("ScreenGui");
local ttLabel = Instance.new("TextButton");
local UICorner = Instance.new("UICorner");
local plrUI = (ClonedService("Players")).LocalPlayer:WaitForChild("PlayerGui");
local isRan = false;
local function protectUI(sGui)
	if sGui:IsA("ScreenGui") then
		sGui.ZIndexBehavior = Enum.ZIndexBehavior.Global;
		sGui.DisplayOrder = 999999999;
		sGui.ResetOnSpawn = false;
		sGui.IgnoreGuiInset = true;
	end;
	local cGUI = ClonedService("CoreGui");
	local lPlr = (ClonedService("Players")).LocalPlayer;
	local function NAProtection(inst, var)
		if inst then
			if var then
				inst[var] = "\000";
				inst.Archivable = false;
			else
				inst.Name = "\000";
				inst.Archivable = false;
			end;
		end;
	end;
	if gethui then
		NAProtection(sGui);
		sGui.Parent = gethui();
		return sGui;
	elseif cGUI and __lt.cm("CoreGui", "FindFirstChild", "RobloxGui") then
		NAProtection(sGui);
		sGui.Parent = __lt.cm("CoreGui", "FindFirstChild", "RobloxGui");
		return sGui;
	elseif cGUI then
		NAProtection(sGui);
		sGui.Parent = cGUI;
		return sGui;
	elseif lPlr and lPlr:FindFirstChildWhichIsA("PlayerGui") then
		NAProtection(sGui);
		sGui.Parent = lPlr:FindFirstChildWhichIsA("PlayerGui");
		sGui.ResetOnSpawn = false;
		return sGui;
	else
		return nil;
	end;
end;
protectUI(ScreenGui);
ttLabel.Name = "\000";
ttLabel.Parent = ScreenGui;
ttLabel.BackgroundColor3 = Color3.fromRGB(4, 4, 4);
ttLabel.BackgroundTransparency = 1;
ttLabel.AnchorPoint = Vector2.new(0.5, 0.5);
ttLabel.Position = UDim2.new(0.5, 0, 0.05, 0);
ttLabel.Size = UDim2.new(0, 32, 0, 33);
ttLabel.Font = Enum.Font.SourceSansBold;
ttLabel.Text = "God Mode (click)";
ttLabel.TextColor3 = Color3.fromRGB(255, 255, 255);
ttLabel.TextSize = 20;
ttLabel.TextWrapped = true;
ttLabel.ZIndex = 9999;
UICorner.CornerRadius = UDim.new(1, 0);
UICorner.Parent = ttLabel;
local function draggable(frame)
	frame.Active = true;
	frame.Draggable = true;
end;
local function removeKillables(eye)
	if eye.Parent == (ClonedService("Workspace")):FindFirstChild("deathModel") then
		return;
	end;
	local lowerName = eye.Name:lower();
	if lowerName == "eyes" or lowerName == "eye" or lowerName == "damageparts" or lowerName == "damagepart" or lowerName == "pandemonium" and eye:IsA("BasePart") or lowerName == "monsterlocker" or lowerName == "tricksterroom" then
		task.defer(function()
			eye:Destroy();
		end);
	end;
end;
local function perform()
	local oldPivot = (ClonedService("Players")).LocalPlayer.Character:GetPivot();
	local enterFunction = nil;
	for _, v in ipairs((ClonedService("Workspace")):QueryDescendants("Instance")) do
		if v.Name:lower() == "locker" and (v:IsA("Model") or v:IsA("BasePart")) then
			local success, errorMsg = pcall(function()
				for _, rem in ipairs(v:QueryDescendants("Instance")) do
					if rem.Name:lower() == "enter" and rem:IsA("RemoteFunction") then
						enterFunction = rem;
					end;
				end;
				if enterFunction then
					for i = 1, 5 do
						(ClonedService("Players")).LocalPlayer.Character:PivotTo(v:GetPivot());
						enterFunction:InvokeServer("true");
						task.wait(0.1);
					end;
				end;
			end);
			if not success then
				warn("Error invoking Remote: " .. errorMsg);
			end;
			(ClonedService("Players")).LocalPlayer.Character:PivotTo(oldPivot);
			if enterFunction then
				break;
			end;
		end;
	end;
	task.wait(0.5);
	local success, errorMsg = pcall(function()
		((ClonedService("Players")).LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")).WalkSpeed = 20;
	end);
	if not success then
		warn("No humanoid");
	end;
	local eBorder = plrUI:FindFirstChild("EntityBorder", true);
	if eBorder then
		(eBorder:GetPropertyChangedSignal("Visible")):Connect(function()
			if eBorder.Visible then
				eBorder.Visible = false;
			end;
		end);
	end;
	for _, g in ipairs((ClonedService("Workspace")):QueryDescendants("Instance")) do
		removeKillables(g);
	end;
	if not isRan then
		isRan = true;
		(ClonedService("Workspace")).DescendantAdded:Connect(removeKillables);
	end;
end;
local function initializeUI()
	local txtlabel = ttLabel;
	txtlabel.Size = UDim2.new(0, 32, 0, 33);
	txtlabel.BackgroundTransparency = 0.14;
	local textWidth = ((ClonedService("TextService")):GetTextSize(txtlabel.Text, txtlabel.TextSize, txtlabel.Font, Vector2.new(math.huge, math.huge))).X;
	local newSize = UDim2.new(0, textWidth + 69, 0, 33);
	txtlabel:TweenSize(newSize, "Out", "Quint", 1, true);
	txtlabel.MouseButton1Click:Connect(function()
		spawn(perform);
	end);
	draggable(txtlabel);
end;
(coroutine.wrap(initializeUI))();
