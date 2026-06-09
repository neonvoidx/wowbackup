-- luacheck: globals BIND_TO_ACCOUNT BIND_TO_BNETACCOUNT BIND_TO_ACCOUNT_UNTIL_EQUIP GetExpansionName
local addonName, addon = ...
addon = addon or {}
_G[addonName] = addon

addon.Bags = addon.Bags or {}
addon.Bags.functions = addon.Bags.functions or {}
addon.Bags.variables = addon.Bags.variables or {}

local L = addon.L or {}

local BUILTIN_CATEGORY_ORDER = {
	"equipment",
	"consumables",
	"tradegoods",
	"recipes",
	"quest",
	"misc",
}

local BUILTIN_CATEGORY_DEFINITIONS = {
	equipment = {
		labelKey = "categoryEquipment",
		color = { 0.63, 0.8, 1 },
		canHide = true,
	},
	consumables = {
		labelKey = "categoryConsumables",
		color = { 0.96, 0.84, 0.33 },
		canHide = true,
	},
	tradegoods = {
		labelKey = "categoryTradeGoods",
		color = { 0.42, 0.85, 0.54 },
		canHide = true,
	},
	recipes = {
		labelKey = "categoryRecipes",
		color = { 0.86, 0.66, 1 },
		canHide = true,
	},
	quest = {
		labelKey = "categoryQuest",
		color = { 1, 0.9, 0.44 },
		canHide = true,
	},
	misc = {
		labelKey = "categoryMiscellaneous",
		color = { 0.8, 0.8, 0.8 },
		canHide = false,
	},
}

local CUSTOM_CATEGORY_COLORS = {
	{ 0.95, 0.74, 0.3 },
	{ 0.56, 0.82, 0.94 },
	{ 0.71, 0.88, 0.54 },
	{ 0.95, 0.54, 0.78 },
	{ 0.77, 0.69, 0.95 },
	{ 0.98, 0.6, 0.39 },
}

local ROOT_GROUP_OPERATOR = "OR"
local OBSOLETE_ITEM_CLASS_IDS = {
	[10] = true,
	[14] = true,
}
local OBSOLETE_SUBCLASS_KEYS = {
	["2:17"] = true,
}

local FIELD_GROUP_ORDER = {
	"basic",
	"classification",
	"smart",
	"ownership",
	"numbers",
	"flags",
}

local FIELD_GROUP_LABEL_KEYS = {
	basic = "settingsCategoryRuleGroupBasic",
	classification = "settingsCategoryRuleGroupClassification",
	smart = "settingsCategoryRuleGroupSmart",
	ownership = "settingsCategoryRuleGroupOwnership",
	numbers = "settingsCategoryRuleGroupNumbers",
	flags = "settingsCategoryRuleGroupFlags",
}

local OPERATOR_DEFINITIONS = {
	EQUALS = {
		id = "EQUALS",
		label = "=",
	},
	NOT_EQUALS = {
		id = "NOT_EQUALS",
		label = "!=",
	},
	LESS_THAN = {
		id = "LESS_THAN",
		label = "<",
	},
	LESS_OR_EQUAL = {
		id = "LESS_OR_EQUAL",
		label = "<=",
	},
	GREATER_THAN = {
		id = "GREATER_THAN",
		label = ">",
	},
	GREATER_OR_EQUAL = {
		id = "GREATER_OR_EQUAL",
		label = ">=",
	},
	AVERAGE_MINUS = {
		id = "AVERAGE_MINUS",
		label = "-",
	},
	AVERAGE_PLUS = {
		id = "AVERAGE_PLUS",
		label = "+",
	},
	IN = {
		id = "IN",
		labelKey = "settingsCategoryRuleOperatorIn",
	},
}

local UPGRADE_TRACK_META = {
	explorer = {
		labelKey = "settingsRuleValueUpgradeTrackExplorer",
		quality = Enum and Enum.ItemQuality and Enum.ItemQuality.Poor or 0,
		aliases = { "explorer" },
	},
	adventurer = {
		labelKey = "settingsRuleValueUpgradeTrackAdventurer",
		quality = Enum and Enum.ItemQuality and Enum.ItemQuality.Common or 1,
		aliases = { "adventurer" },
	},
	veteran = {
		labelKey = "settingsRuleValueUpgradeTrackVeteran",
		quality = Enum and Enum.ItemQuality and Enum.ItemQuality.Uncommon or 2,
		ids = { 972 },
		aliases = { "veteran" },
	},
	champion = {
		labelKey = "settingsRuleValueUpgradeTrackChampion",
		quality = Enum and Enum.ItemQuality and Enum.ItemQuality.Rare or 3,
		ids = { 973 },
		aliases = { "champion" },
	},
	hero = {
		labelKey = "settingsRuleValueUpgradeTrackHero",
		quality = Enum and Enum.ItemQuality and Enum.ItemQuality.Epic or 4,
		ids = { 974 },
		aliases = { "hero" },
	},
	myth = {
		labelKey = "settingsRuleValueUpgradeTrackMyth",
		quality = Enum and Enum.ItemQuality and Enum.ItemQuality.Legendary or 5,
		ids = { 975 },
		aliases = { "myth", "mythic" },
	},
}

local UPGRADE_TRACK_ORDER = {
	"explorer",
	"adventurer",
	"veteran",
	"champion",
	"hero",
	"myth",
}

local upgradeTrackAliasMap
local upgradeTrackIDMap
local upgradeTrackOptionsCache
local customCategoryStateDirty = true
local customCategoryStateRevision = 0
local customCategoryStateModeID
local customCategoryStateModeState
local customCategoryStateCategories
local customCategoryStateGroups
local customCategoryStateHiddenBuiltIn
local customCategoryCompiledState
local cachedCategoryRuleContextUsage
local cachedCategorySectionDefinitions
local BASIC_PRESET_VERSION = 22
local HOUSING_CLASS_ID = 20
local ITEM_ENHANCEMENTS_CLASS_ID = 8
local CATEGORY_MODE_IDS = {
	basic = true,
	advanced = true,
}
local NON_MISC_BUILTIN_CATEGORY_IDS = {
	"equipment",
	"consumables",
	"tradegoods",
	"recipes",
	"quest",
}
local CATEGORY_SORT_MODE_DEFINITIONS = {
	{ id = "default", labelKey = "settingsCategorySortDefault", fallback = "Default" },
	{ id = "expansion", labelKey = "settingsCategorySortModeExpansion", fallback = "Expansion" },
	{ id = "itemLevel", labelKey = "settingsCategorySortModeItemLevel", fallback = "Item level" },
	{ id = "quality", labelKey = "settingsCategorySortModeQuality", fallback = "Quality" },
	{ id = "name", labelKey = "settingsCategorySortModeName", fallback = "Name" },
	{ id = "count", labelKey = "settingsCategorySortModeCount", fallback = "Count" },
	{ id = "sellPrice", labelKey = "settingsCategorySortModeVendorPrice", fallback = "Vendor price" },
	{ id = "keystoneLevel", labelKey = "settingsCategorySortModeKeystoneLevel", fallback = "Keystone level" },
}
local CATEGORY_SORT_MODE_LOOKUP = {}
for _, definition in ipairs(CATEGORY_SORT_MODE_DEFINITIONS) do
	CATEGORY_SORT_MODE_LOOKUP[definition.id] = true
end

local ITEM_CLASS_TRADEGOODS = Enum and Enum.ItemClass and Enum.ItemClass.Tradegoods or 7
local ITEM_CLASS_MISCELLANEOUS = Enum and Enum.ItemClass and Enum.ItemClass.Miscellaneous or 15
local ITEM_MISC_OTHER_SUBCLASS_ID = 4
local PROFESSION_GROUP_DEFINITIONS = {
	{ id = "alchemyHerbalism", labelKey = "professionGroupAlchemyHerbalism", fallback = "Herbalism / Alchemy" },
	{ id = "miningSmithingEngineeringJewelcrafting", labelKey = "professionGroupMiningSmithingEngineeringJewelcrafting", fallback = "Mining / Blacksmithing / Engineering / Jewelcrafting" },
	{ id = "enchanting", labelKey = "professionGroupEnchanting", fallback = "Enchanting" },
	{ id = "inscription", labelKey = "professionGroupInscription", fallback = "Inscription" },
	{ id = "tailoring", labelKey = "professionGroupTailoring", fallback = "Tailoring" },
	{ id = "leatherworkingSkinning", labelKey = "professionGroupLeatherworkingSkinning", fallback = "Leatherworking / Skinning" },
	{ id = "cookingFishing", labelKey = "professionGroupCookingFishing", fallback = "Cooking / Fishing" },
	{ id = "craftingReagents", labelKey = "professionGroupCraftingReagents", fallback = "Crafting reagents" },
	{ id = "otherCrafting", labelKey = "professionGroupOtherCrafting", fallback = "Other crafting" },
}
local TRADEGOODS_PROFESSION_GROUP_BY_SUBCLASS_ID = {
	[0] = "otherCrafting", -- Trade Goods
	[1] = "miningSmithingEngineeringJewelcrafting", -- Parts
	[2] = "miningSmithingEngineeringJewelcrafting", -- Explosives
	[3] = "miningSmithingEngineeringJewelcrafting", -- Devices
	[4] = "miningSmithingEngineeringJewelcrafting", -- Jewelcrafting
	[5] = "tailoring", -- Cloth
	[6] = "leatherworkingSkinning", -- Leather
	[7] = "miningSmithingEngineeringJewelcrafting", -- Metal & Stone
	[8] = "cookingFishing", -- Cooking
	[9] = "alchemyHerbalism", -- Herb
	[10] = "otherCrafting", -- Elemental
	[11] = "otherCrafting", -- Other
	[12] = "enchanting",
	[13] = "inscription",
	[14] = "craftingReagents", -- Optional reagents
	[15] = "craftingReagents", -- Finishing reagents
}
local PROFESSION_GROUP_BY_TREATISE_ITEM_ID = {
	-- TODO: Review and extend this list for each major expansion when new profession knowledge treatises are added.
	[245755] = "alchemyHerbalism", -- Thalassian Treatise on Alchemy
	[245756] = "tailoring", -- Thalassian Treatise on Tailoring
	[245757] = "inscription", -- Thalassian Treatise on Inscription
	[245758] = "leatherworkingSkinning", -- Thalassian Treatise on Leatherworking
	[245759] = "enchanting", -- Thalassian Treatise on Enchanting
	[245760] = "miningSmithingEngineeringJewelcrafting", -- Thalassian Treatise on Jewelcrafting
	[245761] = "alchemyHerbalism", -- Thalassian Treatise on Herbalism
	[245762] = "miningSmithingEngineeringJewelcrafting", -- Thalassian Treatise on Mining
	[245763] = "miningSmithingEngineeringJewelcrafting", -- Thalassian Treatise on Blacksmithing
	[245809] = "miningSmithingEngineeringJewelcrafting", -- Thalassian Treatise on Engineering
	[245828] = "leatherworkingSkinning", -- Thalassian Treatise on Skinning
}

local function trimUpgradeTrackText(text)
	if type(text) ~= "string" then
		return nil
	end

	if type(strtrim) == "function" then
		text = strtrim(text)
	else
		text = text:match("^%s*(.-)%s*$")
	end

	return text ~= "" and text or nil
end

local function getFirstUtf8Char(text)
	if type(text) ~= "string" or text == "" then
		return nil
	end

	return text:match("[%z\1-\127\194-\244][\128-\191]*")
end

local function buildBooleanOptions()
	return {
		{ value = true, label = YES or "Yes" },
		{ value = false, label = NO or "No" },
	}
end

local function getUpgradeTrackLabelText(trackKey)
	local info = UPGRADE_TRACK_META[trackKey]
	if not info then
		return nil
	end

	return L[info.labelKey] or info.labelKey or trackKey
end

local function getUpgradeTrackAliasMap()
	if upgradeTrackAliasMap then
		return upgradeTrackAliasMap
	end

	upgradeTrackAliasMap = {}
	for trackKey, info in pairs(UPGRADE_TRACK_META) do
		upgradeTrackAliasMap[trackKey] = trackKey

		local localizedLabel = trimUpgradeTrackText(getUpgradeTrackLabelText(trackKey))
		if localizedLabel then
			upgradeTrackAliasMap[string.lower(localizedLabel)] = trackKey
		end

		for _, alias in ipairs(info.aliases or {}) do
			alias = trimUpgradeTrackText(alias)
			if alias then
				upgradeTrackAliasMap[string.lower(alias)] = trackKey
			end
		end
	end

	return upgradeTrackAliasMap
