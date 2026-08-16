local env = getgenv()

local function stopController(value)
	if type(value) ~= "table" then
		return
	end
	value.enabled = false
	value.Enabled = false
	if type(value.Stop) == "function" then
		pcall(value.Stop)
	end
	for _, listName in ipairs({ "connections", "Connections" }) do
		local list = value[listName]
		if type(list) == "table" then
			for _, connection in ipairs(list) do
				pcall(function()
					connection:Disconnect()
				end)
			end
		end
	end
end

stopController(env.LOC_AUTO)
stopController(env.LOC_AUTOPLAY_V2)
stopController(env.LOC_CARD_AI)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local ClientCards = ReplicatedStorage:WaitForChild("ClientCards")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PlayCard = Remotes:WaitForChild("PlayCard")
local ChooseColor = Remotes:WaitForChild("ChooseColor")
local ChosenColor = Remotes:WaitForChild("ChosenColor")
local ChoosePlayer = Remotes:WaitForChild("ChoosePlayer")
local ChoiceArrows = Remotes:WaitForChild("ChoiceArrows")
local SlapOnSix = Remotes:WaitForChild("SlapOnSix")
local CallOfficial = Remotes:WaitForChild("CallOfficial")
local CanPlayCard = require(ReplicatedStorage.Modules:WaitForChild("CanPlayCard"))
local CanStackCard = require(ReplicatedStorage.Modules:WaitForChild("CanStackCard"))

local Knowledge = {
	["+1"] = { class = "draw", amount = 1, target = "next" },
	["+2"] = { class = "draw", amount = 2, target = "next" },
	["+5"] = { class = "draw", amount = 5, target = "next" },
	["0"] = { class = "pass-hands" },
	["1"] = { class = "number", value = 1 },
	["2"] = { class = "number", value = 2 },
	["3"] = { class = "number", value = 3 },
	["4"] = { class = "number", value = 4 },
	["5"] = { class = "number", value = 5 },
	["6"] = { class = "slap", value = 6 },
	["7"] = { class = "swap" },
	["8"] = { class = "number", value = 8 },
	["9"] = { class = "number", value = 9 },
	["Auction"] = { class = "auction" },
	["Blox Bank"] = { class = "target-attack", amount = 2 },
	["Bomb"] = { class = "board-attack" },
	["Bomb Card"] = { class = "draw-trap", amount = 3 },
	["Cancel"] = { class = "defense-skip" },
	["Card Star"] = { class = "privacy" },
	["Choice +2"] = { class = "target-attack", amount = 2 },
	["Choice +5"] = { class = "target-attack", amount = 5 },
	["Donate"] = { class = "donate" },
	["Donation Rise"] = { class = "global-threshold" },
	["Draw Til Loco"] = { class = "wild-draw-color" },
	["Event"] = { class = "random" },
	["Forward +2"] = { class = "draw", amount = 2, target = "front" },
	["Forward Loco +5 - 1"] = { class = "wild-draw", amount = 5, target = "front" },
	["Go Again"] = { class = "extra-turn" },
	["Loco +2"] = { class = "wild-draw", amount = 2, target = "next" },
	["Loco +5 - 1"] = { class = "wild-draw", amount = 5, target = "next" },
	["Loco +99"] = { class = "wild-draw", amount = 99, target = "next" },
	["Loco 8"] = { class = "wild" },
	["Loco 8 (Inverted)"] = { class = "wild" },
	["Loco Smite +4"] = { class = "global-color-attack", amount = 4 },
	["Mix"] = { class = "shuffle-target" },
	["Nuke"] = { class = "equalize" },
	["Redirect"] = { class = "redirect" },
	["Reflect"] = { class = "defense-reverse" },
	["Show for the Fans"] = { class = "reveal-target" },
	["Switch"] = { class = "flip" },
	["Time Trial"] = { class = "speed" }
}

local state = {
	enabled = true,
	version = "Card Intelligence V6 Debug",
	debugNotifications = true,
	notificationDuration = 3,
	notificationHistory = {},
	connections = {},
	Knowledge = Knowledge,
	lastAction = "Ready",
	lastDecision = "",
	lastScore = 0,
	lastTarget = "",
	lastColor = "",
	lastColorReason = "",
	lastColorAt = 0,
	colorPermissionUntil = 0,
	lastActionAt = 0,
	lastActionKey = "",
	lastSlapAt = 0,
	lastCalloutAt = 0,
	lastOfficialAt = 0,
	pendingSymbol = nil,
	pendingCard = nil,
	colorActive = false,
	choiceActive = false,
	challengeLatched = false,
	slapLatched = false,
	calloutLatched = false,
	officialLatched = false,
	drawnStartedAt = nil,
	auctionLatched = false,
	choosingLatched = false,
	match = nil,
	seat = nil,
	rules = nil,
	context = nil,
	contextCheckedAt = 0,
	opponentModel = {},
	snapshot = nil,
	lastObservedWildKey = "",
	challengeColor = nil
}

env.LOC_CARD_AI = state

local function notify(title, text, duration, key, cooldown)
	if not state.debugNotifications then
		return false
	end
	title = tostring(title or "LOC AutoPlayer")
	text = tostring(text or "")
	key = tostring(key or (title .. "|" .. text))
	duration = tonumber(duration) or state.notificationDuration or 3
	cooldown = tonumber(cooldown) or 0.8
	local now = os.clock()
	local previous = state.notificationHistory[key]
	if previous and now - previous < cooldown then
		return false
	end
	state.notificationHistory[key] = now
	task.spawn(function()
		for _ = 1, 4 do
			local ok = pcall(function()
				StarterGui:SetCore("SendNotification", {
					Title = title,
					Text = text,
					Duration = duration
				})
			end)
			if ok then
				return
			end
			task.wait(0.25)
		end
	end)
	return true
