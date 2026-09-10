local Environment = if type(getgenv) == "function" then getgenv() else _G

local PreviousUnload = rawget(Environment, "DoorsVibeUIUnload")
if type(PreviousUnload) == "function" then
    pcall(PreviousUnload)
end
local PreviousScriptCleanup = rawget(Environment, "DoorsScriptCleanup")
if type(PreviousScriptCleanup) == "function" then
    pcall(PreviousScriptCleanup)
end

local function cleanupStaleVibeUI()
    local roots = {}
    local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        table.insert(roots,playerGui)
    end
    local ok,hui = pcall(function()
        if gethui then
            return gethui()
        end
        local coreGui = game:GetService("CoreGui")
        return cloneref and cloneref(coreGui) or coreGui
    end)
    if ok and hui then
        table.insert(roots,hui)
    end
    for _,root in ipairs(roots) do
        for _,child in ipairs(root:GetChildren()) do
            local displayOrder = child:IsA("ScreenGui") and child.DisplayOrder or nil
            if child:IsA("ScreenGui") and child.Name == ""
                and (displayOrder == 0 or displayOrder == 999 or displayOrder == 1000)
            then
                pcall(child.Destroy,child)
            end
        end
    end
end

cleanupStaleVibeUI()

local VibeUISource = game:HttpGet(
    "https://sirmemegithub.com/RealSlimShady2000/VibeUI/raw/branch/main/VibeUI.luau"
):gsub("\r\n", "\n")

local function replacePlainOnce(source, old, new)
    local startIndex, endIndex = string.find(source, old, 1, true)
    if not startIndex then
        return source, false
    end
    return string.sub(source, 1, startIndex - 1) .. new .. string.sub(source, endIndex + 1), true
end

local anchorCount
VibeUISource, anchorCount = VibeUISource:gsub(
    "LibMaid:GiveTask%(RunService%.RenderStepped:Connect%(function%(%)[\n]",
    "LibMaid:GiveTask(RunService.RenderStepped:Connect(function()\n\tif next(Anchors) == nil then return end\n",
    1
)
if anchorCount ~= 1 then
    error("VibeUI idle-loop compatibility patch failed")
end

local sharedTable = shared
local previousShared = sharedTable and rawget(sharedTable, "VibeUI") or nil
local previousEnvironment = rawget(Environment, "VibeUI")
if sharedTable then
    rawset(sharedTable, "VibeUI", nil)
end
rawset(Environment, "VibeUI", nil)

local chunk, compileError = loadstring(VibeUISource, "@VibeUI.lua")
if type(chunk) ~= "function" then
    error("VibeUI compile failed: " .. tostring(compileError))
end
local loaded, VibeUI = pcall(chunk)

if sharedTable then
    rawset(sharedTable, "VibeUI", previousShared)
end
rawset(Environment, "VibeUI", previousEnvironment)

if not loaded or type(VibeUI) ~= "table" then
    error("VibeUI load failed: " .. tostring(VibeUI))
end

local library = {}
local windows = {}
local nativeWindow

local function getNativeWindow()
    if nativeWindow then
        return nativeWindow
    end
    nativeWindow = VibeUI:Window({
        Title = "DOORS",
        Size = UDim2.fromOffset(560, 640),
        Keybind = Enum.KeyCode.RightShift,
        Layout = "Side",
        Resizable = true,
    })
    local settingsOk, settingsError = pcall(VibeUI.CreateSettingsPage, VibeUI, nativeWindow)
    if not settingsOk then
        error("VibeUI settings page failed: " .. tostring(settingsError))
    end
    table.insert(windows, nativeWindow)
    return nativeWindow
end

local function decimalPlaces(step)
    step = tonumber(step) or 1
    if step >= 1 then
        return 0
    end
    local places = 0
    while places < 4 and math.abs(step * (10 ^ places) - math.round(step * (10 ^ places))) > 0.000001 do
        places += 1
    end
    return places
end

function library.window(title)
    local rootWindow = getNativeWindow()
    local nativeTab = rootWindow:Tab({Name = tostring(title), Columns = 1})
    local nativeSection = nativeTab:Section({Name = tostring(title), Side = 1})
    local window = {}

    function window.label(text)
        return nativeSection:Label(tostring(text))
    end

    function window.button(text, callback)
        local row = nativeSection:Button()
        row:Add(tostring(text), callback)
        return row
    end

    function window.toggle(text, default, callback)
        return nativeSection:Toggle({
            Name = tostring(text),
            Flag = "Doors_" .. tostring(title) .. "_" .. tostring(text),
            Default = default == true,
            Callback = callback,
        })
    end

    function window.textbox(text, callback)
        return nativeSection:Textbox({
            Name = tostring(text),
            Flag = "Doors_" .. tostring(title) .. "_" .. tostring(text),
            Default = "",
            Placeholder = tostring(text),
            Finished = true,
            Callback = callback,
        })
    end

    function window.dropdown(text, values, default, callback)
        return nativeSection:Dropdown({
            Name = tostring(text),
            Flag = "Doors_" .. tostring(title) .. "_" .. tostring(text),
            Items = values or {},
            Default = default,
            Multi = false,
            Search = false,
            Callback = callback,
        })
    end

    function window.slider(text, minimum, maximum, step, default, callback)
        return nativeSection:Slider({
            Name = tostring(text),
            Flag = "Doors_" .. tostring(title) .. "_" .. tostring(text),
            Min = minimum,
            Max = maximum,
            Default = default,
            Decimals = decimalPlaces(step),
            Callback = callback,
        })
    end

    function window.hide()
        if type(nativeWindow.SetOpen) == "function" then
            nativeWindow:SetOpen(false)
        end
    end

    function window.show()
        if type(nativeWindow.SetOpen) == "function" then
            nativeWindow:SetOpen(true)
        end
    end

    function window.delete()
        pcall(function()
            VibeUI:Unload()
        end)
    end

    return window
end

function library.delete()
    for _, nativeWindow in ipairs(windows) do
        pcall(function()
            if type(nativeWindow.SetOpen) == "function" then
                nativeWindow:SetOpen(false)
            end
        end)
    end
    table.clear(windows)
    pcall(function()
        VibeUI:Unload()
    end)
    nativeWindow = nil
    rawset(Environment, "DoorsVibeUIUnload", nil)
end

rawset(Environment, "DoorsVibeUIUnload", function()
    pcall(function()
        VibeUI:Unload()
    end)
end)

return library
