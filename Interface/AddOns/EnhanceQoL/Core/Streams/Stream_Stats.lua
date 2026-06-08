-- luacheck: globals EnhanceQoL STAT_HASTE STAT_MASTERY STAT_CRITICAL_STRIKE CR_HASTE_MELEE CR_MASTERY CR_CRIT_MELEE CR_LIFESTEAL CR_BLOCK CR_PARRY CR_DODGE CR_AVOIDANCE CR_SPEED STAT_LIFESTEAL STAT_BLOCK STAT_PARRY STAT_DODGE STAT_AVOIDANCE STAT_SPEED GetLifesteal GetBlockChance GetParryChance GetDodgeChance GetAvoidance GetSpeed
local addonName, addon = ...
local L = addon.L

local db

local idx
local primaryResolveToken = 0

local PRIMARY_RESOLVE_DELAY = 0.5
local PRIMARY_RESOLVE_ATTEMPTS = 12

local STR = LE_UNIT_STAT_STRENGTH
local AGI = LE_UNIT_STAT_AGILITY
local INT = LE_UNIT_STAT_INTELLECT

local NAMES = {
	[STR] = ITEM_MOD_STRENGTH_SHORT, -- "Strength" (lokalisiert)
	[AGI] = ITEM_MOD_AGILITY_SHORT, -- "Agility"
	[INT] = ITEM_MOD_INTELLECT_SHORT, -- "Intellect"
}

local PRIMARY_TOKENS = {
	[STR] = "STRENGTH",
	[AGI] = "AGILITY",
	[INT] = "INTELLECT",
}

local STAT_TOKENS = {
	haste = "HASTE",
	mastery = "MASTERY",
	crit = "CRITCHANCE",
	lifesteal = "LIFESTEAL",
	block = "BLOCK",
	parry = "PARRY",
	dodge = "DODGE",
	avoidance = "AVOIDANCE",
	speed = "SPEED",
}

local FALLBACK_ORDER = {
	primary = 1,
	haste = 2,
	mastery = 3,
	crit = 4,
	lifesteal = 5,
	block = 6,
	parry = 7,
	dodge = 8,
	avoidance = 9,
	speed = 10,
}

local VALID_DISPLAY_MODE = {
	percent = true,
	rating = true,
	both = true,
}

local SECONDARY_STATS = {
	"haste",
	"mastery",
	"crit",
	"lifesteal",
	"block",
	"parry",
	"dodge",
	"avoidance",
	"speed",
}

local SUPPORTS_SECONDARY_PERCENT = {
	mastery = true,
}

local STAT_DEFAULT_COLORS = {
	primary = { r = 1, g = 0.82, b = 0, a = 1 },
	haste = { r = 0.31, g = 0.86, b = 0.43, a = 1 },
	mastery = { r = 0.62, g = 0.56, b = 1, a = 1 },
	crit = { r = 1, g = 0.36, b = 0.28, a = 1 },
	lifesteal = { r = 0.35, g = 0.85, b = 0.88, a = 1 },
	block = { r = 0.95, g = 0.67, b = 0.25, a = 1 },
	parry = { r = 0.86, g = 0.52, b = 1, a = 1 },
	dodge = { r = 0.58, g = 0.95, b = 0.42, a = 1 },
	avoidance = { r = 0.48, g = 0.72, b = 1, a = 1 },
	speed = { r = 0.38, g = 0.92, b = 1, a = 1 },
}

local function normalizeMode(mode)
	if VALID_DISPLAY_MODE[mode] then return mode end
	return "percent"
end

local function copyDefaultColor(key)
	local color = STAT_DEFAULT_COLORS[key] or STAT_DEFAULT_COLORS.primary
	return { r = color.r, g = color.g, b = color.b, a = color.a or 1 }
end

local function isDefaultWhite(color)
	return type(color) == "table" and color.r == 1 and color.g == 1 and color.b == 1 and (color.a == nil or color.a == 1)
end

local function formatNumber(value)
	if not value then return nil end
	-- local intValue = math.floor(value + 0.5)
	return BreakUpLargeNumbers(value)
	-- if BreakUpLargeNumbers then
	-- 	local ok, result = pcall(BreakUpLargeNumbers, value)
	-- 	if ok and result then return result end
	-- end
	-- local str = tostring(intValue)
	-- local sign = ""
	-- if str:sub(1, 1) == "-" then
	-- 	sign = "-"
	-- 	str = str:sub(2)
	-- end
	-- local formatted = str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	-- return sign .. formatted
