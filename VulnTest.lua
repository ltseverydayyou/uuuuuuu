local function shortVal(v)
    if v == nil then
        return "nil"
    end
    local t = typeof(v)
    if t == "string" then
        local len = #v
        return "string (length "..len..")"
    elseif t == "table" then
        local c = 0
        for _ in pairs(v) do
            c += 1
        end
        return "table ("..c.." keys)"
    else
        return t.." ("..tostring(v)..")"
    end
end

local function check(t, m)
    local g = getgenv and getgenv() or _G

    if t == "loadstring" then
        return g.loadstring or loadstring
    end

    if t ~= "Request" then
        return false
    end

    if m == "" then
        local h = rawget(g, "http")
        local rq = rawget(g, "request") or (h and rawget(h, "request")) or rawget(g, "http_request")
        if not rq then
            return false
        end
        local ok, res = pcall(rq, { Url = "https://www.google.com", Method = "GET" })
        if not ok or res == nil then
            return false
        end
        return true
    end

    local ls = check("loadstring")

    local function try_ls(src)
        if not ls then
            return nil
        end
        local fn = ls(src)
        if not fn then
            return nil
        end
        local ok, ret = pcall(fn)
        if not ok then
            return nil
        end
        return ret
    end

    local function try_direct(fn)
        local ok, ret = pcall(fn)
        if not ok then
            return nil
        end
        return ret
    end

    if m == "Get" then
        local r = try_ls("return game:HttpGet('https://www.google.com')")
        if r == nil then
            r = try_ls("return httpget('https://www.google.com')")
        end
        if r == nil then
            r = try_direct(function()
                return game:HttpGet("https://www.google.com")
            end)
        end
        if r == nil then
            r = try_direct(function()
                return httpget("https://www.google.com")
            end)
        end
        return r ~= nil
    elseif m == "Post" then
        local r = try_ls("return game:HttpPost('https://www.google.com','{}')")
        if r == nil then
            r = try_ls("return httppost('https://www.google.com','{}')")
        end
        if r == nil then
            r = try_direct(function()
                return game:HttpPost("https://www.google.com", "{}")
            end)
        end
        if r == nil then
            r = try_direct(function()
                return httppost("https://www.google.com", "{}")
            end)
        end
        return r ~= nil
    end

    return false
end

local Vulnerabilities_Test = { 
    Passes = 0,
    Fails = 0,
    Unknown = 0,
    Running = 0,
    identifyexecutor = identifyexecutor or function() 
        return "Unknown", "?" 
    end,
    game_Get = check("Request", "Get"),
    game_Post = check("Request", "Post"),
    Request = check("Request", "")
}

local ICON_SAFE = "✅"
local ICON_UNSAFE = "⛔"
local ICON_UNKNOWN = "⏺️"

print("Executor Vulnerability Check - Executor: "..tostring(Vulnerabilities_Test.identifyexecutor()))
print("This script checks if dangerous functions are BLOCKED, STUBBED, or OPEN.")
print(ICON_SAFE.." Safe  = blocked or returns nil")
print(ICON_UNSAFE.." Unsafe = runs fine / returns data")
print(ICON_UNKNOWN.." Not tested / not supported")

local function data_test(desc, fn)
    local ok, ret = pcall(fn)
    if not ok then
        return "safe", desc.." Call was blocked with an error."
    end
    if ret == nil then
        return "safe", desc.." Function returned nil (probably stubbed/disabled by the executor)."
    end
    return "unsafe", desc.." Function returned data ("..shortVal(ret).."). Scripts can probably use this."
end

local function effect_test(desc, fn)
    local ok, ret = pcall(fn)
    if not ok then
        return "safe", desc.." Call was blocked with an error."
    end
    return "unsafe", desc.." Call ran without error (return: "..shortVal(ret).."). If this is not stubbed, scripts can use it."
end

