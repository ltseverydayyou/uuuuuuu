local G = getgenv and getgenv() or _G;
if G.__apb2 then
	return;
end;
G.__apb2 = true;
local Plrs = game:GetService("Players");
local RS = game:GetService("RunService");
local RSrv = game:GetService("ReplicatedStorage");
local WS = workspace;
local FW;
local Net;
local Sw;
local Snd;
local FRemote;
do
	local okFW, fw = pcall(function()
		return require(RSrv:WaitForChild("Framework"));
	end);
	if okFW and fw then
		FW = fw;
		local okNet, svc = pcall(function()
			return FW:Fetch("SwordService");
		end);
		if okNet and svc then
			Net = svc;
		end;
		local okSw, swc = pcall(function()
			return FW:Get("SwordController");
		end);
		if okSw then
			Sw = swc;
		end;
		local okSnd, sdc = pcall(function()
			return FW:Get("SoundController");
		end);
		if okSnd then
			Snd = sdc;
		end;
	end;
	local okRf, rf = pcall(function()
		return (RSrv:WaitForChild("Framework")):WaitForChild("RemoteFunction");
	end);
	if okRf and rf then
		FRemote = rf;
	end;
end;
local lp = Plrs.LocalPlayer;
local function root()
	local c = lp.Character;
	return c and c:FindFirstChild("HumanoidRootPart");
end;
local baseDetectionDistance = 28;
local detectionDistance = baseDetectionDistance;
local incrementBonus = 0;
local lastParryTime = 0;
local hasParried = false;
local lastParryBall;
local ballBillboard;
local ballLabel;
local predictSphere;
local function DoParry()
	local now = tick();
	if now - lastParryTime < 0.25 then
		return;
	end;
	lastParryTime = now;
	local cam = WS.CurrentCamera;
	if not cam then
		return;
	end;
	local y = cam.CFrame.LookVector.Y;
	local success = false;
	if Net and Net.Block then
		local ok, res = pcall(function()
			return Net.Block:Invoke(y);
		end);
		if ok and res ~= nil then
			success = true;
		end;
	end;
	if not success and FRemote then
		local ok = pcall(function()
			FRemote:InvokeServer("SwordService", "Block", {
				y
			});
		end);
		if ok then
			success = true;
		end;
	end;
	if success then
		local hold = Sw and Sw.GetSwordAnim and Sw.GetSwordAnim("Hold") or nil;
		if hold then
			hold:Play();
		end;
		if Snd and Snd.PlaySound then
			Snd.PlaySound("Block");
		end;
		if Sw and Sw.ShowShield then
			Sw.ShowShield();
		end;
		incrementBonus = math.clamp(incrementBonus + 1, 0, 8);
		detectionDistance = baseDetectionDistance + incrementBonus * 1.5;
	end;
end;
local function createBallVisualizer()
	if ballBillboard then
		ballBillboard:Destroy();
	end;
	ballBillboard = Instance.new("BillboardGui");
	ballBillboard.Name = "BallViz";
	ballBillboard.Size = UDim2.new(0, 200, 0, 50);
	ballBillboard.StudsOffset = Vector3.new(0, 4, 0);
	ballBillboard.AlwaysOnTop = true;
	ballBillboard.Enabled = false;
	ballBillboard.Parent = WS;
	local frame = Instance.new("Frame");
	frame.Size = UDim2.new(1, 0, 1, 0);
	frame.BackgroundTransparency = 1;
	frame.Parent = ballBillboard;
	local text = Instance.new("TextLabel");
	text.Size = UDim2.new(1, 0, 1, 0);
	text.BackgroundTransparency = 1;
	text.TextColor3 = Color3.fromRGB(255, 255, 255);
	text.TextStrokeTransparency = 0.4;
	text.TextStrokeColor3 = Color3.new(0, 0, 0);
	text.Font = Enum.Font.GothamBold;
	text.TextSize = 22;
	text.Text = "Dist: -- | Speed: --";
	text.Parent = frame;
	ballLabel = text;
end;
local function updateBallVisualizer(ball, dist, vel)
	if not ballBillboard or (not ballLabel) or (not ball) then
		return;
	end;
	ballBillboard.Adornee = ball;
	ballBillboard.Enabled = true;
	local color = vel <= 60 and Color3.fromRGB(255, 80, 80) or (vel > 100 and Color3.fromRGB(80, 180, 255) or Color3.fromRGB(100, 255, 100));
	ballLabel.TextColor3 = color;
	ballLabel.Text = string.format("Dist: %.1f | Speed: %.1f", dist, vel);
end;
local function createPredictSphere()
	if predictSphere then
		predictSphere:Destroy();
	end;
	predictSphere = Instance.new("Part");
	predictSphere.Name = "PredictSphere";
	predictSphere.Shape = Enum.PartType.Ball;
	predictSphere.Material = Enum.Material.ForceField;
	predictSphere.Color = Color3.new(1, 1, 1);
	predictSphere.Transparency = 0.5;
	predictSphere.CanCollide = false;
	predictSphere.Anchored = true;
	predictSphere.Size = Vector3.new(1, 1, 1);
	predictSphere.Parent = WS;
