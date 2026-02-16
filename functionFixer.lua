local _env = getgenv and getgenv() or _G or {};
local RunService = game:GetService("RunService");
local HttpService = game:GetService("HttpService");
local Wait = task.wait;
local Delay = task.delay;
local Spawn = task.spawn;
local Insert = table.insert;
local Concat = table.concat;

local promptPartCache = setmetatable({}, {
	__mode = "k"
});

local glitchMarks = {
	"̶",
	"̷",
	"̸",
	"̹",
	"̺",
	"̻",
	"͓",
	"͔",
	"͘",
	"͜",
	"͞",
	"͟",
	"͢"
};

local function hb(n)
	for i = 1, n or 1 do
		RunService.Heartbeat:Wait();
	end;
end;

local isPoopSploit = identifyexecutor and ((identifyexecutor()):lower() == "solara" or (identifyexecutor()):lower() == "xeno") or typeof(firetouchinterest) ~= "function";

local rStringgg = function()
	if HttpService and HttpService.GenerateGUID then
		return HttpService:GenerateGUID(false);
	end;
	local length = math.random(10, 20);
	local result = {};
	for i = 1, length do
		local char = string.char(math.random(32, 126));
		Insert(result, char);
		if math.random() < 0.5 then
			local numGlitches = math.random(1, 4);
			for j = 1, numGlitches do
				Insert(result, glitchMarks[math.random(#glitchMarks)]);
			end;
		end;
	end;
	if math.random() < 0.3 then
		Insert(result, utf8.char(math.random(768, 879)));
	end;
	if math.random() < 0.1 then
		Insert(result, "\000");
	end;
	if math.random() < 0.1 then
		Insert(result, string.rep("43", math.random(5, 20)));
	end;
	if math.random() < 0.2 then
		Insert(result, utf8.char(8238));
	end;
	return Concat(result);
end;

local getPromptPart = function(pp)
	if not pp then
		return nil;
	end;
	local c = promptPartCache[pp];
	if c ~= nil then
		if c == false then
			return nil;
		end;
		return c;
	end;
	local parent = pp.Parent;
	local part;
	if parent then
		if parent:IsA("Attachment") then
			local p = parent.Parent;
			if p and p:IsA("BasePart") then
				part = p;
			end;
		elseif parent:IsA("BasePart") then
			part = parent;
		end;
	end;
	if not part then
		local model = pp:FindFirstAncestorWhichIsA("Model");
		if model then
			if model.PrimaryPart then
				part = model.PrimaryPart;
			else
				part = model:FindFirstChildWhichIsA("BasePart", true);
			end;
		end;
	end;
	if not part then
		part = pp:FindFirstAncestorWhichIsA("BasePart");
	end;
	promptPartCache[pp] = part or false;
	return part;
end;

if isPoopSploit then
	local function toOpts(o)
		if typeof(o) == "number" then
			return {
				hold = o
			};
		end;
		return typeof(o) == "table" and o or {};
	end;

	local state = setmetatable({}, {
		__mode = "k"
	});

	local proxyPart;

	local function snapshot(pp)
		return {
			E = pp.Enabled,
			H = pp.HoldDuration,
			R = pp.RequiresLineOfSight,
			D = pp.MaxActivationDistance,
			X = pp.Exclusivity
		};
	end;

	local function begin(pp, o)
		if not (pp and pp.Parent) then
			return false;
		end;
		local s = state[pp];
		if not s then
			s = snapshot(pp);
			s.ref = 0;
			s.inFlight = false;
			state[pp] = s;
		end;
		if s.inFlight then
			return false;
		end;
		s.inFlight = true;
		s.ref += 1;
		pp.HoldDuration = 0;
		if o.requireLoS ~= nil then
			pp.RequiresLineOfSight = o.requireLoS and true or false;
		elseif o.disableLoS ~= false then
			pp.RequiresLineOfSight = false;
		end;
		if o.distance ~= nil then
			pp.MaxActivationDistance = o.distance;
		elseif o.autoDistance ~= false then
			pp.MaxActivationDistance = 1000000000;
		end;
		if o.exclusivity ~= nil then
			pp.Exclusivity = o.exclusivity;
		else
			pp.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow;
		end;
		if o.forceEnable ~= false then
			pp.Enabled = true;
		end;
		return true;
	end;

	local function finish(pp)
		local s = state[pp];
		if not s then
			return;
		end;
		s.ref -= 1;
		s.inFlight = false;
		if s.ref <= 0 and pp and pp.Parent then
			pp.Enabled = s.E;
			pp.HoldDuration = s.H;
			pp.RequiresLineOfSight = s.R;
			pp.MaxActivationDistance = s.D;
			pp.Exclusivity = s.X;
			state[pp] = nil;
		elseif s.ref <= 0 then
			state[pp] = nil;
		end;
	end;

	local function fireOne(pp, o)
		if not begin(pp, o) then
			return;
		end;
		local restorePos;
		if o.relocate ~= false then
			local part = getPromptPart(pp);
			local cam = workspace.CurrentCamera;
			if part and part:IsA("BasePart") and cam then
				local camPos = cam.CFrame.Position;
				local look = cam.CFrame.LookVector;
				local dir = part.Position - camPos;
				if dir.Magnitude > 0 then
					local dot = dir.Unit:Dot(look);
					if dot < 0 then
						local dist = tonumber(o.relocateDistance) or 4;
						local downFactor = o.relocateDownFactor ~= nil and o.relocateDownFactor or 1.8;
						local target = camPos + look * dist + cam.CFrame.UpVector * (-dist) * downFactor;
						local useProxy = o.relocateProxy ~= false;
						if useProxy then
							if not proxyPart then
								local ok, p = pcall(function()
									local p = Instance.new("Part");
									p.Size = Vector3.new(0.2, 0.2, 0.2);
									p.Anchored = true;
									p.CanCollide = false;
									p.CanTouch = false;
									p.CanQuery = false;
									p.Transparency = 1;
									p.Name = rStringgg and rStringgg() or "\000";
									p.Parent = workspace;
									return p;
								end);
								if ok and p then
									proxyPart = p;
								end;
							end;
							if proxyPart then
								local origParent = pp.Parent;
								pp.Parent = proxyPart;
								proxyPart.CFrame = CFrame.new(target, target + look);
								restorePos = function()
									if pp then
										pp.Parent = origParent;
									end;
								end;
							end;
						end;
						if not restorePos then
							local origCF = part.CFrame;
							local origCollide = part.CanCollide;
							local origTouch = part.CanTouch;
							local origQuery = part.CanQuery;
							local origTrans = part.Transparency;
							local hasLTM, origLTM = pcall(function()
								return part.LocalTransparencyModifier;
							end);
							part.CFrame = CFrame.new(target, target + look);
							part.CanCollide = false;
							part.CanTouch = false;
							part.CanQuery = false;
							part.Transparency = o.relocateTransparency ~= nil and o.relocateTransparency or 1;
							if hasLTM then
								pcall(function()
									part.LocalTransparencyModifier = o.relocateTransparency ~= nil and o.relocateTransparency or 1;
								end);
							end;
							restorePos = function()
								if part and part.Parent then
									part.CFrame = origCF;
									part.CanCollide = origCollide;
									part.CanTouch = origTouch;
									part.CanQuery = origQuery;
									part.Transparency = origTrans;
									if hasLTM then
										pcall(function()
											part.LocalTransparencyModifier = origLTM;
										end);
									end;
								end;
							end;
						end;
					end;
				end;
			end;
		end;
		local ok, err = pcall(function()
			hb(1);
			pp:InputHoldBegin();
			local t = o.hold ~= nil and tonumber(o.hold) or 0;
			if t and t > 0 then
				Wait(t);
			else
				hb(1);
			end;
			pp:InputHoldEnd();
			hb(1);
		end);
		if restorePos then
			pcall(restorePos);
		end;
		finish(pp);
		if not ok then
			warn(("[fireproximityprompt] %s"):format(err));
		end;
	end;

	_env.fireproximityprompt = function(target, opts)
		local o = toOpts(opts);
		local list = {};
		if typeof(target) == "Instance" and target:IsA("ProximityPrompt") and target.Enabled then
			list[1] = target;
		elseif typeof(target) == "table" then
			for _, v in ipairs(target) do
				if typeof(v) == "Instance" and v:IsA("ProximityPrompt") and v.Enabled then
					Insert(list, v);
				end;
			end;
		else
			return false;
		end;
		local stagger = o.stagger ~= nil and math.max(0, o.stagger) or 0;
		if stagger <= 0 and #list > 1 then
			stagger = 0.02;
		end;
		for i, pp in ipairs(list) do
			local d = stagger * (i - 1);
			if d > 0 then
				Delay(d, function()
					fireOne(pp, o);
				end);
			else
				Spawn(fireOne, pp, o);
			end;
		end;
		return #list > 0;
	end;
end;

if isPoopSploit then
	local touchState = setmetatable({}, {
		__mode = "k"
	});

	local function snapshot(part)
		local vel, ang = Vector3.zero, Vector3.zero;
		pcall(function()
			vel = part.AssemblyLinearVelocity;
			ang = part.AssemblyAngularVelocity;
		end);
		local cg = nil;
		pcall(function()
			cg = part.CollisionGroupId;
		end);
		local anchored = nil;
		pcall(function()
			anchored = part.Anchored;
		end);
		local massless = nil;
		pcall(function()
			massless = part.Massless;
		end);
		return {
			CF = part.CFrame,
			VEL = vel,
			ANG = ang,
			CT = part.CanTouch,
			CQ = part.CanQuery,
			CC = part.CanCollide,
			CG = cg,
			AN = anchored,
			MS = massless
		};
	end;

	local function restore(part, snap)
		if not (snap and part and part.Parent) then
			return;
		end;
		pcall(function()
			part.CFrame = snap.CF;
			part.AssemblyLinearVelocity = snap.VEL;
			part.AssemblyAngularVelocity = snap.ANG;
			part.CanTouch = snap.CT;
			part.CanQuery = snap.CQ;
			part.CanCollide = snap.CC;
			if snap.AN ~= nil then
				part.Anchored = snap.AN;
			end;
			if snap.MS ~= nil then
				part.Massless = snap.MS;
			end;
			if snap.CG then
				part.CollisionGroupId = snap.CG;
			end;
		end);
	end;

	local function getRoot(p)
		if typeof(p) ~= "Instance" or (not p:IsA("BasePart")) then
			return nil;
		end;
		return p.AssemblyRootPart or p;
	end;

	_env.firetouchinterest = function(partA, partB, state)
		local handle = getRoot(partA);
		local target = getRoot(partB);
		if not handle or (not target) then
			return false;
		end;
		state = tonumber(state) or 0;
		state = state == 1 and 1 or 0;
		local st = touchState[target];
		if state == 0 then
			if not st then
				st = {
					ref = 0,
					handle = handle,
					handleCT = handle.CanTouch,
					snap = snapshot(target)
				};
				touchState[target] = st;
			end;
			st.ref += 1;
			if handle.CanTouch == false then
				handle.CanTouch = true;
			end;
			if target.CanTouch == false then
				target.CanTouch = true;
			end;
			if target.CanQuery == false then
				target.CanQuery = true;
			end;
			pcall(function()
				target.CanCollide = false;
			end);
			pcall(function()
				target.Massless = true;
			end);
			pcall(function()
				target.CollisionGroupId = handle.CollisionGroupId;
			end);
			pcall(function()
				target.AssemblyLinearVelocity = Vector3.zero;
				target.AssemblyAngularVelocity = Vector3.zero;
				target.CFrame = handle.CFrame;
			end);
			hb(1);
		else
			if st then
				restore(target, st.snap);
				if st.handle and st.handle.Parent and st.handleCT ~= nil then
					pcall(function()
						st.handle.CanTouch = st.handleCT;
					end);
				end;
				st.ref -= 1;
				if st.ref <= 0 then
					touchState[target] = nil;
				end;
			end;
			hb(1);
		end;
		return true;
	end;
end;