end

local function formatPercent(value)
	if value == nil then return nil end
	local txt = ("%.2f"):format(value)
	-- txt = txt:gsub("(%..-)0+$", "%1")
	-- txt = txt:gsub("%.$", "")
	return txt .. "%"
end

local function formatStatText(label, mode, ratingValue, percentValue, secondaryPercent, showSecondaryPercent)
	mode = normalizeMode(mode)
	local ratingText = ratingValue and formatNumber(ratingValue)
	local percentText = percentValue and formatPercent(percentValue)
	local secondaryPercentText = showSecondaryPercent ~= false and secondaryPercent and formatPercent(secondaryPercent)

	if not ratingText and not percentText and not secondaryPercentText then return nil end

	if mode == "rating" then
		if ratingText then return ("%s: %s"):format(label, ratingText) end
		if percentText then return ("%s: %s"):format(label, percentText) end
		if secondaryPercentText then return ("%s: %s"):format(label, secondaryPercentText) end
		return nil
	elseif mode == "both" then
		if secondaryPercentText then
			local percentCombo = percentText and ("%s/%s"):format(percentText, secondaryPercentText) or secondaryPercentText
			if ratingText and percentCombo then return ("%s: %s - %s"):format(label, ratingText, percentCombo) end
			return ("%s: %s"):format(label, ratingText or percentCombo)
		else
			if ratingText and percentText then return ("%s: %s - %s"):format(label, ratingText, percentText) end
			return ("%s: %s"):format(label, ratingText or percentText)
		end
	else -- percent
		if secondaryPercentText then
			if percentText then return ("%s: %s/%s"):format(label, percentText, secondaryPercentText) end
			return ("%s: %s"):format(label, secondaryPercentText)
		end
		if percentText then return ("%s: %s"):format(label, percentText) end
		if ratingText then return ("%s: %s"):format(label, ratingText) end
		return nil
	end
end

local function isPrimaryStatIndex(statIndex)
	return statIndex == STR or statIndex == AGI or statIndex == INT
end

local function GetPlayerPrimaryStatIndex()
	local spec = C_SpecializationInfo.GetSpecialization()
	if spec then
		-- Matches Blizzard's PaperDollFrame primary stat lookup for the active specialization.
		local primaryStat = select(6, C_SpecializationInfo.GetSpecializationInfo(spec, false, false, nil, UnitSex("player")))
		if isPrimaryStatIndex(primaryStat) then return primaryStat end
	end
	if isPrimaryStatIndex(idx) then return idx end
	return nil
end

local function GetPlayerPrimaryStat()
	local primaryIndex = GetPlayerPrimaryStatIndex()
	if not isPrimaryStatIndex(primaryIndex) then return nil, nil, "Primary", nil end
	idx = primaryIndex
	local base, effective = UnitStat("player", primaryIndex) -- effective enthält Buffs
	return (effective or base), primaryIndex, (NAMES[primaryIndex] or "Primary"), PRIMARY_TOKENS[primaryIndex]
end

local function SchedulePrimaryStatRefresh(streamRef, attempts, delay)
	primaryResolveToken = primaryResolveToken + 1
	local token = primaryResolveToken
	local remaining = attempts or PRIMARY_RESOLVE_ATTEMPTS
	local retryDelay = delay or PRIMARY_RESOLVE_DELAY

	local function tryResolve()
		if token ~= primaryResolveToken then return end
		local primaryIndex = GetPlayerPrimaryStatIndex()
		if isPrimaryStatIndex(primaryIndex) then
			idx = primaryIndex
			addon.DataHub:RequestUpdate(streamRef)
			return
		end
		if remaining <= 0 then return end
		remaining = remaining - 1
		C_Timer.After(retryDelay, tryResolve)
	end

	tryResolve()
end

local function getPaperdollStatOrder()
	local order = {}
	local categories = PAPERDOLL_STATCATEGORIES
	if not categories then return order end

	local index = 1
	for _, category in ipairs(categories) do
		local stats = category and category.stats
		if stats then
			for _, entry in ipairs(stats) do
				local token
				if type(entry) == "table" then
					token = entry.stat
				else
					token = entry
				end
				if token and order[token] == nil then
					order[token] = index
					index = index + 1
				end
			end
		end
	end

	return order
