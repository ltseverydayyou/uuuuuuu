local CONFIG = {
    Timeout = 7,
    TestProtectedMethodBypasses = true,
    TestAuthenticatedRobloxHttp = true,
    TestFilesystemEscape = true,
    TestNativeHostAccess = true,
    PrintCapabilityInventory = true,
}

local ICON_SAFE = "✅"
local ICON_UNSAFE = "⛔"
local ICON_UNKNOWN = "⏺️"
local ICON_INFO = "ℹ️"

local AUTH_URL = "https://users.roblox.com/v1/users/authenticated"
local NONCE = tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
local PROBE_DIR = "VulnTestProbe_" .. NONCE
local PROBE_MARKER = "VULNTEST_MARKER_" .. NONCE

local Environment = _G
if type(getgenv) == "function" then
    local ok, executorEnvironment = pcall(getgenv)
    if ok and type(executorEnvironment) == "table" then
        Environment = executorEnvironment
    end
end

local Results = {
    Safe = 0,
    Unsafe = 0,
    Unknown = 0,
    Info = 0,
    RiskTotal = 0,
    RiskFailed = 0,
    Findings = {},
}

local SeverityWeight = {
    critical = 5,
    high = 3,
    medium = 2,
    low = 1,
    info = 0,
}

local function getGlobal(name)
    local value = rawget(Environment, name)
    if value ~= nil then
        return value
    end
    return rawget(_G, name)
end

local function getService(dataModel, name)
    local root = dataModel or game
    if name == "DataModel" then
        return root
    end
    local ok, service = pcall(function()
        return root:GetService(name)
    end)
    if ok and typeof(service) == "Instance" then
        return service
    end
    return nil, service
end

