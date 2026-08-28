local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")
local LSM = LibStub("LibSharedMedia-3.0")
local EditMode = addon.EditMode
local settingType = EditMode and EditMode.lib and EditMode.lib.SettingType
local After = C_Timer and C_Timer.After
local GetVisibilityRuleMetadata = addon.functions and addon.functions.GetVisibilityRuleMetadata
local NormalizeUnitFrameVisibilityConfig = addon.functions and addon.functions.NormalizeUnitFrameVisibilityConfig

local UF = addon.Aura and addon.Aura.UF
local UFHelper = addon.Aura and addon.Aura.UFHelper
local UFProfiles = UF and UF.Profiles
local CastbarSettings = addon.Aura and addon.Aura.SettingsCastbar
local function getCastbarModule() return addon.Aura and (addon.Aura.Castbar or addon.Aura.UFStandaloneCastbar) end
if not (UF and settingType) then return end

local clampNumber = UFHelper and UFHelper.ClampNumber
	or function(value, minValue, maxValue, fallback)
		local v = tonumber(value)
		if v == nil then return fallback end
		if minValue ~= nil and v < minValue then v = minValue end
		if maxValue ~= nil and v > maxValue then v = maxValue end
		return v
	end

local MIN_WIDTH = 50
local OFFSET_RANGE = 3000
local defaultStrata = "LOW"
local defaultLevel = (_G.PlayerFrame and _G.PlayerFrame.GetFrameLevel and _G.PlayerFrame:GetFrameLevel()) or 0
local AuraResourceBars = addon.Aura and addon.Aura.ResourceBars
local STAGGER_EXTRA_THRESHOLD_HIGH = (AuraResourceBars and AuraResourceBars.STAGGER_EXTRA_THRESHOLD_HIGH) or 200
local STAGGER_EXTRA_THRESHOLD_EXTREME = (AuraResourceBars and AuraResourceBars.STAGGER_EXTRA_THRESHOLD_EXTREME) or 300
local STAGGER_EXTRA_COLORS = (AuraResourceBars and AuraResourceBars.STAGGER_EXTRA_COLORS) or {
	high = { r = 0.62, g = 0.2, b = 1.0, a = 1 },
	extreme = { r = 1.0, g = 0.2, b = 0.8, a = 1 },
}
local BORDER_LABEL = EMBLEM_BORDER
local DIRECTION_LEFT_LABEL = HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_LEFT
local DIRECTION_RIGHT_LABEL = HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_RIGHT
local DIRECTION_TOP_LABEL = HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_TOP
local DIRECTION_BOTTOM_LABEL = HUD_EDIT_MODE_SETTING_ENCOUNTER_EVENTS_ICON_DIRECTION_BOTTOM
local DIRECTION_UP_LABEL = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_UP
local DIRECTION_DOWN_LABEL = HUD_EDIT_MODE_SETTING_BAGS_DIRECTION_DOWN
local FONT_SIZE_LABEL = FONT_SIZE
local fontOptions

local strataOptions = {
	{ value = "BACKGROUND", label = "BACKGROUND" },
	{ value = "LOW", label = "LOW" },
	{ value = "MEDIUM", label = "MEDIUM" },
	{ value = "HIGH", label = "HIGH" },
	{ value = "DIALOG", label = "DIALOG" },
	{ value = "FULLSCREEN", label = "FULLSCREEN" },
	{ value = "FULLSCREEN_DIALOG", label = "FULLSCREEN_DIALOG" },
	{ value = "TOOLTIP", label = "TOOLTIP" },
}

local strataOptionsWithDefault = { { value = "", label = DEFAULT or "Default" } }
for _, option in ipairs(strataOptions) do
	strataOptionsWithDefault[#strataOptionsWithDefault + 1] = option
end
UF.ui.settingType = settingType
UF.ui.minWidth = MIN_WIDTH
UF.ui.offsetRange = OFFSET_RANGE
UF.ui.defaultStrata = defaultStrata
UF.ui.strataOptions = strataOptions
UF.ui.strataOptionsWithDefault = strataOptionsWithDefault

local STRATA_INDEX = {}
for index, option in ipairs(strataOptions) do
	local value = type(option) == "table" and option.value
	if type(value) == "string" and value ~= "" then STRATA_INDEX[string.upper(value)] = index end
end

local function syncEditModeSelectionStrata(frame)
	if not (frame and frame.GetFrameStrata) then return end
	local selection = frame.Selection
	if not (selection and selection.SetFrameStrata) then return end
	if not frame._eqolSelectionBaseStrata then
		local baseStrata = (selection.GetFrameStrata and selection:GetFrameStrata()) or "MEDIUM"
		local baseKey = type(baseStrata) == "string" and string.upper(baseStrata) or "MEDIUM"
		frame._eqolSelectionBaseStrata = baseKey
		frame._eqolSelectionBaseStrataIndex = STRATA_INDEX[baseKey] or STRATA_INDEX.MEDIUM or 3
	end
	local baseStrata = frame._eqolSelectionBaseStrata or "MEDIUM"
	local baseIndex = frame._eqolSelectionBaseStrataIndex or STRATA_INDEX[baseStrata] or STRATA_INDEX.MEDIUM or 3
	local currentStrata = frame:GetFrameStrata()
	local currentKey = type(currentStrata) == "string" and string.upper(currentStrata) or nil
	local currentIndex = currentKey and STRATA_INDEX[currentKey]
	local targetStrata = (currentIndex and currentIndex > baseIndex) and currentKey or baseStrata
	if selection.GetFrameStrata and selection:GetFrameStrata() ~= targetStrata then selection:SetFrameStrata(targetStrata) end
end

local function normalizeDurationTextProfile(value)
	if addon.DurationText and addon.DurationText.GetProfileKey then return addon.DurationText:GetProfileKey(value or "MINIMAL") end
	return type(value) == "string" and value ~= "" and value or "MINIMAL"
end

local function durationTextProfileOptions()
	return addon.DurationText and addon.DurationText.GetProfileOptions and addon.DurationText:GetProfileOptions() or {}
end

local textOptions = {
	{ value = "PERCENT", label = L["Percent"] or "Percent" },
	{ value = "CURMAX", label = L["Current/Max"] or "Current/Max" },
	{ value = "CURRENT", label = L["Current"] or "Current" },
	{ value = "MAX", label = L["Max"] or "Max" },
	{ value = "CURPERCENT", label = L["Current / Percent"] or "Current / Percent" },
	{ value = "CURMAXPERCENT", label = L["Current/Max Percent"] or "Current/Max Percent" },
	{ value = "MAXPERCENT", label = L["Max / Percent"] or "Max / Percent" },
	{ value = "PERCENTMAX", label = L["Percent / Max"] or "Percent / Max" },
	{ value = "PERCENTCUR", label = L["Percent / Current"] or "Percent / Current" },
	{ value = "PERCENTCURMAX", label = L["Percent / Current / Max"] or "Percent / Current / Max" },
	{ value = "LEVELPERCENT", label = L["Level / Percent"] or "Level / Percent" },
	{ value = "LEVELPERCENTMAX", label = L["Level / Percent / Max"] or "Level / Percent / Max" },
	{ value = "LEVELPERCENTCUR", label = L["Level / Percent / Current"] or "Level / Percent / Current" },
	{ value = "LEVELPERCENTCURMAX", label = L["Level / Percent / Current / Max"] or "Level / Percent / Current / Max" },
	{ value = "NONE", label = NONE },
}

function UF.ui.formatHealthAbsorbTextLabel(style)
	local currentLabel = L["Current"] or "Current"
	local absorbLabel = L["Absorb"] or "Absorb"
	if style == "PAREN" then return string.format("%s (%s)", currentLabel, absorbLabel) end
	if style == "PIPE" then return string.format("%s | %s", currentLabel, absorbLabel) end
	if style == "PLUS" then return string.format("%s + %s", currentLabel, absorbLabel) end
	return absorbLabel
end

UF.ui.healthTextOptions = {
	{ value = "PERCENT", label = L["Percent"] or "Percent" },
	{ value = "CURMAX", label = L["Current/Max"] or "Current/Max" },
	{ value = "CURRENT", label = L["Current"] or "Current" },
	{ value = "CURABSORB", label = UF.ui.formatHealthAbsorbTextLabel("PAREN") },
	{ value = "CURABSORBPIPE", label = UF.ui.formatHealthAbsorbTextLabel("PIPE") },
	{ value = "CURABSORBPLUS", label = UF.ui.formatHealthAbsorbTextLabel("PLUS") },
	{ value = "ABSORB", label = UF.ui.formatHealthAbsorbTextLabel("ABSORB") },
	{ value = "MAX", label = L["Max"] or "Max" },
	{ value = "CURPERCENT", label = L["Current / Percent"] or "Current / Percent" },
	{ value = "CURMAXPERCENT", label = L["Current/Max Percent"] or "Current/Max Percent" },
	{ value = "MAXPERCENT", label = L["Max / Percent"] or "Max / Percent" },
	{ value = "PERCENTMAX", label = L["Percent / Max"] or "Percent / Max" },
	{ value = "PERCENTCUR", label = L["Percent / Current"] or "Percent / Current" },
	{ value = "PERCENTCURMAX", label = L["Percent / Current / Max"] or "Percent / Current / Max" },
	{ value = "LEVELPERCENT", label = L["Level / Percent"] or "Level / Percent" },
	{ value = "LEVELPERCENTMAX", label = L["Level / Percent / Max"] or "Level / Percent / Max" },
	{ value = "LEVELPERCENTCUR", label = L["Level / Percent / Current"] or "Level / Percent / Current" },
	{ value = "LEVELPERCENTCURMAX", label = L["Level / Percent / Current / Max"] or "Level / Percent / Current / Max" },
	{ value = "NONE", label = NONE },
}

UF.ui.dataBarTextOptions = {
	{ value = "NAME", label = NAME or L["Name"] or "Name" },
	{ value = "LEVEL", label = LEVEL or L["Level"] or "Level" },
}
for _, option in ipairs(UF.ui.healthTextOptions) do
	UF.ui.dataBarTextOptions[#UF.ui.dataBarTextOptions + 1] = option
end

local delimiterOptions = {
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

local function normalizeTextMode(value)
	if value == "CURPERCENTDASH" then return "CURPERCENT" end
	return value
end

local delimiterModeCounts = {
	CURMAX = 1,
	CURPERCENT = 1,
	MAXPERCENT = 1,
	PERCENTMAX = 1,
	PERCENTCUR = 1,
	LEVELPERCENT = 1,
	CURMAXPERCENT = 2,
	PERCENTCURMAX = 2,
	LEVELPERCENTMAX = 2,
	LEVELPERCENTCUR = 2,
	LEVELPERCENTCURMAX = 3,
}

local function textModeDelimiterCount(value)
	local mode = normalizeTextMode(value)
	if type(mode) ~= "string" then return 0 end
	if mode == "PERCENT" or mode == "CURRENT" or mode == "MAX" or mode == "NONE" then return 0 end
	return delimiterModeCounts[mode] or 0
end

local function maxDelimiterCount(leftMode, centerMode, rightMode)
	local count = textModeDelimiterCount(leftMode)
	local centerCount = textModeDelimiterCount(centerMode)
	if centerCount > count then count = centerCount end
	local rightCount = textModeDelimiterCount(rightMode)
	if rightCount > count then count = rightCount end
	return count
end

local outlineOptions = addon.functions and addon.functions.GetFontStyleOptionList and addon.functions.GetFontStyleOptionList(true)
	or {
		{ value = "NONE", label = _G.NONE },
		{ value = "OUTLINE", label = L["Outline"] or "Outline" },
	}

local anchorOptions = {
	{ value = "LEFT", label = "LEFT" },
	{ value = "CENTER", label = "CENTER" },
	{ value = "RIGHT", label = "RIGHT" },
}
local anchorOptions9 = {
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
UF.ui.outlineOptions = outlineOptions
UF.ui.anchorOptions = anchorOptions
UF.ui.anchorOptions9 = anchorOptions9
local classResourceClasses = {
	DEATHKNIGHT = true,
	DRUID = true,
	EVOKER = true,
	MAGE = true,
	MONK = true,
	PALADIN = true,
	ROGUE = true,
	SHAMAN = true,
	WARLOCK = true,
}
local totemFrameClasses = {
	DEATHKNIGHT = true,
	DRUID = true,
	EVOKER = true,
	MAGE = true,
	MONK = true,
	PALADIN = true,
	PRIEST = true,
	SHAMAN = true,
	WARLOCK = true,
}

local function getPlayerClassFrameSupportFlags()
	local classToken = addon.variables and addon.variables.unitClass
	if not classToken then return false, false end
	local hasClassResource = classResourceClasses[classToken] == true
	if UF and UF.ClassResourceUtil and UF.ClassResourceUtil.getClassResourceOptions then
		local options = UF.ClassResourceUtil.getClassResourceOptions(classToken)
		if type(options) == "table" then hasClassResource = #options > 0 end
	end
	return hasClassResource, totemFrameClasses[classToken] == true
end
UF.ui.getPlayerClassFrameSupportFlags = getPlayerClassFrameSupportFlags

local maxBossFrames = (UF and UF.GetSupportedBossFrameCount and UF.GetSupportedBossFrameCount()) or 8
local defaultBossFrames = (UF and UF.GetDefaultBossFrameCount and UF.GetDefaultBossFrameCount()) or (MAX_BOSS_FRAMES or 5)
local bossSpacingMin = (UF and UF.BOSS_SPACING_MIN) or -50
local bossUnitLookup = { boss = true }
for i = 1, maxBossFrames do
	bossUnitLookup["boss" .. i] = true
end
local function isBossUnit(unit) return type(unit) == "string" and bossUnitLookup[unit] == true end

local function defaultsFor(unit)
	if UF.GetDefaults then
		local d = UF.GetDefaults(unit)
		if d then return d end
	end
	if UF.defaults then return UF.defaults[unit] or UF.defaults.player end
	return {}
end
local function defaultFontPath()
	if addon.functions and addon.functions.GetGlobalDefaultFontFace then return addon.functions.GetGlobalDefaultFontFace() end
	return (addon.variables and addon.variables.defaultFont) or (LSM and LSM:Fetch("font", LSM.DefaultMedia.font)) or STANDARD_TEXT_FONT
end

local function globalFontConfigKey()
	if addon.functions and addon.functions.GetGlobalFontConfigKey then return addon.functions.GetGlobalFontConfigKey() end
	return "__EQOL_GLOBAL_FONT__"
end

local function globalFontConfigLabel()
	if addon.functions and addon.functions.GetGlobalFontConfigLabel then return addon.functions.GetGlobalFontConfigLabel() end
	return "Use global font config"
end

local function normalizeFontStyleChoice(value, fallback)
	if addon.functions and addon.functions.NormalizeFontStyleChoice then
		return addon.functions.NormalizeFontStyleChoice(value, fallback, true)
	end
	if value ~= nil then return value end
	return fallback or "OUTLINE"
end
UF.ui.defaultFontPath = defaultFontPath
UF.ui.globalFontConfigKey = globalFontConfigKey
UF.ui.globalFontConfigLabel = globalFontConfigLabel
UF.ui.normalizeFontStyleChoice = normalizeFontStyleChoice
UF.ui.defaultLevel = defaultLevel

local pendingDebounce = {}
local pendingTimers = {}
local function debounced(key, fn)
	if not After then return fn and fn() end
	pendingDebounce[key] = fn
	if pendingTimers[key] then return end
	pendingTimers[key] = true
	After(0.05, function()
		pendingTimers[key] = nil
		local cb = pendingDebounce[key]
		pendingDebounce[key] = nil
		if cb then cb() end
	end)
end

local function getDefaultPowerColor(token)
	if PowerBarColor and token then
		local c = PowerBarColor[token]
		if c then
			if c.r then return c.r, c.g, c.b, c.a or 1 end
			if c[1] then return c[1], c[2], c[3], c[4] or 1 end
		end
	end
	return 0.1, 0.45, 1, 1
end

local function getPowerLabel(token)
	if not token then return "" end
	if UFHelper and UFHelper.getPowerLabel then
		local helperLabel = UFHelper.getPowerLabel(token)
		if helperLabel and helperLabel ~= "" then return helperLabel end
	end
	local label = _G[token]
	if not label or label == "" then label = token:gsub("_", " ") end
	return label
end

local mainPowerTokenCache
local function getMainPowerTokens()
	if mainPowerTokenCache then return mainPowerTokenCache end
	local list = {}
	local seen = {}
	local excluded = {
		HOLY_POWER = true,
		MAELSTROM_WEAPON = true,
		MAELSTROM = true,
		SOUL_SHARDS = true,
		CHI = true,
		ESSENCE = true,
		ARCANE_CHARGES = true,
	}
	local powertypeClasses = addon.Aura and addon.Aura.ResourceBars and addon.Aura.ResourceBars.powertypeClasses
	if type(powertypeClasses) == "table" then
		for _, specs in pairs(powertypeClasses) do
			if type(specs) == "table" then
				for _, info in pairs(specs) do
					local main = info and info.MAIN
					if type(main) == "string" and not seen[main] and not excluded[main] then
						seen[main] = true
						list[#list + 1] = main
					end
				end
			end
		end
	end
	if #list == 0 then
		for _, token in ipairs({ "MANA", "RAGE", "FOCUS", "ENERGY", "RUNIC_POWER", "LUNAR_POWER", "INSANITY", "FURY", "PAIN", "VOID_METAMORPHOSIS" }) do
			seen[token] = true
			list[#list + 1] = token
		end
	end
	table.sort(list, function(a, b) return tostring(getPowerLabel(a)) < tostring(getPowerLabel(b)) end)
	mainPowerTokenCache = list
	return list
end

local primaryPowerTokenOptionsCache
local function getPrimaryPowerTokenOptions()
	if primaryPowerTokenOptionsCache then return primaryPowerTokenOptionsCache end
	if UFHelper and UFHelper.GetPrimaryPowerTokenOptions then
		primaryPowerTokenOptionsCache = UFHelper.GetPrimaryPowerTokenOptions()
		return primaryPowerTokenOptionsCache
	end
	local excluded = {
		ARCANE_CHARGES = true,
		CHI = true,
		ESSENCE = true,
		HOLY_POWER = true,
		MAELSTROM_WEAPON = true,
		RUNIC_POWER = true,
		SOUL_SHARDS = true,
		VOID_METAMORPHOSIS = true,
	}
	local options = {}
	local seen = {}
	local powertypeClasses = addon.Aura and addon.Aura.ResourceBars and addon.Aura.ResourceBars.powertypeClasses
	if type(powertypeClasses) == "table" then
		for _, specs in pairs(powertypeClasses) do
			if type(specs) == "table" then
				for _, info in pairs(specs) do
					local token = info and info.MAIN
					if type(token) == "string" and token ~= "" and not excluded[token] and not seen[token] then
						seen[token] = true
						options[#options + 1] = { value = token, label = getPowerLabel(token) }
					end
				end
			end
		end
	end
	table.sort(options, function(a, b) return tostring(a.label) < tostring(b.label) end)
	primaryPowerTokenOptionsCache = options
	return primaryPowerTokenOptionsCache
end

local secondaryPowerTokenOptionsCache
local function getSecondaryPowerTokenOptions()
	if secondaryPowerTokenOptionsCache then return secondaryPowerTokenOptionsCache end
	if UFHelper and UFHelper.GetSecondaryPowerTokenOptions then
		secondaryPowerTokenOptionsCache = UFHelper.GetSecondaryPowerTokenOptions(false)
		return secondaryPowerTokenOptionsCache
	end
	local options = {}
	local fallbackTokens = { "MANA", "STAGGER", "VOID_METAMORPHOSIS" }
	for i = 1, #fallbackTokens do
		local token = fallbackTokens[i]
		options[#options + 1] = { value = token, label = getPowerLabel(token) }
	end
	table.sort(options, function(a, b) return tostring(a.label) < tostring(b.label) end)
	secondaryPowerTokenOptionsCache = options
	return secondaryPowerTokenOptionsCache
end

local function getPowerOverride(token)
	local overrides = addon.db and addon.db.ufPowerColorOverrides
	return overrides and overrides[token]
end

local function setPowerOverride(token, r, g, b, a)
	addon.db = addon.db or {}
	local overrides = (UFProfiles and UFProfiles.EnsureTableKey and UFProfiles.EnsureTableKey("ufPowerColorOverrides")) or addon.db.ufPowerColorOverrides or {}
	addon.db.ufPowerColorOverrides = overrides
	overrides[token] = { r or 1, g or 1, b or 1, a or 1 }
end

local function getDefaultNPCColor(key)
	if UFHelper and UFHelper.getNPCColorDefault then
		local r, g, b, a = UFHelper.getNPCColorDefault(key)
		if r then return r, g, b, a end
	end
	return 0, 0.8, 0, 1
end

local function getNPCOverride(key)
	local overrides = addon.db and addon.db.ufNPCColorOverrides
	return overrides and overrides[key]
end

local function setNPCOverride(key, r, g, b, a)
	addon.db = addon.db or {}
	local overrides = (UFProfiles and UFProfiles.EnsureTableKey and UFProfiles.EnsureTableKey("ufNPCColorOverrides")) or addon.db.ufNPCColorOverrides or {}
	addon.db.ufNPCColorOverrides = overrides
	overrides[key] = { r or 1, g or 1, b or 1, a or 1 }
end

local function clearNPCOverride(key)
	local overrides = addon.db and addon.db.ufNPCColorOverrides
	if not overrides then return end
	overrides[key] = nil
	if not next(overrides) then
		if UFProfiles and UFProfiles.SetRuntimeKey then
			UFProfiles.SetRuntimeKey("ufNPCColorOverrides", {})
		else
			addon.db.ufNPCColorOverrides = {}
		end
	end
end

local npcColorEntries = {
	{ key = "enemy", label = L["UFNPCEnemy"] or "Enemy NPC" },
	{ key = "neutral", label = L["UFNPCNeutral"] or "Neutral" },
	{ key = "friendly", label = L["UFNPCFriendly"] or "Friendly NPC" },
}

local function ensureConfig(unit)
	if UF.GetConfig then return UF.GetConfig(unit) end
	addon.db = addon.db or {}
	addon.db.ufFrames = addon.db.ufFrames or {}
	local key = unit
	if isBossUnit(unit) then key = "boss" end
	if key == "boss" and not addon.db.ufFrames[key] then
		for i = 1, maxBossFrames do
			if addon.db.ufFrames["boss" .. i] then
				addon.db.ufFrames[key] = addon.db.ufFrames["boss" .. i]
				break
			end
		end
	end
	addon.db.ufFrames[key] = addon.db.ufFrames[key] or {}
	return addon.db.ufFrames[key]
end

local function clampBossFrameCount(value)
	value = tonumber(value)
	if value then value = math.floor(value + 0.5) end
	if not value or value < 1 then value = defaultBossFrames end
	if value > maxBossFrames then value = maxBossFrames end
	return value
end

local function getBossFrameCount()
	if UF and UF.GetBossFrameCount then return UF.GetBossFrameCount() end
	local cfg = ensureConfig("boss")
	return clampBossFrameCount(cfg and cfg.bossCount)
end

addon.variables = addon.variables or {}
addon.variables.ufSampleAbsorb = addon.variables.ufSampleAbsorb or {}
addon.variables.ufSampleHealAbsorb = addon.variables.ufSampleHealAbsorb or {}
local sampleAbsorb = addon.variables.ufSampleAbsorb
local sampleHealAbsorb = addon.variables.ufSampleHealAbsorb

local function getValue(unit, path, fallback)
	local cfg = ensureConfig(unit)
	local cur = cfg
	for i = 1, #path do
		if not cur then return fallback end
		cur = cur[path[i]]
		if cur == nil then return fallback end
	end
	return cur
end

local function setValue(unit, path, value)
	local cfg = ensureConfig(unit)
	local cur = cfg
	for i = 1, #path - 1 do
		cur[path[i]] = cur[path[i]] or {}
		cur = cur[path[i]]
	end
	cur[path[#path]] = value
end

local function cloneSettingValue(value)
	if type(value) ~= "table" then return value end
	return CopyTable(value)
end

local function setTablePathValue(root, path, value)
	if type(root) ~= "table" or type(path) ~= "table" or #path == 0 then return end
	local cur = root
	for i = 1, #path - 1 do
		local key = path[i]
		if type(cur[key]) ~= "table" then cur[key] = {} end
		cur = cur[key]
	end
	cur[path[#path]] = value
end

local function ensureAuraSettingsConfig(unit, auraDef)
	local cfg = ensureConfig(unit)
	cfg.auraIcons = cfg.auraIcons or {}
	local ac = cfg.auraIcons
	if UF and UF.EnsureSingleAuraConfig then
		ac = UF.EnsureSingleAuraConfig(ac, auraDef) or ac
	else
		ac.buff = ac.buff or {}
		ac.debuff = ac.debuff or {}
		if ac.combineLayout == nil then ac.combineLayout = ac.separateDebuffAnchor ~= true end
	end
	ac.buff = ac.buff or {}
	ac.debuff = ac.debuff or {}
	ac.enabled = (ac.buff.enabled ~= false) or (ac.debuff.enabled ~= false)
	ac.showBuffs = ac.buff.enabled ~= false
	ac.showDebuffs = ac.debuff.enabled ~= false
	ac.separateDebuffAnchor = ac.combineLayout ~= true
	return ac
end

local refreshSettingsUI
local radioDropdown
local checkboxDropdown
local slider
local checkbox
local borderOptions
local iconShapeOptions

local function appendUnitAuraSettings(list, unit, def, refreshSelf)
	if not (unit == "player" or unit == "target" or unit == "focus" or isBossUnit(unit)) then return end

	local auraDef = def.auraIcons or { enabled = true, size = 24, padding = 2, max = 16, showCooldown = true }

	local function defaultAuraOffset(anchor)
		if anchor == "TOP" then return 0, 5 end
		if anchor == "LEFT" then return -5, 0 end
		if anchor == "RIGHT" then return 5, 0 end
		return 0, -5
	end

	local function defaultAuraOffsetX(anchor)
		local x = defaultAuraOffset(anchor)
		return x
	end

	local function defaultAuraOffsetY(anchor)
		local _, y = defaultAuraOffset(anchor)
		return y
	end

	local function refreshAuras()
		if not (UF and UF.FullScanTargetAuras) then return end
		if unit == "boss" then
			for i = 1, getBossFrameCount() do
				UF.FullScanTargetAuras("boss" .. i)
			end
		else
			UF.FullScanTargetAuras(unit)
		end
	end

	local borderRenderModeOptions = {
		{ value = "EDGE", label = L["Edge"] or "Edge" },
		{ value = "OVERLAY", label = L["Overlay"] or "Overlay" },
	}
	local stackOutlineOptions = addon.functions and addon.functions.GetFontStyleOptionList and addon.functions.GetFontStyleOptionList(true)
		or {
			{ value = "NONE", label = _G.NONE },
			{ value = "OUTLINE", label = L["Outline"] or "Outline" },
		}
	local stackAnchorOptions = {
		{ value = "TOPLEFT", label = L["Top left"] or "Top left" },
		{ value = "TOPRIGHT", label = L["Top right"] or "Top right" },
		{ value = "BOTTOMLEFT", label = L["Bottom left"] or "Bottom left" },
		{ value = "BOTTOMRIGHT", label = L["Bottom right"] or "Bottom right" },
		{ value = "CENTER", label = L["Center"] or "Center" },
	}
	local cooldownAnchorOptions = {
		{ value = "TOPLEFT", label = L["Top left"] or "Top left" },
		{ value = "TOP", label = DIRECTION_TOP_LABEL },
		{ value = "TOPRIGHT", label = L["Top right"] or "Top right" },
		{ value = "LEFT", label = DIRECTION_LEFT_LABEL },
		{ value = "CENTER", label = L["Center"] or "Center" },
		{ value = "RIGHT", label = DIRECTION_RIGHT_LABEL },
		{ value = "BOTTOMLEFT", label = L["Bottom left"] or "Bottom left" },
		{ value = "BOTTOM", label = DIRECTION_BOTTOM_LABEL },
		{ value = "BOTTOMRIGHT", label = L["Bottom right"] or "Bottom right" },
	}

	local leftLabel = DIRECTION_LEFT_LABEL
	local rightLabel = DIRECTION_RIGHT_LABEL
	local anchorOpts = {
		{ value = "TOP", label = DIRECTION_TOP_LABEL },
		{ value = "BOTTOM", label = DIRECTION_BOTTOM_LABEL },
		{ value = "LEFT", label = leftLabel },
		{ value = "RIGHT", label = rightLabel },
	}

	local upLabel = DIRECTION_UP_LABEL
	local downLabel = DIRECTION_DOWN_LABEL
	local function growthLabel(first, second) return ("%s %s"):format(first, second) end
	local growthOptions = {
		{ value = "UPRIGHT", label = growthLabel(upLabel, rightLabel) },
		{ value = "UPLEFT", label = growthLabel(upLabel, leftLabel) },
		{ value = "RIGHTUP", label = growthLabel(rightLabel, upLabel) },
		{ value = "RIGHTDOWN", label = growthLabel(rightLabel, downLabel) },
		{ value = "LEFTUP", label = growthLabel(leftLabel, upLabel) },
		{ value = "LEFTDOWN", label = growthLabel(leftLabel, downLabel) },
		{ value = "DOWNLEFT", label = growthLabel(downLabel, leftLabel) },
		{ value = "DOWNRIGHT", label = growthLabel(downLabel, rightLabel) },
	}
	local enemyDebuffFilterOptions = {
		{ value = "PLAYER", label = L["UFAuraEnemyDebuffFilterPlayer"] or "Only my debuffs" },
		{ value = "ALL", label = L["UFAuraEnemyDebuffFilterAll"] or "All debuffs" },
	}
	local function syncAuraState(ac)
		if type(ac) ~= "table" then return end
		ac.buff = ac.buff or {}
		ac.debuff = ac.debuff or {}
		ac.enabled = (ac.buff.enabled ~= false) or (ac.debuff.enabled ~= false)
		ac.showBuffs = ac.buff.enabled ~= false
		ac.showDebuffs = ac.debuff.enabled ~= false
		ac.separateDebuffAnchor = ac.combineLayout ~= true
	end
	local function isCombinedLayout()
		local ac = ensureAuraSettingsConfig(unit, auraDef)
		return ac.combineLayout ~= false
	end

	local function getAuraSection(sectionKey)
		local ac = ensureAuraSettingsConfig(unit, auraDef)
		return ac, ac[sectionKey] or {}
	end

	local function getAuraSectionValue(sectionKey, path, fallback)
		local _, section = getAuraSection(sectionKey)
		local cur = section
		for i = 1, #path do
			if type(cur) ~= "table" then return fallback end
			cur = cur[path[i]]
			if cur == nil then return fallback end
		end
		return cur
	end

	local function setAuraSectionValue(sectionKey, path, value)
		local ac, section = getAuraSection(sectionKey)
		setTablePathValue(section, path, cloneSettingValue(value))
		syncAuraState(ac)
	end

	local function getAuraAnchorValue(sectionKey) return getAuraSectionValue(sectionKey, { "anchor" }, auraDef.anchor or "BOTTOM") end
	local function getAuraSectionShape(sectionKey)
		if UF and UF.AuraUtil and UF.AuraUtil.NormalizeIconShape then
			return UF.AuraUtil.NormalizeIconShape(getAuraSectionValue(sectionKey, { "iconShape" }, auraDef.iconShape or "DEFAULT"), auraDef.iconShape or "DEFAULT")
		end
		return getAuraSectionValue(sectionKey, { "iconShape" }, auraDef.iconShape or "DEFAULT")
	end
	local function getAuraSectionIconZoom(sectionKey)
		if addon.IconShape and addon.IconShape.NormalizeIconZoom then return addon.IconShape.NormalizeIconZoom(getAuraSectionValue(sectionKey, { "iconZoom" }, auraDef.iconZoom or 0)) end
		return clampNumber(getAuraSectionValue(sectionKey, { "iconZoom" }, auraDef.iconZoom or 0), 0, 35, auraDef.iconZoom or 0)
	end
	local function getAuraBorderValue(sectionKey)
		local shape = getAuraSectionShape(sectionKey)
		local value = getAuraSectionValue(sectionKey, { "borderTexture" }, auraDef.borderTexture or "DEFAULT")
		if addon.IconShape and addon.IconShape.NormalizeBorder then return addon.IconShape.NormalizeBorder(value, auraDef.borderTexture or "DEFAULT", shape, { allowNone = true }) end
		return value
	end
	local function getAuraBorderOptions(sectionKey)
		return borderOptions(getAuraSectionShape(sectionKey))
	end

	local function defaultAuraGrowth(sectionKey)
		local anchor = getAuraAnchorValue(sectionKey)
		if anchor == "TOP" then return "RIGHTUP" end
		if anchor == "LEFT" then return "LEFTDOWN" end
		return "RIGHTDOWN"
	end

	local function appendAuraSection(sectionKey, parentId, isDebuff)
		local labelPrefix = isDebuff and (L["Debuff"] or "Debuff") or (L["Buff"] or "Buff")

		local function isSectionEnabled() return getAuraSectionValue(sectionKey, { "enabled" }, auraDef.enabled ~= false) == true end
		local function isLayoutEnabled()
			local buffEnabled = getAuraSectionValue("buff", { "enabled" }, auraDef.enabled ~= false) == true
			return isSectionEnabled() and (not isDebuff or not isCombinedLayout() or not buffEnabled)
		end
		local function isEdgeBorderMode()
			local shape = getAuraSectionShape(sectionKey)
			local texture = tostring(getAuraBorderValue(sectionKey) or "DEFAULT"):upper()
			if addon.IconShape and addon.IconShape.IsBackdropBorderCompatible and not addon.IconShape.IsBackdropBorderCompatible(shape) then
				return isSectionEnabled() and addon.IconShape.SupportsBorderSize and addon.IconShape.SupportsBorderSize(texture, shape) == true
			end
			local mode = tostring(getAuraSectionValue(sectionKey, { "borderRenderMode" }, auraDef.borderRenderMode or "EDGE") or "EDGE"):upper()
			return isSectionEnabled() and mode ~= "OVERLAY" and texture ~= "DEFAULT"
		end
		local function supportsBorderOffset()
			local shape = getAuraSectionShape(sectionKey)
			local texture = getAuraBorderValue(sectionKey)
			if addon.IconShape and addon.IconShape.IsBackdropBorderCompatible and not addon.IconShape.IsBackdropBorderCompatible(shape) then
				return isSectionEnabled() and addon.IconShape.SupportsBorderOffset and addon.IconShape.SupportsBorderOffset(texture, shape) == true
			end
			return isEdgeBorderMode()
		end
		local function isShowCooldown() return getAuraSectionValue(sectionKey, { "showCooldown" }, auraDef.showCooldown ~= false) ~= false end
		local function isShowCooldownText()
			local value = getAuraSectionValue(sectionKey, { "showCooldownText" }, nil)
			if value == nil then value = auraDef.showCooldownText end
			if value == nil then value = isShowCooldown() end
			return value ~= false
		end

		list[#list + 1] = checkbox((isDebuff and (L["Show debuffs"] or "Enable debuffs")) or (L["Show buffs"] or "Enable buffs"), isSectionEnabled, function(val)
			setAuraSectionValue(sectionKey, { "enabled" }, val and true or false)
			refreshSelf()
			refreshSettingsUI()
			refreshAuras()
		end, auraDef.enabled ~= false, parentId)

		if isDebuff then
			list[#list + 1] = checkbox(L["UFAuraCombineBuffDebuffLayout"] or "Combine buff and debuff layout", isCombinedLayout, function(val)
				local ac = ensureAuraSettingsConfig(unit, auraDef)
				ac.combineLayout = val and true or false
				ac.combineLayoutModel = 2
				ac.separateDebuffAnchor = ac.combineLayout ~= true
				refreshSelf()
				refreshSettingsUI()
				refreshAuras()
			end, true, parentId)
			list[#list].isEnabled = function()
				return isSectionEnabled() and getAuraSectionValue("buff", { "enabled" }, auraDef.enabled ~= false) == true
			end
		end

		if isDebuff and unit ~= "player" then
			list[#list + 1] = radioDropdown(
				L["UFAuraEnemyDebuffFilter"] or "Enemy debuff filter",
				enemyDebuffFilterOptions,
				function() return getAuraSectionValue(sectionKey, { "enemyDebuffFilterMode" }, auraDef.enemyDebuffFilterMode or "PLAYER") end,
				function(val)
					setAuraSectionValue(sectionKey, { "enemyDebuffFilterMode" }, val or "PLAYER")
					refreshSelf()
					refreshAuras()
				end,
				auraDef.enemyDebuffFilterMode or "PLAYER",
				parentId
			)
			list[#list].isEnabled = isSectionEnabled
		end

		list[#list + 1] = checkbox(L["Show tooltip"] or "Show tooltip", function() return getAuraSectionValue(sectionKey, { "showTooltip" }, true) ~= false end, function(val)
			setAuraSectionValue(sectionKey, { "showTooltip" }, val and true or false)
			refreshSelf()
		end, true, parentId)
		list[#list].isEnabled = isSectionEnabled

		list[#list + 1] = radioDropdown((labelPrefix .. " " .. (L["Anchor"] or "anchor")), anchorOpts, function() return getAuraAnchorValue(sectionKey) end, function(val)
			setAuraSectionValue(sectionKey, { "anchor" }, val or "BOTTOM")
			refreshSelf()
		end, auraDef.anchor or "BOTTOM", parentId)
		list[#list].isEnabled = isLayoutEnabled

		list[#list + 1] = radioDropdown(
			L["GrowthDirection"] or "Growth direction",
			growthOptions,
			function() return (getAuraSectionValue(sectionKey, { "growth" }, defaultAuraGrowth(sectionKey)) or defaultAuraGrowth(sectionKey)):upper() end,
			function(val)
				setAuraSectionValue(sectionKey, { "growth" }, (val or defaultAuraGrowth(sectionKey)):upper())
				refreshSelf()
			end,
			defaultAuraGrowth(sectionKey),
			parentId
		)
		list[#list].isEnabled = isLayoutEnabled

		list[#list + 1] = slider(labelPrefix .. " Offset X", -OFFSET_RANGE, OFFSET_RANGE, 1, function()
			local anchor = getAuraAnchorValue(sectionKey)
			return getAuraSectionValue(sectionKey, { "offset", "x" }, defaultAuraOffsetX(anchor))
		end, function(val)
			setAuraSectionValue(sectionKey, { "offset", "x" }, val or 0)
			refreshSelf()
		end, defaultAuraOffsetX(auraDef.anchor or "BOTTOM"), parentId, true)
		list[#list].isEnabled = isLayoutEnabled

		list[#list + 1] = slider(labelPrefix .. " Offset Y", -OFFSET_RANGE, OFFSET_RANGE, 1, function()
			local anchor = getAuraAnchorValue(sectionKey)
			return getAuraSectionValue(sectionKey, { "offset", "y" }, defaultAuraOffsetY(anchor))
		end, function(val)
			setAuraSectionValue(sectionKey, { "offset", "y" }, val or 0)
			refreshSelf()
		end, defaultAuraOffsetY(auraDef.anchor or "BOTTOM"), parentId, true)
		list[#list].isEnabled = isLayoutEnabled

		if unit == "player" then
			list[#list + 1] = radioDropdown(
				labelPrefix .. " " .. (L["Frame strata"] or "Frame strata"),
				strataOptionsWithDefault,
				function() return getAuraSectionValue(sectionKey, { "strata" }, "") or "" end,
				function(val)
					if val == "" then val = nil end
					setAuraSectionValue(sectionKey, { "strata" }, val)
					refreshSelf()
				end,
				"",
				parentId
			)
			list[#list].isEnabled = isSectionEnabled

			list[#list + 1] = slider(
				labelPrefix .. " " .. (L["UFDetachedPowerLevelOffset"] or "Frame level offset"),
				0,
				50,
				1,
				function() return getAuraSectionValue(sectionKey, { "frameLevelOffset" }, 5) end,
				function(val)
					setAuraSectionValue(sectionKey, { "frameLevelOffset" }, val or 5)
					refreshSelf()
				end,
				5,
				parentId,
				true
			)
			list[#list].isEnabled = isSectionEnabled
		end

		list[#list + 1] = slider(labelPrefix .. " " .. (L["Size"] or "size"), 12, 120, 1, function() return getAuraSectionValue(sectionKey, { "size" }, auraDef.size or 24) end, function(val)
			setAuraSectionValue(sectionKey, { "size" }, clampNumber(val, 12, 120, auraDef.size or 24))
			refreshSelf()
		end, auraDef.size or 24, parentId, true)
		list[#list].isEnabled = isSectionEnabled

		list[#list + 1] = radioDropdown(
			L["settingsIconShapeLabel"] or "Icon shape",
			iconShapeOptions,
			function()
				if UF and UF.AuraUtil and UF.AuraUtil.NormalizeIconShape then
					return UF.AuraUtil.NormalizeIconShape(getAuraSectionValue(sectionKey, { "iconShape" }, auraDef.iconShape or "DEFAULT"), auraDef.iconShape or "DEFAULT")
				end
				return getAuraSectionValue(sectionKey, { "iconShape" }, auraDef.iconShape or "DEFAULT")
			end,
			function(val)
				if UF and UF.AuraUtil and UF.AuraUtil.NormalizeIconShape then val = UF.AuraUtil.NormalizeIconShape(val, "DEFAULT") end
				setAuraSectionValue(sectionKey, { "iconShape" }, val or "DEFAULT")
				if addon.IconShape and addon.IconShape.NormalizeBorder then
					local border = getAuraSectionValue(sectionKey, { "borderTexture" }, auraDef.borderTexture or "DEFAULT")
					setAuraSectionValue(sectionKey, { "borderTexture" }, addon.IconShape.NormalizeBorder(border, auraDef.borderTexture or "DEFAULT", val or "DEFAULT", { allowNone = true }))
				end
				refreshSelf()
				refreshSettingsUI()
				refreshAuras()
			end,
			auraDef.iconShape or "DEFAULT",
			parentId
		)
		list[#list].isEnabled = isSectionEnabled

		list[#list + 1] = slider(
			labelPrefix .. " " .. (L["Icon zoom"] or "Icon zoom"),
			0,
			35,
			1,
			function() return getAuraSectionIconZoom(sectionKey) end,
			function(val)
				if addon.IconShape and addon.IconShape.NormalizeIconZoom then
					val = addon.IconShape.NormalizeIconZoom(val)
				else
					val = clampNumber(val, 0, 35, auraDef.iconZoom or 0)
				end
				setAuraSectionValue(sectionKey, { "iconZoom" }, val or 0)
				refreshSelf()
				refreshAuras()
			end,
			auraDef.iconZoom or 0,
			parentId,
			true
		)
		list[#list].isEnabled = isSectionEnabled

		list[#list + 1] = slider(
			labelPrefix .. " " .. (L["Aura per row"] or "per row"),
			0,
			40,
			1,
			function() return getAuraSectionValue(sectionKey, { "perRow" }, auraDef.perRow or 0) end,
			function(val)
				val = tonumber(val) or 0
				if val < 0 then val = 0 end
				setAuraSectionValue(sectionKey, { "perRow" }, math.floor(val + 0.5))
				refreshSelf()
			end,
			auraDef.perRow or 0,
			parentId,
			true,
			function(value)
				value = tonumber(value) or 0
				if value <= 0 then return L["Auto"] or "Auto" end
				return tostring(math.floor(value + 0.5))
			end
		)
		list[#list].isEnabled = isLayoutEnabled

		list[#list + 1] = slider(
			(isDebuff and (L["Debuff max"] or "Debuff max")) or (L["Buff max"] or "Buff max"),
			1,
			40,
			1,
			function() return getAuraSectionValue(sectionKey, { "max" }, auraDef.max or 16) end,
			function(val)
				val = clampNumber(val, 1, 40, auraDef.max or 16)
				setAuraSectionValue(sectionKey, { "max" }, val or auraDef.max or 16)
				refreshSelf()
			end,
			auraDef.max or 16,
			parentId,
			true
		)
		list[#list].isEnabled = isSectionEnabled

		list[#list + 1] = slider(
			(isDebuff and (L["Debuff spacing"] or "Debuff spacing")) or (L["Buff spacing"] or "Buff spacing"),
			0,
			10,
			1,
			function() return getAuraSectionValue(sectionKey, { "spacing" }, auraDef.padding or 2) end,
			function(val)
				setAuraSectionValue(sectionKey, { "spacing" }, val or 0)
				refreshSelf()
			end,
			auraDef.padding or 2,
			parentId,
			true
		)
		list[#list].isEnabled = isLayoutEnabled

		list[#list + 1] = checkboxDropdown(
			L["Aura border texture"] or "Aura border texture",
			function() return getAuraBorderOptions(sectionKey) end,
			function() return getAuraBorderValue(sectionKey) end,
			function(val)
				if addon.IconShape and addon.IconShape.NormalizeBorder then val = addon.IconShape.NormalizeBorder(val, auraDef.borderTexture or "DEFAULT", getAuraSectionShape(sectionKey), { allowNone = true }) end
				setAuraSectionValue(sectionKey, { "borderTexture" }, val or "DEFAULT")
				refreshSelf()
				refreshSettingsUI()
				refreshAuras()
			end,
			auraDef.borderTexture or "DEFAULT",
			parentId
		)
		list[#list].isEnabled = isSectionEnabled

		list[#list + 1] = radioDropdown(L["Aura border render mode"] or "Aura border render mode", borderRenderModeOptions, function()
			local mode = (getAuraSectionValue(sectionKey, { "borderRenderMode" }, auraDef.borderRenderMode or "EDGE") or "EDGE"):upper()
			if mode == "OVERLAY" then return "OVERLAY" end
			return "EDGE"
		end, function(val)
			local mode = tostring(val or "EDGE"):upper()
			if mode ~= "OVERLAY" then mode = "EDGE" end
			setAuraSectionValue(sectionKey, { "borderRenderMode" }, mode)
			refreshSelf()
			refreshSettingsUI()
			refreshAuras()
		end, ((auraDef.borderRenderMode or "EDGE"):upper() == "OVERLAY") and "OVERLAY" or "EDGE", parentId)
		list[#list].isEnabled = function()
			local shape = getAuraSectionShape(sectionKey)
			return isSectionEnabled() and (not addon.IconShape or not addon.IconShape.IsBackdropBorderCompatible or addon.IconShape.IsBackdropBorderCompatible(shape))
		end

		list[#list + 1] = slider(L["Border size (Edge)"] or "Border size (Edge)", 1, 64, 1, function()
			local iconSize = getAuraSectionValue(sectionKey, { "size" }, auraDef.size or 24)
			local fallback = math.floor((iconSize * 0.08) + 0.5)
			if fallback < 1 then fallback = 1 end
			if fallback > 6 then fallback = 6 end
			return getAuraSectionValue(sectionKey, { "borderSize" }, auraDef.borderSize or fallback)
		end, function(val)
			local size = tonumber(val) or 1
			if size < 1 then size = 1 end
			setAuraSectionValue(sectionKey, { "borderSize" }, math.floor(size + 0.5))
			refreshSelf()
			refreshAuras()
		end, auraDef.borderSize or 2, parentId, true)
		list[#list].isEnabled = isEdgeBorderMode

		list[#list + 1] = slider(
			L["Border offset (Edge)"] or "Border offset (Edge)",
			-64,
			64,
			1,
			function() return getAuraSectionValue(sectionKey, { "borderOffset" }, auraDef.borderOffset or 0) end,
			function(val)
				local offset = tonumber(val) or 0
				setAuraSectionValue(sectionKey, { "borderOffset" }, math.floor(offset + 0.5))
				refreshSelf()
				refreshAuras()
			end,
			auraDef.borderOffset or 0,
			parentId,
			true
		)
		list[#list].isEnabled = supportsBorderOffset

		if isDebuff then
			list[#list + 1] = checkbox(
				L["Highlight dispellable"] or "Highlight dispellable",
				function() return getAuraSectionValue(sectionKey, { "blizzardDispelBorder" }, auraDef.blizzardDispelBorder == true) == true end,
				function(val)
					setAuraSectionValue(sectionKey, { "blizzardDispelBorder" }, val and true or false)
					refreshSelf()
					refreshAuras()
				end,
				auraDef.blizzardDispelBorder == true,
				parentId
			)
			list[#list].isEnabled = isSectionEnabled
		elseif (unit == "target" or unit == "focus" or isBossUnit(unit)) then
			list[#list + 1] = checkbox(
				L["Highlight stealable"] or "Highlight stealable",
				function() return getAuraSectionValue(sectionKey, { "blizzardStealableBorder" }, auraDef.blizzardStealableBorder ~= false) ~= false end,
				function(val)
					setAuraSectionValue(sectionKey, { "blizzardStealableBorder" }, val and true or false)
					refreshSelf()
					refreshSettingsUI()
					refreshAuras()
				end,
				auraDef.blizzardStealableBorder ~= false,
				parentId
			)
			list[#list].isEnabled = isSectionEnabled

			local function isStealableHighlightEnabled()
				return isSectionEnabled() and getAuraSectionValue(sectionKey, { "blizzardStealableBorder" }, auraDef.blizzardStealableBorder ~= false) ~= false
			end
			local stealableGlowStyleOptions = {
				{ value = "DEFAULT", label = _G.DEFAULT or L["Default"] or "Default" },
				{ value = "BLIZZARD", label = L["Blizzard"] or "Blizzard" },
				{ value = "FLASH", label = L["Flash"] or "Flash" },
				{ value = "MARCHING_ANTS", label = L["Marching ants"] or "Marching ants" },
				{ value = "PIXEL", label = L["Pixel"] or "Pixel" },
				{ value = "PULSING", label = L["Pulsing"] or "Pulsing" },
				{ value = "SOLID", label = L["Solid"] or "Solid" },
			}

			local stealableGlowStyle = radioDropdown(
				L["Glow style"] or "Glow style",
				stealableGlowStyleOptions,
				function()
					local value = getAuraSectionValue(sectionKey, { "blizzardStealableGlowStyle" }, auraDef.blizzardStealableGlowStyle or "DEFAULT")
					if UF.AuraUtil and UF.AuraUtil.NormalizeStealableGlowStyle then return UF.AuraUtil.NormalizeStealableGlowStyle(value) end
					return "DEFAULT"
				end,
				function(val)
					if UF.AuraUtil and UF.AuraUtil.NormalizeStealableGlowStyle then val = UF.AuraUtil.NormalizeStealableGlowStyle(val) end
					setAuraSectionValue(sectionKey, { "blizzardStealableGlowStyle" }, val or "DEFAULT")
					refreshSelf()
					refreshAuras()
				end,
				auraDef.blizzardStealableGlowStyle or "DEFAULT",
				parentId
			)
			stealableGlowStyle.isShown = isStealableHighlightEnabled
			stealableGlowStyle.isEnabled = isSectionEnabled
			list[#list + 1] = stealableGlowStyle

			local stealableGlowInset = slider(
				L["Glow inset"] or "Glow inset",
				-100,
				100,
				1,
				function()
					local value = getAuraSectionValue(sectionKey, { "blizzardStealableGlowInset" }, auraDef.blizzardStealableGlowInset or 0)
					if UF.AuraUtil and UF.AuraUtil.NormalizeStealableGlowInset then return UF.AuraUtil.NormalizeStealableGlowInset(value) end
					return 0
				end,
				function(val)
					if UF.AuraUtil and UF.AuraUtil.NormalizeStealableGlowInset then val = UF.AuraUtil.NormalizeStealableGlowInset(val) end
					setAuraSectionValue(sectionKey, { "blizzardStealableGlowInset" }, val or 0)
					refreshSelf()
					refreshAuras()
				end,
				auraDef.blizzardStealableGlowInset or 0,
				parentId,
				true
			)
			stealableGlowInset.isShown = isStealableHighlightEnabled
			stealableGlowInset.isEnabled = isSectionEnabled
			list[#list + 1] = stealableGlowInset
		end

		list[#list + 1] = { name = "", kind = UF.ui.settingType.Divider, parentId = parentId }

		list[#list + 1] = checkbox(L["CooldownPanelShowCooldown"] or "Show cooldown", isShowCooldown, function(val)
			setAuraSectionValue(sectionKey, { "showCooldown" }, val and true or false)
			refreshSelf()
			refreshAuras()
		end, auraDef.showCooldown ~= false, parentId)
		list[#list].isEnabled = isSectionEnabled

		list[#list + 1] = checkbox(L["Show cooldown text"] or "Show cooldown text", isShowCooldownText, function(val)
			setAuraSectionValue(sectionKey, { "showCooldownText" }, val and true or false)
			refreshSelf()
			refreshAuras()
		end, auraDef.showCooldown ~= false, parentId)
		list[#list].isEnabled = isSectionEnabled

		list[#list + 1] = checkboxDropdown(
			L["durationTextProfile"] or "Duration text profile",
			durationTextProfileOptions,
			function() return normalizeDurationTextProfile(getAuraSectionValue(sectionKey, { "durationTextProfile" }, auraDef.durationTextProfile or "MINIMAL")) end,
			function(val)
				setAuraSectionValue(sectionKey, { "durationTextProfile" }, normalizeDurationTextProfile(val))
				refreshSelf()
				refreshAuras()
			end,
			auraDef.durationTextProfile or "MINIMAL",
			parentId
		)
		list[#list].isEnabled = function() return isSectionEnabled() and isShowCooldownText() end

		list[#list + 1] = radioDropdown(
			L["Cooldown text anchor"] or "Cooldown text anchor",
			cooldownAnchorOptions,
			function() return getAuraSectionValue(sectionKey, { "cooldownAnchor" }, auraDef.cooldownAnchor or "CENTER") end,
			function(val)
				setAuraSectionValue(sectionKey, { "cooldownAnchor" }, val or "CENTER")
				refreshSelf()
			end,
			auraDef.cooldownAnchor or "CENTER",
			parentId
		)
		list[#list].isEnabled = function() return isSectionEnabled() and isShowCooldownText() end

		list[#list + 1] = slider(
			L["Cooldown text offset X"] or "Cooldown text offset X",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getAuraSectionValue(sectionKey, { "cooldownOffset", "x" }, (auraDef.cooldownOffset and auraDef.cooldownOffset.x) or 0) end,
			function(val)
				setAuraSectionValue(sectionKey, { "cooldownOffset", "x" }, val or 0)
				refreshSelf()
			end,
			(auraDef.cooldownOffset and auraDef.cooldownOffset.x) or 0,
			parentId,
			true
		)
		list[#list].isEnabled = function() return isSectionEnabled() and isShowCooldownText() end

		list[#list + 1] = slider(
			L["Cooldown text offset Y"] or "Cooldown text offset Y",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getAuraSectionValue(sectionKey, { "cooldownOffset", "y" }, (auraDef.cooldownOffset and auraDef.cooldownOffset.y) or 0) end,
			function(val)
				setAuraSectionValue(sectionKey, { "cooldownOffset", "y" }, val or 0)
				refreshSelf()
			end,
			(auraDef.cooldownOffset and auraDef.cooldownOffset.y) or 0,
			parentId,
			true
		)
		list[#list].isEnabled = function() return isSectionEnabled() and isShowCooldownText() end

		list[#list + 1] = slider(L["Cooldown text size"] or "Cooldown text size", 1, 32, 1, function()
			local fallback = auraDef.cooldownFontSize or 14
			local val = getAuraSectionValue(sectionKey, { "cooldownFontSize" }, fallback)
			val = tonumber(val) or 0
			if val < 1 then val = fallback end
			return val
		end, function(val)
			val = tonumber(val) or 0
			if val < 1 then val = 1 end
			setAuraSectionValue(sectionKey, { "cooldownFontSize" }, val)
			refreshSelf()
		end, auraDef.cooldownFontSize or 14, parentId, true)
		list[#list].isEnabled = function() return isSectionEnabled() and isShowCooldownText() end

		if #fontOptions() > 0 then
			list[#list + 1] = checkboxDropdown(
				L["Cooldown text font"] or "Cooldown text font",
				fontOptions,
				function() return getAuraSectionValue(sectionKey, { "cooldownFont" }, auraDef.cooldownFont or globalFontConfigKey()) end,
				function(val)
					setAuraSectionValue(sectionKey, { "cooldownFont" }, val)
					refreshSelf()
				end,
				auraDef.cooldownFont or globalFontConfigKey(),
				parentId
			)
			list[#list].isEnabled = function() return isSectionEnabled() and isShowCooldownText() end
		end

		list[#list + 1] = checkboxDropdown(
			L["Cooldown text outline"] or "Cooldown text outline",
			outlineOptions,
			function()
				return normalizeFontStyleChoice(
					getAuraSectionValue(sectionKey, { "cooldownFontOutline" }, auraDef.cooldownFontOutline or "OUTLINE"),
					auraDef.cooldownFontOutline or "OUTLINE"
				)
			end,
			function(val)
				setAuraSectionValue(sectionKey, { "cooldownFontOutline" }, normalizeFontStyleChoice(val, auraDef.cooldownFontOutline or "OUTLINE") or nil)
				refreshSelf()
			end,
			auraDef.cooldownFontOutline or "OUTLINE",
			parentId
		)
		list[#list].isEnabled = function() return isSectionEnabled() and isShowCooldownText() end

		list[#list + 1] = { name = "", kind = UF.ui.settingType.Divider, parentId = parentId }

		list[#list + 1] = radioDropdown(
			L["Aura stack position"] or "Aura stack position",
			stackAnchorOptions,
			function() return getAuraSectionValue(sectionKey, { "countAnchor" }, auraDef.countAnchor or "BOTTOMRIGHT") end,
			function(val)
				setAuraSectionValue(sectionKey, { "countAnchor" }, val or "BOTTOMRIGHT")
				refreshSelf()
			end,
			auraDef.countAnchor or "BOTTOMRIGHT",
			parentId
		)
		list[#list].isEnabled = isSectionEnabled

		list[#list + 1] = slider(
			L["Aura stack offset X"] or "Aura stack offset X",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getAuraSectionValue(sectionKey, { "countOffset", "x" }, (auraDef.countOffset and auraDef.countOffset.x) or -2) end,
			function(val)
				setAuraSectionValue(sectionKey, { "countOffset", "x" }, val or 0)
				refreshSelf()
			end,
			(auraDef.countOffset and auraDef.countOffset.x) or -2,
			parentId,
			true
		)
		list[#list].isEnabled = isSectionEnabled

		list[#list + 1] = slider(
			L["Aura stack offset Y"] or "Aura stack offset Y",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getAuraSectionValue(sectionKey, { "countOffset", "y" }, (auraDef.countOffset and auraDef.countOffset.y) or 2) end,
			function(val)
				setAuraSectionValue(sectionKey, { "countOffset", "y" }, val or 0)
				refreshSelf()
			end,
			(auraDef.countOffset and auraDef.countOffset.y) or 2,
			parentId,
			true
		)
		list[#list].isEnabled = isSectionEnabled

		list[#list + 1] = slider(
			L["Aura stack size"] or "Aura stack size",
			8,
			32,
			1,
			function() return getAuraSectionValue(sectionKey, { "countFontSize" }, auraDef.countFontSize or 14) end,
			function(val)
				setAuraSectionValue(sectionKey, { "countFontSize" }, val or 14)
				refreshSelf()
			end,
			auraDef.countFontSize or 14,
			parentId,
			true
		)
		list[#list].isEnabled = isSectionEnabled

		if #fontOptions() > 0 then
			list[#list + 1] = checkboxDropdown(
				L["Font"] or "Font",
				fontOptions,
				function() return getAuraSectionValue(sectionKey, { "countFont" }, auraDef.countFont or globalFontConfigKey()) end,
				function(val)
					setAuraSectionValue(sectionKey, { "countFont" }, val)
					refreshSelf()
				end,
				auraDef.countFont or globalFontConfigKey(),
				parentId
			)
			list[#list].isEnabled = isSectionEnabled
		end

		list[#list + 1] = checkboxDropdown(
			L["Aura stack outline"] or "Aura stack outline",
			stackOutlineOptions,
			function()
				return normalizeFontStyleChoice(
					getAuraSectionValue(sectionKey, { "countFontOutline" }, auraDef.countFontOutline or "OUTLINE"),
					auraDef.countFontOutline or "OUTLINE"
				)
			end,
			function(val)
				setAuraSectionValue(sectionKey, { "countFontOutline" }, normalizeFontStyleChoice(val, auraDef.countFontOutline or "OUTLINE") or nil)
				refreshSelf()
			end,
			auraDef.countFontOutline or "OUTLINE",
			parentId
		)
		list[#list].isEnabled = isSectionEnabled

		list[#list + 1] = checkbox(
			(isDebuff and (L["Hide permanent debuffs"] or "Hide permanent debuffs")) or (L["Hide permanent buffs"] or "Hide permanent buffs"),
			function() return getAuraSectionValue(sectionKey, { "hidePermanentAuras" }, false) == true end,
			function(val)
				setAuraSectionValue(sectionKey, { "hidePermanentAuras" }, val and true or false)
				refreshSelf()
				refreshAuras()
			end,
			false,
			parentId
		)
		list[#list].isEnabled = isSectionEnabled
	end

	list[#list + 1] = { name = L["Buffs"] or "Buffs", kind = UF.ui.settingType.Collapsible, id = "buffs", defaultCollapsed = true }
	appendAuraSection("buff", "buffs", false)

	list[#list + 1] = { name = L["Debuffs"] or "Debuffs", kind = UF.ui.settingType.Collapsible, id = "debuffs", defaultCollapsed = true }
	appendAuraSection("debuff", "debuffs", true)
end

local function toRGBA(value, fallback)
	if not value then value = fallback end
	if not value then return 1, 1, 1, 1 end
	if value.r then return value.r or 1, value.g or 1, value.b or 1, value.a or 1 end
	return value[1] or (fallback and fallback[1]) or 1, value[2] or (fallback and fallback[2]) or 1, value[3] or (fallback and fallback[3]) or 1, value[4] or (fallback and fallback[4]) or 1
end

local visualOnlyRefreshPending = false

local function consumeVisualOnlyRefreshPending()
	local pending = visualOnlyRefreshPending == true
	visualOnlyRefreshPending = false
	return pending
end

local function setColor(unit, path, r, g, b, a)
	local _, _, _, curA = toRGBA(getValue(unit, path))
	setValue(unit, path, { r or 1, g or 1, b or 1, a or curA or 1 })
	visualOnlyRefreshPending = true
end

local function canRefresh() return addon.db ~= nil and addon.Aura and addon.Aura.UFInitialized end

local function refresh(unit)
	if not canRefresh() then return end
	if UF.RefreshUnit and unit then
		UF.RefreshUnit(unit)
	elseif UF.Refresh then
		UF.Refresh()
	end
	consumeVisualOnlyRefreshPending()
end

local refreshBatchDepth = 0
local refreshBatchAll = false
local refreshBatchUnits = {}

local function clearRefreshBatchState()
	refreshBatchAll = false
	for unit in pairs(refreshBatchUnits) do
		refreshBatchUnits[unit] = nil
	end
end

local function requestRefresh(unit)
	if refreshBatchDepth > 0 then
		if unit == nil then
			clearRefreshBatchState()
			refreshBatchAll = true
		elseif not refreshBatchAll then
			refreshBatchUnits[unit] = true
		end
		return
	end
	refresh(unit)
end

local function flushRefreshBatch()
	if refreshBatchAll then
		clearRefreshBatchState()
		refresh()
		return
	end
	local pendingCount = 0
	local pendingUnit
	for unit in pairs(refreshBatchUnits) do
		pendingCount = pendingCount + 1
		pendingUnit = unit
		if pendingCount > 1 then break end
	end
	clearRefreshBatchState()
	if pendingCount == 1 then
		refresh(pendingUnit)
	elseif pendingCount > 1 then
		refresh()
	end
end

local function beginRefreshBatch() refreshBatchDepth = refreshBatchDepth + 1 end

local function endRefreshBatch()
	if refreshBatchDepth <= 0 then return end
	refreshBatchDepth = refreshBatchDepth - 1
	if refreshBatchDepth == 0 then flushRefreshBatch() end
end

function refreshSettingsUI()
	local lib = addon.EditModeLib
	local internal = lib and lib.internal
	if not internal then return end
	if internal.RequestRefreshSettings then
		internal:RequestRefreshSettings()
		if internal.RequestRefreshSettingValues then internal:RequestRefreshSettingValues() end
		return
	end
	if internal.RefreshSettings then internal:RefreshSettings() end
	if internal.RefreshSettingValues then internal:RefreshSettingValues() end
end

local frameIds = {
	player = "EQOL_UF_Player",
	target = "EQOL_UF_Target",
	targettarget = "EQOL_UF_ToT",
	pet = "EQOL_UF_Pet",
	focus = "EQOL_UF_Focus",
	boss = "EQOL_UF_Boss",
}

local function getGlobalAuraIgnoreEditorContext(unit)
	if unit == "player" or unit == "target" or unit == "focus" then return unit end
	return nil
end

local function toggleGlobalAuraIgnoreEditor(unit)
	local context = getGlobalAuraIgnoreEditorContext(unit)
	if not context then return end
	local editor = UF and UF.GlobalAuraIgnore
	if not (editor and editor.ToggleEditor) then return end
	editor:ToggleEditor(context)
	if addon.EditModeLib and addon.EditModeLib.internal and addon.EditModeLib.internal.RequestRefreshSettings then addon.EditModeLib.internal:RequestRefreshSettings() end
end

local syncingEditModeFrameRefresh = {}

local function getEditModeAnchorValues(unit)
	local ownerFrame = _G[UF.GetAnchorFrameName and UF.GetAnchorFrameName(unit) or ""]
	local dynamicWinner = UF.GetDynamicAnchorWinner and UF.GetDynamicAnchorWinner(unit, ownerFrame) or nil
	if dynamicWinner then
		local placement = dynamicWinner.placement or {}
		local point = placement.point or "CENTER"
		return point, placement.relativePoint or point, tonumber(placement.x) or 0, tonumber(placement.y) or 0
	end
	local cfg = ensureConfig(unit)
	local def = defaultsFor(unit)
	local anchor = (cfg and cfg.anchor) or (def and def.anchor) or {}
	local point = type(anchor.point) == "string" and string.upper(anchor.point) or "CENTER"
	local relativePoint = type(anchor.relativePoint) == "string" and string.upper(anchor.relativePoint) or point
	local x = tonumber(anchor.x) or 0
	local relativeName = anchor.relativeTo or anchor.relativeFrame
	local ownerFrameName = UF.GetAnchorFrameName and UF.GetAnchorFrameName(unit) or nil
	local relativeFrame = UF.ResolveRelativeAnchorFrame and UF.ResolveRelativeAnchorFrame(relativeName, ownerFrameName) or UIParent
	local showStatus = unit ~= "boss" and UF.ShouldShowStatusLayout and UF.ShouldShowStatusLayout(cfg, unit, def)
	local statusHeightDelta = unit ~= "boss" and UF.GetStatusHeightDelta and UF.GetStatusHeightDelta(showStatus) or 0
	local y = UF.ResolvePhysicalUnitFrameAnchorY and UF.ResolvePhysicalUnitFrameAnchorY(point, relativePoint, anchor.y, relativeFrame, statusHeightDelta) or tonumber(anchor.y) or 0
	return point, relativePoint, x, y
end

local function refreshEditModeFrame(unit)
	if not (EditMode and EditMode.RefreshFrame) then return end
	local frameId = frameIds[unit]
	if not frameId then return end
	local point, relativePoint, x, y = getEditModeAnchorValues(unit)
	if EditMode.SetValue then
		EditMode:SetValue(frameId, "point", point, nil, true)
		EditMode:SetValue(frameId, "relativePoint", relativePoint, nil, true)
		EditMode:SetValue(frameId, "x", x, nil, true)
		EditMode:SetValue(frameId, "y", y, nil, true)
	elseif EditMode.EnsureLayoutData and EditMode.GetActiveLayoutName then
		local layoutName = EditMode:GetActiveLayoutName()
		if layoutName then
			local data = EditMode:EnsureLayoutData(frameId, layoutName)
			if data then
				data.point = point
				data.relativePoint = relativePoint
				data.x = x
				data.y = y
			end
		end
	end
	do
		local internal = addon.EditModeLib and addon.EditModeLib.internal
		if internal and internal.RequestRefreshSettingValues then
			internal:RequestRefreshSettingValues()
		elseif internal and internal.RefreshSettingValues then
			internal:RefreshSettingValues()
		end
	end
	if not syncingEditModeFrameRefresh[frameId] then
		syncingEditModeFrameRefresh[frameId] = true
		EditMode:RefreshFrame(frameId)
		syncingEditModeFrameRefresh[frameId] = nil
	end
	if EditMode and EditMode.IsInEditMode and EditMode:IsInEditMode() then
		local entry = EditMode.frames and EditMode.frames[frameId]
		local frame = entry and entry.frame
		syncEditModeSelectionStrata(frame)
	end
end

local copyDialogKey = "EQOL_UF_COPY_SETTINGS"
local copyFrameLabels = {
	player = L["UFPlayerFrame"] or PLAYER,
	target = L["UFTargetFrame"] or TARGET,
	targettarget = L["UFToTFrame"] or "Target of Target",
	pet = L["UFPetFrame"] or PET,
	focus = L["UFFocusFrame"] or FOCUS,
	boss = L["UFBossFrame"] or BOSS or "Boss Frame",
}
local UnitAnchor = {
	optionOrder = { "player", "target", "targettarget", "focus", "pet", "boss" },
	frameNames = {
		player = "EQOLUFPlayerFrame",
		target = "EQOLUFTargetFrame",
		targettarget = "EQOLUFToTFrame",
		pet = "EQOLUFPetFrame",
		focus = "EQOLUFFocusFrame",
		boss = "EQOLUFBossContainer",
	},
}

function UnitAnchor.GetFrameName(unit)
	if UF and UF.GetAnchorFrameName then return UF.GetAnchorFrameName(unit) end
	return UnitAnchor.frameNames[unit]
end

function UnitAnchor.GetRelativeName(unit)
	local cfg = ensureConfig(unit)
	local def = defaultsFor(unit)
	local anchor = (cfg and cfg.anchor) or (def and def.anchor) or {}
	return anchor.relativeTo or anchor.relativeFrame or "UIParent"
end

function UnitAnchor.ResolveEditModeFrame(unit)
	local ownerFrame = _G[UnitAnchor.GetFrameName(unit)]
	local dynamicWinner = UF.GetDynamicAnchorWinner and UF.GetDynamicAnchorWinner(unit, ownerFrame) or nil
	if dynamicWinner and dynamicWinner.frame then return dynamicWinner.frame end
	local relativeName = UnitAnchor.GetRelativeName(unit)
	if UF and UF.ResolveRelativeAnchorFrame then return UF.ResolveRelativeAnchorFrame(relativeName, UnitAnchor.GetFrameName(unit)) end
	if relativeName == "UIParent" then return UIParent end
	return _G[relativeName] or UIParent
end

function UnitAnchor.AddOption(list, seen, value, label)
	if type(value) ~= "string" or value == "" or seen[value] then return end
	seen[value] = true
	list[#list + 1] = { value = value, label = label or value }
end

function UnitAnchor.AppendResourceBars(list, seen)
	local rb = addon.Aura and addon.Aura.ResourceBars
	if not rb then return end
	local classToken = addon.variables and addon.variables.unitClass
	local specIndex = addon.variables and addon.variables.unitSpec
	local settings = addon.db and addon.db.personalResourceBarSettings
	local classCfg = settings and classToken and settings[classToken]
	local specCfg = classCfg and specIndex and classCfg[specIndex]
	local entries = {}
	if (type(specCfg) == "table" and type(specCfg.HEALTH) == "table" and specCfg.HEALTH.enabled == true) or _G.EQOLHealthBar then
		entries[#entries + 1] = {
			value = "EQOLHealthBar",
			label = string.format("%s: %s", L["Resource Bars"] or "Resource Bars", HEALTH or _G.HEALTH or "Health"),
		}
	end
	if type(specCfg) == "table" then
		for barType, barCfg in pairs(specCfg) do
			if barType ~= "HEALTH" and type(barCfg) == "table" then
				local frameName = "EQOL" .. tostring(barType) .. "Bar"
				if barCfg.enabled == true or _G[frameName] then
					local barLabel = (rb.PowerLabels and rb.PowerLabels[barType]) or tostring(barType)
					entries[#entries + 1] = {
						value = frameName,
						label = string.format("%s: %s", L["Resource Bars"] or "Resource Bars", tostring(barLabel)),
					}
				end
			end
		end
	end
	table.sort(entries, function(a, b) return tostring(a.label) < tostring(b.label) end)
	for _, entry in ipairs(entries) do
		UnitAnchor.AddOption(list, seen, entry.value, entry.label)
	end
end

function UnitAnchor.AppendCooldownViewers(list, seen)
	local function add(frameName, label)
		UnitAnchor.AddOption(list, seen, frameName, label)
	end

	add("EssentialCooldownViewer", L["cooldownViewerEssential"] or "Essential Cooldown Viewer")
	add("UtilityCooldownViewer", L["cooldownViewerUtility"] or "Utility Cooldown Viewer")
	add("BuffIconCooldownViewer", L["cooldownViewerBuffIcon"] or "Buff Icon Cooldowns")
	add("BuffBarCooldownViewer", L["cooldownViewerBuffBar"] or "Buff Bar Cooldowns")
end

function UnitAnchor.AppendCooldownPanels(list, seen)
	local cp = addon.Aura and addon.Aura.CooldownPanels
	if not (cp and cp.GetRoot and cp.GetPanel) then return end
	local root = cp:GetRoot()
	if not (root and root.panels) then return end
	local entries = {}
	local handled = {}
	local function addPanel(panelId)
		if panelId == nil or handled[panelId] then return end
		handled[panelId] = true
		local panel = cp:GetPanel(panelId) or root.panels[panelId] or root.panels[tostring(panelId)]
		if not panel then return end
		entries[#entries + 1] = {
			value = "EQOL_CooldownPanel" .. tostring(panelId),
			label = string.format("%s: %s", L["VisibilityCooldownPanel"] or L["Cooldown Panels"] or "Cooldown Panel", panel.name or tostring(panelId)),
		}
	end
	for _, panelId in ipairs(root.order or {}) do
		addPanel(panelId)
	end
	for panelId in pairs(root.panels) do
		addPanel(panelId)
	end
	table.sort(entries, function(a, b) return tostring(a.label) < tostring(b.label) end)
	for _, entry in ipairs(entries) do
		UnitAnchor.AddOption(list, seen, entry.value, entry.label)
	end
end

function UnitAnchor.GetOptions(unit)
	local list = {}
	local seen = {}
	UnitAnchor.AddOption(list, seen, "UIParent", L["Screen (UIParent)"] or "Screen (UIParent)")
	for _, otherUnit in ipairs(UnitAnchor.optionOrder) do
		if otherUnit ~= unit then
			local frameName = UnitAnchor.GetFrameName(otherUnit)
			if frameName then UnitAnchor.AddOption(list, seen, frameName, copyFrameLabels[otherUnit] or frameName) end
		end
	end
	UnitAnchor.AppendResourceBars(list, seen)
	UnitAnchor.AppendCooldownViewers(list, seen)
	UnitAnchor.AppendCooldownPanels(list, seen)
	return list
end

function UnitAnchor.IsKnownTarget(unit, relativeName)
	if type(relativeName) ~= "string" or relativeName == "" or relativeName == "UIParent" then return true end
	for _, option in ipairs(UnitAnchor.GetOptions(unit)) do
		if option.value == relativeName then return true end
	end
	return false
end

function UnitAnchor.GetTargetValue(unit)
	local relativeName = UnitAnchor.GetRelativeName(unit)
	if relativeName == UnitAnchor.GetFrameName(unit) then return "UIParent" end
	if UF and UF.WouldRelativeAnchorLoop and UF.WouldRelativeAnchorLoop(unit, relativeName) then return "UIParent" end
	return relativeName
end

local function availableCopySources(unit)
	local opts = {}
	for key, label in pairs(copyFrameLabels) do
		if key ~= unit then opts[#opts + 1] = { value = key, label = label } end
	end
	table.sort(opts, function(a, b) return tostring(a.label) < tostring(b.label) end)
	return opts
end
UF.ui.availableCopySources = availableCopySources

local copySectionOrder = {
	"frame",
	"layout",
	"border",
	"highlight",
	"portrait",
	"name",
	"health",
	"incomingHeal",
	"absorb",
	"healAbsorb",
	"level",
	"statusText",
	"unitStatus",
	"raidicon",
	"power",
	"buffs",
	"debuffs",
	"rangeFade",
	"classResource",
	"totemFrame",
	"cast",
	"combatFeedback",
}

local copySectionLabels = {
	frame = L["Frame"] or "Frame",
	layout = L["Layout"] or "Layout",
	border = BORDER_LABEL,
	highlight = L["Highlight"] or "Highlight",
	portrait = L["Portrait"] or "Portrait",
	rangeFade = L["UFRangeFade"] or "Range fade",
	name = NAME or "Name",
	health = L["Health"] or HEALTH or "Health",
	incomingHeal = L["Incoming heals"] or "Incoming heals",
	absorb = L["Absorb"] or "Absorb",
	healAbsorb = L["Heal absorb"] or "Heal absorb",
	level = LEVEL or "Level",
	statusText = L["Status text"] or "Status text",
	unitStatus = L["UFUnitStatus"] or "Unit status",
	raidicon = L["Raid marker"] or "Raid marker",
	power = L["Power"] or _G.POWER or "Power",
	buffs = L["Buffs"] or "Buffs",
	debuffs = L["Debuffs"] or "Debuffs",
	classResource = L["ClassResource"] or "Class Resource",
	totemFrame = L["Totem Frame"] or "Totem Frame",
	cast = L["Castbar"] or "Cast Bar",
	combatFeedback = L["UFCombatFeedback"] or "Combat feedback",
}

local function getCopySectionSetForUnit(unit)
	local set = {
		frame = true,
		border = true,
		highlight = true,
		portrait = true,
		health = true,
		power = true,
		raidicon = true,
		name = true,
		level = true,
		statusText = true,
		unitStatus = true,
		combatFeedback = true,
	}
	local bossUnit = isBossUnit(unit)
	if bossUnit then set.layout = true end
	if unit == "target" or bossUnit then set.rangeFade = true end
	if unit == "player" or unit == "target" or unit == "focus" then set.incomingHeal = true end
	if unit ~= "pet" then
		set.absorb = true
		set.healAbsorb = true
	end
	if unit == "player" then
		local hasClassResource, hasTotemFrame = getPlayerClassFrameSupportFlags()
		if hasClassResource then set.classResource = true end
		if hasTotemFrame then set.totemFrame = true end
	end
	if unit == "player" or unit == "target" or unit == "focus" or bossUnit then
		set.cast = true
		set.buffs = true
		set.debuffs = true
	end
	return set
end

local function getCopySectionOptions(fromUnit, toUnit)
	local opts = {}
	local fromSections = getCopySectionSetForUnit(fromUnit)
	local toSections = getCopySectionSetForUnit(toUnit)
	for _, sectionId in ipairs(copySectionOrder) do
		if fromSections[sectionId] and toSections[sectionId] then opts[#opts + 1] = { value = sectionId, label = copySectionLabels[sectionId] or sectionId } end
	end
	return opts
end

local function ensureCopySectionSelection(payload)
	if type(payload) ~= "table" then return end
	payload.sectionOptions = type(payload.sectionOptions) == "table" and payload.sectionOptions or {}
	payload.sectionSelection = type(payload.sectionSelection) == "table" and payload.sectionSelection or {}
	for _, option in ipairs(payload.sectionOptions) do
		if payload.sectionSelection[option.value] == nil then payload.sectionSelection[option.value] = true end
	end
end

local function getSelectedCopySections(payload)
	local selected = {}
	if type(payload) ~= "table" then return selected end
	for _, option in ipairs(payload.sectionOptions or {}) do
		if payload.sectionSelection and payload.sectionSelection[option.value] == true then selected[#selected + 1] = option.value end
	end
	return selected
end

local function ensureCopySectionCheckbox(dialog, index)
	dialog.eqolCopySectionRows = dialog.eqolCopySectionRows or {}
	local row = dialog.eqolCopySectionRows[index]
	if row then return row end
	row = CreateFrame("CheckButton", nil, dialog, "UICheckButtonTemplate")
	row.Label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	row.Label:SetPoint("LEFT", row, "RIGHT", 1, 1)
	row.Label:SetJustifyH("LEFT")
	row.Label:SetWidth(250)
	row:SetHitRectInsets(0, -250, 0, 0)
	dialog.eqolCopySectionRows[index] = row
	return row
end

local function ensureCopyAllCheckbox(dialog)
	if dialog.eqolCopyAllRow then return dialog.eqolCopyAllRow end
	local row = CreateFrame("CheckButton", nil, dialog, "UICheckButtonTemplate")
	row.Label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	row.Label:SetPoint("LEFT", row, "RIGHT", 1, 1)
	row.Label:SetJustifyH("LEFT")
	row.Label:SetWidth(250)
	row:SetHitRectInsets(0, -250, 0, 0)
	row.Label:SetText(L["UFAllSettings"] or "All settings")
	row:SetScript("OnClick", function(self)
		local popup = self:GetParent()
		local payload = popup and popup.data
		if not payload then return end
		ensureCopySectionSelection(payload)
		local checked = self:GetChecked() == true
		for _, option in ipairs(payload.sectionOptions) do
			payload.sectionSelection[option.value] = checked
		end
		if popup.eqolRefreshCopySelection then popup:eqolRefreshCopySelection() end
	end)
	dialog.eqolCopyAllRow = row
	return row
end

local function refreshCopySelectionDialog(dialog)
	local payload = dialog and dialog.data
	if not payload then return end
	ensureCopySectionSelection(payload)
	local options = payload.sectionOptions or {}
	local popupHeight = 150 + ((#options + 1) * 22)
	if popupHeight < 190 then popupHeight = 190 end
	local maxPopupHeight = 540
	if UIParent and UIParent.GetHeight then
		local uiHeight = tonumber(UIParent:GetHeight())
		if uiHeight and uiHeight > 0 then maxPopupHeight = math.max(320, math.floor(uiHeight - 120)) end
	end
	if popupHeight > maxPopupHeight then popupHeight = maxPopupHeight end
	if StaticPopup_Resize then StaticPopup_Resize(dialog, 370, popupHeight) end
	local allRow = ensureCopyAllCheckbox(dialog)
	allRow:ClearAllPoints()
	if dialog.button1 then
		allRow:SetPoint("TOPLEFT", dialog.button1, "BOTTOMLEFT", -40, -16)
	else
		allRow:SetPoint("TOPLEFT", dialog, "TOPLEFT", 24, -72)
	end
	allRow:Show()
	local lastAnchor = allRow
	local selectedCount = 0
	for index, option in ipairs(options) do
		local row = ensureCopySectionCheckbox(dialog, index)
		row.sectionId = option.value
		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", lastAnchor, "BOTTOMLEFT", 0, -2)
		row.Label:SetText(option.label or option.value)
		local checked = payload.sectionSelection[option.value] == true
		row:SetChecked(checked)
		if checked then selectedCount = selectedCount + 1 end
		row:SetScript("OnClick", function(self)
			local popup = self:GetParent()
			local popupPayload = popup and popup.data
			if not popupPayload then return end
			ensureCopySectionSelection(popupPayload)
			popupPayload.sectionSelection[self.sectionId] = self:GetChecked() == true
			if popup.eqolRefreshCopySelection then popup:eqolRefreshCopySelection() end
		end)
		row:Show()
		lastAnchor = row
	end
	local rows = dialog.eqolCopySectionRows or {}
	for index = #options + 1, #rows do
		local row = rows[index]
		if row then row:Hide() end
	end
	local allSelected = #options > 0 and selectedCount == #options
	allRow:SetChecked(allSelected)
	if dialog.button1 and dialog.button1.SetEnabled then dialog.button1:SetEnabled(selectedCount > 0) end
end

local function isPlayerScopedFrameVisibilityRule(key)
	return key == "PLAYER_CASTING"
		or key == "PLAYER_MOUNTED"
		or key == "PLAYER_NOT_MOUNTED"
		or key == "PLAYER_HAS_FOCUS"
		or key == "PLAYER_HAS_TARGET"
		or key == "PLAYER_IN_GROUP"
		or key == "PLAYER_IN_PARTY"
		or key == "PLAYER_IN_RAID"
		or key == "SKYRIDING_ACTIVE"
		or key == "SKYRIDING_INACTIVE"
		or key == "FLYING_ACTIVE"
		or key == "FLYING_INACTIVE"
end

local function supportsPlayerScopedFrameVisibility(unitToken) return unitToken == "player" or unitToken == "target" or unitToken == "targettarget" or unitToken == "focus" or unitToken == "pet" end

local function getVisibilityRuleOptions(unit)
	if not GetVisibilityRuleMetadata then return {} end
	local options = {}
	local unitToken = unit
	for key, data in pairs(GetVisibilityRuleMetadata() or {}) do
		local allowed = data.appliesTo and data.appliesTo.frame
		if allowed and data.unitRequirement and data.unitRequirement ~= unitToken then
			if data.unitRequirement == "player" and isPlayerScopedFrameVisibilityRule(key) and supportsPlayerScopedFrameVisibility(unitToken) then
				allowed = true
			else
				allowed = false
			end
		end
		if allowed then options[#options + 1] = { value = key, label = data.label or key, order = data.order or 999 } end
	end
	table.sort(options, function(a, b)
		if a.order == b.order then return tostring(a.label) < tostring(b.label) end
		return a.order < b.order
	end)
	return options
end
UF.ui.getVisibilityRuleOptions = getVisibilityRuleOptions

local function showCopySettingsPopup(fromUnit, toUnit)
	if not (fromUnit and toUnit and UF.CopySettings) then return end
	local sectionOptions = getCopySectionOptions(fromUnit, toUnit)
	if #sectionOptions == 0 then
		if UF.CopySettings(fromUnit, toUnit, { keepAnchor = true, keepEnabled = true }) then
			refresh(toUnit)
			refreshSettingsUI()
		end
		return
	end
	StaticPopupDialogs[copyDialogKey] = StaticPopupDialogs[copyDialogKey]
		or {
			text = "%s",
			button1 = L["Copy"] or ACCEPT,
			button2 = CANCEL,
			hideOnEscape = true,
			timeout = 0,
			whileDead = 1,
			preferredIndex = 3,
			OnAccept = function(self, data)
				local payload = data or self.data
				if payload and payload.from and payload.to and UF.CopySettings then
					local selected = getSelectedCopySections(payload)
					if #selected == 0 then return end
					local copyOptions = { keepAnchor = true, keepEnabled = true }
					if #selected < #(payload.sectionOptions or {}) then copyOptions.sections = selected end
					if UF.CopySettings(payload.from, payload.to, copyOptions) then
						refresh(payload.to)
						refreshSettingsUI()
					end
				end
			end,
			OnShow = function(self, data)
				self.data = data or self.data
				ensureCopySectionSelection(self.data or {})
				if not self.eqolRefreshCopySelection then self.eqolRefreshCopySelection = refreshCopySelectionDialog end
				self:eqolRefreshCopySelection()
			end,
			OnHide = function(self)
				if self.eqolCopyAllRow then self.eqolCopyAllRow:Hide() end
				if self.eqolCopySectionRows then
					for _, row in ipairs(self.eqolCopySectionRows) do
						if row then row:Hide() end
					end
				end
			end,
		}
	local dialog = StaticPopupDialogs[copyDialogKey]
	if not dialog then return end
	local fromLabel = copyFrameLabels[fromUnit] or fromUnit
	local toLabel = copyFrameLabels[toUnit] or toUnit
	dialog.text = string.format("%s\n%s -> %s", L["Copy settings"] or "Copy settings", fromLabel, toLabel)
	StaticPopup_Show(copyDialogKey, nil, nil, {
		from = fromUnit,
		to = toUnit,
		sectionOptions = sectionOptions,
		sectionSelection = {},
	})
end

local function hideFrameReset(frame)
	local lib = addon.EditModeLib
	if frame and lib and lib.SetFrameSettingsResetVisible then lib:SetFrameSettingsResetVisible(frame, false) end
end

local function getCachedLSMMedia(mediaType)
	local names = addon.functions and addon.functions.GetLSMMediaNames and addon.functions.GetLSMMediaNames(mediaType)
	local hash = addon.functions and addon.functions.GetLSMMediaHash and addon.functions.GetLSMMediaHash(mediaType)
	if type(names) == "table" and type(hash) == "table" then return names, hash end
	return {}, {}
end

function fontOptions()
	local list = {}
	local defaultPath = defaultFontPath()
	local globalOption = { value = globalFontConfigKey(), label = globalFontConfigLabel() }
	local names, hash = getCachedLSMMedia("font")
	local hasDefault = false
	for i = 1, #names do
		local name = names[i]
		local path = hash[name]
		if type(path) == "string" and path ~= "" then list[#list + 1] = { value = path, label = tostring(name) } end
		if path == defaultPath then hasDefault = true end
	end
	if defaultPath and not hasDefault then list[#list + 1] = { value = defaultPath, label = DEFAULT } end
	table.insert(list, 1, globalOption)
	return list
end

local function textureOptions()
	local list = {}
	local seen = {}
	local function add(value, label)
		local lv = tostring(value or ""):lower()
		if lv == "" or seen[lv] then return end
		seen[lv] = true
		list[#list + 1] = { value = value, label = label }
	end
	add("DEFAULT", "Default (Blizzard)")
	add("SOLID", "Solid")
	if UFHelper and UFHelper.BLIZZARD_RAID_FRAME_TEX_KEY then add(UFHelper.BLIZZARD_RAID_FRAME_TEX_KEY, L["Blizzard Raid Frame"] or "Blizzard Raid Frame") end
	local names, hash = getCachedLSMMedia("statusbar")
	for i = 1, #names do
		local name = names[i]
		local path = hash[name]
		if type(path) == "string" and path ~= "" then add(name, tostring(name)) end
	end
	table.sort(list, function(a, b) return tostring(a.label) < tostring(b.label) end)
	return list
end
UF.ui.textureOptions = textureOptions

function borderOptions(shape)
	local names, hash = getCachedLSMMedia("border")
	if addon.IconShape and addon.IconShape.GetBorderOptions then
		return addon.IconShape.GetBorderOptions(L, shape, {
			defaultOptions = {
				{ value = "DEFAULT", label = DEFAULT },
				{ value = "SOLID", label = "Solid" },
			},
			lsmNames = names,
			lsmHash = hash,
			includeNone = true,
			noneLabel = _G.NONE or "None",
			sort = true,
		})
	end
	local list = {}
	local seen = {}
	local function add(value, label)
		local lv = tostring(value or ""):lower()
		if lv == "" or seen[lv] then return end
		seen[lv] = true
		list[#list + 1] = { value = value, label = label }
	end
	add("DEFAULT", DEFAULT)
	add("SOLID", "Solid")
	for i = 1, #names do
		local name = names[i]
		local path = hash[name]
		if type(path) == "string" and path ~= "" then add(name, tostring(name)) end
	end
	table.sort(list, function(a, b) return tostring(a.label) < tostring(b.label) end)
	return list
end

function iconShapeOptions()
	if addon.IconShape and addon.IconShape.GetOptions then return addon.IconShape.GetOptions(L) end
		return {
			{ value = "DEFAULT", label = L["settingsIconShapeDefault"] or DEFAULT or "Default" },
			{ value = "SQUARE", label = L["settingsIconShapeSquare"] or "Square" },
			{ value = "ROUND", label = L["settingsIconShapeRound"] or "Round" },
			{ value = "ROUND_STAR", label = L["settingsIconShapeRoundStar"] or "Round star" },
			{ value = "HEXAGON", label = L["settingsIconShapeHexagon"] or "Hexagon" },
			{ value = "DIAMOND", label = L["settingsIconShapeDiamond"] or "Diamond" },
		}
end

function radioDropdown(name, options, getter, setter, default, parentId)
	return {
		name = name,
		kind = UF.ui.settingType.Dropdown,
		height = 180,
		parentId = parentId,
		default = default,
		generator = function(_, root)
			local opts = type(options) == "function" and options() or options
			if type(opts) ~= "table" then return end
			for _, opt in ipairs(opts) do
				local value = opt.value
				local label = opt.label
				root:CreateRadio(label, function() return getter() == value end, function() setter(value) end)
			end
		end,
	}
end

function checkboxDropdown(name, options, getter, setter, default, parentId)
	return {
		name = name,
		kind = UF.ui.settingType.Dropdown,
		height = 180,
		parentId = parentId,
		default = default,
		generator = function(_, root)
			local opts = type(options) == "function" and options() or options
			if type(opts) ~= "table" then return end
			for _, opt in ipairs(opts) do
				local value = opt.value
				local label = opt.label
				root:CreateCheckbox(label, function() return getter() == value end, function()
					if getter() ~= value then setter(value) end
				end)
			end
		end,
	}
end

local function appendBossLayoutSettings(list, unit, def, refreshSelf)
	list[#list + 1] = { name = L["Layout"] or "Layout", kind = UF.ui.settingType.Collapsible, id = "layout", defaultCollapsed = true }
	local bossCountOptions = {}
	for i = 1, maxBossFrames do
		bossCountOptions[#bossCountOptions + 1] = { value = i, label = tostring(i) }
	end
	list[#list + 1] = radioDropdown(
		L["Boss frame count"] or "Boss frame count",
		bossCountOptions,
		function() return clampBossFrameCount(getValue(unit, { "bossCount" }, def.bossCount or defaultBossFrames)) end,
		function(val)
			setValue(unit, { "bossCount" }, clampBossFrameCount(val))
			refreshSelf(true)
		end,
		clampBossFrameCount(def.bossCount or defaultBossFrames),
		"layout"
	)

	list[#list + 1] = slider(L["UFBossSpacing"] or "Boss spacing", bossSpacingMin, 100, 1, function() return getValue(unit, { "spacing" }, def.spacing or 4) end, function(val)
		setValue(unit, { "spacing" }, val or def.spacing or 4)
		refreshSelf()
	end, def.spacing or 4, "layout", true)

	local growthOpts = {
		{ value = "DOWN", label = DIRECTION_DOWN_LABEL },
		{ value = "UP", label = DIRECTION_UP_LABEL },
		{ value = "RIGHT", label = DIRECTION_RIGHT_LABEL },
		{ value = "LEFT", label = DIRECTION_LEFT_LABEL },
	}
	list[#list + 1] = radioDropdown(L["Growth direction"] or "Growth direction", growthOpts, function() return (getValue(unit, { "growth" }, def.growth or "DOWN") or "DOWN"):upper() end, function(val)
		setValue(unit, { "growth" }, (val or "DOWN"):upper())
		refreshSelf()
	end, (def.growth or "DOWN"):upper(), "layout")
end
UF.ui.appendBossLayoutSettings = appendBossLayoutSettings

local function multiDropdown(name, options, isSelected, setSelected, default, parentId, isEnabled)
	return {
		name = name,
		kind = UF.ui.settingType.Dropdown,
		height = 200,
		parentId = parentId,
		default = default,
		generator = function(_, root)
			local opts = type(options) == "function" and options() or options
			if type(opts) ~= "table" then return end
			for _, opt in ipairs(opts) do
				local value = opt.value
				local label = opt.label
				root:CreateCheckbox(label, function() return isSelected(value) end, function() setSelected(value, not isSelected(value)) end)
			end
		end,
		isEnabled = isEnabled,
	}
end
UF.ui.multiDropdown = multiDropdown

function slider(name, minVal, maxVal, step, getter, setter, default, parentId, allowInput, formatter)
	return {
		name = name,
		kind = UF.ui.settingType.Slider,
		parentId = parentId,
		minValue = minVal,
		maxValue = maxVal,
		valueStep = step,
		allowInput = allowInput,
		default = default,
		get = function() return getter() end,
		set = function(_, value) setter(value) end,
		formatter = formatter,
	}
end

function checkbox(name, getter, setter, default, parentId, isEnabled)
	return {
		name = name,
		kind = UF.ui.settingType.Checkbox,
		parentId = parentId,
		default = default,
		get = function() return getter() end,
		set = function(_, value) setter(value) end,
		isEnabled = isEnabled,
	}
end

local function checkboxColor(args)
	return {
		name = args.name,
		kind = UF.ui.settingType.CheckboxColor,
		parentId = args.parentId,
		default = args.defaultChecked,
		get = function() return args.isChecked() end,
		set = function(_, value) args.onChecked(value) end,
		colorDefault = args.colorDefault,
		colorGet = function()
			local r, g, b, a = args.getColor()
			return { r = r, g = g, b = b, a = a }
		end,
		colorSet = function(_, value) args.onColor(value) end,
		hasOpacity = true,
	}
end
UF.ui.checkboxColor = checkboxColor

local function setRangeFadeSpecSpell(unit, specId, kind, value)
	local cfg = ensureConfig(unit)
	cfg.rangeFade = cfg.rangeFade or {}
	if type(cfg.rangeFade.specSpells) ~= "table" then cfg.rangeFade.specSpells = {} end
	local specKey = tonumber(specId)
	if not specKey or specKey <= 0 then return end
	local entry = cfg.rangeFade.specSpells[specKey]
	if type(entry) ~= "table" then
		entry = {}
		cfg.rangeFade.specSpells[specKey] = entry
	end

	if value == "NONE" then
		entry[kind] = false
	elseif value == "DEFAULT" then
		entry[kind] = nil
	else
		local spellId = tonumber(value)
		if spellId and spellId > 0 then
			entry[kind] = math.floor(spellId)
		else
			entry[kind] = nil
		end
	end

	if entry.friendly == nil and entry.enemy == nil then cfg.rangeFade.specSpells[specKey] = nil end
	if not next(cfg.rangeFade.specSpells) then cfg.rangeFade.specSpells = nil end
end

local function getRangeFadeSpecSpellState(unit, specId, kind)
	local cfg = ensureConfig(unit)
	local rangeCfg = cfg and cfg.rangeFade or nil
	local specKey = tonumber(specId)
	local stored
	if rangeCfg and type(rangeCfg.specSpells) == "table" and specKey then
		local entry = rangeCfg.specSpells[specKey]
		if type(entry) == "table" then stored = entry[kind] end
	end

	local resolvedFriendly, resolvedEnemy
	if UFHelper and UFHelper.RangeFadeResolveSpellPair then
		resolvedFriendly, resolvedEnemy = UFHelper.RangeFadeResolveSpellPair(rangeCfg, specKey)
	end
	local resolved = (kind == "friendly") and resolvedFriendly or resolvedEnemy
	if stored == false or stored == 0 or stored == "0" then return "none", nil end
	if tonumber(stored) and tonumber(stored) > 0 then return "custom", math.floor(tonumber(stored)) end
	if resolved and tonumber(resolved) and tonumber(resolved) > 0 then return "default", math.floor(tonumber(resolved)) end
	return "default", nil
end

local function getRangeFadeSpellDisplay(unit, specId, kind)
	local mode, spellId = getRangeFadeSpecSpellState(unit, specId, kind)
	if mode == "none" then return NONE end
	if spellId and UFHelper and UFHelper.RangeFadeGetSpellLabel then return UFHelper.RangeFadeGetSpellLabel(spellId, false) or tostring(spellId) end
	if mode == "default" then return L["UFRangeFadeDefaultNone"] or "Default (none)" end
	return NONE
end

local function createRangeFadeSpellPickerSetting(unit, isRangeFadeEnabled, refreshSelf, refreshRangeFadeRuntime)
	return {
		name = L["UFRangeFadeSpells"] or "Range check spells",
		kind = UF.ui.settingType.Dropdown,
		height = 300,
		parentId = "rangeFade",
		default = nil,
		generator = function(_, root)
			local specOptions = (UFHelper and UFHelper.RangeFadeGetSpecOptions and UFHelper.RangeFadeGetSpecOptions()) or {}
			local friendlyLabel = L["UFRangeFadeFriendlySpell"] or "Friendly spell"
			local enemyLabel = L["UFRangeFadeEnemySpell"] or "Enemy spell"
			local defaultLabel = L["Default"] or "Default"
			local defaultNoneLabel = L["UFRangeFadeDefaultNone"] or "Default (none)"
			local noneLabel = NONE
			if #specOptions == 0 then
				root:CreateButton(noneLabel)
				return
			end

			local function buildSpellMenu(parent, specId, kind, options)
				if parent and parent.SetScrollMode then parent:SetScrollMode(280) end
				local mode, currentSpellId = getRangeFadeSpecSpellState(unit, specId, kind)
				local modeDefault = mode == "default"
				local modeNone = mode == "none"
				parent:CreateRadio(defaultLabel, function() return modeDefault end, function()
					setRangeFadeSpecSpell(unit, specId, kind, "DEFAULT")
					refreshRangeFadeRuntime(true, false)
					refreshSelf()
					refreshSettingsUI()
				end)
				parent:CreateRadio(noneLabel, function() return modeNone end, function()
					setRangeFadeSpecSpell(unit, specId, kind, "NONE")
					refreshRangeFadeRuntime(true, false)
					refreshSelf()
					refreshSettingsUI()
				end)
				local defaultFriendly, defaultEnemy = nil, nil
				if UFHelper and UFHelper.RangeFadeGetDefaultSpellPair then
					defaultFriendly, defaultEnemy = UFHelper.RangeFadeGetDefaultSpellPair(specId)
				end
				local defaultSpellId = kind == "friendly" and defaultFriendly or defaultEnemy
				if defaultSpellId and UFHelper and UFHelper.RangeFadeGetSpellLabel then
					parent:CreateButton(string.format("%s: %s", defaultLabel, UFHelper.RangeFadeGetSpellLabel(defaultSpellId, true) or tostring(defaultSpellId)))
				elseif defaultSpellId == nil then
					parent:CreateButton(defaultNoneLabel)
				end
				for i = 1, #options do
					local option = options[i]
					local spellId = option and option.value
					if spellId then
						parent:CreateRadio(option.label, function() return mode == "custom" and currentSpellId == spellId end, function()
							setRangeFadeSpecSpell(unit, specId, kind, spellId)
							refreshRangeFadeRuntime(true, false)
							refreshSelf()
							refreshSettingsUI()
						end)
					end
				end
			end

			for i = 1, #specOptions do
				local specEntry = specOptions[i]
				local specId = specEntry and specEntry.value
				if specId then
					local classToken = specEntry.classToken
					local friendlyOptions = (UFHelper and UFHelper.RangeFadeGetSpellOptions and UFHelper.RangeFadeGetSpellOptions("friendly", classToken)) or {}
					local enemyOptions = (UFHelper and UFHelper.RangeFadeGetSpellOptions and UFHelper.RangeFadeGetSpellOptions("enemy", classToken)) or {}
					local specMenu = root:CreateButton(specEntry.label or ("Spec " .. tostring(specId)))
					if specMenu and specMenu.SetScrollMode then specMenu:SetScrollMode(220) end
					local friendlyMenu = specMenu:CreateButton(string.format("%s: %s", friendlyLabel, getRangeFadeSpellDisplay(unit, specId, "friendly")))
					local enemyMenu = specMenu:CreateButton(string.format("%s: %s", enemyLabel, getRangeFadeSpellDisplay(unit, specId, "enemy")))
					buildSpellMenu(friendlyMenu, specId, "friendly", friendlyOptions)
					buildSpellMenu(enemyMenu, specId, "enemy", enemyOptions)
				end
			end
		end,
		isEnabled = isRangeFadeEnabled,
	}
end

local function anchorUsesUIParent(unit) return not (UF.IsDynamicAnchorEnabled and UF.IsDynamicAnchorEnabled(unit)) and UnitAnchor.GetTargetValue(unit) == "UIParent" end

local function calcLayout(unit, frame)
	local cfg = ensureConfig(unit)
	local def = defaultsFor(unit)
	local anchor = cfg.anchor or def.anchor or {}
	local pcfg = cfg.power or {}
	local powerDef = def.power or {}
	local powerEnabled = getValue(unit, { "power", "enabled" }, powerDef.enabled ~= false)
	if unit == "player" and powerEnabled and UFHelper and UFHelper.IsPrimaryPowerAllowed and UnitPowerType then
		local enumId, token = UnitPowerType("player")
		powerEnabled = UFHelper.IsPrimaryPowerAllowed(pcfg, powerDef, token, enumId, "player") ~= false
	end
	local powerDetached = powerEnabled and pcfg.detached == true
	local secondaryDef = def.secondaryPower or {}
	local secondaryCfg = cfg.secondaryPower or {}
	local secondaryToken
	if unit == "player" and UFHelper and UFHelper.ResolveSecondaryPowerToken then
		secondaryToken = UFHelper.ResolveSecondaryPowerToken(secondaryCfg, secondaryDef, addon.variables and addon.variables.unitClass, addon.variables and addon.variables.unitSpec)
	end
	local secondaryPowerEnabled = unit == "player" and getValue(unit, { "secondaryPower", "enabled" }, secondaryDef.enabled == true) ~= false and secondaryToken ~= nil
	local secondaryPowerDetached = secondaryPowerEnabled and secondaryCfg.detached == true
	local statusUnit = unit == "boss" and "boss1" or unit
	local showStatus = UF.ShouldShowStatusLayout and UF.ShouldShowStatusLayout(cfg, statusUnit, def)
	local statusHeight = UF.ResolveStatusHeight and UF.ResolveStatusHeight(cfg, def, showStatus) or 0
	local statusHeightDelta = unit ~= "boss" and UF.GetStatusHeightDelta and UF.GetStatusHeightDelta(showStatus) or 0
	local borderOffset = 0
	if cfg.border and cfg.border.enabled then
		borderOffset = cfg.border.offset
		if borderOffset == nil then borderOffset = cfg.border.edgeSize or 1 end
		borderOffset = math.max(0, borderOffset or 0)
		if UF.ResolveBorderLayoutOffset then borderOffset = UF.ResolveBorderLayoutOffset(frame, borderOffset) end
	end

	local portraitDef = def.portrait or {}
	local portraitCfg = cfg.portrait or {}
	local portraitEnabled = portraitCfg.enabled
	if portraitEnabled == nil then portraitEnabled = portraitDef.enabled end
	portraitEnabled = portraitEnabled == true

	local healthHeight = cfg.healthHeight or def.healthHeight or 24
	local powerHeight = powerEnabled and (cfg.powerHeight or def.powerHeight or 16) or 0
	local secondaryPowerHeight = secondaryPowerEnabled and (cfg.secondaryPowerHeight or def.secondaryPowerHeight or cfg.powerHeight or def.powerHeight or 16) or 0
	if UF.ResolvePixelLayoutSize then
		healthHeight = UF.ResolvePixelLayoutSize(frame, healthHeight)
		powerHeight = UF.ResolvePixelLayoutSize(frame, powerHeight)
		secondaryPowerHeight = UF.ResolvePixelLayoutSize(frame, secondaryPowerHeight)
	end
	local stackHeight = healthHeight + (powerDetached and 0 or powerHeight) + (secondaryPowerDetached and 0 or secondaryPowerHeight)
	local portraitInnerHeight = stackHeight
	local portraitSize = portraitEnabled and math.max(1, portraitInnerHeight) or 0

	local separatorEnabled = false
	local separatorSize = 0
	if portraitEnabled and cfg.enabled ~= false then
		local borderCfg = cfg.border or {}
		if borderCfg.enabled == true then
			local sdef = portraitDef.separator or {}
			local scfg = portraitCfg.separator or {}
			local enabled = scfg.enabled
			if enabled == nil then enabled = sdef.enabled end
			if enabled == nil then enabled = true end
			if enabled == true then
				local size = scfg.size
				if size == nil then size = sdef.size end
				if not size or size <= 0 then size = borderCfg.edgeSize or 1 end
				separatorEnabled = true
				separatorSize = math.max(1, size or 1)
				if UF.ResolvePixelLayoutSize then separatorSize = UF.ResolvePixelLayoutSize(frame, separatorSize) end
			end
		end
	end

	local portraitSpace = portraitEnabled and (portraitSize + (separatorEnabled and separatorSize or 0)) or 0
	local contentWidth = cfg.width or def.width or frame:GetWidth() or 200
	if UF.ResolvePixelLayoutSize then contentWidth = UF.ResolvePixelLayoutSize(frame, contentWidth) end
	local width = contentWidth + borderOffset * 2 + portraitSpace
	if UF.ResolvePixelLayoutSize then width = UF.ResolvePixelLayoutSize(frame, width) end
	local point = anchor.point or "CENTER"
	local relativePoint = anchor.relativePoint or point
	local relativeName = anchor.relativeTo or anchor.relativeFrame
	local ownerFrameName = UF.GetAnchorFrameName and UF.GetAnchorFrameName(unit) or nil
	local relativeFrame = UF.ResolveRelativeAnchorFrame and UF.ResolveRelativeAnchorFrame(relativeName, ownerFrameName) or UIParent
	local physicalY = UF.ResolvePhysicalUnitFrameAnchorY and UF.ResolvePhysicalUnitFrameAnchorY(point, relativePoint, anchor.y, relativeFrame, statusHeightDelta) or anchor.y or 0
	local height = statusHeight + stackHeight + borderOffset * 2
	return {
		point = point,
		relativePoint = relativePoint,
		x = anchor.x or 0,
		y = physicalY,
		width = width,
		height = height,
	}
end

local function appendSecondaryPowerSettings(list, unit, def, textureOpts, addDivider, refresh, refreshSelf)
	if unit ~= "player" then return end
	list[#list + 1] = { name = (_G.SECONDARY or "Secondary") .. " " .. (L["PowerBar"] or "Power Bar"), kind = UF.ui.settingType.Collapsible, id = "secondaryPower", defaultCollapsed = true }
	local secondaryDef = def.secondaryPower or {}
	local defaultSecondaryAllowedTypes = (UFHelper and UFHelper.GetDefaultSecondaryPowerAllowedTypes and UFHelper.GetDefaultSecondaryPowerAllowedTypes())
		or {
			MANA = true,
			STAGGER = true,
			VOID_METAMORPHOSIS = true,
		}
	local function normalizeSecondaryTypeToken(token)
		if type(token) ~= "string" then return nil end
		local normalized = string.upper(token)
		if normalized == "" or normalized == "NONE" then return nil end
		return normalized
	end
	local function resolveSecondaryAllowedForDisplay()
		local cfgAllowed = getValue(unit, { "secondaryPower", "allowedTypes" }, nil)
		if type(cfgAllowed) == "table" then return cfgAllowed end
		local defAllowed = secondaryDef.allowedTypes
		if type(defAllowed) == "table" then return defAllowed end
		return defaultSecondaryAllowedTypes
	end
	local function isSecondaryAllowedTypeSelected(token)
		local normalized = normalizeSecondaryTypeToken(token)
		if not normalized then return false end
		local allowed = resolveSecondaryAllowedForDisplay()
		return type(allowed) == "table" and allowed[normalized] == true
	end
	local function setSecondaryAllowedType(token, enabled)
		local normalized = normalizeSecondaryTypeToken(token)
		if not normalized then return end
		local source = resolveSecondaryAllowedForDisplay()
		local allowed = {}
		if type(source) == "table" then
			for key, isAllowed in pairs(source) do
				if isAllowed == true then allowed[key] = true end
			end
		end
		if enabled then
			allowed[normalized] = true
		else
			allowed[normalized] = nil
		end
		setValue(unit, { "secondaryPower", "allowedTypes" }, allowed)
		refreshSelf()
		refreshSettingsUI()
	end
	local function isSecondaryPowerEnabled() return getValue(unit, { "secondaryPower", "enabled" }, secondaryDef.enabled == true) ~= false end
	local function isSecondaryPowerDetached() return getValue(unit, { "secondaryPower", "detached" }, secondaryDef.detached == true) == true end
	local function isSecondaryPowerDetachedEnabled() return isSecondaryPowerEnabled() and isSecondaryPowerDetached() end
	local function isSecondaryStaggerAllowed() return isSecondaryAllowedTypeSelected("STAGGER") end
	local function isSecondaryStaggerSettingsShown() return isSecondaryPowerEnabled() and isSecondaryStaggerAllowed() end
	local function isSecondaryStaggerExtendedEnabled() return getValue(unit, { "secondaryPower", "staggerHighColors" }, secondaryDef.staggerHighColors == true) == true end
	local function isDetachedSecondaryWidthMatched() return getValue(unit, { "secondaryPower", "detachedMatchHealthWidth" }, secondaryDef.detachedMatchHealthWidth == true) == true end
	local function isDetachedSecondaryBorderEnabled()
		local border = getValue(unit, { "border" }, def.border or {})
		return isSecondaryPowerDetachedEnabled() and border.detachedSecondaryPower == true
	end
	local detachedStrataOptions = { { value = "", label = DEFAULT } }
	for i = 1, #UF.ui.strataOptions do
		detachedStrataOptions[#detachedStrataOptions + 1] = UF.ui.strataOptions[i]
	end

	list[#list + 1] = checkbox(L["Show power bar"] or "Show power bar", isSecondaryPowerEnabled, function(val)
		setValue(unit, { "secondaryPower", "enabled" }, val and true or false)
		refreshSelf()
		refreshSettingsUI()
	end, secondaryDef.enabled == true, "secondaryPower")

	local secondaryType = multiDropdown(TYPE or "Type", getSecondaryPowerTokenOptions, isSecondaryAllowedTypeSelected, setSecondaryAllowedType, nil, "secondaryPower")
	secondaryType.isEnabled = isSecondaryPowerEnabled
	list[#list + 1] = secondaryType

	local secondaryDetachedSetting = checkbox(L["UFPowerDetached"] or "Detach power bar", isSecondaryPowerDetached, function(val)
		setValue(unit, { "secondaryPower", "detached" }, val and true or false)
		refresh()
		refreshSettingsUI()
	end, secondaryDef.detached == true, "secondaryPower", isSecondaryPowerEnabled)
	list[#list + 1] = secondaryDetachedSetting
	addDivider("secondaryPower", isSecondaryPowerDetachedEnabled)

	local secondaryEmptyFallbackSetting = checkbox(
		L["UFPowerEmptyFallback"] or "Handle empty power bars (max 0)",
		function() return getValue(unit, { "secondaryPower", "emptyMaxFallback" }, secondaryDef.emptyMaxFallback == true) == true end,
		function(val)
			setValue(unit, { "secondaryPower", "emptyMaxFallback" }, val and true or false)
			refresh()
		end,
		secondaryDef.emptyMaxFallback == true,
		"secondaryPower",
		isSecondaryPowerEnabled
	)
	secondaryEmptyFallbackSetting.isEnabled = isSecondaryPowerDetachedEnabled
	secondaryEmptyFallbackSetting.isShown = isSecondaryPowerDetachedEnabled
	list[#list + 1] = secondaryEmptyFallbackSetting

	local secondaryMatchWidthSetting = checkbox(L["UFPowerDetachedMatchHealthWidth"] or "Match health width", isDetachedSecondaryWidthMatched, function(val)
		setValue(unit, { "secondaryPower", "detachedMatchHealthWidth" }, val and true or false)
		refresh()
		refreshSettingsUI()
	end, secondaryDef.detachedMatchHealthWidth == true, "secondaryPower", isSecondaryPowerDetachedEnabled)
	secondaryMatchWidthSetting.isEnabled = isSecondaryPowerDetachedEnabled
	secondaryMatchWidthSetting.isShown = isSecondaryPowerDetachedEnabled
	list[#list + 1] = secondaryMatchWidthSetting

	local secondaryWidthSetting = slider(L["UFPowerWidth"] or "Power width", MIN_WIDTH, 800, 1, function()
		local fallback = getValue(unit, { "width" }, def.width or MIN_WIDTH)
		return getValue(unit, { "secondaryPower", "width" }, fallback)
	end, function(val)
		debounced(unit .. "_secondaryPowerWidth", function()
			setValue(unit, { "secondaryPower", "width" }, math.max(MIN_WIDTH, val or MIN_WIDTH))
			refresh()
		end)
	end, def.width or MIN_WIDTH, "secondaryPower", true)
	secondaryWidthSetting.isEnabled = function() return isSecondaryPowerDetachedEnabled() and not isDetachedSecondaryWidthMatched() end
	secondaryWidthSetting.isShown = isSecondaryPowerDetachedEnabled
	list[#list + 1] = secondaryWidthSetting

	local secondaryGrowFromCenterSetting = checkbox(
		L["Grow from center"] or "Grow from center",
		function() return getValue(unit, { "secondaryPower", "detachedGrowFromCenter" }, secondaryDef.detachedGrowFromCenter == true) == true end,
		function(val)
			setValue(unit, { "secondaryPower", "detachedGrowFromCenter" }, val and true or false)
			refresh()
		end,
		secondaryDef.detachedGrowFromCenter == true,
		"secondaryPower",
		isSecondaryPowerDetachedEnabled
	)
	secondaryGrowFromCenterSetting.isEnabled = isSecondaryPowerDetachedEnabled
	secondaryGrowFromCenterSetting.isShown = isSecondaryPowerDetachedEnabled
	list[#list + 1] = secondaryGrowFromCenterSetting

	local secondaryOffsetX = slider(L["Offset X"] or "Offset X", -OFFSET_RANGE, OFFSET_RANGE, 1, function() return getValue(unit, { "secondaryPower", "offset", "x" }, 0) end, function(val)
		debounced(unit .. "_secondaryPowerOffsetX", function()
			setValue(unit, { "secondaryPower", "offset", "x" }, val or 0)
			refresh()
		end)
	end, 0, "secondaryPower", true)
	secondaryOffsetX.isEnabled = isSecondaryPowerDetachedEnabled
	secondaryOffsetX.isShown = isSecondaryPowerDetachedEnabled
	list[#list + 1] = secondaryOffsetX

	local secondaryOffsetY = slider(L["Offset Y"] or "Offset Y", -OFFSET_RANGE, OFFSET_RANGE, 1, function() return getValue(unit, { "secondaryPower", "offset", "y" }, 0) end, function(val)
		debounced(unit .. "_secondaryPowerOffsetY", function()
			setValue(unit, { "secondaryPower", "offset", "y" }, val or 0)
			refresh()
		end)
	end, 0, "secondaryPower", true)
	secondaryOffsetY.isEnabled = isSecondaryPowerDetachedEnabled
	secondaryOffsetY.isShown = isSecondaryPowerDetachedEnabled
	list[#list + 1] = secondaryOffsetY
	addDivider("secondaryPower", isSecondaryPowerDetachedEnabled)

	local detachedSecondaryStrata = radioDropdown(
		L["UFDetachedPowerStrata"] or "Strata",
		detachedStrataOptions,
		function() return getValue(unit, { "secondaryPower", "detachedStrata" }, secondaryDef.detachedStrata or "") end,
		function(val)
			if val == "" then val = nil end
			setValue(unit, { "secondaryPower", "detachedStrata" }, val)
			refresh()
		end,
		secondaryDef.detachedStrata or "",
		"secondaryPower",
		true
	)
	detachedSecondaryStrata.isEnabled = isSecondaryPowerDetachedEnabled
	detachedSecondaryStrata.isShown = isSecondaryPowerDetachedEnabled
	list[#list + 1] = detachedSecondaryStrata

	local detachedSecondaryLevelOffset = slider(
		L["UFDetachedPowerLevelOffset"] or "Frame level offset",
		0,
		50,
		1,
		function() return getValue(unit, { "secondaryPower", "detachedFrameLevelOffset" }, secondaryDef.detachedFrameLevelOffset or 5) end,
		function(val)
			debounced(unit .. "_detachedSecondaryPowerLevelOffset", function()
				setValue(unit, { "secondaryPower", "detachedFrameLevelOffset" }, val or secondaryDef.detachedFrameLevelOffset or 5)
				refresh()
			end)
		end,
		secondaryDef.detachedFrameLevelOffset or 5,
		"secondaryPower",
		true
	)
	detachedSecondaryLevelOffset.isEnabled = isSecondaryPowerDetachedEnabled
	detachedSecondaryLevelOffset.isShown = isSecondaryPowerDetachedEnabled
	list[#list + 1] = detachedSecondaryLevelOffset
	addDivider("secondaryPower", isSecondaryPowerDetachedEnabled)

	local detachedSecondaryBorderToggle = checkbox(
		L["Show border"] or "Show border",
		function() return getValue(unit, { "border", "detachedSecondaryPower" }, def.border and def.border.detachedSecondaryPower == true) == true end,
		function(val)
			local border = getValue(unit, { "border" }, def.border or {})
			border.detachedSecondaryPower = val and true or false
			setValue(unit, { "border" }, border)
			refresh()
			refreshSettingsUI()
		end,
		def.border and def.border.detachedSecondaryPower == true,
		"secondaryPower"
	)
	detachedSecondaryBorderToggle.isEnabled = isSecondaryPowerDetachedEnabled
	detachedSecondaryBorderToggle.isShown = isSecondaryPowerDetachedEnabled
	list[#list + 1] = detachedSecondaryBorderToggle

	local detachedSecondaryBorderTexture = checkboxDropdown(L["Border texture"] or "Border texture", borderOptions, function()
		local border = getValue(unit, { "border" }, def.border or {})
		return border.detachedSecondaryPowerTexture or border.texture or (def.border and def.border.texture) or "DEFAULT"
	end, function(val)
		local border = getValue(unit, { "border" }, def.border or {})
		border.detachedSecondaryPowerTexture = val or "DEFAULT"
		setValue(unit, { "border" }, border)
		refresh()
	end, (def.border and def.border.detachedSecondaryPowerTexture) or (def.border and def.border.texture) or "DEFAULT", "secondaryPower")
	detachedSecondaryBorderTexture.isEnabled = isDetachedSecondaryBorderEnabled
	detachedSecondaryBorderTexture.isShown = isSecondaryPowerDetachedEnabled
	list[#list + 1] = detachedSecondaryBorderTexture

	local detachedSecondaryBorderSize = slider(L["Border size"] or "Border size", 1, 64, 1, function()
		local border = getValue(unit, { "border" }, def.border or {})
		return border.detachedSecondaryPowerSize or border.edgeSize or 1
	end, function(val)
		debounced(unit .. "_detachedSecondaryPowerBorderSize", function()
			local border = getValue(unit, { "border" }, def.border or {})
			border.detachedSecondaryPowerSize = val or 1
			setValue(unit, { "border" }, border)
			refresh()
		end)
	end, (def.border and def.border.detachedSecondaryPowerSize) or (def.border and def.border.edgeSize) or 1, "secondaryPower", true)
	detachedSecondaryBorderSize.isEnabled = isDetachedSecondaryBorderEnabled
	detachedSecondaryBorderSize.isShown = isSecondaryPowerDetachedEnabled
	list[#list + 1] = detachedSecondaryBorderSize

	local detachedSecondaryBorderOffset = slider(L["Border offset"] or "Border offset", 0, 64, 1, function()
		local border = getValue(unit, { "border" }, def.border or {})
		if border.detachedSecondaryPowerOffset == nil then
			if border.offset ~= nil then return border.offset end
			return border.edgeSize or 1
		end
		return border.detachedSecondaryPowerOffset
	end, function(val)
		debounced(unit .. "_detachedSecondaryPowerBorderOffset", function()
			local border = getValue(unit, { "border" }, def.border or {})
			border.detachedSecondaryPowerOffset = val or 0
			setValue(unit, { "border" }, border)
			refresh()
		end)
	end, (def.border and def.border.detachedSecondaryPowerOffset) or (def.border and def.border.offset) or (def.border and def.border.edgeSize) or 1, "secondaryPower", true)
	detachedSecondaryBorderOffset.isEnabled = isDetachedSecondaryBorderEnabled
	detachedSecondaryBorderOffset.isShown = isSecondaryPowerDetachedEnabled
	list[#list + 1] = detachedSecondaryBorderOffset
	addDivider("secondaryPower", isSecondaryPowerDetachedEnabled)

	list[#list + 1] = checkbox(L["Reverse fill"] or "Reverse fill", function() return getValue(unit, { "secondaryPower", "reverseFill" }, secondaryDef.reverseFill == true) == true end, function(val)
		setValue(unit, { "secondaryPower", "reverseFill" }, val and true or false)
		refresh()
	end, secondaryDef.reverseFill == true, "secondaryPower", isSecondaryPowerEnabled)

	local secondaryPowerHeightSetting = slider(
		L["Power height"] or "Power height",
		1,
		60,
		1,
		function() return getValue(unit, { "secondaryPowerHeight" }, def.secondaryPowerHeight or def.powerHeight or 16) end,
		function(val)
			debounced(unit .. "_secondaryPowerHeight", function()
				setValue(unit, { "secondaryPowerHeight" }, val or def.secondaryPowerHeight or def.powerHeight or 16)
				refresh()
			end)
		end,
		def.secondaryPowerHeight or def.powerHeight or 16,
		"secondaryPower",
		true
	)
	secondaryPowerHeightSetting.isEnabled = isSecondaryPowerEnabled
	list[#list + 1] = secondaryPowerHeightSetting
	addDivider("secondaryPower")

	local secondaryTextLeft = radioDropdown(
		L["Left text"] or "Left text",
		textOptions,
		function() return normalizeTextMode(getValue(unit, { "secondaryPower", "textLeft" }, secondaryDef.textLeft or "PERCENT")) end,
		function(val)
			setValue(unit, { "secondaryPower", "textLeft" }, val)
			refreshSelf()
			refreshSettingsUI()
		end,
		secondaryDef.textLeft or "PERCENT",
		"secondaryPower"
	)
	secondaryTextLeft.isEnabled = isSecondaryPowerEnabled
	list[#list + 1] = secondaryTextLeft

	local secondaryTextCenter = radioDropdown(
		L["Center text"] or "Center text",
		textOptions,
		function() return normalizeTextMode(getValue(unit, { "secondaryPower", "textCenter" }, secondaryDef.textCenter or "NONE")) end,
		function(val)
			setValue(unit, { "secondaryPower", "textCenter" }, val)
			refreshSelf()
			refreshSettingsUI()
		end,
		secondaryDef.textCenter or "NONE",
		"secondaryPower"
	)
	secondaryTextCenter.isEnabled = isSecondaryPowerEnabled
	list[#list + 1] = secondaryTextCenter

	local secondaryTextRight = radioDropdown(
		L["Right text"] or "Right text",
		textOptions,
		function() return normalizeTextMode(getValue(unit, { "secondaryPower", "textRight" }, secondaryDef.textRight or "CURMAX")) end,
		function(val)
			setValue(unit, { "secondaryPower", "textRight" }, val)
			refreshSelf()
			refreshSettingsUI()
		end,
		secondaryDef.textRight or "CURMAX",
		"secondaryPower"
	)
	secondaryTextRight.isEnabled = isSecondaryPowerEnabled
	list[#list + 1] = secondaryTextRight

	local secondaryDelimiter = radioDropdown(
		L["Delimiter"] or "Delimiter",
		delimiterOptions,
		function() return getValue(unit, { "secondaryPower", "textDelimiter" }, secondaryDef.textDelimiter or " ") end,
		function(val)
			setValue(unit, { "secondaryPower", "textDelimiter" }, val)
			refreshSelf()
		end,
		secondaryDef.textDelimiter or " ",
		"secondaryPower"
	)
	local function secondaryDelimiterCount()
		local leftMode = getValue(unit, { "secondaryPower", "textLeft" }, secondaryDef.textLeft or "PERCENT")
		local centerMode = getValue(unit, { "secondaryPower", "textCenter" }, secondaryDef.textCenter or "NONE")
		local rightMode = getValue(unit, { "secondaryPower", "textRight" }, secondaryDef.textRight or "CURMAX")
		return maxDelimiterCount(leftMode, centerMode, rightMode)
	end
	secondaryDelimiter.isShown = function() return secondaryDelimiterCount() >= 1 end
	secondaryDelimiter.isEnabled = isSecondaryPowerEnabled
	list[#list + 1] = secondaryDelimiter

	local secondaryDelimiterSecondary = radioDropdown(L["Secondary Delimiter"] or "Secondary delimiter", delimiterOptions, function()
		local primary = getValue(unit, { "secondaryPower", "textDelimiter" }, secondaryDef.textDelimiter or " ")
		return getValue(unit, { "secondaryPower", "textDelimiterSecondary" }, primary)
	end, function(val)
		setValue(unit, { "secondaryPower", "textDelimiterSecondary" }, val)
		refreshSelf()
	end, secondaryDef.textDelimiterSecondary or secondaryDef.textDelimiter or " ", "secondaryPower")
	secondaryDelimiterSecondary.isShown = function() return secondaryDelimiterCount() >= 2 end
	secondaryDelimiterSecondary.isEnabled = isSecondaryPowerEnabled
	list[#list + 1] = secondaryDelimiterSecondary

	local secondaryDelimiterTertiary = radioDropdown(L["Tertiary Delimiter"] or "Tertiary delimiter", delimiterOptions, function()
		local primary = getValue(unit, { "secondaryPower", "textDelimiter" }, secondaryDef.textDelimiter or " ")
		local secondary = getValue(unit, { "secondaryPower", "textDelimiterSecondary" }, primary)
		return getValue(unit, { "secondaryPower", "textDelimiterTertiary" }, secondary)
	end, function(val)
		setValue(unit, { "secondaryPower", "textDelimiterTertiary" }, val)
		refreshSelf()
	end, secondaryDef.textDelimiterTertiary or secondaryDef.textDelimiterSecondary or secondaryDef.textDelimiter or " ", "secondaryPower")
	secondaryDelimiterTertiary.isShown = function() return secondaryDelimiterCount() >= 3 end
	secondaryDelimiterTertiary.isEnabled = isSecondaryPowerEnabled
	list[#list + 1] = secondaryDelimiterTertiary

	list[#list + 1] = checkbox(
		L["Hide % symbol"] or "Hide % symbol",
		function() return getValue(unit, { "secondaryPower", "hidePercentSymbol" }, secondaryDef.hidePercentSymbol == true) == true end,
		function(val)
			setValue(unit, { "secondaryPower", "hidePercentSymbol" }, val and true or false)
			refresh()
		end,
		secondaryDef.hidePercentSymbol == true,
		"secondaryPower",
		isSecondaryPowerEnabled
	)

	list[#list + 1] = checkbox(
		L["Round percent values"] or "Round percent values",
		function() return getValue(unit, { "secondaryPower", "roundPercent" }, secondaryDef.roundPercent == true) == true end,
		function(val)
			setValue(unit, { "secondaryPower", "roundPercent" }, val and true or false)
			refresh()
		end,
		secondaryDef.roundPercent == true,
		"secondaryPower",
		isSecondaryPowerEnabled
	)

	local secondaryFontSize = slider(FONT_SIZE_LABEL, 8, 30, 1, function() return getValue(unit, { "secondaryPower", "fontSize" }, secondaryDef.fontSize or 14) end, function(val)
		debounced(unit .. "_secondaryPowerFontSize", function()
			setValue(unit, { "secondaryPower", "fontSize" }, val or secondaryDef.fontSize or 14)
			refreshSelf()
		end)
	end, secondaryDef.fontSize or 14, "secondaryPower", true)
	secondaryFontSize.isEnabled = isSecondaryPowerEnabled
	list[#list + 1] = secondaryFontSize

	if #fontOptions() > 0 then
		local secondaryFont = checkboxDropdown(
			L["Font"] or "Font",
			fontOptions,
			function() return getValue(unit, { "secondaryPower", "font" }, secondaryDef.font or globalFontConfigKey()) end,
			function(val)
				setValue(unit, { "secondaryPower", "font" }, val)
				refreshSelf()
			end,
			secondaryDef.font or globalFontConfigKey(),
			"secondaryPower"
		)
		secondaryFont.isEnabled = isSecondaryPowerEnabled
		list[#list + 1] = secondaryFont
	end

	local secondaryFontOutline = checkboxDropdown(
		L["Font outline"] or "Font outline",
		outlineOptions,
		function()
			return normalizeFontStyleChoice(getValue(unit, { "secondaryPower", "fontOutline" }, secondaryDef.fontOutline or "OUTLINE"), secondaryDef.fontOutline or "OUTLINE")
		end,
		function(val)
			setValue(unit, { "secondaryPower", "fontOutline" }, normalizeFontStyleChoice(val, secondaryDef.fontOutline or "OUTLINE"))
			refresh()
		end,
		secondaryDef.fontOutline or "OUTLINE",
		"secondaryPower"
	)
	secondaryFontOutline.isEnabled = isSecondaryPowerEnabled
	list[#list + 1] = secondaryFontOutline

	local function showSecondaryTextOffsets(key, fallback)
		local mode = normalizeTextMode(getValue(unit, { "secondaryPower", key }, fallback))
		return mode ~= "NONE"
	end

	local secondaryLeftX = slider(
		L["TextLeftOffsetX"] or "Left text X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "secondaryPower", "offsetLeft", "x" }, (secondaryDef.offsetLeft and secondaryDef.offsetLeft.x) or 0) end,
		function(val)
			debounced(unit .. "_secondaryPowerLeftX", function()
				setValue(unit, { "secondaryPower", "offsetLeft", "x" }, val or 0)
				refresh()
			end)
		end,
		(secondaryDef.offsetLeft and secondaryDef.offsetLeft.x) or 0,
		"secondaryPower",
		true
	)
	secondaryLeftX.isEnabled = isSecondaryPowerEnabled
	secondaryLeftX.isShown = function() return showSecondaryTextOffsets("textLeft", secondaryDef.textLeft or "PERCENT") end
	list[#list + 1] = secondaryLeftX

	local secondaryLeftY = slider(
		L["TextLeftOffsetY"] or "Left text Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "secondaryPower", "offsetLeft", "y" }, (secondaryDef.offsetLeft and secondaryDef.offsetLeft.y) or 0) end,
		function(val)
			debounced(unit .. "_secondaryPowerLeftY", function()
				setValue(unit, { "secondaryPower", "offsetLeft", "y" }, val or 0)
				refresh()
			end)
		end,
		(secondaryDef.offsetLeft and secondaryDef.offsetLeft.y) or 0,
		"secondaryPower",
		true
	)
	secondaryLeftY.isEnabled = isSecondaryPowerEnabled
	secondaryLeftY.isShown = function() return showSecondaryTextOffsets("textLeft", secondaryDef.textLeft or "PERCENT") end
	list[#list + 1] = secondaryLeftY

	local secondaryCenterX = slider(
		L["TextCenterOffsetX"] or "Center text X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "secondaryPower", "offsetCenter", "x" }, (secondaryDef.offsetCenter and secondaryDef.offsetCenter.x) or 0) end,
		function(val)
			debounced(unit .. "_secondaryPowerCenterX", function()
				setValue(unit, { "secondaryPower", "offsetCenter", "x" }, val or 0)
				refresh()
			end)
		end,
		(secondaryDef.offsetCenter and secondaryDef.offsetCenter.x) or 0,
		"secondaryPower",
		true
	)
	secondaryCenterX.isEnabled = isSecondaryPowerEnabled
	secondaryCenterX.isShown = function() return showSecondaryTextOffsets("textCenter", secondaryDef.textCenter or "NONE") end
	list[#list + 1] = secondaryCenterX

	local secondaryCenterY = slider(
		L["TextCenterOffsetY"] or "Center text Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "secondaryPower", "offsetCenter", "y" }, (secondaryDef.offsetCenter and secondaryDef.offsetCenter.y) or 0) end,
		function(val)
			debounced(unit .. "_secondaryPowerCenterY", function()
				setValue(unit, { "secondaryPower", "offsetCenter", "y" }, val or 0)
				refresh()
			end)
		end,
		(secondaryDef.offsetCenter and secondaryDef.offsetCenter.y) or 0,
		"secondaryPower",
		true
	)
	secondaryCenterY.isEnabled = isSecondaryPowerEnabled
	secondaryCenterY.isShown = function() return showSecondaryTextOffsets("textCenter", secondaryDef.textCenter or "NONE") end
	list[#list + 1] = secondaryCenterY

	local secondaryRightX = slider(
		L["TextRightOffsetX"] or "Right text X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "secondaryPower", "offsetRight", "x" }, (secondaryDef.offsetRight and secondaryDef.offsetRight.x) or 0) end,
		function(val)
			debounced(unit .. "_secondaryPowerRightX", function()
				setValue(unit, { "secondaryPower", "offsetRight", "x" }, val or 0)
				refresh()
			end)
		end,
		(secondaryDef.offsetRight and secondaryDef.offsetRight.x) or 0,
		"secondaryPower",
		true
	)
	secondaryRightX.isEnabled = isSecondaryPowerEnabled
	secondaryRightX.isShown = function() return showSecondaryTextOffsets("textRight", secondaryDef.textRight or "CURMAX") end
	list[#list + 1] = secondaryRightX

	local secondaryRightY = slider(
		L["TextRightOffsetY"] or "Right text Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "secondaryPower", "offsetRight", "y" }, (secondaryDef.offsetRight and secondaryDef.offsetRight.y) or 0) end,
		function(val)
			debounced(unit .. "_secondaryPowerRightY", function()
				setValue(unit, { "secondaryPower", "offsetRight", "y" }, val or 0)
				refresh()
			end)
		end,
		(secondaryDef.offsetRight and secondaryDef.offsetRight.y) or 0,
		"secondaryPower",
		true
	)
	secondaryRightY.isEnabled = isSecondaryPowerEnabled
	secondaryRightY.isShown = function() return showSecondaryTextOffsets("textRight", secondaryDef.textRight or "CURMAX") end
	list[#list + 1] = secondaryRightY

	list[#list + 1] = checkbox(
		L["Use short numbers"] or "Use short numbers",
		function() return getValue(unit, { "secondaryPower", "useShortNumbers" }, secondaryDef.useShortNumbers ~= false) end,
		function(val)
			setValue(unit, { "secondaryPower", "useShortNumbers" }, val and true or false)
			refresh()
		end,
		secondaryDef.useShortNumbers ~= false,
		"secondaryPower",
		isSecondaryPowerEnabled
	)
	addDivider("secondaryPower")

	local secondaryTexture = checkboxDropdown(
		L["Bar Texture"] or "Bar Texture",
		textureOpts,
		function() return getValue(unit, { "secondaryPower", "texture" }, secondaryDef.texture or "DEFAULT") end,
		function(val)
			setValue(unit, { "secondaryPower", "texture" }, val)
			refresh()
		end,
		secondaryDef.texture or "DEFAULT",
		"secondaryPower"
	)
	secondaryTexture.isEnabled = isSecondaryPowerEnabled
	list[#list + 1] = secondaryTexture

	list[#list + 1] = checkboxColor({
		name = L["Show bar backdrop"] or "Show bar backdrop",
		parentId = "secondaryPower",
		defaultChecked = (secondaryDef.backdrop and secondaryDef.backdrop.enabled) ~= false,
		isChecked = function() return getValue(unit, { "secondaryPower", "backdrop", "enabled" }, (secondaryDef.backdrop and secondaryDef.backdrop.enabled) ~= false) ~= false end,
		onChecked = function(val)
			debounced(unit .. "_secondaryPowerBackdrop", function()
				setValue(unit, { "secondaryPower", "backdrop", "enabled" }, val and true or false)
				refresh()
				refreshSettingsUI()
			end)
		end,
		getColor = function()
			return toRGBA(
				getValue(unit, { "secondaryPower", "backdrop", "color" }, secondaryDef.backdrop and secondaryDef.backdrop.color),
				secondaryDef.backdrop and secondaryDef.backdrop.color or { 0, 0, 0, 0.6 }
			)
		end,
		onColor = function(color)
			debounced(unit .. "_secondaryPowerBackdropColor", function()
				setColor(unit, { "secondaryPower", "backdrop", "color" }, color.r, color.g, color.b, color.a)
				refresh()
			end)
		end,
		colorDefault = { r = 0, g = 0, b = 0, a = 0.6 },
		isEnabled = isSecondaryPowerEnabled,
	})

	local staggerColorsSection = {
		name = L["UFSecondaryStaggerColors"] or "Stagger colors",
		kind = UF.ui.settingType.Collapsible,
		id = "secondaryPowerStaggerColors",
		defaultCollapsed = true,
	}
	staggerColorsSection.isEnabled = isSecondaryStaggerSettingsShown
	staggerColorsSection.isShown = isSecondaryStaggerSettingsShown
	list[#list + 1] = staggerColorsSection

	local staggerHighDefaultColor = secondaryDef.staggerHighColor or (STAGGER_EXTRA_COLORS and STAGGER_EXTRA_COLORS.high) or { 0.62, 0.2, 1, 1 }
	local staggerExtremeDefaultColor = secondaryDef.staggerExtremeColor or (STAGGER_EXTRA_COLORS and STAGGER_EXTRA_COLORS.extreme) or { 1, 0.2, 0.8, 1 }

	local staggerUseExtended = checkbox(L["UFSecondaryStaggerUseExtended"] or "Use extended stagger colors", isSecondaryStaggerExtendedEnabled, function(val)
		setValue(unit, { "secondaryPower", "staggerHighColors" }, val and true or false)
		refresh()
		refreshSettingsUI()
	end, secondaryDef.staggerHighColors == true, "secondaryPowerStaggerColors", isSecondaryStaggerSettingsShown)
	staggerUseExtended.isShown = isSecondaryStaggerSettingsShown
	list[#list + 1] = staggerUseExtended

	local staggerHighThreshold = slider(
		L["UFSecondaryStaggerHighThreshold"] or "Stagger high threshold (%)",
		100,
		1000,
		10,
		function() return getValue(unit, { "secondaryPower", "staggerHighThreshold" }, secondaryDef.staggerHighThreshold or STAGGER_EXTRA_THRESHOLD_HIGH) end,
		function(val)
			local high = clampNumber(val, 100, 1000, STAGGER_EXTRA_THRESHOLD_HIGH)
			setValue(unit, { "secondaryPower", "staggerHighThreshold" }, high)
			local extreme = clampNumber(
				getValue(unit, { "secondaryPower", "staggerExtremeThreshold" }, secondaryDef.staggerExtremeThreshold or STAGGER_EXTRA_THRESHOLD_EXTREME),
				100,
				1000,
				STAGGER_EXTRA_THRESHOLD_EXTREME
			)
			if extreme < high then setValue(unit, { "secondaryPower", "staggerExtremeThreshold" }, high) end
			refresh()
		end,
		secondaryDef.staggerHighThreshold or STAGGER_EXTRA_THRESHOLD_HIGH,
		"secondaryPowerStaggerColors",
		true,
		function(value) return tostring(value) .. "%" end
	)
	staggerHighThreshold.isEnabled = function() return isSecondaryStaggerSettingsShown() and isSecondaryStaggerExtendedEnabled() end
	staggerHighThreshold.isShown = isSecondaryStaggerSettingsShown
	list[#list + 1] = staggerHighThreshold

	local staggerHighColor = {
		name = L["UFSecondaryStaggerHighColor"] or "Stagger high color",
		kind = UF.ui.settingType.Color,
		parentId = "secondaryPowerStaggerColors",
		isEnabled = function() return isSecondaryStaggerSettingsShown() and isSecondaryStaggerExtendedEnabled() end,
		isShown = isSecondaryStaggerSettingsShown,
		get = function() return getValue(unit, { "secondaryPower", "staggerHighColor" }, staggerHighDefaultColor) end,
		set = function(_, color)
			setColor(unit, { "secondaryPower", "staggerHighColor" }, color.r, color.g, color.b, color.a)
			refresh()
		end,
		colorGet = function() return getValue(unit, { "secondaryPower", "staggerHighColor" }, staggerHighDefaultColor) end,
		colorSet = function(_, color)
			setColor(unit, { "secondaryPower", "staggerHighColor" }, color.r, color.g, color.b, color.a)
			refresh()
		end,
		colorDefault = {
			r = select(1, toRGBA(staggerHighDefaultColor, { 0.62, 0.2, 1, 1 })),
			g = select(2, toRGBA(staggerHighDefaultColor, { 0.62, 0.2, 1, 1 })),
			b = select(3, toRGBA(staggerHighDefaultColor, { 0.62, 0.2, 1, 1 })),
			a = select(4, toRGBA(staggerHighDefaultColor, { 0.62, 0.2, 1, 1 })),
		},
		hasOpacity = true,
	}
	list[#list + 1] = staggerHighColor

	local staggerExtremeThreshold = slider(
		L["UFSecondaryStaggerExtremeThreshold"] or "Stagger extreme threshold (%)",
		100,
		1000,
		10,
		function() return getValue(unit, { "secondaryPower", "staggerExtremeThreshold" }, secondaryDef.staggerExtremeThreshold or STAGGER_EXTRA_THRESHOLD_EXTREME) end,
		function(val)
			local high =
				clampNumber(getValue(unit, { "secondaryPower", "staggerHighThreshold" }, secondaryDef.staggerHighThreshold or STAGGER_EXTRA_THRESHOLD_HIGH), 100, 1000, STAGGER_EXTRA_THRESHOLD_HIGH)
			local extreme = clampNumber(val, high, 1000, STAGGER_EXTRA_THRESHOLD_EXTREME)
			setValue(unit, { "secondaryPower", "staggerExtremeThreshold" }, extreme)
			refresh()
		end,
		secondaryDef.staggerExtremeThreshold or STAGGER_EXTRA_THRESHOLD_EXTREME,
		"secondaryPowerStaggerColors",
		true,
		function(value) return tostring(value) .. "%" end
	)
	staggerExtremeThreshold.isEnabled = function() return isSecondaryStaggerSettingsShown() and isSecondaryStaggerExtendedEnabled() end
	staggerExtremeThreshold.isShown = isSecondaryStaggerSettingsShown
	list[#list + 1] = staggerExtremeThreshold

	local staggerExtremeColor = {
		name = L["UFSecondaryStaggerExtremeColor"] or "Stagger extreme color",
		kind = UF.ui.settingType.Color,
		parentId = "secondaryPowerStaggerColors",
		isEnabled = function() return isSecondaryStaggerSettingsShown() and isSecondaryStaggerExtendedEnabled() end,
		isShown = isSecondaryStaggerSettingsShown,
		get = function() return getValue(unit, { "secondaryPower", "staggerExtremeColor" }, staggerExtremeDefaultColor) end,
		set = function(_, color)
			setColor(unit, { "secondaryPower", "staggerExtremeColor" }, color.r, color.g, color.b, color.a)
			refresh()
		end,
		colorGet = function() return getValue(unit, { "secondaryPower", "staggerExtremeColor" }, staggerExtremeDefaultColor) end,
		colorSet = function(_, color)
			setColor(unit, { "secondaryPower", "staggerExtremeColor" }, color.r, color.g, color.b, color.a)
			refresh()
		end,
		colorDefault = {
			r = select(1, toRGBA(staggerExtremeDefaultColor, { 1, 0.2, 0.8, 1 })),
			g = select(2, toRGBA(staggerExtremeDefaultColor, { 1, 0.2, 0.8, 1 })),
			b = select(3, toRGBA(staggerExtremeDefaultColor, { 1, 0.2, 0.8, 1 })),
			a = select(4, toRGBA(staggerExtremeDefaultColor, { 1, 0.2, 0.8, 1 })),
		},
		hasOpacity = true,
	}
	list[#list + 1] = staggerExtremeColor
end

addon.Aura = addon.Aura or {}
addon.Aura.AppendUFSecondaryPowerSettings = appendSecondaryPowerSettings
addon.Aura.GetUFPrimaryPowerTokenOptions = getPrimaryPowerTokenOptions
addon.Aura.GetUFMainPowerTokens = getMainPowerTokens
addon.Aura.GetUFPowerLabel = getPowerLabel

local function appendIncomingHealSettings(list, unit, healthDef, textureOpts, refresh, refreshSettingsUI)
	local incomingHealColorDef = healthDef.incomingHealColor or { 0.2, 0.85, 0.35, 0.45 }
	local function isIncomingHealEnabled() return getValue(unit, { "health", "incomingHealEnabled" }, healthDef.incomingHealEnabled == true) == true end
	local function refreshIncomingHealRegistration()
		if UF and UF.Refresh then
			UF.Refresh()
		else
			refresh()
		end
	end

	list[#list + 1] = { name = L["Incoming heals"] or "Incoming heals", kind = UF.ui.settingType.Collapsible, id = "incomingHeal", defaultCollapsed = true }
	list[#list + 1] = checkbox(L["Show incoming heal bar"] or "Show incoming heal bar", isIncomingHealEnabled, function(val)
		setValue(unit, { "health", "incomingHealEnabled" }, val and true or false)
		refreshIncomingHealRegistration()
		refreshSettingsUI()
	end, healthDef.incomingHealEnabled == true, "incomingHeal")

	list[#list + 1] = checkbox(
		L["Show sample incoming heals"] or "Show sample incoming heals",
		function() return getValue(unit, { "health", "showSampleIncomingHeal" }, healthDef.showSampleIncomingHeal == true) == true end,
		function(val)
			setValue(unit, { "health", "showSampleIncomingHeal" }, val and true or false)
			refresh()
		end,
		healthDef.showSampleIncomingHeal == true,
		"incomingHeal",
		isIncomingHealEnabled
	)

	local absorbLayerOrderSetting = radioDropdown(
		L["Absorb layer order"] or "Absorb layer order",
		{
			{ value = "INCOMING_ABOVE", label = L["Incoming heals above absorbs"] or "Incoming heals above absorbs" },
			{ value = "ABSORB_ABOVE", label = L["Absorbs above incoming heals"] or "Absorbs above incoming heals" },
		},
		function() return UFHelper.NormalizeAbsorbLayerOrder(getValue(unit, { "health", "absorbLayerOrder" }, "INCOMING_ABOVE")) end,
		function(val)
			setValue(unit, { "health", "absorbLayerOrder" }, UFHelper.NormalizeAbsorbLayerOrder(val))
			refresh()
		end,
		"INCOMING_ABOVE",
		"incomingHeal"
	)
	absorbLayerOrderSetting.isEnabled = isIncomingHealEnabled
	absorbLayerOrderSetting.newTagID = "ufAbsorbLayerOrder"
	list[#list + 1] = absorbLayerOrderSetting

	local incomingHealTextureSetting = checkboxDropdown(
		L["Incoming heal texture"] or "Incoming heal texture",
		textureOpts,
		function() return getValue(unit, { "health", "incomingHealTexture" }, healthDef.incomingHealTexture or healthDef.texture or "DEFAULT") end,
		function(val)
			setValue(unit, { "health", "incomingHealTexture" }, val)
			refresh()
		end,
		healthDef.incomingHealTexture or healthDef.texture or "DEFAULT",
		"incomingHeal"
	)
	incomingHealTextureSetting.isEnabled = isIncomingHealEnabled
	list[#list + 1] = incomingHealTextureSetting

	list[#list + 1] = {
		name = L["Incoming heal color"] or "Incoming heal color",
		kind = UF.ui.settingType.Color,
		parentId = "incomingHeal",
		isEnabled = isIncomingHealEnabled,
		get = function() return getValue(unit, { "health", "incomingHealColor" }, incomingHealColorDef) end,
		set = function(_, color)
			setColor(unit, { "health", "incomingHealColor" }, color.r, color.g, color.b, color.a)
			refresh()
		end,
		colorGet = function() return getValue(unit, { "health", "incomingHealColor" }, incomingHealColorDef) end,
		colorSet = function(_, color)
			setColor(unit, { "health", "incomingHealColor" }, color.r, color.g, color.b, color.a)
			refresh()
		end,
		colorDefault = {
			r = incomingHealColorDef[1] or 0.2,
			g = incomingHealColorDef[2] or 0.85,
			b = incomingHealColorDef[3] or 0.35,
			a = incomingHealColorDef[4] or 0.45,
		},
		hasOpacity = true,
	}
end

local function appendUnitCombatFeedbackSettings(list, unit, def, refreshSelf)
	list[#list + 1] = { name = L["UFCombatFeedback"] or "Combat feedback", kind = UF.ui.settingType.Collapsible, id = "combatFeedback", defaultCollapsed = true }
	local combatDef = def.combatFeedback or {}
	local function isCombatFeedbackEnabled() return getValue(unit, { "combatFeedback", "enabled" }, combatDef.enabled == true) == true end

	list[#list + 1] = checkbox(L["UFCombatFeedbackEnable"] or "Enable combat feedback", isCombatFeedbackEnabled, function(val)
		setValue(unit, { "combatFeedback", "enabled" }, val and true or false)
		refresh()
		refreshSettingsUI()
	end, combatDef.enabled == true, "combatFeedback")

	local function isCombatEventSelected(key)
		local events = getValue(unit, { "combatFeedback", "events" })
		if type(events) ~= "table" then events = combatDef.events end
		if type(events) ~= "table" then return true end
		local val = events[key]
		if val == nil and type(combatDef.events) == "table" then val = combatDef.events[key] end
		if val == nil then return true end
		return val == true
	end

	local function setCombatEventSelected(key, selected)
		local events = getValue(unit, { "combatFeedback", "events" })
		if type(events) ~= "table" then
			events = combatDef.events and CopyTable(combatDef.events) or {}
		else
			events = CopyTable(events)
		end
		events[key] = selected and true or false
		setValue(unit, { "combatFeedback", "events" }, events)
		refresh()
	end

	local combatFeedbackLocationOptions = {
		{ value = "FRAME", label = L["Frame"] or "Frame" },
		{ value = "STATUS", label = L["Status text"] or "Status text" },
		{ value = "HEALTH", label = L["Health"] or HEALTH or "Health" },
		{ value = "POWER", label = L["Power"] or _G.POWER or "Power" },
	}

	local combatFeedbackAnchorOptions = {
		{ value = "TOPLEFT", label = L["Top left"] or "Top left" },
		{ value = "TOP", label = DIRECTION_TOP_LABEL },
		{ value = "TOPRIGHT", label = L["Top right"] or "Top right" },
		{ value = "LEFT", label = DIRECTION_LEFT_LABEL },
		{ value = "CENTER", label = L["Center"] or "Center" },
		{ value = "RIGHT", label = DIRECTION_RIGHT_LABEL },
		{ value = "BOTTOMLEFT", label = L["Bottom left"] or "Bottom left" },
		{ value = "BOTTOM", label = DIRECTION_BOTTOM_LABEL },
		{ value = "BOTTOMRIGHT", label = L["Bottom right"] or "Bottom right" },
	}

	local combatFeedbackEventOptions = {
		{ value = "WOUND", label = L["Combat feedback damage"] or "Damage" },
		{ value = "HEAL", label = L["Combat feedback heal"] or "Heal" },
		{ value = "ENERGIZE", label = L["Combat feedback energize"] or "Energize" },
		{ value = "MISS", label = MISS or "Miss" },
		{ value = "DODGE", label = DODGE or "Dodge" },
		{ value = "PARRY", label = PARRY or "Parry" },
		{ value = "BLOCK", label = BLOCK or "Block" },
		{ value = "RESIST", label = RESIST or "Resist" },
		{ value = "ABSORB", label = ABSORB or "Absorb" },
		{ value = "IMMUNE", label = IMMUNE or "Immune" },
		{ value = "DEFLECT", label = DEFLECT or "Deflect" },
		{ value = "REFLECT", label = REFLECT or "Reflect" },
		{ value = "EVADE", label = EVADE or "Evade" },
		{ value = "INTERRUPT", label = INTERRUPT or "Interrupt" },
	}

	local combatFeedbackSampleOptions = {
		{ value = "WOUND", label = L["Combat feedback damage"] or "Damage" },
		{ value = "HEAL", label = L["Combat feedback heal"] or "Heal" },
		{ value = "ENERGIZE", label = L["Combat feedback energize"] or "Energize" },
	}

	list[#list + 1] = multiDropdown(
		L["Events"] or "Combat feedback events",
		combatFeedbackEventOptions,
		isCombatEventSelected,
		setCombatEventSelected,
		combatDef.events,
		"combatFeedback",
		isCombatFeedbackEnabled
	)

	if #fontOptions() > 0 then
		local combatFontSetting = checkboxDropdown(
			L["Font"] or "Combat feedback font",
			fontOptions,
			function() return getValue(unit, { "combatFeedback", "font" }, combatDef.font or UF.ui.globalFontConfigKey()) end,
			function(val)
				setValue(unit, { "combatFeedback", "font" }, val)
				refreshSelf()
			end,
			combatDef.font or UF.ui.globalFontConfigKey(),
			"combatFeedback"
		)
		combatFontSetting.isEnabled = isCombatFeedbackEnabled
		list[#list + 1] = combatFontSetting
	end

	local combatFontSizeSetting = slider(
		L["Size"] or "Combat feedback size",
		8,
		64,
		1,
		function() return getValue(unit, { "combatFeedback", "fontSize" }, combatDef.fontSize or 30) end,
		function(val)
			debounced(unit .. "_combatFeedbackSize", function()
				setValue(unit, { "combatFeedback", "fontSize" }, val or 30)
				refreshSelf()
			end)
		end,
		combatDef.fontSize or 30,
		"combatFeedback",
		true
	)
	combatFontSizeSetting.isEnabled = isCombatFeedbackEnabled
	list[#list + 1] = combatFontSizeSetting

	local combatLocationSetting = radioDropdown(
		L["Location"] or "Combat feedback location",
		combatFeedbackLocationOptions,
		function() return getValue(unit, { "combatFeedback", "location" }, combatDef.location or "STATUS") end,
		function(val)
			setValue(unit, { "combatFeedback", "location" }, val or "STATUS")
			refreshSelf()
		end,
		combatDef.location or "STATUS",
		"combatFeedback"
	)
	combatLocationSetting.isEnabled = isCombatFeedbackEnabled
	list[#list + 1] = combatLocationSetting

	local combatAnchorSetting = radioDropdown(
		L["Anchor"] or "Combat feedback anchor",
		combatFeedbackAnchorOptions,
		function() return getValue(unit, { "combatFeedback", "anchor" }, combatDef.anchor or "CENTER") end,
		function(val)
			setValue(unit, { "combatFeedback", "anchor" }, val or "CENTER")
			refreshSelf()
		end,
		combatDef.anchor or "CENTER",
		"combatFeedback"
	)
	combatAnchorSetting.isEnabled = isCombatFeedbackEnabled
	list[#list + 1] = combatAnchorSetting

	local combatOffsetX = slider(
		L["Offset X"] or "Combat feedback offset X",
		-UF.ui.offsetRange,
		UF.ui.offsetRange,
		1,
		function() return getValue(unit, { "combatFeedback", "offset", "x" }, (combatDef.offset and combatDef.offset.x) or 0) end,
		function(val)
			local off = getValue(unit, { "combatFeedback", "offset" }, { x = 0, y = 0 }) or {}
			off.x = val or 0
			setValue(unit, { "combatFeedback", "offset" }, off)
			refreshSelf()
		end,
		(combatDef.offset and combatDef.offset.x) or 0,
		"combatFeedback",
		true
	)
	combatOffsetX.isEnabled = isCombatFeedbackEnabled
	list[#list + 1] = combatOffsetX

	local combatOffsetY = slider(
		L["Offset Y"] or "Combat feedback offset Y",
		-UF.ui.offsetRange,
		UF.ui.offsetRange,
		1,
		function() return getValue(unit, { "combatFeedback", "offset", "y" }, (combatDef.offset and combatDef.offset.y) or 0) end,
		function(val)
			local off = getValue(unit, { "combatFeedback", "offset" }, { x = 0, y = 0 }) or {}
			off.y = val or 0
			setValue(unit, { "combatFeedback", "offset" }, off)
			refreshSelf()
		end,
		(combatDef.offset and combatDef.offset.y) or 0,
		"combatFeedback",
		true
	)
	combatOffsetY.isEnabled = isCombatFeedbackEnabled
	list[#list + 1] = combatOffsetY
	list[#list + 1] = { name = "", kind = UF.ui.settingType.Divider, parentId = "combatFeedback" }

	local function isCombatFeedbackSampleEnabled() return isCombatFeedbackEnabled() and getValue(unit, { "combatFeedback", "sample" }, combatDef.sample == true) == true end

	list[#list + 1] = checkbox(L["Show sample"] or "Show sample", function() return getValue(unit, { "combatFeedback", "sample" }, combatDef.sample == true) == true end, function(val)
		setValue(unit, { "combatFeedback", "sample" }, val and true or false)
		refreshSelf()
	end, combatDef.sample == true, "combatFeedback")
	list[#list].isEnabled = isCombatFeedbackEnabled

	local sampleTypeSetting = radioDropdown(
		L["UFCombatFeedbackSampleType"] or "Sample type",
		combatFeedbackSampleOptions,
		function() return getValue(unit, { "combatFeedback", "sampleEvent" }, combatDef.sampleEvent or "WOUND") end,
		function(val)
			setValue(unit, { "combatFeedback", "sampleEvent" }, val or "WOUND")
			refreshSelf()
		end,
		combatDef.sampleEvent or "WOUND",
		"combatFeedback"
	)
	sampleTypeSetting.isEnabled = isCombatFeedbackSampleEnabled
	list[#list + 1] = sampleTypeSetting

	local sampleAmountSetting = slider(
		L["UFCombatFeedbackSampleAmount"] or "Sample amount",
		0,
		200000,
		1,
		function() return getValue(unit, { "combatFeedback", "sampleAmount" }, combatDef.sampleAmount or 12345) end,
		function(val)
			local amt = tonumber(val) or 0
			if amt < 0 then amt = 0 end
			setValue(unit, { "combatFeedback", "sampleAmount" }, amt)
			refreshSelf()
		end,
		combatDef.sampleAmount or 12345,
		"combatFeedback",
		true
	)
	sampleAmountSetting.isEnabled = isCombatFeedbackSampleEnabled
	list[#list + 1] = sampleAmountSetting
end

function UF.ui.appendDataBarSettings(list, unit, def, refresh, refreshSelf, addDivider)
	local dataBarDef = def.dataBar or {}
	list[#list + 1] = { name = L["UFDataBar"] or "Data bar", kind = UF.ui.settingType.Collapsible, id = "dataBar", defaultCollapsed = true }

	local function isDataBarEnabled()
		return getValue(unit, { "dataBar", "enabled" }, dataBarDef.enabled == true) == true
	end

	list[#list + 1] = checkbox(L["UFDataBarEnable"] or "Enable data bar", isDataBarEnabled, function(val)
		setValue(unit, { "dataBar", "enabled" }, val and true or false)
		refreshSelf()
		refreshSettingsUI()
	end, dataBarDef.enabled == true, "dataBar")

	local dataBarPositionOptions = {
		{ value = "ABOVE", label = L["UFDataBarAbove"] or "Above" },
		{ value = "CENTER", label = _G.CENTER or "Center" },
		{ value = "BELOW", label = L["UFDataBarBelow"] or "Below" },
	}
	local dataBarPosition = radioDropdown(L["UFDataBarPosition"] or "Data bar position", dataBarPositionOptions, function()
		return tostring(getValue(unit, { "dataBar", "position" }, dataBarDef.position or "BELOW")):upper()
	end, function(val)
		setValue(unit, { "dataBar", "position" }, (val or "BELOW"):upper())
		refreshSelf()
	end, dataBarDef.position or "BELOW", "dataBar")
	dataBarPosition.isEnabled = isDataBarEnabled
	list[#list + 1] = dataBarPosition

	local dataBarHeight = slider(L["UFDataBarHeight"] or "Data bar height", 4, 80, 1, function()
		return getValue(unit, { "dataBar", "height" }, dataBarDef.height or 16)
	end, function(val)
		debounced(unit .. "_dataBarHeight", function()
			setValue(unit, { "dataBar", "height" }, val or dataBarDef.height or 16)
			refreshSelf()
		end)
	end, dataBarDef.height or 16, "dataBar", true)
	dataBarHeight.isEnabled = isDataBarEnabled
	dataBarHeight.isShown = function() return getValue(unit, { "dataBar", "detached" }, dataBarDef.detached == true) ~= true end
	list[#list + 1] = dataBarHeight

	local dataBarGap = slider(L["UFDataBarGap"] or "Data bar gap", -40, 40, 1, function()
		return getValue(unit, { "dataBar", "gap" }, dataBarDef.gap or 0)
	end, function(val)
		debounced(unit .. "_dataBarGap", function()
			setValue(unit, { "dataBar", "gap" }, val or 0)
			refreshSelf()
		end)
	end, dataBarDef.gap or 0, "dataBar", true)
	dataBarGap.isEnabled = isDataBarEnabled
	list[#list + 1] = dataBarGap

	local function isDataBarDetached()
		return isDataBarEnabled() and getValue(unit, { "dataBar", "detached" }, dataBarDef.detached == true) == true
	end

	local dataBarDetached = checkbox(L["UFDataBarDetached"] or "Detach data bar", function()
		return getValue(unit, { "dataBar", "detached" }, dataBarDef.detached == true) == true
	end, function(val)
		setValue(unit, { "dataBar", "detached" }, val and true or false)
		refreshSelf()
		refreshSettingsUI()
	end, dataBarDef.detached == true, "dataBar", isDataBarEnabled)
	dataBarDetached.field = "dataBarDetached"
	list[#list + 1] = dataBarDetached

	local detachedWidth = slider(L["UFDataBarWidth"] or "Data bar width", 10, 1000, 1, function()
		return getValue(unit, { "dataBar", "detachedWidth" }, getValue(unit, { "width" }, def.width or MIN_WIDTH))
	end, function(val)
		debounced(unit .. "_detachedDataBarWidth", function()
			setValue(unit, { "dataBar", "detachedWidth" }, math.min(1000, math.max(10, tonumber(val) or def.width or MIN_WIDTH)))
			refreshSelf()
		end)
	end, def.width or MIN_WIDTH, "dataBar", true)
	detachedWidth.isEnabled = isDataBarDetached
	detachedWidth.isShown = isDataBarDetached
	detachedWidth.field = "dataBarDetachedWidth"
	list[#list + 1] = detachedWidth

	local detachedHeight = slider(L["UFDataBarHeight"] or "Data bar height", 4, 1000, 1, function()
		return getValue(unit, { "dataBar", "detachedHeight" }, getValue(unit, { "dataBar", "height" }, dataBarDef.height or 16))
	end, function(val)
		debounced(unit .. "_detachedDataBarHeight", function()
			setValue(unit, { "dataBar", "detachedHeight" }, math.min(1000, math.max(4, tonumber(val) or dataBarDef.height or 16)))
			refreshSelf()
		end)
	end, dataBarDef.detachedHeight or dataBarDef.height or 16, "dataBar", true)
	detachedHeight.isEnabled = isDataBarDetached
	detachedHeight.isShown = isDataBarDetached
	detachedHeight.field = "dataBarDetachedHeight"
	list[#list + 1] = detachedHeight

	local detachedOffsetX = slider(L["Offset X"] or "Offset X", -800, 800, 1, function()
		return getValue(unit, { "dataBar", "detachedOffset", "x" }, 0)
	end, function(val)
		debounced(unit .. "_detachedDataBarOffsetX", function()
			setValue(unit, { "dataBar", "detachedOffset", "x" }, tonumber(val) or 0)
			refreshSelf()
		end)
	end, 0, "dataBar", true)
	detachedOffsetX.isEnabled = isDataBarDetached
	detachedOffsetX.isShown = isDataBarDetached
	detachedOffsetX.field = "dataBarDetachedOffsetX"
	list[#list + 1] = detachedOffsetX

	local detachedOffsetY = slider(L["Offset Y"] or "Offset Y", -800, 800, 1, function()
		return getValue(unit, { "dataBar", "detachedOffset", "y" }, 0)
	end, function(val)
		debounced(unit .. "_detachedDataBarOffsetY", function()
			setValue(unit, { "dataBar", "detachedOffset", "y" }, tonumber(val) or 0)
			refreshSelf()
		end)
	end, 0, "dataBar", true)
	detachedOffsetY.isEnabled = isDataBarDetached
	detachedOffsetY.isShown = isDataBarDetached
	detachedOffsetY.field = "dataBarDetachedOffsetY"
	list[#list + 1] = detachedOffsetY

	list[#list + 1] = checkbox(
		L["Use class color (players)"] or "Use class color (players)",
		function() return getValue(unit, { "dataBar", "useClassColor" }, dataBarDef.useClassColor == true) == true end,
		function(val)
			setValue(unit, { "dataBar", "useClassColor" }, val and true or false)
			refreshSelf()
			refreshSettingsUI()
		end,
		dataBarDef.useClassColor == true,
		"dataBar",
		isDataBarEnabled
	)

	list[#list + 1] = {
		name = L["UFDataBarColor"] or "Data bar color",
		kind = UF.ui.settingType.Color,
		parentId = "dataBar",
		hasOpacity = true,
		default = dataBarDef.color or { 0.18, 0.18, 0.22, 1 },
		get = function() return getValue(unit, { "dataBar", "color" }, dataBarDef.color or { 0.18, 0.18, 0.22, 1 }) end,
		set = function(_, color)
			setColor(unit, { "dataBar", "color" }, color.r, color.g, color.b, color.a)
			refreshSelf()
		end,
		colorGet = function()
			local r, g, b, a = toRGBA(getValue(unit, { "dataBar", "color" }, dataBarDef.color), dataBarDef.color or { 0.18, 0.18, 0.22, 1 })
			return { r = r, g = g, b = b, a = a }
		end,
		colorSet = function(_, color)
			setColor(unit, { "dataBar", "color" }, color.r, color.g, color.b, color.a)
			refreshSelf()
		end,
		colorDefault = {
			r = (dataBarDef.color and dataBarDef.color[1]) or 0.18,
			g = (dataBarDef.color and dataBarDef.color[2]) or 0.18,
			b = (dataBarDef.color and dataBarDef.color[3]) or 0.22,
			a = (dataBarDef.color and dataBarDef.color[4]) or 1,
		},
		isEnabled = function()
			return isDataBarEnabled() and getValue(unit, { "dataBar", "useClassColor" }, dataBarDef.useClassColor == true) ~= true
		end,
	}
	addDivider("dataBar")

	list[#list + 1] = radioDropdown(L["Left text"] or "Left text", UF.ui.dataBarTextOptions, function()
		return normalizeTextMode(getValue(unit, { "dataBar", "textLeft" }, dataBarDef.textLeft or "NAME"))
	end, function(val)
		setValue(unit, { "dataBar", "textLeft" }, val)
		refresh()
		refreshSettingsUI()
	end, dataBarDef.textLeft or "NAME", "dataBar")
	list[#list].isEnabled = isDataBarEnabled

	list[#list + 1] = radioDropdown(L["Center text"] or "Center text", UF.ui.dataBarTextOptions, function()
		return normalizeTextMode(getValue(unit, { "dataBar", "textCenter" }, dataBarDef.textCenter or "CURMAX"))
	end, function(val)
		setValue(unit, { "dataBar", "textCenter" }, val)
		refresh()
		refreshSettingsUI()
	end, dataBarDef.textCenter or "CURMAX", "dataBar")
	list[#list].isEnabled = isDataBarEnabled

	list[#list + 1] = radioDropdown(L["Right text"] or "Right text", UF.ui.dataBarTextOptions, function()
		return normalizeTextMode(getValue(unit, { "dataBar", "textRight" }, dataBarDef.textRight or "PERCENT"))
	end, function(val)
		setValue(unit, { "dataBar", "textRight" }, val)
		refresh()
		refreshSettingsUI()
	end, dataBarDef.textRight or "PERCENT", "dataBar")
	list[#list].isEnabled = isDataBarEnabled

	local function isDataBarNameTextEnabled()
		if not isDataBarEnabled() then return false end
		return normalizeTextMode(getValue(unit, { "dataBar", "textLeft" }, dataBarDef.textLeft or "NAME")) == "NAME"
			or normalizeTextMode(getValue(unit, { "dataBar", "textCenter" }, dataBarDef.textCenter or "CURMAX")) == "NAME"
			or normalizeTextMode(getValue(unit, { "dataBar", "textRight" }, dataBarDef.textRight or "PERCENT")) == "NAME"
	end

	local dataBarNameMaxChars = slider(
		L["Name max width"] or "Name max width",
		0,
		40,
		1,
		function() return getValue(unit, { "dataBar", "nameMaxChars" }, dataBarDef.nameMaxChars or 0) end,
		function(val)
			setValue(unit, { "dataBar", "nameMaxChars" }, val or 0)
			refresh()
		end,
		dataBarDef.nameMaxChars or 0,
		"dataBar",
		true
	)
	dataBarNameMaxChars.isEnabled = isDataBarNameTextEnabled
	dataBarNameMaxChars.isShown = isDataBarNameTextEnabled
	list[#list + 1] = dataBarNameMaxChars

	local function dataBarDelimiterCount()
		local leftMode = getValue(unit, { "dataBar", "textLeft" }, dataBarDef.textLeft or "NAME")
		local centerMode = getValue(unit, { "dataBar", "textCenter" }, dataBarDef.textCenter or "CURMAX")
		local rightMode = getValue(unit, { "dataBar", "textRight" }, dataBarDef.textRight or "PERCENT")
		return maxDelimiterCount(leftMode, centerMode, rightMode)
	end

	local dataBarDelimiter = radioDropdown(L["Delimiter"] or "Delimiter", delimiterOptions, function()
		return getValue(unit, { "dataBar", "textDelimiter" }, dataBarDef.textDelimiter or " ")
	end, function(val)
		setValue(unit, { "dataBar", "textDelimiter" }, val)
		refresh()
	end, dataBarDef.textDelimiter or " ", "dataBar")
	dataBarDelimiter.isEnabled = isDataBarEnabled
	dataBarDelimiter.isShown = function() return dataBarDelimiterCount() >= 1 end
	list[#list + 1] = dataBarDelimiter

	local dataBarDelimiterSecondary = radioDropdown(L["Secondary Delimiter"] or "Secondary delimiter", delimiterOptions, function()
		local primary = getValue(unit, { "dataBar", "textDelimiter" }, dataBarDef.textDelimiter or " ")
		return getValue(unit, { "dataBar", "textDelimiterSecondary" }, primary)
	end, function(val)
		setValue(unit, { "dataBar", "textDelimiterSecondary" }, val)
		refresh()
	end, dataBarDef.textDelimiterSecondary or dataBarDef.textDelimiter or " ", "dataBar")
	dataBarDelimiterSecondary.isEnabled = isDataBarEnabled
	dataBarDelimiterSecondary.isShown = function() return dataBarDelimiterCount() >= 2 end
	list[#list + 1] = dataBarDelimiterSecondary

	local dataBarDelimiterTertiary = radioDropdown(L["Tertiary Delimiter"] or "Tertiary delimiter", delimiterOptions, function()
		local primary = getValue(unit, { "dataBar", "textDelimiter" }, dataBarDef.textDelimiter or " ")
		local secondary = getValue(unit, { "dataBar", "textDelimiterSecondary" }, primary)
		return getValue(unit, { "dataBar", "textDelimiterTertiary" }, secondary)
	end, function(val)
		setValue(unit, { "dataBar", "textDelimiterTertiary" }, val)
		refresh()
	end, dataBarDef.textDelimiterTertiary or dataBarDef.textDelimiterSecondary or dataBarDef.textDelimiter or " ", "dataBar")
	dataBarDelimiterTertiary.isEnabled = isDataBarEnabled
	dataBarDelimiterTertiary.isShown = function() return dataBarDelimiterCount() >= 3 end
	list[#list + 1] = dataBarDelimiterTertiary
	addDivider("dataBar")

	local dataBarFontSize = slider(FONT_SIZE_LABEL, 8, 30, 1, function()
		return getValue(unit, { "dataBar", "fontSize" }, dataBarDef.fontSize or 12)
	end, function(val)
		debounced(unit .. "_dataBarFontSize", function()
			setValue(unit, { "dataBar", "fontSize" }, val or dataBarDef.fontSize or 12)
			refresh()
		end)
	end, dataBarDef.fontSize or 12, "dataBar", true)
	dataBarFontSize.isEnabled = isDataBarEnabled
	list[#list + 1] = dataBarFontSize

	if #fontOptions() > 0 then
		local dataBarFont = checkboxDropdown(L["Font"] or "Font", fontOptions, function()
			return getValue(unit, { "dataBar", "font" }, dataBarDef.font or UF.ui.globalFontConfigKey())
		end, function(val)
			setValue(unit, { "dataBar", "font" }, val)
			refresh()
		end, dataBarDef.font or UF.ui.globalFontConfigKey(), "dataBar")
		dataBarFont.isEnabled = isDataBarEnabled
		list[#list + 1] = dataBarFont
	end

	local dataBarFontOutline = checkboxDropdown(L["Font outline"] or "Font outline", UF.ui.outlineOptions, function()
		return UF.ui.normalizeFontStyleChoice(getValue(unit, { "dataBar", "fontOutline" }, dataBarDef.fontOutline or "OUTLINE"), dataBarDef.fontOutline or "OUTLINE")
	end, function(val)
		setValue(unit, { "dataBar", "fontOutline" }, UF.ui.normalizeFontStyleChoice(val, dataBarDef.fontOutline or "OUTLINE"))
		refresh()
	end, dataBarDef.fontOutline or "OUTLINE", "dataBar")
	dataBarFontOutline.isEnabled = isDataBarEnabled
	list[#list + 1] = dataBarFontOutline

	list[#list + 1] = checkbox(
		L["UFDataBarTextUseClassColor"] or "Use class color (data bar text)",
		function() return getValue(unit, { "dataBar", "useTextClassColor" }, dataBarDef.useTextClassColor == true) == true end,
		function(val)
			setValue(unit, { "dataBar", "useTextClassColor" }, val and true or false)
			refresh()
			refreshSettingsUI()
		end,
		dataBarDef.useTextClassColor == true,
		"dataBar",
		isDataBarEnabled
	)

	list[#list + 1] = {
		name = L["UFDataBarTextColor"] or "Data bar text color",
		kind = UF.ui.settingType.Color,
		parentId = "dataBar",
		hasOpacity = true,
		default = dataBarDef.textColor or { 1, 1, 1, 1 },
		get = function() return getValue(unit, { "dataBar", "textColor" }, dataBarDef.textColor or { 1, 1, 1, 1 }) end,
		set = function(_, color)
			setColor(unit, { "dataBar", "textColor" }, color.r, color.g, color.b, color.a)
			setValue(unit, { "dataBar", "useTextClassColor" }, false)
			refresh()
		end,
		colorGet = function()
			local r, g, b, a = toRGBA(getValue(unit, { "dataBar", "textColor" }, dataBarDef.textColor), dataBarDef.textColor or { 1, 1, 1, 1 })
			return { r = r, g = g, b = b, a = a }
		end,
		colorSet = function(_, color)
			setColor(unit, { "dataBar", "textColor" }, color.r, color.g, color.b, color.a)
			setValue(unit, { "dataBar", "useTextClassColor" }, false)
			refresh()
		end,
		colorDefault = {
			r = (dataBarDef.textColor and dataBarDef.textColor[1]) or 1,
			g = (dataBarDef.textColor and dataBarDef.textColor[2]) or 1,
			b = (dataBarDef.textColor and dataBarDef.textColor[3]) or 1,
			a = (dataBarDef.textColor and dataBarDef.textColor[4]) or 1,
		},
		isEnabled = function()
			return isDataBarEnabled() and getValue(unit, { "dataBar", "useTextClassColor" }, dataBarDef.useTextClassColor == true) ~= true
		end,
	}

	local function showDataBarTextOffsets(key, fallback)
		local mode = normalizeTextMode(getValue(unit, { "dataBar", key }, fallback))
		return mode ~= "NONE"
	end

	local dataBarLeftX = slider(
		L["TextLeftOffsetX"] or "Left text X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "dataBar", "offsetLeft", "x" }, (dataBarDef.offsetLeft and dataBarDef.offsetLeft.x) or 0) end,
		function(val)
			debounced(unit .. "_dataBarLeftX", function()
				setValue(unit, { "dataBar", "offsetLeft", "x" }, val or 0)
				refresh()
			end)
		end,
		(dataBarDef.offsetLeft and dataBarDef.offsetLeft.x) or 0,
		"dataBar",
		true
	)
	dataBarLeftX.isEnabled = isDataBarEnabled
	dataBarLeftX.isShown = function() return showDataBarTextOffsets("textLeft", dataBarDef.textLeft or "NAME") end
	list[#list + 1] = dataBarLeftX

	local dataBarLeftY = slider(
		L["TextLeftOffsetY"] or "Left text Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "dataBar", "offsetLeft", "y" }, (dataBarDef.offsetLeft and dataBarDef.offsetLeft.y) or 0) end,
		function(val)
			debounced(unit .. "_dataBarLeftY", function()
				setValue(unit, { "dataBar", "offsetLeft", "y" }, val or 0)
				refresh()
			end)
		end,
		(dataBarDef.offsetLeft and dataBarDef.offsetLeft.y) or 0,
		"dataBar",
		true
	)
	dataBarLeftY.isEnabled = isDataBarEnabled
	dataBarLeftY.isShown = function() return showDataBarTextOffsets("textLeft", dataBarDef.textLeft or "NAME") end
	list[#list + 1] = dataBarLeftY

	local dataBarCenterX = slider(
		L["TextCenterOffsetX"] or "Center text X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "dataBar", "offsetCenter", "x" }, (dataBarDef.offsetCenter and dataBarDef.offsetCenter.x) or 0) end,
		function(val)
			debounced(unit .. "_dataBarCenterX", function()
				setValue(unit, { "dataBar", "offsetCenter", "x" }, val or 0)
				refresh()
			end)
		end,
		(dataBarDef.offsetCenter and dataBarDef.offsetCenter.x) or 0,
		"dataBar",
		true
	)
	dataBarCenterX.isEnabled = isDataBarEnabled
	dataBarCenterX.isShown = function() return showDataBarTextOffsets("textCenter", dataBarDef.textCenter or "CURMAX") end
	list[#list + 1] = dataBarCenterX

	local dataBarCenterY = slider(
		L["TextCenterOffsetY"] or "Center text Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "dataBar", "offsetCenter", "y" }, (dataBarDef.offsetCenter and dataBarDef.offsetCenter.y) or 0) end,
		function(val)
			debounced(unit .. "_dataBarCenterY", function()
				setValue(unit, { "dataBar", "offsetCenter", "y" }, val or 0)
				refresh()
			end)
		end,
		(dataBarDef.offsetCenter and dataBarDef.offsetCenter.y) or 0,
		"dataBar",
		true
	)
	dataBarCenterY.isEnabled = isDataBarEnabled
	dataBarCenterY.isShown = function() return showDataBarTextOffsets("textCenter", dataBarDef.textCenter or "CURMAX") end
	list[#list + 1] = dataBarCenterY

	local dataBarRightX = slider(
		L["TextRightOffsetX"] or "Right text X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "dataBar", "offsetRight", "x" }, (dataBarDef.offsetRight and dataBarDef.offsetRight.x) or 0) end,
		function(val)
			debounced(unit .. "_dataBarRightX", function()
				setValue(unit, { "dataBar", "offsetRight", "x" }, val or 0)
				refresh()
			end)
		end,
		(dataBarDef.offsetRight and dataBarDef.offsetRight.x) or 0,
		"dataBar",
		true
	)
	dataBarRightX.isEnabled = isDataBarEnabled
	dataBarRightX.isShown = function() return showDataBarTextOffsets("textRight", dataBarDef.textRight or "PERCENT") end
	list[#list + 1] = dataBarRightX

	local dataBarRightY = slider(
		L["TextRightOffsetY"] or "Right text Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "dataBar", "offsetRight", "y" }, (dataBarDef.offsetRight and dataBarDef.offsetRight.y) or 0) end,
		function(val)
			debounced(unit .. "_dataBarRightY", function()
				setValue(unit, { "dataBar", "offsetRight", "y" }, val or 0)
				refresh()
			end)
		end,
		(dataBarDef.offsetRight and dataBarDef.offsetRight.y) or 0,
		"dataBar",
		true
	)
	dataBarRightY.isEnabled = isDataBarEnabled
	dataBarRightY.isShown = function() return showDataBarTextOffsets("textRight", dataBarDef.textRight or "PERCENT") end
	list[#list + 1] = dataBarRightY
	addDivider("dataBar")

	local dataBarTexture = checkboxDropdown(L["Bar Texture"] or "Bar Texture", textureOptions, function()
		return getValue(unit, { "dataBar", "texture" }, dataBarDef.texture or "SOLID")
	end, function(val)
		setValue(unit, { "dataBar", "texture" }, val or "SOLID")
		refresh()
	end, dataBarDef.texture or "SOLID", "dataBar")
	dataBarTexture.isEnabled = isDataBarEnabled
	list[#list + 1] = dataBarTexture

	list[#list + 1] = {
		name = L["UFDataBarCustomAtlas"] or "Custom atlas texture",
		kind = UF.ui.settingType.Input,
		parentId = "dataBar",
		newTagID = "ufDataBarCustomAtlas",
		maxChars = 160,
		tooltip = L["UFDataBarCustomAtlasDesc"] or "Enter a valid WoW atlas name. Leave blank to use the selected bar texture.",
		get = function() return getValue(unit, { "dataBar", "customAtlas" }, dataBarDef.customAtlas or "") end,
		set = function(_, value)
			local atlas = type(value) == "string" and value:match("^%s*(.-)%s*$") or ""
			setValue(unit, { "dataBar", "customAtlas" }, atlas)
			refresh()
		end,
		isEnabled = isDataBarEnabled,
	}
end

local function buildUnitSettings(unit)
	local MIN_WIDTH = UF.ui.minWidth
	local OFFSET_RANGE = UF.ui.offsetRange
	local def = defaultsFor(unit)
	local list = {}
	local function addDivider(parentId, isShown, isEnabled)
		local divider = { name = "", kind = UF.ui.settingType.Divider, parentId = parentId }
		if type(isShown) == "function" then divider.isShown = isShown end
		if type(isEnabled) == "function" then divider.isEnabled = isEnabled end
		list[#list + 1] = divider
	end
	local isBoss = isBossUnit(unit)
	local refreshFunc = refresh
	local function refreshSelf(syncEditModeValues)
		local visualOnlyRefresh = consumeVisualOnlyRefreshPending()
		if isBoss and UF.ConfigureBossFrames then
			UF.ConfigureBossFrames()
		else
			refreshFunc(unit)
		end
		if syncEditModeValues and not visualOnlyRefresh and addon.EditModeLib and addon.EditModeLib.IsInEditMode and addon.EditModeLib:IsInEditMode() then
			refreshEditModeFrame(isBoss and "boss" or unit)
		end
	end
	local refresh = refreshSelf
	local isPlayer = unit == "player"
	local isPet = unit == "pet"
	local classHasResource = false
	local classHasTotemFrame = false
	if isPlayer then
		classHasResource, classHasTotemFrame = UF.ui.getPlayerClassFrameSupportFlags()
	end
	local copyOptions = UF.ui.availableCopySources(unit)
	local visibilityOptions = UF.ui.getVisibilityRuleOptions(unit)
	local function getVisibilityConfig()
		local cfg = ensureConfig(unit)
		local raw = cfg and cfg.visibility
		local normalizeVisibilityConfig = addon.functions and addon.functions.NormalizeUnitFrameVisibilityConfig
		if normalizeVisibilityConfig then return normalizeVisibilityConfig(nil, raw, { skipSave = true, ignoreOverride = true }) end
		if type(raw) == "table" then return raw end
		return nil
	end
	local function isVisibilityRuleSelected(key)
		local config = getVisibilityConfig()
		return config and config[key] == true
	end
	local function setVisibilitySelection(selection)
		local cfg = ensureConfig(unit)
		local working
		if type(selection) == "table" then
			for _, option in ipairs(visibilityOptions) do
				local key = option and option.value
				if key ~= nil and selection[key] == true then
					if key == "ALWAYS_HIDDEN" then
						working = { ALWAYS_HIDDEN = true }
						break
					end
					working = working or {}
					working[key] = true
				end
			end
		end
		if working ~= nil and not next(working) then working = nil end
		cfg.visibility = working
		if UF and UF.ScheduleEqolVisibilityDriverAlphaRefresh then
			UF.ScheduleEqolVisibilityDriverAlphaRefresh()
		elseif UF and UF.RefreshEqolVisibilityDrivers then
			UF.RefreshEqolVisibilityDrivers()
		end
		if UF and UF.ApplyVisibilityRules then UF.ApplyVisibilityRules(unit) end
	end
	local function setVisibilityRule(key, shouldSelect)
		local selection = getVisibilityConfig() or {}
		if key == "ALWAYS_HIDDEN" and shouldSelect then
			selection = { ALWAYS_HIDDEN = true }
		elseif shouldSelect then
			selection[key] = true
			selection.ALWAYS_HIDDEN = nil
		else
			selection[key] = nil
		end
		setVisibilitySelection(selection)
	end
	local function isHideInVehicleEnabled()
		local cfg = ensureConfig(unit)
		local value = cfg and cfg.hideInVehicle
		if value == nil then value = def.hideInVehicle end
		return value == true
	end
	local function setHideInVehicleEnabled(value)
		local cfg = ensureConfig(unit)
		cfg.hideInVehicle = value and true or false
		refreshSelf()
		refreshSettingsUI()
	end
	list[#list + 1] = { name = SETTINGS or "Settings", kind = UF.ui.settingType.Collapsible, id = "utility", defaultCollapsed = true }

	list[#list + 1] = {
		name = L["Copy settings"] or "Copy settings",
		kind = UF.ui.settingType.Dropdown,
		height = 180,
		parentId = "utility",
		default = nil,
		generator = function(_, root)
			for _, opt in ipairs(copyOptions) do
				root:CreateRadio(opt.label, function() return false end, function() showCopySettingsPopup(opt.value, unit) end)
			end
		end,
		isEnabled = function() return #copyOptions > 0 end,
	}

	list[#list + 1] = { name = L["Frame"] or "Frame", kind = UF.ui.settingType.Collapsible, id = "frame", defaultCollapsed = true }

	local function isTooltipEnabled() return getValue(unit, { "showTooltip" }, def.showTooltip or false) == true end

	list[#list + 1] = checkbox(L["UFShowTooltip"] or "Show unit tooltip", isTooltipEnabled, function(val)
		setValue(unit, { "showTooltip" }, val and true or false)
		refreshSelf()
		refreshSettingsUI()
	end, def.showTooltip or false, "frame")

	list[#list + 1] = checkbox(
		L["UFTooltipUseEditMode"] or "Use Edit Mode tooltip position",
		function() return getValue(unit, { "tooltipUseEditMode" }, def.tooltipUseEditMode == true) == true end,
		function(val) setValue(unit, { "tooltipUseEditMode" }, val and true or false) end,
		def.tooltipUseEditMode == true,
		"frame",
		isTooltipEnabled
	)
	list[#list + 1] = checkbox(L["Hide in vehicles"] or "Hide in vehicles", isHideInVehicleEnabled, setHideInVehicleEnabled, def.hideInVehicle == true, "frame")

	if #visibilityOptions > 0 then
		list[#list + 1] = {
			name = L["Show when"] or "Show when",
			kind = UF.ui.settingType.MultiDropdown,
			parentId = "frame",
			height = 200,
			hideSummary = true,
			refreshOnSelect = false,
			values = visibilityOptions,
			get = function() return getVisibilityConfig() end,
			set = function(_, selection) setVisibilitySelection(selection) end,
			isSelected = function(_, value) return isVisibilityRuleSelected(value) end,
			setSelected = function(_, value, state) setVisibilityRule(value, state) end,
		}
		if not isBoss then
			list[#list + 1] = slider(L["Fade amount"] or "Fade amount", 0, 100, 1, function()
				local strength = getValue(unit, { "visibilityFadeStrength" }, 1)
				strength = tonumber(strength) or 1
				if strength < 0 then strength = 0 end
				if strength > 1 then strength = 1 end
				return math.floor((strength * 100) + 0.5)
			end, function(val)
				local pct = tonumber(val) or 0
				if pct < 0 then pct = 0 end
				if pct > 100 then pct = 100 end
				setValue(unit, { "visibilityFadeStrength" }, pct / 100)
				if UF.ScheduleEqolVisibilityDriverAlphaRefresh then UF.ScheduleEqolVisibilityDriverAlphaRefresh() end
				refreshSelf()
			end, 100, "frame", true, function(v) return tostring(v) .. "%" end)
		end
	end
	addDivider("frame")

	list[#list + 1] = slider(L["UFWidth"] or "Frame width", MIN_WIDTH, 800, 1, function() return getValue(unit, { "width" }, def.width or MIN_WIDTH) end, function(val)
		setValue(unit, { "width" }, math.max(MIN_WIDTH, val or MIN_WIDTH))
		refreshSelf()
	end, def.width or MIN_WIDTH, "frame", true)

	list[#list + 1] = radioDropdown(L["Anchor to"] or "Anchor to", function() return UnitAnchor.GetOptions(unit) end, function()
		return UnitAnchor.GetTargetValue(unit)
	end, function(val)
		local target = type(val) == "string" and val ~= "" and val or "UIParent"
		if not UnitAnchor.IsKnownTarget(unit, target) then target = "UIParent" end
		if target == UnitAnchor.GetFrameName(unit) then target = "UIParent" end
		if UF and UF.WouldRelativeAnchorLoop and UF.WouldRelativeAnchorLoop(unit, target) then target = "UIParent" end
		local cfg = ensureConfig(unit)
		cfg.anchor = cfg.anchor or {}
		if cfg.anchor.relativeTo == target and cfg.anchor.relativeFrame == target then return end
		cfg.anchor.relativeTo = target
		cfg.anchor.relativeFrame = target
		refreshSelf(true)
		refreshSettingsUI()
	end, (def.anchor and (def.anchor.relativeTo or def.anchor.relativeFrame)) or "UIParent", "frame")
	list[#list].field = "anchorTarget"

	list[#list + 1] = radioDropdown(L["Anchor point"] or "Anchor point", UF.ui.anchorOptions9, function()
		local fallback = (def.anchor and def.anchor.point) or "CENTER"
		return getValue(unit, { "anchor", "point" }, fallback)
	end, function(val)
		setValue(unit, { "anchor", "point" }, val or "CENTER")
		local currentRelative = getValue(unit, { "anchor", "relativePoint" }, nil)
		if not currentRelative then setValue(unit, { "anchor", "relativePoint" }, val or "CENTER") end
		refreshSelf(true)
		refreshSettingsUI()
	end, (def.anchor and def.anchor.point) or "CENTER", "frame")
	list[#list].field = "point"

	list[#list + 1] = radioDropdown(L["Relative point"] or "Relative point", UF.ui.anchorOptions9, function()
		local fallback = (def.anchor and def.anchor.relativePoint) or (def.anchor and def.anchor.point) or "CENTER"
		return getValue(unit, { "anchor", "relativePoint" }, fallback)
	end, function(val)
		setValue(unit, { "anchor", "relativePoint" }, val or "CENTER")
		refreshSelf(true)
		refreshSettingsUI()
	end, (def.anchor and def.anchor.relativePoint) or (def.anchor and def.anchor.point) or "CENTER", "frame")
	list[#list].field = "relativePoint"

	list[#list + 1] = slider(L["Offset X"] or "Offset X", -OFFSET_RANGE, OFFSET_RANGE, 1, function()
		local fallback = def.anchor and def.anchor.x or 0
		local value = getValue(unit, { "anchor", "x" }, fallback)
		return tonumber(value) or 0
	end, function(val)
		setValue(unit, { "anchor", "x" }, tonumber(val) or 0)
		refreshSelf(true)
	end, (def.anchor and def.anchor.x) or 0, "frame", true)
	list[#list].field = "x"

	list[#list + 1] = slider(L["Offset Y"] or "Offset Y", -OFFSET_RANGE, OFFSET_RANGE, 1, function()
		local fallback = def.anchor and def.anchor.y or 0
		local value = getValue(unit, { "anchor", "y" }, fallback)
		return tonumber(value) or 0
	end, function(val)
		setValue(unit, { "anchor", "y" }, tonumber(val) or 0)
		refreshSelf(true)
	end, (def.anchor and def.anchor.y) or 0, "frame", true)
	list[#list].field = "y"

	if addon.DynamicAnchors and addon.DynamicAnchors.AddEditModeAssignmentSettings then
		addon.DynamicAnchors:AddEditModeAssignmentSettings(list, UF.ui.settingType, {
			consumerId = UF.GetDynamicAnchorId(unit),
			parentId = "frame",
			insertAfterId = "frame",
			enabledNewTagID = "ufDynamicAnchorEnabled",
			profileNewTagID = "ufDynamicAnchorProfile",
			refresh = function() refreshSelf(true) end,
			staticFields = {
				anchorTarget = true,
				point = true,
				relativePoint = true,
				x = true,
				y = true,
			},
		})
	end

	if isBoss then UF.ui.appendBossLayoutSettings(list, unit, def, refreshSelf) end
	addDivider("frame")

	list[#list + 1] = radioDropdown(L["Frame strata"] or "Frame strata", UF.ui.strataOptions, function()
		return getValue(unit, { "strata" }, def.strata or UF.ui.defaultStrata or "")
	end, function(val)
		setValue(unit, { "strata" }, val ~= "" and val or nil)
		refreshSelf()
	end, def.strata or UF.ui.defaultStrata or "", "frame")

	list[#list + 1] = slider(L["UFFrameLevel"] or "Frame level", 0, 50, 1, function()
		return getValue(unit, { "frameLevel" }, def.frameLevel or UF.ui.defaultLevel)
	end, function(val)
		debounced(unit .. "_frameLevel", function()
			setValue(unit, { "frameLevel" }, val or UF.ui.defaultLevel)
			refreshSelf()
		end)
	end, def.frameLevel or UF.ui.defaultLevel, "frame", true)

	list[#list + 1] = checkbox(L["Smooth fill"] or "Smooth fill", function() return getValue(unit, { "smoothFill" }, def.smoothFill == true) == true end, function(val)
		setValue(unit, { "smoothFill" }, val and true or false)
		refreshSelf()
	end, def.smoothFill == true, "frame")
	addDivider("frame")

	list[#list + 1] = { name = BORDER_LABEL, kind = UF.ui.settingType.Collapsible, id = "border", defaultCollapsed = true }

	list[#list + 1] = checkboxColor({
		name = L["Show border"] or "Show border",
		parentId = "border",
		defaultChecked = (def.border and def.border.enabled) ~= false,
		isChecked = function()
			local border = getValue(unit, { "border" }, def.border or {})
			return border.enabled ~= false
		end,
		onChecked = function(val)
			local border = getValue(unit, { "border" }, def.border or {})
			border.enabled = val and true or false
			setValue(unit, { "border" }, border)
			refresh()
			refreshSettingsUI()
		end,
		getColor = function()
			local border = getValue(unit, { "border" }, def.border or {})
			return toRGBA(border.color, def.border and def.border.color or { 0, 0, 0, 0.8 })
		end,
		onColor = function(color)
			local border = getValue(unit, { "border" }, def.border or {})
			border.color = { color.r, color.g, color.b, color.a }
			setValue(unit, { "border" }, border)
			refresh()
		end,
		colorDefault = {
			r = (def.border and def.border.color and def.border.color[1]) or 0,
			g = (def.border and def.border.color and def.border.color[2]) or 0,
			b = (def.border and def.border.color and def.border.color[3]) or 0,
			a = (def.border and def.border.color and def.border.color[4]) or 0.8,
		},
	})

	local function isBorderEnabled() return getValue(unit, { "border", "enabled" }, (def.border and def.border.enabled) ~= false) ~= false end

	local borderTexture = checkboxDropdown(L["Border texture"] or "Border texture", borderOptions, function()
		local border = getValue(unit, { "border" }, def.border or {})
		return border.texture or (def.border and def.border.texture) or "DEFAULT"
	end, function(val)
		local border = getValue(unit, { "border" }, def.border or {})
		border.texture = val or "DEFAULT"
		setValue(unit, { "border" }, border)
		refresh()
	end, (def.border and def.border.texture) or "DEFAULT", "border")
	borderTexture.isEnabled = isBorderEnabled
	list[#list + 1] = borderTexture

	local borderSizeSetting = slider(L["Border size"] or "Border size", 1, 64, 1, function()
		local border = getValue(unit, { "border" }, def.border or {})
		return border.edgeSize or 1
	end, function(val)
		debounced(unit .. "_borderEdge", function()
			local border = getValue(unit, { "border" }, def.border or {})
			border.edgeSize = val or 1
			setValue(unit, { "border" }, border)
			refresh()
		end)
	end, max(1, (def.border and def.border.edgeSize) or 1), "border", true)
	borderSizeSetting.isEnabled = isBorderEnabled
	list[#list + 1] = borderSizeSetting

	local borderOffsetSetting = slider(L["Border offset"] or "Border offset", 0, 64, 1, function()
		local border = getValue(unit, { "border" }, def.border or {})
		if border.offset == nil then return border.edgeSize or 1 end
		return border.offset
	end, function(val)
		debounced(unit .. "_borderOffset", function()
			local border = getValue(unit, { "border" }, def.border or {})
			border.offset = val or 0
			setValue(unit, { "border" }, border)
			refresh()
		end)
	end, (def.border and def.border.offset) or (def.border and def.border.edgeSize) or 1, "border", true)
	borderOffsetSetting.isEnabled = isBorderEnabled
	list[#list + 1] = borderOffsetSetting
	addDivider("border")

	local highlightDef = def.highlight or {}
	list[#list + 1] = { name = L["Highlight"] or "Highlight", kind = UF.ui.settingType.Collapsible, id = "highlight", defaultCollapsed = true }
	list[#list + 1] = checkboxColor({
		name = L["UFHighlightBorder"] or "Highlight border",
		parentId = "highlight",
		defaultChecked = highlightDef.enabled == true,
		isChecked = function() return getValue(unit, { "highlight", "enabled" }, highlightDef.enabled == true) == true end,
		onChecked = function(val)
			local highlight = getValue(unit, { "highlight" }, highlightDef)
			highlight.enabled = val and true or false
			setValue(unit, { "highlight" }, highlight)
			refresh()
			refreshSettingsUI()
		end,
		getColor = function()
			local highlight = getValue(unit, { "highlight" }, highlightDef)
			return toRGBA(highlight.color, highlightDef.color or { 1, 0, 0, 1 })
		end,
		onColor = function(color)
			local highlight = getValue(unit, { "highlight" }, highlightDef)
			highlight.color = { color.r, color.g, color.b, color.a }
			setValue(unit, { "highlight" }, highlight)
			refresh()
		end,
		colorDefault = {
			r = (highlightDef.color and highlightDef.color[1]) or 1,
			g = (highlightDef.color and highlightDef.color[2]) or 0,
			b = (highlightDef.color and highlightDef.color[3]) or 0,
			a = (highlightDef.color and highlightDef.color[4]) or 1,
		},
	})

	local function isHighlightEnabled() return getValue(unit, { "highlight", "enabled" }, highlightDef.enabled == true) == true end
	local function isHighlightAggroEnabled() return isHighlightEnabled() and (isPlayer or isPet) end
	local function isHighlightCombatEnabled() return isHighlightEnabled() and isPlayer and (getValue(unit, { "highlight", "combat" }, highlightDef.combat == true) == true) end
	local function isHighlightMouseoverEnabled() return isHighlightEnabled() and (getValue(unit, { "highlight", "mouseover" }, highlightDef.mouseover ~= false) == true) end

	list[#list + 1] = checkbox(
		L["UFHighlightMouseover"] or "Highlight on mouseover",
		function() return getValue(unit, { "highlight", "mouseover" }, highlightDef.mouseover ~= false) == true end,
		function(val)
			setValue(unit, { "highlight", "mouseover" }, val and true or false)
			refresh()
		end,
		highlightDef.mouseover ~= false,
		"highlight",
		isHighlightEnabled
	)

	list[#list + 1] = {
		name = L["UFHighlightMouseoverColor"] or "Mouseover color",
		kind = UF.ui.settingType.Color,
		parentId = "highlight",
		hasOpacity = true,
		default = highlightDef.mouseoverColor or highlightDef.color or { 1, 0, 0, 1 },
		get = function() return getValue(unit, { "highlight", "mouseoverColor" }, highlightDef.mouseoverColor or highlightDef.color or { 1, 0, 0, 1 }) end,
		set = function(_, color)
			setColor(unit, { "highlight", "mouseoverColor" }, color.r, color.g, color.b, color.a)
			refresh()
		end,
		colorGet = function()
			local color = getValue(unit, { "highlight", "mouseoverColor" }, highlightDef.mouseoverColor or highlightDef.color or { 1, 0, 0, 1 })
			local r, g, b, a = toRGBA(color, highlightDef.mouseoverColor or highlightDef.color or { 1, 0, 0, 1 })
			return { r = r, g = g, b = b, a = a }
		end,
		colorSet = function(_, color)
			setColor(unit, { "highlight", "mouseoverColor" }, color.r, color.g, color.b, color.a)
			refresh()
		end,
		colorDefault = {
			r = select(1, toRGBA(highlightDef.mouseoverColor or highlightDef.color, { 1, 0, 0, 1 })),
			g = select(2, toRGBA(highlightDef.mouseoverColor or highlightDef.color, { 1, 0, 0, 1 })),
			b = select(3, toRGBA(highlightDef.mouseoverColor or highlightDef.color, { 1, 0, 0, 1 })),
			a = select(4, toRGBA(highlightDef.mouseoverColor or highlightDef.color, { 1, 0, 0, 1 })),
		},
		isEnabled = isHighlightMouseoverEnabled,
	}

	list[#list + 1] = checkbox(
		L["Enable target highlight"] or "Enable target highlight",
		function() return getValue(unit, { "highlight", "target" }, highlightDef.target == true) == true end,
		function(val)
			setValue(unit, { "highlight", "target" }, val and true or false)
			refresh()
		end,
		highlightDef.target == true,
		"highlight",
		isHighlightEnabled
	)

	if isPlayer or isPet then
		list[#list + 1] = checkbox(L["UFHighlightAggro"] or "Highlight on aggro", function() return getValue(unit, { "highlight", "aggro" }, highlightDef.aggro ~= false) == true end, function(val)
			setValue(unit, { "highlight", "aggro" }, val and true or false)
			refresh()
		end, highlightDef.aggro ~= false, "highlight", isHighlightAggroEnabled)
	end

	if isPlayer then
		list[#list + 1] = checkbox(
			L["UFHighlightCombat"] or "Highlight in combat",
			function() return getValue(unit, { "highlight", "combat" }, highlightDef.combat == true) == true end,
			function(val)
				setValue(unit, { "highlight", "combat" }, val and true or false)
				refresh()
			end,
			highlightDef.combat == true,
			"highlight",
			isHighlightEnabled
		)

		list[#list + 1] = {
			name = L["UFHighlightCombatColor"] or "Combat color",
			kind = UF.ui.settingType.Color,
			parentId = "highlight",
			hasOpacity = true,
			default = highlightDef.combatColor or highlightDef.color or { 1, 0, 0, 1 },
			get = function() return getValue(unit, { "highlight", "combatColor" }, highlightDef.combatColor or highlightDef.color or { 1, 0, 0, 1 }) end,
			set = function(_, color)
				setColor(unit, { "highlight", "combatColor" }, color.r, color.g, color.b, color.a)
				refresh()
			end,
			colorGet = function()
				local color = getValue(unit, { "highlight", "combatColor" }, highlightDef.combatColor or highlightDef.color or { 1, 0, 0, 1 })
				local r, g, b, a = toRGBA(color, highlightDef.combatColor or highlightDef.color or { 1, 0, 0, 1 })
				return { r = r, g = g, b = b, a = a }
			end,
			colorSet = function(_, color)
				setColor(unit, { "highlight", "combatColor" }, color.r, color.g, color.b, color.a)
				refresh()
			end,
			colorDefault = {
				r = select(1, toRGBA(highlightDef.combatColor or highlightDef.color, { 1, 0, 0, 1 })),
				g = select(2, toRGBA(highlightDef.combatColor or highlightDef.color, { 1, 0, 0, 1 })),
				b = select(3, toRGBA(highlightDef.combatColor or highlightDef.color, { 1, 0, 0, 1 })),
				a = select(4, toRGBA(highlightDef.combatColor or highlightDef.color, { 1, 0, 0, 1 })),
			},
			isEnabled = isHighlightCombatEnabled,
		}
	end

	local highlightTexture = checkboxDropdown(
		L["UFHighlightTexture"] or "Highlight texture",
		borderOptions,
		function() return getValue(unit, { "highlight", "texture" }, highlightDef.texture or "DEFAULT") end,
		function(val)
			setValue(unit, { "highlight", "texture" }, val or "DEFAULT")
			refresh()
		end,
		highlightDef.texture or "DEFAULT",
		"highlight"
	)
	highlightTexture.isEnabled = isHighlightEnabled
	list[#list + 1] = highlightTexture

	local highlightStrata = radioDropdown(
		L["Frame strata"] or "Frame strata",
		UF.ui.strataOptionsWithDefault,
		function() return getValue(unit, { "highlight", "strata" }, highlightDef.strata or "") or "" end,
		function(val)
			setValue(unit, { "highlight", "strata" }, val ~= "" and val or nil)
			refresh()
		end,
		highlightDef.strata or "",
		"highlight"
	)
	highlightStrata.isEnabled = isHighlightEnabled
	list[#list + 1] = highlightStrata

	local highlightSizeSetting = slider(L["UFHighlightSize"] or "Highlight size", 1, 64, 1, function() return getValue(unit, { "highlight", "size" }, highlightDef.size or 2) end, function(val)
		debounced(unit .. "_highlightSize", function()
			setValue(unit, { "highlight", "size" }, val or highlightDef.size or 2)
			refresh()
		end)
	end, highlightDef.size or 2, "highlight", true)
	highlightSizeSetting.isEnabled = isHighlightEnabled
	list[#list + 1] = highlightSizeSetting
	addDivider("highlight")

	local portraitDef = def.portrait or {}
	list[#list + 1] = { name = L["Portrait"] or "Portrait", kind = UF.ui.settingType.Collapsible, id = "portrait", defaultCollapsed = true }
	local function isPortraitEnabled() return getValue(unit, { "portrait", "enabled" }, portraitDef.enabled == true) == true end
	local function isPortraitDetached() return getValue(unit, { "portrait", "detached" }, portraitDef.detached == true) == true end
	local function isDetachedPortraitEnabled() return isPortraitEnabled() and isPortraitDetached() end
	local function isDetachedPortraitBorderEnabled()
		return getValue(unit, { "portrait", "detachedBorderEnabled" }, portraitDef.detachedBorderEnabled ~= false) ~= false
	end

	list[#list + 1] = checkbox(L["Enable portrait"] or "Enable portrait", isPortraitEnabled, function(val)
		setValue(unit, { "portrait", "enabled" }, val and true or false)
		refreshSelf()
		refreshSettingsUI()
	end, portraitDef.enabled == true, "portrait")

	local portraitModeOptions = {
		{ value = "PORTRAIT", label = L["UFPortraitModePortrait"] or "Portrait" },
		{ value = "CLASS_ICON", label = L["UFPortraitModeClassIcon"] or "Class icon" },
	}
	local portraitMode = radioDropdown(
		L["UFPortraitMode"] or "Portrait mode",
		portraitModeOptions,
		function()
			local mode = tostring(getValue(unit, { "portrait", "mode" }, portraitDef.mode or "PORTRAIT") or "PORTRAIT"):upper()
			if mode ~= "CLASS_ICON" then mode = "PORTRAIT" end
			return mode
		end,
		function(val)
			local mode = tostring(val or "PORTRAIT"):upper()
			if mode ~= "CLASS_ICON" then mode = "PORTRAIT" end
			setValue(unit, { "portrait", "mode" }, mode)
			refreshSelf()
		end,
		portraitDef.mode or "PORTRAIT",
		"portrait"
	)
	portraitMode.isEnabled = isPortraitEnabled
	list[#list + 1] = portraitMode

	list[#list + 1] = radioDropdown(
		L["settingsIconShapeLabel"] or "Icon shape",
		UF.GetPortraitShapeOptions(),
		function() return UF.NormalizePortraitShape(getValue(unit, { "portrait", "shape" }, portraitDef.shape or "SQUARE")) end,
		function(val)
			setValue(unit, { "portrait", "shape" }, UF.NormalizePortraitShape(val))
			refreshSelf()
		end,
		UF.NormalizePortraitShape(portraitDef.shape),
		"portrait"
	)
	list[#list].isEnabled = isPortraitEnabled
	list[#list].newTagID = "ufPortraitShape"

	local portraitSideOptions = {
		{ value = "LEFT", label = HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_LEFT or "Left" },
		{ value = "RIGHT", label = HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_RIGHT or "Right" },
	}
	local portraitSide = radioDropdown(
		L["Portrait side"] or "Portrait side",
		portraitSideOptions,
		function() return (getValue(unit, { "portrait", "side" }, portraitDef.side or "LEFT") or "LEFT"):upper() end,
		function(val)
			setValue(unit, { "portrait", "side" }, (val or "LEFT"):upper())
			refreshSelf()
		end,
		(portraitDef.side or "LEFT"):upper(),
		"portrait"
	)
	portraitSide.isEnabled = function() return isPortraitEnabled() and not isPortraitDetached() end
	list[#list + 1] = portraitSide

	local portraitDetached = checkbox(L["UFPortraitDetached"] or "Detach portrait", isPortraitDetached, function(val)
		setValue(unit, { "portrait", "detached" }, val and true or false)
		refreshSelf()
		refreshSettingsUI()
	end, portraitDef.detached == true, "portrait", isPortraitEnabled)
	portraitDetached.newTagID = "ufPortraitDetached"
	list[#list + 1] = portraitDetached

	local portraitDetachedSize = slider(L["Size"] or "Size", 8, 200, 1, function()
		local size = getValue(unit, { "portrait", "detachedSize" }, nil)
		if size ~= nil then return size end
		return UF.GetDefaultDetachedPortraitSize(ensureConfig(unit), unit)
	end, function(val)
		debounced(unit .. "_portraitDetachedSize", function()
			setValue(unit, { "portrait", "detachedSize" }, val or UF.GetDefaultDetachedPortraitSize(ensureConfig(unit), unit))
			refreshSelf()
		end)
	end, portraitDef.detachedSize or UF.GetDefaultDetachedPortraitSize(ensureConfig(unit), unit), "portrait", true)
	portraitDetachedSize.isEnabled = isDetachedPortraitEnabled
	portraitDetachedSize.isShown = isPortraitDetached
	portraitDetachedSize.newTagID = "ufPortraitDetachedSize"
	list[#list + 1] = portraitDetachedSize

	local portraitDetachedBorder = checkbox(L["Show border"] or "Show border", isDetachedPortraitBorderEnabled, function(val)
		setValue(unit, { "portrait", "detachedBorderEnabled" }, val and true or false)
		refreshSelf()
	end, portraitDef.detachedBorderEnabled ~= false, "portrait")
	portraitDetachedBorder.isEnabled = function() return isDetachedPortraitEnabled() and isBorderEnabled() end
	portraitDetachedBorder.isShown = isPortraitDetached
	portraitDetachedBorder.newTagID = "ufPortraitDetachedBorderEnabled"
	list[#list + 1] = portraitDetachedBorder

	local portraitDetachedBorderOffset = slider(L["Border offset"] or "Border offset", 0, 64, 1, function()
		local offset = getValue(unit, { "portrait", "detachedBorderOffset" }, nil)
		if offset ~= nil then return offset end
		local border = getValue(unit, { "border" }, def.border or {})
		return border.offset or (def.border and def.border.offset) or border.inset or (def.border and def.border.inset) or border.edgeSize or (def.border and def.border.edgeSize) or 1
	end, function(val)
		debounced(unit .. "_portraitDetachedBorderOffset", function()
			setValue(unit, { "portrait", "detachedBorderOffset" }, val or 0)
			refreshSelf()
		end)
	end, (def.border and (def.border.offset or def.border.inset or def.border.edgeSize)) or 1, "portrait", true)
	portraitDetachedBorderOffset.isEnabled = function() return isDetachedPortraitEnabled() and isBorderEnabled() and isDetachedPortraitBorderEnabled() end
	portraitDetachedBorderOffset.isShown = isPortraitDetached
	portraitDetachedBorderOffset.newTagID = "ufPortraitDetachedBorderOffset"
	list[#list + 1] = portraitDetachedBorderOffset

	local portraitDetachedOffsetX = slider(L["Offset X"] or "Offset X", -OFFSET_RANGE, OFFSET_RANGE, 1, function()
		local offset = getValue(unit, { "portrait", "detachedOffset", "x" }, nil)
		if offset ~= nil then return offset end
		local size = getValue(unit, { "portrait", "detachedSize" }, nil) or UF.GetDefaultDetachedPortraitSize(ensureConfig(unit), unit)
		local x = UF.GetDefaultDetachedPortraitOffset(ensureConfig(unit), unit, nil, size)
		return x
	end, function(val)
		debounced(unit .. "_portraitDetachedOffsetX", function()
			setValue(unit, { "portrait", "detachedOffset", "x" }, val or 0)
			refreshSelf()
		end)
	end, select(1, UF.GetDefaultDetachedPortraitOffset(ensureConfig(unit), unit)), "portrait", true)
	portraitDetachedOffsetX.isEnabled = isDetachedPortraitEnabled
	portraitDetachedOffsetX.isShown = isPortraitDetached
	portraitDetachedOffsetX.newTagID = "ufPortraitDetachedOffsetX"
	list[#list + 1] = portraitDetachedOffsetX

	local portraitDetachedOffsetY = slider(L["Offset Y"] or "Offset Y", -OFFSET_RANGE, OFFSET_RANGE, 1, function()
		local offset = getValue(unit, { "portrait", "detachedOffset", "y" }, nil)
		if offset ~= nil then return offset end
		local size = getValue(unit, { "portrait", "detachedSize" }, nil) or UF.GetDefaultDetachedPortraitSize(ensureConfig(unit), unit)
		local _, y = UF.GetDefaultDetachedPortraitOffset(ensureConfig(unit), unit, nil, size)
		return y
	end, function(val)
		debounced(unit .. "_portraitDetachedOffsetY", function()
			setValue(unit, { "portrait", "detachedOffset", "y" }, val or 0)
			refreshSelf()
		end)
	end, select(2, UF.GetDefaultDetachedPortraitOffset(ensureConfig(unit), unit)), "portrait", true)
	portraitDetachedOffsetY.isEnabled = isDetachedPortraitEnabled
	portraitDetachedOffsetY.isShown = isPortraitDetached
	portraitDetachedOffsetY.newTagID = "ufPortraitDetachedOffsetY"
	list[#list + 1] = portraitDetachedOffsetY

	local portraitDetachedStrata = radioDropdown(
		L["UFDetachedPowerStrata"] or "Strata",
		UF.ui.strataOptionsWithDefault,
		function() return getValue(unit, { "portrait", "detachedStrata" }, portraitDef.detachedStrata or "") or "" end,
		function(val)
			setValue(unit, { "portrait", "detachedStrata" }, val ~= "" and val or nil)
			refreshSelf()
		end,
		portraitDef.detachedStrata or "",
		"portrait"
	)
	portraitDetachedStrata.isEnabled = isDetachedPortraitEnabled
	portraitDetachedStrata.isShown = isPortraitDetached
	portraitDetachedStrata.newTagID = "ufPortraitDetachedStrata"
	list[#list + 1] = portraitDetachedStrata

	local portraitDetachedFrameLevel = slider(
		L["UFDetachedPowerLevelOffset"] or "Frame level offset",
		-20,
		1000,
		1,
		function() return getValue(unit, { "portrait", "detachedFrameLevelOffset" }, portraitDef.detachedFrameLevelOffset or 1) end,
		function(val)
			debounced(unit .. "_portraitDetachedFrameLevel", function()
				setValue(unit, { "portrait", "detachedFrameLevelOffset" }, val or portraitDef.detachedFrameLevelOffset or 1)
				refreshSelf()
			end)
		end,
		portraitDef.detachedFrameLevelOffset or 1,
		"portrait",
		true
	)
	portraitDetachedFrameLevel.isEnabled = isDetachedPortraitEnabled
	portraitDetachedFrameLevel.isShown = isPortraitDetached
	portraitDetachedFrameLevel.newTagID = "ufPortraitDetachedFrameLevel"
	list[#list + 1] = portraitDetachedFrameLevel

	local portraitSquareBackground = checkbox(
		L["Force square background"] or "Force square background",
		function() return getValue(unit, { "portrait", "squareBackground" }, portraitDef.squareBackground == true) == true end,
		function(val)
			setValue(unit, { "portrait", "squareBackground" }, val and true or false)
			refreshSelf()
		end,
		portraitDef.squareBackground == true,
		"portrait"
	)
	portraitSquareBackground.isEnabled = isPortraitEnabled
	list[#list + 1] = portraitSquareBackground

	local portraitSeparatorDef = portraitDef.separator or {}
	local function isPortraitSeparatorEnabled()
		local enabled = getValue(unit, { "portrait", "separator", "enabled" }, portraitSeparatorDef.enabled)
		if enabled == nil then enabled = true end
		return enabled == true
	end

	list[#list + 1] = checkbox(L["UFPortraitSeparatorEnable"] or "Show portrait separator", isPortraitSeparatorEnabled, function(val)
		setValue(unit, { "portrait", "separator", "enabled" }, val and true or false)
		refreshSelf()
	end, portraitSeparatorDef.enabled ~= false, "portrait")
	list[#list].isEnabled = function() return isPortraitEnabled() and not isPortraitDetached() end

	local portraitSeparatorSize = slider(L["Separator size"] or "Separator size", 1, 64, 1, function()
		local size = getValue(unit, { "portrait", "separator", "size" }, portraitSeparatorDef.size)
		if not size or size <= 0 then
			local border = getValue(unit, { "border" }, def.border or {})
			size = border.edgeSize or 1
		end
		return size
	end, function(val)
		setValue(unit, { "portrait", "separator", "size" }, val or 1)
		refreshSelf()
	end, portraitSeparatorDef.size or (def.border and def.border.edgeSize) or 1, "portrait", true)
	portraitSeparatorSize.isEnabled = function() return isPortraitEnabled() and not isPortraitDetached() and isPortraitSeparatorEnabled() end
	list[#list + 1] = portraitSeparatorSize

	local portraitSeparatorTexture = radioDropdown(
		L["UFPortraitSeparatorTexture"] or "Separator texture",
		textureOptions,
		function() return getValue(unit, { "portrait", "separator", "texture" }, portraitSeparatorDef.texture or "SOLID") or "SOLID" end,
		function(val)
			setValue(unit, { "portrait", "separator", "texture" }, val or "SOLID")
			refreshSelf()
		end,
		portraitSeparatorDef.texture or "SOLID",
		"portrait"
	)
	portraitSeparatorTexture.isEnabled = function() return isPortraitEnabled() and not isPortraitDetached() and isPortraitSeparatorEnabled() end
	list[#list + 1] = portraitSeparatorTexture

	local portraitSeparatorColor = checkboxColor({
		name = L["Separator color"] or "Separator color",
		parentId = "portrait",
		defaultChecked = portraitSeparatorDef.useCustomColor == true,
		isChecked = function() return getValue(unit, { "portrait", "separator", "useCustomColor" }, portraitSeparatorDef.useCustomColor == true) == true end,
		onChecked = function(val)
			setValue(unit, { "portrait", "separator", "useCustomColor" }, val and true or false)
			if val and not getValue(unit, { "portrait", "separator", "color" }) then
				local border = getValue(unit, { "border" }, def.border or {})
				local fallback = border.color or (def.border and def.border.color) or { 0, 0, 0, 0.8 }
				setValue(unit, { "portrait", "separator", "color" }, { fallback[1] or 0, fallback[2] or 0, fallback[3] or 0, fallback[4] or 0.8 })
			end
			refreshSelf()
		end,
		getColor = function()
			local border = getValue(unit, { "border" }, def.border or {})
			local fallback = border.color or (def.border and def.border.color) or { 0, 0, 0, 0.8 }
			return toRGBA(getValue(unit, { "portrait", "separator", "color" }, portraitSeparatorDef.color or fallback), portraitSeparatorDef.color or fallback)
		end,
		onColor = function(color)
			setColor(unit, { "portrait", "separator", "color" }, color.r, color.g, color.b, color.a)
			setValue(unit, { "portrait", "separator", "useCustomColor" }, true)
			refreshSelf()
		end,
		colorDefault = {
			r = (portraitSeparatorDef.color and portraitSeparatorDef.color[1]) or (def.border and def.border.color and def.border.color[1]) or 0,
			g = (portraitSeparatorDef.color and portraitSeparatorDef.color[2]) or (def.border and def.border.color and def.border.color[2]) or 0,
			b = (portraitSeparatorDef.color and portraitSeparatorDef.color[3]) or (def.border and def.border.color and def.border.color[3]) or 0,
			a = (portraitSeparatorDef.color and portraitSeparatorDef.color[4]) or (def.border and def.border.color and def.border.color[4]) or 0.8,
		},
	})
	portraitSeparatorColor.isEnabled = function() return isPortraitEnabled() and not isPortraitDetached() and isPortraitSeparatorEnabled() end
	list[#list + 1] = portraitSeparatorColor

	if unit == "target" or unit == "boss" then
		local rangeDef = def.rangeFade or {}
		local function isRangeFadeEnabled() return getValue(unit, { "rangeFade", "enabled" }, rangeDef.enabled == true) == true end
		local function refreshRangeFadeRuntime(rebuildSpellList, applyCurrent)
			if unit == "boss" then
				if UF.RefreshBossRangeFade then UF.RefreshBossRangeFade() end
				return
			end
			if not UFHelper then return end
			if UFHelper.RangeFadeMarkConfigDirty then UFHelper.RangeFadeMarkConfigDirty() end
			if rebuildSpellList and UFHelper.RangeFadeMarkSpellListDirty then UFHelper.RangeFadeMarkSpellListDirty() end
			if applyCurrent and UFHelper.RangeFadeApplyCurrent then UFHelper.RangeFadeApplyCurrent(true) end
			if UFHelper.RangeFadeUpdateSpells then UFHelper.RangeFadeUpdateSpells() end
		end

		list[#list + 1] = { name = L["UFRangeFade"] or "Range fade", kind = UF.ui.settingType.Collapsible, id = "rangeFade", defaultCollapsed = true }

		local rangeFadeEnabled = checkbox(L["UFRangeFadeEnable"] or "Enable range fade", isRangeFadeEnabled, function(val)
			setValue(unit, { "rangeFade", "enabled" }, val and true or false)
			refreshSelf()
			refreshRangeFadeRuntime(true, false)
		end, rangeDef.enabled == true, "rangeFade")
		if unit == "boss" then rangeFadeEnabled.newTagID = "ufBossRangeFade" end
		list[#list + 1] = rangeFadeEnabled

		local rangeFadeAlpha = slider(L["UFRangeFadeAlpha"] or "Out of range opacity", 0, 100, 1, function()
			local alpha = getValue(unit, { "rangeFade", "alpha" }, rangeDef.alpha or 0.5)
			if type(alpha) ~= "number" then alpha = 0.5 end
			if alpha < 0 then alpha = 0 end
			if alpha > 1 then alpha = 1 end
			return math.floor((alpha * 100) + 0.5)
		end, function(val)
			local pct = tonumber(val) or 0
			if pct < 0 then pct = 0 end
			if pct > 100 then pct = 100 end
			setValue(unit, { "rangeFade", "alpha" }, pct / 100)
			refreshSelf()
			refreshRangeFadeRuntime(false, true)
		end, math.floor(((rangeDef.alpha or 0.5) * 100) + 0.5), "rangeFade", true, function(v) return tostring(v) .. "%" end)
		rangeFadeAlpha.isEnabled = isRangeFadeEnabled
		list[#list + 1] = rangeFadeAlpha

		list[#list + 1] = createRangeFadeSpellPickerSetting(unit, isRangeFadeEnabled, refreshSelf, refreshRangeFadeRuntime)
	end

	UF.ui.appendDataBarSettings(list, unit, def, refresh, refreshSelf, addDivider)
	list[#list + 1] = { name = L["Health"] or HEALTH or "Health", kind = UF.ui.settingType.Collapsible, id = "health", defaultCollapsed = true }

	list[#list + 1] = slider(L["UFHealthHeight"] or "Health height", 8, 80, 1, function() return getValue(unit, { "healthHeight" }, def.healthHeight or 24) end, function(val)
		setValue(unit, { "healthHeight" }, val or def.healthHeight or 24)
		refresh()
	end, def.healthHeight or 24, "health", true)

	local healthDef = def.health or {}

	if not isBoss then
		list[#list + 1] = checkbox(
			L["Use class color (players)"] or "Use class color (players)",
			function() return getValue(unit, { "health", "useClassColor" }, healthDef.useClassColor == true) == true end,
			function(val)
				setValue(unit, { "health", "useClassColor" }, val and true or false)
				if val then setValue(unit, { "health", "useCustomColor" }, false) end
				refreshSelf()
				refreshSettingsUI()
			end,
			healthDef.useClassColor == true,
			"health",
			function() return getValue(unit, { "health", "useCustomColor" }, healthDef.useCustomColor == true) ~= true end
		)
	end

	list[#list + 1] = checkboxColor({
		name = L["Custom health color"] or "Custom health color",
		parentId = "health",
		defaultChecked = healthDef.useCustomColor == true,
		isChecked = function() return getValue(unit, { "health", "useCustomColor" }, healthDef.useCustomColor == true) == true end,
		onChecked = function(val)
			local useCustom = val and true or false
			setValue(unit, { "health", "useCustomColor" }, useCustom)
			if useCustom then setValue(unit, { "health", "useClassColor" }, false) end
			if useCustom and not getValue(unit, { "health", "color" }) then setValue(unit, { "health", "color" }, healthDef.color or { 0.0, 0.8, 0.0, 1 }) end
			refreshSelf()
			refreshSettingsUI()
		end,
		getColor = function() return toRGBA(getValue(unit, { "health", "color" }, healthDef.color or { 0.0, 0.8, 0.0, 1 }), healthDef.color or { 0.0, 0.8, 0.0, 1 }) end,
		onColor = function(color)
			setColor(unit, { "health", "color" }, color.r, color.g, color.b, color.a)
			setValue(unit, { "health", "useCustomColor" }, true)
			setValue(unit, { "health", "useClassColor" }, false)
			refreshSelf()
		end,
		colorDefault = {
			r = (healthDef.color and healthDef.color[1]) or 0.0,
			g = (healthDef.color and healthDef.color[2]) or 0.8,
			b = (healthDef.color and healthDef.color[3]) or 0.0,
			a = (healthDef.color and healthDef.color[4]) or 1,
		},
		isEnabled = function() return getValue(unit, { "health", "useClassColor" }, healthDef.useClassColor == true) ~= true end,
	})

	local function isHealthPercentCurveEnabled() return getValue(unit, { "health", "usePercentColorCurve" }, healthDef.usePercentColorCurve == true) == true end

	local MAX_HEALTH_GRADIENT_POINTS = 5
	local healthGradientPointDefaults = {
		{ percent = 0, color = healthDef.percentColorCurveLowColor or { 0.9, 0.0, 0.0, 1 } },
		{ percent = healthDef.percentColorCurveMidpoint or 60, color = healthDef.percentColorCurveMidColor or { 0.9, 0.9, 0.0, 1 } },
		{ percent = 80, color = { 0.6, 0.85, 0.0, 1 } },
		{ percent = 40, color = { 0.95, 0.6, 0.0, 1 } },
		{ percent = 20, color = { 0.95, 0.25, 0.0, 1 } },
	}

	local configuredGradientPoints = healthDef.percentColorCurvePoints
	if type(configuredGradientPoints) == "table" then
		for i = 1, MAX_HEALTH_GRADIENT_POINTS do
			local src = configuredGradientPoints[i]
			if type(src) == "table" then
				local target = healthGradientPointDefaults[i] or {}
				local pct = tonumber(src.percent or src[1])
				if pct then target.percent = pct end
				local col = src.color or src[2]
				if col == nil and src.percent == nil and src[1] ~= nil and src[2] ~= nil and src[3] ~= nil then col = src end
				if col then target.color = col end
				healthGradientPointDefaults[i] = target
			end
		end
	end

	local function clampGradientPercent(value)
		local pct = tonumber(value)
		if pct == nil then return nil end
		if pct < 0 then pct = 0 end
		if pct > 99 then pct = 99 end
		return pct
	end

	local function normalizeGradientPointColor(color, fallback)
		local r, g, b, a = toRGBA(color, fallback)
		return { r or 1, g or 1, b or 1, a or 1 }
	end

	local function getDefaultGradientPoint(index)
		local fallback = healthGradientPointDefaults[index] or healthGradientPointDefaults[#healthGradientPointDefaults] or { percent = 0, color = { 0.9, 0.0, 0.0, 1 } }
		local percent = clampGradientPercent(fallback.percent) or 0
		local color = normalizeGradientPointColor(fallback.color, { 0.9, 0.0, 0.0, 1 })
		return percent, color
	end

	local function countGradientPoints(points)
		if type(points) ~= "table" then return 0 end
		local count = 0
		for i = 1, MAX_HEALTH_GRADIENT_POINTS do
			if type(points[i]) == "table" then count = i end
		end
		return count
	end

	local function getHealthGradientPointCount()
		local fallbackCount = tonumber(healthDef.percentColorCurvePointCount)
		local configuredCount = countGradientPoints(healthDef.percentColorCurvePoints)
		if (not fallbackCount or fallbackCount <= 0) and configuredCount > 0 then fallbackCount = configuredCount end
		if not fallbackCount or fallbackCount <= 0 then fallbackCount = 2 end
		local stored = tonumber(getValue(unit, { "health", "percentColorCurvePointCount" }, fallbackCount))
		if stored == nil or stored <= 0 then stored = fallbackCount end
		if stored > MAX_HEALTH_GRADIENT_POINTS then stored = MAX_HEALTH_GRADIENT_POINTS end
		return floor(stored + 0.5)
	end

	local function ensureHealthGradientPoint(index)
		local defaultPercent, defaultColor = getDefaultGradientPoint(index)
		if getValue(unit, { "health", "percentColorCurvePoints", index, "percent" }) == nil then setValue(unit, { "health", "percentColorCurvePoints", index, "percent" }, defaultPercent) end
		if getValue(unit, { "health", "percentColorCurvePoints", index, "color" }) == nil then setValue(unit, { "health", "percentColorCurvePoints", index, "color" }, defaultColor) end
	end

	list[#list + 1] = checkbox(L["UFHealthPercentGradient"] or "Use health percent gradient", isHealthPercentCurveEnabled, function(val)
		local enabled = val and true or false
		setValue(unit, { "health", "usePercentColorCurve" }, enabled)
		if enabled then
			if getValue(unit, { "health", "percentColorCurveType" }) == nil then setValue(unit, { "health", "percentColorCurveType" }, healthDef.percentColorCurveType or "COSINE") end
			local count = getHealthGradientPointCount()
			setValue(unit, { "health", "percentColorCurvePointCount" }, count)
			for i = 1, count do
				ensureHealthGradientPoint(i)
			end
		end
		refreshSelf()
		refreshSettingsUI()
	end, healthDef.usePercentColorCurve == true, "health")

	local healthCurveTypeOptions = {
		{ value = "COSINE", label = L["UFCurveTypeCosine"] or "Cosine" },
		{ value = "LINEAR", label = L["UFCurveTypeLinear"] or "Linear" },
		{ value = "STEP", label = L["UFCurveTypeStep"] or "Step" },
	}
	local healthCurveType = radioDropdown(
		L["UFHealthGradientCurveType"] or "Gradient curve type",
		healthCurveTypeOptions,
		function() return tostring(getValue(unit, { "health", "percentColorCurveType" }, healthDef.percentColorCurveType or "COSINE")):upper() end,
		function(val)
			setValue(unit, { "health", "percentColorCurveType" }, (val or "COSINE"):upper())
			refreshSelf()
		end,
		healthDef.percentColorCurveType or "COSINE",
		"health"
	)
	healthCurveType.isEnabled = isHealthPercentCurveEnabled
	list[#list + 1] = healthCurveType

	local healthCurvePointCountOptions = {
		{ value = 1, label = "1" },
		{ value = 2, label = "2" },
		{ value = 3, label = "3" },
		{ value = 4, label = "4" },
		{ value = 5, label = "5" },
	}
	local healthCurvePointCount = radioDropdown(L["UFHealthGradientPointCount"] or "Gradient points", healthCurvePointCountOptions, function() return getHealthGradientPointCount() end, function(val)
		local count = floor(tonumber(val) or 2)
		if count < 1 then count = 1 end
		if count > MAX_HEALTH_GRADIENT_POINTS then count = MAX_HEALTH_GRADIENT_POINTS end
		setValue(unit, { "health", "percentColorCurvePointCount" }, count)
		for i = 1, count do
			ensureHealthGradientPoint(i)
		end
		refreshSelf()
		refreshSettingsUI()
	end, getHealthGradientPointCount(), "health")
	healthCurvePointCount.isEnabled = isHealthPercentCurveEnabled
	list[#list + 1] = healthCurvePointCount

	for i = 1, MAX_HEALTH_GRADIENT_POINTS do
		local pointColorName = string.format(L["Point %d color"] or "Point %d color", i)
		local pointPercentName = string.format(L["UFHealthGradientPointPercent"] or "Point %d percent", i)

		local pointPercent = slider(pointPercentName, 0, 99, 1, function()
			local defaultPercent = getDefaultGradientPoint(i)
			local value = clampGradientPercent(getValue(unit, { "health", "percentColorCurvePoints", i, "percent" }, defaultPercent))
			if value == nil then value = defaultPercent end
			return value
		end, function(val)
			local pct = clampGradientPercent(val)
			if pct == nil then pct = getDefaultGradientPoint(i) end
			setValue(unit, { "health", "percentColorCurvePoints", i, "percent" }, pct)
			refreshSelf()
		end, getDefaultGradientPoint(i), "health", true, function(v) return tostring(v) .. "%" end)
		pointPercent.isEnabled = isHealthPercentCurveEnabled
		pointPercent.isShown = function() return isHealthPercentCurveEnabled() and i <= getHealthGradientPointCount() end
		list[#list + 1] = pointPercent

		local _, defaultPointColor = getDefaultGradientPoint(i)
		local pointColor = {
			name = pointColorName,
			kind = UF.ui.settingType.Color,
			parentId = "health",
			isEnabled = isHealthPercentCurveEnabled,
			isShown = function() return isHealthPercentCurveEnabled() and i <= getHealthGradientPointCount() end,
			get = function() return getValue(unit, { "health", "percentColorCurvePoints", i, "color" }, defaultPointColor) end,
			set = function(_, color)
				setColor(unit, { "health", "percentColorCurvePoints", i, "color" }, color.r, color.g, color.b, color.a)
				refreshSelf()
			end,
			colorGet = function() return getValue(unit, { "health", "percentColorCurvePoints", i, "color" }, defaultPointColor) end,
			colorSet = function(_, color)
				setColor(unit, { "health", "percentColorCurvePoints", i, "color" }, color.r, color.g, color.b, color.a)
				refreshSelf()
			end,
			colorDefault = {
				r = defaultPointColor[1] or 1,
				g = defaultPointColor[2] or 1,
				b = defaultPointColor[3] or 1,
				a = defaultPointColor[4] or 1,
			},
			hasOpacity = true,
		}
		list[#list + 1] = pointColor
	end

	local showTapDeniedColor = unit == "target" or unit == "targettarget" or unit == "focus" or isBoss
	if showTapDeniedColor then
		local tapDef = healthDef.tapDeniedColor or { 0.5, 0.5, 0.5, 1 }
		list[#list + 1] = checkboxColor({
			name = L["UFTapDeniedColor"] or "Tapped mob color",
			parentId = "health",
			defaultChecked = healthDef.useTapDeniedColor ~= false,
			isChecked = function() return getValue(unit, { "health", "useTapDeniedColor" }, healthDef.useTapDeniedColor ~= false) ~= false end,
			onChecked = function(val)
				setValue(unit, { "health", "useTapDeniedColor" }, val and true or false)
				if val and not getValue(unit, { "health", "tapDeniedColor" }) then setValue(unit, { "health", "tapDeniedColor" }, tapDef) end
				refreshSelf()
				refreshSettingsUI()
			end,
			getColor = function() return toRGBA(getValue(unit, { "health", "tapDeniedColor" }, tapDef), tapDef) end,
			onColor = function(color)
				setColor(unit, { "health", "tapDeniedColor" }, color.r, color.g, color.b, color.a)
				setValue(unit, { "health", "useTapDeniedColor" }, true)
				refreshSelf()
			end,
			colorDefault = { r = tapDef[1] or 0.5, g = tapDef[2] or 0.5, b = tapDef[3] or 0.5, a = tapDef[4] or 1 },
		})
	end
	addDivider("health")

	list[#list + 1] = radioDropdown(
		L["Left text"] or "Left text",
		UF.ui.healthTextOptions,
		function() return normalizeTextMode(getValue(unit, { "health", "textLeft" }, healthDef.textLeft or "PERCENT")) end,
		function(val)
			setValue(unit, { "health", "textLeft" }, val)
			refresh()
			refreshSettingsUI()
		end,
		healthDef.textLeft or "PERCENT",
		"health"
	)

	list[#list + 1] = radioDropdown(
		L["Center text"] or "Center text",
		UF.ui.healthTextOptions,
		function() return normalizeTextMode(getValue(unit, { "health", "textCenter" }, healthDef.textCenter or "NONE")) end,
		function(val)
			setValue(unit, { "health", "textCenter" }, val)
			refresh()
			refreshSettingsUI()
		end,
		healthDef.textCenter or "NONE",
		"health"
	)

	list[#list + 1] = radioDropdown(
		L["Right text"] or "Right text",
		UF.ui.healthTextOptions,
		function() return normalizeTextMode(getValue(unit, { "health", "textRight" }, healthDef.textRight or "CURMAX")) end,
		function(val)
			setValue(unit, { "health", "textRight" }, val)
			refresh()
			refreshSettingsUI()
		end,
		healthDef.textRight or "CURMAX",
		"health"
	)

	local healthDelimiterSetting = radioDropdown(
		L["Delimiter"] or "Delimiter",
		delimiterOptions,
		function() return getValue(unit, { "health", "textDelimiter" }, healthDef.textDelimiter or " ") end,
		function(val)
			setValue(unit, { "health", "textDelimiter" }, val)
			refresh()
		end,
		healthDef.textDelimiter or " ",
		"health"
	)
	local function healthDelimiterCount()
		local leftMode = getValue(unit, { "health", "textLeft" }, healthDef.textLeft or "PERCENT")
		local centerMode = getValue(unit, { "health", "textCenter" }, healthDef.textCenter or "NONE")
		local rightMode = getValue(unit, { "health", "textRight" }, healthDef.textRight or "CURMAX")
		return maxDelimiterCount(leftMode, centerMode, rightMode)
	end
	healthDelimiterSetting.isShown = function() return healthDelimiterCount() >= 1 end
	list[#list + 1] = healthDelimiterSetting

	local healthDelimiterSecondary = radioDropdown(L["Secondary Delimiter"] or "Secondary delimiter", delimiterOptions, function()
		local primary = getValue(unit, { "health", "textDelimiter" }, healthDef.textDelimiter or " ")
		return getValue(unit, { "health", "textDelimiterSecondary" }, primary)
	end, function(val)
		setValue(unit, { "health", "textDelimiterSecondary" }, val)
		refresh()
	end, healthDef.textDelimiterSecondary or healthDef.textDelimiter or " ", "health")
	healthDelimiterSecondary.isShown = function() return healthDelimiterCount() >= 2 end
	list[#list + 1] = healthDelimiterSecondary

	local healthDelimiterTertiary = radioDropdown(L["Tertiary Delimiter"] or "Tertiary delimiter", delimiterOptions, function()
		local primary = getValue(unit, { "health", "textDelimiter" }, healthDef.textDelimiter or " ")
		local secondary = getValue(unit, { "health", "textDelimiterSecondary" }, primary)
		return getValue(unit, { "health", "textDelimiterTertiary" }, secondary)
	end, function(val)
		setValue(unit, { "health", "textDelimiterTertiary" }, val)
		refresh()
	end, healthDef.textDelimiterTertiary or healthDef.textDelimiterSecondary or healthDef.textDelimiter or " ", "health")
	healthDelimiterTertiary.isShown = function() return healthDelimiterCount() >= 3 end
	list[#list + 1] = healthDelimiterTertiary

	list[#list + 1] = checkbox(
		L["Hide % symbol"] or "Hide % symbol",
		function() return getValue(unit, { "health", "hidePercentSymbol" }, healthDef.hidePercentSymbol == true) == true end,
		function(val)
			setValue(unit, { "health", "hidePercentSymbol" }, val and true or false)
			refresh()
		end,
		healthDef.hidePercentSymbol == true,
		"health"
	)

	list[#list + 1] = checkbox(
		L["Round percent values"] or "Round percent values",
		function() return getValue(unit, { "health", "roundPercent" }, healthDef.roundPercent == true) == true end,
		function(val)
			setValue(unit, { "health", "roundPercent" }, val and true or false)
			refresh()
		end,
		healthDef.roundPercent == true,
		"health"
	)
	addDivider("health")

	list[#list + 1] = slider(FONT_SIZE_LABEL, 8, 30, 1, function() return getValue(unit, { "health", "fontSize" }, healthDef.fontSize or 14) end, function(val)
		debounced(unit .. "_healthFontSize", function()
			setValue(unit, { "health", "fontSize" }, val or healthDef.fontSize or 14)
			refresh()
		end)
	end, healthDef.fontSize or 14, "health", true)

	if #fontOptions() > 0 then
		list[#list + 1] = checkboxDropdown(L["Font"] or "Font", fontOptions, function()
			return getValue(unit, { "health", "font" }, healthDef.font or UF.ui.globalFontConfigKey())
		end, function(val)
			setValue(unit, { "health", "font" }, val)
			refresh()
		end, healthDef.font or UF.ui.globalFontConfigKey(), "health")
	end

	list[#list + 1] = checkboxDropdown(
		L["Font outline"] or "Font outline",
		UF.ui.outlineOptions,
		function()
			return UF.ui.normalizeFontStyleChoice(
				getValue(unit, { "health", "fontOutline" }, healthDef.fontOutline or "OUTLINE"),
				healthDef.fontOutline or "OUTLINE"
			)
		end,
		function(val)
			setValue(unit, { "health", "fontOutline" }, UF.ui.normalizeFontStyleChoice(val, healthDef.fontOutline or "OUTLINE"))
			refresh()
		end,
		healthDef.fontOutline or "OUTLINE",
		"health"
	)

	local function showHealthTextOffsets(key, fallback)
		local mode = normalizeTextMode(getValue(unit, { "health", key }, fallback))
		return mode ~= "NONE"
	end

	local healthLeftX = slider(
		L["TextLeftOffsetX"] or "Left text X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return (getValue(unit, { "health", "offsetLeft", "x" }, (healthDef.offsetLeft and healthDef.offsetLeft.x) or 0)) end,
		function(val)
			debounced(unit .. "_healthLeftX", function()
				setValue(unit, { "health", "offsetLeft", "x" }, val or 0)
				refresh()
			end)
		end,
		(healthDef.offsetLeft and healthDef.offsetLeft.x) or 0,
		"health",
		true
	)
	healthLeftX.isShown = function() return showHealthTextOffsets("textLeft", healthDef.textLeft or "PERCENT") end
	list[#list + 1] = healthLeftX

	local healthLeftY = slider(
		L["TextLeftOffsetY"] or "Left text Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return (getValue(unit, { "health", "offsetLeft", "y" }, (healthDef.offsetLeft and healthDef.offsetLeft.y) or 0)) end,
		function(val)
			debounced(unit .. "_healthLeftY", function()
				setValue(unit, { "health", "offsetLeft", "y" }, val or 0)
				refresh()
			end)
		end,
		(healthDef.offsetLeft and healthDef.offsetLeft.y) or 0,
		"health",
		true
	)
	healthLeftY.isShown = function() return showHealthTextOffsets("textLeft", healthDef.textLeft or "PERCENT") end
	list[#list + 1] = healthLeftY

	local healthCenterX = slider(
		L["TextCenterOffsetX"] or "Center text X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return (getValue(unit, { "health", "offsetCenter", "x" }, (healthDef.offsetCenter and healthDef.offsetCenter.x) or 0)) end,
		function(val)
			debounced(unit .. "_healthCenterX", function()
				setValue(unit, { "health", "offsetCenter", "x" }, val or 0)
				refresh()
			end)
		end,
		(healthDef.offsetCenter and healthDef.offsetCenter.x) or 0,
		"health",
		true
	)
	healthCenterX.isShown = function() return showHealthTextOffsets("textCenter", healthDef.textCenter or "NONE") end
	list[#list + 1] = healthCenterX

	local healthCenterY = slider(
		L["TextCenterOffsetY"] or "Center text Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return (getValue(unit, { "health", "offsetCenter", "y" }, (healthDef.offsetCenter and healthDef.offsetCenter.y) or 0)) end,
		function(val)
			debounced(unit .. "_healthCenterY", function()
				setValue(unit, { "health", "offsetCenter", "y" }, val or 0)
				refresh()
			end)
		end,
		(healthDef.offsetCenter and healthDef.offsetCenter.y) or 0,
		"health",
		true
	)
	healthCenterY.isShown = function() return showHealthTextOffsets("textCenter", healthDef.textCenter or "NONE") end
	list[#list + 1] = healthCenterY

	local healthRightX = slider(
		L["TextRightOffsetX"] or "Right text X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return (getValue(unit, { "health", "offsetRight", "x" }, (healthDef.offsetRight and healthDef.offsetRight.x) or 0)) end,
		function(val)
			debounced(unit .. "_healthRightX", function()
				setValue(unit, { "health", "offsetRight", "x" }, val or 0)
				refresh()
			end)
		end,
		(healthDef.offsetRight and healthDef.offsetRight.x) or 0,
		"health",
		true
	)
	healthRightX.isShown = function() return showHealthTextOffsets("textRight", healthDef.textRight or "CURMAX") end
	list[#list + 1] = healthRightX

	local healthRightY = slider(
		L["TextRightOffsetY"] or "Right text Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return (getValue(unit, { "health", "offsetRight", "y" }, (healthDef.offsetRight and healthDef.offsetRight.y) or 0)) end,
		function(val)
			debounced(unit .. "_healthRightY", function()
				setValue(unit, { "health", "offsetRight", "y" }, val or 0)
				refresh()
			end)
		end,
		(healthDef.offsetRight and healthDef.offsetRight.y) or 0,
		"health",
		true
	)
	healthRightY.isShown = function() return showHealthTextOffsets("textRight", healthDef.textRight or "CURMAX") end
	list[#list + 1] = healthRightY
	addDivider("health")

	list[#list + 1] = checkbox(L["Use short numbers"] or "Use short numbers", function() return getValue(unit, { "health", "useShortNumbers" }, healthDef.useShortNumbers ~= false) end, function(val)
		setValue(unit, { "health", "useShortNumbers" }, val and true or false)
		refresh()
	end, healthDef.useShortNumbers ~= false, "health")

	local textureOpts = textureOptions
	list[#list + 1] = checkboxDropdown(L["Bar Texture"] or "Bar Texture", textureOpts, function() return getValue(unit, { "health", "texture" }, healthDef.texture or "DEFAULT") end, function(val)
		setValue(unit, { "health", "texture" }, val)
		refresh()
	end, healthDef.texture or "DEFAULT", "health")

	local healthOrientation = radioDropdown(L["CooldownPanelBarOrientation"] or "Bar orientation", {
		{ value = "HORIZONTAL", label = L["Horizontal"] or "Horizontal" },
		{ value = "VERTICAL", label = L["Vertical"] or "Vertical" },
	}, function()
		return UFHelper.normalizeStatusBarOrientation(getValue(unit, { "health", "orientation" }, healthDef.orientation or "HORIZONTAL"))
	end, function(val)
		setValue(unit, { "health", "orientation" }, UFHelper.normalizeStatusBarOrientation(val))
		refresh()
	end, "HORIZONTAL", "health")
	healthOrientation.newTagID = "ufHealthBarOrientation"
	list[#list + 1] = healthOrientation

	list[#list + 1] = checkbox(L["Reverse fill"] or "Reverse fill", function() return getValue(unit, { "health", "reverseFill" }, healthDef.reverseFill == true) == true end, function(val)
		setValue(unit, { "health", "reverseFill" }, val and true or false)
		refresh()
	end, healthDef.reverseFill == true, "health")

	list[#list + 1] = checkbox(L["Show temporary max health loss"] or "Show temporary max health loss", function()
		return getValue(unit, { "health", "tempMaxHealthLossEnabled" }, healthDef.tempMaxHealthLossEnabled ~= false) ~= false
	end, function(val)
		setValue(unit, { "health", "tempMaxHealthLossEnabled" }, val and true or false)
		refresh()
	end, healthDef.tempMaxHealthLossEnabled ~= false, "health")
	addDivider("health")

	list[#list + 1] = checkboxColor({
		name = L["Show bar backdrop"] or "Show bar backdrop",
		parentId = "health",
		defaultChecked = (healthDef.backdrop and healthDef.backdrop.enabled) ~= false,
		isChecked = function() return getValue(unit, { "health", "backdrop", "enabled" }, (healthDef.backdrop and healthDef.backdrop.enabled) ~= false) ~= false end,
		onChecked = function(val)
			debounced(unit .. "_healthBackdrop", function()
				setValue(unit, { "health", "backdrop", "enabled" }, val and true or false)
				refresh()
				refreshSettingsUI()
			end)
		end,
		getColor = function()
			return toRGBA(getValue(unit, { "health", "backdrop", "color" }, healthDef.backdrop and healthDef.backdrop.color), healthDef.backdrop and healthDef.backdrop.color or { 0, 0, 0, 0.6 })
		end,
		onColor = function(color)
			debounced(unit .. "_healthBackdropColor", function()
				setColor(unit, { "health", "backdrop", "color" }, color.r, color.g, color.b, color.a)
				refresh()
			end)
		end,
		colorDefault = { r = 0, g = 0, b = 0, a = 0.6 },
		isEnabled = function()
			local isBackdropEnabled = getValue(unit, { "health", "backdrop", "enabled" }, (healthDef.backdrop and healthDef.backdrop.enabled) ~= false) ~= false
			if not isBackdropEnabled then return false end
			local useBackdropClassColor = getValue(unit, { "health", "backdrop", "useClassColor" }, healthDef.backdrop and healthDef.backdrop.useClassColor == true) == true
			return useBackdropClassColor ~= true
		end,
	})
	list[#list + 1] = checkboxDropdown(
		L["Backdrop texture"] or "Backdrop texture",
		textureOpts,
		function() return getValue(unit, { "health", "backdrop", "texture" }, (healthDef.backdrop and healthDef.backdrop.texture) or "DEFAULT") end,
		function(val)
			setValue(unit, { "health", "backdrop", "texture" }, val or "DEFAULT")
			refresh()
		end,
		(healthDef.backdrop and healthDef.backdrop.texture) or "DEFAULT",
		"health"
	)
	list[#list].isEnabled = function()
		local isBackdropEnabled = getValue(unit, { "health", "backdrop", "enabled" }, (healthDef.backdrop and healthDef.backdrop.enabled) ~= false) ~= false
		return isBackdropEnabled
	end
	list[#list + 1] = checkbox(
		L["Clamp backdrop to missing health"] or "Clamp backdrop to missing health",
		function()
			local value = getValue(unit, { "health", "backdrop", "clampToFill" }, healthDef.backdrop and healthDef.backdrop.clampToFill)
			if value == nil then value = false end
			return value == true
		end,
		function(val)
			setValue(unit, { "health", "backdrop", "clampToFill" }, val and true or false)
			refresh()
		end,
		healthDef.backdrop and healthDef.backdrop.clampToFill == true,
		"health",
		function() return getValue(unit, { "health", "backdrop", "enabled" }, (healthDef.backdrop and healthDef.backdrop.enabled) ~= false) ~= false end
	)

	if not isBoss then
		list[#list + 1] = checkbox(
			L["UFHealthBackdropUseClassColor"] or "Use class color for health backdrop (players)",
			function() return getValue(unit, { "health", "backdrop", "useClassColor" }, healthDef.backdrop and healthDef.backdrop.useClassColor == true) == true end,
			function(val)
				setValue(unit, { "health", "backdrop", "useClassColor" }, val and true or false)
				refreshSelf()
				refreshSettingsUI()
			end,
			healthDef.backdrop and healthDef.backdrop.useClassColor == true,
			"health",
			function() return getValue(unit, { "health", "backdrop", "enabled" }, (healthDef.backdrop and healthDef.backdrop.enabled) ~= false) ~= false end
		)
	end

	if unit ~= "pet" then
		if unit == "player" or unit == "target" or unit == "focus" then appendIncomingHealSettings(list, unit, healthDef, textureOpts, refresh, refreshSettingsUI) end

		local function formatOverlayHeight(value)
			if (tonumber(value) or 0) <= 0 then return L["Max"] or "Max" end
			return tostring(math.floor((tonumber(value) or 0) + 0.5))
		end

		list[#list + 1] = { name = L["Absorb"] or "Absorb", kind = UF.ui.settingType.Collapsible, id = "absorb", defaultCollapsed = true }
		local absorbColorDef = healthDef.absorbColor or { 0.85, 0.95, 1, 0.7 }

		list[#list + 1] = checkboxColor({
			name = L["Use custom absorb color"] or "Use custom absorb color",
			parentId = "absorb",
			defaultChecked = healthDef.absorbUseCustomColor == true,
			isChecked = function() return getValue(unit, { "health", "absorbUseCustomColor" }, healthDef.absorbUseCustomColor == true) == true end,
			onChecked = function(val)
				debounced(unit .. "_absorbCustomColorToggle", function()
					setValue(unit, { "health", "absorbUseCustomColor" }, val and true or false)
					if val and not getValue(unit, { "health", "absorbColor" }) then setValue(unit, { "health", "absorbColor" }, absorbColorDef) end
					refresh()
					refreshSettingsUI()
				end)
			end,
			getColor = function() return toRGBA(getValue(unit, { "health", "absorbColor" }, absorbColorDef), absorbColorDef) end,
			onColor = function(color)
				setColor(unit, { "health", "absorbColor" }, color.r, color.g, color.b, color.a)
				setValue(unit, { "health", "absorbUseCustomColor" }, true)
				refresh()
			end,
			colorDefault = {
				r = absorbColorDef[1] or 0.85,
				g = absorbColorDef[2] or 0.95,
				b = absorbColorDef[3] or 1,
				a = absorbColorDef[4] or 0.7,
			},
		})

		local absorbGlowSetting = checkbox(
			L["Use absorb glow"] or "Use absorb glow",
			function() return getValue(unit, { "health", "useAbsorbGlow" }, healthDef.useAbsorbGlow ~= false) ~= false end,
			function(val)
				setValue(unit, { "health", "useAbsorbGlow" }, val and true or false)
				refresh()
			end,
			healthDef.useAbsorbGlow ~= false,
			"absorb"
		)
		absorbGlowSetting.isShown = function()
			return UFHelper.normalizeStatusBarOrientation(getValue(unit, { "health", "orientation" }, healthDef.orientation or "HORIZONTAL")) ~= "VERTICAL"
		end
		list[#list + 1] = absorbGlowSetting

		list[#list + 1] = checkbox(
			L["Reverse fill"] or "Reverse fill",
			function() return getValue(unit, { "health", "absorbReverseFill" }, healthDef.absorbReverseFill == true) == true end,
			function(val)
				setValue(unit, { "health", "absorbReverseFill" }, val and true or false)
				refresh()
			end,
			healthDef.absorbReverseFill == true,
			"absorb"
		)

		list[#list + 1] = checkbox(
			L["Don't overflow health bar"] or "Don't overflow health bar",
			function() return getValue(unit, { "health", "absorbDontOverflowHealthBar" }, healthDef.absorbDontOverflowHealthBar == true) == true end,
			function(val)
				setValue(unit, { "health", "absorbDontOverflowHealthBar" }, val and true or false)
				refresh()
			end,
			healthDef.absorbDontOverflowHealthBar == true,
			"absorb",
			function() return getValue(unit, { "health", "absorbReverseFill" }, healthDef.absorbReverseFill == true) == true end
		)

		list[#list + 1] = slider(L["Absorb overlay height"] or "Absorb overlay height", 0, 800, 1, function()
			local val = getValue(unit, { "health", "absorbOverlayHeight" }, healthDef.absorbOverlayHeight)
			if not val or val <= 0 then return 0 end
			return math.min(val, 800)
		end, function(val)
			val = tonumber(val) or 0
			setValue(unit, { "health", "absorbOverlayHeight" }, val > 0 and val or nil)
			refresh()
		end, 0, "absorb", true, formatOverlayHeight)

		list[#list + 1] = checkbox(L["Anchor overlay to top"] or "Anchor overlay to top", function()
			return getValue(unit, { "health", "absorbOverlayAnchorTop" }, healthDef.absorbOverlayAnchorTop == true) == true
		end, function(val)
			setValue(unit, { "health", "absorbOverlayAnchorTop" }, val and true or false)
			refresh()
		end, healthDef.absorbOverlayAnchorTop == true, "absorb")

		list[#list + 1] = checkbox(L["Show sample absorb"] or "Show sample absorb", function() return sampleAbsorb[unit] == true end, function(val)
			sampleAbsorb[unit] = val and true or false
			refresh()
		end, false, "absorb")

		local absorbTextureSetting = checkboxDropdown(
			L["Absorb texture"] or "Absorb texture",
			textureOpts,
			function() return getValue(unit, { "health", "absorbTexture" }, healthDef.absorbTexture or healthDef.texture or "SOLID") end,
			function(val)
				setValue(unit, { "health", "absorbTexture" }, val)
				refresh()
			end,
			healthDef.absorbTexture or healthDef.texture or "SOLID",
			"absorb"
		)
		list[#list + 1] = absorbTextureSetting

		list[#list + 1] = { name = L["Heal absorb"] or "Heal absorb", kind = UF.ui.settingType.Collapsible, id = "healAbsorb", defaultCollapsed = true }
		local healAbsorbColorDef = healthDef.healAbsorbColor or { 1, 0.3, 0.3, 0.7 }

		list[#list + 1] = checkboxColor({
			name = L["Use custom heal absorb color"] or "Use custom heal absorb color",
			parentId = "healAbsorb",
			defaultChecked = healthDef.healAbsorbUseCustomColor == true,
			isChecked = function() return getValue(unit, { "health", "healAbsorbUseCustomColor" }, healthDef.healAbsorbUseCustomColor == true) == true end,
			onChecked = function(val)
				debounced(unit .. "_healAbsorbCustomColorToggle", function()
					setValue(unit, { "health", "healAbsorbUseCustomColor" }, val and true or false)
					if val and not getValue(unit, { "health", "healAbsorbColor" }) then setValue(unit, { "health", "healAbsorbColor" }, healAbsorbColorDef) end
					refresh()
					refreshSettingsUI()
				end)
			end,
			getColor = function() return toRGBA(getValue(unit, { "health", "healAbsorbColor" }, healAbsorbColorDef), healAbsorbColorDef) end,
			onColor = function(color)
				setColor(unit, { "health", "healAbsorbColor" }, color.r, color.g, color.b, color.a)
				setValue(unit, { "health", "healAbsorbUseCustomColor" }, true)
				refresh()
			end,
			colorDefault = {
				r = healAbsorbColorDef[1] or 1,
				g = healAbsorbColorDef[2] or 0.3,
				b = healAbsorbColorDef[3] or 0.3,
				a = healAbsorbColorDef[4] or 0.7,
			},
		})

		list[#list + 1] = checkbox(
			L["Reverse heal absorb fill"] or "Reverse heal absorb fill",
			function() return getValue(unit, { "health", "healAbsorbReverseFill" }, healthDef.healAbsorbReverseFill == true) == true end,
			function(val)
				setValue(unit, { "health", "healAbsorbReverseFill" }, val and true or false)
				refresh()
			end,
			healthDef.healAbsorbReverseFill == true,
			"healAbsorb"
		)

		list[#list + 1] = slider(L["Heal absorb overlay height"] or "Heal absorb overlay height", 0, 800, 1, function()
			local val = getValue(unit, { "health", "healAbsorbOverlayHeight" }, healthDef.healAbsorbOverlayHeight)
			if not val or val <= 0 then return 0 end
			return math.min(val, 800)
		end, function(val)
			val = tonumber(val) or 0
			setValue(unit, { "health", "healAbsorbOverlayHeight" }, val > 0 and val or nil)
			refresh()
		end, 0, "healAbsorb", true, formatOverlayHeight)

		list[#list + 1] = checkbox(L["Anchor overlay to top"] or "Anchor overlay to top", function()
			return getValue(unit, { "health", "healAbsorbOverlayAnchorTop" }, healthDef.healAbsorbOverlayAnchorTop == true) == true
		end, function(val)
			setValue(unit, { "health", "healAbsorbOverlayAnchorTop" }, val and true or false)
			refresh()
		end, healthDef.healAbsorbOverlayAnchorTop == true, "healAbsorb")

		list[#list + 1] = checkbox(L["Show sample heal absorb"] or "Show sample heal absorb", function() return sampleHealAbsorb[unit] == true end, function(val)
			sampleHealAbsorb[unit] = val and true or false
			refresh()
		end, false, "healAbsorb")

		local healAbsorbTextureSetting = checkboxDropdown(
			L["Heal absorb texture"] or "Heal absorb texture",
			textureOpts,
			function() return getValue(unit, { "health", "healAbsorbTexture" }, healthDef.healAbsorbTexture or healthDef.texture or "SOLID") end,
			function(val)
				setValue(unit, { "health", "healAbsorbTexture" }, val)
				refresh()
			end,
			healthDef.healAbsorbTexture or healthDef.texture or "SOLID",
			"healAbsorb"
		)
		list[#list + 1] = healAbsorbTextureSetting
	end

	list[#list + 1] = { name = L["Power"] or _G.POWER or "Power", kind = UF.ui.settingType.Collapsible, id = "power", defaultCollapsed = true }
	local powerDef = def.power or {}
	local function isPowerEnabled() return getValue(unit, { "power", "enabled" }, powerDef.enabled ~= false) ~= false end
	local function isPowerDetached() return getValue(unit, { "power", "detached" }, powerDef.detached == true) == true end
	local function isPowerDetachedEnabled() return isPowerEnabled() and isPowerDetached() end
	local function isDetachedPowerWidthMatched() return getValue(unit, { "power", "detachedMatchHealthWidth" }, powerDef.detachedMatchHealthWidth == true) == true end
	local detachedStrataOptions = { { value = "", label = DEFAULT } }
	for i = 1, #UF.ui.strataOptions do
		detachedStrataOptions[#detachedStrataOptions + 1] = UF.ui.strataOptions[i]
	end
	local function isDetachedPowerBorderEnabled()
		local border = getValue(unit, { "border" }, def.border or {})
		return isPowerDetachedEnabled() and border.detachedPower == true
	end
	local defaultPrimaryAllowedTypes = (UFHelper and UFHelper.GetDefaultPrimaryPowerAllowedTypes and UFHelper.GetDefaultPrimaryPowerAllowedTypes()) or {}
	local function normalizePrimaryTypeToken(token)
		if type(token) ~= "string" then return nil end
		local normalized = token
		if UFHelper and UFHelper.getCanonicalPowerToken then normalized = UFHelper.getCanonicalPowerToken(nil, token) or token end
		normalized = string.upper(normalized)
		if normalized == "" or normalized == "NONE" then return nil end
		return normalized
	end
	local function resolvePrimaryAllowedForDisplay()
		local cfgAllowed = getValue(unit, { "power", "allowedTypes" }, nil)
		if type(cfgAllowed) == "table" then return cfgAllowed end
		local defAllowed = powerDef.allowedTypes
		if type(defAllowed) == "table" then return defAllowed end
		return defaultPrimaryAllowedTypes
	end
	local function isPrimaryAllowedTypeSelected(token)
		local normalized = normalizePrimaryTypeToken(token)
		if not normalized then return false end
		local allowed = resolvePrimaryAllowedForDisplay()
		return type(allowed) == "table" and allowed[normalized] == true
	end
	local function setPrimaryAllowedType(token, enabled)
		local normalized = normalizePrimaryTypeToken(token)
		if not normalized then return end
		local source = resolvePrimaryAllowedForDisplay()
		local allowed = {}
		if type(source) == "table" then
			for key, isAllowed in pairs(source) do
				if isAllowed == true then allowed[key] = true end
			end
		end
		if enabled then
			allowed[normalized] = true
		else
			allowed[normalized] = nil
		end
		setValue(unit, { "power", "allowedTypes" }, allowed)
		refreshSelf()
		refreshSettingsUI()
	end

	list[#list + 1] = checkbox(L["Show power bar"] or "Show power bar", isPowerEnabled, function(val)
		setValue(unit, { "power", "enabled" }, val and true or false)
		refreshSelf()
		refreshSettingsUI()
	end, powerDef.enabled ~= false, "power")

	if unit == "player" then
		local powerTypeSetting = multiDropdown(TYPE or "Type", function()
			local provider = addon.Aura and addon.Aura.GetUFPrimaryPowerTokenOptions
			if type(provider) == "function" then return provider() end
			return {}
		end, isPrimaryAllowedTypeSelected, setPrimaryAllowedType, nil, "power")
		powerTypeSetting.isEnabled = isPowerEnabled
		list[#list + 1] = powerTypeSetting
	end

	local powerDetachedSetting = checkbox(L["UFPowerDetached"] or "Detach power bar", isPowerDetached, function(val)
		setValue(unit, { "power", "detached" }, val and true or false)
		refresh()
		refreshSettingsUI()
	end, powerDef.detached == true, "power", isPowerEnabled)
	list[#list + 1] = powerDetachedSetting
	addDivider("power", isPowerDetachedEnabled)

	local powerEmptyFallbackSetting = checkbox(
		L["UFPowerEmptyFallback"] or "Handle empty power bars (max 0)",
		function() return getValue(unit, { "power", "emptyMaxFallback" }, powerDef.emptyMaxFallback == true) == true end,
		function(val)
			setValue(unit, { "power", "emptyMaxFallback" }, val and true or false)
			refresh()
		end,
		powerDef.emptyMaxFallback == true,
		"power",
		isPowerEnabled
	)
	powerEmptyFallbackSetting.isEnabled = isPowerDetachedEnabled
	powerEmptyFallbackSetting.isShown = isPowerDetachedEnabled
	list[#list + 1] = powerEmptyFallbackSetting

	local powerMatchWidthSetting = checkbox(L["UFPowerDetachedMatchHealthWidth"] or "Match health width", isDetachedPowerWidthMatched, function(val)
		setValue(unit, { "power", "detachedMatchHealthWidth" }, val and true or false)
		refresh()
		refreshSettingsUI()
	end, powerDef.detachedMatchHealthWidth == true, "power", isPowerDetachedEnabled)
	powerMatchWidthSetting.isEnabled = isPowerDetachedEnabled
	powerMatchWidthSetting.isShown = isPowerDetachedEnabled
	list[#list + 1] = powerMatchWidthSetting

	local powerWidthSetting = slider(L["UFPowerWidth"] or "Power width", MIN_WIDTH, 800, 1, function()
		local fallback = getValue(unit, { "width" }, def.width or MIN_WIDTH)
		return getValue(unit, { "power", "width" }, fallback)
	end, function(val)
		debounced(unit .. "_powerWidth", function()
			setValue(unit, { "power", "width" }, math.max(MIN_WIDTH, val or MIN_WIDTH))
			refresh()
		end)
	end, def.width or MIN_WIDTH, "power", true)
	powerWidthSetting.isEnabled = function() return isPowerDetachedEnabled() and not isDetachedPowerWidthMatched() end
	powerWidthSetting.isShown = isPowerDetachedEnabled
	list[#list + 1] = powerWidthSetting

	local powerGrowFromCenterSetting = checkbox(
		L["Grow from center"] or "Grow from center",
		function() return getValue(unit, { "power", "detachedGrowFromCenter" }, powerDef.detachedGrowFromCenter == true) == true end,
		function(val)
			setValue(unit, { "power", "detachedGrowFromCenter" }, val and true or false)
			refresh()
		end,
		powerDef.detachedGrowFromCenter == true,
		"power",
		isPowerDetachedEnabled
	)
	powerGrowFromCenterSetting.isEnabled = isPowerDetachedEnabled
	powerGrowFromCenterSetting.isShown = isPowerDetachedEnabled
	list[#list + 1] = powerGrowFromCenterSetting

	local powerOffsetX = slider(L["Offset X"] or "Offset X", -OFFSET_RANGE, OFFSET_RANGE, 1, function() return getValue(unit, { "power", "offset", "x" }, 0) end, function(val)
		debounced(unit .. "_powerOffsetX", function()
			setValue(unit, { "power", "offset", "x" }, val or 0)
			refresh()
		end)
	end, 0, "power", true)
	powerOffsetX.isEnabled = isPowerDetachedEnabled
	powerOffsetX.isShown = isPowerDetachedEnabled
	list[#list + 1] = powerOffsetX

	local powerOffsetY = slider(L["Offset Y"] or "Offset Y", -OFFSET_RANGE, OFFSET_RANGE, 1, function() return getValue(unit, { "power", "offset", "y" }, 0) end, function(val)
		debounced(unit .. "_powerOffsetY", function()
			setValue(unit, { "power", "offset", "y" }, val or 0)
			refresh()
		end)
	end, 0, "power", true)
	powerOffsetY.isEnabled = isPowerDetachedEnabled
	powerOffsetY.isShown = isPowerDetachedEnabled
	list[#list + 1] = powerOffsetY
	addDivider("power", isPowerDetachedEnabled)

	local detachedPowerStrata = radioDropdown(
		L["UFDetachedPowerStrata"] or "Strata",
		detachedStrataOptions,
		function() return getValue(unit, { "power", "detachedStrata" }, powerDef.detachedStrata or "") end,
		function(val)
			if val == "" then val = nil end
			setValue(unit, { "power", "detachedStrata" }, val)
			refresh()
		end,
		powerDef.detachedStrata or "",
		"power",
		true
	)
	detachedPowerStrata.isEnabled = isPowerDetachedEnabled
	detachedPowerStrata.isShown = isPowerDetachedEnabled
	list[#list + 1] = detachedPowerStrata

	local detachedPowerLevelOffset = slider(
		L["UFDetachedPowerLevelOffset"] or "Frame level offset",
		0,
		50,
		1,
		function() return getValue(unit, { "power", "detachedFrameLevelOffset" }, powerDef.detachedFrameLevelOffset or 5) end,
		function(val)
			debounced(unit .. "_detachedPowerLevelOffset", function()
				setValue(unit, { "power", "detachedFrameLevelOffset" }, val or powerDef.detachedFrameLevelOffset or 5)
				refresh()
			end)
		end,
		powerDef.detachedFrameLevelOffset or 5,
		"power",
		true
	)
	detachedPowerLevelOffset.isEnabled = isPowerDetachedEnabled
	detachedPowerLevelOffset.isShown = isPowerDetachedEnabled
	list[#list + 1] = detachedPowerLevelOffset
	addDivider("power", isPowerDetachedEnabled)

	local detachedBorderToggle = checkbox(
		L["Show border"] or "Show border",
		function() return getValue(unit, { "border", "detachedPower" }, def.border and def.border.detachedPower == true) == true end,
		function(val)
			local border = getValue(unit, { "border" }, def.border or {})
			border.detachedPower = val and true or false
			setValue(unit, { "border" }, border)
			refresh()
			refreshSettingsUI()
		end,
		def.border and def.border.detachedPower == true,
		"power"
	)
	detachedBorderToggle.isEnabled = isPowerDetachedEnabled
	detachedBorderToggle.isShown = isPowerDetachedEnabled
	list[#list + 1] = detachedBorderToggle

	local detachedBorderTexture = checkboxDropdown(L["Border texture"] or "Border texture", borderOptions, function()
		local border = getValue(unit, { "border" }, def.border or {})
		return border.detachedPowerTexture or border.texture or (def.border and def.border.texture) or "DEFAULT"
	end, function(val)
		local border = getValue(unit, { "border" }, def.border or {})
		border.detachedPowerTexture = val or "DEFAULT"
		setValue(unit, { "border" }, border)
		refresh()
	end, (def.border and def.border.detachedPowerTexture) or (def.border and def.border.texture) or "DEFAULT", "power")
	detachedBorderTexture.isEnabled = isDetachedPowerBorderEnabled
	detachedBorderTexture.isShown = isPowerDetachedEnabled
	list[#list + 1] = detachedBorderTexture

	local detachedBorderSize = slider(L["Border size"] or "Border size", 1, 64, 1, function()
		local border = getValue(unit, { "border" }, def.border or {})
		return border.detachedPowerSize or border.edgeSize or 1
	end, function(val)
		debounced(unit .. "_detachedPowerBorderSize", function()
			local border = getValue(unit, { "border" }, def.border or {})
			border.detachedPowerSize = val or 1
			setValue(unit, { "border" }, border)
			refresh()
		end)
	end, (def.border and def.border.detachedPowerSize) or (def.border and def.border.edgeSize) or 1, "power", true)
	detachedBorderSize.isEnabled = isDetachedPowerBorderEnabled
	detachedBorderSize.isShown = isPowerDetachedEnabled
	list[#list + 1] = detachedBorderSize

	local detachedBorderOffset = slider(L["Border offset"] or "Border offset", 0, 64, 1, function()
		local border = getValue(unit, { "border" }, def.border or {})
		if border.detachedPowerOffset == nil then
			if border.offset ~= nil then return border.offset end
			return border.edgeSize or 1
		end
		return border.detachedPowerOffset
	end, function(val)
		debounced(unit .. "_detachedPowerBorderOffset", function()
			local border = getValue(unit, { "border" }, def.border or {})
			border.detachedPowerOffset = val or 0
			setValue(unit, { "border" }, border)
			refresh()
		end)
	end, (def.border and def.border.detachedPowerOffset) or (def.border and def.border.offset) or (def.border and def.border.edgeSize) or 1, "power", true)
	detachedBorderOffset.isEnabled = isDetachedPowerBorderEnabled
	detachedBorderOffset.isShown = isPowerDetachedEnabled
	list[#list + 1] = detachedBorderOffset
	addDivider("power", isPowerDetachedEnabled)

	list[#list + 1] = checkbox(L["Reverse fill"] or "Reverse fill", function() return getValue(unit, { "power", "reverseFill" }, powerDef.reverseFill == true) == true end, function(val)
		setValue(unit, { "power", "reverseFill" }, val and true or false)
		refresh()
	end, powerDef.reverseFill == true, "power", isPowerEnabled)

	local powerOrientation = radioDropdown(L["CooldownPanelBarOrientation"] or "Bar orientation", {
		{ value = "HORIZONTAL", label = L["Horizontal"] or "Horizontal" },
		{ value = "VERTICAL", label = L["Vertical"] or "Vertical" },
	}, function()
		return UFHelper.normalizeStatusBarOrientation(getValue(unit, { "power", "orientation" }, powerDef.orientation or "HORIZONTAL"))
	end, function(val)
		setValue(unit, { "power", "orientation" }, UFHelper.normalizeStatusBarOrientation(val))
		refresh()
	end, "HORIZONTAL", "power")
	powerOrientation.newTagID = "ufPowerBarOrientation"
	powerOrientation.isEnabled = isPowerEnabled
	list[#list + 1] = powerOrientation

	local powerHeightSetting = slider(L["Power height"] or "Power height", 1, 60, 1, function() return getValue(unit, { "powerHeight" }, def.powerHeight or 16) end, function(val)
		debounced(unit .. "_powerHeight", function()
			setValue(unit, { "powerHeight" }, val or def.powerHeight or 16)
			refresh()
		end)
	end, def.powerHeight or 16, "power", true)
	powerHeightSetting.isEnabled = isPowerEnabled
	list[#list + 1] = powerHeightSetting
	addDivider("power")

	local powerTextLeft = radioDropdown(
		L["Left text"] or "Left text",
		textOptions,
		function() return normalizeTextMode(getValue(unit, { "power", "textLeft" }, powerDef.textLeft or "PERCENT")) end,
		function(val)
			setValue(unit, { "power", "textLeft" }, val)
			refreshSelf()
			refreshSettingsUI()
		end,
		powerDef.textLeft or "PERCENT",
		"power"
	)
	powerTextLeft.isEnabled = isPowerEnabled
	list[#list + 1] = powerTextLeft

	local powerTextCenter = radioDropdown(
		L["Center text"] or "Center text",
		textOptions,
		function() return normalizeTextMode(getValue(unit, { "power", "textCenter" }, powerDef.textCenter or "NONE")) end,
		function(val)
			setValue(unit, { "power", "textCenter" }, val)
			refreshSelf()
			refreshSettingsUI()
		end,
		powerDef.textCenter or "NONE",
		"power"
	)
	powerTextCenter.isEnabled = isPowerEnabled
	list[#list + 1] = powerTextCenter

	local powerTextRight = radioDropdown(
		L["Right text"] or "Right text",
		textOptions,
		function() return normalizeTextMode(getValue(unit, { "power", "textRight" }, powerDef.textRight or "CURMAX")) end,
		function(val)
			setValue(unit, { "power", "textRight" }, val)
			refreshSelf()
			refreshSettingsUI()
		end,
		powerDef.textRight or "CURMAX",
		"power"
	)
	powerTextRight.isEnabled = isPowerEnabled
	list[#list + 1] = powerTextRight

	local powerDelimiter = radioDropdown(
		L["Delimiter"] or "Delimiter",
		delimiterOptions,
		function() return getValue(unit, { "power", "textDelimiter" }, powerDef.textDelimiter or " ") end,
		function(val)
			setValue(unit, { "power", "textDelimiter" }, val)
			refreshSelf()
		end,
		powerDef.textDelimiter or " ",
		"power"
	)
	local function powerDelimiterCount()
		local leftMode = getValue(unit, { "power", "textLeft" }, powerDef.textLeft or "PERCENT")
		local centerMode = getValue(unit, { "power", "textCenter" }, powerDef.textCenter or "NONE")
		local rightMode = getValue(unit, { "power", "textRight" }, powerDef.textRight or "CURMAX")
		return maxDelimiterCount(leftMode, centerMode, rightMode)
	end
	powerDelimiter.isShown = function() return powerDelimiterCount() >= 1 end
	powerDelimiter.isEnabled = isPowerEnabled
	list[#list + 1] = powerDelimiter

	local powerDelimiterSecondary = radioDropdown(L["Secondary Delimiter"] or "Secondary delimiter", delimiterOptions, function()
		local primary = getValue(unit, { "power", "textDelimiter" }, powerDef.textDelimiter or " ")
		return getValue(unit, { "power", "textDelimiterSecondary" }, primary)
	end, function(val)
		setValue(unit, { "power", "textDelimiterSecondary" }, val)
		refreshSelf()
	end, powerDef.textDelimiterSecondary or powerDef.textDelimiter or " ", "power")
	powerDelimiterSecondary.isShown = function() return powerDelimiterCount() >= 2 end
	powerDelimiterSecondary.isEnabled = isPowerEnabled
	list[#list + 1] = powerDelimiterSecondary

	local powerDelimiterTertiary = radioDropdown(L["Tertiary Delimiter"] or "Tertiary delimiter", delimiterOptions, function()
		local primary = getValue(unit, { "power", "textDelimiter" }, powerDef.textDelimiter or " ")
		local secondary = getValue(unit, { "power", "textDelimiterSecondary" }, primary)
		return getValue(unit, { "power", "textDelimiterTertiary" }, secondary)
	end, function(val)
		setValue(unit, { "power", "textDelimiterTertiary" }, val)
		refreshSelf()
	end, powerDef.textDelimiterTertiary or powerDef.textDelimiterSecondary or powerDef.textDelimiter or " ", "power")
	powerDelimiterTertiary.isShown = function() return powerDelimiterCount() >= 3 end
	powerDelimiterTertiary.isEnabled = isPowerEnabled
	list[#list + 1] = powerDelimiterTertiary

	list[#list + 1] = checkbox(L["Hide % symbol"] or "Hide % symbol", function() return getValue(unit, { "power", "hidePercentSymbol" }, powerDef.hidePercentSymbol == true) == true end, function(val)
		setValue(unit, { "power", "hidePercentSymbol" }, val and true or false)
		refresh()
	end, powerDef.hidePercentSymbol == true, "power", isPowerEnabled)

	list[#list + 1] = checkbox(
		L["Round percent values"] or "Round percent values",
		function() return getValue(unit, { "power", "roundPercent" }, powerDef.roundPercent == true) == true end,
		function(val)
			setValue(unit, { "power", "roundPercent" }, val and true or false)
			refresh()
		end,
		powerDef.roundPercent == true,
		"power",
		isPowerEnabled
	)

	local powerFontSize = slider(FONT_SIZE_LABEL, 8, 30, 1, function() return getValue(unit, { "power", "fontSize" }, powerDef.fontSize or 14) end, function(val)
		debounced(unit .. "_powerFontSize", function()
			setValue(unit, { "power", "fontSize" }, val or powerDef.fontSize or 14)
			refreshSelf()
		end)
	end, powerDef.fontSize or 14, "power", true)
	powerFontSize.isEnabled = isPowerEnabled
	list[#list + 1] = powerFontSize

	if #fontOptions() > 0 then
		local powerFont = checkboxDropdown(L["Font"] or "Font", fontOptions, function()
			return getValue(unit, { "power", "font" }, powerDef.font or UF.ui.globalFontConfigKey())
		end, function(val)
			setValue(unit, { "power", "font" }, val)
			refreshSelf()
		end, powerDef.font or UF.ui.globalFontConfigKey(), "power")
		powerFont.isEnabled = isPowerEnabled
		list[#list + 1] = powerFont
	end

	local powerFontOutline = checkboxDropdown(
		L["Font outline"] or "Font outline",
		UF.ui.outlineOptions,
		function()
			return UF.ui.normalizeFontStyleChoice(
				getValue(unit, { "power", "fontOutline" }, powerDef.fontOutline or "OUTLINE"),
				powerDef.fontOutline or "OUTLINE"
			)
		end,
		function(val)
			setValue(unit, { "power", "fontOutline" }, UF.ui.normalizeFontStyleChoice(val, powerDef.fontOutline or "OUTLINE"))
			refresh()
		end,
		powerDef.fontOutline or "OUTLINE",
		"power"
	)
	powerFontOutline.isEnabled = isPowerEnabled
	list[#list + 1] = powerFontOutline

	local function showPowerTextOffsets(key, fallback)
		local mode = normalizeTextMode(getValue(unit, { "power", key }, fallback))
		return mode ~= "NONE"
	end

	local powerLeftX = slider(
		L["TextLeftOffsetX"] or "Left text X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return (getValue(unit, { "power", "offsetLeft", "x" }, (powerDef.offsetLeft and powerDef.offsetLeft.x) or 0)) end,
		function(val)
			debounced(unit .. "_powerLeftX", function()
				setValue(unit, { "power", "offsetLeft", "x" }, val or 0)
				refresh()
			end)
		end,
		(powerDef.offsetLeft and powerDef.offsetLeft.x) or 0,
		"power",
		true
	)
	powerLeftX.isEnabled = isPowerEnabled
	powerLeftX.isShown = function() return showPowerTextOffsets("textLeft", powerDef.textLeft or "PERCENT") end
	list[#list + 1] = powerLeftX

	local powerLeftY = slider(
		L["TextLeftOffsetY"] or "Left text Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return (getValue(unit, { "power", "offsetLeft", "y" }, (powerDef.offsetLeft and powerDef.offsetLeft.y) or 0)) end,
		function(val)
			debounced(unit .. "_powerLeftY", function()
				setValue(unit, { "power", "offsetLeft", "y" }, val or 0)
				refresh()
			end)
		end,
		(powerDef.offsetLeft and powerDef.offsetLeft.y) or 0,
		"power",
		true
	)
	powerLeftY.isEnabled = isPowerEnabled
	powerLeftY.isShown = function() return showPowerTextOffsets("textLeft", powerDef.textLeft or "PERCENT") end
	list[#list + 1] = powerLeftY

	local powerCenterX = slider(
		L["TextCenterOffsetX"] or "Center text X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return (getValue(unit, { "power", "offsetCenter", "x" }, (powerDef.offsetCenter and powerDef.offsetCenter.x) or 0)) end,
		function(val)
			debounced(unit .. "_powerCenterX", function()
				setValue(unit, { "power", "offsetCenter", "x" }, val or 0)
				refresh()
			end)
		end,
		(powerDef.offsetCenter and powerDef.offsetCenter.x) or 0,
		"power",
		true
	)
	powerCenterX.isEnabled = isPowerEnabled
	powerCenterX.isShown = function() return showPowerTextOffsets("textCenter", powerDef.textCenter or "NONE") end
	list[#list + 1] = powerCenterX

	local powerCenterY = slider(
		L["TextCenterOffsetY"] or "Center text Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return (getValue(unit, { "power", "offsetCenter", "y" }, (powerDef.offsetCenter and powerDef.offsetCenter.y) or 0)) end,
		function(val)
			debounced(unit .. "_powerCenterY", function()
				setValue(unit, { "power", "offsetCenter", "y" }, val or 0)
				refresh()
			end)
		end,
		(powerDef.offsetCenter and powerDef.offsetCenter.y) or 0,
		"power",
		true
	)
	powerCenterY.isEnabled = isPowerEnabled
	powerCenterY.isShown = function() return showPowerTextOffsets("textCenter", powerDef.textCenter or "NONE") end
	list[#list + 1] = powerCenterY

	local powerRightX = slider(
		L["TextRightOffsetX"] or "Right text X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return (getValue(unit, { "power", "offsetRight", "x" }, (powerDef.offsetRight and powerDef.offsetRight.x) or 0)) end,
		function(val)
			debounced(unit .. "_powerRightX", function()
				setValue(unit, { "power", "offsetRight", "x" }, val or 0)
				refresh()
			end)
		end,
		(powerDef.offsetRight and powerDef.offsetRight.x) or 0,
		"power",
		true
	)
	powerRightX.isEnabled = isPowerEnabled
	powerRightX.isShown = function() return showPowerTextOffsets("textRight", powerDef.textRight or "CURMAX") end
	list[#list + 1] = powerRightX

	local powerRightY = slider(
		L["TextRightOffsetY"] or "Right text Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return (getValue(unit, { "power", "offsetRight", "y" }, (powerDef.offsetRight and powerDef.offsetRight.y) or 0)) end,
		function(val)
			debounced(unit .. "_powerRightY", function()
				setValue(unit, { "power", "offsetRight", "y" }, val or 0)
				refresh()
			end)
		end,
		(powerDef.offsetRight and powerDef.offsetRight.y) or 0,
		"power",
		true
	)
	powerRightY.isEnabled = isPowerEnabled
	powerRightY.isShown = function() return showPowerTextOffsets("textRight", powerDef.textRight or "CURMAX") end
	list[#list + 1] = powerRightY

	list[#list + 1] = checkbox(L["Use short numbers"] or "Use short numbers", function() return getValue(unit, { "power", "useShortNumbers" }, powerDef.useShortNumbers ~= false) end, function(val)
		setValue(unit, { "power", "useShortNumbers" }, val and true or false)
		refresh()
	end, powerDef.useShortNumbers ~= false, "power", isPowerEnabled)
	addDivider("power")

	local powerTexture = checkboxDropdown(L["Bar Texture"] or "Bar Texture", textureOpts, function() return getValue(unit, { "power", "texture" }, powerDef.texture or "DEFAULT") end, function(val)
		setValue(unit, { "power", "texture" }, val)
		refresh()
	end, powerDef.texture or "DEFAULT", "power")
	powerTexture.isEnabled = isPowerEnabled
	list[#list + 1] = powerTexture

	list[#list + 1] = checkboxColor({
		name = L["Show bar backdrop"] or "Show bar backdrop",
		parentId = "power",
		defaultChecked = (powerDef.backdrop and powerDef.backdrop.enabled) ~= false,
		isChecked = function() return getValue(unit, { "power", "backdrop", "enabled" }, (powerDef.backdrop and powerDef.backdrop.enabled) ~= false) ~= false end,
		onChecked = function(val)
			debounced(unit .. "_powerBackdrop", function()
				setValue(unit, { "power", "backdrop", "enabled" }, val and true or false)
				refresh()
				refreshSettingsUI()
			end)
		end,
		getColor = function()
			return toRGBA(getValue(unit, { "power", "backdrop", "color" }, powerDef.backdrop and powerDef.backdrop.color), powerDef.backdrop and powerDef.backdrop.color or { 0, 0, 0, 0.6 })
		end,
		onColor = function(color)
			debounced(unit .. "_powerBackdropColor", function()
				setColor(unit, { "power", "backdrop", "color" }, color.r, color.g, color.b, color.a)
				refresh()
			end)
		end,
		colorDefault = { r = 0, g = 0, b = 0, a = 0.6 },
		isEnabled = isPowerEnabled,
	})
	list[#list + 1] = checkboxDropdown(
		L["Backdrop texture"] or "Backdrop texture",
		textureOpts,
		function() return getValue(unit, { "power", "backdrop", "texture" }, (powerDef.backdrop and powerDef.backdrop.texture) or "DEFAULT") end,
		function(val)
			setValue(unit, { "power", "backdrop", "texture" }, val or "DEFAULT")
			refresh()
		end,
		(powerDef.backdrop and powerDef.backdrop.texture) or "DEFAULT",
		"power"
	)
	list[#list].isEnabled = function() return isPowerEnabled() and getValue(unit, { "power", "backdrop", "enabled" }, (powerDef.backdrop and powerDef.backdrop.enabled) ~= false) ~= false end

	if addon.Aura and addon.Aura.AppendUFSecondaryPowerSettings then addon.Aura.AppendUFSecondaryPowerSettings(list, unit, def, textureOpts, addDivider, refresh, refreshSelf) end

	local showNPCColors = unit == "target" or unit == "targettarget" or unit == "focus" or isBoss
	if showNPCColors then
		list[#list + 1] = { name = L["UFNPCColors"] or "NPC colors", kind = UF.ui.settingType.Collapsible, id = "npcColors", defaultCollapsed = true }
		for _, entry in ipairs(npcColorEntries) do
			local dr, dg, db, da = getDefaultNPCColor(entry.key)
			local defaultColor = { dr, dg, db, da }
			list[#list + 1] = checkboxColor({
				name = entry.label,
				parentId = "npcColors",
				defaultChecked = false,
				isChecked = function() return getNPCOverride(entry.key) ~= nil end,
				onChecked = function(val)
					debounced("uf_npccolor_toggle_" .. entry.key, function()
						if val then
							setNPCOverride(entry.key, dr, dg, db, da)
						else
							clearNPCOverride(entry.key)
						end
						if UF and UF.Refresh then UF.Refresh() end
						refreshSettingsUI()
					end)
				end,
				getColor = function() return toRGBA(getNPCOverride(entry.key) or defaultColor, defaultColor) end,
				onColor = function(color)
					debounced("uf_npccolor_pick_" .. entry.key, function()
						local shouldRefreshSettings = getNPCOverride(entry.key) == nil
						setNPCOverride(entry.key, color.r, color.g, color.b, color.a)
						if UF and UF.Refresh then UF.Refresh() end
						if shouldRefreshSettings then refreshSettingsUI() end
					end)
				end,
				colorDefault = { r = dr, g = dg, b = db, a = da },
			})
		end
	end

	local function SnapToStep(value, step, minV, maxV)
		value = tonumber(value)
		if not value then return nil end

		if minV then value = math.max(minV, value) end
		if maxV then value = math.min(maxV, value) end

		local inv = 1 / (step or 1)
		local ticks = math.floor(value * inv + 0.5)
		local snapped = ticks / inv

		snapped = math.floor(snapped * 100 + 0.5) / 100
		return snapped
	end

	if isPlayer and classHasResource then
		local crDef = def.classResource or {}
		list[#list + 1] = { name = L["ClassResource"] or "Class Resource", kind = UF.ui.settingType.Collapsible, id = "classResource", defaultCollapsed = true }
		local function isClassResourceEnabled() return getValue(unit, { "classResource", "enabled" }, crDef.enabled ~= false) ~= false end
		local function getPathValue(root, path)
			local cur = root
			if type(cur) ~= "table" then return nil end
			for i = 1, #path do
				cur = cur[path[i]]
				if cur == nil then return nil end
			end
			return cur
		end
		local function getClassResourceOptions()
			local util = UF and UF.ClassResourceUtil
			if util and util.getClassResourceOptions then
				local classToken = addon.variables and addon.variables.unitClass
				local options = util.getClassResourceOptions(classToken)
				if type(options) == "table" then return options end
			end
			return {}
		end
		addon.variables = addon.variables or {}
		addon.variables.ufSelectedClassResourceByUnit = type(addon.variables.ufSelectedClassResourceByUnit) == "table" and addon.variables.ufSelectedClassResourceByUnit or {}
		local selectedClassResourceByUnit = addon.variables.ufSelectedClassResourceByUnit
		local function getSelectedResourceID()
			local options = getClassResourceOptions()
			if #options == 0 then
				selectedClassResourceByUnit[unit] = nil
				return nil
			end
			local selected = selectedClassResourceByUnit[unit]
			local valid = false
			if type(selected) == "string" and selected ~= "" then
				for i = 1, #options do
					if options[i].value == selected then
						valid = true
						break
					end
				end
			end
			if not valid then
				selected = options[1].value
				selectedClassResourceByUnit[unit] = selected
			end
			return selected
		end
		local function setSelectedResourceID(resourceID)
			local options = getClassResourceOptions()
			for i = 1, #options do
				if options[i].value == resourceID then
					selectedClassResourceByUnit[unit] = resourceID
					return true
				end
			end
			return false
		end
		local function getClassResourceConfigIDs(resourceID)
			local util = UF and UF.ClassResourceUtil
			if util and util.getClassResourceConfigIDs then
				local classToken = addon.variables and addon.variables.unitClass
				local ids = util.getClassResourceConfigIDs(classToken, resourceID)
				if type(ids) == "table" and #ids > 0 then return ids end
			end
			if type(resourceID) == "string" and resourceID ~= "" then return { resourceID } end
			return {}
		end
		local function buildClassResourcePath(resourceID, suffix)
			local path = { "classResource" }
			if type(resourceID) == "string" and resourceID ~= "" then
				path[#path + 1] = "resources"
				path[#path + 1] = resourceID
			end
			for i = 1, #suffix do
				path[#path + 1] = suffix[i]
			end
			return path
		end
		local function getClassResourceValueFor(resourceID, suffix, fallback)
			if type(resourceID) == "string" and resourceID ~= "" then
				local configIDs = getClassResourceConfigIDs(resourceID)
				for i = 1, #configIDs do
					local scopedValue = getValue(unit, buildClassResourcePath(configIDs[i], suffix), nil)
					if scopedValue ~= nil then return scopedValue end
				end
			end
			local globalValue = getValue(unit, buildClassResourcePath(nil, suffix), nil)
			if globalValue ~= nil then return globalValue end
			if type(resourceID) == "string" and resourceID ~= "" and type(crDef.resources) == "table" then
				local configIDs = getClassResourceConfigIDs(resourceID)
				for i = 1, #configIDs do
					local resourceDef = crDef.resources[configIDs[i]]
					local resourceDefault = getPathValue(resourceDef, suffix)
					if resourceDefault ~= nil then return resourceDefault end
				end
			end
			local globalDefault = getPathValue(crDef, suffix)
			if globalDefault ~= nil then return globalDefault end
			return fallback
		end
		local function setClassResourceValueFor(resourceID, suffix, value) setValue(unit, buildClassResourcePath(resourceID, suffix), value) end
		local function getSelectedClassResourceValue(suffix, fallback) return getClassResourceValueFor(getSelectedResourceID(), suffix, fallback) end
		local function setSelectedClassResourceValue(suffix, value) setClassResourceValueFor(getSelectedResourceID(), suffix, value) end
		local function defaultOffsetY()
			local anchor = getSelectedClassResourceValue({ "anchor" }, crDef.anchor or "TOP")
			return anchor == "TOP" and -5 or 5
		end

		list[#list + 1] = checkbox(L["Show class resource"] or "Show class resource", isClassResourceEnabled, function(val)
			setValue(unit, { "classResource", "enabled" }, val and true or false)
			refreshSelf()
		end, crDef.enabled ~= false, "classResource")

		local classResourceVisibility = multiDropdown(
			L["UFClassResourceVisibleResources"] or L["ClassResource"],
			getClassResourceOptions,
			function(resourceID) return getClassResourceValueFor(resourceID, { "enabled" }, true) ~= false end,
			function(resourceID, selected)
				setClassResourceValueFor(resourceID, { "enabled" }, selected and true or false)
				refreshSelf()
				refreshSettingsUI()
			end,
			nil,
			"classResource"
		)
		classResourceVisibility.isEnabled = isClassResourceEnabled
		classResourceVisibility.isShown = function() return #getClassResourceOptions() > 0 end
		list[#list + 1] = classResourceVisibility

		local classResourceSelector = radioDropdown(L["UFClassResourceSelector"] or L["ClassResource"], getClassResourceOptions, function() return getSelectedResourceID() end, function(val)
			if setSelectedResourceID(val) then refreshSettingsUI() end
		end, nil, "classResource")
		classResourceSelector.isEnabled = isClassResourceEnabled
		classResourceSelector.isShown = function() return #getClassResourceOptions() > 1 end
		list[#list + 1] = classResourceSelector

		local classAnchorOpts = {
			{ value = "TOP", label = DIRECTION_TOP_LABEL },
			{ value = "BOTTOM", label = DIRECTION_BOTTOM_LABEL },
		}
		local classAnchor = radioDropdown(L["Anchor"] or "Anchor", classAnchorOpts, function() return getSelectedClassResourceValue({ "anchor" }, crDef.anchor or "TOP") end, function(val)
			setSelectedClassResourceValue({ "anchor" }, val or "TOP")
			refreshSelf()
		end, crDef.anchor or "TOP", "classResource")
		classAnchor.isEnabled = isClassResourceEnabled
		list[#list + 1] = classAnchor

		local classStrata = radioDropdown(
			L["UFClassResourceStrata"] or "Class resource strata",
			strataOptionsWithDefault,
			function() return getSelectedClassResourceValue({ "strata" }, crDef.strata or "") end,
			function(val)
				setSelectedClassResourceValue({ "strata" }, (val and val ~= "") and val or nil)
				refreshSelf()
			end,
			crDef.strata or "",
			"classResource"
		)
		classStrata.isEnabled = isClassResourceEnabled
		list[#list + 1] = classStrata

		local classFrameLevelOffset = slider(L["UFClassResourceFrameLevelOffset"] or "Class resource frame level offset", 0, 50, 1, function()
			local fallback = tonumber(getPathValue(crDef, { "frameLevelOffset" }))
			if fallback == nil then fallback = 5 end
			return math.max(0, tonumber(getSelectedClassResourceValue({ "frameLevelOffset" }, fallback)) or fallback)
		end, function(val)
			local levelOffset = math.max(0, val or 0)
			setSelectedClassResourceValue({ "frameLevelOffset" }, levelOffset)
			refreshSelf()
		end, math.max(0, tonumber(getPathValue(crDef, { "frameLevelOffset" })) or 5), "classResource", true)
		classFrameLevelOffset.isEnabled = isClassResourceEnabled
		list[#list + 1] = classFrameLevelOffset

		local classOffsetX = slider(
			L["Offset X"] or "Offset X",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return tonumber(getSelectedClassResourceValue({ "offset", "x" }, (crDef.offset and crDef.offset.x) or 0)) or 0 end,
			function(val)
				debounced(unit .. "_classResourceOffsetX", function()
					setSelectedClassResourceValue({ "offset", "x" }, val or 0)
					refreshSelf()
				end)
			end,
			(crDef.offset and crDef.offset.x) or 0,
			"classResource",
			true
		)
		classOffsetX.isEnabled = isClassResourceEnabled
		list[#list + 1] = classOffsetX

		local classOffsetY = slider(
			L["Offset Y"] or "Offset Y",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return tonumber(getSelectedClassResourceValue({ "offset", "y" }, defaultOffsetY())) or defaultOffsetY() end,
			function(val)
				debounced(unit .. "_classResourceOffsetY", function()
					setSelectedClassResourceValue({ "offset", "y" }, val or 0)
					refreshSelf()
				end)
			end,
			defaultOffsetY(),
			"classResource",
			true
		)
		classOffsetY.isEnabled = isClassResourceEnabled
		list[#list + 1] = classOffsetY

		local classScale = slider(
			L["Scale"] or "Scale",
			0.5,
			2,
			0.05,
			function()
				local v = getSelectedClassResourceValue({ "scale" }, crDef.scale or 1)
				return SnapToStep(v, 0.05, 0.5, 2) or 1
			end,
			function(val)
				debounced(unit .. "_classResourceScale", function()
					val = SnapToStep(val, 0.05, 0.5, 2) or 1
					setSelectedClassResourceValue({ "scale" }, val)
					refreshSelf()
					refreshSettingsUI()
				end)
			end,
			SnapToStep(crDef.scale or 1, 0.05, 0.5, 2) or 1,
			"classResource",
			true,
			function(value)
				value = SnapToStep(value, 0.05, 0.5, 2) or 1
				return string.format("%.2f", value)
			end
		)
		classScale.isEnabled = isClassResourceEnabled
		list[#list + 1] = classScale
	end

	if isPlayer and classHasTotemFrame then
		local crDef = def.classResource or {}
		local totemDef = type(crDef.totemFrame) == "table" and crDef.totemFrame or {}
		local function normalizeTotemValue(value)
			if value == true then return { enabled = true } end
			if type(value) == "table" then return value end
			return {}
		end
		local function getTotemConfig() return normalizeTotemValue(getValue(unit, { "classResource", "totemFrame" }, crDef.totemFrame)) end
		local function updateTotemConfig(handler)
			local current = getTotemConfig()
			local nextCfg = {}
			for key, val in pairs(current) do
				nextCfg[key] = val
			end
			handler(nextCfg)
			setValue(unit, { "classResource", "totemFrame" }, nextCfg)
		end
		local function isTotemFrameEnabled()
			local cfg = getTotemConfig()
			local enabled = cfg.enabled
			if enabled == nil then enabled = totemDef.enabled end
			return enabled == true
		end

		list[#list + 1] = { name = L["Totem Frame"] or "Totem Frame", kind = UF.ui.settingType.Collapsible, id = "totemFrame", defaultCollapsed = true }

		list[#list + 1] = checkbox(L["Re-anchor Totem Frame"] or "Re-anchor Totem Frame", isTotemFrameEnabled, function(val)
			updateTotemConfig(function(cfg) cfg.enabled = val and true or false end)
			refreshSelf()
		end, totemDef.enabled == true, "totemFrame")

		local totemAnchorOptions = {
			{ value = "TOPLEFT", label = L["Top left"] or "Top left" },
			{ value = "TOP", label = DIRECTION_TOP_LABEL },
			{ value = "TOPRIGHT", label = L["Top right"] or "Top right" },
			{ value = "LEFT", label = DIRECTION_LEFT_LABEL },
			{ value = "CENTER", label = L["Center"] or "Center" },
			{ value = "RIGHT", label = DIRECTION_RIGHT_LABEL },
			{ value = "BOTTOMLEFT", label = L["Bottom left"] or "Bottom left" },
			{ value = "BOTTOM", label = DIRECTION_BOTTOM_LABEL },
			{ value = "BOTTOMRIGHT", label = L["Bottom right"] or "Bottom right" },
		}
		local totemAnchor = radioDropdown(L["Anchor"] or "Anchor", totemAnchorOptions, function()
			local cfg = getTotemConfig()
			return cfg.anchor or totemDef.anchor or "BOTTOMRIGHT"
		end, function(val)
			updateTotemConfig(function(cfg) cfg.anchor = val or "BOTTOMRIGHT" end)
			refreshSelf()
		end, totemDef.anchor or "BOTTOMRIGHT", "totemFrame")
		totemAnchor.isEnabled = isTotemFrameEnabled
		list[#list + 1] = totemAnchor

		local totemOffsetX = slider(L["Offset X"] or "Offset X", -OFFSET_RANGE, OFFSET_RANGE, 1, function()
			local cfg = getTotemConfig()
			local offset = cfg.offset or {}
			if offset.x == nil and totemDef.offset then return totemDef.offset.x or 0 end
			return offset.x or 0
		end, function(val)
			debounced(unit .. "_totemFrameOffsetX", function()
				updateTotemConfig(function(cfg)
					cfg.offset = cfg.offset or {}
					cfg.offset.x = val or 0
				end)
				refreshSelf()
			end)
		end, (totemDef.offset and totemDef.offset.x) or 0, "totemFrame", true)
		totemOffsetX.isEnabled = isTotemFrameEnabled
		list[#list + 1] = totemOffsetX

		local totemOffsetY = slider(L["Offset Y"] or "Offset Y", -OFFSET_RANGE, OFFSET_RANGE, 1, function()
			local cfg = getTotemConfig()
			local offset = cfg.offset or {}
			if offset.y == nil and totemDef.offset then return totemDef.offset.y or 0 end
			return offset.y or 0
		end, function(val)
			debounced(unit .. "_totemFrameOffsetY", function()
				updateTotemConfig(function(cfg)
					cfg.offset = cfg.offset or {}
					cfg.offset.y = val or 0
				end)
				refreshSelf()
			end)
		end, (totemDef.offset and totemDef.offset.y) or 0, "totemFrame", true)
		totemOffsetY.isEnabled = isTotemFrameEnabled
		list[#list + 1] = totemOffsetY

		local totemScale = slider(
			L["Scale"] or "Scale",
			0.5,
			2,
			0.05,
			function()
				local cfg = getTotemConfig()
				local v = cfg.scale
				if v == nil then v = totemDef.scale or 1 end
				return SnapToStep(v, 0.05, 0.5, 2) or 1
			end,
			function(val)
				debounced(unit .. "_totemFrameScale", function()
					val = SnapToStep(val, 0.05, 0.5, 2) or 1
					updateTotemConfig(function(cfg) cfg.scale = val end)
					refreshSelf()
					refreshSettingsUI()
				end)
			end,
			SnapToStep(totemDef.scale or 1, 0.05, 0.5, 2) or 1,
			"totemFrame",
			true,
			function(value)
				value = SnapToStep(value, 0.05, 0.5, 2) or 1
				return string.format("%.2f", value)
			end
		)
		totemScale.isEnabled = isTotemFrameEnabled
		list[#list + 1] = totemScale

		local totemSample = checkbox(L["Show sample in Edit Mode"] or "Show sample in Edit Mode", function()
			local cfg = getTotemConfig()
			local val = cfg.showSample
			if val == nil then val = totemDef.showSample end
			return val == true
		end, function(val)
			updateTotemConfig(function(cfg) cfg.showSample = val and true or false end)
			refreshSelf()
		end, totemDef.showSample == true, "totemFrame")
		totemSample.isEnabled = isTotemFrameEnabled
		list[#list + 1] = totemSample
	end

	local raidIconDef = def.raidIcon or { enabled = true, size = 18, offset = { x = 0, y = -2 } }
	local function isRaidIconEnabled() return getValue(unit, { "raidIcon", "enabled" }, raidIconDef.enabled ~= false) ~= false end
	list[#list + 1] = { name = L["Raid marker"] or "Raid marker", kind = UF.ui.settingType.Collapsible, id = "raidicon", defaultCollapsed = true }

	list[#list + 1] = checkbox(L["Show raid target icon"] or "Show raid target icon", isRaidIconEnabled, function(val)
		setValue(unit, { "raidIcon", "enabled" }, val and true or false)
		refreshSelf()
	end, raidIconDef.enabled ~= false, "raidicon")

	local raidIconSize = slider(L["Icon size"] or "Icon size", 10, 30, 1, function() return getValue(unit, { "raidIcon", "size" }, raidIconDef.size or 18) end, function(val)
		local v = val or raidIconDef.size or 18
		if v < 10 then v = 10 end
		if v > 30 then v = 30 end
		setValue(unit, { "raidIcon", "size" }, v)
		refreshSelf()
	end, raidIconDef.size or 18, "raidicon", true)
	raidIconSize.isEnabled = isRaidIconEnabled
	list[#list + 1] = raidIconSize

	local raidIconOffsetX = slider(
		L["Offset X"] or "Offset X",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "raidIcon", "offset", "x" }, (raidIconDef.offset and raidIconDef.offset.x) or 0) end,
		function(val)
			setValue(unit, { "raidIcon", "offset", "x" }, val or 0)
			refreshSelf()
		end,
		(raidIconDef.offset and raidIconDef.offset.x) or 0,
		"raidicon",
		true
	)
	raidIconOffsetX.isEnabled = isRaidIconEnabled
	list[#list + 1] = raidIconOffsetX

	local raidIconOffsetY = slider(
		L["Offset Y"] or "Offset Y",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "raidIcon", "offset", "y" }, (raidIconDef.offset and raidIconDef.offset.y) or 0) end,
		function(val)
			setValue(unit, { "raidIcon", "offset", "y" }, val or 0)
			refreshSelf()
		end,
		(raidIconDef.offset and raidIconDef.offset.y) or 0,
		"raidicon",
		true
	)
	raidIconOffsetY.isEnabled = isRaidIconEnabled
	list[#list + 1] = raidIconOffsetY

	if unit == "player" or unit == "target" or unit == "focus" or isBoss then
		local castDef = def.cast or {}
		list[#list + 1] = { name = L["Castbar"] or "Cast Bar", kind = UF.ui.settingType.Collapsible, id = "cast", defaultCollapsed = true }
		local function isCastEnabled() return getValue(unit, { "cast", "enabled" }, castDef.enabled ~= false) ~= false end
		local function isCastIconEnabled() return isCastEnabled() and getValue(unit, { "cast", "showIcon" }, castDef.showIcon ~= false) ~= false end
		local function isCastNameEnabled() return isCastEnabled() and getValue(unit, { "cast", "showName" }, castDef.showName ~= false) ~= false end
		local function isCastDurationEnabled() return isCastEnabled() and getValue(unit, { "cast", "showDuration" }, castDef.showDuration ~= false) ~= false end

		list[#list + 1] = checkbox(L["Show cast bar"] or "Show cast bar", function() return getValue(unit, { "cast", "enabled" }, castDef.enabled ~= false) ~= false end, function(val)
			setValue(unit, { "cast", "enabled" }, val and true or false)
			refresh()
			refreshSettingsUI()
		end, castDef.enabled ~= false, "cast")

		local castWidth = slider(L["UFWidth"] or "Frame width", 50, 800, 1, function() return getValue(unit, { "cast", "width" }, castDef.width or def.width or 220) end, function(val)
			setValue(unit, { "cast", "width" }, math.max(50, val or 50))
			refresh()
		end, castDef.width or def.width or 220, "cast", true)
		castWidth.isEnabled = isCastEnabled
		list[#list + 1] = castWidth

		local castHeight = slider(L["Cast bar height"] or "Cast bar height", 6, 200, 1, function() return getValue(unit, { "cast", "height" }, castDef.height or 16) end, function(val)
			setValue(unit, { "cast", "height" }, val or castDef.height or 16)
			refresh()
		end, castDef.height or 16, "cast", true)
		castHeight.isEnabled = isCastEnabled
		list[#list + 1] = castHeight

		local castStrata = radioDropdown(
			L["UFCastStrata"] or "Castbar strata",
			strataOptionsWithDefault,
			function() return getValue(unit, { "cast", "strata" }, castDef.strata or "") end,
			function(val)
				setValue(unit, { "cast", "strata" }, (val and val ~= "") and val or nil)
				refresh()
			end,
			castDef.strata or "",
			"cast"
		)
		castStrata.isEnabled = isCastEnabled
		list[#list + 1] = castStrata

		local castFrameLevelOffset = slider(L["UFCastFrameLevelOffset"] or "Castbar frame level offset", -20, 50, 1, function()
			local fallback = castDef.frameLevelOffset
			if fallback == nil then fallback = 1 end
			return getValue(unit, { "cast", "frameLevelOffset" }, fallback)
		end, function(val)
			setValue(unit, { "cast", "frameLevelOffset" }, val)
			refresh()
		end, (castDef.frameLevelOffset == nil) and 1 or castDef.frameLevelOffset, "cast", true)
		castFrameLevelOffset.isEnabled = isCastEnabled
		list[#list + 1] = castFrameLevelOffset

		local anchorOpts = {
			{ value = "TOP", label = DIRECTION_TOP_LABEL },
			{ value = "BOTTOM", label = DIRECTION_BOTTOM_LABEL },
		}
		local castAnchor = radioDropdown(L["Anchor"] or "Anchor", anchorOpts, function() return getValue(unit, { "cast", "anchor" }, castDef.anchor or "BOTTOM") end, function(val)
			setValue(unit, { "cast", "anchor" }, val or "BOTTOM")
			refresh()
		end, castDef.anchor or "BOTTOM", "cast")
		castAnchor.isEnabled = isCastEnabled
		list[#list + 1] = castAnchor

		local castOffsetX = slider(
			L["Offset X"] or "Offset X",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "cast", "offset", "x" }, (castDef.offset and castDef.offset.x) or 0) end,
			function(val)
				setValue(unit, { "cast", "offset", "x" }, val or 0)
				refresh()
			end,
			(castDef.offset and castDef.offset.x) or 0,
			"cast",
			true
		)
		castOffsetX.isEnabled = isCastEnabled
		list[#list + 1] = castOffsetX

		local castOffsetY = slider(
			L["Offset Y"] or "Offset Y",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "cast", "offset", "y" }, (castDef.offset and castDef.offset.y) or 0) end,
			function(val)
				setValue(unit, { "cast", "offset", "y" }, val or 0)
				refresh()
			end,
			(castDef.offset and castDef.offset.y) or 0,
			"cast",
			true
		)
		castOffsetY.isEnabled = isCastEnabled
		list[#list + 1] = castOffsetY

		list[#list + 1] = checkbox(L["Show spell icon"] or "Show spell icon", function() return getValue(unit, { "cast", "showIcon" }, castDef.showIcon ~= false) ~= false end, function(val)
			setValue(unit, { "cast", "showIcon" }, val and true or false)
			refresh()
			refreshSettingsUI()
		end, castDef.showIcon ~= false, "cast", isCastEnabled)

		local castIconSize = slider(L["Icon size"] or "Icon size", 8, 64, 1, function() return getValue(unit, { "cast", "iconSize" }, castDef.iconSize or 22) end, function(val)
			setValue(unit, { "cast", "iconSize" }, val or castDef.iconSize or 22)
			refresh()
		end, castDef.iconSize or 22, "cast", true)
		castIconSize.isEnabled = isCastIconEnabled
		list[#list + 1] = castIconSize

		local castIconOffsetX = slider(
			L["Icon X Offset"] or "Icon X Offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "cast", "iconOffset", "x" }, (castDef.iconOffset and castDef.iconOffset.x) or -4) end,
			function(val)
				setValue(unit, { "cast", "iconOffset", "x" }, val or -4)
				refresh()
			end,
			(castDef.iconOffset and castDef.iconOffset.x) or -4,
			"cast",
			true
		)
		castIconOffsetX.isEnabled = isCastIconEnabled
		list[#list + 1] = castIconOffsetX

		local function isCastIconBorderEnabled() return isCastIconEnabled() and getValue(unit, { "cast", "iconBorder", "enabled" }, (castDef.iconBorder and castDef.iconBorder.enabled) == true) == true end

		list[#list + 1] = checkboxColor({
			name = L["Cast icon border"] or "Cast icon border",
			parentId = "cast",
			defaultChecked = (castDef.iconBorder and castDef.iconBorder.enabled) == true,
			isChecked = function() return isCastIconBorderEnabled() end,
			onChecked = function(val)
				setValue(unit, { "cast", "iconBorder", "enabled" }, val and true or false)
				if val and not getValue(unit, { "cast", "iconBorder", "color" }) then
					setValue(unit, { "cast", "iconBorder", "color" }, (castDef.iconBorder and castDef.iconBorder.color) or { 0, 0, 0, 0.8 })
				end
				refresh()
				refreshSettingsUI()
			end,
			getColor = function()
				local fallback = (castDef.iconBorder and castDef.iconBorder.color) or { 0, 0, 0, 0.8 }
				return toRGBA(getValue(unit, { "cast", "iconBorder", "color" }, castDef.iconBorder and castDef.iconBorder.color), fallback)
			end,
			onColor = function(color)
				setColor(unit, { "cast", "iconBorder", "color" }, color.r, color.g, color.b, color.a)
				setValue(unit, { "cast", "iconBorder", "enabled" }, true)
				refresh()
			end,
			colorDefault = {
				r = (castDef.iconBorder and castDef.iconBorder.color and castDef.iconBorder.color[1]) or 0,
				g = (castDef.iconBorder and castDef.iconBorder.color and castDef.iconBorder.color[2]) or 0,
				b = (castDef.iconBorder and castDef.iconBorder.color and castDef.iconBorder.color[3]) or 0,
				a = (castDef.iconBorder and castDef.iconBorder.color and castDef.iconBorder.color[4]) or 0.8,
			},
			isEnabled = isCastIconEnabled,
		})

		local castIconBorderTexture = checkboxDropdown(
			L["Border texture"] or "Border texture",
			borderOptions,
			function() return getValue(unit, { "cast", "iconBorder", "texture" }, (castDef.iconBorder and castDef.iconBorder.texture) or "DEFAULT") end,
			function(val)
				setValue(unit, { "cast", "iconBorder", "texture" }, val or "DEFAULT")
				refresh()
			end,
			(castDef.iconBorder and castDef.iconBorder.texture) or "DEFAULT",
			"cast"
		)
		castIconBorderTexture.isEnabled = isCastIconBorderEnabled
		list[#list + 1] = castIconBorderTexture

		local castIconBorderSize = slider(L["Border size"] or "Border size", 1, 64, 1, function()
			local border = getValue(unit, { "cast", "iconBorder" }, castDef.iconBorder or {})
			return border.edgeSize or 1
		end, function(val)
			local border = getValue(unit, { "cast", "iconBorder" }, castDef.iconBorder or {})
			border.edgeSize = val or 1
			setValue(unit, { "cast", "iconBorder" }, border)
			refresh()
		end, (castDef.iconBorder and castDef.iconBorder.edgeSize) or 1, "cast", true)
		castIconBorderSize.isEnabled = isCastIconBorderEnabled
		list[#list + 1] = castIconBorderSize

		local castIconBorderOffset = slider(L["Border offset"] or "Border offset", 0, 64, 1, function()
			local border = getValue(unit, { "cast", "iconBorder" }, castDef.iconBorder or {})
			if border.offset == nil then return border.edgeSize or 1 end
			return border.offset
		end, function(val)
			local border = getValue(unit, { "cast", "iconBorder" }, castDef.iconBorder or {})
			border.offset = val or 0
			setValue(unit, { "cast", "iconBorder" }, border)
			refresh()
		end, (castDef.iconBorder and castDef.iconBorder.offset) or (castDef.iconBorder and castDef.iconBorder.edgeSize) or 1, "cast", true)
		castIconBorderOffset.isEnabled = isCastIconBorderEnabled
		list[#list + 1] = castIconBorderOffset

		list[#list + 1] = { name = "", kind = UF.ui.settingType.Divider, parentId = "cast" }

		list[#list + 1] = checkbox(L["Show spell name"] or "Show spell name", function() return getValue(unit, { "cast", "showName" }, castDef.showName ~= false) ~= false end, function(val)
			setValue(unit, { "cast", "showName" }, val and true or false)
			refresh()
			refreshSettingsUI()
		end, castDef.showName ~= false, "cast", isCastEnabled)

		if unit == "player" then
			list[#list + 1] = checkbox(
				L["Show cast target"] or "Show cast target",
				function() return getValue(unit, { "cast", "showCastTarget" }, castDef.showCastTarget == true) == true end,
				function(val)
					setValue(unit, { "cast", "showCastTarget" }, val and true or false)
					refresh()
					refreshSettingsUI()
				end,
				castDef.showCastTarget == true,
				"cast",
				isCastNameEnabled
			)
		end

		local castNameAnchor = radioDropdown(L["UFCastNameAnchor"] or "Cast name anchor", UF.ui.anchorOptions, function()
			local fallback = castDef.nameAnchor or "LEFT"
			if fallback ~= "LEFT" and fallback ~= "CENTER" and fallback ~= "RIGHT" then fallback = "LEFT" end
			local value = getValue(unit, { "cast", "nameAnchor" }, fallback)
			if value ~= "LEFT" and value ~= "CENTER" and value ~= "RIGHT" then return fallback end
			return value
		end, function(val)
			local value = val
			if value ~= "LEFT" and value ~= "CENTER" and value ~= "RIGHT" then value = "LEFT" end
			setValue(unit, { "cast", "nameAnchor" }, value)
			refresh()
		end, castDef.nameAnchor or "LEFT", "cast")
		castNameAnchor.isEnabled = isCastNameEnabled
		list[#list + 1] = castNameAnchor

		local castNameX = slider(
			L["Name X Offset"] or "Name X Offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "cast", "nameOffset", "x" }, (castDef.nameOffset and castDef.nameOffset.x) or 6) end,
			function(val)
				setValue(unit, { "cast", "nameOffset", "x" }, val or 0)
				refresh()
			end,
			(castDef.nameOffset and castDef.nameOffset.x) or 6,
			"cast",
			true
		)
		castNameX.isEnabled = isCastNameEnabled
		list[#list + 1] = castNameX

		local castNameY = slider(
			L["Name Y Offset"] or "Name Y Offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "cast", "nameOffset", "y" }, (castDef.nameOffset and castDef.nameOffset.y) or 0) end,
			function(val)
				setValue(unit, { "cast", "nameOffset", "y" }, val or 0)
				refresh()
			end,
			(castDef.nameOffset and castDef.nameOffset.y) or 0,
			"cast",
			true
		)
		castNameY.isEnabled = isCastNameEnabled
		list[#list + 1] = castNameY

		local function getCastFont() return getValue(unit, { "cast", "font" }, castDef.font or UF.ui.globalFontConfigKey()) end

		local castNameFont = {
			name = L["Font"] or "Font",
			kind = UF.ui.settingType.DropdownColor,
			height = 180,
			parentId = "cast",
			default = castDef.font or UF.ui.globalFontConfigKey(),
			generator = function(_, root)
				local opts = fontOptions()
				if type(opts) ~= "table" then return end
				for _, opt in ipairs(opts) do
					local value = opt.value
					local label = opt.label
					root:CreateCheckbox(label, function() return getCastFont() == value end, function()
						if getCastFont() ~= value then
							setValue(unit, { "cast", "font" }, value)
							refresh()
						end
					end)
				end
			end,
			colorDefault = { r = 1, g = 1, b = 1, a = 1 },
			colorGet = function()
				local fallback = castDef.fontColor or { 1, 1, 1, 1 }
				local r, g, b, a = toRGBA(getValue(unit, { "cast", "fontColor" }, castDef.fontColor), fallback)
				return { r = r, g = g, b = b, a = a }
			end,
			colorSet = function(_, color)
				setColor(unit, { "cast", "fontColor" }, color.r, color.g, color.b, color.a)
				refresh()
			end,
			hasOpacity = true,
		}
		castNameFont.isEnabled = isCastNameEnabled
		list[#list + 1] = castNameFont

		local castNameFontOutline = checkboxDropdown(
			L["Font outline"] or "Font outline",
			UF.ui.outlineOptions,
			function()
				return UF.ui.normalizeFontStyleChoice(
					getValue(unit, { "cast", "fontOutline" }, castDef.fontOutline or "OUTLINE"),
					castDef.fontOutline or "OUTLINE"
				)
			end,
			function(val)
				setValue(unit, { "cast", "fontOutline" }, UF.ui.normalizeFontStyleChoice(val, castDef.fontOutline or "OUTLINE"))
				refresh()
			end,
			castDef.fontOutline or "OUTLINE",
			"cast"
		)
		castNameFontOutline.isEnabled = isCastNameEnabled
		list[#list + 1] = castNameFontOutline

		local castNameFontSize = slider(FONT_SIZE_LABEL, 8, 30, 1, function() return getValue(unit, { "cast", "fontSize" }, castDef.fontSize or 12) end, function(val)
			setValue(unit, { "cast", "fontSize" }, val or 12)
			refresh()
		end, castDef.fontSize or 12, "cast", true)
		castNameFontSize.isEnabled = isCastNameEnabled
		list[#list + 1] = castNameFontSize

		local castNameMaxCharsSetting = slider(
			L["UFCastNameMaxChars"] or "Cast name max width",
			0,
			100,
			1,
			function() return getValue(unit, { "cast", "nameMaxChars" }, castDef.nameMaxChars or 0) end,
			function(val)
				setValue(unit, { "cast", "nameMaxChars" }, val or 0)
				refresh()
			end,
			castDef.nameMaxChars or 0,
			"cast",
			true
		)
		castNameMaxCharsSetting.isEnabled = isCastNameEnabled
		list[#list + 1] = castNameMaxCharsSetting

		list[#list + 1] = { name = "", kind = UF.ui.settingType.Divider, parentId = "cast" }

		list[#list + 1] = checkbox(
			L["Show cast duration"] or "Show cast duration",
			function() return getValue(unit, { "cast", "showDuration" }, castDef.showDuration ~= false) ~= false end,
			function(val)
				setValue(unit, { "cast", "showDuration" }, val and true or false)
				refresh()
				refreshSettingsUI()
			end,
			castDef.showDuration ~= false,
			"cast",
			isCastEnabled
		)

		local castDurationFormatOptions = {
			{ value = "REMAINING", label = L["UFCastDurationRemaining"] or "Remaining" },
			{ value = "REMAINING_TOTAL", label = L["UFCastDurationRemainingTotal"] or "Remaining/Total" },
			{ value = "ELAPSED_TOTAL", label = L["UFCastDurationElapsedTotal"] or "Elapsed/Total" },
		}

		local castDurationFormat = checkboxDropdown(
			L["UFCastDurationFormat"] or "Cast duration format",
			castDurationFormatOptions,
			function() return getValue(unit, { "cast", "durationFormat" }, castDef.durationFormat or "REMAINING") end,
			function(val)
				setValue(unit, { "cast", "durationFormat" }, val or "REMAINING")
				refresh()
			end,
			castDef.durationFormat or "REMAINING",
			"cast"
		)
		castDurationFormat.isEnabled = isCastDurationEnabled
		list[#list + 1] = castDurationFormat

		local castDurX = slider(
			L["Duration X Offset"] or "Duration X Offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "cast", "durationOffset", "x" }, (castDef.durationOffset and castDef.durationOffset.x) or -6) end,
			function(val)
				setValue(unit, { "cast", "durationOffset", "x" }, val or 0)
				refresh()
			end,
			(castDef.durationOffset and castDef.durationOffset.x) or -6,
			"cast",
			true
		)

		castDurX.isEnabled = isCastDurationEnabled
		list[#list + 1] = castDurX

		local castDurY = slider(
			L["Duration Y Offset"] or "Duration Y Offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "cast", "durationOffset", "y" }, (castDef.durationOffset and castDef.durationOffset.y) or 0) end,
			function(val)
				setValue(unit, { "cast", "durationOffset", "y" }, val or 0)
				refresh()
			end,
			(castDef.durationOffset and castDef.durationOffset.y) or 0,
			"cast",
			true
		)
		castDurY.isEnabled = isCastDurationEnabled
		list[#list + 1] = castDurY

		local castTexture = checkboxDropdown(L["Cast texture"] or "Cast texture", textureOpts, function() return getValue(unit, { "cast", "texture" }, castDef.texture or "DEFAULT") end, function(val)
			setValue(unit, { "cast", "texture" }, val)
			refresh()
		end, castDef.texture or "DEFAULT", "cast")
		castTexture.isEnabled = isCastEnabled
		list[#list + 1] = castTexture

		list[#list + 1] = { name = "", kind = UF.ui.settingType.Divider, parentId = "cast" }

		local castBackdrop = checkboxColor({
			name = L["Show bar backdrop"] or "Show bar backdrop",
			parentId = "cast",
			defaultChecked = (castDef.backdrop and castDef.backdrop.enabled) ~= false,
			isChecked = function() return getValue(unit, { "cast", "backdrop", "enabled" }, (castDef.backdrop and castDef.backdrop.enabled) ~= false) ~= false end,
			onChecked = function(val)
				setValue(unit, { "cast", "backdrop", "enabled" }, val and true or false)
				refresh()
				refreshSettingsUI()
			end,
			getColor = function()
				return toRGBA(getValue(unit, { "cast", "backdrop", "color" }, castDef.backdrop and castDef.backdrop.color), castDef.backdrop and castDef.backdrop.color or { 0, 0, 0, 0.6 })
			end,
			onColor = function(color)
				setColor(unit, { "cast", "backdrop", "color" }, color.r, color.g, color.b, color.a)
				refresh()
			end,
			colorDefault = { r = 0, g = 0, b = 0, a = 0.6 },
			isEnabled = isCastEnabled,
		})
		castBackdrop.isEnabled = isCastEnabled
		list[#list + 1] = castBackdrop
		list[#list + 1] = checkboxDropdown(
			L["Backdrop texture"] or "Backdrop texture",
			textureOpts,
			function() return getValue(unit, { "cast", "backdrop", "texture" }, (castDef.backdrop and castDef.backdrop.texture) or "DEFAULT") end,
			function(val)
				setValue(unit, { "cast", "backdrop", "texture" }, val or "DEFAULT")
				refresh()
			end,
			(castDef.backdrop and castDef.backdrop.texture) or "DEFAULT",
			"cast"
		)
		list[#list].isEnabled = function() return isCastEnabled() and getValue(unit, { "cast", "backdrop", "enabled" }, (castDef.backdrop and castDef.backdrop.enabled) ~= false) ~= false end

		local function isCastBorderEnabled() return getValue(unit, { "cast", "border", "enabled" }, (castDef.border and castDef.border.enabled) == true) == true end

		list[#list + 1] = checkboxColor({
			name = L["Cast bar border"] or "Cast bar border",
			parentId = "cast",
			defaultChecked = (castDef.border and castDef.border.enabled) == true,
			isChecked = function() return isCastBorderEnabled() end,
			onChecked = function(val)
				setValue(unit, { "cast", "border", "enabled" }, val and true or false)
				if val and not getValue(unit, { "cast", "border", "color" }) then setValue(unit, { "cast", "border", "color" }, (castDef.border and castDef.border.color) or { 0, 0, 0, 0.8 }) end
				refresh()
				refreshSettingsUI()
			end,
			getColor = function()
				local fallback = (castDef.border and castDef.border.color) or { 0, 0, 0, 0.8 }
				return toRGBA(getValue(unit, { "cast", "border", "color" }, castDef.border and castDef.border.color), fallback)
			end,
			onColor = function(color)
				setColor(unit, { "cast", "border", "color" }, color.r, color.g, color.b, color.a)
				setValue(unit, { "cast", "border", "enabled" }, true)
				refresh()
			end,
			colorDefault = {
				r = (castDef.border and castDef.border.color and castDef.border.color[1]) or 0,
				g = (castDef.border and castDef.border.color and castDef.border.color[2]) or 0,
				b = (castDef.border and castDef.border.color and castDef.border.color[3]) or 0,
				a = (castDef.border and castDef.border.color and castDef.border.color[4]) or 0.8,
			},
			isEnabled = isCastEnabled,
		})

		local castBorderTexture = checkboxDropdown(
			L["Border texture"] or "Border texture",
			borderOptions,
			function() return getValue(unit, { "cast", "border", "texture" }, (castDef.border and castDef.border.texture) or "DEFAULT") end,
			function(val)
				setValue(unit, { "cast", "border", "texture" }, val or "DEFAULT")
				refresh()
			end,
			(castDef.border and castDef.border.texture) or "DEFAULT",
			"cast"
		)
		castBorderTexture.isEnabled = isCastBorderEnabled
		list[#list + 1] = castBorderTexture

		local castBorderSize = slider(L["Border size"] or "Border size", 1, 64, 1, function()
			local border = getValue(unit, { "cast", "border" }, castDef.border or {})
			return border.edgeSize or 1
		end, function(val)
			local border = getValue(unit, { "cast", "border" }, castDef.border or {})
			border.edgeSize = val or 1
			setValue(unit, { "cast", "border" }, border)
			refresh()
		end, (castDef.border and castDef.border.edgeSize) or 1, "cast", true)
		castBorderSize.isEnabled = isCastBorderEnabled
		list[#list + 1] = castBorderSize

		local castBorderOffset = slider(L["Border offset"] or "Border offset", 0, 64, 1, function()
			local border = getValue(unit, { "cast", "border" }, castDef.border or {})
			if border.offset == nil then return border.edgeSize or 1 end
			return border.offset
		end, function(val)
			local border = getValue(unit, { "cast", "border" }, castDef.border or {})
			border.offset = val or 0
			setValue(unit, { "cast", "border" }, border)
			refresh()
		end, (castDef.border and castDef.border.offset) or (castDef.border and castDef.border.edgeSize) or 1, "cast", true)
		castBorderOffset.isEnabled = isCastBorderEnabled
		list[#list + 1] = castBorderOffset

		list[#list + 1] = { name = "", kind = UF.ui.settingType.Divider, parentId = "cast" }

		local function isCastClassColorEnabled() return getValue(unit, { "cast", "useClassColor" }, castDef.useClassColor == true) == true end
		local function isCastGradientEnabled()
			if unit ~= "player" then return false end
			return isCastEnabled() and not isCastClassColorEnabled() and getValue(unit, { "cast", "useGradient" }, castDef.useGradient == true) == true
		end
		local function isCastColorEnabled() return isCastEnabled() and not isCastClassColorEnabled() and not isCastGradientEnabled() end

		list[#list + 1] = {
			name = L["Cast color"] or "Cast color",
			kind = UF.ui.settingType.Color,
			parentId = "cast",
			isEnabled = isCastColorEnabled,
			get = function() return getValue(unit, { "cast", "color" }, castDef.color or { 0.9, 0.7, 0.2, 1 }) end,
			set = function(_, color)
				setColor(unit, { "cast", "color" }, color.r, color.g, color.b, color.a)
				refresh()
			end,
			colorGet = function() return getValue(unit, { "cast", "color" }, castDef.color or { 0.9, 0.7, 0.2, 1 }) end,
			colorSet = function(_, color)
				setColor(unit, { "cast", "color" }, color.r, color.g, color.b, color.a)
				refresh()
			end,
			colorDefault = {
				r = (castDef.color and castDef.color[1]) or 0.9,
				g = (castDef.color and castDef.color[2]) or 0.7,
				b = (castDef.color and castDef.color[3]) or 0.2,
				a = (castDef.color and castDef.color[4]) or 1,
			},
			hasOpacity = true,
		}

		list[#list + 1] = checkbox(L["Use class color"] or "Use class color", isCastClassColorEnabled, function(val)
			local useClassColor = val and true or false
			setValue(unit, { "cast", "useClassColor" }, useClassColor)
			if useClassColor then setValue(unit, { "cast", "useGradient" }, false) end
			refresh()
			refreshSettingsUI()
		end, castDef.useClassColor == true, "cast", isCastEnabled)

		if unit == "player" then
			list[#list + 1] = checkbox(L["Use gradient"] or "Use gradient", isCastGradientEnabled, function(val)
				local useGradient = val and true or false
				setValue(unit, { "cast", "useGradient" }, useGradient)
				if useGradient then setValue(unit, { "cast", "useClassColor" }, false) end
				refresh()
				refreshSettingsUI()
			end, castDef.useGradient == true, "cast", isCastEnabled)

			local castGradientModeOptions = {
				{ value = "CASTBAR", label = L["Gradient with castbar"] or "Gradient with castbar" },
				{ value = "BAR_END", label = L["Gradient at end of bar"] or "Gradient at end of bar" },
			}
			local castGradientMode = checkboxDropdown(
				L["Gradient mode"] or "Gradient mode",
				castGradientModeOptions,
				function() return getValue(unit, { "cast", "gradientMode" }, castDef.gradientMode or "CASTBAR") end,
				function(val)
					setValue(unit, { "cast", "gradientMode" }, val or "CASTBAR")
					refresh()
				end,
				castDef.gradientMode or "CASTBAR",
				"cast"
			)
			castGradientMode.isEnabled = function() return isCastEnabled() and isCastGradientEnabled() end
			list[#list + 1] = castGradientMode

			list[#list + 1] = {
				name = L["Gradient start color"] or "Gradient start color",
				kind = UF.ui.settingType.Color,
				parentId = "cast",
				isEnabled = function() return isCastEnabled() and isCastGradientEnabled() end,
				get = function() return getValue(unit, { "cast", "gradientStartColor" }, castDef.gradientStartColor or { 1, 1, 1, 1 }) end,
				set = function(_, color)
					setColor(unit, { "cast", "gradientStartColor" }, color.r, color.g, color.b, color.a)
					refresh()
				end,
				colorGet = function() return getValue(unit, { "cast", "gradientStartColor" }, castDef.gradientStartColor or { 1, 1, 1, 1 }) end,
				colorSet = function(_, color)
					setColor(unit, { "cast", "gradientStartColor" }, color.r, color.g, color.b, color.a)
					refresh()
				end,
				colorDefault = {
					r = (castDef.gradientStartColor and castDef.gradientStartColor[1]) or 1,
					g = (castDef.gradientStartColor and castDef.gradientStartColor[2]) or 1,
					b = (castDef.gradientStartColor and castDef.gradientStartColor[3]) or 1,
					a = (castDef.gradientStartColor and castDef.gradientStartColor[4]) or 1,
				},
				hasOpacity = true,
			}

			list[#list + 1] = {
				name = L["Gradient end color"] or "Gradient end color",
				kind = UF.ui.settingType.Color,
				parentId = "cast",
				isEnabled = function() return isCastEnabled() and isCastGradientEnabled() end,
				get = function() return getValue(unit, { "cast", "gradientEndColor" }, castDef.gradientEndColor or { 1, 1, 1, 1 }) end,
				set = function(_, color)
					setColor(unit, { "cast", "gradientEndColor" }, color.r, color.g, color.b, color.a)
					refresh()
				end,
				colorGet = function() return getValue(unit, { "cast", "gradientEndColor" }, castDef.gradientEndColor or { 1, 1, 1, 1 }) end,
				colorSet = function(_, color)
					setColor(unit, { "cast", "gradientEndColor" }, color.r, color.g, color.b, color.a)
					refresh()
				end,
				colorDefault = {
					r = (castDef.gradientEndColor and castDef.gradientEndColor[1]) or 1,
					g = (castDef.gradientEndColor and castDef.gradientEndColor[2]) or 1,
					b = (castDef.gradientEndColor and castDef.gradientEndColor[3]) or 1,
					a = (castDef.gradientEndColor and castDef.gradientEndColor[4]) or 1,
				},
				hasOpacity = true,
			}

			list[#list + 1] = { name = "", kind = UF.ui.settingType.Divider, parentId = "cast" }
		end

		if unit ~= "player" then
			list[#list + 1] = {
				name = L["Not interruptible color"] or "Not interruptible color",
				kind = UF.ui.settingType.Color,
				parentId = "cast",
				isEnabled = function() return isCastEnabled() and not isCastGradientEnabled() end,
				get = function() return getValue(unit, { "cast", "notInterruptibleColor" }, castDef.notInterruptibleColor or { 204 / 255, 204 / 255, 204 / 255, 1 }) end,
				set = function(_, color)
					setColor(unit, { "cast", "notInterruptibleColor" }, color.r, color.g, color.b, color.a)
					refresh()
				end,
				colorGet = function() return getValue(unit, { "cast", "notInterruptibleColor" }, castDef.notInterruptibleColor or { 204 / 255, 204 / 255, 204 / 255, 1 }) end,
				colorSet = function(_, color)
					setColor(unit, { "cast", "notInterruptibleColor" }, color.r, color.g, color.b, color.a)
					refresh()
				end,
				colorDefault = {
					r = (castDef.notInterruptibleColor and castDef.notInterruptibleColor[1]) or (204 / 255),
					g = (castDef.notInterruptibleColor and castDef.notInterruptibleColor[2]) or (204 / 255),
					b = (castDef.notInterruptibleColor and castDef.notInterruptibleColor[3]) or (204 / 255),
					a = (castDef.notInterruptibleColor and castDef.notInterruptibleColor[4]) or 1,
				},
				hasOpacity = true,
			}
		end

		list[#list + 1] = checkbox(
			L["Show interrupt feedback"] or "Show interrupt feedback",
			function() return getValue(unit, { "cast", "showInterruptFeedback" }, castDef.showInterruptFeedback ~= false) ~= false end,
			function(val)
				setValue(unit, { "cast", "showInterruptFeedback" }, val and true or false)
				refresh()
				refreshSettingsUI()
			end,
			castDef.showInterruptFeedback ~= false,
			"cast",
			isCastEnabled
		)

		local function isInterruptFeedbackEnabled() return isCastEnabled() and getValue(unit, { "cast", "showInterruptFeedback" }, castDef.showInterruptFeedback ~= false) ~= false end

		list[#list + 1] = checkbox(
			L["Show interrupt feedback glow"] or "Show interrupt feedback glow",
			function() return getValue(unit, { "cast", "showInterruptFeedbackGlow" }, castDef.showInterruptFeedbackGlow ~= false) ~= false end,
			function(val)
				setValue(unit, { "cast", "showInterruptFeedbackGlow" }, val and true or false)
				refresh()
			end,
			castDef.showInterruptFeedbackGlow ~= false,
			"cast",
			isInterruptFeedbackEnabled
		)

		list[#list + 1] = {
			name = L["Interrupt feedback color"] or "Interrupt feedback color",
			kind = UF.ui.settingType.Color,
			parentId = "cast",
			isEnabled = isInterruptFeedbackEnabled,
			get = function() return getValue(unit, { "cast", "interruptFeedbackColor" }, castDef.interruptFeedbackColor or { 0.85, 0.12, 0.12, 1 }) end,
			set = function(_, color)
				setColor(unit, { "cast", "interruptFeedbackColor" }, color.r, color.g, color.b, color.a)
				refresh()
			end,
			colorGet = function() return getValue(unit, { "cast", "interruptFeedbackColor" }, castDef.interruptFeedbackColor or { 0.85, 0.12, 0.12, 1 }) end,
			colorSet = function(_, color)
				setColor(unit, { "cast", "interruptFeedbackColor" }, color.r, color.g, color.b, color.a)
				refresh()
			end,
			colorDefault = {
				r = (castDef.interruptFeedbackColor and castDef.interruptFeedbackColor[1]) or 0.85,
				g = (castDef.interruptFeedbackColor and castDef.interruptFeedbackColor[2]) or 0.12,
				b = (castDef.interruptFeedbackColor and castDef.interruptFeedbackColor[3]) or 0.12,
				a = (castDef.interruptFeedbackColor and castDef.interruptFeedbackColor[4]) or 1,
			},
			hasOpacity = true,
		}
	end

	list[#list + 1] = { name = NAME or "Name", kind = UF.ui.settingType.Collapsible, id = "name", defaultCollapsed = true }
	local statusDef = def.status or {}
	local function isNameEnabled() return getValue(unit, { "status", "enabled" }, statusDef.enabled ~= false) ~= false end
	local function isLevelEnabled() return getValue(unit, { "status", "levelEnabled" }, statusDef.levelEnabled ~= false) ~= false end
	local function isUnitStatusEnabled() return getValue(unit, { "status", "unitStatus", "enabled" }, (statusDef.unitStatus and statusDef.unitStatus.enabled) == true) == true end
	local function isNameOrLevelEnabled() return isNameEnabled() or isLevelEnabled() end
	local classIconDef = statusDef.classificationIcon or { enabled = false, hideText = false, size = 16, offset = { x = -4, y = 0 } }
	local function isClassificationIconEnabled() return getValue(unit, { "status", "classificationIcon", "enabled" }, classIconDef.enabled == true) == true end
	local function addStatusStrataSetting(label, path, defaultValue, parentId, enabledFn)
		local setting = radioDropdown(label, strataOptionsWithDefault, function() return getValue(unit, path, defaultValue or "") end, function(val)
			setValue(unit, path, (val and val ~= "") and val or nil)
			refresh()
		end, defaultValue or "", parentId)
		setting.isEnabled = enabledFn
		list[#list + 1] = setting
	end
	local function makeScopedLabel(baseLabel, scopeLabel)
		local base = baseLabel or ""
		local scope = scopeLabel or ""
		if base ~= "" and scope ~= "" then return string.format("%s (%s)", base, scope) end
		if base ~= "" then return base end
		return scope
	end
	local nameScopeLabel = NAME or L["Name"] or "Name"
	local levelScopeLabel = LEVEL or L["Level"] or "Level"

	local showNameToggle = checkbox(L["Show name"] or L["Show name"] or "Show name", isNameEnabled, function(val)
		setValue(unit, { "status", "enabled" }, val and true or false)
		refresh()
		refreshSettingsUI()
	end, statusDef.enabled ~= false, "name")
	list[#list + 1] = showNameToggle

	local nameColorSetting = checkboxColor({
		name = L["Name color"] or "Name color",
		parentId = "name",
		defaultChecked = (statusDef.nameColorMode or "CLASS") ~= "CLASS",
		isChecked = function() return getValue(unit, { "status", "nameColorMode" }, statusDef.nameColorMode or "CLASS") ~= "CLASS" end,
		onChecked = function(val)
			setValue(unit, { "status", "nameColorMode" }, val and "CUSTOM" or "CLASS")
			refresh()
		end,
		getColor = function() return toRGBA(getValue(unit, { "status", "nameColor" }, statusDef.nameColor or { 0.8, 0.8, 1, 1 }), statusDef.nameColor or { 0.8, 0.8, 1, 1 }) end,
		onColor = function(color)
			setColor(unit, { "status", "nameColor" }, color.r, color.g, color.b, color.a)
			setValue(unit, { "status", "nameColorMode" }, "CUSTOM")
			refresh()
		end,
		colorDefault = {
			r = (statusDef.nameColor and statusDef.nameColor[1]) or 0.8,
			g = (statusDef.nameColor and statusDef.nameColor[2]) or 0.8,
			b = (statusDef.nameColor and statusDef.nameColor[3]) or 1,
			a = (statusDef.nameColor and statusDef.nameColor[4]) or 1,
		},
	})
	nameColorSetting.isEnabled = isNameEnabled
	list[#list + 1] = nameColorSetting

	local showNameReactionSetting = unit == "target" or unit == "targettarget" or unit == "focus" or isBossUnit(unit)
	if showNameReactionSetting then
		local nameReactionSetting = checkbox(
			L["UFNameUseReactionColor"] or "Use reaction color for NPC names",
			function() return getValue(unit, { "status", "nameUseReactionColor" }, statusDef.nameUseReactionColor == true) == true end,
			function(val)
				setValue(unit, { "status", "nameUseReactionColor" }, val and true or false)
				refresh()
			end,
			statusDef.nameUseReactionColor == true,
			"name"
		)
		nameReactionSetting.isEnabled = function() return isNameEnabled() and getValue(unit, { "status", "nameColorMode" }, statusDef.nameColorMode or "CLASS") ~= "CUSTOM" end
		list[#list + 1] = nameReactionSetting
	end

	local nameAnchorSetting = radioDropdown(
		L["Name anchor"] or "Name anchor",
		UF.ui.anchorOptions,
		function() return getValue(unit, { "status", "nameAnchor" }, statusDef.nameAnchor or "LEFT") end,
		function(val)
			setValue(unit, { "status", "nameAnchor" }, val)
			refresh()
		end,
		statusDef.nameAnchor or "LEFT",
		"name"
	)
	nameAnchorSetting.isEnabled = isNameEnabled
	list[#list + 1] = nameAnchorSetting

	addStatusStrataSetting(makeScopedLabel(L["Frame strata"] or "Frame strata", nameScopeLabel), { "status", "nameStrata" }, statusDef.nameStrata or "", "name", isNameEnabled)

	local nameFrameLevelOffsetSetting = slider(
		makeScopedLabel(L["UFFrameLevel"] or "Frame level", nameScopeLabel),
		-20,
		50,
		1,
		function() return getValue(unit, { "status", "nameFrameLevelOffset" }, statusDef.nameFrameLevelOffset or 5) end,
		function(val)
			setValue(unit, { "status", "nameFrameLevelOffset" }, val or 5)
			refresh()
		end,
		statusDef.nameFrameLevelOffset or 5,
		"name",
		true
	)
	nameFrameLevelOffsetSetting.isEnabled = isNameEnabled
	list[#list + 1] = nameFrameLevelOffsetSetting

	local nameFontSizeSetting = slider(L["Name font size"] or "Name font size", 8, 30, 1, function() return getValue(unit, { "status", "nameFontSize" }, statusDef.fontSize or 14) end, function(val)
		debounced(unit .. "_statusNameFontSize", function()
			setValue(unit, { "status", "nameFontSize" }, val or statusDef.fontSize or 14)
			refreshSelf()
		end)
	end, statusDef.fontSize or 14, "name", true)
	nameFontSizeSetting.isEnabled = isNameEnabled
	list[#list + 1] = nameFontSizeSetting

	local nameMaxCharsSetting = slider(
		L["Name max width"] or "Name max width",
		0,
		100,
		1,
		function() return getValue(unit, { "status", "nameMaxChars" }, statusDef.nameMaxChars or 0) end,
		function(val)
			setValue(unit, { "status", "nameMaxChars" }, val or 0)
			refresh()
		end,
		statusDef.nameMaxChars or 15,
		"name",
		true
	)
	nameMaxCharsSetting.isEnabled = isNameEnabled
	list[#list + 1] = nameMaxCharsSetting

	local nameOffsetXSetting = slider(
		L["UFNameX"] or "Name X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "status", "nameOffset", "x" }, (statusDef.nameOffset and statusDef.nameOffset.x) or 0) end,
		function(val)
			setValue(unit, { "status", "nameOffset", "x" }, val or 0)
			refresh()
		end,
		(statusDef.nameOffset and statusDef.nameOffset.x) or 0,
		"name",
		true
	)
	nameOffsetXSetting.isEnabled = isNameEnabled
	list[#list + 1] = nameOffsetXSetting

	local nameOffsetYSetting = slider(
		L["UFNameY"] or "Name Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "status", "nameOffset", "y" }, (statusDef.nameOffset and statusDef.nameOffset.y) or 0) end,
		function(val)
			setValue(unit, { "status", "nameOffset", "y" }, val or 0)
			refresh()
		end,
		(statusDef.nameOffset and statusDef.nameOffset.y) or 0,
		"name",
		true
	)
	nameOffsetYSetting.isEnabled = isNameEnabled
	list[#list + 1] = nameOffsetYSetting

	if unit == "target" then
		local targetTargetNameDef = statusDef.targetTargetName or {}
		local function isTargetTargetNameEnabled()
			local cfg = getValue(unit, { "status", "targetTargetName" }, nil)
			if type(cfg) == "table" and cfg.enabled ~= nil then return cfg.enabled == true end
			return getValue(unit, { "status", "showTargetTargetName" }, false) == true
		end
		local showTargetTargetNameSetting = checkbox(
			L["UFShowTargetTargetName"] or "Show target-of-target name",
			isTargetTargetNameEnabled,
			function(val)
				setValue(unit, { "status", "targetTargetName", "enabled" }, val and true or false)
				setValue(unit, { "status", "showTargetTargetName" }, nil)
				refresh()
			end,
			targetTargetNameDef.enabled == true,
			"name"
		)
		list[#list + 1] = showTargetTargetNameSetting

		local targetTargetAnchorSetting = radioDropdown(
			L["UFTargetTargetNameAnchor"] or "Target-of-target anchor",
			UF.ui.anchorOptions,
			function() return getValue(unit, { "status", "targetTargetName", "anchor" }, targetTargetNameDef.anchor or "RIGHT") end,
			function(val)
				setValue(unit, { "status", "targetTargetName", "anchor" }, val or targetTargetNameDef.anchor or "RIGHT")
				refresh()
			end,
			targetTargetNameDef.anchor or "RIGHT",
			"name"
		)
		targetTargetAnchorSetting.isShown = isTargetTargetNameEnabled
		list[#list + 1] = targetTargetAnchorSetting

		local targetTargetFontSizeSetting = slider(
			L["UFTargetTargetNameFontSize"] or "Target-of-target font size",
			8,
			30,
			1,
			function() return getValue(unit, { "status", "targetTargetName", "fontSize" }, targetTargetNameDef.fontSize or statusDef.nameFontSize or statusDef.fontSize or 14) end,
			function(val)
				setValue(unit, { "status", "targetTargetName", "fontSize" }, val or targetTargetNameDef.fontSize or statusDef.nameFontSize or statusDef.fontSize or 14)
				refreshSelf()
			end,
			targetTargetNameDef.fontSize or statusDef.nameFontSize or statusDef.fontSize or 14,
			"name",
			true
		)
		targetTargetFontSizeSetting.isShown = isTargetTargetNameEnabled
		list[#list + 1] = targetTargetFontSizeSetting

		local targetTargetOffsetXSetting = slider(
			L["UFTargetTargetNameX"] or "Target-of-target X offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "status", "targetTargetName", "offset", "x" }, (targetTargetNameDef.offset and targetTargetNameDef.offset.x) or 0) end,
			function(val)
				setValue(unit, { "status", "targetTargetName", "offset", "x" }, val or 0)
				refresh()
			end,
			(targetTargetNameDef.offset and targetTargetNameDef.offset.x) or 0,
			"name",
			true
		)
		targetTargetOffsetXSetting.isShown = isTargetTargetNameEnabled
		list[#list + 1] = targetTargetOffsetXSetting

		local targetTargetOffsetYSetting = slider(
			L["UFTargetTargetNameY"] or "Target-of-target Y offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "status", "targetTargetName", "offset", "y" }, (targetTargetNameDef.offset and targetTargetNameDef.offset.y) or 0) end,
			function(val)
				setValue(unit, { "status", "targetTargetName", "offset", "y" }, val or 0)
				refresh()
			end,
			(targetTargetNameDef.offset and targetTargetNameDef.offset.y) or 0,
			"name",
			true
		)
		targetTargetOffsetYSetting.isShown = isTargetTargetNameEnabled
		list[#list + 1] = targetTargetOffsetYSetting
	end

	list[#list + 1] = { name = "", kind = UF.ui.settingType.Divider, parentId = "name" }

	list[#list + 1] = { name = LEVEL or "Level", kind = UF.ui.settingType.Collapsible, id = "level", defaultCollapsed = true }

	local showLevelToggle = checkbox(L["Show level"] or "Show level", function() return getValue(unit, { "status", "levelEnabled" }, statusDef.levelEnabled ~= false) end, function(val)
		setValue(unit, { "status", "levelEnabled" }, val and true or false)
		refresh()
		refreshSettingsUI()
	end, statusDef.levelEnabled ~= false, "level")
	list[#list + 1] = showLevelToggle

	local hideLevelAtMaxToggle = checkbox(
		L["UFHideLevelAtMax"] or "Hide at max level",
		function() return getValue(unit, { "status", "hideLevelAtMax" }, statusDef.hideLevelAtMax == true) end,
		function(val)
			setValue(unit, { "status", "hideLevelAtMax" }, val and true or false)
			refresh()
		end,
		statusDef.hideLevelAtMax == true,
		"level"
	)
	hideLevelAtMaxToggle.isEnabled = isLevelEnabled
	list[#list + 1] = hideLevelAtMaxToggle

	local levelColorSetting = checkboxColor({
		name = L["Level color"] or "Custom level color",
		parentId = "level",
		defaultChecked = (statusDef.levelColorMode or "CLASS") ~= "CLASS",
		isChecked = function() return getValue(unit, { "status", "levelColorMode" }, statusDef.levelColorMode or "CLASS") ~= "CLASS" end,
		onChecked = function(val)
			setValue(unit, { "status", "levelColorMode" }, val and "CUSTOM" or "CLASS")
			refresh()
		end,
		getColor = function() return toRGBA(getValue(unit, { "status", "levelColor" }, statusDef.levelColor or { 1, 0.85, 0, 1 }), statusDef.levelColor or { 1, 0.85, 0, 1 }) end,
		onColor = function(color)
			setColor(unit, { "status", "levelColor" }, color.r, color.g, color.b, color.a)
			setValue(unit, { "status", "levelColorMode" }, "CUSTOM")
			refresh()
		end,
		colorDefault = {
			r = (statusDef.levelColor and statusDef.levelColor[1]) or 1,
			g = (statusDef.levelColor and statusDef.levelColor[2]) or 0.85,
			b = (statusDef.levelColor and statusDef.levelColor[3]) or 0,
			a = (statusDef.levelColor and statusDef.levelColor[4]) or 1,
		},
	})
	levelColorSetting.isEnabled = isLevelEnabled
	list[#list + 1] = levelColorSetting

	local levelAnchorSetting = radioDropdown(
		L["Level anchor"] or "Level anchor",
		UF.ui.anchorOptions,
		function() return getValue(unit, { "status", "levelAnchor" }, statusDef.levelAnchor or "RIGHT") end,
		function(val)
			setValue(unit, { "status", "levelAnchor" }, val)
			refresh()
		end,
		statusDef.levelAnchor or "RIGHT",
		"level"
	)
	levelAnchorSetting.isEnabled = isLevelEnabled
	list[#list + 1] = levelAnchorSetting

	addStatusStrataSetting(makeScopedLabel(L["Frame strata"] or "Frame strata", levelScopeLabel), { "status", "levelStrata" }, statusDef.levelStrata or "", "level", isLevelEnabled)

	local levelFrameLevelOffsetSetting = slider(
		makeScopedLabel(L["UFFrameLevel"] or "Frame level", levelScopeLabel),
		-20,
		50,
		1,
		function() return getValue(unit, { "status", "levelFrameLevelOffset" }, statusDef.levelFrameLevelOffset or 5) end,
		function(val)
			setValue(unit, { "status", "levelFrameLevelOffset" }, val or 5)
			refresh()
		end,
		statusDef.levelFrameLevelOffset or 5,
		"level",
		true
	)
	levelFrameLevelOffsetSetting.isEnabled = isLevelEnabled
	list[#list + 1] = levelFrameLevelOffsetSetting

	local levelFontSizeSetting = slider(
		L["Level font size"] or "Level font size",
		8,
		30,
		1,
		function() return getValue(unit, { "status", "levelFontSize" }, statusDef.fontSize or 14) end,
		function(val)
			debounced(unit .. "_statusLevelFontSize", function()
				setValue(unit, { "status", "levelFontSize" }, val or statusDef.fontSize or 14)
				refreshSelf()
			end)
		end,
		statusDef.fontSize or 14,
		"level",
		true
	)
	levelFontSizeSetting.isEnabled = isLevelEnabled
	list[#list + 1] = levelFontSizeSetting

	local levelOffsetXSetting = slider(
		L["UFLevelX"] or "Level X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "status", "levelOffset", "x" }, (statusDef.levelOffset and statusDef.levelOffset.x) or 0) end,
		function(val)
			setValue(unit, { "status", "levelOffset", "x" }, val or 0)
			refresh()
		end,
		(statusDef.levelOffset and statusDef.levelOffset.x) or 0,
		"level",
		true
	)
	levelOffsetXSetting.isEnabled = isLevelEnabled
	list[#list + 1] = levelOffsetXSetting

	local levelOffsetYSetting = slider(
		L["UFLevelY"] or "Level Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "status", "levelOffset", "y" }, (statusDef.levelOffset and statusDef.levelOffset.y) or 0) end,
		function(val)
			setValue(unit, { "status", "levelOffset", "y" }, val or 0)
			refresh()
		end,
		(statusDef.levelOffset and statusDef.levelOffset.y) or 0,
		"level",
		true
	)
	levelOffsetYSetting.isEnabled = isLevelEnabled
	list[#list + 1] = levelOffsetYSetting

	if not isPlayer then
		list[#list + 1] = checkbox(L["UFShowClassificationIcon"] or "Show elite/rare icon", isClassificationIconEnabled, function(val)
			setValue(unit, { "status", "classificationIcon", "enabled" }, val and true or false)
			refresh()
			refreshSettingsUI()
		end, classIconDef.enabled == true, "unitStatus")

		local hideClassTextToggle = checkbox(
			L["UFClassificationIconHideText"] or "Hide elite/rare text indicators",
			function() return getValue(unit, { "status", "classificationIcon", "hideText" }, classIconDef.hideText == true) == true end,
			function(val)
				setValue(unit, { "status", "classificationIcon", "hideText" }, val and true or false)
				refresh()
			end,
			classIconDef.hideText == true,
			"unitStatus"
		)
		hideClassTextToggle.isEnabled = isClassificationIconEnabled
		hideClassTextToggle.isShown = isClassificationIconEnabled
		list[#list + 1] = hideClassTextToggle

		local classIconSize = slider(L["Icon size"] or "Icon size", 8, 40, 1, function() return getValue(unit, { "status", "classificationIcon", "size" }, classIconDef.size or 16) end, function(val)
			local v = val or classIconDef.size or 16
			setValue(unit, { "status", "classificationIcon", "size" }, v)
			refresh()
		end, classIconDef.size or 16, "unitStatus", true)
		classIconSize.isEnabled = isClassificationIconEnabled
		classIconSize.isShown = isClassificationIconEnabled
		list[#list + 1] = classIconSize

		local classIconOffsetX = slider(
			L["UFClassificationIconOffsetX"] or "Elite/rare icon X offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "status", "classificationIcon", "offset", "x" }, (classIconDef.offset and classIconDef.offset.x) or -4) end,
			function(val)
				local off = getValue(unit, { "status", "classificationIcon", "offset" }, { x = -4, y = 0 }) or {}
				off.x = val or 0
				setValue(unit, { "status", "classificationIcon", "offset" }, off)
				refresh()
			end,
			(classIconDef.offset and classIconDef.offset.x) or -4,
			"unitStatus",
			true
		)
		classIconOffsetX.isEnabled = isClassificationIconEnabled
		classIconOffsetX.isShown = isClassificationIconEnabled
		list[#list + 1] = classIconOffsetX

		local classIconOffsetY = slider(
			L["UFClassificationIconOffsetY"] or "Elite/rare icon Y offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "status", "classificationIcon", "offset", "y" }, (classIconDef.offset and classIconDef.offset.y) or 0) end,
			function(val)
				local off = getValue(unit, { "status", "classificationIcon", "offset" }, { x = -4, y = 0 }) or {}
				off.y = val or 0
				setValue(unit, { "status", "classificationIcon", "offset" }, off)
				refresh()
			end,
			(classIconDef.offset and classIconDef.offset.y) or 0,
			"unitStatus",
			true
		)
		classIconOffsetY.isEnabled = isClassificationIconEnabled
		classIconOffsetY.isShown = isClassificationIconEnabled
		list[#list + 1] = classIconOffsetY
	end

	if #fontOptions() > 0 then
		local statusFont = checkboxDropdown(L["Font"] or "Font", fontOptions, function()
			return getValue(unit, { "status", "font" }, statusDef.font or UF.ui.globalFontConfigKey())
		end, function(val)
			setValue(unit, { "status", "font" }, val)
			refreshSelf()
		end, statusDef.font or UF.ui.globalFontConfigKey(), "name")
		statusFont.isEnabled = isNameOrLevelEnabled
		list[#list + 1] = statusFont
	end

	local statusFontOutline = checkboxDropdown(
		L["Font outline"] or "Font outline",
		UF.ui.outlineOptions,
		function()
			return UF.ui.normalizeFontStyleChoice(
				getValue(unit, { "status", "fontOutline" }, statusDef.fontOutline or "OUTLINE"),
				statusDef.fontOutline or "OUTLINE"
			)
		end,
		function(val)
			setValue(unit, { "status", "fontOutline" }, UF.ui.normalizeFontStyleChoice(val, statusDef.fontOutline or "OUTLINE"))
			refreshSelf()
		end,
		statusDef.fontOutline or "OUTLINE",
		"name"
	)
	statusFontOutline.isEnabled = isNameOrLevelEnabled
	list[#list + 1] = statusFontOutline

	local usDef = statusDef.unitStatus or {}

	list[#list + 1] = { name = L["Status text"] or "Status text", kind = UF.ui.settingType.Collapsible, id = "statusText", defaultCollapsed = true }

	list[#list + 1] = { name = L["UFUnitStatus"] or "Unit status", kind = UF.ui.settingType.Collapsible, id = "unitStatus", defaultCollapsed = true }

	if unit == "player" or unit == "target" or unit == "focus" then
		local pvpDef = def.pvpIndicator or { enabled = false, size = 20, offset = { x = -24, y = -2 } }
		local function isPvPIndicatorEnabled() return getValue(unit, { "pvpIndicator", "enabled" }, pvpDef.enabled == true) == true end

		list[#list + 1] = checkbox(L["UFPvPIndicatorEnable"] or "Show PvP indicator", isPvPIndicatorEnabled, function(val)
			setValue(unit, { "pvpIndicator", "enabled" }, val and true or false)
			refreshSelf()
		end, pvpDef.enabled == true, "unitStatus")

		local pvpIconSize = slider(L["Icon size"] or "Icon size", 10, 40, 1, function() return getValue(unit, { "pvpIndicator", "size" }, pvpDef.size or 20) end, function(val)
			local v = val or pvpDef.size or 20
			if v < 10 then v = 10 end
			if v > 40 then v = 40 end
			setValue(unit, { "pvpIndicator", "size" }, v)
			refreshSelf()
		end, pvpDef.size or 20, "unitStatus", true)
		pvpIconSize.isEnabled = isPvPIndicatorEnabled
		list[#list + 1] = pvpIconSize

		local pvpOffsetX = slider(
			L["Offset X"] or "Offset X",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "pvpIndicator", "offset", "x" }, (pvpDef.offset and pvpDef.offset.x) or 0) end,
			function(val)
				setValue(unit, { "pvpIndicator", "offset", "x" }, val or 0)
				refreshSelf()
			end,
			(pvpDef.offset and pvpDef.offset.x) or 0,
			"unitStatus",
			true
		)
		pvpOffsetX.isEnabled = isPvPIndicatorEnabled
		list[#list + 1] = pvpOffsetX

		local pvpOffsetY = slider(
			L["Offset Y"] or "Offset Y",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "pvpIndicator", "offset", "y" }, (pvpDef.offset and pvpDef.offset.y) or 0) end,
			function(val)
				setValue(unit, { "pvpIndicator", "offset", "y" }, val or 0)
				refreshSelf()
			end,
			(pvpDef.offset and pvpDef.offset.y) or 0,
			"unitStatus",
			true
		)
		pvpOffsetY.isEnabled = isPvPIndicatorEnabled
		list[#list + 1] = pvpOffsetY
		addDivider("unitStatus")

		local roleDef = def.roleIndicator or { enabled = false, size = 18, offset = { x = 24, y = -2 } }
		local function isRoleIndicatorEnabled() return getValue(unit, { "roleIndicator", "enabled" }, roleDef.enabled == true) == true end

		list[#list + 1] = checkbox(L["UFRoleIndicatorEnable"] or "Show role indicator", isRoleIndicatorEnabled, function(val)
			setValue(unit, { "roleIndicator", "enabled" }, val and true or false)
			refreshSelf()
		end, roleDef.enabled == true, "unitStatus")

		local roleIconSize = slider(L["Icon size"] or "Icon size", 10, 40, 1, function() return getValue(unit, { "roleIndicator", "size" }, roleDef.size or 18) end, function(val)
			local v = val or roleDef.size or 18
			if v < 10 then v = 10 end
			if v > 40 then v = 40 end
			setValue(unit, { "roleIndicator", "size" }, v)
			refreshSelf()
		end, roleDef.size or 18, "unitStatus", true)
		roleIconSize.isEnabled = isRoleIndicatorEnabled
		list[#list + 1] = roleIconSize

		local roleOffsetX = slider(
			L["UFRoleIndicatorOffsetX"] or "Role indicator X offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "roleIndicator", "offset", "x" }, (roleDef.offset and roleDef.offset.x) or 0) end,
			function(val)
				setValue(unit, { "roleIndicator", "offset", "x" }, val or 0)
				refreshSelf()
			end,
			(roleDef.offset and roleDef.offset.x) or 0,
			"unitStatus",
			true
		)
		roleOffsetX.isEnabled = isRoleIndicatorEnabled
		list[#list + 1] = roleOffsetX

		local roleOffsetY = slider(
			L["UFRoleIndicatorOffsetY"] or "Role indicator Y offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "roleIndicator", "offset", "y" }, (roleDef.offset and roleDef.offset.y) or 0) end,
			function(val)
				setValue(unit, { "roleIndicator", "offset", "y" }, val or 0)
				refreshSelf()
			end,
			(roleDef.offset and roleDef.offset.y) or 0,
			"unitStatus",
			true
		)
		roleOffsetY.isEnabled = isRoleIndicatorEnabled
		list[#list + 1] = roleOffsetY
		addDivider("unitStatus")

		local leaderDef = def.leaderIcon or { enabled = false, size = 12, offset = { x = 0, y = 0 } }
		local function isLeaderIndicatorEnabled() return getValue(unit, { "leaderIcon", "enabled" }, leaderDef.enabled == true) == true end

		list[#list + 1] = checkbox(L["UFLeaderIndicatorEnable"] or "Show party leader icon", isLeaderIndicatorEnabled, function(val)
			setValue(unit, { "leaderIcon", "enabled" }, val and true or false)
			refreshSelf()
		end, leaderDef.enabled == true, "unitStatus")

		local leaderIconSize = slider(L["Icon size"] or "Icon size", 8, 40, 1, function() return getValue(unit, { "leaderIcon", "size" }, leaderDef.size or 12) end, function(val)
			local v = val or leaderDef.size or 12
			if v < 8 then v = 8 end
			if v > 40 then v = 40 end
			setValue(unit, { "leaderIcon", "size" }, v)
			refreshSelf()
		end, leaderDef.size or 12, "unitStatus", true)
		leaderIconSize.isEnabled = isLeaderIndicatorEnabled
		list[#list + 1] = leaderIconSize

		local leaderOffsetX = slider(
			L["Offset X"] or "Offset X",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "leaderIcon", "offset", "x" }, (leaderDef.offset and leaderDef.offset.x) or 0) end,
			function(val)
				setValue(unit, { "leaderIcon", "offset", "x" }, val or 0)
				refreshSelf()
			end,
			(leaderDef.offset and leaderDef.offset.x) or 0,
			"unitStatus",
			true
		)
		leaderOffsetX.isEnabled = isLeaderIndicatorEnabled
		list[#list + 1] = leaderOffsetX

		local leaderOffsetY = slider(
			L["Offset Y"] or "Offset Y",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "leaderIcon", "offset", "y" }, (leaderDef.offset and leaderDef.offset.y) or 0) end,
			function(val)
				setValue(unit, { "leaderIcon", "offset", "y" }, val or 0)
				refreshSelf()
			end,
			(leaderDef.offset and leaderDef.offset.y) or 0,
			"unitStatus",
			true
		)
		leaderOffsetY.isEnabled = isLeaderIndicatorEnabled
		list[#list + 1] = leaderOffsetY
		list[#list + 1] = { name = L["UFDispelIndicator"] or "Dispel indicator", kind = UF.ui.settingType.Collapsible, id = "dispelTint", defaultCollapsed = true }

		local dispelDef = statusDef.dispelTint
			or {
				enabled = true,
				filterMode = "MY",
				alpha = 0.25,
				showSample = false,
				fillEnabled = true,
				fillAlpha = 0.2,
				fillColor = { 0, 0, 0, 1 },
				strata = nil,
				frameLevelModel = 2,
				frameLevelOffset = 20,
				glowEnabled = false,
				glowColorMode = "DISPEL",
				glowColor = { 1, 1, 1, 1 },
				glowEffect = "PIXEL",
				glowFrequency = 0.25,
				glowX = 0,
				glowY = 0,
				glowLines = 8,
				glowThickness = 3,
				glowStrata = nil,
				glowFrameLevelModel = 2,
				glowFrameLevelOffset = 21,
			}
		local dispelFilterModeOptions = {
			{ value = "ANY", label = L["UFDispelFilterAny"] or "Any dispel" },
			{ value = "GROUP", label = L["UFDispelFilterGroup"] or "Dispellable by group" },
			{ value = "MY", label = L["UFDispelFilterMine"] or "Dispellable by me" },
		}
		local dispelGlowColorModeOptions = {
			{ value = "DISPEL", label = L["Dispel color"] or "Dispel color" },
			{ value = "CUSTOM", label = L["Custom color"] or "Custom color" },
		}
		local dispelGlowEffectOptions = {
			{ value = "PIXEL", label = L["Pixel"] or "Pixel" },
			{ value = "SHINE", label = L["Shine"] or "Shine" },
			{ value = "BLIZZARD", label = L["Blizzard"] or "Blizzard" },
		}
		local dispelFillColorDefault = { toRGBA(dispelDef.fillColor, { 0, 0, 0, 1 }) }
		local dispelGlowColorDefault = { toRGBA(dispelDef.glowColor, { 1, 1, 1, 1 }) }

		local function isDispelIndicatorEnabled() return getValue(unit, { "status", "dispelTint", "enabled" }, dispelDef.enabled ~= false) ~= false end

		local function isDispelFillEnabled() return isDispelIndicatorEnabled() and (getValue(unit, { "status", "dispelTint", "fillEnabled" }, dispelDef.fillEnabled ~= false) ~= false) end

		local function isDispelGlowEnabled() return getValue(unit, { "status", "dispelTint", "glowEnabled" }, dispelDef.glowEnabled == true) == true end

		local function getDispelGlowColorMode() return getValue(unit, { "status", "dispelTint", "glowColorMode" }, dispelDef.glowColorMode or "DISPEL") end

		list[#list + 1] = checkbox(L["Enable tint"] or "Enable tint", isDispelIndicatorEnabled, function(val)
			setValue(unit, { "status", "dispelTint", "enabled" }, val and true or false)
			refreshSelf()
			refreshSettingsUI()
		end, dispelDef.enabled ~= false, "dispelTint")

		local dispelFilterMode = radioDropdown(
			L["UFDispelFilterMode"] or "Dispel filter",
			dispelFilterModeOptions,
			function() return getValue(unit, { "status", "dispelTint", "filterMode" }, dispelDef.filterMode or "MY") end,
			function(val)
				setValue(unit, { "status", "dispelTint", "filterMode" }, val or "MY")
				refreshSelf()
			end,
			dispelDef.filterMode or "MY",
			"dispelTint"
		)
		dispelFilterMode.isEnabled = function() return isDispelIndicatorEnabled() or isDispelGlowEnabled() end
		list[#list + 1] = dispelFilterMode

		list[#list + 1] = checkbox(L["Fill"] or "Fill", function() return getValue(unit, { "status", "dispelTint", "fillEnabled" }, dispelDef.fillEnabled ~= false) ~= false end, function(val)
			setValue(unit, { "status", "dispelTint", "fillEnabled" }, val and true or false)
			refreshSelf()
			refreshSettingsUI()
		end, dispelDef.fillEnabled ~= false, "dispelTint", isDispelIndicatorEnabled)

		list[#list + 1] = slider(
			L["Fill opacity"] or "Fill opacity",
			0,
			1,
			0.01,
			function() return getValue(unit, { "status", "dispelTint", "fillAlpha" }, dispelDef.fillAlpha or 0.2) end,
			function(val)
				setValue(unit, { "status", "dispelTint", "fillAlpha" }, clampNumber(val, 0, 1, dispelDef.fillAlpha or 0.2))
				refreshSelf()
			end,
			dispelDef.fillAlpha or 0.2,
			"dispelTint",
			true,
			function(value) return string.format("%.2f", tonumber(value) or 0) end
		)
		list[#list].isEnabled = isDispelFillEnabled

		list[#list + 1] = {
			name = L["Fill color"] or "Fill color",
			kind = UF.ui.settingType.Color,
			parentId = "dispelTint",
			isEnabled = isDispelFillEnabled,
			get = function() return getValue(unit, { "status", "dispelTint", "fillColor" }, dispelDef.fillColor or { 0, 0, 0, 1 }) end,
			set = function(_, color)
				setColor(unit, { "status", "dispelTint", "fillColor" }, color.r, color.g, color.b, color.a)
				refreshSelf()
			end,
			colorGet = function()
				local r, g, b, a = toRGBA(getValue(unit, { "status", "dispelTint", "fillColor" }, dispelDef.fillColor), dispelDef.fillColor or { 0, 0, 0, 1 })
				return { r = r, g = g, b = b, a = a }
			end,
			colorSet = function(_, color)
				setColor(unit, { "status", "dispelTint", "fillColor" }, color.r, color.g, color.b, color.a)
				refreshSelf()
			end,
			colorDefault = {
				r = dispelFillColorDefault[1] or 0,
				g = dispelFillColorDefault[2] or 0,
				b = dispelFillColorDefault[3] or 0,
				a = dispelFillColorDefault[4] or 1,
			},
			hasOpacity = false,
		}

		list[#list + 1] = slider(L["Tint alpha"] or "Tint alpha", 0, 1, 0.01, function() return getValue(unit, { "status", "dispelTint", "alpha" }, dispelDef.alpha or 0.25) end, function(val)
			setValue(unit, { "status", "dispelTint", "alpha" }, clampNumber(val, 0, 1, dispelDef.alpha or 0.25))
			refreshSelf()
		end, dispelDef.alpha or 0.25, "dispelTint", true, function(value) return string.format("%.2f", tonumber(value) or 0) end)
		list[#list].isEnabled = isDispelIndicatorEnabled

		local dispelStrata = radioDropdown(
			L["Frame strata"] or "Frame strata",
			strataOptionsWithDefault,
			function() return getValue(unit, { "status", "dispelTint", "strata" }, dispelDef.strata or "") end,
			function(val)
				setValue(unit, { "status", "dispelTint", "strata" }, val ~= "" and val or nil)
				setValue(unit, { "status", "dispelTint", "frameLevelModel" }, 2)
				refreshSelf()
			end,
			dispelDef.strata or "",
			"dispelTint"
		)
		dispelStrata.isEnabled = isDispelIndicatorEnabled
		list[#list + 1] = dispelStrata

		local dispelFrameLevel = slider(
			L["UFFrameLevel"] or "Frame level",
			-20,
			1000,
			1,
			function() return getValue(unit, { "status", "dispelTint", "frameLevelOffset" }, dispelDef.frameLevelOffset or 20) end,
			function(val)
				setValue(unit, { "status", "dispelTint", "frameLevelModel" }, 2)
				setValue(unit, { "status", "dispelTint", "frameLevelOffset" }, clampNumber(val, -20, 1000, dispelDef.frameLevelOffset or 20))
				refreshSelf()
			end,
			dispelDef.frameLevelOffset or 20,
			"dispelTint",
			true
		)
		dispelFrameLevel.isEnabled = isDispelIndicatorEnabled
		list[#list + 1] = dispelFrameLevel

		list[#list + 1] = checkbox(
			L["Show sample in Edit Mode"] or "Show sample in Edit Mode",
			function() return getValue(unit, { "status", "dispelTint", "showSample" }, dispelDef.showSample == true) == true end,
			function(val)
				setValue(unit, { "status", "dispelTint", "showSample" }, val and true or false)
				refreshSelf()
			end,
			dispelDef.showSample == true,
			"dispelTint",
			function() return isDispelIndicatorEnabled() or isDispelGlowEnabled() end
		)

		addDivider("dispelTint")

		list[#list + 1] = checkbox(L["Enable glow"] or "Enable glow", isDispelGlowEnabled, function(val)
			setValue(unit, { "status", "dispelTint", "glowEnabled" }, val and true or false)
			refreshSelf()
			refreshSettingsUI()
		end, dispelDef.glowEnabled == true, "dispelTint")

		list[#list + 1] = radioDropdown(L["Glow color"] or "Glow color", dispelGlowColorModeOptions, getDispelGlowColorMode, function(val)
			setValue(unit, { "status", "dispelTint", "glowColorMode" }, val or "DISPEL")
			refreshSelf()
			refreshSettingsUI()
		end, dispelDef.glowColorMode or "DISPEL", "dispelTint")
		list[#list].isEnabled = isDispelGlowEnabled

		local dispelGlowStrata = radioDropdown(
			L["UFDispelGlowStrata"] or "Dispel glow strata",
			strataOptionsWithDefault,
			function() return getValue(unit, { "status", "dispelTint", "glowStrata" }, dispelDef.glowStrata or "") end,
			function(val)
				setValue(unit, { "status", "dispelTint", "glowStrata" }, val ~= "" and val or nil)
				setValue(unit, { "status", "dispelTint", "glowFrameLevelModel" }, 2)
				refreshSelf()
			end,
			dispelDef.glowStrata or "",
			"dispelTint"
		)
		dispelGlowStrata.isEnabled = isDispelGlowEnabled
		list[#list + 1] = dispelGlowStrata

		local dispelGlowFrameLevel = slider(
			L["UFDispelGlowFrameLevel"] or "Dispel glow frame level",
			-20,
			1000,
			1,
			function() return getValue(unit, { "status", "dispelTint", "glowFrameLevelOffset" }, dispelDef.glowFrameLevelOffset or 21) end,
			function(val)
				setValue(unit, { "status", "dispelTint", "glowFrameLevelModel" }, 2)
				setValue(unit, { "status", "dispelTint", "glowFrameLevelOffset" }, clampNumber(val, -20, 1000, dispelDef.glowFrameLevelOffset or 21))
				refreshSelf()
			end,
			dispelDef.glowFrameLevelOffset or 21,
			"dispelTint",
			true
		)
		dispelGlowFrameLevel.isEnabled = isDispelGlowEnabled
		list[#list + 1] = dispelGlowFrameLevel

		list[#list + 1] = {
			name = L["Custom glow color"] or "Custom glow color",
			kind = UF.ui.settingType.Color,
			parentId = "dispelTint",
			isEnabled = function() return isDispelGlowEnabled() and getDispelGlowColorMode() == "CUSTOM" end,
			get = function() return getValue(unit, { "status", "dispelTint", "glowColor" }, dispelDef.glowColor or { 1, 1, 1, 1 }) end,
			set = function(_, color)
				setColor(unit, { "status", "dispelTint", "glowColor" }, color.r, color.g, color.b, color.a)
				refreshSelf()
			end,
			colorGet = function()
				local r, g, b, a = toRGBA(getValue(unit, { "status", "dispelTint", "glowColor" }, dispelDef.glowColor), dispelDef.glowColor or { 1, 1, 1, 1 })
				return { r = r, g = g, b = b, a = a }
			end,
			colorSet = function(_, color)
				setColor(unit, { "status", "dispelTint", "glowColor" }, color.r, color.g, color.b, color.a)
				refreshSelf()
			end,
			colorDefault = {
				r = dispelGlowColorDefault[1] or 1,
				g = dispelGlowColorDefault[2] or 1,
				b = dispelGlowColorDefault[3] or 1,
				a = dispelGlowColorDefault[4] or 1,
			},
			hasOpacity = false,
		}

		list[#list + 1] = radioDropdown(
			L["Glow effect"] or "Glow effect",
			dispelGlowEffectOptions,
			function() return getValue(unit, { "status", "dispelTint", "glowEffect" }, dispelDef.glowEffect or "PIXEL") end,
			function(val)
				setValue(unit, { "status", "dispelTint", "glowEffect" }, val or "PIXEL")
				refreshSelf()
			end,
			dispelDef.glowEffect or "PIXEL",
			"dispelTint"
		)
		list[#list].isEnabled = isDispelGlowEnabled

		list[#list + 1] = slider(
			L["Animation speed"] or "Animation speed",
			-1.5,
			1.5,
			0.25,
			function() return getValue(unit, { "status", "dispelTint", "glowFrequency" }, dispelDef.glowFrequency or 0.25) end,
			function(val)
				setValue(unit, { "status", "dispelTint", "glowFrequency" }, clampNumber(val, -1.5, 1.5, dispelDef.glowFrequency or 0.25))
				refreshSelf()
			end,
			dispelDef.glowFrequency or 0.25,
			"dispelTint",
			true,
			function(value) return string.format("%.2f", tonumber(value) or 0) end
		)
		list[#list].isEnabled = isDispelGlowEnabled

		list[#list + 1] = slider(L["X Offset"] or "X Offset", -10, 10, 1, function() return getValue(unit, { "status", "dispelTint", "glowX" }, dispelDef.glowX or 0) end, function(val)
			setValue(unit, { "status", "dispelTint", "glowX" }, clampNumber(val, -10, 10, dispelDef.glowX or 0))
			refreshSelf()
		end, dispelDef.glowX or 0, "dispelTint", true)
		list[#list].isEnabled = isDispelGlowEnabled

		list[#list + 1] = slider(L["Y Offset"] or "Y Offset", -10, 10, 1, function() return getValue(unit, { "status", "dispelTint", "glowY" }, dispelDef.glowY or 0) end, function(val)
			setValue(unit, { "status", "dispelTint", "glowY" }, clampNumber(val, -10, 10, dispelDef.glowY or 0))
			refreshSelf()
		end, dispelDef.glowY or 0, "dispelTint", true)
		list[#list].isEnabled = isDispelGlowEnabled

		list[#list + 1] = slider(
			L["Number of lines"] or "Number of lines",
			1,
			20,
			1,
			function() return getValue(unit, { "status", "dispelTint", "glowLines" }, dispelDef.glowLines or 8) end,
			function(val)
				setValue(unit, { "status", "dispelTint", "glowLines" }, clampNumber(val, 1, 20, dispelDef.glowLines or 8))
				refreshSelf()
			end,
			dispelDef.glowLines or 8,
			"dispelTint",
			true
		)
		list[#list].isEnabled = isDispelGlowEnabled

		list[#list + 1] = slider(L["Thickness"] or "Thickness", 1, 10, 1, function() return getValue(unit, { "status", "dispelTint", "glowThickness" }, dispelDef.glowThickness or 3) end, function(val)
			setValue(unit, { "status", "dispelTint", "glowThickness" }, clampNumber(val, 1, 10, dispelDef.glowThickness or 3))
			refreshSelf()
		end, dispelDef.glowThickness or 3, "dispelTint", true)
		list[#list].isEnabled = isDispelGlowEnabled

		addDivider("dispelTint")
	end

	list[#list + 1] = checkbox(L["Show status text"] or "Show status text", function() return getValue(unit, { "status", "unitStatus", "enabled" }, usDef.enabled == true) == true end, function(val)
		setValue(unit, { "status", "unitStatus", "enabled" }, val and true or false)
		refresh()
		refreshSettingsUI()
	end, usDef.enabled == true, "statusText")

	local unitStatusOffsetX = slider(
		L["UFUnitStatusOffsetX"] or "Unit status X offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "status", "unitStatus", "offset", "x" }, (usDef.offset and usDef.offset.x) or 0) end,
		function(val)
			local off = getValue(unit, { "status", "unitStatus", "offset" }, { x = 0, y = 0 }) or {}
			off.x = val or 0
			setValue(unit, { "status", "unitStatus", "offset" }, off)
			refresh()
		end,
		(usDef.offset and usDef.offset.x) or 0,
		"statusText",
		true
	)
	unitStatusOffsetX.isEnabled = isUnitStatusEnabled
	list[#list + 1] = unitStatusOffsetX

	local unitStatusOffsetY = slider(
		L["UFUnitStatusOffsetY"] or "Unit status Y offset",
		-OFFSET_RANGE,
		OFFSET_RANGE,
		1,
		function() return getValue(unit, { "status", "unitStatus", "offset", "y" }, (usDef.offset and usDef.offset.y) or 0) end,
		function(val)
			local off = getValue(unit, { "status", "unitStatus", "offset" }, { x = 0, y = 0 }) or {}
			off.y = val or 0
			setValue(unit, { "status", "unitStatus", "offset" }, off)
			refresh()
		end,
		(usDef.offset and usDef.offset.y) or 0,
		"statusText",
		true
	)
	unitStatusOffsetY.isEnabled = isUnitStatusEnabled
	list[#list + 1] = unitStatusOffsetY
	list[#list + 1] = { name = "", kind = UF.ui.settingType.Divider, parentId = "statusText" }

	local unitStatusFontSizeSetting = slider(
		FONT_SIZE_LABEL,
		8,
		30,
		1,
		function() return getValue(unit, { "status", "unitStatus", "fontSize" }, usDef.fontSize or statusDef.fontSize or 14) end,
		function(val)
			debounced(unit .. "_unitStatusFontSize", function()
				setValue(unit, { "status", "unitStatus", "fontSize" }, val or statusDef.fontSize or 14)
				refreshSelf()
			end)
		end,
		usDef.fontSize or statusDef.fontSize or 14,
		"statusText",
		true
	)
	unitStatusFontSizeSetting.isEnabled = isUnitStatusEnabled
	list[#list + 1] = unitStatusFontSizeSetting

	if #fontOptions() > 0 then
		local unitStatusFontSetting = checkboxDropdown(
			L["Font"] or "Font",
			fontOptions,
			function() return getValue(unit, { "status", "unitStatus", "font" }, usDef.font or statusDef.font or UF.ui.globalFontConfigKey()) end,
			function(val)
				setValue(unit, { "status", "unitStatus", "font" }, val)
				refreshSelf()
			end,
			usDef.font or statusDef.font or UF.ui.globalFontConfigKey(),
			"statusText"
		)
		unitStatusFontSetting.isEnabled = isUnitStatusEnabled
		list[#list + 1] = unitStatusFontSetting
	end

	local unitStatusFontOutlineSetting = checkboxDropdown(
		L["Font outline"] or "Font outline",
		UF.ui.outlineOptions,
		function()
			return UF.ui.normalizeFontStyleChoice(
				getValue(unit, { "status", "unitStatus", "fontOutline" }, usDef.fontOutline or statusDef.fontOutline or "OUTLINE"),
				usDef.fontOutline or statusDef.fontOutline or "OUTLINE"
			)
		end,
		function(val)
			setValue(
				unit,
				{ "status", "unitStatus", "fontOutline" },
				UF.ui.normalizeFontStyleChoice(val, usDef.fontOutline or statusDef.fontOutline or "OUTLINE")
			)
			refreshSelf()
		end,
		usDef.fontOutline or statusDef.fontOutline or "OUTLINE",
		"statusText"
	)
	unitStatusFontOutlineSetting.isEnabled = isUnitStatusEnabled
	list[#list + 1] = unitStatusFontOutlineSetting

	if unit == "player" or unit == "target" then
		local function isGroupEnabled() return isUnitStatusEnabled() and getValue(unit, { "status", "unitStatus", "showGroup" }, usDef.showGroup == true) == true end

		list[#list + 1] = checkbox(
			L["UFUnitStatusShowGroup"] or "Show group number",
			function() return getValue(unit, { "status", "unitStatus", "showGroup" }, usDef.showGroup == true) == true end,
			function(val)
				setValue(unit, { "status", "unitStatus", "showGroup" }, val and true or false)
				refresh()
			end,
			usDef.showGroup == true,
			"statusText"
		)
		list[#list].isEnabled = isUnitStatusEnabled

		local groupNumberFormatOptions = {
			{ value = "GROUP", label = "Group 1" },
			{ value = "G", label = "G1" },
			{ value = "G_SPACE", label = "G 1" },
			{ value = "NUMBER", label = "1" },
			{ value = "PARENS", label = "(1)" },
			{ value = "BRACKETS", label = "[1]" },
			{ value = "BRACES", label = "{1}" },
			{ value = "ANGLE", label = "<1>" },
			{ value = "PIPE", label = "|| 1 ||" },
			{ value = "HASH", label = "#1" },
		}

		local groupFormatSetting = checkboxDropdown(
			L["UFUnitStatusGroupFormat"] or "Group number format",
			groupNumberFormatOptions,
			function() return getValue(unit, { "status", "unitStatus", "groupFormat" }, usDef.groupFormat or "GROUP") end,
			function(val)
				setValue(unit, { "status", "unitStatus", "groupFormat" }, val or "GROUP")
				refresh()
			end,
			usDef.groupFormat or "GROUP",
			"statusText"
		)
		groupFormatSetting.isEnabled = isGroupEnabled
		list[#list + 1] = groupFormatSetting

		list[#list + 1] = radioDropdown(
			L["UFUnitStatusGroupAnchor"] or "Group number anchor",
			UF.ui.anchorOptions9,
			function() return getValue(unit, { "status", "unitStatus", "groupAnchor" }, usDef.groupAnchor or "TOP") end,
			function(val)
				setValue(unit, { "status", "unitStatus", "groupAnchor" }, val or "TOP")
				refresh()
			end,
			usDef.groupAnchor or "TOP",
			"unitStatus"
		)
		list[#list].isEnabled = isGroupEnabled

		list[#list + 1] = slider(
			L["UFUnitStatusGroupSize"] or "Group number size",
			8,
			30,
			1,
			function() return getValue(unit, { "status", "unitStatus", "groupFontSize" }, usDef.groupFontSize or usDef.fontSize or statusDef.fontSize or 14) end,
			function(val)
				setValue(unit, { "status", "unitStatus", "groupFontSize" }, val or usDef.fontSize or statusDef.fontSize or 14)
				refresh()
			end,
			usDef.groupFontSize or usDef.fontSize or statusDef.fontSize or 14,
			"statusText",
			true
		)
		list[#list].isEnabled = isGroupEnabled

		if #fontOptions() > 0 then
			local groupFontSetting = checkboxDropdown(
				L["UFUnitStatusGroupFont"] or "Group number font",
				fontOptions,
				function() return getValue(unit, { "status", "unitStatus", "groupFont" }, usDef.groupFont or usDef.font or statusDef.font or UF.ui.globalFontConfigKey()) end,
				function(val)
					setValue(unit, { "status", "unitStatus", "groupFont" }, val)
					refreshSelf()
				end,
				usDef.groupFont or usDef.font or statusDef.font or UF.ui.globalFontConfigKey(),
				"statusText"
			)
			groupFontSetting.isEnabled = isGroupEnabled
			list[#list + 1] = groupFontSetting
		end

		local groupFontOutlineSetting = checkboxDropdown(
			L["UFUnitStatusGroupFontOutline"] or "Group number font outline",
			UF.ui.outlineOptions,
			function()
				return UF.ui.normalizeFontStyleChoice(
					getValue(unit, { "status", "unitStatus", "groupFontOutline" }, usDef.groupFontOutline or usDef.fontOutline or statusDef.fontOutline or "OUTLINE"),
					usDef.groupFontOutline or usDef.fontOutline or statusDef.fontOutline or "OUTLINE"
				)
			end,
			function(val)
				setValue(
					unit,
					{ "status", "unitStatus", "groupFontOutline" },
					UF.ui.normalizeFontStyleChoice(val, usDef.groupFontOutline or usDef.fontOutline or statusDef.fontOutline or "OUTLINE")
				)
				refreshSelf()
			end,
			usDef.groupFontOutline or usDef.fontOutline or statusDef.fontOutline or "OUTLINE",
			"statusText"
		)
		groupFontOutlineSetting.isEnabled = isGroupEnabled
		list[#list + 1] = groupFontOutlineSetting

		list[#list + 1] = slider(
			L["UFUnitStatusGroupOffsetX"] or "Group number X offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "status", "unitStatus", "groupOffset", "x" }, (usDef.groupOffset and usDef.groupOffset.x) or 0) end,
			function(val)
				local off = getValue(unit, { "status", "unitStatus", "groupOffset" }, { x = 0, y = 0 }) or {}
				off.x = val or 0
				setValue(unit, { "status", "unitStatus", "groupOffset" }, off)
				refresh()
			end,
			(usDef.groupOffset and usDef.groupOffset.x) or 0,
			"statusText",
			true
		)
		list[#list].isEnabled = isGroupEnabled

		list[#list + 1] = slider(
			L["UFUnitStatusGroupOffsetY"] or "Group number Y offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "status", "unitStatus", "groupOffset", "y" }, (usDef.groupOffset and usDef.groupOffset.y) or 0) end,
			function(val)
				local off = getValue(unit, { "status", "unitStatus", "groupOffset" }, { x = 0, y = 0 }) or {}
				off.y = val or 0
				setValue(unit, { "status", "unitStatus", "groupOffset" }, off)
				refresh()
			end,
			(usDef.groupOffset and usDef.groupOffset.y) or 0,
			"statusText",
			true
		)
		list[#list].isEnabled = isGroupEnabled
		list[#list + 1] = { name = "", kind = UF.ui.settingType.Divider, parentId = "unitStatus" }

		local restDef = def.resting or {}
		local function isRestEnabled() return getValue(unit, { "resting", "enabled" }, restDef.enabled ~= false) ~= false end

		list[#list + 1] = checkbox(L["UFRestingEnable"] or "Show resting indicator", function() return getValue(unit, { "resting", "enabled" }, restDef.enabled ~= false) ~= false end, function(val)
			setValue(unit, { "resting", "enabled" }, val and true or false)
			refresh()
		end, restDef.enabled ~= false, "unitStatus")

		list[#list + 1] = slider(L["UFRestingSize"] or "Resting size", 10, 80, 1, function() return getValue(unit, { "resting", "size" }, restDef.size or 20) end, function(val)
			setValue(unit, { "resting", "size" }, val or restDef.size or 20)
			refresh()
		end, restDef.size or 20, "unitStatus", true)
		list[#list].isEnabled = isRestEnabled

		list[#list + 1] = slider(
			L["UFRestingOffsetX"] or "Resting offset X",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "resting", "offset", "x" }, (restDef.offset and restDef.offset.x) or 0) end,
			function(val)
				local defx = (restDef.offset and restDef.offset.x) or 0
				local off = getValue(unit, { "resting", "offset" }, { x = defx, y = 0 }) or {}
				off.x = val ~= nil and val or defx
				setValue(unit, { "resting", "offset" }, off)
				refresh()
			end,
			(restDef.offset and restDef.offset.x) or 0,
			"unitStatus",
			true
		)
		list[#list].isEnabled = isRestEnabled

		list[#list + 1] = slider(
			L["UFRestingOffsetY"] or "Resting offset Y",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "resting", "offset", "y" }, (restDef.offset and restDef.offset.y) or 0) end,
			function(val)
				local defy = (restDef.offset and restDef.offset.y) or 0
				local off = getValue(unit, { "resting", "offset" }, { x = 0, y = defy }) or {}
				off.y = val ~= nil and val or defy
				setValue(unit, { "resting", "offset" }, off)
				refresh()
			end,
			(restDef.offset and restDef.offset.y) or 0,
			"unitStatus",
			true
		)
		list[#list].isEnabled = isRestEnabled
		list[#list + 1] = { name = "", kind = UF.ui.settingType.Divider, parentId = "unitStatus" }
	end

	if isPlayer or unit == "target" or unit == "focus" then
		local ciDef = statusDef.combatIndicator or {}
		local function isCombatIndicatorEnabled() return getValue(unit, { "status", "combatIndicator", "enabled" }, ciDef.enabled ~= false) ~= false end
		local function getCombatIndicatorIconValue()
			return getValue(unit, { "status", "combatIndicator", "icon" }, ciDef.icon or UF.COMBAT_INDICATOR_DEFAULT_ICON or "DEFAULT") or UF.COMBAT_INDICATOR_DEFAULT_ICON or "DEFAULT"
		end
		local function getCombatIndicatorIconLabel(value)
			if UF.GetCombatIndicatorIconMarkup then return UF.GetCombatIndicatorIconMarkup(value, 18) end
			return tostring(value or "")
		end
		local combatIndicatorToggle = checkbox(
			L["UFCombatIndicator"] or "Show combat indicator",
			function() return getValue(unit, { "status", "combatIndicator", "enabled" }, ciDef.enabled ~= false) end,
			function(val)
				setValue(unit, { "status", "combatIndicator", "enabled" }, val and true or false)
				refresh()
				refreshSettingsUI()
			end,
			ciDef.enabled ~= false,
			"unitStatus"
		)
		list[#list + 1] = combatIndicatorToggle

		local combatIndicatorIcon = {
			name = L["Icon"] or "Icon",
			kind = UF.ui.settingType.Dropdown,
			height = 180,
			parentId = "unitStatus",
			default = ciDef.icon or UF.COMBAT_INDICATOR_DEFAULT_ICON or "DEFAULT",
			generator = function(_, root)
				local options = UF.COMBAT_INDICATOR_ICONS or {}
				for _, option in ipairs(options) do
					local value = option.value
					local label = getCombatIndicatorIconLabel(value)
					root:CreateRadio(label, function() return getCombatIndicatorIconValue() == value end, function()
						setValue(unit, { "status", "combatIndicator", "icon" }, value or UF.COMBAT_INDICATOR_DEFAULT_ICON or "DEFAULT")
						refresh()
						refreshSettingsUI()
					end)
				end
			end,
		}
		combatIndicatorIcon.isEnabled = isCombatIndicatorEnabled
		list[#list + 1] = combatIndicatorIcon

		local combatIndicatorSize = slider(
			L["UFCombatIndicatorSize"] or "Combat indicator size",
			10,
			64,
			1,
			function() return getValue(unit, { "status", "combatIndicator", "size" }, ciDef.size or 18) end,
			function(val)
				setValue(unit, { "status", "combatIndicator", "size" }, val or ciDef.size or 18)
				refresh()
			end,
			ciDef.size or 18,
			"unitStatus",
			true
		)
		combatIndicatorSize.isEnabled = isCombatIndicatorEnabled
		list[#list + 1] = combatIndicatorSize

		local combatIndicatorOffsetX = slider(
			L["UFCombatIndicatorOffsetX"] or "Combat indicator X offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "status", "combatIndicator", "offset", "x" }, (ciDef.offset and ciDef.offset.x) or -8) end,
			function(val)
				local off = getValue(unit, { "status", "combatIndicator", "offset" }, { x = -8, y = 0 }) or {}
				off.x = val or -8
				setValue(unit, { "status", "combatIndicator", "offset" }, off)
				refresh()
			end,
			(ciDef.offset and ciDef.offset.x) or -8,
			"unitStatus",
			true
		)
		combatIndicatorOffsetX.isEnabled = isCombatIndicatorEnabled
		list[#list + 1] = combatIndicatorOffsetX

		local combatIndicatorOffsetY = slider(
			L["UFCombatIndicatorOffsetY"] or "Combat indicator Y offset",
			-OFFSET_RANGE,
			OFFSET_RANGE,
			1,
			function() return getValue(unit, { "status", "combatIndicator", "offset", "y" }, (ciDef.offset and ciDef.offset.y) or 0) end,
			function(val)
				local off = getValue(unit, { "status", "combatIndicator", "offset" }, { x = -8, y = 0 }) or {}
				off.y = val or 0
				setValue(unit, { "status", "combatIndicator", "offset" }, off)
				refresh()
			end,
			(ciDef.offset and ciDef.offset.y) or 0,
			"unitStatus",
			true
		)
		combatIndicatorOffsetY.isEnabled = isCombatIndicatorEnabled
		list[#list + 1] = combatIndicatorOffsetY
	end

	appendUnitCombatFeedbackSettings(list, unit, def, refreshSelf)

	appendUnitAuraSettings(list, unit, def, refreshSelf)


	-- Keep section order stable across units while preserving each section's internal order.
	local commonSectionOrder = {
		"utility",
		"frame",
		"layout",
		"border",
		"highlight",
		"portrait",
		"name",
		"health",
		"incomingHeal",
		"absorb",
		"healAbsorb",
		"power",
		"level",
		"statusText",
		"unitStatus",
		"rangeFade",
		"dispelTint",
		"raidicon",
		"buffs",
		"debuffs",
	}
	local specificSectionOrder = {
		"secondaryPower",
		"secondaryPowerStaggerColors",
		"classResource",
		"totemFrame",
		"cast",
		"combatFeedback",
		"npcColors",
	}

	local sectionHeaderIndexById = {}
	local encounteredSectionIds = {}
	for i = 1, #list do
		local entry = list[i]
		if type(entry) == "table" and entry.kind == UF.ui.settingType.Collapsible and type(entry.id) == "string" and sectionHeaderIndexById[entry.id] == nil then
			sectionHeaderIndexById[entry.id] = i
			encounteredSectionIds[#encounteredSectionIds + 1] = entry.id
		end
	end

	local orderedSectionIds = {}
	local seenSectionIds = {}
	for i = 1, #commonSectionOrder do
		local id = commonSectionOrder[i]
		if sectionHeaderIndexById[id] then
			orderedSectionIds[#orderedSectionIds + 1] = id
			seenSectionIds[id] = true
		end
	end
	local firstSpecificSectionIndex
	for i = 1, #specificSectionOrder do
		local id = specificSectionOrder[i]
		if sectionHeaderIndexById[id] then
			if not firstSpecificSectionIndex then firstSpecificSectionIndex = #orderedSectionIds + 1 end
			orderedSectionIds[#orderedSectionIds + 1] = id
			seenSectionIds[id] = true
		end
	end
	for i = 1, #encounteredSectionIds do
		local id = encounteredSectionIds[i]
		if not seenSectionIds[id] then
			orderedSectionIds[#orderedSectionIds + 1] = id
			seenSectionIds[id] = true
		end
	end

	local orderedList = {}
	local appended = {}
	for i = 1, #orderedSectionIds do
		if firstSpecificSectionIndex and i == firstSpecificSectionIndex and #orderedList > 0 then orderedList[#orderedList + 1] = { name = "", kind = UF.ui.settingType.Divider } end
		local id = orderedSectionIds[i]
		local headerIndex = sectionHeaderIndexById[id]
		if headerIndex and not appended[headerIndex] then
			orderedList[#orderedList + 1] = list[headerIndex]
			appended[headerIndex] = true
		end
		for j = 1, #list do
			if not appended[j] then
				local entry = list[j]
				if type(entry) == "table" and entry.parentId == id then
					orderedList[#orderedList + 1] = entry
					appended[j] = true
				end
			end
		end
	end

	for i = 1, #list do
		if not appended[i] then orderedList[#orderedList + 1] = list[i] end
	end

	return orderedList
end

local function buildStandaloneCastbarSettings()
	if not (CastbarSettings and CastbarSettings.BuildStandaloneCastbarSettings) then return {} end
	local list = CastbarSettings.BuildStandaloneCastbarSettings({
		L = L,
		settingType = settingType,
		getCastbarModule = getCastbarModule,
		toRGBA = toRGBA,
		refreshSettingsUI = refreshSettingsUI,
		textureOptions = textureOptions,
		borderOptions = borderOptions,
		fontOptions = fontOptions,
		outlineOptions = outlineOptions,
		strataOptionsWithDefault = strataOptionsWithDefault,
		OFFSET_RANGE = OFFSET_RANGE,
		checkbox = checkbox,
		slider = slider,
		radioDropdown = radioDropdown,
		checkboxDropdown = checkboxDropdown,
		checkboxColor = checkboxColor,
	})
	if type(list) ~= "table" then return {} end
	do
		local anchorName = L["UFCastNameAnchor"] or "Cast name anchor"
		for i = 1, #list do
			local entry = list[i]
			if type(entry) == "table" and entry.parentId == "castSpellName" and entry.name == anchorName then return list end
		end
	end

	local function normalizeCastNameAnchor(value, fallback)
		local anchor = type(value) == "string" and string.upper(value) or nil
		local fallbackAnchor = type(fallback) == "string" and string.upper(fallback) or "LEFT"
		if fallbackAnchor ~= "LEFT" and fallbackAnchor ~= "CENTER" and fallbackAnchor ~= "RIGHT" then fallbackAnchor = "LEFT" end
		if anchor ~= "LEFT" and anchor ~= "CENTER" and anchor ~= "RIGHT" then return fallbackAnchor end
		return anchor
	end

	local castCfg, castDef
	local castbarModule = getCastbarModule()
	if castbarModule and castbarModule.GetConfig then
		castCfg, castDef = castbarModule.GetConfig()
	end
	if type(castCfg) ~= "table" then
		addon.db = addon.db or {}
		addon.db.castbar = type(addon.db.castbar) == "table" and addon.db.castbar or {}
		castCfg = addon.db.castbar
	end
	if type(castDef) ~= "table" and castbarModule and castbarModule.GetDefaults then castDef = castbarModule.GetDefaults() end
	if type(castDef) ~= "table" then castDef = {} end

	local function refreshCastbar()
		local module = getCastbarModule()
		if module and module.Refresh then module.Refresh() end
	end
	local function isCastNameEnabled()
		local showName = castCfg.showName
		if showName == nil then showName = castDef.showName ~= false end
		return showName ~= false
	end

	local castNameAnchorSetting = radioDropdown(
		L["UFCastNameAnchor"] or "Cast name anchor",
		anchorOptions,
		function() return normalizeCastNameAnchor(castCfg.nameAnchor, castDef.nameAnchor or "LEFT") end,
		function(val)
			castCfg.nameAnchor = normalizeCastNameAnchor(val, castDef.nameAnchor or "LEFT")
			refreshCastbar()
		end,
		normalizeCastNameAnchor(castDef.nameAnchor, "LEFT"),
		"castSpellName"
	)
	castNameAnchorSetting.isEnabled = isCastNameEnabled

	local insertIndex = #list + 1
	local targetName = L["Name X Offset"] or "Name X Offset"
	for i = 1, #list do
		local entry = list[i]
		if type(entry) == "table" and entry.parentId == "castSpellName" and entry.name == targetName then
			insertIndex = i
			break
		end
	end
	table.insert(list, insertIndex, castNameAnchorSetting)
	return list
end

local standaloneCastbarSettingsRegistered = false
local function registerStandaloneCastbarEditModeSettings()
	if standaloneCastbarSettingsRegistered then return end
	local CastbarModule = getCastbarModule()
	if not (CastbarModule and CastbarModule.SetEditModeSettings) then return end
	CastbarModule.SetEditModeSettings(buildStandaloneCastbarSettings())
	standaloneCastbarSettingsRegistered = true
end

local DEFAULT_SETTINGS_MAX_HEIGHT = 900
local DEFAULT_SETTINGS_SCREEN_MARGIN = 200
local registeredUnitFrames = {}
local settingsMaxHeightWatcher

local function getSettingsMaxHeight()
	local screenHeight = addon.variables and tonumber(addon.variables.screenHeight)
	if (not screenHeight or screenHeight <= 0) and GetScreenHeight then
		screenHeight = tonumber(GetScreenHeight())
		if screenHeight and screenHeight > 0 then
			addon.variables = addon.variables or {}
			addon.variables.screenHeight = screenHeight
		end
	end
	if not screenHeight or screenHeight <= 0 then return DEFAULT_SETTINGS_MAX_HEIGHT end
	if screenHeight < DEFAULT_SETTINGS_MAX_HEIGHT then return screenHeight end
	return math.max(DEFAULT_SETTINGS_MAX_HEIGHT, screenHeight - DEFAULT_SETTINGS_SCREEN_MARGIN)
end

local function applyFrameSettingsMaxHeight(frame, maxHeight)
	local lib = addon.EditModeLib or (EditMode and EditMode.lib)
	if not (lib and lib.SetFrameSettingsMaxHeight and frame) then return end
	lib:SetFrameSettingsMaxHeight(frame, maxHeight or getSettingsMaxHeight())
end

local function applyRegisteredSettingsMaxHeight()
	local maxHeight = getSettingsMaxHeight()
	for _, frame in pairs(registeredUnitFrames) do
		applyFrameSettingsMaxHeight(frame, maxHeight)
	end
end

local function ensureSettingsMaxHeightWatcher()
	if settingsMaxHeightWatcher then return end
	settingsMaxHeightWatcher = CreateFrame("Frame")
	settingsMaxHeightWatcher:RegisterEvent("PLAYER_LOGIN")
	settingsMaxHeightWatcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
	settingsMaxHeightWatcher:RegisterEvent("UI_SCALE_CHANGED")
	settingsMaxHeightWatcher:SetScript("OnEvent", function()
		if GetScreenHeight then
			local screenHeight = tonumber(GetScreenHeight())
			if screenHeight and screenHeight > 0 then
				addon.variables = addon.variables or {}
				addon.variables.screenHeight = screenHeight
			end
		end
		applyRegisteredSettingsMaxHeight()
	end)
end

local function registerUnitFrame(unit, info)
	if registeredUnitFrames[unit] then return false end
	if UF.EnsureFrames then
		if unit == "boss" then
			for i = 1, getBossFrameCount() do
				UF.EnsureFrames("boss" .. i)
			end
		else
			UF.EnsureFrames(unit)
		end
	end
	local frame = _G[info.frameName]
	if not frame then return false end
	local layout = calcLayout(unit, frame)
	local settingsList = buildUnitSettings(unit)
	local function applyAnchorFromEditModeData(data)
		if type(data) ~= "table" or not data.point or not anchorUsesUIParent(unit) then return end
		local cfg = ensureConfig(unit)
		cfg.anchor = cfg.anchor or {}
		local oldPoint = cfg.anchor.point
		local oldRelativePoint = cfg.anchor.relativePoint
		local oldX = cfg.anchor.x or 0
		local oldY = cfg.anchor.y or 0
		local newPoint = data.point
		local newRelativePoint = data.relativePoint or data.point
		local newX = data.x or 0
		local newY = data.y or 0
		cfg.anchor.relativeTo = cfg.anchor.relativeTo or cfg.anchor.relativeFrame or "UIParent"
		cfg.anchor.relativeFrame = cfg.anchor.relativeTo
		local def = defaultsFor(unit)
		local showStatus = unit ~= "boss" and UF.ShouldShowStatusLayout and UF.ShouldShowStatusLayout(cfg, unit, def)
		local statusHeightDelta = unit ~= "boss" and UF.GetStatusHeightDelta and UF.GetStatusHeightDelta(showStatus) or 0
		local relativeFrame = UF.ResolveRelativeAnchorFrame and UF.ResolveRelativeAnchorFrame(cfg.anchor.relativeTo, info.frameName) or UIParent
		if UF.ResolveStoredUnitFrameAnchorY then newY = UF.ResolveStoredUnitFrameAnchorY(newPoint, newRelativePoint, newY, relativeFrame, statusHeightDelta) end
		if oldPoint == newPoint and oldRelativePoint == newRelativePoint and oldX == newX and oldY == newY then return end
		cfg.anchor.point = newPoint
		cfg.anchor.relativePoint = newRelativePoint
		cfg.anchor.x = newX
		cfg.anchor.y = newY
		requestRefresh(unit)
		refreshSettingsUI()
	end
	EditMode:RegisterFrame(info.frameId, {
		frame = frame,
		title = info.title,
		enableOverlayToggle = true,
		allowDrag = function() return anchorUsesUIParent(unit) end,
		settingsSpacing = 1,
		sliderHeight = 28,
		layoutDefaults = layout,
		normalizePosition = true,
		settingsMaxHeight = DEFAULT_SETTINGS_MAX_HEIGHT,
		onPositionChanged = function(_, _, data) applyAnchorFromEditModeData(data) end,
		relativeTo = function() return UnitAnchor.ResolveEditModeFrame(unit) end,
		onEnter = function(activeFrame) syncEditModeSelectionStrata(activeFrame) end,
		isEnabled = function() return ensureConfig(unit).enabled == true end,
		settings = settingsList,
		showOutsideEditMode = true,
		collapseExclusive = true,
		showReset = false,
	})
	local editorContext = getGlobalAuraIgnoreEditorContext(unit)
	if EditMode and EditMode.RegisterButtons then
		local buttons = {
			{
				text = L["Toggle sample"] or "Toggle sample",
				click = function()
					if UF and UF.ToggleEditModeSample then UF.ToggleEditModeSample(unit) end
				end,
			},
		}
		if editorContext then
			buttons[#buttons + 1] = {
				text = L["UFGlobalAuraIgnoreEditModeButton"] or L["UFGroupGlobalAuraIgnoreEditModeButton"] or "Edit aura ignore",
				click = function() toggleGlobalAuraIgnoreEditor(editorContext) end,
			}
		end
		EditMode:RegisterButtons(info.frameId, buttons)
	end
	registeredUnitFrames[unit] = frame
	applyFrameSettingsMaxHeight(frame)
	hideFrameReset(frame)
	-- Keep EditMode data in sync with the authoritative UF profile anchor.
	refreshEditModeFrame(unit)
	return true
end

function UF.IsEditModeLayoutReady()
	local editMode = addon.EditMode
	local lib = editMode and editMode.lib
	if not lib or not lib.GetActiveLayoutName then return true end
	local name = lib:GetActiveLayoutName()
	return name ~= nil and name ~= ""
end

local function registerEditModeFrames(requestedUnit)
	if not UF.IsEditModeLayoutReady() then return false end
	ensureSettingsMaxHeightWatcher()
	UF.EditModeRegistered = true
	local frames = {
		player = { frameName = "EQOLUFPlayerFrame", frameId = frameIds.player, title = L["UFPlayerFrame"] or PLAYER },
		target = { frameName = "EQOLUFTargetFrame", frameId = frameIds.target, title = L["UFTargetFrame"] or TARGET },
		targettarget = { frameName = "EQOLUFToTFrame", frameId = frameIds.targettarget, title = L["UFToTFrame"] or "Target of Target" },
		pet = { frameName = "EQOLUFPetFrame", frameId = frameIds.pet, title = L["UFPetFrame"] or PET },
		focus = { frameName = "EQOLUFFocusFrame", frameId = frameIds.focus, title = L["UFFocusFrame"] or FOCUS },
		boss = { frameName = "EQOLUFBossContainer", frameId = frameIds.boss, title = (L["UFBossFrame"] or "Boss Frames") },
	}
	local registeredAny = false
	beginRefreshBatch()
	local ok, err = pcall(function()
		for unit, info in pairs(frames) do
			local matchesRequest = requestedUnit == nil or requestedUnit == unit
			local cfg = matchesRequest and ensureConfig(unit) or nil
			if cfg and cfg.enabled == true and registerUnitFrame(unit, info) then registeredAny = true end
		end
		applyRegisteredSettingsMaxHeight()
	end)
	endRefreshBatch()
	if not ok then error(err) end
	local internal = registeredAny and addon.EditModeLib and addon.EditModeLib.internal
	if internal and internal.RefreshSettingValues then internal:RefreshSettingValues() end
	return registeredAny
end

function UF.RegisterEnabledEditModeFrames(unit)
	return registerEditModeFrames(unit)
end

local function registerGlobalAuraIgnoreSettingsCenterControl(parentSection)
	local app = addon.ConfigApp
	local editor = UF and UF.GlobalAuraIgnore
	if not (app and editor and editor.RenderSettingsCenterTable) then return end
	local pageID = parentSection and app.legacySections and app.legacySections[parentSection]
	if not pageID then return end
	local groupID = "unitframes-global-aura-ignore"
	local title = L["UFGlobalAuraIgnoreMatrixTitle"] or L["UFGlobalAuraIgnoreEditorTitle"] or "Global Aura Ignore"
	app:RegisterGroup(pageID, {
		id = groupID,
		title = title,
		order = 30,
	})
	app:RegisterControl(pageID, {
		id = "UFGlobalAuraIgnoreMatrix",
		type = "custom",
		label = title,
		description = L["UFGlobalAuraIgnoreMatrixDesc"] or "Configure ignored auras for Player, Target, Focus, Group and Raid unit frames.",
		groupID = groupID,
		groupTitle = title,
		order = 10,
		newTagID = "UFGlobalAuraIgnoreMatrix",
		getHeight = function()
			if editor.GetSettingsCenterTableHeight then return editor.GetSettingsCenterTableHeight() end
			return 1200
		end,
		render = function(parent, appInstance, control, state, focusID)
			return editor.RenderSettingsCenterTable(parent, {
				app = appInstance,
				page = control,
				state = state,
				focusID = focusID,
			})
		end,
		release = function(handle)
			if handle and handle.Release then handle:Release() end
		end,
	})
end

local function registerSettingsUI()
	if UF.SettingsRegistered then return end
	if not (addon.functions and addon.functions.SettingsCreateCategory) then return end
	-- Simple toggles in Settings panel (keep basic visibility outside Edit Mode)
	local cUF = addon.SettingsLayout.rootUI
	local function getStandaloneCastbarConfig()
		addon.db = addon.db or {}
		addon.db.castbar = type(addon.db.castbar) == "table" and addon.db.castbar or {}
		local castbar = getCastbarModule()
		local cfg, defaults
		if castbar and castbar.GetConfig then cfg, defaults = castbar.GetConfig() end
		cfg = type(cfg) == "table" and cfg or addon.db.castbar
		defaults = type(defaults) == "table" and defaults or {}
		if cfg.enabled == nil then cfg.enabled = defaults.enabled == true end
		return cfg
	end
	local function refreshStandaloneCastbar()
		local castbar = getCastbarModule()
		if castbar and castbar.Refresh then castbar.Refresh() end
		if addon.functions and addon.functions.ApplyCastBarVisibility then addon.functions.ApplyCastBarVisibility() end
	end
	local castbarExpandable = addon.SettingsLayout.suitesCastbarSection
	if not castbarExpandable then
		castbarExpandable = addon.functions.SettingsCreateExpandableSection(cUF, {
			name = L["Castbar"] or L["CastBars2"] or "Castbar",
			description = L["configCenterPageDescEQoLCastbar"] or "Enable and configure the standalone EQoL player castbar. Size, position and style are handled in Edit Mode.",
			expanded = false,
			colorizeTitle = false,
			newTagID = "EQoLCastbar",
			configPageKey = "EQoLCastbar",
			iconKey = "castbar",
			modernCategory = "suites",
			modernOnly = true,
		})
		addon.SettingsLayout.suitesCastbarSection = castbarExpandable
	end
	addon.functions.SettingsCreateSectionHeader(cUF, ("EQoL %s"):format(L["Castbar"] or L["CastBars2"] or "Castbar"), {
		parentSection = castbarExpandable,
	})
	addon.functions.SettingsCreateCheckbox(cUF, {
		var = "useCustomPlayerCastbar",
		text = L["useCustomPlayerCastbar"] or "Enable castbar",
		desc = L["useCustomPlayerCastbarDesc"] or "Enable the EQoL castbar.",
		get = function() return getStandaloneCastbarConfig().enabled == true end,
		func = function(value)
			local castCfg = getStandaloneCastbarConfig()
			castCfg.enabled = value and true or false
			addon.db.useCustomPlayerCastbar = castCfg.enabled
			refreshStandaloneCastbar()
		end,
		default = false,
		parentSection = castbarExpandable,
	})
	addon.functions.SettingsCreateText(cUF, "|cffffd700" .. (L["useCustomPlayerCastbarHint"] or "Configure size, position, and style in Edit Mode.") .. "|r", {
		parentSection = castbarExpandable,
	})

	local expandable = addon.SettingsLayout.expEQoLUnitFrames
	if not expandable then
		expandable = addon.functions.SettingsCreateExpandableSection(cUF, {
			name = L["CustomUnitFrames"] or "EQoL Unit Frames",
			description = L["configCenterPageDescUnitFrames"]
				or "Customize player, target, focus, party and group frames, including layout, bars, auras, text and profiles.",
			newTagID = "CustomUnitFrames",
			iconKey = "unitframes",
			modernCategory = "suites",
			modernOnly = true,
			expanded = false,
			colorizeTitle = false,
		})
		addon.SettingsLayout.expEQoLUnitFrames = expandable
	end
	registerGlobalAuraIgnoreSettingsCenterControl(expandable)

	addon.SettingsLayout.ufPlusCategory = cUF
	addon.functions.SettingsCreateText(cUF, "|cff99e599" .. L["UFPlusHint"] .. "|r", { parentSection = expandable })
	addon.functions.SettingsCreateText(cUF, "", { parentSection = expandable })
	local function getGroupFramesConfig(kind)
		if UF and UF.GroupFrames and UF.GroupFrames.GetConfig then return UF.GroupFrames:GetConfig(kind) end
		addon.db = addon.db or {}
		addon.db.ufGroupFrames = addon.db.ufGroupFrames or {}
		addon.db.ufGroupFrames[kind] = addon.db.ufGroupFrames[kind] or {}
		return addon.db.ufGroupFrames[kind]
	end
	local frameToggleDesc = L["UFFrameToggleEditModeDesc"] or "Enable this frame here, then adjust layout and position in Edit Mode."
	local function hasClassColorConsumer()
		if ensureConfig("player").enabled == true then return true end
		if ensureConfig("target").enabled == true then return true end
		if ensureConfig("targettarget").enabled == true then return true end
		local partyCfg = getGroupFramesConfig("party")
		if partyCfg and partyCfg.enabled == true then return true end
		local raidCfg = getGroupFramesConfig("raid")
		if raidCfg and raidCfg.enabled == true then return true end
		local mtCfg = getGroupFramesConfig("mt")
		if mtCfg and mtCfg.enabled == true then return true end
		local maCfg = getGroupFramesConfig("ma")
		return maCfg and maCfg.enabled == true
	end
	addon.functions.SettingsCreateHeadline(cUF, L["UFGroupFrames"] or "Group Frames", { parentSection = expandable, order = 20 })
	addon.functions.SettingsCreateCheckbox(cUF, {
		var = "ufEnablePartyGroupFrames",
		text = L["UFGroupFramesPartyEnable"] or "Enable party frames",
		desc = frameToggleDesc,
		default = false,
		get = function()
			local cfg = getGroupFramesConfig("party")
			return cfg and cfg.enabled == true
		end,
		func = function(val)
			local cfg = getGroupFramesConfig("party")
			if cfg then cfg.enabled = val and true or false end
			if UF and UF.GroupFrames then
				if val then
					UF.GroupFrames:Enable("party")
				else
					UF.GroupFrames:Disable("party")
				end
			end
			if val == false then
				addon.variables.requireReload = true
				if addon.functions and addon.functions.checkReloadFrame then addon.functions.checkReloadFrame() end
			end
			refreshSettingsUI()
		end,
		parentSection = expandable,
	})
	addon.functions.SettingsCreateCheckbox(cUF, {
		var = "ufEnableRaidGroupFrames",
		text = L["UFGroupFramesRaidEnable"] or "Enable raid frames",
		desc = frameToggleDesc,
		default = false,
		get = function()
			local cfg = getGroupFramesConfig("raid")
			return cfg and cfg.enabled == true
		end,
		func = function(val)
			local cfg = getGroupFramesConfig("raid")
			if cfg then cfg.enabled = val and true or false end
			if UF and UF.GroupFrames then
				if val then
					UF.GroupFrames:Enable("raid")
				else
					UF.GroupFrames:Disable("raid")
				end
			end
			if val == false then
				addon.variables.requireReload = true
				if addon.functions and addon.functions.checkReloadFrame then addon.functions.checkReloadFrame() end
			end
			refreshSettingsUI()
		end,
		parentSection = expandable,
	})
	addon.functions.SettingsCreateButton(cUF, {
		var = "ufSpotlightFramesKeybind",
		newTagID = "ufSpotlightFramesKeybind",
		text = L["UFSpotlightFrames"] or "Spotlight frames",
		desc = L["UFSpotlightKeybindDesc"] or "Assign the key used while hovering a raid frame to add or remove that player from Spotlight frames.",
		label = _G.KEY_BINDINGS or "Key Bindings",
		buttonText = _G.KEY_BINDINGS or "Key Bindings",
		parentSection = expandable,
		onClick = function()
			if Settings and Settings.OpenToCategory and Settings.KEYBINDINGS_CATEGORY_ID then
				Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID, "Enhance QoL")
			end
		end,
		isEnabled = function()
			local raidCfg = getGroupFramesConfig("raid")
			return raidCfg and raidCfg.enabled == true and tostring(raidCfg.spotlightPosition or "DISABLED"):upper() ~= "DISABLED"
		end,
	})
	addon.functions.SettingsCreateCheckbox(cUF, {
		var = "ufEnableMainTankGroupFrames",
		text = L["UFGroupFramesMTEnable"] or "Enable Main Tank frames",
		desc = frameToggleDesc,
		default = false,
		get = function()
			local cfg = getGroupFramesConfig("mt")
			return cfg and cfg.enabled == true
		end,
		func = function(val)
			local cfg = getGroupFramesConfig("mt")
			if cfg then cfg.enabled = val and true or false end
			if UF and UF.GroupFrames then
				if val then
					UF.GroupFrames:Enable("mt")
				else
					UF.GroupFrames:Disable("mt")
				end
			end
			refreshSettingsUI()
		end,
		isEnabled = function()
			local raidCfg = getGroupFramesConfig("raid")
			return raidCfg and raidCfg.enabled == true
		end,
		parentSection = expandable,
	})
	addon.functions.SettingsCreateCheckbox(cUF, {
		var = "ufEnableMainAssistGroupFrames",
		text = L["UFGroupFramesMAEnable"] or "Enable Main Assist frames",
		desc = frameToggleDesc,
		default = false,
		get = function()
			local cfg = getGroupFramesConfig("ma")
			return cfg and cfg.enabled == true
		end,
		func = function(val)
			local cfg = getGroupFramesConfig("ma")
			if cfg then cfg.enabled = val and true or false end
			if UF and UF.GroupFrames then
				if val then
					UF.GroupFrames:Enable("ma")
				else
					UF.GroupFrames:Disable("ma")
				end
			end
			refreshSettingsUI()
		end,
		isEnabled = function()
			local raidCfg = getGroupFramesConfig("raid")
			return raidCfg and raidCfg.enabled == true
		end,
		parentSection = expandable,
	})
	local function addToggle(unit, label, varName)
		local def = defaultsFor(unit)
		addon.functions.SettingsCreateCheckbox(cUF, {
			var = varName,
			text = label,
			desc = frameToggleDesc,
			default = def.enabled or false,
			get = function() return ensureConfig(unit).enabled == true end,
			func = function(val)
				local cfg = ensureConfig(unit)
				cfg.enabled = val and true or false
				if UF.SetRuntimeConsumerActive then UF.SetRuntimeConsumerActive("unit", unit, cfg.enabled) end
				if unit == "player" then
					if cfg.enabled then
						UF.Enable()
					else
						UF.Disable()
					end
				else
					UF.Refresh()
				end
				if UF.StopEventsIfInactive then UF.StopEventsIfInactive() end
				refreshEditModeFrame(unit)
				if val == false then
					addon.variables.requireReload = true
					if addon.functions and addon.functions.checkReloadFrame then addon.functions.checkReloadFrame() end
				end
			end,
			parentSection = expandable,
		})
		return def.enabled or false
	end

	addon.functions.SettingsCreateHeadline(cUF, L["UFSoloFrames"] or "Solo Frames", { parentSection = expandable, order = 10 })
	addToggle("player", L["UFPlayerEnable"] or "Enable custom player frame", "ufEnablePlayer")
	addToggle("target", L["UFTargetEnable"] or "Enable custom target frame", "ufEnableTarget")
	addToggle("targettarget", L["UFToTEnable"] or "Enable target-of-target frame", "ufEnableToT")
	addToggle("pet", L["UFPetEnable"] or "Enable pet frame", "ufEnablePet")
	addToggle("focus", L["UFFocusEnable"] or "Enable focus frame", "ufEnableFocus")
	addon.functions.SettingsCreateCheckbox(cUF, {
		var = "ufEnableBoss",
		text = L["UFBossEnable"] or "Enable boss frames",
		desc = frameToggleDesc,
		default = false,
		get = function() return ensureConfig("boss").enabled == true end,
		func = function(val)
			local cfg = ensureConfig("boss")
			cfg.enabled = val and true or false
			if UF.Refresh then UF.Refresh() end
			if UF.StopEventsIfInactive then UF.StopEventsIfInactive() end
			refreshEditModeFrame("boss")
			if val == false then
				addon.variables.requireReload = true
				if addon.functions and addon.functions.checkReloadFrame then addon.functions.checkReloadFrame() end
			end
		end,
		parentSection = expandable,
	})


	local function getDefaultClassColor(classTag)
		local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classTag]
		if color then
			if color.GetRGBA then return color:GetRGBA() end
			return color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1, color.a or color[4] or 1
		end
		if C_ClassColor and C_ClassColor.GetClassColor then
			local classColor = C_ClassColor.GetClassColor(classTag)
			if classColor and classColor.GetRGBA then return classColor:GetRGBA() end
		end
		return 1, 1, 1, 1
	end

	local function ensureCustomClassColors()
		local classColors = (UFProfiles and UFProfiles.EnsureTableKey and UFProfiles.EnsureTableKey("ufClassColors")) or addon.db.ufClassColors or {}
		addon.db.ufClassColors = classColors
		local order = CLASS_SORT_ORDER or {}
		if #order == 0 and RAID_CLASS_COLORS then
			for classTag in pairs(RAID_CLASS_COLORS) do
				order[#order + 1] = classTag
			end
			table.sort(order)
		end
		for _, classTag in ipairs(order) do
			if not classColors[classTag] then
				local r, g, b, a = getDefaultClassColor(classTag)
				classColors[classTag] = { r = r, g = g, b = b, a = a }
			end
		end
	end

	local classEntries = {}
	do
		local order = CLASS_SORT_ORDER or {}
		if #order == 0 and RAID_CLASS_COLORS then
			for classTag in pairs(RAID_CLASS_COLORS) do
				order[#order + 1] = classTag
			end
			table.sort(order)
		end
		for _, classTag in ipairs(order) do
			local label = (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[classTag]) or classTag
			classEntries[#classEntries + 1] = { key = classTag, label = label }
		end
	end

	addon.functions.SettingsCreateHeadline(cUF, L["Class colors"] or "Class colors", { parentSection = expandable })

	addon.functions.SettingsCreateCheckbox(cUF, {
		var = "ufUseCustomClassColors",
		text = L["ufUseCustomClassColors"] or "Use custom class colors for unit frames",
		desc = L["ufUseCustomClassColorsDesc"] or "Overrides class colors used by Enhance QoL unit frames.",
		isEnabled = hasClassColorConsumer,
		func = function(value)
			if UFProfiles and UFProfiles.SetUseCustomClassColors then
				UFProfiles.SetUseCustomClassColors(value and true or false)
			else
				addon.db["ufUseCustomClassColors"] = value and true or false
			end
			if value then ensureCustomClassColors() end
			if Settings and Settings.NotifyUpdate then Settings.NotifyUpdate("EQOL_ufUseCustomClassColors") end
			if addon.Aura and addon.Aura.UF and addon.Aura.UF.Refresh then addon.Aura.UF.Refresh() end
		end,
		parentSection = expandable,
	})

	local classColorParent = addon.SettingsLayout.elements["ufUseCustomClassColors"] and addon.SettingsLayout.elements["ufUseCustomClassColors"].element
	addon.functions.SettingsCreateColorOverrides(cUF, {
		var = "ufClassColors",
		text = L["Class colors"] or "Class colors",
		entries = classEntries,
		getColor = function(key)
			local overrides = addon.db and addon.db.ufClassColors
			local color = overrides and overrides[key]
			if color then return color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1, color.a or color[4] or 1 end
			return getDefaultClassColor(key)
		end,
		setColor = function(key, r, g, b, a)
			local classColors = (UFProfiles and UFProfiles.EnsureTableKey and UFProfiles.EnsureTableKey("ufClassColors")) or addon.db.ufClassColors or {}
			addon.db.ufClassColors = classColors
			classColors[key] = { r = r, g = g, b = b, a = a }
			if addon.Aura and addon.Aura.UF and addon.Aura.UF.Refresh then addon.Aura.UF.Refresh() end
		end,
		getDefaultColor = function(key) return getDefaultClassColor(key) end,
		parent = classColorParent,
		parentCheck = function()
			local entry = addon.SettingsLayout.elements["ufUseCustomClassColors"]
			return hasClassColorConsumer() and entry and entry.setting and entry.setting:GetValue() == true
		end,
		parentSection = expandable,
	})

	local powerEntries = {}
	for _, token in ipairs(getMainPowerTokens()) do
		powerEntries[#powerEntries + 1] = { key = token, label = getPowerLabel(token) }
	end
	if #powerEntries > 0 then
		addon.functions.SettingsCreateHeadline(cUF, L["UFMainPowerColors"] or "Main power colors", { parentSection = expandable })
		addon.functions.SettingsCreateCheckbox(cUF, {
			var = "ufUseCustomPowerColors",
			text = L["ufUseCustomPowerColors"] or "Use custom power colors for unit frames",
			desc = L["ufUseCustomPowerColorsDesc"] or "Overrides main power colors used by Enhance QoL unit frames.",
			default = false,
			func = function(value)
				if UFProfiles and UFProfiles.SetUseCustomPowerColors then
					UFProfiles.SetUseCustomPowerColors(value and true or false)
				else
					addon.db.ufUseCustomPowerColors = value and true or false
				end
				if Settings and Settings.NotifyUpdate then Settings.NotifyUpdate("EQOL_ufUseCustomPowerColors") end
				if addon.Aura and addon.Aura.UF and addon.Aura.UF.Refresh then addon.Aura.UF.Refresh() end
			end,
			parentSection = expandable,
			newTagID = "ufUseCustomPowerColors",
		})
		local powerColorParent = addon.SettingsLayout.elements["ufUseCustomPowerColors"] and addon.SettingsLayout.elements["ufUseCustomPowerColors"].element
		addon.functions.SettingsCreateColorOverrides(cUF, {
			var = "ufPowerColorOverrides",
			text = L["UFMainPowerColors"] or "Main power colors",
			entries = powerEntries,
			getColor = function(key)
				local color = getPowerOverride(key)
				if color then return color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1, color.a or color[4] or 1 end
				return getDefaultPowerColor(key)
			end,
			setColor = function(key, r, g, b, a)
				setPowerOverride(key, r, g, b, a)
				if addon.Aura and addon.Aura.UF and addon.Aura.UF.Refresh then addon.Aura.UF.Refresh() end
			end,
			getDefaultColor = function(key) return getDefaultPowerColor(key) end,
			parent = powerColorParent,
			parentCheck = function()
				local entry = addon.SettingsLayout.elements["ufUseCustomPowerColors"]
				return entry and entry.setting and entry.setting:GetValue() == true
			end,
			parentSection = expandable,
		})
	end


	do -- Profile management + export/import
		if UFProfiles and UFProfiles.Initialize then UFProfiles.Initialize() end
		local scopeOptions = {
			ALL = L["UFProfileScopeAll"] or "All frames",
			player = L["UFPlayerFrame"] or PLAYER,
			target = L["UFTargetFrame"] or TARGET,
			targettarget = L["UFToTFrame"] or "Target of Target",
			focus = L["UFFocusFrame"] or FOCUS,
			pet = L["UFPetFrame"] or PET,
			boss = L["UFBossFrame"] or BOSS or "Boss Frame",
			party = PARTY or "Party",
			raid = RAID or "Raid",
			mt = MAINTANK or "Main Tank",
			ma = MAINASSIST or "Main Assist",
		}
		local scopeOrder = { "ALL", "player", "target", "targettarget", "focus", "pet", "boss", "party", "raid", "mt", "ma" }
		local function getScope()
			addon.db = addon.db or {}
			local cur = addon.db.ufProfileScope or "ALL"
			if not scopeOptions[cur] then cur = "ALL" end
			addon.db.ufProfileScope = cur
			return cur
		end
		local function setScope(val)
			addon.db = addon.db or {}
			addon.db.ufProfileScope = scopeOptions[val] and val or "ALL"
		end

		local profilesCategory = nil
		local profileOrderActive, profileOrderGlobal, profileOrderCopy, profileOrderDelete = {}, {}, {}, {}
		local noOverrideLabel = L["No override"] or "No override"

		local function clearOrder(order)
			for i = #order, 1, -1 do
				order[i] = nil
			end
		end

		local function buildProfileList(order, excludeFunc, includeEmpty, emptyLabel)
			clearOrder(order)
			local list = {}
			if includeEmpty then
				list[""] = emptyLabel or ""
				order[#order + 1] = ""
			end
			local names = (UFProfiles and UFProfiles.GetSortedNames and UFProfiles.GetSortedNames()) or {}
			for _, name in ipairs(names) do
				if not excludeFunc or not excludeFunc(name) then
					list[name] = name
					order[#order + 1] = name
				end
			end
			return list
		end

		local function getActiveUFProfile()
			if UFProfiles and UFProfiles.GetActiveName then return UFProfiles.GetActiveName() end
			return nil
		end

		local function getGlobalUFProfile()
			if UFProfiles and UFProfiles.GetGlobalName then return UFProfiles.GetGlobalName() end
			return nil
		end

		local function printUFProfileError(reason)
			if reason == "INVALID_NAME" then
				print("|cff00ff98Enhance QoL|r: " .. tostring(L["UFProfileCreateInvalid"] or "Please enter a valid Unit Frames profile name."))
			elseif reason == "EXISTS" then
				print("|cff00ff98Enhance QoL|r: " .. tostring(L["UFProfileCreateExists"] or "A Unit Frames profile with that name already exists."))
			elseif reason == "PROTECTED" then
				print("|cff00ff98Enhance QoL|r: " .. tostring(L["UFProfileDeleteBlocked"] or "You cannot delete the active or global Unit Frames profile."))
			else
				print("|cff00ff98Enhance QoL|r: " .. tostring(L["UFProfileActionFailed"] or "Could not update Unit Frames profiles."))
			end
		end

		local expandableProfile = addon.functions.SettingsCreateExpandableSection(profilesCategory, {
			name = L["CustomUnitFrames"],
			configPageKey = "UFProfiles",
			description = L["configCenterPageCardDescProfilesUnitFrames"] or L["configCenterPageDescUnitFrames"],
			iconKey = "unitframes",
			expanded = false,
			colorizeTitle = false,
			newTagID = "UFProfiles",
			modernCategory = "profiles",
			modernOnly = true,
		})

		addon.functions.SettingsCreateHeadline(profilesCategory, L["ProfileManagement"] or "Profile management", { parentSection = expandableProfile })

		addon.functions.SettingsCreateDropdown(profilesCategory, {
			var = "ufProfileActive",
			text = L["Active profile"] or (L["Active profile"] or "Active profile"),
			listFunc = function() return buildProfileList(profileOrderActive) end,
			order = profileOrderActive,
			get = function() return getActiveUFProfile() or "Default" end,
			set = function(value)
				local ok, reason
				if UFProfiles and UFProfiles.SetActiveName then
					ok, reason = UFProfiles.SetActiveName(value, "SETTINGS_DROPDOWN")
				end
				if not ok then
					local msg = L["UFProfileSetActiveFailed"] or "Could not switch the active Unit Frames profile."
					if reason == "NOT_FOUND" then msg = L["UFProfileSetActiveMissing"] or "That Unit Frames profile does not exist." end
					print("|cff00ff98Enhance QoL|r: " .. tostring(msg))
				end
			end,
			default = "Default",
			parentSection = expandableProfile,
		})

		addon.functions.SettingsCreateDropdown(profilesCategory, {
			var = "ufProfileGlobal",
			text = L["Global profile"] or (L["Global profile"] or "Global profile"),
			listFunc = function() return buildProfileList(profileOrderGlobal) end,
			order = profileOrderGlobal,
			get = function() return getGlobalUFProfile() or "Default" end,
			set = function(value)
				local ok, reason
				if UFProfiles and UFProfiles.SetGlobalName then
					ok, reason = UFProfiles.SetGlobalName(value)
				end
				if not ok then
					local msg = L["UFProfileSetGlobalFailed"] or "Could not set the global Unit Frames profile."
					if reason == "NOT_FOUND" then msg = L["UFProfileSetActiveMissing"] or "That Unit Frames profile does not exist." end
					print("|cff00ff98Enhance QoL|r: " .. tostring(msg))
				end
			end,
			default = "Default",
			parentSection = expandableProfile,
		})

		addon.functions.SettingsCreateDropdown(profilesCategory, {
			var = "ufProfileCopy",
			text = L["Copy settings from profile"] or (L["Copy settings from profile"] or "Copy settings from profile"),
			listFunc = function()
				local active = getActiveUFProfile()
				return buildProfileList(profileOrderCopy, function(name) return name == active end, true)
			end,
			order = profileOrderCopy,
			get = function() return "" end,
			set = function(value)
				if value == "" then return end
				StaticPopupDialogs["EQOL_UF_PROFILE_COPY"] = StaticPopupDialogs["EQOL_UF_PROFILE_COPY"]
					or {
						text = "",
						button1 = YES,
						button2 = CANCEL,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
						OnAccept = function(self)
							local source = self.data
							local ok, reason
							if UFProfiles and UFProfiles.CopyToActive then
								ok, reason = UFProfiles.CopyToActive(source)
							end
							if not ok then
								printUFProfileError(reason)
								return
							end
							local msg = (L["UFProfileCopySuccess"] or 'Copied Unit Frames settings from "%s".'):format(source or "")
							print("|cff00ff98Enhance QoL|r: " .. msg)
						end,
					}
				StaticPopupDialogs["EQOL_UF_PROFILE_COPY"].text = (L["UFProfileCopyConfirm"] or 'Copy settings from "%s" to your active Unit Frames profile?'):format(value)
				StaticPopup_Show("EQOL_UF_PROFILE_COPY", nil, nil, value)
			end,
			default = "",
			parentSection = expandableProfile,
		})

		addon.functions.SettingsCreateDropdown(profilesCategory, {
			var = "ufProfileDelete",
			text = L["Delete profile"] or (L["Delete profile"] or "Delete profile"),
			listFunc = function()
				local active = getActiveUFProfile()
				local globalProfile = getGlobalUFProfile()
				return buildProfileList(profileOrderDelete, function(name) return name == active or name == globalProfile end, true)
			end,
			order = profileOrderDelete,
			get = function() return "" end,
			set = function(value)
				if value == "" then return end
				StaticPopupDialogs["EQOL_UF_PROFILE_DELETE"] = StaticPopupDialogs["EQOL_UF_PROFILE_DELETE"]
					or {
						text = "",
						button1 = YES,
						button2 = CANCEL,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
						OnAccept = function(self)
							local profileName = self.data
							local ok, reason
							if UFProfiles and UFProfiles.Delete then
								ok, reason = UFProfiles.Delete(profileName)
							end
							if not ok then
								printUFProfileError(reason)
								return
							end
							local msg = (L["UFProfileDeleteSuccess"] or 'Deleted Unit Frames profile "%s".'):format(profileName or "")
							print("|cff00ff98Enhance QoL|r: " .. msg)
						end,
					}
				StaticPopupDialogs["EQOL_UF_PROFILE_DELETE"].text = (L["UFProfileDeleteConfirm"] or 'Delete Unit Frames profile "%s"?'):format(value)
				StaticPopup_Show("EQOL_UF_PROFILE_DELETE", nil, nil, value)
			end,
			default = "",
			parentSection = expandableProfile,
		})

		addon.functions.SettingsCreateButton(profilesCategory, {
			var = "ufProfileCreate",
			text = L["UFProfileAdd"] or (L["ProfileName"] or "Add a new profile"),
			func = function()
				StaticPopupDialogs["EQOL_UF_PROFILE_CREATE"] = StaticPopupDialogs["EQOL_UF_PROFILE_CREATE"]
					or {
						text = L["UFProfileCreatePrompt"] or "Enter a name for the new Unit Frames profile.",
						hasEditBox = true,
						button1 = OKAY,
						button2 = CANCEL,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
						OnShow = function(self)
							local editBox = self.editBox or self:GetEditBox()
							editBox:SetText("")
							editBox:SetFocus()
							editBox:HighlightText()
						end,
						EditBoxOnEnterPressed = function(editBox)
							local parent = editBox:GetParent()
							if parent and parent.button1 then parent.button1:Click() end
						end,
						OnAccept = function(self)
							local editBox = self.editBox or self:GetEditBox()
							local name = editBox:GetText() or ""
							local ok, reason
							if UFProfiles and UFProfiles.Create then
								ok, reason = UFProfiles.Create(name)
							end
							if not ok then
								printUFProfileError(reason)
								return
							end
							print("|cff00ff98Enhance QoL|r: " .. tostring(L["UFProfileCreateSuccess"] or "Unit Frames profile created."))
						end,
					}
				StaticPopup_Show("EQOL_UF_PROFILE_CREATE")
			end,
			parentSection = expandableProfile,
		})

		addon.functions.SettingsCreateHeadline(profilesCategory, L["UFProfileSpecMappingHeader"] or "Specialization profile mapping", { parentSection = expandableProfile })

		local specDropdownOrders = {}
		local classID = addon.variables and addon.variables.unitClassID
		if not classID then
			local _, _, id = UnitClass("player")
			classID = id
		end
		classID = tonumber(classID)
		if classID and classID > 0 and C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID and GetSpecializationInfoForClassID then
			local specCount = C_SpecializationInfo.GetNumSpecializationsForClassID(classID)
			for specIndex = 1, (specCount or 0) do
				local specID, specName = GetSpecializationInfoForClassID(classID, specIndex)
				if specID and specName then
					specDropdownOrders[specID] = {}
					addon.functions.SettingsCreateDropdown(profilesCategory, {
						var = string.format("ufProfileSpecMap_%d", specID),
						text = (L["UFProfileSpecMapping"] or "%s profile"):format(specName),
						listFunc = function()
							local order = specDropdownOrders[specID]
							return buildProfileList(order, nil, true, noOverrideLabel)
						end,
						order = specDropdownOrders[specID],
						get = function()
							local mapped = UFProfiles and UFProfiles.GetSpecMapping and UFProfiles.GetSpecMapping(specID)
							if not mapped or mapped == "" then return "" end
							return mapped
						end,
						set = function(value)
							local target = value
							if target == "" then target = nil end
							local ok, reason
							if UFProfiles and UFProfiles.SetSpecMapping then
								ok, reason = UFProfiles.SetSpecMapping(specID, target)
							end
							if not ok then
								local msg = L["UFProfileSpecMapFailed"] or "Could not update specialization profile mapping."
								if reason == "NOT_FOUND" then msg = L["UFProfileSetActiveMissing"] or "That Unit Frames profile does not exist." end
								print("|cff00ff98Enhance QoL|r: " .. tostring(msg))
							end
						end,
						default = "",
						parentSection = expandableProfile,
					})
				end
			end
		end

		addon.functions.SettingsCreateHeadline(profilesCategory, L["Export / Import"] or "Export / Import", { parentSection = expandableProfile })

		addon.functions.SettingsCreateDropdown(profilesCategory, {
			var = "ufProfileScope",
			text = L["ProfileScope"] or (L["Apply to"] or "Apply to"),
			list = scopeOptions,
			order = scopeOrder,
			get = getScope,
			set = setScope,
			default = "ALL",
			parentSection = expandableProfile,
		})

		addon.functions.SettingsCreateButton(profilesCategory, {
			var = "ufExportProfile",
			text = L["Export"] or "Export",
			func = function()
				local scopeKey = getScope()
				local code
				local reason
				if UF.ExportProfile then
					code, reason = UF.ExportProfile(scopeKey)
				end
				if not code then
					local msg = (UF.ExportErrorMessage and UF.ExportErrorMessage(reason)) or (L["UFExportProfileFailed"] or "Export failed.")
					print("|cff00ff98Enhance QoL|r: " .. tostring(msg))
					return
				end
				StaticPopupDialogs["EQOL_UF_EXPORT_SETTINGS"] = StaticPopupDialogs["EQOL_UF_EXPORT_SETTINGS"]
					or {
						text = L["UFExportProfileTitle"] or "Export Unit Frames",
						button1 = CLOSE,
						hasEditBox = true,
						editBoxWidth = 320,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
				StaticPopupDialogs["EQOL_UF_EXPORT_SETTINGS"].text = L["UFExportProfileTitle"] or "Export Unit Frames"
				StaticPopupDialogs["EQOL_UF_EXPORT_SETTINGS"].OnShow = function(self)
					self:SetFrameStrata("TOOLTIP")
					local editBox = self.editBox or self:GetEditBox()
					editBox:SetText(code)
					editBox:HighlightText()
					editBox:SetFocus()
				end
				StaticPopup_Show("EQOL_UF_EXPORT_SETTINGS")
			end,
			parentSection = expandableProfile,
		})

		addon.functions.SettingsCreateButton(profilesCategory, {
			var = "ufImportProfile",
			text = L["Import"] or "Import",
			func = function()
				local importText = (L["UFImportProfileTitle"] or "Import Unit Frames")
				if L["UFImportProfileReloadHint"] then importText = importText .. "\n\n" .. L["UFImportProfileReloadHint"] end
				StaticPopupDialogs["EQOL_UF_IMPORT_SETTINGS"] = StaticPopupDialogs["EQOL_UF_IMPORT_SETTINGS"]
					or {
						text = importText,
						button1 = OKAY,
						button2 = CANCEL,
						hasEditBox = true,
						editBoxWidth = 320,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
				StaticPopupDialogs["EQOL_UF_IMPORT_SETTINGS"].text = importText
				StaticPopupDialogs["EQOL_UF_IMPORT_SETTINGS"].OnShow = function(self)
					self:SetFrameStrata("TOOLTIP")
					local editBox = self.editBox or self:GetEditBox()
					editBox:SetText("")
					editBox:SetFocus()
				end
				StaticPopupDialogs["EQOL_UF_IMPORT_SETTINGS"].EditBoxOnEnterPressed = function(editBox)
					local parent = editBox:GetParent()
					if parent and parent.button1 then parent.button1:Click() end
				end
				StaticPopupDialogs["EQOL_UF_IMPORT_SETTINGS"].OnAccept = function(self)
					local editBox = self.editBox or self:GetEditBox()
					local input = editBox:GetText() or ""
					local scopeKey = getScope()
					local ok, applied = false, nil
					if UF.ImportProfile then
						ok, applied = UF.ImportProfile(input, scopeKey)
					end
					if not ok then
						local msg = UF.ImportErrorMessage and UF.ImportErrorMessage(applied) or (L["UFImportProfileFailed"] or "Import failed.")
						print("|cff00ff98Enhance QoL|r: " .. tostring(msg))
						return
					end
					if applied and #applied > 0 then
						local names = {}
						for _, key in ipairs(applied) do
							names[#names + 1] = scopeOptions[key] or key
						end
						local label = table.concat(names, ", ")
						local msg = (L["UFImportProfileSuccess"] or "Unit Frames updated for: %s"):format(label)
						print("|cff00ff98Enhance QoL|r: " .. msg)
					else
						local msg = L["UFImportProfileSuccessGeneric"] or "Unit Frame profile imported."
						print("|cff00ff98Enhance QoL|r: " .. msg)
					end
					if ReloadUI then ReloadUI() end
				end
				StaticPopup_Show("EQOL_UF_IMPORT_SETTINGS")
			end,
			parentSection = expandableProfile,
		})
	end

	UF.SettingsRegistered = true
end

function UF.RegisterSettings()
	if not addon.db then return end
	registerSettingsUI()
	registerStandaloneCastbarEditModeSettings()
	if UF.IsEditModeLayoutReady() then
		registerEditModeFrames()
		return
	end
	if UF._pendingEditModeRegister then return end
	UF._pendingEditModeRegister = true
	local waiter = CreateFrame("Frame")
	waiter:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
	waiter:RegisterEvent("PLAYER_LOGIN")
	waiter:SetScript("OnEvent", function()
		if not UF.IsEditModeLayoutReady() then return end
		registerEditModeFrames()
		UF._pendingEditModeRegister = nil
		waiter:UnregisterAllEvents()
		waiter:SetScript("OnEvent", nil)
	end)
end