end

local function setAction(text, title, details, duration, key, cooldown)
	state.lastAction = tostring(text)
	local body = state.lastAction
	if details and tostring(details) ~= "" then
		body = body .. "\n" .. tostring(details)
	end
	notify(title or "LOC AutoPlayer", body, duration, key or state.lastAction, cooldown)
end

state.Notify = notify
state.SetDebugNotifications = function(enabled)
	state.debugNotifications = enabled ~= false
	notify("LOC AutoPlayer", state.debugNotifications and "Debug notifications enabled" or "Debug notifications disabled", 2, "debug-toggle", 0)
end

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(state.connections, connection)
	return connection
end

local function getContainer()
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local cards = playerGui and playerGui:FindFirstChild("cards")
	return cards and cards:FindFirstChild("Container")
end

local function findMatch()
	local assets = Workspace:FindFirstChild("GameAssets")
	if not assets then
		return nil, nil
	end
	for _, item in ipairs(assets:GetChildren()) do
		if item:IsA("Model") then
			for index = 1, 20 do
				local playerName = item:GetAttribute("Player_" .. index)
				if playerName == LocalPlayer.Name then
					return item, tostring(index)
				end
			end
		end
	end
	return nil, nil
end

local function refreshContext(match, seat)
	if not match then
		state.context = nil
		state.rules = nil
		return
	end
	if state.match ~= match then
		state.context = nil
		state.rules = nil
		state.contextCheckedAt = 0
		state.opponentModel = {}
		state.snapshot = nil
		state.lastObservedWildKey = ""
		state.challengeColor = nil
	end
	if state.context and state.context.CardPile == match and type(state.rules) == "table" then
		return
	end
	if os.clock() - state.contextCheckedAt < 2 then
		return
	end
	state.contextCheckedAt = os.clock()
	if type(getgc) ~= "function" then
		return
	end
	local ok, objects = pcall(getgc, true)
	if not ok then
		return
	end
	for _, object in ipairs(objects) do
		if type(object) == "table" and rawget(object, "CardPile") == match and type(rawget(object, "HouseRules")) == "table" then
			state.context = object
			state.rules = object.HouseRules
			if object.HouseRules.LocalPlayerNumber then
				state.seat = tostring(object.HouseRules.LocalPlayerNumber)
			elseif object.LocalPlayerNumber then
				state.seat = tostring(object.LocalPlayerNumber)
			else
				state.seat = seat
			end
			return
		end
	end
end

local function activeCardData(card, pile, forceInverted)
	local inverted = forceInverted
	if inverted == nil then
		inverted = pile and pile:GetAttribute("Inverted") == true
	end
	local rules = state.rules or {}
	local useInverted = rules.DeckName == "SwitchDeck" and inverted
	local color = card:GetAttribute(useInverted and "ColorInverted" or "Color")
	local symbol = card:GetAttribute(useInverted and "SymbolInverted" or "Symbol")
	if color == nil then
		color = card:GetAttribute("Color")
	end
	if symbol == nil then
		symbol = card:GetAttribute("Symbol")
	end
	return {
		Color = color,
		Symbol = tostring(symbol),
		Instance = card,
		Attributes = card:GetAttributes()
	}
end

local function pileData(pile)
	return {
		Color = pile:GetAttribute("Color"),
		Symbol = tostring(pile:GetAttribute("Symbol"))
	}
end

local function getHand(pile)
	local hand = {}
	for _, card in ipairs(ClientCards:GetChildren()) do
		if card:IsA("Configuration") then
			table.insert(hand, activeCardData(card, pile))
		end
	end
	return hand
end

local function getPlayers(match, seat, handCount)
	local output = {}
	local assets = Workspace:FindFirstChild("GameAssets")
	local display = assets and match and assets:FindFirstChild("CardDisplays/" .. match.Name)
	if display then
		for _, folder in ipairs(display:GetChildren()) do
			local playerSeat, playerName = string.match(folder.Name, "^(%d+)/(.*)$")
			if playerSeat and playerName then
				table.insert(output, {
					seat = tostring(playerSeat),
					name = playerName,
					count = #folder:GetChildren(),
					self = tostring(playerSeat) == tostring(seat)
				})
			end
		end
	end
	if #output == 0 and match then
		for index = 1, 20 do
			local name = match:GetAttribute("Player_" .. index)
			if name then
				table.insert(output, {
					seat = tostring(index),
					name = tostring(name),
					count = tostring(index) == tostring(seat) and handCount or 99,
					self = tostring(index) == tostring(seat)
				})
			end
		end
	end
	for _, player in ipairs(output) do
		if player.self then
			player.count = handCount
		end
	end
	return output
end

local function teammate(a, b)
	local rules = state.rules or {}
	if not rules.Teams then
		return false
	end
	return tonumber(a) and tonumber(b) and tonumber(a) % 2 == tonumber(b) % 2
end

local function sortedOpponents(players, preferSmall, attacksOnly)
	local candidates = {}
	for _, player in ipairs(players) do
		if not player.self then
			if not attacksOnly or not teammate(state.seat, player.seat) then
				table.insert(candidates, player)
			end
		end
	end
	if #candidates == 0 then
		for _, player in ipairs(players) do
			if not player.self then
				table.insert(candidates, player)
			end
		end
	end
	table.sort(candidates, function(a, b)
		if a.count == b.count then
			return tonumber(a.seat) < tonumber(b.seat)
		end
		if preferSmall then
			return a.count < b.count
		end
		return a.count > b.count
	end)
	return candidates
end

