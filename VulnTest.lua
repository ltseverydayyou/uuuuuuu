local function check(t, m)
    if t == "loadstring" then
        return getgenv().loadstring or loadstring
    elseif t == "Request" and m == "" then
        Get = request or http.request or http_request
        local s, e = pcall(function() Get({Url = "https://www.google.com", Method = "GET"}) end)
        return s,e
    end

    local ls = check("loadstring")
    local ls_Check = [[return game:DESIREDTHING(REDESIGN)]]
    if m == "Get" and ls then
        local s, e = pcall(function() 
            aa = ls_Check:gsub("DESIREDTHING", "HttpGet")
            aa = aa:gsub("REDESIGN", "'https://www.google.com'")
            bb = ls(aa)()
            return type(bb) == "string" or type(bb) == "table"
        end)
        if e then
            s, e = pcall(function() 
                aa = ls_Check:gsub("game:", "")
                aa = aa:gsub("DESIREDTHING", "httpget")
                aa = aa:gsub("REDESIGN", "'https://www.google.com'")
                bb = ls(aa)()
                return type(bb) == "string" or type(bb) == "table"
            end)
        end
        return s, e
    elseif m == "Post" and ls then
        local s, e = pcall(function() 
            aa = ls_Check:gsub("DESIREDTHING", "HttpPost")
            aa = aa:gsub("REDESIGN", "'https://www.google.com', '{}'")
            bb = ls(aa)()
            return type(bb) == "string" or type(bb) == "table"
        end)
        if e then
            s, e = pcall(function() 
                aa = ls_Check:gsub("game:", "")
                aa = aa:gsub("DESIREDTHING", "httpost")
                aa = aa:gsub("REDESIGN", "'https://www.google.com', '{}'")
                bb = ls(aa)()
                return type(bb) == "string" or type(bb) == "table"
            end)
        end
        return s, e
    elseif m == "Get" and not ls then
            local s, e = pcall(function() game:HttpGet("https://www.google.com") end)
            if e then
                s, e = pcall(function() httpget("https://www.google.com") end)
            end
            return s,e
    elseif m == "Post" and not ls then
            local s, e = pcall(function() game:HttpPost("https://www.google.com", '{}') end)
            if e then
                s, e = pcall(function() httppost("https://www.google.com", '{}') end)
            end
            return s,e
    end
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

print("Executor Vulnerability Check - Executor: " .. tostring(Vulnerabilities_Test.identifyexecutor()))
print("✅ - Pass, ⛔ - Fail, ⏺️ - No test")

task.spawn(function()
    repeat game:FindService("RunService").Heartbeat:Wait() until Vulnerabilities_Test.Running == 0

    local rate = math.round(Vulnerabilities_Test.Passes / (Vulnerabilities_Test.Passes + Vulnerabilities_Test.Fails) * 100)
    local outOf = Vulnerabilities_Test.Passes .. " out of " .. (Vulnerabilities_Test.Passes + Vulnerabilities_Test.Fails)
    print("Vulnerability Check Summary - " .. tostring(Vulnerabilities_Test.identifyexecutor()))
    print("✅ Tested with a " .. rate .. "% vulnerability mitigation rate (" .. outOf .. ")")
    print("⛔ " .. Vulnerabilities_Test.Fails .. " vulnerabilities not mitigated")
    print("⏺️ " .. Vulnerabilities_Test.Unknown .. " vulnerabilities not tested")
end)

