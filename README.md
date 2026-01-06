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
