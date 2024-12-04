if (not isfolder) or (not makefolder) or (not isfile) or (not delfile) or (not listfiles) then return end -- poo executors cant use im sry

if (not isfolder('ExecutorProfiles')) then makefolder('ExecutorProfiles') end

local function issetting(setting)
    assert(typeof(setting) == 'string', ('bad argument #1 to %q, expected %q got %q'):format('issetting', typeof(setting), 'string'))
    return isfolder('ExecutorProfiles\\' .. setting)
end

local function isprofile(setting, profile)
    assert(typeof(setting) == 'string', ('bad argument #1 to %q, expected %q got %q'):format('isprofile', typeof(setting), 'string'))
    assert(typeof(profile) == 'string', ('bad argument #2 to %q, expected %q got %q'):format('isprofile', typeof(profile), 'string'))

    if issetting(setting) then
        return isfile('ExecutorProfiles\\' .. setting .. '\\' .. profile .. '.profile')
    end
end

local function writeprofile(setting, profile, data)
    assert(typeof(setting) == 'string', ('bad argument #1 to %q, expected %q got %q'):format('writeprofile', typeof(setting), 'string'))
    assert(typeof(profile) == 'string', ('bad argument #2 to %q, expected %q got %q'):format('writeprofile', typeof(profile), 'string'))
    assert(typeof(data) == 'string', ('bad argument #3 to %q, expected %q got %q'):format('writeprofile', typeof(data), 'string'))

    if (not issetting(setting)) then
        makefolder('ExecutorProfiles\\' .. setting)
    end

    writefile('ExecutorProfiles\\' .. setting .. '\\' .. profile .. '.profile', data)
end

local function getprofile(setting, profile)
    assert(typeof(setting) == 'string', ('bad argument #1 to %q, expected %q got %q'):format('getprofile', typeof(setting), 'string'))
    assert(typeof(profile) == 'string', ('bad argument #2 to %q, expected %q got %q'):format('getprofile', typeof(profile), 'string'))

    if isprofile(setting, profile) then
        return readfile('ExecutorProfiles\\' .. setting .. '\\' .. profile .. '.profile')
    end
end

local function deletesetting(setting)
    assert(typeof(setting) == 'string', ('bad argument #1 to %q, expected %q got %q'):format('deletesetting', typeof(setting), 'string'))

    if issetting(setting) then
        return delfolder('ExecutorProfiles\\' .. setting)
    end
    
    return error('error deleting the specified setting!')
end

local function deleteprofile(setting, profile)
    assert(typeof(setting) == 'string', ('bad argument #1 to %q, expected %q got %q'):format('deleteprofile', typeof(setting), 'string'))

    if isprofile(setting, profile) then
        return delfile('ExecutorProfiles\\' .. setting .. '\\' .. profile .. '.profile')
    end
    
    return error('error deleting the specified profile!')
end

local function getsettingprofiles(setting)
    assert(typeof(setting) == 'string', ('bad argument #1 to %q, expected %q got %q'):format('getsettingprofiles', typeof(setting), 'string'))

    if issetting(setting) then
        local path = ('ExecutorProfiles\\' .. setting)
        local s, list = pcall(listfiles, path) -- synapse has stupid error with unicode / emoji file names
        
        for i = 1, #list do
            if type(list[i]) == 'string' then
                list[i] = list[i]:gsub(path, '')
            end
        end

        return list
    end

    return {}
end

local environment = getgenv()
environment.issetting = issetting
environment.isprofile = isprofile

environment.readprofile = getprofile
environment.getprofile = getprofile

environment.writeprofile = writeprofile

environment.deletesetting = deletesetting
environment.deleteprofile = deleteprofile

environment.getsettingprofiles = getsettingprofiles
