local MODEL = workspace.Model
local FLIP_AXIS = "X"

local AXIS_VECTORS = {
	X = Vector3.xAxis,
	Y = Vector3.yAxis,
	Z = Vector3.zAxis,
}

local AXIS_NAMES = { "X", "Y", "Z" }

local function assertAxis(axis)
	if not AXIS_VECTORS[axis] then
		error(string.format("Invalid flip axis %q; expected X, Y, or Z", tostring(axis)), 3)
	end
end

local function reflectVector(vector, axis)
	if axis == "X" then
		return Vector3.new(-vector.X, vector.Y, vector.Z)
	elseif axis == "Y" then
		return Vector3.new(vector.X, -vector.Y, vector.Z)
	end

	return Vector3.new(vector.X, vector.Y, -vector.Z)
end

local function reflectPoint(point, center, axis)
	return center + reflectVector(point - center, axis)
end

local function getModelCenter(model)
	local boundingCFrame = model:GetBoundingBox()
	return boundingCFrame.Position
end

local function getExtentsCenter(part)
	local success, extentsCFrame = pcall(function()
		return part.ExtentsCFrame
	end)

	if success and typeof(extentsCFrame) == "CFrame" then
		return extentsCFrame.Position
	end

	return part.Position
end

local function getLocalCenterOfMass(part, fallback)
	local success, centerOfMass = pcall(function()
		return part.CenterOfMass
	end)

	if success and typeof(centerOfMass) == "Vector3" then
		return centerOfMass
	end

	return fallback
end

local function makeReflectedRotation(sourceCFrame, worldAxis, localCorrectionAxis)
	local xVector = reflectVector(sourceCFrame.XVector, worldAxis)
	local yVector = reflectVector(sourceCFrame.YVector, worldAxis)
	local zVector = reflectVector(sourceCFrame.ZVector, worldAxis)

	if localCorrectionAxis == "X" then
		xVector = -xVector
	elseif localCorrectionAxis == "Y" then
		yVector = -yVector
	else
		zVector = -zVector
	end

	return CFrame.fromMatrix(Vector3.zero, xVector, yVector, zVector)
end

local function getAlignmentScore(sourceCFrame, worldAxis, localAxis)
	local worldNormal = AXIS_VECTORS[worldAxis]

	if localAxis == "X" then
		return math.abs(sourceCFrame.XVector:Dot(worldNormal))
	elseif localAxis == "Y" then
		return math.abs(sourceCFrame.YVector:Dot(worldNormal))
	end

	return math.abs(sourceCFrame.ZVector:Dot(worldNormal))
end

local function buildCandidate(source, center, localCorrectionAxis)
	local rotation = makeReflectedRotation(source.cframe, FLIP_AXIS, localCorrectionAxis)
	local targetExtentsCenter = reflectPoint(source.extentsCenter, center, FLIP_AXIS)
	local targetOrigin = targetExtentsCenter - rotation:VectorToWorldSpace(source.localExtentsCenter)
	local targetCFrame = CFrame.new(targetOrigin) * rotation

	local targetCenterOfMass = targetCFrame:PointToWorldSpace(source.localCenterOfMass)
	local centerOfMassError = (targetCenterOfMass - source.targetCenterOfMass).Magnitude
	local alignment = getAlignmentScore(source.cframe, FLIP_AXIS, localCorrectionAxis)

	local score = centerOfMassError + ((1 - alignment) * 1e-4)

	return targetCFrame, score
end

local function getTarget(part, center)
	local sourceCFrame = part.CFrame
	local extentsCenter = getExtentsCenter(part)
	local localExtentsCenter = sourceCFrame:PointToObjectSpace(extentsCenter)
	local localCenterOfMass = getLocalCenterOfMass(part, localExtentsCenter)
	local worldCenterOfMass = sourceCFrame:PointToWorldSpace(localCenterOfMass)

	local source = {
		cframe = sourceCFrame,
		extentsCenter = extentsCenter,
		localExtentsCenter = localExtentsCenter,
		localCenterOfMass = localCenterOfMass,
		targetCenterOfMass = reflectPoint(worldCenterOfMass, center, FLIP_AXIS),
	}

	local forcedAxis = part:GetAttribute("FlipLocalAxis")
	if typeof(forcedAxis) == "string" then
		forcedAxis = string.upper(forcedAxis)
		if AXIS_VECTORS[forcedAxis] then
			local targetCFrame = buildCandidate(source, center, forcedAxis)
			return targetCFrame, forcedAxis
		end
	end

	local bestCFrame
	local bestAxis
	local bestScore = math.huge

	for _, localAxis in AXIS_NAMES do
		local candidateCFrame, candidateScore = buildCandidate(source, center, localAxis)

		if candidateScore < bestScore then
			bestScore = candidateScore
			bestCFrame = candidateCFrame
			bestAxis = localAxis
		end
	end

	return bestCFrame, bestAxis
end

local function flipFace(face, localAxis)
	if localAxis == "X" then
		if face == Enum.NormalId.Left then
			return Enum.NormalId.Right
		elseif face == Enum.NormalId.Right then
			return Enum.NormalId.Left
		end
	elseif localAxis == "Y" then
		if face == Enum.NormalId.Top then
			return Enum.NormalId.Bottom
		elseif face == Enum.NormalId.Bottom then
			return Enum.NormalId.Top
		end
	elseif localAxis == "Z" then
		if face == Enum.NormalId.Front then
			return Enum.NormalId.Back
		elseif face == Enum.NormalId.Back then
			return Enum.NormalId.Front
		end
	end

	return face
end

local function reflectLocalCFrame(localCFrame, parentMirrorAxis)
	local position = reflectVector(localCFrame.Position, parentMirrorAxis)
	local bestAxis = "X"
	local bestAlignment = -math.huge
	local mirrorNormal = AXIS_VECTORS[parentMirrorAxis]

	for _, candidateAxis in AXIS_NAMES do
		local basisVector
		if candidateAxis == "X" then
			basisVector = localCFrame.XVector
		elseif candidateAxis == "Y" then
			basisVector = localCFrame.YVector
		else
			basisVector = localCFrame.ZVector
		end

		local alignment = math.abs(basisVector:Dot(mirrorNormal))
		if alignment > bestAlignment then
			bestAlignment = alignment
			bestAxis = candidateAxis
		end
	end

	local rotation = makeReflectedRotation(localCFrame, parentMirrorAxis, bestAxis)
	return CFrame.new(position) * rotation
end

local function flipPartChildren(part, localMirrorAxis)
	for _, child in part:GetDescendants() do
		if child:IsA("Texture") or child:IsA("Decal") or child:IsA("SurfaceGui") then
			child.Face = flipFace(child.Face, localMirrorAxis)
		elseif child:IsA("Attachment") then
			child.CFrame = reflectLocalCFrame(child.CFrame, localMirrorAxis)
		end
	end
end

local function flipModel(model)
	assertAxis(FLIP_AXIS)

	local center = getModelCenter(model)
	local targets = {}

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			local targetCFrame, localMirrorAxis = getTarget(descendant, center)
			table.insert(targets, {
				part = descendant,
				cframe = targetCFrame,
				localMirrorAxis = localMirrorAxis,
			})
		end
	end

	for _, target in targets do
		target.part.CFrame = target.cframe
	end

	for _, target in targets do
		flipPartChildren(target.part, target.localMirrorAxis)
	end
end

flipModel(MODEL)
