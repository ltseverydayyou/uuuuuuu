stop skidding my shit kthxbye

## Contents
- [Topbar Icon Loader](#topbar-icon-loader)
  - [Quick Start](#quick-start)
  - [Events](#events)
  - [Recipes](#recipes)
  - [Notes](#notes)
- [ErrorPrompter (TrollErrorPrompt)](#errorprompter-trollerrorprompt)
  - [What it is](#what-it-is)
  - [Quick Start](#quick-start-1)
  - [Buttons](#buttons)
  - [API](#api)
  - [Notes](#notes-1)

---

## Topbar Icon Loader

### Quick Start
Load once:
```lua
local Icon = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Icon.luau"))()
````

Make an icon:

```lua
local myIcon = Icon.new()
	:setName("Demo")
	:setLabel("Hello")
	:setImage("rbxassetid://6031763426")
```

Optional alignment:

```lua
myIcon:align("Right")
```

### Events

```lua
myIcon.selected:Connect(function()
	print("selected")
end)

myIcon.deselected:Connect(function()
	print("deselected")
end)
```

### Recipes

**Basic icon with toggle key**

```lua
local Icon = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Icon.luau"))()
local ico = Icon.new()
	:setName("Hello")
	:setLabel("Hi")
	:setImage("rbxassetid://6031763426")
	:bindToggleKey(Enum.KeyCode.G)
```

**Dropdown (child icons live inside parent)**

```lua
local parent = Icon.new():setName("Main"):setLabel("Menu")
parent:addDropdown():new():setLabel("Option A")
parent:addDropdown():new():setLabel("Option B")
```

**Menu (horizontal menu children)**

```lua
local parent = Icon.new():setName("MenuIcon"):setLabel("Menu")
local submenu = parent:addMenu()
submenu:new():setLabel("One")
submenu:new():setLabel("Two")
```

**Notices (badge)**

```lua
local ico = Icon.new()
	:setName("Updates")
	:setLabel("Updates")
	:setImage("rbxassetid://6031068421")

ico:notify()
ico:clearNotices()
```

**Themes (global and per-icon)**

```lua
local Classic = Icon.Features.Themes and Icon.Features.Themes.Classic
if Classic then
	Icon.modifyBaseTheme(Classic)
end

local ico = Icon.new():setName("Blue")
ico:setTheme({
	{"IconImage", "ImageColor3", Color3.fromRGB(80, 160, 255), "Deselected"},
	{"IconButton", "BackgroundTransparency", 0.1, "Selected"},
})
```

**Alignment and order**

```lua
Icon.new():setName("Lefty"):align("Left"):setOrder(1)
Icon.new():setName("CenterGuy"):align("Center"):setOrder(2)
Icon.new():setName("Righty"):align("Right"):setOrder(3)
```

**Click callbacks / toggle vs one-click**

```lua
local ico = Icon.new():setName("ToggleMe")
ico.selected:Connect(function()
	print("turned on")
end)
ico.deselected:Connect(function()
	print("turned off")
end)

local once = Icon.new():setName("RunOnce"):oneClick(function(icon)
	print("ran once")
end)

local btn = Icon.new():setName("DoStuff")
btn:bindEvent("selected", function(icon)
	print("button pressed")
	icon:deselect()
end)
```

**Images and text tweaks**

```lua
local ico = Icon.new():setName("PicButton")
ico:setImage("rbxassetid://6031075930")
ico:setImageScale(0.8)
ico:setImageRatio(1)
ico:setLabel("Open")
ico:setCornerRadius(0.4)
ico:setCaption("Small helper text")
ico:setCaptionHint("Tooltip when hovered")
```

**More notice styles**

```lua
local updates = Icon.new():setName("Updates")
updates:notify()
updates:setIndicator("rbxassetid://6031068421")
updates:disableOverlay(true)
```

**Toggle/visibility helpers**

```lua
local ico = Icon.new()
ico:disableOverlay(true)
ico:setEnabled(false)

Icon.setTopbarEnabled(false)
```

**Indicators**

```lua
local ico = Icon.new():setName("Loading")
ico:setIndicator("rbxassetid://6031763426")
```

### Notes

* Loader caches across scripts; after loading once, you can call `Icon.new()` anywhere.
* Modules fetch over HTTP on first use.

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