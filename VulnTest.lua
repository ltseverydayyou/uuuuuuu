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
local function shortVal(v)
	if v == nil then
		return "nil";
	end;
	local t = typeof(v);
	if t == "string" then
		local len = #v;
		return "string (length " .. len .. ")";
	elseif t == "table" then
		local c = 0;
		for _ in pairs(v) do
			c += 1;
		end;
		return "table (" .. c .. " keys)";
	else
		return t .. " (" .. tostring(v) .. ")";
	end;
end;
local function hasMember(obj, member)
	local ok, value = pcall(function()
		return obj and obj[member];
	end);
	return ok and value ~= nil;
end;
local function check(t, m)
	local g = getgenv and getgenv() or _G;
	if t == "loadstring" then
		return g.loadstring or loadstring;
	end;
	if t ~= "Request" then
		return false;
	end;
	local h = rawget(g, "http");
	local rq = rawget(g, "request") or h and rawget(h, "request") or rawget(g, "http_request");
	if m == "" then
		return type(rq) == "function";
	end;
	if m == "Get" then
		return type(rawget(g, "httpget")) == "function" or hasMember(game, "HttpGet");
	elseif m == "Post" then
		return type(rawget(g, "httppost")) == "function" or hasMember(game, "HttpPost");
	end;
	return false;
end;
local Vulnerabilities_Test = {
	Passes = 0,
	Fails = 0,
	Unknown = 0,
	Running = 0,
	identifyexecutor = identifyexecutor or function()
		return "Unknown", "?";
	end,
	game_Get = check("Request", "Get"),
	game_Post = check("Request", "Post"),
	Request = check("Request", "")
};
local ICON_SAFE = "✅";
local ICON_UNSAFE = "⛔";
local ICON_UNKNOWN = "⏺️";
local TEST_TIMEOUT = 7;
local FS_PROBE_DIR = "VulnTestProbe";
local FS_PROBE_FILE = FS_PROBE_DIR .. "/probe.txt";
local FS_PROBE_SCRIPT = FS_PROBE_DIR .. "/probe.lua";
local function formatExecutor()
	local ok, name, version = pcall(Vulnerabilities_Test.identifyexecutor);
	if not ok then
		return "Unknown";
	end;
	if version ~= nil and tostring(version) ~= "" and tostring(version) ~= tostring(name) then
		return tostring(name) .. " " .. tostring(version);
	end;
	return tostring(name);
end;
local function classify_error(desc, err)
	local msg = tostring(err or "");
	local lower = string.lower(msg);
	if lower == "" then
		return "unknown", desc .. " Call failed without a useful error message.";
	end;
	if lower:find("lacking permission", 1, true)
		or lower:find("current identity", 1, true)
		or lower:find("permission", 1, true)
		or lower:find("not permitted", 1, true)
		or lower:find("cannot access", 1, true)
		or lower:find("http requests are not enabled", 1, true)
		or lower:find("blocked", 1, true) then
		return "safe", desc .. " Call was blocked by Roblox/executor permissions (" .. msg .. ").";
	end;
	if lower:find("attempt to call a nil value", 1, true)
		or lower:find("is not a valid member", 1, true)
		or lower:find("unknown global", 1, true)
		or lower:find("not available", 1, true)
		or lower:find("not supported", 1, true) then
		return "unknown", desc .. " API is not exposed here (" .. msg .. ").";
	end;
	if lower:find("argument", 1, true)
		or lower:find("expected", 1, true)
		or lower:find("unable to cast", 1, true)
		or lower:find("missing", 1, true)
		or lower:find("enumitem", 1, true)
		or lower:find("instance", 1, true)
		or lower:find("table expected", 1, true) then
		return "unknown", desc .. " API responded, but this test used invalid or incomplete arguments (" .. msg .. ").";
	end;
	return "unknown", desc .. " Call failed, but the reason was inconclusive (" .. msg .. ").";
