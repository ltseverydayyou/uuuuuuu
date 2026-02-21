if
    getgenv().SimpleSpyExecuted
    and type(getgenv().SimpleSpyShutdown) == 'function'
then
    getgenv().SimpleSpyShutdown()
end

local realconfigs = {
    logcheckcaller = false,
    autoblock = false,
    funcEnabled = true,
    advancedinfo = false,
    --logreturnvalues = false,
    supersecretdevtoggle = false,
    log_FireServer = true,
    log_InvokeServer = true,
    call_FireServer = true,
    call_InvokeServer = true,
    log_Fire = true,
    log_Invoke = true,
    bufferDumpComments = false,
    log_Receive = true,
    adonisBypass = true,
    pathMode = 1,
    blockIncoming = true,
    ignorePlayerModule = false,
}

local configs = newproxy(true)
local configsmetatable = getmetatable(configs)

configsmetatable.__index = function(self, index)
    return realconfigs[index]
end

local oth = syn and syn.oth
local unhook = oth and oth.unhook
local hook = oth and oth.hook

local lower = string.lower
local byte = string.byte
local round = math.round
local running = coroutine.running
local resume = coroutine.resume
local status = coroutine.status
local yield = coroutine.yield
local create = coroutine.create
local close = coroutine.close
local OldDebugId = game.GetDebugId
local info = debug.info
local getregistry = (debug and debug.getregistry) or getreg
local getreg = getreg or getregistry

local function safeDebugInfo(target, what)
    if not info then
        return nil
    end

    local ok, result = pcall(info, target, what)
    return ok and result or nil
end

local function safeGetScriptFromThread(thread)
    if not getscriptfromthread or not thread then
        return nil
    end

    local ok, script = pcall(getscriptfromthread, thread)
    return ok and script or nil
end

local IsA = game.IsA
local tostring = tostring
local tonumber = tonumber
local delay = task.delay
local spawn = task.spawn
local clear = table.clear
local clone = table.clone

local function blankfunction(...)
    return ...
end

local get_thread_identity = (syn and syn.get_thread_identity)
    or getidentity
    or getthreadidentity
local set_thread_identity = (syn and syn.set_thread_identity) or setidentity
local islclosure = islclosure or is_l_closure
local threadfuncs = (get_thread_identity and set_thread_identity and true)
    or false

local getinfo = getinfo or blankfunction
local getupvalues = getupvalues or debug.getupvalues or blankfunction
local getconstants = getconstants or debug.getconstants or blankfunction

local getcustomasset = getsynasset or getcustomasset
local getcallingscript = getcallingscript or blankfunction
local newcclosure = newcclosure or blankfunction
local clonefunction = clonefunction or blankfunction
local cloneref = cloneref or blankfunction
local request = request or syn and syn.request
local isfunctionhooked = isfunctionhooked
local makewritable = makewriteable
    or function(tbl)
        setreadonly(tbl, false)
    end
local makereadonly = makereadonly
    or function(tbl)
        setreadonly(tbl, true)
    end
local isreadonly = isreadonly or table.isfrozen

local setclipboard = setclipboard
    or toclipboard
    or set_clipboard
    or (Clipboard and Clipboard.set)
    or function(...)
        return ErrorPrompt('Attempted to set clipboard: ' .. (...), true)
    end

local nativeHookMetamethod = hookmetamethod
local hookmetamethod = hookmetamethod
    or (makewriteable and makereadonly and getrawmetatable)
        and function(obj: object, metamethod: string, func: Function)
            local old = getrawmetatable(obj)

            if hookfunction then
                return hookfunction(old[metamethod], func)
            else
                local oldmetamethod = old[metamethod]
                makewriteable(old)
                old[metamethod] = func
                makereadonly(old)
                return oldmetamethod
            end
        end

local function Create(instance, properties, children)
    local obj = Instance.new(instance)

    for i, v in next, properties or {} do
        obj[i] = v
        for _, child in next, children or {} do
            child.Parent = obj
        end
    end
    return obj
end

local function SafeGetService(name)
    local Service = game.GetService
    local Reference = cloneref
        or function(reference)
            return reference
        end
    return Reference(Service(game, name))
end

local function protectUI(sGui)
    if sGui:IsA('ScreenGui') then
        sGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
        sGui.DisplayOrder = 999999999
        sGui.ResetOnSpawn = false
        --sGui.IgnoreGuiInset = true
    end
    local cGUI = SafeGetService('CoreGui')
    local lPlr = SafeGetService('Players').LocalPlayer

    local function NAProtection(inst, var)
        if inst then
            if var then
                inst[var] = '\0'
                inst.Archivable = false
            else
                inst.Name = '\0'
                inst.Archivable = false
            end
        end
    end

    if gethui then
        NAProtection(sGui)
        sGui.Parent = gethui()
        return sGui
    elseif cGUI and cGUI:FindFirstChild('RobloxGui') then
        NAProtection(sGui)
        sGui.Parent = cGUI:FindFirstChild('RobloxGui')
        return sGui
    elseif cGUI then
        NAProtection(sGui)
        sGui.Parent = cGUI
        return sGui
    elseif lPlr and lPlr:FindFirstChildWhichIsA('PlayerGui') then
        NAProtection(sGui)
        sGui.Parent = lPlr:FindFirstChildWhichIsA('PlayerGui')
        sGui.ResetOnSpawn = false
        return sGui
    else
        return nil
    end
end

local function resolveAdonisEnv()
    local gc = getgc or (debug and debug.getgc)
    local hookf = hookfunction
    local env = getrenv
    local dbgInfo = (env and env().debug and env().debug.info) or (debug and debug.info)
    local newcc = newcclosure or function(fn)
        return fn
    end
    local typeOf = typeof or function(value)
        return type(value)
    end
    return gc, hookf, env, dbgInfo, newcc, typeOf
end

local function detectAdonis()
    local gc, hookf, env, dbgInfo, _, typeOf = resolveAdonisEnv()
    if not (gc and hookf and env and dbgInfo) then
        return false
    end

    for _, value in gc(true) do
        if typeOf(value) == 'table' then
            local hasDetected = typeOf(rawget(value, 'Detected')) == 'function'
            local hasKill = typeOf(rawget(value, 'Kill')) == 'function'
            local hasVars = rawget(value, 'Variables') ~= nil
            local hasProcess = rawget(value, 'Process') ~= nil

            if hasDetected or (hasKill and hasVars and hasProcess) then
                return true
            end
        end
    end

    return false
end

local function bypassAdonis()
    local gc, hookf, env, dbgInfo, newcc, typeOf = resolveAdonisEnv()
    if not (gc and hookf and env and dbgInfo) then
        return false
    end

    local DetectedMeth, KillMeth

    for _, value in gc(true) do
        if typeOf(value) == 'table' then
            local detected = rawget(value, 'Detected')
            local kill = rawget(value, 'Kill')

            if typeOf(detected) == 'function' and not DetectedMeth then
                DetectedMeth = detected
                local old
                old = hookf(DetectedMeth, function(methodName, methodFunc)
                    if methodName ~= '_' then end
                    return true
                end)
            end

            if rawget(value, 'Variables') and rawget(value, 'Process') and typeOf(kill) == 'function' and not KillMeth then
                KillMeth = kill
                local old
                old = hookf(KillMeth, function(killFunc) end)
            end

            if DetectedMeth and KillMeth then
                break
            end
        end
    end

    if DetectedMeth and dbgInfo then
        local old
        old = hookf(dbgInfo, newcc(function(...)
            local functionName = ...
            if functionName == DetectedMeth then
                return coroutine.yield(coroutine.running())
            end
            return old(...)
        end))
    end

    return DetectedMeth ~= nil
end

local function runAdonisBypass()
    if not configs.adonisBypass or getgenv().SimpleSpyAdonisBypassed then
        return
    end

    local ok, detected = pcall(detectAdonis)
    if ok and detected and bypassAdonis() then
        getgenv().SimpleSpyAdonisBypassed = true
    end
end

local function Search(logtable, tbl)
    table.insert(logtable, tbl)

    for i, v in tbl do
        if type(v) == 'table' then
            return table.find(logtable, v) ~= nil or Search(v)
        end
    end
end

local function IsCyclicTable(tbl)
    local checkedtables = {}

    local function SearchTable(tbl)
        table.insert(checkedtables, tbl)

        for i, v in next, tbl do -- Stupid mistake on my part thanks 59it for pointing it out
            if type(v) == 'table' then
                return table.find(checkedtables, v) and true or SearchTable(v)
            end
        end
    end

    return SearchTable(tbl)
end

local function deepclone(args: table, copies: table): table
    local copy = nil
    copies = copies or {}

    if type(args) == 'table' then
        if copies[args] then
            copy = copies[args]
        else
            copy = {}
            copies[args] = copy
            for i, v in next, args do
                copy[deepclone(i, copies)] = deepclone(v, copies)
            end
        end
    elseif typeof(args) == 'Instance' then
        copy = cloneref(args)
    else
        copy = args
    end
    return copy
end

local function rawtostring(userdata)
    if type(userdata) == 'table' or typeof(userdata) == 'userdata' then
        local rawmetatable = type(getrawmetatable) == 'function'
            and getrawmetatable(userdata)
        local cachedstring = rawmetatable and rawget(rawmetatable, '__tostring')

        if cachedstring then
            local wasreadonly = isreadonly(rawmetatable)
            if wasreadonly then
                makewritable(rawmetatable)
            end
            rawset(rawmetatable, '__tostring', nil)
            local safestring = tostring(userdata)
            rawset(rawmetatable, '__tostring', cachedstring)
            if wasreadonly then
                makereadonly(rawmetatable)
            end
            return safestring
        end
    end
    return tostring(userdata)
end

local CoreGui = SafeGetService('CoreGui')
local Players = SafeGetService('Players')
local RunService = SafeGetService('RunService')
local UserInputService = SafeGetService('UserInputService')
local TweenService = SafeGetService('TweenService')
local ContentProvider = SafeGetService('ContentProvider')
local TextService = SafeGetService('TextService')
local http = SafeGetService('HttpService')
local GuiInset = SafeGetService('GuiService'):GetGuiInset() :: Vector2 -- pulled from rewrite

local function jsone(str)
    return http:JSONEncode(str)
end
local function jsond(str)
    local suc, err = pcall(http.JSONDecode, http, str)
    return suc and err or suc
end

function ErrorPrompt(Message, state)
    local shown = false
    if getrenv then
        local env = getrenv()
        local req = env and env.require
        if type(req) == 'function' then
            local okModule, ErrorPromptModule = pcall(
                req,
                CoreGui:WaitForChild('RobloxGui')
                    :WaitForChild('Modules')
                    :WaitForChild('ErrorPrompt')
            )
            if
                okModule
                and type(ErrorPromptModule) == 'table'
                and type(ErrorPromptModule.new) == 'function'
            then
                local okPrompt, prompt =
                    pcall(ErrorPromptModule.new, 'Default', { HideErrorCode = true })
                if okPrompt and prompt then
                    local ErrorStoarge =
                        Create('ScreenGui', { Parent = CoreGui, ResetOnSpawn = false })
                    local thread
                    if state and coroutine.isyieldable then
                        local okYieldable, isYieldable =
                            pcall(coroutine.isyieldable)
                        if okYieldable and isYieldable then
                            thread = running()
                        end
                    end
                    local okShow = pcall(function()
                        prompt:setParent(ErrorStoarge)
                        prompt:setErrorTitle('Simple Spy V3 Error')
                        prompt:updateButtons({
                            {
                                Text = 'Proceed',
                                Callback = function()
                                    prompt:_close()
                                    ErrorStoarge:Destroy()
                                    if thread then
                                        resume(thread)
                                    end
                                end,
                                Primary = true,
                            },
                        }, 'Default')
                        prompt:_open(Message)
                    end)
                    if okShow then
                        shown = true
                        if thread then
                            yield(thread)
                        end
                    else
                        ErrorStoarge:Destroy()
                    end
                end
            end
        end
    end
    if not shown then
        warn(Message)
    end
end

local Highlight = (
    isfile
    and loadfile
    and isfile('Highlight.lua')
    and loadfile('Highlight.lua')()
)

if not Highlight and type(loadstring) == 'function' then
    local ok, loaded = pcall(function()
        return loadstring(
            game:HttpGet(
                'https://raw.githubusercontent.com/78n/SimpleSpy/main/Highlight.lua'
            )
        )()
    end)
    if ok then
        Highlight = loaded
    end
end

if type(Highlight) ~= 'table' or type(Highlight.new) ~= 'function' then
    Highlight = {
        new = function(parent)
            local textBox = Create('TextBox', {
                Parent = parent,
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(4, 2),
                Size = UDim2.new(1, -8, 1, -4),
                Text = '',
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextSize = 14,
                Font = Enum.Font.Code,
                ClearTextOnFocus = false,
                MultiLine = true,
            })
            return {
                setRaw = function(_, text)
                    textBox.Text = tostring(text or '')
                end,
                getString = function()
                    return textBox.Text or ''
                end,
            }
        end,
    }
end

local ui = {}
do
    ui.SimpleSpy3 = Create('ScreenGui', { ResetOnSpawn = false })
    ui.Storage = Create('Folder', {})
    ui.Background = Create('Frame', {
        Parent = ui.SimpleSpy3,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 500, 0, 200),
        Size = UDim2.new(0, 450, 0, 268),
    })
    ui.LeftPanel = Create('Frame', {
        Parent = ui.Background,
        BackgroundColor3 = Color3.fromRGB(53, 52, 55),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 19),
        Size = UDim2.new(0, 131, 0, 249),
    })
    ui.LogList = Create('ScrollingFrame', {
        Parent = ui.LeftPanel,
        Active = true,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 9),
        Size = UDim2.new(0, 131, 0, 232),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
    })
    ui.UIListLayout = Create('UIListLayout', {
        Parent = ui.LogList,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    ui.RightPanel = Create('Frame', {
        Parent = ui.Background,
        BackgroundColor3 = Color3.fromRGB(37, 36, 38),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 131, 0, 19),
        Size = UDim2.new(0, 319, 0, 249),
    })
    ui.CodeBox = Create('Frame', {
        Parent = ui.RightPanel,
        BackgroundColor3 = Color3.new(0.0823529, 0.0745098, 0.0784314),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 319, 0, 119),
    })
    ui.ScrollingFrame = Create('ScrollingFrame', {
        Parent = ui.RightPanel,
        Active = true,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0.5, -9),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
    })
    ui.UIGridLayout = Create('UIGridLayout', {
        Parent = ui.ScrollingFrame,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        CellPadding = UDim2.new(0, 0, 0, 0),
        CellSize = UDim2.new(0, 94, 0, 27),
    })
    ui.TopBar = Create('Frame', {
        Parent = ui.Background,
        Active = true,
        BackgroundColor3 = Color3.fromRGB(37, 35, 38),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 450, 0, 19),
    })
    ui.Simple = Create('TextButton', {
        Parent = ui.TopBar,
        BackgroundColor3 = Color3.new(1, 1, 1),
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 5, 0, 0),
        Size = UDim2.new(0, 57, 0, 18),
        Font = Enum.Font.SourceSansBold,
        Text = 'SimpleSpy',
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    ui.CloseButton = Create('TextButton', {
        Parent = ui.TopBar,
        BackgroundColor3 = Color3.new(0.145098, 0.141176, 0.14902),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -19, 0, 0),
        Size = UDim2.new(0, 19, 0, 19),
        Font = Enum.Font.SourceSans,
        Text = '',
        TextColor3 = Color3.new(0, 0, 0),
        TextSize = 14,
    })
    ui.ImageLabelClose = Create('ImageLabel', {
        Parent = ui.CloseButton,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 5, 0, 5),
        Size = UDim2.new(0, 9, 0, 9),
        Image = 'http://www.roblox.com/asset/?id=5597086202',
    })
    ui.MaximizeButton = Create('TextButton', {
        Parent = ui.TopBar,
        BackgroundColor3 = Color3.new(0.145098, 0.141176, 0.14902),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -38, 0, 0),
        Size = UDim2.new(0, 19, 0, 19),
        Font = Enum.Font.SourceSans,
        Text = '',
        TextColor3 = Color3.new(0, 0, 0),
        TextSize = 14,
    })
    ui.ImageLabelMax = Create('ImageLabel', {
        Parent = ui.MaximizeButton,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 5, 0, 5),
        Size = UDim2.new(0, 9, 0, 9),
        Image = 'http://www.roblox.com/asset/?id=5597108117',
    })
    ui.MinimizeButton = Create('TextButton', {
        Parent = ui.TopBar,
        BackgroundColor3 = Color3.new(0.145098, 0.141176, 0.14902),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -57, 0, 0),
        Size = UDim2.new(0, 19, 0, 19),
        Font = Enum.Font.SourceSans,
        Text = '',
        TextColor3 = Color3.new(0, 0, 0),
        TextSize = 14,
    })
    ui.ImageLabelMin = Create('ImageLabel', {
        Parent = ui.MinimizeButton,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 5, 0, 5),
        Size = UDim2.new(0, 9, 0, 9),
        Image = 'http://www.roblox.com/asset/?id=5597105827',
    })
    ui.NextButton = Create('TextButton', {
        Parent = ui.SimpleSpy3,
        Position = UDim2.new(0, 100, 0, 60),
        ZIndex = 5,
        BackgroundColor3 = Color3.fromRGB(53, 52, 55),
        Text = '-',
        TextScaled = true,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        AutoButtonColor = false,
        Size = UDim2.new(0, 35, 0, 35),
        Active = true,
    })
    Create('UICorner', { Parent = ui.NextButton })
    ui.ToolTip = Create('Frame', {
        Parent = ui.SimpleSpy3,
        BackgroundColor3 = Color3.fromRGB(26, 26, 26),
        BackgroundTransparency = 0.1,
        BorderColor3 = Color3.new(1, 1, 1),
        Size = UDim2.new(0, 200, 0, 50),
        ZIndex = 3,
        Visible = false,
    })
    ui.TextLabel = Create('TextLabel', {
        Parent = ui.ToolTip,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 2, 0, 2),
        Size = UDim2.new(0, 196, 0, 46),
        ZIndex = 3,
        Font = Enum.Font.SourceSans,
        Text = 'This is some slightly longer text.',
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
    })
