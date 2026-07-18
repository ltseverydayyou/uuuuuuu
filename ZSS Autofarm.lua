local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Remote = ReplicatedStorage:WaitForChild("Remote")
local NotificationEvent = ReplicatedStorage:FindFirstChild("Notifications") and ReplicatedStorage.Notifications:FindFirstChild("yes")
local StatHolder = require(ReplicatedStorage:WaitForChild("StatHolder"))
local ProductValidate = nil
for _, object in ipairs(getgc(true)) do
	if type(object) == "function" then
		local ok, name = pcall(debug.info, object, "n")
		if ok and name == "ValidatePosition" and debug.info(object, "s") == "ReplicatedStorage.ProductHandler" then
			ProductValidate = object
			break
		end
	end
end

local previous = getgenv().ZSSHub or getgenv().ZSSAutomation
if previous then
	previous.Enabled = false
	if previous.Connections then
		for _, connection in pairs(previous.Connections) do
			pcall(function()
				connection:Disconnect()
			end)
		end
	end
	if previous.Window then
		pcall(function()
			previous.Window:Destroy()
		end)
	end
end

local Hub = {
	Enabled = true,
	Paused = false,
	Interval = 0.3,
	AutoStationUpgrades = true,
	CheapestPurchases = true,
	ExpansionPriority = true,
	MinimumStationReserve = 100,
	BillReserveMultiplier = 2,
	BillExtraBuffer = 25,
	UpgradeSpendCap = 500,
	UpgradeCheckInterval = 5,
	NextUpgradeCheck = 0,
	UpgradeReadyAt = 0,
	AutoBuyFuel = true,
	AutoBuyProducts = true,
	AutoRestock = true,
	AutoClean = true,
	AutoCashier = true,
	AutoRefuel = true,
	AutoCarWash = true,
	AutoWindshield = true,
	AutoScrap = true,
	AutoRetire = true,
	AutoStamina = true,
	AutoRepair = true,
	AutoMechanic = true,
	AutoMechanicStock = true,
	FuelThreshold = 0.15,
	ProductMinimum = 0,
	MechanicMinimum = 3,
	RestLow = 0.5,
	RestHigh = 0.85,
	Status = "Starting",
	TaskCursor = 0,
	ChecksPerTick = 1,
	NextPurchaseCheck = 0,
	RetirePending = false,
	RetireAttemptAt = 0,
	RetireRetryAt = 0,
	Prompting = false,
	Resting = false,
	PendingStack = nil,
	PendingScrap = nil,
	LastStackKey = nil,
	LastPurchaseAt = 0,
	PurchaseReadyAt = 0,
	FuelRequests = {},
	Cooldowns = {},
	BadStacks = {},
	Connections = {},
	Stats = {
		FuelLiters = 0,
		ProductsBought = 0,
		MechanicPartsBought = 0,
		Restocked = 0,
		Cleaned = 0,
		Scanned = 0,
		CarsRefueled = 0,
		CarWashSides = 0,
		WindshieldsCleaned = 0,
		ScrapsCollected = 0,
		Retirements = 0,
		MachinesRepaired = 0,
		MechanicSteps = 0,
		Rests = 0,
		EnergyBoosts = 0,
		InvalidPositions = 0,
		Purchases = 0,
		StationUpgrades = 0,
		SettingsSaves = 0,
	},
}

getgenv().ZSSHub = Hub
getgenv().ZSSAutomation = Hub

local SettingsFile = "ZSS_Automation_Settings.json"
local SavedSettingKeys = {
	"Interval", "AutoStationUpgrades", "CheapestPurchases", "ExpansionPriority",
	"MinimumStationReserve", "BillReserveMultiplier", "BillExtraBuffer", "UpgradeSpendCap",
	"AutoBuyFuel", "AutoBuyProducts", "AutoRestock", "AutoClean", "AutoCashier",
	"AutoRefuel", "AutoCarWash", "AutoWindshield", "AutoScrap", "AutoRetire",
	"AutoStamina", "AutoRepair", "AutoMechanic", "AutoMechanicStock",
	"FuelThreshold", "ProductMinimum", "MechanicMinimum", "RestLow", "RestHigh",
}
local SavedSettingLookup = {}
for _, key in ipairs(SavedSettingKeys) do SavedSettingLookup[key] = true end

local function collectSettings()
	local data = { Version = 1 }
	for _, key in ipairs(SavedSettingKeys) do data[key] = Hub[key] end
	return data
end

local function saveSettings()
	if type(writefile) ~= "function" then return false end
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, collectSettings())
	if not ok then return false end
	local wrote = pcall(writefile, SettingsFile, encoded)
	if wrote then Hub.Stats.SettingsSaves = (Hub.Stats.SettingsSaves or 0) + 1 end
	return wrote
end

local function loadSettings()
	if type(isfile) ~= "function" or type(readfile) ~= "function" or not isfile(SettingsFile) then return false end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, readfile(SettingsFile))
	if not ok or type(decoded) ~= "table" then return false end
	for key, value in pairs(decoded) do
		if SavedSettingLookup[key] and type(value) == type(Hub[key]) then Hub[key] = value end
	end
	Hub.Interval = math.clamp(tonumber(Hub.Interval) or 0.3, 0.05, 0.5)
	Hub.RestLow = math.clamp(tonumber(Hub.RestLow) or 0.5, 0.1, 0.9)
	Hub.RestHigh = math.clamp(tonumber(Hub.RestHigh) or 0.85, 0.2, 1)
	return true
end

loadSettings()
saveSettings()
Hub.SaveSettings = saveSettings
Hub.LoadSettings = loadSettings
local lastSettingsSignature = HttpService:JSONEncode(collectSettings())
task.spawn(function()
	while Hub.Enabled do
		task.wait(1)
		local signature = HttpService:JSONEncode(collectSettings())
		if signature ~= lastSettingsSignature then
			lastSettingsSignature = signature
			saveSettings()
		end
	end
end)


local function now()
	return os.clock()
end

local function setStatus(text)
	Hub.Status = text
end

local function cooldownReady(key)
	return (Hub.Cooldowns[key] or 0) <= now()
end

local function setCooldown(key, duration)
	Hub.Cooldowns[key] = now() + duration
end

local function getCharacter()
	return LocalPlayer.Character
end

local function getHumanoid()
	local character = getCharacter()
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function characterBusy()
	local character = getCharacter()
	local humanoid = getHumanoid()
	if not character or not humanoid or humanoid.Health <= 0 then
		return true
	end
	local action = character:GetAttribute("PlayerAction")
	if action and action ~= "" then
		return true
	end
	if LocalPlayer:GetAttribute("PerformingService") then
		return true
	end
	if Hub.Prompting then
		return true
	end
	return false
end

local function effectiveMaxStamina()
	local base = LocalPlayer:GetAttribute("MaxStamina") or 100
	local ok, value = pcall(function()
		return StatHolder.GetAccessoryBonus(LocalPlayer, "Energy", base)
	end)
	if ok and type(value) == "number" then
		return math.max(base, value)
	end
	return base
end

local function staminaRatio()
	local current = LocalPlayer:GetAttribute("Stamina") or 0
	local maximum = effectiveMaxStamina()
	if maximum <= 0 then
		return 1
	end
	return math.clamp(current / maximum, 0, 1)
end

Hub.FundReservations = Hub.FundReservations or {}
Hub.Stats.FundsSkipped = Hub.Stats.FundsSkipped or 0
Hub.LastFundingIssue = Hub.LastFundingIssue or nil

local function managerPresent()
	local teams = game:FindFirstChild("Teams")
	local managers = teams and teams:FindFirstChild("Manager")
	return managers and #managers:GetPlayers() > 0 or false
end

local function preferredFundingSource()
	return managerPresent() and "Client" or "Station"
end

local function rawFunds(source)
	if source == "Client" then
		return tonumber(LocalPlayer:GetAttribute("Money")) or 0
	end
	local station = workspace:FindFirstChild("Station")
	return tonumber(station and station:GetAttribute("Money")) or 0
end

local function clearFundReservations()
	local currentTime = now()
	for index = #Hub.FundReservations, 1, -1 do
		local reservation = Hub.FundReservations[index]
		if not reservation or currentTime >= reservation.Expires then
			table.remove(Hub.FundReservations, index)
		end
	end
end

local function reservedFunds(source)
	clearFundReservations()
	local total = 0
	for _, reservation in ipairs(Hub.FundReservations) do
		if reservation.Source == source then
			total = total + reservation.Amount
		end
	end
	return total