end;
local function run_with_timeout(fn, timeoutSeconds)
	local finished = false;
	local ok, a, b;
	task.spawn(function()
		ok, a, b = pcall(fn);
		finished = true;
	end);
	local deadline = os.clock() + (timeoutSeconds or TEST_TIMEOUT);
	local runService = __betterGetService("RunService");
	while not finished and os.clock() < deadline do
		if runService and runService.Heartbeat then
			runService.Heartbeat:Wait();
		else
			task.wait(0.05);
		end;
	end;
	if not finished then
		return false, "timeout", "Timed out after " .. tostring(timeoutSeconds or TEST_TIMEOUT) .. "s. The call likely hung or waited forever.";
	end;
	return true, ok, a, b;
end;
local function cleanup_fs_probe()
	if type(delfile) == "function" then
		pcall(delfile, FS_PROBE_FILE);
		pcall(delfile, FS_PROBE_SCRIPT);
	end;
	if type(delfolder) == "function" then
		pcall(delfolder, FS_PROBE_DIR);
	end;
end;
print("Executor Vulnerability Check - Executor: " .. formatExecutor());
print("This script checks if dangerous functions are BLOCKED, STUBBED, or OPEN.");
print(ICON_SAFE .. " Safe  = blocked or returns nil");
print(ICON_UNSAFE .. " Unsafe = runs fine / returns data");
print(ICON_UNKNOWN .. " Not tested / not supported");
local function data_test(desc, fn)
	local ok, ret = pcall(fn);
	if not ok then
		return classify_error(desc, ret);
	end;
	if ret == nil then
		return "safe", desc .. " Function returned nil (probably stubbed/disabled by the executor).";
	end;
	return "unsafe", desc .. " Function returned data (" .. shortVal(ret) .. "). Scripts can probably use this.";
end;
local function effect_test(desc, fn)
	local ok, ret = pcall(fn);
	if not ok then
		return classify_error(desc, ret);
	end;
	if ret == nil then
		return "safe", desc .. " Call returned nil with no observable data. Treating this as stubbed/safe.";
	end;
	return "unsafe", desc .. " Call ran without error (return: " .. shortVal(ret) .. "). If this is not stubbed, scripts can use it.";
end;
local function bool_test(desc, fn, trueMessage, falseMessage)
	local ok, ret = pcall(fn);
	if not ok then
		return classify_error(desc, ret);
	end;
	if ret then
		return "unsafe", trueMessage or (desc .. " Returned true.");
	end;
	return "safe", falseMessage or (desc .. " Returned false/nil.");