end

-------------------------------------------------------------------------------

local selectedColor = Color3.new(0.321569, 0.333333, 1)
local deselectedColor = Color3.new(0.8, 0.8, 0.8)
--- So things are descending
local layoutOrderNum = 999999999
--- Whether or not the gui is closing
local mainClosing = false
--- Whether or not the gui is closed (defaults to false)
local closed = false
--- Whether or not the sidebar is closing
local sideClosing = false
--- Whether or not the sidebar is closed (defaults to true but opens automatically on remote selection)
local sideClosed = false
--- Whether or not the code box is maximized (defaults to false)
local maximized = false
--- The event logs to be read from
local logs = {}
--- The event currently selected.Log (defaults to nil)
local selected = nil
--- The blacklist (can be a string name or the Remote Instance)
local blacklist = {}
--- The block list (can be a string name or the Remote Instance)
local blocklist = {}
--- Whether or not to add getNil function
local getNil = false
--- Array of remotes (and original functions) connected to
local connectedRemotes = {}
--- True = hookfunction, false = namecall
local toggle = false
--- used to prevent recursives
local prevTables = {}
--- holds logs (for deletion)
local remoteLogs = {}
--- used for hookfunction
getgenv().SIMPLESPYCONFIG_MaxRemotes = 300
getgenv().SIMPLESPYCONFIG_SchedulerBurst = 12
local indent = 4
local scheduled = {}
local schedulerconnect
local SimpleSpy = {}
local topstr = ''
local bottomstr = ''
local remotesFadeIn
local rightFadeIn
local codebox
local p
local getnilrequired = false

-- autoblock variables
local history = {}
local excluding = {}

-- if mouse inside gui
local mouseInGui = false

local connections = {}
local DecompiledScripts = {}
local generation = {}
local running_threads = {}
local originalnamecall

local remoteEvent = Instance.new('RemoteEvent', ui.Storage)
local remoteFunction = Instance.new('RemoteFunction', ui.Storage)
local originalBindableEventFire
local originalBindableFunctionInvoke
local NamecallHandler = Instance.new('BindableEvent', ui.Storage)
local IndexHandler = Instance.new('BindableEvent', ui.Storage)
local GetDebugIdHandler = Instance.new('BindableFunction', ui.Storage) --Thanks engo for the idea of using BindableFunctions
local loggedClientEvent, wrappedClientInvoke = {}, {}
local _origClientInvoke = setmetatable({}, { __mode = 'k' })
local wrappedInvokeCallbacks = setmetatable({}, { __mode = 'k' })

local originalEvent = remoteEvent.FireServer
local originalFunction = remoteFunction.InvokeServer
local GetDebugIDInvoke = GetDebugIdHandler.Invoke
local internalRemotes = setmetatable({}, { __mode = 'k' })
local preferIndexPaths = false
local preferIndexOverride = rawget(getgenv(), 'SimpleSpyPreferIndexPaths')
if preferIndexOverride ~= nil then
    preferIndexPaths = not not preferIndexOverride
end

local returnPreviewLimit = rawget(getgenv(), 'SimpleSpyReturnPreviewLimit')
if type(returnPreviewLimit) ~= 'number' then
    returnPreviewLimit = 400
elseif returnPreviewLimit < 0 then
    returnPreviewLimit = 0
end
local bufferDumpEnabled = not not realconfigs.bufferDumpComments
local bufferDumpOverride = rawget(getgenv(), 'SimpleSpyBufferDumper')
if bufferDumpOverride ~= nil then
    bufferDumpEnabled = not not bufferDumpOverride
else
    realconfigs.bufferDumpComments = bufferDumpEnabled
end

local function markInternal(obj)
    if typeof(obj) ~= 'Instance' then
        return
    end
    internalRemotes[obj] = true
    local ok, ref = pcall(cloneref, obj)
    if ok and ref then
        internalRemotes[ref] = true
    end
end

markInternal(remoteEvent)
markInternal(remoteFunction)
markInternal(NamecallHandler)
markInternal(IndexHandler)
markInternal(GetDebugIdHandler)

function GetDebugIdHandler.OnInvoke(obj: Instance) -- To avoid having to set thread identity and ect
    return OldDebugId(obj)
end

local function ThreadGetDebugId(obj: Instance): string
    return GetDebugIDInvoke(GetDebugIdHandler, obj) -- indexing to avoid having to setnamecall later
end

local synv3 = false

if syn and identifyexecutor then
    local _, version = identifyexecutor()
    if version and version:sub(1, 2) == 'v3' then
        synv3 = true
    end
end

local caps = {
    hookFunction = type(hookfunction) == 'function',
    hookAPI = type(hook) == 'function',
    unhookAPI = type(unhook) == 'function',
    restoreFunction = type(restorefunction) == 'function',
    rawMetatable = type(getrawmetatable) == 'function',
    getNamecallMethod = type(getnamecallmethod) == 'function',
    checkCaller = type(checkcaller) == 'function',
    getConnections = type(getconnections) == 'function',
    decompile = type(decompile) == 'function',
}
caps.anyHookMetamethod = type(nativeHookMetamethod) == 'function'
    or (caps.hookFunction and caps.rawMetatable)
    or (type(setreadonly) == 'function' and caps.rawMetatable)
caps.namecallHook = caps.getNamecallMethod
    and ((synv3 and caps.hookAPI and caps.rawMetatable) or caps.anyHookMetamethod)
caps.sendHooks = caps.namecallHook
    or ((synv3 and caps.hookAPI) or caps.hookFunction)
caps.newIndexHook = caps.anyHookMetamethod and caps.checkCaller

local function safeCheckCaller()
    if not caps.checkCaller then
        return false
    end
    local ok, result = pcall(checkcaller)
    return ok and result or false
end

xpcall(function()
    if isfile and readfile and isfolder and makefolder then
        local cachedconfigs = isfile('SimpleSpy//Settings.json')
            and jsond(readfile('SimpleSpy//Settings.json'))

        if cachedconfigs then
            for i, v in next, realconfigs do
                if cachedconfigs[i] == nil then
                    cachedconfigs[i] = v
                end
            end
            realconfigs = cachedconfigs
        end

        if not isfolder('SimpleSpy') then
            makefolder('SimpleSpy')
        end
        if not isfolder('SimpleSpy//Assets') then
            makefolder('SimpleSpy//Assets')
        end
        if not isfile('SimpleSpy//Settings.json') then
            writefile('SimpleSpy//Settings.json', jsone(realconfigs))
        end

        configsmetatable.__newindex = function(self, index, newindex)
            realconfigs[index] = newindex
            spawn(function()
                local okEncode, encoded = pcall(jsone, realconfigs)
                if okEncode and type(encoded) == 'string' then
                    pcall(writefile, 'SimpleSpy//Settings.json', encoded)
                end
            end)
        end
    else
        configsmetatable.__newindex = function(self, index, newindex)
            realconfigs[index] = newindex
        end
    end
end, function(err)
    ErrorPrompt(('An error has occured: (%s)'):format(err))
end)

local function logthread(thread: thread)
    table.insert(running_threads, thread)
end

--- Prevents remote spam from causing lag (clears logs after `getgenv().SIMPLESPYCONFIG_MaxRemotes` or 500 remotes)
function clean()
    local max = getgenv().SIMPLESPYCONFIG_MaxRemotes
    if not typeof(max) == 'number' and math.floor(max) ~= max then
        max = 500
    end
    if #remoteLogs > max then
        for i = 100, #remoteLogs do
            local v = remoteLogs[i]
            if typeof(v[1]) == 'RBXScriptConnection' then
                v[1]:Disconnect()
            end
            if typeof(v[2]) == 'Instance' then
                v[2]:Destroy()
            end
        end
        local newLogs = {}
        for i = 1, 100 do
            table.insert(newLogs, remoteLogs[i])
        end
        remoteLogs = newLogs
    end
end

local function ThreadIsNotDead(thread: thread): boolean
    return not status(thread) == 'dead'
end

--- Scales the ui.ToolTip to fit containing text
function scaleToolTip()
    local size = TextService:GetTextSize(
        ui.TextLabel.Text,
        ui.TextLabel.TextSize,
        ui.TextLabel.Font,
        Vector2.new(196, math.huge)
    )
    ui.TextLabel.Size = UDim2.new(0, size.X, 0, size.Y)
    ui.ToolTip.Size = UDim2.new(0, size.X + 4, 0, size.Y + 4)
end

--- Executed when the toggle button (the SimpleSpy logo) is hovered over
function onToggleButtonHover()
    if not toggle then
        TweenService:Create(
            ui.Simple,
            TweenInfo.new(0.5),
            { TextColor3 = Color3.fromRGB(252, 51, 51) }
        ):Play()
    else
        TweenService:Create(
            ui.Simple,
            TweenInfo.new(0.5),
            { TextColor3 = Color3.fromRGB(68, 206, 91) }
        ):Play()
    end
end

--- Executed when the toggle button is unhovered over
function onToggleButtonUnhover()
    TweenService:Create(
        ui.Simple,
        TweenInfo.new(0.5),
        { TextColor3 = Color3.fromRGB(255, 255, 255) }
    ):Play()
end

--- Executed when the X button is hovered over
function onXButtonHover()
    TweenService:Create(
        ui.CloseButton,
        TweenInfo.new(0.2),
        { BackgroundColor3 = Color3.fromRGB(255, 60, 60) }
    ):Play()
end

--- Executed when the X button is unhovered over
function onXButtonUnhover()
    TweenService:Create(
        ui.CloseButton,
        TweenInfo.new(0.2),
        { BackgroundColor3 = Color3.fromRGB(37, 36, 38) }
    ):Play()
end

--- Toggles the remote spy method (when button clicked)
function onToggleButtonClick()
    if toggle then
        TweenService:Create(
            ui.Simple,
            TweenInfo.new(0.5),
            { TextColor3 = Color3.fromRGB(252, 51, 51) }
        ):Play()
    else
        TweenService:Create(
            ui.Simple,
            TweenInfo.new(0.5),
            { TextColor3 = Color3.fromRGB(68, 206, 91) }
        ):Play()
    end
    toggleSpyMethod()
end

--- Reconnects bringBackOnResize if the current viewport changes and also connects it initially
function connectResize()
    if not SafeGetService('Workspace').CurrentCamera then
        SafeGetService('Workspace')
            :GetPropertyChangedSignal('CurrentCamera')
            :Wait()
    end
    local lastCam = SafeGetService('Workspace').CurrentCamera
        :GetPropertyChangedSignal('ViewportSize')
        :Connect(bringBackOnResize)
    SafeGetService('Workspace')
        :GetPropertyChangedSignal('CurrentCamera')
        :Connect(function()
            lastCam:Disconnect()
            if typeof(lastCam) == 'Connection' then
                lastCam:Disconnect()
            end
            lastCam = SafeGetService('Workspace').CurrentCamera
                :GetPropertyChangedSignal('ViewportSize')
                :Connect(bringBackOnResize)
        end)
end

--- Brings gui back if it gets lost offscreen (connected to the camera viewport changing)
function bringBackOnResize()
    validateSize()
    if sideClosed then
        minimizeSize()
    else
        maximizeSize()
    end
    local currentX = ui.Background.AbsolutePosition.X
    local currentY = ui.Background.AbsolutePosition.Y
    local viewportSize = SafeGetService('Workspace').CurrentCamera.ViewportSize
    if
        (currentX < 0)
        or (
            currentX
            > (
                viewportSize.X
                - (sideClosed and 131 or ui.Background.AbsoluteSize.X)
            )
        )
    then
        if currentX < 0 then
            currentX = 0
        else
            currentX = viewportSize.X
                - (sideClosed and 131 or ui.Background.AbsoluteSize.X)
        end
    end
    if
        (currentY < 0)
        or (
            currentY
            > (
                viewportSize.Y
                - (closed and 19 or ui.Background.AbsoluteSize.Y)
                - GuiInset.Y
            )
        )
    then
        if currentY < 0 then
            currentY = 0
        else
            currentY = viewportSize.Y
                - (closed and 19 or ui.Background.AbsoluteSize.Y)
                - GuiInset.Y
        end
    end
    TweenService.Create(
        TweenService,
        ui.Background,
        TweenInfo.new(0.1),
        { Position = UDim2.new(0, currentX, 0, currentY) }
    ):Play()
end

--- Drags gui (so long as mouse is held down)
--- @param input InputObject
function onBarInput(input)
    if
        input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        local lastPos = UserInputService:GetMouseLocation()
        local mainPos = ui.Background.AbsolutePosition
        local offset = mainPos - lastPos
        local currentPos = offset + lastPos
        if not connections['drag'] then
            connections['drag'] = RunService.RenderStepped:Connect(function()
                local newPos = UserInputService:GetMouseLocation()
                if newPos ~= lastPos then
                    local currentX = (offset + newPos).X
                    local currentY = (offset + newPos).Y
                    local viewportSize =
                        SafeGetService('Workspace').CurrentCamera.ViewportSize
                    if
                        (currentX < 0 and currentX < currentPos.X)
                        or (
                            currentX
                                > (viewportSize.X - (sideClosed and 131 or ui.TopBar.AbsoluteSize.X))
                            and currentX > currentPos.X
                        )
                    then
                        if currentX < 0 then
                            currentX = 0
                        else
                            currentX = viewportSize.X
                                - (sideClosed and 131 or ui.TopBar.AbsoluteSize.X)
                        end
                    end
                    if
                        (currentY < 0 and currentY < currentPos.Y)
                        or (
                            currentY
                                > (viewportSize.Y - (closed and 19 or ui.Background.AbsoluteSize.Y) - GuiInset.Y)
                            and currentY > currentPos.Y
                        )
                    then
                        if currentY < 0 then
                            currentY = 0
                        else
                            currentY = viewportSize.Y
                                - (closed and 19 or ui.Background.AbsoluteSize.Y)
                                - GuiInset.Y
                        end
                    end
                    currentPos = Vector2.new(currentX, currentY)
                    lastPos = newPos
                    TweenService.Create(
                        TweenService,
                        ui.Background,
                        TweenInfo.new(0.1),
                        {
                            Position = UDim2.new(
                                0,
                                currentPos.X,
                                0,
                                currentPos.Y
                            ),
                        }
                    )
                        :Play()
                end
            end)
        end
        table.insert(
            connections,
            UserInputService.InputEnded:Connect(function(inputE)
                if input == inputE then
                    if connections['drag'] then
                        connections['drag']:Disconnect()
                        connections['drag'] = nil
                    end
                end
            end)
        )
    end
end

--- Fades out the table of elements (and makes them invisible), returns a function to make them visible again
function fadeOut(elements)
    local data = {}
    for _, v in next, elements do
        if typeof(v) == 'Instance' and v:IsA('GuiObject') and v.Visible then
            spawn(function()
                data[v] = {
                    BackgroundTransparency = v.BackgroundTransparency,
                }
                TweenService
                    :Create(
                        v,
                        TweenInfo.new(0.5),
                        { BackgroundTransparency = 1 }
                    )
                    :Play()
                if
                    v:IsA('TextBox')
                    or v:IsA('TextButton')
                    or v:IsA('TextLabel')
                then
                    data[v].TextTransparency = v.TextTransparency
                    TweenService
                        :Create(v, TweenInfo.new(0.5), { TextTransparency = 1 })
                        :Play()
                elseif v:IsA('ImageButton') or v:IsA('ImageLabel') then
                    data[v].ImageTransparency = v.ImageTransparency
                    TweenService
                        :Create(
                            v,
                            TweenInfo.new(0.5),
                            { ImageTransparency = 1 }
                        )
                        :Play()
                end
                delay(0.5, function()
                    v.Visible = false
                    for i, x in next, data[v] do
                        v[i] = x
                    end
                    data[v] = true
                end)
            end)
        end
    end
    return function()
        for i, _ in next, data do
            spawn(function()
                local properties = {
                    BackgroundTransparency = i.BackgroundTransparency,
                }
                i.BackgroundTransparency = 1
                TweenService
                    :Create(i, TweenInfo.new(0.5), {
                        BackgroundTransparency = properties.BackgroundTransparency,
                    })
                    :Play()
                if
                    i:IsA('TextBox')
                    or i:IsA('TextButton')
                    or i:IsA('TextLabel')
                then
                    properties.TextTransparency = i.TextTransparency
                    i.TextTransparency = 1
                    TweenService
                        :Create(
                            i,
                            TweenInfo.new(0.5),
                            { TextTransparency = properties.TextTransparency }
                        )
                        :Play()
                elseif i:IsA('ImageButton') or i:IsA('ImageLabel') then
                    properties.ImageTransparency = i.ImageTransparency
                    i.ImageTransparency = 1
                    TweenService
                        :Create(
                            i,
                            TweenInfo.new(0.5),
                            { ImageTransparency = properties.ImageTransparency }
                        )
                        :Play()
                end
                i.Visible = true
            end)
        end
    end
end

