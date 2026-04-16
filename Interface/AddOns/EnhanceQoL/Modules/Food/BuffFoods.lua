local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local UnitLevel = UnitLevel
local tinsert = table.insert
local tsort = table.sort
local CreateFrame = CreateFrame
local C_Item_GetItemInfo = C_Item and C_Item.GetItemInfo
local C_Item_GetItemNameByID = C_Item and C_Item.GetItemNameByID
local C_Item_RequestLoadItemDataByID = C_Item and C_Item.RequestLoadItemDataByID

local STAT_CRIT_LABEL = _G.STAT_CRITICAL_STRIKE
local STAT_HASTE_LABEL = _G.STAT_HASTE
local STAT_MASTERY_LABEL = _G.STAT_MASTERY
local STAT_VERSATILITY_LABEL = _G.STAT_VERSATILITY
local ROLE_TANK_LABEL = _G.TANK
local ROLE_HEALER_LABEL = _G.HEALER
local ROLE_DAMAGER_LABEL = _G.ROLE_DAMAGER
local ROLE_RANGED_LABEL = _G.RANGED
local ROLE_MELEE_LABEL = _G.MELEE

addon.BuffFoods = addon.BuffFoods or {}
addon.BuffFoods.functions = addon.BuffFoods.functions or {}
addon.BuffFoods.filteredBuffFoods = addon.BuffFoods.filteredBuffFoods or {}
addon.BuffFoods.bagItemCountCache = addon.BuffFoods.bagItemCountCache or {}
addon.BuffFoods.candidateCache = addon.BuffFoods.candidateCache or {}

addon.BuffFoods.typeOrder = {
	"highestSecondary",
	"primary",
	"haste",
	"criticalStrike",
	"mastery",
	"versatility",
	"criticalStrikeVersatility",
	"masteryVersatility",
	"criticalStrikeMastery",
	"versatilityHaste",
	"criticalStrikeHaste",
	"masteryHaste",
}
addon.BuffFoods.roleOrder = addon.BuffFoods.roleOrder or { "tank", "healer", "ranged", "melee" }
addon.BuffFoods.typeLabels = addon.BuffFoods.typeLabels
	or {
		highestSecondary = "Highest secondary stat",
		primary = "Primary stat",
		haste = STAT_HASTE_LABEL,
		criticalStrike = STAT_CRIT_LABEL,
		mastery = STAT_MASTERY_LABEL,
		versatility = STAT_VERSATILITY_LABEL,
		criticalStrikeVersatility = string.format("%s + %s", STAT_CRIT_LABEL, STAT_VERSATILITY_LABEL),
		masteryVersatility = string.format("%s + %s", STAT_MASTERY_LABEL, STAT_VERSATILITY_LABEL),
		criticalStrikeMastery = string.format("%s + %s", STAT_CRIT_LABEL, STAT_MASTERY_LABEL),
		versatilityHaste = string.format("%s + %s", STAT_VERSATILITY_LABEL, STAT_HASTE_LABEL),
		criticalStrikeHaste = string.format("%s + %s", STAT_CRIT_LABEL, STAT_HASTE_LABEL),
		masteryHaste = string.format("%s + %s", STAT_MASTERY_LABEL, STAT_HASTE_LABEL),
	}
addon.BuffFoods.roleLabels = addon.BuffFoods.roleLabels
	or {
		tank = ROLE_TANK_LABEL,
		healer = ROLE_HEALER_LABEL,
		ranged = ROLE_RANGED_LABEL and ROLE_DAMAGER_LABEL and (ROLE_RANGED_LABEL .. " " .. ROLE_DAMAGER_LABEL) or ROLE_RANGED_LABEL,
		melee = ROLE_MELEE_LABEL and ROLE_DAMAGER_LABEL and (ROLE_MELEE_LABEL .. " " .. ROLE_DAMAGER_LABEL) or ROLE_MELEE_LABEL,
	}

local function foodEntry(key, familyKey, itemId, sortRank, isHearty)
	return {
		key = key,
		familyKey = familyKey,
		id = itemId,
		requiredLevel = 90,
		sortRank = sortRank,
		isHearty = isHearty == true,
	}
