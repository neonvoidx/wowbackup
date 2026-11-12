local addonName, addon = ...

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local issecretvalue = _G.issecretvalue
local UnitThreatLeadSituation = _G.UnitThreatLeadSituation

---- REGION Functions
local timeoutReleaseDifficultyLookup = {}

local cChar = addon.SettingsLayout.rootGAMEPLAY
addon.SettingsLayout.characterInspectCategory = cChar
local data

local COMBAT_LOG_DIFFICULTY_DB_KEYS = {
	dungeon = "combatLogDungeonDifficulties",
	raid = "combatLogRaidDifficulties",
}
local COMBAT_LOG_TOGGLE_DB_KEYS = {
	pvp = "combatLogPvp",
	scenario = "combatLogScenario",
}
local COMBAT_LOG_DELAY_SECONDS = 30
local CURRENT_EXPANSION_RAID_INSTANCE_CACHE
local combatLogInstanceMap = {
	party = "dungeon",
	raid = "raid",
	pvp = "pvp",
	arena = "pvp",
	scenario = "scenario",
}
local NAMEPLATE_MOB_COLORS_DB_KEY = "nameplateMobColors"
local NAMEPLATE_MOB_COLORS_DUNGEONS_DB_KEY = "nameplateMobColorsInDungeons"
local NAMEPLATE_MOB_COLORS_OUTSIDE_DUNGEONS_DB_KEY = "nameplateMobColorsOutsideDungeons"
local NAMEPLATE_SLUG_OUTLINE_DB_KEY = "nameplateSlugOutline"
local NAMEPLATE_TEXT_CUSTOM_FONT_DB_KEY = "nameplateTextCustomFont"
local NAMEPLATE_TEXT_FONT_DB_KEY = "nameplateTextFont"
local NAMEPLATE_TEXT_OUTLINE_DB_KEY = "nameplateTextOutline"
local NAMEPLATE_TEXT_SIZE_DB_KEY = "nameplateTextSize"
local NAMEPLATE_CAST_TEXT_SIZE_DB_KEY = "nameplateCastTextSize"
local NAMEPLATE_ELITE_MARKERS_DB_KEY = "nameplateEliteMarkers"
local NAMEPLATE_ELITE_MARKER_ANCHOR_DB_KEY = "nameplateEliteMarkerAnchor"
local NAMEPLATE_ELITE_MARKER_SIZE_DB_KEY = "nameplateEliteMarkerSize"
local NAMEPLATE_QUEST_MARKERS_DB_KEY = "nameplateQuestMarkers"
local NAMEPLATE_QUEST_MARKER_ANCHOR_DB_KEY = "nameplateQuestMarkerAnchor"
local NAMEPLATE_QUEST_MARKER_SIZE_DB_KEY = "nameplateQuestMarkerSize"
local NAMEPLATE_TARGET_MARKERS_DB_KEY = "nameplateTargetMarkers"
local NAMEPLATE_TARGET_MARKER_ATLAS_DB_KEY = "nameplateTargetMarkerAtlas"
local NAMEPLATE_TARGET_MARKER_SIZE_DB_KEY = "nameplateTargetMarkerSize"
local NAMEPLATE_HEALTHBAR_TEXTURE_DB_KEY = "nameplateHealthbarTexture"
local NAMEPLATE_FOCUS_HEALTHBAR_TEXTURE_DB_KEY = "nameplateFocusHealthbarTexture"
local NAMEPLATE_MOB_COLOR_FOCUS_DB_KEY = "nameplateMobColorFocus"
local NAMEPLATE_MOB_COLOR_BOSS_DB_KEY = "nameplateMobColorBoss"
local NAMEPLATE_MOB_COLOR_MINIBOSS_DB_KEY = "nameplateMobColorMiniboss"
local NAMEPLATE_MOB_COLOR_CASTER_DB_KEY = "nameplateMobColorCaster"
local NAMEPLATE_MOB_COLOR_MELEE_DB_KEY = "nameplateMobColorMelee"
local NAMEPLATE_MOB_COLOR_NEUTRAL_DB_KEY = "nameplateMobColorNeutral"
local NAMEPLATE_MOB_COLOR_TANK_MODE_DB_KEY = "nameplateMobColorTankMode"
local NAMEPLATE_MOB_COLOR_THREAT_LOST_DB_KEY = "nameplateMobColorThreatLost"
local NAMEPLATE_MOB_COLOR_THREAT_WARNING_DB_KEY = "nameplateMobColorThreatWarning"
local NAMEPLATE_MOB_COLOR_TRIVIAL_DB_KEY = "nameplateMobColorTrivial"
local NAMEPLATE_MOB_TANK_MODE_DB_KEY = "nameplateMobTankMode"
local nameplateMobColorFrame
local nameplateMobColorHooksInstalled = false
local nameplateHealthbarTextureHookInstalled = false
local nameplateMobColorsActive = false
local nameplateEliteMarkersActive = false
local nameplateQuestMarkersActive = false
local nameplateTargetMarkersActive = false
local nameplateTargetMarkerLastUnit
local nameplateHealthbarTextureActive = false
local nameplateFocusHealthbarTextureActive = false
local nameplateFocusHealthbarTextureLastUnit
local nameplateQuestMarkersByUnitFrame = setmetatable({}, { __mode = "k" })
local nameplateEliteMarkersByUnitFrame = setmetatable({}, { __mode = "k" })
local nameplateTargetLeftMarkersByUnitFrame = setmetatable({}, { __mode = "k" })
local nameplateTargetRightMarkersByUnitFrame = setmetatable({}, { __mode = "k" })
local nameplateFocusHealthbarDefaults = setmetatable({}, { __mode = "k" })
local nameplateQuestMarkerCache = {}
local nameplateMobColorState = {
	otherTanksDirty = true,
	appliedColors = setmetatable({}, { __mode = "k" }),
	isActive = false,
	isDirty = true,
	instanceType = "none",
	zonePvpType = nil,
	lastLFGInstanceID = nil,
	isInstancedPve = false,
	isAllowed = false,
	referenceLevel = nil,
	lieutenantLevel = nil,
}
local function buildNameplateColorDefault(colorSource, fallbackR, fallbackG, fallbackB)
	if type(colorSource) == "table" then
		if type(colorSource.GetRGBA) == "function" then
			local r, g, b, a = colorSource:GetRGBA()
			if type(r) == "number" and type(g) == "number" and type(b) == "number" then return { r = r, g = g, b = b, a = type(a) == "number" and a or 1 } end
		end

		local r = issecretvalue(colorSource.r) and nil or colorSource.r
		local g = issecretvalue(colorSource.g) and nil or colorSource.g
		local b = issecretvalue(colorSource.b) and nil or colorSource.b
		local a = issecretvalue(colorSource.a) and nil or colorSource.a
		if type(r) == "number" and type(g) == "number" and type(b) == "number" then return { r = r, g = g, b = b, a = type(a) == "number" and a or 1 } end
	end

	return { r = fallbackR, g = fallbackG, b = fallbackB, a = 1 }
end

local NAMEPLATE_MOB_COLOR_DEFAULTS = {
	[NAMEPLATE_MOB_COLOR_FOCUS_DB_KEY] = { r = 1, g = 0, b = 1, a = 1 },
	[NAMEPLATE_MOB_COLOR_BOSS_DB_KEY] = { r = 188 / 255, g = 28 / 255, b = 0 / 255, a = 1 },
	[NAMEPLATE_MOB_COLOR_MINIBOSS_DB_KEY] = { r = 144 / 255, g = 0 / 255, b = 188 / 255, a = 1 },
	[NAMEPLATE_MOB_COLOR_CASTER_DB_KEY] = { r = 0 / 255, g = 116 / 255, b = 188 / 255, a = 1 },
	[NAMEPLATE_MOB_COLOR_MELEE_DB_KEY] = { r = 252 / 255, g = 252 / 255, b = 252 / 255, a = 1 },
	[NAMEPLATE_MOB_COLOR_NEUTRAL_DB_KEY] = buildNameplateColorDefault(_G.FACTION_BAR_COLORS and _G.FACTION_BAR_COLORS[4], 1, 1, 0),
	nameplateMobColorQuestNeutral = { r = 1, g = 0.65, b = 0.2, a = 1 },
	nameplateMobColorQuestHostile = { r = 1, g = 0.3, b = 0.65, a = 1 },
	nameplateMobColorTapped = { r = 0.9, g = 0.9, b = 0.9, a = 1 },
	[NAMEPLATE_MOB_COLOR_TANK_MODE_DB_KEY] = { r = 0.15, g = 0.85, b = 1, a = 1 },
	[NAMEPLATE_MOB_COLOR_THREAT_LOST_DB_KEY] = buildNameplateColorDefault(_G.ORANGE_THREAT_COLOR, 1, 0.6, 0),
	["nameplateMobColorOtherTank"] = { r = 0.2, g = 0.6, b = 1, a = 1 },
	[NAMEPLATE_MOB_COLOR_THREAT_WARNING_DB_KEY] = buildNameplateColorDefault(_G.YELLOW_THREAT_COLOR, 1, 1, 0),
	[NAMEPLATE_MOB_COLOR_TRIVIAL_DB_KEY] = { r = 178 / 255, g = 142 / 255, b = 85 / 255, a = 1 },
}
addon.constants = addon.constants or {}
addon.constants.DEFAULT_NAMEPLATE_FEATURE_KEYS = {
	slugOutline = NAMEPLATE_SLUG_OUTLINE_DB_KEY,
	textCustomFont = NAMEPLATE_TEXT_CUSTOM_FONT_DB_KEY,
	textFont = NAMEPLATE_TEXT_FONT_DB_KEY,
	textOutline = NAMEPLATE_TEXT_OUTLINE_DB_KEY,
	textSize = NAMEPLATE_TEXT_SIZE_DB_KEY,
	castTextSize = NAMEPLATE_CAST_TEXT_SIZE_DB_KEY,
	eliteMarkers = NAMEPLATE_ELITE_MARKERS_DB_KEY,
	eliteMarkerAnchor = NAMEPLATE_ELITE_MARKER_ANCHOR_DB_KEY,
	eliteMarkerSize = NAMEPLATE_ELITE_MARKER_SIZE_DB_KEY,
	eliteMarkerOffsetX = "nameplateEliteMarkerOffsetX",
	eliteMarkerOffsetY = "nameplateEliteMarkerOffsetY",
	mobColors = NAMEPLATE_MOB_COLORS_DB_KEY,
	mobColorsInDungeons = NAMEPLATE_MOB_COLORS_DUNGEONS_DB_KEY,
	mobColorsOutsideDungeons = NAMEPLATE_MOB_COLORS_OUTSIDE_DUNGEONS_DB_KEY,
	questMarkers = NAMEPLATE_QUEST_MARKERS_DB_KEY,
	questMarkerAnchor = NAMEPLATE_QUEST_MARKER_ANCHOR_DB_KEY,
	questMarkerSize = NAMEPLATE_QUEST_MARKER_SIZE_DB_KEY,
	questMarkerOffsetX = "nameplateQuestMarkerOffsetX",
	questMarkerOffsetY = "nameplateQuestMarkerOffsetY",
	targetMarkers = NAMEPLATE_TARGET_MARKERS_DB_KEY,
	targetMarkerAtlas = NAMEPLATE_TARGET_MARKER_ATLAS_DB_KEY,
	targetMarkerHideFriendly = "nameplateTargetMarkerHideFriendly",
	targetMarkerSize = NAMEPLATE_TARGET_MARKER_SIZE_DB_KEY,
	healthbarTexture = NAMEPLATE_HEALTHBAR_TEXTURE_DB_KEY,
	focusHealthbarTexture = NAMEPLATE_FOCUS_HEALTHBAR_TEXTURE_DB_KEY,
	mobColorFocus = NAMEPLATE_MOB_COLOR_FOCUS_DB_KEY,
	mobColorFocusEnabled = "nameplateMobColorFocusEnabled",
	mobColorBoss = NAMEPLATE_MOB_COLOR_BOSS_DB_KEY,
	mobColorBossEnabled = "nameplateMobColorBossEnabled",
	mobColorMiniboss = NAMEPLATE_MOB_COLOR_MINIBOSS_DB_KEY,
	mobColorMinibossEnabled = "nameplateMobColorMinibossEnabled",
	mobColorCaster = NAMEPLATE_MOB_COLOR_CASTER_DB_KEY,
	mobColorCasterEnabled = "nameplateMobColorCasterEnabled",
	mobColorMelee = NAMEPLATE_MOB_COLOR_MELEE_DB_KEY,
	mobColorMeleeEnabled = "nameplateMobColorMeleeEnabled",
	mobColorNeutral = NAMEPLATE_MOB_COLOR_NEUTRAL_DB_KEY,
	mobColorNeutralEnabled = "nameplateMobColorNeutralEnabled",
	mobColorTapped = "nameplateMobColorTapped",
	mobColorTappedEnabled = "nameplateMobColorTappedEnabled",
	mobColorTankMode = NAMEPLATE_MOB_COLOR_TANK_MODE_DB_KEY,
	mobColorThreatLost = NAMEPLATE_MOB_COLOR_THREAT_LOST_DB_KEY,
	mobColorThreatLostEnabled = "nameplateMobColorThreatLostEnabled",
	mobColorOtherTank = "nameplateMobColorOtherTank",
	mobColorOtherTankEnabled = "nameplateMobColorOtherTankEnabled",
	mobColorThreatWarning = NAMEPLATE_MOB_COLOR_THREAT_WARNING_DB_KEY,
	mobColorThreatWarningEnabled = "nameplateMobColorThreatWarningEnabled",
	mobColorTrivial = NAMEPLATE_MOB_COLOR_TRIVIAL_DB_KEY,
	mobColorTrivialEnabled = "nameplateMobColorTrivialEnabled",
	mobTankMode = NAMEPLATE_MOB_TANK_MODE_DB_KEY,
}
local DIFFICULTY_IDS = (_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}
local COMBAT_LOG_DIFFICULTY_GROUPS = {
	dungeon = {
		{ key = "normal", text = PLAYER_DIFFICULTY1, difficulties = { DIFFICULTY_IDS.DungeonNormal or 1, 150, 216 } },
		{ key = "heroic", text = PLAYER_DIFFICULTY2, difficulties = { DIFFICULTY_IDS.DungeonHeroic or 2 } },
		{ key = "mythic", text = PLAYER_DIFFICULTY6, difficulties = { DIFFICULTY_IDS.DungeonMythic or 23 } },
		{ key = "timewalking", text = PLAYER_DIFFICULTY_TIMEWALKER, difficulties = { DIFFICULTY_IDS.DungeonTimewalker or 24 } },
	},
	raid = {
		{ key = "lfr", text = PLAYER_DIFFICULTY3, difficulties = { DIFFICULTY_IDS.RaidLFR or 7, DIFFICULTY_IDS.PrimaryRaidLFR or 17, 151 } },
		{
			key = "normal",
			text = PLAYER_DIFFICULTY1,
			difficulties = {
				DIFFICULTY_IDS.Raid10Normal or 3,
				DIFFICULTY_IDS.Raid25Normal or 4,
				DIFFICULTY_IDS.PrimaryRaidNormal or 14,
				DIFFICULTY_IDS.Raid40 or 9,
				DIFFICULTY_IDS.RaidStory or 220,
			},
		},
		{ key = "heroic", text = PLAYER_DIFFICULTY2, difficulties = { DIFFICULTY_IDS.Raid10Heroic or 5, DIFFICULTY_IDS.Raid25Heroic or 6, DIFFICULTY_IDS.PrimaryRaidHeroic or 15 } },
		{ key = "mythic", text = PLAYER_DIFFICULTY6, difficulties = { DIFFICULTY_IDS.PrimaryRaidMythic or 16, 233 } },
		{ key = "timewalking", text = PLAYER_DIFFICULTY_TIMEWALKER, difficulties = { DIFFICULTY_IDS.RaidTimewalker or 33 } },
	},
}


local function getCombatLogCategory(instanceType) return combatLogInstanceMap[instanceType] end

local function getCombatLogSelectionTable(category)
	if not addon.db then return nil end
	local key = COMBAT_LOG_DIFFICULTY_DB_KEYS[category]
	if not key then return nil end
	local selection = addon.db[key]
	if type(selection) ~= "table" then
		selection = {}
		addon.db[key] = selection
	end
	return selection
end

local function buildCombatLogDifficultyData()
	addon.variables = addon.variables or {}
	if addon.variables.combatLogDifficultyGroups and addon.variables.combatLogDifficultyLookup then return addon.variables.combatLogDifficultyGroups, addon.variables.combatLogDifficultyLookup end

	local groups = {}
	local lookup = {}
	for category, entries in pairs(COMBAT_LOG_DIFFICULTY_GROUPS) do
		groups[category] = entries
		lookup[category] = {}
		for _, entry in ipairs(entries) do
			for _, difficultyID in ipairs(entry.difficulties or {}) do
				lookup[category][difficultyID] = entry.key
			end
		end
	end

	addon.variables.combatLogDifficultyGroups = groups
	addon.variables.combatLogDifficultyLookup = lookup
	return groups, lookup
end