--- Expands and minimizes the gui (closed is the toggle boolean)
function toggleMinimize(override)
    if mainClosing and not override or maximized then
        return
    end
    mainClosing = true
    closed = not closed
    if closed then
        if not sideClosed then
            toggleSideTray(true)
        end
        ui.LeftPanel.Visible = true
        remotesFadeIn = fadeOut(ui.LeftPanel:GetDescendants())
        TweenService:Create(
            ui.LeftPanel,
            TweenInfo.new(0.5),
            { Size = UDim2.new(0, 131, 0, 0) }
        ):Play()
        wait(0.5)
    else
        TweenService:Create(
            ui.LeftPanel,
            TweenInfo.new(0.5),
            { Size = UDim2.new(0, 131, 0, 249) }
        ):Play()
        wait(0.5)
        if remotesFadeIn then
            remotesFadeIn()
            remotesFadeIn = nil
        end
        bringBackOnResize()
    end
    mainClosing = false
end

--- Expands and minimizes the sidebar (sideClosed is the toggle boolean)
function toggleSideTray(override)
    if sideClosing and not override or maximized then
        return
    end
    sideClosing = true
    sideClosed = not sideClosed
    if sideClosed then
        rightFadeIn = fadeOut(ui.RightPanel:GetDescendants())
        wait(0.5)
        minimizeSize(0.5)
        wait(0.5)
        ui.RightPanel.Visible = false
    else
        if closed then
            toggleMinimize(true)
        end
        ui.RightPanel.Visible = true
        maximizeSize(0.5)
        wait(0.5)
        if rightFadeIn then
            rightFadeIn()
        end
        bringBackOnResize()
    end
    sideClosing = false
end

--- Expands code box to fit screen for more convenient viewing
function toggleMaximize()
    if not sideClosed and not maximized then
        maximized = true
        local disable = Instance.new('TextButton')
        local prevSize =
            UDim2.new(0, ui.CodeBox.AbsoluteSize.X, 0, ui.CodeBox.AbsoluteSize.Y)
        local prevPos = UDim2.new(
            0,
            ui.CodeBox.AbsolutePosition.X,
            0,
            ui.CodeBox.AbsolutePosition.Y
        )
        disable.Size = UDim2.new(1, 0, 1, 0)
        disable.BackgroundColor3 = Color3.new()
        disable.BorderSizePixel = 0
        disable.Text = 0
        disable.ZIndex = 3
        disable.BackgroundTransparency = 1
        disable.AutoButtonColor = false
        ui.CodeBox.ZIndex = 4
        ui.CodeBox.Position = prevPos
        ui.CodeBox.Size = prevSize
        TweenService:Create(ui.CodeBox, TweenInfo.new(0.5), {
            Size = UDim2.new(0.5, 0, 0.5, 0),
            Position = UDim2.new(0.25, 0, 0.25, 0),
        }):Play()
        TweenService
            :Create(
                disable,
                TweenInfo.new(0.5),
                { BackgroundTransparency = 0.5 }
            )
            :Play()
        disable.MouseButton1Click:Connect(function()
            if
                UserInputService:GetMouseLocation().Y + GuiInset.Y
                    >= ui.CodeBox.AbsolutePosition.Y
                and UserInputService:GetMouseLocation().Y + GuiInset.Y <= ui.CodeBox.AbsolutePosition.Y + ui.CodeBox.AbsoluteSize.Y
                and UserInputService:GetMouseLocation().X >= ui.CodeBox.AbsolutePosition.X
                and UserInputService:GetMouseLocation().X
                    <= ui.CodeBox.AbsolutePosition.X + ui.CodeBox.AbsoluteSize.X
            then
                return
            end
            TweenService:Create(
                ui.CodeBox,
                TweenInfo.new(0.5),
                { Size = prevSize, Position = prevPos }
            ):Play()
            TweenService
                :Create(
                    disable,
                    TweenInfo.new(0.5),
                    { BackgroundTransparency = 1 }
                )
                :Play()
            wait(0.5)
            disable:Destroy()
            ui.CodeBox.Size = UDim2.new(1, 0, 0.5, 0)
            ui.CodeBox.Position = UDim2.new(0, 0, 0, 0)
            ui.CodeBox.ZIndex = 0
            maximized = false
        end)
    end
end

--- Checks if cursor is within resize range
--- @param p Vector2
function isInResizeRange(p)
    local relativeP = p - ui.Background.AbsolutePosition
    local range = 5
    if
        relativeP.X >= ui.TopBar.AbsoluteSize.X - range
        and relativeP.Y >= ui.Background.AbsoluteSize.Y - range
        and relativeP.X <= ui.TopBar.AbsoluteSize.X
        and relativeP.Y <= ui.Background.AbsoluteSize.Y
    then
        return true, 'B'
    elseif
        relativeP.X >= ui.TopBar.AbsoluteSize.X - range
        and relativeP.X <= ui.Background.AbsoluteSize.X
    then
        return true, 'X'
    elseif
        relativeP.Y >= ui.Background.AbsoluteSize.Y - range
        and relativeP.Y <= ui.Background.AbsoluteSize.Y
    then
        return true, 'Y'
    end
    return false
end

--- Checks if cursor is within dragging range
--- @param p Vector2
function isInDragRange(p)
    local relativeP = p - ui.Background.AbsolutePosition
    local topbarAS = ui.TopBar.AbsoluteSize
    return relativeP.X <= topbarAS.X - ui.CloseButton.AbsoluteSize.X * 3
            and relativeP.X >= 0
            and relativeP.Y <= topbarAS.Y
            and relativeP.Y >= 0
        or false
end

--- Called when mouse enters SimpleSpy
local customCursor = Create('ImageLabel', {
    Parent = ui.SimpleSpy3,
    Visible = false,
    Size = UDim2.fromOffset(200, 200),
    ZIndex = 1e9,
    BackgroundTransparency = 1,
    Image = '',
    Parent = ui.SimpleSpy3,
})
function mouseEntered()
    local con = connections['SIMPLESPY_CURSOR']
    if con then
        con:Disconnect()
        connections['SIMPLESPY_CURSOR'] = nil
    end
    connections['SIMPLESPY_CURSOR'] = RunService.RenderStepped:Connect(
        function()
            UserInputService.MouseIconEnabled = not mouseInGui
            customCursor.Visible = mouseInGui
            if mouseInGui and getgenv().SimpleSpyExecuted then
                local mouseLocation = UserInputService:GetMouseLocation()
                    - GuiInset
                customCursor.Position = UDim2.fromOffset(
                    mouseLocation.X - customCursor.AbsoluteSize.X / 2,
                    mouseLocation.Y - customCursor.AbsoluteSize.Y / 2
                )
                local inRange, type = isInResizeRange(mouseLocation)
                if inRange and not closed then
                    if not sideClosed then
                        customCursor.Image = type == 'B'
                                and 'rbxassetid://6065821980'
                            or type == 'X' and 'rbxassetid://6065821086'
                            or type == 'Y' and 'rbxassetid://6065821596'
                    elseif type == 'Y' or type == 'B' then
                        customCursor.Image = 'rbxassetid://6065821596'
                    end
                elseif customCursor.Image ~= 'rbxassetid://6065775281' then
                    customCursor.Image = 'rbxassetid://6065775281'
                end
            else
                connections['SIMPLESPY_CURSOR']:Disconnect()
            end
        end
    )
end

--- Called when mouse moves
function mouseMoved()
    local mousePos = UserInputService:GetMouseLocation() - GuiInset
    if
        not closed
        and mousePos.X >= ui.TopBar.AbsolutePosition.X
        and mousePos.X <= ui.TopBar.AbsolutePosition.X + ui.TopBar.AbsoluteSize.X
        and mousePos.Y >= ui.Background.AbsolutePosition.Y
        and mousePos.Y
            <= ui.Background.AbsolutePosition.Y + ui.Background.AbsoluteSize.Y
    then
        if not mouseInGui then
            mouseInGui = true
            mouseEntered()
        end
    else
        mouseInGui = false
    end
end