end

-- Current Midnight live buff foods. Categories are semantic, so primary/highest-secondary
-- include feast variants that grant the same relevant stat plus extra stamina.
addon.BuffFoods.typeFoods = addon.BuffFoods.typeFoods
	or {
		highestSecondary = {
			foodEntry("HeartyQueldoreiMedley90", "queldoreiMedley", 266986, 1650, true),
			foodEntry("HeartyQueldoreiMedley", "queldoreiMedley", 242744, 1640, true),
			foodEntry("HeartyBloomingFeast", "bloomingFeast", 242745, 1640, true),
			foodEntry("HeartyFloraFrenzy90A", "floraFrenzy", 268680, 1050, true),
			foodEntry("HeartyFloraFrenzy90B", "floraFrenzy", 267000, 1050, true),
			foodEntry("HeartyChampionsBento", "championsBento", 242746, 1040, true),
			foodEntry("QueldoreiMedley", "queldoreiMedley", 242272, 940, false),
			foodEntry("BloomingFeast", "bloomingFeast", 242273, 940, false),
			foodEntry("FloraFrenzy", "floraFrenzy", 255848, 840, false),
			foodEntry("ChampionsBento", "championsBento", 242274, 840, false),
		},
		primary = {
			foodEntry("HeartySilvermoonParade", "silvermoonParade", 266985, 1500, true),
			foodEntry("HeartyHarandarCelebration", "harandarCelebration", 266996, 1500, true),
			foodEntry("SilvermoonParade", "silvermoonParade", 255845, 1400, false),
			foodEntry("HarandarCelebration", "harandarCelebration", 255846, 1400, false),
			foodEntry("HeartyRoyalRoast", "royalRoast", 242747, 1000, true),
			foodEntry("HeartyImpossiblyRoyalRoast", "impossiblyRoyalRoast", 268679, 1000, true),
			foodEntry("RoyalRoast", "royalRoast", 242275, 900, false),
			foodEntry("ImpossiblyRoyalRoast", "impossiblyRoyalRoast", 255847, 900, false),
			foodEntry("HeartyRootlandSurprise", "rootlandSurprise", 242751, 880, true),
			foodEntry("BakedLuckyLoa", "bakedLuckyLoa", 242279, 780, false),
			foodEntry("HeartyTwilightAnglersMedley", "twilightAnglersMedley", 242760, 700, true),
			foodEntry("HeartySpellfireFilet", "spellfireFilet", 242761, 700, true),
			foodEntry("TwilightAnglersMedley", "twilightAnglersMedley", 242288, 600, false),
			foodEntry("SpellfireFilet", "spellfireFilet", 242289, 600, false),
			foodEntry("HeartyBloomSkewers", "bloomSkewers", 242769, 500, true),
			foodEntry("HeartyManaInfusedStew", "manaInfusedStew", 242770, 500, true),
		},
		haste = {
			foodEntry("HeartyCrimsonCalamari", "crimsonCalamari", 242749, 576, true),
			foodEntry("HeartyNullAndVoidPlate", "nullAndVoidPlate", 242754, 576, true),
			foodEntry("HeartyFelKissedFilet", "felKissedFilet", 242758, 576, true),
			foodEntry("CrimsonCalamari", "crimsonCalamari", 242277, 566, false),
			foodEntry("NullAndVoidPlate", "nullAndVoidPlate", 242282, 566, false),
			foodEntry("FelKissedFilet", "felKissedFilet", 242286, 566, false),
		},
		criticalStrike = {
			foodEntry("HeartyTastySmokedTetra", "tastySmokedTetra", 242750, 576, true),
			foodEntry("HeartySunSearedLumifin", "sunSearedLumifin", 242755, 576, true),
			foodEntry("HeartyArcanoCutlets", "arcanoCutlets", 242759, 576, true),
			foodEntry("TastySmokedTetra", "tastySmokedTetra", 242278, 566, false),
			foodEntry("SunSearedLumifin", "sunSearedLumifin", 242283, 566, false),
			foodEntry("ArcanoCutlets", "arcanoCutlets", 242287, 566, false),
		},
		mastery = {
			foodEntry("HeartyGlitterSkewers", "glitterSkewers", 242753, 576, true),
			foodEntry("HeartyWarpedWiseWings", "warpedWiseWings", 242757, 576, true),
			foodEntry("GlitterSkewers", "glitterSkewers", 242281, 566, false),
			foodEntry("WarpedWiseWings", "warpedWiseWings", 242285, 566, false),
		},
		versatility = {
			foodEntry("HeartyBraisedBloodHunter", "braisedBloodHunter", 242748, 576, true),
			foodEntry("HeartyButteredRootCrab", "butteredRootCrab", 242752, 576, true),
			foodEntry("HeartyVoidKissedFishRolls", "voidKissedFishRolls", 242756, 576, true),
			foodEntry("BraisedBloodHunter", "braisedBloodHunter", 242276, 566, false),
			foodEntry("ButteredRootCrab", "butteredRootCrab", 242280, 566, false),
			foodEntry("VoidKissedFishRolls", "voidKissedFishRolls", 242284, 566, false),
			foodEntry("HeartyFelberryFigs", "felberryFigs", 242766, 448, true),
			foodEntry("FelberryFigs", "felberryFigs", 242294, 438, false),
		},
		criticalStrikeVersatility = {
			foodEntry("HeartyWiseTails", "wiseTails", 242762, 448, true),
			foodEntry("WiseTails", "wiseTails", 242290, 438, false),
			foodEntry("HeartySpicedBiscuits", "spicedBiscuits", 242771, 320, true),
		},
		masteryVersatility = {
			foodEntry("HeartyFriedBloomtail", "friedBloomtail", 242763, 448, true),
			foodEntry("FriedBloomtail", "friedBloomtail", 242291, 438, false),
			foodEntry("HeartySilvermoonStandard", "silvermoonStandard", 242772, 320, true),
		},
		criticalStrikeMastery = {
			foodEntry("HeartyEversongPudding", "eversongPudding", 242764, 448, true),
			foodEntry("EversongPudding", "eversongPudding", 242292, 438, false),
			foodEntry("HeartyForagersMedley", "foragersMedley", 242773, 320, true),
		},
		versatilityHaste = {
			foodEntry("HeartySunwellDelight", "sunwellDelight", 242765, 448, true),
			foodEntry("SunwellDelight", "sunwellDelight", 242293, 438, false),
			foodEntry("HeartyQuickSandwich", "quickSandwich", 242774, 320, true),
		},
		criticalStrikeHaste = {
			foodEntry("HeartyHearthflameSupper", "hearthflameSupper", 242767, 448, true),
			foodEntry("HearthflameSupper", "hearthflameSupper", 242295, 438, false),
			foodEntry("HeartyPortableSnack", "portableSnack", 242775, 320, true),
		},
		masteryHaste = {
			foodEntry("HeartyBloodthistleWrappedCutlets", "bloodthistleWrappedCutlets", 242768, 448, true),
			foodEntry("BloodthistleWrappedCutlets", "bloodthistleWrappedCutlets", 242296, 438, false),
			foodEntry("HeartyFarstriderRations", "farstriderRations", 242776, 320, true),
		},
	}

