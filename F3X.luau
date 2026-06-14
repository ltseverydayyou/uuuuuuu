local t = {}
local string = string
local math = math
local table = table
local error = error
local tonumber = tonumber
local tostring = tostring
local type = type
local setmetatable = setmetatable
local pairs = pairs
local ipairs = ipairs
local assert = assert
local function setp(o, p, v)
	if o == nil then
		return false
	end
	return pcall(function()
		o[p] = v
	end)
end
_G.setp = setp
local StringBuilder = {
	buffer = {},
}
function StringBuilder:New()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.buffer = {}
	return o
end
function StringBuilder:Append(s)
	self.buffer[#self.buffer + 1] = s
end
function StringBuilder:ToString()
	return table.concat(self.buffer)
end
local JsonWriter = {
	backslashes = {
		["\b"] = "\\b",
		["\t"] = "\\t",
		["\n"] = "\\n",
		["\f"] = "\\f",
		["\r"] = "\\r",
		['"'] = '\\"',
		["\\"] = "\\\\",
		["/"] = "\\/",
	},
}
function JsonWriter:New()
	local o = {}
	o.writer = StringBuilder:New()
	setmetatable(o, self)
	self.__index = self
	return o
end
function JsonWriter:Append(s)
	self.writer:Append(s)
end
function JsonWriter:ToString()
	return self.writer:ToString()
end
function JsonWriter:Write(o)
	local t = type(o)
	if t == "nil" then
		self:WriteNil()
	elseif t == "boolean" then
		self:WriteString(o)
	elseif t == "number" then
		self:WriteString(o)
	elseif t == "string" then
		self:ParseString(o)
	elseif t == "table" then
		self:WriteTable(o)
	elseif t == "function" then
		self:WriteFunction(o)
	elseif t == "thread" then
		self:WriteError(o)
	elseif t == "userdata" then
		self:WriteError(o)
	end
end
function JsonWriter:WriteNil()
	self:Append("null")
end
function JsonWriter:WriteString(o)
	self:Append(tostring(o))
end
function JsonWriter:ParseString(s)
	self:Append('"')
	self:Append(string.gsub(s, '[%z%c\\"/]', function(n)
		local c = self.backslashes[n]
		if c then
			return c
		end
		return string.format("\\u%.4X", string.byte(n))
	end))
	self:Append('"')
end
function JsonWriter:IsArray(t)
	local count = 0
	local isindex = function(k)
		if type(k) == "number" and k > 0 then
			if math.floor(k) == k then
				return true
			end
		end
		return false
	end
	for k, v in pairs(t) do
		if not isindex(k) then
			return false, "{", "}"
		else
			count = math.max(count, k)
		end
	end
	return true, "[", "]", count
end
function JsonWriter:WriteTable(t)
	local ba, st, et, n = self:IsArray(t)
	self:Append(st)
	if ba then
		for i = 1, n do
			self:Write(t[i])
			if i < n then
				self:Append(",")
			end
		end
	else
		local first = true
		for k, v in pairs(t) do
			if not first then
				self:Append(",")
			end
			first = false
			self:ParseString(k)
			self:Append(":")
			self:Write(v)
		end
	end
	self:Append(et)
end
function JsonWriter:WriteError(o)
	error(string.format("Encoding of %s unsupported", tostring(o)))
end
function JsonWriter:WriteFunction(o)
	if o == Null then
		self:WriteNil()
	else
		self:WriteError(o)
	end
end
local StringReader = {
	s = "",
	i = 0,
}
function StringReader:New(s)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.s = s or o.s
	return o
end
function StringReader:Peek()
	local i = self.i + 1
	if i <= #self.s then
		return string.sub(self.s, i, i)
	end
	return nil
end
function StringReader:Next()
	self.i = self.i + 1
	if self.i <= #self.s then
		return string.sub(self.s, self.i, self.i)
	end
	return nil
end
function StringReader:All()
	return self.s
end
local JsonReader = {
	escapes = {
		t = "\t",
		n = "\n",
		f = "\f",
		r = "\r",
		b = "\b",
	},
}
function JsonReader:New(s)
	local o = {}
	o.reader = StringReader:New(s)
	setmetatable(o, self)
	self.__index = self
	return o
end
function JsonReader:Read()
	self:SkipWhiteSpace()
	local peek = self:Peek()
	if peek == nil then
		error(string.format("Nil string: '%s'", self:All()))
	elseif peek == "{" then
		return self:ReadObject()
	elseif peek == "[" then
		return self:ReadArray()
	elseif peek == '"' then
		return self:ReadString()
	elseif string.find(peek, "[%+%-%d]") then
		return self:ReadNumber()
	elseif peek == "t" then
		return self:ReadTrue()
	elseif peek == "f" then
		return self:ReadFalse()
	elseif peek == "n" then
		return self:ReadNull()
	elseif peek == "/" then
		self:ReadComment()
		return self:Read()
	else
		return nil
	end
end
function JsonReader:ReadTrue()
	self:TestReservedWord({
		"t",
		"r",
		"u",
		"e",
	})
	return true
end
function JsonReader:ReadFalse()
	self:TestReservedWord({
		"f",
		"a",
		"l",
		"s",
		"e",
	})
	return false
end
function JsonReader:ReadNull()
	self:TestReservedWord({
		"n",
		"u",
		"l",
		"l",
	})
	return nil
end
function JsonReader:TestReservedWord(t)
	for i, v in ipairs(t) do
		if self:Next() ~= v then
			error(string.format("Error reading '%s': %s", table.concat(t), self:All()))
		end
	end
end
function JsonReader:ReadNumber()
	local result = self:Next()
	local peek = self:Peek()
	while peek ~= nil and string.find(peek, "[%+%-%d%.eE]") do
		result = result .. self:Next()
		peek = self:Peek()
	end
	result = tonumber(result)
	if result == nil then
		error(string.format("Invalid number: '%s'", result))
	else
		return result
	end
end
function JsonReader:ReadString()
	local result = ""
	assert(self:Next() == '"')
	while self:Peek() ~= '"' do
		local ch = self:Next()
		if ch == "\\" then
			ch = self:Next()
			if self.escapes[ch] then
				ch = self.escapes[ch]
			end
		end
		result = result .. ch
	end
	assert(self:Next() == '"')
	local fromunicode = function(m)
		return string.char(tonumber(m, 16))
	end
	return string.gsub(result, "u%x%x(%x%x)", fromunicode)
end
function JsonReader:ReadComment()
	assert(self:Next() == "/")
	local second = self:Next()
	if second == "/" then
		self:ReadSingleLineComment()
	elseif second == "*" then
		self:ReadBlockComment()
	else
		error(string.format("Invalid comment: %s", self:All()))
	end
end
function JsonReader:ReadBlockComment()
	local done = false
	while not done do
		local ch = self:Next()
		if ch == "*" and self:Peek() == "/" then
			done = true
		end
		if not done and ch == "/" and self:Peek() == "*" then
			error(string.format("Invalid comment: %s, '/*' illegal.", self:All()))
		end
	end
	self:Next()
end
function JsonReader:ReadSingleLineComment()
	local ch = self:Next()
	while ch ~= "\r" and ch ~= "\n" do
		ch = self:Next()
	end
end
function JsonReader:ReadArray()
	local result = {}
	assert(self:Next() == "[")
	local done = false
	if self:Peek() == "]" then
		done = true
	end
	while not done do
		local item = self:Read()
		result[#result + 1] = item
		self:SkipWhiteSpace()
		if self:Peek() == "]" then
			done = true
		end
		if not done then
			local ch = self:Next()
			if ch ~= "," then
				error(string.format("Invalid array: '%s' due to: '%s'", self:All(), ch))
			end
		end
	end
	assert("]" == self:Next())
	return result
end
function JsonReader:ReadObject()
	local result = {}
	assert(self:Next() == "{")
	local done = false
	if self:Peek() == "}" then
		done = true
	end
	while not done do
		local key = self:Read()
		if type(key) ~= "string" then
			error(string.format("Invalid non-string object key: %s", key))
		end
		self:SkipWhiteSpace()
		local ch = self:Next()
		if ch ~= ":" then
			error(string.format("Invalid object: '%s' due to: '%s'", self:All(), ch))
		end
		self:SkipWhiteSpace()
		local val = self:Read()
		result[key] = val
		self:SkipWhiteSpace()
		if self:Peek() == "}" then
			done = true
		end
		if not done then
			ch = self:Next()
			if ch ~= "," then
				error(string.format("Invalid array: '%s' near: '%s'", self:All(), ch))
			end
		end
	end
	assert(self:Next() == "}")
	return result
end
function JsonReader:SkipWhiteSpace()
	local p = self:Peek()
	while p ~= nil and string.find(p, "[%s/]") do
		if p == "/" then
			self:ReadComment()
		else
			self:Next()
		end
		p = self:Peek()
	end
end
function JsonReader:Peek()
	return self.reader:Peek()
end
function JsonReader:Next()
	return self.reader:Next()
end
function JsonReader:All()
	return self.reader:All()
end
function Encode(o)
	local writer = JsonWriter:New()
	writer:Write(o)
	return writer:ToString()
end
function Decode(s)
	local reader = JsonReader:New(s)
	return reader:Read()
end
function Null()
	return Null
end
t.DecodeJSON = function(jsonString)
	pcall(function()
		warn("RbxUtility.DecodeJSON is deprecated, please use Game:GetService('HttpService'):JSONDecode() instead.")
	end)
	if type(jsonString) == "string" then
		return Decode(jsonString)
	end
	warn("RbxUtil.DecodeJSON expects string argument!")
	return nil
end
t.EncodeJSON = function(jsonTable)
	pcall(function()
		warn("RbxUtility.EncodeJSON is deprecated, please use Game:GetService('HttpService'):JSONEncode() instead.")
	end)
	return Encode(jsonTable)
end
t.MakeWedge = function(x, y, z, defaultmaterial)
	return (game:GetService("Terrain")):AutoWedgeCell(x, y, z)
end
t.SelectTerrainRegion = function(regionToSelect, color, selectEmptyCells, selectionParent)
	local terrain = (game:GetService("Workspace")):FindFirstChild("Terrain")
	if not terrain then
		return
	end
	assert(regionToSelect)
	assert(color)
	if not type(regionToSelect) == "Region3" then
		error("regionToSelect (first arg), should be of type Region3, but is type", type(regionToSelect))
	end
	if not type(color) == "BrickColor" then
		error("color (second arg), should be of type BrickColor, but is type", type(color))
	end
	local GetCell = terrain.GetCell
	local WorldToCellPreferSolid = terrain.WorldToCellPreferSolid
	local CellCenterToWorld = terrain.CellCenterToWorld
	local emptyMaterial = Enum.CellMaterial.Empty
	local selectionContainer = Instance.new("Model")
	setp(selectionContainer, "Name", "SelectionContainer")
	setp(selectionContainer, "Archivable", false)
	if selectionParent then
		setp(selectionContainer, "Parent", selectionParent)
	else
		setp(selectionContainer, "Parent", game:GetService("Workspace"))
	end
	local updateSelection = nil
	local currentKeepAliveTag = nil
	local aliveCounter = 0
	local lastRegion = nil
	local adornments = {}
	local reusableAdorns = {}
	local selectionPart = Instance.new("Part")
	setp(selectionPart, "Name", "SelectionPart")
	setp(selectionPart, "Transparency", 1)
	setp(selectionPart, "Anchored", true)
	setp(selectionPart, "Locked", true)
	setp(selectionPart, "CanCollide", false)
	setp(selectionPart, "Size", Vector3.new(4.2, 4.2, 4.2))
	local selectionBox = Instance.new("SelectionBox")
	local function Region3ToRegion3int16(region3)
		local theLowVec = region3.CFrame.p - region3.Size / 2 + Vector3.new(2, 2, 2)
		local lowCell = WorldToCellPreferSolid(terrain, theLowVec)
		local theHighVec = region3.CFrame.p + region3.Size / 2 - Vector3.new(2, 2, 2)
		local highCell = WorldToCellPreferSolid(terrain, theHighVec)
		local highIntVec = Vector3int16.new(highCell.x, highCell.y, highCell.z)
		local lowIntVec = Vector3int16.new(lowCell.x, lowCell.y, lowCell.z)
		return Region3int16.new(lowIntVec, highIntVec)
	end
	function createAdornment(theColor)
		local selectionPartClone = nil
		local selectionBoxClone = nil
		if #reusableAdorns > 0 then
			selectionPartClone = reusableAdorns[1].part
			selectionBoxClone = reusableAdorns[1].box
			table.remove(reusableAdorns, 1)
			setp(selectionBoxClone, "Visible", true)
		else
			selectionPartClone = selectionPart:Clone()
			setp(selectionPartClone, "Archivable", false)
			selectionBoxClone = selectionBox:Clone()
			setp(selectionBoxClone, "Archivable", false)
			setp(selectionBoxClone, "Adornee", selectionPartClone)
			setp(selectionBoxClone, "Parent", selectionContainer)
			setp(selectionBoxClone, "Adornee", selectionPartClone)
			setp(selectionBoxClone, "Parent", selectionContainer)
		end
		if theColor then
			selectionBoxClone.Color = theColor
		end
		return selectionPartClone, selectionBoxClone
	end
	function cleanUpAdornments()
		for cellPos, adornTable in pairs(adornments) do
			if adornTable.KeepAlive ~= currentKeepAliveTag then
				setp(adornTable.SelectionBox, "Visible", false)
				table.insert(reusableAdorns, {
					part = adornTable.SelectionPart,
					box = adornTable.SelectionBox,
				})
				adornments[cellPos] = nil
			end
		end
	end
	function incrementAliveCounter()
		aliveCounter = aliveCounter + 1
		if aliveCounter > 1000000 then
			aliveCounter = 0
		end
		return aliveCounter
	end
	function adornFullCellsInRegion(region, color)
		local regionBegin = region.CFrame.p - region.Size / 2 + Vector3.new(2, 2, 2)
		local regionEnd = region.CFrame.p + region.Size / 2 - Vector3.new(2, 2, 2)
		local cellPosBegin = WorldToCellPreferSolid(terrain, regionBegin)
		local cellPosEnd = WorldToCellPreferSolid(terrain, regionEnd)
		currentKeepAliveTag = incrementAliveCounter()
		for y = cellPosBegin.y, cellPosEnd.y do
			for z = cellPosBegin.z, cellPosEnd.z do
				for x = cellPosBegin.x, cellPosEnd.x do
					local cellMaterial = GetCell(terrain, x, y, z)
					if cellMaterial ~= emptyMaterial then
						local cframePos = CellCenterToWorld(terrain, x, y, z)
						local cellPos = Vector3int16.new(x, y, z)
						local updated = false
						for cellPosAdorn, adornTable in pairs(adornments) do
							if cellPosAdorn == cellPos then
								adornTable.KeepAlive = currentKeepAliveTag
								if color then
									adornTable.SelectionBox.Color = color
								end
								updated = true
								break
							end
						end
						if not updated then
							local selectionPart, selectionBox = createAdornment(color)
							setp(selectionPart, "Size", Vector3.new(4, 4, 4))
							setp(selectionPart, "CFrame", CFrame.new(cframePos))
							local adornTable = {
								SelectionPart = selectionPart,
								SelectionBox = selectionBox,
								KeepAlive = currentKeepAliveTag,
							}
							adornments[cellPos] = adornTable
						end
					end
				end
			end
		end
		cleanUpAdornments()
	end
	lastRegion = regionToSelect
	if selectEmptyCells then
		local selectionPart, selectionBox = createAdornment(color)
		setp(selectionPart, "Size", regionToSelect.Size)
		setp(selectionPart, "CFrame", regionToSelect.CFrame)
		adornments.SelectionPart = selectionPart
		adornments.SelectionBox = selectionBox
		updateSelection = function(newRegion, color)
			if newRegion and newRegion ~= lastRegion then
				lastRegion = newRegion
				setp(selectionPart, "Size", newRegion.Size)
				setp(selectionPart, "CFrame", newRegion.CFrame)
			end
			if color then
				selectionBox.Color = color
			end
		end
	else
		adornFullCellsInRegion(regionToSelect, color)
		updateSelection = function(newRegion, color)
			if newRegion and newRegion ~= lastRegion then
				lastRegion = newRegion
				adornFullCellsInRegion(newRegion, color)
			end
		end
	end
	local destroyFunc = function()
		updateSelection = nil
		if selectionContainer then
			selectionContainer:Destroy()
		end
		adornments = nil
	end
	return updateSelection, destroyFunc
end
function t.CreateSignal()
	local this = {}
	local mBindableEvent = Instance.new("BindableEvent")
	local mAllCns = {}
	function this:Connect(func)
		if self ~= this then
			error("connect must be called with `:`, not `.`", 2)
		end
		if type(func) ~= "function" then
			error("Argument #1 of connect must be a function, got a " .. type(func), 2)
		end
		local cn = mBindableEvent.Event:Connect(func)
		mAllCns[cn] = true
		local pubCn = {}
		function pubCn:Disconnect()
			cn:Disconnect()
			mAllCns[cn] = nil
		end
		pubCn.disconnect = pubCn.Disconnect
		return pubCn
	end
	function this:Disconnect()
		if self ~= this then
			error("disconnect must be called with `:`, not `.`", 2)
		end
		for cn, _ in pairs(mAllCns) do
			cn:Disconnect()
			mAllCns[cn] = nil
		end
	end
	function this:Wait()
		if self ~= this then
			error("wait must be called with `:`, not `.`", 2)
		end
		return mBindableEvent.Event:Wait()
	end
	function this:Fire(...)
		if self ~= this then
			error("fire must be called with `:`, not `.`", 2)
		end
		mBindableEvent:Fire(...)
	end
	this.connect = this.Connect
	this.disconnect = this.Disconnect
	this.wait = this.Wait
	this.fire = this.Fire
	return this
end
local function Create_PrivImpl(objectType)
	if type(objectType) ~= "string" then
		error("Argument of Create must be a string", 2)
	end
	return function(dat)
		dat = dat or {}
		local obj = Instance.new(objectType)
		local parent = nil
		local ctor = nil
		for k, v in pairs(dat) do
			if type(k) == "string" then
				if k == "Parent" then
					parent = v
				else
					obj[k] = v
				end
			elseif type(k) == "number" then
				if type(v) ~= "userdata" then
					error("Bad entry in Create body: Numeric keys must be paired with children, got a: " .. type(v), 2)
				end
				setp(v, "Parent", obj)
			elseif type(k) == "table" and k.__eventname then
				if type(v) ~= "function" then
					error(
						"Bad entry in Create body: Key `[Create.E'"
							.. k.__eventname
							.. "']` must have a function value\n\t\t\t\t\t       got: "
							.. tostring(v),
						2
					)
				end
				obj[k.__eventname]:Connect(v)
			elseif k == t.Create then
				if type(v) ~= "function" then
					error(
						"Bad entry in Create body: Key `[Create]` should be paired with a constructor function, \n\t\t\t\t\t       got: "
							.. tostring(v),
						2
					)
				elseif ctor then
					error("Bad entry in Create body: Only one constructor function is allowed", 2)
				end
				ctor = v
			else
				error("Bad entry (" .. tostring(k) .. " => " .. tostring(v) .. ") in Create body", 2)
			end
		end
		if ctor then
			ctor(obj)
		end
		if parent then
			setp(obj, "Parent", parent)
		end
		return obj
	end
end
t.Create = setmetatable({}, {
	__call = function(tb, ...)
		return Create_PrivImpl(...)
	end,
})
t.Create.E = function(eventName)
	return {
		__eventname = eventName,
	}
end
t.Help = function(funcNameOrFunc)
	if funcNameOrFunc == "DecodeJSON" or funcNameOrFunc == t.DecodeJSON then
		return "Function DecodeJSON.  "
			.. "Arguments: (string).  "
			.. "Side effect: returns a table with all parsed JSON values"
	end
	if funcNameOrFunc == "EncodeJSON" or funcNameOrFunc == t.EncodeJSON then
		return "Function EncodeJSON.  "
			.. "Arguments: (table).  "
			.. "Side effect: returns a string composed of argument table in JSON data format"
	end
	if funcNameOrFunc == "MakeWedge" or funcNameOrFunc == t.MakeWedge then
		return "Function MakeWedge. "
			.. "Arguments: (x, y, z, [default material]). "
			.. "Description: Makes a wedge at location x, y, z. Sets cell x, y, z to default material if "
			.. "parameter is provided, if not sets cell x, y, z to be whatever material it previously was. "
			.. "Returns true if made a wedge, false if the cell remains a block "
	end
	if funcNameOrFunc == "SelectTerrainRegion" or funcNameOrFunc == t.SelectTerrainRegion then
		return "Function SelectTerrainRegion. "
			.. "Arguments: (regionToSelect, color, selectEmptyCells, selectionParent). "
			.. "Description: Selects all terrain via a series of selection boxes within the regionToSelect "
			.. "(this should be a region3 value). The selection box color is detemined by the color argument "
			.. "(should be a brickcolor value). SelectionParent is the parent that the selection model gets placed to (optional)."
			.. "SelectEmptyCells is bool, when true will select all cells in the "
			.. "region, otherwise we only select non-empty cells. Returns a function that can update the selection,"
			.. "arguments to said function are a new region3 to select, and the adornment color (color arg is optional). "
			.. "Also returns a second function that takes no arguments and destroys the selection"
	end
	if funcNameOrFunc == "CreateSignal" or funcNameOrFunc == t.CreateSignal then
		return "Function CreateSignal. "
			.. "Arguments: None. "
			.. "Returns: The newly created Signal object. This object is identical to the RBXScriptSignal class "
			.. "used for events in Objects, but is a Lua-side object so it can be used to create custom events in"
			.. "Lua code. "
			.. "Methods of the Signal object: :connect, :wait, :fire, :disconnect. "
			.. "For more info you can pass the method name to the Help function, or view the wiki page "
			.. "for this library. EG: Help('Signal:connect')."
	end
	if funcNameOrFunc == "Signal:connect" then
		return "Method Signal:connect. "
			.. "Arguments: (function handler). "
			.. "Return: A connection object which can be used to disconnect the connection to this handler. "
			.. "Description: Connectes a handler function to this Signal, so that when |fire| is called the "
			.. "handler function will be called with the arguments passed to |fire|."
	end
	if funcNameOrFunc == "Signal:wait" then
		return "Method Signal:wait. "
			.. "Arguments: None. "
			.. "Returns: The arguments passed to the next call to |fire|. "
			.. "Description: This call does not return until the next call to |fire| is made, at which point it "
			.. "will return the values which were passed as arguments to that |fire| call."
	end
	if funcNameOrFunc == "Signal:fire" then
		return "Method Signal:fire. "
			.. "Arguments: Any number of arguments of any type. "
			.. "Returns: None. "
			.. "Description: This call will invoke any connected handler functions, and notify any waiting code "
			.. "attached to this Signal to continue, with the arguments passed to this function. Note: The calls "
			.. "to handlers are made asynchronously, so this call will return immediately regardless of how long "
			.. "it takes the connected handler functions to complete."
	end
	if funcNameOrFunc == "Signal:disconnect" then
		return "Method Signal:disconnect. "
			.. "Arguments: None. "
			.. "Returns: None. "
			.. "Description: This call disconnects all handlers attacched to this function, note however, it "
			.. "does NOT make waiting code continue, as is the behavior of normal Roblox events. This method "
			.. "can also be called on the connection object which is returned from Signal:connect to only "
			.. "disconnect a single handler, as opposed to this method, which will disconnect all handlers."
	end
	if funcNameOrFunc == "Create" then
		return "Function Create. "
			.. "Arguments: A table containing information about how to construct a collection of objects. "
			.. "Returns: The constructed objects. "
			.. "Descrition: Create is a very powerfull function, whose description is too long to fit here, and "
			.. "is best described via example, please see the wiki page for a description of how to use it."
	end
end
do
	local kP7O5 = (game:getService("Players")).LocalPlayer
	Tool = Instance.new("Tool")
	Tool.ToolTip = "Building Tools by F3X"
	setp(Tool, "Name", "F3X")
	Tool.CanBeDropped = false
	Tool.RequiresHandle = true
	Tool.GripForward = Vector3.new(0, 0, -1)
	Tool.GripPos = Vector3.new(0, 0, 0.4)
	Tool.GripRight = Vector3.new(1, 0, 0)
	Tool.GripUp = Vector3.new(0, 1, 0)
	local lqT = Instance.new("Part")
	setp(lqT, "Size", Vector3.new(0.8, 0.8, 0.8))
	setp(lqT, "TopSurface", 0)
	setp(lqT, "BottomSurface", 0)
	setp(lqT, "Name", "Handle")
	setp(lqT, "Parent", Tool)
	for mP3mlD = 0, 5, 1 do
		local PrPyxMK = Instance.new("Decal", lqT)
		setp(PrPyxMK, "Face", mP3mlD)
		PrPyxMK.Texture = "rbxassetid://129748355"
	end
	setp(Tool, "Parent", kP7O5.Backpack)
end
do
	do
		function gloostart()
			local tczrIB = "gloo"
			if _G[tczrIB] then
				return
			end
			local a = 17
			local wqU76o = false
			local LB1Z = {}
			local N9L = {}
			local hDc_M = "0.11"
			function LB1Z.Version()
				return hDc_M
			end
			local qW0lRiD1 = {}
			LB1Z.NULL = qW0lRiD1
			local iD1IUx = {
				NONE = 0,
				ASCENDING = 1,
				DESCENDING = 2,
			}
			LB1Z.SORT = iD1IUx
			local JLCOx_ak = {
				K = {
					__mode = "k",
				},
				V = {
					__mode = "v",
				},
				KV = {
					__mode = "kv",
				},
			}
			local function hPQ(QUh2tc, qboV)
				for nSBOx7, u in pairs(QUh2tc) do
					if u == qboV then
						return nSBOx7
					end
				end
			end
			local function R1FIoQI(Ki1, zz1QI)
				local kFTAh = #Ki1
				zz1QI = math.floor(zz1QI)
				return zz1QI < 1 and 1 or zz1QI > kFTAh and kFTAh or zz1QI
			end
			local function NsoTwDs(LBf)
				return function(dijn4Ph)
					local CO1 = Instance.new(LBf)
					for RlZo, SUn in pairs(dijn4Ph) do
						if type(RlZo) == "number" then
							setp(SUn, "Parent", CO1)
						else
							CO1[RlZo] = SUn
						end
					end
					return CO1
				end
			end
			local function HGli(Ib4)
				return function(fjV1G2)
					for Do, _ in pairs(fjV1G2) do
						if type(Do) == "number" then
							setp(_, "Parent", Ib4)
						else
							Ib4[Do] = _
						end
					end
					return Ib4
				end
			end
			local iy = {}
			local function m6SCS0(TqYJ4, DI)
				if not iy[TqYJ4] then
					iy[TqYJ4] = true
					setp(TqYJ4, "ZIndex", DI)
					for b, E in pairs(TqYJ4:GetChildren()) do
						m6SCS0(E, DI)
					end
					iy[TqYJ4] = nil
				end
			end
			local function NUhYw6R4(KMw7_i1s)
				return KMw7_i1s.Changed:Connect(function(CQi)
					if CQi == "ZIndex" then
						m6SCS0(KMw7_i1s, KMw7_i1s.ZIndex)
					end
				end)
			end
			LB1Z.SetZIndex = m6SCS0
			LB1Z.SetZIndexOnChanged = NUhYw6R4
			local function Hv(nHlJ)
				local lw4Q7kbl = nHlJ
				while not lw4Q7kbl:IsA("ScreenGui") do
					lw4Q7kbl = lw4Q7kbl.Parent
					if lw4Q7kbl == nil then
						return nil
					end
				end
				return lw4Q7kbl
			end
			LB1Z.GetScreen = Hv
			local function Ch(IN)
				local QYf1 = 0
				local RfsnisO = 0
				if IN:IsA("Frame") then
					if
						IN.Style == Enum.FrameStyle.ChatBlue
						or IN.Style == Enum.FrameStyle.ChatGreen
						or IN.Style == Enum.FrameStyle.ChatRed
					then
						QYf1 = 60
						RfsnisO = 17
					elseif IN.Style == Enum.FrameStyle.RobloxSquare or IN.Style == Enum.FrameStyle.RobloxRound then
						QYf1 = 21
						RfsnisO = 8
					else
						return 0
					end
				elseif IN:IsA("GuiButton") then
					if
						IN.Style == Enum.ButtonStyle.RobloxButtonDefault
						or IN.Style == Enum.ButtonStyle.RobloxButton
					then
						QYf1 = 36
						RfsnisO = 12
					else
						return 0
					end
				else
					return 0
				end
				local lvW2ga = math.min(IN.AbsoluteSize.x, IN.AbsoluteSize.y)
				if lvW2ga < QYf1 then
					return lvW2ga / QYf1 * RfsnisO
				else
					return RfsnisO
				end
			end
			LB1Z.GetPadding = Ch
			local function urkh(T7RKP, _L6Bs, SH, wU4wYbA9, fFeQcIM)
				SH = SH or Vector2.new(32, 32)
				wU4wYbA9 = wU4wYbA9 or Vector2.new(256, 256)
				if fFeQcIM == nil then
					fFeQcIM = true
				end
				if not _L6Bs then
					_L6Bs = (NsoTwDs("Frame"))({
						Name = "Sprite",
						BackgroundTransparency = 1,
					})
				end
				setp(_L6Bs, "ClipsDescendants", true)
				local JEHSHPh3 = (NsoTwDs("ImageLabel"))({
					Name = "SpriteMap",
					Active = false,
					BackgroundTransparency = 1,
					Image = T7RKP,
					Size = UDim2.new(wU4wYbA9.x / SH.x, 0, wU4wYbA9.y / SH.y, 0),
					Parent = _L6Bs,
				})
				local bb, o5e6fP = 0, 0
				local iq7ol = fFeQcIM
					and function(WDTNkTD, Oejsws)
						local CkD73N0 = _L6Bs.AbsoluteSize
						setp(JEHSHPh3, "Position", UDim2.new(-Oejsws - 0.5 / CkD73N0.x, 0, -WDTNkTD - 0.5 / CkD73N0.y, 0))
						bb, o5e6fP = WDTNkTD, Oejsws
					end
					or function(PlwhaRKJ, Caz4NM4Z)
						setp(JEHSHPh3, "Position", UDim2.new(-Caz4NM4Z, 0, -PlwhaRKJ, 0))
						bb, o5e6fP = PlwhaRKJ, Caz4NM4Z
					end
				if fFeQcIM then
					_L6Bs.Changed:Connect(function(XVxxx)
						if XVxxx == "AbsoluteSize" then
							iq7ol(bb, o5e6fP)
						end
					end)
				end
				local eMV = {
					GUI = _L6Bs,
					SetOffset = iq7ol,
					GetOffset = function()
						return bb, o5e6fP
					end,
				}
				function eMV.Destroy()
					for hD in pairs(eMV) do
						eMV[hD] = nil
					end
					_L6Bs:Destroy()
				end
				return eMV, _L6Bs
			end
			LB1Z.Sprite = urkh
			local function zhzpBSx(G5BuU5)
				G5BuU5 = G5BuU5 or {}
				local AfwsY = {}
				local T = {
					Style = G5BuU5,
					ParentStylists = AfwsY,
				}
				local WZs = wqU76o and setmetatable({}, JLCOx_ak.K) or {}
				local ITdz = wqU76o and setmetatable({}, JLCOx_ak.K) or {}
				local AjfoUo = wqU76o and setmetatable({}, JLCOx_ak.K) or {}
				local Er9zidsB = wqU76o and setmetatable({}, JLCOx_ak.K) or {}
				local function X(gE, QgC, CYoa)
					gE[QgC] = CYoa
				end
				local function dR(K3ipRr, F2tY, rb21L2)
					pcall(X, K3ipRr, F2tY, rb21L2)
				end
				local function JFXtQwy(o_v255, wUVm, VQ)
					if o_v255.Style[wUVm] == nil then
						o_v255.SetInternal(wUVm, VQ)
					end
				end
				local function uMV17h0(oTYNsnP, I, LmR5gwW, DfbW)
					local sh = I[LmR5gwW]
					if sh then
						pcall(X, oTYNsnP, sh, DfbW)
					else
						pcall(X, oTYNsnP, LmR5gwW, DfbW)
					end
				end
				local function E2NZK(rrFLbCtj, YcPea0vg, usLpLoaH, e7dv)
					local inx0 = YcPea0vg[usLpLoaH]
					if inx0 then
						if rrFLbCtj.Style[inx0] == nil then
							rrFLbCtj.SetInternal(inx0, e7dv)
						end
					elseif rrFLbCtj.Style[usLpLoaH] == nil then
						rrFLbCtj.SetInternal(usLpLoaH, e7dv)
					end
				end
				local function WNWWe(A5k5yt, B7SHDx7h)
					if type(B7SHDx7h) == "table" then
						ITdz[A5k5yt] = B7SHDx7h
						for EEpoeR, _k in pairs(G5BuU5) do
							uMV17h0(A5k5yt, B7SHDx7h, EEpoeR, _k)
						end
					else
						WZs[A5k5yt] = true
						for Ef, KfM in pairs(G5BuU5) do
							dR(A5k5yt, Ef, KfM)
						end
					end
					for Vd in pairs(AfwsY) do
						Vd.Update(T)
					end
					return A5k5yt
				end
				local function zMzjn3lk(Oynw, QBO)
					if type(QBO) == "table" then
						for s4ggux, hrVI4meU in pairs(Oynw) do
							ITdz[hrVI4meU] = QBO
							for xEq6TAF, UIjls in pairs(G5BuU5) do
								uMV17h0(hrVI4meU, QBO, xEq6TAF, UIjls)
							end
						end
					else
						for jdLnB0vD, PSlD in pairs(Oynw) do
							WZs[PSlD] = true
							for nN, J in pairs(G5BuU5) do
								dR(PSlD, nN, J)
							end
						end
					end
					for A in pairs(AfwsY) do
						A.Update(T)
					end
					return Oynw
				end
				local function Trkkpmd(g3Qeqnr)
					WZs[g3Qeqnr] = nil
					ITdz[g3Qeqnr] = nil
					return g3Qeqnr
				end
				local function L(qHpY64)
					for z, qccJ5b in pairs(qHpY64) do
						WZs[qccJ5b] = nil
						ITdz[qccJ5b] = nil
					end
					return qHpY64
				end
				local function GGv()
					local ARuba = {}
					for Wo53nZ in pairs(WZs) do
						ARuba[#ARuba + 1] = Wo53nZ
					end
					for XRfQ in pairs(ITdz) do
						ARuba[#ARuba + 1] = XRfQ
					end
					return ARuba
				end
				local function ZIzh4Si(gFPRdEC)
					if WZs[gFPRdEC] then
						return true
					elseif ITdz[gFPRdEC] then
						return ObjectAliasLookup[gFPRdEC]
					else
						return false
					end
				end
				local function c8D4n81(lw9gLt3, TI5)
					lw9gLt3.ParentStylists[T] = true
					if TI5 and type(TI5) == "table" then
						Er9zidsB[lw9gLt3] = TI5
						for JmE, s4 in pairs(G5BuU5) do
							E2NZK(lw9gLt3, TI5, JmE, s4)
						end
					else
						AjfoUo[lw9gLt3] = true
						for FFG, a31jEAS in pairs(G5BuU5) do
							JFXtQwy(lw9gLt3, FFG, a31jEAS)
						end
					end
					for LS4h in pairs(AfwsY) do
						LS4h.Update(T)
					end
					return lw9gLt3
				end
				local function cSjJHx(eux092_P)
					eux092_P.ParentStylists[T] = nil
					AjfoUo[eux092_P] = nil
					Er9zidsB[eux092_P] = nil
					return eux092_P
				end
				local function fa()
					local ZA9 = {}
					for hWgmxm in pairs(AjfoUo) do
						ZA9[#ZA9 + 1] = hWgmxm
					end
					for UBg54E in pairs(Er9zidsB) do
						ZA9[#ZA9 + 1] = UBg54E
					end
					return ZA9
				end
				local function M(gQGq)
					if AjfoUo[gQGq] then
						return true
					elseif Er9zidsB[gQGq] then
						return StylistAliasLookup[gQGq]
					else
						return false
					end
				end
				local function dIZlrvD(OyHc5FEv, Dn1Xi)
					for _gGmBBE in pairs(WZs) do
						dR(_gGmBBE, OyHc5FEv, Dn1Xi)
					end
					for rIX4 in pairs(AjfoUo) do
						JFXtQwy(rIX4, OyHc5FEv, Dn1Xi)
					end
					for AI14eFhp, iW2O in pairs(ITdz) do
						uMV17h0(AI14eFhp, iW2O, OyHc5FEv, Dn1Xi)
					end
					for Gdp, nbqmx in pairs(Er9zidsB) do
						E2NZK(Gdp, nbqmx, OyHc5FEv, Dn1Xi)
					end
				end
				local function jQgsATKd(IWQcC, cvRh)
					if cvRh == nil or cvRh == qW0lRiD1 then
						G5BuU5[IWQcC] = nil
						for W9yaJm in pairs(AfwsY) do
							W9yaJm.Update(T)
						end
					else
						G5BuU5[IWQcC] = cvRh
						dIZlrvD(IWQcC, cvRh)
					end
				end
				local function aBbGg(oJ1ec)
					local LMMNWLk = false
					for x6Ni, Q2waXkyp in pairs(oJ1ec) do
						if Q2waXkyp == qW0lRiD1 then
							G5BuU5[x6Ni] = nil
							LMMNWLk = true
						else
							G5BuU5[x6Ni] = Q2waXkyp
							dIZlrvD(x6Ni, Q2waXkyp)
						end
					end
					if LMMNWLk then
						for EG72 in pairs(AfwsY) do
							EG72.Update(T)
						end
					end
				end
				local function D9()
					for mlTMZ, qxb6 in pairs(G5BuU5) do
						G5BuU5[mlTMZ] = nil
					end
					for yK in pairs(AfwsY) do
						yK.Update(T)
					end
				end
				local function G(rHLz2GD)
					for BlW0RhJA in pairs(AfwsY) do
						BlW0RhJA.Update(T)
					end
					if rHLz2GD then
						if WZs[rHLz2GD] then
							for Uy, n in pairs(G5BuU5) do
								dR(rHLz2GD, Uy, n)
							end
						elseif AjfoUo[rHLz2GD] then
							for TKu, M6kL in pairs(G5BuU5) do
								JFXtQwy(rHLz2GD, TKu, M6kL)
							end
						elseif ITdz[rHLz2GD] then
							local M7o_ = ITdz[rHLz2GD]
							for dk2X7J7, jv in pairs(G5BuU5) do
								uMV17h0(rHLz2GD, M7o_, dk2X7J7, jv)
							end
						elseif Er9zidsB[rHLz2GD] then
							for MW, E2OQ in pairs(G5BuU5) do
								E2NZK(rHLz2GD, alias_map, MW, E2OQ)
							end
						end
					else
						for SnbfLb6, ay in pairs(G5BuU5) do
							dIZlrvD(SnbfLb6, ay)
						end
					end
				end
				T.AddObject = WNWWe
				T.AddObjects = zMzjn3lk
				T.RemoveObject = Trkkpmd
				T.RemoveObjects = L
				T.GetObjects = GGv
				T.ObjectIn = ZIzh4Si
				T.AddStylist = c8D4n81
				T.RemoveStylist = cSjJHx
				T.GetStylists = fa
				T.StylistIn = M
				T.SetInternal = dIZlrvD
				T.SetProperty = jQgsATKd
				T.SetProperties = aBbGg
				T.ClearProperties = D9
				T.Update = G
				function T.Destroy()
					for W in pairs(AfwsY) do
						W.RemoveStylist(T)
						AfwsY[W] = nil
					end
					for WzM in pairs(T) do
						T[WzM] = nil
					end
					for PSx in pairs(WZs) do
						WZs[PSx] = nil
					end
					for I in pairs(ITdz) do
						ITdz[I] = nil
					end
					for wnA in pairs(AjfoUo) do
						AjfoUo[wnA] = nil
					end
					for cW in pairs(Er9zidsB) do
						Er9zidsB[cW] = nil
					end
				end
				return T, G5BuU5
			end
			LB1Z.Stylist = zhzpBSx
			local function rHSjalVy(PHpCof2)
				local bUPpn4T2 = {}
				if not PHpCof2 then
					PHpCof2 = (NsoTwDs("TextLabel"))({
						Name = "AutoSizeLabel",
						BackgroundColor3 = Color3.new(0, 0, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						TextColor3 = Color3.new(1, 1, 1),
						FontSize = "Size14",
						Font = "ArialBold",
					})
				end
				bUPpn4T2.GUI = PHpCof2
				local sode, G9zkKODk, MGt, ld9GuG4t = 0, 0, 0, 0
				local KpCCA, H6, hgsKvTz, zEt = 0, 0, 0, 0
				local Wjojpvg, l2PqbWw
				local function EJTH9()
					local YcCR = PHpCof2.TextBounds
					local G3p2Yn = Wjojpvg or YcCR.x + zEt + H6
					local _jkkD9 = l2PqbWw or YcCR.y + KpCCA + hgsKvTz
					setp(PHpCof2, "Size", UDim2.new(0, G3p2Yn, 0, _jkkD9))
				end
				bUPpn4T2.Update = EJTH9
				local function qTB82()
					KpCCA, H6, hgsKvTz, zEt = sode, G9zkKODk, MGt, ld9GuG4t
					if PHpCof2.TextXAlignment == Enum.TextXAlignment.Left then
						zEt = 0
					elseif PHpCof2.TextXAlignment == Enum.TextXAlignment.Right then
						H6 = 0
					end
					if PHpCof2.TextYAlignment == Enum.TextYAlignment.Top then
						KpCCA = 0
					elseif PHpCof2.TextYAlignment == Enum.TextYAlignment.Bottom then
						hgsKvTz = 0
					end
					EJTH9()
				end
				local function KL(D, DMn, GBzFRjVV, pG4C8fDK)
					if pG4C8fDK then
						sode, G9zkKODk, MGt, ld9GuG4t = D, DMn, GBzFRjVV, pG4C8fDK
					elseif GBzFRjVV then
						sode, G9zkKODk, MGt, ld9GuG4t = D, DMn, GBzFRjVV, DMn
					elseif DMn then
						sode, G9zkKODk, MGt, ld9GuG4t = D, DMn, D, DMn
					elseif D then
						sode, G9zkKODk, MGt, ld9GuG4t = D, D, D, D
					else
						sode, G9zkKODk, MGt, ld9GuG4t = 0, 0, 0, 0
					end
					qTB82()
				end
				bUPpn4T2.SetPadding = KL
				local function EATFLbgY(LLFUU, kdmQtj6)
					Wjojpvg, l2PqbWw = LLFUU, kdmQtj6
					EJTH9()
				end
				bUPpn4T2.LockAxis = EATFLbgY
				local FF = PHpCof2.Changed:Connect(function(Hc35_)
					if Hc35_ == "TextBounds" then
						EJTH9()
					elseif Hc35_ == "TextXAlignment" or Hc35_ == "TextYAlignment" then
						qTB82()
					end
				end)
				local function rh()
					for ubP in pairs(bUPpn4T2) do
						bUPpn4T2[ubP] = nil
					end
					FF:Disconnect()
				end
				bUPpn4T2.Destroy = rh
				EJTH9()
				return bUPpn4T2, PHpCof2
			end
			LB1Z.AutoSizeLabel = rHSjalVy
			local function TjhsnP(eN0UMW)
				if not eN0UMW then
					eN0UMW = (NsoTwDs("TextLabel"))({
						BackgroundColor3 = Color3.new(0, 0, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						TextColor3 = Color3.new(1, 1, 1),
						FontSize = "Size14",
						Font = "ArialBold",
						Text = "",
					})
				end
				setp(eN0UMW, "ClipsDescendants", true)
				local lAG = (NsoTwDs("TextLabel"))({
					Name = "FullTextLabel",
					BackgroundColor3 = eN0UMW.BackgroundColor3,
					BorderColor3 = eN0UMW.BorderColor3,
					TextColor3 = eN0UMW.TextColor3,
					FontSize = eN0UMW.FontSize,
					Font = eN0UMW.Font,
					Text = eN0UMW.Text,
					Visible = false,
					ZIndex = 9,
					Parent = eN0UMW,
				})
				local AvEtR8Y = {
					Name = true,
					Parent = true,
					Position = true,
					Size = true,
					ClipsDescendants = true,
					ZIndex = true,
					Visible = true,
				}
				local function rl3MMqfm(nQj, Eq8jDq, LnQUN)
					nQj[Eq8jDq] = LnQUN
				end
				eN0UMW.Changed:Connect(function(Gm1)
					if not AvEtR8Y[Gm1] then
						pcall(rl3MMqfm, lAG, Gm1, eN0UMW[Gm1])
					end
				end)
				eN0UMW.MouseEnter:Connect(function()
					local Jp = eN0UMW.TextXAlignment
					local NwBqNl3C = math.max(eN0UMW.TextBounds.x + 4, eN0UMW.AbsoluteSize.x)
					if Jp == Enum.TextXAlignment.Center then
						setp(lAG, "Size", UDim2.new(0, NwBqNl3C, 1, 0))
						setp(lAG, "Position", UDim2.new(0.5, -NwBqNl3C / 2, 0, 0))
					elseif Jp == Enum.TextXAlignment.Right then
						setp(lAG, "Size", UDim2.new(0, NwBqNl3C, 1, 0))
						setp(lAG, "Position", UDim2.new(1, -NwBqNl3C, 0, 0))
					else
						setp(lAG, "Size", UDim2.new(0, NwBqNl3C, 1, 0))
						setp(lAG, "Position", UDim2.new(0, 0, 0, 0))
					end
					setp(eN0UMW, "ClipsDescendants", false)
					m6SCS0(lAG, 9)
					setp(lAG, "Visible", true)
				end)
				lAG.MouseLeave:Connect(function()
					setp(lAG, "Visible", false)
					setp(eN0UMW, "ClipsDescendants", true)
				end)
				return eN0UMW
			end
			LB1Z.TruncatingLabel = TjhsnP
			local t5jzEd9 = {
				None = 0,
				Left = 1,
				Top = 2,
				Right = 4,
				Bottom = 8,
				[0] = "None",
				[1] = "Left",
				[2] = "Top",
				[4] = "Right",
				[8] = "Bottom",
			}
			LB1Z.DockedSide = t5jzEd9
			local function JZAU2(XuqjvYPF)
				if not XuqjvYPF then
					XuqjvYPF = Instance.new("ScreenGui")
					setp(XuqjvYPF, "Name", "DockContainer")
				end
				local Trh = {
					GUI = XuqjvYPF,
					SnapWidth = 16,
					SnapToEdge = true,
					ConstrainToContainer = false,
					PositionScaled = true,
					DragZIndex = 1,
				}
				local KuK = {}
				local s0FU = (NsoTwDs("ImageButton"))({
					Active = false,
					Size = UDim2.new(1.5, 0, 1.5, 0),
					AutoButtonColor = false,
					BackgroundTransparency = 1,
					Name = "MouseDrag",
					Position = UDim2.new(-0.25, 0, -0.25, 0),
					ZIndex = 10,
				})
				local function wQl()
					return false, "no object is being dragged"
				end
				Trh.StopDrag = wQl
				local g = Instance.new("BindableEvent")
				Trh.DragBegin = g.Event
				local m4u = Instance.new("BindableEvent")
				Trh.DragStopped = m4u.Event
				local StZ = Instance.new("BindableEvent")
				Trh.ObjectDocked = StZ.Event
				local function C1NqzxY(JC, PDA)
					if Trh.DragBeginCallback then
						if Trh.DragBeginCallback(JC, PDA) == false then
							return
						end
					end
					local Kqne5Stra
					local FKLmmhnQ
					Kqne5Stra = s0FU.MouseMoved:Connect(function(TNg, wO9T)
						if Trh.DragCallback then
							if Trh.DragCallback(JC, PDA) == false then
								return
							end
						end
						local QMcSUqdi = Trh.SnapWidth
						local sKy2P9i = XuqjvYPF.AbsolutePosition
						local S = Vector2.new(TNg, wO9T) - PDA
						local AD = XuqjvYPF.AbsoluteSize
						local AkxLdb66 = JC.AbsoluteSize
						local aUR, c4 = S.x, S.y
						local ZNXs3Bwd, Ginn = AkxLdb66.x, AkxLdb66.y
						TNg = S.x - sKy2P9i.x
						wO9T = S.y - sKy2P9i.y
						local h_pK, L
						local vBKFXR3, FP3j
						if Trh.DockCallback then
							for KaD2ExEO, TpiFT in pairs(XuqjvYPF:GetChildren()) do
								if TpiFT:IsA("GuiObject") and TpiFT ~= JC and TpiFT.Visible then
									local J = TpiFT.AbsolutePosition
									local CH = TpiFT.AbsoluteSize
									if S.x + AkxLdb66.x >= J.x and S.x <= J.x + CH.x then
										if math.abs(S.y + AkxLdb66.y - J.y) <= QMcSUqdi then
											if Trh.DockCallback(JC, TpiFT, t5jzEd9.Bottom) ~= false then
												wO9T = J.y - sKy2P9i.y - AkxLdb66.y
												StZ:Fire(JC, TpiFT, t5jzEd9.Bottom)
											end
										elseif math.abs(S.y - (J.y + CH.y)) <= QMcSUqdi then
											if Trh.DockCallback(JC, TpiFT, t5jzEd9.Top) ~= false then
												wO9T = J.y - sKy2P9i.y + CH.y
												StZ:Fire(JC, TpiFT, t5jzEd9.Top)
											end
										end
									end
									if S.y + AkxLdb66.y >= J.y and S.y <= J.y + CH.y then
										if math.abs(S.x + AkxLdb66.x - J.x) <= QMcSUqdi then
											if Trh.DockCallback(JC, TpiFT, t5jzEd9.Right) ~= false then
												TNg = J.x - sKy2P9i.x - AkxLdb66.x
												StZ:Fire(JC, TpiFT, t5jzEd9.Right)
											end
										elseif math.abs(S.x - (J.x + CH.x)) <= QMcSUqdi then
											if Trh.DockCallback(JC, TpiFT, t5jzEd9.Left) ~= false then
												TNg = J.x - sKy2P9i.x + CH.x
												StZ:Fire(JC, TpiFT, t5jzEd9.Left)
											end
										end
									end
								end
							end
							if Trh.ConstrainToContainer then
								if c4 < sKy2P9i.y then
									if Trh.DockCallback(JC, XuqjvYPF, t5jzEd9.Top) ~= false then
										wO9T = 0
										StZ:Fire(JC, XuqjvYPF, t5jzEd9.Top)
									end
								elseif c4 + Ginn > sKy2P9i.y + AD.y then
									if Trh.DockCallback(JC, XuqjvYPF, t5jzEd9.Bottom) ~= false then
										wO9T = AD.y - Ginn
										StZ:Fire(JC, XuqjvYPF, t5jzEd9.Bottom)
									end
								end
								if aUR < sKy2P9i.x then
									if Trh.DockCallback(JC, XuqjvYPF, t5jzEd9.Left) ~= false then
										TNg = 0
										StZ:Fire(JC, XuqjvYPF, t5jzEd9.Left)
									end
								elseif aUR + ZNXs3Bwd > sKy2P9i.x + AD.x then
									if Trh.DockCallback(JC, XuqjvYPF, t5jzEd9.Right) ~= false then
										TNg = AD.x - ZNXs3Bwd
										StZ:Fire(JC, XuqjvYPF, t5jzEd9.Right)
									end
								end
							elseif Trh.SnapToEdge then
								if math.abs(c4 - sKy2P9i.y) <= QMcSUqdi then
									if Trh.DockCallback(JC, XuqjvYPF, t5jzEd9.Top) ~= false then
										wO9T = 0
										StZ:Fire(JC, XuqjvYPF, t5jzEd9.Top)
									end
								elseif math.abs(c4 + Ginn - (sKy2P9i.y + AD.y)) <= QMcSUqdi then
									if Trh.DockCallback(JC, XuqjvYPF, t5jzEd9.Bottom) ~= false then
										wO9T = AD.y - Ginn
										StZ:Fire(JC, XuqjvYPF, t5jzEd9.Bottom)
									end
								end
								if math.abs(aUR - sKy2P9i.x) <= QMcSUqdi then
									if Trh.DockCallback(JC, XuqjvYPF, t5jzEd9.Left) ~= false then
										TNg = 0
										StZ:Fire(JC, XuqjvYPF, t5jzEd9.Left)
									end
								elseif math.abs(aUR + ZNXs3Bwd - (sKy2P9i.x + AD.x)) <= QMcSUqdi then
									if Trh.DockCallback(JC, XuqjvYPF, t5jzEd9.Right) ~= false then
										TNg = AD.x - ZNXs3Bwd
										StZ:Fire(JC, XuqjvYPF, t5jzEd9.Right)
									end
								end
							end
						else
							for sJ05I, HrLCim in pairs(XuqjvYPF:GetChildren()) do
								if HrLCim:IsA("GuiObject") and HrLCim ~= JC and HrLCim.Visible then
									local w = HrLCim.AbsolutePosition
									local sUu7z = HrLCim.AbsoluteSize
									if S.x + AkxLdb66.x >= w.x and S.x <= w.x + sUu7z.x then
										if math.abs(S.y + AkxLdb66.y - w.y) <= QMcSUqdi then
											wO9T = w.y - sKy2P9i.y - AkxLdb66.y
											StZ:Fire(JC, HrLCim, t5jzEd9.Bottom)
										elseif math.abs(S.y - (w.y + sUu7z.y)) <= QMcSUqdi then
											wO9T = w.y - sKy2P9i.y + sUu7z.y
											StZ:Fire(JC, HrLCim, t5jzEd9.Top)
										end
									end
									if S.y + AkxLdb66.y >= w.y and S.y <= w.y + sUu7z.y then
										if math.abs(S.x + AkxLdb66.x - w.x) <= QMcSUqdi then
											TNg = w.x - sKy2P9i.x - AkxLdb66.x
											StZ:Fire(JC, HrLCim, t5jzEd9.Right)
										elseif math.abs(S.x - (w.x + sUu7z.x)) <= QMcSUqdi then
											TNg = w.x - sKy2P9i.x + sUu7z.x
											StZ:Fire(JC, HrLCim, t5jzEd9.Left)
										end
									end
								end
							end
							if Trh.ConstrainToContainer then
								if c4 < sKy2P9i.y then
									wO9T = 0
									StZ:Fire(JC, XuqjvYPF, t5jzEd9.Top)
								elseif c4 + Ginn > sKy2P9i.y + AD.y then
									wO9T = AD.y - Ginn
									StZ:Fire(JC, XuqjvYPF, t5jzEd9.Bottom)
								end
								if aUR < sKy2P9i.x then
									TNg = 0
									StZ:Fire(JC, XuqjvYPF, t5jzEd9.Left)
								elseif aUR + ZNXs3Bwd > sKy2P9i.x + AD.x then
									TNg = AD.x - ZNXs3Bwd
									StZ:Fire(JC, XuqjvYPF, t5jzEd9.Right)
								end
							elseif Trh.SnapToEdge then
								if math.abs(c4 - sKy2P9i.y) <= QMcSUqdi then
									wO9T = 0
									StZ:Fire(JC, XuqjvYPF, t5jzEd9.Top)
								elseif math.abs(c4 + Ginn - (sKy2P9i.y + AD.y)) <= QMcSUqdi then
									wO9T = AD.y - Ginn
									StZ:Fire(JC, XuqjvYPF, t5jzEd9.Bottom)
								end
								if math.abs(aUR - sKy2P9i.x) <= QMcSUqdi then
									TNg = 0
									StZ:Fire(JC, XuqjvYPF, t5jzEd9.Left)
								elseif math.abs(aUR + ZNXs3Bwd - (sKy2P9i.x + AD.x)) <= QMcSUqdi then
									TNg = AD.x - ZNXs3Bwd
									StZ:Fire(JC, XuqjvYPF, t5jzEd9.Right)
								end
							end
						end
						local fe, ggnA = 0, 0
						if Trh.PositionScaled then
							fe = TNg / AD.x
							ggnA = wO9T / AD.y
							TNg = 0
							wO9T = 0
						end
						setp(JC, "Position", UDim2.new(fe, TNg, ggnA, wO9T))
					end)
					local F82 = JC.ZIndex
					local function wJ6tY_()
						Trh.StopDrag = wQl
						setp(s0FU, "Parent", nil)
						Kqne5Stra:Disconnect()
						Kqne5Stra = nil
						FKLmmhnQ:Disconnect()
						drag = nil
						m6SCS0(JC, F82)
						m4u:Fire(JC, PDA)
						return true
					end
					FKLmmhnQ = s0FU.MouseButton1Up:Connect(wJ6tY_)
					m6SCS0(JC, F82 + Trh.DragZIndex)
					setp(s0FU, "Parent", Hv(JC))
					Trh.StopDrag = wJ6tY_
					g:Fire(JC, PDA)
				end
				Trh.InvokeDrag = C1NqzxY
				local function T1gVrYq(M5oB)
					if M5oB:IsA("GuiButton") then
						KuK[M5oB] = M5oB.MouseButton1Down:Connect(function(xIyIKo, f2x)
							C1NqzxY(M5oB, Vector2.new(xIyIKo, f2x) - M5oB.AbsolutePosition)
						end)
					end
				end
				local function P5G(Nwl)
					if KuK[Nwl] then
						KuK[Nwl]:Disconnect()
						KuK[Nwl] = nil
					end
				end
				XuqjvYPF.ChildAdded:Connect(T1gVrYq)
				XuqjvYPF.ChildRemoved:Connect(P5G)
				for Xpt_SQ, Y in pairs(XuqjvYPF:GetChildren()) do
					T1gVrYq(Y)
				end
				return Trh, XuqjvYPF
			end
			LB1Z.DockContainer = JZAU2
			local zPXTTg = {
				["arrow-up"] = {
					{
						2,
						4,
						6,
					},
					{
						5,
						3,
						5,
					},
					8,
				},
				["arrow-down"] = {
					{
						2,
						4,
						6,
					},
					{
						3,
						5,
						3,
					},
					8,
				},
				["arrow-left"] = {
					{
						5,
						3,
						5,
					},
					{
						2,
						4,
						6,
					},
					8,
				},
				["arrow-right"] = {
					{
						3,
						5,
						3,
					},
					{
						2,
						4,
						6,
					},
					8,
				},
				["check-mark"] = {
					{
						1,
						3,
						7,
						7,
						3,
						1,
					},
					{
						3,
						5,
						1,
						3,
						7,
						5,
					},
					8,
				},
				pin = {
					{
						4,
						11,
						11,
						12,
						12,
						8,
						8,
						7,
						7,
						3,
						3,
						4,
						4,
						5,
						7,
						7,
						5,
						5,
					},
					{
						2,
						2,
						9,
						9,
						10,
						10,
						14,
						14,
						10,
						10,
						9,
						9,
						2,
						3,
						3,
						9,
						9,
						3,
					},
					16,
				},
				wrench = {
					{
						2,
						8,
						18,
						25,
						29,
						29,
						24,
						20,
						17,
						17,
						22,
						16,
						12,
						12,
					},
					{
						24,
						30,
						20,
						20,
						16,
						10,
						15,
						15,
						12,
						8,
						3,
						3,
						7,
						14,
					},
					32,
				},
				cross = {
					{
						1,
						2,
						4,
						6,
						7,
						7,
						5,
						7,
						7,
						6,
						4,
						2,
						1,
						1,
						3,
						1,
					},
					{
						1,
						1,
						3,
						1,
						1,
						2,
						4,
						6,
						7,
						7,
						5,
						7,
						7,
						6,
						4,
						2,
					},
					8,
				},
				grip = function(SMa, Bo, zF6ZPjQ)
					local nNQG3 = Bo.GUI
					setp(nNQG3, "Size", UDim2.new(0, SMa.x * (SMa.y == 0 and 2 or SMa.y), 0, SMa.x * 2))
					for yW = 1, SMa.x do
						local efGM8UMy = Instance.new("Frame", nNQG3)
						setp(efGM8UMy, "BackgroundColor3", Color3.new(0, 0, 0))
						setp(efGM8UMy, "BorderSizePixel", 0)
						setp(efGM8UMy, "Size", UDim2.new(1, 0, 0, 1))
						setp(efGM8UMy, "Position", UDim2.new(0, 0, 0, (yW - 1) * (SMa.y == 0 and 2 or SMa.y)))
						Bo.Stylist.AddObject(efGM8UMy)
					end
					return Bo, nNQG3
				end,
				vgrip = function(KhH, H4tXd, Nq6If)
					local II = H4tXd.GUI
					setp(II, "Size", UDim2.new(0, KhH.x * 2, 0, KhH.x * (KhH.y == 0 and 2 or KhH.y)))
					for Y_tefq = 1, KhH.x do
						local i = Instance.new("Frame", II)
						setp(i, "BackgroundColor3", Color3.new(0, 0, 0))
						setp(i, "BorderSizePixel", 0)
						setp(i, "Size", UDim2.new(0, 1, 1, 0))
						setp(i, "Position", UDim2.new(0, (Y_tefq - 1) * (KhH.y == 0 and 2 or KhH.y), 0, 0))
						H4tXd.Stylist.AddObject(i)
					end
					return H4tXd, II
				end,
			}
			local function seMLr(a3u, mzhB, sTxVGmb, GSIcq)
				local function Go(Mn)
					if Mn < 0 then
						return ceil(Mn - 0.5)
					else
						return floor(Mn + 0.5)
					end
				end
				local DGf = Instance.new("Frame")
				setp(DGf, "Name", "Graphic")
				setp(DGf, "BackgroundTransparency", 1)
				local kgRX7X = zhzpBSx(sTxVGmb)
				local JB = {
					GUI = DGf,
					Stylist = kgRX7X,
				}
				function JB.Destroy()
					for ut0 in pairs(JB) do
						JB[ut0] = nil
					end
					kgRX7X.Destroy()
					DGf:Destroy()
				end
				local GGJhclKa, KWahIz = {}, {}
				if type(a3u) == "table" then
					GGJhclKa = a3u[1]
					KWahIz = a3u[2]
					local ZFhlP6eg = a3u[3]
					if ZFhlP6eg then
						for ExUgDG = 1, #GGJhclKa do
							GGJhclKa[ExUgDG] = GGJhclKa[ExUgDG] / ZFhlP6eg
						end
						for jc4o42jz = 1, #KWahIz do
							KWahIz[jc4o42jz] = KWahIz[jc4o42jz] / ZFhlP6eg
						end
					end
				elseif type(a3u) == "string" then
					local jc = zPXTTg[a3u]
					if type(jc) == "table" then
						local Ojz_ = jc[3] or 1
						for x = 1, #jc[1] do
							GGJhclKa[x] = jc[1][x] / Ojz_
						end
						for Xtecl = 1, #jc[2] do
							KWahIz[Xtecl] = jc[2][Xtecl] / Ojz_
						end
					elseif type(jc) == "function" then
						return jc(mzhB, JB, GSIcq)
					else
						error("'" .. tostring(a3u) .. "' is not a valid internal polygon", 2)
					end
				else
					error("invalid polygon", 2)
				end
				local X2kyW, pVlvW, QcKn_, jiM = 0, 0, 0, 0
				GSIcq = GSIcq or {}
				local YUdA = GSIcq.method or "scaled"
				local Go = Go
				if GSIcq.round == "ceil" then
					Go = math.ceil
				elseif GSIcq.round == "floor" then
					Go = math.floor
				elseif GSIcq.round == "half" then
					Go = Go
				end
				if GSIcq.offset then
					X2kyW, pVlvW = -GSIcq.offset.x, -GSIcq.offset.y
				end
				if type(mzhB) == "userdata" then
					QcKn_ = mzhB.x
					jiM = mzhB.y
				elseif type(mzhB) == "table" then
					QcKn_ = mzhB[1] or mzhB.x
					jiM = mzhB[2] or mzhB.y
				else
					error("invalid size", 2)
				end
				polygonN = #GGJhclKa
				for KVcYU = 1, polygonN do
					GGJhclKa[KVcYU] = GGJhclKa[KVcYU] * QcKn_
				end
				for _ = 1, polygonN do
					KWahIz[_] = KWahIz[_] * jiM
				end
				setp(DGf, "Size", UDim2.new(0, QcKn_, 0, jiM))
				local lx3cpJ = Instance.new("Frame")
				setp(lx3cpJ, "BorderSizePixel", 0)
				setp(lx3cpJ, "BackgroundColor3", Color3.new())
				setp(lx3cpJ, "Size", UDim2.new(0, 1, 0, 1))
				local Yx9
				if YUdA == "scaled" then
					Yx9 = function(C, CJeG, F43eMG)
						CJeG = CJeG - C
						if CJeG ~= 0 then
							local mCzjh4 = lx3cpJ:Clone()
							kgRX7X.AddObject(mCzjh4)
							setp(mCzjh4, "Position", UDim2.new(C / QcKn_, 0, F43eMG / jiM, 0))
							setp(mCzjh4, "Size", UDim2.new(CJeG / QcKn_, 0, 1 / jiM, 0))
							setp(mCzjh4, "Parent", DGf)
						end
					end
				elseif YUdA == "static" then
					Yx9 = function(lU, epQue9, cHUJrj)
						lU = Go(lU, 1)
						epQue9 = Go(epQue9, 1) - lU
						if epQue9 ~= 0 then
							local EI0x = lx3cpJ:Clone()
							kgRX7X.AddObject(EI0x)
							setp(EI0x, "Position", UDim2.new(0, lU, 0, cHUJrj))
							setp(EI0x, "Size", UDim2.new(0, epQue9, 0, 1))
							setp(EI0x, "Parent", DGf)
						end
					end
				else
					error("invalid method", 2)
				end
				for E = pVlvW, jiM + pVlvW - 1 do
					local lacOdjf9 = 0
					local R2h4lP4l = {}
					local Fh = polygonN
					for hBph = 1, polygonN do
						if KWahIz[hBph] < E and KWahIz[Fh] >= E or KWahIz[Fh] < E and KWahIz[hBph] >= E then
							R2h4lP4l[lacOdjf9] = GGJhclKa[hBph]
								+ (E - KWahIz[hBph]) / (KWahIz[Fh] - KWahIz[hBph]) * (GGJhclKa[Fh] - GGJhclKa[hBph])
							lacOdjf9 = lacOdjf9 + 1
						end
						Fh = hBph
					end
					local a2e9fa = 0
					while a2e9fa < lacOdjf9 - 1 do
						if R2h4lP4l[a2e9fa] > R2h4lP4l[a2e9fa + 1] then
							R2h4lP4l[a2e9fa], R2h4lP4l[a2e9fa + 1] = R2h4lP4l[a2e9fa + 1], R2h4lP4l[a2e9fa]
							if a2e9fa ~= 0 then
								a2e9fa = a2e9fa - 1
							end
						else
							a2e9fa = a2e9fa + 1
						end
					end
					local Rc9_ZID, H1HF2wD6 = X2kyW + QcKn_, pVlvW + jiM
					local a2e9fa = 0
					while a2e9fa < lacOdjf9 - 1 do
						if R2h4lP4l[a2e9fa] >= Rc9_ZID then
							break
						end
						if R2h4lP4l[a2e9fa + 1] > X2kyW then
							if R2h4lP4l[a2e9fa] < X2kyW then
								R2h4lP4l[a2e9fa] = X2kyW
							end
							if R2h4lP4l[a2e9fa + 1] > Rc9_ZID then
								R2h4lP4l[a2e9fa + 1] = Rc9_ZID
							end
							Yx9(R2h4lP4l[a2e9fa] - X2kyW, R2h4lP4l[a2e9fa + 1] - X2kyW, E - pVlvW)
						end
						a2e9fa = a2e9fa + 2
					end
				end
				return JB, DGf
			end
			LB1Z.Graphic = seMLr
			local function qX(bxNo9h, Khst)
				Khst = Khst or a
				local pUT = (NsoTwDs("Frame"))({
					Size = bxNo9h and UDim2.new(1, 0, 0, Khst) or UDim2.new(0, Khst, 1, 0),
					Position = bxNo9h and UDim2.new(0, 0, 1, -Khst) or UDim2.new(1, -Khst, 0, 0),
					BackgroundTransparency = 1,
					Name = "ScrollFrame",
					(NsoTwDs("ImageButton"))({
						BackgroundColor3 = Color3.new(1, 1, 1),
						BackgroundTransparency = 0.7,
						BorderSizePixel = 0,
						Size = UDim2.new(0, Khst, 0, Khst),
						Name = "ScrollDown",
						Position = bxNo9h and UDim2.new(1, -Khst, 0, 0) or UDim2.new(0, 0, 1, -Khst),
					}),
					(NsoTwDs("ImageButton"))({
						BackgroundColor3 = Color3.new(1, 1, 1),
						BackgroundTransparency = 0.7,
						BorderSizePixel = 0,
						Size = UDim2.new(0, Khst, 0, Khst),
						Name = "ScrollUp",
					}),
					(NsoTwDs("ImageButton"))({
						AutoButtonColor = false,
						Size = bxNo9h and UDim2.new(1, -Khst * 2, 1, 0) or UDim2.new(1, 0, 1, -Khst * 2),
						BackgroundColor3 = Color3.new(0, 0, 0),
						BorderSizePixel = 0,
						BackgroundTransparency = 0.7,
						Position = bxNo9h and UDim2.new(0, Khst, 0, 0) or UDim2.new(0, 0, 0, Khst),
						Name = "ScrollBar",
						(NsoTwDs("ImageButton"))({
							BorderSizePixel = 0,
							BackgroundColor3 = Color3.new(1, 1, 1),
							Size = UDim2.new(0, Khst, 0, Khst),
							BackgroundTransparency = 0.5,
							Name = "ScrollThumb",
						}),
					}),
				})
				local ISg1 = pUT.ScrollDown
				local Gh5UJya = seMLr(bxNo9h and "arrow-right" or "arrow-down", Vector2.new(Khst, Khst))
				setp(Gh5UJya.GUI, "Parent", ISg1)
				local k = pUT.ScrollUp
				local Z8Ue = seMLr(bxNo9h and "arrow-left" or "arrow-up", Vector2.new(Khst, Khst))
				setp(Z8Ue.GUI, "Parent", k)
				local TXbmx = pUT.ScrollBar
				local r = TXbmx.ScrollThumb
				local Pqgz415t = seMLr(bxNo9h and "vgrip" or "grip", Vector2.new(4), {
					BackgroundColor3 = Color3.new(0, 0, 0),
					BackgroundTransparency = 0.5,
				})
				setp(Pqgz415t.GUI, "Position", UDim2.new(0.5, -4, 0.5, -4))
				setp(Pqgz415t.GUI, "Parent", r)
				local McNxKV = (NsoTwDs("ImageButton"))({
					Active = false,
					Size = UDim2.new(1.5, 0, 1.5, 0),
					AutoButtonColor = false,
					BackgroundTransparency = 1,
					Name = "MouseDrag",
					Position = UDim2.new(-0.25, 0, -0.25, 0),
					ZIndex = 10,
				})
				local WcwGYJh = {
					GUI = pUT,
					ScrollIndex = 0,
					VisibleSpace = 0,
					TotalSpace = 0,
					PageIncrement = 1,
				}
				local function gJt()
					return WcwGYJh.ScrollIndex / (WcwGYJh.TotalSpace - WcwGYJh.VisibleSpace)
				end
				WcwGYJh.GetScrollPercent = gJt
				local function hCs8M()
					return WcwGYJh.ScrollIndex + WcwGYJh.VisibleSpace < WcwGYJh.TotalSpace
				end
				WcwGYJh.CanScrollDown = hCs8M
				WcwGYJh.CanScrollRight = hCs8M
				local function GkjCn_mq()
					return WcwGYJh.ScrollIndex > 0
				end
				WcwGYJh.CanScrollUp = GkjCn_mq
				WcwGYJh.CanScrollLeft = GkjCn_mq
				local T9sySp = {
					BackgroundColor3 = Color3.new(0, 0, 0),
					BackgroundTransparency = 0,
				}
				local DL0mMXM = {
					BackgroundColor3 = Color3.new(0, 0, 0),
					BackgroundTransparency = 0.7,
				}
				local o4Kvi75g
				local ELb
				local FV5 = bxNo9h
					and function()
						setp(r, "Size", UDim2.new(WcwGYJh.VisibleSpace / WcwGYJh.TotalSpace, 0, 0, Khst))
						if r.AbsoluteSize.x < Khst then
							setp(r, "Size", UDim2.new(0, Khst, 0, Khst))
						end
						local t = TXbmx.AbsoluteSize.x
						setp(r, "Position", UDim2.new(gJt() * (t - r.AbsoluteSize.x) / t, 0, 0, 0))
					end
					or function()
						setp(r, "Size", UDim2.new(0, Khst, WcwGYJh.VisibleSpace / WcwGYJh.TotalSpace, 0))
						if r.AbsoluteSize.y < Khst then
							setp(r, "Size", UDim2.new(0, Khst, 0, Khst))
						end
						local H = TXbmx.AbsoluteSize.y
						setp(r, "Position", UDim2.new(0, 0, gJt() * (H - r.AbsoluteSize.y) / H, 0))
					end
				local function sX()
					local glZrOuSo = WcwGYJh.TotalSpace
					local Zdzaj = WcwGYJh.VisibleSpace
					local UxRGyO9e = WcwGYJh.ScrollIndex
					if Zdzaj <= glZrOuSo then
						if UxRGyO9e > 0 then
							if UxRGyO9e + Zdzaj > glZrOuSo then
								WcwGYJh.ScrollIndex = glZrOuSo - Zdzaj
							end
						else
							WcwGYJh.ScrollIndex = 0
						end
					else
						WcwGYJh.ScrollIndex = 0
					end
					if WcwGYJh.UpdateCallback then
						if WcwGYJh.UpdateCallback(WcwGYJh) == false then
							return
						end
					end
					local fvj_L = hCs8M()
					local _CPU89l = GkjCn_mq()
					if fvj_L ~= o4Kvi75g then
						o4Kvi75g = fvj_L
						setp(ISg1, "Active", fvj_L)
						setp(ISg1, "AutoButtonColor", fvj_L)
						Gh5UJya.Stylist.SetProperties(fvj_L and T9sySp or DL0mMXM)
						setp(ISg1, "BackgroundTransparency", fvj_L and 0.5 or 0.7)
					end
					if _CPU89l ~= ELb then
						ELb = _CPU89l
						setp(k, "Active", _CPU89l)
						setp(k, "AutoButtonColor", _CPU89l)
						Z8Ue.Stylist.SetProperties(_CPU89l and T9sySp or DL0mMXM)
						setp(k, "BackgroundTransparency", _CPU89l and 0.5 or 0.7)
					end
					setp(r, "Visible", fvj_L or _CPU89l)
					FV5()
				end
				WcwGYJh.Update = sX
				local function DH6mUlGB()
					WcwGYJh.ScrollIndex = WcwGYJh.ScrollIndex + WcwGYJh.PageIncrement
					sX()
				end
				WcwGYJh.ScrollDown = DH6mUlGB
				WcwGYJh.ScrollRight = DH6mUlGB
				local function A4ZRczp()
					WcwGYJh.ScrollIndex = WcwGYJh.ScrollIndex - WcwGYJh.PageIncrement
					sX()
				end
				WcwGYJh.ScrollUp = A4ZRczp
				WcwGYJh.ScrollLeft = A4ZRczp
				local function rUT(U)
					WcwGYJh.ScrollIndex = U
					sX()
				end
				WcwGYJh.ScrollTo = rUT
				local function g(Kwxn)
					WcwGYJh.ScrollIndex = math.floor((WcwGYJh.TotalSpace - WcwGYJh.VisibleSpace) * Kwxn + 0.5)
					sX()
				end
				WcwGYJh.SetScrollPercent = g
				local function JPi(yp5DGSwX)
					local Sb1Mw7R = yp5DGSwX.Active
					setp(yp5DGSwX, "Active", not Sb1Mw7R)
					setp(yp5DGSwX, "Active", Sb1Mw7R)
				end
				NUhYw6R4(pUT)
				local Kkl6fa = 0
				ISg1.MouseButton1Down:Connect(function()
					Kkl6fa = tick()
					local fuF = Kkl6fa
					local pA2
					pA2 = McNxKV.MouseButton1Up:Connect(function()
						Kkl6fa = tick()
						setp(McNxKV, "Parent", nil)
						JPi(ISg1)
						pA2:Disconnect()
						drag = nil
					end)
					setp(McNxKV, "Parent", Hv(pUT))
					DH6mUlGB()
					task.wait(0.2)
					while Kkl6fa == fuF do
						DH6mUlGB()
						if not hCs8M() then
							break
						end
						task.wait()
					end
				end)
				ISg1.MouseButton1Up:Connect(function()
					Kkl6fa = tick()
				end)
				k.MouseButton1Down:Connect(function()
					Kkl6fa = tick()
					local M5lAedm = Kkl6fa
					local _uYRl2kj
					_uYRl2kj = McNxKV.MouseButton1Up:Connect(function()
						Kkl6fa = tick()
						setp(McNxKV, "Parent", nil)
						JPi(k)
						_uYRl2kj:Disconnect()
						drag = nil
					end)
					setp(McNxKV, "Parent", Hv(pUT))
					A4ZRczp()
					task.wait(0.2)
					while Kkl6fa == M5lAedm do
						A4ZRczp()
						if not GkjCn_mq() then
							break
						end
						task.wait()
					end
				end)
				k.MouseButton1Up:Connect(function()
					Kkl6fa = tick()
				end)
				TXbmx.MouseButton1Down:Connect(bxNo9h and function(tbN, x)
					Kkl6fa = tick()
					local m = Kkl6fa
					local VVQ
					VVQ = McNxKV.MouseButton1Up:Connect(function()
						Kkl6fa = tick()
						setp(McNxKV, "Parent", nil)
						JPi(k)
						VVQ:Disconnect()
						drag = nil
					end)
					setp(McNxKV, "Parent", Hv(pUT))
					if tbN > r.AbsolutePosition.x then
						rUT(WcwGYJh.ScrollIndex + WcwGYJh.VisibleSpace)
						task.wait(0.2)
						while Kkl6fa == m do
							if tbN < r.AbsolutePosition.x + r.AbsoluteSize.x then
								break
							end
							rUT(WcwGYJh.ScrollIndex + WcwGYJh.VisibleSpace)
							task.wait()
						end
					else
						rUT(WcwGYJh.ScrollIndex - WcwGYJh.VisibleSpace)
						task.wait(0.2)
						while Kkl6fa == m do
							if tbN > r.AbsolutePosition.x then
								break
							end
							rUT(WcwGYJh.ScrollIndex - WcwGYJh.VisibleSpace)
							task.wait()
						end
					end
				end or function(Jb, qcpea)
					Kkl6fa = tick()
					local tjDBv = Kkl6fa
					local vmn7v
					vmn7v = McNxKV.MouseButton1Up:Connect(function()
						Kkl6fa = tick()
						setp(McNxKV, "Parent", nil)
						JPi(k)
						vmn7v:Disconnect()
						drag = nil
					end)
					setp(McNxKV, "Parent", Hv(pUT))
					if qcpea > r.AbsolutePosition.y then
						rUT(WcwGYJh.ScrollIndex + WcwGYJh.VisibleSpace)
						task.wait(0.2)
						while Kkl6fa == tjDBv do
							if qcpea < r.AbsolutePosition.y + r.AbsoluteSize.y then
								break
							end
							rUT(WcwGYJh.ScrollIndex + WcwGYJh.VisibleSpace)
							task.wait()
						end
					else
						rUT(WcwGYJh.ScrollIndex - WcwGYJh.VisibleSpace)
						task.wait(0.2)
						while Kkl6fa == tjDBv do
							if qcpea > r.AbsolutePosition.y then
								break
							end
							rUT(WcwGYJh.ScrollIndex - WcwGYJh.VisibleSpace)
							task.wait()
						end
					end
				end)
				r.MouseButton1Down:Connect(bxNo9h and function(Au1mzs, u39i)
					Kkl6fa = tick()
					local Fdg7p = Au1mzs - r.AbsolutePosition.x
					local GD3AP
					local jph00k
					GD3AP = McNxKV.MouseMoved:Connect(function(Au1mzs, u39i)
						local wE_4o = TXbmx.AbsolutePosition.x
						local F = TXbmx.AbsoluteSize.x - r.AbsoluteSize.x
						local bUO1NvT = wE_4o + F
						Au1mzs = Au1mzs - Fdg7p
						Au1mzs = Au1mzs < wE_4o and wE_4o or Au1mzs > bUO1NvT and bUO1NvT or Au1mzs
						Au1mzs = Au1mzs - wE_4o
						g(Au1mzs / F)
					end)
					jph00k = McNxKV.MouseButton1Up:Connect(function()
						Kkl6fa = tick()
						setp(McNxKV, "Parent", nil)
						JPi(r)
						GD3AP:Disconnect()
						GD3AP = nil
						jph00k:Disconnect()
						drag = nil
					end)
					setp(McNxKV, "Parent", Hv(pUT))
				end or function(KRQG, tVwI_N)
					Kkl6fa = tick()
					local Jkp2lGXG = tVwI_N - r.AbsolutePosition.y
					local ifcyuS
					local V03W
					ifcyuS = McNxKV.MouseMoved:Connect(function(KRQG, tVwI_N)
						local R = TXbmx.AbsolutePosition.y
						local X6_ = TXbmx.AbsoluteSize.y - r.AbsoluteSize.y
						local tN5u = R + X6_
						tVwI_N = tVwI_N - Jkp2lGXG
						tVwI_N = tVwI_N < R and R or tVwI_N > tN5u and tN5u or tVwI_N
						tVwI_N = tVwI_N - R
						g(tVwI_N / X6_)
					end)
					V03W = McNxKV.MouseButton1Up:Connect(function()
						Kkl6fa = tick()
						setp(McNxKV, "Parent", nil)
						JPi(r)
						ifcyuS:Disconnect()
						ifcyuS = nil
						V03W:Disconnect()
						drag = nil
					end)
					setp(McNxKV, "Parent", Hv(pUT))
				end)
				sX()
				return WcwGYJh, pUT
			end
			LB1Z.ScrollBar = qX
			local function h_8(Yqc0GWr, UC7, WbvvcjER)
				Yqc0GWr = Yqc0GWr or Instance.new("Frame")
				local rOLxXC = {}
				local w762p7sZ = {}
				local _7jt = 0
				local ORXyFQ = 0
				local OL1oV = 0
				local Q = 0
				local HQvT5
				if UC7 then
					if WbvvcjER then
						HQvT5 = function()
							Q = Q + 1
							local Tcv_ = Q
							local lygY = 0
							local HG = 0
							for u, m9i in pairs(rOLxXC) do
								if Q ~= Tcv_ then
									return
								end
								if m9i.Visible then
									local EqPMP = m9i.AbsoluteSize
									setp(m9i, "Position", UDim2.new(0, HG + _7jt, 1, -EqPMP.y - _7jt))
									lygY = EqPMP.y > lygY and EqPMP.y or lygY
									HG = HG + EqPMP.x + ORXyFQ
								end
							end
							if Q ~= Tcv_ then
								return
							end
							if #rOLxXC > 0 then
								setp(Yqc0GWr, "Size", UDim2.new(0, HG - ORXyFQ + _7jt * 2 + OL1oV, 0, lygY + _7jt * 2 + OL1oV))
							else
								setp(Yqc0GWr, "Size", UDim2.new(0, _7jt * 2 + OL1oV, 0, _7jt * 2 + OL1oV))
							end
						end
					else
						HQvT5 = function()
							Q = Q + 1
							local JR = Q
							local G1Cl6 = 0
							local h = 0
							for fYUikw, W9qTCm in pairs(rOLxXC) do
								if Q ~= JR then
									return
								end
								if W9qTCm.Visible then
									local YlaSjEKp = W9qTCm.AbsoluteSize
									setp(W9qTCm, "Position", UDim2.new(0, h + _7jt, 0, _7jt))
									G1Cl6 = YlaSjEKp.y > G1Cl6 and YlaSjEKp.y or G1Cl6
									h = h + YlaSjEKp.x + ORXyFQ
								end
							end
							if Q ~= JR then
								return
							end
							if #rOLxXC > 0 then
								setp(Yqc0GWr, "Size", UDim2.new(0, h - ORXyFQ + _7jt * 2 + OL1oV, 0, G1Cl6 + _7jt * 2 + OL1oV))
							else
								setp(Yqc0GWr, "Size", UDim2.new(0, _7jt * 2 + OL1oV, 0, _7jt * 2 + OL1oV))
							end
						end
					end
				elseif WbvvcjER then
					HQvT5 = function()
						Q = Q + 1
						local u_ogp8 = Q
						local Kob = 0
						local a3 = 0
						for MvWxr, HgY6 in pairs(rOLxXC) do
							if Q ~= u_ogp8 then
								return
							end
							if HgY6.Visible then
								local Wc = HgY6.AbsoluteSize
								setp(HgY6, "Position", UDim2.new(1, -Wc.x - _7jt, 0, a3 + _7jt))
								Kob = Wc.x > Kob and Wc.x or Kob
								a3 = a3 + Wc.y + ORXyFQ
							end
						end
						if Q ~= u_ogp8 then
							return
						end
						if #rOLxXC > 0 then
							setp(Yqc0GWr, "Size", UDim2.new(0, Kob + _7jt * 2 + OL1oV, 0, a3 - ORXyFQ + _7jt * 2 + OL1oV))
						else
							setp(Yqc0GWr, "Size", UDim2.new(0, _7jt * 2 + OL1oV, 0, _7jt * 2 + OL1oV))
						end
					end
				else
					HQvT5 = function()
						Q = Q + 1
						local eQ5 = Q
						local kvR = 0
						local So = 0
						for Wi, X1WM in pairs(rOLxXC) do
							if Q ~= eQ5 then
								return
							end
							if X1WM.Visible then
								local OVBAVy = X1WM.AbsoluteSize
								setp(X1WM, "Position", UDim2.new(0, _7jt, 0, So + _7jt))
								kvR = OVBAVy.x > kvR and OVBAVy.x or kvR
								So = So + OVBAVy.y + ORXyFQ
							end
						end
						if Q ~= eQ5 then
							return
						end
						if #rOLxXC > 0 then
							setp(Yqc0GWr, "Size", UDim2.new(0, kvR + _7jt * 2 + OL1oV, 0, So - ORXyFQ + _7jt * 2 + OL1oV))
						else
							setp(Yqc0GWr, "Size", UDim2.new(0, _7jt * 2 + OL1oV, 0, _7jt * 2 + OL1oV))
						end
					end
				end
				local function dN(Joa, NF0)
					ORXyFQ = Joa or ORXyFQ
					_7jt = NF0 or _7jt
					HQvT5()
				end
				local function B35igHj(OeF, sawaLtSr)
					if OeF:IsA("GuiObject") then
						if type(sawaLtSr) == "number" then
							table.insert(rOLxXC, sawaLtSr, OeF)
						else
							table.insert(rOLxXC, OeF)
						end
						w762p7sZ[OeF] = OeF.Changed:Connect(function(KWeL)
							if KWeL == "AbsoluteSize" or KWeL == "Visible" then
								HQvT5()
							end
						end)
						setp(OeF, "Parent", Yqc0GWr)
						HQvT5()
					end
				end
				local function o8pPC2(Krvhod9t)
					if Krvhod9t == nil then
						Krvhod9t = #rOLxXC
					elseif type(Krvhod9t) ~= "number" then
						Krvhod9t = hPQ(rOLxXC, Krvhod9t)
					end
					if Krvhod9t then
						Krvhod9t = R1FIoQI(rOLxXC, Krvhod9t)
						local bfx5oN = table.remove(rOLxXC, Krvhod9t)
						if w762p7sZ[bfx5oN] then
							w762p7sZ[bfx5oN]:Disconnect()
							w762p7sZ[bfx5oN] = nil
						end
						setp(bfx5oN, "Parent", nil)
						HQvT5()
						return bfx5oN
					end
				end
				local function f7nUIW(XDKTNXw, RyTb)
					if XDKTNXw == nil then
						XDKTNXw = #rOLxXC
					elseif type(XDKTNXw) ~= "number" then
						XDKTNXw = hPQ(rOLxXC, XDKTNXw)
					end
					if RyTb == nil then
						RyTb = #rOLxXC
					elseif type(RyTb) ~= "number" then
						RyTb = hPQ(rOLxXC, RyTb)
					end
					if XDKTNXw and RyTb then
						XDKTNXw = R1FIoQI(rOLxXC, XDKTNXw)
						RyTb = R1FIoQI(rOLxXC, RyTb)
						local ImqF1v = table.remove(rOLxXC, XDKTNXw)
						table.insert(rOLxXC, RyTb, ImqF1v)
						HQvT5()
					end
				end
				local bDgD = {
					GUI = Yqc0GWr,
					List = rOLxXC,
					Update = HQvT5,
					SetPadding = dN,
					AddObject = B35igHj,
					RemoveObject = o8pPC2,
					MoveObject = f7nUIW,
					GetIndex = function(KRu)
						return hPQ(rOLxXC, KRu)
					end,
				}
				local function Kg8PhSq()
					for Vy5qF, rokDhenZ in pairs(rOLxXC) do
						if w762p7sZ[rokDhenZ] then
							w762p7sZ[rokDhenZ]:Disconnect()
							w762p7sZ[rokDhenZ] = nil
						end
						setp(rokDhenZ, "Parent", nil)
						rOLxXC[Vy5qF] = nil
					end
					for td8OL, W in pairs(w762p7sZ) do
						W:Disconnect()
						w762p7sZ[td8OL] = nil
					end
					for CS in pairs(bDgD) do
						bDgD[CS] = nil
					end
					Yqc0GWr:Destroy()
				end
				bDgD.Destroy = Kg8PhSq
				for iv2VylMn, Oi in pairs(Yqc0GWr:GetChildren()) do
					B35igHj(Oi, iv2VylMn)
				end
				HQvT5()
				Yqc0GWr.Changed:Connect(function(KwcrRu)
					if KwcrRu == "AbsoluteSize" or KwcrRu == "Style" then
						local bgFJ = OL1oV
						OL1oV = Ch(Yqc0GWr) * 2
						if OL1oV ~= bgFJ then
							HQvT5()
						end
					end
				end)
				return bDgD, Yqc0GWr
			end
			LB1Z.StackingFrame = h_8
			local function xL7OTb(fqGD1rfW, K0)
				fqGD1rfW = fqGD1rfW or {}
				K0 = entyHeight or a
				local _1To2 = Instance.new("Frame")
				setp(_1To2, "Size", UDim2.new(0, 300, 0, 200))
				_1To2.Style = Enum.FrameStyle.RobloxRound
				setp(_1To2, "Active", true)
				setp(_1To2, "Name", "ScrollingListFrame")
				local lkzs = Instance.new("Frame", _1To2)
				setp(lkzs, "Name", "ListViewFrame")
				setp(lkzs, "BackgroundTransparency", 1)
				setp(lkzs, "Size", UDim2.new(1, -K0, 1, 0))
				local Hhwf3oO = Stylist({
					Name = "ListEntry",
					Font = "ArialBold",
					FontSize = "Size14",
					TextColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					TextXAlignment = "Left",
				})
				local Oh5 = Instance.new("TextLabel")
				local LgQF = {}
				local emGbhJGH, e_Ev8OQ = qX(false, K0)
				setp(e_Ev8OQ, "Size", UDim2.new(0, K0, 1, 0))
				setp(e_Ev8OQ, "Position", UDim2.new(1, -K0, 0, 0))
				setp(e_Ev8OQ, "Parent", _1To2)
				local zBMvU6 = emGbhJGH.Update
				local ZmbDgbg = {
					List = fqGD1rfW,
					GUI = _1To2,
					Scroll = emGbhJGH,
					Update = zBMvU6,
					EntryStylist = Hhwf3oO,
				}
				emGbhJGH.UpdateCallback = function()
					local guEhw = emGbhJGH.VisibleSpace
					for sll = 1, guEhw do
						local BzNBgGvD = fqGD1rfW[sll + emGbhJGH.ScrollIndex]
						if BzNBgGvD then
							local KIQCH = LgQF[sll]
							if not KIQCH then
								KIQCH = Oh5:Clone()
								Hhwf3oO.AddObject(KIQCH)
								LgQF[sll] = KIQCH
								setp(KIQCH, "Parent", lkzs)
								setp(KIQCH, "ZIndex", _1To2.ZIndex)
							end
							setp(KIQCH, "Text", tostring(BzNBgGvD))
							setp(KIQCH, "Position", UDim2.new(0, 0, 0, (sll - 1) * K0))
							setp(KIQCH, "Size", UDim2.new(1, 0, 0, K0))
						else
							local L4bw = LgQF[sll]
							if L4bw then
								Hhwf3oO.RemoveObject(L4bw)
								L4bw:Destroy()
								LgQF[sll] = nil
							end
						end
					end
					for XhBEPD = emGbhJGH.VisibleSpace + 1, #LgQF do
						local Uq = LgQF[XhBEPD]
						if Uq then
							Hhwf3oO.RemoveObject(Uq)
							Uq:Destroy()
						end
						LgQF[XhBEPD] = nil
					end
				end
				local function hMxy(RmyiI_D, w_2iiJwx)
					if w_2iiJwx then
						table.insert(fqGD1rfW, w_2iiJwx, RmyiI_D)
					else
						table.insert(fqGD1rfW, RmyiI_D)
					end
					emGbhJGH.TotalSpace = #fqGD1rfW
					zBMvU6()
				end
				ZmbDgbg.AddEntry = hMxy
				local function hj3(RRESd, S1qoVmFR)
					if S1qoVmFR then
						for f2 = 1, #RRESd do
							table.insert(fqGD1rfW, S1qoVmFR + f2 - 1, RRESd[f2])
						end
					else
						for O3rHR = 1, #RRESd do
							table.insert(fqGD1rfW, RRESd[O3rHR])
						end
					end
					emGbhJGH.TotalSpace = #fqGD1rfW
					zBMvU6()
				end
				ZmbDgbg.AddEntries = hj3
				local function M7q3pa8(YU80)
					if type(YU80) == "number" or type(YU80) == "nil" then
						table.remove(fqGD1rfW, YU80)
					else
						for ARnO_0E, Qh in pairs(fqGD1rfW) do
							if Qh == YU80 then
								table.remove(fqGD1rfW, ARnO_0E)
								break
							end
						end
					end
					emGbhJGH.TotalSpace = #fqGD1rfW
					zBMvU6()
				end
				ZmbDgbg.RemoveEntry = M7q3pa8
				NUhYw6R4(_1To2)
				lkzs.Changed:Connect(function(lqxbMC)
					if lqxbMC == "AbsoluteSize" then
						emGbhJGH.VisibleSpace = math.floor(lkzs.AbsoluteSize.y / K0)
						zBMvU6()
					end
				end)
				function ZmbDgbg.Destroy()
					for qOk5Jm in pairs(ZmbDgbg) do
						ZmbDgbg[qOk5Jm] = nil
					end
					for tpSe2fs, AuVgc7 in pairs(LgQF) do
						AuVgc7:Destroy()
						LgQF[tpSe2fs] = nil
					end
					Hhwf3oO.Destroy()
					emGbhJGH.Destroy()
					_1To2:Destroy()
				end
				return ZmbDgbg, _1To2
			end
			LB1Z.ScrollingList = xL7OTb
			local function w8T3f(vxnB, ZQOXXXd, cyBmTv)
				if vxnB == nil then
					vxnB = true
				end
				cyBmTv = cyBmTv or a
				local _TKd0F = (NsoTwDs("Frame"))({
					Name = "ScrollingContainer",
					Size = UDim2.new(0, 300, 0, 200),
					BackgroundTransparency = 1,
				})
				local Z = (NsoTwDs("Frame"))({
					Name = "Boundary",
					BackgroundColor3 = Color3.new(0, 0, 0),
					BorderColor3 = Color3.new(1, 1, 1),
					ClipsDescendants = true,
					Parent = _TKd0F,
				})
				local Dw = (NsoTwDs("Frame"))({
					Name = "Container",
					BackgroundTransparency = 1,
					Parent = Z,
				})
				local bsFpM = {
					GUI = _TKd0F,
					Boundary = Z,
					Container = Dw,
				}
				if vxnB and ZQOXXXd then
					local h = qX(false, cyBmTv)
					h.PageIncrement = cyBmTv
					setp(h.GUI, "Position", UDim2.new(1, -cyBmTv, 0, 0))
					setp(h.GUI, "Size", UDim2.new(0, cyBmTv, 1, -cyBmTv))
					setp(h.GUI, "Parent", _TKd0F)
					local doBTofya = h.Update
					h.UpdateCallback = function()
						setp(Dw, "Position", UDim2.new(0, Dw.Position.X.Offset, 0, -h.ScrollIndex))
					end
					local rNP = qX(true, cyBmTv)
					rNP.PageIncrement = cyBmTv
					setp(rNP.GUI, "Position", UDim2.new(0, 0, 1, -cyBmTv))
					setp(rNP.GUI, "Size", UDim2.new(1, -cyBmTv, 0, cyBmTv))
					setp(rNP.GUI, "Parent", _TKd0F)
					local TL = rNP.Update
					rNP.UpdateCallback = function()
						setp(Dw, "Position", UDim2.new(0, -rNP.ScrollIndex, 0, Dw.Position.Y.Offset))
					end
					setp(Z, "Size", UDim2.new(1, -cyBmTv, 1, -cyBmTv))
					local function Tzgj_W()
						doBTofya()
						TL()
					end
					local function g0AS39(t2)
						if t2 == "AbsoluteSize" then
							h.TotalSpace = Dw.AbsoluteSize.y
							h.VisibleSpace = Z.AbsoluteSize.y
							rNP.TotalSpace = Dw.AbsoluteSize.x
							rNP.VisibleSpace = Z.AbsoluteSize.x
							Tzgj_W()
						end
					end
					Z.Changed:Connect(g0AS39)
					Dw.Changed:Connect(g0AS39)
					bsFpM.VScroll = h
					bsFpM.HScroll = rNP
					bsFpM.Update = Tzgj_W
					g0AS39("AbsoluteSize")
					Tzgj_W()
				elseif vxnB then
					local PDewNmM = qX(false, cyBmTv)
					PDewNmM.PageIncrement = cyBmTv
					setp(PDewNmM.GUI, "Position", UDim2.new(1, -cyBmTv, 0, 0))
					setp(PDewNmM.GUI, "Size", UDim2.new(0, cyBmTv, 1, 0))
					setp(PDewNmM.GUI, "Parent", _TKd0F)
					local GFlD = PDewNmM.Update
					PDewNmM.UpdateCallback = function()
						setp(Dw, "Position", UDim2.new(0, Dw.Position.X.Offset, 0, -PDewNmM.ScrollIndex))
					end
					local function y3owm5E(psHOEe2)
						if psHOEe2 == "AbsoluteSize" then
							PDewNmM.TotalSpace = Dw.AbsoluteSize.y
							PDewNmM.VisibleSpace = Z.AbsoluteSize.y
							GFlD()
						end
					end
					Z.Changed:Connect(y3owm5E)
					Dw.Changed:Connect(y3owm5E)
					bsFpM.VScroll = PDewNmM
					bsFpM.Update = GFlD
					y3owm5E("AbsoluteSize")
					GFlD()
				elseif ZQOXXXd then
					local R1zT = qX(true, cyBmTv)
					R1zT.PageIncrement = cyBmTv
					setp(R1zT.GUI, "Position", UDim2.new(0, 0, 1, -cyBmTv))
					setp(R1zT.GUI, "Size", UDim2.new(1, 0, 0, cyBmTv))
					setp(R1zT.GUI, "Parent", _TKd0F)
					local J2Df = R1zT.Update
					R1zT.UpdateCallback = function()
						setp(Dw, "Position", UDim2.new(0, -R1zT.ScrollIndex, 0, Dw.Position.Y.Offset))
					end
					local function YyS(o)
						if o == "AbsoluteSize" then
							R1zT.TotalSpace = Dw.AbsoluteSize.x
							R1zT.VisibleSpace = Z.AbsoluteSize.x
							J2Df()
						end
					end
					Z.Changed:Connect(YyS)
					Dw.Changed:Connect(YyS)
					bsFpM.HScroll = R1zT
					bsFpM.Update = J2Df
					YyS("AbsoluteSize")
					J2Df()
				end
				return bsFpM, _TKd0F
			end
			LB1Z.ScrollingContainer = w8T3f
			local function K(MY16y, ZBUghmX, ncK)
				MY16y = MY16y or {}
				ncK = ncK or a
				local Deq = 0
				local GH3wE = math.floor(Deq / ncK)
				local xZFv = 0
				local bc0w4j = {}
				local OGMxal0 = {}
				local QlewVjkq = {}
				local Q = {}
				local yI = {}
				local EDE3 = (NsoTwDs("Frame"))({
					Size = UDim2.new(0, 300, 0, 200),
					BackgroundTransparency = 1,
					(NsoTwDs("Frame"))({
						Name = "ListViewFrame",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -ncK, 1, -ncK),
						Position = UDim2.new(0, 0, 0, ncK),
					}),
					(NsoTwDs("Frame"))({
						Name = "ColumnHeaderFrame",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, -ncK, 0, ncK),
						Position = UDim2.new(0, 0, 0, 0),
					}),
				})
				local FpWG11U = EDE3.ListViewFrame
				local kRY46C = EDE3.ColumnHeaderFrame
				local MvOaiq = zhzpBSx({
					TextColor3 = Color3.new(1, 1, 1),
					TextTransparency = 0,
					Font = Enum.Font.ArialBold,
					FontSize = Enum.FontSize.Size14,
				})
				local DUic_1K = zhzpBSx({
					BackgroundColor3 = Color3.new(0, 0, 0),
					BorderColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 1,
					BackgroundTransparency = 0.7,
				})
				MvOaiq.AddStylist(DUic_1K)
				local rVj9z4 = zhzpBSx({
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderColor3 = Color3.new(1, 1, 1),
					BorderSizePixel = 1,
					BackgroundTransparency = 0.8,
				})
				MvOaiq.AddStylist(rVj9z4)
				local mWkmCx = zhzpBSx({
					BackgroundTransparency = 1,
				})
				MvOaiq.AddStylist(mWkmCx)
				local qQpo = {}
				local qXKzBXo0 = {}
				local cJ, HI4G3oH = qX(false, ncK);
				(HGli(HI4G3oH))({
					Size = UDim2.new(0, ncK, 1, -ncK),
					Position = UDim2.new(1, -ncK, 0, ncK),
					Parent = EDE3,
				})
				local ncWw = cJ.Update
				local kdS = {
					Data = MY16y,
					GUI = EDE3,
					Stylist = {
						Global = MvOaiq,
						Cell = DUic_1K,
						Header = rVj9z4,
						RowSpan = mWkmCx,
						Rows = qQpo,
						Columns = qXKzBXo0,
					},
					Update = ncWw,
				}
				local OS60 = 0
				cJ.UpdateCallback = function()
					OS60 = OS60 + 1
					local DIoX3 = OS60
					for sjXYan, KxB8fW in pairs(Q) do
						if OS60 ~= DIoX3 then
							return
						end
						setp(KxB8fW, "Visible", false)
						Q[sjXYan] = nil
					end
					for M = 1, cJ.VisibleSpace do
						if OS60 ~= DIoX3 then
							return
						end
						local JmyAd = bc0w4j[M + cJ.ScrollIndex]
						if JmyAd then
							Q[#Q + 1] = JmyAd
							setp(JmyAd, "Position", UDim2.new(0, 0, 0, (M - 1) * ncK))
							setp(JmyAd, "Size", UDim2.new(1, 0, 0, ncK))
							setp(JmyAd, "Visible", true)
						end
					end
				end
				FpWG11U.Changed:Connect(function(L)
					if L == "AbsoluteSize" then
						cJ.VisibleSpace = math.floor(FpWG11U.AbsoluteSize.y / ncK)
						ncWw()
					end
				end)
				local dl = (NsoTwDs("Frame"))({
					Name = "SortGraphic",
					BackgroundTransparency = 1,
					Size = UDim2.new(0, ncK, 0, ncK),
					Position = UDim2.new(1, -ncK * 0.75, 0.5, -ncK / 8),
				})
				local b2UK = {
					TextColor3 = "BackgroundColor3",
					TextTransparency = "BackgroundTransparency",
					BorderSizePixel = "",
				}
				local FC0yhp, lL30T = seMLr("arrow-up", Vector2.new(ncK, ncK))
				MvOaiq.AddStylist(FC0yhp.Stylist, b2UK)
				setp(lL30T, "Visible", false)
				setp(lL30T, "Parent", dl)
				local zt, Ofgm3g = seMLr("arrow-down", Vector2.new(ncK, ncK))
				MvOaiq.AddStylist(zt.Stylist, b2UK)
				setp(Ofgm3g, "Visible", false)
				setp(Ofgm3g, "Parent", dl)
				local function z6WE21dc(U, uAbuU)
					if uAbuU then
						if uAbuU.TextXAlignment == Enum.TextXAlignment.Right then
							setp(dl, "Position", UDim2.new(0, 0, 0, 0))
						else
							setp(dl, "Position", UDim2.new(1, -ncK, 0, 0))
						end
					end
					if U > 0 then
						setp(lL30T, "Visible", true)
						setp(Ofgm3g, "Visible", false)
						if dl.ZIndex ~= uAbuU.ZIndex then
							m6SCS0(dl, uAbuU.ZIndex)
						end
						setp(dl, "Parent", uAbuU)
					elseif U < 0 then
						setp(lL30T, "Visible", false)
						setp(Ofgm3g, "Visible", true)
						if dl.ZIndex ~= uAbuU.ZIndex then
							m6SCS0(dl, uAbuU.ZIndex)
						end
						setp(dl, "Parent", uAbuU)
					else
						setp(lL30T, "Visible", false)
						setp(Ofgm3g, "Visible", false)
						setp(dl, "Parent", nil)
					end
				end
				local function rJg9H(EF205E, YFR5myC)
					for KMu, PPqE in pairs(MY16y) do
						bc0w4j[KMu] = OGMxal0[PPqE]
					end
					local K1Lgio = (kRY46C:GetChildren())[EF205E]
					z6WE21dc(0)
					if YFR5myC == iD1IUx.ASCENDING then
						table.sort(bc0w4j, function(sOE, hf9m_U8)
							local dTQ, k29Z4 = QlewVjkq[sOE][EF205E], QlewVjkq[hf9m_U8][EF205E]
							local ai = type(dTQ)
							if ai == "table" then
								dTQ, k29Z4 = dTQ[1], k29Z4[1]
								ai = type(dTQ)
							end
							if ai == "boolean" then
								return tostring(dTQ) > tostring(k29Z4)
							elseif ai == "number" or ai == "string" then
								return dTQ < k29Z4
							else
								return tostring(dTQ) < tostring(k29Z4)
							end
						end)
						z6WE21dc(1, K1Lgio)
					elseif YFR5myC == iD1IUx.DESCENDING then
						table.sort(bc0w4j, function(t, TmE)
							local xR, LJ3E = QlewVjkq[t][EF205E], QlewVjkq[TmE][EF205E]
							local Vjx = type(xR)
							if Vjx == "table" then
								xR, LJ3E = xR[1], LJ3E[1]
								Vjx = type(xR)
							end
							if Vjx == "boolean" then
								return tostring(xR) < tostring(LJ3E)
							elseif Vjx == "number" or Vjx == "string" then
								return xR > LJ3E
							else
								return tostring(xR) > tostring(LJ3E)
							end
						end)
						local K1Lgio = (kRY46C:GetChildren())[EF205E]
						z6WE21dc(-1, K1Lgio)
					end
					ncWw()
				end
				local sNyznm3W = (NsoTwDs("Frame"))({
					Name = "Row",
					Visible = false,
				})
				local function UU(curjMDD, gBS9Zk)
					if gBS9Zk == nil then
						setp(curjMDD, "Text", "")
					else
						gBS9Zk = tostring(gBS9Zk)
						if #gBS9Zk > 0 and curjMDD.TextXAlignment ~= Enum.TextXAlignment.Center then
							if curjMDD.TextXAlignment == Enum.TextXAlignment.Left then
								setp(curjMDD, "Text", " " .. gBS9Zk)
							elseif curjMDD.TextXAlignment == Enum.TextXAlignment.Right then
								setp(curjMDD, "Text", gBS9Zk .. " ")
							end
						else
							setp(curjMDD, "Text", gBS9Zk)
						end
					end
				end
				local function YBciOAz2(Xr, UPp)
					local hWpZC = yI[Xr]
					local bFF8, RXM = hWpZC.Checked, hWpZC.Unchecked
					if type(RXM) == "string" then
						setp(Xr, "Image", UPp and "" or RXM)
					elseif type(RXM) == "table" then
						if UPp then
							setp(RXM.GUI, "Parent", nil)
						else
							if RXM.GUI.ZIndex ~= Xr.ZIndex then
								m6SCS0(RXM.GUI, Xr.ZIndex)
							end
							setp(RXM.GUI, "Parent", Xr)
						end
					end
					if type(bFF8) == "string" then
						setp(Xr, "Image", UPp and bFF8 or "")
					elseif type(bFF8) == "table" then
						if UPp then
							if bFF8.GUI.ZIndex ~= Xr.ZIndex then
								m6SCS0(bFF8.GUI, Xr.ZIndex)
							end
							setp(bFF8.GUI, "Parent", Xr)
						else
							setp(bFF8.GUI, "Parent", nil)
						end
					end
				end
				local wJvNH = nil
				local dOvZoN = iD1IUx.NONE
				local IP01vP = UDim.new()
				for Ieb1cGC, Bf in pairs(ZBUghmX) do
					local hKJi2 = zhzpBSx(Bf.style)
					qXKzBXo0[Ieb1cGC] = hKJi2
					local jW = Bf.type
					local JkVK
					if jW == "text" then
						JkVK = Instance.new("TextLabel", sNyznm3W)
						setp(JkVK, "Name", "Text")
					elseif jW == "image" then
						JkVK = Instance.new("ImageLabel", sNyznm3W)
						setp(JkVK, "Name", "Image")
					elseif jW == "text-button" then
						JkVK = Instance.new("TextButton", sNyznm3W)
						setp(JkVK, "Name", "TextButton")
					elseif jW == "image-button" then
						JkVK = Instance.new("ImageButton", sNyznm3W)
						setp(JkVK, "Name", "ImageButton")
					elseif jW == "text-field" then
						JkVK = Instance.new("TextBox", sNyznm3W)
						setp(JkVK, "Name", "TextField")
						setp(JkVK, "ClearTextOnFocus", false)
					elseif jW == "check-box" then
						JkVK = Instance.new("ImageButton", sNyznm3W)
						setp(JkVK, "Name", "CheckBox")
					end
					local oXM7 = (NsoTwDs("TextButton"))({
						Name = "ColumnHeader",
						Parent = kRY46C,
					})
					rVj9z4.AddObject(oXM7)
					hKJi2.AddObject(oXM7)
					UU(oXM7, Bf.name)
					oXM7.MouseButton1Click:Connect(function()
						if wJvNH == oXM7 then
							if dOvZoN == iD1IUx.ASCENDING then
								dOvZoN = iD1IUx.DESCENDING
							elseif dOvZoN == iD1IUx.DESCENDING then
								dOvZoN = iD1IUx.NONE
							else
								dOvZoN = iD1IUx.ASCENDING
							end
						else
							dOvZoN = iD1IUx.ASCENDING
						end
						wJvNH = oXM7
						rJg9H(Ieb1cGC, dOvZoN)
					end)
					local z__Va = Bf.width
					setp(oXM7, "Size", UDim2.new(z__Va.Scale, z__Va.Offset, 1, 0))
					setp(oXM7, "Position", UDim2.new(IP01vP.Scale, IP01vP.Offset, 0, 0))
					IP01vP = IP01vP + z__Va
				end
				IP01vP = nil
				function kdS.UpdateRow(uGbp)
					local OXK0
					if type(uGbp) == "number" then
						OXK0 = MY16y[uGbp]
					else
						OXK0 = uGbp
					end
					local Ek3QueoD = OGMxal0[OXK0]
					local g = Ek3QueoD:GetChildren()
					local m_l = UDim.new()
					for L, XmcB in pairs(ZBUghmX) do
						local l5Nd = XmcB.type
						local sEMv = g[L]
						local VPX = OXK0[L]
						local c = XmcB.width
						if l5Nd == "text" then
							UU(sEMv, VPX)
						elseif l5Nd == "image" then
							setp(sEMv, "Image", VPX)
						elseif l5Nd == "text-button" then
							UU(sEMv, VPX)
						elseif l5Nd == "image-button" then
							setp(sEMv, "Image", VPX)
						elseif l5Nd == "text-field" then
							UU(sEMv, VPX)
						elseif l5Nd == "check-box" then
							YBciOAz2(sEMv, VPX)
						end
						setp(sEMv, "Size", UDim2.new(c.Scale, c.Offset, 1, 0))
						setp(sEMv, "Position", UDim2.new(m_l.Scale, m_l.Offset, 0, 0))
						m_l = m_l + c
					end
				end
				function kdS.AddRow(VGJdue, ztMtdy, rA)
					local zHapMi = sNyznm3W:Clone()
					if ztMtdy then
						ztMtdy = ztMtdy > #MY16y + 1 and #MY16y + 1 or ztMtdy < 1 and 1 or ztMtdy
						table.insert(MY16y, ztMtdy, VGJdue)
						table.insert(bc0w4j, ztMtdy, zHapMi)
					else
						table.insert(MY16y, VGJdue)
						table.insert(bc0w4j, zHapMi)
					end
					cJ.TotalSpace = #MY16y
					mWkmCx.AddObject(zHapMi)
					setp(zHapMi, "Size", UDim2.new(1, 0, 0, ncK))
					setp(zHapMi, "ZIndex", EDE3.ZIndex)
					setp(zHapMi, "Parent", FpWG11U)
					local Jmsve1Q = zHapMi:GetChildren()
					local _B8W1YL = UDim.new()
					local F = zhzpBSx(rA)
					qQpo[VGJdue] = F
					for FN7, cpNryuPy in pairs(ZBUghmX) do
						local mVKRd8 = cpNryuPy.type
						local TBV0052 = Jmsve1Q[FN7]
						setp(TBV0052, "ZIndex", EDE3.ZIndex)
						DUic_1K.AddObject(TBV0052)
						qXKzBXo0[FN7].AddObject(TBV0052)
						F.AddObject(TBV0052)
						local cGBeq = VGJdue[FN7]
						local PRXb = cpNryuPy.width
						if mVKRd8 == "text" then
							UU(TBV0052, cGBeq)
						elseif mVKRd8 == "image" then
							setp(TBV0052, "Image", cGBeq)
						elseif mVKRd8 == "text-button" then
							UU(TBV0052, cGBeq)
							TBV0052.MouseButton1Click:Connect(function()
								cpNryuPy.callback(VGJdue, kdS)
							end)
						elseif mVKRd8 == "image-button" then
							setp(TBV0052, "Image", cGBeq)
							TBV0052.MouseButton1Click:Connect(function()
								cpNryuPy.callback(VGJdue, kdS)
							end)
						elseif mVKRd8 == "text-field" then
							UU(TBV0052, cGBeq)
							local t = cGBeq
							TBV0052.FocusLost:Connect(function(Jk3TbYo)
								local Nm61D3Il = cpNryuPy.callback(TBV0052.Text, VGJdue, kdS, Jk3TbYo)
								if Nm61D3Il then
									VGJdue[FN7] = Nm61D3Il
									UU(TBV0052, Nm61D3Il)
									t = Nm61D3Il
								else
									UU(TBV0052, t)
								end
							end)
						elseif mVKRd8 == "check-box" then
							yI[TBV0052] = {}
							if type(cpNryuPy.checked) == "table" then
								local Qjx7nk = seMLr(cpNryuPy.checked[1], cpNryuPy.checked[2])
								m6SCS0(Qjx7nk.GUI, EDE3.ZIndex)
								MvOaiq.AddStylist(Qjx7nk.Stylist, b2UK)
								yI[TBV0052].Checked = Qjx7nk
							else
								yI[TBV0052].Checked = cpNryuPy.checked
							end
							if type(cpNryuPy.unchecked) == "table" then
								local ZfqIP = seMLr(cpNryuPy.unchecked[1], cpNryuPy.unchecked[2])
								m6SCS0(ZfqIP.GUI, EDE3.ZIndex)
								MvOaiq.AddStylist(ZfqIP.Stylist, b2UK)
								yI[TBV0052].Unchecked = ZfqIP
							else
								yI[TBV0052].Unchecked = cpNryuPy.unchecked
							end
							YBciOAz2(TBV0052, cGBeq)
							TBV0052.MouseButton1Click:Connect(function()
								local p4ZD2RW = true
								if cpNryuPy.callback then
									p4ZD2RW = cpNryuPy.callback(VGJdue, kdS)
								end
								if p4ZD2RW then
									VGJdue[FN7] = not VGJdue[FN7]
									YBciOAz2(TBV0052, VGJdue[FN7])
								end
							end)
						end
						setp(TBV0052, "Size", UDim2.new(PRXb.Scale, PRXb.Offset, 1, 0))
						setp(TBV0052, "Position", UDim2.new(_B8W1YL.Scale, _B8W1YL.Offset, 0, 0))
						_B8W1YL = _B8W1YL + PRXb
					end
					OGMxal0[VGJdue] = zHapMi
					QlewVjkq[zHapMi] = VGJdue
					ncWw()
					return VGJdue
				end
				function kdS.RemoveRow(o)
					local QK5cr
					if type(o) == "number" or type(o) == "nil" then
						QK5cr = table.remove(MY16y, o)
					else
						for e575, OP in pairs(MY16y) do
							if OP == o then
								QK5cr = table.remove(MY16y, e575)
								break
							end
						end
					end
					if QK5cr then
						local HxUqj4B = qQpo[QK5cr]
						HxUqj4B.Destroy()
						qQpo[QK5cr] = nil
						local dryo7a = OGMxal0[QK5cr]
						QlewVjkq[dryo7a] = nil
						OGMxal0[QK5cr] = nil
						for Vvmt, z1jKKH in pairs(bc0w4j) do
							if z1jKKH == dryo7a then
								for Vvmt, A in pairs(z1jKKH:GetChildren()) do
									MvOaiq.RemoveObject(A)
									qXKzBXo0[Vvmt].RemoveObject(A)
									DUic_1K.RemoveObject(A)
								end
								table.remove(bc0w4j, Vvmt)
								break
							end
						end
						cJ.TotalSpace = #MY16y
						for i_ASR7X, lneZ2 in pairs(Q) do
							if lneZ2 == dryo7a then
								table.remove(Q, i_ASR7X)
								break
							end
						end
						dryo7a:Destroy()
					end
					ncWw()
					return QK5cr
				end
				do
					local wZLxwQr = {}
					for Z, b3h1 in pairs(MY16y) do
						wZLxwQr[Z] = b3h1
						MY16y[Z] = nil
					end
					for AGn = 1, #wZLxwQr do
						kdS.AddRow(wZLxwQr[AGn])
					end
				end
				NUhYw6R4(EDE3)
				function kdS.Destroy()
					local function EQVz(pYXX)
						for GvHSsw in pairs(pYXX) do
							pYXX[GvHSsw] = nil
						end
					end
					EQVz(kdS.Stylist)
					EQVz(kdS)
					EQVz(bc0w4j)
					EQVz(OGMxal0)
					EQVz(QlewVjkq)
					EQVz(Q)
					EQVz(yI)
					MvOaiq.Destroy()
					DUic_1K.Destroy()
					rVj9z4.Destroy()
					mWkmCx.Destroy()
					for XvK5, bK2 in pairs(qQpo) do
						bK2.Destroy()
						qQpo[XvK5] = nil
					end
					for U, FVkHUl7 in pairs(qXKzBXo0) do
						FVkHUl7.Destroy()
						qXKzBXo0[U] = nil
					end
					cJ.Destroy()
					sNyznm3W:Destroy()
					EDE3:Destroy()
				end
				kdS.Update()
				return kdS, EDE3
			end
			LB1Z.DetailedList = K
			local function qL(FOA, eF0tAUG, _x)
				eF0tAUG = eF0tAUG or 24
				_x = _x or 20
				local J2o6d = 0
				local r = {}
				local PKiW0 = {}
				local odc5tp = {}
				local t3yD = (NsoTwDs("Frame"))({
					Name = "TabContainer",
					Size = UDim2.new(0, 300, 0, 200),
					BackgroundTransparency = 1,
					(NsoTwDs("Frame"))({
						Name = "Content",
						Size = UDim2.new(1, 0, 1, -eF0tAUG),
						Position = UDim2.new(0, 0, 0, eF0tAUG),
						BackgroundColor3 = Color3.new(),
						BorderColor3 = Color3.new(1, 1, 1),
					}),
					(NsoTwDs("Frame"))({
						Parent = TabContainerFrame,
						Name = "Tabs",
						BackgroundTransparency = 1,
					}),
				})
				local _nofE2 = t3yD.Content
				local kPOaEej = t3yD.Tabs
				local XrKR = h_8(kPOaEej, true, true)
				local EZSc2rAA = zhzpBSx({
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.5,
					BorderColor3 = Color3.new(1, 1, 1),
					TextColor3 = Color3.new(1, 1, 1),
					Font = "ArialBold",
					FontSize = "Size14",
				})
				EZSc2rAA.AddObject(_nofE2)
				local r0aOmY = zhzpBSx({
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.5,
					BorderColor3 = Color3.new(1, 1, 1),
					TextColor3 = Color3.new(1, 1, 1),
					Font = "ArialBold",
					FontSize = "Size14",
				})
				local function hPQ(Yo)
					for nkWKbF, M9 in pairs(r) do
						if M9 == Yo then
							return nkWKbF
						end
					end
				end
				local function YzL3P1()
					return J2o6d, r[J2o6d]
				end
				local function R1FIoQI(cVvE, R8)
					local CsDz = #r + (R8 or 0)
					cVvE = math.floor(cVvE)
					return cVvE < 1 and 1 or cVvE > CsDz and CsDz or cVvE
				end
				local function a2(u)
					if #r > 0 then
						if type(u) ~= "number" then
							u = hPQ(u)
						end
						if u then
							u = R1FIoQI(u)
							if J2o6d > 0 then
								local m5STS = r[J2o6d]
								setp(m5STS, "Visible", false)
								local CJ4gk6Xx = PKiW0[m5STS]
								CJ4gk6Xx.LockAxis(nil, _x)
								r0aOmY.RemoveObject(CJ4gk6Xx, GUI)
								EZSc2rAA.AddObject(CJ4gk6Xx.GUI)
							end
							local Ru8E = r[u]
							setp(Ru8E, "Visible", true)
							local nK = PKiW0[Ru8E]
							nK.LockAxis(nil, eF0tAUG)
							EZSc2rAA.RemoveObject(nK.GUI)
							r0aOmY.AddObject(nK.GUI)
							J2o6d = u
						end
					else
						J2o6d = 0
					end
				end
				local function hrEWj(WwPLCA3t, YAwrq)
					if YAwrq then
						YAwrq = R1FIoQI(YAwrq, 1)
						table.insert(r, YAwrq, WwPLCA3t)
					else
						table.insert(r, WwPLCA3t)
						YAwrq = #r
					end
					setp(WwPLCA3t, "Visible", false)
					setp(WwPLCA3t, "Parent", _nofE2)
					local VHZ4I = (NsoTwDs("TextButton"))({
						Name = "Tab",
						Text = WwPLCA3t.Name,
					})
					local JTS = rHSjalVy(VHZ4I)
					PKiW0[WwPLCA3t] = JTS
					JTS.SetPadding(0, 4)
					JTS.LockAxis(nil, _x)
					EZSc2rAA.AddObject(VHZ4I)
					XrKR.AddObject(VHZ4I, YAwrq)
					VHZ4I.MouseButton1Click:Connect(function()
						a2(WwPLCA3t)
					end)
					odc5tp[WwPLCA3t] = WwPLCA3t.Changed:Connect(function(zRbXf)
						if zRbXf == "Name" then
							setp(VHZ4I, "Text", WwPLCA3t.Name)
						end
					end)
					if J2o6d == 0 then
						a2(YAwrq)
					elseif YAwrq <= J2o6d then
						J2o6d = J2o6d + 1
					end
				end
				local function Qgeq(caDLM)
					if #r > 0 then
						if type(caDLM) ~= "number" then
							if caDLM == nil then
								caDLM = #r
							else
								caDLM = hPQ(caDLM)
							end
						end
						if caDLM then
							caDLM = R1FIoQI(caDLM)
							local Pj = table.remove(r, caDLM)
							setp(Pj, "Parent", nil)
							odc5tp[Pj]:Disconnect()
							odc5tp[Pj] = nil
							local xm = PKiW0[Pj]
							XrKR.RemoveObject(caDLM)
							PKiW0[Pj] = nil
							xm.Destroy()
							if caDLM == J2o6d then
								a2(caDLM)
							elseif caDLM < J2o6d then
								J2o6d = J2o6d - 1
							end
							return Pj
						end
					end
				end
				local function ay_Dm(we, uv)
					if #r > 0 then
						if type(we) ~= "number" then
							we = hPQ(we)
						end
						if type(uv) ~= "number" then
							uv = hPQ(uv)
						end
						if we and uv then
							we = R1FIoQI(we)
							uv = R1FIoQI(uv)
							local eu = table.remove(r, we)
							table.insert(r, uv, eu)
							XrKR.MoveObject(we, uv)
							if we == J2o6d then
								J2o6d = uv
							elseif we > J2o6d and uv <= J2o6d then
								J2o6d = J2o6d + 1
							elseif we < J2o6d and uv >= J2o6d then
								J2o6d = J2o6d - 1
							end
						end
					end
				end
				local z8K0j = {
					GUI = t3yD,
					GetIndex = hPQ,
					GetSelectedIndex = YzL3P1,
					SelectTab = a2,
					AddTab = hrEWj,
					RemoveTab = Qgeq,
					MoveTab = ay_Dm,
					TabStylist = EZSc2rAA,
					SelectedTabStylist = r0aOmY,
				}
				NUhYw6R4(t3yD)
				local function yh()
					for j7Zsjoj in pairs(z8K0j) do
						z8K0j[j7Zsjoj] = nil
					end
					r0aOmY.Destroy()
					EZSc2rAA.Destroy()
					XrKR.Destroy()
					for VDXpXH, NT23H in pairs(odc5tp) do
						NT23H:Disconnect()
						odc5tp[VDXpXH] = nil
					end
					for N8WCvTtk, vk7 in pairs(r) do
						setp(vk7, "Parent", nil)
						r[N8WCvTtk] = nil
					end
					for aaOq, F7JMSq_H in pairs(PKiW0) do
						PKiW0[aaOq] = nil
						F7JMSq_H.Destroy()
					end
					t3yD:Destroy()
				end
				z8K0j.Destroy = yh
				if FOA then
					for BNZ09E, mcJGlQD6 in pairs(FOA) do
						hrEWj(mcJGlQD6, BNZ09E)
					end
				end
				return z8K0j, t3yD
			end
			LB1Z.TabContainer = qL
			local vfIyB = {}
			function vfIyB.Confirm(AcM1nG, mMJQWw, sC, RE)
				GlobalStylist = sC
					or Stylist({
						BackgroundColor3 = Color3.new(0, 0, 0),
						BorderColor3 = Color3.new(1, 1, 1),
						TextColor3 = Color3.new(1, 1, 1),
						Font = "ArialBold",
						FontSize = "Size14",
					})
				ButtonStylist = RE or Stylist({
					Style = "RobloxButton",
				})
				local mPRxk = zhzpBSx(style)
				local iVO = zhzpBSx(button_style)
				local S5PgiAbz = mPRxk.StylistIn(iVO)
				mPRxk.AddStylist(iVO)
				local jj1oYjc = (NsoTwDs("Frame"))({
					Name = "ConfirmDialog",
					Size = UDim2.new(1.5, 0, 1.5, 0),
					Position = UDim2.new(-0.25, 0, -0.25, 0),
					BorderSizePixel = 0,
					BackgroundTransparency = 0.5,
					BackgroundColor3 = Color3.new(0, 0, 0),
					Active = true,
					mPRxk.AddObject((NsoTwDs("Frame"))({
						Name = "DialogBox",
						Size = UDim2.new(0, 250, 0, 150),
						Position = UDim2.new(0.5, -125, 0.5, -75),
						(NsoTwDs("Frame"))({
							Name = "MarginBox",
							BackgroundTransparency = 1,
							Size = UDim2.new(1, -16, 1, -16),
							Position = UDim2.new(0, 8, 0, 8),
							mPRxk.AddObject((NsoTwDs("TextLabel"))({
								BackgroundTransparency = 1,
								TextScaled = true,
								Text = mMJQWw or "",
								Size = UDim2.new(1, -16, 0.8, -24),
								Position = UDim2.new(0, 8, 0, 8),
							})),
							(NsoTwDs("Frame"))({
								Name = "Buttons",
								BackgroundTransparency = 1,
								Size = UDim2.new(1, 0, 0.2, 0),
								Position = UDim2.new(0, 0, 0.8, 0),
								iVO.AddObject((NsoTwDs("TextButton"))({
									Name = "YesButton",
									Text = "Yes",
									Size = UDim2.new(1 / 3, 0, 1, 0),
									Position = UDim2.new(0 / 3, 0, 0, 0),
								})),
								iVO.AddObject((NsoTwDs("TextButton"))({
									Name = "NoButton",
									Text = "No",
									Size = UDim2.new(1 / 3, 0, 1, 0),
									Position = UDim2.new(1 / 3, 0, 0, 0),
								})),
								iVO.AddObject((NsoTwDs("TextButton"))({
									Name = "CancelButton",
									Text = "Cancel",
									Size = UDim2.new(1 / 3, 0, 1, 0),
									Position = UDim2.new(2 / 3, 0, 0, 0),
								})),
							}),
						}),
					})),
				})
				local YVjxMh = jj1oYjc.DialogBox.MarginBox.Buttons
				local sERpty = nil
				local R9WhkbR = Instance.new("BindableEvent")
				YVjxMh.YesButton.MouseButton1Click:Connect(function()
					sERpty = true
					R9WhkbR:Fire()
				end)
				YVjxMh.NoButton.MouseButton1Click:Connect(function()
					sERpty = false
					R9WhkbR:Fire()
				end)
				YVjxMh.CancelButton.MouseButton1Click:Connect(function()
					sERpty = nil
					R9WhkbR:Fire()
				end)
				m6SCS0(jj1oYjc, 10)
				setp(jj1oYjc, "Parent", AcM1nG)
				R9WhkbR.Event:Wait()
				jj1oYjc:Destroy()
				R9WhkbR:Destroy()
				if sC == nil then
					mPRxk.Destroy()
				elseif not S5PgiAbz then
					mPRxk.RemoveStylist(iVO)
				end
				if RE == nil then
					iVO.Destroy()
				end
				return sERpty
			end
			LB1Z.dialog = vfIyB
			do
				local Wjj = {}
				for X9n9mro, Uj6hK in pairs(N9L) do
					if type(X9n9mro) == "string" then
						table.insert(Wjj, X9n9mro)
					end
				end
				table.sort(Wjj)
				for qk3r, Otbx_3g in pairs(Wjj) do
					default_help = default_help .. "\t" .. Otbx_3g .. "\n"
				end
			end
			local quNsijN = {}
			quNsijN[false] = default_help
			function LB1Z.Help(XRg, Q7c8C2T)
				if type(XRg) == "string" then
					XRg = XRg:lower()
				end
				local Gz = quNsijN[XRg] or quNsijN[false]
				if not Q7c8C2T then
					warn(string.rep("_", 80))
					for XfMQy in (Gz:gsub("\r\n?", "\n")):gmatch("(.-)\n") do
						XfMQy = XfMQy:gsub(" ", "\160")
						XfMQy = XfMQy:gsub("\t", string.rep("\160", 8))
						warn(#XfMQy == 0 and "\160" or XfMQy)
					end
					warn("\160")
				end
				return Gz
			end
			for mu_2r, Es in pairs(N9L) do
				if type(mu_2r) == "string" then
					quNsijN[mu_2r:lower()] = Es
					local c = LB1Z[mu_2r]
					if type(c) == "function" then
						quNsijN[c] = Es
					end
				end
			end
			setmetatable(LB1Z, {
				__tostring = function()
					return ("%s GUI Library [v%s] (use %s.Help() for help)"):format(tczrIB, hDc_M, tczrIB)
				end,
			})
			_G.gloo = LB1Z
		end
		gloostart()
	end
end
LTServiceResolver = (function()
	local SY = (getgenv and getgenv()) or _G or {}
	local Mq = rawget(_G, "shared")
	local Dv = type(Mq) == "table" and Mq or (type(SY) == "table" and SY or nil)
	if Dv then
		local yf = rawget(Dv, "__lt_service_resolver")
		if type(yf) == "table" then
			return yf
		end
	end
	return nil
end)()
LTUIProtector = (function()
	local SY = (getgenv and getgenv()) or _G or {}
	local Mq = rawget(_G, "shared")
	local Dv = type(Mq) == "table" and Mq or (type(SY) == "table" and SY or nil)
	if Dv then
		local yf = rawget(Dv, "__lt_ui_protector")
		if type(yf) == "table" then
			return yf
		end
	end
	return nil
end)()
function LTGetService(n)
	if LTServiceResolver and type(LTServiceResolver.cs) == "function" then
		local Rf = cloneref and type(cloneref) == "function" and cloneref or function(x)
			return x
		end
		local ok, s = pcall(function()
			return LTServiceResolver.cs(n, Rf)
		end)
		if ok and s then
			return s
		end
	end
	if LTServiceResolver and type(LTServiceResolver.gs) == "function" then
		local ok, s = pcall(function()
			return LTServiceResolver.gs(n)
		end)
		if ok and s then
			return s
		end
	end
	return game:GetService(n)
end
function LTCallService(n, m, ...)
	if LTServiceResolver and type(LTServiceResolver.cm) == "function" then
		local ok, r = pcall(function(...)
			return LTServiceResolver.cm(n, m, ...)
		end, ...)
		if ok then
			return r
		end
	end
	local s = LTGetService(n)
	return s[m](s, ...)
end
function LTProtectUI(gui, opts)
	if LTUIProtector and type(LTUIProtector.protectUI) == "function" then
		local ok, protected = pcall(function()
			return LTUIProtector.protectUI(gui, opts)
		end)
		if ok and protected and typeof(protected) == "Instance" then
			return protected
		elseif ok and protected then
			return gui
		end
	end
	if gui and gui:IsA("ScreenGui") then
		pcall(function()
			setp(gui, "ZIndexBehavior", Enum.ZIndexBehavior.Global)
			setp(gui, "DisplayOrder", 999999999)
			setp(gui, "ResetOnSpawn", false)
			setp(gui, "IgnoreGuiInset", true)
		end)
	end
	return gui
end
F3XDebugEnabled = false
function F3XLog(level, message)
	if level == "debug" then
		return nil
	end
	local entry = "[F3X:" .. tostring(level) .. "] " .. tostring(message)
	warn(entry)
	return entry
end
function F3XDebug(message)
	return nil
end
function F3XWarn(message)
	return F3XLog("warn", message)
end
function F3XTraceback(err)
	if debug and type(debug.traceback) == "function" then
		return debug.traceback(tostring(err), 2)
	end
	return tostring(err)
end
function F3XSpawn(fn)
	if task and type(task.spawn) == "function" then
		task.spawn(fn)
	elseif type(spawn) == "function" then
		spawn(fn)
	else
		coroutine.wrap(function()
			task.wait()
			fn()
		end)()
	end
end
function LTLoadHelperAsync(name, url, cacheKey, assign)
	if type(loadstring or load) ~= "function" then
		F3XWarn(name .. " loader unavailable")
		return
	end
	F3XSpawn(function()
		local loader = loadstring or load
		local okSource, source = pcall(function()
			return game:HttpGet(url)
		end)
		if not okSource or type(source) ~= "string" or source == "" then
			F3XWarn(name .. " background fetch failed: " .. tostring(source))
			return
		end
		local okChunk, chunk = pcall(function()
			return loader(source, "@" .. name .. ".luau")
		end)
		if not okChunk or type(chunk) ~= "function" then
			F3XWarn(name .. " compile failed: " .. tostring(chunk))
			return
		end
		local okLoaded, loaded = xpcall(chunk, F3XTraceback)
		if not okLoaded or type(loaded) ~= "table" then
			F3XWarn(name .. " load failed: " .. tostring(loaded))
			return
		end
		local SY = (getgenv and getgenv()) or _G or {}
		local Mq = rawget(_G, "shared")
		local Dv = type(Mq) == "table" and Mq or (type(SY) == "table" and SY or nil)
		if Dv then
			Dv[cacheKey] = loaded
		end
		assign(loaded)
	end)
end
if not LTServiceResolver then
	LTLoadHelperAsync(
		"ServiceResolver",
		"https://ltseverydayyou.github.io/ServiceResolver.luau",
		"__lt_service_resolver",
		function(loaded)
			LTServiceResolver = loaded
		end
	)
end
if not LTUIProtector then
	LTLoadHelperAsync(
		"UIprotector",
		"https://ltseverydayyou.github.io/UIprotector.luau",
		"__lt_ui_protector",
		function(loaded)
			LTUIProtector = loaded
			if UI then
				LTProtectUI(UI, {
					name = "Building Tools by F3X (UI)",
					keepName = true,
					harden = true,
					deep = true,
					watch = true,
					rename = false,
				})
			end
		end
	)
end
Workspace = LTGetService("Workspace")
RunService = LTGetService("RunService")
Players = LTGetService("Players")
MarketplaceService = LTGetService("MarketplaceService")
ContentProvider = LTGetService("ContentProvider")
SoundService = LTGetService("SoundService")
UserInputService = LTGetService("UserInputService")
SelectionService = LTGetService("Selection")
CoreGui = LTGetService("CoreGui")
HttpService = LTGetService("HttpService")
ChangeHistoryService = LTGetService("ChangeHistoryService")
Assets = {
	DarkSlantedRectangle = "http://www.roblox.com/asset/?id=127774197",
	LightSlantedRectangle = "http://www.roblox.com/asset/?id=127772502",
	ActionCompletionSound = "http://www.roblox.com/asset/?id=99666917",
	ExpandArrow = "http://www.roblox.com/asset/?id=134367382",
	UndoActiveDecal = "http://www.roblox.com/asset/?id=141741408",
	UndoInactiveDecal = "http://www.roblox.com/asset/?id=142074557",
	RedoActiveDecal = "http://www.roblox.com/asset/?id=141741327",
	RedoInactiveDecal = "http://www.roblox.com/asset/?id=142074553",
	DeleteActiveDecal = "http://www.roblox.com/asset/?id=141896298",
	DeleteInactiveDecal = "http://www.roblox.com/asset/?id=142074644",
	ExportActiveDecal = "http://www.roblox.com/asset/?id=141741337",
	ExportInactiveDecal = "http://www.roblox.com/asset/?id=142074569",
	CloneActiveDecal = "http://www.roblox.com/asset/?id=142073926",
	CloneInactiveDecal = "http://www.roblox.com/asset/?id=142074563",
	PluginIcon = "http://www.roblox.com/asset/?id=142287521",
	GroupLockIcon = "http://www.roblox.com/asset/?id=175396862",
	GroupUnlockIcon = "http://www.roblox.com/asset/?id=160408836",
	GroupUpdateOKIcon = "http://www.roblox.com/asset/?id=164421681",
	GroupUpdateIcon = "http://www.roblox.com/asset/?id=160402908",
}
ToolAssetID = 142785488
Player = Players.LocalPlayer
Mouse = nil
if plugin then
	ToolType = "plugin"
	GUIContainer = CoreGui
	ToolbarButton = (plugin:CreateToolbar("Building Tools by F3X")):CreateButton(
		"",
		"Building Tools by F3X",
		Assets.PluginIcon
	)
elseif Tool:IsA("Tool") then
	ToolType = "tool"
	GUIContainer = Player:WaitForChild("PlayerGui")
end
RbxUtility = t
Support = {}
SupportLibrary = {}
function SupportLibrary.FindTableOccurrences(C, o0Xe6nHM)
	local ulAVnjc = {}
	for zF6Bw, zuKqH in pairs(C) do
		if zuKqH == o0Xe6nHM then
			table.insert(ulAVnjc, zF6Bw)
		end
	end
	return ulAVnjc
end
function SupportLibrary.FindTableOccurrence(litdqp, r)
	for n, uSzWLeSi in pairs(litdqp) do
		if uSzWLeSi == r then
			return n
		end
	end
	return nil
end
function SupportLibrary.IsInTable(phUBXWJ9, Qgtt7)
	for yTthTeWK, pG in pairs(phUBXWJ9) do
		if pG == Qgtt7 then
			return true
		end
	end
	return false
end
function SupportLibrary.Round(um_kO, ngCGBaF)
	local A8TTTd8 = 10 ^ (ngCGBaF or 0)
	return math.floor((um_kO * A8TTTd8 + 0.5)) / A8TTTd8
end
function SupportLibrary.CloneTable(yGa)
	local j4bdRB6o = getmetatable(yGa)
	return setmetatable({
		unpack(yGa),
	}, j4bdRB6o)
end
function SupportLibrary.GetAllDescendants(f8jh)
	local OLzzUp = {}
	for VlN, r in pairs(f8jh:GetChildren()) do
		table.insert(OLzzUp, r)
		for VlN, mhEYg in pairs(SupportLibrary.GetAllDescendants(r)) do
			table.insert(OLzzUp, mhEYg)
		end
	end
	return OLzzUp
end
function SupportLibrary.GetDescendantCount(rUJN6)
	local cYH30J = 0
	for VR, pyzkzd in pairs(rUJN6:GetChildren()) do
		cYH30J = cYH30J + 1
		cYH30J = cYH30J + SupportLibrary.GetDescendantCount(pyzkzd)
	end
	return cYH30J
end
function SupportLibrary.CloneParts(ksDuO71)
	local BAy = {}
	for tTCbo2, p in pairs(ksDuO71) do
		BAy[tTCbo2] = p:Clone()
	end
	return BAy
end
function SupportLibrary.SplitString(UNyk, cG0)
	local kzTZ7 = {}
	local f8SnhE4T = ("([^%s]+)"):format(cG0)
	UNyk:gsub(f8SnhE4T, function(aascxP)
		table.insert(kzTZ7, aascxP)
	end)
	return kzTZ7
end
function SupportLibrary.GetChildOfClass(eSG8f8ru, w2yJAi, lH1c)
	if not lH1c then
		for CHS, fQdTWIXs in pairs(eSG8f8ru:GetChildren()) do
			if fQdTWIXs.ClassName == w2yJAi then
				return fQdTWIXs
			end
		end
	else
		for QG, d78 in pairs(eSG8f8ru:GetChildren()) do
			if d78:IsA(w2yJAi) then
				return d78
			end
		end
	end
	return nil
end
function SupportLibrary.GetChildrenOfClass(C6pS, GwH, O)
	local sbuS4 = {}
	if not O then
		for Rrfir0, lXr in pairs(C6pS:GetChildren()) do
			if lXr.ClassName == GwH then
				table.insert(sbuS4, lXr)
			end
		end
	else
		for hz, f in pairs(C6pS:GetChildren()) do
			if f:IsA(GwH) then
				table.insert(sbuS4, f)
			end
		end
	end
	return sbuS4
end
function SupportLibrary.HSVToRGB(knCGg, UPf, amxXn)
	if UPf == 0 then
		return amxXn
	end
	local CSwsYPyj = math.floor(knCGg / 60)
	local I9I = knCGg / 60 - CSwsYPyj
	local aB = amxXn * (1 - UPf)
	local BiUZ8vx4 = amxXn * (1 - UPf * I9I)
	local v = amxXn * (1 - UPf * (1 - I9I))
	if CSwsYPyj == 0 then
		return amxXn, v, aB
	elseif CSwsYPyj == 1 then
		return BiUZ8vx4, amxXn, aB
	elseif CSwsYPyj == 2 then
		return aB, amxXn, v
	elseif CSwsYPyj == 3 then
		return aB, BiUZ8vx4, amxXn
	elseif CSwsYPyj == 4 then
		return v, aB, amxXn
	elseif CSwsYPyj == 5 then
		return amxXn, aB, BiUZ8vx4
	end
end
function SupportLibrary.RGBToHSV(W8dN, eL, U4G6f)
	local gmhVDH, a, NesXI
	local OZ8oHL = math.min(W8dN, eL, U4G6f)
	local sa = math.max(W8dN, eL, U4G6f)
	NesXI = sa
	local hT = sa - OZ8oHL
	if sa ~= 0 then
		a = hT / sa
	else
		a = 0
		gmhVDH = -1
		return gmhVDH, a, NesXI
	end
	if W8dN == sa then
		gmhVDH = (eL - U4G6f) / hT
	elseif eL == sa then
		gmhVDH = 2 + (U4G6f - W8dN) / hT
	else
		gmhVDH = 4 + (W8dN - eL) / hT
	end
	gmhVDH = gmhVDH * 60
	if gmhVDH < 0 then
		gmhVDH = gmhVDH + 360
	end
	return gmhVDH, a, NesXI
end
function SupportLibrary.IdentifyCommonItem(zICb5)
	local HB_RPF = nil
	for kJZlA, blNC in pairs(zICb5) do
		if kJZlA == 1 then
			HB_RPF = blNC
		elseif blNC ~= HB_RPF then
			return nil
		end
	end
	return HB_RPF
end
function SupportLibrary.IdentifyCommonProperty(l, y9)
	local z = {}
	for MjtdB7KS, _M_Cmn9C in pairs(l) do
		table.insert(z, _M_Cmn9C[y9])
	end
	return SupportLibrary.IdentifyCommonItem(z)
end
function SupportLibrary.CreateSignal()
	local GZQBW7r7 = {
		Connections = {},
		Connect = function(VHBi5G, Z1D6NL)
			table.insert(VHBi5G.Connections, Z1D6NL)
			local XAy = {
				Handler = Z1D6NL,
				Disconnect = function(zxyLTb)
					local rhMWaiC = SupportLibrary.FindTableOccurrences(VHBi5G.Connections, zxyLTb.Handler)
					if #rhMWaiC > 0 then
						local pM = rhMWaiC[1]
						table.remove(VHBi5G.Connections, pM)
					end
				end,
			}
			XAy.disconnect = XAy.Disconnect
			return XAy
		end,
		Fire = function(i, ...)
			for k, hr in pairs(i.Connections) do
				hr(...)
			end
		end,
	}
	GZQBW7r7.connect = GZQBW7r7.Connect
	GZQBW7r7.fire = GZQBW7r7.Fire
	return GZQBW7r7
end
function SupportLibrary.GetPartCorners(M)
	local Ucy5ca = table.insert
	local ycyK = (CFrame.new()).toWorldSpace
	local Yfm6hogh = CFrame.new
	local T6eti = M.CFrame
	local z7j, CGz, aukN3ZWX = M.Size.x / 2, M.Size.y / 2, M.Size.z / 2
	local eSCsri5 = {}
	Ucy5ca(eSCsri5, ycyK(T6eti, Yfm6hogh(z7j, CGz, aukN3ZWX)))
	Ucy5ca(eSCsri5, ycyK(T6eti, Yfm6hogh(-z7j, CGz, aukN3ZWX)))
	Ucy5ca(eSCsri5, ycyK(T6eti, Yfm6hogh(z7j, -CGz, aukN3ZWX)))
	Ucy5ca(eSCsri5, ycyK(T6eti, Yfm6hogh(z7j, CGz, -aukN3ZWX)))
	Ucy5ca(eSCsri5, ycyK(T6eti, Yfm6hogh(-z7j, CGz, -aukN3ZWX)))
	Ucy5ca(eSCsri5, ycyK(T6eti, Yfm6hogh(-z7j, -CGz, aukN3ZWX)))
	Ucy5ca(eSCsri5, ycyK(T6eti, Yfm6hogh(z7j, -CGz, -aukN3ZWX)))
	Ucy5ca(eSCsri5, ycyK(T6eti, Yfm6hogh(-z7j, -CGz, -aukN3ZWX)))
	return eSCsri5
end
function SupportLibrary.CreatePart(_g10f_)
	local r4cyFP
	if _g10f_ == "Normal" then
		r4cyFP = Instance.new("Part")
		setp(r4cyFP, "Size", Vector3.new(4, 1, 2))
	elseif _g10f_ == "Truss" then
		r4cyFP = Instance.new("TrussPart")
	elseif _g10f_ == "Wedge" then
		r4cyFP = Instance.new("WedgePart")
		setp(r4cyFP, "Size", Vector3.new(4, 1, 2))
	elseif _g10f_ == "Corner" then
		r4cyFP = Instance.new("CornerWedgePart")
	elseif _g10f_ == "Cylinder" then
		r4cyFP = Instance.new("Part")
		setp(r4cyFP, "Shape", "Cylinder")
		setp(r4cyFP, "TopSurface", Enum.SurfaceType.Smooth)
		setp(r4cyFP, "BottomSurface", Enum.SurfaceType.Smooth)
		setp(r4cyFP, "Size", Vector3.new(2, 2, 2))
	elseif _g10f_ == "Ball" then
		r4cyFP = Instance.new("Part")
		setp(r4cyFP, "Shape", "Ball")
		setp(r4cyFP, "TopSurface", Enum.SurfaceType.Smooth)
		setp(r4cyFP, "BottomSurface", Enum.SurfaceType.Smooth)
	elseif _g10f_ == "Seat" then
		r4cyFP = Instance.new("Seat")
		setp(r4cyFP, "Size", Vector3.new(4, 1, 2))
	elseif _g10f_ == "Vehicle Seat" then
		r4cyFP = Instance.new("VehicleSeat")
		setp(r4cyFP, "Size", Vector3.new(4, 1, 2))
	elseif _g10f_ == "Spawn" then
		r4cyFP = Instance.new("SpawnLocation")
		setp(r4cyFP, "Size", Vector3.new(4, 1, 2))
	end
	setp(r4cyFP, "Anchored", true)
	return r4cyFP
end
function SupportLibrary.ImportServices()
	local fcSy4_k0 = getfenv(2)
	fcSy4_k0.Workspace = LTGetService("Workspace")
	fcSy4_k0.RunService = LTGetService("RunService")
	fcSy4_k0.Players = LTGetService("Players")
	fcSy4_k0.MarketplaceService = LTGetService("MarketplaceService")
	fcSy4_k0.ContentProvider = LTGetService("ContentProvider")
	fcSy4_k0.SoundService = LTGetService("SoundService")
	fcSy4_k0.UserInputService = LTGetService("UserInputService")
	fcSy4_k0.SelectionService = LTGetService("Selection")
	fcSy4_k0.CoreGui = LTGetService("CoreGui")
	fcSy4_k0.HttpService = LTGetService("HttpService")
	fcSy4_k0.ChangeHistoryService = LTGetService("ChangeHistoryService")
	fcSy4_k0.ReplicatedStorage = LTGetService("ReplicatedStorage")
	fcSy4_k0.GroupService = LTGetService("GroupService")
	fcSy4_k0.ServerScriptService = LTGetService("ServerScriptService")
	fcSy4_k0.StarterGui = LTGetService("StarterGui")
end
function SupportLibrary.GetListMembers(TrC17, MEwJPiqM)
	local jHIxW_ = {}
	for gny, KabKdEUu in pairs(TrC17) do
		table.insert(jHIxW_, KabKdEUu[MEwJPiqM])
	end
	return jHIxW_
end
function SupportLibrary.AddUserInputListener(oQ8AOvfn, m, cX88nonB, kkWQP4)
	local m = Enum.UserInputType[m]
	return UserInputService["Input" .. oQ8AOvfn]:Connect(function(E4F, E)
		if E and not cX88nonB then
			return
		end
		if E4F.UserInputType ~= m then
			return
		end
		if m == Enum.UserInputType.Keyboard and UserInputService:GetFocusedTextBox() then
			return
		end
		kkWQP4(E4F)
	end)
end
function SupportLibrary.AddGuiInputListener(IGef7Hc5, RY1, bkV, VOG, r8MEhbdT)
	local bkV = Enum.UserInputType[bkV]
	return IGef7Hc5["Input" .. RY1]:Connect(function(klSf0ZT5, t85a4rt)
		if t85a4rt and not VOG then
			return
		end
		if klSf0ZT5.UserInputType ~= bkV then
			return
		end
		r8MEhbdT(klSf0ZT5)
	end)
end
function SupportLibrary.AreKeysPressed(...)
	local OfQcD = 0
	local Yj = SupportLibrary.GetListMembers(UserInputService:GetKeysPressed(), "KeyCode")
	for LvKdRh, _D in pairs({
		...,
		}) do
		if SupportLibrary.IsInTable(Yj, _D) then
			OfQcD = OfQcD + 1
		end
	end
	return OfQcD == #{
		...,
	}
end
function SupportLibrary.MergeTable(uYwYKAU, mq)
	for m7YIn, tYqOsEJ in pairs(mq) do
		table.insert(uYwYKAU, tYqOsEJ)
	end
	return uYwYKAU
end
function SupportLibrary.ClearTable(udoq)
	for boTHtaG in pairs(udoq) do
		udoq[boTHtaG] = nil
	end
	return udoq
end
Support = SupportLibrary
for zbQgT, duYPlVu in pairs(Assets) do
	coroutine.wrap(function()
		pcall(function()
			ContentProvider:Preload(duYPlVu)
		end)
	end)()
end
repeat
	task.wait(0)
until _G.gloo
Gloo = _G.gloo
HttpInterface = {}
RobloxAPIProxyBases = {
	["api.roblox.com"] = {
		"https://api.roproxy.com",
		"https://api.rotunnel.com",
		"https://api.roblox.com",
	},
	["games.roblox.com"] = {
		"https://games.roproxy.com",
		"https://games.rotunnel.com",
		"https://games.roblox.com",
	},
	["www.roblox.com"] = {
		"https://www.roproxy.com",
		"https://www.rotunnel.com",
		"https://www.roblox.com",
	},
}
function HttpInterface.GetProxyUrls(rJn)
	local Z4, Zl, b9U = tostring(rJn):match("^(https?)://([^/]+)(.*)$")
	if not Z4 or not Zl then
		return {
			rJn,
		}
	end
	local Ycp = RobloxAPIProxyBases[Zl:lower()]
	if not Ycp then
		return {
			rJn,
		}
	end
	local Xc = {}
	for Rk, o1 in ipairs(Ycp) do
		table.insert(Xc, o1 .. b9U)
	end
	return Xc
end
HttpInterface.GetAsync = function(n5, zl5hfbAb)
	local xVvJF = HttpService
	local zsKRyBU, YPb = {}, nil
	for fC, GwJ in ipairs(HttpInterface.GetProxyUrls(n5)) do
		local uxC, v6J = ypcall(function()
			return xVvJF:GetAsync(GwJ, zl5hfbAb)
		end)
		if uxC and v6J then
			return v6J
		end
		YPb = v6J
	end
	return unpack(zsKRyBU), YPb
end
HttpInterface.PostAsync = function(Lukg, rkKj, yAaxRZGY)
	local _Tb = HttpService
	local BJRFwSz, bH6 = {}, nil
	for F, Mg in ipairs(HttpInterface.GetProxyUrls(Lukg)) do
		local J2S, rsx = ypcall(function()
			return _Tb:PostAsync(Mg, rkKj, yAaxRZGY)
		end)
		if J2S and rsx then
			return rsx
		end
		bH6 = rsx
	end
	return unpack(BJRFwSz), bH6
end
HttpInterface.Test = function()
	local beAAh6T, yUaD, sPD = ypcall(function()
		return HttpInterface.GetAsync("https://api.roblox.com/marketplace/productinfo?assetId=" .. tostring(ToolAssetID))
	end)
	if beAAh6T and yUaD then
		return true
	end
	return false, beAAh6T and sPD or yUaD
end
local DFb100j = nil
do
	NG1 = Instance.new("Frame")
	setp(NG1, "Name", "Interfaces")
	NG2 = Instance.new("Frame")
	setp(NG2, "Active", true)
	setp(NG2, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG2, "BackgroundTransparency", 1)
	setp(NG2, "BorderSizePixel", 0)
	setp(NG2, "Name", "BTMaterialToolGUI")
	setp(NG2, "Position", UDim2.new(0, 0, 0, 172))
	setp(NG2, "Size", UDim2.new(0, 200, 0, 145))
	NG2.Draggable = true
	setp(NG2, "Parent", NG1)
	NG3 = Instance.new("Frame")
	setp(NG3, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG3, "BackgroundTransparency", 1)
	setp(NG3, "BorderSizePixel", 0)
	setp(NG3, "Name", "Title")
	setp(NG3, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG3, "Parent", NG2)
	NG4 = Instance.new("Frame")
	setp(NG4, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG4, "BorderSizePixel", 0)
	setp(NG4, "Name", "ColorBar")
	setp(NG4, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG4, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG4, "Parent", NG3)
	NG5 = Instance.new("TextLabel")
	setp(NG5, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG5, "BackgroundTransparency", 1)
	setp(NG5, "BorderSizePixel", 0)
	setp(NG5, "Name", "Label")
	setp(NG5, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG5, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG5, "Font", Enum.Font.ArialBold)
	setp(NG5, "FontSize", Enum.FontSize.Size10)
	setp(NG5, "Text", "MATERIAL TOOL")
	setp(NG5, "TextColor3", Color3.new(1, 1, 1))
	setp(NG5, "TextStrokeTransparency", 0)
	setp(NG5, "TextWrapped", true)
	setp(NG5, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG5, "Parent", NG3)
	NG6 = Instance.new("TextLabel")
	setp(NG6, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG6, "BackgroundTransparency", 1)
	setp(NG6, "BorderSizePixel", 0)
	setp(NG6, "Name", "F3XSignature")
	setp(NG6, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG6, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG6, "Font", Enum.Font.ArialBold)
	setp(NG6, "FontSize", Enum.FontSize.Size14)
	setp(NG6, "Text", "F3X")
	setp(NG6, "TextColor3", Color3.new(1, 1, 1))
	setp(NG6, "TextStrokeTransparency", 0.89999997615814)
	setp(NG6, "TextWrapped", true)
	setp(NG6, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG6, "Parent", NG3)
	NG7 = Instance.new("Frame")
	setp(NG7, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG7, "BackgroundTransparency", 1)
	setp(NG7, "BorderSizePixel", 0)
	setp(NG7, "Name", "MaterialOption")
	setp(NG7, "Position", UDim2.new(0, 14, 0, 30))
	setp(NG7, "Size", UDim2.new(1, -14, 0, 25))
	setp(NG7, "Parent", NG2)
	NG8 = Instance.new("TextLabel")
	setp(NG8, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG8, "BackgroundTransparency", 1)
	setp(NG8, "BorderSizePixel", 0)
	setp(NG8, "Name", "Label")
	setp(NG8, "Size", UDim2.new(0, 40, 0, 25))
	setp(NG8, "Font", Enum.Font.ArialBold)
	setp(NG8, "FontSize", Enum.FontSize.Size10)
	setp(NG8, "Text", "Material")
	setp(NG8, "TextColor3", Color3.new(1, 1, 1))
	setp(NG8, "TextStrokeTransparency", 0)
	setp(NG8, "TextWrapped", true)
	setp(NG8, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG8, "Parent", NG7)
	NG9 = Instance.new("Frame")
	setp(NG9, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG9, "BackgroundTransparency", 1)
	setp(NG9, "BorderSizePixel", 0)
	setp(NG9, "Name", "TransparencyOption")
	setp(NG9, "Position", UDim2.new(0, 0, 0, 65))
	setp(NG9, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG9, "Parent", NG2)
	NG10 = Instance.new("TextLabel")
	setp(NG10, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG10, "BackgroundTransparency", 1)
	setp(NG10, "BorderSizePixel", 0)
	setp(NG10, "Name", "Label")
	setp(NG10, "Position", UDim2.new(0, 14, 0, 0))
	setp(NG10, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG10, "Font", Enum.Font.ArialBold)
	setp(NG10, "FontSize", Enum.FontSize.Size10)
	setp(NG10, "Text", "Transparency")
	setp(NG10, "TextColor3", Color3.new(1, 1, 1))
	setp(NG10, "TextStrokeTransparency", 0)
	setp(NG10, "TextWrapped", true)
	setp(NG10, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG10, "Parent", NG9)
	NG11 = Instance.new("Frame")
	setp(NG11, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG11, "BackgroundTransparency", 1)
	setp(NG11, "BorderSizePixel", 0)
	setp(NG11, "Name", "TransparencyInput")
	setp(NG11, "Position", UDim2.new(0, 90, 0, 0))
	setp(NG11, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG11, "Parent", NG9)
	NG12 = Instance.new("TextButton")
	setp(NG12, "Active", true)
	setp(NG12, "AutoButtonColor", false)
	setp(NG12, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG12, "BackgroundTransparency", 1)
	setp(NG12, "BorderSizePixel", 0)
	NG12.Selectable = true
	setp(NG12, "Size", UDim2.new(1, 0, 1, 0))
	NG12.Style = Enum.ButtonStyle.Custom
	setp(NG12, "ZIndex", 2)
	setp(NG12, "Font", Enum.Font.Legacy)
	setp(NG12, "FontSize", Enum.FontSize.Size8)
	setp(NG12, "Text", "")
	setp(NG12, "Parent", NG11)
	NG13 = Instance.new("ImageLabel")
	setp(NG13, "Active", false)
	setp(NG13, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG13, "BackgroundTransparency", 1)
	setp(NG13, "BorderSizePixel", 0)
	setp(NG13, "Name", "Background")
	NG13.Selectable = false
	setp(NG13, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG13, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG13, "Parent", NG11)
	NG14 = Instance.new("Frame")
	setp(NG14, "BorderSizePixel", 0)
	setp(NG14, "Name", "SelectedIndicator")
	setp(NG14, "Position", UDim2.new(0, 5, 0, -2))
	setp(NG14, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG14, "Parent", NG11)
	NG15 = Instance.new("TextBox")
	setp(NG15, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG15, "BackgroundTransparency", 1)
	setp(NG15, "BorderSizePixel", 0)
	setp(NG15, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG15, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG15, "Font", Enum.Font.ArialBold)
	setp(NG15, "FontSize", Enum.FontSize.Size10)
	setp(NG15, "Text", "")
	setp(NG15, "TextColor3", Color3.new(1, 1, 1))
	setp(NG15, "Parent", NG11)
	NG16 = Instance.new("Frame")
	setp(NG16, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG16, "BackgroundTransparency", 1)
	setp(NG16, "BorderSizePixel", 0)
	setp(NG16, "Name", "ReflectanceOption")
	setp(NG16, "Position", UDim2.new(0, 0, 0, 100))
	setp(NG16, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG16, "Parent", NG2)
	NG17 = Instance.new("TextLabel")
	setp(NG17, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG17, "BackgroundTransparency", 1)
	setp(NG17, "BorderSizePixel", 0)
	setp(NG17, "Name", "Label")
	setp(NG17, "Position", UDim2.new(0, 14, 0, 0))
	setp(NG17, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG17, "Font", Enum.Font.ArialBold)
	setp(NG17, "FontSize", Enum.FontSize.Size10)
	setp(NG17, "Text", "Reflectance")
	setp(NG17, "TextColor3", Color3.new(1, 1, 1))
	setp(NG17, "TextStrokeTransparency", 0)
	setp(NG17, "TextWrapped", true)
	setp(NG17, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG17, "Parent", NG16)
	NG18 = Instance.new("Frame")
	setp(NG18, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG18, "BackgroundTransparency", 1)
	setp(NG18, "BorderSizePixel", 0)
	setp(NG18, "Name", "ReflectanceInput")
	setp(NG18, "Position", UDim2.new(0, 85, 0, 0))
	setp(NG18, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG18, "Parent", NG16)
	NG19 = Instance.new("TextButton")
	setp(NG19, "Active", true)
	setp(NG19, "AutoButtonColor", false)
	setp(NG19, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG19, "BackgroundTransparency", 1)
	setp(NG19, "BorderSizePixel", 0)
	NG19.Selectable = true
	setp(NG19, "Size", UDim2.new(1, 0, 1, 0))
	NG19.Style = Enum.ButtonStyle.Custom
	setp(NG19, "ZIndex", 2)
	setp(NG19, "Font", Enum.Font.Legacy)
	setp(NG19, "FontSize", Enum.FontSize.Size8)
	setp(NG19, "Text", "")
	setp(NG19, "Parent", NG18)
	NG20 = Instance.new("Frame")
	setp(NG20, "BorderSizePixel", 0)
	setp(NG20, "Name", "SelectedIndicator")
	setp(NG20, "Position", UDim2.new(0, 5, 0, -2))
	setp(NG20, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG20, "Parent", NG18)
	NG21 = Instance.new("ImageLabel")
	setp(NG21, "Active", false)
	setp(NG21, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG21, "BackgroundTransparency", 1)
	setp(NG21, "BorderSizePixel", 0)
	setp(NG21, "Name", "Background")
	NG21.Selectable = false
	setp(NG21, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG21, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG21, "Parent", NG18)
	NG22 = Instance.new("TextBox")
	setp(NG22, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG22, "BackgroundTransparency", 1)
	setp(NG22, "BorderSizePixel", 0)
	setp(NG22, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG22, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG22, "Font", Enum.Font.ArialBold)
	setp(NG22, "FontSize", Enum.FontSize.Size10)
	setp(NG22, "Text", "")
	setp(NG22, "TextColor3", Color3.new(1, 1, 1))
	setp(NG22, "Parent", NG18)
	NG23 = Instance.new("Frame")
	setp(NG23, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG23, "BackgroundTransparency", 1)
	setp(NG23, "BorderSizePixel", 0)
	setp(NG23, "Name", "Bottom")
	setp(NG23, "Position", UDim2.new(0, 5, 1, -10))
	setp(NG23, "Size", UDim2.new(1, -5, 0, 20))
	setp(NG23, "Parent", NG2)
	NG24 = Instance.new("Frame")
	setp(NG24, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG24, "BorderSizePixel", 0)
	setp(NG24, "Name", "ColorBar")
	setp(NG24, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG24, "Parent", NG23)
	NG25 = Instance.new("TextLabel")
	setp(NG25, "BackgroundTransparency", 1)
	setp(NG25, "BorderSizePixel", 0)
	setp(NG25, "Name", "SelectNote")
	setp(NG25, "Position", UDim2.new(0, 10, 0, 27))
	setp(NG25, "Size", UDim2.new(1, -10, 0, 15))
	setp(NG25, "Visible", false)
	setp(NG25, "FontSize", Enum.FontSize.Size14)
	setp(NG25, "Text", "Select something to use this tool.")
	setp(NG25, "TextColor3", Color3.new(1, 1, 1))
	setp(NG25, "TextScaled", true)
	setp(NG25, "TextStrokeTransparency", 0.5)
	setp(NG25, "TextWrapped", true)
	setp(NG25, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG25, "Parent", NG2)
	NG26 = Instance.new("Frame")
	setp(NG26, "Active", true)
	setp(NG26, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG26, "BackgroundTransparency", 1)
	setp(NG26, "BorderSizePixel", 0)
	setp(NG26, "Name", "BTNewPartToolGUI")
	setp(NG26, "Position", UDim2.new(0, 0, 0, 280))
	setp(NG26, "Size", UDim2.new(0, 220, 0, 90))
	NG26.Draggable = true
	setp(NG26, "Parent", NG1)
	NG27 = Instance.new("Frame")
	setp(NG27, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG27, "BackgroundTransparency", 1)
	setp(NG27, "BorderSizePixel", 0)
	setp(NG27, "Name", "Title")
	setp(NG27, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG27, "Parent", NG26)
	NG28 = Instance.new("Frame")
	setp(NG28, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG28, "BorderSizePixel", 0)
	setp(NG28, "Name", "ColorBar")
	setp(NG28, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG28, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG28, "Parent", NG27)
	NG29 = Instance.new("TextLabel")
	setp(NG29, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG29, "BackgroundTransparency", 1)
	setp(NG29, "BorderSizePixel", 0)
	setp(NG29, "Name", "Label")
	setp(NG29, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG29, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG29, "Font", Enum.Font.ArialBold)
	setp(NG29, "FontSize", Enum.FontSize.Size10)
	setp(NG29, "Text", "NEW PART TOOL")
	setp(NG29, "TextColor3", Color3.new(1, 1, 1))
	setp(NG29, "TextStrokeTransparency", 0)
	setp(NG29, "TextWrapped", true)
	setp(NG29, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG29, "Parent", NG27)
	NG30 = Instance.new("TextLabel")
	setp(NG30, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG30, "BackgroundTransparency", 1)
	setp(NG30, "BorderSizePixel", 0)
	setp(NG30, "Name", "F3XSignature")
	setp(NG30, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG30, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG30, "Font", Enum.Font.ArialBold)
	setp(NG30, "FontSize", Enum.FontSize.Size14)
	setp(NG30, "Text", "F3X")
	setp(NG30, "TextColor3", Color3.new(1, 1, 1))
	setp(NG30, "TextStrokeTransparency", 0.89999997615814)
	setp(NG30, "TextWrapped", true)
	setp(NG30, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG30, "Parent", NG27)
	NG31 = Instance.new("Frame")
	setp(NG31, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG31, "BackgroundTransparency", 1)
	setp(NG31, "BorderSizePixel", 0)
	setp(NG31, "Name", "TypeOption")
	setp(NG31, "Position", UDim2.new(0, 0, 0, 30))
	setp(NG31, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG31, "Parent", NG26)
	NG32 = Instance.new("TextLabel")
	setp(NG32, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG32, "BackgroundTransparency", 1)
	setp(NG32, "BorderSizePixel", 0)
	setp(NG32, "Name", "Label")
	setp(NG32, "Position", UDim2.new(0, 14, 0, 0))
	setp(NG32, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG32, "Font", Enum.Font.ArialBold)
	setp(NG32, "FontSize", Enum.FontSize.Size10)
	setp(NG32, "Text", "Part Type")
	setp(NG32, "TextColor3", Color3.new(1, 1, 1))
	setp(NG32, "TextStrokeTransparency", 0)
	setp(NG32, "TextWrapped", true)
	setp(NG32, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG32, "Parent", NG31)
	NG33 = Instance.new("Frame")
	setp(NG33, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG33, "BackgroundTransparency", 1)
	setp(NG33, "BorderSizePixel", 0)
	setp(NG33, "Name", "Tip")
	setp(NG33, "Position", UDim2.new(0, 5, 0, 70))
	setp(NG33, "Size", UDim2.new(1, -5, 0, 20))
	setp(NG33, "Parent", NG26)
	NG34 = Instance.new("Frame")
	setp(NG34, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG34, "BorderSizePixel", 0)
	setp(NG34, "Name", "ColorBar")
	setp(NG34, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG34, "Parent", NG33)
	NG35 = Instance.new("TextLabel")
	setp(NG35, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG35, "BackgroundTransparency", 1)
	setp(NG35, "BorderSizePixel", 0)
	setp(NG35, "Name", "Text")
	setp(NG35, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG35, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG35, "Font", Enum.Font.ArialBold)
	setp(NG35, "FontSize", Enum.FontSize.Size10)
	setp(NG35, "Text", "TIP: Point and click for a new part.")
	setp(NG35, "TextColor3", Color3.new(1, 1, 1))
	setp(NG35, "TextStrokeTransparency", 0.5)
	setp(NG35, "TextWrapped", true)
	setp(NG35, "Parent", NG33)
	NG36 = Instance.new("Frame")
	setp(NG36, "Active", true)
	setp(NG36, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG36, "BackgroundTransparency", 1)
	setp(NG36, "BorderSizePixel", 0)
	setp(NG36, "Name", "BTPaintToolGUI")
	setp(NG36, "Position", UDim2.new(0, 0, 0, 230))
	setp(NG36, "Size", UDim2.new(0, 205, 0, 230))
	NG36.Draggable = true
	setp(NG36, "Parent", NG1)
	NG37 = Instance.new("Frame")
	setp(NG37, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG37, "BackgroundTransparency", 1)
	setp(NG37, "BorderSizePixel", 0)
	setp(NG37, "Name", "Title")
	setp(NG37, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG37, "Parent", NG36)
	NG38 = Instance.new("Frame")
	setp(NG38, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG38, "BorderSizePixel", 0)
	setp(NG38, "Name", "ColorBar")
	setp(NG38, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG38, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG38, "Parent", NG37)
	NG39 = Instance.new("TextLabel")
	setp(NG39, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG39, "BackgroundTransparency", 1)
	setp(NG39, "BorderSizePixel", 0)
	setp(NG39, "Name", "Label")
	setp(NG39, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG39, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG39, "Font", Enum.Font.ArialBold)
	setp(NG39, "FontSize", Enum.FontSize.Size10)
	setp(NG39, "Text", "PAINT TOOL")
	setp(NG39, "TextColor3", Color3.new(1, 1, 1))
	setp(NG39, "TextStrokeTransparency", 0)
	setp(NG39, "TextWrapped", true)
	setp(NG39, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG39, "Parent", NG37)
	NG40 = Instance.new("TextLabel")
	setp(NG40, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG40, "BackgroundTransparency", 1)
	setp(NG40, "BorderSizePixel", 0)
	setp(NG40, "Name", "F3XSignature")
	setp(NG40, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG40, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG40, "Font", Enum.Font.ArialBold)
	setp(NG40, "FontSize", Enum.FontSize.Size14)
	setp(NG40, "Text", "F3X")
	setp(NG40, "TextColor3", Color3.new(1, 1, 1))
	setp(NG40, "TextStrokeTransparency", 0.89999997615814)
	setp(NG40, "TextWrapped", true)
	setp(NG40, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG40, "Parent", NG37)
	NG41 = Instance.new("Frame")
	setp(NG41, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG41, "BackgroundTransparency", 1)
	setp(NG41, "Name", "Palette")
	setp(NG41, "Position", UDim2.new(0, 5, 0, 20))
	setp(NG41, "Size", UDim2.new(0, 205, 0, 205))
	setp(NG41, "Parent", NG36)
	NG42 = Instance.new("TextButton")
	setp(NG42, "Active", true)
	setp(NG42, "BackgroundColor3", Color3.new(0.643137, 0.741176, 0.278431))
	setp(NG42, "BorderSizePixel", 0)
	setp(NG42, "Name", "Br. yellowish green")
	setp(NG42, "Position", UDim2.new(0, 5, 0, 5))
	NG42.Selectable = true
	setp(NG42, "Size", UDim2.new(0, 20, 0, 20))
	NG42.Style = Enum.ButtonStyle.Custom
	setp(NG42, "Font", Enum.Font.Arial)
	setp(NG42, "FontSize", Enum.FontSize.Size10)
	setp(NG42, "Text", "")
	setp(NG42, "TextColor3", Color3.new(1, 1, 1))
	setp(NG42, "TextStrokeTransparency", 0.75)
	setp(NG42, "Parent", NG41)
	NG43 = Instance.new("TextButton")
	setp(NG43, "Active", true)
	setp(NG43, "BackgroundColor3", Color3.new(0.960784, 0.803922, 0.188235))
	setp(NG43, "BorderSizePixel", 0)
	setp(NG43, "Name", "Bright yellow")
	setp(NG43, "Position", UDim2.new(0, 30, 0, 5))
	NG43.Selectable = true
	setp(NG43, "Size", UDim2.new(0, 20, 0, 20))
	NG43.Style = Enum.ButtonStyle.Custom
	setp(NG43, "Font", Enum.Font.Arial)
	setp(NG43, "FontSize", Enum.FontSize.Size10)
	setp(NG43, "Text", "")
	setp(NG43, "TextColor3", Color3.new(1, 1, 1))
	setp(NG43, "TextStrokeTransparency", 0.75)
	setp(NG43, "Parent", NG41)
	NG44 = Instance.new("TextButton")
	setp(NG44, "Active", true)
	setp(NG44, "BackgroundColor3", Color3.new(0.854902, 0.521569, 0.254902))
	setp(NG44, "BorderSizePixel", 0)
	setp(NG44, "Name", "Bright orange")
	setp(NG44, "Position", UDim2.new(0, 55, 0, 5))
	NG44.Selectable = true
	setp(NG44, "Size", UDim2.new(0, 20, 0, 20))
	NG44.Style = Enum.ButtonStyle.Custom
	setp(NG44, "Font", Enum.Font.Arial)
	setp(NG44, "FontSize", Enum.FontSize.Size10)
	setp(NG44, "Text", "")
	setp(NG44, "TextColor3", Color3.new(1, 1, 1))
	setp(NG44, "TextStrokeTransparency", 0.75)
	setp(NG44, "Parent", NG41)
	NG45 = Instance.new("TextButton")
	setp(NG45, "Active", true)
	setp(NG45, "BackgroundColor3", Color3.new(0.768628, 0.156863, 0.109804))
	setp(NG45, "BorderSizePixel", 0)
	setp(NG45, "Name", "Bright red")
	setp(NG45, "Position", UDim2.new(0, 80, 0, 5))
	NG45.Selectable = true
	setp(NG45, "Size", UDim2.new(0, 20, 0, 20))
	NG45.Style = Enum.ButtonStyle.Custom
	setp(NG45, "Font", Enum.Font.Arial)
	setp(NG45, "FontSize", Enum.FontSize.Size10)
	setp(NG45, "Text", "")
	setp(NG45, "TextColor3", Color3.new(1, 1, 1))
	setp(NG45, "TextStrokeTransparency", 0.75)
	setp(NG45, "Parent", NG41)
	NG46 = Instance.new("TextButton")
	setp(NG46, "Active", true)
	setp(NG46, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG46, "BorderSizePixel", 0)
	setp(NG46, "Name", "Bright violet")
	setp(NG46, "Position", UDim2.new(0, 105, 0, 5))
	NG46.Selectable = true
	setp(NG46, "Size", UDim2.new(0, 20, 0, 20))
	NG46.Style = Enum.ButtonStyle.Custom
	setp(NG46, "Font", Enum.Font.Arial)
	setp(NG46, "FontSize", Enum.FontSize.Size10)
	setp(NG46, "Text", "")
	setp(NG46, "TextColor3", Color3.new(1, 1, 1))
	setp(NG46, "TextStrokeTransparency", 0.75)
	setp(NG46, "Parent", NG41)
	NG47 = Instance.new("TextButton")
	setp(NG47, "Active", true)
	setp(NG47, "BackgroundColor3", Color3.new(0.0509804, 0.411765, 0.67451))
	setp(NG47, "BorderSizePixel", 0)
	setp(NG47, "Name", "Bright blue")
	setp(NG47, "Position", UDim2.new(0, 130, 0, 5))
	NG47.Selectable = true
	setp(NG47, "Size", UDim2.new(0, 20, 0, 20))
	NG47.Style = Enum.ButtonStyle.Custom
	setp(NG47, "Font", Enum.Font.Arial)
	setp(NG47, "FontSize", Enum.FontSize.Size10)
	setp(NG47, "Text", "")
	setp(NG47, "TextColor3", Color3.new(1, 1, 1))
	setp(NG47, "TextStrokeTransparency", 0.75)
	setp(NG47, "Parent", NG41)
	NG48 = Instance.new("TextButton")
	setp(NG48, "Active", true)
	setp(NG48, "BackgroundColor3", Color3.new(0, 0.560784, 0.611765))
	setp(NG48, "BorderSizePixel", 0)
	setp(NG48, "Name", "Bright bluish green")
	setp(NG48, "Position", UDim2.new(0, 155, 0, 5))
	NG48.Selectable = true
	setp(NG48, "Size", UDim2.new(0, 20, 0, 20))
	NG48.Style = Enum.ButtonStyle.Custom
	setp(NG48, "Font", Enum.Font.Arial)
	setp(NG48, "FontSize", Enum.FontSize.Size10)
	setp(NG48, "Text", "")
	setp(NG48, "TextColor3", Color3.new(1, 1, 1))
	setp(NG48, "TextStrokeTransparency", 0.75)
	setp(NG48, "Parent", NG41)
	NG49 = Instance.new("TextButton")
	setp(NG49, "Active", true)
	setp(NG49, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG49, "BorderSizePixel", 0)
	setp(NG49, "Name", "Bright green")
	setp(NG49, "Position", UDim2.new(0, 180, 0, 5))
	NG49.Selectable = true
	setp(NG49, "Size", UDim2.new(0, 20, 0, 20))
	NG49.Style = Enum.ButtonStyle.Custom
	setp(NG49, "Font", Enum.Font.Arial)
	setp(NG49, "FontSize", Enum.FontSize.Size10)
	setp(NG49, "Text", "")
	setp(NG49, "TextColor3", Color3.new(1, 1, 1))
	setp(NG49, "TextStrokeTransparency", 0.75)
	setp(NG49, "Parent", NG41)
	NG50 = Instance.new("TextButton")
	setp(NG50, "Active", true)
	setp(NG50, "BackgroundColor3", Color3.new(0.972549, 0.972549, 0.972549))
	setp(NG50, "BorderSizePixel", 0)
	setp(NG50, "Name", "Institutional white")
	setp(NG50, "Position", UDim2.new(0, 5, 0, 30))
	NG50.Selectable = true
	setp(NG50, "Size", UDim2.new(0, 20, 0, 20))
	NG50.Style = Enum.ButtonStyle.Custom
	setp(NG50, "Font", Enum.Font.Arial)
	setp(NG50, "FontSize", Enum.FontSize.Size10)
	setp(NG50, "Text", "")
	setp(NG50, "TextColor3", Color3.new(1, 1, 1))
	setp(NG50, "TextStrokeTransparency", 0.75)
	setp(NG50, "Parent", NG41)
	NG51 = Instance.new("TextButton")
	setp(NG51, "Active", true)
	setp(NG51, "BackgroundColor3", Color3.new(0.94902, 0.952941, 0.952941))
	setp(NG51, "BorderSizePixel", 0)
	setp(NG51, "Name", "White")
	setp(NG51, "Position", UDim2.new(0, 30, 0, 30))
	NG51.Selectable = true
	setp(NG51, "Size", UDim2.new(0, 20, 0, 20))
	NG51.Style = Enum.ButtonStyle.Custom
	setp(NG51, "Font", Enum.Font.Arial)
	setp(NG51, "FontSize", Enum.FontSize.Size10)
	setp(NG51, "Text", "")
	setp(NG51, "TextColor3", Color3.new(1, 1, 1))
	setp(NG51, "TextStrokeTransparency", 0.75)
	setp(NG51, "Parent", NG41)
	NG52 = Instance.new("TextButton")
	setp(NG52, "Active", true)
	setp(NG52, "BackgroundColor3", Color3.new(0.898039, 0.894118, 0.87451))
	setp(NG52, "BorderSizePixel", 0)
	setp(NG52, "Name", "Light stone grey")
	setp(NG52, "Position", UDim2.new(0, 55, 0, 30))
	NG52.Selectable = true
	setp(NG52, "Size", UDim2.new(0, 20, 0, 20))
	NG52.Style = Enum.ButtonStyle.Custom
	setp(NG52, "Font", Enum.Font.Arial)
	setp(NG52, "FontSize", Enum.FontSize.Size10)
	setp(NG52, "Text", "")
	setp(NG52, "TextColor3", Color3.new(1, 1, 1))
	setp(NG52, "TextStrokeTransparency", 0.75)
	setp(NG52, "Parent", NG41)
	NG53 = Instance.new("TextButton")
	setp(NG53, "Active", true)
	setp(NG53, "BackgroundColor3", Color3.new(0.803922, 0.803922, 0.803922))
	setp(NG53, "BorderSizePixel", 0)
	setp(NG53, "Name", "Mid gray")
	setp(NG53, "Position", UDim2.new(0, 80, 0, 30))
	NG53.Selectable = true
	setp(NG53, "Size", UDim2.new(0, 20, 0, 20))
	NG53.Style = Enum.ButtonStyle.Custom
	setp(NG53, "Font", Enum.Font.Arial)
	setp(NG53, "FontSize", Enum.FontSize.Size10)
	setp(NG53, "Text", "")
	setp(NG53, "TextColor3", Color3.new(1, 1, 1))
	setp(NG53, "TextStrokeTransparency", 0.75)
	setp(NG53, "Parent", NG41)
	NG54 = Instance.new("TextButton")
	setp(NG54, "Active", true)
	setp(NG54, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG54, "BorderSizePixel", 0)
	setp(NG54, "Name", "Medium stone grey")
	setp(NG54, "Position", UDim2.new(0, 105, 0, 30))
	NG54.Selectable = true
	setp(NG54, "Size", UDim2.new(0, 20, 0, 20))
	NG54.Style = Enum.ButtonStyle.Custom
	setp(NG54, "Font", Enum.Font.Arial)
	setp(NG54, "FontSize", Enum.FontSize.Size10)
	setp(NG54, "Text", "")
	setp(NG54, "TextColor3", Color3.new(1, 1, 1))
	setp(NG54, "TextStrokeTransparency", 0.75)
	setp(NG54, "Parent", NG41)
	NG55 = Instance.new("TextButton")
	setp(NG55, "Active", true)
	setp(NG55, "BackgroundColor3", Color3.new(0.388235, 0.372549, 0.384314))
	setp(NG55, "BorderSizePixel", 0)
	setp(NG55, "Name", "Dark stone grey")
	setp(NG55, "Position", UDim2.new(0, 130, 0, 30))
	NG55.Selectable = true
	setp(NG55, "Size", UDim2.new(0, 20, 0, 20))
	NG55.Style = Enum.ButtonStyle.Custom
	setp(NG55, "Font", Enum.Font.Arial)
	setp(NG55, "FontSize", Enum.FontSize.Size10)
	setp(NG55, "Text", "")
	setp(NG55, "TextColor3", Color3.new(1, 1, 1))
	setp(NG55, "TextStrokeTransparency", 0.75)
	setp(NG55, "Parent", NG41)
	NG56 = Instance.new("TextButton")
	setp(NG56, "Active", true)
	setp(NG56, "BackgroundColor3", Color3.new(0.105882, 0.164706, 0.207843))
	setp(NG56, "BorderSizePixel", 0)
	setp(NG56, "Name", "Black")
	setp(NG56, "Position", UDim2.new(0, 155, 0, 30))
	NG56.Selectable = true
	setp(NG56, "Size", UDim2.new(0, 20, 0, 20))
	NG56.Style = Enum.ButtonStyle.Custom
	setp(NG56, "Font", Enum.Font.Arial)
	setp(NG56, "FontSize", Enum.FontSize.Size10)
	setp(NG56, "Text", "")
	setp(NG56, "TextColor3", Color3.new(1, 1, 1))
	setp(NG56, "TextStrokeTransparency", 0.75)
	setp(NG56, "Parent", NG41)
	NG57 = Instance.new("TextButton")
	setp(NG57, "Active", true)
	setp(NG57, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG57, "BorderSizePixel", 0)
	setp(NG57, "Name", "Really black")
	setp(NG57, "Position", UDim2.new(0, 180, 0, 30))
	NG57.Selectable = true
	setp(NG57, "Size", UDim2.new(0, 20, 0, 20))
	NG57.Style = Enum.ButtonStyle.Custom
	setp(NG57, "Font", Enum.Font.Arial)
	setp(NG57, "FontSize", Enum.FontSize.Size10)
	setp(NG57, "Text", "")
	setp(NG57, "TextColor3", Color3.new(1, 1, 1))
	setp(NG57, "TextStrokeTransparency", 0.75)
	setp(NG57, "Parent", NG41)
	NG58 = Instance.new("TextButton")
	setp(NG58, "Active", true)
	setp(NG58, "BackgroundColor3", Color3.new(0.498039, 0.556863, 0.392157))
	setp(NG58, "BorderSizePixel", 0)
	setp(NG58, "Name", "Grime")
	setp(NG58, "Position", UDim2.new(0, 5, 0, 55))
	NG58.Selectable = true
	setp(NG58, "Size", UDim2.new(0, 20, 0, 20))
	NG58.Style = Enum.ButtonStyle.Custom
	setp(NG58, "Font", Enum.Font.Arial)
	setp(NG58, "FontSize", Enum.FontSize.Size10)
	setp(NG58, "Text", "")
	setp(NG58, "TextColor3", Color3.new(1, 1, 1))
	setp(NG58, "TextStrokeTransparency", 0.75)
	setp(NG58, "Parent", NG41)
	NG59 = Instance.new("TextButton")
	setp(NG59, "Active", true)
	setp(NG59, "BackgroundColor3", Color3.new(0.886275, 0.607843, 0.25098))
	setp(NG59, "BorderSizePixel", 0)
	setp(NG59, "Name", "Br. yellowish orange")
	setp(NG59, "Position", UDim2.new(0, 30, 0, 55))
	NG59.Selectable = true
	setp(NG59, "Size", UDim2.new(0, 20, 0, 20))
	NG59.Style = Enum.ButtonStyle.Custom
	setp(NG59, "Font", Enum.Font.Arial)
	setp(NG59, "FontSize", Enum.FontSize.Size10)
	setp(NG59, "Text", "")
	setp(NG59, "TextColor3", Color3.new(1, 1, 1))
	setp(NG59, "TextStrokeTransparency", 0.75)
	setp(NG59, "Parent", NG41)
	NG60 = Instance.new("TextButton")
	setp(NG60, "Active", true)
	setp(NG60, "BackgroundColor3", Color3.new(0.917647, 0.721569, 0.572549))
	setp(NG60, "BorderSizePixel", 0)
	setp(NG60, "Name", "Light orange")
	setp(NG60, "Position", UDim2.new(0, 55, 0, 55))
	NG60.Selectable = true
	setp(NG60, "Size", UDim2.new(0, 20, 0, 20))
	NG60.Style = Enum.ButtonStyle.Custom
	setp(NG60, "Font", Enum.Font.Arial)
	setp(NG60, "FontSize", Enum.FontSize.Size10)
	setp(NG60, "Text", "")
	setp(NG60, "TextColor3", Color3.new(1, 1, 1))
	setp(NG60, "TextStrokeTransparency", 0.75)
	setp(NG60, "Parent", NG41)
	NG61 = Instance.new("TextButton")
	setp(NG61, "Active", true)
	setp(NG61, "BackgroundColor3", Color3.new(0.584314, 0.47451, 0.466667))
	setp(NG61, "BorderSizePixel", 0)
	setp(NG61, "Name", "Sand red")
	setp(NG61, "Position", UDim2.new(0, 80, 0, 55))
	NG61.Selectable = true
	setp(NG61, "Size", UDim2.new(0, 20, 0, 20))
	NG61.Style = Enum.ButtonStyle.Custom
	setp(NG61, "Font", Enum.Font.Arial)
	setp(NG61, "FontSize", Enum.FontSize.Size10)
	setp(NG61, "Text", "")
	setp(NG61, "TextColor3", Color3.new(1, 1, 1))
	setp(NG61, "TextStrokeTransparency", 0.75)
	setp(NG61, "Parent", NG41)
	NG62 = Instance.new("TextButton")
	setp(NG62, "Active", true)
	setp(NG62, "BackgroundColor3", Color3.new(0.54902, 0.356863, 0.623529))
	setp(NG62, "BorderSizePixel", 0)
	setp(NG62, "Name", "Lavender")
	setp(NG62, "Position", UDim2.new(0, 105, 0, 55))
	NG62.Selectable = true
	setp(NG62, "Size", UDim2.new(0, 20, 0, 20))
	NG62.Style = Enum.ButtonStyle.Custom
	setp(NG62, "Font", Enum.Font.Arial)
	setp(NG62, "FontSize", Enum.FontSize.Size10)
	setp(NG62, "Text", "")
	setp(NG62, "TextColor3", Color3.new(1, 1, 1))
	setp(NG62, "TextStrokeTransparency", 0.75)
	setp(NG62, "Parent", NG41)
	NG63 = Instance.new("TextButton")
	setp(NG63, "Active", true)
	setp(NG63, "BackgroundColor3", Color3.new(0.454902, 0.52549, 0.615686))
	setp(NG63, "BorderSizePixel", 0)
	setp(NG63, "Name", "Sand blue")
	setp(NG63, "Position", UDim2.new(0, 130, 0, 55))
	NG63.Selectable = true
	setp(NG63, "Size", UDim2.new(0, 20, 0, 20))
	NG63.Style = Enum.ButtonStyle.Custom
	setp(NG63, "Font", Enum.Font.Arial)
	setp(NG63, "FontSize", Enum.FontSize.Size10)
	setp(NG63, "Text", "")
	setp(NG63, "TextColor3", Color3.new(1, 1, 1))
	setp(NG63, "TextStrokeTransparency", 0.75)
	setp(NG63, "Parent", NG41)
	NG64 = Instance.new("TextButton")
	setp(NG64, "Active", true)
	setp(NG64, "BackgroundColor3", Color3.new(0.431373, 0.6, 0.792157))
	setp(NG64, "BorderSizePixel", 0)
	setp(NG64, "Name", "Medium blue")
	setp(NG64, "Position", UDim2.new(0, 155, 0, 55))
	NG64.Selectable = true
	setp(NG64, "Size", UDim2.new(0, 20, 0, 20))
	NG64.Style = Enum.ButtonStyle.Custom
	setp(NG64, "Font", Enum.Font.Arial)
	setp(NG64, "FontSize", Enum.FontSize.Size10)
	setp(NG64, "Text", "")
	setp(NG64, "TextColor3", Color3.new(1, 1, 1))
	setp(NG64, "TextStrokeTransparency", 0.75)
	setp(NG64, "Parent", NG41)
	NG65 = Instance.new("TextButton")
	setp(NG65, "Active", true)
	setp(NG65, "BackgroundColor3", Color3.new(0.470588, 0.564706, 0.509804))
	setp(NG65, "BorderSizePixel", 0)
	setp(NG65, "Name", "Sand green")
	setp(NG65, "Position", UDim2.new(0, 180, 0, 55))
	NG65.Selectable = true
	setp(NG65, "Size", UDim2.new(0, 20, 0, 20))
	NG65.Style = Enum.ButtonStyle.Custom
	setp(NG65, "Font", Enum.Font.Arial)
	setp(NG65, "FontSize", Enum.FontSize.Size10)
	setp(NG65, "Text", "")
	setp(NG65, "TextColor3", Color3.new(1, 1, 1))
	setp(NG65, "TextStrokeTransparency", 0.75)
	setp(NG65, "Parent", NG41)
	NG66 = Instance.new("TextButton")
	setp(NG66, "Active", true)
	setp(NG66, "BackgroundColor3", Color3.new(0.843137, 0.772549, 0.603922))
	setp(NG66, "BorderSizePixel", 0)
	setp(NG66, "Name", "Brick yellow")
	setp(NG66, "Position", UDim2.new(0, 5, 0, 80))
	NG66.Selectable = true
	setp(NG66, "Size", UDim2.new(0, 20, 0, 20))
	NG66.Style = Enum.ButtonStyle.Custom
	setp(NG66, "Font", Enum.Font.Arial)
	setp(NG66, "FontSize", Enum.FontSize.Size10)
	setp(NG66, "Text", "")
	setp(NG66, "TextColor3", Color3.new(1, 1, 1))
	setp(NG66, "TextStrokeTransparency", 0.75)
	setp(NG66, "Parent", NG41)
	NG67 = Instance.new("TextButton")
	setp(NG67, "Active", true)
	setp(NG67, "BackgroundColor3", Color3.new(0.992157, 0.917647, 0.552941))
	setp(NG67, "BorderSizePixel", 0)
	setp(NG67, "Name", "Cool yellow")
	setp(NG67, "Position", UDim2.new(0, 30, 0, 80))
	NG67.Selectable = true
	setp(NG67, "Size", UDim2.new(0, 20, 0, 20))
	NG67.Style = Enum.ButtonStyle.Custom
	setp(NG67, "Font", Enum.Font.Arial)
	setp(NG67, "FontSize", Enum.FontSize.Size10)
	setp(NG67, "Text", "")
	setp(NG67, "TextColor3", Color3.new(1, 1, 1))
	setp(NG67, "TextStrokeTransparency", 0.75)
	setp(NG67, "Parent", NG41)
	NG68 = Instance.new("TextButton")
	setp(NG68, "Active", true)
	setp(NG68, "BackgroundColor3", Color3.new(0.835294, 0.45098, 0.239216))
	setp(NG68, "BorderSizePixel", 0)
	setp(NG68, "Name", "Neon orange")
	setp(NG68, "Position", UDim2.new(0, 55, 0, 80))
	NG68.Selectable = true
	setp(NG68, "Size", UDim2.new(0, 20, 0, 20))
	NG68.Style = Enum.ButtonStyle.Custom
	setp(NG68, "Font", Enum.Font.Arial)
	setp(NG68, "FontSize", Enum.FontSize.Size10)
	setp(NG68, "Text", "")
	setp(NG68, "TextColor3", Color3.new(1, 1, 1))
	setp(NG68, "TextStrokeTransparency", 0.75)
	setp(NG68, "Parent", NG41)
	NG69 = Instance.new("TextButton")
	setp(NG69, "Active", true)
	setp(NG69, "BackgroundColor3", Color3.new(0.854902, 0.52549, 0.478431))
	setp(NG69, "BorderSizePixel", 0)
	setp(NG69, "Name", "Medium red")
	setp(NG69, "Position", UDim2.new(0, 80, 0, 80))
	NG69.Selectable = true
	setp(NG69, "Size", UDim2.new(0, 20, 0, 20))
	NG69.Style = Enum.ButtonStyle.Custom
	setp(NG69, "Font", Enum.Font.Arial)
	setp(NG69, "FontSize", Enum.FontSize.Size10)
	setp(NG69, "Text", "")
	setp(NG69, "TextColor3", Color3.new(1, 1, 1))
	setp(NG69, "TextStrokeTransparency", 0.75)
	setp(NG69, "Parent", NG41)
	NG70 = Instance.new("TextButton")
	setp(NG70, "Active", true)
	setp(NG70, "BackgroundColor3", Color3.new(0.909804, 0.729412, 0.784314))
	setp(NG70, "BorderSizePixel", 0)
	setp(NG70, "Name", "Light reddish violet")
	setp(NG70, "Position", UDim2.new(0, 105, 0, 80))
	NG70.Selectable = true
	setp(NG70, "Size", UDim2.new(0, 20, 0, 20))
	NG70.Style = Enum.ButtonStyle.Custom
	setp(NG70, "Font", Enum.Font.Arial)
	setp(NG70, "FontSize", Enum.FontSize.Size10)
	setp(NG70, "Text", "")
	setp(NG70, "TextColor3", Color3.new(1, 1, 1))
	setp(NG70, "TextStrokeTransparency", 0.75)
	setp(NG70, "Parent", NG41)
	NG71 = Instance.new("TextButton")
	setp(NG71, "Active", true)
	setp(NG71, "BackgroundColor3", Color3.new(0.501961, 0.733333, 0.858824))
	setp(NG71, "BorderSizePixel", 0)
	setp(NG71, "Name", "Pastel Blue")
	setp(NG71, "Position", UDim2.new(0, 130, 0, 80))
	NG71.Selectable = true
	setp(NG71, "Size", UDim2.new(0, 20, 0, 20))
	NG71.Style = Enum.ButtonStyle.Custom
	setp(NG71, "Font", Enum.Font.Arial)
	setp(NG71, "FontSize", Enum.FontSize.Size10)
	setp(NG71, "Text", "")
	setp(NG71, "TextColor3", Color3.new(1, 1, 1))
	setp(NG71, "TextStrokeTransparency", 0.75)
	setp(NG71, "Parent", NG41)
	NG72 = Instance.new("TextButton")
	setp(NG72, "Active", true)
	setp(NG72, "BackgroundColor3", Color3.new(0.0705882, 0.933333, 0.831373))
	setp(NG72, "BorderSizePixel", 0)
	setp(NG72, "Name", "Teal")
	setp(NG72, "Position", UDim2.new(0, 155, 0, 80))
	NG72.Selectable = true
	setp(NG72, "Size", UDim2.new(0, 20, 0, 20))
	NG72.Style = Enum.ButtonStyle.Custom
	setp(NG72, "Font", Enum.Font.Arial)
	setp(NG72, "FontSize", Enum.FontSize.Size10)
	setp(NG72, "Text", "")
	setp(NG72, "TextColor3", Color3.new(1, 1, 1))
	setp(NG72, "TextStrokeTransparency", 0.75)
	setp(NG72, "Parent", NG41)
	NG73 = Instance.new("TextButton")
	setp(NG73, "Active", true)
	setp(NG73, "BackgroundColor3", Color3.new(0.631373, 0.768628, 0.54902))
	setp(NG73, "BorderSizePixel", 0)
	setp(NG73, "Name", "Medium green")
	setp(NG73, "Position", UDim2.new(0, 180, 0, 80))
	NG73.Selectable = true
	setp(NG73, "Size", UDim2.new(0, 20, 0, 20))
	NG73.Style = Enum.ButtonStyle.Custom
	setp(NG73, "Font", Enum.Font.Arial)
	setp(NG73, "FontSize", Enum.FontSize.Size10)
	setp(NG73, "Text", "")
	setp(NG73, "TextColor3", Color3.new(1, 1, 1))
	setp(NG73, "TextStrokeTransparency", 0.75)
	setp(NG73, "Parent", NG41)
	NG74 = Instance.new("TextButton")
	setp(NG74, "Active", true)
	setp(NG74, "BackgroundColor3", Color3.new(1, 0.8, 0.6))
	setp(NG74, "BorderSizePixel", 0)
	setp(NG74, "Name", "Pastel brown")
	setp(NG74, "Position", UDim2.new(0, 5, 0, 105))
	NG74.Selectable = true
	setp(NG74, "Size", UDim2.new(0, 20, 0, 20))
	NG74.Style = Enum.ButtonStyle.Custom
	setp(NG74, "Font", Enum.Font.Arial)
	setp(NG74, "FontSize", Enum.FontSize.Size10)
	setp(NG74, "Text", "")
	setp(NG74, "TextColor3", Color3.new(1, 1, 1))
	setp(NG74, "TextStrokeTransparency", 0.75)
	setp(NG74, "Parent", NG41)
	NG75 = Instance.new("TextButton")
	setp(NG75, "Active", true)
	setp(NG75, "BackgroundColor3", Color3.new(1, 1, 0.8))
	setp(NG75, "BorderSizePixel", 0)
	setp(NG75, "Name", "Pastel yellow")
	setp(NG75, "Position", UDim2.new(0, 30, 0, 105))
	NG75.Selectable = true
	setp(NG75, "Size", UDim2.new(0, 20, 0, 20))
	NG75.Style = Enum.ButtonStyle.Custom
	setp(NG75, "Font", Enum.Font.Arial)
	setp(NG75, "FontSize", Enum.FontSize.Size10)
	setp(NG75, "Text", "")
	setp(NG75, "TextColor3", Color3.new(1, 1, 1))
	setp(NG75, "TextStrokeTransparency", 0.75)
	setp(NG75, "Parent", NG41)
	NG76 = Instance.new("TextButton")
	setp(NG76, "Active", true)
	setp(NG76, "BackgroundColor3", Color3.new(1, 0.788235, 0.788235))
	setp(NG76, "BorderSizePixel", 0)
	setp(NG76, "Name", "Pastel orange")
	setp(NG76, "Position", UDim2.new(0, 55, 0, 105))
	NG76.Selectable = true
	setp(NG76, "Size", UDim2.new(0, 20, 0, 20))
	NG76.Style = Enum.ButtonStyle.Custom
	setp(NG76, "Font", Enum.Font.Arial)
	setp(NG76, "FontSize", Enum.FontSize.Size10)
	setp(NG76, "Text", "")
	setp(NG76, "TextColor3", Color3.new(1, 1, 1))
	setp(NG76, "TextStrokeTransparency", 0.75)
	setp(NG76, "Parent", NG41)
	NG77 = Instance.new("TextButton")
	setp(NG77, "Active", true)
	setp(NG77, "BackgroundColor3", Color3.new(1, 0.4, 0.8))
	setp(NG77, "BorderSizePixel", 0)
	setp(NG77, "Name", "Pink")
	setp(NG77, "Position", UDim2.new(0, 80, 0, 105))
	NG77.Selectable = true
	setp(NG77, "Size", UDim2.new(0, 20, 0, 20))
	NG77.Style = Enum.ButtonStyle.Custom
	setp(NG77, "Font", Enum.Font.Arial)
	setp(NG77, "FontSize", Enum.FontSize.Size10)
	setp(NG77, "Text", "")
	setp(NG77, "TextColor3", Color3.new(1, 1, 1))
	setp(NG77, "TextStrokeTransparency", 0.75)
	setp(NG77, "Parent", NG41)
	NG78 = Instance.new("TextButton")
	setp(NG78, "Active", true)
	setp(NG78, "BackgroundColor3", Color3.new(0.694118, 0.654902, 1))
	setp(NG78, "BorderSizePixel", 0)
	setp(NG78, "Name", "Pastel violet")
	setp(NG78, "Position", UDim2.new(0, 105, 0, 105))
	NG78.Selectable = true
	setp(NG78, "Size", UDim2.new(0, 20, 0, 20))
	NG78.Style = Enum.ButtonStyle.Custom
	setp(NG78, "Font", Enum.Font.Arial)
	setp(NG78, "FontSize", Enum.FontSize.Size10)
	setp(NG78, "Text", "")
	setp(NG78, "TextColor3", Color3.new(1, 1, 1))
	setp(NG78, "TextStrokeTransparency", 0.75)
	setp(NG78, "Parent", NG41)
	NG79 = Instance.new("TextButton")
	setp(NG79, "Active", true)
	setp(NG79, "BackgroundColor3", Color3.new(0.686275, 0.866667, 1))
	setp(NG79, "BorderSizePixel", 0)
	setp(NG79, "Name", "Pastel light blue")
	setp(NG79, "Position", UDim2.new(0, 130, 0, 105))
	NG79.Selectable = true
	setp(NG79, "Size", UDim2.new(0, 20, 0, 20))
	NG79.Style = Enum.ButtonStyle.Custom
	setp(NG79, "Font", Enum.Font.Arial)
	setp(NG79, "FontSize", Enum.FontSize.Size10)
	setp(NG79, "Text", "")
	setp(NG79, "TextColor3", Color3.new(1, 1, 1))
	setp(NG79, "TextStrokeTransparency", 0.75)
	setp(NG79, "Parent", NG41)
	NG80 = Instance.new("TextButton")
	setp(NG80, "Active", true)
	setp(NG80, "BackgroundColor3", Color3.new(0.623529, 0.952941, 0.913726))
	setp(NG80, "BorderSizePixel", 0)
	setp(NG80, "Name", "Pastel blue-green")
	setp(NG80, "Position", UDim2.new(0, 155, 0, 105))
	NG80.Selectable = true
	setp(NG80, "Size", UDim2.new(0, 20, 0, 20))
	NG80.Style = Enum.ButtonStyle.Custom
	setp(NG80, "Font", Enum.Font.Arial)
	setp(NG80, "FontSize", Enum.FontSize.Size10)
	setp(NG80, "Text", "")
	setp(NG80, "TextColor3", Color3.new(1, 1, 1))
	setp(NG80, "TextStrokeTransparency", 0.75)
	setp(NG80, "Parent", NG41)
	NG81 = Instance.new("TextButton")
	setp(NG81, "Active", true)
	setp(NG81, "BackgroundColor3", Color3.new(0.8, 1, 0.8))
	setp(NG81, "BorderSizePixel", 0)
	setp(NG81, "Name", "Pastel green")
	setp(NG81, "Position", UDim2.new(0, 180, 0, 105))
	NG81.Selectable = true
	setp(NG81, "Size", UDim2.new(0, 20, 0, 20))
	NG81.Style = Enum.ButtonStyle.Custom
	setp(NG81, "Font", Enum.Font.Arial)
	setp(NG81, "FontSize", Enum.FontSize.Size10)
	setp(NG81, "Text", "")
	setp(NG81, "TextColor3", Color3.new(1, 1, 1))
	setp(NG81, "TextStrokeTransparency", 0.75)
	setp(NG81, "Parent", NG41)
	NG82 = Instance.new("TextButton")
	setp(NG82, "Active", true)
	setp(NG82, "BackgroundColor3", Color3.new(0.756863, 0.745098, 0.258824))
	setp(NG82, "BorderSizePixel", 0)
	setp(NG82, "Name", "Olive")
	setp(NG82, "Position", UDim2.new(0, 5, 0, 130))
	NG82.Selectable = true
	setp(NG82, "Size", UDim2.new(0, 20, 0, 20))
	NG82.Style = Enum.ButtonStyle.Custom
	setp(NG82, "Font", Enum.Font.Arial)
	setp(NG82, "FontSize", Enum.FontSize.Size10)
	setp(NG82, "Text", "")
	setp(NG82, "TextColor3", Color3.new(1, 1, 1))
	setp(NG82, "TextStrokeTransparency", 0.75)
	setp(NG82, "Parent", NG41)
	NG83 = Instance.new("TextButton")
	setp(NG83, "Active", true)
	setp(NG83, "BackgroundColor3", Color3.new(1, 1, 0))
	setp(NG83, "BorderSizePixel", 0)
	setp(NG83, "Name", "New Yeller")
	setp(NG83, "Position", UDim2.new(0, 30, 0, 130))
	NG83.Selectable = true
	setp(NG83, "Size", UDim2.new(0, 20, 0, 20))
	NG83.Style = Enum.ButtonStyle.Custom
	setp(NG83, "Font", Enum.Font.Arial)
	setp(NG83, "FontSize", Enum.FontSize.Size10)
	setp(NG83, "Text", "")
	setp(NG83, "TextColor3", Color3.new(1, 1, 1))
	setp(NG83, "TextStrokeTransparency", 0.75)
	setp(NG83, "Parent", NG41)
	NG84 = Instance.new("TextButton")
	setp(NG84, "Active", true)
	setp(NG84, "BackgroundColor3", Color3.new(1, 0.686275, 0))
	setp(NG84, "BorderSizePixel", 0)
	setp(NG84, "Name", "Deep orange")
	setp(NG84, "Position", UDim2.new(0, 55, 0, 130))
	NG84.Selectable = true
	setp(NG84, "Size", UDim2.new(0, 20, 0, 20))
	NG84.Style = Enum.ButtonStyle.Custom
	setp(NG84, "Font", Enum.Font.Arial)
	setp(NG84, "FontSize", Enum.FontSize.Size10)
	setp(NG84, "Text", "")
	setp(NG84, "TextColor3", Color3.new(1, 1, 1))
	setp(NG84, "TextStrokeTransparency", 0.75)
	setp(NG84, "Parent", NG41)
	NG85 = Instance.new("TextButton")
	setp(NG85, "Active", true)
	setp(NG85, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG85, "BorderSizePixel", 0)
	setp(NG85, "Name", "Really red")
	setp(NG85, "Position", UDim2.new(0, 80, 0, 130))
	NG85.Selectable = true
	setp(NG85, "Size", UDim2.new(0, 20, 0, 20))
	NG85.Style = Enum.ButtonStyle.Custom
	setp(NG85, "Font", Enum.Font.Arial)
	setp(NG85, "FontSize", Enum.FontSize.Size10)
	setp(NG85, "Text", "")
	setp(NG85, "TextColor3", Color3.new(1, 1, 1))
	setp(NG85, "TextStrokeTransparency", 0.75)
	setp(NG85, "Parent", NG41)
	NG86 = Instance.new("TextButton")
	setp(NG86, "Active", true)
	setp(NG86, "BackgroundColor3", Color3.new(1, 0, 0.74902))
	setp(NG86, "BorderSizePixel", 0)
	setp(NG86, "Name", "Hot pink")
	setp(NG86, "Position", UDim2.new(0, 105, 0, 130))
	NG86.Selectable = true
	setp(NG86, "Size", UDim2.new(0, 20, 0, 20))
	NG86.Style = Enum.ButtonStyle.Custom
	setp(NG86, "Font", Enum.Font.Arial)
	setp(NG86, "FontSize", Enum.FontSize.Size10)
	setp(NG86, "Text", "")
	setp(NG86, "TextColor3", Color3.new(1, 1, 1))
	setp(NG86, "TextStrokeTransparency", 0.75)
	setp(NG86, "Parent", NG41)
	NG87 = Instance.new("TextButton")
	setp(NG87, "Active", true)
	setp(NG87, "BackgroundColor3", Color3.new(0, 0, 1))
	setp(NG87, "BorderSizePixel", 0)
	setp(NG87, "Name", "Really blue")
	setp(NG87, "Position", UDim2.new(0, 130, 0, 130))
	NG87.Selectable = true
	setp(NG87, "Size", UDim2.new(0, 20, 0, 20))
	NG87.Style = Enum.ButtonStyle.Custom
	setp(NG87, "Font", Enum.Font.Arial)
	setp(NG87, "FontSize", Enum.FontSize.Size10)
	setp(NG87, "Text", "")
	setp(NG87, "TextColor3", Color3.new(1, 1, 1))
	setp(NG87, "TextStrokeTransparency", 0.75)
	setp(NG87, "Parent", NG41)
	NG88 = Instance.new("TextButton")
	setp(NG88, "Active", true)
	setp(NG88, "BackgroundColor3", Color3.new(0, 1, 1))
	setp(NG88, "BorderSizePixel", 0)
	setp(NG88, "Name", "Toothpaste")
	setp(NG88, "Position", UDim2.new(0, 155, 0, 130))
	NG88.Selectable = true
	setp(NG88, "Size", UDim2.new(0, 20, 0, 20))
	NG88.Style = Enum.ButtonStyle.Custom
	setp(NG88, "Font", Enum.Font.Arial)
	setp(NG88, "FontSize", Enum.FontSize.Size10)
	setp(NG88, "Text", "")
	setp(NG88, "TextColor3", Color3.new(1, 1, 1))
	setp(NG88, "TextStrokeTransparency", 0.75)
	setp(NG88, "Parent", NG41)
	NG89 = Instance.new("TextButton")
	setp(NG89, "Active", true)
	setp(NG89, "BackgroundColor3", Color3.new(0, 1, 0))
	setp(NG89, "BorderSizePixel", 0)
	setp(NG89, "Name", "Lime green")
	setp(NG89, "Position", UDim2.new(0, 180, 0, 130))
	NG89.Selectable = true
	setp(NG89, "Size", UDim2.new(0, 20, 0, 20))
	NG89.Style = Enum.ButtonStyle.Custom
	setp(NG89, "Font", Enum.Font.Arial)
	setp(NG89, "FontSize", Enum.FontSize.Size10)
	setp(NG89, "Text", "")
	setp(NG89, "TextColor3", Color3.new(1, 1, 1))
	setp(NG89, "TextStrokeTransparency", 0.75)
	setp(NG89, "Parent", NG41)
	NG90 = Instance.new("TextButton")
	setp(NG90, "Active", true)
	setp(NG90, "BackgroundColor3", Color3.new(0.486275, 0.360784, 0.27451))
	setp(NG90, "BorderSizePixel", 0)
	setp(NG90, "Name", "Brown")
	setp(NG90, "Position", UDim2.new(0, 5, 0, 155))
	NG90.Selectable = true
	setp(NG90, "Size", UDim2.new(0, 20, 0, 20))
	NG90.Style = Enum.ButtonStyle.Custom
	setp(NG90, "Font", Enum.Font.Arial)
	setp(NG90, "FontSize", Enum.FontSize.Size10)
	setp(NG90, "Text", "")
	setp(NG90, "TextColor3", Color3.new(1, 1, 1))
	setp(NG90, "TextStrokeTransparency", 0.75)
	setp(NG90, "Parent", NG41)
	NG91 = Instance.new("TextButton")
	setp(NG91, "Active", true)
	setp(NG91, "BackgroundColor3", Color3.new(0.8, 0.556863, 0.411765))
	setp(NG91, "BorderSizePixel", 0)
	setp(NG91, "Name", "Nougat")
	setp(NG91, "Position", UDim2.new(0, 30, 0, 155))
	NG91.Selectable = true
	setp(NG91, "Size", UDim2.new(0, 20, 0, 20))
	NG91.Style = Enum.ButtonStyle.Custom
	setp(NG91, "Font", Enum.Font.Arial)
	setp(NG91, "FontSize", Enum.FontSize.Size10)
	setp(NG91, "Text", "")
	setp(NG91, "TextColor3", Color3.new(1, 1, 1))
	setp(NG91, "TextStrokeTransparency", 0.75)
	setp(NG91, "Parent", NG41)
	NG92 = Instance.new("TextButton")
	setp(NG92, "Active", true)
	setp(NG92, "BackgroundColor3", Color3.new(0.627451, 0.372549, 0.207843))
	setp(NG92, "BorderSizePixel", 0)
	setp(NG92, "Name", "Dark orange")
	setp(NG92, "Position", UDim2.new(0, 55, 0, 155))
	NG92.Selectable = true
	setp(NG92, "Size", UDim2.new(0, 20, 0, 20))
	NG92.Style = Enum.ButtonStyle.Custom
	setp(NG92, "Font", Enum.Font.Arial)
	setp(NG92, "FontSize", Enum.FontSize.Size10)
	setp(NG92, "Text", "")
	setp(NG92, "TextColor3", Color3.new(1, 1, 1))
	setp(NG92, "TextStrokeTransparency", 0.75)
	setp(NG92, "Parent", NG41)
	NG93 = Instance.new("TextButton")
	setp(NG93, "Active", true)
	setp(NG93, "BackgroundColor3", Color3.new(0.384314, 0.145098, 0.819608))
	setp(NG93, "BorderSizePixel", 0)
	setp(NG93, "Name", "Royal purple")
	setp(NG93, "Position", UDim2.new(0, 80, 0, 155))
	NG93.Selectable = true
	setp(NG93, "Size", UDim2.new(0, 20, 0, 20))
	NG93.Style = Enum.ButtonStyle.Custom
	setp(NG93, "Font", Enum.Font.Arial)
	setp(NG93, "FontSize", Enum.FontSize.Size10)
	setp(NG93, "Text", "")
	setp(NG93, "TextColor3", Color3.new(1, 1, 1))
	setp(NG93, "TextStrokeTransparency", 0.75)
	setp(NG93, "Parent", NG41)
	NG94 = Instance.new("TextButton")
	setp(NG94, "Active", true)
	setp(NG94, "BackgroundColor3", Color3.new(0.705882, 0.501961, 1))
	setp(NG94, "BorderSizePixel", 0)
	setp(NG94, "Name", "Alder")
	setp(NG94, "Position", UDim2.new(0, 105, 0, 155))
	NG94.Selectable = true
	setp(NG94, "Size", UDim2.new(0, 20, 0, 20))
	NG94.Style = Enum.ButtonStyle.Custom
	setp(NG94, "Font", Enum.Font.Arial)
	setp(NG94, "FontSize", Enum.FontSize.Size10)
	setp(NG94, "Text", "")
	setp(NG94, "TextColor3", Color3.new(1, 1, 1))
	setp(NG94, "TextStrokeTransparency", 0.75)
	setp(NG94, "Parent", NG41)
	NG95 = Instance.new("TextButton")
	setp(NG95, "Active", true)
	setp(NG95, "BackgroundColor3", Color3.new(0.0156863, 0.686275, 0.92549))
	setp(NG95, "BorderSizePixel", 0)
	setp(NG95, "Name", "Cyan")
	setp(NG95, "Position", UDim2.new(0, 130, 0, 155))
	NG95.Selectable = true
	setp(NG95, "Size", UDim2.new(0, 20, 0, 20))
	NG95.Style = Enum.ButtonStyle.Custom
	setp(NG95, "Font", Enum.Font.Arial)
	setp(NG95, "FontSize", Enum.FontSize.Size10)
	setp(NG95, "Text", "")
	setp(NG95, "TextColor3", Color3.new(1, 1, 1))
	setp(NG95, "TextStrokeTransparency", 0.75)
	setp(NG95, "Parent", NG41)
	NG96 = Instance.new("TextButton")
	setp(NG96, "Active", true)
	setp(NG96, "BackgroundColor3", Color3.new(0.705882, 0.823529, 0.894118))
	setp(NG96, "BorderSizePixel", 0)
	setp(NG96, "Name", "Light blue")
	setp(NG96, "Position", UDim2.new(0, 155, 0, 155))
	NG96.Selectable = true
	setp(NG96, "Size", UDim2.new(0, 20, 0, 20))
	NG96.Style = Enum.ButtonStyle.Custom
	setp(NG96, "Font", Enum.Font.Arial)
	setp(NG96, "FontSize", Enum.FontSize.Size10)
	setp(NG96, "Text", "")
	setp(NG96, "TextColor3", Color3.new(1, 1, 1))
	setp(NG96, "TextStrokeTransparency", 0.75)
	setp(NG96, "Parent", NG41)
	NG97 = Instance.new("TextButton")
	setp(NG97, "Active", true)
	setp(NG97, "BackgroundColor3", Color3.new(0.227451, 0.490196, 0.0823529))
	setp(NG97, "BorderSizePixel", 0)
	setp(NG97, "Name", "Camo")
	setp(NG97, "Position", UDim2.new(0, 180, 0, 155))
	NG97.Selectable = true
	setp(NG97, "Size", UDim2.new(0, 20, 0, 20))
	NG97.Style = Enum.ButtonStyle.Custom
	setp(NG97, "Font", Enum.Font.Arial)
	setp(NG97, "FontSize", Enum.FontSize.Size10)
	setp(NG97, "Text", "")
	setp(NG97, "TextColor3", Color3.new(1, 1, 1))
	setp(NG97, "TextStrokeTransparency", 0.75)
	setp(NG97, "Parent", NG41)
	NG98 = Instance.new("TextButton")
	setp(NG98, "Active", true)
	setp(NG98, "BackgroundColor3", Color3.new(0.411765, 0.25098, 0.156863))
	setp(NG98, "BorderSizePixel", 0)
	setp(NG98, "Name", "Reddish brown")
	setp(NG98, "Position", UDim2.new(0, 5, 0, 180))
	NG98.Selectable = true
	setp(NG98, "Size", UDim2.new(0, 20, 0, 20))
	NG98.Style = Enum.ButtonStyle.Custom
	setp(NG98, "Font", Enum.Font.Arial)
	setp(NG98, "FontSize", Enum.FontSize.Size10)
	setp(NG98, "Text", "")
	setp(NG98, "TextColor3", Color3.new(1, 1, 1))
	setp(NG98, "TextStrokeTransparency", 0.75)
	setp(NG98, "Parent", NG41)
	NG99 = Instance.new("TextButton")
	setp(NG99, "Active", true)
	setp(NG99, "BackgroundColor3", Color3.new(0.666667, 0.333333, 0))
	setp(NG99, "BorderSizePixel", 0)
	setp(NG99, "Name", "CGA brown")
	setp(NG99, "Position", UDim2.new(0, 30, 0, 180))
	NG99.Selectable = true
	setp(NG99, "Size", UDim2.new(0, 20, 0, 20))
	NG99.Style = Enum.ButtonStyle.Custom
	setp(NG99, "Font", Enum.Font.Arial)
	setp(NG99, "FontSize", Enum.FontSize.Size10)
	setp(NG99, "Text", "")
	setp(NG99, "TextColor3", Color3.new(1, 1, 1))
	setp(NG99, "TextStrokeTransparency", 0.75)
	setp(NG99, "Parent", NG41)
	NG100 = Instance.new("TextButton")
	setp(NG100, "Active", true)
	setp(NG100, "BackgroundColor3", Color3.new(0.639216, 0.294118, 0.294118))
	setp(NG100, "BorderSizePixel", 0)
	setp(NG100, "Name", "Dusty Rose")
	setp(NG100, "Position", UDim2.new(0, 55, 0, 180))
	NG100.Selectable = true
	setp(NG100, "Size", UDim2.new(0, 20, 0, 20))
	NG100.Style = Enum.ButtonStyle.Custom
	setp(NG100, "Font", Enum.Font.Arial)
	setp(NG100, "FontSize", Enum.FontSize.Size10)
	setp(NG100, "Text", "")
	setp(NG100, "TextColor3", Color3.new(1, 1, 1))
	setp(NG100, "TextStrokeTransparency", 0.75)
	setp(NG100, "Parent", NG41)
	NG101 = Instance.new("TextButton")
	setp(NG101, "Active", true)
	setp(NG101, "BackgroundColor3", Color3.new(0.666667, 0, 0.666667))
	setp(NG101, "BorderSizePixel", 0)
	setp(NG101, "Name", "Magenta")
	setp(NG101, "Position", UDim2.new(0, 80, 0, 180))
	NG101.Selectable = true
	setp(NG101, "Size", UDim2.new(0, 20, 0, 20))
	NG101.Style = Enum.ButtonStyle.Custom
	setp(NG101, "Font", Enum.Font.Arial)
	setp(NG101, "FontSize", Enum.FontSize.Size10)
	setp(NG101, "Text", "")
	setp(NG101, "TextColor3", Color3.new(1, 1, 1))
	setp(NG101, "TextStrokeTransparency", 0.75)
	setp(NG101, "Parent", NG41)
	NG102 = Instance.new("TextButton")
	setp(NG102, "Active", true)
	setp(NG102, "BackgroundColor3", Color3.new(0.129412, 0.329412, 0.72549))
	setp(NG102, "BorderSizePixel", 0)
	setp(NG102, "Name", "Deep blue")
	setp(NG102, "Position", UDim2.new(0, 105, 0, 180))
	NG102.Selectable = true
	setp(NG102, "Size", UDim2.new(0, 20, 0, 20))
	NG102.Style = Enum.ButtonStyle.Custom
	setp(NG102, "Font", Enum.Font.Arial)
	setp(NG102, "FontSize", Enum.FontSize.Size10)
	setp(NG102, "Text", "")
	setp(NG102, "TextColor3", Color3.new(1, 1, 1))
	setp(NG102, "TextStrokeTransparency", 0.75)
	setp(NG102, "Parent", NG41)
	NG103 = Instance.new("TextButton")
	setp(NG103, "Active", true)
	setp(NG103, "BackgroundColor3", Color3.new(0, 0.12549, 0.376471))
	setp(NG103, "BorderSizePixel", 0)
	setp(NG103, "Name", "Navy blue")
	setp(NG103, "Position", UDim2.new(0, 130, 0, 180))
	NG103.Selectable = true
	setp(NG103, "Size", UDim2.new(0, 20, 0, 20))
	NG103.Style = Enum.ButtonStyle.Custom
	setp(NG103, "Font", Enum.Font.Arial)
	setp(NG103, "FontSize", Enum.FontSize.Size10)
	setp(NG103, "Text", "")
	setp(NG103, "TextColor3", Color3.new(1, 1, 1))
	setp(NG103, "TextStrokeTransparency", 0.75)
	setp(NG103, "Parent", NG41)
	NG104 = Instance.new("TextButton")
	setp(NG104, "Active", true)
	setp(NG104, "BackgroundColor3", Color3.new(0.156863, 0.498039, 0.278431))
	setp(NG104, "BorderSizePixel", 0)
	setp(NG104, "Name", "Dark green")
	setp(NG104, "Position", UDim2.new(0, 155, 0, 180))
	NG104.Selectable = true
	setp(NG104, "Size", UDim2.new(0, 20, 0, 20))
	NG104.Style = Enum.ButtonStyle.Custom
	setp(NG104, "Font", Enum.Font.Arial)
	setp(NG104, "FontSize", Enum.FontSize.Size10)
	setp(NG104, "Text", "")
	setp(NG104, "TextColor3", Color3.new(1, 1, 1))
	setp(NG104, "TextStrokeTransparency", 0.75)
	setp(NG104, "Parent", NG41)
	NG105 = Instance.new("TextButton")
	setp(NG105, "Active", true)
	setp(NG105, "BackgroundColor3", Color3.new(0.152941, 0.27451, 0.176471))
	setp(NG105, "BorderSizePixel", 0)
	setp(NG105, "Name", "Earth green")
	setp(NG105, "Position", UDim2.new(0, 180, 0, 180))
	NG105.Selectable = true
	setp(NG105, "Size", UDim2.new(0, 20, 0, 20))
	NG105.Style = Enum.ButtonStyle.Custom
	setp(NG105, "Font", Enum.Font.Arial)
	setp(NG105, "FontSize", Enum.FontSize.Size10)
	setp(NG105, "Text", "")
	setp(NG105, "TextColor3", Color3.new(1, 1, 1))
	setp(NG105, "TextStrokeTransparency", 0.75)
	setp(NG105, "Parent", NG41)
	NG106 = Instance.new("Frame")
	setp(NG106, "Active", true)
	setp(NG106, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG106, "BackgroundTransparency", 1)
	setp(NG106, "BorderSizePixel", 0)
	setp(NG106, "Name", "BTMoveToolGUI")
	setp(NG106, "Position", UDim2.new(0, 0, 0, 280))
	setp(NG106, "Size", UDim2.new(0, 245, 0, 90))
	NG106.Draggable = true
	setp(NG106, "Parent", NG1)
	NG107 = Instance.new("Frame")
	setp(NG107, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG107, "BackgroundTransparency", 1)
	setp(NG107, "BorderSizePixel", 0)
	setp(NG107, "Name", "Changes")
	setp(NG107, "Position", UDim2.new(0, 5, 0, 100))
	setp(NG107, "Size", UDim2.new(1, -5, 0, 20))
	setp(NG107, "Parent", NG106)
	NG108 = Instance.new("TextLabel")
	setp(NG108, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG108, "BackgroundTransparency", 1)
	setp(NG108, "BorderSizePixel", 0)
	setp(NG108, "Name", "Text")
	setp(NG108, "Position", UDim2.new(0, 10, 0, 2))
	setp(NG108, "Size", UDim2.new(1, -10, 0, 20))
	setp(NG108, "Font", Enum.Font.ArialBold)
	setp(NG108, "FontSize", Enum.FontSize.Size10)
	setp(NG108, "Text", "moved 0 studs")
	setp(NG108, "TextColor3", Color3.new(1, 1, 1))
	setp(NG108, "TextStrokeTransparency", 0.5)
	setp(NG108, "TextWrapped", true)
	setp(NG108, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG108, "Parent", NG107)
	NG109 = Instance.new("Frame")
	setp(NG109, "BackgroundColor3", Color3.new(1, 0.666667, 0))
	setp(NG109, "BorderSizePixel", 0)
	setp(NG109, "Name", "ColorBar")
	setp(NG109, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG109, "Parent", NG107)
	NG110 = Instance.new("Frame")
	setp(NG110, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG110, "BackgroundTransparency", 1)
	setp(NG110, "BorderSizePixel", 0)
	setp(NG110, "Name", "Info")
	setp(NG110, "Position", UDim2.new(0, 5, 0, 100))
	setp(NG110, "Size", UDim2.new(1, -5, 0, 60))
	setp(NG110, "Visible", false)
	setp(NG110, "Parent", NG106)
	NG111 = Instance.new("Frame")
	setp(NG111, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG111, "BackgroundTransparency", 1)
	setp(NG111, "BorderSizePixel", 0)
	setp(NG111, "Name", "Center")
	setp(NG111, "Position", UDim2.new(0, 0, 0, 30))
	setp(NG111, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG111, "Parent", NG110)
	NG112 = Instance.new("Frame")
	setp(NG112, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG112, "BackgroundTransparency", 1)
	setp(NG112, "BorderSizePixel", 0)
	setp(NG112, "Name", "Z")
	setp(NG112, "Position", UDim2.new(0, 164, 0, 0))
	setp(NG112, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG112, "Parent", NG111)
	NG113 = Instance.new("ImageLabel")
	setp(NG113, "Active", false)
	setp(NG113, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG113, "BackgroundTransparency", 1)
	setp(NG113, "BorderSizePixel", 0)
	setp(NG113, "Name", "Background")
	NG113.Selectable = false
	setp(NG113, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG113, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG113, "Parent", NG112)
	NG114 = Instance.new("TextButton")
	setp(NG114, "Active", true)
	setp(NG114, "AutoButtonColor", false)
	setp(NG114, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG114, "BackgroundTransparency", 1)
	setp(NG114, "BorderSizePixel", 0)
	NG114.Selectable = true
	setp(NG114, "Size", UDim2.new(1, 0, 1, 0))
	NG114.Style = Enum.ButtonStyle.Custom
	setp(NG114, "ZIndex", 3)
	setp(NG114, "Font", Enum.Font.Legacy)
	setp(NG114, "FontSize", Enum.FontSize.Size8)
	setp(NG114, "Text", "")
	setp(NG114, "Parent", NG112)
	NG115 = Instance.new("TextBox")
	setp(NG115, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG115, "BackgroundTransparency", 1)
	setp(NG115, "BorderSizePixel", 0)
	setp(NG115, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG115, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG115, "ZIndex", 2)
	setp(NG115, "Font", Enum.Font.ArialBold)
	setp(NG115, "FontSize", Enum.FontSize.Size10)
	setp(NG115, "Text", "")
	setp(NG115, "TextColor3", Color3.new(1, 1, 1))
	setp(NG115, "Parent", NG112)
	NG116 = Instance.new("Frame")
	setp(NG116, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG116, "BackgroundTransparency", 1)
	setp(NG116, "BorderSizePixel", 0)
	setp(NG116, "Name", "Y")
	setp(NG116, "Position", UDim2.new(0, 117, 0, 0))
	setp(NG116, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG116, "Parent", NG111)
	NG117 = Instance.new("TextButton")
	setp(NG117, "Active", true)
	setp(NG117, "AutoButtonColor", false)
	setp(NG117, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG117, "BackgroundTransparency", 1)
	setp(NG117, "BorderSizePixel", 0)
	NG117.Selectable = true
	setp(NG117, "Size", UDim2.new(1, 0, 1, 0))
	NG117.Style = Enum.ButtonStyle.Custom
	setp(NG117, "ZIndex", 3)
	setp(NG117, "Font", Enum.Font.Legacy)
	setp(NG117, "FontSize", Enum.FontSize.Size8)
	setp(NG117, "Text", "")
	setp(NG117, "Parent", NG116)
	NG118 = Instance.new("TextBox")
	setp(NG118, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG118, "BackgroundTransparency", 1)
	setp(NG118, "BorderSizePixel", 0)
	setp(NG118, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG118, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG118, "ZIndex", 2)
	setp(NG118, "Font", Enum.Font.ArialBold)
	setp(NG118, "FontSize", Enum.FontSize.Size10)
	setp(NG118, "Text", "")
	setp(NG118, "TextColor3", Color3.new(1, 1, 1))
	setp(NG118, "Parent", NG116)
	NG119 = Instance.new("ImageLabel")
	setp(NG119, "Active", false)
	setp(NG119, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG119, "BackgroundTransparency", 1)
	setp(NG119, "BorderSizePixel", 0)
	setp(NG119, "Name", "Background")
	NG119.Selectable = false
	setp(NG119, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG119, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG119, "Parent", NG116)
	NG120 = Instance.new("Frame")
	setp(NG120, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG120, "BackgroundTransparency", 1)
	setp(NG120, "BorderSizePixel", 0)
	setp(NG120, "Name", "X")
	setp(NG120, "Position", UDim2.new(0, 70, 0, 0))
	setp(NG120, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG120, "Parent", NG111)
	NG121 = Instance.new("TextBox")
	setp(NG121, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG121, "BackgroundTransparency", 1)
	setp(NG121, "BorderSizePixel", 0)
	setp(NG121, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG121, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG121, "ZIndex", 2)
	setp(NG121, "Font", Enum.Font.ArialBold)
	setp(NG121, "FontSize", Enum.FontSize.Size10)
	setp(NG121, "Text", "")
	setp(NG121, "TextColor3", Color3.new(1, 1, 1))
	setp(NG121, "Parent", NG120)
	NG122 = Instance.new("TextButton")
	setp(NG122, "Active", true)
	setp(NG122, "AutoButtonColor", false)
	setp(NG122, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG122, "BackgroundTransparency", 1)
	setp(NG122, "BorderSizePixel", 0)
	NG122.Selectable = true
	setp(NG122, "Size", UDim2.new(1, 0, 1, 0))
	NG122.Style = Enum.ButtonStyle.Custom
	setp(NG122, "ZIndex", 3)
	setp(NG122, "Font", Enum.Font.Legacy)
	setp(NG122, "FontSize", Enum.FontSize.Size8)
	setp(NG122, "Text", "")
	setp(NG122, "Parent", NG120)
	NG123 = Instance.new("ImageLabel")
	setp(NG123, "Active", false)
	setp(NG123, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG123, "BackgroundTransparency", 1)
	setp(NG123, "BorderSizePixel", 0)
	setp(NG123, "Name", "Background")
	NG123.Selectable = false
	setp(NG123, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG123, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG123, "Parent", NG120)
	NG124 = Instance.new("TextLabel")
	setp(NG124, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG124, "BackgroundTransparency", 1)
	setp(NG124, "BorderSizePixel", 0)
	setp(NG124, "Size", UDim2.new(0, 75, 0, 25))
	setp(NG124, "Font", Enum.Font.ArialBold)
	setp(NG124, "FontSize", Enum.FontSize.Size10)
	setp(NG124, "Text", "Position")
	setp(NG124, "TextColor3", Color3.new(1, 1, 1))
	setp(NG124, "TextStrokeTransparency", 0)
	setp(NG124, "TextWrapped", true)
	setp(NG124, "Parent", NG111)
	NG125 = Instance.new("TextLabel")
	setp(NG125, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG125, "BackgroundTransparency", 1)
	setp(NG125, "BorderSizePixel", 0)
	setp(NG125, "Name", "Label")
	setp(NG125, "Position", UDim2.new(0, 10, 0, 2))
	setp(NG125, "Size", UDim2.new(1, -10, 0, 20))
	setp(NG125, "Font", Enum.Font.ArialBold)
	setp(NG125, "FontSize", Enum.FontSize.Size10)
	setp(NG125, "Text", "SELECTION INFO")
	setp(NG125, "TextColor3", Color3.new(1, 1, 1))
	setp(NG125, "TextStrokeTransparency", 0)
	setp(NG125, "TextWrapped", true)
	setp(NG125, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG125, "Parent", NG110)
	NG126 = Instance.new("Frame")
	setp(NG126, "BackgroundColor3", Color3.new(1, 0.666667, 0))
	setp(NG126, "BorderSizePixel", 0)
	setp(NG126, "Name", "ColorBar")
	setp(NG126, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG126, "Parent", NG110)
	NG127 = Instance.new("Frame")
	setp(NG127, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG127, "BackgroundTransparency", 1)
	setp(NG127, "BorderSizePixel", 0)
	setp(NG127, "Name", "IncrementOption")
	setp(NG127, "Position", UDim2.new(0, 0, 0, 65))
	setp(NG127, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG127, "Parent", NG106)
	NG128 = Instance.new("Frame")
	setp(NG128, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG128, "BackgroundTransparency", 1)
	setp(NG128, "BorderSizePixel", 0)
	setp(NG128, "Name", "Label")
	setp(NG128, "Size", UDim2.new(0, 75, 0, 25))
	setp(NG128, "Parent", NG127)
	NG129 = Instance.new("TextLabel")
	setp(NG129, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG129, "BackgroundTransparency", 1)
	setp(NG129, "BorderSizePixel", 0)
	setp(NG129, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG129, "Font", Enum.Font.ArialBold)
	setp(NG129, "FontSize", Enum.FontSize.Size10)
	setp(NG129, "Text", "Increment")
	setp(NG129, "TextColor3", Color3.new(1, 1, 1))
	setp(NG129, "TextStrokeTransparency", 0)
	setp(NG129, "TextWrapped", true)
	setp(NG129, "Parent", NG128)
	NG130 = Instance.new("Frame")
	setp(NG130, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG130, "BackgroundTransparency", 1)
	setp(NG130, "BorderSizePixel", 0)
	setp(NG130, "Name", "Increment")
	setp(NG130, "Position", UDim2.new(0, 70, 0, 0))
	setp(NG130, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG130, "Parent", NG127)
	NG131 = Instance.new("ImageLabel")
	setp(NG131, "Active", false)
	setp(NG131, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG131, "BackgroundTransparency", 1)
	setp(NG131, "BorderSizePixel", 0)
	setp(NG131, "Name", "Background")
	NG131.Selectable = false
	setp(NG131, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG131, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG131, "Parent", NG130)
	NG132 = Instance.new("TextBox")
	setp(NG132, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG132, "BackgroundTransparency", 1)
	setp(NG132, "BorderSizePixel", 0)
	setp(NG132, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG132, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG132, "ZIndex", 2)
	setp(NG132, "Font", Enum.Font.ArialBold)
	setp(NG132, "FontSize", Enum.FontSize.Size10)
	setp(NG132, "Text", "1")
	setp(NG132, "TextColor3", Color3.new(1, 1, 1))
	setp(NG132, "Parent", NG130)
	NG133 = Instance.new("Frame")
	setp(NG133, "BorderSizePixel", 0)
	setp(NG133, "Name", "SelectedIndicator")
	setp(NG133, "Position", UDim2.new(0, 5, 0, -2))
	setp(NG133, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG133, "Parent", NG130)
	NG134 = Instance.new("Frame")
	setp(NG134, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG134, "BackgroundTransparency", 1)
	setp(NG134, "BorderSizePixel", 0)
	setp(NG134, "Name", "Title")
	setp(NG134, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG134, "Parent", NG106)
	NG135 = Instance.new("TextLabel")
	setp(NG135, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG135, "BackgroundTransparency", 1)
	setp(NG135, "BorderSizePixel", 0)
	setp(NG135, "Name", "F3XSignature")
	setp(NG135, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG135, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG135, "Font", Enum.Font.ArialBold)
	setp(NG135, "FontSize", Enum.FontSize.Size14)
	setp(NG135, "Text", "F3X")
	setp(NG135, "TextColor3", Color3.new(1, 1, 1))
	setp(NG135, "TextStrokeTransparency", 0.89999997615814)
	setp(NG135, "TextWrapped", true)
	setp(NG135, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG135, "Parent", NG134)
	NG136 = Instance.new("TextLabel")
	setp(NG136, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG136, "BackgroundTransparency", 1)
	setp(NG136, "BorderSizePixel", 0)
	setp(NG136, "Name", "Label")
	setp(NG136, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG136, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG136, "Font", Enum.Font.ArialBold)
	setp(NG136, "FontSize", Enum.FontSize.Size10)
	setp(NG136, "Text", "MOVE TOOL")
	setp(NG136, "TextColor3", Color3.new(1, 1, 1))
	setp(NG136, "TextStrokeTransparency", 0)
	setp(NG136, "TextWrapped", true)
	setp(NG136, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG136, "Parent", NG134)
	NG137 = Instance.new("Frame")
	setp(NG137, "BackgroundColor3", Color3.new(1, 0.666667, 0))
	setp(NG137, "BorderSizePixel", 0)
	setp(NG137, "Name", "ColorBar")
	setp(NG137, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG137, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG137, "Parent", NG134)
	NG138 = Instance.new("Frame")
	setp(NG138, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG138, "BackgroundTransparency", 1)
	setp(NG138, "BorderSizePixel", 0)
	setp(NG138, "Name", "AxesOption")
	setp(NG138, "Position", UDim2.new(0, 0, 0, 30))
	setp(NG138, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG138, "Parent", NG106)
	NG139 = Instance.new("Frame")
	setp(NG139, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG139, "BackgroundTransparency", 1)
	setp(NG139, "BorderSizePixel", 0)
	setp(NG139, "Name", "Label")
	setp(NG139, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG139, "Parent", NG138)
	NG140 = Instance.new("TextLabel")
	setp(NG140, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG140, "BackgroundTransparency", 1)
	setp(NG140, "BorderSizePixel", 0)
	setp(NG140, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG140, "Font", Enum.Font.ArialBold)
	setp(NG140, "FontSize", Enum.FontSize.Size10)
	setp(NG140, "Text", "Axes")
	setp(NG140, "TextColor3", Color3.new(1, 1, 1))
	setp(NG140, "TextStrokeTransparency", 0)
	setp(NG140, "TextWrapped", true)
	setp(NG140, "Parent", NG139)
	NG141 = Instance.new("Frame")
	setp(NG141, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG141, "BackgroundTransparency", 1)
	setp(NG141, "BorderSizePixel", 0)
	setp(NG141, "Name", "Last")
	setp(NG141, "Position", UDim2.new(0, 175, 0, 0))
	setp(NG141, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG141, "Parent", NG138)
	NG142 = Instance.new("TextLabel")
	setp(NG142, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG142, "BackgroundTransparency", 1)
	setp(NG142, "BorderSizePixel", 0)
	setp(NG142, "Name", "Label")
	setp(NG142, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG142, "ZIndex", 2)
	setp(NG142, "Font", Enum.Font.ArialBold)
	setp(NG142, "FontSize", Enum.FontSize.Size10)
	setp(NG142, "Text", "LAST")
	setp(NG142, "TextColor3", Color3.new(1, 1, 1))
	setp(NG142, "Parent", NG141)
	NG143 = Instance.new("ImageLabel")
	setp(NG143, "Active", false)
	setp(NG143, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG143, "BackgroundTransparency", 1)
	setp(NG143, "BorderSizePixel", 0)
	setp(NG143, "Name", "Background")
	NG143.Selectable = false
	setp(NG143, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG143, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG143, "Parent", NG141)
	NG144 = Instance.new("TextButton")
	setp(NG144, "Active", true)
	setp(NG144, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG144, "BackgroundTransparency", 1)
	setp(NG144, "BorderSizePixel", 0)
	setp(NG144, "Name", "Button")
	setp(NG144, "Position", UDim2.new(0, 5, 0, 0))
	NG144.Selectable = true
	setp(NG144, "Size", UDim2.new(1, -10, 1, 0))
	NG144.Style = Enum.ButtonStyle.Custom
	setp(NG144, "ZIndex", 2)
	setp(NG144, "Font", Enum.Font.Legacy)
	setp(NG144, "FontSize", Enum.FontSize.Size8)
	setp(NG144, "Text", "")
	NG144.TextTransparency = 1
	setp(NG144, "Parent", NG141)
	NG145 = Instance.new("Frame")
	setp(NG145, "BackgroundTransparency", 1)
	setp(NG145, "BorderSizePixel", 0)
	setp(NG145, "Name", "SelectedIndicator")
	setp(NG145, "Position", UDim2.new(0, 6, 0, -2))
	setp(NG145, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG145, "Parent", NG141)
	NG146 = Instance.new("Frame")
	setp(NG146, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG146, "BackgroundTransparency", 1)
	setp(NG146, "BorderSizePixel", 0)
	setp(NG146, "Name", "Local")
	setp(NG146, "Position", UDim2.new(0, 110, 0, 0))
	setp(NG146, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG146, "Parent", NG138)
	NG147 = Instance.new("TextLabel")
	setp(NG147, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG147, "BackgroundTransparency", 1)
	setp(NG147, "BorderSizePixel", 0)
	setp(NG147, "Name", "Label")
	setp(NG147, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG147, "ZIndex", 2)
	setp(NG147, "Font", Enum.Font.ArialBold)
	setp(NG147, "FontSize", Enum.FontSize.Size10)
	setp(NG147, "Text", "LOCAL")
	setp(NG147, "TextColor3", Color3.new(1, 1, 1))
	setp(NG147, "Parent", NG146)
	NG148 = Instance.new("ImageLabel")
	setp(NG148, "Active", false)
	setp(NG148, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG148, "BackgroundTransparency", 1)
	setp(NG148, "BorderSizePixel", 0)
	setp(NG148, "Name", "Background")
	NG148.Selectable = false
	setp(NG148, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG148, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG148, "Parent", NG146)
	NG149 = Instance.new("TextButton")
	setp(NG149, "Active", true)
	setp(NG149, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG149, "BackgroundTransparency", 1)
	setp(NG149, "BorderSizePixel", 0)
	setp(NG149, "Name", "Button")
	setp(NG149, "Position", UDim2.new(0, 5, 0, 0))
	NG149.Selectable = true
	setp(NG149, "Size", UDim2.new(1, -10, 1, 0))
	NG149.Style = Enum.ButtonStyle.Custom
	setp(NG149, "ZIndex", 2)
	setp(NG149, "Font", Enum.Font.Legacy)
	setp(NG149, "FontSize", Enum.FontSize.Size8)
	setp(NG149, "Text", "")
	NG149.TextTransparency = 1
	setp(NG149, "Parent", NG146)
	NG150 = Instance.new("Frame")
	setp(NG150, "BackgroundTransparency", 1)
	setp(NG150, "BorderSizePixel", 0)
	setp(NG150, "Name", "SelectedIndicator")
	setp(NG150, "Position", UDim2.new(0, 6, 0, -2))
	setp(NG150, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG150, "Parent", NG146)
	NG151 = Instance.new("Frame")
	setp(NG151, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG151, "BackgroundTransparency", 1)
	setp(NG151, "BorderSizePixel", 0)
	setp(NG151, "Name", "Global")
	setp(NG151, "Position", UDim2.new(0, 45, 0, 0))
	setp(NG151, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG151, "Parent", NG138)
	NG152 = Instance.new("TextLabel")
	setp(NG152, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG152, "BackgroundTransparency", 1)
	setp(NG152, "BorderSizePixel", 0)
	setp(NG152, "Name", "Label")
	setp(NG152, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG152, "ZIndex", 2)
	setp(NG152, "Font", Enum.Font.ArialBold)
	setp(NG152, "FontSize", Enum.FontSize.Size10)
	setp(NG152, "Text", "GLOBAL")
	setp(NG152, "TextColor3", Color3.new(1, 1, 1))
	setp(NG152, "Parent", NG151)
	NG153 = Instance.new("ImageLabel")
	setp(NG153, "Active", false)
	setp(NG153, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG153, "BackgroundTransparency", 1)
	setp(NG153, "BorderSizePixel", 0)
	setp(NG153, "Name", "Background")
	NG153.Selectable = false
	setp(NG153, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG153, "Image", "http://www.roblox.com/asset/?id=127774197")
	setp(NG153, "Parent", NG151)
	NG154 = Instance.new("TextButton")
	setp(NG154, "Active", true)
	setp(NG154, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG154, "BackgroundTransparency", 1)
	setp(NG154, "BorderSizePixel", 0)
	setp(NG154, "Name", "Button")
	setp(NG154, "Position", UDim2.new(0, 5, 0, 0))
	NG154.Selectable = true
	setp(NG154, "Size", UDim2.new(1, -10, 1, 0))
	NG154.Style = Enum.ButtonStyle.Custom
	setp(NG154, "ZIndex", 2)
	setp(NG154, "Font", Enum.Font.Legacy)
	setp(NG154, "FontSize", Enum.FontSize.Size8)
	setp(NG154, "Text", "")
	NG154.TextTransparency = 1
	setp(NG154, "Parent", NG151)
	NG155 = Instance.new("Frame")
	setp(NG155, "BorderSizePixel", 0)
	setp(NG155, "Name", "SelectedIndicator")
	setp(NG155, "Position", UDim2.new(0, 6, 0, -2))
	setp(NG155, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG155, "Parent", NG151)
	NG156 = Instance.new("Frame")
	setp(NG156, "Active", true)
	setp(NG156, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG156, "BackgroundTransparency", 1)
	setp(NG156, "BorderSizePixel", 0)
	setp(NG156, "Name", "BTResizeToolGUI")
	setp(NG156, "Position", UDim2.new(0, 0, 0, 280))
	setp(NG156, "Size", UDim2.new(0, 245, 0, 90))
	NG156.Draggable = true
	setp(NG156, "Parent", NG1)
	NG157 = Instance.new("Frame")
	setp(NG157, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG157, "BackgroundTransparency", 1)
	setp(NG157, "BorderSizePixel", 0)
	setp(NG157, "Name", "DirectionsOption")
	setp(NG157, "Position", UDim2.new(0, 0, 0, 30))
	setp(NG157, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG157, "Parent", NG156)
	NG158 = Instance.new("Frame")
	setp(NG158, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG158, "BackgroundTransparency", 1)
	setp(NG158, "BorderSizePixel", 0)
	setp(NG158, "Name", "Normal")
	setp(NG158, "Position", UDim2.new(0, 70, 0, 0))
	setp(NG158, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG158, "Parent", NG157)
	NG159 = Instance.new("Frame")
	setp(NG159, "BorderSizePixel", 0)
	setp(NG159, "Name", "SelectedIndicator")
	setp(NG159, "Position", UDim2.new(0, 6, 0, -2))
	setp(NG159, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG159, "Parent", NG158)
	NG160 = Instance.new("TextButton")
	setp(NG160, "Active", true)
	setp(NG160, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG160, "BackgroundTransparency", 1)
	setp(NG160, "BorderSizePixel", 0)
	setp(NG160, "Name", "Button")
	setp(NG160, "Position", UDim2.new(0, 5, 0, 0))
	NG160.Selectable = true
	setp(NG160, "Size", UDim2.new(1, -10, 1, 0))
	NG160.Style = Enum.ButtonStyle.Custom
	setp(NG160, "ZIndex", 2)
	setp(NG160, "Font", Enum.Font.Legacy)
	setp(NG160, "FontSize", Enum.FontSize.Size8)
	setp(NG160, "Text", "")
	NG160.TextTransparency = 1
	setp(NG160, "Parent", NG158)
	NG161 = Instance.new("ImageLabel")
	setp(NG161, "Active", false)
	setp(NG161, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG161, "BackgroundTransparency", 1)
	setp(NG161, "BorderSizePixel", 0)
	setp(NG161, "Name", "Background")
	NG161.Selectable = false
	setp(NG161, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG161, "Image", "http://www.roblox.com/asset/?id=127774197")
	setp(NG161, "Parent", NG158)
	NG162 = Instance.new("TextLabel")
	setp(NG162, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG162, "BackgroundTransparency", 1)
	setp(NG162, "BorderSizePixel", 0)
	setp(NG162, "Name", "Label")
	setp(NG162, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG162, "Font", Enum.Font.ArialBold)
	setp(NG162, "FontSize", Enum.FontSize.Size10)
	setp(NG162, "Text", "NORMAL")
	setp(NG162, "TextColor3", Color3.new(1, 1, 1))
	setp(NG162, "Parent", NG158)
	NG163 = Instance.new("Frame")
	setp(NG163, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG163, "BackgroundTransparency", 1)
	setp(NG163, "BorderSizePixel", 0)
	setp(NG163, "Name", "Both")
	setp(NG163, "Position", UDim2.new(0, 135, 0, 0))
	setp(NG163, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG163, "Parent", NG157)
	NG164 = Instance.new("Frame")
	setp(NG164, "BackgroundTransparency", 1)
	setp(NG164, "BorderSizePixel", 0)
	setp(NG164, "Name", "SelectedIndicator")
	setp(NG164, "Position", UDim2.new(0, 6, 0, -2))
	setp(NG164, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG164, "Parent", NG163)
	NG165 = Instance.new("TextButton")
	setp(NG165, "Active", true)
	setp(NG165, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG165, "BackgroundTransparency", 1)
	setp(NG165, "BorderSizePixel", 0)
	setp(NG165, "Name", "Button")
	setp(NG165, "Position", UDim2.new(0, 5, 0, 0))
	NG165.Selectable = true
	setp(NG165, "Size", UDim2.new(1, -10, 1, 0))
	NG165.Style = Enum.ButtonStyle.Custom
	setp(NG165, "ZIndex", 2)
	setp(NG165, "Font", Enum.Font.Legacy)
	setp(NG165, "FontSize", Enum.FontSize.Size8)
	setp(NG165, "Text", "")
	NG165.TextTransparency = 1
	setp(NG165, "Parent", NG163)
	NG166 = Instance.new("ImageLabel")
	setp(NG166, "Active", false)
	setp(NG166, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG166, "BackgroundTransparency", 1)
	setp(NG166, "BorderSizePixel", 0)
	setp(NG166, "Name", "Background")
	NG166.Selectable = false
	setp(NG166, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG166, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG166, "Parent", NG163)
	NG167 = Instance.new("TextLabel")
	setp(NG167, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG167, "BackgroundTransparency", 1)
	setp(NG167, "BorderSizePixel", 0)
	setp(NG167, "Name", "Label")
	setp(NG167, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG167, "Font", Enum.Font.ArialBold)
	setp(NG167, "FontSize", Enum.FontSize.Size10)
	setp(NG167, "Text", "BOTH")
	setp(NG167, "TextColor3", Color3.new(1, 1, 1))
	setp(NG167, "Parent", NG163)
	NG168 = Instance.new("Frame")
	setp(NG168, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG168, "BackgroundTransparency", 1)
	setp(NG168, "BorderSizePixel", 0)
	setp(NG168, "Name", "Label")
	setp(NG168, "Size", UDim2.new(0, 75, 0, 25))
	setp(NG168, "Parent", NG157)
	NG169 = Instance.new("TextLabel")
	setp(NG169, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG169, "BackgroundTransparency", 1)
	setp(NG169, "BorderSizePixel", 0)
	setp(NG169, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG169, "Font", Enum.Font.ArialBold)
	setp(NG169, "FontSize", Enum.FontSize.Size10)
	setp(NG169, "Text", "Directions")
	setp(NG169, "TextColor3", Color3.new(1, 1, 1))
	setp(NG169, "TextStrokeTransparency", 0)
	setp(NG169, "TextWrapped", true)
	setp(NG169, "Parent", NG168)
	NG170 = Instance.new("Frame")
	setp(NG170, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG170, "BackgroundTransparency", 1)
	setp(NG170, "BorderSizePixel", 0)
	setp(NG170, "Name", "Title")
	setp(NG170, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG170, "Parent", NG156)
	NG171 = Instance.new("Frame")
	setp(NG171, "BackgroundColor3", Color3.new(0.0156863, 0.686275, 0.92549))
	setp(NG171, "BorderSizePixel", 0)
	setp(NG171, "Name", "ColorBar")
	setp(NG171, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG171, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG171, "Parent", NG170)
	NG172 = Instance.new("TextLabel")
	setp(NG172, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG172, "BackgroundTransparency", 1)
	setp(NG172, "BorderSizePixel", 0)
	setp(NG172, "Name", "Label")
	setp(NG172, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG172, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG172, "Font", Enum.Font.ArialBold)
	setp(NG172, "FontSize", Enum.FontSize.Size10)
	setp(NG172, "Text", "RESIZE TOOL")
	setp(NG172, "TextColor3", Color3.new(1, 1, 1))
	setp(NG172, "TextStrokeTransparency", 0)
	setp(NG172, "TextWrapped", true)
	setp(NG172, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG172, "Parent", NG170)
	NG173 = Instance.new("TextLabel")
	setp(NG173, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG173, "BackgroundTransparency", 1)
	setp(NG173, "BorderSizePixel", 0)
	setp(NG173, "Name", "F3XSignature")
	setp(NG173, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG173, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG173, "Font", Enum.Font.ArialBold)
	setp(NG173, "FontSize", Enum.FontSize.Size14)
	setp(NG173, "Text", "F3X")
	setp(NG173, "TextColor3", Color3.new(1, 1, 1))
	setp(NG173, "TextStrokeTransparency", 0.89999997615814)
	setp(NG173, "TextWrapped", true)
	setp(NG173, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG173, "Parent", NG170)
	NG174 = Instance.new("Frame")
	setp(NG174, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG174, "BackgroundTransparency", 1)
	setp(NG174, "BorderSizePixel", 0)
	setp(NG174, "Name", "IncrementOption")
	setp(NG174, "Position", UDim2.new(0, 0, 0, 65))
	setp(NG174, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG174, "Parent", NG156)
	NG175 = Instance.new("Frame")
	setp(NG175, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG175, "BackgroundTransparency", 1)
	setp(NG175, "BorderSizePixel", 0)
	setp(NG175, "Name", "Increment")
	setp(NG175, "Position", UDim2.new(0, 70, 0, 0))
	setp(NG175, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG175, "Parent", NG174)
	NG176 = Instance.new("Frame")
	setp(NG176, "BorderSizePixel", 0)
	setp(NG176, "Name", "SelectedIndicator")
	setp(NG176, "Position", UDim2.new(0, 5, 0, -2))
	setp(NG176, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG176, "Parent", NG175)
	NG177 = Instance.new("TextBox")
	setp(NG177, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG177, "BackgroundTransparency", 1)
	setp(NG177, "BorderSizePixel", 0)
	setp(NG177, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG177, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG177, "ZIndex", 2)
	setp(NG177, "Font", Enum.Font.ArialBold)
	setp(NG177, "FontSize", Enum.FontSize.Size10)
	setp(NG177, "Text", "1")
	setp(NG177, "TextColor3", Color3.new(1, 1, 1))
	setp(NG177, "Parent", NG175)
	NG178 = Instance.new("ImageLabel")
	setp(NG178, "Active", false)
	setp(NG178, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG178, "BackgroundTransparency", 1)
	setp(NG178, "BorderSizePixel", 0)
	setp(NG178, "Name", "Background")
	NG178.Selectable = false
	setp(NG178, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG178, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG178, "Parent", NG175)
	NG179 = Instance.new("Frame")
	setp(NG179, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG179, "BackgroundTransparency", 1)
	setp(NG179, "BorderSizePixel", 0)
	setp(NG179, "Name", "Label")
	setp(NG179, "Size", UDim2.new(0, 75, 0, 25))
	setp(NG179, "Parent", NG174)
	NG180 = Instance.new("TextLabel")
	setp(NG180, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG180, "BackgroundTransparency", 1)
	setp(NG180, "BorderSizePixel", 0)
	setp(NG180, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG180, "Font", Enum.Font.ArialBold)
	setp(NG180, "FontSize", Enum.FontSize.Size10)
	setp(NG180, "Text", "Increment")
	setp(NG180, "TextColor3", Color3.new(1, 1, 1))
	setp(NG180, "TextStrokeTransparency", 0)
	setp(NG180, "TextWrapped", true)
	setp(NG180, "Parent", NG179)
	NG181 = Instance.new("Frame")
	setp(NG181, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG181, "BackgroundTransparency", 1)
	setp(NG181, "BorderSizePixel", 0)
	setp(NG181, "Name", "Info")
	setp(NG181, "Position", UDim2.new(0, 5, 0, 100))
	setp(NG181, "Size", UDim2.new(1, -5, 0, 60))
	setp(NG181, "Visible", false)
	setp(NG181, "Parent", NG156)
	NG182 = Instance.new("Frame")
	setp(NG182, "BackgroundColor3", Color3.new(0.0156863, 0.686275, 0.92549))
	setp(NG182, "BorderSizePixel", 0)
	setp(NG182, "Name", "ColorBar")
	setp(NG182, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG182, "Parent", NG181)
	NG183 = Instance.new("TextLabel")
	setp(NG183, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG183, "BackgroundTransparency", 1)
	setp(NG183, "BorderSizePixel", 0)
	setp(NG183, "Name", "Label")
	setp(NG183, "Position", UDim2.new(0, 10, 0, 2))
	setp(NG183, "Size", UDim2.new(1, -10, 0, 20))
	setp(NG183, "Font", Enum.Font.ArialBold)
	setp(NG183, "FontSize", Enum.FontSize.Size10)
	setp(NG183, "Text", "SELECTION INFO")
	setp(NG183, "TextColor3", Color3.new(1, 1, 1))
	setp(NG183, "TextStrokeTransparency", 0)
	setp(NG183, "TextWrapped", true)
	setp(NG183, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG183, "Parent", NG181)
	NG184 = Instance.new("Frame")
	setp(NG184, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG184, "BackgroundTransparency", 1)
	setp(NG184, "BorderSizePixel", 0)
	setp(NG184, "Name", "SizeInfo")
	setp(NG184, "Position", UDim2.new(0, 0, 0, 30))
	setp(NG184, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG184, "Parent", NG181)
	NG185 = Instance.new("TextLabel")
	setp(NG185, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG185, "BackgroundTransparency", 1)
	setp(NG185, "BorderSizePixel", 0)
	setp(NG185, "Size", UDim2.new(0, 75, 0, 25))
	setp(NG185, "Font", Enum.Font.ArialBold)
	setp(NG185, "FontSize", Enum.FontSize.Size10)
	setp(NG185, "Text", "Size")
	setp(NG185, "TextColor3", Color3.new(1, 1, 1))
	setp(NG185, "TextStrokeTransparency", 0)
	setp(NG185, "TextWrapped", true)
	setp(NG185, "Parent", NG184)
	NG186 = Instance.new("Frame")
	setp(NG186, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG186, "BackgroundTransparency", 1)
	setp(NG186, "BorderSizePixel", 0)
	setp(NG186, "Name", "X")
	setp(NG186, "Position", UDim2.new(0, 70, 0, 0))
	setp(NG186, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG186, "Parent", NG184)
	NG187 = Instance.new("TextBox")
	setp(NG187, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG187, "BackgroundTransparency", 1)
	setp(NG187, "BorderSizePixel", 0)
	setp(NG187, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG187, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG187, "ZIndex", 2)
	setp(NG187, "Font", Enum.Font.ArialBold)
	setp(NG187, "FontSize", Enum.FontSize.Size10)
	setp(NG187, "Text", "")
	setp(NG187, "TextColor3", Color3.new(1, 1, 1))
	setp(NG187, "Parent", NG186)
	NG188 = Instance.new("TextButton")
	setp(NG188, "Active", true)
	setp(NG188, "AutoButtonColor", false)
	setp(NG188, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG188, "BackgroundTransparency", 1)
	setp(NG188, "BorderSizePixel", 0)
	NG188.Selectable = true
	setp(NG188, "Size", UDim2.new(1, 0, 1, 0))
	NG188.Style = Enum.ButtonStyle.Custom
	setp(NG188, "ZIndex", 3)
	setp(NG188, "Font", Enum.Font.Legacy)
	setp(NG188, "FontSize", Enum.FontSize.Size8)
	setp(NG188, "Text", "")
	setp(NG188, "Parent", NG186)
	NG189 = Instance.new("ImageLabel")
	setp(NG189, "Active", false)
	setp(NG189, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG189, "BackgroundTransparency", 1)
	setp(NG189, "BorderSizePixel", 0)
	setp(NG189, "Name", "Background")
	NG189.Selectable = false
	setp(NG189, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG189, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG189, "Parent", NG186)
	NG190 = Instance.new("Frame")
	setp(NG190, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG190, "BackgroundTransparency", 1)
	setp(NG190, "BorderSizePixel", 0)
	setp(NG190, "Name", "Y")
	setp(NG190, "Position", UDim2.new(0, 117, 0, 0))
	setp(NG190, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG190, "Parent", NG184)
	NG191 = Instance.new("TextBox")
	setp(NG191, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG191, "BackgroundTransparency", 1)
	setp(NG191, "BorderSizePixel", 0)
	setp(NG191, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG191, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG191, "ZIndex", 2)
	setp(NG191, "Font", Enum.Font.ArialBold)
	setp(NG191, "FontSize", Enum.FontSize.Size10)
	setp(NG191, "Text", "")
	setp(NG191, "TextColor3", Color3.new(1, 1, 1))
	setp(NG191, "Parent", NG190)
	NG192 = Instance.new("TextButton")
	setp(NG192, "Active", true)
	setp(NG192, "AutoButtonColor", false)
	setp(NG192, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG192, "BackgroundTransparency", 1)
	setp(NG192, "BorderSizePixel", 0)
	NG192.Selectable = true
	setp(NG192, "Size", UDim2.new(1, 0, 1, 0))
	NG192.Style = Enum.ButtonStyle.Custom
	setp(NG192, "ZIndex", 3)
	setp(NG192, "Font", Enum.Font.Legacy)
	setp(NG192, "FontSize", Enum.FontSize.Size8)
	setp(NG192, "Text", "")
	setp(NG192, "Parent", NG190)
	NG193 = Instance.new("ImageLabel")
	setp(NG193, "Active", false)
	setp(NG193, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG193, "BackgroundTransparency", 1)
	setp(NG193, "BorderSizePixel", 0)
	setp(NG193, "Name", "Background")
	NG193.Selectable = false
	setp(NG193, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG193, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG193, "Parent", NG190)
	NG194 = Instance.new("Frame")
	setp(NG194, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG194, "BackgroundTransparency", 1)
	setp(NG194, "BorderSizePixel", 0)
	setp(NG194, "Name", "Z")
	setp(NG194, "Position", UDim2.new(0, 164, 0, 0))
	setp(NG194, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG194, "Parent", NG184)
	NG195 = Instance.new("TextBox")
	setp(NG195, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG195, "BackgroundTransparency", 1)
	setp(NG195, "BorderSizePixel", 0)
	setp(NG195, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG195, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG195, "ZIndex", 2)
	setp(NG195, "Font", Enum.Font.ArialBold)
	setp(NG195, "FontSize", Enum.FontSize.Size10)
	setp(NG195, "Text", "")
	setp(NG195, "TextColor3", Color3.new(1, 1, 1))
	setp(NG195, "Parent", NG194)
	NG196 = Instance.new("TextButton")
	setp(NG196, "Active", true)
	setp(NG196, "AutoButtonColor", false)
	setp(NG196, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG196, "BackgroundTransparency", 1)
	setp(NG196, "BorderSizePixel", 0)
	NG196.Selectable = true
	setp(NG196, "Size", UDim2.new(1, 0, 1, 0))
	NG196.Style = Enum.ButtonStyle.Custom
	setp(NG196, "ZIndex", 3)
	setp(NG196, "Font", Enum.Font.Legacy)
	setp(NG196, "FontSize", Enum.FontSize.Size8)
	setp(NG196, "Text", "")
	setp(NG196, "Parent", NG194)
	NG197 = Instance.new("ImageLabel")
	setp(NG197, "Active", false)
	setp(NG197, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG197, "BackgroundTransparency", 1)
	setp(NG197, "BorderSizePixel", 0)
	setp(NG197, "Name", "Background")
	NG197.Selectable = false
	setp(NG197, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG197, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG197, "Parent", NG194)
	NG198 = Instance.new("Frame")
	setp(NG198, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG198, "BackgroundTransparency", 1)
	setp(NG198, "BorderSizePixel", 0)
	setp(NG198, "Name", "Changes")
	setp(NG198, "Position", UDim2.new(0, 5, 0, 100))
	setp(NG198, "Size", UDim2.new(1, -5, 0, 20))
	setp(NG198, "Parent", NG156)
	NG199 = Instance.new("Frame")
	setp(NG199, "BackgroundColor3", Color3.new(0.0156863, 0.686275, 0.92549))
	setp(NG199, "BorderSizePixel", 0)
	setp(NG199, "Name", "ColorBar")
	setp(NG199, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG199, "Parent", NG198)
	NG200 = Instance.new("TextLabel")
	setp(NG200, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG200, "BackgroundTransparency", 1)
	setp(NG200, "BorderSizePixel", 0)
	setp(NG200, "Name", "Text")
	setp(NG200, "Position", UDim2.new(0, 10, 0, 2))
	setp(NG200, "Size", UDim2.new(1, -10, 0, 20))
	setp(NG200, "Font", Enum.Font.ArialBold)
	setp(NG200, "FontSize", Enum.FontSize.Size10)
	setp(NG200, "Text", "resized 0 studs")
	setp(NG200, "TextColor3", Color3.new(1, 1, 1))
	setp(NG200, "TextStrokeTransparency", 0.5)
	setp(NG200, "TextWrapped", true)
	setp(NG200, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG200, "Parent", NG198)
	NG201 = Instance.new("Frame")
	setp(NG201, "Active", true)
	setp(NG201, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG201, "BackgroundTransparency", 1)
	setp(NG201, "BorderSizePixel", 0)
	setp(NG201, "Name", "BTSurfaceToolGUI")
	setp(NG201, "Position", UDim2.new(0, 0, 0, 172))
	setp(NG201, "Size", UDim2.new(0, 245, 0, 90))
	NG201.Draggable = true
	setp(NG201, "Parent", NG1)
	NG202 = Instance.new("Frame")
	setp(NG202, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG202, "BackgroundTransparency", 1)
	setp(NG202, "BorderSizePixel", 0)
	setp(NG202, "Name", "Title")
	setp(NG202, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG202, "Parent", NG201)
	NG203 = Instance.new("Frame")
	setp(NG203, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG203, "BorderSizePixel", 0)
	setp(NG203, "Name", "ColorBar")
	setp(NG203, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG203, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG203, "Parent", NG202)
	NG204 = Instance.new("TextLabel")
	setp(NG204, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG204, "BackgroundTransparency", 1)
	setp(NG204, "BorderSizePixel", 0)
	setp(NG204, "Name", "Label")
	setp(NG204, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG204, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG204, "Font", Enum.Font.ArialBold)
	setp(NG204, "FontSize", Enum.FontSize.Size10)
	setp(NG204, "Text", "SURFACE TOOL")
	setp(NG204, "TextColor3", Color3.new(1, 1, 1))
	setp(NG204, "TextStrokeTransparency", 0)
	setp(NG204, "TextWrapped", true)
	setp(NG204, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG204, "Parent", NG202)
	NG205 = Instance.new("TextLabel")
	setp(NG205, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG205, "BackgroundTransparency", 1)
	setp(NG205, "BorderSizePixel", 0)
	setp(NG205, "Name", "F3XSignature")
	setp(NG205, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG205, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG205, "Font", Enum.Font.ArialBold)
	setp(NG205, "FontSize", Enum.FontSize.Size14)
	setp(NG205, "Text", "F3X")
	setp(NG205, "TextColor3", Color3.new(1, 1, 1))
	setp(NG205, "TextStrokeTransparency", 0.89999997615814)
	setp(NG205, "TextWrapped", true)
	setp(NG205, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG205, "Parent", NG202)
	NG206 = Instance.new("Frame")
	setp(NG206, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG206, "BackgroundTransparency", 1)
	setp(NG206, "BorderSizePixel", 0)
	setp(NG206, "Name", "SideOption")
	setp(NG206, "Position", UDim2.new(0, 14, 0, 30))
	setp(NG206, "Size", UDim2.new(0, 120, 0, 25))
	setp(NG206, "Parent", NG201)
	NG207 = Instance.new("TextLabel")
	setp(NG207, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG207, "BackgroundTransparency", 1)
	setp(NG207, "BorderSizePixel", 0)
	setp(NG207, "Name", "Label")
	setp(NG207, "Size", UDim2.new(0, 40, 0, 25))
	setp(NG207, "Font", Enum.Font.ArialBold)
	setp(NG207, "FontSize", Enum.FontSize.Size10)
	setp(NG207, "Text", "Side")
	setp(NG207, "TextColor3", Color3.new(1, 1, 1))
	setp(NG207, "TextStrokeTransparency", 0)
	setp(NG207, "TextWrapped", true)
	setp(NG207, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG207, "Parent", NG206)
	NG208 = Instance.new("Frame")
	setp(NG208, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG208, "BackgroundTransparency", 1)
	setp(NG208, "BorderSizePixel", 0)
	setp(NG208, "Name", "TypeOption")
	setp(NG208, "Position", UDim2.new(0, 124, 0, 30))
	setp(NG208, "Size", UDim2.new(0, 120, 0, 25))
	setp(NG208, "Parent", NG201)
	NG209 = Instance.new("TextLabel")
	setp(NG209, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG209, "BackgroundTransparency", 1)
	setp(NG209, "BorderSizePixel", 0)
	setp(NG209, "Name", "Label")
	setp(NG209, "Size", UDim2.new(0, 40, 0, 25))
	setp(NG209, "Font", Enum.Font.ArialBold)
	setp(NG209, "FontSize", Enum.FontSize.Size10)
	setp(NG209, "Text", "Type")
	setp(NG209, "TextColor3", Color3.new(1, 1, 1))
	setp(NG209, "TextStrokeTransparency", 0)
	setp(NG209, "TextWrapped", true)
	setp(NG209, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG209, "Parent", NG208)
	NG210 = Instance.new("Frame")
	setp(NG210, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG210, "BackgroundTransparency", 1)
	setp(NG210, "BorderSizePixel", 0)
	setp(NG210, "Name", "Tip")
	setp(NG210, "Position", UDim2.new(0, 5, 0, 70))
	setp(NG210, "Size", UDim2.new(1, -5, 0, 20))
	setp(NG210, "Parent", NG201)
	NG211 = Instance.new("Frame")
	setp(NG211, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG211, "BorderSizePixel", 0)
	setp(NG211, "Name", "ColorBar")
	setp(NG211, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG211, "Parent", NG210)
	NG212 = Instance.new("TextLabel")
	setp(NG212, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG212, "BackgroundTransparency", 1)
	setp(NG212, "BorderSizePixel", 0)
	setp(NG212, "Name", "Text")
	setp(NG212, "Position", UDim2.new(0, 6, 0, 2))
	setp(NG212, "Size", UDim2.new(1, -6, 0, 20))
	setp(NG212, "Font", Enum.Font.ArialBold)
	setp(NG212, "FontSize", Enum.FontSize.Size10)
	setp(NG212, "Text", "TIP: Select a part and right click on a surface")
	setp(NG212, "TextColor3", Color3.new(1, 1, 1))
	setp(NG212, "TextStrokeTransparency", 0.5)
	setp(NG212, "TextWrapped", true)
	setp(NG212, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG212, "Parent", NG210)
	NG213 = Instance.new("Frame")
	setp(NG213, "Active", true)
	setp(NG213, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG213, "BackgroundTransparency", 1)
	setp(NG213, "BorderSizePixel", 0)
	setp(NG213, "Name", "BTTextureToolGUI")
	setp(NG213, "Position", UDim2.new(0, 0, 0, 172))
	setp(NG213, "Size", UDim2.new(0, 200, 0, 205))
	NG213.Draggable = true
	setp(NG213, "Parent", NG1)
	NG214 = Instance.new("Frame")
	setp(NG214, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG214, "BackgroundTransparency", 1)
	setp(NG214, "BorderSizePixel", 0)
	setp(NG214, "Name", "Title")
	setp(NG214, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG214, "Parent", NG213)
	NG215 = Instance.new("Frame")
	setp(NG215, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG215, "BorderSizePixel", 0)
	setp(NG215, "Name", "ColorBar")
	setp(NG215, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG215, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG215, "Parent", NG214)
	NG216 = Instance.new("TextLabel")
	setp(NG216, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG216, "BackgroundTransparency", 1)
	setp(NG216, "BorderSizePixel", 0)
	setp(NG216, "Name", "Label")
	setp(NG216, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG216, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG216, "Font", Enum.Font.ArialBold)
	setp(NG216, "FontSize", Enum.FontSize.Size10)
	setp(NG216, "Text", "TEXTURE TOOL")
	setp(NG216, "TextColor3", Color3.new(1, 1, 1))
	setp(NG216, "TextStrokeTransparency", 0)
	setp(NG216, "TextWrapped", true)
	setp(NG216, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG216, "Parent", NG214)
	NG217 = Instance.new("TextLabel")
	setp(NG217, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG217, "BackgroundTransparency", 1)
	setp(NG217, "BorderSizePixel", 0)
	setp(NG217, "Name", "F3XSignature")
	setp(NG217, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG217, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG217, "Font", Enum.Font.ArialBold)
	setp(NG217, "FontSize", Enum.FontSize.Size14)
	setp(NG217, "Text", "F3X")
	setp(NG217, "TextColor3", Color3.new(1, 1, 1))
	setp(NG217, "TextStrokeTransparency", 0.89999997615814)
	setp(NG217, "TextWrapped", true)
	setp(NG217, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG217, "Parent", NG214)
	NG218 = Instance.new("Frame")
	setp(NG218, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG218, "BackgroundTransparency", 1)
	setp(NG218, "BorderSizePixel", 0)
	setp(NG218, "Name", "SideOption")
	setp(NG218, "Position", UDim2.new(0, 14, 0, 65))
	setp(NG218, "Size", UDim2.new(1, -14, 0, 25))
	setp(NG218, "Parent", NG213)
	NG219 = Instance.new("TextLabel")
	setp(NG219, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG219, "BackgroundTransparency", 1)
	setp(NG219, "BorderSizePixel", 0)
	setp(NG219, "Name", "Label")
	setp(NG219, "Size", UDim2.new(0, 30, 0, 25))
	setp(NG219, "Font", Enum.Font.ArialBold)
	setp(NG219, "FontSize", Enum.FontSize.Size10)
	setp(NG219, "Text", "Side")
	setp(NG219, "TextColor3", Color3.new(1, 1, 1))
	setp(NG219, "TextStrokeTransparency", 0)
	setp(NG219, "TextWrapped", true)
	setp(NG219, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG219, "Parent", NG218)
	NG220 = Instance.new("Frame")
	setp(NG220, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG220, "BackgroundTransparency", 1)
	setp(NG220, "BorderSizePixel", 0)
	setp(NG220, "Name", "RepeatOption")
	setp(NG220, "Position", UDim2.new(0, 0, 0, 205))
	setp(NG220, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG220, "Visible", false)
	setp(NG220, "Parent", NG213)
	NG221 = Instance.new("TextLabel")
	setp(NG221, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG221, "BackgroundTransparency", 1)
	setp(NG221, "BorderSizePixel", 0)
	setp(NG221, "Name", "Label")
	setp(NG221, "Position", UDim2.new(0, 14, 0, 0))
	setp(NG221, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG221, "Font", Enum.Font.ArialBold)
	setp(NG221, "FontSize", Enum.FontSize.Size10)
	setp(NG221, "Text", "Repeat")
	setp(NG221, "TextColor3", Color3.new(1, 1, 1))
	setp(NG221, "TextStrokeTransparency", 0)
	setp(NG221, "TextWrapped", true)
	setp(NG221, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG221, "Parent", NG220)
	NG222 = Instance.new("Frame")
	setp(NG222, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG222, "BackgroundTransparency", 1)
	setp(NG222, "BorderSizePixel", 0)
	setp(NG222, "Name", "XInput")
	setp(NG222, "Position", UDim2.new(0, 60, 0, 0))
	setp(NG222, "Size", UDim2.new(0, 45, 0, 25))
	setp(NG222, "Parent", NG220)
	NG223 = Instance.new("TextButton")
	setp(NG223, "Active", true)
	setp(NG223, "AutoButtonColor", false)
	setp(NG223, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG223, "BackgroundTransparency", 1)
	setp(NG223, "BorderSizePixel", 0)
	NG223.Selectable = true
	setp(NG223, "Size", UDim2.new(1, 0, 1, 0))
	NG223.Style = Enum.ButtonStyle.Custom
	setp(NG223, "ZIndex", 2)
	setp(NG223, "Font", Enum.Font.Legacy)
	setp(NG223, "FontSize", Enum.FontSize.Size8)
	setp(NG223, "Text", "")
	setp(NG223, "Parent", NG222)
	NG224 = Instance.new("ImageLabel")
	setp(NG224, "Active", false)
	setp(NG224, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG224, "BackgroundTransparency", 1)
	setp(NG224, "BorderSizePixel", 0)
	setp(NG224, "Name", "Background")
	NG224.Selectable = false
	setp(NG224, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG224, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG224, "Parent", NG222)
	NG225 = Instance.new("Frame")
	setp(NG225, "BorderSizePixel", 0)
	setp(NG225, "Name", "SelectedIndicator")
	setp(NG225, "Position", UDim2.new(0, 5, 0, -2))
	setp(NG225, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG225, "Parent", NG222)
	NG226 = Instance.new("TextBox")
	setp(NG226, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG226, "BackgroundTransparency", 1)
	setp(NG226, "BorderSizePixel", 0)
	setp(NG226, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG226, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG226, "Font", Enum.Font.ArialBold)
	setp(NG226, "FontSize", Enum.FontSize.Size10)
	setp(NG226, "Text", "2")
	setp(NG226, "TextColor3", Color3.new(1, 1, 1))
	setp(NG226, "Parent", NG222)
	NG227 = Instance.new("Frame")
	setp(NG227, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG227, "BackgroundTransparency", 1)
	setp(NG227, "BorderSizePixel", 0)
	setp(NG227, "Name", "YInput")
	setp(NG227, "Position", UDim2.new(0, 105, 0, 0))
	setp(NG227, "Size", UDim2.new(0, 45, 0, 25))
	setp(NG227, "Parent", NG220)
	NG228 = Instance.new("TextButton")
	setp(NG228, "Active", true)
	setp(NG228, "AutoButtonColor", false)
	setp(NG228, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG228, "BackgroundTransparency", 1)
	setp(NG228, "BorderSizePixel", 0)
	NG228.Selectable = true
	setp(NG228, "Size", UDim2.new(1, 0, 1, 0))
	NG228.Style = Enum.ButtonStyle.Custom
	setp(NG228, "ZIndex", 2)
	setp(NG228, "Font", Enum.Font.Legacy)
	setp(NG228, "FontSize", Enum.FontSize.Size8)
	setp(NG228, "Text", "")
	setp(NG228, "Parent", NG227)
	NG229 = Instance.new("ImageLabel")
	setp(NG229, "Active", false)
	setp(NG229, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG229, "BackgroundTransparency", 1)
	setp(NG229, "BorderSizePixel", 0)
	setp(NG229, "Name", "Background")
	NG229.Selectable = false
	setp(NG229, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG229, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG229, "Parent", NG227)
	NG230 = Instance.new("Frame")
	setp(NG230, "BorderSizePixel", 0)
	setp(NG230, "Name", "SelectedIndicator")
	setp(NG230, "Position", UDim2.new(0, 5, 0, -2))
	setp(NG230, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG230, "Parent", NG227)
	NG231 = Instance.new("TextBox")
	setp(NG231, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG231, "BackgroundTransparency", 1)
	setp(NG231, "BorderSizePixel", 0)
	setp(NG231, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG231, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG231, "Font", Enum.Font.ArialBold)
	setp(NG231, "FontSize", Enum.FontSize.Size10)
	setp(NG231, "Text", "2")
	setp(NG231, "TextColor3", Color3.new(1, 1, 1))
	setp(NG231, "Parent", NG227)
	NG232 = Instance.new("Frame")
	setp(NG232, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG232, "BorderSizePixel", 0)
	setp(NG232, "Name", "BottomColorBar")
	setp(NG232, "Position", UDim2.new(0, 5, 1, -2))
	setp(NG232, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG232, "Parent", NG213)
	NG233 = Instance.new("Frame")
	setp(NG233, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG233, "BackgroundTransparency", 1)
	setp(NG233, "BorderSizePixel", 0)
	setp(NG233, "Name", "TransparencyOption")
	setp(NG233, "Position", UDim2.new(0, 14, 0, 135))
	setp(NG233, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG233, "Parent", NG213)
	NG234 = Instance.new("TextLabel")
	setp(NG234, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG234, "BackgroundTransparency", 1)
	setp(NG234, "BorderSizePixel", 0)
	setp(NG234, "Name", "Label")
	setp(NG234, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG234, "Font", Enum.Font.ArialBold)
	setp(NG234, "FontSize", Enum.FontSize.Size10)
	setp(NG234, "Text", "Transparency")
	setp(NG234, "TextColor3", Color3.new(1, 1, 1))
	setp(NG234, "TextStrokeTransparency", 0)
	setp(NG234, "TextWrapped", true)
	setp(NG234, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG234, "Parent", NG233)
	NG235 = Instance.new("Frame")
	setp(NG235, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG235, "BackgroundTransparency", 1)
	setp(NG235, "BorderSizePixel", 0)
	setp(NG235, "Name", "TransparencyInput")
	setp(NG235, "Position", UDim2.new(0, 75, 0, 0))
	setp(NG235, "Size", UDim2.new(0, 45, 0, 25))
	setp(NG235, "Parent", NG233)
	NG236 = Instance.new("TextButton")
	setp(NG236, "Active", true)
	setp(NG236, "AutoButtonColor", false)
	setp(NG236, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG236, "BackgroundTransparency", 1)
	setp(NG236, "BorderSizePixel", 0)
	NG236.Selectable = true
	setp(NG236, "Size", UDim2.new(1, 0, 1, 0))
	NG236.Style = Enum.ButtonStyle.Custom
	setp(NG236, "ZIndex", 2)
	setp(NG236, "Font", Enum.Font.Legacy)
	setp(NG236, "FontSize", Enum.FontSize.Size8)
	setp(NG236, "Text", "")
	setp(NG236, "Parent", NG235)
	NG237 = Instance.new("ImageLabel")
	setp(NG237, "Active", false)
	setp(NG237, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG237, "BackgroundTransparency", 1)
	setp(NG237, "BorderSizePixel", 0)
	setp(NG237, "Name", "Background")
	NG237.Selectable = false
	setp(NG237, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG237, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG237, "Parent", NG235)
	NG238 = Instance.new("Frame")
	setp(NG238, "BorderSizePixel", 0)
	setp(NG238, "Name", "SelectedIndicator")
	setp(NG238, "Position", UDim2.new(0, 5, 0, -2))
	setp(NG238, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG238, "Parent", NG235)
	NG239 = Instance.new("TextBox")
	setp(NG239, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG239, "BackgroundTransparency", 1)
	setp(NG239, "BorderSizePixel", 0)
	setp(NG239, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG239, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG239, "Font", Enum.Font.ArialBold)
	setp(NG239, "FontSize", Enum.FontSize.Size10)
	setp(NG239, "Text", "0")
	setp(NG239, "TextColor3", Color3.new(1, 1, 1))
	setp(NG239, "Parent", NG235)
	NG240 = Instance.new("Frame")
	setp(NG240, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG240, "BackgroundTransparency", 1)
	setp(NG240, "BorderSizePixel", 0)
	setp(NG240, "Name", "ModeOption")
	setp(NG240, "Position", UDim2.new(0, 0, 0, 30))
	setp(NG240, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG240, "Parent", NG213)
	NG241 = Instance.new("TextLabel")
	setp(NG241, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG241, "BackgroundTransparency", 1)
	setp(NG241, "BorderSizePixel", 0)
	setp(NG241, "Name", "Label")
	setp(NG241, "Position", UDim2.new(0, 14, 0, 0))
	setp(NG241, "Size", UDim2.new(0, 40, 0, 25))
	setp(NG241, "Font", Enum.Font.ArialBold)
	setp(NG241, "FontSize", Enum.FontSize.Size10)
	setp(NG241, "Text", "Mode")
	setp(NG241, "TextColor3", Color3.new(1, 1, 1))
	setp(NG241, "TextStrokeTransparency", 0)
	setp(NG241, "TextWrapped", true)
	setp(NG241, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG241, "Parent", NG240)
	NG242 = Instance.new("Frame")
	setp(NG242, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG242, "BackgroundTransparency", 1)
	setp(NG242, "BorderSizePixel", 0)
	setp(NG242, "Name", "Decal")
	setp(NG242, "Position", UDim2.new(0, 55, 0, 0))
	setp(NG242, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG242, "Parent", NG240)
	NG243 = Instance.new("Frame")
	setp(NG243, "BorderSizePixel", 0)
	setp(NG243, "Name", "SelectedIndicator")
	setp(NG243, "Position", UDim2.new(0, 7, 0, -2))
	setp(NG243, "Size", UDim2.new(1, -7, 0, 2))
	setp(NG243, "Parent", NG242)
	NG244 = Instance.new("TextButton")
	setp(NG244, "Active", true)
	setp(NG244, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG244, "BackgroundTransparency", 1)
	setp(NG244, "BorderSizePixel", 0)
	setp(NG244, "Name", "Button")
	setp(NG244, "Position", UDim2.new(0, 5, 0, 0))
	NG244.Selectable = true
	setp(NG244, "Size", UDim2.new(1, -10, 1, 0))
	NG244.Style = Enum.ButtonStyle.Custom
	setp(NG244, "ZIndex", 2)
	setp(NG244, "Font", Enum.Font.Legacy)
	setp(NG244, "FontSize", Enum.FontSize.Size8)
	setp(NG244, "Text", "")
	NG244.TextTransparency = 1
	setp(NG244, "Parent", NG242)
	NG245 = Instance.new("ImageLabel")
	setp(NG245, "Active", false)
	setp(NG245, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG245, "BackgroundTransparency", 1)
	setp(NG245, "BorderSizePixel", 0)
	setp(NG245, "Name", "Background")
	NG245.Selectable = false
	setp(NG245, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG245, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG245, "Parent", NG242)
	NG246 = Instance.new("TextLabel")
	setp(NG246, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG246, "BackgroundTransparency", 1)
	setp(NG246, "BorderSizePixel", 0)
	setp(NG246, "Name", "Label")
	setp(NG246, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG246, "Font", Enum.Font.ArialBold)
	setp(NG246, "FontSize", Enum.FontSize.Size10)
	setp(NG246, "Text", "DECAL")
	setp(NG246, "TextColor3", Color3.new(1, 1, 1))
	setp(NG246, "Parent", NG242)
	NG247 = Instance.new("Frame")
	setp(NG247, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG247, "BackgroundTransparency", 1)
	setp(NG247, "BorderSizePixel", 0)
	setp(NG247, "Name", "Texture")
	setp(NG247, "Position", UDim2.new(0, 122, 0, 0))
	setp(NG247, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG247, "Parent", NG240)
	NG248 = Instance.new("TextButton")
	setp(NG248, "Active", true)
	setp(NG248, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG248, "BackgroundTransparency", 1)
	setp(NG248, "BorderSizePixel", 0)
	setp(NG248, "Name", "Button")
	setp(NG248, "Position", UDim2.new(0, 5, 0, 0))
	NG248.Selectable = true
	setp(NG248, "Size", UDim2.new(1, -10, 1, 0))
	NG248.Style = Enum.ButtonStyle.Custom
	setp(NG248, "ZIndex", 2)
	setp(NG248, "Font", Enum.Font.Legacy)
	setp(NG248, "FontSize", Enum.FontSize.Size8)
	setp(NG248, "Text", "")
	NG248.TextTransparency = 1
	setp(NG248, "Parent", NG247)
	NG249 = Instance.new("ImageLabel")
	setp(NG249, "Active", false)
	setp(NG249, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG249, "BackgroundTransparency", 1)
	setp(NG249, "BorderSizePixel", 0)
	setp(NG249, "Name", "Background")
	NG249.Selectable = false
	setp(NG249, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG249, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG249, "Parent", NG247)
	NG250 = Instance.new("TextLabel")
	setp(NG250, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG250, "BackgroundTransparency", 1)
	setp(NG250, "BorderSizePixel", 0)
	setp(NG250, "Name", "Label")
	setp(NG250, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG250, "Font", Enum.Font.ArialBold)
	setp(NG250, "FontSize", Enum.FontSize.Size10)
	setp(NG250, "Text", "TEXTURE")
	setp(NG250, "TextColor3", Color3.new(1, 1, 1))
	setp(NG250, "Parent", NG247)
	NG251 = Instance.new("Frame")
	setp(NG251, "BackgroundTransparency", 1)
	setp(NG251, "BorderSizePixel", 0)
	setp(NG251, "Name", "SelectedIndicator")
	setp(NG251, "Position", UDim2.new(0, 7, 0, -2))
	setp(NG251, "Size", UDim2.new(1, -7, 0, 2))
	setp(NG251, "Parent", NG247)
	NG252 = Instance.new("Frame")
	setp(NG252, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG252, "BackgroundTransparency", 1)
	setp(NG252, "BorderSizePixel", 0)
	setp(NG252, "Name", "ImageIDOption")
	setp(NG252, "Position", UDim2.new(0, 14, 0, 100))
	setp(NG252, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG252, "Parent", NG213)
	NG253 = Instance.new("TextLabel")
	setp(NG253, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG253, "BackgroundTransparency", 1)
	setp(NG253, "BorderSizePixel", 0)
	setp(NG253, "Name", "Label")
	setp(NG253, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG253, "Font", Enum.Font.ArialBold)
	setp(NG253, "FontSize", Enum.FontSize.Size10)
	setp(NG253, "Text", "Image ID")
	setp(NG253, "TextColor3", Color3.new(1, 1, 1))
	setp(NG253, "TextStrokeTransparency", 0)
	setp(NG253, "TextWrapped", true)
	setp(NG253, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG253, "Parent", NG252)
	NG254 = Instance.new("Frame")
	setp(NG254, "BackgroundTransparency", 1)
	setp(NG254, "BorderSizePixel", 0)
	setp(NG254, "Name", "TextBoxBorder")
	setp(NG254, "Position", UDim2.new(0, 61, 0, 17))
	setp(NG254, "Size", UDim2.new(0, 85, 0, 3))
	setp(NG254, "Parent", NG252)
	NG255 = Instance.new("Frame")
	setp(NG255, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG255, "BorderSizePixel", 0)
	setp(NG255, "Name", "BottomBorder")
	setp(NG255, "Position", UDim2.new(0, 0, 1, -1))
	setp(NG255, "Size", UDim2.new(1, 0, 0, 1))
	setp(NG255, "Parent", NG254)
	NG256 = Instance.new("Frame")
	setp(NG256, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG256, "BorderSizePixel", 0)
	setp(NG256, "Name", "LeftBorder")
	setp(NG256, "Size", UDim2.new(0, 1, 1, 0))
	setp(NG256, "Parent", NG254)
	NG257 = Instance.new("Frame")
	setp(NG257, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG257, "BorderSizePixel", 0)
	setp(NG257, "Name", "RightBorder")
	setp(NG257, "Position", UDim2.new(1, -1, 0, 0))
	setp(NG257, "Size", UDim2.new(0, 1, 1, 0))
	setp(NG257, "Parent", NG254)
	NG258 = Instance.new("Frame")
	setp(NG258, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG258, "BackgroundTransparency", 0.89999997615814)
	setp(NG258, "BorderSizePixel", 0)
	setp(NG258, "Name", "TextBoxBackground")
	setp(NG258, "Position", UDim2.new(0, 60, 0, -2))
	setp(NG258, "Size", UDim2.new(0, 86, 0, 22))
	setp(NG258, "Parent", NG252)
	NG259 = Instance.new("TextButton")
	setp(NG259, "Active", true)
	setp(NG259, "BackgroundTransparency", 1)
	setp(NG259, "BorderSizePixel", 0)
	setp(NG259, "Position", UDim2.new(0, 65, 0, -1))
	NG259.Selectable = true
	setp(NG259, "Size", UDim2.new(0, 80, 0, 18))
	NG259.Style = Enum.ButtonStyle.Custom
	setp(NG259, "ZIndex", 2)
	setp(NG259, "FontSize", Enum.FontSize.Size14)
	setp(NG259, "Text", "")
	setp(NG259, "Parent", NG252)
	NG260 = Instance.new("TextBox")
	setp(NG260, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG260, "BackgroundTransparency", 1)
	setp(NG260, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG260, "BorderSizePixel", 0)
	setp(NG260, "Position", UDim2.new(0, 65, 0, -1))
	setp(NG260, "Size", UDim2.new(0, 80, 0, 18))
	setp(NG260, "Font", Enum.Font.SourceSansBold)
	setp(NG260, "FontSize", Enum.FontSize.Size10)
	setp(NG260, "Text", "")
	setp(NG260, "TextColor3", Color3.new(1, 1, 1))
	setp(NG260, "TextScaled", true)
	setp(NG260, "TextStrokeTransparency", 0.5)
	setp(NG260, "TextWrapped", true)
	setp(NG260, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG260, "Parent", NG252)
	NG261 = Instance.new("Frame")
	setp(NG261, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG261, "BackgroundTransparency", 1)
	setp(NG261, "BorderSizePixel", 0)
	setp(NG261, "Name", "AddButton")
	setp(NG261, "Position", UDim2.new(0, 10, 0, 100))
	setp(NG261, "Size", UDim2.new(1, -10, 0, 20))
	setp(NG261, "Visible", false)
	setp(NG261, "Parent", NG213)
	NG262 = Instance.new("TextButton")
	setp(NG262, "Active", true)
	setp(NG262, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG262, "BackgroundTransparency", 0.44999998807907)
	setp(NG262, "BorderSizePixel", 0)
	setp(NG262, "Name", "Button")
	NG262.Selectable = true
	setp(NG262, "Size", UDim2.new(1, 0, 1, 0))
	NG262.Style = Enum.ButtonStyle.Custom
	setp(NG262, "Font", Enum.Font.ArialBold)
	setp(NG262, "FontSize", Enum.FontSize.Size10)
	setp(NG262, "Text", "ADD DECAL")
	setp(NG262, "TextColor3", Color3.new(1, 1, 1))
	setp(NG262, "TextStrokeTransparency", 0.80000001192093)
	setp(NG262, "Parent", NG261)
	NG263 = Instance.new("Frame")
	setp(NG263, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG263, "BackgroundTransparency", 0.30000001192093)
	setp(NG263, "BorderSizePixel", 0)
	setp(NG263, "Name", "Shadow")
	setp(NG263, "Position", UDim2.new(0, 0, 1, 0))
	setp(NG263, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG263, "ZIndex", 2)
	setp(NG263, "Parent", NG261)
	NG264 = Instance.new("Frame")
	setp(NG264, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG264, "BackgroundTransparency", 1)
	setp(NG264, "BorderSizePixel", 0)
	setp(NG264, "Name", "RemoveButton")
	setp(NG264, "Position", UDim2.new(0, 10, 1, -35))
	setp(NG264, "Size", UDim2.new(1, -10, 0, 20))
	setp(NG264, "Parent", NG213)
	NG265 = Instance.new("TextButton")
	setp(NG265, "Active", true)
	setp(NG265, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG265, "BackgroundTransparency", 0.44999998807907)
	setp(NG265, "BorderSizePixel", 0)
	setp(NG265, "Name", "Button")
	NG265.Selectable = true
	setp(NG265, "Size", UDim2.new(1, 0, 1, 0))
	NG265.Style = Enum.ButtonStyle.Custom
	setp(NG265, "Font", Enum.Font.ArialBold)
	setp(NG265, "FontSize", Enum.FontSize.Size10)
	setp(NG265, "Text", "REMOVE DECAL")
	setp(NG265, "TextColor3", Color3.new(1, 1, 1))
	setp(NG265, "TextStrokeTransparency", 0.80000001192093)
	setp(NG265, "Parent", NG264)
	NG266 = Instance.new("Frame")
	setp(NG266, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG266, "BackgroundTransparency", 0.30000001192093)
	setp(NG266, "BorderSizePixel", 0)
	setp(NG266, "Name", "Shadow")
	setp(NG266, "Position", UDim2.new(0, 0, 1, 0))
	setp(NG266, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG266, "ZIndex", 2)
	setp(NG266, "Parent", NG264)
	NG267 = Instance.new("TextLabel")
	setp(NG267, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG267, "BackgroundTransparency", 1)
	setp(NG267, "BorderSizePixel", 0)
	setp(NG267, "Name", "Text")
	setp(NG267, "Position", UDim2.new(0, 6, 1, 2))
	setp(NG267, "Size", UDim2.new(1, -6, 0, 20))
	setp(NG267, "Font", Enum.Font.ArialBold)
	setp(NG267, "FontSize", Enum.FontSize.Size10)
	setp(NG267, "Text", "TIP: Select a part & right click on a surface")
	setp(NG267, "TextColor3", Color3.new(1, 1, 1))
	setp(NG267, "TextStrokeTransparency", 0.5)
	setp(NG267, "TextWrapped", true)
	setp(NG267, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG267, "Parent", NG213)
	NG268 = Instance.new("Frame")
	setp(NG268, "Active", true)
	setp(NG268, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG268, "BackgroundTransparency", 1)
	setp(NG268, "BorderSizePixel", 0)
	setp(NG268, "Name", "BTWeldToolGUI")
	setp(NG268, "Position", UDim2.new(0, 0, 0, 280))
	setp(NG268, "Size", UDim2.new(0, 220, 0, 90))
	NG268.Draggable = true
	setp(NG268, "Parent", NG1)
	NG269 = Instance.new("Frame")
	setp(NG269, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG269, "BackgroundTransparency", 1)
	setp(NG269, "BorderSizePixel", 0)
	setp(NG269, "Name", "Title")
	setp(NG269, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG269, "Parent", NG268)
	NG270 = Instance.new("Frame")
	setp(NG270, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG270, "BorderSizePixel", 0)
	setp(NG270, "Name", "ColorBar")
	setp(NG270, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG270, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG270, "Parent", NG269)
	NG271 = Instance.new("TextLabel")
	setp(NG271, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG271, "BackgroundTransparency", 1)
	setp(NG271, "BorderSizePixel", 0)
	setp(NG271, "Name", "Label")
	setp(NG271, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG271, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG271, "Font", Enum.Font.ArialBold)
	setp(NG271, "FontSize", Enum.FontSize.Size10)
	setp(NG271, "Text", "WELD TOOL")
	setp(NG271, "TextColor3", Color3.new(1, 1, 1))
	setp(NG271, "TextStrokeTransparency", 0)
	setp(NG271, "TextWrapped", true)
	setp(NG271, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG271, "Parent", NG269)
	NG272 = Instance.new("TextLabel")
	setp(NG272, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG272, "BackgroundTransparency", 1)
	setp(NG272, "BorderSizePixel", 0)
	setp(NG272, "Name", "F3XSignature")
	setp(NG272, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG272, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG272, "Font", Enum.Font.ArialBold)
	setp(NG272, "FontSize", Enum.FontSize.Size14)
	setp(NG272, "Text", "F3X")
	setp(NG272, "TextColor3", Color3.new(1, 1, 1))
	setp(NG272, "TextStrokeTransparency", 0.89999997615814)
	setp(NG272, "TextWrapped", true)
	setp(NG272, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG272, "Parent", NG269)
	NG273 = Instance.new("Frame")
	setp(NG273, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG273, "BackgroundTransparency", 1)
	setp(NG273, "BorderSizePixel", 0)
	setp(NG273, "Name", "Interface")
	setp(NG273, "Position", UDim2.new(0, 10, 0, 30))
	setp(NG273, "Size", UDim2.new(1, -10, 0, 0))
	setp(NG273, "Parent", NG268)
	NG274 = Instance.new("TextButton")
	setp(NG274, "Active", true)
	setp(NG274, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG274, "BackgroundTransparency", 0.40000000596046)
	setp(NG274, "BorderSizePixel", 0)
	setp(NG274, "Name", "WeldButton")
	NG274.Selectable = true
	setp(NG274, "Size", UDim2.new(0.479999989, 0, 0, 25))
	NG274.Style = Enum.ButtonStyle.Custom
	setp(NG274, "Font", Enum.Font.ArialBold)
	setp(NG274, "FontSize", Enum.FontSize.Size10)
	setp(NG274, "Text", "WELD TO LAST")
	setp(NG274, "TextColor3", Color3.new(1, 1, 1))
	setp(NG274, "TextStrokeTransparency", 0.85000002384186)
	setp(NG274, "Parent", NG273)
	NG275 = Instance.new("Frame")
	setp(NG275, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG275, "BackgroundTransparency", 0.15000000596046)
	setp(NG275, "BorderSizePixel", 0)
	setp(NG275, "Name", "Shadow")
	setp(NG275, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG275, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG275, "Parent", NG274)
	NG276 = Instance.new("TextButton")
	setp(NG276, "Active", true)
	setp(NG276, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG276, "BackgroundTransparency", 0.40000000596046)
	setp(NG276, "BorderSizePixel", 0)
	setp(NG276, "Name", "BreakWeldsButton")
	setp(NG276, "Position", UDim2.new(0.519999981, 0, 0, 0))
	NG276.Selectable = true
	setp(NG276, "Size", UDim2.new(0.479999989, 0, 0, 25))
	NG276.Style = Enum.ButtonStyle.Custom
	setp(NG276, "Font", Enum.Font.ArialBold)
	setp(NG276, "FontSize", Enum.FontSize.Size10)
	setp(NG276, "Text", "BREAK WELDS")
	setp(NG276, "TextColor3", Color3.new(1, 1, 1))
	setp(NG276, "TextStrokeTransparency", 0.85000002384186)
	setp(NG276, "Parent", NG273)
	NG277 = Instance.new("Frame")
	setp(NG277, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG277, "BackgroundTransparency", 0.15000000596046)
	setp(NG277, "BorderSizePixel", 0)
	setp(NG277, "Name", "Shadow")
	setp(NG277, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG277, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG277, "Parent", NG276)
	NG278 = Instance.new("Frame")
	setp(NG278, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG278, "BackgroundTransparency", 1)
	setp(NG278, "BorderSizePixel", 0)
	setp(NG278, "Name", "Changes")
	setp(NG278, "Position", UDim2.new(0, 5, 0, 70))
	setp(NG278, "Size", UDim2.new(1, -5, 0, 20))
	setp(NG278, "Parent", NG268)
	NG279 = Instance.new("Frame")
	setp(NG279, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG279, "BorderSizePixel", 0)
	setp(NG279, "Name", "ColorBar")
	setp(NG279, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG279, "Parent", NG278)
	NG280 = Instance.new("TextLabel")
	setp(NG280, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG280, "BackgroundTransparency", 1)
	setp(NG280, "BorderSizePixel", 0)
	setp(NG280, "Name", "Text")
	setp(NG280, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG280, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG280, "Font", Enum.Font.ArialBold)
	setp(NG280, "FontSize", Enum.FontSize.Size10)
	setp(NG280, "Text", "")
	setp(NG280, "TextColor3", Color3.new(1, 1, 1))
	setp(NG280, "TextStrokeTransparency", 0.5)
	setp(NG280, "TextWrapped", true)
	setp(NG280, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG280, "Parent", NG278)
	NG281 = Instance.new("Frame")
	setp(NG281, "Active", true)
	setp(NG281, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG281, "BackgroundTransparency", 1)
	setp(NG281, "BorderSizePixel", 0)
	setp(NG281, "Name", "BTLightingToolGUI")
	setp(NG281, "Position", UDim2.new(0, 0, 0, 172))
	setp(NG281, "Size", UDim2.new(0, 200, 0, 95))
	NG281.Draggable = true
	setp(NG281, "Parent", NG1)
	NG282 = Instance.new("Frame")
	setp(NG282, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG282, "BorderSizePixel", 0)
	setp(NG282, "Name", "BottomColorBar")
	setp(NG282, "Position", UDim2.new(0, 5, 1, -2))
	setp(NG282, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG282, "Parent", NG281)
	NG283 = Instance.new("Frame")
	setp(NG283, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG283, "BackgroundTransparency", 1)
	setp(NG283, "BorderSizePixel", 0)
	setp(NG283, "Name", "Title")
	setp(NG283, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG283, "Parent", NG281)
	NG284 = Instance.new("Frame")
	setp(NG284, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG284, "BorderSizePixel", 0)
	setp(NG284, "Name", "ColorBar")
	setp(NG284, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG284, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG284, "Parent", NG283)
	NG285 = Instance.new("TextLabel")
	setp(NG285, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG285, "BackgroundTransparency", 1)
	setp(NG285, "BorderSizePixel", 0)
	setp(NG285, "Name", "Label")
	setp(NG285, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG285, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG285, "Font", Enum.Font.ArialBold)
	setp(NG285, "FontSize", Enum.FontSize.Size10)
	setp(NG285, "Text", "LIGHTING TOOL")
	setp(NG285, "TextColor3", Color3.new(1, 1, 1))
	setp(NG285, "TextStrokeTransparency", 0)
	setp(NG285, "TextWrapped", true)
	setp(NG285, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG285, "Parent", NG283)
	NG286 = Instance.new("TextLabel")
	setp(NG286, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG286, "BackgroundTransparency", 1)
	setp(NG286, "BorderSizePixel", 0)
	setp(NG286, "Name", "F3XSignature")
	setp(NG286, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG286, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG286, "Font", Enum.Font.ArialBold)
	setp(NG286, "FontSize", Enum.FontSize.Size14)
	setp(NG286, "Text", "F3X")
	setp(NG286, "TextColor3", Color3.new(1, 1, 1))
	setp(NG286, "TextStrokeTransparency", 0.89999997615814)
	setp(NG286, "TextWrapped", true)
	setp(NG286, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG286, "Parent", NG283)
	NG287 = Instance.new("Frame")
	setp(NG287, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG287, "BackgroundTransparency", 0.67500001192093)
	setp(NG287, "BorderSizePixel", 0)
	setp(NG287, "Name", "Spotlight")
	setp(NG287, "Position", UDim2.new(0, 10, 0, 30))
	setp(NG287, "Size", UDim2.new(1, -10, 0, 25))
	setp(NG287, "Parent", NG281)
	NG288 = Instance.new("TextLabel")
	setp(NG288, "BackgroundTransparency", 1)
	setp(NG288, "BorderSizePixel", 0)
	setp(NG288, "Name", "Label")
	setp(NG288, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG288, "Size", UDim2.new(0, 60, 0, 25))
	setp(NG288, "Font", Enum.Font.ArialBold)
	setp(NG288, "FontSize", Enum.FontSize.Size10)
	setp(NG288, "Text", "Spotlight")
	setp(NG288, "TextColor3", Color3.new(1, 1, 1))
	setp(NG288, "TextStrokeTransparency", 0.5)
	setp(NG288, "TextWrapped", true)
	setp(NG288, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG288, "Parent", NG287)
	NG289 = Instance.new("ImageButton")
	setp(NG289, "BackgroundTransparency", 1)
	setp(NG289, "BorderSizePixel", 0)
	setp(NG289, "Name", "ArrowButton")
	setp(NG289, "Position", UDim2.new(0, 10, 0, 3))
	setp(NG289, "Size", UDim2.new(0, 20, 0, 20))
	NG289.Style = Enum.ButtonStyle.Custom
	setp(NG289, "Image", "http://www.roblox.com/asset/?id=134367382")
	setp(NG289, "Parent", NG287)
	NG290 = Instance.new("Frame")
	setp(NG290, "BackgroundColor3", Color3.new(1, 0.682353, 0.235294))
	setp(NG290, "BorderSizePixel", 0)
	setp(NG290, "Name", "ColorBar")
	setp(NG290, "Size", UDim2.new(0, 3, 1, 0))
	setp(NG290, "Parent", NG287)
	NG291 = Instance.new("TextButton")
	setp(NG291, "Active", true)
	setp(NG291, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG291, "BackgroundTransparency", 0.75)
	setp(NG291, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG291, "BorderSizePixel", 0)
	setp(NG291, "Name", "AddButton")
	setp(NG291, "Position", UDim2.new(1, -40, 0, 3))
	NG291.Selectable = true
	setp(NG291, "Size", UDim2.new(0, 35, 0, 19))
	NG291.Style = Enum.ButtonStyle.Custom
	setp(NG291, "Font", Enum.Font.ArialBold)
	setp(NG291, "FontSize", Enum.FontSize.Size10)
	setp(NG291, "Text", "ADD")
	setp(NG291, "TextColor3", Color3.new(1, 1, 1))
	setp(NG291, "Parent", NG287)
	NG292 = Instance.new("TextButton")
	setp(NG292, "Active", true)
	setp(NG292, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG292, "BackgroundTransparency", 0.75)
	setp(NG292, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG292, "BorderSizePixel", 0)
	setp(NG292, "Name", "RemoveButton")
	setp(NG292, "Position", UDim2.new(0, 127, 0, 3))
	NG292.Selectable = true
	setp(NG292, "Size", UDim2.new(0, 58, 0, 19))
	NG292.Style = Enum.ButtonStyle.Custom
	setp(NG292, "Visible", false)
	setp(NG292, "Font", Enum.Font.ArialBold)
	setp(NG292, "FontSize", Enum.FontSize.Size10)
	setp(NG292, "Text", "REMOVE")
	setp(NG292, "TextColor3", Color3.new(1, 1, 1))
	setp(NG292, "Parent", NG287)
	NG293 = Instance.new("Frame")
	setp(NG293, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG293, "BackgroundTransparency", 0.75)
	setp(NG293, "BorderSizePixel", 0)
	setp(NG293, "Name", "Shadow")
	setp(NG293, "Position", UDim2.new(0, 0, 1, -1))
	setp(NG293, "Size", UDim2.new(1, 0, 0, 1))
	setp(NG293, "Parent", NG287)
	NG294 = Instance.new("Frame")
	setp(NG294, "BackgroundTransparency", 1)
	setp(NG294, "BorderSizePixel", 0)
	setp(NG294, "Name", "Options")
	setp(NG294, "Position", UDim2.new(0, 3, 1, 0))
	setp(NG294, "Size", UDim2.new(1, -3, 0, 0))
	setp(NG294, "ClipsDescendants", true)
	setp(NG294, "Parent", NG287)
	NG295 = Instance.new("Frame")
	setp(NG295, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG295, "BackgroundTransparency", 1)
	setp(NG295, "BorderSizePixel", 0)
	setp(NG295, "Name", "ColorOption")
	setp(NG295, "Position", UDim2.new(0, 0, 0, 10))
	setp(NG295, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG295, "Parent", NG294)
	NG296 = Instance.new("TextLabel")
	setp(NG296, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG296, "BackgroundTransparency", 1)
	setp(NG296, "BorderSizePixel", 0)
	setp(NG296, "Name", "Label")
	setp(NG296, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG296, "Font", Enum.Font.ArialBold)
	setp(NG296, "FontSize", Enum.FontSize.Size10)
	setp(NG296, "Text", "Color")
	setp(NG296, "TextColor3", Color3.new(1, 1, 1))
	setp(NG296, "TextStrokeTransparency", 0)
	setp(NG296, "TextWrapped", true)
	setp(NG296, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG296, "Parent", NG295)
	NG297 = Instance.new("Frame")
	setp(NG297, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG297, "BackgroundTransparency", 1)
	setp(NG297, "BorderSizePixel", 0)
	setp(NG297, "Name", "RInput")
	setp(NG297, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG297, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG297, "Parent", NG295)
	NG298 = Instance.new("TextButton")
	setp(NG298, "Active", true)
	setp(NG298, "AutoButtonColor", false)
	setp(NG298, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG298, "BackgroundTransparency", 1)
	setp(NG298, "BorderSizePixel", 0)
	NG298.Selectable = true
	setp(NG298, "Size", UDim2.new(1, 0, 1, 0))
	NG298.Style = Enum.ButtonStyle.Custom
	setp(NG298, "ZIndex", 2)
	setp(NG298, "Font", Enum.Font.Legacy)
	setp(NG298, "FontSize", Enum.FontSize.Size8)
	setp(NG298, "Text", "")
	setp(NG298, "Parent", NG297)
	NG299 = Instance.new("ImageLabel")
	setp(NG299, "Active", false)
	setp(NG299, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG299, "BackgroundTransparency", 1)
	setp(NG299, "BorderSizePixel", 0)
	setp(NG299, "Name", "Background")
	NG299.Selectable = false
	setp(NG299, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG299, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG299, "Parent", NG297)
	NG300 = Instance.new("Frame")
	setp(NG300, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG300, "BorderSizePixel", 0)
	setp(NG300, "Name", "SelectedIndicator")
	setp(NG300, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG300, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG300, "Parent", NG297)
	NG301 = Instance.new("TextBox")
	setp(NG301, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG301, "BackgroundTransparency", 1)
	setp(NG301, "BorderSizePixel", 0)
	setp(NG301, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG301, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG301, "Font", Enum.Font.ArialBold)
	setp(NG301, "FontSize", Enum.FontSize.Size10)
	setp(NG301, "Text", "255")
	setp(NG301, "TextColor3", Color3.new(1, 1, 1))
	setp(NG301, "Parent", NG297)
	NG302 = Instance.new("Frame")
	setp(NG302, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG302, "BackgroundTransparency", 1)
	setp(NG302, "BorderSizePixel", 0)
	setp(NG302, "Name", "GInput")
	setp(NG302, "Position", UDim2.new(0, 72, 0, 0))
	setp(NG302, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG302, "Parent", NG295)
	NG303 = Instance.new("TextButton")
	setp(NG303, "Active", true)
	setp(NG303, "AutoButtonColor", false)
	setp(NG303, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG303, "BackgroundTransparency", 1)
	setp(NG303, "BorderSizePixel", 0)
	NG303.Selectable = true
	setp(NG303, "Size", UDim2.new(1, 0, 1, 0))
	NG303.Style = Enum.ButtonStyle.Custom
	setp(NG303, "ZIndex", 2)
	setp(NG303, "Font", Enum.Font.Legacy)
	setp(NG303, "FontSize", Enum.FontSize.Size8)
	setp(NG303, "Text", "")
	setp(NG303, "Parent", NG302)
	NG304 = Instance.new("ImageLabel")
	setp(NG304, "Active", false)
	setp(NG304, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG304, "BackgroundTransparency", 1)
	setp(NG304, "BorderSizePixel", 0)
	setp(NG304, "Name", "Background")
	NG304.Selectable = false
	setp(NG304, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG304, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG304, "Parent", NG302)
	NG305 = Instance.new("Frame")
	setp(NG305, "BackgroundColor3", Color3.new(0, 1, 0))
	setp(NG305, "BorderSizePixel", 0)
	setp(NG305, "Name", "SelectedIndicator")
	setp(NG305, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG305, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG305, "Parent", NG302)
	NG306 = Instance.new("TextBox")
	setp(NG306, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG306, "BackgroundTransparency", 1)
	setp(NG306, "BorderSizePixel", 0)
	setp(NG306, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG306, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG306, "Font", Enum.Font.ArialBold)
	setp(NG306, "FontSize", Enum.FontSize.Size10)
	setp(NG306, "Text", "255")
	setp(NG306, "TextColor3", Color3.new(1, 1, 1))
	setp(NG306, "Parent", NG302)
	NG307 = Instance.new("Frame")
	setp(NG307, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG307, "BackgroundTransparency", 1)
	setp(NG307, "BorderSizePixel", 0)
	setp(NG307, "Name", "BInput")
	setp(NG307, "Position", UDim2.new(0, 109, 0, 0))
	setp(NG307, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG307, "Parent", NG295)
	NG308 = Instance.new("TextButton")
	setp(NG308, "Active", true)
	setp(NG308, "AutoButtonColor", false)
	setp(NG308, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG308, "BackgroundTransparency", 1)
	setp(NG308, "BorderSizePixel", 0)
	NG308.Selectable = true
	setp(NG308, "Size", UDim2.new(1, 0, 1, 0))
	NG308.Style = Enum.ButtonStyle.Custom
	setp(NG308, "ZIndex", 2)
	setp(NG308, "Font", Enum.Font.Legacy)
	setp(NG308, "FontSize", Enum.FontSize.Size8)
	setp(NG308, "Text", "")
	setp(NG308, "Parent", NG307)
	NG309 = Instance.new("ImageLabel")
	setp(NG309, "Active", false)
	setp(NG309, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG309, "BackgroundTransparency", 1)
	setp(NG309, "BorderSizePixel", 0)
	setp(NG309, "Name", "Background")
	NG309.Selectable = false
	setp(NG309, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG309, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG309, "Parent", NG307)
	NG310 = Instance.new("Frame")
	setp(NG310, "BackgroundColor3", Color3.new(0, 0, 1))
	setp(NG310, "BorderSizePixel", 0)
	setp(NG310, "Name", "SelectedIndicator")
	setp(NG310, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG310, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG310, "Parent", NG307)
	NG311 = Instance.new("TextBox")
	setp(NG311, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG311, "BackgroundTransparency", 1)
	setp(NG311, "BorderSizePixel", 0)
	setp(NG311, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG311, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG311, "Font", Enum.Font.ArialBold)
	setp(NG311, "FontSize", Enum.FontSize.Size10)
	setp(NG311, "Text", "255")
	setp(NG311, "TextColor3", Color3.new(1, 1, 1))
	setp(NG311, "Parent", NG307)
	NG312 = Instance.new("ImageButton")
	setp(NG312, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG312, "BackgroundTransparency", 0.40000000596046)
	setp(NG312, "BorderSizePixel", 0)
	setp(NG312, "Name", "HSVPicker")
	setp(NG312, "Position", UDim2.new(0, 160, 0, -2))
	setp(NG312, "Size", UDim2.new(0, 27, 0, 27))
	NG312.Style = Enum.ButtonStyle.Custom
	setp(NG312, "Image", "http://www.roblox.com/asset/?id=141313631")
	setp(NG312, "Parent", NG295)
	NG313 = Instance.new("Frame")
	setp(NG313, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG313, "BackgroundTransparency", 0.75)
	setp(NG313, "BorderSizePixel", 0)
	setp(NG313, "Name", "Shadow")
	setp(NG313, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG313, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG313, "Parent", NG312)
	NG314 = Instance.new("Frame")
	setp(NG314, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG314, "BackgroundTransparency", 0.5)
	setp(NG314, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG314, "BorderSizePixel", 0)
	setp(NG314, "Name", "Separator")
	setp(NG314, "Position", UDim2.new(0, 151, 0, 4))
	setp(NG314, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG314, "Parent", NG295)
	NG315 = Instance.new("Frame")
	setp(NG315, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG315, "BackgroundTransparency", 0.5)
	setp(NG315, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG315, "BorderSizePixel", 0)
	setp(NG315, "Name", "Separator")
	setp(NG315, "Position", UDim2.new(0, 151, 0, 16))
	setp(NG315, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG315, "Parent", NG295)
	NG316 = Instance.new("Frame")
	setp(NG316, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG316, "BackgroundTransparency", 0.5)
	setp(NG316, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG316, "BorderSizePixel", 0)
	setp(NG316, "Name", "Separator")
	setp(NG316, "Position", UDim2.new(0, 151, 0, 10))
	setp(NG316, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG316, "Parent", NG295)
	NG317 = Instance.new("Frame")
	setp(NG317, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG317, "BackgroundTransparency", 1)
	setp(NG317, "BorderSizePixel", 0)
	setp(NG317, "Name", "BrightnessOption")
	setp(NG317, "Position", UDim2.new(0, 0, 0, 45))
	setp(NG317, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG317, "Parent", NG294)
	NG318 = Instance.new("TextLabel")
	setp(NG318, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG318, "BackgroundTransparency", 1)
	setp(NG318, "BorderSizePixel", 0)
	setp(NG318, "Name", "Label")
	setp(NG318, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG318, "Font", Enum.Font.ArialBold)
	setp(NG318, "FontSize", Enum.FontSize.Size10)
	setp(NG318, "Text", "Brightness")
	setp(NG318, "TextColor3", Color3.new(1, 1, 1))
	setp(NG318, "TextStrokeTransparency", 0)
	setp(NG318, "TextWrapped", true)
	setp(NG318, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG318, "Parent", NG317)
	NG319 = Instance.new("Frame")
	setp(NG319, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG319, "BackgroundTransparency", 1)
	setp(NG319, "BorderSizePixel", 0)
	setp(NG319, "Name", "Input")
	setp(NG319, "Position", UDim2.new(0, 60, 0, 0))
	setp(NG319, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG319, "Parent", NG317)
	NG320 = Instance.new("TextButton")
	setp(NG320, "Active", true)
	setp(NG320, "AutoButtonColor", false)
	setp(NG320, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG320, "BackgroundTransparency", 1)
	setp(NG320, "BorderSizePixel", 0)
	NG320.Selectable = true
	setp(NG320, "Size", UDim2.new(1, 0, 1, 0))
	NG320.Style = Enum.ButtonStyle.Custom
	setp(NG320, "ZIndex", 2)
	setp(NG320, "Font", Enum.Font.Legacy)
	setp(NG320, "FontSize", Enum.FontSize.Size8)
	setp(NG320, "Text", "")
	setp(NG320, "Parent", NG319)
	NG321 = Instance.new("ImageLabel")
	setp(NG321, "Active", false)
	setp(NG321, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG321, "BackgroundTransparency", 1)
	setp(NG321, "BorderSizePixel", 0)
	setp(NG321, "Name", "Background")
	NG321.Selectable = false
	setp(NG321, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG321, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG321, "Parent", NG319)
	NG322 = Instance.new("Frame")
	setp(NG322, "BorderSizePixel", 0)
	setp(NG322, "Name", "SelectedIndicator")
	setp(NG322, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG322, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG322, "Parent", NG319)
	NG323 = Instance.new("TextBox")
	setp(NG323, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG323, "BackgroundTransparency", 1)
	setp(NG323, "BorderSizePixel", 0)
	setp(NG323, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG323, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG323, "Font", Enum.Font.ArialBold)
	setp(NG323, "FontSize", Enum.FontSize.Size10)
	setp(NG323, "Text", "1")
	setp(NG323, "TextColor3", Color3.new(1, 1, 1))
	setp(NG323, "Parent", NG319)
	NG324 = Instance.new("Frame")
	setp(NG324, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG324, "BackgroundTransparency", 1)
	setp(NG324, "BorderSizePixel", 0)
	setp(NG324, "Name", "AngleOption")
	setp(NG324, "Position", UDim2.new(0, 115, 0, 46))
	setp(NG324, "Size", UDim2.new(1, -115, 0, 25))
	setp(NG324, "Parent", NG294)
	NG325 = Instance.new("TextLabel")
	setp(NG325, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG325, "BackgroundTransparency", 1)
	setp(NG325, "BorderSizePixel", 0)
	setp(NG325, "Name", "Label")
	setp(NG325, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG325, "Font", Enum.Font.ArialBold)
	setp(NG325, "FontSize", Enum.FontSize.Size10)
	setp(NG325, "Text", "Angle")
	setp(NG325, "TextColor3", Color3.new(1, 1, 1))
	setp(NG325, "TextStrokeTransparency", 0)
	setp(NG325, "TextWrapped", true)
	setp(NG325, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG325, "Parent", NG324)
	NG326 = Instance.new("Frame")
	setp(NG326, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG326, "BackgroundTransparency", 1)
	setp(NG326, "BorderSizePixel", 0)
	setp(NG326, "Name", "Input")
	setp(NG326, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG326, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG326, "Parent", NG324)
	NG327 = Instance.new("TextButton")
	setp(NG327, "Active", true)
	setp(NG327, "AutoButtonColor", false)
	setp(NG327, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG327, "BackgroundTransparency", 1)
	setp(NG327, "BorderSizePixel", 0)
	NG327.Selectable = true
	setp(NG327, "Size", UDim2.new(1, 0, 1, 0))
	NG327.Style = Enum.ButtonStyle.Custom
	setp(NG327, "ZIndex", 2)
	setp(NG327, "Font", Enum.Font.Legacy)
	setp(NG327, "FontSize", Enum.FontSize.Size8)
	setp(NG327, "Text", "")
	setp(NG327, "Parent", NG326)
	NG328 = Instance.new("ImageLabel")
	setp(NG328, "Active", false)
	setp(NG328, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG328, "BackgroundTransparency", 1)
	setp(NG328, "BorderSizePixel", 0)
	setp(NG328, "Name", "Background")
	NG328.Selectable = false
	setp(NG328, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG328, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG328, "Parent", NG326)
	NG329 = Instance.new("Frame")
	setp(NG329, "BorderSizePixel", 0)
	setp(NG329, "Name", "SelectedIndicator")
	setp(NG329, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG329, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG329, "Parent", NG326)
	NG330 = Instance.new("TextBox")
	setp(NG330, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG330, "BackgroundTransparency", 1)
	setp(NG330, "BorderSizePixel", 0)
	setp(NG330, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG330, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG330, "Font", Enum.Font.ArialBold)
	setp(NG330, "FontSize", Enum.FontSize.Size10)
	setp(NG330, "Text", "90")
	setp(NG330, "TextColor3", Color3.new(1, 1, 1))
	setp(NG330, "Parent", NG326)
	NG331 = Instance.new("Frame")
	setp(NG331, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG331, "BackgroundTransparency", 1)
	setp(NG331, "BorderSizePixel", 0)
	setp(NG331, "Name", "RangeOption")
	setp(NG331, "Position", UDim2.new(0, 0, 0, 80))
	setp(NG331, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG331, "Parent", NG294)
	NG332 = Instance.new("TextLabel")
	setp(NG332, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG332, "BackgroundTransparency", 1)
	setp(NG332, "BorderSizePixel", 0)
	setp(NG332, "Name", "Label")
	setp(NG332, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG332, "Font", Enum.Font.ArialBold)
	setp(NG332, "FontSize", Enum.FontSize.Size10)
	setp(NG332, "Text", "Range")
	setp(NG332, "TextColor3", Color3.new(1, 1, 1))
	setp(NG332, "TextStrokeTransparency", 0)
	setp(NG332, "TextWrapped", true)
	setp(NG332, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG332, "Parent", NG331)
	NG333 = Instance.new("Frame")
	setp(NG333, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG333, "BackgroundTransparency", 1)
	setp(NG333, "BorderSizePixel", 0)
	setp(NG333, "Name", "Input")
	setp(NG333, "Position", UDim2.new(0, 40, 0, 0))
	setp(NG333, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG333, "Parent", NG331)
	NG334 = Instance.new("TextButton")
	setp(NG334, "Active", true)
	setp(NG334, "AutoButtonColor", false)
	setp(NG334, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG334, "BackgroundTransparency", 1)
	setp(NG334, "BorderSizePixel", 0)
	NG334.Selectable = true
	setp(NG334, "Size", UDim2.new(1, 0, 1, 0))
	NG334.Style = Enum.ButtonStyle.Custom
	setp(NG334, "ZIndex", 2)
	setp(NG334, "Font", Enum.Font.Legacy)
	setp(NG334, "FontSize", Enum.FontSize.Size8)
	setp(NG334, "Text", "")
	setp(NG334, "Parent", NG333)
	NG335 = Instance.new("ImageLabel")
	setp(NG335, "Active", false)
	setp(NG335, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG335, "BackgroundTransparency", 1)
	setp(NG335, "BorderSizePixel", 0)
	setp(NG335, "Name", "Background")
	NG335.Selectable = false
	setp(NG335, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG335, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG335, "Parent", NG333)
	NG336 = Instance.new("Frame")
	setp(NG336, "BorderSizePixel", 0)
	setp(NG336, "Name", "SelectedIndicator")
	setp(NG336, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG336, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG336, "Parent", NG333)
	NG337 = Instance.new("TextBox")
	setp(NG337, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG337, "BackgroundTransparency", 1)
	setp(NG337, "BorderSizePixel", 0)
	setp(NG337, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG337, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG337, "Font", Enum.Font.ArialBold)
	setp(NG337, "FontSize", Enum.FontSize.Size10)
	setp(NG337, "Text", "16")
	setp(NG337, "TextColor3", Color3.new(1, 1, 1))
	setp(NG337, "Parent", NG333)
	NG338 = Instance.new("Frame")
	setp(NG338, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG338, "BackgroundTransparency", 1)
	setp(NG338, "BorderSizePixel", 0)
	setp(NG338, "Name", "SideOption")
	setp(NG338, "Position", UDim2.new(0, 0, 0, 115))
	setp(NG338, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG338, "Parent", NG294)
	NG339 = Instance.new("TextLabel")
	setp(NG339, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG339, "BackgroundTransparency", 1)
	setp(NG339, "BorderSizePixel", 0)
	setp(NG339, "Name", "Label")
	setp(NG339, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG339, "Font", Enum.Font.ArialBold)
	setp(NG339, "FontSize", Enum.FontSize.Size10)
	setp(NG339, "Text", "Side")
	setp(NG339, "TextColor3", Color3.new(1, 1, 1))
	setp(NG339, "TextStrokeTransparency", 0)
	setp(NG339, "TextWrapped", true)
	setp(NG339, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG339, "Parent", NG338)
	NG340 = Instance.new("Frame")
	setp(NG340, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG340, "BackgroundTransparency", 1)
	setp(NG340, "BorderSizePixel", 0)
	setp(NG340, "Name", "ShadowsOption")
	setp(NG340, "Position", UDim2.new(0, 0, 0, 150))
	setp(NG340, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG340, "Parent", NG294)
	NG341 = Instance.new("TextLabel")
	setp(NG341, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG341, "BackgroundTransparency", 1)
	setp(NG341, "BorderSizePixel", 0)
	setp(NG341, "Name", "Label")
	setp(NG341, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG341, "Font", Enum.Font.ArialBold)
	setp(NG341, "FontSize", Enum.FontSize.Size10)
	setp(NG341, "Text", "Shadows")
	setp(NG341, "TextColor3", Color3.new(1, 1, 1))
	setp(NG341, "TextStrokeTransparency", 0)
	setp(NG341, "TextWrapped", true)
	setp(NG341, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG341, "Parent", NG340)
	NG342 = Instance.new("Frame")
	setp(NG342, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG342, "BackgroundTransparency", 1)
	setp(NG342, "BorderSizePixel", 0)
	setp(NG342, "Name", "On")
	setp(NG342, "Position", UDim2.new(0, 55, 0, 0))
	setp(NG342, "Size", UDim2.new(0, 45, 0, 25))
	setp(NG342, "Parent", NG340)
	NG343 = Instance.new("Frame")
	setp(NG343, "BackgroundTransparency", 1)
	setp(NG343, "BorderSizePixel", 0)
	setp(NG343, "Name", "SelectedIndicator")
	setp(NG343, "Position", UDim2.new(0, 4, 0, -2))
	setp(NG343, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG343, "Parent", NG342)
	NG344 = Instance.new("TextButton")
	setp(NG344, "Active", true)
	setp(NG344, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG344, "BackgroundTransparency", 1)
	setp(NG344, "BorderSizePixel", 0)
	setp(NG344, "Name", "Button")
	setp(NG344, "Position", UDim2.new(0, 5, 0, 0))
	NG344.Selectable = true
	setp(NG344, "Size", UDim2.new(1, -10, 1, 0))
	NG344.Style = Enum.ButtonStyle.Custom
	setp(NG344, "ZIndex", 2)
	setp(NG344, "Font", Enum.Font.Legacy)
	setp(NG344, "FontSize", Enum.FontSize.Size8)
	setp(NG344, "Text", "")
	NG344.TextTransparency = 1
	setp(NG344, "Parent", NG342)
	NG345 = Instance.new("ImageLabel")
	setp(NG345, "Active", false)
	setp(NG345, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG345, "BackgroundTransparency", 1)
	setp(NG345, "BorderSizePixel", 0)
	setp(NG345, "Name", "Background")
	NG345.Selectable = false
	setp(NG345, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG345, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG345, "Parent", NG342)
	NG346 = Instance.new("TextLabel")
	setp(NG346, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG346, "BackgroundTransparency", 1)
	setp(NG346, "BorderSizePixel", 0)
	setp(NG346, "Name", "Label")
	setp(NG346, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG346, "Font", Enum.Font.ArialBold)
	setp(NG346, "FontSize", Enum.FontSize.Size10)
	setp(NG346, "Text", "ON")
	setp(NG346, "TextColor3", Color3.new(1, 1, 1))
	setp(NG346, "Parent", NG342)
	NG347 = Instance.new("Frame")
	setp(NG347, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG347, "BackgroundTransparency", 1)
	setp(NG347, "BorderSizePixel", 0)
	setp(NG347, "Name", "Off")
	setp(NG347, "Position", UDim2.new(0, 100, 0, 0))
	setp(NG347, "Size", UDim2.new(0, 45, 0, 25))
	setp(NG347, "Parent", NG340)
	NG348 = Instance.new("Frame")
	setp(NG348, "BackgroundTransparency", 1)
	setp(NG348, "BorderSizePixel", 0)
	setp(NG348, "Name", "SelectedIndicator")
	setp(NG348, "Position", UDim2.new(0, 4, 0, -2))
	setp(NG348, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG348, "Parent", NG347)
	NG349 = Instance.new("TextButton")
	setp(NG349, "Active", true)
	setp(NG349, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG349, "BackgroundTransparency", 1)
	setp(NG349, "BorderSizePixel", 0)
	setp(NG349, "Name", "Button")
	setp(NG349, "Position", UDim2.new(0, 5, 0, 0))
	NG349.Selectable = true
	setp(NG349, "Size", UDim2.new(1, -10, 1, 0))
	NG349.Style = Enum.ButtonStyle.Custom
	setp(NG349, "ZIndex", 2)
	setp(NG349, "Font", Enum.Font.Legacy)
	setp(NG349, "FontSize", Enum.FontSize.Size8)
	setp(NG349, "Text", "")
	NG349.TextTransparency = 1
	setp(NG349, "Parent", NG347)
	NG350 = Instance.new("ImageLabel")
	setp(NG350, "Active", false)
	setp(NG350, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG350, "BackgroundTransparency", 1)
	setp(NG350, "BorderSizePixel", 0)
	setp(NG350, "Name", "Background")
	NG350.Selectable = false
	setp(NG350, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG350, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG350, "Parent", NG347)
	NG351 = Instance.new("TextLabel")
	setp(NG351, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG351, "BackgroundTransparency", 1)
	setp(NG351, "BorderSizePixel", 0)
	setp(NG351, "Name", "Label")
	setp(NG351, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG351, "Font", Enum.Font.ArialBold)
	setp(NG351, "FontSize", Enum.FontSize.Size10)
	setp(NG351, "Text", "OFF")
	setp(NG351, "TextColor3", Color3.new(1, 1, 1))
	setp(NG351, "Parent", NG347)
	NG352 = Instance.new("TextLabel")
	setp(NG352, "BackgroundTransparency", 1)
	setp(NG352, "BorderSizePixel", 0)
	setp(NG352, "Name", "SelectNote")
	setp(NG352, "Position", UDim2.new(0, 10, 0, 27))
	setp(NG352, "Size", UDim2.new(1, -10, 0, 15))
	setp(NG352, "Visible", false)
	setp(NG352, "FontSize", Enum.FontSize.Size14)
	setp(NG352, "Text", "Select something to use this tool.")
	setp(NG352, "TextColor3", Color3.new(1, 1, 1))
	setp(NG352, "TextScaled", true)
	setp(NG352, "TextStrokeTransparency", 0.5)
	setp(NG352, "TextWrapped", true)
	setp(NG352, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG352, "Parent", NG281)
	NG353 = Instance.new("Frame")
	setp(NG353, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG353, "BackgroundTransparency", 0.67500001192093)
	setp(NG353, "BorderSizePixel", 0)
	setp(NG353, "Name", "PointLight")
	setp(NG353, "Position", UDim2.new(0, 10, 0, 60))
	setp(NG353, "Size", UDim2.new(1, -10, 0, 25))
	setp(NG353, "Parent", NG281)
	NG354 = Instance.new("TextLabel")
	setp(NG354, "BackgroundTransparency", 1)
	setp(NG354, "BorderSizePixel", 0)
	setp(NG354, "Name", "Label")
	setp(NG354, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG354, "Size", UDim2.new(0, 60, 0, 25))
	setp(NG354, "Font", Enum.Font.ArialBold)
	setp(NG354, "FontSize", Enum.FontSize.Size10)
	setp(NG354, "Text", "Point light")
	setp(NG354, "TextColor3", Color3.new(1, 1, 1))
	setp(NG354, "TextStrokeTransparency", 0.5)
	setp(NG354, "TextWrapped", true)
	setp(NG354, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG354, "Parent", NG353)
	NG355 = Instance.new("ImageButton")
	setp(NG355, "BackgroundTransparency", 1)
	setp(NG355, "BorderSizePixel", 0)
	setp(NG355, "Name", "ArrowButton")
	setp(NG355, "Position", UDim2.new(0, 10, 0, 3))
	setp(NG355, "Size", UDim2.new(0, 20, 0, 20))
	NG355.Style = Enum.ButtonStyle.Custom
	setp(NG355, "Image", "http://www.roblox.com/asset/?id=134367382")
	setp(NG355, "Parent", NG353)
	NG356 = Instance.new("Frame")
	setp(NG356, "BackgroundColor3", Color3.new(0.85098, 0, 1))
	setp(NG356, "BorderSizePixel", 0)
	setp(NG356, "Name", "ColorBar")
	setp(NG356, "Size", UDim2.new(0, 3, 1, 0))
	setp(NG356, "Parent", NG353)
	NG357 = Instance.new("TextButton")
	setp(NG357, "Active", true)
	setp(NG357, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG357, "BackgroundTransparency", 0.75)
	setp(NG357, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG357, "BorderSizePixel", 0)
	setp(NG357, "Name", "AddButton")
	setp(NG357, "Position", UDim2.new(1, -40, 0, 3))
	NG357.Selectable = true
	setp(NG357, "Size", UDim2.new(0, 35, 0, 19))
	NG357.Style = Enum.ButtonStyle.Custom
	setp(NG357, "Font", Enum.Font.ArialBold)
	setp(NG357, "FontSize", Enum.FontSize.Size10)
	setp(NG357, "Text", "ADD")
	setp(NG357, "TextColor3", Color3.new(1, 1, 1))
	setp(NG357, "Parent", NG353)
	NG358 = Instance.new("TextButton")
	setp(NG358, "Active", true)
	setp(NG358, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG358, "BackgroundTransparency", 0.75)
	setp(NG358, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG358, "BorderSizePixel", 0)
	setp(NG358, "Name", "RemoveButton")
	setp(NG358, "Position", UDim2.new(0, 90, 0, 3))
	NG358.Selectable = true
	setp(NG358, "Size", UDim2.new(0, 58, 0, 19))
	NG358.Style = Enum.ButtonStyle.Custom
	setp(NG358, "Visible", false)
	setp(NG358, "Font", Enum.Font.ArialBold)
	setp(NG358, "FontSize", Enum.FontSize.Size10)
	setp(NG358, "Text", "REMOVE")
	setp(NG358, "TextColor3", Color3.new(1, 1, 1))
	setp(NG358, "Parent", NG353)
	NG359 = Instance.new("Frame")
	setp(NG359, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG359, "BackgroundTransparency", 0.75)
	setp(NG359, "BorderSizePixel", 0)
	setp(NG359, "Name", "Shadow")
	setp(NG359, "Position", UDim2.new(0, 0, 1, -1))
	setp(NG359, "Size", UDim2.new(1, 0, 0, 1))
	setp(NG359, "Parent", NG353)
	NG360 = Instance.new("Frame")
	setp(NG360, "BackgroundTransparency", 1)
	setp(NG360, "BorderSizePixel", 0)
	setp(NG360, "Name", "Options")
	setp(NG360, "Position", UDim2.new(0, 3, 1, 0))
	setp(NG360, "Size", UDim2.new(1, -3, 0, 0))
	setp(NG360, "ClipsDescendants", true)
	setp(NG360, "Parent", NG353)
	NG361 = Instance.new("Frame")
	setp(NG361, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG361, "BackgroundTransparency", 1)
	setp(NG361, "BorderSizePixel", 0)
	setp(NG361, "Name", "ColorOption")
	setp(NG361, "Position", UDim2.new(0, 0, 0, 10))
	setp(NG361, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG361, "Parent", NG360)
	NG362 = Instance.new("TextLabel")
	setp(NG362, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG362, "BackgroundTransparency", 1)
	setp(NG362, "BorderSizePixel", 0)
	setp(NG362, "Name", "Label")
	setp(NG362, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG362, "Font", Enum.Font.ArialBold)
	setp(NG362, "FontSize", Enum.FontSize.Size10)
	setp(NG362, "Text", "Color")
	setp(NG362, "TextColor3", Color3.new(1, 1, 1))
	setp(NG362, "TextStrokeTransparency", 0)
	setp(NG362, "TextWrapped", true)
	setp(NG362, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG362, "Parent", NG361)
	NG363 = Instance.new("Frame")
	setp(NG363, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG363, "BackgroundTransparency", 1)
	setp(NG363, "BorderSizePixel", 0)
	setp(NG363, "Name", "RInput")
	setp(NG363, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG363, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG363, "Parent", NG361)
	NG364 = Instance.new("TextButton")
	setp(NG364, "Active", true)
	setp(NG364, "AutoButtonColor", false)
	setp(NG364, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG364, "BackgroundTransparency", 1)
	setp(NG364, "BorderSizePixel", 0)
	NG364.Selectable = true
	setp(NG364, "Size", UDim2.new(1, 0, 1, 0))
	NG364.Style = Enum.ButtonStyle.Custom
	setp(NG364, "ZIndex", 2)
	setp(NG364, "Font", Enum.Font.Legacy)
	setp(NG364, "FontSize", Enum.FontSize.Size8)
	setp(NG364, "Text", "")
	setp(NG364, "Parent", NG363)
	NG365 = Instance.new("ImageLabel")
	setp(NG365, "Active", false)
	setp(NG365, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG365, "BackgroundTransparency", 1)
	setp(NG365, "BorderSizePixel", 0)
	setp(NG365, "Name", "Background")
	NG365.Selectable = false
	setp(NG365, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG365, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG365, "Parent", NG363)
	NG366 = Instance.new("Frame")
	setp(NG366, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG366, "BorderSizePixel", 0)
	setp(NG366, "Name", "SelectedIndicator")
	setp(NG366, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG366, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG366, "Parent", NG363)
	NG367 = Instance.new("TextBox")
	setp(NG367, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG367, "BackgroundTransparency", 1)
	setp(NG367, "BorderSizePixel", 0)
	setp(NG367, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG367, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG367, "Font", Enum.Font.ArialBold)
	setp(NG367, "FontSize", Enum.FontSize.Size10)
	setp(NG367, "Text", "255")
	setp(NG367, "TextColor3", Color3.new(1, 1, 1))
	setp(NG367, "Parent", NG363)
	NG368 = Instance.new("Frame")
	setp(NG368, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG368, "BackgroundTransparency", 1)
	setp(NG368, "BorderSizePixel", 0)
	setp(NG368, "Name", "GInput")
	setp(NG368, "Position", UDim2.new(0, 72, 0, 0))
	setp(NG368, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG368, "Parent", NG361)
	NG369 = Instance.new("TextButton")
	setp(NG369, "Active", true)
	setp(NG369, "AutoButtonColor", false)
	setp(NG369, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG369, "BackgroundTransparency", 1)
	setp(NG369, "BorderSizePixel", 0)
	NG369.Selectable = true
	setp(NG369, "Size", UDim2.new(1, 0, 1, 0))
	NG369.Style = Enum.ButtonStyle.Custom
	setp(NG369, "ZIndex", 2)
	setp(NG369, "Font", Enum.Font.Legacy)
	setp(NG369, "FontSize", Enum.FontSize.Size8)
	setp(NG369, "Text", "")
	setp(NG369, "Parent", NG368)
	NG370 = Instance.new("ImageLabel")
	setp(NG370, "Active", false)
	setp(NG370, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG370, "BackgroundTransparency", 1)
	setp(NG370, "BorderSizePixel", 0)
	setp(NG370, "Name", "Background")
	NG370.Selectable = false
	setp(NG370, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG370, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG370, "Parent", NG368)
	NG371 = Instance.new("Frame")
	setp(NG371, "BackgroundColor3", Color3.new(0, 1, 0))
	setp(NG371, "BorderSizePixel", 0)
	setp(NG371, "Name", "SelectedIndicator")
	setp(NG371, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG371, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG371, "Parent", NG368)
	NG372 = Instance.new("TextBox")
	setp(NG372, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG372, "BackgroundTransparency", 1)
	setp(NG372, "BorderSizePixel", 0)
	setp(NG372, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG372, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG372, "Font", Enum.Font.ArialBold)
	setp(NG372, "FontSize", Enum.FontSize.Size10)
	setp(NG372, "Text", "255")
	setp(NG372, "TextColor3", Color3.new(1, 1, 1))
	setp(NG372, "Parent", NG368)
	NG373 = Instance.new("Frame")
	setp(NG373, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG373, "BackgroundTransparency", 1)
	setp(NG373, "BorderSizePixel", 0)
	setp(NG373, "Name", "BInput")
	setp(NG373, "Position", UDim2.new(0, 109, 0, 0))
	setp(NG373, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG373, "Parent", NG361)
	NG374 = Instance.new("TextButton")
	setp(NG374, "Active", true)
	setp(NG374, "AutoButtonColor", false)
	setp(NG374, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG374, "BackgroundTransparency", 1)
	setp(NG374, "BorderSizePixel", 0)
	NG374.Selectable = true
	setp(NG374, "Size", UDim2.new(1, 0, 1, 0))
	NG374.Style = Enum.ButtonStyle.Custom
	setp(NG374, "ZIndex", 2)
	setp(NG374, "Font", Enum.Font.Legacy)
	setp(NG374, "FontSize", Enum.FontSize.Size8)
	setp(NG374, "Text", "")
	setp(NG374, "Parent", NG373)
	NG375 = Instance.new("ImageLabel")
	setp(NG375, "Active", false)
	setp(NG375, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG375, "BackgroundTransparency", 1)
	setp(NG375, "BorderSizePixel", 0)
	setp(NG375, "Name", "Background")
	NG375.Selectable = false
	setp(NG375, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG375, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG375, "Parent", NG373)
	NG376 = Instance.new("Frame")
	setp(NG376, "BackgroundColor3", Color3.new(0, 0, 1))
	setp(NG376, "BorderSizePixel", 0)
	setp(NG376, "Name", "SelectedIndicator")
	setp(NG376, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG376, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG376, "Parent", NG373)
	NG377 = Instance.new("TextBox")
	setp(NG377, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG377, "BackgroundTransparency", 1)
	setp(NG377, "BorderSizePixel", 0)
	setp(NG377, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG377, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG377, "Font", Enum.Font.ArialBold)
	setp(NG377, "FontSize", Enum.FontSize.Size10)
	setp(NG377, "Text", "255")
	setp(NG377, "TextColor3", Color3.new(1, 1, 1))
	setp(NG377, "Parent", NG373)
	NG378 = Instance.new("ImageButton")
	setp(NG378, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG378, "BackgroundTransparency", 0.40000000596046)
	setp(NG378, "BorderSizePixel", 0)
	setp(NG378, "Name", "HSVPicker")
	setp(NG378, "Position", UDim2.new(0, 160, 0, -2))
	setp(NG378, "Size", UDim2.new(0, 27, 0, 27))
	NG378.Style = Enum.ButtonStyle.Custom
	setp(NG378, "ZIndex", 2)
	setp(NG378, "Image", "http://www.roblox.com/asset/?id=141313631")
	setp(NG378, "Parent", NG361)
	NG379 = Instance.new("Frame")
	setp(NG379, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG379, "BackgroundTransparency", 0.75)
	setp(NG379, "BorderSizePixel", 0)
	setp(NG379, "Name", "Shadow")
	setp(NG379, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG379, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG379, "Parent", NG378)
	NG380 = Instance.new("Frame")
	setp(NG380, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG380, "BackgroundTransparency", 0.5)
	setp(NG380, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG380, "BorderSizePixel", 0)
	setp(NG380, "Name", "Separator")
	setp(NG380, "Position", UDim2.new(0, 151, 0, 4))
	setp(NG380, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG380, "Parent", NG361)
	NG381 = Instance.new("Frame")
	setp(NG381, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG381, "BackgroundTransparency", 0.5)
	setp(NG381, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG381, "BorderSizePixel", 0)
	setp(NG381, "Name", "Separator")
	setp(NG381, "Position", UDim2.new(0, 151, 0, 16))
	setp(NG381, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG381, "Parent", NG361)
	NG382 = Instance.new("Frame")
	setp(NG382, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG382, "BackgroundTransparency", 0.5)
	setp(NG382, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG382, "BorderSizePixel", 0)
	setp(NG382, "Name", "Separator")
	setp(NG382, "Position", UDim2.new(0, 151, 0, 10))
	setp(NG382, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG382, "Parent", NG361)
	NG383 = Instance.new("Frame")
	setp(NG383, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG383, "BackgroundTransparency", 1)
	setp(NG383, "BorderSizePixel", 0)
	setp(NG383, "Name", "BrightnessOption")
	setp(NG383, "Position", UDim2.new(0, 0, 0, 45))
	setp(NG383, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG383, "Parent", NG360)
	NG384 = Instance.new("TextLabel")
	setp(NG384, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG384, "BackgroundTransparency", 1)
	setp(NG384, "BorderSizePixel", 0)
	setp(NG384, "Name", "Label")
	setp(NG384, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG384, "Font", Enum.Font.ArialBold)
	setp(NG384, "FontSize", Enum.FontSize.Size10)
	setp(NG384, "Text", "Brightness")
	setp(NG384, "TextColor3", Color3.new(1, 1, 1))
	setp(NG384, "TextStrokeTransparency", 0)
	setp(NG384, "TextWrapped", true)
	setp(NG384, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG384, "Parent", NG383)
	NG385 = Instance.new("Frame")
	setp(NG385, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG385, "BackgroundTransparency", 1)
	setp(NG385, "BorderSizePixel", 0)
	setp(NG385, "Name", "Input")
	setp(NG385, "Position", UDim2.new(0, 60, 0, 0))
	setp(NG385, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG385, "Parent", NG383)
	NG386 = Instance.new("TextButton")
	setp(NG386, "Active", true)
	setp(NG386, "AutoButtonColor", false)
	setp(NG386, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG386, "BackgroundTransparency", 1)
	setp(NG386, "BorderSizePixel", 0)
	NG386.Selectable = true
	setp(NG386, "Size", UDim2.new(1, 0, 1, 0))
	NG386.Style = Enum.ButtonStyle.Custom
	setp(NG386, "ZIndex", 2)
	setp(NG386, "Font", Enum.Font.Legacy)
	setp(NG386, "FontSize", Enum.FontSize.Size8)
	setp(NG386, "Text", "")
	setp(NG386, "Parent", NG385)
	NG387 = Instance.new("ImageLabel")
	setp(NG387, "Active", false)
	setp(NG387, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG387, "BackgroundTransparency", 1)
	setp(NG387, "BorderSizePixel", 0)
	setp(NG387, "Name", "Background")
	NG387.Selectable = false
	setp(NG387, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG387, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG387, "Parent", NG385)
	NG388 = Instance.new("Frame")
	setp(NG388, "BorderSizePixel", 0)
	setp(NG388, "Name", "SelectedIndicator")
	setp(NG388, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG388, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG388, "Parent", NG385)
	NG389 = Instance.new("TextBox")
	setp(NG389, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG389, "BackgroundTransparency", 1)
	setp(NG389, "BorderSizePixel", 0)
	setp(NG389, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG389, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG389, "Font", Enum.Font.ArialBold)
	setp(NG389, "FontSize", Enum.FontSize.Size10)
	setp(NG389, "Text", "1")
	setp(NG389, "TextColor3", Color3.new(1, 1, 1))
	setp(NG389, "Parent", NG385)
	NG390 = Instance.new("Frame")
	setp(NG390, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG390, "BackgroundTransparency", 1)
	setp(NG390, "BorderSizePixel", 0)
	setp(NG390, "Name", "RangeOption")
	setp(NG390, "Position", UDim2.new(0, 110, 0, 45))
	setp(NG390, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG390, "Parent", NG360)
	NG391 = Instance.new("TextLabel")
	setp(NG391, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG391, "BackgroundTransparency", 1)
	setp(NG391, "BorderSizePixel", 0)
	setp(NG391, "Name", "Label")
	setp(NG391, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG391, "Font", Enum.Font.ArialBold)
	setp(NG391, "FontSize", Enum.FontSize.Size10)
	setp(NG391, "Text", "Range")
	setp(NG391, "TextColor3", Color3.new(1, 1, 1))
	setp(NG391, "TextStrokeTransparency", 0)
	setp(NG391, "TextWrapped", true)
	setp(NG391, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG391, "Parent", NG390)
	NG392 = Instance.new("Frame")
	setp(NG392, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG392, "BackgroundTransparency", 1)
	setp(NG392, "BorderSizePixel", 0)
	setp(NG392, "Name", "Input")
	setp(NG392, "Position", UDim2.new(0, 40, 0, 0))
	setp(NG392, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG392, "Parent", NG390)
	NG393 = Instance.new("TextButton")
	setp(NG393, "Active", true)
	setp(NG393, "AutoButtonColor", false)
	setp(NG393, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG393, "BackgroundTransparency", 1)
	setp(NG393, "BorderSizePixel", 0)
	NG393.Selectable = true
	setp(NG393, "Size", UDim2.new(1, 0, 1, 0))
	NG393.Style = Enum.ButtonStyle.Custom
	setp(NG393, "ZIndex", 2)
	setp(NG393, "Font", Enum.Font.Legacy)
	setp(NG393, "FontSize", Enum.FontSize.Size8)
	setp(NG393, "Text", "")
	setp(NG393, "Parent", NG392)
	NG394 = Instance.new("ImageLabel")
	setp(NG394, "Active", false)
	setp(NG394, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG394, "BackgroundTransparency", 1)
	setp(NG394, "BorderSizePixel", 0)
	setp(NG394, "Name", "Background")
	NG394.Selectable = false
	setp(NG394, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG394, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG394, "Parent", NG392)
	NG395 = Instance.new("Frame")
	setp(NG395, "BorderSizePixel", 0)
	setp(NG395, "Name", "SelectedIndicator")
	setp(NG395, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG395, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG395, "Parent", NG392)
	NG396 = Instance.new("TextBox")
	setp(NG396, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG396, "BackgroundTransparency", 1)
	setp(NG396, "BorderSizePixel", 0)
	setp(NG396, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG396, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG396, "Font", Enum.Font.ArialBold)
	setp(NG396, "FontSize", Enum.FontSize.Size10)
	setp(NG396, "Text", "16")
	setp(NG396, "TextColor3", Color3.new(1, 1, 1))
	setp(NG396, "Parent", NG392)
	NG397 = Instance.new("Frame")
	setp(NG397, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG397, "BackgroundTransparency", 1)
	setp(NG397, "BorderSizePixel", 0)
	setp(NG397, "Name", "ShadowsOption")
	setp(NG397, "Position", UDim2.new(0, 0, 0, 80))
	setp(NG397, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG397, "Parent", NG360)
	NG398 = Instance.new("TextLabel")
	setp(NG398, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG398, "BackgroundTransparency", 1)
	setp(NG398, "BorderSizePixel", 0)
	setp(NG398, "Name", "Label")
	setp(NG398, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG398, "Font", Enum.Font.ArialBold)
	setp(NG398, "FontSize", Enum.FontSize.Size10)
	setp(NG398, "Text", "Shadows")
	setp(NG398, "TextColor3", Color3.new(1, 1, 1))
	setp(NG398, "TextStrokeTransparency", 0)
	setp(NG398, "TextWrapped", true)
	setp(NG398, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG398, "Parent", NG397)
	NG399 = Instance.new("Frame")
	setp(NG399, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG399, "BackgroundTransparency", 1)
	setp(NG399, "BorderSizePixel", 0)
	setp(NG399, "Name", "On")
	setp(NG399, "Position", UDim2.new(0, 55, 0, 0))
	setp(NG399, "Size", UDim2.new(0, 45, 0, 25))
	setp(NG399, "Parent", NG397)
	NG400 = Instance.new("Frame")
	setp(NG400, "BackgroundTransparency", 1)
	setp(NG400, "BorderSizePixel", 0)
	setp(NG400, "Name", "SelectedIndicator")
	setp(NG400, "Position", UDim2.new(0, 4, 0, -2))
	setp(NG400, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG400, "Parent", NG399)
	NG401 = Instance.new("TextButton")
	setp(NG401, "Active", true)
	setp(NG401, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG401, "BackgroundTransparency", 1)
	setp(NG401, "BorderSizePixel", 0)
	setp(NG401, "Name", "Button")
	setp(NG401, "Position", UDim2.new(0, 5, 0, 0))
	NG401.Selectable = true
	setp(NG401, "Size", UDim2.new(1, -10, 1, 0))
	NG401.Style = Enum.ButtonStyle.Custom
	setp(NG401, "ZIndex", 2)
	setp(NG401, "Font", Enum.Font.Legacy)
	setp(NG401, "FontSize", Enum.FontSize.Size8)
	setp(NG401, "Text", "")
	NG401.TextTransparency = 1
	setp(NG401, "Parent", NG399)
	NG402 = Instance.new("ImageLabel")
	setp(NG402, "Active", false)
	setp(NG402, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG402, "BackgroundTransparency", 1)
	setp(NG402, "BorderSizePixel", 0)
	setp(NG402, "Name", "Background")
	NG402.Selectable = false
	setp(NG402, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG402, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG402, "Parent", NG399)
	NG403 = Instance.new("TextLabel")
	setp(NG403, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG403, "BackgroundTransparency", 1)
	setp(NG403, "BorderSizePixel", 0)
	setp(NG403, "Name", "Label")
	setp(NG403, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG403, "Font", Enum.Font.ArialBold)
	setp(NG403, "FontSize", Enum.FontSize.Size10)
	setp(NG403, "Text", "ON")
	setp(NG403, "TextColor3", Color3.new(1, 1, 1))
	setp(NG403, "Parent", NG399)
	NG404 = Instance.new("Frame")
	setp(NG404, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG404, "BackgroundTransparency", 1)
	setp(NG404, "BorderSizePixel", 0)
	setp(NG404, "Name", "Off")
	setp(NG404, "Position", UDim2.new(0, 100, 0, 0))
	setp(NG404, "Size", UDim2.new(0, 45, 0, 25))
	setp(NG404, "Parent", NG397)
	NG405 = Instance.new("Frame")
	setp(NG405, "BackgroundTransparency", 1)
	setp(NG405, "BorderSizePixel", 0)
	setp(NG405, "Name", "SelectedIndicator")
	setp(NG405, "Position", UDim2.new(0, 4, 0, -2))
	setp(NG405, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG405, "Parent", NG404)
	NG406 = Instance.new("TextButton")
	setp(NG406, "Active", true)
	setp(NG406, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG406, "BackgroundTransparency", 1)
	setp(NG406, "BorderSizePixel", 0)
	setp(NG406, "Name", "Button")
	setp(NG406, "Position", UDim2.new(0, 5, 0, 0))
	NG406.Selectable = true
	setp(NG406, "Size", UDim2.new(1, -10, 1, 0))
	NG406.Style = Enum.ButtonStyle.Custom
	setp(NG406, "ZIndex", 2)
	setp(NG406, "Font", Enum.Font.Legacy)
	setp(NG406, "FontSize", Enum.FontSize.Size8)
	setp(NG406, "Text", "")
	NG406.TextTransparency = 1
	setp(NG406, "Parent", NG404)
	NG407 = Instance.new("ImageLabel")
	setp(NG407, "Active", false)
	setp(NG407, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG407, "BackgroundTransparency", 1)
	setp(NG407, "BorderSizePixel", 0)
	setp(NG407, "Name", "Background")
	NG407.Selectable = false
	setp(NG407, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG407, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG407, "Parent", NG404)
	NG408 = Instance.new("TextLabel")
	setp(NG408, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG408, "BackgroundTransparency", 1)
	setp(NG408, "BorderSizePixel", 0)
	setp(NG408, "Name", "Label")
	setp(NG408, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG408, "Font", Enum.Font.ArialBold)
	setp(NG408, "FontSize", Enum.FontSize.Size10)
	setp(NG408, "Text", "OFF")
	setp(NG408, "TextColor3", Color3.new(1, 1, 1))
	setp(NG408, "Parent", NG404)
	NG409 = Instance.new("Frame")
	setp(NG409, "Active", true)
	setp(NG409, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG409, "BackgroundTransparency", 0.89999997615814)
	setp(NG409, "BorderSizePixel", 0)
	setp(NG409, "Name", "BTHSVColorPicker")
	setp(NG409, "Position", UDim2.new(0, 220, 0, 116))
	setp(NG409, "Size", UDim2.new(0, 250, 0, 380))
	NG409.Draggable = true
	setp(NG409, "Parent", NG1)
	NG410 = Instance.new("ImageButton")
	setp(NG410, "BorderColor3", Color3.new(0.207843, 0.207843, 0.207843))
	setp(NG410, "Name", "HueSaturation")
	setp(NG410, "Position", UDim2.new(0, 10, 0, 10))
	setp(NG410, "Size", UDim2.new(0, 209, 0, 200))
	NG410.Style = Enum.ButtonStyle.Custom
	setp(NG410, "Image", "http://www.roblox.com/asset?id=141066192")
	setp(NG410, "Parent", NG409)
	NG411 = Instance.new("ImageLabel")
	setp(NG411, "Active", false)
	setp(NG411, "BackgroundTransparency", 1)
	setp(NG411, "BorderSizePixel", 0)
	setp(NG411, "Name", "Cursor")
	setp(NG411, "Position", UDim2.new(0, -8, 0, 194))
	NG411.Selectable = false
	setp(NG411, "Size", UDim2.new(0, 16, 0, 16))
	setp(NG411, "Image", "http://www.roblox.com/asset/?id=141186650")
	setp(NG411, "Parent", NG410)
	NG412 = Instance.new("ImageButton")
	setp(NG412, "BackgroundTransparency", 1)
	setp(NG412, "BorderColor3", Color3.new(0.207843, 0.207843, 0.207843))
	setp(NG412, "BorderSizePixel", 0)
	setp(NG412, "Name", "Value")
	setp(NG412, "Position", UDim2.new(0, 229, 0, 10))
	setp(NG412, "Size", UDim2.new(0, 13, 0, 200))
	NG412.Style = Enum.ButtonStyle.Custom
	setp(NG412, "ZIndex", 2)
	setp(NG412, "Image", "http://www.roblox.com/asset/?id=141066196")
	setp(NG412, "Parent", NG409)
	NG413 = Instance.new("Frame")
	setp(NG413, "BorderSizePixel", 0)
	setp(NG413, "Name", "ColorBG")
	setp(NG413, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG413, "Parent", NG412)
	NG414 = Instance.new("ImageLabel")
	setp(NG414, "Active", false)
	setp(NG414, "BackgroundTransparency", 1)
	setp(NG414, "BorderSizePixel", 0)
	setp(NG414, "Name", "Cursor")
	setp(NG414, "Position", UDim2.new(0, -2, 0, -8))
	NG414.Selectable = false
	setp(NG414, "Size", UDim2.new(0, 16, 0, 16))
	setp(NG414, "ZIndex", 2)
	setp(NG414, "Image", "http://www.roblox.com/asset/?id=141186650")
	setp(NG414, "Parent", NG412)
	NG415 = Instance.new("Frame")
	setp(NG415, "BackgroundTransparency", 1)
	setp(NG415, "BorderSizePixel", 0)
	setp(NG415, "Name", "HueOption")
	setp(NG415, "Position", UDim2.new(0, 10, 0, 218))
	setp(NG415, "Size", UDim2.new(1, -25, 0, 34))
	setp(NG415, "Parent", NG409)
	NG416 = Instance.new("TextLabel")
	setp(NG416, "BackgroundTransparency", 1)
	setp(NG416, "BorderSizePixel", 0)
	setp(NG416, "Name", "Label")
	setp(NG416, "Position", UDim2.new(0, 15, 0, 0))
	setp(NG416, "Size", UDim2.new(0, 100, 1, 0))
	setp(NG416, "Font", Enum.Font.SourceSansBold)
	setp(NG416, "FontSize", Enum.FontSize.Size18)
	setp(NG416, "Text", "Hue")
	setp(NG416, "TextColor3", Color3.new(1, 1, 1))
	setp(NG416, "TextStrokeTransparency", 0.5)
	setp(NG416, "TextWrapped", true)
	setp(NG416, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG416, "Parent", NG415)
	NG417 = Instance.new("Frame")
	setp(NG417, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG417, "BackgroundTransparency", 1)
	setp(NG417, "BorderSizePixel", 0)
	setp(NG417, "Name", "Input")
	setp(NG417, "Position", UDim2.new(0, 55, 0, 4))
	setp(NG417, "Size", UDim2.new(0, 50, 0, 26))
	setp(NG417, "Parent", NG415)
	NG418 = Instance.new("TextButton")
	setp(NG418, "Active", true)
	setp(NG418, "AutoButtonColor", false)
	setp(NG418, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG418, "BackgroundTransparency", 1)
	setp(NG418, "BorderSizePixel", 0)
	NG418.Selectable = true
	setp(NG418, "Size", UDim2.new(1, 0, 1, 0))
	NG418.Style = Enum.ButtonStyle.Custom
	setp(NG418, "ZIndex", 2)
	setp(NG418, "Font", Enum.Font.Legacy)
	setp(NG418, "FontSize", Enum.FontSize.Size8)
	setp(NG418, "Text", "")
	setp(NG418, "Parent", NG417)
	NG419 = Instance.new("ImageLabel")
	setp(NG419, "Active", false)
	setp(NG419, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG419, "BackgroundTransparency", 1)
	setp(NG419, "BorderSizePixel", 0)
	setp(NG419, "Name", "Background")
	NG419.Selectable = false
	setp(NG419, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG419, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG419, "Parent", NG417)
	NG420 = Instance.new("TextBox")
	setp(NG420, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG420, "BackgroundTransparency", 1)
	setp(NG420, "BorderSizePixel", 0)
	setp(NG420, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG420, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG420, "Font", Enum.Font.ArialBold)
	setp(NG420, "FontSize", Enum.FontSize.Size10)
	setp(NG420, "Text", "360")
	setp(NG420, "TextColor3", Color3.new(1, 1, 1))
	setp(NG420, "Parent", NG417)
	NG421 = Instance.new("Frame")
	setp(NG421, "BorderSizePixel", 0)
	setp(NG421, "Name", "Bar")
	setp(NG421, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG421, "Size", UDim2.new(0, 3, 1, -4))
	setp(NG421, "Parent", NG415)
	NG422 = Instance.new("Frame")
	setp(NG422, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG422, "BackgroundTransparency", 0.89999997615814)
	setp(NG422, "BorderSizePixel", 0)
	setp(NG422, "Name", "Shadow")
	setp(NG422, "Position", UDim2.new(0, 0, 1, -3))
	setp(NG422, "Size", UDim2.new(1, 0, 0, 3))
	setp(NG422, "Parent", NG421)
	NG423 = Instance.new("Frame")
	setp(NG423, "BackgroundTransparency", 1)
	setp(NG423, "BorderSizePixel", 0)
	setp(NG423, "Name", "SaturationOption")
	setp(NG423, "Position", UDim2.new(0, 10, 0, 255))
	setp(NG423, "Size", UDim2.new(1, -25, 0, 34))
	setp(NG423, "Parent", NG409)
	NG424 = Instance.new("TextLabel")
	setp(NG424, "BackgroundTransparency", 1)
	setp(NG424, "BorderSizePixel", 0)
	setp(NG424, "Name", "Label")
	setp(NG424, "Position", UDim2.new(0, 15, 0, 0))
	setp(NG424, "Size", UDim2.new(0, 100, 1, 0))
	setp(NG424, "Font", Enum.Font.SourceSansBold)
	setp(NG424, "FontSize", Enum.FontSize.Size18)
	setp(NG424, "Text", "Saturation")
	setp(NG424, "TextColor3", Color3.new(1, 1, 1))
	setp(NG424, "TextStrokeTransparency", 0.5)
	setp(NG424, "TextWrapped", true)
	setp(NG424, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG424, "Parent", NG423)
	NG425 = Instance.new("Frame")
	setp(NG425, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG425, "BackgroundTransparency", 1)
	setp(NG425, "BorderSizePixel", 0)
	setp(NG425, "Name", "Input")
	setp(NG425, "Position", UDim2.new(0, 100, 0, 4))
	setp(NG425, "Size", UDim2.new(0, 50, 0, 26))
	setp(NG425, "Parent", NG423)
	NG426 = Instance.new("TextButton")
	setp(NG426, "Active", true)
	setp(NG426, "AutoButtonColor", false)
	setp(NG426, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG426, "BackgroundTransparency", 1)
	setp(NG426, "BorderSizePixel", 0)
	NG426.Selectable = true
	setp(NG426, "Size", UDim2.new(1, 0, 1, 0))
	NG426.Style = Enum.ButtonStyle.Custom
	setp(NG426, "ZIndex", 2)
	setp(NG426, "Font", Enum.Font.Legacy)
	setp(NG426, "FontSize", Enum.FontSize.Size8)
	setp(NG426, "Text", "")
	setp(NG426, "Parent", NG425)
	NG427 = Instance.new("ImageLabel")
	setp(NG427, "Active", false)
	setp(NG427, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG427, "BackgroundTransparency", 1)
	setp(NG427, "BorderSizePixel", 0)
	setp(NG427, "Name", "Background")
	NG427.Selectable = false
	setp(NG427, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG427, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG427, "Parent", NG425)
	NG428 = Instance.new("TextBox")
	setp(NG428, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG428, "BackgroundTransparency", 1)
	setp(NG428, "BorderSizePixel", 0)
	setp(NG428, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG428, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG428, "Font", Enum.Font.ArialBold)
	setp(NG428, "FontSize", Enum.FontSize.Size10)
	setp(NG428, "Text", "100%")
	setp(NG428, "TextColor3", Color3.new(1, 1, 1))
	setp(NG428, "Parent", NG425)
	NG429 = Instance.new("Frame")
	setp(NG429, "BorderSizePixel", 0)
	setp(NG429, "Name", "Bar")
	setp(NG429, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG429, "Size", UDim2.new(0, 3, 1, -4))
	setp(NG429, "Parent", NG423)
	NG430 = Instance.new("Frame")
	setp(NG430, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG430, "BackgroundTransparency", 0.89999997615814)
	setp(NG430, "BorderSizePixel", 0)
	setp(NG430, "Name", "Shadow")
	setp(NG430, "Position", UDim2.new(0, 0, 1, -3))
	setp(NG430, "Size", UDim2.new(1, 0, 0, 3))
	setp(NG430, "Parent", NG429)
	NG431 = Instance.new("Frame")
	setp(NG431, "BackgroundTransparency", 1)
	setp(NG431, "BorderSizePixel", 0)
	setp(NG431, "Name", "ValueOption")
	setp(NG431, "Position", UDim2.new(0, 10, 0, 292))
	setp(NG431, "Size", UDim2.new(1, -25, 0, 34))
	setp(NG431, "Parent", NG409)
	NG432 = Instance.new("TextLabel")
	setp(NG432, "BackgroundTransparency", 1)
	setp(NG432, "BorderSizePixel", 0)
	setp(NG432, "Name", "Label")
	setp(NG432, "Position", UDim2.new(0, 15, 0, 0))
	setp(NG432, "Size", UDim2.new(0, 100, 1, 0))
	setp(NG432, "Font", Enum.Font.SourceSansBold)
	setp(NG432, "FontSize", Enum.FontSize.Size18)
	setp(NG432, "Text", "Brightness")
	setp(NG432, "TextColor3", Color3.new(1, 1, 1))
	setp(NG432, "TextStrokeTransparency", 0.5)
	setp(NG432, "TextWrapped", true)
	setp(NG432, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG432, "Parent", NG431)
	NG433 = Instance.new("Frame")
	setp(NG433, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG433, "BackgroundTransparency", 1)
	setp(NG433, "BorderSizePixel", 0)
	setp(NG433, "Name", "Input")
	setp(NG433, "Position", UDim2.new(0, 100, 0, 4))
	setp(NG433, "Size", UDim2.new(0, 50, 0, 26))
	setp(NG433, "Parent", NG431)
	NG434 = Instance.new("TextButton")
	setp(NG434, "Active", true)
	setp(NG434, "AutoButtonColor", false)
	setp(NG434, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG434, "BackgroundTransparency", 1)
	setp(NG434, "BorderSizePixel", 0)
	NG434.Selectable = true
	setp(NG434, "Size", UDim2.new(1, 0, 1, 0))
	NG434.Style = Enum.ButtonStyle.Custom
	setp(NG434, "ZIndex", 2)
	setp(NG434, "Font", Enum.Font.Legacy)
	setp(NG434, "FontSize", Enum.FontSize.Size8)
	setp(NG434, "Text", "")
	setp(NG434, "Parent", NG433)
	NG435 = Instance.new("ImageLabel")
	setp(NG435, "Active", false)
	setp(NG435, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG435, "BackgroundTransparency", 1)
	setp(NG435, "BorderSizePixel", 0)
	setp(NG435, "Name", "Background")
	NG435.Selectable = false
	setp(NG435, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG435, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG435, "Parent", NG433)
	NG436 = Instance.new("TextBox")
	setp(NG436, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG436, "BackgroundTransparency", 1)
	setp(NG436, "BorderSizePixel", 0)
	setp(NG436, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG436, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG436, "Font", Enum.Font.ArialBold)
	setp(NG436, "FontSize", Enum.FontSize.Size10)
	setp(NG436, "Text", "100%")
	setp(NG436, "TextColor3", Color3.new(1, 1, 1))
	setp(NG436, "Parent", NG433)
	NG437 = Instance.new("Frame")
	setp(NG437, "BorderSizePixel", 0)
	setp(NG437, "Name", "Bar")
	setp(NG437, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG437, "Size", UDim2.new(0, 3, 1, -4))
	setp(NG437, "Parent", NG431)
	NG438 = Instance.new("Frame")
	setp(NG438, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG438, "BackgroundTransparency", 0.89999997615814)
	setp(NG438, "BorderSizePixel", 0)
	setp(NG438, "Name", "Shadow")
	setp(NG438, "Position", UDim2.new(0, 0, 1, -3))
	setp(NG438, "Size", UDim2.new(1, 0, 0, 3))
	setp(NG438, "Parent", NG437)
	NG439 = Instance.new("Frame")
	setp(NG439, "BorderSizePixel", 0)
	setp(NG439, "Name", "ColorDisplay")
	setp(NG439, "Position", UDim2.new(0, 180, 0, 220))
	setp(NG439, "Size", UDim2.new(0, 60, 0, 103))
	setp(NG439, "Parent", NG409)
	NG440 = Instance.new("Frame")
	setp(NG440, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG440, "BackgroundTransparency", 0.89999997615814)
	setp(NG440, "BorderSizePixel", 0)
	setp(NG440, "Name", "Shadow")
	setp(NG440, "Position", UDim2.new(0, 0, 1, -3))
	setp(NG440, "Size", UDim2.new(1, 0, 0, 3))
	setp(NG440, "Parent", NG439)
	NG441 = Instance.new("TextButton")
	setp(NG441, "Active", true)
	setp(NG441, "BackgroundColor3", Color3.new(1, 0.635294, 0.184314))
	setp(NG441, "BorderSizePixel", 0)
	setp(NG441, "Name", "OkButton")
	setp(NG441, "Position", UDim2.new(0, 10, 0, 335))
	NG441.Selectable = true
	setp(NG441, "Size", UDim2.new(0, 140, 0, 30))
	NG441.Style = Enum.ButtonStyle.Custom
	setp(NG441, "ZIndex", 2)
	setp(NG441, "Font", Enum.Font.SourceSansBold)
	setp(NG441, "FontSize", Enum.FontSize.Size18)
	setp(NG441, "Text", "Ok")
	setp(NG441, "TextColor3", Color3.new(1, 1, 1))
	setp(NG441, "TextStrokeTransparency", 0.85000002384186)
	setp(NG441, "Parent", NG409)
	NG442 = Instance.new("Frame")
	setp(NG442, "BackgroundColor3", Color3.new(0.8, 0.505882, 0.145098))
	setp(NG442, "BorderSizePixel", 0)
	setp(NG442, "Name", "Bevel")
	setp(NG442, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG442, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG442, "ZIndex", 2)
	setp(NG442, "Parent", NG441)
	NG443 = Instance.new("TextButton")
	setp(NG443, "Active", true)
	setp(NG443, "BackgroundColor3", Color3.new(1, 0.635294, 0.184314))
	setp(NG443, "BackgroundTransparency", 0.60000002384186)
	setp(NG443, "BorderSizePixel", 0)
	setp(NG443, "Name", "CancelButton")
	setp(NG443, "Position", UDim2.new(0, 160, 0, 335))
	NG443.Selectable = true
	setp(NG443, "Size", UDim2.new(0, 80, 0, 30))
	NG443.Style = Enum.ButtonStyle.Custom
	setp(NG443, "ZIndex", 2)
	setp(NG443, "Font", Enum.Font.SourceSansBold)
	setp(NG443, "FontSize", Enum.FontSize.Size18)
	setp(NG443, "Text", "Cancel")
	setp(NG443, "TextColor3", Color3.new(1, 1, 1))
	setp(NG443, "TextStrokeTransparency", 0.85000002384186)
	setp(NG443, "Parent", NG409)
	NG444 = Instance.new("Frame")
	setp(NG444, "BackgroundColor3", Color3.new(0.8, 0.505882, 0.145098))
	setp(NG444, "BackgroundTransparency", 0.60000002384186)
	setp(NG444, "BorderSizePixel", 0)
	setp(NG444, "Name", "Bevel")
	setp(NG444, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG444, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG444, "ZIndex", 2)
	setp(NG444, "Parent", NG443)
	NG445 = Instance.new("Frame")
	setp(NG445, "Active", true)
	setp(NG445, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG445, "BackgroundTransparency", 1)
	setp(NG445, "BorderSizePixel", 0)
	setp(NG445, "Name", "BTMeshToolGUI")
	setp(NG445, "Position", UDim2.new(0, 0, 0, 172))
	setp(NG445, "Size", UDim2.new(0, 200, 0, 55))
	NG445.Draggable = true
	setp(NG445, "Parent", NG1)
	NG446 = Instance.new("Frame")
	setp(NG446, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG446, "BackgroundTransparency", 1)
	setp(NG446, "BorderSizePixel", 0)
	setp(NG446, "Name", "Title")
	setp(NG446, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG446, "Parent", NG445)
	NG447 = Instance.new("Frame")
	setp(NG447, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG447, "BorderSizePixel", 0)
	setp(NG447, "Name", "ColorBar")
	setp(NG447, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG447, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG447, "Parent", NG446)
	NG448 = Instance.new("TextLabel")
	setp(NG448, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG448, "BackgroundTransparency", 1)
	setp(NG448, "BorderSizePixel", 0)
	setp(NG448, "Name", "Label")
	setp(NG448, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG448, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG448, "Font", Enum.Font.ArialBold)
	setp(NG448, "FontSize", Enum.FontSize.Size10)
	setp(NG448, "Text", "MESH TOOL")
	setp(NG448, "TextColor3", Color3.new(1, 1, 1))
	setp(NG448, "TextStrokeTransparency", 0)
	setp(NG448, "TextWrapped", true)
	setp(NG448, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG448, "Parent", NG446)
	NG449 = Instance.new("TextLabel")
	setp(NG449, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG449, "BackgroundTransparency", 1)
	setp(NG449, "BorderSizePixel", 0)
	setp(NG449, "Name", "F3XSignature")
	setp(NG449, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG449, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG449, "Font", Enum.Font.ArialBold)
	setp(NG449, "FontSize", Enum.FontSize.Size14)
	setp(NG449, "Text", "F3X")
	setp(NG449, "TextColor3", Color3.new(1, 1, 1))
	setp(NG449, "TextStrokeTransparency", 0.89999997615814)
	setp(NG449, "TextWrapped", true)
	setp(NG449, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG449, "Parent", NG446)
	NG450 = Instance.new("Frame")
	setp(NG450, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG450, "BackgroundTransparency", 1)
	setp(NG450, "BorderSizePixel", 0)
	setp(NG450, "Name", "TypeOption")
	setp(NG450, "Position", UDim2.new(0, 14, 0, 65))
	setp(NG450, "Size", UDim2.new(1, -14, 0, 25))
	setp(NG450, "Visible", false)
	setp(NG450, "Parent", NG445)
	NG451 = Instance.new("TextLabel")
	setp(NG451, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG451, "BackgroundTransparency", 1)
	setp(NG451, "BorderSizePixel", 0)
	setp(NG451, "Name", "Label")
	setp(NG451, "Size", UDim2.new(0, 30, 0, 25))
	setp(NG451, "Font", Enum.Font.ArialBold)
	setp(NG451, "FontSize", Enum.FontSize.Size10)
	setp(NG451, "Text", "Type")
	setp(NG451, "TextColor3", Color3.new(1, 1, 1))
	setp(NG451, "TextStrokeTransparency", 0)
	setp(NG451, "TextWrapped", true)
	setp(NG451, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG451, "Parent", NG450)
	NG452 = Instance.new("Frame")
	setp(NG452, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG452, "BackgroundTransparency", 1)
	setp(NG452, "BorderSizePixel", 0)
	setp(NG452, "Name", "ScaleOption")
	setp(NG452, "Position", UDim2.new(0, 0, 0, 100))
	setp(NG452, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG452, "Visible", false)
	setp(NG452, "Parent", NG445)
	NG453 = Instance.new("TextLabel")
	setp(NG453, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG453, "BackgroundTransparency", 1)
	setp(NG453, "BorderSizePixel", 0)
	setp(NG453, "Name", "Label")
	setp(NG453, "Position", UDim2.new(0, 14, 0, 0))
	setp(NG453, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG453, "Font", Enum.Font.ArialBold)
	setp(NG453, "FontSize", Enum.FontSize.Size10)
	setp(NG453, "Text", "Scale")
	setp(NG453, "TextColor3", Color3.new(1, 1, 1))
	setp(NG453, "TextStrokeTransparency", 0)
	setp(NG453, "TextWrapped", true)
	setp(NG453, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG453, "Parent", NG452)
	NG454 = Instance.new("Frame")
	setp(NG454, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG454, "BackgroundTransparency", 1)
	setp(NG454, "BorderSizePixel", 0)
	setp(NG454, "Name", "XInput")
	setp(NG454, "Position", UDim2.new(0, 55, 0, 0))
	setp(NG454, "Size", UDim2.new(0, 45, 0, 25))
	setp(NG454, "Parent", NG452)
	NG455 = Instance.new("TextButton")
	setp(NG455, "Active", true)
	setp(NG455, "AutoButtonColor", false)
	setp(NG455, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG455, "BackgroundTransparency", 1)
	setp(NG455, "BorderSizePixel", 0)
	NG455.Selectable = true
	setp(NG455, "Size", UDim2.new(1, 0, 1, 0))
	NG455.Style = Enum.ButtonStyle.Custom
	setp(NG455, "ZIndex", 2)
	setp(NG455, "Font", Enum.Font.Legacy)
	setp(NG455, "FontSize", Enum.FontSize.Size8)
	setp(NG455, "Text", "")
	setp(NG455, "Parent", NG454)
	NG456 = Instance.new("ImageLabel")
	setp(NG456, "Active", false)
	setp(NG456, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG456, "BackgroundTransparency", 1)
	setp(NG456, "BorderSizePixel", 0)
	setp(NG456, "Name", "Background")
	NG456.Selectable = false
	setp(NG456, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG456, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG456, "Parent", NG454)
	NG457 = Instance.new("Frame")
	setp(NG457, "BorderSizePixel", 0)
	setp(NG457, "Name", "SelectedIndicator")
	setp(NG457, "Position", UDim2.new(0, 5, 0, -2))
	setp(NG457, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG457, "Parent", NG454)
	NG458 = Instance.new("TextBox")
	setp(NG458, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG458, "BackgroundTransparency", 1)
	setp(NG458, "BorderSizePixel", 0)
	setp(NG458, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG458, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG458, "Font", Enum.Font.ArialBold)
	setp(NG458, "FontSize", Enum.FontSize.Size10)
	setp(NG458, "Text", "1")
	setp(NG458, "TextColor3", Color3.new(1, 1, 1))
	setp(NG458, "Parent", NG454)
	NG459 = Instance.new("Frame")
	setp(NG459, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG459, "BackgroundTransparency", 1)
	setp(NG459, "BorderSizePixel", 0)
	setp(NG459, "Name", "YInput")
	setp(NG459, "Position", UDim2.new(0, 100, 0, 0))
	setp(NG459, "Size", UDim2.new(0, 45, 0, 25))
	setp(NG459, "Parent", NG452)
	NG460 = Instance.new("TextButton")
	setp(NG460, "Active", true)
	setp(NG460, "AutoButtonColor", false)
	setp(NG460, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG460, "BackgroundTransparency", 1)
	setp(NG460, "BorderSizePixel", 0)
	NG460.Selectable = true
	setp(NG460, "Size", UDim2.new(1, 0, 1, 0))
	NG460.Style = Enum.ButtonStyle.Custom
	setp(NG460, "ZIndex", 2)
	setp(NG460, "Font", Enum.Font.Legacy)
	setp(NG460, "FontSize", Enum.FontSize.Size8)
	setp(NG460, "Text", "")
	setp(NG460, "Parent", NG459)
	NG461 = Instance.new("ImageLabel")
	setp(NG461, "Active", false)
	setp(NG461, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG461, "BackgroundTransparency", 1)
	setp(NG461, "BorderSizePixel", 0)
	setp(NG461, "Name", "Background")
	NG461.Selectable = false
	setp(NG461, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG461, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG461, "Parent", NG459)
	NG462 = Instance.new("Frame")
	setp(NG462, "BorderSizePixel", 0)
	setp(NG462, "Name", "SelectedIndicator")
	setp(NG462, "Position", UDim2.new(0, 5, 0, -2))
	setp(NG462, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG462, "Parent", NG459)
	NG463 = Instance.new("TextBox")
	setp(NG463, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG463, "BackgroundTransparency", 1)
	setp(NG463, "BorderSizePixel", 0)
	setp(NG463, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG463, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG463, "Font", Enum.Font.ArialBold)
	setp(NG463, "FontSize", Enum.FontSize.Size10)
	setp(NG463, "Text", "1")
	setp(NG463, "TextColor3", Color3.new(1, 1, 1))
	setp(NG463, "Parent", NG459)
	NG464 = Instance.new("Frame")
	setp(NG464, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG464, "BackgroundTransparency", 1)
	setp(NG464, "BorderSizePixel", 0)
	setp(NG464, "Name", "ZInput")
	setp(NG464, "Position", UDim2.new(0, 145, 0, 0))
	setp(NG464, "Size", UDim2.new(0, 45, 0, 25))
	setp(NG464, "Parent", NG452)
	NG465 = Instance.new("TextButton")
	setp(NG465, "Active", true)
	setp(NG465, "AutoButtonColor", false)
	setp(NG465, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG465, "BackgroundTransparency", 1)
	setp(NG465, "BorderSizePixel", 0)
	NG465.Selectable = true
	setp(NG465, "Size", UDim2.new(1, 0, 1, 0))
	NG465.Style = Enum.ButtonStyle.Custom
	setp(NG465, "ZIndex", 2)
	setp(NG465, "Font", Enum.Font.Legacy)
	setp(NG465, "FontSize", Enum.FontSize.Size8)
	setp(NG465, "Text", "")
	setp(NG465, "Parent", NG464)
	NG466 = Instance.new("ImageLabel")
	setp(NG466, "Active", false)
	setp(NG466, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG466, "BackgroundTransparency", 1)
	setp(NG466, "BorderSizePixel", 0)
	setp(NG466, "Name", "Background")
	NG466.Selectable = false
	setp(NG466, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG466, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG466, "Parent", NG464)
	NG467 = Instance.new("Frame")
	setp(NG467, "BorderSizePixel", 0)
	setp(NG467, "Name", "SelectedIndicator")
	setp(NG467, "Position", UDim2.new(0, 5, 0, -2))
	setp(NG467, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG467, "Parent", NG464)
	NG468 = Instance.new("TextBox")
	setp(NG468, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG468, "BackgroundTransparency", 1)
	setp(NG468, "BorderSizePixel", 0)
	setp(NG468, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG468, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG468, "Font", Enum.Font.ArialBold)
	setp(NG468, "FontSize", Enum.FontSize.Size10)
	setp(NG468, "Text", "1")
	setp(NG468, "TextColor3", Color3.new(1, 1, 1))
	setp(NG468, "Parent", NG464)
	NG469 = Instance.new("Frame")
	setp(NG469, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG469, "BackgroundTransparency", 1)
	setp(NG469, "BorderSizePixel", 0)
	setp(NG469, "Name", "AddButton")
	setp(NG469, "Position", UDim2.new(0, 10, 0, 30))
	setp(NG469, "Size", UDim2.new(1, -10, 0, 20))
	setp(NG469, "Visible", false)
	setp(NG469, "Parent", NG445)
	NG470 = Instance.new("TextButton")
	setp(NG470, "Active", true)
	setp(NG470, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG470, "BackgroundTransparency", 0.44999998807907)
	setp(NG470, "BorderSizePixel", 0)
	setp(NG470, "Name", "Button")
	NG470.Selectable = true
	setp(NG470, "Size", UDim2.new(1, 0, 1, 0))
	NG470.Style = Enum.ButtonStyle.Custom
	setp(NG470, "Font", Enum.Font.ArialBold)
	setp(NG470, "FontSize", Enum.FontSize.Size10)
	setp(NG470, "Text", "ADD MESH")
	setp(NG470, "TextColor3", Color3.new(1, 1, 1))
	setp(NG470, "TextStrokeTransparency", 0.80000001192093)
	setp(NG470, "Parent", NG469)
	NG471 = Instance.new("Frame")
	setp(NG471, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG471, "BackgroundTransparency", 0.30000001192093)
	setp(NG471, "BorderSizePixel", 0)
	setp(NG471, "Name", "Shadow")
	setp(NG471, "Position", UDim2.new(0, 0, 1, 0))
	setp(NG471, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG471, "ZIndex", 2)
	setp(NG471, "Parent", NG469)
	NG472 = Instance.new("Frame")
	setp(NG472, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG472, "BackgroundTransparency", 1)
	setp(NG472, "BorderSizePixel", 0)
	setp(NG472, "Name", "MeshIDOption")
	setp(NG472, "Position", UDim2.new(0, 14, 0, 135))
	setp(NG472, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG472, "Visible", false)
	setp(NG472, "Parent", NG445)
	NG473 = Instance.new("TextLabel")
	setp(NG473, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG473, "BackgroundTransparency", 1)
	setp(NG473, "BorderSizePixel", 0)
	setp(NG473, "Name", "Label")
	setp(NG473, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG473, "Font", Enum.Font.ArialBold)
	setp(NG473, "FontSize", Enum.FontSize.Size10)
	setp(NG473, "Text", "Mesh ID")
	setp(NG473, "TextColor3", Color3.new(1, 1, 1))
	setp(NG473, "TextStrokeTransparency", 0)
	setp(NG473, "TextWrapped", true)
	setp(NG473, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG473, "Parent", NG472)
	NG474 = Instance.new("TextBox")
	setp(NG474, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG474, "BackgroundTransparency", 1)
	setp(NG474, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG474, "BorderSizePixel", 0)
	setp(NG474, "Position", UDim2.new(0, 60, 0, -1))
	setp(NG474, "Size", UDim2.new(0, 80, 0, 18))
	setp(NG474, "Font", Enum.Font.SourceSansBold)
	setp(NG474, "FontSize", Enum.FontSize.Size10)
	setp(NG474, "Text", "")
	setp(NG474, "TextColor3", Color3.new(1, 1, 1))
	setp(NG474, "TextScaled", true)
	setp(NG474, "TextStrokeTransparency", 0.5)
	setp(NG474, "TextWrapped", true)
	setp(NG474, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG474, "Parent", NG472)
	NG475 = Instance.new("Frame")
	setp(NG475, "BackgroundTransparency", 1)
	setp(NG475, "BorderSizePixel", 0)
	setp(NG475, "Name", "TextBoxBorder")
	setp(NG475, "Position", UDim2.new(0, 56, 0, 17))
	setp(NG475, "Size", UDim2.new(0, 85, 0, 3))
	setp(NG475, "Parent", NG472)
	NG476 = Instance.new("Frame")
	setp(NG476, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG476, "BorderSizePixel", 0)
	setp(NG476, "Name", "BottomBorder")
	setp(NG476, "Position", UDim2.new(0, 0, 1, -1))
	setp(NG476, "Size", UDim2.new(1, 0, 0, 1))
	setp(NG476, "Parent", NG475)
	NG477 = Instance.new("Frame")
	setp(NG477, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG477, "BorderSizePixel", 0)
	setp(NG477, "Name", "LeftBorder")
	setp(NG477, "Size", UDim2.new(0, 1, 1, 0))
	setp(NG477, "Parent", NG475)
	NG478 = Instance.new("Frame")
	setp(NG478, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG478, "BorderSizePixel", 0)
	setp(NG478, "Name", "RightBorder")
	setp(NG478, "Position", UDim2.new(1, -1, 0, 0))
	setp(NG478, "Size", UDim2.new(0, 1, 1, 0))
	setp(NG478, "Parent", NG475)
	NG479 = Instance.new("Frame")
	setp(NG479, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG479, "BackgroundTransparency", 0.89999997615814)
	setp(NG479, "BorderSizePixel", 0)
	setp(NG479, "Name", "TextBoxBackground")
	setp(NG479, "Position", UDim2.new(0, 55, 0, -2))
	setp(NG479, "Size", UDim2.new(0, 86, 0, 22))
	setp(NG479, "Parent", NG472)
	NG480 = Instance.new("TextButton")
	setp(NG480, "Active", true)
	setp(NG480, "BackgroundTransparency", 1)
	setp(NG480, "BorderSizePixel", 0)
	setp(NG480, "Position", UDim2.new(0, 60, 0, -1))
	NG480.Selectable = true
	setp(NG480, "Size", UDim2.new(0, 80, 0, 18))
	NG480.Style = Enum.ButtonStyle.Custom
	setp(NG480, "ZIndex", 2)
	setp(NG480, "FontSize", Enum.FontSize.Size14)
	setp(NG480, "Text", "")
	setp(NG480, "Parent", NG472)
	NG481 = Instance.new("Frame")
	setp(NG481, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG481, "BorderSizePixel", 0)
	setp(NG481, "Name", "BottomColorBar")
	setp(NG481, "Position", UDim2.new(0, 5, 1, -2))
	setp(NG481, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG481, "Parent", NG445)
	NG482 = Instance.new("Frame")
	setp(NG482, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG482, "BackgroundTransparency", 1)
	setp(NG482, "BorderSizePixel", 0)
	setp(NG482, "Name", "TextureIDOption")
	setp(NG482, "Position", UDim2.new(0, 14, 0, 165))
	setp(NG482, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG482, "Visible", false)
	setp(NG482, "Parent", NG445)
	NG483 = Instance.new("TextLabel")
	setp(NG483, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG483, "BackgroundTransparency", 1)
	setp(NG483, "BorderSizePixel", 0)
	setp(NG483, "Name", "Label")
	setp(NG483, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG483, "Font", Enum.Font.ArialBold)
	setp(NG483, "FontSize", Enum.FontSize.Size10)
	setp(NG483, "Text", "Texture ID")
	setp(NG483, "TextColor3", Color3.new(1, 1, 1))
	setp(NG483, "TextStrokeTransparency", 0)
	setp(NG483, "TextWrapped", true)
	setp(NG483, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG483, "Parent", NG482)
	NG484 = Instance.new("TextBox")
	setp(NG484, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG484, "BackgroundTransparency", 1)
	setp(NG484, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG484, "BorderSizePixel", 0)
	setp(NG484, "Position", UDim2.new(0, 65, 0, -1))
	setp(NG484, "Size", UDim2.new(0, 80, 0, 18))
	setp(NG484, "Font", Enum.Font.SourceSansBold)
	setp(NG484, "FontSize", Enum.FontSize.Size10)
	setp(NG484, "Text", "")
	setp(NG484, "TextColor3", Color3.new(1, 1, 1))
	setp(NG484, "TextScaled", true)
	setp(NG484, "TextStrokeTransparency", 0.5)
	setp(NG484, "TextWrapped", true)
	setp(NG484, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG484, "Parent", NG482)
	NG485 = Instance.new("Frame")
	setp(NG485, "BackgroundTransparency", 1)
	setp(NG485, "BorderSizePixel", 0)
	setp(NG485, "Name", "TextBoxBorder")
	setp(NG485, "Position", UDim2.new(0, 61, 0, 17))
	setp(NG485, "Size", UDim2.new(0, 85, 0, 3))
	setp(NG485, "Parent", NG482)
	NG486 = Instance.new("Frame")
	setp(NG486, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG486, "BorderSizePixel", 0)
	setp(NG486, "Name", "BottomBorder")
	setp(NG486, "Position", UDim2.new(0, 0, 1, -1))
	setp(NG486, "Size", UDim2.new(1, 0, 0, 1))
	setp(NG486, "Parent", NG485)
	NG487 = Instance.new("Frame")
	setp(NG487, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG487, "BorderSizePixel", 0)
	setp(NG487, "Name", "LeftBorder")
	setp(NG487, "Size", UDim2.new(0, 1, 1, 0))
	setp(NG487, "Parent", NG485)
	NG488 = Instance.new("Frame")
	setp(NG488, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG488, "BorderSizePixel", 0)
	setp(NG488, "Name", "RightBorder")
	setp(NG488, "Position", UDim2.new(1, -1, 0, 0))
	setp(NG488, "Size", UDim2.new(0, 1, 1, 0))
	setp(NG488, "Parent", NG485)
	NG489 = Instance.new("Frame")
	setp(NG489, "BackgroundColor3", Color3.new(0.333333, 0, 0.498039))
	setp(NG489, "BackgroundTransparency", 0.89999997615814)
	setp(NG489, "BorderSizePixel", 0)
	setp(NG489, "Name", "TextBoxBackground")
	setp(NG489, "Position", UDim2.new(0, 60, 0, -2))
	setp(NG489, "Size", UDim2.new(0, 86, 0, 22))
	setp(NG489, "Parent", NG482)
	NG490 = Instance.new("TextButton")
	setp(NG490, "Active", true)
	setp(NG490, "BackgroundTransparency", 1)
	setp(NG490, "BorderSizePixel", 0)
	setp(NG490, "Position", UDim2.new(0, 65, 0, -1))
	NG490.Selectable = true
	setp(NG490, "Size", UDim2.new(0, 80, 0, 18))
	NG490.Style = Enum.ButtonStyle.Custom
	setp(NG490, "ZIndex", 2)
	setp(NG490, "FontSize", Enum.FontSize.Size14)
	setp(NG490, "Text", "")
	setp(NG490, "Parent", NG482)
	NG491 = Instance.new("Frame")
	setp(NG491, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG491, "BackgroundTransparency", 1)
	setp(NG491, "BorderSizePixel", 0)
	setp(NG491, "Name", "RemoveButton")
	setp(NG491, "Position", UDim2.new(0, 10, 1, -30))
	setp(NG491, "Size", UDim2.new(1, -10, 0, 20))
	setp(NG491, "Visible", false)
	setp(NG491, "Parent", NG445)
	NG492 = Instance.new("TextButton")
	setp(NG492, "Active", true)
	setp(NG492, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG492, "BackgroundTransparency", 0.44999998807907)
	setp(NG492, "BorderSizePixel", 0)
	setp(NG492, "Name", "Button")
	NG492.Selectable = true
	setp(NG492, "Size", UDim2.new(1, 0, 1, 0))
	NG492.Style = Enum.ButtonStyle.Custom
	setp(NG492, "Font", Enum.Font.ArialBold)
	setp(NG492, "FontSize", Enum.FontSize.Size10)
	setp(NG492, "Text", "REMOVE MESH")
	setp(NG492, "TextColor3", Color3.new(1, 1, 1))
	setp(NG492, "TextStrokeTransparency", 0.80000001192093)
	setp(NG492, "Parent", NG491)
	NG493 = Instance.new("Frame")
	setp(NG493, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG493, "BackgroundTransparency", 0.30000001192093)
	setp(NG493, "BorderSizePixel", 0)
	setp(NG493, "Name", "Shadow")
	setp(NG493, "Position", UDim2.new(0, 0, 1, 0))
	setp(NG493, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG493, "ZIndex", 2)
	setp(NG493, "Parent", NG491)
	NG494 = Instance.new("Frame")
	setp(NG494, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG494, "BackgroundTransparency", 1)
	setp(NG494, "BorderSizePixel", 0)
	setp(NG494, "Name", "TintOption")
	setp(NG494, "Position", UDim2.new(0, 0, 0, 200))
	setp(NG494, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG494, "Visible", false)
	setp(NG494, "Parent", NG445)
	NG495 = Instance.new("TextLabel")
	setp(NG495, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG495, "BackgroundTransparency", 1)
	setp(NG495, "BorderSizePixel", 0)
	setp(NG495, "Name", "Label")
	setp(NG495, "Position", UDim2.new(0, 14, 0, 0))
	setp(NG495, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG495, "Font", Enum.Font.ArialBold)
	setp(NG495, "FontSize", Enum.FontSize.Size10)
	setp(NG495, "Text", "Tint")
	setp(NG495, "TextColor3", Color3.new(1, 1, 1))
	setp(NG495, "TextStrokeTransparency", 0)
	setp(NG495, "TextWrapped", true)
	setp(NG495, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG495, "Parent", NG494)
	NG496 = Instance.new("Frame")
	setp(NG496, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG496, "BackgroundTransparency", 1)
	setp(NG496, "BorderSizePixel", 0)
	setp(NG496, "Name", "BInput")
	setp(NG496, "Position", UDim2.new(0, 114, 0, 0))
	setp(NG496, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG496, "Parent", NG494)
	NG497 = Instance.new("TextButton")
	setp(NG497, "Active", true)
	setp(NG497, "AutoButtonColor", false)
	setp(NG497, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG497, "BackgroundTransparency", 1)
	setp(NG497, "BorderSizePixel", 0)
	NG497.Selectable = true
	setp(NG497, "Size", UDim2.new(1, 0, 1, 0))
	NG497.Style = Enum.ButtonStyle.Custom
	setp(NG497, "ZIndex", 2)
	setp(NG497, "Font", Enum.Font.Legacy)
	setp(NG497, "FontSize", Enum.FontSize.Size8)
	setp(NG497, "Text", "")
	setp(NG497, "Parent", NG496)
	NG498 = Instance.new("ImageLabel")
	setp(NG498, "Active", false)
	setp(NG498, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG498, "BackgroundTransparency", 1)
	setp(NG498, "BorderSizePixel", 0)
	setp(NG498, "Name", "Background")
	NG498.Selectable = false
	setp(NG498, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG498, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG498, "Parent", NG496)
	NG499 = Instance.new("Frame")
	setp(NG499, "BackgroundColor3", Color3.new(0, 0, 1))
	setp(NG499, "BorderSizePixel", 0)
	setp(NG499, "Name", "SelectedIndicator")
	setp(NG499, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG499, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG499, "Parent", NG496)
	NG500 = Instance.new("TextBox")
	setp(NG500, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG500, "BackgroundTransparency", 1)
	setp(NG500, "BorderSizePixel", 0)
	setp(NG500, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG500, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG500, "Font", Enum.Font.ArialBold)
	setp(NG500, "FontSize", Enum.FontSize.Size10)
	setp(NG500, "Text", "255")
	setp(NG500, "TextColor3", Color3.new(1, 1, 1))
	setp(NG500, "Parent", NG496)
	NG501 = Instance.new("Frame")
	setp(NG501, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG501, "BackgroundTransparency", 1)
	setp(NG501, "BorderSizePixel", 0)
	setp(NG501, "Name", "GInput")
	setp(NG501, "Position", UDim2.new(0, 77, 0, 0))
	setp(NG501, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG501, "Parent", NG494)
	NG502 = Instance.new("TextButton")
	setp(NG502, "Active", true)
	setp(NG502, "AutoButtonColor", false)
	setp(NG502, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG502, "BackgroundTransparency", 1)
	setp(NG502, "BorderSizePixel", 0)
	NG502.Selectable = true
	setp(NG502, "Size", UDim2.new(1, 0, 1, 0))
	NG502.Style = Enum.ButtonStyle.Custom
	setp(NG502, "ZIndex", 2)
	setp(NG502, "Font", Enum.Font.Legacy)
	setp(NG502, "FontSize", Enum.FontSize.Size8)
	setp(NG502, "Text", "")
	setp(NG502, "Parent", NG501)
	NG503 = Instance.new("ImageLabel")
	setp(NG503, "Active", false)
	setp(NG503, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG503, "BackgroundTransparency", 1)
	setp(NG503, "BorderSizePixel", 0)
	setp(NG503, "Name", "Background")
	NG503.Selectable = false
	setp(NG503, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG503, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG503, "Parent", NG501)
	NG504 = Instance.new("Frame")
	setp(NG504, "BackgroundColor3", Color3.new(0, 1, 0))
	setp(NG504, "BorderSizePixel", 0)
	setp(NG504, "Name", "SelectedIndicator")
	setp(NG504, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG504, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG504, "Parent", NG501)
	NG505 = Instance.new("TextBox")
	setp(NG505, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG505, "BackgroundTransparency", 1)
	setp(NG505, "BorderSizePixel", 0)
	setp(NG505, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG505, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG505, "Font", Enum.Font.ArialBold)
	setp(NG505, "FontSize", Enum.FontSize.Size10)
	setp(NG505, "Text", "255")
	setp(NG505, "TextColor3", Color3.new(1, 1, 1))
	setp(NG505, "Parent", NG501)
	NG506 = Instance.new("Frame")
	setp(NG506, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG506, "BackgroundTransparency", 1)
	setp(NG506, "BorderSizePixel", 0)
	setp(NG506, "Name", "RInput")
	setp(NG506, "Position", UDim2.new(0, 40, 0, 0))
	setp(NG506, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG506, "Parent", NG494)
	NG507 = Instance.new("TextButton")
	setp(NG507, "Active", true)
	setp(NG507, "AutoButtonColor", false)
	setp(NG507, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG507, "BackgroundTransparency", 1)
	setp(NG507, "BorderSizePixel", 0)
	NG507.Selectable = true
	setp(NG507, "Size", UDim2.new(1, 0, 1, 0))
	NG507.Style = Enum.ButtonStyle.Custom
	setp(NG507, "ZIndex", 2)
	setp(NG507, "Font", Enum.Font.Legacy)
	setp(NG507, "FontSize", Enum.FontSize.Size8)
	setp(NG507, "Text", "")
	setp(NG507, "Parent", NG506)
	NG508 = Instance.new("ImageLabel")
	setp(NG508, "Active", false)
	setp(NG508, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG508, "BackgroundTransparency", 1)
	setp(NG508, "BorderSizePixel", 0)
	setp(NG508, "Name", "Background")
	NG508.Selectable = false
	setp(NG508, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG508, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG508, "Parent", NG506)
	NG509 = Instance.new("Frame")
	setp(NG509, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG509, "BorderSizePixel", 0)
	setp(NG509, "Name", "SelectedIndicator")
	setp(NG509, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG509, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG509, "Parent", NG506)
	NG510 = Instance.new("TextBox")
	setp(NG510, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG510, "BackgroundTransparency", 1)
	setp(NG510, "BorderSizePixel", 0)
	setp(NG510, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG510, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG510, "Font", Enum.Font.ArialBold)
	setp(NG510, "FontSize", Enum.FontSize.Size10)
	setp(NG510, "Text", "255")
	setp(NG510, "TextColor3", Color3.new(1, 1, 1))
	setp(NG510, "Parent", NG506)
	NG511 = Instance.new("Frame")
	setp(NG511, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG511, "BackgroundTransparency", 0.5)
	setp(NG511, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG511, "BorderSizePixel", 0)
	setp(NG511, "Name", "Separator")
	setp(NG511, "Position", UDim2.new(0, 156, 0, 4))
	setp(NG511, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG511, "Parent", NG494)
	NG512 = Instance.new("Frame")
	setp(NG512, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG512, "BackgroundTransparency", 0.5)
	setp(NG512, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG512, "BorderSizePixel", 0)
	setp(NG512, "Name", "Separator")
	setp(NG512, "Position", UDim2.new(0, 156, 0, 16))
	setp(NG512, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG512, "Parent", NG494)
	NG513 = Instance.new("Frame")
	setp(NG513, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG513, "BackgroundTransparency", 0.5)
	setp(NG513, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG513, "BorderSizePixel", 0)
	setp(NG513, "Name", "Separator")
	setp(NG513, "Position", UDim2.new(0, 156, 0, 10))
	setp(NG513, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG513, "Parent", NG494)
	NG514 = Instance.new("ImageButton")
	setp(NG514, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG514, "BackgroundTransparency", 0.40000000596046)
	setp(NG514, "BorderSizePixel", 0)
	setp(NG514, "Name", "HSVPicker")
	setp(NG514, "Position", UDim2.new(0, 165, 0, -2))
	setp(NG514, "Size", UDim2.new(0, 27, 0, 27))
	NG514.Style = Enum.ButtonStyle.Custom
	setp(NG514, "ZIndex", 2)
	setp(NG514, "Image", "http://www.roblox.com/asset/?id=141313631")
	setp(NG514, "Parent", NG494)
	NG515 = Instance.new("Frame")
	setp(NG515, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG515, "BackgroundTransparency", 0.75)
	setp(NG515, "BorderSizePixel", 0)
	setp(NG515, "Name", "Shadow")
	setp(NG515, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG515, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG515, "Parent", NG514)
	NG516 = Instance.new("TextLabel")
	setp(NG516, "BackgroundTransparency", 1)
	setp(NG516, "BorderSizePixel", 0)
	setp(NG516, "Name", "SelectNote")
	setp(NG516, "Position", UDim2.new(0, 10, 0, 27))
	setp(NG516, "Size", UDim2.new(1, -10, 0, 15))
	setp(NG516, "FontSize", Enum.FontSize.Size14)
	setp(NG516, "Text", "Select something to use this tool.")
	setp(NG516, "TextColor3", Color3.new(1, 1, 1))
	setp(NG516, "TextScaled", true)
	setp(NG516, "TextStrokeTransparency", 0.5)
	setp(NG516, "TextWrapped", true)
	setp(NG516, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG516, "Parent", NG445)
	NG517 = Instance.new("Frame")
	setp(NG517, "Active", true)
	setp(NG517, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG517, "BackgroundTransparency", 1)
	setp(NG517, "BorderSizePixel", 0)
	setp(NG517, "Name", "BTMoveToolGUI")
	setp(NG517, "Position", UDim2.new(0, 0, 0, 280))
	setp(NG517, "Size", UDim2.new(0, 245, 0, 90))
	NG517.Draggable = true
	setp(NG517, "Parent", NG1)
	NG518 = Instance.new("Frame")
	setp(NG518, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG518, "BackgroundTransparency", 1)
	setp(NG518, "BorderSizePixel", 0)
	setp(NG518, "Name", "Changes")
	setp(NG518, "Position", UDim2.new(0, 5, 0, 100))
	setp(NG518, "Size", UDim2.new(1, -5, 0, 20))
	setp(NG518, "Parent", NG517)
	NG519 = Instance.new("TextLabel")
	setp(NG519, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG519, "BackgroundTransparency", 1)
	setp(NG519, "BorderSizePixel", 0)
	setp(NG519, "Name", "Text")
	setp(NG519, "Position", UDim2.new(0, 10, 0, 2))
	setp(NG519, "Size", UDim2.new(1, -10, 0, 20))
	setp(NG519, "Font", Enum.Font.ArialBold)
	setp(NG519, "FontSize", Enum.FontSize.Size10)
	setp(NG519, "Text", "moved 0 studs")
	setp(NG519, "TextColor3", Color3.new(1, 1, 1))
	setp(NG519, "TextStrokeTransparency", 0.5)
	setp(NG519, "TextWrapped", true)
	setp(NG519, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG519, "Parent", NG518)
	NG520 = Instance.new("Frame")
	setp(NG520, "BackgroundColor3", Color3.new(1, 0.666667, 0))
	setp(NG520, "BorderSizePixel", 0)
	setp(NG520, "Name", "ColorBar")
	setp(NG520, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG520, "Parent", NG518)
	NG521 = Instance.new("Frame")
	setp(NG521, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG521, "BackgroundTransparency", 1)
	setp(NG521, "BorderSizePixel", 0)
	setp(NG521, "Name", "Info")
	setp(NG521, "Position", UDim2.new(0, 5, 0, 100))
	setp(NG521, "Size", UDim2.new(1, -5, 0, 60))
	setp(NG521, "Visible", false)
	setp(NG521, "Parent", NG517)
	NG522 = Instance.new("Frame")
	setp(NG522, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG522, "BackgroundTransparency", 1)
	setp(NG522, "BorderSizePixel", 0)
	setp(NG522, "Name", "Center")
	setp(NG522, "Position", UDim2.new(0, 0, 0, 30))
	setp(NG522, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG522, "Parent", NG521)
	NG523 = Instance.new("Frame")
	setp(NG523, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG523, "BackgroundTransparency", 1)
	setp(NG523, "BorderSizePixel", 0)
	setp(NG523, "Name", "Z")
	setp(NG523, "Position", UDim2.new(0, 164, 0, 0))
	setp(NG523, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG523, "Parent", NG522)
	NG524 = Instance.new("ImageLabel")
	setp(NG524, "Active", false)
	setp(NG524, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG524, "BackgroundTransparency", 1)
	setp(NG524, "BorderSizePixel", 0)
	setp(NG524, "Name", "Background")
	NG524.Selectable = false
	setp(NG524, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG524, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG524, "Parent", NG523)
	NG525 = Instance.new("TextButton")
	setp(NG525, "Active", true)
	setp(NG525, "AutoButtonColor", false)
	setp(NG525, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG525, "BackgroundTransparency", 1)
	setp(NG525, "BorderSizePixel", 0)
	NG525.Selectable = true
	setp(NG525, "Size", UDim2.new(1, 0, 1, 0))
	NG525.Style = Enum.ButtonStyle.Custom
	setp(NG525, "ZIndex", 2)
	setp(NG525, "Font", Enum.Font.Legacy)
	setp(NG525, "FontSize", Enum.FontSize.Size8)
	setp(NG525, "Text", "")
	setp(NG525, "Parent", NG523)
	NG526 = Instance.new("TextBox")
	setp(NG526, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG526, "BackgroundTransparency", 1)
	setp(NG526, "BorderSizePixel", 0)
	setp(NG526, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG526, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG526, "Font", Enum.Font.ArialBold)
	setp(NG526, "FontSize", Enum.FontSize.Size10)
	setp(NG526, "Text", "")
	setp(NG526, "TextColor3", Color3.new(1, 1, 1))
	setp(NG526, "Parent", NG523)
	NG527 = Instance.new("Frame")
	setp(NG527, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG527, "BackgroundTransparency", 1)
	setp(NG527, "BorderSizePixel", 0)
	setp(NG527, "Name", "Y")
	setp(NG527, "Position", UDim2.new(0, 117, 0, 0))
	setp(NG527, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG527, "Parent", NG522)
	NG528 = Instance.new("TextButton")
	setp(NG528, "Active", true)
	setp(NG528, "AutoButtonColor", false)
	setp(NG528, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG528, "BackgroundTransparency", 1)
	setp(NG528, "BorderSizePixel", 0)
	NG528.Selectable = true
	setp(NG528, "Size", UDim2.new(1, 0, 1, 0))
	NG528.Style = Enum.ButtonStyle.Custom
	setp(NG528, "ZIndex", 2)
	setp(NG528, "Font", Enum.Font.Legacy)
	setp(NG528, "FontSize", Enum.FontSize.Size8)
	setp(NG528, "Text", "")
	setp(NG528, "Parent", NG527)
	NG529 = Instance.new("TextBox")
	setp(NG529, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG529, "BackgroundTransparency", 1)
	setp(NG529, "BorderSizePixel", 0)
	setp(NG529, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG529, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG529, "Font", Enum.Font.ArialBold)
	setp(NG529, "FontSize", Enum.FontSize.Size10)
	setp(NG529, "Text", "")
	setp(NG529, "TextColor3", Color3.new(1, 1, 1))
	setp(NG529, "Parent", NG527)
	NG530 = Instance.new("ImageLabel")
	setp(NG530, "Active", false)
	setp(NG530, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG530, "BackgroundTransparency", 1)
	setp(NG530, "BorderSizePixel", 0)
	setp(NG530, "Name", "Background")
	NG530.Selectable = false
	setp(NG530, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG530, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG530, "Parent", NG527)
	NG531 = Instance.new("Frame")
	setp(NG531, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG531, "BackgroundTransparency", 1)
	setp(NG531, "BorderSizePixel", 0)
	setp(NG531, "Name", "X")
	setp(NG531, "Position", UDim2.new(0, 70, 0, 0))
	setp(NG531, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG531, "Parent", NG522)
	NG532 = Instance.new("TextBox")
	setp(NG532, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG532, "BackgroundTransparency", 1)
	setp(NG532, "BorderSizePixel", 0)
	setp(NG532, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG532, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG532, "Font", Enum.Font.ArialBold)
	setp(NG532, "FontSize", Enum.FontSize.Size10)
	setp(NG532, "Text", "")
	setp(NG532, "TextColor3", Color3.new(1, 1, 1))
	setp(NG532, "Parent", NG531)
	NG533 = Instance.new("TextButton")
	setp(NG533, "Active", true)
	setp(NG533, "AutoButtonColor", false)
	setp(NG533, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG533, "BackgroundTransparency", 1)
	setp(NG533, "BorderSizePixel", 0)
	NG533.Selectable = true
	setp(NG533, "Size", UDim2.new(1, 0, 1, 0))
	NG533.Style = Enum.ButtonStyle.Custom
	setp(NG533, "ZIndex", 2)
	setp(NG533, "Font", Enum.Font.Legacy)
	setp(NG533, "FontSize", Enum.FontSize.Size8)
	setp(NG533, "Text", "")
	setp(NG533, "Parent", NG531)
	NG534 = Instance.new("ImageLabel")
	setp(NG534, "Active", false)
	setp(NG534, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG534, "BackgroundTransparency", 1)
	setp(NG534, "BorderSizePixel", 0)
	setp(NG534, "Name", "Background")
	NG534.Selectable = false
	setp(NG534, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG534, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG534, "Parent", NG531)
	NG535 = Instance.new("TextLabel")
	setp(NG535, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG535, "BackgroundTransparency", 1)
	setp(NG535, "BorderSizePixel", 0)
	setp(NG535, "Size", UDim2.new(0, 75, 0, 25))
	setp(NG535, "Font", Enum.Font.ArialBold)
	setp(NG535, "FontSize", Enum.FontSize.Size10)
	setp(NG535, "Text", "Position")
	setp(NG535, "TextColor3", Color3.new(1, 1, 1))
	setp(NG535, "TextStrokeTransparency", 0)
	setp(NG535, "TextWrapped", true)
	setp(NG535, "Parent", NG522)
	NG536 = Instance.new("TextLabel")
	setp(NG536, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG536, "BackgroundTransparency", 1)
	setp(NG536, "BorderSizePixel", 0)
	setp(NG536, "Name", "Label")
	setp(NG536, "Position", UDim2.new(0, 10, 0, 2))
	setp(NG536, "Size", UDim2.new(1, -10, 0, 20))
	setp(NG536, "Font", Enum.Font.ArialBold)
	setp(NG536, "FontSize", Enum.FontSize.Size10)
	setp(NG536, "Text", "SELECTION INFO")
	setp(NG536, "TextColor3", Color3.new(1, 1, 1))
	setp(NG536, "TextStrokeTransparency", 0)
	setp(NG536, "TextWrapped", true)
	setp(NG536, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG536, "Parent", NG521)
	NG537 = Instance.new("Frame")
	setp(NG537, "BackgroundColor3", Color3.new(1, 0.666667, 0))
	setp(NG537, "BorderSizePixel", 0)
	setp(NG537, "Name", "ColorBar")
	setp(NG537, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG537, "Parent", NG521)
	NG538 = Instance.new("Frame")
	setp(NG538, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG538, "BackgroundTransparency", 1)
	setp(NG538, "BorderSizePixel", 0)
	setp(NG538, "Name", "IncrementOption")
	setp(NG538, "Position", UDim2.new(0, 0, 0, 65))
	setp(NG538, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG538, "Parent", NG517)
	NG539 = Instance.new("Frame")
	setp(NG539, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG539, "BackgroundTransparency", 1)
	setp(NG539, "BorderSizePixel", 0)
	setp(NG539, "Name", "Label")
	setp(NG539, "Size", UDim2.new(0, 75, 0, 25))
	setp(NG539, "Parent", NG538)
	NG540 = Instance.new("TextLabel")
	setp(NG540, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG540, "BackgroundTransparency", 1)
	setp(NG540, "BorderSizePixel", 0)
	setp(NG540, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG540, "Font", Enum.Font.ArialBold)
	setp(NG540, "FontSize", Enum.FontSize.Size10)
	setp(NG540, "Text", "Increment")
	setp(NG540, "TextColor3", Color3.new(1, 1, 1))
	setp(NG540, "TextStrokeTransparency", 0)
	setp(NG540, "TextWrapped", true)
	setp(NG540, "Parent", NG539)
	NG541 = Instance.new("Frame")
	setp(NG541, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG541, "BackgroundTransparency", 1)
	setp(NG541, "BorderSizePixel", 0)
	setp(NG541, "Name", "Increment")
	setp(NG541, "Position", UDim2.new(0, 70, 0, 0))
	setp(NG541, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG541, "Parent", NG538)
	NG542 = Instance.new("ImageLabel")
	setp(NG542, "Active", false)
	setp(NG542, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG542, "BackgroundTransparency", 1)
	setp(NG542, "BorderSizePixel", 0)
	setp(NG542, "Name", "Background")
	NG542.Selectable = false
	setp(NG542, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG542, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG542, "Parent", NG541)
	NG543 = Instance.new("TextBox")
	setp(NG543, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG543, "BackgroundTransparency", 1)
	setp(NG543, "BorderSizePixel", 0)
	setp(NG543, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG543, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG543, "ZIndex", 2)
	setp(NG543, "Font", Enum.Font.ArialBold)
	setp(NG543, "FontSize", Enum.FontSize.Size10)
	setp(NG543, "Text", "1")
	setp(NG543, "TextColor3", Color3.new(1, 1, 1))
	setp(NG543, "Parent", NG541)
	NG544 = Instance.new("Frame")
	setp(NG544, "BorderSizePixel", 0)
	setp(NG544, "Name", "SelectedIndicator")
	setp(NG544, "Position", UDim2.new(0, 5, 0, -2))
	setp(NG544, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG544, "Parent", NG541)
	NG545 = Instance.new("Frame")
	setp(NG545, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG545, "BackgroundTransparency", 1)
	setp(NG545, "BorderSizePixel", 0)
	setp(NG545, "Name", "Title")
	setp(NG545, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG545, "Parent", NG517)
	NG546 = Instance.new("TextLabel")
	setp(NG546, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG546, "BackgroundTransparency", 1)
	setp(NG546, "BorderSizePixel", 0)
	setp(NG546, "Name", "F3XSignature")
	setp(NG546, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG546, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG546, "Font", Enum.Font.ArialBold)
	setp(NG546, "FontSize", Enum.FontSize.Size14)
	setp(NG546, "Text", "F3X")
	setp(NG546, "TextColor3", Color3.new(1, 1, 1))
	setp(NG546, "TextStrokeTransparency", 0.89999997615814)
	setp(NG546, "TextWrapped", true)
	setp(NG546, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG546, "Parent", NG545)
	NG547 = Instance.new("TextLabel")
	setp(NG547, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG547, "BackgroundTransparency", 1)
	setp(NG547, "BorderSizePixel", 0)
	setp(NG547, "Name", "Label")
	setp(NG547, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG547, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG547, "Font", Enum.Font.ArialBold)
	setp(NG547, "FontSize", Enum.FontSize.Size10)
	setp(NG547, "Text", "MOVE TOOL")
	setp(NG547, "TextColor3", Color3.new(1, 1, 1))
	setp(NG547, "TextStrokeTransparency", 0)
	setp(NG547, "TextWrapped", true)
	setp(NG547, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG547, "Parent", NG545)
	NG548 = Instance.new("Frame")
	setp(NG548, "BackgroundColor3", Color3.new(1, 0.666667, 0))
	setp(NG548, "BorderSizePixel", 0)
	setp(NG548, "Name", "ColorBar")
	setp(NG548, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG548, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG548, "Parent", NG545)
	NG549 = Instance.new("Frame")
	setp(NG549, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG549, "BackgroundTransparency", 1)
	setp(NG549, "BorderSizePixel", 0)
	setp(NG549, "Name", "AxesOption")
	setp(NG549, "Position", UDim2.new(0, 0, 0, 30))
	setp(NG549, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG549, "Parent", NG517)
	NG550 = Instance.new("Frame")
	setp(NG550, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG550, "BackgroundTransparency", 1)
	setp(NG550, "BorderSizePixel", 0)
	setp(NG550, "Name", "Label")
	setp(NG550, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG550, "Parent", NG549)
	NG551 = Instance.new("TextLabel")
	setp(NG551, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG551, "BackgroundTransparency", 1)
	setp(NG551, "BorderSizePixel", 0)
	setp(NG551, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG551, "Font", Enum.Font.ArialBold)
	setp(NG551, "FontSize", Enum.FontSize.Size10)
	setp(NG551, "Text", "Axes")
	setp(NG551, "TextColor3", Color3.new(1, 1, 1))
	setp(NG551, "TextStrokeTransparency", 0)
	setp(NG551, "TextWrapped", true)
	setp(NG551, "Parent", NG550)
	NG552 = Instance.new("Frame")
	setp(NG552, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG552, "BackgroundTransparency", 1)
	setp(NG552, "BorderSizePixel", 0)
	setp(NG552, "Name", "Last")
	setp(NG552, "Position", UDim2.new(0, 175, 0, 0))
	setp(NG552, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG552, "Parent", NG549)
	NG553 = Instance.new("TextLabel")
	setp(NG553, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG553, "BackgroundTransparency", 1)
	setp(NG553, "BorderSizePixel", 0)
	setp(NG553, "Name", "Label")
	setp(NG553, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG553, "Font", Enum.Font.ArialBold)
	setp(NG553, "FontSize", Enum.FontSize.Size10)
	setp(NG553, "Text", "LAST")
	setp(NG553, "TextColor3", Color3.new(1, 1, 1))
	setp(NG553, "Parent", NG552)
	NG554 = Instance.new("ImageLabel")
	setp(NG554, "Active", false)
	setp(NG554, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG554, "BackgroundTransparency", 1)
	setp(NG554, "BorderSizePixel", 0)
	setp(NG554, "Name", "Background")
	NG554.Selectable = false
	setp(NG554, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG554, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG554, "Parent", NG552)
	NG555 = Instance.new("TextButton")
	setp(NG555, "Active", true)
	setp(NG555, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG555, "BackgroundTransparency", 1)
	setp(NG555, "BorderSizePixel", 0)
	setp(NG555, "Name", "Button")
	setp(NG555, "Position", UDim2.new(0, 5, 0, 0))
	NG555.Selectable = true
	setp(NG555, "Size", UDim2.new(1, -10, 1, 0))
	NG555.Style = Enum.ButtonStyle.Custom
	setp(NG555, "ZIndex", 2)
	setp(NG555, "Font", Enum.Font.Legacy)
	setp(NG555, "FontSize", Enum.FontSize.Size8)
	setp(NG555, "Text", "")
	NG555.TextTransparency = 1
	setp(NG555, "Parent", NG552)
	NG556 = Instance.new("Frame")
	setp(NG556, "BackgroundTransparency", 1)
	setp(NG556, "BorderSizePixel", 0)
	setp(NG556, "Name", "SelectedIndicator")
	setp(NG556, "Position", UDim2.new(0, 6, 0, -2))
	setp(NG556, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG556, "Parent", NG552)
	NG557 = Instance.new("Frame")
	setp(NG557, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG557, "BackgroundTransparency", 1)
	setp(NG557, "BorderSizePixel", 0)
	setp(NG557, "Name", "Local")
	setp(NG557, "Position", UDim2.new(0, 110, 0, 0))
	setp(NG557, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG557, "Parent", NG549)
	NG558 = Instance.new("TextLabel")
	setp(NG558, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG558, "BackgroundTransparency", 1)
	setp(NG558, "BorderSizePixel", 0)
	setp(NG558, "Name", "Label")
	setp(NG558, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG558, "Font", Enum.Font.ArialBold)
	setp(NG558, "FontSize", Enum.FontSize.Size10)
	setp(NG558, "Text", "LOCAL")
	setp(NG558, "TextColor3", Color3.new(1, 1, 1))
	setp(NG558, "Parent", NG557)
	NG559 = Instance.new("ImageLabel")
	setp(NG559, "Active", false)
	setp(NG559, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG559, "BackgroundTransparency", 1)
	setp(NG559, "BorderSizePixel", 0)
	setp(NG559, "Name", "Background")
	NG559.Selectable = false
	setp(NG559, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG559, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG559, "Parent", NG557)
	NG560 = Instance.new("TextButton")
	setp(NG560, "Active", true)
	setp(NG560, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG560, "BackgroundTransparency", 1)
	setp(NG560, "BorderSizePixel", 0)
	setp(NG560, "Name", "Button")
	setp(NG560, "Position", UDim2.new(0, 5, 0, 0))
	NG560.Selectable = true
	setp(NG560, "Size", UDim2.new(1, -10, 1, 0))
	NG560.Style = Enum.ButtonStyle.Custom
	setp(NG560, "ZIndex", 2)
	setp(NG560, "Font", Enum.Font.Legacy)
	setp(NG560, "FontSize", Enum.FontSize.Size8)
	setp(NG560, "Text", "")
	NG560.TextTransparency = 1
	setp(NG560, "Parent", NG557)
	NG561 = Instance.new("Frame")
	setp(NG561, "BackgroundTransparency", 1)
	setp(NG561, "BorderSizePixel", 0)
	setp(NG561, "Name", "SelectedIndicator")
	setp(NG561, "Position", UDim2.new(0, 6, 0, -2))
	setp(NG561, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG561, "Parent", NG557)
	NG562 = Instance.new("Frame")
	setp(NG562, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG562, "BackgroundTransparency", 1)
	setp(NG562, "BorderSizePixel", 0)
	setp(NG562, "Name", "Global")
	setp(NG562, "Position", UDim2.new(0, 45, 0, 0))
	setp(NG562, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG562, "Parent", NG549)
	NG563 = Instance.new("TextLabel")
	setp(NG563, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG563, "BackgroundTransparency", 1)
	setp(NG563, "BorderSizePixel", 0)
	setp(NG563, "Name", "Label")
	setp(NG563, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG563, "Font", Enum.Font.ArialBold)
	setp(NG563, "FontSize", Enum.FontSize.Size10)
	setp(NG563, "Text", "GLOBAL")
	setp(NG563, "TextColor3", Color3.new(1, 1, 1))
	setp(NG563, "Parent", NG562)
	NG564 = Instance.new("ImageLabel")
	setp(NG564, "Active", false)
	setp(NG564, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG564, "BackgroundTransparency", 1)
	setp(NG564, "BorderSizePixel", 0)
	setp(NG564, "Name", "Background")
	NG564.Selectable = false
	setp(NG564, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG564, "Image", "http://www.roblox.com/asset/?id=127774197")
	setp(NG564, "Parent", NG562)
	NG565 = Instance.new("TextButton")
	setp(NG565, "Active", true)
	setp(NG565, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG565, "BackgroundTransparency", 1)
	setp(NG565, "BorderSizePixel", 0)
	setp(NG565, "Name", "Button")
	setp(NG565, "Position", UDim2.new(0, 5, 0, 0))
	NG565.Selectable = true
	setp(NG565, "Size", UDim2.new(1, -10, 1, 0))
	NG565.Style = Enum.ButtonStyle.Custom
	setp(NG565, "ZIndex", 2)
	setp(NG565, "Font", Enum.Font.Legacy)
	setp(NG565, "FontSize", Enum.FontSize.Size8)
	setp(NG565, "Text", "")
	NG565.TextTransparency = 1
	setp(NG565, "Parent", NG562)
	NG566 = Instance.new("Frame")
	setp(NG566, "BorderSizePixel", 0)
	setp(NG566, "Name", "SelectedIndicator")
	setp(NG566, "Position", UDim2.new(0, 6, 0, -2))
	setp(NG566, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG566, "Parent", NG562)
	NG567 = Instance.new("Frame")
	setp(NG567, "BackgroundTransparency", 1)
	setp(NG567, "BorderSizePixel", 0)
	setp(NG567, "Name", "BTStartupNotificationContainer")
	setp(NG567, "Position", UDim2.new(0, 210, 0, 0))
	setp(NG567, "Size", UDim2.new(0, 300, 0, 0))
	NG567.Draggable = true
	setp(NG567, "Parent", NG1)
	NG568 = Instance.new("Frame")
	setp(NG568, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG568, "BackgroundTransparency", 0.69999998807907)
	setp(NG568, "BorderSizePixel", 0)
	setp(NG568, "Name", "ToolUpdateNotification")
	setp(NG568, "Size", UDim2.new(1, 0, 0, 65))
	setp(NG568, "Visible", false)
	setp(NG568, "Parent", NG567)
	NG569 = Instance.new("Frame")
	setp(NG569, "BackgroundColor3", Color3.new(1, 0.666667, 0))
	setp(NG569, "BorderSizePixel", 0)
	setp(NG569, "Name", "Bar")
	setp(NG569, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG569, "Parent", NG568)
	NG570 = Instance.new("TextButton")
	setp(NG570, "Active", true)
	setp(NG570, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG570, "BackgroundTransparency", 0.80000001192093)
	setp(NG570, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG570, "BorderSizePixel", 0)
	setp(NG570, "Name", "OKButton")
	setp(NG570, "Position", UDim2.new(0, 0, 1, -22))
	NG570.Selectable = true
	setp(NG570, "Size", UDim2.new(0.5, 0, 0, 22))
	NG570.Style = Enum.ButtonStyle.Custom
	setp(NG570, "Font", Enum.Font.Arial)
	setp(NG570, "FontSize", Enum.FontSize.Size10)
	setp(NG570, "Text", "GOT IT")
	setp(NG570, "TextColor3", Color3.new(1, 1, 1))
	setp(NG570, "Parent", NG568)
	NG571 = Instance.new("TextButton")
	setp(NG571, "Active", true)
	setp(NG571, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG571, "BackgroundTransparency", 0.80000001192093)
	setp(NG571, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG571, "BorderSizePixel", 0)
	setp(NG571, "Name", "HelpButton")
	setp(NG571, "Position", UDim2.new(0.5, 0, 1, -22))
	NG571.Selectable = true
	setp(NG571, "Size", UDim2.new(0.5, 0, 0, 22))
	NG571.Style = Enum.ButtonStyle.Custom
	setp(NG571, "Font", Enum.Font.Arial)
	setp(NG571, "FontSize", Enum.FontSize.Size10)
	setp(NG571, "Text", "WHAT CAN I DO?")
	setp(NG571, "TextColor3", Color3.new(1, 1, 1))
	setp(NG571, "Parent", NG568)
	NG572 = Instance.new("Frame")
	setp(NG572, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG572, "BackgroundTransparency", 0.75)
	setp(NG572, "BorderSizePixel", 0)
	setp(NG572, "Name", "ButtonSeparator")
	setp(NG572, "Position", UDim2.new(0.5, 0, 1, -22))
	setp(NG572, "Size", UDim2.new(0, 1, 0, 22))
	setp(NG572, "Parent", NG568)
	NG573 = Instance.new("Frame")
	setp(NG573, "BackgroundTransparency", 1)
	setp(NG573, "BorderSizePixel", 0)
	setp(NG573, "Name", "Notice")
	setp(NG573, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG573, "Size", UDim2.new(1, 0, 1, -22))
	setp(NG573, "Parent", NG568)
	NG574 = Instance.new("TextLabel")
	setp(NG574, "BackgroundTransparency", 1)
	setp(NG574, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG574, "BorderSizePixel", 0)
	setp(NG574, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG574, "Font", Enum.Font.SourceSansBold)
	setp(NG574, "FontSize", Enum.FontSize.Size14)
	setp(NG574, "Text", "This version of Building Tools is outdated.")
	setp(NG574, "TextColor3", Color3.new(1, 1, 1))
	setp(NG574, "TextStrokeTransparency", 0.80000001192093)
	setp(NG574, "TextWrapped", true)
	setp(NG574, "Parent", NG573)
	NG575 = Instance.new("IntValue")
	setp(NG575, "Value", 65)
	setp(NG575, "Parent", NG573)
	NG576 = Instance.new("Frame")
	setp(NG576, "BackgroundTransparency", 1)
	setp(NG576, "BorderSizePixel", 0)
	setp(NG576, "Name", "Help")
	setp(NG576, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG576, "Size", UDim2.new(1, 0, 1, -22))
	setp(NG576, "Visible", false)
	setp(NG576, "Parent", NG568)
	NG577 = Instance.new("TextLabel")
	setp(NG577, "BackgroundTransparency", 1)
	setp(NG577, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG577, "BorderSizePixel", 0)
	setp(NG577, "Position", UDim2.new(0, 20, 0, 0))
	setp(NG577, "Size", UDim2.new(1, -20, 1, 0))
	setp(NG577, "Font", Enum.Font.SourceSansBold)
	setp(NG577, "FontSize", Enum.FontSize.Size14)
	setp(NG577, "Text", "Own this place? Simply reinsert the Building Tools model.")
	setp(NG577, "TextColor3", Color3.new(1, 1, 1))
	setp(NG577, "TextStrokeTransparency", 0.80000001192093)
	setp(NG577, "TextWrapped", true)
	setp(NG577, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG577, "Parent", NG576)
	NG578 = Instance.new("IntValue")
	setp(NG578, "Value", 80)
	setp(NG578, "Parent", NG576)
	NG579 = Instance.new("TextLabel")
	setp(NG579, "BackgroundTransparency", 1)
	setp(NG579, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG579, "BorderSizePixel", 0)
	setp(NG579, "Position", UDim2.new(0, 60, 0, 7))
	setp(NG579, "Size", UDim2.new(1, -20, 1, 0))
	setp(NG579, "FontSize", Enum.FontSize.Size14)
	setp(NG579, "Text", "Otherwise, tell the owner to do the above.")
	setp(NG579, "TextColor3", Color3.new(1, 1, 1))
	setp(NG579, "TextStrokeTransparency", 0.80000001192093)
	setp(NG579, "TextWrapped", true)
	setp(NG579, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG579, "Parent", NG576)
	NG580 = Instance.new("Frame")
	setp(NG580, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG580, "BackgroundTransparency", 0.69999998807907)
	setp(NG580, "BorderSizePixel", 0)
	setp(NG580, "Name", "SoloWarning")
	setp(NG580, "Size", UDim2.new(1, 0, 0, 80))
	setp(NG580, "Visible", false)
	setp(NG580, "Parent", NG567)
	NG581 = Instance.new("Frame")
	setp(NG581, "BackgroundColor3", Color3.new(1, 0, 0.0156863))
	setp(NG581, "BorderSizePixel", 0)
	setp(NG581, "Name", "Bar")
	setp(NG581, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG581, "Parent", NG580)
	NG582 = Instance.new("TextButton")
	setp(NG582, "Active", true)
	setp(NG582, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG582, "BackgroundTransparency", 0.80000001192093)
	setp(NG582, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG582, "BorderSizePixel", 0)
	setp(NG582, "Name", "OKButton")
	setp(NG582, "Position", UDim2.new(0, 0, 1, -22))
	NG582.Selectable = true
	setp(NG582, "Size", UDim2.new(0.5, 0, 0, 22))
	NG582.Style = Enum.ButtonStyle.Custom
	setp(NG582, "Font", Enum.Font.Arial)
	setp(NG582, "FontSize", Enum.FontSize.Size10)
	setp(NG582, "Text", "GOT IT")
	setp(NG582, "TextColor3", Color3.new(1, 1, 1))
	setp(NG582, "Parent", NG580)
	NG583 = Instance.new("TextButton")
	setp(NG583, "Active", true)
	setp(NG583, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG583, "BackgroundTransparency", 0.80000001192093)
	setp(NG583, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG583, "BorderSizePixel", 0)
	setp(NG583, "Name", "HelpButton")
	setp(NG583, "Position", UDim2.new(0.5, 0, 1, -22))
	NG583.Selectable = true
	setp(NG583, "Size", UDim2.new(0.5, 0, 0, 22))
	NG583.Style = Enum.ButtonStyle.Custom
	setp(NG583, "Font", Enum.Font.Arial)
	setp(NG583, "FontSize", Enum.FontSize.Size10)
	setp(NG583, "Text", "WHAT CAN I DO?")
	setp(NG583, "TextColor3", Color3.new(1, 1, 1))
	setp(NG583, "Parent", NG580)
	NG584 = Instance.new("Frame")
	setp(NG584, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG584, "BackgroundTransparency", 0.75)
	setp(NG584, "BorderSizePixel", 0)
	setp(NG584, "Name", "ButtonSeparator")
	setp(NG584, "Position", UDim2.new(0.5, 0, 1, -22))
	setp(NG584, "Size", UDim2.new(0, 1, 0, 22))
	setp(NG584, "Parent", NG580)
	NG585 = Instance.new("Frame")
	setp(NG585, "BackgroundTransparency", 1)
	setp(NG585, "BorderSizePixel", 0)
	setp(NG585, "Name", "Notice")
	setp(NG585, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG585, "Size", UDim2.new(1, 0, 1, -22))
	setp(NG585, "Parent", NG580)
	NG586 = Instance.new("TextLabel")
	setp(NG586, "BackgroundTransparency", 1)
	setp(NG586, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG586, "BorderSizePixel", 0)
	setp(NG586, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG586, "Size", UDim2.new(1, -20, 1, 0))
	setp(NG586, "Font", Enum.Font.SourceSansBold)
	setp(NG586, "FontSize", Enum.FontSize.Size14)
	setp(NG586, "Text", "Some features are not available on build mode or during solo testing, including exporting.")
	setp(NG586, "TextColor3", Color3.new(1, 1, 1))
	setp(NG586, "TextStrokeTransparency", 0.80000001192093)
	setp(NG586, "TextWrapped", true)
	setp(NG586, "Parent", NG585)
	NG587 = Instance.new("IntValue")
	setp(NG587, "Value", 80)
	setp(NG587, "Parent", NG585)
	NG588 = Instance.new("Frame")
	setp(NG588, "BackgroundTransparency", 1)
	setp(NG588, "BorderSizePixel", 0)
	setp(NG588, "Name", "Help")
	setp(NG588, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG588, "Size", UDim2.new(1, 0, 1, -22))
	setp(NG588, "Visible", false)
	setp(NG588, "Parent", NG580)
	NG589 = Instance.new("TextLabel")
	setp(NG589, "BackgroundTransparency", 1)
	setp(NG589, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG589, "BorderSizePixel", 0)
	setp(NG589, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG589, "Size", UDim2.new(1, -20, 1, 0))
	setp(NG589, "Font", Enum.Font.SourceSansBold)
	setp(NG589, "FontSize", Enum.FontSize.Size14)
	setp(NG589, "Text", "For all features to be available, you should be in a game server (a regular game, or personal building server). Alternatively, you could use the Studio plugin version of Building Tools.")
	setp(NG589, "TextColor3", Color3.new(1, 1, 1))
	setp(NG589, "TextStrokeTransparency", 0.80000001192093)
	setp(NG589, "TextWrapped", true)
	setp(NG589, "Parent", NG588)
	NG590 = Instance.new("IntValue")
	setp(NG590, "Value", 110)
	setp(NG590, "Parent", NG588)
	NG591 = Instance.new("Frame")
	setp(NG591, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG591, "BackgroundTransparency", 0.69999998807907)
	setp(NG591, "BorderSizePixel", 0)
	setp(NG591, "Name", "PluginUpdateNotification")
	setp(NG591, "Size", UDim2.new(1, 0, 0, 65))
	setp(NG591, "Visible", false)
	setp(NG591, "Parent", NG567)
	NG592 = Instance.new("Frame")
	setp(NG592, "BackgroundColor3", Color3.new(1, 0.666667, 0))
	setp(NG592, "BorderSizePixel", 0)
	setp(NG592, "Name", "Bar")
	setp(NG592, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG592, "Parent", NG591)
	NG593 = Instance.new("TextButton")
	setp(NG593, "Active", true)
	setp(NG593, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG593, "BackgroundTransparency", 0.80000001192093)
	setp(NG593, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG593, "BorderSizePixel", 0)
	setp(NG593, "Name", "OKButton")
	setp(NG593, "Position", UDim2.new(0, 0, 1, -22))
	NG593.Selectable = true
	setp(NG593, "Size", UDim2.new(0.5, 0, 0, 22))
	NG593.Style = Enum.ButtonStyle.Custom
	setp(NG593, "Font", Enum.Font.Arial)
	setp(NG593, "FontSize", Enum.FontSize.Size10)
	setp(NG593, "Text", "GOT IT")
	setp(NG593, "TextColor3", Color3.new(1, 1, 1))
	setp(NG593, "Parent", NG591)
	NG594 = Instance.new("TextButton")
	setp(NG594, "Active", true)
	setp(NG594, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG594, "BackgroundTransparency", 0.80000001192093)
	setp(NG594, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG594, "BorderSizePixel", 0)
	setp(NG594, "Name", "HelpButton")
	setp(NG594, "Position", UDim2.new(0.5, 0, 1, -22))
	NG594.Selectable = true
	setp(NG594, "Size", UDim2.new(0.5, 0, 0, 22))
	NG594.Style = Enum.ButtonStyle.Custom
	setp(NG594, "Font", Enum.Font.Arial)
	setp(NG594, "FontSize", Enum.FontSize.Size10)
	setp(NG594, "Text", "WHAT CAN I DO?")
	setp(NG594, "TextColor3", Color3.new(1, 1, 1))
	setp(NG594, "Parent", NG591)
	NG595 = Instance.new("Frame")
	setp(NG595, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG595, "BackgroundTransparency", 0.75)
	setp(NG595, "BorderSizePixel", 0)
	setp(NG595, "Name", "ButtonSeparator")
	setp(NG595, "Position", UDim2.new(0.5, 0, 1, -22))
	setp(NG595, "Size", UDim2.new(0, 1, 0, 22))
	setp(NG595, "Parent", NG591)
	NG596 = Instance.new("Frame")
	setp(NG596, "BackgroundTransparency", 1)
	setp(NG596, "BorderSizePixel", 0)
	setp(NG596, "Name", "Notice")
	setp(NG596, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG596, "Size", UDim2.new(1, 0, 1, -22))
	setp(NG596, "Parent", NG591)
	NG597 = Instance.new("TextLabel")
	setp(NG597, "BackgroundTransparency", 1)
	setp(NG597, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG597, "BorderSizePixel", 0)
	setp(NG597, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG597, "Font", Enum.Font.SourceSansBold)
	setp(NG597, "FontSize", Enum.FontSize.Size14)
	setp(NG597, "Text", "This version of Building Tools is outdated.")
	setp(NG597, "TextColor3", Color3.new(1, 1, 1))
	setp(NG597, "TextStrokeTransparency", 0.80000001192093)
	setp(NG597, "TextWrapped", true)
	setp(NG597, "Parent", NG596)
	NG598 = Instance.new("IntValue")
	setp(NG598, "Value", 65)
	setp(NG598, "Parent", NG596)
	NG599 = Instance.new("Frame")
	setp(NG599, "BackgroundTransparency", 1)
	setp(NG599, "BorderSizePixel", 0)
	setp(NG599, "Name", "Help")
	setp(NG599, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG599, "Size", UDim2.new(1, 0, 1, -22))
	setp(NG599, "Visible", false)
	setp(NG599, "Parent", NG591)
	NG600 = Instance.new("TextLabel")
	setp(NG600, "BackgroundTransparency", 1)
	setp(NG600, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG600, "BorderSizePixel", 0)
	setp(NG600, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG600, "Size", UDim2.new(1, -20, 1, 0))
	setp(NG600, "Font", Enum.Font.SourceSansBold)
	setp(NG600, "FontSize", Enum.FontSize.Size14)
	setp(NG600, "Text", "Go to Tools > Manage Plugins or Plugins > Manage Plugins to update plugins  :)")
	setp(NG600, "TextColor3", Color3.new(1, 1, 1))
	setp(NG600, "TextStrokeTransparency", 0.80000001192093)
	setp(NG600, "TextWrapped", true)
	setp(NG600, "Parent", NG599)
	NG601 = Instance.new("IntValue")
	setp(NG601, "Value", 80)
	setp(NG601, "Parent", NG599)
	NG602 = Instance.new("Frame")
	setp(NG602, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG602, "BackgroundTransparency", 0.69999998807907)
	setp(NG602, "BorderSizePixel", 0)
	setp(NG602, "Name", "HttpDisabledWarning")
	setp(NG602, "Size", UDim2.new(1, 0, 0, 80))
	setp(NG602, "Visible", false)
	setp(NG602, "Parent", NG567)
	NG603 = Instance.new("Frame")
	setp(NG603, "BackgroundColor3", Color3.new(1, 0, 0.0156863))
	setp(NG603, "BorderSizePixel", 0)
	setp(NG603, "Name", "Bar")
	setp(NG603, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG603, "Parent", NG602)
	NG604 = Instance.new("TextButton")
	setp(NG604, "Active", true)
	setp(NG604, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG604, "BackgroundTransparency", 0.80000001192093)
	setp(NG604, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG604, "BorderSizePixel", 0)
	setp(NG604, "Name", "OKButton")
	setp(NG604, "Position", UDim2.new(0, 0, 1, -22))
	NG604.Selectable = true
	setp(NG604, "Size", UDim2.new(0.5, 0, 0, 22))
	NG604.Style = Enum.ButtonStyle.Custom
	setp(NG604, "Font", Enum.Font.Arial)
	setp(NG604, "FontSize", Enum.FontSize.Size10)
	setp(NG604, "Text", "GOT IT")
	setp(NG604, "TextColor3", Color3.new(1, 1, 1))
	setp(NG604, "Parent", NG602)
	NG605 = Instance.new("TextButton")
	setp(NG605, "Active", true)
	setp(NG605, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG605, "BackgroundTransparency", 0.80000001192093)
	setp(NG605, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG605, "BorderSizePixel", 0)
	setp(NG605, "Name", "HelpButton")
	setp(NG605, "Position", UDim2.new(0.5, 0, 1, -22))
	NG605.Selectable = true
	setp(NG605, "Size", UDim2.new(0.5, 0, 0, 22))
	NG605.Style = Enum.ButtonStyle.Custom
	setp(NG605, "Font", Enum.Font.Arial)
	setp(NG605, "FontSize", Enum.FontSize.Size10)
	setp(NG605, "Text", "WHAT CAN I DO?")
	setp(NG605, "TextColor3", Color3.new(1, 1, 1))
	setp(NG605, "Parent", NG602)
	NG606 = Instance.new("Frame")
	setp(NG606, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG606, "BackgroundTransparency", 0.75)
	setp(NG606, "BorderSizePixel", 0)
	setp(NG606, "Name", "ButtonSeparator")
	setp(NG606, "Position", UDim2.new(0.5, 0, 1, -22))
	setp(NG606, "Size", UDim2.new(0, 1, 0, 22))
	setp(NG606, "Parent", NG602)
	NG607 = Instance.new("Frame")
	setp(NG607, "BackgroundTransparency", 1)
	setp(NG607, "BorderSizePixel", 0)
	setp(NG607, "Name", "Notice")
	setp(NG607, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG607, "Size", UDim2.new(1, 0, 1, -22))
	setp(NG607, "Parent", NG602)
	NG608 = Instance.new("TextLabel")
	setp(NG608, "BackgroundTransparency", 1)
	setp(NG608, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG608, "BorderSizePixel", 0)
	setp(NG608, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG608, "Font", Enum.Font.SourceSansBold)
	setp(NG608, "FontSize", Enum.FontSize.Size14)
	setp(NG608, "Text", "Oh no fam! HttpService isn't working on your client. Some features of this hacky f3x tool won't work, including exporting.")
	setp(NG608, "TextColor3", Color3.new(1, 1, 1))
	setp(NG608, "TextStrokeTransparency", 0.80000001192093)
	setp(NG608, "TextWrapped", true)
	setp(NG608, "Parent", NG607)
	NG609 = Instance.new("IntValue")
	setp(NG609, "Value", 80)
	setp(NG609, "Parent", NG607)
	NG610 = Instance.new("Frame")
	setp(NG610, "BackgroundTransparency", 1)
	setp(NG610, "BorderSizePixel", 0)
	setp(NG610, "Name", "Help")
	setp(NG610, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG610, "Size", UDim2.new(1, 0, 1, -22))
	setp(NG610, "Visible", false)
	setp(NG610, "Parent", NG602)
	NG611 = Instance.new("TextLabel")
	setp(NG611, "BackgroundTransparency", 1)
	setp(NG611, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG611, "BorderSizePixel", 0)
	setp(NG611, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG611, "Size", UDim2.new(1, -20, 0.699999988, 0))
	setp(NG611, "Font", Enum.Font.SourceSansBold)
	setp(NG611, "FontSize", Enum.FontSize.Size14)
	setp(NG611, "Text", "There is nothing you can do, it is essentially only able to work if your exploit is able to load HttpService.")
	setp(NG611, "TextColor3", Color3.new(1, 1, 1))
	setp(NG611, "TextStrokeTransparency", 0.80000001192093)
	setp(NG611, "TextWrapped", true)
	setp(NG611, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG611, "Parent", NG610)
	NG612 = Instance.new("TextLabel")
	setp(NG612, "BackgroundTransparency", 1)
	setp(NG612, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG612, "BorderSizePixel", 0)
	setp(NG612, "Position", UDim2.new(0, 10, 0.649999976, 0))
	setp(NG612, "Size", UDim2.new(1, -10, 0.300000012, 0))
	setp(NG612, "FontSize", Enum.FontSize.Size14)
	setp(NG612, "Text", "Credits: Nickoakz\nUpdates: ltseverydayyou")
	setp(NG612, "TextColor3", Color3.new(1, 1, 1))
	setp(NG612, "TextStrokeTransparency", 0.80000001192093)
	setp(NG612, "TextWrapped", true)
	setp(NG612, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG612, "Parent", NG610)
	NG613 = Instance.new("IntValue")
	setp(NG613, "Value", 110)
	setp(NG613, "Parent", NG610)
	NG614 = Instance.new("Frame")
	setp(NG614, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG614, "BackgroundTransparency", 0.69999998807907)
	setp(NG614, "BorderSizePixel", 0)
	setp(NG614, "Name", "HttpEnabledWarning")
	setp(NG614, "Size", UDim2.new(1, 0, 0, 80))
	setp(NG614, "Visible", false)
	setp(NG614, "Parent", NG567)
	NG615 = Instance.new("Frame")
	setp(NG615, "BackgroundColor3", Color3.new(0, 0.666667, 0))
	setp(NG615, "BorderSizePixel", 0)
	setp(NG615, "Name", "Bar")
	setp(NG615, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG615, "Parent", NG614)
	NG616 = Instance.new("TextButton")
	setp(NG616, "Active", true)
	setp(NG616, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG616, "BackgroundTransparency", 0.80000001192093)
	setp(NG616, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG616, "BorderSizePixel", 0)
	setp(NG616, "Name", "OKButton")
	setp(NG616, "Position", UDim2.new(0, 0, 1, -22))
	NG616.Selectable = true
	setp(NG616, "Size", UDim2.new(0.5, 0, 0, 22))
	NG616.Style = Enum.ButtonStyle.Custom
	setp(NG616, "Font", Enum.Font.Arial)
	setp(NG616, "FontSize", Enum.FontSize.Size10)
	setp(NG616, "Text", "GOT IT")
	setp(NG616, "TextColor3", Color3.new(1, 1, 1))
	setp(NG616, "Parent", NG614)
	NG617 = Instance.new("TextButton")
	setp(NG617, "Active", true)
	setp(NG617, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG617, "BackgroundTransparency", 0.80000001192093)
	setp(NG617, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG617, "BorderSizePixel", 0)
	setp(NG617, "Name", "HelpButton")
	setp(NG617, "Position", UDim2.new(0.5, 0, 1, -22))
	NG617.Selectable = true
	setp(NG617, "Size", UDim2.new(0.5, 0, 0, 22))
	NG617.Style = Enum.ButtonStyle.Custom
	setp(NG617, "Font", Enum.Font.Arial)
	setp(NG617, "FontSize", Enum.FontSize.Size10)
	setp(NG617, "Text", "WAIT WHAT?")
	setp(NG617, "TextColor3", Color3.new(1, 1, 1))
	setp(NG617, "Parent", NG614)
	NG618 = Instance.new("Frame")
	setp(NG618, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG618, "BackgroundTransparency", 0.75)
	setp(NG618, "BorderSizePixel", 0)
	setp(NG618, "Name", "ButtonSeparator")
	setp(NG618, "Position", UDim2.new(0.5, 0, 1, -22))
	setp(NG618, "Size", UDim2.new(0, 1, 0, 22))
	setp(NG618, "Parent", NG614)
	NG619 = Instance.new("Frame")
	setp(NG619, "BackgroundTransparency", 1)
	setp(NG619, "BorderSizePixel", 0)
	setp(NG619, "Name", "Notice")
	setp(NG619, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG619, "Size", UDim2.new(1, 0, 1, -22))
	setp(NG619, "Parent", NG614)
	NG620 = Instance.new("TextLabel")
	setp(NG620, "BackgroundTransparency", 1)
	setp(NG620, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG620, "BorderSizePixel", 0)
	setp(NG620, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG620, "Font", Enum.Font.SourceSansBold)
	setp(NG620, "FontSize", Enum.FontSize.Size14)
	setp(NG620, "Text", "WOO FAM! HttpService works for your client! You'll be able to steal parts from this game using this exploit :)")
	setp(NG620, "TextColor3", Color3.new(1, 1, 1))
	setp(NG620, "TextStrokeTransparency", 0.80000001192093)
	setp(NG620, "TextWrapped", true)
	setp(NG620, "Parent", NG619)
	NG621 = Instance.new("IntValue")
	setp(NG621, "Value", 80)
	setp(NG621, "Parent", NG619)
	NG622 = Instance.new("Frame")
	setp(NG622, "BackgroundTransparency", 1)
	setp(NG622, "BorderSizePixel", 0)
	setp(NG622, "Name", "Help")
	setp(NG622, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG622, "Size", UDim2.new(1, 0, 1, -22))
	setp(NG622, "Visible", false)
	setp(NG622, "Parent", NG614)
	NG623 = Instance.new("TextLabel")
	setp(NG623, "BackgroundTransparency", 1)
	setp(NG623, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG623, "BorderSizePixel", 0)
	setp(NG623, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG623, "Size", UDim2.new(1, -20, 0.300000012, 0))
	setp(NG623, "Font", Enum.Font.SourceSansBold)
	setp(NG623, "FontSize", Enum.FontSize.Size14)
	setp(NG623, "Text", "What do you mean that HTTPService is on?")
	setp(NG623, "TextColor3", Color3.new(1, 1, 1))
	setp(NG623, "TextStrokeTransparency", 0.80000001192093)
	setp(NG623, "TextWrapped", true)
	setp(NG623, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG623, "Parent", NG622)
	NG624 = Instance.new("TextLabel")
	setp(NG624, "BackgroundTransparency", 1)
	setp(NG624, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG624, "BorderSizePixel", 0)
	setp(NG624, "Position", UDim2.new(0, 10, 0.200000003, 0))
	setp(NG624, "Size", UDim2.new(1, -10, 0.800000012, 0))
	setp(NG624, "FontSize", Enum.FontSize.Size14)
	setp(NG624, "Text", "Well umm, you can select a ton of parts ingame, and export it through this hacky f3x tool, and be able to steal them through Roblox Studio? Yeah, thats cool fam!")
	setp(NG624, "TextColor3", Color3.new(1, 1, 1))
	setp(NG624, "TextStrokeTransparency", 0.80000001192093)
	setp(NG624, "TextWrapped", true)
	setp(NG624, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG624, "Parent", NG622)
	NG625 = Instance.new("IntValue")
	setp(NG625, "Value", 110)
	setp(NG625, "Parent", NG622)
	NG626 = Instance.new("Frame")
	setp(NG626, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG626, "BackgroundTransparency", 0.69999998807907)
	setp(NG626, "BorderSizePixel", 0)
	setp(NG626, "Name", "WelcomeFex")
	setp(NG626, "Size", UDim2.new(1, 0, 0, 80))
	setp(NG626, "Visible", false)
	setp(NG626, "Parent", NG567)
	NG627 = Instance.new("TextButton")
	setp(NG627, "Active", true)
	setp(NG627, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG627, "BackgroundTransparency", 0.80000001192093)
	setp(NG627, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG627, "BorderSizePixel", 0)
	setp(NG627, "Name", "OKButton")
	setp(NG627, "Position", UDim2.new(0, 0, 1, -22))
	NG627.Selectable = true
	setp(NG627, "Size", UDim2.new(0.5, 0, 0, 22))
	NG627.Style = Enum.ButtonStyle.Custom
	setp(NG627, "Font", Enum.Font.Arial)
	setp(NG627, "FontSize", Enum.FontSize.Size10)
	setp(NG627, "Text", "GOT IT")
	setp(NG627, "TextColor3", Color3.new(1, 1, 1))
	setp(NG627, "Parent", NG626)
	NG628 = Instance.new("TextButton")
	setp(NG628, "Active", true)
	setp(NG628, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG628, "BackgroundTransparency", 0.80000001192093)
	setp(NG628, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG628, "BorderSizePixel", 0)
	setp(NG628, "Name", "HelpButton")
	setp(NG628, "Position", UDim2.new(0.5, 0, 1, -22))
	NG628.Selectable = true
	setp(NG628, "Size", UDim2.new(0.5, 0, 0, 22))
	NG628.Style = Enum.ButtonStyle.Custom
	setp(NG628, "Font", Enum.Font.Arial)
	setp(NG628, "FontSize", Enum.FontSize.Size10)
	setp(NG628, "Text", "WHAT CAN I DO?")
	setp(NG628, "TextColor3", Color3.new(1, 1, 1))
	setp(NG628, "Parent", NG626)
	NG629 = Instance.new("Frame")
	setp(NG629, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG629, "BackgroundTransparency", 0.75)
	setp(NG629, "BorderSizePixel", 0)
	setp(NG629, "Name", "ButtonSeparator")
	setp(NG629, "Position", UDim2.new(0.5, 0, 1, -22))
	setp(NG629, "Size", UDim2.new(0, 1, 0, 22))
	setp(NG629, "Parent", NG626)
	NG630 = Instance.new("Frame")
	setp(NG630, "BackgroundTransparency", 1)
	setp(NG630, "BorderSizePixel", 0)
	setp(NG630, "Name", "Notice")
	setp(NG630, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG630, "Size", UDim2.new(1, 0, 1, -22))
	setp(NG630, "Parent", NG626)
	NG631 = Instance.new("TextLabel")
	setp(NG631, "BackgroundTransparency", 1)
	setp(NG631, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG631, "BorderSizePixel", 0)
	setp(NG631, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG631, "Font", Enum.Font.SourceSansBold)
	setp(NG631, "FontSize", Enum.FontSize.Size14)
	setp(NG631, "Text", "F3X is running\nMade by Nickoakz\nFixed by ltseverydayyou")
	setp(NG631, "TextColor3", Color3.new(1, 1, 1))
	setp(NG631, "TextStrokeTransparency", 0.80000001192093)
	setp(NG631, "TextWrapped", true)
	setp(NG631, "Parent", NG630)
	NG632 = Instance.new("IntValue")
	setp(NG632, "Value", 80)
	setp(NG632, "Parent", NG630)
	NG633 = Instance.new("Frame")
	setp(NG633, "BackgroundTransparency", 1)
	setp(NG633, "BorderSizePixel", 0)
	setp(NG633, "Name", "Help")
	setp(NG633, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG633, "Size", UDim2.new(1, 0, 1, -22))
	setp(NG633, "Visible", false)
	setp(NG633, "Parent", NG626)
	NG634 = Instance.new("TextLabel")
	setp(NG634, "BackgroundTransparency", 1)
	setp(NG634, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG634, "BorderSizePixel", 0)
	setp(NG634, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG634, "Size", UDim2.new(1, -20, 0.699999988, 0))
	setp(NG634, "Font", Enum.Font.SourceSansBold)
	setp(NG634, "FontSize", Enum.FontSize.Size14)
	setp(NG634, "Text", "Have fun?")
	setp(NG634, "TextColor3", Color3.new(1, 1, 1))
	setp(NG634, "TextStrokeTransparency", 0.80000001192093)
	setp(NG634, "TextWrapped", true)
	setp(NG634, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG634, "Parent", NG633)
	NG635 = Instance.new("TextLabel")
	setp(NG635, "BackgroundTransparency", 1)
	setp(NG635, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG635, "BorderSizePixel", 0)
	setp(NG635, "Position", UDim2.new(0, 10, 0.649999976, 0))
	setp(NG635, "Size", UDim2.new(1, -10, 0.300000012, 0))
	setp(NG635, "FontSize", Enum.FontSize.Size14)
	setp(NG635, "Text", "~Nickoakz")
	setp(NG635, "TextColor3", Color3.new(1, 1, 1))
	setp(NG635, "TextStrokeTransparency", 0.80000001192093)
	setp(NG635, "TextWrapped", true)
	setp(NG635, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG635, "Parent", NG633)
	NG636 = Instance.new("IntValue")
	setp(NG636, "Value", 110)
	setp(NG636, "Parent", NG633)
	NG637 = Instance.new("Frame")
	setp(NG637, "BackgroundTransparency", 1)
	setp(NG637, "BorderSizePixel", 0)
	setp(NG637, "Name", "BottomColorBar")
	setp(NG637, "Position", UDim2.new(0, 0, 1, 0))
	NG637.Rotation = 180
	setp(NG637, "Size", UDim2.new(1, 0, 0, 3))
	setp(NG637, "Parent", NG626)
	NG638 = Instance.new("Frame")
	setp(NG638, "BackgroundColor3", Color3.new(1, 0.686275, 0))
	setp(NG638, "BackgroundTransparency", 0.25)
	setp(NG638, "BorderSizePixel", 0)
	setp(NG638, "Name", "Yellow")
	setp(NG638, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG638, "Parent", NG637)
	NG639 = Instance.new("Frame")
	setp(NG639, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG639, "BackgroundTransparency", 0.25)
	setp(NG639, "BorderSizePixel", 0)
	setp(NG639, "Name", "Green")
	setp(NG639, "Position", UDim2.new(0.200000003, 0, 0, 0))
	setp(NG639, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG639, "Parent", NG637)
	NG640 = Instance.new("Frame")
	setp(NG640, "BackgroundColor3", Color3.new(0.0156863, 0.686275, 0.92549))
	setp(NG640, "BackgroundTransparency", 0.25)
	setp(NG640, "BorderSizePixel", 0)
	setp(NG640, "Name", "Blue")
	setp(NG640, "Position", UDim2.new(0.400000006, 0, 0, 0))
	setp(NG640, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG640, "Parent", NG637)
	NG641 = Instance.new("Frame")
	setp(NG641, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG641, "BackgroundTransparency", 0.25)
	setp(NG641, "BorderSizePixel", 0)
	setp(NG641, "Name", "Red")
	setp(NG641, "Position", UDim2.new(0.600000024, 0, 0, 0))
	setp(NG641, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG641, "Parent", NG637)
	NG642 = Instance.new("Frame")
	setp(NG642, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG642, "BackgroundTransparency", 0.25)
	setp(NG642, "BorderSizePixel", 0)
	setp(NG642, "Name", "Purple")
	setp(NG642, "Position", UDim2.new(0.800000012, 0, 0, 0))
	setp(NG642, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG642, "Parent", NG637)
	NG643 = Instance.new("Frame")
	setp(NG643, "BackgroundTransparency", 1)
	setp(NG643, "BorderSizePixel", 0)
	setp(NG643, "Name", "TopColorBar")
	setp(NG643, "Position", UDim2.new(0, 0, 0, -2))
	NG643.Rotation = 180
	setp(NG643, "Size", UDim2.new(1, 0, 0, 3))
	setp(NG643, "Parent", NG626)
	NG644 = Instance.new("Frame")
	setp(NG644, "BackgroundColor3", Color3.new(1, 0.686275, 0))
	setp(NG644, "BackgroundTransparency", 0.25)
	setp(NG644, "BorderSizePixel", 0)
	setp(NG644, "Name", "Yellow")
	setp(NG644, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG644, "Parent", NG643)
	NG645 = Instance.new("Frame")
	setp(NG645, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG645, "BackgroundTransparency", 0.25)
	setp(NG645, "BorderSizePixel", 0)
	setp(NG645, "Name", "Green")
	setp(NG645, "Position", UDim2.new(0.200000003, 0, 0, 0))
	setp(NG645, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG645, "Parent", NG643)
	NG646 = Instance.new("Frame")
	setp(NG646, "BackgroundColor3", Color3.new(0.0156863, 0.686275, 0.92549))
	setp(NG646, "BackgroundTransparency", 0.25)
	setp(NG646, "BorderSizePixel", 0)
	setp(NG646, "Name", "Blue")
	setp(NG646, "Position", UDim2.new(0.400000006, 0, 0, 0))
	setp(NG646, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG646, "Parent", NG643)
	NG647 = Instance.new("Frame")
	setp(NG647, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG647, "BackgroundTransparency", 0.25)
	setp(NG647, "BorderSizePixel", 0)
	setp(NG647, "Name", "Red")
	setp(NG647, "Position", UDim2.new(0.600000024, 0, 0, 0))
	setp(NG647, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG647, "Parent", NG643)
	NG648 = Instance.new("Frame")
	setp(NG648, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG648, "BackgroundTransparency", 0.25)
	setp(NG648, "BorderSizePixel", 0)
	setp(NG648, "Name", "Purple")
	setp(NG648, "Position", UDim2.new(0.800000012, 0, 0, 0))
	setp(NG648, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG648, "Parent", NG643)
	NG649 = Instance.new("Frame")
	setp(NG649, "Active", true)
	setp(NG649, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG649, "BackgroundTransparency", 1)
	setp(NG649, "BorderColor3", Color3.new(0.137255, 0.137255, 0.137255))
	setp(NG649, "BorderSizePixel", 0)
	setp(NG649, "Name", "BTDockGUI")
	setp(NG649, "Position", UDim2.new(0.699999988, 0, 0.300000012, 0))
	setp(NG649, "Size", UDim2.new(0, 70, 0, 380))
	NG649.Draggable = true
	setp(NG649, "Parent", NG1)
	NG650 = Instance.new("Frame")
	setp(NG650, "BackgroundTransparency", 1)
	setp(NG650, "BorderSizePixel", 0)
	setp(NG650, "Name", "Tooltips")
	setp(NG650, "Position", UDim2.new(0, -120, 0, 0))
	setp(NG650, "Size", UDim2.new(0, 120, 0, 315))
	setp(NG650, "Parent", NG649)
	NG651 = Instance.new("Frame")
	setp(NG651, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG651, "BackgroundTransparency", 0.20000000298023)
	setp(NG651, "BorderSizePixel", 0)
	setp(NG651, "Name", "PaintInfo")
	setp(NG651, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG651, "Visible", false)
	setp(NG651, "Parent", NG650)
	NG652 = Instance.new("Frame")
	setp(NG652, "BackgroundTransparency", 1)
	setp(NG652, "BorderSizePixel", 0)
	setp(NG652, "Name", "Content")
	setp(NG652, "Size", UDim2.new(1, 0, 0, 70))
	setp(NG652, "Parent", NG651)
	NG653 = Instance.new("Frame")
	setp(NG653, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG653, "BorderSizePixel", 0)
	setp(NG653, "Name", "ColorBar")
	setp(NG653, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG653, "Parent", NG652)
	NG654 = Instance.new("TextLabel")
	setp(NG654, "BackgroundTransparency", 1)
	setp(NG654, "BorderSizePixel", 0)
	setp(NG654, "Name", "ToolDescription")
	setp(NG654, "Position", UDim2.new(0, 10, 0, 25))
	setp(NG654, "Size", UDim2.new(0, 82, 0, 50))
	setp(NG654, "Font", Enum.Font.Arial)
	setp(NG654, "FontSize", Enum.FontSize.Size10)
	setp(NG654, "Text", "Allows you to change the color of parts.")
	setp(NG654, "TextColor3", Color3.new(1, 1, 1))
	setp(NG654, "TextWrapped", true)
	setp(NG654, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG654, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG654, "Parent", NG652)
	NG655 = Instance.new("TextLabel")
	setp(NG655, "BackgroundTransparency", 1)
	setp(NG655, "BorderSizePixel", 0)
	setp(NG655, "Name", "ToolName")
	setp(NG655, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG655, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG655, "Font", Enum.Font.ArialBold)
	setp(NG655, "FontSize", Enum.FontSize.Size10)
	setp(NG655, "Text", "PAINT TOOL")
	setp(NG655, "TextColor3", Color3.new(1, 1, 1))
	setp(NG655, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG655, "Parent", NG652)
	NG656 = Instance.new("Frame")
	setp(NG656, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG656, "BackgroundTransparency", 0.20000000298023)
	setp(NG656, "BorderSizePixel", 0)
	setp(NG656, "Name", "SurfaceInfo")
	setp(NG656, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG656, "Visible", false)
	setp(NG656, "Parent", NG650)
	NG657 = Instance.new("Frame")
	setp(NG657, "BackgroundTransparency", 1)
	setp(NG657, "BorderSizePixel", 0)
	setp(NG657, "Name", "Content")
	setp(NG657, "Size", UDim2.new(1, 0, 0, 150))
	setp(NG657, "Parent", NG656)
	NG658 = Instance.new("Frame")
	setp(NG658, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG658, "BorderSizePixel", 0)
	setp(NG658, "Name", "ColorBar")
	setp(NG658, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG658, "Parent", NG657)
	NG659 = Instance.new("TextLabel")
	setp(NG659, "BackgroundTransparency", 1)
	setp(NG659, "BorderSizePixel", 0)
	setp(NG659, "Name", "ToolDescription")
	setp(NG659, "Position", UDim2.new(0, 10, 0, 25))
	setp(NG659, "Size", UDim2.new(0, 82, 0, 120))
	setp(NG659, "Font", Enum.Font.Arial)
	setp(NG659, "FontSize", Enum.FontSize.Size10)
	setp(NG659, "Text", "Lets you change the surface type of parts.  TIP: You can select the side to change by right clicking on a part's side.")
	setp(NG659, "TextColor3", Color3.new(1, 1, 1))
	setp(NG659, "TextWrapped", true)
	setp(NG659, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG659, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG659, "Parent", NG657)
	NG660 = Instance.new("TextLabel")
	setp(NG660, "BackgroundTransparency", 1)
	setp(NG660, "BorderSizePixel", 0)
	setp(NG660, "Name", "ToolName")
	setp(NG660, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG660, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG660, "Font", Enum.Font.ArialBold)
	setp(NG660, "FontSize", Enum.FontSize.Size10)
	setp(NG660, "Text", "SURFACE TOOL")
	setp(NG660, "TextColor3", Color3.new(1, 1, 1))
	setp(NG660, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG660, "Parent", NG657)
	NG661 = Instance.new("Frame")
	setp(NG661, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG661, "BackgroundTransparency", 0.20000000298023)
	setp(NG661, "BorderSizePixel", 0)
	setp(NG661, "Name", "MaterialInfo")
	setp(NG661, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG661, "Visible", false)
	setp(NG661, "Parent", NG650)
	NG662 = Instance.new("Frame")
	setp(NG662, "BackgroundTransparency", 1)
	setp(NG662, "BorderSizePixel", 0)
	setp(NG662, "Name", "Content")
	setp(NG662, "Size", UDim2.new(1, 0, 0, 150))
	setp(NG662, "Parent", NG661)
	NG663 = Instance.new("Frame")
	setp(NG663, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG663, "BorderSizePixel", 0)
	setp(NG663, "Name", "ColorBar")
	setp(NG663, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG663, "Parent", NG662)
	NG664 = Instance.new("TextLabel")
	setp(NG664, "BackgroundTransparency", 1)
	setp(NG664, "BorderSizePixel", 0)
	setp(NG664, "Name", "ToolDescription")
	setp(NG664, "Position", UDim2.new(0, 10, 0, 25))
	setp(NG664, "Size", UDim2.new(0, 80, 0, 120))
	setp(NG664, "Font", Enum.Font.Arial)
	setp(NG664, "FontSize", Enum.FontSize.Size10)
	setp(NG664, "Text", "Lets you change the material, transparency, and reflectance of parts.")
	setp(NG664, "TextColor3", Color3.new(1, 1, 1))
	setp(NG664, "TextWrapped", true)
	setp(NG664, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG664, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG664, "Parent", NG662)
	NG665 = Instance.new("TextLabel")
	setp(NG665, "BackgroundTransparency", 1)
	setp(NG665, "BorderSizePixel", 0)
	setp(NG665, "Name", "ToolName")
	setp(NG665, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG665, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG665, "Font", Enum.Font.ArialBold)
	setp(NG665, "FontSize", Enum.FontSize.Size10)
	setp(NG665, "Text", "MATERIAL TOOL")
	setp(NG665, "TextColor3", Color3.new(1, 1, 1))
	setp(NG665, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG665, "Parent", NG662)
	NG666 = Instance.new("Frame")
	setp(NG666, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG666, "BackgroundTransparency", 0.20000000298023)
	setp(NG666, "BorderSizePixel", 0)
	setp(NG666, "Name", "CollisionInfo")
	setp(NG666, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG666, "Visible", false)
	setp(NG666, "Parent", NG650)
	NG667 = Instance.new("Frame")
	setp(NG667, "BackgroundTransparency", 1)
	setp(NG667, "BorderSizePixel", 0)
	setp(NG667, "Name", "Content")
	setp(NG667, "Size", UDim2.new(1, 0, 0, 150))
	setp(NG667, "Parent", NG666)
	NG668 = Instance.new("Frame")
	setp(NG668, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG668, "BorderSizePixel", 0)
	setp(NG668, "Name", "ColorBar")
	setp(NG668, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG668, "Parent", NG667)
	NG669 = Instance.new("TextLabel")
	setp(NG669, "BackgroundTransparency", 1)
	setp(NG669, "BorderSizePixel", 0)
	setp(NG669, "Name", "ToolDescription")
	setp(NG669, "Position", UDim2.new(0, 10, 0, 25))
	setp(NG669, "Size", UDim2.new(0, 80, 0, 120))
	setp(NG669, "Font", Enum.Font.Arial)
	setp(NG669, "FontSize", Enum.FontSize.Size10)
	setp(NG669, "Text", "Lets you change whether the parts collide with others or not.  TIP: You can toggle collision by pressing Enter.")
	setp(NG669, "TextColor3", Color3.new(1, 1, 1))
	setp(NG669, "TextWrapped", true)
	setp(NG669, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG669, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG669, "Parent", NG667)
	NG670 = Instance.new("TextLabel")
	setp(NG670, "BackgroundTransparency", 1)
	setp(NG670, "BorderSizePixel", 0)
	setp(NG670, "Name", "ToolName")
	setp(NG670, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG670, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG670, "Font", Enum.Font.ArialBold)
	setp(NG670, "FontSize", Enum.FontSize.Size10)
	setp(NG670, "Text", "COLLISION TOOL")
	setp(NG670, "TextColor3", Color3.new(1, 1, 1))
	setp(NG670, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG670, "Parent", NG667)
	NG671 = Instance.new("Frame")
	setp(NG671, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG671, "BackgroundTransparency", 0.20000000298023)
	setp(NG671, "BorderSizePixel", 0)
	setp(NG671, "Name", "AnchorInfo")
	setp(NG671, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG671, "Visible", false)
	setp(NG671, "Parent", NG650)
	NG672 = Instance.new("Frame")
	setp(NG672, "BackgroundTransparency", 1)
	setp(NG672, "BorderSizePixel", 0)
	setp(NG672, "Name", "Content")
	setp(NG672, "Size", UDim2.new(1, 0, 0, 150))
	setp(NG672, "Parent", NG671)
	NG673 = Instance.new("Frame")
	setp(NG673, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG673, "BorderSizePixel", 0)
	setp(NG673, "Name", "ColorBar")
	setp(NG673, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG673, "Parent", NG672)
	NG674 = Instance.new("TextLabel")
	setp(NG674, "BackgroundTransparency", 1)
	setp(NG674, "BorderSizePixel", 0)
	setp(NG674, "Name", "ToolDescription")
	setp(NG674, "Position", UDim2.new(0, 10, 0, 25))
	setp(NG674, "Size", UDim2.new(0, 80, 0, 120))
	setp(NG674, "Font", Enum.Font.Arial)
	setp(NG674, "FontSize", Enum.FontSize.Size10)
	setp(NG674, "Text", "Lets you anchor and unanchor parts.  TIP: You can press Enter to toggle the anchor quickly.")
	setp(NG674, "TextColor3", Color3.new(1, 1, 1))
	setp(NG674, "TextWrapped", true)
	setp(NG674, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG674, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG674, "Parent", NG672)
	NG675 = Instance.new("TextLabel")
	setp(NG675, "BackgroundTransparency", 1)
	setp(NG675, "BorderSizePixel", 0)
	setp(NG675, "Name", "ToolName")
	setp(NG675, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG675, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG675, "Font", Enum.Font.ArialBold)
	setp(NG675, "FontSize", Enum.FontSize.Size10)
	setp(NG675, "Text", "ANCHOR TOOL")
	setp(NG675, "TextColor3", Color3.new(1, 1, 1))
	setp(NG675, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG675, "Parent", NG672)
	NG676 = Instance.new("Frame")
	setp(NG676, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG676, "BackgroundTransparency", 0.20000000298023)
	setp(NG676, "BorderSizePixel", 0)
	setp(NG676, "Name", "NewPartInfo")
	setp(NG676, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG676, "Visible", false)
	setp(NG676, "Parent", NG650)
	NG677 = Instance.new("Frame")
	setp(NG677, "BackgroundTransparency", 1)
	setp(NG677, "BorderSizePixel", 0)
	setp(NG677, "Name", "Content")
	setp(NG677, "Size", UDim2.new(1, 0, 0, 150))
	setp(NG677, "Parent", NG676)
	NG678 = Instance.new("Frame")
	setp(NG678, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG678, "BorderSizePixel", 0)
	setp(NG678, "Name", "ColorBar")
	setp(NG678, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG678, "Parent", NG677)
	NG679 = Instance.new("TextLabel")
	setp(NG679, "BackgroundTransparency", 1)
	setp(NG679, "BorderSizePixel", 0)
	setp(NG679, "Name", "ToolDescription")
	setp(NG679, "Position", UDim2.new(0, 10, 0, 25))
	setp(NG679, "Size", UDim2.new(0, 80, 0, 120))
	setp(NG679, "Font", Enum.Font.Arial)
	setp(NG679, "FontSize", Enum.FontSize.Size10)
	setp(NG679, "Text", "Lets you create new parts of different types.  Select the part type, then click and drag to place the part.")
	setp(NG679, "TextColor3", Color3.new(1, 1, 1))
	setp(NG679, "TextWrapped", true)
	setp(NG679, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG679, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG679, "Parent", NG677)
	NG680 = Instance.new("TextLabel")
	setp(NG680, "BackgroundTransparency", 1)
	setp(NG680, "BorderSizePixel", 0)
	setp(NG680, "Name", "ToolName")
	setp(NG680, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG680, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG680, "Font", Enum.Font.ArialBold)
	setp(NG680, "FontSize", Enum.FontSize.Size10)
	setp(NG680, "Text", "NEW PART TOOL")
	setp(NG680, "TextColor3", Color3.new(1, 1, 1))
	setp(NG680, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG680, "Parent", NG677)
	NG681 = Instance.new("Frame")
	setp(NG681, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG681, "BackgroundTransparency", 0.20000000298023)
	setp(NG681, "BorderSizePixel", 0)
	setp(NG681, "Name", "MeshInfo")
	setp(NG681, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG681, "Visible", false)
	setp(NG681, "Parent", NG650)
	NG682 = Instance.new("Frame")
	setp(NG682, "BackgroundTransparency", 1)
	setp(NG682, "BorderSizePixel", 0)
	setp(NG682, "Name", "Content")
	setp(NG682, "Size", UDim2.new(1, 0, 0, 150))
	setp(NG682, "Parent", NG681)
	NG683 = Instance.new("Frame")
	setp(NG683, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG683, "BorderSizePixel", 0)
	setp(NG683, "Name", "ColorBar")
	setp(NG683, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG683, "Parent", NG682)
	NG684 = Instance.new("TextLabel")
	setp(NG684, "BackgroundTransparency", 1)
	setp(NG684, "BorderSizePixel", 0)
	setp(NG684, "Name", "ToolDescription")
	setp(NG684, "Position", UDim2.new(0, 10, 0, 25))
	setp(NG684, "Size", UDim2.new(0, 84, 0, 260))
	setp(NG684, "Font", Enum.Font.Arial)
	setp(NG684, "FontSize", Enum.FontSize.Size10)
	setp(NG684, "Text", "Lets you add meshes to parts.  If you're using a file mesh, you can paste the URL of anything with a mesh (e.g. a hat, gear, etc.) and it will find the right mesh/texture ID for you.  NOTE: If HttpService is not enabled, you must type the ID of the mesh/image asset directly.")
	setp(NG684, "TextColor3", Color3.new(1, 1, 1))
	setp(NG684, "TextWrapped", true)
	setp(NG684, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG684, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG684, "Parent", NG682)
	NG685 = Instance.new("TextLabel")
	setp(NG685, "BackgroundTransparency", 1)
	setp(NG685, "BorderSizePixel", 0)
	setp(NG685, "Name", "ToolName")
	setp(NG685, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG685, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG685, "Font", Enum.Font.ArialBold)
	setp(NG685, "FontSize", Enum.FontSize.Size10)
	setp(NG685, "Text", "MESH TOOL")
	setp(NG685, "TextColor3", Color3.new(1, 1, 1))
	setp(NG685, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG685, "Parent", NG682)
	NG686 = Instance.new("Frame")
	setp(NG686, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG686, "BackgroundTransparency", 0.20000000298023)
	setp(NG686, "BorderSizePixel", 0)
	setp(NG686, "Name", "TextureInfo")
	setp(NG686, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG686, "Visible", false)
	setp(NG686, "Parent", NG650)
	NG687 = Instance.new("Frame")
	setp(NG687, "BackgroundTransparency", 1)
	setp(NG687, "BorderSizePixel", 0)
	setp(NG687, "Name", "Content")
	setp(NG687, "Size", UDim2.new(1, 0, 0, 150))
	setp(NG687, "Parent", NG686)
	NG688 = Instance.new("Frame")
	setp(NG688, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG688, "BorderSizePixel", 0)
	setp(NG688, "Name", "ColorBar")
	setp(NG688, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG688, "Parent", NG687)
	NG689 = Instance.new("TextLabel")
	setp(NG689, "BackgroundTransparency", 1)
	setp(NG689, "BorderSizePixel", 0)
	setp(NG689, "Name", "ToolDescription")
	setp(NG689, "Position", UDim2.new(0, 10, 0, 25))
	setp(NG689, "Size", UDim2.new(0, 84, 0, 250))
	setp(NG689, "Font", Enum.Font.Arial)
	setp(NG689, "FontSize", Enum.FontSize.Size10)
	setp(NG689, "Text", "Lets you add decals and textures to parts. Simply add a new decal or texture, and paste the URL of the decal you want to add.  TIP: You can select the decal/texture side by right clicking.  NOTE: If HttpService is not enabled, you must type the ID of the image item (not the decal). This can usually be found by subtracting one from the ID number.")
	setp(NG689, "TextColor3", Color3.new(1, 1, 1))
	setp(NG689, "TextWrapped", true)
	setp(NG689, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG689, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG689, "Parent", NG687)
	NG690 = Instance.new("TextLabel")
	setp(NG690, "BackgroundTransparency", 1)
	setp(NG690, "BorderSizePixel", 0)
	setp(NG690, "Name", "ToolName")
	setp(NG690, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG690, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG690, "Font", Enum.Font.ArialBold)
	setp(NG690, "FontSize", Enum.FontSize.Size10)
	setp(NG690, "Text", "TEXTURE TOOL")
	setp(NG690, "TextColor3", Color3.new(1, 1, 1))
	setp(NG690, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG690, "Parent", NG687)
	NG691 = Instance.new("Frame")
	setp(NG691, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG691, "BackgroundTransparency", 0.20000000298023)
	setp(NG691, "BorderSizePixel", 0)
	setp(NG691, "Name", "LightingInfo")
	setp(NG691, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG691, "Visible", false)
	setp(NG691, "Parent", NG650)
	NG692 = Instance.new("Frame")
	setp(NG692, "BackgroundTransparency", 1)
	setp(NG692, "BorderSizePixel", 0)
	setp(NG692, "Name", "Content")
	setp(NG692, "Size", UDim2.new(1, 0, 0, 100))
	setp(NG692, "Parent", NG691)
	NG693 = Instance.new("Frame")
	setp(NG693, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG693, "BorderSizePixel", 0)
	setp(NG693, "Name", "ColorBar")
	setp(NG693, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG693, "Parent", NG692)
	NG694 = Instance.new("TextLabel")
	setp(NG694, "BackgroundTransparency", 1)
	setp(NG694, "BorderSizePixel", 0)
	setp(NG694, "Name", "ToolDescription")
	setp(NG694, "Position", UDim2.new(0, 10, 0, 25))
	setp(NG694, "Size", UDim2.new(0, 80, 0, 200))
	setp(NG694, "Font", Enum.Font.Arial)
	setp(NG694, "FontSize", Enum.FontSize.Size10)
	setp(NG694, "Text", "Allows you to add spotlights or point lights to parts.")
	setp(NG694, "TextColor3", Color3.new(1, 1, 1))
	setp(NG694, "TextWrapped", true)
	setp(NG694, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG694, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG694, "Parent", NG692)
	NG695 = Instance.new("TextLabel")
	setp(NG695, "BackgroundTransparency", 1)
	setp(NG695, "BorderSizePixel", 0)
	setp(NG695, "Name", "ToolName")
	setp(NG695, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG695, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG695, "Font", Enum.Font.ArialBold)
	setp(NG695, "FontSize", Enum.FontSize.Size10)
	setp(NG695, "Text", "LIGHTING TOOL")
	setp(NG695, "TextColor3", Color3.new(1, 1, 1))
	setp(NG695, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG695, "Parent", NG692)
	NG696 = Instance.new("Frame")
	setp(NG696, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG696, "BackgroundTransparency", 0.20000000298023)
	setp(NG696, "BorderSizePixel", 0)
	setp(NG696, "Name", "DecorateInfo")
	setp(NG696, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG696, "Visible", false)
	setp(NG696, "Parent", NG650)
	NG697 = Instance.new("Frame")
	setp(NG697, "BackgroundTransparency", 1)
	setp(NG697, "BorderSizePixel", 0)
	setp(NG697, "Name", "Content")
	setp(NG697, "Size", UDim2.new(1, 0, 0, 100))
	setp(NG697, "Parent", NG696)
	NG698 = Instance.new("Frame")
	setp(NG698, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG698, "BorderSizePixel", 0)
	setp(NG698, "Name", "ColorBar")
	setp(NG698, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG698, "Parent", NG697)
	NG699 = Instance.new("TextLabel")
	setp(NG699, "BackgroundTransparency", 1)
	setp(NG699, "BorderSizePixel", 0)
	setp(NG699, "Name", "ToolDescription")
	setp(NG699, "Position", UDim2.new(0, 10, 0, 25))
	setp(NG699, "Size", UDim2.new(0, 80, 0, 200))
	setp(NG699, "Font", Enum.Font.Arial)
	setp(NG699, "FontSize", Enum.FontSize.Size10)
	setp(NG699, "Text", "Allows you to add smoke, fire, and sparkles to parts.")
	setp(NG699, "TextColor3", Color3.new(1, 1, 1))
	setp(NG699, "TextWrapped", true)
	setp(NG699, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG699, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG699, "Parent", NG697)
	NG700 = Instance.new("TextLabel")
	setp(NG700, "BackgroundTransparency", 1)
	setp(NG700, "BorderSizePixel", 0)
	setp(NG700, "Name", "ToolName")
	setp(NG700, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG700, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG700, "Font", Enum.Font.ArialBold)
	setp(NG700, "FontSize", Enum.FontSize.Size10)
	setp(NG700, "Text", "DECORATE TOOL")
	setp(NG700, "TextColor3", Color3.new(1, 1, 1))
	setp(NG700, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG700, "Parent", NG697)
	NG701 = Instance.new("Frame")
	setp(NG701, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG701, "BackgroundTransparency", 0.20000000298023)
	setp(NG701, "BorderSizePixel", 0)
	setp(NG701, "Name", "MoveInfo")
	setp(NG701, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG701, "Visible", false)
	setp(NG701, "Parent", NG650)
	NG702 = Instance.new("Frame")
	setp(NG702, "BackgroundTransparency", 1)
	setp(NG702, "BorderSizePixel", 0)
	setp(NG702, "Name", "Content")
	setp(NG702, "Size", UDim2.new(1, 0, 0, 500))
	setp(NG702, "Parent", NG701)
	NG703 = Instance.new("Frame")
	setp(NG703, "BackgroundTransparency", 1)
	setp(NG703, "BorderSizePixel", 0)
	setp(NG703, "Name", "AxesInfo")
	setp(NG703, "Position", UDim2.new(0, 0, 0, 60))
	setp(NG703, "Size", UDim2.new(1, 0, 0, 300))
	setp(NG703, "Parent", NG702)
	NG704 = Instance.new("Frame")
	setp(NG704, "BackgroundColor3", Color3.new(1, 0.666667, 0))
	setp(NG704, "BorderSizePixel", 0)
	setp(NG704, "Position", UDim2.new(0, 10, 0, 83))
	setp(NG704, "Size", UDim2.new(0, 2, 0, 123))
	setp(NG704, "Parent", NG703)
	NG705 = Instance.new("TextLabel")
	setp(NG705, "BackgroundTransparency", 1)
	setp(NG705, "BorderSizePixel", 0)
	setp(NG705, "Position", UDim2.new(0, 17, 0, 83))
	setp(NG705, "Size", UDim2.new(0, 80, 0, 180))
	setp(NG705, "Font", Enum.Font.Arial)
	setp(NG705, "FontSize", Enum.FontSize.Size10)
	setp(NG705, "Text", "GLOBAL - Normal  LOCAL - Relative to each part  LAST - Relative to the last part selected")
	setp(NG705, "TextColor3", Color3.new(1, 1, 1))
	setp(NG705, "TextWrapped", true)
	setp(NG705, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG705, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG705, "Parent", NG703)
	NG706 = Instance.new("TextLabel")
	setp(NG706, "BackgroundTransparency", 1)
	setp(NG706, "BorderSizePixel", 0)
	setp(NG706, "Position", UDim2.new(0, 10, 0, 15))
	setp(NG706, "Size", UDim2.new(0, 80, 0, 60))
	setp(NG706, "Font", Enum.Font.Arial)
	setp(NG706, "FontSize", Enum.FontSize.Size10)
	setp(NG706, "Text", "This option lets you choose in which direction to move each part.")
	setp(NG706, "TextColor3", Color3.new(1, 1, 1))
	setp(NG706, "TextWrapped", true)
	setp(NG706, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG706, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG706, "Parent", NG703)
	NG707 = Instance.new("TextLabel")
	setp(NG707, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG707, "BackgroundTransparency", 1)
	setp(NG707, "BorderSizePixel", 0)
	setp(NG707, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG707, "Size", UDim2.new(0, 80, 0, 12))
	setp(NG707, "Font", Enum.Font.ArialBold)
	setp(NG707, "FontSize", Enum.FontSize.Size10)
	setp(NG707, "Text", "Axes")
	setp(NG707, "TextColor3", Color3.new(1, 1, 1))
	setp(NG707, "TextWrapped", true)
	setp(NG707, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG707, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG707, "Parent", NG703)
	NG708 = Instance.new("TextLabel")
	setp(NG708, "BackgroundTransparency", 1)
	setp(NG708, "BorderSizePixel", 0)
	setp(NG708, "Position", UDim2.new(0, 10, 0, 210))
	setp(NG708, "Size", UDim2.new(0, 80, 0, 90))
	setp(NG708, "Font", Enum.Font.Arial)
	setp(NG708, "FontSize", Enum.FontSize.Size10)
	NG708.Text =
		"TIP: When your axes are set to local or last, you can right click to change which part has the handles."
	setp(NG708, "TextColor3", Color3.new(1, 1, 1))
	setp(NG708, "TextWrapped", true)
	setp(NG708, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG708, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG708, "Parent", NG703)
	NG709 = Instance.new("Frame")
	setp(NG709, "BackgroundColor3", Color3.new(1, 0.666667, 0))
	setp(NG709, "BorderSizePixel", 0)
	setp(NG709, "Name", "ColorBar")
	setp(NG709, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG709, "Parent", NG702)
	NG710 = Instance.new("TextLabel")
	setp(NG710, "BackgroundTransparency", 1)
	setp(NG710, "BorderSizePixel", 0)
	setp(NG710, "Name", "ToolDescription")
	setp(NG710, "Position", UDim2.new(0, 10, 0, 25))
	setp(NG710, "Size", UDim2.new(0, 80, 0, 50))
	setp(NG710, "Font", Enum.Font.Arial)
	setp(NG710, "FontSize", Enum.FontSize.Size10)
	setp(NG710, "Text", "Allows you to move parts.")
	setp(NG710, "TextColor3", Color3.new(1, 1, 1))
	setp(NG710, "TextWrapped", true)
	setp(NG710, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG710, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG710, "Parent", NG702)
	NG711 = Instance.new("TextLabel")
	setp(NG711, "BackgroundTransparency", 1)
	setp(NG711, "BorderSizePixel", 0)
	setp(NG711, "Name", "ToolName")
	setp(NG711, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG711, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG711, "Font", Enum.Font.ArialBold)
	setp(NG711, "FontSize", Enum.FontSize.Size10)
	setp(NG711, "Text", "MOVE TOOL")
	setp(NG711, "TextColor3", Color3.new(1, 1, 1))
	setp(NG711, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG711, "Parent", NG702)
	NG712 = Instance.new("Frame")
	setp(NG712, "BackgroundTransparency", 1)
	setp(NG712, "BorderSizePixel", 0)
	setp(NG712, "Name", "IncrementInfo")
	setp(NG712, "Position", UDim2.new(0, 0, 0, 365))
	setp(NG712, "Size", UDim2.new(1, 0, 0, 300))
	setp(NG712, "Parent", NG702)
	NG713 = Instance.new("TextLabel")
	setp(NG713, "BackgroundTransparency", 1)
	setp(NG713, "BorderSizePixel", 0)
	setp(NG713, "Position", UDim2.new(0, 10, 0, 15))
	setp(NG713, "Size", UDim2.new(0, 80, 0, 60))
	setp(NG713, "Font", Enum.Font.Arial)
	setp(NG713, "FontSize", Enum.FontSize.Size10)
	setp(NG713, "Text", "Lets you choose how many studs to move the parts.")
	setp(NG713, "TextColor3", Color3.new(1, 1, 1))
	setp(NG713, "TextWrapped", true)
	setp(NG713, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG713, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG713, "Parent", NG712)
	NG714 = Instance.new("TextLabel")
	setp(NG714, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG714, "BackgroundTransparency", 1)
	setp(NG714, "BorderSizePixel", 0)
	setp(NG714, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG714, "Size", UDim2.new(0, 80, 0, 12))
	setp(NG714, "Font", Enum.Font.ArialBold)
	setp(NG714, "FontSize", Enum.FontSize.Size10)
	setp(NG714, "Text", "Increment")
	setp(NG714, "TextColor3", Color3.new(1, 1, 1))
	setp(NG714, "TextWrapped", true)
	setp(NG714, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG714, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG714, "Parent", NG712)
	NG715 = Instance.new("TextLabel")
	setp(NG715, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG715, "BackgroundTransparency", 1)
	setp(NG715, "BorderSizePixel", 0)
	setp(NG715, "Position", UDim2.new(0, 10, 0, 70))
	setp(NG715, "Size", UDim2.new(0, 80, 0, 50))
	setp(NG715, "Font", Enum.Font.Arial)
	setp(NG715, "FontSize", Enum.FontSize.Size10)
	setp(NG715, "Text", "TIP: Use the - key to focus on the increment input.")
	setp(NG715, "TextColor3", Color3.new(1, 1, 1))
	setp(NG715, "TextWrapped", true)
	setp(NG715, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG715, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG715, "Parent", NG712)
	NG716 = Instance.new("Frame")
	setp(NG716, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG716, "BackgroundTransparency", 0.20000000298023)
	setp(NG716, "BorderSizePixel", 0)
	setp(NG716, "Name", "RotateInfo")
	setp(NG716, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG716, "Visible", false)
	setp(NG716, "Parent", NG650)
	NG717 = Instance.new("Frame")
	setp(NG717, "BackgroundTransparency", 1)
	setp(NG717, "BorderSizePixel", 0)
	setp(NG717, "Name", "Content")
	setp(NG717, "Size", UDim2.new(1, 0, 0, 530))
	setp(NG717, "Parent", NG716)
	NG718 = Instance.new("Frame")
	setp(NG718, "BackgroundTransparency", 1)
	setp(NG718, "BorderSizePixel", 0)
	setp(NG718, "Name", "PivotInfo")
	setp(NG718, "Position", UDim2.new(0, 0, 0, 60))
	setp(NG718, "Size", UDim2.new(1, 0, 0, 300))
	setp(NG718, "Parent", NG717)
	NG719 = Instance.new("Frame")
	setp(NG719, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG719, "BorderSizePixel", 0)
	setp(NG719, "Position", UDim2.new(0, 10, 0, 73))
	setp(NG719, "Size", UDim2.new(0, 2, 0, 168))
	setp(NG719, "Parent", NG718)
	NG720 = Instance.new("TextLabel")
	setp(NG720, "BackgroundTransparency", 1)
	setp(NG720, "BorderSizePixel", 0)
	setp(NG720, "Position", UDim2.new(0, 17, 0, 71))
	setp(NG720, "Size", UDim2.new(0, 80, 0, 180))
	setp(NG720, "Font", Enum.Font.Arial)
	setp(NG720, "FontSize", Enum.FontSize.Size10)
	setp(NG720, "Text", "CENTER - Rotate around the center of the group of selected parts  LOCAL - Rotate each part around its own center  LAST - Rotate each part around the center of the last part selected")
	setp(NG720, "TextColor3", Color3.new(1, 1, 1))
	setp(NG720, "TextWrapped", true)
	setp(NG720, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG720, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG720, "Parent", NG718)
	NG721 = Instance.new("TextLabel")
	setp(NG721, "BackgroundTransparency", 1)
	setp(NG721, "BorderSizePixel", 0)
	setp(NG721, "Position", UDim2.new(0, 10, 0, 15))
	setp(NG721, "Size", UDim2.new(0, 80, 0, 60))
	setp(NG721, "Font", Enum.Font.Arial)
	setp(NG721, "FontSize", Enum.FontSize.Size10)
	setp(NG721, "Text", "This option lets you choose what to rotate the parts around.")
	setp(NG721, "TextColor3", Color3.new(1, 1, 1))
	setp(NG721, "TextWrapped", true)
	setp(NG721, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG721, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG721, "Parent", NG718)
	NG722 = Instance.new("TextLabel")
	setp(NG722, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG722, "BackgroundTransparency", 1)
	setp(NG722, "BorderSizePixel", 0)
	setp(NG722, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG722, "Size", UDim2.new(0, 80, 0, 12))
	setp(NG722, "Font", Enum.Font.ArialBold)
	setp(NG722, "FontSize", Enum.FontSize.Size10)
	setp(NG722, "Text", "Pivot")
	setp(NG722, "TextColor3", Color3.new(1, 1, 1))
	setp(NG722, "TextWrapped", true)
	setp(NG722, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG722, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG722, "Parent", NG718)
	NG723 = Instance.new("TextLabel")
	setp(NG723, "BackgroundTransparency", 1)
	setp(NG723, "BorderSizePixel", 0)
	setp(NG723, "Position", UDim2.new(0, 10, 0, 250))
	setp(NG723, "Size", UDim2.new(0, 80, 0, 90))
	setp(NG723, "Font", Enum.Font.Arial)
	setp(NG723, "FontSize", Enum.FontSize.Size10)
	NG723.Text =
		"TIP: When the pivot is set to local or last, you can right click to switch which part has the handles."
	setp(NG723, "TextColor3", Color3.new(1, 1, 1))
	setp(NG723, "TextWrapped", true)
	setp(NG723, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG723, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG723, "Parent", NG718)
	NG724 = Instance.new("Frame")
	setp(NG724, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG724, "BorderSizePixel", 0)
	setp(NG724, "Name", "ColorBar")
	setp(NG724, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG724, "Parent", NG717)
	NG725 = Instance.new("TextLabel")
	setp(NG725, "BackgroundTransparency", 1)
	setp(NG725, "BorderSizePixel", 0)
	setp(NG725, "Name", "ToolDescription")
	setp(NG725, "Position", UDim2.new(0, 10, 0, 25))
	setp(NG725, "Size", UDim2.new(0, 80, 0, 50))
	setp(NG725, "Font", Enum.Font.Arial)
	setp(NG725, "FontSize", Enum.FontSize.Size10)
	setp(NG725, "Text", "Allows you to rotate parts.")
	setp(NG725, "TextColor3", Color3.new(1, 1, 1))
	setp(NG725, "TextWrapped", true)
	setp(NG725, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG725, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG725, "Parent", NG717)
	NG726 = Instance.new("TextLabel")
	setp(NG726, "BackgroundTransparency", 1)
	setp(NG726, "BorderSizePixel", 0)
	setp(NG726, "Name", "ToolName")
	setp(NG726, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG726, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG726, "Font", Enum.Font.ArialBold)
	setp(NG726, "FontSize", Enum.FontSize.Size10)
	setp(NG726, "Text", "ROTATE TOOL")
	setp(NG726, "TextColor3", Color3.new(1, 1, 1))
	setp(NG726, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG726, "Parent", NG717)
	NG727 = Instance.new("Frame")
	setp(NG727, "BackgroundTransparency", 1)
	setp(NG727, "BorderSizePixel", 0)
	setp(NG727, "Name", "IncrementInfo")
	setp(NG727, "Position", UDim2.new(0, 0, 0, 395))
	setp(NG727, "Size", UDim2.new(1, 0, 0, 130))
	setp(NG727, "Parent", NG717)
	NG728 = Instance.new("TextLabel")
	setp(NG728, "BackgroundTransparency", 1)
	setp(NG728, "BorderSizePixel", 0)
	setp(NG728, "Position", UDim2.new(0, 10, 0, 15))
	setp(NG728, "Size", UDim2.new(0, 80, 0, 60))
	setp(NG728, "Font", Enum.Font.Arial)
	setp(NG728, "FontSize", Enum.FontSize.Size10)
	setp(NG728, "Text", "Lets you choose how many degrees to rotate the parts.")
	setp(NG728, "TextColor3", Color3.new(1, 1, 1))
	setp(NG728, "TextWrapped", true)
	setp(NG728, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG728, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG728, "Parent", NG727)
	NG729 = Instance.new("TextLabel")
	setp(NG729, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG729, "BackgroundTransparency", 1)
	setp(NG729, "BorderSizePixel", 0)
	setp(NG729, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG729, "Size", UDim2.new(0, 80, 0, 12))
	setp(NG729, "Font", Enum.Font.ArialBold)
	setp(NG729, "FontSize", Enum.FontSize.Size10)
	setp(NG729, "Text", "Increment")
	setp(NG729, "TextColor3", Color3.new(1, 1, 1))
	setp(NG729, "TextWrapped", true)
	setp(NG729, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG729, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG729, "Parent", NG727)
	NG730 = Instance.new("TextLabel")
	setp(NG730, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG730, "BackgroundTransparency", 1)
	setp(NG730, "BorderSizePixel", 0)
	setp(NG730, "Position", UDim2.new(0, 10, 0, 70))
	setp(NG730, "Size", UDim2.new(0, 80, 0, 50))
	setp(NG730, "Font", Enum.Font.Arial)
	setp(NG730, "FontSize", Enum.FontSize.Size10)
	setp(NG730, "Text", "TIP: Use the - key to focus on the increment input.")
	setp(NG730, "TextColor3", Color3.new(1, 1, 1))
	setp(NG730, "TextWrapped", true)
	setp(NG730, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG730, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG730, "Parent", NG727)
	NG731 = Instance.new("Frame")
	setp(NG731, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG731, "BackgroundTransparency", 0.20000000298023)
	setp(NG731, "BorderSizePixel", 0)
	setp(NG731, "Name", "ResizeInfo")
	setp(NG731, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG731, "Visible", false)
	setp(NG731, "Parent", NG650)
	NG732 = Instance.new("Frame")
	setp(NG732, "BackgroundTransparency", 1)
	setp(NG732, "BorderSizePixel", 0)
	setp(NG732, "Name", "Content")
	setp(NG732, "Size", UDim2.new(1, 0, 0, 330))
	setp(NG732, "Parent", NG731)
	NG733 = Instance.new("Frame")
	setp(NG733, "BackgroundTransparency", 1)
	setp(NG733, "BorderSizePixel", 0)
	setp(NG733, "Name", "DirectionsInfo")
	setp(NG733, "Position", UDim2.new(0, 0, 0, 60))
	setp(NG733, "Size", UDim2.new(1, 0, 0, 300))
	setp(NG733, "Parent", NG732)
	NG734 = Instance.new("TextLabel")
	setp(NG734, "BackgroundTransparency", 1)
	setp(NG734, "BorderSizePixel", 0)
	setp(NG734, "Position", UDim2.new(0, 10, 0, 15))
	setp(NG734, "Size", UDim2.new(0, 80, 0, 120))
	setp(NG734, "Font", Enum.Font.Arial)
	setp(NG734, "FontSize", Enum.FontSize.Size10)
	setp(NG734, "Text", "Lets you choose in which directions to resize the part.  TIP: You can switch which part has the handles by right-clicking.")
	setp(NG734, "TextColor3", Color3.new(1, 1, 1))
	setp(NG734, "TextWrapped", true)
	setp(NG734, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG734, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG734, "Parent", NG733)
	NG735 = Instance.new("TextLabel")
	setp(NG735, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG735, "BackgroundTransparency", 1)
	setp(NG735, "BorderSizePixel", 0)
	setp(NG735, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG735, "Size", UDim2.new(0, 80, 0, 12))
	setp(NG735, "Font", Enum.Font.ArialBold)
	setp(NG735, "FontSize", Enum.FontSize.Size10)
	setp(NG735, "Text", "Directions")
	setp(NG735, "TextColor3", Color3.new(1, 1, 1))
	setp(NG735, "TextWrapped", true)
	setp(NG735, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG735, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG735, "Parent", NG733)
	NG736 = Instance.new("Frame")
	setp(NG736, "BackgroundColor3", Color3.new(0.0156863, 0.686275, 0.92549))
	setp(NG736, "BorderSizePixel", 0)
	setp(NG736, "Name", "ColorBar")
	setp(NG736, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG736, "Parent", NG732)
	NG737 = Instance.new("TextLabel")
	setp(NG737, "BackgroundTransparency", 1)
	setp(NG737, "BorderSizePixel", 0)
	setp(NG737, "Name", "ToolDescription")
	setp(NG737, "Position", UDim2.new(0, 10, 0, 25))
	setp(NG737, "Size", UDim2.new(0, 80, 0, 50))
	setp(NG737, "Font", Enum.Font.Arial)
	setp(NG737, "FontSize", Enum.FontSize.Size10)
	setp(NG737, "Text", "Allows you to resize parts.")
	setp(NG737, "TextColor3", Color3.new(1, 1, 1))
	setp(NG737, "TextWrapped", true)
	setp(NG737, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG737, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG737, "Parent", NG732)
	NG738 = Instance.new("TextLabel")
	setp(NG738, "BackgroundTransparency", 1)
	setp(NG738, "BorderSizePixel", 0)
	setp(NG738, "Name", "ToolName")
	setp(NG738, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG738, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG738, "Font", Enum.Font.ArialBold)
	setp(NG738, "FontSize", Enum.FontSize.Size10)
	setp(NG738, "Text", "RESIZE TOOL")
	setp(NG738, "TextColor3", Color3.new(1, 1, 1))
	setp(NG738, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG738, "Parent", NG732)
	NG739 = Instance.new("Frame")
	setp(NG739, "BackgroundTransparency", 1)
	setp(NG739, "BorderSizePixel", 0)
	setp(NG739, "Name", "IncrementInfo")
	setp(NG739, "Position", UDim2.new(0, 0, 0, 200))
	setp(NG739, "Size", UDim2.new(1, 0, 0, 140))
	setp(NG739, "Parent", NG732)
	NG740 = Instance.new("TextLabel")
	setp(NG740, "BackgroundTransparency", 1)
	setp(NG740, "BorderSizePixel", 0)
	setp(NG740, "Position", UDim2.new(0, 10, 0, 15))
	setp(NG740, "Size", UDim2.new(0, 80, 0, 60))
	setp(NG740, "Font", Enum.Font.Arial)
	setp(NG740, "FontSize", Enum.FontSize.Size10)
	setp(NG740, "Text", "Lets you choose how many studs to resize the parts.")
	setp(NG740, "TextColor3", Color3.new(1, 1, 1))
	setp(NG740, "TextWrapped", true)
	setp(NG740, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG740, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG740, "Parent", NG739)
	NG741 = Instance.new("TextLabel")
	setp(NG741, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG741, "BackgroundTransparency", 1)
	setp(NG741, "BorderSizePixel", 0)
	setp(NG741, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG741, "Size", UDim2.new(0, 80, 0, 12))
	setp(NG741, "Font", Enum.Font.ArialBold)
	setp(NG741, "FontSize", Enum.FontSize.Size10)
	setp(NG741, "Text", "Increment")
	setp(NG741, "TextColor3", Color3.new(1, 1, 1))
	setp(NG741, "TextWrapped", true)
	setp(NG741, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG741, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG741, "Parent", NG739)
	NG742 = Instance.new("TextLabel")
	setp(NG742, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG742, "BackgroundTransparency", 1)
	setp(NG742, "BorderSizePixel", 0)
	setp(NG742, "Position", UDim2.new(0, 10, 0, 70))
	setp(NG742, "Size", UDim2.new(0, 80, 0, 50))
	setp(NG742, "Font", Enum.Font.Arial)
	setp(NG742, "FontSize", Enum.FontSize.Size10)
	setp(NG742, "Text", "TIP: Use the - key to focus on the increment input.")
	setp(NG742, "TextColor3", Color3.new(1, 1, 1))
	setp(NG742, "TextWrapped", true)
	setp(NG742, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG742, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG742, "Parent", NG739)
	NG743 = Instance.new("Frame")
	setp(NG743, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG743, "BackgroundTransparency", 0.20000000298023)
	setp(NG743, "BorderSizePixel", 0)
	setp(NG743, "Name", "WeldInfo")
	setp(NG743, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG743, "Visible", false)
	setp(NG743, "Parent", NG650)
	NG744 = Instance.new("Frame")
	setp(NG744, "BackgroundTransparency", 1)
	setp(NG744, "BorderSizePixel", 0)
	setp(NG744, "Name", "Content")
	setp(NG744, "Size", UDim2.new(1, 0, 0, 310))
	setp(NG744, "Parent", NG743)
	NG745 = Instance.new("Frame")
	setp(NG745, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG745, "BorderSizePixel", 0)
	setp(NG745, "Name", "ColorBar")
	setp(NG745, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG745, "Parent", NG744)
	NG746 = Instance.new("TextLabel")
	setp(NG746, "BackgroundTransparency", 1)
	setp(NG746, "BorderSizePixel", 0)
	setp(NG746, "Name", "ToolDescription")
	setp(NG746, "Position", UDim2.new(0, 10, 0, 25))
	setp(NG746, "Size", UDim2.new(0, 80, 0, 300))
	setp(NG746, "Font", Enum.Font.Arial)
	setp(NG746, "FontSize", Enum.FontSize.Size10)
	setp(NG746, "Text", "Allows you to weld parts together so that they'll move together.  NOTE: The welds between parts may break if you only move one of the parts (move all of the parts that are connected by welds to prevent this).  NOTE: This tool doesn't work in ROBLOX Studio (it's kind of useless in that context).")
	setp(NG746, "TextColor3", Color3.new(1, 1, 1))
	setp(NG746, "TextWrapped", true)
	setp(NG746, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG746, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG746, "Parent", NG744)
	NG747 = Instance.new("TextLabel")
	setp(NG747, "BackgroundTransparency", 1)
	setp(NG747, "BorderSizePixel", 0)
	setp(NG747, "Name", "ToolName")
	setp(NG747, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG747, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG747, "Font", Enum.Font.ArialBold)
	setp(NG747, "FontSize", Enum.FontSize.Size10)
	setp(NG747, "Text", "WELD TOOL")
	setp(NG747, "TextColor3", Color3.new(1, 1, 1))
	setp(NG747, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG747, "Parent", NG744)
	NG748 = Instance.new("Frame")
	setp(NG748, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG748, "BackgroundTransparency", 0.75)
	setp(NG748, "BorderSizePixel", 0)
	setp(NG748, "Name", "InfoButtons")
	setp(NG748, "Position", UDim2.new(0, 0, 0, 350))
	setp(NG748, "Size", UDim2.new(1, 0, 0, 32))
	setp(NG748, "Parent", NG649)
	NG749 = Instance.new("TextLabel")
	setp(NG749, "BackgroundTransparency", 1)
	setp(NG749, "BorderSizePixel", 0)
	setp(NG749, "Name", "F3XSignature")
	setp(NG749, "Position", UDim2.new(0, 0, 0, 7))
	setp(NG749, "Size", UDim2.new(1, -28, 0, 17))
	setp(NG749, "Font", Enum.Font.ArialBold)
	setp(NG749, "FontSize", Enum.FontSize.Size14)
	setp(NG749, "Text", "F3X")
	setp(NG749, "TextColor3", Color3.new(1, 1, 1))
	setp(NG749, "TextScaled", true)
	setp(NG749, "TextStrokeTransparency", 0.89999997615814)
	setp(NG749, "TextWrapped", true)
	setp(NG749, "Parent", NG748)
	NG750 = Instance.new("ImageButton")
	setp(NG750, "BackgroundColor3", Color3.new(0.333333, 0.666667, 1))
	setp(NG750, "BackgroundTransparency", 1)
	setp(NG750, "BorderSizePixel", 0)
	setp(NG750, "Name", "HelpButton")
	setp(NG750, "Position", UDim2.new(1, -32, 0, 0))
	setp(NG750, "Size", UDim2.new(0, 32, 0, 32))
	NG750.Style = Enum.ButtonStyle.Custom
	setp(NG750, "Image", "http://www.roblox.com/asset/?id=141911973")
	setp(NG750, "Parent", NG748)
	NG751 = Instance.new("Frame")
	setp(NG751, "BackgroundTransparency", 1)
	setp(NG751, "BorderSizePixel", 0)
	setp(NG751, "Name", "Tooltip")
	setp(NG751, "Position", UDim2.new(-0.300000012, 0, 1, 0))
	setp(NG751, "Size", UDim2.new(1.60000002, 0, 0, 0))
	setp(NG751, "Visible", false)
	setp(NG751, "Parent", NG750)
	NG752 = Instance.new("TextLabel")
	setp(NG752, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG752, "BackgroundTransparency", 0.5)
	setp(NG752, "BorderSizePixel", 0)
	setp(NG752, "Name", "Text")
	setp(NG752, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG752, "Font", Enum.Font.ArialBold)
	setp(NG752, "FontSize", Enum.FontSize.Size10)
	setp(NG752, "Text", "HELP")
	setp(NG752, "TextColor3", Color3.new(1, 1, 1))
	setp(NG752, "Parent", NG751)
	NG753 = Instance.new("Frame")
	setp(NG753, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG753, "BackgroundTransparency", 0.69999998807907)
	setp(NG753, "BorderSizePixel", 0)
	setp(NG753, "Name", "Shadow")
	setp(NG753, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG753, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG753, "Parent", NG748)
	NG754 = Instance.new("Frame")
	setp(NG754, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG754, "BackgroundTransparency", 0.5)
	setp(NG754, "BorderSizePixel", 0)
	setp(NG754, "Name", "SelectionButtons")
	setp(NG754, "Position", UDim2.new(0, 0, 0, 245))
	setp(NG754, "Size", UDim2.new(1, 0, 0, 105))
	setp(NG754, "Parent", NG649)
	NG755 = Instance.new("ImageButton")
	setp(NG755, "BackgroundColor3", Color3.new(0.333333, 0.666667, 1))
	setp(NG755, "BackgroundTransparency", 1)
	setp(NG755, "BorderSizePixel", 0)
	setp(NG755, "Name", "DeleteButton")
	setp(NG755, "Position", UDim2.new(0, 0, 0, 35))
	setp(NG755, "Size", UDim2.new(0, 35, 0, 35))
	NG755.Style = Enum.ButtonStyle.Custom
	setp(NG755, "Image", "http://www.roblox.com/asset/?id=142074644")
	setp(NG755, "Parent", NG754)
	NG756 = Instance.new("Frame")
	setp(NG756, "BackgroundTransparency", 1)
	setp(NG756, "BorderSizePixel", 0)
	setp(NG756, "Name", "Tooltip")
	setp(NG756, "Position", UDim2.new(-0.300000012, 0, 1, 0))
	setp(NG756, "Size", UDim2.new(1.60000002, 0, 0, 0))
	setp(NG756, "Visible", false)
	setp(NG756, "Parent", NG755)
	NG757 = Instance.new("TextLabel")
	setp(NG757, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG757, "BackgroundTransparency", 0.5)
	setp(NG757, "BorderSizePixel", 0)
	setp(NG757, "Name", "Text")
	setp(NG757, "Size", UDim2.new(1, 0, 0, 28))
	setp(NG757, "Font", Enum.Font.ArialBold)
	setp(NG757, "FontSize", Enum.FontSize.Size10)
	setp(NG757, "Text", "DELETE (Shift + X)")
	setp(NG757, "TextColor3", Color3.new(1, 1, 1))
	setp(NG757, "Parent", NG756)
	NG758 = Instance.new("ImageButton")
	setp(NG758, "BackgroundColor3", Color3.new(0.333333, 0.666667, 1))
	setp(NG758, "BackgroundTransparency", 1)
	setp(NG758, "BorderSizePixel", 0)
	setp(NG758, "Name", "ExportButton")
	setp(NG758, "Position", UDim2.new(0, 35, 0, 35))
	setp(NG758, "Size", UDim2.new(0, 35, 0, 35))
	NG758.Style = Enum.ButtonStyle.Custom
	setp(NG758, "Image", "http://www.roblox.com/asset/?id=142074569")
	setp(NG758, "Parent", NG754)
	NG759 = Instance.new("Frame")
	setp(NG759, "BackgroundTransparency", 1)
	setp(NG759, "BorderSizePixel", 0)
	setp(NG759, "Name", "Tooltip")
	setp(NG759, "Position", UDim2.new(-0.300000012, 0, 1, 0))
	setp(NG759, "Size", UDim2.new(1.60000002, 0, 0, 0))
	setp(NG759, "Visible", false)
	setp(NG759, "Parent", NG758)
	NG760 = Instance.new("TextLabel")
	setp(NG760, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG760, "BackgroundTransparency", 0.5)
	setp(NG760, "BorderSizePixel", 0)
	setp(NG760, "Name", "Text")
	setp(NG760, "Size", UDim2.new(1, 0, 0, 28))
	setp(NG760, "Font", Enum.Font.ArialBold)
	setp(NG760, "FontSize", Enum.FontSize.Size10)
	setp(NG760, "Text", "EXPORT (Shift + P)")
	setp(NG760, "TextColor3", Color3.new(1, 1, 1))
	setp(NG760, "Parent", NG759)
	NG761 = Instance.new("ImageButton")
	setp(NG761, "BackgroundColor3", Color3.new(0.333333, 0.666667, 1))
	setp(NG761, "BackgroundTransparency", 1)
	setp(NG761, "BorderSizePixel", 0)
	setp(NG761, "Name", "RedoButton")
	setp(NG761, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG761, "Size", UDim2.new(0, 35, 0, 35))
	NG761.Style = Enum.ButtonStyle.Custom
	setp(NG761, "Image", "http://www.roblox.com/asset/?id=142074553")
	setp(NG761, "Parent", NG754)
	NG762 = Instance.new("Frame")
	setp(NG762, "BackgroundTransparency", 1)
	setp(NG762, "BorderSizePixel", 0)
	setp(NG762, "Name", "Tooltip")
	setp(NG762, "Position", UDim2.new(-0.300000012, 0, 1, 0))
	setp(NG762, "Size", UDim2.new(1.60000002, 0, 0, 0))
	setp(NG762, "Visible", false)
	setp(NG762, "Parent", NG761)
	NG763 = Instance.new("TextLabel")
	setp(NG763, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG763, "BackgroundTransparency", 0.5)
	setp(NG763, "BorderSizePixel", 0)
	setp(NG763, "Name", "Text")
	setp(NG763, "Size", UDim2.new(1, 0, 0, 28))
	setp(NG763, "Font", Enum.Font.ArialBold)
	setp(NG763, "FontSize", Enum.FontSize.Size10)
	setp(NG763, "Text", "REDO (Shift + Y)")
	setp(NG763, "TextColor3", Color3.new(1, 1, 1))
	setp(NG763, "Parent", NG762)
	NG764 = Instance.new("ImageButton")
	setp(NG764, "BackgroundColor3", Color3.new(0.333333, 0.666667, 1))
	setp(NG764, "BackgroundTransparency", 1)
	setp(NG764, "BorderSizePixel", 0)
	setp(NG764, "Name", "UndoButton")
	setp(NG764, "Size", UDim2.new(0, 35, 0, 35))
	NG764.Style = Enum.ButtonStyle.Custom
	setp(NG764, "Image", "http://www.roblox.com/asset/?id=142074557")
	setp(NG764, "Parent", NG754)
	NG765 = Instance.new("Frame")
	setp(NG765, "BackgroundTransparency", 1)
	setp(NG765, "BorderSizePixel", 0)
	setp(NG765, "Name", "Tooltip")
	setp(NG765, "Position", UDim2.new(-0.300000012, 0, 1, 0))
	setp(NG765, "Size", UDim2.new(1.60000002, 0, 0, 0))
	setp(NG765, "Visible", false)
	setp(NG765, "Parent", NG764)
	NG766 = Instance.new("TextLabel")
	setp(NG766, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG766, "BackgroundTransparency", 0.5)
	setp(NG766, "BorderSizePixel", 0)
	setp(NG766, "Name", "Text")
	setp(NG766, "Size", UDim2.new(1, 0, 0, 28))
	setp(NG766, "Font", Enum.Font.ArialBold)
	setp(NG766, "FontSize", Enum.FontSize.Size10)
	setp(NG766, "Text", "UNDO (Shift + Z)")
	setp(NG766, "TextColor3", Color3.new(1, 1, 1))
	setp(NG766, "Parent", NG765)
	NG767 = Instance.new("ImageButton")
	setp(NG767, "BackgroundColor3", Color3.new(0.333333, 0.666667, 1))
	setp(NG767, "BackgroundTransparency", 1)
	setp(NG767, "BorderSizePixel", 0)
	setp(NG767, "Name", "CloneButton")
	setp(NG767, "Position", UDim2.new(0, 0, 0, 70))
	setp(NG767, "Size", UDim2.new(0, 35, 0, 35))
	NG767.Style = Enum.ButtonStyle.Custom
	setp(NG767, "Image", "http://www.roblox.com/asset/?id=142074563")
	setp(NG767, "Parent", NG754)
	NG768 = Instance.new("Frame")
	setp(NG768, "BackgroundTransparency", 1)
	setp(NG768, "BorderSizePixel", 0)
	setp(NG768, "Name", "Tooltip")
	setp(NG768, "Position", UDim2.new(-0.300000012, 0, 1, 0))
	setp(NG768, "Size", UDim2.new(1.60000002, 0, 0, 0))
	setp(NG768, "Visible", false)
	setp(NG768, "Parent", NG767)
	NG769 = Instance.new("TextLabel")
	setp(NG769, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG769, "BackgroundTransparency", 0.5)
	setp(NG769, "BorderSizePixel", 0)
	setp(NG769, "Name", "Text")
	setp(NG769, "Size", UDim2.new(1, 0, 0, 28))
	setp(NG769, "Font", Enum.Font.ArialBold)
	setp(NG769, "FontSize", Enum.FontSize.Size10)
	setp(NG769, "Text", "CLONE (Shift + C)")
	setp(NG769, "TextColor3", Color3.new(1, 1, 1))
	setp(NG769, "Parent", NG768)
	NG770 = Instance.new("ImageButton")
	setp(NG770, "BackgroundColor3", Color3.new(0.333333, 0.666667, 1))
	setp(NG770, "BackgroundTransparency", 1)
	setp(NG770, "BorderSizePixel", 0)
	setp(NG770, "Name", "GroupsButton")
	setp(NG770, "Position", UDim2.new(0, 35, 0, 70))
	setp(NG770, "Size", UDim2.new(0, 35, 0, 35))
	NG770.Style = Enum.ButtonStyle.Custom
	setp(NG770, "Image", "http://www.roblox.com/asset/?id=160378203")
	setp(NG770, "Parent", NG754)
	NG771 = Instance.new("Frame")
	setp(NG771, "BackgroundTransparency", 1)
	setp(NG771, "BorderSizePixel", 0)
	setp(NG771, "Name", "Tooltip")
	setp(NG771, "Position", UDim2.new(-0.300000012, 0, 1, 0))
	setp(NG771, "Size", UDim2.new(1.60000002, 0, 0, 0))
	setp(NG771, "Visible", false)
	setp(NG771, "Parent", NG770)
	NG772 = Instance.new("TextLabel")
	setp(NG772, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG772, "BackgroundTransparency", 0.5)
	setp(NG772, "BorderSizePixel", 0)
	setp(NG772, "Name", "Text")
	setp(NG772, "Size", UDim2.new(1, 0, 0, 28))
	setp(NG772, "Font", Enum.Font.ArialBold)
	setp(NG772, "FontSize", Enum.FontSize.Size10)
	setp(NG772, "Text", "GROUPS (Shift + G)")
	setp(NG772, "TextColor3", Color3.new(1, 1, 1))
	setp(NG772, "TextWrapped", true)
	setp(NG772, "Parent", NG771)
	NG773 = Instance.new("Frame")
	setp(NG773, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG773, "BackgroundTransparency", 0.60000002384186)
	setp(NG773, "BorderSizePixel", 0)
	setp(NG773, "Name", "ToolButtons")
	setp(NG773, "Size", UDim2.new(0, 70, 0, 245))
	setp(NG773, "Parent", NG649)
	NG774 = Instance.new("ImageButton")
	setp(NG774, "AutoButtonColor", false)
	setp(NG774, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG774, "BackgroundTransparency", 1)
	setp(NG774, "BorderSizePixel", 0)
	setp(NG774, "Name", "DecorateButton")
	setp(NG774, "Position", UDim2.new(0, 35, 0, 210))
	setp(NG774, "Size", UDim2.new(0, 35, 0, 35))
	NG774.Style = Enum.ButtonStyle.Custom
	setp(NG774, "Image", "http://www.roblox.com/asset/?id=141741412")
	setp(NG774, "Parent", NG773)
	NG775 = Instance.new("TextLabel")
	setp(NG775, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG775, "BackgroundTransparency", 1)
	setp(NG775, "BorderSizePixel", 0)
	setp(NG775, "Name", "Shortcut")
	setp(NG775, "Size", UDim2.new(0, 13, 0, 13))
	setp(NG775, "Font", Enum.Font.ArialBold)
	setp(NG775, "FontSize", Enum.FontSize.Size10)
	setp(NG775, "Text", "P")
	setp(NG775, "TextColor3", Color3.new(1, 1, 1))
	setp(NG775, "Parent", NG774)
	NG776 = Instance.new("ImageButton")
	setp(NG776, "AutoButtonColor", false)
	setp(NG776, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG776, "BackgroundTransparency", 1)
	setp(NG776, "BorderSizePixel", 0)
	setp(NG776, "Name", "WeldButton")
	setp(NG776, "Position", UDim2.new(0, 35, 0, 175))
	setp(NG776, "Size", UDim2.new(0, 35, 0, 35))
	NG776.Style = Enum.ButtonStyle.Custom
	setp(NG776, "Image", "http://www.roblox.com/asset/?id=141741418")
	setp(NG776, "Parent", NG773)
	NG777 = Instance.new("TextLabel")
	setp(NG777, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG777, "BackgroundTransparency", 1)
	setp(NG777, "BorderSizePixel", 0)
	setp(NG777, "Name", "Shortcut")
	setp(NG777, "Size", UDim2.new(0, 13, 0, 13))
	setp(NG777, "Font", Enum.Font.ArialBold)
	setp(NG777, "FontSize", Enum.FontSize.Size10)
	setp(NG777, "Text", "F")
	setp(NG777, "TextColor3", Color3.new(1, 1, 1))
	setp(NG777, "Parent", NG776)
	NG778 = Instance.new("ImageButton")
	setp(NG778, "AutoButtonColor", false)
	setp(NG778, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG778, "BackgroundTransparency", 1)
	setp(NG778, "BorderSizePixel", 0)
	setp(NG778, "Name", "LightingButton")
	setp(NG778, "Position", UDim2.new(0, 0, 0, 210))
	setp(NG778, "Size", UDim2.new(0, 35, 0, 35))
	NG778.Style = Enum.ButtonStyle.Custom
	setp(NG778, "Image", "http://www.roblox.com/asset/?id=141741341")
	setp(NG778, "Parent", NG773)
	NG779 = Instance.new("TextLabel")
	setp(NG779, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG779, "BackgroundTransparency", 1)
	setp(NG779, "BorderSizePixel", 0)
	setp(NG779, "Name", "Shortcut")
	setp(NG779, "Size", UDim2.new(0, 13, 0, 13))
	setp(NG779, "Font", Enum.Font.ArialBold)
	setp(NG779, "FontSize", Enum.FontSize.Size10)
	setp(NG779, "Text", "U")
	setp(NG779, "TextColor3", Color3.new(1, 1, 1))
	setp(NG779, "Parent", NG778)
	NG780 = Instance.new("ImageButton")
	setp(NG780, "AutoButtonColor", false)
	setp(NG780, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG780, "BackgroundTransparency", 1)
	setp(NG780, "BorderSizePixel", 0)
	setp(NG780, "Name", "MeshButton")
	setp(NG780, "Position", UDim2.new(0, 35, 0, 140))
	setp(NG780, "Size", UDim2.new(0, 35, 0, 35))
	NG780.Style = Enum.ButtonStyle.Custom
	setp(NG780, "Image", "http://www.roblox.com/asset/?id=141806786")
	setp(NG780, "Parent", NG773)
	NG781 = Instance.new("TextLabel")
	setp(NG781, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG781, "BackgroundTransparency", 1)
	setp(NG781, "BorderSizePixel", 0)
	setp(NG781, "Name", "Shortcut")
	setp(NG781, "Size", UDim2.new(0, 13, 0, 13))
	setp(NG781, "Font", Enum.Font.ArialBold)
	setp(NG781, "FontSize", Enum.FontSize.Size10)
	setp(NG781, "Text", "H")
	setp(NG781, "TextColor3", Color3.new(1, 1, 1))
	setp(NG781, "Parent", NG780)
	NG782 = Instance.new("ImageButton")
	setp(NG782, "AutoButtonColor", false)
	setp(NG782, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG782, "BackgroundTransparency", 1)
	setp(NG782, "BorderSizePixel", 0)
	setp(NG782, "Name", "CollisionButton")
	setp(NG782, "Position", UDim2.new(0, 35, 0, 105))
	setp(NG782, "Size", UDim2.new(0, 35, 0, 35))
	NG782.Style = Enum.ButtonStyle.Custom
	setp(NG782, "Image", "http://www.roblox.com/asset/?id=141809596")
	setp(NG782, "Parent", NG773)
	NG783 = Instance.new("TextLabel")
	setp(NG783, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG783, "BackgroundTransparency", 1)
	setp(NG783, "BorderSizePixel", 0)
	setp(NG783, "Name", "Shortcut")
	setp(NG783, "Size", UDim2.new(0, 13, 0, 13))
	setp(NG783, "Font", Enum.Font.ArialBold)
	setp(NG783, "FontSize", Enum.FontSize.Size10)
	setp(NG783, "Text", "K")
	setp(NG783, "TextColor3", Color3.new(1, 1, 1))
	setp(NG783, "Parent", NG782)
	NG784 = Instance.new("ImageButton")
	setp(NG784, "AutoButtonColor", false)
	setp(NG784, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG784, "BackgroundTransparency", 1)
	setp(NG784, "BorderSizePixel", 0)
	setp(NG784, "Name", "MaterialButton")
	setp(NG784, "Position", UDim2.new(0, 35, 0, 70))
	setp(NG784, "Size", UDim2.new(0, 35, 0, 35))
	NG784.Style = Enum.ButtonStyle.Custom
	setp(NG784, "Image", "http://www.roblox.com/asset/?id=141809090")
	setp(NG784, "Parent", NG773)
	NG785 = Instance.new("TextLabel")
	setp(NG785, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG785, "BackgroundTransparency", 1)
	setp(NG785, "BorderSizePixel", 0)
	setp(NG785, "Name", "Shortcut")
	setp(NG785, "Size", UDim2.new(0, 13, 0, 13))
	setp(NG785, "Font", Enum.Font.ArialBold)
	setp(NG785, "FontSize", Enum.FontSize.Size10)
	setp(NG785, "Text", "N")
	setp(NG785, "TextColor3", Color3.new(1, 1, 1))
	setp(NG785, "Parent", NG784)
	NG786 = Instance.new("ImageButton")
	setp(NG786, "AutoButtonColor", false)
	setp(NG786, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG786, "BackgroundTransparency", 1)
	setp(NG786, "BorderSizePixel", 0)
	setp(NG786, "Name", "PaintButton")
	setp(NG786, "Position", UDim2.new(0, 35, 0, 35))
	setp(NG786, "Size", UDim2.new(0, 35, 0, 35))
	NG786.Style = Enum.ButtonStyle.Custom
	setp(NG786, "Image", "http://www.roblox.com/asset/?id=141741444")
	setp(NG786, "Parent", NG773)
	NG787 = Instance.new("TextLabel")
	setp(NG787, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG787, "BackgroundTransparency", 1)
	setp(NG787, "BorderSizePixel", 0)
	setp(NG787, "Name", "Shortcut")
	setp(NG787, "Size", UDim2.new(0, 13, 0, 13))
	setp(NG787, "Font", Enum.Font.ArialBold)
	setp(NG787, "FontSize", Enum.FontSize.Size10)
	setp(NG787, "Text", "V")
	setp(NG787, "TextColor3", Color3.new(1, 1, 1))
	setp(NG787, "Parent", NG786)
	NG788 = Instance.new("ImageButton")
	setp(NG788, "AutoButtonColor", false)
	setp(NG788, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG788, "BackgroundTransparency", 1)
	setp(NG788, "BorderSizePixel", 0)
	setp(NG788, "Name", "NewPartButton")
	setp(NG788, "Position", UDim2.new(0, 0, 0, 140))
	setp(NG788, "Size", UDim2.new(0, 35, 0, 35))
	NG788.Style = Enum.ButtonStyle.Custom
	setp(NG788, "Image", "http://www.roblox.com/asset/?id=141741393")
	setp(NG788, "Parent", NG773)
	NG789 = Instance.new("TextLabel")
	setp(NG789, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG789, "BackgroundTransparency", 1)
	setp(NG789, "BorderSizePixel", 0)
	setp(NG789, "Name", "Shortcut")
	setp(NG789, "Size", UDim2.new(0, 13, 0, 13))
	setp(NG789, "Font", Enum.Font.ArialBold)
	setp(NG789, "FontSize", Enum.FontSize.Size10)
	setp(NG789, "Text", "J")
	setp(NG789, "TextColor3", Color3.new(1, 1, 1))
	setp(NG789, "Parent", NG788)
	NG790 = Instance.new("ImageButton")
	setp(NG790, "AutoButtonColor", false)
	setp(NG790, "BackgroundColor3", Color3.new(1, 0.686275, 0))
	setp(NG790, "BackgroundTransparency", 1)
	setp(NG790, "BorderSizePixel", 0)
	setp(NG790, "Name", "MoveButton")
	setp(NG790, "Size", UDim2.new(0, 35, 0, 35))
	NG790.Style = Enum.ButtonStyle.Custom
	setp(NG790, "Image", "http://www.roblox.com/asset/?id=141741366")
	setp(NG790, "Parent", NG773)
	NG791 = Instance.new("TextLabel")
	setp(NG791, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG791, "BackgroundTransparency", 1)
	setp(NG791, "BorderSizePixel", 0)
	setp(NG791, "Name", "Shortcut")
	setp(NG791, "Size", UDim2.new(0, 13, 0, 13))
	setp(NG791, "Font", Enum.Font.ArialBold)
	setp(NG791, "FontSize", Enum.FontSize.Size10)
	setp(NG791, "Text", "Z")
	setp(NG791, "TextColor3", Color3.new(1, 1, 1))
	setp(NG791, "Parent", NG790)
	NG792 = Instance.new("ImageButton")
	setp(NG792, "AutoButtonColor", false)
	setp(NG792, "BackgroundColor3", Color3.new(0.0156863, 0.686275, 0.92549))
	setp(NG792, "BackgroundTransparency", 1)
	setp(NG792, "BorderSizePixel", 0)
	setp(NG792, "Name", "ResizeButton")
	setp(NG792, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG792, "Size", UDim2.new(0, 35, 0, 35))
	NG792.Style = Enum.ButtonStyle.Custom
	setp(NG792, "Image", "http://www.roblox.com/asset/?id=141794324")
	setp(NG792, "Parent", NG773)
	NG793 = Instance.new("TextLabel")
	setp(NG793, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG793, "BackgroundTransparency", 1)
	setp(NG793, "BorderSizePixel", 0)
	setp(NG793, "Name", "Shortcut")
	setp(NG793, "Size", UDim2.new(0, 13, 0, 13))
	setp(NG793, "Font", Enum.Font.ArialBold)
	setp(NG793, "FontSize", Enum.FontSize.Size10)
	setp(NG793, "Text", "X")
	setp(NG793, "TextColor3", Color3.new(1, 1, 1))
	setp(NG793, "Parent", NG792)
	NG794 = Instance.new("ImageButton")
	setp(NG794, "AutoButtonColor", false)
	setp(NG794, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG794, "BackgroundTransparency", 1)
	setp(NG794, "BorderSizePixel", 0)
	setp(NG794, "Name", "RotateButton")
	setp(NG794, "Position", UDim2.new(0, 0, 0, 35))
	setp(NG794, "Size", UDim2.new(0, 35, 0, 35))
	NG794.Style = Enum.ButtonStyle.Custom
	setp(NG794, "Image", "http://www.roblox.com/asset/?id=141807775")
	setp(NG794, "Parent", NG773)
	NG795 = Instance.new("TextLabel")
	setp(NG795, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG795, "BackgroundTransparency", 1)
	setp(NG795, "BorderSizePixel", 0)
	setp(NG795, "Name", "Shortcut")
	setp(NG795, "Size", UDim2.new(0, 13, 0, 13))
	setp(NG795, "Font", Enum.Font.ArialBold)
	setp(NG795, "FontSize", Enum.FontSize.Size10)
	setp(NG795, "Text", "C")
	setp(NG795, "TextColor3", Color3.new(1, 1, 1))
	setp(NG795, "Parent", NG794)
	NG796 = Instance.new("ImageButton")
	setp(NG796, "AutoButtonColor", false)
	setp(NG796, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG796, "BackgroundTransparency", 1)
	setp(NG796, "BorderSizePixel", 0)
	setp(NG796, "Name", "SurfaceButton")
	setp(NG796, "Position", UDim2.new(0, 0, 0, 70))
	setp(NG796, "Size", UDim2.new(0, 35, 0, 35))
	NG796.Style = Enum.ButtonStyle.Custom
	setp(NG796, "Image", "http://www.roblox.com/asset/?id=141803491")
	setp(NG796, "Parent", NG773)
	NG797 = Instance.new("TextLabel")
	setp(NG797, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG797, "BackgroundTransparency", 1)
	setp(NG797, "BorderSizePixel", 0)
	setp(NG797, "Name", "Shortcut")
	setp(NG797, "Size", UDim2.new(0, 13, 0, 13))
	setp(NG797, "Font", Enum.Font.ArialBold)
	setp(NG797, "FontSize", Enum.FontSize.Size10)
	setp(NG797, "Text", "B")
	setp(NG797, "TextColor3", Color3.new(1, 1, 1))
	setp(NG797, "Parent", NG796)
	NG798 = Instance.new("ImageButton")
	setp(NG798, "AutoButtonColor", false)
	setp(NG798, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG798, "BackgroundTransparency", 1)
	setp(NG798, "BorderSizePixel", 0)
	setp(NG798, "Name", "TextureButton")
	setp(NG798, "Position", UDim2.new(0, 0, 0, 175))
	setp(NG798, "Size", UDim2.new(0, 35, 0, 35))
	NG798.Style = Enum.ButtonStyle.Custom
	setp(NG798, "Image", "http://www.roblox.com/asset/?id=141805275")
	setp(NG798, "Parent", NG773)
	NG799 = Instance.new("TextLabel")
	setp(NG799, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG799, "BackgroundTransparency", 1)
	setp(NG799, "BorderSizePixel", 0)
	setp(NG799, "Name", "Shortcut")
	setp(NG799, "Size", UDim2.new(0, 13, 0, 13))
	setp(NG799, "Font", Enum.Font.ArialBold)
	setp(NG799, "FontSize", Enum.FontSize.Size10)
	setp(NG799, "Text", "G")
	setp(NG799, "TextColor3", Color3.new(1, 1, 1))
	setp(NG799, "Parent", NG798)
	NG800 = Instance.new("ImageButton")
	setp(NG800, "AutoButtonColor", false)
	setp(NG800, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG800, "BackgroundTransparency", 1)
	setp(NG800, "BorderSizePixel", 0)
	setp(NG800, "Name", "AnchorButton")
	setp(NG800, "Position", UDim2.new(0, 0, 0, 105))
	setp(NG800, "Size", UDim2.new(0, 35, 0, 35))
	NG800.Style = Enum.ButtonStyle.Custom
	setp(NG800, "Image", "http://www.roblox.com/asset/?id=141741323")
	setp(NG800, "Parent", NG773)
	NG801 = Instance.new("TextLabel")
	setp(NG801, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG801, "BackgroundTransparency", 1)
	setp(NG801, "BorderSizePixel", 0)
	setp(NG801, "Name", "Shortcut")
	setp(NG801, "Size", UDim2.new(0, 13, 0, 13))
	setp(NG801, "Font", Enum.Font.ArialBold)
	setp(NG801, "FontSize", Enum.FontSize.Size10)
	setp(NG801, "Text", "M")
	setp(NG801, "TextColor3", Color3.new(1, 1, 1))
	setp(NG801, "Parent", NG800)
	NG802 = Instance.new("Frame")
	setp(NG802, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG802, "BackgroundTransparency", 0.20000000298023)
	setp(NG802, "BorderSizePixel", 0)
	setp(NG802, "Name", "HelpInfo")
	setp(NG802, "Position", UDim2.new(0, -120, 0, 0))
	setp(NG802, "Size", UDim2.new(0, 120, 0, 380))
	setp(NG802, "Visible", false)
	setp(NG802, "ClipsDescendants", true)
	setp(NG802, "Parent", NG649)
	NG803 = Instance.new("Frame")
	setp(NG803, "BackgroundTransparency", 1)
	setp(NG803, "BorderSizePixel", 0)
	setp(NG803, "Name", "BottomColorBar")
	setp(NG803, "Position", UDim2.new(0, 0, 1, 0))
	NG803.Rotation = 180
	setp(NG803, "Size", UDim2.new(1, 0, 0, 3))
	setp(NG803, "Parent", NG802)
	NG804 = Instance.new("Frame")
	setp(NG804, "BackgroundColor3", Color3.new(1, 0.686275, 0))
	setp(NG804, "BackgroundTransparency", 0.25)
	setp(NG804, "BorderSizePixel", 0)
	setp(NG804, "Name", "Yellow")
	setp(NG804, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG804, "Parent", NG803)
	NG805 = Instance.new("Frame")
	setp(NG805, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG805, "BackgroundTransparency", 0.25)
	setp(NG805, "BorderSizePixel", 0)
	setp(NG805, "Name", "Green")
	setp(NG805, "Position", UDim2.new(0.200000003, 0, 0, 0))
	setp(NG805, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG805, "Parent", NG803)
	NG806 = Instance.new("Frame")
	setp(NG806, "BackgroundColor3", Color3.new(0.0156863, 0.686275, 0.92549))
	setp(NG806, "BackgroundTransparency", 0.25)
	setp(NG806, "BorderSizePixel", 0)
	setp(NG806, "Name", "Blue")
	setp(NG806, "Position", UDim2.new(0.400000006, 0, 0, 0))
	setp(NG806, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG806, "Parent", NG803)
	NG807 = Instance.new("Frame")
	setp(NG807, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG807, "BackgroundTransparency", 0.25)
	setp(NG807, "BorderSizePixel", 0)
	setp(NG807, "Name", "Red")
	setp(NG807, "Position", UDim2.new(0.600000024, 0, 0, 0))
	setp(NG807, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG807, "Parent", NG803)
	NG808 = Instance.new("Frame")
	setp(NG808, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG808, "BackgroundTransparency", 0.25)
	setp(NG808, "BorderSizePixel", 0)
	setp(NG808, "Name", "Purple")
	setp(NG808, "Position", UDim2.new(0.800000012, 0, 0, 0))
	setp(NG808, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG808, "Parent", NG803)
	NG809 = Instance.new("Frame")
	setp(NG809, "BackgroundTransparency", 1)
	setp(NG809, "BorderSizePixel", 0)
	setp(NG809, "Name", "Content")
	setp(NG809, "Size", UDim2.new(1, 0, 0, 680))
	setp(NG809, "Parent", NG802)
	NG810 = Instance.new("TextLabel")
	setp(NG810, "BackgroundTransparency", 1)
	setp(NG810, "BorderSizePixel", 0)
	setp(NG810, "Name", "ToolDescription")
	setp(NG810, "Position", UDim2.new(0, 10, 0, 102))
	setp(NG810, "Size", UDim2.new(0, 85, 0, 62))
	setp(NG810, "Font", Enum.Font.Arial)
	setp(NG810, "FontSize", Enum.FontSize.Size10)
	setp(NG810, "Text", "Hover over any tool icon to reveal more details.")
	setp(NG810, "TextColor3", Color3.new(1, 1, 1))
	setp(NG810, "TextWrapped", true)
	setp(NG810, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG810, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG810, "Parent", NG809)
	NG811 = Instance.new("Frame")
	setp(NG811, "BackgroundTransparency", 1)
	setp(NG811, "BorderSizePixel", 0)
	setp(NG811, "Name", "ColorBar")
	setp(NG811, "Size", UDim2.new(1, 0, 0, 3))
	setp(NG811, "Parent", NG809)
	NG812 = Instance.new("Frame")
	setp(NG812, "BackgroundColor3", Color3.new(1, 0.686275, 0))
	setp(NG812, "BackgroundTransparency", 0.25)
	setp(NG812, "BorderSizePixel", 0)
	setp(NG812, "Name", "Yellow")
	setp(NG812, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG812, "Parent", NG811)
	NG813 = Instance.new("Frame")
	setp(NG813, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG813, "BackgroundTransparency", 0.25)
	setp(NG813, "BorderSizePixel", 0)
	setp(NG813, "Name", "Green")
	setp(NG813, "Position", UDim2.new(0.200000003, 0, 0, 0))
	setp(NG813, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG813, "Parent", NG811)
	NG814 = Instance.new("Frame")
	setp(NG814, "BackgroundColor3", Color3.new(0.0156863, 0.686275, 0.92549))
	setp(NG814, "BackgroundTransparency", 0.25)
	setp(NG814, "BorderSizePixel", 0)
	setp(NG814, "Name", "Blue")
	setp(NG814, "Position", UDim2.new(0.400000006, 0, 0, 0))
	setp(NG814, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG814, "Parent", NG811)
	NG815 = Instance.new("Frame")
	setp(NG815, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG815, "BackgroundTransparency", 0.25)
	setp(NG815, "BorderSizePixel", 0)
	setp(NG815, "Name", "Red")
	setp(NG815, "Position", UDim2.new(0.600000024, 0, 0, 0))
	setp(NG815, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG815, "Parent", NG811)
	NG816 = Instance.new("Frame")
	setp(NG816, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG816, "BackgroundTransparency", 0.25)
	setp(NG816, "BorderSizePixel", 0)
	setp(NG816, "Name", "Purple")
	setp(NG816, "Position", UDim2.new(0.800000012, 0, 0, 0))
	setp(NG816, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG816, "Parent", NG811)
	NG817 = Instance.new("TextLabel")
	setp(NG817, "BackgroundTransparency", 1)
	setp(NG817, "BorderSizePixel", 0)
	setp(NG817, "Name", "ToolName")
	setp(NG817, "Position", UDim2.new(0, 10, 0, 4))
	setp(NG817, "Size", UDim2.new(0, 84, 0, 92))
	setp(NG817, "Font", Enum.Font.ArialBold)
	setp(NG817, "FontSize", Enum.FontSize.Size10)
	setp(NG817, "Text", "BUILDING\nTOOLS BY F3X\nONE-SCRIPT MOD\nBY NICKOAKZ\nUPDATES BY\nltseverydayyou")
	setp(NG817, "TextColor3", Color3.new(1, 1, 1))
	setp(NG817, "TextWrapped", true)
	setp(NG817, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG817, "Parent", NG809)
	NG818 = Instance.new("Frame")
	setp(NG818, "BackgroundTransparency", 1)
	setp(NG818, "BorderSizePixel", 0)
	setp(NG818, "Name", "SelectionInfo")
	setp(NG818, "Position", UDim2.new(0, 0, 0, 170))
	setp(NG818, "Size", UDim2.new(1, 0, 0, 150))
	setp(NG818, "Parent", NG809)
	NG819 = Instance.new("TextLabel")
	setp(NG819, "BackgroundTransparency", 1)
	setp(NG819, "BorderSizePixel", 0)
	setp(NG819, "Position", UDim2.new(0, 10, 0, 15))
	setp(NG819, "Size", UDim2.new(0, 82, 0, 240))
	setp(NG819, "Font", Enum.Font.Arial)
	setp(NG819, "FontSize", Enum.FontSize.Size10)
	setp(NG819, "Text", "You can select multiple parts by holding [Shift] and clicking on each part.  You can also hold [Shift], click, and drag to select parts in that area.  Press [Shift + K] to select parts inside of the selected parts.  Press [Shift + R] to clear your selection.")
	setp(NG819, "TextColor3", Color3.new(1, 1, 1))
	setp(NG819, "TextWrapped", true)
	setp(NG819, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG819, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG819, "Parent", NG818)
	NG820 = Instance.new("TextLabel")
	setp(NG820, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG820, "BackgroundTransparency", 1)
	setp(NG820, "BorderSizePixel", 0)
	setp(NG820, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG820, "Size", UDim2.new(0, 80, 0, 12))
	setp(NG820, "Font", Enum.Font.ArialBold)
	setp(NG820, "FontSize", Enum.FontSize.Size10)
	setp(NG820, "Text", "Selecting")
	setp(NG820, "TextColor3", Color3.new(1, 1, 1))
	setp(NG820, "TextWrapped", true)
	setp(NG820, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG820, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG820, "Parent", NG818)
	NG821 = Instance.new("Frame")
	setp(NG821, "BackgroundTransparency", 1)
	setp(NG821, "BorderSizePixel", 0)
	setp(NG821, "Name", "ExportingInfo")
	setp(NG821, "Position", UDim2.new(0, 0, 0, 420))
	setp(NG821, "Size", UDim2.new(1, 0, 0, 220))
	setp(NG821, "Parent", NG809)
	NG822 = Instance.new("TextLabel")
	setp(NG822, "BackgroundTransparency", 1)
	setp(NG822, "BorderSizePixel", 0)
	setp(NG822, "Position", UDim2.new(0, 10, 0, 30))
	setp(NG822, "Size", UDim2.new(0, 82, 0, 200))
	setp(NG822, "Font", Enum.Font.Arial)
	setp(NG822, "FontSize", Enum.FontSize.Size10)
	setp(NG822, "Text", "You can export any creations you built with Building Tools by F3X by using the export button on the dock (or pressing shift + P).  Install this plugin (roblox.com/item.aspx?id=142485815) in ROBLOX Studio to import your creation.")
	setp(NG822, "TextColor3", Color3.new(1, 1, 1))
	setp(NG822, "TextWrapped", true)
	setp(NG822, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG822, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG822, "Parent", NG821)
	NG823 = Instance.new("TextLabel")
	setp(NG823, "BackgroundColor3", Color3.new(0.239216, 0.239216, 0.239216))
	setp(NG823, "BackgroundTransparency", 1)
	setp(NG823, "BorderSizePixel", 0)
	setp(NG823, "Position", UDim2.new(0, 10, 0, 0))
	setp(NG823, "Size", UDim2.new(0, 80, 0, 24))
	setp(NG823, "Font", Enum.Font.ArialBold)
	setp(NG823, "FontSize", Enum.FontSize.Size10)
	setp(NG823, "Text", "Exporting your creations")
	setp(NG823, "TextColor3", Color3.new(1, 1, 1))
	setp(NG823, "TextWrapped", true)
	setp(NG823, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG823, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG823, "Parent", NG821)
	NG824 = Instance.new("Frame")
	setp(NG824, "Active", true)
	setp(NG824, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG824, "BackgroundTransparency", 1)
	setp(NG824, "BorderSizePixel", 0)
	setp(NG824, "Name", "BTGroupsGUI")
	setp(NG824, "Position", UDim2.new(0, -210, 0, 0))
	setp(NG824, "Size", UDim2.new(0, 200, 0, 100))
	setp(NG824, "Parent", NG1)
	NG825 = Instance.new("Frame")
	setp(NG825, "BackgroundTransparency", 1)
	setp(NG825, "BorderSizePixel", 0)
	setp(NG825, "Name", "Templates")
	setp(NG825, "Visible", false)
	setp(NG825, "Parent", NG824)
	NG826 = Instance.new("Frame")
	setp(NG826, "BackgroundColor3", Color3.new(0.266667, 0.266667, 0.266667))
	setp(NG826, "BackgroundTransparency", 0.64999997615814)
	setp(NG826, "BorderSizePixel", 0)
	setp(NG826, "Name", "GroupButton")
	setp(NG826, "Size", UDim2.new(1, -5, 0, 25))
	setp(NG826, "Parent", NG825)
	NG827 = Instance.new("ImageButton")
	setp(NG827, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG827, "BackgroundTransparency", 1)
	setp(NG827, "BorderSizePixel", 0)
	setp(NG827, "Name", "EditButton")
	setp(NG827, "Position", UDim2.new(1, -50, 0, 5))
	setp(NG827, "Size", UDim2.new(0, 16, 0, 16))
	NG827.Style = Enum.ButtonStyle.Custom
	setp(NG827, "Image", "http://www.roblox.com/asset/?id=160400465")
	setp(NG827, "ImageTransparency", 0.25)
	setp(NG827, "Parent", NG826)
	NG828 = Instance.new("Frame")
	setp(NG828, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG828, "BorderSizePixel", 0)
	setp(NG828, "Name", "RightTooltip")
	setp(NG828, "Position", UDim2.new(0, -50, 0, 0))
	setp(NG828, "Size", UDim2.new(0, 40, 0, 16))
	setp(NG828, "Visible", false)
	setp(NG828, "ZIndex", 2)
	setp(NG828, "Parent", NG827)
	NG829 = Instance.new("Frame")
	setp(NG829, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG829, "BorderSizePixel", 0)
	setp(NG829, "Name", "Tip")
	setp(NG829, "Position", UDim2.new(1, -6, 0, 2))
	NG829.Rotation = 45
	setp(NG829, "Size", UDim2.new(0, 12, 0, 12))
	setp(NG829, "ZIndex", 2)
	setp(NG829, "Parent", NG828)
	NG830 = Instance.new("TextLabel")
	setp(NG830, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG830, "BackgroundTransparency", 1)
	setp(NG830, "BorderSizePixel", 0)
	setp(NG830, "Name", "Text")
	setp(NG830, "Size", UDim2.new(1, 4, 1, 0))
	setp(NG830, "ZIndex", 3)
	setp(NG830, "Font", Enum.Font.ArialBold)
	setp(NG830, "FontSize", Enum.FontSize.Size10)
	setp(NG830, "Text", "RENAME")
	setp(NG830, "TextColor3", Color3.new(1, 1, 1))
	setp(NG830, "Parent", NG828)
	NG831 = Instance.new("ImageButton")
	setp(NG831, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG831, "BackgroundTransparency", 1)
	setp(NG831, "BorderSizePixel", 0)
	setp(NG831, "Name", "IgnoreButton")
	setp(NG831, "Position", UDim2.new(1, -25, 0, 5))
	setp(NG831, "Size", UDim2.new(0, 16, 0, 16))
	NG831.Style = Enum.ButtonStyle.Custom
	setp(NG831, "Image", "http://www.roblox.com/asset/?id=160408836")
	setp(NG831, "ImageTransparency", 0.25)
	setp(NG831, "Parent", NG826)
	NG832 = Instance.new("Frame")
	setp(NG832, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG832, "BorderSizePixel", 0)
	setp(NG832, "Name", "RightTooltip")
	setp(NG832, "Position", UDim2.new(0, -58, 0, 0))
	setp(NG832, "Size", UDim2.new(0, 48, 0, 16))
	setp(NG832, "Visible", false)
	setp(NG832, "ZIndex", 2)
	setp(NG832, "Parent", NG831)
	NG833 = Instance.new("Frame")
	setp(NG833, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG833, "BorderSizePixel", 0)
	setp(NG833, "Name", "Tip")
	setp(NG833, "Position", UDim2.new(1, -6, 0, 2))
	NG833.Rotation = 45
	setp(NG833, "Size", UDim2.new(0, 12, 0, 12))
	setp(NG833, "ZIndex", 2)
	setp(NG833, "Parent", NG832)
	NG834 = Instance.new("TextLabel")
	setp(NG834, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG834, "BackgroundTransparency", 1)
	setp(NG834, "BorderSizePixel", 0)
	setp(NG834, "Name", "Text")
	setp(NG834, "Size", UDim2.new(1, 4, 1, 0))
	setp(NG834, "ZIndex", 3)
	setp(NG834, "Font", Enum.Font.ArialBold)
	setp(NG834, "FontSize", Enum.FontSize.Size10)
	setp(NG834, "Text", "UNIGNORE")
	setp(NG834, "TextColor3", Color3.new(1, 1, 1))
	setp(NG834, "Parent", NG832)
	NG835 = Instance.new("ImageButton")
	setp(NG835, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG835, "BackgroundTransparency", 1)
	setp(NG835, "BorderSizePixel", 0)
	setp(NG835, "Name", "UpdateButton")
	setp(NG835, "Position", UDim2.new(0, 12, 0, 5))
	setp(NG835, "Size", UDim2.new(0, 16, 0, 16))
	NG835.Style = Enum.ButtonStyle.Custom
	setp(NG835, "Image", "http://www.roblox.com/asset/?id=160402908")
	setp(NG835, "ImageTransparency", 0.25)
	setp(NG835, "Parent", NG826)
	NG836 = Instance.new("Frame")
	setp(NG836, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG836, "BorderSizePixel", 0)
	setp(NG836, "Name", "LeftTooltip")
	setp(NG836, "Position", UDim2.new(1, 12, 0, 0))
	setp(NG836, "Size", UDim2.new(0, 38, 0, 16))
	setp(NG836, "Visible", false)
	setp(NG836, "ZIndex", 3)
	setp(NG836, "Parent", NG835)
	NG837 = Instance.new("Frame")
	setp(NG837, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG837, "BorderSizePixel", 0)
	setp(NG837, "Name", "Tip")
	setp(NG837, "Position", UDim2.new(0, -6, 0, 2))
	NG837.Rotation = 45
	setp(NG837, "Size", UDim2.new(0, 12, 0, 12))
	setp(NG837, "ZIndex", 3)
	setp(NG837, "Parent", NG836)
	NG838 = Instance.new("TextLabel")
	setp(NG838, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG838, "BackgroundTransparency", 1)
	setp(NG838, "BorderSizePixel", 0)
	setp(NG838, "Name", "Text")
	setp(NG838, "Position", UDim2.new(0, -4, 0, 0))
	setp(NG838, "Size", UDim2.new(1, 4, 1, 0))
	setp(NG838, "ZIndex", 3)
	setp(NG838, "Font", Enum.Font.ArialBold)
	setp(NG838, "FontSize", Enum.FontSize.Size10)
	setp(NG838, "Text", "UPDATE")
	setp(NG838, "TextColor3", Color3.new(1, 1, 1))
	setp(NG838, "Parent", NG836)
	NG839 = Instance.new("Frame")
	setp(NG839, "BackgroundTransparency", 1)
	setp(NG839, "BorderSizePixel", 0)
	setp(NG839, "Name", "GroupNameArea")
	setp(NG839, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG839, "Size", UDim2.new(0, 90, 0, 25))
	setp(NG839, "Parent", NG826)
	NG840 = Instance.new("Frame")
	setp(NG840, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG840, "BorderSizePixel", 0)
	setp(NG840, "Name", "LeftTooltip")
	setp(NG840, "Position", UDim2.new(1, 12, 0, 5))
	setp(NG840, "Size", UDim2.new(0, 38, 0, 16))
	setp(NG840, "Visible", false)
	setp(NG840, "ZIndex", 2)
	setp(NG840, "Parent", NG839)
	NG841 = Instance.new("Frame")
	setp(NG841, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG841, "BorderSizePixel", 0)
	setp(NG841, "Name", "Tip")
	setp(NG841, "Position", UDim2.new(0, -6, 0, 2))
	NG841.Rotation = 45
	setp(NG841, "Size", UDim2.new(0, 12, 0, 12))
	setp(NG841, "ZIndex", 2)
	setp(NG841, "Parent", NG840)
	NG842 = Instance.new("TextLabel")
	setp(NG842, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG842, "BackgroundTransparency", 1)
	setp(NG842, "BorderSizePixel", 0)
	setp(NG842, "Name", "Text")
	setp(NG842, "Position", UDim2.new(0, -4, 0, 0))
	setp(NG842, "Size", UDim2.new(1, 4, 1, 0))
	setp(NG842, "ZIndex", 3)
	setp(NG842, "Font", Enum.Font.ArialBold)
	setp(NG842, "FontSize", Enum.FontSize.Size10)
	setp(NG842, "Text", "SELECT")
	setp(NG842, "TextColor3", Color3.new(1, 1, 1))
	setp(NG842, "Parent", NG840)
	NG843 = Instance.new("TextButton")
	setp(NG843, "Active", true)
	setp(NG843, "BackgroundTransparency", 1)
	setp(NG843, "BorderSizePixel", 0)
	setp(NG843, "Name", "GroupName")
	setp(NG843, "Position", UDim2.new(0, 35, 0, 0))
	NG843.Selectable = true
	setp(NG843, "Size", UDim2.new(0, 90, 0, 25))
	NG843.Style = Enum.ButtonStyle.Custom
	setp(NG843, "ZIndex", 2)
	setp(NG843, "Font", Enum.Font.ArialBold)
	setp(NG843, "FontSize", Enum.FontSize.Size10)
	setp(NG843, "Text", "Group 1")
	setp(NG843, "TextColor3", Color3.new(1, 1, 1))
	setp(NG843, "TextStrokeTransparency", 0.80000001192093)
	setp(NG843, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG843, "ClipsDescendants", true)
	setp(NG843, "Parent", NG826)
	NG844 = Instance.new("TextBox")
	setp(NG844, "BackgroundTransparency", 1)
	setp(NG844, "BorderSizePixel", 0)
	setp(NG844, "Name", "GroupNamer")
	setp(NG844, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG844, "Size", UDim2.new(0, 90, 0, 25))
	setp(NG844, "Visible", false)
	setp(NG844, "ZIndex", 2)
	setp(NG844, "Font", Enum.Font.ArialBold)
	setp(NG844, "FontSize", Enum.FontSize.Size10)
	setp(NG844, "Text", "Group 1")
	setp(NG844, "TextColor3", Color3.new(1, 1, 1))
	setp(NG844, "TextStrokeTransparency", 0.80000001192093)
	setp(NG844, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG844, "ClipsDescendants", true)
	setp(NG844, "Parent", NG826)
	NG845 = Instance.new("ScrollingFrame")
	setp(NG845, "BackgroundTransparency", 1)
	setp(NG845, "BorderSizePixel", 0)
	setp(NG845, "Name", "GroupList")
	setp(NG845, "Position", UDim2.new(0, 10, 0, 30))
	NG845.Selectable = true
	setp(NG845, "Size", UDim2.new(1, -10, 0, 70))
	NG845.BottomImage = "rbxasset://textures/blackBkg_square.png"
	setp(NG845, "CanvasSize", UDim2.new(1, -10, 0, 0))
	NG845.MidImage = "rbxasset://textures/blackBkg_square.png"
	setp(NG845, "ScrollBarThickness", 3)
	NG845.TopImage = "rbxasset://textures/blackBkg_square.png"
	setp(NG845, "ClipsDescendants", true)
	setp(NG845, "Parent", NG824)
	NG846 = Instance.new("TextLabel")
	setp(NG846, "BackgroundTransparency", 1)
	setp(NG846, "BorderSizePixel", 0)
	setp(NG846, "Name", "SelectNote")
	setp(NG846, "Position", UDim2.new(0, 10, 0, 27))
	setp(NG846, "Size", UDim2.new(1, -10, 0, 15))
	setp(NG846, "Visible", false)
	setp(NG846, "FontSize", Enum.FontSize.Size14)
	setp(NG846, "Text", "Select something to use this tool.")
	setp(NG846, "TextColor3", Color3.new(1, 1, 1))
	setp(NG846, "TextScaled", true)
	setp(NG846, "TextStrokeTransparency", 0.5)
	setp(NG846, "TextWrapped", true)
	setp(NG846, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG846, "Parent", NG824)
	NG847 = Instance.new("Frame")
	setp(NG847, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG847, "BackgroundTransparency", 1)
	setp(NG847, "BorderSizePixel", 0)
	setp(NG847, "Name", "Title")
	setp(NG847, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG847, "Parent", NG824)
	NG848 = Instance.new("TextButton")
	setp(NG848, "Active", true)
	setp(NG848, "BackgroundColor3", Color3.new(0.223529, 0.223529, 0.223529))
	setp(NG848, "BackgroundTransparency", 0.5)
	setp(NG848, "BorderSizePixel", 0)
	setp(NG848, "Name", "CreateButton")
	setp(NG848, "Position", UDim2.new(1, -40, 0, 3))
	NG848.Selectable = true
	setp(NG848, "Size", UDim2.new(0, 40, 0, 16))
	NG848.Style = Enum.ButtonStyle.Custom
	setp(NG848, "Font", Enum.Font.ArialBold)
	setp(NG848, "FontSize", Enum.FontSize.Size10)
	setp(NG848, "Text", "NEW")
	setp(NG848, "TextColor3", Color3.new(1, 1, 1))
	setp(NG848, "Parent", NG847)
	NG849 = Instance.new("Frame")
	setp(NG849, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG849, "BorderSizePixel", 0)
	setp(NG849, "Name", "ColorBar")
	setp(NG849, "Position", UDim2.new(0, 7, 0, -3))
	setp(NG849, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG849, "Parent", NG847)
	NG850 = Instance.new("TextLabel")
	setp(NG850, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG850, "BackgroundTransparency", 1)
	setp(NG850, "BorderSizePixel", 0)
	setp(NG850, "Name", "Label")
	setp(NG850, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG850, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG850, "Font", Enum.Font.ArialBold)
	setp(NG850, "FontSize", Enum.FontSize.Size10)
	setp(NG850, "Text", "SELECTION GROUPS")
	setp(NG850, "TextColor3", Color3.new(1, 1, 1))
	setp(NG850, "TextStrokeTransparency", 0)
	setp(NG850, "TextWrapped", true)
	setp(NG850, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG850, "Parent", NG847)
	NG851 = Instance.new("Frame")
	setp(NG851, "Active", true)
	setp(NG851, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG851, "BackgroundTransparency", 1)
	setp(NG851, "BorderSizePixel", 0)
	setp(NG851, "Name", "BTExportDialog")
	setp(NG851, "Position", UDim2.new(0, 100, 0, 128))
	setp(NG851, "Size", UDim2.new(0, 200, 0, 110))
	NG851.Draggable = true
	setp(NG851, "Parent", NG1)
	NG852 = Instance.new("Frame")
	setp(NG852, "BackgroundTransparency", 1)
	setp(NG852, "BorderSizePixel", 0)
	setp(NG852, "Name", "Info")
	setp(NG852, "Size", UDim2.new(1, 0, 0, 75))
	setp(NG852, "Visible", false)
	setp(NG852, "ClipsDescendants", true)
	setp(NG852, "Parent", NG851)
	NG853 = Instance.new("TextLabel")
	setp(NG853, "BackgroundTransparency", 1)
	setp(NG853, "BorderSizePixel", 0)
	setp(NG853, "Name", "CreationIDLabel")
	setp(NG853, "Position", UDim2.new(0, 0, 0, 5))
	setp(NG853, "Size", UDim2.new(1, 0, 0, 40))
	setp(NG853, "Font", Enum.Font.SourceSansBold)
	setp(NG853, "FontSize", Enum.FontSize.Size18)
	setp(NG853, "Text", "Your creation's ID:")
	setp(NG853, "TextColor3", Color3.new(1, 1, 1))
	setp(NG853, "TextStrokeTransparency", 0.75)
	setp(NG853, "Parent", NG852)
	NG854 = Instance.new("TextLabel")
	setp(NG854, "BackgroundTransparency", 1)
	setp(NG854, "BorderSizePixel", 0)
	setp(NG854, "Name", "CreationID")
	setp(NG854, "Position", UDim2.new(0, 0, 0, 30))
	setp(NG854, "Size", UDim2.new(1, 0, 0, 40))
	setp(NG854, "Font", Enum.Font.SourceSansBold)
	setp(NG854, "FontSize", Enum.FontSize.Size24)
	setp(NG854, "Text", "j5of0")
	setp(NG854, "TextColor3", Color3.new(0.439216, 0.439216, 0.439216))
	NG854.TextStrokeColor3 = Color3.new(1, 1, 1)
	setp(NG854, "TextStrokeTransparency", 0)
	setp(NG854, "Parent", NG852)
	NG855 = Instance.new("Frame")
	setp(NG855, "BackgroundTransparency", 1)
	setp(NG855, "BorderSizePixel", 0)
	setp(NG855, "Name", "ColorBar")
	setp(NG855, "Size", UDim2.new(1, 0, 0, 3))
	setp(NG855, "Parent", NG852)
	NG856 = Instance.new("Frame")
	setp(NG856, "BackgroundColor3", Color3.new(1, 0.686275, 0))
	setp(NG856, "BorderSizePixel", 0)
	setp(NG856, "Name", "Yellow")
	setp(NG856, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG856, "Parent", NG855)
	NG857 = Instance.new("Frame")
	setp(NG857, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG857, "BorderSizePixel", 0)
	setp(NG857, "Name", "Green")
	setp(NG857, "Position", UDim2.new(0.200000003, 0, 0, 0))
	setp(NG857, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG857, "Parent", NG855)
	NG858 = Instance.new("Frame")
	setp(NG858, "BackgroundColor3", Color3.new(0.0156863, 0.686275, 0.92549))
	setp(NG858, "BorderSizePixel", 0)
	setp(NG858, "Name", "Blue")
	setp(NG858, "Position", UDim2.new(0.400000006, 0, 0, 0))
	setp(NG858, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG858, "Parent", NG855)
	NG859 = Instance.new("Frame")
	setp(NG859, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG859, "BorderSizePixel", 0)
	setp(NG859, "Name", "Red")
	setp(NG859, "Position", UDim2.new(0.600000024, 0, 0, 0))
	setp(NG859, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG859, "Parent", NG855)
	NG860 = Instance.new("Frame")
	setp(NG860, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG860, "BorderSizePixel", 0)
	setp(NG860, "Name", "Purple")
	setp(NG860, "Position", UDim2.new(0.800000012, 0, 0, 0))
	setp(NG860, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG860, "Parent", NG855)
	NG861 = Instance.new("Frame")
	setp(NG861, "BackgroundTransparency", 1)
	setp(NG861, "BorderSizePixel", 0)
	setp(NG861, "Name", "Tip")
	setp(NG861, "Position", UDim2.new(0, 0, 0, 75))
	setp(NG861, "Size", UDim2.new(1, 0, 0, 30))
	setp(NG861, "Visible", false)
	setp(NG861, "Parent", NG851)
	NG862 = Instance.new("TextLabel")
	setp(NG862, "BackgroundTransparency", 1)
	setp(NG862, "BorderSizePixel", 0)
	setp(NG862, "Name", "Tip")
	setp(NG862, "Position", UDim2.new(0, 0, 0, 7))
	setp(NG862, "Size", UDim2.new(1, 0, 0, 30))
	setp(NG862, "Font", Enum.Font.SourceSansBold)
	setp(NG862, "FontSize", Enum.FontSize.Size12)
	setp(NG862, "Text", "Use the ID above to import your creation using the plugin.")
	setp(NG862, "TextColor3", Color3.new(1, 1, 1))
	setp(NG862, "TextStrokeTransparency", 0.75)
	setp(NG862, "TextWrapped", true)
	setp(NG862, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG862, "TextYAlignment", Enum.TextYAlignment.Top)
	setp(NG862, "Parent", NG861)
	NG863 = Instance.new("Frame")
	setp(NG863, "BackgroundTransparency", 1)
	setp(NG863, "BorderSizePixel", 0)
	setp(NG863, "Name", "ColorBar")
	NG863.Rotation = 180
	setp(NG863, "Size", UDim2.new(1, 0, 0, 3))
	setp(NG863, "Parent", NG861)
	NG864 = Instance.new("Frame")
	setp(NG864, "BackgroundColor3", Color3.new(1, 0.686275, 0))
	setp(NG864, "BorderSizePixel", 0)
	setp(NG864, "Name", "Yellow")
	setp(NG864, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG864, "Parent", NG863)
	NG865 = Instance.new("Frame")
	setp(NG865, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG865, "BorderSizePixel", 0)
	setp(NG865, "Name", "Green")
	setp(NG865, "Position", UDim2.new(0.200000003, 0, 0, 0))
	setp(NG865, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG865, "Parent", NG863)
	NG866 = Instance.new("Frame")
	setp(NG866, "BackgroundColor3", Color3.new(0.0156863, 0.686275, 0.92549))
	setp(NG866, "BorderSizePixel", 0)
	setp(NG866, "Name", "Blue")
	setp(NG866, "Position", UDim2.new(0.400000006, 0, 0, 0))
	setp(NG866, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG866, "Parent", NG863)
	NG867 = Instance.new("Frame")
	setp(NG867, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG867, "BorderSizePixel", 0)
	setp(NG867, "Name", "Red")
	setp(NG867, "Position", UDim2.new(0.600000024, 0, 0, 0))
	setp(NG867, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG867, "Parent", NG863)
	NG868 = Instance.new("Frame")
	setp(NG868, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG868, "BorderSizePixel", 0)
	setp(NG868, "Name", "Purple")
	setp(NG868, "Position", UDim2.new(0.800000012, 0, 0, 0))
	setp(NG868, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG868, "Parent", NG863)
	NG869 = Instance.new("Frame")
	setp(NG869, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG869, "BackgroundTransparency", 1)
	setp(NG869, "BorderSizePixel", 0)
	setp(NG869, "Name", "Close")
	setp(NG869, "Position", UDim2.new(0, 0, 1, 5))
	setp(NG869, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG869, "Visible", false)
	setp(NG869, "Parent", NG851)
	NG870 = Instance.new("TextButton")
	setp(NG870, "Active", true)
	setp(NG870, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG870, "BackgroundTransparency", 0.5)
	setp(NG870, "BorderSizePixel", 0)
	setp(NG870, "Name", "Button")
	NG870.Selectable = true
	setp(NG870, "Size", UDim2.new(1, 0, 1, 0))
	NG870.Style = Enum.ButtonStyle.Custom
	setp(NG870, "FontSize", Enum.FontSize.Size14)
	setp(NG870, "Text", "Got it")
	setp(NG870, "TextColor3", Color3.new(1, 1, 1))
	setp(NG870, "TextStrokeTransparency", 0.80000001192093)
	setp(NG870, "Parent", NG869)
	NG871 = Instance.new("Frame")
	setp(NG871, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG871, "BackgroundTransparency", 0.30000001192093)
	setp(NG871, "BorderSizePixel", 0)
	setp(NG871, "Name", "Shadow")
	setp(NG871, "Position", UDim2.new(0, 0, 1, 0))
	setp(NG871, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG871, "ZIndex", 2)
	setp(NG871, "Parent", NG869)
	NG872 = Instance.new("Frame")
	setp(NG872, "BackgroundTransparency", 1)
	setp(NG872, "BorderSizePixel", 0)
	setp(NG872, "Name", "Loading")
	setp(NG872, "Size", UDim2.new(1, 0, 0, 80))
	setp(NG872, "ClipsDescendants", true)
	setp(NG872, "Parent", NG851)
	NG873 = Instance.new("Frame")
	setp(NG873, "BackgroundTransparency", 1)
	setp(NG873, "BorderSizePixel", 0)
	setp(NG873, "Name", "ColorBar")
	setp(NG873, "Size", UDim2.new(1, 0, 0, 3))
	setp(NG873, "Parent", NG872)
	NG874 = Instance.new("Frame")
	setp(NG874, "BackgroundColor3", Color3.new(1, 0.686275, 0))
	setp(NG874, "BackgroundTransparency", 0.25)
	setp(NG874, "BorderSizePixel", 0)
	setp(NG874, "Name", "Yellow")
	setp(NG874, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG874, "Parent", NG873)
	NG875 = Instance.new("Frame")
	setp(NG875, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG875, "BackgroundTransparency", 0.25)
	setp(NG875, "BorderSizePixel", 0)
	setp(NG875, "Name", "Green")
	setp(NG875, "Position", UDim2.new(0.200000003, 0, 0, 0))
	setp(NG875, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG875, "Parent", NG873)
	NG876 = Instance.new("Frame")
	setp(NG876, "BackgroundColor3", Color3.new(0.0156863, 0.686275, 0.92549))
	setp(NG876, "BackgroundTransparency", 0.25)
	setp(NG876, "BorderSizePixel", 0)
	setp(NG876, "Name", "Blue")
	setp(NG876, "Position", UDim2.new(0.400000006, 0, 0, 0))
	setp(NG876, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG876, "Parent", NG873)
	NG877 = Instance.new("Frame")
	setp(NG877, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG877, "BackgroundTransparency", 0.25)
	setp(NG877, "BorderSizePixel", 0)
	setp(NG877, "Name", "Red")
	setp(NG877, "Position", UDim2.new(0.600000024, 0, 0, 0))
	setp(NG877, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG877, "Parent", NG873)
	NG878 = Instance.new("Frame")
	setp(NG878, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG878, "BackgroundTransparency", 0.25)
	setp(NG878, "BorderSizePixel", 0)
	setp(NG878, "Name", "Purple")
	setp(NG878, "Position", UDim2.new(0.800000012, 0, 0, 0))
	setp(NG878, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG878, "Parent", NG873)
	NG879 = Instance.new("TextLabel")
	setp(NG879, "BackgroundTransparency", 1)
	setp(NG879, "BorderSizePixel", 0)
	setp(NG879, "Size", UDim2.new(1, 0, 0, 50))
	setp(NG879, "Font", Enum.Font.SourceSansBold)
	setp(NG879, "FontSize", Enum.FontSize.Size18)
	setp(NG879, "Text", "Uploading your creation...")
	setp(NG879, "TextColor3", Color3.new(1, 1, 1))
	setp(NG879, "TextStrokeTransparency", 0.80000001192093)
	setp(NG879, "TextWrapped", true)
	setp(NG879, "Parent", NG872)
	NG880 = Instance.new("Frame")
	setp(NG880, "BackgroundTransparency", 1)
	setp(NG880, "BorderSizePixel", 0)
	setp(NG880, "Name", "BottomColorBar")
	setp(NG880, "Position", UDim2.new(0, 0, 1, 0))
	NG880.Rotation = 180
	setp(NG880, "Size", UDim2.new(1, 0, 0, 3))
	setp(NG880, "Parent", NG872)
	NG881 = Instance.new("Frame")
	setp(NG881, "BackgroundColor3", Color3.new(1, 0.686275, 0))
	setp(NG881, "BackgroundTransparency", 0.25)
	setp(NG881, "BorderSizePixel", 0)
	setp(NG881, "Name", "Yellow")
	setp(NG881, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG881, "Parent", NG880)
	NG882 = Instance.new("Frame")
	setp(NG882, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG882, "BackgroundTransparency", 0.25)
	setp(NG882, "BorderSizePixel", 0)
	setp(NG882, "Name", "Green")
	setp(NG882, "Position", UDim2.new(0.200000003, 0, 0, 0))
	setp(NG882, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG882, "Parent", NG880)
	NG883 = Instance.new("Frame")
	setp(NG883, "BackgroundColor3", Color3.new(0.0156863, 0.686275, 0.92549))
	setp(NG883, "BackgroundTransparency", 0.25)
	setp(NG883, "BorderSizePixel", 0)
	setp(NG883, "Name", "Blue")
	setp(NG883, "Position", UDim2.new(0.400000006, 0, 0, 0))
	setp(NG883, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG883, "Parent", NG880)
	NG884 = Instance.new("Frame")
	setp(NG884, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG884, "BackgroundTransparency", 0.25)
	setp(NG884, "BorderSizePixel", 0)
	setp(NG884, "Name", "Red")
	setp(NG884, "Position", UDim2.new(0.600000024, 0, 0, 0))
	setp(NG884, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG884, "Parent", NG880)
	NG885 = Instance.new("Frame")
	setp(NG885, "BackgroundColor3", Color3.new(0.419608, 0.196078, 0.486275))
	setp(NG885, "BackgroundTransparency", 0.25)
	setp(NG885, "BorderSizePixel", 0)
	setp(NG885, "Name", "Purple")
	setp(NG885, "Position", UDim2.new(0.800000012, 0, 0, 0))
	setp(NG885, "Size", UDim2.new(0.200000003, 0, 1, 0))
	setp(NG885, "Parent", NG880)
	NG886 = Instance.new("TextButton")
	setp(NG886, "Active", true)
	setp(NG886, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG886, "BackgroundTransparency", 0.5)
	setp(NG886, "BorderSizePixel", 0)
	setp(NG886, "Name", "CloseButton")
	setp(NG886, "Position", UDim2.new(0, 0, 1, -30))
	NG886.Selectable = true
	setp(NG886, "Size", UDim2.new(1, 0, 0, 25))
	NG886.Style = Enum.ButtonStyle.Custom
	setp(NG886, "Font", Enum.Font.SourceSansBold)
	setp(NG886, "FontSize", Enum.FontSize.Size14)
	setp(NG886, "Text", "Close")
	setp(NG886, "TextColor3", Color3.new(1, 1, 1))
	setp(NG886, "TextStrokeTransparency", 0.85000002384186)
	setp(NG886, "Parent", NG872)
	NG887 = Instance.new("Frame")
	setp(NG887, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG887, "BackgroundTransparency", 0.69999998807907)
	setp(NG887, "BorderSizePixel", 0)
	setp(NG887, "Name", "Shadow")
	setp(NG887, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG887, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG887, "Parent", NG886)
	NG888 = Instance.new("Frame")
	setp(NG888, "Active", true)
	setp(NG888, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG888, "BackgroundTransparency", 1)
	setp(NG888, "BorderSizePixel", 0)
	setp(NG888, "Name", "BTDecorateToolGUI")
	setp(NG888, "Position", UDim2.new(0, 0, 0, 172))
	setp(NG888, "Size", UDim2.new(0, 200, 0, 125))
	NG888.Draggable = true
	setp(NG888, "Parent", NG1)
	NG889 = Instance.new("Frame")
	setp(NG889, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG889, "BorderSizePixel", 0)
	setp(NG889, "Name", "BottomColorBar")
	setp(NG889, "Position", UDim2.new(0, 5, 1, -2))
	setp(NG889, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG889, "Parent", NG888)
	NG890 = Instance.new("Frame")
	setp(NG890, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG890, "BackgroundTransparency", 1)
	setp(NG890, "BorderSizePixel", 0)
	setp(NG890, "Name", "Title")
	setp(NG890, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG890, "Parent", NG888)
	NG891 = Instance.new("Frame")
	setp(NG891, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG891, "BorderSizePixel", 0)
	setp(NG891, "Name", "ColorBar")
	setp(NG891, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG891, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG891, "Parent", NG890)
	NG892 = Instance.new("TextLabel")
	setp(NG892, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG892, "BackgroundTransparency", 1)
	setp(NG892, "BorderSizePixel", 0)
	setp(NG892, "Name", "Label")
	setp(NG892, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG892, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG892, "Font", Enum.Font.ArialBold)
	setp(NG892, "FontSize", Enum.FontSize.Size10)
	setp(NG892, "Text", "DECORATE TOOL")
	setp(NG892, "TextColor3", Color3.new(1, 1, 1))
	setp(NG892, "TextStrokeTransparency", 0)
	setp(NG892, "TextWrapped", true)
	setp(NG892, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG892, "Parent", NG890)
	NG893 = Instance.new("TextLabel")
	setp(NG893, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG893, "BackgroundTransparency", 1)
	setp(NG893, "BorderSizePixel", 0)
	setp(NG893, "Name", "F3XSignature")
	setp(NG893, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG893, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG893, "Font", Enum.Font.ArialBold)
	setp(NG893, "FontSize", Enum.FontSize.Size14)
	setp(NG893, "Text", "F3X")
	setp(NG893, "TextColor3", Color3.new(1, 1, 1))
	setp(NG893, "TextStrokeTransparency", 0.89999997615814)
	setp(NG893, "TextWrapped", true)
	setp(NG893, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG893, "Parent", NG890)
	NG894 = Instance.new("Frame")
	setp(NG894, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG894, "BackgroundTransparency", 0.67500001192093)
	setp(NG894, "BorderSizePixel", 0)
	setp(NG894, "Name", "Smoke")
	setp(NG894, "Position", UDim2.new(0, 10, 0, 30))
	setp(NG894, "Size", UDim2.new(1, -10, 0, 25))
	setp(NG894, "Parent", NG888)
	NG895 = Instance.new("TextLabel")
	setp(NG895, "BackgroundTransparency", 1)
	setp(NG895, "BorderSizePixel", 0)
	setp(NG895, "Name", "Label")
	setp(NG895, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG895, "Size", UDim2.new(0, 60, 0, 25))
	setp(NG895, "Font", Enum.Font.ArialBold)
	setp(NG895, "FontSize", Enum.FontSize.Size10)
	setp(NG895, "Text", "Smoke")
	setp(NG895, "TextColor3", Color3.new(1, 1, 1))
	setp(NG895, "TextStrokeTransparency", 0.5)
	setp(NG895, "TextWrapped", true)
	setp(NG895, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG895, "Parent", NG894)
	NG896 = Instance.new("ImageButton")
	setp(NG896, "BackgroundTransparency", 1)
	setp(NG896, "BorderSizePixel", 0)
	setp(NG896, "Name", "ArrowButton")
	setp(NG896, "Position", UDim2.new(0, 10, 0, 3))
	setp(NG896, "Size", UDim2.new(0, 20, 0, 20))
	NG896.Style = Enum.ButtonStyle.Custom
	setp(NG896, "Image", "http://www.roblox.com/asset/?id=134367382")
	setp(NG896, "Parent", NG894)
	NG897 = Instance.new("Frame")
	setp(NG897, "BackgroundColor3", Color3.new(1, 0.682353, 0.235294))
	setp(NG897, "BorderSizePixel", 0)
	setp(NG897, "Name", "ColorBar")
	setp(NG897, "Size", UDim2.new(0, 3, 1, 0))
	setp(NG897, "Parent", NG894)
	NG898 = Instance.new("TextButton")
	setp(NG898, "Active", true)
	setp(NG898, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG898, "BackgroundTransparency", 0.75)
	setp(NG898, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG898, "BorderSizePixel", 0)
	setp(NG898, "Name", "AddButton")
	setp(NG898, "Position", UDim2.new(1, -40, 0, 3))
	NG898.Selectable = true
	setp(NG898, "Size", UDim2.new(0, 35, 0, 19))
	NG898.Style = Enum.ButtonStyle.Custom
	setp(NG898, "Font", Enum.Font.ArialBold)
	setp(NG898, "FontSize", Enum.FontSize.Size10)
	setp(NG898, "Text", "ADD")
	setp(NG898, "TextColor3", Color3.new(1, 1, 1))
	setp(NG898, "Parent", NG894)
	NG899 = Instance.new("TextButton")
	setp(NG899, "Active", true)
	setp(NG899, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG899, "BackgroundTransparency", 0.75)
	setp(NG899, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG899, "BorderSizePixel", 0)
	setp(NG899, "Name", "RemoveButton")
	setp(NG899, "Position", UDim2.new(0, 127, 0, 3))
	NG899.Selectable = true
	setp(NG899, "Size", UDim2.new(0, 58, 0, 19))
	NG899.Style = Enum.ButtonStyle.Custom
	setp(NG899, "Visible", false)
	setp(NG899, "Font", Enum.Font.ArialBold)
	setp(NG899, "FontSize", Enum.FontSize.Size10)
	setp(NG899, "Text", "REMOVE")
	setp(NG899, "TextColor3", Color3.new(1, 1, 1))
	setp(NG899, "Parent", NG894)
	NG900 = Instance.new("Frame")
	setp(NG900, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG900, "BackgroundTransparency", 0.75)
	setp(NG900, "BorderSizePixel", 0)
	setp(NG900, "Name", "Shadow")
	setp(NG900, "Position", UDim2.new(0, 0, 1, -1))
	setp(NG900, "Size", UDim2.new(1, 0, 0, 1))
	setp(NG900, "Parent", NG894)
	NG901 = Instance.new("Frame")
	setp(NG901, "BackgroundTransparency", 1)
	setp(NG901, "BorderSizePixel", 0)
	setp(NG901, "Name", "Options")
	setp(NG901, "Position", UDim2.new(0, 3, 1, 0))
	setp(NG901, "Size", UDim2.new(1, -3, 0, 0))
	setp(NG901, "ClipsDescendants", true)
	setp(NG901, "Parent", NG894)
	NG902 = Instance.new("Frame")
	setp(NG902, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG902, "BackgroundTransparency", 1)
	setp(NG902, "BorderSizePixel", 0)
	setp(NG902, "Name", "ColorOption")
	setp(NG902, "Position", UDim2.new(0, 0, 0, 10))
	setp(NG902, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG902, "Parent", NG901)
	NG903 = Instance.new("TextLabel")
	setp(NG903, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG903, "BackgroundTransparency", 1)
	setp(NG903, "BorderSizePixel", 0)
	setp(NG903, "Name", "Label")
	setp(NG903, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG903, "Font", Enum.Font.ArialBold)
	setp(NG903, "FontSize", Enum.FontSize.Size10)
	setp(NG903, "Text", "Color")
	setp(NG903, "TextColor3", Color3.new(1, 1, 1))
	setp(NG903, "TextStrokeTransparency", 0)
	setp(NG903, "TextWrapped", true)
	setp(NG903, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG903, "Parent", NG902)
	NG904 = Instance.new("Frame")
	setp(NG904, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG904, "BackgroundTransparency", 1)
	setp(NG904, "BorderSizePixel", 0)
	setp(NG904, "Name", "RInput")
	setp(NG904, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG904, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG904, "Parent", NG902)
	NG905 = Instance.new("TextButton")
	setp(NG905, "Active", true)
	setp(NG905, "AutoButtonColor", false)
	setp(NG905, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG905, "BackgroundTransparency", 1)
	setp(NG905, "BorderSizePixel", 0)
	NG905.Selectable = true
	setp(NG905, "Size", UDim2.new(1, 0, 1, 0))
	NG905.Style = Enum.ButtonStyle.Custom
	setp(NG905, "ZIndex", 2)
	setp(NG905, "Font", Enum.Font.Legacy)
	setp(NG905, "FontSize", Enum.FontSize.Size8)
	setp(NG905, "Text", "")
	setp(NG905, "Parent", NG904)
	NG906 = Instance.new("ImageLabel")
	setp(NG906, "Active", false)
	setp(NG906, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG906, "BackgroundTransparency", 1)
	setp(NG906, "BorderSizePixel", 0)
	setp(NG906, "Name", "Background")
	NG906.Selectable = false
	setp(NG906, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG906, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG906, "Parent", NG904)
	NG907 = Instance.new("Frame")
	setp(NG907, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG907, "BorderSizePixel", 0)
	setp(NG907, "Name", "SelectedIndicator")
	setp(NG907, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG907, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG907, "Parent", NG904)
	NG908 = Instance.new("TextBox")
	setp(NG908, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG908, "BackgroundTransparency", 1)
	setp(NG908, "BorderSizePixel", 0)
	setp(NG908, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG908, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG908, "Font", Enum.Font.ArialBold)
	setp(NG908, "FontSize", Enum.FontSize.Size10)
	setp(NG908, "Text", "255")
	setp(NG908, "TextColor3", Color3.new(1, 1, 1))
	setp(NG908, "Parent", NG904)
	NG909 = Instance.new("Frame")
	setp(NG909, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG909, "BackgroundTransparency", 1)
	setp(NG909, "BorderSizePixel", 0)
	setp(NG909, "Name", "GInput")
	setp(NG909, "Position", UDim2.new(0, 72, 0, 0))
	setp(NG909, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG909, "Parent", NG902)
	NG910 = Instance.new("TextButton")
	setp(NG910, "Active", true)
	setp(NG910, "AutoButtonColor", false)
	setp(NG910, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG910, "BackgroundTransparency", 1)
	setp(NG910, "BorderSizePixel", 0)
	NG910.Selectable = true
	setp(NG910, "Size", UDim2.new(1, 0, 1, 0))
	NG910.Style = Enum.ButtonStyle.Custom
	setp(NG910, "ZIndex", 2)
	setp(NG910, "Font", Enum.Font.Legacy)
	setp(NG910, "FontSize", Enum.FontSize.Size8)
	setp(NG910, "Text", "")
	setp(NG910, "Parent", NG909)
	NG911 = Instance.new("ImageLabel")
	setp(NG911, "Active", false)
	setp(NG911, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG911, "BackgroundTransparency", 1)
	setp(NG911, "BorderSizePixel", 0)
	setp(NG911, "Name", "Background")
	NG911.Selectable = false
	setp(NG911, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG911, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG911, "Parent", NG909)
	NG912 = Instance.new("Frame")
	setp(NG912, "BackgroundColor3", Color3.new(0, 1, 0))
	setp(NG912, "BorderSizePixel", 0)
	setp(NG912, "Name", "SelectedIndicator")
	setp(NG912, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG912, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG912, "Parent", NG909)
	NG913 = Instance.new("TextBox")
	setp(NG913, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG913, "BackgroundTransparency", 1)
	setp(NG913, "BorderSizePixel", 0)
	setp(NG913, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG913, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG913, "Font", Enum.Font.ArialBold)
	setp(NG913, "FontSize", Enum.FontSize.Size10)
	setp(NG913, "Text", "255")
	setp(NG913, "TextColor3", Color3.new(1, 1, 1))
	setp(NG913, "Parent", NG909)
	NG914 = Instance.new("Frame")
	setp(NG914, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG914, "BackgroundTransparency", 1)
	setp(NG914, "BorderSizePixel", 0)
	setp(NG914, "Name", "BInput")
	setp(NG914, "Position", UDim2.new(0, 109, 0, 0))
	setp(NG914, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG914, "Parent", NG902)
	NG915 = Instance.new("TextButton")
	setp(NG915, "Active", true)
	setp(NG915, "AutoButtonColor", false)
	setp(NG915, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG915, "BackgroundTransparency", 1)
	setp(NG915, "BorderSizePixel", 0)
	NG915.Selectable = true
	setp(NG915, "Size", UDim2.new(1, 0, 1, 0))
	NG915.Style = Enum.ButtonStyle.Custom
	setp(NG915, "ZIndex", 2)
	setp(NG915, "Font", Enum.Font.Legacy)
	setp(NG915, "FontSize", Enum.FontSize.Size8)
	setp(NG915, "Text", "")
	setp(NG915, "Parent", NG914)
	NG916 = Instance.new("ImageLabel")
	setp(NG916, "Active", false)
	setp(NG916, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG916, "BackgroundTransparency", 1)
	setp(NG916, "BorderSizePixel", 0)
	setp(NG916, "Name", "Background")
	NG916.Selectable = false
	setp(NG916, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG916, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG916, "Parent", NG914)
	NG917 = Instance.new("Frame")
	setp(NG917, "BackgroundColor3", Color3.new(0, 0, 1))
	setp(NG917, "BorderSizePixel", 0)
	setp(NG917, "Name", "SelectedIndicator")
	setp(NG917, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG917, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG917, "Parent", NG914)
	NG918 = Instance.new("TextBox")
	setp(NG918, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG918, "BackgroundTransparency", 1)
	setp(NG918, "BorderSizePixel", 0)
	setp(NG918, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG918, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG918, "Font", Enum.Font.ArialBold)
	setp(NG918, "FontSize", Enum.FontSize.Size10)
	setp(NG918, "Text", "255")
	setp(NG918, "TextColor3", Color3.new(1, 1, 1))
	setp(NG918, "Parent", NG914)
	NG919 = Instance.new("ImageButton")
	setp(NG919, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG919, "BackgroundTransparency", 0.40000000596046)
	setp(NG919, "BorderSizePixel", 0)
	setp(NG919, "Name", "HSVPicker")
	setp(NG919, "Position", UDim2.new(0, 160, 0, -2))
	setp(NG919, "Size", UDim2.new(0, 27, 0, 27))
	NG919.Style = Enum.ButtonStyle.Custom
	setp(NG919, "Image", "http://www.roblox.com/asset/?id=141313631")
	setp(NG919, "Parent", NG902)
	NG920 = Instance.new("Frame")
	setp(NG920, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG920, "BackgroundTransparency", 0.75)
	setp(NG920, "BorderSizePixel", 0)
	setp(NG920, "Name", "Shadow")
	setp(NG920, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG920, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG920, "Parent", NG919)
	NG921 = Instance.new("Frame")
	setp(NG921, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG921, "BackgroundTransparency", 0.5)
	setp(NG921, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG921, "BorderSizePixel", 0)
	setp(NG921, "Name", "Separator")
	setp(NG921, "Position", UDim2.new(0, 151, 0, 4))
	setp(NG921, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG921, "Parent", NG902)
	NG922 = Instance.new("Frame")
	setp(NG922, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG922, "BackgroundTransparency", 0.5)
	setp(NG922, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG922, "BorderSizePixel", 0)
	setp(NG922, "Name", "Separator")
	setp(NG922, "Position", UDim2.new(0, 151, 0, 16))
	setp(NG922, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG922, "Parent", NG902)
	NG923 = Instance.new("Frame")
	setp(NG923, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG923, "BackgroundTransparency", 0.5)
	setp(NG923, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG923, "BorderSizePixel", 0)
	setp(NG923, "Name", "Separator")
	setp(NG923, "Position", UDim2.new(0, 151, 0, 10))
	setp(NG923, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG923, "Parent", NG902)
	NG924 = Instance.new("Frame")
	setp(NG924, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG924, "BackgroundTransparency", 1)
	setp(NG924, "BorderSizePixel", 0)
	setp(NG924, "Name", "OpacityOption")
	setp(NG924, "Position", UDim2.new(0, 0, 0, 45))
	setp(NG924, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG924, "Parent", NG901)
	NG925 = Instance.new("TextLabel")
	setp(NG925, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG925, "BackgroundTransparency", 1)
	setp(NG925, "BorderSizePixel", 0)
	setp(NG925, "Name", "Label")
	setp(NG925, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG925, "Font", Enum.Font.ArialBold)
	setp(NG925, "FontSize", Enum.FontSize.Size10)
	setp(NG925, "Text", "Opacity")
	setp(NG925, "TextColor3", Color3.new(1, 1, 1))
	setp(NG925, "TextStrokeTransparency", 0)
	setp(NG925, "TextWrapped", true)
	setp(NG925, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG925, "Parent", NG924)
	NG926 = Instance.new("Frame")
	setp(NG926, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG926, "BackgroundTransparency", 1)
	setp(NG926, "BorderSizePixel", 0)
	setp(NG926, "Name", "Input")
	setp(NG926, "Position", UDim2.new(0, 45, 0, 0))
	setp(NG926, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG926, "Parent", NG924)
	NG927 = Instance.new("TextButton")
	setp(NG927, "Active", true)
	setp(NG927, "AutoButtonColor", false)
	setp(NG927, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG927, "BackgroundTransparency", 1)
	setp(NG927, "BorderSizePixel", 0)
	NG927.Selectable = true
	setp(NG927, "Size", UDim2.new(1, 0, 1, 0))
	NG927.Style = Enum.ButtonStyle.Custom
	setp(NG927, "ZIndex", 2)
	setp(NG927, "Font", Enum.Font.Legacy)
	setp(NG927, "FontSize", Enum.FontSize.Size8)
	setp(NG927, "Text", "")
	setp(NG927, "Parent", NG926)
	NG928 = Instance.new("ImageLabel")
	setp(NG928, "Active", false)
	setp(NG928, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG928, "BackgroundTransparency", 1)
	setp(NG928, "BorderSizePixel", 0)
	setp(NG928, "Name", "Background")
	NG928.Selectable = false
	setp(NG928, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG928, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG928, "Parent", NG926)
	NG929 = Instance.new("Frame")
	setp(NG929, "BorderSizePixel", 0)
	setp(NG929, "Name", "SelectedIndicator")
	setp(NG929, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG929, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG929, "Parent", NG926)
	NG930 = Instance.new("TextBox")
	setp(NG930, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG930, "BackgroundTransparency", 1)
	setp(NG930, "BorderSizePixel", 0)
	setp(NG930, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG930, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG930, "Font", Enum.Font.ArialBold)
	setp(NG930, "FontSize", Enum.FontSize.Size10)
	setp(NG930, "Text", "1")
	setp(NG930, "TextColor3", Color3.new(1, 1, 1))
	setp(NG930, "Parent", NG926)
	NG931 = Instance.new("Frame")
	setp(NG931, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG931, "BackgroundTransparency", 1)
	setp(NG931, "BorderSizePixel", 0)
	setp(NG931, "Name", "VelocityOption")
	setp(NG931, "Position", UDim2.new(0, 100, 0, 45))
	setp(NG931, "Size", UDim2.new(1, -115, 0, 25))
	setp(NG931, "Parent", NG901)
	NG932 = Instance.new("TextLabel")
	setp(NG932, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG932, "BackgroundTransparency", 1)
	setp(NG932, "BorderSizePixel", 0)
	setp(NG932, "Name", "Label")
	setp(NG932, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG932, "Font", Enum.Font.ArialBold)
	setp(NG932, "FontSize", Enum.FontSize.Size10)
	setp(NG932, "Text", "Velocity")
	setp(NG932, "TextColor3", Color3.new(1, 1, 1))
	setp(NG932, "TextStrokeTransparency", 0)
	setp(NG932, "TextWrapped", true)
	setp(NG932, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG932, "Parent", NG931)
	NG933 = Instance.new("Frame")
	setp(NG933, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG933, "BackgroundTransparency", 1)
	setp(NG933, "BorderSizePixel", 0)
	setp(NG933, "Name", "Input")
	setp(NG933, "Position", UDim2.new(0, 45, 0, 0))
	setp(NG933, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG933, "Parent", NG931)
	NG934 = Instance.new("TextButton")
	setp(NG934, "Active", true)
	setp(NG934, "AutoButtonColor", false)
	setp(NG934, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG934, "BackgroundTransparency", 1)
	setp(NG934, "BorderSizePixel", 0)
	NG934.Selectable = true
	setp(NG934, "Size", UDim2.new(1, 0, 1, 0))
	NG934.Style = Enum.ButtonStyle.Custom
	setp(NG934, "ZIndex", 2)
	setp(NG934, "Font", Enum.Font.Legacy)
	setp(NG934, "FontSize", Enum.FontSize.Size8)
	setp(NG934, "Text", "")
	setp(NG934, "Parent", NG933)
	NG935 = Instance.new("ImageLabel")
	setp(NG935, "Active", false)
	setp(NG935, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG935, "BackgroundTransparency", 1)
	setp(NG935, "BorderSizePixel", 0)
	setp(NG935, "Name", "Background")
	NG935.Selectable = false
	setp(NG935, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG935, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG935, "Parent", NG933)
	NG936 = Instance.new("Frame")
	setp(NG936, "BorderSizePixel", 0)
	setp(NG936, "Name", "SelectedIndicator")
	setp(NG936, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG936, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG936, "Parent", NG933)
	NG937 = Instance.new("TextBox")
	setp(NG937, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG937, "BackgroundTransparency", 1)
	setp(NG937, "BorderSizePixel", 0)
	setp(NG937, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG937, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG937, "Font", Enum.Font.ArialBold)
	setp(NG937, "FontSize", Enum.FontSize.Size10)
	setp(NG937, "Text", "90")
	setp(NG937, "TextColor3", Color3.new(1, 1, 1))
	setp(NG937, "Parent", NG933)
	NG938 = Instance.new("Frame")
	setp(NG938, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG938, "BackgroundTransparency", 1)
	setp(NG938, "BorderSizePixel", 0)
	setp(NG938, "Name", "SizeOption")
	setp(NG938, "Position", UDim2.new(0, 0, 0, 80))
	setp(NG938, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG938, "Parent", NG901)
	NG939 = Instance.new("TextLabel")
	setp(NG939, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG939, "BackgroundTransparency", 1)
	setp(NG939, "BorderSizePixel", 0)
	setp(NG939, "Name", "Label")
	setp(NG939, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG939, "Font", Enum.Font.ArialBold)
	setp(NG939, "FontSize", Enum.FontSize.Size10)
	setp(NG939, "Text", "Size")
	setp(NG939, "TextColor3", Color3.new(1, 1, 1))
	setp(NG939, "TextStrokeTransparency", 0)
	setp(NG939, "TextWrapped", true)
	setp(NG939, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG939, "Parent", NG938)
	NG940 = Instance.new("Frame")
	setp(NG940, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG940, "BackgroundTransparency", 1)
	setp(NG940, "BorderSizePixel", 0)
	setp(NG940, "Name", "Input")
	setp(NG940, "Position", UDim2.new(0, 30, 0, 0))
	setp(NG940, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG940, "Parent", NG938)
	NG941 = Instance.new("TextButton")
	setp(NG941, "Active", true)
	setp(NG941, "AutoButtonColor", false)
	setp(NG941, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG941, "BackgroundTransparency", 1)
	setp(NG941, "BorderSizePixel", 0)
	NG941.Selectable = true
	setp(NG941, "Size", UDim2.new(1, 0, 1, 0))
	NG941.Style = Enum.ButtonStyle.Custom
	setp(NG941, "ZIndex", 2)
	setp(NG941, "Font", Enum.Font.Legacy)
	setp(NG941, "FontSize", Enum.FontSize.Size8)
	setp(NG941, "Text", "")
	setp(NG941, "Parent", NG940)
	NG942 = Instance.new("ImageLabel")
	setp(NG942, "Active", false)
	setp(NG942, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG942, "BackgroundTransparency", 1)
	setp(NG942, "BorderSizePixel", 0)
	setp(NG942, "Name", "Background")
	NG942.Selectable = false
	setp(NG942, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG942, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG942, "Parent", NG940)
	NG943 = Instance.new("Frame")
	setp(NG943, "BorderSizePixel", 0)
	setp(NG943, "Name", "SelectedIndicator")
	setp(NG943, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG943, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG943, "Parent", NG940)
	NG944 = Instance.new("TextBox")
	setp(NG944, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG944, "BackgroundTransparency", 1)
	setp(NG944, "BorderSizePixel", 0)
	setp(NG944, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG944, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG944, "Font", Enum.Font.ArialBold)
	setp(NG944, "FontSize", Enum.FontSize.Size10)
	setp(NG944, "Text", "16")
	setp(NG944, "TextColor3", Color3.new(1, 1, 1))
	setp(NG944, "Parent", NG940)
	NG945 = Instance.new("TextLabel")
	setp(NG945, "BackgroundTransparency", 1)
	setp(NG945, "BorderSizePixel", 0)
	setp(NG945, "Name", "SelectNote")
	setp(NG945, "Position", UDim2.new(0, 10, 0, 27))
	setp(NG945, "Size", UDim2.new(1, -10, 0, 15))
	setp(NG945, "Visible", false)
	setp(NG945, "FontSize", Enum.FontSize.Size14)
	setp(NG945, "Text", "Select something to use this tool.")
	setp(NG945, "TextColor3", Color3.new(1, 1, 1))
	setp(NG945, "TextScaled", true)
	setp(NG945, "TextStrokeTransparency", 0.5)
	setp(NG945, "TextWrapped", true)
	setp(NG945, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG945, "Parent", NG888)
	NG946 = Instance.new("Frame")
	setp(NG946, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG946, "BackgroundTransparency", 0.67500001192093)
	setp(NG946, "BorderSizePixel", 0)
	setp(NG946, "Name", "Fire")
	setp(NG946, "Position", UDim2.new(0, 10, 0, 60))
	setp(NG946, "Size", UDim2.new(1, -10, 0, 25))
	setp(NG946, "Parent", NG888)
	NG947 = Instance.new("TextLabel")
	setp(NG947, "BackgroundTransparency", 1)
	setp(NG947, "BorderSizePixel", 0)
	setp(NG947, "Name", "Label")
	setp(NG947, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG947, "Size", UDim2.new(0, 60, 0, 25))
	setp(NG947, "Font", Enum.Font.ArialBold)
	setp(NG947, "FontSize", Enum.FontSize.Size10)
	setp(NG947, "Text", "Fire")
	setp(NG947, "TextColor3", Color3.new(1, 1, 1))
	setp(NG947, "TextStrokeTransparency", 0.5)
	setp(NG947, "TextWrapped", true)
	setp(NG947, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG947, "Parent", NG946)
	NG948 = Instance.new("ImageButton")
	setp(NG948, "BackgroundTransparency", 1)
	setp(NG948, "BorderSizePixel", 0)
	setp(NG948, "Name", "ArrowButton")
	setp(NG948, "Position", UDim2.new(0, 10, 0, 3))
	setp(NG948, "Size", UDim2.new(0, 20, 0, 20))
	NG948.Style = Enum.ButtonStyle.Custom
	setp(NG948, "Image", "http://www.roblox.com/asset/?id=134367382")
	setp(NG948, "Parent", NG946)
	NG949 = Instance.new("Frame")
	setp(NG949, "BackgroundColor3", Color3.new(0.85098, 0, 1))
	setp(NG949, "BorderSizePixel", 0)
	setp(NG949, "Name", "ColorBar")
	setp(NG949, "Size", UDim2.new(0, 3, 1, 0))
	setp(NG949, "Parent", NG946)
	NG950 = Instance.new("TextButton")
	setp(NG950, "Active", true)
	setp(NG950, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG950, "BackgroundTransparency", 0.75)
	setp(NG950, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG950, "BorderSizePixel", 0)
	setp(NG950, "Name", "AddButton")
	setp(NG950, "Position", UDim2.new(1, -40, 0, 3))
	NG950.Selectable = true
	setp(NG950, "Size", UDim2.new(0, 35, 0, 19))
	NG950.Style = Enum.ButtonStyle.Custom
	setp(NG950, "Font", Enum.Font.ArialBold)
	setp(NG950, "FontSize", Enum.FontSize.Size10)
	setp(NG950, "Text", "ADD")
	setp(NG950, "TextColor3", Color3.new(1, 1, 1))
	setp(NG950, "Parent", NG946)
	NG951 = Instance.new("TextButton")
	setp(NG951, "Active", true)
	setp(NG951, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG951, "BackgroundTransparency", 0.75)
	setp(NG951, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG951, "BorderSizePixel", 0)
	setp(NG951, "Name", "RemoveButton")
	setp(NG951, "Position", UDim2.new(0, 90, 0, 3))
	NG951.Selectable = true
	setp(NG951, "Size", UDim2.new(0, 58, 0, 19))
	NG951.Style = Enum.ButtonStyle.Custom
	setp(NG951, "Visible", false)
	setp(NG951, "Font", Enum.Font.ArialBold)
	setp(NG951, "FontSize", Enum.FontSize.Size10)
	setp(NG951, "Text", "REMOVE")
	setp(NG951, "TextColor3", Color3.new(1, 1, 1))
	setp(NG951, "Parent", NG946)
	NG952 = Instance.new("Frame")
	setp(NG952, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG952, "BackgroundTransparency", 0.75)
	setp(NG952, "BorderSizePixel", 0)
	setp(NG952, "Name", "Shadow")
	setp(NG952, "Position", UDim2.new(0, 0, 1, -1))
	setp(NG952, "Size", UDim2.new(1, 0, 0, 1))
	setp(NG952, "Parent", NG946)
	NG953 = Instance.new("Frame")
	setp(NG953, "BackgroundTransparency", 1)
	setp(NG953, "BorderSizePixel", 0)
	setp(NG953, "Name", "Options")
	setp(NG953, "Position", UDim2.new(0, 3, 1, 0))
	setp(NG953, "Size", UDim2.new(1, -3, 0, 0))
	setp(NG953, "ClipsDescendants", true)
	setp(NG953, "Parent", NG946)
	NG954 = Instance.new("Frame")
	setp(NG954, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG954, "BackgroundTransparency", 1)
	setp(NG954, "BorderSizePixel", 0)
	setp(NG954, "Name", "ColorOption")
	setp(NG954, "Position", UDim2.new(0, 0, 0, 10))
	setp(NG954, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG954, "Parent", NG953)
	NG955 = Instance.new("TextLabel")
	setp(NG955, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG955, "BackgroundTransparency", 1)
	setp(NG955, "BorderSizePixel", 0)
	setp(NG955, "Name", "Label")
	setp(NG955, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG955, "Font", Enum.Font.ArialBold)
	setp(NG955, "FontSize", Enum.FontSize.Size10)
	setp(NG955, "Text", "Color")
	setp(NG955, "TextColor3", Color3.new(1, 1, 1))
	setp(NG955, "TextStrokeTransparency", 0)
	setp(NG955, "TextWrapped", true)
	setp(NG955, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG955, "Parent", NG954)
	NG956 = Instance.new("Frame")
	setp(NG956, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG956, "BackgroundTransparency", 1)
	setp(NG956, "BorderSizePixel", 0)
	setp(NG956, "Name", "RInput")
	setp(NG956, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG956, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG956, "Parent", NG954)
	NG957 = Instance.new("TextButton")
	setp(NG957, "Active", true)
	setp(NG957, "AutoButtonColor", false)
	setp(NG957, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG957, "BackgroundTransparency", 1)
	setp(NG957, "BorderSizePixel", 0)
	NG957.Selectable = true
	setp(NG957, "Size", UDim2.new(1, 0, 1, 0))
	NG957.Style = Enum.ButtonStyle.Custom
	setp(NG957, "ZIndex", 2)
	setp(NG957, "Font", Enum.Font.Legacy)
	setp(NG957, "FontSize", Enum.FontSize.Size8)
	setp(NG957, "Text", "")
	setp(NG957, "Parent", NG956)
	NG958 = Instance.new("ImageLabel")
	setp(NG958, "Active", false)
	setp(NG958, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG958, "BackgroundTransparency", 1)
	setp(NG958, "BorderSizePixel", 0)
	setp(NG958, "Name", "Background")
	NG958.Selectable = false
	setp(NG958, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG958, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG958, "Parent", NG956)
	NG959 = Instance.new("Frame")
	setp(NG959, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG959, "BorderSizePixel", 0)
	setp(NG959, "Name", "SelectedIndicator")
	setp(NG959, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG959, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG959, "Parent", NG956)
	NG960 = Instance.new("TextBox")
	setp(NG960, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG960, "BackgroundTransparency", 1)
	setp(NG960, "BorderSizePixel", 0)
	setp(NG960, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG960, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG960, "Font", Enum.Font.ArialBold)
	setp(NG960, "FontSize", Enum.FontSize.Size10)
	setp(NG960, "Text", "255")
	setp(NG960, "TextColor3", Color3.new(1, 1, 1))
	setp(NG960, "Parent", NG956)
	NG961 = Instance.new("Frame")
	setp(NG961, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG961, "BackgroundTransparency", 1)
	setp(NG961, "BorderSizePixel", 0)
	setp(NG961, "Name", "GInput")
	setp(NG961, "Position", UDim2.new(0, 72, 0, 0))
	setp(NG961, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG961, "Parent", NG954)
	NG962 = Instance.new("TextButton")
	setp(NG962, "Active", true)
	setp(NG962, "AutoButtonColor", false)
	setp(NG962, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG962, "BackgroundTransparency", 1)
	setp(NG962, "BorderSizePixel", 0)
	NG962.Selectable = true
	setp(NG962, "Size", UDim2.new(1, 0, 1, 0))
	NG962.Style = Enum.ButtonStyle.Custom
	setp(NG962, "ZIndex", 2)
	setp(NG962, "Font", Enum.Font.Legacy)
	setp(NG962, "FontSize", Enum.FontSize.Size8)
	setp(NG962, "Text", "")
	setp(NG962, "Parent", NG961)
	NG963 = Instance.new("ImageLabel")
	setp(NG963, "Active", false)
	setp(NG963, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG963, "BackgroundTransparency", 1)
	setp(NG963, "BorderSizePixel", 0)
	setp(NG963, "Name", "Background")
	NG963.Selectable = false
	setp(NG963, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG963, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG963, "Parent", NG961)
	NG964 = Instance.new("Frame")
	setp(NG964, "BackgroundColor3", Color3.new(0, 1, 0))
	setp(NG964, "BorderSizePixel", 0)
	setp(NG964, "Name", "SelectedIndicator")
	setp(NG964, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG964, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG964, "Parent", NG961)
	NG965 = Instance.new("TextBox")
	setp(NG965, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG965, "BackgroundTransparency", 1)
	setp(NG965, "BorderSizePixel", 0)
	setp(NG965, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG965, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG965, "Font", Enum.Font.ArialBold)
	setp(NG965, "FontSize", Enum.FontSize.Size10)
	setp(NG965, "Text", "255")
	setp(NG965, "TextColor3", Color3.new(1, 1, 1))
	setp(NG965, "Parent", NG961)
	NG966 = Instance.new("Frame")
	setp(NG966, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG966, "BackgroundTransparency", 1)
	setp(NG966, "BorderSizePixel", 0)
	setp(NG966, "Name", "BInput")
	setp(NG966, "Position", UDim2.new(0, 109, 0, 0))
	setp(NG966, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG966, "Parent", NG954)
	NG967 = Instance.new("TextButton")
	setp(NG967, "Active", true)
	setp(NG967, "AutoButtonColor", false)
	setp(NG967, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG967, "BackgroundTransparency", 1)
	setp(NG967, "BorderSizePixel", 0)
	NG967.Selectable = true
	setp(NG967, "Size", UDim2.new(1, 0, 1, 0))
	NG967.Style = Enum.ButtonStyle.Custom
	setp(NG967, "ZIndex", 2)
	setp(NG967, "Font", Enum.Font.Legacy)
	setp(NG967, "FontSize", Enum.FontSize.Size8)
	setp(NG967, "Text", "")
	setp(NG967, "Parent", NG966)
	NG968 = Instance.new("ImageLabel")
	setp(NG968, "Active", false)
	setp(NG968, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG968, "BackgroundTransparency", 1)
	setp(NG968, "BorderSizePixel", 0)
	setp(NG968, "Name", "Background")
	NG968.Selectable = false
	setp(NG968, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG968, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG968, "Parent", NG966)
	NG969 = Instance.new("Frame")
	setp(NG969, "BackgroundColor3", Color3.new(0, 0, 1))
	setp(NG969, "BorderSizePixel", 0)
	setp(NG969, "Name", "SelectedIndicator")
	setp(NG969, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG969, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG969, "Parent", NG966)
	NG970 = Instance.new("TextBox")
	setp(NG970, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG970, "BackgroundTransparency", 1)
	setp(NG970, "BorderSizePixel", 0)
	setp(NG970, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG970, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG970, "Font", Enum.Font.ArialBold)
	setp(NG970, "FontSize", Enum.FontSize.Size10)
	setp(NG970, "Text", "255")
	setp(NG970, "TextColor3", Color3.new(1, 1, 1))
	setp(NG970, "Parent", NG966)
	NG971 = Instance.new("ImageButton")
	setp(NG971, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG971, "BackgroundTransparency", 0.40000000596046)
	setp(NG971, "BorderSizePixel", 0)
	setp(NG971, "Name", "HSVPicker")
	setp(NG971, "Position", UDim2.new(0, 160, 0, -2))
	setp(NG971, "Size", UDim2.new(0, 27, 0, 27))
	NG971.Style = Enum.ButtonStyle.Custom
	setp(NG971, "ZIndex", 2)
	setp(NG971, "Image", "http://www.roblox.com/asset/?id=141313631")
	setp(NG971, "Parent", NG954)
	NG972 = Instance.new("Frame")
	setp(NG972, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG972, "BackgroundTransparency", 0.75)
	setp(NG972, "BorderSizePixel", 0)
	setp(NG972, "Name", "Shadow")
	setp(NG972, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG972, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG972, "Parent", NG971)
	NG973 = Instance.new("Frame")
	setp(NG973, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG973, "BackgroundTransparency", 0.5)
	setp(NG973, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG973, "BorderSizePixel", 0)
	setp(NG973, "Name", "Separator")
	setp(NG973, "Position", UDim2.new(0, 151, 0, 4))
	setp(NG973, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG973, "Parent", NG954)
	NG974 = Instance.new("Frame")
	setp(NG974, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG974, "BackgroundTransparency", 0.5)
	setp(NG974, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG974, "BorderSizePixel", 0)
	setp(NG974, "Name", "Separator")
	setp(NG974, "Position", UDim2.new(0, 151, 0, 16))
	setp(NG974, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG974, "Parent", NG954)
	NG975 = Instance.new("Frame")
	setp(NG975, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG975, "BackgroundTransparency", 0.5)
	setp(NG975, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG975, "BorderSizePixel", 0)
	setp(NG975, "Name", "Separator")
	setp(NG975, "Position", UDim2.new(0, 151, 0, 10))
	setp(NG975, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG975, "Parent", NG954)
	NG976 = Instance.new("Frame")
	setp(NG976, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG976, "BackgroundTransparency", 1)
	setp(NG976, "BorderSizePixel", 0)
	setp(NG976, "Name", "HeatOption")
	setp(NG976, "Position", UDim2.new(0, 0, 0, 80))
	setp(NG976, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG976, "Parent", NG953)
	NG977 = Instance.new("TextLabel")
	setp(NG977, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG977, "BackgroundTransparency", 1)
	setp(NG977, "BorderSizePixel", 0)
	setp(NG977, "Name", "Label")
	setp(NG977, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG977, "Font", Enum.Font.ArialBold)
	setp(NG977, "FontSize", Enum.FontSize.Size10)
	setp(NG977, "Text", "Heat")
	setp(NG977, "TextColor3", Color3.new(1, 1, 1))
	setp(NG977, "TextStrokeTransparency", 0)
	setp(NG977, "TextWrapped", true)
	setp(NG977, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG977, "Parent", NG976)
	NG978 = Instance.new("Frame")
	setp(NG978, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG978, "BackgroundTransparency", 1)
	setp(NG978, "BorderSizePixel", 0)
	setp(NG978, "Name", "Input")
	setp(NG978, "Position", UDim2.new(0, 34, 0, 0))
	setp(NG978, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG978, "Parent", NG976)
	NG979 = Instance.new("TextButton")
	setp(NG979, "Active", true)
	setp(NG979, "AutoButtonColor", false)
	setp(NG979, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG979, "BackgroundTransparency", 1)
	setp(NG979, "BorderSizePixel", 0)
	NG979.Selectable = true
	setp(NG979, "Size", UDim2.new(1, 0, 1, 0))
	NG979.Style = Enum.ButtonStyle.Custom
	setp(NG979, "ZIndex", 2)
	setp(NG979, "Font", Enum.Font.Legacy)
	setp(NG979, "FontSize", Enum.FontSize.Size8)
	setp(NG979, "Text", "")
	setp(NG979, "Parent", NG978)
	NG980 = Instance.new("ImageLabel")
	setp(NG980, "Active", false)
	setp(NG980, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG980, "BackgroundTransparency", 1)
	setp(NG980, "BorderSizePixel", 0)
	setp(NG980, "Name", "Background")
	NG980.Selectable = false
	setp(NG980, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG980, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG980, "Parent", NG978)
	NG981 = Instance.new("Frame")
	setp(NG981, "BorderSizePixel", 0)
	setp(NG981, "Name", "SelectedIndicator")
	setp(NG981, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG981, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG981, "Parent", NG978)
	NG982 = Instance.new("TextBox")
	setp(NG982, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG982, "BackgroundTransparency", 1)
	setp(NG982, "BorderSizePixel", 0)
	setp(NG982, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG982, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG982, "Font", Enum.Font.ArialBold)
	setp(NG982, "FontSize", Enum.FontSize.Size10)
	setp(NG982, "Text", "1")
	setp(NG982, "TextColor3", Color3.new(1, 1, 1))
	setp(NG982, "Parent", NG978)
	NG983 = Instance.new("Frame")
	setp(NG983, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG983, "BackgroundTransparency", 1)
	setp(NG983, "BorderSizePixel", 0)
	setp(NG983, "Name", "SizeOption")
	setp(NG983, "Position", UDim2.new(0, 90, 0, 80))
	setp(NG983, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG983, "Parent", NG953)
	NG984 = Instance.new("TextLabel")
	setp(NG984, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG984, "BackgroundTransparency", 1)
	setp(NG984, "BorderSizePixel", 0)
	setp(NG984, "Name", "Label")
	setp(NG984, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG984, "Font", Enum.Font.ArialBold)
	setp(NG984, "FontSize", Enum.FontSize.Size10)
	setp(NG984, "Text", "Size")
	setp(NG984, "TextColor3", Color3.new(1, 1, 1))
	setp(NG984, "TextStrokeTransparency", 0)
	setp(NG984, "TextWrapped", true)
	setp(NG984, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG984, "Parent", NG983)
	NG985 = Instance.new("Frame")
	setp(NG985, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG985, "BackgroundTransparency", 1)
	setp(NG985, "BorderSizePixel", 0)
	setp(NG985, "Name", "Input")
	setp(NG985, "Position", UDim2.new(0, 30, 0, 0))
	setp(NG985, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG985, "Parent", NG983)
	NG986 = Instance.new("TextButton")
	setp(NG986, "Active", true)
	setp(NG986, "AutoButtonColor", false)
	setp(NG986, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG986, "BackgroundTransparency", 1)
	setp(NG986, "BorderSizePixel", 0)
	NG986.Selectable = true
	setp(NG986, "Size", UDim2.new(1, 0, 1, 0))
	NG986.Style = Enum.ButtonStyle.Custom
	setp(NG986, "ZIndex", 2)
	setp(NG986, "Font", Enum.Font.Legacy)
	setp(NG986, "FontSize", Enum.FontSize.Size8)
	setp(NG986, "Text", "")
	setp(NG986, "Parent", NG985)
	NG987 = Instance.new("ImageLabel")
	setp(NG987, "Active", false)
	setp(NG987, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG987, "BackgroundTransparency", 1)
	setp(NG987, "BorderSizePixel", 0)
	setp(NG987, "Name", "Background")
	NG987.Selectable = false
	setp(NG987, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG987, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG987, "Parent", NG985)
	NG988 = Instance.new("Frame")
	setp(NG988, "BorderSizePixel", 0)
	setp(NG988, "Name", "SelectedIndicator")
	setp(NG988, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG988, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG988, "Parent", NG985)
	NG989 = Instance.new("TextBox")
	setp(NG989, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG989, "BackgroundTransparency", 1)
	setp(NG989, "BorderSizePixel", 0)
	setp(NG989, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG989, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG989, "Font", Enum.Font.ArialBold)
	setp(NG989, "FontSize", Enum.FontSize.Size10)
	setp(NG989, "Text", "16")
	setp(NG989, "TextColor3", Color3.new(1, 1, 1))
	setp(NG989, "Parent", NG985)
	NG990 = Instance.new("Frame")
	setp(NG990, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG990, "BackgroundTransparency", 1)
	setp(NG990, "BorderSizePixel", 0)
	setp(NG990, "Name", "SecondColorOption")
	setp(NG990, "Position", UDim2.new(0, 0, 0, 45))
	setp(NG990, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG990, "Parent", NG953)
	NG991 = Instance.new("TextLabel")
	setp(NG991, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG991, "BackgroundTransparency", 1)
	setp(NG991, "BorderSizePixel", 0)
	setp(NG991, "Name", "Label")
	setp(NG991, "Size", UDim2.new(0, 40, 0, 25))
	setp(NG991, "Font", Enum.Font.ArialBold)
	setp(NG991, "FontSize", Enum.FontSize.Size10)
	setp(NG991, "Text", "2nd Color")
	setp(NG991, "TextColor3", Color3.new(1, 1, 1))
	setp(NG991, "TextStrokeTransparency", 0)
	setp(NG991, "TextWrapped", true)
	setp(NG991, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG991, "Parent", NG990)
	NG992 = Instance.new("Frame")
	setp(NG992, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG992, "BackgroundTransparency", 1)
	setp(NG992, "BorderSizePixel", 0)
	setp(NG992, "Name", "RInput")
	setp(NG992, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG992, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG992, "Parent", NG990)
	NG993 = Instance.new("TextButton")
	setp(NG993, "Active", true)
	setp(NG993, "AutoButtonColor", false)
	setp(NG993, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG993, "BackgroundTransparency", 1)
	setp(NG993, "BorderSizePixel", 0)
	NG993.Selectable = true
	setp(NG993, "Size", UDim2.new(1, 0, 1, 0))
	NG993.Style = Enum.ButtonStyle.Custom
	setp(NG993, "ZIndex", 2)
	setp(NG993, "Font", Enum.Font.Legacy)
	setp(NG993, "FontSize", Enum.FontSize.Size8)
	setp(NG993, "Text", "")
	setp(NG993, "Parent", NG992)
	NG994 = Instance.new("ImageLabel")
	setp(NG994, "Active", false)
	setp(NG994, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG994, "BackgroundTransparency", 1)
	setp(NG994, "BorderSizePixel", 0)
	setp(NG994, "Name", "Background")
	NG994.Selectable = false
	setp(NG994, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG994, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG994, "Parent", NG992)
	NG995 = Instance.new("Frame")
	setp(NG995, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG995, "BorderSizePixel", 0)
	setp(NG995, "Name", "SelectedIndicator")
	setp(NG995, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG995, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG995, "Parent", NG992)
	NG996 = Instance.new("TextBox")
	setp(NG996, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG996, "BackgroundTransparency", 1)
	setp(NG996, "BorderSizePixel", 0)
	setp(NG996, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG996, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG996, "Font", Enum.Font.ArialBold)
	setp(NG996, "FontSize", Enum.FontSize.Size10)
	setp(NG996, "Text", "255")
	setp(NG996, "TextColor3", Color3.new(1, 1, 1))
	setp(NG996, "Parent", NG992)
	NG997 = Instance.new("Frame")
	setp(NG997, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG997, "BackgroundTransparency", 1)
	setp(NG997, "BorderSizePixel", 0)
	setp(NG997, "Name", "GInput")
	setp(NG997, "Position", UDim2.new(0, 72, 0, 0))
	setp(NG997, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG997, "Parent", NG990)
	NG998 = Instance.new("TextButton")
	setp(NG998, "Active", true)
	setp(NG998, "AutoButtonColor", false)
	setp(NG998, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG998, "BackgroundTransparency", 1)
	setp(NG998, "BorderSizePixel", 0)
	NG998.Selectable = true
	setp(NG998, "Size", UDim2.new(1, 0, 1, 0))
	NG998.Style = Enum.ButtonStyle.Custom
	setp(NG998, "ZIndex", 2)
	setp(NG998, "Font", Enum.Font.Legacy)
	setp(NG998, "FontSize", Enum.FontSize.Size8)
	setp(NG998, "Text", "")
	setp(NG998, "Parent", NG997)
	NG999 = Instance.new("ImageLabel")
	setp(NG999, "Active", false)
	setp(NG999, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG999, "BackgroundTransparency", 1)
	setp(NG999, "BorderSizePixel", 0)
	setp(NG999, "Name", "Background")
	NG999.Selectable = false
	setp(NG999, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG999, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG999, "Parent", NG997)
	NG1000 = Instance.new("Frame")
	setp(NG1000, "BackgroundColor3", Color3.new(0, 1, 0))
	setp(NG1000, "BorderSizePixel", 0)
	setp(NG1000, "Name", "SelectedIndicator")
	setp(NG1000, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1000, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1000, "Parent", NG997)
	NG1001 = Instance.new("TextBox")
	setp(NG1001, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1001, "BackgroundTransparency", 1)
	setp(NG1001, "BorderSizePixel", 0)
	setp(NG1001, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1001, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1001, "Font", Enum.Font.ArialBold)
	setp(NG1001, "FontSize", Enum.FontSize.Size10)
	setp(NG1001, "Text", "255")
	setp(NG1001, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1001, "Parent", NG997)
	NG1002 = Instance.new("Frame")
	setp(NG1002, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1002, "BackgroundTransparency", 1)
	setp(NG1002, "BorderSizePixel", 0)
	setp(NG1002, "Name", "BInput")
	setp(NG1002, "Position", UDim2.new(0, 109, 0, 0))
	setp(NG1002, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1002, "Parent", NG990)
	NG1003 = Instance.new("TextButton")
	setp(NG1003, "Active", true)
	setp(NG1003, "AutoButtonColor", false)
	setp(NG1003, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1003, "BackgroundTransparency", 1)
	setp(NG1003, "BorderSizePixel", 0)
	NG1003.Selectable = true
	setp(NG1003, "Size", UDim2.new(1, 0, 1, 0))
	NG1003.Style = Enum.ButtonStyle.Custom
	setp(NG1003, "ZIndex", 2)
	setp(NG1003, "Font", Enum.Font.Legacy)
	setp(NG1003, "FontSize", Enum.FontSize.Size8)
	setp(NG1003, "Text", "")
	setp(NG1003, "Parent", NG1002)
	NG1004 = Instance.new("ImageLabel")
	setp(NG1004, "Active", false)
	setp(NG1004, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1004, "BackgroundTransparency", 1)
	setp(NG1004, "BorderSizePixel", 0)
	setp(NG1004, "Name", "Background")
	NG1004.Selectable = false
	setp(NG1004, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1004, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1004, "Parent", NG1002)
	NG1005 = Instance.new("Frame")
	setp(NG1005, "BackgroundColor3", Color3.new(0, 0, 1))
	setp(NG1005, "BorderSizePixel", 0)
	setp(NG1005, "Name", "SelectedIndicator")
	setp(NG1005, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1005, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1005, "Parent", NG1002)
	NG1006 = Instance.new("TextBox")
	setp(NG1006, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1006, "BackgroundTransparency", 1)
	setp(NG1006, "BorderSizePixel", 0)
	setp(NG1006, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1006, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1006, "Font", Enum.Font.ArialBold)
	setp(NG1006, "FontSize", Enum.FontSize.Size10)
	setp(NG1006, "Text", "255")
	setp(NG1006, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1006, "Parent", NG1002)
	NG1007 = Instance.new("ImageButton")
	setp(NG1007, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1007, "BackgroundTransparency", 0.40000000596046)
	setp(NG1007, "BorderSizePixel", 0)
	setp(NG1007, "Name", "HSVPicker")
	setp(NG1007, "Position", UDim2.new(0, 160, 0, -2))
	setp(NG1007, "Size", UDim2.new(0, 27, 0, 27))
	NG1007.Style = Enum.ButtonStyle.Custom
	setp(NG1007, "ZIndex", 2)
	setp(NG1007, "Image", "http://www.roblox.com/asset/?id=141313631")
	setp(NG1007, "Parent", NG990)
	NG1008 = Instance.new("Frame")
	setp(NG1008, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1008, "BackgroundTransparency", 0.75)
	setp(NG1008, "BorderSizePixel", 0)
	setp(NG1008, "Name", "Shadow")
	setp(NG1008, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG1008, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG1008, "Parent", NG1007)
	NG1009 = Instance.new("Frame")
	setp(NG1009, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1009, "BackgroundTransparency", 0.5)
	setp(NG1009, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1009, "BorderSizePixel", 0)
	setp(NG1009, "Name", "Separator")
	setp(NG1009, "Position", UDim2.new(0, 151, 0, 4))
	setp(NG1009, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1009, "Parent", NG990)
	NG1010 = Instance.new("Frame")
	setp(NG1010, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1010, "BackgroundTransparency", 0.5)
	setp(NG1010, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1010, "BorderSizePixel", 0)
	setp(NG1010, "Name", "Separator")
	setp(NG1010, "Position", UDim2.new(0, 151, 0, 16))
	setp(NG1010, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1010, "Parent", NG990)
	NG1011 = Instance.new("Frame")
	setp(NG1011, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1011, "BackgroundTransparency", 0.5)
	setp(NG1011, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1011, "BorderSizePixel", 0)
	setp(NG1011, "Name", "Separator")
	setp(NG1011, "Position", UDim2.new(0, 151, 0, 10))
	setp(NG1011, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1011, "Parent", NG990)
	NG1012 = Instance.new("Frame")
	setp(NG1012, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1012, "BackgroundTransparency", 0.67500001192093)
	setp(NG1012, "BorderSizePixel", 0)
	setp(NG1012, "Name", "Sparkles")
	setp(NG1012, "Position", UDim2.new(0, 10, 0, 90))
	setp(NG1012, "Size", UDim2.new(1, -10, 0, 25))
	setp(NG1012, "Parent", NG888)
	NG1013 = Instance.new("TextLabel")
	setp(NG1013, "BackgroundTransparency", 1)
	setp(NG1013, "BorderSizePixel", 0)
	setp(NG1013, "Name", "Label")
	setp(NG1013, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG1013, "Size", UDim2.new(0, 60, 0, 25))
	setp(NG1013, "Font", Enum.Font.ArialBold)
	setp(NG1013, "FontSize", Enum.FontSize.Size10)
	setp(NG1013, "Text", "Sparkles")
	setp(NG1013, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1013, "TextStrokeTransparency", 0.5)
	setp(NG1013, "TextWrapped", true)
	setp(NG1013, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1013, "Parent", NG1012)
	NG1014 = Instance.new("ImageButton")
	setp(NG1014, "BackgroundTransparency", 1)
	setp(NG1014, "BorderSizePixel", 0)
	setp(NG1014, "Name", "ArrowButton")
	setp(NG1014, "Position", UDim2.new(0, 10, 0, 3))
	setp(NG1014, "Size", UDim2.new(0, 20, 0, 20))
	NG1014.Style = Enum.ButtonStyle.Custom
	setp(NG1014, "Image", "http://www.roblox.com/asset/?id=134367382")
	setp(NG1014, "Parent", NG1012)
	NG1015 = Instance.new("Frame")
	setp(NG1015, "BackgroundColor3", Color3.new(0.0196078, 0.396078, 1))
	setp(NG1015, "BorderSizePixel", 0)
	setp(NG1015, "Name", "ColorBar")
	setp(NG1015, "Size", UDim2.new(0, 3, 1, 0))
	setp(NG1015, "Parent", NG1012)
	NG1016 = Instance.new("TextButton")
	setp(NG1016, "Active", true)
	setp(NG1016, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1016, "BackgroundTransparency", 0.75)
	setp(NG1016, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG1016, "BorderSizePixel", 0)
	setp(NG1016, "Name", "AddButton")
	setp(NG1016, "Position", UDim2.new(1, -40, 0, 3))
	NG1016.Selectable = true
	setp(NG1016, "Size", UDim2.new(0, 35, 0, 19))
	NG1016.Style = Enum.ButtonStyle.Custom
	setp(NG1016, "ZIndex", 2)
	setp(NG1016, "Font", Enum.Font.ArialBold)
	setp(NG1016, "FontSize", Enum.FontSize.Size10)
	setp(NG1016, "Text", "ADD")
	setp(NG1016, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1016, "Parent", NG1012)
	NG1017 = Instance.new("TextButton")
	setp(NG1017, "Active", true)
	setp(NG1017, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1017, "BackgroundTransparency", 0.75)
	setp(NG1017, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG1017, "BorderSizePixel", 0)
	setp(NG1017, "Name", "RemoveButton")
	setp(NG1017, "Position", UDim2.new(0, 90, 0, 3))
	NG1017.Selectable = true
	setp(NG1017, "Size", UDim2.new(0, 58, 0, 19))
	NG1017.Style = Enum.ButtonStyle.Custom
	setp(NG1017, "Visible", false)
	setp(NG1017, "ZIndex", 2)
	setp(NG1017, "Font", Enum.Font.ArialBold)
	setp(NG1017, "FontSize", Enum.FontSize.Size10)
	setp(NG1017, "Text", "REMOVE")
	setp(NG1017, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1017, "Parent", NG1012)
	NG1018 = Instance.new("Frame")
	setp(NG1018, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1018, "BackgroundTransparency", 0.75)
	setp(NG1018, "BorderSizePixel", 0)
	setp(NG1018, "Name", "Shadow")
	setp(NG1018, "Position", UDim2.new(0, 0, 1, -1))
	setp(NG1018, "Size", UDim2.new(1, 0, 0, 1))
	setp(NG1018, "Parent", NG1012)
	NG1019 = Instance.new("Frame")
	setp(NG1019, "BackgroundTransparency", 1)
	setp(NG1019, "BorderSizePixel", 0)
	setp(NG1019, "Name", "Options")
	setp(NG1019, "Position", UDim2.new(0, 3, 1, 0))
	setp(NG1019, "Size", UDim2.new(1, -3, 0, 0))
	setp(NG1019, "ClipsDescendants", true)
	setp(NG1019, "Parent", NG1012)
	NG1020 = Instance.new("Frame")
	setp(NG1020, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1020, "BackgroundTransparency", 1)
	setp(NG1020, "BorderSizePixel", 0)
	setp(NG1020, "Name", "ColorOption")
	setp(NG1020, "Position", UDim2.new(0, 0, 0, 10))
	setp(NG1020, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG1020, "Parent", NG1019)
	NG1021 = Instance.new("TextLabel")
	setp(NG1021, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1021, "BackgroundTransparency", 1)
	setp(NG1021, "BorderSizePixel", 0)
	setp(NG1021, "Name", "Label")
	setp(NG1021, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG1021, "Font", Enum.Font.ArialBold)
	setp(NG1021, "FontSize", Enum.FontSize.Size10)
	setp(NG1021, "Text", "Color")
	setp(NG1021, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1021, "TextStrokeTransparency", 0)
	setp(NG1021, "TextWrapped", true)
	setp(NG1021, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1021, "Parent", NG1020)
	NG1022 = Instance.new("Frame")
	setp(NG1022, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1022, "BackgroundTransparency", 1)
	setp(NG1022, "BorderSizePixel", 0)
	setp(NG1022, "Name", "RInput")
	setp(NG1022, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG1022, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1022, "Parent", NG1020)
	NG1023 = Instance.new("TextButton")
	setp(NG1023, "Active", true)
	setp(NG1023, "AutoButtonColor", false)
	setp(NG1023, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1023, "BackgroundTransparency", 1)
	setp(NG1023, "BorderSizePixel", 0)
	NG1023.Selectable = true
	setp(NG1023, "Size", UDim2.new(1, 0, 1, 0))
	NG1023.Style = Enum.ButtonStyle.Custom
	setp(NG1023, "ZIndex", 2)
	setp(NG1023, "Font", Enum.Font.Legacy)
	setp(NG1023, "FontSize", Enum.FontSize.Size8)
	setp(NG1023, "Text", "")
	setp(NG1023, "Parent", NG1022)
	NG1024 = Instance.new("ImageLabel")
	setp(NG1024, "Active", false)
	setp(NG1024, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1024, "BackgroundTransparency", 1)
	setp(NG1024, "BorderSizePixel", 0)
	setp(NG1024, "Name", "Background")
	NG1024.Selectable = false
	setp(NG1024, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1024, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1024, "Parent", NG1022)
	NG1025 = Instance.new("Frame")
	setp(NG1025, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG1025, "BorderSizePixel", 0)
	setp(NG1025, "Name", "SelectedIndicator")
	setp(NG1025, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1025, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1025, "Parent", NG1022)
	NG1026 = Instance.new("TextBox")
	setp(NG1026, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1026, "BackgroundTransparency", 1)
	setp(NG1026, "BorderSizePixel", 0)
	setp(NG1026, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1026, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1026, "Font", Enum.Font.ArialBold)
	setp(NG1026, "FontSize", Enum.FontSize.Size10)
	setp(NG1026, "Text", "255")
	setp(NG1026, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1026, "Parent", NG1022)
	NG1027 = Instance.new("Frame")
	setp(NG1027, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1027, "BackgroundTransparency", 1)
	setp(NG1027, "BorderSizePixel", 0)
	setp(NG1027, "Name", "GInput")
	setp(NG1027, "Position", UDim2.new(0, 72, 0, 0))
	setp(NG1027, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1027, "Parent", NG1020)
	NG1028 = Instance.new("TextButton")
	setp(NG1028, "Active", true)
	setp(NG1028, "AutoButtonColor", false)
	setp(NG1028, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1028, "BackgroundTransparency", 1)
	setp(NG1028, "BorderSizePixel", 0)
	NG1028.Selectable = true
	setp(NG1028, "Size", UDim2.new(1, 0, 1, 0))
	NG1028.Style = Enum.ButtonStyle.Custom
	setp(NG1028, "ZIndex", 2)
	setp(NG1028, "Font", Enum.Font.Legacy)
	setp(NG1028, "FontSize", Enum.FontSize.Size8)
	setp(NG1028, "Text", "")
	setp(NG1028, "Parent", NG1027)
	NG1029 = Instance.new("ImageLabel")
	setp(NG1029, "Active", false)
	setp(NG1029, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1029, "BackgroundTransparency", 1)
	setp(NG1029, "BorderSizePixel", 0)
	setp(NG1029, "Name", "Background")
	NG1029.Selectable = false
	setp(NG1029, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1029, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1029, "Parent", NG1027)
	NG1030 = Instance.new("Frame")
	setp(NG1030, "BackgroundColor3", Color3.new(0, 1, 0))
	setp(NG1030, "BorderSizePixel", 0)
	setp(NG1030, "Name", "SelectedIndicator")
	setp(NG1030, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1030, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1030, "Parent", NG1027)
	NG1031 = Instance.new("TextBox")
	setp(NG1031, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1031, "BackgroundTransparency", 1)
	setp(NG1031, "BorderSizePixel", 0)
	setp(NG1031, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1031, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1031, "Font", Enum.Font.ArialBold)
	setp(NG1031, "FontSize", Enum.FontSize.Size10)
	setp(NG1031, "Text", "255")
	setp(NG1031, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1031, "Parent", NG1027)
	NG1032 = Instance.new("Frame")
	setp(NG1032, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1032, "BackgroundTransparency", 1)
	setp(NG1032, "BorderSizePixel", 0)
	setp(NG1032, "Name", "BInput")
	setp(NG1032, "Position", UDim2.new(0, 109, 0, 0))
	setp(NG1032, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1032, "Parent", NG1020)
	NG1033 = Instance.new("TextButton")
	setp(NG1033, "Active", true)
	setp(NG1033, "AutoButtonColor", false)
	setp(NG1033, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1033, "BackgroundTransparency", 1)
	setp(NG1033, "BorderSizePixel", 0)
	NG1033.Selectable = true
	setp(NG1033, "Size", UDim2.new(1, 0, 1, 0))
	NG1033.Style = Enum.ButtonStyle.Custom
	setp(NG1033, "ZIndex", 2)
	setp(NG1033, "Font", Enum.Font.Legacy)
	setp(NG1033, "FontSize", Enum.FontSize.Size8)
	setp(NG1033, "Text", "")
	setp(NG1033, "Parent", NG1032)
	NG1034 = Instance.new("ImageLabel")
	setp(NG1034, "Active", false)
	setp(NG1034, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1034, "BackgroundTransparency", 1)
	setp(NG1034, "BorderSizePixel", 0)
	setp(NG1034, "Name", "Background")
	NG1034.Selectable = false
	setp(NG1034, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1034, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1034, "Parent", NG1032)
	NG1035 = Instance.new("Frame")
	setp(NG1035, "BackgroundColor3", Color3.new(0, 0, 1))
	setp(NG1035, "BorderSizePixel", 0)
	setp(NG1035, "Name", "SelectedIndicator")
	setp(NG1035, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1035, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1035, "Parent", NG1032)
	NG1036 = Instance.new("TextBox")
	setp(NG1036, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1036, "BackgroundTransparency", 1)
	setp(NG1036, "BorderSizePixel", 0)
	setp(NG1036, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1036, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1036, "Font", Enum.Font.ArialBold)
	setp(NG1036, "FontSize", Enum.FontSize.Size10)
	setp(NG1036, "Text", "255")
	setp(NG1036, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1036, "Parent", NG1032)
	NG1037 = Instance.new("ImageButton")
	setp(NG1037, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1037, "BackgroundTransparency", 0.40000000596046)
	setp(NG1037, "BorderSizePixel", 0)
	setp(NG1037, "Name", "HSVPicker")
	setp(NG1037, "Position", UDim2.new(0, 160, 0, -2))
	setp(NG1037, "Size", UDim2.new(0, 27, 0, 27))
	NG1037.Style = Enum.ButtonStyle.Custom
	setp(NG1037, "ZIndex", 2)
	setp(NG1037, "Image", "http://www.roblox.com/asset/?id=141313631")
	setp(NG1037, "Parent", NG1020)
	NG1038 = Instance.new("Frame")
	setp(NG1038, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1038, "BackgroundTransparency", 0.75)
	setp(NG1038, "BorderSizePixel", 0)
	setp(NG1038, "Name", "Shadow")
	setp(NG1038, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG1038, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG1038, "Parent", NG1037)
	NG1039 = Instance.new("Frame")
	setp(NG1039, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1039, "BackgroundTransparency", 0.5)
	setp(NG1039, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1039, "BorderSizePixel", 0)
	setp(NG1039, "Name", "Separator")
	setp(NG1039, "Position", UDim2.new(0, 151, 0, 4))
	setp(NG1039, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1039, "Parent", NG1020)
	NG1040 = Instance.new("Frame")
	setp(NG1040, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1040, "BackgroundTransparency", 0.5)
	setp(NG1040, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1040, "BorderSizePixel", 0)
	setp(NG1040, "Name", "Separator")
	setp(NG1040, "Position", UDim2.new(0, 151, 0, 16))
	setp(NG1040, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1040, "Parent", NG1020)
	NG1041 = Instance.new("Frame")
	setp(NG1041, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1041, "BackgroundTransparency", 0.5)
	setp(NG1041, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1041, "BorderSizePixel", 0)
	setp(NG1041, "Name", "Separator")
	setp(NG1041, "Position", UDim2.new(0, 151, 0, 10))
	setp(NG1041, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1041, "Parent", NG1020)
	NG1042 = Instance.new("Frame")
	setp(NG1042, "Active", true)
	setp(NG1042, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1042, "BackgroundTransparency", 1)
	setp(NG1042, "BorderSizePixel", 0)
	setp(NG1042, "Name", "BTAnchorToolGUI")
	setp(NG1042, "Position", UDim2.new(0, 0, 0, 280))
	setp(NG1042, "Size", UDim2.new(0, 245, 0, 90))
	NG1042.Draggable = true
	setp(NG1042, "Parent", NG1)
	NG1043 = Instance.new("Frame")
	setp(NG1043, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1043, "BackgroundTransparency", 1)
	setp(NG1043, "BorderSizePixel", 0)
	setp(NG1043, "Name", "Title")
	setp(NG1043, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG1043, "Parent", NG1042)
	NG1044 = Instance.new("Frame")
	setp(NG1044, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG1044, "BorderSizePixel", 0)
	setp(NG1044, "Name", "ColorBar")
	setp(NG1044, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG1044, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG1044, "Parent", NG1043)
	NG1045 = Instance.new("TextLabel")
	setp(NG1045, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1045, "BackgroundTransparency", 1)
	setp(NG1045, "BorderSizePixel", 0)
	setp(NG1045, "Name", "Label")
	setp(NG1045, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG1045, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1045, "Font", Enum.Font.ArialBold)
	setp(NG1045, "FontSize", Enum.FontSize.Size10)
	setp(NG1045, "Text", "ANCHOR TOOL")
	setp(NG1045, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1045, "TextStrokeTransparency", 0)
	setp(NG1045, "TextWrapped", true)
	setp(NG1045, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1045, "Parent", NG1043)
	NG1046 = Instance.new("TextLabel")
	setp(NG1046, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1046, "BackgroundTransparency", 1)
	setp(NG1046, "BorderSizePixel", 0)
	setp(NG1046, "Name", "F3XSignature")
	setp(NG1046, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG1046, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1046, "Font", Enum.Font.ArialBold)
	setp(NG1046, "FontSize", Enum.FontSize.Size14)
	setp(NG1046, "Text", "F3X")
	setp(NG1046, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1046, "TextStrokeTransparency", 0.89999997615814)
	setp(NG1046, "TextWrapped", true)
	setp(NG1046, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG1046, "Parent", NG1043)
	NG1047 = Instance.new("Frame")
	setp(NG1047, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1047, "BackgroundTransparency", 1)
	setp(NG1047, "BorderSizePixel", 0)
	setp(NG1047, "Name", "Status")
	setp(NG1047, "Position", UDim2.new(0, 0, 0, 30))
	setp(NG1047, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG1047, "Parent", NG1042)
	NG1048 = Instance.new("TextLabel")
	setp(NG1048, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1048, "BackgroundTransparency", 1)
	setp(NG1048, "BorderSizePixel", 0)
	setp(NG1048, "Name", "Label")
	setp(NG1048, "Position", UDim2.new(0, 14, 0, 0))
	setp(NG1048, "Size", UDim2.new(0, 40, 0, 25))
	setp(NG1048, "Font", Enum.Font.ArialBold)
	setp(NG1048, "FontSize", Enum.FontSize.Size10)
	setp(NG1048, "Text", "Status")
	setp(NG1048, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1048, "TextStrokeTransparency", 0)
	setp(NG1048, "TextWrapped", true)
	setp(NG1048, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1048, "Parent", NG1047)
	NG1049 = Instance.new("Frame")
	setp(NG1049, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1049, "BackgroundTransparency", 1)
	setp(NG1049, "BorderSizePixel", 0)
	setp(NG1049, "Name", "Anchored")
	setp(NG1049, "Position", UDim2.new(0, 55, 0, 0))
	setp(NG1049, "Size", UDim2.new(0, 90, 0, 25))
	setp(NG1049, "Parent", NG1047)
	NG1050 = Instance.new("Frame")
	setp(NG1050, "BackgroundTransparency", 1)
	setp(NG1050, "BorderSizePixel", 0)
	setp(NG1050, "Name", "SelectedIndicator")
	setp(NG1050, "Position", UDim2.new(0, 9, 0, -2))
	setp(NG1050, "Size", UDim2.new(1, -9, 0, 2))
	setp(NG1050, "Parent", NG1049)
	NG1051 = Instance.new("TextButton")
	setp(NG1051, "Active", true)
	setp(NG1051, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1051, "BackgroundTransparency", 1)
	setp(NG1051, "BorderSizePixel", 0)
	setp(NG1051, "Name", "Button")
	setp(NG1051, "Position", UDim2.new(0, 5, 0, 0))
	NG1051.Selectable = true
	setp(NG1051, "Size", UDim2.new(1, -10, 1, 0))
	NG1051.Style = Enum.ButtonStyle.Custom
	setp(NG1051, "ZIndex", 2)
	setp(NG1051, "Font", Enum.Font.Legacy)
	setp(NG1051, "FontSize", Enum.FontSize.Size8)
	setp(NG1051, "Text", "")
	NG1051.TextTransparency = 1
	setp(NG1051, "Parent", NG1049)
	NG1052 = Instance.new("ImageLabel")
	setp(NG1052, "Active", false)
	setp(NG1052, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1052, "BackgroundTransparency", 1)
	setp(NG1052, "BorderSizePixel", 0)
	setp(NG1052, "Name", "Background")
	NG1052.Selectable = false
	setp(NG1052, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1052, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1052, "Parent", NG1049)
	NG1053 = Instance.new("TextLabel")
	setp(NG1053, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1053, "BackgroundTransparency", 1)
	setp(NG1053, "BorderSizePixel", 0)
	setp(NG1053, "Name", "Label")
	setp(NG1053, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1053, "Font", Enum.Font.ArialBold)
	setp(NG1053, "FontSize", Enum.FontSize.Size10)
	setp(NG1053, "Text", "ANCHORED")
	setp(NG1053, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1053, "Parent", NG1049)
	NG1054 = Instance.new("Frame")
	setp(NG1054, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1054, "BackgroundTransparency", 1)
	setp(NG1054, "BorderSizePixel", 0)
	setp(NG1054, "Name", "Unanchored")
	setp(NG1054, "Position", UDim2.new(0, 140, 0, 0))
	setp(NG1054, "Size", UDim2.new(0, 90, 0, 25))
	setp(NG1054, "Parent", NG1047)
	NG1055 = Instance.new("Frame")
	setp(NG1055, "BackgroundTransparency", 1)
	setp(NG1055, "BorderSizePixel", 0)
	setp(NG1055, "Name", "SelectedIndicator")
	setp(NG1055, "Position", UDim2.new(0, 9, 0, -2))
	setp(NG1055, "Size", UDim2.new(1, -9, 0, 2))
	setp(NG1055, "Parent", NG1054)
	NG1056 = Instance.new("TextButton")
	setp(NG1056, "Active", true)
	setp(NG1056, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1056, "BackgroundTransparency", 1)
	setp(NG1056, "BorderSizePixel", 0)
	setp(NG1056, "Name", "Button")
	setp(NG1056, "Position", UDim2.new(0, 5, 0, 0))
	NG1056.Selectable = true
	setp(NG1056, "Size", UDim2.new(1, -10, 1, 0))
	NG1056.Style = Enum.ButtonStyle.Custom
	setp(NG1056, "ZIndex", 2)
	setp(NG1056, "Font", Enum.Font.ArialBold)
	setp(NG1056, "FontSize", Enum.FontSize.Size8)
	setp(NG1056, "Text", "")
	NG1056.TextTransparency = 1
	setp(NG1056, "Parent", NG1054)
	NG1057 = Instance.new("ImageLabel")
	setp(NG1057, "Active", false)
	setp(NG1057, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1057, "BackgroundTransparency", 1)
	setp(NG1057, "BorderSizePixel", 0)
	setp(NG1057, "Name", "Background")
	NG1057.Selectable = false
	setp(NG1057, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1057, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1057, "Parent", NG1054)
	NG1058 = Instance.new("TextLabel")
	setp(NG1058, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1058, "BackgroundTransparency", 1)
	setp(NG1058, "BorderSizePixel", 0)
	setp(NG1058, "Name", "Label")
	setp(NG1058, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1058, "Font", Enum.Font.ArialBold)
	setp(NG1058, "FontSize", Enum.FontSize.Size10)
	setp(NG1058, "Text", "UNANCHORED")
	setp(NG1058, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1058, "Parent", NG1054)
	NG1059 = Instance.new("Frame")
	setp(NG1059, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1059, "BackgroundTransparency", 1)
	setp(NG1059, "BorderSizePixel", 0)
	setp(NG1059, "Name", "Tip")
	setp(NG1059, "Position", UDim2.new(0, 5, 0, 70))
	setp(NG1059, "Size", UDim2.new(1, -5, 0, 20))
	setp(NG1059, "Parent", NG1042)
	NG1060 = Instance.new("Frame")
	setp(NG1060, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG1060, "BorderSizePixel", 0)
	setp(NG1060, "Name", "ColorBar")
	setp(NG1060, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG1060, "Parent", NG1059)
	NG1061 = Instance.new("TextLabel")
	setp(NG1061, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1061, "BackgroundTransparency", 1)
	setp(NG1061, "BorderSizePixel", 0)
	setp(NG1061, "Name", "Text")
	setp(NG1061, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG1061, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG1061, "Font", Enum.Font.ArialBold)
	setp(NG1061, "FontSize", Enum.FontSize.Size10)
	setp(NG1061, "Text", "TIP: Press Enter to quickly toggle the anchor.")
	setp(NG1061, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1061, "TextStrokeTransparency", 0.5)
	setp(NG1061, "TextWrapped", true)
	setp(NG1061, "Parent", NG1059)
	NG1062 = Instance.new("Frame")
	setp(NG1062, "Active", true)
	setp(NG1062, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1062, "BackgroundTransparency", 1)
	setp(NG1062, "BorderSizePixel", 0)
	setp(NG1062, "Name", "BTCollisionToolGUI")
	setp(NG1062, "Position", UDim2.new(0, 0, 0, 280))
	setp(NG1062, "Size", UDim2.new(0, 200, 0, 90))
	NG1062.Draggable = true
	setp(NG1062, "Parent", NG1)
	NG1063 = Instance.new("Frame")
	setp(NG1063, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1063, "BackgroundTransparency", 1)
	setp(NG1063, "BorderSizePixel", 0)
	setp(NG1063, "Name", "Title")
	setp(NG1063, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG1063, "Parent", NG1062)
	NG1064 = Instance.new("Frame")
	setp(NG1064, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG1064, "BorderSizePixel", 0)
	setp(NG1064, "Name", "ColorBar")
	setp(NG1064, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG1064, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG1064, "Parent", NG1063)
	NG1065 = Instance.new("TextLabel")
	setp(NG1065, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1065, "BackgroundTransparency", 1)
	setp(NG1065, "BorderSizePixel", 0)
	setp(NG1065, "Name", "Label")
	setp(NG1065, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG1065, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1065, "Font", Enum.Font.ArialBold)
	setp(NG1065, "FontSize", Enum.FontSize.Size10)
	setp(NG1065, "Text", "COLLISION TOOL")
	setp(NG1065, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1065, "TextStrokeTransparency", 0)
	setp(NG1065, "TextWrapped", true)
	setp(NG1065, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1065, "Parent", NG1063)
	NG1066 = Instance.new("TextLabel")
	setp(NG1066, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1066, "BackgroundTransparency", 1)
	setp(NG1066, "BorderSizePixel", 0)
	setp(NG1066, "Name", "F3XSignature")
	setp(NG1066, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG1066, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1066, "Font", Enum.Font.ArialBold)
	setp(NG1066, "FontSize", Enum.FontSize.Size14)
	setp(NG1066, "Text", "F3X")
	setp(NG1066, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1066, "TextStrokeTransparency", 0.89999997615814)
	setp(NG1066, "TextWrapped", true)
	setp(NG1066, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG1066, "Parent", NG1063)
	NG1067 = Instance.new("Frame")
	setp(NG1067, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1067, "BackgroundTransparency", 1)
	setp(NG1067, "BorderSizePixel", 0)
	setp(NG1067, "Name", "Status")
	setp(NG1067, "Position", UDim2.new(0, 0, 0, 30))
	setp(NG1067, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG1067, "Parent", NG1062)
	NG1068 = Instance.new("TextLabel")
	setp(NG1068, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1068, "BackgroundTransparency", 1)
	setp(NG1068, "BorderSizePixel", 0)
	setp(NG1068, "Name", "Label")
	setp(NG1068, "Position", UDim2.new(0, 14, 0, 0))
	setp(NG1068, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG1068, "Font", Enum.Font.ArialBold)
	setp(NG1068, "FontSize", Enum.FontSize.Size10)
	setp(NG1068, "Text", "Collision")
	setp(NG1068, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1068, "TextStrokeTransparency", 0)
	setp(NG1068, "TextWrapped", true)
	setp(NG1068, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1068, "Parent", NG1067)
	NG1069 = Instance.new("Frame")
	setp(NG1069, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1069, "BackgroundTransparency", 1)
	setp(NG1069, "BorderSizePixel", 0)
	setp(NG1069, "Name", "On")
	setp(NG1069, "Position", UDim2.new(0, 70, 0, 0))
	setp(NG1069, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG1069, "Parent", NG1067)
	NG1070 = Instance.new("Frame")
	setp(NG1070, "BackgroundTransparency", 1)
	setp(NG1070, "BorderSizePixel", 0)
	setp(NG1070, "Name", "SelectedIndicator")
	setp(NG1070, "Position", UDim2.new(0, 5, 0, -2))
	setp(NG1070, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG1070, "Parent", NG1069)
	NG1071 = Instance.new("TextButton")
	setp(NG1071, "Active", true)
	setp(NG1071, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1071, "BackgroundTransparency", 1)
	setp(NG1071, "BorderSizePixel", 0)
	setp(NG1071, "Name", "Button")
	setp(NG1071, "Position", UDim2.new(0, 5, 0, 0))
	NG1071.Selectable = true
	setp(NG1071, "Size", UDim2.new(1, -10, 1, 0))
	NG1071.Style = Enum.ButtonStyle.Custom
	setp(NG1071, "ZIndex", 2)
	setp(NG1071, "Font", Enum.Font.Legacy)
	setp(NG1071, "FontSize", Enum.FontSize.Size8)
	setp(NG1071, "Text", "")
	NG1071.TextTransparency = 1
	setp(NG1071, "Parent", NG1069)
	NG1072 = Instance.new("ImageLabel")
	setp(NG1072, "Active", false)
	setp(NG1072, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1072, "BackgroundTransparency", 1)
	setp(NG1072, "BorderSizePixel", 0)
	setp(NG1072, "Name", "Background")
	NG1072.Selectable = false
	setp(NG1072, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1072, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1072, "Parent", NG1069)
	NG1073 = Instance.new("TextLabel")
	setp(NG1073, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1073, "BackgroundTransparency", 1)
	setp(NG1073, "BorderSizePixel", 0)
	setp(NG1073, "Name", "Label")
	setp(NG1073, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1073, "Font", Enum.Font.ArialBold)
	setp(NG1073, "FontSize", Enum.FontSize.Size10)
	setp(NG1073, "Text", "ON")
	setp(NG1073, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1073, "Parent", NG1069)
	NG1074 = Instance.new("Frame")
	setp(NG1074, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1074, "BackgroundTransparency", 1)
	setp(NG1074, "BorderSizePixel", 0)
	setp(NG1074, "Name", "Off")
	setp(NG1074, "Position", UDim2.new(0, 118, 0, 0))
	setp(NG1074, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG1074, "Parent", NG1067)
	NG1075 = Instance.new("Frame")
	setp(NG1075, "BackgroundTransparency", 1)
	setp(NG1075, "BorderSizePixel", 0)
	setp(NG1075, "Name", "SelectedIndicator")
	setp(NG1075, "Position", UDim2.new(0, 5, 0, -2))
	setp(NG1075, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG1075, "Parent", NG1074)
	NG1076 = Instance.new("TextButton")
	setp(NG1076, "Active", true)
	setp(NG1076, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1076, "BackgroundTransparency", 1)
	setp(NG1076, "BorderSizePixel", 0)
	setp(NG1076, "Name", "Button")
	setp(NG1076, "Position", UDim2.new(0, 5, 0, 0))
	NG1076.Selectable = true
	setp(NG1076, "Size", UDim2.new(1, -10, 1, 0))
	NG1076.Style = Enum.ButtonStyle.Custom
	setp(NG1076, "ZIndex", 2)
	setp(NG1076, "Font", Enum.Font.Legacy)
	setp(NG1076, "FontSize", Enum.FontSize.Size8)
	setp(NG1076, "Text", "")
	NG1076.TextTransparency = 1
	setp(NG1076, "Parent", NG1074)
	NG1077 = Instance.new("ImageLabel")
	setp(NG1077, "Active", false)
	setp(NG1077, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1077, "BackgroundTransparency", 1)
	setp(NG1077, "BorderSizePixel", 0)
	setp(NG1077, "Name", "Background")
	NG1077.Selectable = false
	setp(NG1077, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1077, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1077, "Parent", NG1074)
	NG1078 = Instance.new("TextLabel")
	setp(NG1078, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1078, "BackgroundTransparency", 1)
	setp(NG1078, "BorderSizePixel", 0)
	setp(NG1078, "Name", "Label")
	setp(NG1078, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1078, "Font", Enum.Font.ArialBold)
	setp(NG1078, "FontSize", Enum.FontSize.Size10)
	setp(NG1078, "Text", "OFF")
	setp(NG1078, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1078, "Parent", NG1074)
	NG1079 = Instance.new("Frame")
	setp(NG1079, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1079, "BackgroundTransparency", 1)
	setp(NG1079, "BorderSizePixel", 0)
	setp(NG1079, "Name", "Tip")
	setp(NG1079, "Position", UDim2.new(0, 5, 0, 70))
	setp(NG1079, "Size", UDim2.new(1, -5, 0, 20))
	setp(NG1079, "Parent", NG1062)
	NG1080 = Instance.new("Frame")
	setp(NG1080, "BackgroundColor3", Color3.new(0.0666667, 0.0666667, 0.0666667))
	setp(NG1080, "BorderSizePixel", 0)
	setp(NG1080, "Name", "ColorBar")
	setp(NG1080, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG1080, "Parent", NG1079)
	NG1081 = Instance.new("TextLabel")
	setp(NG1081, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1081, "BackgroundTransparency", 1)
	setp(NG1081, "BorderSizePixel", 0)
	setp(NG1081, "Name", "Text")
	setp(NG1081, "Position", UDim2.new(0, 0, 0, 2))
	setp(NG1081, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG1081, "Font", Enum.Font.ArialBold)
	setp(NG1081, "FontSize", Enum.FontSize.Size10)
	setp(NG1081, "Text", "TIP: Press Enter to toggle collision.")
	setp(NG1081, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1081, "TextStrokeTransparency", 0.5)
	setp(NG1081, "TextWrapped", true)
	setp(NG1081, "Parent", NG1079)
	NG1082 = Instance.new("Frame")
	setp(NG1082, "Active", true)
	setp(NG1082, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1082, "BackgroundTransparency", 1)
	setp(NG1082, "BorderSizePixel", 0)
	setp(NG1082, "Name", "BTDecorateToolGUI")
	setp(NG1082, "Position", UDim2.new(0, 0, 0, 172))
	setp(NG1082, "Size", UDim2.new(0, 200, 0, 125))
	NG1082.Draggable = true
	setp(NG1082, "Parent", NG1)
	NG1083 = Instance.new("Frame")
	setp(NG1083, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1083, "BorderSizePixel", 0)
	setp(NG1083, "Name", "BottomColorBar")
	setp(NG1083, "Position", UDim2.new(0, 5, 1, -2))
	setp(NG1083, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG1083, "Parent", NG1082)
	NG1084 = Instance.new("Frame")
	setp(NG1084, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1084, "BackgroundTransparency", 1)
	setp(NG1084, "BorderSizePixel", 0)
	setp(NG1084, "Name", "Title")
	setp(NG1084, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG1084, "Parent", NG1082)
	NG1085 = Instance.new("Frame")
	setp(NG1085, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1085, "BorderSizePixel", 0)
	setp(NG1085, "Name", "ColorBar")
	setp(NG1085, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG1085, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG1085, "Parent", NG1084)
	NG1086 = Instance.new("TextLabel")
	setp(NG1086, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1086, "BackgroundTransparency", 1)
	setp(NG1086, "BorderSizePixel", 0)
	setp(NG1086, "Name", "Label")
	setp(NG1086, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG1086, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1086, "Font", Enum.Font.ArialBold)
	setp(NG1086, "FontSize", Enum.FontSize.Size10)
	setp(NG1086, "Text", "DECORATE TOOL")
	setp(NG1086, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1086, "TextStrokeTransparency", 0)
	setp(NG1086, "TextWrapped", true)
	setp(NG1086, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1086, "Parent", NG1084)
	NG1087 = Instance.new("TextLabel")
	setp(NG1087, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1087, "BackgroundTransparency", 1)
	setp(NG1087, "BorderSizePixel", 0)
	setp(NG1087, "Name", "F3XSignature")
	setp(NG1087, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG1087, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1087, "Font", Enum.Font.ArialBold)
	setp(NG1087, "FontSize", Enum.FontSize.Size14)
	setp(NG1087, "Text", "F3X")
	setp(NG1087, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1087, "TextStrokeTransparency", 0.89999997615814)
	setp(NG1087, "TextWrapped", true)
	setp(NG1087, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG1087, "Parent", NG1084)
	NG1088 = Instance.new("Frame")
	setp(NG1088, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1088, "BackgroundTransparency", 0.67500001192093)
	setp(NG1088, "BorderSizePixel", 0)
	setp(NG1088, "Name", "Smoke")
	setp(NG1088, "Position", UDim2.new(0, 10, 0, 30))
	setp(NG1088, "Size", UDim2.new(1, -10, 0, 25))
	setp(NG1088, "Parent", NG1082)
	NG1089 = Instance.new("TextLabel")
	setp(NG1089, "BackgroundTransparency", 1)
	setp(NG1089, "BorderSizePixel", 0)
	setp(NG1089, "Name", "Label")
	setp(NG1089, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG1089, "Size", UDim2.new(0, 60, 0, 25))
	setp(NG1089, "Font", Enum.Font.ArialBold)
	setp(NG1089, "FontSize", Enum.FontSize.Size10)
	setp(NG1089, "Text", "Smoke")
	setp(NG1089, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1089, "TextStrokeTransparency", 0.5)
	setp(NG1089, "TextWrapped", true)
	setp(NG1089, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1089, "Parent", NG1088)
	NG1090 = Instance.new("ImageButton")
	setp(NG1090, "BackgroundTransparency", 1)
	setp(NG1090, "BorderSizePixel", 0)
	setp(NG1090, "Name", "ArrowButton")
	setp(NG1090, "Position", UDim2.new(0, 10, 0, 3))
	setp(NG1090, "Size", UDim2.new(0, 20, 0, 20))
	NG1090.Style = Enum.ButtonStyle.Custom
	setp(NG1090, "Image", "http://www.roblox.com/asset/?id=134367382")
	setp(NG1090, "Parent", NG1088)
	NG1091 = Instance.new("Frame")
	setp(NG1091, "BackgroundColor3", Color3.new(1, 0.682353, 0.235294))
	setp(NG1091, "BorderSizePixel", 0)
	setp(NG1091, "Name", "ColorBar")
	setp(NG1091, "Size", UDim2.new(0, 3, 1, 0))
	setp(NG1091, "Parent", NG1088)
	NG1092 = Instance.new("TextButton")
	setp(NG1092, "Active", true)
	setp(NG1092, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1092, "BackgroundTransparency", 0.75)
	setp(NG1092, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG1092, "BorderSizePixel", 0)
	setp(NG1092, "Name", "AddButton")
	setp(NG1092, "Position", UDim2.new(1, -40, 0, 3))
	NG1092.Selectable = true
	setp(NG1092, "Size", UDim2.new(0, 35, 0, 19))
	NG1092.Style = Enum.ButtonStyle.Custom
	setp(NG1092, "Font", Enum.Font.ArialBold)
	setp(NG1092, "FontSize", Enum.FontSize.Size10)
	setp(NG1092, "Text", "ADD")
	setp(NG1092, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1092, "Parent", NG1088)
	NG1093 = Instance.new("TextButton")
	setp(NG1093, "Active", true)
	setp(NG1093, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1093, "BackgroundTransparency", 0.75)
	setp(NG1093, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG1093, "BorderSizePixel", 0)
	setp(NG1093, "Name", "RemoveButton")
	setp(NG1093, "Position", UDim2.new(0, 127, 0, 3))
	NG1093.Selectable = true
	setp(NG1093, "Size", UDim2.new(0, 58, 0, 19))
	NG1093.Style = Enum.ButtonStyle.Custom
	setp(NG1093, "Visible", false)
	setp(NG1093, "Font", Enum.Font.ArialBold)
	setp(NG1093, "FontSize", Enum.FontSize.Size10)
	setp(NG1093, "Text", "REMOVE")
	setp(NG1093, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1093, "Parent", NG1088)
	NG1094 = Instance.new("Frame")
	setp(NG1094, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1094, "BackgroundTransparency", 0.75)
	setp(NG1094, "BorderSizePixel", 0)
	setp(NG1094, "Name", "Shadow")
	setp(NG1094, "Position", UDim2.new(0, 0, 1, -1))
	setp(NG1094, "Size", UDim2.new(1, 0, 0, 1))
	setp(NG1094, "Parent", NG1088)
	NG1095 = Instance.new("Frame")
	setp(NG1095, "BackgroundTransparency", 1)
	setp(NG1095, "BorderSizePixel", 0)
	setp(NG1095, "Name", "Options")
	setp(NG1095, "Position", UDim2.new(0, 3, 1, 0))
	setp(NG1095, "Size", UDim2.new(1, -3, 0, 0))
	setp(NG1095, "ClipsDescendants", true)
	setp(NG1095, "Parent", NG1088)
	NG1096 = Instance.new("Frame")
	setp(NG1096, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1096, "BackgroundTransparency", 1)
	setp(NG1096, "BorderSizePixel", 0)
	setp(NG1096, "Name", "ColorOption")
	setp(NG1096, "Position", UDim2.new(0, 0, 0, 10))
	setp(NG1096, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG1096, "Parent", NG1095)
	NG1097 = Instance.new("TextLabel")
	setp(NG1097, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1097, "BackgroundTransparency", 1)
	setp(NG1097, "BorderSizePixel", 0)
	setp(NG1097, "Name", "Label")
	setp(NG1097, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG1097, "Font", Enum.Font.ArialBold)
	setp(NG1097, "FontSize", Enum.FontSize.Size10)
	setp(NG1097, "Text", "Color")
	setp(NG1097, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1097, "TextStrokeTransparency", 0)
	setp(NG1097, "TextWrapped", true)
	setp(NG1097, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1097, "Parent", NG1096)
	NG1098 = Instance.new("Frame")
	setp(NG1098, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1098, "BackgroundTransparency", 1)
	setp(NG1098, "BorderSizePixel", 0)
	setp(NG1098, "Name", "RInput")
	setp(NG1098, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG1098, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1098, "Parent", NG1096)
	NG1099 = Instance.new("TextButton")
	setp(NG1099, "Active", true)
	setp(NG1099, "AutoButtonColor", false)
	setp(NG1099, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1099, "BackgroundTransparency", 1)
	setp(NG1099, "BorderSizePixel", 0)
	NG1099.Selectable = true
	setp(NG1099, "Size", UDim2.new(1, 0, 1, 0))
	NG1099.Style = Enum.ButtonStyle.Custom
	setp(NG1099, "ZIndex", 2)
	setp(NG1099, "Font", Enum.Font.Legacy)
	setp(NG1099, "FontSize", Enum.FontSize.Size8)
	setp(NG1099, "Text", "")
	setp(NG1099, "Parent", NG1098)
	NG1100 = Instance.new("ImageLabel")
	setp(NG1100, "Active", false)
	setp(NG1100, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1100, "BackgroundTransparency", 1)
	setp(NG1100, "BorderSizePixel", 0)
	setp(NG1100, "Name", "Background")
	NG1100.Selectable = false
	setp(NG1100, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1100, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1100, "Parent", NG1098)
	NG1101 = Instance.new("Frame")
	setp(NG1101, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG1101, "BorderSizePixel", 0)
	setp(NG1101, "Name", "SelectedIndicator")
	setp(NG1101, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1101, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1101, "Parent", NG1098)
	NG1102 = Instance.new("TextBox")
	setp(NG1102, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1102, "BackgroundTransparency", 1)
	setp(NG1102, "BorderSizePixel", 0)
	setp(NG1102, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1102, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1102, "Font", Enum.Font.ArialBold)
	setp(NG1102, "FontSize", Enum.FontSize.Size10)
	setp(NG1102, "Text", "255")
	setp(NG1102, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1102, "Parent", NG1098)
	NG1103 = Instance.new("Frame")
	setp(NG1103, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1103, "BackgroundTransparency", 1)
	setp(NG1103, "BorderSizePixel", 0)
	setp(NG1103, "Name", "GInput")
	setp(NG1103, "Position", UDim2.new(0, 72, 0, 0))
	setp(NG1103, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1103, "Parent", NG1096)
	NG1104 = Instance.new("TextButton")
	setp(NG1104, "Active", true)
	setp(NG1104, "AutoButtonColor", false)
	setp(NG1104, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1104, "BackgroundTransparency", 1)
	setp(NG1104, "BorderSizePixel", 0)
	NG1104.Selectable = true
	setp(NG1104, "Size", UDim2.new(1, 0, 1, 0))
	NG1104.Style = Enum.ButtonStyle.Custom
	setp(NG1104, "ZIndex", 2)
	setp(NG1104, "Font", Enum.Font.Legacy)
	setp(NG1104, "FontSize", Enum.FontSize.Size8)
	setp(NG1104, "Text", "")
	setp(NG1104, "Parent", NG1103)
	NG1105 = Instance.new("ImageLabel")
	setp(NG1105, "Active", false)
	setp(NG1105, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1105, "BackgroundTransparency", 1)
	setp(NG1105, "BorderSizePixel", 0)
	setp(NG1105, "Name", "Background")
	NG1105.Selectable = false
	setp(NG1105, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1105, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1105, "Parent", NG1103)
	NG1106 = Instance.new("Frame")
	setp(NG1106, "BackgroundColor3", Color3.new(0, 1, 0))
	setp(NG1106, "BorderSizePixel", 0)
	setp(NG1106, "Name", "SelectedIndicator")
	setp(NG1106, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1106, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1106, "Parent", NG1103)
	NG1107 = Instance.new("TextBox")
	setp(NG1107, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1107, "BackgroundTransparency", 1)
	setp(NG1107, "BorderSizePixel", 0)
	setp(NG1107, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1107, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1107, "Font", Enum.Font.ArialBold)
	setp(NG1107, "FontSize", Enum.FontSize.Size10)
	setp(NG1107, "Text", "255")
	setp(NG1107, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1107, "Parent", NG1103)
	NG1108 = Instance.new("Frame")
	setp(NG1108, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1108, "BackgroundTransparency", 1)
	setp(NG1108, "BorderSizePixel", 0)
	setp(NG1108, "Name", "BInput")
	setp(NG1108, "Position", UDim2.new(0, 109, 0, 0))
	setp(NG1108, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1108, "Parent", NG1096)
	NG1109 = Instance.new("TextButton")
	setp(NG1109, "Active", true)
	setp(NG1109, "AutoButtonColor", false)
	setp(NG1109, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1109, "BackgroundTransparency", 1)
	setp(NG1109, "BorderSizePixel", 0)
	NG1109.Selectable = true
	setp(NG1109, "Size", UDim2.new(1, 0, 1, 0))
	NG1109.Style = Enum.ButtonStyle.Custom
	setp(NG1109, "ZIndex", 2)
	setp(NG1109, "Font", Enum.Font.Legacy)
	setp(NG1109, "FontSize", Enum.FontSize.Size8)
	setp(NG1109, "Text", "")
	setp(NG1109, "Parent", NG1108)
	NG1110 = Instance.new("ImageLabel")
	setp(NG1110, "Active", false)
	setp(NG1110, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1110, "BackgroundTransparency", 1)
	setp(NG1110, "BorderSizePixel", 0)
	setp(NG1110, "Name", "Background")
	NG1110.Selectable = false
	setp(NG1110, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1110, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1110, "Parent", NG1108)
	NG1111 = Instance.new("Frame")
	setp(NG1111, "BackgroundColor3", Color3.new(0, 0, 1))
	setp(NG1111, "BorderSizePixel", 0)
	setp(NG1111, "Name", "SelectedIndicator")
	setp(NG1111, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1111, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1111, "Parent", NG1108)
	NG1112 = Instance.new("TextBox")
	setp(NG1112, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1112, "BackgroundTransparency", 1)
	setp(NG1112, "BorderSizePixel", 0)
	setp(NG1112, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1112, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1112, "Font", Enum.Font.ArialBold)
	setp(NG1112, "FontSize", Enum.FontSize.Size10)
	setp(NG1112, "Text", "255")
	setp(NG1112, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1112, "Parent", NG1108)
	NG1113 = Instance.new("ImageButton")
	setp(NG1113, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1113, "BackgroundTransparency", 0.40000000596046)
	setp(NG1113, "BorderSizePixel", 0)
	setp(NG1113, "Name", "HSVPicker")
	setp(NG1113, "Position", UDim2.new(0, 160, 0, -2))
	setp(NG1113, "Size", UDim2.new(0, 27, 0, 27))
	NG1113.Style = Enum.ButtonStyle.Custom
	setp(NG1113, "Image", "http://www.roblox.com/asset/?id=141313631")
	setp(NG1113, "Parent", NG1096)
	NG1114 = Instance.new("Frame")
	setp(NG1114, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1114, "BackgroundTransparency", 0.75)
	setp(NG1114, "BorderSizePixel", 0)
	setp(NG1114, "Name", "Shadow")
	setp(NG1114, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG1114, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG1114, "Parent", NG1113)
	NG1115 = Instance.new("Frame")
	setp(NG1115, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1115, "BackgroundTransparency", 0.5)
	setp(NG1115, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1115, "BorderSizePixel", 0)
	setp(NG1115, "Name", "Separator")
	setp(NG1115, "Position", UDim2.new(0, 151, 0, 4))
	setp(NG1115, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1115, "Parent", NG1096)
	NG1116 = Instance.new("Frame")
	setp(NG1116, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1116, "BackgroundTransparency", 0.5)
	setp(NG1116, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1116, "BorderSizePixel", 0)
	setp(NG1116, "Name", "Separator")
	setp(NG1116, "Position", UDim2.new(0, 151, 0, 16))
	setp(NG1116, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1116, "Parent", NG1096)
	NG1117 = Instance.new("Frame")
	setp(NG1117, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1117, "BackgroundTransparency", 0.5)
	setp(NG1117, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1117, "BorderSizePixel", 0)
	setp(NG1117, "Name", "Separator")
	setp(NG1117, "Position", UDim2.new(0, 151, 0, 10))
	setp(NG1117, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1117, "Parent", NG1096)
	NG1118 = Instance.new("Frame")
	setp(NG1118, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1118, "BackgroundTransparency", 1)
	setp(NG1118, "BorderSizePixel", 0)
	setp(NG1118, "Name", "OpacityOption")
	setp(NG1118, "Position", UDim2.new(0, 0, 0, 45))
	setp(NG1118, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG1118, "Parent", NG1095)
	NG1119 = Instance.new("TextLabel")
	setp(NG1119, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1119, "BackgroundTransparency", 1)
	setp(NG1119, "BorderSizePixel", 0)
	setp(NG1119, "Name", "Label")
	setp(NG1119, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG1119, "Font", Enum.Font.ArialBold)
	setp(NG1119, "FontSize", Enum.FontSize.Size10)
	setp(NG1119, "Text", "Opacity")
	setp(NG1119, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1119, "TextStrokeTransparency", 0)
	setp(NG1119, "TextWrapped", true)
	setp(NG1119, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1119, "Parent", NG1118)
	NG1120 = Instance.new("Frame")
	setp(NG1120, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1120, "BackgroundTransparency", 1)
	setp(NG1120, "BorderSizePixel", 0)
	setp(NG1120, "Name", "Input")
	setp(NG1120, "Position", UDim2.new(0, 45, 0, 0))
	setp(NG1120, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1120, "Parent", NG1118)
	NG1121 = Instance.new("TextButton")
	setp(NG1121, "Active", true)
	setp(NG1121, "AutoButtonColor", false)
	setp(NG1121, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1121, "BackgroundTransparency", 1)
	setp(NG1121, "BorderSizePixel", 0)
	NG1121.Selectable = true
	setp(NG1121, "Size", UDim2.new(1, 0, 1, 0))
	NG1121.Style = Enum.ButtonStyle.Custom
	setp(NG1121, "ZIndex", 2)
	setp(NG1121, "Font", Enum.Font.Legacy)
	setp(NG1121, "FontSize", Enum.FontSize.Size8)
	setp(NG1121, "Text", "")
	setp(NG1121, "Parent", NG1120)
	NG1122 = Instance.new("ImageLabel")
	setp(NG1122, "Active", false)
	setp(NG1122, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1122, "BackgroundTransparency", 1)
	setp(NG1122, "BorderSizePixel", 0)
	setp(NG1122, "Name", "Background")
	NG1122.Selectable = false
	setp(NG1122, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1122, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1122, "Parent", NG1120)
	NG1123 = Instance.new("Frame")
	setp(NG1123, "BorderSizePixel", 0)
	setp(NG1123, "Name", "SelectedIndicator")
	setp(NG1123, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1123, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1123, "Parent", NG1120)
	NG1124 = Instance.new("TextBox")
	setp(NG1124, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1124, "BackgroundTransparency", 1)
	setp(NG1124, "BorderSizePixel", 0)
	setp(NG1124, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1124, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1124, "Font", Enum.Font.ArialBold)
	setp(NG1124, "FontSize", Enum.FontSize.Size10)
	setp(NG1124, "Text", "1")
	setp(NG1124, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1124, "Parent", NG1120)
	NG1125 = Instance.new("Frame")
	setp(NG1125, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1125, "BackgroundTransparency", 1)
	setp(NG1125, "BorderSizePixel", 0)
	setp(NG1125, "Name", "VelocityOption")
	setp(NG1125, "Position", UDim2.new(0, 100, 0, 45))
	setp(NG1125, "Size", UDim2.new(1, -115, 0, 25))
	setp(NG1125, "Parent", NG1095)
	NG1126 = Instance.new("TextLabel")
	setp(NG1126, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1126, "BackgroundTransparency", 1)
	setp(NG1126, "BorderSizePixel", 0)
	setp(NG1126, "Name", "Label")
	setp(NG1126, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG1126, "Font", Enum.Font.ArialBold)
	setp(NG1126, "FontSize", Enum.FontSize.Size10)
	setp(NG1126, "Text", "Velocity")
	setp(NG1126, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1126, "TextStrokeTransparency", 0)
	setp(NG1126, "TextWrapped", true)
	setp(NG1126, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1126, "Parent", NG1125)
	NG1127 = Instance.new("Frame")
	setp(NG1127, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1127, "BackgroundTransparency", 1)
	setp(NG1127, "BorderSizePixel", 0)
	setp(NG1127, "Name", "Input")
	setp(NG1127, "Position", UDim2.new(0, 45, 0, 0))
	setp(NG1127, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1127, "Parent", NG1125)
	NG1128 = Instance.new("TextButton")
	setp(NG1128, "Active", true)
	setp(NG1128, "AutoButtonColor", false)
	setp(NG1128, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1128, "BackgroundTransparency", 1)
	setp(NG1128, "BorderSizePixel", 0)
	NG1128.Selectable = true
	setp(NG1128, "Size", UDim2.new(1, 0, 1, 0))
	NG1128.Style = Enum.ButtonStyle.Custom
	setp(NG1128, "ZIndex", 2)
	setp(NG1128, "Font", Enum.Font.Legacy)
	setp(NG1128, "FontSize", Enum.FontSize.Size8)
	setp(NG1128, "Text", "")
	setp(NG1128, "Parent", NG1127)
	NG1129 = Instance.new("ImageLabel")
	setp(NG1129, "Active", false)
	setp(NG1129, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1129, "BackgroundTransparency", 1)
	setp(NG1129, "BorderSizePixel", 0)
	setp(NG1129, "Name", "Background")
	NG1129.Selectable = false
	setp(NG1129, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1129, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1129, "Parent", NG1127)
	NG1130 = Instance.new("Frame")
	setp(NG1130, "BorderSizePixel", 0)
	setp(NG1130, "Name", "SelectedIndicator")
	setp(NG1130, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1130, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1130, "Parent", NG1127)
	NG1131 = Instance.new("TextBox")
	setp(NG1131, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1131, "BackgroundTransparency", 1)
	setp(NG1131, "BorderSizePixel", 0)
	setp(NG1131, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1131, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1131, "Font", Enum.Font.ArialBold)
	setp(NG1131, "FontSize", Enum.FontSize.Size10)
	setp(NG1131, "Text", "90")
	setp(NG1131, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1131, "Parent", NG1127)
	NG1132 = Instance.new("Frame")
	setp(NG1132, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1132, "BackgroundTransparency", 1)
	setp(NG1132, "BorderSizePixel", 0)
	setp(NG1132, "Name", "SizeOption")
	setp(NG1132, "Position", UDim2.new(0, 0, 0, 80))
	setp(NG1132, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG1132, "Parent", NG1095)
	NG1133 = Instance.new("TextLabel")
	setp(NG1133, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1133, "BackgroundTransparency", 1)
	setp(NG1133, "BorderSizePixel", 0)
	setp(NG1133, "Name", "Label")
	setp(NG1133, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG1133, "Font", Enum.Font.ArialBold)
	setp(NG1133, "FontSize", Enum.FontSize.Size10)
	setp(NG1133, "Text", "Size")
	setp(NG1133, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1133, "TextStrokeTransparency", 0)
	setp(NG1133, "TextWrapped", true)
	setp(NG1133, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1133, "Parent", NG1132)
	NG1134 = Instance.new("Frame")
	setp(NG1134, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1134, "BackgroundTransparency", 1)
	setp(NG1134, "BorderSizePixel", 0)
	setp(NG1134, "Name", "Input")
	setp(NG1134, "Position", UDim2.new(0, 30, 0, 0))
	setp(NG1134, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1134, "Parent", NG1132)
	NG1135 = Instance.new("TextButton")
	setp(NG1135, "Active", true)
	setp(NG1135, "AutoButtonColor", false)
	setp(NG1135, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1135, "BackgroundTransparency", 1)
	setp(NG1135, "BorderSizePixel", 0)
	NG1135.Selectable = true
	setp(NG1135, "Size", UDim2.new(1, 0, 1, 0))
	NG1135.Style = Enum.ButtonStyle.Custom
	setp(NG1135, "ZIndex", 2)
	setp(NG1135, "Font", Enum.Font.Legacy)
	setp(NG1135, "FontSize", Enum.FontSize.Size8)
	setp(NG1135, "Text", "")
	setp(NG1135, "Parent", NG1134)
	NG1136 = Instance.new("ImageLabel")
	setp(NG1136, "Active", false)
	setp(NG1136, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1136, "BackgroundTransparency", 1)
	setp(NG1136, "BorderSizePixel", 0)
	setp(NG1136, "Name", "Background")
	NG1136.Selectable = false
	setp(NG1136, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1136, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1136, "Parent", NG1134)
	NG1137 = Instance.new("Frame")
	setp(NG1137, "BorderSizePixel", 0)
	setp(NG1137, "Name", "SelectedIndicator")
	setp(NG1137, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1137, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1137, "Parent", NG1134)
	NG1138 = Instance.new("TextBox")
	setp(NG1138, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1138, "BackgroundTransparency", 1)
	setp(NG1138, "BorderSizePixel", 0)
	setp(NG1138, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1138, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1138, "Font", Enum.Font.ArialBold)
	setp(NG1138, "FontSize", Enum.FontSize.Size10)
	setp(NG1138, "Text", "16")
	setp(NG1138, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1138, "Parent", NG1134)
	NG1139 = Instance.new("TextLabel")
	setp(NG1139, "BackgroundTransparency", 1)
	setp(NG1139, "BorderSizePixel", 0)
	setp(NG1139, "Name", "SelectNote")
	setp(NG1139, "Position", UDim2.new(0, 10, 0, 27))
	setp(NG1139, "Size", UDim2.new(1, -10, 0, 15))
	setp(NG1139, "Visible", false)
	setp(NG1139, "FontSize", Enum.FontSize.Size14)
	setp(NG1139, "Text", "Select something to use this tool.")
	setp(NG1139, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1139, "TextScaled", true)
	setp(NG1139, "TextStrokeTransparency", 0.5)
	setp(NG1139, "TextWrapped", true)
	setp(NG1139, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1139, "Parent", NG1082)
	NG1140 = Instance.new("Frame")
	setp(NG1140, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1140, "BackgroundTransparency", 0.67500001192093)
	setp(NG1140, "BorderSizePixel", 0)
	setp(NG1140, "Name", "Fire")
	setp(NG1140, "Position", UDim2.new(0, 10, 0, 60))
	setp(NG1140, "Size", UDim2.new(1, -10, 0, 25))
	setp(NG1140, "Parent", NG1082)
	NG1141 = Instance.new("TextLabel")
	setp(NG1141, "BackgroundTransparency", 1)
	setp(NG1141, "BorderSizePixel", 0)
	setp(NG1141, "Name", "Label")
	setp(NG1141, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG1141, "Size", UDim2.new(0, 60, 0, 25))
	setp(NG1141, "Font", Enum.Font.ArialBold)
	setp(NG1141, "FontSize", Enum.FontSize.Size10)
	setp(NG1141, "Text", "Fire")
	setp(NG1141, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1141, "TextStrokeTransparency", 0.5)
	setp(NG1141, "TextWrapped", true)
	setp(NG1141, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1141, "Parent", NG1140)
	NG1142 = Instance.new("ImageButton")
	setp(NG1142, "BackgroundTransparency", 1)
	setp(NG1142, "BorderSizePixel", 0)
	setp(NG1142, "Name", "ArrowButton")
	setp(NG1142, "Position", UDim2.new(0, 10, 0, 3))
	setp(NG1142, "Size", UDim2.new(0, 20, 0, 20))
	NG1142.Style = Enum.ButtonStyle.Custom
	setp(NG1142, "Image", "http://www.roblox.com/asset/?id=134367382")
	setp(NG1142, "Parent", NG1140)
	NG1143 = Instance.new("Frame")
	setp(NG1143, "BackgroundColor3", Color3.new(0.85098, 0, 1))
	setp(NG1143, "BorderSizePixel", 0)
	setp(NG1143, "Name", "ColorBar")
	setp(NG1143, "Size", UDim2.new(0, 3, 1, 0))
	setp(NG1143, "Parent", NG1140)
	NG1144 = Instance.new("TextButton")
	setp(NG1144, "Active", true)
	setp(NG1144, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1144, "BackgroundTransparency", 0.75)
	setp(NG1144, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG1144, "BorderSizePixel", 0)
	setp(NG1144, "Name", "AddButton")
	setp(NG1144, "Position", UDim2.new(1, -40, 0, 3))
	NG1144.Selectable = true
	setp(NG1144, "Size", UDim2.new(0, 35, 0, 19))
	NG1144.Style = Enum.ButtonStyle.Custom
	setp(NG1144, "Font", Enum.Font.ArialBold)
	setp(NG1144, "FontSize", Enum.FontSize.Size10)
	setp(NG1144, "Text", "ADD")
	setp(NG1144, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1144, "Parent", NG1140)
	NG1145 = Instance.new("TextButton")
	setp(NG1145, "Active", true)
	setp(NG1145, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1145, "BackgroundTransparency", 0.75)
	setp(NG1145, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG1145, "BorderSizePixel", 0)
	setp(NG1145, "Name", "RemoveButton")
	setp(NG1145, "Position", UDim2.new(0, 90, 0, 3))
	NG1145.Selectable = true
	setp(NG1145, "Size", UDim2.new(0, 58, 0, 19))
	NG1145.Style = Enum.ButtonStyle.Custom
	setp(NG1145, "Visible", false)
	setp(NG1145, "Font", Enum.Font.ArialBold)
	setp(NG1145, "FontSize", Enum.FontSize.Size10)
	setp(NG1145, "Text", "REMOVE")
	setp(NG1145, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1145, "Parent", NG1140)
	NG1146 = Instance.new("Frame")
	setp(NG1146, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1146, "BackgroundTransparency", 0.75)
	setp(NG1146, "BorderSizePixel", 0)
	setp(NG1146, "Name", "Shadow")
	setp(NG1146, "Position", UDim2.new(0, 0, 1, -1))
	setp(NG1146, "Size", UDim2.new(1, 0, 0, 1))
	setp(NG1146, "Parent", NG1140)
	NG1147 = Instance.new("Frame")
	setp(NG1147, "BackgroundTransparency", 1)
	setp(NG1147, "BorderSizePixel", 0)
	setp(NG1147, "Name", "Options")
	setp(NG1147, "Position", UDim2.new(0, 3, 1, 0))
	setp(NG1147, "Size", UDim2.new(1, -3, 0, 0))
	setp(NG1147, "ClipsDescendants", true)
	setp(NG1147, "Parent", NG1140)
	NG1148 = Instance.new("Frame")
	setp(NG1148, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1148, "BackgroundTransparency", 1)
	setp(NG1148, "BorderSizePixel", 0)
	setp(NG1148, "Name", "ColorOption")
	setp(NG1148, "Position", UDim2.new(0, 0, 0, 10))
	setp(NG1148, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG1148, "Parent", NG1147)
	NG1149 = Instance.new("TextLabel")
	setp(NG1149, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1149, "BackgroundTransparency", 1)
	setp(NG1149, "BorderSizePixel", 0)
	setp(NG1149, "Name", "Label")
	setp(NG1149, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG1149, "Font", Enum.Font.ArialBold)
	setp(NG1149, "FontSize", Enum.FontSize.Size10)
	setp(NG1149, "Text", "Color")
	setp(NG1149, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1149, "TextStrokeTransparency", 0)
	setp(NG1149, "TextWrapped", true)
	setp(NG1149, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1149, "Parent", NG1148)
	NG1150 = Instance.new("Frame")
	setp(NG1150, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1150, "BackgroundTransparency", 1)
	setp(NG1150, "BorderSizePixel", 0)
	setp(NG1150, "Name", "RInput")
	setp(NG1150, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG1150, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1150, "Parent", NG1148)
	NG1151 = Instance.new("TextButton")
	setp(NG1151, "Active", true)
	setp(NG1151, "AutoButtonColor", false)
	setp(NG1151, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1151, "BackgroundTransparency", 1)
	setp(NG1151, "BorderSizePixel", 0)
	NG1151.Selectable = true
	setp(NG1151, "Size", UDim2.new(1, 0, 1, 0))
	NG1151.Style = Enum.ButtonStyle.Custom
	setp(NG1151, "ZIndex", 2)
	setp(NG1151, "Font", Enum.Font.Legacy)
	setp(NG1151, "FontSize", Enum.FontSize.Size8)
	setp(NG1151, "Text", "")
	setp(NG1151, "Parent", NG1150)
	NG1152 = Instance.new("ImageLabel")
	setp(NG1152, "Active", false)
	setp(NG1152, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1152, "BackgroundTransparency", 1)
	setp(NG1152, "BorderSizePixel", 0)
	setp(NG1152, "Name", "Background")
	NG1152.Selectable = false
	setp(NG1152, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1152, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1152, "Parent", NG1150)
	NG1153 = Instance.new("Frame")
	setp(NG1153, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG1153, "BorderSizePixel", 0)
	setp(NG1153, "Name", "SelectedIndicator")
	setp(NG1153, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1153, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1153, "Parent", NG1150)
	NG1154 = Instance.new("TextBox")
	setp(NG1154, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1154, "BackgroundTransparency", 1)
	setp(NG1154, "BorderSizePixel", 0)
	setp(NG1154, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1154, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1154, "Font", Enum.Font.ArialBold)
	setp(NG1154, "FontSize", Enum.FontSize.Size10)
	setp(NG1154, "Text", "255")
	setp(NG1154, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1154, "Parent", NG1150)
	NG1155 = Instance.new("Frame")
	setp(NG1155, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1155, "BackgroundTransparency", 1)
	setp(NG1155, "BorderSizePixel", 0)
	setp(NG1155, "Name", "GInput")
	setp(NG1155, "Position", UDim2.new(0, 72, 0, 0))
	setp(NG1155, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1155, "Parent", NG1148)
	NG1156 = Instance.new("TextButton")
	setp(NG1156, "Active", true)
	setp(NG1156, "AutoButtonColor", false)
	setp(NG1156, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1156, "BackgroundTransparency", 1)
	setp(NG1156, "BorderSizePixel", 0)
	NG1156.Selectable = true
	setp(NG1156, "Size", UDim2.new(1, 0, 1, 0))
	NG1156.Style = Enum.ButtonStyle.Custom
	setp(NG1156, "ZIndex", 2)
	setp(NG1156, "Font", Enum.Font.Legacy)
	setp(NG1156, "FontSize", Enum.FontSize.Size8)
	setp(NG1156, "Text", "")
	setp(NG1156, "Parent", NG1155)
	NG1157 = Instance.new("ImageLabel")
	setp(NG1157, "Active", false)
	setp(NG1157, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1157, "BackgroundTransparency", 1)
	setp(NG1157, "BorderSizePixel", 0)
	setp(NG1157, "Name", "Background")
	NG1157.Selectable = false
	setp(NG1157, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1157, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1157, "Parent", NG1155)
	NG1158 = Instance.new("Frame")
	setp(NG1158, "BackgroundColor3", Color3.new(0, 1, 0))
	setp(NG1158, "BorderSizePixel", 0)
	setp(NG1158, "Name", "SelectedIndicator")
	setp(NG1158, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1158, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1158, "Parent", NG1155)
	NG1159 = Instance.new("TextBox")
	setp(NG1159, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1159, "BackgroundTransparency", 1)
	setp(NG1159, "BorderSizePixel", 0)
	setp(NG1159, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1159, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1159, "Font", Enum.Font.ArialBold)
	setp(NG1159, "FontSize", Enum.FontSize.Size10)
	setp(NG1159, "Text", "255")
	setp(NG1159, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1159, "Parent", NG1155)
	NG1160 = Instance.new("Frame")
	setp(NG1160, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1160, "BackgroundTransparency", 1)
	setp(NG1160, "BorderSizePixel", 0)
	setp(NG1160, "Name", "BInput")
	setp(NG1160, "Position", UDim2.new(0, 109, 0, 0))
	setp(NG1160, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1160, "Parent", NG1148)
	NG1161 = Instance.new("TextButton")
	setp(NG1161, "Active", true)
	setp(NG1161, "AutoButtonColor", false)
	setp(NG1161, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1161, "BackgroundTransparency", 1)
	setp(NG1161, "BorderSizePixel", 0)
	NG1161.Selectable = true
	setp(NG1161, "Size", UDim2.new(1, 0, 1, 0))
	NG1161.Style = Enum.ButtonStyle.Custom
	setp(NG1161, "ZIndex", 2)
	setp(NG1161, "Font", Enum.Font.Legacy)
	setp(NG1161, "FontSize", Enum.FontSize.Size8)
	setp(NG1161, "Text", "")
	setp(NG1161, "Parent", NG1160)
	NG1162 = Instance.new("ImageLabel")
	setp(NG1162, "Active", false)
	setp(NG1162, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1162, "BackgroundTransparency", 1)
	setp(NG1162, "BorderSizePixel", 0)
	setp(NG1162, "Name", "Background")
	NG1162.Selectable = false
	setp(NG1162, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1162, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1162, "Parent", NG1160)
	NG1163 = Instance.new("Frame")
	setp(NG1163, "BackgroundColor3", Color3.new(0, 0, 1))
	setp(NG1163, "BorderSizePixel", 0)
	setp(NG1163, "Name", "SelectedIndicator")
	setp(NG1163, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1163, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1163, "Parent", NG1160)
	NG1164 = Instance.new("TextBox")
	setp(NG1164, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1164, "BackgroundTransparency", 1)
	setp(NG1164, "BorderSizePixel", 0)
	setp(NG1164, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1164, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1164, "Font", Enum.Font.ArialBold)
	setp(NG1164, "FontSize", Enum.FontSize.Size10)
	setp(NG1164, "Text", "255")
	setp(NG1164, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1164, "Parent", NG1160)
	NG1165 = Instance.new("ImageButton")
	setp(NG1165, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1165, "BackgroundTransparency", 0.40000000596046)
	setp(NG1165, "BorderSizePixel", 0)
	setp(NG1165, "Name", "HSVPicker")
	setp(NG1165, "Position", UDim2.new(0, 160, 0, -2))
	setp(NG1165, "Size", UDim2.new(0, 27, 0, 27))
	NG1165.Style = Enum.ButtonStyle.Custom
	setp(NG1165, "ZIndex", 2)
	setp(NG1165, "Image", "http://www.roblox.com/asset/?id=141313631")
	setp(NG1165, "Parent", NG1148)
	NG1166 = Instance.new("Frame")
	setp(NG1166, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1166, "BackgroundTransparency", 0.75)
	setp(NG1166, "BorderSizePixel", 0)
	setp(NG1166, "Name", "Shadow")
	setp(NG1166, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG1166, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG1166, "Parent", NG1165)
	NG1167 = Instance.new("Frame")
	setp(NG1167, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1167, "BackgroundTransparency", 0.5)
	setp(NG1167, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1167, "BorderSizePixel", 0)
	setp(NG1167, "Name", "Separator")
	setp(NG1167, "Position", UDim2.new(0, 151, 0, 4))
	setp(NG1167, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1167, "Parent", NG1148)
	NG1168 = Instance.new("Frame")
	setp(NG1168, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1168, "BackgroundTransparency", 0.5)
	setp(NG1168, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1168, "BorderSizePixel", 0)
	setp(NG1168, "Name", "Separator")
	setp(NG1168, "Position", UDim2.new(0, 151, 0, 16))
	setp(NG1168, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1168, "Parent", NG1148)
	NG1169 = Instance.new("Frame")
	setp(NG1169, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1169, "BackgroundTransparency", 0.5)
	setp(NG1169, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1169, "BorderSizePixel", 0)
	setp(NG1169, "Name", "Separator")
	setp(NG1169, "Position", UDim2.new(0, 151, 0, 10))
	setp(NG1169, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1169, "Parent", NG1148)
	NG1170 = Instance.new("Frame")
	setp(NG1170, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1170, "BackgroundTransparency", 1)
	setp(NG1170, "BorderSizePixel", 0)
	setp(NG1170, "Name", "HeatOption")
	setp(NG1170, "Position", UDim2.new(0, 0, 0, 80))
	setp(NG1170, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG1170, "Parent", NG1147)
	NG1171 = Instance.new("TextLabel")
	setp(NG1171, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1171, "BackgroundTransparency", 1)
	setp(NG1171, "BorderSizePixel", 0)
	setp(NG1171, "Name", "Label")
	setp(NG1171, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG1171, "Font", Enum.Font.ArialBold)
	setp(NG1171, "FontSize", Enum.FontSize.Size10)
	setp(NG1171, "Text", "Heat")
	setp(NG1171, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1171, "TextStrokeTransparency", 0)
	setp(NG1171, "TextWrapped", true)
	setp(NG1171, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1171, "Parent", NG1170)
	NG1172 = Instance.new("Frame")
	setp(NG1172, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1172, "BackgroundTransparency", 1)
	setp(NG1172, "BorderSizePixel", 0)
	setp(NG1172, "Name", "Input")
	setp(NG1172, "Position", UDim2.new(0, 34, 0, 0))
	setp(NG1172, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1172, "Parent", NG1170)
	NG1173 = Instance.new("TextButton")
	setp(NG1173, "Active", true)
	setp(NG1173, "AutoButtonColor", false)
	setp(NG1173, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1173, "BackgroundTransparency", 1)
	setp(NG1173, "BorderSizePixel", 0)
	NG1173.Selectable = true
	setp(NG1173, "Size", UDim2.new(1, 0, 1, 0))
	NG1173.Style = Enum.ButtonStyle.Custom
	setp(NG1173, "ZIndex", 2)
	setp(NG1173, "Font", Enum.Font.Legacy)
	setp(NG1173, "FontSize", Enum.FontSize.Size8)
	setp(NG1173, "Text", "")
	setp(NG1173, "Parent", NG1172)
	NG1174 = Instance.new("ImageLabel")
	setp(NG1174, "Active", false)
	setp(NG1174, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1174, "BackgroundTransparency", 1)
	setp(NG1174, "BorderSizePixel", 0)
	setp(NG1174, "Name", "Background")
	NG1174.Selectable = false
	setp(NG1174, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1174, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1174, "Parent", NG1172)
	NG1175 = Instance.new("Frame")
	setp(NG1175, "BorderSizePixel", 0)
	setp(NG1175, "Name", "SelectedIndicator")
	setp(NG1175, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1175, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1175, "Parent", NG1172)
	NG1176 = Instance.new("TextBox")
	setp(NG1176, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1176, "BackgroundTransparency", 1)
	setp(NG1176, "BorderSizePixel", 0)
	setp(NG1176, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1176, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1176, "Font", Enum.Font.ArialBold)
	setp(NG1176, "FontSize", Enum.FontSize.Size10)
	setp(NG1176, "Text", "1")
	setp(NG1176, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1176, "Parent", NG1172)
	NG1177 = Instance.new("Frame")
	setp(NG1177, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1177, "BackgroundTransparency", 1)
	setp(NG1177, "BorderSizePixel", 0)
	setp(NG1177, "Name", "SizeOption")
	setp(NG1177, "Position", UDim2.new(0, 90, 0, 80))
	setp(NG1177, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG1177, "Parent", NG1147)
	NG1178 = Instance.new("TextLabel")
	setp(NG1178, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1178, "BackgroundTransparency", 1)
	setp(NG1178, "BorderSizePixel", 0)
	setp(NG1178, "Name", "Label")
	setp(NG1178, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG1178, "Font", Enum.Font.ArialBold)
	setp(NG1178, "FontSize", Enum.FontSize.Size10)
	setp(NG1178, "Text", "Size")
	setp(NG1178, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1178, "TextStrokeTransparency", 0)
	setp(NG1178, "TextWrapped", true)
	setp(NG1178, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1178, "Parent", NG1177)
	NG1179 = Instance.new("Frame")
	setp(NG1179, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1179, "BackgroundTransparency", 1)
	setp(NG1179, "BorderSizePixel", 0)
	setp(NG1179, "Name", "Input")
	setp(NG1179, "Position", UDim2.new(0, 30, 0, 0))
	setp(NG1179, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1179, "Parent", NG1177)
	NG1180 = Instance.new("TextButton")
	setp(NG1180, "Active", true)
	setp(NG1180, "AutoButtonColor", false)
	setp(NG1180, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1180, "BackgroundTransparency", 1)
	setp(NG1180, "BorderSizePixel", 0)
	NG1180.Selectable = true
	setp(NG1180, "Size", UDim2.new(1, 0, 1, 0))
	NG1180.Style = Enum.ButtonStyle.Custom
	setp(NG1180, "ZIndex", 2)
	setp(NG1180, "Font", Enum.Font.Legacy)
	setp(NG1180, "FontSize", Enum.FontSize.Size8)
	setp(NG1180, "Text", "")
	setp(NG1180, "Parent", NG1179)
	NG1181 = Instance.new("ImageLabel")
	setp(NG1181, "Active", false)
	setp(NG1181, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1181, "BackgroundTransparency", 1)
	setp(NG1181, "BorderSizePixel", 0)
	setp(NG1181, "Name", "Background")
	NG1181.Selectable = false
	setp(NG1181, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1181, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1181, "Parent", NG1179)
	NG1182 = Instance.new("Frame")
	setp(NG1182, "BorderSizePixel", 0)
	setp(NG1182, "Name", "SelectedIndicator")
	setp(NG1182, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1182, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1182, "Parent", NG1179)
	NG1183 = Instance.new("TextBox")
	setp(NG1183, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1183, "BackgroundTransparency", 1)
	setp(NG1183, "BorderSizePixel", 0)
	setp(NG1183, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1183, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1183, "Font", Enum.Font.ArialBold)
	setp(NG1183, "FontSize", Enum.FontSize.Size10)
	setp(NG1183, "Text", "16")
	setp(NG1183, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1183, "Parent", NG1179)
	NG1184 = Instance.new("Frame")
	setp(NG1184, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1184, "BackgroundTransparency", 1)
	setp(NG1184, "BorderSizePixel", 0)
	setp(NG1184, "Name", "SecondColorOption")
	setp(NG1184, "Position", UDim2.new(0, 0, 0, 45))
	setp(NG1184, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG1184, "Parent", NG1147)
	NG1185 = Instance.new("TextLabel")
	setp(NG1185, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1185, "BackgroundTransparency", 1)
	setp(NG1185, "BorderSizePixel", 0)
	setp(NG1185, "Name", "Label")
	setp(NG1185, "Size", UDim2.new(0, 40, 0, 25))
	setp(NG1185, "Font", Enum.Font.ArialBold)
	setp(NG1185, "FontSize", Enum.FontSize.Size10)
	setp(NG1185, "Text", "2nd Color")
	setp(NG1185, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1185, "TextStrokeTransparency", 0)
	setp(NG1185, "TextWrapped", true)
	setp(NG1185, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1185, "Parent", NG1184)
	NG1186 = Instance.new("Frame")
	setp(NG1186, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1186, "BackgroundTransparency", 1)
	setp(NG1186, "BorderSizePixel", 0)
	setp(NG1186, "Name", "RInput")
	setp(NG1186, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG1186, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1186, "Parent", NG1184)
	NG1187 = Instance.new("TextButton")
	setp(NG1187, "Active", true)
	setp(NG1187, "AutoButtonColor", false)
	setp(NG1187, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1187, "BackgroundTransparency", 1)
	setp(NG1187, "BorderSizePixel", 0)
	NG1187.Selectable = true
	setp(NG1187, "Size", UDim2.new(1, 0, 1, 0))
	NG1187.Style = Enum.ButtonStyle.Custom
	setp(NG1187, "ZIndex", 2)
	setp(NG1187, "Font", Enum.Font.Legacy)
	setp(NG1187, "FontSize", Enum.FontSize.Size8)
	setp(NG1187, "Text", "")
	setp(NG1187, "Parent", NG1186)
	NG1188 = Instance.new("ImageLabel")
	setp(NG1188, "Active", false)
	setp(NG1188, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1188, "BackgroundTransparency", 1)
	setp(NG1188, "BorderSizePixel", 0)
	setp(NG1188, "Name", "Background")
	NG1188.Selectable = false
	setp(NG1188, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1188, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1188, "Parent", NG1186)
	NG1189 = Instance.new("Frame")
	setp(NG1189, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG1189, "BorderSizePixel", 0)
	setp(NG1189, "Name", "SelectedIndicator")
	setp(NG1189, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1189, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1189, "Parent", NG1186)
	NG1190 = Instance.new("TextBox")
	setp(NG1190, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1190, "BackgroundTransparency", 1)
	setp(NG1190, "BorderSizePixel", 0)
	setp(NG1190, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1190, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1190, "Font", Enum.Font.ArialBold)
	setp(NG1190, "FontSize", Enum.FontSize.Size10)
	setp(NG1190, "Text", "255")
	setp(NG1190, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1190, "Parent", NG1186)
	NG1191 = Instance.new("Frame")
	setp(NG1191, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1191, "BackgroundTransparency", 1)
	setp(NG1191, "BorderSizePixel", 0)
	setp(NG1191, "Name", "GInput")
	setp(NG1191, "Position", UDim2.new(0, 72, 0, 0))
	setp(NG1191, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1191, "Parent", NG1184)
	NG1192 = Instance.new("TextButton")
	setp(NG1192, "Active", true)
	setp(NG1192, "AutoButtonColor", false)
	setp(NG1192, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1192, "BackgroundTransparency", 1)
	setp(NG1192, "BorderSizePixel", 0)
	NG1192.Selectable = true
	setp(NG1192, "Size", UDim2.new(1, 0, 1, 0))
	NG1192.Style = Enum.ButtonStyle.Custom
	setp(NG1192, "ZIndex", 2)
	setp(NG1192, "Font", Enum.Font.Legacy)
	setp(NG1192, "FontSize", Enum.FontSize.Size8)
	setp(NG1192, "Text", "")
	setp(NG1192, "Parent", NG1191)
	NG1193 = Instance.new("ImageLabel")
	setp(NG1193, "Active", false)
	setp(NG1193, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1193, "BackgroundTransparency", 1)
	setp(NG1193, "BorderSizePixel", 0)
	setp(NG1193, "Name", "Background")
	NG1193.Selectable = false
	setp(NG1193, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1193, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1193, "Parent", NG1191)
	NG1194 = Instance.new("Frame")
	setp(NG1194, "BackgroundColor3", Color3.new(0, 1, 0))
	setp(NG1194, "BorderSizePixel", 0)
	setp(NG1194, "Name", "SelectedIndicator")
	setp(NG1194, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1194, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1194, "Parent", NG1191)
	NG1195 = Instance.new("TextBox")
	setp(NG1195, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1195, "BackgroundTransparency", 1)
	setp(NG1195, "BorderSizePixel", 0)
	setp(NG1195, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1195, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1195, "Font", Enum.Font.ArialBold)
	setp(NG1195, "FontSize", Enum.FontSize.Size10)
	setp(NG1195, "Text", "255")
	setp(NG1195, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1195, "Parent", NG1191)
	NG1196 = Instance.new("Frame")
	setp(NG1196, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1196, "BackgroundTransparency", 1)
	setp(NG1196, "BorderSizePixel", 0)
	setp(NG1196, "Name", "BInput")
	setp(NG1196, "Position", UDim2.new(0, 109, 0, 0))
	setp(NG1196, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1196, "Parent", NG1184)
	NG1197 = Instance.new("TextButton")
	setp(NG1197, "Active", true)
	setp(NG1197, "AutoButtonColor", false)
	setp(NG1197, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1197, "BackgroundTransparency", 1)
	setp(NG1197, "BorderSizePixel", 0)
	NG1197.Selectable = true
	setp(NG1197, "Size", UDim2.new(1, 0, 1, 0))
	NG1197.Style = Enum.ButtonStyle.Custom
	setp(NG1197, "ZIndex", 2)
	setp(NG1197, "Font", Enum.Font.Legacy)
	setp(NG1197, "FontSize", Enum.FontSize.Size8)
	setp(NG1197, "Text", "")
	setp(NG1197, "Parent", NG1196)
	NG1198 = Instance.new("ImageLabel")
	setp(NG1198, "Active", false)
	setp(NG1198, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1198, "BackgroundTransparency", 1)
	setp(NG1198, "BorderSizePixel", 0)
	setp(NG1198, "Name", "Background")
	NG1198.Selectable = false
	setp(NG1198, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1198, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1198, "Parent", NG1196)
	NG1199 = Instance.new("Frame")
	setp(NG1199, "BackgroundColor3", Color3.new(0, 0, 1))
	setp(NG1199, "BorderSizePixel", 0)
	setp(NG1199, "Name", "SelectedIndicator")
	setp(NG1199, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1199, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1199, "Parent", NG1196)
	NG1200 = Instance.new("TextBox")
	setp(NG1200, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1200, "BackgroundTransparency", 1)
	setp(NG1200, "BorderSizePixel", 0)
	setp(NG1200, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1200, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1200, "Font", Enum.Font.ArialBold)
	setp(NG1200, "FontSize", Enum.FontSize.Size10)
	setp(NG1200, "Text", "255")
	setp(NG1200, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1200, "Parent", NG1196)
	NG1201 = Instance.new("ImageButton")
	setp(NG1201, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1201, "BackgroundTransparency", 0.40000000596046)
	setp(NG1201, "BorderSizePixel", 0)
	setp(NG1201, "Name", "HSVPicker")
	setp(NG1201, "Position", UDim2.new(0, 160, 0, -2))
	setp(NG1201, "Size", UDim2.new(0, 27, 0, 27))
	NG1201.Style = Enum.ButtonStyle.Custom
	setp(NG1201, "ZIndex", 2)
	setp(NG1201, "Image", "http://www.roblox.com/asset/?id=141313631")
	setp(NG1201, "Parent", NG1184)
	NG1202 = Instance.new("Frame")
	setp(NG1202, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1202, "BackgroundTransparency", 0.75)
	setp(NG1202, "BorderSizePixel", 0)
	setp(NG1202, "Name", "Shadow")
	setp(NG1202, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG1202, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG1202, "Parent", NG1201)
	NG1203 = Instance.new("Frame")
	setp(NG1203, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1203, "BackgroundTransparency", 0.5)
	setp(NG1203, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1203, "BorderSizePixel", 0)
	setp(NG1203, "Name", "Separator")
	setp(NG1203, "Position", UDim2.new(0, 151, 0, 4))
	setp(NG1203, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1203, "Parent", NG1184)
	NG1204 = Instance.new("Frame")
	setp(NG1204, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1204, "BackgroundTransparency", 0.5)
	setp(NG1204, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1204, "BorderSizePixel", 0)
	setp(NG1204, "Name", "Separator")
	setp(NG1204, "Position", UDim2.new(0, 151, 0, 16))
	setp(NG1204, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1204, "Parent", NG1184)
	NG1205 = Instance.new("Frame")
	setp(NG1205, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1205, "BackgroundTransparency", 0.5)
	setp(NG1205, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1205, "BorderSizePixel", 0)
	setp(NG1205, "Name", "Separator")
	setp(NG1205, "Position", UDim2.new(0, 151, 0, 10))
	setp(NG1205, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1205, "Parent", NG1184)
	NG1206 = Instance.new("Frame")
	setp(NG1206, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1206, "BackgroundTransparency", 0.67500001192093)
	setp(NG1206, "BorderSizePixel", 0)
	setp(NG1206, "Name", "Sparkles")
	setp(NG1206, "Position", UDim2.new(0, 10, 0, 90))
	setp(NG1206, "Size", UDim2.new(1, -10, 0, 25))
	setp(NG1206, "Parent", NG1082)
	NG1207 = Instance.new("TextLabel")
	setp(NG1207, "BackgroundTransparency", 1)
	setp(NG1207, "BorderSizePixel", 0)
	setp(NG1207, "Name", "Label")
	setp(NG1207, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG1207, "Size", UDim2.new(0, 60, 0, 25))
	setp(NG1207, "Font", Enum.Font.ArialBold)
	setp(NG1207, "FontSize", Enum.FontSize.Size10)
	setp(NG1207, "Text", "Sparkles")
	setp(NG1207, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1207, "TextStrokeTransparency", 0.5)
	setp(NG1207, "TextWrapped", true)
	setp(NG1207, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1207, "Parent", NG1206)
	NG1208 = Instance.new("ImageButton")
	setp(NG1208, "BackgroundTransparency", 1)
	setp(NG1208, "BorderSizePixel", 0)
	setp(NG1208, "Name", "ArrowButton")
	setp(NG1208, "Position", UDim2.new(0, 10, 0, 3))
	setp(NG1208, "Size", UDim2.new(0, 20, 0, 20))
	NG1208.Style = Enum.ButtonStyle.Custom
	setp(NG1208, "Image", "http://www.roblox.com/asset/?id=134367382")
	setp(NG1208, "Parent", NG1206)
	NG1209 = Instance.new("Frame")
	setp(NG1209, "BackgroundColor3", Color3.new(0.0196078, 0.396078, 1))
	setp(NG1209, "BorderSizePixel", 0)
	setp(NG1209, "Name", "ColorBar")
	setp(NG1209, "Size", UDim2.new(0, 3, 1, 0))
	setp(NG1209, "Parent", NG1206)
	NG1210 = Instance.new("TextButton")
	setp(NG1210, "Active", true)
	setp(NG1210, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1210, "BackgroundTransparency", 0.75)
	setp(NG1210, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG1210, "BorderSizePixel", 0)
	setp(NG1210, "Name", "AddButton")
	setp(NG1210, "Position", UDim2.new(1, -40, 0, 3))
	NG1210.Selectable = true
	setp(NG1210, "Size", UDim2.new(0, 35, 0, 19))
	NG1210.Style = Enum.ButtonStyle.Custom
	setp(NG1210, "ZIndex", 2)
	setp(NG1210, "Font", Enum.Font.ArialBold)
	setp(NG1210, "FontSize", Enum.FontSize.Size10)
	setp(NG1210, "Text", "ADD")
	setp(NG1210, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1210, "Parent", NG1206)
	NG1211 = Instance.new("TextButton")
	setp(NG1211, "Active", true)
	setp(NG1211, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1211, "BackgroundTransparency", 0.75)
	setp(NG1211, "BorderColor3", Color3.new(0, 0, 0))
	setp(NG1211, "BorderSizePixel", 0)
	setp(NG1211, "Name", "RemoveButton")
	setp(NG1211, "Position", UDim2.new(0, 90, 0, 3))
	NG1211.Selectable = true
	setp(NG1211, "Size", UDim2.new(0, 58, 0, 19))
	NG1211.Style = Enum.ButtonStyle.Custom
	setp(NG1211, "Visible", false)
	setp(NG1211, "ZIndex", 2)
	setp(NG1211, "Font", Enum.Font.ArialBold)
	setp(NG1211, "FontSize", Enum.FontSize.Size10)
	setp(NG1211, "Text", "REMOVE")
	setp(NG1211, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1211, "Parent", NG1206)
	NG1212 = Instance.new("Frame")
	setp(NG1212, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1212, "BackgroundTransparency", 0.75)
	setp(NG1212, "BorderSizePixel", 0)
	setp(NG1212, "Name", "Shadow")
	setp(NG1212, "Position", UDim2.new(0, 0, 1, -1))
	setp(NG1212, "Size", UDim2.new(1, 0, 0, 1))
	setp(NG1212, "Parent", NG1206)
	NG1213 = Instance.new("Frame")
	setp(NG1213, "BackgroundTransparency", 1)
	setp(NG1213, "BorderSizePixel", 0)
	setp(NG1213, "Name", "Options")
	setp(NG1213, "Position", UDim2.new(0, 3, 1, 0))
	setp(NG1213, "Size", UDim2.new(1, -3, 0, 0))
	setp(NG1213, "ClipsDescendants", true)
	setp(NG1213, "Parent", NG1206)
	NG1214 = Instance.new("Frame")
	setp(NG1214, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1214, "BackgroundTransparency", 1)
	setp(NG1214, "BorderSizePixel", 0)
	setp(NG1214, "Name", "ColorOption")
	setp(NG1214, "Position", UDim2.new(0, 0, 0, 10))
	setp(NG1214, "Size", UDim2.new(1, 0, 0, 25))
	setp(NG1214, "Parent", NG1213)
	NG1215 = Instance.new("TextLabel")
	setp(NG1215, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1215, "BackgroundTransparency", 1)
	setp(NG1215, "BorderSizePixel", 0)
	setp(NG1215, "Name", "Label")
	setp(NG1215, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG1215, "Font", Enum.Font.ArialBold)
	setp(NG1215, "FontSize", Enum.FontSize.Size10)
	setp(NG1215, "Text", "Color")
	setp(NG1215, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1215, "TextStrokeTransparency", 0)
	setp(NG1215, "TextWrapped", true)
	setp(NG1215, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1215, "Parent", NG1214)
	NG1216 = Instance.new("Frame")
	setp(NG1216, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1216, "BackgroundTransparency", 1)
	setp(NG1216, "BorderSizePixel", 0)
	setp(NG1216, "Name", "RInput")
	setp(NG1216, "Position", UDim2.new(0, 35, 0, 0))
	setp(NG1216, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1216, "Parent", NG1214)
	NG1217 = Instance.new("TextButton")
	setp(NG1217, "Active", true)
	setp(NG1217, "AutoButtonColor", false)
	setp(NG1217, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1217, "BackgroundTransparency", 1)
	setp(NG1217, "BorderSizePixel", 0)
	NG1217.Selectable = true
	setp(NG1217, "Size", UDim2.new(1, 0, 1, 0))
	NG1217.Style = Enum.ButtonStyle.Custom
	setp(NG1217, "ZIndex", 2)
	setp(NG1217, "Font", Enum.Font.Legacy)
	setp(NG1217, "FontSize", Enum.FontSize.Size8)
	setp(NG1217, "Text", "")
	setp(NG1217, "Parent", NG1216)
	NG1218 = Instance.new("ImageLabel")
	setp(NG1218, "Active", false)
	setp(NG1218, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1218, "BackgroundTransparency", 1)
	setp(NG1218, "BorderSizePixel", 0)
	setp(NG1218, "Name", "Background")
	NG1218.Selectable = false
	setp(NG1218, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1218, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1218, "Parent", NG1216)
	NG1219 = Instance.new("Frame")
	setp(NG1219, "BackgroundColor3", Color3.new(1, 0, 0))
	setp(NG1219, "BorderSizePixel", 0)
	setp(NG1219, "Name", "SelectedIndicator")
	setp(NG1219, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1219, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1219, "Parent", NG1216)
	NG1220 = Instance.new("TextBox")
	setp(NG1220, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1220, "BackgroundTransparency", 1)
	setp(NG1220, "BorderSizePixel", 0)
	setp(NG1220, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1220, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1220, "Font", Enum.Font.ArialBold)
	setp(NG1220, "FontSize", Enum.FontSize.Size10)
	setp(NG1220, "Text", "255")
	setp(NG1220, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1220, "Parent", NG1216)
	NG1221 = Instance.new("Frame")
	setp(NG1221, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1221, "BackgroundTransparency", 1)
	setp(NG1221, "BorderSizePixel", 0)
	setp(NG1221, "Name", "GInput")
	setp(NG1221, "Position", UDim2.new(0, 72, 0, 0))
	setp(NG1221, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1221, "Parent", NG1214)
	NG1222 = Instance.new("TextButton")
	setp(NG1222, "Active", true)
	setp(NG1222, "AutoButtonColor", false)
	setp(NG1222, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1222, "BackgroundTransparency", 1)
	setp(NG1222, "BorderSizePixel", 0)
	NG1222.Selectable = true
	setp(NG1222, "Size", UDim2.new(1, 0, 1, 0))
	NG1222.Style = Enum.ButtonStyle.Custom
	setp(NG1222, "ZIndex", 2)
	setp(NG1222, "Font", Enum.Font.Legacy)
	setp(NG1222, "FontSize", Enum.FontSize.Size8)
	setp(NG1222, "Text", "")
	setp(NG1222, "Parent", NG1221)
	NG1223 = Instance.new("ImageLabel")
	setp(NG1223, "Active", false)
	setp(NG1223, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1223, "BackgroundTransparency", 1)
	setp(NG1223, "BorderSizePixel", 0)
	setp(NG1223, "Name", "Background")
	NG1223.Selectable = false
	setp(NG1223, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1223, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1223, "Parent", NG1221)
	NG1224 = Instance.new("Frame")
	setp(NG1224, "BackgroundColor3", Color3.new(0, 1, 0))
	setp(NG1224, "BorderSizePixel", 0)
	setp(NG1224, "Name", "SelectedIndicator")
	setp(NG1224, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1224, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1224, "Parent", NG1221)
	NG1225 = Instance.new("TextBox")
	setp(NG1225, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1225, "BackgroundTransparency", 1)
	setp(NG1225, "BorderSizePixel", 0)
	setp(NG1225, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1225, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1225, "Font", Enum.Font.ArialBold)
	setp(NG1225, "FontSize", Enum.FontSize.Size10)
	setp(NG1225, "Text", "255")
	setp(NG1225, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1225, "Parent", NG1221)
	NG1226 = Instance.new("Frame")
	setp(NG1226, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1226, "BackgroundTransparency", 1)
	setp(NG1226, "BorderSizePixel", 0)
	setp(NG1226, "Name", "BInput")
	setp(NG1226, "Position", UDim2.new(0, 109, 0, 0))
	setp(NG1226, "Size", UDim2.new(0, 38, 0, 25))
	setp(NG1226, "Parent", NG1214)
	NG1227 = Instance.new("TextButton")
	setp(NG1227, "Active", true)
	setp(NG1227, "AutoButtonColor", false)
	setp(NG1227, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1227, "BackgroundTransparency", 1)
	setp(NG1227, "BorderSizePixel", 0)
	NG1227.Selectable = true
	setp(NG1227, "Size", UDim2.new(1, 0, 1, 0))
	NG1227.Style = Enum.ButtonStyle.Custom
	setp(NG1227, "ZIndex", 2)
	setp(NG1227, "Font", Enum.Font.Legacy)
	setp(NG1227, "FontSize", Enum.FontSize.Size8)
	setp(NG1227, "Text", "")
	setp(NG1227, "Parent", NG1226)
	NG1228 = Instance.new("ImageLabel")
	setp(NG1228, "Active", false)
	setp(NG1228, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1228, "BackgroundTransparency", 1)
	setp(NG1228, "BorderSizePixel", 0)
	setp(NG1228, "Name", "Background")
	NG1228.Selectable = false
	setp(NG1228, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1228, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1228, "Parent", NG1226)
	NG1229 = Instance.new("Frame")
	setp(NG1229, "BackgroundColor3", Color3.new(0, 0, 1))
	setp(NG1229, "BorderSizePixel", 0)
	setp(NG1229, "Name", "SelectedIndicator")
	setp(NG1229, "Position", UDim2.new(0, 3, 0, -2))
	setp(NG1229, "Size", UDim2.new(1, -3, 0, 2))
	setp(NG1229, "Parent", NG1226)
	NG1230 = Instance.new("TextBox")
	setp(NG1230, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1230, "BackgroundTransparency", 1)
	setp(NG1230, "BorderSizePixel", 0)
	setp(NG1230, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1230, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1230, "Font", Enum.Font.ArialBold)
	setp(NG1230, "FontSize", Enum.FontSize.Size10)
	setp(NG1230, "Text", "255")
	setp(NG1230, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1230, "Parent", NG1226)
	NG1231 = Instance.new("ImageButton")
	setp(NG1231, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1231, "BackgroundTransparency", 0.40000000596046)
	setp(NG1231, "BorderSizePixel", 0)
	setp(NG1231, "Name", "HSVPicker")
	setp(NG1231, "Position", UDim2.new(0, 160, 0, -2))
	setp(NG1231, "Size", UDim2.new(0, 27, 0, 27))
	NG1231.Style = Enum.ButtonStyle.Custom
	setp(NG1231, "ZIndex", 2)
	setp(NG1231, "Image", "http://www.roblox.com/asset/?id=141313631")
	setp(NG1231, "Parent", NG1214)
	NG1232 = Instance.new("Frame")
	setp(NG1232, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1232, "BackgroundTransparency", 0.75)
	setp(NG1232, "BorderSizePixel", 0)
	setp(NG1232, "Name", "Shadow")
	setp(NG1232, "Position", UDim2.new(0, 0, 1, -2))
	setp(NG1232, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG1232, "Parent", NG1231)
	NG1233 = Instance.new("Frame")
	setp(NG1233, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1233, "BackgroundTransparency", 0.5)
	setp(NG1233, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1233, "BorderSizePixel", 0)
	setp(NG1233, "Name", "Separator")
	setp(NG1233, "Position", UDim2.new(0, 151, 0, 4))
	setp(NG1233, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1233, "Parent", NG1214)
	NG1234 = Instance.new("Frame")
	setp(NG1234, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1234, "BackgroundTransparency", 0.5)
	setp(NG1234, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1234, "BorderSizePixel", 0)
	setp(NG1234, "Name", "Separator")
	setp(NG1234, "Position", UDim2.new(0, 151, 0, 16))
	setp(NG1234, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1234, "Parent", NG1214)
	NG1235 = Instance.new("Frame")
	setp(NG1235, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(NG1235, "BackgroundTransparency", 0.5)
	setp(NG1235, "BorderColor3", Color3.new(0.380392, 0.380392, 0.380392))
	setp(NG1235, "BorderSizePixel", 0)
	setp(NG1235, "Name", "Separator")
	setp(NG1235, "Position", UDim2.new(0, 151, 0, 10))
	setp(NG1235, "Size", UDim2.new(0, 4, 0, 4))
	setp(NG1235, "Parent", NG1214)
	NG1236 = Instance.new("Frame")
	setp(NG1236, "Active", true)
	setp(NG1236, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1236, "BackgroundTransparency", 1)
	setp(NG1236, "BorderSizePixel", 0)
	setp(NG1236, "Name", "BTRotateToolGUI")
	setp(NG1236, "Position", UDim2.new(0, 0, 0, 280))
	setp(NG1236, "Size", UDim2.new(0, 245, 0, 90))
	NG1236.Draggable = true
	setp(NG1236, "Parent", NG1)
	NG1237 = Instance.new("Frame")
	setp(NG1237, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1237, "BackgroundTransparency", 1)
	setp(NG1237, "BorderSizePixel", 0)
	setp(NG1237, "Name", "PivotOption")
	setp(NG1237, "Position", UDim2.new(0, 0, 0, 30))
	setp(NG1237, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG1237, "Parent", NG1236)
	NG1238 = Instance.new("Frame")
	setp(NG1238, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1238, "BackgroundTransparency", 1)
	setp(NG1238, "BorderSizePixel", 0)
	setp(NG1238, "Name", "Center")
	setp(NG1238, "Position", UDim2.new(0, 50, 0, 0))
	setp(NG1238, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG1238, "Parent", NG1237)
	NG1239 = Instance.new("Frame")
	setp(NG1239, "BorderSizePixel", 0)
	setp(NG1239, "Name", "SelectedIndicator")
	setp(NG1239, "Position", UDim2.new(0, 6, 0, -2))
	setp(NG1239, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG1239, "Parent", NG1238)
	NG1240 = Instance.new("TextButton")
	setp(NG1240, "Active", true)
	setp(NG1240, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1240, "BackgroundTransparency", 1)
	setp(NG1240, "BorderSizePixel", 0)
	setp(NG1240, "Name", "Button")
	setp(NG1240, "Position", UDim2.new(0, 5, 0, 0))
	NG1240.Selectable = true
	setp(NG1240, "Size", UDim2.new(1, -10, 1, 0))
	NG1240.Style = Enum.ButtonStyle.Custom
	setp(NG1240, "ZIndex", 2)
	setp(NG1240, "Font", Enum.Font.Legacy)
	setp(NG1240, "FontSize", Enum.FontSize.Size8)
	setp(NG1240, "Text", "")
	NG1240.TextTransparency = 1
	setp(NG1240, "Parent", NG1238)
	NG1241 = Instance.new("ImageLabel")
	setp(NG1241, "Active", false)
	setp(NG1241, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1241, "BackgroundTransparency", 1)
	setp(NG1241, "BorderSizePixel", 0)
	setp(NG1241, "Name", "Background")
	NG1241.Selectable = false
	setp(NG1241, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1241, "Image", "http://www.roblox.com/asset/?id=127774197")
	setp(NG1241, "Parent", NG1238)
	NG1242 = Instance.new("TextLabel")
	setp(NG1242, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1242, "BackgroundTransparency", 1)
	setp(NG1242, "BorderSizePixel", 0)
	setp(NG1242, "Name", "Label")
	setp(NG1242, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1242, "Font", Enum.Font.ArialBold)
	setp(NG1242, "FontSize", Enum.FontSize.Size10)
	setp(NG1242, "Text", "CENTER")
	setp(NG1242, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1242, "Parent", NG1238)
	NG1243 = Instance.new("Frame")
	setp(NG1243, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1243, "BackgroundTransparency", 1)
	setp(NG1243, "BorderSizePixel", 0)
	setp(NG1243, "Name", "Local")
	setp(NG1243, "Position", UDim2.new(0, 115, 0, 0))
	setp(NG1243, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG1243, "Parent", NG1237)
	NG1244 = Instance.new("Frame")
	setp(NG1244, "BackgroundTransparency", 1)
	setp(NG1244, "BorderSizePixel", 0)
	setp(NG1244, "Name", "SelectedIndicator")
	setp(NG1244, "Position", UDim2.new(0, 6, 0, -2))
	setp(NG1244, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG1244, "Parent", NG1243)
	NG1245 = Instance.new("TextButton")
	setp(NG1245, "Active", true)
	setp(NG1245, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1245, "BackgroundTransparency", 1)
	setp(NG1245, "BorderSizePixel", 0)
	setp(NG1245, "Name", "Button")
	setp(NG1245, "Position", UDim2.new(0, 5, 0, 0))
	NG1245.Selectable = true
	setp(NG1245, "Size", UDim2.new(1, -10, 1, 0))
	NG1245.Style = Enum.ButtonStyle.Custom
	setp(NG1245, "ZIndex", 2)
	setp(NG1245, "Font", Enum.Font.Legacy)
	setp(NG1245, "FontSize", Enum.FontSize.Size8)
	setp(NG1245, "Text", "")
	NG1245.TextTransparency = 1
	setp(NG1245, "Parent", NG1243)
	NG1246 = Instance.new("ImageLabel")
	setp(NG1246, "Active", false)
	setp(NG1246, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1246, "BackgroundTransparency", 1)
	setp(NG1246, "BorderSizePixel", 0)
	setp(NG1246, "Name", "Background")
	NG1246.Selectable = false
	setp(NG1246, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1246, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1246, "Parent", NG1243)
	NG1247 = Instance.new("TextLabel")
	setp(NG1247, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1247, "BackgroundTransparency", 1)
	setp(NG1247, "BorderSizePixel", 0)
	setp(NG1247, "Name", "Label")
	setp(NG1247, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1247, "Font", Enum.Font.ArialBold)
	setp(NG1247, "FontSize", Enum.FontSize.Size10)
	setp(NG1247, "Text", "LOCAL")
	setp(NG1247, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1247, "Parent", NG1243)
	NG1248 = Instance.new("Frame")
	setp(NG1248, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1248, "BackgroundTransparency", 1)
	setp(NG1248, "BorderSizePixel", 0)
	setp(NG1248, "Name", "Last")
	setp(NG1248, "Position", UDim2.new(0, 180, 0, 0))
	setp(NG1248, "Size", UDim2.new(0, 70, 0, 25))
	setp(NG1248, "Parent", NG1237)
	NG1249 = Instance.new("Frame")
	setp(NG1249, "BackgroundTransparency", 1)
	setp(NG1249, "BorderSizePixel", 0)
	setp(NG1249, "Name", "SelectedIndicator")
	setp(NG1249, "Position", UDim2.new(0, 6, 0, -2))
	setp(NG1249, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG1249, "Parent", NG1248)
	NG1250 = Instance.new("TextButton")
	setp(NG1250, "Active", true)
	setp(NG1250, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1250, "BackgroundTransparency", 1)
	setp(NG1250, "BorderSizePixel", 0)
	setp(NG1250, "Name", "Button")
	setp(NG1250, "Position", UDim2.new(0, 5, 0, 0))
	NG1250.Selectable = true
	setp(NG1250, "Size", UDim2.new(1, -10, 1, 0))
	NG1250.Style = Enum.ButtonStyle.Custom
	setp(NG1250, "ZIndex", 2)
	setp(NG1250, "Font", Enum.Font.Legacy)
	setp(NG1250, "FontSize", Enum.FontSize.Size8)
	setp(NG1250, "Text", "")
	NG1250.TextTransparency = 1
	setp(NG1250, "Parent", NG1248)
	NG1251 = Instance.new("ImageLabel")
	setp(NG1251, "Active", false)
	setp(NG1251, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1251, "BackgroundTransparency", 1)
	setp(NG1251, "BorderSizePixel", 0)
	setp(NG1251, "Name", "Background")
	NG1251.Selectable = false
	setp(NG1251, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1251, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1251, "Parent", NG1248)
	NG1252 = Instance.new("TextLabel")
	setp(NG1252, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1252, "BackgroundTransparency", 1)
	setp(NG1252, "BorderSizePixel", 0)
	setp(NG1252, "Name", "Label")
	setp(NG1252, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1252, "Font", Enum.Font.ArialBold)
	setp(NG1252, "FontSize", Enum.FontSize.Size10)
	setp(NG1252, "Text", "LAST")
	setp(NG1252, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1252, "Parent", NG1248)
	NG1253 = Instance.new("Frame")
	setp(NG1253, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1253, "BackgroundTransparency", 1)
	setp(NG1253, "BorderSizePixel", 0)
	setp(NG1253, "Name", "Label")
	setp(NG1253, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG1253, "Parent", NG1237)
	NG1254 = Instance.new("TextLabel")
	setp(NG1254, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1254, "BackgroundTransparency", 1)
	setp(NG1254, "BorderSizePixel", 0)
	setp(NG1254, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1254, "Font", Enum.Font.ArialBold)
	setp(NG1254, "FontSize", Enum.FontSize.Size10)
	setp(NG1254, "Text", "Pivot")
	setp(NG1254, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1254, "TextStrokeTransparency", 0)
	setp(NG1254, "TextWrapped", true)
	setp(NG1254, "Parent", NG1253)
	NG1255 = Instance.new("Frame")
	setp(NG1255, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1255, "BackgroundTransparency", 1)
	setp(NG1255, "BorderSizePixel", 0)
	setp(NG1255, "Name", "Title")
	setp(NG1255, "Size", UDim2.new(1, 0, 0, 20))
	setp(NG1255, "Parent", NG1236)
	NG1256 = Instance.new("Frame")
	setp(NG1256, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG1256, "BorderSizePixel", 0)
	setp(NG1256, "Name", "ColorBar")
	setp(NG1256, "Position", UDim2.new(0, 5, 0, -3))
	setp(NG1256, "Size", UDim2.new(1, -5, 0, 2))
	setp(NG1256, "Parent", NG1255)
	NG1257 = Instance.new("TextLabel")
	setp(NG1257, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1257, "BackgroundTransparency", 1)
	setp(NG1257, "BorderSizePixel", 0)
	setp(NG1257, "Name", "Label")
	setp(NG1257, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG1257, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1257, "Font", Enum.Font.ArialBold)
	setp(NG1257, "FontSize", Enum.FontSize.Size10)
	setp(NG1257, "Text", "ROTATE TOOL")
	setp(NG1257, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1257, "TextStrokeTransparency", 0)
	setp(NG1257, "TextWrapped", true)
	setp(NG1257, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1257, "Parent", NG1255)
	NG1258 = Instance.new("TextLabel")
	setp(NG1258, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1258, "BackgroundTransparency", 1)
	setp(NG1258, "BorderSizePixel", 0)
	setp(NG1258, "Name", "F3XSignature")
	setp(NG1258, "Position", UDim2.new(0, 10, 0, 1))
	setp(NG1258, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1258, "Font", Enum.Font.ArialBold)
	setp(NG1258, "FontSize", Enum.FontSize.Size14)
	setp(NG1258, "Text", "F3X")
	setp(NG1258, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1258, "TextStrokeTransparency", 0.89999997615814)
	setp(NG1258, "TextWrapped", true)
	setp(NG1258, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG1258, "Parent", NG1255)
	NG1259 = Instance.new("Frame")
	setp(NG1259, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1259, "BackgroundTransparency", 1)
	setp(NG1259, "BorderSizePixel", 0)
	setp(NG1259, "Name", "IncrementOption")
	setp(NG1259, "Position", UDim2.new(0, 0, 0, 65))
	setp(NG1259, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG1259, "Parent", NG1236)
	NG1260 = Instance.new("Frame")
	setp(NG1260, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1260, "BackgroundTransparency", 1)
	setp(NG1260, "BorderSizePixel", 0)
	setp(NG1260, "Name", "Increment")
	setp(NG1260, "Position", UDim2.new(0, 70, 0, 0))
	setp(NG1260, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG1260, "Parent", NG1259)
	NG1261 = Instance.new("Frame")
	setp(NG1261, "BorderSizePixel", 0)
	setp(NG1261, "Name", "SelectedIndicator")
	setp(NG1261, "Position", UDim2.new(0, 5, 0, -2))
	setp(NG1261, "Size", UDim2.new(1, -4, 0, 2))
	setp(NG1261, "Parent", NG1260)
	NG1262 = Instance.new("TextBox")
	setp(NG1262, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1262, "BackgroundTransparency", 1)
	setp(NG1262, "BorderSizePixel", 0)
	setp(NG1262, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1262, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1262, "ZIndex", 2)
	setp(NG1262, "Font", Enum.Font.ArialBold)
	setp(NG1262, "FontSize", Enum.FontSize.Size10)
	setp(NG1262, "Text", "15")
	setp(NG1262, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1262, "Parent", NG1260)
	NG1263 = Instance.new("ImageLabel")
	setp(NG1263, "Active", false)
	setp(NG1263, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1263, "BackgroundTransparency", 1)
	setp(NG1263, "BorderSizePixel", 0)
	setp(NG1263, "Name", "Background")
	NG1263.Selectable = false
	setp(NG1263, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1263, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1263, "Parent", NG1260)
	NG1264 = Instance.new("Frame")
	setp(NG1264, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1264, "BackgroundTransparency", 1)
	setp(NG1264, "BorderSizePixel", 0)
	setp(NG1264, "Name", "Label")
	setp(NG1264, "Size", UDim2.new(0, 75, 0, 25))
	setp(NG1264, "Parent", NG1259)
	NG1265 = Instance.new("TextLabel")
	setp(NG1265, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1265, "BackgroundTransparency", 1)
	setp(NG1265, "BorderSizePixel", 0)
	setp(NG1265, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1265, "Font", Enum.Font.ArialBold)
	setp(NG1265, "FontSize", Enum.FontSize.Size10)
	setp(NG1265, "Text", "Increment")
	setp(NG1265, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1265, "TextStrokeTransparency", 0)
	setp(NG1265, "TextWrapped", true)
	setp(NG1265, "Parent", NG1264)
	NG1266 = Instance.new("Frame")
	setp(NG1266, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1266, "BackgroundTransparency", 1)
	setp(NG1266, "BorderSizePixel", 0)
	setp(NG1266, "Name", "Info")
	setp(NG1266, "Position", UDim2.new(0, 5, 0, 100))
	setp(NG1266, "Size", UDim2.new(1, -5, 0, 60))
	setp(NG1266, "Visible", false)
	setp(NG1266, "Parent", NG1236)
	NG1267 = Instance.new("Frame")
	setp(NG1267, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG1267, "BorderSizePixel", 0)
	setp(NG1267, "Name", "ColorBar")
	setp(NG1267, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG1267, "Parent", NG1266)
	NG1268 = Instance.new("TextLabel")
	setp(NG1268, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1268, "BackgroundTransparency", 1)
	setp(NG1268, "BorderSizePixel", 0)
	setp(NG1268, "Name", "Label")
	setp(NG1268, "Position", UDim2.new(0, 10, 0, 2))
	setp(NG1268, "Size", UDim2.new(1, -10, 0, 20))
	setp(NG1268, "Font", Enum.Font.ArialBold)
	setp(NG1268, "FontSize", Enum.FontSize.Size10)
	setp(NG1268, "Text", "SELECTION INFO")
	setp(NG1268, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1268, "TextStrokeTransparency", 0)
	setp(NG1268, "TextWrapped", true)
	setp(NG1268, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1268, "Parent", NG1266)
	NG1269 = Instance.new("Frame")
	setp(NG1269, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1269, "BackgroundTransparency", 1)
	setp(NG1269, "BorderSizePixel", 0)
	setp(NG1269, "Name", "RotationInfo")
	setp(NG1269, "Position", UDim2.new(0, 0, 0, 30))
	setp(NG1269, "Size", UDim2.new(0, 0, 0, 0))
	setp(NG1269, "Parent", NG1266)
	NG1270 = Instance.new("TextLabel")
	setp(NG1270, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1270, "BackgroundTransparency", 1)
	setp(NG1270, "BorderSizePixel", 0)
	setp(NG1270, "Size", UDim2.new(0, 75, 0, 25))
	setp(NG1270, "Font", Enum.Font.ArialBold)
	setp(NG1270, "FontSize", Enum.FontSize.Size10)
	setp(NG1270, "Text", "Rotation")
	setp(NG1270, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1270, "TextStrokeTransparency", 0)
	setp(NG1270, "TextWrapped", true)
	setp(NG1270, "Parent", NG1269)
	NG1271 = Instance.new("Frame")
	setp(NG1271, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1271, "BackgroundTransparency", 1)
	setp(NG1271, "BorderSizePixel", 0)
	setp(NG1271, "Name", "X")
	setp(NG1271, "Position", UDim2.new(0, 70, 0, 0))
	setp(NG1271, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG1271, "Parent", NG1269)
	NG1272 = Instance.new("TextBox")
	setp(NG1272, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1272, "BackgroundTransparency", 1)
	setp(NG1272, "BorderSizePixel", 0)
	setp(NG1272, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1272, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1272, "ZIndex", 2)
	setp(NG1272, "Font", Enum.Font.ArialBold)
	setp(NG1272, "FontSize", Enum.FontSize.Size10)
	setp(NG1272, "Text", "")
	setp(NG1272, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1272, "Parent", NG1271)
	NG1273 = Instance.new("TextButton")
	setp(NG1273, "Active", true)
	setp(NG1273, "AutoButtonColor", false)
	setp(NG1273, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1273, "BackgroundTransparency", 1)
	setp(NG1273, "BorderSizePixel", 0)
	NG1273.Selectable = true
	setp(NG1273, "Size", UDim2.new(1, 0, 1, 0))
	NG1273.Style = Enum.ButtonStyle.Custom
	setp(NG1273, "ZIndex", 3)
	setp(NG1273, "Font", Enum.Font.Legacy)
	setp(NG1273, "FontSize", Enum.FontSize.Size8)
	setp(NG1273, "Text", "")
	setp(NG1273, "Parent", NG1271)
	NG1274 = Instance.new("ImageLabel")
	setp(NG1274, "Active", false)
	setp(NG1274, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1274, "BackgroundTransparency", 1)
	setp(NG1274, "BorderSizePixel", 0)
	setp(NG1274, "Name", "Background")
	NG1274.Selectable = false
	setp(NG1274, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1274, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1274, "Parent", NG1271)
	NG1275 = Instance.new("Frame")
	setp(NG1275, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1275, "BackgroundTransparency", 1)
	setp(NG1275, "BorderSizePixel", 0)
	setp(NG1275, "Name", "Y")
	setp(NG1275, "Position", UDim2.new(0, 117, 0, 0))
	setp(NG1275, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG1275, "Parent", NG1269)
	NG1276 = Instance.new("TextBox")
	setp(NG1276, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1276, "BackgroundTransparency", 1)
	setp(NG1276, "BorderSizePixel", 0)
	setp(NG1276, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1276, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1276, "ZIndex", 2)
	setp(NG1276, "Font", Enum.Font.ArialBold)
	setp(NG1276, "FontSize", Enum.FontSize.Size10)
	setp(NG1276, "Text", "")
	setp(NG1276, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1276, "Parent", NG1275)
	NG1277 = Instance.new("TextButton")
	setp(NG1277, "Active", true)
	setp(NG1277, "AutoButtonColor", false)
	setp(NG1277, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1277, "BackgroundTransparency", 1)
	setp(NG1277, "BorderSizePixel", 0)
	NG1277.Selectable = true
	setp(NG1277, "Size", UDim2.new(1, 0, 1, 0))
	NG1277.Style = Enum.ButtonStyle.Custom
	setp(NG1277, "ZIndex", 3)
	setp(NG1277, "Font", Enum.Font.Legacy)
	setp(NG1277, "FontSize", Enum.FontSize.Size8)
	setp(NG1277, "Text", "")
	setp(NG1277, "Parent", NG1275)
	NG1278 = Instance.new("ImageLabel")
	setp(NG1278, "Active", false)
	setp(NG1278, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1278, "BackgroundTransparency", 1)
	setp(NG1278, "BorderSizePixel", 0)
	setp(NG1278, "Name", "Background")
	NG1278.Selectable = false
	setp(NG1278, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1278, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1278, "Parent", NG1275)
	NG1279 = Instance.new("Frame")
	setp(NG1279, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1279, "BackgroundTransparency", 1)
	setp(NG1279, "BorderSizePixel", 0)
	setp(NG1279, "Name", "Z")
	setp(NG1279, "Position", UDim2.new(0, 164, 0, 0))
	setp(NG1279, "Size", UDim2.new(0, 50, 0, 25))
	setp(NG1279, "Parent", NG1269)
	NG1280 = Instance.new("TextBox")
	setp(NG1280, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1280, "BackgroundTransparency", 1)
	setp(NG1280, "BorderSizePixel", 0)
	setp(NG1280, "Position", UDim2.new(0, 5, 0, 0))
	setp(NG1280, "Size", UDim2.new(1, -10, 1, 0))
	setp(NG1280, "ZIndex", 2)
	setp(NG1280, "Font", Enum.Font.ArialBold)
	setp(NG1280, "FontSize", Enum.FontSize.Size10)
	setp(NG1280, "Text", "")
	setp(NG1280, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1280, "Parent", NG1279)
	NG1281 = Instance.new("TextButton")
	setp(NG1281, "Active", true)
	setp(NG1281, "AutoButtonColor", false)
	setp(NG1281, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1281, "BackgroundTransparency", 1)
	setp(NG1281, "BorderSizePixel", 0)
	NG1281.Selectable = true
	setp(NG1281, "Size", UDim2.new(1, 0, 1, 0))
	NG1281.Style = Enum.ButtonStyle.Custom
	setp(NG1281, "ZIndex", 3)
	setp(NG1281, "Font", Enum.Font.Legacy)
	setp(NG1281, "FontSize", Enum.FontSize.Size8)
	setp(NG1281, "Text", "")
	setp(NG1281, "Parent", NG1279)
	NG1282 = Instance.new("ImageLabel")
	setp(NG1282, "Active", false)
	setp(NG1282, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1282, "BackgroundTransparency", 1)
	setp(NG1282, "BorderSizePixel", 0)
	setp(NG1282, "Name", "Background")
	NG1282.Selectable = false
	setp(NG1282, "Size", UDim2.new(1, 0, 1, 0))
	setp(NG1282, "Image", "http://www.roblox.com/asset/?id=127772502")
	setp(NG1282, "Parent", NG1279)
	NG1283 = Instance.new("Frame")
	setp(NG1283, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1283, "BackgroundTransparency", 1)
	setp(NG1283, "BorderSizePixel", 0)
	setp(NG1283, "Name", "Changes")
	setp(NG1283, "Position", UDim2.new(0, 5, 0, 100))
	setp(NG1283, "Size", UDim2.new(1, -5, 0, 20))
	setp(NG1283, "Parent", NG1236)
	NG1284 = Instance.new("Frame")
	setp(NG1284, "BackgroundColor3", Color3.new(0.294118, 0.592157, 0.294118))
	setp(NG1284, "BorderSizePixel", 0)
	setp(NG1284, "Name", "ColorBar")
	setp(NG1284, "Size", UDim2.new(1, 0, 0, 2))
	setp(NG1284, "Parent", NG1283)
	NG1285 = Instance.new("TextLabel")
	setp(NG1285, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1285, "BackgroundTransparency", 1)
	setp(NG1285, "BorderSizePixel", 0)
	setp(NG1285, "Name", "Text")
	setp(NG1285, "Position", UDim2.new(0, 10, 0, 2))
	setp(NG1285, "Size", UDim2.new(1, -10, 0, 20))
	setp(NG1285, "Font", Enum.Font.ArialBold)
	setp(NG1285, "FontSize", Enum.FontSize.Size10)
	setp(NG1285, "Text", "rotated 0 degrees")
	setp(NG1285, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1285, "TextStrokeTransparency", 0.5)
	setp(NG1285, "TextWrapped", true)
	setp(NG1285, "TextXAlignment", Enum.TextXAlignment.Right)
	setp(NG1285, "Parent", NG1283)
	NG1286 = Instance.new("TextLabel")
	setp(NG1286, "BackgroundColor3", Color3.new(0.639216, 0.635294, 0.647059))
	setp(NG1286, "BackgroundTransparency", 1)
	setp(NG1286, "BorderSizePixel", 0)
	setp(NG1286, "Name", "EdgeSelectionTip")
	setp(NG1286, "Position", UDim2.new(0, 10, 0, 2))
	setp(NG1286, "Size", UDim2.new(1, -10, 0, 20))
	setp(NG1286, "Font", Enum.Font.ArialBold)
	setp(NG1286, "FontSize", Enum.FontSize.Size10)
	setp(NG1286, "Text", "Press T for edge selection.")
	setp(NG1286, "TextColor3", Color3.new(1, 1, 1))
	setp(NG1286, "TextStrokeTransparency", 0.5)
	setp(NG1286, "TextWrapped", true)
	setp(NG1286, "TextXAlignment", Enum.TextXAlignment.Left)
	setp(NG1286, "Parent", NG1283)
	DFb100j = NG1
end
task.wait(0.1)
ActiveKeys = {}
CurrentTool = nil
function equipTool(Enu)
	if not Enu then
		F3XWarn("equipTool called without a tool")
		return
	end
	if CurrentTool ~= Enu then
		if CurrentTool and CurrentTool.Listeners.Unequipped then
			local okUnequip, errUnequip = xpcall(CurrentTool.Listeners.Unequipped, F3XTraceback)
			if not okUnequip then
				F3XWarn("Tool unequip listener failed: " .. tostring(errUnequip))
			end
		end
		if CurrentTool and CurrentTool.Connections and type(_G.cleanCons) == "function" then
			_G.cleanCons(CurrentTool.Connections)
		end
		CurrentTool = Enu
		if ToolType == "tool" then
			Tool.Handle.BrickColor = Enu.Color
		end
		for fChy5, DNPo4Wqt in pairs(Dock.ToolButtons:GetChildren()) do
			setp(DNPo4Wqt, "BackgroundTransparency", 1)
		end
		local YJ31A6_ = Dock.ToolButtons:FindFirstChild(getToolName(Enu) .. "Button")
		if YJ31A6_ then
			setp(YJ31A6_, "BackgroundTransparency", 0)
		end
		if Enu.Listeners.Equipped then
			local okEquip, errEquip = xpcall(Enu.Listeners.Equipped, F3XTraceback)
			if not okEquip then
				F3XWarn("Tool equip listener failed for " .. tostring(getToolName(Enu)) .. ": " .. tostring(errEquip))
			end
		end
	end
end
function cloneSelection()
	if #Selection.Items > 0 then
		local S8Kb = {}
		for P32, xj1 in pairs(Selection.Items) do
			local rd = xj1:Clone()
			setp(rd, "Parent", Workspace)
			table.insert(S8Kb, rd)
		end
		Selection:clear()
		for wtX, Y in pairs(S8Kb) do
			Selection:add(Y)
		end
		local UMeQ = {
			copies = S8Kb,
			unapply = function(EHSv)
				for Ati7Oq, Tqo2jko in pairs(EHSv.copies) do
					if Tqo2jko then
						setp(Tqo2jko, "Parent", nil)
					end
				end
			end,
			apply = function(uJz)
				Selection:clear()
				for qVvlt, aGkESg in pairs(uJz.copies) do
					if aGkESg then
						setp(aGkESg, "Parent", Workspace)
						aGkESg:MakeJoints()
						Selection:add(aGkESg)
					end
				end
			end,
		}
		History:add(UMeQ)
		local AGhdl3 = (RbxUtility.Create("Sound"))({
			Name = "BTActionCompletionSound",
			Pitch = 1.5,
			SoundId = Assets.ActionCompletionSound,
			Volume = 1,
			Parent = Player or SoundService,
		})
		AGhdl3:Play()
		AGhdl3:Destroy();
		(coroutine.wrap(function()
			for KXnNMI7S = 1, 0.5, -0.1 do
				for fL, Oj in pairs(SelectionBoxes) do
					setp(Oj, "Transparency", KXnNMI7S)
				end
				task.wait(0.1)
			end
		end))()
	end
end
function deleteSelection()
	if #Selection.Items == 0 then
		return
	end
	local pGR0Ig = Support.CloneTable(Selection.Items)
	local bBq = {
		targets = pGR0Ig,
		parents = {},
		apply = function(i)
			for yCkt, irs579 in pairs(i.targets) do
				if irs579 then
					setp(irs579, "Parent", nil)
				end
			end
		end,
		unapply = function(ptD)
			Selection:clear()
			for mj_P, w in pairs(ptD.targets) do
				if w then
					setp(w, "Parent", ptD.parents[w])
					w:MakeJoints()
					Selection:add(w)
				end
			end
		end,
	}
	for Nge6L, aWnFL1 in pairs(pGR0Ig) do
		bBq.parents[aWnFL1] = aWnFL1.Parent
		setp(aWnFL1, "Parent", nil)
	end
	History:add(bBq)
end
function prismSelect()
	if #Selection.Items == 0 then
		return
	end
	local D = {}
	local R = {}
	local u51 = Support.GetAllDescendants(Workspace)
	for WSlpP, xSMd in pairs(u51) do
		if xSMd:IsA("BasePart") and (not Selection:find(xSMd)) then
			table.insert(R, xSMd)
		end
	end
	local O0NUxa = {}
	for vYmD9ed, Cez in pairs(R) do
		O0NUxa[Cez] = 0
		for vYmD9ed, NvSMm in pairs(Selection.Items) do
			local wRpQf = NvSMm.CFrame:toObjectSpace(Cez.CFrame)
			local ed9P = NvSMm.Size / 2
			if math.abs(wRpQf.x) <= ed9P.x and math.abs(wRpQf.y) <= ed9P.y and math.abs(wRpQf.z) <= ed9P.z then
				O0NUxa[Cez] = O0NUxa[Cez] + 1
			end
		end
	end
	local RngfRQ6g = Support.CloneTable(Selection.Items)
	local F = {}
	for NJ5, bpAJ in pairs(RngfRQ6g) do
		F[bpAJ] = bpAJ.Parent
		setp(bpAJ, "Parent", nil)
	end
	for UdPyHc, SciVUxEq in pairs(R) do
		if O0NUxa[SciVUxEq] > 0 then
			Selection:add(SciVUxEq)
		end
	end
	History:add({
		selection_parts = RngfRQ6g,
		selection_part_parents = F,
		new_selection = Support.CloneTable(Selection.Items),
		apply = function(Te)
			Selection:clear()
			for WN, f in pairs(Te.selection_parts) do
				setp(f, "Parent", nil)
			end
			for FleDs3, LP in pairs(Te.new_selection) do
				Selection:add(LP)
			end
		end,
		unapply = function(RLovoVo)
			Selection:clear()
			for Je6Srpf8, p in pairs(RLovoVo.selection_parts) do
				setp(p, "Parent", RLovoVo.selection_part_parents[p])
				Selection:add(p)
			end
		end,
	})
end
function toggleHelp()
	if not Dock then
		return
	end
	setp(Dock.HelpInfo, "Visible", not Dock.HelpInfo.Visible)
end
function getToolName(Z0RFr5F)
	local _Myb = Support.FindTableOccurrences(Tools, Z0RFr5F)
	if #_Myb > 0 then
		return _Myb[1]
	end
end
function isSelectable(Zq)
	if
		not Zq
		or not Zq.Parent
		or (not Zq:IsA("BasePart"))
		or Selection:find(Zq)
		or Groups:IsPartIgnored(Zq)
	then
		return false
	end
	return true
end
function isSelectionTarget(Zq)
	if not Zq or not Zq.Parent or (not Zq:IsA("BasePart")) or Groups:IsPartIgnored(Zq) then
		return false
	end
	return true
end
function getSelectionPointerPosition(input)
	if input and input.Position then
		return Vector2.new(input.Position.X, input.Position.Y)
	end
	if Mouse then
		return Vector2.new(Mouse.X, Mouse.Y)
	end
end
function raycastSelectionTargetAt(pointerPosition)
	if not pointerPosition then
		return Mouse and Mouse.Target or nil
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return Mouse and Mouse.Target or nil
	end
	local okRay, ray = pcall(function()
		return camera:ScreenPointToRay(pointerPosition.X, pointerPosition.Y)
	end)
	if not okRay or not ray then
		okRay, ray = pcall(function()
			return camera:ViewportPointToRay(pointerPosition.X, pointerPosition.Y)
		end)
	end
	if not okRay or not ray then
		return Mouse and Mouse.Target or nil
	end
	local ignoreList = {}
	if Player and Player.Character then
		table.insert(ignoreList, Player.Character)
	end
	if Mouse and Mouse.TargetFilter then
		table.insert(ignoreList, Mouse.TargetFilter)
	end
	local hitPart = nil
	local usedModernRaycast = false
	if Workspace.Raycast and RaycastParams then
		local okCast, result = pcall(function()
			local params = RaycastParams.new()
			local okFilter = pcall(function()
				params.FilterType = Enum.RaycastFilterType.Exclude
			end)
			if not okFilter then
				pcall(function()
					params.FilterType = Enum.RaycastFilterType.Blacklist
				end)
			end
			params.FilterDescendantsInstances = ignoreList
			return Workspace:Raycast(ray.Origin, ray.Direction * 10000, params)
		end)
		usedModernRaycast = okCast
		if okCast and result then
			hitPart = result.Instance
		end
	end
	if not usedModernRaycast and Workspace.FindPartOnRayWithIgnoreList then
		local legacyRay = Ray.new(ray.Origin, ray.Direction * 10000)
		local okLegacy, legacyHit = pcall(function()
			return Workspace:FindPartOnRayWithIgnoreList(legacyRay, ignoreList, false, true)
		end)
		if okLegacy then
			hitPart = legacyHit
		end
	end
	return hitPart or (Mouse and Mouse.Target) or nil
end
function getSelectionTarget(input)
	local target = raycastSelectionTargetAt(getSelectionPointerPosition(input))
	if isSelectionTarget(target) then
		return target
	end
	if Mouse and isSelectionTarget(Mouse.Target) then
		return Mouse.Target
	end
	return target
end
function isGuiVisibleDeep(obj)
	local cur = obj
	while cur and cur ~= UI do
		if cur:IsA("GuiObject") and not cur.Visible then
			return false
		end
		cur = cur.Parent
	end
	return true
end
function isPointerOverBTUI(input)
	local p = getSelectionPointerPosition(input)
	if not p or not UI then
		return false
	end
	for _, obj in pairs(UI:GetDescendants()) do
		if obj:IsA("GuiObject") and obj.Name ~= "Rectangle" and isGuiVisibleDeep(obj) then
			local pos = obj.AbsolutePosition
			local size = obj.AbsoluteSize
			if size.X > 0 and size.Y > 0 and p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y then
				return true
			end
		end
	end
	return false
end
function setMobileMultiSelect(v)
	mobile_multi_select = v == true
	if MobileMultiButton then
		setp(MobileMultiButton, "Text", mobile_multi_select and "MULTI\nON" or "MULTI\nOFF")
		setp(MobileMultiButton, "BackgroundTransparency", mobile_multi_select and 0.15 or 0.55)
		setp(MobileMultiButton, "TextColor3", mobile_multi_select and Color3.new(0.5, 1, 0.5) or Color3.new(1, 1, 1))
	end
end
function updateSelectionTargetBox(input)
	if override_selection or not TargetBox then
		return
	end
	local target = getSelectionTarget(input)
	if isSelectable(target) then
		if TargetBox.Adornee ~= target then
			setp(TargetBox, "Adornee", target)
		end
	else
		setp(TargetBox, "Adornee", nil)
	end
end
function applyPointerSelection(input, touchMode)
	local pointerPosition = getSelectionPointerPosition(input)
	local target = getSelectionTarget(input)
	local dragThreshold = touchMode and 10 or 0
	local moved = false
	if pointerPosition then
		moved = math.abs(pointerPosition.X - click_x) > dragThreshold or math.abs(pointerPosition.Y - click_y) > dragThreshold
	end
	if not Select2D.enabled and moved then
		override_selection = true
	end
	local addMode = selecting or (touchMode and mobile_multi_select)
	if not override_selection and touchMode and not addMode then
		Selection:clear()
		if isSelectable(target) then
			Selection:add(target)
		end
	elseif not override_selection and not addMode and (not isSelectionTarget(target)) then
		Selection:clear()
	elseif not override_selection and addMode then
		if not Selection:find(target) then
			if isSelectable(target) then
				Selection:add(target)
			end
		elseif not moved and Selection:find(target) then
			Selection:remove(target)
		end
	elseif not override_selection and isSelectable(target) then
		Selection:clear()
		Selection:add(target)
	end
	if override_selection then
		override_selection = false
	end
end
function IsVersionOutdated()
	return VersionOutdated == true
end
VersionOutdated = false
VersionCheckError = nil
F3XConfig = type(F3XConfig) == "table" and F3XConfig or {}
F3XConfig.CheckUpdates = F3XConfig.CheckUpdates == true
F3XConfig.AllowHTTP = F3XConfig.AllowHTTP == true
function RefreshVersionStatusAsync()
	if not F3XConfig.CheckUpdates then
		VersionOutdated = false
		VersionCheckError = "disabled"
		return
	end
	F3XSpawn(function()
		local TKS = nil
		local okHttp, s2 = xpcall(function()
			return HttpInterface.GetAsync("https://api.roblox.com/marketplace/productinfo?assetId=" .. tostring(ToolAssetID), true)
		end, F3XTraceback)
		if okHttp and s2 then
			pcall(function()
				TKS = HttpService:JSONDecode(s2)
			end)
		end
		if not TKS then
			local r1nt, fx9 = xpcall(function()
				return MarketplaceService:GetProductInfo(ToolAssetID, Enum.InfoType.Asset)
			end, F3XTraceback)
			if r1nt then
				TKS = fx9
			else
				VersionCheckError = fx9
			end
		end
		if not TKS or not TKS.Description then
			VersionOutdated = false
			VersionCheckError = VersionCheckError or "missing product info description"
			F3XWarn("Version check failed: " .. tostring(VersionCheckError))
			return
		end
		local DUSiwPZm = TKS.Description:match("%[Version: (.+)%]")
		local QSjpjN5 = "1.4.5"
		VersionOutdated = DUSiwPZm ~= QSjpjN5
	end)
end
function RefreshHttpAvailabilityAsync()
	if not F3XConfig.AllowHTTP then
		HttpAvailable = false
		HttpAvailabilityError = "disabled"
		return
	end
	F3XSpawn(function()
		local Ygca, qJm8n, uAGRi = xpcall(function()
			return HttpInterface.Test()
		end, F3XTraceback)
		if Ygca then
			HttpAvailable = qJm8n and true or false
			HttpAvailabilityError = uAGRi
		else
			HttpAvailable = false
			HttpAvailabilityError = qJm8n
		end
	end)
end
HttpAvailable, HttpAvailabilityError = false, nil
if ToolType == "plugin" then
	HttpService.Changed:Connect(function()
		RefreshHttpAvailabilityAsync()
	end)
end
local XL_ = false
function ShowStartupNotifications()
	if XL_ then
		return
	end
	XL_ = true
	local M3ptD1Cf = DFb100j.BTStartupNotificationContainer:Clone()
	setp(M3ptD1Cf.WelcomeFex, "Visible", true)
	if not HttpAvailable and HttpAvailabilityError == "Http requests are not enabled" then
		setp(M3ptD1Cf.HttpDisabledWarning, "Visible", true)
	end
	if not HttpAvailable and HttpAvailabilityError == "Http requests can only be executed by game server" then
		setp(M3ptD1Cf.SoloWarning, "Visible", true)
	end
	if HttpAvailable then
		setp(M3ptD1Cf.HttpEnabledWarning, "Visible", true)
	end
	if IsVersionOutdated() then
		if ToolType == "tool" then
			setp(M3ptD1Cf.ToolUpdateNotification, "Visible", true)
		elseif ToolType == "plugin" then
			setp(M3ptD1Cf.PluginUpdateNotification, "Visible", true)
		end
	end
	local function B()
		local d = 0
		local z0 = M3ptD1Cf:GetChildren()
		for I_bHR9bD, YJha in pairs(z0) do
			YJha.Position =
				UDim2.new(YJha.Position.X.Scale, YJha.Position.X.Offset, YJha.Position.Y.Scale, d == 0 and 0 or d + 10)
			local g9QyV = YJha.Position.Y.Offset + YJha.Size.Y.Offset
			if YJha.Visible and g9QyV > d then
				d = g9QyV
			end
		end
		setp(M3ptD1Cf, "Size", UDim2.new(M3ptD1Cf.Size.X.Scale, M3ptD1Cf.Size.X.Offset, 0, d))
	end
	B()
	local jv = (UI.AbsoluteSize.x - M3ptD1Cf.Size.X.Offset) / 2
	local oTpq = UI.AbsoluteSize.y + M3ptD1Cf.Size.Y.Offset
	setp(M3ptD1Cf, "Position", UDim2.new(0, jv, 0, oTpq))
	setp(M3ptD1Cf, "Parent", UI)
	local function CjPV()
		local An_hQ3m = (UI.AbsoluteSize.y - M3ptD1Cf.Size.Y.Offset) / 2
		M3ptD1Cf:TweenPosition(UDim2.new(0, jv, 0, An_hQ3m), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2)
	end
	CjPV()
	for S, eMj5b1DD in pairs(M3ptD1Cf:GetChildren()) do
		if eMj5b1DD.Visible then
			eMj5b1DD.OKButton.MouseButton1Click:Connect(function()
				eMj5b1DD:Destroy()
				B()
				CjPV()
			end)
			eMj5b1DD.HelpButton.MouseButton1Click:Connect(function()
				eMj5b1DD.HelpButton:Destroy()
				eMj5b1DD.ButtonSeparator:Destroy()
				eMj5b1DD.OKButton:TweenSize(
					UDim2.new(1, 0, 0, 22),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.2
				)
				eMj5b1DD.Notice:Destroy()
				setp(eMj5b1DD.Help, "Visible", true)
				eMj5b1DD:TweenSize(
					UDim2.new(
						eMj5b1DD.Size.X.Scale,
						eMj5b1DD.Size.X.Offset,
						eMj5b1DD.Size.Y.Scale,
						eMj5b1DD.Help.NotificationSize.Value
					),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.2,
					true,
					function()
						B()
						CjPV()
					end
				)
			end)
		end
	end
	if ToolType == "tool" then
		Tool.Unequipped:Connect(function()
			if M3ptD1Cf.Visible then
				setp(M3ptD1Cf, "Visible", false)
				M3ptD1Cf:Destroy()
			end
		end)
	end
end
clicking = false
selecting = false
click_x, click_y = 0, 0
override_selection = false
touch_selection_input = nil
touch_selection_start = nil
last_touch_selection_time = 0
mobile_multi_select = false
MobileMultiButton = nil
SelectionBoxes = {}
SelectionExistenceListeners = {}
SelectionBoxColor = BrickColor.new("Cyan")
TargetBox = nil
Connections = {}
UI = (RbxUtility.Create("ScreenGui"))({
	Name = "Building Tools by F3X (UI)",
})
pcall(function()
	setp(UI, "ResetOnSpawn", false)
	setp(UI, "IgnoreGuiInset", true)
	setp(UI, "ZIndexBehavior", Enum.ZIndexBehavior.Sibling)
end)
UI = LTProtectUI(UI, {
	name = "Building Tools by F3X (UI)",
	keepName = true,
	harden = true,
	deep = true,
	watch = true,
	rename = false,
}) or UI
if not UI.Parent then
	if ToolType == "tool" then
		setp(UI, "Parent", GUIContainer)
	elseif ToolType == "plugin" then
		setp(UI, "Parent", CoreGui)
	end
end
BTMobileUI = {
	DragFrames = {},
	Connections = {},
	ScaledRoot = nil,
	LastViewport = Vector2.new(0, 0),
	Scale = 1,
}
pcall(function()
	BTMobileUI.ScaledRoot = Instance.new("UIScale")
	setp(BTMobileUI.ScaledRoot, "Name", "BTResponsiveScale")
	setp(BTMobileUI.ScaledRoot, "Scale", 1)
	setp(BTMobileUI.ScaledRoot, "Parent", UI)
end)
function BTMobileUI:getViewport()
	local aD = Workspace.CurrentCamera
	if aD then
		return aD.ViewportSize
	end
	return UI.AbsoluteSize
end
function BTMobileUI:updateScale()
	local o9ax = self:getViewport()
	if o9ax.x <= 0 or o9ax.y <= 0 then
		return
	end
	local W9pAZ = math.min(o9ax.x / 460, o9ax.y / 420, 1)
	if UserInputService.TouchEnabled or o9ax.x < 700 or o9ax.y < 420 then
		W9pAZ = math.min(W9pAZ, 0.86)
	end
	W9pAZ = math.max(W9pAZ, 0.65)
	if not self.ScaledRoot then
		W9pAZ = 1
	end
	setp(self, "Scale", W9pAZ)
	if self.ScaledRoot then
		setp(self.ScaledRoot, "Scale", W9pAZ)
	end
	self.LastViewport = o9ax
end
function BTMobileUI:clampFrame(ocU)
	if not ocU or not ocU.Parent or not ocU:IsA("GuiObject") then
		return
	end
	local tMl3 = self:getViewport()
	local rC = self.Scale > 0 and self.Scale or 1
	local i8s = tMl3.x / rC
	local j6 = tMl3.y / rC
	local pG7 = ocU.AbsoluteSize.x / rC
	local cU8 = ocU.AbsoluteSize.y / rC
	if i8s <= 0 or j6 <= 0 then
		return
	end
	local aP = ocU.AnchorPoint or Vector2.new(0, 0)
	local cP = ocU.Position
	local aX = cP.X.Scale * i8s + cP.X.Offset
	local aY = cP.Y.Scale * j6 + cP.Y.Offset
	local minX = aP.X * pG7
	local maxX = i8s - (1 - aP.X) * pG7
	local minY = aP.Y * cU8
	local maxY = j6 - (1 - aP.Y) * cU8
	if maxX < minX then
		maxX = minX
	end
	if maxY < minY then
		maxY = minY
	end
	local n7J = math.max(minX, math.min(aX, maxX))
	local zB2 = math.max(minY, math.min(aY, maxY))
	setp(ocU, "Position", UDim2.new(n7J / i8s, 0, zB2 / j6, 0))
end
function BTMobileUI:clampAll()
	for EN, _ in pairs(self.DragFrames) do
		self:clampFrame(EN)
	end
end
function BTMobileUI:cleanupDrag(Frame)
	local Cd = self.Connections[Frame]
	if Cd then
		for i, C in pairs(Cd) do
			pcall(function()
				C:Disconnect()
			end)
			Cd[i] = nil
		end
	end
	self.Connections[Frame] = nil
	self.DragFrames[Frame] = nil
end
function BTMobileUI:addDrag(Frame)
	if self.DragFrames[Frame] or not Frame:IsA("GuiObject") then
		return
	end
	self.DragFrames[Frame] = true
	self.Connections[Frame] = {}
	setp(Frame, "Active", true)
	pcall(function()
		Frame.Draggable = false
	end)
	local Gx = Frame:FindFirstChild("Title") or Frame
	local dragging = false
	local dragStart = nil
	local startPos = nil
	local dragPointer = nil
	local pendingInput = nil
	local function addConnection(C)
		table.insert(self.Connections[Frame], C)
		return C
	end
	local function stopDrag()
		dragging = false
		dragPointer = nil
		pendingInput = nil
		self:clampFrame(Frame)
	end
	local function update(input)
		if not dragging or not input then
			return
		end
		local tMl3 = self:getViewport()
		local rC = self.Scale > 0 and self.Scale or 1
		local i8s = tMl3.x / rC
		local j6 = tMl3.y / rC
		if i8s <= 0 or j6 <= 0 then
			return
		end
		local pG7 = Frame.AbsoluteSize.x / rC
		local cU8 = Frame.AbsoluteSize.y / rC
		local aP = Frame.AnchorPoint or Vector2.new(0, 0)
		local sX = startPos.X.Scale * i8s + startPos.X.Offset
		local sY = startPos.Y.Scale * j6 + startPos.Y.Offset
		local dX = (input.Position.X - dragStart.X) / rC
		local dY = (input.Position.Y - dragStart.Y) / rC
		local minX = aP.X * pG7
		local maxX = i8s - (1 - aP.X) * pG7
		local minY = aP.Y * cU8
		local maxY = j6 - (1 - aP.Y) * cU8
		if maxX < minX then
			maxX = minX
		end
		if maxY < minY then
			maxY = minY
		end
		local nX = math.max(minX, math.min(sX + dX, maxX))
		local nY = math.max(minY, math.min(sY + dY, maxY))
		setp(Frame, "Position", UDim2.new(nX / i8s, 0, nY / j6, 0))
	end
	addConnection(Gx.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		dragPointer = input
		dragStart = input.Position
		startPos = Frame.Position
	end))
	addConnection(UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			pendingInput = input
		elseif input.UserInputType == Enum.UserInputType.Touch and input == dragPointer then
			pendingInput = input
		end
	end))
	addConnection(UserInputService.InputEnded:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or (input.UserInputType == Enum.UserInputType.Touch and input == dragPointer) then
			stopDrag()
		end
	end))
	addConnection(RunService.RenderStepped:Connect(function()
		local frameInput = pendingInput
		if not frameInput then
			return
		end
		pendingInput = nil
		update(frameInput)
	end))
	addConnection(UI:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:clampFrame(Frame)
	end))
	addConnection(Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:clampFrame(Frame)
	end))
	addConnection(Frame.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:cleanupDrag(Frame)
		end
	end))
	self:clampFrame(Frame)
end
function BTMobileUI:watchFrame(Frame)
	if not Frame:IsA("GuiObject") then
		return
	end
	if Frame.Parent == UI and (Frame:FindFirstChild("Title") or Frame.Active) then
		self:addDrag(Frame)
	end
	Frame.ChildAdded:Connect(function(q7a)
		if q7a.Name == "Title" and Frame.Parent == UI then
			self:addDrag(Frame)
		end
	end)
end
UI.ChildAdded:Connect(function(S)
	BTMobileUI:updateScale()
	BTMobileUI:watchFrame(S)
end)
pcall(function()
	UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(function()
		BTMobileUI:updateScale()
	end)
end)
pcall(function()
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		BTMobileUI:updateScale()
	end)
end)
Dragger = nil
function updateSelectionBoxColor()
	for lDdmS, k1kp870h in pairs(SelectionBoxes) do
		k1kp870h.Color = SelectionBoxColor
	end
end
Selection = {
	Items = {},
	Changed = RbxUtility.CreateSignal(),
	ItemAdded = RbxUtility.CreateSignal(),
	ItemRemoved = RbxUtility.CreateSignal(),
	Cleared = RbxUtility.CreateSignal(),
	find = function(Xfv1_F, F74YQ)
		for SHlZ8Rw, FxP66 in pairs(Xfv1_F.Items) do
			if FxP66 == F74YQ then
				return SHlZ8Rw
			end
		end
	end,
	add = function(y, Ou)
		if not isSelectable(Ou) then
			return false
		end
		if #Support.FindTableOccurrences(y.Items, Ou) > 0 then
			return false
		end
		table.insert(y.Items, Ou)
		if ToolType == "tool" then
			SelectionBoxes[Ou] = Instance.new("SelectionBox", UI)
			SelectionBoxes[Ou].Name = "BTSelectionBox"
			SelectionBoxes[Ou].Color = SelectionBoxColor
			SelectionBoxes[Ou].Adornee = Ou
			SelectionBoxes[Ou].LineThickness = 0.05
			SelectionBoxes[Ou].Transparency = 0.5
		end
		if Ou == TargetBox.Adornee then
			setp(TargetBox, "Adornee", nil)
		end
		SelectionExistenceListeners[Ou] = Ou.AncestryChanged:Connect(function(AbN, lINgqxG1)
			if lINgqxG1 == nil then
				Selection:remove(Ou)
			end
		end)
		y:focus(Ou)
		y.ItemAdded:Fire(Ou)
		y.Changed:Fire()
	end,
	remove = function(Tz4j, vUctRT, ry0d9cxF)
		if not Tz4j:find(vUctRT) then
			return false
		end
		local fdMS0Bi = SelectionBoxes[vUctRT]
		if fdMS0Bi then
			fdMS0Bi:Destroy()
		end
		SelectionBoxes[vUctRT] = nil
		table.remove(Tz4j.Items, Tz4j:find(vUctRT))
		if Tz4j.Last == vUctRT then
			Tz4j:focus(#Tz4j.Items > 0 and Tz4j.Items[#Tz4j.Items] or nil)
		end
		SelectionExistenceListeners[vUctRT]:Disconnect()
		SelectionExistenceListeners[vUctRT] = nil
		Tz4j.ItemRemoved:Fire(vUctRT, ry0d9cxF)
		Tz4j.Changed:Fire()
	end,
	clear = function(jUfRhXXt)
		for bncqpLFj, c9P3 in pairs(Support.CloneTable(jUfRhXXt.Items)) do
			jUfRhXXt:remove(c9P3, true)
		end
		jUfRhXXt.Cleared:Fire()
	end,
	focus = function(D, A)
		D.Last = A
		D.Changed:Fire()
	end,
}
local WYdR = CFrame.new
local QKKks_zt = table.insert
local Are7xU = (CFrame.new()).toWorldSpace
local yxjl = math.min
local ZG = math.max
function calculateExtents(cO3SXQC, qiw, bQRP)
	local K5
	local M = 0
	for gm, jwJufiF in pairs(cO3SXQC) do
		M = M + 1
		K5 = jwJufiF
	end
	if M == 0 then
		return
	end
	local ZubW5sf = qiw and qiw.Minimum or K5.Position
	local VLlBaUgt = qiw and qiw.Maximum or K5.Position
	local QniH, j, x_BU2 = ZubW5sf.x, ZubW5sf.y, ZubW5sf.z
	local AFii, Au, fgK = VLlBaUgt.x, VLlBaUgt.y, VLlBaUgt.z
	for YogtAPf, q7h in pairs(cO3SXQC) do
		if not (q7h.Anchored and qiw) then
			local WS = q7h.CFrame
			local Uee8Une = q7h.Size / 2
			local UtI, L, qx27 = Uee8Une.x, Uee8Une.y, Uee8Une.z
			local whvO
			local kpbY, m_gHw, RFOr = {}, {}, {}
			whvO = Are7xU(WS, WYdR(UtI, L, qx27))
			QKKks_zt(kpbY, whvO.x)
			QKKks_zt(m_gHw, whvO.y)
			QKKks_zt(RFOr, whvO.z)
			whvO = Are7xU(WS, WYdR(-UtI, L, qx27))
			QKKks_zt(kpbY, whvO.x)
			QKKks_zt(m_gHw, whvO.y)
			QKKks_zt(RFOr, whvO.z)
			whvO = Are7xU(WS, WYdR(UtI, -L, qx27))
			QKKks_zt(kpbY, whvO.x)
			QKKks_zt(m_gHw, whvO.y)
			QKKks_zt(RFOr, whvO.z)
			whvO = Are7xU(WS, WYdR(UtI, L, -qx27))
			QKKks_zt(kpbY, whvO.x)
			QKKks_zt(m_gHw, whvO.y)
			QKKks_zt(RFOr, whvO.z)
			whvO = Are7xU(WS, WYdR(-UtI, L, -qx27))
			QKKks_zt(kpbY, whvO.x)
			QKKks_zt(m_gHw, whvO.y)
			QKKks_zt(RFOr, whvO.z)
			whvO = Are7xU(WS, WYdR(-UtI, -L, qx27))
			QKKks_zt(kpbY, whvO.x)
			QKKks_zt(m_gHw, whvO.y)
			QKKks_zt(RFOr, whvO.z)
			whvO = Are7xU(WS, WYdR(UtI, -L, -qx27))
			QKKks_zt(kpbY, whvO.x)
			QKKks_zt(m_gHw, whvO.y)
			QKKks_zt(RFOr, whvO.z)
			whvO = Are7xU(WS, WYdR(-UtI, -L, -qx27))
			QKKks_zt(kpbY, whvO.x)
			QKKks_zt(m_gHw, whvO.y)
			QKKks_zt(RFOr, whvO.z)
			QniH = yxjl(QniH, unpack(kpbY))
			j = yxjl(j, unpack(m_gHw))
			x_BU2 = yxjl(x_BU2, unpack(RFOr))
			AFii = ZG(AFii, unpack(kpbY))
			Au = ZG(Au, unpack(m_gHw))
			fgK = ZG(fgK, unpack(RFOr))
		end
	end
	if bQRP then
		return {
			Minimum = {
				x = QniH,
				y = j,
				z = x_BU2,
			},
			Maximum = {
				x = AFii,
				y = Au,
				z = fgK,
			},
		}
	else
		local NL, g0d1ms_, Xmu5 = AFii - QniH, Au - j, fgK - x_BU2
		local lC3P = Vector3.new(NL, g0d1ms_, Xmu5)
		local QwHnJ1MC = CFrame.new(QniH + (AFii - QniH) / 2, j + (Au - j) / 2, x_BU2 + (fgK - x_BU2) / 2)
		return lC3P, QwHnJ1MC
	end
end
if ToolType == "plugin" then
	Selection.Changed:Connect(function()
		SelectionService:Set(Selection.Items)
	end)
end
Tools = {}
function createDropdown()
	local giqW = (RbxUtility.Create("Frame"))({
		Name = "Dropdown",
		Size = UDim2.new(0, 20, 0, 20),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	});
	local arr = (RbxUtility.Create("ImageLabel"))({
		Parent = giqW,
		Name = "Arrow",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = Assets.ExpandArrow,
		Position = UDim2.new(1, -21, 0, 3),
		Size = UDim2.new(0, 20, 0, 20),
		ZIndex = 3,
	})
	local UJP9j = {
		Frame = giqW,
		_options = {},
		_buttons = {},
		_filter = "",
		refresh = function(dd)
			local shown = 0
			local f = string.lower(dd._filter or "")
			for _, b in ipairs(dd._buttons) do
				local n = string.lower(b.Name or "")
				local ok = f == "" or string.find(n, f, 1, true) ~= nil
				setp(b, "Visible", ok)
				if ok then
					shown = shown + 1
					setp(b, "Position", UDim2.new(math.ceil(shown / 9) - 1, 0, 0, 50 + 25 * ((shown - 1) % 9)))
				end
			end
		end,
		addOption = function(_nBsWM3x, D5)
			table.insert(_nBsWM3x._options, D5)
			local I = (RbxUtility.Create("TextButton"))({
				Parent = _nBsWM3x.Frame,
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.3,
				BorderColor3 = Color3.new(27 / 255, 42 / 255, 53 / 255),
				BorderSizePixel = 1,
				Name = D5,
				Position = UDim2.new(0, 0, 0, 50),
				Size = UDim2.new(1, 0, 0, 25),
				ZIndex = 3,
				Text = "",
			})
			local rgZln = (RbxUtility.Create("TextLabel"))({
				Parent = I,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 6, 0, 0),
				Size = UDim2.new(1, -30, 1, 0),
				ZIndex = 3,
				Font = Enum.Font.ArialBold,
				FontSize = Enum.FontSize.Size10,
				Text = D5,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
			})
			table.insert(_nBsWM3x._buttons, I)
			_nBsWM3x:refresh()
			return I
		end,
		selectOption = function(vB, vFea)
			setp(vB.Frame.MainButton.CurrentOption, "Text", vFea)
		end,
		open = false,
		toggle = function(_T5)
			if _T5.open then
				setp(_T5.Frame.MainButton, "BackgroundTransparency", 0.3)
				setp(_T5.Frame, "ClipsDescendants", true)
				_T5.open = false
				if _T5.SearchBox then
					setp(_T5.SearchBox, "Text", "")
					_T5._filter = ""
					_T5:refresh()
				end
			else
				setp(_T5.Frame.MainButton, "BackgroundTransparency", 0)
				setp(_T5.Frame, "ClipsDescendants", false)
				_T5.open = true
			end
		end,
	}
	local SObxoJk = (RbxUtility.Create("TextButton"))({
		Parent = giqW,
		Name = "MainButton",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.3,
		BorderColor3 = Color3.new(27 / 255, 42 / 255, 53 / 255),
		BorderSizePixel = 1,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 25),
		ZIndex = 2,
		Text = "",
		[RbxUtility.Create.E("MouseButton1Up")] = function()
			UJP9j:toggle()
		end,
	});
	local cur = (RbxUtility.Create("TextLabel"))({
		Parent = SObxoJk,
		Name = "CurrentOption",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 6, 0, 0),
		Size = UDim2.new(1, -30, 1, 0),
		ZIndex = 3,
		Font = Enum.Font.ArialBold,
		FontSize = Enum.FontSize.Size10,
		Text = "",
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	local Mjf = (RbxUtility.Create("TextBox"))({
		Parent = giqW,
		Name = "SearchBox",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.15,
		BorderColor3 = Color3.new(27 / 255, 42 / 255, 53 / 255),
		BorderSizePixel = 1,
		Position = UDim2.new(0, 0, 0, 25),
		Size = UDim2.new(1, 0, 0, 25),
		ZIndex = 3,
		Text = "",
		PlaceholderText = "Search",
		ClearTextOnFocus = false,
		Font = Enum.Font.Arial,
		FontSize = Enum.FontSize.Size10,
		TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	UJP9j.SearchBox = Mjf
	Mjf:GetPropertyChangedSignal("Text"):Connect(function()
		UJP9j._filter = Mjf.Text or ""
		UJP9j:refresh()
	end)
	return UJP9j
end
local function fmtEnum(x, spec)
	local n = x.Name
	if spec and spec[n] then
		return spec[n]
	end
	return (n:gsub("(%l)(%u)", "%1 %2"):gsub("(%a)(%d)", "%1 %2"):gsub("(%d)(%a)", "%1 %2"):upper())
end
local function enumItems(e, spec, ok)
	local r = {}
	for _, x in ipairs(e:GetEnumItems()) do
		if not ok or ok[x.Name] then
			table.insert(r, { Item = x, Text = fmtEnum(x, spec) })
		end
	end
	table.sort(r, function(a, b)
		return a.Text < b.Text
	end)
	return r
end
local function mapEnum(e, spec, ok)
	local r = {}
	for _, x in ipairs(enumItems(e, spec, ok)) do
		r[x.Item] = x.Text
	end
	return r
end
local function addEnum(dd, e, fn, spec, ok, first)
	if first then
		for _, x in ipairs(first) do
			local b = dd:addOption(x[1])
			b.MouseButton1Up:Connect(function()
				fn(x[2])
			end)
		end
	end
	for _, x in ipairs(enumItems(e, spec, ok)) do
		local b = dd:addOption(x.Text)
		b.MouseButton1Up:Connect(function()
			fn(x.Item)
		end)
	end
end
local function setp(o, p, v)
	if o == nil then
		return false
	end
	return pcall(function()
		o[p] = v
	end)
end
_G.setp = setp
local function cleanCons(t)
	if type(t) ~= "table" then
		return
	end
	for k, c in pairs(t) do
		if c then
			pcall(function()
				if c.Disconnect then
					c:Disconnect()
				elseif c.disconnect then
					c:disconnect()
				end
			end)
		end
		t[k] = nil
	end
end
_G.cleanCons = cleanCons
local function bulkMove(ps, cfs)
	if #ps == 0 then
		return
	end
	local ok = pcall(function()
		Workspace:BulkMoveTo(ps, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end)
	if ok then
		return
	end
	for i, p in ipairs(ps) do
		setp(p, "CFrame", cfs[i])
	end
end
Select2D = {
	enabled = false,
	GUI = nil,
	Connections = {},
	start = function(fx, input, startPoint)
		if fx.enabled then
			return
		end
		local sp = startPoint or getSelectionPointerPosition(input) or Vector2.new(click_x, click_y)
		local cp = getSelectionPointerPosition(input) or Vector2.new(Mouse.X, Mouse.Y)
		fx.enabled = true
		fx.GUI = (RbxUtility.Create("ScreenGui"))({
			Name = "BTSelectionRectangle",
			Parent = UI,
		})
		local ZkXY = (RbxUtility.Create("Frame"))({
			Name = "Rectangle",
			Active = false,
			Parent = fx.GUI,
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			Position = UDim2.new(0, math.min(sp.X, cp.X), 0, math.min(sp.Y, cp.Y)),
			Size = UDim2.new(0, math.abs(cp.X - sp.X), 0, math.abs(cp.Y - sp.Y)),
		})
		local function resize(pos)
			setp(ZkXY, "Position", UDim2.new(0, math.min(sp.X, pos.X), 0, math.min(sp.Y, pos.Y)))
			ZkXY.Size = UDim2.new(0, math.abs(pos.X - sp.X), 0, math.abs(pos.Y - sp.Y))
		end
		if input and input.UserInputType == Enum.UserInputType.Touch then
			fx.Connections.SelectionResize = UserInputService.InputChanged:Connect(function(changed)
				if changed == input then
					local pos = getSelectionPointerPosition(changed)
					if pos then
						resize(pos)
					end
				end
			end)
		else
			fx.Connections.SelectionResize = Mouse.Move:Connect(function()
				resize(Vector2.new(Mouse.X, Mouse.Y))
			end)
			fx.Connections.SelectionEnd = UserInputService.InputEnded:Connect(function(sWJA)
				if sWJA.UserInputType == Enum.UserInputType.MouseButton1 then
					fx:select()
					fx:finish()
				end
			end)
		end
	end,
	select = function(NVvo)
		if not NVvo.enabled then
			return
		end
		for P2Kd8, asrUjwf in pairs(Support.GetAllDescendants(Workspace)) do
			if isSelectable(asrUjwf) then
				local Q, ya253Ad = Workspace.CurrentCamera:WorldToScreenPoint(asrUjwf.Position)
				if Q and ya253Ad then
					local T49bAP = Q.x >= NVvo.GUI.Rectangle.AbsolutePosition.x
					local bS5Jz = Q.x <= NVvo.GUI.Rectangle.AbsolutePosition.x + NVvo.GUI.Rectangle.AbsoluteSize.x
					local yl = Q.y >= NVvo.GUI.Rectangle.AbsolutePosition.y
					local srV = Q.y <= NVvo.GUI.Rectangle.AbsolutePosition.y + NVvo.GUI.Rectangle.AbsoluteSize.y
					if T49bAP and bS5Jz and yl and srV then
						Selection:add(asrUjwf)
					end
				end
			end
		end
	end,
	finish = function(tSO4)
		if not tSO4.enabled then
			return
		end
		for ALU1Lf, odzL_ in pairs(tSO4.Connections) do
			odzL_:Disconnect()
			tSO4.Connections[ALU1Lf] = nil
		end
		tSO4.GUI:Destroy()
		tSO4.GUI = nil
		tSO4.enabled = false
	end,
}
SelectEdge = {
	enabled = false,
	started = false,
	Marker = nil,
	MarkerOutline = (RbxUtility.Create("SelectionBox"))({
		Color = BrickColor.new("Institutional white"),
		Parent = UI,
		Name = "BTEdgeSelectionMarkerOutline",
	}),
	Connections = {},
	start = function(rHhv, DUv3)
		if rHhv.started then
			return
		end
		rHhv.Connections.KeyListener = Mouse.KeyDown:Connect(function(qM23K)
			local qM23K = qM23K:lower()
			local HnNik4 = qM23K:byte()
			if qM23K == "t" and #Selection.Items > 0 then
				rHhv:enable(DUv3)
			end
		end)
		rHhv.started = true
	end,
	enable = function(Tb, k)
		if Tb.enabled then
			return
		end
		Tb.Connections.MoveListener = Mouse.Move:Connect(function()
			if not Selection:find(Mouse.Target) then
				return
			end
			local g = {}
			local mOxUSY = {}
			local QKKks_zt = table.insert
			local t = CFrame.new
			local CY = Mouse.Target.CFrame
			local Are7xU = CY.toWorldSpace
			local EPz43s = Mouse.Target.Size / 2
			local zR, ZiGUK4j, X5xyw_Y = EPz43s.x, EPz43s.y, EPz43s.z
			QKKks_zt(mOxUSY, Are7xU(CY, t(zR, ZiGUK4j, X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(-zR, ZiGUK4j, X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(zR, -ZiGUK4j, X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(zR, ZiGUK4j, -X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(-zR, ZiGUK4j, -X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(-zR, -ZiGUK4j, X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(zR, -ZiGUK4j, -X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(-zR, -ZiGUK4j, -X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(zR, ZiGUK4j, 0)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(zR, 0, X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(0, ZiGUK4j, X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(zR, 0, 0)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(0, ZiGUK4j, 0)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(0, 0, X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(-zR, ZiGUK4j, 0)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(-zR, 0, X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(0, -ZiGUK4j, X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(-zR, 0, 0)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(0, -ZiGUK4j, 0)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(0, 0, -X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(zR, -ZiGUK4j, 0)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(zR, 0, -X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(0, ZiGUK4j, -X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(-zR, -ZiGUK4j, 0)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(-zR, 0, -X5xyw_Y)))
			QKKks_zt(mOxUSY, Are7xU(CY, t(0, -ZiGUK4j, -X5xyw_Y)))
			for y7AFV, BUtgk5wL in pairs(mOxUSY) do
				g[y7AFV] = (Mouse.Hit.p - BUtgk5wL.p).magnitude
			end
			local Zb3oLBm1 = 1
			for yvkTFEw, FPuu in pairs(g) do
				if FPuu < g[Zb3oLBm1] then
					Zb3oLBm1 = yvkTFEw
				end
			end
			local gVS = mOxUSY[Zb3oLBm1]
			if Tb.Marker then
				Tb.Marker:Destroy()
			end
			Tb.Marker = (RbxUtility.Create("Part"))({
				Name = "BTEdgeSelectionMarker",
				Anchored = true,
				Locked = true,
				CanCollide = false,
				Transparency = 1,
				FormFactor = Enum.FormFactor.Custom,
				Size = Vector3.new(0.2, 0.2, 0.2),
				CFrame = gVS,
			})
			setp(Tb.MarkerOutline, "Adornee", Tb.Marker)
		end)
		Tb.Connections.ClickListener = Mouse.Button1Up:Connect(function()
			override_selection = true
			Tb:select(k)
		end)
		Tb.enabled = true
	end,
	select = function(IM6lQ1nN, cdRq)
		if not IM6lQ1nN.enabled or not IM6lQ1nN.Marker then
			return
		end
		setp(IM6lQ1nN.MarkerOutline, "Adornee", IM6lQ1nN.Marker)
		cdRq(IM6lQ1nN.Marker)
		IM6lQ1nN.Marker = nil
		IM6lQ1nN:disable()
	end,
	disable = function(rk6C)
		if not rk6C.enabled then
			return
		end
		if rk6C.Connections.ClickListener then
			rk6C.Connections.ClickListener:Disconnect()
			rk6C.Connections.ClickListener = nil
		end
		if rk6C.Connections.MoveListener then
			rk6C.Connections.MoveListener:Disconnect()
			rk6C.Connections.MoveListener = nil
		end
		if rk6C.Marker then
			rk6C.Marker:Destroy()
		end
		rk6C.Marker = nil
		setp(rk6C.MarkerOutline, "Adornee", nil)
		rk6C.enabled = false
	end,
	stop = function(a4EodrlS)
		if not a4EodrlS.started then
			return
		end
		a4EodrlS:disable()
		for QDUH3, FZNkY in pairs(a4EodrlS.Connections) do
			FZNkY:Disconnect()
			a4EodrlS.Connections[QDUH3] = nil
		end
		if a4EodrlS.Marker then
			a4EodrlS.Marker:Destroy()
		end
		a4EodrlS.started = false
	end,
}
History = {
	Data = {},
	index = 0,
	Max = 100,
	Changed = RbxUtility.CreateSignal(),
	undo = function(AMQfXns)
		if AMQfXns.index - 1 < 0 then
			return
		end
		local N = AMQfXns.Data[AMQfXns.index]
		if N and N.unapply then
			pcall(function()
				N:unapply()
			end)
		end
		AMQfXns.index = AMQfXns.index - 1
		AMQfXns.Changed:Fire()
	end,
	redo = function(Zv1xWmbK)
		if Zv1xWmbK.index + 1 > #Zv1xWmbK.Data then
			return
		end
		Zv1xWmbK.index = Zv1xWmbK.index + 1
		local usLtv = Zv1xWmbK.Data[Zv1xWmbK.index]
		if usLtv and usLtv.apply then
			pcall(function()
				usLtv:apply()
			end)
		end
		Zv1xWmbK.Changed:Fire()
	end,
	add = function(D0WSWx, fI4Jq_JC)
		if not fI4Jq_JC then
			return
		end
		D0WSWx.Data[D0WSWx.index + 1] = fI4Jq_JC
		D0WSWx.index = D0WSWx.index + 1
		for CK17 = D0WSWx.index + 1, #D0WSWx.Data do
			D0WSWx.Data[CK17] = nil
		end
		while #D0WSWx.Data > D0WSWx.Max do
			table.remove(D0WSWx.Data, 1)
			D0WSWx.index = math.max(D0WSWx.index - 1, 0)
		end
		D0WSWx.Changed:Fire()
	end,
}
if ToolType == "plugin" then
	History.Changed:Connect(function()
		ChangeHistoryService:SetWaypoint("Building Tools by F3X")
	end)
end
ColorPicker = {
	enabled = false,
	callback = nil,
	track_mouse = nil,
	hue = 0,
	saturation = 1,
	value = 1,
	GUI = nil,
	Connections = {},
	start = function(EN6EGq, _Nz, Lsvt0Xp)
		if EN6EGq.enabled then
			EN6EGq:cancel()
		end
		EN6EGq.enabled = true
		EN6EGq.GUI = DFb100j.BTHSVColorPicker:Clone()
		setp(EN6EGq.GUI, "Parent", UI)
		EN6EGq.callback = _Nz
		local Lsvt0Xp = Lsvt0Xp or Color3.new(1, 0, 0)
		EN6EGq:_changeColor(Support.RGBToHSV(Lsvt0Xp.r, Lsvt0Xp.g, Lsvt0Xp.b))
		table.insert(
			EN6EGq.Connections,
			EN6EGq.GUI.HueSaturation.MouseButton1Down:Connect(function(Js8fS1VE, nfU)
				EN6EGq.track_mouse = "hue-saturation"
				EN6EGq:_onMouseMove(Js8fS1VE, nfU)
			end)
		)
		table.insert(
			EN6EGq.Connections,
			EN6EGq.GUI.HueSaturation.MouseButton1Up:Connect(function()
				EN6EGq.track_mouse = nil
			end)
		)
		table.insert(
			EN6EGq.Connections,
			EN6EGq.GUI.MouseMoved:Connect(function(Zt78U, B_tZsz)
				EN6EGq:_onMouseMove(Zt78U, B_tZsz)
			end)
		)
		table.insert(
			EN6EGq.Connections,
			EN6EGq.GUI.Value.MouseButton1Down:Connect(function(NUeM, DiSdlMR3)
				EN6EGq.track_mouse = "value"
				EN6EGq:_onMouseMove(NUeM, DiSdlMR3)
			end)
		)
		table.insert(
			EN6EGq.Connections,
			EN6EGq.GUI.Value.MouseButton1Up:Connect(function()
				EN6EGq.track_mouse = nil
			end)
		)
		table.insert(
			EN6EGq.Connections,
			EN6EGq.GUI.OkButton.MouseButton1Up:Connect(function()
				EN6EGq:finish()
			end)
		)
		table.insert(
			EN6EGq.Connections,
			EN6EGq.GUI.CancelButton.MouseButton1Up:Connect(function()
				EN6EGq:cancel()
			end)
		)
		table.insert(
			EN6EGq.Connections,
			EN6EGq.GUI.HueOption.Input.TextButton.MouseButton1Down:Connect(function()
				EN6EGq.GUI.HueOption.Input.TextBox:CaptureFocus()
			end)
		)
		table.insert(
			EN6EGq.Connections,
			EN6EGq.GUI.HueOption.Input.TextBox.FocusLost:Connect(function(nE)
				local CIkqRkzw = tonumber(EN6EGq.GUI.HueOption.Input.TextBox.Text)
				if CIkqRkzw then
					if CIkqRkzw > 360 then
						CIkqRkzw = 360
					elseif CIkqRkzw < 0 then
						CIkqRkzw = 0
					end
					EN6EGq:_changeColor(CIkqRkzw, EN6EGq.saturation, EN6EGq.value)
				else
					EN6EGq:_updateGUI()
				end
			end)
		)
		table.insert(
			EN6EGq.Connections,
			EN6EGq.GUI.SaturationOption.Input.TextButton.MouseButton1Down:Connect(function()
				EN6EGq.GUI.SaturationOption.Input.TextBox:CaptureFocus()
			end)
		)
		table.insert(
			EN6EGq.Connections,
			EN6EGq.GUI.SaturationOption.Input.TextBox.FocusLost:Connect(function(sBI)
				local vyewX = tonumber(EN6EGq.GUI.SaturationOption.Input.TextBox.Text:gsub("%%", ""))
				if vyewX then
					if vyewX > 100 then
						vyewX = 100
					elseif vyewX < 0 then
						vyewX = 0
					end
					EN6EGq:_changeColor(EN6EGq.hue, vyewX / 100, EN6EGq.value)
				else
					EN6EGq:_updateGUI()
				end
			end)
		)
		table.insert(
			EN6EGq.Connections,
			EN6EGq.GUI.ValueOption.Input.TextButton.MouseButton1Down:Connect(function()
				EN6EGq.GUI.ValueOption.Input.TextBox:CaptureFocus()
			end)
		)
		table.insert(
			EN6EGq.Connections,
			EN6EGq.GUI.ValueOption.Input.TextBox.FocusLost:Connect(function(ZXMlRMR)
				local CCo8Y = tonumber(EN6EGq.GUI.ValueOption.Input.TextBox.Text:gsub("%%", ""))
				if CCo8Y then
					if CCo8Y < 0 then
						CCo8Y = 0
					elseif CCo8Y > 100 then
						CCo8Y = 100
					end
					EN6EGq:_changeColor(EN6EGq.hue, EN6EGq.saturation, CCo8Y / 100)
				else
					EN6EGq:_updateGUI()
				end
			end)
		)
	end,
	_onMouseMove = function(hx1fY90, dt7v, HBjl)
		if not hx1fY90.track_mouse then
			return
		end
		if hx1fY90.track_mouse == "hue-saturation" then
			local tcVr, r =
				dt7v - hx1fY90.GUI.HueSaturation.AbsolutePosition.x, HBjl - hx1fY90.GUI.HueSaturation.AbsolutePosition.y
			if tcVr < 0 then
				tcVr = 0
			elseif tcVr > hx1fY90.GUI.HueSaturation.AbsoluteSize.x then
				tcVr = hx1fY90.GUI.HueSaturation.AbsoluteSize.x
			end
			if r < 0 then
				r = 0
			elseif r > hx1fY90.GUI.HueSaturation.AbsoluteSize.y then
				r = hx1fY90.GUI.HueSaturation.AbsoluteSize.y
			end
			hx1fY90:_changeColor(359 * tcVr / 209, 1 - r / 200, hx1fY90.value)
		elseif hx1fY90.track_mouse == "value" then
			local htj = HBjl - hx1fY90.GUI.Value.AbsolutePosition.y
			if htj < 0 then
				htj = 0
			elseif htj > hx1fY90.GUI.Value.AbsoluteSize.y then
				htj = hx1fY90.GUI.Value.AbsoluteSize.y
			end
			hx1fY90:_changeColor(hx1fY90.hue, hx1fY90.saturation, 1 - htj / 200)
		end
	end,
	_changeColor = function(Ltq_xgJ, Re, cG3HJLZ, LG)
		if Re ~= Re then
			Re = 359
		end
		Ltq_xgJ.hue = Re
		Ltq_xgJ.saturation = cG3HJLZ == 0 and 0.01 or cG3HJLZ
		Ltq_xgJ.value = LG
		Ltq_xgJ:_updateGUI()
	end,
	_updateGUI = function(x__e0OAv)
		x__e0OAv.GUI.HueSaturation.Cursor.Position =
			UDim2.new(0, 209 * x__e0OAv.hue / 360 - 8, 0, (1 - x__e0OAv.saturation) * 200 - 8)
		setp(x__e0OAv.GUI.Value.Cursor, "Position", UDim2.new(0, -2, 0, (1 - x__e0OAv.value) * 200 - 8))
		local F9 = Color3.new(Support.HSVToRGB(x__e0OAv.hue, x__e0OAv.saturation, x__e0OAv.value))
		setp(x__e0OAv.GUI.ColorDisplay, "BackgroundColor3", F9)
		setp(x__e0OAv.GUI.Value.ColorBG, "BackgroundColor3", Color3.new(Support.HSVToRGB(x__e0OAv.hue, x__e0OAv.saturation, 1)))
		setp(x__e0OAv.GUI.HueOption.Bar, "BackgroundColor3", F9)
		setp(x__e0OAv.GUI.SaturationOption.Bar, "BackgroundColor3", F9)
		setp(x__e0OAv.GUI.ValueOption.Bar, "BackgroundColor3", F9)
		setp(x__e0OAv.GUI.HueOption.Input.TextBox, "Text", math.floor(x__e0OAv.hue))
		setp(x__e0OAv.GUI.SaturationOption.Input.TextBox, "Text", math.floor(x__e0OAv.saturation * 100) .. "%")
		setp(x__e0OAv.GUI.ValueOption.Input.TextBox, "Text", math.floor(x__e0OAv.value * 100) .. "%")
	end,
	finish = function(IbKWp)
		if not IbKWp.enabled then
			return
		end
		if IbKWp.GUI then
			IbKWp.GUI:Destroy()
		end
		IbKWp.GUI = nil
		IbKWp.track_mouse = nil
		for j, nY4CweuF in pairs(IbKWp.Connections) do
			nY4CweuF:Disconnect()
			IbKWp.Connections[j] = nil
		end
		IbKWp.callback(IbKWp.hue, IbKWp.saturation, IbKWp.value)
		IbKWp.callback = nil
		IbKWp.enabled = false
	end,
	cancel = function(Ttb)
		if not Ttb.enabled then
			return
		end
		if Ttb.GUI then
			Ttb.GUI:Destroy()
		end
		Ttb.GUI = nil
		Ttb.track_mouse = nil
		for wIat2P0, m7M in pairs(Ttb.Connections) do
			m7M:Disconnect()
			Ttb.Connections[wIat2P0] = nil
		end
		Ttb.callback()
		Ttb.callback = nil
		Ttb.enabled = false
	end,
}
ExportInterface = {}
ExportInterface.Export = function(J8)
	local VchN = {
		Workspace = Workspace,
	}
	local ws7lX6m_ = HttpService
	local cXif = script.Parent
	local UV = script.Parent.Parent
	local o6kB = require(UV:WaitForChild("SupportLibrary"))
	function _generateSerializationID()
		local la = {
			"0",
			"1",
			"2",
			"3",
			"4",
			"5",
			"6",
			"7",
			"8",
			"9",
			"a",
			"b",
			"c",
			"d",
			"e",
			"f",
			"g",
			"h",
			"i",
			"j",
			"k",
			"l",
			"m",
			"n",
			"o",
			"p",
			"q",
			"r",
			"s",
			"t",
			"u",
			"v",
			"w",
			"x",
			"y",
			"z",
			"A",
			"B",
			"C",
			"D",
			"E",
			"F",
			"G",
			"H",
			"I",
			"J",
			"K",
			"L",
			"M",
			"N",
			"O",
			"P",
			"Q",
			"R",
			"S",
			"T",
			"U",
			"V",
			"W",
			"X",
			"Y",
			"Z",
		}
		local W = ""
		for Ihh6yjj = 1, 5 do
			W = W .. la[math.random(#la)]
		end
		return W
	end
	function _splitNumberListString(q5)
		local hgc6Q = o6kB.SplitString(q5, ", ")
		for mIJ_kc4, J in pairs(hgc6Q) do
			hgc6Q[mIJ_kc4] = tonumber(J)
		end
		return hgc6Q
	end
	function _getSerializationPartType(uUw95D)
		local KRLJOGI = {
			Normal = 1,
			Truss = 2,
			Wedge = 3,
			Corner = 4,
			Cylinder = 5,
			Ball = 6,
			Seat = 7,
			VehicleSeat = 8,
			Spawn = 9,
		}
		if uUw95D.ClassName == "Part" then
			if uUw95D.Shape == Enum.PartType.Block then
				return KRLJOGI.Normal
			elseif uUw95D.Shape == Enum.PartType.Cylinder then
				return KRLJOGI.Cylinder
			elseif uUw95D.Shape == Enum.PartType.Ball then
				return KRLJOGI.Ball
			end
		elseif uUw95D.ClassName == "Seat" then
			return KRLJOGI.Seat
		elseif uUw95D.ClassName == "VehicleSeat" then
			return KRLJOGI.VehicleSeat
		elseif uUw95D.ClassName == "SpawnLocation" then
			return KRLJOGI.Spawn
		elseif uUw95D.ClassName == "WedgePart" then
			return KRLJOGI.Wedge
		elseif uUw95D.ClassName == "CornerWedgePart" then
			return KRLJOGI.Corner
		elseif uUw95D.ClassName == "TrussPart" then
			return KRLJOGI.Truss
		end
	end
	function _serializeParts(Gns3m_)
		local f = {
			version = 1,
			parts = {},
		}
		local _zxBo = {}
		local gN = {}
		local oZs2khg = tick()
		for Bu1tX_x3, m0 in pairs(Gns3m_) do
			local n = _generateSerializationID()
			local Q = {
				_getSerializationPartType(m0),
				_splitNumberListString(tostring(m0.Size)),
				_splitNumberListString(tostring(m0.CFrame)),
				m0.BrickColor.Number,
				m0.Material.Value,
				m0.Anchored,
				m0.CanCollide,
				m0.Reflectance,
				m0.Transparency,
				m0.TopSurface.Value,
				m0.BottomSurface.Value,
				m0.LeftSurface.Value,
				m0.RightSurface.Value,
				m0.FrontSurface.Value,
				m0.BackSurface.Value,
			}
			f.parts[n] = Q
			_zxBo[n] = m0
			gN[m0] = n
		end
		local pSEIak = {}
		for CoiGQD, KR7 in pairs(_zxBo) do
			if KR7:IsA("BasePart") then
				for a, P5 in pairs(KR7:GetChildren()) do
					if P5.Name == "BTWeld" and P5:IsA("Weld") and gN[P5.Part0] and gN[P5.Part1] then
						table.insert(pSEIak, P5)
					end
				end
			end
		end
		if #pSEIak > 0 then
			f.welds = {}
			for h, TCVpKFp in pairs(pSEIak) do
				local NY = _generateSerializationID()
				local hEVRc = {
					gN[TCVpKFp.Part0],
					gN[TCVpKFp.Part1],
					_splitNumberListString(tostring(TCVpKFp.C1)),
				}
				f.welds[NY] = hEVRc
				_zxBo[NY] = TCVpKFp
				gN[TCVpKFp] = NY
			end
		end
		local AkjIt = {}
		for BA6zaoJ, Y7 in pairs(Gns3m_) do
			local g = o6kB.GetChildOfClass(Y7, "SpecialMesh")
			if g then
				table.insert(AkjIt, g)
			end
		end
		if #AkjIt > 0 then
			f.meshes = {}
			for jtL2, DA in pairs(AkjIt) do
				local d7K3 = _generateSerializationID()
				local Ozih058u = {
					gN[DA.Parent],
					DA.MeshType.Value,
					_splitNumberListString(tostring(DA.Scale)),
					DA.MeshId,
					DA.TextureId,
					_splitNumberListString(tostring(DA.VertexColor)),
				}
				f.meshes[d7K3] = Ozih058u
				_zxBo[d7K3] = DA
				gN[DA] = d7K3
			end
		end
		local ox = {}
		for oW9bf, u in pairs(Gns3m_) do
			local rZrrL = o6kB.GetChildrenOfClass(u, "Texture")
			for oW9bf, QXFNNY in pairs(rZrrL) do
				table.insert(ox, QXFNNY)
			end
			local E4a = o6kB.GetChildrenOfClass(u, "Decal")
			for oW9bf, e in pairs(E4a) do
				table.insert(ox, e)
			end
		end
		if #ox > 0 then
			f.textures = {}
			for BH, xD in pairs(ox) do
				local fl
				if xD.ClassName == "Decal" then
					fl = 1
				elseif xD.ClassName == "Texture" then
					fl = 2
				end
				local QCv = _generateSerializationID()
				local qd_HCf = {
					gN[xD.Parent],
					fl,
					xD.Face.Value,
					xD.Texture,
					xD.Transparency,
					fl == 2 and xD.StudsPerTileU or nil,
					fl == 2 and xD.StudsPerTileV or nil,
				}
				f.textures[QCv] = qd_HCf
				_zxBo[QCv] = xD
				gN[xD] = QCv
			end
		end
		local y5FoBZ5 = {}
		for CU, M1ywSQ in pairs(Gns3m_) do
			local g = o6kB.GetChildrenOfClass(M1ywSQ, "Light", true)
			for CU, hPc4e3hn in pairs(g) do
				table.insert(y5FoBZ5, hPc4e3hn)
			end
		end
		if #y5FoBZ5 > 0 then
			f.lights = {}
			for m, Rlb in pairs(y5FoBZ5) do
				local KgX
				if Rlb:IsA("PointLight") then
					KgX = 1
				elseif Rlb:IsA("SpotLight") then
					KgX = 2
				end
				local SXr = _generateSerializationID()
				local IZQg6shq = {
					gN[Rlb.Parent],
					KgX,
					_splitNumberListString(tostring(Rlb.Color)),
					Rlb.Brightness,
					Rlb.Range,
					Rlb.Shadows,
					KgX == 2 and Rlb.Angle or nil,
					KgX == 2 and Rlb.Face.Value or nil,
				}
				f.lights[SXr] = IZQg6shq
				_zxBo[SXr] = Rlb
				gN[Rlb] = SXr
			end
		end
		local VXwusjUq = {}
		for bz, wL in pairs(Gns3m_) do
			table.insert(VXwusjUq, o6kB.GetChildOfClass(wL, "Smoke"))
			table.insert(VXwusjUq, o6kB.GetChildOfClass(wL, "Fire"))
			table.insert(VXwusjUq, o6kB.GetChildOfClass(wL, "Sparkles"))
		end
		if #VXwusjUq > 0 then
			f.decorations = {}
			for BSDnLt_, vQ6pTDbn in pairs(VXwusjUq) do
				local P
				if vQ6pTDbn:IsA("Smoke") then
					P = 1
				elseif vQ6pTDbn:IsA("Fire") then
					P = 2
				elseif vQ6pTDbn:IsA("Sparkles") then
					P = 3
				end
				local W = _generateSerializationID()
				local CDG3os = {
					gN[vQ6pTDbn.Parent],
					P,
				}
				if P == 1 then
					CDG3os[3] = _splitNumberListString(tostring(vQ6pTDbn.Color))
					CDG3os[4] = vQ6pTDbn.Opacity
					CDG3os[5] = vQ6pTDbn.RiseVelocity
					CDG3os[6] = vQ6pTDbn.Size
				elseif P == 2 then
					CDG3os[3] = _splitNumberListString(tostring(vQ6pTDbn.Color))
					CDG3os[4] = _splitNumberListString(tostring(vQ6pTDbn.SecondaryColor))
					CDG3os[5] = vQ6pTDbn.Heat
					CDG3os[6] = vQ6pTDbn.Size
				elseif P == 3 then
					CDG3os[3] = _splitNumberListString(tostring(vQ6pTDbn.SparkleColor))
				end
				f.decorations[W] = CDG3os
				_zxBo[W] = vQ6pTDbn
				gN[vQ6pTDbn] = W
			end
		end
		local xP7ck = ws7lX6m_:JSONEncode(f)
		return xP7ck
	end
	local sdfJ = _serializeParts(J8)
	local uwuecWs
	local l, xhVT42E = ypcall(function()
		uwuecWs = ws7lX6m_:PostAsync("http://www.f3xteam.com/bt/export", sdfJ)
	end)
	local qX
	local A = ypcall(function()
		qX = ws7lX6m_:JSONDecode(uwuecWs)
	end)
	return l, xhVT42E, A, qX
end
IE = {
	export = function()
		if #Selection.Items == 0 then
			return
		end
		local MOd9uwnL = DFb100j.BTExportDialog:Clone()
		setp(MOd9uwnL.Loading, "Size", UDim2.new(1, 0, 0, 0))
		setp(MOd9uwnL, "Parent", UI)
		MOd9uwnL.Loading:TweenSize(UDim2.new(1, 0, 0, 80), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25)
		MOd9uwnL.Loading.CloseButton.MouseButton1Up:Connect(function()
			MOd9uwnL:Destroy()
		end)
		local JZDx8, _XR0EY1, z3J, ufXNV = ExportInterface.Export(Selection.Items)
		if
			not JZDx8
			and (
				_XR0EY1 == "Http requests are not enabled"
					or _XR0EY1 == "Http requests can only be executed by game server"
			)
		then
			setp(MOd9uwnL.Loading.TextLabel, "Text", "Upload failed, see message(s)")
			setp(MOd9uwnL.Loading.CloseButton, "Text", "Okay!")
			XL_ = false
			ShowStartupNotifications()
		elseif not JZDx8 then
			setp(MOd9uwnL.Loading.TextLabel, "Text", "Upload failed (unknown request error)")
			setp(MOd9uwnL.Loading.CloseButton, "Text", "Okay :(")
			XL_ = false
			ShowStartupNotifications()
		elseif JZDx8 and (not z3J or not ufXNV.success) then
			setp(MOd9uwnL.Loading.TextLabel, "Text", "Upload failed (unknown processing error)")
			setp(MOd9uwnL.Loading.CloseButton, "Text", "Okay :(")
			XL_ = false
			ShowStartupNotifications()
		elseif JZDx8 and z3J then
			setp(MOd9uwnL.Loading, "Visible", false)
			setp(MOd9uwnL.Info, "Size", UDim2.new(1, 0, 0, 0))
			setp(MOd9uwnL.Info.CreationID, "Text", ufXNV.id)
			setp(MOd9uwnL.Info, "Visible", true)
			MOd9uwnL.Info:TweenSize(UDim2.new(1, 0, 0, 75), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25)
			setp(MOd9uwnL.Tip, "Size", UDim2.new(1, 0, 0, 0))
			setp(MOd9uwnL.Tip, "Visible", true)
			MOd9uwnL.Tip:TweenSize(UDim2.new(1, 0, 0, 30), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25)
			setp(MOd9uwnL.Close, "Size", UDim2.new(1, 0, 0, 0))
			setp(MOd9uwnL.Close, "Visible", true)
			MOd9uwnL.Close:TweenSize(UDim2.new(1, 0, 0, 20), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25)
			MOd9uwnL.Close.Button.MouseButton1Up:Connect(function()
				MOd9uwnL:Destroy()
			end)
			local Vum8 = (RbxUtility.Create("Sound"))({
				Name = "BTActionCompletionSound",
				Pitch = 1.5,
				SoundId = Assets.ActionCompletionSound,
				Volume = 1,
				Parent = Player or SoundService,
			})
			Vum8:Play()
			Vum8:Destroy()
		end
	end,
}
Tooltips = {}
Dock = DFb100j.BTDockGUI:Clone()
setp(Dock, "Parent", UI)
setp(Dock, "Visible", false)
function createMobileSelectionToggle()
	if not Dock or not Dock:FindFirstChild("InfoButtons") or MobileMultiButton then
		return
	end
	local info = Dock.InfoButtons
	local sig = info:FindFirstChild("F3XSignature")
	if sig then
		setp(sig, "Visible", false)
	end
	MobileMultiButton = Instance.new("TextButton")
	setp(MobileMultiButton, "Name", "MobileMultiSelectToggle")
	setp(MobileMultiButton, "AutoButtonColor", true)
	setp(MobileMultiButton, "BackgroundColor3", Color3.new(0, 0, 0))
	setp(MobileMultiButton, "BackgroundTransparency", 0.55)
	setp(MobileMultiButton, "BorderSizePixel", 0)
	setp(MobileMultiButton, "Position", UDim2.new(0, 0, 0, 0))
	setp(MobileMultiButton, "Size", UDim2.new(1, -32, 1, 0))
	setp(MobileMultiButton, "ZIndex", 4)
	setp(MobileMultiButton, "Font", Enum.Font.ArialBold)
	setp(MobileMultiButton, "FontSize", Enum.FontSize.Size10)
	setp(MobileMultiButton, "TextWrapped", true)
	setp(MobileMultiButton, "TextScaled", true)
	setp(MobileMultiButton, "Text", "MULTI\nOFF")
	setp(MobileMultiButton, "TextColor3", Color3.new(1, 1, 1))
	setp(MobileMultiButton, "Visible", UserInputService.TouchEnabled)
	setp(MobileMultiButton, "Parent", info)
	local function toggle()
		setMobileMultiSelect(not mobile_multi_select)
	end
	if MobileMultiButton.Activated then
		MobileMultiButton.Activated:Connect(toggle)
	else
		MobileMultiButton.MouseButton1Up:Connect(toggle)
	end
	pcall(function()
		UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(function()
			setp(MobileMultiButton, "Visible", UserInputService.TouchEnabled)
		end)
	end)
	setMobileMultiSelect(false)
end
createMobileSelectionToggle()
function RegisterToolButton(NQSh)
	local Y1rSR = NQSh.Name:match("(.+)Button")
	if Y1rSR then
		NQSh.MouseButton1Up:Connect(function()
			local aqQh = Tools[Y1rSR]
			if aqQh then
				equipTool(aqQh)
			end
		end)
		NQSh.MouseEnter:Connect(function()
			local H_ = Tooltips[Y1rSR]
			if H_ then
				H_:focus("button")
			end
		end)
		NQSh.MouseLeave:Connect(function()
			local EQaFI0gZ = Tooltips[Y1rSR]
			if EQaFI0gZ then
				EQaFI0gZ:unfocus("button")
			end
		end)
	end
end
for kKiLOav, XW8 in pairs(Dock.ToolButtons:GetChildren()) do
	RegisterToolButton(XW8)
end
function RegisterTooltip(_8Ls)
	local t_t7 = _8Ls.Name:match("(.+)Info")
	Tooltips[t_t7] = {
		GUI = _8Ls,
		button_focus = false,
		tooltip_focus = false,
		focus = function(o, ogi5Usg)
			if Dock.HelpInfo.Visible then
				return
			end
			if ogi5Usg == "button" then
				o.button_focus = true
			elseif ogi5Usg == "tooltip" then
				o.tooltip_focus = true
			end
			for pA, _8Ls in pairs(Dock.Tooltips:GetChildren()) do
				setp(_8Ls, "Visible", false)
			end
			setp(o.GUI, "Visible", true)
		end,
		unfocus = function(DOIqPj09, RoKAkM)
			if RoKAkM == "button" then
				DOIqPj09.button_focus = false
			elseif RoKAkM == "tooltip" then
				DOIqPj09.tooltip_focus = false
			end
			if not DOIqPj09.button_focus and not DOIqPj09.tooltip_focus then
				setp(DOIqPj09.GUI, "Visible", false)
			end
		end,
	}
	_8Ls.MouseEnter:Connect(function()
		Tooltips[t_t7]:focus("tooltip")
	end)
	_8Ls.MouseLeave:Connect(function()
		Tooltips[t_t7]:unfocus("tooltip")
	end)
	local A_oCK8 = Gloo.ScrollingContainer(true, false, 15)
	setp(A_oCK8.GUI, "Parent", _8Ls)
	for FETmJjQd, RK in pairs(_8Ls.Content:GetChildren()) do
		setp(RK, "Parent", A_oCK8.Container)
	end
	setp(A_oCK8.GUI, "Size", Dock.Tooltips.Size)
	setp(A_oCK8.Container, "Size", _8Ls.Content.Size)
	setp(A_oCK8.Boundary, "Size", Dock.Tooltips.Size)
	setp(A_oCK8.Boundary, "BackgroundTransparency", 1)
	_8Ls.Content:Destroy()
end
for XAv, bdJvhbGA in pairs(Dock.Tooltips:GetChildren()) do
	RegisterTooltip(bdJvhbGA)
end
local Vu0cCAf = Gloo.ScrollingContainer(true, false, 15)
setp(Vu0cCAf.GUI, "Parent", Dock.HelpInfo)
for c9M, bcYXd in pairs(Dock.HelpInfo.Content:GetChildren()) do
	setp(bcYXd, "Parent", Vu0cCAf.Container)
end
setp(Vu0cCAf.GUI, "Size", Dock.HelpInfo.Size)
setp(Vu0cCAf.Container, "Size", Dock.HelpInfo.Content.Size)
setp(Vu0cCAf.Boundary, "Size", Dock.HelpInfo.Size)
setp(Vu0cCAf.Boundary, "BackgroundTransparency", 1)
Dock.HelpInfo.Content:Destroy()
Dock.SelectionButtons.UndoButton.MouseButton1Up:Connect(function()
	History:undo()
end)
Dock.SelectionButtons.RedoButton.MouseButton1Up:Connect(function()
	History:redo()
end)
Dock.SelectionButtons.DeleteButton.MouseButton1Up:Connect(function()
	deleteSelection()
end)
Dock.SelectionButtons.CloneButton.MouseButton1Up:Connect(function()
	cloneSelection()
end)
Dock.SelectionButtons.ExportButton.MouseButton1Up:Connect(function()
	IE:export()
end)
Dock.SelectionButtons.GroupsButton.MouseButton1Up:Connect(function()
	Groups:ToggleUI()
end)
Dock.InfoButtons.HelpButton.MouseButton1Up:Connect(function()
	toggleHelp()
end)
Selection.Changed:Connect(function()
	if #Selection.Items > 0 then
		setp(Dock.SelectionButtons.DeleteButton, "Image", Assets.DeleteActiveDecal)
		setp(Dock.SelectionButtons.CloneButton, "Image", Assets.CloneActiveDecal)
		setp(Dock.SelectionButtons.ExportButton, "Image", Assets.ExportActiveDecal)
	else
		setp(Dock.SelectionButtons.DeleteButton, "Image", Assets.DeleteInactiveDecal)
		setp(Dock.SelectionButtons.CloneButton, "Image", Assets.CloneInactiveDecal)
		setp(Dock.SelectionButtons.ExportButton, "Image", Assets.ExportInactiveDecal)
	end
end)
for wbw9, jFg in pairs(Dock.SelectionButtons:GetChildren()) do
	jFg.MouseEnter:Connect(function()
		if jFg:FindFirstChild("Tooltip") then
			setp(jFg.Tooltip, "Visible", true)
		end
	end)
	jFg.MouseLeave:Connect(function()
		if jFg:FindFirstChild("Tooltip") then
			setp(jFg.Tooltip, "Visible", false)
		end
	end)
end
Dock.InfoButtons.HelpButton.MouseEnter:Connect(function()
	setp(Dock.InfoButtons.HelpButton.Tooltip, "Visible", true)
end)
Dock.InfoButtons.HelpButton.MouseLeave:Connect(function()
	setp(Dock.InfoButtons.HelpButton.Tooltip, "Visible", false)
end)
History.Changed:Connect(function()
	if #History.Data > 0 then
		if History.index == 0 then
			setp(Dock.SelectionButtons.UndoButton, "Image", Assets.UndoInactiveDecal)
			setp(Dock.SelectionButtons.RedoButton, "Image", Assets.RedoActiveDecal)
		elseif History.index == #History.Data then
			setp(Dock.SelectionButtons.UndoButton, "Image", Assets.UndoActiveDecal)
			setp(Dock.SelectionButtons.RedoButton, "Image", Assets.RedoInactiveDecal)
		else
			setp(Dock.SelectionButtons.UndoButton, "Image", Assets.UndoActiveDecal)
			setp(Dock.SelectionButtons.RedoButton, "Image", Assets.RedoActiveDecal)
		end
	else
		setp(Dock.SelectionButtons.UndoButton, "Image", Assets.UndoInactiveDecal)
		setp(Dock.SelectionButtons.RedoButton, "Image", Assets.RedoInactiveDecal)
	end
end)
Groups = {
	Data = {},
	UI = DFb100j.BTGroupsGUI:Clone(),
	GroupAdded = Support.CreateSignal(),
	NewGroup = function(_3BxMtBx)
		local j5rH = {
			Name = "Group " .. #_3BxMtBx.Data + 1,
			Items = {},
			Ignoring = false,
			Changed = Support.CreateSignal(),
			Updated = Support.CreateSignal(),
			Rename = function(mKQv1MD, XvjCso)
				setp(mKQv1MD, "Name", XvjCso)
				mKQv1MD.Changed:Fire()
			end,
			SetIgnore = function(_R3NsF, I)
				_R3NsF.Ignoring = I
				_R3NsF.Changed:Fire()
			end,
			Update = function(luJe, oJ)
				luJe.Items = Support.CloneTable(oJ)
				luJe.Updated:Fire()
			end,
			Select = function(XRK37sBn, W6W)
				if not W6W then
					Selection:clear()
				end
				for HUwZ2ikl, trUgnCUz in pairs(XRK37sBn.Items) do
					Selection:add(trUgnCUz)
				end
			end,
		}
		table.insert(_3BxMtBx.Data, j5rH)
		_3BxMtBx.GroupAdded:Fire(j5rH)
		return j5rH
	end,
	ToggleUI = function(CTJB)
		setp(CTJB.UI, "Visible", not CTJB.UI.Visible)
	end,
	IsPartIgnored = function(PK9, hd)
		for l8vftvD, xb in pairs(PK9.Data) do
			if xb.Ignoring and #Support.FindTableOccurrences(xb.Items, hd) > 0 then
				return true
			end
		end
		return false
	end,
}
setp(Groups.UI, "Visible", false)
setp(Groups.UI, "Parent", Dock)
Groups.UI.Title.CreateButton.MouseButton1Click:Connect(function()
	local KHB = Groups:NewGroup()
	KHB:Update(Selection.Items)
end)
Groups.GroupAdded:Connect(function(RZ8IqF)
	local FasBerA = Groups.UI.Templates.GroupButton:Clone()
	setp(FasBerA, "Position", UDim2.new(0, 0, 0, 26 * (#Groups.UI.GroupList:GetChildren())))
	setp(FasBerA, "Parent", Groups.UI.GroupList)
	setp(FasBerA.GroupName, "Text", RZ8IqF.Name)
	setp(FasBerA.GroupNamer, "Text", RZ8IqF.Name)
	setp(Groups.UI.GroupList, "CanvasSize", UDim2.new(1, -10, 0, 26 * (#Groups.UI.GroupList:GetChildren())))
	setp(FasBerA.IgnoreButton.RightTooltip.Text, "Text", RZ8IqF.Ignoring and "UNIGNORE" or "IGNORE")
	FasBerA.GroupName.MouseButton1Click:Connect(function()
		RZ8IqF:Select(selecting)
	end)
	RZ8IqF.Changed:Connect(function()
		setp(FasBerA.GroupName, "Text", RZ8IqF.Name)
		setp(FasBerA.GroupNamer, "Text", RZ8IqF.Name)
		setp(FasBerA.IgnoreButton, "Image", RZ8IqF.Ignoring and Assets.GroupLockIcon or Assets.GroupUnlockIcon)
		setp(FasBerA.IgnoreButton.RightTooltip.Text, "Text", RZ8IqF.Ignoring and "UNIGNORE" or "IGNORE")
	end)
	RZ8IqF.Updated:Connect(function()
		setp(FasBerA.UpdateButton, "Image", Assets.GroupUpdateOKIcon);
		(coroutine.wrap(function()
			task.wait(1)
			setp(FasBerA.UpdateButton, "Image", Assets.GroupUpdateIcon)
		end))()
	end)
	FasBerA.EditButton.MouseButton1Click:Connect(function()
		setp(FasBerA.GroupName, "Visible", false)
		setp(FasBerA.GroupNamer, "Visible", true)
		FasBerA.GroupNamer:CaptureFocus()
	end)
	FasBerA.GroupNamer.FocusLost:Connect(function(ayR7Lua6)
		if ayR7Lua6 then
			RZ8IqF:Rename(FasBerA.GroupNamer.Text)
		end
		setp(FasBerA.GroupNamer, "Visible", false)
		setp(FasBerA.GroupNamer, "Text", RZ8IqF.Name)
		setp(FasBerA.GroupName, "Visible", true)
	end)
	FasBerA.IgnoreButton.MouseButton1Click:Connect(function()
		RZ8IqF:SetIgnore(not RZ8IqF.Ignoring)
	end)
	FasBerA.UpdateButton.MouseButton1Click:Connect(function()
		RZ8IqF:Update(Selection.Items)
	end)
	local pf = {
		FasBerA.UpdateButton,
		FasBerA.EditButton,
		FasBerA.IgnoreButton,
		FasBerA.GroupNameArea,
	}
	for Ini5SE, PyZ2PUy0 in pairs(pf) do
		local ZiDK = PyZ2PUy0:FindFirstChild("LeftTooltip") or PyZ2PUy0:FindFirstChild("RightTooltip")
		if ZiDK then
			PyZ2PUy0.InputBegan:Connect(function(HfV)
				if HfV.UserInputType == Enum.UserInputType.MouseMovement then
					setp(ZiDK, "Visible", true)
				end
			end)
			PyZ2PUy0.InputEnded:Connect(function(kYK3PhRd)
				if kYK3PhRd.UserInputType == Enum.UserInputType.MouseMovement then
					setp(ZiDK, "Visible", false)
				end
			end)
		end
	end
end)
function equipBT(O)
	Mouse = O
	if not CurrentTool then
		equipTool(Tools.Move)
	end
	if not TargetBox then
		TargetBox = Instance.new("SelectionBox", UI)
		setp(TargetBox, "Name", "BTTargetBox")
		setp(TargetBox, "Color", BrickColor.new("Institutional white"))
		setp(TargetBox, "Transparency", 0.5)
	end
	for xme2_Bb, ccqzSAU in pairs(SelectionBoxes) do
		setp(ccqzSAU, "Parent", UI)
	end
	if ToolType == "plugin" then
		for N, Rl1JVg in pairs(SelectionService:Get()) do
			Selection:add(Rl1JVg)
		end
	end
	if CurrentTool and CurrentTool.Listeners.Equipped then
		local okEquip, errEquip = xpcall(CurrentTool.Listeners.Equipped, F3XTraceback)
		if not okEquip then
			F3XWarn("Current tool equip listener failed: " .. tostring(errEquip))
		end
	end
	setp(Dock, "Visible", true)
	coroutine.wrap(function()
		local okStartup, errStartup = xpcall(ShowStartupNotifications, F3XTraceback)
		if not okStartup then
			F3XWarn("Startup notifications failed: " .. tostring(errStartup))
		end
	end)()
	Connections.SelectionModeStart = Support.AddUserInputListener("Began", "Keyboard", false, function(h)
		if
			h.KeyCode == Enum.KeyCode.LeftShift
			or h.KeyCode == Enum.KeyCode.RightShift
			or h.KeyCode == Enum.KeyCode.LeftControl
			or h.KeyCode == Enum.KeyCode.RightControl
		then
			selecting = true
		end
	end)
	Connections.SelectionModeEnd = Support.AddUserInputListener("Ended", "Keyboard", true, function(nwlg80aZ)
		if
			nwlg80aZ.KeyCode == Enum.KeyCode.LeftShift
			or nwlg80aZ.KeyCode == Enum.KeyCode.RightShift
			or nwlg80aZ.KeyCode == Enum.KeyCode.LeftControl
			or nwlg80aZ.KeyCode == Enum.KeyCode.RightControl
		then
			selecting = false
		end
	end)
	table.insert(
		Connections,
		Mouse.KeyDown:Connect(function(B)
			local B = B:lower()
			local PDGF = B:byte()
			local x_gZS_6x = selecting
			if B == "x" and x_gZS_6x then
				deleteSelection()
				return
			end
			if B == "c" and x_gZS_6x then
				task.wait(0)
				cloneSelection()
				return
			end
			if B == "z" and x_gZS_6x then
				History:undo()
				return
			elseif B == "y" and x_gZS_6x then
				History:redo()
				return
			end
			if B == "p" and x_gZS_6x then
				IE:export()
				return
			end
			if B == "k" and x_gZS_6x then
				prismSelect()
				return
			end
			if B == "r" and x_gZS_6x then
				Selection:clear()
				return
			end
			if B == "g" and x_gZS_6x then
				Groups:ToggleUI()
				return
			end
			if B == "[" then
				local cG = Selection.Last
				if not cG then
					return
				end
				if cG.Parent == Workspace then
					return
				end
				if not x_gZS_6x then
					Selection:clear()
				end
				local L9PPA2e = Support.GetAllDescendants(cG.Parent)
				for JwAi, wjgKmwQJ in pairs(L9PPA2e) do
					Selection:add(wjgKmwQJ)
				end
				Selection:add(cG)
				return
			end
			if B == "z" then
				equipTool(Tools.Move)
			elseif B == "x" then
				equipTool(Tools.Resize)
			elseif B == "c" then
				equipTool(Tools.Rotate)
			elseif B == "v" then
				equipTool(Tools.Paint)
			elseif B == "b" then
				equipTool(Tools.Surface)
			elseif B == "n" then
				equipTool(Tools.Material)
			elseif B == "m" then
				equipTool(Tools.Anchor)
			elseif B == "k" then
				equipTool(Tools.Collision)
			elseif B == "j" then
				equipTool(Tools.NewPart)
			elseif B == "h" then
				equipTool(Tools.Mesh)
			elseif B == "g" then
				equipTool(Tools.Texture)
			elseif B == "f" then
				equipTool(Tools.Weld)
			elseif B == "u" then
				equipTool(Tools.Lighting)
			elseif B == "p" then
				equipTool(Tools.Decorate)
			end
			ActiveKeys[PDGF] = PDGF
			ActiveKeys[B] = B
		end)
	)
	table.insert(
		Connections,
		Mouse.KeyUp:Connect(function(Sq5Mc)
			local Sq5Mc = Sq5Mc:lower()
			local iAXm7_ = Sq5Mc:byte()
			ActiveKeys[iAXm7_] = nil
			ActiveKeys[Sq5Mc] = nil
			if not selecting then
				if Select2D.enabled then
					Select2D:select()
					Select2D:finish()
				end
			end
			if CurrentTool and CurrentTool.Listeners.KeyUp then
				CurrentTool.Listeners.KeyUp(Sq5Mc)
			end
		end)
	)
	table.insert(
		Connections,
		UserInputService.InputEnded:Connect(function(fJ)
			if fJ.UserInputType == Enum.UserInputType.MouseButton1 then
				clicking = false
				if Select2D.enabled then
					Select2D:select()
					Select2D:finish()
				end
			end
		end)
	)
	table.insert(
		Connections,
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if input.UserInputType ~= Enum.UserInputType.Touch or touch_selection_input then
				return
			end
			if UserInputService:GetFocusedTextBox() or isPointerOverBTUI(input) then
				return
			end
			touch_selection_input = input
			touch_selection_start = getSelectionPointerPosition(input)
			last_touch_selection_time = tick()
			clicking = true
			if touch_selection_start then
				click_x, click_y = touch_selection_start.X, touch_selection_start.Y
			end
			updateSelectionTargetBox(input)
		end)
	)
	table.insert(
		Connections,
		UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch or input ~= touch_selection_input then
				return
			end
			local pointerPosition = getSelectionPointerPosition(input)
			if mobile_multi_select and touch_selection_start and pointerPosition and not Select2D.enabled then
				local moved = math.abs(pointerPosition.X - touch_selection_start.X) > 14 or math.abs(pointerPosition.Y - touch_selection_start.Y) > 14
				if moved then
					override_selection = true
					Select2D:start(input, touch_selection_start)
				end
			end
			updateSelectionTargetBox(input)
		end)
	)
	table.insert(
		Connections,
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch or input ~= touch_selection_input then
				return
			end
			clicking = false
			if Select2D.enabled then
				Select2D:select()
				Select2D:finish()
			else
				applyPointerSelection(input, true)
			end
			updateSelectionTargetBox(input)
			touch_selection_input = nil
			touch_selection_start = nil
			last_touch_selection_time = tick()
			if override_selection then
				override_selection = false
			end
		end)
	)
	table.insert(
		Connections,
		Mouse.Button1Down:Connect(function()
			if touch_selection_input or tick() - last_touch_selection_time < 0.25 then
				return
			end
			clicking = true
			click_x, click_y = Mouse.X, Mouse.Y
			if selecting then
				return
			end
			if CurrentTool and CurrentTool.Listeners.Button1Down then
				CurrentTool.Listeners.Button1Down()
			end
		end)
	)
	table.insert(
		Connections,
		Mouse.Move:Connect(function()
			if touch_selection_input then
				return
			end
			if
				not override_selection
				and not Select2D.enabled
				and clicking
				and selecting
				and (click_x ~= Mouse.X or click_y ~= Mouse.Y)
			then
				Select2D:start()
			end
			updateSelectionTargetBox()
			if CurrentTool and CurrentTool.Listeners.Move then
				CurrentTool.Listeners.Move()
			end
			if override_selection then
				override_selection = false
			end
		end)
	)
	table.insert(
		Connections,
		Mouse.Button1Up:Connect(function()
			if touch_selection_input or tick() - last_touch_selection_time < 0.25 then
				return
			end
			clicking = false
			applyPointerSelection(nil, false)
			updateSelectionTargetBox()
			if CurrentTool and CurrentTool.Listeners.Button1Up then
				CurrentTool.Listeners.Button1Up()
			end
			if override_selection then
				override_selection = false
			end
		end)
	)
	table.insert(
		Connections,
		Mouse.Button2Down:Connect(function()
			if CurrentTool and CurrentTool.Listeners.Button2Down then
				CurrentTool.Listeners.Button2Down()
			end
		end)
	)
	table.insert(
		Connections,
		Mouse.Button2Up:Connect(function()
			if CurrentTool and CurrentTool.Listeners.Button2Up then
				CurrentTool.Listeners.Button2Up()
			end
		end)
	)
end
function unequipBT()
	Mouse = nil
	if TargetBox then
		TargetBox:Destroy()
		TargetBox = nil
	end
	for aG3O, M6IbY in pairs(SelectionBoxes) do
		setp(M6IbY, "Parent", nil)
	end
	setp(Dock, "Visible", false)
	for vxWBA, is in pairs(Connections) do
		is:Disconnect()
		Connections[vxWBA] = nil
	end
	if CurrentTool and CurrentTool.Listeners.Unequipped then
		local okUnequip, errUnequip = xpcall(CurrentTool.Listeners.Unequipped, F3XTraceback)
		if not okUnequip then
			F3XWarn("Current tool unequip listener failed: " .. tostring(errUnequip))
		end
	end
end
local q = {
	{
		"Anchor",
		function()
			repeat
				task.wait()
			until _G.BTCoreEnv and _G.BTCoreEnv.tool and _G.BTCoreEnv.tool.CoreReady
			setfenv(1, _G.BTCoreEnv.tool)
			Tools.Anchor = {}
			Tools.Anchor.Connections = {}
			Tools.Anchor.State = {
				anchored = nil,
			}
			Tools.Anchor.Listeners = {}
			setp(Tools.Anchor, "Color", BrickColor.new("Really black"))
			Tools.Anchor.Listeners.Equipped = function()
				local _l = Tools.Anchor
				_l.State.PreviousSelectionBoxColor = SelectionBoxColor
				SelectionBoxColor = _l.Color
				updateSelectionBoxColor()
				_l:showGUI();
				(coroutine.wrap(function()
					updater_on = true
					_l.Updater = function()
						updater_on = false
					end
					while task.wait(0.1) and updater_on do
						if CurrentTool == _l then
							local IVdNQHj = nil
							for l, icedjl in pairs(Selection.Items) do
								if l == 1 then
									IVdNQHj = icedjl.Anchored
								elseif IVdNQHj ~= icedjl.Anchored then
									IVdNQHj = nil
								end
							end
							_l.State.anchored = IVdNQHj
							if _l.GUI and _l.GUI.Visible then
								_l:updateGUI()
							end
						end
					end
				end))()
				_l.Connections.EnterButtonListener = Mouse.KeyDown:Connect(function(H)
					local H = H:lower()
					local d1J = H:byte()
					if d1J == 13 then
						if _l.State.anchored == true then
							_l:unanchor()
						elseif _l.State.anchored == false then
							_l:anchor()
						elseif _l.State.anchored == nil then
							_l:anchor()
						end
					end
				end)
			end
			Tools.Anchor.startHistoryRecord = function(zVUtED)
				if zVUtED.State.HistoryRecord then
					zVUtED.State.HistoryRecord = nil
				end
				zVUtED.State.HistoryRecord = {
					targets = Support.CloneTable(Selection.Items),
					initial_positions = {},
					terminal_positions = {},
					initial_anchors = {},
					terminal_anchors = {},
					unapply = function(zVUtED)
						Selection:clear()
						for d_UB9, FysQC in pairs(zVUtED.targets) do
							if FysQC then
								setp(FysQC, "RotVelocity", Vector3.new(0, 0, 0))
								setp(FysQC, "Velocity", Vector3.new(0, 0, 0))
								setp(FysQC, "CFrame", zVUtED.initial_positions[FysQC])
								setp(FysQC, "Anchored", zVUtED.initial_anchors[FysQC])
								FysQC:MakeJoints()
								Selection:add(FysQC)
							end
						end
					end,
					apply = function(zVUtED)
						Selection:clear()
						for AnG, yV8C in pairs(zVUtED.targets) do
							if yV8C then
								setp(yV8C, "RotVelocity", Vector3.new(0, 0, 0))
								setp(yV8C, "Velocity", Vector3.new(0, 0, 0))
								setp(yV8C, "CFrame", zVUtED.terminal_positions[yV8C])
								setp(yV8C, "Anchored", zVUtED.terminal_anchors[yV8C])
								yV8C:MakeJoints()
								Selection:add(yV8C)
							end
						end
					end,
				}
				for bt4Y, sZNR in pairs(zVUtED.State.HistoryRecord.targets) do
					if sZNR then
						zVUtED.State.HistoryRecord.initial_anchors[sZNR] = sZNR.Anchored
						zVUtED.State.HistoryRecord.initial_positions[sZNR] = sZNR.CFrame
					end
				end
			end
			Tools.Anchor.finishHistoryRecord = function(WAIOz7)
				if not WAIOz7.State.HistoryRecord then
					return
				end
				for ICLcYduB, oXFiMbj in pairs(WAIOz7.State.HistoryRecord.targets) do
					if oXFiMbj then
						WAIOz7.State.HistoryRecord.terminal_anchors[oXFiMbj] = oXFiMbj.Anchored
						WAIOz7.State.HistoryRecord.terminal_positions[oXFiMbj] = oXFiMbj.CFrame
					end
				end
				History:add(WAIOz7.State.HistoryRecord)
				WAIOz7.State.HistoryRecord = nil
			end
			Tools.Anchor.anchor = function(i5L)
				i5L:startHistoryRecord()
				for vYC4bdrc, QAFVQu14 in pairs(Selection.Items) do
					setp(QAFVQu14, "Anchored", true)
					QAFVQu14:MakeJoints()
				end
				i5L:finishHistoryRecord()
			end
			Tools.Anchor.unanchor = function(DVx)
				DVx:startHistoryRecord()
				for r, Knh56 in pairs(Selection.Items) do
					setp(Knh56, "Anchored", false)
					setp(Knh56, "Velocity", Vector3.new(0, 0, 0))
					setp(Knh56, "RotVelocity", Vector3.new(0, 0, 0))
					Knh56:MakeJoints()
				end
				DVx:finishHistoryRecord()
			end
			Tools.Anchor.showGUI = function(DG90Rh)
				if not DG90Rh.GUI then
					local mBxSp8y2 = DFb100j.BTAnchorToolGUI:Clone()
					setp(mBxSp8y2, "Parent", UI)
					mBxSp8y2.Status.Anchored.Button.MouseButton1Down:Connect(function()
						DG90Rh:anchor()
					end)
					mBxSp8y2.Status.Unanchored.Button.MouseButton1Down:Connect(function()
						DG90Rh:unanchor()
					end)
					DG90Rh.GUI = mBxSp8y2
				end
				setp(DG90Rh.GUI, "Visible", true)
			end
			Tools.Anchor.updateGUI = function(W09NOBin)
				if not W09NOBin.GUI then
					return
				end
				local Tek7X = W09NOBin.GUI
				if W09NOBin.State.anchored == nil then
					setp(Tek7X.Status.Anchored.Background, "Image", Assets.LightSlantedRectangle)
					setp(Tek7X.Status.Anchored.SelectedIndicator, "BackgroundTransparency", 1)
					setp(Tek7X.Status.Unanchored.Background, "Image", Assets.LightSlantedRectangle)
					setp(Tek7X.Status.Unanchored.SelectedIndicator, "BackgroundTransparency", 1)
				elseif W09NOBin.State.anchored == true then
					setp(Tek7X.Status.Anchored.Background, "Image", Assets.DarkSlantedRectangle)
					setp(Tek7X.Status.Anchored.SelectedIndicator, "BackgroundTransparency", 0)
					setp(Tek7X.Status.Unanchored.Background, "Image", Assets.LightSlantedRectangle)
					setp(Tek7X.Status.Unanchored.SelectedIndicator, "BackgroundTransparency", 1)
				elseif W09NOBin.State.anchored == false then
					setp(Tek7X.Status.Anchored.Background, "Image", Assets.LightSlantedRectangle)
					setp(Tek7X.Status.Anchored.SelectedIndicator, "BackgroundTransparency", 1)
					setp(Tek7X.Status.Unanchored.Background, "Image", Assets.DarkSlantedRectangle)
					setp(Tek7X.Status.Unanchored.SelectedIndicator, "BackgroundTransparency", 0)
				end
			end
			Tools.Anchor.hideGUI = function(Wzzgk)
				if Wzzgk.GUI then
					setp(Wzzgk.GUI, "Visible", false)
				end
			end
			Tools.Anchor.Listeners.Unequipped = function()
				local anaV = Tools.Anchor
				if anaV.Updater then
					anaV.Updater()
					anaV.Updater = nil
				end
				anaV:hideGUI()
				for gwxp, Qf in pairs(anaV.Connections) do
					Qf:Disconnect()
					anaV.Connections[gwxp] = nil
				end
				SelectionBoxColor = anaV.State.PreviousSelectionBoxColor
				updateSelectionBoxColor()
			end
			Tools.Anchor.Loaded = true
		end,
	},
	{
		"Collision",
		function()
			repeat
				task.wait()
			until _G.BTCoreEnv and _G.BTCoreEnv.tool and _G.BTCoreEnv.tool.CoreReady
			setfenv(1, _G.BTCoreEnv.tool)
			Tools.Collision = {}
			Tools.Collision.Connections = {}
			Tools.Collision.State = {
				colliding = nil,
			}
			Tools.Collision.Listeners = {}
			setp(Tools.Collision, "Color", BrickColor.new("Really black"))
			Tools.Collision.Listeners.Equipped = function()
				local sRf = Tools.Collision
				sRf.State.PreviousSelectionBoxColor = SelectionBoxColor
				SelectionBoxColor = sRf.Color
				updateSelectionBoxColor()
				sRf:showGUI();
				(coroutine.wrap(function()
					updater_on = true
					sRf.Updater = function()
						updater_on = false
					end
					while task.wait(0.1) and updater_on do
						if CurrentTool == sRf then
							local Ir = nil
							for On7i, GAQjek in pairs(Selection.Items) do
								if On7i == 1 then
									Ir = GAQjek.CanCollide
								elseif Ir ~= GAQjek.CanCollide then
									Ir = nil
								end
							end
							sRf.State.colliding = Ir
							if sRf.GUI and sRf.GUI.Visible then
								sRf:updateGUI()
							end
						end
					end
				end))()
				sRf.Connections.EnterButtonListener = Mouse.KeyDown:Connect(function(b)
					local b = b:lower()
					local t = b:byte()
					if t == 13 then
						if sRf.State.colliding == true then
							sRf:disable()
						elseif sRf.State.colliding == false then
							sRf:enable()
						elseif sRf.State.colliding == nil then
							sRf:enable()
						end
					end
				end)
			end
			Tools.Collision.startHistoryRecord = function(nUqS)
				if nUqS.State.HistoryRecord then
					nUqS.State.HistoryRecord = nil
				end
				nUqS.State.HistoryRecord = {
					targets = Support.CloneTable(Selection.Items),
					initial_collide = {},
					terminal_collide = {},
					initial_cframe = {},
					terminal_cframe = {},
					unapply = function(nUqS)
						Selection:clear()
						for wTVytu, VZjB in pairs(nUqS.targets) do
							if VZjB then
								setp(VZjB, "CanCollide", nUqS.initial_collide[VZjB])
								setp(VZjB, "CFrame", nUqS.initial_cframe[VZjB])
								VZjB:MakeJoints()
								Selection:add(VZjB)
							end
						end
					end,
					apply = function(nUqS)
						Selection:clear()
						for Qv_pumH, Rm in pairs(nUqS.targets) do
							if Rm then
								setp(Rm, "CanCollide", nUqS.terminal_collide[Rm])
								setp(Rm, "CFrame", nUqS.terminal_cframe[Rm])
								Rm:MakeJoints()
								Selection:add(Rm)
							end
						end
					end,
				}
				for Wq2v, G in pairs(nUqS.State.HistoryRecord.targets) do
					if G then
						nUqS.State.HistoryRecord.initial_collide[G] = G.CanCollide
						nUqS.State.HistoryRecord.initial_cframe[G] = G.CFrame
					end
				end
			end
			Tools.Collision.finishHistoryRecord = function(e5kmv)
				if not e5kmv.State.HistoryRecord then
					return
				end
				for PSNhu, mAaO3eJ in pairs(e5kmv.State.HistoryRecord.targets) do
					if mAaO3eJ then
						e5kmv.State.HistoryRecord.terminal_collide[mAaO3eJ] = mAaO3eJ.CanCollide
						e5kmv.State.HistoryRecord.terminal_cframe[mAaO3eJ] = mAaO3eJ.CFrame
					end
				end
				History:add(e5kmv.State.HistoryRecord)
				e5kmv.State.HistoryRecord = nil
			end
			Tools.Collision.enable = function(EO)
				EO:startHistoryRecord()
				for Qw9, GMgV5kh in pairs(Selection.Items) do
					setp(GMgV5kh, "CanCollide", true)
					GMgV5kh:MakeJoints()
				end
				EO:finishHistoryRecord()
			end
			Tools.Collision.disable = function(Shm)
				Shm:startHistoryRecord()
				for iIKY5x, fLF in pairs(Selection.Items) do
					setp(fLF, "CanCollide", false)
					fLF:MakeJoints()
				end
				Shm:finishHistoryRecord()
			end
			Tools.Collision.showGUI = function(eQ)
				if not eQ.GUI then
					local yGT7hv6 = DFb100j.BTCollisionToolGUI:Clone()
					setp(yGT7hv6, "Parent", UI)
					yGT7hv6.Status.On.Button.MouseButton1Down:Connect(function()
						eQ:enable()
					end)
					yGT7hv6.Status.Off.Button.MouseButton1Down:Connect(function()
						eQ:disable()
					end)
					eQ.GUI = yGT7hv6
				end
				setp(eQ.GUI, "Visible", true)
			end
			Tools.Collision.updateGUI = function(qG4fWn4a)
				if not qG4fWn4a.GUI then
					return
				end
				local Zkf = qG4fWn4a.GUI
				if qG4fWn4a.State.colliding == nil then
					setp(Zkf.Status.On.Background, "Image", Assets.LightSlantedRectangle)
					setp(Zkf.Status.On.SelectedIndicator, "BackgroundTransparency", 1)
					setp(Zkf.Status.Off.Background, "Image", Assets.LightSlantedRectangle)
					setp(Zkf.Status.Off.SelectedIndicator, "BackgroundTransparency", 1)
				elseif qG4fWn4a.State.colliding == true then
					setp(Zkf.Status.On.Background, "Image", Assets.DarkSlantedRectangle)
					setp(Zkf.Status.On.SelectedIndicator, "BackgroundTransparency", 0)
					setp(Zkf.Status.Off.Background, "Image", Assets.LightSlantedRectangle)
					setp(Zkf.Status.Off.SelectedIndicator, "BackgroundTransparency", 1)
				elseif qG4fWn4a.State.colliding == false then
					setp(Zkf.Status.On.Background, "Image", Assets.LightSlantedRectangle)
					setp(Zkf.Status.On.SelectedIndicator, "BackgroundTransparency", 1)
					setp(Zkf.Status.Off.Background, "Image", Assets.DarkSlantedRectangle)
					setp(Zkf.Status.Off.SelectedIndicator, "BackgroundTransparency", 0)
				end
			end
			Tools.Collision.hideGUI = function(N)
				if N.GUI then
					setp(N.GUI, "Visible", false)
				end
			end
			Tools.Collision.Listeners.Unequipped = function()
				local Bh = Tools.Collision
				if Bh.Updater then
					Bh.Updater()
					Bh.Updater = nil
				end
				Bh:hideGUI()
				for r42joJ, zl1g in pairs(Bh.Connections) do
					zl1g:Disconnect()
					Bh.Connections[r42joJ] = nil
				end
				SelectionBoxColor = Bh.State.PreviousSelectionBoxColor
				updateSelectionBoxColor()
			end
			Tools.Collision.Loaded = true
		end,
	},
	{
		"Material",
		function()
			repeat
				task.wait()
			until _G.BTCoreEnv and _G.BTCoreEnv.tool and _G.BTCoreEnv.tool.CoreReady
			setfenv(1, _G.BTCoreEnv.tool)
			Tools.Material = {}
			setp(Tools.Material, "Color", BrickColor.new("Bright violet"))
			Tools.Material.Connections = {}
			Tools.Material.State = {
				material = nil,
				reflectance_focused = false,
				transparency_focused = false,
			}
			Tools.Material.Listeners = {}
			Tools.Material.SpecialMaterialNames = {
				CorrodedMetal = "CORRODED METAL",
				DiamondPlate = "DIAMOND PLATE",
				SmoothPlastic = "SMOOTH PLASTIC",
				WoodPlanks = "WOOD PLANKS",
			}
			Tools.Material.Listeners.Equipped = function()
				local Cx = Tools.Material
				Cx.State.PreviousSelectionBoxColor = SelectionBoxColor
				SelectionBoxColor = Cx.Color
				updateSelectionBoxColor()
				Cx:showGUI();
				(coroutine.wrap(function()
					updater_on = true
					Cx.Updater = function()
						updater_on = false
					end
					while task.wait(0.1) and updater_on do
						if CurrentTool == Cx then
							local A6o, s2_, i6j = nil, nil, nil
							for oKC, Xzi2KU in pairs(Selection.Items) do
								if oKC == 1 then
									A6o = Xzi2KU.Material
									s2_ = Xzi2KU.Transparency
									i6j = Xzi2KU.Reflectance
								else
									if A6o ~= Xzi2KU.Material then
										A6o = nil
									end
									if i6j ~= Xzi2KU.Reflectance then
										i6j = nil
									end
									if s2_ ~= Xzi2KU.Transparency then
										s2_ = nil
									end
								end
							end
							Cx.State.material = A6o
							Cx.State.transparency = s2_
							Cx.State.reflectance = i6j
							if Cx.GUI and Cx.GUI.Visible then
								Cx:updateGUI()
							end
						end
					end
				end))()
			end
			Tools.Material.Listeners.Unequipped = function()
				local _c = Tools.Material
				if _c.Updater then
					_c.Updater()
					_c.Updater = nil
				end
				_c:hideGUI()
				for S, pI1x in pairs(_c.Connections) do
					pI1x:Disconnect()
					_c.Connections[S] = nil
				end
				SelectionBoxColor = _c.State.PreviousSelectionBoxColor
				updateSelectionBoxColor()
			end
			Tools.Material.startHistoryRecord = function(NgDx9_)
				if NgDx9_.State.HistoryRecord then
					NgDx9_.State.HistoryRecord = nil
				end
				NgDx9_.State.HistoryRecord = {
					targets = Support.CloneTable(Selection.Items),
					initial_material = {},
					terminal_material = {},
					initial_transparency = {},
					terminal_transparency = {},
					initial_reflectance = {},
					terminal_reflectance = {},
					unapply = function(NgDx9_)
						Selection:clear()
						for KzYaixt, i in pairs(NgDx9_.targets) do
							if i then
								setp(i, "Material", NgDx9_.initial_material[i])
								setp(i, "Transparency", NgDx9_.initial_transparency[i])
								setp(i, "Reflectance", NgDx9_.initial_reflectance[i])
								Selection:add(i)
							end
						end
					end,
					apply = function(NgDx9_)
						Selection:clear()
						for DM7, sBDh6v in pairs(NgDx9_.targets) do
							if sBDh6v then
								setp(sBDh6v, "Material", NgDx9_.terminal_material[sBDh6v])
								setp(sBDh6v, "Transparency", NgDx9_.terminal_transparency[sBDh6v])
								setp(sBDh6v, "Reflectance", NgDx9_.terminal_reflectance[sBDh6v])
								Selection:add(sBDh6v)
							end
						end
					end,
				}
				for siy_21f, wkUEOv in pairs(NgDx9_.State.HistoryRecord.targets) do
					if wkUEOv then
						NgDx9_.State.HistoryRecord.initial_material[wkUEOv] = wkUEOv.Material
						NgDx9_.State.HistoryRecord.initial_transparency[wkUEOv] = wkUEOv.Transparency
						NgDx9_.State.HistoryRecord.initial_reflectance[wkUEOv] = wkUEOv.Reflectance
					end
				end
			end
			Tools.Material.finishHistoryRecord = function(b)
				if not b.State.HistoryRecord then
					return
				end
				for s1sExxI, qR in pairs(b.State.HistoryRecord.targets) do
					if qR then
						b.State.HistoryRecord.terminal_material[qR] = qR.Material
						b.State.HistoryRecord.terminal_transparency[qR] = qR.Transparency
						b.State.HistoryRecord.terminal_reflectance[qR] = qR.Reflectance
					end
				end
				History:add(b.State.HistoryRecord)
				b.State.HistoryRecord = nil
			end
			Tools.Material.changeMaterial = function(KMeqP, y3tk)
				KMeqP:startHistoryRecord()
				for A, Iysi_9UF in pairs(Selection.Items) do
					pcall(function()
						setp(Iysi_9UF, "Material", y3tk)
					end)
				end
				KMeqP:finishHistoryRecord()
				if KMeqP.MaterialDropdown.open then
					KMeqP.MaterialDropdown:toggle()
				end
			end
			Tools.Material.changeTransparency = function(joAA, w)
				joAA:startHistoryRecord()
				for ta59, b_knq in pairs(Selection.Items) do
					setp(b_knq, "Transparency", w)
				end
				joAA:finishHistoryRecord()
			end
			Tools.Material.changeReflectance = function(J_AlR, _dqQ8fSw)
				J_AlR:startHistoryRecord()
				for onKnnPCx, WytqKWPI in pairs(Selection.Items) do
					setp(WytqKWPI, "Reflectance", _dqQ8fSw)
				end
				J_AlR:finishHistoryRecord()
			end
			Tools.Material.updateGUI = function(M)
				if not M.GUI then
					return
				end
				if #Selection.Items > 0 then
					setp(M.GUI, "Size", UDim2.new(0, 200, 0, 145))
					setp(M.GUI.MaterialOption, "Visible", true)
					setp(M.GUI.ReflectanceOption, "Visible", true)
					setp(M.GUI.TransparencyOption, "Visible", true)
					setp(M.GUI.SelectNote, "Visible", false)
					M.MaterialDropdown:selectOption(M.State.material and fmtEnum(M.State.material, M.SpecialMaterialNames) or "*")
					if not M.State.transparency_focused then
						M.GUI.TransparencyOption.TransparencyInput.TextBox.Text = M.State.transparency
							and tostring(Support.Round(M.State.transparency, 2))
							or "*"
					end
					if not M.State.reflectance_focused then
						M.GUI.ReflectanceOption.ReflectanceInput.TextBox.Text = M.State.reflectance
							and tostring(Support.Round(M.State.reflectance, 2))
							or "*"
					end
				else
					setp(M.GUI, "Size", UDim2.new(0, 200, 0, 62))
					setp(M.GUI.MaterialOption, "Visible", false)
					setp(M.GUI.ReflectanceOption, "Visible", false)
					setp(M.GUI.TransparencyOption, "Visible", false)
					setp(M.GUI.SelectNote, "Visible", true)
					M.MaterialDropdown:selectOption("")
					setp(M.GUI.TransparencyOption.TransparencyInput.TextBox, "Text", "")
					setp(M.GUI.ReflectanceOption.ReflectanceInput.TextBox, "Text", "")
				end
			end
			Tools.Material.showGUI = function(K4o_AriB)
				if not K4o_AriB.GUI then
					local MXcdGX = DFb100j.BTMaterialToolGUI:Clone()
					setp(MXcdGX, "Parent", UI)
					local R9 = createDropdown()
					K4o_AriB.MaterialDropdown = R9
					setp(R9.Frame, "Parent", MXcdGX.MaterialOption)
					setp(R9.Frame, "Position", UDim2.new(0, 50, 0, 0))
					setp(R9.Frame, "Size", UDim2.new(0, 130, 0, 25));
					addEnum(R9, Enum.Material, function(x)
						K4o_AriB:changeMaterial(x)
					end, K4o_AriB.SpecialMaterialNames)
					MXcdGX.TransparencyOption.TransparencyInput.TextButton.MouseButton1Down:Connect(function()
						K4o_AriB.State.transparency_focused = true
						MXcdGX.TransparencyOption.TransparencyInput.TextBox:CaptureFocus()
					end)
					MXcdGX.TransparencyOption.TransparencyInput.TextBox.FocusLost:Connect(function(n9zj)
						local sWU = tonumber(MXcdGX.TransparencyOption.TransparencyInput.TextBox.Text)
						if sWU then
							if sWU > 1 then
								sWU = 1
							elseif sWU < 0 then
								sWU = 0
							end
							K4o_AriB:changeTransparency(sWU)
						end
						K4o_AriB.State.transparency_focused = false
					end)
					MXcdGX.ReflectanceOption.ReflectanceInput.TextButton.MouseButton1Down:Connect(function()
						K4o_AriB.State.reflectance_focused = true
						MXcdGX.ReflectanceOption.ReflectanceInput.TextBox:CaptureFocus()
					end)
					MXcdGX.ReflectanceOption.ReflectanceInput.TextBox.FocusLost:Connect(function(JoZ28)
						local hBfySU = tonumber(MXcdGX.ReflectanceOption.ReflectanceInput.TextBox.Text)
						if hBfySU then
							if hBfySU > 1 then
								hBfySU = 1
							elseif hBfySU < 0 then
								hBfySU = 0
							end
							K4o_AriB:changeReflectance(hBfySU)
						end
						K4o_AriB.State.reflectance_focused = false
					end)
					K4o_AriB.GUI = MXcdGX
				end
				setp(K4o_AriB.GUI, "Visible", true)
			end
			Tools.Material.hideGUI = function(Uvmu)
				if Uvmu.GUI then
					setp(Uvmu.GUI, "Visible", false)
				end
			end
			Tools.Material.Loaded = true
		end,
	},
	{
		"Mesh",
		function()
			repeat
				task.wait()
			until _G.BTCoreEnv and _G.BTCoreEnv.tool and _G.BTCoreEnv.tool.CoreReady
			setfenv(1, _G.BTCoreEnv.tool)
			Tools.Mesh = {}
			setp(Tools.Mesh, "Color", BrickColor.new("Bright violet"))
			Tools.Mesh.State = {}
			Tools.Mesh.Connections = {}
			Tools.Mesh.Listeners = {}
			Tools.Mesh.Listeners.Equipped = function()
				local _ = Tools.Mesh
				_.State.PreviousSelectionBoxColor = SelectionBoxColor
				SelectionBoxColor = _.Color
				updateSelectionBoxColor()
				_:showGUI();
				(coroutine.wrap(function()
					updater_on = true
					_.Updater = function()
						updater_on = false
					end
					while task.wait(0.1) and updater_on do
						if CurrentTool == _ then
							if _.GUI and _.GUI.Visible then
								_:updateGUI()
							end
						end
					end
				end))()
			end
			Tools.Mesh.Listeners.Unequipped = function()
				local SeHRNaX = Tools.Mesh
				if SeHRNaX.Updater then
					SeHRNaX.Updater()
					SeHRNaX.Updater = nil
				end
				SeHRNaX:hideGUI()
				for kH7r, HOB in pairs(SeHRNaX.Connections) do
					HOB:Disconnect()
					SeHRNaX.Connections[kH7r] = nil
				end
				SelectionBoxColor = SeHRNaX.State.PreviousSelectionBoxColor
				updateSelectionBoxColor()
			end
			Tools.Mesh.TypeLabels = {
				Brick = "BLOCK",
				FileMesh = "FILE",
				Torso = "TRAPEZOID",
			}
			Tools.Mesh.TypeDropdownLabels = mapEnum(Enum.MeshType, Tools.Mesh.TypeLabels)
			Tools.Mesh.changeType = function(RCc, vLr4f)
				local Pad5yPd = {}
				for GAeGfl, TYRl in pairs(Selection.Items) do
					local uoRdE7k = Support.GetChildOfClass(TYRl, "SpecialMesh")
					if uoRdE7k then
						table.insert(Pad5yPd, uoRdE7k)
					end
				end
				RCc:startHistoryRecord(Pad5yPd)
				for k5, F_cOghKV in pairs(Pad5yPd) do
					setp(F_cOghKV, "MeshType", vLr4f)
				end
				RCc:finishHistoryRecord()
				if RCc.TypeDropdown.open then
					RCc.TypeDropdown:toggle()
				end
				RCc:finishHistoryRecord()
			end
			Tools.Mesh.updateGUI = function(Ytf)
				if not Ytf.GUI then
					return
				end
				local VAKgo = Ytf.GUI
				if #Selection.Items > 0 then
					local QB = {}
					for cMk1b62p, iAIf in pairs(Selection.Items) do
						local Am0WLx = Support.GetChildOfClass(iAIf, "SpecialMesh")
						if Am0WLx then
							table.insert(QB, Am0WLx)
						end
					end
					local y8zF, T, fT1
					local lMKfa, P25nFo1, MwI, t, rcbgP, nwoQ, pazH2Fh, GZ2PbO, y
					if #QB == #Selection.Items then
						y8zF = false
						T = true
					elseif #QB == 0 then
						y8zF = true
						T = false
					else
						y8zF = true
						T = true
					end
					if #QB > 0 then
						show_type = true
						for TDJshmj, LTJy0 in pairs(QB) do
							if TDJshmj == 1 then
								lMKfa = LTJy0.MeshType
								P25nFo1, MwI, t = LTJy0.Scale.x, LTJy0.Scale.y, LTJy0.Scale.z
								rcbgP = LTJy0.MeshId:lower()
								nwoQ = LTJy0.TextureId:lower()
								pazH2Fh, GZ2PbO, y = LTJy0.VertexColor.x, LTJy0.VertexColor.y, LTJy0.VertexColor.z
							else
								if lMKfa ~= LTJy0.MeshType then
									lMKfa = nil
								end
								if P25nFo1 ~= LTJy0.Scale.x then
									P25nFo1 = nil
								end
								if MwI ~= LTJy0.Scale.y then
									MwI = nil
								end
								if t ~= LTJy0.Scale.z then
									t = nil
								end
								if rcbgP ~= LTJy0.MeshId:lower() then
									rcbgP = nil
								end
								if nwoQ ~= LTJy0.TextureId:lower() then
									nwoQ = nil
								end
								if pazH2Fh ~= LTJy0.VertexColor.x then
									pazH2Fh = nil
								end
								if GZ2PbO ~= LTJy0.VertexColor.y then
									GZ2PbO = nil
								end
								if y ~= LTJy0.VertexColor.z then
									y = nil
								end
							end
							if LTJy0.MeshType == Enum.MeshType.FileMesh then
								fT1 = true
							end
						end
						Ytf.State.mesh_tint = pazH2Fh and GZ2PbO and y and Color3.new(pazH2Fh, GZ2PbO, y) or nil
						if fT1 and y8zF and T then
							setp(Ytf.GUI.AddButton, "Visible", true)
							setp(Ytf.GUI.RemoveButton, "Visible", true)
							setp(Ytf.GUI.MeshIDOption, "Visible", true)
							setp(Ytf.GUI.TextureIDOption, "Visible", true)
							setp(Ytf.GUI.ScaleOption, "Visible", true)
							setp(Ytf.GUI.TintOption, "Visible", true)
							setp(Ytf.GUI.TypeOption, "Visible", true)
							setp(Ytf.GUI.TypeOption, "Position", UDim2.new(0, 14, 0, 65))
							setp(Ytf.GUI.ScaleOption, "Position", UDim2.new(0, 0, 0, 100))
							setp(Ytf.GUI.MeshIDOption, "Position", UDim2.new(0, 14, 0, 135))
							setp(Ytf.GUI.TextureIDOption, "Position", UDim2.new(0, 14, 0, 165))
							setp(Ytf.GUI.TintOption, "Position", UDim2.new(0, 0, 0, 200))
							setp(Ytf.GUI, "Size", UDim2.new(0, 200, 0, 265))
						elseif fT1 and not y8zF and T then
							setp(Ytf.GUI.AddButton, "Visible", false)
							setp(Ytf.GUI.RemoveButton, "Visible", true)
							setp(Ytf.GUI.MeshIDOption, "Visible", true)
							setp(Ytf.GUI.TextureIDOption, "Visible", true)
							setp(Ytf.GUI.ScaleOption, "Visible", true)
							setp(Ytf.GUI.TintOption, "Visible", true)
							setp(Ytf.GUI.TypeOption, "Visible", true)
							setp(Ytf.GUI.TypeOption, "Position", UDim2.new(0, 14, 0, 30))
							setp(Ytf.GUI.ScaleOption, "Position", UDim2.new(0, 0, 0, 65))
							setp(Ytf.GUI.MeshIDOption, "Position", UDim2.new(0, 14, 0, 100))
							setp(Ytf.GUI.TextureIDOption, "Position", UDim2.new(0, 14, 0, 130))
							setp(Ytf.GUI.TintOption, "Position", UDim2.new(0, 0, 0, 165))
							setp(Ytf.GUI, "Size", UDim2.new(0, 200, 0, 230))
						elseif not fT1 and y8zF and T then
							setp(Ytf.GUI.AddButton, "Visible", true)
							setp(Ytf.GUI.RemoveButton, "Visible", true)
							setp(Ytf.GUI.MeshIDOption, "Visible", false)
							setp(Ytf.GUI.TextureIDOption, "Visible", false)
							setp(Ytf.GUI.ScaleOption, "Visible", true)
							setp(Ytf.GUI.TintOption, "Visible", false)
							setp(Ytf.GUI.TypeOption, "Visible", true)
							setp(Ytf.GUI.TypeOption, "Position", UDim2.new(0, 14, 0, 65))
							setp(Ytf.GUI.ScaleOption, "Position", UDim2.new(0, 0, 0, 100))
							setp(Ytf.GUI, "Size", UDim2.new(0, 200, 0, 165))
						elseif not fT1 and not y8zF and T then
							setp(Ytf.GUI.AddButton, "Visible", false)
							setp(Ytf.GUI.RemoveButton, "Visible", true)
							setp(Ytf.GUI.MeshIDOption, "Visible", false)
							setp(Ytf.GUI.TextureIDOption, "Visible", false)
							setp(Ytf.GUI.ScaleOption, "Visible", true)
							setp(Ytf.GUI.TintOption, "Visible", false)
							setp(Ytf.GUI.TypeOption, "Visible", true)
							setp(Ytf.GUI.TypeOption, "Position", UDim2.new(0, 14, 0, 30))
							setp(Ytf.GUI.ScaleOption, "Position", UDim2.new(0, 0, 0, 65))
							setp(Ytf.GUI, "Size", UDim2.new(0, 200, 0, 130))
						end
						if not Ytf.State.mesh_id_focused then
							setp(Ytf.GUI.MeshIDOption.TextBox, "Text", rcbgP and (rcbgP:match("%?id=([0-9]+)") or "") or "*")
						end
						if not Ytf.State.texture_id_focused then
							setp(Ytf.GUI.TextureIDOption.TextBox, "Text", nwoQ and (nwoQ:match("%?id=([0-9]+)") or "") or "*")
						end
						Ytf.TypeDropdown:selectOption(lMKfa and (Ytf.TypeDropdownLabels[lMKfa] or fmtEnum(lMKfa, Ytf.TypeLabels)) or "*")
						if not Ytf.State.scale_x_focused then
							setp(Ytf.GUI.ScaleOption.XInput.TextBox, "Text", P25nFo1 and Support.Round(P25nFo1, 2) or "*")
						end
						if not Ytf.State.scale_y_focused then
							setp(Ytf.GUI.ScaleOption.YInput.TextBox, "Text", MwI and Support.Round(MwI, 2) or "*")
						end
						if not Ytf.State.scale_z_focused then
							setp(Ytf.GUI.ScaleOption.ZInput.TextBox, "Text", t and Support.Round(t, 2) or "*")
						end
						if not Ytf.State.tint_r_focused then
							setp(Ytf.GUI.TintOption.RInput.TextBox, "Text", pazH2Fh and Support.Round(pazH2Fh * 255, 0) or "*")
						end
						if not Ytf.State.tint_g_focused then
							setp(Ytf.GUI.TintOption.GInput.TextBox, "Text", GZ2PbO and Support.Round(GZ2PbO * 255, 0) or "*")
						end
						if not Ytf.State.tint_b_focused then
							setp(Ytf.GUI.TintOption.BInput.TextBox, "Text", y and Support.Round(y * 255, 0) or "*")
						end
					else
						setp(Ytf.GUI.AddButton, "Visible", true)
						setp(Ytf.GUI.RemoveButton, "Visible", false)
						setp(Ytf.GUI.MeshIDOption, "Visible", false)
						setp(Ytf.GUI.TextureIDOption, "Visible", false)
						setp(Ytf.GUI.ScaleOption, "Visible", false)
						setp(Ytf.GUI.TintOption, "Visible", false)
						setp(Ytf.GUI.TypeOption, "Visible", false)
						setp(Ytf.GUI, "Size", UDim2.new(0, 200, 0, 62))
					end
					setp(Ytf.GUI.SelectNote, "Visible", false)
				else
					setp(Ytf.GUI.AddButton, "Visible", false)
					setp(Ytf.GUI.RemoveButton, "Visible", false)
					setp(Ytf.GUI.MeshIDOption, "Visible", false)
					setp(Ytf.GUI.TextureIDOption, "Visible", false)
					setp(Ytf.GUI.ScaleOption, "Visible", false)
					setp(Ytf.GUI.TintOption, "Visible", false)
					setp(Ytf.GUI.TypeOption, "Visible", false)
					setp(Ytf.GUI.SelectNote, "Visible", true)
					setp(Ytf.GUI, "Size", UDim2.new(0, 200, 0, 55))
				end
			end
			Tools.Mesh.showGUI = function(N)
				if not N.GUI then
					local Ns = DFb100j.BTMeshToolGUI:Clone()
					setp(Ns, "Parent", UI)
					Ns.AddButton.Button.MouseButton1Up:Connect(function()
						N:addMesh()
					end)
					Ns.RemoveButton.Button.MouseButton1Up:Connect(function()
						N:removeMesh()
					end)
					local ZOvR1 = createDropdown()
					N.TypeDropdown = ZOvR1
					setp(ZOvR1.Frame, "Parent", Ns.TypeOption)
					setp(ZOvR1.Frame, "Position", UDim2.new(0, 40, 0, 0))
					setp(ZOvR1.Frame, "Size", UDim2.new(1, -40, 0, 25));
					addEnum(ZOvR1, Enum.MeshType, function(x)
						N:changeType(x)
					end, N.TypeLabels)
					Ns.ScaleOption.XInput.TextButton.MouseButton1Down:Connect(function()
						N.State.scale_x_focused = true
						Ns.ScaleOption.XInput.TextBox:CaptureFocus()
					end)
					Ns.ScaleOption.XInput.TextBox.FocusLost:Connect(function(L75)
						local zh = tonumber(Ns.ScaleOption.XInput.TextBox.Text)
						if zh then
							N:changeScale("x", zh)
						end
						N.State.scale_x_focused = false
					end)
					Ns.ScaleOption.YInput.TextButton.MouseButton1Down:Connect(function()
						N.State.scale_y_focused = true
						Ns.ScaleOption.YInput.TextBox:CaptureFocus()
					end)
					Ns.ScaleOption.YInput.TextBox.FocusLost:Connect(function(v)
						local Il05 = tonumber(Ns.ScaleOption.YInput.TextBox.Text)
						if Il05 then
							N:changeScale("y", Il05)
						end
						N.State.scale_y_focused = false
					end)
					Ns.ScaleOption.ZInput.TextButton.MouseButton1Down:Connect(function()
						N.State.scale_z_focused = true
						Ns.ScaleOption.ZInput.TextBox:CaptureFocus()
					end)
					Ns.ScaleOption.ZInput.TextBox.FocusLost:Connect(function(d0W)
						local b = tonumber(Ns.ScaleOption.ZInput.TextBox.Text)
						if b then
							N:changeScale("z", b)
						end
						N.State.scale_z_focused = false
					end)
					Ns.MeshIDOption.TextButton.MouseButton1Down:Connect(function()
						N.State.mesh_id_focused = true
						Ns.MeshIDOption.TextBox:CaptureFocus()
					end)
					Ns.MeshIDOption.TextBox.FocusLost:Connect(function(dG)
						local wF9WF = Ns.MeshIDOption.TextBox.Text
						local b097 = tonumber(wF9WF) or (wF9WF:lower()):match("%?id=([0-9]+)")
						if b097 then
							N:changeMesh(b097)
						end
						N.State.mesh_id_focused = false
					end)
					Ns.TextureIDOption.TextButton.MouseButton1Down:Connect(function()
						N.State.texture_id_focused = true
						Ns.TextureIDOption.TextBox:CaptureFocus()
					end)
					Ns.TextureIDOption.TextBox.FocusLost:Connect(function(Qu1)
						local r6 = Ns.TextureIDOption.TextBox.Text
						local DOx = tonumber(r6) or (r6:lower()):match("%?id=([0-9]+)")
						if DOx then
							N:changeTexture(DOx)
						end
						N.State.texture_id_focused = false
					end)
					Ns.TintOption.RInput.TextButton.MouseButton1Down:Connect(function()
						N.State.tint_r_focused = true
						Ns.TintOption.RInput.TextBox:CaptureFocus()
					end)
					Ns.TintOption.RInput.TextBox.FocusLost:Connect(function(sQe35a)
						local p2 = tonumber(Ns.TintOption.RInput.TextBox.Text)
						if p2 then
							if p2 > 255 then
								p2 = 255
							elseif p2 < 0 then
								p2 = 0
							end
							N:changeTint("r", p2 / 255)
						end
						N.State.tint_r_focused = false
					end)
					Ns.TintOption.GInput.TextButton.MouseButton1Down:Connect(function()
						N.State.tint_g_focused = true
						Ns.TintOption.GInput.TextBox:CaptureFocus()
					end)
					Ns.TintOption.GInput.TextBox.FocusLost:Connect(function(TN)
						local vtk = tonumber(Ns.TintOption.GInput.TextBox.Text)
						if vtk then
							if vtk > 255 then
								vtk = 255
							elseif vtk < 0 then
								vtk = 0
							end
							N:changeTint("g", vtk / 255)
						end
						N.State.tint_g_focused = false
					end)
					Ns.TintOption.BInput.TextButton.MouseButton1Down:Connect(function()
						N.State.tint_b_focused = true
						Ns.TintOption.BInput.TextBox:CaptureFocus()
					end)
					Ns.TintOption.BInput.TextBox.FocusLost:Connect(function(ENKi)
						local HgWdXJXD = tonumber(Ns.TintOption.BInput.TextBox.Text)
						if HgWdXJXD then
							if HgWdXJXD > 255 then
								HgWdXJXD = 255
							elseif HgWdXJXD < 0 then
								HgWdXJXD = 0
							end
							N:changeTint("b", HgWdXJXD / 255)
						end
						N.State.tint_b_focused = false
					end)
					Ns.TintOption.HSVPicker.MouseButton1Up:Connect(function()
						ColorPicker:start(function(...)
							local wiugbQS = {
								...,
							}
							if #wiugbQS == 3 then
								local Cz5 = {}
								for UfgAV, LO0nqS in pairs(Selection.Items) do
									local PIht9 = Support.GetChildOfClass(LO0nqS, "SpecialMesh")
									if PIht9 then
										table.insert(Cz5, PIht9)
									end
								end
								N:startHistoryRecord(Cz5)
								for bn, A666l08 in pairs(Cz5) do
									setp(A666l08, "VertexColor", Vector3.new(Support.HSVToRGB(...)))
								end
								N:finishHistoryRecord()
							end
						end, N.State.mesh_tint)
					end)
					N.GUI = Ns
				end
				setp(N.GUI, "Visible", true)
			end
			Tools.Mesh.addMesh = function(R02tO)
				local oVO = {
					apply = function(R02tO)
						Selection:clear()
						for r, sZyXLp in pairs(R02tO.meshes) do
							setp(sZyXLp, "Parent", R02tO.mesh_parents[sZyXLp])
							Selection:add(sZyXLp.Parent)
						end
					end,
					unapply = function(R02tO)
						Selection:clear()
						for nHUmh, VEw8 in pairs(R02tO.meshes) do
							Selection:add(VEw8.Parent)
							setp(VEw8, "Parent", nil)
						end
					end,
				}
				local X0NOlR5 = {}
				local drv = {}
				for QAD, R6Ky in pairs(Selection.Items) do
					local vq5u9jrx = Support.GetChildOfClass(R6Ky, "SpecialMesh")
					if not vq5u9jrx then
						local vq5u9jrx = (RbxUtility.Create("SpecialMesh"))({
							Parent = R6Ky,
							MeshType = Enum.MeshType.Brick,
						})
						table.insert(X0NOlR5, vq5u9jrx)
						drv[vq5u9jrx] = R6Ky
					end
				end
				oVO.meshes = X0NOlR5
				oVO.mesh_parents = drv
				History:add(oVO)
			end
			Tools.Mesh.removeMesh = function(kNsSSMzG)
				local ZcV = {
					apply = function(kNsSSMzG)
						Selection:clear()
						for y6z6ip, v in pairs(kNsSSMzG.meshes) do
							Selection:add(v.Parent)
							setp(v, "Parent", nil)
						end
					end,
					unapply = function(kNsSSMzG)
						Selection:clear()
						for Bu, _TI in pairs(kNsSSMzG.meshes) do
							setp(_TI, "Parent", kNsSSMzG.mesh_parents[_TI])
							Selection:add(_TI.Parent)
						end
					end,
				}
				local WiZA = {}
				local K4SQ1h2e = {}
				for YE7, Q2e in pairs(Selection.Items) do
					local z = Support.GetChildrenOfClass(Q2e, "SpecialMesh")
					for YE7, Cy in pairs(z) do
						table.insert(WiZA, Cy)
						K4SQ1h2e[Cy] = Cy.Parent
						setp(Cy, "Parent", nil)
					end
				end
				ZcV.meshes = WiZA
				ZcV.mesh_parents = K4SQ1h2e
				History:add(ZcV)
			end
			Tools.Mesh.startHistoryRecord = function(ZhG, ARBIKz)
				if ZhG.State.HistoryRecord then
					ZhG.State.HistoryRecord = nil
				end
				ZhG.State.HistoryRecord = {
					targets = Support.CloneTable(ARBIKz),
					initial_type = {},
					terminal_type = {},
					initial_mesh = {},
					terminal_mesh = {},
					initial_texture = {},
					terminal_texture = {},
					initial_scale = {},
					terminal_scale = {},
					initial_tint = {},
					terminal_tint = {},
					unapply = function(ZhG)
						Selection:clear()
						for p7, j in pairs(ZhG.targets) do
							if j then
								Selection:add(j.Parent)
								setp(j, "MeshType", ZhG.initial_type[j])
								setp(j, "MeshId", ZhG.initial_mesh[j])
								setp(j, "TextureId", ZhG.initial_texture[j])
								setp(j, "Scale", ZhG.initial_scale[j])
								setp(j, "VertexColor", ZhG.initial_tint[j])
							end
						end
					end,
					apply = function(ZhG)
						Selection:clear()
						for zbC2yHd0, I in pairs(ZhG.targets) do
							if I then
								Selection:add(I.Parent)
								setp(I, "MeshType", ZhG.terminal_type[I])
								setp(I, "MeshId", ZhG.terminal_mesh[I])
								setp(I, "TextureId", ZhG.terminal_texture[I])
								setp(I, "Scale", ZhG.terminal_scale[I])
								setp(I, "VertexColor", ZhG.terminal_tint[I])
							end
						end
					end,
				}
				for Jt, aUu in pairs(ZhG.State.HistoryRecord.targets) do
					if aUu then
						ZhG.State.HistoryRecord.initial_type[aUu] = aUu.MeshType
						ZhG.State.HistoryRecord.initial_mesh[aUu] = aUu.MeshId
						ZhG.State.HistoryRecord.initial_texture[aUu] = aUu.TextureId
						ZhG.State.HistoryRecord.initial_scale[aUu] = aUu.Scale
						ZhG.State.HistoryRecord.initial_tint[aUu] = aUu.VertexColor
					end
				end
			end
			Tools.Mesh.finishHistoryRecord = function(We1INxkk)
				if not We1INxkk.State.HistoryRecord then
					return
				end
				for X37Nsx, eE in pairs(We1INxkk.State.HistoryRecord.targets) do
					if eE then
						We1INxkk.State.HistoryRecord.terminal_type[eE] = eE.MeshType
						We1INxkk.State.HistoryRecord.terminal_mesh[eE] = eE.MeshId
						We1INxkk.State.HistoryRecord.terminal_texture[eE] = eE.TextureId
						We1INxkk.State.HistoryRecord.terminal_scale[eE] = eE.Scale
						We1INxkk.State.HistoryRecord.terminal_tint[eE] = eE.VertexColor
					end
				end
				History:add(We1INxkk.State.HistoryRecord)
				We1INxkk.State.HistoryRecord = nil
			end
			Tools.Mesh.changeMesh = function(pCWPYYE, g)
				local kUNaj9 = {}
				for Ewt, TzK in pairs(Selection.Items) do
					local jjU = Support.GetChildOfClass(TzK, "SpecialMesh")
					if jjU then
						table.insert(kUNaj9, jjU)
					end
				end
				local AiX, CzFcrl, X8Gpm3
				if HttpAvailable then
					local DGflu = "http://www.f3xteam.com/bt/getFirstMeshData/%s"
					local FF9q1AO = HttpInterface.GetAsync(DGflu:format(g))
					if FF9q1AO and FF9q1AO:len() > 0 then
						local FF9q1AO = RbxUtility.DecodeJSON(FF9q1AO)
						if FF9q1AO and FF9q1AO.success then
							if FF9q1AO.meshID then
								g = FF9q1AO.meshID
							end
							if FF9q1AO.textureID then
								AiX = FF9q1AO.textureID
							end
							CzFcrl = Vector3.new(FF9q1AO.tint.x, FF9q1AO.tint.y, FF9q1AO.tint.z)
							X8Gpm3 = Vector3.new(FF9q1AO.scale.x, FF9q1AO.scale.y, FF9q1AO.scale.z)
						end
					end
				end
				pCWPYYE:startHistoryRecord(kUNaj9)
				for pJWQ, DZJXU in pairs(kUNaj9) do
					if g then
						setp(DZJXU, "MeshId", "http://www.roblox.com/asset/?id=" .. g)
					end
					if AiX then
						setp(DZJXU, "TextureId", "http://www.roblox.com/asset/?id=" .. AiX)
					end
					if CzFcrl then
						setp(DZJXU, "VertexColor", CzFcrl)
					end
					if X8Gpm3 then
						setp(DZJXU, "Scale", X8Gpm3)
					end
				end
				pCWPYYE:finishHistoryRecord()
			end
			Tools.Mesh.changeTexture = function(Oo6w, hN)
				local jz1uXDx = {}
				for vTRoD0X, oX9O28J in pairs(Selection.Items) do
					local sTbHW = Support.GetChildOfClass(oX9O28J, "SpecialMesh")
					if sTbHW then
						table.insert(jz1uXDx, sTbHW)
					end
				end
				if HttpAvailable then
					local upZW = "http://www.f3xteam.com/bt/getDecalImageID/%s"
					local AWQPjyxs = HttpInterface.GetAsync(upZW:format(hN))
					if AWQPjyxs and AWQPjyxs:len() > 0 then
						hN = AWQPjyxs
					end
				end
				Oo6w:startHistoryRecord(jz1uXDx)
				for V, M in pairs(jz1uXDx) do
					setp(M, "TextureId", "http://www.roblox.com/asset/?id=" .. hN)
				end
				Oo6w:finishHistoryRecord()
			end
			Tools.Mesh.changeScale = function(sPh, RKD_1r, hnrLmi)
				local Ea23 = {}
				for gdet, x in pairs(Selection.Items) do
					local KzXd = Support.GetChildOfClass(x, "SpecialMesh")
					if KzXd then
						table.insert(Ea23, KzXd)
					end
				end
				sPh:startHistoryRecord(Ea23)
				for gqa3M1, Z in pairs(Ea23) do
					setp(Z, "Scale", Vector3.new(
						RKD_1r == "x" and hnrLmi or Z.Scale.x,
						RKD_1r == "y" and hnrLmi or Z.Scale.y,
						RKD_1r == "z" and hnrLmi or Z.Scale.z
					))
				end
				sPh:finishHistoryRecord()
			end
			Tools.Mesh.changeTint = function(neYEY, H0, r)
				local JF4a = {}
				for HeQL, AuacAxlc in pairs(Selection.Items) do
					local Bk = Support.GetChildOfClass(AuacAxlc, "SpecialMesh")
					if Bk then
						table.insert(JF4a, Bk)
					end
				end
				neYEY:startHistoryRecord(JF4a)
				for IulFXIJ, b in pairs(JF4a) do
					b.VertexColor = Vector3.new(
						H0 == "r" and r or b.VertexColor.x,
						H0 == "g" and r or b.VertexColor.y,
						H0 == "b" and r or b.VertexColor.z
					)
				end
				neYEY:finishHistoryRecord()
			end
			Tools.Mesh.hideGUI = function(xfxoXu)
				if xfxoXu.GUI then
					setp(xfxoXu.GUI, "Visible", false)
				end
			end
			Tools.Mesh.Loaded = true
		end,
	},
	{
		"Move",
		function()
			repeat
				task.wait()
			until _G.BTCoreEnv and _G.BTCoreEnv.tool and _G.BTCoreEnv.tool.CoreReady
			setfenv(1, _G.BTCoreEnv.tool)
			Tools.Move = {}
			setp(Tools.Move, "Color", BrickColor.new("Deep orange"))
			Tools.Move.Connections = {}
			Tools.Move.Options = {
				increment = 1,
				axes = "global",
			}
			Tools.Move.State = {
				distance_moved = 0,
				moving = false,
				PreMove = {},
			}
			Tools.Move.Listeners = {}
			Tools.Move.Listeners.Equipped = function()
				local KJ0Y6 = Tools.Move
				if not Mouse then
					return
				end
				KJ0Y6.State.PreviousSelectionBoxColor = SelectionBoxColor
				SelectionBoxColor = KJ0Y6.Color
				updateSelectionBoxColor()
				KJ0Y6:showGUI()
				if not KJ0Y6.BoundingBox then
					KJ0Y6.BoundingBox = (RbxUtility.Create("Part"))({
						Name = "BTBoundingBox",
						CanCollide = false,
						Transparency = 1,
						Anchored = true,
					})
				end
				Mouse.TargetFilter = KJ0Y6.BoundingBox
				KJ0Y6:changeAxes(KJ0Y6.Options.axes)
				KJ0Y6.Connections.DraggerKeyListener = Mouse.KeyDown:Connect(function(C)
					local C = C:lower()
					if not KJ0Y6.Dragger then
						return
					end
					if C == "r" then
						KJ0Y6.Dragger:AxisRotate(Enum.Axis.Z)
					elseif C == "t" then
						KJ0Y6.Dragger:AxisRotate(Enum.Axis.X)
					elseif C == "y" then
						KJ0Y6.Dragger:AxisRotate(Enum.Axis.Y)
					end
					KJ0Y6.Dragger:MouseMove(Mouse.UnitRay)
				end)
				KJ0Y6.State.StaticItems = {}
				KJ0Y6.State.StaticExtents = nil
				KJ0Y6.State.RecalculateStaticExtents = true
				local KPlOw = {}
				function AddStaticItem(BA)
					if #Support.FindTableOccurrences(KJ0Y6.State.StaticItems, BA) > 0 then
						return
					end
					table.insert(KJ0Y6.State.StaticItems, BA)
					KPlOw[BA] = BA.Changed:Connect(function(ybxsK)
						if ybxsK == "CFrame" or ybxsK == "Size" then
							KJ0Y6.State.RecalculateStaticExtents = true
						elseif ybxsK == "Anchored" and not BA.Anchored then
							RemoveStaticItem(BA)
						end
					end)
					KJ0Y6.State.RecalculateStaticExtents = true
				end
				function RemoveStaticItem(_0fP)
					local l6 = (Support.FindTableOccurrences(KJ0Y6.State.StaticItems, _0fP))[1]
					if l6 then
						KJ0Y6.State.StaticItems[l6] = nil
					end
					if KPlOw[_0fP] then
						KPlOw[_0fP]:Disconnect()
						KPlOw[_0fP] = nil
					end
					KJ0Y6.State.RecalculateStaticExtents = true
				end
				for rGOqO96U, odN0bo in pairs(Selection.Items) do
					if odN0bo.Anchored then
						AddStaticItem(odN0bo)
					end
				end
				table.insert(
					KJ0Y6.Connections,
					Selection.ItemAdded:Connect(function(sn1BOCT5)
						if sn1BOCT5.Anchored then
							AddStaticItem(sn1BOCT5)
						end
					end)
				)
				table.insert(
					KJ0Y6.Connections,
					Selection.ItemRemoved:Connect(function(k0iue, J5)
						if J5 or not KPlOw[k0iue] then
							return
						end
						RemoveStaticItem(k0iue)
					end)
				)
				table.insert(
					KJ0Y6.Connections,
					Selection.Cleared:Connect(function()
						for d3, DAeG in pairs(KPlOw) do
							DAeG:Disconnect()
							KPlOw[d3] = nil
						end
						KJ0Y6.State.StaticExtents = nil
						KJ0Y6.State.StaticItems = {}
					end)
				);
				(coroutine.wrap(function()
					updater_on = true
					KJ0Y6.Updater = function()
						updater_on = false
					end
					while task.wait(0.1) and updater_on do
						if CurrentTool == KJ0Y6 then
							if KJ0Y6.GUI and KJ0Y6.GUI.Visible then
								KJ0Y6:updateGUI()
							end
							if KJ0Y6.Options.axes == "global" then
								KJ0Y6:updateBoundingBox()
							end
						end
					end
				end))()
			end
			Tools.Move.Listeners.Unequipped = function()
				local eb6VK = Tools.Move
				if eb6VK.Updater then
					eb6VK.Updater()
					eb6VK.Updater = nil
				end
				eb6VK:FinishDragging()
				eb6VK:hideGUI()
				eb6VK:hideHandles()
				for U8PPAC, bK92X9wQ in pairs(eb6VK.Connections) do
					bK92X9wQ:Disconnect()
					eb6VK.Connections[U8PPAC] = nil
				end
				SelectionBoxColor = eb6VK.State.PreviousSelectionBoxColor
				updateSelectionBoxColor()
			end
			Tools.Move.updateGUI = function(PZ)
				if PZ.GUI then
					local toG0 = PZ.GUI
					if #Selection.Items > 0 then
						local EZ3qRhLq, E7Q, qts06Ch3 = nil, nil, nil
						for cBwDRgK, veqNhn in pairs(Selection.Items) do
							if cBwDRgK == 1 then
								EZ3qRhLq, E7Q, qts06Ch3 =
									Support.Round(veqNhn.Position.x, 2),
								Support.Round(veqNhn.Position.y, 2),
								Support.Round(veqNhn.Position.z, 2)
							else
								if EZ3qRhLq ~= Support.Round(veqNhn.Position.x, 2) then
									EZ3qRhLq = nil
								end
								if E7Q ~= Support.Round(veqNhn.Position.y, 2) then
									E7Q = nil
								end
								if qts06Ch3 ~= Support.Round(veqNhn.Position.z, 2) then
									qts06Ch3 = nil
								end
							end
						end
						if not PZ.State.pos_x_focused then
							setp(toG0.Info.Center.X.TextBox, "Text", EZ3qRhLq and tostring(EZ3qRhLq) or "*")
						end
						if not PZ.State.pos_y_focused then
							setp(toG0.Info.Center.Y.TextBox, "Text", E7Q and tostring(E7Q) or "*")
						end
						if not PZ.State.pos_z_focused then
							setp(toG0.Info.Center.Z.TextBox, "Text", qts06Ch3 and tostring(qts06Ch3) or "*")
						end
						setp(toG0.Info, "Visible", true)
					else
						setp(toG0.Info, "Visible", false)
					end
					if PZ.State.distance_moved then
						setp(toG0.Changes.Text, "Text", "moved " .. tostring(PZ.State.distance_moved) .. " studs")
						setp(toG0.Changes, "Position", toG0.Info.Visible and UDim2.new(0, 5, 0, 165) or UDim2.new(0, 5, 0, 100))
						setp(toG0.Changes, "Visible", true)
					else
						setp(toG0.Changes.Text, "Text", "")
						setp(toG0.Changes, "Visible", false)
					end
				end
			end
			Tools.Move.changePosition = function(OiD, prw2Jl, oo)
				OiD:startHistoryRecord()
				local ps, cfs = {}, {}
				for DYo, kcCL9hT in pairs(Selection.Items) do
					ps[#ps + 1] = kcCL9hT
					cfs[#cfs + 1] = CFrame.new(
						(prw2Jl == "x" and oo or kcCL9hT.Position.x),
						(prw2Jl == "y" and oo or kcCL9hT.Position.y),
						(prw2Jl == "z" and oo or kcCL9hT.Position.z)
					) * CFrame.Angles(kcCL9hT.CFrame:toEulerAnglesXYZ())
				end
				bulkMove(ps, cfs)
				OiD:finishHistoryRecord()
			end
			Tools.Move.startHistoryRecord = function(pvg)
				if pvg.State.HistoryRecord then
					pvg.State.HistoryRecord = nil
				end
				pvg.State.HistoryRecord = {
					targets = Support.CloneTable(Selection.Items),
					initial_positions = {},
					terminal_positions = {},
					unapply = function(pvg)
						Selection:clear()
						for M, USR in pairs(pvg.targets) do
							if USR then
								setp(USR, "CFrame", pvg.initial_positions[USR])
								USR:MakeJoints()
								Selection:add(USR)
							end
						end
					end,
					apply = function(pvg)
						Selection:clear()
						for Wxk9CBfb, V in pairs(pvg.targets) do
							if V then
								setp(V, "CFrame", pvg.terminal_positions[V])
								V:MakeJoints()
								Selection:add(V)
							end
						end
					end,
				}
				for jWPa, d in pairs(pvg.State.HistoryRecord.targets) do
					if d then
						pvg.State.HistoryRecord.initial_positions[d] = d.CFrame
					end
				end
			end
			Tools.Move.finishHistoryRecord = function(j3Fn)
				if not j3Fn.State.HistoryRecord then
					return
				end
				for oZ65m5, hQjlCjY in pairs(j3Fn.State.HistoryRecord.targets) do
					if hQjlCjY then
						j3Fn.State.HistoryRecord.terminal_positions[hQjlCjY] = hQjlCjY.CFrame
					end
				end
				History:add(j3Fn.State.HistoryRecord)
				j3Fn.State.HistoryRecord = nil
			end
			Tools.Move.StartDragging = function(JDyNU5, cMv6ou)
				for HPZKRJ, cn in pairs(Selection.Items) do
					setp(cn, "RotVelocity", Vector3.new(0, 0, 0))
					setp(cn, "Velocity", Vector3.new(0, 0, 0))
				end
				JDyNU5:startHistoryRecord()
				JDyNU5.State.dragging = true
				override_selection = true
				JDyNU5.Dragger = Instance.new("Dragger")
				JDyNU5.Dragger:MouseDown(
					cMv6ou,
					(cMv6ou.CFrame:toObjectSpace(CFrame.new(Mouse.Hit.p))).p,
					Selection.Items
				)
				JDyNU5.Connections.DraggerConnection = UserInputService.InputEnded:Connect(function(_Yf)
					if _Yf.UserInputType == Enum.UserInputType.MouseButton1 then
						JDyNU5:FinishDragging()
					end
				end)
			end
			Tools.Move.FinishDragging = function(rl)
				override_selection = true
				if rl.Connections.DraggerConnection then
					rl.Connections.DraggerConnection:Disconnect()
					rl.Connections.DraggerConnection = nil
				end
				if not rl.Dragger then
					return
				end
				rl.Dragger:MouseUp()
				rl.State.dragging = false
				rl.Dragger:Destroy()
				rl.Dragger = nil
				rl:finishHistoryRecord()
			end
			Tools.Move.Listeners.Button1Down = function()
				local Z = Tools.Move
				local jOFP = Z.ManualTarget or Mouse.Target
				Z.ManualTarget = nil
				if not Selection:find(jOFP) and isSelectable(jOFP) then
					Selection:clear()
					Selection:add(jOFP)
				end
				if not Selection:find(jOFP) then
					return
				end
				Z:StartDragging(jOFP)
			end
			Tools.Move.Listeners.Move = function()
				local LCqNO = Tools.Move
				if not LCqNO.Dragger then
					return
				end
				override_selection = true
				LCqNO.Dragger:MouseMove(Mouse.UnitRay)
			end
			Tools.Move.Listeners.KeyUp = function(jF4YoB)
				local nROZ = Tools.Move
				if jF4YoB == "-" and nROZ.GUI then
					nROZ.GUI.IncrementOption.Increment.TextBox:CaptureFocus()
				end
			end
			Tools.Move.showGUI = function(_GVROa)
				if not _GVROa.GUI then
					local bO3YuZv = DFb100j.BTMoveToolGUI:Clone()
					setp(bO3YuZv, "Parent", UI)
					bO3YuZv.AxesOption.Global.Button.MouseButton1Down:Connect(function()
						_GVROa:changeAxes("global")
						setp(bO3YuZv.AxesOption.Global.SelectedIndicator, "BackgroundTransparency", 0)
						setp(bO3YuZv.AxesOption.Global.Background, "Image", Assets.DarkSlantedRectangle)
						setp(bO3YuZv.AxesOption.Local.SelectedIndicator, "BackgroundTransparency", 1)
						setp(bO3YuZv.AxesOption.Local.Background, "Image", Assets.LightSlantedRectangle)
						setp(bO3YuZv.AxesOption.Last.SelectedIndicator, "BackgroundTransparency", 1)
						setp(bO3YuZv.AxesOption.Last.Background, "Image", Assets.LightSlantedRectangle)
					end)
					bO3YuZv.AxesOption.Local.Button.MouseButton1Down:Connect(function()
						_GVROa:changeAxes("local")
						setp(bO3YuZv.AxesOption.Global.SelectedIndicator, "BackgroundTransparency", 1)
						setp(bO3YuZv.AxesOption.Global.Background, "Image", Assets.LightSlantedRectangle)
						setp(bO3YuZv.AxesOption.Local.SelectedIndicator, "BackgroundTransparency", 0)
						setp(bO3YuZv.AxesOption.Local.Background, "Image", Assets.DarkSlantedRectangle)
						setp(bO3YuZv.AxesOption.Last.SelectedIndicator, "BackgroundTransparency", 1)
						setp(bO3YuZv.AxesOption.Last.Background, "Image", Assets.LightSlantedRectangle)
					end)
					bO3YuZv.AxesOption.Last.Button.MouseButton1Down:Connect(function()
						_GVROa:changeAxes("last")
						setp(bO3YuZv.AxesOption.Global.SelectedIndicator, "BackgroundTransparency", 1)
						setp(bO3YuZv.AxesOption.Global.Background, "Image", Assets.LightSlantedRectangle)
						setp(bO3YuZv.AxesOption.Local.SelectedIndicator, "BackgroundTransparency", 1)
						setp(bO3YuZv.AxesOption.Local.Background, "Image", Assets.LightSlantedRectangle)
						setp(bO3YuZv.AxesOption.Last.SelectedIndicator, "BackgroundTransparency", 0)
						setp(bO3YuZv.AxesOption.Last.Background, "Image", Assets.DarkSlantedRectangle)
					end)
					bO3YuZv.IncrementOption.Increment.TextBox.FocusLost:Connect(function(Vq)
						_GVROa.Options.increment = tonumber(bO3YuZv.IncrementOption.Increment.TextBox.Text)
							or _GVROa.Options.increment
						setp(bO3YuZv.IncrementOption.Increment.TextBox, "Text", tostring(_GVROa.Options.increment))
					end)
					bO3YuZv.Info.Center.X.TextButton.MouseButton1Down:Connect(function()
						_GVROa.State.pos_x_focused = true
						bO3YuZv.Info.Center.X.TextBox:CaptureFocus()
					end)
					bO3YuZv.Info.Center.X.TextBox.FocusLost:Connect(function(cW)
						local c7GfSrtA = tonumber(bO3YuZv.Info.Center.X.TextBox.Text)
						if c7GfSrtA then
							_GVROa:changePosition("x", c7GfSrtA)
						end
						_GVROa.State.pos_x_focused = false
					end)
					bO3YuZv.Info.Center.Y.TextButton.MouseButton1Down:Connect(function()
						_GVROa.State.pos_y_focused = true
						bO3YuZv.Info.Center.Y.TextBox:CaptureFocus()
					end)
					bO3YuZv.Info.Center.Y.TextBox.FocusLost:Connect(function(lEP9VGU)
						local xpKd = tonumber(bO3YuZv.Info.Center.Y.TextBox.Text)
						if xpKd then
							_GVROa:changePosition("y", xpKd)
						end
						_GVROa.State.pos_y_focused = false
					end)
					bO3YuZv.Info.Center.Z.TextButton.MouseButton1Down:Connect(function()
						_GVROa.State.pos_z_focused = true
						bO3YuZv.Info.Center.Z.TextBox:CaptureFocus()
					end)
					bO3YuZv.Info.Center.Z.TextBox.FocusLost:Connect(function(r)
						local oa = tonumber(bO3YuZv.Info.Center.Z.TextBox.Text)
						if oa then
							_GVROa:changePosition("z", oa)
						end
						_GVROa.State.pos_z_focused = false
					end)
					_GVROa.GUI = bO3YuZv
				end
				setp(_GVROa.GUI, "Visible", true)
			end
			Tools.Move.hideGUI = function(dT)
				if dT.GUI then
					setp(dT.GUI, "Visible", false)
				end
			end
			Tools.Move.showHandles = function(xa78yAit, s_CnSV)
				if not xa78yAit.Handles then
					xa78yAit.Handles = (RbxUtility.Create("Handles"))({
						Name = "BTMovementHandles",
						Color = xa78yAit.Color,
						Parent = GUIContainer,
					})
					xa78yAit.Handles.MouseButton1Down:Connect(function()
						override_selection = true
						xa78yAit.State.moving = true
						xa78yAit.State.distance_moved = 0
						xa78yAit:startHistoryRecord()
						for s, wqRzXIG7 in pairs(Selection.Items) do
							xa78yAit.State.PreMove[wqRzXIG7] = wqRzXIG7:Clone()
							setp(wqRzXIG7, "Anchored", true)
						end
						xa78yAit.Connections.HandleReleaseListener = UserInputService.InputEnded:Connect(function(w3nHh)
							if w3nHh.UserInputType ~= Enum.UserInputType.MouseButton1 then
								return
							end
							override_selection = true
							xa78yAit.State.moving = false
							if xa78yAit.Connections.HandleReleaseListener then
								xa78yAit.Connections.HandleReleaseListener:Disconnect()
								xa78yAit.Connections.HandleReleaseListener = nil
							end
							xa78yAit:finishHistoryRecord()
							for bo0I, lK5ogD in pairs(xa78yAit.State.PreMove) do
								setp(bo0I, "Anchored", lK5ogD.Anchored)
								xa78yAit.State.PreMove[bo0I] = nil
								bo0I:MakeJoints()
								setp(bo0I, "Velocity", Vector3.new(0, 0, 0))
								setp(bo0I, "RotVelocity", Vector3.new(0, 0, 0))
							end
						end)
					end)
					xa78yAit.Handles.MouseDrag:Connect(function(I8F, Y3NU)
						local Avel7IrZ = Y3NU % xa78yAit.Options.increment
						local F = Y3NU - Avel7IrZ
						local _ = Y3NU - Avel7IrZ + xa78yAit.Options.increment
						local DpWpo7kA = math.abs(Y3NU - F)
						local LS = math.abs(Y3NU - _)
						if DpWpo7kA <= LS then
							Y3NU = F
						else
							Y3NU = _
						end
						local cQvh = Y3NU
						xa78yAit.State.distance_moved = Y3NU
						for llU3aki, HQrwQErj in pairs(Selection.Items) do
							HQrwQErj:BreakJoints()
							if I8F == Enum.NormalId.Top then
								if xa78yAit.Options.axes == "global" then
									HQrwQErj.CFrame = (CFrame.new(xa78yAit.State.PreMove[HQrwQErj].CFrame.p)):toWorldSpace(
										CFrame.new(0, cQvh, 0)
									) * CFrame.Angles(
										xa78yAit.State.PreMove[HQrwQErj].CFrame:toEulerAnglesXYZ()
									)
								elseif xa78yAit.Options.axes == "local" then
									HQrwQErj.CFrame =
										xa78yAit.State.PreMove[HQrwQErj].CFrame:toWorldSpace(CFrame.new(0, cQvh, 0))
								elseif xa78yAit.Options.axes == "last" then
									HQrwQErj.CFrame = (xa78yAit.State.PreMove[Selection.Last].CFrame:toWorldSpace(
										CFrame.new(0, cQvh, 0)
										)):toWorldSpace(
										(xa78yAit.State.PreMove[HQrwQErj].CFrame:toObjectSpace(
											xa78yAit.State.PreMove[Selection.Last].CFrame
											)):inverse()
									)
								end
							elseif I8F == Enum.NormalId.Bottom then
								if xa78yAit.Options.axes == "global" then
									HQrwQErj.CFrame = (CFrame.new(xa78yAit.State.PreMove[HQrwQErj].CFrame.p)):toWorldSpace(
										CFrame.new(0, -cQvh, 0)
									) * CFrame.Angles(
										xa78yAit.State.PreMove[HQrwQErj].CFrame:toEulerAnglesXYZ()
									)
								elseif xa78yAit.Options.axes == "local" then
									HQrwQErj.CFrame =
										xa78yAit.State.PreMove[HQrwQErj].CFrame:toWorldSpace(CFrame.new(0, -cQvh, 0))
								elseif xa78yAit.Options.axes == "last" then
									HQrwQErj.CFrame = (xa78yAit.State.PreMove[Selection.Last].CFrame:toWorldSpace(
										CFrame.new(0, -cQvh, 0)
										)):toWorldSpace(
										(xa78yAit.State.PreMove[HQrwQErj].CFrame:toObjectSpace(
											xa78yAit.State.PreMove[Selection.Last].CFrame
											)):inverse()
									)
								end
							elseif I8F == Enum.NormalId.Front then
								if xa78yAit.Options.axes == "global" then
									HQrwQErj.CFrame = (CFrame.new(xa78yAit.State.PreMove[HQrwQErj].CFrame.p)):toWorldSpace(
										CFrame.new(0, 0, -cQvh)
									) * CFrame.Angles(
										xa78yAit.State.PreMove[HQrwQErj].CFrame:toEulerAnglesXYZ()
									)
								elseif xa78yAit.Options.axes == "local" then
									HQrwQErj.CFrame =
										xa78yAit.State.PreMove[HQrwQErj].CFrame:toWorldSpace(CFrame.new(0, 0, -cQvh))
								elseif xa78yAit.Options.axes == "last" then
									HQrwQErj.CFrame = (xa78yAit.State.PreMove[Selection.Last].CFrame:toWorldSpace(
										CFrame.new(0, 0, -cQvh)
										)):toWorldSpace(
										(xa78yAit.State.PreMove[HQrwQErj].CFrame:toObjectSpace(
											xa78yAit.State.PreMove[Selection.Last].CFrame
											)):inverse()
									)
								end
							elseif I8F == Enum.NormalId.Back then
								if xa78yAit.Options.axes == "global" then
									HQrwQErj.CFrame = (CFrame.new(xa78yAit.State.PreMove[HQrwQErj].CFrame.p)):toWorldSpace(
										CFrame.new(0, 0, cQvh)
									) * CFrame.Angles(
										xa78yAit.State.PreMove[HQrwQErj].CFrame:toEulerAnglesXYZ()
									)
								elseif xa78yAit.Options.axes == "local" then
									HQrwQErj.CFrame =
										xa78yAit.State.PreMove[HQrwQErj].CFrame:toWorldSpace(CFrame.new(0, 0, cQvh))
								elseif xa78yAit.Options.axes == "last" then
									HQrwQErj.CFrame = (xa78yAit.State.PreMove[Selection.Last].CFrame:toWorldSpace(
										CFrame.new(0, 0, cQvh)
										)):toWorldSpace(
										(xa78yAit.State.PreMove[HQrwQErj].CFrame:toObjectSpace(
											xa78yAit.State.PreMove[Selection.Last].CFrame
											)):inverse()
									)
								end
							elseif I8F == Enum.NormalId.Right then
								if xa78yAit.Options.axes == "global" then
									HQrwQErj.CFrame = (CFrame.new(xa78yAit.State.PreMove[HQrwQErj].CFrame.p)):toWorldSpace(
										CFrame.new(cQvh, 0, 0)
									) * CFrame.Angles(
										xa78yAit.State.PreMove[HQrwQErj].CFrame:toEulerAnglesXYZ()
									)
								elseif xa78yAit.Options.axes == "local" then
									HQrwQErj.CFrame =
										xa78yAit.State.PreMove[HQrwQErj].CFrame:toWorldSpace(CFrame.new(cQvh, 0, 0))
								elseif xa78yAit.Options.axes == "last" then
									HQrwQErj.CFrame = (xa78yAit.State.PreMove[Selection.Last].CFrame:toWorldSpace(
										CFrame.new(cQvh, 0, 0)
										)):toWorldSpace(
										(xa78yAit.State.PreMove[HQrwQErj].CFrame:toObjectSpace(
											xa78yAit.State.PreMove[Selection.Last].CFrame
											)):inverse()
									)
								end
							elseif I8F == Enum.NormalId.Left then
								if xa78yAit.Options.axes == "global" then
									HQrwQErj.CFrame = (CFrame.new(xa78yAit.State.PreMove[HQrwQErj].CFrame.p)):toWorldSpace(
										CFrame.new(-cQvh, 0, 0)
									) * CFrame.Angles(
										xa78yAit.State.PreMove[HQrwQErj].CFrame:toEulerAnglesXYZ()
									)
								elseif xa78yAit.Options.axes == "local" then
									HQrwQErj.CFrame =
										xa78yAit.State.PreMove[HQrwQErj].CFrame:toWorldSpace(CFrame.new(-cQvh, 0, 0))
								elseif xa78yAit.Options.axes == "last" then
									HQrwQErj.CFrame = (xa78yAit.State.PreMove[Selection.Last].CFrame:toWorldSpace(
										CFrame.new(-cQvh, 0, 0)
										)):toWorldSpace(
										(xa78yAit.State.PreMove[HQrwQErj].CFrame:toObjectSpace(
											xa78yAit.State.PreMove[Selection.Last].CFrame
											)):inverse()
									)
								end
							end
						end
					end)
				end
				if xa78yAit.Connections.AdorneeExistenceListener then
					xa78yAit.Connections.AdorneeExistenceListener:Disconnect()
					xa78yAit.Connections.AdorneeExistenceListener = nil
				end
				setp(xa78yAit.Handles, "Adornee", s_CnSV)
				xa78yAit.Connections.AdorneeExistenceListener = s_CnSV.AncestryChanged:Connect(function(tu, XSuzlcm)
					if tu ~= s_CnSV then
						return
					end
					if XSuzlcm == nil then
						xa78yAit:hideHandles()
					else
						xa78yAit:showHandles(s_CnSV)
					end
				end)
			end
			Tools.Move.hideHandles = function(nbAjk49J)
				if nbAjk49J.Handles then
					setp(nbAjk49J.Handles, "Adornee", nil)
				end
			end
			Tools.Move.updateBoundingBox = function(cB0vBn)
				if #Selection.Items > 0 and not cB0vBn.State.dragging then
					if cB0vBn.State.RecalculateStaticExtents then
						cB0vBn.State.StaticExtents = calculateExtents(cB0vBn.State.StaticItems, nil, true)
						cB0vBn.State.RecalculateStaticExtents = false
					end
					local IccvGO, BNC = calculateExtents(Selection.Items, cB0vBn.State.StaticExtents)
					setp(cB0vBn.BoundingBox, "Size", IccvGO)
					setp(cB0vBn.BoundingBox, "CFrame", BNC)
					cB0vBn:showHandles(cB0vBn.BoundingBox)
				else
					cB0vBn:hideHandles()
				end
			end
			Tools.Move.changeAxes = function(s3, QXOjuVP)
				local KOk = s3.GUI and s3.GUI.AxesOption or nil
				if s3.Connections.HandleFocusChangeListener then
					s3.Connections.HandleFocusChangeListener:Disconnect()
					s3.Connections.HandleFocusChangeListener = nil
				end
				if s3.Connections.HandleSelectionChangeListener then
					s3.Connections.HandleSelectionChangeListener:Disconnect()
					s3.Connections.HandleSelectionChangeListener = nil
				end
				if QXOjuVP == "global" then
					s3.Options.axes = "global"
					s3:hideHandles()
					s3:showHandles(s3.BoundingBox)
					if s3.GUI then
						setp(KOk.Global.SelectedIndicator, "BackgroundTransparency", 0)
						setp(KOk.Global.Background, "Image", Assets.DarkSlantedRectangle)
						setp(KOk.Local.SelectedIndicator, "BackgroundTransparency", 1)
						setp(KOk.Local.Background, "Image", Assets.LightSlantedRectangle)
						setp(KOk.Last.SelectedIndicator, "BackgroundTransparency", 1)
						setp(KOk.Last.Background, "Image", Assets.LightSlantedRectangle)
					end
				end
				if QXOjuVP == "local" then
					s3.Options.axes = "local"
					s3.Connections.HandleSelectionChangeListener = Selection.Changed:Connect(function()
						s3:hideHandles()
						if Selection.Last then
							s3:showHandles(Selection.Last)
						end
					end)
					s3.Connections.HandleFocusChangeListener = Mouse.Button2Up:Connect(function()
						override_selection = true
						if Selection:find(Mouse.Target) then
							Selection:focus(Mouse.Target)
							s3:showHandles(Mouse.Target)
						end
					end)
					if Selection.Last then
						s3:showHandles(Selection.Last)
					end
					if s3.GUI then
						setp(KOk.Global.SelectedIndicator, "BackgroundTransparency", 1)
						setp(KOk.Global.Background, "Image", Assets.LightSlantedRectangle)
						setp(KOk.Local.SelectedIndicator, "BackgroundTransparency", 0)
						setp(KOk.Local.Background, "Image", Assets.DarkSlantedRectangle)
						setp(KOk.Last.SelectedIndicator, "BackgroundTransparency", 1)
						setp(KOk.Last.Background, "Image", Assets.LightSlantedRectangle)
					end
				end
				if QXOjuVP == "last" then
					s3.Options.axes = "last"
					s3.Connections.HandleSelectionChangeListener = Selection.Changed:Connect(function()
						s3:hideHandles()
						if Selection.Last then
							s3:showHandles(Selection.Last)
						end
					end)
					s3.Connections.HandleFocusChangeListener = Mouse.Button2Up:Connect(function()
						override_selection = true
						if Selection:find(Mouse.Target) then
							Selection:focus(Mouse.Target)
							s3:showHandles(Mouse.Target)
						end
					end)
					if Selection.Last then
						s3:showHandles(Selection.Last)
					end
					if s3.GUI then
						setp(KOk.Global.SelectedIndicator, "BackgroundTransparency", 1)
						setp(KOk.Global.Background, "Image", Assets.LightSlantedRectangle)
						setp(KOk.Local.SelectedIndicator, "BackgroundTransparency", 1)
						setp(KOk.Local.Background, "Image", Assets.LightSlantedRectangle)
						setp(KOk.Last.SelectedIndicator, "BackgroundTransparency", 0)
						setp(KOk.Last.Background, "Image", Assets.DarkSlantedRectangle)
					end
				end
			end
			Tools.Move.Loaded = true
		end,
	},
	{
		"NewPart",
		function()
			repeat
				task.wait()
			until _G.BTCoreEnv and _G.BTCoreEnv.tool and _G.BTCoreEnv.tool.CoreReady
			setfenv(1, _G.BTCoreEnv.tool)
			Tools.NewPart = {}
			setp(Tools.NewPart, "Color", BrickColor.new("Really black"))
			Tools.NewPart.Connections = {}
			Tools.NewPart.State = {
				Part = nil,
			}
			Tools.NewPart.Options = {
				type = "block",
			}
			Tools.NewPart.TypeOrder = {}
			Tools.NewPart.TypeNames = {}
			Tools.NewPart.Types = {}
			Tools.NewPart.addType = function(id, label, fn)
				table.insert(Tools.NewPart.TypeOrder, id)
				Tools.NewPart.TypeNames[id] = label
				Tools.NewPart.Types[id] = fn
			end
			local function newBase(cls)
				local ok, p = pcall(function()
					return Instance.new(cls, Workspace)
				end)
				if ok and p and p:IsA("BasePart") then
					return p
				end
				if ok and p then
					pcall(function()
						p:Destroy()
					end)
				end
				p = Instance.new("Part", Workspace)
				setp(p, "Name", cls)
				return p
			end
			local function sized(cls)
				local p = newBase(cls)
				setp(p, "FormFactor", Enum.FormFactor.Custom)
				setp(p, "Size", Vector3.new(4, 1, 2))
				return p
			end
			local function smoothShape(shape)
				local p = sized("Part")
				setp(p, "Shape", shape)
				setp(p, "TopSurface", Enum.SurfaceType.Smooth)
				setp(p, "BottomSurface", Enum.SurfaceType.Smooth)
				return p
			end
			Tools.NewPart.addType("block", "BLOCK", function()
				local p = sized("Part")
				setp(p, "Shape", Enum.PartType.Block)
				return p
			end)
			Tools.NewPart.addType("ball", "BALL", function()
				return smoothShape(Enum.PartType.Ball)
			end)
			Tools.NewPart.addType("cylinder", "CYLINDER", function()
				return smoothShape(Enum.PartType.Cylinder)
			end)
			Tools.NewPart.addType("wedge", "WEDGE", function()
				return sized("WedgePart")
			end)
			Tools.NewPart.addType("cornerwedge", "CORNER WEDGE", function()
				return sized("CornerWedgePart")
			end)
			Tools.NewPart.addType("truss", "TRUSS", function()
				return sized("TrussPart")
			end)
			Tools.NewPart.addType("seat", "SEAT", function()
				return sized("Seat")
			end)
			Tools.NewPart.addType("vehicleseat", "VEHICLE SEAT", function()
				return sized("VehicleSeat")
			end)
			Tools.NewPart.addType("spawnlocation", "SPAWN LOCATION", function()
				return sized("SpawnLocation")
			end)
			Tools.NewPart.addType("meshpart", "MESH PART", function()
				return sized("MeshPart")
			end)
			Tools.NewPart.addType("unionoperation", "UNION OPERATION", function()
				return sized("UnionOperation")
			end)
			Tools.NewPart.addType("negateoperation", "NEGATE OPERATION", function()
				return sized("NegateOperation")
			end)
			Tools.NewPart.addType("intersectoperation", "INTERSECT OPERATION", function()
				return sized("IntersectOperation")
			end)
			Tools.NewPart.addType("flagstand", "FLAG STAND", function()
				return sized("FlagStand")
			end)
			Tools.NewPart.addType("skateboardplatform", "SKATEBOARD PLATFORM", function()
				return sized("SkateboardPlatform")
			end)
			Tools.NewPart.Types.normal = Tools.NewPart.Types.block
			Tools.NewPart.TypeNames.normal = "BLOCK"


			Tools.NewPart.Listeners = {}
			Tools.NewPart.Listeners.Equipped = function()
				local GQ8QsA = Tools.NewPart
				GQ8QsA.State.PreviousSelectionBoxColor = SelectionBoxColor
				SelectionBoxColor = GQ8QsA.Color
				updateSelectionBoxColor()
				GQ8QsA:showGUI()
				GQ8QsA:changeType(GQ8QsA.Options.type)
			end
			Tools.NewPart.Listeners.Unequipped = function()
				local B = Tools.NewPart
				B:hideGUI()
				for i, zmF in pairs(B.Connections) do
					zmF:Disconnect()
					B.Connections[i] = nil
				end
				SelectionBoxColor = B.State.PreviousSelectionBoxColor
				updateSelectionBoxColor()
			end
			Tools.NewPart.Listeners.Button1Down = function()
				local RKBSOvv = Tools.NewPart
				local make = RKBSOvv.Types[RKBSOvv.Options.type] or RKBSOvv.Types.block
				local GxQqHPYH = make()
				setp(GxQqHPYH, "Anchored", true)
				Selection:clear()
				Selection:add(GxQqHPYH)
				local KEhfU = {
					target = GxQqHPYH,
					apply = function(RKBSOvv)
						Selection:clear()
						if RKBSOvv.target then
							setp(RKBSOvv.target, "Parent", Workspace)
							Selection:add(RKBSOvv.target)
						end
					end,
					unapply = function(RKBSOvv)
						if RKBSOvv.target then
							setp(RKBSOvv.target, "Parent", nil)
						end
					end,
				}
				History:add(KEhfU)
				equipTool(Tools.Move)
				Tools.Move.ManualTarget = GxQqHPYH
				setp(GxQqHPYH, "CFrame", CFrame.new(Mouse.Hit.p))
				Tools.Move.Listeners.Button1Down()
				Tools.Move.Listeners.Move()
			end
			Tools.NewPart.changeType = function(zufQE, QwSnT)
				zufQE.Options.type = QwSnT
				zufQE.TypeDropdown:selectOption((zufQE.TypeNames[QwSnT] or QwSnT):upper())
				if zufQE.TypeDropdown.open then
					zufQE.TypeDropdown:toggle()
				end
			end
			Tools.NewPart.showGUI = function(WrvmQJ6)
				if not WrvmQJ6.GUI then
					local rOMAEo = DFb100j.BTNewPartToolGUI:Clone()
					setp(rOMAEo, "Parent", UI)
					local SFGo78 = createDropdown()
					WrvmQJ6.TypeDropdown = SFGo78
					setp(SFGo78.Frame, "Parent", rOMAEo.TypeOption)
					setp(SFGo78.Frame, "Position", UDim2.new(0, 70, 0, 0))
					setp(SFGo78.Frame, "Size", UDim2.new(0, 140, 0, 25));
					for _, id in ipairs(WrvmQJ6.TypeOrder) do
						local label = WrvmQJ6.TypeNames[id] or id:upper()
						local b = SFGo78:addOption(label)
						b.MouseButton1Up:Connect(function()
							WrvmQJ6:changeType(id)
						end)
					end
					WrvmQJ6.GUI = rOMAEo
				end
				setp(WrvmQJ6.GUI, "Visible", true)
			end
			Tools.NewPart.hideGUI = function(LTd5)
				if LTd5.GUI then
					setp(LTd5.GUI, "Visible", false)
				end
			end
			Tools.NewPart.Loaded = true
		end,
	},
	{
		"Paint",
		function()
			repeat
				task.wait()
			until _G.BTCoreEnv and _G.BTCoreEnv.tool and _G.BTCoreEnv.tool.CoreReady
			setfenv(1, _G.BTCoreEnv.tool)
			Tools.Paint = {}
			setp(Tools.Paint, "Color", BrickColor.new("Really red"))
			Tools.Paint.Options = {
				Color = nil,
			}
			Tools.Paint.State = {}
			Tools.Paint.Listeners = {}
			Tools.Paint.Listeners.Equipped = function()
				local JmrwaH = Tools.Paint
				JmrwaH.State.PreviousSelectionBoxColor = SelectionBoxColor
				SelectionBoxColor = JmrwaH.Color
				updateSelectionBoxColor()
				JmrwaH:showGUI()
				JmrwaH:changeColor(JmrwaH.Options.Color)
			end
			Tools.Paint.Listeners.Unequipped = function()
				local qqciA = Tools.Paint
				qqciA:changeColor(nil)
				qqciA:hideGUI()
				SelectionBoxColor = qqciA.State.PreviousSelectionBoxColor
				updateSelectionBoxColor()
			end
			Tools.Paint.startHistoryRecord = function(bgKb)
				if bgKb.State.HistoryRecord then
					bgKb.State.HistoryRecord = nil
				end
				bgKb.State.HistoryRecord = {
					targets = Support.CloneTable(Selection.Items),
					initial_colors = {},
					terminal_colors = {},
					unapply = function(bgKb)
						Selection:clear()
						for b0q, MRluMhh in pairs(bgKb.targets) do
							if MRluMhh then
								setp(MRluMhh, "BrickColor", bgKb.initial_colors[MRluMhh])
								Selection:add(MRluMhh)
							end
						end
					end,
					apply = function(bgKb)
						Selection:clear()
						for n0R1Mj, a4j6 in pairs(bgKb.targets) do
							if a4j6 then
								setp(a4j6, "BrickColor", bgKb.terminal_colors[a4j6])
								Selection:add(a4j6)
							end
						end
					end,
				}
				for lg6u, ubseU in pairs(bgKb.State.HistoryRecord.targets) do
					if ubseU then
						bgKb.State.HistoryRecord.initial_colors[ubseU] = ubseU.BrickColor
					end
				end
			end
			Tools.Paint.finishHistoryRecord = function(kfDX)
				if not kfDX.State.HistoryRecord then
					return
				end
				for g26, HDP in pairs(kfDX.State.HistoryRecord.targets) do
					if HDP then
						kfDX.State.HistoryRecord.terminal_colors[HDP] = HDP.BrickColor
					end
				end
				History:add(kfDX.State.HistoryRecord)
				kfDX.State.HistoryRecord = nil
			end
			Tools.Paint.Listeners.Button1Up = function()
				local c6nlekUb = Tools.Paint
				if Selection:find(Mouse.Target) and not selecting and not selecting then
					override_selection = true
					c6nlekUb:startHistoryRecord()
					if c6nlekUb.Options.Color then
						for NJQ0, o_v3 in pairs(Selection.Items) do
							setp(o_v3, "BrickColor", c6nlekUb.Options.Color)
						end
					end
					c6nlekUb:finishHistoryRecord()
				end
			end
			Tools.Paint.changeColor = function(zI, ET)
				if ET then
					setp(zI.Options, "Color", ET)
					zI:startHistoryRecord()
					for RPrsE2M, T2WO5I in pairs(Selection.Items) do
						setp(T2WO5I, "BrickColor", ET)
					end
					zI:finishHistoryRecord()
					if zI.GUI then
						for f7pL, bHs in pairs(zI.GUI.Palette:GetChildren()) do
							setp(bHs, "Text", "")
						end
						zI.GUI.Palette[ET.Name].Text = "X"
					end
				else
					setp(zI.Options, "Color", nil)
					if zI.GUI then
						for eThxHw, tJVrOA in pairs(zI.GUI.Palette:GetChildren()) do
							setp(tJVrOA, "Text", "")
						end
					end
				end
			end
			Tools.Paint.showGUI = function(tqJFy)
				if not tqJFy.GUI then
					local EoFG = DFb100j.BTPaintToolGUI:Clone()
					setp(EoFG, "Parent", UI)
					for DQsI, Cam in pairs(EoFG.Palette:GetChildren()) do
						Cam.MouseButton1Click:Connect(function()
							tqJFy:changeColor(BrickColor.new(Cam.Name))
						end)
					end
					tqJFy.GUI = EoFG
				end
				setp(tqJFy.GUI, "Visible", true)
			end
			Tools.Paint.hideGUI = function(wF77)
				if wF77.GUI then
					setp(wF77.GUI, "Visible", false)
				end
			end
			Tools.Paint.Loaded = true
		end,
	},
	{
		"Resize",
		function()
			repeat
				task.wait()
			until _G.BTCoreEnv and _G.BTCoreEnv.tool and _G.BTCoreEnv.tool.CoreReady
			setfenv(1, _G.BTCoreEnv.tool)
			Tools.Resize = {}
			Tools.Resize.Connections = {}
			Tools.Resize.Options = {
				increment = 1,
				directions = "normal",
			}
			Tools.Resize.State = {
				PreResize = {},
				previous_distance = 0,
				resizing = false,
				length_resized = 0,
			}
			Tools.Resize.Listeners = {}
			setp(Tools.Resize, "Color", BrickColor.new("Cyan"))
			Tools.Resize.Listeners.Equipped = function()
				local A5pk0 = Tools.Resize
				A5pk0.State.PreviousSelectionBoxColor = SelectionBoxColor
				SelectionBoxColor = A5pk0.Color
				updateSelectionBoxColor()
				A5pk0:showGUI()
				table.insert(
					A5pk0.Connections,
					Selection.Changed:Connect(function()
						A5pk0:hideHandles()
						if Selection.Last then
							A5pk0:showHandles(Selection.Last)
						end
					end)
				)
				table.insert(
					A5pk0.Connections,
					Mouse.Button2Up:Connect(function()
						override_selection = true
						if Selection:find(Mouse.Target) then
							Selection:focus(Mouse.Target)
						end
					end)
				)
				if Selection.Last then
					A5pk0:showHandles(Selection.Last)
				end
				(coroutine.wrap(function()
					updater_on = true
					A5pk0.Updater = function()
						updater_on = false
					end
					while task.wait(0.1) and updater_on do
						if CurrentTool == A5pk0 then
							if A5pk0.GUI and A5pk0.GUI.Visible then
								A5pk0:updateGUI()
							end
						end
					end
				end))()
			end
			Tools.Resize.Listeners.Unequipped = function()
				local j = Tools.Resize
				if j.Updater then
					j.Updater()
					j.Updater = nil
				end
				j:hideGUI()
				j:hideHandles()
				for XE, vtfBBQgI in pairs(j.Connections) do
					vtfBBQgI:Disconnect()
					j.Connections[XE] = nil
				end
				SelectionBoxColor = j.State.PreviousSelectionBoxColor
				updateSelectionBoxColor()
			end
			Tools.Resize.Listeners.KeyUp = function(U1Ca2x)
				local AM_2j6 = Tools.Resize
				if U1Ca2x == "-" and AM_2j6.GUI then
					AM_2j6.GUI.IncrementOption.Increment.TextBox:CaptureFocus()
				end
			end
			Tools.Resize.showGUI = function(tqvqCh)
				if not tqvqCh.GUI then
					local wQb3 = DFb100j.BTResizeToolGUI:Clone()
					setp(wQb3, "Parent", UI)
					wQb3.DirectionsOption.Normal.Button.MouseButton1Down:Connect(function()
						tqvqCh.Options.directions = "normal"
						setp(wQb3.DirectionsOption.Normal.SelectedIndicator, "BackgroundTransparency", 0)
						setp(wQb3.DirectionsOption.Normal.Background, "Image", Assets.DarkSlantedRectangle)
						setp(wQb3.DirectionsOption.Both.SelectedIndicator, "BackgroundTransparency", 1)
						setp(wQb3.DirectionsOption.Both.Background, "Image", Assets.LightSlantedRectangle)
					end)
					wQb3.DirectionsOption.Both.Button.MouseButton1Down:Connect(function()
						tqvqCh.Options.directions = "both"
						setp(wQb3.DirectionsOption.Normal.SelectedIndicator, "BackgroundTransparency", 1)
						setp(wQb3.DirectionsOption.Normal.Background, "Image", Assets.LightSlantedRectangle)
						setp(wQb3.DirectionsOption.Both.SelectedIndicator, "BackgroundTransparency", 0)
						setp(wQb3.DirectionsOption.Both.Background, "Image", Assets.DarkSlantedRectangle)
					end)
					wQb3.IncrementOption.Increment.TextBox.FocusLost:Connect(function(MV_ePmkQ)
						tqvqCh.Options.increment = tonumber(wQb3.IncrementOption.Increment.TextBox.Text)
							or tqvqCh.Options.increment
						setp(wQb3.IncrementOption.Increment.TextBox, "Text", tostring(tqvqCh.Options.increment))
					end)
					wQb3.Info.SizeInfo.X.TextButton.MouseButton1Down:Connect(function()
						tqvqCh.State.size_x_focused = true
						wQb3.Info.SizeInfo.X.TextBox:CaptureFocus()
					end)
					wQb3.Info.SizeInfo.X.TextBox.FocusLost:Connect(function(cX3Y)
						local dOb = tonumber(wQb3.Info.SizeInfo.X.TextBox.Text)
						if dOb then
							tqvqCh:changeSize("x", dOb)
						end
						tqvqCh.State.size_x_focused = false
					end)
					wQb3.Info.SizeInfo.Y.TextButton.MouseButton1Down:Connect(function()
						tqvqCh.State.size_y_focused = true
						wQb3.Info.SizeInfo.Y.TextBox:CaptureFocus()
					end)
					wQb3.Info.SizeInfo.Y.TextBox.FocusLost:Connect(function(JTBnP)
						local Nm = tonumber(wQb3.Info.SizeInfo.Y.TextBox.Text)
						if Nm then
							tqvqCh:changeSize("y", Nm)
						end
						tqvqCh.State.size_y_focused = false
					end)
					wQb3.Info.SizeInfo.Z.TextButton.MouseButton1Down:Connect(function()
						tqvqCh.State.size_z_focused = true
						wQb3.Info.SizeInfo.Z.TextBox:CaptureFocus()
					end)
					wQb3.Info.SizeInfo.Z.TextBox.FocusLost:Connect(function(sCwnNPE)
						local J = tonumber(wQb3.Info.SizeInfo.Z.TextBox.Text)
						if J then
							tqvqCh:changeSize("z", J)
						end
						tqvqCh.State.size_z_focused = false
					end)
					tqvqCh.GUI = wQb3
				end
				setp(tqvqCh.GUI, "Visible", true)
			end
			Tools.Resize.startHistoryRecord = function(jUlV2)
				if jUlV2.State.HistoryRecord then
					jUlV2.State.HistoryRecord = nil
				end
				jUlV2.State.HistoryRecord = {
					targets = Support.CloneTable(Selection.Items),
					initial_positions = {},
					terminal_positions = {},
					initial_sizes = {},
					terminal_sizes = {},
					unapply = function(jUlV2)
						Selection:clear()
						for _WlOka, tFt48gVX in pairs(jUlV2.targets) do
							if tFt48gVX then
								setp(tFt48gVX, "Size", jUlV2.initial_sizes[tFt48gVX])
								setp(tFt48gVX, "CFrame", jUlV2.initial_positions[tFt48gVX])
								tFt48gVX:MakeJoints()
								Selection:add(tFt48gVX)
							end
						end
					end,
					apply = function(jUlV2)
						Selection:clear()
						for VcvWqUR, g9LOIN in pairs(jUlV2.targets) do
							if g9LOIN then
								setp(g9LOIN, "Size", jUlV2.terminal_sizes[g9LOIN])
								setp(g9LOIN, "CFrame", jUlV2.terminal_positions[g9LOIN])
								g9LOIN:MakeJoints()
								Selection:add(g9LOIN)
							end
						end
					end,
				}
				for Ldc7, OWMI6 in pairs(jUlV2.State.HistoryRecord.targets) do
					if OWMI6 then
						jUlV2.State.HistoryRecord.initial_sizes[OWMI6] = OWMI6.Size
						jUlV2.State.HistoryRecord.initial_positions[OWMI6] = OWMI6.CFrame
					end
				end
			end
			Tools.Resize.finishHistoryRecord = function(y)
				if not y.State.HistoryRecord then
					return
				end
				for PN, D4 in pairs(y.State.HistoryRecord.targets) do
					if D4 then
						y.State.HistoryRecord.terminal_sizes[D4] = D4.Size
						y.State.HistoryRecord.terminal_positions[D4] = D4.CFrame
					end
				end
				History:add(y.State.HistoryRecord)
				y.State.HistoryRecord = nil
			end
			Tools.Resize.changeSize = function(bqUq2I19, vfT16V9, Idod8USP)
				bqUq2I19:startHistoryRecord()
				for n, Enpu in pairs(Selection.Items) do
					local F = Enpu.CFrame
					if pcall(function()
							local ed = Enpu.FormFactor
						end) then
						setp(Enpu, "FormFactor", Enum.FormFactor.Custom)
					end
					Enpu.Size = Vector3.new(
						vfT16V9 == "x" and Idod8USP or Enpu.Size.x,
						vfT16V9 == "y" and Idod8USP or Enpu.Size.y,
						vfT16V9 == "z" and Idod8USP or Enpu.Size.z
					)
					setp(Enpu, "CFrame", F)
				end
				bqUq2I19:finishHistoryRecord()
			end
			Tools.Resize.updateGUI = function(QamDb5OV)
				if not QamDb5OV.GUI then
					return
				end
				local Jz = QamDb5OV.GUI
				if #Selection.Items > 0 then
					local by73, lQlrrh, XQtO = nil, nil, nil
					for JefwEh, sbbJI in pairs(Selection.Items) do
						if JefwEh == 1 then
							by73, lQlrrh, XQtO =
								Support.Round(sbbJI.Size.x, 2),
							Support.Round(sbbJI.Size.y, 2),
							Support.Round(sbbJI.Size.z, 2)
						else
							if by73 ~= Support.Round(sbbJI.Size.x, 2) then
								by73 = nil
							end
							if lQlrrh ~= Support.Round(sbbJI.Size.y, 2) then
								lQlrrh = nil
							end
							if XQtO ~= Support.Round(sbbJI.Size.z, 2) then
								XQtO = nil
							end
						end
					end
					if not QamDb5OV.State.size_x_focused then
						setp(Jz.Info.SizeInfo.X.TextBox, "Text", by73 and tostring(by73) or "*")
					end
					if not QamDb5OV.State.size_y_focused then
						setp(Jz.Info.SizeInfo.Y.TextBox, "Text", lQlrrh and tostring(lQlrrh) or "*")
					end
					if not QamDb5OV.State.size_z_focused then
						setp(Jz.Info.SizeInfo.Z.TextBox, "Text", XQtO and tostring(XQtO) or "*")
					end
					setp(Jz.Info, "Visible", true)
				else
					setp(Jz.Info, "Visible", false)
				end
				if QamDb5OV.State.length_resized then
					setp(Jz.Changes.Text, "Text", "resized " .. tostring(QamDb5OV.State.length_resized) .. " studs")
					setp(Jz.Changes, "Position", Jz.Info.Visible and UDim2.new(0, 5, 0, 165) or UDim2.new(0, 5, 0, 100))
					setp(Jz.Changes, "Visible", true)
				else
					setp(Jz.Changes.Text, "Text", "")
					setp(Jz.Changes, "Visible", false)
				end
			end
			Tools.Resize.hideGUI = function(QYayh)
				if QYayh.GUI then
					setp(QYayh.GUI, "Visible", false)
				end
			end
			Tools.Resize.showHandles = function(nr6uCL, FQ1oRl_)
				if not nr6uCL.Handles then
					nr6uCL.Handles = (RbxUtility.Create("Handles"))({
						Name = "BTResizeHandles",
						Style = Enum.HandlesStyle.Resize,
						Color = nr6uCL.Color,
						Parent = GUIContainer,
					})
					nr6uCL.Handles.MouseButton1Down:Connect(function()
						override_selection = true
						nr6uCL.State.resizing = true
						nr6uCL.State.length_resized = 0
						nr6uCL:startHistoryRecord()
						for Q, sHA_0P in pairs(Selection.Items) do
							nr6uCL.State.PreResize[sHA_0P] = sHA_0P:Clone()
							if pcall(function()
									local zskX = sHA_0P.FormFactor
								end) then
								setp(sHA_0P, "FormFactor", Enum.FormFactor.Custom)
							end
							setp(sHA_0P, "Anchored", true)
						end
						nr6uCL.Connections.HandleReleaseListener = Mouse.Button1Up:Connect(function()
							override_selection = true
							nr6uCL.State.resizing = false
							if nr6uCL.Connections.HandleReleaseListener then
								nr6uCL.Connections.HandleReleaseListener:Disconnect()
								nr6uCL.Connections.HandleReleaseListener = nil
							end
							nr6uCL:finishHistoryRecord()
							for z37Qz, MUu in pairs(nr6uCL.State.PreResize) do
								setp(z37Qz, "Anchored", MUu.Anchored)
								nr6uCL.State.PreResize[z37Qz] = nil
								z37Qz:MakeJoints()
							end
						end)
					end)
					nr6uCL.Handles.MouseDrag:Connect(function(rRNsXW, zslu25lH)
						local K = zslu25lH % nr6uCL.Options.increment
						local dBzmP = zslu25lH - K
						local obk = zslu25lH - K + nr6uCL.Options.increment
						local MsipHD_w = math.abs(zslu25lH - dBzmP)
						local uBw1Z77 = math.abs(zslu25lH - obk)
						if MsipHD_w <= uBw1Z77 then
							zslu25lH = dBzmP
						else
							zslu25lH = obk
						end
						local bdJJE = zslu25lH
						nr6uCL.State.previous_distance = zslu25lH
						if nr6uCL.Options.directions == "both" then
							bdJJE = zslu25lH * 2
						end
						nr6uCL.State.length_resized = bdJJE
						for spYT, lEPWTkAE in pairs(Selection.Items) do
							local S = lEPWTkAE:Clone()
							lEPWTkAE:BreakJoints()
							if rRNsXW == Enum.NormalId.Top then
								local Zbxec
								if
									pcall(function()
										local ViHDT = lEPWTkAE.Shape
									end)
										and (
											lEPWTkAE.Shape == Enum.PartType.Ball
											or lEPWTkAE.Shape == Enum.PartType.Cylinder
										)
								then
									Zbxec = Vector3.new(bdJJE, bdJJE, bdJJE)
								elseif
									not pcall(function()
										local fcbl4H = lEPWTkAE.Shape
									end) or lEPWTkAE.Shape and lEPWTkAE.Shape == Enum.PartType.Block
								then
									Zbxec = Vector3.new(0, bdJJE, 0)
								end
								setp(lEPWTkAE, "Size", nr6uCL.State.PreResize[lEPWTkAE].Size + Zbxec)
								if lEPWTkAE.Size == nr6uCL.State.PreResize[lEPWTkAE].Size + Zbxec then
									lEPWTkAE.CFrame = nr6uCL.Options.directions == "normal"
										and nr6uCL.State.PreResize[lEPWTkAE].CFrame:toWorldSpace(
											CFrame.new(0, bdJJE / 2, 0)
										)
										or nr6uCL.Options.directions == "both"
										and nr6uCL.State.PreResize[lEPWTkAE].CFrame
								else
									setp(lEPWTkAE, "Size", S.Size)
									setp(lEPWTkAE, "CFrame", S.CFrame)
								end
							elseif rRNsXW == Enum.NormalId.Bottom then
								local ora4Z
								if
									pcall(function()
										local wmfjOlWH = lEPWTkAE.Shape
									end)
										and (
											lEPWTkAE.Shape == Enum.PartType.Ball
											or lEPWTkAE.Shape == Enum.PartType.Cylinder
										)
								then
									ora4Z = Vector3.new(bdJJE, bdJJE, bdJJE)
								elseif
									not pcall(function()
										local d = lEPWTkAE.Shape
									end) or lEPWTkAE.Shape and lEPWTkAE.Shape == Enum.PartType.Block
								then
									ora4Z = Vector3.new(0, bdJJE, 0)
								end
								setp(lEPWTkAE, "Size", nr6uCL.State.PreResize[lEPWTkAE].Size + ora4Z)
								if lEPWTkAE.Size == nr6uCL.State.PreResize[lEPWTkAE].Size + ora4Z then
									lEPWTkAE.CFrame = nr6uCL.Options.directions == "normal"
										and nr6uCL.State.PreResize[lEPWTkAE].CFrame:toWorldSpace(
											CFrame.new(0, -bdJJE / 2, 0)
										)
										or nr6uCL.Options.directions == "both"
										and nr6uCL.State.PreResize[lEPWTkAE].CFrame
								else
									setp(lEPWTkAE, "Size", S.Size)
									setp(lEPWTkAE, "CFrame", S.CFrame)
								end
							elseif rRNsXW == Enum.NormalId.Front then
								local w60sb3_
								if
									pcall(function()
										local MCm__CEC = lEPWTkAE.Shape
									end)
										and (
											lEPWTkAE.Shape == Enum.PartType.Ball
											or lEPWTkAE.Shape == Enum.PartType.Cylinder
										)
								then
									w60sb3_ = Vector3.new(bdJJE, bdJJE, bdJJE)
								elseif
									not pcall(function()
										local Jr9hz4jk = lEPWTkAE.Shape
									end) or lEPWTkAE.Shape and lEPWTkAE.Shape == Enum.PartType.Block
								then
									w60sb3_ = Vector3.new(0, 0, bdJJE)
								end
								setp(lEPWTkAE, "Size", nr6uCL.State.PreResize[lEPWTkAE].Size + w60sb3_)
								if lEPWTkAE.Size == nr6uCL.State.PreResize[lEPWTkAE].Size + w60sb3_ then
									lEPWTkAE.CFrame = nr6uCL.Options.directions == "normal"
										and nr6uCL.State.PreResize[lEPWTkAE].CFrame:toWorldSpace(
											CFrame.new(0, 0, -bdJJE / 2)
										)
										or nr6uCL.Options.directions == "both"
										and nr6uCL.State.PreResize[lEPWTkAE].CFrame
								else
									setp(lEPWTkAE, "Size", S.Size)
									setp(lEPWTkAE, "CFrame", S.CFrame)
								end
							elseif rRNsXW == Enum.NormalId.Back then
								local Abv
								if
									pcall(function()
										local aqOk = lEPWTkAE.Shape
									end)
										and (
											lEPWTkAE.Shape == Enum.PartType.Ball
											or lEPWTkAE.Shape == Enum.PartType.Cylinder
										)
								then
									Abv = Vector3.new(bdJJE, bdJJE, bdJJE)
								elseif
									not pcall(function()
										local A4ZSOV = lEPWTkAE.Shape
									end) or lEPWTkAE.Shape and lEPWTkAE.Shape == Enum.PartType.Block
								then
									Abv = Vector3.new(0, 0, bdJJE)
								end
								setp(lEPWTkAE, "Size", nr6uCL.State.PreResize[lEPWTkAE].Size + Abv)
								if lEPWTkAE.Size == nr6uCL.State.PreResize[lEPWTkAE].Size + Abv then
									lEPWTkAE.CFrame = nr6uCL.Options.directions == "normal"
										and nr6uCL.State.PreResize[lEPWTkAE].CFrame:toWorldSpace(
											CFrame.new(0, 0, bdJJE / 2)
										)
										or nr6uCL.Options.directions == "both"
										and nr6uCL.State.PreResize[lEPWTkAE].CFrame
								else
									setp(lEPWTkAE, "Size", S.Size)
									setp(lEPWTkAE, "CFrame", S.CFrame)
								end
							elseif rRNsXW == Enum.NormalId.Left then
								local wtbkXqKs
								if
									pcall(function()
										local vX_5TSFO = lEPWTkAE.Shape
									end)
										and (
											lEPWTkAE.Shape == Enum.PartType.Ball
											or lEPWTkAE.Shape == Enum.PartType.Cylinder
										)
								then
									wtbkXqKs = Vector3.new(bdJJE, bdJJE, bdJJE)
								elseif
									not pcall(function()
										local MFweCJ3 = lEPWTkAE.Shape
									end) or lEPWTkAE.Shape and lEPWTkAE.Shape == Enum.PartType.Block
								then
									wtbkXqKs = Vector3.new(bdJJE, 0, 0)
								end
								setp(lEPWTkAE, "Size", nr6uCL.State.PreResize[lEPWTkAE].Size + wtbkXqKs)
								if lEPWTkAE.Size == nr6uCL.State.PreResize[lEPWTkAE].Size + wtbkXqKs then
									lEPWTkAE.CFrame = nr6uCL.Options.directions == "normal"
										and nr6uCL.State.PreResize[lEPWTkAE].CFrame:toWorldSpace(
											CFrame.new(-bdJJE / 2, 0, 0)
										)
										or nr6uCL.Options.directions == "both"
										and nr6uCL.State.PreResize[lEPWTkAE].CFrame
								else
									setp(lEPWTkAE, "Size", S.Size)
									setp(lEPWTkAE, "CFrame", S.CFrame)
								end
							elseif rRNsXW == Enum.NormalId.Right then
								local z6
								if
									pcall(function()
										local n0q2 = lEPWTkAE.Shape
									end)
										and (
											lEPWTkAE.Shape == Enum.PartType.Ball
											or lEPWTkAE.Shape == Enum.PartType.Cylinder
										)
								then
									z6 = Vector3.new(bdJJE, bdJJE, bdJJE)
								elseif
									not pcall(function()
										local X2UHF = lEPWTkAE.Shape
									end) or lEPWTkAE.Shape and lEPWTkAE.Shape == Enum.PartType.Block
								then
									z6 = Vector3.new(bdJJE, 0, 0)
								end
								setp(lEPWTkAE, "Size", nr6uCL.State.PreResize[lEPWTkAE].Size + z6)
								if lEPWTkAE.Size == nr6uCL.State.PreResize[lEPWTkAE].Size + z6 then
									lEPWTkAE.CFrame = nr6uCL.Options.directions == "normal"
										and nr6uCL.State.PreResize[lEPWTkAE].CFrame:toWorldSpace(
											CFrame.new(bdJJE / 2, 0, 0)
										)
										or nr6uCL.Options.directions == "both"
										and nr6uCL.State.PreResize[lEPWTkAE].CFrame
								else
									setp(lEPWTkAE, "Size", S.Size)
									setp(lEPWTkAE, "CFrame", S.CFrame)
								end
							end
							lEPWTkAE:MakeJoints()
						end
					end)
				end
				if nr6uCL.Connections.AdorneeExistenceListener then
					nr6uCL.Connections.AdorneeExistenceListener:Disconnect()
					nr6uCL.Connections.AdorneeExistenceListener = nil
				end
				setp(nr6uCL.Handles, "Adornee", FQ1oRl_)
				nr6uCL.Connections.AdorneeExistenceListener = FQ1oRl_.AncestryChanged:Connect(function(uanm, BJf2)
					if uanm ~= FQ1oRl_ then
						return
					end
					if BJf2 == nil then
						nr6uCL:hideHandles()
					else
						nr6uCL:showHandles(FQ1oRl_)
					end
				end)
			end
			Tools.Resize.hideHandles = function(bV)
				if bV.Handles then
					setp(bV.Handles, "Adornee", nil)
				end
			end
			Tools.Resize.Loaded = true
		end,
	},
	{
		"Rotate",
		function()
			repeat
				task.wait()
			until _G.BTCoreEnv and _G.BTCoreEnv.tool and _G.BTCoreEnv.tool.CoreReady
			setfenv(1, _G.BTCoreEnv.tool)
			Tools.Rotate = {}
			Tools.Rotate.Connections = {}
			Tools.Rotate.Options = {
				increment = 15,
				pivot = "center",
			}
			Tools.Rotate.State = {
				PreRotation = {},
				rotating = false,
				previous_distance = 0,
				degrees_rotated = 0,
				rotation_size = 0,
			}
			Tools.Rotate.Listeners = {}
			setp(Tools.Rotate, "Color", BrickColor.new("Bright green"))
			Tools.Rotate.Listeners.Equipped = function()
				local hhe = Tools.Rotate
				hhe.State.PreviousSelectionBoxColor = SelectionBoxColor
				SelectionBoxColor = hhe.Color
				updateSelectionBoxColor()
				hhe:showGUI()
				if not hhe.BoundingBox then
					hhe.BoundingBox = (RbxUtility.Create("Part"))({
						Name = "BTBoundingBox",
						CanCollide = false,
						Transparency = 1,
						Anchored = true,
					})
				end
				Mouse.TargetFilter = hhe.BoundingBox
				hhe:changePivot(hhe.Options.pivot)
				hhe.State.StaticItems = {}
				hhe.State.StaticExtents = nil
				hhe.State.RecalculateStaticExtents = true
				local hw = {}
				function AddStaticItem(Xjh2)
					if #Support.FindTableOccurrences(hhe.State.StaticItems, Xjh2) > 0 then
						return
					end
					table.insert(hhe.State.StaticItems, Xjh2)
					hw[Xjh2] = Xjh2.Changed:Connect(function(wS)
						if wS == "CFrame" or wS == "Size" then
							hhe.State.RecalculateStaticExtents = true
						elseif wS == "Anchored" and not Xjh2.Anchored then
							RemoveStaticItem(Xjh2)
						end
					end)
					hhe.State.RecalculateStaticExtents = true
				end
				function RemoveStaticItem(SxbR)
					local G = (Support.FindTableOccurrences(hhe.State.StaticItems, SxbR))[1]
					if G then
						hhe.State.StaticItems[G] = nil
					end
					if hw[SxbR] then
						hw[SxbR]:Disconnect()
						hw[SxbR] = nil
					end
					hhe.State.RecalculateStaticExtents = true
				end
				for ufs, rBbV5m in pairs(Selection.Items) do
					if rBbV5m.Anchored then
						AddStaticItem(rBbV5m)
					end
				end
				table.insert(
					hhe.Connections,
					Selection.ItemAdded:Connect(function(v)
						if v.Anchored then
							AddStaticItem(v)
						end
					end)
				)
				table.insert(
					hhe.Connections,
					Selection.ItemRemoved:Connect(function(L_4ez, ILvdT1AO)
						if ILvdT1AO or not hw[L_4ez] then
							return
						end
						RemoveStaticItem(L_4ez)
					end)
				)
				table.insert(
					hhe.Connections,
					Selection.Cleared:Connect(function()
						for X, iiB in pairs(hw) do
							iiB:Disconnect()
							hw[X] = nil
						end
						hhe.State.StaticExtents = nil
						hhe.State.StaticItems = {}
					end)
				);
				(coroutine.wrap(function()
					updater_on = true
					hhe.Updater = function()
						updater_on = false
					end
					while task.wait(0.1) and updater_on do
						if CurrentTool == hhe then
							if hhe.GUI and hhe.GUI.Visible then
								hhe:updateGUI()
							end
							if hhe.Options.pivot == "center" then
								hhe:updateBoundingBox()
							end
						end
					end
				end))()
				SelectEdge:start(function(Ai9ugkhp)
					hhe:changePivot("last")
					hhe.Options.PivotPoint = Ai9ugkhp.CFrame
					hhe.Connections.EdgeSelectionRemover = Selection.Changed:Connect(function()
						hhe.Options.PivotPoint = nil
						if hhe.Connections.EdgeSelectionRemover then
							hhe.Connections.EdgeSelectionRemover:Disconnect()
							hhe.Connections.EdgeSelectionRemover = nil
						end
					end)
					hhe:showHandles(Ai9ugkhp)
				end)
			end
			Tools.Rotate.Listeners.Unequipped = function()
				local vx0 = Tools.Rotate
				if vx0.Updater then
					vx0.Updater()
					vx0.Updater = nil
				end
				SelectEdge:stop()
				if vx0.Options.PivotPoint then
					vx0.Options.PivotPoint = nil
				end
				vx0:hideGUI()
				vx0:hideHandles()
				for oTT0I_tH, d in pairs(vx0.Connections) do
					d:Disconnect()
					vx0.Connections[oTT0I_tH] = nil
				end
				SelectionBoxColor = vx0.State.PreviousSelectionBoxColor
				updateSelectionBoxColor()
			end
			Tools.Rotate.Listeners.Button1Down = function()
				local HF = Tools.Rotate
				if not HF.State.rotating and HF.Options.PivotPoint then
					HF.Options.PivotPoint = nil
				end
			end
			Tools.Rotate.Listeners.KeyUp = function(ORg_K6y)
				local Y0 = Tools.Rotate
				if ORg_K6y == "-" and Y0.GUI then
					Y0.GUI.IncrementOption.Increment.TextBox:CaptureFocus()
				end
			end
			Tools.Rotate.showGUI = function(gwII)
				if not gwII.GUI then
					local ItMCtiyJ = DFb100j.BTRotateToolGUI:Clone()
					setp(ItMCtiyJ, "Parent", UI)
					ItMCtiyJ.PivotOption.Center.Button.MouseButton1Down:Connect(function()
						gwII:changePivot("center")
					end)
					ItMCtiyJ.PivotOption.Local.Button.MouseButton1Down:Connect(function()
						gwII:changePivot("local")
					end)
					ItMCtiyJ.PivotOption.Last.Button.MouseButton1Down:Connect(function()
						gwII:changePivot("last")
					end)
					ItMCtiyJ.IncrementOption.Increment.TextBox.FocusLost:Connect(function(iXtk)
						gwII.Options.increment = tonumber(ItMCtiyJ.IncrementOption.Increment.TextBox.Text)
							or gwII.Options.increment
						setp(ItMCtiyJ.IncrementOption.Increment.TextBox, "Text", tostring(gwII.Options.increment))
					end)
					ItMCtiyJ.Info.RotationInfo.X.TextButton.MouseButton1Down:Connect(function()
						gwII.State.rot_x_focused = true
						ItMCtiyJ.Info.RotationInfo.X.TextBox:CaptureFocus()
					end)
					ItMCtiyJ.Info.RotationInfo.X.TextBox.FocusLost:Connect(function(snG)
						local V5j = tonumber(ItMCtiyJ.Info.RotationInfo.X.TextBox.Text)
						if V5j then
							gwII:changeRotation("x", math.rad(V5j))
						end
						gwII.State.rot_x_focused = false
					end)
					ItMCtiyJ.Info.RotationInfo.Y.TextButton.MouseButton1Down:Connect(function()
						gwII.State.rot_y_focused = true
						ItMCtiyJ.Info.RotationInfo.Y.TextBox:CaptureFocus()
					end)
					ItMCtiyJ.Info.RotationInfo.Y.TextBox.FocusLost:Connect(function(lItF)
						local xq1bs = tonumber(ItMCtiyJ.Info.RotationInfo.Y.TextBox.Text)
						if xq1bs then
							gwII:changeRotation("y", math.rad(xq1bs))
						end
						gwII.State.rot_y_focused = false
					end)
					ItMCtiyJ.Info.RotationInfo.Z.TextButton.MouseButton1Down:Connect(function()
						gwII.State.rot_z_focused = true
						ItMCtiyJ.Info.RotationInfo.Z.TextBox:CaptureFocus()
					end)
					ItMCtiyJ.Info.RotationInfo.Z.TextBox.FocusLost:Connect(function(F)
						local Oro89 = tonumber(ItMCtiyJ.Info.RotationInfo.Z.TextBox.Text)
						if Oro89 then
							gwII:changeRotation("z", math.rad(Oro89))
						end
						gwII.State.rot_z_focused = false
					end)
					gwII.GUI = ItMCtiyJ
				end
				setp(gwII.GUI, "Visible", true)
			end
			Tools.Rotate.startHistoryRecord = function(O_dX)
				if O_dX.State.HistoryRecord then
					O_dX.State.HistoryRecord = nil
				end
				O_dX.State.HistoryRecord = {
					targets = Support.CloneTable(Selection.Items),
					initial_cframes = {},
					terminal_cframes = {},
					unapply = function(O_dX)
						Selection:clear()
						for k3U, p8 in pairs(O_dX.targets) do
							if p8 then
								setp(p8, "CFrame", O_dX.initial_cframes[p8])
								p8:MakeJoints()
								Selection:add(p8)
							end
						end
					end,
					apply = function(O_dX)
						Selection:clear()
						for BLvFfZ, _ in pairs(O_dX.targets) do
							if _ then
								setp(_, "CFrame", O_dX.terminal_cframes[_])
								_:MakeJoints()
								Selection:add(_)
							end
						end
					end,
				}
				for dAcD, e in pairs(O_dX.State.HistoryRecord.targets) do
					if e then
						O_dX.State.HistoryRecord.initial_cframes[e] = e.CFrame
					end
				end
			end
			Tools.Rotate.finishHistoryRecord = function(RG)
				if not RG.State.HistoryRecord then
					return
				end
				for Y, htKd_R2 in pairs(RG.State.HistoryRecord.targets) do
					if htKd_R2 then
						RG.State.HistoryRecord.terminal_cframes[htKd_R2] = htKd_R2.CFrame
					end
				end
				History:add(RG.State.HistoryRecord)
				RG.State.HistoryRecord = nil
			end
			Tools.Rotate.changeRotation = function(vr, ylrttgX, L)
				vr:startHistoryRecord()
				for I, KYV in pairs(Selection.Items) do
					local d, sBB, vvEDp5PM = KYV.CFrame:toEulerAnglesXYZ()
					KYV.CFrame = CFrame.new(KYV.Position)
						* CFrame.Angles(
							(ylrttgX == "x" and L or d),
							(ylrttgX == "y" and L or sBB),
							(ylrttgX == "z" and L or vvEDp5PM)
						)
				end
				vr:finishHistoryRecord()
			end
			Tools.Rotate.updateGUI = function(EBzZ)
				if not EBzZ.GUI then
					return
				end
				local JnR5AeB = EBzZ.GUI
				if #Selection.Items > 0 then
					local vfXvA0O, OZRh, eNaZt = nil, nil, nil
					for eE49cc, n_Q69rHB in pairs(Selection.Items) do
						local h2_ty, zHG, FYzFO1 = n_Q69rHB.CFrame:toEulerAnglesXYZ()
						if eE49cc == 1 then
							vfXvA0O, OZRh, eNaZt =
								Support.Round(math.deg(h2_ty), 2),
							Support.Round(math.deg(zHG), 2),
							Support.Round(math.deg(FYzFO1), 2)
						else
							if vfXvA0O ~= Support.Round(math.deg(h2_ty), 2) then
								vfXvA0O = nil
							end
							if OZRh ~= Support.Round(math.deg(zHG), 2) then
								OZRh = nil
							end
							if eNaZt ~= Support.Round(math.deg(FYzFO1), 2) then
								eNaZt = nil
							end
						end
					end
					if not EBzZ.State.rot_x_focused then
						setp(JnR5AeB.Info.RotationInfo.X.TextBox, "Text", vfXvA0O and tostring(vfXvA0O) or "*")
					end
					if not EBzZ.State.rot_y_focused then
						setp(JnR5AeB.Info.RotationInfo.Y.TextBox, "Text", OZRh and tostring(OZRh) or "*")
					end
					if not EBzZ.State.rot_z_focused then
						setp(JnR5AeB.Info.RotationInfo.Z.TextBox, "Text", eNaZt and tostring(eNaZt) or "*")
					end
					setp(JnR5AeB.Info, "Visible", true)
				else
					setp(JnR5AeB.Info, "Visible", false)
				end
				if EBzZ.State.degrees_rotated then
					setp(JnR5AeB.Changes.Text, "Text", "rotated " .. tostring(EBzZ.State.degrees_rotated) .. " degrees")
					JnR5AeB.Changes.Position = JnR5AeB.Info.Visible and UDim2.new(0, 5, 0, 165)
						or UDim2.new(0, 5, 0, 100)
					setp(JnR5AeB.Changes, "Visible", true)
				else
					setp(JnR5AeB.Changes.Text, "Text", "")
					setp(JnR5AeB.Changes, "Visible", false)
				end
			end
			Tools.Rotate.hideGUI = function(gR48Oozb)
				if gR48Oozb.GUI then
					setp(gR48Oozb.GUI, "Visible", false)
				end
			end
			Tools.Rotate.updateBoundingBox = function(bK0bhdq)
				if #Selection.Items > 0 then
					if bK0bhdq.State.RecalculateStaticExtents then
						bK0bhdq.State.StaticExtents = calculateExtents(bK0bhdq.State.StaticItems, nil, true)
						bK0bhdq.State.RecalculateStaticExtents = false
					end
					local nP, eN5tc = calculateExtents(Selection.Items, bK0bhdq.State.StaticExtents)
					setp(bK0bhdq.BoundingBox, "Size", nP)
					setp(bK0bhdq.BoundingBox, "CFrame", eN5tc)
					bK0bhdq:showHandles(bK0bhdq.BoundingBox)
				else
					bK0bhdq:hideHandles()
				end
			end
			Tools.Rotate.changePivot = function(KehBOft6, R)
				local ao5 = KehBOft6.GUI and KehBOft6.GUI.PivotOption or nil
				if KehBOft6.Connections.HandleFocusChangeListener then
					KehBOft6.Connections.HandleFocusChangeListener:Disconnect()
					KehBOft6.Connections.HandleFocusChangeListener = nil
				end
				if KehBOft6.Connections.HandleSelectionChangeListener then
					KehBOft6.Connections.HandleSelectionChangeListener:Disconnect()
					KehBOft6.Connections.HandleSelectionChangeListener = nil
				end
				if KehBOft6.Options.PivotPoint then
					KehBOft6.Options.PivotPoint = nil
				end
				if R == "center" then
					KehBOft6.Options.pivot = "center"
					KehBOft6:showHandles(KehBOft6.BoundingBox)
					if KehBOft6.GUI then
						setp(ao5.Center.SelectedIndicator, "BackgroundTransparency", 0)
						setp(ao5.Center.Background, "Image", Assets.DarkSlantedRectangle)
						setp(ao5.Local.SelectedIndicator, "BackgroundTransparency", 1)
						setp(ao5.Local.Background, "Image", Assets.LightSlantedRectangle)
						setp(ao5.Last.SelectedIndicator, "BackgroundTransparency", 1)
						setp(ao5.Last.Background, "Image", Assets.LightSlantedRectangle)
					end
				end
				if R == "local" then
					KehBOft6.Options.pivot = "local"
					KehBOft6.Connections.HandleSelectionChangeListener = Selection.Changed:Connect(function()
						KehBOft6:hideHandles()
						if Selection.Last then
							KehBOft6:showHandles(Selection.Last)
						end
					end)
					KehBOft6.Connections.HandleFocusChangeListener = Mouse.Button2Up:Connect(function()
						override_selection = true
						if Selection:find(Mouse.Target) then
							Selection:focus(Mouse.Target)
							KehBOft6:showHandles(Mouse.Target)
						end
					end)
					if Selection.Last then
						KehBOft6:showHandles(Selection.Last)
					end
					if KehBOft6.GUI then
						setp(ao5.Center.SelectedIndicator, "BackgroundTransparency", 1)
						setp(ao5.Center.Background, "Image", Assets.LightSlantedRectangle)
						setp(ao5.Local.SelectedIndicator, "BackgroundTransparency", 0)
						setp(ao5.Local.Background, "Image", Assets.DarkSlantedRectangle)
						setp(ao5.Last.SelectedIndicator, "BackgroundTransparency", 1)
						setp(ao5.Last.Background, "Image", Assets.LightSlantedRectangle)
					end
				end
				if R == "last" then
					KehBOft6.Options.pivot = "last"
					KehBOft6.Connections.HandleSelectionChangeListener = Selection.Changed:Connect(function()
						if not KehBOft6.Options.PivotPoint then
							KehBOft6:hideHandles()
						end
						if Selection.Last and not KehBOft6.Options.PivotPoint then
							KehBOft6:showHandles(Selection.Last)
						end
					end)
					KehBOft6.Connections.HandleFocusChangeListener = Mouse.Button2Up:Connect(function()
						override_selection = true
						if Selection:find(Mouse.Target) then
							Selection:focus(Mouse.Target)
							KehBOft6:showHandles(Mouse.Target)
						end
					end)
					if Selection.Last then
						KehBOft6:showHandles(Selection.Last)
					end
					if KehBOft6.GUI then
						setp(ao5.Center.SelectedIndicator, "BackgroundTransparency", 1)
						setp(ao5.Center.Background, "Image", Assets.LightSlantedRectangle)
						setp(ao5.Local.SelectedIndicator, "BackgroundTransparency", 1)
						setp(ao5.Local.Background, "Image", Assets.LightSlantedRectangle)
						setp(ao5.Last.SelectedIndicator, "BackgroundTransparency", 0)
						setp(ao5.Last.Background, "Image", Assets.DarkSlantedRectangle)
					end
				end
			end
			Tools.Rotate.showHandles = function(oZy, oZ)
				if not oZy.Handles then
					oZy.Handles = (RbxUtility.Create("ArcHandles"))({
						Name = "BTRotationHandles",
						Color = oZy.Color,
						Parent = GUIContainer,
					})
					oZy.Handles.MouseButton1Down:Connect(function()
						override_selection = true
						oZy.State.rotating = true
						oZy.State.degrees_rotated = 0
						oZy.State.rotation_size = 0
						oZy:startHistoryRecord()
						for idRDAlB, tXR1E510 in pairs(Selection.Items) do
							oZy.State.PreRotation[tXR1E510] = tXR1E510:Clone()
							setp(tXR1E510, "Anchored", true)
						end
						local ndeNBp, o76bqPp = calculateExtents(oZy.State.PreRotation)
						oZy.State.PreRotationPosition = o76bqPp
						oZy.Connections.HandleReleaseListener = Mouse.Button1Up:Connect(function()
							override_selection = true
							oZy.State.rotating = false
							if oZy.Connections.HandleReleaseListener then
								oZy.Connections.HandleReleaseListener:Disconnect()
								oZy.Connections.HandleReleaseListener = nil
							end
							oZy:finishHistoryRecord()
							for ZawK6, bK in pairs(oZy.State.PreRotation) do
								setp(ZawK6, "Anchored", bK.Anchored)
								oZy.State.PreRotation[ZawK6] = nil
								ZawK6:MakeJoints()
							end
						end)
					end)
					oZy.Handles.MouseDrag:Connect(function(OJGVLn, UzgoE5O)
						local UzgoE5O = math.floor(math.deg(UzgoE5O))
						local RvHs = UzgoE5O % oZy.Options.increment
						local u = UzgoE5O - RvHs
						local Anrb = UzgoE5O - RvHs + oZy.Options.increment
						local C9lJAfo = math.abs(UzgoE5O - u)
						local NeSAkW = math.abs(UzgoE5O - Anrb)
						if C9lJAfo <= NeSAkW then
							UzgoE5O = u
						else
							UzgoE5O = Anrb
						end
						local Ccoa = oZy.Options.increment * math.floor((UzgoE5O / oZy.Options.increment))
						oZy.State.degrees_rotated = UzgoE5O
						for Y, zljPh in pairs(Selection.Items) do
							local C7mQfN = zljPh:Clone()
							zljPh:BreakJoints()
							if OJGVLn == Enum.Axis.Y then
								if oZy.Options.pivot == "center" then
									zljPh.CFrame = (oZy.State.PreRotationPosition:toWorldSpace(
										CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(Ccoa), 0)
										)):toWorldSpace(
										(oZy.State.PreRotation[zljPh].CFrame:toObjectSpace(
											oZy.State.PreRotationPosition
											)):inverse()
									)
								elseif oZy.Options.pivot == "local" then
									zljPh.CFrame = oZy.State.PreRotation[zljPh].CFrame:toWorldSpace(
										CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(Ccoa), 0)
									)
								elseif oZy.Options.pivot == "last" then
									zljPh.CFrame = ((
										oZy.Options.PivotPoint or oZy.State.PreRotation[Selection.Last].CFrame
										):toWorldSpace(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(Ccoa), 0))):toWorldSpace(
										(oZy.State.PreRotation[zljPh].CFrame:toObjectSpace(
											oZy.Options.PivotPoint or oZy.State.PreRotation[Selection.Last].CFrame
											)):inverse()
									)
								end
							elseif OJGVLn == Enum.Axis.X then
								if oZy.Options.pivot == "center" then
									zljPh.CFrame = (oZy.State.PreRotationPosition:toWorldSpace(
										CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(Ccoa), 0, 0)
										)):toWorldSpace(
										(oZy.State.PreRotation[zljPh].CFrame:toObjectSpace(
											oZy.State.PreRotationPosition
											)):inverse()
									)
								elseif oZy.Options.pivot == "local" then
									zljPh.CFrame = oZy.State.PreRotation[zljPh].CFrame:toWorldSpace(
										CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(Ccoa), 0, 0)
									)
								elseif oZy.Options.pivot == "last" then
									zljPh.CFrame = ((
										oZy.Options.PivotPoint or oZy.State.PreRotation[Selection.Last].CFrame
										):toWorldSpace(CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(Ccoa), 0, 0))):toWorldSpace(
										(oZy.State.PreRotation[zljPh].CFrame:toObjectSpace(
											oZy.Options.PivotPoint or oZy.State.PreRotation[Selection.Last].CFrame
											)):inverse()
									)
								end
							elseif OJGVLn == Enum.Axis.Z then
								if oZy.Options.pivot == "center" then
									zljPh.CFrame = (oZy.State.PreRotationPosition:toWorldSpace(
										CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(Ccoa))
										)):toWorldSpace(
										(oZy.State.PreRotation[zljPh].CFrame:toObjectSpace(
											oZy.State.PreRotationPosition
											)):inverse()
									)
								elseif oZy.Options.pivot == "local" then
									zljPh.CFrame = oZy.State.PreRotation[zljPh].CFrame:toWorldSpace(
										CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(Ccoa))
									)
								elseif oZy.Options.pivot == "last" then
									zljPh.CFrame = ((
										oZy.Options.PivotPoint or oZy.State.PreRotation[Selection.Last].CFrame
										):toWorldSpace(CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(Ccoa)))):toWorldSpace(
										(oZy.State.PreRotation[zljPh].CFrame:toObjectSpace(
											oZy.Options.PivotPoint or oZy.State.PreRotation[Selection.Last].CFrame
											)):inverse()
									)
								end
							end
							zljPh:MakeJoints()
						end
					end)
				end
				if oZy.Connections.AdorneeExistenceListener then
					oZy.Connections.AdorneeExistenceListener:Disconnect()
					oZy.Connections.AdorneeExistenceListener = nil
				end
				setp(oZy.Handles, "Adornee", oZ)
				oZy.Connections.AdorneeExistenceListener = oZ.AncestryChanged:Connect(function(hIkuxuG, wSnPWSA8)
					if hIkuxuG ~= oZ then
						return
					end
					if wSnPWSA8 == nil then
						oZy:hideHandles()
					else
						oZy:showHandles(oZ)
					end
				end)
			end
			Tools.Rotate.hideHandles = function(Ktu1)
				if Ktu1.Handles then
					setp(Ktu1.Handles, "Adornee", nil)
				end
			end
			Tools.Rotate.Loaded = true
		end,
	},
	{
		"Surface",
		function()
			repeat
				task.wait()
			until _G.BTCoreEnv and _G.BTCoreEnv.tool and _G.BTCoreEnv.tool.CoreReady
			setfenv(1, _G.BTCoreEnv.tool)
			Tools.Surface = {}
			setp(Tools.Surface, "Color", BrickColor.new("Bright violet"))
			Tools.Surface.Connections = {}
			Tools.Surface.State = {
				type = nil,
			}
			Tools.Surface.Options = {
				side = Enum.NormalId.Front,
			}
			Tools.Surface.Listeners = {}
			Tools.Surface.Listeners.Equipped = function()
				local g = Tools.Surface
				g.State.PreviousSelectionBoxColor = SelectionBoxColor
				SelectionBoxColor = g.Color
				updateSelectionBoxColor()
				g:showGUI()
				g:changeSurface(g.Options.side);
				(coroutine.wrap(function()
					updater_on = true
					g.Updater = function()
						updater_on = false
					end
					while task.wait(0.1) and updater_on do
						if CurrentTool == g then
							local R = {}
							if g.Options.side == "*" then
								for t, jYRxYT in pairs(Selection.Items) do
									table.insert(R, jYRxYT.TopSurface)
									table.insert(R, jYRxYT.BottomSurface)
									table.insert(R, jYRxYT.LeftSurface)
									table.insert(R, jYRxYT.RightSurface)
									table.insert(R, jYRxYT.FrontSurface)
									table.insert(R, jYRxYT.BackSurface)
								end
							else
								local kd = g.Options.side.Name .. "Surface"
								for kalNjedc, b2Pn in pairs(Selection.Items) do
									table.insert(R, b2Pn[kd])
								end
							end
							local WiBcS8j = Support.IdentifyCommonItem(R)
							g.State.type = WiBcS8j
							if g.GUI and g.GUI.Visible then
								g:updateGUI()
							end
						end
					end
				end))()
			end
			Tools.Surface.Listeners.Unequipped = function()
				local trdghrt = Tools.Surface
				if trdghrt.Updater then
					trdghrt.Updater()
					trdghrt.Updater = nil
				end
				trdghrt:hideGUI()
				for J, y1gHSu in pairs(trdghrt.Connections) do
					y1gHSu:Disconnect()
					trdghrt.Connections[J] = nil
				end
				SelectionBoxColor = trdghrt.State.PreviousSelectionBoxColor
				updateSelectionBoxColor()
			end
			Tools.Surface.Listeners.Button2Down = function()
				local lF3FR = Tools.Surface
				local _HG, W, rEJdQN = Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ()
				lF3FR.State.PreB2DownCameraRotation = Vector3.new(_HG, W, rEJdQN)
			end
			Tools.Surface.Listeners.Button2Up = function()
				local HF6Ag = Tools.Surface
				local Y, TEM, jWvh = Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ()
				local YO_aE9lks = Vector3.new(Y, TEM, jWvh)
				if Selection:find(Mouse.Target) and HF6Ag.State.PreB2DownCameraRotation == YO_aE9lks then
					HF6Ag:changeSurface(Mouse.TargetSurface)
				end
			end
			Tools.Surface.startHistoryRecord = function(wuF)
				if wuF.State.HistoryRecord then
					wuF.State.HistoryRecord = nil
				end
				wuF.State.HistoryRecord = {
					targets = Support.CloneTable(Selection.Items),
					target_surface = wuF.Options.side,
					initial_surfaces = {},
					terminal_surfaces = {},
					unapply = function(wuF)
						Selection:clear()
						for ipXc, EgbUS in pairs(wuF.targets) do
							if EgbUS then
								for XJ, RDsGq in pairs(wuF.initial_surfaces[EgbUS]) do
									EgbUS[XJ] = RDsGq
								end
								EgbUS:MakeJoints()
								Selection:add(EgbUS)
							end
						end
					end,
					apply = function(wuF)
						Selection:clear()
						for wg6c1w, iPEJyOaN in pairs(wuF.targets) do
							if iPEJyOaN then
								for D0, a223 in pairs(wuF.terminal_surfaces[iPEJyOaN]) do
									iPEJyOaN[D0] = a223
								end
								iPEJyOaN:MakeJoints()
								Selection:add(iPEJyOaN)
							end
						end
					end,
				}
				for px4R7I, a in pairs(wuF.State.HistoryRecord.targets) do
					if a then
						wuF.State.HistoryRecord.initial_surfaces[a] = {}
						if wuF.State.HistoryRecord.target_surface == "*" then
							wuF.State.HistoryRecord.initial_surfaces[a].RightSurface = a.RightSurface
							wuF.State.HistoryRecord.initial_surfaces[a].LeftSurface = a.LeftSurface
							wuF.State.HistoryRecord.initial_surfaces[a].FrontSurface = a.FrontSurface
							wuF.State.HistoryRecord.initial_surfaces[a].BackSurface = a.BackSurface
							wuF.State.HistoryRecord.initial_surfaces[a].TopSurface = a.TopSurface
							wuF.State.HistoryRecord.initial_surfaces[a].BottomSurface = a.BottomSurface
						else
							wuF.State.HistoryRecord.initial_surfaces[a][wuF.State.HistoryRecord.target_surface.Name .. "Surface"] =
								a[wuF.State.HistoryRecord.target_surface.Name .. "Surface"]
						end
					end
				end
			end
			Tools.Surface.finishHistoryRecord = function(I29)
				if not I29.State.HistoryRecord then
					return
				end
				for a, qji75cGk in pairs(I29.State.HistoryRecord.targets) do
					if qji75cGk then
						I29.State.HistoryRecord.terminal_surfaces[qji75cGk] = {}
						if I29.State.HistoryRecord.target_surface == "*" then
							I29.State.HistoryRecord.terminal_surfaces[qji75cGk].RightSurface = qji75cGk.RightSurface
							I29.State.HistoryRecord.terminal_surfaces[qji75cGk].LeftSurface = qji75cGk.LeftSurface
							I29.State.HistoryRecord.terminal_surfaces[qji75cGk].FrontSurface = qji75cGk.FrontSurface
							I29.State.HistoryRecord.terminal_surfaces[qji75cGk].BackSurface = qji75cGk.BackSurface
							I29.State.HistoryRecord.terminal_surfaces[qji75cGk].TopSurface = qji75cGk.TopSurface
							I29.State.HistoryRecord.terminal_surfaces[qji75cGk].BottomSurface = qji75cGk.BottomSurface
						else
							I29.State.HistoryRecord.terminal_surfaces[qji75cGk][I29.State.HistoryRecord.target_surface.Name .. "Surface"] =
								qji75cGk[I29.State.HistoryRecord.target_surface.Name .. "Surface"]
						end
					end
				end
				History:add(I29.State.HistoryRecord)
				I29.State.HistoryRecord = nil
			end
			Tools.Surface.SpecialTypeNames = {
				SmoothNoOutlines = "NO OUTLINE",
				Inlet = "INLETS",
			}
			Tools.Surface.changeType = function(BRk_bg, B97ZvZrX)
				BRk_bg:startHistoryRecord()
				for DINB, rvLAm9 in pairs(Selection.Items) do
					if BRk_bg.Options.side == "*" then
						setp(rvLAm9, "FrontSurface", B97ZvZrX)
						setp(rvLAm9, "BackSurface", B97ZvZrX)
						setp(rvLAm9, "RightSurface", B97ZvZrX)
						setp(rvLAm9, "LeftSurface", B97ZvZrX)
						setp(rvLAm9, "TopSurface", B97ZvZrX)
						setp(rvLAm9, "BottomSurface", B97ZvZrX)
					else
						rvLAm9[BRk_bg.Options.side.Name .. "Surface"] = B97ZvZrX
					end
					rvLAm9:MakeJoints()
				end
				BRk_bg:finishHistoryRecord()
				BRk_bg.TypeDropdown:selectOption(fmtEnum(B97ZvZrX, BRk_bg.SpecialTypeNames))
				if BRk_bg.TypeDropdown.open then
					BRk_bg.TypeDropdown:toggle()
				end
			end
			Tools.Surface.changeSurface = function(E, Im)
				E.Options.side = Im
				E.SideDropdown:selectOption(Im == "*" and "ALL" or fmtEnum(Im))
				if E.SideDropdown.open then
					E.SideDropdown:toggle()
				end
			end
			Tools.Surface.updateGUI = function(yWsj)
				if not yWsj.GUI then
					return
				end
				if #Selection.Items > 0 then
					yWsj.TypeDropdown:selectOption(yWsj.State.type and fmtEnum(yWsj.State.type, yWsj.SpecialTypeNames) or "*")
				else
					yWsj.TypeDropdown:selectOption("")
				end
			end
			Tools.Surface.showGUI = function(MFbe)
				if not MFbe.GUI then
					local i = DFb100j.BTSurfaceToolGUI:Clone()
					setp(i, "Parent", UI)
					local ayLU = createDropdown()
					MFbe.SideDropdown = ayLU
					setp(ayLU.Frame, "Parent", i.SideOption)
					setp(ayLU.Frame, "Position", UDim2.new(0, 30, 0, 0))
					setp(ayLU.Frame, "Size", UDim2.new(0, 72, 0, 25));
					addEnum(ayLU, Enum.NormalId, function(x)
						MFbe:changeSurface(x)
					end, nil, nil, { { "ALL", "*" } })
					local T2y = createDropdown()
					MFbe.TypeDropdown = T2y
					setp(T2y.Frame, "Parent", i.TypeOption)
					setp(T2y.Frame, "Position", UDim2.new(0, 30, 0, 0))
					setp(T2y.Frame, "Size", UDim2.new(0, 87, 0, 25));
					addEnum(T2y, Enum.SurfaceType, function(x)
						MFbe:changeType(x)
					end, MFbe.SpecialTypeNames)
					MFbe.GUI = i
				end
				setp(MFbe.GUI, "Visible", true)
			end
			Tools.Surface.hideGUI = function(QgLdZF)
				if QgLdZF.GUI then
					setp(QgLdZF.GUI, "Visible", false)
				end
			end
			Tools.Surface.Loaded = true
		end,
	},
	{
		"Texture",
		function()
			repeat
				task.wait()
			until _G.BTCoreEnv and _G.BTCoreEnv.tool and _G.BTCoreEnv.tool.CoreReady
			setfenv(1, _G.BTCoreEnv.tool)
			Tools.Texture = {}
			setp(Tools.Texture, "Color", BrickColor.new("Bright violet"))
			Tools.Texture.Options = {
				side = Enum.NormalId.Front,
				mode = "decal",
			}
			Tools.Texture.State = {}
			Tools.Texture.Connections = {}
			Tools.Texture.Listeners = {}
			Tools.Texture.Listeners.Equipped = function()
				local XGyz6oE = Tools.Texture
				XGyz6oE.State.PreviousSelectionBoxColor = SelectionBoxColor
				SelectionBoxColor = XGyz6oE.Color
				updateSelectionBoxColor()
				XGyz6oE:showGUI()
				XGyz6oE:changeSide(XGyz6oE.Options.side)
				XGyz6oE:changeMode(XGyz6oE.Options.mode);
				(coroutine.wrap(function()
					updater_on = true
					XGyz6oE.Updater = function()
						updater_on = false
					end
					while task.wait(0.1) and updater_on do
						if CurrentTool == XGyz6oE then
							if XGyz6oE.GUI and XGyz6oE.GUI.Visible then
								XGyz6oE:updateGUI()
							end
						end
					end
				end))()
			end
			Tools.Texture.Listeners.Unequipped = function()
				local i3NlQ94 = Tools.Texture
				if i3NlQ94.Updater then
					i3NlQ94.Updater()
					i3NlQ94.Updater = nil
				end
				i3NlQ94:hideGUI()
				for RnFNLp, wOOFocF in pairs(i3NlQ94.Connections) do
					wOOFocF:Disconnect()
					i3NlQ94.Connections[RnFNLp] = nil
				end
				SelectionBoxColor = i3NlQ94.State.PreviousSelectionBoxColor
				updateSelectionBoxColor()
			end
			Tools.Texture.Listeners.Button2Down = function()
				local cUoJ = Tools.Texture
				local m3QdLvW, xv, H = Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ()
				cUoJ.State.PreB2DownCameraRotation = Vector3.new(m3QdLvW, xv, H)
			end
			Tools.Texture.Listeners.Button2Up = function()
				local Gjvc = Tools.Texture
				local u3iW5, MGaxDz, ezQ = Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ()
				local c = Vector3.new(u3iW5, MGaxDz, ezQ)
				if Selection:find(Mouse.Target) and Gjvc.State.PreB2DownCameraRotation == c then
					Gjvc:changeSide(Mouse.TargetSurface)
				end
			end
			Tools.Texture.startHistoryRecord = function(FVJlfw, MwzzZ)
				if FVJlfw.State.HistoryRecord then
					FVJlfw.State.HistoryRecord = nil
				end
				FVJlfw.State.HistoryRecord = {
					targets = Support.CloneTable(MwzzZ),
					initial_texture = {},
					terminal_texture = {},
					initial_transparency = {},
					terminal_transparency = {},
					initial_repeat = {},
					terminal_repeat = {},
					initial_side = {},
					terminal_side = {},
					unapply = function(FVJlfw)
						Selection:clear()
						for EQI, zdm in pairs(FVJlfw.targets) do
							if zdm then
								Selection:add(zdm.Parent)
								zdm.Texture = FVJlfw.initial_texture[zdm]
								setp(zdm, "Transparency", FVJlfw.initial_transparency[zdm])
								setp(zdm, "Face", FVJlfw.initial_side[zdm])
								if zdm:IsA("Texture") then
									zdm.StudsPerTileU = FVJlfw.initial_repeat[zdm].x
									zdm.StudsPerTileV = FVJlfw.initial_repeat[zdm].y
								end
							end
						end
					end,
					apply = function(FVJlfw)
						Selection:clear()
						for OQaP, V1AAbF in pairs(FVJlfw.targets) do
							if V1AAbF then
								Selection:add(V1AAbF.Parent)
								V1AAbF.Texture = FVJlfw.terminal_texture[V1AAbF]
								setp(V1AAbF, "Transparency", FVJlfw.terminal_transparency[V1AAbF])
								setp(V1AAbF, "Face", FVJlfw.terminal_side[V1AAbF])
								if V1AAbF:IsA("Texture") then
									V1AAbF.StudsPerTileU = FVJlfw.terminal_repeat[V1AAbF].x
									V1AAbF.StudsPerTileV = FVJlfw.terminal_repeat[V1AAbF].y
								end
							end
						end
					end,
				}
				for DVp, uMHoys in pairs(FVJlfw.State.HistoryRecord.targets) do
					if uMHoys then
						FVJlfw.State.HistoryRecord.initial_texture[uMHoys] = uMHoys.Texture
						FVJlfw.State.HistoryRecord.initial_transparency[uMHoys] = uMHoys.Transparency
						FVJlfw.State.HistoryRecord.initial_side[uMHoys] = uMHoys.Face
						if uMHoys:IsA("Texture") then
							FVJlfw.State.HistoryRecord.initial_repeat[uMHoys] =
								Vector2.new(uMHoys.StudsPerTileU, uMHoys.StudsPerTileV)
						end
					end
				end
			end
			Tools.Texture.finishHistoryRecord = function(hebAWpv)
				if not hebAWpv.State.HistoryRecord then
					return
				end
				for iO, kQfTr6 in pairs(hebAWpv.State.HistoryRecord.targets) do
					if kQfTr6 then
						hebAWpv.State.HistoryRecord.terminal_texture[kQfTr6] = kQfTr6.Texture
						hebAWpv.State.HistoryRecord.terminal_transparency[kQfTr6] = kQfTr6.Transparency
						hebAWpv.State.HistoryRecord.terminal_side[kQfTr6] = kQfTr6.Face
						if kQfTr6:IsA("Texture") then
							hebAWpv.State.HistoryRecord.terminal_repeat[kQfTr6] =
								Vector2.new(kQfTr6.StudsPerTileU, kQfTr6.StudsPerTileV)
						end
					end
				end
				History:add(hebAWpv.State.HistoryRecord)
				hebAWpv.State.HistoryRecord = nil
			end
			Tools.Texture.changeMode = function(VF, qby)
				VF.Options.mode = qby
				if not VF.GUI then
					return
				end
				if qby == "decal" then
					setp(VF.GUI.ModeOption.Decal.SelectedIndicator, "Transparency", 0)
					setp(VF.GUI.ModeOption.Texture.SelectedIndicator, "Transparency", 1)
					setp(VF.GUI.ModeOption.Decal.Background, "Image", Assets.DarkSlantedRectangle)
					setp(VF.GUI.ModeOption.Texture.Background, "Image", Assets.LightSlantedRectangle)
					setp(VF.GUI.AddButton.Button, "Text", "ADD DECAL")
					setp(VF.GUI.RemoveButton.Button, "Text", "REMOVE DECAL")
				elseif qby == "texture" then
					setp(VF.GUI.ModeOption.Decal.SelectedIndicator, "Transparency", 1)
					setp(VF.GUI.ModeOption.Texture.SelectedIndicator, "Transparency", 0)
					setp(VF.GUI.ModeOption.Decal.Background, "Image", Assets.LightSlantedRectangle)
					setp(VF.GUI.ModeOption.Texture.Background, "Image", Assets.DarkSlantedRectangle)
					setp(VF.GUI.AddButton.Button, "Text", "ADD TEXTURE")
					setp(VF.GUI.RemoveButton.Button, "Text", "REMOVE TEXTURE")
				end
			end
			Tools.Texture.changeSide = function(xocXyH, guNNjlMM)
				xocXyH.Options.side = guNNjlMM
				if xocXyH.SideDropdown then
					xocXyH.SideDropdown:selectOption(fmtEnum(guNNjlMM))
					if xocXyH.SideDropdown.open then
						xocXyH.SideDropdown:toggle()
					end
				end
			end
			Tools.Texture.changeTexture = function(wvoHfla, UIgl)
				local ij = {}
				for m, TO857 in pairs(Selection.Items) do
					local Uo5o = Support.GetChildrenOfClass(TO857, "Texture")
					for m, xX9 in pairs(Uo5o) do
						if xX9.Face == wvoHfla.Options.side then
							table.insert(ij, xX9)
						end
					end
				end
				if HttpAvailable then
					local pOltGg = "http://www.f3xteam.com/bt/getDecalImageID/%s"
					local aD = HttpInterface.GetAsync(pOltGg:format(UIgl))
					if aD and aD:len() > 0 then
						UIgl = aD
					end
				end
				wvoHfla:startHistoryRecord(ij)
				for KO, Z in pairs(ij) do
					Z.Texture = "http://www.roblox.com/asset/?id=" .. UIgl
				end
				wvoHfla:finishHistoryRecord()
			end
			Tools.Texture.changeDecal = function(kv6Rc, G8PtJug)
				local RwGMa = {}
				for wODtgBt, R83 in pairs(Selection.Items) do
					local O3 = Support.GetChildrenOfClass(R83, "Decal")
					for wODtgBt, Y in pairs(O3) do
						if Y.Face == kv6Rc.Options.side then
							table.insert(RwGMa, Y)
						end
					end
				end
				if HttpAvailable then
					local Nau29CQd = "http://www.f3xteam.com/bt/getDecalImageID/%s"
					local rPWy4BIw = HttpInterface.GetAsync(Nau29CQd:format(G8PtJug))
					if rPWy4BIw and rPWy4BIw:len() > 0 then
						G8PtJug = rPWy4BIw
					end
				end
				kv6Rc:startHistoryRecord(RwGMa)
				for FIDceK, h in pairs(RwGMa) do
					h.Texture = "http://www.roblox.com/asset/?id=" .. G8PtJug
				end
				kv6Rc:finishHistoryRecord()
			end
			Tools.Texture.changeTransparency = function(lSW, kl)
				local W = {}
				for xtH, qujnE in pairs(Selection.Items) do
					if lSW.Options.mode == "texture" then
						local fX = Support.GetChildrenOfClass(qujnE, "Texture")
						for xtH, Gu9cA in pairs(fX) do
							if Gu9cA.Face == lSW.Options.side then
								table.insert(W, Gu9cA)
							end
						end
					elseif lSW.Options.mode == "decal" then
						local qie86E6k = Support.GetChildrenOfClass(qujnE, "Decal")
						for xtH, _7XdqeK in pairs(qie86E6k) do
							if _7XdqeK.Face == lSW.Options.side then
								table.insert(W, _7XdqeK)
							end
						end
					end
				end
				lSW:startHistoryRecord(W)
				for FUhqkm2, OmYbhPA in pairs(W) do
					setp(OmYbhPA, "Transparency", kl)
				end
				lSW:finishHistoryRecord()
			end
			Tools.Texture.changeFrequency = function(o1, cKy3Dt, y)
				local zB6zO = {}
				for C6, J09Np7H8 in pairs(Selection.Items) do
					local tf = Support.GetChildrenOfClass(J09Np7H8, "Texture")
					for C6, VzDXmgRS in pairs(tf) do
						if VzDXmgRS.Face == o1.Options.side then
							table.insert(zB6zO, VzDXmgRS)
						end
					end
				end
				o1:startHistoryRecord(zB6zO)
				for QHdb, dtRn in pairs(zB6zO) do
					if cKy3Dt == "x" then
						dtRn.StudsPerTileU = y
					elseif cKy3Dt == "y" then
						dtRn.StudsPerTileV = y
					end
				end
				o1:finishHistoryRecord()
			end
			Tools.Texture.addTexture = function(eHQcOZ4)
				local Sd6s = {
					apply = function(eHQcOZ4)
						Selection:clear()
						for KVcI5x, AHVxk8 in pairs(eHQcOZ4.textures) do
							setp(AHVxk8, "Parent", eHQcOZ4.texture_parents[AHVxk8])
							Selection:add(AHVxk8.Parent)
						end
					end,
					unapply = function(eHQcOZ4)
						Selection:clear()
						for ykIP, XQaA in pairs(eHQcOZ4.textures) do
							Selection:add(XQaA.Parent)
							setp(XQaA, "Parent", nil)
						end
					end,
				}
				local G4 = {}
				local A = {}
				for UFkKFj0, mj8vF in pairs(Selection.Items) do
					local N = Support.GetChildrenOfClass(mj8vF, "Texture")
					local XN_r = false
					for UFkKFj0, ihQKt in pairs(N) do
						if ihQKt.Face == eHQcOZ4.Options.side then
							XN_r = true
							break
						end
					end
					if not XN_r then
						local Nf = (RbxUtility.Create("Texture"))({
							Parent = mj8vF,
							Face = eHQcOZ4.Options.side,
						})
						table.insert(G4, Nf)
						A[Nf] = mj8vF
					end
				end
				Sd6s.textures = G4
				Sd6s.texture_parents = A
				History:add(Sd6s)
			end
			Tools.Texture.addDecal = function(v0xXBtzp)
				local Rh8dzZf_ = {
					apply = function(v0xXBtzp)
						Selection:clear()
						for DQKzz7t, I in pairs(v0xXBtzp.decals) do
							setp(I, "Parent", v0xXBtzp.decal_parents[I])
							Selection:add(I.Parent)
						end
					end,
					unapply = function(v0xXBtzp)
						Selection:clear()
						for jvpPcK, s in pairs(v0xXBtzp.decals) do
							Selection:add(s.Parent)
							setp(s, "Parent", nil)
						end
					end,
				}
				local k6z = {}
				local W = {}
				for Tx, izebj in pairs(Selection.Items) do
					local RioX = Support.GetChildrenOfClass(izebj, "Decal")
					local sgtu = false
					for Tx, i3XH in pairs(RioX) do
						if i3XH.Face == v0xXBtzp.Options.side then
							sgtu = true
							break
						end
					end
					if not sgtu then
						local USt6PLe2 = (RbxUtility.Create("Decal"))({
							Parent = izebj,
							Face = v0xXBtzp.Options.side,
						})
						table.insert(k6z, USt6PLe2)
						W[USt6PLe2] = izebj
					end
				end
				Rh8dzZf_.decals = k6z
				Rh8dzZf_.decal_parents = W
				History:add(Rh8dzZf_)
			end
			Tools.Texture.removeTexture = function(j)
				local EHi = {
					textures = {},
					texture_parents = {},
					apply = function(j)
						Selection:clear()
						for Du4PWm2, jEJClb in pairs(j.textures) do
							Selection:add(jEJClb.Parent)
							setp(jEJClb, "Parent", nil)
						end
					end,
					unapply = function(j)
						Selection:clear()
						for np8JkPc, Rfao in pairs(j.textures) do
							setp(Rfao, "Parent", j.texture_parents[Rfao])
							Selection:add(Rfao.Parent)
						end
					end,
				}
				for N6IWFa, Hr3mtiCq in pairs(Selection.Items) do
					local mf1UO = Support.GetChildrenOfClass(Hr3mtiCq, "Texture")
					for N6IWFa, wykbGA84 in pairs(mf1UO) do
						if wykbGA84.Face == j.Options.side then
							table.insert(EHi.textures, wykbGA84)
							EHi.texture_parents[wykbGA84] = wykbGA84.Parent
							setp(wykbGA84, "Parent", nil)
						end
					end
				end
				History:add(EHi)
			end
			Tools.Texture.removeDecal = function(Pd)
				local po2ff4F = {
					decals = {},
					decal_parents = {},
					apply = function(Pd)
						Selection:clear()
						for f, a in pairs(Pd.decals) do
							Selection:add(a.Parent)
							setp(a, "Parent", nil)
						end
					end,
					unapply = function(Pd)
						Selection:clear()
						for mBRe, Cb in pairs(Pd.decals) do
							setp(Cb, "Parent", Pd.decal_parents[Cb])
							Selection:add(Cb.Parent)
						end
					end,
				}
				for QP, k in pairs(Selection.Items) do
					local NTz6jdr = Support.GetChildrenOfClass(k, "Decal")
					for QP, cgIU3 in pairs(NTz6jdr) do
						if cgIU3.Face == Pd.Options.side then
							table.insert(po2ff4F.decals, cgIU3)
							po2ff4F.decal_parents[cgIU3] = cgIU3.Parent
							setp(cgIU3, "Parent", nil)
						end
					end
				end
				History:add(po2ff4F)
			end
			Tools.Texture.updateGUI = function(auV7A3JP)
				if not auV7A3JP.GUI then
					return
				end
				local FzJwZ = auV7A3JP.GUI
				if #Selection.Items == 0 then
					setp(auV7A3JP.GUI.AddButton, "Visible", false)
					setp(auV7A3JP.GUI.RemoveButton, "Visible", false)
					setp(auV7A3JP.GUI.ImageIDOption, "Visible", false)
					setp(auV7A3JP.GUI.TransparencyOption, "Visible", false)
					setp(auV7A3JP.GUI.RepeatOption, "Visible", false)
					setp(auV7A3JP.GUI, "Size", UDim2.new(0, 200, 0, 100))
				elseif auV7A3JP.Options.mode == "texture" then
					local Zb5 = {}
					for Ofe, TV4H8 in pairs(Selection.Items) do
						local HdS = Support.GetChildrenOfClass(TV4H8, "Texture")
						for Ofe, bvGUlnl8 in pairs(HdS) do
							if bvGUlnl8.Face == auV7A3JP.Options.side then
								table.insert(Zb5, bvGUlnl8)
								break
							end
						end
					end
					if #Zb5 == 0 then
						setp(auV7A3JP.GUI.AddButton, "Visible", true)
						setp(auV7A3JP.GUI.RemoveButton, "Visible", false)
						setp(auV7A3JP.GUI.ImageIDOption, "Visible", false)
						setp(auV7A3JP.GUI.TransparencyOption, "Visible", false)
						setp(auV7A3JP.GUI.RepeatOption, "Visible", false)
						setp(auV7A3JP.GUI, "Size", UDim2.new(0, 200, 0, 130))
					elseif #Zb5 ~= #Selection.Items then
						setp(auV7A3JP.GUI.AddButton, "Visible", true)
						setp(auV7A3JP.GUI.RemoveButton, "Visible", true)
						setp(auV7A3JP.GUI.ImageIDOption, "Visible", true)
						setp(auV7A3JP.GUI.TransparencyOption, "Visible", true)
						setp(auV7A3JP.GUI.RepeatOption, "Visible", true)
						setp(auV7A3JP.GUI.ImageIDOption, "Position", UDim2.new(0, 14, 0, 135))
						setp(auV7A3JP.GUI.TransparencyOption, "Position", UDim2.new(0, 14, 0, 170))
						setp(auV7A3JP.GUI.RepeatOption, "Position", UDim2.new(0, 0, 0, 205))
						setp(auV7A3JP.GUI, "Size", UDim2.new(0, 200, 0, 280))
					elseif #Zb5 == #Selection.Items then
						setp(auV7A3JP.GUI.AddButton, "Visible", false)
						setp(auV7A3JP.GUI.RemoveButton, "Visible", true)
						setp(auV7A3JP.GUI.ImageIDOption, "Visible", true)
						setp(auV7A3JP.GUI.TransparencyOption, "Visible", true)
						setp(auV7A3JP.GUI.RepeatOption, "Visible", true)
						setp(auV7A3JP.GUI.ImageIDOption, "Position", UDim2.new(0, 14, 0, 100))
						setp(auV7A3JP.GUI.TransparencyOption, "Position", UDim2.new(0, 14, 0, 135))
						setp(auV7A3JP.GUI.RepeatOption, "Position", UDim2.new(0, 0, 0, 170))
						setp(auV7A3JP.GUI, "Size", UDim2.new(0, 200, 0, 245))
					end
					local U, D1Bo4qP, CaGUl8h, zL
					for E2J9X, y in pairs(Zb5) do
						if E2J9X == 1 then
							U = y.Texture:lower()
							D1Bo4qP = y.Transparency
							CaGUl8h = y.StudsPerTileU
							zL = y.StudsPerTileV
						else
							if U ~= y.Texture:lower() then
								U = nil
							end
							if D1Bo4qP ~= y.Transparency then
								D1Bo4qP = nil
							end
							if CaGUl8h ~= y.StudsPerTileU then
								CaGUl8h = nil
							end
							if zL ~= y.StudsPerTileV then
								zL = nil
							end
						end
					end
					if not auV7A3JP.State.image_id_focused then
						setp(auV7A3JP.GUI.ImageIDOption.TextBox, "Text", U and (U:match("%?id=([0-9]+)") or "") or "*")
					end
					if not auV7A3JP.State.transparency_focused then
						auV7A3JP.GUI.TransparencyOption.TransparencyInput.TextBox.Text = D1Bo4qP
							and Support.Round(D1Bo4qP, 2)
							or "*"
					end
					if not auV7A3JP.State.rep_x_focused then
						setp(auV7A3JP.GUI.RepeatOption.XInput.TextBox, "Text", CaGUl8h and Support.Round(CaGUl8h, 2) or "*")
					end
					if not auV7A3JP.State.rep_y_focused then
						setp(auV7A3JP.GUI.RepeatOption.YInput.TextBox, "Text", zL and Support.Round(zL, 2) or "*")
					end
				elseif auV7A3JP.Options.mode == "decal" then
					local _Sbcpg = {}
					for WO, dcu in pairs(Selection.Items) do
						local HR = Support.GetChildrenOfClass(dcu, "Decal")
						for WO, P in pairs(HR) do
							if P.Face == auV7A3JP.Options.side then
								table.insert(_Sbcpg, P)
								break
							end
						end
					end
					if #_Sbcpg == 0 then
						setp(auV7A3JP.GUI.AddButton, "Visible", true)
						setp(auV7A3JP.GUI.RemoveButton, "Visible", false)
						setp(auV7A3JP.GUI.ImageIDOption, "Visible", false)
						setp(auV7A3JP.GUI.TransparencyOption, "Visible", false)
						setp(auV7A3JP.GUI.RepeatOption, "Visible", false)
						setp(auV7A3JP.GUI, "Size", UDim2.new(0, 200, 0, 130))
					elseif #_Sbcpg ~= #Selection.Items then
						setp(auV7A3JP.GUI.AddButton, "Visible", true)
						setp(auV7A3JP.GUI.RemoveButton, "Visible", true)
						setp(auV7A3JP.GUI.ImageIDOption, "Visible", true)
						setp(auV7A3JP.GUI.TransparencyOption, "Visible", true)
						setp(auV7A3JP.GUI.RepeatOption, "Visible", false)
						setp(auV7A3JP.GUI.ImageIDOption, "Position", UDim2.new(0, 14, 0, 135))
						setp(auV7A3JP.GUI.TransparencyOption, "Position", UDim2.new(0, 14, 0, 170))
						setp(auV7A3JP.GUI, "Size", UDim2.new(0, 200, 0, 245))
					elseif #_Sbcpg == #Selection.Items then
						setp(auV7A3JP.GUI.AddButton, "Visible", false)
						setp(auV7A3JP.GUI.RemoveButton, "Visible", true)
						setp(auV7A3JP.GUI.ImageIDOption, "Visible", true)
						setp(auV7A3JP.GUI.TransparencyOption, "Visible", true)
						setp(auV7A3JP.GUI.RepeatOption, "Visible", false)
						setp(auV7A3JP.GUI.ImageIDOption, "Position", UDim2.new(0, 14, 0, 100))
						setp(auV7A3JP.GUI.TransparencyOption, "Position", UDim2.new(0, 14, 0, 135))
						setp(auV7A3JP.GUI, "Size", UDim2.new(0, 200, 0, 205))
					end
					local y99_, f7ZTY
					for y1jZqCcc, ARVZ in pairs(_Sbcpg) do
						if y1jZqCcc == 1 then
							y99_ = ARVZ.Texture:lower()
							f7ZTY = ARVZ.Transparency
						else
							if y99_ ~= ARVZ.Texture:lower() then
								y99_ = nil
							end
							if f7ZTY ~= ARVZ.Transparency then
								f7ZTY = nil
							end
						end
					end
					if not auV7A3JP.State.image_id_focused then
						setp(auV7A3JP.GUI.ImageIDOption.TextBox, "Text", y99_ and (y99_:match("%?id=([0-9]+)") or "") or "*")
					end
					if not auV7A3JP.State.transparency_focused then
						auV7A3JP.GUI.TransparencyOption.TransparencyInput.TextBox.Text = f7ZTY
							and Support.Round(f7ZTY, 2)
							or "*"
					end
				end
			end
			Tools.Texture.showGUI = function(ulU)
				if not ulU.GUI then
					local mkpyU5eh = DFb100j.BTTextureToolGUI:Clone()
					setp(mkpyU5eh, "Parent", UI)
					mkpyU5eh.AddButton.Button.MouseButton1Up:Connect(function()
						if ulU.Options.mode == "decal" then
							ulU:addDecal()
						elseif ulU.Options.mode == "texture" then
							ulU:addTexture()
						end
					end)
					mkpyU5eh.RemoveButton.Button.MouseButton1Up:Connect(function()
						if ulU.Options.mode == "decal" then
							ulU:removeDecal()
						elseif ulU.Options.mode == "texture" then
							ulU:removeTexture()
						end
					end)
					mkpyU5eh.ModeOption.Decal.Button.MouseButton1Down:Connect(function()
						ulU:changeMode("decal")
					end)
					mkpyU5eh.ModeOption.Texture.Button.MouseButton1Down:Connect(function()
						ulU:changeMode("texture")
					end)
					local U9 = createDropdown()
					ulU.SideDropdown = U9
					setp(U9.Frame, "Parent", mkpyU5eh.SideOption)
					setp(U9.Frame, "Position", UDim2.new(0, 35, 0, 0))
					setp(U9.Frame, "Size", UDim2.new(1, -50, 0, 25));
					addEnum(U9, Enum.NormalId, function(x)
						ulU:changeSide(x)
					end)
					mkpyU5eh.RepeatOption.XInput.TextButton.MouseButton1Down:Connect(function()
						ulU.State.rep_x_focused = true
						mkpyU5eh.RepeatOption.XInput.TextBox:CaptureFocus()
					end)
					mkpyU5eh.RepeatOption.XInput.TextBox.FocusLost:Connect(function(pzpDOr)
						local yoo = tonumber(mkpyU5eh.RepeatOption.XInput.TextBox.Text)
						if yoo then
							ulU:changeFrequency("x", yoo)
						end
						ulU.State.rep_x_focused = false
					end)
					mkpyU5eh.RepeatOption.YInput.TextButton.MouseButton1Down:Connect(function()
						ulU.State.rep_y_focused = true
						mkpyU5eh.RepeatOption.YInput.TextBox:CaptureFocus()
					end)
					mkpyU5eh.RepeatOption.YInput.TextBox.FocusLost:Connect(function(MXzW)
						local Uvqu6c5 = tonumber(mkpyU5eh.RepeatOption.YInput.TextBox.Text)
						if Uvqu6c5 then
							ulU:changeFrequency("y", Uvqu6c5)
						end
						ulU.State.rep_y_focused = false
					end)
					mkpyU5eh.ImageIDOption.TextButton.MouseButton1Down:Connect(function()
						ulU.State.image_id_focused = true
						mkpyU5eh.ImageIDOption.TextBox:CaptureFocus()
					end)
					mkpyU5eh.ImageIDOption.TextBox.FocusLost:Connect(function(MMXv)
						local R = mkpyU5eh.ImageIDOption.TextBox.Text
						local u = tonumber(R) or (R:lower()):match("%?id=([0-9]+)")
						if u then
							if ulU.Options.mode == "decal" then
								ulU:changeDecal(u)
							elseif ulU.Options.mode == "texture" then
								ulU:changeTexture(u)
							end
						end
						ulU.State.image_id_focused = false
					end)
					mkpyU5eh.TransparencyOption.TransparencyInput.TextButton.MouseButton1Down:Connect(function()
						ulU.State.transparency_focused = true
						mkpyU5eh.TransparencyOption.TransparencyInput.TextBox:CaptureFocus()
					end)
					mkpyU5eh.TransparencyOption.TransparencyInput.TextBox.FocusLost:Connect(function(ipLsp)
						local cpC = tonumber(mkpyU5eh.TransparencyOption.TransparencyInput.TextBox.Text)
						if cpC then
							if cpC > 1 then
								cpC = 1
							elseif cpC < 0 then
								cpC = 0
							end
							ulU:changeTransparency(cpC)
						end
						ulU.State.transparency_focused = false
					end)
					ulU.GUI = mkpyU5eh
				end
				setp(ulU.GUI, "Visible", true)
			end
			Tools.Texture.hideGUI = function(k73bTK)
				if k73bTK.GUI then
					setp(k73bTK.GUI, "Visible", false)
				end
			end
			Tools.Texture.Loaded = true
		end,
	},
	{
		"Weld",
		function()
			repeat
				task.wait()
			until _G.BTCoreEnv and _G.BTCoreEnv.tool and _G.BTCoreEnv.tool.CoreReady
			setfenv(1, _G.BTCoreEnv.tool)
			Tools.Weld = {}
			setp(Tools.Weld, "Color", BrickColor.new("Really black"))
			Tools.Weld.State = {}
			Tools.Weld.Connections = {}
			Tools.Weld.Listeners = {}
			Tools.Weld.Listeners.Equipped = function()
				local cqVt = Tools.Weld
				cqVt.State.PreviousSelectionBoxColor = SelectionBoxColor
				SelectionBoxColor = cqVt.Color
				updateSelectionBoxColor()
				cqVt:showGUI()
				if Selection.Last and SelectionBoxes[Selection.Last] then
					SelectionBoxes[Selection.Last].Color = BrickColor.new("Pastel Blue")
				end
				cqVt.Connections.LastPartHighlighter = Selection.Changed:Connect(function()
					updateSelectionBoxColor()
					if Selection.Last and SelectionBoxes[Selection.Last] then
						SelectionBoxes[Selection.Last].Color = BrickColor.new("Pastel Blue")
					end
				end)
			end
			Tools.Weld.Listeners.Unequipped = function()
				local ywq = Tools.Weld
				ywq:hideGUI()
				for lMF, WVA in pairs(ywq.Connections) do
					WVA:Disconnect()
					ywq.Connections[lMF] = nil
				end
				SelectionBoxColor = ywq.State.PreviousSelectionBoxColor
				updateSelectionBoxColor()
			end
			Tools.Weld.Listeners.Button2Down = function()
				local iWh = Tools.Weld
				local XG, Ts, K8jL8qZ = Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ()
				iWh.State.PreB2DownCameraRotation = Vector3.new(XG, Ts, K8jL8qZ)
			end
			Tools.Weld.Listeners.Button2Up = function()
				local wucZH2qz = Tools.Weld
				local Ox0yyMI3, hvw, ZFhe = Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ()
				local Kgpa = Vector3.new(Ox0yyMI3, hvw, ZFhe)
				if Selection:find(Mouse.Target) and wucZH2qz.State.PreB2DownCameraRotation == Kgpa then
					Selection:focus(Mouse.Target)
				end
			end
			Tools.Weld.weld = function(TEz)
				local AJJ1kZS = {
					weld_parents = {},
					unapply = function(TEz)
						Selection:clear()
						for Bd, e in pairs(TEz.welds) do
							Selection:add(e.Part0)
							Selection:add(e.Part1)
							setp(e, "Parent", nil)
						end
					end,
					apply = function(TEz)
						Selection:clear()
						for tsGRH, U in pairs(TEz.welds) do
							setp(U, "Parent", TEz.weld_parents[U])
							Selection:add(U.Part0)
							Selection:add(U.Part1)
						end
					end,
				}
				local B = {}
				if #Selection.Items > 1 and Selection.Last then
					for m, U84H37 in pairs(Selection.Items) do
						if U84H37 ~= Selection.Last then
							local C = (RbxUtility.Create("Weld"))({
								Name = "BTWeld",
								Parent = Selection.Last,
								Part0 = Selection.Last,
								Part1 = U84H37,
								Archivable = false,
								C1 = U84H37.CFrame:toObjectSpace(Selection.Last.CFrame),
							})
							table.insert(B, C)
							AJJ1kZS.weld_parents[C] = C.Parent
						end
					end
				end
				AJJ1kZS.welds = B
				History:add(AJJ1kZS)
				setp(TEz.GUI.Changes.Text, "Text", "created " .. #B .. " weld" .. (#B ~= 1 and "s" or ""))
				local vZdI = (RbxUtility.Create("Sound"))({
					Name = "BTActionCompletionSound",
					Pitch = 1.5,
					SoundId = Assets.ActionCompletionSound,
					Volume = 1,
					Parent = Player,
				})
				vZdI:Play()
				vZdI:Destroy()
			end
			Tools.Weld.breakWelds = function(f4fN)
				local ODzAx = {
					weld_parents = {},
					apply = function(f4fN)
						Selection:clear()
						for SC, bWuOG in pairs(f4fN.welds) do
							Selection:add(bWuOG.Part0)
							Selection:add(bWuOG.Part1)
							setp(bWuOG, "Parent", nil)
						end
					end,
					unapply = function(f4fN)
						Selection:clear()
						for jGg, x in pairs(f4fN.welds) do
							Selection:add(x.Part1)
							Selection:add(x.Part0)
							setp(x, "Parent", f4fN.weld_parents[x])
						end
					end,
				}
				local IsAkf = {}
				local Pwzq_Fj = Support.GetAllDescendants(Game.Workspace)
				for vqs1_7, vLdk in pairs(Pwzq_Fj) do
					if vLdk:IsA("Weld") and vLdk.Name == "BTWeld" then
						for vqs1_7, cU6JgXi in pairs(Selection.Items) do
							if vLdk.Part0 == cU6JgXi or vLdk.Part1 == cU6JgXi then
								if not ODzAx.weld_parents[vLdk] then
									table.insert(IsAkf, vLdk)
									ODzAx.weld_parents[vLdk] = vLdk.Parent
									setp(vLdk, "Parent", nil)
								end
							end
						end
					end
				end
				ODzAx.welds = IsAkf
				History:add(ODzAx)
				setp(f4fN.GUI.Changes.Text, "Text", "broke " .. #IsAkf .. " weld" .. (#IsAkf ~= 1 and "s" or ""))
				local GKDMp = (RbxUtility.Create("Sound"))({
					Name = "BTActionCompletionSound",
					Pitch = 1.5,
					SoundId = Assets.ActionCompletionSound,
					Volume = 1,
					Parent = Player,
				})
				GKDMp:Play()
				GKDMp:Destroy()
			end
			Tools.Weld.showGUI = function(tEiL)
				if not tEiL.GUI then
					local nWMi = DFb100j.BTWeldToolGUI:Clone()
					setp(nWMi, "Parent", UI)
					nWMi.Interface.WeldButton.MouseButton1Up:Connect(function()
						tEiL:weld()
					end)
					nWMi.Interface.BreakWeldsButton.MouseButton1Up:Connect(function()
						tEiL:breakWelds()
					end)
					tEiL.GUI = nWMi
				end
				setp(tEiL.GUI, "Visible", true)
			end
			Tools.Weld.hideGUI = function(gl9xJb)
				if gl9xJb.GUI then
					setp(gl9xJb.GUI, "Visible", false)
				end
			end
			Tools.Weld.Loaded = true
		end,
	},
	{
		"Lighting",
		function()
			repeat
				task.wait()
			until _G.BTCoreEnv and _G.BTCoreEnv.tool and _G.BTCoreEnv.tool.CoreReady
			setfenv(1, _G.BTCoreEnv.tool)
			Tools.Lighting = {}
			setp(Tools.Lighting, "Color", BrickColor.new("Really black"))
			Tools.Lighting.State = {}
			Tools.Lighting.Connections = {}
			Tools.Lighting.Listeners = {}
			Tools.Lighting.Listeners.Equipped = function()
				local oHk5pUB = Tools.Lighting
				oHk5pUB.State.PreviousSelectionBoxColor = SelectionBoxColor
				SelectionBoxColor = oHk5pUB.Color
				updateSelectionBoxColor()
				oHk5pUB:showGUI();
				(coroutine.wrap(function()
					updater_on = true
					oHk5pUB.Updater = function()
						updater_on = false
					end
					while task.wait(0.1) and updater_on do
						if CurrentTool == oHk5pUB then
							if oHk5pUB.GUI and oHk5pUB.GUI.Visible then
								oHk5pUB:updateGUI()
							end
						end
					end
				end))()
			end
			Tools.Lighting.Listeners.Unequipped = function()
				local Ltm = Tools.Lighting
				if Ltm.Updater then
					Ltm.Updater()
					Ltm.Updater = nil
				end
				Ltm:hideGUI()
				for yW9GRj, QGXSL6 in pairs(Ltm.Connections) do
					QGXSL6:Disconnect()
					Ltm.Connections[yW9GRj] = nil
				end
				SelectionBoxColor = Ltm.State.PreviousSelectionBoxColor
				updateSelectionBoxColor()
			end
			Tools.Lighting.Listeners.Button2Down = function()
				local M = Tools.Lighting
				local _X, eir, e = Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ()
				M.State.PreB2DownCameraRotation = Vector3.new(_X, eir, e)
			end
			Tools.Lighting.Listeners.Button2Up = function()
				local XKqiVa3 = Tools.Lighting
				local v4mltq, AIOtQ8e_, d = Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ()
				local l7 = Vector3.new(v4mltq, AIOtQ8e_, d)
				if Selection:find(Mouse.Target) and XKqiVa3.State.PreB2DownCameraRotation == l7 then
					XKqiVa3:changeSide(Mouse.TargetSurface)
				end
			end
			Tools.Lighting.updateGUI = function(vtjp)
				if not vtjp.GUI then
					return
				end
				if #Selection.Items > 0 then
					local qLEp2 = vtjp:getSpotlights()
					local XbIEI_3k = vtjp:getPointLights()
					local Ysuv, v, my19G, oO, zqYNA, XMzOvb, l8zYu, x17pq6s
					local Cxc, G, dZty4, d, NQQjm0G, qeyvW
					for fuJ, vBt in pairs(qLEp2) do
						if fuJ == 1 then
							Ysuv, v, my19G = vBt.Color.r, vBt.Color.g, vBt.Color.b
							oO = vBt.Brightness
							zqYNA = vBt.Range
							XMzOvb = vBt.Shadows
							l8zYu = vBt.Angle
							x17pq6s = vBt.Face
						else
							if Ysuv ~= vBt.Color.r then
								Ysuv = nil
							end
							if v ~= vBt.Color.g then
								v = nil
							end
							if my19G ~= vBt.Color.b then
								my19G = nil
							end
							if oO ~= vBt.Brightness then
								oO = nil
							end
							if zqYNA ~= vBt.Range then
								zqYNA = nil
							end
							if XMzOvb ~= vBt.Shadows then
								XMzOvb = nil
							end
							if l8zYu ~= vBt.Angle then
								l8zYu = nil
							end
							if x17pq6s ~= vBt.Face then
								x17pq6s = nil
							end
						end
					end
					for j6f, DhLDRM in pairs(XbIEI_3k) do
						if j6f == 1 then
							Cxc, G, dZty4 = DhLDRM.Color.r, DhLDRM.Color.g, DhLDRM.Color.b
							d = DhLDRM.Brightness
							NQQjm0G = DhLDRM.Range
							qeyvW = DhLDRM.Shadows
						else
							if Cxc ~= DhLDRM.Color.r then
								Cxc = nil
							end
							if G ~= DhLDRM.Color.g then
								G = nil
							end
							if dZty4 ~= DhLDRM.Color.b then
								dZty4 = nil
							end
							if d ~= DhLDRM.Brightness then
								d = nil
							end
							if NQQjm0G ~= DhLDRM.Range then
								NQQjm0G = nil
							end
							if qeyvW ~= DhLDRM.Shadows then
								qeyvW = nil
							end
						end
					end
					vtjp.State.sl_color = Ysuv and v and my19G and Color3.new(Ysuv, v, my19G) or nil
					vtjp.State.pl_color = Cxc and G and dZty4 and Color3.new(Cxc, G, dZty4) or nil
					if not vtjp.State.sl_color_r_focused then
						vtjp.GUI.Spotlight.Options.ColorOption.RInput.TextBox.Text = Ysuv
							and Support.Round(Ysuv * 255, 0)
							or "*"
					end
					if not vtjp.State.sl_color_g_focused then
						vtjp.GUI.Spotlight.Options.ColorOption.GInput.TextBox.Text = v and Support.Round(v * 255, 0)
							or "*"
					end
					if not vtjp.State.sl_color_b_focused then
						vtjp.GUI.Spotlight.Options.ColorOption.BInput.TextBox.Text = my19G
							and Support.Round(my19G * 255, 0)
							or "*"
					end
					if not vtjp.State.sl_brightness_focused then
						vtjp.GUI.Spotlight.Options.BrightnessOption.Input.TextBox.Text = oO and Support.Round(oO, 2)
							or "*"
					end
					if not vtjp.State.sl_range_focused then
						vtjp.GUI.Spotlight.Options.RangeOption.Input.TextBox.Text = zqYNA and Support.Round(zqYNA, 2)
							or "*"
					end
					if XMzOvb == nil then
						setp(vtjp.GUI.Spotlight.Options.ShadowsOption.On.Background, "Image", Assets.LightSlantedRectangle)
						setp(vtjp.GUI.Spotlight.Options.ShadowsOption.On.SelectedIndicator, "BackgroundTransparency", 1)
						setp(vtjp.GUI.Spotlight.Options.ShadowsOption.Off.Background, "Image", Assets.LightSlantedRectangle)
						setp(vtjp.GUI.Spotlight.Options.ShadowsOption.Off.SelectedIndicator, "BackgroundTransparency", 1)
					elseif XMzOvb == true then
						setp(vtjp.GUI.Spotlight.Options.ShadowsOption.On.Background, "Image", Assets.DarkSlantedRectangle)
						setp(vtjp.GUI.Spotlight.Options.ShadowsOption.On.SelectedIndicator, "BackgroundTransparency", 0)
						setp(vtjp.GUI.Spotlight.Options.ShadowsOption.Off.Background, "Image", Assets.LightSlantedRectangle)
						setp(vtjp.GUI.Spotlight.Options.ShadowsOption.Off.SelectedIndicator, "BackgroundTransparency", 1)
					elseif XMzOvb == false then
						setp(vtjp.GUI.Spotlight.Options.ShadowsOption.On.Background, "Image", Assets.LightSlantedRectangle)
						setp(vtjp.GUI.Spotlight.Options.ShadowsOption.On.SelectedIndicator, "BackgroundTransparency", 1)
						setp(vtjp.GUI.Spotlight.Options.ShadowsOption.Off.Background, "Image", Assets.DarkSlantedRectangle)
						setp(vtjp.GUI.Spotlight.Options.ShadowsOption.Off.SelectedIndicator, "BackgroundTransparency", 0)
					end
					if not vtjp.State.sl_angle_focused then
						vtjp.GUI.Spotlight.Options.AngleOption.Input.TextBox.Text = l8zYu and Support.Round(l8zYu, 2)
							or "*"
					end
					vtjp.SideDropdown:selectOption(x17pq6s and fmtEnum(x17pq6s) or "*")
					if not vtjp.State.pl_color_r_focused then
						vtjp.GUI.PointLight.Options.ColorOption.RInput.TextBox.Text = Cxc
							and Support.Round(Cxc * 255, 0)
							or "*"
					end
					if not vtjp.State.pl_color_g_focused then
						vtjp.GUI.PointLight.Options.ColorOption.GInput.TextBox.Text = G and Support.Round(G * 255, 0)
							or "*"
					end
					if not vtjp.State.pl_color_b_focused then
						vtjp.GUI.PointLight.Options.ColorOption.BInput.TextBox.Text = dZty4
							and Support.Round(dZty4 * 255, 0)
							or "*"
					end
					if not vtjp.State.pl_brightness_focused then
						vtjp.GUI.PointLight.Options.BrightnessOption.Input.TextBox.Text = d and Support.Round(d, 2)
							or "*"
					end
					if not vtjp.State.pl_range_focused then
						vtjp.GUI.PointLight.Options.RangeOption.Input.TextBox.Text = NQQjm0G
							and Support.Round(NQQjm0G, 2)
							or "*"
					end
					if qeyvW == nil then
						setp(vtjp.GUI.PointLight.Options.ShadowsOption.On.Background, "Image", Assets.LightSlantedRectangle)
						setp(vtjp.GUI.PointLight.Options.ShadowsOption.On.SelectedIndicator, "BackgroundTransparency", 1)
						setp(vtjp.GUI.PointLight.Options.ShadowsOption.Off.Background, "Image", Assets.LightSlantedRectangle)
						setp(vtjp.GUI.PointLight.Options.ShadowsOption.Off.SelectedIndicator, "BackgroundTransparency", 1)
					elseif qeyvW == true then
						setp(vtjp.GUI.PointLight.Options.ShadowsOption.On.Background, "Image", Assets.DarkSlantedRectangle)
						setp(vtjp.GUI.PointLight.Options.ShadowsOption.On.SelectedIndicator, "BackgroundTransparency", 0)
						setp(vtjp.GUI.PointLight.Options.ShadowsOption.Off.Background, "Image", Assets.LightSlantedRectangle)
						setp(vtjp.GUI.PointLight.Options.ShadowsOption.Off.SelectedIndicator, "BackgroundTransparency", 1)
					elseif qeyvW == false then
						setp(vtjp.GUI.PointLight.Options.ShadowsOption.On.Background, "Image", Assets.LightSlantedRectangle)
						setp(vtjp.GUI.PointLight.Options.ShadowsOption.On.SelectedIndicator, "BackgroundTransparency", 1)
						setp(vtjp.GUI.PointLight.Options.ShadowsOption.Off.Background, "Image", Assets.DarkSlantedRectangle)
						setp(vtjp.GUI.PointLight.Options.ShadowsOption.Off.SelectedIndicator, "BackgroundTransparency", 0)
					end
					if vtjp.GUI.SelectNote.Visible then
						vtjp:closePointLight()
						vtjp:closeSpotlight()
					end
					setp(vtjp.GUI.Spotlight, "Visible", true)
					setp(vtjp.GUI.PointLight, "Visible", true)
					setp(vtjp.GUI.SelectNote, "Visible", false)
					if not vtjp.State.spotlight_open and not vtjp.State.pointlight_open then
						vtjp.GUI:TweenSize(
							UDim2.new(0, 200, 0, 95),
							Enum.EasingDirection.Out,
							Enum.EasingStyle.Quad,
							0.5,
							true
						)
					end
					if #qLEp2 == 0 then
						setp(vtjp.GUI.Spotlight.Options, "Size", UDim2.new(1, -3, 0, 0))
						setp(vtjp.GUI.Spotlight.AddButton, "Visible", true)
						setp(vtjp.GUI.Spotlight.RemoveButton, "Visible", false)
						if vtjp.State.spotlight_open then
							vtjp:closeSpotlight()
						end
					elseif #qLEp2 ~= #Selection.Items then
						setp(vtjp.GUI.Spotlight.AddButton, "Visible", true)
						setp(vtjp.GUI.Spotlight.RemoveButton, "Position", UDim2.new(0, 90, 0, 3))
						setp(vtjp.GUI.Spotlight.RemoveButton, "Visible", true)
					elseif #qLEp2 == #Selection.Items then
						setp(vtjp.GUI.Spotlight.AddButton, "Visible", false)
						setp(vtjp.GUI.Spotlight.RemoveButton, "Position", UDim2.new(0, 127, 0, 3))
						setp(vtjp.GUI.Spotlight.RemoveButton, "Visible", true)
						if vtjp.GUI.Spotlight.Size == UDim2.new(0, 200, 0, 52) then
							setp(vtjp.GUI.Spotlight, "Size", UDim2.new(0, 200, 0, 95))
						end
					end
					if #XbIEI_3k == 0 then
						setp(vtjp.GUI.PointLight.Options, "Size", UDim2.new(1, -3, 0, 0))
						setp(vtjp.GUI.PointLight.AddButton, "Visible", true)
						setp(vtjp.GUI.PointLight.RemoveButton, "Visible", false)
						if vtjp.State.pointlight_open then
							vtjp:closePointLight()
						end
					elseif #XbIEI_3k ~= #Selection.Items then
						setp(vtjp.GUI.PointLight.AddButton, "Visible", true)
						setp(vtjp.GUI.PointLight.RemoveButton, "Position", UDim2.new(0, 90, 0, 3))
						setp(vtjp.GUI.PointLight.RemoveButton, "Visible", true)
					elseif #XbIEI_3k == #Selection.Items then
						setp(vtjp.GUI.PointLight.AddButton, "Visible", false)
						setp(vtjp.GUI.PointLight.RemoveButton, "Position", UDim2.new(0, 127, 0, 3))
						setp(vtjp.GUI.PointLight.RemoveButton, "Visible", true)
					end
				else
					setp(vtjp.GUI.Spotlight, "Visible", false)
					setp(vtjp.GUI.PointLight, "Visible", false)
					setp(vtjp.GUI.SelectNote, "Visible", true)
					setp(vtjp.GUI, "Size", UDim2.new(0, 200, 0, 52))
				end
			end
			Tools.Lighting.openSpotlight = function(LgVwYh6)
				LgVwYh6.State.spotlight_open = true
				LgVwYh6:closePointLight()
				LgVwYh6.GUI.Spotlight.Options:TweenSize(
					UDim2.new(1, -3, 0, 300),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				LgVwYh6.GUI.Spotlight:TweenPosition(
					UDim2.new(0, 10, 0, 30),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				LgVwYh6.GUI:TweenSize(
					UDim2.new(0, 200, 0, 275),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
			end
			Tools.Lighting.openPointLight = function(tSBo)
				tSBo.State.pointlight_open = true
				tSBo:closeSpotlight()
				tSBo.GUI.PointLight.Options:TweenSize(
					UDim2.new(1, -3, 0, 110),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				tSBo.GUI.PointLight:TweenPosition(
					UDim2.new(0, 10, 0, 60),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				tSBo.GUI:TweenSize(
					UDim2.new(0, 200, 0, 200),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
			end
			Tools.Lighting.closeSpotlight = function(FuIUnM)
				FuIUnM.State.spotlight_open = false
				FuIUnM.GUI.Spotlight.Options:TweenSize(
					UDim2.new(1, -3, 0, 0),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				FuIUnM.GUI.PointLight:TweenPosition(
					UDim2.new(0, 10, 0, 60),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				if not FuIUnM.State.pointlight_open then
					FuIUnM.GUI:TweenSize(
						UDim2.new(0, 200, 0, 95),
						Enum.EasingDirection.Out,
						Enum.EasingStyle.Quad,
						0.5,
						true
					)
				end
			end
			Tools.Lighting.closePointLight = function(WtoMT)
				WtoMT.State.pointlight_open = false
				WtoMT.GUI.PointLight:TweenPosition(
					UDim2.new(0, 10, 0, WtoMT.State.spotlight_open and 240 or 60),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				WtoMT.GUI.PointLight.Options:TweenSize(
					UDim2.new(1, -3, 0, 0),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				if not WtoMT.State.spotlight_open then
					WtoMT.GUI:TweenSize(
						UDim2.new(0, 200, 0, 95),
						Enum.EasingDirection.Out,
						Enum.EasingStyle.Quad,
						0.5,
						true
					)
				end
			end
			Tools.Lighting.showGUI = function(gTa7jfw)
				if not gTa7jfw.GUI then
					local d6RaDSY = DFb100j.BTLightingToolGUI:Clone()
					setp(d6RaDSY, "Parent", UI)
					d6RaDSY.Spotlight.ArrowButton.MouseButton1Up:Connect(function()
						if not gTa7jfw.State.spotlight_open and #gTa7jfw:getSpotlights() > 0 then
							gTa7jfw:openSpotlight()
						else
							gTa7jfw:closeSpotlight()
						end
					end)
					d6RaDSY.PointLight.ArrowButton.MouseButton1Up:Connect(function()
						if not gTa7jfw.State.pointlight_open and #gTa7jfw:getPointLights() > 0 then
							gTa7jfw:openPointLight()
						else
							gTa7jfw:closePointLight()
						end
					end)
					d6RaDSY.Spotlight.AddButton.MouseButton1Up:Connect(function()
						gTa7jfw:addLight("SpotLight")
						gTa7jfw:openSpotlight()
					end)
					d6RaDSY.PointLight.AddButton.MouseButton1Up:Connect(function()
						gTa7jfw:addLight("PointLight")
						gTa7jfw:openPointLight()
					end)
					d6RaDSY.Spotlight.RemoveButton.MouseButton1Up:Connect(function()
						gTa7jfw:removeLight("spotlight")
						gTa7jfw:closeSpotlight()
					end)
					d6RaDSY.PointLight.RemoveButton.MouseButton1Up:Connect(function()
						gTa7jfw:removeLight("pointlight")
						gTa7jfw:closePointLight()
					end)
					local hJEr = createDropdown()
					gTa7jfw.SideDropdown = hJEr
					setp(hJEr.Frame, "Parent", d6RaDSY.Spotlight.Options.SideOption)
					setp(hJEr.Frame, "Position", UDim2.new(0, 35, 0, 0))
					setp(hJEr.Frame, "Size", UDim2.new(0, 90, 0, 25));
					addEnum(hJEr, Enum.NormalId, function(x)
						gTa7jfw:changeSide(x)
					end)
					local deq_fwZ = d6RaDSY.Spotlight
					local d4iuG = deq_fwZ.Options.ColorOption
					d4iuG.RInput.TextButton.MouseButton1Down:Connect(function()
						gTa7jfw.State.sl_color_r_focused = true
						d4iuG.RInput.TextBox:CaptureFocus()
					end)
					d4iuG.RInput.TextBox.FocusLost:Connect(function(Lc4UCGl)
						local lEoJniu = tonumber(d4iuG.RInput.TextBox.Text)
						if lEoJniu then
							if lEoJniu > 255 then
								lEoJniu = 255
							elseif lEoJniu < 0 then
								lEoJniu = 0
							end
							gTa7jfw:changeColor("spotlight", "r", lEoJniu / 255)
						end
						gTa7jfw.State.sl_color_r_focused = false
					end)
					d4iuG.GInput.TextButton.MouseButton1Down:Connect(function()
						gTa7jfw.State.sl_color_g_focused = true
						d4iuG.GInput.TextBox:CaptureFocus()
					end)
					d4iuG.GInput.TextBox.FocusLost:Connect(function(sMV)
						local HLkyy = tonumber(d4iuG.GInput.TextBox.Text)
						if HLkyy then
							if HLkyy > 255 then
								HLkyy = 255
							elseif HLkyy < 0 then
								HLkyy = 0
							end
							gTa7jfw:changeColor("spotlight", "g", HLkyy / 255)
						end
						gTa7jfw.State.sl_color_g_focused = false
					end)
					d4iuG.BInput.TextButton.MouseButton1Down:Connect(function()
						gTa7jfw.State.sl_color_b_focused = true
						d4iuG.BInput.TextBox:CaptureFocus()
					end)
					d4iuG.BInput.TextBox.FocusLost:Connect(function(ttFi_l_)
						local dSeSQ5 = tonumber(d4iuG.BInput.TextBox.Text)
						if dSeSQ5 then
							if dSeSQ5 > 255 then
								dSeSQ5 = 255
							elseif dSeSQ5 < 0 then
								dSeSQ5 = 0
							end
							gTa7jfw:changeColor("spotlight", "b", dSeSQ5 / 255)
						end
						gTa7jfw.State.sl_color_b_focused = false
					end)
					d4iuG.HSVPicker.MouseButton1Up:Connect(function()
						ColorPicker:start(function(...)
							local CHYkRQW6 = {
								...,
							}
							if #CHYkRQW6 == 3 then
								gTa7jfw:changeColor("spotlight", Support.HSVToRGB(...))
							end
						end, gTa7jfw.State.sl_color)
					end)
					local tn2 = deq_fwZ.Options.BrightnessOption.Input
					tn2.TextButton.MouseButton1Down:Connect(function()
						gTa7jfw.State.sl_brightness_focused = true
						tn2.TextBox:CaptureFocus()
					end)
					tn2.TextBox.FocusLost:Connect(function(cZtDtN7N)
						local Z7UyFJN = tonumber(tn2.TextBox.Text)
						if Z7UyFJN then
							if Z7UyFJN > 5 then
								Z7UyFJN = 5
							elseif Z7UyFJN < 0 then
								Z7UyFJN = 0
							end
							gTa7jfw:changeBrightness("spotlight", Z7UyFJN)
						end
						gTa7jfw.State.sl_brightness_focused = false
					end)
					local iFXPT_P = deq_fwZ.Options.AngleOption.Input
					iFXPT_P.TextButton.MouseButton1Down:Connect(function()
						gTa7jfw.State.sl_angle_focused = true
						iFXPT_P.TextBox:CaptureFocus()
					end)
					iFXPT_P.TextBox.FocusLost:Connect(function(DYBqYM)
						local s1 = tonumber(iFXPT_P.TextBox.Text)
						if s1 then
							gTa7jfw:changeAngle(s1)
						end
						gTa7jfw.State.sl_angle_focused = false
					end)
					local KY = deq_fwZ.Options.RangeOption.Input
					KY.TextButton.MouseButton1Down:Connect(function()
						gTa7jfw.State.sl_range_focused = true
						KY.TextBox:CaptureFocus()
					end)
					KY.TextBox.FocusLost:Connect(function(v)
						local aFb6x0hg = tonumber(KY.TextBox.Text)
						if aFb6x0hg then
							if aFb6x0hg > 60 then
								aFb6x0hg = 60
							elseif aFb6x0hg < 0 then
								aFb6x0hg = 0
							end
							gTa7jfw:changeRange("spotlight", aFb6x0hg)
						end
						gTa7jfw.State.sl_range_focused = false
					end)
					local Vg7WM = deq_fwZ.Options.ShadowsOption
					Vg7WM.On.Button.MouseButton1Down:Connect(function()
						gTa7jfw:changeShadows("spotlight", true)
					end)
					Vg7WM.Off.Button.MouseButton1Down:Connect(function()
						gTa7jfw:changeShadows("spotlight", false)
					end)
					local DPOHoac = d6RaDSY.PointLight
					local HLe = DPOHoac.Options.ColorOption
					HLe.RInput.TextButton.MouseButton1Down:Connect(function()
						gTa7jfw.State.pl_color_r_focused = true
						HLe.RInput.TextBox:CaptureFocus()
					end)
					HLe.RInput.TextBox.FocusLost:Connect(function(_KKTJh)
						local Gikjz8_9 = tonumber(HLe.RInput.TextBox.Text)
						if Gikjz8_9 then
							if Gikjz8_9 > 255 then
								Gikjz8_9 = 255
							elseif Gikjz8_9 < 0 then
								Gikjz8_9 = 0
							end
							gTa7jfw:changeColor("pointlight", "r", Gikjz8_9 / 255)
						end
						gTa7jfw.State.pl_color_r_focused = false
					end)
					HLe.GInput.TextButton.MouseButton1Down:Connect(function()
						gTa7jfw.State.pl_color_g_focused = true
						HLe.GInput.TextBox:CaptureFocus()
					end)
					HLe.GInput.TextBox.FocusLost:Connect(function(WN20gP)
						local L2VjlBE = tonumber(HLe.GInput.TextBox.Text)
						if L2VjlBE then
							if L2VjlBE > 255 then
								L2VjlBE = 255
							elseif L2VjlBE < 0 then
								L2VjlBE = 0
							end
							gTa7jfw:changeColor("pointlight", "g", L2VjlBE / 255)
						end
						gTa7jfw.State.pl_color_g_focused = false
					end)
					HLe.BInput.TextButton.MouseButton1Down:Connect(function()
						gTa7jfw.State.pl_color_b_focused = true
						HLe.BInput.TextBox:CaptureFocus()
					end)
					HLe.BInput.TextBox.FocusLost:Connect(function(xH)
						local N = tonumber(HLe.BInput.TextBox.Text)
						if N then
							if N > 255 then
								N = 255
							elseif N < 0 then
								N = 0
							end
							gTa7jfw:changeColor("pointlight", "b", N / 255)
						end
						gTa7jfw.State.pl_color_b_focused = false
					end)
					HLe.HSVPicker.MouseButton1Up:Connect(function()
						ColorPicker:start(function(...)
							local R = {
								...,
							}
							if #R == 3 then
								gTa7jfw:changeColor("pointlight", Support.HSVToRGB(...))
							end
						end, gTa7jfw.State.pl_color)
					end)
					local COX = DPOHoac.Options.BrightnessOption.Input
					COX.TextButton.MouseButton1Down:Connect(function()
						gTa7jfw.State.pl_brightness_focused = true
						COX.TextBox:CaptureFocus()
					end)
					COX.TextBox.FocusLost:Connect(function(owi4kS)
						local zUfjp = tonumber(COX.TextBox.Text)
						if zUfjp then
							if zUfjp > 5 then
								zUfjp = 5
							elseif zUfjp < 0 then
								zUfjp = 0
							end
							gTa7jfw:changeBrightness("pointlight", zUfjp)
						end
						gTa7jfw.State.pl_brightness_focused = false
					end)
					local BP9Y0 = DPOHoac.Options.RangeOption.Input
					BP9Y0.TextButton.MouseButton1Down:Connect(function()
						gTa7jfw.State.pl_range_focused = true
						BP9Y0.TextBox:CaptureFocus()
					end)
					BP9Y0.TextBox.FocusLost:Connect(function(fd5S4R)
						local Jt = tonumber(BP9Y0.TextBox.Text)
						if Jt then
							if Jt > 60 then
								Jt = 60
							elseif Jt < 0 then
								Jt = 0
							end
							gTa7jfw:changeRange("pointlight", Jt)
						end
						gTa7jfw.State.pl_range_focused = false
					end)
					local DR = DPOHoac.Options.ShadowsOption
					DR.On.Button.MouseButton1Down:Connect(function()
						gTa7jfw:changeShadows("pointlight", true)
					end)
					DR.Off.Button.MouseButton1Down:Connect(function()
						gTa7jfw:changeShadows("pointlight", false)
					end)
					gTa7jfw.GUI = d6RaDSY
				end
				setp(gTa7jfw.GUI, "Visible", true)
			end
			Tools.Lighting.changeSide = function(vJ88gTG, GVscDb)
				local eGuTD = vJ88gTG:getSpotlights()
				vJ88gTG:startHistoryRecord(eGuTD)
				for l, rcJbyavv in pairs(eGuTD) do
					setp(rcJbyavv, "Face", GVscDb)
				end
				vJ88gTG:finishHistoryRecord()
				if vJ88gTG.SideDropdown.open then
					vJ88gTG.SideDropdown:toggle()
				end
			end
			Tools.Lighting.changeAngle = function(nPu, wKdmIyn)
				local Po67cFi = nPu:getSpotlights()
				nPu:startHistoryRecord(Po67cFi)
				for nlAeE, h in pairs(Po67cFi) do
					setp(h, "Angle", wKdmIyn)
				end
				nPu:finishHistoryRecord()
			end
			Tools.Lighting.getSpotlights = function(B)
				local mmcA = {}
				for Pk, es in pairs(Selection.Items) do
					local F0ZX = Support.GetChildOfClass(es, "SpotLight")
					if F0ZX then
						table.insert(mmcA, F0ZX)
					end
				end
				return mmcA
			end
			Tools.Lighting.getPointLights = function(W_)
				local he3X = {}
				for IAEOa, lq0 in pairs(Selection.Items) do
					local cJ = Support.GetChildOfClass(lq0, "PointLight")
					if cJ then
						table.insert(he3X, cJ)
					end
				end
				return he3X
			end
			Tools.Lighting.changeColor = function(VxeY5X, oS8SgP, ...)
				local hBilFrU4 = {
					...,
				}
				local AodN1
				if oS8SgP == "spotlight" then
					AodN1 = VxeY5X:getSpotlights()
				elseif oS8SgP == "pointlight" then
					AodN1 = VxeY5X:getPointLights()
				end
				VxeY5X:startHistoryRecord(AodN1)
				if #hBilFrU4 == 2 then
					local yj4Mo = hBilFrU4[1]
					local BiwDB = hBilFrU4[2]
					for Ca, wHJE0ZY in pairs(AodN1) do
						setp(wHJE0ZY, "Color", Color3.new(
							yj4Mo == "r" and BiwDB or wHJE0ZY.Color.r,
							yj4Mo == "g" and BiwDB or wHJE0ZY.Color.g,
							yj4Mo == "b" and BiwDB or wHJE0ZY.Color.b
						))
					end
				elseif #hBilFrU4 == 3 then
					local Js7, h6W2B6z, Cx = ...
					for oj, u1 in pairs(AodN1) do
						setp(u1, "Color", Color3.new(Js7, h6W2B6z, Cx))
					end
				end
				VxeY5X:finishHistoryRecord()
			end
			Tools.Lighting.changeBrightness = function(TYixjzX4, vI9Mah0, Ad)
				local l
				if vI9Mah0 == "spotlight" then
					l = TYixjzX4:getSpotlights()
				elseif vI9Mah0 == "pointlight" then
					l = TYixjzX4:getPointLights()
				end
				TYixjzX4:startHistoryRecord(l)
				for LwNRuJvR, nohO9Ia in pairs(l) do
					setp(nohO9Ia, "Brightness", Ad)
				end
				TYixjzX4:finishHistoryRecord()
			end
			Tools.Lighting.changeRange = function(FDJ, u, v)
				local i0iuEsi
				if u == "spotlight" then
					i0iuEsi = FDJ:getSpotlights()
				elseif u == "pointlight" then
					i0iuEsi = FDJ:getPointLights()
				end
				FDJ:startHistoryRecord(i0iuEsi)
				for qWrjc, y2zVVi in pairs(i0iuEsi) do
					setp(y2zVVi, "Range", v)
				end
				FDJ:finishHistoryRecord()
			end
			Tools.Lighting.changeShadows = function(mQIVEP5, QV4HoK0r, uqoP)
				local fXnJ2kO
				if QV4HoK0r == "spotlight" then
					fXnJ2kO = mQIVEP5:getSpotlights()
				elseif QV4HoK0r == "pointlight" then
					fXnJ2kO = mQIVEP5:getPointLights()
				end
				mQIVEP5:startHistoryRecord(fXnJ2kO)
				for mHD8, L in pairs(fXnJ2kO) do
					setp(L, "Shadows", uqoP)
				end
				mQIVEP5:finishHistoryRecord()
			end
			Tools.Lighting.addLight = function(tlNupYZ, VY6SD)
				local ydb = {
					apply = function(tlNupYZ)
						Selection:clear()
						for ElVn76, yAEULfS in pairs(tlNupYZ.lights) do
							setp(yAEULfS, "Parent", tlNupYZ.light_parents[yAEULfS])
							Selection:add(yAEULfS.Parent)
						end
					end,
					unapply = function(tlNupYZ)
						Selection:clear()
						for O6Ft6oPX, RWubfxqF in pairs(tlNupYZ.lights) do
							Selection:add(RWubfxqF.Parent)
							setp(RWubfxqF, "Parent", nil)
						end
					end,
				}
				local O = {}
				local _ = {}
				for E, e0kpxJ in pairs(Selection.Items) do
					local VXZfG = Support.GetChildOfClass(e0kpxJ, VY6SD)
					if not VXZfG then
						local VXZfG = (RbxUtility.Create(VY6SD))({
							Parent = e0kpxJ,
						})
						table.insert(O, VXZfG)
						_[VXZfG] = e0kpxJ
					end
				end
				ydb.lights = O
				ydb.light_parents = _
				History:add(ydb)
			end
			Tools.Lighting.removeLight = function(Bd, Qf)
				local p2jTk = {
					apply = function(Bd)
						Selection:clear()
						for IR7v, _SmNfMoD in pairs(Bd.lights) do
							Selection:add(_SmNfMoD.Parent)
							setp(_SmNfMoD, "Parent", nil)
						end
					end,
					unapply = function(Bd)
						Selection:clear()
						for g5wBR, z0SIbm in pairs(Bd.lights) do
							setp(z0SIbm, "Parent", Bd.light_parents[z0SIbm])
							Selection:add(z0SIbm.Parent)
						end
					end,
				}
				local _5Pf = {}
				local vHVSWs9 = {}
				local _5Pf
				if Qf == "spotlight" then
					_5Pf = Bd:getSpotlights()
				elseif Qf == "pointlight" then
					_5Pf = Bd:getPointLights()
				end
				for zL, nWzKrVe in pairs(_5Pf) do
					vHVSWs9[nWzKrVe] = nWzKrVe.Parent
					setp(nWzKrVe, "Parent", nil)
				end
				p2jTk.lights = _5Pf
				p2jTk.light_parents = vHVSWs9
				History:add(p2jTk)
			end
			Tools.Lighting.startHistoryRecord = function(zha, yBtE)
				if zha.State.HistoryRecord then
					zha.State.HistoryRecord = nil
				end
				zha.State.HistoryRecord = {
					targets = Support.CloneTable(yBtE),
					initial_color = {},
					terminal_color = {},
					initial_brightness = {},
					terminal_brightness = {},
					initial_range = {},
					terminal_range = {},
					initial_shadows = {},
					terminal_shadows = {},
					initial_side = {},
					terminal_side = {},
					initial_angle = {},
					terminal_angle = {},
					unapply = function(zha)
						Selection:clear()
						for GlmZIM, bm in pairs(zha.targets) do
							if bm then
								Selection:add(bm.Parent)
								setp(bm, "Color", zha.initial_color[bm])
								setp(bm, "Brightness", zha.initial_brightness[bm])
								setp(bm, "Range", zha.initial_range[bm])
								setp(bm, "Shadows", zha.initial_shadows[bm])
								if bm:IsA("SpotLight") then
									setp(bm, "Face", zha.initial_side[bm])
									setp(bm, "Angle", zha.initial_angle[bm])
								end
							end
						end
					end,
					apply = function(zha)
						Selection:clear()
						for ken, gHpr in pairs(zha.targets) do
							if gHpr then
								Selection:add(gHpr.Parent)
								setp(gHpr, "Color", zha.terminal_color[gHpr])
								setp(gHpr, "Brightness", zha.terminal_brightness[gHpr])
								setp(gHpr, "Range", zha.terminal_range[gHpr])
								setp(gHpr, "Shadows", zha.terminal_shadows[gHpr])
								if gHpr:IsA("SpotLight") then
									setp(gHpr, "Face", zha.terminal_side[gHpr])
									setp(gHpr, "Angle", zha.terminal_angle[gHpr])
								end
							end
						end
					end,
				}
				for wL, uXW in pairs(zha.State.HistoryRecord.targets) do
					if uXW then
						zha.State.HistoryRecord.initial_color[uXW] = uXW.Color
						zha.State.HistoryRecord.initial_brightness[uXW] = uXW.Brightness
						zha.State.HistoryRecord.initial_range[uXW] = uXW.Range
						zha.State.HistoryRecord.initial_shadows[uXW] = uXW.Shadows
						if uXW:IsA("SpotLight") then
							zha.State.HistoryRecord.initial_side[uXW] = uXW.Face
							zha.State.HistoryRecord.initial_angle[uXW] = uXW.Angle
						end
					end
				end
			end
			Tools.Lighting.finishHistoryRecord = function(f1Guph)
				if not f1Guph.State.HistoryRecord then
					return
				end
				for VoIe2R, wULNB in pairs(f1Guph.State.HistoryRecord.targets) do
					if wULNB then
						f1Guph.State.HistoryRecord.terminal_color[wULNB] = wULNB.Color
						f1Guph.State.HistoryRecord.terminal_brightness[wULNB] = wULNB.Brightness
						f1Guph.State.HistoryRecord.terminal_range[wULNB] = wULNB.Range
						f1Guph.State.HistoryRecord.terminal_shadows[wULNB] = wULNB.Shadows
						if wULNB:IsA("SpotLight") then
							f1Guph.State.HistoryRecord.terminal_side[wULNB] = wULNB.Face
							f1Guph.State.HistoryRecord.terminal_angle[wULNB] = wULNB.Angle
						end
					end
				end
				History:add(f1Guph.State.HistoryRecord)
				f1Guph.State.HistoryRecord = nil
			end
			Tools.Lighting.hideGUI = function(Uin1c)
				if Uin1c.GUI then
					setp(Uin1c.GUI, "Visible", false)
				end
			end
			Tools.Lighting.Loaded = true
		end,
	},
	{
		"Decorate",
		function()
			repeat
				task.wait()
			until _G.BTCoreEnv and _G.BTCoreEnv.tool and _G.BTCoreEnv.tool.CoreReady
			setfenv(1, _G.BTCoreEnv.tool)
			Tools.Decorate = {}
			setp(Tools.Decorate, "Color", BrickColor.new("Really black"))
			Tools.Decorate.State = {}
			Tools.Decorate.Connections = {}
			Tools.Decorate.Listeners = {}
			Tools.Decorate.Listeners.Equipped = function()
				local uZOynu = Tools.Decorate
				uZOynu.State.PreviousSelectionBoxColor = SelectionBoxColor
				SelectionBoxColor = uZOynu.Color
				updateSelectionBoxColor()
				uZOynu:showGUI();
				(coroutine.wrap(function()
					updater_on = true
					uZOynu.Updater = function()
						updater_on = false
					end
					while task.wait(0.1) and updater_on do
						if CurrentTool == uZOynu then
							if uZOynu.GUI and uZOynu.GUI.Visible then
								uZOynu:updateGUI()
							end
						end
					end
				end))()
			end
			Tools.Decorate.Listeners.Unequipped = function()
				local XYjab = Tools.Decorate
				if XYjab.Updater then
					XYjab.Updater()
					XYjab.Updater = nil
				end
				XYjab:hideGUI()
				for g226Ed, iKS in pairs(XYjab.Connections) do
					iKS:Disconnect()
					XYjab.Connections[g226Ed] = nil
				end
				SelectionBoxColor = XYjab.State.PreviousSelectionBoxColor
				updateSelectionBoxColor()
			end
			Tools.Decorate.updateGUI = function(vKlf)
				if not vKlf.GUI then
					return
				end
				if #Selection.Items > 0 then
					local SlWsaU = vKlf:getSmoke()
					local Mj = vKlf:getFire()
					local c_ = vKlf:getSparkles()
					local Kw4ta8iS, AlV6, LtS, TaJ2US, Ghp0, opR
					local sif2, PGiQADW, PI, dZc, iebKJjA, d, CaFSQRf, vn3NH
					local JFZ, L, j_st9
					for Ubiy, mIV in pairs(SlWsaU) do
						if Ubiy == 1 then
							Kw4ta8iS, AlV6, LtS = mIV.Color.r, mIV.Color.g, mIV.Color.b
							TaJ2US = mIV.Opacity
							Ghp0 = mIV.RiseVelocity
							opR = mIV.Size
						else
							if Kw4ta8iS ~= mIV.Color.r then
								Kw4ta8iS = nil
							end
							if AlV6 ~= mIV.Color.g then
								AlV6 = nil
							end
							if LtS ~= mIV.Color.b then
								LtS = nil
							end
							if TaJ2US ~= mIV.Opacity then
								TaJ2US = nil
							end
							if Ghp0 ~= mIV.RiseVelocity then
								Ghp0 = nil
							end
							if opR ~= mIV.Size then
								opR = nil
							end
						end
					end
					for hgRaw, vvwRldj in pairs(Mj) do
						if hgRaw == 1 then
							sif2, PGiQADW, PI = vvwRldj.Color.r, vvwRldj.Color.g, vvwRldj.Color.b
							dZc, iebKJjA, d =
								vvwRldj.SecondaryColor.r, vvwRldj.SecondaryColor.g, vvwRldj.SecondaryColor.b
							CaFSQRf = vvwRldj.Heat
							vn3NH = vvwRldj.Size
						else
							if sif2 ~= vvwRldj.Color.r then
								sif2 = nil
							end
							if PGiQADW ~= vvwRldj.Color.g then
								PGiQADW = nil
							end
							if PI ~= vvwRldj.Color.b then
								PI = nil
							end
							if dZc ~= vvwRldj.SecondaryColor.r then
								dZc = nil
							end
							if iebKJjA ~= vvwRldj.SecondaryColor.g then
								iebKJjA = nil
							end
							if d ~= vvwRldj.SecondaryColor.b then
								d = nil
							end
							if CaFSQRf ~= vvwRldj.Heat then
								CaFSQRf = nil
							end
							if vn3NH ~= vvwRldj.Size then
								vn3NH = nil
							end
						end
					end
					for f_7I8Jo, K072gC9 in pairs(c_) do
						if f_7I8Jo == 1 then
							JFZ, L, j_st9 = K072gC9.SparkleColor.r, K072gC9.SparkleColor.g, K072gC9.SparkleColor.b
						else
							if JFZ ~= K072gC9.SparkleColor.r then
								JFZ = nil
							end
							if L ~= K072gC9.SparkleColor.g then
								L = nil
							end
							if j_st9 ~= K072gC9.SparkleColor.b then
								j_st9 = nil
							end
						end
					end
					vKlf.State.smoke_color = Kw4ta8iS and AlV6 and LtS and Color3.new(Kw4ta8iS, AlV6, LtS) or nil
					vKlf.State.fire_color = sif2 and PGiQADW and PI and Color3.new(sif2, PGiQADW, PI) or nil
					vKlf.State.fire_2nd_color = dZc and iebKJjA and d and Color3.new(dZc, iebKJjA, d) or nil
					vKlf.State.sparkles_color = JFZ and L and j_st9 and Color3.new(JFZ, L, j_st9) or nil
					if not vKlf.State.smoke_color_r_focused then
						vKlf.GUI.Smoke.Options.ColorOption.RInput.TextBox.Text = Kw4ta8iS
							and Support.Round(Kw4ta8iS * 255, 0)
							or "*"
					end
					if not vKlf.State.smoke_color_g_focused then
						vKlf.GUI.Smoke.Options.ColorOption.GInput.TextBox.Text = AlV6 and Support.Round(AlV6 * 255, 0)
							or "*"
					end
					if not vKlf.State.smoke_color_b_focused then
						vKlf.GUI.Smoke.Options.ColorOption.BInput.TextBox.Text = LtS and Support.Round(LtS * 255, 0)
							or "*"
					end
					if not vKlf.State.smoke_opacity_focused then
						vKlf.GUI.Smoke.Options.OpacityOption.Input.TextBox.Text = TaJ2US and Support.Round(TaJ2US, 2)
							or "*"
					end
					if not vKlf.State.smoke_velocity_focused then
						vKlf.GUI.Smoke.Options.VelocityOption.Input.TextBox.Text = Ghp0 and Support.Round(Ghp0, 2)
							or "*"
					end
					if not vKlf.State.smoke_size_focused then
						setp(vKlf.GUI.Smoke.Options.SizeOption.Input.TextBox, "Text", opR and Support.Round(opR, 2) or "*")
					end
					if not vKlf.State.fire_color_r_focused then
						vKlf.GUI.Fire.Options.ColorOption.RInput.TextBox.Text = sif2 and Support.Round(sif2 * 255, 0)
							or "*"
					end
					if not vKlf.State.fire_color_g_focused then
						vKlf.GUI.Fire.Options.ColorOption.GInput.TextBox.Text = PGiQADW
							and Support.Round(PGiQADW * 255, 0)
							or "*"
					end
					if not vKlf.State.fire_color_b_focused then
						setp(vKlf.GUI.Fire.Options.ColorOption.BInput.TextBox, "Text", PI and Support.Round(PI * 255, 0) or "*")
					end
					if not vKlf.State.fire_2nd_color_r_focused then
						vKlf.GUI.Fire.Options.SecondColorOption.RInput.TextBox.Text = dZc
							and Support.Round(dZc * 255, 0)
							or "*"
					end
					if not vKlf.State.fire_2nd_color_g_focused then
						vKlf.GUI.Fire.Options.SecondColorOption.GInput.TextBox.Text = iebKJjA
							and Support.Round(iebKJjA * 255, 0)
							or "*"
					end
					if not vKlf.State.fire_2nd_color_b_focused then
						vKlf.GUI.Fire.Options.SecondColorOption.BInput.TextBox.Text = d and Support.Round(d * 255, 0)
							or "*"
					end
					if not vKlf.State.fire_heat_focused then
						vKlf.GUI.Fire.Options.HeatOption.Input.TextBox.Text = CaFSQRf and Support.Round(CaFSQRf, 2)
							or "*"
					end
					if not vKlf.State.fire_size_focused then
						setp(vKlf.GUI.Fire.Options.SizeOption.Input.TextBox, "Text", vn3NH and Support.Round(vn3NH, 2) or "*")
					end
					if not vKlf.State.sparkles_color_r_focused then
						vKlf.GUI.Sparkles.Options.ColorOption.RInput.TextBox.Text = JFZ and Support.Round(JFZ * 255, 0)
							or "*"
					end
					if not vKlf.State.sparkles_color_g_focused then
						vKlf.GUI.Sparkles.Options.ColorOption.GInput.TextBox.Text = L and Support.Round(L * 255, 0)
							or "*"
					end
					if not vKlf.State.sparkles_color_b_focused then
						vKlf.GUI.Sparkles.Options.ColorOption.BInput.TextBox.Text = j_st9
							and Support.Round(j_st9 * 255, 0)
							or "*"
					end
					if vKlf.GUI.SelectNote.Visible then
						vKlf:closeSmoke()
						vKlf:closeFire()
						vKlf:closeSparkles()
					end
					setp(vKlf.GUI.Smoke, "Visible", true)
					setp(vKlf.GUI.Fire, "Visible", true)
					setp(vKlf.GUI.Sparkles, "Visible", true)
					setp(vKlf.GUI.SelectNote, "Visible", false)
					if not vKlf.State.smoke_open and not vKlf.State.fire_open and not vKlf.State.sparkles_open then
						vKlf.GUI:TweenSize(
							UDim2.new(0, 200, 0, 125),
							Enum.EasingDirection.Out,
							Enum.EasingStyle.Quad,
							0.5,
							true
						)
					end
					if #SlWsaU == 0 then
						setp(vKlf.GUI.Smoke.Options, "Size", UDim2.new(1, -3, 0, 0))
						setp(vKlf.GUI.Smoke.AddButton, "Visible", true)
						setp(vKlf.GUI.Smoke.RemoveButton, "Visible", false)
						if vKlf.State.smoke_open then
							vKlf:closeSmoke()
						end
					elseif #SlWsaU ~= #Selection.Items then
						setp(vKlf.GUI.Smoke.AddButton, "Visible", true)
						setp(vKlf.GUI.Smoke.RemoveButton, "Position", UDim2.new(0, 90, 0, 3))
						setp(vKlf.GUI.Smoke.RemoveButton, "Visible", true)
					elseif #SlWsaU == #Selection.Items then
						setp(vKlf.GUI.Smoke.AddButton, "Visible", false)
						setp(vKlf.GUI.Smoke.RemoveButton, "Position", UDim2.new(0, 127, 0, 3))
						setp(vKlf.GUI.Smoke.RemoveButton, "Visible", true)
						if vKlf.GUI.Smoke.Size == UDim2.new(0, 200, 0, 52) then
							setp(vKlf.GUI.Smoke, "Size", UDim2.new(0, 200, 0, 125))
						end
					end
					if #Mj == 0 then
						setp(vKlf.GUI.Fire.Options, "Size", UDim2.new(1, -3, 0, 0))
						setp(vKlf.GUI.Fire.AddButton, "Visible", true)
						setp(vKlf.GUI.Fire.RemoveButton, "Visible", false)
						if vKlf.State.fire_open then
							vKlf:closeFire()
						end
					elseif #Mj ~= #Selection.Items then
						setp(vKlf.GUI.Fire.AddButton, "Visible", true)
						setp(vKlf.GUI.Fire.RemoveButton, "Position", UDim2.new(0, 90, 0, 3))
						setp(vKlf.GUI.Fire.RemoveButton, "Visible", true)
					elseif #Mj == #Selection.Items then
						setp(vKlf.GUI.Fire.AddButton, "Visible", false)
						setp(vKlf.GUI.Fire.RemoveButton, "Position", UDim2.new(0, 127, 0, 3))
						setp(vKlf.GUI.Fire.RemoveButton, "Visible", true)
					end
					if #c_ == 0 then
						setp(vKlf.GUI.Sparkles.Options, "Size", UDim2.new(1, -3, 0, 0))
						setp(vKlf.GUI.Sparkles.AddButton, "Visible", true)
						setp(vKlf.GUI.Sparkles.RemoveButton, "Visible", false)
						if vKlf.State.sparkles_open then
							vKlf:closeSparkles()
						end
					elseif #c_ ~= #Selection.Items then
						setp(vKlf.GUI.Sparkles.AddButton, "Visible", true)
						setp(vKlf.GUI.Sparkles.RemoveButton, "Position", UDim2.new(0, 90, 0, 3))
						setp(vKlf.GUI.Sparkles.RemoveButton, "Visible", true)
					elseif #c_ == #Selection.Items then
						setp(vKlf.GUI.Sparkles.AddButton, "Visible", false)
						setp(vKlf.GUI.Sparkles.RemoveButton, "Position", UDim2.new(0, 127, 0, 3))
						setp(vKlf.GUI.Sparkles.RemoveButton, "Visible", true)
					end
				else
					setp(vKlf.GUI.Smoke, "Visible", false)
					setp(vKlf.GUI.Fire, "Visible", false)
					setp(vKlf.GUI.Sparkles, "Visible", false)
					setp(vKlf.GUI.SelectNote, "Visible", true)
					setp(vKlf.GUI, "Size", UDim2.new(0, 200, 0, 52))
				end
			end
			Tools.Decorate.openSmoke = function(SbuPM)
				SbuPM.State.smoke_open = true
				SbuPM:closeFire()
				SbuPM:closeSparkles()
				SbuPM.GUI.Smoke.Options:TweenSize(
					UDim2.new(1, -3, 0, 110),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				SbuPM.GUI.Smoke:TweenPosition(
					UDim2.new(0, 10, 0, 30),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				SbuPM.GUI:TweenSize(
					UDim2.new(0, 200, 0, 235),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
			end
			Tools.Decorate.openFire = function(cobaoFK)
				cobaoFK.State.fire_open = true
				cobaoFK:closeSmoke()
				cobaoFK:closeSparkles()
				cobaoFK.GUI.Fire.Options:TweenSize(
					UDim2.new(1, -3, 0, 110),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				cobaoFK.GUI.Fire:TweenPosition(
					UDim2.new(0, 10, 0, 60),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				cobaoFK.GUI:TweenSize(
					UDim2.new(0, 200, 0, 235),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
			end
			Tools.Decorate.openSparkles = function(JbhOvI)
				JbhOvI.State.sparkles_open = true
				JbhOvI:closeSmoke()
				JbhOvI:closeFire()
				JbhOvI.GUI.Sparkles.Options:TweenSize(
					UDim2.new(1, -3, 0, 40),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				JbhOvI.GUI.Sparkles:TweenPosition(
					UDim2.new(0, 10, 0, 90),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				JbhOvI.GUI:TweenSize(
					UDim2.new(0, 200, 0, 160),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
			end
			Tools.Decorate.closeSmoke = function(yA)
				yA.State.smoke_open = false
				yA.GUI.Smoke.Options:TweenSize(
					UDim2.new(1, -3, 0, 0),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				yA.GUI.Fire:TweenPosition(
					UDim2.new(0, 10, 0, 60),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				if not yA.State.fire_open then
					yA.GUI.Sparkles:TweenPosition(
						UDim2.new(0, 10, 0, 90),
						Enum.EasingDirection.Out,
						Enum.EasingStyle.Quad,
						0.5,
						true
					)
				end
				if not yA.State.fire_open and not yA.State.sparkles_open then
					yA.GUI:TweenSize(
						UDim2.new(0, 200, 0, 125),
						Enum.EasingDirection.Out,
						Enum.EasingStyle.Quad,
						0.5,
						true
					)
				end
			end
			Tools.Decorate.closeFire = function(NUsjSgB)
				NUsjSgB.State.fire_open = false
				if NUsjSgB.State.smoke_open then
					NUsjSgB.GUI.Fire:TweenPosition(
						UDim2.new(0, 10, 0, 170),
						Enum.EasingDirection.Out,
						Enum.EasingStyle.Quad,
						0.5,
						true
					)
				else
					NUsjSgB.GUI.Fire:TweenPosition(
						UDim2.new(0, 10, 0, 60),
						Enum.EasingDirection.Out,
						Enum.EasingStyle.Quad,
						0.5,
						true
					)
				end
				NUsjSgB.GUI.Fire.Options:TweenSize(
					UDim2.new(1, -3, 0, 0),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				if not NUsjSgB.State.smoke_open then
					NUsjSgB.GUI.Sparkles:TweenPosition(
						UDim2.new(0, 10, 0, 90),
						Enum.EasingDirection.Out,
						Enum.EasingStyle.Quad,
						0.5,
						true
					)
				end
				if not NUsjSgB.State.smoke_open and not NUsjSgB.State.sparkles_open then
					NUsjSgB.GUI:TweenSize(
						UDim2.new(0, 200, 0, 125),
						Enum.EasingDirection.Out,
						Enum.EasingStyle.Quad,
						0.5,
						true
					)
				end
			end
			Tools.Decorate.closeSparkles = function(Xuvxfbm)
				Xuvxfbm.State.sparkles_open = false
				if Xuvxfbm.State.smoke_open or Xuvxfbm.State.fire_open then
					Xuvxfbm.GUI.Sparkles:TweenPosition(
						UDim2.new(0, 10, 0, 200),
						Enum.EasingDirection.Out,
						Enum.EasingStyle.Quad,
						0.5,
						true
					)
				else
					Xuvxfbm.GUI.Sparkles:TweenPosition(
						UDim2.new(0, 10, 0, 90),
						Enum.EasingDirection.Out,
						Enum.EasingStyle.Quad,
						0.5,
						true
					)
				end
				Xuvxfbm.GUI.Sparkles.Options:TweenSize(
					UDim2.new(1, -3, 0, 0),
					Enum.EasingDirection.Out,
					Enum.EasingStyle.Quad,
					0.5,
					true
				)
				if not Xuvxfbm.State.smoke_open and not Xuvxfbm.State.fire_open then
					Xuvxfbm.GUI:TweenSize(
						UDim2.new(0, 200, 0, 125),
						Enum.EasingDirection.Out,
						Enum.EasingStyle.Quad,
						0.5,
						true
					)
				end
			end
			Tools.Decorate.showGUI = function(tY)
				if not tY.GUI then
					local l1YAdT2c = DFb100j.BTDecorateToolGUI:Clone()
					setp(l1YAdT2c, "Parent", UI)
					l1YAdT2c.Smoke.ArrowButton.MouseButton1Up:Connect(function()
						if not tY.State.smoke_open and #tY:getSmoke() > 0 then
							tY:openSmoke()
						else
							tY:closeSmoke()
						end
					end)
					l1YAdT2c.Fire.ArrowButton.MouseButton1Up:Connect(function()
						if not tY.State.fire_open and #tY:getFire() > 0 then
							tY:openFire()
						else
							tY:closeFire()
						end
					end)
					l1YAdT2c.Sparkles.ArrowButton.MouseButton1Up:Connect(function()
						if not tY.State.sparkles_open and #tY:getSparkles() > 0 then
							tY:openSparkles()
						else
							tY:closeSparkles()
						end
					end)
					l1YAdT2c.Smoke.AddButton.MouseButton1Up:Connect(function()
						tY:addSmoke()
						tY:openSmoke()
					end)
					l1YAdT2c.Fire.AddButton.MouseButton1Up:Connect(function()
						tY:addFire()
						tY:openFire()
					end)
					l1YAdT2c.Sparkles.AddButton.MouseButton1Up:Connect(function()
						tY:addSparkles()
						tY:openSparkles()
					end)
					l1YAdT2c.Smoke.RemoveButton.MouseButton1Up:Connect(function()
						tY:removeSmoke()
						tY:closeSmoke()
					end)
					l1YAdT2c.Fire.RemoveButton.MouseButton1Up:Connect(function()
						tY:removeFire()
						tY:closeFire()
					end)
					l1YAdT2c.Sparkles.RemoveButton.MouseButton1Up:Connect(function()
						tY:removeSparkles()
						tY:closeSparkles()
					end)
					local A1A = l1YAdT2c.Smoke
					local PMB1UGv = A1A.Options.ColorOption
					PMB1UGv.RInput.TextButton.MouseButton1Down:Connect(function()
						tY.State.smoke_color_r_focused = true
						PMB1UGv.RInput.TextBox:CaptureFocus()
					end)
					PMB1UGv.RInput.TextBox.FocusLost:Connect(function(_MI)
						local TITR = tonumber(PMB1UGv.RInput.TextBox.Text)
						if TITR then
							if TITR > 255 then
								TITR = 255
							elseif TITR < 0 then
								TITR = 0
							end
							tY:changeSmokeColor("r", TITR / 255)
						end
						tY.State.smoke_color_r_focused = false
					end)
					PMB1UGv.GInput.TextButton.MouseButton1Down:Connect(function()
						tY.State.smoke_color_g_focused = true
						PMB1UGv.GInput.TextBox:CaptureFocus()
					end)
					PMB1UGv.GInput.TextBox.FocusLost:Connect(function(i_aIFe)
						local YFJRo6 = tonumber(PMB1UGv.GInput.TextBox.Text)
						if YFJRo6 then
							if YFJRo6 > 255 then
								YFJRo6 = 255
							elseif YFJRo6 < 0 then
								YFJRo6 = 0
							end
							tY:changeSmokeColor("g", YFJRo6 / 255)
						end
						tY.State.smoke_color_g_focused = false
					end)
					PMB1UGv.BInput.TextButton.MouseButton1Down:Connect(function()
						tY.State.smoke_color_b_focused = true
						PMB1UGv.BInput.TextBox:CaptureFocus()
					end)
					PMB1UGv.BInput.TextBox.FocusLost:Connect(function(V3EcTFrW)
						local zJbXZu2D = tonumber(PMB1UGv.BInput.TextBox.Text)
						if zJbXZu2D then
							if zJbXZu2D > 255 then
								zJbXZu2D = 255
							elseif zJbXZu2D < 0 then
								zJbXZu2D = 0
							end
							tY:changeSmokeColor("b", zJbXZu2D / 255)
						end
						tY.State.smoke_color_b_focused = false
					end)
					PMB1UGv.HSVPicker.MouseButton1Up:Connect(function()
						ColorPicker:start(function(...)
							local drq = {
								...,
							}
							if #drq == 3 then
								tY:changeSmokeColor(Support.HSVToRGB(...))
							end
						end, tY.State.smoke_color)
					end)
					local TicLenZ = A1A.Options.OpacityOption.Input
					TicLenZ.TextButton.MouseButton1Down:Connect(function()
						tY.State.smoke_opacity_focused = true
						TicLenZ.TextBox:CaptureFocus()
					end)
					TicLenZ.TextBox.FocusLost:Connect(function(ezkF)
						local dlHohKjZ = tonumber(TicLenZ.TextBox.Text)
						if dlHohKjZ then
							if dlHohKjZ > 1 then
								dlHohKjZ = 1
							elseif dlHohKjZ < 0 then
								dlHohKjZ = 0
							end
							tY:changeSmokeOpacity(dlHohKjZ)
						end
						tY.State.smoke_opacity_focused = false
					end)
					local Xc = A1A.Options.VelocityOption.Input
					Xc.TextButton.MouseButton1Down:Connect(function()
						tY.State.smoke_velocity_focused = true
						Xc.TextBox:CaptureFocus()
					end)
					Xc.TextBox.FocusLost:Connect(function(QI)
						local fI = tonumber(Xc.TextBox.Text)
						if fI then
							if fI > 25 then
								fI = 25
							elseif fI < -25 then
								fI = -25
							end
							tY:changeSmokeVelocity(fI)
						end
						tY.State.smoke_velocity_focused = false
					end)
					local onx = A1A.Options.SizeOption.Input
					onx.TextButton.MouseButton1Down:Connect(function()
						tY.State.smoke_size_focused = true
						onx.TextBox:CaptureFocus()
					end)
					onx.TextBox.FocusLost:Connect(function(In)
						local u = tonumber(onx.TextBox.Text)
						if u then
							if u > 100 then
								u = 100
							elseif u < 0.1 then
								u = 0.1
							end
							tY:changeSmokeSize(u)
						end
						tY.State.smoke_size_focused = false
					end)
					local z = l1YAdT2c.Fire
					local hHo = z.Options.ColorOption
					hHo.RInput.TextButton.MouseButton1Down:Connect(function()
						tY.State.fire_color_r_focused = true
						hHo.RInput.TextBox:CaptureFocus()
					end)
					hHo.RInput.TextBox.FocusLost:Connect(function(ygfhj)
						local fN = tonumber(hHo.RInput.TextBox.Text)
						if fN then
							if fN > 255 then
								fN = 255
							elseif fN < 0 then
								fN = 0
							end
							tY:changeFireColor("r", fN / 255)
						end
						tY.State.fire_color_r_focused = false
					end)
					hHo.GInput.TextButton.MouseButton1Down:Connect(function()
						tY.State.fire_color_g_focused = true
						hHo.GInput.TextBox:CaptureFocus()
					end)
					hHo.GInput.TextBox.FocusLost:Connect(function(ws8)
						local yDc8 = tonumber(hHo.GInput.TextBox.Text)
						if yDc8 then
							if yDc8 > 255 then
								yDc8 = 255
							elseif yDc8 < 0 then
								yDc8 = 0
							end
							tY:changeFireColor("g", yDc8 / 255)
						end
						tY.State.fire_color_g_focused = false
					end)
					hHo.BInput.TextButton.MouseButton1Down:Connect(function()
						tY.State.fire_color_b_focused = true
						hHo.BInput.TextBox:CaptureFocus()
					end)
					hHo.BInput.TextBox.FocusLost:Connect(function(d3g)
						local vZH = tonumber(hHo.BInput.TextBox.Text)
						if vZH then
							if vZH > 255 then
								vZH = 255
							elseif vZH < 0 then
								vZH = 0
							end
							tY:changeFireColor("b", vZH / 255)
						end
						tY.State.fire_color_b_focused = false
					end)
					hHo.HSVPicker.MouseButton1Up:Connect(function()
						ColorPicker:start(function(...)
							local RWqs = {
								...,
							}
							if #RWqs == 3 then
								tY:changeFireColor(Support.HSVToRGB(...))
							end
						end, tY.State.fire_color)
					end)
					local fgqM6D = z.Options.SecondColorOption
					fgqM6D.RInput.TextButton.MouseButton1Down:Connect(function()
						tY.State.fire_2nd_color_r_focused = true
						fgqM6D.RInput.TextBox:CaptureFocus()
					end)
					fgqM6D.RInput.TextBox.FocusLost:Connect(function(tn)
						local FKyVcS = tonumber(fgqM6D.RInput.TextBox.Text)
						if FKyVcS then
							if FKyVcS > 255 then
								FKyVcS = 255
							elseif FKyVcS < 0 then
								FKyVcS = 0
							end
							tY:changeFireColor2("r", FKyVcS / 255)
						end
						tY.State.fire_2nd_color_r_focused = false
					end)
					fgqM6D.GInput.TextButton.MouseButton1Down:Connect(function()
						tY.State.fire_2nd_color_g_focused = true
						fgqM6D.GInput.TextBox:CaptureFocus()
					end)
					fgqM6D.GInput.TextBox.FocusLost:Connect(function(zNfSeV)
						local HtbHbcu = tonumber(fgqM6D.GInput.TextBox.Text)
						if HtbHbcu then
							if HtbHbcu > 255 then
								HtbHbcu = 255
							elseif HtbHbcu < 0 then
								HtbHbcu = 0
							end
							tY:changeFireColor2("g", HtbHbcu / 255)
						end
						tY.State.fire_2nd_color_g_focused = false
					end)
					fgqM6D.BInput.TextButton.MouseButton1Down:Connect(function()
						tY.State.fire_2nd_color_b_focused = true
						fgqM6D.BInput.TextBox:CaptureFocus()
					end)
					fgqM6D.BInput.TextBox.FocusLost:Connect(function(MDLzj7)
						local RNIZJ = tonumber(fgqM6D.BInput.TextBox.Text)
						if RNIZJ then
							if RNIZJ > 255 then
								RNIZJ = 255
							elseif RNIZJ < 0 then
								RNIZJ = 0
							end
							tY:changeFireColor2("b", RNIZJ / 255)
						end
						tY.State.fire_2nd_color_b_focused = false
					end)
					fgqM6D.HSVPicker.MouseButton1Up:Connect(function()
						ColorPicker:start(function(...)
							local ma = {
								...,
							}
							if #ma == 3 then
								tY:changeFireColor2(Support.HSVToRGB(...))
							end
						end, tY.State.fire_2nd_color)
					end)
					local KXz5 = z.Options.HeatOption.Input
					KXz5.TextButton.MouseButton1Down:Connect(function()
						tY.State.fire_heat_focused = true
						KXz5.TextBox:CaptureFocus()
					end)
					KXz5.TextBox.FocusLost:Connect(function(X_)
						local E_fkS = tonumber(KXz5.TextBox.Text)
						if E_fkS then
							if E_fkS > 25 then
								E_fkS = 25
							elseif E_fkS < -25 then
								E_fkS = -25
							end
							tY:changeFireHeat(E_fkS)
						end
						tY.State.fire_heat_focused = false
					end)
					local IxVqKpu = z.Options.SizeOption.Input
					IxVqKpu.TextButton.MouseButton1Down:Connect(function()
						tY.State.fire_size_focused = true
						IxVqKpu.TextBox:CaptureFocus()
					end)
					IxVqKpu.TextBox.FocusLost:Connect(function(iv18CGzs)
						local TpEB = tonumber(IxVqKpu.TextBox.Text)
						if TpEB then
							if TpEB > 30 then
								TpEB = 30
							elseif TpEB < 2 then
								TpEB = 2
							end
							tY:changeFireSize(TpEB)
						end
						tY.State.fire_size_focused = false
					end)
					local B0cg08r_ = l1YAdT2c.Sparkles
					local GRkE = B0cg08r_.Options.ColorOption
					GRkE.RInput.TextButton.MouseButton1Down:Connect(function()
						tY.State.sparkles_color_r_focused = true
						GRkE.RInput.TextBox:CaptureFocus()
					end)
					GRkE.RInput.TextBox.FocusLost:Connect(function(x)
						local yF1U = tonumber(GRkE.RInput.TextBox.Text)
						if yF1U then
							if yF1U > 255 then
								yF1U = 255
							elseif yF1U < 0 then
								yF1U = 0
							end
							tY:changeSparklesColor("r", yF1U / 255)
						end
						tY.State.sparkles_color_r_focused = false
					end)
					GRkE.GInput.TextButton.MouseButton1Down:Connect(function()
						tY.State.sparkles_color_g_focused = true
						GRkE.GInput.TextBox:CaptureFocus()
					end)
					GRkE.GInput.TextBox.FocusLost:Connect(function(JE6a4s)
						local sloRQ = tonumber(GRkE.GInput.TextBox.Text)
						if sloRQ then
							if sloRQ > 255 then
								sloRQ = 255
							elseif sloRQ < 0 then
								sloRQ = 0
							end
							tY:changeSparklesColor("g", sloRQ / 255)
						end
						tY.State.sparkles_color_g_focused = false
					end)
					GRkE.BInput.TextButton.MouseButton1Down:Connect(function()
						tY.State.sparkles_color_b_focused = true
						GRkE.BInput.TextBox:CaptureFocus()
					end)
					GRkE.BInput.TextBox.FocusLost:Connect(function(mJ2)
						local P = tonumber(GRkE.BInput.TextBox.Text)
						if P then
							if P > 255 then
								P = 255
							elseif P < 0 then
								P = 0
							end
							tY:changeSparklesColor("b", P / 255)
						end
						tY.State.sparkles_color_b_focused = false
					end)
					GRkE.HSVPicker.MouseButton1Up:Connect(function()
						ColorPicker:start(function(...)
							local Ge = {
								...,
							}
							if #Ge == 3 then
								tY:changeSparklesColor(Support.HSVToRGB(...))
							end
						end, tY.State.sparkles_color)
					end)
					tY.GUI = l1YAdT2c
				end
				setp(tY.GUI, "Visible", true)
			end
			Tools.Decorate.changeSmokeOpacity = function(tYF, jzn73)
				local vQTwJ6V1 = tYF:getSmoke()
				tYF:startHistoryRecord(vQTwJ6V1)
				for Knf7U, I0 in pairs(vQTwJ6V1) do
					I0.Opacity = jzn73
				end
				tYF:finishHistoryRecord()
			end
			Tools.Decorate.changeSmokeVelocity = function(jFyAt, LyJxC)
				local E = jFyAt:getSmoke()
				jFyAt:startHistoryRecord(E)
				for vnC8kIGX, dnKfz in pairs(E) do
					dnKfz.RiseVelocity = LyJxC
				end
				jFyAt:finishHistoryRecord()
			end
			Tools.Decorate.changeSmokeSize = function(kDt, QLp)
				local IXNl = kDt:getSmoke()
				kDt:startHistoryRecord(IXNl)
				for oqPG, Pa in pairs(IXNl) do
					setp(Pa, "Size", QLp)
				end
				kDt:finishHistoryRecord()
			end
			Tools.Decorate.changeFireHeat = function(j37n1ZA, aLxQ)
				local GW = j37n1ZA:getFire()
				j37n1ZA:startHistoryRecord(GW)
				for AzhdvccS, J in pairs(GW) do
					J.Heat = aLxQ
				end
				j37n1ZA:finishHistoryRecord()
			end
			Tools.Decorate.changeFireSize = function(PYFFxAp, i)
				local AP1UcfB = PYFFxAp:getFire()
				PYFFxAp:startHistoryRecord(AP1UcfB)
				for e, H4 in pairs(AP1UcfB) do
					setp(H4, "Size", i)
				end
				PYFFxAp:finishHistoryRecord()
			end
			Tools.Decorate.getSmoke = function(CMIGYkL8)
				local n9FOtM = {}
				for K, EeAZn in pairs(Selection.Items) do
					local aCKog = Support.GetChildOfClass(EeAZn, "Smoke")
					if aCKog then
						table.insert(n9FOtM, aCKog)
					end
				end
				return n9FOtM
			end
			Tools.Decorate.getFire = function(c)
				local OWrvY = {}
				for lp2, k in pairs(Selection.Items) do
					local sEjUvkV = Support.GetChildOfClass(k, "Fire")
					if sEjUvkV then
						table.insert(OWrvY, sEjUvkV)
					end
				end
				return OWrvY
			end
			Tools.Decorate.getSparkles = function(pnOWD9)
				local iRm2 = {}
				for J61iBvjC, _ in pairs(Selection.Items) do
					local X79LkbfD = Support.GetChildOfClass(_, "Sparkles")
					if X79LkbfD then
						table.insert(iRm2, X79LkbfD)
					end
				end
				return iRm2
			end
			Tools.Decorate.changeSmokeColor = function(JNRj6X, ...)
				local ldz480 = {
					...,
				}
				local rE = JNRj6X:getSmoke()
				JNRj6X:startHistoryRecord(rE)
				if #ldz480 == 2 then
					local f7eR2T = ldz480[1]
					local l = ldz480[2]
					for XZ3A, Czs0f in pairs(rE) do
						Czs0f.Color = Color3.new(
							f7eR2T == "r" and l or Czs0f.Color.r,
							f7eR2T == "g" and l or Czs0f.Color.g,
							f7eR2T == "b" and l or Czs0f.Color.b
						)
					end
				elseif #ldz480 == 3 then
					local aMvb, _QG, CWG = ...
					for z1q, YkD6SuyP in pairs(rE) do
						setp(YkD6SuyP, "Color", Color3.new(aMvb, _QG, CWG))
					end
				end
				JNRj6X:finishHistoryRecord()
			end
			Tools.Decorate.changeFireColor = function(GW3xWh, ...)
				local eA_ohY = {
					...,
				}
				local b5p2AMKP = GW3xWh:getFire()
				GW3xWh:startHistoryRecord(b5p2AMKP)
				if #eA_ohY == 2 then
					local m = eA_ohY[1]
					local Xve = eA_ohY[2]
					for Hk0hzj, Mfs in pairs(b5p2AMKP) do
						Mfs.Color = Color3.new(
							m == "r" and Xve or Mfs.Color.r,
							m == "g" and Xve or Mfs.Color.g,
							m == "b" and Xve or Mfs.Color.b
						)
					end
				elseif #eA_ohY == 3 then
					local JqnndWc, l5T8J5g1, RhLeG = ...
					for tOSI20, n in pairs(b5p2AMKP) do
						setp(n, "Color", Color3.new(JqnndWc, l5T8J5g1, RhLeG))
					end
				end
				GW3xWh:finishHistoryRecord()
			end
			Tools.Decorate.changeFireColor2 = function(mZcPQEV, ...)
				local O_oVTYL = {
					...,
				}
				local PGzKhtPH = mZcPQEV:getFire()
				mZcPQEV:startHistoryRecord(PGzKhtPH)
				if #O_oVTYL == 2 then
					local wI3DS0Kh = O_oVTYL[1]
					local CwTDNbR = O_oVTYL[2]
					for A, JfSij6_ in pairs(PGzKhtPH) do
						JfSij6_.SecondaryColor = Color3.new(
							wI3DS0Kh == "r" and CwTDNbR or JfSij6_.Color.r,
							wI3DS0Kh == "g" and CwTDNbR or JfSij6_.Color.g,
							wI3DS0Kh == "b" and CwTDNbR or JfSij6_.Color.b
						)
					end
				elseif #O_oVTYL == 3 then
					local Lr, NXu695, lzWnF = ...
					for sNe6_x, fBLoB6JH in pairs(PGzKhtPH) do
						fBLoB6JH.SecondaryColor = Color3.new(Lr, NXu695, lzWnF)
					end
				end
				mZcPQEV:finishHistoryRecord()
			end
			Tools.Decorate.changeSparklesColor = function(z6gv, ...)
				local ZZ93rHc0 = {
					...,
				}
				local j_V = z6gv:getSparkles()
				z6gv:startHistoryRecord(j_V)
				if #ZZ93rHc0 == 2 then
					local I_ = ZZ93rHc0[1]
					local yPn = ZZ93rHc0[2]
					for LsT, E in pairs(j_V) do
						E.SparkleColor = Color3.new(
							I_ == "r" and yPn or E.SparkleColor.r,
							I_ == "g" and yPn or E.SparkleColor.g,
							I_ == "b" and yPn or E.SparkleColor.b
						)
					end
				elseif #ZZ93rHc0 == 3 then
					local dOD2G, jhOfPSgm, eri = ...
					for uaTR, JDs76MG in pairs(j_V) do
						JDs76MG.SparkleColor = Color3.new(dOD2G, jhOfPSgm, eri)
					end
				end
				z6gv:finishHistoryRecord()
			end
			Tools.Decorate.addSmoke = function(aDZVav)
				local sRoTvf = {
					apply = function(aDZVav)
						Selection:clear()
						for cUR, p in pairs(aDZVav.smoke) do
							setp(p, "Parent", aDZVav.smoke_parents[p])
							Selection:add(p.Parent)
						end
					end,
					unapply = function(aDZVav)
						Selection:clear()
						for kKdY4XaA, d in pairs(aDZVav.smoke) do
							Selection:add(d.Parent)
							setp(d, "Parent", nil)
						end
					end,
				}
				local R1TLssk = {}
				local H = {}
				for sPM6lF, Qp_1 in pairs(Selection.Items) do
					local q1YAR = Support.GetChildOfClass(Qp_1, "Smoke")
					if not q1YAR then
						local q1YAR = (RbxUtility.Create("Smoke"))({
							Parent = Qp_1,
						})
						table.insert(R1TLssk, q1YAR)
						H[q1YAR] = Qp_1
					end
				end
				sRoTvf.smoke = R1TLssk
				sRoTvf.smoke_parents = H
				History:add(sRoTvf)
			end
			Tools.Decorate.removeSmoke = function(kg)
				local bijI = {
					apply = function(kg)
						Selection:clear()
						for NhucT, SZMbpM in pairs(kg.smoke) do
							Selection:add(SZMbpM.Parent)
							setp(SZMbpM, "Parent", nil)
						end
					end,
					unapply = function(kg)
						Selection:clear()
						for aTkVS, eBp38EEt in pairs(kg.smoke) do
							setp(eBp38EEt, "Parent", kg.smoke_parents[eBp38EEt])
							Selection:add(eBp38EEt.Parent)
						end
					end,
				}
				local K = kg:getSmoke()
				local lCr41We = {}
				for U8NHKEk, yf0 in pairs(K) do
					lCr41We[yf0] = yf0.Parent
					setp(yf0, "Parent", nil)
				end
				bijI.smoke = K
				bijI.smoke_parents = lCr41We
				History:add(bijI)
			end
			Tools.Decorate.addFire = function(skphQH)
				local ioxmHxH = {
					apply = function(skphQH)
						Selection:clear()
						for e09Nk, ifI_m2 in pairs(skphQH.fire) do
							setp(ifI_m2, "Parent", skphQH.fire_parents[ifI_m2])
							Selection:add(ifI_m2.Parent)
						end
					end,
					unapply = function(skphQH)
						Selection:clear()
						for QSX2, L1dTNDQb in pairs(skphQH.fire) do
							Selection:add(L1dTNDQb.Parent)
							setp(L1dTNDQb, "Parent", nil)
						end
					end,
				}
				local YGhYv64 = {}
				local i = {}
				for eMzb, J0KiSt in pairs(Selection.Items) do
					local pXdVoc = Support.GetChildOfClass(J0KiSt, "Fire")
					if not pXdVoc then
						local pXdVoc = (RbxUtility.Create("Fire"))({
							Parent = J0KiSt,
						})
						table.insert(YGhYv64, pXdVoc)
						i[pXdVoc] = J0KiSt
					end
				end
				ioxmHxH.fire = YGhYv64
				ioxmHxH.fire_parents = i
				History:add(ioxmHxH)
			end
			Tools.Decorate.removeFire = function(xme)
				local kAbF = {
					apply = function(xme)
						Selection:clear()
						for sqZtSeO, K4W6 in pairs(xme.fire) do
							Selection:add(K4W6.Parent)
							setp(K4W6, "Parent", nil)
						end
					end,
					unapply = function(xme)
						Selection:clear()
						for R4qp7, _F71WhJ in pairs(xme.fire) do
							setp(_F71WhJ, "Parent", xme.fire_parents[_F71WhJ])
							Selection:add(_F71WhJ.Parent)
						end
					end,
				}
				local h = xme:getFire()
				local GtezA0 = {}
				for YciJj, CZ2Wt in pairs(h) do
					GtezA0[CZ2Wt] = CZ2Wt.Parent
					setp(CZ2Wt, "Parent", nil)
				end
				kAbF.fire = h
				kAbF.fire_parents = GtezA0
				History:add(kAbF)
			end
			Tools.Decorate.addSparkles = function(rp3QaP)
				local Anqa = {
					apply = function(rp3QaP)
						Selection:clear()
						for C, wM4R in pairs(rp3QaP.sparkles) do
							setp(wM4R, "Parent", rp3QaP.sparkles_parents[wM4R])
							Selection:add(wM4R.Parent)
						end
					end,
					unapply = function(rp3QaP)
						Selection:clear()
						for sHOVr, v4D in pairs(rp3QaP.sparkles) do
							Selection:add(v4D.Parent)
							setp(v4D, "Parent", nil)
						end
					end,
				}
				local sDak1ecL = {}
				local r = {}
				for KBI_GdWx, XcV in pairs(Selection.Items) do
					local yq_h4JT = Support.GetChildOfClass(XcV, "Sparkles")
					if not yq_h4JT then
						local yq_h4JT = (RbxUtility.Create("Sparkles"))({
							Parent = XcV,
							SparkleColor = Color3.new(1, 0, 0),
						})
						table.insert(sDak1ecL, yq_h4JT)
						r[yq_h4JT] = XcV
					end
				end
				Anqa.sparkles = sDak1ecL
				Anqa.sparkles_parents = r
				History:add(Anqa)
			end
			Tools.Decorate.removeSparkles = function(Dde)
				local RIc = {
					apply = function(Dde)
						Selection:clear()
						for _neQ47D, scY in pairs(Dde.sparkles) do
							Selection:add(scY.Parent)
							setp(scY, "Parent", nil)
						end
					end,
					unapply = function(Dde)
						Selection:clear()
						for H42, JLx in pairs(Dde.sparkles) do
							setp(JLx, "Parent", Dde.sparkles_parents[JLx])
							Selection:add(JLx.Parent)
						end
					end,
				}
				local WL7T8_G = Dde:getSparkles()
				local DN = {}
				for vDPis1Y, pEV in pairs(WL7T8_G) do
					DN[pEV] = pEV.Parent
					setp(pEV, "Parent", nil)
				end
				RIc.sparkles = WL7T8_G
				RIc.sparkles_parents = DN
				History:add(RIc)
			end
			Tools.Decorate.startHistoryRecord = function(v1pCX6, NK)
				if v1pCX6.State.HistoryRecord then
					v1pCX6.State.HistoryRecord = nil
				end
				v1pCX6.State.HistoryRecord = {
					targets = Support.CloneTable(NK),
					initial_color = {},
					terminal_color = {},
					initial_2nd_color = {},
					terminal_2nd_color = {},
					initial_opacity = {},
					terminal_opacity = {},
					initial_velocity = {},
					terminal_velocity = {},
					initial_size = {},
					terminal_size = {},
					initial_heat = {},
					terminal_heat = {},
					unapply = function(v1pCX6)
						Selection:clear()
						for KNYh, STO_Hubw in pairs(v1pCX6.targets) do
							if STO_Hubw then
								Selection:add(STO_Hubw.Parent)
								if STO_Hubw:IsA("Sparkles") then
									STO_Hubw.SparkleColor = v1pCX6.initial_color[STO_Hubw]
								else
									setp(STO_Hubw, "Color", v1pCX6.initial_color[STO_Hubw])
									setp(STO_Hubw, "Size", v1pCX6.initial_size[STO_Hubw])
								end
								if STO_Hubw:IsA("Smoke") then
									STO_Hubw.Opacity = v1pCX6.initial_opacity[STO_Hubw]
									STO_Hubw.RiseVelocity = v1pCX6.initial_velocity[STO_Hubw]
								end
								if STO_Hubw:IsA("Fire") then
									STO_Hubw.SecondaryColor = v1pCX6.initial_2nd_color[STO_Hubw]
									STO_Hubw.Heat = v1pCX6.initial_heat[STO_Hubw]
								end
							end
						end
					end,
					apply = function(v1pCX6)
						Selection:clear()
						for S4jSoR, w in pairs(v1pCX6.targets) do
							if w then
								Selection:add(w.Parent)
								if w:IsA("Sparkles") then
									w.SparkleColor = v1pCX6.terminal_color[w]
								else
									setp(w, "Color", v1pCX6.terminal_color[w])
									setp(w, "Size", v1pCX6.terminal_size[w])
								end
								if w:IsA("Smoke") then
									w.Opacity = v1pCX6.terminal_opacity[w]
									w.RiseVelocity = v1pCX6.terminal_velocity[w]
								end
								if w:IsA("Fire") then
									w.SecondaryColor = v1pCX6.terminal_2nd_color[w]
									w.Heat = v1pCX6.terminal_heat[w]
								end
							end
						end
					end,
				}
				for yX3j, bOwWOjQH in pairs(v1pCX6.State.HistoryRecord.targets) do
					if bOwWOjQH then
						if bOwWOjQH:IsA("Sparkles") then
							v1pCX6.State.HistoryRecord.initial_color[bOwWOjQH] = bOwWOjQH.SparkleColor
						else
							v1pCX6.State.HistoryRecord.initial_color[bOwWOjQH] = bOwWOjQH.Color
							v1pCX6.State.HistoryRecord.initial_size[bOwWOjQH] = bOwWOjQH.Size
						end
						if bOwWOjQH:IsA("Smoke") then
							v1pCX6.State.HistoryRecord.initial_opacity[bOwWOjQH] = bOwWOjQH.Opacity
							v1pCX6.State.HistoryRecord.initial_velocity[bOwWOjQH] = bOwWOjQH.RiseVelocity
						end
						if bOwWOjQH:IsA("Fire") then
							v1pCX6.State.HistoryRecord.initial_2nd_color[bOwWOjQH] = bOwWOjQH.SecondaryColor
							v1pCX6.State.HistoryRecord.initial_heat[bOwWOjQH] = bOwWOjQH.Heat
						end
					end
				end
			end
			Tools.Decorate.finishHistoryRecord = function(d)
				if not d.State.HistoryRecord then
					return
				end
				for pM6sO5R0, TF4nyv in pairs(d.State.HistoryRecord.targets) do
					if TF4nyv then
						if TF4nyv:IsA("Sparkles") then
							d.State.HistoryRecord.terminal_color[TF4nyv] = TF4nyv.SparkleColor
						else
							d.State.HistoryRecord.terminal_color[TF4nyv] = TF4nyv.Color
							d.State.HistoryRecord.terminal_size[TF4nyv] = TF4nyv.Size
						end
						if TF4nyv:IsA("Smoke") then
							d.State.HistoryRecord.terminal_opacity[TF4nyv] = TF4nyv.Opacity
							d.State.HistoryRecord.terminal_velocity[TF4nyv] = TF4nyv.RiseVelocity
						end
						if TF4nyv:IsA("Fire") then
							d.State.HistoryRecord.terminal_2nd_color[TF4nyv] = TF4nyv.SecondaryColor
							d.State.HistoryRecord.terminal_heat[TF4nyv] = TF4nyv.Heat
						end
					end
				end
				History:add(d.State.HistoryRecord)
				d.State.HistoryRecord = nil
			end
			Tools.Decorate.hideGUI = function(lilD_Ll)
				if lilD_Ll.GUI then
					setp(lilD_Ll.GUI, "Visible", false)
				end
			end
			Tools.Decorate.Loaded = true
		end,
	},
}
if not _G.BTCoreEnv then
	_G.BTCoreEnv = {}
end
_G.BTCoreEnv.tool = getfenv(0)
CoreReady = true
ToolLoadErrors = {}
for Q2jN, Y1v09ha in ipairs(q) do
	local toolName = Y1v09ha[1]
	local ok, err = xpcall(Y1v09ha[2], F3XTraceback)
	if not ok then
		ToolLoadErrors[toolName] = err
		F3XWarn("Tool module failed while loading " .. tostring(toolName) .. ": " .. tostring(err))
		Tools[toolName] = Tools[toolName] or {
			Color = BrickColor.new("Really black"),
			Listeners = {},
			State = {},
			Connections = {},
			Loaded = true,
			LoadFailed = true,
			LoadError = err,
		}
	end
end
local toolLoadDeadline = tick() + 8
for XWU, t in ipairs(q) do
	local toolName = t[1]
	while not Tools[toolName] and tick() < toolLoadDeadline do
		task.wait()
	end
	if not Tools[toolName] then
		local err = "tool table was not created before timeout"
		ToolLoadErrors[toolName] = err
		F3XWarn("Tool module failed while loading " .. tostring(toolName) .. ": " .. err)
		Tools[toolName] = {
			Color = BrickColor.new("Really black"),
			Listeners = {},
			State = {},
			Connections = {},
			Loaded = true,
			LoadFailed = true,
			LoadError = err,
		}
	end
	while Tools[toolName] and not Tools[toolName].Loaded and tick() < toolLoadDeadline do
		task.wait()
	end
	if Tools[toolName] and not Tools[toolName].Loaded then
		local err = "tool did not set Loaded before timeout"
		ToolLoadErrors[toolName] = err
		F3XWarn("Tool module failed while loading " .. tostring(toolName) .. ": " .. err)
		Tools[toolName].Loaded = true
		Tools[toolName].LoadFailed = true
		Tools[toolName].LoadError = err
	end
end
if next(ToolLoadErrors) then
	F3XWarn("F3X loaded with tool errors. Inspect _G.BTCoreEnv.tool.ToolLoadErrors.")
end
if ToolType == "plugin" then
	local i = false
	ToolbarButton.Click:Connect(function()
		if i then
			i = false
			unequipBT()
		else
			i = true
			plugin:Activate(true)
			equipBT(plugin:GetMouse())
		end
	end)
	plugin.Deactivation:Connect(unequipBT)
elseif ToolType == "tool" then
	Tool.Equipped:Connect(equipBT)
	Tool.Unequipped:Connect(unequipBT)
end
RefreshHttpAvailabilityAsync()
RefreshVersionStatusAsync()
