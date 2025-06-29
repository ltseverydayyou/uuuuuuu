local G=6352299542
if game.GameId~=G then return end
local function S(n)return (cloneref and cloneref(game:GetService(n))) or game:GetService(n)end
local RS=S("ReplicatedStorage")
local PS=S("Players")
local RV=S("RunService")
local P=PS.LocalPlayer or PS.PlayerAdded:Wait()
local GUI=P:FindFirstChild("PlayerGui") or P:WaitForChild("PlayerGui")
if GUI then
    local ROG=GUI:FindFirstChild("ResetOnSpawnGui")
    if ROG then ROG.Enabled=false ROG.ResetOnSpawn=false end
    local MG=GUI:FindFirstChild("MainGui")
    local TH=MG and MG:FindFirstChild("MainTextHolder")
    local TG=TH and TH:FindFirstChild("TextGenerator")
    if TG then TG.Disabled=true end
end
local C=P.Character or P.CharacterAdded:Wait()
local H=C:FindFirstChild("HealthManager") or C:WaitForChild("HealthManager",5)
if H then
    local RF=RS:FindFirstChild("Remotes")
    local D=RF and RF:FindFirstChild("DamageCall")
    local I=-99999999999
    if D and hookmetamethod then
        local O
        O=hookmetamethod(game,"__namecall",function(self,...)
            if not checkcaller() and self==D then
                local M=getnamecallmethod():lower()
                if M=="fireserver" or M=="invokeserver" then
                    local A={...}
                    A[1]=I
                    return O(self,table.unpack(A))
                end
            end
            return O(self,...)
        end)
    end
    if D then RV.Stepped:Connect(function()D:FireServer(I)end)end
end

local TopBarApp={top=nil;frame=nil}
task.spawn(function()
    TopBarApp.top=Instance.new("ScreenGui")
    TopBarApp.top.Name="\u{200B}\u{200C}"
    TopBarApp.top.Enabled=true
    TopBarApp.top.DisplayOrder=0x7FFFFFFF
    TopBarApp.top.IgnoreGuiInset=true
    TopBarApp.top.Parent=(gethui and gethui()) or S("CoreGui") or GUI
    TopBarApp.frame=Instance.new("Frame")
    TopBarApp.frame.Name="\u{200B}\u{200C}"
    TopBarApp.frame.Size=UDim2.new(1,0,0,36)
    TopBarApp.frame.Position=UDim2.new(0,0,0,0)
    TopBarApp.frame.BackgroundTransparency=1
    TopBarApp.frame.Parent=TopBarApp.top
end)

task.spawn(function()
    repeat task.wait() until TopBarApp.frame
    local btn=Instance.new("TextButton")
    btn.Name="\u{200B}\u{200C}"
    btn.Text="Auto Kick"
    btn.Size=UDim2.new(0,100,0,30)
    btn.AnchorPoint=Vector2.new(0.5,0)
    btn.Position=UDim2.new(0.5,0,0,3)
    btn.BackgroundColor3=Color3.fromRGB(70,70,70)
    btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.BorderSizePixel=0
    btn.Parent=TopBarApp.frame
    local UC=Instance.new("UICorner",btn)
    UC.Name="\u{200B}\u{200C}"
    UC.CornerRadius=UDim.new(1,0)
    local UIS=S("UserInputService")
    local dragging=false
    local dragInput,dragStart,startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            dragStart=input.Position
            startPos=btn.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    btn.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
            dragInput=input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input==dragInput then
            local delta=input.Position-dragStart
            local fw=TopBarApp.frame.AbsoluteSize.X
            local bw=btn.AbsoluteSize.X
            local half=(fw-bw)/2
            local off=math.clamp(startPos.X.Offset+delta.X,-half,half)
            btn.Position=UDim2.new(0.5,off,startPos.Y.Scale,startPos.Y.Offset)
        end
    end)
    local running=false
    btn.Activated:Connect(function()
        running=not running
        btn.BackgroundColor3=running and Color3.fromRGB(0,200,0) or Color3.fromRGB(70,70,70)
        if running then task.spawn(function()
            local KR
            repeat
                task.wait(1)
                KR=C:FindFirstChild("MainControls")
                  and C.MainControls:FindFirstChild("ScriptsForCall")
                  and C.MainControls.ScriptsForCall:FindFirstChild("KickRemote")
            until KR
            while running do
                local RL=C:FindFirstChild("Right Leg")
                local FA=RL and RL:FindFirstChild("RightFootAttachment")
                if KR and FA then pcall(function()KR:FireServer(false,FA)end)end
                task.wait()
            end
        end) end
    end)
end)