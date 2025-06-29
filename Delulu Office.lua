local GAME_ID = 6352299542
if game.GameId ~= GAME_ID then return end

local function getSvc(name)
    return (cloneref and cloneref(game:GetService(name))) or game:GetService(name)
end

local repS = getSvc("ReplicatedStorage")
local pls  = getSvc("Players")
local runS = getSvc("RunService")

local pl = pls.LocalPlayer or pls.PlayerAdded:Wait()
local ch = pl.Character    or pl.CharacterAdded:Wait()
local hm = ch:WaitForChild("HealthManager", 5)
if not hm then return end

local r   = repS:WaitForChild("Remotes")
local dc  = r:WaitForChild("DamageCall")
local dmg = { -99999999999 }

local function sendD()
    task.spawn(function()
        dc:FireServer(table.unpack(dmg))
    end)
end

hm:GetPropertyChangedSignal("Value"):Connect(sendD)
runS.Stepped:Connect(sendD)

if hookmetamethod then
    local orig
    orig = hookmetamethod(game, "__namecall", function(self, ...)
        if not checkcaller() and self == dc then
            local m = getnamecallmethod():lower()
            if m == "fireserver" or m == "invokeserver" then
                local a = {...}
                a[1] = dmg[1]
                return orig(self, table.unpack(a))
            end
        end
        return orig(self, ...)
    end)
end