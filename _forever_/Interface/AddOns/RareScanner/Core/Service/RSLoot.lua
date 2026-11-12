-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local RSLoot = private.NewLib("RareScannerLoot")

-- RareScanner database libraries
local RSConfigDB = private.ImportLib("RareScannerConfigDB")
local RSLootDB = private.ImportLib("RareScannerLootDB")
local RSCollectionsDB = private.ImportLib("RareScannerCollectionsDB")
local RSNpcDB = private.ImportLib("RareScannerNpcDB")
local RSContainerDB = private.ImportLib("RareScannerContainerDB")

-- RareScanner general libraries
local RSLogger = private.ImportLib("RareScannerLogger")
local RSConstants = private.ImportLib("RareScannerConstants")
local RSUtils = private.ImportLib("RareScannerUtils")
local RSTooltipScanners = private.ImportLib("RareScannerTooltipScanners")

---============================================================================
-- Upgrades
---============================================================================

-- Equipment slots where each inventory type can be equipped
RSLoot.EQUIP_SLOTS = {
	INVTYPE_HEAD = { 1 },
	INVTYPE_NECK = { 2 },
	INVTYPE_SHOULDER = { 3 },
	INVTYPE_CHEST = { 5 },
	INVTYPE_ROBE = { 5 },
	INVTYPE_WAIST = { 6 },
	INVTYPE_LEGS = { 7 },
	INVTYPE_FEET = { 8 },
	INVTYPE_WRIST = { 9 },
	INVTYPE_HAND = { 10 },
	INVTYPE_FINGER = { 11, 12 },
	INVTYPE_TRINKET = { 13, 14 },
	INVTYPE_CLOAK = { 15 },
	INVTYPE_WEAPON = { 16, 17 },
	INVTYPE_2HWEAPON = { 16 },
	INVTYPE_WEAPONMAINHAND = { 16 },
	INVTYPE_RANGED = { 16 },
	INVTYPE_RANGEDRIGHT = { 16 },
	INVTYPE_WEAPONOFFHAND = { 17 },
	INVTYPE_SHIELD = { 17 },
	INVTYPE_HOLDABLE = { 17 },
}

-- Cheap check (no tooltips): the item level is higher than the equipped one of the same type
function RSLoot.IsUpgrade(itemID, itemLink)
	local _, _, _, equipLoc, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
	local slots = RSLoot.EQUIP_SLOTS[equipLoc]
	if (not slots) then
		return false
	end

	local itemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
	if (not itemLevel) then
		return false
	end

	local lowestEquippedLevel
	for _, slot in ipairs(slots) do
		local equippedLink = GetInventoryItemLink("player", slot)
		if (equippedLink) then
			-- Only compares with items of the same type (cloth with cloth, swords with swords...)
			local _, _, _, _, _, equippedClassID, equippedSubClassID = C_Item.GetItemInfoInstant(equippedLink)
			if (equippedClassID == classID and equippedSubClassID == subClassID) then
				local equippedLevel = C_Item.GetDetailedItemLevelInfo(equippedLink) or 0
				if (not lowestEquippedLevel or equippedLevel < lowestEquippedLevel) then
					lowestEquippedLevel = equippedLevel
				end
			end
		-- Empty slots count only for items that don't need proficiency (jewelry, cloaks, trinkets)
		elseif (classID == 4 and (subClassID == 0 or equipLoc == "INVTYPE_CLOAK")) then
			return true
		end
	end

	return lowestEquippedLevel ~= nil and itemLevel > lowestEquippedLevel
end

-- Sort criteria of the loot: upgrades first, then quality, then drop chance and finally name
function RSLoot.CompareItems(chances, itemIDA, qualityA, isUpgradeA, itemIDB, qualityB, isUpgradeB)
	if (isUpgradeA ~= isUpgradeB) then
		return isUpgradeA
	end

	qualityA, qualityB = qualityA or 1, qualityB or 1
	if (qualityA ~= qualityB) then
		return qualityA > qualityB
	end

	local chanceA = tonumber(chances[itemIDA]) or RSConstants.LOOT_DEFAULT_DROP_CHANCE
	local chanceB = tonumber(chances[itemIDB]) or RSConstants.LOOT_DEFAULT_DROP_CHANCE
	if (chanceA ~= chanceB) then
		return chanceA > chanceB
	end

	local nameA, nameB = C_Item.GetItemNameByID(itemIDA), C_Item.GetItemNameByID(itemIDB)
	if (nameA and nameB and nameA ~= nameB) then
		return strcmputf8i(nameA, nameB) < 0
	end

	return itemIDA < itemIDB