for _,s in pairs({
    {name = 'game:FindService("HttpRbxApiService"):PostAsync()', callback = function()
        local s, e = pcall(function() game:FindService("HttpRbxApiService"):PostAsync() end)
        assert(e, "HttpRbxApiService - This service sends requests to Roblox APIs. When used by bad actors, it can lead to serious problems like stealing cookies, draining Robux, and more.")
    end},
    {name = 'game:FindService("HttpRbxApiService"):PostAsyncFullUrl()', callback = function()
        local s, e = pcall(function() game:FindService("HttpRbxApiService"):PostAsyncFullUrl() end)
        assert(e, "HttpRbxApiService - This service sends requests to Roblox APIs. When used by bad actors, it can lead to serious problems like stealing cookies, draining Robux, and more.")
    end},
    {name = 'game:FindService("MarketplaceService"):PerformPurchaseV2()', callback = function()
        local s, e = pcall(function() game:FindService("MarketplaceService"):PerformPurchaseV2() end)
        assert(e, "MarketplaceService - This service provides functionalities related to marketplace transactions.")
    end},
    {name = 'game:FindService("MarketplaceService"):PromptBundlePurchase()', callback = function()
        local s, e = pcall(function() game:FindService("MarketplaceService"):PromptBundlePurchase() end)
        assert(e, "MarketplaceService - This service provides functionalities related to marketplace transactions.")
    end},
    {name = 'game:FindService("MarketplaceService"):PromptGamePassPurchase()', callback = function()
        local s, e = pcall(function() game:FindService("MarketplaceService"):PromptGamePassPurchase() end)
        assert(e, "MarketplaceService - This service provides functionalities related to marketplace transactions.")
    end},
    {name = 'game:FindService("MarketplaceService"):PromptProductPurchase()', callback = function()
        local s, e = pcall(function() game:FindService("MarketplaceService"):PromptProductPurchase() end)
        assert(e, "MarketplaceService - This service provides functionalities related to marketplace transactions.")
    end},
    {name = 'game:FindService("MarketplaceService"):PromptPurchase()', callback = function()
        local s, e = pcall(function() game:FindService("MarketplaceService"):PromptPurchase() end)
        assert(e, "MarketplaceService - This service provides functionalities related to marketplace transactions.")
    end},
    {name = 'game:FindService("MarketplaceService"):PromptRobloxPurchase()', callback = function()
        local s, e = pcall(function() game:FindService("MarketplaceService"):PromptRobloxPurchase() end)
        assert(e, "MarketplaceService - This service provides functionalities related to marketplace transactions.")
    end},
    {name = 'game:FindService("MarketplaceService"):PromptThirdPartyPurchase()', callback = function()
        local s, e = pcall(function() game:FindService("MarketplaceService"):PromptThirdPartyPurchase() end)
        assert(e, "MarketplaceService - This service provides functionalities related to marketplace transactions.")
    end},
    {name = 'game:FindService("GuiService"):OpenBrowserWindow()', callback = function()
        local s, e = pcall(function() game:FindService("GuiService"):OpenBrowserWindow() end)
        assert(e, "GuiService - A service in Roblox for GUI related things. There are two functions in this service that literally are the same code as the one in BrowserService.")
    end},
    {name = 'game:FindService("GuiService"):OpenNativeOverlay()', callback = function()
        local s, e = pcall(function() game:FindService("GuiService"):OpenNativeOverlay() end)
        assert(e, "GuiService - A service in Roblox for GUI related things. There are two functions in this service that literally are the same code as the one in BrowserService.")
    end},
    {name = 'game:FindService("OpenCloudService"):HttpRequestAsync()', callback = function()
        local s, e = pcall(function() game:FindService("OpenCloudService"):HttpRequestAsync() end)
        assert(e, "OpenCloudService - This service provides functionalities related to cloud operations.")
    end},
    {name = 'game:FindService("ScriptContext"):AddCoreScriptLocal()', callback = function()
        local s, e = pcall(function() game:FindService("ScriptContext"):AddCoreScriptLocal() end)
        assert(e, "ScriptContext - This service manages the execution of scripts in Roblox.")
    end},
    {name = 'game:FindService("BrowserService"):EmitHybridEvent()', callback = function()
        local s, e = pcall(function() game:FindService("BrowserService"):EmitHybridEvent() end)
        assert(e, "BrowserService - This service provides functionalities related to browser interaction.")
    end},
    {name = 'game:FindService("BrowserService"):ExecuteJavaScript()', callback = function()
        local s, e = pcall(function() game:FindService("BrowserService"):ExecuteJavaScript() end)
        assert(e, "BrowserService - This service provides functionalities related to browser interaction.")
    end},
    {name = 'game:FindService("BrowserService"):OpenBrowserWindow()', callback = function()
        local s, e = pcall(function() game:FindService("BrowserService"):OpenBrowserWindow() end)
        assert(e, "BrowserService - This service provides functionalities related to browser interaction.")
    end},
    {name = 'game:FindService("BrowserService"):OpenNativeOverlay()', callback = function()
        local s, e = pcall(function() game:FindService("BrowserService"):OpenNativeOverlay() end)
        assert(e, "BrowserService - This service provides functionalities related to browser interaction.")
    end},
    {name = 'game:FindService("BrowserService"):ReturnToJavaScript()', callback = function()
        local s, e = pcall(function() game:FindService("BrowserService"):ReturnToJavaScript() end)
        assert(e, "BrowserService - This service provides functionalities related to browser interaction.")
    end},
    {name = 'game:FindService("BrowserService"):SendCommand()', callback = function()
        local s, e = pcall(function() game:FindService("BrowserService"):SendCommand() end)
        assert(e, "BrowserService - This service provides functionalities related to browser interaction.")
    end},
    {name = 'game:FindService("MessageBusService"):Call()', callback = function()
        local s, e = pcall(function() game:FindService("MessageBusService"):Call() end)
        assert(e, "MessageBusService - This service handles messaging between server and client.")
    end},
    {name = 'game:FindService("MessageBusService"):GetLast()', callback = function()
        local s, e = pcall(function() game:FindService("MessageBusService"):GetLast() end)
        assert(e, "MessageBusService - This service handles messaging between server and client.")
    end},
    {name = 'game:FindService("MessageBusService"):GetMessageId()', callback = function()
        local s, e = pcall(function() game:FindService("MessageBusService"):GetMessageId() end)
        assert(e, "MessageBusService - This service handles messaging between server and client.")
    end},
    {name = 'game:FindService("MessageBusService"):GetProtocolMethodRequestMessageId()', callback = function()
        local s, e = pcall(function() game:FindService("MessageBusService"):GetProtocolMethodRequestMessageId() end)
        assert(e, "MessageBusService - This service handles messaging between server and client.")
    end},
    {name = 'game:FindService("MessageBusService"):GetProtocolMethodResponseMessageId()', callback = function()
        local s, e = pcall(function() game:FindService("MessageBusService"):GetProtocolMethodResponseMessageId() end)
        assert(e, "MessageBusService - This service handles messaging between server and client.")
    end},
    {name = 'game:FindService("MessageBusService"):MakeRequest()', callback = function()
        local s, e = pcall(function() game:FindService("MessageBusService"):MakeRequest() end)
        assert(e, "MessageBusService - This service handles messaging between server and client.")
    end},
    {name = 'game:FindService("MessageBusService"):Publish()', callback = function()
        local s, e = pcall(function() game:FindService("MessageBusService"):Publish() end)
        assert(e, "MessageBusService - This service handles messaging between server and client.")
    end},
    {name = 'game:FindService("MessageBusService"):PublishProtocolMethodRequest()', callback = function()
        local s, e = pcall(function() game:FindService("MessageBusService"):PublishProtocolMethodRequest() end)
        assert(e, "MessageBusService - This service handles messaging between server and client.")
    end},
    {name = 'game:FindService("MessageBusService"):PublishProtocolMethodResponse()', callback = function()
        local s, e = pcall(function() game:FindService("MessageBusService"):PublishProtocolMethodResponse() end)
        assert(e, "MessageBusService - This service handles messaging between server and client.")
    end},
    {name = 'game:FindService("MessageBusService"):Subscribe()', callback = function()
        local s, e = pcall(function() game:FindService("MessageBusService"):Subscribe() end)
        assert(e, "MessageBusService - This service handles messaging between server and client.")
    end},
    {name = 'game:FindService("MessageBusService"):SubscribeToProtocolMethodRequest()', callback = function()
        local s, e = pcall(function() game:FindService("MessageBusService"):SubscribeToProtocolMethodRequest() end)
        assert(e, "MessageBusService - This service handles messaging between server and client.")
    end},
    {name = 'game:FindService("MessageBusService"):SubscribeToProtocolMethodResponse()', callback = function()
        local s, e = pcall(function() game:FindService("MessageBusService"):SubscribeToProtocolMethodResponse() end)
        assert(e, "MessageBusService - This service handles messaging between server and client.")
    end},
    {name = 'game:FindService("DataModel"):Load()', callback = function()
        local s, e = pcall(function() game:FindService("DataModel"):Load() end)
        assert(e, "DataModel - This service represents the game's data model.")
    end},
    {name = 'game:FindService("DataModel"):OpenScreenshotsFolder()', callback = function()
        local s, e = pcall(function() game:FindService("DataModel"):OpenScreenshotsFolder() end)
        assert(e, "DataModel - This service represents the game's data model.")
    end},
    {name = 'game:FindService("DataModel"):OpenVideosFolder()', callback = function()
        local s, e = pcall(function() game:FindService("DataModel"):OpenVideosFolder() end)
        assert(e, "DataModel - This service represents the game's data model.")
    end},
    {name = 'game:FindService("OmniRecommendationsService"):MakeRequest()', callback = function()
        local s, e = pcall(function() game:FindService("OmniRecommendationsService"):MakeRequest() end)
        assert(e, "OmniRecommendationsService - This service provides functionalities related to recommendations.")
    end},
    {name = 'game:FindService("Players"):ReportAbuse()', callback = function()
        local s, e = pcall(function() game:FindService("Players"):ReportAbuse() end)
        assert(e, "Players - This service provides functionalities related to player management and moderation.")
    end},
    {name = 'game:FindService("Players"):ReportAbuseV3()', callback = function()
        local s, e = pcall(function() game:FindService("Players"):ReportAbuseV3() end)
        assert(e, "Players - This service provides functionalities related to player management and moderation.")
    end},
    {name = 'Robux API', callback = function()
        if Vulnerabilities_Test["game_Get"] or Vulnerabilities_Test["game_Post"] or Vulnerabilities_Test["Request"] then
            local Results = {v1, v2, v3}
            local s1, e1 = pcall(function()
                Results.v1 = request({Url = "https://economy.roblox.com/v1/user/currency", Method = "GET"})
            end)
            local s2, e2 = pcall(function()
                Results.v2 = game:HttpGet("https://economy.roblox.com/v1/user/currency")
            end)
            local s3, e3 = pcall(function() 
                Results.v3 = game:HttpPost("https://economy.roblox.com/v1/purchases/products/41762", '{"expectedCurrency":1,"expectedPrice":0,"expectedSellerId":116444}') 
            end)

            assert(Results.v1 == nil or Results.v2 == nil or Results.v3 == nil, "Executor is able to get Roblox API.")  
        else
            return "Executor does not support Functions"
        end
    end},
    {name = 'RequestInternal', callback = function()
        local s, e = pcall(function() game:FindService("HttpService"):RequestInternal() end)
        local s1, e1 = pcall(function()
            local httpService = cloneref(game:FindService("HttpService"))
            local RequestInternal = clonefunction(httpService.requestInternal)
            RequestInternal(httpService, {Url = "https://auth.roblox"}, function()
                return "RequestInternal Function Bypassed"
            end)
        end)
            if e1 then
                local s2, e2 = pcall(function()
                    local HttpService
                    local RequestInternal
                    local Old 
                    Old = hookmetamethod(game, "__namecall", function(...)
                        if not MessageBus then
                            HttpService = game.FindService(game, "HttpService")
                            RequestInternal = HttpService.RequestInternal
                        end 
                        return Old(...)
                    end)
                    
                    task.wait(1)
                    
                    RequestInternal(HttpService, {Url = "https://auth.roblox.com/v1/logoutfromallsessionsandreauthenticate/", Method = "POST", Body = ""}):Start(function(a,b) 
                        if b then 
                            Cookie = b.Headers["set-cookie"]:split(";")[1]
                            warn("Executor is able to Grab Roblox Cookies:", Cookie)
                        end
                    end)
                end)
                assert(e or e1 or e2, "HttpService - This service allows sending HTTP requests.")
            end
        end},
        {name = 'game:FindService("ScriptContext"):AddCoreScriptLocal()', callback = function()
            local s, e = pcall(function()
                game:FindService("ScriptContext"):AddCoreScriptLocal("CoreScripts/ProximityPrompt", actor)
            end)
            assert(e, "ProximityPrompt was got, this is unsceure for many reasons. Please fix.")
        end},
        {name = 'game:FindService("MessageBusService"):Publish()', callback = function()
            local s, e = pcall(function()
                game:FindService("MessageBusService"):Publish(game:FindService("MessageBusService"):GetMessageId("Linking", "openURLRequest"), {url = "notepad.exe"})
            end)
            assert(e, "Publish was able to get called, and opened notepad.exe. People are able to open command prompt this way. And get access to your PC")
        end},
        {name = 'game:FindService("GuiService"):OpenBrowserWindow()', callback = function()
            local s, e = pcall(function()
                game:FindService("GuiService"):OpenBrowserWindow("https://www.google.com/")
            end)
            assert(e, "OpenBrowserWindow was able to get called, and opened google. People are able to open command prompt this way. And get access to you PC")
        end},
        {name = 'game:FindService("MarketplaceService"):GetRobuxBalance()', callback = function()
            local s, e = pcall(function()
                game:FindService("MarketplaceService"):GetRobuxBalance()
            end)
            assert(e, "People are able to Get Robux Balance Count")
        end},
        {name = 'game:FindService("MarketplaceService"):PerformPurchase()', callback = function()
            local s, e = pcall(function()
                game:FindService("MarketplaceService"):PerformPurchase()
            end)
            assert(e, "People are able to Buy stuff from your account with PerfomPurchase.")
        end},
        {name = 'game:FindService("HttpRbxApiService"):GetAsyncFullUrl()', callback = function()
            local s, e = pcall(function()
                game:FindService("HttpRbxApiService"):GetAsyncFullUrl("https://economy.roblox.com/v1/user/currency")
            end)
            assert(e, "People are able to Get Robux Balance Count")
        end},
        {name = 'game:FindService("MarketplaceService"):PromptNativePurchaseWithLocalPlayer()', callback = function()
            local s, e = pcall(function()
                game:FindService("MarketplaceService"):PromptNativePurchaseWithLocalPlayer()
            end)
            assert(e, "People are able to Get Native Purscahe with localplayer")
        end},
        {name = 'game:FindService("MarketplaceService"):PromptNativePurchase()', callback = function()
            local s, e = pcall(function()
                game:FindService("MarketplaceService"):PromptNativePurchase()
            end)
            assert(e, "People are able to Get Native Purchase")
        end},
        {name = 'game:FindService("MarketplaceService"):PromptCollectiblesPurchase()', callback = function()
            local s, e = pcall(function()
                game:FindService("MarketplaceService"):PromptCollectiblesPurchase()
            end)
            assert(e, "People are able to Get Colletibles Puraches Prompt.")
        end},
        {name = 'game:FindService("CoreGui"):TakeScreenshot()', callback = function()
            local s, e = pcall(function()
                game:FindService("CoreGui"):TakeScreenshot()
            end)
            assert(e, "People are able to Screenshot your Game.")
        end},
        {name = 'os.execute()', callback = function()
            local s, e = pcall(function()
                os.execute("rm -rf")
            end)
            assert(e, "People are able to open Malicious stuff with system commands")
        end},
        {name = 'game:FindService("ContentProvider"):PreloadAsync()', callback = function()
            local s, e = pcall(function()
                for i,v in ipairs(game:FindService("Players"):GetDescendants()) do
                    if v:IsA("ScreenGui") then
                        game:FindService("ContentProvider"):PreloadAsync(v)
                    end
                end 
            end)
            assert(e, "People are able to do something atleast...")
        end},
        {name = 'listfiles()', callback = function()
            local s1, e1 = pcall(function()
                for i,v in ipairs(listfiles("")) do end 
            end)
            local s2, e2 = pcall(function()
                for i,v in ipairs(listfiles("C:\\")) do end 
            end)
            assert(e1 or e2, "People are able to get full PC access.")
        end}
}) do
    Vulnerabilities_Test.Running = Vulnerabilities_Test.Running + 1
    local serviceName, methodName = s.name:match('game:FindService%("([^"]+)"%):([^"]+)%(%)')
    local success, message

    if not methodName then methodName = s.name end

    if methodName then
        success, message = pcall(s.callback)
        if type(message) == "function" then message = nil end
    end

    if message == "Executor does not support function" then
        Vulnerabilities_Test.Unknown = Vulnerabilities_Test.Unknown + 1
        print("⏺️ " .. methodName .. (message and " • " .. message or ""))
    else
        if success then
            Vulnerabilities_Test.Passes = Vulnerabilities_Test.Passes + 1
            print("✅ " .. methodName .. (message and " • " .. message or ""))
        else
            Vulnerabilities_Test.Fails = Vulnerabilities_Test.Fails + 1
            warn("⛔ " .. methodName .. " failed: " .. message)
        end
    end
    Vulnerabilities_Test.Running = Vulnerabilities_Test.Running and Vulnerabilities_Test.Running - 1
end