local function pickTarget(symbol, players)
	if #players == 0 then
		return nil
	end
	if symbol == "Donate" and (state.rules or {}).Teams then
		local allies = {}
		for _, player in ipairs(players) do
			if not player.self and teammate(state.seat, player.seat) then
				table.insert(allies, player)
			end
		end
		table.sort(allies, function(a, b)
			return a.count < b.count
		end)
		if allies[1] then
			return allies[1]
		end
	end
	if symbol == "Redirect" and (state.rules or {}).Teams then
		local allies = {}
		for _, player in ipairs(players) do
			if not player.self and teammate(state.seat, player.seat) then
				table.insert(allies, player)
			end
		end
		table.sort(allies, function(a, b)
			return a.count < b.count
		end)
		if allies[1] then
			return allies[1]
		end
	end
	if symbol == "Redirect" or symbol == "Donate" then
		return sortedOpponents(players, false, false)[1]
	end
	return sortedOpponents(players, true, true)[1]
end

local COLORS = { "Red", "Green", "Yellow", "Blue" }

local function opponentProfile(seat)
	local key = tostring(seat or "")
	local profile = state.opponentModel[key]
	if not profile then
		profile = {
			weak = { Red = 0, Green = 0, Yellow = 0, Blue = 0 },
			prefer = { Red = 0, Green = 0, Yellow = 0, Blue = 0 }
		}
		state.opponentModel[key] = profile
	end
	return profile
end

local function isForcedDrawSymbol(symbol)
	symbol = tostring(symbol or "")
	return string.find(symbol, "+", 1, true) ~= nil
		or symbol == "Bomb Card"
		or symbol == "Blox Bank"
		or symbol == "Draw Til Loco"
		or symbol == "Loco Smite +4"
end

local function isPureWildSymbol(symbol)
	return symbol == "Loco 8" or symbol == "Loco 8 (Inverted)"
end

local function isControlCard(symbol)
	return symbol == "Cancel"
		or symbol == "Reflect"
		or symbol == "Redirect"
		or symbol == "+1"
		or symbol == "+2"
		or symbol == "+5"
		or symbol == "Choice +2"
		or symbol == "Choice +5"
		or symbol == "Bomb Card"
end

local ColorPickSymbols = {
	["Loco 8"] = true,
	["Loco 8 (Inverted)"] = true,
	["Loco +2"] = true,
	["Loco +5 - 1"] = true,
	["Forward Loco +5 - 1"] = true,
	["Loco +99"] = true,
	["Draw Til Loco"] = true,
	["Loco Smite +4"] = true
}

local function isColorPickSymbol(symbol)
	return ColorPickSymbols[tostring(symbol)] == true
end

local function finishability(card)
	if not card then
		return 0
	end
	if isColorPickSymbol(card.Symbol) then
		return 115
	end
	if not tonumber(card.Symbol) then
		return 62
	end
	return 24
end

local function colorCounts(hand, excludeInstance)
	local counts = {
		Red = 0,
		Green = 0,
		Yellow = 0,
		Blue = 0
	}
	for _, card in ipairs(hand) do
		if card.Instance ~= excludeInstance and counts[card.Color] ~= nil then
			counts[card.Color] = counts[card.Color] + 1
		end
	end
	return counts
end

local function getPlayerBySeat(players, wantedSeat)
	for _, player in ipairs(players) do
		if tostring(player.seat) == tostring(wantedSeat) then
			return player
		end
	end
	return nil
end

local function wrappedSeat(seat, delta, playerCount)
	local value = tonumber(seat)
	if not value or playerCount <= 0 then
		return nil
	end
	return tostring(((value - 1 + delta) % playerCount) + 1)
end

local function getDisplayRoot(match)
	local assets = Workspace:FindFirstChild("GameAssets")
	return assets and match and assets:FindFirstChild("CardDisplays/" .. match.Name)
end

local function readDisplayedCardColor(cardObject, pile)
	local inverted = pile and pile:GetAttribute("Inverted") == true
	local useInverted = (state.rules or {}).DeckName == "SwitchDeck" and inverted
	local attributeName = useInverted and "ColorInverted" or "Color"
	local color = cardObject:GetAttribute(attributeName) or cardObject:GetAttribute("Color")
	if color ~= nil then
		return tostring(color)
	end
	for _, descendant in ipairs(cardObject:GetDescendants()) do
		color = descendant:GetAttribute(attributeName) or descendant:GetAttribute("Color")
		if color ~= nil then
			return tostring(color)
		end
	end
	return nil
end

local function knownPlayerColorCounts(match, seat, pile)
	local root = getDisplayRoot(match)
	if not root then
		return nil, 0
	end
	local folder = nil
	for _, candidate in ipairs(root:GetChildren()) do
		local playerSeat = string.match(candidate.Name, "^(%d+)/")
		if playerSeat and tostring(playerSeat) == tostring(seat) then
			folder = candidate
			break
		end
	end
	if not folder then
		return nil, 0
	end
	local counts = {
		Red = 0,
		Green = 0,
		Yellow = 0,
		Blue = 0
	}
	local known = 0
	for _, cardObject in ipairs(folder:GetChildren()) do
		local color = readDisplayedCardColor(cardObject, pile)
		if counts[color] ~= nil then
			counts[color] = counts[color] + 1
			known = known + 1
		end
	end
	return counts, known
end

