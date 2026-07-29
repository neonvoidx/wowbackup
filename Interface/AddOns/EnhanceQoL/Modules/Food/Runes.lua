local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local tsort = table.sort
local C_Item_RequestLoadItemDataByID = C_Item and C_Item.RequestLoadItemDataByID

addon.Runes = addon.Runes or {}
addon.Runes.functions = addon.Runes.functions or {}
addon.Runes.filteredRunes = addon.Runes.filteredRunes or {}

addon.Runes.items = addon.Runes.items
	or {
		{ key = "VoidTouchedAugmentRune", id = 259085, priority = 1, spellId = 1264426 },
		{ key = "EtherealAugmentRune", id = 243191, priority = 2, spellId = 1234969 },
		{ key = "SoulgorgedAugmentRune", id = 246492, priority = 3, spellId = 1242347 },
		{ key = "CrystallizedAugmentRune", id = 224572, priority = 4, spellId = 453250 },
		{ key = "DreamboundAugmentRune", id = 211495, priority = 5, spellId = 393438 },
		{ key = "DraconicAugmentRune", id = 201325, priority = 6, spellId = 393438 },
		{ key = "VeiledAugmentRune", id = 181468, priority = 7, spellId = 347901 },
	}

local function requestItemNameData()
	if not C_Item_RequestLoadItemDataByID then return end
	local items = addon.Runes.items or {}
	for i = 1, #items do
		local entry = items[i]
		if entry and entry.id then C_Item_RequestLoadItemDataByID(entry.id) end
	end
end

requestItemNameData()

local function rebuildBagItemCountCache()
	if addon.functions and addon.functions.rebuildFoodBagItemCountCache then return addon.functions.rebuildFoodBagItemCountCache() end
	return {}
end

local function getBagItemCount(itemId)
	if addon.functions and addon.functions.getFoodBagItemCount then return addon.functions.getFoodBagItemCount(itemId) end
	local counts = rebuildBagItemCountCache()
	return tonumber(counts[itemId]) or 0
end

function addon.Runes.functions.getAvailableCandidates()
	local items = addon.Runes.items or {}
	local available = addon.Runes.filteredRunes or {}

	for i = #available, 1, -1 do
		available[i] = nil
	end

	for i = 1, #items do
		local entry = items[i]
		local itemId = tonumber(entry and entry.id)
		if itemId and itemId > 0 then
			local count = getBagItemCount(itemId)
			if count > 0 then
				available[#available + 1] = {
					key = entry.key,
					id = itemId,
					count = count,
					priority = tonumber(entry.priority) or 99,
					spellId = tonumber(entry.spellId) or nil,
				}
			end
		end
	end

	tsort(available, function(a, b)
		local aPriority = tonumber(a and a.priority) or 99
		local bPriority = tonumber(b and b.priority) or 99
		if aPriority ~= bPriority then return aPriority < bPriority end

		local aCount = tonumber(a and a.count) or 0
		local bCount = tonumber(b and b.count) or 0
		if aCount ~= bCount then return aCount > bCount end

		return (tonumber(a and a.id) or 0) < (tonumber(b and b.id) or 0)
	end)

	addon.Runes.filteredRunes = available
	return available
end