local function getCombatLogDifficultyOptions(category)
	local groups = buildCombatLogDifficultyData()
	local options = {}
	for _, entry in ipairs(groups[category] or {}) do
		options[#options + 1] = { value = entry.key, text = entry.text }
	end
	return options
end

local function getCombatLogDifficultyKey(category, difficultyID)
	local _, lookup = buildCombatLogDifficultyData()
	local bucket = lookup[category]
	return bucket and bucket[difficultyID]
end

local function setCombatLogSelection(category, key, enabled)
	local selection = getCombatLogSelectionTable(category)
	if not selection or not key then return end
	selection[key] = enabled and true or false
	if addon.db and addon.db.autoCombatLog then
		if addon.functions.UpdateCombatLogState then addon.functions.UpdateCombatLogState() end
	end
end

local function isCombatLogSelected(category, key)
	local selection = getCombatLogSelectionTable(category)
	return selection and selection[key] == true
end

local function isCombatLogToggleEnabled(category)
	local key = COMBAT_LOG_TOGGLE_DB_KEYS[category]
	if not key or not addon.db then return false end
	return addon.db[key] == true
end

local function getCombatLogDecision(category, difficultyID)
	if COMBAT_LOG_TOGGLE_DB_KEYS[category] then return isCombatLogToggleEnabled(category) end
	local key = getCombatLogDifficultyKey(category, difficultyID)
	if not key then return nil end
	return isCombatLogSelected(category, key)
end

local function getCurrentExpansionLevel()
	local expansionLevel
	if type(LE_EXPANSION_LEVEL_CURRENT) == "number" then expansionLevel = LE_EXPANSION_LEVEL_CURRENT end
	if type(expansionLevel) ~= "number" and _G.GetServerExpansionLevel then expansionLevel = _G.GetServerExpansionLevel() end
	if type(expansionLevel) ~= "number" and _G.GetMaximumExpansionLevel then expansionLevel = _G.GetMaximumExpansionLevel() end
	if type(expansionLevel) ~= "number" and GetExpansionLevel then expansionLevel = GetExpansionLevel() end
	if issecretvalue and issecretvalue(expansionLevel) then return nil end
	return type(expansionLevel) == "number" and expansionLevel or nil
end

local function getCurrentExpansionRaidInstanceCache()
	local expansionLevel = getCurrentExpansionLevel()
	if not expansionLevel then return nil end
	if CURRENT_EXPANSION_RAID_INSTANCE_CACHE and CURRENT_EXPANSION_RAID_INSTANCE_CACHE.expansionLevel == expansionLevel then return CURRENT_EXPANSION_RAID_INSTANCE_CACHE end
	if not (EJ_SelectTier and EJ_GetInstanceByIndex and EJ_GetNumTiers and EJ_GetTierInfo) then
		local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or _G.IsAddOnLoaded
		local loadAddOn = (C_AddOns and C_AddOns.LoadAddOn) or _G.UIParentLoadAddOn or _G.LoadAddOn
		if isLoaded and loadAddOn and not isLoaded("Blizzard_EncounterJournal") then pcall(loadAddOn, "Blizzard_EncounterJournal") end
	end
	if not (EJ_SelectTier and EJ_GetInstanceByIndex and EJ_GetNumTiers and EJ_GetTierInfo) then return nil end

	local cache = { expansionLevel = expansionLevel, instances = {}, maps = {} }
	local previousTier = EJ_GetCurrentTier and EJ_GetCurrentTier() or nil
	local selectedTier
	local tierCount = EJ_GetNumTiers and EJ_GetNumTiers() or nil
	if issecretvalue and issecretvalue(tierCount) then tierCount = nil end
	if type(tierCount) == "number" and tierCount > 0 then
		local expansionName = _G["EXPANSION_NAME" .. expansionLevel]
		if issecretvalue and issecretvalue(expansionName) then expansionName = nil end
		if type(expansionName) == "string" and EJ_GetTierInfo then
			for i = 1, tierCount do
				if EJ_GetTierInfo(i) == expansionName then
					selectedTier = i
					break
				end
			end
		end
	end
	if not selectedTier then return nil end
	EJ_SelectTier(selectedTier)

	local index = 1
	while true do
		local journalInstanceID, _, _, _, _, _, _, _, _, _, mapID = EJ_GetInstanceByIndex(index, true)
		if not journalInstanceID then break end
		cache.instances[journalInstanceID] = true
		if type(mapID) == "number" and mapID > 0 then cache.maps[mapID] = true end
		index = index + 1
	end

	if previousTier then EJ_SelectTier(previousTier) end
	CURRENT_EXPANSION_RAID_INSTANCE_CACHE = cache
	return cache
end

local function isCurrentExpansionRaidInstance(difficultyID, instanceMapID, lfgDungeonID)
	local currentExpansionLevel = getCurrentExpansionLevel()
	if not currentExpansionLevel then return true end

	if GetLFGDungeonInfo and lfgDungeonID then
		local _, _, _, _, _, _, _, _, expansionLevel, _, _, _, _, _, _, _, _, isTimewalker = GetLFGDungeonInfo(lfgDungeonID)
		if issecretvalue and issecretvalue(expansionLevel) then expansionLevel = nil end
		if issecretvalue and issecretvalue(isTimewalker) then isTimewalker = nil end
		if isTimewalker == true then return false end
		if type(expansionLevel) == "number" then return expansionLevel >= currentExpansionLevel end
	end

	local ids = (_G.DifficultyUtil and _G.DifficultyUtil.ID) or {}
	if difficultyID == (ids.RaidTimewalker or 33) then return false end

	local cache = getCurrentExpansionRaidInstanceCache()
	if type(cache) ~= "table" then return true end
	if type(instanceMapID) == "number" and cache.maps[instanceMapID] then return true end

	local journalInstanceID = C_EncounterJournal and C_EncounterJournal.GetInstanceForGameMap and type(instanceMapID) == "number"
		and C_EncounterJournal.GetInstanceForGameMap(instanceMapID)
		or nil
	return journalInstanceID ~= nil and cache.instances[journalInstanceID] == true
end

local function printCombatLogMessage(message)
	if not message or message == "" then return end
	local prefix = "|cff33ff99EQOL|r: "
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage(prefix .. message)
	else
		print(prefix .. message)
	end
end

local function cancelCombatLogStopTimer()
	if not addon.variables or not addon.variables.combatLogStopTimer then return end
	if addon.variables.combatLogStopTimer.Cancel then addon.variables.combatLogStopTimer:Cancel() end
	addon.variables.combatLogStopTimer = nil
end

local function getCombatLogEnabledState()
	local enabled = C_ChatInfo.IsLoggingCombat()
	return enabled and true or false
end

local function applyCombatLogState(enabled)
	local logger = _G.LoggingCombat
	if not logger then return end
	local target = enabled and true or false
	if target then
		cancelCombatLogStopTimer()
		local current = getCombatLogEnabledState()
		if current then return end
		logger(true)
		printCombatLogMessage(L["combatLogEnabledMsg"] or "Combat logging enabled.")
		return
	end

	if addon.db and addon.db.combatLogDelayedStop and C_Timer and C_Timer.NewTimer then
		local current = getCombatLogEnabledState()
		if not current then return end
		addon.variables = addon.variables or {}
		if addon.variables.combatLogStopTimer then return end
		addon.variables.combatLogStopTimer = C_Timer.NewTimer(COMBAT_LOG_DELAY_SECONDS, function()
			addon.variables.combatLogStopTimer = nil
			if getCombatLogEnabledState() then
				logger(false)
				printCombatLogMessage(L["combatLogDisabledMsg"] or "Combat logging disabled.")
			end
		end)
		return
	end

	cancelCombatLogStopTimer()
	local current = getCombatLogEnabledState()
	if current == target then return end
	logger(false)
	printCombatLogMessage(L["combatLogDisabledMsg"] or "Combat logging disabled.")
end

local function updateCombatLogState()
	if not addon.db or not addon.db.autoCombatLog then
		cancelCombatLogStopTimer()
		return
	end

	local _, instanceType, difficultyID, _, _, _, _, instanceMapID, _, lfgDungeonID = GetInstanceInfo()
	if not instanceType or instanceType == "none" then
		applyCombatLogState(false)
		return
	end

	local category = getCombatLogCategory(instanceType)
	if not category then
		applyCombatLogState(false)
		return
	end

	local decision = getCombatLogDecision(category, difficultyID)
	if decision == nil then decision = false end
	if decision == true and category == "raid" and addon.db.combatLogRaidCurrentExpansionOnly and not isCurrentExpansionRaidInstance(difficultyID, instanceMapID, lfgDungeonID) then decision = false end
	applyCombatLogState(decision)
end

addon.functions.UpdateCombatLogState = updateCombatLogState

local function isSecretValue(value) return issecretvalue and issecretvalue(value) end

local function clearNameplateQuestMarkerCache()
	for unit in pairs(nameplateQuestMarkerCache) do
		nameplateQuestMarkerCache[unit] = nil
	end
end

local function isNameplateUnitToken(unit)
	if type(unit) ~= "string" or isSecretValue(unit) then return false end
	return unit:match("^nameplate%d+$") ~= nil
end

local function isNeutralUnit(unit)
	if not isNameplateUnitToken(unit) then return false end

	if type(UnitSelectionType) == "function" then
		local selectionType = UnitSelectionType(unit)
		if not isSecretValue(selectionType) then return selectionType == 2 end
	end

	local reaction = UnitReaction(unit, "player")
	if isSecretValue(reaction) then return false end
	return reaction == 4
end

local function colorsMatch(colorA, colorB)
	if type(colorA) ~= "table" or type(colorB) ~= "table" then return false end

	local ar = isSecretValue(colorA.r) and nil or colorA.r
	local ag = isSecretValue(colorA.g) and nil or colorA.g
	local ab = isSecretValue(colorA.b) and nil or colorA.b
	local br = isSecretValue(colorB.r) and nil or colorB.r
	local bg = isSecretValue(colorB.g) and nil or colorB.g
	local bb = isSecretValue(colorB.b) and nil or colorB.b
	if type(ar) ~= "number" or type(ag) ~= "number" or type(ab) ~= "number" then return false end
	if type(br) ~= "number" or type(bg) ~= "number" or type(bb) ~= "number" then return false end

	return math.abs(ar - br) < 0.0001 and math.abs(ag - bg) < 0.0001 and math.abs(ab - bb) < 0.0001
end

local function isLegacyNameplateMobFallbackColor(dbKey, color)
	if dbKey == NAMEPLATE_MOB_COLOR_NEUTRAL_DB_KEY or dbKey == NAMEPLATE_MOB_COLOR_THREAT_WARNING_DB_KEY then
		return colorsMatch(color, NAMEPLATE_MOB_COLOR_DEFAULTS[NAMEPLATE_MOB_COLOR_THREAT_WARNING_DB_KEY])
	elseif dbKey == NAMEPLATE_MOB_COLOR_THREAT_LOST_DB_KEY then
		return colorsMatch(color, NAMEPLATE_MOB_COLOR_DEFAULTS[NAMEPLATE_MOB_COLOR_THREAT_LOST_DB_KEY])
	end

	return false
end

local function getNeutralNameplateDefaultColor(unit)
	if isNameplateUnitToken(unit) and type(UnitSelectionColor) == "function" then
		local r, g, b = UnitSelectionColor(unit)
		if not isSecretValue(r) and not isSecretValue(g) and not isSecretValue(b) and type(r) == "number" and type(g) == "number" and type(b) == "number" then
			return { r = r, g = g, b = b, a = 1 }
		end
	end

	return buildNameplateColorDefault(_G.FACTION_BAR_COLORS and _G.FACTION_BAR_COLORS[4], 1, 1, 0)
end

local function getNameplateMobColorDefault(dbKey, unit)
	if dbKey == NAMEPLATE_MOB_COLOR_NEUTRAL_DB_KEY then return getNeutralNameplateDefaultColor(unit) end
	return NAMEPLATE_MOB_COLOR_DEFAULTS[dbKey]
end

local function isPlayerEffectivelyTank()
	local isTank = PlayerUtil and type(PlayerUtil.IsPlayerEffectivelyTank) == "function" and PlayerUtil.IsPlayerEffectivelyTank() or false
	if isSecretValue(isTank) then isTank = false end
	return isTank == true
end

local function isNameplateUnitOnThreatListWithPlayer(unitFrame)
	if not unitFrame or isSecretValue(unitFrame) then return false end

	local threatUnit = unitFrame.displayedUnit
	if isSecretValue(threatUnit) then threatUnit = nil end
	if not isNameplateUnitToken(threatUnit) then threatUnit = unitFrame.unit end
	if not isNameplateUnitToken(threatUnit) then return false end

	local onThreatList
	if type(_G.CompactUnitFrame_IsOnThreatListWithPlayer) == "function" then
		onThreatList = _G.CompactUnitFrame_IsOnThreatListWithPlayer(threatUnit)
	elseif type(UnitDetailedThreatSituation) == "function" then
		local _, threatStatus = UnitDetailedThreatSituation("player", threatUnit)
		if isSecretValue(threatStatus) then threatStatus = nil end
		onThreatList = threatStatus ~= nil
	end

	if isSecretValue(onThreatList) then onThreatList = false end
	return onThreatList == true
end

local function isNameplateMobColorsActive() return nameplateMobColorsActive == true end

do
	local nameplateSlugOutlineFrame
	local nameplateSlugOutlineActive = false
	local nameplateSlugOutlineApplyFrameOptionsHooked = false
	local nameplateSlugOutlineFontObjectDefaults = {}
	local nameplateSlugOutlineFontStringDefaults = setmetatable({}, { __mode = "k" })

local function isNameplateSlugOutlineActive() return nameplateSlugOutlineActive == true end

local NAMEPLATE_SLUG_OUTLINE_FONT_OBJECTS = {
	"SystemFont_NamePlate",
	"SystemFont_NamePlateFixed",
	"SystemFont_NamePlate_Outlined",
	"SystemFont_LargeNamePlate",
	"SystemFont_LargeNamePlateFixed",
}

local function getNameplateNameFontString(unitFrame)
	if not unitFrame or isSecretValue(unitFrame) then return nil end
	if unitFrame.IsForbidden and unitFrame:IsForbidden() then return nil end

	local name = unitFrame.name or unitFrame.Name
	if isSecretValue(name) then return nil end
	if name and type(name.SetFont) == "function" and type(name.GetFont) == "function" then return name end
	return nil
end

local function getNameplateTextSizeOverride(fallbackSize)
	local size = addon.db and tonumber(addon.db[NAMEPLATE_TEXT_SIZE_DB_KEY]) or 0
	if type(size) ~= "number" or size <= 0 then return fallbackSize end
	if size < 8 then size = 8 end
	if size > 32 then size = 32 end
	return size
end

local function getNameplateCastTextSizeOverride(fallbackSize)
	local size = addon.db and tonumber(addon.db[NAMEPLATE_CAST_TEXT_SIZE_DB_KEY]) or 0
	if type(size) ~= "number" or size <= 0 then return fallbackSize end
	if size < 8 then size = 8 end
	if size > 32 then size = 32 end
	return size
end

local function getNameplateTextFontFace(fallbackFont)
	if not addon.db then return fallbackFont end
	local customFont = addon.db[NAMEPLATE_TEXT_CUSTOM_FONT_DB_KEY]
	if customFont == nil then customFont = addon.db[NAMEPLATE_TEXT_FONT_DB_KEY] ~= nil end
	if customFont ~= true then return fallbackFont end

	local globalFontKey = addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or "__EQOL_GLOBAL_FONT__"
	local configured = addon.db and addon.db[NAMEPLATE_TEXT_FONT_DB_KEY] or globalFontKey
	if addon.functions.ResolveFontFace then return addon.functions.ResolveFontFace(configured, fallbackFont) end
	return fallbackFont
end

local function getNameplateTextStyleFlags()
	local globalStyleKey = addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or "__EQOL_GLOBAL_FONT_STYLE__"
	local style = addon.db and addon.db[NAMEPLATE_TEXT_OUTLINE_DB_KEY] or globalStyleKey
	if addon.functions.NormalizeFontStyleChoice then style = addon.functions.NormalizeFontStyleChoice(style, globalStyleKey, true) end
	if style == "NONE" then style = globalStyleKey end
	local flags = addon.functions.GetFontFlagsForStyle and addon.functions.GetFontFlagsForStyle(style, globalStyleKey) or "OUTLINE,SLUG"
	if not flags or flags == "" then return "OUTLINE" end
	if flags == "SLUG" then return "OUTLINE,SLUG" end
	return flags
end

local function getNameplateTextStyleChoice()
	local globalStyleKey = addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or "__EQOL_GLOBAL_FONT_STYLE__"
	local style = addon.db and addon.db[NAMEPLATE_TEXT_OUTLINE_DB_KEY] or globalStyleKey
	if addon.functions.NormalizeFontStyleChoice then return addon.functions.NormalizeFontStyleChoice(style, globalStyleKey, true), globalStyleKey end
	return style, globalStyleKey
end

local function cacheFontShadowDefaults(defaults, fontElement)
	if not defaults or not fontElement then return end
	if type(fontElement.GetShadowColor) == "function" then
		local r, g, b, a = fontElement:GetShadowColor()
		defaults.shadowColor = { r = r, g = g, b = b, a = a }
	end
	if type(fontElement.GetShadowOffset) == "function" then
		local x, y = fontElement:GetShadowOffset()
		defaults.shadowX = x
		defaults.shadowY = y
	end
end

local function applyNameplateTextStyleShadow(fontElement)
	if not (fontElement and addon.functions.ApplyFontStyleShadow) then return end
	local style, fallback = getNameplateTextStyleChoice()
	addon.functions.ApplyFontStyleShadow(fontElement, style, fallback)
end

local function restoreFontShadowDefaults(fontElement, defaults)
	if not (fontElement and defaults) then return end
	if defaults.shadowColor and type(fontElement.SetShadowColor) == "function" then
		local color = defaults.shadowColor
		fontElement:SetShadowColor(color.r or 0, color.g or 0, color.b or 0, color.a or 0)
	end
	if defaults.shadowX ~= nil and defaults.shadowY ~= nil and type(fontElement.SetShadowOffset) == "function" then fontElement:SetShadowOffset(defaults.shadowX, defaults.shadowY) end
end

local function setNameplateTextFont(fontElement, font, size, flags)
	if not (fontElement and font and size and type(fontElement.SetFont) == "function") then return end
	if not flags or flags == "" then flags = "OUTLINE" end
	if flags == "SLUG" then flags = "OUTLINE,SLUG" end
	local ufHelper = addon.Aura and addon.Aura.UFHelper
	if ufHelper and ufHelper.setFontWithFallback then
		local ok = ufHelper.setFontWithFallback(fontElement, font, size, flags)
		if ok then return end
	end
	fontElement:SetFont(font, size, flags)
end

local function applySlugOutlineToFontObject(fontObject)
	if not fontObject or type(fontObject.GetFont) ~= "function" or type(fontObject.SetFont) ~= "function" then return end
	if not nameplateSlugOutlineFontObjectDefaults[fontObject] then
		local font, size, flags = fontObject:GetFont()
		nameplateSlugOutlineFontObjectDefaults[fontObject] = { font = font, size = size, flags = flags }
		cacheFontShadowDefaults(nameplateSlugOutlineFontObjectDefaults[fontObject], fontObject)
	end

	local defaults = nameplateSlugOutlineFontObjectDefaults[fontObject]
	local font = getNameplateTextFontFace(defaults and defaults.font)
	local size = defaults and defaults.size
	setNameplateTextFont(fontObject, font, size, getNameplateTextStyleFlags())
	applyNameplateTextStyleShadow(fontObject)
end

local function restoreSlugOutlineFontObject(fontObject)
	local defaults = nameplateSlugOutlineFontObjectDefaults[fontObject]
	if not defaults or not fontObject or type(fontObject.SetFont) ~= "function" then return end
	setNameplateTextFont(fontObject, defaults.font, defaults.size, defaults.flags)
	restoreFontShadowDefaults(fontObject, defaults)
end

local function applySlugOutlineToFontString(fontString, sizeOverride)
	if not fontString or type(fontString.GetFont) ~= "function" or type(fontString.SetFont) ~= "function" then return end
	if not nameplateSlugOutlineFontStringDefaults[fontString] then
		local font, size, flags = fontString:GetFont()
		nameplateSlugOutlineFontStringDefaults[fontString] = { font = font, size = size, flags = flags }
		cacheFontShadowDefaults(nameplateSlugOutlineFontStringDefaults[fontString], fontString)
	end

	local defaults = nameplateSlugOutlineFontStringDefaults[fontString]
	local font = getNameplateTextFontFace(defaults and defaults.font)
	local size = sizeOverride(defaults and defaults.size)
	setNameplateTextFont(fontString, font, size, getNameplateTextStyleFlags())
	applyNameplateTextStyleShadow(fontString)
end

local function restoreSlugOutlineFontString(fontString)
	local defaults = nameplateSlugOutlineFontStringDefaults[fontString]
	if not defaults or not fontString or type(fontString.SetFont) ~= "function" then return end
	setNameplateTextFont(fontString, defaults.font, defaults.size, defaults.flags)
	restoreFontShadowDefaults(fontString, defaults)
end

local function getNameplateCastTextFontStrings(unitFrame)
	if not unitFrame or isSecretValue(unitFrame) then return nil, nil end
	if unitFrame.IsForbidden and unitFrame:IsForbidden() then return nil, nil end

	local castBarsContainer = unitFrame.CastBarsContainer
	if isSecretValue(castBarsContainer) then castBarsContainer = nil end
	local castBar = castBarsContainer and castBarsContainer.castBar or unitFrame.castBar
	if isSecretValue(castBar) then return nil, nil end
	if not castBar or (castBar.IsForbidden and castBar:IsForbidden()) then return nil, nil end

	local spellText = castBar.Text
	if isSecretValue(spellText) or not spellText or type(spellText.SetFont) ~= "function" or type(spellText.GetFont) ~= "function" then spellText = nil end
	local targetText = castBar.CastTargetNameText
	if isSecretValue(targetText) or not targetText or type(targetText.SetFont) ~= "function" or type(targetText.GetFont) ~= "function" then targetText = nil end
	return spellText, targetText
end

local function applySlugOutlineToUnitFrame(unitFrame)
	local name = getNameplateNameFontString(unitFrame)
	if name then applySlugOutlineToFontString(name, getNameplateTextSizeOverride) end

	local spellText, targetText = getNameplateCastTextFontStrings(unitFrame)
	if spellText then applySlugOutlineToFontString(spellText, getNameplateCastTextSizeOverride) end
	if targetText then applySlugOutlineToFontString(targetText, getNameplateCastTextSizeOverride) end
end

local function restoreSlugOutlineOnUnitFrame(unitFrame)
	local name = getNameplateNameFontString(unitFrame)
	if name then restoreSlugOutlineFontString(name) end

	local spellText, targetText = getNameplateCastTextFontStrings(unitFrame)
	if spellText then restoreSlugOutlineFontString(spellText) end
	if targetText then restoreSlugOutlineFontString(targetText) end
end
local function applySlugOutlineToNameplate(namePlate)
	local unitFrame = namePlate and namePlate.UnitFrame
	applySlugOutlineToUnitFrame(unitFrame)
end

local function restoreSlugOutlineOnNameplate(namePlate)
	local unitFrame = namePlate and namePlate.UnitFrame
	restoreSlugOutlineOnUnitFrame(unitFrame)
end

local function ensureNameplateApplyFrameOptionsHook()
	if nameplateSlugOutlineApplyFrameOptionsHooked then return end
	local unitFrameMixin = _G.NamePlateUnitFrameMixin
	if type(unitFrameMixin) ~= "table" or type(unitFrameMixin.ApplyFrameOptions) ~= "function" then return end

	nameplateSlugOutlineApplyFrameOptionsHooked = true
	hooksecurefunc(unitFrameMixin, "ApplyFrameOptions", function(unitFrame)
		if isNameplateSlugOutlineActive() then applySlugOutlineToUnitFrame(unitFrame) end
	end)
end

local function applyNameplateSlugOutlineToFontObjects()
	for _, fontObjectName in ipairs(NAMEPLATE_SLUG_OUTLINE_FONT_OBJECTS) do
		applySlugOutlineToFontObject(_G[fontObjectName])
	end
end

local function restoreNameplateSlugOutlineFontObjects()
	for _, fontObjectName in ipairs(NAMEPLATE_SLUG_OUTLINE_FONT_OBJECTS) do
		restoreSlugOutlineFontObject(_G[fontObjectName])
	end
end

local function applyNameplateSlugOutlineToAllNameplates()
	applyNameplateSlugOutlineToFontObjects()
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
	for _, namePlate in pairs(C_NamePlate.GetNamePlates() or {}) do
		applySlugOutlineToNameplate(namePlate)
	end
end

local function restoreNameplateSlugOutlineOnAllNameplates()
	restoreNameplateSlugOutlineFontObjects()
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
	for _, namePlate in pairs(C_NamePlate.GetNamePlates() or {}) do
		restoreSlugOutlineOnNameplate(namePlate)
	end
end

local function ensureNameplateSlugOutlineWatcher()
	if nameplateSlugOutlineFrame then return end

	nameplateSlugOutlineFrame = CreateFrame("Frame")
	nameplateSlugOutlineFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	nameplateSlugOutlineFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	nameplateSlugOutlineFrame:SetScript("OnEvent", function(_, event, unit)
		if not isNameplateSlugOutlineActive() then return end
		if event == "NAME_PLATE_UNIT_ADDED" and unit and C_NamePlate and C_NamePlate.GetNamePlateForUnit then
			local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
			if namePlate then applySlugOutlineToNameplate(namePlate) end
			return
		end

		applyNameplateSlugOutlineToAllNameplates()
	end)
end

local function syncNameplateSlugOutline()
	if not isNameplateSlugOutlineActive() then return end
	ensureNameplateSlugOutlineWatcher()
	ensureNameplateApplyFrameOptionsHook()
	applyNameplateSlugOutlineToAllNameplates()
end

	function addon.functions.SetDefaultNameplateSlugOutlineEnabled(value)
		local enabled = value and true or false
		addon.db[NAMEPLATE_SLUG_OUTLINE_DB_KEY] = enabled
		nameplateSlugOutlineActive = enabled
		if enabled then
			syncNameplateSlugOutline()
		else
			restoreNameplateSlugOutlineOnAllNameplates()
		end
	end

	function addon.functions.RefreshDefaultNameplateTextStyle()
		if isNameplateSlugOutlineActive() then syncNameplateSlugOutline() end
	end

	function addon.functions.InitializeDefaultNameplateTextStyle()
		nameplateSlugOutlineActive = addon.db and addon.db[NAMEPLATE_SLUG_OUTLINE_DB_KEY] == true
		if nameplateSlugOutlineActive then syncNameplateSlugOutline() end
	end
end

local function isNameplateMobColorScopeEnabled(dbKey, defaultValue)
	if not addon.db then return defaultValue and true or false end
	local value = addon.db[dbKey]
	if value == nil then return defaultValue and true or false end
	return value == true
end

local function isNameplateMobColorPvpContext(instanceType, zonePvpType)
	if instanceType == "pvp" or instanceType == "arena" then return true end
	return zonePvpType == "arena" or zonePvpType == "combat" or zonePvpType == "ffapvp"
end

local function readNameplateMobColorContext()
	local _, instanceType, _, _, _, _, _, _, _, lfgDungeonID = GetInstanceInfo()
	if isSecretValue(instanceType) then instanceType = nil end
	if isSecretValue(lfgDungeonID) then lfgDungeonID = nil end
	if type(instanceType) ~= "string" or instanceType == "" then instanceType = "none" end

	local zonePvpType
	if C_PvP and type(C_PvP.GetZonePVPInfo) == "function" then
		zonePvpType = C_PvP.GetZonePVPInfo()
		if isSecretValue(zonePvpType) then zonePvpType = nil end
	end

	local allowInDungeons = isNameplateMobColorScopeEnabled(NAMEPLATE_MOB_COLORS_DUNGEONS_DB_KEY, true)
	local allowOutsideDungeons = isNameplateMobColorScopeEnabled(NAMEPLATE_MOB_COLORS_OUTSIDE_DUNGEONS_DB_KEY, false)
	local isInstancedPve = instanceType == "party" or instanceType == "raid" or instanceType == "scenario"
	local isPvp = isNameplateMobColorPvpContext(instanceType, zonePvpType)
	local isAllowedByScope = (isInstancedPve and allowInDungeons) or ((not isInstancedPve) and allowOutsideDungeons)
	return instanceType, lfgDungeonID, zonePvpType, isInstancedPve, isAllowedByScope and not isPvp
end

local function isPlayerControlledNameplateUnit(unit)
	if not isNameplateUnitToken(unit) then return false end

	local isPlayerUnit = type(UnitIsPlayer) == "function" and UnitIsPlayer(unit) or false
	if isSecretValue(isPlayerUnit) then isPlayerUnit = false end
	if isPlayerUnit then return true end

	local isPlayerControlled = type(UnitPlayerControlled) == "function" and UnitPlayerControlled(unit) or false
	if isSecretValue(isPlayerControlled) then isPlayerControlled = false end
	return isPlayerControlled == true
end

local function updateNameplateMobColorContext(forceRefresh)
	if not forceRefresh and not nameplateMobColorState.isDirty then return end
	local isFeatureEnabled = isNameplateMobColorsActive()
	local instanceType, lfgDungeonID, zonePvpType, isInstancedPve, isAllowed = readNameplateMobColorContext()
	local state = nameplateMobColorState
	local contextChanged = state.instanceType ~= instanceType
		or state.lastLFGInstanceID ~= lfgDungeonID
		or state.zonePvpType ~= zonePvpType
		or state.isAllowed ~= isAllowed
	state.isDirty = false

	if not isFeatureEnabled or not isAllowed then
		state.isActive = false
		state.instanceType = instanceType
		state.zonePvpType = zonePvpType
		state.lastLFGInstanceID = lfgDungeonID
		state.isInstancedPve = isInstancedPve == true
		state.isAllowed = isAllowed == true
		state.referenceLevel = nil
		state.lieutenantLevel = nil
		return
	end

	if not forceRefresh and not contextChanged and state.isActive == true then return end

	state.isActive = true
	state.instanceType = instanceType
	state.zonePvpType = zonePvpType
	state.lastLFGInstanceID = lfgDungeonID
	state.isInstancedPve = isInstancedPve == true
	state.isAllowed = isAllowed == true
	state.lieutenantLevel = nil

	local referenceLevel
	if lfgDungeonID and isInstancedPve and type(_G.GetMaximumExpansionLevel) == "function" and type(_G.GetMaxLevelForExpansionLevel) == "function" then
		local maximumExpansionLevel = _G.GetMaximumExpansionLevel()
		if not isSecretValue(maximumExpansionLevel) then
			referenceLevel = _G.GetMaxLevelForExpansionLevel(maximumExpansionLevel)
			if isSecretValue(referenceLevel) then referenceLevel = nil end
		end
	end

	if type(referenceLevel) ~= "number" then
		referenceLevel = UnitEffectiveLevel and UnitEffectiveLevel("player")
		if isSecretValue(referenceLevel) then referenceLevel = nil end
	end
	if type(referenceLevel) ~= "number" and type(UnitLevel) == "function" then
		referenceLevel = UnitLevel("player")
		if isSecretValue(referenceLevel) then referenceLevel = nil end
	end

	state.referenceLevel = type(referenceLevel) == "number" and referenceLevel or nil
end

local function getNameplateHealthBar(unitFrame)
	if not unitFrame or isSecretValue(unitFrame) then return nil end

	local healthBar = unitFrame.healthBar
	if not healthBar and unitFrame.HealthBarsContainer and not isSecretValue(unitFrame.HealthBarsContainer) then healthBar = unitFrame.HealthBarsContainer.healthBar end
	if not healthBar and unitFrame.HealthBar then healthBar = unitFrame.HealthBar end
	if isSecretValue(healthBar) then return nil end
	if healthBar and healthBar.IsForbidden and healthBar:IsForbidden() then return nil end
	return healthBar
end

local function isNameplateQuestMarkersActive() return nameplateQuestMarkersActive == true end

function nameplateMobColorState.HasQuestDisplay() return isNameplateQuestMarkersActive() or (addon.db and addon.db.nameplateQuestProgress == true) end

function addon.functions.CanScanNameplateQuestMarkers()
	return not IsInInstance() and (nameplateMobColorState.HasQuestDisplay() or (isNameplateMobColorsActive() and addon.db
		and addon.db.nameplateMobColorsOutsideDungeons == true
		and (addon.db.nameplateMobColorQuestNeutralEnabled == true or addon.db.nameplateMobColorQuestHostileEnabled == true)))
end

local function isNameplateTargetMarkersActive() return nameplateTargetMarkersActive == true end

local function isNameplateEliteMarkersActive() return nameplateEliteMarkersActive == true end

local function getNameplateQuestMarkerAnchor(unitFrame)
	if not unitFrame or isSecretValue(unitFrame) then return nil end
	if unitFrame.IsForbidden and unitFrame:IsForbidden() then return nil end

	local anchor = unitFrame.HealthBarsContainer
	if isSecretValue(anchor) then anchor = nil end
	if not anchor then anchor = getNameplateHealthBar(unitFrame) end
	if not anchor then anchor = unitFrame end
	if anchor.IsForbidden and anchor:IsForbidden() then return nil end
	return anchor
end

local NAMEPLATE_QUEST_MARKER_ANCHORS = {
	CENTER = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 },
	TOP = { point = "BOTTOM", relativePoint = "TOP", x = 0, y = 2 },
	TOPRIGHT = { point = "BOTTOMLEFT", relativePoint = "TOPRIGHT", x = 2, y = 2 },
	RIGHT = { point = "LEFT", relativePoint = "RIGHT", x = 2, y = 0 },
	BOTTOMRIGHT = { point = "TOPLEFT", relativePoint = "BOTTOMRIGHT", x = 2, y = -2 },
	BOTTOM = { point = "TOP", relativePoint = "BOTTOM", x = 0, y = -2 },
	BOTTOMLEFT = { point = "TOPRIGHT", relativePoint = "BOTTOMLEFT", x = -2, y = -2 },
	LEFT = { point = "RIGHT", relativePoint = "LEFT", x = -2, y = 0 },
	TOPLEFT = { point = "BOTTOMRIGHT", relativePoint = "TOPLEFT", x = -2, y = 2 },
}

