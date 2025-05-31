if game.GameId == 5170973975 then
    local function ClonedService(name)
    local service = (cloneref and cloneref(game:GetService(name))) or game:GetService(name)
    return service
end
repeat wait() until
ClonedService("Players").LocalPlayer.PlayerGui.AreaGui.Enabled == true

getgenv().zombieslol = not getgenv().zombieslol

                while getgenv().zombieslol and task.wait() do
                        pcall(function()
                            for i, v in pairs(ClonedService("Workspace").Stage_Monster:GetChildren()) do
                                local args = {
                                    [1] = {
                                        ["CF"] = CFrame.new(4.875078201293945, 24.025789260864258, 11.118204116821289) * CFrame.Angles(0.01760457269847393, -0.02762647345662117, 0.00048634063568897545),
                                        ["Part"] = v.Head,
                                        ["Owner"] = game:GetService("Players").LocalPlayer,
                                        ["TargetHead"] = false,
                                        ["Character"] = game:GetService("Players").LocalPlayer.Character,
                                        ["Hit"] = v.Head,
                                        ["Target"] = v,
                                        ["position"] = Vector3.new(5.695760726928711, 24.54859733581543, -18.57601547241211),
                                        ["normal"] = Vector3.new(-0.012950442731380463, -0.3850027620792389, 0.9228245615959167),
                                        ["Damage"] = 99
                                    }
                                }
                                
                                game:GetService("ReplicatedStorage").Remote.CastRemote:FireServer(unpack(args))
                            end
for _, j in pairs(ClonedService("Workspace").Temp_Item:GetChildren()) do
        spawn(function()
fireproximityprompt(j.Base.Attachment.ProximityPrompt)
end)
    end
    end)
end
end