--- Adjusts the ui elements to the 'Maximized' size
function maximizeSize(speed)
    speed = speed or 0.05
    TweenService:Create(ui.LeftPanel, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            ui.LeftPanel.AbsoluteSize.X,
            ui.Background.AbsoluteSize.Y - ui.TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(ui.RightPanel, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            ui.Background.AbsoluteSize.X - ui.LeftPanel.AbsoluteSize.X,
            ui.Background.AbsoluteSize.Y - ui.TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(ui.TopBar, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            ui.Background.AbsoluteSize.X,
            ui.TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(ui.ScrollingFrame, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            ui.Background.AbsoluteSize.X - ui.LeftPanel.AbsoluteSize.X,
            110
        ),
        Position = UDim2.fromOffset(
            0,
            ui.Background.AbsoluteSize.Y - 119 - ui.TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(ui.CodeBox, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            ui.Background.AbsoluteSize.X - ui.LeftPanel.AbsoluteSize.X,
            ui.Background.AbsoluteSize.Y - 119 - ui.TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(ui.LogList, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            ui.LogList.AbsoluteSize.X,
            ui.Background.AbsoluteSize.Y - ui.TopBar.AbsoluteSize.Y - 18
        ),
    }):Play()
end

--- Adjusts the ui elements to close the side
function minimizeSize(speed)
    speed = speed or 0.05
    TweenService:Create(ui.LeftPanel, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            ui.LeftPanel.AbsoluteSize.X,
            ui.Background.AbsoluteSize.Y - ui.TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(ui.RightPanel, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            0,
            ui.Background.AbsoluteSize.Y - ui.TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(ui.TopBar, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            ui.LeftPanel.AbsoluteSize.X,
            ui.TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(ui.ScrollingFrame, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(0, 119),
        Position = UDim2.fromOffset(
            0,
            ui.Background.AbsoluteSize.Y - 119 - ui.TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(ui.CodeBox, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            0,
            ui.Background.AbsoluteSize.Y - 119 - ui.TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(ui.LogList, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            ui.LogList.AbsoluteSize.X,
            ui.Background.AbsoluteSize.Y - ui.TopBar.AbsoluteSize.Y - 18
        ),
    }):Play()
end

--- Ensures size is within screensize limitations
function validateSize()
    local x, y = ui.Background.AbsoluteSize.X, ui.Background.AbsoluteSize.Y
    local screenSize = SafeGetService('Workspace').CurrentCamera.ViewportSize
    if x + ui.Background.AbsolutePosition.X > screenSize.X then
        if screenSize.X - ui.Background.AbsolutePosition.X >= 450 then
            x = screenSize.X - ui.Background.AbsolutePosition.X
        else
            x = 450
        end
    elseif y + ui.Background.AbsolutePosition.Y > screenSize.Y then
        if screenSize.X - ui.Background.AbsolutePosition.Y >= 268 then
            y = screenSize.Y - ui.Background.AbsolutePosition.Y
        else
            y = 268
        end
    end
    ui.Background.Size = UDim2.fromOffset(x, y)
end

--- Called on user input while mouse in 'ui.Background' frame
--- @param input InputObject
function backgroundUserInput(input)
    local mousePos = UserInputService:GetMouseLocation() - GuiInset
    local inResizeRange, type = isInResizeRange(mousePos)
    if
        input.UserInputType == Enum.UserInputType.MouseButton1
        and inResizeRange
    then
        local lastPos = UserInputService:GetMouseLocation()
        local offset = ui.Background.AbsoluteSize - lastPos
        local currentPos = lastPos + offset
        if not connections['SIMPLESPY_RESIZE'] then
            connections['SIMPLESPY_RESIZE'] = RunService.RenderStepped:Connect(
                function()
                    local newPos = UserInputService:GetMouseLocation()
                    if newPos ~= lastPos then
                        local currentX = (newPos + offset).X
                        local currentY = (newPos + offset).Y
                        if currentX < 450 then
                            currentX = 450
                        end
                        if currentY < 268 then
                            currentY = 268
                        end
                        currentPos = Vector2.new(currentX, currentY)
                        ui.Background.Size = UDim2.fromOffset(
                            (
                                not sideClosed
                                and not closed
                                and (type == 'X' or type == 'B')
                            )
                                    and currentPos.X
                                or ui.Background.AbsoluteSize.X,
                            (--[[(not sideClosed or currentPos.X <= ui.LeftPanel.AbsolutePosition.X + ui.LeftPanel.AbsoluteSize.X) and]]not closed and (type == 'Y' or type == 'B'))
                                    and currentPos.Y
                                or ui.Background.AbsoluteSize.Y
                        )
                        validateSize()
                        if sideClosed then
                            minimizeSize()
                        else
                            maximizeSize()
                        end
                        lastPos = newPos
                    end
                end
            )
        end
        table.insert(
            connections,
            UserInputService.InputEnded:Connect(function(inputE)
                if input == inputE then
                    if connections['SIMPLESPY_RESIZE'] then
                        connections['SIMPLESPY_RESIZE']:Disconnect()
                        connections['SIMPLESPY_RESIZE'] = nil
                    end
                end
            end)
        )
    elseif isInDragRange(mousePos) then
        onBarInput(input)
    end
end

--- Gets the player an instance is descended from
function getPlayerFromInstance(instance)
    for _, v in next, Players:GetPlayers() do
        if
            v.Character
            and (
                instance:IsDescendantOf(v.Character)
                or instance == v.Character
            )
        then
            return v
        end
    end
end

--- Runs on MouseButton1Click of an event frame
function eventSelect(frame)
    if selected and selected.Log then
        if selected.Button then
            spawn(function()
                TweenService
                    :Create(
                        selected.Button,
                        TweenInfo.new(0.5),
                        { BackgroundColor3 = Color3.fromRGB(0, 0, 0) }
                    )
                    :Play()
            end)
        end
        selected = nil
    end
    for _, v in next, logs do
        if frame == v.Log then
            selected = v
        end
    end
    if selected and selected.Log then
        spawn(function()
            TweenService:Create(
                frame.Button,
                TweenInfo.new(0.5),
                { BackgroundColor3 = Color3.fromRGB(92, 126, 229) }
            ):Play()
        end)
        codebox:setRaw(selected.GenScript)
    end
    if sideClosed then
        toggleSideTray()
    end
end

--- Updates the canvas size to fit the current amount of function buttons
function updateFunctionCanvas()
    ui.ScrollingFrame.CanvasSize = UDim2.fromOffset(
        ui.UIGridLayout.AbsoluteContentSize.X,
        ui.UIGridLayout.AbsoluteContentSize.Y
    )
end

--- Updates the canvas size to fit the amount of current remotes
function updateRemoteCanvas()
    ui.LogList.CanvasSize = UDim2.fromOffset(
        ui.UIListLayout.AbsoluteContentSize.X,
        ui.UIListLayout.AbsoluteContentSize.Y
    )
end

--- Allows for toggling of the ui.ToolTip and easy setting of le description
--- @param enable boolean
--- @param text string
function makeToolTip(enable, text)
    if enable and text then
        if ui.ToolTip.Visible then
            ui.ToolTip.Visible = false
            local tooltip = connections['ToolTip']
            if tooltip then
                tooltip:Disconnect()
            end
        end
        local first = true
        connections['ToolTip'] = RunService.RenderStepped:Connect(function()
            local MousePos = UserInputService:GetMouseLocation()
            local topLeft = MousePos + Vector2.new(20, -15)
            local bottomRight = topLeft + ui.ToolTip.AbsoluteSize
            local ViewportSize =
                SafeGetService('Workspace').CurrentCamera.ViewportSize
            local ViewportSizeX = ViewportSize.X
            local ViewportSizeY = ViewportSize.Y

            if topLeft.X < 0 then
                topLeft = Vector2.new(0, topLeft.Y)
            elseif bottomRight.X > ViewportSizeX then
                topLeft = Vector2.new(
                    ViewportSizeX - ui.ToolTip.AbsoluteSize.X,
                    topLeft.Y
                )
            end
            if topLeft.Y < 0 then
                topLeft = Vector2.new(topLeft.X, 0)
            elseif bottomRight.Y > ViewportSizeY - 35 then
                topLeft = Vector2.new(
                    topLeft.X,
                    ViewportSizeY - ui.ToolTip.AbsoluteSize.Y - 35
                )
            end
            if topLeft.X <= MousePos.X and topLeft.Y <= MousePos.Y then
                topLeft = Vector2.new(
                    MousePos.X - ui.ToolTip.AbsoluteSize.X - 2,
                    MousePos.Y - ui.ToolTip.AbsoluteSize.Y - 2
                )
            end
            if first then
                ui.ToolTip.Position = UDim2.fromOffset(topLeft.X, topLeft.Y)
                first = false
            else
                ui.ToolTip:TweenPosition(
                    UDim2.fromOffset(topLeft.X, topLeft.Y),
                    'Out',
                    'Linear',
                    0.1
                )
            end
        end)
        ui.TextLabel.Text = text
        ui.TextLabel.TextScaled = true
        ui.ToolTip.Visible = true
        return
    else
        if ui.ToolTip.Visible then
            ui.ToolTip.Visible = false
            local tooltip = connections['ToolTip']
            if tooltip then
                tooltip:Disconnect()
            end
        end
    end
end

--- Creates new function button (below ui.CodeBox)
--- @param name string
---@param description function
---@param onClick function
function newButton(name, description, onClick)
    local FunctionTemplate = Create('Frame', {
        Name = 'FunctionTemplate',
        Parent = ui.ScrollingFrame,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 117, 0, 23),
    })
    local ColorBar = Create('Frame', {
        Name = 'ColorBar',
        Parent = FunctionTemplate,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 7, 0, 10),
        Size = UDim2.new(0, 7, 0, 18),
        ZIndex = 3,
    })
    local Text = Create('TextLabel', {
        Text = name,
        Name = 'Text',
        Parent = FunctionTemplate,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 19, 0, 10),
        Size = UDim2.new(0, 69, 0, 18),
        ZIndex = 2,
        Font = Enum.Font.SourceSans,
        TextColor3 = Color3.new(1, 1, 1),
        --TextSize = 14,
        TextScaled = true,
        TextStrokeColor3 = Color3.new(0.145098, 0.141176, 0.14902),
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    local Button = Create('TextButton', {
        Name = 'Button',
        Parent = FunctionTemplate,
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.69999998807907,
        BorderColor3 = Color3.new(1, 1, 1),
        Position = UDim2.new(0, 7, 0, 10),
        Size = UDim2.new(0, 80, 0, 18),
        AutoButtonColor = false,
        Font = Enum.Font.SourceSans,
        Text = '',
        TextColor3 = Color3.new(0, 0, 0),
        --TextSize = 14,
        TextScaled = true,
    })

    Button.MouseEnter:Connect(function()
        makeToolTip(true, description())
    end)
    Button.MouseLeave:Connect(function()
        makeToolTip(false)
    end)
    FunctionTemplate.AncestryChanged:Connect(function()
        makeToolTip(false)
    end)
    Button.MouseButton1Click:Connect(function(...)
        logthread(running())
        onClick(FunctionTemplate, ...)
    end)
    updateFunctionCanvas()
end

local COLOR_RE_FIRE_SERVER = Color3.fromRGB(255, 242, 0)
local COLOR_RF_INVOKE_SERVER = Color3.fromRGB(99, 86, 245)
local COLOR_BE_FIRE = Color3.fromRGB(255, 170, 0)
local COLOR_BF_INVOKE = Color3.fromRGB(0, 200, 200)

local function colorForRemote(data)
    local r = data.remote
    local m = string.lower(data.method or "")
    local isReliableEvent = r:IsA("RemoteEvent")
    local isUnreliableEvent = r:IsA("UnreliableRemoteEvent")

    if (isReliableEvent or isUnreliableEvent) and m == "fireserver" then
        return COLOR_RE_FIRE_SERVER
    end
    if r:IsA("RemoteFunction") and m == "invokeserver" then
        return COLOR_RF_INVOKE_SERVER
    end
    if (isReliableEvent or isUnreliableEvent) and m == "onclientevent" then
        return Color3.fromRGB(0, 200, 255)
    end
    if m == "onclientinvoke" then
        return Color3.fromRGB(110, 230, 160)
    end
    if r:IsA("BindableEvent") and m == "fire" then
        return COLOR_BE_FIRE
    end
    if r:IsA("BindableFunction") and m == "invoke" then
        return COLOR_BF_INVOKE
    end
    return Color3.fromRGB(180, 180, 180)
end

--- Adds new Remote to logs
--- @param name string The name of the remote being logged
--- @param type string The type of the remote being logged (either 'function' or 'event')
--- @param args any
--- @param remote any
--- @param function_info string
--- @param blocked any
logsById = logsById or {}

local function logKey(data)
    local rid = data.id or OldDebugId(data.remote)
    local m = tostring(data.method or ''):lower()
    return rid .. '|' .. m
end

local formatReturnValues

local function cloneReturnValues(container)
    if type(container) ~= 'table' then
        return nil
    end
    local data = container.data
    if type(data) ~= 'table' then
        return nil
    end
    local ok, copied = pcall(deepclone, data)
    if ok then
        return copied
    end
    if clone then
        local okClone, fallback = pcall(clone, data)
        if okClone then
            return fallback
        end
    end
    local fallback = {}
    for k, v in pairs(data) do
        fallback[k] = v
    end
    return fallback
end

local function selectCall(log, idx)
    local c = log.calls[idx]
    if not c then
        return
    end
    log.selectedIdx = idx
    log.args = deepclone(c.args or {})
    log.method = (c.method or log.method or ""):lower()
    selected = log

    local argsLen = (type(log.args) == "table" and #log.args) or 0
    local g = argsLen > 0 and (v2v({ args = log.args }) .. "\n") or ""
    local r = v2s(log.Remote)
    local rem = log.Remote
    local m = log.method

    if rem:IsA("RemoteEvent") or rem:IsA("UnreliableRemoteEvent") then
        if m == "onclientevent" then
            if firesignal then
                g ..= argsLen > 0
                    and ("firesignal(%s.OnClientEvent, unpack(args))"):format(r)
                    or ("firesignal(%s.OnClientEvent)"):format(r)
            else
                g ..= argsLen > 0
                    and ("-- firesignal missing\n%s:FireServer(unpack(args))"):format(r)
                    or ("-- firesignal missing\n%s:FireServer()"):format(r)
            end
        else
            g ..= argsLen > 0
                and ("%s:FireServer(unpack(args))"):format(r)
                or ("%s:FireServer()"):format(r)
        end
    elseif rem:IsA("RemoteFunction") then
        if m == "onclientinvoke" then
            g ..= ("%s.OnClientInvoke = function(...)\n\treturn nil\nend"):format(r)
        else
            g ..= argsLen > 0
                and ("%s:InvokeServer(unpack(args))"):format(r)
                or ("%s:InvokeServer()"):format(r)
        end
    elseif rem:IsA("BindableEvent") then
        g ..= argsLen > 0
            and ("%s:Fire(unpack(args))"):format(r)
            or ("%s:Fire()"):format(r)
    elseif rem:IsA("BindableFunction") then
        g ..= argsLen > 0
            and ("%s:Invoke(unpack(args))"):format(r)
            or ("%s:Invoke()"):format(r)
    end

    local retPrev = formatReturnValues and formatReturnValues(c.returns)
    if retPrev and #retPrev > 0 then
        g ..= "\n\n" .. retPrev
    end

    if log.returnvalue and c.returns then
        log.returnvalue.data = c.returns
    end

    log.GenScript = g
    codebox:setRaw(g)
end

function newRemote(type, data)
    if layoutOrderNum < 1 then
        layoutOrderNum = 999999999
    end
    local remote = data.remote
    local rid = data.id or OldDebugId(remote)
    local key = logKey(data)
    local callReturns = cloneReturnValues(data.returnvalue)

    local existing = logsById[key]
    if existing then
        local uiAlive = existing.Log
            and existing.Log.Parent
            and existing.CallsList
            and existing.CallsList.Parent
        if not uiAlive then
            logsById[key] = nil
            existing = nil
        end
    end

    local function rowColor()
    local m = tostring(data.method or ""):lower()
    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
        return (m == "onclientevent") and Color3.fromRGB(0, 200, 255)
            or Color3.fromRGB(255, 208, 0)
    elseif remote:IsA("RemoteFunction") then
        return (m == "onclientinvoke") and Color3.fromRGB(110, 230, 160)
            or Color3.fromRGB(99, 86, 245)
    elseif remote:IsA("BindableEvent") then
        return Color3.fromRGB(255, 170, 0)
    elseif remote:IsA("BindableFunction") then
        return Color3.fromRGB(0, 200, 200)
    end
    return Color3.fromRGB(200, 200, 200)
end

    local existing = logsById[key]
    if existing then
        existing.Count += 1
        existing.CountLabel.Text = ('x%d'):format(existing.Count)
        existing.CountLabel.Visible = true

        if data.callingscript and not existing.Source then
            existing.Source = data.callingscript
        end
        if data.infofunc and (not existing.Function or existing.Function == '') then
            existing.Function = data.infofunc
        end

        local idx = #existing.calls + 1
        table.insert(existing.calls, {
            time = os.date('%H:%M:%S'),
            args = deepclone(data.args),
            method = tostring(data.method or ''):lower(),
            returns = callReturns,
        })
        if data.returnvalue then
            existing.returnvalue = data.returnvalue
        end

        local item = Create('TextButton', {
            Parent = existing.CallsList,
            BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.Code,
            TextSize = 12,
            Text = ('[%d] %s'):format(idx, existing.calls[idx].time),
            AutoButtonColor = true,
            TextColor3 = Color3.fromRGB(235, 235, 235),
        })
        item.MouseButton1Click:Connect(function()
            selectCall(existing, idx)
        end)
        updateRemoteCanvas()
        return
    end

    local RemoteTemplate = Create('Frame', {
        LayoutOrder = layoutOrderNum,
        Name = 'RemoteTemplate',
        Parent = ui.LogList,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.Y,
    })

    local Row = Create('Frame', {
        Name = 'Row',
        Parent = RemoteTemplate,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
    })

    local ColorBar = Create('Frame', {
        Name = 'ColorBar',
        Parent = Row,
        BackgroundColor3 = rowColor(),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 2),
        Size = UDim2.new(0, 7, 0, 18),
        ZIndex = 2,
    })

    local Text = Create('TextLabel', {
        Name = 'Text',
        Parent = Row,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 2),
        Size = UDim2.new(1, -76, 0, 18),
        Font = Enum.Font.SourceSans,
        Text = remote.Name,
        TextColor3 = Color3.fromRGB(245, 245, 245),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 2,
    })

    local CountLabel = Create('TextLabel', {
        Name = 'Count',
        Parent = Row,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 36, 0, 18),
        Position = UDim2.new(1, -58, 0, 2),
        Font = Enum.Font.SourceSansBold,
        Text = 'x1',
        TextSize = 14,
        TextColor3 = Color3.fromRGB(180, 200, 255),
        Visible = false,
        ZIndex = 4,
    })

    local Expand = Create('TextButton', {
        Name = 'Expand',
        Parent = Row,
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -4, 0, 2),
        Size = UDim2.new(0, 18, 0, 18),
        Font = Enum.Font.SourceSansBold,
        Text = '+',
        TextSize = 14,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        AutoButtonColor = true,
        ZIndex = 5,
    })

    local Button = Create('TextButton', {
        Name = 'Button',
        Parent = Row,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, -24, 0, 22),
        Text = '',
        ZIndex = 1,
    })

    local Details = Create('Frame', {
        Name = 'Details',
        Parent = RemoteTemplate,
        BackgroundTransparency = 1,
        Visible = false,
        Size = UDim2.new(1, -12, 0, 0),
        Position = UDim2.new(0, 12, 0, 24),
        AutomaticSize = Enum.AutomaticSize.Y,
    })

    local CallsList = Create('Frame', {
        Parent = Details,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    local CallsLayout = Instance.new('UIListLayout')
    CallsLayout.Parent = CallsList
    CallsLayout.FillDirection = Enum.FillDirection.Vertical
    CallsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CallsLayout.Padding = UDim.new(0, 2)

    local log = {
        Name = remote.Name,
        Function = data.infofunc or '',
        Remote = remote,
        DebugId = rid,
        metamethod = data.metamethod,
        args = nil,
        Log = RemoteTemplate,
        Button = Button,
        Blocked = data.blocked,
        Source = data.callingscript,
        returnvalue = data.returnvalue,
        GenScript = '',
        CallsList = CallsList,
        CountLabel = CountLabel,
        Count = 0,
        calls = {},
        method = data.method,
    }

    logs[#logs + 1] = log
    logsById[key] = log

    local idx1 = 1
    table.insert(log.calls, {
        time = os.date('%H:%M:%S'),
        args = deepclone(data.args),
        method = tostring(data.method or ''):lower(),
        returns = callReturns,
    })
    log.Count = 1

    local firstItem = Create('TextButton', {
        Parent = CallsList,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Code,
        TextSize = 12,
        Text = ('[1] %s'):format(log.calls[1].time),
        AutoButtonColor = true,
        TextColor3 = Color3.fromRGB(235, 235, 235),
    })
    firstItem.MouseButton1Click:Connect(function()
        selectCall(log, 1)
    end)

    local expanded = false
    local function toggleDetails()
        expanded = not expanded
        Details.Visible = expanded
        Expand.Text = expanded and '–' or '+'
        updateRemoteCanvas()
    end
    Expand.MouseButton1Click:Connect(toggleDetails)

    Button.MouseButton1Click:Connect(function()
        selectCall(log, #log.calls)
    end)

    layoutOrderNum -= 1
    table.insert(remoteLogs, 1, { Button, RemoteTemplate })
    clean()
    updateRemoteCanvas()
end

--- Generates a script from the provided arguments (first has to be remote path)
function genScript(remote, args, method)
    method = tostring(method or ""):lower()
    prevTables = {}
    local gen = ""
    xpcall(function()
        gen = v2v({ args = args }) .. "\n"
    end, function(err)
        gen = (gen or "") .. ("-- TableToString failure: %s\n"):format(tostring(err))
    end)
    if not remote:IsDescendantOf(game) and not getnilrequired then
        gen = "function getNil(name,class) for _,v in next, getnilinstances() do if v.ClassName==class and v.Name==name then return v end end end\n\n" .. gen
        getnilrequired = true
    end
    local r = v2s(remote)
    if #args > 0 then
        if remote:IsA("RemoteEvent") then
            if method == "onclientevent" then
                if firesignal then
                    gen ..= ("firesignal(%s.OnClientEvent, unpack(args))"):format(r)
                else
                    gen ..= ("-- firesignal not available for %s.OnClientEvent"):format(r)
                end
            else
                gen ..= ("%s:FireServer(unpack(args))"):format(r)
            end
        elseif remote:IsA("RemoteFunction") then
            if method == "onclientinvoke" then
                gen ..= ("%s.OnClientInvoke = function(...)\n\treturn nil\nend"):format(r)
            else
                gen ..= ("%s:InvokeServer(unpack(args))"):format(r)
            end
        elseif remote:IsA("BindableEvent") then
            gen ..= ("%s:Fire(unpack(args))"):format(r)
        elseif remote:IsA("BindableFunction") then
            gen ..= ("%s:Invoke(unpack(args))"):format(r)
        end
    else
        if remote:IsA("RemoteEvent") then
            if method == "onclientevent" then
                if firesignal then
                    gen ..= ("firesignal(%s.OnClientEvent)"):format(r)
                else
                    gen ..= ("-- firesignal not available for %s.OnClientEvent"):format(r)
                end
            else
                gen ..= ("%s:FireServer()"):format(r)
            end
        elseif remote:IsA("RemoteFunction") then
            if method == "onclientinvoke" then
                gen ..= ("%s.OnClientInvoke = function(...)\n\treturn nil\nend"):format(r)
            else
                gen ..= ("%s:InvokeServer()"):format(r)
            end
        elseif remote:IsA("BindableEvent") then
            gen ..= ("%s:Fire()"):format(r)
        elseif remote:IsA("BindableFunction") then
            gen ..= ("%s:Invoke()"):format(r)
        end
    end
    prevTables = {}
    return gen
end

local function clampReturnPreview(str)
    local limit = returnPreviewLimit
    if type(str) ~= 'string' then
        return ''
    end
    if type(limit) == 'number' and limit > 0 and #str > limit then
        if limit <= 3 then
            return str:sub(1, limit)
        end
        return str:sub(1, limit - 3) .. '...'
    end
    return str
end

local function describeReturnValue(value)
    local vtype = typeof(value)
    if vtype == 'string' then
        return ('string %s'):format(string.format('%q', value))
    elseif vtype == 'number' or vtype == 'boolean' then
        return vtype .. ' ' .. tostring(value)
    elseif vtype == 'nil' then
        return 'nil'
    elseif vtype == 'Instance' then
        local ok, path = pcall(i2p, value)
        if ok and type(path) == 'string' then
            return ('Instance<%s> %s'):format(value.ClassName, path)
        end
        local success, fullName = pcall(function()
            return value:GetFullName()
        end)
        return ('Instance<%s> %s'):format(
            value.ClassName,
            (success and fullName) or 'Instance'
        )
    elseif is_buffer and is_buffer(value) then
        return clampReturnPreview(buffer_literal(value))
    elseif vtype == 'table' then
        local ok, dumped = pcall(v2s, value)
        if ok and type(dumped) == 'string' then
            return 'table ' .. clampReturnPreview(dumped)
        end
        return 'table --[[serialization failed]]'
    end
    return vtype .. ' ' .. rawtostring(value)
end

local function packedLength(values)
    if type(values) ~= 'table' then
        return 0
    end
    if type(values.n) == 'number' and values.n >= 0 then
        return values.n
    end
    return table_maxn(values)
end

formatReturnValues = function(values)
    if type(values) ~= 'table' then
        return nil
    end
    local len = packedLength(values)
    if len <= 0 then
        return nil
    end
    local lines = { '-- Return Values (' .. len .. ')' }
    for i = 1, len do
        local ok, desc = pcall(describeReturnValue, values[i])
        if ok then
            lines[#lines + 1] = ('-- [%d] %s'):format(i, desc)
        else
            lines[#lines + 1] = ('-- [%d] <error: %s>'):format(
                i,
                tostring(desc)
            )
        end
    end
    return table.concat(lines, '\n')
end

local captureRemoteCall

local logConnectionFunctions = setmetatable({}, { __mode = 'k' })

local function getConnectionFunction(conn)
    local func = conn and conn.Function
    return (typeof(func) == 'function') and func or nil
end

local function getConnectionScript(conn, fallbackFunc)
    local origin = safeGetScriptFromThread(conn and conn.Thread)
    if origin then
        return origin
    end

    local func = getConnectionFunction(conn) or fallbackFunc
    if func then
        local ok, env = pcall(getfenv, func)
        if ok then
            local script = rawget(env, 'script')
            if typeof(script) == 'Instance' then
                return script
            end
        end
    end
end

local function logClientEvent(re: RemoteEvent)
    if internalRemotes[re] then
        return
    end
    if loggedClientEvent[re] then
        return
    end
    loggedClientEvent[re] = true
    local function logConnection(...)
        local args = { ... }
        local argsLength = select('#', ...)
        if not captureRemoteCall then
            return
        end

        local loggedAny = false
        local connections
        if caps.getConnections then
            local ok, current = pcall(getconnections, re.OnClientEvent)
            if ok and type(current) == 'table' then
                connections = current
            end
        end

        if connections then
            for _, conn in ipairs(connections) do
                if conn.ForeignState then
                    continue
                end

                local func = getConnectionFunction(conn)
                if func and logConnectionFunctions[func] then
                    continue
                end

                local origin = getConnectionScript(conn, func)
                loggedAny = true

                captureRemoteCall({
                    remote = cloneref(re),
                    method = 'OnClientEvent',
                    args = args,
                    argsLength = argsLength,
                    metaMethod = 'signal',
                    transferType = 'Receive',
                    callingscript = origin,
                    infofunc = func,
                    infoline = safeDebugInfo(func, 'l'),
                    infosource = safeDebugInfo(func, 's'),
                    isexecutor = isexecutorclosure and func
                        and isexecutorclosure(func),
                })
            end
        end

        if not loggedAny then
            captureRemoteCall({
                remote = cloneref(re),
                method = 'OnClientEvent',
                args = args,
                argsLength = argsLength,
                metaMethod = 'signal',
                transferType = 'Receive',
            })
        end
    end

    logConnectionFunctions[logConnection] = true
    re.OnClientEvent:Connect(logConnection)
end

local function wrapOnClientInvokeCallback(rf, callback)
    if internalRemotes[rf] then
        return callback
    end
    if type(callback) ~= 'function' then
        return callback
    end
    if wrappedInvokeCallbacks[callback] then
        return callback
    end
    local remoteRef = cloneref(rf)
    local invoking = false
    return function(...)
        if invoking then
            return callback(...)
        end
        invoking = true
        local args = { ... }
        local argsLength = select('#', ...)
        if not captureRemoteCall then
            return callback(...)
        end
        local origin = safeGetScriptFromThread(coroutine.running and coroutine.running())
            or getConnectionScript(nil, callback)
        local callSource = safeDebugInfo(callback, 's')
        local callLine = safeDebugInfo(callback, 'l')
        local isExec = isexecutorclosure and callback and isexecutorclosure(callback)
        local ok, results = pcall(function()
            return table_pack(captureRemoteCall({
                remote = remoteRef,
                method = 'OnClientInvoke',
                args = args,
                argsLength = argsLength,
                metaMethod = 'callback',
                transferType = 'Receive',
                callingscript = origin,
                infofunc = callback,
                infoline = callLine,
                infosource = callSource,
                isexecutor = isExec,
                callOriginal = function(...)
                    return callback(...)
                end,
            }))
        end)
        invoking = false
        if not ok then
            error(results)
        end
        return unpack(results, 1, results.n or table_maxn(results))
    end
end

local function setWrappedOnClientInvoke(rf, callback)
    if type(callback) ~= 'function' then
        return callback
    end
    if wrappedInvokeCallbacks[callback] then
        return callback
    end
    wrappedInvokeCallbacks[callback] = true
    _origClientInvoke[rf] = callback
    local wrapped = wrapOnClientInvokeCallback(rf, callback)
    return wrapped
end

local function wrapClientInvoke(rf)
    if internalRemotes[rf] then
        return
    end
    if wrappedClientInvoke[rf] then
        return
    end
    wrappedClientInvoke[rf] = true

    local function getExistingInvokeCallback()
        if getcallbackmember then
            local ok, cb = pcall(getcallbackmember, rf, 'OnClientInvoke')
            if ok and type(cb) == 'function' then
                return cb
            end
        end
        local ok, cb = pcall(function()
            return rf.OnClientInvoke
        end)
        if ok and type(cb) == 'function' then
            return cb
        end
    end

    local current = getExistingInvokeCallback()
    if
        type(current) == 'function'
        and _origClientInvoke[rf] ~= current
        and not wrappedInvokeCallbacks[current]
    then
        rf.OnClientInvoke = setWrappedOnClientInvoke(rf, current)
    end
end

--- value-to-string: value, string (out), level (indentation), parent table, var name, is from tovar
local CustomGeneration = {
    Vector3 = (function()
        local temp = {}
        for i, v in Vector3 do
            if type(v) == 'vector' then
                temp[v] = `Vector3.{i}`
            end
        end
        return temp
    end)(),
    Vector2 = (function()
        local temp = {}
        for i, v in Vector2 do
            if type(v) == 'userdata' then
                temp[v] = `Vector2.{i}`
            end
        end
        return temp
    end)(),
    CFrame = {
        [CFrame.identity] = 'CFrame.identity',
    },
}

local number_table = {
    ['inf'] = 'math.huge',
    ['-inf'] = '-math.huge',
    ['nan'] = '0/0',
}

local ufunctions
ufunctions = {
    TweenInfo = function(u)
        return `TweenInfo.new({u.Time}, {u.EasingStyle}, {u.EasingDirection}, {u.RepeatCount}, {u.Reverses}, {u.DelayTime})`
    end,
    Ray = function(u)
        local Vector3tostring = ufunctions['Vector3']

        return `Ray.new({Vector3tostring(u.Origin)}, {Vector3tostring(
            u.Direction
        )})`
    end,
    BrickColor = function(u)
        return `BrickColor.new({u.Number})`
    end,
    NumberRange = function(u)
        return `NumberRange.new({u.Min}, {u.Max})`
    end,
    Region3 = function(u)
        local center = u.CFrame.Position
        local centersize = u.Size / 2
        local Vector3tostring = ufunctions['Vector3']

        return `Region3.new({Vector3tostring(center - centersize)}, {Vector3tostring(
            center + centersize
        )})`
    end,
    Faces = function(u)
        local faces = {}
        if u.Top then
            table.insert(faces, 'Top')
        end
        if u.Bottom then
            table.insert(faces, 'Enum.NormalId.Bottom')
        end
        if u.Left then
            table.insert(faces, 'Enum.NormalId.Left')
        end
        if u.Right then
            table.insert(faces, 'Enum.NormalId.Right')
        end
        if u.Back then
            table.insert(faces, 'Enum.NormalId.Back')
        end
        if u.Front then
            table.insert(faces, 'Enum.NormalId.Front')
        end
        return `Faces.new({table.concat(faces, ', ')})`
    end,
    EnumItem = function(u)
        return tostring(u)
    end,
    Enums = function(u)
        return 'Enum'
    end,
    Enum = function(u)
        return `Enum.{u}`
    end,
    Vector3 = function(u)
        return CustomGeneration.Vector3[u] or `Vector3.new({u})`
    end,
    Vector2 = function(u)
        return CustomGeneration.Vector2[u] or `Vector2.new({u})`
    end,
    CFrame = function(u)
        return CustomGeneration.CFrame[u]
            or `CFrame.new({table.concat({ u:GetComponents() }, ', ')})`
    end,
    PathWaypoint = function(u)
        return `PathWaypoint.new({ufunctions['Vector3'](u.Position)}, {u.Action}, "{u.Label}")`
    end,
    UDim = function(u)
        return `UDim.new({u})`
    end,
    UDim2 = function(u)
        return `UDim2.new({u})`
    end,
    Rect = function(u)
        local Vector2tostring = ufunctions['Vector2']
        return `Rect.new({Vector2tostring(u.Min)}, {Vector2tostring(u.Max)})`
    end,
    Color3 = function(u)
        return `Color3.new({u.R}, {u.G}, {u.B})`
    end,
    buffer = function(u, l)
        return buffer_literal(u, l)
    end,
    RBXScriptSignal = function(u) -- The server doesnt recive this
        return "RBXScriptSignal --[[RBXScriptSignal's are not supported]]"
    end,
    RBXScriptConnection = function(u) -- The server doesnt recive this
        return "RBXScriptConnection --[[RBXScriptConnection's are not supported]]"
    end,
}

local typeofv2sfunctions = {
    number = function(v)
        local number = tostring(v)
        return number_table[number] or number
    end,
    boolean = function(v)
        return tostring(v)
    end,
    string = function(v, l)
        return formatstr(v, l)
    end,
    ['function'] = function(v) -- The server doesnt recive this
        return f2s(v)
    end,
    table = function(v, l, p, n, vtv, i, pt, path, tables, tI)
        return t2s(v, l, p, n, vtv, i, pt, path, tables, tI)
    end,
    Instance = function(v)
        local DebugId = OldDebugId(v)
        return i2p(v, generation[DebugId])
    end,
    userdata = function(v) -- The server doesnt recive this
        if configs.advancedinfo then
            if caps.rawMetatable and getrawmetatable(v) then
                return 'newproxy(true)'
            end
            return 'newproxy(false)'
        end
        return 'newproxy(true)'
    end,
}

local typev2sfunctions = {
    userdata = function(v, vtypeof, l)
        if is_buffer(v) then
            return buffer_literal(v, l)
        end
        if ufunctions[vtypeof] then
            return ufunctions[vtypeof](v, l)
        end
        return `{vtypeof}({rawtostring(v)}) --[[Generation Failure]]`
    end,
    vector = ufunctions['Vector3'],
}

function v2s(v, l, p, n, vtv, i, pt, path, tables, tI)
    if is_buffer(v) then
        return buffer_literal(v, l)
    end
    local vtypeof = typeof(v)
    local vtypeoffunc = typeofv2sfunctions[vtypeof]
    local vtypefunc = typev2sfunctions[type(v)]
    local vtype = type(v)
    if not tI then
        tI = { 0 }
    else
        tI[1] += 1
    end

    if vtypeoffunc then
        return vtypeoffunc(v, l, p, n, vtv, i, pt, path, tables, tI)
    elseif vtypefunc then
        return vtypefunc(v, vtypeof, l)
    end
    return `{vtypeof}({rawtostring(v)}) --[[Generation Failure]]`
end

--- value-to-variable
--- @param t any
function v2v(t)
    topstr = ''
    bottomstr = ''
    getnilrequired = false
    local ret = ''
    local count = 1
    for i, v in next, t do
        if type(i) == 'string' and i:match('^[%a_]+[%w_]*$') then
            ret = ret
                .. 'local '
                .. i
                .. ' = '
                .. v2s(v, nil, nil, i, true)
                .. '\n'
        elseif rawtostring(i):match('^[%a_]+[%w_]*$') then
            ret = ret
                .. 'local '
                .. lower(rawtostring(i))
                .. '_'
                .. rawtostring(count)
                .. ' = '
                .. v2s(
                    v,
                    nil,
                    nil,
                    lower(rawtostring(i)) .. '_' .. rawtostring(count),
                    true
                )
                .. '\n'
        else
            ret = ret
                .. 'local '
                .. type(v)
                .. '_'
                .. rawtostring(count)
                .. ' = '
                .. v2s(v, nil, nil, type(v) .. '_' .. rawtostring(count), true)
                .. '\n'
        end
        count = count + 1
    end
    if getnilrequired then
        topstr = 'function getNil(name,class) for _,v in next, getnilinstances() do if v.ClassName==class and v.Name==name then return v;end end end\n'
            .. topstr
    end
    if #topstr > 0 then
        ret = topstr .. '\n' .. ret
    end
    if #bottomstr > 0 then
        ret = ret .. bottomstr
    end
    return ret
end

function tabletostring(tbl: table, format: boolean) end

--- table-to-string
--- @param t table
--- @param l number
--- @param p table
--- @param n string
--- @param vtv boolean
--- @param i any
--- @param pt table
--- @param path string
--- @param tables table
--- @param tI table
function t2s(t, l, p, n, vtv, i, pt, path, tables, tI)
    local globalIndex = table.find(getgenv(), t) -- checks if table is a global
    if type(globalIndex) == 'string' then
        return globalIndex
    end
    if not tI then
        tI = { 0 }
    end
    if not path then -- sets path to empty string (so it doesn't have to manually provided every time)
        path = ''
    end
    if not l then -- sets the level to 0 (for indentation) and tables for logging tables it already serialized
        l = 0
        tables = {}
    end
    if not p then -- p is the previous table but doesn't really matter if it's the first
        p = t
    end
    for _, v in next, tables do -- checks if the current table has been serialized before
        if n and rawequal(v, t) then
            bottomstr = bottomstr
                .. '\n'
                .. rawtostring(n)
                .. rawtostring(path)
                .. ' = '
                .. rawtostring(n)
                .. rawtostring(({ v2p(v, p) })[2])
            return '{} --[[DUPLICATE]]'
        end
    end
    table.insert(tables, t) -- logs table to past tables
    local s = '{' -- start of serialization
    local size = 0
    l += indent -- set indentation level
    for k, v in next, t do -- iterates over table
        size = size + 1 -- changes size for max limit
        if size > (getgenv().SimpleSpyMaxTableSize or 1000) then
            s = s
                .. '\n'
                .. string.rep(' ', l)
                .. "-- MAXIMUM TABLE SIZE REACHED, CHANGE 'getgenv().SimpleSpyMaxTableSize' TO ADJUST MAXIMUM SIZE "
            break
        end
        if rawequal(k, t) then -- checks if the table being iterated over is being used as an index within itself (yay, lua)
            bottomstr ..= `\n{n}{path}[{n}{path}] = {(rawequal(v, k) and `{n}{path}` or v2s(
                v,
                l,
                p,
                n,
                vtv,
                k,
                t,
                `{path}[{n}{path}]`,
                tables
            ))}`
            --bottomstr = bottomstr .. "\n" .. rawtostring(n) .. rawtostring(path) .. "[" .. rawtostring(n) .. rawtostring(path) .. "]" .. " = " .. (rawequal(v, k) and rawtostring(n) .. rawtostring(path) or v2s(v, l, p, n, vtv, k, t, path .. "[" .. rawtostring(n) .. rawtostring(path) .. "]", tables))
            size -= 1
            continue
        end
        local currentPath = '' -- initializes the path of 'v' within 't'
        if type(k) == 'string' and k:match('^[%a_]+[%w_]*$') then -- cleanly handles table path generation (for the first half)
            currentPath = '.' .. k
        else
            currentPath = '['
                .. v2s(k, l, p, n, vtv, k, t, path .. currentPath, tables, tI)
                .. ']'
        end
        if size % 100 == 0 then
            scheduleWait()
        end
        -- actually serializes the member of the table
        s = s
            .. '\n'
            .. string.rep(' ', l)
            .. '['
            .. v2s(k, l, p, n, vtv, k, t, path .. currentPath, tables, tI)
            .. '] = '
            .. v2s(v, l, p, n, vtv, k, t, path .. currentPath, tables, tI)
            .. ','
    end
    if #s > 1 then -- removes the last comma because it looks nicer (no way to tell if it's done 'till it's done so...)
        s = s:sub(1, #s - 1)
    end
    if size > 0 then -- cleanly indents the last curly bracket
        s = s .. '\n' .. string.rep(' ', l - indent)
    end
    return s .. '}'
end

--- function-to-string
function f2s(f)
    for k, x in next, getgenv() do
        local isgucci, gpath
        if rawequal(x, f) then
            isgucci, gpath = true, ''
        elseif type(x) == 'table' then
            isgucci, gpath = v2p(f, x)
        end
        if isgucci and type(k) ~= 'function' then
            if type(k) == 'string' and k:match('^[%a_]+[%w_]*$') then
                return k .. gpath
            else
                return 'getgenv()[' .. v2s(k) .. ']' .. gpath
            end
        end
    end

    if configs.funcEnabled then
        local funcname = info(f, 'n')

        if funcname and funcname:match('^[%a_]+[%w_]*$') then
            return `function {funcname}() end -- Function Called: {funcname}`
        end
    end
    return tostring(f)
end

--- instance-to-path
--- @param i userdata
local function hasDupName(parent, name)
    local n = 0
    for _, c in ipairs(parent:GetChildren()) do
        if c.Name == name then
            n += 1
            if n > 1 then
                return true
            end
        end
    end
    return false
end
local function childIndex(parent, child)
    if not parent or not child then
        return nil
    end
    local targetId = OldDebugId(child)
    local list = parent:GetChildren()
    for i = 1, #list do
        local item = list[i]
        if item == child or OldDebugId(item) == targetId then
            return i
        end
    end
    return nil
end
local function stepFromParentToChild(p, c)
    if not p or not c then
        return ''
    end
    local idx = childIndex(p, c)
    local duplicate = hasDupName(p, c.Name)
    local validName = c.Name ~= '' and c.Name:match('^[%a_][%w_]*$')
    local forceIndex = not validName
    if idx and (preferIndexPaths or duplicate or forceIndex) then
        return (':GetChildren()[' .. idx .. ']')
    end
    if validName then
        return duplicate and ':WaitForChild(' .. formatstr(c.Name) .. ')'
            or '.' .. c.Name
    end
    return ':WaitForChild(' .. formatstr(c.Name or '') .. ')'
end
function i2p(i, customgen)
    if customgen then
        return customgen
    end
    if i == nil then
        return 'nil'
    end

    local Players = game:GetService('Players')
    local function isIdent(s)
        return type(s) == 'string' and s:match('^[%a_][%w_]*$') ~= nil
    end
    local function q(s)
        return string.format('%q', s)
    end
    local function getplayer(instance)
        for _, plr in ipairs(Players:GetPlayers()) do
            local ch = plr.Character
            if ch and (instance == ch or instance:IsDescendantOf(ch)) then
                return plr
            end
        end
    end
    local function hasDupName(parent, name)
        local n = 0
        for _, c in ipairs(parent:GetChildren()) do
            if c.Name == name then
                n += 1
                if n > 1 then
                    return true
                end
            end
        end
        return false
    end
    local function childIndex(parent, child)
        if not parent or not child then
            return nil
        end
        local targetId = OldDebugId(child)
        local list = parent:GetChildren()
        for idx = 1, #list do
            local item = list[idx]
            if item == child or OldDebugId(item) == targetId then
                return idx
            end
        end
        return nil
    end
    local function stepFromParentToChild(p, c)
        if not p or not c then
            return ''
        end
        if p == Players and c.ClassName == 'Player' then
            return (':GetPlayerByUserId(%d)'):format(c.UserId)
        end

        local idx = childIndex(p, c)
        local duplicate = hasDupName(p, c.Name)
        local validName = c.Name ~= '' and isIdent(c.Name)
        local forceIndex = not validName

        if idx and (preferIndexPaths or duplicate or forceIndex) then
            return (':GetChildren()[%d]'):format(idx)
        end

        local mode = configs.pathMode or 1
        local nameLit = q(c.Name or '')

        if mode == 2 then
            return (':FindFirstChild(%s)'):format(nameLit)
        elseif mode == 3 then
            return (':WaitForChild(%s)'):format(nameLit)
        end

        if validName and not duplicate then
            return '.' .. c.Name
        end
        return (':WaitForChild(%s)'):format(nameLit)
    end

    if i == Players.LocalPlayer then
        return 'game:GetService("Players").LocalPlayer'
    end
    if
        i == workspace
        or (
            typeof(i) == 'Instance'
            and i:IsDescendantOf(workspace)
            and i == workspace
        )
    then
        return 'workspace'
    end
    if i == game then
        return 'game'
    end

    local plr = getplayer(i)
    if plr then
        local out = ''
        local cur = i
        while cur and cur ~= plr.Character do
            out = stepFromParentToChild(cur.Parent, cur) .. out
            cur = cur.Parent
        end
        if plr == Players.LocalPlayer then
            return 'game:GetService("Players").LocalPlayer.Character' .. out
        else
            return ('game:GetService("Players"):GetPlayerByUserId(%d).Character'):format(
                plr.UserId
            ) .. out
        end
    end

    local out = ''
    local cur = i

    if not cur.Parent then
        return ('getNil(%s, %q)'):format(q(cur.Name), cur.ClassName)
    end

    while cur and cur.Parent and cur.Parent ~= game do
        out = stepFromParentToChild(cur.Parent, cur) .. out
        if Players.LocalPlayer and cur:IsDescendantOf(Players.LocalPlayer) then
            return 'game:GetService("Players").LocalPlayer' .. out
        end
        cur = cur.Parent
    end

    if not cur then
        return 'nil'
    end

    local root = cur
    local base
    local class = root.ClassName
    local svcOk = pcall(function()
        game:GetService(class)
    end)

    if svcOk then
        if class:lower() == 'workspace' then
            base = 'workspace'
        else
            base = ('game:GetService(%q)'):format(class)
        end
    else
        if isIdent(root.Name) then
            base = 'game.' .. root.Name
        else
            base = ('game:FindFirstChild(%s)'):format(q(root.Name))
        end
    end

    local descend = ''
    local node = i
    local chain = {}
    while node and node ~= root do
        table.insert(chain, 1, node)
        node = node.Parent
    end
    for _, child in ipairs(chain) do
        descend = descend .. stepFromParentToChild(child.Parent, child)
    end

    if Players.LocalPlayer and i:IsDescendantOf(Players.LocalPlayer) then
        base = 'game:GetService("Players").LocalPlayer'
        descend = ''
        node = i
        while node and node ~= Players.LocalPlayer do
            descend = stepFromParentToChild(node.Parent, node) .. descend
            node = node.Parent
        end
    end

    return base .. descend
end

--- Gets the player an instance is descended from
function getplayer(instance)
    for _, v in next, Players:GetPlayers() do
        if
            v.Character
            and (
                instance:IsDescendantOf(v.Character)
                or instance == v.Character
            )
        then
            return v
        end
    end
end

--- value-to-path (in table)
function v2p(x, t, path, prev)
    if not path then
        path = ''
    end
    if not prev then
        prev = {}
    end
    if rawequal(x, t) then
        return true, ''
    end
    for i, v in next, t do
        if rawequal(v, x) then
            if type(i) == 'string' and i:match('^[%a_]+[%w_]*$') then
                return true, (path .. '.' .. i)
            else
                return true, (path .. '[' .. v2s(i) .. ']')
            end
        end
        if type(v) == 'table' then
            local duplicate = false
            for _, y in next, prev do
                if rawequal(y, v) then
                    duplicate = true
                end
            end
            if not duplicate then
                table.insert(prev, t)
                local found
                found, p = v2p(x, v, path, prev)
                if found then
                    if type(i) == 'string' and i:match('^[%a_]+[%w_]*$') then
                        return true, '.' .. i .. p
                    else
                        return true, '[' .. v2s(i) .. ']' .. p
                    end
                end
            end
        end
    end
    return false, ''
end

--- format s: string, byte encrypt (for weird symbols)
local function formatstr_with_status(s, indentation)
    if not indentation then
        indentation = 0
    end
    local handled, reachedMax = handlespecials(s, indentation)
    local literal = '"'
        .. handled
        .. '"'
        .. (
            reachedMax
                and " --[[ MAXIMUM STRING SIZE REACHED, CHANGE 'getgenv().SimpleSpyMaxStringSize' TO ADJUST MAXIMUM SIZE ]]"
            or ''
        )
    return literal, reachedMax
end

function formatstr(s, indentation)
    local literal = formatstr_with_status(s, indentation)
    return literal
end

--- Adds \'s to the text as a replacement to whitespace chars and other things because string.format can't yayeet

local function isFinished(coroutines: table)
    for _, v in next, coroutines do
        if status(v) == 'running' then
            return false
        end
    end
    return true
end

local specialstrings = {
    ['\n'] = function(thread, index)
        resume(thread, index, '\\n')
    end,
    ['\t'] = function(thread, index)
        resume(thread, index, '\\t')
    end,
    ['\\'] = function(thread, index)
        resume(thread, index, '\\\\')
    end,
    ['"'] = function(thread, index)
        resume(thread, index, '\\"')
    end,
}

function handlespecials(s, indentation)
    local i = 0
    local n = 1
    local coroutines = {}
    local coroutineFunc = function(i, r)
        s = s:sub(0, i - 1) .. r .. s:sub(i + 1, -1)
    end
    local timeout = 0
    repeat
        i += 1
        if timeout >= 10 then
            task.wait()
            timeout = 0
        end
        local char = s:sub(i, i)

        if byte(char) then
            timeout += 1
            local c = create(coroutineFunc)
            table.insert(coroutines, c)
            local specialfunc = specialstrings[char]

            if specialfunc then
                specialfunc(c, i)
                i += 1
            elseif byte(char) > 126 or byte(char) < 32 then
                resume(c, i, '\\' .. byte(char))
                -- s = s:sub(0, i - 1) .. "\\" .. byte(char) .. s:sub(i + 1, -1)
                i += #rawtostring(byte(char))
            end
            if i >= n * 100 then
                local extra = string.format(
                    '" ..\n%s"',
                    string.rep(' ', indentation + indent)
                )
                s = s:sub(0, i) .. extra .. s:sub(i + 1, -1)
                i += #extra
                n += 1
            end
        end
    until char == '' or i > (getgenv().SimpleSpyMaxStringSize or 10000)
    while not isFinished(coroutines) do
        RunService.Heartbeat:Wait()
    end
    clear(coroutines)
    if i > (getgenv().SimpleSpyMaxStringSize or 10000) then
        s = string.sub(s, 0, getgenv().SimpleSpyMaxStringSize or 10000)
        return s, true
    end
    return s, false
end

function is_buffer(u)
    if typeof(u) == 'buffer' then
        return true
    end
    if buffer then
        local ok = pcall(buffer.len, u)
        if ok then
            return true
        end
    end
    return false
end

local function _buf_bytes(b)
    local n = buffer.len(b)
    local t = table.create(n)
    for i = 0, n - 1 do
        t[i + 1] = buffer.readu8(b, i)
    end
    return t
end

local function buffer_hex_preview(bytes, limit)
    local hexdumpLines = {}
    local lineBytes = {}
    local shown = math.min(limit, #bytes)
    for i = 1, shown do
        lineBytes[#lineBytes + 1] = string.format('%02X', bytes[i])
        if #lineBytes >= 16 then
            hexdumpLines[#hexdumpLines + 1] = table.concat(lineBytes, ' ')
            lineBytes = {}
        end
    end
    if #lineBytes > 0 then
        hexdumpLines[#hexdumpLines + 1] = table.concat(lineBytes, ' ')
    end
    if #hexdumpLines > 0 then
        return table.concat(hexdumpLines, '\n'), shown
    end
    return nil, 0
end

local function buffer_string_literal(bytes, maxLiteralBytes, indentation)
    local count = #bytes
    if count == 0 or count > maxLiteralBytes then
        return nil
    end
    local chars = table.create(count)
    for i = 1, count do
        chars[i] = string.char(bytes[i])
    end
    local literal, reachedMax =
        formatstr_with_status(table.concat(chars), indentation or 0)
    if reachedMax then
        return nil
    end
    return ('buffer.fromstring(%s)'):format(literal)
end

local function buffer_char_literal(bytes)
    local count = #bytes
    if count == 0 then
        return 'buffer.fromstring("")'
    end
    local chunks = {}
    local line = {}
    local c = 0
    for i = 1, count do
        c += 1
        line[#line + 1] = tostring(bytes[i])
        if c >= 256 then
            chunks[#chunks + 1] = table.concat(line, ',')
            line = {}
            c = 0
        end
    end
    if #line > 0 then
        chunks[#chunks + 1] = table.concat(line, ',')
    end
    if #chunks == 1 then
        return ('buffer.fromstring(string.char(%s))'):format(chunks[1])
    end
    local parts = table.create(#chunks)
    for i = 1, #chunks do
        parts[i] = ('string.char(%s)'):format(chunks[i])
    end
    return ("buffer.fromstring(table.concat({%s}, ''))"):format(
        table.concat(parts, ',')
    )
end

function buffer_literal(u, indentation)
    local ok_len, n = pcall(buffer.len, u)
    if not ok_len or type(n) ~= 'number' or n <= 0 then
        return 'buffer.fromstring("")'
    end
    local bytes = _buf_bytes(u)
    local previewLimit =
        math.min(n, math.max(1, getgenv().SimpleSpyMaxBufferPreview or 256))
    local hexdump, shown = nil, 0
    if bufferDumpEnabled and previewLimit > 0 then
        hexdump, shown = buffer_hex_preview(bytes, previewLimit)
    end
    local maxLiteralBytes = getgenv().SimpleSpyMaxStringSize
    if type(maxLiteralBytes) ~= 'number' or maxLiteralBytes <= 0 then
        maxLiteralBytes = 10000
    end
    local literal = buffer_string_literal(bytes, maxLiteralBytes, indentation)
    if not literal then
        literal = buffer_char_literal(bytes)
    end
    if hexdump then
        literal = ('--[[buffer dump (%d bytes, showing %d)\n%s\n]]%s'):format(
            n,
            shown,
            hexdump,
            literal
        )
    end
    return literal
end

--- finds script from 'src' from getinfo, returns nil if not found
--- @param src string
function getScriptFromSrc(src)
    local realPath
    local runningTest
    --- @type number
    local s, e
    local match = false
    if src:sub(1, 1) == '=' then
        realPath = game
        s = 2
    else
        runningTest = src:sub(2, e and e - 1 or -1)
        for _, v in next, getnilinstances() do
            if v.Name == runningTest then
                realPath = v
                break
            end
        end
        s = #runningTest + 1
    end
    if realPath then
        e = src:sub(s, -1):find('%.')
        local i = 0
        repeat
            i += 1
            if not e then
                runningTest = src:sub(s, -1)
                local test = realPath.FindFirstChild(realPath, runningTest)
                if test then
                    realPath = test
                end
                match = true
            else
                runningTest = src:sub(s, e)
                local test = realPath.FindFirstChild(realPath, runningTest)
                local yeOld = e
                if test then
                    realPath = test
                    s = e + 2
                    e = src:sub(e + 2, -1):find('%.')
                    e = e and e + yeOld or e
                else
                    e = src:sub(e + 2, -1):find('%.')
                    e = e and e + yeOld or e
                end
            end
        until match or i >= 50
    end
    return realPath
end

--- schedules the provided function (and calls it with any args after)

local function scheduleUrgent(f, ...)
    table.insert(scheduled, 1, { f, ... })
end

function schedule(f, ...)
    table.insert(scheduled, { f, ... })
end

--- yields the current thread until the scheduler gives the ok
function scheduleWait()
    local thread = running()
    schedule(function()
        resume(thread)
    end)
    yield()
end

--- the big (well tbh small now) boi task scheduler himself, handles p much anything as quicc as possible
local function taskscheduler()
    if not toggle then
        scheduled = {}
        return
    end
    local burst = tonumber(getgenv().SIMPLESPYCONFIG_SchedulerBurst) or 12
    local n = math.min(burst, #scheduled)
    for _ = 1, n do
        local currentf = table.remove(scheduled, 1)
        if type(currentf) == 'table' and type(currentf[1]) == 'function' then
            pcall(unpack(currentf))
        end
    end
end

local function tablecheck(tabletocheck, instance, id)
    return tabletocheck[id] or tabletocheck[instance.Name]
end

function remoteHandler(data)
    local m = string.lower(data.method or '')
    if
        (m == 'fireserver' and not configs.log_FireServer)
        or (m == 'invokeserver' and not configs.log_InvokeServer)
        or (m == 'fire' and not configs.log_Fire)
        or (m == 'invoke' and not configs.log_Invoke)
    then
        return
    end

    if configs.autoblock then
        local id = data.id
        if excluding[id] then
            return
        end

        local now = tick()
        local h = history[id]

        if not h then
            h = { badOccurances = 0, lastCall = now }
            history[id] = h
        else
            if now - h.lastCall < 1 then
                h.badOccurances += 1
                h.lastCall = now
                if h.badOccurances >= 3 then
                    excluding[id] = true
                    return
                end
            else
                h.badOccurances = 0
                h.lastCall = now
            end
        end
    end

    newRemote(
        (
            data.remote:IsA('RemoteFunction')
            or data.remote:IsA('BindableFunction')
        ) and 'function'
            or 'event',
        data
    )
end

local RemoteClassData = {
    RemoteEvent = {
        Send = { 'fireserver' },
        Receive = { 'onclientevent' },
    },
    RemoteFunction = {
        IsRemoteFunction = true,
        Send = { 'invokeserver' },
        Receive = { 'onclientinvoke' },
    },
    UnreliableRemoteEvent = {
        Send = { 'fireserver' },
        Receive = { 'onclientevent' },
    },
    BindableEvent = {
        Send = { 'fire' },
        Receive = { 'event' },
    },
    BindableFunction = {
        IsRemoteFunction = true,
        Send = { 'invoke' },
        Receive = { 'oninvoke' },
    },
}

local table_maxn = table.maxn
if not table_maxn then
    table_maxn = function(t)
        local max = 0
        for k in next, t do
            if type(k) == 'number' and k > max then
                max = k
            end
        end
        return max
    end
end

local function normalizeMethod(method)
    if typeof(method) == 'string' then
        return lower(method)
    end
end

local function methodAllowed(classData, transferType, method)
    if not classData or not method or method == '' then
        return false
    end

    local key = transferType == 'Receive' and 'Receive' or 'Send'
    local allowed = classData[key]
    if not allowed then
        return false
    end

    for _, name in ipairs(allowed) do
        if name == method then
            return true
        end
    end

    return false
end

local function callOriginal(callback, args, length)
    if not callback then
        return
    end

    local callArgs = args or {}
    local callLength = length
    if not callLength then
        callLength = table_maxn(callArgs)
    end

    if callLength and callLength > 0 then
        return callback(unpack(callArgs, 1, callLength))
    end
    return callback()
end

local table_pack = table.pack
if not table_pack then
    table_pack = function(...)
        local packed = { ... }
        packed.n = select('#', ...)
        return packed
    end
end

captureRemoteCall = function(options)
    local args = options.args or {}
    local argsLength = options.argsLength
    if not argsLength then
        argsLength = table_maxn(args)
    end
    local remote = options.remote
    local transferType = options.transferType == 'Receive' and 'Receive'
        or 'Send'
    if internalRemotes[remote] then
        return callOriginal(options.callOriginal, args, argsLength)
    end
    if typeof(remote) ~= 'Instance' then
        return callOriginal(options.callOriginal, args, argsLength)
    end

    local classData = RemoteClassData[remote.ClassName]
    local normalizedMethod = normalizeMethod(options.method)
    if not methodAllowed(classData, transferType, normalizedMethod) then
        return callOriginal(options.callOriginal, args, argsLength)
    end

    if transferType == 'Receive' and not configs.log_Receive then
        return callOriginal(options.callOriginal, args, argsLength)
    end

    if
        transferType == 'Send'
        and not configs.logcheckcaller
        and safeCheckCaller()
    then
        return callOriginal(options.callOriginal, args, argsLength)
    end

    local id = ThreadGetDebugId(remote)
    local blockcheck = false
    if transferType == 'Send' then
        blockcheck = tablecheck(blocklist, remote, id)
        if normalizedMethod == 'fireserver' and not configs.call_FireServer then
            blockcheck = true
        elseif
            normalizedMethod == 'invokeserver'
            and not configs.call_InvokeServer
        then
            blockcheck = true
        end
    end

    if
        transferType == 'Receive'
        and configs.blockIncoming
        and tablecheck(blocklist, remote, id)
    then
        return
    end

    local callingScript = options.callingscript
    if callingScript == nil then
        callingScript = getcallingscript()
    end

    local infoLevel = options.infoLevel or 2
    local infoFunc = options.infofunc or safeDebugInfo(infoLevel, 'f')
    local infoSource = options.infosource or safeDebugInfo(infoLevel, 's')
    local infoLine = options.infoline or safeDebugInfo(infoLevel, 'l')
    local isExec = options.isexecutor
    if isExec == nil then
        isExec = transferType == 'Send' and safeCheckCaller() or false
    end

    local blacklisted = tablecheck(blacklist, remote, id)
    local entry
    if not blacklisted and not IsCyclicTable(args) then
        entry = {
            method = normalizedMethod,
            remote = remote,
            args = deepclone(args),
            infofunc = infoFunc,
            callingscript = callingScript and cloneref(callingScript) or nil,
            source = infoSource,
            line = infoLine,
            isexecutor = isExec,
            metamethod = options.metaMethod or transferType,
            blockcheck = blockcheck,
            blocked = blockcheck,
            id = id,
            returnvalue = { data = nil },
        }
        schedule(remoteHandler, entry)
    end

    if transferType == 'Send' and blockcheck then
        return
    end

    if not options.callOriginal then
        return
    end

    local results
    if argsLength and argsLength > 0 then
        results = table_pack(options.callOriginal(unpack(args, 1, argsLength)))
    else
        results = table_pack(options.callOriginal())
    end
    local resultLength = (results and results.n) or table_maxn(results)
    if entry and entry.returnvalue then
        local ok, cloned = pcall(deepclone, results)
        entry.returnvalue.data = ok and cloned or results
    end

    return unpack(results, 1, resultLength)
end

local function call_original_namecall(method, self, ...)
    if setnamecallmethod then
        setnamecallmethod(method)
    end
    return originalnamecall(self, ...)
end

local newnamecall = newcclosure(function(self, ...)
    local method = caps.getNamecallMethod and getnamecallmethod() or nil
    local args = { ... }
    local argsLength = select('#', ...)
    if internalRemotes[self] then
        return call_original_namecall(method, self, ...)
    end
    return captureRemoteCall({
        remote = cloneref(self),
        method = method,
        args = args,
        argsLength = argsLength,
        metaMethod = '__namecall',
        callOriginal = function(...)
            return call_original_namecall(method, self, ...)
        end,
    })
end)

local newFireServer = newcclosure(function(self, ...)
    local args = { ... }
    local argsLength = select('#', ...)
    if internalRemotes[self] then
        return originalEvent(self, ...)
    end
    return captureRemoteCall({
        remote = cloneref(self),
        method = 'FireServer',
        args = args,
        argsLength = argsLength,
        metaMethod = '__index',
        callOriginal = function(...)
            return originalEvent(self, ...)
        end,
    })
end)

local newInvokeServer = newcclosure(function(self, ...)
    local args = { ... }
    local argsLength = select('#', ...)
    if internalRemotes[self] then
        return originalFunction(self, ...)
    end
    return captureRemoteCall({
        remote = cloneref(self),
        method = 'InvokeServer',
        args = args,
        argsLength = argsLength,
        metaMethod = '__index',
        callOriginal = function(...)
            return originalFunction(self, ...)
        end,
    })
end)

local newFireBindable = newcclosure(function(self, ...)
    local args = { ... }
    local argsLength = select('#', ...)
    if internalRemotes[self] then
        return originalBindableEventFire(self, ...)
    end
    return captureRemoteCall({
        remote = cloneref(self),
        method = 'Fire',
        args = args,
        argsLength = argsLength,
        metaMethod = '__index',
        callOriginal = function(...)
            return originalBindableEventFire(self, ...)
        end,
    })
end)

local newInvokeBindable = newcclosure(function(self, ...)
    local args = { ... }
    local argsLength = select('#', ...)
    if internalRemotes[self] then
        return originalBindableFunctionInvoke(self, ...)
    end
    return captureRemoteCall({
        remote = cloneref(self),
        method = 'Invoke',
        args = args,
        argsLength = argsLength,
        metaMethod = '__index',
        callOriginal = function(...)
            return originalBindableFunctionInvoke(self, ...)
        end,
    })
end)

local hookState = {
    active = false,
    namecall = false,
    fireServer = false,
    invokeServer = false,
    bindableFire = false,
    bindableInvoke = false,
}

local function disablehooks()
    if not hookState.active then
        return
    end
    hookState.active = false

    if synv3 then
        if hookState.namecall and caps.unhookAPI and caps.rawMetatable and originalnamecall then
            pcall(unhook, getrawmetatable(game).__namecall, originalnamecall)
        end
        if hookState.fireServer and caps.unhookAPI and originalEvent then
            pcall(unhook, Instance.new('RemoteEvent').FireServer, originalEvent)
        end
        if hookState.invokeServer and caps.unhookAPI and originalFunction then
            pcall(
                unhook,
                Instance.new('RemoteFunction').InvokeServer,
                originalFunction
            )
        end
        if hookState.bindableFire and caps.unhookAPI and originalBindableEventFire then
            pcall(
                unhook,
                Instance.new('BindableEvent').Fire,
                originalBindableEventFire
            )
        end
        if
            hookState.bindableInvoke
            and caps.unhookAPI
            and originalBindableFunctionInvoke
        then
            pcall(
                unhook,
                Instance.new('BindableFunction').Invoke,
                originalBindableFunctionInvoke
            )
        end
        if hookState.namecall and caps.restoreFunction and originalnamecall then
            pcall(restorefunction, originalnamecall)
        end
        if hookState.fireServer and caps.restoreFunction and originalEvent then
            pcall(restorefunction, originalEvent)
        end
        if hookState.invokeServer and caps.restoreFunction and originalFunction then
            pcall(restorefunction, originalFunction)
        end
        if
            hookState.bindableFire
            and caps.restoreFunction
            and originalBindableEventFire
        then
            pcall(restorefunction, originalBindableEventFire)
        end
        if
            hookState.bindableInvoke
            and caps.restoreFunction
            and originalBindableFunctionInvoke
        then
            pcall(restorefunction, originalBindableFunctionInvoke)
        end
    else
        if hookState.namecall and originalnamecall then
            if type(hookmetamethod) == 'function' then
                pcall(hookmetamethod, game, '__namecall', originalnamecall)
            elseif caps.hookFunction and caps.rawMetatable then
                pcall(
                    hookfunction,
                    getrawmetatable(game).__namecall,
                    originalnamecall
                )
            end
        end
        if hookState.fireServer and caps.hookFunction and originalEvent then
            pcall(hookfunction, Instance.new('RemoteEvent').FireServer, originalEvent)
        end
        if hookState.invokeServer and caps.hookFunction and originalFunction then
            pcall(
                hookfunction,
                Instance.new('RemoteFunction').InvokeServer,
                originalFunction
            )
        end
        if hookState.bindableFire and caps.hookFunction and originalBindableEventFire then
            pcall(
                hookfunction,
                Instance.new('BindableEvent').Fire,
                originalBindableEventFire
            )
        end
        if
            hookState.bindableInvoke
            and caps.hookFunction
            and originalBindableFunctionInvoke
        then
            pcall(
                hookfunction,
                Instance.new('BindableFunction').Invoke,
                originalBindableFunctionInvoke
            )
        end
    end

    hookState.namecall = false
    hookState.fireServer = false
    hookState.invokeServer = false
    hookState.bindableFire = false
    hookState.bindableInvoke = false
end

--- Toggles on and off the remote spy
function toggleSpy()
    if not caps.sendHooks then
        return false
    end

    if not toggle then
        hookState.namecall = false
        hookState.fireServer = false
        hookState.invokeServer = false
        hookState.bindableFire = false
        hookState.bindableInvoke = false

        local oldnamecall
        if synv3 then
            if caps.namecallHook and caps.hookAPI and caps.rawMetatable then
                local ok, previous = pcall(
                    hook,
                    getrawmetatable(game).__namecall,
                    clonefunction(newnamecall)
                )
                if ok then
                    oldnamecall = previous
                    hookState.namecall = true
                end
            end
            if caps.hookAPI then
                local okFire, oldFire = pcall(
                    hook,
                    Instance.new('RemoteEvent').FireServer,
                    clonefunction(newFireServer)
                )
                if okFire then
                    originalEvent = oldFire
                    hookState.fireServer = true
                end
                local okInvoke, oldInvoke = pcall(
                    hook,
                    Instance.new('RemoteFunction').InvokeServer,
                    clonefunction(newInvokeServer)
                )
                if okInvoke then
                    originalFunction = oldInvoke
                    hookState.invokeServer = true
                end
                local okBindableFire, oldBindableFire = pcall(
                    hook,
                    Instance.new('BindableEvent').Fire,
                    clonefunction(newFireBindable)
                )
                if okBindableFire then
                    originalBindableEventFire = oldBindableFire
                    hookState.bindableFire = true
                end
                local okBindableInvoke, oldBindableInvoke = pcall(
                    hook,
                    Instance.new('BindableFunction').Invoke,
                    clonefunction(newInvokeBindable)
                )
                if okBindableInvoke then
                    originalBindableFunctionInvoke = oldBindableInvoke
                    hookState.bindableInvoke = true
                end
            end
        else
            if caps.namecallHook then
                if type(hookmetamethod) == 'function' then
                    local ok, previous = pcall(
                        hookmetamethod,
                        game,
                        '__namecall',
                        clonefunction(newnamecall)
                    )
                    if ok then
                        oldnamecall = previous
                        hookState.namecall = true
                    end
                elseif caps.hookFunction and caps.rawMetatable then
                    local ok, previous = pcall(
                        hookfunction,
                        getrawmetatable(game).__namecall,
                        clonefunction(newnamecall)
                    )
                    if ok then
                        oldnamecall = previous
                        hookState.namecall = true
                    end
                end
            end
            if caps.hookFunction then
                local okFire, oldFire = pcall(
                    hookfunction,
                    Instance.new('RemoteEvent').FireServer,
                    clonefunction(newFireServer)
                )
                if okFire then
                    originalEvent = oldFire
                    hookState.fireServer = true
                end
                local okInvoke, oldInvoke = pcall(
                    hookfunction,
                    Instance.new('RemoteFunction').InvokeServer,
                    clonefunction(newInvokeServer)
                )
                if okInvoke then
                    originalFunction = oldInvoke
                    hookState.invokeServer = true
                end
                local okBindableFire, oldBindableFire = pcall(
                    hookfunction,
                    Instance.new('BindableEvent').Fire,
                    clonefunction(newFireBindable)
                )
                if okBindableFire then
                    originalBindableEventFire = oldBindableFire
                    hookState.bindableFire = true
                end
                local okBindableInvoke, oldBindableInvoke = pcall(
                    hookfunction,
                    Instance.new('BindableFunction').Invoke,
                    clonefunction(newInvokeBindable)
                )
                if okBindableInvoke then
                    originalBindableFunctionInvoke = oldBindableInvoke
                    hookState.bindableInvoke = true
                end
            end
        end
        if oldnamecall then
            originalnamecall = originalnamecall
                or function(...)
                    return oldnamecall(...)
                end
        end
        hookState.active = hookState.namecall
            or hookState.fireServer
            or hookState.invokeServer
            or hookState.bindableFire
            or hookState.bindableInvoke
    else
        disablehooks()
    end

    return true
end

--- Toggles between the two remotespy methods (hookfunction currently = disabled)
function toggleSpyMethod()
    toggleSpy()
    toggle = not toggle
end

--- Shuts down the remote spy
local function shutdown()
    if schedulerconnect then
        schedulerconnect:Disconnect()
    end
    for _, connection in next, connections do
        connection:Disconnect()
    end
    for i, v in next, running_threads do
        if ThreadIsNotDead(v) then
            close(v)
        end
    end
    clear(running_threads)
    clear(connections)
    clear(logs)
    clear(remoteLogs)
    disablehooks()
    ui.SimpleSpy3:Destroy()
    ui.Storage:Destroy()
    UserInputService.MouseIconEnabled = true
    getgenv().SimpleSpyExecuted = false
end

-- main
if not getgenv().SimpleSpyExecuted then
    local succeeded, err = pcall(function()
        if not RunService:IsClient() then
            error('SimpleSpy cannot run on the server!')
        end
        getgenv().SimpleSpyShutdown = shutdown
        onToggleButtonClick()
        if not caps.sendHooks then
            ErrorPrompt(
                'Outbound hooks are unavailable. Falling back to OnClientEvent/OnClientInvoke logging only.',
                true
            )
        elseif not caps.namecallHook then
            ErrorPrompt(
                'Namecall hook is unavailable. Using direct FireServer/InvokeServer hooks only.',
                true
            )
        end
        codebox = Highlight.new(ui.CodeBox)
        logthread(spawn(function()
            local suc, err = pcall(
                game.HttpGet,
                game,
                'https://raw.githubusercontent.com/78n/SimpleSpy/main/UpdateLog.lua'
            )
            codebox:setRaw((suc and err) or '')
        end))
        getgenv().SimpleSpy = SimpleSpy
        logthread(spawn(runAdonisBypass))
        getgenv().getNil = function(name, class)
            for _, v in next, getnilinstances() do
                if v.ClassName == class and v.Name == name then
                    return v
                end
            end
        end
        ui.Background.MouseEnter:Connect(function(...)
            mouseInGui = true
            mouseEntered()
        end)
        ui.Background.MouseLeave:Connect(function(...)
            mouseInGui = false
            mouseEntered()
        end)
        ui.TextLabel:GetPropertyChangedSignal('Text'):Connect(scaleToolTip)
        -- ui.TopBar.InputBegan:Connect(onBarInput)
        ui.MinimizeButton.MouseButton1Click:Connect(toggleMinimize)
        ui.MaximizeButton.MouseButton1Click:Connect(toggleSideTray)
        ui.Simple.MouseButton1Click:Connect(onToggleButtonClick)
        ui.CloseButton.MouseEnter:Connect(onXButtonHover)
        ui.CloseButton.MouseLeave:Connect(onXButtonUnhover)
        ui.Simple.MouseEnter:Connect(onToggleButtonHover)
        ui.Simple.MouseLeave:Connect(onToggleButtonUnhover)
        ui.CloseButton.MouseButton1Click:Connect(shutdown)
        table.insert(
            connections,
            UserInputService.InputBegan:Connect(backgroundUserInput)
        )
        connectResize()
        ui.SimpleSpy3.Enabled = true
        logthread(spawn(function()
            delay(1, onToggleButtonUnhover)
        end))
        schedulerconnect = RunService.Heartbeat:Connect(taskscheduler)
        bringBackOnResize()
        protectUI(ui.SimpleSpy3)
        logthread(spawn(function()
            local lp = Players.LocalPlayer
                or Players:GetPropertyChangedSignal('LocalPlayer'):Wait()
                or Players.LocalPlayer
            generation = {
                [OldDebugId(lp)] = 'game:GetService("Players").LocalPlayer',
                [OldDebugId(lp:GetMouse())] = 'game:GetService("Players").LocalPlayer:GetMouse',
                [OldDebugId(game)] = 'game',
                [OldDebugId(SafeGetService('Workspace'))] = 'workspace',
            }
        end))
    end)
    if succeeded then
        getgenv().SimpleSpyExecuted = true
    else
        shutdown()
        ErrorPrompt('An error has occured:\n' .. rawtostring(err))
        return
    end
else
    ui.SimpleSpy3:Destroy()
    return
end

local oldNewIndex
if caps.newIndexHook and type(hookmetamethod) == 'function' then
    local ok, hooked = pcall(
        hookmetamethod,
        game,
        '__newindex',
        function(self, k, v)
            if
                not safeCheckCaller()
                and typeof(self) == 'Instance'
                and self:IsA('RemoteFunction')
                and k == 'OnClientInvoke'
                and type(v) == 'function'
            then
                return oldNewIndex(self, k, setWrappedOnClientInvoke(self, v))
            end
            return oldNewIndex(self, k, v)
        end
    )
    if ok then
        oldNewIndex = hooked
    end
end

for _, inst in ipairs(game:GetDescendants()) do
    if inst:IsA("RemoteEvent") or inst:IsA("UnreliableRemoteEvent") then
        logClientEvent(inst)
    end
    if inst:IsA("RemoteFunction") then
        wrapClientInvoke(inst)
    end
end

game.DescendantAdded:Connect(function(inst)
    if inst:IsA("RemoteEvent") or inst:IsA("UnreliableRemoteEvent") then
        logClientEvent(inst)
    end
    if inst:IsA("RemoteFunction") then
        wrapClientInvoke(inst)
    end
end)

function SimpleSpy:newButton(name, description, onClick)
    return newButton(name, description, onClick)
end

----- ADD ONS ----- (easily add or remove additonal functionality to the RemoteSpy!)
--[[
    Some helpful things:
        - add your function in here, and create buttons for them through the 'newButton' function
        - the first argument provided is the TextButton the player clicks to run the function
        - generated scripts are generated when the namecall is initially fired and saved in remoteFrame objects
        - blacklisted remotes will be ignored directly in namecall (less lag)
        - the properties of a 'remoteFrame' object:
            {
                Name: (string) The name of the Remote
                GenScript: (string) The generated script that appears in the ui.CodeBox (generated when namecall fired)
                Source: (Instance (LocalScript)) The script that fired/invoked the remote
                Remote: (Instance (RemoteEvent) | Instance (RemoteFunction)) The remote that was fired/invoked
                Log: (Instance (TextButton)) The button being used for the remote (same as 'selected.Log')
            }
        - globals list: (contact @exx#9394 for more information or if you have suggestions for more to be added)
            - closed: (boolean) whether or not the GUI is currently minimized
            - logs: (table[remoteFrame]) full of remoteFrame objects (properties listed above)
            - selected: (remoteFrame) the currently selected remoteFrame (properties listed above)
            - blacklist: (string[] | Instance[] (RemoteEvent) | Instance[] (RemoteFunction)) an array of blacklisted names and remotes
            - ui.CodeBox: (Instance (Frame)) container for the Highlight code viewer
]]

do
    ui.NextButton.MouseButton1Click:Connect(function()
        ui.Background.Visible = not ui.Background.Visible
        ui.NextButton.Text = ui.Background.Visible and '-' or '+'
    end)
    ui.NextButton.InputBegan:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            local lastPos = UserInputService:GetMouseLocation()
            local startPos = ui.NextButton.AbsolutePosition
            if not connections['dragNextb'] then
                connections['dragNextb'] = RunService.RenderStepped:Connect(
                    function()
                        local newPos = UserInputService:GetMouseLocation()
                        if newPos ~= lastPos then
                            local dx, dy =
                                newPos.X - lastPos.X, newPos.Y - lastPos.Y
                            startPos = startPos + Vector2.new(dx, dy)
                            ui.NextButton.Position =
                                UDim2.fromOffset(startPos.X, startPos.Y)
                            lastPos = newPos
                        end
                    end
                )
            end
            table.insert(
                connections,
                UserInputService.InputEnded:Connect(function(e)
                    if e == input and connections['dragNextb'] then
                        connections['dragNextb']:Disconnect()
                        connections['dragNextb'] = nil
                    end
                end)
            )
        end
    end)
end

-- Copies the contents of the ui.CodeBox
newButton('Copy Code', function()
    return 'Click to copy code'
end, function()
    setclipboard(codebox:getString())
    ui.TextLabel.Text = 'Copied successfully!'
end)

--- Copies the source script (that fired the remote)
newButton('Copy Remote', function()
    return 'Click to copy the path of the remote'
end, function()
    if selected and selected.Remote then
        setclipboard(v2s(selected.Remote))
        ui.TextLabel.Text = 'Copied!'
    end
end)

-- Executes the contents of the ui.CodeBox through loadstring
newButton('Run Code', function()
    return 'Click to execute code'
end, function()
    local src = codebox:getString()
    if not src or src == '' then
        ui.TextLabel.Text = 'CodeBox is empty'
        return
    end

    local fn, err = loadstring(src)
    if not fn then
        ui.TextLabel.Text = 'Compile error: ' .. tostring(err)
        return
    end

    local ok, runtimeErr = pcall(fn)
    if not ok then
        ui.TextLabel.Text = 'Runtime error: ' .. tostring(runtimeErr)
    else
        ui.TextLabel.Text = 'Code executed'
    end
end)

if caps.sendHooks then
    newButton('Log FireServer', function()
        return ('[%s] FireServer'):format(
            configs.log_FireServer and 'ON' or 'OFF'
        )
    end, function()
        configs.log_FireServer = not configs.log_FireServer
        ui.TextLabel.Text = ('FireServer: %s'):format(
            configs.log_FireServer and 'ON' or 'OFF'
        )
    end)

    newButton('Log InvokeServer', function()
        return ('[%s] InvokeServer'):format(
            configs.log_InvokeServer and 'ON' or 'OFF'
        )
    end, function()
        configs.log_InvokeServer = not configs.log_InvokeServer
        ui.TextLabel.Text = ('InvokeServer: %s'):format(
            configs.log_InvokeServer and 'ON' or 'OFF'
        )
    end)

    newButton('Call FireServer', function()
        return ('[%s] Allow FireServer calls'):format(
            configs.call_FireServer and 'ON' or 'OFF'
        )
    end, function()
        configs.call_FireServer = not configs.call_FireServer
        ui.TextLabel.Text = ('FireServer calls: %s'):format(
            configs.call_FireServer and 'ALLOWED' or 'BLOCKED'
        )
    end)

    newButton('Call InvokeServer', function()
        return ('[%s] Allow InvokeServer calls'):format(
            configs.call_InvokeServer and 'ON' or 'OFF'
        )
    end, function()
        configs.call_InvokeServer = not configs.call_InvokeServer
        ui.TextLabel.Text = ('InvokeServer calls: %s'):format(
            configs.call_InvokeServer and 'ALLOWED' or 'BLOCKED'
        )
    end)

    newButton('Log Fire', function()
        return ('[%s] Bindable:Fire'):format(configs.log_Fire and 'ON' or 'OFF')
    end, function()
        configs.log_Fire = not configs.log_Fire
        ui.TextLabel.Text = ('Bindable Fire: %s'):format(
            configs.log_Fire and 'ON' or 'OFF'
        )
    end)

    newButton('Log Invoke', function()
        return ('[%s] Bindable:Invoke'):format(
            configs.log_Invoke and 'ON' or 'OFF'
        )
    end, function()
        configs.log_Invoke = not configs.log_Invoke
        ui.TextLabel.Text = ('Bindable Invoke: %s'):format(
            configs.log_Invoke and 'ON' or 'OFF'
        )
    end)
end

newButton('Log Client', function()
    return ('[%s] OnClientEvent/OnClientInvoke'):format(
        configs.log_Receive and 'ON' or 'OFF'
    )
end, function()
    configs.log_Receive = not configs.log_Receive
    ui.TextLabel.Text = ('Client events: %s'):format(
        configs.log_Receive and 'ON' or 'OFF'
    )
end)

newButton('Adonis Bypass', function()
    return ('[%s] Adonis anticheat bypass'):format(
        configs.adonisBypass and 'AUTO' or 'OFF'
    )
end, function()
    configs.adonisBypass = not configs.adonisBypass
    if configs.adonisBypass then
        logthread(spawn(runAdonisBypass))
    end
    ui.TextLabel.Text = configs.adonisBypass and 'Auto-bypass enabled'
        or 'Auto-bypass disabled'
end)

--- Gets the calling script (not super reliable but w/e)
newButton('Get Script', function()
    return 'Click to copy calling script to clipboard\nWARNING: Not super reliable, nil == could not find'
end, function()
    if selected then
        if not selected.Source then
            selected.Source = rawget(getfenv(selected.Function), 'script')
        end
        setclipboard(v2s(selected.Source))
        ui.TextLabel.Text = 'Done!'
    end
end)

--- Decompiles the script that fired the remote and puts it in the code box
newButton('Function Info', function()
    return 'Click to view calling function information'
end, function()
    local func = selected and selected.Function
    if func then
        local typeoffunc = typeof(func)

        if typeoffunc ~= 'string' then
            codebox:setRaw('--[[Generating Function Info please wait]]')
            RunService.Heartbeat:Wait()
            local lclosure = islclosure(func)
            local SourceScript = rawget(getfenv(func), 'script')
            local CallingScript = selected.Source or nil
            local info = {}

            info = {
                info = getinfo(func),
                constants = lclosure and deepclone(getconstants(func))
                    or 'N/A --Lua Closure expected got C Closure',
                upvalues = deepclone(getupvalues(func)),
                script = {
                    SourceScript = SourceScript or 'nil',
                    CallingScript = CallingScript or 'nil',
                },
            }

            if configs.advancedinfo then
                local Remote = selected.Remote

                info['advancedinfo'] = {
                    Metamethod = selected.metamethod,
                    DebugId = {
                        SourceScriptDebugId = SourceScript
                                and typeof(SourceScript) == 'Instance'
                                and OldDebugId(SourceScript)
                            or 'N/A',
                        CallingScriptDebugId = CallingScript
                                and typeof(SourceScript) == 'Instance'
                                and OldDebugId(CallingScript)
                            or 'N/A',
                        RemoteDebugId = OldDebugId(Remote),
                    },
                    Protos = lclosure and getprotos(func)
                        or 'N/A --Lua Closure expected got C Closure',
                }

                if Remote:IsA('RemoteFunction') then
                    if getcallbackmember then
                        local ok, cb =
                            pcall(getcallbackmember, Remote, 'OnClientInvoke')
                        info['advancedinfo']['OnClientInvoke'] =
                            (ok and cb) or 'N/A'
                    else
                        info['advancedinfo']['OnClientInvoke'] =
                            'N/A --Missing function getcallbackmember'
                    end
                elseif caps.getConnections then
                    info['advancedinfo']['OnClientEvents'] = {}
                    local okConnections, remoteConnections =
                        pcall(getconnections, Remote.OnClientEvent)
                    if okConnections and type(remoteConnections) == 'table' then
                        for i, v in next, remoteConnections do
                            info['advancedinfo']['OnClientEvents'][i] = {
                                Function = v.Function or 'N/A',
                                State = v.State or 'N/A',
                            }
                        end
                    end
                end
            end
            codebox:setRaw('--[[Converting table to string please wait]]')
            selected.Function = v2v({ functionInfo = info })
        end
        codebox:setRaw(
            '-- Calling function info\n-- Generated by the SimpleSpy V3 serializer\n\n'
                .. selected.Function
        )
        ui.TextLabel.Text =
            'Done! Function info generated by the SimpleSpy V3 Serializer.'
    else
        ui.TextLabel.Text = 'Error! Selected function was not found.'
    end
end)

--- Clears the Remote logs
newButton('Clr Logs', function()
    return 'Click to clear logs'
end, function()
    ui.TextLabel.Text = 'Clearing...'

    table.clear(logs)
    logsById = {}
    remoteLogs = {}

    for _, v in next, ui.LogList:GetChildren() do
        if not v:IsA('UIListLayout') then
            v:Destroy()
        end
    end

    codebox:setRaw('')
    selected = nil
    ui.TextLabel.Text = 'Logs cleared!'
end)

--- Excludes the selected.Log Remote from the RemoteSpy
newButton('Exclude (i)', function()
    return 'Click to exclude this Remote.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable.'
end, function()
    if selected then
        blacklist[OldDebugId(selected.Remote)] = true
        ui.TextLabel.Text = 'Excluded!'
    end
end)

--- Excludes all Remotes that share the same name as the selected.Log remote from the RemoteSpy
newButton('Exclude (n)', function()
    return 'Click to exclude all remotes with this name.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable.'
end, function()
    if selected then
        blacklist[selected.Name] = true
        ui.TextLabel.Text = 'Excluded!'
    end
end)

--- clears blacklist
newButton('Clr Blacklist', function()
    return 'Click to clear the blacklist.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable.'
end, function()
    blacklist = {}
    ui.TextLabel.Text = 'Blacklist cleared!'
end)

--- Prevents the selected.Log Remote from firing the server (still logged)
newButton('Block (i)', function()
    return "Click to stop this remote from firing.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server."
end, function()
    if selected then
        blocklist[OldDebugId(selected.Remote)] = true
        ui.TextLabel.Text = 'Excluded!'
    end
end)

--- Prevents all remotes from firing that share the same name as the selected.Log remote from the RemoteSpy (still logged)
newButton('Block (n)', function()
    return "Click to stop remotes with this name from firing.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server."
end, function()
    if selected then
        blocklist[selected.Name] = true
        ui.TextLabel.Text = 'Excluded!'
    end
end)

--- clears blacklist
newButton('Clr Blocklist', function()
    return "Click to stop blocking remotes.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server."
end, function()
    blocklist = {}
    ui.TextLabel.Text = 'Blocklist cleared!'
end)

--- Attempts to decompile the source script
if caps.decompile then
    newButton('Decompile', function()
        return 'Decompile source script'
    end, function()
        if selected and selected.Source then
            local Source = selected.Source
            if not DecompiledScripts[Source] then
                codebox:setRaw('--[[Decompiling]]')

                xpcall(function()
                    local decompiledsource = decompile(Source):gsub(
                        '-- Decompiled with the Synapse X Luau decompiler.',
                        ''
                    )
                    local Sourcev2s = v2s(Source)
                    if (decompiledsource):find('script') and Sourcev2s then
                        DecompiledScripts[Source] = ('local script = %s\n%s'):format(
                            Sourcev2s,
                            decompiledsource
                        )
                    end
                end, function(err)
                    return codebox:setRaw(
                        ('--[[\nAn error has occured\n%s\n]]'):format(err)
                    )
                end)
            end
            codebox:setRaw(DecompiledScripts[Source] or '--No Source Found')
            ui.TextLabel.Text = 'Done!'
        else
            ui.TextLabel.Text = 'Source not found!'
        end
    end)
end

newButton('Script Path', function()
    return 'Copy path of the calling script'
end, function()
    if not selected then
        ui.TextLabel.Text = 'No remote selected'
        return
    end
    local src = selected.Source
    if not src then
        local func = selected.Function
        if func then
            src = rawget(getfenv(func), 'script')
            selected.Source = src
        end
    end
    if not src then
        ui.TextLabel.Text = 'Source not found'
        return
    end

    local path
    local pathKind = 'instance'
    if typeof(src) == 'Instance' then
        if src.Parent then
            path = v2s(src)
        else
            local func = selected.Function
            if type(func) == 'function' then
                local debugSource = safeDebugInfo(func, 's')
                if type(debugSource) == 'string' and debugSource ~= '' then
                    path = debugSource
                    pathKind = 'debug'
                end
            end
            if not path then
                path = v2s(src)
                pathKind = 'nilinstance'
            end
        end
    elseif type(selected.Function) == 'function' then
        local debugSource = safeDebugInfo(selected.Function, 's')
        if type(debugSource) == 'string' and debugSource ~= '' then
            path = debugSource
            pathKind = 'debug'
        end
    end

    if not path then
        ui.TextLabel.Text = 'Source not found'
        return
    end
    setclipboard(path)
    if pathKind == 'debug' then
        ui.TextLabel.Text = 'Copied debug source (instance path unavailable)'
    elseif pathKind == 'nilinstance' then
        ui.TextLabel.Text = 'Script is nil-parented; copied getNil fallback'
    else
        ui.TextLabel.Text = 'Script path copied!'
    end
end)

--[[newButton(
        "returnvalue",
        function() return "Get a Remote's return data" end,
        function()
            if selected then
                local Remote = selected.Remote
                if Remote and Remote:IsA("RemoteFunction") then
                    if selected.returnvalue and selected.returnvalue.data then
                        return codebox:setRaw(v2s(selected.returnvalue.data))
                    end
                    return codebox:setRaw("No data was returned")
                else
                    codebox:setRaw("RemoteFunction expected got "..(Remote and Remote.ClassName))
                end
            end
        end
    )]]

newButton('Disable Info', function()
    return string.format(
        '[%s] Toggle function info (because it can cause lag in some games)',
        configs.funcEnabled and 'ENABLED' or 'DISABLED'
    )
end, function()
    configs.funcEnabled = not configs.funcEnabled
    ui.TextLabel.Text = string.format(
        '[%s] Toggle function info (because it can cause lag in some games)',
        configs.funcEnabled and 'ENABLED' or 'DISABLED'
    )
end)

newButton('Autoblock', function()
    return string.format(
        '[%s] [BETA] Intelligently detects and excludes spammy remote calls from logs',
        configs.autoblock and 'ENABLED' or 'DISABLED'
    )
end, function()
    configs.autoblock = not configs.autoblock
    ui.TextLabel.Text = string.format(
        '[%s] [BETA] Intelligently detects and excludes spammy remote calls from logs',
        configs.autoblock and 'ENABLED' or 'DISABLED'
    )
    history = {}
    excluding = {}
end)

if caps.checkCaller and caps.sendHooks then
    newButton('Logcheckcaller', function()
        return ('[%s] Log remotes fired by the client'):format(
            configs.logcheckcaller and 'ENABLED' or 'DISABLED'
        )
    end, function()
        configs.logcheckcaller = not configs.logcheckcaller
        ui.TextLabel.Text = ('[%s] Log remotes fired by the client'):format(
            configs.logcheckcaller and 'ENABLED' or 'DISABLED'
        )
    end)
end

--[[newButton("Log returnvalues",function()
    return ("[BETA] [%s] Log RemoteFunction's return values"):format(configs.logcheckcaller and "ENABLED" or "DISABLED")
end,
function()
    configs.logreturnvalues = not configs.logreturnvalues
    ui.TextLabel.Text = ("[BETA] [%s] Log RemoteFunction's return values"):format(configs.logreturnvalues and "ENABLED" or "DISABLED")
end)]]

newButton('Advanced Info', function()
    return ('[%s] Display more remoteinfo'):format(
        configs.advancedinfo and 'ENABLED' or 'DISABLED'
    )
end, function()
    configs.advancedinfo = not configs.advancedinfo
    ui.TextLabel.Text = ('[%s] Display more remoteinfo'):format(
        configs.advancedinfo and 'ENABLED' or 'DISABLED'
    )
end)

newButton('Buffer Dump', function()
    local state = (configs.bufferDumpComments and 'ON' or 'OFF')
    return ('[%s] Include hex preview comments for buffers'):format(state)
end, function()
    configs.bufferDumpComments = not configs.bufferDumpComments
    bufferDumpEnabled = configs.bufferDumpComments
    ui.TextLabel.Text = ('Buffer dump comments: %s'):format(
        configs.bufferDumpComments and 'ON' or 'OFF'
    )
end)

local pathModeNames = {
    [1] = ".Child",
    [2] = ":FindFirstChild()",
    [3] = ":WaitForChild()",
}

newButton('Path Mode', function()
    local mode = configs.pathMode or 1
    return ('Path style: %s'):format(pathModeNames[mode] or '?')
end, function()
    local mode = configs.pathMode or 1
    mode += 1
    if mode > 3 then
        mode = 1
    end
    configs.pathMode = mode
    ui.TextLabel.Text = ('Path style set to %s'):format(pathModeNames[mode])
end)

if configs.supersecretdevtoggle then
    newButton('Load SSV2.2', function()
        return "Load's Simple Spy V2.2"
    end, function()
        loadstring(
            game:HttpGet(
                'https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua'
            )
        )()
    end)
    newButton('Load SSV3', function()
        return "Load's Simple Spy V3"
    end, function()
        loadstring(
            game:HttpGet(
                'https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpySource.lua'
            )
        )()
    end)
    local SuperSecretFolder = Create('Folder', { Parent = ui.SimpleSpy3 })
    newButton('SUPER SECRET BUTTON', function()
        return 'You dont need a discription you already know what it does'
    end, function()
        SuperSecretFolder:ClearAllChildren()
        local random = listfiles('Music')
        local NotSound = Create('Sound', {
            Parent = SuperSecretFolder,
            Looped = false,
            Volume = math.random(1, 5),
            SoundId = getcustomasset(random[math.random(1, #random)]),
        })
        NotSound:Play()
    end)
end
