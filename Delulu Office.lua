if game.GameId==6352299542 then
local rs = game:GetService("ReplicatedStorage")
local p = game:GetService("Players")
local lp = p.LocalPlayer
local c = lp.Character
local hm = c:FindFirstChild("HealthManager", true)
local r = rs:WaitForChild("Remotes")
local dc = r:WaitForChild("DamageCall")
local runService = game:GetService("RunService")
local a = { -math.huge }

local function hp()
    task.spawn(function()
        dc:FireServer(unpack(a))
    end)
end

hm:GetPropertyChangedSignal("Value"):Connect(function()
task.spawn(hp)
end)

runService.RenderStepped:Connect(function()
task.spawn(hp)
end)
if hookmetamethod then
local namecall
namecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod():lower()
    if not checkcaller() and self == dc and (method == "invokeserver" or method == "fireserver") then
        local args = {...}
        args[1] = -math.huge
        return namecall(self, unpack(args))
    end
    return namecall(self, ...)
end)
end
end