local function getNameplateMarkerAnchorConfig(dbKey, fallback)
	local anchorKey = addon.db and addon.db[dbKey] or fallback
	if type(anchorKey) ~= "string" or not NAMEPLATE_QUEST_MARKER_ANCHORS[anchorKey] then anchorKey = fallback end
	return NAMEPLATE_QUEST_MARKER_ANCHORS[anchorKey]
end

local function getNameplateQuestMarkerAnchorConfig()
	return getNameplateMarkerAnchorConfig(NAMEPLATE_QUEST_MARKER_ANCHOR_DB_KEY, "RIGHT")
end

local function getNameplateQuestMarkerSize()
	local size = addon.db and tonumber(addon.db[NAMEPLATE_QUEST_MARKER_SIZE_DB_KEY]) or 18
	if size < 8 then size = 8 end
	if size > 48 then size = 48 end
	return size
end

local function getNameplateEliteMarkerAnchorConfig()
	return getNameplateMarkerAnchorConfig(NAMEPLATE_ELITE_MARKER_ANCHOR_DB_KEY, "LEFT")
end

local function getNameplateEliteMarkerSize()
	local size = addon.db and tonumber(addon.db[NAMEPLATE_ELITE_MARKER_SIZE_DB_KEY]) or 18
	if size < 8 then size = 8 end
	if size > 48 then size = 48 end
	return size
end

local function unitIdentityIsSecret(unit)
	if not (C_Secrets and type(C_Secrets.ShouldUnitIdentityBeSecret) == "function") then return false end
	local ok, isSecret = pcall(C_Secrets.ShouldUnitIdentityBeSecret, unit)
	if not ok or isSecretValue(isSecret) then return true end
	return isSecret == true
end

local questTooltipLineTypes = {}
if Enum and Enum.TooltipDataLineType then
	questTooltipLineTypes[Enum.TooltipDataLineType.QuestObjective] = true
	questTooltipLineTypes[Enum.TooltipDataLineType.QuestTitle] = true
	questTooltipLineTypes[Enum.TooltipDataLineType.QuestPlayer] = true
