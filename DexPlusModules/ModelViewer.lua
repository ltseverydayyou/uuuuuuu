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
		RefreshRate = 30, -- hertz
		ParticlePreviewMaxEmitters = 10,
		ParticlePreviewMaxParticles = 55,
		ParticlePreviewMaxSpawnPerFrame = 6,
		ParticlePreviewRateScale = 0.12,
		ParticlePreviewMaxRatePerEmitter = 30,
		ParticlePreviewMaxPixelSize = 42,
	}
	
	local window, viewportFrame, particleOverlay, pathLabel, settingsButton
	local model, camera, originalModel
	local particleEmitters = {}
	local previewParticles = {}
	local random = Random.new()

	local function queryDescendants(root)
		if not root then return {} end

		local okQuery, result = pcall(function()
			return root:QueryDescendants("Instance")
		end)
		if okQuery and type(result) == "table" then
			return result
		end

		local okFallback, fallback = pcall(function()
			return root:QueryDescendants("Instance")
		end)
		if okFallback and type(fallback) == "table" then
			return fallback
		end

		return {}
	end

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
		for _, child in queryDescendants(item) do
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
		if particleOverlay then
			particleOverlay:ClearAllChildren()
		end
		particleEmitters = {}
		previewParticles = {}
	end

	local function isClass(item, className)
		local ok, result = pcall(function()
			return item:IsA(className)
		end)
		return ok and result
	end

	local function sampleRange(range, fallback)
		if typeof(range) == "NumberRange" then
			return random:NextNumber(range.Min, range.Max)
		end
		return fallback or 0
	end

	local function sampleSequence(sequence, alpha, fallback)
		if typeof(sequence) ~= "NumberSequence" then
			return fallback or 0
		end

		local keypoints = sequence.Keypoints
		if #keypoints == 0 then
			return fallback or 0
		end
		if alpha <= keypoints[1].Time then
			return keypoints[1].Value
		end

		for i = 2, #keypoints do
			local previous = keypoints[i - 1]
			local current = keypoints[i]

			if alpha <= current.Time then
				local span = current.Time - previous.Time
				local t = span > 0 and ((alpha - previous.Time) / span) or 0
				return previous.Value + ((current.Value - previous.Value) * t)
			end
		end

		return keypoints[#keypoints].Value
	end

	local function sampleColor(sequence, alpha, fallback)
		if typeof(sequence) ~= "ColorSequence" then
			return fallback or Color3.new(1, 1, 1)
		end

		local keypoints = sequence.Keypoints
		if #keypoints == 0 then
			return fallback or Color3.new(1, 1, 1)
		end
		if alpha <= keypoints[1].Time then
			return keypoints[1].Value
		end

		for i = 2, #keypoints do
			local previous = keypoints[i - 1]
			local current = keypoints[i]

			if alpha <= current.Time then
				local span = current.Time - previous.Time
				local t = span > 0 and ((alpha - previous.Time) / span) or 0
				return previous.Value:Lerp(current.Value, t)
			end
		end

		return keypoints[#keypoints].Value
	end

	local function getEmitterOrigin(emitter)
		local parent = emitter and emitter.Parent
		if not parent then
			return Vector3.zero
		end

		if parent:IsA("Attachment") then
			return parent.WorldPosition
		elseif parent:IsA("BasePart") then
			return parent.Position
		end

		local part = emitter:FindFirstAncestorWhichIsA("BasePart")
		if part then
			return part.Position
		end

		return model and model.PrimaryPart and model.PrimaryPart.Position or Vector3.zero
	end

	local function getEmitterDirection(emitter)
		local parent = emitter and emitter.Parent
		local cf = CFrame.new()

		if parent then
			if parent:IsA("Attachment") then
				cf = parent.WorldCFrame
			elseif parent:IsA("BasePart") then
				cf = parent.CFrame
			end
		end

		local baseDirection = cf.LookVector
		pcall(function()
			if emitter.EmissionDirection == Enum.NormalId.Top then
				baseDirection = cf.UpVector
			elseif emitter.EmissionDirection == Enum.NormalId.Bottom then
				baseDirection = -cf.UpVector
			elseif emitter.EmissionDirection == Enum.NormalId.Front then
				baseDirection = -cf.LookVector
			elseif emitter.EmissionDirection == Enum.NormalId.Back then
				baseDirection = cf.LookVector
			elseif emitter.EmissionDirection == Enum.NormalId.Right then
				baseDirection = cf.RightVector
			elseif emitter.EmissionDirection == Enum.NormalId.Left then
				baseDirection = -cf.RightVector
			end
		end)

		local spread = Vector2.zero
		pcall(function()
			spread = emitter.SpreadAngle
		end)

		local yaw = math.rad(random:NextNumber(-spread.X, spread.X))
		local pitch = math.rad(random:NextNumber(-spread.Y, spread.Y))
		return (CFrame.lookAt(Vector3.zero, baseDirection) * CFrame.Angles(pitch, yaw, 0)).LookVector
	end

	local function makeParticleGui(texture)
		local gui

		if type(texture) == "string" and texture ~= "" then
			gui = Instance.new("ImageLabel")
			gui.BackgroundTransparency = 1
			gui.Image = texture
			gui.ScaleType = Enum.ScaleType.Fit
		else
			gui = Instance.new("Frame")
			gui.BackgroundColor3 = Color3.new(1, 1, 1)
			gui.BorderSizePixel = 0

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = gui
		end

		gui.AnchorPoint = Vector2.new(0.5, 0.5)
		gui.Position = UDim2.new(0.5, 0, 0.5, 0)
		gui.Size = UDim2.new(0, 8, 0, 8)
		gui.ZIndex = particleOverlay.ZIndex + 1
		gui.Visible = false
		gui.Parent = particleOverlay
		return gui
	end

	local function emitPreviewParticle(emitter, count)
		if not particleOverlay then return end
		local remaining = ModelViewer.ParticlePreviewMaxParticles - #previewParticles
		if remaining <= 0 then return 0 end

		local texture = ""
		local lifetime = NumberRange.new(1)
		local speed = NumberRange.new(2)
		local color = ColorSequence.new(Color3.new(1, 1, 1))
		local size = NumberSequence.new(1)
		local transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})

		pcall(function() texture = emitter.Texture end)
		pcall(function() lifetime = emitter.Lifetime end)
		pcall(function() speed = emitter.Speed end)
		pcall(function() color = emitter.Color end)
		pcall(function() size = emitter.Size end)
		pcall(function() transparency = emitter.Transparency end)

		count = math.clamp(count or 1, 1, remaining)

		for _ = 1, count do
			local life = math.clamp(sampleRange(lifetime, 1), 0.08, 1.25)
			local velocity = getEmitterDirection(emitter) * math.min(sampleRange(speed, 2), 12)
			local gui = makeParticleGui(texture)

			table.insert(previewParticles, {
				Emitter = emitter,
				Gui = gui,
				Position = getEmitterOrigin(emitter),
				Velocity = velocity,
				Age = 0,
				Life = life,
				Color = color,
				Size = size,
				Transparency = transparency,
			})
		end

		return count
	end

	local function updateParticleGui(particle)
		if not camera or not particleOverlay then return end

		local size = particleOverlay.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then return end

		local cameraPoint = camera.CFrame:PointToObjectSpace(particle.Position)
		if cameraPoint.Z >= -0.05 then
			particle.Gui.Visible = false
			return
		end

		local yScale = 0.5 / math.tan(math.rad(camera.FieldOfView) / 2)
		local xScale = yScale * (size.Y / size.X)
		local screenX = 0.5 + ((cameraPoint.X / -cameraPoint.Z) * xScale)
		local screenY = 0.5 - ((cameraPoint.Y / -cameraPoint.Z) * yScale)

		if screenX < -0.1 or screenX > 1.1 or screenY < -0.1 or screenY > 1.1 then
			particle.Gui.Visible = false
			return
		end

		local alpha = math.clamp(particle.Age / particle.Life, 0, 1)
		local particleSize = sampleSequence(particle.Size, alpha, 1)
		local pixelSize = math.clamp((particleSize * 12) / math.max(-cameraPoint.Z / 8, 0.35), 2, ModelViewer.ParticlePreviewMaxPixelSize)
		local particleColor = sampleColor(particle.Color, alpha, Color3.new(1, 1, 1))
		local particleTransparency = math.clamp(sampleSequence(particle.Transparency, alpha, 0), 0, 1)

		particle.Gui.Position = UDim2.new(screenX, 0, screenY, 0)
		particle.Gui.Size = UDim2.new(0, pixelSize, 0, pixelSize)
		if particle.Gui:IsA("ImageLabel") then
			particle.Gui.ImageColor3 = particleColor
			particle.Gui.ImageTransparency = particleTransparency
		else
			particle.Gui.BackgroundColor3 = particleColor
			particle.Gui.BackgroundTransparency = particleTransparency
		end
		particle.Gui.Visible = true
	end

	local function preparePreview(root, forceEffects)
		if not root then return end
		local items = queryDescendants(root)
		table.insert(items, root)

		for _, child in items do
			if child:IsA("BasePart") then
				child.Anchored = true
			elseif child:IsA("ParticleEmitter") then
				if #particleEmitters >= ModelViewer.ParticlePreviewMaxEmitters then
					child.Enabled = false
					continue
				end

				local previewEnabled = true
				pcall(function()
					previewEnabled = child.Enabled
				end)
				if forceEffects then
					previewEnabled = true
				end
				child.Enabled = false

				table.insert(particleEmitters, {
					Emitter = child,
					Accumulator = 0,
					Enabled = previewEnabled,
				})

				local emitCount = 2
				pcall(function()
					emitCount = math.clamp(math.floor(math.min(child.Rate, ModelViewer.ParticlePreviewMaxRatePerEmitter) * 0.08), 1, 4)
				end)
				if previewEnabled then
					emitPreviewParticle(child, emitCount)
				end
			elseif isClass(child, "Beam") or isClass(child, "Trail") or isClass(child, "Fire") or isClass(child, "Smoke") or isClass(child, "Sparkles") then
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
					for _, child in queryDescendants(model) do
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

		particleOverlay = Instance.new("Frame")
		particleOverlay.Parent = window.GuiElems.Content
		particleOverlay.BackgroundTransparency = 1
		particleOverlay.ClipsDescendants = true
		particleOverlay.Size = UDim2.new(1,0,1,0)
		particleOverlay.ZIndex = viewportFrame.ZIndex + 1
		
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
				elseif particleData.Enabled then
					local emitRate = 0
					pcall(function()
						emitRate = emitter.Rate
					end)
					emitRate = math.min(emitRate, ModelViewer.ParticlePreviewMaxRatePerEmitter) * ModelViewer.ParticlePreviewRateScale

					if emitRate > 0 then
						particleData.Accumulator += emitRate * dt
						local emitCount = math.floor(particleData.Accumulator)

						if emitCount > 0 then
							particleData.Accumulator -= emitCount
							emitPreviewParticle(emitter, math.min(emitCount, ModelViewer.ParticlePreviewMaxSpawnPerFrame))
						end
					end
				end
			end

			for i = #previewParticles, 1, -1 do
				local particle = previewParticles[i]

				if not particle.Gui or not particle.Gui.Parent or not particle.Emitter or not particle.Emitter.Parent then
					if particle.Gui then
						particle.Gui:Destroy()
					end
					table.remove(previewParticles, i)
				else
					particle.Age += dt

					if particle.Age >= particle.Life then
						particle.Gui:Destroy()
						table.remove(previewParticles, i)
					else
						particle.Position += particle.Velocity * dt
						updateParticleGui(particle)
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