local function sortEntriesDescending(list)
	if type(list) ~= "table" then return end
	tsort(list, function(a, b)
		local aLevel = tonumber(a and a.requiredLevel) or 0
		local bLevel = tonumber(b and b.requiredLevel) or 0
		if aLevel ~= bLevel then return aLevel > bLevel end
		local aRank = tonumber(a and a.sortRank) or 0
		local bRank = tonumber(b and b.sortRank) or 0
		if aRank ~= bRank then return aRank > bRank end
		return (tonumber(a and a.id) or 0) > (tonumber(b and b.id) or 0)
	end)
end

for _, typeKey in ipairs(addon.BuffFoods.typeOrder) do
	sortEntriesDescending(addon.BuffFoods.typeFoods[typeKey])
end

local function requestItemNameData()
	if not C_Item_RequestLoadItemDataByID then return end
	for _, typeKey in ipairs(addon.BuffFoods.typeOrder) do
		local entries = addon.BuffFoods.typeFoods[typeKey]
		if entries then
			for i = 1, #entries do
				local entry = entries[i]
				if entry and entry.id then C_Item_RequestLoadItemDataByID(entry.id) end
			end
		end
	end
end

requestItemNameData()

local VALID_TYPES = {}
for _, key in ipairs(addon.BuffFoods.typeOrder) do
	VALID_TYPES[key] = true