end

local function isQuestObjectiveLineIncomplete(text)
	if type(text) ~= "string" or text == "" then return true end

	local current, required = text:match("(%d+)%s*/%s*(%d+)")
	if current and required then return tonumber(current) ~= tonumber(required) end

	local percent = text:match("(%d+)%%")
	if percent then return tonumber(percent) ~= 100 end

	return true
end

local function isNameplateQuestObjectiveUnit(unit)
	if not isNameplateUnitToken(unit) or not addon.functions.CanScanNameplateQuestMarkers() then return false end
	if nameplateQuestMarkerCache[unit] ~= nil then return nameplateQuestMarkerCache[unit] ~= false end
	if unitIdentityIsSecret(unit) then
		nameplateQuestMarkerCache[unit] = false
		return false
	end
	if type(UnitExists) == "function" and not UnitExists(unit) then
		nameplateQuestMarkerCache[unit] = false
		return false
	end
	if not (C_TooltipInfo and type(C_TooltipInfo.GetUnit) == "function") then
		nameplateQuestMarkerCache[unit] = false
		return false
	end

	local tooltipInfo = C_TooltipInfo.GetUnit(unit)
	if isSecretValue(tooltipInfo) or type(tooltipInfo) ~= "table" or type(tooltipInfo.lines) ~= "table" then
		nameplateQuestMarkerCache[unit] = false
		return false
	end

	local playerName, playerSurname
	if UnitName then playerName, playerSurname = UnitName("player") end
	if type(playerName) == "string" and type(playerSurname) == "string" and playerSurname ~= "" then playerName = playerName .. " " .. playerSurname end
	local ignoreUntilTitle = false
	local objectives = {}
	local hasObjective = false
	for _, line in ipairs(tooltipInfo.lines) do
		if not isSecretValue(line) and type(line) == "table" and not isSecretValue(line.type) and questTooltipLineTypes[line.type] then
			local leftText
			if not isSecretValue(line.leftText) then leftText = line.leftText end
			if not ignoreUntilTitle and line.type == Enum.TooltipDataLineType.QuestObjective and type(leftText) == "string" and isQuestObjectiveLineIncomplete(leftText) then
				hasObjective = true
				local current, required = leftText:match("(%d+)%s*/%s*(%d+)")
				local progress = current and (current .. "/" .. required) or leftText:match("%d+%%")
				if progress then objectives[#objectives + 1] = progress end
			elseif line.type == Enum.TooltipDataLineType.QuestTitle then
				ignoreUntilTitle = false
			elseif line.type == Enum.TooltipDataLineType.QuestPlayer then
				ignoreUntilTitle = leftText ~= playerName
			end
		end
	end

	nameplateQuestMarkerCache[unit] = hasObjective and table.concat(objectives, " · ") or false
	return hasObjective
end

local function getNameplateQuestMarker(unitFrame)
	if not nameplateMobColorState.HasQuestDisplay() then return nil end
	local anchor = getNameplateQuestMarkerAnchor(unitFrame)
	if not anchor then return nil end

	local marker = nameplateQuestMarkersByUnitFrame[unitFrame]
	if not marker then
		marker = unitFrame:CreateTexture(nil, "OVERLAY")
		marker:SetAtlas("QuestNormal", true)
		marker.progress = unitFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		marker.progress:SetTextColor(1, 1, 1)
		marker.progress:SetPoint("LEFT", marker, "RIGHT", 2, 0)
		marker.progress:Hide()
		marker:Hide()
		nameplateQuestMarkersByUnitFrame[unitFrame] = marker
	end

	local anchorConfig = getNameplateQuestMarkerAnchorConfig()
	local size = getNameplateQuestMarkerSize()
	local offsetX = math.max(-50, math.min(50, tonumber(addon.db.nameplateQuestMarkerOffsetX) or 0))
	local offsetY = math.max(-50, math.min(50, tonumber(addon.db.nameplateQuestMarkerOffsetY) or 0))
	marker:SetSize(size, size)
	marker:ClearAllPoints()
	marker:SetPoint(anchorConfig.point, anchor, anchorConfig.relativePoint, anchorConfig.x + offsetX, anchorConfig.y + offsetY)
	local progress = marker.progress
	local progressAnchor = getNameplateMarkerAnchorConfig("nameplateQuestProgressAnchor", "TOP")
	progress:ClearAllPoints()
	progress:SetPoint(progressAnchor.point, anchor, progressAnchor.relativePoint,
		progressAnchor.x + math.max(-100, math.min(100, tonumber(addon.db.nameplateQuestProgressOffsetX) or 0)),
		progressAnchor.y + math.max(-100, math.min(100, tonumber(addon.db.nameplateQuestProgressOffsetY) or 0)))
	local style = addon.db.nameplateQuestProgressOutline or addon.functions.GetGlobalFontStyleConfigKey()
	local fontSize = math.max(8, math.min(48, tonumber(addon.db.nameplateQuestProgressSize) or 12))
	addon.functions.ApplyFontString(progress, addon.db.nameplateQuestProgressFont, fontSize, style, STANDARD_TEXT_FONT)
	local color = addon.db.nameplateQuestProgressColor or { r = 1, g = 1, b = 1, a = 1 }
	if addon.db.nameplateQuestProgressUseClassColor == true then
		local _, class = UnitClass("player")
		color = (class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]) or color
	end
	progress:SetTextColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
	return marker
end

local function updateNameplateQuestMarker(unitFrame, unit)
	local marker = unitFrame and nameplateQuestMarkersByUnitFrame[unitFrame]
	if not nameplateMobColorState.HasQuestDisplay() or not addon.functions.CanScanNameplateQuestMarkers() or not isNameplateUnitToken(unit) then
		if marker then
			marker:Hide()
			marker.progress:Hide()
		end
		return
	end

	local shouldShow = isNameplateQuestObjectiveUnit(unit)
	if not shouldShow then
		if marker then
			marker:Hide()
			marker.progress:Hide()
		end
		return
	end

	marker = getNameplateQuestMarker(unitFrame)
	if marker then
		marker:SetShown(isNameplateQuestMarkersActive())
		local progress = nameplateQuestMarkerCache[unit]
		if addon.db.nameplateQuestProgress == true and type(progress) == "string" and progress ~= "" then
			marker.progress:SetText(progress)
			marker.progress:Show()
		else
			marker.progress:Hide()
		end
	end
end

local function hideAllNameplateQuestMarkers()
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
	for _, namePlate in pairs(C_NamePlate.GetNamePlates() or {}) do
		local unitFrame = namePlate and namePlate.UnitFrame
		local marker = unitFrame and nameplateQuestMarkersByUnitFrame[unitFrame]
		if marker then
			marker:Hide()
			marker.progress:Hide()
		end
	end
end

local ELITE_MARKER_TEXTURE = "Interface\\AddOns\\EnhanceQoL\\Assets\\NameplateEliteStar.tga"
local BOSS_MARKER_ATLAS = "worldquest-icon-boss"
local RARE_MARKER_ATLAS = "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Star"

local function getNameplateEliteMarkerUnitLevel(unit)
	local mobLevel = UnitEffectiveLevel and UnitEffectiveLevel(unit)
	if isSecretValue(mobLevel) then mobLevel = nil end
	if type(mobLevel) ~= "number" and type(UnitLevel) == "function" then
		mobLevel = UnitLevel(unit)
		if isSecretValue(mobLevel) then mobLevel = nil end
	end
	return type(mobLevel) == "number" and mobLevel or nil
end

local function getNameplateEliteMarkerReferenceLevel()
	updateNameplateMobColorContext()
	local lfgDungeonID = nameplateMobColorState.lastLFGInstanceID
	local isInstancedPve = nameplateMobColorState.isInstancedPve
	local referenceLevel
	if lfgDungeonID and isInstancedPve and type(_G.GetMaximumExpansionLevel) == "function" and type(_G.GetMaxLevelForExpansionLevel) == "function" then
		local maximumExpansionLevel = _G.GetMaximumExpansionLevel()
		if not isSecretValue(maximumExpansionLevel) then
			referenceLevel = _G.GetMaxLevelForExpansionLevel(maximumExpansionLevel)
			if isSecretValue(referenceLevel) then referenceLevel = nil end
		end
	end

	if type(referenceLevel) ~= "number" then
		referenceLevel = UnitEffectiveLevel and UnitEffectiveLevel("player")
		if isSecretValue(referenceLevel) then referenceLevel = nil end
	end
	if type(referenceLevel) ~= "number" and type(UnitLevel) == "function" then
		referenceLevel = UnitLevel("player")
		if isSecretValue(referenceLevel) then referenceLevel = nil end
	end

	return type(referenceLevel) == "number" and referenceLevel or nil
end

local function getNameplateEliteMarkerKind(unit)
	if not isNameplateUnitToken(unit) then return false end
	if type(UnitClassification) ~= "function" then return false end
	local classification = UnitClassification(unit)
	if isSecretValue(classification) then return false end

	if classification == "worldboss" then return "boss" end
	if classification == "rare" then return "rare" end
	if classification ~= "elite" and classification ~= "rareelite" then return false end

	local mobLevel = getNameplateEliteMarkerUnitLevel(unit)
	if mobLevel == -1 then return "boss" end

	local referenceLevel = getNameplateEliteMarkerReferenceLevel()
	if type(mobLevel) == "number" and type(referenceLevel) == "number" and mobLevel == (referenceLevel + 2) then return "boss" end

	return "elite"
end

local function getNameplateEliteMarker(unitFrame, markerKind)
	if not isNameplateEliteMarkersActive() then return nil end
	local anchor = getNameplateQuestMarkerAnchor(unitFrame)
	if not anchor then return nil end

	-- Draw on the health bar so its fill and border cannot cover the marker.
	local parent = getNameplateHealthBar(unitFrame) or anchor
	local marker = nameplateEliteMarkersByUnitFrame[unitFrame]
	if not marker then
		marker = parent:CreateTexture(nil, "OVERLAY", nil, 7)
		marker:Hide()
		nameplateEliteMarkersByUnitFrame[unitFrame] = marker
	end

	if marker:GetParent() ~= parent then marker:SetParent(parent) end

	local anchorConfig = getNameplateEliteMarkerAnchorConfig()
	local size = getNameplateEliteMarkerSize()
	local offsetX = math.max(-50, math.min(50, tonumber(addon.db.nameplateEliteMarkerOffsetX) or 0))
	local offsetY = math.max(-50, math.min(50, tonumber(addon.db.nameplateEliteMarkerOffsetY) or 0))
	if markerKind == "boss" then
		marker:SetAtlas(BOSS_MARKER_ATLAS, true)
	elseif markerKind == "rare" then
		marker:SetAtlas(RARE_MARKER_ATLAS, true)
	else
		marker:SetTexture(ELITE_MARKER_TEXTURE)
		marker:SetTexCoord(0, 1, 0, 1)
	end
	marker:SetSize(size, size)
	marker:ClearAllPoints()
	marker:SetPoint(anchorConfig.point, anchor, anchorConfig.relativePoint, anchorConfig.x + offsetX, anchorConfig.y + offsetY)
	return marker
end

local function updateNameplateEliteMarker(unitFrame, unit)
	local marker = unitFrame and nameplateEliteMarkersByUnitFrame[unitFrame]
	if not isNameplateEliteMarkersActive() or not isNameplateUnitToken(unit) then
		if marker then marker:Hide() end
		return
	end

	local markerKind = getNameplateEliteMarkerKind(unit)
	marker = getNameplateEliteMarker(unitFrame, markerKind)
	if marker then marker:SetShown(markerKind ~= false) end
end

local function hideAllNameplateEliteMarkers()
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
	for _, namePlate in pairs(C_NamePlate.GetNamePlates() or {}) do
		local unitFrame = namePlate and namePlate.UnitFrame
		local marker = unitFrame and nameplateEliteMarkersByUnitFrame[unitFrame]
		if marker then marker:Hide() end
	end
end

local TARGET_MARKER_DEFAULT_ATLAS = "shop-header-arrow-hover"
addon.variables.nameplateTargetMarkerAtlases = {
	["common-icon-forwardarrow"] = "right",
	["CovenantSanctum-Renown-Arrow"] = "left",
	["CovenantSanctum-Renown-DoubleArrow"] = "left",
	["CovenantSanctum-Renown-DoubleArrow-Hover"] = "left",
	["gearupdate-arrow-bullet-point"] = "right",
	["pvptalents-selectedarrow"] = "right",
	["shop-header-arrow-hover"] = "left",
	["wowlabs-spectatecycling-arrowright"] = "right",
}
local TARGET_MARKER_OFFSET = 2

local function getNameplateTargetMarkerAtlas()
	local atlas = addon.db and addon.db[NAMEPLATE_TARGET_MARKER_ATLAS_DB_KEY] or TARGET_MARKER_DEFAULT_ATLAS
	if type(atlas) ~= "string" or not addon.variables.nameplateTargetMarkerAtlases[atlas] then atlas = TARGET_MARKER_DEFAULT_ATLAS end
	return atlas
end

local function getNameplateTargetMarkerSize()
	local size = addon.db and tonumber(addon.db[NAMEPLATE_TARGET_MARKER_SIZE_DB_KEY]) or 18
	if size < 8 then size = 8 end
	if size > 64 then size = 64 end
	return size
end

local function getNameplateTargetMarkers(unitFrame)
	if not isNameplateTargetMarkersActive() then return nil, nil end
	local anchor = getNameplateQuestMarkerAnchor(unitFrame)
	if not anchor then return nil, nil end

	local left = nameplateTargetLeftMarkersByUnitFrame[unitFrame]
	if not left then
		left = unitFrame:CreateTexture(nil, "OVERLAY")
		left:Hide()
		nameplateTargetLeftMarkersByUnitFrame[unitFrame] = left
	end

	local right = nameplateTargetRightMarkersByUnitFrame[unitFrame]
	if not right then
		right = unitFrame:CreateTexture(nil, "OVERLAY")
		right:Hide()
		nameplateTargetRightMarkersByUnitFrame[unitFrame] = right
		local levelFrame = unitFrame.PlayerLevelDiffFrame
		if levelFrame and levelFrame.HookScript then
			local function refreshAnchors() getNameplateTargetMarkers(unitFrame) end
			levelFrame:HookScript("OnShow", refreshAnchors)
			levelFrame:HookScript("OnHide", refreshAnchors)
		end
	end

	local atlas = getNameplateTargetMarkerAtlas()
	local size = getNameplateTargetMarkerSize()
	left:SetAtlas(atlas, true)
	right:SetAtlas(atlas, true)
	if left.SetRotation and right.SetRotation then
		local atlasPointsRight = addon.variables.nameplateTargetMarkerAtlases[atlas] == "right"
		left:SetRotation(atlasPointsRight and 0 or math.pi)
		right:SetRotation(atlasPointsRight and math.pi or 0)
	end
	left:SetSize(size, size)
	right:SetSize(size, size)
	local leftAnchor, rightAnchor = anchor, anchor
	local leftOffset, rightOffset = TARGET_MARKER_OFFSET, TARGET_MARKER_OFFSET
	local levelFrame = unitFrame.PlayerLevelDiffFrame
	if levelFrame and levelFrame:IsShown() and not (addon.db and addon.db.nameplateLevelReplace == true) then
		-- Use the client layout without measuring restricted nameplate regions.
		rightAnchor, rightOffset = levelFrame, TARGET_MARKER_OFFSET
	end
	left:ClearAllPoints()
	left:SetPoint("RIGHT", leftAnchor, "LEFT", -leftOffset, 0)
	right:ClearAllPoints()
	right:SetPoint("LEFT", rightAnchor, "RIGHT", rightOffset, 0)
	return left, right
end

local function updateNameplateTargetMarkers(unitFrame, unit)
	local left = unitFrame and nameplateTargetLeftMarkersByUnitFrame[unitFrame]
	local right = unitFrame and nameplateTargetRightMarkersByUnitFrame[unitFrame]
	if not isNameplateTargetMarkersActive() or not isNameplateUnitToken(unit) then
		if left then left:Hide() end
		if right then right:Hide() end
		return
	end

	local isTarget = UnitIsUnit and UnitIsUnit(unit, "target") == true
	if isTarget and addon.db and addon.db.nameplateTargetMarkerHideFriendly == true and UnitIsFriend and UnitIsFriend("player", unit) == true then isTarget = false end
	left, right = getNameplateTargetMarkers(unitFrame)
	if left then left:SetShown(isTarget) end
	if right then right:SetShown(isTarget) end
end

