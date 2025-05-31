if game.GameId==6352299542 then
    local function ClonedService(name)
        local service = (cloneref and cloneref(game:GetService(name))) or game:GetService(name)
        return service
    end
    local rs = ClonedService("ReplicatedStorage")
    local p = ClonedService("Players")
    local lp = p.LocalPlayer
    local c = lp.Character
    local hm = c:FindFirstChild("HealthManager", true)
    local r = rs:WaitForChild("Remotes")
    local dc = r:WaitForChild("DamageCall")
    local runService = ClonedService("RunService")
    local a = { -9999999999999 }

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
                args[1] = -9999999999999
                return namecall(self, unpack(args))
            end
            return namecall(self, ...)
        end)
    end
end