end

local function normalizeTypeKey(value)
	if type(value) ~= "string" then return "none" end
	if VALID_TYPES[value] then return value end
	return "none"
end

local function getCurrentSpecID()
	local specIndex = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization and C_SpecializationInfo.GetSpecialization()
	if not specIndex then return addon.variables and addon.variables.unitSpecId or nil end

	local specID
	if C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo then
		local info = C_SpecializationInfo.GetSpecializationInfo(specIndex)
		if type(info) == "table" then
			specID = info.specID
		else
			specID = info
		end
	end

	if type(specID) ~= "number" or specID <= 0 then return addon.variables and addon.variables.unitSpecId or nil end
	return specID
end

local function rebuildBagItemCountCache()
	if addon.functions and addon.functions.rebuildFoodBagItemCountCache then return addon.functions.rebuildFoodBagItemCountCache() end
	return {}
end

local function getBagItemCountCache()
	if addon.functions and addon.functions.getFoodBagItemCountCache then return addon.functions.getFoodBagItemCountCache() end
	return rebuildBagItemCountCache()
end

local function getDirectBagItemCount(itemId)
	local targetId = tonumber(itemId)
	if not targetId or targetId <= 0 then return 0 end

	local cache = getBagItemCountCache()
	return tonumber(cache[targetId]) or 0
end

local function getBestItemCount(itemId)
	local targetId = tonumber(itemId)
	if not targetId or targetId <= 0 then return 0, 0, 0 end

	local countBag = getDirectBagItemCount(targetId)
	return countBag, countBag, countBag
end

local function isEntryAvailable(entry, playerLevel)
	if not entry or not entry.id then return false end
	if (entry.requiredLevel or 1) > playerLevel then return false end

	local count = getBestItemCount(entry.id)
	return count > 0
end

