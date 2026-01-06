stop skidding my shit kthxbye

Topbar loader usage
- Load once: `local Icon = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Icon.luau"))()`
- Make an icon: `local myIcon = Icon.new():setName("Demo"):setLabel("Hello"):setImage("rbxassetid://6031763426")`
- Optional alignment: `myIcon:align("Right")`
- Events:
  - `myIcon.selected:Connect(function() print("selected") end)`
  - `myIcon.deselected:Connect(function() print("deselected") end)`
- Add more icons by calling `Icon.new()` again in other scripts; the loader caches the package globally.

Quick recipes
- Basic icon with toggle key: 
  ```lua
  local Icon = loadstring(game:HttpGet("https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Icon.luau"))()
  local ico = Icon.new():setName("Hello"):setLabel("Hi"):setImage("rbxassetid://6031763426"):bindToggleKey(Enum.KeyCode.G)
  ```
- Dropdown (child icons live inside parent): 
  ```lua
  local parent = Icon.new():setName("Main"):setLabel("Menu")
  parent:addDropdown():new():setLabel("Option A")
  parent:addDropdown():new():setLabel("Option B")
  ```
- Menu (horizontal menu children): 
  ```lua
  local parent = Icon.new():setName("MenuIcon"):setLabel("Menu")
  local submenu = parent:addMenu()
  submenu:new():setLabel("One")
  submenu:new():setLabel("Two")
  ```
- Notices (badge): 
  ```lua
  local ico = Icon.new():setName("Updates")
  ico:notify() -- shows badge
  ico:clearNotices()
  ```
- Themes (global and per-icon):
  ```lua
  -- base theme for all icons
  local Classic = Icon.Features.Themes and Icon.Features.Themes.Classic
  if Classic then Icon.modifyBaseTheme(Classic) end
  -- per icon tweak
  local ico = Icon.new():setName("Blue")
  ico:setTheme({
    {"IconImage", "ImageColor3", Color3.fromRGB(80, 160, 255), "Deselected"},
    {"IconButton", "BackgroundTransparency", 0.1, "Selected"},
  })
  ```
- Alignment and order: 
  ```lua
  Icon.new():setName("Lefty"):align("Left"):setOrder(1)
  Icon.new():setName("CenterGuy"):align("Center"):setOrder(2)
  Icon.new():setName("Righty"):align("Right"):setOrder(3)
  ```
- Click callbacks / toggle vs one-click:
  ```lua
  -- Default toggle: stays selected until deselected
  local ico = Icon.new():setName("ToggleMe")
  ico.selected:Connect(function() print("turned on") end)
  ico.deselected:Connect(function() print("turned off") end)

  -- One-click: fires once, does not stay selected
  local once = Icon.new():setName("RunOnce"):oneClick(function(icon)
    print("ran once")
  end)

  -- Treat as a button: run code on select, then force deselect
  local btn = Icon.new():setName("DoStuff")
  btn:bindEvent("selected", function(icon)
    print("button pressed")
    -- your code here
    icon:deselect()
  end)
  ```
- Images and text tweaks:
  ```lua
  local ico = Icon.new():setName("PicButton")
  ico:setImage("rbxassetid://6031075930")                -- icon image
  ico:setImageScale(0.8)                                  -- scale inside button
  ico:setImageRatio(1)                                   -- keep square
  ico:setLabel("Open")                                   -- button text
  ico:setCornerRadius(0.4)                               -- rounded look
  ico:setCaption("Small helper text")                    -- caption under text
  ico:setCaptionHint("Tooltip when hovered")
  ```
- More notice styles:
  ```lua
  local updates = Icon.new():setName("Updates")
  updates:notify()                                       -- badge on
  updates:setIndicator("rbxassetid://6031068421")        -- indicator image
  updates:disableOverlay(true)                           -- hide hover overlay if you want
  ```
- Toggle/visibility helpers:
  ```lua
  local ico = Icon.new()
  ico:disableOverlay(true) -- hide hover overlay
  ico:setEnabled(false)     -- hide from topbar
  Icon.setTopbarEnabled(false) -- hide every icon
  ```
- Indicators:
  ```lua
  local ico = Icon.new():setName("Loading")
  ico:setIndicator("rbxassetid://6031763426") -- adds indicator image
  ```

Notes
- The loader caches across scripts; call `Icon.new()` anywhere after the loadstring.
- All modules are fetched via HTTP when first needed; keep internet access available when first running.***