local function updateOpponentModel(pile, players)
	local previous = state.snapshot
	local current = {
		match = pile,
		turn = tostring(pile:GetAttribute("CurrentTurn")),
		previousTurn = tostring(pile:GetAttribute("PreviousTurn")),
		color = tostring(pile:GetAttribute("Color")),
		symbol = tostring(pile:GetAttribute("Symbol")),
		counts = {}
	}

	for _, player in ipairs(players) do
		current.counts[tostring(player.seat)] = player.count
	end

	if previous and previous.match == pile then
		for _, player in ipairs(players) do
			if not player.self then
				local seat = tostring(player.seat)
				local oldCount = previous.counts[seat]
				if oldCount and player.count > oldCount
					and previous.turn == seat
					and table.find(COLORS, previous.color)
					and not isForcedDrawSymbol(previous.symbol)
					and not pile:GetAttribute("IsAuctioning")
					and pile:GetAttribute("IsChoosingCard") == nil
				then
					local profile = opponentProfile(seat)
					profile.weak[previous.color] = math.min(10, profile.weak[previous.color] + math.min(player.count - oldCount, 3) * 1.5)
				end
			end
		end
	end

	if isColorPickSymbol(current.symbol) and table.find(COLORS, current.color) then
		local key = table.concat({ pile.Name, current.previousTurn, current.symbol, current.color }, ":")
		if key ~= state.lastObservedWildKey then
			state.lastObservedWildKey = key
			local player = getPlayerBySeat(players, current.previousTurn)
			if player and not player.self then
				local profile = opponentProfile(player.seat)
				profile.prefer[current.color] = math.min(10, profile.prefer[current.color] + 2)
			end
		end
	end

	if previous and previous.match == pile
		and previous.symbol ~= current.symbol
		and isColorPickSymbol(current.symbol)
		and table.find(COLORS, previous.color)
	then
		state.challengeColor = previous.color
	elseif not isColorPickSymbol(current.symbol) and not pile:GetAttribute("IsChallenging") then
		state.challengeColor = nil
	end

	state.snapshot = current
end

local function colorFollowupValue(hand, color, excludeInstance)
	local value = 0
	local rules = state.rules or {}
	for _, card in ipairs(hand) do
		if card.Instance ~= excludeInstance and card.Color == color then
			local number = tonumber(card.Symbol)
			if number then
				value = value + 5
				if rules["7-0"] and (card.Symbol == "7" or card.Symbol == "0") then
					value = value - 3
				end
			else
				value = value + 9
				if string.find(card.Symbol, "+", 1, true) then
					value = value + 4
				end
			end
		end
	end
	return value
end

local function bestColor(hand, symbol, pile, players)
	local excludeInstance = state.pendingCard
	local counts = colorCounts(hand, excludeInstance)
	local best = nil
	local bestScore = -math.huge
	local bestReason = ""
	local playerCount = players and #players or 0
	local direction = pile and (tonumber(pile:GetAttribute("Direction")) or 1) or 1
	local nextSeat = playerCount > 0 and wrappedSeat(state.seat, direction, playerCount) or nil
	local nextPlayer = players and getPlayerBySeat(players, nextSeat) or nil

	for _, color in ipairs(COLORS) do
		local ownCount = counts[color] or 0
		local score = ownCount * 34 + colorFollowupValue(hand, color, excludeInstance)
		local reasons = { "own=" .. tostring(ownCount) }

		if pile and color == pile:GetAttribute("Color") then
			score = score + 2
		end

		if symbol == "Draw Til Loco" then
			score = score + ownCount * 10
			table.insert(reasons, "draw-til pressure")
		elseif symbol == "Loco Smite +4" then
			if ownCount <= 0 then
				score = score - 10000
				table.insert(reasons, "self-smite risk")
			else
				score = score + 90
				table.insert(reasons, "self-safe")
			end
		end

		if players and pile then
			if symbol == "Loco Smite +4" then
				for _, player in ipairs(players) do
					if not player.self then
						local knownCounts, known = knownPlayerColorCounts(state.match, player.seat, pile)
						if known > 0 then
							local held = knownCounts[color] or 0
							if teammate(state.seat, player.seat) then
								if held == 0 then
									score = score - 80
								else
									score = score + math.min(held, 2) * 5
								end
							else
								if held == 0 then
									score = score + 80
								else
									score = score - math.min(held, 3) * 8
								end
							end
						end
						local profile = opponentProfile(player.seat)
						local weak = profile.weak[color] or 0
						local prefer = profile.prefer[color] or 0
						if teammate(state.seat, player.seat) then
							score = score - weak * 10 + prefer * 5
						else
							score = score + weak * 16 - prefer * 7
						end
					end
				end
			elseif nextPlayer then
				local knownCounts, known = knownPlayerColorCounts(state.match, nextPlayer.seat, pile)
				if known > 0 then
					local held = knownCounts[color] or 0
					if teammate(state.seat, nextPlayer.seat) then
						score = score + held * 8
						if held == 0 then
							score = score - 18
						end
					else
						score = score - held * (nextPlayer.count <= 2 and 24 or 8)
						if held == 0 then
							score = score + (nextPlayer.count <= 2 and 95 or 22)
						end
					end
				end
				local profile = opponentProfile(nextPlayer.seat)
				local weak = profile.weak[color] or 0
				local prefer = profile.prefer[color] or 0
				if teammate(state.seat, nextPlayer.seat) then
					score = score - weak * 7 + prefer * 5
				else
					score = score + weak * (nextPlayer.count <= 2 and 28 or 12)
						- prefer * (nextPlayer.count <= 2 and 16 or 6)
				end
			end
		end

		if score > bestScore then
			best = color
			bestScore = score
			bestReason = table.concat(reasons, ", ")
		end
	end

	if symbol == "Loco Smite +4" and (counts[best] or 0) <= 0 then
		for _, color in ipairs(COLORS) do
			if (counts[color] or 0) > 0 then
				best = color
				bestReason = "fallback self-safe"
				break
			end
		end
	end

	return best or "Red", counts, bestReason, bestScore
end