local function appendAvailable(list, playerLevel, out, heartyOnly)
	if type(list) ~= "table" then return end
	for i = 1, #list do
		local entry = list[i]
		if entry and (heartyOnly == nil or entry.isHearty == heartyOnly) and isEntryAvailable(entry, playerLevel) then out[#out + 1] = entry end
	end
end

local function getRoleBucketForSpec(specID)
	if addon.Flasks and addon.Flasks.functions and addon.Flasks.functions.getRoleBucketForSpec then return addon.Flasks.functions.getRoleBucketForSpec(specID) end
	return nil
end

function addon.BuffFoods.functions.getPlayerSpecs()
	if addon.Flasks and addon.Flasks.functions and addon.Flasks.functions.getPlayerSpecs then return addon.Flasks.functions.getPlayerSpecs() or {} end
	return {}
end

function addon.BuffFoods.functions.getAllSpecs()
	if addon.Flasks and addon.Flasks.functions and addon.Flasks.functions.getAllSpecs then return addon.Flasks.functions.getAllSpecs() or {} end
	return addon.BuffFoods.functions.getPlayerSpecs()
end

function addon.BuffFoods.functions.getRoleBucketForSpec(specID) return getRoleBucketForSpec(specID) end

function addon.BuffFoods.functions.getTypeDisplayName(typeKey)
	if addon.BuffFoods and addon.BuffFoods.typeLabels and addon.BuffFoods.typeLabels[typeKey] then return addon.BuffFoods.typeLabels[typeKey] end

	local entries = addon.BuffFoods and addon.BuffFoods.typeFoods and addon.BuffFoods.typeFoods[typeKey]
	if type(entries) == "table" then
		for i = 1, #entries do
			local itemId = entries[i] and entries[i].id
			if itemId then
				local itemName = nil
				if C_Item_GetItemNameByID then itemName = C_Item_GetItemNameByID(itemId) end
				if (not itemName or itemName == "") and C_Item_GetItemInfo then itemName = C_Item_GetItemInfo(itemId) end
				if itemName and itemName ~= "" then return itemName end
			end
		end
	end

	return tostring(typeKey or "")
end

function addon.BuffFoods.functions.normalizeTypeKey(value) return normalizeTypeKey(value) end
function addon.BuffFoods.functions.getCurrentSpecID() return getCurrentSpecID() end
function addon.BuffFoods.functions.rebuildBagItemCountCache() return rebuildBagItemCountCache() end

local function buildCandidateCacheKey(specID, playerLevel, bagVersion, selectedType, selectedRoleKey, selectedPreference)
	local db = addon.db or {}
	return table.concat({
		tostring(tonumber(specID) or 0),
		tostring(tonumber(playerLevel) or 0),
		tostring(tonumber(bagVersion) or 0),
		tostring(selectedType or "none"),
		tostring(selectedRoleKey or "none"),
		tostring(selectedPreference or "useRole"),
		db.buffFoodPreferHearty == false and "standard" or "hearty",
	}, "|")
end

function addon.BuffFoods.functions.getAvailableCandidatesForSpec(specID)
	local playerLevel = UnitLevel("player") or 0
	local selectedType = "none"
	local selectedPreference = "useRole"
	local selectedRoleKey = nil

	local db = addon.db or {}

	if db.buffFoodPreferredBySpec and specID and db.buffFoodPreferredBySpec[specID] ~= nil then selectedPreference = db.buffFoodPreferredBySpec[specID] end
	if selectedPreference == "useRole" then
		selectedRoleKey = getRoleBucketForSpec(specID)
		local roleSelection = db.buffFoodPreferredByRole and selectedRoleKey and db.buffFoodPreferredByRole[selectedRoleKey] or nil
		selectedType = normalizeTypeKey(roleSelection)
	else
		selectedType = normalizeTypeKey(selectedPreference)
	end

	getBagItemCountCache()
	local bagVersion = addon.functions and addon.functions.getFoodBagItemCountCacheVersion and addon.functions.getFoodBagItemCountCacheVersion() or 0
	local cacheKey = buildCandidateCacheKey(specID, playerLevel, bagVersion, selectedType, selectedRoleKey, selectedPreference)
	local cache = addon.BuffFoods.candidateCache
	if cache and cache.key == cacheKey and type(cache.list) == "table" then
		return cache.list, cache.selectedType, cache.selectedRoleKey, cache.selectedPreference
	end

	local candidates = {}
	if selectedType ~= "none" then
		local list = addon.BuffFoods.typeFoods and addon.BuffFoods.typeFoods[selectedType]
		if db.buffFoodPreferHearty ~= false then
			appendAvailable(list, playerLevel, candidates, true)
			appendAvailable(list, playerLevel, candidates, false)
		else
			appendAvailable(list, playerLevel, candidates, false)
			appendAvailable(list, playerLevel, candidates, true)
		end
	end

	addon.BuffFoods.candidateCache = {
		key = cacheKey,
		list = candidates,
		selectedType = selectedType,
		selectedRoleKey = selectedRoleKey,
		selectedPreference = selectedPreference,
	}
	return candidates, selectedType, selectedRoleKey, selectedPreference
end

function addon.BuffFoods.functions.updateAllowedBuffFoods(specID)
	local resolvedSpecID = specID or getCurrentSpecID()
	local candidates, selectedType, selectedRoleKey, selectedPreference = addon.BuffFoods.functions.getAvailableCandidatesForSpec(resolvedSpecID)
	local bagVersion = addon.functions and addon.functions.getFoodBagItemCountCacheVersion and addon.functions.getFoodBagItemCountCacheVersion() or 0
	addon.BuffFoods.filteredBuffFoods = candidates
	addon.BuffFoods.lastSpecID = resolvedSpecID
	addon.BuffFoods.lastBagVersion = bagVersion
	addon.BuffFoods.lastSelectedType = selectedType
	addon.BuffFoods.lastSelectedRole = selectedRoleKey
	addon.BuffFoods.lastSelectedPreference = selectedPreference
	return candidates, selectedType
end
