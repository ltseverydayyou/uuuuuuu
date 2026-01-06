local BASE_URL = "https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/Topbar/"

local loader = rawget(_G, "__TopbarHttpLoader")
if not loader then
	loader = { sourceCache = {}, moduleCache = {}, nodes = {} }
	rawset(_G, "__TopbarHttpLoader", loader)
end

local sourceCache = loader.sourceCache
local moduleCache = loader.moduleCache
local nodes = loader.nodes

local Node = loader.Node
if not Node then
	Node = {}
	Node.__index = function(self, key)
		local direct = rawget(self, key)
		if direct ~= nil then
			return direct
		end
		local child = self.Children[key]
		if child then
			return child
		end
		return rawget(Node, key)
	end

	function Node.new(name, path, parent)
		local self = setmetatable({ Name = name, Parent = parent, Children = {}, __path = path }, Node)
		if parent then
			parent.Children[name] = self
		end
		return self
	end

	function Node:FindFirstChild(childName)
		return self.Children[childName]
	end

	function Node:IsA(kind)
		if kind == "ModuleScript" then
			return self.__path ~= nil
		end
		if kind == "Folder" then
			return self.__path == nil
		end
		return false
	end

	loader.Node = Node
end

if not nodes["Icon.luau"] then
	local root = Node.new("IconRoot", nil, nil)
	local icon = Node.new("Icon", "Icon.luau", root)
	nodes["Icon.luau"] = icon

	local elements = Node.new("Elements", nil, icon)
	Node.new("Caption", "Elements/Caption.luau", elements)
	Node.new("Container", "Elements/Container.luau", elements)
	Node.new("Indicator", "Elements/Indicator.luau", elements)
	Node.new("Menu", "Elements/Menu.luau", elements)
	Node.new("Notice", "Elements/Notice.luau", elements)
	Node.new("Selection", "Elements/Selection.luau", elements)
	Node.new("Widget", "Elements/Widget.luau", elements)
	Node.new("Dropdown", "Elements/Dropdown.luau", elements)

	local features = Node.new("Features", nil, icon)
	Node.new("Gamepad", "Features/Gamepad.luau", features)
	Node.new("Overflow", "Features/Overflow.luau", features)
	local themes = Node.new("Themes", "Features/Themes.luau", features)
	Node.new("Classic", "Features/Themes/Classic.luau", themes)
	Node.new("Default", "Features/Themes/Default.luau", themes)

	local packages = Node.new("Packages", nil, icon)
	Node.new("GoodSignal", "Packages/GoodSignal.luau", packages)
	Node.new("Janitor", "Packages/Janitor.luau", packages)

	Node.new("Types", "Types.luau", icon)
	Node.new("Reference", "Reference.luau", icon)
	Node.new("Utility", "Utility.luau", icon)
end

local function fetch(path)
	local cached = sourceCache[path]
	if cached then
		return cached
	end
	local source = game:HttpGet(BASE_URL .. path)
	sourceCache[path] = source
	return source
end

local function import(target)
	local path
	local scriptNode
	if type(target) == "table" and rawget(target, "__path") then
		path = target.__path
		scriptNode = target
	elseif type(target) == "string" then
		path = target
		scriptNode = nodes[path]
	end
	if not path then
		error("Invalid import target")
	end
	local cached = moduleCache[path]
	if cached ~= nil then
		return cached
	end
	local src = fetch(path)
	local fn, err = loadstring("return function(Import, script)\n" .. src .. "\nend", "=" .. path)
	if not fn then
		error(err)
	end
	local runner = fn()
	local result = runner(import, scriptNode)
	moduleCache[path] = result
	return result
end

loader.import = import

return import(nodes["Icon.luau"])
