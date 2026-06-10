local __lt = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {};
	local sharedEnv = rawget(_G, "shared");
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil);
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver");
		if type(cached) == "table" then
			return cached;
		end;
	end;
	local loader = loadstring or load;
	if type(loader) ~= "function" then
		error("Service resolver loader unavailable");
	end;
	local resolver = loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau");
	if type(resolver) ~= "function" then
		error("Service resolver failed to compile");
	end;
	local loaded = resolver();
	if type(loaded) ~= "table" then
		error("Service resolver failed to load");
	end;
	if cacheHost then
		cacheHost.__lt_service_resolver = loaded;
	end;
	return loaded;
end)();

--[[
	Model Viewer App Module
	
	A model viewer :3
]]

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, ModelViewer, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local function getPath(obj)
	if obj.Parent == nil then
		return "Nil parented"
	else
		return Explorer.GetInstancePath(obj)
	end
end

local function trackConn(conn)
	if Main and Main.TrackConn then
		return Main.TrackConn(conn)
	end
	return conn
end
local function main()
	local RunService = __lt.cs("RunService", cloneref)
	local UserInputService = __lt.cs("UserInputService", cloneref)
	
	local ModelViewer = {
		EnableInputCamera = true,
		IsViewing = false,
		AutoRefresh = false,
		ZoomMultiplier = 2,
		AutoRotate = true,
		RotationSpeed = 0.01,
		RefreshRate = 30 -- hertz
	}
	
	local window, viewportFrame, pathLabel, settingsButton
	local model, camera, originalModel
	local particleEmitters = {}

	local effectClasses = {
		"ParticleEmitter",
		"Beam",
		"Trail",
		"Fire",
		"Smoke",
		"Sparkles",
	}

	local function isPreviewEffect(item)
		if not item then return false end
		for _, className in effectClasses do
			if item:IsA(className) then
				return true
			end
		end
		return false
	end

	local function hasPreviewEffect(item)
		if not item then return false end
		if isPreviewEffect(item) then
			return true
		end
		for _, child in item:GetDescendants() do
			if isPreviewEffect(child) then
				return true
			end
		end
		return false
	end

	local function clearViewportContent(keepCamera)
		if not viewportFrame then return end
		for _, child in viewportFrame:GetChildren() do
			if not (keepCamera and camera and child == camera) then
				child:Destroy()
			end
		end
		particleEmitters = {}
	end

	local function preparePreview(root, forceEffects)
		if not root then return end
		local items = root:GetDescendants()
		table.insert(items, root)

		for _, child in items do
			if child:IsA("BasePart") then
				child.Anchored = true
			elseif child:IsA("ParticleEmitter") then
				if forceEffects then
					child.Enabled = true
				end
				table.insert(particleEmitters, {
					Emitter = child,
					Accumulator = 0,
				})

				local emitCount = 8
				pcall(function()
					emitCount = math.clamp(math.floor(child.Rate / 4), 1, 30)
				end)
				pcall(function()
					child:Emit(emitCount)
				end)
			elseif child:IsA("Beam") or child:IsA("Trail") or child:IsA("Fire") or child:IsA("Smoke") or child:IsA("Sparkles") then
				if forceEffects then
					child.Enabled = true
				end
			end
		end
	end

	local function createPreviewWorld()
		local worldModel = Instance.new("WorldModel")
		worldModel.Name = "ViewModel"
		worldModel.Parent = viewportFrame
		return worldModel
	end

	local function createEffectPreview(item, worldModel)
		model = Instance.new("Model")
		model.Name = item.Name .. " Preview"
		model.Parent = worldModel

		local hostPart = Instance.new("Part")
		hostPart.Name = "EffectOrigin"
		hostPart.Anchored = true
		hostPart.CanCollide = false
		hostPart.CanTouch = false
		hostPart.CanQuery = false
		hostPart.Transparency = 1
		hostPart.Size = Vector3.new(1, 1, 1)
		hostPart.CFrame = CFrame.new(0, 0, 0)
		hostPart.Parent = model
		model.PrimaryPart = hostPart

		if item:IsA("Beam") or item:IsA("Trail") then
			local attach0 = Instance.new("Attachment")
			attach0.Name = "PreviewAttachment0"
			attach0.Position = Vector3.new(-1, 0, 0)
			attach0.Parent = hostPart

			local attach1 = Instance.new("Attachment")
			attach1.Name = "PreviewAttachment1"
			attach1.Position = Vector3.new(1, 0, 0)
			attach1.Parent = hostPart

			pcall(function()
				if item.Attachment0 then
					attach0.CFrame = item.Attachment0.CFrame
				end
			end)
			pcall(function()
				if item.Attachment1 then
					attach1.CFrame = item.Attachment1.CFrame
				end
			end)

			local clone = item:Clone()
			clone.Attachment0 = attach0
			clone.Attachment1 = attach1
			clone.Enabled = true
			clone.Parent = hostPart
		elseif item:IsA("Attachment") then
			local attachment = item:Clone()
			attachment.Parent = hostPart
		else
			local parent = item.Parent
			local effectParent = hostPart

			if parent and parent:IsA("Attachment") then
				local attachment = parent:Clone()
				attachment:ClearAllChildren()
				attachment.Parent = hostPart
				effectParent = attachment
			end

			local clone = item:Clone()
			clone.Parent = effectParent
		end

		preparePreview(model, true)
	end
	
	
	ModelViewer.StopViewModel = function(updating)
		if updating then
			clearViewportContent(true)
			model = nil
		else
			if camera then camera = nil end
			if model then model = nil end
			clearViewportContent(false)
			
			ModelViewer.IsViewing = false
			window:SetTitle("3D Preview")
			pathLabel.Gui.Text = ""
		end
	end

	ModelViewer.CanView = function(item)
		return item and (
			item:IsA("BasePart")
			or item:IsA("Model")
			or isPreviewEffect(item)
			or (item:IsA("Attachment") and hasPreviewEffect(item))
		)
	end

	ModelViewer.ViewModel = function(item, updating)
		if not item then return end
		ModelViewer.StopViewModel(updating)
		
		if item ~= workspace and not item:IsA("Terrain") then
			local worldModel = createPreviewWorld()

			-- why Model == workspace
			-- wtf?
			
			if item:IsA("BasePart") and not item:IsA("Model") then			
				model = Instance.new("Model")
				model.Parent = worldModel

				local clone = item:Clone()
				clone.Parent = model
				model.PrimaryPart = clone
				model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
				preparePreview(model, true)
			elseif item:IsA("Model") then
				item.Archivable = true

			--[[if not item.PrimaryPart then
				pathLabel.Gui.Text = "Failed to view model: No PrimaryPart is found."
				return
			end]]
				if #item:GetChildren() == 0 then
					worldModel:Destroy()
					return
				end
				
				model = item:Clone()
				model.Parent = worldModel

				-- fallback
				if not model.PrimaryPart then
					local found = false
					for _, child in model:GetDescendants() do
						if child:IsA("BasePart") then
							model.PrimaryPart = child
							model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
							found = true
							break
						end
					end
					if not found then
						model:Destroy()
						model = nil
						worldModel:Destroy()
						return
					end
				end
				preparePreview(model, true)
			elseif isPreviewEffect(item) or (item:IsA("Attachment") and hasPreviewEffect(item)) then
				createEffectPreview(item, worldModel)
			else
				worldModel:Destroy()
				return
			end
		end
		
		originalModel = item
		
		if ModelViewer.AutoRefresh and not updating then
			task.spawn(function()
				while model and ModelViewer.AutoRefresh do
					
					ModelViewer.ViewModel(originalModel, true)
					task.wait(1 / ModelViewer.RefreshRate)
				end
			end)
		end
		
		if not updating then
			camera = Instance.new("Camera")
			viewportFrame.CurrentCamera = camera

			camera.Parent = viewportFrame
			camera.FieldOfView = 60
			
			window:SetTitle(item.Name.." - 3D Preview")
			pathLabel.Gui.Text = "path: " .. getPath(originalModel)
			window:Show()
			ModelViewer.IsViewing = true
		end
	end

	ModelViewer.Init = function()
		window = Lib.Window.new()
		window:SetTitle("3D Preview")
		window:Resize(350,200)
		ModelViewer.Window =  window
		
		viewportFrame = Instance.new("ViewportFrame")
		viewportFrame.Parent = window.GuiElems.Content
		viewportFrame.BackgroundTransparency = 1
		viewportFrame.Size = UDim2.new(1,0,1,0)
		
		pathLabel = Lib.Label.new()
		pathLabel.Gui.Parent = window.GuiElems.Content
		pathLabel.Gui.AnchorPoint = Vector2.new(0,1)
		pathLabel.Gui.Text = ""
		pathLabel.Gui.TextSize = 12
		pathLabel.Gui.TextTransparency = 0.8
		pathLabel.Gui.Position = UDim2.new(0,1,1,0)
		pathLabel.Gui.Size = UDim2.new(1,-1,0,15)
		pathLabel.Gui.BackgroundTransparency = 1
		
		settingsButton = Instance.new("ImageButton",window.GuiElems.Content)
		settingsButton.AnchorPoint = Vector2.new(1,0)
		settingsButton.BackgroundTransparency = 1
		settingsButton.Size = UDim2.new(0,15,0,15)
		settingsButton.Position = UDim2.new(1,-3,0,3)
		settingsButton.Image = Main.ResolveAsset("rbxassetid://6578871732")
		settingsButton.ImageTransparency = 0.5
		-- mobile input check
		if __lt.cm("UserInputService", "GetLastInputType") == Enum.UserInputType.Touch then
			settingsButton.Visible = true
		else
			settingsButton.Visible = false
		end

		ModelViewer.ApplyTheme = function()
			local t = Settings and Settings.Theme
			if not t then return end
			if ModelViewer.Window and ModelViewer.Window.ApplyTheme then
				ModelViewer.Window:ApplyTheme()
			end
			if viewportFrame then
				viewportFrame.BackgroundColor3 = t.Main1 or viewportFrame.BackgroundColor3
			end
		end

		local rotationX, rotationY = -15, 0
		local distance = 10
		local dragging = false
		local hovering = false
		local lastpos = Vector2.zero

		trackConn(viewportFrame.InputBegan:Connect(function(input)
			if not ModelViewer.EnableInputCamera then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				lastpos = input.Position
			elseif input.KeyCode == Enum.KeyCode.LeftShift then
				ModelViewer.ZoomMultiplier = 10
			end
		end))
		

		trackConn(viewportFrame.MouseEnter:Connect(function()
			hovering = true
		end))
		trackConn(viewportFrame.MouseLeave:Connect(function()
			hovering = false
		end))

		trackConn(viewportFrame.InputEnded:Connect(function(input)
			if not ModelViewer.EnableInputCamera then return end
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			elseif input.KeyCode == Enum.KeyCode.LeftShift then
				ModelViewer.ZoomMultiplier = 2
			end
		end))

		trackConn(viewportFrame.InputChanged:Connect(function(input)
			if not ModelViewer.EnableInputCamera then return end
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local delta = input.Position - lastpos
				lastpos = input.Position

				rotationY -= delta.X * 0.01
				rotationX -= delta.Y * 0.01
				rotationX = math.clamp(rotationX, -math.pi/2 + 0.1, math.pi/2 - 0.1)
			end

			if input.UserInputType == Enum.UserInputType.MouseWheel and hovering then
				distance = math.clamp(distance - (input.Position.Z * ModelViewer.ZoomMultiplier), 0.1, math.huge)
			end
		end))

		trackConn(RunService.RenderStepped:Connect(function(dt)
			if camera and model then
				if not dragging and ModelViewer.AutoRotate then
					rotationY += ModelViewer.RotationSpeed
				end
				
				local center = model.PrimaryPart.Position
				local offset = CFrame.new(0, 0, distance)
				local rotation = CFrame.Angles(0, rotationY, 0) * CFrame.Angles(rotationX, 0, 0)

				local camCF = CFrame.new(center) * rotation * offset

				camera.CFrame = CFrame.lookAt(camCF.Position, center)
				
			end

			for i = #particleEmitters, 1, -1 do
				local particleData = particleEmitters[i]
				local emitter = particleData.Emitter

				if not emitter or not emitter.Parent then
					table.remove(particleEmitters, i)
				elseif emitter.Enabled then
					local emitRate = 0
					pcall(function()
						emitRate = emitter.Rate
					end)

					if emitRate > 0 then
						particleData.Accumulator += emitRate * dt
						local emitCount = math.floor(particleData.Accumulator)

						if emitCount > 0 then
							particleData.Accumulator -= emitCount
							pcall(function()
								emitter:Emit(math.clamp(emitCount, 1, 50))
							end)
						end
					end
				end
			end
		end))
		
		-- context stuffs
		local context = Lib.ContextMenu.new()
		
		local absoluteSize = context.Gui.AbsoluteSize
		context.MaxHeight = (absoluteSize.Y <= 600 and (absoluteSize.Y - 40)) or nil

		-- Registers
		context:Register("STOP",{Name = "Stop Viewing", OnClick = function()
			ModelViewer.StopViewModel()
		end})
		context:Register("EXIT",{Name = "Exit", OnClick = function()
			ModelViewer.StopViewModel()
			context:Hide()
			window:Hide()
		end})
		context:Register("COPY_PATH",{Name = "Copy Path", OnClick = function()
			if model then
				env.setclipboard(getPath(originalModel))
			end
		end})
		context:Register("REFRESH",{Name = "Refresh", OnClick = function()
			if originalModel then
				ModelViewer.ViewModel(originalModel)
			end
		end})
		context:Register("ENABLE_AUTO_REFRESH",{Name = "Enable Auto Refresh", OnClick = function()
			if originalModel then
				ModelViewer.AutoRefresh = true
				ModelViewer.ViewModel(originalModel)
			end
		end})
		context:Register("DISABLE_AUTO_REFRESH",{Name = "Disable Auto Refresh", OnClick = function()
			if originalModel then
				ModelViewer.AutoRefresh = false
				ModelViewer.ViewModel(originalModel)
			end
		end})
		context:Register("SAVE_INST",{Name = "Save to File", OnClick = function()
			if model then
				local saveName = Main.FormatFileName(Settings.Files.ObjectSaveNameFormat, {
					name = originalModel.Name,
					className = originalModel.ClassName,
					index = 1,
					count = 1
				})
				Lib.SaveAsPrompt(saveName, function(filename)
					window:SetTitle(originalModel.Name.." - Model Viewer - Saving")	
					
					local success, result = pcall(env.saveinstance,
						originalModel,
						{
							FilePath = filename,
							Decompile = true,
							RemovePlayerCharacters = false
						}
					)
					
					if success then
						window:SetTitle(originalModel.Name.." - Model Viewer - Saved")
						context:Hide()
						task.wait(5)
						if model then
							window:SetTitle(originalModel.Name.." - Model Viewer")
						end
					else
						window:SetTitle(originalModel.Name.." - Model Viewer - Error")
						warn("Error while saving model: "..result)
						context:Hide()
						task.wait(5)
						if model then
							window:SetTitle(originalModel.Name.." - Model Viewer")
						end
					end
				end)
			end
		end})
		
		context:Register("ENABLE_AUTO_ROTATE",{Name = "Enable Auto Rotate", OnClick = function()
			ModelViewer.AutoRotate = true
			
		end})
		context:Register("DISABLE_AUTO_ROTATE",{Name = "Disable Auto Rotate", OnClick = function()
			ModelViewer.AutoRotate = false
		end})
		context:Register("LOCK_CAM",{Name = "Lock Camera", OnClick = function()
			ModelViewer.EnableInputCamera = false
		end})
		context:Register("UNLOCK_CAM",{Name = "Unlock Camera", OnClick = function()
			ModelViewer.EnableInputCamera = true
		end})
		
		context:Register("ZOOM_IN",{Name = "Zoom In", OnClick = function()
			distance = math.clamp(distance - (ModelViewer.ZoomMultiplier * 2), 2, math.huge)
		end})
		
		context:Register("ZOOM_OUT",{Name = "Zoom Out", OnClick = function()
			distance = math.clamp(distance + (ModelViewer.ZoomMultiplier * 2), 2, math.huge)
		end})
		
		local function ShowContext()
			context:Clear()

			context:AddRegistered("STOP", not ModelViewer.IsViewing)	
			context:AddRegistered("REFRESH", not ModelViewer.IsViewing)
			context:AddRegistered("COPY_PATH", not ModelViewer.IsViewing)
			context:AddRegistered("SAVE_INST", not ModelViewer.IsViewing)
			context:AddDivider()
			
			if env.isonmobile then
				context:AddRegistered("ZOOM_IN")
				context:AddRegistered("ZOOM_OUT")
				context:AddDivider()
			end

			if ModelViewer.AutoRotate then
				context:AddRegistered("DISABLE_AUTO_ROTATE")
			else
				context:AddRegistered("ENABLE_AUTO_ROTATE")
			end
			if ModelViewer.AutoRefresh then
				context:AddRegistered("DISABLE_AUTO_REFRESH")
			else
				context:AddRegistered("ENABLE_AUTO_REFRESH")
			end
			if ModelViewer.EnableInputCamera then
				context:AddRegistered("LOCK_CAM")
			else
				context:AddRegistered("UNLOCK_CAM")
			end

			context:AddDivider()

			context:AddRegistered("EXIT")

			context:Show()
		end
		
		local function HideContext()
			context:Hide()
		end
		
		trackConn(viewportFrame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				ShowContext()
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 and Lib.CheckMouseInGui(context.Gui) then
				HideContext()
			end
		end))
		trackConn(settingsButton.MouseButton1Click:Connect(function()
			ShowContext()
		end))
	end

	return ModelViewer
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
