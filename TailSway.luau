local g = getgenv and getgenv() or _G;
g.__TailAnim = g.__TailAnim or {};
local st = g.__TailAnim;
if st.conn then
	st.conn:Disconnect();
	st.conn = nil;
end;
local plrs = game:GetService("Players");
local rs = game:GetService("RunService");
local lp = plrs.LocalPlayer;
local chr = lp.Character or lp.CharacterAdded:Wait();
local swingSpeed = 1.5;
local swingEnabled = true;
local function isTail(acc)
	if not acc:IsA("Accessory") then
		return false;
	end;
	local n = (acc.Name or ""):lower();
	if n:find("tail", 1, true) then
		return true;
	end;
	if acc.AccessoryType == Enum.AccessoryType.Waist then
		local h = acc:FindFirstChild("Handle");
		if not h then
			return false;
		end;
		local m = h:FindFirstChildOfClass("Mesh") or h:FindFirstChildOfClass("SpecialMesh");
		if not m then
			return false;
		end;
		local mn = (m.Name or ""):lower();
		local mid = (tostring(m.MeshId or "")):lower();
		if mn:find("tail", 1, true) or mid:find("tail", 1, true) then
			return true;
		end;
	end;
	return false;
end;
local function getTailMotor()
	chr = lp.Character or lp.CharacterAdded:Wait();
	for _, v in ipairs(chr:GetChildren()) do
		if isTail(v) then
			local h = v:FindFirstChild("Handle");
			if h then
				local m = h:FindFirstChildOfClass("Motor6D") or h:FindFirstChild("AccessoryWeld");
				if m then
					return m;
				end;
			end;
		end;
	end;
end;
local m = getTailMotor();
if not m then
	return;
end;
local baseC0 = m.C0;
local t = 0;
local amp = math.rad(25);
st.conn = rs.RenderStepped:Connect(function(dt)
	if not m or (not m.Parent) then
		m = getTailMotor();
		if not m then
			return;
		end;
		baseC0 = m.C0;
		t = 0;
	end;
	if not swingEnabled then
		m.C0 = baseC0;
		return;
	end;
	t = t + dt * swingSpeed;
	local sway = math.sin(t) * amp;
	m.C0 = baseC0 * CFrame.Angles(0, sway, 0);
end);
