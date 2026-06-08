-- luacheck: globals C_DamageMeter C_DeathRecap C_LFGInfo C_Spell C_StringUtil C_CVar C_RestrictedActions C_ChallengeMode SetCVar StaticPopupDialogs StaticPopup_Show YES CANCEL OKAY MenuUtil Menu GameTooltip SecondsToClock DAMAGE_METER_COMBAT_NUMBER CLASS_ICON_TCOORDS UnitClass UnitExists UnitGUID UnitName UnitCanAttack UnitIsPlayer UnitAffectingCombat UnitDetailedThreatSituation GetNumGroupMembers GetNumSubgroupMembers IsInRaid IsInInstance GetInstanceInfo Ambiguate UISpecialFrames GetCursorPosition GetTime C_Timer ACTION_SWING ACTION_ENVIRONMENTAL_DAMAGE_DROWNING ACTION_ENVIRONMENTAL_DAMAGE_FALLING ACTION_ENVIRONMENTAL_DAMAGE_FIRE ACTION_ENVIRONMENTAL_DAMAGE_LAVA ACTION_ENVIRONMENTAL_DAMAGE_SLIME ACTION_ENVIRONMENTAL_DAMAGE_FATIGUE DEATH_RECAP_TITLE CreateAbbreviateConfig
local addonName, addon = ...

local host = addon.DamageMeterHost or {}
host.displayName = host.displayName or "EnhanceQoL"
host.framePrefix = host.framePrefix or "EnhanceQoLDamageMeter"
host.editModePrefix = host.editModePrefix or "EQOL_DamageMeter"
host.popupPrefix = host.popupPrefix or "EQOL_DAMAGE_METER"
host.menuHistoryTag = host.menuHistoryTag or "MENU_EQOL_DAMAGE_METER_HISTORY"

local L = LibStub("AceLocale-3.0"):GetLocale(host.localeName or addonName)
local LSM = LibStub("LibSharedMedia-3.0", true)
local EditMode = addon.EditMode
local SettingType = EditMode and EditMode.lib and EditMode.lib.SettingType

local DamageMeter = {}
addon.DamageMeter = DamageMeter

DamageMeter.GENERIC_CLASS_ICON_TCOORDS = {
	WARRIOR = { 0, 0.125, 0, 0.125 },
	MAGE = { 0.125, 0.248046875, 0, 0.125 },
	ROGUE = { 0.248046875, 0.37109375, 0, 0.125 },
	DRUID = { 0.37109375, 0.494140625, 0, 0.125 },
	EVOKER = { 0.50390625, 0.625, 0, 0.125 },
	HUNTER = { 0, 0.125, 0.125, 0.25 },
	SHAMAN = { 0.125, 0.248046875, 0.125, 0.25 },
	PRIEST = { 0.248046875, 0.37109375, 0.125, 0.25 },
	WARLOCK = { 0.37109375, 0.494140625, 0.125, 0.25 },
	PALADIN = { 0, 0.125, 0.25, 0.375 },
	DEATHKNIGHT = { 0.125, 0.25, 0.25, 0.375 },
	MONK = { 0.25, 0.369140625, 0.25, 0.375 },
	DEMONHUNTER = { 0.369140625, 0.5, 0.25, 0.375 },
}

local MAX_WINDOWS = 5
local DEFAULT_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local DEFAULT_BORDER = "Interface\\Buttons\\WHITE8x8"
local DEFAULT_FONT = "Fonts\\FRIZQT__.TTF"
local CLASS_ICON_TEXTURE = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local GLOBAL_FONT_KEY = "__EQOL_GLOBAL_FONT__"
local GLOBAL_STYLE_KEY = "__EQOL_GLOBAL_FONT_STYLE__"
local REMOVE_WINDOW_POPUP = host.popupPrefix .. "_REMOVE_WINDOW"
local COPY_WINDOW_POPUP = host.popupPrefix .. "_COPY_WINDOW"
local RESET_DATA_POPUP = host.popupPrefix .. "_RESET_DATA"
local AUTO_CLEAR_POPUP = host.popupPrefix .. "_AUTO_CLEAR"
local CONTEXT_MENU_WIDTH = 376
local CONTEXT_MENU_PADDING = 8
local CONTEXT_MENU_BUTTON_HEIGHT = 30
local CONTEXT_MENU_BUTTON_GAP = 4
local BLIZZARD_DAMAGE_METER_ENABLED_CVAR = "damageMeterEnabled"
local TOOLTIP_TARGET_ATLAS = "Islands-AzeriteBoss"
local getWindowCount
local PARTY_UNIT_TOKENS = { "player", "party1", "party2", "party3", "party4" }
local SESSION_TYPES = {
	current = Enum and Enum.DamageMeterSessionType and Enum.DamageMeterSessionType.Current,
	overall = Enum and Enum.DamageMeterSessionType and Enum.DamageMeterSessionType.Overall,
}
local STATUSBAR_INTERP = Enum and Enum.StatusBarInterpolation
local INTERP_EASE = STATUSBAR_INTERP and STATUSBAR_INTERP.ExponentialEaseOut
local AUTO_CLEAR_DELAY_SECONDS = 2
local DERIVED_TARGET_SCAN_LIMIT = 80
-- Keep Blizzard's localized abbreviation breakpoints, with one extra floor so sub-1000 DPS values do not show long decimals.
local LOW_NUMBER_ABBREV_BREAKPOINT = { breakpoint = 1, abbreviation = "", significandDivisor = 1, fractionDivisor = 1, abbreviationIsGlobal = false }
local FALLBACK_SHORT_NUMBER_ABBREV_BREAKPOINTS = {
	{ breakpoint = 10000000000, abbreviation = "B", significandDivisor = 1000000000, fractionDivisor = 1, abbreviationIsGlobal = false },
	{ breakpoint = 1000000000, abbreviation = "B", significandDivisor = 100000000, fractionDivisor = 10, abbreviationIsGlobal = false },
	{ breakpoint = 10000000, abbreviation = "M", significandDivisor = 10000, fractionDivisor = 100, abbreviationIsGlobal = false },
	{ breakpoint = 1000000, abbreviation = "M", significandDivisor = 10000, fractionDivisor = 100, abbreviationIsGlobal = false },
	{ breakpoint = 10000, abbreviation = "K", significandDivisor = 1000, fractionDivisor = 1, abbreviationIsGlobal = false },
	{ breakpoint = 1000, abbreviation = "K", significandDivisor = 100, fractionDivisor = 10, abbreviationIsGlobal = false },
	LOW_NUMBER_ABBREV_BREAKPOINT,
}
local shortNumberAbbrevOptions
local SYNC_EXCLUDED_KEYS = {
	alwaysShowPlayer = true,
	anchorToWindow = true,
	sessionType = true,
	damageMeterType = true,
	keepManualType = true,
	roleSpecificType = true,
	tankDamageMeterType = true,
	healerDamageMeterType = true,
	damagerDamageMeterType = true,
	visibility = true,
	visibilityFadeAlpha = true,
	visibilityFadeMode = true,
	visibleRows = true,
	raidRowsEnabled = true,
	raidVisibleRows = true,
	windowAnchorPoint = true,
	windowRelativePoint = true,
	windowOffsetX = true,
	windowOffsetY = true,
	showHeaderTime = true,
	tooltipPreview = true,
}
local DEFAULT_WINDOW = {
	alwaysShowPlayer = false,
	anchorToWindow = 0,
	windowAnchorPoint = "TOPLEFT",
	windowRelativePoint = "TOPRIGHT",
	windowOffsetX = 0,
	windowOffsetY = 0,
	sessionType = "current",
	damageMeterType = "DamageDone",
	keepManualType = false,
	roleSpecificType = false,
	tankDamageMeterType = "DamageDone",
	healerDamageMeterType = "HealingDone",
	damagerDamageMeterType = "DamageDone",
	quickTypes = { "DamageDone", "DamageTaken" },
	visibility = "always",
	visibilityFadeMode = "none",
	visibilityFadeAlpha = 0.25,
	visibleRows = 5,
	raidRowsEnabled = false,
	raidVisibleRows = 8,
	width = 300,
	heightOffset = 0,
	headerPosition = "TOP",
	rowGrowth = "DOWN",
	rowSort = "TOP",
	rowHeight = 20,
	changeBarSize = true,
	barHeight = 20,
	barAnchor = "CENTER",
	barWidthOffset = 0,
	barSpacing = 4,
	smoothBars = true,
	barBackgroundUseCustomTexture = false,
	barBackgroundCustomTexture = "",
	barBackgroundTexture = "",
	barBackgroundColor = { r = 0, g = 0, b = 0, a = 0.45 },
	rowBorderEnabled = false,
	rowBorderTexture = "",
	rowBorderColor = { r = 0, g = 0, b = 0, a = 0.9 },
	rowBorderUseClassColor = false,
	rowBorderSize = 1,
	rowBorderInset = 0,
	barBorderEnabled = true,
	barBorderTexture = "",
	barBorderColor = { r = 0, g = 0, b = 0, a = 0.2 },
	barBorderUseClassColor = false,
	barBorderSize = 1,
	barBorderInset = 0,
	changeIconSize = true,
	iconSizeOffset = 0,
	iconGap = 4,
	iconType = "class",
	iconUseCustomClassTexture = false,
	iconCustomClassTexture = "",
	iconBorderEnabled = false,
	iconBorderTexture = "EQOL: Midnight white",
	iconBorderColor = { r = 0, g = 0, b = 0, a = 0.9 },
	iconBorderUseClassColor = true,
	iconBorderSize = 8,
	iconBorderInset = 0,
	borderAlignmentVersion = 2,
	showHeader = true,
	showHeaderSession = false,
	showHeaderType = true,
	showHeaderTime = true,
	showHeaderButtons = true,
	showHeaderReportButton = true,
	headerHistoryHover = true,
	headerButtonSize = 16,
	headerButtonOffsetX = 0,
	headerButtonOffsetY = 6,
	headerButtonColor = { r = 1, g = 1, b = 1, a = 1 },
	headerButtonAlpha = 1,
	headerButtonFadeEnabled = false,
	headerButtonFadeAlpha = 0.35,
	headerBackgroundEnabled = true,
	headerBackgroundUseCustomTexture = true,
	headerBackgroundCustomTexture = "ui-damagemeters-header-bar",
	headerBackgroundTexture = "TWEBA Blizzard",
	headerBackgroundColor = { r = 1, g = 1, b = 1, a = 1 },
	headerBackgroundOffsetX = 0,
	headerBackgroundOffsetY = 6,
	headerBackgroundSizeOffsetX = 9,
	headerBackgroundSizeOffsetY = 3,
	headerTextOffsetX = 0,
	headerTextOffsetY = 9,
	headerFormat = "timeTypeDash",
	headerTimeFormat = "clock",
	showStatus = false,
	footerBackgroundEnabled = false,
	footerBackgroundUseCustomTexture = false,
	footerBackgroundCustomTexture = "",
	footerBackgroundTexture = "EQOL: Blizzard cropped",
	footerBackgroundColor = { r = 0, g = 0, b = 0, a = 0.35 },
	footerBackgroundOffsetX = 0,
	footerBackgroundOffsetY = 0,
	footerBackgroundSizeOffsetX = 0,
	footerBackgroundSizeOffsetY = 0,
	showFooterQuickSwitch = true,
	showNoData = true,
	showNames = true,
	showIcons = true,
	showRanks = false,
	prefixRankInName = false,
	rankUseClassColors = false,
	rankColor = { r = 1, g = 1, b = 1, a = 1 },
	rankGap = 0,
	rankAnchorH = "LEFT",
	rankAnchorV = "CENTER",
	rankOffsetX = 0,
	rankOffsetY = 0,
	rankFontFace = GLOBAL_FONT_KEY,
	rankFontOutline = GLOBAL_STYLE_KEY,
	rankFontSize = 10,
	showPercent = false,
	hideRealmNames = true,
	nameNoEllipsis = false,
	abbreviation = "short",
	valueLayout = "combined",
	amountColumnWidth = 65,
	rateColumnWidth = 48,
	percentColumnWidth = 46,
	valueColumnGap = 4,
	nameValueGap = 6,
	minNameWidth = 135,
	valueMode = "auto",
	valueFormat = "slash",
	valueSeparator = "|",
	nameAnchorH = "LEFT",
	nameAnchorV = "CENTER",
	nameOffsetX = 5,
	nameOffsetY = 0,
	valueAnchorH = "RIGHT",
	valueAnchorV = "CENTER",
	valueOffsetX = -5,
	valueOffsetY = 0,
	useClassColors = true,
	barColor = { r = 0.22, g = 0.56, b = 0.9, a = 1 },
	barOpacity = 0.85,
	nameUseClassColors = false,
	nameColor = { r = 1, g = 1, b = 1, a = 1 },
	texture = "Blizzard Raid Bar",
	backdropUseCustomTexture = false,
	backdropCustomTexture = "",
	backdropTexture = "",
	backdropColor = { r = 0.01960784383118153, g = 0.02352941408753395, b = 0.0313725508749485, a = 0 },
	backdropOffsetX = 0,
	backdropOffsetY = 0,
	backdropSizeOffsetX = 0,
	backdropSizeOffsetY = 0,
	contentBackgroundEnabled = false,
	contentBackgroundUseCustomTexture = false,
	contentBackgroundCustomTexture = "",
	contentBackgroundTexture = "",
	contentBackgroundColor = { r = 0, g = 0, b = 0, a = 0.35 },
	contentBackgroundOffsetX = 0,
	contentBackgroundOffsetY = 0,
	contentBackgroundSizeOffsetX = 0,
	contentBackgroundSizeOffsetY = 0,
	borderEnabled = false,
	borderTexture = "EQOL: Midnight white",
	borderColor = { r = 1, g = 0.8196079134941101, b = 0, a = 1 },
	borderSize = 8,
	borderInset = 2,
	borderUseAdvancedOffsets = false,
	borderOffsetX = 0,
	borderOffsetY = 0,
	borderSizeOffsetX = 0,
	borderSizeOffsetY = 0,
	unclampWindow = false,
	fontFace = GLOBAL_FONT_KEY,
	fontOutline = GLOBAL_STYLE_KEY,
	fontSize = 14,
	valueFontFace = GLOBAL_FONT_KEY,
	valueFontOutline = GLOBAL_STYLE_KEY,
	valueFontSize = 14,
	valueUseClassColors = false,
	valueColor = { r = 1, g = 1, b = 1, a = 1 },
	titleFontFace = GLOBAL_FONT_KEY,
	titleFontOutline = GLOBAL_STYLE_KEY,
	titleFontSize = 14,
	titleColor = { r = 1, g = 0.82, b = 0, a = 1 },
	statusFontFace = "Friz Quadrata TT",
	statusFontOutline = "SHADOW",
	statusFontSize = 10,
	tooltipEnabled = true,
	tooltipClickToPin = false,
	tooltipPreview = false,
	tooltipAnchor = "RIGHT",
	tooltipAnchorV = "CENTER",
	tooltipGrow = "DOWN",
	tooltipOffsetX = 8,
	tooltipOffsetY = 0,
	tooltipFontFace = GLOBAL_FONT_KEY,
	tooltipFontOutline = GLOBAL_STYLE_KEY,
	tooltipFontSize = 14,
	tooltipMaxLines = 12,
	tooltipShowTargets = true,
	tooltipWidth = 380,
	tooltipBackdropTexture = "",
	tooltipBorderTexture = "Blizzard Tooltip",
	tooltipBorderSize = 14,
	tooltipBorderInset = 3,
	tooltipShowBars = true,
	tooltipBarTexture = "Blizzard Raid Bar",
	tooltipBarColor = { r = 0.7686275243759155, g = 0.168627455830574, b = 0.2823529541492462, a = 1 },
	tooltipBarUseClassColor = false,
	tooltipBarSpacing = 0,
	tooltipRowBorderEnabled = false,
	tooltipRowBorderTexture = "",
	tooltipRowBorderColor = { r = 0, g = 0, b = 0, a = 0.9 },
	tooltipRowBorderUseClassColor = false,
	tooltipRowBorderSize = 1,
	tooltipRowBorderInset = 0,
	tooltipBarBorderEnabled = false,
	tooltipBarBorderTexture = "",
	tooltipBarBorderColor = { r = 0, g = 0, b = 0, a = 0.9 },
	tooltipBarBorderUseClassColor = false,
	tooltipBarBorderSize = 1,
	tooltipBarBorderInset = 0,
	tooltipIconBorderEnabled = false,
	tooltipIconBorderTexture = "",
	tooltipIconBorderColor = { r = 0, g = 0, b = 0, a = 0.9 },
	tooltipIconBorderUseClassColor = false,
	tooltipIconBorderSize = 1,
	tooltipIconBorderInset = 0,
	tooltipIconGap = 4,
	tooltipShowAmount = true,
	tooltipShowDPS = true,
	tooltipShowPercent = true,
	tooltipShowCreatureName = true,
	tooltipCreatureNameColor = { r = 0.72, g = 0.74, b = 0.78, a = 0.85 },
	tooltipBackdropColor = { r = 0, g = 0, b = 0, a = 0.6718742251396179 },
	tooltipBorderColor = { r = 1, g = 0.8196079134941101, b = 0, a = 0.5468746423721313 },
}
local PREVIEW_SESSION = {
	combatSources = {
		{ totalAmount = 100820000, amountPerSecond = 1008200, name = "Shuja Grimaxe", classFilename = "WARRIOR", specIconID = 132355 },
		{ totalAmount = 82640000, amountPerSecond = 826400, name = "Meredy Huntswell", classFilename = "HUNTER", specIconID = 461115 },
		{ totalAmount = 71250000, amountPerSecond = 712500, name = "Austin Huxworth", classFilename = "MAGE", specIconID = 135932 },
		{ totalAmount = 64890000, amountPerSecond = 648900, name = "Kjellsortera-TarrenMill", classFilename = "PALADIN", specIconID = 135920 },
		{ totalAmount = 51120000, amountPerSecond = 511200, name = "Headhunter-Todeswache", classFilename = "HUNTER", specIconID = 236180 },
		{ totalAmount = 42080000, amountPerSecond = 420800, name = "Raizord", classFilename = "DRUID", specIconID = 132276, isLocalPlayer = true },
	},
	maxAmount = 100820000,
	totalAmount = 412840000,
	durationSeconds = 82,
}
local PREVIEW_SOURCE_DETAILS = {
	combatSpells = {
		{ spellID = 188196, totalAmount = 344000, amountPerSecond = 14400, creatureName = "Ash", combatSpellDetails = { unitName = "Dutiful Groundskeeper", amount = 489000, specIconID = 236157 } },
		{ spellID = 117014, totalAmount = 148000, amountPerSecond = 6000, combatSpellDetails = { unitName = "Restless Steward", amount = 223000, specIconID = 236157 } },
		{ spellID = 51505, totalAmount = 91000, amountPerSecond = 3700, combatSpellDetails = { unitName = "Dutiful Groundskeeper", amount = 91000, specIconID = 236157 } },
		{ spellID = 188389, totalAmount = 58000, amountPerSecond = 2300, combatSpellDetails = { unitName = "Restless Steward", amount = 58000, specIconID = 236157 } },
		{ spellID = 45284, totalAmount = 49000, amountPerSecond = 2000, combatSpellDetails = { unitName = "Dutiful Groundskeeper", amount = 49000, specIconID = 236157 } },
	},
	maxAmount = 344000,
	totalAmount = 690000,
}

local function db()
	return addon.db or {}
end

local function clampNumber(value, minValue, maxValue, default)
	value = tonumber(value) or default
	if value < minValue then return minValue end
	if value > maxValue then return maxValue end
	return value
end

local copyValue
local normalizeWindowQuickTypes

local function copyDefaults(target, defaults)
	for key, value in pairs(defaults) do
		if target[key] == nil then
			target[key] = copyValue(value)
		end
	end
end

copyValue = function(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for key, child in pairs(value) do
		copy[key] = copyValue(child)
	end
	return copy
end

local function applyWindowDefaults(target, index)
	local hadSessionType = target.sessionType ~= nil
	local borderAlignmentVersion = tonumber(target.borderAlignmentVersion) or 1
	if borderAlignmentVersion < 2 then
		local barBorderInset = target.barBorderInset
		if barBorderInset == nil then barBorderInset = DEFAULT_WINDOW.barBorderInset end
		if barBorderInset == 0 and target.iconBorderInset == 1 then
			target.iconBorderInset = DEFAULT_WINDOW.iconBorderInset
		end
		target.borderAlignmentVersion = 2
	end
	copyDefaults(target, DEFAULT_WINDOW)
	if index > 1 and not hadSessionType then
		target.sessionType = index % 2 == 0 and "overall" or "current"
	end
	normalizeWindowQuickTypes(target)
	return target
end

local function copyWindowConfig(source)
	local copy = {}
	source = type(source) == "table" and source or {}
	for key, defaultValue in pairs(DEFAULT_WINDOW) do
		if source[key] ~= nil then
			copy[key] = copyValue(source[key])
		else
			copy[key] = copyValue(defaultValue)
		end
	end
	return copy
end

local function copySyncedWindowConfig(source, target)
	source = type(source) == "table" and source or {}
	target = type(target) == "table" and target or {}
	copyDefaults(target, DEFAULT_WINDOW)
	for key, defaultValue in pairs(DEFAULT_WINDOW) do
		if not SYNC_EXCLUDED_KEYS[key] then
			if source[key] ~= nil then
				target[key] = copyValue(source[key])
			else
				target[key] = copyValue(defaultValue)
			end
		end
	end
	return target
end

local function getGlobalFontKey()
	return addon.functions.GetGlobalFontConfigKey and addon.functions.GetGlobalFontConfigKey() or GLOBAL_FONT_KEY
end

local function getGlobalFontLabel()
	return addon.functions.GetGlobalFontConfigLabel and addon.functions.GetGlobalFontConfigLabel() or (L["useGlobalFontConfig"] or "Use global font config")
end

local function getGlobalStyleKey()
	return addon.functions.GetGlobalFontStyleConfigKey and addon.functions.GetGlobalFontStyleConfigKey() or GLOBAL_STYLE_KEY
end

local function getGlobalStyleLabel()
	return addon.functions.GetGlobalFontStyleConfigLabel and addon.functions.GetGlobalFontStyleConfigLabel() or (L["useGlobalFontStyleConfig"] or "Use global font styling")
end

local function normalizeStyle(value)
	if addon.functions.NormalizeFontStyleChoice then
		return addon.functions.NormalizeFontStyleChoice(value, getGlobalStyleKey(), true)
	end
	if value == GLOBAL_STYLE_KEY then return value end
	if value == "NONE" or value == "OUTLINE" or value == "THICKOUTLINE" or value == "MONOCHROME" or value == "MONOCHROMEOUTLINE" then return value end
	return GLOBAL_STYLE_KEY
end

local function resolveStyle(value)
	if addon.functions.ResolveFontStyleChoice then
		return addon.functions.ResolveFontStyleChoice(value, "OUTLINE")
	end
	value = normalizeStyle(value)
	if value == GLOBAL_STYLE_KEY then
		local globalValue = db().globalFontStyle
		if type(globalValue) == "string" and globalValue ~= "" then return globalValue end
		return "OUTLINE"
	end
	if value == "NONE" then return "" end
	return value
end

local function resolveMedia(mediaType, key, fallback)
	if type(key) == "string" and key ~= "" then
		if addon.functions.ResolveLSMMedia then
			local resolved = addon.functions.ResolveLSMMedia(mediaType, key, fallback, true)
			if resolved then return resolved end
		end
		if LSM and LSM.Fetch then
			local resolved = LSM:Fetch(mediaType, key, true)
			if resolved then return resolved end
		end
	end
	return fallback
end

local function resolveFont(key)
	if key == GLOBAL_FONT_KEY then
		key = db().globalFontFace or getGlobalFontKey()
	end
	return resolveMedia("font", key, DEFAULT_FONT)
end

local function buildMediaOptions(mediaType, includeGlobal)
	local options = {}
	if includeGlobal and mediaType == "font" then
		options[#options + 1] = { value = getGlobalFontKey(), label = getGlobalFontLabel() }
	elseif mediaType == "statusbar" or mediaType == "border" then
		options[#options + 1] = { value = "", label = _G.DEFAULT or "Default" }
	end
	local names = addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames(mediaType) or {}
	for _, name in ipairs(names) do
		options[#options + 1] = { value = name, label = name }
	end
	return options
end

local function buildStyleOptions()
	if addon.functions.GetFontStyleOptionList then
		return addon.functions.GetFontStyleOptionList(true)
	end
	return {
		{ value = getGlobalStyleKey(), label = getGlobalStyleLabel() },
		{ value = "NONE", label = _G.NONE or "None" },
		{ value = "OUTLINE", label = L["Font outline"] or "Font outline" },
		{ value = "THICKOUTLINE", label = L["Thick outline"] or "Thick outline" },
		{ value = "MONOCHROME", label = "Monochrome" },
		{ value = "MONOCHROMEOUTLINE", label = "Monochrome Outline" },
	}
end

local function buildHorizontalAnchorOptions()
	return {
		{ value = "LEFT", label = _G.LEFT or "Left" },
		{ value = "CENTER", label = _G.CENTER or "Center" },
		{ value = "RIGHT", label = _G.RIGHT or "Right" },
	}
end

local function buildVerticalAnchorOptions()
	return {
		{ value = "TOP", label = _G.TOP or "Top" },
		{ value = "CENTER", label = _G.CENTER or "Center" },
		{ value = "BOTTOM", label = _G.BOTTOM or "Bottom" },
	}
end

local function buildTooltipAnchorOptions()
	return {
		{ value = "RIGHT", label = _G.RIGHT or "Right" },
		{ value = "LEFT", label = _G.LEFT or "Left" },
		{ value = "TOP", label = _G.TOP or "Top" },
		{ value = "BOTTOM", label = _G.BOTTOM or "Bottom" },
	}
end

local function buildTooltipGrowOptions()
	return {
		{ value = "DOWN", label = L["damageMeterRowsGrowDown"] or "Down" },
		{ value = "UP", label = L["damageMeterRowsGrowUp"] or "Up" },
	}
end

local function buildHeaderPositionOptions()
	return {
		{ value = "TOP", label = _G.TOP or "Top" },
		{ value = "BOTTOM", label = _G.BOTTOM or "Bottom" },
	}
end

local function buildRowGrowthOptions()
	return {
		{ value = "DOWN", label = L["damageMeterRowsGrowDown"] or "Down" },
		{ value = "UP", label = L["damageMeterRowsGrowUp"] or "Up" },
	}
end

local function buildRowSortOptions()
	return {
		{ value = "TOP", label = L["damageMeterHighestBarTop"] or "Highest bar on top" },
		{ value = "BOTTOM", label = L["damageMeterHighestBarBottom"] or "Highest bar on bottom" },
	}
end

local function buildVisibilityOptions()
	return {
		{ value = "MOUSEOVER", label = L["Mouseover"] or "Mouseover", text = L["Mouseover"] or "Mouseover" },
		{ value = "ALWAYS_IN_COMBAT", label = L["In combat"] or "In combat", text = L["In combat"] or "In combat" },
		{ value = "ALWAYS_OUT_OF_COMBAT", label = L["Out of combat"] or "Out of combat", text = L["Out of combat"] or "Out of combat" },
		{ value = "PLAYER_IN_PARTY", label = L["In party"] or "In party", text = L["In party"] or "In party" },
		{ value = "PLAYER_IN_RAID", label = L["In raid"] or "In raid", text = L["In raid"] or "In raid" },
		{ value = "PLAYER_IN_GROUP", label = L["In party/raid"] or "In party/raid", text = L["In party/raid"] or "In party/raid" },
		{ value = "IN_INSTANCE", label = L["VisibilityCondInInstance"] or "In instance", text = L["VisibilityCondInInstance"] or "In instance" },
		{ value = "IN_MYTHIC_PLUS", label = L["damageMeterVisibilityInMythicPlus"] or "In Mythic+", text = L["damageMeterVisibilityInMythicPlus"] or "In Mythic+" },
		{ value = "OPEN_WORLD", label = L["World"] or "Open world", text = L["World"] or "Open world" },
		{ value = "NOT_IN_INSTANCE", label = L["damageMeterVisibilityNotInInstance"] or "Not in instance", text = L["damageMeterVisibilityNotInInstance"] or "Not in instance" },
	}
end

local DAMAGE_METER_VISIBILITY_KEYS = {
	MOUSEOVER = true,
	ALWAYS_IN_COMBAT = true,
	ALWAYS_OUT_OF_COMBAT = true,
	PLAYER_IN_PARTY = true,
	PLAYER_IN_RAID = true,
	PLAYER_IN_GROUP = true,
	IN_INSTANCE = true,
	IN_MYTHIC_PLUS = true,
	OPEN_WORLD = true,
	NOT_IN_INSTANCE = true,
}

local function isVisibilityOptionAllowed(value)
	return type(value) == "string" and DAMAGE_METER_VISIBILITY_KEYS[value] == true
end

local function normalizeVisibilityConfig(value)
	if type(value) == "table" then
		local config
		for key in pairs(value) do
			if DAMAGE_METER_VISIBILITY_KEYS[key] then
				config = config or {}
				config[key] = true
			end
		end
		return config
	end
	return nil
end

local function getDamageMeterVisibilityContext()
	local inInstance = IsInInstance and IsInInstance() == true
	local inMythicPlus = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() == true
	local inRaid = IsInRaid and IsInRaid() == true
	local inGroup = _G.IsInGroup and _G.IsInGroup() == true
	return {
		inCombat = UnitAffectingCombat and UnitAffectingCombat("player") == true,
		inGroup = inGroup,
		inInstance = inInstance,
		inMythicPlus = inMythicPlus,
		inParty = inGroup and not inRaid,
		inRaid = inRaid,
		openWorld = not inInstance,
	}
end

local function visibilityMatchesContext(visibility, isMouseOver)
	local config = normalizeVisibilityConfig(visibility)
	if not config then return true end
	if config.MOUSEOVER and isMouseOver == true then return true end
	local context = getDamageMeterVisibilityContext()
	if config.ALWAYS_IN_COMBAT and context.inCombat then return true end
	if config.ALWAYS_OUT_OF_COMBAT and not context.inCombat then return true end
	if config.PLAYER_IN_PARTY and context.inParty then return true end
	if config.PLAYER_IN_RAID and context.inRaid then return true end
	if config.PLAYER_IN_GROUP and context.inGroup then return true end
	if config.IN_INSTANCE and context.inInstance then return true end
	if config.IN_MYTHIC_PLUS and context.inMythicPlus then return true end
	if config.OPEN_WORLD and context.openWorld then return true end
	if config.NOT_IN_INSTANCE and not context.inInstance then return true end
	return false
end

local function visibilityUsesMouseover(visibility)
	local config = normalizeVisibilityConfig(visibility)
	return config and config.MOUSEOVER == true
end

local DAMAGE_METER_TYPES = {
	{ key = "Absorbs", global = "DAMAGE_METER_TYPE_ABSORBS", enum = "Absorbs" },
	{ key = "AvoidableDamageTaken", global = "DAMAGE_METER_TYPE_AVOIDABLE_DAMAGE_TAKEN", enum = "AvoidableDamageTaken" },
	{ key = "DamageDone", global = "DAMAGE_METER_TYPE_DAMAGE_DONE", enum = "DamageDone" },
	{ key = "DamageTaken", global = "DAMAGE_METER_TYPE_DAMAGE_TAKEN", enum = "DamageTaken" },
	{ key = "Deaths", global = "DAMAGE_METER_TYPE_DEATHS", enum = "Deaths" },
	{ key = "Dispels", global = "DAMAGE_METER_TYPE_DISPELS", enum = "Dispels" },
	{ key = "Dps", global = "DAMAGE_METER_TYPE_DPS", enum = "Dps" },
	{ key = "EnemyDamageTaken", global = "DAMAGE_METER_TYPE_ENEMY_DAMAGE_TAKEN", enum = "EnemyDamageTaken" },
	{ key = "HealingDone", global = "DAMAGE_METER_TYPE_HEALING_DONE", enum = "HealingDone" },
	{ key = "Hps", global = "DAMAGE_METER_TYPE_HPS", enum = "Hps" },
	{ key = "Interrupts", global = "DAMAGE_METER_TYPE_INTERRUPTS", enum = "Interrupts" },
	{ key = "Threat", global = "THREAT" },
}

local DAMAGE_METER_TYPE_ICONS = {
	Absorbs = "Interface\\Icons\\Spell_Holy_PowerWordShield",
	AvoidableDamageTaken = "Interface\\Icons\\Ability_Defend",
	DamageDone = "Interface\\Icons\\INV_Sword_04",
	DamageTaken = "Interface\\Icons\\Ability_Defend",
	Deaths = "Interface\\Icons\\Ability_Creature_Cursed_02",
	Dispels = "Interface\\Icons\\Spell_Holy_DispelMagic",
	Dps = "Interface\\Icons\\INV_Sword_04",
	EnemyDamageTaken = "Interface\\Icons\\Ability_DualWield",
	HealingDone = "Interface\\Icons\\Spell_Holy_HolyBolt",
	Hps = "Interface\\Icons\\Spell_Holy_HolyBolt",
	Interrupts = "Interface\\Icons\\Ability_Kick",
	Threat = "Interface\\Icons\\Ability_Warrior_Incite",
}

local function getDamageMeterTypeInfo(key)
	for _, info in ipairs(DAMAGE_METER_TYPES) do
		if info.key == key then return info end
	end
	return DAMAGE_METER_TYPES[3]
end

local function getDamageMeterTypeLabel(key)
	local info = getDamageMeterTypeInfo(key)
	return _G[info.global] or info.key
end

local function getDamageMeterTypeIcon(key)
	return DAMAGE_METER_TYPE_ICONS[getDamageMeterTypeInfo(key).key] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function normalizeDamageMeterTypeKey(key)
	local info = getDamageMeterTypeInfo(key)
	return info and info.key or DEFAULT_WINDOW.damageMeterType
end

local function getDamageMeterTypeValue(key)
	local info = getDamageMeterTypeInfo(key)
	if not info.enum then return nil end
	return Enum and Enum.DamageMeterType and Enum.DamageMeterType[info.enum]
end

local function buildDamageMeterTypeOptions()
	local options = {}
	for _, info in ipairs(DAMAGE_METER_TYPES) do
		if not info.enum or (Enum and Enum.DamageMeterType and Enum.DamageMeterType[info.enum] ~= nil) then
			options[#options + 1] = { value = info.key, label = getDamageMeterTypeLabel(info.key) }
		end
	end
	table.sort(options, function(a, b) return a.label < b.label end)
	return options
end

local function isValidDamageMeterTypeKey(key)
	for _, info in ipairs(DAMAGE_METER_TYPES) do
		if info.key == key then return true end
	end
	return false
end

local function normalizeQuickDamageMeterTypes(types, fallback)
	local normalized = {}
	local seen = {}
	if type(types) == "table" then
		for _, value in ipairs(types) do
			local key = normalizeDamageMeterTypeKey(value)
			if isValidDamageMeterTypeKey(key) and not seen[key] then
				normalized[#normalized + 1] = key
				seen[key] = true
			end
		end
	end
	if #normalized == 0 and fallback then
		local key = normalizeDamageMeterTypeKey(fallback)
		if isValidDamageMeterTypeKey(key) then normalized[1] = key end
	end
	return normalized
end

normalizeWindowQuickTypes = function(config)
	config.quickTypes = normalizeQuickDamageMeterTypes(config.quickTypes, config.damageMeterType or DEFAULT_WINDOW.damageMeterType)
	return config.quickTypes
end

local function normalizeFramePoint(value)
	if value == "TOPLEFT" or value == "TOP" or value == "TOPRIGHT" or value == "LEFT" or value == "CENTER" or value == "RIGHT" or value == "BOTTOMLEFT" or value == "BOTTOM" or value == "BOTTOMRIGHT" then
		return value
	end
	return "TOPLEFT"
end

local function buildFramePointOptions()
	return {
		{ value = "TOPLEFT", label = "TOPLEFT" },
		{ value = "TOP", label = "TOP" },
		{ value = "TOPRIGHT", label = "TOPRIGHT" },
		{ value = "LEFT", label = "LEFT" },
		{ value = "CENTER", label = "CENTER" },
		{ value = "RIGHT", label = "RIGHT" },
		{ value = "BOTTOMLEFT", label = "BOTTOMLEFT" },
		{ value = "BOTTOM", label = "BOTTOM" },
		{ value = "BOTTOMRIGHT", label = "BOTTOMRIGHT" },
	}
end

local function buildWindowAnchorOptions(index)
	local options = {
		{ value = "0", label = _G.NONE or "None" },
	}
	for windowIndex = 1, math.min(index - 1, getWindowCount()) do
		options[#options + 1] = { value = tostring(windowIndex), label = string.format("%s %d", L["damageMeterTitle"] or "Damage Meter", windowIndex) }
	end
	return options
end

local function isSecret(value)
	return _G.issecretvalue and _G.issecretvalue(value)
end

local function safeText(value, fallback)
	if value == nil or isSecret(value) then return fallback end
	value = tostring(value)
	if value == "" then return fallback end
	return value
end

local function safeNumber(value)
	if value == nil or isSecret(value) then return nil end
	return tonumber(value)
end

local function formatFull(value)
	if isSecret(value) then
		if AbbreviateNumbers then return AbbreviateNumbers(value) end
		if AbbreviateLargeNumbers then return AbbreviateLargeNumbers(value) end
		return ""
	end
	value = tonumber(value) or 0
	return BreakUpLargeNumbers and BreakUpLargeNumbers(math.floor(value + 0.5)) or tostring(math.floor(value + 0.5))
end

local function copyShortNumberAbbrevBreakpoints(data)
	if type(data) ~= "table" then return nil end
	local breakpoints = {}
	for _, breakpoint in ipairs(data) do
		if type(breakpoint) == "table" then
			local significandDivisor = breakpoint.significandDivisor
			local fractionDivisor = breakpoint.fractionDivisor
			local order = significandDivisor and fractionDivisor and significandDivisor * fractionDivisor
			if order == 1000000 then
				fractionDivisor = 100
				significandDivisor = 10000
			end
			breakpoints[#breakpoints + 1] = {
				breakpoint = breakpoint.breakpoint,
				abbreviation = breakpoint.abbreviation,
				significandDivisor = significandDivisor,
				fractionDivisor = fractionDivisor,
				abbreviationIsGlobal = breakpoint.abbreviationIsGlobal ~= false,
			}
		end
	end
	if #breakpoints == 0 then return nil end
	breakpoints[#breakpoints + 1] = LOW_NUMBER_ABBREV_BREAKPOINT
	return breakpoints
end

local function getShortNumberAbbrevOptions()
	if not shortNumberAbbrevOptions then
		local breakpoints = C_StringUtil and C_StringUtil.GetDefaultAbbreviationBreakpoints and copyShortNumberAbbrevBreakpoints(C_StringUtil.GetDefaultAbbreviationBreakpoints())
		breakpoints = breakpoints or FALLBACK_SHORT_NUMBER_ABBREV_BREAKPOINTS
		shortNumberAbbrevOptions = { breakpointData = breakpoints }
		if CreateAbbreviateConfig then
			shortNumberAbbrevOptions.config = CreateAbbreviateConfig(breakpoints)
		end
	end
	return shortNumberAbbrevOptions
end

local function formatShort(value)
	if value == nil then return "0" end
	if not isSecret(value) then
		local numeric = tonumber(value) or 0
		if numeric < 1000 then return tostring(math.floor(numeric + 0.5)) end
	end
	if AbbreviateNumbers then return AbbreviateNumbers(value, getShortNumberAbbrevOptions()) end
	if isSecret(value) then
		if AbbreviateLargeNumbers then return AbbreviateLargeNumbers(value) end
		return ""
	end
	value = tonumber(value) or 0
	if AbbreviateLargeNumbers then return AbbreviateLargeNumbers(value) end
	if value >= 1000000000 then return string.format("%.1fb", value / 1000000000) end
	if value >= 1000000 then return string.format("%.1fm", value / 1000000) end
	if value >= 1000 then return string.format("%.1fk", value / 1000) end
	return tostring(math.floor(value + 0.5))
end

local function formatNumber(value, mode)
	if mode == "none" then return formatFull(value) end
	return formatShort(value)
end

local function formatDuration(seconds, mode)
	seconds = safeNumber(seconds)
	if not seconds then return nil end
	seconds = math.floor(seconds + 0.5)
	if mode == "seconds" then
		return tostring(seconds) .. "s"
	end
	if mode == "clock" then
		return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
	end
	if seconds >= 60 then
		return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
	end
	return tostring(seconds) .. "s"
end

local function formatHistoryDuration(seconds)
	seconds = safeNumber(seconds)
	if not seconds then return nil end
	seconds = math.floor(seconds + 0.5)
	if SecondsToClock then return SecondsToClock(seconds) end
	if seconds >= 60 then return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60) end
	return tostring(seconds) .. "s"
end

local function buildHeaderFormatOptions()
	return {
		{ value = "timeTypeDash", label = L["damageMeterHeaderFormatTimeTypeDash"] or "<combat time> - <type>" },
		{ value = "timeTypeSpace", label = L["damageMeterHeaderFormatTimeTypeSpace"] or "<combat time> <type>" },
		{ value = "typeTimeDash", label = L["damageMeterHeaderFormatTypeTimeDash"] or "<type> - <combat time>" },
		{ value = "typeTimeSpace", label = L["damageMeterHeaderFormatTypeTimeSpace"] or "<type> <combat time>" },
	}
end

local function buildHeaderTimeFormatOptions()
	return {
		{ value = "smart", label = L["damageMeterHeaderTimeFormatSmart"] or "1:05 after 60s" },
		{ value = "clock", label = L["damageMeterHeaderTimeFormatClock"] or "1:05" },
		{ value = "seconds", label = L["damageMeterHeaderTimeFormatSeconds"] or "65s" },
	}
end

local function normalizeHeaderFormat(value)
	if value == "timeTypeSpace" or value == "typeTimeDash" or value == "typeTimeSpace" then return value end
	return "timeTypeDash"
end

local function normalizeHeaderTimeFormat(value)
	if value == "clock" then return "clock" end
	return value == "seconds" and "seconds" or "smart"
end

local function normalizeValueMode(value)
	if value == "both" or value == "total" or value == "rate" then return value end
	return "auto"
end

local function normalizeValueLayout(value)
	return value == "combined" and "combined" or "columns"
end

local function buildValueModeOptions()
	return {
		{ value = "auto", label = L["damageMeterValueModeAuto"] or "Automatic" },
		{ value = "both", label = L["damageMeterValueModeBoth"] or "Total and rate" },
		{ value = "total", label = L["damageMeterValueModeTotal"] or "Total only" },
		{ value = "rate", label = L["damageMeterValueModeRate"] or "Rate only" },
	}
end

local function buildValueLayoutOptions()
	return {
		{ value = "columns", label = L["damageMeterValueLayoutColumns"] or "Columns" },
		{ value = "combined", label = L["damageMeterValueLayoutCombined"] or "Combined" },
	}
end

local VALUE_SEPARATORS = {
	[" "] = true,
	["  "] = true,
	["/"] = true,
	[":"] = true,
	["-"] = true,
	["–"] = true,
	["|"] = true,
	["•"] = true,
	["·"] = true,
}

local function normalizeValueSeparator(value)
	return VALUE_SEPARATORS[value] and value or DEFAULT_WINDOW.valueSeparator
end

local function buildValueSeparatorOptions()
	return {
		{ value = " ", label = L["Space"] or "Space" },
		{ value = "  ", label = L["Double Space"] or "Double space" },
		{ value = "/", label = "/" },
		{ value = ":", label = ":" },
		{ value = "-", label = "-" },
		{ value = "–", label = "–" },
		{ value = "|", label = "|" },
		{ value = "•", label = "•" },
		{ value = "·", label = "·" },
	}
end

local function joinValueText(leftText, rightText, separator)
	separator = normalizeValueSeparator(separator)
	if separator == " " or separator == "  " then
		return leftText .. separator .. rightText
	end
	return leftText .. " " .. separator .. " " .. rightText
end

local function formatSourceName(value, config)
	if config.hideRealmNames ~= false and Ambiguate and value ~= nil then
		return Ambiguate(value, "short")
	end
	if value == nil then return L["Unknown"] or UNKNOWN or "Unknown" end
	return value
end

local function formatDisplayName(source, config)
	local name = formatSourceName(source and source.name, config)
	if isSecret(name) then return name end
	return name
end

function DamageMeter:TruncateNameWithoutEllipsis(name, fontString, config)
	if config.nameNoEllipsis ~= true or isSecret(name) then return name end
	if type(name) ~= "string" or name == "" or not fontString then return name end
	local width = tonumber(fontString._damageMeterNameLayoutWidth) or 0
	if width <= 0 then return name end
	local fontSize = clampNumber(config.fontSize, 8, 24, DEFAULT_WINDOW.fontSize)
	local maxChars = math.floor(width / math.max(1, fontSize * 0.58))
	if maxChars <= 0 then return "" end
	local pos = 1
	local count = 0
	for char in name:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		count = count + 1
		if count > maxChars then return name:sub(1, pos - 1) end
		pos = pos + #char
	end
	return name
end

local function isPerSecondMeterType(key)
	key = normalizeDamageMeterTypeKey(key)
	return key == "Dps" or key == "Hps"
end

local function isCountOnlyMeterType(key)
	key = normalizeDamageMeterTypeKey(key)
	return key == "Dispels" or key == "Interrupts"
end

local function getRowValueMode(damageMeterType, config)
	if damageMeterType == "Deaths" then return "death" end
	if damageMeterType == "Threat" then return "threat" end
	if damageMeterType == "Dispels" or damageMeterType == "Interrupts" then return "count" end
	local valueMode = normalizeValueMode(config and config.valueMode)
	if valueMode == "both" then return "amountAndRate" end
	if valueMode == "total" then return "amount" end
	if valueMode == "rate" then return "perSecond" end
	if damageMeterType == "Dps" or damageMeterType == "Hps" then return "perSecond" end
	return "amountAndRate"
end

local function useRaidRows(config)
	return config.raidRowsEnabled == true and IsInRaid and IsInRaid() == true
end

local function getEffectiveVisibleRows(config)
	if useRaidRows(config) then
		return clampNumber(config.raidVisibleRows, 1, 30, DEFAULT_WINDOW.raidVisibleRows)
	end
	return clampNumber(config.visibleRows, 1, 30, DEFAULT_WINDOW.visibleRows)
end

local function formatDeathTimeText(source)
	local rawDeathTimeSeconds = source and source.deathTimeSeconds
	if isSecret(rawDeathTimeSeconds) then return tostring(rawDeathTimeSeconds) end
	local deathTimeSeconds = safeNumber(rawDeathTimeSeconds)
	if not deathTimeSeconds or deathTimeSeconds == -1 then return "" end
	return formatDuration(deathTimeSeconds, "clock") or ""
end

local function appendRowPercent(text, percent, showPercent)
	if showPercent and percent then
		return string.format("%s (%.1f%%)", text, percent)
	end
	return text
end

local function formatDeathRowValueText(source)
	return formatDeathTimeText(source)
end

local function formatCountRowValueText(source, percent, abbreviation, showPercent)
	return appendRowPercent(formatNumber(source.totalAmount, abbreviation), percent, showPercent)
end

local function formatPerSecondRowValueText(source, percent, abbreviation, showPercent)
	return appendRowPercent(formatNumber(source.amountPerSecond, abbreviation), percent, showPercent)
end

local function formatAmountRowValueText(source, percent, abbreviation, showPercent)
	return appendRowPercent(formatNumber(source.totalAmount, abbreviation), percent, showPercent)
end

local function formatAmountRateRowValueText(source, percent, abbreviation, showPercent, useParentheses, separator)
	local amountText = formatNumber(source.totalAmount, abbreviation)
	local dpsText = formatNumber(source.amountPerSecond, abbreviation)
	local text = useParentheses and (amountText .. " (" .. dpsText .. ")") or joinValueText(amountText, dpsText, separator)
	return appendRowPercent(text, percent, showPercent)
end

local ROW_VALUE_FORMATTERS = {
	amount = formatAmountRowValueText,
	amountAndRate = formatAmountRateRowValueText,
	count = formatCountRowValueText,
	death = formatDeathRowValueText,
	perSecond = formatPerSecondRowValueText,
	threat = function(source)
		local value = safeNumber(source and source.totalAmount)
		if not value then return "" end
		return string.format("%.1f%%", value)
	end,
}

local function getRowValueColumnVisibility(damageMeterType, config)
	local mode = getRowValueMode(damageMeterType, config)
	local showAmount = mode == "amount" or mode == "amountAndRate" or mode == "count" or mode == "death" or mode == "threat"
	local showRate = mode == "perSecond" or mode == "amountAndRate"
	local showPercent = mode ~= "threat" and config.showPercent ~= false
	return showAmount, showRate, showPercent, mode
end

local function formatRowValueColumnTexts(source, percent, damageMeterType, config)
	local showAmount, showRate, showPercent, mode = getRowValueColumnVisibility(damageMeterType, config)
	local abbreviation = config.abbreviation
	local amountText
	local rateText
	if mode == "death" then
		amountText = formatDeathTimeText(source)
	elseif mode == "threat" then
		local value = safeNumber(source and source.totalAmount)
		amountText = value and string.format("%.1f%%", value) or ""
	elseif mode == "count" or mode == "amount" then
		amountText = formatNumber(source.totalAmount, abbreviation)
	elseif mode == "perSecond" then
		rateText = formatNumber(source.amountPerSecond, abbreviation)
	else
		amountText = formatNumber(source.totalAmount, abbreviation)
		rateText = formatNumber(source.amountPerSecond, abbreviation)
	end
	return showAmount and amountText or "", showRate and rateText or "", showPercent and percent and string.format("%.1f%%", percent) or "", showAmount, showRate, showPercent
end

local function isReportFieldSafe(value)
	return value ~= nil and not isSecret(value)
end

local function getReportValueMode(damageMeterType, config)
	return getRowValueMode(damageMeterType, config)
end

local function isSourceReportable(source, damageMeterType, config, requirePercent)
	if not source or isSecret(source.name) then return false end
	local valueMode = getReportValueMode(damageMeterType, config)
	if valueMode == "death" then
		return isReportFieldSafe(source.deathTimeSeconds)
	end
	if valueMode == "perSecond" then
		return isReportFieldSafe(source.amountPerSecond)
	end
	if valueMode == "amountAndRate" then
		return isReportFieldSafe(source.totalAmount) and isReportFieldSafe(source.amountPerSecond)
	end
	if requirePercent then
		return isReportFieldSafe(source.totalAmount)
	end
	return isReportFieldSafe(source.totalAmount)
end

local function getReportChannelLabel(chatType)
	if chatType == "SAY" then return _G.SAY or "Say" end
	if chatType == "PARTY" then return _G.PARTY or "Party" end
	if chatType == "RAID" then return _G.RAID or "Raid" end
	if chatType == "INSTANCE_CHAT" then return _G.INSTANCE_CHAT or "Instance" end
	if chatType == "GUILD" then return _G.GUILD or "Guild" end
	if chatType == "WHISPER" then return _G.WHISPER or "Whisper" end
	return chatType
end

local function sanitizeReportChatMessage(message)
	message = tostring(message or "")
	message = message:gsub("|", "||")
	if #message <= 255 then return message end
	message = message:sub(1, 252)
	while message:sub(-1) == "|" do
		message = message:sub(1, -2)
	end
	return message .. "..."
end

local REPORT_CHANNELS = {
	{ chatType = "SAY" },
	{ chatType = "PARTY" },
	{ chatType = "RAID" },
	{ chatType = "INSTANCE_CHAT" },
	{ chatType = "GUILD" },
	{ chatType = "WHISPER" },
}

local function getRestrictionTypes()
	local restrictionTypes = Enum and Enum.AddOnRestrictionType
	if not restrictionTypes then return nil end
	return {
		restrictionTypes.Combat,
		restrictionTypes.Encounter,
		restrictionTypes.ChallengeMode,
		restrictionTypes.PvPMatch,
		restrictionTypes.Map,
		restrictionTypes.Chat,
	}
end

local function isInFollowerDungeon()
	if C_LFGInfo and C_LFGInfo.IsInLFGFollowerDungeon then
		if C_LFGInfo.IsInLFGFollowerDungeon() == true then return true end
	end
	local _, instanceType, difficultyID = GetInstanceInfo()
	return instanceType == "party" and difficultyID == 205
end

local trimTextureInput

local function applyClassIcon(texture, classFilename, classTexture, classCoordLayout)
	if type(classFilename) ~= "string" or classFilename == "" or not CLASS_ICON_TCOORDS or not CLASS_ICON_TCOORDS[classFilename] then return false end
	classTexture = classTexture or CLASS_ICON_TEXTURE
	if texture._damageMeterIconKind == "class" and texture._damageMeterIconValue == classFilename and texture._damageMeterIconTexture == classTexture and texture._damageMeterIconCoordLayout == classCoordLayout then return true end
	texture._damageMeterIconKind = "class"
	texture._damageMeterIconValue = classFilename
	texture._damageMeterIconTexture = classTexture
	texture._damageMeterIconCoordLayout = classCoordLayout
	local coords = classCoordLayout == "generic" and DamageMeter.GENERIC_CLASS_ICON_TCOORDS[classFilename] or CLASS_ICON_TCOORDS[classFilename]
	if not coords then coords = CLASS_ICON_TCOORDS[classFilename] end
	texture:SetTexture(classTexture)
	texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
	return true
end

local function applyAtlasIcon(texture, atlas)
	if not atlas or not texture.SetAtlas then return false end
	if texture._damageMeterIconKind == "atlas" and texture._damageMeterIconValue == atlas then return true end
	texture._damageMeterIconKind = "atlas"
	texture._damageMeterIconValue = atlas
	texture._damageMeterIconTexture = nil
	texture._damageMeterIconCoordLayout = nil
	texture:SetTexCoord(0, 1, 0, 1)
	texture:SetAtlas(atlas, false)
	return true
end

function DamageMeter.ApplySpecIcon(texture, specIconID)
	if not specIconID or specIconID == 0 then return false end
	if texture._damageMeterIconKind == "spec" and texture._damageMeterIconValue == specIconID then return true end
	texture._damageMeterIconKind = "spec"
	texture._damageMeterIconValue = specIconID
	texture._damageMeterIconTexture = nil
	texture._damageMeterIconCoordLayout = nil
	texture:SetTexture(specIconID)
	texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	return true
end

function DamageMeter.ApplyFallbackIcon(texture)
	if texture._damageMeterIconKind ~= "fallback" then
		texture._damageMeterIconKind = "fallback"
		texture._damageMeterIconValue = 136243
		texture._damageMeterIconTexture = nil
		texture._damageMeterIconCoordLayout = nil
		texture:SetTexture(136243)
		texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	end
end

local function applySourceIcon(texture, source, inFollowerDungeon, damageMeterType, config)
	if damageMeterType == "EnemyDamageTaken" and applyAtlasIcon(texture, TOOLTIP_TARGET_ATLAS) then
		return
	end
	local useSpecIcon = config and config.iconType == "spec"
	local customClassTexture = not useSpecIcon and config and config.iconUseCustomClassTexture == true and trimTextureInput(config.iconCustomClassTexture)
	local classTexture = customClassTexture and customClassTexture ~= "" and customClassTexture or CLASS_ICON_TEXTURE
	classTexture = tonumber(classTexture) or classTexture
	local classCoordLayout = customClassTexture and customClassTexture ~= "" and "generic" or "blizzard"
	if not useSpecIcon then
		if inFollowerDungeon and source.isLocalPlayer ~= true and applyClassIcon(texture, source.classFilename, classTexture, classCoordLayout) then
			return
		end
		if applyClassIcon(texture, source.classFilename, classTexture, classCoordLayout) then return end
		if DamageMeter.ApplySpecIcon(texture, source.specIconID) then return end
		DamageMeter.ApplyFallbackIcon(texture)
		return
	end
	if DamageMeter.ApplySpecIcon(texture, source.specIconID) then return end
	if applyClassIcon(texture, source.classFilename, classTexture, classCoordLayout) then return end
	DamageMeter.ApplyFallbackIcon(texture)
end

local function normalizeColor(value, fallback)
	fallback = fallback or DEFAULT_WINDOW.backdropColor
	if type(value) ~= "table" then value = fallback end
	return {
		r = clampNumber(value.r or value[1], 0, 1, fallback.r or fallback[1] or 0),
		g = clampNumber(value.g or value[2], 0, 1, fallback.g or fallback[2] or 0),
		b = clampNumber(value.b or value[3], 0, 1, fallback.b or fallback[3] or 0),
		a = clampNumber(value.a or value[4], 0, 1, fallback.a or fallback[4] or 1),
	}
end

local function colorComponents(value, fallback)
	fallback = fallback or DEFAULT_WINDOW.backdropColor
	if type(value) ~= "table" then value = fallback end
	return clampNumber(value.r or value[1], 0, 1, fallback.r or fallback[1] or 0),
		clampNumber(value.g or value[2], 0, 1, fallback.g or fallback[2] or 0),
		clampNumber(value.b or value[3], 0, 1, fallback.b or fallback[3] or 0),
		clampNumber(value.a or value[4], 0, 1, fallback.a or fallback[4] or 1)
end

local function colorToHex(color, fallback)
	local r, g, b, a = colorComponents(color, fallback)
	return string.format("%02x%02x%02x%02x", math.floor((a * 255) + 0.5), math.floor((r * 255) + 0.5), math.floor((g * 255) + 0.5), math.floor((b * 255) + 0.5))
end

local function setStatusBarValue(bar, value, smooth)
	if smooth and INTERP_EASE then
		bar:SetValue(value, INTERP_EASE)
	else
		bar:SetValue(value)
	end
end

local function getGlobalFontStateVersion()
	if addon.functions and addon.functions.GetGlobalFontStateVersion then return addon.functions.GetGlobalFontStateVersion() or 0 end
	return 0
end

local function setShownIfChanged(region, shown)
	shown = shown == true
	if region:IsShown() ~= shown then region:SetShown(shown) end
end

local function setTextColorIfChanged(fontString, r, g, b, a)
	a = a == nil and 1 or a
	if fontString._damageMeterTextColorR == r
		and fontString._damageMeterTextColorG == g
		and fontString._damageMeterTextColorB == b
		and fontString._damageMeterTextColorA == a then
		return
	end
	fontString._damageMeterTextColorR = r
	fontString._damageMeterTextColorG = g
	fontString._damageMeterTextColorB = b
	fontString._damageMeterTextColorA = a
	fontString:SetTextColor(r, g, b, a)
end

local function setPlainTextIfChanged(fontString, text)
	text = text or ""
	if fontString._damageMeterPlainText == text then return end
	fontString._damageMeterPlainText = text
	fontString:SetText(text)
end

local function formatAlphaSliderValue(value)
	return string.format("%.2f", tonumber(value) or 0)
end

local function getRowMetrics(config)
	local rowHeight = clampNumber(config.rowHeight, 10, 70, DEFAULT_WINDOW.rowHeight)
	local barHeight = config.changeBarSize == true and math.min(rowHeight, clampNumber(config.barHeight, 1, rowHeight, DEFAULT_WINDOW.barHeight)) or rowHeight
	local spacing = clampNumber(config.barSpacing, -16, 16, DEFAULT_WINDOW.barSpacing)
	return rowHeight, barHeight, spacing
end

local function getIconBorderOutset(config)
	if config.showIcons == false or config.iconBorderEnabled ~= true then return 0 end
	return clampNumber(config.iconBorderInset, 0, 24, DEFAULT_WINDOW.iconBorderInset)
end

local function getEffectiveRowHeight(config)
	local rowHeight = getRowMetrics(config)
	return rowHeight + (getIconBorderOutset(config) * 2)
end

local function getIconSize(config)
	if config.showIcons == false then return 0 end
	local maxSize = math.max(8, getEffectiveRowHeight(config) - (getIconBorderOutset(config) * 2))
	if config.changeIconSize ~= true then return maxSize end
	local offset = clampNumber(config.iconSizeOffset, -60, 0, DEFAULT_WINDOW.iconSizeOffset)
	return clampNumber(maxSize + offset, 8, maxSize, maxSize)
end

local function clearArray(array)
	if not array then return end
	for index = #array, 1, -1 do
		array[index] = nil
	end
end

local function findLocalPlayerSourceIndex(orderedSources)
	for sourceIndex, source in ipairs(orderedSources) do
		if source and source.isLocalPlayer == true then
			return sourceIndex
		end
	end
	return nil
end

local function getScrollViewportVisualRange(frame, config, contentRows)
	contentRows = math.max(0, tonumber(contentRows) or 0)
	if contentRows <= 0 then return 1, 0 end

	local visibleRows = math.min(getEffectiveVisibleRows(config), contentRows)
	if visibleRows <= 0 then return 1, 0 end

	local _, _, spacing = getRowMetrics(config)
	local rowPitch = getEffectiveRowHeight(config) + spacing
	if rowPitch <= 0 then rowPitch = 1 end

	local scroll = 0
	if frame and frame.rowsViewport then
		scroll = frame.rowsViewport:GetVerticalScroll() or 0
	end
	if scroll < 0 then scroll = 0 end

	local maxStart = math.max(1, contentRows - visibleRows + 1)
	local viewportStart = math.floor((scroll / rowPitch) + 0.0001) + 1
	viewportStart = clampNumber(viewportStart, 1, maxStart, 1)
	local viewportEnd = math.min(contentRows, viewportStart + visibleRows - 1)
	return viewportStart, viewportEnd
end

local function sourceIndexToVisualIndex(sourceIndex, contentRows, highestBottom)
	if highestBottom then
		return contentRows - sourceIndex + 1
	end
	return sourceIndex
end

local function visualIndexToEntryIndex(visualIndex, contentRows, highestBottom)
	if highestBottom then
		return contentRows - visualIndex + 1
	end
	return visualIndex
end

local function buildViewportAwareDisplayIndices(frame, config, contentRows, playerSourceIndex, highestBottom)
	local displayIndices = frame and frame._damageMeterDisplayIndices
	if config.alwaysShowPlayer ~= true or not playerSourceIndex or contentRows <= 0 then
		clearArray(displayIndices)
		return nil
	end

	local viewportStart, viewportEnd = getScrollViewportVisualRange(frame, config, contentRows)
	if viewportEnd < viewportStart then
		clearArray(displayIndices)
		return nil
	end

	local playerVisualIndex = sourceIndexToVisualIndex(playerSourceIndex, contentRows, highestBottom)
	local injectVisualIndex
	if playerVisualIndex < viewportStart then
		injectVisualIndex = viewportStart
	elseif playerVisualIndex > viewportEnd then
		injectVisualIndex = viewportEnd
	else
		clearArray(displayIndices)
		return nil
	end

	local injectEntryIndex = visualIndexToEntryIndex(injectVisualIndex, contentRows, highestBottom)
	injectEntryIndex = clampNumber(injectEntryIndex, 1, contentRows, contentRows)
	if not displayIndices then
		displayIndices = {}
		frame._damageMeterDisplayIndices = displayIndices
	else
		clearArray(displayIndices)
	end

	local writeIndex = 1
	for sourceIndex = 1, contentRows do
		if writeIndex == injectEntryIndex then
			displayIndices[writeIndex] = playerSourceIndex
			writeIndex = writeIndex + 1
		end
		if sourceIndex ~= playerSourceIndex then
			if writeIndex <= contentRows then
				displayIndices[writeIndex] = sourceIndex
			end
			writeIndex = writeIndex + 1
		end
	end
	if writeIndex == injectEntryIndex and writeIndex <= contentRows then
		displayIndices[writeIndex] = playerSourceIndex
	end

	return displayIndices
end

local function getIconGap(config)
	return clampNumber(config.iconGap, 0, 24, DEFAULT_WINDOW.iconGap)
end

local function getRankGap(config)
	return clampNumber(config.rankGap, -50, 50, DEFAULT_WINDOW.rankGap)
end

local function getEffectiveRankWidth(config)
	if config.showRanks == false then return 0 end
	local rankChars = 3
	if config.prefixRankInName == true then
		local fontSize = clampNumber(config.fontSize, 8, 24, DEFAULT_WINDOW.fontSize)
		return math.min(80, math.max(8, math.ceil(rankChars * fontSize * 0.62) + 2))
	end
	local rankFontSize = clampNumber(config.rankFontSize, 8, 24, DEFAULT_WINDOW.rankFontSize)
	return math.min(80, math.max(18, math.ceil(rankChars * rankFontSize * 0.9) + 6))
end

local function useTextRankPrefix(config)
	return config.showRanks ~= false and config.prefixRankInName == true
end

local function getRowTextInsets(config, forceRankColumn)
	local rankWidth = getEffectiveRankWidth(config)
	local rankGap = getRankGap(config)
	local iconSize = getIconSize(config)
	local iconGap = getIconGap(config)
	local leftInset = 4
	if iconSize > 0 then
		leftInset = leftInset + iconSize + iconGap
	end
	if rankWidth > 0 and not useTextRankPrefix(config) then
		leftInset = leftInset + math.max(0, rankWidth + rankGap)
	end
	return leftInset, 4, iconSize, rankWidth, rankGap
end

local function normalizeAnchorH(value)
	return (value == "CENTER" or value == "RIGHT") and value or "LEFT"
end

local function normalizeAnchorV(value)
	return (value == "TOP" or value == "BOTTOM") and value or "CENTER"
end

local function normalizeTooltipAnchor(value)
	if value == "LEFT" or value == "TOP" or value == "BOTTOM" then return value end
	return "RIGHT"
end

local function normalizeTooltipGrow(value)
	return value == "UP" and "UP" or "DOWN"
end

local function normalizeHeaderPosition(value)
	return value == "BOTTOM" and "BOTTOM" or "TOP"
end

local function normalizeRowGrowth(value)
	return value == "UP" and "UP" or "DOWN"
end

local function normalizeRowSort(value)
	return value == "BOTTOM" and "BOTTOM" or "TOP"
end

local function anchorPoint(horizontal, vertical)
	horizontal = normalizeAnchorH(horizontal)
	vertical = normalizeAnchorV(vertical)
	if vertical == "CENTER" then return horizontal end
	if horizontal == "CENTER" then return vertical end
	return vertical .. horizontal
end

local function justifyFromAnchor(horizontal)
	horizontal = normalizeAnchorH(horizontal)
	if horizontal == "RIGHT" then return "RIGHT" end
	if horizontal == "CENTER" then return "CENTER" end
	return "LEFT"
end

local function getRowValueLayout(config)
	return normalizeValueLayout(config.valueLayout)
end

local function getUpdateRate()
	return clampNumber(db().damageMeterUpdateRate, 0.1, 5, 0.1)
end

local function normalizeAutoClearMode(value)
	if value == "ask" or value == "always" then return value end
	return "never"
end

local function normalizeAutoClearInstances(value)
	local normalized = {}
	if type(value) ~= "table" then
		normalized.party = true
		normalized.raid = true
		return normalized
	end
	if value.party == true then normalized.party = true end
	if value.raid == true then normalized.raid = true end
	if value.raidEncounter == true then normalized.raidEncounter = true end
	return normalized
end

local function buildAutoClearOptions()
	return {
		{ value = "never", label = L["damageMeterAutomaticClearNever"] or "Never" },
		{ value = "ask", label = L["damageMeterAutomaticClearAsk"] or "Ask" },
		{ value = "always", label = L["damageMeterAutomaticClearAlways"] or "Always" },
	}
end

local function buildAutoClearInstanceOptions()
	return {
		{ value = "party", text = L["Dungeon"] or "Dungeon" },
		{ value = "raid", text = L["Raid"] or "Raid" },
		{ value = "raidEncounter", text = L["damageMeterAutomaticClearRaidEncounterStart"] or "Raid encounter start" },
	}
end

function getWindowCount()
	return clampNumber(db().damageMeterWindowCount, 1, MAX_WINDOWS, 1)
end

local function setWindowCount(value)
	db().damageMeterWindowCount = clampNumber(value, 1, MAX_WINDOWS, 1)
end

function DamageMeter:GetWindowsDB()
	local profile = db()
	if type(profile.damageMeterWindows) ~= "table" then profile.damageMeterWindows = {} end
	if self.normalizedWindowsDB == profile.damageMeterWindows then return profile.damageMeterWindows end
	for index = 1, MAX_WINDOWS do
		if type(profile.damageMeterWindows[index]) ~= "table" then profile.damageMeterWindows[index] = {} end
		applyWindowDefaults(profile.damageMeterWindows[index], index)
	end
	self.normalizedWindowsDB = profile.damageMeterWindows
	return profile.damageMeterWindows
end

function DamageMeter:GetConfig(index)
	return self:GetWindowsDB()[index]
end

function DamageMeter:GetRowViewportPadding(config)
	local padding = 0
	if config.barBorderEnabled == true then
		padding = math.max(padding, clampNumber(config.barBorderInset, 0, 24, DEFAULT_WINDOW.barBorderInset))
	end
	if config.rowBorderEnabled == true then
		padding = math.max(padding, clampNumber(config.rowBorderInset, 0, 24, DEFAULT_WINDOW.rowBorderInset))
	end
	return padding
end

function DamageMeter:GetWindowStyleVersion(index)
	self.windowStyleVersions = self.windowStyleVersions or {}
	return self.windowStyleVersions[index] or 0
end

function DamageMeter:InvalidateLiveEventWatch()
	self.liveEventWatchDirty = true
end

function DamageMeter:MarkWindowStyleDirty(index)
	self.windowStyleVersions = self.windowStyleVersions or {}
	if index then
		self.windowStyleVersions[index] = (self.windowStyleVersions[index] or 0) + 1
		return
	end
	for windowIndex = 1, MAX_WINDOWS do
		self.windowStyleVersions[windowIndex] = (self.windowStyleVersions[windowIndex] or 0) + 1
	end
end

function DamageMeter:GetTemporarySelection(index)
	self.temporarySelections = self.temporarySelections or {}
	if type(self.temporarySelections[index]) ~= "table" then self.temporarySelections[index] = {} end
	return self.temporarySelections[index]
end

function DamageMeter:GetRoleSpecificDamageMeterType(config)
	if not config or config.roleSpecificType ~= true then return nil end
	local role = addon.variables.unitRole
	if role == "TANK" then return config.tankDamageMeterType end
	if role == "HEALER" then return config.healerDamageMeterType end
	if role == "DAMAGER" then return config.damagerDamageMeterType end
	return nil
end

function DamageMeter:GetEffectiveDamageMeterType(index)
	local temporary = self:GetTemporarySelection(index)
	local config = self:GetConfig(index)
	if config.keepManualType == true then
		return normalizeDamageMeterTypeKey(config.damageMeterType)
	end
	return normalizeDamageMeterTypeKey(self:GetRoleSpecificDamageMeterType(config) or temporary.damageMeterType or config.damageMeterType)
end

function DamageMeter:GetQuickDamageMeterTypes(index)
	local config = self:GetConfig(index)
	if config.quickTypes == DEFAULT_WINDOW.quickTypes then
		config.quickTypes = copyValue(DEFAULT_WINDOW.quickTypes)
	end
	if type(config.quickTypes) ~= "table" or #config.quickTypes == 0 then return normalizeWindowQuickTypes(config) end
	return config.quickTypes
end

function DamageMeter:GetQuickDamageMeterTypeLabels(index, fallbackLabel)
	self.quickTypeLabelCache = self.quickTypeLabelCache or {}
	local quickTypes = self:GetQuickDamageMeterTypes(index)
	local cache = self.quickTypeLabelCache[index]
	if cache and cache.quickTypes == quickTypes and cache.fallbackLabel == fallbackLabel then return cache.text end
	local text
	for quickIndex, quickType in ipairs(quickTypes) do
		local label = getDamageMeterTypeLabel(quickType)
		text = text and (text .. " / " .. label) or label
	end
	if not text or text == "" then text = fallbackLabel or "" end
	self.quickTypeLabelCache[index] = {
		quickTypes = quickTypes,
		fallbackLabel = fallbackLabel,
		text = text,
	}
	return text
end

function DamageMeter:HasQuickDamageMeterType(index, damageMeterType)
	local key = normalizeDamageMeterTypeKey(damageMeterType)
	for _, quickType in ipairs(self:GetQuickDamageMeterTypes(index)) do
		if quickType == key then return true end
	end
	return false
end

function DamageMeter:AddQuickDamageMeterType(index, damageMeterType)
	local key = normalizeDamageMeterTypeKey(damageMeterType)
	local quickTypes = copyValue(self:GetQuickDamageMeterTypes(index))
	for _, quickType in ipairs(quickTypes) do
		if quickType == key then return end
	end
	quickTypes[#quickTypes + 1] = key
	self:SetConfigValue(index, "quickTypes", quickTypes)
end

function DamageMeter:RemoveQuickDamageMeterType(index, damageMeterType)
	local key = normalizeDamageMeterTypeKey(damageMeterType)
	local quickTypes = copyValue(self:GetQuickDamageMeterTypes(index))
	for quickIndex = #quickTypes, 1, -1 do
		if quickTypes[quickIndex] == key then
			table.remove(quickTypes, quickIndex)
		end
	end
	self:SetConfigValue(index, "quickTypes", quickTypes)
end

function DamageMeter:CycleQuickDamageMeterType(index, direction)
	local quickTypes = self:GetQuickDamageMeterTypes(index)
	if #quickTypes == 0 then return end
	local current = self:GetEffectiveDamageMeterType(index)
	local currentIndex = 1
	for quickIndex, quickType in ipairs(quickTypes) do
		if quickType == current then
			currentIndex = quickIndex
			break
		end
	end
	local nextIndex = currentIndex + (direction or 1)
	if nextIndex > #quickTypes then nextIndex = 1 end
	if nextIndex < 1 then nextIndex = #quickTypes end
	self:SetTemporaryDamageMeterType(index, quickTypes[nextIndex])
end

function DamageMeter:GetEffectiveSessionType(index)
	local temporary = self:GetTemporarySelection(index)
	if temporary.sessionID then return nil end
	return temporary.sessionType or self:GetConfig(index).sessionType
end

function DamageMeter:GetEffectiveSessionID(index)
	return self:GetTemporarySelection(index).sessionID
end

function DamageMeter:GetEffectiveSessionLabel(index)
	local temporary = self:GetTemporarySelection(index)
	if temporary.sessionID then
		local fallback = DAMAGE_METER_COMBAT_NUMBER and DAMAGE_METER_COMBAT_NUMBER:format(temporary.sessionID) or string.format("%s %d", L["damageMeterCombat"] or "Combat", temporary.sessionID)
		return safeText(temporary.sessionName, fallback)
	end
	local sessionType = self:GetEffectiveSessionType(index)
	return sessionType == "overall" and (L["damageMeterOverall"] or "Overall") or (L["damageMeterCurrent"] or "Current")
end

function DamageMeter:ForEachLinkedSessionWindow(index, callback)
	if db().damageMeterLinkSegments == true then
		for windowIndex = 1, getWindowCount() do
			callback(windowIndex)
		end
	else
		callback(index)
	end
end

function DamageMeter:SetTemporaryDamageMeterType(index, damageMeterType)
	local config = self:GetConfig(index)
	local normalizedType = normalizeDamageMeterTypeKey(damageMeterType)
	if config.keepManualType == true then
		local temporary = self:GetTemporarySelection(index)
		temporary.damageMeterType = nil
		self:SetConfigValue(index, "damageMeterType", normalizedType)
		return
	end

	local temporary = self:GetTemporarySelection(index)
	temporary.damageMeterType = normalizedType
	self:InvalidateLiveEventWatch()
	self:ScheduleRefresh()
end

function DamageMeter:SetKeepManualDamageMeterType(index, enabled)
	local config = self:GetConfig(index)
	enabled = enabled == true
	local currentType = normalizeDamageMeterTypeKey(self:GetEffectiveDamageMeterType(index))
	local changed = config.keepManualType ~= enabled
	config.keepManualType = enabled

	if enabled then
		if config.damageMeterType ~= currentType then
			config.damageMeterType = currentType
			changed = true
		end
		if config.roleSpecificType ~= false then
			config.roleSpecificType = false
			changed = true
		end
		local temporary = self:GetTemporarySelection(index)
		if temporary.damageMeterType ~= nil then
			temporary.damageMeterType = nil
			changed = true
		end
	end

	if not changed then return end
	self:InvalidateLiveEventWatch()
	self:UpdateEventState()
	self:MarkWindowStyleDirty(index)
	self:RefreshWindow(index)
end

function DamageMeter:GetAvailableCombatSessions()
	if not C_DamageMeter or not C_DamageMeter.GetAvailableCombatSessions then return {} end
	local sessions = C_DamageMeter.GetAvailableCombatSessions()
	return type(sessions) == "table" and sessions or {}
end

function DamageMeter:SetTemporarySessionType(index, sessionType)
	sessionType = sessionType == "overall" and "overall" or "current"
	self:ForEachLinkedSessionWindow(index, function(windowIndex)
		local temporary = self:GetTemporarySelection(windowIndex)
		temporary.sessionID = nil
		temporary.sessionName = nil
		temporary.sessionDurationSeconds = nil
		temporary.sessionType = sessionType
	end)
	self:InvalidateLiveEventWatch()
	self:ScheduleRefresh()
end

function DamageMeter:SetTemporarySessionID(index, sessionID, sessionName, durationSeconds)
	sessionID = tonumber(sessionID)
	if not sessionID then return end
	durationSeconds = safeNumber(durationSeconds)
	self:ForEachLinkedSessionWindow(index, function(windowIndex)
		local temporary = self:GetTemporarySelection(windowIndex)
		temporary.sessionType = nil
		temporary.sessionID = sessionID
		temporary.sessionName = sessionName
		temporary.sessionDurationSeconds = durationSeconds
	end)
	self:InvalidateLiveEventWatch()
	self:ScheduleRefresh()
end

function DamageMeter:ClearTemporarySelection(index)
	self.temporarySelections = self.temporarySelections or {}
	self.temporarySelections[index] = nil
	self:InvalidateLiveEventWatch()
	self:ScheduleRefresh()
end

function DamageMeter:IsEnabled()
	return db().damageMeterEnabled == true
end

function DamageMeter:IsWindowEnabled(index)
	return self:IsEnabled() and index <= getWindowCount()
end

function DamageMeter:IsAvailable()
	if not C_DamageMeter or not C_DamageMeter.IsDamageMeterAvailable then return false end
	return C_DamageMeter.IsDamageMeterAvailable() == true
end

function DamageMeter:SetBlizzardDamageMeterEnabled(enabled)
	local value = enabled and "1" or "0"
	if C_CVar and C_CVar.SetCVar then
		C_CVar.SetCVar(BLIZZARD_DAMAGE_METER_ENABLED_CVAR, value)
	elseif SetCVar then
		SetCVar(BLIZZARD_DAMAGE_METER_ENABLED_CVAR, value)
	end
end

function DamageMeter:SuppressBlizzardDamageMeter()
	self.blizzardDamageMeterSuppressed = true
	self:SetBlizzardDamageMeterEnabled(false)

end

function DamageMeter:IsInEditMode()
	return EditMode and EditMode.IsInEditMode and EditMode:IsInEditMode()
end

function DamageMeter:UsePreviewData()
	return self:IsInEditMode() and db().damageMeterEditModeSample ~= false
end

function DamageMeter:ShouldShow(index)
	if not self:IsWindowEnabled(index) then return false end
	if self:IsInEditMode() then return true end
	if not self:IsAvailable() then return false end
	local visibility = self:GetConfig(index).visibility
	return visibilityMatchesContext(visibility, false) or visibilityUsesMouseover(visibility) == true or self:GetWindowAlpha(index) > 0
end

function DamageMeter:GetWindowAlpha(index)
	local config = self:GetConfig(index)
	if self:IsInEditMode() then return 1 end
	if not normalizeVisibilityConfig(config.visibility) then return 1 end
	local frame = self.windows and self.windows[index]
	if visibilityMatchesContext(config.visibility, false) then return 1 end
	if visibilityUsesMouseover(config.visibility) and frame and frame._damageMeterMouseOver == true then return 1 end
	return clampNumber(config.visibilityFadeAlpha, 0, 1, DEFAULT_WINDOW.visibilityFadeAlpha)
end

function DamageMeter:UpdateWindowAlpha(index)
	local frame = self.windows and self.windows[index]
	if not frame then return end
	local alpha = self:GetWindowAlpha(index)
	if frame._damageMeterAlpha == alpha then return end
	frame._damageMeterAlpha = alpha
	frame:SetAlpha(alpha)
end

function DamageMeter:SetWindowHover(index, hovered)
	local frame = self.windows and self.windows[index]
	if not frame then return end
	if not hovered and frame.IsMouseOver and frame:IsMouseOver() then
		return
	end
	frame._damageMeterMouseOver = hovered == true
	self:UpdateWindowAlpha(index)
end

function DamageMeter:ClearWindowRows(frame)
	if not frame then return end
	if frame.rows then
		for _, row in ipairs(frame.rows) do
			row.sourceData = nil
			row:Hide()
		end
	end
	if frame.empty then frame.empty:Hide() end
end

function DamageMeter:BuildRefreshSharedState()
	local shared = self.refreshSharedState
	if not shared then
		shared = {}
		self.refreshSharedState = shared
	end
	local editMode = self:IsInEditMode()
	local preview = editMode and db().damageMeterEditModeSample ~= false
	local enabled = self:IsEnabled()
	local available = preview or (enabled and self:IsAvailable())
	shared.available = available
	shared.editMode = editMode
	shared.enabled = enabled
	shared.inFollowerDungeon = isInFollowerDungeon()
	shared.preview = preview
	shared.windowCount = getWindowCount()
	return shared
end

function DamageMeter:BuildWindowRefreshState(index, shared)
	shared = shared or self:BuildRefreshSharedState()
	self.refreshWindowStates = self.refreshWindowStates or {}
	local state = self.refreshWindowStates[index]
	if not state then
		state = {}
		self.refreshWindowStates[index] = state
	end
	local config = self:GetConfig(index)
	local temporary = self.temporarySelections and self.temporarySelections[index]
	local damageMeterType = self:GetEffectiveDamageMeterType(index)
	local damageMeterEnum = getDamageMeterTypeValue(damageMeterType)
	local sessionID = temporary and temporary.sessionID or nil
	local sessionType = sessionID and nil or ((temporary and temporary.sessionType) or config.sessionType)
	local sessionEnum = sessionType and (SESSION_TYPES[sessionType] or SESSION_TYPES.current) or nil
	local usesMouseoverVisibility = visibilityUsesMouseover(config.visibility)
	local visible = shared.enabled == true and index <= shared.windowCount
	if visible and not shared.editMode then
		visible = shared.available == true
		if visible then
			local fadeAlpha = clampNumber(config.visibilityFadeAlpha, 0, 1, DEFAULT_WINDOW.visibilityFadeAlpha)
			visible = visibilityMatchesContext(config.visibility, false) or usesMouseoverVisibility == true or fadeAlpha > 0
		end
	end
	state.available = shared.available
	state.config = config
	state.damageMeterEnum = damageMeterEnum
	state.damageMeterType = damageMeterType
	state.editMode = shared.editMode
	state.index = index
	state.inFollowerDungeon = shared.inFollowerDungeon
	state.preview = shared.preview
	state.sessionEnum = sessionEnum
	state.sessionID = sessionID
	state.sessionType = sessionType
	state.temporary = temporary
	state.usesMouseoverVisibility = usesMouseoverVisibility
	state.visible = visible
	return state
end

function DamageMeter:GetSessionForState(state, sessionCache)
	if state.preview then return PREVIEW_SESSION end
	if state.damageMeterType == "Threat" then return self:BuildThreatSession(state) end
	if not state.available or state.damageMeterEnum == nil then return nil end
	if state.sessionID and C_DamageMeter.GetCombatSessionFromID then
		if sessionCache then
			sessionCache.byID = sessionCache.byID or {}
			local typeCache = sessionCache.byID[state.damageMeterEnum]
			if not typeCache then
				typeCache = {}
				sessionCache.byID[state.damageMeterEnum] = typeCache
			end
			local cached = typeCache[state.sessionID]
			if cached ~= nil then return cached ~= false and cached or nil end
			local session = C_DamageMeter.GetCombatSessionFromID(state.sessionID, state.damageMeterEnum)
			typeCache[state.sessionID] = session or false
			return session
		end
		return C_DamageMeter.GetCombatSessionFromID(state.sessionID, state.damageMeterEnum)
	end
	if not state.sessionEnum or not C_DamageMeter.GetCombatSessionFromType then return nil end
	if sessionCache then
		sessionCache.byType = sessionCache.byType or {}
		local typeCache = sessionCache.byType[state.damageMeterEnum]
		if not typeCache then
			typeCache = {}
			sessionCache.byType[state.damageMeterEnum] = typeCache
		end
		local cached = typeCache[state.sessionEnum]
		if cached ~= nil then return cached ~= false and cached or nil end
		local session = C_DamageMeter.GetCombatSessionFromType(state.sessionEnum, state.damageMeterEnum)
		typeCache[state.sessionEnum] = session or false
		return session
	end
	return C_DamageMeter.GetCombatSessionFromType(state.sessionEnum, state.damageMeterEnum)
end

function DamageMeter:GetThreatMobUnit()
	if UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsPlayer("target") then
		return "target"
	end
	if UnitExists("targettarget") and UnitCanAttack("player", "targettarget") and not UnitIsPlayer("targettarget") then
		return "targettarget"
	end
	if UnitExists("focus") and UnitCanAttack("player", "focus") and not UnitIsPlayer("focus") then
		return "focus"
	end
	if UnitExists("focustarget") and UnitCanAttack("player", "focustarget") and not UnitIsPlayer("focustarget") then
		return "focustarget"
	end
end

function DamageMeter:AddThreatUnit(threatSession, seen, unitToken, mobToken)
	if not unitToken or not UnitExists(unitToken) then return end
	local guid = UnitGUID(unitToken)
	if guid == nil or isSecret(guid) or seen[guid] then return end
	local _, classFilename = UnitClass(unitToken)
	local isTanking, status, scaledPercent, rawPercent, rawThreat = UnitDetailedThreatSituation(unitToken, mobToken)
	if rawThreat == nil or isSecret(rawThreat) then return end
	rawThreat = tonumber(rawThreat)
	if not rawThreat then return end
	if isTanking ~= nil and isSecret(isTanking) then isTanking = false end
	seen[guid] = true
	if rawThreat > threatSession.topThreat then threatSession.topThreat = rawThreat end
	if isTanking == true then threatSession.tankThreat = rawThreat end
	if rawPercent ~= nil and isSecret(rawPercent) then rawPercent = nil end
	if scaledPercent ~= nil and isSecret(scaledPercent) then scaledPercent = nil end
	if status ~= nil and isSecret(status) then status = nil end
	local name = UnitName(unitToken)
	if name == nil or isSecret(name) then name = unitToken end
	if classFilename ~= nil and isSecret(classFilename) then classFilename = nil end
	threatSession.pending[#threatSession.pending + 1] = {
		name = name,
		classFilename = classFilename,
		guid = guid,
		isLocalPlayer = unitToken == "player",
		rawThreat = rawThreat,
		rawPercent = tonumber(rawPercent),
		scaledPercent = tonumber(scaledPercent),
		threatStatus = tonumber(status),
		isTanking = isTanking == true,
	}
end

function DamageMeter:ScanThreatGroup(threatSession, seen, mobToken)
	if IsInRaid and IsInRaid() == true then
		for unitIndex = 1, GetNumGroupMembers() do
			self:AddThreatUnit(threatSession, seen, "raid" .. unitIndex, mobToken)
			self:AddThreatUnit(threatSession, seen, "raidpet" .. unitIndex, mobToken)
		end
	else
		for unitIndex = 1, GetNumSubgroupMembers() do
			self:AddThreatUnit(threatSession, seen, "party" .. unitIndex, mobToken)
			self:AddThreatUnit(threatSession, seen, "partypet" .. unitIndex, mobToken)
		end
	end
	self:AddThreatUnit(threatSession, seen, "player", mobToken)
	self:AddThreatUnit(threatSession, seen, "pet", mobToken)
end

function DamageMeter:BuildThreatSession(state)
	if not state or state.preview then return PREVIEW_SESSION end
	if not UnitDetailedThreatSituation then return nil end
	local mobToken = self:GetThreatMobUnit()
	if not mobToken then return nil end
	local threatSession = {
		combatSources = {},
		durationSeconds = 0,
		maxAmount = 1,
		pending = {},
		tankThreat = nil,
		topThreat = 0,
		totalAmount = 100,
	}
	self:ScanThreatGroup(threatSession, {}, mobToken)
	local tankThreat = threatSession.tankThreat or threatSession.topThreat
	if not tankThreat or tankThreat <= 0 or #threatSession.pending == 0 then return nil end
	table.sort(threatSession.pending, function(left, right)
		return (left.rawThreat or 0) > (right.rawThreat or 0)
	end)
	local maxPercent = 1
	for sourceIndex, source in ipairs(threatSession.pending) do
		local threatPercent = source.rawThreat / tankThreat * 100
		if threatPercent > maxPercent then maxPercent = threatPercent end
		source.totalAmount = threatPercent
		source.amountPerSecond = source.rawThreat
		source.sourceGUID = source.guid
		threatSession.combatSources[sourceIndex] = source
	end
	threatSession.maxAmount = maxPercent
	threatSession.pending = nil
	return threatSession
end

function DamageMeter:GetSession(index)
	return self:GetSessionForState(self:BuildWindowRefreshState(index))
end

function DamageMeter:ClearRefreshSessionCache(cache)
	if not cache then return end
	if cache.byID then
		for damageMeterType, sessions in pairs(cache.byID) do
			if type(sessions) == "table" then
				for sessionID in pairs(sessions) do
					sessions[sessionID] = nil
				end
			else
				cache.byID[damageMeterType] = nil
			end
		end
	end
	if cache.byType then
		for damageMeterType, sessions in pairs(cache.byType) do
			if type(sessions) == "table" then
				for sessionType in pairs(sessions) do
					sessions[sessionType] = nil
				end
			else
				cache.byType[damageMeterType] = nil
			end
		end
	end
end

function DamageMeter:BuildLiveEventWatch()
	local typeWatch = self.liveEventTypeWatch
	if not typeWatch then
		typeWatch = {}
		self.liveEventTypeWatch = typeWatch
	else
		for key in pairs(typeWatch) do
			typeWatch[key] = nil
		end
	end
	local allSessionWatch = self.liveEventAllSessionWatch
	if not allSessionWatch then
		allSessionWatch = {}
		self.liveEventAllSessionWatch = allSessionWatch
	else
		for key in pairs(allSessionWatch) do
			allSessionWatch[key] = nil
		end
	end
	local sessionWatch = self.liveEventSessionWatch
	if not sessionWatch then
		sessionWatch = {}
		self.liveEventSessionWatch = sessionWatch
	else
		for key in pairs(sessionWatch) do
			sessionWatch[key] = nil
		end
	end
	if self:IsEnabled() then
		for index = 1, getWindowCount() do
			local damageMeterType = getDamageMeterTypeValue(self:GetEffectiveDamageMeterType(index))
			if damageMeterType ~= nil then
				typeWatch[damageMeterType] = true
				local sessionID = self:GetEffectiveSessionID(index)
				if sessionID then
					local sessions = sessionWatch[damageMeterType]
					if not sessions then
						sessions = {}
						sessionWatch[damageMeterType] = sessions
					end
					sessions[sessionID] = true
				else
					allSessionWatch[damageMeterType] = true
				end
			end
		end
	end
	self.liveEventWatchDirty = false
end

function DamageMeter:IsLiveEventRelevant(damageMeterType, sessionID)
	if damageMeterType == nil then return true end
	if self.liveEventWatchDirty or not self.liveEventTypeWatch then
		self:BuildLiveEventWatch()
	end
	if not self.liveEventTypeWatch[damageMeterType] then return false end
	if self.liveEventAllSessionWatch[damageMeterType] then return true end
	local sessions = self.liveEventSessionWatch[damageMeterType]
	return sessionID ~= nil and sessions and sessions[sessionID] == true
end

function DamageMeter:GetSessionDuration(index, session, state)
	state = state or self:BuildWindowRefreshState(index)
	if session then
		local duration = session.durationSeconds
		if duration and not isSecret(duration) then return safeNumber(duration) end
	end
	if state.preview then return PREVIEW_SESSION.durationSeconds end
	if state.sessionID then
		return safeNumber(state.temporary and state.temporary.sessionDurationSeconds)
	end
	if state.sessionEnum and C_DamageMeter and C_DamageMeter.GetSessionDurationSeconds then
		local duration = C_DamageMeter.GetSessionDurationSeconds(state.sessionEnum)
		if not isSecret(duration) then return safeNumber(duration) end
	end
	return nil
end

function DamageMeter:InvalidatePartyClassFallback()
	self.partyClassGeneration = (self.partyClassGeneration or 0) + 1
	self.partyClassCache = nil
end

function DamageMeter:MarkPartyClassFallbackCurrent()
	self.currentPartyClassGeneration = self.partyClassGeneration or 0
end

function DamageMeter:CanUsePartyClassFallback(index)
	if self:UsePreviewData() then return false end
	if self:GetEffectiveSessionID(index) then return false end
	if self:GetEffectiveSessionType(index) ~= "current" then return false end
	return (self.currentPartyClassGeneration or 0) == (self.partyClassGeneration or 0)
end

function DamageMeter:GetUniquePartyUnitTokenForClass(classFilename)
	if type(classFilename) ~= "string" or classFilename == "" then return nil end
	if IsInRaid and IsInRaid() then return nil end
	if not UnitExists or not UnitClass then return nil end
	self.partyClassCache = self.partyClassCache or {}
	for key in pairs(self.partyClassCache) do
		self.partyClassCache[key] = nil
	end
	for _, unitToken in ipairs(PARTY_UNIT_TOKENS) do
		if UnitExists(unitToken) then
			local _, unitClassFilename = UnitClass(unitToken)
			if type(unitClassFilename) == "string" and unitClassFilename ~= "" then
				local entry = self.partyClassCache[unitClassFilename]
				if entry then
					entry.duplicate = true
				else
					self.partyClassCache[unitClassFilename] = { token = unitToken, duplicate = false }
				end
			end
		end
	end
	local entry = self.partyClassCache[classFilename]
	if entry and not entry.duplicate and entry.token ~= "player" then return entry.token end
	return nil
end

function DamageMeter:GetUnitTokenGUID(unitToken)
	if not unitToken or not UnitGUID then return nil end
	local guid = UnitGUID(unitToken)
	if guid and not isSecret(guid) then return guid end
	return nil
end

function DamageMeter:HasSourceSpellDetails(details)
	return type(details) == "table" and type(details.combatSpells) == "table" and #details.combatSpells > 0
end

local getTooltipColumnVisibility
local resolveTooltipUnitName
local damageMeterNamesMatch

function DamageMeter:GetSourceDetails(index, source)
	if self:UsePreviewData() then return PREVIEW_SOURCE_DETAILS end
	if not source or not self:IsAvailable() then return nil end
	local damageMeterType = getDamageMeterTypeValue(self:GetEffectiveDamageMeterType(index))
	if damageMeterType == nil then return nil end
	local sessionID = self:GetEffectiveSessionID(index)
	local rawSourceGUID = source.sourceGUID
	local rawSourceCreatureID = source.sourceCreatureID
	local sourceGUID = not isSecret(rawSourceGUID) and rawSourceGUID or nil
	local sourceCreatureID = not isSecret(rawSourceCreatureID) and rawSourceCreatureID or nil
	local isLocalPlayer = source.isLocalPlayer == true
	local isRestrictedSource = isSecret(source.name) or isSecret(rawSourceGUID) or isSecret(rawSourceCreatureID)
	local partyUnitToken = isRestrictedSource and not isLocalPlayer and self:CanUsePartyClassFallback(index) and self:GetUniquePartyUnitTokenForClass(source.classFilename) or nil
	if sourceGUID == nil and sourceCreatureID == nil and not isLocalPlayer and not partyUnitToken then return nil end
	if sessionID and C_DamageMeter.GetCombatSessionSourceFromID then
		local emptyLocalDetails
		local details = C_DamageMeter.GetCombatSessionSourceFromID(sessionID, damageMeterType, sourceGUID, sourceCreatureID)
		if not isLocalPlayer or self:HasSourceSpellDetails(details) then return details end
		emptyLocalDetails = details
		if isLocalPlayer then
			local playerGUID = self:GetUnitTokenGUID("player")
			if playerGUID then
				details = C_DamageMeter.GetCombatSessionSourceFromID(sessionID, damageMeterType, playerGUID, nil)
				return details
			end
			details = C_DamageMeter.GetCombatSessionSourceFromID(sessionID, damageMeterType, nil, nil)
			if self:HasSourceSpellDetails(details) then return details end
		end
		local partyGUID = self:GetUnitTokenGUID(partyUnitToken)
		if partyGUID then
			details = C_DamageMeter.GetCombatSessionSourceFromID(sessionID, damageMeterType, partyGUID, nil)
			return details
		end
		if emptyLocalDetails then return emptyLocalDetails end
		return nil
	end
	local sessionType = SESSION_TYPES[self:GetEffectiveSessionType(index)] or SESSION_TYPES.current
	if sessionType and C_DamageMeter.GetCombatSessionSourceFromType then
		local emptyLocalDetails
		local details = C_DamageMeter.GetCombatSessionSourceFromType(sessionType, damageMeterType, sourceGUID, sourceCreatureID)
		if not isLocalPlayer or self:HasSourceSpellDetails(details) then return details end
		emptyLocalDetails = details
		if isLocalPlayer then
			local playerGUID = self:GetUnitTokenGUID("player")
			if playerGUID then
				details = C_DamageMeter.GetCombatSessionSourceFromType(sessionType, damageMeterType, playerGUID, nil)
				return details
			end
			details = C_DamageMeter.GetCombatSessionSourceFromType(sessionType, damageMeterType, nil, nil)
			if self:HasSourceSpellDetails(details) then return details end
		end
		local partyGUID = self:GetUnitTokenGUID(partyUnitToken)
		if partyGUID then
			details = C_DamageMeter.GetCombatSessionSourceFromType(sessionType, damageMeterType, partyGUID, nil)
			return details
		end
		if emptyLocalDetails then return emptyLocalDetails end
	end
	return nil
end

function DamageMeter:InvalidateDerivedTargetCache(liveSessionsOnly)
	if liveSessionsOnly and self.derivedTargetCache then
		for cacheKey in pairs(self.derivedTargetCache) do
			if type(cacheKey) ~= "string" or cacheKey:find("\001type:", 1, true) then
				self.derivedTargetCache[cacheKey] = nil
			end
		end
		if self.derivedTargetSessionCache then
			for cacheKey in pairs(self.derivedTargetSessionCache) do
				if type(cacheKey) ~= "string" or cacheKey:find("\001type:", 1, true) then
					self.derivedTargetSessionCache[cacheKey] = nil
				end
			end
		end
		return
	end
	self.derivedTargetCacheGeneration = (self.derivedTargetCacheGeneration or 0) + 1
	self.derivedTargetCache = nil
	self.derivedTargetSessionCache = nil
end

function DamageMeter:GetDerivedTargetSessionCacheKey(index)
	local sessionID = self:GetEffectiveSessionID(index)
	local sessionKey = sessionID and ("id:" .. tostring(sessionID)) or ("type:" .. tostring(self:GetEffectiveSessionType(index) or "current"))
	return table.concat({
		tostring(self.derivedTargetCacheGeneration or 0),
		tostring(index),
		sessionKey,
	}, "\001")
end

function DamageMeter:GetDerivedTargetCacheKey(index, source, config, damageMeterType)
	if not source or source.name == nil or isSecret(source.name) then return nil end
	return table.concat({
		self:GetDerivedTargetSessionCacheKey(index),
		tostring(damageMeterType),
		tostring(source.name),
		tostring(config.abbreviation),
		tostring(config.tooltipShowAmount ~= false),
		tostring(config.tooltipShowDPS ~= false),
		tostring(config.tooltipShowPercent ~= false),
		tostring(config.tooltipShowCreatureName ~= false),
		tostring(config.hideRealmNames ~= false),
		colorToHex(config.tooltipCreatureNameColor, DEFAULT_WINDOW.tooltipCreatureNameColor),
	}, "\001")
end

function DamageMeter:GetEnemyDamageTakenSourceDetails(index, enemySource)
	if self:UsePreviewData() or not enemySource or not self:IsAvailable() then return nil end
	local damageMeterType = getDamageMeterTypeValue("EnemyDamageTaken")
	if damageMeterType == nil then return nil end
	local rawSourceGUID = enemySource.sourceGUID
	local rawSourceCreatureID = enemySource.sourceCreatureID
	local sourceGUID = not isSecret(rawSourceGUID) and rawSourceGUID or nil
	local sourceCreatureID = not isSecret(rawSourceCreatureID) and rawSourceCreatureID or nil
	if sourceGUID == nil and sourceCreatureID == nil then return nil end
	local sessionID = self:GetEffectiveSessionID(index)
	if sessionID and C_DamageMeter.GetCombatSessionSourceFromID then
		local details
		if sourceCreatureID ~= nil then
			details = C_DamageMeter.GetCombatSessionSourceFromID(sessionID, damageMeterType, nil, sourceCreatureID)
			if self:HasSourceSpellDetails(details) then return details end
		end
		details = C_DamageMeter.GetCombatSessionSourceFromID(sessionID, damageMeterType, sourceGUID, sourceCreatureID)
		if self:HasSourceSpellDetails(details) then return details end
		if sourceGUID ~= nil then
			details = C_DamageMeter.GetCombatSessionSourceFromID(sessionID, damageMeterType, sourceGUID, nil)
		end
		return details
	end
	local sessionType = SESSION_TYPES[self:GetEffectiveSessionType(index)] or SESSION_TYPES.current
	if sessionType and C_DamageMeter.GetCombatSessionSourceFromType then
		local details
		if sourceCreatureID ~= nil then
			details = C_DamageMeter.GetCombatSessionSourceFromType(sessionType, damageMeterType, nil, sourceCreatureID)
			if self:HasSourceSpellDetails(details) then return details end
		end
		details = C_DamageMeter.GetCombatSessionSourceFromType(sessionType, damageMeterType, sourceGUID, sourceCreatureID)
		if self:HasSourceSpellDetails(details) then return details end
		if sourceGUID ~= nil then
			details = C_DamageMeter.GetCombatSessionSourceFromType(sessionType, damageMeterType, sourceGUID, nil)
		end
		return details
	end
	return nil
end

function DamageMeter:AddDerivedTargetEntry(cache, actorName, targetKey, targetName, amount, dps, classFilename)
	if actorName == nil or targetKey == nil or isSecret(actorName) or isSecret(targetKey) or not amount then return end
	actorName = tostring(actorName)
	targetKey = tostring(targetKey)
	if actorName == "" or targetKey == "" then return end
	if targetName == nil then
		targetName = targetKey
	elseif not isSecret(targetName) then
		targetName = tostring(targetName)
		if targetName == "" then targetName = targetKey end
	end
	local actorTargets = cache.byActor[actorName]
	if not actorTargets then
		actorTargets = {}
		cache.byActor[actorName] = actorTargets
		if Ambiguate then
			local shortName = Ambiguate(actorName, "short")
			if shortName and shortName ~= "" and shortName ~= actorName and not cache.byActor[shortName] then
				cache.byActor[shortName] = actorTargets
			end
		end
	end
	local target = actorTargets[targetKey]
	if not target then
		target = { key = targetKey, name = targetName, atlas = TOOLTIP_TARGET_ATLAS, amount = 0, dps = 0, classFilename = classFilename }
		actorTargets[targetKey] = target
	elseif target.name == nil or (not isSecret(target.name) and target.name == target.key) then
		target.name = targetName
	end
	if target.classFilename == nil then target.classFilename = classFilename end
	target.amount = target.amount + amount
	target.dps = target.dps + (dps or 0)
	return true
end

function DamageMeter:BuildDerivedTargetSessionCache(index)
	local cacheKey = self:GetDerivedTargetSessionCacheKey(index)
	self.derivedTargetSessionCache = self.derivedTargetSessionCache or {}
	local cached = self.derivedTargetSessionCache[cacheKey]
	if cached ~= nil then return cached ~= false and cached or nil end
	if UnitAffectingCombat and UnitAffectingCombat("player") then return nil end
	local enemyDamageTakenType = getDamageMeterTypeValue("EnemyDamageTaken")
	if enemyDamageTakenType == nil or not self:IsAvailable() then
		return nil
	end
	local session
	local sessionID = self:GetEffectiveSessionID(index)
	if sessionID and C_DamageMeter.GetCombatSessionFromID then
		session = C_DamageMeter.GetCombatSessionFromID(sessionID, enemyDamageTakenType)
	else
		local sessionType = SESSION_TYPES[self:GetEffectiveSessionType(index)] or SESSION_TYPES.current
		if sessionType and C_DamageMeter.GetCombatSessionFromType then
			session = C_DamageMeter.GetCombatSessionFromType(sessionType, enemyDamageTakenType)
		end
	end
	if type(session) ~= "table" or type(session.combatSources) ~= "table" then
		return nil
	end

	local cache = { byActor = {} }
	local addedAny = false
	local scanCount = 0
	for _, enemySource in ipairs(session.combatSources) do
		scanCount = scanCount + 1
		if scanCount > DERIVED_TARGET_SCAN_LIMIT then break end
		local targetName = resolveTooltipUnitName(enemySource.name)
		local targetKey = enemySource.sourceCreatureID
		if targetKey == nil or isSecret(targetKey) then targetKey = targetName end
		local enemyDetails = self:GetEnemyDamageTakenSourceDetails(index, enemySource)
		if targetKey ~= nil and not isSecret(targetKey) and type(enemyDetails) == "table" and type(enemyDetails.combatSpells) == "table" then
			for _, spell in ipairs(enemyDetails.combatSpells) do
				local spellDetails = spell.combatSpellDetails
				if type(spellDetails) == "table" then
					local amount = safeNumber(spell.totalAmount)
					if amount then
						if self:AddDerivedTargetEntry(cache, spellDetails.unitName, targetKey, targetName, amount, safeNumber(spell.amountPerSecond), spellDetails.unitClassFilename) then
							addedAny = true
						end
					end
				end
			end
		end
	end
	if not addedAny then return nil end
	self.derivedTargetSessionCache[cacheKey] = cache
	return cache
end

function DamageMeter:GetDerivedTargetsForSource(index, source)
	if not source or source.name == nil or isSecret(source.name) then return nil end
	local cache = self:BuildDerivedTargetSessionCache(index)
	if not cache or type(cache.byActor) ~= "table" then return nil end
	local actorTargets = cache.byActor[tostring(source.name)]
	if not actorTargets and Ambiguate then
		local shortName = Ambiguate(source.name, "short")
		if shortName and shortName ~= "" then actorTargets = cache.byActor[shortName] end
	end
	if not actorTargets then
		for actorName, targets in pairs(cache.byActor) do
			if damageMeterNamesMatch(actorName, source.name) then
				actorTargets = targets
				break
			end
		end
	end
	return actorTargets
end

function DamageMeter:BuildDerivedTargetRows(index, source, config, damageMeterType)
	if damageMeterType ~= "DamageDone" and damageMeterType ~= "Dps" then return nil end
	if not source or isSecret(source.name) then return nil end
	local cacheKey = self:GetDerivedTargetCacheKey(index, source, config, damageMeterType)
	if cacheKey then
		self.derivedTargetCache = self.derivedTargetCache or {}
		local cached = self.derivedTargetCache[cacheKey]
		if cached ~= nil then return cached ~= false and cached or nil end
	end
	local actorTargets = self:GetDerivedTargetsForSource(index, source)
	if type(actorTargets) ~= "table" then return nil end

	local showAmount, showDPS, showPercent = getTooltipColumnVisibility(config, damageMeterType)
	local targets = {}
	for _, target in pairs(actorTargets) do targets[#targets + 1] = target end
	table.sort(targets, function(a, b) return (a.amount or 0) > (b.amount or 0) end)
	if #targets == 0 then
		if cacheKey then self.derivedTargetCache[cacheKey] = false end
		return nil
	end

	local rows = {}
	local targetTotal = 0
	local targetMaxAmount = 0
	for _, target in ipairs(targets) do
		targetTotal = targetTotal + (target.amount or 0)
		if target.amount and target.amount > targetMaxAmount then targetMaxAmount = target.amount end
	end
	for _, target in ipairs(targets) do
		local percent = targetTotal > 0 and (target.amount / targetTotal * 100) or nil
		rows[#rows + 1] = {
			name = resolveTooltipUnitName(target.name, config) or target.name,
			atlas = target.atlas,
			icon = target.icon,
			amount = showAmount and formatNumber(target.amount, config.abbreviation),
			dps = showDPS and formatNumber(target.dps, config.abbreviation),
			percent = showPercent and percent and string.format("%.1f%%", percent),
			sortAmount = target.amount or 0,
			barValue = target.amount,
			barMax = targetMaxAmount,
			classFilename = target.classFilename,
		}
	end
	table.sort(rows, function(a, b) return (a.sortAmount or 0) > (b.sortAmount or 0) end)
	if targetMaxAmount > 0 then
		for _, target in ipairs(rows) do
			target.barMax = targetMaxAmount
		end
	end
	if cacheKey then self.derivedTargetCache[cacheKey] = rows end
	return rows
end

local function getRaidClassColor(classFilename)
	if type(classFilename) == "string" and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFilename] then
		return RAID_CLASS_COLORS[classFilename]
	end
end

local function getClassOrCustomColor(classFilename, customColor, defaultColor, useClassColor)
	local r, g, b, a = colorComponents(customColor, defaultColor)
	local classColor = useClassColor == true and getRaidClassColor(classFilename)
	if classColor then
		return classColor.r or 1, classColor.g or 1, classColor.b or 1, a
	end
	return r, g, b, a
end

function DamageMeter:GetBarColor(config, classFilename)
	local r, g, b = colorComponents(config.barColor, DEFAULT_WINDOW.barColor)
	local a = clampNumber(config.barOpacity, 0, 1, DEFAULT_WINDOW.barOpacity)
	if config.useClassColors ~= true then return r, g, b, a end
	local color = getRaidClassColor(classFilename)
	if color then
		return color.r or 1, color.g or 1, color.b or 1, a
	end
	return 0.55, 0.55, 0.55, a
end

function DamageMeter:GetNameColor(config, classFilename)
	return getClassOrCustomColor(classFilename, config.nameColor, DEFAULT_WINDOW.nameColor, config.nameUseClassColors)
end

function DamageMeter:GetValueColor(config, classFilename)
	return getClassOrCustomColor(classFilename, config.valueColor, DEFAULT_WINDOW.valueColor, config.valueUseClassColors)
end

function DamageMeter:GetPrefixRankColor(config, classFilename)
	return self:GetRankColor(config, classFilename)
end

function DamageMeter:GetRankColor(config, classFilename)
	return getClassOrCustomColor(classFilename, config.rankColor, DEFAULT_WINDOW.rankColor, config.rankUseClassColors)
end

function DamageMeter:GetRowColorState(frame, config, classFilename)
	local styleVersion = self:GetWindowStyleVersion(frame.index or 0)
	local cache = frame._damageMeterRowColorCache
	if not cache or cache.styleVersion ~= styleVersion then
		cache = { styleVersion = styleVersion, byClass = {} }
		frame._damageMeterRowColorCache = cache
	end
	local classKey = type(classFilename) == "string" and classFilename ~= "" and classFilename or false
	local entry = cache.byClass[classKey]
	if entry then return entry end
	local r, g, b, a = self:GetBarColor(config, classKey)
	local nr, ng, nb, na = self:GetNameColor(config, classKey)
	local vr, vg, vb, va = self:GetValueColor(config, classKey)
	local prr, prg, prb, pra = self:GetPrefixRankColor(config, classKey)
	local rr, rg, rb, ra = self:GetRankColor(config, classKey)
	local rbr, rbg, rbb, rba = getClassOrCustomColor(classKey, config.rowBorderColor, DEFAULT_WINDOW.rowBorderColor, config.rowBorderUseClassColor)
	local bbr, bbg, bbb, bba = getClassOrCustomColor(classKey, config.barBorderColor, DEFAULT_WINDOW.barBorderColor, config.barBorderUseClassColor)
	local ibr, ibg, ibb, iba = getClassOrCustomColor(classKey, config.iconBorderColor, DEFAULT_WINDOW.iconBorderColor, config.iconBorderUseClassColor)
	entry = {
		r = r, g = g, b = b, a = a,
		nr = nr, ng = ng, nb = nb, na = na,
		vr = vr, vg = vg, vb = vb, va = va,
		prr = prr, prg = prg, prb = prb, pra = pra,
		rr = rr, rg = rg, rb = rb, ra = ra,
		rbr = rbr, rbg = rbg, rbb = rbb, rba = rba,
		bbr = bbr, bbg = bbg, bbb = bbb, bba = bba,
		ibr = ibr, ibg = ibg, ibb = ibb, iba = iba,
	}
	cache.byClass[classKey] = entry
	return entry
end

local function applyCachedFontString(fontString, fontFace, size, fontOutline, cachePrefix)
	local globalFontVersion = getGlobalFontStateVersion()
	cachePrefix = cachePrefix or "font"
	if fontString._damageMeterFontPrefix == cachePrefix
		and fontString._damageMeterFontFace == fontFace
		and fontString._damageMeterFontSize == size
		and fontString._damageMeterFontOutline == fontOutline
		and fontString._damageMeterFontGlobalVersion == globalFontVersion then
		return
	end
	fontString._damageMeterFontPrefix = cachePrefix
	fontString._damageMeterFontFace = fontFace
	fontString._damageMeterFontSize = size
	fontString._damageMeterFontOutline = fontOutline
	fontString._damageMeterFontGlobalVersion = globalFontVersion
	local ufHelper = addon.Aura and addon.Aura.UFHelper
	if ufHelper and ufHelper.applyFont then
		ufHelper.applyFont(fontString, fontFace, size, fontOutline)
		return
	end
	if addon.functions.ApplyFontString then
		addon.functions.ApplyFontString(fontString, fontFace, size, fontOutline, DEFAULT_FONT, "OUTLINE")
		return
	end
	local font = resolveFont(fontFace)
	local style = resolveStyle(fontOutline)
	fontString:SetFont(font, size, style)
end

function DamageMeter:ApplyFontString(fontString, config)
	applyCachedFontString(fontString, config.fontFace, clampNumber(config.fontSize, 8, 24, 11), config.fontOutline, "name")
end

function DamageMeter:ApplyRankFontString(fontString, config)
	applyCachedFontString(fontString, config.rankFontFace, clampNumber(config.rankFontSize, 8, 24, DEFAULT_WINDOW.rankFontSize), config.rankFontOutline, "rank")
end

function DamageMeter:ApplyValueFontString(fontString, config)
	applyCachedFontString(fontString, config.valueFontFace, clampNumber(config.valueFontSize, 8, 24, DEFAULT_WINDOW.valueFontSize), config.valueFontOutline, "value")
end

function DamageMeter:ApplyTitleFontString(fontString, config)
	applyCachedFontString(fontString, config.titleFontFace, clampNumber(config.titleFontSize, 8, 28, DEFAULT_WINDOW.titleFontSize), config.titleFontOutline, "title")
end

function DamageMeter:ApplyStatusFontString(fontString, config)
	applyCachedFontString(fontString, config.statusFontFace, clampNumber(config.statusFontSize, 8, 24, DEFAULT_WINDOW.statusFontSize), config.statusFontOutline, "status")
end

function DamageMeter:ApplyTooltipFontString(fontString, config)
	applyCachedFontString(fontString, config.tooltipFontFace, clampNumber(config.tooltipFontSize, 8, 24, DEFAULT_WINDOW.tooltipFontSize), config.tooltipFontOutline, "tooltip")
end

local function applyTooltipBorder(border, enabled, textureKey, size, r, g, b, a)
	if not border then return end
	if enabled then
		if not border._damageMeterBorderTop then
			border._damageMeterBorderTop = border:CreateTexture(nil, "BORDER")
			border._damageMeterBorderBottom = border:CreateTexture(nil, "BORDER")
			border._damageMeterBorderLeft = border:CreateTexture(nil, "BORDER")
			border._damageMeterBorderRight = border:CreateTexture(nil, "BORDER")
		end
		local top = border._damageMeterBorderTop
		local bottom = border._damageMeterBorderBottom
		local left = border._damageMeterBorderLeft
		local right = border._damageMeterBorderRight
		if border._damageMeterBackdropEnabled ~= true
			or border._damageMeterBackdropTexture ~= textureKey
			or border._damageMeterBackdropSize ~= size then
			border._damageMeterBackdropEnabled = true
			border._damageMeterBackdropTexture = textureKey
			border._damageMeterBackdropSize = size
			local texture = resolveMedia("border", textureKey, DEFAULT_BORDER)
			top:SetTexture(texture)
			bottom:SetTexture(texture)
			left:SetTexture(texture)
			right:SetTexture(texture)
			top:ClearAllPoints()
			top:SetPoint("TOPLEFT", border, "TOPLEFT")
			top:SetPoint("TOPRIGHT", border, "TOPRIGHT")
			top:SetHeight(size)
			bottom:ClearAllPoints()
			bottom:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT")
			bottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
			bottom:SetHeight(size)
			left:ClearAllPoints()
			left:SetPoint("TOPLEFT", border, "TOPLEFT")
			left:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT")
			left:SetWidth(size)
			right:ClearAllPoints()
			right:SetPoint("TOPRIGHT", border, "TOPRIGHT")
			right:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT")
			right:SetWidth(size)
		end
		if border._damageMeterBorderColorR ~= r
			or border._damageMeterBorderColorG ~= g
			or border._damageMeterBorderColorB ~= b
			or border._damageMeterBorderColorA ~= a then
			border._damageMeterBorderColorR = r
			border._damageMeterBorderColorG = g
			border._damageMeterBorderColorB = b
			border._damageMeterBorderColorA = a
			top:SetVertexColor(r, g, b, a)
			bottom:SetVertexColor(r, g, b, a)
			left:SetVertexColor(r, g, b, a)
			right:SetVertexColor(r, g, b, a)
		end
		top:Show()
		bottom:Show()
		left:Show()
		right:Show()
		setShownIfChanged(border, true)
	else
		if border._damageMeterBackdropEnabled ~= false then
			border._damageMeterBackdropEnabled = false
			border._damageMeterBackdropTexture = nil
			border._damageMeterBackdropSize = nil
			border._damageMeterBorderColorR = nil
			border._damageMeterBorderColorG = nil
			border._damageMeterBorderColorB = nil
			border._damageMeterBorderColorA = nil
			if border._damageMeterBorderTop then border._damageMeterBorderTop:Hide() end
			if border._damageMeterBorderBottom then border._damageMeterBorderBottom:Hide() end
			if border._damageMeterBorderLeft then border._damageMeterBorderLeft:Hide() end
			if border._damageMeterBorderRight then border._damageMeterBorderRight:Hide() end
		end
		setShownIfChanged(border, false)
	end
end

function trimTextureInput(value)
	if type(value) ~= "string" then return "" end
	return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function getCustomTextureInfo(value)
	value = trimTextureInput(value)
	if value == "" then return nil end
	local textureID = tonumber(value)
	if textureID then return "texture", textureID end
	if _G.C_Texture and _G.C_Texture.GetAtlasInfo and _G.C_Texture.GetAtlasInfo(value) then
		return "atlas", value
	end
	return "texture", value
end

local function applyTextureOverride(textureObject, textureKind, texture)
	if textureObject._damageMeterTextureKind == textureKind and textureObject._damageMeterTexture == texture then return end
	textureObject._damageMeterTextureKind = textureKind
	textureObject._damageMeterTexture = texture
	if textureKind == "atlas" then
		textureObject:SetAtlas(texture)
	else
		textureObject:SetTexture(texture)
		textureObject:SetTexCoord(0, 1, 0, 1)
	end
end

local function applyTextureColor(textureObject, r, g, b, a)
	if textureObject._damageMeterColorR == r
		and textureObject._damageMeterColorG == g
		and textureObject._damageMeterColorB == b
		and textureObject._damageMeterColorA == a then
		return
	end
	textureObject._damageMeterColorR = r
	textureObject._damageMeterColorG = g
	textureObject._damageMeterColorB = b
	textureObject._damageMeterColorA = a
	textureObject:SetVertexColor(r, g, b, a)
end

function DamageMeter:ApplyBarBackground(row, config)
	local textureKind, texture = getCustomTextureInfo(config.barBackgroundUseCustomTexture == true and config.barBackgroundCustomTexture or nil)
	if not textureKind then
		textureKind = "texture"
		texture = resolveMedia("statusbar", config.barBackgroundTexture, "Interface\\Buttons\\WHITE8x8")
	end
	local r, g, b, a = colorComponents(config.barBackgroundColor, DEFAULT_WINDOW.barBackgroundColor)
	applyTextureOverride(row.background, textureKind, texture)
	applyTextureColor(row.background, r, g, b, a)
end

function DamageMeter:ApplyHeaderBackground(frame, config, showHeader)
	local enabled = showHeader and config.headerBackgroundEnabled == true
	setShownIfChanged(frame.headerBackground, enabled)
	if not enabled then return end
	local textureKind, texture = getCustomTextureInfo(config.headerBackgroundUseCustomTexture == true and config.headerBackgroundCustomTexture or nil)
	if not textureKind then
		textureKind = "texture"
		texture = resolveMedia("statusbar", config.headerBackgroundTexture, "Interface\\Buttons\\WHITE8x8")
	end
	local r, g, b, a = colorComponents(config.headerBackgroundColor, DEFAULT_WINDOW.headerBackgroundColor)
	applyTextureOverride(frame.headerBackground, textureKind, texture)
	applyTextureColor(frame.headerBackground, r, g, b, a)
end

function DamageMeter:ApplyFooterBackground(frame, config, showFooter)
	local enabled = showFooter and config.footerBackgroundEnabled == true
	setShownIfChanged(frame.footerBackground, enabled)
	if not enabled then return end
	local textureKind, texture = getCustomTextureInfo(config.footerBackgroundUseCustomTexture == true and config.footerBackgroundCustomTexture or nil)
	if not textureKind then
		textureKind = "texture"
		texture = resolveMedia("statusbar", config.footerBackgroundTexture, "Interface\\Buttons\\WHITE8x8")
	end
	local r, g, b, a = colorComponents(config.footerBackgroundColor, DEFAULT_WINDOW.footerBackgroundColor)
	applyTextureOverride(frame.footerBackground, textureKind, texture)
	applyTextureColor(frame.footerBackground, r, g, b, a)
end

function DamageMeter:ApplyWindowBackground(frame, config)
	local textureKind, texture = getCustomTextureInfo(config.backdropUseCustomTexture == true and config.backdropCustomTexture or nil)
	if not textureKind then
		textureKind = "texture"
		texture = resolveMedia("statusbar", config.backdropTexture, "Interface\\Buttons\\WHITE8x8")
	end
	local r, g, b, a = colorComponents(config.backdropColor, DEFAULT_WINDOW.backdropColor)
	setShownIfChanged(frame.windowBackground, a > 0)
	applyTextureOverride(frame.windowBackground, textureKind, texture)
	applyTextureColor(frame.windowBackground, r, g, b, a)
end

function DamageMeter:ApplyContentBackground(frame, config)
	local enabled = config.contentBackgroundEnabled == true
	setShownIfChanged(frame.contentBackground, enabled)
	if not enabled then return end
	local textureKind, texture = getCustomTextureInfo(config.contentBackgroundUseCustomTexture == true and config.contentBackgroundCustomTexture or nil)
	if not textureKind then
		textureKind = "texture"
		texture = resolveMedia("statusbar", config.contentBackgroundTexture, "Interface\\Buttons\\WHITE8x8")
	end
	local r, g, b, a = colorComponents(config.contentBackgroundColor, DEFAULT_WINDOW.contentBackgroundColor)
	applyTextureOverride(frame.contentBackground, textureKind, texture)
	applyTextureColor(frame.contentBackground, r, g, b, a)
end

function DamageMeter:GetRowBorderLeftOffset(row, config)
	local _, _, iconSize, rankWidth, rankGap = getRowTextInsets(config)
	local showRankColumn = config.showRanks ~= false and rankWidth > 0
	local rankPrefixText = useTextRankPrefix(config)
	local leftOffset = 4
	if showRankColumn and not rankPrefixText then
		local rankOffsetX = clampNumber(config.rankOffsetX, -200, 200, DEFAULT_WINDOW.rankOffsetX)
		leftOffset = leftOffset + rankOffsetX + rankWidth + rankGap
	end
	if config.showIcons ~= false and iconSize > 0 and row.iconFrame and row.iconFrame:IsShown() then
		return leftOffset
	end
	if showRankColumn and not rankPrefixText then
		return leftOffset
	end
	return 4
end

function DamageMeter:PositionRowBorder(row, config)
	if not row.rowBorder then return end
	row.rowBorder:ClearAllPoints()
	local borderOffset = clampNumber(config.rowBorderInset, 0, 24, DEFAULT_WINDOW.rowBorderInset)
	local barWidthOffset = clampNumber(config.barWidthOffset, -200, 200, DEFAULT_WINDOW.barWidthOffset)
	local leftOffset = self:GetRowBorderLeftOffset(row, config) - borderOffset
	local rightOffset = -4 + barWidthOffset + borderOffset
	row.rowBorder:SetPoint("TOPLEFT", row, "TOPLEFT", leftOffset, borderOffset)
	row.rowBorder:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", rightOffset, -borderOffset)
	row.rowBorder:SetFrameLevel(row.bar:GetFrameLevel() + 2)
end

function DamageMeter:ApplyRowBorder(row, config, classFilename, colors)
	local border = row.rowBorder
	if not border or not border.SetBackdrop then return end
	local enabled = config.rowBorderEnabled == true
	local styleVersion = self:GetWindowStyleVersion(row.windowIndex or 0)
	local classKey = enabled and config.rowBorderUseClassColor == true and type(classFilename) == "string" and classFilename ~= "" and classFilename or false
	if border._damageMeterApplyVersion == styleVersion
		and border._damageMeterApplyEnabled == enabled
		and border._damageMeterApplyClassKey == classKey then
		setShownIfChanged(border, enabled)
		return
	end
	border._damageMeterApplyVersion = styleVersion
	border._damageMeterApplyEnabled = enabled
	border._damageMeterApplyClassKey = classKey
	if enabled then
		local size = clampNumber(config.rowBorderSize, 1, 32, DEFAULT_WINDOW.rowBorderSize)
		local br, bg, bb, ba
		if colors then
			br, bg, bb, ba = colors.rbr, colors.rbg, colors.rbb, colors.rba
		else
			br, bg, bb, ba = getClassOrCustomColor(classKey, config.rowBorderColor, DEFAULT_WINDOW.rowBorderColor, config.rowBorderUseClassColor)
		end
		local backdropChanged = false
		if border._damageMeterBackdropEnabled ~= true
			or border._damageMeterBackdropTexture ~= config.rowBorderTexture
			or border._damageMeterBackdropSize ~= size then
			border._damageMeterBackdropEnabled = true
			border._damageMeterBackdropTexture = config.rowBorderTexture
			border._damageMeterBackdropSize = size
			backdropChanged = true
			local borderTexture = resolveMedia("border", config.rowBorderTexture, DEFAULT_BORDER)
			border:SetBackdrop({
				edgeFile = borderTexture,
				edgeSize = size,
			})
		end
		if backdropChanged
			or border._damageMeterBorderColorR ~= br
			or border._damageMeterBorderColorG ~= bg
			or border._damageMeterBorderColorB ~= bb
			or border._damageMeterBorderColorA ~= ba then
			border._damageMeterBorderColorR = br
			border._damageMeterBorderColorG = bg
			border._damageMeterBorderColorB = bb
			border._damageMeterBorderColorA = ba
			border:SetBackdropBorderColor(br, bg, bb, ba)
		end
		setShownIfChanged(border, true)
	else
		if border._damageMeterBackdropEnabled ~= false then
			border._damageMeterBackdropEnabled = false
			border._damageMeterBackdropTexture = nil
			border._damageMeterBackdropSize = nil
			border._damageMeterBorderColorR = nil
			border._damageMeterBorderColorG = nil
			border._damageMeterBorderColorB = nil
			border._damageMeterBorderColorA = nil
			border:SetBackdrop(nil)
		end
		setShownIfChanged(border, false)
	end
end

function DamageMeter:ApplyBarBorder(row, config, classFilename, colors)
	local border = row.barBorder
	if not border or not border.SetBackdrop then return end
	local enabled = config.barBorderEnabled == true
	local classKey = enabled and config.barBorderUseClassColor == true and type(classFilename) == "string" and classFilename ~= "" and classFilename or false
	local styleVersion = self:GetWindowStyleVersion(row.windowIndex or 0)
	if border._damageMeterApplyVersion == styleVersion
		and border._damageMeterApplyEnabled == enabled
		and border._damageMeterApplyClassKey == classKey then
		setShownIfChanged(border, enabled)
		return
	end
	border._damageMeterApplyVersion = styleVersion
	border._damageMeterApplyEnabled = enabled
	border._damageMeterApplyClassKey = classKey
	if config.barBorderEnabled == true then
		local size = clampNumber(config.barBorderSize, 1, 32, DEFAULT_WINDOW.barBorderSize)
		local br, bg, bb, ba
		if colors then
			br, bg, bb, ba = colors.bbr, colors.bbg, colors.bbb, colors.bba
		else
			br, bg, bb, ba = getClassOrCustomColor(classKey, config.barBorderColor, DEFAULT_WINDOW.barBorderColor, config.barBorderUseClassColor)
		end
		local backdropChanged = false
		if border._damageMeterBackdropEnabled ~= true
			or border._damageMeterBackdropTexture ~= config.barBorderTexture
			or border._damageMeterBackdropSize ~= size then
			border._damageMeterBackdropEnabled = true
			border._damageMeterBackdropTexture = config.barBorderTexture
			border._damageMeterBackdropSize = size
			backdropChanged = true
			local borderTexture = resolveMedia("border", config.barBorderTexture, DEFAULT_BORDER)
			border:SetBackdrop({
				edgeFile = borderTexture,
				edgeSize = size,
			})
		end
		if backdropChanged
			or border._damageMeterBorderColorR ~= br
			or border._damageMeterBorderColorG ~= bg
			or border._damageMeterBorderColorB ~= bb
			or border._damageMeterBorderColorA ~= ba then
			border._damageMeterBorderColorR = br
			border._damageMeterBorderColorG = bg
			border._damageMeterBorderColorB = bb
			border._damageMeterBorderColorA = ba
			border:SetBackdropBorderColor(br, bg, bb, ba)
		end
		setShownIfChanged(border, true)
	else
		if border._damageMeterBackdropEnabled ~= false then
			border._damageMeterBackdropEnabled = false
			border._damageMeterBackdropTexture = nil
			border._damageMeterBackdropSize = nil
			border._damageMeterBorderColorR = nil
			border._damageMeterBorderColorG = nil
			border._damageMeterBorderColorB = nil
			border._damageMeterBorderColorA = nil
			border:SetBackdrop(nil)
		end
		setShownIfChanged(border, false)
	end
end

function DamageMeter:ApplyIconBorder(row, config, classFilename, colors)
	local border = row.iconBorder
	if not border or not border.SetBackdrop then return end
	local enabled = config.showIcons ~= false and config.iconBorderEnabled == true
	local classKey = enabled and config.iconBorderUseClassColor == true and type(classFilename) == "string" and classFilename ~= "" and classFilename or false
	local styleVersion = self:GetWindowStyleVersion(row.windowIndex or 0)
	if border._damageMeterApplyVersion == styleVersion
		and border._damageMeterApplyEnabled == enabled
		and border._damageMeterApplyClassKey == classKey then
		setShownIfChanged(border, enabled)
		return
	end
	border._damageMeterApplyVersion = styleVersion
	border._damageMeterApplyEnabled = enabled
	border._damageMeterApplyClassKey = classKey
	if enabled then
		local size = clampNumber(config.iconBorderSize, 1, 32, DEFAULT_WINDOW.iconBorderSize)
		local br, bg, bb, ba
		if colors then
			br, bg, bb, ba = colors.ibr, colors.ibg, colors.ibb, colors.iba
		else
			br, bg, bb, ba = getClassOrCustomColor(classKey, config.iconBorderColor, DEFAULT_WINDOW.iconBorderColor, config.iconBorderUseClassColor)
		end
		local backdropChanged = false
		if border._damageMeterBackdropEnabled ~= true
			or border._damageMeterBackdropTexture ~= config.iconBorderTexture
			or border._damageMeterBackdropSize ~= size then
			border._damageMeterBackdropEnabled = true
			border._damageMeterBackdropTexture = config.iconBorderTexture
			border._damageMeterBackdropSize = size
			backdropChanged = true
			local borderTexture = resolveMedia("border", config.iconBorderTexture, DEFAULT_BORDER)
			border:SetBackdrop({
				edgeFile = borderTexture,
				edgeSize = size,
			})
		end
		if backdropChanged
			or border._damageMeterBorderColorR ~= br
			or border._damageMeterBorderColorG ~= bg
			or border._damageMeterBorderColorB ~= bb
			or border._damageMeterBorderColorA ~= ba then
			border._damageMeterBorderColorR = br
			border._damageMeterBorderColorG = bg
			border._damageMeterBorderColorB = bb
			border._damageMeterBorderColorA = ba
			border:SetBackdropBorderColor(br, bg, bb, ba)
		end
		setShownIfChanged(border, true)
	else
		if border._damageMeterBackdropEnabled ~= false then
			border._damageMeterBackdropEnabled = false
			border._damageMeterBackdropTexture = nil
			border._damageMeterBackdropSize = nil
			border._damageMeterBorderColorR = nil
			border._damageMeterBorderColorG = nil
			border._damageMeterBorderColorB = nil
			border._damageMeterBorderColorA = nil
			border:SetBackdrop(nil)
		end
		setShownIfChanged(border, false)
	end
end

function DamageMeter:ApplyRowTextLayout(row, config, forceRankColumn)
	local rowMode = config.raidRowsEnabled == true and IsInRaid() and "raid" or "default"
	local styleVersion = self:GetWindowStyleVersion(row.windowIndex or 0)
	if row._damageMeterTextLayoutStyleVersion == styleVersion
		and row._damageMeterTextLayoutRowMode == rowMode
		and row._damageMeterTextLayoutForceRankColumn == (forceRankColumn == true) then
		return
	end
	row._damageMeterTextLayoutStyleVersion = styleVersion
	row._damageMeterTextLayoutRowMode = rowMode
	row._damageMeterTextLayoutForceRankColumn = forceRankColumn == true

	local _, barHeight = getRowMetrics(config)
	local leftInset, rightInset, iconSize, rankWidth, rankGap = getRowTextInsets(config, forceRankColumn)
	local iconGap = getIconGap(config)
	local rankPrefixText = useTextRankPrefix(config)
	local showRankColumn = config.showRanks ~= false and rankWidth > 0
	row.rank:SetWidth(rankWidth)
	row.rank:ClearAllPoints()
	setShownIfChanged(row.rank, showRankColumn)
	row.iconFrame:SetSize(iconSize, iconSize)
	row.iconFrame:ClearAllPoints()
	if iconSize > 0 and showRankColumn and not rankPrefixText then
		row.iconFrame:SetPoint("LEFT", row.rank, "RIGHT", rankGap, 0)
		row.iconFrame:Show()
	elseif iconSize > 0 then
		row.iconFrame:SetPoint("LEFT", 4, 0)
		row.iconFrame:Show()
	else
		row.iconFrame:Hide()
	end
	row.iconBorder:ClearAllPoints()
	local iconBorderOffset = getIconBorderOutset(config)
	row.iconBorder:SetPoint("TOPLEFT", row.iconFrame, "TOPLEFT", -iconBorderOffset, iconBorderOffset)
	row.iconBorder:SetPoint("BOTTOMRIGHT", row.iconFrame, "BOTTOMRIGHT", iconBorderOffset, -iconBorderOffset)
	row.iconBorder:SetFrameLevel(row.iconFrame:GetFrameLevel() + 2)
	row.bar:ClearAllPoints()
	if iconSize > 0 then
		row.bar:SetPoint("LEFT", row.iconFrame, "RIGHT", iconGap, 0)
	elseif showRankColumn and not rankPrefixText then
		row.bar:SetPoint("LEFT", row.rank, "RIGHT", rankGap, 0)
	else
		row.bar:SetPoint("LEFT", row, "LEFT", 4, 0)
	end
	local barWidthOffset = clampNumber(config.barWidthOffset, -200, 200, DEFAULT_WINDOW.barWidthOffset)
	row.bar:SetPoint("RIGHT", row, "RIGHT", -4 + barWidthOffset, 0)
	row.bar:SetHeight(barHeight)
	if normalizeAnchorV(config.barAnchor) == "TOP" then
		row.bar:SetPoint("TOP", row, "TOP", 0, 0)
	elseif normalizeAnchorV(config.barAnchor) == "BOTTOM" then
		row.bar:SetPoint("BOTTOM", row, "BOTTOM", 0, 0)
	else
		row.bar:SetPoint("CENTER", row, "CENTER", 0, 0)
	end
	row.barBorder:ClearAllPoints()
	local borderOffset = clampNumber(config.barBorderInset, 0, 24, DEFAULT_WINDOW.barBorderInset)
	row.barBorder:SetPoint("TOPLEFT", row.bar, "TOPLEFT", -borderOffset, borderOffset)
	row.barBorder:SetPoint("BOTTOMRIGHT", row.bar, "BOTTOMRIGHT", borderOffset, -borderOffset)
	self:PositionRowBorder(row, config)
	row.barBorder:SetFrameLevel(row.bar:GetFrameLevel() + 3)
	row.rankFrame:SetFrameLevel(row.bar:GetFrameLevel() + 5)
	row.textArea:ClearAllPoints()
	row.textArea:SetFrameLevel(row.bar:GetFrameLevel() + 4)
	row.textArea:SetPoint("TOPLEFT", row, "TOPLEFT", leftInset, 0)
	row.textArea:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -rightInset, 0)
	if showRankColumn then
		if rankPrefixText then
			row.rank:SetPoint("LEFT", row.textArea, "LEFT", 0, 0)
		else
			local rankH = normalizeAnchorH(config.rankAnchorH)
			local rankV = normalizeAnchorV(config.rankAnchorV)
			local rankOffsetX = clampNumber(config.rankOffsetX, -200, 200, DEFAULT_WINDOW.rankOffsetX)
			local rankOffsetY = clampNumber(config.rankOffsetY, -200, 200, DEFAULT_WINDOW.rankOffsetY)
			local rankColumnOffset = 4
			if rankH == "CENTER" then
				rankColumnOffset = rankColumnOffset + (rankWidth / 2)
			elseif rankH == "RIGHT" then
				rankColumnOffset = rankColumnOffset + rankWidth
			end
			row.rank:SetPoint(anchorPoint(rankH, rankV), row, anchorPoint("LEFT", rankV), rankColumnOffset + rankOffsetX, rankOffsetY)
		end
		row.rank:SetJustifyH(justifyFromAnchor(rankPrefixText and "LEFT" or config.rankAnchorH))
	end
	setShownIfChanged(row.name, config.showNames == true)
end

function DamageMeter:ApplyRowValueWidth(row, config, damageMeterType, forceRankColumn)
	damageMeterType = damageMeterType or config.damageMeterType
	local rowMode = config.raidRowsEnabled == true and IsInRaid() and "raid" or "default"
	local styleVersion = self:GetWindowStyleVersion(row.windowIndex or 0)
	if row._damageMeterValueLayoutStyleVersion == styleVersion
		and row._damageMeterValueLayoutRowMode == rowMode
		and row._damageMeterValueLayoutType == damageMeterType
		and row._damageMeterValueLayoutForceRankColumn == (forceRankColumn == true)
		and row._damageMeterValueLayoutMode == getRowValueLayout(config) then
		return
	end
	row._damageMeterValueLayoutStyleVersion = styleVersion
	row._damageMeterValueLayoutRowMode = rowMode
	row._damageMeterValueLayoutType = damageMeterType
	row._damageMeterValueLayoutForceRankColumn = forceRankColumn == true
	row._damageMeterValueLayoutMode = getRowValueLayout(config)

	local frameWidth = clampNumber(config.width, 100, 700, DEFAULT_WINDOW.width)
	local leftInset, rightInset, _, rankWidth, rankGap = getRowTextInsets(config, forceRankColumn)
	local availableWidth = math.max(1, (frameWidth - 8) - leftInset - rightInset)
	local nameGap = config.showNames == false and 0 or 4
	local rankPrefixText = useTextRankPrefix(config)
	local rankPrefixWidth = rankPrefixText and math.max(0, rankWidth + rankGap) or 0
	local valueFontSize = clampNumber(config.valueFontSize, 8, 24, DEFAULT_WINDOW.valueFontSize)
	local useValueColumns = getRowValueLayout(config) == "columns"
	local minNameWidth = (config.showNames == false or useValueColumns) and 0 or clampNumber(config.minNameWidth, 0, 180, DEFAULT_WINDOW.minNameWidth)
	row._damageMeterUseValueColumns = useValueColumns
	if useValueColumns then
		local showAmount, showRate, showPercent = getRowValueColumnVisibility(damageMeterType, config)
		local amountWidth = showAmount and clampNumber(config.amountColumnWidth, 24, 180, DEFAULT_WINDOW.amountColumnWidth) or 0
		local rateWidth = showRate and clampNumber(config.rateColumnWidth, 24, 180, DEFAULT_WINDOW.rateColumnWidth) or 0
		local percentWidth = showPercent and clampNumber(config.percentColumnWidth, 24, 120, DEFAULT_WINDOW.percentColumnWidth) or 0
		local columnGap = clampNumber(config.valueColumnGap, 0, 24, DEFAULT_WINDOW.valueColumnGap)
		local nameValueGap = config.showNames == false and 0 or clampNumber(config.nameValueGap, 0, 32, DEFAULT_WINDOW.nameValueGap)
		local function getColumnsWidth()
			local count = (showAmount and 1 or 0) + (showRate and 1 or 0) + (showPercent and 1 or 0)
			return amountWidth + rateWidth + percentWidth + (math.max(0, count - 1) * columnGap)
		end
		local maxColumnsWidth = math.max(1, availableWidth - minNameWidth - nameValueGap - rankPrefixWidth)
		local columnsWidth = getColumnsWidth()
		if columnsWidth > maxColumnsWidth and showPercent then
			showPercent = false
			percentWidth = 0
			columnsWidth = getColumnsWidth()
		end
		if columnsWidth > maxColumnsWidth and showRate and showAmount then
			showRate = false
			rateWidth = 0
			columnsWidth = getColumnsWidth()
		end
		if columnsWidth > maxColumnsWidth and columnsWidth > 0 then
			local scale = maxColumnsWidth / columnsWidth
			amountWidth = showAmount and math.max(24, math.floor(amountWidth * scale)) or 0
			rateWidth = showRate and math.max(24, math.floor(rateWidth * scale)) or 0
			percentWidth = showPercent and math.max(24, math.floor(percentWidth * scale)) or 0
			columnsWidth = getColumnsWidth()
		end
		local nameWidth = math.max(0, availableWidth - columnsWidth - nameValueGap - rankPrefixWidth)
		row.value:SetWidth(amountWidth)
		row.name:SetWidth(nameWidth)
		row.name._damageMeterNameLayoutWidth = nameWidth
		row.rank:SetWidth(rankWidth)
		if row.rateValue then row.rateValue:SetWidth(rateWidth) end
		if row.percentValue then row.percentValue:SetWidth(percentWidth) end
		row.value:SetShown(showAmount)
		if row.rateValue then row.rateValue:SetShown(showRate) end
		if row.percentValue then row.percentValue:SetShown(showPercent) end

		row.value:ClearAllPoints()
		row.name:ClearAllPoints()
		if row.rateValue then row.rateValue:ClearAllPoints() end
		if row.percentValue then row.percentValue:ClearAllPoints() end
		if rankPrefixText then row.rank:ClearAllPoints() end

		local rightAnchor = row.textArea
		local rightOffset = 0
		local nameV = normalizeAnchorV(config.nameAnchorV)
		local nameOffsetX = clampNumber(config.nameOffsetX, -200, 200, DEFAULT_WINDOW.nameOffsetX)
		local nameOffsetY = clampNumber(config.nameOffsetY, -200, 200, DEFAULT_WINDOW.nameOffsetY)
		local valueV = normalizeAnchorV(config.valueAnchorV)
		local valueOffsetX = clampNumber(config.valueOffsetX, -200, 200, DEFAULT_WINDOW.valueOffsetX)
		local valueOffsetY = clampNumber(config.valueOffsetY, -200, 200, DEFAULT_WINDOW.valueOffsetY)
		local previousColumn
		if showPercent and row.percentValue then
			row.percentValue:SetPoint(anchorPoint("RIGHT", valueV), rightAnchor, anchorPoint("RIGHT", valueV), rightOffset + valueOffsetX, valueOffsetY)
			row.percentValue:SetJustifyH("RIGHT")
			previousColumn = row.percentValue
			rightOffset = -columnGap
		end
		if showRate and row.rateValue then
			if previousColumn then
				row.rateValue:SetPoint(anchorPoint("RIGHT", valueV), previousColumn, anchorPoint("LEFT", valueV), rightOffset, 0)
			else
				row.rateValue:SetPoint(anchorPoint("RIGHT", valueV), rightAnchor, anchorPoint("RIGHT", valueV), rightOffset + valueOffsetX, valueOffsetY)
			end
			row.rateValue:SetJustifyH("RIGHT")
			previousColumn = row.rateValue
			rightOffset = -columnGap
		end
		if showAmount then
			if previousColumn then
				row.value:SetPoint(anchorPoint("RIGHT", valueV), previousColumn, anchorPoint("LEFT", valueV), rightOffset, 0)
			else
				row.value:SetPoint(anchorPoint("RIGHT", valueV), rightAnchor, anchorPoint("RIGHT", valueV), rightOffset + valueOffsetX, valueOffsetY)
			end
			row.value:SetJustifyH("RIGHT")
			previousColumn = row.value
		end
		if rankPrefixText then
			row.rank:SetPoint(anchorPoint("LEFT", nameV), row.textArea, anchorPoint("LEFT", nameV), nameOffsetX, nameOffsetY)
			row.name:SetPoint("LEFT", row.rank, "RIGHT", rankGap, 0)
		else
			row.name:SetPoint(anchorPoint("LEFT", nameV), row.textArea, anchorPoint("LEFT", nameV), nameOffsetX, nameOffsetY)
		end
		if previousColumn then
			row.name:SetPoint(anchorPoint("RIGHT", nameV), previousColumn, anchorPoint("LEFT", nameV), -nameValueGap + nameOffsetX, nameOffsetY)
		else
			row.name:SetPoint(anchorPoint("RIGHT", nameV), row.textArea, anchorPoint("RIGHT", nameV), -2 + nameOffsetX, nameOffsetY)
		end
		row.name:SetJustifyH("LEFT")
		return
	end

	local maxValueWidth = math.max(1, availableWidth - minNameWidth - nameGap - rankPrefixWidth)
	local valueMode = getRowValueMode(damageMeterType, config)
	local estimatedCharacters
	if isCountOnlyMeterType(damageMeterType) then
		estimatedCharacters = config.showPercent ~= false and 10 or 4
	elseif valueMode == "amount" or valueMode == "perSecond" then
		estimatedCharacters = config.showPercent ~= false and 15 or 9
	elseif config.showPercent ~= false then
		estimatedCharacters = config.valueFormat == "parentheses" and 22 or 24
	else
		estimatedCharacters = config.valueFormat == "parentheses" and 16 or 18
	end
	local valueTargetWidth = math.ceil((valueFontSize * estimatedCharacters * 0.62) + 12)
	local minValueWidth
	if isCountOnlyMeterType(damageMeterType) then
		minValueWidth = 42
	elseif valueMode == "amount" or valueMode == "perSecond" then
		minValueWidth = 58
	else
		minValueWidth = config.valueFormat == "parentheses" and 76 or 86
	end
	local valueWidth = math.min(math.max(minValueWidth, valueTargetWidth), maxValueWidth)
	local nameWidth = math.max(minNameWidth, availableWidth - valueWidth - nameGap - rankPrefixWidth)
	row.value:SetWidth(valueWidth)
	row.name:SetWidth(nameWidth)
	row.name._damageMeterNameLayoutWidth = nameWidth
	row.rank:SetWidth(rankWidth)
	row.value:SetShown(true)
	if row.rateValue then row.rateValue:Hide() end
	if row.percentValue then row.percentValue:Hide() end

	row.value:ClearAllPoints()
	row.name:ClearAllPoints()
	if row.rateValue then row.rateValue:ClearAllPoints() end
	if row.percentValue then row.percentValue:ClearAllPoints() end
	if rankPrefixText then row.rank:ClearAllPoints() end
	local valueH = "RIGHT"
	local valueV = normalizeAnchorV(config.valueAnchorV)
	local nameH = "LEFT"
	local nameV = normalizeAnchorV(config.nameAnchorV)
	row.value:SetPoint(anchorPoint(valueH, valueV), row.textArea, anchorPoint(valueH, valueV), clampNumber(config.valueOffsetX, -200, 200, DEFAULT_WINDOW.valueOffsetX), clampNumber(config.valueOffsetY, -200, 200, DEFAULT_WINDOW.valueOffsetY))
	row.value:SetJustifyH(justifyFromAnchor(valueH))
	if rankPrefixText then
		local rankLeft = anchorPoint("LEFT", nameV)
		row.rank:SetPoint(rankLeft, row.textArea, rankLeft, clampNumber(config.nameOffsetX, -200, 200, DEFAULT_WINDOW.nameOffsetX), clampNumber(config.nameOffsetY, -200, 200, DEFAULT_WINDOW.nameOffsetY))
		row.name:SetPoint(anchorPoint("LEFT", nameV), row.rank, anchorPoint("RIGHT", nameV), rankGap, 0)
	else
		row.name:SetPoint(anchorPoint(nameH, nameV), row.textArea, anchorPoint(nameH, nameV), clampNumber(config.nameOffsetX, -200, 200, DEFAULT_WINDOW.nameOffsetX), clampNumber(config.nameOffsetY, -200, 200, DEFAULT_WINDOW.nameOffsetY))
	end
	row.name:SetJustifyH(justifyFromAnchor(nameH))
end

function DamageMeter:ApplyRankText(row, rowIndex, config)
	local rankWidth = getEffectiveRankWidth(config)
	if config.showRanks == false or rankWidth <= 0 then
		row.rank:SetText("")
		return
	end

	local text = rowIndex .. "."
	row.rank:SetText(text)
end

function DamageMeter:ShowTooltip(owner, text)
	if not GameTooltip or not text then return end
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:SetText(text)
	GameTooltip:Show()
end

function DamageMeter:CreateContextMenuIconButton(frame, label, tooltipText, onClick)
	local button = CreateFrame("Button", nil, frame)
	button:SetSize(18, 18)
	button:SetScript("OnClick", onClick)
	button:SetScript("OnEnter", function(owner)
		button.bg:SetColorTexture(0.18, 0.18, 0.18, 0.95)
		self:ShowTooltip(owner, tooltipText)
	end)
	button:SetScript("OnLeave", function()
		button.bg:SetColorTexture(0.07, 0.07, 0.07, 0.85)
		if GameTooltip then GameTooltip:Hide() end
	end)
	button.bg = button:CreateTexture(nil, "BACKGROUND")
	button.bg:SetAllPoints()
	button.bg:SetColorTexture(0.07, 0.07, 0.07, 0.85)
	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.text:SetAllPoints()
	button.text:SetJustifyH("CENTER")
	button.text:SetText(label)
	return button
end

function DamageMeter:CreateHeaderButton(frame, label, atlas, tooltipText, onClick)
	local button = CreateFrame("Button", nil, frame)
	button:SetSize(16, 16)
	button:SetScript("OnClick", onClick)
	button:SetScript("OnEnter", function(owner)
		DamageMeter:SetWindowHover(frame.index, true)
		frame._damageMeterHeaderButtonHover = true
		DamageMeter:UpdateHeaderButtonAlpha(frame)
		self:ShowTooltip(owner, tooltipText)
	end)
	button:SetScript("OnLeave", function()
		frame._damageMeterHeaderButtonHover = nil
		DamageMeter:UpdateHeaderButtonAlpha(frame)
		if GameTooltip then GameTooltip:Hide() end
		DamageMeter:SetWindowHover(frame.index, false)
	end)
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetPoint("CENTER")
	button.icon:SetSize(14, 14)
	local hasAtlas = atlas ~= nil
	if hasAtlas then
		button.icon:SetAtlas(atlas)
	end
	button.icon:SetShown(hasAtlas == true)
	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.text:SetAllPoints()
	button.text:SetJustifyH("CENTER")
	button.text:SetText(label)
	button.text:SetShown(hasAtlas ~= true)
	return button
end

function DamageMeter:UpdateHeaderButtonAlpha(frame)
	if not frame then return end
	local alpha
	if frame._damageMeterHeaderButtonFadeEnabled and not frame._damageMeterHeaderButtonHover then
		alpha = frame._damageMeterHeaderButtonFadeAlpha or DEFAULT_WINDOW.headerButtonFadeAlpha
	else
		alpha = frame._damageMeterHeaderButtonAlpha or DEFAULT_WINDOW.headerButtonAlpha
	end
	if frame._damageMeterHeaderButtonAppliedAlpha == alpha then return end
	frame._damageMeterHeaderButtonAppliedAlpha = alpha
	if frame.headerButtons then frame.headerButtons:SetAlpha(alpha) end
	if frame.resetButton then frame.resetButton:SetAlpha(alpha) end
	if frame.historyButton then frame.historyButton:SetAlpha(alpha) end
	if frame.reportButton then frame.reportButton:SetAlpha(alpha) end
end

function DamageMeter:ApplyHeaderButtons(frame, config, showHeaderButtons)
	local buttonSize = clampNumber(config.headerButtonSize, 10, 32, DEFAULT_WINDOW.headerButtonSize)
	local gap = math.max(2, math.floor(buttonSize / 4))
	local iconSize = math.max(8, buttonSize - 2)
	local showReportButton = showHeaderButtons and config.showHeaderReportButton ~= false
	local buttonCount = showReportButton and 3 or 2
	local color = normalizeColor(config.headerButtonColor, DEFAULT_WINDOW.headerButtonColor)
	local alpha = clampNumber(config.headerButtonAlpha, 0, 1, DEFAULT_WINDOW.headerButtonAlpha)
	local fadeAlpha = clampNumber(config.headerButtonFadeAlpha, 0, 1, DEFAULT_WINDOW.headerButtonFadeAlpha)
	local fadeEnabled = config.headerButtonFadeEnabled == true
	local signature = buttonSize .. ":" .. gap .. ":" .. iconSize .. ":" .. tostring(showHeaderButtons == true) .. ":" .. tostring(showReportButton == true)
	if frame.headerButtons._damageMeterHeaderButtonsSignature ~= signature then
		frame.headerButtons._damageMeterHeaderButtonsSignature = signature
		frame.headerButtons:SetSize((buttonSize * buttonCount) + (gap * math.max(0, buttonCount - 1)), buttonSize)
		frame.resetButton:SetSize(buttonSize, buttonSize)
		frame.historyButton:SetSize(buttonSize, buttonSize)
		frame.reportButton:SetSize(buttonSize, buttonSize)
		frame.resetButton.icon:SetSize(iconSize, iconSize)
		frame.historyButton.icon:SetSize(iconSize, iconSize)
		frame.reportButton.icon:SetSize(iconSize, iconSize)
		frame.resetButton:ClearAllPoints()
		frame.resetButton:SetPoint("RIGHT", frame.headerButtons, "RIGHT", 0, 0)
		frame.historyButton:ClearAllPoints()
		frame.historyButton:SetPoint("RIGHT", frame.resetButton, "LEFT", -gap, 0)
		frame.reportButton:ClearAllPoints()
		frame.reportButton:SetPoint("RIGHT", frame.historyButton, "LEFT", -gap, 0)
		setShownIfChanged(frame.headerButtons, showHeaderButtons)
		setShownIfChanged(frame.resetButton, showHeaderButtons)
		setShownIfChanged(frame.historyButton, showHeaderButtons)
		setShownIfChanged(frame.reportButton, showReportButton)
	end
	if frame.headerButtons._damageMeterHeaderButtonColorR ~= color.r
		or frame.headerButtons._damageMeterHeaderButtonColorG ~= color.g
		or frame.headerButtons._damageMeterHeaderButtonColorB ~= color.b
		or frame.headerButtons._damageMeterHeaderButtonColorA ~= color.a then
		frame.headerButtons._damageMeterHeaderButtonColorR = color.r
		frame.headerButtons._damageMeterHeaderButtonColorG = color.g
		frame.headerButtons._damageMeterHeaderButtonColorB = color.b
		frame.headerButtons._damageMeterHeaderButtonColorA = color.a
		frame.resetButton.icon:SetVertexColor(color.r, color.g, color.b, color.a)
		frame.historyButton.icon:SetVertexColor(color.r, color.g, color.b, color.a)
		frame.reportButton.icon:SetVertexColor(color.r, color.g, color.b, color.a)
		frame.resetButton.text:SetTextColor(color.r, color.g, color.b, color.a)
		frame.historyButton.text:SetTextColor(color.r, color.g, color.b, color.a)
		frame.reportButton.text:SetTextColor(color.r, color.g, color.b, color.a)
	end
	frame._damageMeterHeaderButtonAlpha = alpha
	frame._damageMeterHeaderButtonFadeAlpha = fadeAlpha
	frame._damageMeterHeaderButtonFadeEnabled = fadeEnabled
	if not showHeaderButtons then frame._damageMeterHeaderButtonHover = nil end
	self:UpdateHeaderButtonAlpha(frame)
	return showHeaderButtons and ((buttonSize * buttonCount) + (gap * math.max(0, buttonCount - 1)) + 12) or 8
end

function DamageMeter:EnsureContextMenu()
	if self.contextMenu then return self.contextMenu end
	local frame = CreateFrame("Frame", host.framePrefix .. "ContextMenu", UIParent, "BackdropTemplate")
	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(80)
	frame:SetClampedToScreen(true)
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:SetWidth(CONTEXT_MENU_WIDTH)
	frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	frame:SetBackdropColor(0.015, 0.016, 0.018, 0.94)
	frame:SetBackdropBorderColor(0.16, 0.18, 0.2, 0.9)
	frame:Hide()
	frame.buttons = {}
	frame.clickCatcher = CreateFrame("Button", nil, UIParent)
	frame.clickCatcher:SetFrameStrata("DIALOG")
	frame.clickCatcher:SetFrameLevel(79)
	frame.clickCatcher:SetAllPoints(UIParent)
	frame.clickCatcher:EnableMouse(true)
	frame.clickCatcher:RegisterForClicks("AnyUp")
	frame.clickCatcher:SetScript("OnClick", function() self:HideContextMenu() end)
	frame.clickCatcher:Hide()
	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.title:SetJustifyH("LEFT")
	frame.title:SetWordWrap(false)
	frame.addLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	frame.addLabel:SetJustifyH("CENTER")
	frame.addLabel:SetWordWrap(false)
	frame.modeHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	frame.modeHint:SetJustifyH("RIGHT")
	frame.modeHint:SetWordWrap(false)
	frame.resetButton = self:CreateContextMenuIconButton(frame, "R", L["damageMeterResetData"] or "Reset data", function()
		self:HideContextMenu()
		self:PromptResetData()
	end)
	frame.historyButton = self:CreateContextMenuIconButton(frame, "H", L["damageMeterShowHistory"] or "Show history", function()
		local owner = frame.owner or frame
		local index = frame.index or 1
		self:HideContextMenu()
		self:OpenHistoryMenu(owner, index)
	end)
	frame.clearButton = self:CreateContextMenuIconButton(frame, "X", L["damageMeterResetTemporarySelection"] or "Reset temporary selection", function()
		local index = frame.index or 1
		self:HideContextMenu()
		self:ClearTemporarySelection(index)
	end)
	frame:SetScript("OnHide", function()
		if GameTooltip then GameTooltip:Hide() end
		if frame.clickCatcher then frame.clickCatcher:Hide() end
	end)
	if UISpecialFrames then
		UISpecialFrames[#UISpecialFrames + 1] = frame:GetName()
	end
	self.contextMenu = frame
	return frame
end

function DamageMeter:HideContextMenu()
	if self.contextMenu then
		if self.contextMenu.clickCatcher then self.contextMenu.clickCatcher:Hide() end
		self.contextMenu.owner = nil
		self.contextMenu.index = nil
		self.contextMenu:Hide()
	end
end

function DamageMeter:IsContextMenuOpenFor(index)
	local frame = self.contextMenu
	return frame and frame:IsShown() and (tonumber(index) or 1) == (tonumber(frame.index) or 1)
end

function DamageMeter:GetContextMenuButton(frame, buttonIndex)
	local button = frame.buttons[buttonIndex]
	if button then return button end
	button = CreateFrame("Button", nil, frame)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
	button:SetHeight(CONTEXT_MENU_BUTTON_HEIGHT)
	button.bg = button:CreateTexture(nil, "BACKGROUND")
	button.bg:SetAllPoints()
	button.bg:SetColorTexture(0.06, 0.065, 0.07, 0.92)
	button.icon = button:CreateTexture(nil, "ARTWORK")
	button.icon:SetPoint("LEFT", 9, 0)
	button.icon:SetSize(18, 18)
	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	button.text:SetPoint("LEFT", button.icon, "RIGHT", 8, 0)
	button.text:SetPoint("RIGHT", -28, 0)
	button.text:SetJustifyH("LEFT")
	button.text:SetWordWrap(false)
	button.rightText = button:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	button.rightText:SetPoint("RIGHT", -8, 0)
	button.rightText:SetJustifyH("RIGHT")
	button.rightText:SetWordWrap(false)
	button.removeButton = CreateFrame("Button", nil, button)
	button.removeButton:SetSize(18, 18)
	button.removeButton:SetPoint("RIGHT", -3, 0)
	button.removeButton:SetFrameLevel(button:GetFrameLevel() + 3)
	button.removeButton:RegisterForClicks("AnyUp")
	button.removeButton.text = button.removeButton:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	button.removeButton.text:SetAllPoints()
	button.removeButton.text:SetJustifyH("CENTER")
	button.removeButton.text:SetText("X")
	button.removeButton.text:SetTextColor(0.55, 0.58, 0.6, 1)
	button.removeButton:SetScript("OnEnter", function(owner)
		owner.text:SetTextColor(1, 0.25, 0.25, 1)
	end)
	button.removeButton:SetScript("OnLeave", function(owner)
		owner.text:SetTextColor(0.55, 0.58, 0.6, 1)
	end)
	button:SetScript("OnEnter", function(owner)
		local selected = owner.selected == true
		owner.bg:SetColorTexture(selected and 0.03 or 0.12, selected and 0.24 or 0.13, selected and 0.21 or 0.15, 0.96)
	end)
	button:SetScript("OnLeave", function(owner)
		if owner.selected == true then
			owner.bg:SetColorTexture(0.02, 0.19, 0.17, 0.95)
		else
			owner.bg:SetColorTexture(0.06, 0.065, 0.07, 0.92)
		end
	end)
	frame.buttons[buttonIndex] = button
	return button
end

function DamageMeter:SetupContextMenuButton(button, label, icon, selected, rightText, onClick, disabled, onRemove)
	button.selected = selected == true
	button.disabled = disabled == true
	button:SetEnabled(disabled ~= true)
	button:SetAlpha(disabled and 0.45 or 1)
	button.bg:SetColorTexture(selected and 0.02 or 0.06, selected and 0.19 or 0.065, selected and 0.17 or 0.07, selected and 0.95 or 0.92)
	button.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
	button.text:SetText(label or "")
	button.rightText:SetText(rightText or "")
	button:SetScript("OnClick", onClick)
	button.removeButton:SetShown(type(onRemove) == "function")
	button.removeButton:SetScript("OnClick", onRemove)
	button:Show()
end

function DamageMeter:AnchorContextMenu(frame, owner)
	frame:ClearAllPoints()
	if GetCursorPosition and UIParent and UIParent.GetEffectiveScale then
		local scale = UIParent:GetEffectiveScale()
		local cursorX, cursorY = GetCursorPosition()
		if scale and scale > 0 and cursorX and cursorY then
			frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (cursorX / scale) + 6, (cursorY / scale) - 6)
			return
		end
	end
	frame:SetPoint("TOPLEFT", owner or UIParent, "BOTTOMLEFT", 0, -4)
end

function DamageMeter:RefreshContextMenu(owner, index, keepAnchor)
	local frame = self:EnsureContextMenu()
	index = tonumber(index) or 1
	frame.owner = owner or frame.owner
	frame.index = index

	local effectiveType = self:GetEffectiveDamageMeterType(index)
	local typeLabel = getDamageMeterTypeLabel(effectiveType)
	local durationText = formatDuration(self:GetSessionDuration(index, self:GetSession(index)), "clock")
	frame.title:SetText(durationText and string.format("%s (%s)", typeLabel, durationText) or typeLabel)

	local pad = CONTEXT_MENU_PADDING
	local y = -pad
	frame.title:ClearAllPoints()
	frame.title:SetPoint("TOPLEFT", pad, y)
	frame.title:SetPoint("TOPRIGHT", -84, y)
	frame.title:SetHeight(18)
	frame.clearButton:ClearAllPoints()
	frame.clearButton:SetPoint("TOPRIGHT", -pad, y + 1)
	frame.historyButton:ClearAllPoints()
	frame.historyButton:SetPoint("RIGHT", frame.clearButton, "LEFT", -4, 0)
	frame.resetButton:ClearAllPoints()
	frame.resetButton:SetPoint("RIGHT", frame.historyButton, "LEFT", -4, 0)
	y = y - 24

	local buttonIndex = 1
	frame.addLabel:SetText(L["damageMeterQuickSwitch"] or "Quick switch")
	frame.addLabel:ClearAllPoints()
	frame.addLabel:SetPoint("TOPLEFT", pad, y + 1)
	frame.addLabel:SetPoint("TOPRIGHT", -pad, y + 1)
	frame.addLabel:SetHeight(16)
	y = y - 20

	local quickTypes = self:GetQuickDamageMeterTypes(index)
	local quickSeen = {}
	for _, quickType in ipairs(quickTypes) do
		quickSeen[quickType] = true
		local button = self:GetContextMenuButton(frame, buttonIndex)
		self:SetupContextMenuButton(button, getDamageMeterTypeLabel(quickType), getDamageMeterTypeIcon(quickType), effectiveType == quickType, nil, function(_, mouseButton)
			if mouseButton == "RightButton" or mouseButton == "MiddleButton" then
				self:RemoveQuickDamageMeterType(index, quickType)
				self:RefreshContextMenu(owner, index, true)
				return
			end
			self:HideContextMenu()
			self:SetTemporaryDamageMeterType(index, quickType)
		end, false, function()
			self:RemoveQuickDamageMeterType(index, quickType)
			self:RefreshContextMenu(owner, index, true)
		end)
		button:ClearAllPoints()
		button:SetPoint("TOPLEFT", pad, y)
		button:SetPoint("TOPRIGHT", -pad, y)
		buttonIndex = buttonIndex + 1
		y = y - CONTEXT_MENU_BUTTON_HEIGHT - CONTEXT_MENU_BUTTON_GAP
	end

	y = y - CONTEXT_MENU_BUTTON_GAP
	frame.modeHint:SetText(_G.ADD or "Add")
	frame.modeHint:ClearAllPoints()
	frame.modeHint:SetPoint("TOPLEFT", pad, y + 1)
	frame.modeHint:SetPoint("TOPRIGHT", -pad, y + 1)
	frame.modeHint:SetJustifyH("CENTER")
	frame.modeHint:SetHeight(16)
	y = y - 20

	local options = buildDamageMeterTypeOptions()
	local columns = 2
	local columnGap = CONTEXT_MENU_BUTTON_GAP
	local buttonWidth = (CONTEXT_MENU_WIDTH - (pad * 2) - columnGap) / columns
	local addIndex = 0
	for _, option in ipairs(options) do
		if not quickSeen[option.value] then
			addIndex = addIndex + 1
			local button = self:GetContextMenuButton(frame, buttonIndex)
			local optionValue = option.value
			self:SetupContextMenuButton(button, option.label, getDamageMeterTypeIcon(optionValue), false, nil, function()
				self:AddQuickDamageMeterType(index, optionValue)
				self:HideContextMenu()
				self:SetTemporaryDamageMeterType(index, optionValue)
			end)
			button:ClearAllPoints()
			local column = (addIndex - 1) % columns
			local row = math.floor((addIndex - 1) / columns)
			button:SetPoint("TOPLEFT", pad + (column * (buttonWidth + columnGap)), y - (row * (CONTEXT_MENU_BUTTON_HEIGHT + CONTEXT_MENU_BUTTON_GAP)))
			button:SetSize(buttonWidth, CONTEXT_MENU_BUTTON_HEIGHT)
			buttonIndex = buttonIndex + 1
		end
	end
	local rows = addIndex > 0 and math.ceil(addIndex / columns) or 0
	y = y - (rows * (CONTEXT_MENU_BUTTON_HEIGHT + CONTEXT_MENU_BUTTON_GAP))
	for unusedIndex = buttonIndex, #frame.buttons do
		frame.buttons[unusedIndex]:Hide()
	end

	frame:SetHeight(math.abs(y) + pad)
	if keepAnchor ~= true then
		self:AnchorContextMenu(frame, owner)
	end
	if frame.clickCatcher then frame.clickCatcher:Show() end
	frame:Show()
end

function DamageMeter:BuildSessionMenu(index, rootDescription)
	local effectiveSessionID = self:GetEffectiveSessionID(index)
	for _, availableCombatSession in ipairs(self:GetAvailableCombatSessions()) do
		local sessionID = safeNumber(availableCombatSession.sessionID)
		if sessionID then
			local sessionName = safeText(availableCombatSession.name, nil)
			if not sessionName then
				sessionName = DAMAGE_METER_COMBAT_NUMBER and DAMAGE_METER_COMBAT_NUMBER:format(sessionID) or string.format("%s %d", L["damageMeterCombat"] or "Combat", sessionID)
			end
			local durationText = formatHistoryDuration(availableCombatSession.durationSeconds)
			local label = durationText and string.format("%s [%s]", sessionName, durationText) or sessionName
			rootDescription:CreateRadio(label, function(value) return effectiveSessionID == value.sessionID end, function(value) self:SetTemporarySessionID(index, value.sessionID, value.name, value.durationSeconds) end, {
				sessionID = sessionID,
				name = sessionName,
				durationSeconds = safeNumber(availableCombatSession.durationSeconds),
			})
		end
	end

	rootDescription:CreateDivider()
	rootDescription:CreateRadio(L["damageMeterCurrent"] or "Current", function() return not self:GetEffectiveSessionID(index) and self:GetEffectiveSessionType(index) == "current" end, function() self:SetTemporarySessionType(index, "current") end)
	rootDescription:CreateRadio(L["damageMeterOverall"] or "Overall", function() return not self:GetEffectiveSessionID(index) and self:GetEffectiveSessionType(index) == "overall" end, function() self:SetTemporarySessionType(index, "overall") end)
end

function DamageMeter:OpenContextMenu(owner, index)
	if self:IsContextMenuOpenFor(index) then return end
	self:RefreshContextMenu(owner, index)
end

function DamageMeter:IsHistoryHoverMenuHovered()
	local owner = self.historyHoverOwner
	local menu = self.historyHoverMenu
	if owner and owner.IsMouseOver and owner:IsMouseOver() then return true end
	if menu and menu.IsMouseOver and menu:IsMouseOver() then return true end
	return false
end

function DamageMeter:CloseHistoryHoverMenu()
	local menu = self.historyHoverMenu
	self.historyHoverMenu = nil
	self.historyHoverOwner = nil
	if menu and menu.Close then
		menu:Close()
	elseif Menu and Menu.GetManager then
		Menu.GetManager():CloseMenus()
	end
end

function DamageMeter:ScheduleHistoryHoverMenuClose(token)
	if not C_Timer or not C_Timer.After then return end
	C_Timer.After(0.28, function()
		if token ~= self.historyHoverToken or not self.historyHoverMenu then return end
		if self:IsHistoryHoverMenuHovered() then
			self:ScheduleHistoryHoverMenuClose(token)
			return
		end
		self:CloseHistoryHoverMenu()
	end)
end

function DamageMeter:OpenHistoryMenu(owner, index, hoverMode)
	if not MenuUtil or not MenuUtil.CreateContextMenu then return end

	if hoverMode and self.historyHoverMenu and self.historyHoverOwner == owner then
		self.historyHoverToken = (self.historyHoverToken or 0) + 1
		self:ScheduleHistoryHoverMenuClose(self.historyHoverToken)
		return
	end

	if hoverMode and Menu and Menu.GetManager and AnchorUtil and MenuUtil.CreateRootMenuDescription then
		local menuVariants = _G.MenuVariants
		local menuMixin = owner and owner.menuMixin or (menuVariants and menuVariants.GetDefaultContextMenuMixin and menuVariants.GetDefaultContextMenuMixin()) or nil
		local rootDescription = MenuUtil.CreateRootMenuDescription(menuMixin)
		rootDescription:SetTag(host.menuHistoryTag)
		self:BuildSessionMenu(index, rootDescription)

		local anchor = AnchorUtil.CreateAnchor("TOPRIGHT", owner, "BOTTOMRIGHT", 0, -2)
		local menu = Menu.GetManager():OpenMenu(owner, rootDescription, anchor)
		if menu then
			self.historyHoverMenu = menu
			self.historyHoverOwner = owner
			self.historyHoverToken = (self.historyHoverToken or 0) + 1
			self:ScheduleHistoryHoverMenuClose(self.historyHoverToken)
		end
		return
	end

	local menu = MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
		rootDescription:SetTag(host.menuHistoryTag)
		self:BuildSessionMenu(index, rootDescription)
	end)
	if hoverMode and menu then
		self.historyHoverMenu = menu
		self.historyHoverOwner = owner
		self.historyHoverToken = (self.historyHoverToken or 0) + 1
		self:ScheduleHistoryHoverMenuClose(self.historyHoverToken)
	end
end

function DamageMeter:EnsureSourceTooltip()
	if self.sourceTooltip then return self.sourceTooltip end
	local frame = CreateFrame("Frame", host.framePrefix .. "SourceTooltip", UIParent, "BackdropTemplate")
	frame:SetFrameStrata("TOOLTIP")
	frame:SetFrameLevel(20)
	if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
	frame:Hide()
	frame.lines = {}
	frame.border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	frame.border:EnableMouse(false)
	frame.border:SetFrameLevel(frame:GetFrameLevel() + 2)
	self.sourceTooltip = frame
	return frame
end

function DamageMeter:GetTooltipLine(frame, lineIndex)
	local line = frame.lines[lineIndex]
	if line then return line end
	line = CreateFrame("Frame", nil, frame)
	line:SetHeight(18)
	line.icon = line:CreateTexture(nil, "ARTWORK")
	line.icon:SetSize(16, 16)
	line.icon:SetPoint("LEFT", 6, 0)
	line.iconBorder = CreateFrame("Frame", nil, line, "BackdropTemplate")
	line.iconBorder:EnableMouse(false)
	line.barBG = line:CreateTexture(nil, "BACKGROUND")
	line.bar = CreateFrame("StatusBar", nil, line)
	line.bar:SetPoint("TOPLEFT", line.icon, "TOPRIGHT", 4, 0)
	line.bar:SetPoint("BOTTOMLEFT", line.icon, "BOTTOMRIGHT", 4, 0)
	line.bar:SetFrameLevel(line:GetFrameLevel() + 1)
	line.rowBorder = CreateFrame("Frame", nil, line, "BackdropTemplate")
	line.rowBorder:EnableMouse(false)
	line.rowBorder:SetFrameLevel(line.bar:GetFrameLevel() + 2)
	line.barBorder = CreateFrame("Frame", nil, line, "BackdropTemplate")
	line.barBorder:EnableMouse(false)
	line.barBorder:SetFrameLevel(line.bar:GetFrameLevel() + 3)
	line.iconBorder:SetFrameLevel(line.bar:GetFrameLevel() + 3)
	line.textLayer = CreateFrame("Frame", nil, line)
	line.textLayer:SetAllPoints()
	line.textLayer:SetFrameLevel(line.bar:GetFrameLevel() + 4)
	line.name = line.textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	line.name:SetPoint("LEFT", line.icon, "RIGHT", 4, 0)
	line.name:SetJustifyH("LEFT")
	line.name:SetWordWrap(false)
	line.amount = line.textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	line.amount:SetJustifyH("RIGHT")
	line.amount:SetWordWrap(false)
	line.dps = line.textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	line.dps:SetJustifyH("RIGHT")
	line.dps:SetWordWrap(false)
	line.percent = line.textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	line.percent:SetJustifyH("RIGHT")
	line.percent:SetWordWrap(false)
	frame.lines[lineIndex] = line
	return line
end

function DamageMeter:AnchorSourceTooltip(frame, owner, config)
	frame:ClearAllPoints()
	local anchor = normalizeTooltipAnchor(config.tooltipAnchor)
	local anchorV = normalizeAnchorV(config.tooltipAnchorV)
	local offsetX = clampNumber(config.tooltipOffsetX, -300, 300, DEFAULT_WINDOW.tooltipOffsetX)
	local offsetY = clampNumber(config.tooltipOffsetY, -300, 300, DEFAULT_WINDOW.tooltipOffsetY)
	if anchor == "LEFT" then
		if anchorV == "TOP" then
			frame:SetPoint("TOPRIGHT", owner, "TOPLEFT", -offsetX, offsetY)
		elseif anchorV == "BOTTOM" then
			frame:SetPoint("BOTTOMRIGHT", owner, "BOTTOMLEFT", -offsetX, offsetY)
		else
			frame:SetPoint("RIGHT", owner, "LEFT", -offsetX, offsetY)
		end
	elseif anchor == "TOP" then
		frame:SetPoint("BOTTOMLEFT", owner, "TOPLEFT", offsetX, offsetY)
	elseif anchor == "BOTTOM" then
		frame:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", offsetX, -offsetY)
	else
		if anchorV == "TOP" then
			frame:SetPoint("TOPLEFT", owner, "TOPRIGHT", offsetX, offsetY)
		elseif anchorV == "BOTTOM" then
			frame:SetPoint("BOTTOMLEFT", owner, "BOTTOMRIGHT", offsetX, offsetY)
		else
			frame:SetPoint("LEFT", owner, "RIGHT", offsetX, offsetY)
		end
	end
end

local function addTooltipSectionGap(rows)
	rows[#rows + 1] = { spacer = true, heightMultiplier = 0.7 }
end

local function resolveCombatSpellDisplay(spell, config)
	if not spell then return L["Unknown"] or UNKNOWN or "Unknown", 136243 end
	local spellID = spell.spellID
	local spellName
	local spellIcon
	if spellID and C_Spell then
		if C_Spell.GetSpellInfo then
			local spellInfo = C_Spell.GetSpellInfo(spellID)
			if type(spellInfo) == "table" then
				spellName = spellInfo.name
				spellIcon = spellInfo.iconID
			end
		end
		if not spellName and C_Spell.GetSpellName then
			spellName = C_Spell.GetSpellName(spellID)
		end
		if not spellIcon and C_Spell.GetSpellTexture then
			spellIcon = C_Spell.GetSpellTexture(spellID)
		end
	end
	if not spellName then
		local creatureName = spell.creatureName
		if creatureName and isSecret(creatureName) then
			spellName = creatureName
		elseif creatureName and tostring(creatureName) ~= "" then
			spellName = tostring(creatureName)
		else
			spellName = L["Unknown"] or UNKNOWN or "Unknown"
		end
	end
	if config and config.tooltipShowCreatureName ~= false and spellName and spell.creatureName ~= nil and not isSecret(spellName) and not isSecret(spell.creatureName) then
		local creatureName = tostring(spell.creatureName)
		if creatureName ~= "" then
			local colorHex = colorToHex(config.tooltipCreatureNameColor, DEFAULT_WINDOW.tooltipCreatureNameColor)
			spellName = string.format("%s |c%s(%s)|r", spellName, colorHex, creatureName)
		end
	end
	return spellName, spellIcon or 136243
end

getTooltipColumnVisibility = function(config, damageMeterType)
	local showAmount = config.tooltipShowAmount ~= false
	local showDPS = config.tooltipShowDPS ~= false
	local showPercent = config.tooltipShowPercent ~= false
	if damageMeterType == "Deaths" or damageMeterType == "Dispels" or damageMeterType == "Interrupts" then
		showDPS = false
	end
	if damageMeterType == "Dps" or damageMeterType == "Hps" then
		showAmount = false
	end
	return showAmount, showDPS, showPercent
end

function DamageMeter:GetTooltipRateColumnLabel(damageMeterType)
	if damageMeterType == "HealingDone" or damageMeterType == "Hps" then
		return getDamageMeterTypeLabel("Hps") or "HPS"
	end
	return L["damageMeterTooltipDPS"] or "DPS"
end

resolveTooltipUnitName = function(value, config)
	if value == nil then return nil end
	if isSecret(value) then return value end
	value = tostring(value)
	if value == "" then return nil end
	return formatSourceName(value, config or DEFAULT_WINDOW)
end

damageMeterNamesMatch = function(left, right)
	if left == nil or right == nil or isSecret(left) or isSecret(right) then return false end
	left = tostring(left)
	right = tostring(right)
	if left == "" or right == "" then return false end
	if left == right then return true end
	if Ambiguate then
		local shortLeft = Ambiguate(left, "short")
		local shortRight = Ambiguate(right, "short")
		return shortLeft ~= nil and shortLeft ~= "" and shortLeft == shortRight
	end
	return false
end

local function getTooltipBarValue(value)
	if not isSecret(value) and value == nil then return 0 end
	return value
end

local function getTooltipBarMax(value)
	if not isSecret(value) and (value == nil or value <= 0) then return 1 end
	return value
end

local function resolveDeathRecapEventDisplay(eventData)
	if type(eventData) ~= "table" then return L["Unknown"] or UNKNOWN or "Unknown", 136243 end
	local eventType = eventData.event
	local spellID = eventData.spellId
	local spellName = eventData.spellName
	local icon
	if eventType == "SWING_DAMAGE" then
		spellID = 88163
		spellName = ACTION_SWING or spellName
	elseif eventType == "ENVIRONMENTAL_DAMAGE" then
		local environmentalType = type(eventData.environmentalType) == "string" and string.upper(eventData.environmentalType) or ""
		spellName = _G["ACTION_ENVIRONMENTAL_DAMAGE_" .. environmentalType] or spellName or eventType
		if environmentalType == "DROWNING" then
			icon = "Interface\\Icons\\spell_shadow_demonbreath"
		elseif environmentalType == "FALLING" then
			icon = "Interface\\Icons\\ability_rogue_quickrecovery"
		elseif environmentalType == "FIRE" or environmentalType == "LAVA" then
			icon = "Interface\\Icons\\spell_fire_fire"
		elseif environmentalType == "SLIME" then
			icon = "Interface\\Icons\\inv_misc_slime_01"
		elseif environmentalType == "FATIGUE" then
			icon = "Interface\\Icons\\ability_creature_cursed_05"
		else
			icon = "Interface\\Icons\\ability_creature_cursed_05"
		end
	end
	if spellID and C_Spell and C_Spell.GetSpellTexture then
		local texture = C_Spell.GetSpellTexture(spellID)
		if texture then icon = texture end
	end
	return spellName or eventType or (L["Unknown"] or UNKNOWN or "Unknown"), icon or 136243
end

function DamageMeter:BuildDeathRecapRows(source, config)
	local rows = {}
	if not C_DeathRecap or not C_DeathRecap.GetRecapEvents or not source then return rows end
	local recapID = source.deathRecapID
	if not recapID or recapID == 0 then return rows end
	local events = C_DeathRecap.GetRecapEvents(recapID)
	if type(events) ~= "table" or #events == 0 then return rows end
	local maxHealth
	if C_DeathRecap.GetRecapMaxHealth then
		maxHealth = C_DeathRecap.GetRecapMaxHealth(recapID)
	end
	maxHealth = safeNumber(maxHealth)
	local showAmount, _, showPercent = getTooltipColumnVisibility(config, "Deaths")
	rows[#rows + 1] = { header = true, name = DEATH_RECAP_TITLE or getDamageMeterTypeLabel("Deaths"), icon = getDamageMeterTypeIcon("Deaths"), amount = showAmount and (L["damageMeterTooltipAmount"] or "Amount"), percent = showPercent and "%" }
	local deathTimestamp = 0
	for _, eventData in ipairs(events) do
		local timestamp = safeNumber(eventData.timestamp)
		if timestamp and timestamp > deathTimestamp then deathTimestamp = timestamp end
	end
	for eventIndex = #events, 1, -1 do
		local eventData = events[eventIndex]
		local spellName, spellIcon = resolveDeathRecapEventDisplay(eventData)
		local sourceName = safeText(eventData.sourceName)
		if sourceName then
			spellName = string.format("%s (%s)", spellName, sourceName)
		end
		local timestamp = safeNumber(eventData.timestamp)
		local seconds = timestamp and math.max(0, deathTimestamp - timestamp) or 0
		local amount = safeNumber(eventData.amount)
		local overkill = safeNumber(eventData.overkill)
		local amountText = amount and ("-" .. formatNumber(amount, config.abbreviation)) or nil
		if amountText and overkill and overkill > 0 then
			amountText = string.format("%s (%s %s)", amountText, formatNumber(overkill, config.abbreviation), _G.OVERKILL or "overkill")
		end
		local currentHP = safeNumber(eventData.currentHP)
		local percent = currentHP and maxHealth and maxHealth > 0 and (currentHP / maxHealth * 100) or nil
		rows[#rows + 1] = {
			name = string.format("-%.1fs %s", seconds, spellName),
			icon = spellIcon,
			amount = showAmount and amountText,
			percent = showPercent and percent and string.format("%.0f%%", percent),
			sortAmount = amount or 0,
			barValue = currentHP,
			barMax = maxHealth,
		}
	end
	return rows
end

function DamageMeter:BuildTooltipRows(details, config, damageMeterType, derivedTargetRows)
	local rows = {}
	if not details or type(details.combatSpells) ~= "table" then
		if type(derivedTargetRows) ~= "table" or #derivedTargetRows == 0 then return rows end
		details = { combatSpells = {} }
	end
	local showAmount, showDPS, showPercent = getTooltipColumnVisibility(config, damageMeterType)
	local showTargets = config.tooltipShowTargets ~= false and not (UnitAffectingCombat and UnitAffectingCombat("player"))
	local spellLimit = clampNumber(config.tooltipMaxLines, 4, 30, DEFAULT_WINDOW.tooltipMaxLines)
	local totalAmount = safeNumber(details.totalAmount)
	local showSpellSection = damageMeterType ~= "EnemyDamageTaken" and #details.combatSpells > 0
	local detailsMaxAmount = details.maxAmount
	local rateColumnLabel = self:GetTooltipRateColumnLabel(damageMeterType)

	if showSpellSection then
		rows[#rows + 1] = { header = true, name = L["damageMeterTooltipSpellName"] or "Spell Name", icon = "Interface\\WORLDSTATEFRAME\\CombatSwords", amount = showAmount and (L["damageMeterTooltipAmount"] or "Amount"), dps = showDPS and rateColumnLabel, percent = showPercent and "%" }
	end
	local targetMap = {}
	local directTargetRows = {}
	local spellMaxAmount = 0
	local spellMaxScanRows = 0
	for _, spell in ipairs(details.combatSpells) do
		if spellMaxScanRows >= spellLimit then break end
		local amount = safeNumber(spell.totalAmount)
		if amount and amount > spellMaxAmount then spellMaxAmount = amount end
		spellMaxScanRows = spellMaxScanRows + 1
	end
	local spellRows = 0
	for _, spell in ipairs(details.combatSpells) do
		local spellName, spellIcon = resolveCombatSpellDisplay(spell, config)
		local amount = spell.totalAmount
		local dps = spell.amountPerSecond
		local percent = totalAmount and totalAmount > 0 and safeNumber(amount) and (safeNumber(amount) / totalAmount * 100) or nil
		local target = spell.combatSpellDetails
		if showSpellSection and spellRows < spellLimit then
			rows[#rows + 1] = { name = spellName, icon = spellIcon, amount = showAmount and formatNumber(amount, config.abbreviation), dps = showDPS and formatNumber(dps, config.abbreviation), percent = showPercent and percent and string.format("%.1f%%", percent), sortAmount = safeNumber(amount) or 0, barValue = amount, barMax = detailsMaxAmount or spellMaxAmount }
			spellRows = spellRows + 1
		end

		if showTargets and type(target) == "table" then
			local targetName = resolveTooltipUnitName(target.unitName, config)
			if targetName ~= nil then
				local rawTargetAmount = damageMeterType == "EnemyDamageTaken" and spell.totalAmount or target.amount
				local targetAmount = safeNumber(rawTargetAmount)
				local targetDps = safeNumber(spell.amountPerSecond)
				if not isSecret(targetName) and targetAmount then
					local entry = targetMap[targetName]
					if not entry then
						entry = { name = targetName, amount = 0, dps = 0, classFilename = target.unitClassFilename }
						if damageMeterType == "EnemyDamageTaken" then
							entry.icon = target.specIconID ~= 0 and target.specIconID or 136243
						else
							entry.atlas = TOOLTIP_TARGET_ATLAS
						end
						targetMap[targetName] = entry
					end
					entry.amount = entry.amount + targetAmount
					entry.dps = entry.dps + (targetDps or 0)
				elseif not isSecret(targetName) and rawTargetAmount ~= nil and not isSecret(rawTargetAmount) then
					directTargetRows[#directTargetRows + 1] = {
						name = targetName,
						atlas = damageMeterType ~= "EnemyDamageTaken" and TOOLTIP_TARGET_ATLAS or nil,
						icon = damageMeterType == "EnemyDamageTaken" and (target.specIconID ~= 0 and target.specIconID or 136243) or nil,
						classFilename = target.unitClassFilename,
						amount = showAmount and formatNumber(rawTargetAmount, config.abbreviation),
						dps = showDPS and formatNumber(spell.amountPerSecond, config.abbreviation),
						sortAmount = safeNumber(spell.totalAmount) or 0,
						barValue = rawTargetAmount,
						barMax = detailsMaxAmount or spellMaxAmount,
					}
				end
			end
		end
	end

	if not showTargets then return rows end
	local targets = {}
	for _, target in pairs(targetMap) do targets[#targets + 1] = target end
	table.sort(targets, function(a, b) return (a.amount or 0) > (b.amount or 0) end)
	local useDerivedTargets = type(derivedTargetRows) == "table" and #derivedTargetRows > 0
	if useDerivedTargets or #targets > 0 or #directTargetRows > 0 then
		if showSpellSection then addTooltipSectionGap(rows) end
		local targetHeaderName = damageMeterType == "EnemyDamageTaken" and (L["damageMeterTooltipPlayers"] or "Players") or (L["damageMeterTooltipTargets"] or "Targets")
		rows[#rows + 1] = { header = true, name = targetHeaderName, atlas = damageMeterType ~= "EnemyDamageTaken" and TOOLTIP_TARGET_ATLAS or nil, icon = damageMeterType == "EnemyDamageTaken" and "Interface\\Icons\\Achievement_GuildPerk_EveryonesAFriend" or nil, amount = showAmount and (L["damageMeterTooltipAmount"] or "Amount"), dps = showDPS and rateColumnLabel, percent = showPercent and "%" }
		if useDerivedTargets then
			for _, target in ipairs(derivedTargetRows) do
				rows[#rows + 1] = target
			end
		else
			local targetTotal = 0
			local targetMaxAmount = 0
			local targetRows = {}
			for _, target in ipairs(targets) do
				targetTotal = targetTotal + (target.amount or 0)
				if target.amount and target.amount > targetMaxAmount then targetMaxAmount = target.amount end
			end
			for _, target in ipairs(targets) do
				local percent = targetTotal > 0 and (target.amount / targetTotal * 100) or nil
				targetRows[#targetRows + 1] = { name = target.name, atlas = target.atlas, icon = target.icon, classFilename = target.classFilename, amount = showAmount and formatNumber(target.amount, config.abbreviation), dps = showDPS and formatNumber(target.dps, config.abbreviation), percent = showPercent and percent and string.format("%.1f%%", percent), sortAmount = target.amount or 0, barValue = target.amount, barMax = targetMaxAmount }
			end
			for _, target in ipairs(directTargetRows) do
				local sortAmount = target.sortAmount
				if sortAmount and sortAmount > targetMaxAmount then targetMaxAmount = sortAmount end
				targetRows[#targetRows + 1] = target
			end
			table.sort(targetRows, function(a, b) return (a.sortAmount or 0) > (b.sortAmount or 0) end)
			if targetMaxAmount > 0 then
				for _, target in ipairs(targetRows) do
					target.barMax = targetMaxAmount
				end
			end
			for _, target in ipairs(targetRows) do
				rows[#rows + 1] = target
			end
		end
	end
	return rows
end

function DamageMeter:ShowSourceTooltip(owner, index, source)
	if self.pinnedTooltipOwner and self.pinnedTooltipOwner ~= owner then
		self.pinnedTooltipOwner = nil
		self.pinnedTooltipIndex = nil
	end
	local damageMeterType = self:GetEffectiveDamageMeterType(index)
	if normalizeDamageMeterTypeKey(damageMeterType) == "Threat" then return end
	local config = self:GetConfig(index)
	if config.tooltipEnabled ~= true then return end
	local frame = self:EnsureSourceTooltip()
	local rows = damageMeterType == "Deaths" and self:BuildDeathRecapRows(source, config) or nil
	if not rows or #rows == 0 then
		local details = self:GetSourceDetails(index, source)
		local derivedTargetRows = config.tooltipShowTargets ~= false and self:BuildDerivedTargetRows(index, source, config, damageMeterType) or nil
		rows = self:BuildTooltipRows(details, config, damageMeterType, derivedTargetRows)
	end
	if #rows == 0 then
		rows[1] = { name = L["damageMeterTooltipNoData"] or "No details available", icon = 136243 }
	end
	local width = clampNumber(config.tooltipWidth, 100, 600, DEFAULT_WINDOW.tooltipWidth)
	local tooltipFontSize = clampNumber(config.tooltipFontSize, 8, 24, DEFAULT_WINDOW.tooltipFontSize)
	local lineHeight = tooltipFontSize + 7
	local tooltipIconSize = math.max(16, math.min(24, lineHeight - 2))
	local tooltipIconGap = clampNumber(config.tooltipIconGap, 0, 24, DEFAULT_WINDOW.tooltipIconGap)
	local showAmount, showDPS, showPercent = getTooltipColumnVisibility(config, damageMeterType)
	local percentWidth = showPercent and math.max(40, tooltipFontSize * 3.8) or 0
	local dpsWidth = showDPS and math.max(42, tooltipFontSize * 4.5) or 0
	local amountWidth = showAmount and (damageMeterType == "Deaths" and 110 or math.max(50, tooltipFontSize * 5.2)) or 0
	local rightPadding = 10
	local barStartX = 10 + tooltipIconSize + tooltipIconGap
	local minNameWidth = math.max(60, tooltipFontSize * 6)
	local requiredWidth = barStartX + minNameWidth + amountWidth + dpsWidth + percentWidth + rightPadding + 8
	width = math.min(600, math.max(width, requiredWidth))
	local percentRight = -rightPadding
	local dpsRight = percentRight - percentWidth
	local amountRight = dpsRight - dpsWidth
	local nameRight = amountRight - amountWidth - 8
	local showBars = config.tooltipShowBars == true
	local barTexture = resolveMedia("statusbar", config.tooltipBarTexture, DEFAULT_TEXTURE)
	local shown = #rows
	local tooltipBarSpacing = clampNumber(config.tooltipBarSpacing, -16, 16, DEFAULT_WINDOW.tooltipBarSpacing)
	local tooltipHeight = 10
	for rowIndex = 1, shown do
		local multiplier = rows[rowIndex].heightMultiplier or 1
		tooltipHeight = tooltipHeight + (lineHeight * multiplier)
		if rowIndex < shown then tooltipHeight = tooltipHeight + tooltipBarSpacing end
	end

	local backdropTexture = resolveMedia("statusbar", config.tooltipBackdropTexture, "Interface\\Buttons\\WHITE8x8")
	local borderTexture = resolveMedia("border", config.tooltipBorderTexture, DEFAULT_BORDER)
	local borderSize = clampNumber(config.tooltipBorderSize, 1, 32, DEFAULT_WINDOW.tooltipBorderSize)
	local borderOffset = clampNumber(config.tooltipBorderInset, 0, 32, DEFAULT_WINDOW.tooltipBorderInset)
	frame:SetBackdrop({ bgFile = backdropTexture })
	local bg = normalizeColor(config.tooltipBackdropColor, DEFAULT_WINDOW.tooltipBackdropColor)
	local border = normalizeColor(config.tooltipBorderColor, DEFAULT_WINDOW.tooltipBorderColor)
	frame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
	frame:SetSize(width, tooltipHeight)
	frame.border:ClearAllPoints()
	frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -borderOffset, borderOffset)
	frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", borderOffset, -borderOffset)
	frame.border:SetBackdrop({ edgeFile = borderTexture, edgeSize = borderSize })
	frame.border:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
	frame.border:Show()
	self:AnchorSourceTooltip(frame, owner, config)

	local growUp = normalizeTooltipGrow(config.tooltipGrow) == "UP"
	local yOffset = 5
	for lineIndex = 1, shown do
		local line = self:GetTooltipLine(frame, lineIndex)
		local data = rows[lineIndex]
		if data then
			local currentLineHeight = lineHeight * (data.heightMultiplier or 1)
			line:ClearAllPoints()
			if growUp then
				line:SetPoint("BOTTOMLEFT", 0, yOffset)
				line:SetPoint("BOTTOMRIGHT", 0, yOffset)
			else
				line:SetPoint("TOPLEFT", 0, -yOffset)
				line:SetPoint("TOPRIGHT", 0, -yOffset)
			end
			line:SetHeight(currentLineHeight)
			self:ApplyTooltipFontString(line.name, config)
			self:ApplyTooltipFontString(line.amount, config)
			self:ApplyTooltipFontString(line.dps, config)
			self:ApplyTooltipFontString(line.percent, config)
			line.name:ClearAllPoints()
			line.amount:ClearAllPoints()
			line.dps:ClearAllPoints()
			line.percent:ClearAllPoints()
			line.rowBorder:ClearAllPoints()
			line.barBorder:ClearAllPoints()
			line.iconBorder:ClearAllPoints()
			line.barBG:ClearAllPoints()
			line.bar:ClearAllPoints()
			line.icon:SetSize(tooltipIconSize, tooltipIconSize)
			if data.header then
				line.name:SetPoint("LEFT", line, "LEFT", 6, 0)
			else
				line.name:SetPoint("LEFT", line.icon, "RIGHT", tooltipIconGap, 0)
			end
			line.name:SetPoint("RIGHT", line, "RIGHT", nameRight, 0)
			local showLineIcon = not data.spacer and not data.header
			line.icon:SetShown(showLineIcon)
			if showLineIcon then
				if data.atlas and line.icon.SetAtlas then
					line.icon:SetTexCoord(0, 1, 0, 1)
					line.icon:SetAtlas(data.atlas, false)
				else
					line.icon:SetTexture(data.icon or 136243)
					line.icon:SetTexCoord(0, 1, 0, 1)
				end
			end
			local classFilename = data.classFilename or (source and source.classFilename)
			local barR, barG, barB, barA = getClassOrCustomColor(classFilename, config.tooltipBarColor, DEFAULT_WINDOW.tooltipBarColor, config.tooltipBarUseClassColor)
			local availableBarWidth = math.max(1, width - rightPadding - barStartX)
			local barHeight = math.max(1, currentLineHeight - 3)
			if showBars and not data.header and not data.spacer and data.barValue ~= nil then
				line.barBG:SetTexture(barTexture)
				line.barBG:SetVertexColor(0, 0, 0, math.min(0.45, (barA or 1) * 0.6))
				line.barBG:SetPoint("LEFT", line.icon, "RIGHT", tooltipIconGap, 0)
				line.barBG:SetSize(availableBarWidth, barHeight)
				line.barBG:Show()
				line.bar:SetStatusBarTexture(barTexture)
				line.bar:SetStatusBarColor(barR, barG, barB, barA)
				line.bar:SetPoint("LEFT", line.icon, "RIGHT", tooltipIconGap, 0)
				line.bar:SetSize(availableBarWidth, barHeight)
				line.bar:SetMinMaxValues(0, getTooltipBarMax(data.barMax))
				line.bar:SetValue(getTooltipBarValue(data.barValue))
				line.bar:Show()
			else
				line.barBG:Hide()
				line.bar:Hide()
			end
			local showLineBorders = not data.header and not data.spacer
			local rowBorderOffset = clampNumber(config.tooltipRowBorderInset, 0, 24, DEFAULT_WINDOW.tooltipRowBorderInset)
			local rowBorderWidth = math.max(1, width - rightPadding - 6 + (rowBorderOffset * 2))
			local rowBorderHeight = math.max(1, currentLineHeight + (rowBorderOffset * 2))
			line.rowBorder:ClearAllPoints()
			line.rowBorder:SetPoint("TOPLEFT", line.icon, "TOPLEFT", -rowBorderOffset, rowBorderOffset)
			line.rowBorder:SetSize(rowBorderWidth, rowBorderHeight)
			local rbr, rbg, rbb, rba = getClassOrCustomColor(classFilename, config.tooltipRowBorderColor, DEFAULT_WINDOW.tooltipRowBorderColor, config.tooltipRowBorderUseClassColor)
			applyTooltipBorder(line.rowBorder, showLineBorders and config.tooltipRowBorderEnabled == true, config.tooltipRowBorderTexture, clampNumber(config.tooltipRowBorderSize, 1, 32, DEFAULT_WINDOW.tooltipRowBorderSize), rbr, rbg, rbb, rba)

			local barBorderOffset = clampNumber(config.tooltipBarBorderInset, 0, 24, DEFAULT_WINDOW.tooltipBarBorderInset)
			local barBorderWidth = math.max(1, availableBarWidth + (barBorderOffset * 2))
			local barBorderHeight = math.max(1, barHeight + (barBorderOffset * 2))
			line.barBorder:ClearAllPoints()
			line.barBorder:SetPoint("TOPLEFT", line.bar, "TOPLEFT", -barBorderOffset, barBorderOffset)
			line.barBorder:SetSize(barBorderWidth, barBorderHeight)
			local bbr, bbg, bbb, bba = getClassOrCustomColor(classFilename, config.tooltipBarBorderColor, DEFAULT_WINDOW.tooltipBarBorderColor, config.tooltipBarBorderUseClassColor)
			applyTooltipBorder(line.barBorder, line.bar:IsShown() and config.tooltipBarBorderEnabled == true, config.tooltipBarBorderTexture, clampNumber(config.tooltipBarBorderSize, 1, 32, DEFAULT_WINDOW.tooltipBarBorderSize), bbr, bbg, bbb, bba)

			local iconBorderOffset = clampNumber(config.tooltipIconBorderInset, 0, 24, DEFAULT_WINDOW.tooltipIconBorderInset)
			local iconBorderSize = math.max(1, tooltipIconSize + (iconBorderOffset * 2))
			line.iconBorder:ClearAllPoints()
			line.iconBorder:SetPoint("TOPLEFT", line.icon, "TOPLEFT", -iconBorderOffset, iconBorderOffset)
			line.iconBorder:SetSize(iconBorderSize, iconBorderSize)
			local ibr, ibg, ibb, iba = getClassOrCustomColor(classFilename, config.tooltipIconBorderColor, DEFAULT_WINDOW.tooltipIconBorderColor, config.tooltipIconBorderUseClassColor)
			applyTooltipBorder(line.iconBorder, line.icon:IsShown() and showLineBorders and config.tooltipIconBorderEnabled == true, config.tooltipIconBorderTexture, clampNumber(config.tooltipIconBorderSize, 1, 32, DEFAULT_WINDOW.tooltipIconBorderSize), ibr, ibg, ibb, iba)

			local lineName = data.name
			if data.spacer or lineName == nil then lineName = "" end
			line.name:SetText(lineName)
			line.amount:SetPoint("RIGHT", line, "RIGHT", amountRight, 0)
			line.dps:SetPoint("RIGHT", line, "RIGHT", dpsRight, 0)
			line.percent:SetPoint("RIGHT", line, "RIGHT", percentRight, 0)
			line.amount:SetWidth(amountWidth)
			line.dps:SetWidth(dpsWidth)
			line.percent:SetWidth(percentWidth)
			line.amount:SetText(data.amount or "")
			line.dps:SetText(data.dps or "")
			line.percent:SetText(data.percent or "")
			if data.header then
				line.name:SetTextColor(1, 0.82, 0, 1)
				line.amount:SetTextColor(1, 0.82, 0, 1)
				line.dps:SetTextColor(1, 0.82, 0, 1)
				line.percent:SetTextColor(1, 0.82, 0, 1)
			else
				line.name:SetTextColor(1, 1, 1, 1)
				line.amount:SetTextColor(1, 1, 1, 1)
				line.dps:SetTextColor(1, 1, 1, 1)
				line.percent:SetTextColor(1, 1, 1, 1)
			end
			line:Show()
			yOffset = yOffset + currentLineHeight + tooltipBarSpacing
		elseif line then
			line:Hide()
		end
	end
	for lineIndex = shown + 1, #frame.lines do
		frame.lines[lineIndex]:Hide()
	end
	frame:Show()
end

function DamageMeter:HideSourceTooltip()
	if self.previewTooltipOwner then return end
	if self.pinnedTooltipOwner then return end
	if self.sourceTooltip then self.sourceTooltip:Hide() end
end

function DamageMeter:ClearPinnedTooltip(index)
	if index and self.pinnedTooltipIndex ~= index then return end
	if self.sourceTooltip and not self.previewTooltipOwner then self.sourceTooltip:Hide() end
	self.pinnedTooltipOwner = nil
	self.pinnedTooltipIndex = nil
end

function DamageMeter:ClearPreviewTooltip(index)
	if index and self.previewTooltipIndex ~= index then return end
	if self.sourceTooltip then self.sourceTooltip:Hide() end
	self.previewTooltipIndex = nil
	self.previewTooltipOwner = nil
	if not index or self.activePreviewTooltipIndex == index then
		self.activePreviewTooltipIndex = nil
	end
	self.pinnedTooltipOwner = nil
	self.pinnedTooltipIndex = nil
end

function DamageMeter:TogglePinnedTooltip(owner, index)
	local config = self:GetConfig(index)
	if normalizeDamageMeterTypeKey(self:GetEffectiveDamageMeterType(index)) == "Threat" or config.tooltipEnabled ~= true or config.tooltipClickToPin ~= true or not owner or not owner.sourceData then return end
	if self.pinnedTooltipOwner == owner then
		self:ClearPinnedTooltip(index)
		return
	end
	self.previewTooltipOwner = nil
	self.pinnedTooltipOwner = owner
	self.pinnedTooltipIndex = index
	self:ShowSourceTooltip(owner, index, owner.sourceData)
	self.pinnedTooltipOwner = owner
	self.pinnedTooltipIndex = index
end

function DamageMeter:UpdatePreviewTooltip(index)
	local config = self:GetConfig(index)
	if normalizeDamageMeterTypeKey(self:GetEffectiveDamageMeterType(index)) == "Threat" then
		if self.previewTooltipIndex == index then self:ClearPreviewTooltip(index) end
		return
	end
	if self.previewTooltipIndex == index and (config.tooltipPreview ~= true or not self:IsInEditMode()) and self.sourceTooltip then
		self:ClearPreviewTooltip(index)
	end
	if self.activePreviewTooltipIndex and self.activePreviewTooltipIndex ~= index then
		if self.previewTooltipIndex == index then self:ClearPreviewTooltip(index) end
		return
	end
	local frame = self.windows and self.windows[index]
	if not frame or config.tooltipPreview ~= true or not self:IsInEditMode() then return end
	local row = frame.rows and frame.rows[1]
	if row then
		self.previewTooltipOwner = row
		self.previewTooltipIndex = index
		self:ShowSourceTooltip(row, index, PREVIEW_SESSION.combatSources[1])
		self.previewTooltipOwner = nil
	end
end

function DamageMeter:CreateRow(window, index, forceRankColumn)
	local config = self:GetConfig(window.index)
	local _, _, spacing = getRowMetrics(config)
	local effectiveRowHeight = getEffectiveRowHeight(config)
	local viewportPadding = self:GetRowViewportPadding(config)
	local texture = resolveMedia("statusbar", config.texture, DEFAULT_TEXTURE)
	local row = CreateFrame("Button", nil, window.rowsContainer)
	row.windowIndex = window.index
	row:RegisterForClicks("AnyUp")
	row:SetScript("OnClick", function(owner, button)
		if button == "RightButton" then
			DamageMeter:OpenContextMenu(owner, window.index)
		elseif button == "LeftButton" then
			DamageMeter:TogglePinnedTooltip(owner, window.index)
		end
	end)
	row:SetScript("OnEnter", function(owner)
		DamageMeter:SetWindowHover(window.index, true)
		if DamageMeter.pinnedTooltipOwner then return end
		DamageMeter:ShowSourceTooltip(owner, window.index, owner.sourceData)
	end)
	row:SetScript("OnLeave", function()
		DamageMeter:HideSourceTooltip()
		DamageMeter:SetWindowHover(window.index, false)
	end)
	row:SetHeight(effectiveRowHeight)
	row:ClearAllPoints()
	if normalizeRowGrowth(config.rowGrowth) == "UP" then
		if index > 1 and window.rows[index - 1] then
			row:SetPoint("BOTTOMLEFT", window.rows[index - 1], "TOPLEFT", 0, spacing)
			row:SetPoint("BOTTOMRIGHT", window.rows[index - 1], "TOPRIGHT", 0, spacing)
		else
			row:SetPoint("BOTTOMLEFT", window.rowsContainer, "BOTTOMLEFT", 0, viewportPadding)
			row:SetPoint("BOTTOMRIGHT", window.rowsContainer, "BOTTOMRIGHT", 0, viewportPadding)
		end
	else
		if index > 1 and window.rows[index - 1] then
			row:SetPoint("TOPLEFT", window.rows[index - 1], "BOTTOMLEFT", 0, -spacing)
			row:SetPoint("TOPRIGHT", window.rows[index - 1], "BOTTOMRIGHT", 0, -spacing)
		else
			row:SetPoint("TOPLEFT", window.rowsContainer, "TOPLEFT", 0, -viewportPadding)
			row:SetPoint("TOPRIGHT", window.rowsContainer, "TOPRIGHT", 0, -viewportPadding)
		end
	end

	row.iconFrame = CreateFrame("Frame", nil, row, "BackdropTemplate")
	row.iconFrame:EnableMouse(false)

	row.icon = row.iconFrame:CreateTexture(nil, "ARTWORK")
	row.icon:SetAllPoints()
	row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	row.iconBorder = CreateFrame("Frame", nil, row, "BackdropTemplate")
	row.iconBorder:EnableMouse(false)

	row.bar = CreateFrame("StatusBar", nil, row, "BackdropTemplate")
	row.bar:SetMinMaxValues(0, 1)
	row.bar:SetValue(0)
	row.bar:SetStatusBarTexture(texture)

	row.background = row.bar:CreateTexture(nil, "BACKGROUND")
	row.background:SetAllPoints()
	self:ApplyBarBackground(row, config)

	row.barBorder = CreateFrame("Frame", nil, row, "BackdropTemplate")
	row.barBorder:EnableMouse(false)

	row.rowBorder = CreateFrame("Frame", nil, row, "BackdropTemplate")
	row.rowBorder:EnableMouse(false)

	row.rankFrame = CreateFrame("Frame", nil, row)
	row.rankFrame:EnableMouse(false)
	row.rankFrame:SetAllPoints(row)
	row.rankFrame:SetFrameLevel(row.bar:GetFrameLevel() + 5)

	row.rank = row.rankFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.rank:SetPoint("LEFT", 4, 0)
	row.rank:SetWidth(24)
	row.rank:SetJustifyH("LEFT")
	row.rank:SetWordWrap(false)
	if row.rank.SetMaxLines then row.rank:SetMaxLines(1) end

	row.textArea = CreateFrame("Frame", nil, row)
	row.textArea:SetFrameLevel(row.bar:GetFrameLevel() + 4)

	row.name = row.textArea:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.name:SetJustifyH("LEFT")
	row.name:SetWordWrap(false)
	if row.name.SetMaxLines then row.name:SetMaxLines(1) end

	row.value = row.textArea:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.value:SetJustifyH("RIGHT")
	row.value:SetWordWrap(false)
	if row.value.SetMaxLines then row.value:SetMaxLines(1) end

	row.rateValue = row.textArea:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.rateValue:SetJustifyH("RIGHT")
	row.rateValue:SetWordWrap(false)
	if row.rateValue.SetMaxLines then row.rateValue:SetMaxLines(1) end

	row.percentValue = row.textArea:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.percentValue:SetJustifyH("RIGHT")
	row.percentValue:SetWordWrap(false)
	if row.percentValue.SetMaxLines then row.percentValue:SetMaxLines(1) end

	if config.prefixRankInName == true then
		self:ApplyFontString(row.rank, config)
	else
		self:ApplyRankFontString(row.rank, config)
	end
	self:ApplyFontString(row.name, config)
	self:ApplyValueFontString(row.value, config)
	self:ApplyValueFontString(row.rateValue, config)
	self:ApplyValueFontString(row.percentValue, config)
	self:ApplyRowTextLayout(row, config, forceRankColumn)
	self:ApplyRowBorder(row, config)
	self:ApplyIconBorder(row, config)
	self:ApplyBarBorder(row, config)

	window.rows[index] = row
	return row
end

function DamageMeter:EnsureWindow(index)
	self.windows = self.windows or {}
	local window = self.windows[index]
	if window then return window end

	local frame = CreateFrame("Frame", host.framePrefix .. "Frame" .. index, UIParent, "BackdropTemplate")
	frame:SetFrameStrata("MEDIUM")
	if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
	frame:EnableMouse(true)
	frame:SetScript("OnMouseUp", function(owner, button)
		if button == "RightButton" then
			DamageMeter:OpenContextMenu(owner, index)
		end
	end)
	frame:SetScript("OnEnter", function()
		DamageMeter:SetWindowHover(index, true)
	end)
	frame:SetScript("OnLeave", function()
		DamageMeter:SetWindowHover(index, false)
	end)
	frame:Hide()
	frame.index = index

	local windowBackground = frame:CreateTexture(nil, "BACKGROUND")
	windowBackground:Hide()
	frame.windowBackground = windowBackground

	local contentBackground = frame:CreateTexture(nil, "BACKGROUND")
	contentBackground:Hide()
	frame.contentBackground = contentBackground

	local windowBorder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
	windowBorder:SetFrameLevel(frame:GetFrameLevel() + 6)
	windowBorder:Hide()
	frame.windowBorder = windowBorder

	local headerBackground = frame:CreateTexture(nil, "ARTWORK")
	headerBackground:Hide()
	frame.headerBackground = headerBackground

	local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	header:SetPoint("TOPLEFT", 8, -7)
	header:SetPoint("TOPRIGHT", -8, -7)
	header:SetJustifyH("LEFT")
	header:SetJustifyV("MIDDLE")
	header:SetWordWrap(false)
	if header.SetNonSpaceWrap then header:SetNonSpaceWrap(false) end
	if header.SetMaxLines then header:SetMaxLines(1) end
	frame.header = header

	local headerButtons = CreateFrame("Frame", nil, frame)
	headerButtons:SetSize(36, 16)
	frame.headerButtons = headerButtons
	local resetButton = self:CreateHeaderButton(frame, "R", "GM-raidMarker-reset", L["damageMeterResetData"] or "Reset data", function() DamageMeter:PromptResetData() end)
	resetButton:SetPoint("RIGHT", headerButtons, "RIGHT", 0, 0)
	frame.resetButton = resetButton
		local historyButton = self:CreateHeaderButton(frame, "H", "questlog-questtypeicon-clockyellow", L["damageMeterShowHistory"] or "Show history", function(owner) DamageMeter:OpenHistoryMenu(owner, index) end)
		historyButton:SetScript("OnEnter", function(owner)
			DamageMeter:SetWindowHover(frame.index, true)
			frame._damageMeterHeaderButtonHover = true
			DamageMeter:UpdateHeaderButtonAlpha(frame)
			if DamageMeter:GetConfig(index).headerHistoryHover == true then
				if GameTooltip then GameTooltip:Hide() end
				DamageMeter:OpenHistoryMenu(owner, index, true)
			else
				DamageMeter:ShowTooltip(owner, L["damageMeterShowHistory"] or "Show history")
			end
		end)
		historyButton:SetPoint("RIGHT", resetButton, "LEFT", -4, 0)
		frame.historyButton = historyButton
	local reportButton = self:CreateHeaderButton(frame, "!", nil, L["damageMeterReport"] or "Report", function() DamageMeter:OpenReportDialog(index) end)
	reportButton:SetPoint("RIGHT", historyButton, "LEFT", -4, 0)
	frame.reportButton = reportButton

	local rowsViewport = CreateFrame("ScrollFrame", nil, frame)
	rowsViewport:SetPoint("TOPLEFT", 4, -28)
	rowsViewport:SetPoint("BOTTOMRIGHT", -4, 22)
	rowsViewport:EnableMouse(true)
	rowsViewport:SetScript("OnMouseUp", function(owner, button)
		if button == "RightButton" then
			DamageMeter:OpenContextMenu(owner, index)
		end
	end)
	rowsViewport:EnableMouseWheel(true)
	rowsViewport:SetScript("OnMouseWheel", function(_, delta)
		local config = DamageMeter:GetConfig(index)
		local _, _, spacing = getRowMetrics(config)
		local effectiveRowHeight = getEffectiveRowHeight(config)
		local rowPitch = math.max(1, effectiveRowHeight + spacing)
		local visibleRows = getEffectiveVisibleRows(config)
		local contentRows = frame.contentRows or visibleRows
		local maxScroll = math.max(0, (contentRows - visibleRows) * rowPitch)
		local currentScroll = rowsViewport:GetVerticalScroll() or 0
		local nextScroll = clampNumber(currentScroll - (delta * rowPitch), 0, maxScroll, 0)
		rowsViewport:SetVerticalScroll(nextScroll)
		if config.alwaysShowPlayer == true and nextScroll ~= currentScroll then
			DamageMeter:RefreshWindow(index, DamageMeter:BuildRefreshSharedState())
		end
	end)
	rowsViewport:SetScript("OnEnter", function()
		DamageMeter:SetWindowHover(index, true)
	end)
	rowsViewport:SetScript("OnLeave", function()
		DamageMeter:SetWindowHover(index, false)
	end)
	frame.rowsViewport = rowsViewport

	local rowsContainer = CreateFrame("Frame", nil, rowsViewport)
	rowsContainer:EnableMouse(true)
	rowsContainer:SetScript("OnMouseUp", function(owner, button)
		if button == "RightButton" then
			DamageMeter:OpenContextMenu(owner, index)
		end
	end)
	rowsViewport:SetScrollChild(rowsContainer)
	frame.rowsContainer = rowsContainer

	local empty = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	empty:SetPoint("CENTER", rowsViewport, "CENTER", 0, 0)
	empty:SetText(L["damageMeterNoData"] or "No data")
	frame.empty = empty

	local status = CreateFrame("Button", nil, frame)
	status:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	status:SetPoint("BOTTOMLEFT", 4, 4)
	status:SetPoint("BOTTOMRIGHT", -4, 4)
	status:SetHeight(16)
	status:SetScript("OnClick", function(owner, button)
		if DamageMeter:GetConfig(index).showFooterQuickSwitch == false then return end
		if button == "RightButton" then
			local currentSessionType = DamageMeter:GetEffectiveSessionType(index) or DamageMeter:GetConfig(index).sessionType
			DamageMeter:SetTemporarySessionType(index, currentSessionType == "overall" and "current" or "overall")
			return
		end
		DamageMeter:CycleQuickDamageMeterType(index, 1)
	end)
	status:SetScript("OnMouseWheel", function(_, delta)
		if DamageMeter:GetConfig(index).showFooterQuickSwitch == false then return end
		DamageMeter:CycleQuickDamageMeterType(index, delta and delta < 0 and -1 or 1)
	end)
	status:SetScript("OnEnter", function()
		DamageMeter:SetWindowHover(index, true)
	end)
	status:SetScript("OnLeave", function()
		DamageMeter:SetWindowHover(index, false)
	end)
	status:EnableMouseWheel(true)
	local footerBackground = status:CreateTexture(nil, "ARTWORK")
	footerBackground:SetAllPoints()
	footerBackground:Hide()
	status.background = footerBackground
	frame.footerBackground = footerBackground
	status.text = status:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	status.text:SetAllPoints()
	status.text:SetJustifyH("CENTER")
	status.text:SetTextColor(0.8, 0.82, 0.86)
	frame.status = status

	frame.rows = {}
	self.windows[index] = frame
	return frame
end

function DamageMeter:ApplyWindowAnchor(index)
	if index <= 1 then return end
	local frame = self.windows and self.windows[index]
	if not frame then return end
	local config = self:GetConfig(index)
	local targetIndex = clampNumber(config.anchorToWindow, 0, index - 1, 0)
	if targetIndex <= 0 then
		if frame._damageMeterAnchored then
			local id = host.editModePrefix .. index
			local point = EditMode and EditMode.GetValue and EditMode:GetValue(id, "point") or "CENTER"
			local relativePoint = EditMode and EditMode.GetValue and EditMode:GetValue(id, "relativePoint") or point
			local x = EditMode and EditMode.GetValue and EditMode:GetValue(id, "x") or 300
			local y = EditMode and EditMode.GetValue and EditMode:GetValue(id, "y") or (-120 - ((index - 1) * 30))
			frame:ClearAllPoints()
			frame:SetPoint(point or "CENTER", UIParent, relativePoint or point or "CENTER", x or 0, y or 0)
			frame._damageMeterAnchored = false
		end
		return
	end
	local target = self:EnsureWindow(targetIndex)
	if not target then return end
	frame:ClearAllPoints()
	frame:SetPoint(
		normalizeFramePoint(config.windowAnchorPoint),
		target,
		normalizeFramePoint(config.windowRelativePoint),
		clampNumber(config.windowOffsetX, -1000, 1000, DEFAULT_WINDOW.windowOffsetX),
		clampNumber(config.windowOffsetY, -1000, 1000, DEFAULT_WINDOW.windowOffsetY)
	)
	frame._damageMeterAnchored = true
end

function DamageMeter:ApplyWindowStyle(index, contentRows, forceRankColumn)
	local frame = self:EnsureWindow(index)
	local config = self:GetConfig(index)
	local damageMeterType = self:GetEffectiveDamageMeterType(index)
	local rowMode = config.raidRowsEnabled == true and IsInRaid() and "raid" or "default"
	local styleVersion = self:GetWindowStyleVersion(index)
	local rowCount = #frame.rows
	local globalFontVersion = getGlobalFontStateVersion()
	if frame._damageMeterWindowStyleVersion == styleVersion
		and frame._damageMeterWindowStyleContentRows == contentRows
		and frame._damageMeterWindowStyleRowCount == rowCount
		and frame._damageMeterWindowStyleRowMode == rowMode
		and frame._damageMeterWindowStyleGlobalFontVersion == globalFontVersion
		and frame._damageMeterWindowStyleDamageMeterType == damageMeterType
		and frame._damageMeterWindowStyleForceRankColumn == (forceRankColumn == true) then
		return
	end
	frame._damageMeterWindowStyleVersion = styleVersion
	frame._damageMeterWindowStyleContentRows = contentRows
	frame._damageMeterWindowStyleRowCount = rowCount
	frame._damageMeterWindowStyleRowMode = rowMode
	frame._damageMeterWindowStyleGlobalFontVersion = globalFontVersion
	frame._damageMeterWindowStyleDamageMeterType = damageMeterType
	frame._damageMeterWindowStyleForceRankColumn = forceRankColumn == true

	local width = clampNumber(config.width, 100, 700, DEFAULT_WINDOW.width)
	local showHeader = config.showHeader == true
	local showHeaderButtons = showHeader and config.showHeaderButtons ~= false and normalizeDamageMeterTypeKey(damageMeterType) ~= "Threat"
	local showStatus = config.showStatus ~= false
	local headerPosition = normalizeHeaderPosition(config.headerPosition)
	local rowsGrowUp = normalizeRowGrowth(config.rowGrowth) == "UP"
	local _, _, spacing = getRowMetrics(config)
	local effectiveRowHeight = getEffectiveRowHeight(config)
	local viewportPadding = self:GetRowViewportPadding(config)
	local visibleRows = getEffectiveVisibleRows(config)
	contentRows = math.max(0, tonumber(contentRows) or 0)
	local viewportHeight = math.max(1, (visibleRows * effectiveRowHeight) + (math.max(0, visibleRows - 1) * spacing) + (viewportPadding * 2))
	local titleFontSize = clampNumber(config.titleFontSize, 8, 28, DEFAULT_WINDOW.titleFontSize)
	local statusFontSize = clampNumber(config.statusFontSize, 8, 24, DEFAULT_WINDOW.statusFontSize)
	local headerButtonSize = clampNumber(config.headerButtonSize, 10, 32, DEFAULT_WINDOW.headerButtonSize)
	local headerHeight = showHeader and math.max(24, titleFontSize + 12, showHeaderButtons and (headerButtonSize + 8) or 0) or 0
	local statusHeight = showStatus and math.max(16, statusFontSize + 6) or 0
	local topInset = headerPosition == "TOP" and (headerHeight > 0 and headerHeight or 4) or 4
	local bottomInset = 4 + (showStatus and (statusHeight + 2) or 0) + (headerPosition == "BOTTOM" and headerHeight or 0)
	local heightOffset = clampNumber(config.heightOffset, 0, 300, DEFAULT_WINDOW.heightOffset)
	local topOffset = math.floor(heightOffset / 2)
	local bottomOffset = heightOffset - topOffset
	local height = math.max(60, viewportHeight + topInset + bottomInset + heightOffset)
	local contentHeight = contentRows > 0 and math.max(1, (contentRows * effectiveRowHeight) + (math.max(0, contentRows - 1) * spacing) + (viewportPadding * 2)) or math.max(1, viewportPadding * 2)
	local borderR, borderG, borderB, borderA = colorComponents(config.borderColor, DEFAULT_WINDOW.borderColor)
	local titleR, titleG, titleB, titleA = colorComponents(config.titleColor, DEFAULT_WINDOW.titleColor)
	local backdropOffsetX = clampNumber(config.backdropOffsetX, -200, 200, DEFAULT_WINDOW.backdropOffsetX)
	local backdropOffsetY = clampNumber(config.backdropOffsetY, -200, 200, DEFAULT_WINDOW.backdropOffsetY)
	local backdropSizeOffsetX = clampNumber(config.backdropSizeOffsetX, -200, 200, DEFAULT_WINDOW.backdropSizeOffsetX)
	local backdropSizeOffsetY = clampNumber(config.backdropSizeOffsetY, -200, 200, DEFAULT_WINDOW.backdropSizeOffsetY)
	local contentBackgroundOffsetX = clampNumber(config.contentBackgroundOffsetX, -200, 200, DEFAULT_WINDOW.contentBackgroundOffsetX)
	local contentBackgroundOffsetY = clampNumber(config.contentBackgroundOffsetY, -200, 200, DEFAULT_WINDOW.contentBackgroundOffsetY)
	local contentBackgroundSizeOffsetX = clampNumber(config.contentBackgroundSizeOffsetX, -200, 200, DEFAULT_WINDOW.contentBackgroundSizeOffsetX)
	local contentBackgroundSizeOffsetY = clampNumber(config.contentBackgroundSizeOffsetY, -200, 200, DEFAULT_WINDOW.contentBackgroundSizeOffsetY)
	local headerTextOffsetX = clampNumber(config.headerTextOffsetX, -100, 100, DEFAULT_WINDOW.headerTextOffsetX)
	local headerTextOffsetY = clampNumber(config.headerTextOffsetY, -100, 100, DEFAULT_WINDOW.headerTextOffsetY)
	local headerButtonOffsetX = clampNumber(config.headerButtonOffsetX, -100, 100, DEFAULT_WINDOW.headerButtonOffsetX)
	local headerButtonOffsetY = clampNumber(config.headerButtonOffsetY, -100, 100, DEFAULT_WINDOW.headerButtonOffsetY)
	local headerBackgroundOffsetX = clampNumber(config.headerBackgroundOffsetX, -200, 200, DEFAULT_WINDOW.headerBackgroundOffsetX)
	local headerBackgroundOffsetY = clampNumber(config.headerBackgroundOffsetY, -200, 200, DEFAULT_WINDOW.headerBackgroundOffsetY)
	local headerBackgroundSizeOffsetX = clampNumber(config.headerBackgroundSizeOffsetX, -200, 200, DEFAULT_WINDOW.headerBackgroundSizeOffsetX)
	local headerBackgroundSizeOffsetY = clampNumber(config.headerBackgroundSizeOffsetY, -200, 200, DEFAULT_WINDOW.headerBackgroundSizeOffsetY)
	local footerBackgroundOffsetX = clampNumber(config.footerBackgroundOffsetX, -200, 200, DEFAULT_WINDOW.footerBackgroundOffsetX)
	local footerBackgroundOffsetY = clampNumber(config.footerBackgroundOffsetY, -200, 200, DEFAULT_WINDOW.footerBackgroundOffsetY)
	local footerBackgroundSizeOffsetX = clampNumber(config.footerBackgroundSizeOffsetX, -200, 200, DEFAULT_WINDOW.footerBackgroundSizeOffsetX)
	local footerBackgroundSizeOffsetY = clampNumber(config.footerBackgroundSizeOffsetY, -200, 200, DEFAULT_WINDOW.footerBackgroundSizeOffsetY)
	frame.contentRows = contentRows

	local texture = resolveMedia("statusbar", config.texture, DEFAULT_TEXTURE)
	if frame.SetClampedToScreen then frame:SetClampedToScreen(config.unclampWindow ~= true) end
	frame:SetSize(width, height)
	self:ApplyWindowAnchor(index)
	local headerButtonTextInset = self:ApplyHeaderButtons(frame, config, showHeaderButtons)
	setShownIfChanged(frame.header, showHeader)
	setShownIfChanged(frame.status, showStatus)
	frame.status:EnableMouseWheel(showStatus and config.showFooterQuickSwitch ~= false)
	frame.header:SetHeight(math.max(1, math.min(headerHeight, titleFontSize + 6)))
	frame.header:ClearAllPoints()
	frame.headerBackground:ClearAllPoints()
	frame.windowBackground:ClearAllPoints()
	frame.contentBackground:ClearAllPoints()
	frame.headerButtons:ClearAllPoints()
	frame.status:ClearAllPoints()
	frame.footerBackground:ClearAllPoints()
	if headerPosition == "BOTTOM" then
		frame.headerBackground:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 4 + headerBackgroundOffsetX - headerBackgroundSizeOffsetX, 4 + bottomOffset + headerBackgroundOffsetY - headerBackgroundSizeOffsetY)
		frame.headerBackground:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -4 + headerBackgroundOffsetX + headerBackgroundSizeOffsetX, 4 + bottomOffset + headerHeight + headerBackgroundOffsetY + headerBackgroundSizeOffsetY)
		frame.header:SetPoint("BOTTOMLEFT", 8 + headerTextOffsetX, 7 + bottomOffset + headerTextOffsetY)
		frame.header:SetPoint("BOTTOMRIGHT", -headerButtonTextInset + headerTextOffsetX, 7 + bottomOffset + headerTextOffsetY)
		frame.headerButtons:SetPoint("BOTTOMRIGHT", -8 + headerButtonOffsetX, 7 + bottomOffset + headerButtonOffsetY)
		frame.status:SetPoint("BOTTOMLEFT", 4, 4 + bottomOffset + headerHeight)
		frame.status:SetPoint("BOTTOMRIGHT", -4, 4 + bottomOffset + headerHeight)
	else
		frame.headerBackground:SetPoint("TOPLEFT", frame, "TOPLEFT", 4 + headerBackgroundOffsetX - headerBackgroundSizeOffsetX, -(topOffset + 4) + headerBackgroundOffsetY + headerBackgroundSizeOffsetY)
		frame.headerBackground:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -4 + headerBackgroundOffsetX + headerBackgroundSizeOffsetX, -(topOffset + headerHeight) + headerBackgroundOffsetY - headerBackgroundSizeOffsetY)
		frame.header:SetPoint("TOPLEFT", 8 + headerTextOffsetX, -(7 + topOffset) + headerTextOffsetY)
		frame.header:SetPoint("TOPRIGHT", -headerButtonTextInset + headerTextOffsetX, -(7 + topOffset) + headerTextOffsetY)
		frame.headerButtons:SetPoint("TOPRIGHT", -8 + headerButtonOffsetX, -(7 + topOffset) + headerButtonOffsetY)
		frame.status:SetPoint("BOTTOMLEFT", 4, 4 + bottomOffset)
		frame.status:SetPoint("BOTTOMRIGHT", -4, 4 + bottomOffset)
	end
	self:ApplyHeaderBackground(frame, config, showHeader)
	frame.windowBackground:SetPoint("TOPLEFT", frame, "TOPLEFT", backdropOffsetX - backdropSizeOffsetX, backdropOffsetY + backdropSizeOffsetY)
	frame.windowBackground:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", backdropOffsetX + backdropSizeOffsetX, backdropOffsetY - backdropSizeOffsetY)
	self:ApplyWindowBackground(frame, config)
	frame.contentBackground:SetPoint("TOPLEFT", frame.rowsViewport, "TOPLEFT", contentBackgroundOffsetX - contentBackgroundSizeOffsetX, contentBackgroundOffsetY + contentBackgroundSizeOffsetY)
	frame.contentBackground:SetPoint("BOTTOMRIGHT", frame.rowsViewport, "BOTTOMRIGHT", contentBackgroundOffsetX + contentBackgroundSizeOffsetX, contentBackgroundOffsetY - contentBackgroundSizeOffsetY)
	self:ApplyContentBackground(frame, config)
	frame.footerBackground:SetPoint("TOPLEFT", frame.status, "TOPLEFT", footerBackgroundOffsetX - footerBackgroundSizeOffsetX, footerBackgroundOffsetY + footerBackgroundSizeOffsetY)
	frame.footerBackground:SetPoint("BOTTOMRIGHT", frame.status, "BOTTOMRIGHT", footerBackgroundOffsetX + footerBackgroundSizeOffsetX, footerBackgroundOffsetY - footerBackgroundSizeOffsetY)
	self:ApplyFooterBackground(frame, config, showStatus)

	local borderTexture = resolveMedia("border", config.borderTexture, DEFAULT_BORDER)
	if config.borderEnabled == true then
		local size = clampNumber(config.borderSize, 1, 32, DEFAULT_WINDOW.borderSize)
		local offset = clampNumber(config.borderInset, 0, 24, DEFAULT_WINDOW.borderInset)
		local borderOffsetX = 0
		local borderOffsetY = 0
		local borderSizeOffsetX = 0
		local borderSizeOffsetY = 0
		if config.borderUseAdvancedOffsets == true then
			borderOffsetX = clampNumber(config.borderOffsetX, -200, 200, DEFAULT_WINDOW.borderOffsetX)
			borderOffsetY = clampNumber(config.borderOffsetY, -200, 200, DEFAULT_WINDOW.borderOffsetY)
			borderSizeOffsetX = clampNumber(config.borderSizeOffsetX, -200, 200, DEFAULT_WINDOW.borderSizeOffsetX)
			borderSizeOffsetY = clampNumber(config.borderSizeOffsetY, -200, 200, DEFAULT_WINDOW.borderSizeOffsetY)
		end
		frame.windowBorder:ClearAllPoints()
		frame.windowBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", -offset + borderOffsetX - borderSizeOffsetX, offset + borderOffsetY + borderSizeOffsetY)
		frame.windowBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset + borderOffsetX + borderSizeOffsetX, -offset + borderOffsetY - borderSizeOffsetY)
		frame.windowBorder:SetBackdrop({
			bgFile = nil,
			edgeFile = borderTexture,
			edgeSize = size,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
		frame.windowBorder:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
		frame.windowBorder:Show()
	else
		frame.windowBorder:Hide()
		frame.windowBorder:SetBackdrop(nil)
	end
	frame:SetBackdrop(nil)

	frame.status:SetHeight(math.max(1, statusHeight))

	frame.rowsViewport:ClearAllPoints()
	frame.rowsViewport:SetPoint("TOPLEFT", 4, -(topInset + topOffset))
	frame.rowsViewport:SetPoint("TOPRIGHT", -4, -(topInset + topOffset))
	frame.rowsViewport:SetHeight(viewportHeight)
	frame.rowsContainer:SetSize(math.max(1, width - 8), math.max(1, contentHeight))
	local maxScroll = math.max(0, contentHeight - viewportHeight)
	if (frame.rowsViewport:GetVerticalScroll() or 0) > maxScroll then
		frame.rowsViewport:SetVerticalScroll(maxScroll)
	end

	self:ApplyTitleFontString(frame.header, config)
	setTextColorIfChanged(frame.header, titleR, titleG, titleB, titleA)
	self:ApplyFontString(frame.empty, config)
	self:ApplyStatusFontString(frame.status.text, config)

	local previous
	for rowIndex, row in ipairs(frame.rows) do
		row:SetHeight(effectiveRowHeight)
		row:ClearAllPoints()
		if rowsGrowUp then
			if previous then
				row:SetPoint("BOTTOMLEFT", previous, "TOPLEFT", 0, spacing)
				row:SetPoint("BOTTOMRIGHT", previous, "TOPRIGHT", 0, spacing)
			else
				row:SetPoint("BOTTOMLEFT", frame.rowsContainer, "BOTTOMLEFT", 0, viewportPadding)
				row:SetPoint("BOTTOMRIGHT", frame.rowsContainer, "BOTTOMRIGHT", 0, viewportPadding)
			end
		else
			if previous then
				row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -spacing)
				row:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -spacing)
			else
				row:SetPoint("TOPLEFT", frame.rowsContainer, "TOPLEFT", 0, -viewportPadding)
				row:SetPoint("TOPRIGHT", frame.rowsContainer, "TOPRIGHT", 0, -viewportPadding)
			end
		end
		if row.bar._damageMeterTexture ~= texture then
			row.bar._damageMeterTexture = texture
			row.bar:SetStatusBarTexture(texture)
		end
		self:ApplyBarBackground(row, config)
		if config.prefixRankInName == true then
			self:ApplyFontString(row.rank, config)
		else
			self:ApplyRankFontString(row.rank, config)
			end
			self:ApplyFontString(row.name, config)
			self:ApplyValueFontString(row.value, config)
			if row.rateValue then self:ApplyValueFontString(row.rateValue, config) end
			if row.percentValue then self:ApplyValueFontString(row.percentValue, config) end
			self:ApplyRowTextLayout(row, config, forceRankColumn)
		self:ApplyRowBorder(row, config)
		self:ApplyRowValueWidth(row, config, nil, forceRankColumn)
		previous = row
	end
end

function DamageMeter:UpdateHeader(index, session, state)
	state = state or self:BuildWindowRefreshState(index)
	local frame = self:EnsureWindow(index)
	local config = state.config
	local showHeader = config.showHeader == true
	local showStatus = config.showStatus ~= false
	local showFooterQuickSwitch = showStatus and config.showFooterQuickSwitch ~= false
	if not showHeader and not showStatus then return end
	local sessionLabel
	if state.sessionID then
		local fallback = DAMAGE_METER_COMBAT_NUMBER and DAMAGE_METER_COMBAT_NUMBER:format(state.sessionID) or string.format("%s %d", L["damageMeterCombat"] or "Combat", state.sessionID)
		sessionLabel = safeText(state.temporary and state.temporary.sessionName, fallback)
	else
		sessionLabel = state.sessionType == "overall" and (L["damageMeterOverall"] or "Overall") or (L["damageMeterCurrent"] or "Current")
	end
	local typeLabel = getDamageMeterTypeLabel(state.damageMeterType)
	local durationText
	local durationBucket = false
	local headerTimeFormat = normalizeHeaderTimeFormat(config.headerTimeFormat)
	local showHeaderTime = config.showHeaderTime ~= false and state.sessionType ~= "overall"
	if showHeader and showHeaderTime then
		local duration = self:GetSessionDuration(index, session, state)
		if duration then
			durationBucket = math.floor(duration + 0.5)
			durationText = formatDuration(duration, headerTimeFormat)
		end
	end
	local formatMode = normalizeHeaderFormat(config.headerFormat)
	local quickTypeLabels = showFooterQuickSwitch and self:GetQuickDamageMeterTypeLabels(index, typeLabel) or nil
	local styleVersion = self:GetWindowStyleVersion(index)
	if frame._damageMeterHeaderStyleVersion == styleVersion
		and frame._damageMeterHeaderShowHeader == showHeader
		and frame._damageMeterHeaderShowStatus == showStatus
		and frame._damageMeterHeaderShowFooterQuickSwitch == showFooterQuickSwitch
		and frame._damageMeterHeaderShowSession == (config.showHeaderSession ~= false)
		and frame._damageMeterHeaderShowType == (config.showHeaderType ~= false)
		and frame._damageMeterHeaderShowTime == showHeaderTime
		and frame._damageMeterHeaderFormat == formatMode
		and frame._damageMeterHeaderTimeFormat == headerTimeFormat
		and frame._damageMeterHeaderDurationBucket == durationBucket
		and frame._damageMeterHeaderSessionLabel == sessionLabel
		and frame._damageMeterHeaderTypeLabel == typeLabel
		and frame._damageMeterHeaderQuickTypeLabels == quickTypeLabels then
		return
	end
	frame._damageMeterHeaderStyleVersion = styleVersion
	frame._damageMeterHeaderShowHeader = showHeader
	frame._damageMeterHeaderShowStatus = showStatus
	frame._damageMeterHeaderShowFooterQuickSwitch = showFooterQuickSwitch
	frame._damageMeterHeaderShowSession = config.showHeaderSession ~= false
	frame._damageMeterHeaderShowType = config.showHeaderType ~= false
	frame._damageMeterHeaderShowTime = showHeaderTime
	frame._damageMeterHeaderFormat = formatMode
	frame._damageMeterHeaderTimeFormat = headerTimeFormat
	frame._damageMeterHeaderDurationBucket = durationBucket
	frame._damageMeterHeaderSessionLabel = sessionLabel
	frame._damageMeterHeaderTypeLabel = typeLabel
	frame._damageMeterHeaderQuickTypeLabels = quickTypeLabels

	local separator = (formatMode == "timeTypeSpace" or formatMode == "typeTimeSpace") and " " or " - "
	local headerText = ""
	if showHeader then
		if durationText and (formatMode == "timeTypeDash" or formatMode == "timeTypeSpace") then headerText = durationText end
		if config.showHeaderType ~= false and typeLabel then
			headerText = headerText ~= "" and (headerText .. separator .. typeLabel) or typeLabel
		end
		if durationText and (formatMode == "typeTimeDash" or formatMode == "typeTimeSpace") then
			headerText = headerText ~= "" and (headerText .. separator .. durationText) or durationText
		end
		if config.showHeaderSession ~= false and sessionLabel then
			if headerText ~= "" then
				headerText = sessionLabel .. " - " .. headerText
			else
				headerText = sessionLabel
			end
		end
		setPlainTextIfChanged(frame.header, headerText)
	end
	if showStatus then
		setPlainTextIfChanged(frame.status.text, showFooterQuickSwitch and string.format("%s  |  %s", sessionLabel, quickTypeLabels) or "")
	end
end

function DamageMeter:GetReportOrderedSources(session, damageMeterType)
	local sources = session and type(session.combatSources) == "table" and session.combatSources or {}
	if damageMeterType ~= "Deaths" or #sources <= 1 then return sources end
	local orderedSources = {}
	local hasComparableDeathTime = false
	for _, source in ipairs(sources) do
		if safeNumber(source and source.deathTimeSeconds) then
			hasComparableDeathTime = true
			break
		end
	end
	if hasComparableDeathTime then
		for sourceIndex, source in ipairs(sources) do
			orderedSources[sourceIndex] = source
		end
		table.sort(orderedSources, function(left, right)
			local leftTime = safeNumber(left and left.deathTimeSeconds) or math.huge
			local rightTime = safeNumber(right and right.deathTimeSeconds) or math.huge
			return leftTime < rightTime
		end)
	else
		for sourceIndex = 1, #sources do
			orderedSources[sourceIndex] = sources[#sources - sourceIndex + 1]
		end
	end
	return orderedSources
end

function DamageMeter:IsReportDataAvailable(session, orderedSources, damageMeterType, config, lineLimit)
	if self:IsReportRestricted() then return false end
	if not session or type(orderedSources) ~= "table" or #orderedSources == 0 then return false end
	local requirePercent = config.showPercent ~= false and damageMeterType ~= "Deaths"
	if requirePercent and not isReportFieldSafe(session.totalAmount) then return false end
	lineLimit = clampNumber(lineLimit, 1, 20, 10)
	for sourceIndex = 1, math.min(lineLimit, #orderedSources) do
		if not isSourceReportable(orderedSources[sourceIndex], damageMeterType, config, requirePercent) then
			return false
		end
	end
	return true
end

function DamageMeter:RefreshReportRestrictionState(restrictionType, state)
	local restrictionStates = Enum and Enum.AddOnRestrictionState
	if restrictionStates and (state == restrictionStates.Active or state == restrictionStates.Activating) then
		self.reportRestrictionActive = true
		return
	end
	self.reportRestrictionActive = false
	if not C_RestrictedActions or not C_RestrictedActions.GetAddOnRestrictionState then return end
	local restrictionTypes = getRestrictionTypes()
	if not restrictionTypes then return end
	for _, knownType in ipairs(restrictionTypes) do
		if knownType ~= nil and (restrictionType == nil or knownType ~= restrictionType) then
			local currentState = C_RestrictedActions.GetAddOnRestrictionState(knownType)
			if restrictionStates and currentState ~= restrictionStates.Inactive then
				self.reportRestrictionActive = true
				return
			end
		end
	end
end

function DamageMeter:IsReportRestricted()
	if self.reportRestrictionActive == nil then
		self:RefreshReportRestrictionState()
	end
	return self.reportRestrictionActive == true
end

function DamageMeter:FormatReportValue(source, session, damageMeterType, config)
	local valueMode = getReportValueMode(damageMeterType, config)
	if valueMode == "death" then return formatDeathTimeText(source) end
	local abbreviation = config.abbreviation
	local text
	if valueMode == "count" or valueMode == "amount" then
		text = formatNumber(source.totalAmount, abbreviation)
	elseif valueMode == "perSecond" then
		text = formatNumber(source.amountPerSecond, abbreviation)
	else
		local amountText = formatNumber(source.totalAmount, abbreviation)
		local rateText = formatNumber(source.amountPerSecond, abbreviation)
		text = config.valueFormat == "parentheses" and (amountText .. " (" .. rateText .. ")") or joinValueText(amountText, rateText, config.valueSeparator)
	end
	if config.showPercent ~= false then
		local totalAmount = safeNumber(session and session.totalAmount)
		local amount = safeNumber(source.totalAmount)
		if totalAmount and totalAmount > 0 and amount then
			text = string.format("%s (%.1f%%)", text, amount / totalAmount * 100)
		end
	end
	return text
end

function DamageMeter:BuildReportLines(index, lineLimit)
	local state = self:BuildWindowRefreshState(index)
	if not state.visible then return nil, L["damageMeterReportNoData"] or "No reportable Damage Meter data." end
	local config = state.config
	local session = self:GetSessionForState(state)
	local damageMeterType = state.damageMeterType
	if normalizeDamageMeterTypeKey(damageMeterType) == "Threat" then return nil, L["damageMeterReportNoData"] or "No reportable Damage Meter data." end
	local orderedSources = self:GetReportOrderedSources(session, damageMeterType)
	lineLimit = clampNumber(lineLimit, 1, 20, 10)
	if not self:IsReportDataAvailable(session, orderedSources, damageMeterType, config, math.min(lineLimit, #orderedSources)) then
		return nil, L["damageMeterReportRestricted"] or "Report data is restricted right now."
	end
	local sessionLabel = state.sessionID and (state.temporary and state.temporary.sessionName or L["damageMeterHistory"] or "History") or (state.sessionType == "overall" and (L["damageMeterOverall"] or "Overall") or (L["damageMeterCurrent"] or "Current"))
	local duration = self:GetSessionDuration(index, session, state)
	local typeLabel = getDamageMeterTypeLabel(damageMeterType)
	local header = string.format("%s: %s - %s", host.displayName, sessionLabel or "", typeLabel or "")
	local durationText = formatDuration(duration, "smart")
	if durationText then header = string.format("%s (%s)", header, durationText) end
	local lines = { header }
	for sourceIndex = 1, math.min(lineLimit, #orderedSources) do
		local source = orderedSources[sourceIndex]
		local name = formatSourceName(source and source.name, config)
		if isSecret(name) then return nil, L["damageMeterReportRestricted"] or "Report data is restricted right now." end
		lines[#lines + 1] = string.format("%d. %s: %s", sourceIndex, tostring(name), self:FormatReportValue(source, session, damageMeterType, config))
	end
	if #lines <= 1 then return nil, L["damageMeterReportNoData"] or "No reportable Damage Meter data." end
	return lines
end

function DamageMeter:IsReportChannelAvailable(chatType, target)
	if chatType == "SAY" then return true end
	if chatType == "PARTY" then return _G.IsInGroup and _G.IsInGroup() == true and not (IsInRaid and IsInRaid() == true) end
	if chatType == "RAID" then return IsInRaid and IsInRaid() == true end
	if chatType == "INSTANCE_CHAT" then return _G.IsInGroup and _G.IsInGroup(_G.LE_PARTY_CATEGORY_INSTANCE) == true end
	if chatType == "GUILD" then return _G.IsInGuild and _G.IsInGuild() == true end
	if chatType == "WHISPER" then return target and target ~= "" end
	return false
end

function DamageMeter:GetAvailableReportChannels()
	local channels = self.availableReportChannels
	if not channels then
		channels = {}
		self.availableReportChannels = channels
	else
		for index = #channels, 1, -1 do
			channels[index] = nil
		end
	end
	for _, channel in ipairs(REPORT_CHANNELS) do
		if channel.chatType == "WHISPER" or self:IsReportChannelAvailable(channel.chatType) then
			channels[#channels + 1] = channel
		end
	end
	return channels
end

function DamageMeter:SetReportDialogChannel(frame, chatType)
	frame.selectedChatType = chatType or "SAY"
	frame.channelButton:SetText(getReportChannelLabel(frame.selectedChatType))
	local whisper = frame.selectedChatType == "WHISPER"
	frame.targetLabel:SetShown(whisper)
	frame.targetBox:SetShown(whisper)
	frame:SetHeight(whisper and 220 or 184)
end

function DamageMeter:SendReport(index, chatType, lineLimit, target)
	if not _G.SendChatMessage then return end
	if not self:IsReportChannelAvailable(chatType, target) then
		print(L["damageMeterReportChannelUnavailable"] or "That report channel is not available right now.")
		return
	end
	local lines, errorText = self:BuildReportLines(index, lineLimit)
	if not lines then
		print(errorText or (L["damageMeterReportNoData"] or "No reportable Damage Meter data."))
		return
	end
	for lineIndex, line in ipairs(lines) do
		local message = sanitizeReportChatMessage(line)
		local sendTarget = chatType == "WHISPER" and target or nil
		if C_Timer and C_Timer.NewTimer then
			C_Timer.NewTimer(lineIndex * 0.2, function()
				_G.SendChatMessage(message, chatType, nil, sendTarget)
			end)
		else
			_G.SendChatMessage(message, chatType, nil, sendTarget)
		end
	end
end

function DamageMeter:EnsureReportDialog()
	if self.reportDialog then return self.reportDialog end
	local frame = CreateFrame("Frame", host.framePrefix .. "ReportDialog", UIParent, "BackdropTemplate")
	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(90)
	frame:SetSize(360, 270)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetClampedToScreen(true)
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	frame:SetBackdropColor(0.02, 0.02, 0.025, 0.96)
	frame:SetBackdropBorderColor(0.22, 0.24, 0.28, 1)
	frame:Hide()
	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.title:SetPoint("TOPLEFT", 16, -14)
	frame.title:SetText(L["damageMeterReportTitle"] or "Report Damage Meter")
	frame.channelLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.channelLabel:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -18)
	frame.channelLabel:SetText(L["damageMeterReportChannel"] or "Channel")
	frame.channelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.channelButton:SetSize(150, 24)
	frame.channelButton:SetPoint("LEFT", frame.channelLabel, "RIGHT", 12, 0)
	frame.channelButton:SetScript("OnClick", function(owner)
		if not MenuUtil or not MenuUtil.CreateContextMenu then return end
		MenuUtil.CreateContextMenu(owner, function(_, rootDescription)
			for _, channel in ipairs(DamageMeter:GetAvailableReportChannels()) do
				rootDescription:CreateButton(getReportChannelLabel(channel.chatType), function()
					DamageMeter:SetReportDialogChannel(frame, channel.chatType)
				end)
			end
		end)
	end)
	frame.linesLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.linesLabel:SetPoint("TOPLEFT", frame.channelLabel, "BOTTOMLEFT", 0, -18)
	frame.linesLabel:SetText(L["damageMeterReportLines"] or "Lines")
	frame.linesBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	frame.linesBox:SetSize(54, 24)
	frame.linesBox:SetPoint("LEFT", frame.linesLabel, "RIGHT", 12, 0)
	frame.linesBox:SetAutoFocus(false)
	frame.linesBox:SetNumeric(true)
	frame.linesBox:SetNumber(5)
	frame.targetLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.targetLabel:SetPoint("TOPLEFT", frame.linesLabel, "BOTTOMLEFT", 0, -18)
	frame.targetLabel:SetText(L["damageMeterReportTarget"] or "Whisper target")
	frame.targetBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	frame.targetBox:SetSize(180, 24)
	frame.targetBox:SetPoint("LEFT", frame.targetLabel, "RIGHT", 12, 0)
	frame.targetBox:SetAutoFocus(false)
	frame.send = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.send:SetSize(96, 24)
	frame.send:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 14)
	frame.send:SetText(OKAY or "Okay")
	frame.send:SetScript("OnClick", function()
		local target = frame.targetBox:GetText()
		local lines = clampNumber(frame.linesBox:GetNumber(), 1, 20, 5)
		DamageMeter:SendReport(frame.index or 1, frame.selectedChatType or "SAY", lines, target)
		frame:Hide()
	end)
	frame.cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.cancel:SetSize(96, 24)
	frame.cancel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 14)
	frame.cancel:SetText(CANCEL or "Cancel")
	frame.cancel:SetScript("OnClick", function() frame:Hide() end)
	table.insert(UISpecialFrames, frame:GetName())
	self.reportDialog = frame
	return frame
end

function DamageMeter:OpenReportDialog(index)
	local _, errorText = self:BuildReportLines(index, 1)
	if errorText then
		print(errorText)
		return
	end
	local frame = self:EnsureReportDialog()
	frame.index = index
	frame.title:SetText(L["damageMeterReportTitle"] or "Report Damage Meter")
	frame.channelLabel:SetText(L["damageMeterReportChannel"] or "Channel")
	frame.linesLabel:SetText(L["damageMeterReportLines"] or "Lines")
	frame.targetLabel:SetText(L["damageMeterReportTarget"] or "Whisper target")
	if not frame.linesBox:GetNumber() or frame.linesBox:GetNumber() < 1 then frame.linesBox:SetNumber(5) end
	local channels = self:GetAvailableReportChannels()
	local selectedChatType = channels[1] and channels[1].chatType or "WHISPER"
	self:SetReportDialogChannel(frame, selectedChatType)
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:Show()
end

function DamageMeter:RefreshWindow(index, shared, sessionCache)
	local state = self:BuildWindowRefreshState(index, shared)
	local frame = self:EnsureWindow(index)
	if not state.editMode and self.pinnedTooltipIndex == index and self.pinnedTooltipOwner and (not self.pinnedTooltipOwner:IsShown() or self.pinnedTooltipOwner.sourceData == nil) then
		self:ClearPinnedTooltip(index)
	end
	if not state.editMode then self:ClearPreviewTooltip(index) end
	if not state.visible then
		self:ClearPreviewTooltip(index)
		self:ClearPinnedTooltip(index)
		self:ClearWindowRows(frame)
		frame:Hide()
		return
	end

	local config = state.config
	local session = self:GetSessionForState(state, sessionCache)
	local sources = session and type(session.combatSources) == "table" and session.combatSources or {}
	local damageMeterType = state.damageMeterType
	local orderedSources = sources
	if damageMeterType == "Deaths" and type(sources) == "table" and #sources > 1 then
		orderedSources = {}
		local hasComparableDeathTime = false
		for _, source in ipairs(sources) do
			if safeNumber(source and source.deathTimeSeconds) then
				hasComparableDeathTime = true
				break
			end
		end
		if hasComparableDeathTime then
			for sourceIndex, source in ipairs(sources) do
				orderedSources[sourceIndex] = source
			end
			table.sort(orderedSources, function(left, right)
				local leftTime = safeNumber(left and left.deathTimeSeconds) or math.huge
				local rightTime = safeNumber(right and right.deathTimeSeconds) or math.huge
				return leftTime < rightTime
			end)
		else
			for sourceIndex = 1, #sources do
				orderedSources[sourceIndex] = sources[#sources - sourceIndex + 1]
			end
		end
	end
	local rowsGrowUp = normalizeRowGrowth(config.rowGrowth) == "UP"
	local highestBottom = damageMeterType ~= "Deaths" and normalizeRowSort(config.rowSort) == "BOTTOM"
	local visibleRows = getEffectiveVisibleRows(config)
	local contentRows = #orderedSources
	local playerSourceIndex = config.alwaysShowPlayer == true and findLocalPlayerSourceIndex(orderedSources) or nil

	local forceRankColumn = false
	local reportAvailable = self:IsReportDataAvailable(session, orderedSources, damageMeterType, config, math.min(visibleRows, #orderedSources))
	if config.showRanks ~= false and config.prefixRankInName == true then
		for entryIndex = 1, contentRows do
			local source = orderedSources[entryIndex]
			if source and isSecret(source.name) then
				forceRankColumn = true
				break
			end
		end
	end

	self:ApplyWindowStyle(index, contentRows, forceRankColumn)
	local displayIndices = buildViewportAwareDisplayIndices(frame, config, contentRows, playerSourceIndex, highestBottom)
	self:UpdateHeader(index, session, state)
	if frame.reportButton then
		setShownIfChanged(frame.reportButton, normalizeDamageMeterTypeKey(damageMeterType) ~= "Threat" and config.showHeader == true and config.showHeaderButtons ~= false and config.showHeaderReportButton ~= false and reportAvailable == true)
	end

	local totalAmount = safeNumber(session and session.totalAmount)
	local shown = 0
	local inFollowerDungeon = state.inFollowerDungeon
	local valueMode = getRowValueMode(damageMeterType, config)
	local valueFormatter = ROW_VALUE_FORMATTERS[valueMode] or formatAmountRateRowValueText
	local valueAbbreviation = config.abbreviation
	local valueShowPercent = config.showPercent ~= false
	local valueUseParentheses = config.valueFormat == "parentheses"
	local valueSeparator = normalizeValueSeparator(config.valueSeparator)

	for rowIndex = 1, contentRows do
		local visualTopIndex = rowsGrowUp and (contentRows - rowIndex + 1) or rowIndex
		local entryIndex = highestBottom and (contentRows - visualTopIndex + 1) or visualTopIndex
		local sourceIndex
		if entryIndex >= 1 and entryIndex <= contentRows then
			if displayIndices then
				sourceIndex = displayIndices[entryIndex]
			else
				sourceIndex = entryIndex
			end
		end
		local source = sourceIndex and orderedSources[sourceIndex] or nil
		local row = frame.rows[rowIndex]
		if not row then
			row = self:CreateRow(frame, rowIndex, forceRankColumn)
		end
		if source then
			local rawMaxAmount, rawAmount
			if damageMeterType == "Deaths" then
				rawMaxAmount = 1
				rawAmount = 1
			else
				rawMaxAmount = session and session.maxAmount
				rawAmount = source.totalAmount
				if rawMaxAmount == nil then rawMaxAmount = 1 end
				if rawAmount == nil then rawAmount = 0 end
			end
				local amount = safeNumber(source.totalAmount)
				local percent = totalAmount and totalAmount > 0 and amount and (amount / totalAmount * 100) or nil
				local colors = self:GetRowColorState(frame, config, source.classFilename)
				local valueText = valueFormatter(source, percent, valueAbbreviation, valueShowPercent, valueUseParentheses, valueSeparator)
				local amountText, rateText, percentText = formatRowValueColumnTexts(source, percent, damageMeterType, config)

				self:ApplyRankText(row, sourceIndex, config)
				row.sourceData = source
			self:ApplyRowBorder(row, config, source.classFilename, colors)
			self:ApplyIconBorder(row, config, source.classFilename, colors)
			self:ApplyBarBorder(row, config, source.classFilename, colors)
			if config.showIcons ~= false then applySourceIcon(row.icon, source, inFollowerDungeon, damageMeterType, config) end
			self:ApplyRowValueWidth(row, config, damageMeterType, forceRankColumn)
			local displayName = formatDisplayName(source, config)
			row.name:SetText(self:TruncateNameWithoutEllipsis(displayName, row.name, config))
			setTextColorIfChanged(row.name, colors.nr, colors.ng, colors.nb, colors.na)
				if config.prefixRankInName == true then
					setTextColorIfChanged(row.rank, colors.prr, colors.prg, colors.prb, colors.pra)
				else
					setTextColorIfChanged(row.rank, colors.rr, colors.rg, colors.rb, colors.ra)
				end
				if row._damageMeterUseValueColumns then
					row.value:SetText(amountText)
					if row.rateValue then row.rateValue:SetText(rateText) end
					if row.percentValue then row.percentValue:SetText(percentText) end
				else
					row.value:SetText(valueText)
					if row.rateValue then row.rateValue:SetText("") end
					if row.percentValue then row.percentValue:SetText("") end
				end
				setTextColorIfChanged(row.value, colors.vr, colors.vg, colors.vb, colors.va)
				if row.rateValue then setTextColorIfChanged(row.rateValue, colors.vr, colors.vg, colors.vb, colors.va) end
				if row.percentValue then setTextColorIfChanged(row.percentValue, colors.vr, colors.vg, colors.vb, colors.va) end
				row.bar:SetStatusBarColor(colors.r, colors.g, colors.b, colors.a)
			row.bar:SetMinMaxValues(0, rawMaxAmount)
			setStatusBarValue(row.bar, rawAmount, config.smoothBars == true)
			row:Show()
			shown = shown + 1
		else
			row.sourceData = nil
			row:Hide()
		end
	end

	for rowIndex = contentRows + 1, #frame.rows do
		frame.rows[rowIndex]:Hide()
	end

	frame.empty:SetShown(shown == 0 and config.showNoData ~= false)
	frame:SetShown(true)
	self:UpdateWindowAlpha(index)
	self:UpdatePreviewTooltip(index)
end

function DamageMeter:Refresh()
	local shared = self:BuildRefreshSharedState()
	local sessionCache = self.refreshSessionCache
	if not sessionCache then
		sessionCache = {}
		self.refreshSessionCache = sessionCache
	end
	self:ClearRefreshSessionCache(sessionCache)
	for index = 1, MAX_WINDOWS do
		self:RefreshWindow(index, shared, sessionCache)
	end
	self:ClearRefreshSessionCache(sessionCache)
end

function DamageMeter:ScheduleRefresh()
	if GetTime then
		self.lastLiveRefreshTime = GetTime()
	end
	self:Refresh()
end

function DamageMeter:RefreshFromLiveEvent(damageMeterType, sessionID)
	if not self:IsLiveEventRelevant(damageMeterType, sessionID) then return end
	local now = GetTime and GetTime() or (time and time() or 0)
	local last = self.lastLiveRefreshTime or 0
	if now - last < getUpdateRate() then return end
	self.lastLiveRefreshTime = now
	self:Refresh()
end

function DamageMeter:ScheduleContextRefresh()
	if self.contextRefreshPending then return end
	self.contextRefreshPending = true
	C_Timer.After(0.05, function()
		DamageMeter.contextRefreshPending = nil
		DamageMeter:ScheduleRefresh()
	end)
end

function DamageMeter:ScheduleThreatRefresh()
	local now = GetTime and GetTime() or 0
	local interval = getUpdateRate()
	local elapsed = now - (self.lastThreatRefreshTime or 0)
	if elapsed >= interval then
		self.lastThreatRefreshTime = now
		self:Refresh()
		return
	end
	if self.threatRefreshPending then return end
	self.threatRefreshPending = true
	C_Timer.After(math.max(0.05, interval - elapsed), function()
		DamageMeter.threatRefreshPending = nil
		DamageMeter.lastThreatRefreshTime = GetTime and GetTime() or 0
		DamageMeter:Refresh()
	end)
end

function DamageMeter:RegisterLiveEvents()
	local frame = self.eventFrame
	if not frame or self.liveEventsRegistered then return end
	frame:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED")
	frame:RegisterEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED")
	frame:RegisterEvent("DAMAGE_METER_RESET")
	frame:RegisterEvent("GROUP_ROSTER_UPDATE")
	frame:RegisterEvent("PLAYER_REGEN_DISABLED")
	frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("ENCOUNTER_START")
	frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
	frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
	frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	frame:RegisterEvent("CHALLENGE_MODE_START")
	frame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
	frame:RegisterEvent("CHALLENGE_MODE_RESET")
	frame:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED")
	self.liveEventsRegistered = true
end

function DamageMeter:UnregisterLiveEvents()
	local frame = self.eventFrame
	if not frame or not self.liveEventsRegistered then return end
	frame:UnregisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED")
	frame:UnregisterEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED")
	frame:UnregisterEvent("DAMAGE_METER_RESET")
	frame:UnregisterEvent("GROUP_ROSTER_UPDATE")
	frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
	frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
	frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	frame:UnregisterEvent("ENCOUNTER_START")
	frame:UnregisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
	frame:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
	frame:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
	frame:UnregisterEvent("CHALLENGE_MODE_START")
	frame:UnregisterEvent("CHALLENGE_MODE_COMPLETED")
	frame:UnregisterEvent("CHALLENGE_MODE_RESET")
	frame:UnregisterEvent("ADDON_RESTRICTION_STATE_CHANGED")
	self.liveEventsRegistered = false
end

function DamageMeter:HasRoleSpecificTypeWindows()
	if not self:IsEnabled() then return false end
	local windows = self:GetWindowsDB()
	for index = 1, getWindowCount() do
		if windows[index] and windows[index].keepManualType ~= true and windows[index].roleSpecificType == true then return true end
	end
	return false
end

function DamageMeter:HasThreatWindows()
	if not self:IsEnabled() then return false end
	for index = 1, getWindowCount() do
		if self:GetEffectiveDamageMeterType(index) == "Threat" then return true end
	end
	return false
end

function DamageMeter:RegisterRoleTypeEvents()
	local frame = self.eventFrame
	if not frame or self.roleTypeEventsRegistered then return end
	frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
	if frame.RegisterUnitEvent then
		frame:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
	else
		frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	end
	frame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
	self.roleTypeEventsRegistered = true
end

function DamageMeter:UnregisterRoleTypeEvents()
	local frame = self.eventFrame
	if not frame or not self.roleTypeEventsRegistered then return end
	frame:UnregisterEvent("PLAYER_ROLES_ASSIGNED")
	frame:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	frame:UnregisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
	self.roleTypeEventsRegistered = false
end

function DamageMeter:RegisterThreatEvents()
	local frame = self.eventFrame
	if not frame or self.threatEventsRegistered then return end
	frame:RegisterEvent("PLAYER_TARGET_CHANGED")
	frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
	frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
	frame:RegisterUnitEvent("UNIT_TARGET", "focus", "target")
	self.threatEventsRegistered = true
end

function DamageMeter:UnregisterThreatEvents()
	local frame = self.eventFrame
	if not frame or not self.threatEventsRegistered then return end
	frame:UnregisterEvent("PLAYER_TARGET_CHANGED")
	frame:UnregisterEvent("UNIT_THREAT_LIST_UPDATE")
	frame:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE")
	frame:UnregisterEvent("UNIT_TARGET")
	self.threatEventsRegistered = false
end

function DamageMeter:UpdateEventState()
	self:InvalidateLiveEventWatch()
	local enabled = self:IsEnabled()
	if enabled then
		self:SuppressBlizzardDamageMeter()
	else
		self.blizzardDamageMeterSuppressed = false
	end
	if enabled and self:IsAvailable() then
		self:RegisterLiveEvents()
	else
		self:UnregisterLiveEvents()
	end
	if self:HasRoleSpecificTypeWindows() then
		self:RegisterRoleTypeEvents()
	else
		self:UnregisterRoleTypeEvents()
	end
	if self:HasThreatWindows() then
		self:RegisterThreatEvents()
	else
		self:UnregisterThreatEvents()
	end
	self:ScheduleRefresh()
end

function DamageMeter:ApplySyncedConfig(sourceIndex)
	if db().damageMeterSyncSettings ~= true then return end
	local windows = self:GetWindowsDB()
	local source = copyWindowConfig(windows[sourceIndex])
	for index = 1, MAX_WINDOWS do
		if index ~= sourceIndex then
			windows[index] = copySyncedWindowConfig(source, windows[index])
		end
	end
	self:MarkWindowStyleDirty()
	self:Refresh()
end

function DamageMeter:CopySettings(sourceIndex, targetIndex)
	sourceIndex = tonumber(sourceIndex)
	targetIndex = tonumber(targetIndex)
	if not sourceIndex or not targetIndex or sourceIndex == targetIndex then return end
	local count = getWindowCount()
	if sourceIndex < 1 or sourceIndex > count or targetIndex < 1 or targetIndex > count then return end
	local windows = self:GetWindowsDB()
	windows[targetIndex] = copyWindowConfig(windows[sourceIndex])
	self:InvalidateLiveEventWatch()
	self:MarkWindowStyleDirty(targetIndex)
	if db().damageMeterSyncSettings == true then
		self:ApplySyncedConfig(targetIndex)
	else
		self:RefreshWindow(targetIndex)
	end
end

function DamageMeter:ResetNewWindowPlacement(index)
	local config = self:GetConfig(index)
	config.anchorToWindow = 0
	config.windowAnchorPoint = "CENTER"
	config.windowRelativePoint = "CENTER"
	config.windowOffsetX = 0
	config.windowOffsetY = 0
	local frame = self:EnsureWindow(index)
	if frame then
		frame._damageMeterAnchored = false
		frame:ClearAllPoints()
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	end
	if EditMode and EditMode.SetFramePosition then
		EditMode:SetFramePosition(host.editModePrefix .. index, "CENTER", 0, 0, nil, true, "CENTER")
	end
end

function DamageMeter:AddWindow(sourceIndex)
	local count = getWindowCount()
	if count >= MAX_WINDOWS then return end
	local newIndex = count + 1
	setWindowCount(newIndex)
	self:GetWindowsDB()
	self:InvalidateLiveEventWatch()
	self:MarkWindowStyleDirty(newIndex)
	if db().damageMeterSyncSettings == true then
		self:CopySettings(sourceIndex or 1, newIndex)
	end
	self:ResetNewWindowPlacement(newIndex)
	self:UpdateEventState()
	self:Refresh()
	return newIndex
end

function DamageMeter:CloseEditModeDialogForWindow(index)
	local frame = self.windows and self.windows[index]
	local lib = EditMode and EditMode.lib
	local dialog = lib and lib.internal and lib.internal.dialog
	if not (frame and dialog and dialog.IsShown and dialog:IsShown()) then return end
	local contextFrame = dialog.context and dialog.context.frame
	local selectionFrame = dialog.selection and dialog.selection.parent
	if contextFrame == frame or selectionFrame == frame then
		dialog:Hide()
	end
end

function DamageMeter:RemoveWindow(index)
	index = tonumber(index)
	local count = getWindowCount()
	if not index or index <= 1 or index > count then return end
	self:HideContextMenu()
	self:CloseEditModeDialogForWindow(index)
	local windows = self:GetWindowsDB()
	for windowIndex = index, count - 1 do
		windows[windowIndex] = copyWindowConfig(windows[windowIndex + 1])
	end
	windows[count] = copyWindowConfig(DEFAULT_WINDOW)
	setWindowCount(count - 1)
	for windowIndex = count, MAX_WINDOWS do
		local frame = self.windows and self.windows[windowIndex]
		if frame then frame:Hide() end
	end
	self:InvalidateLiveEventWatch()
	self:Refresh()
end

function DamageMeter:EnsureStaticPopups()
	if not StaticPopupDialogs then return end
	StaticPopupDialogs[REMOVE_WINDOW_POPUP] = StaticPopupDialogs[REMOVE_WINDOW_POPUP] or {
		text = L["damageMeterRemoveWindowConfirm"] or "Remove Damage Meter window %s?",
		button1 = YES or "Yes",
		button2 = CANCEL or "Cancel",
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopupDialogs[REMOVE_WINDOW_POPUP].OnAccept = function(_, data) DamageMeter:RemoveWindow(data) end

	StaticPopupDialogs[COPY_WINDOW_POPUP] = StaticPopupDialogs[COPY_WINDOW_POPUP] or {
		text = L["damageMeterCopyWindowConfirm"] or "Copy settings from Damage Meter %s to Damage Meter %s?",
		button1 = YES or "Yes",
		button2 = CANCEL or "Cancel",
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopupDialogs[COPY_WINDOW_POPUP].OnAccept = function(_, data)
		if type(data) == "table" then DamageMeter:CopySettings(data.source, data.target) end
	end

	StaticPopupDialogs[RESET_DATA_POPUP] = StaticPopupDialogs[RESET_DATA_POPUP] or {
		text = L["damageMeterResetDataConfirm"] or "Reset all Damage Meter data?",
		button1 = YES or "Yes",
		button2 = CANCEL or "Cancel",
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopupDialogs[RESET_DATA_POPUP].OnAccept = function() DamageMeter:ResetData() end

	StaticPopupDialogs[AUTO_CLEAR_POPUP] = StaticPopupDialogs[AUTO_CLEAR_POPUP] or {
		text = L["damageMeterAutomaticClearConfirm"] or "Clear all Damage Meter data for this instance?",
		button1 = YES or "Yes",
		button2 = CANCEL or "Cancel",
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopupDialogs[AUTO_CLEAR_POPUP].OnAccept = function() DamageMeter:ResetData() end
end

function DamageMeter:PromptRemoveWindow(index)
	self:EnsureStaticPopups()
	if StaticPopup_Show then
		StaticPopup_Show(REMOVE_WINDOW_POPUP, tostring(index), nil, index)
	else
		self:RemoveWindow(index)
	end
end

function DamageMeter:PromptCopySettings(sourceIndex, targetIndex)
	if sourceIndex == targetIndex then return end
	self:EnsureStaticPopups()
	if StaticPopup_Show then
		StaticPopup_Show(COPY_WINDOW_POPUP, tostring(sourceIndex), tostring(targetIndex), { source = sourceIndex, target = targetIndex })
	else
		self:CopySettings(sourceIndex, targetIndex)
	end
end

function DamageMeter:ResetData()
	if C_DamageMeter and C_DamageMeter.ResetAllCombatSessions then
		C_DamageMeter.ResetAllCombatSessions()
	end
	self.temporarySelections = {}
	self:InvalidateLiveEventWatch()
	self:ScheduleRefresh()
end

function DamageMeter:PromptResetData()
	self:EnsureStaticPopups()
	if StaticPopup_Show then
		StaticPopup_Show(RESET_DATA_POPUP)
	else
		self:ResetData()
	end
end

function DamageMeter:PromptAutoClearData()
	self:EnsureStaticPopups()
	if StaticPopup_Show then
		StaticPopup_Show(AUTO_CLEAR_POPUP)
	else
		self:ResetData()
	end
end

function DamageMeter:GetAutomaticClearInstanceKey()
	if not (IsInInstance and GetInstanceInfo) then return nil end
	local inInstance, instanceType = IsInInstance()
	if not inInstance or (instanceType ~= "party" and instanceType ~= "raid") then return nil end
	local instances = normalizeAutoClearInstances(db().damageMeterAutomaticClearInstances)
	if instances[instanceType] ~= true then return nil end
	local instanceID = select(8, GetInstanceInfo())
	if not instanceID then return nil end
	return instanceType .. ":" .. tostring(instanceID)
end

function DamageMeter:RunAutomaticClear(instanceKey)
	if self.autoClearPendingInstanceKey ~= instanceKey then return end
	self.autoClearPendingInstanceKey = nil
	if not self:IsEnabled() or self:IsInEditMode() then return end
	local mode = normalizeAutoClearMode(db().damageMeterAutomaticClear)
	if mode == "never" then return end
	if self:GetAutomaticClearInstanceKey() ~= instanceKey then return end
	self.autoClearActiveInstanceKey = instanceKey
	if mode == "ask" then
		self:PromptAutoClearData()
	else
		self:ResetData()
	end
end

function DamageMeter:CheckAutomaticClear()
	if not self:IsEnabled() or self:IsInEditMode() then return end
	local mode = normalizeAutoClearMode(db().damageMeterAutomaticClear)
	if mode == "never" then return end
	local instanceKey = self:GetAutomaticClearInstanceKey()
	if not instanceKey then
		self.autoClearActiveInstanceKey = nil
		self.autoClearPendingInstanceKey = nil
		return
	end
	if self.autoClearActiveInstanceKey == instanceKey or self.autoClearPendingInstanceKey == instanceKey then return end
	self.autoClearPendingInstanceKey = instanceKey
	if C_Timer and C_Timer.After then
		C_Timer.After(AUTO_CLEAR_DELAY_SECONDS, function() DamageMeter:RunAutomaticClear(instanceKey) end)
	else
		self:RunAutomaticClear(instanceKey)
	end
end

function DamageMeter:RunEncounterStartAutomaticClear(clearKey)
	if self.autoClearPendingEncounterKey ~= clearKey then return end
	self.autoClearPendingEncounterKey = nil
	if not self:IsEnabled() or self:IsInEditMode() then return end
	local mode = normalizeAutoClearMode(db().damageMeterAutomaticClear)
	if mode == "never" then return end
	local instances = normalizeAutoClearInstances(db().damageMeterAutomaticClearInstances)
	if instances.raidEncounter ~= true then return end
	local inInstance, instanceType
	if IsInInstance then inInstance, instanceType = IsInInstance() end
	if not inInstance or instanceType ~= "raid" then return end
	if mode == "ask" then
		self:PromptAutoClearData()
	else
		self:ResetData()
	end
end

function DamageMeter:CheckEncounterStartAutomaticClear(encounterID)
	if not self:IsEnabled() or self:IsInEditMode() then return end
	local mode = normalizeAutoClearMode(db().damageMeterAutomaticClear)
	if mode == "never" then return end
	local instances = normalizeAutoClearInstances(db().damageMeterAutomaticClearInstances)
	if instances.raidEncounter ~= true then return end
	local inInstance, instanceType
	if IsInInstance then inInstance, instanceType = IsInInstance() end
	if not inInstance or instanceType ~= "raid" then return end
	local clearKey = table.concat({ "encounter", tostring(select(8, GetInstanceInfo()) or "0"), tostring(encounterID or "0"), tostring(GetTime and GetTime() or 0) }, "\001")
	self.autoClearPendingEncounterKey = clearKey
	if C_Timer and C_Timer.After then
		C_Timer.After(0.1, function() DamageMeter:RunEncounterStartAutomaticClear(clearKey) end)
	else
		self:RunEncounterStartAutomaticClear(clearKey)
	end
end

local function buildWindowCopyOptions(targetIndex)
	local options = {}
	local count = getWindowCount()
	for index = 1, count do
		if index ~= targetIndex then
			options[#options + 1] = { value = tostring(index), label = string.format("%s %d", L["damageMeterTitle"] or "Damage Meter", index) }
		end
	end
	if #options == 0 then options[#options + 1] = { value = "", label = _G.NONE or "None" } end
	return options
end

local function dropdownSetting(name, getter, setter, options, parentId, height, isEnabled, isShown)
	return {
		name = name,
		kind = SettingType.Dropdown,
		parentId = parentId,
		height = height or 160,
		isEnabled = isEnabled,
		isShown = isShown,
		get = getter,
		set = function(_, value) setter(value) end,
		generator = function(_, root)
			local optionList = type(options) == "function" and options() or options
			for _, option in ipairs(optionList) do
				root:CreateRadio(option.label, function() return getter() == option.value end, function() setter(option.value) end)
			end
		end,
	}
end

local function sliderSetting(name, getter, setter, minValue, maxValue, step, parentId, isEnabled, isShown, formatter)
	return {
		name = name,
		kind = SettingType.Slider,
		parentId = parentId,
		isEnabled = isEnabled,
		isShown = isShown,
		minValue = minValue,
		maxValue = maxValue,
		valueStep = step or 1,
		allowInput = true,
		formatter = formatter,
		get = getter,
		set = function(_, value) setter(value) end,
	}
end

local function checkboxSetting(name, getter, setter, parentId, isEnabled, tooltip, isShown)
	return {
		name = name,
		kind = SettingType.Checkbox,
		parentId = parentId,
		isEnabled = isEnabled,
		isShown = isShown,
		tooltip = tooltip,
		get = getter,
		set = function(_, value) setter(value == true) end,
	}
end

local function inputSetting(name, getter, setter, parentId, isEnabled, tooltip, maxChars)
	return {
		name = name,
		kind = SettingType.Input,
		parentId = parentId,
		isEnabled = isEnabled,
		tooltip = tooltip,
		maxChars = maxChars or 128,
		get = getter,
		set = function(_, value) setter(value) end,
	}
end

local function colorSetting(name, getter, setter, default, parentId, isEnabled)
	return {
		name = name,
		kind = SettingType.Color,
		parentId = parentId,
		isEnabled = isEnabled,
		default = default,
		hasOpacity = true,
		get = getter,
		set = function(_, value) setter(value) end,
	}
end

local function colorNoOpacitySetting(name, getter, setter, default, parentId, isEnabled)
	return {
		name = name,
		kind = SettingType.Color,
		parentId = parentId,
		isEnabled = isEnabled,
		default = default,
		hasOpacity = false,
		get = getter,
		set = function(_, value) setter(value) end,
	}
end

local function dividerSetting(parentId, isEnabled, isShown)
	return {
		name = "",
		kind = SettingType.Divider,
		parentId = parentId,
		isEnabled = isEnabled,
		isShown = isShown,
	}
end

local function requestEditModeSettingsRefresh()
	if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RequestRefreshSettings then
		addon.EditModeLib.internal:RequestRefreshSettings()
	end
end

function DamageMeter:EnableSyncedConfigFromSource(sourceIndex)
	sourceIndex = clampNumber(sourceIndex, 1, getWindowCount(), 1)
	db().damageMeterSyncSettings = true
	self:ApplySyncedConfig(sourceIndex)
	requestEditModeSettingsRefresh()
end

function DamageMeter:EnsureSyncSourceDialog()
	if self.syncSourceDialog then return self.syncSourceDialog end
	local frame = CreateFrame("Frame", host.framePrefix .. "SyncSourceDialog", UIParent, "BackdropTemplate")
	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(90)
	frame:SetSize(360, 190)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetClampedToScreen(true)
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
	frame:SetBackdropColor(0.02, 0.02, 0.025, 0.96)
	frame:SetBackdropBorderColor(0.22, 0.24, 0.28, 1)
	frame:Hide()

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
	frame.title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -14)
	frame.title:SetJustifyH("LEFT")

	frame.description = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	frame.description:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -8)
	frame.description:SetPoint("TOPRIGHT", frame.title, "BOTTOMRIGHT", 0, -8)
	frame.description:SetJustifyH("LEFT")
	frame.description:SetJustifyV("TOP")
	frame.description:SetSpacing(2)

	frame.buttons = {}
	frame.cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.cancel:SetSize(110, 24)
	frame.cancel:SetText(CANCEL or "Cancel")
	frame.cancel:SetScript("OnClick", function()
		db().damageMeterSyncSettings = false
		frame:Hide()
		requestEditModeSettingsRefresh()
	end)

	table.insert(UISpecialFrames, frame:GetName())
	self.syncSourceDialog = frame
	return frame
end

function DamageMeter:PromptEnableSyncSettings(sourceIndex)
	local count = getWindowCount()
	if count <= 1 then
		self:EnableSyncedConfigFromSource(1)
		return
	end
	db().damageMeterSyncSettings = false
	local frame = self:EnsureSyncSourceDialog()
	frame.title:SetText(L["damageMeterSyncSourceTitle"] or "Choose sync source")
	frame.description:SetText(L["damageMeterSyncSourceDesc"] or "Choose which Damage Meter window should provide the initial shared layout and styling settings. Behavior settings stay separate per window.")
	local topOffset = 86
	local buttonHeight = 26
	local gap = 6
	for index = 1, MAX_WINDOWS do
		local button = frame.buttons[index]
		if not button then
			button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
			button:SetHeight(buttonHeight)
			frame.buttons[index] = button
		end
		if index <= count then
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -(topOffset + ((index - 1) * (buttonHeight + gap))))
			button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -16, -(topOffset + ((index - 1) * (buttonHeight + gap))))
			button:SetText(string.format(L["damageMeterSyncSourceButton"] or "Use window %d", index))
			button:SetScript("OnClick", function()
				frame:Hide()
				self:EnableSyncedConfigFromSource(index)
			end)
			button:Show()
		else
			button:Hide()
		end
	end
	frame.cancel:ClearAllPoints()
	frame.cancel:SetPoint("TOP", frame.buttons[count], "BOTTOM", 0, -12)
	frame:SetHeight(topOffset + (count * (buttonHeight + gap)) + 42)
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:Show()
	requestEditModeSettingsRefresh()
end

function DamageMeter:SetConfigValue(index, key, value)
	local config = self:GetConfig(index)
	if key == "quickTypes" then
		config.quickTypes = normalizeQuickDamageMeterTypes(value, config.damageMeterType or DEFAULT_WINDOW.damageMeterType)
		if self.quickTypeLabelCache then self.quickTypeLabelCache[index] = nil end
	elseif key == "visibility" then
		config.visibility = normalizeVisibilityConfig(value)
	else
		config[key] = copyValue(value)
	end
	if key == "damageMeterType" or key == "sessionType" or key == "roleSpecificType" or key == "tankDamageMeterType" or key == "healerDamageMeterType" or key == "damagerDamageMeterType" then
		self:InvalidateLiveEventWatch()
	end
	if key == "sessionType" and db().damageMeterLinkSegments == true then
		local sessionType = config.sessionType == "overall" and "overall" or "current"
		local windows = self:GetWindowsDB()
		for windowIndex = 1, getWindowCount() do
			windows[windowIndex].sessionType = sessionType
			local temporary = self:GetTemporarySelection(windowIndex)
			temporary.sessionID = nil
			temporary.sessionName = nil
			temporary.sessionDurationSeconds = nil
			temporary.sessionType = nil
			self:MarkWindowStyleDirty(windowIndex)
		end
		self:Refresh()
		return
	end
	if key == "damageMeterType" or key == "roleSpecificType" or key == "tankDamageMeterType" or key == "healerDamageMeterType" or key == "damagerDamageMeterType" then self:UpdateEventState() end
	self:MarkWindowStyleDirty(index)
	if self:IsInEditMode() and config.tooltipPreview == true then
		self.activePreviewTooltipIndex = index
	end
	if key == "tooltipPreview" and value ~= true and self.sourceTooltip then
		self.sourceTooltip:Hide()
		if self.previewTooltipIndex == index then self.previewTooltipIndex = nil end
		if self.activePreviewTooltipIndex == index then self.activePreviewTooltipIndex = nil end
	end
	if key == "tooltipEnabled" and value ~= true and self.sourceTooltip then
		self:ClearPreviewTooltip(index)
		self:ClearPinnedTooltip(index)
	end
	if key == "tooltipClickToPin" and value ~= true then
		self:ClearPinnedTooltip(index)
	end
	if key == "rowHeight" or key == "barHeight" or key == "changeBarSize" then
		local rowHeight = clampNumber(config.rowHeight, 10, 70, DEFAULT_WINDOW.rowHeight)
		config.barHeight = clampNumber(config.barHeight, 1, rowHeight, DEFAULT_WINDOW.barHeight)
	end
	if db().damageMeterSyncSettings == true and not SYNC_EXCLUDED_KEYS[key] then
		local windows = self:GetWindowsDB()
		for windowIndex = 1, MAX_WINDOWS do
			if windowIndex ~= index then
				windows[windowIndex][key] = copyValue(config[key])
				self:MarkWindowStyleDirty(windowIndex)
				if key == "rowHeight" or key == "barHeight" or key == "changeBarSize" then
					local rowHeight = clampNumber(windows[windowIndex].rowHeight, 10, 70, DEFAULT_WINDOW.rowHeight)
					windows[windowIndex].barHeight = clampNumber(windows[windowIndex].barHeight, 1, rowHeight, DEFAULT_WINDOW.barHeight)
				end
			end
		end
		self:Refresh()
	else
		self:RefreshWindow(index)
	end
end

function DamageMeter:BuildWindowSettings(index)
	local function cfg() return self:GetConfig(index) end
	local function headerEnabled() return cfg().showHeader == true end
	local function headerTimeEnabled() return cfg().showHeader == true and cfg().showHeaderTime ~= false end
	local function statusEnabled() return cfg().showStatus ~= false end
	local function footerBackgroundEnabled() return cfg().showStatus ~= false and cfg().footerBackgroundEnabled == true end
	local function namesEnabled() return cfg().showNames == true end
	local function fixedNameColorEnabled() return cfg().showNames == true and cfg().nameUseClassColors ~= true end
	local function tooltipEnabled() return cfg().tooltipEnabled == true end
	local function headerBackgroundEnabled() return cfg().showHeader == true and cfg().headerBackgroundEnabled == true end
	local function contentBackgroundEnabled() return cfg().contentBackgroundEnabled == true end
	local function customBarSizeEnabled() return cfg().changeBarSize == true end
	local function rowBorderEnabled() return cfg().rowBorderEnabled == true end
	local function fixedRowBorderColorEnabled() return cfg().rowBorderEnabled == true and cfg().rowBorderUseClassColor ~= true end
	local function barBorderEnabled() return cfg().barBorderEnabled == true end
	local function fixedBarBorderColorEnabled() return cfg().barBorderEnabled == true and cfg().barBorderUseClassColor ~= true end
	local function fixedBarColorEnabled() return cfg().useClassColors ~= true end
	local function iconsEnabled() return cfg().showIcons ~= false end
	local function customIconSizeEnabled() return cfg().showIcons ~= false and cfg().changeIconSize == true end
	local function iconBorderEnabled() return cfg().showIcons ~= false and cfg().iconBorderEnabled == true end
	local function fixedIconBorderColorEnabled() return cfg().showIcons ~= false and cfg().iconBorderEnabled == true and cfg().iconBorderUseClassColor ~= true end
	local function windowBorderEnabled() return cfg().borderEnabled == true end
	local function fixedValueColorEnabled() return cfg().valueUseClassColors ~= true end
	local function automaticTypeVisible() return cfg().keepManualType ~= true end
	local function roleSpecificTypeEnabled() return automaticTypeVisible() and cfg().roleSpecificType == true end
	local function rankingEnabled() return cfg().showRanks ~= false end
	local function rankColumnEnabled() return cfg().showRanks ~= false and cfg().prefixRankInName ~= true end
	local function fixedRankColorEnabled() return cfg().showRanks ~= false and cfg().rankUseClassColors ~= true end
	local function fixedTooltipBarColorEnabled() return cfg().tooltipEnabled == true and cfg().tooltipBarUseClassColor ~= true end
	local function tooltipRowBorderEnabled() return cfg().tooltipEnabled == true and cfg().tooltipRowBorderEnabled == true end
	local function fixedTooltipRowBorderColorEnabled() return tooltipRowBorderEnabled() and cfg().tooltipRowBorderUseClassColor ~= true end
	local function tooltipBarBorderEnabled() return cfg().tooltipEnabled == true and cfg().tooltipBarBorderEnabled == true end
	local function fixedTooltipBarBorderColorEnabled() return tooltipBarBorderEnabled() and cfg().tooltipBarBorderUseClassColor ~= true end
	local function tooltipIconBorderEnabled() return cfg().tooltipEnabled == true and cfg().tooltipIconBorderEnabled == true end
	local function fixedTooltipIconBorderColorEnabled() return tooltipIconBorderEnabled() and cfg().tooltipIconBorderUseClassColor ~= true end
	local function windowAnchorVisible() return index > 1 end
	local function windowAnchorEnabled() return index > 1 and clampNumber(cfg().anchorToWindow, 0, index - 1, 0) > 0 end
	local function raidRowsEnabled() return cfg().raidRowsEnabled == true end
	local function valueColumnsEnabled() return getRowValueLayout(cfg()) == "columns" end
	local function combinedValueLayoutEnabled() return getRowValueLayout(cfg()) == "combined" end
	local behaviorId = "damageMeterBehavior" .. index
	local layoutId = "damageMeterLayout" .. index
	local headerId = "damageMeterHeader" .. index
	local contentBackgroundId = "damageMeterContentBackground" .. index
	local statusId = "damageMeterStatus" .. index
	local barId = "damageMeterBar" .. index
	local iconId = "damageMeterIcon" .. index
	local namesId = "damageMeterNames" .. index
	local valuesId = "damageMeterValues" .. index
	local tooltipId = "damageMeterTooltip" .. index
	local rankingId = "damageMeterRanking" .. index
	local mediaId = "damageMeterMedia" .. index
	local borderId = "damageMeterBorder" .. index
	local settingsId = "damageMeterSettings" .. index
	local settings = {
		{ name = L["damageMeterSettings"] or "Settings", kind = SettingType.Collapsible, id = settingsId, defaultCollapsed = true },
		checkboxSetting(L["damageMeterSyncSettings"] or "Sync settings", function() return db().damageMeterSyncSettings == true end, function(value)
			if value == true then
				self:PromptEnableSyncSettings(index)
			else
				db().damageMeterSyncSettings = false
				self:Refresh()
				requestEditModeSettingsRefresh()
			end
		end, settingsId, nil, L["damageMeterSyncSettingsDesc"] or "When enabled, choose the source window once. Damage Meter windows then share layout and styling settings. Behavior settings stay separate per window."),
		dropdownSetting(L["damageMeterCopySettingsFrom"] or "Copy settings from", function() return "" end, function(value)
			local sourceIndex = tonumber(value)
			if sourceIndex then self:PromptCopySettings(sourceIndex, index) end
		end, function() return buildWindowCopyOptions(index) end, settingsId, 160, function() return getWindowCount() > 1 and db().damageMeterSyncSettings ~= true end),
		{ name = L["Behavior"] or "Behavior", kind = SettingType.Collapsible, id = behaviorId, defaultCollapsed = true },
		checkboxSetting(L["damageMeterAlwaysShowPlayer"] or "Always show player", function() return cfg().alwaysShowPlayer == true end, function(value) self:SetConfigValue(index, "alwaysShowPlayer", value) end, behaviorId),
		checkboxSetting(L["damageMeterLinkSegments"] or "Link segments", function() return db().damageMeterLinkSegments == true end, function(value)
			db().damageMeterLinkSegments = value == true
			self:InvalidateLiveEventWatch()
			self:Refresh()
		end, behaviorId, nil, L["damageMeterLinkSegmentsDesc"] or "When enabled, changing the selected segment in one Damage Meter window switches all Damage Meter windows to that segment."),
		checkboxSetting(L["damageMeterKeepManualType"] or "Keep manual type", function() return cfg().keepManualType == true end, function(value)
			self:SetKeepManualDamageMeterType(index, value)
			requestEditModeSettingsRefresh()
		end, behaviorId, nil, L["damageMeterKeepManualTypeDesc"] or "When enabled, manual type changes are saved for this window and restored after reloads."),
		dropdownSetting(L["damageMeterSession"] or "Session", function() return cfg().sessionType end, function(value) self:SetConfigValue(index, "sessionType", value == "overall" and "overall" or "current") end, {
			{ value = "current", label = L["damageMeterCurrent"] or "Current" },
			{ value = "overall", label = L["damageMeterOverall"] or "Overall" },
		}, behaviorId, 110),
		dropdownSetting(_G.TYPE or "Type", function() return normalizeDamageMeterTypeKey(cfg().damageMeterType) end, function(value) self:SetConfigValue(index, "damageMeterType", normalizeDamageMeterTypeKey(value)) end, buildDamageMeterTypeOptions, behaviorId, 180, function() return automaticTypeVisible() and cfg().roleSpecificType ~= true end, automaticTypeVisible),
		checkboxSetting(L["damageMeterRoleSpecificType"] or "Role-specific type", function() return cfg().roleSpecificType == true end, function(value)
			self:SetConfigValue(index, "roleSpecificType", value)
			requestEditModeSettingsRefresh()
		end, behaviorId, nil, nil, automaticTypeVisible),
		dropdownSetting(L["damageMeterTankType"] or "Tank type", function() return normalizeDamageMeterTypeKey(cfg().tankDamageMeterType) end, function(value) self:SetConfigValue(index, "tankDamageMeterType", normalizeDamageMeterTypeKey(value)) end, buildDamageMeterTypeOptions, behaviorId, 180, roleSpecificTypeEnabled, automaticTypeVisible),
		dropdownSetting(L["damageMeterHealerType"] or "Healer type", function() return normalizeDamageMeterTypeKey(cfg().healerDamageMeterType) end, function(value) self:SetConfigValue(index, "healerDamageMeterType", normalizeDamageMeterTypeKey(value)) end, buildDamageMeterTypeOptions, behaviorId, 180, roleSpecificTypeEnabled, automaticTypeVisible),
		dropdownSetting(L["damageMeterDpsType"] or "DPS type", function() return normalizeDamageMeterTypeKey(cfg().damagerDamageMeterType) end, function(value) self:SetConfigValue(index, "damagerDamageMeterType", normalizeDamageMeterTypeKey(value)) end, buildDamageMeterTypeOptions, behaviorId, 180, roleSpecificTypeEnabled, automaticTypeVisible),
		dividerSetting(behaviorId),
		dropdownSetting(L["damageMeterAutomaticClear"] or "Automatic clear", function() return normalizeAutoClearMode(db().damageMeterAutomaticClear) end, function(value)
			db().damageMeterAutomaticClear = normalizeAutoClearMode(value)
			requestEditModeSettingsRefresh()
		end, buildAutoClearOptions(), behaviorId, 120),
		{
			name = L["damageMeterAutomaticClearIn"] or "Clear in",
			kind = SettingType.MultiDropdown,
			field = "damageMeterAutomaticClearInstances",
			parentId = behaviorId,
			height = 115,
			values = buildAutoClearInstanceOptions(),
			hideSummary = true,
			isEnabled = function() return normalizeAutoClearMode(db().damageMeterAutomaticClear) ~= "never" end,
			get = function() return normalizeAutoClearInstances(db().damageMeterAutomaticClearInstances) end,
			set = function(_, selection)
				local instances = {}
				if type(selection) == "table" then
					if selection.party == true then instances.party = true end
					if selection.raid == true then instances.raid = true end
					if selection.raidEncounter == true then instances.raidEncounter = true end
				end
				db().damageMeterAutomaticClearInstances = instances
			end,
			isSelected = function(_, value)
				local instances = normalizeAutoClearInstances(db().damageMeterAutomaticClearInstances)
				return instances[value] == true
			end,
			setSelected = function(_, value, state)
				if value ~= "party" and value ~= "raid" and value ~= "raidEncounter" then return end
				local instances = normalizeAutoClearInstances(db().damageMeterAutomaticClearInstances)
				if state then
					instances[value] = true
				else
					instances[value] = nil
				end
				db().damageMeterAutomaticClearInstances = instances
			end,
		},
		dividerSetting(behaviorId),
		{
			name = L["damageMeterVisibility"] or "Show when",
			kind = SettingType.MultiDropdown,
			field = "visibility",
			parentId = behaviorId,
			height = 170,
			values = buildVisibilityOptions(),
			hideSummary = true,
			get = function() return normalizeVisibilityConfig(cfg().visibility) end,
			set = function(_, selection)
				local visibilityConfig
				if type(selection) == "table" then
					for key, selected in pairs(selection) do
						if selected == true and isVisibilityOptionAllowed(key) then
							if key == "ALWAYS_HIDDEN" then
								visibilityConfig = { ALWAYS_HIDDEN = true }
								break
							end
							visibilityConfig = visibilityConfig or {}
							visibilityConfig[key] = true
							visibilityConfig.ALWAYS_HIDDEN = nil
						end
					end
				end
				self:SetConfigValue(index, "visibility", visibilityConfig)
			end,
			isSelected = function(_, value)
				local visibilityConfig = normalizeVisibilityConfig(cfg().visibility)
				return visibilityConfig and visibilityConfig[value] == true or false
			end,
			setSelected = function(_, value, state)
				if not isVisibilityOptionAllowed(value) then return end
				local visibilityConfig = normalizeVisibilityConfig(cfg().visibility) or {}
				if state then
					if value == "ALWAYS_HIDDEN" then
						self:SetConfigValue(index, "visibility", { ALWAYS_HIDDEN = true })
						return
					end
					visibilityConfig[value] = true
					visibilityConfig.ALWAYS_HIDDEN = nil
				else
					visibilityConfig[value] = nil
				end
				if not next(visibilityConfig) then visibilityConfig = nil end
				self:SetConfigValue(index, "visibility", visibilityConfig)
			end,
		},
		sliderSetting(L["damageMeterVisibilityFadeAlpha"] or "Faded opacity", function() return cfg().visibilityFadeAlpha end, function(value) self:SetConfigValue(index, "visibilityFadeAlpha", clampNumber(value, 0, 1, DEFAULT_WINDOW.visibilityFadeAlpha)) end, 0, 1, 0.05, behaviorId, function() return normalizeVisibilityConfig(cfg().visibility) ~= nil end, nil, formatAlphaSliderValue),
		checkboxSetting(L["damageMeterShowNoData"] or "Show no data text", function() return cfg().showNoData ~= false end, function(value) self:SetConfigValue(index, "showNoData", value) end, behaviorId),
		{ name = L["Layout"] or "Layout", kind = SettingType.Collapsible, id = layoutId, defaultCollapsed = false },
		sliderSetting(L["damageMeterVisibleRows"] or "Visible rows", function() return cfg().visibleRows end, function(value) self:SetConfigValue(index, "visibleRows", clampNumber(value, 1, 30, DEFAULT_WINDOW.visibleRows)) end, 1, 30, 1, layoutId),
		dividerSetting(layoutId),
		checkboxSetting(L["damageMeterDifferentRaidRows"] or "Different settings in raid", function() return cfg().raidRowsEnabled == true end, function(value) self:SetConfigValue(index, "raidRowsEnabled", value) end, layoutId),
		sliderSetting(L["damageMeterRaidVisibleRows"] or "Raid visible rows", function() return cfg().raidVisibleRows end, function(value) self:SetConfigValue(index, "raidVisibleRows", clampNumber(value, 1, 30, DEFAULT_WINDOW.raidVisibleRows)) end, 1, 30, 1, layoutId, raidRowsEnabled),
		dividerSetting(layoutId),
		sliderSetting(L["Width"] or "Width", function() return cfg().width end, function(value) self:SetConfigValue(index, "width", clampNumber(value, 100, 700, DEFAULT_WINDOW.width)) end, 100, 700, 1, layoutId),
		sliderSetting(L["damageMeterHeightOffset"] or "Height offset", function() return cfg().heightOffset end, function(value) self:SetConfigValue(index, "heightOffset", clampNumber(value, 0, 300, DEFAULT_WINDOW.heightOffset)) end, 0, 300, 1, layoutId),
		checkboxSetting(L["damageMeterUnclampWindow"] or "Unclamp window", function() return cfg().unclampWindow == true end, function(value) self:SetConfigValue(index, "unclampWindow", value) end, layoutId),
		dividerSetting(layoutId),
		dropdownSetting(L["damageMeterHeaderPosition"] or "Header position", function() return normalizeHeaderPosition(cfg().headerPosition) end, function(value) self:SetConfigValue(index, "headerPosition", normalizeHeaderPosition(value)) end, buildHeaderPositionOptions(), layoutId, 120),
		dropdownSetting(L["damageMeterRowGrowth"] or "Rows grow", function() return normalizeRowGrowth(cfg().rowGrowth) end, function(value) self:SetConfigValue(index, "rowGrowth", normalizeRowGrowth(value)) end, buildRowGrowthOptions(), layoutId, 120),
		dropdownSetting(L["damageMeterRowSort"] or "Row order", function() return normalizeRowSort(cfg().rowSort) end, function(value) self:SetConfigValue(index, "rowSort", normalizeRowSort(value)) end, buildRowSortOptions(), layoutId, 160),
		dividerSetting(layoutId, nil, windowAnchorVisible),
		dropdownSetting(L["damageMeterAnchorToWindow"] or "Anchor to window", function() return tostring(clampNumber(cfg().anchorToWindow, 0, index - 1, 0)) end, function(value)
			self:SetConfigValue(index, "anchorToWindow", clampNumber(value, 0, index - 1, 0))
			requestEditModeSettingsRefresh()
		end, function() return buildWindowAnchorOptions(index) end, layoutId, 140, nil, windowAnchorVisible),
		dropdownSetting(L["damageMeterWindowAnchorPoint"] or "Anchor point", function() return normalizeFramePoint(cfg().windowAnchorPoint) end, function(value) self:SetConfigValue(index, "windowAnchorPoint", normalizeFramePoint(value)) end, buildFramePointOptions(), layoutId, 180, windowAnchorEnabled, windowAnchorVisible),
		dropdownSetting(L["damageMeterWindowRelativePoint"] or "Relative point", function() return normalizeFramePoint(cfg().windowRelativePoint) end, function(value) self:SetConfigValue(index, "windowRelativePoint", normalizeFramePoint(value)) end, buildFramePointOptions(), layoutId, 180, windowAnchorEnabled, windowAnchorVisible),
		sliderSetting(L["damageMeterWindowOffsetX"] or "Window X offset", function() return cfg().windowOffsetX end, function(value) self:SetConfigValue(index, "windowOffsetX", clampNumber(value, -1000, 1000, DEFAULT_WINDOW.windowOffsetX)) end, -1000, 1000, 1, layoutId, windowAnchorEnabled, windowAnchorVisible),
		sliderSetting(L["damageMeterWindowOffsetY"] or "Window Y offset", function() return cfg().windowOffsetY end, function(value) self:SetConfigValue(index, "windowOffsetY", clampNumber(value, -1000, 1000, DEFAULT_WINDOW.windowOffsetY)) end, -1000, 1000, 1, layoutId, windowAnchorEnabled, windowAnchorVisible),
		{ name = L["Header"] or "Header", kind = SettingType.Collapsible, id = headerId, defaultCollapsed = true },
		checkboxSetting(L["damageMeterShowHeader"] or "Show header", function() return cfg().showHeader == true end, function(value) self:SetConfigValue(index, "showHeader", value) end, headerId),
		checkboxSetting(L["damageMeterShowHeaderSession"] or "Show session", function() return cfg().showHeaderSession ~= false end, function(value) self:SetConfigValue(index, "showHeaderSession", value) end, headerId, headerEnabled),
		checkboxSetting(L["damageMeterShowHeaderType"] or "Show type", function() return cfg().showHeaderType ~= false end, function(value) self:SetConfigValue(index, "showHeaderType", value) end, headerId, headerEnabled),
		checkboxSetting(L["damageMeterShowHeaderTime"] or "Show combat time", function() return cfg().showHeaderTime ~= false end, function(value) self:SetConfigValue(index, "showHeaderTime", value) end, headerId, headerEnabled),
			checkboxSetting(L["damageMeterShowHeaderButtons"] or "Show header buttons", function() return cfg().showHeaderButtons ~= false end, function(value) self:SetConfigValue(index, "showHeaderButtons", value) end, headerId, headerEnabled),
			checkboxSetting(L["damageMeterShowReportButton"] or "Show report button", function() return cfg().showHeaderReportButton ~= false end, function(value) self:SetConfigValue(index, "showHeaderReportButton", value) end, headerId, function() return cfg().showHeader == true and cfg().showHeaderButtons ~= false end),
			checkboxSetting(L["damageMeterHeaderHistoryHover"] or "Open history on hover", function() return cfg().headerHistoryHover == true end, function(value) self:SetConfigValue(index, "headerHistoryHover", value) end, headerId, function() return cfg().showHeader == true and cfg().showHeaderButtons ~= false end),
			sliderSetting(L["damageMeterHeaderButtonSize"] or "Header button size", function() return cfg().headerButtonSize end, function(value) self:SetConfigValue(index, "headerButtonSize", clampNumber(value, 10, 32, DEFAULT_WINDOW.headerButtonSize)) end, 10, 32, 1, headerId, function() return cfg().showHeader == true and cfg().showHeaderButtons ~= false end),
		sliderSetting(L["damageMeterHeaderButtonOffsetX"] or "Header button X offset", function() return cfg().headerButtonOffsetX end, function(value) self:SetConfigValue(index, "headerButtonOffsetX", clampNumber(value, -100, 100, DEFAULT_WINDOW.headerButtonOffsetX)) end, -100, 100, 1, headerId, function() return cfg().showHeader == true and cfg().showHeaderButtons ~= false end),
		sliderSetting(L["damageMeterHeaderButtonOffsetY"] or "Header button Y offset", function() return cfg().headerButtonOffsetY end, function(value) self:SetConfigValue(index, "headerButtonOffsetY", clampNumber(value, -100, 100, DEFAULT_WINDOW.headerButtonOffsetY)) end, -100, 100, 1, headerId, function() return cfg().showHeader == true and cfg().showHeaderButtons ~= false end),
		colorSetting(L["damageMeterHeaderButtonColor"] or "Header button color", function() return normalizeColor(cfg().headerButtonColor, DEFAULT_WINDOW.headerButtonColor) end, function(value) self:SetConfigValue(index, "headerButtonColor", normalizeColor(value, DEFAULT_WINDOW.headerButtonColor)) end, DEFAULT_WINDOW.headerButtonColor, headerId, function() return cfg().showHeader == true and cfg().showHeaderButtons ~= false end),
		sliderSetting(L["damageMeterHeaderButtonAlpha"] or "Header button opacity", function() return cfg().headerButtonAlpha end, function(value) self:SetConfigValue(index, "headerButtonAlpha", clampNumber(value, 0, 1, DEFAULT_WINDOW.headerButtonAlpha)) end, 0, 1, 0.05, headerId, function() return cfg().showHeader == true and cfg().showHeaderButtons ~= false end, nil, formatAlphaSliderValue),
		checkboxSetting(L["damageMeterHeaderButtonFade"] or "Fade header buttons", function() return cfg().headerButtonFadeEnabled == true end, function(value) self:SetConfigValue(index, "headerButtonFadeEnabled", value) end, headerId, function() return cfg().showHeader == true and cfg().showHeaderButtons ~= false end),
		sliderSetting(L["damageMeterHeaderButtonFadeAlpha"] or "Faded button opacity", function() return cfg().headerButtonFadeAlpha end, function(value) self:SetConfigValue(index, "headerButtonFadeAlpha", clampNumber(value, 0, 1, DEFAULT_WINDOW.headerButtonFadeAlpha)) end, 0, 1, 0.05, headerId, function() return cfg().showHeader == true and cfg().showHeaderButtons ~= false and cfg().headerButtonFadeEnabled == true end, nil, formatAlphaSliderValue),
		dividerSetting(headerId),
		checkboxSetting(L["damageMeterHeaderBackground"] or "Header background", function() return cfg().headerBackgroundEnabled == true end, function(value)
			self:SetConfigValue(index, "headerBackgroundEnabled", value)
			requestEditModeSettingsRefresh()
		end, headerId, headerEnabled),
		checkboxSetting(L["damageMeterHeaderBackgroundUseCustomTexture"] or "Custom texture", function() return cfg().headerBackgroundUseCustomTexture == true end, function(value)
			self:SetConfigValue(index, "headerBackgroundUseCustomTexture", value)
			requestEditModeSettingsRefresh()
		end, headerId, headerBackgroundEnabled),
		inputSetting(L["damageMeterHeaderBackgroundCustomTexture"] or "Atlas name or texture ID", function() return cfg().headerBackgroundCustomTexture or "" end, function(value) self:SetConfigValue(index, "headerBackgroundCustomTexture", trimTextureInput(value)) end, headerId, function() return headerBackgroundEnabled() and cfg().headerBackgroundUseCustomTexture == true end, L["damageMeterHeaderBackgroundCustomTextureDesc"] or "Enter an atlas name, texture file ID, or texture path.", 160),
		dropdownSetting(L["damageMeterHeaderBackgroundTexture"] or "Header background texture", function() return cfg().headerBackgroundTexture end, function(value) self:SetConfigValue(index, "headerBackgroundTexture", value) end, buildMediaOptions("statusbar", false), headerId, 260, function() return headerBackgroundEnabled() and cfg().headerBackgroundUseCustomTexture ~= true end),
		colorSetting(L["damageMeterHeaderBackgroundColor"] or "Header background color", function() return normalizeColor(cfg().headerBackgroundColor, DEFAULT_WINDOW.headerBackgroundColor) end, function(value) self:SetConfigValue(index, "headerBackgroundColor", normalizeColor(value, DEFAULT_WINDOW.headerBackgroundColor)) end, DEFAULT_WINDOW.headerBackgroundColor, headerId, headerBackgroundEnabled),
		sliderSetting(L["damageMeterHeaderBackgroundOffsetX"] or "X offset", function() return cfg().headerBackgroundOffsetX end, function(value) self:SetConfigValue(index, "headerBackgroundOffsetX", clampNumber(value, -200, 200, DEFAULT_WINDOW.headerBackgroundOffsetX)) end, -200, 200, 1, headerId, headerBackgroundEnabled),
		sliderSetting(L["damageMeterHeaderBackgroundOffsetY"] or "Y offset", function() return cfg().headerBackgroundOffsetY end, function(value) self:SetConfigValue(index, "headerBackgroundOffsetY", clampNumber(value, -200, 200, DEFAULT_WINDOW.headerBackgroundOffsetY)) end, -200, 200, 1, headerId, headerBackgroundEnabled),
		sliderSetting(L["damageMeterHeaderBackgroundSizeOffsetX"] or "Width offset", function() return cfg().headerBackgroundSizeOffsetX end, function(value) self:SetConfigValue(index, "headerBackgroundSizeOffsetX", clampNumber(value, -200, 200, DEFAULT_WINDOW.headerBackgroundSizeOffsetX)) end, -200, 200, 1, headerId, headerBackgroundEnabled),
		sliderSetting(L["damageMeterHeaderBackgroundSizeOffsetY"] or "Height offset", function() return cfg().headerBackgroundSizeOffsetY end, function(value) self:SetConfigValue(index, "headerBackgroundSizeOffsetY", clampNumber(value, -200, 200, DEFAULT_WINDOW.headerBackgroundSizeOffsetY)) end, -200, 200, 1, headerId, headerBackgroundEnabled),
		dividerSetting(headerId),
		dropdownSetting(L["damageMeterHeaderFormat"] or "Header format", function() return normalizeHeaderFormat(cfg().headerFormat) end, function(value) self:SetConfigValue(index, "headerFormat", normalizeHeaderFormat(value)) end, buildHeaderFormatOptions(), headerId, 150, headerTimeEnabled),
		dropdownSetting(L["damageMeterHeaderTimeFormat"] or "Time format", function() return normalizeHeaderTimeFormat(cfg().headerTimeFormat) end, function(value) self:SetConfigValue(index, "headerTimeFormat", normalizeHeaderTimeFormat(value)) end, buildHeaderTimeFormatOptions(), headerId, 120, headerTimeEnabled),
		dividerSetting(headerId),
		dropdownSetting(L["damageMeterTitleFont"] or "Title font", function() return cfg().titleFontFace end, function(value) self:SetConfigValue(index, "titleFontFace", value) end, buildMediaOptions("font", true), headerId, 260, headerEnabled),
		dropdownSetting(L["damageMeterTitleFontOutline"] or "Title font outline", function() return cfg().titleFontOutline end, function(value) self:SetConfigValue(index, "titleFontOutline", normalizeStyle(value)) end, buildStyleOptions(), headerId, 180, headerEnabled),
		sliderSetting(L["damageMeterTitleFontSize"] or "Title font size", function() return cfg().titleFontSize end, function(value) self:SetConfigValue(index, "titleFontSize", clampNumber(value, 8, 28, DEFAULT_WINDOW.titleFontSize)) end, 8, 28, 1, headerId, headerEnabled),
		colorSetting(L["damageMeterHeaderColor"] or "Header color", function() return normalizeColor(cfg().titleColor, DEFAULT_WINDOW.titleColor) end, function(value) self:SetConfigValue(index, "titleColor", normalizeColor(value, DEFAULT_WINDOW.titleColor)) end, DEFAULT_WINDOW.titleColor, headerId, headerEnabled),
		sliderSetting(L["damageMeterHeaderTextOffsetX"] or "Header text X offset", function() return cfg().headerTextOffsetX end, function(value) self:SetConfigValue(index, "headerTextOffsetX", clampNumber(value, -100, 100, DEFAULT_WINDOW.headerTextOffsetX)) end, -100, 100, 1, headerId, headerEnabled),
		sliderSetting(L["damageMeterHeaderTextOffsetY"] or "Header text Y offset", function() return cfg().headerTextOffsetY end, function(value) self:SetConfigValue(index, "headerTextOffsetY", clampNumber(value, -100, 100, DEFAULT_WINDOW.headerTextOffsetY)) end, -100, 100, 1, headerId, headerEnabled),
		{ name = L["damageMeterContentBackground"] or "Content background", kind = SettingType.Collapsible, id = contentBackgroundId, defaultCollapsed = true },
		checkboxSetting(L["damageMeterContentBackground"] or "Content background", function() return cfg().contentBackgroundEnabled == true end, function(value)
			self:SetConfigValue(index, "contentBackgroundEnabled", value)
			requestEditModeSettingsRefresh()
		end, contentBackgroundId),
		checkboxSetting(L["damageMeterContentBackgroundUseCustomTexture"] or "Custom texture", function() return cfg().contentBackgroundUseCustomTexture == true end, function(value)
			self:SetConfigValue(index, "contentBackgroundUseCustomTexture", value)
			requestEditModeSettingsRefresh()
		end, contentBackgroundId, contentBackgroundEnabled),
		inputSetting(L["damageMeterContentBackgroundCustomTexture"] or "Atlas name or texture ID", function() return cfg().contentBackgroundCustomTexture or "" end, function(value) self:SetConfigValue(index, "contentBackgroundCustomTexture", trimTextureInput(value)) end, contentBackgroundId, function() return contentBackgroundEnabled() and cfg().contentBackgroundUseCustomTexture == true end, L["damageMeterHeaderBackgroundCustomTextureDesc"] or "Enter an atlas name, texture file ID, or texture path.", 160),
		dropdownSetting(L["damageMeterContentBackgroundTexture"] or "Texture", function() return cfg().contentBackgroundTexture end, function(value) self:SetConfigValue(index, "contentBackgroundTexture", value) end, buildMediaOptions("statusbar", false), contentBackgroundId, 260, function() return contentBackgroundEnabled() and cfg().contentBackgroundUseCustomTexture ~= true end),
		colorSetting(L["damageMeterContentBackgroundColor"] or "Color", function() return normalizeColor(cfg().contentBackgroundColor, DEFAULT_WINDOW.contentBackgroundColor) end, function(value) self:SetConfigValue(index, "contentBackgroundColor", normalizeColor(value, DEFAULT_WINDOW.contentBackgroundColor)) end, DEFAULT_WINDOW.contentBackgroundColor, contentBackgroundId, contentBackgroundEnabled),
		sliderSetting(L["damageMeterContentBackgroundOffsetX"] or "X offset", function() return cfg().contentBackgroundOffsetX end, function(value) self:SetConfigValue(index, "contentBackgroundOffsetX", clampNumber(value, -200, 200, DEFAULT_WINDOW.contentBackgroundOffsetX)) end, -200, 200, 1, contentBackgroundId, contentBackgroundEnabled),
		sliderSetting(L["damageMeterContentBackgroundOffsetY"] or "Y offset", function() return cfg().contentBackgroundOffsetY end, function(value) self:SetConfigValue(index, "contentBackgroundOffsetY", clampNumber(value, -200, 200, DEFAULT_WINDOW.contentBackgroundOffsetY)) end, -200, 200, 1, contentBackgroundId, contentBackgroundEnabled),
		sliderSetting(L["damageMeterContentBackgroundSizeOffsetX"] or "Width offset", function() return cfg().contentBackgroundSizeOffsetX end, function(value) self:SetConfigValue(index, "contentBackgroundSizeOffsetX", clampNumber(value, -200, 200, DEFAULT_WINDOW.contentBackgroundSizeOffsetX)) end, -200, 200, 1, contentBackgroundId, contentBackgroundEnabled),
		sliderSetting(L["damageMeterContentBackgroundSizeOffsetY"] or "Height offset", function() return cfg().contentBackgroundSizeOffsetY end, function(value) self:SetConfigValue(index, "contentBackgroundSizeOffsetY", clampNumber(value, -200, 200, DEFAULT_WINDOW.contentBackgroundSizeOffsetY)) end, -200, 200, 1, contentBackgroundId, contentBackgroundEnabled),
		{ name = L["damageMeterFooter"] or "Footer", kind = SettingType.Collapsible, id = statusId, defaultCollapsed = true },
		checkboxSetting(L["damageMeterShowFooter"] or "Show footer", function() return cfg().showStatus ~= false end, function(value)
			self:SetConfigValue(index, "showStatus", value)
			requestEditModeSettingsRefresh()
		end, statusId),
		checkboxSetting(L["damageMeterShowFooterQuickSwitch"] or "Show quick switch", function() return cfg().showFooterQuickSwitch ~= false end, function(value) self:SetConfigValue(index, "showFooterQuickSwitch", value) end, statusId, statusEnabled, L["damageMeterQuickSwitchTooltip"] or "Left-click cycles through selected quick switch favorites. Right-click switches between Current and Overall."),
		dropdownSetting(L["damageMeterFooterFont"] or "Footer font", function() return cfg().statusFontFace end, function(value) self:SetConfigValue(index, "statusFontFace", value) end, buildMediaOptions("font", true), statusId, 260, statusEnabled),
		dropdownSetting(L["damageMeterFooterFontOutline"] or "Footer font outline", function() return cfg().statusFontOutline end, function(value) self:SetConfigValue(index, "statusFontOutline", normalizeStyle(value)) end, buildStyleOptions(), statusId, 180, statusEnabled),
		sliderSetting(L["damageMeterFooterFontSize"] or "Footer font size", function() return cfg().statusFontSize end, function(value) self:SetConfigValue(index, "statusFontSize", clampNumber(value, 8, 24, DEFAULT_WINDOW.statusFontSize)) end, 8, 24, 1, statusId, statusEnabled),
		dividerSetting(statusId),
		checkboxSetting(L["damageMeterFooterBackground"] or "Footer background", function() return cfg().footerBackgroundEnabled == true end, function(value)
			self:SetConfigValue(index, "footerBackgroundEnabled", value)
			requestEditModeSettingsRefresh()
		end, statusId, statusEnabled),
		checkboxSetting(L["damageMeterFooterBackgroundUseCustomTexture"] or "Custom texture", function() return cfg().footerBackgroundUseCustomTexture == true end, function(value)
			self:SetConfigValue(index, "footerBackgroundUseCustomTexture", value)
			requestEditModeSettingsRefresh()
		end, statusId, footerBackgroundEnabled),
		inputSetting(L["damageMeterFooterBackgroundCustomTexture"] or "Atlas name or texture ID", function() return cfg().footerBackgroundCustomTexture or "" end, function(value) self:SetConfigValue(index, "footerBackgroundCustomTexture", trimTextureInput(value)) end, statusId, function() return footerBackgroundEnabled() and cfg().footerBackgroundUseCustomTexture == true end, L["damageMeterHeaderBackgroundCustomTextureDesc"] or "Enter an atlas name, texture file ID, or texture path.", 160),
		dropdownSetting(L["damageMeterFooterBackgroundTexture"] or "Texture", function() return cfg().footerBackgroundTexture end, function(value) self:SetConfigValue(index, "footerBackgroundTexture", value) end, buildMediaOptions("statusbar", false), statusId, 260, function() return footerBackgroundEnabled() and cfg().footerBackgroundUseCustomTexture ~= true end),
		colorSetting(L["damageMeterFooterBackgroundColor"] or "Color", function() return normalizeColor(cfg().footerBackgroundColor, DEFAULT_WINDOW.footerBackgroundColor) end, function(value) self:SetConfigValue(index, "footerBackgroundColor", normalizeColor(value, DEFAULT_WINDOW.footerBackgroundColor)) end, DEFAULT_WINDOW.footerBackgroundColor, statusId, footerBackgroundEnabled),
		sliderSetting(L["damageMeterFooterBackgroundOffsetX"] or "X offset", function() return cfg().footerBackgroundOffsetX end, function(value) self:SetConfigValue(index, "footerBackgroundOffsetX", clampNumber(value, -200, 200, DEFAULT_WINDOW.footerBackgroundOffsetX)) end, -200, 200, 1, statusId, footerBackgroundEnabled),
		sliderSetting(L["damageMeterFooterBackgroundOffsetY"] or "Y offset", function() return cfg().footerBackgroundOffsetY end, function(value) self:SetConfigValue(index, "footerBackgroundOffsetY", clampNumber(value, -200, 200, DEFAULT_WINDOW.footerBackgroundOffsetY)) end, -200, 200, 1, statusId, footerBackgroundEnabled),
		sliderSetting(L["damageMeterFooterBackgroundSizeOffsetX"] or "Width offset", function() return cfg().footerBackgroundSizeOffsetX end, function(value) self:SetConfigValue(index, "footerBackgroundSizeOffsetX", clampNumber(value, -200, 200, DEFAULT_WINDOW.footerBackgroundSizeOffsetX)) end, -200, 200, 1, statusId, footerBackgroundEnabled),
		sliderSetting(L["damageMeterFooterBackgroundSizeOffsetY"] or "Height offset", function() return cfg().footerBackgroundSizeOffsetY end, function(value) self:SetConfigValue(index, "footerBackgroundSizeOffsetY", clampNumber(value, -200, 200, DEFAULT_WINDOW.footerBackgroundSizeOffsetY)) end, -200, 200, 1, statusId, footerBackgroundEnabled),
		{ name = L["Bar"] or "Bar", kind = SettingType.Collapsible, id = barId, defaultCollapsed = true },
		sliderSetting(L["damageMeterRowHeight"] or "Row height", function() return cfg().rowHeight end, function(value) self:SetConfigValue(index, "rowHeight", clampNumber(value, 10, 70, DEFAULT_WINDOW.rowHeight)) end, 10, 70, 1, barId),
		dividerSetting(barId),
		checkboxSetting(L["damageMeterChangeBarSize"] or "Change bar size", function() return cfg().changeBarSize == true end, function(value) self:SetConfigValue(index, "changeBarSize", value) end, barId),
		sliderSetting(L["damageMeterBarHeight"] or "Bar height", function() return math.min(clampNumber(cfg().barHeight, 1, 70, DEFAULT_WINDOW.barHeight), clampNumber(cfg().rowHeight, 10, 70, DEFAULT_WINDOW.rowHeight)) end, function(value) self:SetConfigValue(index, "barHeight", clampNumber(value, 1, clampNumber(cfg().rowHeight, 10, 70, DEFAULT_WINDOW.rowHeight), DEFAULT_WINDOW.barHeight)) end, 1, 70, 1, barId, customBarSizeEnabled),
		dropdownSetting(L["damageMeterBarAnchor"] or "Bar anchor", function() return normalizeAnchorV(cfg().barAnchor) end, function(value) self:SetConfigValue(index, "barAnchor", normalizeAnchorV(value)) end, buildVerticalAnchorOptions(), barId, 120, customBarSizeEnabled),
		sliderSetting(L["damageMeterBarWidthOffset"] or "Bar width offset", function() return cfg().barWidthOffset end, function(value) self:SetConfigValue(index, "barWidthOffset", clampNumber(value, -200, 200, DEFAULT_WINDOW.barWidthOffset)) end, -200, 200, 1, barId),
		dividerSetting(barId),
		sliderSetting(L["damageMeterBarSpacing"] or "Bar spacing", function() return cfg().barSpacing end, function(value) self:SetConfigValue(index, "barSpacing", clampNumber(value, -16, 16, DEFAULT_WINDOW.barSpacing)) end, -16, 16, 1, barId),
		dividerSetting(barId),
		dropdownSetting(L["Texture"] or "Texture", function() return cfg().texture end, function(value) self:SetConfigValue(index, "texture", value) end, buildMediaOptions("statusbar", false), barId, 260),
		checkboxSetting(L["damageMeterUseClassColors"] or "Use class colors", function() return cfg().useClassColors == true end, function(value) self:SetConfigValue(index, "useClassColors", value) end, barId),
		colorNoOpacitySetting(L["damageMeterBarColor"] or "Color", function() return normalizeColor(cfg().barColor, DEFAULT_WINDOW.barColor) end, function(value)
			local color = normalizeColor(value, DEFAULT_WINDOW.barColor)
			color.a = 1
			self:SetConfigValue(index, "barColor", color)
		end, DEFAULT_WINDOW.barColor, barId, fixedBarColorEnabled),
		sliderSetting(L["damageMeterBarOpacity"] or "Bar opacity", function() return cfg().barOpacity end, function(value) self:SetConfigValue(index, "barOpacity", clampNumber(value, 0, 1, DEFAULT_WINDOW.barOpacity)) end, 0, 1, 0.05, barId, nil, nil, formatAlphaSliderValue),
		checkboxSetting(L["damageMeterSmoothBars"] or "Smooth bars", function() return cfg().smoothBars == true end, function(value) self:SetConfigValue(index, "smoothBars", value) end, barId),
		checkboxSetting(L["damageMeterBarBackgroundUseCustomTexture"] or "Custom background texture", function() return cfg().barBackgroundUseCustomTexture == true end, function(value)
			self:SetConfigValue(index, "barBackgroundUseCustomTexture", value)
			requestEditModeSettingsRefresh()
		end, barId),
		inputSetting(L["damageMeterBarBackgroundCustomTexture"] or "Atlas name or texture ID", function() return cfg().barBackgroundCustomTexture or "" end, function(value) self:SetConfigValue(index, "barBackgroundCustomTexture", trimTextureInput(value)) end, barId, function() return cfg().barBackgroundUseCustomTexture == true end, L["damageMeterHeaderBackgroundCustomTextureDesc"] or "Enter an atlas name, texture file ID, or texture path.", 160),
		dropdownSetting(L["damageMeterBarBackgroundTexture"] or "Background texture", function() return cfg().barBackgroundTexture end, function(value) self:SetConfigValue(index, "barBackgroundTexture", value) end, buildMediaOptions("statusbar", false), barId, 260, function() return cfg().barBackgroundUseCustomTexture ~= true end),
		colorSetting(L["damageMeterBarBackgroundColor"] or "Background color", function() return normalizeColor(cfg().barBackgroundColor, DEFAULT_WINDOW.barBackgroundColor) end, function(value) self:SetConfigValue(index, "barBackgroundColor", normalizeColor(value, DEFAULT_WINDOW.barBackgroundColor)) end, DEFAULT_WINDOW.barBackgroundColor, barId),
		dividerSetting(barId),
		checkboxSetting(L["damageMeterRowBorder"] or "Row border", function() return cfg().rowBorderEnabled == true end, function(value)
			self:SetConfigValue(index, "rowBorderEnabled", value)
			requestEditModeSettingsRefresh()
		end, barId),
		dropdownSetting(L["damageMeterRowBorderTexture"] or "Row border texture", function() return cfg().rowBorderTexture end, function(value) self:SetConfigValue(index, "rowBorderTexture", value) end, buildMediaOptions("border", false), barId, 260, rowBorderEnabled),
		checkboxSetting(L["damageMeterUseClassColor"] or "Use class color", function() return cfg().rowBorderUseClassColor == true end, function(value)
			self:SetConfigValue(index, "rowBorderUseClassColor", value)
			requestEditModeSettingsRefresh()
		end, barId, rowBorderEnabled),
		colorSetting(L["damageMeterRowBorderColor"] or "Row border color", function() return normalizeColor(cfg().rowBorderColor, DEFAULT_WINDOW.rowBorderColor) end, function(value) self:SetConfigValue(index, "rowBorderColor", normalizeColor(value, DEFAULT_WINDOW.rowBorderColor)) end, DEFAULT_WINDOW.rowBorderColor, barId, fixedRowBorderColorEnabled),
		sliderSetting(L["damageMeterRowBorderSize"] or "Row border size", function() return cfg().rowBorderSize end, function(value) self:SetConfigValue(index, "rowBorderSize", clampNumber(value, 1, 32, DEFAULT_WINDOW.rowBorderSize)) end, 1, 32, 1, barId, rowBorderEnabled),
		sliderSetting(L["damageMeterRowBorderOffset"] or "Row border offset", function() return cfg().rowBorderInset end, function(value) self:SetConfigValue(index, "rowBorderInset", clampNumber(value, 0, 24, DEFAULT_WINDOW.rowBorderInset)) end, 0, 24, 1, barId, rowBorderEnabled),
		dividerSetting(barId),
		checkboxSetting(L["damageMeterBarBorder"] or "Bar border", function() return cfg().barBorderEnabled == true end, function(value) self:SetConfigValue(index, "barBorderEnabled", value) end, barId),
		dropdownSetting(L["damageMeterBarBorderTexture"] or "Bar border texture", function() return cfg().barBorderTexture end, function(value) self:SetConfigValue(index, "barBorderTexture", value) end, buildMediaOptions("border", false), barId, 260, barBorderEnabled),
		checkboxSetting(L["damageMeterUseClassColor"] or "Use class color", function() return cfg().barBorderUseClassColor == true end, function(value)
			self:SetConfigValue(index, "barBorderUseClassColor", value)
			requestEditModeSettingsRefresh()
		end, barId, barBorderEnabled),
		colorSetting(L["damageMeterBarBorderColor"] or "Bar border color", function() return normalizeColor(cfg().barBorderColor, DEFAULT_WINDOW.barBorderColor) end, function(value) self:SetConfigValue(index, "barBorderColor", normalizeColor(value, DEFAULT_WINDOW.barBorderColor)) end, DEFAULT_WINDOW.barBorderColor, barId, fixedBarBorderColorEnabled),
		sliderSetting(L["damageMeterBarBorderSize"] or "Bar border size", function() return cfg().barBorderSize end, function(value) self:SetConfigValue(index, "barBorderSize", clampNumber(value, 1, 32, DEFAULT_WINDOW.barBorderSize)) end, 1, 32, 1, barId, barBorderEnabled),
		sliderSetting(L["damageMeterBarBorderOffset"] or "Bar border offset", function() return cfg().barBorderInset end, function(value) self:SetConfigValue(index, "barBorderInset", clampNumber(value, 0, 24, DEFAULT_WINDOW.barBorderInset)) end, 0, 24, 1, barId, barBorderEnabled),
		{ name = L["damageMeterIcon"] or "Icon", kind = SettingType.Collapsible, id = iconId, defaultCollapsed = true },
		checkboxSetting(L["damageMeterShowIcons"] or "Show icons", function() return cfg().showIcons ~= false end, function(value)
			self:SetConfigValue(index, "showIcons", value)
			requestEditModeSettingsRefresh()
		end, iconId),
		dropdownSetting(L["damageMeterIconType"] or "Icon type", function() return cfg().iconType == "spec" and "spec" or "class" end, function(value)
			self:SetConfigValue(index, "iconType", value == "spec" and "spec" or "class")
			requestEditModeSettingsRefresh()
		end, {
			{ value = "class", label = L["damageMeterIconTypeClass"] or "Class icon" },
			{ value = "spec", label = L["damageMeterIconTypeSpec"] or "Spec icon" },
		}, iconId, 160, iconsEnabled),
		checkboxSetting(L["damageMeterUseCustomClassIconTexture"] or "Use custom class icon texture", function() return cfg().iconUseCustomClassTexture == true end, function(value)
			self:SetConfigValue(index, "iconUseCustomClassTexture", value)
			requestEditModeSettingsRefresh()
		end, iconId, function() return iconsEnabled() and cfg().iconType ~= "spec" end, L["damageMeterUseCustomClassIconTextureDesc"] or "Use a class icon sheet with the same coordinate layout as Blizzard class icons."),
		inputSetting(L["damageMeterCustomClassIconTexture"] or "Class icon texture path", function() return cfg().iconCustomClassTexture or "" end, function(value) self:SetConfigValue(index, "iconCustomClassTexture", trimTextureInput(value)) end, iconId, function() return cfg().showIcons ~= false and cfg().iconType ~= "spec" and cfg().iconUseCustomClassTexture == true end, L["damageMeterCustomClassIconTextureDesc"] or "Enter a texture path for a class icon sheet. The sheet must match Blizzard class icon coordinates.", 180),
		dividerSetting(iconId),
		checkboxSetting(L["damageMeterChangeIconSize"] or "Change icon size", function() return cfg().changeIconSize == true end, function(value)
			self:SetConfigValue(index, "changeIconSize", value)
			requestEditModeSettingsRefresh()
		end, iconId, iconsEnabled),
		sliderSetting(L["damageMeterIconSizeOffset"] or "Icon size offset", function() return cfg().iconSizeOffset end, function(value) self:SetConfigValue(index, "iconSizeOffset", clampNumber(value, -60, 0, DEFAULT_WINDOW.iconSizeOffset)) end, -60, 0, 1, iconId, customIconSizeEnabled),
		sliderSetting(L["damageMeterIconGap"] or "Icon gap", function() return cfg().iconGap end, function(value) self:SetConfigValue(index, "iconGap", clampNumber(value, 0, 24, DEFAULT_WINDOW.iconGap)) end, 0, 24, 1, iconId, iconsEnabled),
		dividerSetting(iconId),
		checkboxSetting(L["damageMeterIconBorder"] or "Icon border", function() return cfg().iconBorderEnabled == true end, function(value)
			self:SetConfigValue(index, "iconBorderEnabled", value)
			requestEditModeSettingsRefresh()
		end, iconId, iconsEnabled),
		dropdownSetting(L["damageMeterIconBorderTexture"] or "Icon border texture", function() return cfg().iconBorderTexture end, function(value) self:SetConfigValue(index, "iconBorderTexture", value) end, buildMediaOptions("border", false), iconId, 260, iconBorderEnabled),
		checkboxSetting(L["damageMeterUseClassColor"] or "Use class color", function() return cfg().iconBorderUseClassColor == true end, function(value)
			self:SetConfigValue(index, "iconBorderUseClassColor", value)
			requestEditModeSettingsRefresh()
		end, iconId, iconBorderEnabled),
		colorSetting(L["damageMeterIconBorderColor"] or "Icon border color", function() return normalizeColor(cfg().iconBorderColor, DEFAULT_WINDOW.iconBorderColor) end, function(value) self:SetConfigValue(index, "iconBorderColor", normalizeColor(value, DEFAULT_WINDOW.iconBorderColor)) end, DEFAULT_WINDOW.iconBorderColor, iconId, fixedIconBorderColorEnabled),
		sliderSetting(L["damageMeterIconBorderSize"] or "Icon border size", function() return cfg().iconBorderSize end, function(value) self:SetConfigValue(index, "iconBorderSize", clampNumber(value, 1, 32, DEFAULT_WINDOW.iconBorderSize)) end, 1, 32, 1, iconId, iconBorderEnabled),
		sliderSetting(L["damageMeterIconBorderOffset"] or "Icon border offset", function() return cfg().iconBorderInset end, function(value) self:SetConfigValue(index, "iconBorderInset", clampNumber(value, 0, 24, DEFAULT_WINDOW.iconBorderInset)) end, 0, 24, 1, iconId, iconBorderEnabled),
		{ name = L["damageMeterNames"] or "Names", kind = SettingType.Collapsible, id = namesId, defaultCollapsed = true },
		checkboxSetting(L["damageMeterShowNames"] or "Show names", function() return cfg().showNames == true end, function(value) self:SetConfigValue(index, "showNames", value) end, namesId),
		checkboxSetting(L["damageMeterHideRealmNames"] or "Hide realm names", function() return cfg().hideRealmNames ~= false end, function(value) self:SetConfigValue(index, "hideRealmNames", value) end, namesId, namesEnabled),
		checkboxSetting(L["damageMeterNameNoEllipsis"] or "Truncate without ellipsis", function() return cfg().nameNoEllipsis == true end, function(value) self:SetConfigValue(index, "nameNoEllipsis", value) end, namesId, namesEnabled),
		checkboxSetting(L["damageMeterNameUseClassColor"] or "Use class color for names", function() return cfg().nameUseClassColors == true end, function(value) self:SetConfigValue(index, "nameUseClassColors", value) end, namesId, namesEnabled),
		colorSetting(L["damageMeterNameColor"] or "Name color", function() return normalizeColor(cfg().nameColor, DEFAULT_WINDOW.nameColor) end, function(value) self:SetConfigValue(index, "nameColor", normalizeColor(value, DEFAULT_WINDOW.nameColor)) end, DEFAULT_WINDOW.nameColor, namesId, fixedNameColorEnabled),
		dividerSetting(namesId),
		dropdownSetting(L["damageMeterNameFont"] or "Name font", function() return cfg().fontFace end, function(value) self:SetConfigValue(index, "fontFace", value) end, buildMediaOptions("font", true), namesId, 260, namesEnabled),
		dropdownSetting(L["damageMeterNameFontOutline"] or "Name font outline", function() return cfg().fontOutline end, function(value) self:SetConfigValue(index, "fontOutline", normalizeStyle(value)) end, buildStyleOptions(), namesId, 180, namesEnabled),
		sliderSetting(L["damageMeterNameFontSize"] or "Name font size", function() return cfg().fontSize end, function(value) self:SetConfigValue(index, "fontSize", clampNumber(value, 8, 24, DEFAULT_WINDOW.fontSize)) end, 8, 24, 1, namesId, namesEnabled),
		dividerSetting(namesId),
		sliderSetting(L["damageMeterMinimumNameWidth"] or "Minimum name width", function() return cfg().minNameWidth end, function(value) self:SetConfigValue(index, "minNameWidth", clampNumber(value, 0, 180, DEFAULT_WINDOW.minNameWidth)) end, 0, 180, 1, namesId, function() return namesEnabled() and combinedValueLayoutEnabled() end, function() return namesEnabled() and combinedValueLayoutEnabled() end),
		dividerSetting(namesId),
		dropdownSetting(L["damageMeterNameAnchorV"] or "Name vertical anchor", function() return normalizeAnchorV(cfg().nameAnchorV) end, function(value) self:SetConfigValue(index, "nameAnchorV", normalizeAnchorV(value)) end, buildVerticalAnchorOptions(), namesId, 120, namesEnabled, namesEnabled),
		sliderSetting(L["damageMeterNameOffsetX"] or "Name X offset", function() return cfg().nameOffsetX end, function(value) self:SetConfigValue(index, "nameOffsetX", clampNumber(value, -200, 200, DEFAULT_WINDOW.nameOffsetX)) end, -200, 200, 1, namesId, namesEnabled, namesEnabled),
		sliderSetting(L["damageMeterNameOffsetY"] or "Name Y offset", function() return cfg().nameOffsetY end, function(value) self:SetConfigValue(index, "nameOffsetY", clampNumber(value, -200, 200, DEFAULT_WINDOW.nameOffsetY)) end, -200, 200, 1, namesId, namesEnabled, namesEnabled),
		{ name = L["damageMeterValues"] or "Values", kind = SettingType.Collapsible, id = valuesId, defaultCollapsed = true },
		checkboxSetting(L["damageMeterShowPercent"] or "Show percent", function() return cfg().showPercent ~= false end, function(value) self:SetConfigValue(index, "showPercent", value) end, valuesId),
		dividerSetting(valuesId),
		checkboxSetting(L["damageMeterUseClassColor"] or "Use class color", function() return cfg().valueUseClassColors == true end, function(value)
			self:SetConfigValue(index, "valueUseClassColors", value)
			requestEditModeSettingsRefresh()
		end, valuesId),
		colorSetting(L["damageMeterValueColor"] or "Value color", function() return normalizeColor(cfg().valueColor, DEFAULT_WINDOW.valueColor) end, function(value) self:SetConfigValue(index, "valueColor", normalizeColor(value, DEFAULT_WINDOW.valueColor)) end, DEFAULT_WINDOW.valueColor, valuesId, fixedValueColorEnabled),
		dividerSetting(valuesId),
		dropdownSetting(L["damageMeterValueFont"] or "Value font", function() return cfg().valueFontFace end, function(value) self:SetConfigValue(index, "valueFontFace", value) end, buildMediaOptions("font", true), valuesId, 260),
		dropdownSetting(L["damageMeterValueFontOutline"] or "Value font outline", function() return cfg().valueFontOutline end, function(value) self:SetConfigValue(index, "valueFontOutline", normalizeStyle(value)) end, buildStyleOptions(), valuesId, 180),
		sliderSetting(L["damageMeterValueFontSize"] or "Value font size", function() return cfg().valueFontSize end, function(value) self:SetConfigValue(index, "valueFontSize", clampNumber(value, 8, 24, DEFAULT_WINDOW.valueFontSize)) end, 8, 24, 1, valuesId),
		dividerSetting(valuesId),
		dropdownSetting(L["damageMeterValueLayout"] or "Value layout", function() return getRowValueLayout(cfg()) end, function(value)
			self:SetConfigValue(index, "valueLayout", normalizeValueLayout(value))
			requestEditModeSettingsRefresh()
		end, buildValueLayoutOptions(), valuesId, 120),
		sliderSetting(L["damageMeterAmountColumnWidth"] or "Amount column width", function() return cfg().amountColumnWidth end, function(value) self:SetConfigValue(index, "amountColumnWidth", clampNumber(value, 24, 180, DEFAULT_WINDOW.amountColumnWidth)) end, 24, 180, 1, valuesId, valueColumnsEnabled, valueColumnsEnabled),
		sliderSetting(L["damageMeterRateColumnWidth"] or "Rate column width", function() return cfg().rateColumnWidth end, function(value) self:SetConfigValue(index, "rateColumnWidth", clampNumber(value, 24, 180, DEFAULT_WINDOW.rateColumnWidth)) end, 24, 180, 1, valuesId, valueColumnsEnabled, valueColumnsEnabled),
		sliderSetting(L["damageMeterPercentColumnWidth"] or "Percent column width", function() return cfg().percentColumnWidth end, function(value) self:SetConfigValue(index, "percentColumnWidth", clampNumber(value, 24, 120, DEFAULT_WINDOW.percentColumnWidth)) end, 24, 120, 1, valuesId, valueColumnsEnabled, valueColumnsEnabled),
		sliderSetting(L["damageMeterColumnGap"] or "Column gap", function() return cfg().valueColumnGap end, function(value) self:SetConfigValue(index, "valueColumnGap", clampNumber(value, 0, 24, DEFAULT_WINDOW.valueColumnGap)) end, 0, 24, 1, valuesId, valueColumnsEnabled, valueColumnsEnabled),
		sliderSetting(L["damageMeterNameValueGap"] or "Name/value gap", function() return cfg().nameValueGap end, function(value) self:SetConfigValue(index, "nameValueGap", clampNumber(value, 0, 32, DEFAULT_WINDOW.nameValueGap)) end, 0, 32, 1, valuesId, valueColumnsEnabled, valueColumnsEnabled),
		dropdownSetting(L["damageMeterValueAnchorV"] or "Value vertical anchor", function() return normalizeAnchorV(cfg().valueAnchorV) end, function(value) self:SetConfigValue(index, "valueAnchorV", normalizeAnchorV(value)) end, buildVerticalAnchorOptions(), valuesId, 120),
		sliderSetting(L["damageMeterValueOffsetX"] or "Value X offset", function() return cfg().valueOffsetX end, function(value) self:SetConfigValue(index, "valueOffsetX", clampNumber(value, -200, 200, DEFAULT_WINDOW.valueOffsetX)) end, -200, 200, 1, valuesId),
		sliderSetting(L["damageMeterValueOffsetY"] or "Value Y offset", function() return cfg().valueOffsetY end, function(value) self:SetConfigValue(index, "valueOffsetY", clampNumber(value, -200, 200, DEFAULT_WINDOW.valueOffsetY)) end, -200, 200, 1, valuesId),
		dividerSetting(valuesId),
		dropdownSetting(L["damageMeterValueMode"] or "Value display", function() return normalizeValueMode(cfg().valueMode) end, function(value) self:SetConfigValue(index, "valueMode", normalizeValueMode(value)) end, buildValueModeOptions(), valuesId, 160),
		dividerSetting(valuesId),
		dropdownSetting(L["damageMeterAbbreviation"] or "Number format", function() return cfg().abbreviation end, function(value) self:SetConfigValue(index, "abbreviation", value == "none" and "none" or "short") end, {
			{ value = "short", label = L["damageMeterAbbreviationShort"] or "Abbreviated" },
			{ value = "none", label = L["damageMeterAbbreviationFull"] or "Full numbers" },
		}, valuesId, 100),
		dropdownSetting(L["damageMeterValueFormat"] or "Value format", function() return cfg().valueFormat end, function(value)
			self:SetConfigValue(index, "valueFormat", value == "parentheses" and "parentheses" or "slash")
			requestEditModeSettingsRefresh()
		end, {
			{ value = "slash", label = L["damageMeterValueFormatSlash"] or "<total> / <DPS>" },
			{ value = "parentheses", label = L["damageMeterValueFormatParentheses"] or "<total> (<DPS>)" },
		}, valuesId, 110, combinedValueLayoutEnabled, combinedValueLayoutEnabled),
		dropdownSetting(L["Delimiter"] or "Delimiter", function() return normalizeValueSeparator(cfg().valueSeparator) end, function(value) self:SetConfigValue(index, "valueSeparator", normalizeValueSeparator(value)) end, buildValueSeparatorOptions(), valuesId, 120, function() return combinedValueLayoutEnabled() and cfg().valueFormat ~= "parentheses" end, combinedValueLayoutEnabled),
		{ name = L["damageMeterTooltip"] or "Tooltip", kind = SettingType.Collapsible, id = tooltipId, defaultCollapsed = true },
		checkboxSetting(L["damageMeterTooltipEnabled"] or "Show row tooltip", function() return cfg().tooltipEnabled == true end, function(value) self:SetConfigValue(index, "tooltipEnabled", value) end, tooltipId),
		checkboxSetting(L["damageMeterTooltipClickToPin"] or "Click to pin tooltip", function() return cfg().tooltipClickToPin == true end, function(value) self:SetConfigValue(index, "tooltipClickToPin", value) end, tooltipId, tooltipEnabled),
		checkboxSetting(L["damageMeterTooltipPreview"] or "Preview tooltip", function() return cfg().tooltipPreview == true end, function(value) self:SetConfigValue(index, "tooltipPreview", value) end, tooltipId, tooltipEnabled),
		dividerSetting(tooltipId),
		dropdownSetting(L["damageMeterTooltipAnchor"] or "Tooltip anchor", function() return normalizeTooltipAnchor(cfg().tooltipAnchor) end, function(value) self:SetConfigValue(index, "tooltipAnchor", normalizeTooltipAnchor(value)) end, buildTooltipAnchorOptions(), tooltipId, 120, tooltipEnabled),
		dropdownSetting(L["damageMeterTooltipVerticalAnchor"] or "Vertical anchor", function() return normalizeAnchorV(cfg().tooltipAnchorV) end, function(value) self:SetConfigValue(index, "tooltipAnchorV", normalizeAnchorV(value)) end, buildVerticalAnchorOptions(), tooltipId, 120, tooltipEnabled),
		dropdownSetting(L["damageMeterTooltipGrow"] or "Grow", function() return normalizeTooltipGrow(cfg().tooltipGrow) end, function(value) self:SetConfigValue(index, "tooltipGrow", normalizeTooltipGrow(value)) end, buildTooltipGrowOptions(), tooltipId, 120, tooltipEnabled),
		sliderSetting(L["damageMeterTooltipOffsetX"] or "Tooltip X offset", function() return cfg().tooltipOffsetX end, function(value) self:SetConfigValue(index, "tooltipOffsetX", clampNumber(value, -300, 300, DEFAULT_WINDOW.tooltipOffsetX)) end, -300, 300, 1, tooltipId, tooltipEnabled),
		sliderSetting(L["damageMeterTooltipOffsetY"] or "Tooltip Y offset", function() return cfg().tooltipOffsetY end, function(value) self:SetConfigValue(index, "tooltipOffsetY", clampNumber(value, -300, 300, DEFAULT_WINDOW.tooltipOffsetY)) end, -300, 300, 1, tooltipId, tooltipEnabled),
		sliderSetting(L["damageMeterTooltipWidth"] or "Tooltip width", function() return cfg().tooltipWidth end, function(value) self:SetConfigValue(index, "tooltipWidth", clampNumber(value, 100, 600, DEFAULT_WINDOW.tooltipWidth)) end, 100, 600, 1, tooltipId, tooltipEnabled),
		sliderSetting(L["damageMeterTooltipMaxLines"] or "Tooltip max lines", function() return cfg().tooltipMaxLines end, function(value) self:SetConfigValue(index, "tooltipMaxLines", clampNumber(value, 4, 30, DEFAULT_WINDOW.tooltipMaxLines)) end, 4, 30, 1, tooltipId, tooltipEnabled),
		dividerSetting(tooltipId),
		dropdownSetting(L["damageMeterTooltipFont"] or "Font", function() return cfg().tooltipFontFace end, function(value) self:SetConfigValue(index, "tooltipFontFace", value) end, buildMediaOptions("font", true), tooltipId, 260, tooltipEnabled),
		dropdownSetting(L["damageMeterTooltipFontOutline"] or "Font outline", function() return cfg().tooltipFontOutline end, function(value) self:SetConfigValue(index, "tooltipFontOutline", normalizeStyle(value)) end, buildStyleOptions(), tooltipId, 180, tooltipEnabled),
		sliderSetting(L["damageMeterTooltipFontSize"] or "Tooltip font size", function() return cfg().tooltipFontSize end, function(value) self:SetConfigValue(index, "tooltipFontSize", clampNumber(value, 8, 24, DEFAULT_WINDOW.tooltipFontSize)) end, 8, 24, 1, tooltipId, tooltipEnabled),
		dividerSetting(tooltipId),
		checkboxSetting(L["damageMeterTooltipShowAmount"] or "Show amount column", function() return cfg().tooltipShowAmount ~= false end, function(value) self:SetConfigValue(index, "tooltipShowAmount", value) end, tooltipId, tooltipEnabled),
		checkboxSetting(L["damageMeterTooltipShowDPS"] or "Show DPS column", function() return cfg().tooltipShowDPS ~= false end, function(value) self:SetConfigValue(index, "tooltipShowDPS", value) end, tooltipId, tooltipEnabled),
		checkboxSetting(L["damageMeterTooltipShowPercent"] or "Show percent column", function() return cfg().tooltipShowPercent ~= false end, function(value) self:SetConfigValue(index, "tooltipShowPercent", value) end, tooltipId, tooltipEnabled),
		checkboxSetting(L["damageMeterTooltipShowTargets"] or "Show targets", function() return cfg().tooltipShowTargets ~= false end, function(value) self:SetConfigValue(index, "tooltipShowTargets", value) end, tooltipId, tooltipEnabled),
		checkboxSetting(L["damageMeterTooltipShowCreatureName"] or "Show creature name", function() return cfg().tooltipShowCreatureName ~= false end, function(value) self:SetConfigValue(index, "tooltipShowCreatureName", value) end, tooltipId, tooltipEnabled),
		colorSetting(L["damageMeterTooltipCreatureNameColor"] or "Creature name color", function() return normalizeColor(cfg().tooltipCreatureNameColor, DEFAULT_WINDOW.tooltipCreatureNameColor) end, function(value) self:SetConfigValue(index, "tooltipCreatureNameColor", normalizeColor(value, DEFAULT_WINDOW.tooltipCreatureNameColor)) end, DEFAULT_WINDOW.tooltipCreatureNameColor, tooltipId, function() return cfg().tooltipEnabled == true and cfg().tooltipShowCreatureName ~= false end),
		dividerSetting(tooltipId),
		checkboxSetting(L["damageMeterTooltipShowBars"] or "Show bars", function() return cfg().tooltipShowBars == true end, function(value) self:SetConfigValue(index, "tooltipShowBars", value) end, tooltipId, tooltipEnabled),
		dropdownSetting(L["damageMeterTooltipBarTexture"] or "Tooltip bar texture", function() return cfg().tooltipBarTexture end, function(value) self:SetConfigValue(index, "tooltipBarTexture", value) end, buildMediaOptions("statusbar", false), tooltipId, 260, tooltipEnabled),
		checkboxSetting(L["damageMeterTooltipBarUseClassColor"] or "Use class color for tooltip bars", function() return cfg().tooltipBarUseClassColor == true end, function(value)
			self:SetConfigValue(index, "tooltipBarUseClassColor", value)
			requestEditModeSettingsRefresh()
		end, tooltipId, tooltipEnabled),
		colorSetting(L["damageMeterTooltipBarColor"] or "Tooltip bar color", function() return normalizeColor(cfg().tooltipBarColor, DEFAULT_WINDOW.tooltipBarColor) end, function(value) self:SetConfigValue(index, "tooltipBarColor", normalizeColor(value, DEFAULT_WINDOW.tooltipBarColor)) end, DEFAULT_WINDOW.tooltipBarColor, tooltipId, fixedTooltipBarColorEnabled),
		sliderSetting(L["damageMeterBarSpacing"] or "Bar spacing", function() return cfg().tooltipBarSpacing end, function(value) self:SetConfigValue(index, "tooltipBarSpacing", clampNumber(value, -16, 16, DEFAULT_WINDOW.tooltipBarSpacing)) end, -16, 16, 1, tooltipId, tooltipEnabled),
		dividerSetting(tooltipId),
		checkboxSetting(L["damageMeterRowBorder"] or "Row border", function() return cfg().tooltipRowBorderEnabled == true end, function(value)
			self:SetConfigValue(index, "tooltipRowBorderEnabled", value)
			requestEditModeSettingsRefresh()
		end, tooltipId, tooltipEnabled),
		dropdownSetting(L["damageMeterRowBorderTexture"] or "Row border texture", function() return cfg().tooltipRowBorderTexture end, function(value) self:SetConfigValue(index, "tooltipRowBorderTexture", value) end, buildMediaOptions("border", false), tooltipId, 260, tooltipRowBorderEnabled),
		checkboxSetting(L["damageMeterUseClassColor"] or "Use class color", function() return cfg().tooltipRowBorderUseClassColor == true end, function(value)
			self:SetConfigValue(index, "tooltipRowBorderUseClassColor", value)
			requestEditModeSettingsRefresh()
		end, tooltipId, tooltipRowBorderEnabled),
		colorSetting(L["damageMeterRowBorderColor"] or "Row border color", function() return normalizeColor(cfg().tooltipRowBorderColor, DEFAULT_WINDOW.tooltipRowBorderColor) end, function(value) self:SetConfigValue(index, "tooltipRowBorderColor", normalizeColor(value, DEFAULT_WINDOW.tooltipRowBorderColor)) end, DEFAULT_WINDOW.tooltipRowBorderColor, tooltipId, fixedTooltipRowBorderColorEnabled),
		sliderSetting(L["damageMeterRowBorderSize"] or "Row border size", function() return cfg().tooltipRowBorderSize end, function(value) self:SetConfigValue(index, "tooltipRowBorderSize", clampNumber(value, 1, 32, DEFAULT_WINDOW.tooltipRowBorderSize)) end, 1, 32, 1, tooltipId, tooltipRowBorderEnabled),
		sliderSetting(L["damageMeterRowBorderOffset"] or "Row border offset", function() return cfg().tooltipRowBorderInset end, function(value) self:SetConfigValue(index, "tooltipRowBorderInset", clampNumber(value, 0, 24, DEFAULT_WINDOW.tooltipRowBorderInset)) end, 0, 24, 1, tooltipId, tooltipRowBorderEnabled),
		dividerSetting(tooltipId),
		checkboxSetting(L["damageMeterBarBorder"] or "Bar border", function() return cfg().tooltipBarBorderEnabled == true end, function(value)
			self:SetConfigValue(index, "tooltipBarBorderEnabled", value)
			requestEditModeSettingsRefresh()
		end, tooltipId, tooltipEnabled),
		dropdownSetting(L["damageMeterBarBorderTexture"] or "Bar border texture", function() return cfg().tooltipBarBorderTexture end, function(value) self:SetConfigValue(index, "tooltipBarBorderTexture", value) end, buildMediaOptions("border", false), tooltipId, 260, tooltipBarBorderEnabled),
		checkboxSetting(L["damageMeterUseClassColor"] or "Use class color", function() return cfg().tooltipBarBorderUseClassColor == true end, function(value)
			self:SetConfigValue(index, "tooltipBarBorderUseClassColor", value)
			requestEditModeSettingsRefresh()
		end, tooltipId, tooltipBarBorderEnabled),
		colorSetting(L["damageMeterBarBorderColor"] or "Bar border color", function() return normalizeColor(cfg().tooltipBarBorderColor, DEFAULT_WINDOW.tooltipBarBorderColor) end, function(value) self:SetConfigValue(index, "tooltipBarBorderColor", normalizeColor(value, DEFAULT_WINDOW.tooltipBarBorderColor)) end, DEFAULT_WINDOW.tooltipBarBorderColor, tooltipId, fixedTooltipBarBorderColorEnabled),
		sliderSetting(L["damageMeterBarBorderSize"] or "Bar border size", function() return cfg().tooltipBarBorderSize end, function(value) self:SetConfigValue(index, "tooltipBarBorderSize", clampNumber(value, 1, 32, DEFAULT_WINDOW.tooltipBarBorderSize)) end, 1, 32, 1, tooltipId, tooltipBarBorderEnabled),
		sliderSetting(L["damageMeterBarBorderOffset"] or "Bar border offset", function() return cfg().tooltipBarBorderInset end, function(value) self:SetConfigValue(index, "tooltipBarBorderInset", clampNumber(value, 0, 24, DEFAULT_WINDOW.tooltipBarBorderInset)) end, 0, 24, 1, tooltipId, tooltipBarBorderEnabled),
		dividerSetting(tooltipId),
		checkboxSetting(L["damageMeterIconBorder"] or "Icon border", function() return cfg().tooltipIconBorderEnabled == true end, function(value)
			self:SetConfigValue(index, "tooltipIconBorderEnabled", value)
			requestEditModeSettingsRefresh()
		end, tooltipId, tooltipEnabled),
		dropdownSetting(L["damageMeterIconBorderTexture"] or "Icon border texture", function() return cfg().tooltipIconBorderTexture end, function(value) self:SetConfigValue(index, "tooltipIconBorderTexture", value) end, buildMediaOptions("border", false), tooltipId, 260, tooltipIconBorderEnabled),
		checkboxSetting(L["damageMeterUseClassColor"] or "Use class color", function() return cfg().tooltipIconBorderUseClassColor == true end, function(value)
			self:SetConfigValue(index, "tooltipIconBorderUseClassColor", value)
			requestEditModeSettingsRefresh()
		end, tooltipId, tooltipIconBorderEnabled),
		colorSetting(L["damageMeterIconBorderColor"] or "Icon border color", function() return normalizeColor(cfg().tooltipIconBorderColor, DEFAULT_WINDOW.tooltipIconBorderColor) end, function(value) self:SetConfigValue(index, "tooltipIconBorderColor", normalizeColor(value, DEFAULT_WINDOW.tooltipIconBorderColor)) end, DEFAULT_WINDOW.tooltipIconBorderColor, tooltipId, fixedTooltipIconBorderColorEnabled),
		sliderSetting(L["damageMeterIconBorderSize"] or "Icon border size", function() return cfg().tooltipIconBorderSize end, function(value) self:SetConfigValue(index, "tooltipIconBorderSize", clampNumber(value, 1, 32, DEFAULT_WINDOW.tooltipIconBorderSize)) end, 1, 32, 1, tooltipId, tooltipIconBorderEnabled),
		sliderSetting(L["damageMeterIconBorderOffset"] or "Icon border offset", function() return cfg().tooltipIconBorderInset end, function(value) self:SetConfigValue(index, "tooltipIconBorderInset", clampNumber(value, 0, 24, DEFAULT_WINDOW.tooltipIconBorderInset)) end, 0, 24, 1, tooltipId, tooltipIconBorderEnabled),
		sliderSetting(L["damageMeterIconGap"] or "Icon gap", function() return cfg().tooltipIconGap end, function(value) self:SetConfigValue(index, "tooltipIconGap", clampNumber(value, 0, 24, DEFAULT_WINDOW.tooltipIconGap)) end, 0, 24, 1, tooltipId, tooltipEnabled),
		dividerSetting(tooltipId),
		dropdownSetting(L["damageMeterTooltipBackgroundTexture"] or "Tooltip background texture", function() return cfg().tooltipBackdropTexture end, function(value) self:SetConfigValue(index, "tooltipBackdropTexture", value) end, buildMediaOptions("statusbar", false), tooltipId, 260, tooltipEnabled),
		colorSetting(L["damageMeterTooltipBackgroundColor"] or "Tooltip background color", function() return normalizeColor(cfg().tooltipBackdropColor, DEFAULT_WINDOW.tooltipBackdropColor) end, function(value) self:SetConfigValue(index, "tooltipBackdropColor", normalizeColor(value, DEFAULT_WINDOW.tooltipBackdropColor)) end, DEFAULT_WINDOW.tooltipBackdropColor, tooltipId, tooltipEnabled),
		dropdownSetting(L["damageMeterTooltipBorderTexture"] or "Tooltip border texture", function() return cfg().tooltipBorderTexture end, function(value) self:SetConfigValue(index, "tooltipBorderTexture", value) end, buildMediaOptions("border", false), tooltipId, 260, tooltipEnabled),
		colorSetting(L["damageMeterTooltipBorderColor"] or "Tooltip border color", function() return normalizeColor(cfg().tooltipBorderColor, DEFAULT_WINDOW.tooltipBorderColor) end, function(value) self:SetConfigValue(index, "tooltipBorderColor", normalizeColor(value, DEFAULT_WINDOW.tooltipBorderColor)) end, DEFAULT_WINDOW.tooltipBorderColor, tooltipId, tooltipEnabled),
		sliderSetting(L["damageMeterTooltipBorderSize"] or "Tooltip border size", function() return cfg().tooltipBorderSize end, function(value) self:SetConfigValue(index, "tooltipBorderSize", clampNumber(value, 1, 32, DEFAULT_WINDOW.tooltipBorderSize)) end, 1, 32, 1, tooltipId, tooltipEnabled),
		sliderSetting(L["damageMeterTooltipBorderOffset"] or "Border offset", function() return cfg().tooltipBorderInset end, function(value) self:SetConfigValue(index, "tooltipBorderInset", clampNumber(value, 0, 32, DEFAULT_WINDOW.tooltipBorderInset)) end, 0, 32, 1, tooltipId, tooltipEnabled),
		{ name = L["Ranking"] or "Ranking", kind = SettingType.Collapsible, id = rankingId, defaultCollapsed = true },
		checkboxSetting(L["damageMeterShowRanks"] or "Show ranks", function() return cfg().showRanks ~= false end, function(value) self:SetConfigValue(index, "showRanks", value) end, rankingId),
		checkboxSetting(L["damageMeterPrefixRankInName"] or "Prefix rank in name", function() return cfg().prefixRankInName == true end, function(value) self:SetConfigValue(index, "prefixRankInName", value) end, rankingId, rankingEnabled),
		checkboxSetting(L["damageMeterRankUseClassColor"] or "Use class color for ranks", function() return cfg().rankUseClassColors == true end, function(value)
			self:SetConfigValue(index, "rankUseClassColors", value)
			requestEditModeSettingsRefresh()
		end, rankingId, rankingEnabled),
		colorSetting(L["damageMeterRankColor"] or "Rank color", function() return normalizeColor(cfg().rankColor, DEFAULT_WINDOW.rankColor) end, function(value) self:SetConfigValue(index, "rankColor", normalizeColor(value, DEFAULT_WINDOW.rankColor)) end, DEFAULT_WINDOW.rankColor, rankingId, fixedRankColorEnabled),
		dividerSetting(rankingId, rankColumnEnabled),
		dropdownSetting(L["damageMeterRankFont"] or "Rank font", function() return cfg().rankFontFace end, function(value) self:SetConfigValue(index, "rankFontFace", value) end, buildMediaOptions("font", true), rankingId, 260, rankColumnEnabled),
		dropdownSetting(L["damageMeterRankFontOutline"] or "Rank font outline", function() return cfg().rankFontOutline end, function(value) self:SetConfigValue(index, "rankFontOutline", normalizeStyle(value)) end, buildStyleOptions(), rankingId, 180, rankColumnEnabled),
		sliderSetting(L["damageMeterRankFontSize"] or "Rank font size", function() return cfg().rankFontSize end, function(value) self:SetConfigValue(index, "rankFontSize", clampNumber(value, 8, 24, DEFAULT_WINDOW.rankFontSize)) end, 8, 24, 1, rankingId, rankColumnEnabled),
		dropdownSetting(L["damageMeterRankAnchorH"] or "Rank horizontal anchor", function() return normalizeAnchorH(cfg().rankAnchorH) end, function(value) self:SetConfigValue(index, "rankAnchorH", normalizeAnchorH(value)) end, buildHorizontalAnchorOptions(), rankingId, 120, rankColumnEnabled),
		dropdownSetting(L["damageMeterRankAnchorV"] or "Rank vertical anchor", function() return normalizeAnchorV(cfg().rankAnchorV) end, function(value) self:SetConfigValue(index, "rankAnchorV", normalizeAnchorV(value)) end, buildVerticalAnchorOptions(), rankingId, 120, rankColumnEnabled),
		sliderSetting(L["damageMeterRankOffsetX"] or "Rank X offset", function() return cfg().rankOffsetX end, function(value) self:SetConfigValue(index, "rankOffsetX", clampNumber(value, -200, 200, DEFAULT_WINDOW.rankOffsetX)) end, -200, 200, 1, rankingId, rankColumnEnabled),
		sliderSetting(L["damageMeterRankOffsetY"] or "Rank Y offset", function() return cfg().rankOffsetY end, function(value) self:SetConfigValue(index, "rankOffsetY", clampNumber(value, -200, 200, DEFAULT_WINDOW.rankOffsetY)) end, -200, 200, 1, rankingId, rankColumnEnabled),
		sliderSetting(L["damageMeterRankGap"] or "Rank gap", function() return cfg().rankGap end, function(value) self:SetConfigValue(index, "rankGap", clampNumber(value, -50, 50, DEFAULT_WINDOW.rankGap)) end, -50, 50, 1, rankingId, rankingEnabled),
		{ name = L["Background"] or "Backdrop", kind = SettingType.Collapsible, id = mediaId, defaultCollapsed = true },
		checkboxSetting(L["damageMeterBackdropUseCustomTexture"] or "Custom texture", function() return cfg().backdropUseCustomTexture == true end, function(value)
			self:SetConfigValue(index, "backdropUseCustomTexture", value)
			requestEditModeSettingsRefresh()
		end, mediaId),
		inputSetting(L["damageMeterBackdropCustomTexture"] or "Atlas name or texture ID", function() return cfg().backdropCustomTexture or "" end, function(value) self:SetConfigValue(index, "backdropCustomTexture", trimTextureInput(value)) end, mediaId, function() return cfg().backdropUseCustomTexture == true end, L["damageMeterHeaderBackgroundCustomTextureDesc"] or "Enter an atlas name, texture file ID, or texture path.", 160),
		dropdownSetting(L["Backdrop texture"] or "Backdrop texture", function() return cfg().backdropTexture end, function(value) self:SetConfigValue(index, "backdropTexture", value) end, buildMediaOptions("statusbar", false), mediaId, 260, function() return cfg().backdropUseCustomTexture ~= true end),
		colorSetting(L["Background color"] or "Background color", function() return normalizeColor(cfg().backdropColor, DEFAULT_WINDOW.backdropColor) end, function(value) self:SetConfigValue(index, "backdropColor", normalizeColor(value, DEFAULT_WINDOW.backdropColor)) end, DEFAULT_WINDOW.backdropColor, mediaId),
		sliderSetting(L["damageMeterBackdropOffsetX"] or "X offset", function() return cfg().backdropOffsetX end, function(value) self:SetConfigValue(index, "backdropOffsetX", clampNumber(value, -200, 200, DEFAULT_WINDOW.backdropOffsetX)) end, -200, 200, 1, mediaId),
		sliderSetting(L["damageMeterBackdropOffsetY"] or "Y offset", function() return cfg().backdropOffsetY end, function(value) self:SetConfigValue(index, "backdropOffsetY", clampNumber(value, -200, 200, DEFAULT_WINDOW.backdropOffsetY)) end, -200, 200, 1, mediaId),
		sliderSetting(L["damageMeterBackdropSizeOffsetX"] or "Width offset", function() return cfg().backdropSizeOffsetX end, function(value) self:SetConfigValue(index, "backdropSizeOffsetX", clampNumber(value, -200, 200, DEFAULT_WINDOW.backdropSizeOffsetX)) end, -200, 200, 1, mediaId),
		sliderSetting(L["damageMeterBackdropSizeOffsetY"] or "Height offset", function() return cfg().backdropSizeOffsetY end, function(value) self:SetConfigValue(index, "backdropSizeOffsetY", clampNumber(value, -200, 200, DEFAULT_WINDOW.backdropSizeOffsetY)) end, -200, 200, 1, mediaId),
		{ name = L["Border"] or "Border", kind = SettingType.Collapsible, id = borderId, defaultCollapsed = true },
		checkboxSetting(L["Use border"] or "Use border", function() return cfg().borderEnabled == true end, function(value) self:SetConfigValue(index, "borderEnabled", value) end, borderId),
		dropdownSetting(L["Border texture"] or "Border texture", function() return cfg().borderTexture end, function(value) self:SetConfigValue(index, "borderTexture", value) end, buildMediaOptions("border", false), borderId, 260, windowBorderEnabled),
		colorSetting(L["Border color"] or "Border color", function() return normalizeColor(cfg().borderColor, DEFAULT_WINDOW.borderColor) end, function(value) self:SetConfigValue(index, "borderColor", normalizeColor(value, DEFAULT_WINDOW.borderColor)) end, DEFAULT_WINDOW.borderColor, borderId, windowBorderEnabled),
		sliderSetting(L["Border size"] or "Border size", function() return cfg().borderSize end, function(value) self:SetConfigValue(index, "borderSize", clampNumber(value, 1, 32, DEFAULT_WINDOW.borderSize)) end, 1, 32, 1, borderId, windowBorderEnabled),
		sliderSetting(L["Border offset"] or "Border offset", function() return cfg().borderInset end, function(value) self:SetConfigValue(index, "borderInset", clampNumber(value, 0, 24, DEFAULT_WINDOW.borderInset)) end, 0, 24, 1, borderId, function() return windowBorderEnabled() and cfg().borderUseAdvancedOffsets ~= true end),
		checkboxSetting(L["damageMeterBorderAdvancedOffsets"] or "Separate border offsets", function() return cfg().borderUseAdvancedOffsets == true end, function(value)
			self:SetConfigValue(index, "borderUseAdvancedOffsets", value)
			requestEditModeSettingsRefresh()
		end, borderId, windowBorderEnabled),
		sliderSetting(L["damageMeterBorderOffsetX"] or "Border X offset", function() return cfg().borderOffsetX end, function(value) self:SetConfigValue(index, "borderOffsetX", clampNumber(value, -200, 200, DEFAULT_WINDOW.borderOffsetX)) end, -200, 200, 1, borderId, function() return windowBorderEnabled() and cfg().borderUseAdvancedOffsets == true end),
		sliderSetting(L["damageMeterBorderOffsetY"] or "Border Y offset", function() return cfg().borderOffsetY end, function(value) self:SetConfigValue(index, "borderOffsetY", clampNumber(value, -200, 200, DEFAULT_WINDOW.borderOffsetY)) end, -200, 200, 1, borderId, function() return windowBorderEnabled() and cfg().borderUseAdvancedOffsets == true end),
		sliderSetting(L["damageMeterBorderWidthOffset"] or "Border width offset", function() return cfg().borderSizeOffsetX end, function(value) self:SetConfigValue(index, "borderSizeOffsetX", clampNumber(value, -200, 200, DEFAULT_WINDOW.borderSizeOffsetX)) end, -200, 200, 1, borderId, function() return windowBorderEnabled() and cfg().borderUseAdvancedOffsets == true end),
		sliderSetting(L["damageMeterBorderHeightOffset"] or "Border height offset", function() return cfg().borderSizeOffsetY end, function(value) self:SetConfigValue(index, "borderSizeOffsetY", clampNumber(value, -200, 200, DEFAULT_WINDOW.borderSizeOffsetY)) end, -200, 200, 1, borderId, function() return windowBorderEnabled() and cfg().borderUseAdvancedOffsets == true end),
	}
	return settings
end

function DamageMeter:BuildWindowButtons(index)
	local buttons = {
		{
			text = L["damageMeterAddWindow"] or "Add new window",
			click = function() DamageMeter:AddWindow(index) end,
		},
	}
	if index > 1 then
		buttons[#buttons + 1] = {
			text = L["damageMeterRemoveWindow"] or "Remove window",
			click = function() DamageMeter:PromptRemoveWindow(index) end,
		}
	end
	return buttons
end

function DamageMeter:RegisterEditMode()
	if self.editModeRegistered or not (EditMode and EditMode.RegisterFrame and SettingType) then return end
	for index = 1, MAX_WINDOWS do
		EditMode:RegisterFrame(host.editModePrefix .. index, {
			frame = self:EnsureWindow(index),
			title = string.format("%s %d", L["damageMeterTitle"] or "Damage Meter", index),
			layoutDefaults = { point = "CENTER", relativePoint = "CENTER", x = 300, y = -120 - ((index - 1) * 30) },
			onApply = function() DamageMeter:RefreshWindow(index) end,
			onEnter = function() DamageMeter:RefreshWindow(index) end,
			onExit = function() C_Timer.After(0, function() DamageMeter:RefreshWindow(index) end) end,
			isEnabled = function() return DamageMeter:ShouldShow(index) end,
			settings = self:BuildWindowSettings(index),
			buttons = self:BuildWindowButtons(index),
			showOutsideEditMode = true,
			showReset = false,
			showSettingsReset = false,
			enableOverlayToggle = true,
			collapseExclusive = true,
			settingsMaxHeight = 700,
		})
	end
	self.editModeRegistered = true
end

function DamageMeter:Init()
	if self.initialized then return end
	self.initialized = true
	self:GetWindowsDB()
	for index = 1, MAX_WINDOWS do
		self:EnsureWindow(index)
	end
	self:RegisterEditMode()
	self.eventFrame = CreateFrame("Frame")
	self.partyClassGeneration = 0
	self.currentPartyClassGeneration = 0
	self.eventFrame:SetScript("OnEvent", function(_, event, damageMeterType, sessionID)
		if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
			self:InvalidatePartyClassFallback()
			self:InvalidateDerivedTargetCache(true)
			if event == "PLAYER_ENTERING_WORLD" then self:CheckAutomaticClear() end
		elseif event == "PLAYER_ROLES_ASSIGNED" or event == "PLAYER_SPECIALIZATION_CHANGED" or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" then
			self:InvalidateLiveEventWatch()
		elseif event == "PLAYER_REGEN_DISABLED" then
			self:MarkPartyClassFallbackCurrent()
			self:InvalidateDerivedTargetCache(true)
		elseif event == "DAMAGE_METER_RESET" then
			self:InvalidatePartyClassFallback()
			self:MarkPartyClassFallbackCurrent()
			self:InvalidateDerivedTargetCache()
		elseif event == "ADDON_RESTRICTION_STATE_CHANGED" then
			self:RefreshReportRestrictionState(damageMeterType, sessionID)
		end
		if event == "DAMAGE_METER_COMBAT_SESSION_UPDATED" then
			self:InvalidateDerivedTargetCache(true)
			self:RefreshFromLiveEvent(damageMeterType, sessionID)
		elseif event == "DAMAGE_METER_CURRENT_SESSION_UPDATED" then
			self:InvalidateDerivedTargetCache(true)
			self:RefreshFromLiveEvent()
		elseif event == "UNIT_THREAT_LIST_UPDATE" or event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_TARGET" or event == "PLAYER_TARGET_CHANGED" then
			self:ScheduleThreatRefresh()
		elseif event == "ADDON_RESTRICTION_STATE_CHANGED" then
			self:ScheduleContextRefresh()
		elseif event == "ENCOUNTER_START" then
			self:CheckEncounterStartAutomaticClear(damageMeterType)
			self:ScheduleContextRefresh()
		elseif event == "ZONE_CHANGED_NEW_AREA" then
			self:CheckAutomaticClear()
			self:ScheduleContextRefresh()
		else
			self:ScheduleContextRefresh()
		end
	end)
	self:UpdateEventState()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
	DamageMeter:Init()
end)