end

local function isStationOwner()
	local ownerId = workspace:GetAttribute("Owner")
	return type(ownerId) == "number" and ownerId ~= 0 and LocalPlayer.UserId == ownerId
end

local function contributionFunds()
	if managerPresent() or isStationOwner() then
		return math.huge
	end
	local attributeValue = tonumber(LocalPlayer:GetAttribute("Contributions")) or 0
	local contributions = StatHolder.Contributions
	local syncedValue = tonumber(contributions and contributions[LocalPlayer]) or 0
	return math.max(attributeValue, syncedValue)
end

local function estimatedBills()
	local station = workspace:FindFirstChild("Station")
	return math.max(0, tonumber(station and station:GetAttribute("EstBills")) or 0)
end

local function stationReserve()
	return math.max(
		math.max(0, tonumber(Hub.MinimumStationReserve) or 0),
		estimatedBills() * math.max(1, tonumber(Hub.BillReserveMultiplier) or 1) + math.max(0, tonumber(Hub.BillExtraBuffer) or 0)
	)
end
Hub.GetStationReserve = stationReserve

local function availableFunds(source)
	local reservations = reservedFunds(source)
	local available = math.max(0, rawFunds(source) - reservations)
	if source == "Station" then
		available = math.max(0, available - stationReserve())
		if not managerPresent() and not isStationOwner() then
			available = math.min(available, math.max(0, contributionFunds() - reservations))
		end
	end
	return available
end

local function markFundingWait(source, available, required)
	local currentTime = now()
	local previous = Hub.LastFundingIssue
	if not previous or previous.Source ~= source or math.abs(previous.Required - required) > 0.01 or currentTime - previous.Time >= 3 then
		Hub.Stats.FundsSkipped = Hub.Stats.FundsSkipped + 1
	end
	Hub.LastFundingIssue = {
		Source = source,
		Available = available,
		Required = required,
		Time = currentTime,
	}
	Hub.PurchaseReadyAt = math.max(Hub.PurchaseReadyAt or 0, currentTime + 3)
	setStatus(string.format("Waiting for %s funds: $%.2f / $%.2f", source == "Client" and "wallet" or "station", available, required))
end

local function fundingSource(price)
	local required = math.max(0, tonumber(price) or 0)
	local source
	if now() < (Hub.ForceClientFundingUntil or 0) then
		source = "Client"
	else
		source = preferredFundingSource()
	end
	local available = availableFunds(source)
	if available + 0.001 >= required then
		return source, source, available
	end
	if source == "Station" then
		local walletAvailable = availableFunds("Client")
		if walletAvailable + 0.001 >= required then
			Hub.Stats.FundingFallbacks = (Hub.Stats.FundingFallbacks or 0) + 1
			Hub.LastFundingFallback = {
				Reason = contributionFunds() + 0.001 < required and "Contribution" or "StationFunds",
				Station = rawFunds("Station"),
				Contribution = contributionFunds(),
				Required = required,
				Time = now(),
			}
			return "Client", "Client", walletAvailable
		end
	end
	return nil, source, available
end

local function reserveFunds(source, amount, duration)
	table.insert(Hub.FundReservations, {
		Source = source,
		Amount = amount,
		Expires = now() + math.max(2, duration or 2),
	})
end

local function promptCFrame(prompt)
	local parent = prompt and prompt.Parent
	if not parent then
		return nil
	end
	if parent:IsA("Attachment") then
		return parent.WorldCFrame
	end
	if parent:IsA("BasePart") then
		return parent.CFrame
	end
	if parent:IsA("Model") then
		return parent:GetPivot()
	end
	local ancestorPart = parent:FindFirstAncestorWhichIsA("BasePart")
	if ancestorPart then
		return ancestorPart.CFrame
	end
	local ancestorModel = parent:FindFirstAncestorWhichIsA("Model")
	if ancestorModel then
		return ancestorModel:GetPivot()
	end
	return nil
end

local function moveAndPrompt(prompt, status)
	if not prompt or not prompt.Parent or not prompt.Enabled or Hub.Prompting then
		return false
	end
	Hub.Prompting = true
	setStatus(status or ("Prompt: " .. prompt.ActionText))
	task.spawn(function()
		local character = getCharacter()
		local cf = promptCFrame(prompt)
		if character and cf then
			pcall(function()
				character:PivotTo(cf * CFrame.new(0, 2.5, 0))
			end)
			task.wait(0.08)
		end
		pcall(function()
			fireproximityprompt(prompt, 0)
		end)
		task.wait(0.22)
		Hub.Prompting = false
	end)
	return true
end

local ProductShopMap = {}
for shopName, categories in pairs(StatHolder.Shops or {}) do
	if type(categories) == "table" and shopName ~= "Syntin Petrol Co" and shopName ~= "Zal's Auto Parts" then
		for categoryName, items in pairs(categories) do
			if type(items) == "table" then
				for itemName, data in pairs(items) do
					if type(itemName) == "string" and type(data) == "table" then
						ProductShopMap[itemName] = {
							Shop = shopName,
							Category = categoryName,
							Data = data,
						}
					end
				end
			end
		end
	end
end

local MechanicCategory = {
	["Door (Left)"] = "Exterior / Cosmetical",
	["Door (Right)"] = "Exterior / Cosmetical",
	["Mirror (Left)"] = "Exterior / Cosmetical",
	["Mirror (Right)"] = "Exterior / Cosmetical",
	["Wheel"] = "Exterior / Cosmetical",
	["Brakedisk"] = "Technical / Wear & Tear",
}

local function purchaseCooldown(price)
	return math.max((tonumber(price) or 0) / 100, 1)
end

local function canPurchase()
	return now() >= Hub.PurchaseReadyAt
end

local function buyItem(shop, category, item, amountOrIndex, price, statName, statAmount)
	if not canPurchase() then
		return false
	end
	price = math.max(0, tonumber(price) or 0)
	local source, expectedSource, available = fundingSource(price)
	if not source then
		markFundingWait(expectedSource, available, price)
		return false
	end
	local cooldown = purchaseCooldown(price)
	Hub.PurchaseReadyAt = now() + cooldown
	Hub.LastPurchaseAt = now()
	reserveFunds(source, price, cooldown + 1)
	Remote:FireServer("BuyItem", shop, category, item, source, amountOrIndex)
	Hub.Stats.Purchases = Hub.Stats.Purchases + 1
	if statName and Hub.Stats[statName] ~= nil then
		Hub.Stats[statName] = Hub.Stats[statName] + (statAmount or 1)
	end
	setStatus("Buying: " .. tostring(item))
	return true
end
local function buyFuelStep()
	if not Hub.AutoBuyFuel then return false end
	local pumps = workspace:FindFirstChild("Pumps")
	local fuelShop = StatHolder.Shops and StatHolder.Shops["Syntin Petrol Co"]
	if not pumps or not fuelShop then return false end
	local source = preferredFundingSource()
	local budget = availableFunds(source)
	local candidates = {}
	local cheapestRequired = nil
	for _, fuelName in ipairs({ "Gasoline 87", "Gasoline 90" }) do
		local compact = fuelName:gsub("%s+", "")
		local current = pumps:GetAttribute(compact)
		local maximum = pumps:GetAttribute("Max" .. compact)
		local buying = pumps:GetAttribute("Buying_" .. compact)
		local requested = Hub.FuelRequests[compact]
		if type(current) == "number" and type(maximum) == "number" and maximum > 0 and not (type(buying) == "number" and buying > 0) and (requested or current / maximum <= Hub.FuelThreshold) then
			local missing = maximum - current
			for index, package in ipairs(fuelShop[fuelName] or {}) do
				local liters = tonumber(package[1]) or 0
				local price = tonumber(package[2]) or math.huge
				if liters > 0 and liters <= missing then
					cheapestRequired = math.min(cheapestRequired or price, price)
					if price <= budget + 0.001 then table.insert(candidates,{FuelName=fuelName,Compact=compact,Index=index,Liters=liters,Price=price}) end
				end
			end
		end
	end
	table.sort(candidates,function(a,b) if a.Price == b.Price then return a.Liters < b.Liters end return a.Price < b.Price end)
	local chosen = candidates[1]
	if chosen and buyItem("Syntin Petrol Co",chosen.FuelName,chosen.Index,1,chosen.Price,"FuelLiters",chosen.Liters) then Hub.FuelRequests[chosen.Compact] = nil return true end
	if cheapestRequired then markFundingWait(source,budget,cheapestRequired) end
	return false