end;
local tests = {
	{
		name = "HttpRbxApiService:PostAsync",
		callback = function()
			local s_ok, srv = pcall(function()
				return __betterGetService("HttpRbxApiService");
			end);
			if not s_ok or (not srv) then
				return "unknown", "HttpRbxApiService is not available here.";
			end;
			return data_test("Sends low-level requests to Roblox APIs.", function()
				return srv:PostAsync("", "");
			end);
		end
	},
	{
		name = "HttpRbxApiService:PostAsyncFullUrl",
		callback = function()
			local s_ok, srv = pcall(function()
				return __betterGetService("HttpRbxApiService");
			end);
			if not s_ok or (not srv) then
				return "unknown", "HttpRbxApiService is not available here.";
			end;
			return data_test("Can talk directly to Roblox web APIs with a full URL.", function()
				return srv:PostAsyncFullUrl("https://economy.roblox.com/v1/user/currency", "");
			end);
		end
	},
	{
		name = "MarketplaceService:PerformPurchaseV2",
		callback = function()
			local srv = __betterGetService("MarketplaceService");
			return effect_test("Can try to perform purchases from your account.", function()
				return srv:PerformPurchaseV2();
			end);
		end
	},
	{
		name = "MarketplaceService:PromptBundlePurchase",
		callback = function()
			local srv = __betterGetService("MarketplaceService");
			return effect_test("Can pop up bundle purchase prompts on your account.", function()
				return srv:PromptBundlePurchase();
			end);
		end
	},
	{
		name = "MarketplaceService:PromptGamePassPurchase",
		callback = function()
			local srv = __betterGetService("MarketplaceService");
			return effect_test("Can pop up game pass purchase prompts.", function()
				return srv:PromptGamePassPurchase();
			end);
		end
	},
	{
		name = "MarketplaceService:PromptProductPurchase",
		callback = function()
			local srv = __betterGetService("MarketplaceService");
			return effect_test("Can pop up developer product purchase prompts.", function()
				return srv:PromptProductPurchase();
			end);
		end
	},
	{
		name = "MarketplaceService:PromptPurchase",
		callback = function()
			local srv = __betterGetService("MarketplaceService");
			return effect_test("Generic purchase prompt from your account.", function()
				return srv:PromptPurchase();
			end);
		end
	},
	{
		name = "MarketplaceService:PromptRobloxPurchase",
		callback = function()
			local srv = __betterGetService("MarketplaceService");
			return effect_test("Can open special Roblox purchase prompts.", function()
				return srv:PromptRobloxPurchase();
			end);
		end
	},
	{
		name = "MarketplaceService:PromptThirdPartyPurchase",
		callback = function()
			local srv = __betterGetService("MarketplaceService");
			return effect_test("Can open third-party purchase prompts.", function()
				return srv:PromptThirdPartyPurchase();
			end);
		end
	},
	{
		name = "GuiService:OpenBrowserWindow",
		callback = function()
			local srv = __betterGetService("GuiService");
			return effect_test("Can open browser windows or programs on your PC.", function()
				return srv:OpenBrowserWindow();
			end);
		end
	},
	{
		name = "GuiService:OpenNativeOverlay",
		callback = function()
			local srv = __betterGetService("GuiService");
			return effect_test("Can open native OS overlays from Roblox.", function()
				return srv:OpenNativeOverlay();
			end);
		end
	},
	{
		name = "OpenCloudService:HttpRequestAsync",
		callback = function()
			local s_ok, srv = pcall(function()
				return __betterGetService("OpenCloudService");
			end);
			if not s_ok or (not srv) then
				return "unknown", "OpenCloudService is not available here.";
			end;
			return data_test("Can make Open Cloud HTTP requests.", function()
				return srv:HttpRequestAsync({});
			end);
		end
	},
	{
		name = "ScriptContext:AddCoreScriptLocal",
		callback = function()
			local srv = __betterGetService("ScriptContext");
			return effect_test("Can load internal Roblox core scripts.", function()
				return srv:AddCoreScriptLocal();
			end);
		end
	},
	{
		name = "BrowserService:EmitHybridEvent",
		callback = function()
			local s_ok, srv = pcall(function()
				return __betterGetService("BrowserService");
			end);
			if not s_ok or (not srv) then
				return "unknown", "BrowserService is not available here.";
			end;
			return effect_test("Browser/JS hybrid events from Roblox to your system.", function()
				return srv:EmitHybridEvent();
			end);
		end
	},
	{
		name = "BrowserService:ExecuteJavaScript",
		callback = function()
			local s_ok, srv = pcall(function()
				return __betterGetService("BrowserService");
			end);
			if not s_ok or (not srv) then
				return "unknown", "BrowserService is not available here.";
			end;
			return effect_test("Can execute JavaScript in embedded browser contexts.", function()
				return srv:ExecuteJavaScript();
			end);
		end
	},
	{
		name = "BrowserService:OpenBrowserWindow",
		callback = function()
			local s_ok, srv = pcall(function()
				return __betterGetService("BrowserService");
			end);
			if not s_ok or (not srv) then
				return "unknown", "BrowserService is not available here.";
			end;
			return effect_test("Can open a browser window on your machine.", function()
				return srv:OpenBrowserWindow();
			end);
		end
	},
	{
		name = "BrowserService:OpenNativeOverlay",
		callback = function()
			local s_ok, srv = pcall(function()
				return __betterGetService("BrowserService");
			end);
			if not s_ok or (not srv) then
				return "unknown", "BrowserService is not available here.";
			end;
			return effect_test("Can open native overlays through browser service.", function()
				return srv:OpenNativeOverlay();
			end);
		end
	},
	{
		name = "BrowserService:ReturnToJavaScript",
		callback = function()
			local s_ok, srv = pcall(function()
				return __betterGetService("BrowserService");
			end);
			if not s_ok or (not srv) then
				return "unknown", "BrowserService is not available here.";
			end;
			return effect_test("Controls bridge between Roblox and JavaScript.", function()
				return srv:ReturnToJavaScript();
			end);
		end
	},
	{
		name = "BrowserService:SendCommand",
		callback = function()
			local s_ok, srv = pcall(function()
				return __betterGetService("BrowserService");
			end);
			if not s_ok or (not srv) then
				return "unknown", "BrowserService is not available here.";
			end;
			return effect_test("Sends low-level commands to browser integration.", function()
				return srv:SendCommand();
			end);
		end
	},
	{
		name = "MessageBusService:Call",
		callback = function()
			local srv = __betterGetService("MessageBusService");
			return effect_test("Low-level message calls inside Roblox client.", function()
				return srv:Call();
			end);
		end
	},
	{
		name = "MessageBusService:GetLast",
		callback = function()
			local srv = __betterGetService("MessageBusService");
			return data_test("Can read last internal message.", function()
				return srv:GetLast();
			end);
		end
	},
	{
		name = "MessageBusService:GetMessageId",
		callback = function()
			local srv = __betterGetService("MessageBusService");
			return data_test("Can access internal message IDs.", function()
				return srv:GetMessageId("Test", "Method");
			end);
		end
	},
	{
		name = "MessageBusService:GetProtocolMethodRequestMessageId",
		callback = function()
			local srv = __betterGetService("MessageBusService");
			return data_test("Can get protocol method request IDs.", function()
				return srv:GetProtocolMethodRequestMessageId("Test", "Method");
			end);
		end
	},
	{
		name = "MessageBusService:GetProtocolMethodResponseMessageId",
		callback = function()
			local srv = __betterGetService("MessageBusService");
			return data_test("Can get protocol method response IDs.", function()
				return srv:GetProtocolMethodResponseMessageId("Test", "Method");
			end);
		end
	},
	{
		name = "MessageBusService:MakeRequest",
		callback = function()
			local srv = __betterGetService("MessageBusService");
			return data_test("Can make low-level message bus requests.", function()
				return srv:MakeRequest({});
			end);
		end
	},
	{
		name = "MessageBusService:Publish",
		callback = function()
			local srv = __betterGetService("MessageBusService");
			return effect_test("Can publish messages into internal bus.", function()
				return srv:Publish("Test", {});
			end);
		end
	},
	{
		name = "MessageBusService:PublishProtocolMethodRequest",
		callback = function()
			local srv = __betterGetService("MessageBusService");
			return effect_test("Can publish protocol method requests.", function()
				return srv:PublishProtocolMethodRequest("Test", "Method", {});
			end);
		end
	},
	{
		name = "MessageBusService:PublishProtocolMethodResponse",
		callback = function()
			local srv = __betterGetService("MessageBusService");
			return effect_test("Can publish protocol method responses.", function()
				return srv:PublishProtocolMethodResponse("Test", "Method", {});
			end);
		end
	},
	{
		name = "MessageBusService:Subscribe",
		callback = function()
			local srv = __betterGetService("MessageBusService");
			return effect_test("Can subscribe to internal message channels.", function()
				return srv:Subscribe("Test", function()
				end);
			end);
		end
	},
	{
		name = "MessageBusService:SubscribeToProtocolMethodRequest",
		callback = function()
			local srv = __betterGetService("MessageBusService");
			return effect_test("Can subscribe to protocol method requests.", function()
				return srv:SubscribeToProtocolMethodRequest("Test", "Method", function()
				end);
			end);
		end
	},
	{
		name = "MessageBusService:SubscribeToProtocolMethodResponse",
		callback = function()
			local srv = __betterGetService("MessageBusService");
			return effect_test("Can subscribe to protocol method responses.", function()
				return srv:SubscribeToProtocolMethodResponse("Test", "Method", function()
				end);
			end);
		end
	},
	{
		name = "DataModel:Load",
		callback = function()
			local dm = __betterGetService("DataModel");
			return effect_test("Can load external place files into the data model.", function()
				return dm:Load("");
			end);
		end
	},
	{
		name = "DataModel:OpenScreenshotsFolder",
		callback = function()
			local dm = __betterGetService("DataModel");
			return effect_test("Can open your Roblox screenshots folder on disk.", function()
				return dm:OpenScreenshotsFolder();
			end);
		end
	},
	{
		name = "DataModel:OpenVideosFolder",
		callback = function()
			local dm = __betterGetService("DataModel");
			return effect_test("Can open your Roblox videos folder on disk.", function()
				return dm:OpenVideosFolder();
			end);
		end
	},
	{
		name = "OmniRecommendationsService:MakeRequest",
		callback = function()
			local s_ok, srv = pcall(function()
				return __betterGetService("OmniRecommendationsService");
			end);
			if not s_ok or (not srv) then
				return "unknown", "OmniRecommendationsService is not available here.";
			end;
			return data_test("Can request recommendation data.", function()
				return srv:MakeRequest({});
			end);
		end
	},
	{
		name = "Players:ReportAbuse",
		callback = function()
			local plrs = __betterGetService("Players");
			return effect_test("Can send abuse reports from your account.", function()
				return plrs:ReportAbuse();
			end);
		end
	},
	{
		name = "Players:ReportAbuseV3",
		callback = function()
			local plrs = __betterGetService("Players");
			return effect_test("Can send V3 abuse reports from your account.", function()
				return plrs:ReportAbuseV3();
			end);
		end
	},
	{
		name = "Robux API",
		callback = function()
			if not (Vulnerabilities_Test.game_Get or Vulnerabilities_Test.game_Post or Vulnerabilities_Test.Request) then
				return "unknown", "Executor does not expose HTTP functions used in this Robux API test.";
			end;
			local results = {
				v1 = nil,
				v2 = nil,
				v3 = nil
			};
			pcall(function()
				if request then
					results.v1 = request({
						Url = "https://economy.roblox.com/v1/user/currency",
						Method = "GET"
					});
				end;
			end);
			pcall(function()
				results.v2 = game:HttpGet("https://economy.roblox.com/v1/user/currency");
			end);
			pcall(function()
				results.v3 = game:HttpPost("https://economy.roblox.com/v1/purchases/products/41762", "{\"expectedCurrency\":1,\"expectedPrice\":0,\"expectedSellerId\":116444}");
			end);
			if results.v1 ~= nil or results.v2 ~= nil or results.v3 ~= nil then
				return "unsafe", "At least one call to Roblox web APIs returned data (" .. shortVal((results.v1 or results.v2 or results.v3)) .. "). Web APIs are reachable.";
			end;
			return "safe", "All Roblox web API calls were blocked or returned nil.";
		end
	},
	{
		name = "RequestInternal",
		callback = function()
			local hs_ok, hs = pcall(function()
				return __betterGetService("HttpService");
			end);
			if not hs_ok or (not hs) then
				return "unknown", "HttpService is not available.";
			end;
			local ok0, req0 = pcall(function()
				return hs:RequestInternal({
					Url = "https://users.roblox.com/v1/users/authenticated",
					Method = "GET"
				});
			end);
			local ok1, req1 = pcall(function()
				local httpService = cloneref and cloneref(hs) or hs;
				local requestInternal = clonefunction and clonefunction(httpService.RequestInternal) or httpService.RequestInternal;
				return requestInternal(httpService, {
					Url = "https://auth.roblox.com/v1/logout",
					Method = "POST",
					Body = ""
				});
			end);
			if ok0 or ok1 then
				return "unsafe", "RequestInternal returned a request object (" .. shortVal(req0 or req1) .. "). Low-level Roblox HTTP is exposed.";
			end;
			return classify_error("Low-level Roblox HTTP (RequestInternal).", req0 or req1);
		end
	},
	{
		name = "ScriptContext:AddCoreScriptLocal (ProximityPrompt)",
		callback = function()
			local srv = __betterGetService("ScriptContext");
			return effect_test("Can inject the ProximityPrompt core script.", function()
				return srv:AddCoreScriptLocal("CoreScripts/ProximityPrompt", nil);
			end);
		end
	},
	{
		name = "MessageBusService:Publish (openURLRequest)",
		callback = function()
			local srv = __betterGetService("MessageBusService");
			local msgId = srv:GetMessageId("Linking", "openURLRequest");
			return effect_test("Can publish a message that asks the client to open URLs.", function()
				return srv:Publish(msgId, {});
			end);
		end
	},
	{
		name = "GuiService:OpenBrowserWindow (google.com)",
		callback = function()
			local srv = __betterGetService("GuiService");
			return effect_test("Can open a browser window on your machine.", function()
				return srv:OpenBrowserWindow();
			end);
		end
	},
	{
		name = "MarketplaceService:GetRobuxBalance",
		callback = function()
			local srv = __betterGetService("MarketplaceService");
			local ok, ret = pcall(function()
				return srv:GetRobuxBalance();
			end);
			if not ok then
				return "safe", "Roblox blocked Robux balance read with an error.";
			end;
			if ret == nil then
				return "safe", "GetRobuxBalance returned nil (likely stubbed). Your balance is not exposed here.";
			end;
			return "unsafe", "GetRobuxBalance returned a value (" .. shortVal(ret) .. "). Scripts can probably see your Robux.";
		end
	},
	{
		name = "MarketplaceService:PerformPurchase",
		callback = function()
			local srv = __betterGetService("MarketplaceService");
			return effect_test("Can try to perform purchases from your account.", function()
				return srv:PerformPurchase();
			end);
		end
	},
	{
		name = "HttpRbxApiService:GetAsyncFullUrl",
		callback = function()
			local s_ok, srv = pcall(function()
				return __betterGetService("HttpRbxApiService");
			end);
			if not s_ok or (not srv) then
				return "unknown", "HttpRbxApiService is not available here.";
			end;
			return data_test("Reads data from Roblox web APIs.", function()
				return srv:GetAsyncFullUrl("https://economy.roblox.com/v1/user/currency");
			end);
		end
	},
	{
		name = "MarketplaceService:PromptNativePurchaseWithLocalPlayer",
		callback = function()
			local srv = __betterGetService("MarketplaceService");
			return effect_test("Can open native purchase prompts with your account.", function()
				return srv:PromptNativePurchaseWithLocalPlayer();
			end);
		end
	},
	{
		name = "MarketplaceService:PromptNativePurchase",
		callback = function()
			local srv = __betterGetService("MarketplaceService");
			return effect_test("Can open native purchase prompts.", function()
				return srv:PromptNativePurchase();
			end);
		end
	},
	{
		name = "MarketplaceService:PromptCollectiblesPurchase",
		callback = function()
			local srv = __betterGetService("MarketplaceService");
			return effect_test("Can open collectibles purchase prompts.", function()
				return srv:PromptCollectiblesPurchase();
			end);
		end
	},
	{
		name = "CoreGui:TakeScreenshot",
		callback = function()
			local cg = __betterGetService("CoreGui");
			return effect_test("Can take screenshots from your game view.", function()
				return cg:TakeScreenshot();
			end);
		end
	},
	{
		name = "os.execute",
		callback = function()
			if type(os) ~= "table" or type(os.execute) ~= "function" then
				return "unknown", "os.execute is not exposed in this environment.";
			end;
			local ok, ret = pcall(function()
				return os.execute("echo test");
			end);
			if not ok then
				return "safe", "System commands (os.execute) are blocked with an error.";
			end;
			return "unsafe", "System commands can run (os.execute returned " .. shortVal(ret) .. "). This is very dangerous.";
		end
	},
	{
		name = "ContentProvider:PreloadAsync",
		callback = function()
			local srv = __betterGetService("ContentProvider");
			local plrs = __betterGetService("Players");
			return effect_test("Can preload all UIs, which can be abused for weird behavior.", function()
				local list = {};
				for _, v in ipairs(plrs:QueryDescendants("Instance")) do
					if v:IsA("ScreenGui") then
						table.insert(list, v);
					end;
				end;
				if #list > 0 then
					return srv:PreloadAsync(list);
				end;
			end);
		end
	},
	{
		name = "isfolder (C:\\)",
		callback = function()
			if type(isfolder) ~= "function" then
				return "unknown", "isfolder is not available in this executor.";
			end;
			return bool_test("Checks whether scripts can probe absolute Windows paths.", function()
				return isfolder("C:\\");
			end, "isfolder('C:\\') returned true. Absolute drive paths are visible to scripts.", "isfolder('C:\\') returned false/nil.");
		end
	},
	{
		name = "writefile/readfile",
		callback = function()
			if type(writefile) ~= "function" or type(readfile) ~= "function" then
				return "unknown", "writefile/readfile are not both available in this executor.";
			end;
			cleanup_fs_probe();
			if type(makefolder) == "function" then
				pcall(makefolder, FS_PROBE_DIR);
			end;
			local okWrite, errWrite = pcall(writefile, FS_PROBE_FILE, "VULNTEST_FS_CHECK");
			if not okWrite then
				cleanup_fs_probe();
				return classify_error("Local file write access.", errWrite);
			end;
			local okRead, contents = pcall(readfile, FS_PROBE_FILE);
			cleanup_fs_probe();
			if not okRead then
				return classify_error("Local file read access.", contents);
			end;
			if contents == "VULNTEST_FS_CHECK" then
				return "unsafe", "writefile/readfile successfully created and read a local file. Scripts can access executor storage.";
			end;
			return "unsafe", "writefile succeeded and readfile returned data (" .. shortVal(contents) .. "). Local file access is exposed.";
		end
	},
	{
		name = "appendfile",
		callback = function()
			if type(appendfile) ~= "function" or type(writefile) ~= "function" or type(readfile) ~= "function" then
				return "unknown", "appendfile/writefile/readfile are not all available in this executor.";
			end;
			cleanup_fs_probe();
			if type(makefolder) == "function" then
				pcall(makefolder, FS_PROBE_DIR);
			end;
			local okWrite, errWrite = pcall(writefile, FS_PROBE_FILE, "A");
			if not okWrite then
				cleanup_fs_probe();
				return classify_error("Seed file creation for appendfile.", errWrite);
			end;
			local okAppend, errAppend = pcall(appendfile, FS_PROBE_FILE, "B");
			if not okAppend then
				cleanup_fs_probe();
				return classify_error("Local file append access.", errAppend);
			end;
			local okRead, contents = pcall(readfile, FS_PROBE_FILE);
			cleanup_fs_probe();
			if okRead and contents == "AB" then
				return "unsafe", "appendfile modified a local file successfully. Scripts can alter executor files.";
			end;
			if okRead then
				return "unsafe", "appendfile ran and the file contents changed (" .. shortVal(contents) .. ").";
			end;
			return classify_error("Verification read after appendfile.", contents);
		end
	},
	{
		name = "loadfile",
		callback = function()
			if type(loadfile) ~= "function" or type(writefile) ~= "function" then
				return "unknown", "loadfile/writefile are not both available in this executor.";
			end;
			cleanup_fs_probe();
			if type(makefolder) == "function" then
				pcall(makefolder, FS_PROBE_DIR);
			end;
			local okWrite, errWrite = pcall(writefile, FS_PROBE_SCRIPT, "return 'VULNTEST_LOADFILE'");
			if not okWrite then
				cleanup_fs_probe();
				return classify_error("Seed script creation for loadfile.", errWrite);
			end;
			local okLoad, chunkOrErr = pcall(loadfile, FS_PROBE_SCRIPT);
			if not okLoad then
				cleanup_fs_probe();
				return classify_error("Loading local files as code.", chunkOrErr);
			end;
			local okRun, ret = pcall(chunkOrErr);
			cleanup_fs_probe();
			if okRun and ret == "VULNTEST_LOADFILE" then
				return "unsafe", "loadfile executed code from a local disk file. Local code execution is exposed.";
			end;
			if okRun then
				return "unsafe", "loadfile executed a local file and returned " .. shortVal(ret) .. ".";
			end;
			return classify_error("Executing a chunk returned by loadfile.", ret);
		end
	},
	{
		name = "dofile",
		callback = function()
			if type(dofile) ~= "function" or type(writefile) ~= "function" then
				return "unknown", "dofile/writefile are not both available in this executor.";
			end;
			cleanup_fs_probe();
			if type(makefolder) == "function" then
				pcall(makefolder, FS_PROBE_DIR);
			end;
			local okWrite, errWrite = pcall(writefile, FS_PROBE_SCRIPT, "return 'VULNTEST_DOFILE'");
			if not okWrite then
				cleanup_fs_probe();
				return classify_error("Seed script creation for dofile.", errWrite);
			end;
			local okRun, ret = pcall(dofile, FS_PROBE_SCRIPT);
			cleanup_fs_probe();
			if okRun and ret == "VULNTEST_DOFILE" then
				return "unsafe", "dofile executed code from a local disk file. This is a strong local file-system/code-exec exposure.";
			end;
			if okRun then
				return "unsafe", "dofile ran a local file and returned " .. shortVal(ret) .. ".";
			end;
			return classify_error("Executing local files with dofile.", ret);
		end
	},
	{
		name = "setclipboard",
		callback = function()
			if type(setclipboard) ~= "function" then
				return "unknown", "setclipboard is not exposed in this executor.";
			end;
			return effect_test("Can write arbitrary text to your clipboard.", function()
				return setclipboard("VulnTest clipboard probe");
			end);
		end
	},
	{
		name = "listfiles",
		callback = function()
			if type(listfiles) ~= "function" then
				return "unknown", "listfiles is not available in this executor.";
			end;
			local ok1, ret1 = pcall(function()
				return listfiles("");
			end);
			local ok2, ret2 = pcall(function()
				return listfiles("C:\\");
			end);
			if not ok1 and (not ok2) then
				return classify_error("Listing files through executor file APIs.", ret2 or ret1);
			end;
			if ret1 ~= nil or ret2 ~= nil then
				return "unsafe", "listfiles returned data (" .. shortVal((ret1 or ret2)) .. "). Scripts can probably read files on your executor/PC.";
			end;
			return "safe", "listfiles returned nil (likely stubbed).";
		end
	}
};
for _, s in ipairs(tests) do
	Vulnerabilities_Test.Running = Vulnerabilities_Test.Running + 1;
	local completed, callOk, resultStatus, resultInfo = run_with_timeout(s.callback, TEST_TIMEOUT);
	local status, info;
	if not completed then
		status = "unknown";
		info = resultInfo;
	elseif not callOk then
		status = "unknown";
		info = "The test itself crashed: " .. tostring(resultStatus);
	else
		status = resultStatus;
		info = resultInfo;
	end;
	if status == "safe" then
		Vulnerabilities_Test.Passes = Vulnerabilities_Test.Passes + 1;
		print(ICON_SAFE .. " " .. s.name .. " • " .. info);
	elseif status == "unsafe" then
		Vulnerabilities_Test.Fails = Vulnerabilities_Test.Fails + 1;
		warn(ICON_UNSAFE .. " " .. s.name .. " • " .. info);
	else
		Vulnerabilities_Test.Unknown = Vulnerabilities_Test.Unknown + 1;
		print(ICON_UNKNOWN .. " " .. s.name .. " • " .. (info or "Not supported / could not be tested."));
	end;
	Vulnerabilities_Test.Running = Vulnerabilities_Test.Running - 1;