end

local function getOptionsHint()
	if addon.DataPanel and addon.DataPanel.GetOptionsHintText then
		local text = addon.DataPanel.GetOptionsHintText()
		if text ~= nil then return text end
		return nil
	end
	return L["Right-Click for options"]
end

local function ensureStatEntry(key, supportsMode, supportsSecondaryPercent)
	db[key] = db[key] or {}
	local entry = db[key]
	if entry.enabled == nil then entry.enabled = true end
	if supportsMode then
		if entry.mode == nil then
			if entry.rating ~= nil then
				entry.mode = entry.rating and "rating" or "percent"
			else
				entry.mode = "percent"
			end
		end
		entry.mode = normalizeMode(entry.mode)
	else
		entry.mode = nil
	end
	if supportsSecondaryPercent then
		if entry.showSecondaryPercent == nil then entry.showSecondaryPercent = true end
	else
		entry.showSecondaryPercent = nil
	end
	entry.rating = nil
	if type(entry.color) ~= "table" or isDefaultWhite(entry.color) then
		entry.color = copyDefaultColor(key)
	end
end

local function ensureDB()
	addon.db.datapanel = addon.db.datapanel or {}
	addon.db.datapanel.stats = addon.db.datapanel.stats or {}
	db = addon.db.datapanel.stats
	db.fontSize = db.fontSize or 14
	db.vertical = db.vertical or false
	db.primary = db.primary or {}
	if db.primary.enabled == nil then db.primary.enabled = true end
	ensureStatEntry("primary", false, false)

	for _, key in ipairs(SECONDARY_STATS) do
		ensureStatEntry(key, true, SUPPORTS_SECONDARY_PERCENT[key] == true)
	end
end

local function openSettings()
	if addon.functions and addon.functions.OpenConfigCenter then
		addon.functions.OpenConfigCenter("interface.datapanel", "DataPanel_stats_fontSize")
	end
end

local function colorize(text, color)
	if color and color.r and color.g and color.b then return ("|cff%02x%02x%02x%s|r"):format(color.r * 255, color.g * 255, color.b * 255, text) end
	return text
end