end

local function getUpgradeTrackIDMap()
	if upgradeTrackIDMap then
		return upgradeTrackIDMap
	end

	upgradeTrackIDMap = {}
	for trackKey, info in pairs(UPGRADE_TRACK_META) do
		for _, trackID in ipairs(info.ids or {}) do
			upgradeTrackIDMap[trackID] = trackKey
		end
	end

	return upgradeTrackIDMap
end

local function getUpgradeTrackCanonicalKey(trackID, trackString)
	if type(trackID) == "number" then
		local canonicalByID = getUpgradeTrackIDMap()[trackID]
		if canonicalByID then
			return canonicalByID
		end
	end

	trackString = trimUpgradeTrackText(trackString)
	if trackString then
		return getUpgradeTrackAliasMap()[string.lower(trackString)]
	end

	return nil
end

local function buildUpgradeTrackOptions()
	if upgradeTrackOptionsCache then
		return upgradeTrackOptionsCache
	end

	local options = {}

	for _, trackKey in ipairs(UPGRADE_TRACK_ORDER) do
		options[#options + 1] = {
			value = trackKey,
			label = getUpgradeTrackLabelText(trackKey),
		}
	end

	upgradeTrackOptionsCache = options
	return upgradeTrackOptionsCache
end

local function getItemUpgradeInfo(itemInfo)
	if not itemInfo or not (C_Item and C_Item.GetItemUpgradeInfo) then
		return nil
	end

	return C_Item.GetItemUpgradeInfo(itemInfo)
end

local function buildItemUpgradeDisplayText(itemUpgradeInfo, trackKey)
	if type(itemUpgradeInfo) ~= "table" or not trackKey then
		return nil
	end

	local currentLevel = tonumber(itemUpgradeInfo.currentLevel)
	local maxLevel = tonumber(itemUpgradeInfo.maxLevel)
	if currentLevel and maxLevel and currentLevel >= 0 and maxLevel > 0 then
		return string.format("%d/%d", currentLevel, maxLevel)
	end

	if currentLevel and currentLevel >= 0 then
		return tostring(currentLevel)
	end

	return nil
end

local function buildItemClassOptions()
	local options = {}
	local seen = {}

	for _, classID in pairs(Enum and Enum.ItemClass or {}) do
		if type(classID) == "number" and not seen[classID] and not OBSOLETE_ITEM_CLASS_IDS[classID] then
			seen[classID] = true
			local label = C_Item and C_Item.GetItemClassInfo and C_Item.GetItemClassInfo(classID)
			if label and label ~= "" then
				options[#options + 1] = {
					value = classID,
					label = label,
				}
			end
		end
	end

	table.sort(options, function(a, b)
		return (a.label or "") < (b.label or "")
	end)
	return options
end

local function buildItemSubclassOptions()
	local options = {}
	local classOptions = buildItemClassOptions()

	for _, classOption in ipairs(classOptions) do
		for subclassID = 0, 64 do
			local subclassLabel = C_Item and C_Item.GetItemSubClassInfo and C_Item.GetItemSubClassInfo(classOption.value, subclassID)
			local subclassKey = string.format("%d:%d", classOption.value, subclassID)
			if subclassLabel and subclassLabel ~= "" and not OBSOLETE_SUBCLASS_KEYS[subclassKey] then
				options[#options + 1] = {
					value = subclassKey,
					label = subclassLabel,
					groupLabel = classOption.label,
				}
			end
		end
	end

	table.sort(options, function(a, b)
		if a.groupLabel == b.groupLabel then
			return (a.label or "") < (b.label or "")
		end
		return (a.groupLabel or "") < (b.groupLabel or "")
	end)
	return options
end

local function buildProfessionGroupOptions()
	local options = {}
	for _, definition in ipairs(PROFESSION_GROUP_DEFINITIONS) do
		options[#options + 1] = {
			value = definition.id,
			label = L[definition.labelKey] or definition.fallback or definition.id,
		}
	end
	return options
end

local function getClassLabelByID(classID)
	if not (C_Item and C_Item.GetItemClassInfo) then
		return nil
	end

	local label = C_Item.GetItemClassInfo(classID)
	if type(label) == "string" and label ~= "" then
		return label
	end

	return nil
end

local function getHousingClassLabel()
	return getClassLabelByID(HOUSING_CLASS_ID) or "Housing"
end

local function getItemEnhancementsClassLabel()
	return getClassLabelByID(ITEM_ENHANCEMENTS_CLASS_ID) or "Item Enhancements"
end

function addon.GetProfessionGroupKeyForItem(classID, subClassID, itemID)
	classID = tonumber(classID)
	subClassID = tonumber(subClassID)
	if classID == ITEM_CLASS_TRADEGOODS and subClassID ~= nil then
		return TRADEGOODS_PROFESSION_GROUP_BY_SUBCLASS_ID[subClassID]
	end

	if classID ~= ITEM_CLASS_MISCELLANEOUS or subClassID ~= ITEM_MISC_OTHER_SUBCLASS_ID then
		return nil
	end

	itemID = tonumber(itemID)
	if itemID and PROFESSION_GROUP_BY_TREATISE_ITEM_ID[itemID] then
		return PROFESSION_GROUP_BY_TREATISE_ITEM_ID[itemID]
	end

	return itemID and PROFESSION_GROUP_BY_TREATISE_ITEM_ID[itemID] or nil
end

local FIELD_DEFINITIONS = {
	defaultCategory = {
		labelKey = "settingsRuleFieldDefaultCategory",
		groupID = "basic",
		valueType = "enum",
		operators = { "EQUALS", "NOT_EQUALS", "IN" },
		defaultOperator = "EQUALS",
		contextKey = "defaultCategory",
		buildOptions = function()
			local options = {}
			for _, categoryID in ipairs(BUILTIN_CATEGORY_ORDER) do
				local definition = BUILTIN_CATEGORY_DEFINITIONS[categoryID]
				options[#options + 1] = {
					value = categoryID,
					label = L[definition.labelKey] or definition.labelKey or categoryID,
				}
			end
			return options
		end,
	},
	classID = {
		labelKey = "settingsRuleFieldClass",
		groupID = "classification",
		valueType = "enum",
		operators = { "EQUALS", "NOT_EQUALS", "IN" },
		defaultOperator = "EQUALS",
		contextKey = "classID",
		buildOptions = buildItemClassOptions,
	},
	subClassKey = {
		labelKey = "settingsRuleFieldSubclass",
		groupID = "classification",
		valueType = "enum",
		operators = { "EQUALS", "NOT_EQUALS", "IN" },
		defaultOperator = "EQUALS",
		contextKey = "subClassKey",
		buildOptions = buildItemSubclassOptions,
	},
	professionGroupKey = {
		labelKey = "settingsRuleFieldProfessionGroup",
		groupID = "classification",
		valueType = "enum",
		operators = { "EQUALS", "NOT_EQUALS", "IN" },
		defaultOperator = "EQUALS",
		contextKey = "professionGroupKey",
		buildOptions = buildProfessionGroupOptions,
	},
	quality = {
		labelKey = "settingsRuleFieldQuality",
		groupID = "classification",
		valueType = "enum",
		operators = { "EQUALS", "NOT_EQUALS", "IN" },
		defaultOperator = "EQUALS",
		contextKey = "quality",
		buildOptions = function()
			local options = {}
			for quality = 0, 7 do
				local label = _G[string.format("ITEM_QUALITY%d_DESC", quality)]
				if label and label ~= "" then
					options[#options + 1] = {
						value = quality,
						label = label,
					}
				end
			end
			return options
		end,
	},
	bindType = {
		labelKey = "settingsRuleFieldBindType",
		groupID = "ownership",
		valueType = "enum",
		operators = { "EQUALS", "NOT_EQUALS", "IN" },
		defaultOperator = "EQUALS",
		contextKey = "bindType",
		buildOptions = function()
			local labels = {
				[0] = NONE or "None",
				[1] = ITEM_BIND_ON_PICKUP or "Bind on Pickup",
				[2] = ITEM_BIND_ON_EQUIP or "Bind on Equip",
				[3] = ITEM_BIND_ON_USE or "Bind on Use",
				[4] = ITEM_BIND_QUEST or "Quest Item",
				[7] = BIND_TO_ACCOUNT or "Warbound",
				[8] = BIND_TO_BNETACCOUNT or "Bind to Battle.net Account",
				[9] = BIND_TO_ACCOUNT_UNTIL_EQUIP or "Warbound Until Equipped",
			}
			local ordered = { 0, 1, 2, 3, 4, 7, 8, 9 }
			local options = {}

			for _, bindType in ipairs(ordered) do
				options[#options + 1] = {
					value = bindType,
					label = labels[bindType] or tostring(bindType),
				}
			end

			return options
		end,
	},
	equipLoc = {
		labelKey = "settingsRuleFieldEquipLoc",
		groupID = "classification",
		valueType = "enum",
		operators = { "EQUALS", "NOT_EQUALS", "IN" },
		defaultOperator = "EQUALS",
		contextKey = "equipLoc",
		buildOptions = function()
			local orderedValues = {
				"INVTYPE_HEAD",
				"INVTYPE_NECK",
				"INVTYPE_SHOULDER",
				"INVTYPE_CHEST",
				"INVTYPE_ROBE",
				"INVTYPE_WAIST",
				"INVTYPE_LEGS",
				"INVTYPE_FEET",
				"INVTYPE_WRIST",
				"INVTYPE_HAND",
				"INVTYPE_FINGER",
				"INVTYPE_TRINKET",
				"INVTYPE_CLOAK",
				"INVTYPE_WEAPON",
				"INVTYPE_SHIELD",
				"INVTYPE_2HWEAPON",
				"INVTYPE_WEAPONMAINHAND",
				"INVTYPE_WEAPONOFFHAND",
				"INVTYPE_HOLDABLE",
				"INVTYPE_RANGED",
				"INVTYPE_RANGEDRIGHT",
				"INVTYPE_TABARD",
				"INVTYPE_BODY",
				"INVTYPE_BAG",
			}
			local options = {}

			for _, equipLoc in ipairs(orderedValues) do
				local label = _G[equipLoc]
				if label and label ~= "" then
					options[#options + 1] = {
						value = equipLoc,
						label = label,
						disambiguator = tostring(equipLoc):gsub("^INVTYPE_", ""),
					}
				end
			end

			local labelCounts = {}
			for _, option in ipairs(options) do
				labelCounts[option.label] = (labelCounts[option.label] or 0) + 1
			end
			for _, option in ipairs(options) do
				if labelCounts[option.label] and labelCounts[option.label] > 1 then
					option.label = string.format(L["settingsEquipLocDuplicateFormat"] or "%s (%s)", option.label, option.disambiguator)
				end
				option.disambiguator = nil
			end

			table.sort(options, function(a, b)
				return (a.label or "") < (b.label or "")
			end)
			return options
		end,
	},
	expansionID = {
		labelKey = "settingsRuleFieldExpansion",
		groupID = "classification",
		valueType = "enum",
		operators = { "EQUALS", "NOT_EQUALS", "IN" },
		defaultOperator = "EQUALS",
		contextKey = "expansionID",
		buildOptions = function()
			local options = {}
			for expansionID = 0, (LE_EXPANSION_LEVEL_CURRENT or 0) do
				local label = type(GetExpansionName) == "function" and GetExpansionName(expansionID) or nil
				label = label or _G[string.format("EXPANSION_NAME%d", expansionID)]
				if label and label ~= "" then
					options[#options + 1] = {
						value = expansionID,
						label = label,
					}
				end
			end
			return options
		end,
	},
	recommendedForSpec = {
		labelKey = "settingsRuleFieldRecommendedForSpec",
		groupID = "smart",
		valueType = "enum",
		operators = { "EQUALS" },
		defaultOperator = "EQUALS",
		contextKey = "recommendedForSpec",
		buildOptions = buildBooleanOptions,
	},
	recommendedForClass = {
		labelKey = "settingsRuleFieldRecommendedForClass",
		groupID = "smart",
		valueType = "enum",
		operators = { "EQUALS" },
		defaultOperator = "EQUALS",
		contextKey = "recommendedForClass",
		buildOptions = buildBooleanOptions,
	},
	isUpgrade = {
		labelKey = "settingsRuleFieldUpgradeOnly",
		groupID = "smart",
		valueType = "enum",
		operators = { "EQUALS" },
		defaultOperator = "EQUALS",
		contextKey = "isUpgrade",
		buildOptions = buildBooleanOptions,
	},
	itemLevelRelativeToEquippedAverage = {
		labelKey = "settingsRuleFieldItemLevelRelativeToEquippedAverage",
		groupID = "smart",
		valueType = "number",
		operators = { "AVERAGE_MINUS", "AVERAGE_PLUS" },
		defaultOperator = "AVERAGE_MINUS",
		defaultValue = 20,
		contextKey = "itemLevel",
		comparisonContextKey = "equippedAverageItemLevel",
		comparisonValueMode = "equippedAverageOffset",
	},
	upgradeTrackKey = {
		labelKey = "settingsRuleFieldUpgradeTrack",
		groupID = "smart",
		valueType = "enum",
		operators = { "EQUALS", "NOT_EQUALS", "IN" },
		defaultOperator = "EQUALS",
		contextKey = "upgradeTrackKey",
		buildOptions = buildUpgradeTrackOptions,
	},
	canVendor = {
		labelKey = "settingsRuleFieldCanVendor",
		groupID = "smart",
		valueType = "enum",
		operators = { "EQUALS" },
		defaultOperator = "EQUALS",
		contextKey = "canVendor",
		buildOptions = buildBooleanOptions,
	},
	canAuctionHouseSell = {
		labelKey = "settingsRuleFieldCanAuctionHouseSell",
		groupID = "smart",
		valueType = "enum",
		operators = { "EQUALS" },
		defaultOperator = "EQUALS",
		contextKey = "canAuctionHouseSell",
		buildOptions = buildBooleanOptions,
	},
	isEquipmentSet = {
		labelKey = "settingsRuleFieldEquipmentSet",
		groupID = "smart",
		valueType = "enum",
		operators = { "EQUALS" },
		defaultOperator = "EQUALS",
		contextKey = "isEquipmentSet",
		buildOptions = buildBooleanOptions,
	},
	isTeleportItem = {
		labelKey = "settingsRuleFieldTeleportItem",
		groupID = "smart",
		valueType = "enum",
		operators = { "EQUALS" },
		defaultOperator = "EQUALS",
		contextKey = "isTeleportItem",
		buildOptions = buildBooleanOptions,
	},
	isHearthstone = {
		labelKey = "settingsRuleFieldHearthstone",
		groupID = "smart",
		valueType = "enum",
		operators = { "EQUALS" },
		defaultOperator = "EQUALS",
		contextKey = "isHearthstone",
		buildOptions = buildBooleanOptions,
	},
	isTransmogSet = {
		labelKey = "settingsRuleFieldTransmogSet",
		groupID = "smart",
		valueType = "enum",
		operators = { "EQUALS" },
		defaultOperator = "EQUALS",
		contextKey = "isTransmogSet",
		buildOptions = buildBooleanOptions,
	},
	isToy = {
		labelKey = "settingsRuleFieldToy",
		groupID = "smart",
		valueType = "enum",
		operators = { "EQUALS" },
		defaultOperator = "EQUALS",
		contextKey = "isToy",
		buildOptions = buildBooleanOptions,
	},
	isKeystone = {
		labelKey = "settingsRuleFieldKeystone",
		groupID = "smart",
		valueType = "enum",
		operators = { "EQUALS" },
		defaultOperator = "EQUALS",
		contextKey = "isKeystone",
		buildOptions = buildBooleanOptions,
	},
	isPvpItem = {
		labelKey = "settingsRuleFieldPvpItem",
		groupID = "smart",
		valueType = "enum",
		operators = { "EQUALS" },
		defaultOperator = "EQUALS",
		contextKey = "isPvpItem",
		buildOptions = buildBooleanOptions,
	},
	itemLevel = {
		labelKey = "settingsRuleFieldItemLevel",
		groupID = "numbers",
		valueType = "number",
		operators = { "EQUALS", "LESS_THAN", "LESS_OR_EQUAL", "GREATER_THAN", "GREATER_OR_EQUAL" },
		defaultOperator = "GREATER_OR_EQUAL",
		defaultValue = 1,
		contextKey = "itemLevel",
	},
	itemMinLevel = {
		labelKey = "settingsRuleFieldRequiredLevel",
		groupID = "numbers",
		valueType = "number",
		operators = { "EQUALS", "LESS_THAN", "LESS_OR_EQUAL", "GREATER_THAN", "GREATER_OR_EQUAL" },
		defaultOperator = "GREATER_OR_EQUAL",
		defaultValue = 1,
		contextKey = "itemMinLevel",
	},
	itemStackCount = {
		labelKey = "settingsRuleFieldStackCount",
		groupID = "numbers",
		valueType = "number",
		operators = { "EQUALS", "LESS_THAN", "LESS_OR_EQUAL", "GREATER_THAN", "GREATER_OR_EQUAL" },
		defaultOperator = "GREATER_OR_EQUAL",
		defaultValue = 1,
		contextKey = "itemStackCount",
	},
	sellPrice = {
		labelKey = "settingsRuleFieldSellPrice",
		groupID = "numbers",
		valueType = "number",
		operators = { "EQUALS", "LESS_THAN", "LESS_OR_EQUAL", "GREATER_THAN", "GREATER_OR_EQUAL" },
		defaultOperator = "GREATER_OR_EQUAL",
		defaultValue = 0,
		contextKey = "sellPrice",
	},
	isCraftingReagent = {
		labelKey = "settingsRuleFieldCraftingReagent",
		groupID = "flags",
		valueType = "enum",
		operators = { "EQUALS" },
		defaultOperator = "EQUALS",
		contextKey = "isCraftingReagent",
		buildOptions = buildBooleanOptions,
	},
	isBound = {
		labelKey = "settingsRuleFieldBound",
		groupID = "flags",
		valueType = "enum",
		operators = { "EQUALS" },
		defaultOperator = "EQUALS",
		contextKey = "isBound",
		buildOptions = buildBooleanOptions,
	},
}

