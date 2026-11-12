local I = _G.EnhanceQoL.Items
local P = I.internal
local flavorRestrictions = {
	tbc = { isAccountBound = true, isWarboundUntilEquip = true, isRelic = true, upgradeTrackKey = true, equipmentSetIDs = true, isEquipmentSet = true, isTransmogSet = true, isToy = true, isKeystone = true, isPvpItem = true },
	forever = { isAccountBound = true, isWarboundUntilEquip = true, isRelic = true, upgradeTrackKey = true, expansionID = true, isKeystone = true, recommendedForSpec = true },
}
local bagObservations = { defaultCategory = true, subClassKey = true, professionGroupKey = true, recommendedForSpec = true, recommendedForClass = true, isUpgrade = true, upgradeTrackKey = true, canVendor = true, canAuctionHouseSell = true, isEquipmentSet = true, equipmentSetIDs = true, isTransmogSet = true, isPvpItem = true, isTeleportItem = true, isHearthstone = true, isQuestItem = true, questID = true }
local scalarOperators = {
	boolean = { "=", "!=", "exists" },
	number = { "=", "!=", "<", "<=", ">", ">=", "in", "between", "exists" },
	string = { "=", "!=", "contains", "matches", "in", "exists" },
	set = { "has", "contains", "exists" },
}
local function define(name, kind, scope, source, aliases, group)
	local field = { name = name, type = kind, scope = scope, source = source, aliases = aliases or {},
		category = group or "item", labelKey = "ItemsField" .. name:gsub("^%l", string.upper), operators = scalarOperators[kind] }
	I.fields[name] = field
	I.aliases[name:lower()] = name
	for _, alias in ipairs(field.aliases) do I.aliases[alias:lower()] = name end
	return field
end
local base = {
	{ "name", "string", { "itemName" } }, { "link", "string", { "itemLink" } },
	{ "quality", "number" }, { "minLevel", "number", { "itemMinLevel", "requiredLevel" } },
	{ "itemType", "string" }, { "itemSubtype", "string", { "itemSubType" } },
	{ "maxStack", "number", { "itemStackCount" } }, { "equipSlot", "string", { "equipLoc" } },
	{ "sellPrice", "number" }, { "classID", "number", { "class" } }, { "subclassID", "number", { "subClassID" } },
	{ "bindType", "number" }, { "expansionID", "number" }, { "setID", "number" },
	{ "isReagent", "boolean", { "isCraftingReagent", "reagent" } },
}
for _, entry in ipairs(base) do define(entry[1], entry[2], "item", "base", entry[3]) end
define("baseItemLevel", "number", "item", "base").hidden = true
define("itemDescription", "string", "item", "base").hidden = true
for name, statKey in pairs({ strength = "ITEM_MOD_STRENGTH_SHORT", agility = "ITEM_MOD_AGILITY_SHORT", intellect = "ITEM_MOD_INTELLECT_SHORT", stamina = "ITEM_MOD_STAMINA_SHORT", spirit = "ITEM_MOD_SPIRIT_SHORT", armor = "RESISTANCE0_NAME" }) do
	local field = define(name, "number", "variant", "stats", nil, "stats"); field.statKey = statKey
	field.operators = { "present", "=", "!=", "<", "<=", ">", ">=", "in", "between", "exists" }
end
define("sockets", "number", "variant", "stats", nil, "stats")
define("isSocketed", "boolean", "variant", "stats", { "socketed" }, "stats")
define("itemID", "number", "item", "snapshot", { "id" })
define("icon", "number", "item", "base", { "itemTexture" })
define("itemLevel", "number", "variant", "itemLevel", { "level", "ilvl" })
define("count", "number", "instance", "snapshot", { "stackCount" })
define("isBound", "boolean", "instance", "snapshot", { "bound" }, "binding")
define("isLocked", "boolean", "instance", "snapshot", { "locked" })
define("hasLoot", "boolean", "instance", "snapshot")
local derived = {
	isEquipment = { "equipSlot", { "gear", "equipment" } }, isConsumable = { "classID", { "consumable" } },
	isRecipe = { "classID", { "recipe" } }, isQuest = { "classID", { "quest" } },
	isJunkQuality = { "quality", { "junk" } }, isStackable = { "maxStack", { "stackable" } },
	isBoE = { "bindType", { "boe" } }, isBoP = { "bindType", { "bop" } }, isBoU = { "bindType", { "bou" } },
	isPotion = { "classID", { "potion" } }, isElixir = { "classID", { "elixir" } }, isFlask = { "classID", { "flask" } },
	isFoodAndDrink = { "classID", { "foodAndDrink" } }, isBandage = { "classID", { "bandage" } }, isPet = { "classID", { "pet" } },
}
for name, data in pairs(derived) do
	local field = define(name, "boolean", "item", "derived", data[2], "type")
	field.dependencies = { data[1] }
	if name == "isPotion" or name == "isElixir" or name == "isFlask" or name == "isFoodAndDrink" or name == "isBandage" or name == "isPet" then field.dependencies[2] = "subclassID" end
