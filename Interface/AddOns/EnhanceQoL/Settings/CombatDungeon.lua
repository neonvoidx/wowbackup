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
	delve = "combatLogDelve",
}
local COMBAT_LOG_DELAY_SECONDS = 30
local CURRENT_EXPANSION_RAID_INSTANCE_CACHE
local combatLogInstanceMap = {
	party = "dungeon",
	raid = "raid",
	pvp = "pvp",
	arena = "pvp",
	scenario = "scenario",
	delve = "delve",
}
local LEGACY_NAMEPLATE_AURA_CLICKTHROUGH_DB_KEY = "experimentalNameplateAuraClickthrough"
local NAMEPLATE_AURA_CLICKTHROUGH_DB_KEY = "nameplateAuraClickthrough"
local NAMEPLATE_MOB_COLORS_DB_KEY = "nameplateMobColors"
local NAMEPLATE_MOB_COLORS_DUNGEONS_DB_KEY = "nameplateMobColorsInDungeons"
local NAMEPLATE_MOB_COLORS_OUTSIDE_DUNGEONS_DB_KEY = "nameplateMobColorsOutsideDungeons"
local NAMEPLATE_SLUG_OUTLINE_DB_KEY = "nameplateSlugOutline"
local NAMEPLATE_TEXT_CUSTOM_FONT_DB_KEY = "nameplateTextCustomFont"
local NAMEPLATE_TEXT_FONT_DB_KEY = "nameplateTextFont"
local NAMEPLATE_TEXT_OUTLINE_DB_KEY = "nameplateTextOutline"
local NAMEPLATE_TEXT_SIZE_DB_KEY = "nameplateTextSize"
local NAMEPLATE_FRIENDLY_PLAYER_NAMES_ONLY_DB_KEY = "nameplateFriendlyPlayerNamesOnly"
local NAMEPLATE_FRIENDLY_PLAYER_CLASS_COLOR_NAMES_DB_KEY = "nameplateFriendlyPlayerClassColorNames"
local NAMEPLATE_HIDE_FRIENDLY_PLAYER_REALMS_DB_KEY = "nameplateHideFriendlyPlayerRealms"
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
local nameplateAuraClickthroughFrame
local nameplateAuraClickthroughHookedBuffPools = setmetatable({}, { __mode = "k" })
local nameplateAuraClickthroughHookedAuraFrames = setmetatable({}, { __mode = "k" })
local nameplateAuraClickthroughActive = false
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
	nameplateMobColorTapped = { r = 0.9, g = 0.9, b = 0.9, a = 1 },
	[NAMEPLATE_MOB_COLOR_TANK_MODE_DB_KEY] = { r = 0.15, g = 0.85, b = 1, a = 1 },
	[NAMEPLATE_MOB_COLOR_THREAT_LOST_DB_KEY] = buildNameplateColorDefault(_G.ORANGE_THREAT_COLOR, 1, 0.6, 0),
	[NAMEPLATE_MOB_COLOR_THREAT_WARNING_DB_KEY] = buildNameplateColorDefault(_G.YELLOW_THREAT_COLOR, 1, 1, 0),
	[NAMEPLATE_MOB_COLOR_TRIVIAL_DB_KEY] = { r = 178 / 255, g = 142 / 255, b = 85 / 255, a = 1 },
}
addon.constants = addon.constants or {}
addon.constants.DEFAULT_NAMEPLATE_FEATURE_KEYS = {
	auraClickthrough = NAMEPLATE_AURA_CLICKTHROUGH_DB_KEY,
	slugOutline = NAMEPLATE_SLUG_OUTLINE_DB_KEY,
	textCustomFont = NAMEPLATE_TEXT_CUSTOM_FONT_DB_KEY,
	textFont = NAMEPLATE_TEXT_FONT_DB_KEY,
	textOutline = NAMEPLATE_TEXT_OUTLINE_DB_KEY,
	textSize = NAMEPLATE_TEXT_SIZE_DB_KEY,
	friendlyPlayerNamesOnly = NAMEPLATE_FRIENDLY_PLAYER_NAMES_ONLY_DB_KEY,
	friendlyPlayerClassColorNames = NAMEPLATE_FRIENDLY_PLAYER_CLASS_COLOR_NAMES_DB_KEY,
	hideFriendlyPlayerRealms = NAMEPLATE_HIDE_FRIENDLY_PLAYER_REALMS_DB_KEY,
	eliteMarkers = NAMEPLATE_ELITE_MARKERS_DB_KEY,
	eliteMarkerAnchor = NAMEPLATE_ELITE_MARKER_ANCHOR_DB_KEY,
	eliteMarkerSize = NAMEPLATE_ELITE_MARKER_SIZE_DB_KEY,
	mobColors = NAMEPLATE_MOB_COLORS_DB_KEY,
	mobColorsInDungeons = NAMEPLATE_MOB_COLORS_DUNGEONS_DB_KEY,
	mobColorsOutsideDungeons = NAMEPLATE_MOB_COLORS_OUTSIDE_DUNGEONS_DB_KEY,
	questMarkers = NAMEPLATE_QUEST_MARKERS_DB_KEY,
	questMarkerAnchor = NAMEPLATE_QUEST_MARKER_ANCHOR_DB_KEY,
	questMarkerSize = NAMEPLATE_QUEST_MARKER_SIZE_DB_KEY,
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
		{ key = "mythicPlus", text = PLAYER_DIFFICULTY_MYTHIC_PLUS, difficulties = { DIFFICULTY_IDS.DungeonChallenge or 8 } },
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
		cancelCombatLogStopTimer()
		addon.variables = addon.variables or {}
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
		if addon.variables and addon.variables.combatLogRestoreState ~= nil then
			applyCombatLogState(addon.variables.combatLogRestoreState)
			addon.variables.combatLogRestoreState = nil
		end
		return
	end

	local _, instanceType, difficultyID, _, _, _, _, instanceMapID, _, lfgDungeonID = GetInstanceInfo()
	if not instanceType or instanceType == "none" then
		if addon.variables and addon.variables.combatLogRestoreState ~= nil then
			applyCombatLogState(addon.variables.combatLogRestoreState)
			addon.variables.combatLogRestoreState = nil
		end
		return
	end

	local category = getCombatLogCategory(instanceType)
	if not category then return end
	if addon.variables and addon.variables.combatLogRestoreState == nil then addon.variables.combatLogRestoreState = getCombatLogEnabledState() end

	local decision = getCombatLogDecision(category, difficultyID)
	if decision == nil then return end
	if decision == true and category == "raid" and addon.db.combatLogRaidCurrentExpansionOnly and not isCurrentExpansionRaidInstance(difficultyID, instanceMapID, lfgDungeonID) then decision = false end
	applyCombatLogState(decision)
end

addon.functions.UpdateCombatLogState = updateCombatLogState

local function isNameplateAuraClickthroughActive() return nameplateAuraClickthroughActive == true end

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
	local friendlyNameplateOptionsFrame

	local FRIENDLY_NAMEPLATE_CVARS = {
		[NAMEPLATE_FRIENDLY_PLAYER_NAMES_ONLY_DB_KEY] = "nameplateShowOnlyNameForFriendlyPlayerUnits",
		[NAMEPLATE_FRIENDLY_PLAYER_CLASS_COLOR_NAMES_DB_KEY] = "nameplateUseClassColorForFriendlyPlayerUnitNames",
	}

	local function setCVarBool(cvarName, enabled)
		if not (C_CVar and C_CVar.SetCVar) then return end
		C_CVar.SetCVar(cvarName, enabled and "1" or "0")
	end

	local function refreshFriendlyNameplateNames()
		if not (C_NamePlate and C_NamePlate.GetNamePlates and _G.CompactUnitFrame_UpdateName) then return end
		for _, namePlate in pairs(C_NamePlate.GetNamePlates() or {}) do
			local unitFrame = namePlate and namePlate.UnitFrame
			local unit = unitFrame and unitFrame.unit
			if unit and UnitIsPlayer(unit) and UnitIsFriend("player", unit) then _G.CompactUnitFrame_UpdateName(unitFrame) end
		end
	end

	local function setFriendlyRealmTextureEnabled(enabled)
		if not (_G.TextureLoadingGroupMixin and _G.NamePlateFriendlyFrameOptions) then return end
		local updateKey = "updateNameUsesGetUnitName"
		local textureGroup = { textures = _G.NamePlateFriendlyFrameOptions }
		if enabled and _G.TextureLoadingGroupMixin.RemoveTexture then
			_G.TextureLoadingGroupMixin.RemoveTexture(textureGroup, updateKey)
		elseif not enabled and _G.TextureLoadingGroupMixin.AddTexture then
			_G.TextureLoadingGroupMixin.AddTexture(textureGroup, updateKey)
		end
		refreshFriendlyNameplateNames()
	end

	local function applyFriendlyNameplateOptions()
		if not addon.db then return end
		for dbKey, cvarName in pairs(FRIENDLY_NAMEPLATE_CVARS) do
			if addon.db[dbKey] == true then setCVarBool(cvarName, true) end
		end
		if addon.db[NAMEPLATE_HIDE_FRIENDLY_PLAYER_REALMS_DB_KEY] == true then setFriendlyRealmTextureEnabled(true) end
	end

	local function ensureFriendlyNameplateOptionsWatcher()
		if friendlyNameplateOptionsFrame then return end
		friendlyNameplateOptionsFrame = CreateFrame("Frame")
		friendlyNameplateOptionsFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
		friendlyNameplateOptionsFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
		friendlyNameplateOptionsFrame:SetScript("OnEvent", function(_, event, unit)
			if event == "NAME_PLATE_UNIT_ADDED" then
				if unit and UnitIsPlayer(unit) and UnitIsFriend("player", unit) and addon.db and addon.db[NAMEPLATE_HIDE_FRIENDLY_PLAYER_REALMS_DB_KEY] == true then
					local namePlate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
					local unitFrame = namePlate and namePlate.UnitFrame
					if unitFrame and _G.CompactUnitFrame_UpdateName then _G.CompactUnitFrame_UpdateName(unitFrame) end
				end
				return
			end
			applyFriendlyNameplateOptions()
		end)
	end

	function addon.functions.SetDefaultNameplateFriendlyPlayerNamesOnlyEnabled(value)
		local enabled = value and true or false
		addon.db[NAMEPLATE_FRIENDLY_PLAYER_NAMES_ONLY_DB_KEY] = enabled
		setCVarBool(FRIENDLY_NAMEPLATE_CVARS[NAMEPLATE_FRIENDLY_PLAYER_NAMES_ONLY_DB_KEY], enabled)
		ensureFriendlyNameplateOptionsWatcher()
	end

	function addon.functions.SetDefaultNameplateFriendlyPlayerClassColorNamesEnabled(value)
		local enabled = value and true or false
		addon.db[NAMEPLATE_FRIENDLY_PLAYER_CLASS_COLOR_NAMES_DB_KEY] = enabled
		setCVarBool(FRIENDLY_NAMEPLATE_CVARS[NAMEPLATE_FRIENDLY_PLAYER_CLASS_COLOR_NAMES_DB_KEY], enabled)
		ensureFriendlyNameplateOptionsWatcher()
	end

	function addon.functions.SetDefaultNameplateHideFriendlyPlayerRealmsEnabled(value)
		local enabled = value and true or false
		addon.db[NAMEPLATE_HIDE_FRIENDLY_PLAYER_REALMS_DB_KEY] = enabled
		setFriendlyRealmTextureEnabled(enabled)
		ensureFriendlyNameplateOptionsWatcher()
	end

	function addon.functions.InitializeDefaultNameplateFriendlyPlayerOptions()
		ensureFriendlyNameplateOptionsWatcher()
		applyFriendlyNameplateOptions()
	end
end

do
	local nameplateSlugOutlineFrame
	local nameplateSlugOutlineActive = false
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
	local size = getNameplateTextSizeOverride(defaults and defaults.size)
	setNameplateTextFont(fontObject, font, size, getNameplateTextStyleFlags())
	applyNameplateTextStyleShadow(fontObject)
end

local function restoreSlugOutlineFontObject(fontObject)
	local defaults = nameplateSlugOutlineFontObjectDefaults[fontObject]
	if not defaults or not fontObject or type(fontObject.SetFont) ~= "function" then return end
	setNameplateTextFont(fontObject, defaults.font, defaults.size, defaults.flags)
	restoreFontShadowDefaults(fontObject, defaults)
end

local function applySlugOutlineToFontString(fontString)
	if not fontString or type(fontString.GetFont) ~= "function" or type(fontString.SetFont) ~= "function" then return end
	if not nameplateSlugOutlineFontStringDefaults[fontString] then
		local font, size, flags = fontString:GetFont()
		nameplateSlugOutlineFontStringDefaults[fontString] = { font = font, size = size, flags = flags }
		cacheFontShadowDefaults(nameplateSlugOutlineFontStringDefaults[fontString], fontString)
	end

	local defaults = nameplateSlugOutlineFontStringDefaults[fontString]
	local font = getNameplateTextFontFace(defaults and defaults.font)
	local size = getNameplateTextSizeOverride(defaults and defaults.size)
	setNameplateTextFont(fontString, font, size, getNameplateTextStyleFlags())
	applyNameplateTextStyleShadow(fontString)
end

local function restoreSlugOutlineFontString(fontString)
	local defaults = nameplateSlugOutlineFontStringDefaults[fontString]
	if not defaults or not fontString or type(fontString.SetFont) ~= "function" then return end
	setNameplateTextFont(fontString, defaults.font, defaults.size, defaults.flags)
	restoreFontShadowDefaults(fontString, defaults)
end

local function applySlugOutlineToNameplate(namePlate)
	local unitFrame = namePlate and namePlate.UnitFrame
	local fontString = getNameplateNameFontString(unitFrame)
	if fontString then applySlugOutlineToFontString(fontString) end
end

local function restoreSlugOutlineOnNameplate(namePlate)
	local unitFrame = namePlate and namePlate.UnitFrame
	local fontString = getNameplateNameFontString(unitFrame)
	if fontString then restoreSlugOutlineFontString(fontString) end
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

function addon.functions.CanScanNameplateQuestMarkers()
	return isNameplateQuestMarkersActive() and not IsInInstance()
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
	if nameplateQuestMarkerCache[unit] ~= nil then return nameplateQuestMarkerCache[unit] == true end
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

	local playerName = UnitName and UnitName("player")
	local ignoreUntilTitle = false
	for _, line in ipairs(tooltipInfo.lines) do
		if type(line) == "table" and questTooltipLineTypes[line.type] then
			local leftText = isSecretValue(line.leftText) and nil or line.leftText
			if not ignoreUntilTitle and line.type == Enum.TooltipDataLineType.QuestObjective and isQuestObjectiveLineIncomplete(leftText) then
				nameplateQuestMarkerCache[unit] = true
				return true
			elseif line.type == Enum.TooltipDataLineType.QuestTitle then
				ignoreUntilTitle = false
			elseif line.type == Enum.TooltipDataLineType.QuestPlayer then
				ignoreUntilTitle = leftText ~= playerName
			end
		end
	end

	nameplateQuestMarkerCache[unit] = false
	return false
end

local function getNameplateQuestMarker(unitFrame)
	if not isNameplateQuestMarkersActive() then return nil end
	local anchor = getNameplateQuestMarkerAnchor(unitFrame)
	if not anchor then return nil end

	local marker = nameplateQuestMarkersByUnitFrame[unitFrame]
	if not marker then
		marker = unitFrame:CreateTexture(nil, "OVERLAY")
		marker:SetAtlas("QuestNormal", true)
		marker:Hide()
		nameplateQuestMarkersByUnitFrame[unitFrame] = marker
	end

	local anchorConfig = getNameplateQuestMarkerAnchorConfig()
	local size = getNameplateQuestMarkerSize()
	marker:SetSize(size, size)
	marker:ClearAllPoints()
	marker:SetPoint(anchorConfig.point, anchor, anchorConfig.relativePoint, anchorConfig.x, anchorConfig.y)
	return marker
end

local function updateNameplateQuestMarker(unitFrame, unit)
	local marker = unitFrame and nameplateQuestMarkersByUnitFrame[unitFrame]
	if not addon.functions.CanScanNameplateQuestMarkers() or not isNameplateUnitToken(unit) then
		if marker then marker:Hide() end
		return
	end

	local shouldShow = isNameplateQuestObjectiveUnit(unit)
	if not shouldShow then
		if marker then marker:Hide() end
		return
	end

	marker = getNameplateQuestMarker(unitFrame)
	if marker then marker:Show() end
end

local function hideAllNameplateQuestMarkers()
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
	for _, namePlate in pairs(C_NamePlate.GetNamePlates() or {}) do
		local unitFrame = namePlate and namePlate.UnitFrame
		local marker = unitFrame and nameplateQuestMarkersByUnitFrame[unitFrame]
		if marker then marker:Hide() end
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

	local marker = nameplateEliteMarkersByUnitFrame[unitFrame]
	if not marker then
		marker = unitFrame:CreateTexture(nil, "OVERLAY")
		marker:Hide()
		nameplateEliteMarkersByUnitFrame[unitFrame] = marker
	end

	local anchorConfig = getNameplateEliteMarkerAnchorConfig()
	local size = getNameplateEliteMarkerSize()
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
	marker:SetPoint(anchorConfig.point, anchor, anchorConfig.relativePoint, anchorConfig.x, anchorConfig.y)
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
	left:ClearAllPoints()
	left:SetPoint("RIGHT", anchor, "LEFT", -TARGET_MARKER_OFFSET, 0)
	right:ClearAllPoints()
	right:SetPoint("LEFT", anchor, "RIGHT", TARGET_MARKER_OFFSET, 0)
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
		if addon.db and addon.db.nameplateMobColorNeutralEnabled == true then return getNameplateMobColor(NAMEPLATE_MOB_COLOR_NEUTRAL_DB_KEY, unit) end
		return nil
	end
	if isPlayerControlledNameplateUnit(unit) then return nil end

	local canAttack = UnitCanAttack("player", unit)
	if isSecretValue(canAttack) or not canAttack then return nil end

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
	local threatStatus = getNameplateThreatStatus(unitFrame)
	local color
	if addon.db and addon.db.nameplateMobColorFocusEnabled == true and UnitIsUnit(unit, "focus") then color = getNameplateMobColor(NAMEPLATE_MOB_COLOR_FOCUS_DB_KEY) end
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
		return
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

	applyNameplateBaseHealthColor(unitFrame)
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
			hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(unitFrame) applyNameplateMobColor(unitFrame) end)
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
	nameplateMobColorFrame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
	nameplateMobColorFrame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
	nameplateMobColorFrame:SetScript("OnEvent", function(_, event, unit)
		ensureNameplateMobColorHooks()
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
	if not isNameplateQuestMarkersActive() then return end
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

local function safeSetNameplateAuraButtonClicks(button, enabled)
	if not button or type(button.SetMouseClickEnabled) ~= "function" then return false end
	local ok = pcall(button.SetMouseClickEnabled, button, enabled and true or false)
	return ok == true
end

local function applyNameplateAuraClickthroughToBuffPool(pool)
	if not pool or type(pool.EnumerateActive) ~= "function" then return end
	local allowClicks = not isNameplateAuraClickthroughActive()
	for button in pool:EnumerateActive() do
		safeSetNameplateAuraButtonClicks(button, allowClicks)
	end
end

local function applyNameplateAuraClickthroughToAurasFrame(aurasFrame)
	if not aurasFrame then return end

	local allowClicks = not isNameplateAuraClickthroughActive()
	local pool = aurasFrame.auraItemFramePool
	if pool and type(pool.EnumerateActive) == "function" then
		for auraItem in pool:EnumerateActive() do
			safeSetNameplateAuraButtonClicks(auraItem, allowClicks)
		end
	end

	local lossOfControlAura = aurasFrame.LossOfControlFrame and aurasFrame.LossOfControlFrame.AuraItemFrame
	if lossOfControlAura then safeSetNameplateAuraButtonClicks(lossOfControlAura, allowClicks) end
end

local function hookNameplateAuraClickthroughOnBuffFrame(buffFrame)
	if not buffFrame then return end

	local pool = buffFrame.buffPool
	if pool and not nameplateAuraClickthroughHookedBuffPools[pool] and type(pool.resetterFunc) == "function" then
		hooksecurefunc(pool, "resetterFunc", function(_, button)
			local allowClicks = not isNameplateAuraClickthroughActive()
			safeSetNameplateAuraButtonClicks(button, allowClicks)
		end)
		nameplateAuraClickthroughHookedBuffPools[pool] = true
	end

	if not buffFrame._eqolNameplateAuraClickthroughHooked and type(buffFrame.UpdateBuffs) == "function" then
		hooksecurefunc(buffFrame, "UpdateBuffs", function(self) applyNameplateAuraClickthroughToBuffPool(self.buffPool) end)
		buffFrame._eqolNameplateAuraClickthroughHooked = true
	end

	applyNameplateAuraClickthroughToBuffPool(pool)
end

local function hookNameplateAuraClickthroughOnAurasFrame(aurasFrame)
	if not aurasFrame or nameplateAuraClickthroughHookedAuraFrames[aurasFrame] then return end

	if type(aurasFrame.RefreshAuras) == "function" then hooksecurefunc(aurasFrame, "RefreshAuras", function(self) applyNameplateAuraClickthroughToAurasFrame(self) end) end

	if type(aurasFrame.RefreshLossOfControl) == "function" then hooksecurefunc(aurasFrame, "RefreshLossOfControl", function(self) applyNameplateAuraClickthroughToAurasFrame(self) end) end

	nameplateAuraClickthroughHookedAuraFrames[aurasFrame] = true
	applyNameplateAuraClickthroughToAurasFrame(aurasFrame)
end

local function hookNameplateAuraClickthroughOnUnitFrame(unitFrame)
	if not unitFrame then return end
	hookNameplateAuraClickthroughOnBuffFrame(unitFrame.BuffFrame)
	hookNameplateAuraClickthroughOnAurasFrame(unitFrame.AurasFrame)
end

local function applyNameplateAuraClickthroughToNameplate(namePlate)
	if not namePlate or not namePlate.UnitFrame then return end
	hookNameplateAuraClickthroughOnUnitFrame(namePlate.UnitFrame)
end

local function applyNameplateAuraClickthroughToAllNameplates()
	if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
	for _, namePlate in pairs(C_NamePlate.GetNamePlates() or {}) do
		applyNameplateAuraClickthroughToNameplate(namePlate)
	end
end

local function ensureNameplateAuraClickthroughWatcher()
	if nameplateAuraClickthroughFrame then return end

	nameplateAuraClickthroughFrame = CreateFrame("Frame")
	nameplateAuraClickthroughFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	nameplateAuraClickthroughFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
	nameplateAuraClickthroughFrame:SetScript("OnEvent", function(_, event, unit)
		if event == "NAME_PLATE_UNIT_ADDED" and unit and C_NamePlate and C_NamePlate.GetNamePlateForUnit then
			local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
			if namePlate then applyNameplateAuraClickthroughToNameplate(namePlate) end
			return
		end

		applyNameplateAuraClickthroughToAllNameplates()
	end)
end

local function syncNameplateAuraClickthrough()
	if not isNameplateAuraClickthroughActive() then return end
	ensureNameplateAuraClickthroughWatcher()
	applyNameplateAuraClickthroughToAllNameplates()
end

local function requestFeatureReload()
	addon.variables = addon.variables or {}
	addon.variables.requireReload = true
	if addon.functions.checkReloadFrame then addon.functions.checkReloadFrame() end
end

function addon.functions.SetDefaultNameplateAuraClickthroughEnabled(value)
	local wasActive = isNameplateAuraClickthroughActive()
	local enabled = value and true or false
	addon.db[NAMEPLATE_AURA_CLICKTHROUGH_DB_KEY] = enabled
	if enabled then
		nameplateAuraClickthroughActive = true
		syncNameplateAuraClickthrough()
	elseif wasActive then
		requestFeatureReload()
	end
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
	if enabled then
		syncNameplateQuestMarkers()
	else
		hideAllNameplateQuestMarkers()
	end
end

function addon.functions.RefreshDefaultNameplateQuestMarkers()
	if isNameplateQuestMarkersActive() then syncNameplateQuestMarkers() end
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
	if instanceType == "party" then return selection["dungeonNormal"] or selection["dungeonHeroic"] or selection["dungeonMythic"] or selection["dungeonMythicPlus"] or selection["dungeonFollower"] end

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

local function toggleGroupApplication(value)
	if addon.functions and addon.functions.isRestrictedContent and addon.functions.isRestrictedContent(true) then return end
	local viewer = _G.LFGListFrame and _G.LFGListFrame.ApplicationViewer
	local cover = viewer and viewer.UnempoweredCover
	if not (cover and cover.Label and cover.Background and cover.Waitdot1 and cover.Waitdot2 and cover.Waitdot3) then return end
	if value then
		-- Hide overlay and text label
		cover.Label:Hide()
		cover.Background:Hide()
		-- Hide the 3 animated texture icons
		cover.Waitdot1:Hide()
		cover.Waitdot2:Hide()
		cover.Waitdot3:Hide()
	else
		-- Hide overlay and text label
		cover.Label:Show()
		cover.Background:Show()
		-- Hide the 3 animated texture icons
		cover.Waitdot1:Show()
		cover.Waitdot2:Show()
		cover.Waitdot3:Show()
	end
end

function addon.functions.initDungeonFrame()
	if addon.db and addon.db[NAMEPLATE_AURA_CLICKTHROUGH_DB_KEY] == nil and addon.db[LEGACY_NAMEPLATE_AURA_CLICKTHROUGH_DB_KEY] ~= nil then
		addon.db[NAMEPLATE_AURA_CLICKTHROUGH_DB_KEY] = addon.db[LEGACY_NAMEPLATE_AURA_CLICKTHROUGH_DB_KEY] and true or false
	end

	addon.functions.InitDBValue("autoChooseDelvePower", false)
	addon.functions.InitDBValue("lfgSortByRio", false)
	addon.functions.InitDBValue("groupfinderSkipRoleSelect", false)
	addon.functions.InitDBValue("enableChatIMRaiderIO", false)
	addon.functions.InitDBValue(NAMEPLATE_AURA_CLICKTHROUGH_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLORS_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLORS_DUNGEONS_DB_KEY, true)
	addon.functions.InitDBValue(NAMEPLATE_MOB_COLORS_OUTSIDE_DUNGEONS_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_SLUG_OUTLINE_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_TEXT_FONT_DB_KEY, addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or "__EQOL_GLOBAL_FONT__")
	addon.functions.InitDBValue(NAMEPLATE_TEXT_OUTLINE_DB_KEY, addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or "__EQOL_GLOBAL_FONT_STYLE__")
	addon.functions.InitDBValue(NAMEPLATE_TEXT_SIZE_DB_KEY, 0)
	addon.functions.InitDBValue(NAMEPLATE_FRIENDLY_PLAYER_NAMES_ONLY_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_FRIENDLY_PLAYER_CLASS_COLOR_NAMES_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_HIDE_FRIENDLY_PLAYER_REALMS_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_ELITE_MARKERS_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_ELITE_MARKER_ANCHOR_DB_KEY, "LEFT")
	addon.functions.InitDBValue(NAMEPLATE_ELITE_MARKER_SIZE_DB_KEY, 18)
	addon.functions.InitDBValue(NAMEPLATE_QUEST_MARKERS_DB_KEY, false)
	addon.functions.InitDBValue(NAMEPLATE_QUEST_MARKER_ANCHOR_DB_KEY, "RIGHT")
	addon.functions.InitDBValue(NAMEPLATE_QUEST_MARKER_SIZE_DB_KEY, 18)
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
	addon.functions.InitDBValue("combatLogDelve", false)
	addon.functions.InitDBValue("combatLogDelayedStop", false)

	nameplateAuraClickthroughActive = addon.db and addon.db[NAMEPLATE_AURA_CLICKTHROUGH_DB_KEY] == true
	nameplateMobColorsActive = addon.db and addon.db[NAMEPLATE_MOB_COLORS_DB_KEY] == true
	nameplateEliteMarkersActive = addon.db and addon.db[NAMEPLATE_ELITE_MARKERS_DB_KEY] == true
	nameplateQuestMarkersActive = addon.db and addon.db[NAMEPLATE_QUEST_MARKERS_DB_KEY] == true
	nameplateTargetMarkersActive = addon.db and addon.db[NAMEPLATE_TARGET_MARKERS_DB_KEY] == true
	nameplateHealthbarTextureActive = type(addon.db and addon.db[NAMEPLATE_HEALTHBAR_TEXTURE_DB_KEY]) == "string" and addon.db[NAMEPLATE_HEALTHBAR_TEXTURE_DB_KEY] ~= ""
	nameplateFocusHealthbarTextureActive = type(addon.db and addon.db[NAMEPLATE_FOCUS_HEALTHBAR_TEXTURE_DB_KEY]) == "string" and addon.db[NAMEPLATE_FOCUS_HEALTHBAR_TEXTURE_DB_KEY] ~= ""
	if nameplateAuraClickthroughActive then syncNameplateAuraClickthrough() end
	if nameplateMobColorsActive then syncNameplateMobColors() end
	if addon.functions.InitializeDefaultNameplateFriendlyPlayerOptions then addon.functions.InitializeDefaultNameplateFriendlyPlayerOptions() end
	if addon.functions.InitializeDefaultNameplateTextStyle then addon.functions.InitializeDefaultNameplateTextStyle() end
	if nameplateEliteMarkersActive then syncNameplateEliteMarkers() end
	if nameplateQuestMarkersActive then syncNameplateQuestMarkers() end
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
	createCombatLogToggle("combatLogDelve", L["combatLogDelve"] or "Delves", L["combatLogDelveDesc"] or "Automatically toggle combat logging in delves.")

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

	-- Add Raider.IO URL to LFG applicant member context menu
	if Menu and Menu.ModifyMenu then
		local regionTable = { "US", "KR", "EU", "TW", "CN" }
		local function trimNamePart(value)
			if issecretvalue and issecretvalue(value) then return nil end
			if type(value) ~= "string" then return nil end
			value = value:gsub("^%s+", ""):gsub("%s+$", "")
			if value == "" then return nil end
			return value
		end

		local function AddLFGApplicantRIO(owner, root, ctx)
			if not addon.db["enableChatIMRaiderIO"] then return end

			local ownerParent = owner and owner.GetParent and owner:GetParent() or nil
			local appID = (ownerParent and ownerParent.applicantID) or (ctx and (ctx.applicantID or ctx.appID))
			local memberIdx = (owner and owner.memberIdx) or (ctx and (ctx.memberIdx or ctx.memberIndex))
			if issecretvalue and (issecretvalue(appID) or issecretvalue(memberIdx)) then return end
			if not appID or not memberIdx then return end

			local name = C_LFGList and C_LFGList.GetApplicantMemberInfo and C_LFGList.GetApplicantMemberInfo(appID, memberIdx)
			if issecretvalue and issecretvalue(name) then return end
			if type(name) ~= "string" or name == "" then return end

			local char, realm = name:match("^%s*([^%-]+)%s*%-%s*(.-)%s*$")
			char = trimNamePart(char) or trimNamePart(name)
			realm = trimNamePart(realm) or trimNamePart(GetRealmName() or "")
			if not char or not realm then return end

			local regionKey = regionTable[GetCurrentRegion()] or "EU"
			local realmSlug = realm:gsub("%s+", "-"):lower()
			local riolink = "https://raider.io/characters/" .. string.lower(regionKey) .. "/" .. realmSlug .. "/" .. char

			root:CreateDivider()
			root:CreateButton(L["RaiderIOUrl"], function(link)
				if StaticPopup_Show then StaticPopup_Show("EQOL_URL_COPY", nil, nil, link) end
			end, riolink)
		end

		Menu.ModifyMenu("MENU_LFG_FRAME_MEMBER_APPLY", AddLFGApplicantRIO)
	end

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
		var = "randomMountDracthyrVisageBeforeMount",
		text = L["randomMountDracthyrVisageBeforeMount"] or "Turn to Visage form as Dracthyr before mounting",
		desc = L["randomMountDracthyrVisageBeforeMountDesc"] or "Only applies to Dracthyr characters.",
		func = function(value) addon.db["randomMountDracthyrVisageBeforeMount"] = value and true or false end,
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

-- Dungeons & Mythic+
local sectionDungeon = addon.SettingsLayout.gameplayDungeonsMythicSection
if not sectionDungeon then
	sectionDungeon = addon.functions.SettingsCreateExpandableSection(cChar, {
		name = L["DungeonsMythicPlus"],
		iconKey = "dungeons",
		expanded = false,
		colorizeTitle = false,
		newTagID = "DungeonsMythicPlus",
		modernOnly = true,
	})
	addon.SettingsLayout.gameplayDungeonsMythicSection = sectionDungeon
end

-- Mythic+ & Raid (Combat & Dungeon)
local keystoneEnable
local function isKeystoneEnabled() return keystoneEnable and keystoneEnable.setting and keystoneEnable.setting:GetValue() == true end

if cChar and sectionDungeon then
	addon.functions.SettingsCreateHeadline(cChar, PLAYER_DIFFICULTY_MYTHIC_PLUS .. " & " .. RAID, { parentSection = sectionDungeon })

	-- Keystone Helper
	keystoneEnable = addon.functions.SettingsCreateCheckbox(cChar, {
		var = "enableKeystoneHelper",
		text = L["enableKeystoneHelper"],
		desc = L["enableKeystoneHelperDesc"],
		func = function(v)
			addon.db["enableKeystoneHelper"] = v
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.toggleFrame then addon.MythicPlus.functions.toggleFrame() end
		end,
		parentSection = sectionDungeon,
	})

	local keystoneChildren = {
		{ var = "autoInsertKeystone", text = L["Automatically insert keystone"], func = function(v) addon.db["autoInsertKeystone"] = v end, parentSection = sectionDungeon },
		{ var = "closeBagsOnKeyInsert", text = L["Close all bags on keystone insert"], func = function(v) addon.db["closeBagsOnKeyInsert"] = v end, parentSection = sectionDungeon },
		{ var = "autoKeyStart", text = L["autoKeyStart"], func = function(v) addon.db["autoKeyStart"] = v end, parentSection = sectionDungeon },
	}
	for _, entry in ipairs(keystoneChildren) do
		entry.parent = true
		entry.element = keystoneEnable.element
		entry.parentCheck = isKeystoneEnabled
		addon.functions.SettingsCreateCheckbox(cChar, entry)
	end

	local listPull, orderPull = addon.functions.prepareListForDropdown({
		[1] = _G.NONE,
		[2] = L["Blizzard Pull Timer"],
		[3] = L["DBM / BigWigs Pull Timer"],
		[4] = _G.STATUS_TEXT_BOTH,
	})
	addon.functions.SettingsCreateDropdown(cChar, {
		var = "PullTimerType",
		text = L["Pull Timer"],
		desc = L["PullTimerTypeDesc"],
		type = Settings.VarType.Number,
		default = 2,
		list = listPull,
		order = orderPull,
		get = function() return (addon.db and addon.db["PullTimerType"]) or 1 end,
		set = function(value) addon.db["PullTimerType"] = value end,
		parent = true,
		element = keystoneEnable.element,
		parentCheck = isKeystoneEnabled,
		parentSection = sectionDungeon,
	})

	addon.functions.SettingsCreateCheckbox(cChar, {
		var = "noChatOnPullTimer",
		text = L["noChatOnPullTimer"],
		desc = L["noChatOnPullTimerDesc"],
		func = function(v) addon.db["noChatOnPullTimer"] = v end,
		parent = true,
		element = keystoneEnable.element,
		parentCheck = isKeystoneEnabled,
		parentSection = sectionDungeon,
	})

	addon.functions.SettingsCreateSlider(cChar, {
		var = "pullTimerLongTime",
		text = L["Pull Timer"],
		desc = L["pullTimerLongTimeDesc"],
		min = 0,
		max = 60,
		step = 1,
		default = 10,
		get = function() return (addon.db and addon.db["pullTimerLongTime"]) or 10 end,
		set = function(val) addon.db["pullTimerLongTime"] = val end,
		parent = true,
		element = keystoneEnable.element,
		parentCheck = isKeystoneEnabled,
		parentSection = sectionDungeon,
	})

	addon.functions.SettingsCreateSlider(cChar, {
		var = "pullTimerShortTime",
		text = L["sliderShortTime"],
		desc = L["pullTimerShortTimeDesc"],
		min = 0,
		max = 60,
		step = 1,
		default = 5,
		get = function() return (addon.db and addon.db["pullTimerShortTime"]) or 5 end,
		set = function(val) addon.db["pullTimerShortTime"] = val end,
		parent = true,
		element = keystoneEnable.element,
		parentCheck = isKeystoneEnabled,
		parentSection = sectionDungeon,
	})

	-- Objective Tracker
	local objEnable = addon.functions.SettingsCreateCheckbox(cChar, {
		var = "mythicPlusEnableObjectiveTracker",
		text = L["mythicPlusEnableObjectiveTracker"],
		desc = L["mythicPlusEnableObjectiveTrackerDesc"],
		func = function(v)
			addon.db["mythicPlusEnableObjectiveTracker"] = v
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.setObjectiveFrames then addon.MythicPlus.functions.setObjectiveFrames() end
		end,
		parentSection = sectionDungeon,
	})
	local function isObjectiveEnabled() return objEnable and objEnable.setting and objEnable.setting:GetValue() == true end

	local objectiveTrackerDefaultScope = "dungeonMythicPlus"
	local objectiveTrackerScopeOptions = {
		{ value = "dungeonNormal", text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY1 },
		{ value = "dungeonHeroic", text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY2 },
		{ value = "dungeonMythic", text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY6 },
		{ value = objectiveTrackerDefaultScope, text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY_MYTHIC_PLUS },
		{ value = "dungeonTimewalking", text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY_TIMEWALKER },
		{ value = "raidLfr", text = RAID .. " - " .. PLAYER_DIFFICULTY3 },
		{ value = "raidNormal", text = RAID .. " - " .. PLAYER_DIFFICULTY1 },
		{ value = "raidHeroic", text = RAID .. " - " .. PLAYER_DIFFICULTY2 },
		{ value = "raidMythic", text = RAID .. " - " .. PLAYER_DIFFICULTY6 },
		{ value = "raidTimewalking", text = RAID .. " - " .. PLAYER_DIFFICULTY_TIMEWALKER },
		{ value = "scenarioDelve", text = L["objectiveTrackerScopeScenarioDelve"] },
	}
	local function getObjectiveTrackerScopes()
		if type(addon.db["mythicPlusObjectiveTrackerScopes"]) ~= "table" then addon.db["mythicPlusObjectiveTrackerScopes"] = { [objectiveTrackerDefaultScope] = true } end
		return addon.db["mythicPlusObjectiveTrackerScopes"]
	end
	addon.functions.SettingsCreateMultiDropdown(cChar, {
		var = "mythicPlusObjectiveTrackerScopes",
		text = L["objectiveTrackerScope"],
		desc = L["objectiveTrackerScopeDesc"],
		options = objectiveTrackerScopeOptions,
		get = getObjectiveTrackerScopes,
		set = function(value)
			addon.db["mythicPlusObjectiveTrackerScopes"] = type(value) == "table" and value or { [objectiveTrackerDefaultScope] = true }
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.setObjectiveFrames then addon.MythicPlus.functions.setObjectiveFrames() end
		end,
		parent = true,
		element = objEnable.element,
		parentCheck = isObjectiveEnabled,
		parentSection = sectionDungeon,
	})

	-- BR Tracker
	addon.functions.SettingsCreateCheckbox(cChar, {
		var = "mythicPlusBRTrackerEnabled",
		text = L["mythicPlusBRTrackerEnabled"],
		desc = L["mythicPlusBRTrackerEditModeHint"],
		func = function(v)
			addon.db["mythicPlusBRTrackerEnabled"] = v
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.createBRFrame then
				addon.MythicPlus.functions.createBRFrame()
			elseif addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.setObjectiveFrames then
				addon.MythicPlus.functions.setObjectiveFrames()
			end
		end,
		parentSection = sectionDungeon,
	})

	addon.functions.SettingsCreateCheckbox(cChar, {
		var = "mythicPlusBloodlustTrackerEnabled",
		text = L["mythicPlusBloodlustTrackerEnabled"],
		desc = L["mythicPlusBloodlustTrackerEditModeHint"],
		func = function(v)
			addon.db["mythicPlusBloodlustTrackerEnabled"] = v
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.syncBloodlustUnitAuraRegistration then addon.MythicPlus.functions.syncBloodlustUnitAuraRegistration() end
			if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.createBloodlustFrame then
				addon.MythicPlus.functions.createBloodlustFrame()
				if addon.MythicPlus.functions.refreshBloodlustTracker then addon.MythicPlus.functions.refreshBloodlustTracker(false) end
			end
		end,
		parentSection = sectionDungeon,
	})
end

data = {
	{
		var = "autoChooseDelvePower",
		text = L["autoChooseDelvePower"],
		desc = L["autoChooseDelvePowerDesc"],
		func = function(value) addon.db["autoChooseDelvePower"] = value and true or false end,
		parentSection = sectionDungeon,
	},
}
table.sort(data, function(a, b) return a.text < b.text end)

addon.functions.SettingsCreateHeadline(cChar, DELVES_LABEL, { parentSection = sectionDungeon })
addon.functions.SettingsCreateCheckboxes(cChar, data)

-- Group Finder
local sectionGroupFinder = addon.SettingsLayout.gameplayGroupFinderSection
if not sectionGroupFinder then
	sectionGroupFinder = addon.functions.SettingsCreateExpandableSection(cChar, {
		name = L["Group Finder"],
		configPageKey = "GroupFinder",
		iconKey = "groupfinder",
		expanded = false,
		colorizeTitle = false,
		modernOnly = true,
	})
	addon.SettingsLayout.gameplayGroupFinderSection = sectionGroupFinder
end

data = {
	{
		text = L["groupfinderAppText"],
		var = "groupfinderAppText",
		func = function(value)
			addon.db["groupfinderAppText"] = value
			if addon.functions.UpdateGroupFinderApplicantEventRegistration then addon.functions.UpdateGroupFinderApplicantEventRegistration() end
			toggleGroupApplication(value)
		end,
		parentSection = sectionGroupFinder,
	},
	{
		text = L["groupfinderSkipRoleSelect"],
		var = "groupfinderSkipRoleSelect",
		func = function(value) addon.db["groupfinderSkipRoleSelect"] = value end,
		desc = L["groupfinderSkipRoleSelectDesc"],
		parentSection = sectionGroupFinder,
		children = {
			{
				list = { [1] = L["groupfinderSkipRolecheckUseSpec"], [2] = L["groupfinderSkipRolecheckUseLFD"] },
				text = L["groupfinderSkipRolecheckHeadline"],
				get = function() return addon.db["groupfinderSkipRoleSelectOption"] or 1 end,
				set = function(key) addon.db["groupfinderSkipRoleSelectOption"] = key end,
				parentCheck = function()
					return addon.SettingsLayout.elements["groupfinderSkipRoleSelect"]
						and addon.SettingsLayout.elements["groupfinderSkipRoleSelect"].setting
						and addon.SettingsLayout.elements["groupfinderSkipRoleSelect"].setting:GetValue() == true
				end,
				parent = true,
				default = 1,
				var = "groupfinderSkipRoleSelectOption",
				type = Settings.VarType.Number,
				sType = "dropdown",
				parentSection = sectionGroupFinder,
			},
		},
	},
	{
		var = "persistSignUpNote",
		text = L["Persist LFG signup note"],
		desc = L["persistSignUpNoteDesc"],
		func = function(value) addon.db["persistSignUpNote"] = value end,
		parentSection = sectionGroupFinder,
	},
	{
		var = "skipSignUpDialog",
		text = L["Quick signup"],
		desc = L["skipSignUpDialogDesc"],
		func = function(value) addon.db["skipSignUpDialog"] = value end,
		parentSection = sectionGroupFinder,
	},
	{
		var = "lfgSortByRio",
		text = L["lfgSortByRio"],
		desc = L["lfgSortByRioDesc"],
		func = function(value)
			addon.db["lfgSortByRio"] = value
			if addon.functions.UpdateGroupFinderApplicantEventRegistration then addon.functions.UpdateGroupFinderApplicantEventRegistration() end
		end,
		parentSection = sectionGroupFinder,
	},
	{
		var = "enableChatIMRaiderIO",
		text = L["enableChatIMRaiderIO"],
		desc = L["enableChatIMRaiderIODesc"],
		func = function(value) addon.db["enableChatIMRaiderIO"] = value end,
		parentSection = sectionGroupFinder,
	},
}

table.insert(data, {
	var = "groupfinderShowPartyKeystone",
	text = L["groupfinderShowPartyKeystone"],
	desc = L["groupfinderShowPartyKeystoneDesc"],
	func = function(v)
		addon.db["groupfinderShowPartyKeystone"] = v
		if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.togglePartyKeystone then addon.MythicPlus.functions.togglePartyKeystone() end
	end,
	parentSection = sectionGroupFinder,
})

table.insert(data, {
	var = "groupfinderShowDungeonScoreFrame",
	text = L["groupfinderShowDungeonScoreFrame"]:format(DUNGEON_SCORE),
	desc = L["groupfinderShowDungeonScoreFrameDesc"],
	func = function(v)
		addon.db["groupfinderShowDungeonScoreFrame"] = v
		if addon.MythicPlus and addon.MythicPlus.functions and addon.MythicPlus.functions.toggleFrame then addon.MythicPlus.functions.toggleFrame() end
	end,
	parentSection = sectionGroupFinder,
})

table.insert(data, {
	var = "mythicPlusEnableDungeonFilter",
	text = L["mythicPlusEnableDungeonFilter"],
	desc = L["mythicPlusEnableDungeonFilterDesc"],
	func = function(v)
		addon.db["mythicPlusEnableDungeonFilter"] = v
		if addon.MythicPlus and addon.MythicPlus.functions then
			if v and addon.MythicPlus.functions.addDungeonFilter then
				addon.MythicPlus.functions.addDungeonFilter()
			elseif not v and addon.MythicPlus.functions.removeDungeonFilter then
				addon.MythicPlus.functions.removeDungeonFilter()
			end
		end
	end,
	parentSection = sectionGroupFinder,
	children = {
		{
			var = "mythicPlusEnableDungeonFilterClearReset",
			text = L["mythicPlusEnableDungeonFilterClearReset"],
			func = function(v) addon.db["mythicPlusEnableDungeonFilterClearReset"] = v end,
			parentCheck = function()
				return addon.SettingsLayout.elements["mythicPlusEnableDungeonFilter"]
					and addon.SettingsLayout.elements["mythicPlusEnableDungeonFilter"].setting
					and addon.SettingsLayout.elements["mythicPlusEnableDungeonFilter"].setting:GetValue() == true
			end,
			parent = true,
			default = false,
			type = Settings.VarType.Boolean,
			sType = "checkbox",
			parentSection = sectionGroupFinder,
		},
	},
})

table.sort(data, function(a, b) return a.text < b.text end)
addon.functions.SettingsCreateCheckboxes(cChar, data)

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
		var = "timeoutRelease_dungeonMythicPlus",
		value = "dungeonMythicPlus",
		text = DUNGEONS .. " - " .. PLAYER_DIFFICULTY_MYTHIC_PLUS,
		func = function(value) addon.db["timeoutReleaseDifficulties"]["dungeonMythicPlus"] = value and true or false end,
		get = function() return addon.db["timeoutReleaseDifficulties"]["dungeonMythicPlus"] end,
		parentCheck = function() return rData.setting and rData.setting:GetValue() == true end,
		element = rData.element,
		parent = true,
		difficulties = { 8 },
	},
	{
		var = "timeoutRelease_dungeonFollower",
		value = "dungeonFollower",
		text = GUILD_CHALLENGE_TYPE4 .. " - " .. L["timeoutReleasePrefixScenario"],
		func = function(value) addon.db["timeoutReleaseDifficulties"]["dungeonFollower"] = value and true or false end,
		get = function() return addon.db["timeoutReleaseDifficulties"]["dungeonFollower"] end,
		parentCheck = function() return rData.setting and rData.setting:GetValue() == true end,
		element = rData.element,
		parent = true,
		difficulties = { 11, 12, 20, 30, 38, 39, 40, 147, 149, 152, 153, 167, 168, 169, 170, 171, 208 },
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
		{
			var = "autoReleasePvPExcludeWintergrasp",
			text = L["autoReleasePvPExcludeWintergrasp"],
			func = function(v) addon.db["autoReleasePvPExcludeWintergrasp"] = v end,
			parentCheck = isAutoReleasePvPEnabled,
			parent = true,
			default = false,
			type = Settings.VarType.Boolean,
			sType = "checkbox",
			parentSection = sectionDeathRes,
		},
		{
			var = "autoReleasePvPExcludeTolBarad",
			text = L["autoReleasePvPExcludeTolBarad"],
			func = function(v) addon.db["autoReleasePvPExcludeTolBarad"] = v end,
			parentCheck = isAutoReleasePvPEnabled,
			parent = true,
			default = false,
			type = Settings.VarType.Boolean,
			sType = "checkbox",
			parentSection = sectionDeathRes,
		},
		{
			var = "autoReleasePvPExcludeAshran",
			text = L["autoReleasePvPExcludeAshran"],
			func = function(v) addon.db["autoReleasePvPExcludeAshran"] = v end,
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
local lfgApplicantRefreshPending = false

local function shouldRegisterGroupFinderApplicantEvent()
	return addon.db and (addon.db["lfgSortByRio"] == true or addon.db["groupfinderAppText"] == true)
end

local function shouldRefreshLFGApplicantsForRioSort()
	return PVEFrame
		and PVEFrame:IsShown()
		and addon.db
		and addon.db["lfgSortByRio"] == true
		and addon.functions
		and addon.functions.isRestrictedContent
		and not addon.functions.isRestrictedContent()
		and C_LFGList
		and C_LFGList.RefreshApplicants
end

local function requestLFGApplicantRefresh()
	if not shouldRefreshLFGApplicantsForRioSort() then return end
	if lfgApplicantRefreshPending then return end
	lfgApplicantRefreshPending = true
	C_Timer.After(0.15, function()
		lfgApplicantRefreshPending = false
		if shouldRefreshLFGApplicantsForRioSort() then C_LFGList.RefreshApplicants() end
	end)
end

function addon.functions.UpdateGroupFinderApplicantEventRegistration()
	if not frameLoad then return end
	if shouldRegisterGroupFinderApplicantEvent() then
		if not frameLoad._eqolLFGApplicantEventRegistered then
			frameLoad:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
			frameLoad._eqolLFGApplicantEventRegistered = true
		end
	elseif frameLoad._eqolLFGApplicantEventRegistered then
		frameLoad:UnregisterEvent("LFG_LIST_APPLICANT_UPDATED")
		frameLoad._eqolLFGApplicantEventRegistered = nil
		lfgApplicantRefreshPending = false
	end
end

function addon.functions.UpdateTimeoutReleaseEventRegistration()
	if not frameLoad then return end
	if not frameLoad._eqolTimeoutReleaseEventRegistered then
		frameLoad:RegisterEvent("MODIFIER_STATE_CHANGED")
		frameLoad._eqolTimeoutReleaseEventRegistered = true
	end
end

local eventHandlers = {

	["LFG_LIST_APPLICANT_UPDATED"] = function()
		requestLFGApplicantRefresh()
		if InCombatLockdown() then return end
		if addon.db["groupfinderAppText"] then toggleGroupApplication(true) end
	end,
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
	["PLAYER_CHOICE_UPDATE"] = function()
		if select(3, GetInstanceInfo()) == 208 and addon.db["autoChooseDelvePower"] then
			local choiceInfo = C_PlayerChoice.GetCurrentPlayerChoiceInfo()
			local option = choiceInfo and choiceInfo.options and #choiceInfo.options == 1 and choiceInfo.options[1]
			if option and option.buttons and #option.buttons == 1 and option.buttons[1].id then
				C_PlayerChoice.SendPlayerChoiceResponse(option.buttons[1].id)
				if PlayerChoiceFrame:IsShown() then PlayerChoiceFrame:Hide() end
			end
		end
	end,
	["UPDATE_INSTANCE_INFO"] = function()
		if addon.functions.UpdateCombatLogState then addon.functions.UpdateCombatLogState() end
	end,
}

local function registerEvents(frame)
	for event in pairs(eventHandlers) do
		if event ~= "LFG_LIST_APPLICANT_UPDATED" then
			frame:RegisterEvent(event)
			if event == "MODIFIER_STATE_CHANGED" then frame._eqolTimeoutReleaseEventRegistered = true end
		end
	end
end

local function eventHandler(self, event, ...)
	if eventHandlers[event] then eventHandlers[event](...) end
end

frameLoad = CreateFrame("Frame")

registerEvents(frameLoad)
addon.functions.UpdateGroupFinderApplicantEventRegistration()
addon.functions.UpdateTimeoutReleaseEventRegistration()
frameLoad:SetScript("OnEvent", eventHandler)