end;
local function updatePredictSphere(position, radius)
	if not predictSphere then
		createPredictSphere();
	end;
	predictSphere.CFrame = CFrame.new(position);
	local finalRadius = math.clamp(radius / 3 * 0.7 * 1.1, 4, 20);
	predictSphere.Size = Vector3.new(finalRadius * 2, finalRadius * 2, finalRadius * 2);
	predictSphere.Transparency = 0.5;
end;
local function hasProximityBoost(ball)
	for _, p in ipairs(Plrs:GetPlayers()) do
		if p ~= lp and p.Character then
			local h = p.Character:FindFirstChild("HumanoidRootPart");
			if h and (h.Position - ball.Position).Magnitude <= 20 then
				return true;
			end;
		end;
	end;
	return false;
end;
local function findBall()
	local b = WS:FindFirstChild("Ball");
	if b and b:IsA("BasePart") then
		return b;
	end;
	local folder = WS:FindFirstChild("Balls");
	if not folder then
		return nil;
	end;
	local hrp = root();
	if not hrp then
		return nil;
	end;
	local best;
	local bestDist = math.huge;
	for _, v in ipairs(folder:GetChildren()) do
		if v:IsA("BasePart") then
			local d = (v.Position - hrp.Position).Magnitude;
			if d < bestDist then
				bestDist = d;
				best = v;
			end;
		end;
	end;
	return best;
end;
createBallVisualizer();
createPredictSphere();
RS.Heartbeat:Connect(function()
	local hrp = root();
	if not hrp then
		return;
	end;
	local char = lp.Character;
	if not char then
		return;
	end;
	local now = tick();
	local parryCooldown = 1.8;
	local hasHighlight = char:FindFirstChild("Highlight") ~= nil;
	if now - lastParryTime > parryCooldown and detectionDistance > baseDetectionDistance then
		detectionDistance = baseDetectionDistance;
		incrementBonus = 0;
	end;
	if hasParried and hasHighlight and now - lastParryTime >= parryCooldown then
		hasParried = false;
	end;
	task.defer(function()
		if not ballBillboard then
			createBallVisualizer();
		end;
		if not predictSphere then
			createPredictSphere();
		end;
		local ball = findBall();
		if not ball or (not ball:IsA("BasePart")) then
			if ballBillboard then
				ballBillboard.Enabled = false;
			end;
			if predictSphere then
				predictSphere.Transparency = 1;
			end;
			hasParried = false;
			lastParryBall = nil;
			return;
		end;
		if ball ~= lastParryBall then
			hasParried = false;
			lastParryBall = ball;
		end;
		local dist = (hrp.Position - ball.Position).Magnitude;
		local velVec = ball.AssemblyLinearVelocity;
		local currVel = velVec.Magnitude;
		local prevVel = ball:GetAttribute("PrevVel") or currVel;
		local accel = currVel - prevVel;
		ball:SetAttribute("PrevVel", currVel);
		local seenAt = ball:GetAttribute("__SeenAt");
		if not seenAt then
			seenAt = now;
			ball:SetAttribute("__SeenAt", seenAt);
		end;
		local age = now - seenAt;
		updateBallVisualizer(ball, dist, currVel);
		local multiplier = 0.12;
		if currVel < 60 then
			multiplier = 0.06;
		elseif currVel > 120 then
			multiplier = 0.2;
		elseif currVel > 80 then
			multiplier = 0.16;
		end;
		local proxBoost = hasProximityBoost(ball) and 2 or 0;
		local accelExtra = accel > 10 and math.min(accel * 0.25, 6) or 0;
		local predict = detectionDistance + proxBoost + currVel * multiplier + accelExtra;
		if age > 0.35 then
			if currVel < 70 then
				predict = predict + (70 - currVel) * 0.3;
			end;
			if currVel < 30 then
				predict = predict + 6;
			end;
		end;
		updatePredictSphere(hrp.Position, predict);
		local minSpeed = 8;
		if age < 0.35 and dist > 17 then
			minSpeed = 30;
		end;
		if currVel < minSpeed then
			return;
		end;
		local toYou = hrp.Position - ball.Position;
		local mag = toYou.Magnitude;
		if mag < 0.001 then
			return;
		end;
		local dirToYou = toYou / mag;
		local velDir = currVel > 0.001 and velVec / currVel or (-dirToYou);
		local dot = dirToYou:Dot(velDir);
		if dot <= 0.4 then
			return;
		end;
		local targetName = ball:GetAttribute("Target");
		local isTarget = targetName == lp.Name;
		if not isTarget then
			return;
		end;
		if not hasHighlight then
			return;
		end;
		if dist <= predict and (not hasParried) and now - lastParryTime >= 0.25 then
			DoParry();
			hasParried = true;
		end;
		if dist > predict + 12 then
			hasParried = false;
		end;
	end);
end);