local function sideStrength(pile, inverted)
	local counts = {
		Red = 0,
		Green = 0,
		Yellow = 0,
		Blue = 0
	}
	local actions = 0
	for _, card in ipairs(ClientCards:GetChildren()) do
		if card:IsA("Configuration") then
			local data = activeCardData(card, pile, inverted)
			if counts[data.Color] ~= nil then
				counts[data.Color] = counts[data.Color] + 1
			end
			if not tonumber(data.Symbol) then
				actions = actions + 1
			end
		end
	end
	local strongest = 0
	for _, value in pairs(counts) do
		strongest = math.max(strongest, value)
	end
	return strongest * 3 + actions
end

local function minMaxAverage(players, handCount)
	local minimum = 99
	local maximum = 0
	local total = handCount
	local count = 1
	for _, player in ipairs(players) do
		if not player.self then
			minimum = math.min(minimum, player.count)
			maximum = math.max(maximum, player.count)
			total = total + player.count
			count = count + 1
		end
	end
	if minimum == 99 then
		minimum = handCount
	end
	return minimum, maximum, total / math.max(count, 1)
end

local function scoreCard(card, hand, players, pile)
	local symbol = card.Symbol
	local number = tonumber(symbol)
	local handCount = #hand
	local minimum, _, average = minMaxAverage(players, handCount)
	local danger = math.max(0, 6 - minimum) * 12
	local counts = colorCounts(hand, state.pendingCard)
	local score = 0
	local reason = ""
	if number then
		score = 35 + number * 2
		reason = "number"
		if symbol == "6" then
			score = 52 + danger
			reason = "slap card"
		elseif symbol == "7" and (state.rules or {})["7-0"] then
			local target = sortedOpponents(players, true, true)[1]
			if target and target.count < handCount - 1 then
				score = 120 + (handCount - 1 - target.count) * 15
				reason = "beneficial 7 swap"
			else
				score = -90
				reason = "avoid harmful 7 swap"
			end
		elseif symbol == "0" and (state.rules or {})["7-0"] then
			local direction = tonumber(pile:GetAttribute("Direction")) or 1
			local sourceSeat = wrappedSeat(state.seat, -direction, #players)
			local source = getPlayerBySeat(players, sourceSeat)
			if source and source.count < handCount - 1 then
				score = 105 + (handCount - 1 - source.count) * 12
				reason = "beneficial hand rotation"
			else
				score = -70
				reason = "avoid harmful hand rotation"
			end
		end
	else
		local values = {
			["+1"] = 82,
			["+2"] = 95,
			["+5"] = 125,
			["Forward +2"] = 94,
			["Cancel"] = 88,
			["Reflect"] = 84,
			["Redirect"] = 76,
			["Choice +2"] = 108 + danger * 0.8,
			["Choice +5"] = 142 + danger * 1.2,
			["Loco 8"] = 72,
			["Loco 8 (Inverted)"] = 72,
			["Loco +2"] = 112,
			["Loco +5 - 1"] = 148,
			["Forward Loco +5 - 1"] = 145,
			["Loco +99"] = 1000,
			["Draw Til Loco"] = 155,
			["Event"] = handCount > average and 88 or 25,
			["Mix"] = 74 + danger,
			["Switch"] = 60,
			["Auction"] = handCount > average and 58 or 25,
			["Blox Bank"] = 138 + danger,
			["Bomb"] = 68,
			["Nuke"] = handCount > average and 130 + (handCount - average) * 14 or -80,
			["Loco Smite +4"] = 130,
			["Donation Rise"] = 75,
			["Donate"] = handCount >= 2 and 145 or -100,
			["Bomb Card"] = 105 + danger,
			["Card Star"] = handCount >= 5 and 72 or 15,
			["Show for the Fans"] = 83 + danger * 0.7,
			["Time Trial"] = 125 + danger * 0.8,
			["Go Again"] = 150
		}
		score = values[symbol] or 55
		reason = (Knowledge[symbol] and Knowledge[symbol].class) or "action"
		if symbol == "Switch" then
			local current = pile:GetAttribute("Inverted") == true
			local gain = sideStrength(pile, not current) - sideStrength(pile, current)
			score = score + gain * 12
			reason = gain >= 0 and "stronger reverse side" or "weaker reverse side"
		elseif symbol == "Donation Rise" then
			local highNumbers = 0
			for _, other in ipairs(hand) do
				if tonumber(other.Symbol) and tonumber(other.Symbol) >= 6 then
					highNumbers = highNumbers + 1
				end
			end
			score = score + highNumbers * 10
		elseif symbol == "Cancel" or symbol == "Reflect" then
			score = score + danger
		elseif symbol == "Loco Smite +4" then
			local color = bestColor(hand, symbol, pile, players)
			score = score + (counts[color] or 0) * 8
		elseif string.find(symbol, "Loco", 1, true) then
			local color = bestColor(hand, symbol, pile, players)
			score = score + (counts[color] or 0) * 7
		end
	end
	if counts[card.Color] ~= nil then
		score = score + counts[card.Color] * 5
	end
	if card.Color == pile:GetAttribute("Color") then
		score = score + 5
	end
	if handCount <= 3 and symbol ~= "7" and symbol ~= "0" then
		score = score + 20
	end

	local opponentThreat = minimum <= 2
	if isPureWildSymbol(symbol) then
		if handCount >= 5 and not opponentThreat then
			score = score - 72
			reason = reason .. "; preserve flexible wild"
		elseif handCount <= 3 then
			score = score + 46
			reason = reason .. "; endgame wild"
		end
	elseif isControlCard(symbol) then
		if handCount >= 6 and not opponentThreat then
			score = score - 34
			reason = reason .. "; preserve control"
		elseif opponentThreat then
			score = score + 38
			reason = reason .. "; stop near-win opponent"
		end
	end

	if handCount == 2 then
		local remaining = nil
		for _, other in ipairs(hand) do
			if other.Instance ~= card.Instance then
				remaining = other
				break
			end
		end
		if remaining then
			local finish = finishability(remaining)
			score = score + finish
			reason = reason .. "; leave " .. remaining.Symbol .. " as finisher"
			if isPureWildSymbol(symbol) and not isColorPickSymbol(remaining.Symbol) then
				score = score - 90
				reason = reason .. "; save wild for last"
			end
		end
	end

	return score, reason
end

local function currentTurnAllowed(pile, card)
	local turn = pile:GetAttribute("CurrentTurn")
	local previous = pile:GetAttribute("PreviousTurn")
	local previousPlay = pile:GetAttribute("PreviousTurnPlay")
	if turn == nil or tostring(turn) == tostring(state.seat) then
		return true
	end
	if tostring(previous) == tostring(state.seat) and previousPlay then
		return true
	end
	local rules = state.rules or {}
	if rules["Jump In"] then
		local top = pileData(pile)
		return tostring(card.Symbol) == tostring(top.Symbol) and tostring(card.Color) == tostring(top.Color)
	end
	return false
end

local function canPlay(pile, card)
	if not currentTurnAllowed(pile, card) then
		return false
	end
	if pile:GetAttribute("AllowPlay") == false or pile:GetAttribute("AllowCurrentPlay") == false then
		return false
	end
	if pile:GetAttribute("DonationRiseEvent") then
		local cardNumber = tonumber(card.Symbol)
		local pileNumber = tonumber(pile:GetAttribute("Symbol"))
		return cardNumber ~= nil and pileNumber ~= nil and cardNumber >= pileNumber
	end
	local top = pileData(pile)
	if pile:GetAttribute("IsStacking") then
		local ok, result = pcall(CanStackCard, pile:GetAttribute("IsStacking"), top, {
			Color = card.Color,
			Symbol = card.Symbol
		}, state.rules or {
			Stacking = true,
			Defense = true
		})
		return ok and result == true
	end
	local ok, result = pcall(CanPlayCard, {
		Color = card.Color,
		Symbol = card.Symbol
	}, top)
	return ok and result == true
end

local function weakestOffer(hand)
	local selected = nil
	local selectedValue = math.huge
	local counts = colorCounts(hand, state.pendingCard)
	for _, card in ipairs(hand) do
		local number = tonumber(card.Symbol)
		local value
		if number then
			value = number * 4 + (counts[card.Color] or 0)
			if card.Symbol == "7" or card.Symbol == "0" then
				value = value + 80
			end
		else
			value = 140
			if card.Symbol == "Event" or card.Symbol == "Auction" or card.Symbol == "Card Star" then
				value = 90
			end
			if string.find(card.Symbol, "Loco", 1, true) then
				value = 220
			end
		end
		if value < selectedValue then
			selected = card
			selectedValue = value
		end
	end
	return selected
end

local function action(key, cooldown, callback)
	local now = os.clock()
	if state.lastActionKey == key and now - state.lastActionAt < cooldown then
		return false
	end
	if now - state.lastActionAt < 0.08 then
		return false
	end
	state.lastActionKey = key
	state.lastActionAt = now
	local ok, err = pcall(callback)
	if not ok then
		notify("LOC AutoPlayer • Error", tostring(err), 5, "action-error:" .. tostring(err), 2)
	end
	return ok
end

local function activate(button)
	if not button then
		return false
	end
	if type(firesignal) == "function" then
		local ok = pcall(firesignal, button.MouseButton1Down)
		if ok then
			return true
		end
	end
	if type(getconnections) == "function" then
		local ok, connections = pcall(getconnections, button.MouseButton1Down)
		if ok then
			for _, connection in ipairs(connections) do
				pcall(function()
					connection:Fire()
				end)
			end
			return true
		end
	end
	return false
end

local function submitColor(pile, hand, players, source, force)
	local now = os.clock()
	if state.colorActive and now - state.lastColorAt < 0.6 then
		return false
	end
	local color, _, reason = bestColor(hand, state.pendingSymbol, pile, players)
	state.colorActive = true
	state.lastColorAt = now
	state.lastColor = color
	state.lastColorReason = reason or ""
	setAction(
		"Choose color: " .. color,
		"LOC AutoPlayer • Color",
		"Source: " .. tostring(source) .. ((reason and reason ~= "") and ("\nReason: " .. reason) or ""),
		4,
		"color:" .. color .. ":" .. tostring(source),
		0.5
	)
	task.delay(0.055, function()
		if not state.enabled then
			return
		end
		if force or Workspace:GetAttribute("PickingColor") then
			pcall(function()
				ChooseColor:FireServer(color)
			end)
		end
	end)
	return true
end

local function handleColor(pile, hand, players)
	if not Workspace:GetAttribute("PickingColor") then
		state.colorActive = false
		return
	end
	if state.colorActive then
		return
	end
	local now = os.clock()
	local granted = state.colorPermissionUntil > now
	local recentOwnWild = isColorPickSymbol(state.pendingSymbol)
		and now - state.lastActionAt < 3
		and tostring(pile:GetAttribute("PreviousTurn")) == tostring(state.seat)
	if granted or recentOwnWild then
		submitColor(pile, hand, players, granted and "remote" or "fallback", false)
	end
end

local function handleButtons(pile, hand, players)
	local container = getContainer()
	if not container then
		return false
	end
	local slap = container:FindFirstChild("SlapButton")
	if (slap and slap.Visible) or pile:GetAttribute("IsSlapping") then
		if not state.slapLatched or os.clock() - state.lastSlapAt > 0.5 then
			state.slapLatched = true
			state.lastSlapAt = os.clock()
			setAction("Slap on 6", "LOC AutoPlayer • Reaction", nil, 2, "slap", 0.8)
			pcall(function()
				SlapOnSix:FireServer()
			end)
		end
	else
		state.slapLatched = false
	end
	local callout = container:FindFirstChild("CalloutButton")
	if callout and callout.Visible then
		if not state.calloutLatched or os.clock() - state.lastCalloutAt > 0.7 then
			state.calloutLatched = true
			state.lastCalloutAt = os.clock()
			setAction("Block final card", "LOC AutoPlayer • Counter", "Calling out UNO", 3, "callout", 0.8)
			pcall(function()
				PlayCard:FireServer("Callout")
			end)
		end
	else
		state.calloutLatched = false
	end
	local official = container:FindFirstChild("OfficialButton")
	if official and official.Visible then
		if not state.officialLatched or os.clock() - state.lastOfficialAt > 0.7 then
			state.officialLatched = true
			state.lastOfficialAt = os.clock()
			setAction("Call Official", "LOC AutoPlayer • Counter", nil, 3, "official", 0.8)
			pcall(function()
				CallOfficial:FireServer()
			end)
		end
	else
		state.officialLatched = false
	end
	local challenge = container:FindFirstChild("ChallengingFrame")
	if challenge and challenge.Visible then
		if not state.challengeLatched then
			state.challengeLatched = true
			local previous = getPlayerBySeat(players, pile:GetAttribute("PreviousTurn"))
			local shouldChallenge = false
			local confidence = "insufficient evidence"
			if previous then
				local challengedColor = state.challengeColor
				local knownCounts, known = knownPlayerColorCounts(state.match, previous.seat, pile)
				if challengedColor and known > 0 and knownCounts[challengedColor] and knownCounts[challengedColor] > 0 then
					shouldChallenge = true
					confidence = "exposed prior-color card"
				elseif challengedColor then
					local profile = opponentProfile(previous.seat)
					local preference = profile.prefer[challengedColor] or 0
					if preference >= 6 then
						shouldChallenge = true
						confidence = "strong prior-color history"
					end
				end
			end
			if shouldChallenge then
				setAction("Challenge draw card", "LOC AutoPlayer • Challenge", "Evidence: " .. confidence, 4, "challenge:" .. confidence, 1)
				pcall(function()
					PlayCard:FireServer("Challenging")
				end)
			else
				setAction("Decline challenge", "LOC AutoPlayer • Challenge", "Evidence too weak; accepting draw", 4, "decline-challenge", 1)
				pcall(function()
					PlayCard:FireServer({
						DrawCard = true
					})
				end)
			end
		end
		return true
	else
		state.challengeLatched = false
	end
	local drawn = container:FindFirstChild("PlayDrawnCard")
	if drawn and drawn.Visible then
		if not state.drawnStartedAt then
			state.drawnStartedAt = os.clock()
			setAction("Play drawn card", "LOC AutoPlayer • Draw", "Drawn card is playable", 3, "play-drawn", 0.8)
			activate(drawn:FindFirstChild("Play"))
		elseif os.clock() - state.drawnStartedAt > 0.65 then
			setAction("Keep drawn card", "LOC AutoPlayer • Draw", "No legal follow-up", 3, "keep-drawn", 0.8)
			activate(drawn:FindFirstChild("Keep"))
			state.drawnStartedAt = os.clock() + 2
		end
		return true
	else
		state.drawnStartedAt = nil
	end
	return false
end

local function handleOffer(pile, hand)
	local choosing = pile:GetAttribute("IsChoosingCard")
	if choosing ~= nil and tostring(choosing) == tostring(state.seat) then
		if not state.choosingLatched then
			local card = weakestOffer(hand)
			if card then
				state.choosingLatched = true
				state.pendingSymbol = state.pendingSymbol or "Donate"
				setAction("Offer card: " .. card.Color .. "/" .. card.Symbol, "LOC AutoPlayer • Donate", "Offering lowest-value card", 4, "offer:" .. card.Color .. ":" .. card.Symbol, 0.8)
				pcall(function()
					PlayCard:FireServer({ "OfferCard", card.Attributes })
				end)
			end
		end
		return true
	else
		state.choosingLatched = false
	end
	if pile:GetAttribute("IsAuctioning") then
		if not state.auctionLatched then
			local card = weakestOffer(hand)
			if card then
				state.auctionLatched = true
				state.pendingSymbol = "Auction"
				setAction("Auction bid: " .. card.Color .. "/" .. card.Symbol, "LOC AutoPlayer • Auction", "Bidding lowest-value card", 4, "auction:" .. card.Color .. ":" .. card.Symbol, 0.8)
				pcall(function()
					PlayCard:FireServer({ "OfferCard", card.Attributes })
				end)
			end
		end
		return true
	else
		state.auctionLatched = false
	end
	return false
end

local function chooseAndPlay(pile, hand, players)
	if tostring(pile:GetAttribute("CurrentTurn")) ~= tostring(state.seat) then
		local hasJump = false
		for _, card in ipairs(hand) do
			if canPlay(pile, card) then
				hasJump = true
				break
			end
		end
		if not hasJump then
			return
		end
	end
	local best = nil
	local bestScore = -math.huge
	local bestReason = ""
	for _, card in ipairs(hand) do
		if canPlay(pile, card) then
			local score, reason = scoreCard(card, hand, players, pile)
			if score > bestScore then
				best = card
				bestScore = score
				bestReason = reason
			end
		end
	end
	if best then
		local key = table.concat({
			pile.Name,
			tostring(pile:GetAttribute("CurrentTurn")),
			tostring(pile:GetAttribute("Color")),
			tostring(pile:GetAttribute("Symbol")),
			tostring(#hand),
			best.Color,
			best.Symbol
		}, ":")
		action(key, 0.55, function()
			state.pendingSymbol = best.Symbol
			state.pendingCard = best.Instance
			state.lastScore = bestScore
			state.lastDecision = bestReason
			setAction(
				"Play: " .. best.Color .. "/" .. best.Symbol,
				"LOC AutoPlayer • Play",
				"Score: " .. string.format("%.1f", bestScore) .. ((bestReason ~= "") and ("\nReason: " .. bestReason) or ""),
				4,
				"play:" .. key,
				0.5
			)
			PlayCard:FireServer(best.Attributes)
		end)
		return
	end
	if tostring(pile:GetAttribute("CurrentTurn")) == tostring(state.seat) then
		local key = table.concat({
			"draw",
			pile.Name,
			tostring(pile:GetAttribute("Color")),
			tostring(pile:GetAttribute("Symbol")),
			tostring(#hand)
		}, ":")
		action(key, 0.7, function()
			state.lastScore = 0
			state.lastDecision = "no playable card"
			setAction("Draw card", "LOC AutoPlayer • Draw", "No playable card", 3, "draw:" .. key, 0.5)
			PlayCard:FireServer({
				DrawCard = true
			})
		end)
	end
end

local function step()
	if not state.enabled then
		return
	end
	local match, seat = findMatch()
	if state.match ~= match then
		state.opponentModel = {}
		state.snapshot = nil
		state.lastObservedWildKey = ""
		state.challengeColor = nil
	end
	state.match = match
	state.seat = seat or state.seat
	if not match or not state.seat then
		setAction("Waiting for match", "LOC AutoPlayer", "No active match detected", 2, "waiting-match", 8)
		return
	end
	refreshContext(match, state.seat)
	local hand = getHand(match)
	local players = getPlayers(match, state.seat, #hand)
	updateOpponentModel(match, players)
	handleColor(match, hand, players)
	if handleButtons(match, hand, players) then
		return
	end
	if handleOffer(match, hand) then
		return
	end
	chooseAndPlay(match, hand, players)
end

connect(ChoiceArrows.OnClientEvent, function(folder)
	if not state.enabled or state.choiceActive or typeof(folder) ~= "Instance" then
		return
	end
	state.choiceActive = true
	task.delay(0.08, function()
		if not state.enabled or not folder.Parent then
			state.choiceActive = false
			return
		end
		local match, seat = findMatch()
		state.match = match
		state.seat = seat or state.seat
		local hand = match and getHand(match) or {}
		local players = match and getPlayers(match, state.seat, #hand) or {}
		local symbol = state.pendingSymbol or (match and tostring(match:GetAttribute("Symbol"))) or ""
		local target = pickTarget(symbol, players)
		local selected = nil
		if target then
			for _, child in ipairs(folder:GetChildren()) do
				if child.Name == target.name or child.Name == target.seat or string.find(child.Name, target.name, 1, true) then
					selected = child
					break
				end
			end
		end
		if not selected then
			for _, child in ipairs(folder:GetChildren()) do
				if child.Name ~= LocalPlayer.Name and child.Name ~= tostring(state.seat) then
					selected = child
					break
				end
			end
		end
		if not selected then
			selected = folder:GetChildren()[1]
		end
		if selected then
			state.lastTarget = selected.Name
			setAction(
				"Choose target: " .. selected.Name,
				"LOC AutoPlayer • Target",
				"Card: " .. tostring(symbol),
				4,
				"target:" .. tostring(symbol) .. ":" .. selected.Name,
				0.5
			)
			pcall(function()
				ChoosePlayer:FireServer(selected.Name)
			end)
		end
		task.delay(0.5, function()
			state.choiceActive = false
		end)
	end)
end)

connect(ChooseColor.OnClientEvent, function(wildType, canChoose)
	if canChoose == false or not state.enabled then
		return
	end
	state.colorPermissionUntil = os.clock() + 2
	local match, seat = findMatch()
	state.match = match or state.match
	state.seat = seat or state.seat
	local hand = state.match and getHand(state.match) or {}
	local players = state.match and getPlayers(state.match, state.seat, #hand) or {}
	if not isColorPickSymbol(state.pendingSymbol) then
		local map = {
			WildCard = "Loco 8",
			WildCardInverted = "Loco 8 (Inverted)",
			DrawTilWild = "Draw Til Loco",
			SmiteCard = "Loco Smite +4",
			FourPlusCard = "Loco +5 - 1"
		}
		state.pendingSymbol = map[tostring(wildType)] or state.pendingSymbol
	end
	submitColor(state.match, hand, players, "choice-event", true)
end)

connect(ChosenColor.OnClientEvent, function()
	state.colorActive = false
	state.colorPermissionUntil = 0
end)

connect(ClientCards.ChildAdded, function()
	task.defer(step)
end)

connect(ClientCards.ChildRemoved, function(card)
	if state.pendingCard == card then
		state.pendingCard = nil
	end
	task.defer(step)
end)

state.Stop = function()
	notify("LOC AutoPlayer", "Autoplayer stopped", 2, "stopped", 0)
	state.enabled = false
	for _, connection in ipairs(state.connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(state.connections)
end

task.spawn(function()
	while state.enabled do
		local ok, err = pcall(step)
		if not ok then
			notify("LOC AutoPlayer • Error", tostring(err), 5, "step-error:" .. tostring(err), 2)
		end
		task.wait(0.08)
	end
end)

notify("LOC AutoPlayer", state.version .. " loaded\nDebug notifications enabled", 4, "loaded", 0)
step()
