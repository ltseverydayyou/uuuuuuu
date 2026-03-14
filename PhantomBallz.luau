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

if (getgenv()).__na_aex then
	return;
end;
(getgenv()).__na_aex = true;
if game.GameId ~= 4538598064 then
	return;
end;
local Plrs = __lt.cs("Players", cloneref);
local RS = __lt.cs("RunService", cloneref);
local SS = __lt.cs("SoundService", cloneref);
local TS = __lt.cs("TweenService", cloneref);
local RSrv = __lt.cs("ReplicatedStorage", cloneref);
local WS = workspace;
local UIS = __lt.cs("UserInputService", cloneref);
local Net = (require(RSrv.TS.Network.Network)).Network;
local Def = (require(RSrv.TS.Abilities.DeflectAbility)).DeflectAbility;
local PNotif = __lt.cm("ReplicatedStorage", "WaitForChild", "PromptNotification");
task.spawn(function()
	PNotif:Fire("super scuffed autoparry loaded 💀💀💀", true);
end);
local oAvail;
oAvail = hookfunction(Def.IsAvailable, function(self, ...)
	return true;
end);
local oSend;
oSend = hookfunction(Net.CSendEvent, function(self, router, evt, ...)
	if router == 46848415795802784000000000000000000000000000000000000000000000000000000000000 then
		return oSend(self, router, 29338138590583890000000000000000000000000000000000000000000000000000000000000, ...);
	end;
	return oSend(self, router, evt, ...);
end);
local function sendParry()
	if not Net then
		return;
	end;
	Net:CSendEvent(46848415795802784000000000000000000000000000000000000000000000000000000000000, 6846744283873508500000000000000000000000000000000000000000000000000000000000);