end

---============================================================================
-- Filters to apply to the loot displayed under the main button and the worldmap
---============================================================================

local function IsToy(itemLink, itemID)
	if (RSLootDB.IsToy(itemID)) then
		return true
	elseif (RSTooltipScanners.ScanLoot(itemLink, TOY)) then
		RSLootDB.SetItemAsToy(itemID)
		return true
	end
end

local function IsFilteredByCategory(itemLink, itemID, itemClassID, itemSubClassID)
	-- If filtered by category
	if (RSConfigDB.GetLootFilterByCategory(itemClassID, itemSubClassID) == false) then
		-- We ignore toys from this filter because they are scattered all around
		if (IsToy(itemLink, itemID)) then
			return false
		end
		
		return true
	end
	
	return false
end

local function IsCollectionFiltered(type, entityID, itemID)
	local items = RSCollectionsDB.GetEntityCollectionsLoot(entityID, type)
	if (RSUtils.Contains(items, itemID)) then
		return false
	end
	
	RSLogger:PrintDebugMessageItemID(itemID, string.format("Item [%s]. Filtrado por estar ya conseguido o estar filtrado en el explorador", itemID))
	return true
end

function RSLoot.IsFiltered(entityID, itemID, itemLink, itemRarity, itemEquipLoc, itemClassID, itemSubClassID)
	-- Quality filter
	if (itemRarity < tonumber(RSConfigDB.GetLootFilterMinQuality())) then
		RSLogger:PrintDebugMessageItemID(itemID, string.format("Item [%s]. Filtrado por su calidad.", itemID))
		return true
	end
	
	-- Individual filter
	if (RSConfigDB.GetItemFiltered(itemID)) then
		RSLogger:PrintDebugMessageItemID(itemID, string.format("Item [%s]. Filtrado individualmente.", itemID))
		return true
	end

	-- Drop chance filter (items without a known drop chance count as the default one)
	local minChance = RSConfigDB.GetLootFilterMinChance()
	local maxChance = RSConfigDB.GetLootFilterMaxChance()
	if (minChance or maxChance) then
		local chances = RSNpcDB.GetNpcLootChance(entityID) or RSContainerDB.GetContainerLootChance(entityID)
		local chance = tonumber(chances and chances[itemID]) or RSConstants.LOOT_DEFAULT_DROP_CHANCE
		if ((minChance and chance < minChance) or (maxChance and chance > maxChance)) then
			RSLogger:PrintDebugMessageItemID(itemID, string.format("Item [%s]. Filtrado por su probabilidad de drop.", itemID))
			return true
		end
	end

	-- Equipable filter
	if (RSConfigDB.IsFilteringLootByNotEquipableItems() and not C_Item.IsEquippableItem(itemID)) then
		RSLogger:PrintDebugMessageItemID(itemID, string.format("Item [%s]. Filtrado por no ser equipable.", itemID))
		return true;
	end

	-- Usable filter (any requirement not met except the level, like class, faction, profession, reputation, armor or weapon type...)
	if (RSConfigDB.IsFilteringLootByNotUsable() and not RSTooltipScanners.GetItemRestrictions(itemID).isUsable) then
		RSLogger:PrintDebugMessageItemID(itemID, string.format("Item [%s]. Filtrado por no poder usarlo.", itemID))
		return true;
	end
	
	-- Filter by explorer results
	if (RSConfigDB.IsFilteringByExplorerResults() and RSUtils.GetTableLength(RSCollectionsDB.GetAllEntitiesCollectionsLoot()) > 0) then
		return IsCollectionFiltered(RSConstants.ITEM_SOURCE.NPC, entityID, itemID) and IsCollectionFiltered(RSConstants.ITEM_SOURCE.CONTAINER, entityID, itemID)
	end

	-- Category filter
	if (not RSConfigDB.IsFilteringByExplorerResults() and IsFilteredByCategory(itemLink, itemID, itemClassID, itemSubClassID)) then
		RSLogger:PrintDebugMessageItemID(itemID, string.format("Item [%s]. Filtrado por su categoria.", itemID))
		return true
	end
	
	return false
end