end
local native = {
	isAccountBound = { "IsItemBindToAccount", { "boa", "warbound" } },
	isWarboundUntilEquip = { "IsItemBindToAccountUntilEquip", { "wue" } },
	isKeystone = { "IsItemKeystoneByID", { "keystone" } },
	isCosmetic = { "IsCosmeticItem", { "cosmetic" } }, isRelic = { "IsRelicItem", { "relic" } },
	isUsable = { "IsUsableItem", { "usable" } },
}
for name, data in pairs(native) do
	local field = define(name, "boolean", name == "isUsable" and "character" or "variant", "native", data[2])
	field.api = data[1]
end
define("isToy", "boolean", "item", "toy", { "toy" }, "collection")
define("isMount", "boolean", "item", "mount", { "mount" }, "collection")
define("isCollected", "boolean", "account", "collection", { "collected" }, "collection")
-- These facts are policies/observations owned by the consumer, not guessed by the service.
local observed = {
	defaultCategory = "string", subClassKey = "string", professionGroupKey = "string",
	recommendedForSpec = "boolean", recommendedForClass = "boolean", isUpgrade = "boolean", upgradeTrackKey = "string",
	canVendor = "boolean", canAuctionHouseSell = "boolean", isEquipmentSet = "boolean", equipmentSetIDs = "set",
	isTransmogSet = "boolean", isPvpItem = "boolean", isTeleportItem = "boolean", isHearthstone = "boolean",
	isQuestItem = "boolean", questID = "number", isFood = "boolean", isDrink = "boolean", isOpenable = "boolean",
	isReadable = "boolean", isConjured = "boolean", isRefundable = "boolean", isTradeableLoot = "boolean",
	isKnowledge = "boolean", isTierToken = "boolean", isEnsemble = "boolean", isArsenal = "boolean", isHousing = "boolean",
	isCurrentExpansion = "boolean", isActiveSeason = "boolean", isCatalyst = "boolean", isCatalystUpgrade = "boolean",
	isTransmogUpgrade = "boolean", isMyClass = "boolean", isCrafted = "boolean", craftingQuality = "number",
}
local observedAliases = { isUpgrade = { "upgrade" }, isEquipmentSet = { "isInEquipmentSet", "equipmentset" },
	isPvpItem = { "isPvP", "pvp" }, isFood = { "food" }, isDrink = { "drink" } }
for name, kind in pairs(observed) do
	local field = define(name, kind, name == "equipmentSetIDs" and "instance" or "character", "observation", observedAliases[name], "context")
	field.consumer = bagObservations[name] and "bags" or nil
end
-- Class/subclass identity is native item metadata, also usable outside Bags.
I.fields.subClassKey.source = "derived"
I.fields.subClassKey.scope = "item"
I.fields.subClassKey.dependencies = { "classID", "subclassID" }
define("equippedAverage", "number", "character", "reference", { "equippedAverageItemLevel" }, "context")
define("player.level", "number", "character", "reference", nil, "context")
I.fields["player.level"].labelKey = "ItemsFieldPlayerLevel"
I.fields.equipmentSetIDs.elementType = "number|string"
I.fields.quality.valueOptions = {}
for index, name in ipairs({ "poor", "common", "uncommon", "rare", "epic", "legendary", "artifact", "heirloom" }) do
	I.fields.quality.valueOptions[#I.fields.quality.valueOptions + 1] = {
		value = index - 1, token = name, label = _G["ITEM_QUALITY" .. (index - 1) .. "_DESC"] or name,
	}
end
function I.GetField(name, context)
	if not P.Safe(name) or type(name) ~= "string" then return nil end
	local canonical = I.aliases[name:lower()]
	if not canonical then return nil end
	return P.Describe and P.Describe(I.fields[canonical], context) or P.Copy(I.fields[canonical])
end
function P.Canonical(name)
	return P.Safe(name) and type(name) == "string" and I.aliases[name:lower()] or nil
