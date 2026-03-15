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
local TweenService = __betterGetService("TweenService")
local UserInput = __betterGetService("UserInputService")
local GuiService = __betterGetService("GuiService")

local TabSelector = {}

local Base = import("ui/MainUI").Base
local Tabs = Base.Tabs.Container
local Pages = Base.Body.Pages

if Tabs and Tabs.IsA and Tabs:IsA("GuiObject") then
    Tabs.Active = true
    local tabsParent = Tabs.Parent
    if tabsParent and tabsParent.IsA and tabsParent:IsA("GuiObject") then
        tabsParent.Active = true
    end
end

local MessageBox, MessageType = import("ui/controls/MessageBox")

local requiredMethods = {
    ConstantScanner = import("modules/ConstantScanner").RequiredMethods,
    UpvalueScanner = import("modules/UpvalueScanner").RequiredMethods,
    ScriptScanner = import("modules/ScriptScanner").RequiredMethods,
    ModuleScanner = import("modules/ModuleScanner").RequiredMethods,
    ClosureSpy = import("modules/ClosureSpy").RequiredMethods,
    RemoteSpy = import("modules/RemoteSpy").RequiredMethods
}

local constants = {
    fadeLength = TweenInfo.new(0.15),
    tabSelected = Color3.fromRGB(45, 45, 45),
    iconSelected = Color3.fromRGB(255, 255, 255),
    tabUnselected = Color3.fromRGB(20, 20, 20),
    iconUnselected = Color3.fromRGB(127, 127, 127)
}

local selectedTab 
local selectedPage = Pages.Home

local function isPointInGui(gui, pos)
    local absPos = gui.AbsolutePosition
    local absSize = gui.AbsoluteSize
    return pos.X >= absPos.X and pos.X <= (absPos.X + absSize.X)
        and pos.Y >= absPos.Y and pos.Y <= (absPos.Y + absSize.Y)
end

local function findTabFromGuiObjects(pos)
    if not (GuiService and GuiService.GetGuiObjectsAtPosition) then
        return nil
    end

    local objects = GuiService:GetGuiObjectsAtPosition(pos.X, pos.Y)
    for _, obj in ipairs(objects) do
        local cur = obj
        while cur and cur ~= Tabs do
            if cur:IsA("ImageButton") and cur.Parent == Tabs and Tabs:FindFirstChild(cur.Name) then
                return cur
            end
            cur = cur.Parent
        end
    end
    return nil
end

local function methodsCheck(methods)
    local globalMethods = oh.Methods
    local missingMethods = ""

    for methodName in pairs(methods) do
        if not globalMethods[methodName] then
            missingMethods = missingMethods .. methodName .. ", "
        end
    end

    return (missingMethods ~= "" and missingMethods:sub(1, -3)) or nil
end

local animationCache = {}
local function selectTab(tabName)
    local methodsFound = requiredMethods[tabName]
    local missingMethods = methodsFound and methodsCheck(methodsFound)

    if missingMethods then
        return MessageBox.Show(
            "Your exploit does not support this section",
            "The following functions are missing from your exploit: " .. missingMethods,
            MessageType.OK
        )
    end

    local tab = Tabs:FindFirstChild(tabName)
    local page = Pages:FindFirstChild(tabName)

    if selectedTab then
        local tabAnimation = animationCache[selectedTab]
        tabAnimation.unselected:Play()
        tabAnimation.iconUnselected:Play()
    end

    selectedPage.Visible = false
    page.Visible = true
    tab.ImageColor3 = constants.tabSelected
    tab.Icon.ImageColor3 = constants.iconSelected

    oh.setStatus(page.Name:sub(1, 1) .. page.Name:sub(2):gsub('%u', function(c) return ' ' .. c end))
    
    selectedTab = tab
    selectedPage = page
    return true
end

for _i, tab in pairs(Tabs:GetChildren()) do
    if tab:IsA("ImageButton") then
        tab.Active = true
        local selected = TweenService:Create(tab, constants.fadeLength, { ImageColor3 = constants.tabSelected })
        local unselected = TweenService:Create(tab, constants.fadeLength, { ImageColor3 = constants.tabUnselected })
        local iconSelected = TweenService:Create(tab.Icon, constants.fadeLength, { ImageColor3 = constants.iconSelected })
        local iconUnselected = TweenService:Create(tab.Icon, constants.fadeLength, { ImageColor3 = constants.iconUnselected })

        animationCache[tab] = {
            selected = selected,
            unselected = unselected,
            iconSelected = iconSelected,
            iconUnselected = iconUnselected
        }

        local function onTabActivated()
            if selectedTab ~= tab and Tabs:FindFirstChild(tab.Name) then
                selectTab(tab.Name)
            end
        end

        tab.MouseButton1Click:Connect(onTabActivated)
        tab.MouseButton1Click:Connect(onTabActivated)

        tab.MouseEnter:Connect(function()
            if selectedPage ~= Pages:FindFirstChild(tab.Name) then
                selected:Play()
                iconSelected:Play()
            end
        end)

        tab.MouseLeave:Connect(function()
            if selectedPage ~= Pages:FindFirstChild(tab.Name) then
                unselected:Play()
                iconUnselected:Play()
            end
        end)
    end
end

if UserInput then
    UserInput.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = UserInput:GetMouseLocation()
            local root = Base:FindFirstAncestorOfClass("ScreenGui")
            if root and not root.IgnoreGuiInset then
                local inset = GuiService and GuiService.GetGuiInset and GuiService:GetGuiInset()
                if inset then
                    pos = pos - inset
                end
            end

            local hitTab = findTabFromGuiObjects(pos)
            if hitTab and hitTab ~= selectedTab then
                selectTab(hitTab.Name)
                return
            end

            for _, tab in pairs(Tabs:GetChildren()) do
                if tab:IsA("ImageButton") and tab.Visible and selectedTab ~= tab and isPointInGui(tab, pos) then
                    selectTab(tab.Name)
                    break
                end
            end
        end
    end)
end

TabSelector.SelectTab = selectTab
return TabSelector