local function refreshNameplateTargetMarkerForUnit(unit)
	if not (unit and C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return nil end
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
	local unitFrame = namePlate and namePlate.UnitFrame
	if not unitFrame then return nil end
	local displayedUnit = unitFrame.unit
	if not isNameplateUnitToken(displayedUnit) then displayedUnit = unit end
	updateNameplateTargetMarkers(unitFrame, displayedUnit)
	return displayedUnit
end

local function refreshCurrentAndPreviousNameplateTargetMarkers()
	if nameplateTargetMarkerLastUnit then refreshNameplateTargetMarkerForUnit(nameplateTargetMarkerLastUnit) end
	local currentUnit = refreshNameplateTargetMarkerForUnit("target")
	nameplateTargetMarkerLastUnit = isNameplateUnitToken(currentUnit) and currentUnit or nil
end

local function hideAllNameplateTargetMarkers()
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
	for _, namePlate in pairs(C_NamePlate.GetNamePlates() or {}) do
		local unitFrame = namePlate and namePlate.UnitFrame
		local left = unitFrame and nameplateTargetLeftMarkersByUnitFrame[unitFrame]
		local right = unitFrame and nameplateTargetRightMarkersByUnitFrame[unitFrame]
		if left then left:Hide() end
		if right then right:Hide() end
	end
	nameplateTargetMarkerLastUnit = nil
end

addon.variables.nameplateFocusHealthbarDefaultTexture = "Interface\\TargetingFrame\\UI-StatusBar"

function addon.functions.GetNameplateHealthbarTexture()
	local fallback = addon.variables.nameplateFocusHealthbarDefaultTexture
	local configured = addon.db and addon.db[NAMEPLATE_HEALTHBAR_TEXTURE_DB_KEY] or fallback
	if addon.functions.ResolveLSMMedia then return addon.functions.ResolveLSMMedia("statusbar", configured, fallback, true) or fallback end
	return configured or fallback
end

function addon.functions.GetNameplateFocusHealthbarTexture()
	local fallback = addon.variables.nameplateFocusHealthbarDefaultTexture
	local configured = addon.db and addon.db[NAMEPLATE_FOCUS_HEALTHBAR_TEXTURE_DB_KEY] or fallback
	if addon.functions.ResolveLSMMedia then return addon.functions.ResolveLSMMedia("statusbar", configured, fallback, true) or fallback end
	return configured or fallback
end

function addon.functions.RestoreNameplateHealthbarTexture(healthBar)
	if not (healthBar and healthBar.SetStatusBarTexture) then return end
	local defaults = nameplateFocusHealthbarDefaults[healthBar]
	if not defaults then return end
	if defaults.maskedTexture and defaults.mask and defaults.maskedTexture.RemoveMaskTexture then
		defaults.maskedTexture:RemoveMaskTexture(defaults.mask)
		defaults.mask:Hide()
	end
	if defaults.atlas then
		healthBar:SetStatusBarTexture(defaults.atlas)
	elseif defaults.texture then
		healthBar:SetStatusBarTexture(defaults.texture)
	end
	local texture = healthBar.GetStatusBarTexture and healthBar:GetStatusBarTexture()
	if texture and defaults.texCoord then texture:SetTexCoord(unpack(defaults.texCoord)) end
	nameplateFocusHealthbarDefaults[healthBar] = nil
end

function addon.functions.ApplyNameplateFocusHealthbarTexture(unitFrame, unit)
	local healthBar = getNameplateHealthBar(unitFrame)
	if not healthBar then return end

	local isFocus = nameplateFocusHealthbarTextureActive == true and isNameplateUnitToken(unit) and UnitIsUnit and UnitIsUnit(unit, "focus") == true
	local customTexture
	if isFocus then
		customTexture = addon.functions.GetNameplateFocusHealthbarTexture()
	elseif nameplateHealthbarTextureActive == true then
		customTexture = addon.functions.GetNameplateHealthbarTexture()
	end
	if not customTexture then
		addon.functions.RestoreNameplateHealthbarTexture(healthBar)
		return
	end

	local defaults = nameplateFocusHealthbarDefaults[healthBar]
	if not defaults then
		local texture = healthBar.GetStatusBarTexture and healthBar:GetStatusBarTexture()
		local texCoord
		if texture and texture.GetTexCoord then texCoord = { texture:GetTexCoord() } end
		defaults = {
			texture = texture and texture.GetTexture and texture:GetTexture() or nil,
			atlas = texture and texture.GetAtlas and texture:GetAtlas() or nil,
			texCoord = texCoord,
		}
		nameplateFocusHealthbarDefaults[healthBar] = defaults
	elseif defaults.maskedTexture and defaults.mask and defaults.maskedTexture.RemoveMaskTexture then
		defaults.maskedTexture:RemoveMaskTexture(defaults.mask)
		defaults.maskedTexture = nil
	end

	healthBar:SetStatusBarTexture(customTexture)
	local texture = healthBar.GetStatusBarTexture and healthBar:GetStatusBarTexture()
	if texture and texture.AddMaskTexture and healthBar.CreateMaskTexture then
		local mask = healthBar.EQoLFocusHealthbarMask
		if not mask then
			mask = healthBar:CreateMaskTexture(nil, "ARTWORK")
			healthBar.EQoLFocusHealthbarMask = mask
		end
		mask:ClearAllPoints()
		mask:SetAllPoints(healthBar)
		if defaults.atlas then
			mask:SetAtlas(defaults.atlas)
		elseif defaults.texture then
			mask:SetTexture(defaults.texture)
			if defaults.texCoord then mask:SetTexCoord(unpack(defaults.texCoord)) end
		else
			mask:SetAtlas("UI-HUD-CoolDownManager-Bar")
		end
		mask:Show()
		texture:AddMaskTexture(mask)
		defaults.mask = mask
		defaults.maskedTexture = texture
	end
end

function addon.functions.RefreshNameplateFocusHealthbarTextureForUnit(unit)
	if not (unit and C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return nil end
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
	local unitFrame = namePlate and namePlate.UnitFrame
	if not unitFrame then return nil end
	local displayedUnit = unitFrame.unit
	if not isNameplateUnitToken(displayedUnit) then displayedUnit = unit end
	addon.functions.ApplyNameplateFocusHealthbarTexture(unitFrame, displayedUnit)
	return displayedUnit
end

function addon.functions.RefreshCurrentAndPreviousNameplateFocusHealthbarTextures()
	if nameplateFocusHealthbarTextureLastUnit then addon.functions.RefreshNameplateFocusHealthbarTextureForUnit(nameplateFocusHealthbarTextureLastUnit) end
	local currentUnit = addon.functions.RefreshNameplateFocusHealthbarTextureForUnit("focus")
	nameplateFocusHealthbarTextureLastUnit = isNameplateUnitToken(currentUnit) and currentUnit or nil
end

function addon.functions.RestoreAllNameplateFocusHealthbarTextures()
	for healthBar in pairs(nameplateFocusHealthbarDefaults) do
		addon.functions.RestoreNameplateHealthbarTexture(healthBar)
	end
	nameplateFocusHealthbarTextureLastUnit = nil
end

local function getNameplateMobColor(dbKey, unit)
	local color = addon.db and addon.db[dbKey]
	if type(color) ~= "table" then return getNameplateMobColorDefault(dbKey, unit) end

	if colorsMatch(color, NAMEPLATE_MOB_COLOR_DEFAULTS[dbKey]) or isLegacyNameplateMobFallbackColor(dbKey, color) then
		return getNameplateMobColorDefault(dbKey, unit)
	end

	return color
end

-- Cache only assigned player tanks; pets and raid assist assignments are not tank roles.
function nameplateMobColorState.RefreshOtherTanks()
	local tanks = {}
	nameplateMobColorState.otherTanks = tanks
	nameplateMobColorState.otherTanksDirty = false
	if type(UnitGroupRolesAssigned) ~= "function" or type(UnitIsUnit) ~= "function" then return end
	local inRaid = IsInRaid and IsInRaid()
	if isSecretValue(inRaid) then return end
	for i = 1, inRaid and 40 or 4 do
		local unit = (inRaid and "raid" or "party") .. i
		local isPlayer = UnitIsUnit(unit, "player")
		local role = UnitGroupRolesAssigned(unit)
		if not isSecretValue(isPlayer) and not isPlayer and not isSecretValue(role) and role == "TANK" then tanks[#tanks + 1] = unit end
	end
end

function nameplateMobColorState.GetOtherTankColor(unitFrame)
	if not nameplateMobColorState.isActive or not (addon.db and addon.db.nameplateMobColorOtherTankEnabled == true) then return nil end
	if not isPlayerEffectivelyTank() or type(UnitThreatSituation) ~= "function" then return nil end
	if not unitFrame or isSecretValue(unitFrame) then return nil end
	local unit = unitFrame.displayedUnit
	if isSecretValue(unit) then unit = nil end
	if not isNameplateUnitToken(unit) then unit = unitFrame.unit end
	if not isNameplateUnitToken(unit) then return nil end
	local ownThreat = UnitThreatSituation("player", unit)
	if isSecretValue(ownThreat) then return nil end
	-- Preserve the warning while approaching or losing aggro, and our own safe color.
	if ownThreat ~= nil and ownThreat ~= 0 then return nil end
	if nameplateMobColorState.otherTanksDirty or not nameplateMobColorState.otherTanks then nameplateMobColorState.RefreshOtherTanks() end
	for _, tank in ipairs(nameplateMobColorState.otherTanks) do
		local threat = UnitThreatSituation(tank, unit)
		if not isSecretValue(threat) and threat == 3 then return getNameplateMobColor("nameplateMobColorOtherTank") end
	end
	return nil
end

-- Keep Blizzard's threat priority, but calculate it for EQOL's own mob colors
-- even when Blizzard's native threat health bar color option is disabled.
local function getNameplateThreatStatus(unitFrame)
	if not nameplateMobColorState.isActive then return nil end
	if not unitFrame or issecretvalue(unitFrame) then return nil end

	local threatUnit = unitFrame.displayedUnit
	if issecretvalue(threatUnit) then threatUnit = nil end
	if not isNameplateUnitToken(threatUnit) then threatUnit = unitFrame.unit end
	if not isNameplateUnitToken(threatUnit) then return nil end

	if type(UnitInParty) == "function" and UnitInParty("player") == false then return nil end

	local explicitThreatSituation = issecretvalue(unitFrame.explicitThreatSituation) and nil or unitFrame.explicitThreatSituation
	if type(explicitThreatSituation) == "number" then return explicitThreatSituation > 0 and explicitThreatSituation or nil end

	local optionTable = unitFrame.optionTable
	local usePlayerForAggroHighlightThreat = type(optionTable) == "table" and optionTable.usePlayerForAggroHighlightThreat == true
	local threatStatus

	if usePlayerForAggroHighlightThreat then
		local isTank = PlayerUtil and type(PlayerUtil.IsPlayerEffectivelyTank) == "function" and PlayerUtil.IsPlayerEffectivelyTank() or false
		if issecretvalue(isTank) then isTank = false end

		if isTank and type(UnitThreatLeadSituation) == "function" then
			threatStatus = UnitThreatLeadSituation("player", threatUnit)
		elseif type(UnitThreatSituation) == "function" then
			threatStatus = UnitThreatSituation("player", threatUnit)
		end
	elseif type(UnitThreatSituation) == "function" then
		threatStatus = UnitThreatSituation(threatUnit)
	end

	if issecretvalue(threatStatus) then threatStatus = nil end
	if type(threatStatus) ~= "number" or threatStatus <= 0 then return nil end
	return threatStatus
end

local function getNameplateThreatColor(unitFrame, threatStatus)
	if type(threatStatus) ~= "number" then threatStatus = getNameplateThreatStatus(unitFrame) end
	if type(threatStatus) ~= "number" then return nil end
	if threatStatus >= 3 then
		if not (addon.db and addon.db.nameplateMobColorThreatLostEnabled == true) then return nil end
		return getNameplateMobColor(NAMEPLATE_MOB_COLOR_THREAT_LOST_DB_KEY)
	end
	if not (addon.db and addon.db.nameplateMobColorThreatWarningEnabled == true) then return nil end
	return getNameplateMobColor(NAMEPLATE_MOB_COLOR_THREAT_WARNING_DB_KEY)
end

local function getNameplateTankModeColor(unitFrame, threatStatus)
	if not nameplateMobColorState.isActive then return nil end
	if not (addon.db and addon.db[NAMEPLATE_MOB_TANK_MODE_DB_KEY] == true) then return nil end
	if not isPlayerEffectivelyTank() then return nil end
	if not isNameplateUnitOnThreatListWithPlayer(unitFrame) then return nil end
	if type(threatStatus) == "number" and threatStatus > 0 then return nil end
	return getNameplateMobColor(NAMEPLATE_MOB_COLOR_TANK_MODE_DB_KEY)
end

local function getNameplateMobLevel(unit)
	local mobLevel = UnitEffectiveLevel and UnitEffectiveLevel(unit)
	if isSecretValue(mobLevel) then mobLevel = nil end
	if type(mobLevel) ~= "number" and type(UnitLevel) == "function" then
		mobLevel = UnitLevel(unit)
		if isSecretValue(mobLevel) then mobLevel = nil end
	end
	return type(mobLevel) == "number" and mobLevel or nil
end

local function isManaUsingNameplateMob(unit)
	if type(UnitPowerType) ~= "function" then return false end

	local powerType, powerToken = UnitPowerType(unit)
	if isSecretValue(powerType) then powerType = nil end
	if isSecretValue(powerToken) then powerToken = nil end

	if powerToken == "MANA" then return true end

	local manaPowerType = Enum and Enum.PowerType and Enum.PowerType.Mana
	return type(powerType) == "number" and type(manaPowerType) == "number" and powerType == manaPowerType
end

local function computeNameplateMobColor(unit, unitFrame)
	if not nameplateMobColorState.isActive then return nil end
	if not isNameplateUnitToken(unit) then return nil end
	if isNeutralUnit(unit) then
		-- Blizzard flips neutral nameplates to hostile once the player is on their threat list.
		if isNameplateUnitOnThreatListWithPlayer(unitFrame) then return nil end
		if addon.db and addon.db.nameplateMobColorQuestNeutralEnabled == true and isNameplateQuestObjectiveUnit(unit) then return getNameplateMobColor("nameplateMobColorQuestNeutral", unit) end
		if addon.db and addon.db.nameplateMobColorNeutralEnabled == true then return getNameplateMobColor(NAMEPLATE_MOB_COLOR_NEUTRAL_DB_KEY, unit) end
		return nil
	end
	if isPlayerControlledNameplateUnit(unit) then return nil end

	local canAttack = UnitCanAttack("player", unit)
	if isSecretValue(canAttack) or not canAttack then return nil end

	if addon.db and addon.db.nameplateMobColorQuestHostileEnabled == true and isNameplateQuestObjectiveUnit(unit) then return getNameplateMobColor("nameplateMobColorQuestHostile", unit) end

	local classification = UnitClassification and UnitClassification(unit)
	if isSecretValue(classification) then classification = nil end
	if classification == "worldboss" then
		if addon.db and addon.db.nameplateMobColorBossEnabled == true then return getNameplateMobColor(NAMEPLATE_MOB_COLOR_BOSS_DB_KEY) end
		return nil
	elseif classification == "elite" or classification == "rare" or classification == "rareelite" then
		local mobLevel = getNameplateMobLevel(unit)

		local isLieutenant = type(_G.UnitIsLieutenant) == "function" and _G.UnitIsLieutenant(unit) or false
		if isSecretValue(isLieutenant) then isLieutenant = false end

		local referenceLevel = nameplateMobColorState.referenceLevel
		local lieutenantLevel = nameplateMobColorState.lieutenantLevel
		local isMiniBoss = type(mobLevel) == "number" and referenceLevel and mobLevel == (referenceLevel + 1)
		local isBoss = mobLevel == -1
			or (type(mobLevel) == "number" and referenceLevel and mobLevel == (referenceLevel + 2))
			or (type(mobLevel) == "number" and lieutenantLevel and mobLevel == (lieutenantLevel + 1))

		if isMiniBoss or isLieutenant then
			nameplateMobColorState.lieutenantLevel = mobLevel
			if addon.db and addon.db.nameplateMobColorMinibossEnabled == true then return getNameplateMobColor(NAMEPLATE_MOB_COLOR_MINIBOSS_DB_KEY) end
			return nil
		elseif isBoss then
			if addon.db and addon.db.nameplateMobColorBossEnabled == true then return getNameplateMobColor(NAMEPLATE_MOB_COLOR_BOSS_DB_KEY) end
			return nil
		end

		if nameplateMobColorState.isInstancedPve ~= true then
			if addon.db and addon.db.nameplateMobColorMinibossEnabled == true then return getNameplateMobColor(NAMEPLATE_MOB_COLOR_MINIBOSS_DB_KEY) end
			return nil
		end
		if isManaUsingNameplateMob(unit) then
			if addon.db and addon.db.nameplateMobColorCasterEnabled == true then return getNameplateMobColor(NAMEPLATE_MOB_COLOR_CASTER_DB_KEY) end
			return nil
		end
		if addon.db and addon.db.nameplateMobColorMeleeEnabled == true then return getNameplateMobColor(NAMEPLATE_MOB_COLOR_MELEE_DB_KEY) end
		return nil
	elseif classification == "normal" then
		if isManaUsingNameplateMob(unit) then
			if addon.db and addon.db.nameplateMobColorCasterEnabled == true then return getNameplateMobColor(NAMEPLATE_MOB_COLOR_CASTER_DB_KEY) end
			return nil
		end
		if addon.db and addon.db.nameplateMobColorMeleeEnabled == true then return getNameplateMobColor(NAMEPLATE_MOB_COLOR_MELEE_DB_KEY) end
		return nil
	elseif classification == "trivial" or classification == "minus" then
		if addon.db and addon.db.nameplateMobColorTrivialEnabled == true then return getNameplateMobColor(NAMEPLATE_MOB_COLOR_TRIVIAL_DB_KEY) end
		return nil
	end

	return nil
end

local function applyNameplateMobColor(unitFrame)
	if not unitFrame or isSecretValue(unitFrame) then return end

	local unit = unitFrame.unit
	if not isNameplateUnitToken(unit) then return end
	if isPlayerControlledNameplateUnit(unit) then return end

	updateNameplateMobColorContext()
	if not nameplateMobColorState.isActive then return end
	local threatStatus = getNameplateThreatStatus(unitFrame)
	local color
	if addon.db and addon.db.nameplateMobColorFocusEnabled == true and UnitIsUnit(unit, "focus") then color = getNameplateMobColor(NAMEPLATE_MOB_COLOR_FOCUS_DB_KEY) end
	if not color and addon.db and addon.db.nameplateMobColorOtherTankEnabled == true then color = nameplateMobColorState.GetOtherTankColor(unitFrame) end
	if not color then color = getNameplateTankModeColor(unitFrame, threatStatus) end
	if not color then color = getNameplateThreatColor(unitFrame, threatStatus) end
	if not color and type(threatStatus) == "number" then return end
	if not color and UnitIsTapDenied then
		local tapDenied = UnitIsTapDenied(unit)
		if isSecretValue(tapDenied) then tapDenied = false end
		if tapDenied then
			if addon.db and addon.db.nameplateMobColorTappedEnabled == true then
				color = getNameplateMobColor("nameplateMobColorTapped")
			else
				return
			end
		end
	end
	if not color then color = computeNameplateMobColor(unit, unitFrame) end
	if not color then return end

	local healthBar = getNameplateHealthBar(unitFrame)
	if not healthBar then return end

	local currentR, currentG, currentB = healthBar:GetStatusBarColor()
	local targetR = isSecretValue(color.r) and nil or color.r
	local targetG = isSecretValue(color.g) and nil or color.g
	local targetB = isSecretValue(color.b) and nil or color.b
	if type(targetR) ~= "number" or type(targetG) ~= "number" or type(targetB) ~= "number" then return end
	if not isSecretValue(currentR) and not isSecretValue(currentG) and not isSecretValue(currentB) and currentR == targetR and currentG == targetG and currentB == targetB then return end
	healthBar:SetStatusBarColor(targetR, targetG, targetB)
	local appliedColor = nameplateMobColorState.appliedColors[unitFrame] or {}
	appliedColor.unit, appliedColor.r, appliedColor.g, appliedColor.b = unit, targetR, targetG, targetB
	nameplateMobColorState.appliedColors[unitFrame] = appliedColor
end

local function applyNameplateBaseHealthColor(unitFrame)
	if not unitFrame or isSecretValue(unitFrame) then return false end
	local unit = unitFrame.unit
	if not isNameplateUnitToken(unit) then return false end
	local displayedUnit = unitFrame.displayedUnit
	if isSecretValue(displayedUnit) then displayedUnit = unit end

	local healthBar = getNameplateHealthBar(unitFrame)
	if not healthBar then return false end

	local connected = UnitIsConnected and UnitIsConnected(unit)
	if isSecretValue(connected) then return false end
	local isDead = connected and UnitIsDead and UnitIsDead(unit)
	if isSecretValue(isDead) then return false end
	local unitIsPlayer = UnitIsPlayer and UnitIsPlayer(unit)
	if isSecretValue(unitIsPlayer) then unitIsPlayer = false end
	local displayedUnitIsPlayer = UnitIsPlayer and UnitIsPlayer(displayedUnit)
	if isSecretValue(displayedUnitIsPlayer) then displayedUnitIsPlayer = false end
	local isPlayer = unitIsPlayer or displayedUnitIsPlayer
	if isSecretValue(isPlayer) then return false end

	local r, g, b
	if not connected or (isDead and not isPlayer) then
		r, g, b = 0.5, 0.5, 0.5
	else
		local optionTable = unitFrame.optionTable
		if type(optionTable) == "table" and type(optionTable.healthBarColorOverride) == "table" then
			local color = optionTable.healthBarColorOverride
			r, g, b = color.r, color.g, color.b
		else
			local localizedClass, englishClass = UnitClass(unit)
			if isSecretValue(localizedClass) then localizedClass = nil end
			if isSecretValue(englishClass) then englishClass = nil end
			local classColor = englishClass and RAID_CLASS_COLORS and RAID_CLASS_COLORS[englishClass]
			local useClassColors = false
			if type(_G.CompactUnitFrame_GetOptionUseClassColors) == "function" and type(optionTable) == "table" then
				useClassColors = _G.CompactUnitFrame_GetOptionUseClassColors(unitFrame, optionTable)
				if isSecretValue(useClassColors) then useClassColors = false end
			end

			local treatAsPlayer = _G.UnitTreatAsPlayerForDisplay and _G.UnitTreatAsPlayerForDisplay(unit)
			if isSecretValue(treatAsPlayer) then treatAsPlayer = false end
			if type(optionTable) == "table" and (optionTable.allowClassColorsForNPCs or isPlayer or treatAsPlayer) and classColor and useClassColors then
				r, g, b = classColor.r, classColor.g, classColor.b
			else
				local tapDenied = UnitIsTapDenied and UnitIsTapDenied(unit)
				if isSecretValue(tapDenied) then tapDenied = false end
				if tapDenied then
					r, g, b = 0.9, 0.9, 0.9
				elseif type(optionTable) == "table" and optionTable.colorHealthBySelection and type(UnitSelectionColor) == "function" then
					local onThreatList = type(_G.CompactUnitFrame_IsOnThreatListWithPlayer) == "function" and _G.CompactUnitFrame_IsOnThreatListWithPlayer(displayedUnit)
					if isSecretValue(onThreatList) then onThreatList = false end
					local isFriend = UnitIsFriend and UnitIsFriend("player", unit)
					if isSecretValue(isFriend) then isFriend = false end
					if optionTable.considerSelectionInCombatAsHostile and onThreatList and not isFriend then
						r, g, b = 1, 0, 0
					else
						local displayedUnitIsFriend = UnitIsFriend and UnitIsFriend("player", displayedUnit)
						if isSecretValue(displayedUnitIsFriend) then displayedUnitIsFriend = false end
						if displayedUnitIsPlayer and displayedUnitIsFriend then
							r, g, b = 0.667, 0.667, 1
						else
							r, g, b = UnitSelectionColor(unit, optionTable.colorHealthWithExtendedColors)
							if isSecretValue(r) or isSecretValue(g) or isSecretValue(b) then return false end
						end
					end
				else
					local isFriend = UnitIsFriend and UnitIsFriend("player", unit)
					if isSecretValue(isFriend) then isFriend = false end
					if isFriend then
						r, g, b = 0, 1, 0
					else
						r, g, b = 1, 0, 0
					end
				end
			end
		end
	end

	if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return false end
	healthBar:SetStatusBarColor(r, g, b)
	if unitFrame.selectionHighlight then
		local optionTable = unitFrame.optionTable
		if type(optionTable) == "table" and optionTable.colorHealthWithExtendedColors then
			unitFrame.selectionHighlight:SetVertexColor(r, g, b)
		else
			unitFrame.selectionHighlight:SetVertexColor(1, 1, 1)
		end
	end
	return true
end

local function refreshNameplateMobColorUnitFrame(unitFrame, refreshKind)
	if not unitFrame or isSecretValue(unitFrame) then return end
	local unit = unitFrame.unit
	if not isNameplateUnitToken(unit) then return end

	if refreshKind == "quest" then
		updateNameplateQuestMarker(unitFrame, unit)
		refreshKind = "colors"
	elseif refreshKind == "elite" then
		updateNameplateEliteMarker(unitFrame, unit)
		return
	elseif refreshKind == "target" then
		updateNameplateTargetMarkers(unitFrame, unit)
		return
	elseif refreshKind == "focus" then
		addon.functions.ApplyNameplateFocusHealthbarTexture(unitFrame, unit)
		return
	end

	updateNameplateMobColorContext()
	if refreshKind ~= "colors" then
		updateNameplateEliteMarker(unitFrame, unit)
		updateNameplateQuestMarker(unitFrame, unit)
		updateNameplateTargetMarkers(unitFrame, unit)
		addon.functions.ApplyNameplateFocusHealthbarTexture(unitFrame, unit)
	end
	if not isNameplateMobColorsActive() then return end

	if isPlayerControlledNameplateUnit(unit) then
		nameplateMobColorState.appliedColors[unitFrame] = nil
		return
	end
	if not nameplateMobColorState.isActive then
		local appliedColor = nameplateMobColorState.appliedColors[unitFrame]
		nameplateMobColorState.appliedColors[unitFrame] = nil
		if not appliedColor or appliedColor.unit ~= unit then return end
		local healthBar = getNameplateHealthBar(unitFrame)
		if not healthBar then return end
		local r, g, b = healthBar:GetStatusBarColor()
		-- Restore only our own unchanged color, once; leave other color providers alone.
		if not isSecretValue(r) and not isSecretValue(g) and not isSecretValue(b) and r == appliedColor.r and g == appliedColor.g and b == appliedColor.b then
			applyNameplateBaseHealthColor(unitFrame)
		end
		return
	end

	if applyNameplateBaseHealthColor(unitFrame) then nameplateMobColorState.appliedColors[unitFrame] = nil end
	applyNameplateMobColor(unitFrame)
end

local function refreshAllNameplateMobColors(refreshKind)
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
	for _, namePlate in pairs(C_NamePlate.GetNamePlates() or {}) do
		local unitFrame = namePlate and namePlate.UnitFrame
		if unitFrame then refreshNameplateMobColorUnitFrame(unitFrame, refreshKind) end
	end
end

function addon.functions.ScheduleNameplateQuestMarkerRefresh()
	local timer = addon.variables.nameplateQuestMarkerRefreshTimer
	if timer and not timer._cancelled and timer.Cancel then
		timer:Cancel()
	end
	if not (C_Timer and C_Timer.NewTimer) then
		refreshAllNameplateMobColors("quest")
		return
	end

	addon.variables.nameplateQuestMarkerRefreshTimer = C_Timer.NewTimer(1, function()
		addon.variables.nameplateQuestMarkerRefreshTimer = nil
		refreshAllNameplateMobColors("quest")
	end)
end

local function ensureNameplateMobColorHooks()
	local needsMobColorHooks = isNameplateMobColorsActive()
	local needsHealthbarTextureHook = nameplateHealthbarTextureActive or nameplateFocusHealthbarTextureActive
	if (not needsMobColorHooks or nameplateMobColorHooksInstalled) and (not needsHealthbarTextureHook or nameplateHealthbarTextureHookInstalled) then return end
	if type(hooksecurefunc) ~= "function" then return end

	if needsMobColorHooks and not nameplateMobColorHooksInstalled then
		local installedAnyHook = false
		if type(_G.CompactUnitFrame_UpdateHealthColor) == "function" then
			hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(unitFrame)
				if unitFrame and not isSecretValue(unitFrame) then nameplateMobColorState.appliedColors[unitFrame] = nil end
				applyNameplateMobColor(unitFrame)
			end)
			installedAnyHook = true
		end

		if type(_G.CompactUnitFrame_UpdateAll) == "function" then
			hooksecurefunc("CompactUnitFrame_UpdateAll", function(unitFrame) applyNameplateMobColor(unitFrame) end)
			installedAnyHook = true
		end

		nameplateMobColorHooksInstalled = installedAnyHook
	end

	local namePlateMixin = _G.NamePlateUnitFrameMixin
	if needsHealthbarTextureHook and not nameplateHealthbarTextureHookInstalled and type(namePlateMixin) == "table" and type(namePlateMixin.UpdateAnchors) == "function" then
		hooksecurefunc(namePlateMixin, "UpdateAnchors", function(unitFrame)
			if nameplateHealthbarTextureActive or nameplateFocusHealthbarTextureActive then
				addon.functions.ApplyNameplateFocusHealthbarTexture(unitFrame, unitFrame and unitFrame.unit)
			end
		end)
		nameplateHealthbarTextureHookInstalled = true
	end
end

local function ensureNameplateMobColorWatcher()
	ensureNameplateMobColorHooks()
	if nameplateMobColorFrame then return end

	nameplateMobColorFrame = CreateFrame("Frame")
	nameplateMobColorFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	nameplateMobColorFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	nameplateMobColorFrame:RegisterEvent("PLAYER_LEVEL_UP")
	nameplateMobColorFrame:RegisterEvent("INSTANCE_GROUP_SIZE_CHANGED")
	nameplateMobColorFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	nameplateMobColorFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
	nameplateMobColorFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	nameplateMobColorFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
	nameplateMobColorFrame:RegisterEvent("QUEST_LOG_UPDATE")
	nameplateMobColorFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	nameplateMobColorFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
	nameplateMobColorFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	nameplateMobColorFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
	nameplateMobColorFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
	nameplateMobColorFrame:SetScript("OnEvent", function(_, event, unit)
		ensureNameplateMobColorHooks()
		if event == "PLAYER_ENTERING_WORLD" or event == "INSTANCE_GROUP_SIZE_CHANGED" or event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ROLES_ASSIGNED" or event == "PLAYER_SPECIALIZATION_CHANGED" then
			nameplateMobColorState.otherTanksDirty = true
		end
		if event == "NAME_PLATE_UNIT_REMOVED" then
			if isNameplateUnitToken(unit) then nameplateQuestMarkerCache[unit] = nil end
			if unit == nameplateTargetMarkerLastUnit then nameplateTargetMarkerLastUnit = nil end
			if unit == nameplateFocusHealthbarTextureLastUnit then nameplateFocusHealthbarTextureLastUnit = nil end
			return
		elseif event == "QUEST_LOG_UPDATE" then
			clearNameplateQuestMarkerCache()
			addon.functions.ScheduleNameplateQuestMarkerRefresh()
			return
		elseif event == "PLAYER_TARGET_CHANGED" then
			refreshCurrentAndPreviousNameplateTargetMarkers()
			return
		elseif event == "PLAYER_FOCUS_CHANGED" then
			addon.functions.RefreshCurrentAndPreviousNameplateFocusHealthbarTextures()
			if isNameplateMobColorsActive() then refreshAllNameplateMobColors("colors") end
			return
		elseif event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" then
			if isNameplateUnitToken(unit) and C_NamePlate and C_NamePlate.GetNamePlateForUnit then
				local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
				local unitFrame = namePlate and namePlate.UnitFrame
				if unitFrame then refreshNameplateMobColorUnitFrame(unitFrame, "colors") end
			else
				refreshAllNameplateMobColors("colors")
			end
			return
		end

		local forceRefresh = event ~= "NAME_PLATE_UNIT_ADDED"
		if forceRefresh then nameplateMobColorState.isDirty = true end
		updateNameplateMobColorContext(forceRefresh)
		if event == "NAME_PLATE_UNIT_ADDED" and unit and C_NamePlate and C_NamePlate.GetNamePlateForUnit then
			local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
			local unitFrame = namePlate and namePlate.UnitFrame
			if unitFrame then refreshNameplateMobColorUnitFrame(unitFrame) end
			return
		end

		refreshAllNameplateMobColors()
	end)
end

local function syncNameplateMobColors()
	if not isNameplateMobColorsActive() then return end
	ensureNameplateMobColorWatcher()
	nameplateMobColorState.isDirty = true
	updateNameplateMobColorContext(true)
	refreshAllNameplateMobColors()
end

local function syncNameplateQuestMarkers()
	if not nameplateMobColorState.HasQuestDisplay() then return end
	ensureNameplateMobColorWatcher()
	clearNameplateQuestMarkerCache()
	refreshAllNameplateMobColors("quest")
end

local function syncNameplateEliteMarkers()
	if not isNameplateEliteMarkersActive() then return end
	ensureNameplateMobColorWatcher()
	refreshAllNameplateMobColors("elite")
end

local function syncNameplateTargetMarkers()
	if not isNameplateTargetMarkersActive() then return end
	ensureNameplateMobColorWatcher()
	refreshAllNameplateMobColors("target")
end

function addon.functions.SyncNameplateFocusHealthbarTextures()
	if nameplateHealthbarTextureActive ~= true and nameplateFocusHealthbarTextureActive ~= true then return end
	ensureNameplateMobColorWatcher()
	refreshAllNameplateMobColors("focus")
end

local function requestFeatureReload()
	addon.variables = addon.variables or {}
	addon.variables.requireReload = true
	if addon.functions.checkReloadFrame then addon.functions.checkReloadFrame() end
end

function addon.functions.SetDefaultNameplateMobColorsEnabled(value)
	local wasActive = isNameplateMobColorsActive()
	local enabled = value and true or false
	addon.db[NAMEPLATE_MOB_COLORS_DB_KEY] = enabled
	nameplateMobColorState.isDirty = true
	if enabled then
		nameplateMobColorsActive = true
		syncNameplateMobColors()
	elseif wasActive then
		requestFeatureReload()
	end
end

function addon.functions.RefreshDefaultNameplateMobColors()
	nameplateMobColorState.isDirty = true
	if isNameplateMobColorsActive() then syncNameplateMobColors() end
end

function addon.functions.SetDefaultNameplateQuestMarkersEnabled(value)
	local enabled = value and true or false
	addon.db[NAMEPLATE_QUEST_MARKERS_DB_KEY] = enabled
	nameplateQuestMarkersActive = enabled
	clearNameplateQuestMarkerCache()
	if nameplateMobColorState.HasQuestDisplay() then
		syncNameplateQuestMarkers()
	else
		hideAllNameplateQuestMarkers()
	end
end

function addon.functions.RefreshDefaultNameplateQuestMarkers()
	if nameplateMobColorState.HasQuestDisplay() then
		syncNameplateQuestMarkers()
	else
		hideAllNameplateQuestMarkers()
	end
end

function addon.functions.SetDefaultNameplateEliteMarkersEnabled(value)
	local enabled = value and true or false
	addon.db[NAMEPLATE_ELITE_MARKERS_DB_KEY] = enabled
	nameplateEliteMarkersActive = enabled
	if enabled then
		syncNameplateEliteMarkers()
	else
		hideAllNameplateEliteMarkers()
	end
end

function addon.functions.RefreshDefaultNameplateEliteMarkers()
	if isNameplateEliteMarkersActive() then syncNameplateEliteMarkers() end
end

function addon.functions.SetDefaultNameplateTargetMarkersEnabled(value)
	local enabled = value and true or false
	addon.db[NAMEPLATE_TARGET_MARKERS_DB_KEY] = enabled
	nameplateTargetMarkersActive = enabled
	if enabled then
		syncNameplateTargetMarkers()
	else
		hideAllNameplateTargetMarkers()
	end
end

function addon.functions.RefreshDefaultNameplateTargetMarkers()
	if isNameplateTargetMarkersActive() then syncNameplateTargetMarkers() end
end

function addon.functions.SetDefaultNameplateFocusHealthbarTexture(value)
	addon.db[NAMEPLATE_FOCUS_HEALTHBAR_TEXTURE_DB_KEY] = value
	nameplateFocusHealthbarTextureActive = type(value) == "string" and value ~= ""
	addon.functions.RestoreAllNameplateFocusHealthbarTextures()
	if nameplateHealthbarTextureActive or nameplateFocusHealthbarTextureActive then
		addon.functions.SyncNameplateFocusHealthbarTextures()
	end
end

function addon.functions.RefreshDefaultNameplateFocusHealthbarTexture()
	addon.functions.RestoreAllNameplateFocusHealthbarTextures()
	if nameplateHealthbarTextureActive or nameplateFocusHealthbarTextureActive then
		addon.functions.SyncNameplateFocusHealthbarTextures()
	end
end

function addon.functions.SetDefaultNameplateHealthbarTexture(value)
	addon.db[NAMEPLATE_HEALTHBAR_TEXTURE_DB_KEY] = value
	nameplateHealthbarTextureActive = type(value) == "string" and value ~= ""
	addon.functions.RefreshDefaultNameplateFocusHealthbarTexture()
end

local function shouldUseTimeoutReleaseForCurrentContext()
	if not addon.db or not addon.db["timeoutRelease"] then return false end

	local selection = addon.db["timeoutReleaseDifficulties"]
	if selection == nil then return true end

	local hasSelection = false
	for key, enabled in pairs(selection) do
		if enabled then
			hasSelection = true
			break
		end
	end
	if not hasSelection then return true end

	local inInstance, instanceType = IsInInstance()
	if not inInstance or instanceType == "none" then return selection["world"] and true or false end

	local difficultyID = select(3, GetInstanceInfo())
	if difficultyID then
		local keys = timeoutReleaseDifficultyLookup[difficultyID]
		if keys then
			for _, key in ipairs(keys) do
				if selection[key] then return true end
			end
		end
	end

	if instanceType == "scenario" then return selection["scenario"] and true or false end
	if instanceType == "pvp" or instanceType == "arena" then return selection["pvp"] and true or false end
	if instanceType == "raid" then return selection["raidNormal"] or selection["raidHeroic"] or selection["raidMythic"] end
	if instanceType == "party" then return selection["dungeonNormal"] or selection["dungeonHeroic"] or selection["dungeonMythic"] end

	return false
end

addon.functions.shouldUseTimeoutReleaseForCurrentContext = shouldUseTimeoutReleaseForCurrentContext

local TIMEOUT_RELEASE_UPDATE_INTERVAL = 0.1

local function isPlayerDeadOrGhost()
	if UnitIsDeadOrGhost then return UnitIsDeadOrGhost("player") == true end
	return (UnitIsDead and UnitIsDead("player")) or (UnitIsGhost and UnitIsGhost("player")) or false
end

local modifierCheckers = {
	SHIFT = function() return IsShiftKeyDown() end,
	CTRL = function() return IsControlKeyDown() end,
	ALT = function() return IsAltKeyDown() end,
}

local modifierDisplayNames = {
	SHIFT = SHIFT_KEY_TEXT,
	CTRL = CTRL_KEY_TEXT,
	ALT = ALT_KEY_TEXT,
}

local DEFAULT_TIMEOUT_RELEASE_HINT = "Hold %s to release"

function addon.functions.getTimeoutReleaseModifierKey()
	local modifierKey = addon.db and addon.db["timeoutReleaseModifier"] or "SHIFT"
	if not modifierCheckers[modifierKey] then modifierKey = "SHIFT" end
	return modifierKey
end

function addon.functions.isTimeoutReleaseModifierDown(modifierKey)
	local checker = modifierCheckers[modifierKey]
	return checker and checker() or false
end

function addon.functions.getTimeoutReleaseModifierDisplayName(modifierKey) return modifierDisplayNames[modifierKey] or modifierKey end

function addon.functions.showTimeoutReleaseHint(popup, modifierDisplayName)
	if not popup then return end
	local label = popup.eqolTimeoutReleaseLabel
	if not label then
		label = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		label:SetJustifyH("CENTER")
		label:SetPoint("BOTTOM", popup, "TOP", 0, 8)
		label:SetTextColor(1, 0.82, 0)
		label:SetWordWrap(true)
		popup.eqolTimeoutReleaseLabel = label
	end
	local hintTemplate = rawget(L, "timeoutReleaseHoldHint") or DEFAULT_TIMEOUT_RELEASE_HINT
	label:SetWidth(popup:GetWidth())
	label:SetText(hintTemplate:format(modifierDisplayName))
	label:Show()
end

function addon.functions.hideTimeoutReleaseHint(popup)
	local label = popup and popup.eqolTimeoutReleaseLabel
	if label then label:Hide() end
end


function addon.functions.initDungeonFrame()
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLORS_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLORS_DUNGEONS_DB_KEY, true)
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLORS_OUTSIDE_DUNGEONS_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_SLUG_OUTLINE_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_TEXT_FONT_DB_KEY, addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or "__EQOL_GLOBAL_FONT__")
	addon.functions.InitDBValue(NAMEPLATE_TEXT_OUTLINE_DB_KEY, addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or "__EQOL_GLOBAL_FONT_STYLE__")
	addon.functions.InitDBValue(NAMEPLATE_TEXT_SIZE_DB_KEY, 0)
	addon.functions.InitDBValue(NAMEPLATE_CAST_TEXT_SIZE_DB_KEY, 0)
	addon.functions.InitDBValue(NAMEPLATE_ELITE_MARKERS_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_ELITE_MARKER_ANCHOR_DB_KEY, "LEFT")
	addon.functions.InitDBValue(NAMEPLATE_ELITE_MARKER_SIZE_DB_KEY, 18)
	addon.functions.InitDBValue("nameplateEliteMarkerOffsetX", 0)
	addon.functions.InitDBValue("nameplateEliteMarkerOffsetY", 0)
	addon.functions.InitDBValue(NAMEPLATE_QUEST_MARKERS_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_QUEST_MARKER_ANCHOR_DB_KEY, "RIGHT")
	addon.functions.InitDBValue(NAMEPLATE_QUEST_MARKER_SIZE_DB_KEY, 18)
	addon.functions.InitDBValue("nameplateQuestProgress", false)
	addon.functions.InitDBValue("nameplateQuestProgressUseClassColor", false)
	addon.functions.InitDBValue("nameplateQuestProgressAnchor", "TOP")
	addon.functions.InitDBValue("nameplateQuestProgressFont", addon.functions.GetGlobalFontConfigKey())
	addon.functions.InitDBValue("nameplateQuestProgressOutline", addon.functions.GetGlobalFontStyleConfigKey())
	addon.functions.InitDBValue("nameplateQuestProgressSize", 12)
	addon.functions.InitDBValue("nameplateQuestProgressColor", { r = 1, g = 1, b = 1, a = 1 })
	addon.functions.InitDBValue("nameplateQuestProgressOffsetX", 0)
	addon.functions.InitDBValue("nameplateQuestProgressOffsetY", 0)
	for _, key in ipairs({ "nameplateMobColorQuestNeutral", "nameplateMobColorQuestHostile" }) do
		addon.functions.InitDBValue(key, getNameplateMobColorDefault(key))
		addon.functions.InitDBValue(key .. "Enabled", false)
	end
	addon.functions.InitDBValue("nameplateQuestMarkerOffsetX", 0)
	addon.functions.InitDBValue("nameplateQuestMarkerOffsetY", 0)
	addon.functions.InitDBValue(NAMEPLATE_TARGET_MARKERS_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_TARGET_MARKER_ATLAS_DB_KEY, TARGET_MARKER_DEFAULT_ATLAS)
	addon.functions.InitDBValue("nameplateTargetMarkerHideFriendly", false)
	addon.functions.InitDBValue(NAMEPLATE_TARGET_MARKER_SIZE_DB_KEY, 18)
	addon.functions.InitDBValue(NAMEPLATE_HEALTHBAR_TEXTURE_DB_KEY, "")
	addon.functions.InitDBValue(NAMEPLATE_FOCUS_HEALTHBAR_TEXTURE_DB_KEY, "")
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLOR_FOCUS_DB_KEY, getNameplateMobColorDefault(NAMEPLATE_MOB_COLOR_FOCUS_DB_KEY))
	addon.functions.InitDBValue("nameplateMobColorFocusEnabled", true)
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLOR_BOSS_DB_KEY, getNameplateMobColorDefault(NAMEPLATE_MOB_COLOR_BOSS_DB_KEY))
	addon.functions.InitDBValue("nameplateMobColorBossEnabled", true)
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLOR_MINIBOSS_DB_KEY, getNameplateMobColorDefault(NAMEPLATE_MOB_COLOR_MINIBOSS_DB_KEY))
	addon.functions.InitDBValue("nameplateMobColorMinibossEnabled", true)
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLOR_CASTER_DB_KEY, getNameplateMobColorDefault(NAMEPLATE_MOB_COLOR_CASTER_DB_KEY))
	addon.functions.InitDBValue("nameplateMobColorCasterEnabled", true)
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLOR_MELEE_DB_KEY, getNameplateMobColorDefault(NAMEPLATE_MOB_COLOR_MELEE_DB_KEY))
	addon.functions.InitDBValue("nameplateMobColorMeleeEnabled", true)
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLOR_NEUTRAL_DB_KEY, getNameplateMobColorDefault(NAMEPLATE_MOB_COLOR_NEUTRAL_DB_KEY))
	addon.functions.InitDBValue("nameplateMobColorNeutralEnabled", true)
	addon.functions.InitDBValue("nameplateMobColorTapped", getNameplateMobColorDefault("nameplateMobColorTapped"))
	addon.functions.InitDBValue("nameplateMobColorTappedEnabled", true)
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLOR_TANK_MODE_DB_KEY, getNameplateMobColorDefault(NAMEPLATE_MOB_COLOR_TANK_MODE_DB_KEY))
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLOR_THREAT_LOST_DB_KEY, getNameplateMobColorDefault(NAMEPLATE_MOB_COLOR_THREAT_LOST_DB_KEY))
	addon.functions.InitDBValue("nameplateMobColorThreatLostEnabled", true)
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLOR_THREAT_WARNING_DB_KEY, getNameplateMobColorDefault(NAMEPLATE_MOB_COLOR_THREAT_WARNING_DB_KEY))
	addon.functions.InitDBValue("nameplateMobColorThreatWarningEnabled", true)
	addon.functions.InitDBValue("nameplateMobColorOtherTank", getNameplateMobColorDefault("nameplateMobColorOtherTank"))
	addon.functions.InitDBValue("nameplateMobColorOtherTankEnabled", false)
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLOR_TRIVIAL_DB_KEY, getNameplateMobColorDefault(NAMEPLATE_MOB_COLOR_TRIVIAL_DB_KEY))
	addon.functions.InitDBValue("nameplateMobColorTrivialEnabled", true)
	addon.functions.InitDBValue(NAMEPLATE_MOB_TANK_MODE_DB_KEY, false)
	addon.functions.InitDBValue("timeoutReleaseDifficulties", {})
	addon.functions.InitDBValue("autoCombatLog", false)
	addon.functions.InitDBValue("combatLogDungeonDifficulties", {})
	addon.functions.InitDBValue("combatLogRaidDifficulties", {})
	addon.functions.InitDBValue("combatLogRaidCurrentExpansionOnly", true)
	addon.functions.InitDBValue("combatLogPvp", false)
	addon.functions.InitDBValue("combatLogScenario", false)
	addon.functions.InitDBValue("combatLogDelayedStop", false)

	nameplateMobColorsActive = addon.db and addon.db[NAMEPLATE_MOB_COLORS_DB_KEY] == true
	nameplateEliteMarkersActive = addon.db and addon.db[NAMEPLATE_ELITE_MARKERS_DB_KEY] == true
	nameplateQuestMarkersActive = addon.db and addon.db[NAMEPLATE_QUEST_MARKERS_DB_KEY] == true
	nameplateTargetMarkersActive = addon.db and addon.db[NAMEPLATE_TARGET_MARKERS_DB_KEY] == true
	nameplateHealthbarTextureActive = type(addon.db and addon.db[NAMEPLATE_HEALTHBAR_TEXTURE_DB_KEY]) == "string" and addon.db[NAMEPLATE_HEALTHBAR_TEXTURE_DB_KEY] ~= ""
	nameplateFocusHealthbarTextureActive = type(addon.db and addon.db[NAMEPLATE_FOCUS_HEALTHBAR_TEXTURE_DB_KEY]) == "string" and addon.db[NAMEPLATE_FOCUS_HEALTHBAR_TEXTURE_DB_KEY] ~= ""
	if nameplateMobColorsActive then syncNameplateMobColors() end
	if addon.functions.InitializeDefaultNameplateTextStyle then addon.functions.InitializeDefaultNameplateTextStyle() end
	if nameplateEliteMarkersActive then syncNameplateEliteMarkers() end
	if nameplateMobColorState.HasQuestDisplay() then syncNameplateQuestMarkers() end
	if nameplateTargetMarkersActive then syncNameplateTargetMarkers() end
	if nameplateHealthbarTextureActive or nameplateFocusHealthbarTextureActive then addon.functions.SyncNameplateFocusHealthbarTextures() end

	local combatLogSection = addon.functions.SettingsCreateExpandableSection(cChar, {
		name = L["combatLogSection"] or "Combat logging",
		configPageKey = "CombatLogging",
		iconKey = "combatlogging",
		expanded = false,
		colorizeTitle = false,
		modernOnly = true,
	})

	local combatLogEnabled = addon.functions.SettingsCreateCheckbox(cChar, {
		var = "autoCombatLog",
		text = L["combatLogAuto"] or "Auto combat logging in instances",
		desc = L["combatLogAutoDesc"],
		func = function(value)
			addon.db.autoCombatLog = value and true or false
			if addon.functions.UpdateCombatLogState then addon.functions.UpdateCombatLogState() end
		end,
		parentSection = combatLogSection,
	})

	local function isCombatLogEnabled() return combatLogEnabled and combatLogEnabled.setting and combatLogEnabled.setting:GetValue() == true end

	addon.functions.SettingsCreateCheckbox(cChar, {
		var = "combatLogDelayedStop",
		text = L["combatLogDelayStop"] or "Delayed log stop",
		desc = L["combatLogDelayStopDesc"],
		func = function(value) addon.db.combatLogDelayedStop = value and true or false end,
		element = combatLogEnabled.element,
		parentSection = combatLogSection,
		parentCheck = isCombatLogEnabled,
		parent = true,
	})

	local function createCombatLogToggle(var, label, desc)
		addon.functions.SettingsCreateCheckbox(cChar, {
			var = var,
			text = label,
			desc = desc,
			func = function(value)
				addon.db[var] = value and true or false
				if addon.db.autoCombatLog and addon.functions.UpdateCombatLogState then addon.functions.UpdateCombatLogState() end
			end,
			element = combatLogEnabled.element,
			parentSection = combatLogSection,
			parentCheck = isCombatLogEnabled,
			parent = true,
		})
	end

	createCombatLogToggle("combatLogPvp", L["PvP"] or "PvP", L["combatLogPvpDesc"] or "Automatically toggle combat logging in PvP instances.")
	createCombatLogToggle("combatLogScenario", L["combatLogScenario"] or "Scenarios", L["combatLogScenarioDesc"] or "Automatically toggle combat logging in scenarios.")

	local function createCombatLogDropdown(var, label, category)
		addon.functions.SettingsCreateMultiDropdown(cChar, {
			var = var,
			text = label,
			desc = L["combatLogListDesc"],
			listFunc = function() return getCombatLogDifficultyOptions(category) end,
			isSelectedFunc = function(key) return isCombatLogSelected(category, key) end,
			setSelectedFunc = function(key, selected) setCombatLogSelection(category, key, selected) end,
			menuHeight = 260,
			element = combatLogEnabled.element,
			parentSection = combatLogSection,
			parentCheck = isCombatLogEnabled,
			isEnabled = isCombatLogEnabled,
		})
	end

	createCombatLogDropdown("combatLogDungeonDifficulties", L["combatLogDungeon"] or "Dungeons", "dungeon")
	createCombatLogDropdown("combatLogRaidDifficulties", L["combatLogRaid"] or "Raids", "raid")
	addon.functions.SettingsCreateCheckbox(cChar, {
		var = "combatLogRaidCurrentExpansionOnly",
		text = L["combatLogRaidCurrentExpansionOnly"] or "Only current expansion raids",
		desc = L["combatLogRaidCurrentExpansionOnlyDesc"] or "Automatically toggle combat logging for raids only when the raid belongs to the current expansion.",
		func = function(value)
			addon.db.combatLogRaidCurrentExpansionOnly = value and true or false
			if addon.db.autoCombatLog and addon.functions.UpdateCombatLogState then addon.functions.UpdateCombatLogState() end
		end,
		default = true,
		element = combatLogEnabled.element,
		parentSection = combatLogSection,
		parentCheck = isCombatLogEnabled,
		parent = true,
	})

	-- Secure snippets cannot compile without the client-provided compiler.
	-- TODO: Temporary Forever workaround pending Blizzard's restricted-environment fix.
	-- Remove this guard once the client fix is verified and secure marker snippets execute correctly.
	if type(_G.loadstring_untainted) == "function" then
		local find = {
			["CLICK EQOLWorldMarkerCycler:LeftButton"] = true,
			["CLICK EQOLWorldMarkerCycler:RightButton"] = true,
		}
		addon.variables.keybindFindings = addon.functions.FindBindingIndex(find)

		-- Markers
		local sectionMarkers = addon.SettingsLayout.gameplayMarkersSection
		if not sectionMarkers then
			sectionMarkers = addon.functions.SettingsCreateExpandableSection(cChar, {
				name = L["WorldMarkers"] or "World Markers",
				configPageKey = "Markers",
				description = L["configCenterPageCardDescMarkers"]
					or "Configure keybindings for cycling and clearing world markers.",
				iconKey = "markers",
				expanded = false,
				colorizeTitle = false,
				modernOnly = true,
			})
			addon.SettingsLayout.gameplayMarkersSection = sectionMarkers
		end

		addon.functions.SettingsCreateHeadline(addon.SettingsLayout.characterInspectCategory, L["WorldMarkers"], {
			parentSection = sectionMarkers,
		})
		addon.functions.SettingsCreateButton(addon.SettingsLayout.characterInspectCategory, {
			var = "worldMarkerKeybindings",
			text = L["WorldMarkerKeybindings"] or "World marker keybindings",
			desc = L["WorldMarkerKeybindingsDesc"]
				or "Assign keybindings for cycling world markers and clearing all world markers.",
			label = _G.KEY_BINDINGS or "Key Bindings",
			buttonText = _G.KEY_BINDINGS or "Key Bindings",
			parentSection = sectionMarkers,
			onClick = function()
				if Settings and Settings.OpenToCategory and Settings.KEYBINDINGS_CATEGORY_ID then
					Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID, L["WorldMarkers"] or "World Markers")
				end
			end,
		})


		_G["BINDING_NAME_CLICK EQOLWorldMarkerCycler:LeftButton"] = L["Cycle World Marker"]
		_G["BINDING_NAME_CLICK EQOLWorldMarkerCycler:RightButton"] = L["Clear World Marker"]

		local btn = CreateFrame("Button", "EQOLWorldMarkerCycler", UIParent, "SecureActionButtonTemplate")
		btn:SetAttribute("type", "macro")
		btn:RegisterForClicks("AnyUp", "AnyDown")
		local body = "i = 0;order = newtable()"
		for i = 1, 8 do
			body = body .. format("\ntinsert(order, %s)", i)
		end
		SecureHandlerExecute(btn, body)

		SecureHandlerUnwrapScript(btn, "PreClick")

		SecureHandlerWrapScript(
			btn,
			"PreClick",
			btn,
			[=[
			if not down or not next(order) then return end
			if button == "RightButton" then
				i = 0
				self:SetAttribute("macrotext", "/cwm all")
			else
				i = i%#order + 1
				self:SetAttribute("macrotext", "/wm [@cursor]"..order[i])
			end
		]=]
		)
	end

	local expandable = addon.SettingsLayout.gameplayConvenienceSection
	if not expandable then
		expandable = addon.functions.SettingsCreateExpandableSection(addon.SettingsLayout.characterInspectCategory, {
			name = L["MacrosAndConsumables"] or "Macros & Consumables",
			newTagID = "MacrosAndConsumables",
			configPageKey = "MacrosConsumables",
			iconKey = "macros",
			expanded = false,
			colorizeTitle = false,
			modernOnly = true,
		})
		addon.SettingsLayout.gameplayConvenienceSection = expandable
	end
	if addon.functions.initDrinkMacro then addon.functions.initDrinkMacro() end

	addon.functions.SettingsCreateHeadline(addon.SettingsLayout.characterInspectCategory, L["Mounts"] or "Mounts", { parentSection = expandable })
	addon.functions.SettingsCreateCheckbox(addon.SettingsLayout.characterInspectCategory, {
		var = "mountBindingDismountWhileMounted",
		text = L["mountBindingDismountWhileMounted"],
		desc = L["mountBindingDismountWhileMountedDesc"],
		func = function(value) addon.db["mountBindingDismountWhileMounted"] = value and true or false end,
		default = false,
		newTagID = "mountBindingDismountWhileMounted",
		parentSection = expandable,
	})

	addon.functions.SettingsCreateCheckbox(addon.SettingsLayout.characterInspectCategory, {
		var = "randomMountUseAll",
		text = L["Use all mounts for random mount"] or "Use all mounts for random mount",
		desc = L["randomMountUseAllDesc"],
		func = function(value)
			addon.db["randomMountUseAll"] = value and true or false
			if addon.MountActions and addon.MountActions.MarkRandomCacheDirty then addon.MountActions:MarkRandomCacheDirty() end
		end,
		default = false,
		parentSection = expandable,
	})


	addon.functions.SettingsCreateCheckbox(addon.SettingsLayout.characterInspectCategory, {
		var = "randomMountCastSlowFallWhenFalling",
		text = L["randomMountCastSlowFallWhenFalling"] or "Cast Slow Fall/Levitate/Travel Form while falling",
		desc = L["randomMountCastSlowFallWhenFallingDesc"] or "Only applies to Mages (Slow Fall), Druids (Travel Form) and Priests (Levitate).",
		func = function(value) addon.db["randomMountCastSlowFallWhenFalling"] = value and true or false end,
		default = false,
		parentSection = expandable,
	})

	addon.functions.SettingsCreateCheckbox(addon.SettingsLayout.characterInspectCategory, {
		var = "randomMountDruidNoShiftWhileMounted",
		text = L["randomMountDruidNoShiftWhileMounted"],
		desc = L["randomMountDruidNoShiftWhileMountedDesc"],
		func = function(value) addon.db["randomMountDruidNoShiftWhileMounted"] = value and true or false end,
		default = false,
		parentSection = expandable,
	})

	local data = {
		{
			var = "autoCancelDruidFlightForm",
			text = L["autoCancelDruidFlightForm"],
			desc = L["autoCancelDruidFlightFormDesc"],
			func = function(value)
				addon.db["autoCancelDruidFlightForm"] = value and true or false
				if addon.functions.updateDruidFlightFormWatcher then addon.functions.updateDruidFlightFormWatcher() end
			end,
			parentSection = expandable,
		},
	}

	addon.functions.SettingsCreateCheckboxes(addon.SettingsLayout.characterInspectCategory, data)
