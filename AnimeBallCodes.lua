if game.GameId ~= 5120885191 then
	return
end

local rs = game:GetService("ReplicatedStorage")
local fw = rs:WaitForChild("Framework")
local rf = fw:WaitForChild("RemoteFunction")
local re = fw:WaitForChild("RemoteEvent")
local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer

local aDaily = { "RewardService", "ClaimDailyReward", {} }
local aCode1 = { "CodeService", "Redeem", { "thx4support" } }
local aCode2 = { "CodeService", "Redeem", { "grabitquick" } }
local aCr1 = { "CrateService", "BuyCrate", { "SwordA1", 1, false } }
local aCr2 = { "CrateService", "BuyCrate", { "GoldCrateA1", 1, false } }
local aSpin = { "RewardService", "ClaimSpinReward", {} }

rf:InvokeServer(unpack(aDaily))
task.wait(0.5)
rf:InvokeServer(unpack(aCode1))
rf:InvokeServer(unpack(aCode2))
task.wait(0.5)

task.spawn(function()
	while true do
		rf:InvokeServer(unpack(aCr1))
		task.wait(0.1)
	end
end)

task.spawn(function()
	while true do
		rf:InvokeServer(unpack(aCr2))
		task.wait(0.1)
	end
end)

if game.PlaceId ~= 15440283215 then
	task.spawn(function()
		local gui = lp:WaitForChild("PlayerGui")
		local sw
		local h
		while true do
			if not sw or not sw.Parent then
				sw = gui:FindFirstChild("SpinWheel") or gui:WaitForChild("SpinWheel", 5)
			end
			if sw and (not h or not h.Parent) then
				h = sw:FindFirstChild("Holder") or sw:WaitForChild("Holder", 5)
			end
			local t
			if h then
				local spin = h:FindFirstChild("Spin")
				if spin then
					local inside = spin:FindFirstChild("Inside")
					if inside then
						t = inside:FindFirstChild("Title")
					end
				end
			end
			if h then
				if t and typeof(t.Text) == "string" and t.Text:find("SPIN (x0)") then
					h.Visible = false
				else
					h.Visible = true
					re:FireServer(unpack(aSpin))
				end
			end
			task.wait(0.1)
		end
	end)
end
