local GAME_ID=6352299542
if game.GameId~=GAME_ID then return end
local function getSvc(n)return (cloneref and cloneref(game:GetService(n))) or game:GetService(n)end
local repS=getSvc("ReplicatedStorage")
local pls=getSvc("Players")
local runS=getSvc("RunService")
local pl=pls.LocalPlayer or pls.PlayerAdded:Wait()
local ch=pl.Character or pl.CharacterAdded:Wait()
local hm=ch:WaitForChild("HealthManager",5)
if not hm then return end
local dc=repS:WaitForChild("Remotes"):WaitForChild("DamageCall")
local INFINITE=-99999999999
if hookmetamethod then
    local orig
    orig=hookmetamethod(game,"__namecall",function(self,...)
        if not checkcaller() and self==dc then
            local m=getnamecallmethod():lower()
            if m=="fireserver" or m=="invokeserver" then
                local a={...}
                a[1]=INFINITE
                return orig(self,table.unpack(a))
            end
        end
        return orig(self,...)
    end)
end
runS.Stepped:Connect(function()
    dc:FireServer(INFINITE)
end)