end

---- END REGION

---- REGION SETTINGS



-- Death & Resurrect
local sectionDeathRes = addon.SettingsLayout.gameplayDeathResSection
if not sectionDeathRes then
	sectionDeathRes = addon.functions.SettingsCreateExpandableSection(cChar, {
		name = L["DeathResurrect"],
		newTagID = "DeathResurrect",
		iconKey = "death",
		expanded = false,
		colorizeTitle = false,
		modernOnly = true,
	})
	addon.SettingsLayout.gameplayDeathResSection = sectionDeathRes
end

addon.functions.SettingsCreateHeadline(cChar, L["ReleaseTimer"], { parentSection = sectionDeathRes })

data = {
	var = "timeoutRelease",
	text = L["timeoutRelease"],
	func = function(value)
		addon.db["timeoutRelease"] = value
		if addon.functions.UpdateTimeoutReleaseEventRegistration then addon.functions.UpdateTimeoutReleaseEventRegistration() end
	end,
	parentSection = sectionDeathRes,
}
table.sort(data, function(a, b) return a.text < b.text end)

local rData = addon.functions.SettingsCreateCheckbox(cChar, data)

data = {
	list = {
		SHIFT = SHIFT_KEY_TEXT,
		CTRL = CTRL_KEY_TEXT,
		ALT = ALT_KEY_TEXT,
	},
	text = L["timeoutReleaseModifierLabel"],
	get = function() return addon.db["timeoutReleaseModifier"] or "SHIFT" end,
	set = function(key) addon.db["timeoutReleaseModifier"] = key end,
	parentCheck = function() return rData.setting and rData.setting:GetValue() == true end,
	element = rData.element,
	parent = true,
	default = "SHIFT",
	var = "timeoutReleaseModifier",
	parentSection = sectionDeathRes,
}