local function shortValue(value)
    local valueType = typeof(value)
    if value == nil then
        return "nil"
    elseif valueType == "string" then
        return "string(length=" .. tostring(#value) .. ")"
    elseif valueType == "table" then
        local count = 0
        for _ in value do
            count += 1
            if count >= 1000 then
                break
            end
        end
        return "table(keys=" .. tostring(count) .. ")"
    end
    return valueType
end

local function lowerError(value)
    return string.lower(tostring(value or ""))
end

local function containsAny(text, patterns)
    for _, pattern in patterns do
        if string.find(text, pattern, 1, true) then
            return true
        end
    end
    return false
end

local BLOCK_PATTERNS = {
    "lacking capability",
    "lacking permission",
    "current thread cannot",
    "current identity",
    "permission denied",
    "not permitted",
    "not authorized",
    "not allowed",
    "not accessible",
    "cannot access",
    "cannot call restricted",
    "access denied",
    "security check",
    "insufficient permission",
    "insufficient privilege",
    "robloxscript security",
    "localuser security",
    "plugin security",
    "blocked by",
}

local ARGUMENT_PATTERNS = {
    "argument 1 missing",
    "argument 2 missing",
    "argument 3 missing",
    "missing or nil",
    "bad argument",
    "invalid argument",
    "expected",
    "unable to cast",
    "cannot convert",
    "requires an argument",
    "table expected",
    "string expected",
    "instance expected",
    "player expected",
}

local ABSENT_PATTERNS = {
    "is not a valid member",
    "attempt to call a nil value",
    "unknown global",
    "not available",
    "not supported",
    "does not exist",
    "could not find service",
}

local function classifyError(err)
    local text = lowerError(err)
    if containsAny(text, BLOCK_PATTERNS) then
        return "blocked"
    elseif containsAny(text, ABSENT_PATTERNS) then
        return "absent"
    elseif containsAny(text, ARGUMENT_PATTERNS) or string.find(text, "argument", 1, true) then
        return "argument"
    elseif string.find(text, "unauthorized", 1, true)
        or string.find(text, "authentication", 1, true)
        or string.find(text, "status code 401", 1, true)
        or string.find(text, "status code 403", 1, true) then
        return "unauthenticated"
    end
    return "other"
end

local function runWithTimeout(callback, timeout)
    local done = false
    local packed
    local thread = task.spawn(function()
        packed = table.pack(pcall(callback))
        done = true
    end)

    local deadline = os.clock() + (timeout or CONFIG.Timeout)
    local runService = getService(game, "RunService")
    while not done and os.clock() < deadline do
        if runService and runService.Heartbeat then
            runService.Heartbeat:Wait()
        else
            task.wait(0.05)
        end
    end

    if not done then
        if type(task.cancel) == "function" then
            pcall(task.cancel, thread)
        end
        return false, "timeout"
    end

    return true, table.unpack(packed, 1, packed.n)
end

local function addFinding(status, severity, name, message)
    local weight = SeverityWeight[severity] or 0
    if severity ~= "info" and (status == "safe" or status == "unsafe") then
        Results.RiskTotal += weight
    end

    if status == "safe" then
        Results.Safe += 1
        print(ICON_SAFE .. " [" .. string.upper(severity) .. "] " .. name .. " • " .. message)
    elseif status == "unsafe" then
        Results.Unsafe += 1
        Results.RiskFailed += weight
        table.insert(Results.Findings, {
            Severity = severity,
            Name = name,
            Message = message,
        })
        warn(ICON_UNSAFE .. " [" .. string.upper(severity) .. "] " .. name .. " • " .. message)
    elseif status == "info" then
        Results.Info += 1
        print(ICON_INFO .. " " .. name .. " • " .. message)
    else
        Results.Unknown += 1
        print(ICON_UNKNOWN .. " [" .. string.upper(severity) .. "] " .. name .. " • " .. message)
    end
end

local Tests = {}
local Inventory = {}

local function test(name, severity, callback)
    table.insert(Tests, {
        Name = name,
        Severity = severity,
        Callback = callback,
    })
end

local function inventory(name, callback)
    table.insert(Inventory, {
        Name = name,
        Callback = callback,
    })
end

local function findRequestFunction()
    local direct = getGlobal("request") or getGlobal("http_request")
    if type(direct) == "function" then
        return direct, "request/http_request"
    end

    local http = getGlobal("http")
    if type(http) == "table" and type(rawget(http, "request")) == "function" then
        return rawget(http, "request"), "http.request"
    end

    local syn = getGlobal("syn")
    if type(syn) == "table" and type(rawget(syn, "request")) == "function" then
        return rawget(syn, "request"), "syn.request"
    end

    return nil
end

local function getResponseBody(response)
    if type(response) == "string" then
        return response
    elseif type(response) == "table" then
        return response.Body or response.body or response.ResponseBody or response.responseBody
    end
    return nil
end

local function getResponseStatus(response)
    if type(response) ~= "table" then
        return nil
    end
    return tonumber(response.StatusCode or response.Status or response.status_code or response.status)
end

local function inspectAuthenticatedResponse(response)
    local body = getResponseBody(response)
    local statusCode = getResponseStatus(response)

    if statusCode == 401 or statusCode == 403 then
        return "safe", "Roblox rejected the request as unauthenticated (HTTP " .. tostring(statusCode) .. ")."
    end

    if type(body) ~= "string" or body == "" then
        return "unknown", "The request returned no inspectable response body."
    end

    local httpService = getService(game, "HttpService")
    if httpService then
        local ok, decoded = pcall(function()
            return httpService:JSONDecode(body)
        end)
        if ok and type(decoded) == "table" then
            local returnedId = tonumber(decoded.id or decoded.userId or decoded.UserId)
            local players = getService(game, "Players")
            local localPlayer = players and players.LocalPlayer
            if returnedId and localPlayer and returnedId == localPlayer.UserId then
                return "unsafe", "The call was authenticated as the current Roblox account (user ID matched)."
            elseif returnedId then
                return "unsafe", "The call returned an authenticated Roblox user identity."
            end
        end
    end

    local bodyLower = string.lower(body)
    if string.find(bodyLower, "unauthorized", 1, true)
        or string.find(bodyLower, "authentication credentials", 1, true)
        or string.find(bodyLower, "not authenticated", 1, true) then
        return "safe", "Roblox returned an unauthenticated response."
    end

    if statusCode and statusCode >= 200 and statusCode < 300 then
        return "unknown", "The call succeeded, but the response did not prove whether account credentials were attached."
    end

    return "unknown", "The response was inconclusive (HTTP " .. tostring(statusCode or "unknown") .. ")."
end

local function callRequestInternal(options)
    local httpService, serviceErr = getService(game, "HttpService")
    if not httpService then
        return "unknown", "HttpService is unavailable: " .. tostring(serviceErr)
    end

    local okCreate, requestObject = pcall(function()
        return httpService:RequestInternal(options)
    end)
    if not okCreate then
        local classification = classifyError(requestObject)
        if classification == "blocked" then
            return "safe", "RequestInternal was blocked by the executor/Roblox security boundary."
        elseif classification == "absent" then
            return "unknown", "RequestInternal is not exposed."
        elseif classification == "argument" then
            return "unsafe", "RequestInternal reached Roblox argument validation instead of being blocked."
        end
        return "unknown", "RequestInternal failed inconclusively: " .. tostring(requestObject)
    end

    if requestObject == nil then
        return "unknown", "RequestInternal returned nil."
    end

    local startMethod
    local okStartLookup, lookupResult = pcall(function()
        return requestObject.Start
    end)
    if okStartLookup then
        startMethod = lookupResult
    end
    if type(startMethod) ~= "function" then
        return "unsafe", "RequestInternal returned a request object, proving the restricted method is exposed, but no Start method was available for verification."
    end

    local done = false
    local callbackA
    local callbackB
    local okStart, startErr = pcall(function()
        startMethod(requestObject, function(a, b)
            callbackA = a
            callbackB = b
            done = true
        end)
    end)
    if not okStart then
        return "unsafe", "RequestInternal created a request object but starting it failed: " .. tostring(startErr)
    end

    local deadline = os.clock() + CONFIG.Timeout
    local runService = getService(game, "RunService")
    while not done and os.clock() < deadline do
        if runService and runService.Heartbeat then
            runService.Heartbeat:Wait()
        else
            task.wait(0.05)
        end
    end

    if not done then
        return "unsafe", "RequestInternal was exposed and started a request, but its callback timed out."
    end

    local response = callbackB
    if type(response) ~= "table" and type(response) ~= "string" then
        response = callbackA
    end

    local status, message = inspectAuthenticatedResponse(response)
    if status == "safe" then
        return "unsafe", "RequestInternal is exposed even though this particular request was not authenticated. " .. message
    elseif status == "unsafe" then
        return "unsafe", message
    end
    return "unsafe", "RequestInternal is exposed and completed a request, but authentication could not be conclusively verified."
end

local function acquireDataModelRoute(routeName)
    if routeName == "direct" then
        return game
    elseif routeName == "workspace.Parent" then
        local workspaceService = getService(game, "Workspace")
        return workspaceService and workspaceService.Parent or nil
    elseif routeName == "cloneref" then
        local cloneRef = getGlobal("cloneref")
        if type(cloneRef) == "function" then
            local ok, cloned = pcall(cloneRef, game)
            if ok then
                return cloned
            end
        end
    elseif routeName == "getrenv" then
        local getRealEnvironment = getGlobal("getrenv")
        if type(getRealEnvironment) == "function" then
            local ok, environment = pcall(getRealEnvironment)
            if ok and type(environment) == "table" then
                local direct = rawget(environment, "game")
                if direct ~= nil then
                    return direct
                end
                local okGame, environmentGame = pcall(function()
                    return environment.game
                end)
                if okGame then
                    return environmentGame
                end
            end
        end
    elseif routeName == "getfenv(print)" then
        local getFunctionEnvironment = getGlobal("getfenv")
        if type(getFunctionEnvironment) == "function" then
            local ok, environment = pcall(getFunctionEnvironment, print)
            if ok and type(environment) == "table" then
                local direct = rawget(environment, "game")
                if direct ~= nil then
                    return direct
                end
                local okGame, environmentGame = pcall(function()
                    return environment.game
                end)
                if okGame then
                    return environmentGame
                end
            end
        end
    end
    return nil
end

local function probeProtectedRoute(routeName, serviceName, methodName, arguments, cloneMethod)
    local dataModel = acquireDataModelRoute(routeName)
    if routeName == "null-byte GetService" then
        dataModel = game
    end
    if not dataModel then
        return "unsupported", routeName .. " route is unavailable."
    end

    local service
    local serviceErr
    if routeName == "null-byte GetService" then
        local okService, result = pcall(function()
            return dataModel:GetService(serviceName .. "\0")
        end)
        if okService and typeof(result) == "Instance" then
            service = result
        else
            return "unsupported", "Null-byte service-name route was rejected."
        end
    else
        service, serviceErr = getService(dataModel, serviceName)
    end
    if not service then
        return "unknown", routeName .. " could not obtain " .. serviceName .. ": " .. tostring(serviceErr)
    end

    local okMethod, methodOrErr = pcall(function()
        return service[methodName]
    end)
    if not okMethod or type(methodOrErr) ~= "function" then
        return "unknown", routeName .. " could not access " .. methodName .. "."
    end

    local method = methodOrErr
    if cloneMethod then
        local cloneFunction = getGlobal("clonefunction")
        if type(cloneFunction) ~= "function" then
            return "unsupported", "clonefunction is unavailable."
        end
        local okClone, cloned = pcall(cloneFunction, method)
        if not okClone or type(cloned) ~= "function" then
            return "unknown", "clonefunction failed for " .. serviceName .. "." .. methodName .. "."
        end
        method = cloned
    end

    local okCall, returnOrError = pcall(function()
        return method(service, table.unpack(arguments or {}))
    end)
    if okCall then
        if returnOrError == nil then
            return "unknown", routeName .. (cloneMethod and "+clonefunction" or "") .. " returned nil for invalid arguments. This may be a safe stub, but no blocking error proved it."
        end
        return "unsafe", routeName .. (cloneMethod and "+clonefunction" or "") .. " executed the restricted method with deliberately invalid arguments (return " .. shortValue(returnOrError) .. ")."
    end

    local classification = classifyError(returnOrError)
    if classification == "blocked" then
        return "safe", routeName .. (cloneMethod and "+clonefunction" or "") .. " was blocked before argument validation."
    elseif classification == "argument" then
        return "unsafe", routeName .. (cloneMethod and "+clonefunction" or "") .. " reached Roblox argument validation, so the security filter was bypassed."
    elseif classification == "absent" then
        return "unknown", routeName .. " does not expose the method."
    end
    return "unknown", routeName .. " failed inconclusively: " .. tostring(returnOrError)
end

local function probeProtectedMethod(serviceName, methodName, arguments)
    local routes = {"direct"}
    if CONFIG.TestProtectedMethodBypasses then
        table.insert(routes, "workspace.Parent")
        table.insert(routes, "cloneref")
        table.insert(routes, "getrenv")
        table.insert(routes, "getfenv(print)")
        table.insert(routes, "null-byte GetService")
    end

    local safeCount = 0
    local unknownCount = 0
    local details = {}
    for _, routeName in routes do
        local status, message = probeProtectedRoute(routeName, serviceName, methodName, arguments, false)
        if status == "unsafe" then
            return "unsafe", message
        elseif status == "safe" then
            safeCount += 1
        elseif status ~= "unsupported" then
            unknownCount += 1
            table.insert(details, message)
        end

        if routeName == "direct" and CONFIG.TestProtectedMethodBypasses then
            local cloneStatus, cloneMessage = probeProtectedRoute(routeName, serviceName, methodName, arguments, true)
            if cloneStatus == "unsafe" then
                return "unsafe", cloneMessage
            elseif cloneStatus == "safe" then
                safeCount += 1
            elseif cloneStatus ~= "unsupported" then
                unknownCount += 1
                table.insert(details, cloneMessage)
            end
        end
    end

    if safeCount > 0 and unknownCount == 0 then
        return "safe", "All available direct and alternate-reference routes were blocked before argument validation."
    elseif unknownCount > 0 then
        return "unknown", table.concat(details, " | ")
    end
    return "unknown", "No supported route could test this method."
end

local function countTableKeys(value)
    if type(value) ~= "table" then
        return 0
    end
    local count = 0
    for _ in value do
        count += 1
        if count >= 1000 then
            break
        end
    end
    return count
end

local function probeSecretMethod(serviceName, methodName, arguments)
    local service, serviceErr = getService(game, serviceName)
    if not service then
        return "unknown", serviceName .. " is unavailable: " .. tostring(serviceErr)
    end

    local okMethod, method = pcall(function()
        return service[methodName]
    end)
    if not okMethod or type(method) ~= "function" then
        return "unknown", methodName .. " is not exposed."
    end

    local okCall, result = pcall(function()
        return method(service, table.unpack(arguments or {}))
    end)
    if not okCall then
        local classification = classifyError(result)
        if classification == "blocked" then
            return "safe", methodName .. " was blocked by the security boundary."
        elseif classification == "absent" then
            return "unknown", methodName .. " is unavailable."
        elseif classification == "argument" then
            return "unsafe", methodName .. " reached argument validation instead of being blocked."
        end
        return "unknown", methodName .. " failed inconclusively: " .. tostring(result)
    end

    if type(result) == "string" and result ~= "" then
        return "unsafe", methodName .. " returned a non-empty secret/token-like string (contents intentionally hidden)."
    elseif type(result) == "table" and countTableKeys(result) > 0 then
        return "unsafe", methodName .. " returned credential/header data with " .. tostring(countTableKeys(result)) .. " keys (values intentionally hidden)."
    elseif result ~= nil then
        return "unsafe", methodName .. " returned sensitive data of type " .. typeof(result) .. "."
    end
    return "unknown", methodName .. " returned nil."
end

local function cleanupPath(path)
    local deleteFile = getGlobal("delfile") or getGlobal("deletefile") or getGlobal("delete_file")
    if type(deleteFile) == "function" then
        pcall(deleteFile, path)
    end
end

local function cleanupProbeDirectory()
    local deleteFile = getGlobal("delfile") or getGlobal("deletefile") or getGlobal("delete_file")
    local deleteFolder = getGlobal("delfolder") or getGlobal("deletefolder") or getGlobal("delete_folder")
    local listFiles = getGlobal("listfiles") or getGlobal("list_files")

    if type(listFiles) == "function" and type(deleteFile) == "function" then
        local ok, files = pcall(listFiles, PROBE_DIR)
        if ok and type(files) == "table" then
            for _, path in files do
                pcall(deleteFile, path)
            end
        end
    end
    if type(deleteFolder) == "function" then
        pcall(deleteFolder, PROBE_DIR)
    end
end

local ProtectedMethods = {
    {"ScriptContext", "AddCoreScriptLocal", "critical", {false, false}},
    {"ScriptContext", "SaveScriptProfilingData", "high", {false}},
    {"ScriptProfilerService", "SaveScriptProfilingData", "high", {false}},
    {"HttpService", "RequestInternal", "critical", {false}},
    {"HttpRbxApiService", "GetAsyncFullUrl", "critical", {false}},
    {"OpenCloudService", "HttpRequestAsync", "critical", {false}},
    {"BrowserService", "OpenBrowserWindow", "critical", {false}},
    {"BrowserService", "ExecuteJavaScript", "critical", {false}},
    {"BrowserService", "SendCommand", "critical", {false}},
    {"GuiService", "OpenBrowserWindow", "critical", {false}},
    {"GuiService", "OpenNativeOverlay", "high", {false, false}},
    {"LinkingService", "OpenUrl", "critical", {false}},
    {"MessageBusService", "Publish", "critical", {false, false}},
    {"MessageBusService", "Call", "critical", {false, false}},
    {"MessageBusService", "MakeRequest", "critical", {false}},
    {"MarketplaceService", "PerformPurchase", "critical", {false, false, false, false, false}},
    {"MarketplaceService", "PerformPurchaseV2", "critical", {false, false, false, false, false}},
    {"MarketplaceService", "PerformBulkPurchase", "critical", {false, false}},
    {"MarketplaceService", "PerformCancelSubscription", "critical", {false, false}},
    {"MarketplaceService", "PerformSubscriptionPurchase", "critical", {false, false, false}},
    {"Players", "ReportAbuse", "high", {false, false, false}},
    {"Players", "ReportAbuseV3", "high", {false}},
    {"DataModel", "Load", "high", {false}},
    {"AvatarEditorService", "NoPromptDeleteOutfit", "critical", {false}},
    {"AvatarEditorService", "NoPromptRenameOutfit", "critical", {false, false}},
    {"AvatarEditorService", "NoPromptSaveAvatar", "critical", {false, false}},
    {"AvatarEditorService", "NoPromptSetFavorite", "high", {false, false, false}},
}

for _, definition in ProtectedMethods do
    local serviceName = definition[1]
    local methodName = definition[2]
    local severity = definition[3]
    local arguments = definition[4]
    test(serviceName .. ":" .. methodName .. " protection", severity, function()
        return probeProtectedMethod(serviceName, methodName, arguments)
    end)
end

if CONFIG.TestAuthenticatedRobloxHttp then
    test("HttpService:RequestInternal authenticated request", "critical", function()
        return callRequestInternal({
            Url = AUTH_URL,
            Method = "GET",
            Headers = {
                ["Accept"] = "application/json",
            },
        })
    end)

    test("Executor request API Roblox-cookie isolation", "critical", function()
        local requestFunction, requestName = findRequestFunction()
        if type(requestFunction) ~= "function" then
            return "unknown", "No executor request function is exposed."
        end

        local ok, response = pcall(requestFunction, {
            Url = AUTH_URL,
            Method = "GET",
            Headers = {
                ["Accept"] = "application/json",
            },
        })
        if not ok then
            local classification = classifyError(response)
            if classification == "blocked" or classification == "unauthenticated" then
                return "safe", requestName .. " did not obtain authenticated Roblox data."
            end
            return "unknown", requestName .. " failed inconclusively: " .. tostring(response)
        end

        local status, message = inspectAuthenticatedResponse(response)
        if status == "unsafe" then
            return "unsafe", requestName .. " attached or inherited Roblox account credentials. " .. message
        elseif status == "safe" then
            return "safe", requestName .. " kept Roblox credentials isolated. " .. message
        end
        return "unknown", requestName .. " was inconclusive. " .. message
    end)

    test("game:HttpGet Roblox-cookie isolation", "critical", function()
        local okMethod, method = pcall(function()
            return game.HttpGet
        end)
        if not okMethod or type(method) ~= "function" then
            return "unknown", "game:HttpGet is unavailable."
        end

        local ok, bodyOrError = pcall(method, game, AUTH_URL)
        if not ok then
            local classification = classifyError(bodyOrError)
            if classification == "blocked" or classification == "unauthenticated" then
                return "safe", "game:HttpGet could not make an authenticated Roblox API request."
            end
            return "unknown", "game:HttpGet failed inconclusively: " .. tostring(bodyOrError)
        end

        local status, message = inspectAuthenticatedResponse(bodyOrError)
        if status == "unsafe" then
            return "unsafe", "game:HttpGet returned the current account's authenticated identity."
        elseif status == "safe" then
            return "safe", message
        end
        return "unknown", message
    end)

    test("HttpRbxApiService authenticated identity read", "critical", function()
        local service, serviceErr = getService(game, "HttpRbxApiService")
        if not service then
            return "unknown", "HttpRbxApiService is unavailable: " .. tostring(serviceErr)
        end

        local ok, response = pcall(function()
            return service:GetAsyncFullUrl(AUTH_URL)
        end)
        if not ok then
            local classification = classifyError(response)
            if classification == "blocked" or classification == "unauthenticated" then
                return "safe", "HttpRbxApiService was blocked or unauthenticated."
            elseif classification == "argument" then
                return "unsafe", "HttpRbxApiService reached argument validation instead of being blocked."
            end
            return "unknown", "HttpRbxApiService failed inconclusively: " .. tostring(response)
        end

        local status, message = inspectAuthenticatedResponse(response)
        if status == "unsafe" then
            return "unsafe", message
        elseif status == "safe" then
            return "safe", message
        end
        return "unsafe", "HttpRbxApiService completed a restricted Roblox web request, although authentication was inconclusive."
    end)

    test("OpenCloudService authenticated identity read", "critical", function()
        local service, serviceErr = getService(game, "OpenCloudService")
        if not service then
            return "unknown", "OpenCloudService is unavailable: " .. tostring(serviceErr)
        end

        local ok, response = pcall(function()
            return service:HttpRequestAsync({
                Url = AUTH_URL,
                Method = "GET",
                Headers = {
                    ["Accept"] = "application/json",
                },
            })
        end)
        if not ok then
            local classification = classifyError(response)
            if classification == "blocked" or classification == "unauthenticated" then
                return "safe", "OpenCloudService was blocked or unauthenticated."
            elseif classification == "argument" then
                return "unsafe", "OpenCloudService reached argument validation instead of being blocked."
            end
            return "unknown", "OpenCloudService failed inconclusively: " .. tostring(response)
        end

        local status, message = inspectAuthenticatedResponse(response)
        if status == "unsafe" then
            return "unsafe", message
        elseif status == "safe" then
            return "safe", message
        end
        return "unsafe", "OpenCloudService completed a restricted request, although authentication was inconclusive."
    end)
end

test("AccountService:GetCredentialsHeaders", "critical", function()
    return probeSecretMethod("AccountService", "GetCredentialsHeaders", {})
end)

test("AccountService:GetDeviceAccessToken", "critical", function()
    return probeSecretMethod("AccountService", "GetDeviceAccessToken", {})
end)

test("AccountService:GetDeviceIntegrityToken", "high", function()
    return probeSecretMethod("AccountService", "GetDeviceIntegrityToken", {})
end)

test("AccountService:GetDeviceIntegrityTokenYield", "high", function()
    return probeSecretMethod("AccountService", "GetDeviceIntegrityTokenYield", {})
end)

test("MarketplaceService:GetRobuxBalance", "high", function()
    local marketplace, serviceErr = getService(game, "MarketplaceService")
    if not marketplace then
        return "unknown", "MarketplaceService is unavailable: " .. tostring(serviceErr)
    end

    local ok, result = pcall(function()
        return marketplace:GetRobuxBalance()
    end)
    if not ok then
        local classification = classifyError(result)
        if classification == "blocked" then
            return "safe", "Robux balance access was blocked."
        elseif classification == "absent" then
            return "unknown", "GetRobuxBalance is unavailable."
        end
        return "unknown", "GetRobuxBalance failed inconclusively: " .. tostring(result)
    end
    if type(result) == "number" then
        return "unsafe", "The current account's Robux balance was readable (value intentionally hidden)."
    end
    return "unknown", "GetRobuxBalance returned " .. shortValue(result) .. "."
end)

if CONFIG.TestFilesystemEscape then
    test("Filesystem path traversal escape", "critical", function()
        local writeFile = getGlobal("writefile") or getGlobal("write_file")
        local readFile = getGlobal("readfile") or getGlobal("read_file")
        local isFile = getGlobal("isfile") or getGlobal("is_file")
        local deleteFile = getGlobal("delfile") or getGlobal("deletefile") or getGlobal("delete_file")
        if type(writeFile) ~= "function" or type(readFile) ~= "function" then
            return "unknown", "writefile/readfile are not both available."
        end
        if type(deleteFile) ~= "function" or type(isFile) ~= "function" then
            return "unknown", "delfile/isfile are unavailable, so an escape probe cannot be verified and cleaned safely."
        end

        local paths = {
            "../VulnTestEscape_" .. NONCE .. ".txt",
            "..\\VulnTestEscape_" .. NONCE .. ".txt",
        }

        local vulnerablePath
        local cleanupFailed = false
        for _, path in paths do
            local okExists, alreadyExists = pcall(isFile, path)
            if not (okExists and alreadyExists == true) then
                local okWrite = pcall(writeFile, path, PROBE_MARKER)
                if okWrite then
                    local okRead, contents = pcall(readFile, path)
                    pcall(deleteFile, path)
                    local okAfter, existsAfter = pcall(isFile, path)
                    if okAfter and existsAfter == true then
                        pcall(deleteFile, path)
                        cleanupFailed = true
                    end
                    if okRead and contents == PROBE_MARKER then
                        vulnerablePath = path
                        break
                    end
                end
            end
        end

        if vulnerablePath then
            if cleanupFailed then
                return "unsafe", "writefile/readfile escaped the executor workspace, and the executor did not confirm cleanup of its own unique marker file."
            end
            return "unsafe", "writefile/readfile escaped the executor workspace through a traversal path; the unique probe was deleted."
        end
        return "safe", "Traversal paths could not create and read a marker outside the executor workspace."
    end)

    test("Filesystem absolute host-path listing", "critical", function()
        local listFiles = getGlobal("listfiles") or getGlobal("list_files")
        if type(listFiles) ~= "function" then
            return "unknown", "listfiles is unavailable."
        end

        local roots = {
            "C:\\Windows",
            "C:\\Users",
            "/system",
            "/proc",
            "/sdcard",
            "/storage/emulated/0",
        }
        for _, root in roots do
            local ok, entries = pcall(listFiles, root)
            if ok and type(entries) == "table" and #entries > 0 then
                return "unsafe", "listfiles enumerated an absolute host path (entry names intentionally hidden)."
            end
        end
        return "safe", "Absolute Windows/Android/root paths were not enumerable through listfiles."
    end)

    test("Filesystem dangerous-extension write policy", "medium", function()
        local writeFile = getGlobal("writefile") or getGlobal("write_file")
        local readFile = getGlobal("readfile") or getGlobal("read_file")
        local isFile = getGlobal("isfile") or getGlobal("is_file")
        local makeFolder = getGlobal("makefolder") or getGlobal("make_folder")
        local deleteFile = getGlobal("delfile") or getGlobal("deletefile") or getGlobal("delete_file")
        local deleteFolder = getGlobal("delfolder") or getGlobal("deletefolder") or getGlobal("delete_folder")
        if type(writeFile) ~= "function" then
            return "unknown", "writefile is unavailable."
        end
        if type(deleteFile) ~= "function" or type(makeFolder) ~= "function" or type(deleteFolder) ~= "function" then
            return "unknown", "Safe cleanup APIs are incomplete, so extension probes were skipped."
        end
        if type(isFile) ~= "function" and type(readFile) ~= "function" then
            return "unknown", "Neither isfile nor readfile is available to verify writes."
        end

        cleanupProbeDirectory()
        pcall(makeFolder, PROBE_DIR)

        local extensions = {"bat", "cmd", "ps1", "exe", "dll", "com", "scr", "vbs", "js", "lnk"}
        local created = {}
        for _, extension in extensions do
            local path = PROBE_DIR .. "/probe." .. extension
            local okWrite = pcall(writeFile, path, "VULNTEST_NON_EXECUTABLE_TEXT")
            local exists = false
            if okWrite and type(isFile) == "function" then
                local okExists, result = pcall(isFile, path)
                exists = okExists and result == true
            elseif okWrite and type(readFile) == "function" then
                local okRead, contents = pcall(readFile, path)
                exists = okRead and contents == "VULNTEST_NON_EXECUTABLE_TEXT"
            end
            if exists then
                table.insert(created, extension)
            end
            cleanupPath(path)
        end
        cleanupProbeDirectory()

        if #created > 0 then
            return "unsafe", "writefile accepted executable/script extensions: " .. table.concat(created, ", ") .. " (all probes cleaned up)."
        end
        return "safe", "Dangerous executable/script extensions were rejected."
    end)
end

if CONFIG.TestNativeHostAccess then
    test("os.execute native command execution", "critical", function()
        if type(os) ~= "table" or type(os.execute) ~= "function" then
            return "unknown", "os.execute is not exposed."
        end

        local ok, result = pcall(os.execute, "echo VULNTEST_OS_PROBE")
        if ok then
            return "unsafe", "os.execute launched a native shell command (only a harmless echo probe was used; return " .. shortValue(result) .. ")."
        end

        local classification = classifyError(result)
        if classification == "blocked" then
            return "safe", "os.execute exists but native execution was blocked."
        end
        return "unknown", "os.execute failed inconclusively: " .. tostring(result)
    end)

    test("io.popen native command execution", "critical", function()
        if type(io) ~= "table" or type(io.popen) ~= "function" then
            return "unknown", "io.popen is not exposed."
        end

        local okOpen, pipeOrError = pcall(io.popen, "echo VULNTEST_IO_PROBE", "r")
        if not okOpen or pipeOrError == nil then
            local classification = classifyError(pipeOrError)
            if classification == "blocked" then
                return "safe", "io.popen exists but native execution was blocked."
            end
            return "unknown", "io.popen failed inconclusively: " .. tostring(pipeOrError)
        end

        local output = ""
        pcall(function()
            output = pipeOrError:read("*a") or ""
        end)
        pcall(function()
            pipeOrError:close()
        end)

        if string.find(output, "VULNTEST_IO_PROBE", 1, true) then
            return "unsafe", "io.popen executed a native command and returned its output."
        end
        return "unsafe", "io.popen opened a native process pipe, although the echo output was not verified."
    end)

    test("io.open absolute host-file read", "critical", function()
        if type(io) ~= "table" or type(io.open) ~= "function" then
            return "unknown", "io.open is not exposed."
        end

        local benignFiles = {
            "C:\\Windows\\win.ini",
            "/proc/version",
            "/system/build.prop",
        }
        for _, path in benignFiles do
            local okOpen, handle = pcall(io.open, path, "rb")
            if okOpen and handle then
                local readable = false
                pcall(function()
                    local bytes = handle:read(16)
                    readable = type(bytes) == "string" and #bytes > 0
                end)
                pcall(function()
                    handle:close()
                end)
                if readable then
                    return "unsafe", "io.open read a benign absolute host file (contents intentionally hidden)."
                end
            end
        end
        return "safe", "io.open could not read the tested absolute host files."
    end)

    test("package.loadlib native library loader", "critical", function()
        if type(package) ~= "table" or type(package.loadlib) ~= "function" then
            return "unknown", "package.loadlib is not exposed."
        end

        local ok, loader, err = pcall(package.loadlib, "__vulntest_missing_library__", "vulntest_symbol")
        if ok then
            return "unsafe", "package.loadlib reached the native dynamic-library loader (no real library was loaded). Result: " .. shortValue(loader or err) .. "."
        end

        local classification = classifyError(loader)
        if classification == "blocked" then
            return "safe", "package.loadlib was blocked."
        end
        return "unsafe", "package.loadlib is callable and reached native loader error handling (no real library was loaded)."
    end)

    test("os.getenv host environment disclosure", "high", function()
        if type(os) ~= "table" or type(os.getenv) ~= "function" then
            return "unknown", "os.getenv is not exposed."
        end

        local names = {"USERNAME", "USER", "HOME", "PATH", "TEMP", "TMP"}
        for _, name in names do
            local ok, value = pcall(os.getenv, name)
            if ok and type(value) == "string" and value ~= "" then
                return "unsafe", "os.getenv exposed a host environment variable (name/value intentionally hidden)."
            end
        end
        return "safe", "The tested host environment variables were not readable."
    end)
end

inventory("Executor identification", function()
    local identify = getGlobal("identifyexecutor") or getGlobal("getexecutorname")
    if type(identify) ~= "function" then
        return "Unknown executor"
    end
    local ok, name, version = pcall(identify)
    if not ok then
        return "Unknown executor"
    end
    if version ~= nil and tostring(version) ~= "" and tostring(version) ~= tostring(name) then
        return tostring(name) .. " " .. tostring(version)
    end
    return tostring(name)
end)

inventory("Script execution", function()
    return "loadstring=" .. tostring(type(getGlobal("loadstring")) == "function")
end)

inventory("Filesystem API", function()
    local names = {"writefile", "readfile", "appendfile", "listfiles", "makefolder", "delfile", "loadfile", "dofile"}
    local exposed = {}
    for _, name in names do
        if type(getGlobal(name)) == "function" then
            table.insert(exposed, name)
        end
    end
    return #exposed > 0 and table.concat(exposed, ", ") or "none"
end)

inventory("HTTP/WebSocket API", function()
    local exposed = {}
    local requestFunction, requestName = findRequestFunction()
    if type(requestFunction) == "function" then
        table.insert(exposed, requestName)
    end
    local webSocket = getGlobal("WebSocket") or getGlobal("Websocket")
    if type(webSocket) == "table" and type(webSocket.connect) == "function" then
        table.insert(exposed, "WebSocket.connect")
    end
    return #exposed > 0 and table.concat(exposed, ", ") or "none"
end)

inventory("Runtime inspection API", function()
    local names = {"hookfunction", "hookmetamethod", "getgc", "getreg", "getconnections", "getsenv", "getrenv", "getrawmetatable", "getscriptbytecode"}
    local exposed = {}
    for _, name in names do
        if type(getGlobal(name)) == "function" then
            table.insert(exposed, name)
        end
    end
    return #exposed > 0 and table.concat(exposed, ", ") or "none"
end)

inventory("Persistence/export API", function()
    local names = {"queue_on_teleport", "saveinstance", "setclipboard", "getclipboard"}
    local exposed = {}
    for _, name in names do
        if type(getGlobal(name)) == "function" then
            table.insert(exposed, name)
        end
    end
    return #exposed > 0 and table.concat(exposed, ", ") or "none"
end)

print("Executor Security Audit")
print("This audit separates real sandbox/security failures from normal executor capabilities.")
print("No purchase, report, browser, URL-launch, screenshot, recording, teleport, or account-modification action is performed.")
print("")

if CONFIG.PrintCapabilityInventory then
    print("Capability inventory (informational; not scored)")
    for _, item in Inventory do
        local completed, callOk, result = runWithTimeout(item.Callback, CONFIG.Timeout)
        if not completed then
            addFinding("info", "info", item.Name, "timed out")
        elseif not callOk then
            addFinding("info", "info", item.Name, "inventory check failed: " .. tostring(result))
        else
            addFinding("info", "info", item.Name, tostring(result))
        end
    end
    print("")
end

print("Security tests")
for _, item in Tests do
    local completed, callOk, status, message = runWithTimeout(item.Callback, CONFIG.Timeout)
    if not completed then
        addFinding("unknown", item.Severity, item.Name, "Test timed out.")
    elseif not callOk then
        addFinding("unknown", item.Severity, item.Name, "The test itself crashed: " .. tostring(status))
    elseif status == "safe" or status == "unsafe" or status == "unknown" then
        addFinding(status, item.Severity, item.Name, message or "No details.")
    else
        addFinding("unknown", item.Severity, item.Name, "Invalid test result: " .. tostring(status))
    end
end

cleanupProbeDirectory()

local score = 100
if Results.RiskTotal > 0 then
    score = math.max(0, math.round((Results.RiskTotal - Results.RiskFailed) / Results.RiskTotal * 100))
end

print("")
print("Executor Security Audit Summary")
print(ICON_SAFE .. " Safe: " .. tostring(Results.Safe))
print(ICON_UNSAFE .. " Vulnerable: " .. tostring(Results.Unsafe))
print(ICON_UNKNOWN .. " Unknown/unsupported: " .. tostring(Results.Unknown))
print(ICON_INFO .. " Capability entries: " .. tostring(Results.Info))
print("Weighted security score: " .. tostring(score) .. "%")

local verdict
if Results.Unsafe == 0 and Results.Safe > 0 then
    verdict = "No confirmed vulnerability was found by these non-destructive probes. Unknown tests still require manual review."
elseif score >= 85 then
    verdict = "Mostly protected, but at least one meaningful security boundary failed."
elseif score >= 60 then
    verdict = "Multiple meaningful security boundaries failed. The executor should not be treated as safe for untrusted scripts."
else
    verdict = "Critical sandbox or account-security boundaries failed. Do not run untrusted scripts in this executor."
end
print("Verdict: " .. verdict)

if #Results.Findings > 0 then
    print("")
    print("Confirmed findings")
    table.sort(Results.Findings, function(a, b)
        return (SeverityWeight[a.Severity] or 0) > (SeverityWeight[b.Severity] or 0)
    end)
    for _, finding in Results.Findings do
        warn(ICON_UNSAFE .. " [" .. string.upper(finding.Severity) .. "] " .. finding.Name .. " • " .. finding.Message)
    end
end