local LEGACY_RULE_TYPE_MAP = {
	defaultCategory = "defaultCategory",
	itemClass = "classID",
	itemSubclass = "subClassKey",
	itemQuality = "quality",
	bindType = "bindType",
	equipLoc = "equipLoc",
	expansionID = "expansionID",
	itemLevel = "itemLevel",
	itemMinLevel = "itemMinLevel",
	sellPrice = "sellPrice",
}

local optionCache = {}
local optionLookupCache = {}

local function trimText(value)
	if type(strtrim) == "function" then
		return strtrim(value or "")
	end

	return (value or ""):match("^%s*(.-)%s*$")
end

local function getSettings()
	if addon.GetSettings then
		return addon.GetSettings()
	end

	addon.DB = addon.DB or {}
	addon.DB.settings = addon.DB.settings or {}
	return addon.DB.settings
end

local function normalizeCategoryMode(mode)
	mode = tostring(mode or "")
	if CATEGORY_MODE_IDS[mode] then
		return mode
	end
	return "basic"
end

local function ensureModeStateDefaults(modeState)
	modeState = type(modeState) == "table" and modeState or {}
	modeState.customCategories = type(modeState.customCategories) == "table" and modeState.customCategories or {}
	modeState.customGroups = type(modeState.customGroups) == "table" and modeState.customGroups or {}
	modeState.hiddenBuiltInCategories = type(modeState.hiddenBuiltInCategories) == "table" and modeState.hiddenBuiltInCategories or {}
	modeState.hiddenBuiltInCategories.misc = nil
	modeState.nextCustomCategoryID = tonumber(modeState.nextCustomCategoryID) or 0
	modeState.nextCustomGroupID = tonumber(modeState.nextCustomGroupID) or 0
	modeState.nextCustomCategoryNodeID = tonumber(modeState.nextCustomCategoryNodeID) or 0
	modeState.nextCustomCategorySortOrder = tonumber(modeState.nextCustomCategorySortOrder) or 0
	modeState.presetVersionApplied = tonumber(modeState.presetVersionApplied) or 0
	return modeState
end

local function getCategoryModesTable()
	local settings = getSettings()
	settings.categoryModes = type(settings.categoryModes) == "table" and settings.categoryModes or {}
	settings.categoryModes.basic = ensureModeStateDefaults(settings.categoryModes.basic)
	settings.categoryModes.advanced = ensureModeStateDefaults(settings.categoryModes.advanced)
	return settings.categoryModes
end

local function getCategoryModeState(mode)
	local modes = getCategoryModesTable()
	mode = normalizeCategoryMode(mode or (addon.GetActiveCategoryMode and addon.GetActiveCategoryMode()) or "basic")
	modes[mode] = ensureModeStateDefaults(modes[mode])
	return modes[mode], mode
end

local function resetCategoryModeState(modeState)
	modeState = ensureModeStateDefaults(modeState)
	wipe(modeState.customCategories)
	wipe(modeState.customGroups)
	wipe(modeState.hiddenBuiltInCategories)
	modeState.hiddenBuiltInCategories.misc = nil
	modeState.nextCustomCategoryID = 0
	modeState.nextCustomGroupID = 0
	modeState.nextCustomCategoryNodeID = 0
	modeState.nextCustomCategorySortOrder = 0
	modeState.presetVersionApplied = 0
	return modeState
end

local function hideStandardBuiltInCategories(hiddenBuiltInCategories)
	hiddenBuiltInCategories = type(hiddenBuiltInCategories) == "table" and hiddenBuiltInCategories or {}
	for _, categoryID in ipairs(NON_MISC_BUILTIN_CATEGORY_IDS) do
		hiddenBuiltInCategories[categoryID] = true
	end
	hiddenBuiltInCategories.misc = nil
	return hiddenBuiltInCategories
end