end;
do
	local mas = __lt.cm("SoundService", "FindFirstChild", "Master");
	local mus = mas and mas:FindFirstChild("Music");
	local gam = mus and mus:FindFirstChild("Game");
	local lob = mus and mus:FindFirstChild("Lobby");
	local main = lob and lob:FindFirstChild("Main");
	if mus and gam and main then
		for _, v in ipairs(gam:GetChildren()) do
			if v:IsA("Sound") then
				v:Destroy();
			end;
		end;
		local ids = {
			"rbxassetid://15448175657",
			"rbxassetid://15448189246",
			"rbxassetid://15492387259",
			"rbxassetid://15492384385",
			"rbxassetid://15619382428",
			"rbxassetid://15619385373",
			"rbxassetid://15933457903"
		};
		local spd = {
			1,
			1.1,
			1,
			1,
			1,
			1,
			1
		};
		local MAXV, FADE = 1, 0.35;
		local vars = table.create(7);
		for i = 1, 7 do
			local s = Instance.new("Sound");
			s.Name = "Variant" .. i;
			s.SoundId = ids[i];
			s.SoundGroup = mus;
			s.Looped = false;
			s.RollOffMode = Enum.RollOffMode.InverseTapered;
			s.PlaybackSpeed = spd[i];
			pcall(function()
				s.Pitch = spd[i];
			end);
			s.Volume = 0;
			s.Parent = gam;
			vars[i] = s;
		end;
		local function isPlay(s)
			local ok, v = pcall(function()
				return s.IsPlaying;
			end);
			if ok then
				return v;
			end;
			ok, v = pcall(function()
				return s.Playing;
			end);
			return ok and v or false;
		end;
		local tws = {};
		local function twVol(s, v, t)
			if not (s and s.Parent) then
				return;
			end;
			if tws[s] then
				pcall(function()
					tws[s]:Cancel();
				end);
			end;
			local ok, tw = pcall(function()
				return __lt.cm("TweenService", "Create", s, TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Volume = v
				});
			end);
			if ok and tw then
				tws[s] = tw;
				tw:Play();
			else
				pcall(function()
					s.Volume = v;
				end);
			end;
		end;
		local function stopFade(s, t)
			if not (s and s.Parent) then
				return;
			end;
			twVol(s, 0, t);
			task.delay(t, function()
				if not (s and s.Parent) then
					return;
				end;
				pcall(function()
					s:Stop();
				end);
				pcall(function()
					s.Volume = 0;
				end);
			end);
		end;
		local rng = Random.new();
		local function pickNext(lastI)
			if #vars <= 1 then
				return 1;
			end;
			local i;
			repeat
				i = rng:NextInteger(1, #vars);
			until i ~= lastI;
			return i;
		end;
		local cur, curI, con, tok = nil, nil, nil, 0;
		local function playRand()
			tok += 1;
			local my = tok;
			if con then
				con:Disconnect();
				con = nil;
			end;
			local i = pickNext(curI);
			curI = i;
			local s = vars[i];
			cur = s;
			if not (s and s.Parent) then
				cur = nil;
				return;
			end;
			pcall(function()
				s:Stop();
			end);
			pcall(function()
				s.TimePosition = 0;
			end);
			pcall(function()
				s.Volume = 0;
			end);
			pcall(function()
				s:Play();
			end);
			twVol(s, MAXV, 0.45);
			con = s.Ended:Connect(function()
				if tok ~= my then
					return;
				end;
				if main.Parent and (not isPlay(main)) then
					playRand();
				else
					cur = nil;
				end;
			end);
		end;
		task.spawn(function()
			while main.Parent do
				if isPlay(main) then
					tok += 1;
					if con then
						con:Disconnect();
						con = nil;
					end;
					if cur then
						local s = cur;
						cur = nil;
						stopFade(s, FADE);
					end;
					while main.Parent and isPlay(main) do
						task.wait(0.1);
					end;
				else
					if not (cur and cur.Parent and isPlay(cur)) then
						playRand();
					end;
					task.wait(0.05);
				end;
			end;
			tok += 1;
			if con then
				con:Disconnect();
			end;
			if cur then
				stopFade(cur, 0.25);
			end;
		end);
	end;
end;
do
	local gi;
	do
		local ok, mod = pcall(function()
			return require((__lt.cm("ReplicatedStorage", "WaitForChild", "TS")):WaitForChild("GameInfo"));
		end);
		if ok and mod and mod.GameInfo then
			gi = mod.GameInfo;
		end;
	end;
	local br;
	do
		local ok, mod = pcall(function()
			return require(((__lt.cm("ReplicatedStorage", "WaitForChild", "TS")):WaitForChild("BallReplicator")):WaitForChild("BallReplicator"));
		end);
		if ok and mod and mod.BallReplicator then
			br = mod.BallReplicator;
		end;
	end;
	local lp = Plrs.LocalPlayer;
	local function getBall()
		if gi and gi.BallModel and gi.BallModel.Parent then
			return gi.BallModel;
		end;
		return WS:FindFirstChild("GameBall", true) or WS:FindFirstChild("GameBall");
	end;
	local function tgtOn()
		local ch = lp.Character;
		if ch and ch:FindFirstChild("Highlight") then
			return true;
		end;
		local t = WS:GetAttribute("GameBallTarget");
		if t == lp.UserId then
			return true;
		end;
		if br and br.syncData and br.syncData.HighlightTargetPlayerID == lp.UserId then
			return true;
		end;
		return false;
	end;
	local spamOn = false;
	local spamConn;
	local mobIcon;
	local syncingIcon = false;
	local function syncTopbarIcon()
		if not mobIcon then
			return;
		end;
		syncingIcon = true;
		mobIcon:setLabel(spamOn and "Parry spam: ON" or "Parry spam: OFF");
		if spamOn then
			mobIcon:select("Sync", mobIcon);
		else
			mobIcon:deselect("Sync", mobIcon);
		end;
		syncingIcon = false;
	end;
	local function setSpam(v)
		if spamOn == v then
			syncTopbarIcon();
			return;
		end;
		spamOn = v;
		if spamOn then
			if not spamConn and Net then
				spamConn = RS.PreSimulation:Connect(function()
					sendParry();
				end);
			end;
		elseif spamConn then
			spamConn:Disconnect();
			spamConn = nil;
		end;
		syncTopbarIcon();
	end;
	UIS.InputBegan:Connect(function(inp, gpe)
		if gpe then
			return;
		end;
		if inp.KeyCode == Enum.KeyCode.X then
			setSpam(not spamOn);
		end;
	end);
	task.spawn(function()
		local ok, Icon = pcall(function()
			return (loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Icon.luau")))();
		end);
		if not ok or (not Icon) then
			warn("Failed to load topbar icon for parry spam");
			return;
		end;
		local ico = ((Icon.new()):setName("ParrySpam")):setLabel("Parry spam: OFF");
		ico:autoDeselect(false);
		ico:align("Center");
		ico.selected:Connect(function()
			if syncingIcon then
				return;
			end;
			setSpam(true);
		end);
		ico.deselected:Connect(function()
			if syncingIcon then
				return;
			end;
			setSpam(false);
		end);
		mobIcon = ico;
		syncTopbarIcon();
	end);
	local hb;
	local function bind(ch)
		if hb then
			hb:Disconnect();
			hb = nil;
		end;
		local hrp = ch:WaitForChild("HumanoidRootPart", 9000000000);
		local ring = Instance.new("Part");
		ring.Name = "__ltseverydayyou__VISUALIZER__";
		ring.Anchored = true;
		ring.CanCollide = false;
		ring.CanTouch = false;
		ring.CanQuery = false;
		ring.CastShadow = false;
		ring.Material = Enum.Material.ForceField;
		ring.Transparency = 0.5;
		ring.Color = Color3.fromRGB(255, 255, 255);
		ring.Shape = Enum.PartType.Ball;
		ring.Size = Vector3.new(10, 10, 10);
		ring.Parent = WS;
		local lastPos, lastT = nil, nil;
		local vel = Vector3.zero;
		local tau = 0.05;
		local minR, maxR = 9, 90;
		local cd = 0.3;
		local lastFire = 0;
		local flashT = 0;
		hb = RS.Heartbeat:Connect(function(dt)
			if not (ch and ch.Parent and hrp and hrp.Parent) then
				return;
			end;
			local b = getBall();
			if not (b and b.Parent) then
				ring.Color = spamOn and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255);
				return;
			end;
			local now = tick();
			local bp = b.Position;
			local raw;
			local okVel, av = pcall(function()
				return b.AssemblyLinearVelocity;
			end);
			if okVel and typeof(av) == "Vector3" and av.Magnitude > 0.1 then
				raw = av;
				vel = av;
			elseif not lastT then
				lastT, lastPos = now, bp;
			else
				local dtt = now - lastT;
				if dtt > 0 then
					raw = (bp - lastPos) / dtt;
					local a = dt / (tau + dt);
					vel = vel + (raw - vel) * a;
					lastT, lastPos = now, bp;
				end;
			end;
			local hrpPos = hrp.Position;
			local spd = vel.Magnitude;
			local baseWin = 0.32;
			local baseOff = 6;
			local rad = spd * baseWin + baseOff;
			if rad < minR then
				rad = minR;
			end;
			if rad > maxR then
				rad = maxR;
			end;
			local pre = 8;
			local parryRad = rad + pre;
			ring.Size = Vector3.new(rad * 2, rad * 2, rad * 2);
			ring.CFrame = CFrame.new(hrpPos);
			local d = (bp - hrpPos).Magnitude;
			local dot = vel:Dot(hrpPos - bp);
			local app = dot > 0;
			local tgt = tgtOn();
			local ok = tgt;
			local tImp = 1000000;
			if spd > 1 then
				tImp = d / spd;
			end;
			local can = ok and app and spd > 5 and d <= parryRad and tImp <= 0.35;
			if spamOn then
				ring.Color = Color3.fromRGB(255, 0, 0);
			elseif now - flashT <= 0.12 then
				ring.Color = Color3.fromRGB(255, 60, 60);
			elseif not ok then
				ring.Color = Color3.fromRGB(255, 255, 255);
			elseif d <= rad then
				ring.Color = Color3.fromRGB(60, 255, 120);
			else
				ring.Color = Color3.fromRGB(255, 200, 60);
			end;
			if can and now - lastFire >= cd then
				sendParry();
				lastFire = now;
				flashT = now;
			end;
		end);
		ch.AncestryChanged:Connect(function(_, p)
			if not p then
				if hb then
					hb:Disconnect();
					hb = nil;
				end;
				if ring then
					ring:Destroy();
				end;
			end;
		end);
	end;
	local lp = Plrs.LocalPlayer;
	lp.CharacterAdded:Connect(bind);
	if lp.Character then
		bind(lp.Character);
	end;
end;
do
	local del = {
		"ballhit",
		"slasheffect"
	};
	local function chk(inst)
		if not inst:IsDescendantOf(workspace) then
			return;
		end;
		local n = inst.Name;
		if type(n) ~= "string" then
			return;
		end;
		local l = n:lower();
		for _, k in ipairs(del) do
			if l:find(k, 1, true) then
				pcall(function()
					inst:Destroy();
				end);
				break;
			end;
		end;
	end;
	for _, d in ipairs(workspace:QueryDescendants("Instance")) do
		task.defer(chk, d);
	end;
	workspace.DescendantAdded:Connect(function(inst)
		task.defer(chk, inst);
	end);
end;
