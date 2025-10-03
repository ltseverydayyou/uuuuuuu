if getgenv().NamelessAPI then
    return
end

local function getExecutor()
    if is_protosmasher_caller then
        return 0
    end
    if elysianexecute then
        return 1
    end
    if fullaccess then
        return 2
    end
    if Synapse then
        return 3
    end
    return 4
end

if getExecutor() == 2 then
    error('na-api: Exploit not supported')
end

local getHooks, setHooks, callHooks = {}, {}, {}
local globalGetHooks, globalSetHooks, globalCallHooks = {}, {}, {}
local propertyTypes, propertyValues = {}, {}

local rawmeta = getrawmetatable(game)
local oldIndex = rawmeta.__index
local oldNew = rawmeta.__newindex
local oldName = rawmeta.__namecall

if getExecutor() == 0 then
    make_writeable(rawmeta)
else
    setreadonly(rawmeta, false)
end

rawmeta.__index = newcclosure(function(obj, key)
    if getHooks[obj] and getHooks[obj][key] then
        local h = getHooks[obj][key]
        return h.IsCallback and h.Value(obj) or h.Value
    end
    if globalGetHooks[key] then
        local h = globalGetHooks[key]
        return h.IsCallback and h.Value(obj) or h.Value
    end
    if propertyTypes[obj] and propertyTypes[obj][key] then
        return propertyValues[obj][key]
    end
    return oldIndex(obj, key)
end)

rawmeta.__newindex = newcclosure(function(obj, key, val)
    if setHooks[obj] and setHooks[obj][key] then
        local h = setHooks[obj][key]
        if h.Callback then
            h.Callback(obj, val)
        end
        return
    end
    if globalSetHooks[key] then
        local h = globalSetHooks[key]
        if h.Callback then
            h.Callback(obj, val)
        end
        return
    end
    if propertyTypes[obj] and propertyTypes[obj][key] then
        local t = propertyTypes[obj][key].Type
        if typeof(val) ~= t then
            error(
                "bad argument #3 to '"
                    .. key
                    .. "' ("
                    .. t
                    .. ' expected, got '
                    .. typeof(val)
                    .. ')'
            )
        end
        propertyValues[obj][key] = val
        return
    end
    return oldNew(obj, key, val)
end)

rawmeta.__namecall = newcclosure(function(obj, ...)
    local method = getnamecallmethod()
    local args = { ... }

    if method == 'AddGetHook' then
        local _, prop, val, isCb = obj, table.unpack(args)
        getHooks[obj] = getHooks[obj] or {}
        getHooks[obj][prop] = { Value = val, IsCallback = isCb }
        local r = function()
            getHooks[obj][prop] = nil
        end
        return { remove = r, Remove = r }
    end

    if method == 'AddGlobalGetHook' then
        local prop, val, isCb = table.unpack(args)
        globalGetHooks[prop] = { Value = val, IsCallback = isCb }
        local r = function()
            globalGetHooks[prop] = nil
        end
        return { remove = r, Remove = r }
    end

    if method == 'AddSetHook' then
        local _, prop, cb = obj, table.unpack(args)
        setHooks[obj] = setHooks[obj] or {}
        setHooks[obj][prop] = { Callback = cb }
        local r = function()
            setHooks[obj][prop] = nil
        end
        return { remove = r, Remove = r }
    end

    if method == 'AddGlobalSetHook' then
        local prop, cb = table.unpack(args)
        globalSetHooks[prop] = { Callback = cb }
        local r = function()
            globalSetHooks[prop] = nil
        end
        return { remove = r, Remove = r }
    end

    if method == 'AddCallHook' then
        local _, name, cb = obj, table.unpack(args)
        callHooks[obj] = callHooks[obj] or {}
        callHooks[obj][name] = { Callback = cb }
        local r = function()
            callHooks[obj][name] = nil
        end
        return { remove = r, Remove = r }
    end

    if method == 'AddGlobalCallHook' then
        local name, cb = table.unpack(args)
        globalCallHooks[name] = { Callback = cb }
        local r = function()
            globalCallHooks[name] = nil
        end
        return { remove = r, Remove = r }
    end

    if method == 'AddPropertyEmulator' then
        local _, prop = obj, table.unpack(args)
        local v = oldIndex(obj, prop)
        propertyTypes[obj] = propertyTypes[obj] or {}
        propertyValues[obj] = propertyValues[obj] or {}
        propertyTypes[obj][prop] = { Type = typeof(v) }
        propertyValues[obj][prop] = v
        local r = function()
            propertyTypes[obj][prop] = nil
            propertyValues[obj][prop] = nil
        end
        return { remove = r, Remove = r }
    end

    if callHooks[obj] and callHooks[obj][method] then
        return callHooks[obj][method].Callback(
            oldIndex(obj, method),
            table.unpack(args)
        )
    end

    if globalCallHooks[method] then
        return globalCallHooks[method].Callback(
            obj,
            oldIndex(obj, method),
            table.unpack(args)
        )
    end

    return oldName(obj, ...)
end)

setreadonly(rawmeta, true)
getgenv().NamelessAPI = true