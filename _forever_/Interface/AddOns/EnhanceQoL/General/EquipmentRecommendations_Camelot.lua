local _, addon = ...

-- Equipment eligibility comes from the character's current proficiencies and
-- requirements, rather than specialization-specific equipment preferences.
function addon.functions.GetEquipmentRecommendationOverride(itemRef, equipLoc)
	if not itemRef or equipLoc == "INVTYPE_TABARD" then return false end
	if not C_Item.IsEquippableItem(itemRef) then return false end
	local itemID, _, _, instantEquipLoc = C_Item.GetItemInfoInstant(itemRef)
	if not itemID or (equipLoc or instantEquipLoc) == "INVTYPE_TABARD" then return false end
	return C_PlayerInfo.CanUseItem(itemID) == true
end

-- Item level alone can favor weaker armor. Any stat loss makes the item a
-- tradeoff rather than an automatic upgrade, regardless of gains elsewhere.
function addon.functions.CanCompareEquipmentUpgrade(itemRef, comparisonSlots)
	if not itemRef then return false, false end
	if not comparisonSlots or #comparisonSlots ~= 1 then return true, true end
	local itemID, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemRef)
	if classID == nil or subClassID == nil then return false, false end
	if classID ~= 4 or not ((subClassID >= 1 and subClassID <= 4) or subClassID == 6) then return true, true end

	local equippedLink = GetInventoryItemLink("player", comparisonSlots[1])
	if not equippedLink then
		local isEmpty = not GetInventoryItemID("player", comparisonSlots[1])
		return isEmpty, isEmpty
	end
	local _, candidateLink = C_Item.GetItemInfo(itemRef)
	if not candidateLink then
		C_Item.RequestLoadItemDataByID(itemID)
		return false, false
	end
	local getStats = C_Item.GetItemStats or GetItemStats
	local candidateStats = getStats and getStats(candidateLink)
	local equippedStats = getStats and getStats(equippedLink)
	if not candidateStats or not equippedStats or not next(candidateStats) or not next(equippedStats) then return false, false end

	for stat, value in pairs(equippedStats) do
		if value > (candidateStats[stat] or 0) then return false, true end
	end
	return true, true
end