local tests = {
    {
        name = 'HttpRbxApiService:PostAsync',
        callback = function()
            local s_ok, srv = pcall(function() return game:GetService("HttpRbxApiService") end)
            if not s_ok or not srv then
                return "unknown", "HttpRbxApiService is not available here."
            end
            return data_test("Sends low-level requests to Roblox APIs.", function()
                return srv:PostAsync("","")
            end)
        end
    },
    {
        name = 'HttpRbxApiService:PostAsyncFullUrl',
        callback = function()
            local s_ok, srv = pcall(function() return game:GetService("HttpRbxApiService") end)
            if not s_ok or not srv then
                return "unknown", "HttpRbxApiService is not available here."
            end
            return data_test("Can talk directly to Roblox web APIs with a full URL.", function()
                return srv:PostAsyncFullUrl("https://economy.roblox.com/v1/user/currency","")
            end)
        end
    },
    {
        name = 'MarketplaceService:PerformPurchaseV2',
        callback = function()
            local srv = game:GetService("MarketplaceService")
            return effect_test("Can try to perform purchases from your account.", function()
                return srv:PerformPurchaseV2()
            end)
        end
    },
    {
        name = 'MarketplaceService:PromptBundlePurchase',
        callback = function()
            local srv = game:GetService("MarketplaceService")
            return effect_test("Can pop up bundle purchase prompts on your account.", function()
                return srv:PromptBundlePurchase()
            end)
        end
    },
    {
        name = 'MarketplaceService:PromptGamePassPurchase',
        callback = function()
            local srv = game:GetService("MarketplaceService")
            return effect_test("Can pop up game pass purchase prompts.", function()
                return srv:PromptGamePassPurchase()
            end)
        end
    },
    {
        name = 'MarketplaceService:PromptProductPurchase',
        callback = function()
            local srv = game:GetService("MarketplaceService")
            return effect_test("Can pop up developer product purchase prompts.", function()
                return srv:PromptProductPurchase()
            end)
        end
    },
    {
        name = 'MarketplaceService:PromptPurchase',
        callback = function()
            local srv = game:GetService("MarketplaceService")
            return effect_test("Generic purchase prompt from your account.", function()
                return srv:PromptPurchase()
            end)
        end
    },
    {
        name = 'MarketplaceService:PromptRobloxPurchase',
        callback = function()
            local srv = game:GetService("MarketplaceService")
            return effect_test("Can open special Roblox purchase prompts.", function()
                return srv:PromptRobloxPurchase()
            end)
        end
    },
    {
        name = 'MarketplaceService:PromptThirdPartyPurchase',
        callback = function()
            local srv = game:GetService("MarketplaceService")
            return effect_test("Can open third-party purchase prompts.", function()
                return srv:PromptThirdPartyPurchase()
            end)
        end
    },
    {
        name = 'GuiService:OpenBrowserWindow',
        callback = function()
            local srv = game:GetService("GuiService")
            return effect_test("Can open browser windows or programs on your PC.", function()
                return srv:OpenBrowserWindow()
            end)
        end
    },
    {
        name = 'GuiService:OpenNativeOverlay',
        callback = function()
            local srv = game:GetService("GuiService")
            return effect_test("Can open native OS overlays from Roblox.", function()
                return srv:OpenNativeOverlay()
            end)
        end
    },
    {
        name = 'OpenCloudService:HttpRequestAsync',
        callback = function()
            local s_ok, srv = pcall(function() return game:GetService("OpenCloudService") end)
            if not s_ok or not srv then
                return "unknown", "OpenCloudService is not available here."
            end
            return data_test("Can make Open Cloud HTTP requests.", function()
                return srv:HttpRequestAsync({})
            end)
        end
    },
    {
        name = 'ScriptContext:AddCoreScriptLocal',
        callback = function()
            local srv = game:GetService("ScriptContext")
            return effect_test("Can load internal Roblox core scripts.", function()
                return srv:AddCoreScriptLocal()
            end)
        end
    },
    {
        name = 'BrowserService:EmitHybridEvent',
        callback = function()
            local s_ok, srv = pcall(function() return game:GetService("BrowserService") end)
            if not s_ok or not srv then
                return "unknown", "BrowserService is not available here."
            end
            return effect_test("Browser/JS hybrid events from Roblox to your system.", function()
                return srv:EmitHybridEvent()
            end)
        end
    },
    {
        name = 'BrowserService:ExecuteJavaScript',
        callback = function()
            local s_ok, srv = pcall(function() return game:GetService("BrowserService") end)
            if not s_ok or not srv then
                return "unknown", "BrowserService is not available here."
            end
            return effect_test("Can execute JavaScript in embedded browser contexts.", function()
                return srv:ExecuteJavaScript()
            end)
        end
    },
    {
        name = 'BrowserService:OpenBrowserWindow',
        callback = function()
            local s_ok, srv = pcall(function() return game:GetService("BrowserService") end)
            if not s_ok or not srv then
                return "unknown", "BrowserService is not available here."
            end
            return effect_test("Can open a browser window on your machine.", function()
                return srv:OpenBrowserWindow()
            end)
        end
    },
    {
        name = 'BrowserService:OpenNativeOverlay',
        callback = function()
            local s_ok, srv = pcall(function() return game:GetService("BrowserService") end)
            if not s_ok or not srv then
                return "unknown", "BrowserService is not available here."
            end
            return effect_test("Can open native overlays through browser service.", function()
                return srv:OpenNativeOverlay()
            end)
        end
    },
    {
        name = 'BrowserService:ReturnToJavaScript',
        callback = function()
            local s_ok, srv = pcall(function() return game:GetService("BrowserService") end)
            if not s_ok or not srv then
                return "unknown", "BrowserService is not available here."
            end
            return effect_test("Controls bridge between Roblox and JavaScript.", function()
                return srv:ReturnToJavaScript()
            end)
        end
    },
    {
        name = 'BrowserService:SendCommand',
        callback = function()
            local s_ok, srv = pcall(function() return game:GetService("BrowserService") end)
            if not s_ok or not srv then
                return "unknown", "BrowserService is not available here."
            end
            return effect_test("Sends low-level commands to browser integration.", function()
                return srv:SendCommand()
            end)
        end
    },
    {
        name = 'MessageBusService:Call',
        callback = function()
            local srv = game:GetService("MessageBusService")
            return effect_test("Low-level message calls inside Roblox client.", function()
                return srv:Call()
            end)
        end
    },
    {
        name = 'MessageBusService:GetLast',
        callback = function()
            local srv = game:GetService("MessageBusService")
            return data_test("Can read last internal message.", function()
                return srv:GetLast()
            end)
        end
    },
    {
        name = 'MessageBusService:GetMessageId',
        callback = function()
            local srv = game:GetService("MessageBusService")
            return data_test("Can access internal message IDs.", function()
                return srv:GetMessageId("Test", "Method")
            end)
        end
    },
    {
        name = 'MessageBusService:GetProtocolMethodRequestMessageId',
        callback = function()
            local srv = game:GetService("MessageBusService")
            return data_test("Can get protocol method request IDs.", function()
                return srv:GetProtocolMethodRequestMessageId("Test", "Method")
            end)
        end
    },
    {
        name = 'MessageBusService:GetProtocolMethodResponseMessageId',
        callback = function()
            local srv = game:GetService("MessageBusService")
            return data_test("Can get protocol method response IDs.", function()
                return srv:GetProtocolMethodResponseMessageId("Test", "Method")
            end)
        end
    },
    {
        name = 'MessageBusService:MakeRequest',
        callback = function()
            local srv = game:GetService("MessageBusService")
            return data_test("Can make low-level message bus requests.", function()
                return srv:MakeRequest({})
            end)
        end
    },
    {
        name = 'MessageBusService:Publish',
        callback = function()
            local srv = game:GetService("MessageBusService")
            return effect_test("Can publish messages into internal bus.", function()
                return srv:Publish("Test", {})
            end)
        end
    },
    {
        name = 'MessageBusService:PublishProtocolMethodRequest',
        callback = function()
            local srv = game:GetService("MessageBusService")
            return effect_test("Can publish protocol method requests.", function()
                return srv:PublishProtocolMethodRequest("Test", "Method", {})
            end)
        end
    },
    {
        name = 'MessageBusService:PublishProtocolMethodResponse',
        callback = function()
            local srv = game:GetService("MessageBusService")
            return effect_test("Can publish protocol method responses.", function()
                return srv:PublishProtocolMethodResponse("Test", "Method", {})
            end)
        end
    },
    {
        name = 'MessageBusService:Subscribe',
        callback = function()
            local srv = game:GetService("MessageBusService")
            return effect_test("Can subscribe to internal message channels.", function()
                return srv:Subscribe("Test", function() end)
            end)
        end
    },
    {
        name = 'MessageBusService:SubscribeToProtocolMethodRequest',
        callback = function()
            local srv = game:GetService("MessageBusService")
            return effect_test("Can subscribe to protocol method requests.", function()
                return srv:SubscribeToProtocolMethodRequest("Test", "Method", function() end)
            end)
        end
    },
    {
        name = 'MessageBusService:SubscribeToProtocolMethodResponse',
        callback = function()
            local srv = game:GetService("MessageBusService")
            return effect_test("Can subscribe to protocol method responses.", function()
                return srv:SubscribeToProtocolMethodResponse("Test", "Method", function() end)
            end)
        end
    },
    {
        name = 'DataModel:Load',
        callback = function()
            local dm = game:GetService("DataModel")
            return effect_test("Can load external place files into the data model.", function()
                return dm:Load("")
            end)
        end
    },
    {
        name = 'DataModel:OpenScreenshotsFolder',
        callback = function()
            local dm = game:GetService("DataModel")
            return effect_test("Can open your Roblox screenshots folder on disk.", function()
                return dm:OpenScreenshotsFolder()
            end)
        end
    },
    {
        name = 'DataModel:OpenVideosFolder',
        callback = function()
            local dm = game:GetService("DataModel")
            return effect_test("Can open your Roblox videos folder on disk.", function()
                return dm:OpenVideosFolder()
            end)
        end
    },
    {
        name = 'OmniRecommendationsService:MakeRequest',
        callback = function()
            local s_ok, srv = pcall(function() return game:GetService("OmniRecommendationsService") end)
            if not s_ok or not srv then
                return "unknown", "OmniRecommendationsService is not available here."
            end
            return data_test("Can request recommendation data.", function()
                return srv:MakeRequest({})
            end)
        end
    },
    {
        name = 'Players:ReportAbuse',
        callback = function()
            local plrs = game:GetService("Players")
            return effect_test("Can send abuse reports from your account.", function()
                return plrs:ReportAbuse()
            end)
        end
    },
    {
        name = 'Players:ReportAbuseV3',
        callback = function()
            local plrs = game:GetService("Players")
            return effect_test("Can send V3 abuse reports from your account.", function()
                return plrs:ReportAbuseV3()
            end)
        end
    },
    {
        name = 'Robux API',
        callback = function()
            if not (Vulnerabilities_Test.game_Get or Vulnerabilities_Test.game_Post or Vulnerabilities_Test.Request) then
                return "unknown", "Executor does not expose HTTP functions used in this Robux API test."
            end

            local results = { v1 = nil, v2 = nil, v3 = nil }

            pcall(function()
                if request then
                    results.v1 = request({ Url = "https://economy.roblox.com/v1/user/currency", Method = "GET" })
                end
            end)

            pcall(function()
                results.v2 = game:HttpGet("https://economy.roblox.com/v1/user/currency")
            end)

            pcall(function()
                results.v3 = game:HttpPost("https://economy.roblox.com/v1/purchases/products/41762",
                    '{"expectedCurrency":1,"expectedPrice":0,"expectedSellerId":116444}')
            end)

            if results.v1 ~= nil or results.v2 ~= nil or results.v3 ~= nil then
                return "unsafe", "At least one call to Roblox web APIs returned data (" ..
                    shortVal(results.v1 or results.v2 or results.v3).."). Web APIs are reachable."
            end

            return "safe", "All Roblox web API calls were blocked or returned nil."
        end
    },
    {
        name = 'RequestInternal',
        callback = function()
            local hs_ok, hs = pcall(function() return game:GetService("HttpService") end)
            if not hs_ok or not hs then
                return "unknown", "HttpService is not available."
            end

            local any_ok = false

            local ok0 = pcall(function()
                hs:RequestInternal({})
            end)
            any_ok = any_ok or ok0

            local ok1 = pcall(function()
                local httpService = cloneref and cloneref(hs) or hs
                local RequestInternal = clonefunction and clonefunction(httpService.requestInternal) or httpService.requestInternal
                RequestInternal(httpService, { Url = "https://auth.roblox.com" }, function()
                    return "RequestInternal Function Bypassed"
                end)
            end)
            any_ok = any_ok or ok1

            local ok2 = pcall(function()
                local HttpService
                local RequestInternal
                local Old
                Old = hookmetamethod(game, "__namecall", function(...)
                    if not HttpService then
                        HttpService = game.GetService(game, "HttpService")
                        RequestInternal = HttpService.RequestInternal
                    end
                    return Old(...)
                end)

                task.wait(1)

                RequestInternal(HttpService, {
                    Url = "https://auth.roblox.com/v1/logoutfromallsessionsandreauthenticate/",
                    Method = "POST",
                    Body = ""
                }):Start(function(a, b)
                    if b and b.Headers and b.Headers["set-cookie"] then
                        local cookie = b.Headers["set-cookie"]:split(";")[1]
                        warn("Executor is able to grab Roblox cookies:", cookie)
                    end
                end)
            end)
            any_ok = any_ok or ok2

            if any_ok then
                return "unsafe", "RequestInternal calls succeeded; low-level HTTP is reachable."
            end
            return "safe", "All RequestInternal attempts failed with errors."
        end
    },
    {
        name = 'ScriptContext:AddCoreScriptLocal (ProximityPrompt)',
        callback = function()
            local srv = game:GetService("ScriptContext")
            return effect_test("Can inject the ProximityPrompt core script.", function()
                return srv:AddCoreScriptLocal("CoreScripts/ProximityPrompt", nil)
            end)
        end
    },
    {
        name = 'MessageBusService:Publish (openURLRequest)',
        callback = function()
            local srv = game:GetService("MessageBusService")
            local msgId = srv:GetMessageId("Linking", "openURLRequest")
            return effect_test("Can publish a message that tries to open a URL (like notepad.exe).", function()
                return srv:Publish(msgId, { url = "notepad.exe" })
            end)
        end
    },
    {
        name = 'GuiService:OpenBrowserWindow (google.com)',
        callback = function()
            local srv = game:GetService("GuiService")
            return effect_test("Can open a specific web page on your machine.", function()
                return srv:OpenBrowserWindow("https://www.google.com/")
            end)
        end
    },
    {
        name = 'MarketplaceService:GetRobuxBalance',
        callback = function()
            local srv = game:GetService("MarketplaceService")
            local ok, ret = pcall(function()
                return srv:GetRobuxBalance()
            end)
            if not ok then
                return "safe", "Roblox blocked Robux balance read with an error."
            end
            if ret == nil then
                return "safe", "GetRobuxBalance returned nil (likely stubbed). Your balance is not exposed here."
            end
            return "unsafe", "GetRobuxBalance returned a value ("..shortVal(ret).."). Scripts can probably see your Robux."
        end
    },
    {
        name = 'MarketplaceService:PerformPurchase',
        callback = function()
            local srv = game:GetService("MarketplaceService")
            return effect_test("Can try to perform purchases from your account.", function()
                return srv:PerformPurchase()
            end)
        end
    },
    {
        name = 'HttpRbxApiService:GetAsyncFullUrl',
        callback = function()
            local s_ok, srv = pcall(function() return game:GetService("HttpRbxApiService") end)
            if not s_ok or not srv then
                return "unknown", "HttpRbxApiService is not available here."
            end
            return data_test("Reads data from Roblox web APIs.", function()
                return srv:GetAsyncFullUrl("https://economy.roblox.com/v1/user/currency")
            end)
        end
    },
    {
        name = 'MarketplaceService:PromptNativePurchaseWithLocalPlayer',
        callback = function()
            local srv = game:GetService("MarketplaceService")
            return effect_test("Can open native purchase prompts with your account.", function()
                return srv:PromptNativePurchaseWithLocalPlayer()
            end)
        end
    },
    {
        name = 'MarketplaceService:PromptNativePurchase',
        callback = function()
            local srv = game:GetService("MarketplaceService")
            return effect_test("Can open native purchase prompts.", function()
                return srv:PromptNativePurchase()
            end)
        end
    },
    {
        name = 'MarketplaceService:PromptCollectiblesPurchase',
        callback = function()
            local srv = game:GetService("MarketplaceService")
            return effect_test("Can open collectibles purchase prompts.", function()
                return srv:PromptCollectiblesPurchase()
            end)
        end
    },
    {
        name = 'CoreGui:TakeScreenshot',
        callback = function()
            local cg = game:GetService("CoreGui")
            return effect_test("Can take screenshots from your game view.", function()
                return cg:TakeScreenshot()
            end)
        end
    },
    {
        name = 'os.execute',
        callback = function()
            if type(os) ~= "table" or type(os.execute) ~= "function" then
                return "unknown", "os.execute is not exposed in this environment."
            end
            local ok, ret = pcall(function()
                return os.execute("echo test")
            end)
            if not ok then
                return "safe", "System commands (os.execute) are blocked with an error."
            end
            return "unsafe", "System commands can run (os.execute returned "..shortVal(ret).."). This is very dangerous."
        end
    },
    {
        name = 'ContentProvider:PreloadAsync',
        callback = function()
            local srv = game:GetService("ContentProvider")
            local plrs = game:GetService("Players")
            return effect_test("Can preload all UIs, which can be abused for weird behavior.", function()
                local list = {}
                for _, v in ipairs(plrs:GetDescendants()) do
                    if v:IsA("ScreenGui") then
                        table.insert(list, v)
                    end
                end
                if #list > 0 then
                    return srv:PreloadAsync(list)
                end
            end)
        end
    },
    {
        name = 'listfiles',
        callback = function()
            if type(listfiles) ~= "function" then
                return "unknown", "listfiles is not available in this executor."
            end
            local ok1, ret1 = pcall(function()
                return listfiles("")
            end)
            local ok2, ret2 = pcall(function()
                return listfiles("C:\\")
            end)
            if not ok1 and not ok2 then
                return "safe", "File system access via listfiles appears blocked (errors)."
            end
            if (ret1 ~= nil) or (ret2 ~= nil) then
                return "unsafe", "listfiles returned data (" ..
                    shortVal(ret1 or ret2).."). Scripts can probably read files on your executor/PC."
            end
            return "safe", "listfiles returned nil (likely stubbed)."
        end
    }
}

