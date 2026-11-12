local parentAddonName = "EnhanceQoL"
local _, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local consumables = addon.ForeverConsumables
local health = addon.Health
local healthstoneIDs = {}
health.healthList = {}
health.filteredHealth = {}
health._wrapped = {}
health.constants = { healthstoneItemID = 5512 }

for _, entry in ipairs(consumables.items) do
	if entry.category == "healthstone" or entry.category == "healing_potion" or entry.category == "healing_and_mana_potion" then
		local itemType = entry.category == "healthstone" and "stone" or "potion"
		health.healthList[#health.healthList + 1] = {
			id = entry.id,
			key = "ForeverItem" .. entry.id .. "Item",
			requiredLevel = entry.requiredLevel,
			type = itemType,
			heal = entry.health or 0,
			entry = entry,
		}
		if itemType == "stone" then healthstoneIDs[entry.id] = true end
	end
end

-- Reviewed zone-only recovery stays separate from the unrestricted catalogue.
-- Spell 1259231 requires area 8845; its nominal base healing is 60.
health.healthList[#health.healthList + 1] = {
	id = 255663,
	key = "ForeverItem255663Item",
	requiredLevel = 0,
	type = "potion",
	heal = 60,
	requiredAreaID = 8845,
	entry = { id = 255663, requiredLevel = 0, health = 60 },
}

local function isBetter(candidate, current)
	if not current then return true end
	if candidate.heal ~= current.heal then return candidate.heal > current.heal end
	if candidate.requiredLevel ~= current.requiredLevel then return candidate.requiredLevel > current.requiredLevel end
	return candidate.id < current.id
end

function health.functions.updateAllowedHealth()
	if InCombatLockdown and InCombatLockdown() then return end
	local filtered = {}
	local bestStone, bestPotion
	for _, source in ipairs(health.healthList) do
		local entry = source.entry
		local areaName = source.requiredAreaID and C_Map and C_Map.GetAreaInfo(source.requiredAreaID)
		local inRequiredArea = not source.requiredAreaID or (areaName and GetRealZoneText and GetRealZoneText() == areaName)
		if inRequiredArea and consumables.IsEligible(entry) then
			local item = health._wrapped[source.id]
			if not item then
				item = addon.functions.newItem(source.id, nil, false)
				item.getCount = function() return consumables.GetCount(entry) end
				health._wrapped[source.id] = item
			end
			item.requiredLevel = source.requiredLevel or 0
			item.type = source.type
			item.key = source.key
			item.heal = consumables.GetRecovery(entry, "health")
			filtered[#filtered + 1] = item
			if item.getCount() > 0 then
				if consumables.RequestOwnedItemData then consumables.RequestOwnedItemData(entry) end
				if item.type == "stone" and isBetter(item, bestStone) then bestStone = item end
				if item.type == "potion" and isBetter(item, bestPotion) then bestPotion = item end
			end
		end
	end
	table.sort(filtered, isBetter)
	health.filteredHealth = filtered
	health.bestStone = bestStone
	health.bestPotion = bestPotion
	health.bestOther = nil
end

-- Every classic rank can act as a placeholder for the strongest carried stone.
function health.functions.resolveTrackedHealthstoneItem(itemID)
	local numericID = tonumber(itemID)
	if not numericID then return nil end
	if not healthstoneIDs[numericID] then return numericID end
	local stone = consumables.GetBest("healthstone", "health")
	return stone and stone.id or numericID
end
