local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}
addon.Aura.UF = addon.Aura.UF or {}
local UF = addon.Aura.UF
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

UF.GroupFramesHealerBuffs = UF.GroupFramesHealerBuffs or {}
local HB = UF.GroupFramesHealerBuffs

local GF = UF.GroupFrames
local GFH = UF.GroupFramesHelper
local AuraUtil = UF.AuraUtil
local UFHelper = addon.Aura.UFHelper
local Pixel = GFH and GFH.Pixel

local floor = math.floor
local max = math.max
local min = math.min
local abs = math.abs
local sin = math.sin
local pi = math.pi
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local next = next
local tinsert = table.insert
local sort = table.sort
local format = string.format
local wipe = _G.wipe or (table and table.wipe)
local issecretvalue = _G.issecretvalue
local UnitIsUnit = _G.UnitIsUnit
local UnitExists = _G.UnitExists
local UnitIsPlayer = _G.UnitIsPlayer

local EMPTY = {}

local STYLE_ICON = "ICON"
local STYLE_SQUARE = "SQUARE"
local STYLE_BAR = "BAR"
local STYLE_BORDER = "BORDER"
local STYLE_TINT = "TINT"

local STYLE_SET = {
	[STYLE_ICON] = true,
	[STYLE_SQUARE] = true,
	[STYLE_BAR] = true,
	[STYLE_BORDER] = true,
	[STYLE_TINT] = true,
}

local ORIENT_HORIZONTAL = "HORIZONTAL"
local ORIENT_VERTICAL = "VERTICAL"

local RULE_MATCH_ANY = "ANY"
local RULE_MATCH_ALL = "ALL"
local ICON_MODE_ALL = "ALL"
local ICON_MODE_PRIORITY = "PRIORITY"
local ICON_LAYOUT_MODE_MAX = "MAX"
local ICON_LAYOUT_MODE_FIXED_SORT = "FIXED_SORT"
local KIND_PARTY = "party"
local KIND_RAID = "raid"

local ORIENTATION_SET = {
	[ORIENT_HORIZONTAL] = true,
	[ORIENT_VERTICAL] = true,
}

local BAR_SIZE_MAX = 512

local RULE_MATCH_SET = {
	[RULE_MATCH_ANY] = true,
	[RULE_MATCH_ALL] = true,
}

local ICON_MODE_SET = {
	[ICON_MODE_ALL] = true,
	[ICON_MODE_PRIORITY] = true,
}

local DURATION_COLOR_STEP_MAX = 3

local KIND_SET = {
	[KIND_PARTY] = true,
	[KIND_RAID] = true,
	target = true,
	focus = true,
	boss = true,
}

local FRAME_STRATA_SET = {
	BACKGROUND = true,
	LOW = true,
	MEDIUM = true,
	HIGH = true,
	DIALOG = true,
	FULLSCREEN = true,
	FULLSCREEN_DIALOG = true,
	TOOLTIP = true,
}

local ANCHOR_SET = {
	TOPLEFT = true,
	TOP = true,
	TOPRIGHT = true,
	LEFT = true,
	CENTER = true,
	RIGHT = true,
	BOTTOMLEFT = true,
	BOTTOM = true,
	BOTTOMRIGHT = true,
}

local GROWTH_DIRS = {
	UPRIGHT = true,
	UPLEFT = true,
	RIGHTUP = true,
	RIGHTDOWN = true,
	LEFTUP = true,
	LEFTDOWN = true,
	DOWNLEFT = true,
	DOWNRIGHT = true,
}

local GROWTH_AXES = {
	UPRIGHT = { "UP", "RIGHT" },
	UPLEFT = { "UP", "LEFT" },
	RIGHTUP = { "RIGHT", "UP" },
	RIGHTDOWN = { "RIGHT", "DOWN" },
	LEFTUP = { "LEFT", "UP" },
	LEFTDOWN = { "LEFT", "DOWN" },
	DOWNLEFT = { "DOWN", "LEFT" },
	DOWNRIGHT = { "DOWN", "RIGHT" },
}

local function tr(key, fallback)
	local value = L and L[key]
	if value == nil or value == "" then return fallback or key end
	return value
end

HB.STYLE_OPTIONS = {
	{ value = STYLE_ICON, label = tr("Icon", "Icon") },
	{ value = STYLE_SQUARE, label = tr("Square", "Square") },
	{ value = STYLE_BAR, label = tr("Bar", "Bar") },
	{ value = STYLE_BORDER, label = tr("Border", "Border") },
	{ value = STYLE_TINT, label = tr("UFGroupHealerBuffStyleTint", "Tint") },
}

HB.ORIENTATION_OPTIONS = {
	{ value = ORIENT_HORIZONTAL, label = tr("Horizontal", "Horizontal") },
	{ value = ORIENT_VERTICAL, label = tr("Vertical", "Vertical") },
}

HB.RULE_MATCH_OPTIONS = {
	{ value = RULE_MATCH_ANY, label = tr("UFGroupHealerBuffRuleMatchAny", "Require Any Spell") },
	{ value = RULE_MATCH_ALL, label = tr("UFGroupHealerBuffRuleMatchAll", "Require All Spells") },
}

HB.ICON_MODE_OPTIONS = {
	{ value = ICON_MODE_ALL, label = tr("UFGroupHealerBuffIconModeAll", "Show All Active Spells") },
	{ value = ICON_MODE_PRIORITY, label = tr("UFGroupHealerBuffIconModePriority", "Show Highest Priority Only") },
}

HB.ICON_LAYOUT_MODE_OPTIONS = {
	{ value = ICON_LAYOUT_MODE_MAX, label = tr("UFGroupHealerBuffIconLayoutModeMax", "Dynamic Maximum") },
	{ value = ICON_LAYOUT_MODE_FIXED_SORT, label = tr("UFGroupHealerBuffIconLayoutModeFixedSort", "Fixed Rule Order (Higher resource usage)") },
}

HB.ANCHOR_OPTIONS = GFH and GFH.anchorOptions9
	or {
		{ value = "TOPLEFT", label = tr("Top Left", "Top Left") },
		{ value = "TOP", label = tr("Top", "Top") },
		{ value = "TOPRIGHT", label = tr("Top Right", "Top Right") },
		{ value = "LEFT", label = tr("Left", "Left") },
		{ value = "CENTER", label = tr("Center", "Center") },
		{ value = "RIGHT", label = tr("Right", "Right") },
		{ value = "BOTTOMLEFT", label = tr("Bottom Left", "Bottom Left") },
		{ value = "BOTTOM", label = tr("Bottom", "Bottom") },
		{ value = "BOTTOMRIGHT", label = tr("Bottom Right", "Bottom Right") },
	}

HB.GROWTH_OPTIONS = GFH and GFH.auraGrowthOptions
	or {
		{ value = "UPRIGHT", label = tr("UFGroupHealerBuffGrowthUpRight", "Up Right") },
		{ value = "UPLEFT", label = tr("UFGroupHealerBuffGrowthUpLeft", "Up Left") },
		{ value = "RIGHTUP", label = tr("UFGroupHealerBuffGrowthRightUp", "Right Up") },
		{ value = "RIGHTDOWN", label = tr("UFGroupHealerBuffGrowthRightDown", "Right Down") },
		{ value = "LEFTUP", label = tr("UFGroupHealerBuffGrowthLeftUp", "Left Up") },
		{ value = "LEFTDOWN", label = tr("UFGroupHealerBuffGrowthLeftDown", "Left Down") },
		{ value = "DOWNLEFT", label = tr("UFGroupHealerBuffGrowthDownLeft", "Down Left") },
		{ value = "DOWNRIGHT", label = tr("UFGroupHealerBuffGrowthDownRight", "Down Right") },
	}

local FAMILY_DATA = {
	-- Player-applied class buffs
	{ id = "druid_mark_of_the_wild", classToken = "DRUID", spellIds = { 1126 }, fallbackName = "Mark of the Wild", ignoreForNpcUnits = true },
	{ id = "mage_arcane_intellect", classToken = "MAGE", spellIds = { 1459 }, fallbackName = "Arcane Intellect", ignoreForNpcUnits = true },
	{ id = "priest_power_word_fortitude", classToken = "PRIEST", spellIds = { 21562 }, fallbackName = "Power Word: Fortitude", ignoreForNpcUnits = true },
	{ id = "warrior_battle_shout", classToken = "WARRIOR", spellIds = { 6673 }, fallbackName = "Battle Shout", ignoreForNpcUnits = true },
	{
		id = "evoker_blessing_of_the_bronze",
		classToken = "EVOKER",
		ignoreForNpcUnits = true,
		spellIds = {
			381732,
			381741,
			381746,
			381748,
			381749,
			381750,
			381751,
			381752,
			381753,
			381754,
			381756,
			381757,
			381758,
		},
		fallbackName = "Blessing of the Bronze",
	},
	{ id = "shaman_skyfury", classToken = "SHAMAN", spellIds = { 462854 }, fallbackName = "Skyfury", ignoreForNpcUnits = true },

	-- Preservation Evoker
	{ id = "evoker_pres_dream_breath", classToken = "EVOKER", spec = "Preservation", spellIds = { 355941 }, fallbackName = "Dream Breath" },
	{ id = "evoker_pres_dream_flight", classToken = "EVOKER", spec = "Preservation", spellIds = { 363502 }, fallbackName = "Dream Flight" },
	{ id = "evoker_pres_echo", classToken = "EVOKER", spec = "Preservation", spellIds = { 364343 }, fallbackName = "Echo" },
	{ id = "evoker_pres_reversion", classToken = "EVOKER", spec = "Preservation", spellIds = { 366155 }, fallbackName = "Reversion" },
	{ id = "evoker_pres_echo_reversion", classToken = "EVOKER", spec = "Preservation", spellIds = { 367364 }, fallbackName = "Echo Reversion" },
	{ id = "evoker_pres_lifebind", classToken = "EVOKER", spec = "Preservation", spellIds = { 373267 }, fallbackName = "Lifebind" },
	{ id = "evoker_pres_echo_dream_breath", classToken = "EVOKER", spec = "Preservation", spellIds = { 376788 }, fallbackName = "Echo Dream Breath" },
	{ id = "evoker_pres_verdant_embrace", classToken = "EVOKER", spec = "Preservation", spellIds = { 409895 }, fallbackName = "Verdant Embrace" },
	-- Augmentation Evoker
	{ id = "evoker_aug_blistering_scales", classToken = "EVOKER", spec = "Augmentation", spellIds = { 360827 }, fallbackName = "Blistering Scales" },
	{ id = "evoker_aug_ebon_might", classToken = "EVOKER", spec = "Augmentation", spellIds = { 395152, 395296 }, fallbackName = "Ebon Might" },
	{ id = "evoker_aug_prescience", classToken = "EVOKER", spec = "Augmentation", spellIds = { 410089 }, fallbackName = "Prescience" },
	{ id = "evoker_aug_infernos_blessing", classToken = "EVOKER", spec = "Augmentation", spellIds = { 410263 }, fallbackName = "Inferno's Blessing" },
	{ id = "evoker_aug_symbiotic_bloom", classToken = "EVOKER", spec = "Augmentation", spellIds = { 410686 }, fallbackName = "Symbiotic Bloom" },
	{ id = "evoker_aug_shifting_sands", classToken = "EVOKER", spec = "Augmentation", spellIds = { 413984 }, fallbackName = "Shifting Sands" },
	-- Restoration Druid
	{ id = "druid_rejuvenation", classToken = "DRUID", spec = "Restoration", spellIds = { 774 }, fallbackName = "Rejuvenation" },
	{ id = "druid_regrowth", classToken = "DRUID", spec = "Restoration", spellIds = { 8936 }, fallbackName = "Regrowth" },
	{ id = "druid_lifebloom", classToken = "DRUID", spec = "Restoration", spellIds = { 33763 }, fallbackName = "Lifebloom" },
	{ id = "druid_wild_growth", classToken = "DRUID", spec = "Restoration", spellIds = { 48438 }, fallbackName = "Wild Growth" },
	{ id = "druid_germination", classToken = "DRUID", spec = "Restoration", spellIds = { 155777 }, fallbackName = "Germination" },
	{ id = "druid_symbiotic_blooms", classToken = "DRUID", spec = "Restoration", spellIds = { 439530 }, fallbackName = "Symbiotic Blooms" },
	-- Priest
	{ id = "priest_pw_shield", classToken = "PRIEST", specs = { "Discipline", "Holy" }, spellIds = { 1300008, 17 }, fallbackName = "Power Word: Shield" },
	{ id = "priest_atonement", classToken = "PRIEST", spec = "Discipline", spellIds = { 194384 }, fallbackName = "Atonement" },
	{ id = "priest_void_shield", classToken = "PRIEST", spec = "Discipline", spellIds = { 1253593, 1300009 }, fallbackName = "Void Shield" },
	{ id = "priest_renew", classToken = "PRIEST", specs = { "Discipline", "Holy" }, spellIds = { 139 }, fallbackName = "Renew" },
	{ id = "priest_prayer_of_mending", classToken = "PRIEST", specs = { "Discipline", "Holy" }, spellIds = { 41635 }, fallbackName = "Prayer of Mending" },
	{ id = "priest_echo_of_light", classToken = "PRIEST", spec = "Holy", spellIds = { 77489 }, fallbackName = "Echo of Light" },
	-- Mistweaver Monk
	{ id = "monk_soothing_mist", classToken = "MONK", spec = "Mistweaver", spellIds = { 115175 }, fallbackName = "Soothing Mist" },
	{ id = "monk_renewing_mist", classToken = "MONK", spec = "Mistweaver", spellIds = { 119611 }, fallbackName = "Renewing Mist" },
	{ id = "monk_enveloping_mist", classToken = "MONK", spec = "Mistweaver", spellIds = { 124682 }, fallbackName = "Enveloping Mist" },
	{ id = "monk_aspect_of_harmony", classToken = "MONK", spec = "Mistweaver", spellIds = { 450769 }, fallbackName = "Aspect of Harmony" },
	{ id = "monk_coalescence", classToken = "MONK", spec = "Mistweaver", spellIds = { 1292922 }, fallbackName = "Coalescence", fallbackIcon = 1360977 },
	-- Restoration Shaman
	{ id = "shaman_earth_shield", classToken = "SHAMAN", spec = "Restoration", spellIds = { 974, 383648 }, fallbackName = "Earth Shield" },
	{ id = "shaman_riptide", classToken = "SHAMAN", spec = "Restoration", spellIds = { 61295 }, fallbackName = "Riptide" },
	{ id = "shaman_ancestral_vigor", classToken = "SHAMAN", spec = "Restoration", spellIds = { 207400 }, fallbackName = "Ancestral Vigor" },
	{ id = "shaman_earthliving_weapon", classToken = "SHAMAN", spec = "Restoration", spellIds = { 382024 }, fallbackName = "Earthliving Weapon" },
	{ id = "shaman_hydrobubble", classToken = "SHAMAN", spec = "Restoration", spellIds = { 444490 }, fallbackName = "Hydrobubble" },
	-- Holy Paladin
	{
		id = "paladin_beacon_of_light",
		classToken = "PALADIN",
		spec = "Holy",
		spellIds = { 53563 },
		knownSpellIds = { 53563 },
		overrideBaseSpellId = 53563,
		requiredOverrideSpellId = 53563,
		fallbackName = "Beacon of Light",
	},
	{ id = "paladin_eternal_flame", classToken = "PALADIN", spec = "Holy", spellIds = { 156322 }, knownSpellIds = { 156322 }, fallbackName = "Eternal Flame" },
	{ id = "paladin_dawnlight", classToken = "PALADIN", spec = "Holy", spellIds = { 431381 }, fallbackName = "Dawnlight" },
	{ id = "paladin_beacon_of_faith", classToken = "PALADIN", spec = "Holy", spellIds = { 156910 }, knownSpellIds = { 156910 }, fallbackName = "Beacon of Faith" },
	{ id = "paladin_beacon_of_the_savior", classToken = "PALADIN", spec = "Holy", spellIds = { 1244893 }, fallbackName = "Beacon of the Savior" },
	{
		id = "paladin_beacon_of_virtue",
		classToken = "PALADIN",
		spec = "Holy",
		spellIds = { 200025 },
		overrideBaseSpellId = 53563,
		requiredOverrideSpellId = 200025,
		fallbackName = "Beacon of Virtue",
	},
}

local FAMILY_BY_ID = {}
local FAMILY_ORDER = {}
local SPELL_TO_FAMILY = {}