end;
local total = Vulnerabilities_Test.Passes + Vulnerabilities_Test.Fails;
local rate = total > 0 and math.round(Vulnerabilities_Test.Passes / total * 100) or 0;
print("");
print("Vulnerability Check Summary - " .. formatExecutor());
print(ICON_SAFE .. " Safe tests: " .. Vulnerabilities_Test.Passes);
print(ICON_UNSAFE .. " Unsafe tests: " .. Vulnerabilities_Test.Fails);
print(ICON_UNKNOWN .. " Not tested / unsupported: " .. Vulnerabilities_Test.Unknown);
print("Score: " .. rate .. "% of the tested dangerous functions looked safe (blocked or nil).");
local verdict;
if Vulnerabilities_Test.Fails == 0 and total > 0 then
	verdict = "Excellent: all checked dangerous functions are blocked or stubbed.";
elseif rate >= 70 then
	verdict = "Decent: most dangerous functions are blocked, but there are still some risks.";
elseif rate >= 40 then
	verdict = "Meh: about half of the dangerous functions are open. This is not very safe.";
else
	verdict = "Bad: many dangerous functions are open. This executor is quite risky.";
end;
print("Human summary: " .. verdict);
if Vulnerabilities_Test.Fails > 0 then
	print("Look for the " .. ICON_UNSAFE .. " lines above to see exactly which functions are dangerous.");
end;
