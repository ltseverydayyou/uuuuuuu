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
    log_Fire = true,
    log_Invoke = true,
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
        local rawmetatable = getrawmetatable(userdata)
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
    if getrenv then
        local ErrorPrompt = getrenv().require(
            CoreGui:WaitForChild('RobloxGui')
                :WaitForChild('Modules')
                :WaitForChild('ErrorPrompt')
        ) -- File can be located in your roblox folder (C:\Users\%Username%\AppData\Local\Roblox\Versions\whateverversionitis\ExtraContent\scripts\CoreScripts\Modules)
        local prompt = ErrorPrompt.new('Default', { HideErrorCode = true })
        local ErrorStoarge =
            Create('ScreenGui', { Parent = CoreGui, ResetOnSpawn = false })
        local thread = state and running()
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
        if thread then
            yield(thread)
        end
    else
        warn(Message)
    end
end

local Highlight = (
    isfile
    and loadfile
    and isfile('Highlight.lua')
    and loadfile('Highlight.lua')()
)
    or loadstring(
        game:HttpGet(
            'https://raw.githubusercontent.com/78n/SimpleSpy/main/Highlight.lua'
        )
    )()

local SimpleSpy3 = Create('ScreenGui', { ResetOnSpawn = false })
local Storage = Create('Folder', {})
local Background = Create('Frame', {
    Parent = SimpleSpy3,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 500, 0, 200),
    Size = UDim2.new(0, 450, 0, 268),
})
local LeftPanel = Create('Frame', {
    Parent = Background,
    BackgroundColor3 = Color3.fromRGB(53, 52, 55),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 19),
    Size = UDim2.new(0, 131, 0, 249),
})
local LogList = Create('ScrollingFrame', {
    Parent = LeftPanel,
    Active = true,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 9),
    Size = UDim2.new(0, 131, 0, 232),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 4,
})
local UIListLayout = Create('UIListLayout', {
    Parent = LogList,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
})
local RightPanel = Create('Frame', {
    Parent = Background,
    BackgroundColor3 = Color3.fromRGB(37, 36, 38),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 131, 0, 19),
    Size = UDim2.new(0, 319, 0, 249),
})
local CodeBox = Create('Frame', {
    Parent = RightPanel,
    BackgroundColor3 = Color3.new(0.0823529, 0.0745098, 0.0784314),
    BorderSizePixel = 0,
    Size = UDim2.new(0, 319, 0, 119),
})
local ScrollingFrame = Create('ScrollingFrame', {
    Parent = RightPanel,
    Active = true,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0.5, 0),
    Size = UDim2.new(1, 0, 0.5, -9),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 4,
})
local UIGridLayout = Create('UIGridLayout', {
    Parent = ScrollingFrame,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    CellPadding = UDim2.new(0, 0, 0, 0),
    CellSize = UDim2.new(0, 94, 0, 27),
})
local TopBar = Create('Frame', {
    Parent = Background,
    Active = true,
    BackgroundColor3 = Color3.fromRGB(37, 35, 38),
    BorderSizePixel = 0,
    Size = UDim2.new(0, 450, 0, 19),
})
local Simple = Create('TextButton', {
    Parent = TopBar,
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
local CloseButton = Create('TextButton', {
    Parent = TopBar,
    BackgroundColor3 = Color3.new(0.145098, 0.141176, 0.14902),
    BorderSizePixel = 0,
    Position = UDim2.new(1, -19, 0, 0),
    Size = UDim2.new(0, 19, 0, 19),
    Font = Enum.Font.SourceSans,
    Text = '',
    TextColor3 = Color3.new(0, 0, 0),
    TextSize = 14,
})
local ImageLabel = Create('ImageLabel', {
    Parent = CloseButton,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 5, 0, 5),
    Size = UDim2.new(0, 9, 0, 9),
    Image = 'http://www.roblox.com/asset/?id=5597086202',
})
local MaximizeButton = Create('TextButton', {
    Parent = TopBar,
    BackgroundColor3 = Color3.new(0.145098, 0.141176, 0.14902),
    BorderSizePixel = 0,
    Position = UDim2.new(1, -38, 0, 0),
    Size = UDim2.new(0, 19, 0, 19),
    Font = Enum.Font.SourceSans,
    Text = '',
    TextColor3 = Color3.new(0, 0, 0),
    TextSize = 14,
})
local ImageLabel_2 = Create('ImageLabel', {
    Parent = MaximizeButton,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 5, 0, 5),
    Size = UDim2.new(0, 9, 0, 9),
    Image = 'http://www.roblox.com/asset/?id=5597108117',
})
local MinimizeButton = Create('TextButton', {
    Parent = TopBar,
    BackgroundColor3 = Color3.new(0.145098, 0.141176, 0.14902),
    BorderSizePixel = 0,
    Position = UDim2.new(1, -57, 0, 0),
    Size = UDim2.new(0, 19, 0, 19),
    Font = Enum.Font.SourceSans,
    Text = '',
    TextColor3 = Color3.new(0, 0, 0),
    TextSize = 14,
})
local ImageLabel_3 = Create('ImageLabel', {
    Parent = MinimizeButton,
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 5, 0, 5),
    Size = UDim2.new(0, 9, 0, 9),
    Image = 'http://www.roblox.com/asset/?id=5597105827',
})
local nextb = Create('TextButton', {
    Parent = SimpleSpy3,
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
Create('UICorner', { Parent = nextb })
local ToolTip = Create('Frame', {
    Parent = SimpleSpy3,
    BackgroundColor3 = Color3.fromRGB(26, 26, 26),
    BackgroundTransparency = 0.1,
    BorderColor3 = Color3.new(1, 1, 1),
    Size = UDim2.new(0, 200, 0, 50),
    ZIndex = 3,
    Visible = false,
})
local TextLabel = Create('TextLabel', {
    Parent = ToolTip,
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

local remoteEvent = Instance.new('RemoteEvent', Storage)
local remoteFunction = Instance.new('RemoteFunction', Storage)
local originalBindableEventFire
local originalBindableFunctionInvoke
local NamecallHandler = Instance.new('BindableEvent', Storage)
local IndexHandler = Instance.new('BindableEvent', Storage)
local GetDebugIdHandler = Instance.new('BindableFunction', Storage) --Thanks engo for the idea of using BindableFunctions
local loggedClientEvent, wrappedClientInvoke = {}, {}
local _origClientInvoke = setmetatable({}, { __mode = 'k' })

local originalEvent = remoteEvent.FireServer
local originalFunction = remoteFunction.InvokeServer
local GetDebugIDInvoke = GetDebugIdHandler.Invoke

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
            writefile('SimpleSpy//Settings.json', jsone(realconfigs))
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

--- Scales the ToolTip to fit containing text
function scaleToolTip()
    local size = TextService:GetTextSize(
        TextLabel.Text,
        TextLabel.TextSize,
        TextLabel.Font,
        Vector2.new(196, math.huge)
    )
    TextLabel.Size = UDim2.new(0, size.X, 0, size.Y)
    ToolTip.Size = UDim2.new(0, size.X + 4, 0, size.Y + 4)
end

--- Executed when the toggle button (the SimpleSpy logo) is hovered over
function onToggleButtonHover()
    if not toggle then
        TweenService:Create(
            Simple,
            TweenInfo.new(0.5),
            { TextColor3 = Color3.fromRGB(252, 51, 51) }
        ):Play()
    else
        TweenService:Create(
            Simple,
            TweenInfo.new(0.5),
            { TextColor3 = Color3.fromRGB(68, 206, 91) }
        ):Play()
    end
end

--- Executed when the toggle button is unhovered over
function onToggleButtonUnhover()
    TweenService:Create(
        Simple,
        TweenInfo.new(0.5),
        { TextColor3 = Color3.fromRGB(255, 255, 255) }
    ):Play()
end

--- Executed when the X button is hovered over
function onXButtonHover()
    TweenService:Create(
        CloseButton,
        TweenInfo.new(0.2),
        { BackgroundColor3 = Color3.fromRGB(255, 60, 60) }
    ):Play()
end

--- Executed when the X button is unhovered over
function onXButtonUnhover()
    TweenService:Create(
        CloseButton,
        TweenInfo.new(0.2),
        { BackgroundColor3 = Color3.fromRGB(37, 36, 38) }
    ):Play()
end

--- Toggles the remote spy method (when button clicked)
function onToggleButtonClick()
    if toggle then
        TweenService:Create(
            Simple,
            TweenInfo.new(0.5),
            { TextColor3 = Color3.fromRGB(252, 51, 51) }
        ):Play()
    else
        TweenService:Create(
            Simple,
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
    local currentX = Background.AbsolutePosition.X
    local currentY = Background.AbsolutePosition.Y
    local viewportSize = SafeGetService('Workspace').CurrentCamera.ViewportSize
    if
        (currentX < 0)
        or (
            currentX
            > (
                viewportSize.X
                - (sideClosed and 131 or Background.AbsoluteSize.X)
            )
        )
    then
        if currentX < 0 then
            currentX = 0
        else
            currentX = viewportSize.X
                - (sideClosed and 131 or Background.AbsoluteSize.X)
        end
    end
    if
        (currentY < 0)
        or (
            currentY
            > (
                viewportSize.Y
                - (closed and 19 or Background.AbsoluteSize.Y)
                - GuiInset.Y
            )
        )
    then
        if currentY < 0 then
            currentY = 0
        else
            currentY = viewportSize.Y
                - (closed and 19 or Background.AbsoluteSize.Y)
                - GuiInset.Y
        end
    end
    TweenService.Create(
        TweenService,
        Background,
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
        local mainPos = Background.AbsolutePosition
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
                                > (viewportSize.X - (sideClosed and 131 or TopBar.AbsoluteSize.X))
                            and currentX > currentPos.X
                        )
                    then
                        if currentX < 0 then
                            currentX = 0
                        else
                            currentX = viewportSize.X
                                - (sideClosed and 131 or TopBar.AbsoluteSize.X)
                        end
                    end
                    if
                        (currentY < 0 and currentY < currentPos.Y)
                        or (
                            currentY
                                > (viewportSize.Y - (closed and 19 or Background.AbsoluteSize.Y) - GuiInset.Y)
                            and currentY > currentPos.Y
                        )
                    then
                        if currentY < 0 then
                            currentY = 0
                        else
                            currentY = viewportSize.Y
                                - (closed and 19 or Background.AbsoluteSize.Y)
                                - GuiInset.Y
                        end
                    end
                    currentPos = Vector2.new(currentX, currentY)
                    lastPos = newPos
                    TweenService.Create(
                        TweenService,
                        Background,
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
        LeftPanel.Visible = true
        remotesFadeIn = fadeOut(LeftPanel:GetDescendants())
        TweenService:Create(
            LeftPanel,
            TweenInfo.new(0.5),
            { Size = UDim2.new(0, 131, 0, 0) }
        ):Play()
        wait(0.5)
    else
        TweenService:Create(
            LeftPanel,
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
        rightFadeIn = fadeOut(RightPanel:GetDescendants())
        wait(0.5)
        minimizeSize(0.5)
        wait(0.5)
        RightPanel.Visible = false
    else
        if closed then
            toggleMinimize(true)
        end
        RightPanel.Visible = true
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
            UDim2.new(0, CodeBox.AbsoluteSize.X, 0, CodeBox.AbsoluteSize.Y)
        local prevPos = UDim2.new(
            0,
            CodeBox.AbsolutePosition.X,
            0,
            CodeBox.AbsolutePosition.Y
        )
        disable.Size = UDim2.new(1, 0, 1, 0)
        disable.BackgroundColor3 = Color3.new()
        disable.BorderSizePixel = 0
        disable.Text = 0
        disable.ZIndex = 3
        disable.BackgroundTransparency = 1
        disable.AutoButtonColor = false
        CodeBox.ZIndex = 4
        CodeBox.Position = prevPos
        CodeBox.Size = prevSize
        TweenService:Create(CodeBox, TweenInfo.new(0.5), {
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
                    >= CodeBox.AbsolutePosition.Y
                and UserInputService:GetMouseLocation().Y + GuiInset.Y <= CodeBox.AbsolutePosition.Y + CodeBox.AbsoluteSize.Y
                and UserInputService:GetMouseLocation().X >= CodeBox.AbsolutePosition.X
                and UserInputService:GetMouseLocation().X
                    <= CodeBox.AbsolutePosition.X + CodeBox.AbsoluteSize.X
            then
                return
            end
            TweenService:Create(
                CodeBox,
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
            CodeBox.Size = UDim2.new(1, 0, 0.5, 0)
            CodeBox.Position = UDim2.new(0, 0, 0, 0)
            CodeBox.ZIndex = 0
            maximized = false
        end)
    end
end

--- Checks if cursor is within resize range
--- @param p Vector2
function isInResizeRange(p)
    local relativeP = p - Background.AbsolutePosition
    local range = 5
    if
        relativeP.X >= TopBar.AbsoluteSize.X - range
        and relativeP.Y >= Background.AbsoluteSize.Y - range
        and relativeP.X <= TopBar.AbsoluteSize.X
        and relativeP.Y <= Background.AbsoluteSize.Y
    then
        return true, 'B'
    elseif
        relativeP.X >= TopBar.AbsoluteSize.X - range
        and relativeP.X <= Background.AbsoluteSize.X
    then
        return true, 'X'
    elseif
        relativeP.Y >= Background.AbsoluteSize.Y - range
        and relativeP.Y <= Background.AbsoluteSize.Y
    then
        return true, 'Y'
    end
    return false
end

--- Checks if cursor is within dragging range
--- @param p Vector2
function isInDragRange(p)
    local relativeP = p - Background.AbsolutePosition
    local topbarAS = TopBar.AbsoluteSize
    return relativeP.X <= topbarAS.X - CloseButton.AbsoluteSize.X * 3
            and relativeP.X >= 0
            and relativeP.Y <= topbarAS.Y
            and relativeP.Y >= 0
        or false
end

--- Called when mouse enters SimpleSpy
local customCursor = Create('ImageLabel', {
    Parent = SimpleSpy3,
    Visible = false,
    Size = UDim2.fromOffset(200, 200),
    ZIndex = 1e9,
    BackgroundTransparency = 1,
    Image = '',
    Parent = SimpleSpy3,
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
        and mousePos.X >= TopBar.AbsolutePosition.X
        and mousePos.X <= TopBar.AbsolutePosition.X + TopBar.AbsoluteSize.X
        and mousePos.Y >= Background.AbsolutePosition.Y
        and mousePos.Y
            <= Background.AbsolutePosition.Y + Background.AbsoluteSize.Y
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
    TweenService:Create(LeftPanel, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            LeftPanel.AbsoluteSize.X,
            Background.AbsoluteSize.Y - TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(RightPanel, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            Background.AbsoluteSize.X - LeftPanel.AbsoluteSize.X,
            Background.AbsoluteSize.Y - TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(TopBar, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            Background.AbsoluteSize.X,
            TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(ScrollingFrame, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            Background.AbsoluteSize.X - LeftPanel.AbsoluteSize.X,
            110
        ),
        Position = UDim2.fromOffset(
            0,
            Background.AbsoluteSize.Y - 119 - TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(CodeBox, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            Background.AbsoluteSize.X - LeftPanel.AbsoluteSize.X,
            Background.AbsoluteSize.Y - 119 - TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(LogList, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            LogList.AbsoluteSize.X,
            Background.AbsoluteSize.Y - TopBar.AbsoluteSize.Y - 18
        ),
    }):Play()
end

--- Adjusts the ui elements to close the side
function minimizeSize(speed)
    speed = speed or 0.05
    TweenService:Create(LeftPanel, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            LeftPanel.AbsoluteSize.X,
            Background.AbsoluteSize.Y - TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(RightPanel, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            0,
            Background.AbsoluteSize.Y - TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(TopBar, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            LeftPanel.AbsoluteSize.X,
            TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(ScrollingFrame, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(0, 119),
        Position = UDim2.fromOffset(
            0,
            Background.AbsoluteSize.Y - 119 - TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(CodeBox, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            0,
            Background.AbsoluteSize.Y - 119 - TopBar.AbsoluteSize.Y
        ),
    }):Play()
    TweenService:Create(LogList, TweenInfo.new(speed), {
        Size = UDim2.fromOffset(
            LogList.AbsoluteSize.X,
            Background.AbsoluteSize.Y - TopBar.AbsoluteSize.Y - 18
        ),
    }):Play()
end

--- Ensures size is within screensize limitations
function validateSize()
    local x, y = Background.AbsoluteSize.X, Background.AbsoluteSize.Y
    local screenSize = SafeGetService('Workspace').CurrentCamera.ViewportSize
    if x + Background.AbsolutePosition.X > screenSize.X then
        if screenSize.X - Background.AbsolutePosition.X >= 450 then
            x = screenSize.X - Background.AbsolutePosition.X
        else
            x = 450
        end
    elseif y + Background.AbsolutePosition.Y > screenSize.Y then
        if screenSize.X - Background.AbsolutePosition.Y >= 268 then
            y = screenSize.Y - Background.AbsolutePosition.Y
        else
            y = 268
        end
    end
    Background.Size = UDim2.fromOffset(x, y)
end

--- Called on user input while mouse in 'Background' frame
--- @param input InputObject
function backgroundUserInput(input)
    local mousePos = UserInputService:GetMouseLocation() - GuiInset
    local inResizeRange, type = isInResizeRange(mousePos)
    if
        input.UserInputType == Enum.UserInputType.MouseButton1
        and inResizeRange
    then
        local lastPos = UserInputService:GetMouseLocation()
        local offset = Background.AbsoluteSize - lastPos
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
                        Background.Size = UDim2.fromOffset(
                            (
                                not sideClosed
                                and not closed
                                and (type == 'X' or type == 'B')
                            )
                                    and currentPos.X
                                or Background.AbsoluteSize.X,
                            (--[[(not sideClosed or currentPos.X <= LeftPanel.AbsolutePosition.X + LeftPanel.AbsoluteSize.X) and]]not closed and (type == 'Y' or type == 'B'))
                                    and currentPos.Y
                                or Background.AbsoluteSize.Y
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
    ScrollingFrame.CanvasSize = UDim2.fromOffset(
        UIGridLayout.AbsoluteContentSize.X,
        UIGridLayout.AbsoluteContentSize.Y
    )
end

--- Updates the canvas size to fit the amount of current remotes
function updateRemoteCanvas()
    LogList.CanvasSize = UDim2.fromOffset(
        UIListLayout.AbsoluteContentSize.X,
        UIListLayout.AbsoluteContentSize.Y
    )
end

--- Allows for toggling of the tooltip and easy setting of le description
--- @param enable boolean
--- @param text string
function makeToolTip(enable, text)
    if enable and text then
        if ToolTip.Visible then
            ToolTip.Visible = false
            local tooltip = connections['ToolTip']
            if tooltip then
                tooltip:Disconnect()
            end
        end
        local first = true
        connections['ToolTip'] = RunService.RenderStepped:Connect(function()
            local MousePos = UserInputService:GetMouseLocation()
            local topLeft = MousePos + Vector2.new(20, -15)
            local bottomRight = topLeft + ToolTip.AbsoluteSize
            local ViewportSize =
                SafeGetService('Workspace').CurrentCamera.ViewportSize
            local ViewportSizeX = ViewportSize.X
            local ViewportSizeY = ViewportSize.Y

            if topLeft.X < 0 then
                topLeft = Vector2.new(0, topLeft.Y)
            elseif bottomRight.X > ViewportSizeX then
                topLeft = Vector2.new(
                    ViewportSizeX - ToolTip.AbsoluteSize.X,
                    topLeft.Y
                )
            end
            if topLeft.Y < 0 then
                topLeft = Vector2.new(topLeft.X, 0)
            elseif bottomRight.Y > ViewportSizeY - 35 then
                topLeft = Vector2.new(
                    topLeft.X,
                    ViewportSizeY - ToolTip.AbsoluteSize.Y - 35
                )
            end
            if topLeft.X <= MousePos.X and topLeft.Y <= MousePos.Y then
                topLeft = Vector2.new(
                    MousePos.X - ToolTip.AbsoluteSize.X - 2,
                    MousePos.Y - ToolTip.AbsoluteSize.Y - 2
                )
            end
            if first then
                ToolTip.Position = UDim2.fromOffset(topLeft.X, topLeft.Y)
                first = false
            else
                ToolTip:TweenPosition(
                    UDim2.fromOffset(topLeft.X, topLeft.Y),
                    'Out',
                    'Linear',
                    0.1
                )
            end
        end)
        TextLabel.Text = text
        TextLabel.TextScaled = true
        ToolTip.Visible = true
        return
    else
        if ToolTip.Visible then
            ToolTip.Visible = false
            local tooltip = connections['ToolTip']
            if tooltip then
                tooltip:Disconnect()
            end
        end
    end
end

--- Creates new function button (below codebox)
--- @param name string
---@param description function
---@param onClick function
function newButton(name, description, onClick)
    local FunctionTemplate = Create('Frame', {
        Name = 'FunctionTemplate',
        Parent = ScrollingFrame,
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
    local r, m = data.remote, string.lower(data.method or '')
    if r:IsA('RemoteEvent') and m == 'fireserver' then
        return Color3.fromRGB(255, 242, 0)
    end
    if r:IsA('RemoteFunction') and m == 'invokeserver' then
        return Color3.fromRGB(99, 86, 245)
    end
    if m == 'onclientevent' then
        return Color3.fromRGB(0, 200, 255)
    end
    if m == 'onclientinvoke' then
        return Color3.fromRGB(110, 230, 160)
    end
    if r:IsA('BindableEvent') and m == 'fire' then
        return Color3.fromRGB(255, 170, 0)
    end
    if r:IsA('BindableFunction') and m == 'invoke' then
        return Color3.fromRGB(0, 200, 200)
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

local function selectCall(log, idx)
    local c = log.calls[idx]
    if not c then
        return
    end
    log.selectedIdx = idx
    log.args = deepclone(c.args or {})
    log.method = (c.method or log.method or ''):lower()
    selected = log
    local g = genScript(log.Remote, log.args, log.method)
    log.GenScript = g
    codebox:setRaw(g)
end

function newRemote(type, data)
    if layoutOrderNum < 1 then
        layoutOrderNum = 999999999
    end
    local remote = data.remote
    local rid = data.id or OldDebugId(remote)

    local existing = logsById[rid]
    if existing then
        local uiAlive = existing.Log
            and existing.Log.Parent
            and existing.CallsList
            and existing.CallsList.Parent
        if not uiAlive then
            logsById[rid] = nil
            existing = nil
        end
    end

    local function rowColor()
        local m = tostring(data.method or ''):lower()
        if remote:IsA('RemoteEvent') then
            return (m == 'onclientevent') and Color3.fromRGB(0, 200, 255)
                or Color3.fromRGB(255, 208, 0)
        elseif remote:IsA('RemoteFunction') then
            return (m == 'onclientinvoke') and Color3.fromRGB(110, 230, 160)
                or Color3.fromRGB(99, 86, 245)
        elseif remote:IsA('BindableEvent') then
            return Color3.fromRGB(255, 170, 0)
        elseif remote:IsA('BindableFunction') then
            return Color3.fromRGB(0, 200, 200)
        end
        return Color3.fromRGB(200, 200, 200)
    end

    local existing = logsById[rid]
    if existing then
        existing.Count += 1
        existing.CountLabel.Text = ('x%d'):format(existing.Count)
        existing.CountLabel.Visible = true

        local idx = #existing.calls + 1
        table.insert(existing.calls, {
            time = os.date('%H:%M:%S'),
            args = deepclone(data.args),
            method = tostring(data.method or ''):lower(),
        })

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
        Parent = LogList,
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
        TextSize = 14,
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
    logsById[rid] = log

    local idx1 = 1
    table.insert(log.calls, {
        time = os.date('%H:%M:%S'),
        args = deepclone(data.args),
        method = tostring(data.method or ''):lower(),
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
    method = tostring(method or ''):lower()
    prevTables = {}
    local gen = ''
    if #args > 0 then
        xpcall(function()
            gen = v2v({ args = args }) .. '\n'
        end, function(err)
            -- Fallback: just note the failure and keep going
            gen = (gen or '')
                .. ('-- TableToString failure: %s\n'):format(tostring(err))
        end)

        if not remote:IsDescendantOf(game) and not getnilrequired then
            gen = 'function getNil(name,class) ... end\n\n' .. gen
        end

        if remote:IsA('RemoteEvent') then
            if method == 'onclientevent' then
                gen ..= (firesignal and ('firesignal(' .. v2s(remote) .. '.OnClientEvent, unpack(args))') or '-- firesignal not available')
            else
                gen ..= v2s(remote) .. ':FireServer(unpack(args))'
            end
        elseif remote:IsA('RemoteFunction') then
            if method == 'onclientinvoke' then
                gen ..= v2s(remote) .. '.OnClientInvoke = function(...)\n\treturn --[[ your return here ]]\nend\n\n'
                gen ..= '-- cannot “invoke” client callback directly from here'
            else
                gen ..= v2s(remote) .. ':InvokeServer(unpack(args))'
            end
        elseif remote:IsA('BindableEvent') then
            gen ..= v2s(remote) .. ':Fire(unpack(args))'
        elseif remote:IsA('BindableFunction') then
            gen ..= v2s(remote) .. ':Invoke(unpack(args))'
        end
    else
        if remote:IsA('RemoteEvent') then
            gen ..= (method == 'onclientevent') and ((firesignal and ('firesignal(' .. v2s(
                remote
            ) .. '.OnClientEvent)')) or '-- firesignal not available') or (v2s(
                remote
            ) .. ':FireServer()')
        elseif remote:IsA('RemoteFunction') then
            gen ..= (method == 'onclientinvoke') and (v2s(remote) .. '.OnClientInvoke = function() return end') or (v2s(
                remote
            ) .. ':InvokeServer()')
        elseif remote:IsA('BindableEvent') then
            gen ..= v2s(remote) .. ':Fire()'
        elseif remote:IsA('BindableFunction') then
            gen ..= v2s(remote) .. ':Invoke()'
        end
    end
    prevTables = {}
    return gen
end

local function logClientEvent(re: RemoteEvent)
    if loggedClientEvent[re] then
        return
    end
    loggedClientEvent[re] = true
    re.OnClientEvent:Connect(function(...)
        schedule(remoteHandler, {
            method = 'onclientevent',
            remote = re,
            args = deepclone({ ... }),
            metamethod = 'signal',
            id = ThreadGetDebugId(re),
        })
    end)
end

local function wrapClientInvoke(rf)
    if wrappedClientInvoke[rf] then
        return
    end
    wrappedClientInvoke[rf] = true

    if getcallbackmember then
        local f = getcallbackmember(rf, 'OnClientInvoke')
        if type(f) == 'function' and _origClientInvoke[rf] ~= f then
            _origClientInvoke[rf] = f
            rf.OnClientInvoke = f
        end
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
    buffer = function(u)
        return buffer_literal(u)
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
            if getrawmetatable(v) then
                return 'newproxy(true)'
            end
            return 'newproxy(false)'
        end
        return 'newproxy(true)'
    end,
}

local typev2sfunctions = {
    userdata = function(v, vtypeof)
        if is_buffer(v) then
            return buffer_literal(v)
        end
        if ufunctions[vtypeof] then
            return ufunctions[vtypeof](v)
        end
        return `{vtypeof}({rawtostring(v)}) --[[Generation Failure]]`
    end,
    vector = ufunctions['Vector3'],
}

function v2s(v, l, p, n, vtv, i, pt, path, tables, tI)
    if is_buffer(v) then
        return buffer_literal(v)
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
        return vtypefunc(v, vtypeof)
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
function i2p(i, customgen)
    if customgen then
        return customgen
    end
    local player = getplayer(i)
    local parent = i
    local out = ''
    if parent == nil then
        return 'nil'
    elseif player then
        while true do
            if parent and parent == player.Character then
                if player == Players.LocalPlayer then
                    return 'game:GetService("Players").LocalPlayer.Character'
                        .. out
                else
                    return i2p(player) .. '.Character' .. out
                end
            else
                if parent.Name:match('[%a_]+[%w+]*') ~= parent.Name then
                    out = ':FindFirstChild('
                        .. formatstr(parent.Name)
                        .. ')'
                        .. out
                else
                    out = '.' .. parent.Name .. out
                end
            end
            task.wait()
            parent = parent.Parent
        end
    elseif parent ~= game then
        while true do
            if parent and parent.Parent == game then
                if game:FindService(parent.ClassName) then -- You arent getting clout off of this
                    if lower(parent.ClassName) == 'workspace' then
                        return `workspace{out}`
                    else
                        return 'game:GetService("'
                            .. parent.ClassName
                            .. '")'
                            .. out
                    end
                else
                    if parent.Name:match('[%a_]+[%w_]*') then
                        return 'game.' .. parent.Name .. out
                    else
                        return 'game:FindFirstChild('
                            .. formatstr(parent.Name)
                            .. ')'
                            .. out
                    end
                end
            elseif not parent.Parent then
                getnilrequired = true
                return 'getNil('
                    .. formatstr(parent.Name)
                    .. ', "'
                    .. parent.ClassName
                    .. '")'
                    .. out
            else
                if parent.Name:match('[%a_]+[%w_]*') ~= parent.Name then
                    out = ':WaitForChild('
                        .. formatstr(parent.Name)
                        .. ')'
                        .. out
                else
                    out = ':WaitForChild("' .. parent.Name .. '")' .. out
                end
            end
            if i:IsDescendantOf(Players.LocalPlayer) then
                return 'game:GetService("Players").LocalPlayer' .. out
            end
            parent = parent.Parent
            task.wait()
        end
    else
        return 'game'
    end
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
function formatstr(s, indentation)
    if not indentation then
        indentation = 0
    end
    local handled, reachedMax = handlespecials(s, indentation)
    return '"'
        .. handled
        .. '"'
        .. (
            reachedMax
                and " --[[ MAXIMUM STRING SIZE REACHED, CHANGE 'getgenv().SimpleSpyMaxStringSize' TO ADJUST MAXIMUM SIZE ]]"
            or ''
        )
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

function buffer_literal(u)
    local ok, s = pcall(buffer.tostring, u)
    if ok and type(s) == 'string' then
        return 'buffer.fromstring(' .. formatstr(s) .. ')'
    end
    local n = 0
    pcall(function()
        n = buffer.len(u)
    end)
    return ('buffer.fromstring("") --[[Generation Failure: unreadable buffer (len=%d)]]'):format(
        n
    )
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
    if #scheduled > SIMPLESPYCONFIG_MaxRemotes + 100 then
        table.remove(scheduled, #scheduled)
    end
    if #scheduled > 0 then
        local currentf = scheduled[1]
        table.remove(scheduled, 1)
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
        if not history[id] then
            history[id] = { badOccurances = 0, lastCall = tick() }
        end
        if tick() - history[id].lastCall < 1 then
            history[id].badOccurances += 1
            return
        else
            history[id].badOccurances = 0
        end
        if history[id].badOccurances > 3 then
            excluding[id] = true
            return
        end
        history[id].lastCall = tick()
    end
    newRemote(
        (
            data.remote:IsA('RemoteFunction')
            or data.remote:IsA('BindableFunction')
        )
                and 'function'
            or 'event',
        data
    )
end

local newindex = function(method, originalfunction, self, ...)
    if typeof(self) == 'Instance' then
        local remote = cloneref(self)
        if remote:IsA('RemoteEvent') or remote:IsA('RemoteFunction') then
            if not configs.logcheckcaller and checkcaller() then
                return nil -- let wrapper forward
            end
            local id = ThreadGetDebugId(remote)
            local blockcheck = tablecheck(blocklist, remote, id)
            local args = { ... }

            if
                not tablecheck(blacklist, remote, id)
                and not IsCyclicTable(args)
            then
                local data = {
                    method = method,
                    remote = remote,
                    args = deepclone(args),
                    infofunc = info(2, 'f'),
                    callingscript = getcallingscript()
                            and cloneref(getcallingscript())
                        or nil,
                    metamethod = '__index',
                    blockcheck = blockcheck,
                    id = id,
                    returnvalue = {},
                }
                schedule(remoteHandler, data)
            end

            if blockcheck then
                return false -- signal “blocked”
            end
            return nil -- signal “not blocked”
        end
    end

    return nil -- non-remote path; wrapper will just call original
end

local function call_original_namecall(method, self, ...)
    if setnamecallmethod then
        setnamecallmethod(method)
    end
    return originalnamecall(self, ...)
end

local newnamecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if
        method
        and (
            method == 'FireServer'
            or method == 'fireServer'
            or method == 'InvokeServer'
            or method == 'invokeServer'
            or method == 'Fire'
            or method == 'fire'
            or method == 'Invoke'
            or method == 'invoke'
        )
    then
        if
            typeof(self) == 'Instance'
            and (
                self:IsA('RemoteEvent')
                or self:IsA('RemoteFunction')
                or self:IsA('BindableEvent')
                or self:IsA('BindableFunction')
            )
        then
            -- let client-fired calls pass through when you disabled logging them
            if not configs.logcheckcaller and checkcaller() then
                return call_original_namecall(method, self, ...)
            end

            local id = ThreadGetDebugId(self)
            local blockcheck = tablecheck(blocklist, self, id)
            local args = { ... }

            if
                not tablecheck(blacklist, self, id) and not IsCyclicTable(args)
            then
                local data = {
                    method = method,
                    remote = self,
                    args = deepclone(args),
                    infofunc = info(2, 'f'),
                    callingscript = getcallingscript()
                            and cloneref(getcallingscript())
                        or nil,
                    metamethod = '__namecall',
                    blockcheck = blockcheck,
                    id = id,
                    returnvalue = {},
                }
                schedule(remoteHandler, data)
            end

            -- if blocked: swallow; otherwise immediately forward
            if blockcheck then
                -- (Optional) quick visual so you can see it really *was* blocked by name/id:
                -- warn("[SimpleSpy] Blocked remote:", self.Name, id)
                return
            end

            return call_original_namecall(method, self, unpack(args))
        end
    end

    -- non-remote (or non-matching method) → pass through
    return originalnamecall(self, ...)
end)

local newFireServer = newcclosure(function(self, ...)
    local res = newindex('FireServer', originalEvent, self, ...)
    if res ~= nil then
        return res
    end -- if newindex chose to return (blocked), respect it
    return originalEvent(self, ...)
end)

local newInvokeServer = newcclosure(function(self, ...)
    local res = newindex('InvokeServer', originalFunction, self, ...)
    if res ~= nil then
        return res
    end
    return originalFunction(self, ...)
end)

local newFireBindable = newcclosure(function(self, ...)
    local res = newindex('Fire', originalBindableEventFire, self, ...)
    if res ~= nil then
        return res
    end
    return originalBindableEventFire(self, ...)
end)

local newInvokeBindable = newcclosure(function(self, ...)
    local res = newindex('Invoke', originalBindableFunctionInvoke, self, ...)
    if res ~= nil then
        return res
    end
    return originalBindableFunctionInvoke(self, ...)
end)

local function disablehooks()
    if synv3 then
        unhook(getrawmetatable(game).__namecall, originalnamecall)
        unhook(Instance.new('RemoteEvent').FireServer, originalEvent)
        unhook(Instance.new('RemoteFunction').InvokeServer, originalFunction)
        unhook(Instance.new('BindableEvent').Fire, originalBindableEventFire)
        unhook(
            Instance.new('BindableFunction').Invoke,
            originalBindableFunctionInvoke
        )
        restorefunction(originalnamecall)
        restorefunction(originalEvent)
        restorefunction(originalFunction)
        restorefunction(originalBindableEventFire)
        restorefunction(originalBindableFunctionInvoke)
    else
        if hookmetamethod then
            hookmetamethod(game, '__namecall', originalnamecall)
        else
            hookfunction(getrawmetatable(game).__namecall, originalnamecall)
        end
        hookfunction(Instance.new('RemoteEvent').FireServer, originalEvent)
        hookfunction(
            Instance.new('RemoteFunction').InvokeServer,
            originalFunction
        )
        hookfunction(
            Instance.new('BindableEvent').Fire,
            originalBindableEventFire
        )
        hookfunction(
            Instance.new('BindableFunction').Invoke,
            originalBindableFunctionInvoke
        )
    end
end

--- Toggles on and off the remote spy
function toggleSpy()
    if not toggle then
        local oldnamecall
        if synv3 then
            oldnamecall = hook(
                getrawmetatable(game).__namecall,
                clonefunction(newnamecall)
            )
            originalEvent = hook(
                Instance.new('RemoteEvent').FireServer,
                clonefunction(newFireServer)
            )
            originalFunction = hook(
                Instance.new('RemoteFunction').InvokeServer,
                clonefunction(newInvokeServer)
            )
            originalBindableEventFire = hook(
                Instance.new('BindableEvent').Fire,
                clonefunction(newFireBindable)
            )
            originalBindableFunctionInvoke = hook(
                Instance.new('BindableFunction').Invoke,
                clonefunction(newInvokeBindable)
            )
        else
            if hookmetamethod then
                oldnamecall = hookmetamethod(
                    game,
                    '__namecall',
                    clonefunction(newnamecall)
                )
            else
                oldnamecall = hookfunction(
                    getrawmetatable(game).__namecall,
                    clonefunction(newnamecall)
                )
            end
            originalEvent = hookfunction(
                Instance.new('RemoteEvent').FireServer,
                clonefunction(newFireServer)
            )
            originalFunction = hookfunction(
                Instance.new('RemoteFunction').InvokeServer,
                clonefunction(newInvokeServer)
            )
            originalBindableEventFire = hookfunction(
                Instance.new('BindableEvent').Fire,
                clonefunction(newFireBindable)
            )
            originalBindableFunctionInvoke = hookfunction(
                Instance.new('BindableFunction').Invoke,
                clonefunction(newInvokeBindable)
            )
        end
        originalnamecall = originalnamecall
            or function(...)
                return oldnamecall(...)
            end
    else
        disablehooks()
    end
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
    SimpleSpy3:Destroy()
    Storage:Destroy()
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
        if not hookmetamethod then
            ErrorPrompt(
                "Simple Spy V3 will not function to it's fullest capablity due to your executor not supporting hookmetamethod.",
                true
            )
        end
        codebox = Highlight.new(CodeBox)
        logthread(spawn(function()
            local suc, err = pcall(
                game.HttpGet,
                game,
                'https://raw.githubusercontent.com/78n/SimpleSpy/main/UpdateLog.lua'
            )
            codebox:setRaw((suc and err) or '')
        end))
        getgenv().SimpleSpy = SimpleSpy
        getgenv().getNil = function(name, class)
            for _, v in next, getnilinstances() do
                if v.ClassName == class and v.Name == name then
                    return v
                end
            end
        end
        Background.MouseEnter:Connect(function(...)
            mouseInGui = true
            mouseEntered()
        end)
        Background.MouseLeave:Connect(function(...)
            mouseInGui = false
            mouseEntered()
        end)
        TextLabel:GetPropertyChangedSignal('Text'):Connect(scaleToolTip)
        -- TopBar.InputBegan:Connect(onBarInput)
        MinimizeButton.MouseButton1Click:Connect(toggleMinimize)
        MaximizeButton.MouseButton1Click:Connect(toggleSideTray)
        Simple.MouseButton1Click:Connect(onToggleButtonClick)
        CloseButton.MouseEnter:Connect(onXButtonHover)
        CloseButton.MouseLeave:Connect(onXButtonUnhover)
        Simple.MouseEnter:Connect(onToggleButtonHover)
        Simple.MouseLeave:Connect(onToggleButtonUnhover)
        CloseButton.MouseButton1Click:Connect(shutdown)
        table.insert(
            connections,
            UserInputService.InputBegan:Connect(backgroundUserInput)
        )
        connectResize()
        SimpleSpy3.Enabled = true
        logthread(spawn(function()
            delay(1, onToggleButtonUnhover)
        end))
        schedulerconnect = RunService.Heartbeat:Connect(taskscheduler)
        bringBackOnResize()
        protectUI(SimpleSpy3)
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
    SimpleSpy3:Destroy()
    return
end

local oldNewIndex
oldNewIndex = hookmetamethod(game, '__newindex', function(self, k, v)
    if
        not checkcaller()
        and typeof(self) == 'Instance'
        and self:IsA('RemoteFunction')
        and k == 'OnClientInvoke'
        and type(v) == 'function'
    then
        local rf = self
        _origClientInvoke[rf] = v

        local function wrapped(...)
            local args = { ... }
            schedule(remoteHandler, {
                method = 'OnClientInvoke',
                remote = rf,
                args = deepclone(args),
                metamethod = 'callback',
                id = ThreadGetDebugId(rf),
            })
            return v(...)
        end
        return oldNewIndex(self, k, wrapped)
    end
    return oldNewIndex(self, k, v)
end)

for _, inst in ipairs(game:GetDescendants()) do
    if inst:IsA('RemoteEvent') then
        logClientEvent(inst)
    end
    if inst:IsA('RemoteFunction') then
        wrapClientInvoke(inst)
    end
end
game.DescendantAdded:Connect(function(inst)
    if inst:IsA('RemoteEvent') then
        logClientEvent(inst)
    end
    if inst:IsA('RemoteFunction') then
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
                GenScript: (string) The generated script that appears in the codebox (generated when namecall fired)
                Source: (Instance (LocalScript)) The script that fired/invoked the remote
                Remote: (Instance (RemoteEvent) | Instance (RemoteFunction)) The remote that was fired/invoked
                Log: (Instance (TextButton)) The button being used for the remote (same as 'selected.Log')
            }
        - globals list: (contact @exx#9394 for more information or if you have suggestions for more to be added)
            - closed: (boolean) whether or not the GUI is currently minimized
            - logs: (table[remoteFrame]) full of remoteFrame objects (properties listed above)
            - selected: (remoteFrame) the currently selected remoteFrame (properties listed above)
            - blacklist: (string[] | Instance[] (RemoteEvent) | Instance[] (RemoteFunction)) an array of blacklisted names and remotes
            - codebox: (Instance (TextBox)) the textbox that holds all the code- cleared often
]]

do
    nextb.MouseButton1Click:Connect(function()
        Background.Visible = not Background.Visible
        nextb.Text = Background.Visible and '-' or '+'
    end)
    nextb.InputBegan:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            local lastPos = UserInputService:GetMouseLocation()
            local startPos = nextb.AbsolutePosition
            if not connections['dragNextb'] then
                connections['dragNextb'] = RunService.RenderStepped:Connect(
                    function()
                        local newPos = UserInputService:GetMouseLocation()
                        if newPos ~= lastPos then
                            local dx, dy =
                                newPos.X - lastPos.X, newPos.Y - lastPos.Y
                            startPos = startPos + Vector2.new(dx, dy)
                            nextb.Position =
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

-- Copies the contents of the codebox
newButton('Copy Code', function()
    return 'Click to copy code'
end, function()
    setclipboard(codebox:getString())
    TextLabel.Text = 'Copied successfully!'
end)

--- Copies the source script (that fired the remote)
newButton('Copy Remote', function()
    return 'Click to copy the path of the remote'
end, function()
    if selected and selected.Remote then
        setclipboard(v2s(selected.Remote))
        TextLabel.Text = 'Copied!'
    end
end)

-- Executes the contents of the codebox through loadstring
newButton('Run Code', function()
    return 'Click to execute code'
end, function()
    local log = selected
    if not (log and log.Remote) then
        TextLabel.Text = 'No selection'
        return
    end

    local obj = log.Remote
    local m = tostring(log.method or ''):lower()
    local last = log.calls and log.calls[#log.calls]
    local args = (last and last.args) or log.args or {}

    local ok, err = pcall(function()
        if m == 'onclientevent' then
            -- strictly trigger the client event; no connects, no prints
            if firesignal then
                firesignal(obj.OnClientEvent, unpack(args))
                TextLabel.Text = 'Fired (OnClientEvent)'
            else
                TextLabel.Text = 'firesignal missing'
            end
            return
        end

        if m == 'onclientinvoke' then
            -- directly call the currently bound client callback if present
            local f = obj.OnClientInvoke
            if type(f) == 'function' then
                f(unpack(args)) -- no printing, no capturing
                TextLabel.Text = 'Called (OnClientInvoke)'
            else
                TextLabel.Text = 'No OnClientInvoke bound'
            end
            return
        end

        -- normal remotes/bindables
        if obj:IsA('RemoteEvent') and (m == 'fireserver' or m == '') then
            obj:FireServer(unpack(args))
            TextLabel.Text = 'Fired (FireServer)'
            return
        end
        if obj:IsA('RemoteFunction') and (m == 'invokeserver' or m == '') then
            obj:InvokeServer(unpack(args)) -- ignore return; no prints
            TextLabel.Text = 'Called (InvokeServer)'
            return
        end
        if obj:IsA('BindableEvent') and (m == 'fire' or m == '') then
            obj:Fire(unpack(args))
            TextLabel.Text = 'Fired (Bindable:Fire)'
            return
        end
        if obj:IsA('BindableFunction') and (m == 'invoke' or m == '') then
            obj:Invoke(unpack(args)) -- ignore return
            TextLabel.Text = 'Called (Bindable:Invoke)'
            return
        end

        TextLabel.Text = ('Unsupported: %s / %s'):format(
            obj.ClassName,
            tostring(log.method)
        )
    end)

    if not ok then
        TextLabel.Text = ('Execution error: %s'):format(err)
    end
end)

newButton('Log FireServer', function()
    return ('[%s] FireServer'):format(configs.log_FireServer and 'ON' or 'OFF')
end, function()
    configs.log_FireServer = not configs.log_FireServer
    TextLabel.Text = ('FireServer: %s'):format(
        configs.log_FireServer and 'ON' or 'OFF'
    )
end)

newButton('Log InvokeServer', function()
    return ('[%s] InvokeServer'):format(
        configs.log_InvokeServer and 'ON' or 'OFF'
    )
end, function()
    configs.log_InvokeServer = not configs.log_InvokeServer
    TextLabel.Text = ('InvokeServer: %s'):format(
        configs.log_InvokeServer and 'ON' or 'OFF'
    )
end)

newButton('Log Fire', function()
    return ('[%s] Bindable:Fire'):format(configs.log_Fire and 'ON' or 'OFF')
end, function()
    configs.log_Fire = not configs.log_Fire
    TextLabel.Text = ('Bindable Fire: %s'):format(
        configs.log_Fire and 'ON' or 'OFF'
    )
end)

newButton('Log Invoke', function()
    return ('[%s] Bindable:Invoke'):format(configs.log_Invoke and 'ON' or 'OFF')
end, function()
    configs.log_Invoke = not configs.log_Invoke
    TextLabel.Text = ('Bindable Invoke: %s'):format(
        configs.log_Invoke and 'ON' or 'OFF'
    )
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
        TextLabel.Text = 'Done!'
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
                    info['advancedinfo']['OnClientInvoke'] = getcallbackmember
                            and (getcallbackmember(Remote, 'OnClientInvoke') or 'N/A')
                        or 'N/A --Missing function getcallbackmember'
                elseif getconnections then
                    info['advancedinfo']['OnClientEvents'] = {}

                    for i, v in next, getconnections(Remote.OnClientEvent) do
                        info['advancedinfo']['OnClientEvents'][i] = {
                            Function = v.Function or 'N/A',
                            State = v.State or 'N/A',
                        }
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
        TextLabel.Text =
            'Done! Function info generated by the SimpleSpy V3 Serializer.'
    else
        TextLabel.Text = 'Error! Selected function was not found.'
    end
end)

--- Clears the Remote logs
newButton('Clr Logs', function()
    return 'Click to clear logs'
end, function()
    TextLabel.Text = 'Clearing...'

    table.clear(logs)
    logsById = {}
    remoteLogs = {}

    for _, v in next, LogList:GetChildren() do
        if not v:IsA('UIListLayout') then
            v:Destroy()
        end
    end

    codebox:setRaw('')
    selected = nil
    TextLabel.Text = 'Logs cleared!'
end)

--- Excludes the selected.Log Remote from the RemoteSpy
newButton('Exclude (i)', function()
    return 'Click to exclude this Remote.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable.'
end, function()
    if selected then
        blacklist[OldDebugId(selected.Remote)] = true
        TextLabel.Text = 'Excluded!'
    end
end)

--- Excludes all Remotes that share the same name as the selected.Log remote from the RemoteSpy
newButton('Exclude (n)', function()
    return 'Click to exclude all remotes with this name.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable.'
end, function()
    if selected then
        blacklist[selected.Name] = true
        TextLabel.Text = 'Excluded!'
    end
end)

--- clears blacklist
newButton('Clr Blacklist', function()
    return 'Click to clear the blacklist.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable.'
end, function()
    blacklist = {}
    TextLabel.Text = 'Blacklist cleared!'
end)

--- Prevents the selected.Log Remote from firing the server (still logged)
newButton('Block (i)', function()
    return "Click to stop this remote from firing.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server."
end, function()
    if selected then
        blocklist[OldDebugId(selected.Remote)] = true
        TextLabel.Text = 'Excluded!'
    end
end)

--- Prevents all remotes from firing that share the same name as the selected.Log remote from the RemoteSpy (still logged)
newButton('Block (n)', function()
    return "Click to stop remotes with this name from firing.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server."
end, function()
    if selected then
        blocklist[selected.Name] = true
        TextLabel.Text = 'Excluded!'
    end
end)

--- clears blacklist
newButton('Clr Blocklist', function()
    return "Click to stop blocking remotes.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server."
end, function()
    blocklist = {}
    TextLabel.Text = 'Blocklist cleared!'
end)

--- Attempts to decompile the source script
newButton('Decompile', function()
    return 'Decompile source script'
end, function()
    if decompile then
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
            TextLabel.Text = 'Done!'
        else
            TextLabel.Text = 'Source not found!'
        end
    else
        TextLabel.Text = 'Missing function (decompile)'
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
    TextLabel.Text = string.format(
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
    TextLabel.Text = string.format(
        '[%s] [BETA] Intelligently detects and excludes spammy remote calls from logs',
        configs.autoblock and 'ENABLED' or 'DISABLED'
    )
    history = {}
    excluding = {}
end)

newButton('Logcheckcaller', function()
    return ('[%s] Log remotes fired by the client'):format(
        configs.logcheckcaller and 'ENABLED' or 'DISABLED'
    )
end, function()
    configs.logcheckcaller = not configs.logcheckcaller
    TextLabel.Text = ('[%s] Log remotes fired by the client'):format(
        configs.logcheckcaller and 'ENABLED' or 'DISABLED'
    )
end)

--[[newButton("Log returnvalues",function()
    return ("[BETA] [%s] Log RemoteFunction's return values"):format(configs.logcheckcaller and "ENABLED" or "DISABLED")
end,
function()
    configs.logreturnvalues = not configs.logreturnvalues
    TextLabel.Text = ("[BETA] [%s] Log RemoteFunction's return values"):format(configs.logreturnvalues and "ENABLED" or "DISABLED")
end)]]

newButton('Advanced Info', function()
    return ('[%s] Display more remoteinfo'):format(
        configs.advancedinfo and 'ENABLED' or 'DISABLED'
    )
end, function()
    configs.advancedinfo = not configs.advancedinfo
    TextLabel.Text = ('[%s] Display more remoteinfo'):format(
        configs.advancedinfo and 'ENABLED' or 'DISABLED'
    )
end)

newButton('Join Discord', function()
    return 'Joins The Simple Spy Discord'
end, function()
    setclipboard('https://discord.com/invite/AWS6ez9')
    TextLabel.Text = 'Copied invite to your clipboard'
    if request then
        request({
            Url = 'http://127.0.0.1:6463/rpc?v=1',
            Method = 'POST',
            Headers = {
                ['Content-Type'] = 'application/json',
                Origin = 'https://discord.com',
            },
            Body = http:JSONEncode({
                cmd = 'INVITE_BROWSER',
                nonce = http:GenerateGUID(false),
                args = { code = 'AWS6ez9' },
            }),
        })
    end
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
    local SuperSecretFolder = Create('Folder', { Parent = SimpleSpy3 })
    newButton('SUPER SECRET BUTTON', function()
        return 'You dont need a discription you already know what it does'
    end, function()
        SuperSecretFolder:ClearAllChildren()
        local random = listfiles('Music')
        local NotSound = Create('Sound', {
            Parent = SuperSecretFolder,
            Looped = false,
            Volume = math.random(1, 5),
            SoundId = getsynasset(random[math.random(1, #random)]),
        })
        NotSound:Play()
    end)
end