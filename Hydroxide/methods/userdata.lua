local function __betterGetService(name)
	local service = game:FindService(name)
	if service then
		return service
	end
	local ok, inst = pcall(Instance.new, name)
	if ok and inst and typeof(inst) == "Instance" then
		return inst
	end
	return nil
end
local methods = {}

local players = __betterGetService("Players")
local client = players.LocalPlayer

local function formatLuaString(value)
    return tostring(value)
        :gsub("\\", "\\\\")
        :gsub("\"", "\\\"")
        :gsub("\n", "\\n")
        :gsub("\r", "\\r")
        :gsub("\t", "\\t")
end

local function getInstancePath(instance)
    local path = ""
    local cur = instance

    while cur do
        if cur == game then
            path = "game" .. path
            break
        end

        local className = cur.ClassName
        local curName = tostring(cur)
        local indexName

        if curName:match("^[%a_][%w_]*$") then
            indexName = "." .. curName
        else
            indexName = "[\"" .. formatLuaString(curName) .. "\"]"
        end

        if cur == client then
            indexName = ".LocalPlayer"
        end

        local parent = cur.Parent
        if parent then
            if parent == game then
                local service = game:FindService(className)
                if service and service == cur then
                    indexName = ':GetService("' .. className .. '")'
                end
            else
                local first = parent:FindFirstChild(curName)
                if first and first ~= cur then
                    local children = parent:GetChildren()
                    local idx = table.find(children, cur)
                    if idx then
                        indexName = ":GetChildren()[" .. idx .. "]"
                    end
                end
            end
        else
            local getnil = "local getNil = function(name, class) for _, v in next, getnilinstances() do if v.ClassName == class and v.Name == name then return v end end end"
            indexName = getnil .. ("\n\ngetNil(\"%s\", \"%s\")"):format(formatLuaString(cur.Name), className)
        end

        path = indexName .. path
        cur = parent
    end

    return path
end

local function userdataValue(data)
    local dataType = typeof(data)

    if dataType == "userdata" then
        return "aux.placeholderUserdataConstant"
    elseif dataType == "Instance" then
        return data.Name
    elseif dataType == "BrickColor" then
        return dataType .. ".new(\"" .. tostring(data) .. "\")"
    elseif
        dataType == "TweenInfo" or
        dataType == "Vector3" or
        dataType == "Vector2" or
        dataType == "CFrame" or
        dataType == "Color3" or
        dataType == "Random" or
        dataType == "Faces" or
        dataType == "UDim2" or
        dataType == "UDim" or
        dataType == "Rect" or
        dataType == "Axes" or
        dataType == "NumberRange" or
        dataType == "RaycastParams" or
        dataType == "PhysicalProperties"
    then
        return dataType .. ".new(" .. tostring(data) .. ")"
    elseif dataType == "DateTime" then
        return dataType .. ".now()"
    elseif dataType == "PathWaypoint" then
        local split = tostring(data):split('}, ')
        local vector = split[1]:gsub('{', "Vector3.new(")
        return dataType .. ".new(" .. vector .. "), " .. split[2] .. ')'
    elseif dataType == "Ray" or dataType == "Region3" then
        local split = tostring(data):split('}, ')
        local vprimary = split[1]:gsub('{', "Vector3.new(")
        local vsecondary = split[2]:gsub('{', "Vector3.new("):gsub('}', ')')
        return dataType .. ".new(" .. vprimary .. "), " .. vsecondary .. ')'
    elseif dataType == "ColorSequence" or dataType == "NumberSequence" then 
        return dataType .. ".new(" .. tableToString(data.Keypoints) .. ')'
    elseif dataType == "ColorSequenceKeypoint" then
        return "ColorSequenceKeypoint.new(" .. data.Time .. ", Color3.new(" .. tostring(data.Value) .. "))"
    elseif dataType == "NumberSequenceKeypoint" then
        local envelope = data.Envelope and data.Value .. ", " .. data.Envelope or data.Value
        return "NumberSequenceKeypoint.new(" .. data.Time .. ", " .. envelope .. ")"
    end

    return tostring(data)
end

local function isUserdata(type)
    return type == "BrickColor"
        or type == "TweenInfo"
        or type == "Instance"
        or type == "DateTime"
        or type == "Vector3" 
        or type == "Vector2"
        or type == "Region3"
        or type == "CFrame"
        or type == "Color3"
        or type == "Random"
        or type == "Faces"
        or type == "UDim2"
        or type == "UDim"
        or type == "Rect"
        or type == "Axes"
        or type == "Ray"
        or type == "RaycastParams"
        or type == "PathWaypoint"
        or type == "PhysicalProperties"
        or type == "ColorSequence"
        or type == "ColorSequenceKeypoint"
        or type == "NumberRange"
        or type == "NumberSequence"
        or type == "NumberSequenceKeypoint"
end

methods.isUserdata = isUserdata
methods.userdataValue = userdataValue
methods.getInstancePath = getInstancePath
return methods