addon.functions.SettingsCreateDropdown(cChar, data)

local timeoutReleaseGroups = {
	{
		var = "timeoutRelease_raidNormal",
		value = "raidNormal",
		text = RAID .. " - " .. PLAYER_DIFFICULTY1 .. " / " .. PLAYER_DIFFICULTY3 .. " / " .. PLAYER_DIFFICULTY_TIMEWALKER,
		func = function(value) addon.db["timeoutReleaseDifficulties"]["raidNormal"] = value and true or false end,
		get = function() return addon.db["timeoutReleaseDifficulties"]["raidNormal"] end,
		parentCheck = function() return rData.setting and rData.setting:GetValue() == true end,
		element = rData.element,
		parent = true,
		difficulties = { 3, 4, 7, 9, 14, 17, 18, 33, 151, 220 },
	},
	{
		var = "timeoutRelease_raidHeroic",
		value = "raidHeroic",
		text = RAID .. " - " .. PLAYER_DIFFICULTY2,
		func = function(value) addon.db["timeoutReleaseDifficulties"]["raidHeroic"] = value and true or false end,
		get = function() return addon.db["timeoutReleaseDifficulties"]["raidHeroic"] end,
		parentCheck = function() return rData.setting and rData.setting:GetValue() == true end,
		element = rData.element,
		parent = true,
		difficulties = { 5, 6, 15 },
	},
	{
		var = "timeoutRelease_raidMythic",
		value = "raidMythic",
		text = RAID .. " - " .. PLAYER_DIFFICULTY6,
		func = function(value) addon.db["timeoutReleaseDifficulties"]["raidMythic"] = value and true or false end,
		get = function() return addon.db["timeoutReleaseDifficulties"]["raidMythic"] end,
		parentCheck = function() return rData.setting and rData.setting:GetValue() == true end,
		element = rData.element,
		parent = true,
		difficulties = { 16, 233 },
	},
	{
		var = "timeoutRelease_dungeonNormal",
		value = "dungeonNormal",
		text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY1 .. " / " .. PLAYER_DIFFICULTY_TIMEWALKER,
		func = function(value) addon.db["timeoutReleaseDifficulties"]["dungeonNormal"] = value and true or false end,
		get = function() return addon.db["timeoutReleaseDifficulties"]["dungeonNormal"] end,
		parentCheck = function() return rData.setting and rData.setting:GetValue() == true end,
		element = rData.element,
		parent = true,
		difficulties = { 1, 24, 150, 216 },
	},
	{
		var = "timeoutRelease_dungeonHeroic",
		value = "dungeonHeroic",
		text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY2,
		func = function(value) addon.db["timeoutReleaseDifficulties"]["dungeonHeroic"] = value and true or false end,
		get = function() return addon.db["timeoutReleaseDifficulties"]["dungeonHeroic"] end,
		parentCheck = function() return rData.setting and rData.setting:GetValue() == true end,
		element = rData.element,
		parent = true,
		difficulties = { 2 },
	},
	{
		var = "timeoutRelease_dungeonMythic",
		value = "dungeonMythic",
		text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY6,
		func = function(value) addon.db["timeoutReleaseDifficulties"]["dungeonMythic"] = value and true or false end,
		get = function() return addon.db["timeoutReleaseDifficulties"]["dungeonMythic"] end,
		parentCheck = function() return rData.setting and rData.setting:GetValue() == true end,
		element = rData.element,
		parent = true,
		difficulties = { 23 },
	},
	{
		var = "timeoutRelease_pvp",
		value = "pvp",
		text = PVP,
		func = function(value) addon.db["timeoutReleaseDifficulties"]["pvp"] = value and true or false end,
		get = function() return addon.db["timeoutReleaseDifficulties"]["pvp"] end,
		parentCheck = function() return rData.setting and rData.setting:GetValue() == true end,
		element = rData.element,
		parent = true,
		difficulties = { 29, 34, 45 },
	},
	{
		var = "timeoutRelease_world",
		value = "world",
		text = WORLD,
		func = function(value) addon.db["timeoutReleaseDifficulties"]["world"] = value and true or false end,
		get = function() return addon.db["timeoutReleaseDifficulties"]["world"] end,
		parentCheck = function() return rData.setting and rData.setting:GetValue() == true end,
		element = rData.element,
		parent = true,
		difficulties = { 0, 172, 192 },
	},
}