local function deepCopyValue(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, nestedValue in pairs(value) do
		copy[key] = deepCopyValue(nestedValue)
	end
	return copy
end

local function copyModeStateContents(sourceState, targetState)
	sourceState = ensureModeStateDefaults(sourceState)
	targetState = resetCategoryModeState(targetState)

	for _, group in ipairs(sourceState.customGroups or {}) do
		targetState.customGroups[#targetState.customGroups + 1] = deepCopyValue(group)
	end
	for _, category in ipairs(sourceState.customCategories or {}) do
		targetState.customCategories[#targetState.customCategories + 1] = deepCopyValue(category)
	end
	for categoryID, isHidden in pairs(sourceState.hiddenBuiltInCategories or {}) do
		targetState.hiddenBuiltInCategories[categoryID] = isHidden and true or nil
	end

	targetState.nextCustomCategoryID = tonumber(sourceState.nextCustomCategoryID) or 0
	targetState.nextCustomGroupID = tonumber(sourceState.nextCustomGroupID) or 0
	targetState.nextCustomCategoryNodeID = tonumber(sourceState.nextCustomCategoryNodeID) or 0
	targetState.nextCustomCategorySortOrder = tonumber(sourceState.nextCustomCategorySortOrder) or 0
	targetState.presetVersionApplied = tonumber(sourceState.presetVersionApplied) or 0
	targetState.hiddenBuiltInCategories.misc = nil
	return targetState
end

local function copyColor(color)
	return { color[1], color[2], color[3] }
end

local function sanitizeColor(color, fallback)
	local defaultColor = fallback or { 1, 1, 1 }
	if type(color) ~= "table" then
		return copyColor(defaultColor)
	end

	local sanitized = {}
	for index = 1, 3 do
		local value = tonumber(color[index]) or defaultColor[index] or 1
		if value < 0 then
			value = 0
		elseif value > 1 then
			value = 1
		end
		sanitized[index] = value
	end

	return sanitized
end

local function getDefaultCategoryColor(index)
	local color = CUSTOM_CATEGORY_COLORS[((index - 1) % #CUSTOM_CATEGORY_COLORS) + 1]
	return copyColor(color)
end

local function nextCounter(counterState, key)
	counterState[key] = (tonumber(counterState[key]) or 0) + 1
	return counterState[key]
end

local function allocateCategoryID(counterState)
	return string.format("custom-%d", nextCounter(counterState, "nextCustomCategoryID"))
end

local function allocateGroupID(counterState)
	return string.format("group-%d", nextCounter(counterState, "nextCustomGroupID"))
end

local function allocateNodeID(counterState)
	return string.format("node-%d", nextCounter(counterState, "nextCustomCategoryNodeID"))
end

local function allocateSortOrder(counterState)
	return nextCounter(counterState, "nextCustomCategorySortOrder")
end

local function getCustomCategoriesTable(mode)
	local modeState = getCategoryModeState(mode)
	return modeState.customCategories
end

local function getCustomCategoryGroupsTable(mode)
	local modeState = getCategoryModeState(mode)
	return modeState.customGroups
end

local function getHiddenBuiltInCategories(mode)
	local modeState = getCategoryModeState(mode)
	modeState.hiddenBuiltInCategories.misc = nil
	return modeState.hiddenBuiltInCategories
end

local function markCustomCategoryStateDirty()
	customCategoryStateRevision = customCategoryStateRevision + 1
	customCategoryStateDirty = true
	customCategoryCompiledState = nil
	cachedCategoryRuleContextUsage = nil
	cachedCategorySectionDefinitions = nil
end

local function getFieldDefinition(fieldID)
	return FIELD_DEFINITIONS[fieldID] or FIELD_DEFINITIONS.defaultCategory
end

local function getNodeFieldID(ruleNode)
	if type(ruleNode) == "table" then
		return ruleNode.field or ruleNode.ruleType
	end
	return ruleNode
end

local function buildOptionsForField(fieldID)
	local definition = getFieldDefinition(fieldID)
	return definition.buildOptions and definition.buildOptions() or {}
end

local function getFieldOptions(fieldID)
	if not optionCache[fieldID] then
		local options = buildOptionsForField(fieldID)
		local lookup = {}

		for _, option in ipairs(options) do
			lookup[tostring(option.value)] = option
		end

		optionCache[fieldID] = options
		optionLookupCache[fieldID] = lookup
	end

	return optionCache[fieldID], optionLookupCache[fieldID]
end

local function getOperatorDefinition(operatorID)
	return OPERATOR_DEFINITIONS[operatorID]
end

local function getFieldDefaultOperator(fieldID)
	local definition = getFieldDefinition(fieldID)
	return definition.defaultOperator or definition.operators[1]
end

local function sanitizeOperator(fieldID, operatorID)
	local definition = getFieldDefinition(fieldID)
	for _, candidate in ipairs(definition.operators or {}) do
		if candidate == operatorID then
			return operatorID
		end
	end
	return getFieldDefaultOperator(fieldID)
end

local function getDefaultFieldValue(fieldID, operatorID)
	local definition = getFieldDefinition(fieldID)
	if definition.valueType == "number" then
		return tonumber(definition.defaultValue) or 0
	end

	local options = getFieldOptions(fieldID)
	local firstOption = options and options[1]
	if operatorID == "IN" then
		return firstOption and { firstOption.value } or {}
	end
	if firstOption then
		return firstOption.value
	end
	return nil
end

local function sanitizeEnumValue(fieldID, operatorID, value)
	local options, lookup = getFieldOptions(fieldID)
	if #options == 0 then
		return operatorID == "IN" and {} or nil
	end

	if operatorID == "IN" then
		local normalized = {}
		local seen = {}
		local sourceValues = type(value) == "table" and value or { value }

		for _, candidate in ipairs(sourceValues) do
			local option = lookup[tostring(candidate)]
			if option and not seen[tostring(option.value)] then
				normalized[#normalized + 1] = option.value
				seen[tostring(option.value)] = true
			end
		end

		if #normalized == 0 then
			normalized[1] = options[1].value
		end

		return normalized
	end

	local option = lookup[tostring(value)]
	if option then
		return option.value
	end
	return options[1].value
end

local function sanitizeNumericValue(fieldID, value)
	local definition = getFieldDefinition(fieldID)
	local numericValue = tonumber(value)
	if not numericValue then
		numericValue = tonumber(definition.defaultValue) or 0
	end

	numericValue = math.floor(numericValue + 0.5)
	if numericValue < 0 then
		numericValue = 0
	end
	return numericValue
end

local function sanitizeRuleValue(fieldID, operatorID, value)
	local definition = getFieldDefinition(fieldID)
	if definition.valueType == "number" then
		return sanitizeNumericValue(fieldID, value)
	end
	return sanitizeEnumValue(fieldID, operatorID, value)
end

local function sanitizeRuleNode(settings, node)
	node = type(node) == "table" and node or {}

	local fieldID = node.field or LEGACY_RULE_TYPE_MAP[node.ruleType] or "defaultCategory"
	if fieldID == "itemLevelBelowEquipped" then
		fieldID = "itemLevelRelativeToEquippedAverage"
	end
	node.nodeType = "rule"
	node.id = tostring(node.id or allocateNodeID(settings))
	node.field = FIELD_DEFINITIONS[fieldID] and fieldID or "defaultCategory"
	node.ruleType = nil
	node.operator = sanitizeOperator(node.field, node.operator)
	node.value = sanitizeRuleValue(node.field, node.operator, node.value)
	return node
end

local function buildCompiledRuleNode(node, usage)
	if not node then
		return nil
	end

	if node.nodeType == "group" then
		local compiledChildren = {}
		for _, child in ipairs(node.children or {}) do
			local compiledChild = buildCompiledRuleNode(child, usage)
			if compiledChild then
				compiledChildren[#compiledChildren + 1] = compiledChild
			end
		end

		return {
			nodeType = "group",
			operator = node.operator == "AND" and "AND" or ROOT_GROUP_OPERATOR,
			children = compiledChildren,
		}
	end

	local definition = getFieldDefinition(node.field)
	if definition.contextKey then
		usage[definition.contextKey] = true
	end
	if definition.comparisonContextKey then
		usage[definition.comparisonContextKey] = true
	end

	local compiledNode = {
		nodeType = "rule",
		field = node.field,
		operator = node.operator,
		contextKey = definition.contextKey,
		comparisonContextKey = definition.comparisonContextKey,
		comparisonValueMode = definition.comparisonValueMode,
		valueType = definition.valueType,
	}

	if definition.valueType == "number" then
		compiledNode.value = tonumber(node.value) or 0
	elseif node.operator == "IN" then
		local valueSet = {}
		for _, candidate in ipairs(type(node.value) == "table" and node.value or {}) do
			valueSet[candidate] = true
		end
		compiledNode.value = node.value
		compiledNode.valueSet = valueSet
	else
		compiledNode.value = node.value
	end

	return compiledNode
end

local function evaluateCompiledRuleNode(node, itemContext)
	if not node or not itemContext then
		return false
	end

	if node.nodeType == "group" then
		local children = node.children or {}
		if #children == 0 then
			return false
		end

		if node.operator == "AND" then
			for _, child in ipairs(children) do
				if not evaluateCompiledRuleNode(child, itemContext) then
					return false
				end
			end
			return true
		end

		for _, child in ipairs(children) do
			if evaluateCompiledRuleNode(child, itemContext) then
				return true
			end
		end

		return false
	end

	local contextKey = node.contextKey
	if not contextKey then
		return false
	end

	local actualValue = itemContext[contextKey]
	if actualValue == nil then
		return false
	end

	local operatorID = node.operator
	local expectedValue = node.value
	if node.comparisonContextKey and node.comparisonValueMode == "equippedAverageOffset" then
		local comparisonBase = tonumber(itemContext[node.comparisonContextKey])
		local offsetValue = tonumber(node.value)
		if comparisonBase and offsetValue then
			expectedValue = node.operator == "AVERAGE_PLUS" and comparisonBase + offsetValue or comparisonBase - offsetValue
		else
			expectedValue = nil
		end
		if expectedValue == nil then
			return false
		end
		return tonumber(actualValue) and tonumber(actualValue) >= expectedValue or false
	end

	if operatorID == "IN" then
		return node.valueSet and node.valueSet[actualValue] == true or false
	elseif operatorID == "NOT_EQUALS" then
		return actualValue ~= expectedValue
	elseif operatorID == "LESS_THAN" then
		local actualNumber = tonumber(actualValue)
		return actualNumber and actualNumber < expectedValue or false
	elseif operatorID == "LESS_OR_EQUAL" then
		local actualNumber = tonumber(actualValue)
		return actualNumber and actualNumber <= expectedValue or false
	elseif operatorID == "GREATER_THAN" then
		local actualNumber = tonumber(actualValue)
		return actualNumber and actualNumber > expectedValue or false
	elseif operatorID == "GREATER_OR_EQUAL" then
		local actualNumber = tonumber(actualValue)
		return actualNumber and actualNumber >= expectedValue or false
	end

	return actualValue == expectedValue
end

local sanitizeGroupName

local function compareEntriesBySortOrder(a, b)
	local aSortOrder = tonumber(a and a.sortOrder) or 0
	local bSortOrder = tonumber(b and b.sortOrder) or 0
	if aSortOrder ~= bSortOrder then
		return aSortOrder < bSortOrder
	end

	return (a and a.name or "") < (b and b.name or "")
end

local function compareCategoriesByPriority(a, b)
	local aPriority = tonumber(a and a.priority) or 0
	local bPriority = tonumber(b and b.priority) or 0
	if aPriority ~= bPriority then
		return aPriority > bPriority
	end

	return compareEntriesBySortOrder(a, b)
end

local function compareDisplayEntriesBySortOrder(a, b)
	return compareEntriesBySortOrder(a, b)
end

local function buildCompiledCustomCategoryState(categories, groups)
	local compiledState = {
		revision = customCategoryStateRevision,
		sourceCategories = categories,
		sourceGroups = groups,
		categories = {},
		categoryByID = {},
		itemIDToCategoryID = {},
		contextUsage = {},
		sectionDefinitions = {},
		hiddenSectionIDs = {},
	}

	local hiddenGroupIDs = {}
	for _, group in ipairs(groups or {}) do
		if group.hidden == true then
			hiddenGroupIDs[group.id] = true
		end
	end

	local matchingCategories = {}
	for _, category in ipairs(categories or {}) do
		matchingCategories[#matchingCategories + 1] = category
	end
	table.sort(matchingCategories, compareCategoriesByPriority)

	for _, category in ipairs(matchingCategories) do
		local compiledCategory = {
			id = category.id,
			name = category.name,
			priority = category.priority,
			sortOrder = category.sortOrder,
			sortMode = category.sortMode,
			color = category.color,
			groupID = category.groupID,
			hidden = category.hidden == true or hiddenGroupIDs[category.groupID] == true,
			itemIDs = category.itemIDs,
			ruleTree = buildCompiledRuleNode(category.ruleTree, compiledState.contextUsage),
			isCustom = true,
		}
		if compiledCategory.hidden then
			compiledState.hiddenSectionIDs[category.id] = true
		end

		for _, itemID in ipairs(category.itemIDs or {}) do
			if compiledState.itemIDToCategoryID[itemID] == nil then
				compiledState.itemIDToCategoryID[itemID] = category.id
			end
		end

		compiledState.categories[#compiledState.categories + 1] = compiledCategory
		compiledState.categoryByID[category.id] = compiledCategory
	end

	local groupByID = {}
	local categoriesByGroupID = {}
	local topLevelEntries = {}

	local function appendSectionDefinitionForEntry(entry)
		if entry.kind == "group" then
			local group = entry.group
			if group.hidden == true then
				return
			end
			for _, category in ipairs(categoriesByGroupID[group.id] or {}) do
				if category.hidden ~= true then
					compiledState.sectionDefinitions[#compiledState.sectionDefinitions + 1] = {
						id = category.id,
						label = category.name,
						color = category.color,
						sortMode = category.sortMode,
						isCustom = true,
						groupID = group.id,
						groupLabel = group.name,
						groupColor = group.color,
						groupCollapseID = string.format("group:%s", group.id),
						groupSpacerBefore = group.spacerBefore == true,
						groupCombineSubcategories = group.combineSubcategories == true,
						desaturateItems = category.desaturateItems == true or group.desaturateItems == true,
						collapsible = false,
					}
				end
			end
		elseif entry.category then
			local category = entry.category
			if category.hidden ~= true then
				compiledState.sectionDefinitions[#compiledState.sectionDefinitions + 1] = {
					id = category.id,
					label = category.name,
					color = category.color,
					sortMode = category.sortMode,
					isCustom = true,
					desaturateItems = category.desaturateItems == true,
				}
			end
		end
	end

	for _, group in ipairs(groups or {}) do
		groupByID[group.id] = group
		categoriesByGroupID[group.id] = {}
		topLevelEntries[#topLevelEntries + 1] = {
			kind = "group",
			sortOrder = group.sortOrder,
			name = group.name,
			group = group,
			afterBuiltins = group.renderAfterBuiltIns == true,
		}
	end

	for _, category in ipairs(categories or {}) do
		if category.groupID and groupByID[category.groupID] then
			local groupedCategories = categoriesByGroupID[category.groupID]
			groupedCategories[#groupedCategories + 1] = category
		else
			topLevelEntries[#topLevelEntries + 1] = {
				kind = "category",
				sortOrder = category.sortOrder,
				name = category.name,
				category = category,
				afterBuiltins = category.renderAfterBuiltIns == true,
			}
		end
	end

	for _, groupedCategories in pairs(categoriesByGroupID) do
		table.sort(groupedCategories, compareEntriesBySortOrder)
	end
	table.sort(topLevelEntries, compareDisplayEntriesBySortOrder)

	for _, entry in ipairs(topLevelEntries) do
		if not entry.afterBuiltins then
			appendSectionDefinitionForEntry(entry)
		end
	end

	for _, categoryID in ipairs(BUILTIN_CATEGORY_ORDER) do
		if addon.IsBuiltInCategoryVisible(categoryID) then
			local definition = BUILTIN_CATEGORY_DEFINITIONS[categoryID]
			compiledState.sectionDefinitions[#compiledState.sectionDefinitions + 1] = {
				id = categoryID,
				labelKey = definition.labelKey,
				color = definition.color,
			}
		end
	end

	for _, entry in ipairs(topLevelEntries) do
		if entry.afterBuiltins then
			appendSectionDefinitionForEntry(entry)
		end
	end

	return compiledState
end

local function sanitizeGroupNode(settings, node)
	node = type(node) == "table" and node or {}
	node.nodeType = "group"
	node.id = tostring(node.id or allocateNodeID(settings))
	node.operator = node.operator == "AND" and "AND" or "OR"
	node.children = type(node.children) == "table" and node.children or {}

	for index, child in ipairs(node.children) do
		if type(child) == "table" and child.nodeType == "group" then
			node.children[index] = sanitizeGroupNode(settings, child)
		else
			node.children[index] = sanitizeRuleNode(settings, child)
		end
	end

	return node
end

local function sanitizeItemIDs(itemIDs)
	local normalized = {}
	local seen = {}

	for _, itemID in ipairs(type(itemIDs) == "table" and itemIDs or {}) do
		itemID = tonumber(itemID)
		if itemID and itemID > 0 and not seen[itemID] then
			normalized[#normalized + 1] = itemID
			seen[itemID] = true
		end
	end

	table.sort(normalized)
	return normalized
end

local function sanitizePriority(priority)
	priority = math.floor((tonumber(priority) or 0) + 0.5)
	if priority < 0 then
		priority = 0
	elseif priority > 100 then
		priority = 100
	end
	return priority
end

sanitizeGroupName = function(groupName)
	groupName = trimText(groupName)
	if groupName == "" then
		return nil
	end

	return groupName
end

local function sanitizeCustomGroup(settings, group, index)
	group = type(group) == "table" and group or {}
	group.id = tostring(group.id or allocateGroupID(settings))
	group.sortOrder = math.floor(tonumber(group.sortOrder) or allocateSortOrder(settings))
	group.name = sanitizeGroupName(group.name) or string.format("%s %d", L["settingsCategoryGroupLabel"] or "Group", index)
	group.color = sanitizeColor(group.color, getDefaultCategoryColor(index))
	group.spacerBefore = group.spacerBefore == true
	group.combineSubcategories = group.combineSubcategories == true
	group.desaturateItems = group.desaturateItems == true
	group.hidden = group.hidden == true
	return group
end

local function migrateLegacyCategoryGroups(settings, groups, categories)
	local groupNameLookup = {}
	for _, group in ipairs(groups) do
		local groupName = sanitizeGroupName(group.name)
		if groupName then
			groupNameLookup[string.lower(groupName)] = group
		end
	end

	local nextIndex = #groups
	for _, category in ipairs(categories or {}) do
		local legacyGroupName = sanitizeGroupName(category.groupName)
		if legacyGroupName and not category.groupID then
			local groupKey = string.lower(legacyGroupName)
			local group = groupNameLookup[groupKey]
			if not group then
				nextIndex = nextIndex + 1
				group = sanitizeCustomGroup(settings, {
					name = legacyGroupName,
					color = category.color,
				}, nextIndex)
				groups[#groups + 1] = group
				groupNameLookup[groupKey] = group
			end
			category.groupID = group.id
		end
		category.groupName = nil
	end
end

local function sanitizeCategory(settings, category, index, validGroupLookup)
	category = type(category) == "table" and category or {}
	category.id = tostring(category.id or allocateCategoryID(settings))
	category.sortOrder = math.floor(tonumber(category.sortOrder) or allocateSortOrder(settings))
	category.name = trimText(category.name)
	if category.name == "" then
		category.name = string.format("%s %d", L["settingsCategoryCustomDefaultName"] or "Category", index)
	end

	category.priority = sanitizePriority(category.priority)
	category.color = sanitizeColor(category.color, getDefaultCategoryColor(index))
	category.sortMode = CATEGORY_SORT_MODE_LOOKUP[tostring(category.sortMode or "")] and tostring(category.sortMode) or nil
	if category.sortMode == "default" then
		category.sortMode = nil
	end
	category.groupID = validGroupLookup and validGroupLookup[tostring(category.groupID or "")] and tostring(category.groupID) or nil
	category.groupName = nil
	category.hidden = category.hidden == true
	category.desaturateItems = category.desaturateItems == true
	category.itemIDs = sanitizeItemIDs(category.itemIDs)
	category.ruleTree = sanitizeGroupNode(settings, category.ruleTree)
	category.ruleTree.operator = category.ruleTree.operator == "AND" and "AND" or ROOT_GROUP_OPERATOR
	return category
end

local function buildPresetRule(counterState, field, operator, value)
	return sanitizeRuleNode(counterState, {
		field = field,
		operator = operator,
		value = value,
	})
end

local function buildPresetRuleGroup(counterState, operator, children)
	return sanitizeGroupNode(counterState, {
		operator = operator,
		children = children,
	})
end

local function seedBasicPresetIntoModeState(modeState)
	modeState = resetCategoryModeState(modeState)
	hideStandardBuiltInCategories(modeState.hiddenBuiltInCategories)

	local presetGroups = {
		{
			name = L["basicPresetGroupGear"] or "Gear",
			color = { 0.63, 0.8, 1 },
			categories = {
				{
					name = L["basicPresetCategoryUpgrades"] or "Upgrades",
					priority = 95,
					sortMode = "itemLevel",
					color = { 0.77, 0.9, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "recommendedForClass", "EQUALS", true),
							buildPresetRule(counterState, "isUpgrade", "EQUALS", true),
						})
					end,
				},
				{
					name = L["basicPresetCategoryEquipmentSets"] or "Equipment Sets",
					priority = 96,
					sortMode = "itemLevel",
					color = { 0.6, 0.76, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "isEquipmentSet", "EQUALS", true),
						})
					end,
				},
				{
					name = L["basicPresetCategoryTrinkets"] or "Trinkets",
					priority = 88,
					sortMode = "itemLevel",
					color = { 0.74, 0.88, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "equipment"),
							buildPresetRule(counterState, "equipLoc", "EQUALS", "INVTYPE_TRINKET"),
						})
					end,
				},
				{
					name = L["basicPresetCategoryRings"] or "Jewelry",
					priority = 87,
					sortMode = "itemLevel",
					color = { 0.72, 0.85, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "equipment"),
							buildPresetRule(counterState, "equipLoc", "IN", {
								"INVTYPE_FINGER",
								"INVTYPE_NECK",
							}),
						})
					end,
				},
				{
					name = L["basicPresetCategoryWeapons"] or "Weapons",
					priority = 86,
					sortMode = "itemLevel",
					color = { 0.68, 0.82, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "equipment"),
							buildPresetRule(counterState, "equipLoc", "IN", {
								"INVTYPE_WEAPON",
								"INVTYPE_2HWEAPON",
								"INVTYPE_WEAPONMAINHAND",
								"INVTYPE_WEAPONOFFHAND",
								"INVTYPE_HOLDABLE",
								"INVTYPE_RANGED",
								"INVTYPE_RANGEDRIGHT",
							}),
						})
					end,
				},
				{
					name = L["basicPresetCategoryCloak"] or "Cloak",
					priority = 85,
					sortMode = "itemLevel",
					color = { 0.7, 0.78, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "equipment"),
							buildPresetRule(counterState, "equipLoc", "EQUALS", "INVTYPE_CLOAK"),
						})
					end,
				},
				{
					name = L["basicPresetCategoryCloth"] or "Cloth",
					priority = 80,
					sortMode = "itemLevel",
					color = { 0.78, 0.66, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "equipment"),
							buildPresetRule(counterState, "subClassKey", "EQUALS", "4:1"),
							buildPresetRule(counterState, "equipLoc", "NOT_EQUALS", "INVTYPE_CLOAK"),
						})
					end,
				},
				{
					name = L["basicPresetCategoryLeather"] or "Leather",
					priority = 79,
					sortMode = "itemLevel",
					color = { 0.85, 0.68, 0.47 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "equipment"),
							buildPresetRule(counterState, "subClassKey", "EQUALS", "4:2"),
						})
					end,
				},
				{
					name = L["basicPresetCategoryMail"] or "Mail",
					priority = 78,
					sortMode = "itemLevel",
					color = { 0.54, 0.82, 0.8 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "equipment"),
							buildPresetRule(counterState, "subClassKey", "EQUALS", "4:3"),
						})
					end,
				},
				{
					name = L["basicPresetCategoryPlate"] or "Plate",
					priority = 77,
					sortMode = "itemLevel",
					color = { 0.74, 0.79, 0.88 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "equipment"),
							buildPresetRule(counterState, "subClassKey", "EQUALS", "4:4"),
						})
					end,
				},
				{
					name = L["basicPresetCategoryOtherEquipment"] or "Other Equipment",
					priority = 60,
					sortMode = "itemLevel",
					color = { 0.63, 0.8, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "equipment"),
							buildPresetRule(counterState, "classID", "NOT_EQUALS", 19),
						})
					end,
				},
			},
		},
		{
			name = L["basicPresetGroupSupplies"] or "Supplies",
			color = { 0.96, 0.84, 0.33 },
			categories = {
				{
					name = L["basicPresetCategoryHearthstones"] or "Hearthstones",
					priority = 92,
					sortMode = "name",
					color = { 0.95, 0.9, 0.44 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "isHearthstone", "EQUALS", true),
						})
					end,
				},
				{
					name = L["basicPresetCategoryTeleporting"] or "Teleporting",
					priority = 91,
					sortMode = "quality",
					color = { 0.58, 0.86, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "isTeleportItem", "EQUALS", true),
						})
					end,
				},
				{
					name = L["basicPresetCategoryKeystones"] or "Keystones",
					priority = 90,
					sortMode = "keystoneLevel",
					color = { 0.82, 0.82, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "isKeystone", "EQUALS", true),
						})
					end,
				},
				{
					name = L["basicPresetCategoryTransmogSets"] or "Transmog Sets",
					priority = 83,
					sortMode = "name",
					color = { 0.86, 0.62, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "isTransmogSet", "EQUALS", true),
						})
					end,
				},
				{
					name = L["basicPresetCategoryPotions"] or "Potions",
					priority = 82,
					sortMode = "count",
					color = { 0.96, 0.58, 0.58 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "consumables"),
							buildPresetRule(counterState, "subClassKey", "IN", {
								"0:1",
								"0:3",
							}),
						})
					end,
				},
				{
					name = L["basicPresetCategoryFoodDrink"] or "Food & Drink",
					priority = 81,
					sortMode = "count",
					color = { 0.96, 0.84, 0.33 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "consumables"),
							buildPresetRule(counterState, "subClassKey", "EQUALS", "0:5"),
						})
					end,
				},
				{
					name = L["basicPresetCategoryConsumables"] or "Consumables",
					priority = 50,
					sortMode = "count",
					color = { 0.96, 0.84, 0.33 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "consumables"),
						})
					end,
				},
			},
		},
		{
			name = L["basicPresetGroupProfessions"] or "Professions",
			color = { 0.42, 0.85, 0.54 },
			categories = {
				{
					name = L["basicPresetCategoryProfessionGear"] or "Profession Gear",
					priority = 45,
					sortMode = "itemLevel",
					color = { 0.5, 0.88, 0.62 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "classID", "EQUALS", 19),
						})
					end,
				},
				{
					name = L["basicPresetCategoryTradeGoods"] or "Trade Goods",
					priority = 40,
					sortMode = "count",
					color = { 0.42, 0.85, 0.54 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "tradegoods"),
						})
					end,
				},
				{
					name = L["basicPresetCategoryRecipes"] or "Recipes",
					priority = 35,
					sortMode = "quality",
					color = { 0.86, 0.66, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "recipes"),
						})
					end,
				},
			},
		},
		{
			name = L["basicPresetGroupSelling"] or "Selling",
			color = { 0.95, 0.74, 0.3 },
			renderAfterBuiltIns = true,
			categories = {
				{
					name = L["basicPresetCategoryJunk"] or "Junk",
					priority = 85,
					sortMode = "sellPrice",
					color = { 0.72, 0.72, 0.72 },
					desaturateItems = true,
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "quality", "EQUALS", 0),
						})
					end,
				},
			},
		},
		{
			name = L["basicPresetGroupSpecial"] or "Special",
			color = { 1, 0.9, 0.44 },
			categories = {
				{
					name = L["basicPresetCategoryMounts"] or "Mounts",
					priority = 34,
					sortMode = "quality",
					color = { 0.72, 0.86, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "subClassKey", "EQUALS", "15:5"),
						})
					end,
				},
				{
					name = L["basicPresetCategoryPets"] or "Pets",
					priority = 33,
					sortMode = "quality",
					color = { 0.95, 0.7, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "OR", {
							buildPresetRule(counterState, "subClassKey", "EQUALS", "15:2"),
							buildPresetRule(counterState, "classID", "EQUALS", 17),
						})
					end,
				},
				{
					name = L["basicPresetCategoryToys"] or "Toys",
					priority = 33,
					sortMode = "quality",
					color = { 0.5, 0.86, 1 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "isToy", "EQUALS", true),
						})
					end,
				},
				{
					name = L["basicPresetCategoryBags"] or "Bags",
					priority = 32,
					sortMode = "quality",
					color = { 0.84, 0.76, 0.42 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "equipLoc", "EQUALS", "INVTYPE_BAG"),
						})
					end,
				},
				{
					name = getHousingClassLabel(),
					priority = 31,
					sortMode = "quality",
					color = { 0.9, 0.82, 0.98 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "classID", "EQUALS", HOUSING_CLASS_ID),
						})
					end,
				},
				{
					name = getItemEnhancementsClassLabel(),
					priority = 30,
					sortMode = "quality",
					color = { 0.98, 0.88, 0.6 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "classID", "EQUALS", ITEM_ENHANCEMENTS_CLASS_ID),
						})
					end,
				},
				{
					name = L["basicPresetCategoryQuest"] or "Quest",
					priority = 29,
					sortMode = "quality",
					color = { 1, 0.9, 0.44 },
					ruleTree = function(counterState)
						return buildPresetRuleGroup(counterState, "AND", {
							buildPresetRule(counterState, "defaultCategory", "EQUALS", "quest"),
						})
					end,
				},
			},
		},
	}

	for groupIndex, presetGroup in ipairs(presetGroups) do
		local group = sanitizeCustomGroup(modeState, {
			name = presetGroup.name,
			color = presetGroup.color,
		}, groupIndex)
		modeState.customGroups[#modeState.customGroups + 1] = group

		for _, presetCategory in ipairs(presetGroup.categories or {}) do
			local category = sanitizeCategory(modeState, {
				name = presetCategory.name,
				priority = presetCategory.priority,
				sortMode = presetCategory.sortMode,
				color = presetCategory.color,
				groupID = group.id,
				itemIDs = {},
				ruleTree = presetCategory.ruleTree(modeState),
			}, #modeState.customCategories + 1, {
				[group.id] = true,
			})
			modeState.customCategories[#modeState.customCategories + 1] = category
		end
	end

	modeState.presetVersionApplied = BASIC_PRESET_VERSION
	return modeState
end

function addon.MarkCategoryModeStateDirty()
	markCustomCategoryStateDirty()
end

function addon.InitializeCategoryModeSettings(isNewDatabase)
	local settings = getSettings()
	local modes = getCategoryModesTable()
	local hasLegacyCategoryData = type(settings.customCategories) == "table"
		or type(settings.customGroups) == "table"
		or type(settings.hiddenBuiltInCategories) == "table"
		or settings.nextCustomCategoryID ~= nil
		or settings.nextCustomGroupID ~= nil
		or settings.nextCustomCategoryNodeID ~= nil
		or settings.nextCustomCategorySortOrder ~= nil

	ensureModeStateDefaults(modes.basic)
	ensureModeStateDefaults(modes.advanced)

	if settings.categoryModesMigrated ~= true then
		if hasLegacyCategoryData then
			local advancedState = resetCategoryModeState(modes.advanced)
			copyModeStateContents({
				customCategories = deepCopyValue(settings.customCategories or {}),
				customGroups = deepCopyValue(settings.customGroups or {}),
				hiddenBuiltInCategories = deepCopyValue(settings.hiddenBuiltInCategories or {}),
				nextCustomCategoryID = tonumber(settings.nextCustomCategoryID) or 0,
				nextCustomGroupID = tonumber(settings.nextCustomGroupID) or 0,
				nextCustomCategoryNodeID = tonumber(settings.nextCustomCategoryNodeID) or 0,
				nextCustomCategorySortOrder = tonumber(settings.nextCustomCategorySortOrder) or 0,
				presetVersionApplied = 0,
			}, advancedState)
			settings.customCategories = nil
			settings.customGroups = nil
			settings.hiddenBuiltInCategories = nil
			settings.nextCustomCategoryID = nil
			settings.nextCustomGroupID = nil
			settings.nextCustomCategoryNodeID = nil
			settings.nextCustomCategorySortOrder = nil
			hideStandardBuiltInCategories(modes.basic.hiddenBuiltInCategories)
			settings.activeCategoryMode = "advanced"
			settings.modeOnboardingComplete = true
		elseif isNewDatabase then
			hideStandardBuiltInCategories(modes.basic.hiddenBuiltInCategories)
			hideStandardBuiltInCategories(modes.advanced.hiddenBuiltInCategories)
			settings.activeCategoryMode = "basic"
			settings.modeOnboardingComplete = false
		else
			hideStandardBuiltInCategories(modes.basic.hiddenBuiltInCategories)
			hideStandardBuiltInCategories(modes.advanced.hiddenBuiltInCategories)
			settings.activeCategoryMode = "advanced"
			settings.modeOnboardingComplete = true
		end
		settings.categoryModesMigrated = true
	elseif isNewDatabase then
		hideStandardBuiltInCategories(modes.basic.hiddenBuiltInCategories)
		hideStandardBuiltInCategories(modes.advanced.hiddenBuiltInCategories)
	end

	settings.activeCategoryMode = normalizeCategoryMode(settings.activeCategoryMode)
	settings.modeOnboardingComplete = settings.modeOnboardingComplete == true
	if settings.activeCategoryMode == "basic" and (tonumber(modes.basic.presetVersionApplied) < BASIC_PRESET_VERSION or #modes.basic.customCategories == 0) then
		seedBasicPresetIntoModeState(modes.basic)
	end
	markCustomCategoryStateDirty()
	return modes
end

function addon.ShouldShowCategoryModeOnboarding()
	return addon.IsCategoryModeOnboardingComplete and not addon.IsCategoryModeOnboardingComplete()
end

function addon.EnsureBasicPresetSeeded()
	local modeState = getCategoryModeState("basic")
	if tonumber(modeState.presetVersionApplied) >= BASIC_PRESET_VERSION and #modeState.customCategories > 0 then
		return false
	end

	seedBasicPresetIntoModeState(modeState)
	markCustomCategoryStateDirty()
	return true
end

function addon.HasCategoryModeContent(mode)
	local modeState = getCategoryModeState(mode)
	return #(modeState.customCategories or {}) > 0 or #(modeState.customGroups or {}) > 0
end

function addon.CopyBasicCategoriesToAdvanced()
	local basicState = getCategoryModeState("basic")
	local advancedState = getCategoryModeState("advanced")
	if #basicState.customCategories == 0 then
		addon.EnsureBasicPresetSeeded()
		basicState = getCategoryModeState("basic")
	end

	copyModeStateContents(basicState, advancedState)
	markCustomCategoryStateDirty()
	return true
end

local function ensureCustomCategoryState()
	local modeState, modeID = getCategoryModeState()
	local categories = getCustomCategoriesTable(modeID)
	local groups = getCustomCategoryGroupsTable(modeID)
	local hiddenBuiltInCategories = getHiddenBuiltInCategories(modeID)
	local stateChanged = customCategoryStateModeID ~= modeID
		or customCategoryStateModeState ~= modeState
		or customCategoryStateCategories ~= categories
		or customCategoryStateGroups ~= groups
		or customCategoryStateHiddenBuiltIn ~= hiddenBuiltInCategories

	if not customCategoryStateDirty and not stateChanged then
		return categories
	end

	if stateChanged and not customCategoryStateDirty then
		customCategoryStateRevision = customCategoryStateRevision + 1
	end

	for categoryID in pairs(hiddenBuiltInCategories) do
		local definition = BUILTIN_CATEGORY_DEFINITIONS[categoryID]
		if not definition or not definition.canHide then
			hiddenBuiltInCategories[categoryID] = nil
		end
	end

	for index, group in ipairs(groups) do
		groups[index] = sanitizeCustomGroup(modeState, group, index)
	end
	migrateLegacyCategoryGroups(modeState, groups, categories)
	table.sort(groups, compareEntriesBySortOrder)

	local validGroupLookup = {}
	for _, group in ipairs(groups) do
		validGroupLookup[group.id] = true
	end

	for index, category in ipairs(categories) do
		categories[index] = sanitizeCategory(modeState, category, index, validGroupLookup)
	end

	table.sort(categories, compareCategoriesByPriority)

	customCategoryStateDirty = false
	customCategoryStateModeID = modeID
	customCategoryStateModeState = modeState
	customCategoryStateCategories = categories
	customCategoryStateGroups = groups
	customCategoryStateHiddenBuiltIn = hiddenBuiltInCategories
	customCategoryCompiledState = buildCompiledCustomCategoryState(categories, groups)
	cachedCategoryRuleContextUsage = customCategoryCompiledState.contextUsage
	cachedCategorySectionDefinitions = customCategoryCompiledState.sectionDefinitions

	return categories
end

local function findGroupByID(groupID)
	ensureCustomCategoryState()
	for _, group in ipairs(customCategoryStateGroups or getCustomCategoryGroupsTable()) do
		if group.id == groupID then
			return group
		end
	end
end

local function findCategoryByID(categoryID)
	for _, category in ipairs(ensureCustomCategoryState()) do
		if category.id == categoryID then
			return category
		end
	end
end

local function findNodeRecursive(node, nodeID, parentNode)
	if not node then
		return nil
	end

	if node.id == nodeID then
		return node, parentNode
	end

	if node.nodeType == "group" then
		for _, child in ipairs(node.children or {}) do
			local foundNode, foundParent = findNodeRecursive(child, nodeID, node)
			if foundNode then
				return foundNode, foundParent
			end
		end
	end

	return nil
end

local function parseItemID(input)
	if type(input) == "number" then
		input = math.floor(input)
		return input > 0 and input or nil
	end

	if type(input) ~= "string" then
		return nil
	end

	local value = trimText(input)
	if value == "" then
		return nil
	end

	local itemID = value:match("|Hitem:(%d+)")
		or value:match("item:(%d+)")
		or value:match("|Hkeystone:(%d+)")
		or value:match("keystone:(%d+)")
		or value:match("^(%d+)$")
	itemID = tonumber(itemID)
	if itemID and itemID > 0 then
		return itemID
	end

	return nil
end

local function categoryMatchesItemID(category, itemID)
	itemID = tonumber(itemID)
	if not itemID or itemID <= 0 then
		return false
	end

	for _, assignedItemID in ipairs(category.itemIDs or {}) do
		if assignedItemID == itemID then
			return true
		end
	end

	return false
end

local function compareRuleValue(actualValue, operatorID, expectedValue)
	if operatorID == "IN" then
		for _, candidate in ipairs(type(expectedValue) == "table" and expectedValue or {}) do
			if actualValue == candidate then
				return true
			end
		end
		return false
	elseif operatorID == "NOT_EQUALS" then
		return actualValue ~= expectedValue
	elseif operatorID == "LESS_THAN" then
		return tonumber(actualValue) and tonumber(expectedValue) and tonumber(actualValue) < tonumber(expectedValue) or false
	elseif operatorID == "LESS_OR_EQUAL" then
		return tonumber(actualValue) and tonumber(expectedValue) and tonumber(actualValue) <= tonumber(expectedValue) or false
	elseif operatorID == "GREATER_THAN" then
		return tonumber(actualValue) and tonumber(expectedValue) and tonumber(actualValue) > tonumber(expectedValue) or false
	elseif operatorID == "GREATER_OR_EQUAL" then
		return tonumber(actualValue) and tonumber(expectedValue) and tonumber(actualValue) >= tonumber(expectedValue) or false
	end

	return actualValue == expectedValue
end

local function evaluateRuleNode(node, itemContext)
	if not node or not itemContext then
		return false
	end

	if node.nodeType == "group" then
		local children = node.children or {}
		if #children == 0 then
			return false
		end

		if node.operator == "AND" then
			for _, child in ipairs(children) do
				if not evaluateRuleNode(child, itemContext) then
					return false
				end
			end
			return true
		end

		for _, child in ipairs(children) do
			if evaluateRuleNode(child, itemContext) then
				return true
			end
		end

		return false
	end

	local definition = getFieldDefinition(node.field)
	local actualValue = itemContext[definition.contextKey]
	if actualValue == nil then
		return false
	end

	local expectedValue = node.value
	if definition.comparisonContextKey and definition.comparisonValueMode == "equippedAverageOffset" then
		local comparisonBase = tonumber(itemContext[definition.comparisonContextKey])
		local offsetValue = tonumber(node.value)
		if comparisonBase and offsetValue then
			expectedValue = node.operator == "AVERAGE_PLUS" and comparisonBase + offsetValue or comparisonBase - offsetValue
		else
			expectedValue = nil
		end
		if expectedValue == nil then
			return false
		end
		return tonumber(actualValue) and tonumber(actualValue) >= expectedValue or false
	end

	return compareRuleValue(actualValue, node.operator, expectedValue)
end

local function collectRuleContextUsage(node, usage)
	if not node then
		return
	end

	if node.nodeType == "group" then
		for _, child in ipairs(node.children or {}) do
			collectRuleContextUsage(child, usage)
		end
		return
	end

	local definition = getFieldDefinition(node.field)
	if definition.contextKey then
		usage[definition.contextKey] = true
	end
	if definition.comparisonContextKey then
		usage[definition.comparisonContextKey] = true
	end
end

local function getValueLabelForNode(ruleNode)
	if not ruleNode then
		return ""
	end

	local definition = getFieldDefinition(ruleNode.field)
	if definition.valueType == "number" then
		if ruleNode.field == "sellPrice" and type(GetMoneyString) == "function" then
			return GetMoneyString(tonumber(ruleNode.value) or 0, true)
		end
		return tostring(ruleNode.value or 0)
	end

	local options, lookup = getFieldOptions(ruleNode.field)
	if ruleNode.operator == "IN" then
		local values = type(ruleNode.value) == "table" and ruleNode.value or {}
		if #values == 0 then
			return ""
		end

		local firstOption = lookup[tostring(values[1])]
		local firstLabel = firstOption and firstOption.label or tostring(values[1])
		if #values == 1 then
			return firstLabel
		end
		return string.format("%s +%d", firstLabel, #values - 1)
	end

	local option = lookup[tostring(ruleNode.value)]
	return option and option.label or tostring(ruleNode.value or "")
end

function addon.GetCustomCategories()
	return ensureCustomCategoryState()
end

function addon.GetCustomCategoryGroups()
	ensureCustomCategoryState()
	return customCategoryStateGroups or getCustomCategoryGroupsTable()
end

function addon.HasCustomCategories()
	return #ensureCustomCategoryState() > 0
end

function addon.GetCategoryRulesRevision()
	ensureCustomCategoryState()
	return customCategoryStateRevision
end

function addon.GetBuiltInCategoryOrder()
	return BUILTIN_CATEGORY_ORDER
end

function addon.GetBuiltInCategoryDefinitions()
	return BUILTIN_CATEGORY_DEFINITIONS
end

function addon.GetBuiltInCategoryStates()
	local states = {}
	for _, categoryID in ipairs(BUILTIN_CATEGORY_ORDER) do
		local definition = BUILTIN_CATEGORY_DEFINITIONS[categoryID]
		states[#states + 1] = {
			id = categoryID,
			label = L[definition.labelKey] or definition.labelKey or categoryID,
			color = definition.color,
			canHide = definition.canHide ~= false,
			visible = addon.IsBuiltInCategoryVisible(categoryID),
		}
	end
	return states
end

function addon.IsBuiltInCategoryVisible(categoryID)
	local definition = BUILTIN_CATEGORY_DEFINITIONS[categoryID]
	if not definition then
		return false
	end
	if not definition.canHide then
		return true
	end
	return not getHiddenBuiltInCategories()[categoryID]
end

function addon.SetBuiltInCategoryVisible(categoryID, isVisible)
	local definition = BUILTIN_CATEGORY_DEFINITIONS[categoryID]
	if not definition or not definition.canHide then
		return false
	end

	local hiddenBuiltInCategories = getHiddenBuiltInCategories()
	if isVisible then
		hiddenBuiltInCategories[categoryID] = nil
	else
		hiddenBuiltInCategories[categoryID] = true
	end

	markCustomCategoryStateDirty()
	return true
end

function addon.NormalizeCategorySectionID(sectionID)
	local definition = BUILTIN_CATEGORY_DEFINITIONS[sectionID]
	if definition and not addon.IsBuiltInCategoryVisible(sectionID) then
		return "misc"
	end
	return sectionID
end

function addon.GetCategoryRuleFieldGroups()
	local groups = {}

	for _, groupID in ipairs(FIELD_GROUP_ORDER) do
		local group = {
			id = groupID,
			label = L[FIELD_GROUP_LABEL_KEYS[groupID]] or FIELD_GROUP_LABEL_KEYS[groupID] or groupID,
			fields = {},
		}

		for fieldID, definition in pairs(FIELD_DEFINITIONS) do
			if definition.groupID == groupID then
				group.fields[#group.fields + 1] = {
					id = fieldID,
					label = L[definition.labelKey] or definition.labelKey or fieldID,
				}
			end
		end

		table.sort(group.fields, function(a, b)
			return (a.label or "") < (b.label or "")
		end)

		if #group.fields > 0 then
			groups[#groups + 1] = group
		end
	end

	return groups
end

function addon.GetCategoryRuleOperators(ruleNode)
	local definition = getFieldDefinition(getNodeFieldID(ruleNode))
	local operators = {}

	for _, operatorID in ipairs(definition.operators or {}) do
		local operatorInfo = getOperatorDefinition(operatorID)
		operators[#operators + 1] = {
			id = operatorID,
			label = operatorInfo.label or (operatorInfo.labelKey and (L[operatorInfo.labelKey] or operatorInfo.labelKey)) or operatorID,
		}
	end

	return operators
end

function addon.GetCategoryRuleValueType(ruleNode)
	local definition = getFieldDefinition(getNodeFieldID(ruleNode))
	return definition.valueType == "number" and "number" or "enum"
end

function addon.GetCategoryRuleValueOptions(ruleNode)
	local fieldID = getNodeFieldID(ruleNode)
	local options = getFieldOptions(fieldID)
	local result = {}

	for index, option in ipairs(options or {}) do
		result[index] = {
			value = option.value,
			label = option.label,
			groupLabel = option.groupLabel,
		}
	end

	return result
end

function addon.GetCategoryRuleFieldLabel(ruleNode)
	local definition = getFieldDefinition(getNodeFieldID(ruleNode))
	return L[definition.labelKey] or definition.labelKey or tostring(getNodeFieldID(ruleNode) or "")
end

function addon.GetCategoryRuleOperatorLabel(ruleNode, operatorID)
	if type(ruleNode) == "table" and operatorID == nil then
		operatorID = ruleNode.operator
	end

	local operatorInfo = getOperatorDefinition(operatorID)
	if not operatorInfo then
		return tostring(operatorID or "")
	end

	return operatorInfo.label or (operatorInfo.labelKey and (L[operatorInfo.labelKey] or operatorInfo.labelKey)) or operatorInfo.id
end

function addon.GetCategoryRuleValueLabel(ruleNode)
	return getValueLabelForNode(ruleNode)
end

function addon.GetCategoryRuleLabel(ruleNode)
	if not ruleNode then
		return ""
	end

	return string.format(
		"%s %s %s",
		addon.GetCategoryRuleFieldLabel(ruleNode),
		addon.GetCategoryRuleOperatorLabel(ruleNode),
		getValueLabelForNode(ruleNode)
	)
end

function addon.GetCategoryGroupLabel(operator)
	if operator == "AND" then
		return L["settingsCategoryGroupMatchAll"] or "Match all"
	end
	return L["settingsCategoryGroupMatchAny"] or "Match any"
end

function addon.GetCategoryRuleContextUsage()
	ensureCustomCategoryState()
	if customCategoryCompiledState then
		cachedCategoryRuleContextUsage = customCategoryCompiledState.contextUsage
	end

	return cachedCategoryRuleContextUsage
end

function addon.GetCategorySectionDefinitions()
	ensureCustomCategoryState()
	if customCategoryCompiledState then
		cachedCategorySectionDefinitions = customCategoryCompiledState.sectionDefinitions
	end

	return cachedCategorySectionDefinitions
end

function addon.IsCategorySectionHidden(sectionID)
	ensureCustomCategoryState()
	return customCategoryCompiledState
		and customCategoryCompiledState.hiddenSectionIDs
		and customCategoryCompiledState.hiddenSectionIDs[sectionID] == true
		or false
end

function addon.GetCategorySortModeOptions()
	local options = {}
	for _, definition in ipairs(CATEGORY_SORT_MODE_DEFINITIONS) do
		options[#options + 1] = {
			value = definition.id,
			label = L[definition.labelKey] or definition.fallback or definition.id,
		}
	end

	return options
end

function addon.NormalizeUpgradeTrackKey(trackID, trackString)
	return getUpgradeTrackCanonicalKey(trackID, trackString)
end

function addon.GetUpgradeTrackOptions()
	return buildUpgradeTrackOptions()
end

function addon.GetUpgradeTrackLabel(trackKey)
	local canonical = getUpgradeTrackCanonicalKey(nil, trackKey)
	if not canonical then
		return nil
	end

	return getUpgradeTrackLabelText(canonical)
end

function addon.GetUpgradeTrackAbbreviation(trackKey)
	local label = addon.GetUpgradeTrackLabel and addon.GetUpgradeTrackLabel(trackKey)
	if not label then
		return nil
	end

	return getFirstUtf8Char(label)
end

function addon.GetUpgradeTrackColor(trackKey)
	local canonical = getUpgradeTrackCanonicalKey(nil, trackKey)
	if not canonical then
		return 1, 1, 1, 1
	end

	local quality = UPGRADE_TRACK_META[canonical] and UPGRADE_TRACK_META[canonical].quality
	if quality ~= nil and C_Item and C_Item.GetItemQualityColor then
		local r, g, b = C_Item.GetItemQualityColor(quality)
		if r and g and b then
			return r, g, b, 1
		end
	end

	return 1, 1, 1, 1
end

function addon.GetItemUpgradeInfoForItem(itemInfo)
	local itemUpgradeInfo = getItemUpgradeInfo(itemInfo)
	local trackKey = getUpgradeTrackCanonicalKey(itemUpgradeInfo and itemUpgradeInfo.trackStringID, itemUpgradeInfo and itemUpgradeInfo.trackString)
	if not trackKey then
		return nil
	end

	return {
		key = trackKey,
		currentLevel = itemUpgradeInfo.currentLevel,
		maxLevel = itemUpgradeInfo.maxLevel,
		maxItemLevel = itemUpgradeInfo.maxItemLevel,
		trackString = trimUpgradeTrackText(itemUpgradeInfo.trackString),
		trackStringID = itemUpgradeInfo.trackStringID,
		label = addon.GetUpgradeTrackLabel and addon.GetUpgradeTrackLabel(trackKey) or nil,
		abbreviation = addon.GetUpgradeTrackAbbreviation and addon.GetUpgradeTrackAbbreviation(trackKey) or nil,
		displayText = buildItemUpgradeDisplayText(itemUpgradeInfo, trackKey),
	}
end

function addon.GetMatchingCustomCategoryID(itemContext)
	ensureCustomCategoryState()
	local compiledState = customCategoryCompiledState
	if not compiledState then
		return nil
	end

	local itemID = itemContext and itemContext.itemID
	if itemID ~= nil then
		local explicitCategoryID = compiledState.itemIDToCategoryID[itemID]
		if explicitCategoryID then
			return explicitCategoryID
		end
	end

	for _, category in ipairs(compiledState.categories or {}) do
		if evaluateCompiledRuleNode(category.ruleTree, itemContext) then
			return category.id
		end
	end

	return nil
end

function addon.CreateCustomCategory(parentGroupID)
	local categories = ensureCustomCategoryState()
	local modeState = customCategoryStateModeState or getCategoryModeState()
	local validGroupLookup = {}
	for _, group in ipairs(addon.GetCustomCategoryGroups and addon.GetCustomCategoryGroups() or {}) do
		validGroupLookup[group.id] = true
	end
	local category = sanitizeCategory(modeState, {
		name = string.format("%s %d", L["settingsCategoryCustomDefaultName"] or "Category", #categories + 1),
		priority = 0,
		color = getDefaultCategoryColor(#categories + 1),
		groupID = validGroupLookup[tostring(parentGroupID or "")] and tostring(parentGroupID) or nil,
		itemIDs = {},
		ruleTree = {
			nodeType = "group",
			operator = ROOT_GROUP_OPERATOR,
			children = {},
		},
	}, #categories + 1, validGroupLookup)

	categories[#categories + 1] = category
	markCustomCategoryStateDirty()
	return category
end

function addon.CreateCustomCategoryGroup()
	ensureCustomCategoryState()
	local groups = customCategoryStateGroups or getCustomCategoryGroupsTable()
	local modeState = customCategoryStateModeState or getCategoryModeState()
	local group = sanitizeCustomGroup(modeState, {
		name = string.format("%s %d", L["settingsCategoryGroupLabel"] or "Group", #groups + 1),
		color = getDefaultCategoryColor(#groups + 1),
	}, #groups + 1)

	groups[#groups + 1] = group
	markCustomCategoryStateDirty()
	return group
end

function addon.RemoveCustomCategory(categoryID)
	local categories = ensureCustomCategoryState()
	for index, category in ipairs(categories) do
		if category.id == categoryID then
			table.remove(categories, index)
			markCustomCategoryStateDirty()
			return true
		end
	end
	return false
end

function addon.SetCustomCategoryName(categoryID, name)
	local category = findCategoryByID(categoryID)
	if not category then
		return false
	end

	name = trimText(name)
	if name == "" then
		return false
	end

	category.name = name
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategoryPriority(categoryID, priority)
	local category = findCategoryByID(categoryID)
	if not category then
		return false
	end

	category.priority = sanitizePriority(priority)
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategorySortOrder(categoryID, sortOrder)
	local category = findCategoryByID(categoryID)
	if not category then
		return false
	end

	sortOrder = math.floor((tonumber(sortOrder) or 0) + 0.5)
	if sortOrder < 0 then
		sortOrder = 0
	elseif sortOrder > 999 then
		sortOrder = 999
	end

	if category.sortOrder == sortOrder then
		return false
	end

	category.sortOrder = sortOrder
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategoryHidden(categoryID, hidden)
	local category = findCategoryByID(categoryID)
	if not category then
		return false
	end

	hidden = hidden == true
	if category.hidden == hidden then
		return false
	end

	category.hidden = hidden
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategoryDesaturateItems(categoryID, enabled)
	local category = findCategoryByID(categoryID)
	if not category then
		return false
	end

	enabled = enabled == true
	if category.desaturateItems == enabled then
		return false
	end

	category.desaturateItems = enabled
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategoryGroupSortOrder(groupID, sortOrder)
	local group = findGroupByID(groupID)
	if not group then
		return false
	end

	sortOrder = math.floor((tonumber(sortOrder) or 0) + 0.5)
	if sortOrder < 0 then
		sortOrder = 0
	elseif sortOrder > 999 then
		sortOrder = 999
	end

	if group.sortOrder == sortOrder then
		return false
	end

	group.sortOrder = sortOrder
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategoryGroupHidden(groupID, hidden)
	local group = findGroupByID(groupID)
	if not group then
		return false
	end

	hidden = hidden == true
	if group.hidden == hidden then
		return false
	end

	group.hidden = hidden
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategoryGroupDesaturateItems(groupID, enabled)
	local group = findGroupByID(groupID)
	if not group then
		return false
	end

	enabled = enabled == true
	if group.desaturateItems == enabled then
		return false
	end

	group.desaturateItems = enabled
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategorySortMode(categoryID, sortMode)
	local category = findCategoryByID(categoryID)
	if not category then
		return false
	end

	sortMode = CATEGORY_SORT_MODE_LOOKUP[tostring(sortMode or "")] and tostring(sortMode) or nil
	if sortMode == "default" then
		sortMode = nil
	end

	category.sortMode = sortMode
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategoryColor(categoryID, color)
	local categories = ensureCustomCategoryState()
	for index, category in ipairs(categories) do
		if category.id == categoryID then
			category.color = sanitizeColor(color, getDefaultCategoryColor(index))
			markCustomCategoryStateDirty()
			return true
		end
	end

	return false
end

function addon.RemoveCustomCategoryGroup(groupID)
	local groups = addon.GetCustomCategoryGroups and addon.GetCustomCategoryGroups() or getCustomCategoryGroupsTable()
	for index, group in ipairs(groups) do
		if group.id == groupID then
			table.remove(groups, index)
			for _, category in ipairs(ensureCustomCategoryState()) do
				if category.groupID == groupID then
					category.groupID = nil
				end
			end
			markCustomCategoryStateDirty()
			return true
		end
	end

	return false
end

function addon.SetCustomCategoryGroupName(groupID, groupName)
	local group = findGroupByID(groupID)
	if not group then
		return false
	end

	groupName = sanitizeGroupName(groupName)
	if not groupName or group.name == groupName then
		return false
	end

	group.name = groupName
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategoryGroupColor(groupID, color)
	local groups = addon.GetCustomCategoryGroups and addon.GetCustomCategoryGroups() or getCustomCategoryGroupsTable()
	for index, group in ipairs(groups) do
		if group.id == groupID then
			group.color = sanitizeColor(color, getDefaultCategoryColor(index))
			markCustomCategoryStateDirty()
			return true
		end
	end

	return false
end

function addon.SetCustomCategoryGroupSpacerBefore(groupID, enabled)
	local group = findGroupByID(groupID)
	if not group then
		return false
	end

	enabled = enabled == true
	if group.spacerBefore == enabled then
		return false
	end

	group.spacerBefore = enabled
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategoryGroupCombineSubcategories(groupID, enabled)
	local group = findGroupByID(groupID)
	if not group then
		return false
	end

	enabled = enabled == true
	if group.combineSubcategories == enabled then
		return false
	end

	group.combineSubcategories = enabled
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategoryParentGroup(categoryID, groupID)
	local category = findCategoryByID(categoryID)
	if not category then
		return false
	end

	groupID = groupID and tostring(groupID) or nil
	if groupID and not findGroupByID(groupID) then
		groupID = nil
	end
	if category.groupID == groupID then
		return false
	end

	category.groupID = groupID
	markCustomCategoryStateDirty()
	return true
end

function addon.AddCustomCategoryItemID(categoryID, itemInput)
	local category = findCategoryByID(categoryID)
	local itemID = parseItemID(itemInput)
	if not category or not itemID then
		return false
	end

	local changed = false
	for _, otherCategory in ipairs(getCustomCategoriesTable() or {}) do
		if otherCategory.id ~= category.id then
			for index = #(otherCategory.itemIDs or {}), 1, -1 do
				if otherCategory.itemIDs[index] == itemID then
					table.remove(otherCategory.itemIDs, index)
					changed = true
				end
			end
		end
	end

	for _, assignedItemID in ipairs(category.itemIDs or {}) do
		if assignedItemID == itemID then
			if changed then
				markCustomCategoryStateDirty()
			end
			return changed
		end
	end

	category.itemIDs[#category.itemIDs + 1] = itemID
	table.sort(category.itemIDs)
	markCustomCategoryStateDirty()
	return true
end

function addon.RemoveCustomCategoryItemID(categoryID, itemID)
	local category = findCategoryByID(categoryID)
	itemID = tonumber(itemID)
	if not category or not itemID then
		return false
	end

	for index, assignedItemID in ipairs(category.itemIDs or {}) do
		if assignedItemID == itemID then
			table.remove(category.itemIDs, index)
			markCustomCategoryStateDirty()
			return true
		end
	end

	return false
end

function addon.AddCustomCategoryRule(categoryID, parentNodeID, fieldID)
	local settings = getSettings()
	local category = findCategoryByID(categoryID)
	if not category then
		return nil
	end

	local parentNode = category.ruleTree
	if parentNodeID and parentNodeID ~= category.ruleTree.id then
		parentNode = findNodeRecursive(category.ruleTree, parentNodeID)
	end

	if not parentNode or parentNode.nodeType ~= "group" then
		return nil
	end

	local ruleNode = sanitizeRuleNode(settings, {
		field = fieldID,
	})
	parentNode.children[#parentNode.children + 1] = ruleNode
	markCustomCategoryStateDirty()
	return ruleNode
end

function addon.AddCustomCategoryGroup(categoryID, parentNodeID, operator)
	local settings = getSettings()
	local category = findCategoryByID(categoryID)
	if not category then
		return nil
	end

	local parentNode = category.ruleTree
	if parentNodeID and parentNodeID ~= category.ruleTree.id then
		parentNode = findNodeRecursive(category.ruleTree, parentNodeID)
	end

	if not parentNode or parentNode.nodeType ~= "group" then
		return nil
	end

	local groupNode = sanitizeGroupNode(settings, {
		operator = operator == "AND" and "AND" or "OR",
		children = {},
	})
	parentNode.children[#parentNode.children + 1] = groupNode
	markCustomCategoryStateDirty()
	return groupNode
end

function addon.SetCustomCategoryGroupOperator(categoryID, nodeID, operator)
	local category = findCategoryByID(categoryID)
	if not category then
		return false
	end

	local node = findNodeRecursive(category.ruleTree, nodeID)
	if not node or node.nodeType ~= "group" then
		return false
	end

	node.operator = operator == "AND" and "AND" or "OR"
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategoryRuleField(categoryID, nodeID, fieldID)
	local category = findCategoryByID(categoryID)
	if not category then
		return false
	end

	local node = findNodeRecursive(category.ruleTree, nodeID)
	if not node or node.nodeType ~= "rule" then
		return false
	end

	node.field = FIELD_DEFINITIONS[fieldID] and fieldID or "defaultCategory"
	node.operator = sanitizeOperator(node.field, nil)
	node.value = sanitizeRuleValue(node.field, node.operator, nil)
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategoryRuleOperator(categoryID, nodeID, operator)
	local category = findCategoryByID(categoryID)
	if not category then
		return false
	end

	local node = findNodeRecursive(category.ruleTree, nodeID)
	if not node or node.nodeType ~= "rule" then
		return false
	end

	node.operator = sanitizeOperator(node.field, operator)
	node.value = sanitizeRuleValue(node.field, node.operator, node.value)
	markCustomCategoryStateDirty()
	return true
end

function addon.SetCustomCategoryRuleValue(categoryID, nodeID, value)
	local category = findCategoryByID(categoryID)
	if not category then
		return false
	end

	local node = findNodeRecursive(category.ruleTree, nodeID)
	if not node or node.nodeType ~= "rule" then
		return false
	end

	node.value = sanitizeRuleValue(node.field, node.operator, value)
	markCustomCategoryStateDirty()
	return true
end

function addon.ToggleCustomCategoryRuleListValue(categoryID, nodeID, value)
	local category = findCategoryByID(categoryID)
	if not category then
		return false
	end

	local node = findNodeRecursive(category.ruleTree, nodeID)
	if not node or node.nodeType ~= "rule" or node.operator ~= "IN" then
		return false
	end

	local currentValues = sanitizeEnumValue(node.field, "IN", node.value)
	local normalizedValue = sanitizeEnumValue(node.field, "EQUALS", value)
	local existingIndex

	for index, candidate in ipairs(currentValues) do
		if candidate == normalizedValue then
			existingIndex = index
			break
		end
	end

	if existingIndex then
		if #currentValues == 1 then
			return false
		end
		table.remove(currentValues, existingIndex)
	else
		currentValues[#currentValues + 1] = normalizedValue
	end

	node.value = sanitizeEnumValue(node.field, "IN", currentValues)
	markCustomCategoryStateDirty()
	return true
end

function addon.RemoveCustomCategoryNode(categoryID, nodeID)
	local category = findCategoryByID(categoryID)
	if not category or not category.ruleTree then
		return false
	end

	nodeID = tostring(nodeID or "")
	if nodeID == "" then
		return false
	end

	local function removeChildNode(parentNode)
		if not parentNode or parentNode.nodeType ~= "group" then
			return false
		end

		for index, child in ipairs(parentNode.children or {}) do
			if tostring(child.id or "") == nodeID then
				table.remove(parentNode.children, index)
				return true
			end
		end

		for _, child in ipairs(parentNode.children or {}) do
			if child.nodeType == "group" and removeChildNode(child) then
				return true
			end
		end

		return false
	end

	if removeChildNode(category.ruleTree) then
		markCustomCategoryStateDirty()
		return true
	end

	return false
end
