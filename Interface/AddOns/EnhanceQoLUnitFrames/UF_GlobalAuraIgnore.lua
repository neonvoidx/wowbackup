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

UF.GlobalAuraIgnore = UF.GlobalAuraIgnore or {}
local GAI = UF.GlobalAuraIgnore

local ipairs = ipairs
local pairs = pairs
local next = next
local tostring = tostring
local tonumber = tonumber
local tinsert = table.insert
local sort = table.sort
local wipe = _G.wipe or (table and table.wipe)
local issecretvalue = _G.issecretvalue
local LOCALIZED_CLASS_NAMES_MALE = _G.LOCALIZED_CLASS_NAMES_MALE or {}
local LOCALIZED_CLASS_NAMES_FEMALE = _G.LOCALIZED_CLASS_NAMES_FEMALE or {}

local UNIT_CONTEXT_ORDER = {
	"player",
	"target",
	"focus",
	"party",
	"raid",
}

local UNIT_CONTEXT_LOOKUP = {
	player = true,
	target = true,
	focus = true,
	party = true,
	raid = true,
}

local DEFAULT_SPECIAL_DEBUFFS = {
	challengeTime = true,
	classUtility = false,
	satedExhaustion = true,
	deserter = true,
	skyridingUtility = false,
}

local SPECIAL_DEBUFF_GROUPS = {
	{
		key = "challengeTime",
		labelKey = "UFGlobalAuraIgnoreChallengeTime",
		fallbackLabel = "Challenge/Instance Debuffs",
		spellIds = { 206151, 308312, 1254550 },
	},
	{
		key = "classUtility",
		labelKey = "UFGlobalAuraIgnoreClassUtility",
		fallbackLabel = "Class/Utility Auras",
		spellIds = { 124255, 405189, 462742, 462757, 1217607 },
		matrixGroups = {
			{ classToken = "DEMONHUNTER", spellIds = { 1217607 } },
			{ classToken = "DRUID", spellIds = { 405189 } },
			{ classToken = "MONK", spellIds = { 124255 } },
			{ classToken = "SHAMAN", spellIds = { 462742, 462757 } },
		},
	},
	{
		key = "satedExhaustion",
		labelKey = "UFGlobalAuraIgnoreSatedExhaustion",
		fallbackLabel = "Sated/Exhaustion Debuffs",
		spellIds = { 57723, 57724, 80354, 95809, 160455, 264689, 390435 },
		matrixRows = {
			{
				labelSpellId = 2825,
				fallbackLabel = "Bloodlust",
				iconSpellId = 2825,
				spellIds = { 57723, 57724, 80354, 95809, 160455, 264689, 390435 },
			},
		},
	},
	{
		key = "deserter",
		labelKey = "UFGlobalAuraIgnoreDeserter",
		fallbackLabel = "Deserter Debuffs",
		spellIds = { 26013, 71041 },
	},
	{
		key = "skyridingUtility",
		labelKey = "UFGlobalAuraIgnoreSkyridingUtility",
		fallbackLabel = "Skyriding/Ride Along Auras",
		spellIds = { 369968, 377234, 388367, 404464, 404468, 418590, 427490, 447959, 447960 },
		matrixRows = {
			{ spellIds = { 369968 } },
			{ spellIds = { 377234 } },
			{ spellIds = { 388367 } },
			{ spellIds = { 404464 } },
			{ spellIds = { 404468 } },
			{ spellIds = { 418590 } },
			{
				label = "Ride Along",
				iconSpellId = 427490,
				spellIds = { 427490, 447959, 447960 },
			},
		},
	},
}

local SPECIAL_DEBUFF_SETS = {}
for i = 1, #SPECIAL_DEBUFF_GROUPS do
	local group = SPECIAL_DEBUFF_GROUPS[i]
	local set = {}
	for j = 1, #(group.spellIds or {}) do
		local spellId = tonumber(group.spellIds[j])
		if spellId and spellId > 0 then set[spellId] = true end
	end
	SPECIAL_DEBUFF_SETS[group.key] = set
end

local familyEntryList
local familyEntryById

local MATRIX_FAMILY_COMBINES = {
	evoker_pres_dream_breath = { "evoker_pres_dream_breath", "evoker_pres_echo_dream_breath" },
	evoker_pres_reversion = { "evoker_pres_reversion", "evoker_pres_echo_reversion" },
}

local MATRIX_FAMILY_COMBINE_MEMBER = {}
for primaryFamilyId, familyIds in pairs(MATRIX_FAMILY_COMBINES) do
	for i = 1, #familyIds do
		MATRIX_FAMILY_COMBINE_MEMBER[familyIds[i]] = primaryFamilyId
	end
end

local function tr(key, fallback)
	local value = L and L[key]
	if value == nil or value == "" then return fallback or key end
	return value
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

local function getClassLabel(classToken)
	if classToken and classToken ~= "" then
		if LOCALIZED_CLASS_NAMES_MALE[classToken] then return LOCALIZED_CLASS_NAMES_MALE[classToken] end
		if LOCALIZED_CLASS_NAMES_FEMALE[classToken] then return LOCALIZED_CLASS_NAMES_FEMALE[classToken] end
		return tostring(classToken)
	end
	return tr("Other", "Other")
end

local function getUnitContextLabel(context)
	if context == "player" then return PLAYER or "Player" end
	if context == "target" then return TARGET or "Target" end
	if context == "focus" then return FOCUS or "Focus" end
	if context == "party" then return PARTY or "Party" end
	if context == "raid" then return RAID or "Raid" end
	return tostring(context or "")
end

local function getFamilyFromSpell(spellId)
	local hb = UF and UF.GroupFramesHealerBuffs
	if hb and hb.GetFamilyFromSpell then return hb.GetFamilyFromSpell(spellId) end
	return nil
end