for _, s in ipairs(tests) do
    Vulnerabilities_Test.Running = Vulnerabilities_Test.Running + 1

    local success, status, info = pcall(s.callback)
    if not success then
        status = "unsafe"
        info = "The test itself crashed: "..tostring(status)
    end

    if status == "safe" then
        Vulnerabilities_Test.Passes = Vulnerabilities_Test.Passes + 1
        print(ICON_SAFE.." "..s.name.." • "..info)
    elseif status == "unsafe" then
        Vulnerabilities_Test.Fails = Vulnerabilities_Test.Fails + 1
        warn(ICON_UNSAFE.." "..s.name.." • "..info)
    else
        Vulnerabilities_Test.Unknown = Vulnerabilities_Test.Unknown + 1
        print(ICON_UNKNOWN.." "..s.name.." • "..(info or "Not supported / could not be tested."))
    end

    Vulnerabilities_Test.Running = Vulnerabilities_Test.Running - 1
end

task.spawn(function()
    repeat game:GetService("RunService").Heartbeat:Wait() until Vulnerabilities_Test.Running == 0

    local total = Vulnerabilities_Test.Passes + Vulnerabilities_Test.Fails
    local rate = total > 0 and math.round(Vulnerabilities_Test.Passes / total * 100) or 0
    local outOf = Vulnerabilities_Test.Passes.." out of "..total

    print("")
    print("Vulnerability Check Summary - "..tostring(Vulnerabilities_Test.identifyexecutor()))
    print(ICON_SAFE.." Safe tests: "..Vulnerabilities_Test.Passes)
    print(ICON_UNSAFE.." Unsafe tests: "..Vulnerabilities_Test.Fails)
    print(ICON_UNKNOWN.." Not tested / unsupported: "..Vulnerabilities_Test.Unknown)
    print("Score: "..rate.."% of the tested dangerous functions looked safe (blocked or nil).")

    local verdict
    if Vulnerabilities_Test.Fails == 0 and total > 0 then
        verdict = "Excellent: all checked dangerous functions are blocked or stubbed."
    elseif rate >= 70 then
        verdict = "Decent: most dangerous functions are blocked, but there are still some risks."
    elseif rate >= 40 then
        verdict = "Meh: about half of the dangerous functions are open. This is not very safe."
    else
        verdict = "Bad: many dangerous functions are open. This executor is quite risky."
    end

    print("Human summary: "..verdict)
    if Vulnerabilities_Test.Fails > 0 then
        print("Look for the "..ICON_UNSAFE.." lines above to see exactly which functions are dangerous.")
    end
end)
