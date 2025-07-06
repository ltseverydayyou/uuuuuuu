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
    btn.Position=UDim2.new(0.5,0,0,10)
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
                KR=C:FindFirstChild("MainControls") and C.MainControls:FindFirstChild("ScriptsForCall") and C.MainControls.ScriptsForCall:FindFirstChild("KickRemote")
            until KR
            while running do
                local RL=C:FindFirstChild("Right Leg")
                local FA=RL and RL:FindFirstChild("RightFootAttachment")
                if KR and FA then pcall(function()KR:FireServer(false,FA)end) pcall(function()KR:FireServer(0,FA)end)end
                task.wait(.15)
            end
        end) end
    end)

    local fixBtn=Instance.new("TextButton")
    fixBtn.Name="\u{200B}\u{200C}"
    fixBtn.Text="Anchor Stuck Fix"
    fixBtn.Size=UDim2.new(0,100,0,30)
    fixBtn.AnchorPoint=Vector2.new(0.5,0)
    fixBtn.Position=UDim2.new(0.65,0,0,10)
    fixBtn.BackgroundColor3=Color3.fromRGB(70,70,70)
    fixBtn.TextColor3=Color3.fromRGB(255,255,255)
    fixBtn.BorderSizePixel=0
    fixBtn.Parent=TopBarApp.frame
    local fixUC=Instance.new("UICorner",fixBtn)
    fixUC.Name="\u{200B}\u{200C}"
    fixUC.CornerRadius=UDim.new(1,0)
    local fixDragging=false
    local fixDragInput,fixDragStart,fixStartPos
    fixBtn.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            fixDragging=true
            fixDragStart=input.Position
            fixStartPos=fixBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then fixDragging=false end
            end)
        end
    end)
    fixBtn.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
            fixDragInput=input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if fixDragging and input==fixDragInput then
            local delta=input.Position-fixDragStart
            local fw=TopBarApp.frame.AbsoluteSize.X
            local bw=fixBtn.AbsoluteSize.X
            local half=(fw-bw)/2
            local off=math.clamp(fixStartPos.X.Offset+delta.X,-half,half)
            fixBtn.Position=UDim2.new(fixStartPos.X.Scale,off,fixStartPos.Y.Scale,fixStartPos.Y.Offset)
        end
    end)
    fixBtn.Activated:Connect(function()
        local promptGui=Instance.new("ScreenGui")
        promptGui.Name="\u{200B}\u{200C}"
        promptGui.DisplayOrder=0x7FFFFFFF
        promptGui.Parent=(gethui and gethui()) or S("CoreGui") or GUI
        local promptFrame=Instance.new("Frame",promptGui)
        promptFrame.Size=UDim2.new(0,300,0,150)
        promptFrame.Position=UDim2.new(0.5,-150,0.5,-75)
        promptFrame.BackgroundColor3=Color3.fromRGB(50,50,50)
        promptFrame.BorderSizePixel=0
        local promptLabel=Instance.new("TextLabel",promptFrame)
        promptLabel.Size=UDim2.new(1,-20,0,80)
        promptLabel.Position=UDim2.new(0,10,0,10)
        promptLabel.BackgroundTransparency=1
        promptLabel.Text="Are you sure you want to run this? Only use it when you're completely stuck in the void."
        promptLabel.TextWrapped=true
        promptLabel.TextColor3=Color3.fromRGB(255,255,255)
        promptLabel.Font=Enum.Font.SourceSans
        promptLabel.TextSize=18
        local yesBtn=Instance.new("TextButton",promptFrame)
        yesBtn.Size=UDim2.new(0,100,0,30)
        yesBtn.Position=UDim2.new(0.25,0,0,110)
        yesBtn.Text="Yes"
        yesBtn.BackgroundColor3=Color3.fromRGB(0,170,0)
        local yesUC=Instance.new("UICorner",yesBtn)
        yesUC.CornerRadius=UDim.new(0,4)
        local noBtn=Instance.new("TextButton",promptFrame)
        noBtn.Size=UDim2.new(0,100,0,30)
        noBtn.Position=UDim2.new(0.65,0,0,110)
        noBtn.Text="No"
        noBtn.BackgroundColor3=Color3.fromRGB(170,0,0)
        local noUC=Instance.new("UICorner",noBtn)
        noUC.CornerRadius=UDim.new(0,4)
        noBtn.Activated:Connect(function()
            promptGui:Destroy()
        end)
        yesBtn.Activated:Connect(function()
            promptGui:Destroy()
            spawn(function()
                local rs=game:GetService("ReplicatedStorage")
                local r=rs:WaitForChild("Remotes"):WaitForChild("EntityTpObbyCall")
                r:FireServer(false)
                task.wait()
                r:FireServer(true)
                task.wait()
                r:FireServer(false)
                task.wait(6)
                local exitPart
                for _,desc in ipairs(workspace:GetDescendants()) do
                    if desc:IsA("BasePart") and desc.Name=="ExitPart" then
                        exitPart=desc
                        break
                    end
                end
                if exitPart then
                    local player=game:GetService("Players").LocalPlayer
                    local char=player.Character or player.CharacterAdded:Wait()
                    if char.PrimaryPart then
                        char:PivotTo(exitPart.CFrame*CFrame.new(0,1,0))
                    end
                end
            end)
        end)
    end)
end)

task.spawn(function()
    local pscr=P:WaitForChild("PlayerScripts")
    local scr=pscr:WaitForChild("ScreenControls")
    local cm=scr:WaitForChild("CameraManagementMain")
    local o=cm:WaitForChild("CameraCFrameOverwrite")
    RV.RenderStepped:Connect(function()
        o.Value=0
    end)
end)