local function buildFamilyEntries()
	local hb = UF and UF.GroupFramesHealerBuffs
	if not (hb and hb.FAMILY_ORDER and hb.FAMILY_BY_ID) then return {}, {} end

	local entries = {}
	local byId = {}
	local classBuckets = {}
	local classOrder = {}
	local classSeen = {}
	local helper = UF and UF.GroupFramesHelper
	local preferredClassOrder = (helper and helper.CLASS_TOKENS) or {}

	for i = 1, #preferredClassOrder do
		local token = preferredClassOrder[i]
		if token and not classSeen[token] then
			classSeen[token] = true
			classOrder[#classOrder + 1] = token
		end
	end

	local function ensureBucket(token)
		token = token or "OTHER"
		if not classBuckets[token] then classBuckets[token] = {} end
		if not classSeen[token] then
			classSeen[token] = true
			classOrder[#classOrder + 1] = token
		end
		return classBuckets[token]
	end

	for i = 1, #hb.FAMILY_ORDER do
		local familyId = hb.FAMILY_ORDER[i]
		local family = hb.FAMILY_BY_ID[familyId]
		if family then
			local spellIds = {}
			local rawSpellIds = family.spellIds or {}
			for j = 1, #rawSpellIds do
				local spellId = tonumber(rawSpellIds[j])
				if spellId and spellId > 0 then spellIds[#spellIds + 1] = spellId end
			end
			local primarySpellId = spellIds[1]
			local resolvedName = getSpellName(primarySpellId) or family.fallbackName or family.id or tostring(familyId)
			local specPrefix = family.spec and family.spec ~= "" and (tostring(family.spec) .. ": ") or ""
			local label = string.format("%s%s", specPrefix, tostring(resolvedName))
			local entry = {
				familyId = tostring(familyId),
				classToken = family.classToken or "OTHER",
				classLabel = getClassLabel(family.classToken),
				label = label,
				spellIds = spellIds,
			}
			tinsert(ensureBucket(entry.classToken), entry)
			byId[entry.familyId] = entry
		end
	end

	local sortedClassOrder = {}
	for i = 1, #classOrder do
		local token = classOrder[i]
		if classBuckets[token] and #classBuckets[token] > 0 then sortedClassOrder[#sortedClassOrder + 1] = token end
	end
	for token, bucket in pairs(classBuckets) do
		if #bucket > 0 then
			local present = false
			for i = 1, #sortedClassOrder do
				if sortedClassOrder[i] == token then
					present = true
					break
				end
			end
			if not present then sortedClassOrder[#sortedClassOrder + 1] = token end
		end
	end

	sort(sortedClassOrder, function(a, b)
		local aIdx = nil
		local bIdx = nil
		for i = 1, #classOrder do
			if aIdx == nil and classOrder[i] == a then aIdx = i end
			if bIdx == nil and classOrder[i] == b then bIdx = i end
		end
		if aIdx and bIdx then return aIdx < bIdx end
		if aIdx then return true end
		if bIdx then return false end
		return tostring(a) < tostring(b)
	end)

	for i = 1, #sortedClassOrder do
		local token = sortedClassOrder[i]
		local bucket = classBuckets[token]
		tinsert(entries, {
			isHeader = true,
			classToken = token,
			label = getClassLabel(token),
		})
		sort(bucket, function(a, b) return tostring(a.label) < tostring(b.label) end)
		for j = 1, #bucket do
			tinsert(entries, bucket[j])
		end
	end

	return entries, byId
end

local function getFamilyEntries()
	if not familyEntryList then
		familyEntryList, familyEntryById = buildFamilyEntries()
	end
	return familyEntryList, familyEntryById
end

local function createDefaultSpecialDebuffs()
	local out = {}
	for key, defaultValue in pairs(DEFAULT_SPECIAL_DEBUFFS) do
		out[key] = defaultValue == true
	end
	return out
end

local function createDefaultConfig()
	local function createDefaultBucket()
		return {
			allowedSpells = {},
			ignoredFamilies = {},
			ignoredSpells = {},
			specialDebuffs = createDefaultSpecialDebuffs(),
		}
	end

	return {
		enabled = false,
		version = 2,
		customSpells = {},
		byContext = {
			party = createDefaultBucket(),
			raid = createDefaultBucket(),
		},
	}
end

GAI.CreateDefaultConfig = createDefaultConfig

local function hasAnyEnabledValues(map)
	if type(map) ~= "table" then return false end
	for _, value in pairs(map) do
		if value == true then return true end
	end
	return false
end

local function normalizeFamilySet(source, knownById)
	local out = {}
	if type(source) ~= "table" then return out end
	for key, value in pairs(source) do
		if value == true then
			local familyId = tostring(key)
			if not knownById or knownById[familyId] then out[familyId] = true end
		end
	end
	return out
end

local function normalizeSpellSet(source)
	local out = {}
	if type(source) ~= "table" then return out end
	for key, value in pairs(source) do
		local spellId
		if value == true or value == 1 then
			spellId = tonumber(key)
		elseif type(value) == "number" then
			spellId = tonumber(value)
		end
		if spellId and spellId > 0 then out[spellId] = true end
	end
	return out
end

local function normalizeSpecialSet(source)
	local out = {}
	for key, defaultValue in pairs(DEFAULT_SPECIAL_DEBUFFS) do
		if type(source) == "table" then
			if source[key] == nil then
				out[key] = defaultValue == true
			else
				out[key] = source[key] == true
			end
		else
			out[key] = defaultValue == true
		end
	end
	return out
end

local function normalizeContextBucket(cfg, context, knownById)
	context = GAI.ResolveContext(context) or context
	if not UNIT_CONTEXT_LOOKUP[context] then return nil end
	cfg.byContext = type(cfg.byContext) == "table" and cfg.byContext or {}
	local bucket = cfg.byContext[context]
	if type(bucket) ~= "table" then bucket = {} end
	bucket.allowedSpells = normalizeSpellSet(bucket.allowedSpells)
	bucket.ignoredFamilies = normalizeFamilySet(bucket.ignoredFamilies, knownById)
	bucket.ignoredSpells = normalizeSpellSet(bucket.ignoredSpells)
	bucket.specialDebuffs = normalizeSpecialSet(bucket.specialDebuffs)
	cfg.byContext[context] = bucket
	return bucket
end

local function getContextBucket(cfg, context)
	context = GAI.ResolveContext(context) or context
	if not UNIT_CONTEXT_LOOKUP[context] then return nil end
	cfg.byContext = type(cfg.byContext) == "table" and cfg.byContext or {}
	local bucket = cfg.byContext[context]
	if type(bucket) ~= "table" then
		bucket = {
			allowedSpells = {},
			ignoredFamilies = {},
			ignoredSpells = {},
			specialDebuffs = createDefaultSpecialDebuffs(),
		}
		cfg.byContext[context] = bucket
		return bucket
	end
	if type(bucket.allowedSpells) ~= "table" then bucket.allowedSpells = {} end
	if type(bucket.ignoredFamilies) ~= "table" then bucket.ignoredFamilies = {} end
	if type(bucket.ignoredSpells) ~= "table" then bucket.ignoredSpells = {} end
	if type(bucket.specialDebuffs) ~= "table" then
		bucket.specialDebuffs = createDefaultSpecialDebuffs()
	else
		for key, defaultValue in pairs(DEFAULT_SPECIAL_DEBUFFS) do
			if bucket.specialDebuffs[key] == nil then bucket.specialDebuffs[key] = defaultValue == true end
		end
	end
	return bucket
end

local function normalizeConfig(cfg)
	if type(cfg) ~= "table" then cfg = createDefaultConfig() end
	cfg.enabled = cfg.enabled == true
	cfg.version = 2
	cfg.customSpells = normalizeSpellSet(cfg.customSpells)
	cfg.byContext = type(cfg.byContext) == "table" and cfg.byContext or {}

	local _, byId = getFamilyEntries()
	if cfg._eqolContextMigrated ~= true then
		local legacyFamilies = normalizeFamilySet(cfg.ignoredFamilies, byId)
		local legacySpells = normalizeSpellSet(cfg.ignoredSpells)
		local legacySpecial = normalizeSpecialSet(cfg.specialDebuffs)
		local hasLegacyValues = hasAnyEnabledValues(legacyFamilies) or hasAnyEnabledValues(legacySpells) or hasAnyEnabledValues(legacySpecial)
		if hasLegacyValues then
			local targetContexts = {}
			if type(cfg.applyTo) == "table" then
				for i = 1, #UNIT_CONTEXT_ORDER do
					local context = UNIT_CONTEXT_ORDER[i]
					if cfg.applyTo[context] == true then targetContexts[#targetContexts + 1] = context end
				end
			end
			if #targetContexts == 0 then
				for i = 1, #UNIT_CONTEXT_ORDER do
					targetContexts[#targetContexts + 1] = UNIT_CONTEXT_ORDER[i]
				end
			end
			for i = 1, #targetContexts do
				local context = targetContexts[i]
				local bucket = type(cfg.byContext[context]) == "table" and cfg.byContext[context] or {}
				bucket.allowedSpells = type(bucket.allowedSpells) == "table" and bucket.allowedSpells or {}
				bucket.ignoredFamilies = type(bucket.ignoredFamilies) == "table" and bucket.ignoredFamilies or {}
				bucket.ignoredSpells = type(bucket.ignoredSpells) == "table" and bucket.ignoredSpells or {}
				bucket.specialDebuffs = normalizeSpecialSet(bucket.specialDebuffs)
				for familyId in pairs(legacyFamilies) do
					bucket.ignoredFamilies[familyId] = true
				end
				for spellId in pairs(legacySpells) do
					bucket.ignoredSpells[spellId] = true
				end
				for specialKey, enabled in pairs(legacySpecial) do
					if enabled == true then bucket.specialDebuffs[specialKey] = true end
				end
				cfg.byContext[context] = bucket
			end
		end
		cfg._eqolContextMigrated = true
	end

	for i = 1, #UNIT_CONTEXT_ORDER do
		normalizeContextBucket(cfg, UNIT_CONTEXT_ORDER[i], byId)
	end
	for key in pairs(cfg.byContext) do
		if not UNIT_CONTEXT_LOOKUP[key] then cfg.byContext[key] = nil end
	end
	if cfg._eqolSpecialDefaultsV2 ~= true then
		for i = 1, #UNIT_CONTEXT_ORDER do
			local bucket = getContextBucket(cfg, UNIT_CONTEXT_ORDER[i])
			if bucket and type(bucket.specialDebuffs) == "table" then
				bucket.specialDebuffs.satedExhaustion = true
				bucket.specialDebuffs.deserter = true
			end
		end
		cfg._eqolSpecialDefaultsV2 = true
	end
	if cfg._eqolSpecialDefaultsV3 ~= true then
		for i = 1, #UNIT_CONTEXT_ORDER do
			local bucket = getContextBucket(cfg, UNIT_CONTEXT_ORDER[i])
			if bucket and type(bucket.specialDebuffs) == "table" then bucket.specialDebuffs.challengeTime = true end
		end
		cfg._eqolSpecialDefaultsV3 = true
	end
	if cfg._eqolSpecialDefaultsV4 ~= true then
		for i = 1, #UNIT_CONTEXT_ORDER do
			local context = UNIT_CONTEXT_ORDER[i]
			local bucket = getContextBucket(cfg, context)
			if context ~= "player" and bucket and type(bucket.specialDebuffs) == "table" then bucket.specialDebuffs.skyridingUtility = true end
		end
		cfg._eqolSpecialDefaultsV4 = true
	end

	-- Legacy fields: normalized into byContext above.
	cfg.applyTo = nil
	cfg.ignoredFamilies = nil
	cfg.ignoredSpells = nil
	cfg.specialDebuffs = nil

	cfg._eqolNormalized = true
	return cfg
end

function GAI.EnsureConfig()
	addon.db = addon.db or {}
	if type(addon.db.ufGlobalAuraIgnore) ~= "table" then addon.db.ufGlobalAuraIgnore = createDefaultConfig() end
	addon.db.ufGlobalAuraIgnore = normalizeConfig(addon.db.ufGlobalAuraIgnore)
	return addon.db.ufGlobalAuraIgnore
end

function GAI.ResolveContext(context)
	local key = tostring(context or ""):lower()
	if key == "" then return nil end
	if key == "party" or key:match("^party%d+$") then return "party" end
	if key == "raid" or key == "mt" or key == "ma" or key:match("^raid%d+$") then return "raid" end
	if key == "player" or key == "pet" or key == "vehicle" then return "player" end
	if key == "focus" then return "focus" end
	if key == "target" or key == "targettarget" or key:match("^boss%d+$") then return "target" end
	return nil
end

function GAI.ShouldIgnoreSpell(context, spellId, cfgOverride)
	if spellId == nil then return false end
	if issecretvalue and issecretvalue(spellId) then return false end
	spellId = tonumber(spellId)
	if not spellId or spellId <= 0 then return false end
	local cfg = cfgOverride
	if type(cfg) ~= "table" then
		cfg = addon.db and addon.db.ufGlobalAuraIgnore
		if type(cfg) ~= "table" then cfg = GAI.EnsureConfig() end
	end
	if cfg._eqolNormalized ~= true then cfg = normalizeConfig(cfg) end
	if cfg.enabled ~= true then return false end

	local resolvedContext = GAI.ResolveContext(context)
	if not resolvedContext then return false end
	local bucket = getContextBucket(cfg, resolvedContext)
	if not bucket then return false end

	if bucket.allowedSpells and bucket.allowedSpells[spellId] == true then return false end
	if bucket.ignoredSpells[spellId] == true then return true end

	for i = 1, #SPECIAL_DEBUFF_GROUPS do
		local group = SPECIAL_DEBUFF_GROUPS[i]
		if bucket.specialDebuffs[group.key] == true and SPECIAL_DEBUFF_SETS[group.key] and SPECIAL_DEBUFF_SETS[group.key][spellId] == true then return true end
	end

	local familyId = getFamilyFromSpell(spellId)
	if familyId and bucket.ignoredFamilies[tostring(familyId)] == true then return true end
	return false
end

function GAI.ShouldIgnoreAura(context, aura, cfgOverride)
	if type(aura) ~= "table" then return false end
	local spellId = aura.spellId
	if spellId == nil then spellId = aura.spellID end
	if spellId == nil then return false end
	return GAI.ShouldIgnoreSpell(context, spellId, cfgOverride)
end

function GAI.GetIgnoredSpellIDs(context, cfgOverride)
	local cfg = cfgOverride
	if type(cfg) ~= "table" then
		cfg = addon.db and addon.db.ufGlobalAuraIgnore
		if type(cfg) ~= "table" then cfg = GAI.EnsureConfig() end
	end
	if cfg._eqolNormalized ~= true then cfg = normalizeConfig(cfg) end
	if cfg.enabled ~= true then return nil end

	local resolvedContext = GAI.ResolveContext(context)
	if not resolvedContext then return nil end
	local bucket = getContextBucket(cfg, resolvedContext)
	if not bucket then return nil end

	local spellIDs = {}
	for spellId, ignored in pairs(bucket.ignoredSpells or {}) do
		if ignored == true then spellIDs[spellId] = true end
	end
	for i = 1, #SPECIAL_DEBUFF_GROUPS do
		local group = SPECIAL_DEBUFF_GROUPS[i]
		if bucket.specialDebuffs[group.key] == true then
			for spellId in pairs(SPECIAL_DEBUFF_SETS[group.key] or {}) do
				spellIDs[spellId] = true
			end
		end
	end
	local _, familiesById = getFamilyEntries()
	for familyId, ignored in pairs(bucket.ignoredFamilies or {}) do
		local family = ignored == true and familiesById[tostring(familyId)] or nil
		for i = 1, #(family and family.spellIds or {}) do
			spellIDs[family.spellIds[i]] = true
		end
	end
	for spellId, allowed in pairs(bucket.allowedSpells or {}) do
		if allowed == true then spellIDs[spellId] = nil end
	end
	return next(spellIDs) and spellIDs or nil
end

local function requestAuraRefresh()
	if InCombatLockdown and InCombatLockdown() then return end
	local defaultAuraContainers = addon.DefaultAuraContainers and addon.DefaultAuraContainers.functions
	if defaultAuraContainers and defaultAuraContainers.RefreshDefaultAuraIconSkin then defaultAuraContainers.RefreshDefaultAuraIconSkin() end

	if UF and UF.FullScanTargetAuras then
		if UF.RefreshNativeAuraIgnoreFilters then UF.RefreshNativeAuraIgnoreFilters("player") end
		UF.FullScanTargetAuras("player")
		if UF.RefreshNativeAuraIgnoreFilters then UF.RefreshNativeAuraIgnoreFilters("target") end
		UF.FullScanTargetAuras("target")
		if UF.RefreshNativeAuraIgnoreFilters then UF.RefreshNativeAuraIgnoreFilters("focus") end
		UF.FullScanTargetAuras("focus")
		local bossCount = (UF.GetBossFrameCount and UF.GetBossFrameCount()) or (UF.GetSupportedBossFrameCount and UF.GetSupportedBossFrameCount()) or 8
		for i = 1, bossCount do
			local unit = "boss" .. tostring(i)
			if UF.RefreshNativeAuraIgnoreFilters then UF.RefreshNativeAuraIgnoreFilters(unit) end
			UF.FullScanTargetAuras(unit)
		end
	end

	local gf = UF and UF.GroupFrames
	if gf then
		if gf.Refresh then gf.Refresh() end
		if gf.RefreshHealerBuffPlacement then gf:RefreshHealerBuffPlacement() end
	end
end

GAI.RequestAuraRefresh = requestAuraRefresh
addon.functions = addon.functions or {}
addon.functions.GetGlobalAuraIgnoredSpellIDs = GAI.GetIgnoredSpellIDs

function GAI:ToggleEditor()
	if addon.functions and addon.functions.OpenConfigCenter then
		addon.functions.OpenConfigCenter("suites.customunitframes", "UFGlobalAuraIgnoreMatrix")
	end
end

function GAI:HideEditor()
end

function GAI:GetSpecialDebuffGroups()
	local list = {}
	for i = 1, #SPECIAL_DEBUFF_GROUPS do
		local group = SPECIAL_DEBUFF_GROUPS[i]
		list[#list + 1] = {
			key = group.key,
			label = tr(group.labelKey, group.fallbackLabel),
			spellIds = copyTable(group.spellIds or {}),
		}
	end
	return list
end

function GAI:GetFamilyEntries()
	local entries = getFamilyEntries()
	return copyTable(entries)
end

function GAI:ResetFamilyCache()
	familyEntryList = nil
	familyEntryById = nil
end

local function getSpellTexture(spellId)
	if spellId == nil then return nil end
	if C_Spell and C_Spell.GetSpellTexture then
		local texture = C_Spell.GetSpellTexture(spellId)
		if texture then return texture end
	end
	if GetSpellTexture then return GetSpellTexture(spellId) end
	return nil
end

local function getPrimarySpellId(rowData)
	if not rowData then return nil end
	if rowData.iconSpellId then return rowData.iconSpellId end
	if rowData.labelSpellId then return rowData.labelSpellId end
	if rowData.spellId then return rowData.spellId end
	if type(rowData.spellIds) == "table" then return rowData.spellIds[1] end
	return nil
end

local function buildSpellMatrixRow(rowData)
	local spellIds = {}
	local seen = {}
	local rawSpellIds = rowData and rowData.spellIds
	if type(rawSpellIds) == "table" then
		for i = 1, #rawSpellIds do
			local spellId = tonumber(rawSpellIds[i])
			if spellId and spellId > 0 and not seen[spellId] then
				seen[spellId] = true
				spellIds[#spellIds + 1] = spellId
			end
		end
	else
		local spellId = tonumber(rowData and rowData.spellId)
		if spellId and spellId > 0 then
			seen[spellId] = true
			spellIds[#spellIds + 1] = spellId
		end
	end
	if #spellIds == 0 then return nil end
	local primarySpellId = getPrimarySpellId(rowData) or spellIds[1]
	local labelSpellId = rowData and rowData.labelSpellId
	return {
		kind = "spell",
		spellId = spellIds[1],
		spellIds = spellIds,
		tooltipSpellId = primarySpellId,
		label = (labelSpellId and getSpellName(labelSpellId)) or (rowData and rowData.label) or (rowData and rowData.fallbackLabel) or getSpellName(spellIds[1]) or ("#" .. tostring(spellIds[1])),
		icon = getSpellTexture(primarySpellId) or getSpellTexture(spellIds[1]),
	}
end

local function appendSpecialSpellRows(rows, group)
	local grouped = {}
	local order = {}
	for i = 1, #(group.spellIds or {}) do
		local spellId = tonumber(group.spellIds[i])
		if spellId and spellId > 0 then
			local label = getSpellName(spellId) or ("#" .. tostring(spellId))
			if not grouped[label] then
				grouped[label] = {
					label = label,
					spellIds = {},
					iconSpellId = spellId,
				}
				order[#order + 1] = label
			end
			grouped[label].spellIds[#grouped[label].spellIds + 1] = spellId
		end
	end
	sort(order, function(a, b) return tostring(a) < tostring(b) end)
	for i = 1, #order do
		local row = buildSpellMatrixRow(grouped[order[i]])
		if row then rows[#rows + 1] = row end
	end
end

local function appendSpellMatrixRows(rows, matrixRows)
	local sortedRows = {}
	for i = 1, #(matrixRows or {}) do
		local row = buildSpellMatrixRow(matrixRows[i])
		if row then sortedRows[#sortedRows + 1] = row end
	end
	sort(sortedRows, function(a, b) return tostring(a.label or "") < tostring(b.label or "") end)
	for i = 1, #sortedRows do
		rows[#rows + 1] = sortedRows[i]
	end
end

local function appendSettingsCenterSection(sections, label, rows)
	if not label or label == "" then return nil end
	for i = 1, #sections do
		if sections[i].label == label then
			local targetRows = sections[i].rows or {}
			for j = 1, #(rows or {}) do
				targetRows[#targetRows + 1] = rows[j]
			end
			sections[i].rows = targetRows
			return sections[i]
		end
	end
	local section = {
		label = label,
		rows = rows or {},
	}
	sections[#sections + 1] = section
	return section
end

local function appendSortedSettingsCenterSections(rows, sections)
	sort(sections, function(a, b) return tostring(a.label or "") < tostring(b.label or "") end)
	for i = 1, #sections do
		local section = sections[i]
		rows[#rows + 1] = {
			isHeader = true,
			label = section.label or "",
		}
		local sectionRows = section.rows or {}
		sort(sectionRows, function(a, b) return tostring(a.label or "") < tostring(b.label or "") end)
		for j = 1, #sectionRows do
			rows[#rows + 1] = sectionRows[j]
		end
	end
end

local function buildSettingsCenterRows()
	local rows = {}
	local sections = {}
	for i = 1, #SPECIAL_DEBUFF_GROUPS do
		local group = SPECIAL_DEBUFF_GROUPS[i]
		if type(group.matrixGroups) == "table" then
			local matrixGroups = {}
			for j = 1, #group.matrixGroups do
				local matrixGroup = group.matrixGroups[j]
				matrixGroups[#matrixGroups + 1] = {
					label = matrixGroup.label or getClassLabel(matrixGroup.classToken),
					rows = matrixGroup.matrixRows or { { spellIds = matrixGroup.spellIds } },
				}
			end
			for j = 1, #matrixGroups do
				local sectionRows = {}
				appendSpellMatrixRows(sectionRows, matrixGroups[j].rows)
				appendSettingsCenterSection(sections, matrixGroups[j].label, sectionRows)
			end
		else
			local sectionRows = {}
			if type(group.matrixRows) == "table" then
				appendSpellMatrixRows(sectionRows, group.matrixRows)
			else
				appendSpecialSpellRows(sectionRows, group)
			end
			appendSettingsCenterSection(sections, tr(group.labelKey, group.fallbackLabel), sectionRows)
		end
	end

	local entries = getFamilyEntries()
	local _, byFamilyId = getFamilyEntries()
	local activeSection
	for i = 1, #entries do
		local entry = entries[i]
		if entry.isHeader then
			activeSection = {
				label = entry.label or "",
				rows = {},
			}
			activeSection = appendSettingsCenterSection(sections, activeSection.label, activeSection.rows)
		else
			local combinePrimaryId = MATRIX_FAMILY_COMBINE_MEMBER[entry.familyId]
			if combinePrimaryId and combinePrimaryId ~= entry.familyId then
				-- Render combined Echo variants once on the primary family row.
			else
				local spellId = entry.spellIds and entry.spellIds[1]
				local familyIds = MATRIX_FAMILY_COMBINES[entry.familyId]
				local spellIds = entry.spellIds
				if familyIds then
					spellIds = {}
					for j = 1, #familyIds do
						local familyEntry = byFamilyId and byFamilyId[familyIds[j]]
						local familySpellIds = familyEntry and familyEntry.spellIds
						for k = 1, #(familySpellIds or {}) do
							spellIds[#spellIds + 1] = familySpellIds[k]
						end
					end
				end
				local row = {
					kind = "family",
					familyId = entry.familyId,
					familyIds = familyIds,
					spellId = spellId,
					spellIds = spellIds,
					tooltipSpellId = spellId,
					label = entry.label or getSpellName(spellId) or tostring(entry.familyId or ""),
					icon = getSpellTexture(spellId),
				}
				if activeSection and activeSection.rows then activeSection.rows[#activeSection.rows + 1] = row end
			end
		end
	end

	local cfg = GAI.EnsureConfig()
	local customRows = {}
	for spellId, enabled in pairs(cfg.customSpells or {}) do
		if enabled == true then
			local row = buildSpellMatrixRow({ spellId = spellId })
			if row then
				row.kind = "custom"
				row.removable = true
				customRows[#customRows + 1] = row
			end
		end
	end
	if #customRows > 0 then appendSettingsCenterSection(sections, tr("UFGlobalAuraIgnoreCustomAuras", "Custom auras"), customRows) end
	appendSortedSettingsCenterSections(rows, sections)
	return rows
end

function GAI.GetSettingsCenterTableHeight()
	local rows = buildSettingsCenterRows()
	local height = 122
	for i = 1, #rows do
		height = height + (rows[i].isHeader and 34 or 30)
	end
	return height + 18
end

local function getMatrixSettingRows()
	local rows = buildSettingsCenterRows()
	local settingRows = {}
	for i = 1, #rows do
		if not rows[i].isHeader then settingRows[#settingRows + 1] = rows[i] end
	end
	return settingRows
end

function GAI.GetSettingsCenterSettingCount()
	return 1 + (#getMatrixSettingRows() * #UNIT_CONTEXT_ORDER)
end

function GAI.GetSettingsCenterSearchEntries()
	local entries = {
		{
			id = "overview",
			label = tr("UFGlobalAuraIgnoreMatrixTitle", "Aura Ignore Matrix"),
			keywords = {
				tr("UFGlobalAuraIgnoreEditorTitle", "Global Aura Ignore"),
				tr("UFGlobalAuraIgnoreMatrixDesc", "Configure ignored auras for Player, Target, Focus, Group and Raid unit frames."),
				"Aura Ignore",
				"Global Aura Ignore",
				"Unit Frames",
			},
		},
	}
	local activeHeader
	local rows = buildSettingsCenterRows()
	for i = 1, #rows do
		local row = rows[i]
		if row.isHeader then
			activeHeader = row.label
			entries[#entries + 1] = {
				id = "header." .. tostring(i),
				label = row.label or "",
				keywords = {
					tr("UFGlobalAuraIgnoreMatrixTitle", "Aura Ignore Matrix"),
					tr("UFGlobalAuraIgnoreEditorTitle", "Global Aura Ignore"),
					"Aura Ignore",
					"Ignore",
				},
			}
		else
			local keywords = {
				tr("UFGlobalAuraIgnoreMatrixTitle", "Aura Ignore Matrix"),
				tr("UFGlobalAuraIgnoreEditorTitle", "Global Aura Ignore"),
				activeHeader,
				"Aura Ignore",
				"Ignore",
			}
			if type(row.spellIds) == "table" then
				for j = 1, #row.spellIds do
					local spellId = tonumber(row.spellIds[j])
					if spellId then
						keywords[#keywords + 1] = tostring(spellId)
						keywords[#keywords + 1] = getSpellName(spellId)
					end
				end
			elseif row.spellId then
				keywords[#keywords + 1] = tostring(row.spellId)
				keywords[#keywords + 1] = getSpellName(row.spellId)
			end
			if type(row.familyIds) == "table" then
				for j = 1, #row.familyIds do
					keywords[#keywords + 1] = row.familyIds[j]
				end
			elseif row.familyId then
				keywords[#keywords + 1] = row.familyId
			end
			entries[#entries + 1] = {
				id = (row.kind or "row") .. "." .. tostring(row.familyId or row.spellId or i),
				label = row.label or "",
				keywords = keywords,
				focusID = tostring(row.familyId or row.spellId or i),
			}
		end
	end
	return entries
end

local function isSpellIgnoredInBucket(bucket, spellId)
	spellId = tonumber(spellId)
	if not bucket or not spellId or spellId <= 0 then return false end
	if bucket.allowedSpells and bucket.allowedSpells[spellId] == true then return false end
	if bucket.ignoredSpells and bucket.ignoredSpells[spellId] == true then return true end
	for i = 1, #SPECIAL_DEBUFF_GROUPS do
		local group = SPECIAL_DEBUFF_GROUPS[i]
		if bucket.specialDebuffs and bucket.specialDebuffs[group.key] == true and SPECIAL_DEBUFF_SETS[group.key] and SPECIAL_DEBUFF_SETS[group.key][spellId] == true then return true end
	end
	return false
end

local function getMatrixRowIgnored(row, context, cfg)
	if not row then return false end
	local bucket = getContextBucket(cfg, context)
	if not bucket then return false end
	if row.kind == "family" then
		if type(row.familyIds) == "table" then
			for i = 1, #row.familyIds do
				if bucket.ignoredFamilies and bucket.ignoredFamilies[tostring(row.familyIds[i])] == true then return true end
			end
			return false
		end
		return row.familyId ~= nil and bucket.ignoredFamilies and bucket.ignoredFamilies[tostring(row.familyId)] == true
	end
	if type(row.spellIds) == "table" then
		for i = 1, #row.spellIds do
			if isSpellIgnoredInBucket(bucket, row.spellIds[i]) == true then return true end
		end
		return false
	end
	return row.spellId ~= nil and isSpellIgnoredInBucket(bucket, row.spellId) == true
end

function GAI.GetSettingsCenterCustomizedCount()
	local cfg = GAI.EnsureConfig()
	local defaults = normalizeConfig(createDefaultConfig())
	local count = cfg.enabled == true and 1 or 0
	for _, enabled in pairs(cfg.customSpells or {}) do
		if enabled == true then count = count + 1 end
	end
	local rows = getMatrixSettingRows()
	for i = 1, #rows do
		for j = 1, #UNIT_CONTEXT_ORDER do
			local context = UNIT_CONTEXT_ORDER[j]
			if getMatrixRowIgnored(rows[i], context, cfg) ~= getMatrixRowIgnored(rows[i], context, defaults) then count = count + 1 end
		end
	end
	return count
end

local function addCustomSpell(spellId)
	spellId = tonumber(spellId)
	if not spellId or spellId <= 0 or spellId ~= math.floor(spellId) then return false, "invalid" end
	if C_Spell and C_Spell.DoesSpellExist and not C_Spell.DoesSpellExist(spellId) then return false, "invalid" end
	local cfg = GAI.EnsureConfig()
	if cfg.customSpells[spellId] == true then return false, "duplicate" end
	cfg.customSpells[spellId] = true
	for i = 1, #UNIT_CONTEXT_ORDER do
		local bucket = getContextBucket(cfg, UNIT_CONTEXT_ORDER[i])
		if bucket then
			bucket.allowedSpells[spellId] = nil
			bucket.ignoredSpells[spellId] = true
		end
	end
	normalizeConfig(cfg)
	requestAuraRefresh()
	return true
end

local function removeCustomSpell(spellId)
	spellId = tonumber(spellId)
	if not spellId then return end
	local cfg = GAI.EnsureConfig()
	cfg.customSpells[spellId] = nil
	for i = 1, #UNIT_CONTEXT_ORDER do
		local bucket = getContextBucket(cfg, UNIT_CONTEXT_ORDER[i])
		if bucket then
			bucket.allowedSpells[spellId] = nil
			bucket.ignoredSpells[spellId] = nil
		end
	end
	normalizeConfig(cfg)
	requestAuraRefresh()
end

local function setMatrixRowIgnored(row, context, ignored)
	if not row or not UNIT_CONTEXT_LOOKUP[context] then return end
	local cfg = GAI.EnsureConfig()
	local bucket = getContextBucket(cfg, context)
	if not bucket then return end
	if row.kind == "family" then
		local familyIds = type(row.familyIds) == "table" and row.familyIds or { row.familyId }
		for i = 1, #familyIds do
			local familyId = tostring(familyIds[i] or "")
			if familyId ~= "" then
				if ignored then
					bucket.ignoredFamilies[familyId] = true
				else
					bucket.ignoredFamilies[familyId] = nil
				end
			end
		end
	elseif row.spellId then
		local spellIds = type(row.spellIds) == "table" and row.spellIds or { row.spellId }
		for i = 1, #spellIds do
			local spellId = tonumber(spellIds[i])
			if spellId and spellId > 0 then
				if ignored then
					bucket.allowedSpells[spellId] = nil
					bucket.ignoredSpells[spellId] = true
				else
					bucket.ignoredSpells[spellId] = nil
					bucket.allowedSpells[spellId] = true
				end
			end
		end
	end
	normalizeConfig(cfg)
	requestAuraRefresh()
end

local function updateSettingsCenterChecks(handle)
	if not handle then return end
	local cfg = GAI.EnsureConfig()
	if handle.EnabledCheck then handle.EnabledCheck:SetChecked(cfg.enabled == true) end
	for i = 1, #(handle.checks or {}) do
		local check = handle.checks[i]
		if check and check._matrixRow and check._matrixContext then
			check:SetChecked(getMatrixRowIgnored(check._matrixRow, check._matrixContext, cfg))
			check:SetAlpha(cfg.enabled == true and 1 or 0.7)
		end
	end
end

function GAI.RenderSettingsCenterTable(parent, opts)
	if not parent then return nil end
	opts = opts or {}
	local handle = {
		frames = {},
		checks = {},
	}
	local rows = buildSettingsCenterRows()
	local columnX = {
		player = -150,
		target = -120,
		focus = -90,
		party = -60,
		raid = -30,
	}
	local headerLabels = {
		player = "P",
		target = "T",
		focus = "F",
		party = "G",
		raid = "R",
	}
	local function track(frame)
		handle.frames[#handle.frames + 1] = frame
		return frame
	end

	local enabledCheck = track(CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate"))
	enabledCheck:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -8)
	if enabledCheck.Text then
		enabledCheck.Text:SetText(tr("UFGlobalAuraIgnoreMatrixEnabled", "Enable global aura ignore"))
		enabledCheck.Text:SetTextColor(1, 1, 1, 1)
		enabledCheck.Text:SetWidth(420)
		enabledCheck.Text:SetJustifyH("LEFT")
	end
	enabledCheck:SetScript("OnClick", function(self)
		local cfg = GAI.EnsureConfig()
		cfg.enabled = self:GetChecked() == true
		normalizeConfig(cfg)
		requestAuraRefresh()
		updateSettingsCenterChecks(handle)
	end)
	handle.EnabledCheck = enabledCheck

	local addFrame = track(CreateFrame("Frame", nil, parent))
	addFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -38)
	addFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -38)
	addFrame:SetHeight(34)

	local spellIDLabel = track(addFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
	spellIDLabel:SetPoint("LEFT", addFrame, "LEFT", 6, 0)
	spellIDLabel:SetText(tr("UFGlobalAuraIgnoreCustomSpellID", "Spell ID"))

	local spellIDInput = track(CreateFrame("EditBox", nil, addFrame, "InputBoxTemplate"))
	spellIDInput:SetSize(110, 24)
	spellIDInput:SetPoint("LEFT", spellIDLabel, "RIGHT", 10, 0)
	spellIDInput:SetAutoFocus(false)
	spellIDInput:SetNumeric(true)
	spellIDInput:SetMaxLetters(10)

	local addButton = track(CreateFrame("Button", nil, addFrame, "UIPanelButtonTemplate"))
	addButton:SetSize(78, 24)
	addButton:SetPoint("LEFT", spellIDInput, "RIGHT", 8, 0)
	addButton:SetText(_G.ADD or "Add")

	local addStatus = track(addFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
	addStatus:SetPoint("LEFT", addButton, "RIGHT", 10, 0)
	addStatus:SetPoint("RIGHT", addFrame, "RIGHT", -8, 0)
	addStatus:SetJustifyH("LEFT")
	addStatus:SetTextColor(1, 0.25, 0.25, 1)

	local function requestLayout()
		local state = opts.state
		if state and state.RequestLayout then state:RequestLayout() end
	end

	addButton:SetScript("OnClick", function()
		local added, reason = addCustomSpell(spellIDInput:GetText())
		if added then
			spellIDInput:SetText("")
			requestLayout()
		elseif reason == "duplicate" then
			addStatus:SetText(tr("UFGlobalAuraIgnoreCustomAlreadyAdded", "This aura has already been added."))
		else
			addStatus:SetText(tr("UFGlobalAuraIgnoreCustomInvalidSpell", "Enter a valid Spell ID."))
		end
	end)
	spellIDInput:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
		addButton:Click()
	end)
	spellIDInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

	local header = track(CreateFrame("Frame", nil, parent))
	header:SetPoint("TOPLEFT", addFrame, "BOTTOMLEFT", 0, -4)
	header:SetPoint("TOPRIGHT", addFrame, "BOTTOMRIGHT", 0, -4)
	header:SetHeight(26)
	for i = 1, #UNIT_CONTEXT_ORDER do
		local context = UNIT_CONTEXT_ORDER[i]
		local label = track(header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
		label:SetPoint("RIGHT", header, "RIGHT", columnX[context], 0)
		label:SetText(headerLabels[context] or "")
		label:SetWidth(24)
		label:SetJustifyH("CENTER")
	end

	local previous = header
	for i = 1, #rows do
		local rowData = rows[i]
		if rowData.isHeader then
			local frame = track(CreateFrame("Frame", nil, parent))
			frame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -6)
			frame:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -6)
			frame:SetHeight(24)
			local label = track(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"))
			label:SetPoint("LEFT", frame, "LEFT", 6, 0)
			label:SetPoint("RIGHT", frame, "RIGHT", -180, 0)
			label:SetJustifyH("LEFT")
			label:SetText(rowData.label or "")
			label:SetTextColor(1, 0.85, 0.2, 1)
			previous = frame
		else
			local frame = track(CreateFrame("Frame", nil, parent))
			frame:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -2)
			frame:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -2)
			frame:SetHeight(28)
			frame:EnableMouse(true)
			frame:SetScript("OnEnter", function()
				if not GameTooltip then return end
				local spellId = tonumber(rowData.tooltipSpellId or rowData.spellId)
				GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
				if spellId and GameTooltip.SetSpellByID then
					GameTooltip:SetSpellByID(spellId)
				else
					GameTooltip:AddLine(rowData.label or "", 1, 0.82, 0)
				end
				GameTooltip:Show()
			end)
			frame:SetScript("OnLeave", function()
				if GameTooltip then GameTooltip:Hide() end
			end)

			local icon = track(frame:CreateTexture(nil, "ARTWORK"))
			icon:SetSize(22, 22)
			icon:SetPoint("LEFT", frame, "LEFT", 6, 0)
			icon:SetTexture(rowData.icon or 134400)

			local name = track(frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
			name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
			name:SetPoint("RIGHT", frame, "RIGHT", rowData.removable and -210 or -180, 0)
			name:SetJustifyH("LEFT")
			name:SetText(rowData.label or "")

			if rowData.removable then
				local removeButton = track(CreateFrame("Button", nil, frame, "UIPanelCloseButton"))
				removeButton:SetSize(20, 20)
				removeButton:SetPoint("RIGHT", frame, "RIGHT", -180, 0)
				removeButton:SetFrameLevel(frame:GetFrameLevel() + 2)
				removeButton:RegisterForClicks("LeftButtonUp")
				removeButton._customSpellId = rowData.spellId
				removeButton:SetScript("OnClick", function(self)
					removeCustomSpell(self._customSpellId)
					requestLayout()
				end)
				removeButton:SetScript("OnEnter", function(self)
					if not GameTooltip then return end
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:AddLine(tr("UFGlobalAuraIgnoreCustomRemove", "Remove custom aura"), 1, 0.82, 0)
					GameTooltip:Show()
				end)
				removeButton:SetScript("OnLeave", function()
					if GameTooltip then GameTooltip:Hide() end
				end)
			end

			for j = 1, #UNIT_CONTEXT_ORDER do
				local context = UNIT_CONTEXT_ORDER[j]
				local check = track(CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate"))
				check:SetSize(24, 24)
				check:SetPoint("RIGHT", frame, "RIGHT", columnX[context], 0)
				check._matrixRow = rowData
				check._matrixContext = context
				check:SetScript("OnClick", function(self)
					setMatrixRowIgnored(self._matrixRow, self._matrixContext, self:GetChecked() == true)
					updateSettingsCenterChecks(handle)
				end)
				check:SetScript("OnEnter", function(self)
					if not GameTooltip then return end
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
					GameTooltip:AddLine(rowData.label or "", 1, 0.82, 0)
					GameTooltip:AddLine(string.format(tr("UFGlobalAuraIgnoreMatrixAppliesTo", "Applies to: %s"), getUnitContextLabel(self._matrixContext)), 1, 1, 1)
					GameTooltip:Show()
				end)
				check:SetScript("OnLeave", function()
					if GameTooltip then GameTooltip:Hide() end
				end)
				handle.checks[#handle.checks + 1] = check
			end
			previous = frame
		end
	end

	function handle:Release()
		for i = 1, #(self.frames or {}) do
			local frame = self.frames[i]
			if frame and frame.Hide then frame:Hide() end
			if frame and frame.SetParent then frame:SetParent(nil) end
		end
		wipeTable(self.frames)
		wipeTable(self.checks)
	end

	updateSettingsCenterChecks(handle)
	return handle
end