end
function P.Capability(field, context)
	context = type(context) == "table" and context or {}
	local observedValues = context.observations or {}
	if P.Safe(observedValues[field.name]) and observedValues[field.name] ~= nil then return true, "observation" end
	for _, alias in ipairs(field.aliases) do if P.Safe(observedValues[alias]) and observedValues[alias] ~= nil then return true, "observation" end end
	if context.capabilities and context.capabilities[field.name] ~= nil then
		local cap = context.capabilities[field.name]
		return cap == true or (type(cap) == "table" and cap.supported == true), "consumer"
	end
	local variables = _G.EnhanceQoL.variables or {}
	local flavor = context.flavor or (variables.isTBC and "tbc" or variables.isForever and "forever" or "retail")
	if flavorRestrictions[flavor] and flavorRestrictions[flavor][field.name] then return false, "flavor" end
	if field.source == "observation" then return field.consumer ~= nil and context.consumer == field.consumer, "observation" end
	if field.source == "snapshot" then return true, "snapshot" end
	if field.source == "reference" then return true, "context" end
	if field.source == "stats" then return type(P.Native("GetItemStats")) == "function", "itemData" end
	if field.source == "base" or field.source == "derived" then return type(P.Native("GetItemInfo")) == "function", "itemData" end
	if field.source == "itemLevel" then return type(P.Native("GetDetailedItemLevelInfo")) == "function" or type(P.Native("GetItemInfo")) == "function", "itemData" end
	if field.source == "native" then return type(P.Native(field.api)) == "function", "native" end
	if field.source == "toy" then return _G.C_ToyBox and type(_G.C_ToyBox.GetToyInfo) == "function" or false, "collection" end
	if field.source == "mount" then return _G.C_MountJournal and type(_G.C_MountJournal.GetMountFromItem) == "function" or false, "collection" end
	if field.source == "collection" then return _G.C_ToyBox ~= nil or _G.C_MountJournal ~= nil or _G.C_PetJournal ~= nil or _G.C_TransmogCollection ~= nil, "collection" end
	if P.ExtraCapability then return P.ExtraCapability(field) end
	return false, "unsupported"
end
function I.ListFields(context)
	local out = {}
	for _, field in pairs(I.fields) do
		local entry = P.Describe and P.Describe(field, context) or P.Copy(field)
		if not P.Describe then entry.supported, entry.reason = P.Capability(field, context) end
		out[#out + 1] = entry
	end
	table.sort(out, function(a, b) return a.name < b.name end)
	return out
end
function I.GetCapabilities(context)
	local out = { fields = {}, flavor = type(context) == "table" and context.flavor or ((_G.EnhanceQoL.variables or {}).isTBC and "tbc" or ((_G.EnhanceQoL.variables or {}).isForever and "forever" or "retail")) }
	for _, field in pairs(I.fields) do
		local supported, reason = P.Capability(field, context)
		out.fields[field.name] = { supported = supported, reason = reason, scope = field.scope }
	end
	return out
end

local bagLabels = {
	classID = "Class", subclassID = "Subclass", subClassKey = "Subclass", bindType = "BindType", equipSlot = "EquipLoc",
	expansionID = "Expansion", minLevel = "RequiredLevel", sellPrice = "SellPrice", defaultCategory = "DefaultCategory",
	professionGroupKey = "ProfessionGroup", recommendedForSpec = "RecommendedForSpec", recommendedForClass = "RecommendedForClass",
	isUpgrade = "UpgradeOnly", upgradeTrackKey = "UpgradeTrack", canVendor = "CanVendor", canAuctionHouseSell = "CanAuctionHouseSell",
	isEquipmentSet = "EquipmentSet", equipmentSetIDs = "SpecificEquipmentSet", isTeleportItem = "TeleportItem", isHearthstone = "Hearthstone",
	isTransmogSet = "TransmogSet", isPvpItem = "PvpItem", isKeystone = "Keystone",
}
local inventoryLabels = { "name", "itemID", "quality", "itemLevel", "count", "isBound", "isBoE", "isBoP", "isBoU", "isAccountBound", "isWarboundUntilEquip", "isPotion", "isRecipe", "isEquipment", "isReagent", "isConsumable", "isQuest", "isStackable", "isToy", "isPet", "isMount", "isCollected", "isFoodAndDrink", "isFlask", "isElixir", "isBandage" }
for _, name in ipairs(inventoryLabels) do I.fields[name].labelKey = "InventoryFilterField" .. name:gsub("^%l", string.upper) end
for name, suffix in pairs(bagLabels) do I.fields[name].labelKey = "settingsRuleField" .. suffix end
I.aliases.subclass = "subClassKey"
I.aliases.slot = "equipSlot"
I.fields.isQuestItem.labelKey = "InventoryFilterFieldIsQuest"
-- Presentation-only fields remain readable, but are not useful filter suggestions.
for _, name in ipairs({ "link", "icon", "itemType", "itemSubtype", "setID", "subclassID" }) do I.fields[name].hidden = true end
I.fields.classID.valueOptions = {}
for id, token in pairs({ [0] = "consumable", [1] = "container", [2] = "weapon", [3] = "gem", [4] = "armor", [5] = "reagent", [7] = "tradegoods", [8] = "enhancement", [9] = "recipe", [11] = "quiver", [12] = "quest", [13] = "key", [15] = "miscellaneous", [16] = "glyph", [17] = "battlepet", [18] = "token", [19] = "profession", [20] = "housing" }) do
	local getClass = (_G.C_Item and _G.C_Item.GetItemClassInfo) or _G.GetItemClassInfo
	I.fields.classID.valueOptions[#I.fields.classID.valueOptions + 1] = { value = id, token = token, label = getClass and getClass(id) or token }
end
table.sort(I.fields.classID.valueOptions, function(a, b) return a.value < b.value end)

for name, expression in pairs({ subClassKey = "subclass", classID = "class", equipSlot = "slot", minLevel = "requiredLevel" }) do
	I.fields[name].expressionName = expression
end
