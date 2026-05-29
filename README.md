stop skidding my shit kthxbye

## Contents
- [Topbar Icon Loader](#topbar-icon-loader)
  - [Overview](#overview)
  - [Quick Start](#quick-start)
  - [How Loading Works](#how-loading-works)
  - [Static API](#static-api)
  - [Icon Lifecycle](#icon-lifecycle)
  - [States and Events](#states-and-events)
  - [Layout, Alignment, and Overflow](#layout-alignment-and-overflow)
  - [Text, Images, and Visuals](#text-images-and-visuals)
  - [Themes](#themes)
  - [Menus and Dropdowns](#menus-and-dropdowns)
  - [Notices, Captions, and Indicators](#notices-captions-and-indicators)
  - [Input and Toggle Helpers](#input-and-toggle-helpers)
  - [Advanced Instance Access](#advanced-instance-access)
  - [Complete Method Reference](#complete-method-reference)
  - [Complete Event Reference](#complete-event-reference)
  - [Complete Examples](#complete-examples)
  - [Notes and Gotchas](#notes-and-gotchas)
- [ErrorPrompter (TrollErrorPrompt)](#errorprompter-trollerrorprompt)
  - [What it is](#what-it-is)
  - [Quick Start](#quick-start-1)
  - [Buttons](#buttons)
  - [API](#api)
  - [Notes](#notes-1)

---

## Topbar Icon Loader

### Overview

This repo exposes a TopbarPlus-style icon module through raw GitHub files.

Load the root `Icon.luau` entrypoint:

```lua
local Icon = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Icon.luau"))()
```

The returned `Icon` object is the API used to create, style, align, group, and destroy topbar buttons.

### Quick Start

```lua
local Icon = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Icon.luau"))()

local myIcon = Icon.new()
	:setName("Demo")
	:setLabel("Hello")
	:setImage("rbxassetid://6031763426")
```

Align it:

```lua
myIcon:align("Right")
```

Destroy it:

```lua
myIcon:destroy()
```

### How Loading Works

- `Icon.luau` is the entrypoint.
- `Topbar/` contains the loaded module sources.
- `ServiceResolver.luau` is loaded for service fetching and method calls.
- `UIprotector.luau` is used when parenting the generated ScreenGuis.
- Module source and module return values are cached globally in `_G.__TopbarHttpLoader`.
- The first load fetches module files over HTTP. Later imports reuse the cache.
- The GitHub URL points at `main`, so local changes only affect that URL after pushing.

### Static API

`Icon.new()`

Creates and returns a new icon.

```lua
local icon = Icon.new()
	:setName("Demo")
	:setLabel("Hello")
```

`Icon.getIcons()`

Returns the internal dictionary of icons, keyed by UID.

```lua
for uid, icon in pairs(Icon.getIcons()) do
	print(uid, icon.name)
end
```

`Icon.getIconByUID(uid)`

Returns an icon by UID.

```lua
local icon = Icon.getIconByUID(someUID)
```

`Icon.getIcon(nameOrUID)`

Returns an icon by UID first, then by `.name`.

```lua
local demo = Icon.getIcon("Demo")
```

`Icon.setTopbarEnabled(enabled)`

Enables or disables all Topbar ScreenGuis.

```lua
Icon.setTopbarEnabled(false)
task.wait(2)
Icon.setTopbarEnabled(true)
```

`Icon.modifyBaseTheme(modifications)`

Applies theme modifications to the global base theme and refreshes existing icons.

```lua
Icon.modifyBaseTheme({
	{ "IconButton", "BackgroundColor3", Color3.fromRGB(30, 30, 35) },
	{ "IconLabel", "TextColor3", Color3.fromRGB(255, 255, 255) },
})
```

`Icon.setDisplayOrder(order)`

Sets the ScreenGui display order for all Topbar containers.

```lua
Icon.setDisplayOrder(50)
```

Static properties:

- `Icon.baseDisplayOrder`
- `Icon.baseTheme`
- `Icon.closeableOverflowMenus`
- `Icon.container`
- `Icon.Features`
- `Icon.Themes`
- `Icon.iconsDictionary`
- `Icon.topbarEnabled`
- `Icon.isOldTopbar`

### Icon Lifecycle

Every icon starts with these defaults:

- `isEnabled = true`
- `isSelected = false`
- `isViewing = false`
- `activeState = "Deselected"`
- `alignment = "Left"` after construction setup
- `deselectWhenOtherIconSelected = true`
- `totalNotices = 0`

Create:

```lua
local icon = Icon.new()
```

Name:

```lua
icon:setName("Inventory")
print(icon.name)
```

Enable / disable one icon:

```lua
icon:setEnabled(false)
icon:setEnabled(true)
```

Select / deselect:

```lua
icon:select()
icon:deselect()
```

Destroy:

```lua
icon:destroy()
```

`Icon.Destroy` is an alias:

```lua
icon:Destroy()
```

### States and Events

Main states:

- `Deselected`
- `Selected`
- `Viewing`

Set state directly:

```lua
icon:setState("Selected")
icon:setState("Deselected")
icon:setState("Viewing")
```

Listen to core state events:

```lua
icon.selected:Connect(function(fromSource, sourceIcon)
	print("selected", fromSource, sourceIcon)
end)

icon.deselected:Connect(function(fromSource, sourceIcon)
	print("deselected", fromSource, sourceIcon)
end)

icon.toggled:Connect(function(isSelected, fromSource, sourceIcon)
	print("toggled", isSelected, fromSource)
end)

icon.stateChanged:Connect(function(stateName, fromSource, sourceIcon)
	print("state changed", stateName)
end)
```

Hover / viewing events:

```lua
icon.viewingStarted:Connect(function()
	print("hover/gamepad focus started")
end)

icon.viewingEnded:Connect(function()
	print("hover/gamepad focus ended")
end)
```

Bind by event name:

```lua
icon:bindEvent("selected", function(self, fromSource, sourceIcon)
	print(self.name, "selected")
end)

icon:unbindEvent("selected")
```

### Layout, Alignment, and Overflow

Alignments:

- `Left`
- `Center`
- `Right`

Methods:

```lua
icon:align("Left")
icon:align("Center")
icon:align("Right")

icon:setLeft()
icon:setMid()
icon:setRight()
```

`setAlignment` is an alias for `align`:

```lua
icon:setAlignment("Right")
```

Ordering:

```lua
Icon.new():setName("First"):setOrder(1)
Icon.new():setName("Second"):setOrder(2)
Icon.new():setName("Third"):setOrder(3)
```

Width:

```lua
icon:setWidth(120)
```

Overflow:

- Left and right icons automatically move into overflow menus when there is not enough horizontal space.
- Overflow icons are created internally.
- `Icon.closeableOverflowMenus = true` keeps the overflow/close control visible.
- Center icons can be relocated into left/right overflow when needed.
- Overflow menus use the same menu system as `setMenu`.

Example stress test:

```lua
local Icon = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Icon.luau"))()

for i = 1, 20 do
	Icon.new()
		:setName("Button" .. i)
		:setLabel("B" .. i)
		:setImage(6031763426)
		:setOrder(i)
end
```

### Text, Images, and Visuals

Label:

```lua
icon:setLabel("Inventory")
icon:setLabel("Selected label", "Selected")
icon:setLabel("Hover label", "Viewing")
```

Image:

```lua
icon:setImage("rbxassetid://6031763426")
icon:setImage(6031763426)
icon:setImage("rbxassetid://6031075930", "Selected")
```

Image scale / ratio:

```lua
icon:setImageScale(0.65)
icon:setImageRatio(1)
```

Text size, color, and font:

```lua
icon:setTextSize(18)
icon:setTextColor(Color3.fromRGB(255, 220, 120))
icon:setTextFont("BuilderSans", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
icon:setTextFont(Enum.Font.GothamBold)
icon:setTextFont("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium)
```

Corner radius:

```lua
icon:setCornerRadius(UDim.new(1, 0))
icon:setCornerRadius(UDim.new(0, 8), "Selected")
```

Overlay:

```lua
icon:disableOverlay(true)
icon:disableStateOverlay(true)
```

### Themes

Theme modifications are arrays:

```lua
{ instanceOrCollectiveName, propertyName, value, optionalStateName }
```

States can be:

- `Deselected`
- `Selected`
- `Viewing`
- nil, which applies to all supported states through the theme rebuild path

Set a complete per-icon theme:

```lua
icon:setTheme({
	{ "IconButton", "BackgroundColor3", Color3.fromRGB(20, 20, 25), "Deselected" },
	{ "IconButton", "BackgroundColor3", Color3.fromRGB(55, 55, 70), "Selected" },
	{ "IconLabel", "TextColor3", Color3.fromRGB(255, 255, 255) },
})
```

Modify a theme and save the modification UID:

```lua
local _, uid = icon:modifyTheme({
	{ "IconImage", "ImageColor3", Color3.fromRGB(80, 160, 255) },
	{ "IconLabel", "TextSize", 18, "Selected" },
})

task.wait(3)
icon:removeModification(uid)
```

Remove by instance/property/state:

```lua
icon:removeModificationWith("IconLabel", "TextSize", "Selected")
```

Modify child icons in menus/dropdowns:

```lua
parent:modifyChildTheme({
	{ "IconLabel", "TextColor3", Color3.fromRGB(255, 255, 0) },
	{ "Widget", "MinimumWidth", 160 },
})
```

Modify every icon base theme:

```lua
Icon.modifyBaseTheme({
	{ "IconButton", "BackgroundTransparency", 0.2 },
})
```

Use the Classic theme file:

```lua
local Classic = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Topbar/Features/Themes/Classic.luau"))()
Icon.modifyBaseTheme(Classic)
```

Common theme targets:

- `Widget`
- `IconButton`
- `IconSpot`
- `IconOverlay`
- `IconImage`
- `IconImageScale`
- `IconImageRatio`
- `IconImageCorner`
- `IconLabel`
- `IconCorners`
- `Selection`
- `SelectionGradient`
- `ContentsList`
- `PaddingLeft`
- `PaddingRight`
- `Menu`
- `Dropdown`
- `Notice`
- `NoticeLabel`
- `Indicator`

Advanced behavior hook:

```lua
icon:setBehaviour("IconButton", "BackgroundTransparency", function(value, instance, property)
	return math.clamp(value, 0, 0.5)
end, true)
```

### Menus and Dropdowns

Create child icons normally, then pass them to `setMenu` or `setDropdown`.

Horizontal menu:

```lua
local parent = Icon.new()
	:setName("Tools")
	:setLabel("Tools")
	:setImage(6031763426)

local one = Icon.new():setName("ToolOne"):setLabel("One")
local two = Icon.new():setName("ToolTwo"):setLabel("Two")
local three = Icon.new():setName("ToolThree"):setLabel("Three")

parent:setMenu({ one, two, three })
```

Compatibility menu builder:

```lua
local menu = parent:addMenu()

local visual = menu:new()
	:setName("VisualToggle")
	:setLabel("Visual: OFF")
	:oneClick(function()
		print("visual toggled")
	end)
```

Fixed menu:

```lua
parent:setFixedMenu({ one, two })
```

`setFrozenMenu` is an alias:

```lua
parent:setFrozenMenu({ one, two })
```

Manual menu join:

```lua
local child = Icon.new():setName("ManualChild"):setLabel("Child")
child:joinMenu(parent)
```

Leave a menu/dropdown:

```lua
child:leave()
```

Vertical dropdown:

```lua
local parent = Icon.new()
	:setName("Settings")
	:setLabel("Settings")
	:setImage(6031280882)

local graphics = Icon.new():setName("Graphics"):setLabel("Graphics")
local audio = Icon.new():setName("Audio"):setLabel("Audio")
local controls = Icon.new():setName("Controls"):setLabel("Controls")

parent:setDropdown({ graphics, audio, controls })
```

Manual dropdown join:

```lua
local child = Icon.new():setName("DropdownChild"):setLabel("Child")
child:joinDropdown(parent)
```

Force dropdown creation and get the dropdown frame:

```lua
local dropdown = parent:getDropdown()
dropdown:SetAttribute("MaxIcons", 3)
```

Menu and dropdown events:

```lua
parent.menuChildAdded:Connect(function(childIcon)
	print("menu child added", childIcon.name)
end)

parent.dropdownChildAdded:Connect(function(childIcon)
	print("dropdown child added", childIcon.name)
end)
```

### Notices, Captions, and Indicators

Notices:

```lua
icon:notify()
icon:notify(nil, "message-1")
icon:clearNotices()
```

Clear a notice on a custom signal:

```lua
local clearSignal = Instance.new("BindableEvent")
icon:notify(clearSignal.Event, "quest-complete")

task.wait(2)
clearSignal:Fire()
```

Notice events:

```lua
icon.notified:Connect(function()
	print("notice changed")
end)

icon.noticeChanged:Connect(function(totalNotices)
	print("notices", totalNotices)
end)
```

Captions:

```lua
icon:setCaption("Open inventory")
icon:setCaption("")
```

Caption hotkey hint:

```lua
icon:setCaptionHint(Enum.KeyCode.G)
```

Indicators are gamepad key indicators. `setIndicator` expects a `KeyCode` and uses `UserInputService:GetImageForKeyCode`.

```lua
icon:setIndicator(Enum.KeyCode.DPadUp)
icon:setIndicator(nil)
```

### Input and Toggle Helpers

Toggle key:

```lua
icon:bindToggleKey(Enum.KeyCode.G)
icon:unbindToggleKey(Enum.KeyCode.G)
```

One-click button:

```lua
Icon.new()
	:setName("Refresh")
	:setLabel("Refresh")
	:oneClick()
	:bindEvent("selected", function(self)
		print("refresh clicked")
	end)
```

Prevent auto-deselect:

```lua
icon:autoDeselect(false)
```

Lock / unlock:

```lua
icon:lock()
task.wait(1)
icon:unlock()
```

Debounce:

```lua
icon:bindEvent("selected", function(self)
	self:debounce(0.5)
end)
```

Bind a GUI to icon selection:

```lua
local panel = Instance.new("Frame")
panel.Visible = false

icon:bindToggleItem(panel)
icon:select()
icon:deselect()
icon:unbindToggleItem(panel)
```

Run a callback in a spawned thread:

```lua
icon:call(function(self, message)
	print(self.name, message)
end, "hello")
```

Add cleanup:

```lua
local connection = game:GetService("RunService").Heartbeat:Connect(function() end)
icon:addToJanitor(connection, "Disconnect")
```

### Advanced Instance Access

Get one generated instance:

```lua
local widget = icon:getInstance("Widget")
local label = icon:getInstance("IconLabel")
local button = icon:getInstance("IconButton")
```

Get a collective:

```lua
local corners = icon:getCollective("IconCorners")
for _, corner in pairs(corners) do
	corner.CornerRadius = UDim.new(0, 6)
end
```

Get instance or collective:

```lua
for _, instance in pairs(icon:getInstanceOrCollective("IconCorners")) do
	print(instance)
end
```

Refresh appearance manually:

```lua
icon:refreshAppearance(icon:getInstance("IconButton"), "BackgroundTransparency")
icon:refresh()
```

Clip UI outside the icon:

```lua
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(200, 120)
frame.Position = UDim2.new(0, 0, 1, 8)
frame.Parent = icon.widget

local _, clippedClone = icon:clipOutside(frame)
```

Convert label to a number spinner:

```lua
icon:convertLabelToNumberSpinner(numberSpinner, function()
	print("spinner attached")
end)
```

### Complete Method Reference

Static methods:

| Method | Usage |
| --- | --- |
| `Icon.new()` | Creates an icon. |
| `Icon.getIcons()` | Returns the icon dictionary. |
| `Icon.getIconByUID(uid)` | Finds by UID. |
| `Icon.getIcon(nameOrUID)` | Finds by UID or name. |
| `Icon.setTopbarEnabled(bool)` | Enables/disables all topbar ScreenGuis. |
| `Icon.modifyBaseTheme(modifications)` | Changes the shared base theme. |
| `Icon.setDisplayOrder(order)` | Changes ScreenGui display order. |

Instance methods:

| Method | Usage |
| --- | --- |
| `setName(name)` | Sets `.name` and widget name. |
| `setState(state, fromSource, sourceIcon)` | Sets `Selected`, `Deselected`, or `Viewing`. |
| `getInstance(name)` | Gets generated UI by name. |
| `getCollective(name)` | Gets generated UI by collective attribute. |
| `getInstanceOrCollective(name)` | Gets either a direct instance or a collective list. |
| `getStateGroup(state)` | Gets internal appearance state group. |
| `refreshAppearance(instance, property)` | Reapplies theme to an instance/property. |
| `refresh()` | Refreshes the icon and recalculates size. |
| `updateParent()` | Refreshes parent menu/dropdown sizing. |
| `setBehaviour(name, property, callback, refresh)` | Adds a value transform before theme application. |
| `modifyTheme(modifications, uid)` | Adds theme modifications. Returns `self, uid`. |
| `modifyChildTheme(modifications, uid)` | Applies modifications to children. |
| `removeModification(uid)` | Removes modifications by UID. |
| `removeModificationWith(instance, property, state)` | Removes modifications by matching fields. |
| `setTheme(theme)` | Sets a full icon theme. |
| `setEnabled(bool)` | Shows/hides this icon. |
| `select(fromSource, sourceIcon)` | Selects this icon. |
| `deselect(fromSource, sourceIcon)` | Deselects this icon. |
| `notify(clearSignal, noticeId)` | Adds a notice badge. |
| `clearNotices()` | Clears notices. |
| `disableOverlay(bool)` | Disables the hover/selected overlay. |
| `disableStateOverlay(bool)` | Alias of `disableOverlay`. |
| `setImage(imageId, state)` | Sets icon image. |
| `setLabel(text, state)` | Sets label text. |
| `setOrder(order, state)` | Sets layout order. |
| `setCornerRadius(udim, state)` | Sets `IconCorners` corner radius. |
| `align(alignment)` | Aligns left/center/right. |
| `setAlignment(alignment)` | Alias of `align`. |
| `setLeft()` | Aligns left. |
| `setMid()` | Aligns center. |
| `setRight()` | Aligns right. |
| `setWidth(width, state)` | Sets desired widget width. |
| `setImageScale(scale, state)` | Sets image scale. |
| `setImageRatio(ratio, state)` | Sets image aspect ratio. |
| `setTextSize(size, state)` | Sets label text size. |
| `setTextFont(font, weight, style, state)` | Sets label font. |
| `setTextColor(color, state)` | Sets label color. |
| `bindToggleItem(gui)` | Shows/hides a GUI with selection. |
| `unbindToggleItem(gui)` | Removes a bound GUI. |
| `bindEvent(eventName, callback)` | Connects to an icon signal. |
| `unbindEvent(eventName)` | Disconnects a bound event. |
| `bindToggleKey(keyCode)` | Adds keyboard toggle key. |
| `unbindToggleKey(keyCode)` | Removes keyboard toggle key. |
| `call(callback, ...)` | Runs callback with `self` asynchronously. |
| `addToJanitor(item, method, index)` | Adds cleanup to icon janitor. |
| `lock()` | Disables clicking/toggling. |
| `unlock()` | Re-enables clicking/toggling. |
| `debounce(seconds)` | Locks, waits, unlocks. |
| `autoDeselect(bool)` | Controls deselect when another icon selects. |
| `oneClick(boolOrCallback)` | Auto-deselects after selection, or runs a callback then deselects. |
| `setCaption(text)` | Sets hover caption. |
| `setCaptionHint(keyCode)` | Uses a key hint caption. |
| `leave()` | Leaves menu/dropdown parent. |
| `addMenu()` | Returns a compatibility menu builder with `:new()`. |
| `joinMenu(parentIcon)` | Joins parent menu. |
| `setMenu(iconArray)` | Sets horizontal menu children. |
| `setFixedMenu(iconArray)` | Creates frozen menu. |
| `setFrozenMenu(iconArray)` | Alias of `setFixedMenu`. |
| `freezeMenu()` | Keeps menu selected and hides icon spot. |
| `joinDropdown(parentIcon)` | Joins parent dropdown. |
| `getDropdown()` | Creates/returns dropdown frame. |
| `setDropdown(iconArray)` | Sets dropdown children. |
| `clipOutside(instance)` | Creates clipped clone for outside UI. |
| `setIndicator(keyCode)` | Sets gamepad key indicator. |
| `convertLabelToNumberSpinner(spinner, callback)` | Replaces label display with spinner UI. |
| `destroy()` | Destroys icon and cleanup. |
| `Destroy()` | Alias of `destroy`. |

### Complete Event Reference

Static signals:

| Signal | Fires when |
| --- | --- |
| `Icon.baseDisplayOrderChanged` | `Icon.setDisplayOrder` runs. |
| `Icon.insetHeightChanged` | Roblox topbar inset height changes. |
| `Icon.iconAdded` | An icon is created/changed into availability. |
| `Icon.iconRemoved` | An icon is destroyed. |
| `Icon.iconChanged` | An icon alignment/state relevant to layout changes. |

Instance signals:

| Signal | Fires when |
| --- | --- |
| `selected` | Icon enters selected state. |
| `deselected` | Icon enters deselected state. |
| `toggled` | Selection boolean changes. |
| `viewingStarted` | Hover/focus viewing starts. |
| `viewingEnded` | Hover/focus viewing ends. |
| `stateChanged` | Active state changes. |
| `notified` | Notice behavior fires. |
| `noticeStarted` | `notify()` starts a notice. |
| `noticeChanged` | Notice count changes. |
| `endNotices` | Notices are cleared. |
| `toggleKeyAdded` | A toggle key is bound. |
| `fakeToggleKeyChanged` | Caption hint key changes. |
| `alignmentChanged` | Alignment changes. |
| `updateSize` | Widget size should recalculate. |
| `resizingComplete` | Widget resize finishes. |
| `joinedParent` | Icon joins menu/dropdown. |
| `menuSet` | `setMenu()` runs. |
| `dropdownSet` | `setDropdown()` runs. |
| `updateMenu` | Menu width should recalculate. |
| `startMenuUpdate` | Menu update begins. |
| `childThemeModified` | Child theme modifications change. |
| `indicatorSet` | `setIndicator()` runs. |
| `dropdownChildAdded` | Child joins dropdown. |
| `menuChildAdded` | Child joins menu. |

### Complete Examples

Basic toggle:

```lua
local Icon = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Icon.luau"))()

local toggle = Icon.new()
	:setName("Demo")
	:setLabel("Hello")
	:setImage("rbxassetid://6031763426")

toggle.selected:Connect(function()
	print("on")
end)

toggle.deselected:Connect(function()
	print("off")
end)
```

One-click action:

```lua
Icon.new()
	:setName("Save")
	:setLabel("Save")
	:setImage(6035067836)
	:oneClick()
	:bindEvent("selected", function(self)
		print("saved")
	end)
```

Right-side settings dropdown:

```lua
local settings = Icon.new()
	:setName("Settings")
	:setLabel("Settings")
	:setImage(6031280882)
	:setRight()

local audio = Icon.new():setName("Audio"):setLabel("Audio")
local video = Icon.new():setName("Video"):setLabel("Video")
local controls = Icon.new():setName("Controls"):setLabel("Controls")

settings:setDropdown({ audio, video, controls })
```

Horizontal tools menu:

```lua
local tools = Icon.new()
	:setName("Tools")
	:setLabel("Tools")
	:setImage(6031763426)

local move = Icon.new():setName("Move"):setLabel("Move")
local scale = Icon.new():setName("Scale"):setLabel("Scale")
local rotate = Icon.new():setName("Rotate"):setLabel("Rotate")

tools:setMenu({ move, scale, rotate })
```

Notification icon:

```lua
local quests = Icon.new()
	:setName("Quests")
	:setLabel("Quests")
	:setImage(6031068421)

quests:notify()

quests.selected:Connect(function()
	quests:clearNotices()
end)
```

Hotkey icon:

```lua
local inventory = Icon.new()
	:setName("Inventory")
	:setLabel("Inventory")
	:setImage(6031265976)
	:bindToggleKey(Enum.KeyCode.G)
	:setCaption("Open inventory")
	:setCaptionHint(Enum.KeyCode.G)
```

Custom selected style:

```lua
local icon = Icon.new()
	:setName("Styled")
	:setLabel("Styled")
	:setImage(6031075930)

icon:modifyTheme({
	{ "IconButton", "BackgroundColor3", Color3.fromRGB(45, 70, 120), "Selected" },
	{ "IconLabel", "TextColor3", Color3.fromRGB(255, 255, 255), "Selected" },
	{ "IconImage", "ImageColor3", Color3.fromRGB(120, 190, 255), "Selected" },
})
```

Temporary style:

```lua
local _, uid = icon:modifyTheme({
	{ "IconButton", "BackgroundTransparency", 0 },
})

task.wait(2)
icon:removeModification(uid)
```

Bound panel:

```lua
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local panelGui = Instance.new("ScreenGui")
panelGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(300, 200)
panel.Position = UDim2.fromOffset(20, 80)
panel.Visible = false
panel.Parent = panelGui

local icon = Icon.new()
	:setName("Panel")
	:setLabel("Panel")
	:bindToggleItem(panel)
```

Overflow test:

```lua
for i = 1, 30 do
	Icon.new()
		:setName("OverflowTest" .. i)
		:setLabel("Item " .. i)
		:setOrder(i)
end
```

Gamepad indicator:

```lua
local gamepadIcon = Icon.new()
	:setName("Gamepad")
	:setLabel("Action")
	:setIndicator(Enum.KeyCode.ButtonA)
```

Cleanup:

```lua
local icon = Icon.new():setName("Cleanup")

local connection = game:GetService("RunService").Heartbeat:Connect(function()
	print("running")
end)

icon:addToJanitor(connection, "Disconnect")

task.wait(2)
icon:destroy()
```

### Notes and Gotchas

- `setCaptionHint` expects an `Enum.KeyCode`, not a string.
- `setIndicator` expects an `Enum.KeyCode`, not an image id.
- `setImage` accepts either a full image string or a numeric asset id.
- `modifyTheme` returns `self, modificationUID`.
- Most instance methods return `self` so calls can be chained.
- The loader uses protected UI parenting, so Topbar ScreenGuis are put through `UIprotector.luau`.

---

## ErrorPrompter (TrollErrorPrompt)

### What it is

A simple, gamepad-friendly error prompt UI (title + message + buttons) with optional open/close animation, auto sizing, and input-sink while open.

### Quick Start

```lua
local Players = game:GetService("Players")

local TrollErrorPrompt = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/ErrorPrompter.lua"))()

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local prompt = TrollErrorPrompt.new("Default", {
	PlayAnimation = true,
	HideErrorCode = false,
	MessageTextScaled = false,
})

prompt:setParent(pg)
prompt:setErrorTitle("Catastrophic Troll Failure")

prompt:updateButtons({
	{
		Text = "Retry",
		Primary = true,
		LayoutOrder = 1,
		Callback = function()
			prompt:onErrorChanged("Retry failed spectacularly. Try crying.", 420, "Channel: Troll-01")
		end,
	},
	{
		Text = "Ignore",
		Primary = false,
		LayoutOrder = 2,
		Callback = function()
			prompt:onErrorChanged("Ignoring made it worse. Nice job.", 666, "Channel: Troll-02")
		end,
	},
	{
		Text = "OK I Give Up",
		Primary = false,
		LayoutOrder = 3,
		Callback = function()
			prompt:onErrorChanged("", nil, "")
		end,
	},
})

task.wait(3)
prompt:onErrorChanged("Roblox has detected extreme levels of skill issue.", 1337, "Channel: SkillIssue")
```

### Buttons

`updateButtons()` takes an array of button entries:

* `Text` (string) — label text
* `Primary` (boolean) — styles it as the primary action
* `LayoutOrder` (number) — left-to-right order
* `Callback` (function) — runs on click/tap/gamepad activate

Example (single OK button):

```lua
prompt:updateButtons({
	{
		Text = "OK",
		Primary = true,
		LayoutOrder = 1,
		Callback = function()
			prompt:onErrorChanged("")
		end,
	},
})
```

### API

**Constructor**

* `TrollErrorPrompt.new(styleName, options)`

  * `styleName`: currently `"Default"` (placeholder for future templates)
  * `options`:

    * `PlayAnimation` (bool)
    * `HideErrorCode` (bool)
    * `MenuIsOpenKey` (string)
    * `MessageTextScaled` (bool)

**Attach**

* `prompt:setParent(parent)`

  * `PlayerGui` recommended (auto creates internal `ScreenGui`)
  * also supports `GuiBase2d` or direct instance parenting

**Content**

* `prompt:setErrorTitle(titleText)`
* `prompt:setErrorText(message, errorCode, extra)`
* `prompt:updateButtons(buttonList)`

**Open/Close**

* `prompt:onErrorChanged(message, errorCode, extra)`

  * if `message` is `""` or nil => closes
  * otherwise => opens/updates prompt

**Cleanup**

* `prompt:Destroy()`

### Notes

* While open, input is sunk (gamepad A/B/Start) so it behaves like a real modal.
* It auto resizes height to fit text; call `prompt:resizeWidthAndHeight()` if you change parent size dynamically.
* If you call `updateButtons()` with multiple buttons, widths are auto-split across the row.