local function checkStats(stream)
	ensureDB()
	local sep = db.vertical and "\n" or " "
	local size = db.fontSize or 14
	stream.snapshot.fontSize = size
	stream.snapshot.tooltip = getOptionsHint()
	stream.snapshot.text = nil
	stream.snapshot.textFormat = nil
	stream.snapshot.textArgs = nil
	stream.snapshot.parts = nil
	stream.snapshot.partsLayout = nil
	stream.snapshot.partSpacing = nil
	stream.snapshot.skipPanelClassColor = true

	local orderMap = getPaperdollStatOrder()
	local entries = {}

	local function push(key, token, text, color)
		if not text then return end
		entries[#entries + 1] = {
			sort = token and orderMap[token] or nil,
			fallback = FALLBACK_ORDER[key] or (#entries + 100),
			text = colorize(text, color),
		}
	end

	local function emitStat(key, token, label, ratingValue, percentValue, extraPercentValue)
		local cfg = db[key]
		if not cfg or not cfg.enabled then return end
		local text = formatStatText(label, cfg.mode or "percent", ratingValue, percentValue, extraPercentValue, cfg.showSecondaryPercent)
		push(key, token, text, cfg.color)
	end

	local primaryValue, _, primaryName, primaryToken = GetPlayerPrimaryStat()
	if db.primary.enabled and primaryValue ~= nil then
		local formattedPrimary = formatNumber(primaryValue) or (primaryValue ~= nil and tostring(primaryValue) or "")
		push("primary", primaryToken, ("%s: %s"):format(primaryName, formattedPrimary), db.primary.color)
	elseif db.primary.enabled and not isPrimaryStatIndex(idx) then
		SchedulePrimaryStatRefresh(stream, 2, 0.25)
	end

	emitStat("haste", STAT_TOKENS.haste, STAT_HASTE or "Haste", GetCombatRating(CR_HASTE_MELEE), GetHaste())
	emitStat("mastery", STAT_TOKENS.mastery, STAT_MASTERY or "Mastery", GetCombatRating(CR_MASTERY), GetMasteryEffect())
	-- 12.0.5: Versatility combines multiple secret-backed stat APIs and is omitted here to avoid restricted-state taint/errors.
	emitStat("crit", STAT_TOKENS.crit, STAT_CRITICAL_STRIKE or "Crit", GetCombatRating(CR_CRIT_MELEE), GetCritChance())
	emitStat("lifesteal", STAT_TOKENS.lifesteal, STAT_LIFESTEAL or "Leech", GetCombatRating(CR_LIFESTEAL), GetLifesteal())
	emitStat("block", STAT_TOKENS.block, STAT_BLOCK or "Block", GetCombatRating(CR_BLOCK), GetBlockChance())
	emitStat("parry", STAT_TOKENS.parry, STAT_PARRY or "Parry", GetCombatRating(CR_PARRY), GetParryChance())
	emitStat("dodge", STAT_TOKENS.dodge, STAT_DODGE or "Dodge", GetCombatRating(CR_DODGE), GetDodgeChance())
	emitStat("avoidance", STAT_TOKENS.avoidance, STAT_AVOIDANCE or "Avoidance", GetCombatRating(CR_AVOIDANCE), GetAvoidance())
	emitStat("speed", STAT_TOKENS.speed, STAT_SPEED or "Speed", GetCombatRating(CR_SPEED), GetSpeed())

	table.sort(entries, function(a, b)
		local aOrder = a.sort or a.fallback
		local bOrder = b.sort or b.fallback
		if aOrder == bOrder then return a.fallback < b.fallback end
		return aOrder < bOrder
	end)

	local texts = {}
	local placeholders = {}
	for i, entry in ipairs(entries) do
		texts[i] = entry.text
		placeholders[i] = "%s"
	end

	if #texts == 0 then return end

	stream.snapshot.textFormat = table.concat(placeholders, sep)
	stream.snapshot.textArgs = texts
end

local provider = {
	id = "stats",
	version = 4,
	title = PET_BATTLE_STATS_LABEL,
	update = checkStats,
	events = {
		COMBAT_RATING_UPDATE = function(stream) addon.DataHub:RequestUpdate(stream) end,
		MASTERY_UPDATE = function(stream) addon.DataHub:RequestUpdate(stream) end,
		PLAYER_EQUIPMENT_CHANGED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		PLAYER_TALENT_UPDATE = function(stream) addon.DataHub:RequestUpdate(stream) end,
		ACTIVE_TALENT_GROUP_CHANGED = function(stream) addon.DataHub:RequestUpdate(stream) end,
		UPDATE_SHAPESHIFT_FORM = function(stream) addon.DataHub:RequestUpdate(stream) end,
		PLAYER_ENTERING_WORLD = function(stream)
			SchedulePrimaryStatRefresh(stream)
			addon.DataHub:RequestUpdate(stream)
		end,
		PLAYER_LOGIN = function(stream)
			SchedulePrimaryStatRefresh(stream)
			addon.DataHub:RequestUpdate(stream)
		end,
		PLAYER_SPECIALIZATION_CHANGED = function(stream, _, unit)
			if unit and unit ~= "player" then return end
			SchedulePrimaryStatRefresh(stream)
			addon.DataHub:RequestUpdate(stream)
		end,
		ACTIVE_PLAYER_SPECIALIZATION_CHANGED = function(stream)
			SchedulePrimaryStatRefresh(stream)
			addon.DataHub:RequestUpdate(stream)
		end,
		TRAIT_CONFIG_UPDATED = function(stream)
			SchedulePrimaryStatRefresh(stream, 4, 0.25)
			addon.DataHub:RequestUpdate(stream)
		end,
	},
	eventsUnit = {
		player = {
			UNIT_SPELL_HASTE = true,
			UNIT_ATTACK_SPEED = true,
			UNIT_STATS = true,
			UNIT_AURA = function(stream)
				C_Timer.After(0.5, function() addon.DataHub:RequestUpdate(stream) end)
			end,
		},
	},
	OnClick = function(_, btn)
		if btn == "RightButton" then openSettings() end
	end,
}

EnhanceQoL.DataHub.RegisterStream(provider)

return provider
