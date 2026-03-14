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
local client = __betterGetService("Players").LocalPlayer
local control = client.PlayerScripts:FindFirstChild("Control Script")

local methods = {}

local function secureCall(closure, ...)
    local env = getfenv(1)
    local renv = getrenv()
    local results
    
    setfenv(1, setmetatable({ script = script }, {
        __index = renv
    }))

    results = (syn and { syn.secure_call(closure, control, ...) }) or { closure(...) }

    setfenv(1, env)

    return unpack(results)
end

methods.secureCall = secureCall
return methods