end

local function rounded(value, increment)
	return math.floor(value / increment + 0.5) * increment
end

local function buildStackGroups()
	local shelves = workspace:FindFirstChild("Shelves")
	local storage = workspace:FindFirstChild("Storage")
	if not shelves or not storage then
		return {}
	end
	local columns = {}
	for _, shelf in ipairs(shelves:GetChildren()) do
		local content = shelf:FindFirstChild("Content")
		if content then
			for _, model in ipairs(content:GetChildren()) do
				local stock = storage:FindFirstChild(model.Name)
				local cur = model:GetAttribute("CurStack")
				local max = model:GetAttribute("MaxStack")
				if model:IsA("Model") and stock and type(cur) == "number" and type(max) == "number" and model:GetAttribute("CanStack") then
					local pivot = model:GetPivot()
					local position = pivot.Position
					local columnKey = model.Name .. ":" .. tostring(rounded(position.X, 0.05)) .. ":" .. tostring(rounded(position.Z, 0.05))
					columns[columnKey] = columns[columnKey] or {
						Name = model.Name,
						Stock = stock,
						Items = {},
						ColumnKey = columnKey,
					}
					table.insert(columns[columnKey].Items, model)
				end
			end
		end
	end
	local groups = {}
	for _, column in pairs(columns) do
		table.sort(column.Items, function(a, b)
			return a:GetPivot().Position.Y < b:GetPivot().Position.Y
		end)
		local cluster = nil
		local clusterIndex = 0
		local previousItem = nil
		for _, item in ipairs(column.Items) do
			local startNew = false
			if previousItem then
				local previousY = previousItem:GetPivot().Position.Y
				local currentY = item:GetPivot().Position.Y
				local _, previousSize = previousItem:GetBoundingBox()
				local _, currentSize = item:GetBoundingBox()
				local gapLimit = math.max(previousSize.Y, currentSize.Y) * 1.8 + 0.2
				local previousCur = previousItem:GetAttribute("CurStack") or 0
				local currentCur = item:GetAttribute("CurStack") or 0
				if currentY - previousY > gapLimit or currentCur <= previousCur then
					startNew = true
				end
			end
			if not cluster or startNew then
				clusterIndex = clusterIndex + 1
				cluster = {
					Name = column.Name,
					Stock = column.Stock,
					Items = {},
					Key = column.ColumnKey .. ":" .. tostring(clusterIndex),
				}
				table.insert(groups, cluster)
			end
			table.insert(cluster.Items, item)
			previousItem = item
		end
	end
	for _, group in ipairs(groups) do
		table.sort(group.Items, function(a, b)
			local ac = a:GetAttribute("CurStack") or 0
			local bc = b:GetAttribute("CurStack") or 0
			if ac == bc then
				return a:GetPivot().Position.Y < b:GetPivot().Position.Y
			end
			return ac < bc
		end)
		group.Top = group.Items[#group.Items]
		group.Previous = group.Items[#group.Items - 1]
	end
	return groups
end

local function demandedProducts()
	local demand = {}
	for _, group in ipairs(buildStackGroups()) do
		local top = group.Top
		if top and (top:GetAttribute("CurStack") or 0) < (top:GetAttribute("MaxStack") or 0) then
			demand[group.Name] = true
		end
	end
	return demand
end

local function buyProductStep()
	if not Hub.AutoBuyProducts then return false end
	local storage = workspace:FindFirstChild("Storage")
	if not storage then return false end
	local source = preferredFundingSource()
	local budget = availableFunds(source)
	local candidates = {}
	local cheapestRequired = nil
	for productName in pairs(demandedProducts()) do
		local stock = storage:FindFirstChild(productName)
		local mapping = ProductShopMap[productName]
		if stock and mapping then
			local current = stock:GetAttribute("Storage") or 0
			local maximum = stock:GetAttribute("MaxStorage") or current
			if current <= Hub.ProductMinimum and maximum > current then
				local unitPrice = tonumber(mapping.Data[2]) or 0
				local capacity = math.max(0,maximum-current)
				if capacity > 0 and unitPrice >= 0 then
					cheapestRequired = math.min(cheapestRequired or unitPrice,unitPrice)
					local affordable = unitPrice > 0 and math.floor((budget+0.001)/unitPrice) or capacity
					local amount = Hub.CheapestPurchases and math.min(1,capacity,affordable) or math.min(capacity,10,affordable)
					if amount >= 1 then table.insert(candidates,{Name=productName,Mapping=mapping,UnitPrice=unitPrice,Amount=amount}) end
				end
			end
		end
	end
	table.sort(candidates,function(a,b) if a.UnitPrice == b.UnitPrice then return a.Name < b.Name end return a.UnitPrice < b.UnitPrice end)
	local chosen=candidates[1]
	if chosen and buyItem(chosen.Mapping.Shop,chosen.Mapping.Category,chosen.Name,chosen.Amount,chosen.UnitPrice*chosen.Amount,"ProductsBought",chosen.Amount) then return true end
	if cheapestRequired then markFundingWait(source,budget,cheapestRequired) end
	return false
end

local function buyMechanicStockStep()
	if not Hub.AutoMechanicStock then return false end
	local storage=workspace:FindFirstChild("Storage")
	local shop=StatHolder.Shops and StatHolder.Shops["Zal's Auto Parts"]
	if not storage or not shop then return false end
	local source=preferredFundingSource()
	local budget=availableFunds(source)
	local candidates={}
	local cheapestRequired=nil
	for itemName,categoryName in pairs(MechanicCategory) do
		local stock=storage:FindFirstChild(itemName)
		local data=shop[categoryName] and shop[categoryName][itemName]
		if stock and data then
			local current=stock:GetAttribute("Storage") or 0
			local maximum=stock:GetAttribute("MaxStorage") or current
			if current <= Hub.MechanicMinimum and maximum > current then
				local unitPrice=tonumber(data[2]) or 0
				local capacity=math.max(0,maximum-current)
				cheapestRequired=math.min(cheapestRequired or unitPrice,unitPrice)
				local affordable=unitPrice > 0 and math.floor((budget+0.001)/unitPrice) or capacity
				local amount=Hub.CheapestPurchases and math.min(1,capacity,affordable) or math.min(capacity,10,affordable)
				if amount >= 1 then table.insert(candidates,{Name=itemName,Category=categoryName,UnitPrice=unitPrice,Amount=amount}) end
			end
		end
	end
	table.sort(candidates,function(a,b) if a.UnitPrice == b.UnitPrice then return a.Name < b.Name end return a.UnitPrice < b.UnitPrice end)
	local chosen=candidates[1]
	if chosen and buyItem("Zal's Auto Parts",chosen.Category,chosen.Name,chosen.Amount,chosen.UnitPrice*chosen.Amount,"MechanicPartsBought",chosen.Amount) then return true end
	if cheapestRequired then markFundingWait(source,budget,cheapestRequired) end
	return false
end

local UpgradePromptNames={BuyExpansion=true,BuyStorageExpansion=true,BuyShelf=true,BuyPump=true,BuyParkingSpot=true,BuySolarGenerator=true,BuySolarBattery=true,BuyFreezer=true,BuyFresh=true,BuySelfCheckout=true,BuyWasher=true,BuyCleaner=true,BuyBusStop=true,BuySecurityGate=true,UpgradePump=true,UpgradeCharger=true,AutoWindowCleaner=true,UpgradeFuelCapacity=true,BuyParkingMeter=true,BuyPressureWasher=true,BuyAutoWash=true,BuyUpgrade=true}

local function stationUpgradePrice(prompt)
	local price=tonumber((prompt.ActionText or ""):match("%$([%d%.]+)"))
	if price then return price end
	if prompt.Name == "BuyExpansion" then return 500 end
	if prompt.Name == "BuyStorageExpansion" then
		local storage=workspace:FindFirstChild("StorageSystem")
		local mirror=storage and storage:FindFirstChild("Mirror")
		local ui=mirror and mirror:FindFirstChild("MirrorUI")
		local label=ui and ui:FindFirstChild("Price")
		return label and tonumber((label.Text or ""):match("%$([%d%.]+)")) or nil
	end
	return nil
end

local function stationUpgradePrompts()
	local roots={workspace:FindFirstChild("Tycoon_BuyPlates"),workspace:FindFirstChild("Solar"),workspace:FindFirstChild("Pumps"),workspace:FindFirstChild("ElectricChargers"),workspace:FindFirstChild("FuelTanks"),workspace:FindFirstChild("Parking"),workspace:FindFirstChild("CarWash"),workspace:FindFirstChild("Windows"),workspace:FindFirstChild("StorageSystem"),workspace:FindFirstChild("StationUpgrade_1_Remove")}
	local out={}
	for _,root in ipairs(roots) do
		if root then
			for _,prompt in ipairs(root:GetDescendants()) do
				if prompt:IsA("ProximityPrompt") and prompt.Enabled and UpgradePromptNames[prompt.Name] and string.find(string.lower(prompt.ObjectText or ""),"station funds",1,true) then
					local price=stationUpgradePrice(prompt)
					if price then table.insert(out,{Prompt=prompt,Price=price}) end
				end
			end
		end
	end
	return out
end

local function stationUpgradeStep()
	if not Hub.AutoStationUpgrades or now() < (Hub.NextUpgradeCheck or 0) or now() < (Hub.UpgradeReadyAt or 0) or not workspace:GetAttribute("FinishedUpgrading") then return false end
	Hub.NextUpgradeCheck=now()+math.max(2,tonumber(Hub.UpgradeCheckInterval) or 5)
	local budget=availableFunds("Station")
	local candidates={}
	for _,candidate in ipairs(stationUpgradePrompts()) do
		if candidate.Price <= math.max(0,tonumber(Hub.UpgradeSpendCap) or 0) and candidate.Price <= budget+0.001 then
			local rank=3
			if Hub.ExpansionPriority and candidate.Prompt.Name=="BuyExpansion" then rank=1 elseif Hub.ExpansionPriority and candidate.Prompt.Name=="BuyStorageExpansion" then rank=2 end
			candidate.Rank=rank
			table.insert(candidates,candidate)
		end
	end
	table.sort(candidates,function(a,b) if a.Rank ~= b.Rank then return a.Rank < b.Rank end if a.Price ~= b.Price then return a.Price < b.Price end return a.Prompt:GetFullName() < b.Prompt:GetFullName() end)
	local chosen=candidates[1]
	if not chosen then return false end
	reserveFunds("Station",chosen.Price,5)
	Hub.UpgradeReadyAt=now()+math.max(5,chosen.Price/50)
	if moveAndPrompt(chosen.Prompt,"Buying station upgrade: "..chosen.Prompt.ActionText) then Hub.Stats.StationUpgrades=(Hub.Stats.StationUpgrades or 0)+1 return true end
	return false
end

local function purchaseStep()
	if now() < Hub.NextPurchaseCheck then
		return false
	end
	Hub.NextPurchaseCheck = now() + 0.5
	if not canPurchase() then
		return false
	end
	if buyFuelStep() then
		return true
	end
	if buyMechanicStockStep() then
		return true
	end
	if buyProductStep() then
		return true
	end
	return false
end

local function fireSilentRestock(productName, target)
	local muted = {}
	if NotificationEvent and getconnections then
		for _, connection in ipairs(getconnections(NotificationEvent.OnClientEvent)) do
			local ok, sourceName = pcall(function()
				return debug.info(connection.Function, "s")
			end)
			if ok and sourceName == "ReplicatedStorage.Notifications" and connection.Enabled then
				pcall(function() connection:Disable() end)
				table.insert(muted, connection)
			end
		end
	end
	Remote:FireServer("PlaceProduct", productName, target, true, 1)
	task.delay(0.8, function()
		for _, connection in ipairs(muted) do
			pcall(function() connection:Enable() end)
		end
	end)
end

local function resolvePendingStack()
	local pending = Hub.PendingStack
	if not pending then
		return
	end
	if now() - pending.Time < 1.2 then
		return
	end
	local stock = workspace.Storage:FindFirstChild(pending.Name)
	local current = stock and stock:GetAttribute("Storage") or pending.Storage
	if current < pending.Storage then
		Hub.Stats.Restocked = Hub.Stats.Restocked + 1
		Hub.BadStacks[pending.Key] = now() + 2
	else
		Hub.BadStacks[pending.Key] = now() + 60
	end
	Hub.PendingStack = nil
end

local function validatedStackTarget(group)
	if not ProductValidate then
		return nil
	end
	local top = group.Top
	if not top or not top.Parent then
		return nil
	end
	local assetFolder = ReplicatedStorage:FindFirstChild("Assets")
	local products = assetFolder and assetFolder:FindFirstChild("Products")
	local template = products and products:FindFirstChild(group.Name)
	if not template then
		return nil
	end
	local clone = template:Clone()
	clone.Parent = workspace
	if clone.PrimaryPart then
		clone.PrimaryPart.Anchored = true
		pcall(function() clone.PrimaryPart.CollisionGroup = "Characters" end)
	end
	local delta
	local previous = group.Previous
	local cur = top:GetAttribute("CurStack") or 0
	if previous and previous.Parent and (previous:GetAttribute("CurStack") or -1) == cur - 1 then
		delta = top:GetPivot().Position - previous:GetPivot().Position
	else
		local _, size = top:GetBoundingBox()
		delta = Vector3.new(0, size.Y, 0)
	end
	local target = nil
	for step = 0, 24 do
		local offset
		if step == 0 then
			offset = 0
		else
			local amount = math.ceil(step / 2) * 0.01
			offset = step % 2 == 1 and amount or -amount
		end
		local candidate = top:GetPivot() + delta + Vector3.new(0, offset, 0)
		clone:PivotTo(candidate)
		local ok, valid = pcall(ProductValidate, clone, getCharacter())
		if ok and valid then
			target = candidate
			break
		end
	end
	clone:Destroy()
	return target
end

local function restockStep()
	if not Hub.AutoRestock or Hub.PendingStack then
		return false
	end
	resolvePendingStack()
	if Hub.PendingStack then
		return false
	end
	for _, group in ipairs(buildStackGroups()) do
		local top = group.Top
		if top and top.Parent and (Hub.BadStacks[group.Key] or 0) <= now() then
			local cur = top:GetAttribute("CurStack") or 0
			local max = top:GetAttribute("MaxStack") or 0
			local stockAmount = group.Stock:GetAttribute("Storage") or 0
			if cur < max and stockAmount > 0 then
				local target = validatedStackTarget(group)
				if target then
					Hub.LastStackKey = group.Key
					Hub.PendingStack = {
						Key = group.Key,
						Name = group.Name,
						Storage = stockAmount,
						Time = now(),
					}
					setStatus("Restocking: " .. group.Name)
					fireSilentRestock(group.Name, target)
					return true
				end
				Hub.BadStacks[group.Key] = now() + 30
			end
		end
	end
	return false
end

local function cleanStep()
	if not Hub.AutoClean then
		return false
	end
	local character = getCharacter()
	if not character then
		return false
	end
	if character:GetAttribute("CarryingTrash") then
		for _, prompt in ipairs(workspace:GetDescendants()) do
			if prompt:IsA("ProximityPrompt") and prompt.Name == "ThrowTrashbag" and prompt.Enabled and cooldownReady(prompt) then
				setCooldown(prompt, 2)
				setStatus("Disposing trash")
				Remote:FireServer("ThrowTrashbag", prompt.Parent.Parent)
				Hub.Stats.Cleaned = Hub.Stats.Cleaned + 1
				return true
			end
		end
	end
	for _, prompt in ipairs(workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") and prompt.Enabled and cooldownReady(prompt) then
			if prompt.Name == "EmptyTrashbin" then
				setCooldown(prompt, 4)
				setStatus("Emptying trash")
				Remote:FireServer("EmptyTrashbin", prompt)
				Hub.Stats.Cleaned = Hub.Stats.Cleaned + 1
				return true
			end
		end
	end
	for _, prompt in ipairs(workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") and prompt.Name == "Clean" and prompt.Enabled and cooldownReady(prompt) then
			setCooldown(prompt, 4)
			setStatus("Cleaning: " .. (prompt.ObjectText ~= "" and prompt.ObjectText or prompt.Parent.Name))
			Remote:FireServer("Clean", prompt)
			Hub.Stats.Cleaned = Hub.Stats.Cleaned + 1
			return true
		end
	end
	return false
end

local function cashierStep()
	if not Hub.AutoCashier then
		return false
	end
	local checkouts = workspace:FindFirstChild("Checkouts")
	if not checkouts then
		return false
	end
	for _, register in ipairs(checkouts:GetChildren()) do
		local items = register:FindFirstChild("Items")
		if items and cooldownReady(register) then
			for _, item in ipairs(items:GetChildren()) do
				local root = item:FindFirstChild("Root")
				local scan = root and root:FindFirstChild("Scan")
				if scan and scan:IsA("ProximityPrompt") and scan.Enabled then
					setCooldown(register, 1)
					setStatus("Cashier: " .. item.Name)
					Remote:FireServer("ScanItem", item, register)
					Hub.Stats.Scanned = Hub.Stats.Scanned + 1
					return true
				end
			end
		end
	end
	return false
end

local function refuelStep()
	if not Hub.AutoRefuel then
		return false
	end
	for _, prompt in ipairs(workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Name == "FinishFuel" then
			local car = prompt:FindFirstAncestorOfClass("Model")
			local root = car and car:FindFirstChild("Root")
			local pumpValue = root and root:FindFirstChild("Pump")
			local pump = pumpValue and pumpValue.Value
			if car and pump and cooldownReady(car) then
				setCooldown(car, 3)
				setStatus("Finishing refuel: " .. car.Name)
				Remote:FireServer("FinishFuel", car, pump)
				Hub.Stats.CarsRefueled = Hub.Stats.CarsRefueled + 1
				return true
			end
		end
	end
	for _, prompt in ipairs(workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Name == "Refuel" then
			local car = prompt:FindFirstAncestorOfClass("Model")
			local root = car and car:FindFirstChild("Root")
			local pumpValue = root and root:FindFirstChild("Pump")
			local pump = pumpValue and pumpValue.Value
			if car and pump and not pump:GetAttribute("Broken") and cooldownReady(car) then
				local fuelType = pump:GetAttribute("Type")
				local required = car:GetAttribute("RequiredFuel") or 0
				local available = fuelType and workspace.Pumps:GetAttribute(fuelType) or 0
				if type(available) == "number" and available < required then
					Hub.FuelRequests[fuelType or "Gasoline87"] = true
					setStatus("Buying fuel for: " .. car.Name)
					return false
				end
				setCooldown(car, 15)
				setStatus("Refueling: " .. car.Name)
				Remote:FireServer("FuelCustomer", car, pump)
				return true
			end
		end
	end
	return false
end

local function carWashStep()
	if not Hub.AutoCarWash then
		return false
	end
	for _, prompt in ipairs(workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Name == "Wash" then
			local car = prompt:FindFirstAncestorOfClass("Model")
			local root = car and car:FindFirstChild("Root")
			local washValue = root and root:FindFirstChild("Wash")
			local wash = washValue and washValue.Value
			local sideName = prompt.Parent and prompt.Parent.Name or ""
			local side = sideName:match("^CleanSide_(.+)$")
			local dirt = side and car and car:FindFirstChild("Dirt_" .. side)
			if car and wash and dirt and dirt.Transparency < 0.99 and not dirt:GetAttribute("IsWashing") and cooldownReady(dirt) then
				setCooldown(dirt, 10)
				setStatus("Car wash: " .. side)
				Remote:FireServer("Wash", car, wash, dirt)
				Hub.Stats.CarWashSides = Hub.Stats.CarWashSides + 1
				return true
			end
		end
	end
	return false
end

local function windshieldStep()
	if not Hub.AutoWindshield then
		return false
	end
	local character = getCharacter()
	if not character then
		return false
	end
	for _, prompt in ipairs(workspace:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Name == "CleanWindshield" and cooldownReady(prompt) then
			if not character:GetAttribute("GotWindshieldCleaningKit") then
				setCooldown("cleaning-kit", 2)
				setStatus("Equipping windshield kit")
				Remote:FireServer("CleaningKit", "Equip", true)
				return true
			end
			local car = prompt:FindFirstAncestorOfClass("Model")
			if car then
				setCooldown(prompt, 10)
				setStatus("Cleaning windshield: " .. car.Name)
				Remote:FireServer("CleaningKit", "Clean", car)
				Hub.Stats.WindshieldsCleaned = Hub.Stats.WindshieldsCleaned + 1
				return true
			end
		end
	end
	return false
end

local function resolvePendingScrap()
	local pending = Hub.PendingScrap
	if not pending or now() - pending.Time < 0.6 then
		return
	end
	local character = getCharacter()
	local amount = character and (character:GetAttribute("CarryingTrash_Amount") or 0) or 0
	if not pending.Prompt.Parent or amount > pending.Amount then
		Hub.Stats.ScrapsCollected = Hub.Stats.ScrapsCollected + 1
	else
		setCooldown(pending.Prompt, 5)
	end
	Hub.PendingScrap = nil
end

local function scrapStep()
	if not Hub.AutoScrap or Hub.PendingScrap then
		return false
	end
	local character = getCharacter()
	local scraps = workspace:FindFirstChild("BrokenCarParts")
	if not character or not scraps or character:GetAttribute("CarryingTrash") then
		return false
	end
	for _, prompt in ipairs(scraps:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.ActionText == "Grab Scrap" and cooldownReady(prompt) then
			Hub.PendingScrap = {
				Prompt = prompt,
				Amount = character:GetAttribute("CarryingTrash_Amount") or 0,
				Time = now(),
			}
			setCooldown(prompt, 1)
			if moveAndPrompt(prompt, "Collecting mechanic scrap") then
				return true
			end
			Hub.PendingScrap = nil
		end
	end
	return false
end

local function eligibleForRetirement()
	local stats = StatHolder.PlayerStats and StatHolder.PlayerStats[LocalPlayer]
	if not stats or not stats.Jobs then
		return false
	end
	for jobName in pairs(stats.Jobs) do
		local ok, level = pcall(function()
			return StatHolder.GetLevel(LocalPlayer, jobName)[1]
		end)
		if ok and type(level) == "number" and level >= 20 then
			return true
		end
	end
	return false
end

local function resolveRetirement()
	if Hub.RetirePending and now() - Hub.RetireAttemptAt >= 8 then
		Hub.RetirePending = false
		Hub.RetireRetryAt = now() + 30
		setStatus("Retirement retry queued")
	end
end

local function retireStep()
	if not Hub.AutoRetire or Hub.RetirePending or now() < Hub.RetireRetryAt or not eligibleForRetirement() then
		return false
	end
	Hub.RetirePending = true
	Hub.RetireAttemptAt = now()
	setStatus("Requesting retirement")
	Remote:FireServer("Retire")
	return true
end

local function machineRepairStep()
	if not Hub.AutoRepair then
		return false
	end
	local pumps = workspace:FindFirstChild("Pumps")
	if pumps then
		for _, pump in ipairs(pumps:GetChildren()) do
			local prompt = pump:FindFirstChild("RepairPump", true)
			if pump:GetAttribute("Broken") and prompt and prompt.Enabled and cooldownReady(pump) then
				setCooldown(pump, 12)
				setStatus("Repairing pump: " .. pump.Name)
				Remote:FireServer("RepairPump", pump)
				Hub.Stats.MachinesRepaired = Hub.Stats.MachinesRepaired + 1
				return true
			end
		end
	end
	local carWash = workspace:FindFirstChild("CarWash")
	if carWash then
		for _, machine in ipairs(carWash:GetChildren()) do
			local prompt = machine:FindFirstChild("RepairCarWash", true)
			if machine:GetAttribute("Broken") and prompt and prompt.Enabled and cooldownReady(machine) then
				setCooldown(machine, 12)
				setStatus("Repairing car wash: " .. machine.Name)
				Remote:FireServer("RepairCarWash", machine)
				Hub.Stats.MachinesRepaired = Hub.Stats.MachinesRepaired + 1
				return true
			end
		end
	end
	return false
end

local RequirementMap = {
	["floorjack"] = { Type = "Tool", Expected = "Floorjack", Display = "Floorjack" },
	["floor jack"] = { Type = "Tool", Expected = "Floorjack", Display = "Floorjack" },
	["ratchet handle"] = { Type = "Tool", Expected = "Ratchethandle", Display = "Ratchet Handle" },
	["ratchethandle"] = { Type = "Tool", Expected = "Ratchethandle", Display = "Ratchet Handle" },
	["crowbar"] = { Type = "Tool", Expected = "Crowbar", Display = "Crowbar" },
	["hammer"] = { Type = "Tool", Expected = "Hammer", Display = "Hammer" },
	["wrench"] = { Type = "Tool", Expected = "Wrench", Display = "Wrench" },
	["paintgun"] = { Type = "Tool", Expected = "Paintgun", Display = "Paintgun" },
	["paint gun"] = { Type = "Tool", Expected = "Paintgun", Display = "Paintgun" },
	["wheel"] = { Type = "Item", Expected = "Wheel", Storage = "Wheel" },
	["brakedisk"] = { Type = "Item", Expected = "Brakedisk", Storage = "Brakedisk" },
	["brake disk"] = { Type = "Item", Expected = "Brakedisk", Storage = "Brakedisk" },
	["left mirror"] = { Type = "Item", Expected = "Mirror_Left", Storage = "Mirror (Left)" },
	["right mirror"] = { Type = "Item", Expected = "Mirror_Right", Storage = "Mirror (Right)" },
	["left door"] = { Type = "Item", Expected = "Door_Left", Storage = "Door (Left)" },
	["right door"] = { Type = "Item", Expected = "Door_Right", Storage = "Door (Right)" },
	["left hinged door"] = { Type = "Item", Expected = "Door_Left", Storage = "Door (Left)" },
	["right hinged door"] = { Type = "Item", Expected = "Door_Right", Storage = "Door (Right)" },
}

local function parseRequirements(prompt)
	local text = ((prompt.ObjectText or "") .. " " .. (prompt.ActionText or "")):lower()
	local requirementText = text:match("requires%s+([^%)]+)")
	if not requirementText then
		return {}
	end
	requirementText = requirementText:gsub("[%(%)]", ""):gsub("%s+and%s+", ",")
	local requirements = {}
	local seen = {}
	for token in requirementText:gmatch("[^,]+") do
		token = token:gsub("^%s+", ""):gsub("%s+$", "")
		local found = RequirementMap[token]
		if not found then
			for key, value in pairs(RequirementMap) do
				if token:find(key, 1, true) then
					found = value
					break
				end
			end
		end
		if found then
			local id = found.Type .. ":" .. found.Expected
			if not seen[id] then
				seen[id] = true
				table.insert(requirements, found)
			end
		end
	end
	return requirements
end

local function findToolPrompt(requirement)
	local garage = workspace:FindFirstChild("Garage")
	local tools = garage and garage:FindFirstChild("Tools")
	if not tools then
		return nil
	end
	for _, prompt in ipairs(tools:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") and prompt.Name == "EquipTool" and prompt.Enabled then
			local parentName = prompt.Parent and prompt.Parent.Name or ""
			if parentName == requirement.Expected or prompt.ActionText == requirement.Display then
				return prompt
			end
		end
	end
	return nil
end

local function findItemPrompt(requirement)
	local storage = workspace:FindFirstChild("Storage")
	local folder = storage and storage:FindFirstChild(requirement.Storage)
	if not folder or (folder:GetAttribute("Storage") or 0) <= 0 then
		return nil
	end
	for _, prompt in ipairs(folder:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") and prompt.Name == "EquipTool" and prompt.Enabled then
			return prompt
		end
	end
	return nil
end

local function activeGarageCars()
	local cars = {}
	for _, child in ipairs(workspace:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("InGarage") and child:GetAttribute("ServiceReady") then
			table.insert(cars, child)
		end
	end
	return cars
end

local function openGarageDoorStep()
	local garage = workspace:FindFirstChild("Garage")
	if not garage then
		return false
	end
	for _, prompt in ipairs(garage:GetDescendants()) do
		if prompt:IsA("ProximityPrompt") and prompt.Name == "Power" and prompt.Enabled and prompt.ActionText == "Open" and cooldownReady(prompt) then
			setCooldown(prompt, 2)
			return moveAndPrompt(prompt, "Opening garage door")
		end
	end
	return false
end

local function mechanicStep()
	if not Hub.AutoMechanic then
		return false
	end
	local character = getCharacter()
	if not character then
		return false
	end
	local cars = activeGarageCars()
	for _, car in ipairs(cars) do
		for _, prompt in ipairs(car:GetDescendants()) do
			if prompt:IsA("ProximityPrompt") and prompt.Enabled and prompt.Name ~= "CleanWindshield" and cooldownReady(prompt) then
				local requirements = parseRequirements(prompt)
				for _, requirement in ipairs(requirements) do
					if requirement.Type == "Tool" and character:GetAttribute("CarryingTool") ~= requirement.Expected then
						local equipPrompt = findToolPrompt(requirement)
						if equipPrompt then
							setCooldown(equipPrompt, 1)
							return moveAndPrompt(equipPrompt, "Equipping: " .. requirement.Display)
						end
						setStatus("Missing tool: " .. requirement.Display)
						return false
					end
					if requirement.Type == "Item" and character:GetAttribute("CarryingItem") ~= requirement.Expected then
						local equipPrompt = findItemPrompt(requirement)
						if equipPrompt then
							setCooldown(equipPrompt, 1)
							return moveAndPrompt(equipPrompt, "Picking up: " .. requirement.Storage)
						end
						setStatus("Waiting for stock: " .. requirement.Storage)
						return false
					end
				end
				setCooldown(prompt, 1.5)
				Hub.Stats.MechanicSteps = Hub.Stats.MechanicSteps + 1
				return moveAndPrompt(prompt, "Mechanic: " .. prompt.ActionText)
			end
		end
	end
	if #cars > 0 then
		return openGarageDoorStep()
	end
	return false
end

local function bestSeat()
	local best = nil
	local bestRegen = -math.huge
	for _, seat in ipairs(workspace:GetDescendants()) do
		if seat:IsA("Seat") and not seat.Occupant then
			local regen = seat:GetAttribute("StaminaRegen") or 0
			if regen > bestRegen then
				best = seat
				bestRegen = regen
			end
		end
	end
	return best
end

local function staminaStep()
	if not Hub.AutoStamina then
		Hub.Resting = false
		return false
	end
	local ratio = staminaRatio()
	if Hub.Resting then
		if ratio >= Hub.RestHigh then
			Hub.Resting = false
			local humanoid = getHumanoid()
			if humanoid then
				humanoid.Sit = false
			end
			setStatus("Energy restored")
			return false
		end
		setStatus("Resting: " .. tostring(math.floor(ratio * 100)) .. "%")
		if cooldownReady("bloxbull") then
			local vendors = workspace:FindFirstChild("Vendors")
			if vendors and (vendors:GetAttribute("Available") or 0) > 0 then
				for _, prompt in ipairs(vendors:GetDescendants()) do
					if prompt:IsA("ProximityPrompt") and prompt.Name == "BuyBloxBull" and prompt.Enabled then
						setCooldown("bloxbull", 30)
						Hub.Stats.EnergyBoosts = Hub.Stats.EnergyBoosts + 1
						return moveAndPrompt(prompt, "Buying BloxBull for energy")
					end
				end
			end
		end
		local humanoid = getHumanoid()
		local character = getCharacter()
		if humanoid and character and not humanoid.Sit and cooldownReady("seat") then
			setCooldown("seat", 2)
			local seat = bestSeat()
			if seat then
				pcall(function()
					character:PivotTo(seat.CFrame * CFrame.new(0, 2.5, 0))
				end)
				task.wait(0.05)
				pcall(function()
					seat:Sit(humanoid)
				end)
				pcall(function()
					firetouchinterest(character.HumanoidRootPart, seat, 0)
					firetouchinterest(character.HumanoidRootPart, seat, 1)
				end)
			end
		end
		return true
	end
	if ratio <= Hub.RestLow and not characterBusy() then
		Hub.Resting = true
		Hub.Stats.Rests = Hub.Stats.Rests + 1
		setStatus("Starting energy recovery")
		return true
	end
	return false
end

local WorkOrder = {
	{ Key = "Retire", Enabled = function() return Hub.AutoRetire end, Run = retireStep },
	{ Key = "Cashier", Enabled = function() return Hub.AutoCashier end, Run = cashierStep },
	{ Key = "Refuel", Enabled = function() return Hub.AutoRefuel end, Run = refuelStep },
	{ Key = "CarWash", Enabled = function() return Hub.AutoCarWash end, Run = carWashStep },
	{ Key = "Windshield", Enabled = function() return Hub.AutoWindshield end, Run = windshieldStep },
	{ Key = "Scrap", Enabled = function() return Hub.AutoScrap end, Run = scrapStep },
	{ Key = "Mechanic", Enabled = function() return Hub.AutoMechanic end, Run = mechanicStep },
	{ Key = "Repair", Enabled = function() return Hub.AutoRepair end, Run = machineRepairStep },
	{ Key = "Clean", Enabled = function() return Hub.AutoClean end, Run = cleanStep },
	{ Key = "Restock", Enabled = function() return Hub.AutoRestock end, Run = restockStep },
}

local function workStep()
	local character = getCharacter()
	if character and character:GetAttribute("CarryingTrash") and Hub.AutoClean then
		local ok, result = pcall(cleanStep)
		if ok and result then
			return true
		end
	end
	for _ = 1, #WorkOrder do
		Hub.TaskCursor = Hub.TaskCursor % #WorkOrder + 1
		local entry = WorkOrder[Hub.TaskCursor]
		if entry.Enabled() then
			local ok, result = pcall(entry.Run)
			if not ok then
				setStatus(entry.Key .. " error: " .. tostring(result))
				return false
			end
			return result == true
		end
	end
	return false
end

local notificationRemote = NotificationEvent
if notificationRemote and notificationRemote:IsA("RemoteEvent") then
	local connection = notificationRemote.OnClientEvent:Connect(function(data)
		if type(data) ~= "table" then
			return
		end
		local text = (tostring(data.Header or "") .. " " .. tostring(data.BodyText or "")):lower()
		if text:find("out of fuel", 1, true) or text:find("automatic fuel pump is requiring", 1, true) then
			if text:find("gasoline90", 1, true) or text:find("gasoline 90", 1, true) then
				Hub.FuelRequests.Gasoline90 = true
			elseif text:find("gasoline87", 1, true) or text:find("gasoline 87", 1, true) then
				Hub.FuelRequests.Gasoline87 = true
			else
				Hub.FuelRequests.Gasoline87 = true
				Hub.FuelRequests.Gasoline90 = true
			end
		end
		if text:find("invalid position", 1, true) then
			Hub.Stats.InvalidPositions = Hub.Stats.InvalidPositions + 1
			if Hub.LastStackKey then
				Hub.BadStacks[Hub.LastStackKey] = now() + 60
			end
			Hub.PendingStack = nil
		end
	end)
	table.insert(Hub.Connections, connection)
end

local notifications = ReplicatedStorage:FindFirstChild("Notifications")
local noFundsRemote = notifications and notifications:FindFirstChild("yes")
if noFundsRemote and noFundsRemote:IsA("RemoteEvent") then
	local connection = noFundsRemote.OnClientEvent:Connect(function(data)
		if now() - (Hub.LastPurchaseAt or 0) > 5 or type(data) ~= "table" then
			return
		end
		local body = string.lower(tostring(data.BodyText or data.Description or ""))
		local header = string.lower(tostring(data.Header or data.Title or ""))
		local noFunds = header:find("no funds", 1, true) or body:find("no funds", 1, true) or body:find("can not afford", 1, true)
		local noContribution = header:find("not enough contribution", 1, true) or body:find("not enough contribution", 1, true) or body:find("not contributed enough", 1, true) or body:find("contribute more", 1, true)
		if not noFunds and not noContribution then
			return
		end
		table.clear(Hub.FundReservations)
		Hub.PurchaseReadyAt = now() + 3
		Hub.NextPurchaseCheck = now() + 3
		if noContribution then
			Hub.ForceClientFundingUntil = now() + 30
			Hub.Stats.ContributionFallbacks = (Hub.Stats.ContributionFallbacks or 0) + 1
			Hub.LastFundingIssue = {
				Source = "Station",
				Available = contributionFunds(),
				Required = Hub.LastPurchasePrice or 0,
				Reason = "Contribution",
				Time = now(),
			}
			setStatus("Contribution too low; using wallet")
		else
			Hub.Stats.FundsSkipped = (Hub.Stats.FundsSkipped or 0) + 1
			setStatus("Station funds changed; recalculating")
		end
	end)
	table.insert(Hub.Connections, connection)
end

local retirementConnection = Remote.OnClientEvent:Connect(function(eventName)
	if eventName == "Retired" then
		Hub.RetirePending = false
		Hub.RetireRetryAt = now() + 300
		Hub.Stats.Retirements = (Hub.Stats.Retirements or 0) + 1
		setStatus("Retired successfully")
	end
end)
table.insert(Hub.Connections, retirementConnection)

local StatusComponent = nil
local StatsComponent = nil
local BudgetComponent = nil
local WindUI = nil
local Window = nil

local function currentScreenSize()
	local ok, resolution = pcall(function()
		return GuiService:GetScreenResolution()
	end)
	if ok and resolution then
		return resolution
	end
	return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
end

local function desiredWindowSize()
	local resolution = currentScreenSize()
	local topLeft = Vector2.zero
	local bottomRight = Vector2.zero
	pcall(function()
		topLeft, bottomRight = GuiService:GetGuiInset()
	end)
	local usableWidth = math.max(360, resolution.X - topLeft.X - bottomRight.X)
	local usableHeight = math.max(280, resolution.Y - topLeft.Y - bottomRight.Y)
	return math.clamp(math.floor(usableWidth * 0.5), 390, 560), math.clamp(math.floor(usableHeight * 0.84), 300, 410)
end

local function listHas(values, wanted)
	for _, value in ipairs(values or {}) do
		if value == wanted then
			return true
		end
	end
	return false
end

local function selectedValues(items)
	local values = {}
	for _, item in ipairs(items) do
		if item.Enabled() then
			table.insert(values, item.Title)
		end
	end
	return values
end

local uiOk, uiError = pcall(function()
	WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
	local width, height = desiredWindowSize()
	Window = WindUI:CreateWindow({
		Title = "ZSS Automation Hub",
		Icon = "wrench",
		Author = "Zach's Service Station",
		Folder = "ZSSHub",
		Size = UDim2.fromOffset(width, height),
		MinSize = Vector2.new(math.min(width, 390), math.min(height, 300)),
		MaxSize = Vector2.new(width, height),
		Transparent = false,
		Theme = "Dark",
		Resizable = false,
		SideBarWidth = math.clamp(math.floor(width * 0.3), 120, 155),
		HideSearchBar = true,
		ScrollBarEnabled = true,
		OpenButton = {
			Title = "ZSS Hub",
			Enabled = true,
			Draggable = true,
			OnlyMobile = false,
			Scale = 0.72,
		},
		Topbar = {
			Height = 40,
			ButtonsType = "Mac",
		},
	})
	Hub.Window = Window

	local Main = Window:Tab({ Title = "Main", Icon = "house" })
	StatusComponent = Main:Paragraph({ Title = "Status", Desc = Hub.Status, Image = "activity", ImageSize = 22 })
	StatsComponent = Main:Paragraph({ Title = "Counters", Desc = "Waiting for scheduler data", Image = "chart-no-axes-column", ImageSize = 22 })
	Main:Toggle({
		Title = "Pause automation",
		Desc = "Temporarily stops all scheduler actions",
		Value = Hub.Paused,
		Callback = function(value)
			Hub.Paused = value
			setStatus(value and "Paused" or "Idle")
		end,
	})
	Main:Button({
		Title = "Stop hub",
		Desc = "Stops automation and destroys this window",
		Icon = "square",
		Color = Color3.fromRGB(190, 55, 55),
		Callback = function()
			if Hub.Stop then Hub.Stop() end
		end,
	})

	local Store = Window:Tab({ Title = "Store", Icon = "shopping-basket" })
	Store:Dropdown({
		Title = "Store services",
		Desc = "Select the station jobs the scheduler can perform",
		Values = { "Restock shelves", "Clean station", "Cashier" },
		Value = selectedValues({
			{ Title = "Restock shelves", Enabled = function() return Hub.AutoRestock end },
			{ Title = "Clean station", Enabled = function() return Hub.AutoClean end },
			{ Title = "Cashier", Enabled = function() return Hub.AutoCashier end },
		}),
		Multi = true,
		AllowNone = true,
		Callback = function(values)
			Hub.AutoRestock = listHas(values, "Restock shelves")
			Hub.AutoClean = listHas(values, "Clean station")
			Hub.AutoCashier = listHas(values, "Cashier")
		end,
	})
	Store:Dropdown({
		Title = "Automatic purchasing",
		Desc = "Purchases depleted stock with the configured funding rule",
		Values = { "Fuel", "Products", "Mechanic parts" },
		Value = selectedValues({
			{ Title = "Fuel", Enabled = function() return Hub.AutoBuyFuel end },
			{ Title = "Products", Enabled = function() return Hub.AutoBuyProducts end },
			{ Title = "Mechanic parts", Enabled = function() return Hub.AutoMechanicStock end },
		}),
		Multi = true,
		AllowNone = true,
		Callback = function(values)
			Hub.AutoBuyFuel = listHas(values, "Fuel")
			Hub.AutoBuyProducts = listHas(values, "Products")
			Hub.AutoMechanicStock = listHas(values, "Mechanic parts")
		end,
	})

	local Vehicles = Window:Tab({ Title = "Vehicles", Icon = "car-front" })
	Vehicles:Dropdown({
		Title = "Vehicle services",
		Desc = "Customer vehicles, garage work, scraps and station machines",
		Values = { "Refuel customers", "Car wash", "Windshields", "Mechanic", "Mechanic scraps", "Repair machines" },
		Value = selectedValues({
			{ Title = "Refuel customers", Enabled = function() return Hub.AutoRefuel end },
			{ Title = "Car wash", Enabled = function() return Hub.AutoCarWash end },
			{ Title = "Windshields", Enabled = function() return Hub.AutoWindshield end },
			{ Title = "Mechanic", Enabled = function() return Hub.AutoMechanic end },
			{ Title = "Mechanic scraps", Enabled = function() return Hub.AutoScrap end },
			{ Title = "Repair machines", Enabled = function() return Hub.AutoRepair end },
		}),
		Multi = true,
		AllowNone = true,
		Callback = function(values)
			Hub.AutoRefuel = listHas(values, "Refuel customers")
			Hub.AutoCarWash = listHas(values, "Car wash")
			Hub.AutoWindshield = listHas(values, "Windshields")
			Hub.AutoMechanic = listHas(values, "Mechanic")
			Hub.AutoScrap = listHas(values, "Mechanic scraps")
			Hub.AutoRepair = listHas(values, "Repair machines")
		end,
	})

	local Budget = Window:Tab({ Title = "Budget", Icon = "wallet-cards" })
	BudgetComponent = Budget:Paragraph({ Title = "Station reserve", Desc = "Calculating protected funds", Image = "shield-check", ImageSize = 22 })
	Budget:Toggle({ Title = "Auto station upgrades", Desc = "Buys expansions and improvements only above the protected reserve", Value = Hub.AutoStationUpgrades, Callback = function(value) Hub.AutoStationUpgrades = value end })
	Budget:Toggle({ Title = "Cheapest shop purchases", Desc = "Buys the cheapest fuel package and one cheapest item per order", Value = Hub.CheapestPurchases, Callback = function(value) Hub.CheapestPurchases = value end })
	Budget:Toggle({ Title = "Prioritize expansion", Desc = "Prefers station and storage expansion before optional upgrades", Value = Hub.ExpansionPriority, Callback = function(value) Hub.ExpansionPriority = value end })
	Budget:Slider({ Title = "Minimum station reserve", Desc = "Cash never used for purchasing or upgrades", Step = 10, Value = { Min = 0, Max = 2000, Default = Hub.MinimumStationReserve }, Callback = function(value) Hub.MinimumStationReserve = value end })
	Budget:Slider({ Title = "Bill reserve multiplier", Desc = "Multiplier applied to Station.EstBills", Step = 0.25, Value = { Min = 1, Max = 5, Default = Hub.BillReserveMultiplier }, Callback = function(value) Hub.BillReserveMultiplier = value end })
	Budget:Slider({ Title = "Extra bill buffer", Desc = "Additional protected cash above estimated bills", Step = 5, Value = { Min = 0, Max = 500, Default = Hub.BillExtraBuffer }, Callback = function(value) Hub.BillExtraBuffer = value end })
	Budget:Slider({ Title = "Maximum upgrade price", Desc = "Skips individual upgrades above this price", Step = 10, Value = { Min = 20, Max = 2000, Default = Hub.UpgradeSpendCap }, Callback = function(value) Hub.UpgradeSpendCap = value end })
	Budget:Button({ Title = "Save settings now", Desc = "Writes all options to ZSS_Automation_Settings.json", Icon = "save", Callback = function() saveSettings(); setStatus("Settings saved") end })

	local System = Window:Tab({ Title = "System", Icon = "settings" })
	System:Toggle({ Title = "Auto stamina recovery", Desc = "Uses the real effective stamina percentage", Value = Hub.AutoStamina, Callback = function(value) Hub.AutoStamina = value end })
	System:Toggle({ Title = "Auto retire", Desc = "Waits for server confirmation before counting retirement", Value = Hub.AutoRetire, Callback = function(value) Hub.AutoRetire = value end })
	System:Slider({ Title = "Scheduler interval", Desc = "Delay between coordinated checks", Step = 0.01, Value = { Min = 0.05, Max = 0.5, Default = Hub.Interval }, Callback = function(value) Hub.Interval = math.max(0.05, value) end })
	System:Slider({ Title = "Rest below", Desc = "Effective stamina percentage that starts recovery", Step = 1, Value = { Min = 10, Max = 90, Default = math.floor(Hub.RestLow * 100 + 0.5) }, Callback = function(value) Hub.RestLow = value / 100 end })
	System:Slider({ Title = "Resume above", Desc = "Effective stamina percentage that resumes work", Step = 1, Value = { Min = 20, Max = 100, Default = math.floor(Hub.RestHigh * 100 + 0.5) }, Callback = function(value) Hub.RestHigh = value / 100 end })
	System:Slider({ Title = "Fuel buy threshold", Desc = "Tank percentage that starts purchasing", Step = 1, Value = { Min = 0, Max = 50, Default = math.floor(Hub.FuelThreshold * 100 + 0.5) }, Callback = function(value) Hub.FuelThreshold = value / 100 end })
	System:Slider({ Title = "Mechanic minimum stock", Desc = "Part amount that starts purchasing", Step = 1, Value = { Min = 0, Max = 10, Default = Hub.MechanicMinimum }, Callback = function(value) Hub.MechanicMinimum = math.floor(value) end })

	WindUI:Notify({ Title = "ZSS Hub", Content = "WindUI loaded with the optimized scheduler", Icon = "check", Duration = 4 })
end)

if not uiOk then
	warn("[ZSS HUB] WindUI failed: " .. tostring(uiError))
end

function Hub.Stop()
	saveSettings()
	Hub.Enabled = false
	for _, connection in pairs(Hub.Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(Hub.Connections)
	if Hub.Window then
		pcall(function()
			Hub.Window:Destroy()
		end)
	end
	setStatus("Stopped")
end

local lastUiUpdate = 0
local function updateStatusUi()
	if now() - lastUiUpdate < 1 then
		return
	end
	lastUiUpdate = now()
	if StatusComponent then
		pcall(function()
			StatusComponent:SetDesc(Hub.Status)
		end)
	end
	if BudgetComponent then
		local reserve = stationReserve()
		local money = rawFunds("Station")
		local spendable = availableFunds("Station")
		pcall(function() BudgetComponent:SetDesc(string.format("Station $%.2f | Bills $%.2f | Protected $%.2f | Spendable $%.2f", money, estimatedBills(), reserve, spendable)) end)
	end
	if StatsComponent then
		local s = Hub.Stats
		local text = string.format("Stock %d | Clean %d | Scan %d | Refuel %d | Wash %d | Scrap %d | Mech %d | Upgrades %d", s.Restocked, s.Cleaned, s.Scanned, s.CarsRefueled, s.CarWashSides, s.ScrapsCollected, s.MechanicSteps, s.StationUpgrades or 0)
		pcall(function()
			StatsComponent:SetDesc(text)
		end)
	end
end

task.spawn(function()
	while Hub.Enabled do
		local started = now()
		local ok, errorMessage = pcall(function()
			resolvePendingStack()
			resolvePendingScrap()
			resolveRetirement()
			if not Hub.Paused then
				if not stationUpgradeStep() then purchaseStep() end
				local resting = staminaStep()
				if not resting and not characterBusy() then
					if not workStep() and Hub.Status ~= "Energy restored" then
						setStatus("Idle")
					end
				end
			else
				setStatus("Paused")
			end
			updateStatusUi()
		end)
		if not ok then
			setStatus("Scheduler error: " .. tostring(errorMessage))
			warn("[ZSS HUB] " .. tostring(errorMessage))
		end
		local elapsed = now() - started
		task.wait(math.max(0.03, Hub.Interval - elapsed))
	end
end)

print("[ZSS HUB] Started with WindUI and 0.3 second scheduler")