for _, family in ipairs(FAMILY_DATA) do
	family.spellIds = family.spellIds or {}
	FAMILY_BY_ID[family.id] = family
	FAMILY_ORDER[#FAMILY_ORDER + 1] = family.id
	for i = 1, #family.spellIds do
		SPELL_TO_FAMILY[tonumber(family.spellIds[i])] = family.id
	end
end

HB.FAMILY_BY_ID = FAMILY_BY_ID
HB.FAMILY_ORDER = FAMILY_ORDER
HB.SPELL_TO_FAMILY = SPELL_TO_FAMILY
HB.CUSTOM_SPELL_FAMILY_PREFIX = "spell:"
HB._configuredCustomSpellToFamily = HB._configuredCustomSpellToFamily or {}

function HB.GetCustomSpellFamilyId(value)
	local prefix = HB.CUSTOM_SPELL_FAMILY_PREFIX
	if type(value) ~= "string" or value:sub(1, #prefix) ~= prefix then return nil, nil end
	local spellId = tonumber(value:sub(#prefix + 1))
	if not spellId or spellId <= 0 or spellId ~= floor(spellId) then return nil, nil end
	return prefix .. tostring(spellId), spellId
end

function HB.CreateCustomSpellFamily(familyId, spellId)
	return {
		id = familyId,
		spellIds = { spellId },
		fallbackName = "Spell " .. tostring(spellId),
		isCustomSpell = true,
		customSpellId = spellId,
	}
end

function HB.ResolveFamily(familyId, source)
	if familyId == nil then return nil end
	familyId = tostring(familyId)
	local familiesById = source and source.familiesById
	local family = (familiesById and familiesById[familyId]) or FAMILY_BY_ID[familyId]
	if family then return family end
	local canonicalId, spellId = HB.GetCustomSpellFamilyId(familyId)
	if not canonicalId then return nil end
	if familiesById and familiesById[canonicalId] then return familiesById[canonicalId] end
	return HB.CreateCustomSpellFamily(canonicalId, spellId)
end

local PROVIDER_SPEC_IDS = {
	DRUID = { Restoration = 105 },
	EVOKER = { Preservation = 1468, Augmentation = 1473 },
	MONK = { Mistweaver = 270 },
	PALADIN = { Holy = 65 },
	PRIEST = { Discipline = 256, Holy = 257 },
	SHAMAN = { Restoration = 264 },
}

local PROVIDER_CLASS_IGNORES_SPEC = {}

local function getPlayerClassToken()
	local classToken = addon.variables and addon.variables.unitClass
	if type(classToken) == "string" and classToken ~= "" then return classToken end
	if UnitClass then
		local _, token = UnitClass("player")
		if type(token) == "string" and token ~= "" then return token end
	end
	return nil
end

local function getPlayerSpecId()
	local sid = addon.variables and addon.variables.unitSpecId
	sid = tonumber(sid)
	if sid and sid > 0 then return sid end

	local specIndex = nil
	if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then specIndex = C_SpecializationInfo.GetSpecialization() end
	if not specIndex then return nil end

	if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
		local info = C_SpecializationInfo.GetSpecializationInfo(specIndex)
		if type(info) == "table" then
			sid = tonumber(info.specID or info.id)
		else
			sid = tonumber(info)
		end
		if sid and sid > 0 then return sid end
	end

	if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
		sid = tonumber(C_SpecializationInfo.GetSpecializationInfo(specIndex))
		if sid and sid > 0 then return sid end
	end

	return nil
end

local function familyMatchesPlayerSpec(family, classSpecMap, playerSpecId)
	local familySpec = family and family.spec and tostring(family.spec) or nil
	if familySpec and familySpec ~= "" then
		local requiredSpecId = classSpecMap and classSpecMap[familySpec] or nil
		return requiredSpecId == nil or playerSpecId == requiredSpecId
	end

	local familySpecs = family and family.specs
	if type(familySpecs) == "table" then
		for i = 1, #familySpecs do
			local requiredSpecName = tostring(familySpecs[i] or "")
			local requiredSpecId = classSpecMap and classSpecMap[requiredSpecName] or nil
			if requiredSpecId and playerSpecId == requiredSpecId then return true end
		end
		return false
	end

	return true
end

function HB.IsPlayerFamilyAvailable(family)
	if type(family) ~= "table" then return false end

	local knownSpellIds = family.knownSpellIds
	local playerSpellBank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
	if type(knownSpellIds) == "table" and #knownSpellIds > 0 and playerSpellBank ~= nil
		and C_SpellBook and type(C_SpellBook.IsSpellKnownOrInSpellBook) == "function" then
		local hasKnownSpell = false
		for i = 1, #knownSpellIds do
			local spellId = tonumber(knownSpellIds[i])
			if spellId and spellId > 0 then
				local known = C_SpellBook.IsSpellKnownOrInSpellBook(spellId, playerSpellBank, true)
				if not (issecretvalue and issecretvalue(known)) and known == true then
					hasKnownSpell = true
					break
				end
			end
		end
		if not hasKnownSpell then return false end
	end

	local requiredOverrideSpellId = tonumber(family.requiredOverrideSpellId)
	local overrideBaseSpellId = tonumber(family.overrideBaseSpellId)
	if requiredOverrideSpellId and requiredOverrideSpellId > 0 and overrideBaseSpellId and overrideBaseSpellId > 0
		and C_Spell and type(C_Spell.GetOverrideSpell) == "function" then
		local overrideSpellId = C_Spell.GetOverrideSpell(overrideBaseSpellId, 0, true)
		if not (issecretvalue and issecretvalue(overrideSpellId)) then
			overrideSpellId = tonumber(overrideSpellId)
			if overrideSpellId ~= requiredOverrideSpellId then return false end
		end
	end

	return true
end

local function canPlayerProvideFamily(familyId, source)
	local family = HB.ResolveFamily(familyId, source)
	if not family then return false end

	local familyClass = family.classToken and tostring(family.classToken) or nil
	if familyClass then
		local playerClass = getPlayerClassToken()
		if not playerClass or tostring(playerClass) ~= familyClass then return false end
	end

	if not PROVIDER_CLASS_IGNORES_SPEC[familyClass] then
		local classSpecMap = familyClass and PROVIDER_SPEC_IDS[familyClass] or nil
		local playerSpecId = getPlayerSpecId()
		if not familyMatchesPlayerSpec(family, classSpecMap, playerSpecId) then return false end
	end

	return HB.IsPlayerFamilyAvailable(family)
end

local _playerFamilyProvisionCache = {
	key = nil,
	map = nil,
}

function HB.InvalidatePlayerFamilyProvisionCache()
	_playerFamilyProvisionCache.key = nil
	_playerFamilyProvisionCache.map = nil
end

local function getPlayerFamilyProvisionMap()
	local classToken = addon.variables and addon.variables.unitClass
	if type(classToken) == "string" and classToken == "" then classToken = nil end
	if classToken == nil and UnitClass then
		local _, token = UnitClass("player")
		if type(token) == "string" and token ~= "" then classToken = token end
	end
	local specId = addon.variables and addon.variables.unitSpecId
	specId = tonumber(specId)
	if specId == nil or specId <= 0 then specId = getPlayerSpecId() end
	specId = tonumber(specId) or 0

	local cacheKey = tostring(classToken or "") .. "|" .. tostring(specId)
	if _playerFamilyProvisionCache.key == cacheKey and _playerFamilyProvisionCache.map ~= nil then return _playerFamilyProvisionCache.map end

	local map = {}
	local specMap = classToken and PROVIDER_SPEC_IDS[classToken] or nil
	for familyId, family in pairs(FAMILY_BY_ID) do
		if family and family.classToken then
			local familyIdKey = tostring(familyId)
			if tostring(family.classToken) ~= classToken then
				map[familyIdKey] = false
			elseif PROVIDER_CLASS_IGNORES_SPEC[classToken] then
				map[familyIdKey] = HB.IsPlayerFamilyAvailable(family)
			else
				map[familyIdKey] = familyMatchesPlayerSpec(family, specMap, specId) and HB.IsPlayerFamilyAvailable(family)
			end
		end
	end
	_playerFamilyProvisionCache.key = cacheKey
	_playerFamilyProvisionCache.map = map
	return map
end

local function canPlayerProvideFamilyCached(familyId, source)
	local family = HB.ResolveFamily(familyId, source)
	if family == nil or family.classToken == nil then return canPlayerProvideFamily(familyId, source) end
	local map = getPlayerFamilyProvisionMap()
	if map == nil then return false end
	return map[tostring(familyId)] == true
end

HB.CanPlayerProvideFamily = canPlayerProvideFamilyCached

local function wipeTable(tbl)
	if not tbl then return end
	if wipe then
		wipe(tbl)
	else
		for key in pairs(tbl) do
			tbl[key] = nil
		end
	end
end

local function copyTable(src)
	if type(src) ~= "table" then return src end
	if addon.functions and addon.functions.copyTable then return addon.functions.copyTable(src) end
	if CopyTable then return CopyTable(src) end
	local out = {}
	for key, value in pairs(src) do
		if type(value) == "table" then
			out[key] = copyTable(value)
		else
			out[key] = value
		end
	end
	return out
end

local function clamp(value, minValue, maxValue, fallback)
	local n = tonumber(value)
	if n == nil then n = fallback end
	if n == nil then return nil end
	if minValue ~= nil and n < minValue then n = minValue end
	if maxValue ~= nil and n > maxValue then n = maxValue end
	return n
end

local function roundInt(value)
	local n = tonumber(value) or 0
	if n >= 0 then return floor(n + 0.5) end
	return -floor(abs(n) + 0.5)
end

local function normalizeStyle(value)
	local style = tostring(value or STYLE_ICON):upper()
	if STYLE_SET[style] then return style end
	return STYLE_ICON
end

local function normalizeOrientation(value)
	local orient = tostring(value or ORIENT_HORIZONTAL):upper()
	if ORIENTATION_SET[orient] then return orient end
	return ORIENT_HORIZONTAL
end

local function normalizeBarReverseFill(value) return value == true end

local function normalizeRuleMatch(value)
	local mode = tostring(value or RULE_MATCH_ANY):upper()
	if RULE_MATCH_SET[mode] then return mode end
	return RULE_MATCH_ANY
end

local function normalizeIconMode(value)
	local mode = tostring(value or ICON_MODE_ALL):upper()
	if ICON_MODE_SET[mode] then return mode end
	return ICON_MODE_ALL
end

local function normalizeIconLayoutMode(value)
	local mode = tostring(value or ICON_LAYOUT_MODE_MAX):upper()
	if mode == "FIXED" then mode = ICON_LAYOUT_MODE_FIXED_SORT end
	if mode == ICON_LAYOUT_MODE_MAX or mode == ICON_LAYOUT_MODE_FIXED_SORT then return mode end
	return ICON_LAYOUT_MODE_MAX
end

local function normalizeAnchor(value)
	local anchor = tostring(value or "CENTER"):upper()
	if ANCHOR_SET[anchor] then return anchor end
	return "CENTER"
end

local function normalizeFrameStrataToken(value)
	if GF and GF.NormalizeFrameStrataToken then return GF.NormalizeFrameStrataToken(value) end
	if type(value) ~= "string" or value == "" then return nil end
	local token = string.upper(value)
	if token == "DEFAULT" then return nil end
	if FRAME_STRATA_SET[token] then return token end
	return nil
end

local function parseGrowth(growth)
	if not growth then return nil end
	local raw = tostring(growth):upper():gsub("[%s_]+", "")
	if GROWTH_DIRS[raw] then return raw end
	local first, second = tostring(growth):upper():match("^(%a+)[_%s]+(%a+)$")
	if first and second then
		local combo = first .. second
		if GROWTH_DIRS[combo] then return combo end
	end
	return nil
end

local function normalizeGrowth(value)
	local growth = parseGrowth(value)
	if growth then return growth end
	return "RIGHTDOWN"
end

local function normalizeColor(value, fallback)
	local ref = fallback or { 1, 1, 1, 1 }
	local r, g, b, a
	if type(value) == "table" then
		r = value.r or value[1]
		g = value.g or value[2]
		b = value.b or value[3]
		a = value.a
		if a == nil then a = value[4] end
	end
	if r == nil then r = ref[1] or 1 end
	if g == nil then g = ref[2] or 1 end
	if b == nil then b = ref[3] or 1 end
	if a == nil then a = ref[4] end
	if a == nil then a = 1 end
	r = clamp(r, 0, 1, 1)
	g = clamp(g, 0, 1, 1)
	b = clamp(b, 0, 1, 1)
	a = clamp(a, 0, 1, 1)
	return { r, g, b, a }
end

local function normalizeOptionalColor(value)
	if value == nil then return nil end
	if type(value) ~= "table" then return nil end
	return normalizeColor(value, { 1, 1, 1, 1 })
end

local function normalizeDurationColorSteps(value)
	if type(value) ~= "table" then return nil end
	local steps = {}
	local hasStep = false
	for i = 1, DURATION_COLOR_STEP_MAX do
		local step = value[i]
		if type(step) == "table" and step.enabled == true then
			local seconds = roundInt(clamp(step.seconds or step.threshold, 1, 3600, nil))
			local color = normalizeOptionalColor(step.color)
			if seconds and color then
				hasStep = true
				steps[i] = {
					enabled = true,
					seconds = seconds,
					color = color,
				}
			end
		end
	end
	if not hasStep then return nil end
	return steps
end

local function normalizeKind(kind)
	kind = tostring(kind or KIND_PARTY):lower()
	if kind == "mt" or kind == "ma" then return KIND_RAID end
	if KIND_SET[kind] then return kind end
	return kind
end

local function normalizeOrder(order, map)
	local result = {}
	local seen = {}
	if type(order) == "table" then
		for i = 1, #order do
			local id = order[i]
			if id ~= nil then
				id = tostring(id)
				if map[id] and not seen[id] then
					seen[id] = true
					result[#result + 1] = id
				end
			end
		end
	end
	local missing = {}
	for id in pairs(map) do
		if not seen[id] then missing[#missing + 1] = id end
	end
	sort(missing, function(a, b)
		local na = tonumber(a)
		local nb = tonumber(b)
		if na and nb then return na < nb end
		if na then return true end
		if nb then return false end
		return tostring(a) < tostring(b)
	end)
	for i = 1, #missing do
		result[#result + 1] = missing[i]
	end
	return result
end

local function getSpellName(spellId)
	if spellId == nil then return nil end
	if C_Spell and C_Spell.GetSpellName then
		local name = C_Spell.GetSpellName(spellId)
		if type(name) == "string" and name ~= "" then return name end
	end
	if GetSpellInfo then
		local name = GetSpellInfo(spellId)
		if type(name) == "string" and name ~= "" then return name end
	end
	return nil
end

local function getSpellTexture(spellId)
	if spellId == nil then return nil end
	if C_Spell and C_Spell.GetSpellTexture then
		local texture = C_Spell.GetSpellTexture(spellId)
		if texture then return texture end
	end
	if GetSpellTexture then
		local texture = GetSpellTexture(spellId)
		if texture then return texture end
	end
	return nil
end

local function ensureFamilyPresentation(family)
	if not family then return nil, nil end
	if not family._resolvedName then family._resolvedName = getSpellName(family.spellIds and family.spellIds[1]) or family.fallbackName or family.id end
	if not family._resolvedIcon then family._resolvedIcon = getSpellTexture(family.spellIds and family.spellIds[1]) or family.fallbackIcon or 134400 end
	return family._resolvedName, family._resolvedIcon
end

local function buildFamilyLabel(family)
	if not family then return "" end
	local name = ensureFamilyPresentation(family)
	local classToken = family.classToken or ""
	local spec = family.spec
	if spec and spec ~= "" then return spec .. " " .. classToken .. " - " .. tostring(name) end
	if classToken ~= "" then return classToken .. " - " .. tostring(name) end
	return tostring(name)
end

function HB.GetFamilyOptions(classFilter)
	local list = {}
	for i = 1, #FAMILY_ORDER do
		local family = FAMILY_BY_ID[FAMILY_ORDER[i]]
		if family then
			if classFilter == nil or classFilter == "" or classFilter == family.classToken then
				local _, icon = ensureFamilyPresentation(family)
				list[#list + 1] = {
					value = family.id,
					label = buildFamilyLabel(family),
					icon = icon,
					classToken = family.classToken,
					spec = family.spec,
					spellIds = family.spellIds,
				}
			end
		end
	end
	return list
end

function HB.GetFamilyById(id, source)
	if id == nil then return nil end
	local family = HB.ResolveFamily(id, source)
	if family then ensureFamilyPresentation(family) end
	return family
end

function HB.GetFamilyFromSpell(spellId, source)
	if spellId == nil then return nil end
	if issecretvalue and issecretvalue(spellId) then return nil end
	local spellToFamily = source and source.spellToFamily or SPELL_TO_FAMILY
	spellId = tonumber(spellId)
	local familyId = spellToFamily[spellId]
	if familyId ~= nil then return familyId end
	if source == nil then return HB._configuredCustomSpellToFamily[spellId] end
	return nil
end

local function getFamilyDefaultScanAllCasters(familyId, source)
	local family = HB.ResolveFamily(familyId, source)
	return family and family.scanAllCasters == true or false
end

function HB.GetFamilyScanAllCasters(familyId, source) return getFamilyDefaultScanAllCasters(familyId, source) end

function HB.GetRuleSpellIDs(rule, source)
	local family = rule and HB.ResolveFamily(rule.spellFamilyId, source) or nil
	if not (family and type(family.spellIds) == "table") then return nil end
	local spellIds = {}
	for i = 1, #family.spellIds do
		local spellId = tonumber(family.spellIds[i])
		if spellId and spellId > 0 and spellId == floor(spellId) then spellIds[#spellIds + 1] = spellId end
	end
	return spellIds
end

function HB.GetRuleAuraFilter(rule, source)
	if not rule then return nil end
	return HB.GetFamilyScanAllCasters(rule.spellFamilyId, source) and "HELPFUL" or "HELPFUL|PLAYER"
end

function HB.GetNativeSupportInfo(rule, source)
	local spellIds = HB.GetRuleSpellIDs(rule, source)
	local supported = rule ~= nil and rule.enabled ~= false and rule["not"] ~= true and spellIds ~= nil and #spellIds > 0
	return {
		supported = supported,
		reason = supported and nil or (rule and rule["not"] == true and "negativeRule" or "invalidRule"),
		filterString = spellIds and HB.GetRuleAuraFilter(rule, source) or nil,
		spellIDs = spellIds,
	}
end

HB.GetNativeRuleSupportInfo = HB.GetNativeSupportInfo

function HB.MarkPlacementDirty(cfgOrPlacement)
	if type(cfgOrPlacement) ~= "table" then return end
	local placement = cfgOrPlacement.healerBuffPlacement
	if type(placement) ~= "table" then placement = cfgOrPlacement end
	if type(placement) ~= "table" then return end
	placement._eqolDirty = true
	placement._eqolNormalized = nil
end

local function newPlacementConfig()
	return {
		enabled = false,
		version = 3,
		groupsById = {},
		groupOrder = {},
		rulesById = {},
		ruleOrder = {},
	}
end

function HB.CreateDefaultPlacement() return newPlacementConfig() end

local function getDefaultGroupName(id) return format(tr("UFGroupHealerBuffEditorIndicatorNameFormat", "Indicator %s"), tostring(id or "")) end

HB.GetDefaultGroupName = getDefaultGroupName

function HB.CreateDefaultGroup(id)
	id = tostring(id or "1")
	return {
		id = id,
		name = getDefaultGroupName(id),
		style = STYLE_ICON,
		anchorPoint = "CENTER",
		anchorOutside = false,
		x = 0,
		y = 0,
		growth = "RIGHTDOWN",
		perRow = 3,
		max = 3,
		spacing = 0,
		size = 16,
		barOrientation = ORIENT_HORIZONTAL,
		barThickness = 6,
		barAlpha = 0.9,
		barDrainAnimation = false,
		barFillFrame = false,
		barStrata = nil,
		barFrameLevelOffset = 3,
		barReverseFill = false,
		inset = 0,
		borderSize = 2,
		borderStrata = nil,
		borderFrameLevelModel = 2,
		borderFrameLevelOffset = 16,
		indicatorBorderEnabled = false,
		indicatorBorderTexture = "DEFAULT",
		indicatorBorderSize = 1,
		indicatorBorderOffset = 0,
		indicatorBorderColor = { 0, 0, 0, 0.95 },
		ruleMatch = RULE_MATCH_ANY,
		iconMode = ICON_MODE_ALL,
		iconLayoutMode = ICON_LAYOUT_MODE_MAX,
		showCooldown = true,
		showCooldownSwipe = true,
		showCooldownEdge = true,
		showCooldownBling = true,
		hideCooldownText = false,
		hideChargeText = false,
		color = { 1, 0.82, 0.1, 0.9 },
	}
end

function HB.CreateDefaultRule(id, familyId, groupId)
	id = tostring(id or "1")
	return {
		id = id,
		spellFamilyId = familyId,
		groupId = tostring(groupId or "1"),
		["not"] = false,
		desaturateMissing = false,
		expirationPulseEnabled = false,
		expirationPulseThreshold = 3,
		expirationPulseColor = { 1, 0.2, 0.2, 1 },
		expirationPulseCountdownOnly = false,
		enabled = true,
		appliesParty = true,
		appliesRaid = true,
		appliesTarget = true,
		appliesFocus = true,
		appliesBoss = true,
	}
end

local function normalizeGroup(group, id)
	if type(group) ~= "table" then return nil end
	group.id = tostring(group.id or id)
	if group.name == nil or group.name == "" then group.name = getDefaultGroupName(group.id) end
	group.style = normalizeStyle(group.style)
	group.anchorPoint = normalizeAnchor(group.anchorPoint)
	group.anchorOutside = group.anchorOutside == true
	group.x = roundInt(clamp(group.x, -300, 300, 0))
	group.y = roundInt(clamp(group.y, -300, 300, 0))
	group.growth = normalizeGrowth(group.growth)
	group.perRow = roundInt(clamp(group.perRow, 1, 20, 3))
	group.max = roundInt(clamp(group.max, 0, 40, 3))
	group.spacing = roundInt(clamp(group.spacing, 0, 40, 0))
	group.size = roundInt(clamp(group.size, 4, 96, 16))
	if addon.IconShape and addon.IconShape.NormalizeIconZoom then
		group.iconZoom = addon.IconShape.NormalizeIconZoom(group.iconZoom)
	else
		group.iconZoom = roundInt(clamp(group.iconZoom, 0, 35, 0))
	end
	group.barOrientation = normalizeOrientation(group.barOrientation)
	group.barThickness = roundInt(clamp(group.barThickness, 1, 96, 6))
	local barWidth = clamp(group.barWidth, 1, BAR_SIZE_MAX, nil)
	if barWidth ~= nil then barWidth = roundInt(barWidth) end
	group.barWidth = barWidth
	local barHeight = clamp(group.barHeight, 1, BAR_SIZE_MAX, nil)
	if barHeight ~= nil then barHeight = roundInt(barHeight) end
	group.barHeight = barHeight
	group.barAlpha = clamp(group.barAlpha, 0, 1, nil)
	group.barDrainAnimation = group.barDrainAnimation == true
	group.barFillFrame = group.barFillFrame == true
	group.barStrata = normalizeFrameStrataToken(group.barStrata)
	group.barFrameLevelOffset = roundInt(clamp(group.barFrameLevelOffset, -20, 1000, 3))
	group.barReverseFill = normalizeBarReverseFill(group.barReverseFill)
	group.inset = roundInt(clamp(group.inset, 0, 60, 0))
	group.borderSize = roundInt(clamp(group.borderSize, 1, 24, 2))
	group.borderStrata = normalizeFrameStrataToken(group.borderStrata)
	local storedBorderFrameLevelModel = rawget(group, "borderFrameLevelModel")
	local storedBorderFrameLevelOffset = tonumber(rawget(group, "borderFrameLevelOffset"))
	if storedBorderFrameLevelModel == 2 then
		group.borderFrameLevelOffset = roundInt(clamp(storedBorderFrameLevelOffset, -20, 1000, 16))
	elseif storedBorderFrameLevelOffset ~= nil then
		group.borderFrameLevelOffset = roundInt(clamp(storedBorderFrameLevelOffset, -20, 1000, 4) + 12)
	else
		group.borderFrameLevelOffset = 16
	end
	group.borderFrameLevelModel = 2
	local indicatorBorderEnabled = group.indicatorBorderEnabled
	if indicatorBorderEnabled == nil then indicatorBorderEnabled = group.iconBorderEnabled end
	group.indicatorBorderEnabled = indicatorBorderEnabled == true
	local indicatorBorderTexture = group.indicatorBorderTexture
	if indicatorBorderTexture == nil then indicatorBorderTexture = group.iconBorderTexture end
	indicatorBorderTexture = tostring(indicatorBorderTexture or "DEFAULT")
	if indicatorBorderTexture == "" then indicatorBorderTexture = "DEFAULT" end
	group.indicatorBorderTexture = indicatorBorderTexture
	group.indicatorBorderSize = roundInt(clamp(group.indicatorBorderSize or group.iconBorderSize, 1, 24, 1))
	group.indicatorBorderOffset = roundInt(clamp(group.indicatorBorderOffset or group.iconBorderOffset, -12, 12, 0))
	group.indicatorBorderColor = normalizeColor(group.indicatorBorderColor or group.iconBorderColor, { 0, 0, 0, 0.95 })
	group.ruleMatch = normalizeRuleMatch(group.ruleMatch or group.matchMode or group.ruleMode)
	group.iconMode = normalizeIconMode(group.iconMode or group.iconDisplayMode or group.iconRuleMode)
	group.iconLayoutMode = normalizeIconLayoutMode(group.iconLayoutMode or group.iconOrderMode)
	group.iconOrderMode = nil
	if group.showCooldown ~= nil then group.showCooldown = group.showCooldown ~= false end
	local showCooldownSwipe = group.showCooldownSwipe
	if showCooldownSwipe == nil then showCooldownSwipe = group.cooldownSwipe end
	group.showCooldownSwipe = showCooldownSwipe ~= false
	local showCooldownEdge = group.showCooldownEdge
	if showCooldownEdge == nil then showCooldownEdge = group.cooldownEdge end
	if showCooldownEdge == nil then showCooldownEdge = group.drawEdge end
	group.showCooldownEdge = showCooldownEdge ~= false
	local showCooldownBling = group.showCooldownBling
	if showCooldownBling == nil then showCooldownBling = group.cooldownBling end
	if showCooldownBling == nil then showCooldownBling = group.drawBling end
	group.showCooldownBling = showCooldownBling ~= false
	group.hideCooldownText = group.hideCooldownText == true
	if group.hideChargeText == nil then group.hideChargeText = group.hideStacks end
	group.hideChargeText = group.hideChargeText == true
	local cooldownTextSize = clamp(group.cooldownTextSize or group.cooldownSize or group.cooldownFontSizeOverride, 6, 64, nil)
	if cooldownTextSize ~= nil then cooldownTextSize = roundInt(cooldownTextSize) end
	group.cooldownTextSize = cooldownTextSize
	local chargeTextSize = clamp(group.chargeTextSize or group.chargeSize or group.countFontSizeOverride, 6, 64, nil)
	if chargeTextSize ~= nil then chargeTextSize = roundInt(chargeTextSize) end
	group.chargeTextSize = chargeTextSize
	group.matchMode = nil
	group.ruleMode = nil
	group.iconDisplayMode = nil
	group.iconRuleMode = nil
	group.cooldownSwipe = nil
	group.cooldownEdge = nil
	group.cooldownBling = nil
	group.drawEdge = nil
	group.drawBling = nil
	group.hideStacks = nil
	group.cooldownSize = nil
	group.chargeSize = nil
	group.cooldownFontSizeOverride = nil
	group.countFontSizeOverride = nil
	group.iconBorderEnabled = nil
	group.iconBorderTexture = nil
	group.iconBorderSize = nil
	group.iconBorderOffset = nil
	group.iconBorderColor = nil
	group.color = normalizeColor(group.color, { 1, 0.82, 0.1, 0.9 })
	return group
end

local function normalizeRule(rule, id)
	if type(rule) ~= "table" then return nil end
	rule.id = tostring(rule.id or id)
	local familyId = rule.spellFamilyId or rule.familyId
	if familyId ~= nil then familyId = tostring(familyId) end
	local customFamilyId = familyId and HB.GetCustomSpellFamilyId(familyId) or nil
	if customFamilyId then familyId = customFamilyId end
	rule.spellFamilyId = familyId
	rule.familyId = nil
	rule.groupId = tostring(rule.groupId or "")
	rule["not"] = rule["not"] == true
	local desaturateMissing = rule.desaturateMissing
	if desaturateMissing == nil then desaturateMissing = rule.missingDesaturate end
	rule.desaturateMissing = desaturateMissing == true
	rule.missingDesaturate = nil
	rule.expirationPulseEnabled = rule.expirationPulseEnabled == true
	rule.expirationPulseThreshold = roundInt(clamp(rule.expirationPulseThreshold, 1, 10, 3))
	rule.expirationPulseColor = normalizeColor(rule.expirationPulseColor, { 1, 0.2, 0.2, 1 })
	rule.expirationPulseCountdownOnly = rule.expirationPulseCountdownOnly == true
	rule.durationColorSteps = normalizeDurationColorSteps(rule.durationColorSteps or rule.remainingColorSteps)
	rule.remainingColorSteps = nil
	if rule.enabled == nil then rule.enabled = true end
	rule.enabled = rule.enabled ~= false
	local appliesParty = rule.appliesParty
	if appliesParty == nil then appliesParty = rule.appliesToParty end
	if appliesParty == nil then appliesParty = rule.party end
	if appliesParty == nil then appliesParty = true end
	local appliesRaid = rule.appliesRaid
	if appliesRaid == nil then appliesRaid = rule.appliesToRaid end
	if appliesRaid == nil then appliesRaid = rule.raid end
	if appliesRaid == nil then appliesRaid = true end
	rule.appliesParty = appliesParty ~= false
	rule.appliesRaid = appliesRaid ~= false
	rule.appliesTarget = rule.appliesTarget == true
	rule.appliesFocus = rule.appliesFocus == true
	rule.appliesBoss = rule.appliesBoss == true
	rule.appliesToParty = nil
	rule.appliesToRaid = nil
	rule.party = nil
	rule.raid = nil
	rule.color = normalizeOptionalColor(rule.color or rule.spellColor)
	rule.spellColor = nil
	return rule
end

function HB.ShouldDesaturateRuleIcon(group, rule)
	if not (group and rule) then return false end
	if normalizeStyle(group.style) ~= STYLE_ICON then return false end
	local desaturateMissing = rule.desaturateMissing
	if desaturateMissing == nil then desaturateMissing = rule.missingDesaturate end
	return rule["not"] == true and desaturateMissing == true
end

function HB.EnsureConfig(cfg)
	if type(cfg) ~= "table" then return nil end
	local placement = cfg.healerBuffPlacement
	if type(placement) ~= "table" then
		placement = newPlacementConfig()
		cfg.healerBuffPlacement = placement
	end
	local placementVersion = tonumber(placement.version) or 0
	if placement._eqolNormalized == true and placement._eqolDirty ~= true and placementVersion >= 2 then
		if placement.enabled == nil then placement.enabled = false end
		placement.version = placementVersion >= 3 and 3 or 2
		for _, group in pairs(placement.groupsById or EMPTY) do
			group.iconLayoutMode = normalizeIconLayoutMode(group.iconLayoutMode or group.iconOrderMode)
			group.iconOrderMode = nil
			if placement.version >= 3 then group.showCooldown = group.showCooldown ~= false end
		end
		for _, rule in pairs(placement.rulesById or EMPTY) do
			local customFamilyId, customSpellId = HB.GetCustomSpellFamilyId(rule and rule.spellFamilyId)
			if customFamilyId then HB._configuredCustomSpellToFamily[customSpellId] = customFamilyId end
		end
		return placement
	end
	if placement.enabled == nil then placement.enabled = false end
	placement.includeTarget = nil
	placement.includeFocus = nil
	placement.includeBoss = nil
	placement.version = placementVersion >= 3 and 3 or 2
	placement.groupsById = type(placement.groupsById) == "table" and placement.groupsById or {}
	placement.groupOrder = type(placement.groupOrder) == "table" and placement.groupOrder or {}
	placement.rulesById = type(placement.rulesById) == "table" and placement.rulesById or {}
	placement.ruleOrder = type(placement.ruleOrder) == "table" and placement.ruleOrder or {}

	local normalizedGroups = {}
	for key, group in pairs(placement.groupsById) do
		group = normalizeGroup(group, key)
		if group then normalizedGroups[group.id] = group end
	end
	placement.groupsById = normalizedGroups
	placement.groupOrder = normalizeOrder(placement.groupOrder, normalizedGroups)
	placement.familyScanAllCasters = nil

	local normalizedRules = {}
	for key, rule in pairs(placement.rulesById) do
		rule = normalizeRule(rule, key)
		if rule and rule.spellFamilyId and HB.ResolveFamily(rule.spellFamilyId) and normalizedGroups[rule.groupId] then
			normalizedRules[rule.id] = rule
			local customFamilyId, customSpellId = HB.GetCustomSpellFamilyId(rule.spellFamilyId)
			if customFamilyId then HB._configuredCustomSpellToFamily[customSpellId] = customFamilyId end
		end
	end
	placement.rulesById = normalizedRules
	placement.ruleOrder = normalizeOrder(placement.ruleOrder, normalizedRules)
	placement._eqolDirty = nil
	placement._eqolNormalized = true

	return placement
end

function HB.MigrateCooldownVisibility(placement, partyCfg, raidCfg)
	if type(placement) ~= "table" or (tonumber(placement.version) or 0) >= 3 then return placement end
	local partyShowCooldown = not (partyCfg and partyCfg.auras and partyCfg.auras.buff and partyCfg.auras.buff.showCooldown == false)
	local raidShowCooldown = not (raidCfg and raidCfg.auras and raidCfg.auras.buff and raidCfg.auras.buff.showCooldown == false)
	local scopeByGroup = {}
	for _, rule in pairs(placement.rulesById or EMPTY) do
		if type(rule) == "table" then
			local groupId = tostring(rule.groupId or "")
			if groupId ~= "" then
				local scope = scopeByGroup[groupId]
				if not scope then
					scope = {}
					scopeByGroup[groupId] = scope
				end
				if rule.appliesParty ~= false or rule.appliesTarget == true or rule.appliesFocus == true or rule.appliesBoss == true then scope.party = true end
				if rule.appliesRaid ~= false then scope.raid = true end
			end
		end
	end
	for groupId, group in pairs(placement.groupsById or EMPTY) do
		if type(group) == "table" and group.showCooldown == nil then
			local scope = scopeByGroup[tostring(groupId)]
			local usesParty = not scope or scope.party == true
			local usesRaid = scope and scope.raid == true
			group.showCooldown = not ((usesParty and not partyShowCooldown) or (usesRaid and not raidShowCooldown))
		end
	end
	placement.version = 3
	return placement
end

function HB.GetNextGroupId(placement)
	placement = placement or {}
	local groups = placement.groupsById or {}
	local maxId = 0
	for id in pairs(groups) do
		local n = tonumber(id)
		if n and n > maxId then maxId = n end
	end
	return tostring(maxId + 1)
end

function HB.GetNextRuleId(placement)
	placement = placement or {}
	local rules = placement.rulesById or {}
	local maxId = 0
	for id in pairs(rules) do
		local n = tonumber(id)
		if n and n > maxId then maxId = n end
	end
	return tostring(maxId + 1)
end

HB._kindGeneration = HB._kindGeneration or {}
HB._compiledByConfig = HB._compiledByConfig or setmetatable({}, { __mode = "k" })

function HB.InvalidateKind(kind)
	kind = normalizeKind(kind)
	if not KIND_SET[kind] then return end
	HB._kindGeneration[kind] = (HB._kindGeneration[kind] or 0) + 1
end

function HB.IsEnabled(kind, cfg)
	cfg = cfg or {}
	kind = normalizeKind(kind)
	local placement = HB.EnsureConfig(cfg)
	if not placement or placement.enabled ~= true then return false end
	if not KIND_SET[kind] then return false end
	if not next(placement.groupsById or EMPTY) then return false end
	if not next(placement.rulesById or EMPTY) then return false end
	return true
end

local function buildRulePseudoAuraId(ruleId)
	local numeric = tonumber(ruleId)
	if numeric then return -700000 - numeric end
	local hash = 0
	ruleId = tostring(ruleId or "")
	for i = 1, #ruleId do
		hash = ((hash * 33) + ruleId:byte(i)) % 100000
	end
	return -800000 - hash
end

local function ruleAppliesToKind(rule, kind)
	if not rule then return false end
	if kind == KIND_PARTY then return rule.appliesParty ~= false end
	if kind == KIND_RAID then return rule.appliesRaid ~= false end
	if kind == "target" then return rule.appliesTarget == true end
	if kind == "focus" then return rule.appliesFocus == true end
	if kind == "boss" then return rule.appliesBoss == true end
	return false
end

local function compile(kind, cfg)
	kind = normalizeKind(kind)
	local placement = HB.EnsureConfig(cfg)
	if not placement then return nil end
	local generation = HB._kindGeneration[kind] or 0
	local cachedByKind = HB._compiledByConfig[cfg]
	local cached = cachedByKind and cachedByKind[kind]
	if cached and cached.generation == generation then return cached end

	local familiesById = {}
	local spellToFamily = {}
	for familyId, family in pairs(FAMILY_BY_ID) do
		familiesById[familyId] = family
	end
	for spellId, familyId in pairs(SPELL_TO_FAMILY) do
		spellToFamily[spellId] = familyId
	end

	local compiled = {
		kind = kind,
		generation = generation,
		placement = placement,
		groupsById = placement.groupsById,
		groupOrder = placement.groupOrder,
		rulesById = placement.rulesById,
		ruleOrder = placement.ruleOrder,
		ruleById = {},
		groupToRuleIds = {},
		groupToEnabledRuleIds = {},
		familyToRuleIds = {},
		enabledFamilies = {},
		familyScanAllCastersById = {},
		suppressedFamilies = {},
		groupOrderByStyle = {
			[STYLE_ICON] = {},
			[STYLE_SQUARE] = {},
			[STYLE_BAR] = {},
			[STYLE_BORDER] = {},
			[STYLE_TINT] = {},
		},
		familiesById = familiesById,
		spellToFamily = spellToFamily,
		positiveSpellIDs = {},
		suppressedPositiveSpellIDs = {},
		enabled = false,
	}

	for i = 1, #compiled.groupOrder do
		local groupId = compiled.groupOrder[i]
		local group = compiled.groupsById[groupId]
		if group then
			compiled.groupToRuleIds[groupId] = compiled.groupToRuleIds[groupId] or {}
			compiled.groupToEnabledRuleIds[groupId] = compiled.groupToEnabledRuleIds[groupId] or {}
			compiled.groupOrderByStyle[group.style][#compiled.groupOrderByStyle[group.style] + 1] = groupId
		end
	end

	for i = 1, #compiled.ruleOrder do
		local ruleId = compiled.ruleOrder[i]
		local rule = compiled.rulesById[ruleId]
		if rule and ruleAppliesToKind(rule, kind) then
			local familyId = rule.spellFamilyId
			local groupId = rule.groupId
			local family = HB.ResolveFamily(familyId, compiled)
			if family and family.isCustomSpell == true and not compiled.familiesById[family.id] then
				compiled.familiesById[family.id] = family
				compiled.spellToFamily[family.customSpellId] = family.id
				familyId = family.id
				rule.spellFamilyId = familyId
			end
			if family and groupId and compiled.groupsById[groupId] then
				rule._pseudoAuraInstanceId = rule._pseudoAuraInstanceId or buildRulePseudoAuraId(rule.id)
				compiled.ruleById[ruleId] = rule
				local byFamily = compiled.familyToRuleIds[familyId]
				if not byFamily then
					byFamily = {}
					compiled.familyToRuleIds[familyId] = byFamily
				end
				byFamily[#byFamily + 1] = ruleId
				if rule.enabled ~= false then compiled.suppressedFamilies[familyId] = true end
				local byGroup = compiled.groupToRuleIds[groupId]
				if not byGroup then
					byGroup = {}
					compiled.groupToRuleIds[groupId] = byGroup
				end
				byGroup[#byGroup + 1] = ruleId
				if rule.enabled ~= false then
					if rule["not"] ~= true then
						for spellIndex = 1, #(family.spellIds or EMPTY) do
							local spellId = tonumber(family.spellIds[spellIndex])
							if spellId and spellId > 0 then
								compiled.positiveSpellIDs[spellId] = true
								compiled.suppressedPositiveSpellIDs[spellId] = true
							end
						end
					end
					compiled.enabledFamilies[familyId] = true
					if HB.GetFamilyScanAllCasters(familyId, compiled) then
						compiled.familyScanAllCastersById[familyId] = true
						compiled.needsWideHelpfulScan = true
					end
					local byGroupEnabled = compiled.groupToEnabledRuleIds[groupId]
					if not byGroupEnabled then
						byGroupEnabled = {}
						compiled.groupToEnabledRuleIds[groupId] = byGroupEnabled
					end
					byGroupEnabled[#byGroupEnabled + 1] = ruleId
				end
			end
		end
	end

	if placement.enabled == true and next(compiled.ruleById) and next(compiled.groupsById) and KIND_SET[kind] then compiled.enabled = true end
	cachedByKind = cachedByKind or {}
	cachedByKind[kind] = compiled
	HB._compiledByConfig[cfg] = cachedByKind
	return compiled
end

local function roundToPixel(value, scale)
	if GFH and GFH.RoundToPixel then return GFH.RoundToPixel(value, scale) end
	return roundInt(value)
end

local function getEffectiveScale(frame)
	if GFH and GFH.GetEffectiveScale then return GFH.GetEffectiveScale(frame) end
	if frame and frame.GetEffectiveScale then
		local scale = frame:GetEffectiveScale()
		if scale and scale > 0 then return scale end
	end
	return 1
end

local function setFrameParentCached(frame, parent)
	if not (frame and parent and frame.SetParent) then return false end
	if frame._hbCachedParent == parent and (not frame.GetParent or frame:GetParent() == parent) then return false end
	frame:SetParent(parent)
	frame._hbCachedParent = parent
	return true
end

local function setFrameStrataCached(frame, strata)
	if not (frame and frame.SetFrameStrata and strata ~= nil) then return false end
	if frame._hbCachedFrameStrata == strata then return false end
	frame:SetFrameStrata(strata)
	frame._hbCachedFrameStrata = strata
	return true
end

local function setFrameLevelCached(frame, level)
	if not (frame and frame.SetFrameLevel and level ~= nil) then return false end
	level = max(0, tonumber(level) or 0)
	if frame._hbCachedFrameLevel == level then return false end
	frame:SetFrameLevel(level)
	frame._hbCachedFrameLevel = level
	return true
end

local function setAllPointsCached(frame, relativeTo)
	if not (frame and relativeTo) then return false end
	if frame._hbAllPointsTarget == relativeTo then return false end
	frame._hbAllPointsTarget = relativeTo
	frame._hbPointCache = nil
	if frame.ClearAllPoints then frame:ClearAllPoints() end
	if frame.SetAllPoints then
		frame:SetAllPoints(relativeTo)
	else
		frame:SetPoint("TOPLEFT", relativeTo, "TOPLEFT", 0, 0)
		frame:SetPoint("BOTTOMRIGHT", relativeTo, "BOTTOMRIGHT", 0, 0)
	end
	return true
end

local function setSinglePointCached(frame, point, relativeTo, relativePoint, x, y)
	if not frame then return false end
	x = x or 0
	y = y or 0
	if Pixel and Pixel.Round then
		x = Pixel.Round(x, frame)
		y = Pixel.Round(y, frame)
	end
	local cache = frame._hbPointCache
	if cache and cache.mode == 1 and cache.point == point and cache.relativeTo == relativeTo and cache.relativePoint == relativePoint and cache.x == x and cache.y == y then return false end
	frame._hbAllPointsTarget = nil
	cache = cache or {}
	frame._hbPointCache = cache
	if frame.ClearAllPoints then frame:ClearAllPoints() end
	frame:SetPoint(point, relativeTo, relativePoint, x, y)
	cache.mode = 1
	cache.point = point
	cache.relativeTo = relativeTo
	cache.relativePoint = relativePoint
	cache.x = x
	cache.y = y
	return true
end

local function setTwoPointsCached(frame, firstPoint, firstRelativeTo, firstRelativePoint, firstX, firstY, secondPoint, secondRelativeTo, secondRelativePoint, secondX, secondY)
	if not frame then return false end
	firstX = firstX or 0
	firstY = firstY or 0
	secondX = secondX or 0
	secondY = secondY or 0
	if Pixel and Pixel.Round then
		firstX = Pixel.Round(firstX, frame)
		firstY = Pixel.Round(firstY, frame)
		secondX = Pixel.Round(secondX, frame)
		secondY = Pixel.Round(secondY, frame)
	end
	local cache = frame._hbPointCache
	if
		cache
		and cache.mode == 2
		and cache.firstPoint == firstPoint
		and cache.firstRelativeTo == firstRelativeTo
		and cache.firstRelativePoint == firstRelativePoint
		and cache.firstX == firstX
		and cache.firstY == firstY
		and cache.secondPoint == secondPoint
		and cache.secondRelativeTo == secondRelativeTo
		and cache.secondRelativePoint == secondRelativePoint
		and cache.secondX == secondX
		and cache.secondY == secondY
	then
		return false
	end
	frame._hbAllPointsTarget = nil
	cache = cache or {}
	frame._hbPointCache = cache
	if frame.ClearAllPoints then frame:ClearAllPoints() end
	frame:SetPoint(firstPoint, firstRelativeTo, firstRelativePoint, firstX, firstY)
	frame:SetPoint(secondPoint, secondRelativeTo, secondRelativePoint, secondX, secondY)
	cache.mode = 2
	cache.firstPoint = firstPoint
	cache.firstRelativeTo = firstRelativeTo
	cache.firstRelativePoint = firstRelativePoint
	cache.firstX = firstX
	cache.firstY = firstY
	cache.secondPoint = secondPoint
	cache.secondRelativeTo = secondRelativeTo
	cache.secondRelativePoint = secondRelativePoint
	cache.secondX = secondX
	cache.secondY = secondY
	return true
end

local function setSizeCached(frame, width, height)
	if not (frame and frame.SetSize) then return false end
	width = width or 0
	height = height or 0
	if Pixel and Pixel.Round then
		width = Pixel.Round(width, frame)
		height = Pixel.Round(height, frame)
	end
	if frame._hbCachedWidth == width and frame._hbCachedHeight == height then return false end
	frame:SetSize(width, height)
	frame._hbCachedWidth = width
	frame._hbCachedHeight = height
	return true
end

local function getOffsetXY(offset)
	if type(offset) ~= "table" then return nil, nil end
	return offset.x, offset.y
end

local function getGrowthAxes(growth)
	local axes = GROWTH_AXES[normalizeGrowth(growth)]
	if axes then return axes[1], axes[2] end
	return "RIGHT", "DOWN"
end

local function clearHiddenAuraButton(btn)
	if not btn then return end
	if AuraUtil and AuraUtil.setAuraTooltipState then AuraUtil.setAuraTooltipState(btn, EMPTY) end
	btn._showTooltip = false
	btn._hbTooltipShown = false
	btn._tooltipUseEditMode = nil
	btn._tooltipAnchor = nil
	if btn.SetMouseClickEnabled and btn._hbMouseClickEnabled ~= false then
		btn:SetMouseClickEnabled(false)
		btn._hbMouseClickEnabled = false
	end
	if btn.SetMouseMotionEnabled and btn._hbMouseMotionEnabled ~= false then
		btn:SetMouseMotionEnabled(false)
		btn._hbMouseMotionEnabled = false
	end
	if btn.EnableMouse then
		if btn._hbMouseEnabled ~= false then btn:EnableMouse(false) end
		btn._hbMouseEnabled = false
	end
	if GameTooltip and GameTooltip.IsOwned and GameTooltip.Hide and GameTooltip:IsOwned(btn) then GameTooltip:Hide() end
	if btn.Hide then btn:Hide() end
end

local function hideButtons(buttons, startIndex)
	if not buttons then return end
	for i = startIndex, #buttons do
		clearHiddenAuraButton(buttons[i])
	end
end

local function calcGridSize(shown, perRow, size, spacing, primary)
	if shown == nil or shown < 1 then return 0.001, 0.001 end
	perRow = max(1, tonumber(perRow) or 1)
	size = tonumber(size) or 16
	spacing = tonumber(spacing) or 0
	local primaryVertical = primary == "UP" or primary == "DOWN"
	local rows, cols
	if primaryVertical then
		rows = min(shown, perRow)
		cols = max(1, floor((shown + perRow - 1) / perRow))
	else
		rows = max(1, floor((shown + perRow - 1) / perRow))
		cols = min(shown, perRow)
	end
	local w = cols * size + spacing * max(0, cols - 1)
	local h = rows * size + spacing * max(0, rows - 1)
	if w <= 0 then w = 0.001 end
	if h <= 0 then h = 0.001 end
	return w, h
end

local function positionAuraButton(btn, container, primary, secondary, index, perRow, size, spacing, anchorPoint)
	if not (btn and container) then return end
	perRow = max(1, perRow or 1)
	local primaryHorizontal = primary == "LEFT" or primary == "RIGHT"
	local row, col
	if primaryHorizontal then
		row = floor((index - 1) / perRow)
		col = (index - 1) % perRow
	else
		row = (index - 1) % perRow
		col = floor((index - 1) / perRow)
	end
	local horizontalDir = primaryHorizontal and primary or secondary
	local verticalDir = primaryHorizontal and secondary or primary
	local xSign = horizontalDir == "RIGHT" and 1 or -1
	local ySign = verticalDir == "UP" and 1 or -1
	local step = size + spacing
	local scale = getEffectiveScale(container)
	local x = roundToPixel(col * step * xSign, scale)
	local y = roundToPixel(row * step * ySign, scale)
	anchorPoint = normalizeAnchor(anchorPoint)
	setSinglePointCached(btn, anchorPoint, container, anchorPoint, x, y)
end

local function getState(btn)
	if not btn then return nil, nil end
	local st = btn._eqolUFState
	if not st then return nil, nil end
	local state = st._healerBuffPlacementState
	if state then return state, st end
	state = {
		auraFamilyByInstance = {},
		familyCounts = {},
		familyAura = {},
		familyAuraInstance = {},
		ruleActive = {},
		groupActive = {},
		renderHashByStyle = {},
		groupContainers = {},
		groupButtons = {},
		groupBars = {},
		groupStyleCache = {},
		changedFamilies = {},
		changedRules = {},
		changedGroups = {},
		tempRuleList = {},
		tempSampleRuleActive = {},
		tempSampleGroupActive = {},
		tempSampleFamilyAura = {},
		tempSampleFamilyAuraInstance = {},
		tempSampleFamilyCounts = {},
		tempPlaceholderByRule = {},
	}
	st._healerBuffPlacementState = state
	return state, st
end

local function ensureVisualLayers(btn, st, forceLayout)
	if not (btn and st) then return nil end
	local parent = st.barGroup or btn
	if not parent then return nil end

	local layoutChanged = forceLayout == true
	if not st.healerBuffRoot then
		st.healerBuffRoot = CreateFrame("Frame", nil, parent)
		st.healerBuffRoot:EnableMouse(false)
		layoutChanged = true
	end
	local root = st.healerBuffRoot
	if st._hbVisualParent ~= parent or (root.GetParent and root:GetParent() ~= parent) then
		layoutChanged = true
		st._hbVisualParent = parent
	end
	setFrameParentCached(root, parent)
	if layoutChanged then
		root._hbAllPointsTarget = nil
		setAllPointsCached(root, parent)
	end
	if root.SetFrameStrata and parent.GetFrameStrata then setFrameStrataCached(root, parent:GetFrameStrata()) end
	if root.SetFrameLevel and parent.GetFrameLevel then setFrameLevelCached(root, (parent:GetFrameLevel() or 0) + 12) end
	root:Show()

	if not st.healerBuffIconLayer then
		st.healerBuffIconLayer = CreateFrame("Frame", nil, root)
		st.healerBuffIconLayer:EnableMouse(false)
		layoutChanged = true
	end
	local iconLayer = st.healerBuffIconLayer
	setFrameParentCached(iconLayer, root)
	if layoutChanged then
		iconLayer._hbAllPointsTarget = nil
		setAllPointsCached(iconLayer, root)
	end
	if iconLayer.SetFrameStrata and root.GetFrameStrata then setFrameStrataCached(iconLayer, root:GetFrameStrata()) end
	if iconLayer.SetFrameLevel and root.GetFrameLevel then setFrameLevelCached(iconLayer, (root:GetFrameLevel() or 0) + 30) end

	if not st.healerBuffTint then
		st.healerBuffTint = (Pixel and Pixel.CreateTexture and Pixel.CreateTexture(root, nil, "ARTWORK", nil, 2)) or root:CreateTexture(nil, "ARTWORK", nil, 2)
		if Pixel and Pixel.SetColorTexture then
			Pixel.SetColorTexture(st.healerBuffTint, 0, 0, 0, 0)
		else
			st.healerBuffTint:SetColorTexture(0, 0, 0, 0)
		end
		st.healerBuffTint:Hide()
	end
	if st.healerBuffTint.GetParent and st.healerBuffTint:GetParent() ~= root then st.healerBuffTint:SetParent(root) end
	if st.healerBuffTint.SetDrawLayer then st.healerBuffTint:SetDrawLayer("ARTWORK", 2) end

	if not st.healerBuffBar then
		st.healerBuffBar = CreateFrame("StatusBar", nil, root)
		st.healerBuffBar:EnableMouse(false)
		if Pixel and Pixel.SetStatusBarTexture then
			Pixel.SetStatusBarTexture(st.healerBuffBar, "Interface\\Buttons\\WHITE8x8")
		else
			st.healerBuffBar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
		end
		st.healerBuffBar:SetMinMaxValues(0, 1)
		st.healerBuffBar:SetValue(1)
		st.healerBuffBar:Hide()
	end
	setFrameParentCached(st.healerBuffBar, root)
	if st.healerBuffBar.SetFrameStrata and root.GetFrameStrata then setFrameStrataCached(st.healerBuffBar, root:GetFrameStrata()) end
	if st.healerBuffBar.SetFrameLevel and root.GetFrameLevel then setFrameLevelCached(st.healerBuffBar, (root:GetFrameLevel() or 0) + 3) end
	local barTex = st.healerBuffBar.GetStatusBarTexture and st.healerBuffBar:GetStatusBarTexture()
	if barTex then
		barTex:SetHorizTile(false)
		barTex:SetVertTile(false)
	end
	st.healerBuffBar:Hide()

	if not st.healerBuffBorder then
		st.healerBuffBorder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
		st.healerBuffBorder:EnableMouse(false)
		st.healerBuffBorder:Hide()
	end
	setFrameParentCached(st.healerBuffBorder, parent)
	if st.healerBuffBorder.SetFrameStrata and parent.GetFrameStrata then setFrameStrataCached(st.healerBuffBorder, parent:GetFrameStrata()) end
	if st.healerBuffBorder.SetFrameLevel and parent.GetFrameLevel then setFrameLevelCached(st.healerBuffBorder, (parent:GetFrameLevel() or 0) + 16) end

	if layoutChanged then st._hbHealerBuffLayoutRevision = (st._hbHealerBuffLayoutRevision or 0) + 1 end

	return root
end

local function ensureBarForGroup(state, st, groupId)
	if not (state and st and st.healerBuffRoot and groupId) then return nil end
	local bars = state.groupBars
	if not bars then
		bars = {}
		state.groupBars = bars
	end
	local bar = bars[groupId]
	if not bar then
		bar = CreateFrame("StatusBar", nil, st.healerBuffRoot)
		bar:EnableMouse(false)
		if Pixel and Pixel.SetStatusBarTexture then
			Pixel.SetStatusBarTexture(bar, "Interface\\Buttons\\WHITE8x8")
		else
			bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
		end
		bar:SetMinMaxValues(0, 1)
		bar:SetValue(1)
		bar:Hide()
		bars[groupId] = bar
	end
	setFrameParentCached(bar, st.healerBuffRoot)
	if bar.SetFrameStrata and st.healerBuffRoot.GetFrameStrata then setFrameStrataCached(bar, st.healerBuffRoot:GetFrameStrata()) end
	if bar.SetFrameLevel and st.healerBuffRoot.GetFrameLevel then setFrameLevelCached(bar, (st.healerBuffRoot:GetFrameLevel() or 0) + 3) end
	local barTex = bar.GetStatusBarTexture and bar:GetStatusBarTexture()
	if barTex then
		barTex:SetHorizTile(false)
		barTex:SetVertTile(false)
	end
	return bar
end

local function ensureVisualLayersForUpdate(btn, st)
	if not (btn and st) then return nil end
	local parent = st.barGroup or btn
	if not parent then return nil end
	if not st.healerBuffRoot or not st.healerBuffIconLayer then return ensureVisualLayers(btn, st, false) end
	if st._hbVisualParent ~= parent then return ensureVisualLayers(btn, st, false) end
	if st.healerBuffRoot.GetParent and st.healerBuffRoot:GetParent() ~= parent then return ensureVisualLayers(btn, st, false) end
	return st.healerBuffRoot
end

local function clearHealthTint(st)
	if not st then return false end
	local changed = (st._hbHealthTintR ~= nil) or (st._hbHealthTintG ~= nil) or (st._hbHealthTintB ~= nil) or (st._hbHealthTintA ~= nil)
	st._hbHealthTintR = nil
	st._hbHealthTintG = nil
	st._hbHealthTintB = nil
	st._hbHealthTintA = nil
	return changed
end

local BAR_UPDATE_INTERVAL = 0.05
local TINT_UPDATE_INTERVAL = 1
local updateDurationColorStatusBar
local clearBarDurationColorState
local clearBorderDurationColorState
local clearTintDurationColorState

local function clearAnimatedBarState(bar)
	if not bar then return end
	bar._hbTrackedDuration = nil
	bar._hbTrackedExpirationTime = nil
	bar._hbBarUpdateElapsed = nil
	if bar.SetScript and bar._hbDurationColorRule == nil then bar:SetScript("OnUpdate", nil) end
end

local function getTimedBarFill(duration, expirationTime, now)
	duration = tonumber(duration)
	expirationTime = tonumber(expirationTime)
	if not (duration and duration > 0 and expirationTime and expirationTime > 0) then return nil end
	now = tonumber(now) or ((GetTime and GetTime()) or 0)
	return clamp((expirationTime - now) / duration, 0, 1, 0)
end

local function updateAnimatedBarValue(bar, now)
	if not (bar and bar.SetValue) then return end
	local fill = getTimedBarFill(bar._hbTrackedDuration, bar._hbTrackedExpirationTime, now)
	bar:SetValue(fill ~= nil and fill or 1)
end

local function setAnimatedBarAura(bar, aura)
	if not bar then return false end
	local duration = aura and tonumber(aura.duration) or nil
	local expirationTime = aura and tonumber(aura.expirationTime) or nil
	if not (duration and duration > 0 and expirationTime and expirationTime > 0) then
		clearAnimatedBarState(bar)
		if bar.SetValue then bar:SetValue(1) end
		return false
	end
	bar._hbTrackedDuration = duration
	bar._hbTrackedExpirationTime = expirationTime
	bar._hbBarUpdateElapsed = 0
	updateAnimatedBarValue(bar)
	if not bar._hbBarOnUpdate then
		bar._hbBarOnUpdate = function(self, elapsed)
			self._hbBarUpdateElapsed = (self._hbBarUpdateElapsed or 0) + (elapsed or 0)
			if self._hbBarUpdateElapsed < BAR_UPDATE_INTERVAL then return end
			self._hbBarUpdateElapsed = 0
			updateAnimatedBarValue(self)
			if updateDurationColorStatusBar then updateDurationColorStatusBar(self) end
		end
	end
	if bar.SetScript then bar:SetScript("OnUpdate", bar._hbBarOnUpdate) end
	return true
end

local function hideAllVisuals(btn, st, state)
	if not st then return end
	if st.healerBuffTint then st.healerBuffTint:Hide() end
	if clearTintDurationColorState then clearTintDurationColorState(st) end
	if st.healerBuffBar then
		clearAnimatedBarState(st.healerBuffBar)
		if clearBarDurationColorState then clearBarDurationColorState(st.healerBuffBar) end
		st.healerBuffBar:Hide()
	end
	if state and state.groupBars then
		for _, bar in pairs(state.groupBars) do
			if bar then
				clearAnimatedBarState(bar)
				if clearBarDurationColorState then clearBarDurationColorState(bar) end
				bar:Hide()
			end
		end
	end
	if st.healerBuffBorder then
		if clearBorderDurationColorState then clearBorderDurationColorState(st.healerBuffBorder) end
		st.healerBuffBorder:Hide()
	end
	local tintChanged = clearHealthTint(st)
	if state and state.groupContainers then
		for groupId, container in pairs(state.groupContainers) do
			if container then container:Hide() end
			hideButtons(state.groupButtons and state.groupButtons[groupId], 1)
		end
	end
	if tintChanged and btn and UF and UF.GroupFrames and UF.GroupFrames.UpdateHealthStyle then UF.GroupFrames:UpdateHealthStyle(btn) end
end

local function resetState(state)
	if not state then return end
	wipeTable(state.auraFamilyByInstance)
	wipeTable(state.familyCounts)
	wipeTable(state.familyAura)
	wipeTable(state.familyAuraInstance)
	wipeTable(state.ruleActive)
	wipeTable(state.groupActive)
	wipeTable(state.changedFamilies)
	wipeTable(state.changedRules)
	wipeTable(state.changedGroups)
	wipeTable(state.tempRuleList)
	wipeTable(state.renderHashByStyle)
end

local function isNpcUnit(unit)
	if type(unit) ~= "string" or unit == "" then return false end
	if issecretvalue and issecretvalue(unit) then return false end

	if UnitExists then
		local exists = UnitExists(unit)
		if issecretvalue and issecretvalue(exists) then return false end
		if exists ~= true then return false end
	end

	if not UnitIsPlayer then return false end
	local isPlayer = UnitIsPlayer(unit)
	if issecretvalue and issecretvalue(isPlayer) then return false end
	return isPlayer == false
end

local function shouldIgnoreFamilyForUnit(familyId, unit, source)
	if familyId == nil then return false end
	local family = HB.ResolveFamily(familyId, source)
	if not (family and family.ignoreForNpcUnits == true) then return false end
	return isNpcUnit(unit)
end

local function isAuraFromPlayer(unit, aura, familyId, compiled)
	if aura == nil then return false end
	local isHelpful = aura.isHelpful
	if issecretvalue and issecretvalue(isHelpful) then return false end
	if isHelpful ~= true then return false end
	local familyKey = familyId and tostring(familyId) or nil
	local family = familyKey and HB.ResolveFamily(familyKey, compiled) or nil
	if family and family.classToken ~= nil and not canPlayerProvideFamilyCached(familyKey, compiled) then return false end
	if familyKey and compiled and compiled.familyScanAllCastersById and compiled.familyScanAllCastersById[familyKey] == true then
		return true
	end
	if not (C_UnitAuras and C_UnitAuras.IsAuraFilteredOutByInstanceID and aura.auraInstanceID) then return false end
	return not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, aura.auraInstanceID, "HELPFUL|PLAYER")
end

local function getFamilyForAura(compiled, aura, unit)
	if not (compiled and aura) then return nil end
	local spellId = aura.spellId
	if spellId == nil then return nil end
	if issecretvalue and issecretvalue(spellId) then return nil end
	local familyId = compiled.spellToFamily[tonumber(spellId)]
	if familyId == nil then return nil end
	if compiled.enabledFamilies and compiled.enabledFamilies[familyId] ~= true then return nil end
	if shouldIgnoreFamilyForUnit(familyId, unit, compiled) then return nil end
	if not isAuraFromPlayer(unit, aura, familyId, compiled) then return nil end
	return familyId
end

function HB.ShouldSuppressRegularBuffAura(kind, cfg, aura, compiled, unit)
	if aura == nil or cfg == nil then return false end
	compiled = compiled or compile(kind, cfg)
	if not (compiled and compiled.enabled) then return false end
	local familyId = getFamilyForAura(compiled, aura, unit)
	if familyId == nil then return false end
	return compiled.suppressedFamilies and compiled.suppressedFamilies[familyId] == true
end

local function rebuildFamilyStateFromCache(state, compiled, cache, unit)
	wipeTable(state.auraFamilyByInstance)
	wipeTable(state.familyCounts)
	wipeTable(state.familyAura)
	wipeTable(state.familyAuraInstance)
	if not (cache and cache.order and cache.auras) then return end
	local order = cache.order
	local auras = cache.auras
	for i = 1, #order do
		local auraId = order[i]
		local aura = auraId and auras[auraId]
		if aura and auraId then
			local familyId = getFamilyForAura(compiled, aura, unit)
			if familyId then
				state.auraFamilyByInstance[auraId] = familyId
				state.familyCounts[familyId] = (state.familyCounts[familyId] or 0) + 1
				if not state.familyAura[familyId] then
					state.familyAura[familyId] = aura
					state.familyAuraInstance[familyId] = auraId
				end
			end
		end
	end
end

local function findRepresentativeAura(state, cache, familyId)
	if not (cache and cache.order and cache.auras and familyId) then
		state.familyAura[familyId] = nil
		state.familyAuraInstance[familyId] = nil
		return
	end
	local order = cache.order
	local auras = cache.auras
	for i = 1, #order do
		local auraId = order[i]
		if auraId and state.auraFamilyByInstance[auraId] == familyId then
			state.familyAura[familyId] = auras[auraId]
			state.familyAuraInstance[familyId] = auraId
			return
		end
	end
	state.familyAura[familyId] = nil
	state.familyAuraInstance[familyId] = nil
end

local function markFamilyChanged(changedFamilies, familyId)
	if familyId then changedFamilies[familyId] = true end
end

local function updateFamilyFromAura(state, compiled, auraId, aura, changedFamilies, unit)
	local oldFamily = state.auraFamilyByInstance[auraId]
	local newFamily = aura and getFamilyForAura(compiled, aura, unit) or nil
	if oldFamily == newFamily then
		if newFamily then
			state.familyAura[newFamily] = aura
			state.familyAuraInstance[newFamily] = auraId
			markFamilyChanged(changedFamilies, newFamily)
		end
		return
	end

	if oldFamily then
		local oldCount = (state.familyCounts[oldFamily] or 0) - 1
		if oldCount <= 0 then
			state.familyCounts[oldFamily] = nil
			state.familyAura[oldFamily] = nil
			state.familyAuraInstance[oldFamily] = nil
		else
			state.familyCounts[oldFamily] = oldCount
			if state.familyAuraInstance[oldFamily] == auraId then
				state.familyAura[oldFamily] = nil
				state.familyAuraInstance[oldFamily] = nil
			end
		end
		markFamilyChanged(changedFamilies, oldFamily)
	end

	if newFamily then
		state.auraFamilyByInstance[auraId] = newFamily
		state.familyCounts[newFamily] = (state.familyCounts[newFamily] or 0) + 1
		state.familyAura[newFamily] = aura
		state.familyAuraInstance[newFamily] = auraId
		markFamilyChanged(changedFamilies, newFamily)
	else
		state.auraFamilyByInstance[auraId] = nil
	end
end

local function applyDeltaToFamilyState(state, compiled, cache, updateInfo, unit)
	local changedFamilies = state.changedFamilies
	wipeTable(changedFamilies)
	if not updateInfo then return changedFamilies end

	if updateInfo.removedAuraInstanceIDs then
		for i = 1, #updateInfo.removedAuraInstanceIDs do
			local auraId = updateInfo.removedAuraInstanceIDs[i]
			if auraId then updateFamilyFromAura(state, compiled, auraId, nil, changedFamilies, unit) end
		end
	end

	if updateInfo.addedAuras then
		for i = 1, #updateInfo.addedAuras do
			local aura = updateInfo.addedAuras[i]
			local auraId = aura and aura.auraInstanceID
			if auraId then updateFamilyFromAura(state, compiled, auraId, aura, changedFamilies, unit) end
		end
	end

	if updateInfo.updatedAuraInstanceIDs and cache and cache.auras then
		for i = 1, #updateInfo.updatedAuraInstanceIDs do
			local auraId = updateInfo.updatedAuraInstanceIDs[i]
			if auraId then
				local aura = cache.auras[auraId]
				updateFamilyFromAura(state, compiled, auraId, aura, changedFamilies, unit)
			end
		end
	end

	for familyId in pairs(changedFamilies) do
		if state.familyCounts[familyId] and not state.familyAuraInstance[familyId] then findRepresentativeAura(state, cache, familyId) end
	end

	return changedFamilies
end

local function evaluateRuleActive(rule, familyCounts, unit, compiled)
	if not rule or rule.enabled == false then return false end
	if shouldIgnoreFamilyForUnit(rule.spellFamilyId, unit, compiled) then return false end
	if rule["not"] and not canPlayerProvideFamilyCached(rule.spellFamilyId, compiled) then return false end
	local active = (familyCounts[rule.spellFamilyId] or 0) > 0
	if rule["not"] then active = not active end
	return active
end

local function evaluateGroupActive(state, compiled, groupId)
	local active = false
	local group = compiled.groupsById and compiled.groupsById[groupId]
	local isTintAll = group and group.style == STYLE_TINT and group.ruleMatch == RULE_MATCH_ALL
	if isTintAll then
		local enabledRuleIds = compiled.groupToEnabledRuleIds[groupId]
		if enabledRuleIds and #enabledRuleIds > 0 then
			active = true
			for i = 1, #enabledRuleIds do
				if state.ruleActive[enabledRuleIds[i]] ~= true then
					active = false
					break
				end
			end
		end
	else
		local ruleIds = compiled.groupToRuleIds[groupId]
		if ruleIds then
			for i = 1, #ruleIds do
				if state.ruleActive[ruleIds[i]] then
					active = true
					break
				end
			end
		end
	end
	local changed = state.groupActive[groupId] ~= active
	state.groupActive[groupId] = active
	return changed
end

local function evaluateAllRulesAndGroups(state, compiled, unit)
	wipeTable(state.ruleActive)
	wipeTable(state.groupActive)
	for i = 1, #compiled.ruleOrder do
		local ruleId = compiled.ruleOrder[i]
		local rule = compiled.ruleById[ruleId]
		if rule then state.ruleActive[ruleId] = evaluateRuleActive(rule, state.familyCounts, unit, compiled) end
	end
	for i = 1, #compiled.groupOrder do
		evaluateGroupActive(state, compiled, compiled.groupOrder[i])
	end
end

local function evaluateDeltaRulesAndGroups(state, compiled, changedFamilies, unit)
	local changedRules = state.changedRules
	local changedGroups = state.changedGroups
	wipeTable(changedRules)
	wipeTable(changedGroups)

	for familyId in pairs(changedFamilies or EMPTY) do
		local familyRules = compiled.familyToRuleIds[familyId]
		if familyRules then
			for i = 1, #familyRules do
				changedRules[familyRules[i]] = true
			end
		end
	end

	for ruleId in pairs(changedRules) do
		local rule = compiled.ruleById[ruleId]
		if rule then
			local newActive = evaluateRuleActive(rule, state.familyCounts, unit, compiled)
			if state.ruleActive[ruleId] ~= newActive then
				state.ruleActive[ruleId] = newActive
				changedGroups[rule.groupId] = true
			end
		end
	end

	for groupId in pairs(changedGroups) do
		evaluateGroupActive(state, compiled, groupId)
	end
end

local function ensureGroupContainer(state, st, groupId)
	local container = state.groupContainers[groupId]
	if not container then
		container = CreateFrame("Frame", nil, st.healerBuffIconLayer)
		container:EnableMouse(false)
		state.groupContainers[groupId] = container
	end
	setFrameParentCached(container, st.healerBuffIconLayer)
	if container.SetFrameStrata and st.healerBuffIconLayer.GetFrameStrata then setFrameStrataCached(container, st.healerBuffIconLayer:GetFrameStrata()) end
	if container.SetFrameLevel and st.healerBuffIconLayer.GetFrameLevel then setFrameLevelCached(container, (st.healerBuffIconLayer:GetFrameLevel() or 0) + 1) end
	return container
end

local function getAuraStyleForGroup(state, cfg, group)
	local styleCache = state.groupStyleCache[group.id]
	if not styleCache then
		styleCache = {}
		state.groupStyleCache[group.id] = styleCache
	end
	local ac = cfg and cfg.auras and cfg.auras.buff or EMPTY
	local cooldownOffsetX, cooldownOffsetY = getOffsetXY(ac.cooldownOffset)
	local countOffsetX, countOffsetY = getOffsetXY(ac.countOffset)
	local showTooltip = ac.showTooltip == true
	local showCooldownSwipe = group.showCooldownSwipe ~= false
	local showCooldownEdge = group.showCooldownEdge ~= false
	local showCooldownBling = group.showCooldownBling ~= false
	local showCooldown = group.showCooldown ~= false
	local showCooldownText = showCooldown and group.hideCooldownText ~= true
	local showStacks
	if group.hideChargeText == true then
		showStacks = false
	elseif ac.showStacks ~= nil then
		showStacks = ac.showStacks
	else
		showStacks = nil
	end
	local cooldownFontSize = group.cooldownTextSize ~= nil and group.cooldownTextSize or ac.cooldownFontSize
	local countFontSize = group.chargeTextSize ~= nil and group.chargeTextSize or ac.countFontSize
	local changed = styleCache._cfgSize ~= group.size
		or styleCache._cfgPadding ~= group.spacing
		or styleCache._cfgIconZoom ~= group.iconZoom
		or styleCache._cfgShowTooltip ~= showTooltip
		or styleCache._cfgShowCooldownSwipe ~= showCooldownSwipe
		or styleCache._cfgShowCooldownEdge ~= showCooldownEdge
		or styleCache._cfgShowCooldownBling ~= showCooldownBling
		or styleCache._cfgShowCooldown ~= showCooldown
		or styleCache._cfgShowCooldownText ~= showCooldownText
		or styleCache._cfgShowStacks ~= showStacks
		or styleCache._cfgCooldownAnchor ~= ac.cooldownAnchor
		or styleCache._cfgCooldownOffsetX ~= cooldownOffsetX
		or styleCache._cfgCooldownOffsetY ~= cooldownOffsetY
		or styleCache._cfgCooldownFont ~= ac.cooldownFont
		or styleCache._cfgCooldownFontSize ~= cooldownFontSize
		or styleCache._cfgCooldownFontOutline ~= ac.cooldownFontOutline
		or styleCache._cfgDurationTextProfile ~= ac.durationTextProfile
		or styleCache._cfgCountAnchor ~= ac.countAnchor
		or styleCache._cfgCountOffsetX ~= countOffsetX
		or styleCache._cfgCountOffsetY ~= countOffsetY
		or styleCache._cfgCountFont ~= ac.countFont
		or styleCache._cfgCountFontSize ~= countFontSize
		or styleCache._cfgCountFontOutline ~= ac.countFontOutline
	if not changed then return styleCache end

	styleCache._cfgSize = group.size
	styleCache._cfgPadding = group.spacing
	styleCache._cfgIconZoom = group.iconZoom
	styleCache._cfgShowTooltip = showTooltip
	styleCache._cfgShowCooldownSwipe = showCooldownSwipe
	styleCache._cfgShowCooldownEdge = showCooldownEdge
	styleCache._cfgShowCooldownBling = showCooldownBling
	styleCache._cfgShowCooldown = showCooldown
	styleCache._cfgShowCooldownText = showCooldownText
	styleCache._cfgShowStacks = showStacks
	styleCache._cfgCooldownAnchor = ac.cooldownAnchor
	styleCache._cfgCooldownOffsetX = cooldownOffsetX
	styleCache._cfgCooldownOffsetY = cooldownOffsetY
	styleCache._cfgCooldownFont = ac.cooldownFont
	styleCache._cfgDurationTextProfile = ac.durationTextProfile
	if group.cooldownTextSize ~= nil then
		styleCache._cfgCooldownFontSize = group.cooldownTextSize
	else
		styleCache._cfgCooldownFontSize = ac.cooldownFontSize
	end
	styleCache._cfgCooldownFontOutline = ac.cooldownFontOutline
	styleCache._cfgCountAnchor = ac.countAnchor
	styleCache._cfgCountOffsetX = countOffsetX
	styleCache._cfgCountOffsetY = countOffsetY
	styleCache._cfgCountFont = ac.countFont
	if group.chargeTextSize ~= nil then
		styleCache._cfgCountFontSize = group.chargeTextSize
	else
		styleCache._cfgCountFontSize = ac.countFontSize
	end
	styleCache._cfgCountFontOutline = ac.countFontOutline
	styleCache.size = group.size
	styleCache.padding = group.spacing
	styleCache.iconZoom = group.iconZoom
	styleCache.showTooltip = showTooltip
	styleCache.showCooldownSwipe = showCooldownSwipe
	styleCache.showCooldownEdge = showCooldownEdge
	styleCache.showCooldownBling = showCooldownBling
	styleCache.showCooldown = showCooldown
	styleCache.showCooldownText = showCooldownText
	styleCache.showStacks = showStacks
	styleCache.cooldownAnchor = ac.cooldownAnchor
	styleCache.cooldownOffset = ac.cooldownOffset
	styleCache.cooldownFont = ac.cooldownFont
	styleCache.cooldownFontSize = cooldownFontSize
	styleCache.cooldownFontOutline = ac.cooldownFontOutline
	styleCache.durationTextProfile = ac.durationTextProfile
	styleCache.countAnchor = ac.countAnchor
	styleCache.countOffset = ac.countOffset
	styleCache.countFont = ac.countFont
	styleCache.countFontSize = countFontSize
	styleCache.countFontOutline = ac.countFontOutline
	styleCache.showDR = false
	styleCache._eqolAuraButtonStyleKey = nil
	styleCache._eqolStyleRevision = (styleCache._eqolStyleRevision or 0) + 1
	return styleCache
end

local function updateGroupContainerLayout(container, group, shown)
	local growthPrimary, growthSecondary = getGrowthAxes(group.growth)
	local scale = getEffectiveScale(container)
	local ox = roundToPixel(group.x or 0, scale)
	local oy = roundToPixel(group.y or 0, scale)
	setSinglePointCached(container, group.anchorPoint, container:GetParent(), group.anchorPoint, ox, oy)
	local w, h = calcGridSize(shown, group.perRow, group.size, group.spacing, growthPrimary)
	setSizeCached(container, w, h)
	return growthPrimary, growthSecondary
end

local function resolveColor(color)
	if type(color) == "table" then return color[1] or color.r or 1, color[2] or color.g or 1, color[3] or color.b or 1, color[4] or color.a or 1 end
	return 1, 1, 1, 1
end

local function applyButtonIconZoom(btn, iconZoom, baseInset)
	if addon.IconShape and addon.IconShape.NormalizeIconZoom then
		iconZoom = addon.IconShape.NormalizeIconZoom(iconZoom)
	else
		iconZoom = roundInt(clamp(iconZoom, 0, 35, 0))
	end
	if iconZoom <= 0 then
		if btn and btn.icon and btn.icon.SetTexCoord then btn.icon:SetTexCoord(0, 1, 0, 1) end
		return
	end
	if addon.IconShape and addon.IconShape.ApplyTextureZoom then
		addon.IconShape.ApplyTextureZoom(btn and btn.icon, iconZoom, "_hbIconTexCoord", baseInset)
		return
	end
	if btn and btn.icon and btn.icon.SetTexCoord then btn.icon:SetTexCoord(0, 1, 0, 1) end
end

local function styleSquareButton(btn, color, iconZoom)
	if not btn then return end
	local r, g, b, a = resolveColor(color)
	if btn.icon then
		if Pixel and Pixel.SetTexture then
			Pixel.SetTexture(btn.icon, "Interface\\Buttons\\WHITE8x8")
		else
			btn.icon:SetTexture("Interface\\Buttons\\WHITE8x8")
		end
		applyButtonIconZoom(btn, iconZoom, 0)
		btn.icon:SetVertexColor(r, g, b, a)
		if btn.icon.SetDesaturated then btn.icon:SetDesaturated(false) end
	end
	if btn.border then btn.border:Hide() end
	if btn.dispelIcon then btn.dispelIcon:Hide() end
end

local function styleIconButton(btn)
	if not btn then return end
	if btn.icon then
		btn.icon:SetVertexColor(1, 1, 1, 1)
		if btn.icon.SetDesaturated then btn.icon:SetDesaturated(false) end
	end
end

local function setButtonIconDesaturated(btn, enabled)
	local icon = btn and btn.icon
	if not (icon and icon.SetDesaturated) then return end
	local shouldDesaturate = enabled == true
	if icon._hbDesaturated == shouldDesaturate then return end
	icon:SetDesaturated(shouldDesaturate)
	icon._hbDesaturated = shouldDesaturate
end

local function resolveBorderTexture(key)
	if UFHelper and UFHelper.resolveBorderTexture then return UFHelper.resolveBorderTexture(key) end
	if not key or key == "" or key == "DEFAULT" then return "Interface\\Buttons\\WHITE8x8" end
	return key
end

local function ensureIndicatorBorderFrame(btn)
	if not btn then return nil end
	local border = btn._hbIndicatorBorder
	if not border then
		border = CreateFrame("Frame", nil, btn.overlay or btn, "BackdropTemplate")
		border:EnableMouse(false)
		btn._hbIndicatorBorder = border
	end
	local parent = btn.overlay or btn
	setFrameParentCached(border, parent)
	setFrameStrataCached(border, parent:GetFrameStrata() or btn:GetFrameStrata())
	local baseLevel = parent:GetFrameLevel() or btn:GetFrameLevel() or 0
	setFrameLevelCached(border, baseLevel + 2)
	return border
end

local function applyIndicatorBorder(btn, group)
	if not btn then return end
	local style = tostring(group and group.style or ""):upper()
	local enabled = (style == STYLE_ICON or style == STYLE_SQUARE) and group and group.indicatorBorderEnabled == true
	local border = btn._hbIndicatorBorder
	if not enabled then
		if border then border:Hide() end
		return
	end
	border = ensureIndicatorBorderFrame(btn)
	if not border then return end
	local size = max(1, roundInt(tonumber(group.indicatorBorderSize) or 1))
	local offset = roundInt(tonumber(group.indicatorBorderOffset) or 0)
	if offset > 12 then offset = 12 end
	if offset < -12 then offset = -12 end
	local texture = resolveBorderTexture(group.indicatorBorderTexture or "DEFAULT")
	local key = tostring(texture) .. "|" .. tostring(size)
	if border._hbBackdropKey ~= key then
		border._hbBackdropKey = key
		border:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = texture,
			tile = false,
			edgeSize = size,
			insets = { left = size, right = size, top = size, bottom = size },
		})
	end
	if border._hbOffset ~= offset then
		border._hbOffset = offset
		setTwoPointsCached(border, "TOPLEFT", btn, "TOPLEFT", -offset, offset, "BOTTOMRIGHT", btn, "BOTTOMRIGHT", offset, -offset)
	end
	local br, bg, bb, ba = resolveColor(group.indicatorBorderColor)
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(br, bg, bb, ba)
	border:Show()
end

local function ensureExpirationPulseBorderFrame(btn)
	if not btn then return nil end
	local border = btn._hbExpirationPulseBorder
	if not border then
		border = CreateFrame("Frame", nil, btn.overlay or btn, "BackdropTemplate")
		border:EnableMouse(false)
		btn._hbExpirationPulseBorder = border
	end
	local parent = btn.overlay or btn
	setFrameParentCached(border, parent)
	setFrameStrataCached(border, parent:GetFrameStrata() or btn:GetFrameStrata())
	local baseLevel = parent:GetFrameLevel() or btn:GetFrameLevel() or 0
	setFrameLevelCached(border, baseLevel + 4)
	return border
end

local function hideExpirationPulseBorder(btn)
	local border = btn and btn._hbExpirationPulseBorder
	if border then border:Hide() end
end

local function shouldHideCooldownText(btn, group)
	if btn and btn._hbHideCooldownTextEffective ~= nil then return btn._hbHideCooldownTextEffective == true end
	return group and group.hideCooldownText == true or false
end

local EXPIRATION_PULSE_INTERVAL = 0.05
local updateExpirationPulseButton
local updateDurationColorButton

local function refreshButtonTimedOnUpdate(btn)
	if not btn then return end
	local wantsUpdate = btn._hbExpirationPulseRule ~= nil or btn._hbDurationColorRule ~= nil
	if not wantsUpdate then
		if btn.SetScript and (not btn.GetScript or btn:GetScript("OnUpdate") == btn._hbTimedOnUpdate) then btn:SetScript("OnUpdate", nil) end
		return
	end
	if not btn._hbTimedOnUpdate then
		btn._hbTimedOnUpdate = function(self, elapsed)
			self._hbTimedUpdateElapsed = (self._hbTimedUpdateElapsed or 0) + (elapsed or 0)
			if self._hbTimedUpdateElapsed < EXPIRATION_PULSE_INTERVAL then return end
			self._hbTimedUpdateElapsed = 0
			if updateExpirationPulseButton then updateExpirationPulseButton(self) end
			if updateDurationColorButton then updateDurationColorButton(self) end
		end
	end
	if btn.SetScript then btn:SetScript("OnUpdate", btn._hbTimedOnUpdate) end
end

local function getAuraRemaining(aura, now)
	local expirationTime = aura and tonumber(aura.expirationTime) or nil
	if not (expirationTime and expirationTime > 0) then return nil end
	now = tonumber(now) or ((GetTime and GetTime()) or 0)
	return expirationTime - now
end

local function getDurationColorStep(rule, aura, now)
	local steps = rule and rule.durationColorSteps
	if type(steps) ~= "table" then return nil, nil end
	local remaining = getAuraRemaining(aura, now)
	if not remaining or remaining < 0 then return nil, nil end
	local bestStep, bestSeconds, bestIndex
	for i = 1, DURATION_COLOR_STEP_MAX do
		local step = steps[i]
		local seconds = tonumber(step and step.seconds)
		if seconds and seconds > 0 and remaining <= seconds and (not bestSeconds or seconds < bestSeconds) then
			bestStep = step
			bestSeconds = seconds
			bestIndex = i
		end
	end
	if bestStep then return bestStep.color, bestIndex end
	return nil, nil
end

local function getDisplayColorToken(rule, aura)
	local _, stepIndex = getDurationColorStep(rule, aura)
	return stepIndex and ("step" .. tostring(stepIndex)) or "base"
end

local function clearExpirationPulse(btn, group)
	if not btn then return end
	btn._hbExpirationPulseRule = nil
	btn._hbExpirationPulseAura = nil
	btn._hbExpirationPulseGroup = nil
	btn._hbExpirationPulseThreshold = nil
	btn._hbExpirationPulseCountdownOnly = nil
	btn._hbExpirationPulseElapsed = nil
	hideExpirationPulseBorder(btn)
	if btn.cd and btn.cd.SetHideCountdownNumbers then btn.cd:SetHideCountdownNumbers(shouldHideCooldownText(btn, group)) end
	applyIndicatorBorder(btn, group)
	refreshButtonTimedOnUpdate(btn)
end

local function applyExpirationPulseBorder(btn, group, rule, pulseAlpha)
	local useIndicatorBorder = group and group.indicatorBorderEnabled == true
	local border = useIndicatorBorder and ensureIndicatorBorderFrame(btn) or ensureExpirationPulseBorderFrame(btn)
	if not border then return end
	if useIndicatorBorder then hideExpirationPulseBorder(btn) end
	local pulse = clamp(pulseAlpha, 0, 1, 1) or 1
	local size = roundInt(tonumber(group and group.indicatorBorderSize) or 1)
	if useIndicatorBorder then
		size = max(1, size)
	else
		size = max(2, size)
	end
	local offset = roundInt(tonumber(group and group.indicatorBorderOffset) or 0)
	if offset > 12 then offset = 12 end
	if offset < -12 then offset = -12 end
	local texture = resolveBorderTexture((group and group.indicatorBorderTexture) or "DEFAULT")
	local key = tostring(texture) .. "|" .. tostring(size)
	if border._hbBackdropKey ~= key then
		border._hbBackdropKey = key
		border:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = texture,
			tile = false,
			edgeSize = size,
			insets = { left = size, right = size, top = size, bottom = size },
		})
	end
	if border._hbOffset ~= offset then
		border._hbOffset = offset
		setTwoPointsCached(border, "TOPLEFT", btn, "TOPLEFT", -offset, offset, "BOTTOMRIGHT", btn, "BOTTOMRIGHT", offset, -offset)
	end
	local br, bg, bb, ba = resolveColor((rule and rule.expirationPulseColor) or { 1, 0.2, 0.2, 1 })
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(br, bg, bb, clamp(max(ba or 1, 0.85) * (0.08 + (0.92 * pulse)), 0, 1, 1) or 1)
	border:Show()
end

updateExpirationPulseButton = function(btn)
	local aura = btn and btn._hbExpirationPulseAura
	local group = btn and btn._hbExpirationPulseGroup
	local rule = btn and btn._hbExpirationPulseRule
	if not (btn and aura and group and rule) then return end
	local remaining = getAuraRemaining(aura)
	local threshold = tonumber(btn._hbExpirationPulseThreshold) or 3
	if not remaining or remaining <= 0 then
		clearExpirationPulse(btn, group)
		return
	end
	local inPulse = remaining <= threshold
	if btn.cd and btn.cd.SetHideCountdownNumbers then
		btn.cd:SetHideCountdownNumbers(shouldHideCooldownText(btn, group) or (btn._hbExpirationPulseCountdownOnly == true and not inPulse))
	end
	if not inPulse then
		hideExpirationPulseBorder(btn)
		applyIndicatorBorder(btn, group)
		return
	end
	local pulse = (sin(((threshold - remaining) * 2) * pi) + 1) * 0.5
	applyExpirationPulseBorder(btn, group, rule, pulse)
end

updateDurationColorButton = function(btn)
	local group = btn and btn._hbDurationColorGroup
	local rule = btn and btn._hbDurationColorRule
	local aura = btn and btn._hbDurationColorAura
	if not (btn and group and rule and aura) then return end
	local token = getDisplayColorToken(rule, aura)
	if btn._hbDurationColorToken == token then return end
	btn._hbDurationColorToken = token
	styleSquareButton(btn, getDurationColorStep(rule, aura) or (rule and rule.color) or (group and group.color), group and group.iconZoom)
end

local function clearDurationColorButton(btn)
	if not btn then return end
	btn._hbDurationColorGroup = nil
	btn._hbDurationColorRule = nil
	btn._hbDurationColorAura = nil
	btn._hbDurationColorToken = nil
	refreshButtonTimedOnUpdate(btn)
end

local function applyDurationColorButton(btn, group, rule, aura)
	local style = tostring(group and group.style or ""):upper()
	if not (btn and style == STYLE_SQUARE and rule and type(rule.durationColorSteps) == "table" and aura and tonumber(aura.expirationTime)) then
		clearDurationColorButton(btn)
		return
	end
	btn._hbDurationColorGroup = group
	btn._hbDurationColorRule = rule
	btn._hbDurationColorAura = aura
	btn._hbDurationColorToken = nil
	updateDurationColorButton(btn)
	refreshButtonTimedOnUpdate(btn)
end

local function applyExpirationPulse(btn, group, rule, aura)
	local style = tostring(group and group.style or ""):upper()
	local enabled = (style == STYLE_ICON or style == STYLE_SQUARE) and rule and rule.expirationPulseEnabled == true
	local duration = aura and tonumber(aura.duration) or nil
	local expirationTime = aura and tonumber(aura.expirationTime) or nil
	if not (enabled and duration and duration > 0 and expirationTime and expirationTime > 0) then
		clearExpirationPulse(btn, group)
		return
	end
	btn._hbExpirationPulseRule = rule
	btn._hbExpirationPulseAura = aura
	btn._hbExpirationPulseGroup = group
	btn._hbExpirationPulseThreshold = clamp(rule.expirationPulseThreshold, 1, 10, 3) or 3
	btn._hbExpirationPulseCountdownOnly = rule.expirationPulseCountdownOnly == true
	btn._hbExpirationPulseElapsed = 0
	updateExpirationPulseButton(btn)
	refreshButtonTimedOnUpdate(btn)
end

local function getPlaceholderAura(state, ruleId, familyId, compiled)
	state.tempPlaceholderByRule = state.tempPlaceholderByRule or {}
	local aura = state.tempPlaceholderByRule[ruleId]
	if not aura then
		aura = {}
		state.tempPlaceholderByRule[ruleId] = aura
	end
	local family = HB.ResolveFamily(familyId, compiled)
	local _, icon = ensureFamilyPresentation(family)
	aura.auraInstanceID = (family and family._pseudoAuraInstanceId) or buildRulePseudoAuraId(ruleId)
	aura.icon = icon or 134400
	aura.duration = 0
	aura.expirationTime = nil
	aura.applications = 1
	aura.isSample = true
	aura.spellId = family and family.spellIds and family.spellIds[1] or nil
	return aura
end

local function collectActiveRulesForGroup(state, compiled, groupId, outRules, changedFamilies, maxRules)
	wipeTable(outRules)
	local byGroup = compiled.groupToRuleIds[groupId]
	if not byGroup then return false end
	local force = false
	for i = 1, #byGroup do
		local ruleId = byGroup[i]
		if state.ruleActive[ruleId] then
			outRules[#outRules + 1] = ruleId
			local rule = compiled.ruleById[ruleId]
			if changedFamilies and rule and changedFamilies[rule.spellFamilyId] then force = true end
			if maxRules and #outRules >= maxRules then break end
		end
	end
	return force
end

local function getPriorityActiveRuleForGroup(state, compiled, groupId)
	local byGroup = compiled and compiled.groupToRuleIds and compiled.groupToRuleIds[groupId]
	if not byGroup then return nil, nil end
	for i = 1, #byGroup do
		local ruleId = byGroup[i]
		if state.ruleActive[ruleId] then return compiled.ruleById[ruleId], ruleId end
	end
	return nil, nil
end

local function resolveDisplayColor(group, rule, aura)
	local r, g, b, a = resolveColor(getDurationColorStep(rule, aura) or (rule and rule.color) or (group and group.color))
	if group and normalizeStyle(group.style) == STYLE_BAR and group.barAlpha ~= nil then a = clamp(group.barAlpha, 0, 1, a) or a end
	return r, g, b, a
end

updateDurationColorStatusBar = function(bar)
	local group = bar and bar._hbDurationColorGroup
	local rule = bar and bar._hbDurationColorRule
	local aura = bar and bar._hbDurationColorAura
	if not (bar and group and rule and aura and bar.SetStatusBarColor) then return end
	local token = getDisplayColorToken(rule, aura)
	if bar._hbDurationColorToken == token then return end
	bar._hbDurationColorToken = token
	local r, g, b, a = resolveDisplayColor(group, rule, aura)
	bar:SetStatusBarColor(r, g, b, a)
end

clearBarDurationColorState = function(bar)
	if not bar then return end
	bar._hbDurationColorGroup = nil
	bar._hbDurationColorRule = nil
	bar._hbDurationColorAura = nil
	bar._hbDurationColorToken = nil
	if bar.SetScript and bar._hbTrackedDuration == nil then bar:SetScript("OnUpdate", nil) end
end

local function setBarDurationColorState(bar, group, rule, aura)
	if not (bar and group and rule and type(rule.durationColorSteps) == "table" and aura and tonumber(aura.expirationTime)) then
		clearBarDurationColorState(bar)
		return
	end
	bar._hbDurationColorGroup = group
	bar._hbDurationColorRule = rule
	bar._hbDurationColorAura = aura
	bar._hbDurationColorToken = nil
	updateDurationColorStatusBar(bar)
	if not bar._hbBarOnUpdate then
		bar._hbBarOnUpdate = function(self, elapsed)
			self._hbBarUpdateElapsed = (self._hbBarUpdateElapsed or 0) + (elapsed or 0)
			if self._hbBarUpdateElapsed < BAR_UPDATE_INTERVAL then return end
			self._hbBarUpdateElapsed = 0
			updateAnimatedBarValue(self)
			if updateDurationColorStatusBar then updateDurationColorStatusBar(self) end
		end
	end
	if bar.SetScript then bar:SetScript("OnUpdate", bar._hbBarOnUpdate) end
end

local function didGroupRenderStateChange(cache, compiled, group, activeRules, familyAuraInstance, styleRevision, layoutRevision)
	local changed = cache.groupId ~= group.id
		or cache.groupStyle ~= group.style
		or cache.iconZoom ~= group.iconZoom
		or cache.compiledGeneration ~= compiled.generation
		or cache.styleRevision ~= styleRevision
		or cache.layoutRevision ~= layoutRevision
		or cache.ruleCount ~= #activeRules
		or cache.anchorOutside ~= group.anchorOutside
		or cache.indicatorBorderEnabled ~= group.indicatorBorderEnabled
		or cache.indicatorBorderTexture ~= group.indicatorBorderTexture
		or cache.indicatorBorderSize ~= group.indicatorBorderSize
		or cache.indicatorBorderOffset ~= group.indicatorBorderOffset

	local borderR, borderG, borderB, borderA = resolveColor(group.indicatorBorderColor)
	changed = changed or cache.indicatorBorderR ~= borderR or cache.indicatorBorderG ~= borderG or cache.indicatorBorderB ~= borderB or cache.indicatorBorderA ~= borderA

	if group.style == STYLE_SQUARE then
		local groupR, groupG, groupB, groupA = resolveColor(group.color)
		changed = changed or cache.squareGroupR ~= groupR or cache.squareGroupG ~= groupG or cache.squareGroupB ~= groupB or cache.squareGroupA ~= groupA
		cache.squareGroupR = groupR
		cache.squareGroupG = groupG
		cache.squareGroupB = groupB
		cache.squareGroupA = groupA
	else
		cache.squareGroupR = nil
		cache.squareGroupG = nil
		cache.squareGroupB = nil
		cache.squareGroupA = nil
	end

	local cachedRuleIds = cache.ruleIds or {}
	local cachedAuraIds = cache.auraIds or {}
	cache.ruleIds = cachedRuleIds
	cache.auraIds = cachedAuraIds
	for i = 1, #activeRules do
		local ruleId = activeRules[i]
		local rule = compiled.ruleById[ruleId]
		local familyId = rule and rule.spellFamilyId
		local auraId = familyId and familyAuraInstance and familyAuraInstance[familyId] or 0
		if cachedRuleIds[i] ~= ruleId or cachedAuraIds[i] ~= auraId then changed = true end
		cachedRuleIds[i] = ruleId
		cachedAuraIds[i] = auraId
	end
	for i = #activeRules + 1, cache.ruleCount or 0 do
		if cachedRuleIds[i] ~= nil or cachedAuraIds[i] ~= nil then changed = true end
		cachedRuleIds[i] = nil
		cachedAuraIds[i] = nil
	end

	cache.groupId = group.id
	cache.groupStyle = group.style
	cache.iconZoom = group.iconZoom
	cache.compiledGeneration = compiled.generation
	cache.styleRevision = styleRevision
	cache.layoutRevision = layoutRevision
	cache.ruleCount = #activeRules
	cache.anchorOutside = group.anchorOutside
	cache.indicatorBorderEnabled = group.indicatorBorderEnabled
	cache.indicatorBorderTexture = group.indicatorBorderTexture
	cache.indicatorBorderSize = group.indicatorBorderSize
	cache.indicatorBorderOffset = group.indicatorBorderOffset
	cache.indicatorBorderR = borderR
	cache.indicatorBorderG = borderG
	cache.indicatorBorderB = borderB
	cache.indicatorBorderA = borderA
	return changed
end

local function didBarRenderStateChange(cache, group, groupId, layoutRevision, trackedAura, trackedRuleId, trackedFamilyId, colorRule, colorRuleId, colorAura)
	if not (group and groupId) then
		local changed = cache.active ~= false
		wipeTable(cache)
		cache.active = false
		return changed
	end
	local r, g, b, a = resolveDisplayColor(group, colorRule, colorAura)
	local colorToken = getDisplayColorToken(colorRule, colorAura)
	local trackedAuraInstance = trackedAura and trackedAura.auraInstanceID or nil
	local trackedDuration = trackedAura and tonumber(trackedAura.duration) or nil
	local trackedExpirationTime = trackedAura and tonumber(trackedAura.expirationTime) or nil
	local changed = cache.active ~= true
		or cache.groupId ~= groupId
		or cache.layoutRevision ~= layoutRevision
		or cache.barOrientation ~= group.barOrientation
		or cache.barWidth ~= group.barWidth
		or cache.barHeight ~= group.barHeight
		or cache.barAlpha ~= group.barAlpha
		or cache.barThickness ~= group.barThickness
		or cache.barDrainAnimation ~= group.barDrainAnimation
		or cache.barFillFrame ~= group.barFillFrame
		or cache.barStrata ~= group.barStrata
		or cache.barFrameLevelOffset ~= group.barFrameLevelOffset
		or cache.barReverseFill ~= group.barReverseFill
		or cache.inset ~= group.inset
		or cache.anchorPoint ~= group.anchorPoint
		or cache.anchorOutside ~= group.anchorOutside
		or cache.x ~= group.x
		or cache.y ~= group.y
		or cache.colorRuleId ~= colorRuleId
		or cache.colorToken ~= colorToken
		or cache.r ~= r
		or cache.g ~= g
		or cache.b ~= b
		or cache.a ~= a
	cache.active = true
	cache.groupId = groupId
	cache.layoutRevision = layoutRevision
	cache.barOrientation = group.barOrientation
	cache.barWidth = group.barWidth
	cache.barHeight = group.barHeight
	cache.barAlpha = group.barAlpha
	cache.barThickness = group.barThickness
	cache.barDrainAnimation = group.barDrainAnimation
	cache.barFillFrame = group.barFillFrame
	cache.barStrata = group.barStrata
	cache.barFrameLevelOffset = group.barFrameLevelOffset
	cache.barReverseFill = group.barReverseFill
	cache.inset = group.inset
	cache.anchorPoint = group.anchorPoint
	cache.anchorOutside = group.anchorOutside
	cache.x = group.x
	cache.y = group.y
	cache.colorRuleId = colorRuleId
	cache.colorToken = colorToken
	cache.r = r
	cache.g = g
	cache.b = b
	cache.a = a
	if group.barDrainAnimation == true then
		changed = changed
			or cache.trackedRuleId ~= trackedRuleId
			or cache.trackedFamilyId ~= trackedFamilyId
			or cache.trackedAuraInstance ~= trackedAuraInstance
			or cache.trackedDuration ~= trackedDuration
			or cache.trackedExpirationTime ~= trackedExpirationTime
		cache.trackedRuleId = trackedRuleId
		cache.trackedFamilyId = trackedFamilyId
		cache.trackedAuraInstance = trackedAuraInstance
		cache.trackedDuration = trackedDuration
		cache.trackedExpirationTime = trackedExpirationTime
	else
		cache.trackedRuleId = nil
		cache.trackedFamilyId = nil
		cache.trackedAuraInstance = nil
		cache.trackedDuration = nil
		cache.trackedExpirationTime = nil
	end
	return changed
end

local function didBorderRenderStateChange(cache, group, groupId, layoutRevision, colorRule, colorRuleId, colorAura)
	if not (group and groupId) then
		local changed = cache.active ~= false
		wipeTable(cache)
		cache.active = false
		return changed
	end
	local r, g, b, a = resolveDisplayColor(group, colorRule, colorAura)
	local colorToken = getDisplayColorToken(colorRule, colorAura)
	local changed = cache.active ~= true
		or cache.groupId ~= groupId
		or cache.layoutRevision ~= layoutRevision
		or cache.borderSize ~= group.borderSize
		or cache.borderStrata ~= group.borderStrata
		or cache.borderFrameLevelOffset ~= group.borderFrameLevelOffset
		or cache.inset ~= group.inset
		or cache.anchorPoint ~= group.anchorPoint
		or cache.anchorOutside ~= group.anchorOutside
		or cache.x ~= group.x
		or cache.y ~= group.y
		or cache.colorRuleId ~= colorRuleId
		or cache.colorToken ~= colorToken
		or cache.r ~= r
		or cache.g ~= g
		or cache.b ~= b
		or cache.a ~= a
	cache.active = true
	cache.groupId = groupId
	cache.layoutRevision = layoutRevision
	cache.borderSize = group.borderSize
	cache.borderStrata = group.borderStrata
	cache.borderFrameLevelOffset = group.borderFrameLevelOffset
	cache.inset = group.inset
	cache.anchorPoint = group.anchorPoint
	cache.anchorOutside = group.anchorOutside
	cache.x = group.x
	cache.y = group.y
	cache.colorRuleId = colorRuleId
	cache.colorToken = colorToken
	cache.r = r
	cache.g = g
	cache.b = b
	cache.a = a
	return changed
end

local function didTintRenderStateChange(cache, group, groupId, colorRule, colorRuleId, colorAura)
	if not (group and groupId) then
		local changed = cache.active ~= false
		wipeTable(cache)
		cache.active = false
		return changed
	end
	local r, g, b, a = resolveDisplayColor(group, colorRule, colorAura)
	local colorToken = getDisplayColorToken(colorRule, colorAura)
	local changed = cache.active ~= true or cache.groupId ~= groupId or cache.colorRuleId ~= colorRuleId or cache.colorToken ~= colorToken or cache.r ~= r or cache.g ~= g or cache.b ~= b or cache.a ~= a
	cache.active = true
	cache.groupId = groupId
	cache.colorRuleId = colorRuleId
	cache.colorToken = colorToken
	cache.r = r
	cache.g = g
	cache.b = b
	cache.a = a
	return changed
end

local function renderIconStyleForGroup(btn, st, state, compiled, cfg, group, changedFamilies, renderHashes)
	local container = ensureGroupContainer(state, st, group.id)
	local buttons = state.groupButtons[group.id]
	if not buttons then
		buttons = {}
		state.groupButtons[group.id] = buttons
	end

	local activeRules = state.tempRuleList
	local maxRules = (group.iconMode == ICON_MODE_PRIORITY) and 1 or nil
	local force = collectActiveRulesForGroup(state, compiled, group.id, activeRules, changedFamilies, maxRules)
	local style = getAuraStyleForGroup(state, cfg, group)
	style.tooltipUseEditMode = st and st._tooltipUseEditMode == true
	style.tooltipAnchor = "ANCHOR_RIGHT"
	local styleRevision = style._eqolStyleRevision or 0
	local layoutRevision = st._hbHealerBuffLayoutRevision or 0
	local renderState = renderHashes[group.id]
	if not renderState then
		renderState = {}
		renderHashes[group.id] = renderState
	end
	local renderChanged = didGroupRenderStateChange(renderState, compiled, group, activeRules, state.familyAuraInstance, styleRevision, layoutRevision)
	if not force and not renderChanged then return end

		if #activeRules == 0 then
		container:Hide()
		for i = 1, #buttons do
			clearExpirationPulse(buttons[i], group)
			clearDurationColorButton(buttons[i])
		end
		hideButtons(buttons, 1)
		return
	end

	local primary, secondary = updateGroupContainerLayout(container, group, #activeRules)
	container:Show()
	local unitToken = btn._eqolUnit or "player"
	for index = 1, #activeRules do
		local ruleId = activeRules[index]
		local rule = compiled.ruleById[ruleId]
		local familyId = rule and rule.spellFamilyId
		local aura = familyId and state.familyAura[familyId] or nil
			if not aura then aura = getPlaceholderAura(state, ruleId, familyId, compiled) end
		local auraInstanceId = aura and aura.auraInstanceID
		local button = buttons[index]
		if not button then button = AuraUtil.ensureAuraButton(container, buttons, index, style) end
		if not button then break end
		button._hbHideCooldownTextEffective = style.showCooldownText == false or group.hideCooldownText == true
		button._tooltipUseEditMode = style.tooltipUseEditMode == true
		button._tooltipAnchor = style.tooltipAnchor or "ANCHOR_BOTTOMRIGHT"
		local drawCooldownSwipe = style.showCooldownSwipe ~= false
		if button.cd and button._hbDrawCooldownSwipe ~= drawCooldownSwipe then
			button._hbDrawCooldownSwipe = drawCooldownSwipe
			if button.cd.SetDrawSwipe then button.cd:SetDrawSwipe(drawCooldownSwipe) end
		end
		local drawCooldownEdge = style.showCooldownEdge ~= false
		if button.cd and button._hbDrawCooldownEdge ~= drawCooldownEdge then
			button._hbDrawCooldownEdge = drawCooldownEdge
			if button.cd.SetDrawEdge then button.cd:SetDrawEdge(drawCooldownEdge) end
		end
		local drawCooldownBling = style.showCooldownBling ~= false
		if button.cd and button._hbDrawCooldownBling ~= drawCooldownBling then
			button._hbDrawCooldownBling = drawCooldownBling
			if button.cd.SetDrawBling then button.cd:SetDrawBling(drawCooldownBling) end
		end
		local familyChanged = changedFamilies and familyId and changedFamilies[familyId] == true
		local auraApplied = false
		if familyChanged or button._hbAuraInstance ~= auraInstanceId or button._hbStyleRevision ~= styleRevision or button._hbAppliedVisualMode ~= group.style then
			AuraUtil.applyAuraToButton(button, aura, style, false, unitToken)
			button._hbAuraInstance = auraInstanceId
			button._hbStyleRevision = styleRevision
			button._hbAppliedVisualMode = group.style
			auraApplied = true
		end
		if group.style == STYLE_SQUARE then
			if auraApplied or button._hbVisualMode ~= STYLE_SQUARE or button._hbVisualRuleId ~= ruleId or button._hbVisualGeneration ~= compiled.generation then
				styleSquareButton(button, getDurationColorStep(rule, aura) or (rule and rule.color) or group.color, group.iconZoom)
				button._hbVisualMode = STYLE_SQUARE
				button._hbVisualRuleId = ruleId
				button._hbVisualGeneration = compiled.generation
			end
			if button._hbTooltipShown ~= false then
				AuraUtil.setAuraTooltipState(button, EMPTY)
				button._hbTooltipShown = false
			end
			else
				clearDurationColorButton(button)
				if button._hbVisualMode ~= STYLE_ICON then
					styleIconButton(button)
				button._hbVisualMode = STYLE_ICON
				button._hbVisualRuleId = nil
				button._hbVisualGeneration = compiled.generation
			end
			setButtonIconDesaturated(button, HB.ShouldDesaturateRuleIcon(group, rule))
			local showTooltip = style.showTooltip == true
			if button._hbTooltipShown ~= showTooltip then
				AuraUtil.setAuraTooltipState(button, style)
				button._hbTooltipShown = showTooltip
			end
			end
			applyDurationColorButton(button, group, rule, aura)
			if button._hbIndicatorRevision ~= compiled.generation or button._hbIndicatorGroupId ~= group.id or button._hbIndicatorStyle ~= group.style then
			applyIndicatorBorder(button, group)
			button._hbIndicatorRevision = compiled.generation
			button._hbIndicatorGroupId = group.id
			button._hbIndicatorStyle = group.style
		end
		applyExpirationPulse(button, group, rule, aura)
		if button.SetSize and button._hbButtonSize ~= group.size then
			if AuraUtil and AuraUtil.setAuraButtonSize then
				AuraUtil.setAuraButtonSize(button, group.size)
			else
				setSizeCached(button, group.size, group.size)
				button._eqolAuraButtonSize = group.size
			end
			button._hbButtonSize = group.size
		end
		positionAuraButton(button, container, primary, secondary, index, group.perRow, group.size, group.spacing, group.anchorPoint)
		button:Show()
	end
	for index = #activeRules + 1, #buttons do
		clearExpirationPulse(buttons[index], group)
		clearDurationColorButton(buttons[index])
	end
	hideButtons(buttons, #activeRules + 1)
end

local function hideUnusedGroupContainers(state, activeGroups)
	for groupId, container in pairs(state.groupContainers or EMPTY) do
		if not activeGroups[groupId] then
			if container then container:Hide() end
			local buttons = state.groupButtons and state.groupButtons[groupId]
			if buttons then
				for i = 1, #buttons do
					clearExpirationPulse(buttons[i], nil)
					clearDurationColorButton(buttons[i])
				end
			end
			hideButtons(state.groupButtons and state.groupButtons[groupId], 1)
		end
	end
end

local function winnerForStyle(compiled, groupActive, style)
	local order = compiled.groupOrderByStyle[style]
	if not order then return nil end
	for i = 1, #order do
		local groupId = order[i]
		if groupActive[groupId] then return compiled.groupsById[groupId], groupId end
	end
	return nil
end

local function getTrackedAuraForBarGroup(state, compiled, groupId)
	local ruleIds = compiled and compiled.groupToRuleIds and compiled.groupToRuleIds[groupId]
	if not ruleIds then return nil, nil, nil end
	local fallbackAura, fallbackRuleId, fallbackFamilyId
	for i = 1, #ruleIds do
		local ruleId = ruleIds[i]
		if state.ruleActive[ruleId] then
			local rule = compiled.ruleById[ruleId]
			local familyId = rule and rule.spellFamilyId
			if familyId then
				local aura = state.familyAura[familyId]
				if fallbackRuleId == nil then
					fallbackAura = aura
					fallbackRuleId = ruleId
					fallbackFamilyId = familyId
				end
				if aura and getTimedBarFill(aura.duration, aura.expirationTime) ~= nil then return aura, ruleId, familyId end
			end
		end
	end
	return fallbackAura, fallbackRuleId, fallbackFamilyId
end

local function getStyleAnchoredOffsets(root, group, inset)
	if not (root and group) then return 0, 0 end
	local rootW = root.GetWidth and root:GetWidth() or 0
	local rootH = root.GetHeight and root:GetHeight() or 0
	if rootW <= 0 or rootH <= 0 then return 0, 0 end
	local x, y = group.x or 0, group.y or 0
	if group.anchorOutside ~= true then x, y = HB.ClampOffsets(group.anchorPoint, x, y, rootW, rootH, inset or 0) end
	local scale = getEffectiveScale(root)
	return roundToPixel(x or 0, scale), roundToPixel(y or 0, scale)
end

local function renderBar(bar, st, group, trackedAura, colorRule, colorAura)
	if not bar then return end
	if not group then
		clearAnimatedBarState(bar)
		bar:Hide()
		return
	end
	local scale = getEffectiveScale(st.healerBuffRoot or bar)
	local inset = group.inset or 0
	inset = max(0, roundToPixel(inset, scale))
	local r, g, b, a = resolveDisplayColor(group, colorRule, colorAura)
	local orientation = group.barOrientation == ORIENT_VERTICAL and ORIENT_VERTICAL or ORIENT_HORIZONTAL
	local reverseFill = group.barDrainAnimation == true and group.barReverseFill == true
	local root = st.healerBuffRoot
	local rootWidth = root and root.GetWidth and root:GetWidth() or 0
	local rootHeight = root and root.GetHeight and root:GetHeight() or 0
	local barWidth, barHeight, useSizedPlacement = HB.GetBarDisplaySize(group, rootWidth, rootHeight)
	if bar._hbOrientation ~= orientation then
		bar:SetOrientation(orientation)
		bar._hbOrientation = orientation
	end
	if bar._hbReverseFill ~= reverseFill then
		if UFHelper and UFHelper.applyStatusBarReverseFill then UFHelper.applyStatusBarReverseFill(bar, reverseFill) end
		bar._hbReverseFill = reverseFill
	end
	bar:SetStatusBarColor(r, g, b, a)
	bar:SetMinMaxValues(0, 1)
	if useSizedPlacement then
		local ox, oy = group.x or 0, group.y or 0
		if group.anchorOutside ~= true then ox, oy = HB.ClampOffsetsForRegion(group.anchorPoint, ox, oy, rootWidth, rootHeight, barWidth, barHeight, inset) end
		setSinglePointCached(bar, group.anchorPoint or "CENTER", st.healerBuffRoot, group.anchorPoint or "CENTER", ox, oy)
		setSizeCached(bar, barWidth, barHeight)
		bar._hbBarWidth = nil
		bar._hbBarHeight = nil
	elseif group.barOrientation == ORIENT_VERTICAL then
		local thickness
		if Pixel and Pixel.Round then
			thickness = Pixel.Round(max(1, group.barThickness or 6), bar, 1)
		else
			thickness = max(1, roundToPixel(group.barThickness or 6, scale))
		end
		local ox, oy = getStyleAnchoredOffsets(st.healerBuffRoot, group, inset)
		setTwoPointsCached(bar, "TOP", st.healerBuffRoot, "TOP", ox, oy - inset, "BOTTOM", st.healerBuffRoot, "BOTTOM", ox, oy + inset)
		if bar._hbBarWidth ~= thickness then
			if Pixel and Pixel.SetWidth then
				Pixel.SetWidth(bar, thickness, 1)
			else
				bar:SetWidth(thickness)
			end
			bar._hbBarWidth = thickness
		end
		bar._hbBarHeight = nil
	else
		local thickness
		if Pixel and Pixel.Round then
			thickness = Pixel.Round(max(1, group.barThickness or 6), bar, 1)
		else
			thickness = max(1, roundToPixel(group.barThickness or 6, scale))
		end
		local ox, oy = getStyleAnchoredOffsets(st.healerBuffRoot, group, inset)
		setTwoPointsCached(bar, "LEFT", st.healerBuffRoot, "LEFT", ox + inset, oy, "RIGHT", st.healerBuffRoot, "RIGHT", ox - inset, oy)
		if bar._hbBarHeight ~= thickness then
			if Pixel and Pixel.SetHeight then
				Pixel.SetHeight(bar, thickness, 1)
			else
				bar:SetHeight(thickness)
			end
			bar._hbBarHeight = thickness
		end
		bar._hbBarWidth = nil
	end
	if group.barDrainAnimation == true then
		setAnimatedBarAura(bar, trackedAura)
	else
		clearAnimatedBarState(bar)
		bar:SetValue(1)
	end
	setBarDurationColorState(bar, group, colorRule, colorAura)
	if root then
		local targetStrata = normalizeFrameStrataToken(group.barStrata)
		if not targetStrata and root.GetFrameStrata then targetStrata = root:GetFrameStrata() end
		if targetStrata then setFrameStrataCached(bar, targetStrata) end
		if root.GetFrameLevel then
			local levelOffset = roundInt(clamp(group.barFrameLevelOffset, -20, 1000, 3))
			setFrameLevelCached(bar, (root:GetFrameLevel() or 0) + levelOffset)
		end
	end
	bar:Show()
end

local function updateDurationColorBorder(border)
	local group = border and border._hbDurationColorGroup
	local rule = border and border._hbDurationColorRule
	local aura = border and border._hbDurationColorAura
	if not (border and group and rule and aura and border.SetBackdropBorderColor) then return end
	local token = getDisplayColorToken(rule, aura)
	if border._hbDurationColorToken == token then return end
	border._hbDurationColorToken = token
	local r, g, b, a = resolveDisplayColor(group, rule, aura)
	border:SetBackdropBorderColor(r, g, b, a)
end

clearBorderDurationColorState = function(border)
	if not border then return end
	border._hbDurationColorGroup = nil
	border._hbDurationColorRule = nil
	border._hbDurationColorAura = nil
	border._hbDurationColorToken = nil
	border._hbDurationColorElapsed = nil
	if border.SetScript then border:SetScript("OnUpdate", nil) end
end

local function setBorderDurationColorState(border, group, rule, aura)
	if not (border and group and rule and type(rule.durationColorSteps) == "table" and aura and tonumber(aura.expirationTime)) then
		clearBorderDurationColorState(border)
		return
	end
	border._hbDurationColorGroup = group
	border._hbDurationColorRule = rule
	border._hbDurationColorAura = aura
	border._hbDurationColorToken = nil
	updateDurationColorBorder(border)
	if not border._hbDurationColorOnUpdate then
		border._hbDurationColorOnUpdate = function(self, elapsed)
			self._hbDurationColorElapsed = (self._hbDurationColorElapsed or 0) + (elapsed or 0)
			if self._hbDurationColorElapsed < BAR_UPDATE_INTERVAL then return end
			self._hbDurationColorElapsed = 0
			updateDurationColorBorder(self)
		end
	end
	if border.SetScript then border:SetScript("OnUpdate", border._hbDurationColorOnUpdate) end
end

local function renderBorder(st, group, colorRule, colorAura)
	local border = st.healerBuffBorder
	if not border then return end
	if not group then
		clearBorderDurationColorState(border)
		border:Hide()
		return
	end
	local root = st.healerBuffRoot
	local layerBase = st.barGroup or (root and root.GetParent and root:GetParent()) or root
	if root and layerBase then
		local targetStrata = normalizeFrameStrataToken(group.borderStrata)
		if not targetStrata and layerBase.GetFrameStrata then targetStrata = layerBase:GetFrameStrata() end
		if targetStrata then setFrameStrataCached(border, targetStrata) end
		if layerBase.GetFrameLevel then
			local levelOffset = roundInt(clamp(group.borderFrameLevelOffset, -20, 1000, 16))
			setFrameLevelCached(border, (layerBase:GetFrameLevel() or 0) + levelOffset)
		end
	end
	local inset = group.inset or 0
	local size = max(1, group.borderSize or 1)
	local r, g, b, a = resolveDisplayColor(group, colorRule, colorAura)
	local ox, oy = getStyleAnchoredOffsets(st.healerBuffRoot, group, inset)
	setTwoPointsCached(border, "TOPLEFT", st.healerBuffRoot, "TOPLEFT", ox + inset, oy - inset, "BOTTOMRIGHT", st.healerBuffRoot, "BOTTOMRIGHT", ox - inset, oy + inset)
	local key = tostring(size)
	if border._hbBackdropKey ~= key then
		border._hbBackdropKey = key
		border:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8",
			edgeFile = "Interface\\Buttons\\WHITE8x8",
			tile = false,
			edgeSize = size,
			insets = { left = 0, right = 0, top = 0, bottom = 0 },
		})
	end
	border:SetBackdropColor(0, 0, 0, 0)
	border:SetBackdropBorderColor(r, g, b, a)
	setBorderDurationColorState(border, group, colorRule, colorAura)
	border:Show()
end

function HB.ApplyHealthTint(st, r, g, b, a)
	local strength = st and st._hbHealthTintA
	if not strength then return r, g, b, a end
	strength = clamp(strength, 0, 1, 0) or 0
	if strength <= 0 then return r, g, b, a end
	local tr = st._hbHealthTintR or r
	local tg = st._hbHealthTintG or g
	local tb = st._hbHealthTintB or b
	if strength >= 1 then return tr, tg, tb, a end
	local inv = 1 - strength
	return (r * inv) + (tr * strength), (g * inv) + (tg * strength), (b * inv) + (tb * strength), a
end

local function updateDurationColorTint(root)
	local st = root and root._hbTintDurationColorStateRef
	local btn = root and root._hbTintDurationColorButton
	local group = root and root._hbTintDurationColorGroup
	local rule = root and root._hbTintDurationColorRule
	local aura = root and root._hbTintDurationColorAura
	if not (root and st and group and rule and aura) then return end
	local token = getDisplayColorToken(rule, aura)
	if root._hbTintDurationColorToken == token then return end
	root._hbTintDurationColorToken = token
	local r, g, b, a = resolveDisplayColor(group, rule, aura)
	a = clamp(a, 0, 1, 1) or 1
	if st._hbHealthTintR ~= r or st._hbHealthTintG ~= g or st._hbHealthTintB ~= b or st._hbHealthTintA ~= a then
		st._hbHealthTintR, st._hbHealthTintG, st._hbHealthTintB, st._hbHealthTintA = r, g, b, a
		if btn and UF and UF.GroupFrames and UF.GroupFrames.UpdateHealthStyle then UF.GroupFrames:UpdateHealthStyle(btn) end
	end
end

clearTintDurationColorState = function(st)
	local root = st and st.healerBuffRoot
	if not root then return end
	root._hbTintDurationColorStateRef = nil
	root._hbTintDurationColorButton = nil
	root._hbTintDurationColorGroup = nil
	root._hbTintDurationColorRule = nil
	root._hbTintDurationColorAura = nil
	root._hbTintDurationColorToken = nil
	root._hbTintDurationColorElapsed = nil
	if root.SetScript and (not root.GetScript or root:GetScript("OnUpdate") == root._hbTintDurationColorOnUpdate) then root:SetScript("OnUpdate", nil) end
end

local function setTintDurationColorState(btn, st, group, rule, aura)
	local root = st and st.healerBuffRoot
	if not (root and group and rule and type(rule.durationColorSteps) == "table" and aura and tonumber(aura.expirationTime)) then
		clearTintDurationColorState(st)
		return
	end
	root._hbTintDurationColorStateRef = st
	root._hbTintDurationColorButton = btn
	root._hbTintDurationColorGroup = group
	root._hbTintDurationColorRule = rule
	root._hbTintDurationColorAura = aura
	root._hbTintDurationColorToken = nil
	updateDurationColorTint(root)
	if not root._hbTintDurationColorOnUpdate then
		root._hbTintDurationColorOnUpdate = function(self, elapsed)
			self._hbTintDurationColorElapsed = (self._hbTintDurationColorElapsed or 0) + (elapsed or 0)
			if self._hbTintDurationColorElapsed < TINT_UPDATE_INTERVAL then return end
			self._hbTintDurationColorElapsed = 0
			updateDurationColorTint(self)
		end
	end
	if root.SetScript then root:SetScript("OnUpdate", root._hbTintDurationColorOnUpdate) end
end

local function renderTint(btn, st, group, colorRule, colorAura)
	local tint = st and st.healerBuffTint
	local changed = false
	if tint then tint:Hide() end
	if not group then
		clearTintDurationColorState(st)
		changed = clearHealthTint(st)
	else
		local r, g, b, a = resolveDisplayColor(group, colorRule, colorAura)
		a = clamp(a, 0, 1, 1) or 1
		if st._hbHealthTintR ~= r or st._hbHealthTintG ~= g or st._hbHealthTintB ~= b or st._hbHealthTintA ~= a then
			st._hbHealthTintR, st._hbHealthTintG, st._hbHealthTintB, st._hbHealthTintA = r, g, b, a
			changed = true
		end
		setTintDurationColorState(btn, st, group, colorRule, colorAura)
	end
	if changed and btn and UF and UF.GroupFrames and UF.GroupFrames.UpdateHealthStyle then UF.GroupFrames:UpdateHealthStyle(btn) end
end

local function hideUnusedBars(state, activeBars, renderHashes)
	for groupId, bar in pairs(state.groupBars or EMPTY) do
			if not activeBars[groupId] then
				clearAnimatedBarState(bar)
				if clearBarDurationColorState then clearBarDurationColorState(bar) end
				bar:Hide()
				if renderHashes then renderHashes[groupId] = nil end
		end
	end
end

local function renderBarGroups(st, state, compiled, layoutRevision, renderHashes)
	local activeBars = {}
	for i = 1, #compiled.groupOrder do
		local groupId = compiled.groupOrder[i]
		local group = compiled.groupsById[groupId]
			if group and group.style == STYLE_BAR and state.groupActive[groupId] then
				activeBars[groupId] = true
				local bar = ensureBarForGroup(state, st, groupId)
				local barTrackedAura, barTrackedRuleId, barTrackedFamilyId
				local barColorRule, barColorRuleId = getPriorityActiveRuleForGroup(state, compiled, groupId)
				local barColorAura = barColorRule and barColorRule.spellFamilyId and state.familyAura[barColorRule.spellFamilyId] or nil
				if group.barDrainAnimation == true then barTrackedAura, barTrackedRuleId, barTrackedFamilyId = getTrackedAuraForBarGroup(state, compiled, groupId) end
				local renderState = renderHashes[groupId]
			if not renderState then
				renderState = {}
				renderHashes[groupId] = renderState
			end
				if didBarRenderStateChange(renderState, group, groupId, layoutRevision, barTrackedAura, barTrackedRuleId, barTrackedFamilyId, barColorRule, barColorRuleId, barColorAura) then
					renderBar(bar, st, group, barTrackedAura, barColorRule, barColorAura)
				end
			end
	end
	hideUnusedBars(state, activeBars, renderHashes)
	if st.healerBuffBar and st.healerBuffBar:IsShown() then
		clearAnimatedBarState(st.healerBuffBar)
		if clearBarDurationColorState then clearBarDurationColorState(st.healerBuffBar) end
		st.healerBuffBar:Hide()
	end
end

local function renderAll(btn, st, state, compiled, cfg, changedFamilies)
	local renderHash = state.renderHashByStyle
	renderHash[STYLE_ICON] = renderHash[STYLE_ICON] or {}
	renderHash[STYLE_SQUARE] = renderHash[STYLE_SQUARE] or {}
	renderHash[STYLE_BAR] = renderHash[STYLE_BAR] or {}
	renderHash[STYLE_BORDER] = renderHash[STYLE_BORDER] or {}
	renderHash[STYLE_TINT] = renderHash[STYLE_TINT] or {}
	local layoutRevision = st._hbHealerBuffLayoutRevision or 0

	local activeContainers = {}
	for i = 1, #compiled.groupOrder do
		local groupId = compiled.groupOrder[i]
		local group = compiled.groupsById[groupId]
		if group and (group.style == STYLE_ICON or group.style == STYLE_SQUARE) then
				if state.groupActive[groupId] then
					activeContainers[groupId] = true
					renderIconStyleForGroup(btn, st, state, compiled, cfg, group, changedFamilies, renderHash[group.style])
				else
					local container = state.groupContainers[groupId]
					if container then container:Hide() end
					local buttons = state.groupButtons[groupId]
					if buttons then
						for i = 1, #buttons do
							clearExpirationPulse(buttons[i], group)
							clearDurationColorButton(buttons[i])
						end
					end
					hideButtons(state.groupButtons[groupId], 1)
					renderHash[group.style][groupId] = nil
				end
		end
	end
	hideUnusedGroupContainers(state, activeContainers)

	local borderGroup, borderGroupId = winnerForStyle(compiled, state.groupActive, STYLE_BORDER)
	local tintGroup, tintGroupId = winnerForStyle(compiled, state.groupActive, STYLE_TINT)
	local borderColorRule, borderColorRuleId = getPriorityActiveRuleForGroup(state, compiled, borderGroupId)
	local tintColorRule, tintColorRuleId = getPriorityActiveRuleForGroup(state, compiled, tintGroupId)
	local borderColorAura = borderColorRule and borderColorRule.spellFamilyId and state.familyAura[borderColorRule.spellFamilyId] or nil
	local tintColorAura = tintColorRule and tintColorRule.spellFamilyId and state.familyAura[tintColorRule.spellFamilyId] or nil

	renderBarGroups(st, state, compiled, layoutRevision, renderHash[STYLE_BAR])

	if didBorderRenderStateChange(renderHash[STYLE_BORDER], borderGroup, borderGroupId, layoutRevision, borderColorRule, borderColorRuleId, borderColorAura) then renderBorder(st, borderGroup, borderColorRule, borderColorAura) end

	if didTintRenderStateChange(renderHash[STYLE_TINT], tintGroup, tintGroupId, tintColorRule, tintColorRuleId, tintColorAura) then renderTint(btn, st, tintGroup, tintColorRule, tintColorAura) end
end

function HB.BuildButton(btn)
	local state, st = getState(btn)
	if not (state and st) then return end
	ensureVisualLayers(btn, st, true)
end

function HB.LayoutButton(btn)
	local state, st = getState(btn)
	if not (state and st) then return end
	ensureVisualLayers(btn, st, true)
end

function HB.ClearButton(btn)
	local state, st = getState(btn)
	if not (state and st) then return end
	resetState(state)
	hideAllVisuals(btn, st, state)
end

function HB.UpdateFromAuras(btn, updateInfo, cache, changed, isFullUpdate, compiledOverride)
	local state, st = getState(btn)
	if not (state and st and btn) then return end
	local kind = normalizeKind(btn._eqolGroupKind or KIND_PARTY)
	local cfg = btn._eqolCfg
	if not cfg then return end
	local compiled = compiledOverride or compile(kind, cfg)
	if not (compiled and compiled.enabled) then
		HB.ClearButton(btn)
		return
	end

	ensureVisualLayersForUpdate(btn, st)
	local unit = btn._eqolUnit
	if unit == nil or unit == "" then
		HB.ClearButton(btn)
		return
	end

	if isFullUpdate or not updateInfo then
		rebuildFamilyStateFromCache(state, compiled, cache, unit)
		evaluateAllRulesAndGroups(state, compiled, unit)
		wipeTable(state.changedFamilies)
		for familyId in pairs(state.familyCounts) do
			state.changedFamilies[familyId] = true
		end
		renderAll(btn, st, state, compiled, cfg, state.changedFamilies)
		return
	end

	local changedFamilies = applyDeltaToFamilyState(state, compiled, cache, updateInfo, unit)
	if not next(changedFamilies) then return end
	evaluateDeltaRulesAndGroups(state, compiled, changedFamilies, unit)
	renderAll(btn, st, state, compiled, cfg, changedFamilies)
end

local function buildSampleState(state, compiled)
	local sampleRuleActive = state.tempSampleRuleActive
	local sampleGroupActive = state.tempSampleGroupActive
	local sampleFamilyAura = state.tempSampleFamilyAura
	local sampleFamilyAuraInstance = state.tempSampleFamilyAuraInstance
	local sampleFamilyCounts = state.tempSampleFamilyCounts

	wipeTable(sampleRuleActive)
	wipeTable(sampleGroupActive)
	wipeTable(sampleFamilyAura)
	wipeTable(sampleFamilyAuraInstance)
	wipeTable(sampleFamilyCounts)

	for i = 1, #compiled.groupOrder do
		local groupId = compiled.groupOrder[i]
		local group = compiled.groupsById and compiled.groupsById[groupId]
		local enabledRules = compiled.groupToEnabledRuleIds[groupId]
		if enabledRules and #enabledRules > 0 then
			local anyPicked = nil
			local isPriorityOnly = group and (group.style == STYLE_ICON or group.style == STYLE_SQUARE) and group.iconMode == ICON_MODE_PRIORITY
			for j = 1, #enabledRules do
				local ruleId = enabledRules[j]
				local rule = compiled.ruleById[ruleId]
				if rule then
					sampleRuleActive[ruleId] = true
					local familyId = rule.spellFamilyId
					if familyId then
						sampleFamilyCounts[familyId] = 1
						sampleFamilyAuraInstance[familyId] = rule._pseudoAuraInstanceId
						sampleFamilyAura[familyId] = getPlaceholderAura(state, ruleId, familyId, compiled)
					end
					if not anyPicked then anyPicked = ruleId end
					if isPriorityOnly then break end
				end
			end
			if anyPicked then sampleGroupActive[groupId] = true end
		end
	end

	return sampleRuleActive, sampleGroupActive, sampleFamilyAura, sampleFamilyAuraInstance, sampleFamilyCounts
end

function HB.UpdateSample(btn)
	local state, st = getState(btn)
	if not (state and st and btn) then return end
	local kind = normalizeKind(btn._eqolGroupKind or KIND_PARTY)
	local cfg = btn._eqolCfg
	if not cfg then return end
	local compiled = compile(kind, cfg)
	if not (compiled and compiled.enabled) then
		HB.ClearButton(btn)
		return
	end
	ensureVisualLayersForUpdate(btn, st)

	local sampleRuleActive, sampleGroupActive, sampleFamilyAura, sampleFamilyAuraInstance = buildSampleState(state, compiled)
	state.ruleActive = sampleRuleActive
	state.groupActive = sampleGroupActive
	state.familyAura = sampleFamilyAura
	state.familyAuraInstance = sampleFamilyAuraInstance

	wipeTable(state.changedFamilies)
	for familyId in pairs(sampleFamilyAura) do
		state.changedFamilies[familyId] = true
	end
	renderAll(btn, st, state, compiled, cfg, state.changedFamilies)
end

local ANCHOR_COORDS = {
	TOPLEFT = { -0.5, 0.5 },
	TOP = { 0, 0.5 },
	TOPRIGHT = { 0.5, 0.5 },
	LEFT = { -0.5, 0 },
	CENTER = { 0, 0 },
	RIGHT = { 0.5, 0 },
	BOTTOMLEFT = { -0.5, -0.5 },
	BOTTOM = { 0, -0.5 },
	BOTTOMRIGHT = { 0.5, -0.5 },
}

function HB.ClampOffsets(anchorPoint, x, y, frameW, frameH, inset)
	anchorPoint = normalizeAnchor(anchorPoint)
	frameW = tonumber(frameW) or 0
	frameH = tonumber(frameH) or 0
	if frameW <= 0 then frameW = 200 end
	if frameH <= 0 then frameH = 100 end
	inset = clamp(inset, 0, min(frameW, frameH) * 0.5, 0) or 0

	local anchor = ANCHOR_COORDS[anchorPoint] or ANCHOR_COORDS.CENTER
	local anchorX = (anchor[1] or 0) * frameW
	local anchorY = (anchor[2] or 0) * frameH
	local minX = (-frameW * 0.5 + inset) - anchorX
	local maxX = (frameW * 0.5 - inset) - anchorX
	local minY = (-frameH * 0.5 + inset) - anchorY
	local maxY = (frameH * 0.5 - inset) - anchorY

	x = clamp(x, minX, maxX, 0) or 0
	y = clamp(y, minY, maxY, 0) or 0
	return roundInt(x), roundInt(y)
end

function HB.ClampOffsetsForRegion(anchorPoint, x, y, frameW, frameH, regionW, regionH, inset)
	anchorPoint = normalizeAnchor(anchorPoint)
	frameW = tonumber(frameW) or 0
	frameH = tonumber(frameH) or 0
	if frameW <= 0 then frameW = 200 end
	if frameH <= 0 then frameH = 100 end
	inset = clamp(inset, 0, min(frameW, frameH) * 0.5, 0) or 0

	local maxRegionW = max(1, frameW - (inset * 2))
	local maxRegionH = max(1, frameH - (inset * 2))
	regionW = clamp(regionW, 1, maxRegionW, maxRegionW) or maxRegionW
	regionH = clamp(regionH, 1, maxRegionH, maxRegionH) or maxRegionH

	local anchor = ANCHOR_COORDS[anchorPoint] or ANCHOR_COORDS.CENTER
	local fx = (anchor[1] or 0) + 0.5
	local fy = (anchor[2] or 0) + 0.5

	local minX = inset + (fx * (regionW - frameW))
	local maxX = ((1 - fx) * (frameW - regionW)) - inset
	local minY = inset + (fy * (regionH - frameH))
	local maxY = ((1 - fy) * (frameH - regionH)) - inset

	x = clamp(x, minX, maxX, 0) or 0
	y = clamp(y, minY, maxY, 0) or 0
	return roundInt(x), roundInt(y)
end

function HB.GetBarDisplaySize(group, rootWidth, rootHeight)
	if type(group) ~= "table" then return 0, 0, false, false end
	rootWidth = tonumber(rootWidth) or 0
	rootHeight = tonumber(rootHeight) or 0
	if rootWidth <= 0 then rootWidth = 200 end
	if rootHeight <= 0 then rootHeight = 100 end

	local inset = clamp(group.inset, 0, min(rootWidth, rootHeight) * 0.5, 0) or 0
	local availableWidth = max(1, rootWidth - (inset * 2))
	local availableHeight = max(1, rootHeight - (inset * 2))
	local orientation = normalizeOrientation(group.barOrientation)
	local thickness = roundInt(clamp(group.barThickness, 1, BAR_SIZE_MAX, 6))
	local fillFrame = group.barFillFrame == true
	local useSizedPlacement = fillFrame or group.barWidth ~= nil or group.barHeight ~= nil
	local width = clamp(group.barWidth, 1, BAR_SIZE_MAX, nil)
	local height = clamp(group.barHeight, 1, BAR_SIZE_MAX, nil)

	if fillFrame then
		width = availableWidth
		height = availableHeight
	else
		if width == nil then width = orientation == ORIENT_VERTICAL and thickness or availableWidth end
		if height == nil then height = orientation == ORIENT_VERTICAL and availableHeight or thickness end
	end

	width = roundInt(clamp(width, 1, availableWidth, availableWidth))
	height = roundInt(clamp(height, 1, availableHeight, availableHeight))
	return width, height, useSizedPlacement, fillFrame
end

function HB.GetGrowthAxes(growth)
	local first, second = getGrowthAxes(growth)
	return first, second
end

function HB.GetCompiled(kind, cfg)
	if not cfg then return nil end
	return compile(kind, cfg)
end

function HB.GetCompiledPositiveSpellIDs(compiled, suppressedOnly)
	if not compiled then return nil end
	local source = suppressedOnly == true and compiled.suppressedPositiveSpellIDs or compiled.positiveSpellIDs
	if type(source) ~= "table" then return nil end
	local spellIDs = {}
	for spellId, enabled in pairs(source) do
		if enabled == true then spellIDs[spellId] = true end
	end
	return spellIDs
end

function HB.GetManagedSuppressedSpellIDs(compiled)
	if not compiled then return nil end
	local spellIDs = {}
	for spellId, enabled in pairs(compiled.suppressedPositiveSpellIDs or EMPTY) do
		local familyId = compiled.spellToFamily and compiled.spellToFamily[spellId]
		if enabled == true and (familyId == nil or canPlayerProvideFamilyCached(familyId, compiled)) then spellIDs[spellId] = true end
	end
	return spellIDs
end

function HB.CompiledNeedsWideHelpfulScan(compiled) return compiled and compiled.needsWideHelpfulScan == true or false end
