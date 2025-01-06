if getgenv().PressureBallsLoaded then return end


pcall(function() getgenv().PressureBallsLoaded=true end)

local ScreenGui=Instance.new("ScreenGui")
local ttLabel=Instance.new("TextButton")
local UICorner=Instance.new("UICorner")
local rep=game:GetService("ReplicatedStorage")
local plrUI=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
--local deathUI=plrUI:FindFirstChild("AfterDeath",true)
local isRan=false
local modulesToRestore = {}

local p,o=pcall(function()
	local function RestoreableModule(Module)
		if Module then
			for i,v in pairs(Module:GetChildren()) do RestoreableModule(v) end
			modulesToRestore[#modulesToRestore+1] = {Module,Module.Parent}
			Module:Remove()
		end
	end
	RestoreableModule(rep:FindFirstChild("PermanentEyefestation",true)) 
	RestoreableModule(rep:FindFirstChild("Searchlight",true))
	RestoreableModule(plrUI:FindFirstChild("LocalParasites",true))
	RestoreableModule(plrUI:FindFirstChild("LocalSquiddles",true))
	RestoreableModule(plrUI:FindFirstChild("LocalEntities",true))
end)

game:GetService("Players").LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid").Died:Connect(function()
	task.spawn(function()
		for i,v in pairs(modulesToRestore) do
			task.spawn(function()
				v[1].Parent = v[2]
				v=nil
			end)
		end
	end)
end)

if not gethui then
	getgenv().gethui=function()
		local h=(game:GetService("CoreGui"):FindFirstChildWhichIsA("ScreenGui") or game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui"))
		return h
	end
end

function randomString()
	local length=math.random(10,20)
	local array={}
	for i=1,length do
		array[i]=string.char(math.random(32,126))
	end
	return table.concat(array)
end
ScreenGui.Name=randomString()
ScreenGui.Parent=gethui()
ttLabel.Name=randomString()
ttLabel.Parent=ScreenGui
ttLabel.BackgroundColor3=Color3.fromRGB(4,4,4)
ttLabel.BackgroundTransparency=1.000
ttLabel.AnchorPoint=Vector2.new(0.5,0.5)
ttLabel.Position=UDim2.new(0.5,0,0,0)
ttLabel.Size=UDim2.new(0,32,0,33)
ttLabel.Font=Enum.Font.SourceSansBold
ttLabel.Text="God Mode (click me)"
ttLabel.TextColor3=Color3.fromRGB(255,255,255)
ttLabel.TextSize=20.000
ttLabel.TextWrapped=true
ttLabel.ZIndex=9999

UICorner.CornerRadius=UDim.new(1,0)
UICorner.Parent=ttLabel

function draggablev2(floght)
	floght.Active=true
	floght.Draggable=true
end	
local function removeKillables(eye)

	if eye.Parent == game:GetService("Workspace"):FindFirstChild("deathModel") then
		return
	end

	if (eye.Name:lower()=="eyes" or eye.Name:lower()=="eye") then
		wait();
		eye:Destroy()
	elseif eye.Name:lower()=="damageparts" or eye.Name:lower()=="damagepart" then
		wait();
		eye:Destroy()
	elseif eye.Name:lower()=="pandemonium" and eye:IsA"Part" then
		wait();
		eye:Destroy()
	elseif eye.Name:lower()=="monsterlocker" then
		wait();
		eye:Destroy()
	elseif eye.Name:lower()=="tricksterroom" then
		wait();
		eye:Destroy()
	end
end
function Perform()
	local old = game:GetService("Players").LocalPlayer.Character:GetPivot()
	local checking=false
	local enter = nil

	for _, v in ipairs(game:GetService("Workspace"):GetDescendants()) do
		if v.Name:lower() == "locker" and (v:IsA("Model") or v:IsA("BasePart")) then
			checking=false
			local s, e = pcall(function()
			for _,rem in ipairs(v:GetDescendants()) do
				if rem.Name:lower()=="enter" and rem:IsA("RemoteFunction") then
				enter=rem
				end
				end
				if enter then
					for i = 1, 5 do
						game:GetService("Players").LocalPlayer.Character:PivotTo(v:GetPivot())
						enter:InvokeServer("true")
						task.wait(.1)
					end
					checking=true
				end
			end)

			if not s then
				warn("Error invoking Remote: "..e)
			end
			game:GetService("Players").LocalPlayer.Character:PivotTo(old)
			if checking then break end
		end
	end

	task.wait(.5);

	local h,f=pcall(function()
		game:GetService("Players").LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid").WalkSpeed=20
	end)
	if not h then warn("no humanoid") end

	local eBorder=plrUI:FindFirstChild("EntityBorder",true)

	eBorder:GetPropertyChangedSignal("Visible"):Connect(function()
		if eBorder.Visible then eBorder.Visible=false end
	end)

	for _,g in ipairs(game:GetService("Workspace"):GetDescendants()) do
		removeKillables(g)
	end

	if not isRan then
		isRan=true
		game:GetService("Workspace").DescendantAdded:connect(function(eye)
			removeKillables(eye)
		end)
	end
end


function poop()
	local txtlabel=ttLabel
	txtlabel.Size=UDim2.new(0,32,0,33)
	txtlabel.BackgroundTransparency=0.14
	local textWidth=game:GetService("TextService"):GetTextSize(txtlabel.Text,txtlabel.TextSize,txtlabel.Font,Vector2.new(math.huge,math.huge)).X
	local newSize=UDim2.new(0,textWidth+69,0,33)
	txtlabel:TweenSize(newSize,"Out","Quint",1,true)
	txtlabel.MouseButton1Click:connect(function()
		spawn(Perform)
	end)
	draggablev2(txtlabel)
end
coroutine.wrap(poop)()