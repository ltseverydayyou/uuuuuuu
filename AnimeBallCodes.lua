if game.GameId ~= 5120885191 then
	return
end

local rs = game:GetService("ReplicatedStorage")
local fw = rs:WaitForChild("Framework")
local rf = fw:WaitForChild("RemoteFunction")
local re = fw:WaitForChild("RemoteEvent")
local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer

local aAFK = { "MatchService", "SetAFK", { true } }
local aDaily = { "RewardService", "ClaimDailyReward", {} }
local aCode1 = { "CodeService", "Redeem", { "thx4support" } }
local aCode2 = { "CodeService", "Redeem", { "grabitquick" } }
local aCr1 = { "CrateService", "BuyCrate", { "SwordA1", 1, false } }
local aCr2 = { "CrateService", "BuyCrate", { "GoldCrateA1", 1, false } }
local aSpin = { "RewardService", "ClaimSpinReward", {} }
local aLuck = { "BoostService", "UseBoost", { "Luck" } }
local aYen = { "BoostService", "UseBoost", { "Yen" } }

re:FireServer(unpack(aAFK))

rf:InvokeServer(unpack(aDaily))
task.wait(0.5)
rf:InvokeServer(unpack(aCode1))
rf:InvokeServer(unpack(aCode2))
task.wait(0.5)

task.spawn(function()
	while true do
		rf:InvokeServer(unpack(aCr1))
		re:FireServer(unpack(aLuck))
		re:FireServer(unpack(aYen))
		task.wait(0.1)
	end
end)

task.spawn(function()
	while true do
		rf:InvokeServer(unpack(aCr2))
		re:FireServer(unpack(aLuck))
		re:FireServer(unpack(aYen))
		task.wait(0.1)
	end
end)

if game.PlaceId ~= 15440283215 then
	task.spawn(function()
		local gui = lp:WaitForChild("PlayerGui")
		local sw = gui:WaitForChild("SpinWheel")
		local h = sw:WaitForChild("Holder")
		local spin = h:WaitForChild("Spin")
		local inside = spin:WaitForChild("Inside")
		local title = inside:WaitForChild("Title")
		local darken = h:FindFirstChild("Darken")

		while true do
			if not sw.Parent or not h.Parent or not title.Parent then
				sw = gui:FindFirstChild("SpinWheel") or gui:WaitForChild("SpinWheel", 5)
				if not sw then
					task.wait(0.5)
					continue
				end
				h = sw:FindFirstChild("Holder") or sw:WaitForChild("Holder", 5)
				if not h then
					task.wait(0.5)
					continue
				end
				spin = h:FindFirstChild("Spin") or h:WaitForChild("Spin", 5)
				inside = spin:FindFirstChild("Inside") or spin:WaitForChild("Inside", 5)
				title = inside:FindFirstChild("Title") or inside:WaitForChild("Title", 5)
				darken = h:FindFirstChild("Darken")
			end

			if not darken or not darken.Parent then
				darken = h:FindFirstChild("Darken")
			end

			if darken then
				darken.Visible = false
			end

			local txt = tostring(title.Text or "")
			local low = txt:lower()

			if low:find("spin (x0)", 1, true) then
				h.Visible = false
			else
				h.Visible = true
				re:FireServer(unpack(aSpin))
				re:FireServer(unpack(aLuck))
				re:FireServer(unpack(aYen))
			end

			task.wait(0.1)
		end
	end)
end