for _, group in ipairs(timeoutReleaseGroups) do
	if group.difficulties then
		group.difficultySet = {}
		for _, difficultyID in ipairs(group.difficulties) do
			group.difficultySet[difficultyID] = true
			local bucket = timeoutReleaseDifficultyLookup[difficultyID]
			if not bucket then
				timeoutReleaseDifficultyLookup[difficultyID] = { group.key }
			else
				table.insert(bucket, group.key)
			end
		end
	end
end

addon.functions.SettingsCreateMultiDropdown(cChar, {
	var = "timeoutReleaseDifficulties",
	text = L["timeoutReleaseHeadline"],
	parent = true,
	element = rData.element,
	parentCheck = function() return rData.setting and rData.setting:GetValue() == true end,
	options = timeoutReleaseGroups,
	parentSection = sectionDeathRes,
})

local function isAutoAcceptResurrectionEnabled()
	return addon.SettingsLayout.elements["autoAcceptResurrection"]
		and addon.SettingsLayout.elements["autoAcceptResurrection"].setting
		and addon.SettingsLayout.elements["autoAcceptResurrection"].setting:GetValue() == true
end

addon.functions.SettingsCreateHeadline(cChar, L["Resurrection"], { parentSection = sectionDeathRes })

addon.functions.SettingsCreateCheckbox(cChar, {
	var = "autoAcceptResurrection",
	text = L["autoAcceptResurrection"],
	desc = L["autoAcceptResurrectionDesc"],
	func = function(value) addon.db["autoAcceptResurrection"] = value end,
	parentSection = sectionDeathRes,
	children = {
		{
			var = "autoAcceptResurrectionExcludeCombat",
			text = L["autoAcceptResurrectionExcludeCombat"],
			desc = L["autoAcceptResurrectionExcludeCombatDesc"],
			func = function(v) addon.db["autoAcceptResurrectionExcludeCombat"] = v end,
			parentCheck = isAutoAcceptResurrectionEnabled,
			parent = true,
			default = true,
			type = Settings.VarType.Boolean,
			sType = "checkbox",
			parentSection = sectionDeathRes,
		},
		{
			var = "autoAcceptResurrectionExcludeAfterlife",
			text = L["autoAcceptResurrectionExcludeAfterlife"],
			desc = L["autoAcceptResurrectionExcludeAfterlifeDesc"],
			func = function(v) addon.db["autoAcceptResurrectionExcludeAfterlife"] = v end,
			parentCheck = isAutoAcceptResurrectionEnabled,
			parent = true,
			default = true,
			type = Settings.VarType.Boolean,
			sType = "checkbox",
			parentSection = sectionDeathRes,
		},
	},
})

local function isAutoReleasePvPEnabled()
	return addon.SettingsLayout.elements["autoReleasePvP"] and addon.SettingsLayout.elements["autoReleasePvP"].setting and addon.SettingsLayout.elements["autoReleasePvP"].setting:GetValue() == true
end

addon.functions.SettingsCreateHeadline(cChar, L["PvPAutoRelease"], { parentSection = sectionDeathRes })

addon.functions.SettingsCreateCheckbox(cChar, {
	var = "autoReleasePvP",
	text = L["autoReleasePvP"],
	desc = L["autoReleasePvPDesc"],
	func = function(value) addon.db["autoReleasePvP"] = value end,
	parentSection = sectionDeathRes,
	children = {
		{
			var = "autoReleasePvPDelay",
			text = L["autoReleasePvPDelay"],
			desc = L["autoReleasePvPDelayDesc"],
			get = function() return addon.db and addon.db.autoReleasePvPDelay or 0 end,
			set = function(value) addon.db["autoReleasePvPDelay"] = value end,
			min = 0,
			max = 3000,
			step = 100,
			parentCheck = isAutoReleasePvPEnabled,
			parent = true,
			default = 0,
			sType = "slider",
			parentSection = sectionDeathRes,
		},
		{
			var = "autoReleasePvPExcludeAlterac",
			text = L["autoReleasePvPExcludeAlterac"],
			func = function(v) addon.db["autoReleasePvPExcludeAlterac"] = v end,
			parentCheck = isAutoReleasePvPEnabled,
			parent = true,
			default = false,
			type = Settings.VarType.Boolean,
			sType = "checkbox",
			parentSection = sectionDeathRes,
		},
	},
})

---- REGION END

local frameLoad





function addon.functions.UpdateTimeoutReleaseEventRegistration()
	if not frameLoad then return end
	if not frameLoad._eqolTimeoutReleaseEventRegistered then
		frameLoad:RegisterEvent("MODIFIER_STATE_CHANGED")
		frameLoad._eqolTimeoutReleaseEventRegistered = true
	end
end

local eventHandlers = {

	["PLAYER_DIFFICULTY_CHANGED"] = function()
		if addon.functions.UpdateCombatLogState then addon.functions.UpdateCombatLogState() end
	end,
	["PLAYER_ENTERING_WORLD"] = function()
		if addon.functions.UpdateCombatLogState then addon.functions.UpdateCombatLogState() end
	end,
	["ZONE_CHANGED_NEW_AREA"] = function()
		if addon.functions.UpdateCombatLogState then addon.functions.UpdateCombatLogState() end
	end,
	["MODIFIER_STATE_CHANGED"] = function(arg1, arg2)
		if not addon.db["timeoutRelease"] then return end
		if not isPlayerDeadOrGhost() then return end
		local modifierKey = addon.functions.getTimeoutReleaseModifierKey()
		if not (arg1 and arg1:match(modifierKey)) then return end

		local _, stp = StaticPopup_Visible("DEATH")
		if stp and stp.GetButton and addon.functions.shouldUseTimeoutReleaseForCurrentContext() then
			local btn = stp:GetButton(1)
			if btn then btn:SetAlpha(arg2 or 0) end
		end
	end,
	["UPDATE_INSTANCE_INFO"] = function()
		if addon.functions.UpdateCombatLogState then addon.functions.UpdateCombatLogState() end
	end,
}

local function registerEvents(frame)
	for event in pairs(eventHandlers) do
		frame:RegisterEvent(event)
		if event == "MODIFIER_STATE_CHANGED" then frame._eqolTimeoutReleaseEventRegistered = true end
	end
end

local function eventHandler(self, event, ...)
	if eventHandlers[event] then eventHandlers[event](...) end
end

frameLoad = CreateFrame("Frame")

registerEvents(frameLoad)
addon.functions.UpdateTimeoutReleaseEventRegistration()
frameLoad:SetScript("OnEvent", eventHandler)
