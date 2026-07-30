local parentAddonName = "EnhanceQoL"
local addonName, addon = ...
local InCombatLockdown = InCombatLockdown
local GetMacroInfo = GetMacroInfo
local GetNumMacros = GetNumMacros
local CreateMacro = CreateMacro
local EditMacro = EditMacro
local CreateFrame = CreateFrame
local print = print
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Drinks = addon.Drinks or {}
addon.Drinks.functions = addon.Drinks.functions or {}
addon.Drinks.filteredDrinks = addon.Drinks.filteredDrinks or {} -- Used for the filtered List later
addon.LDrinkMacro = addon.LDrinkMacro or {} -- Locales for drink macro

-- Flask macro module scaffolding
addon.Flasks = addon.Flasks or {}
addon.Flasks.functions = addon.Flasks.functions or {}
addon.Flasks.filteredFlasks = addon.Flasks.filteredFlasks or {}

-- Buff food macro module scaffolding
addon.BuffFoods = addon.BuffFoods or {}
addon.BuffFoods.functions = addon.BuffFoods.functions or {}
addon.BuffFoods.filteredBuffFoods = addon.BuffFoods.filteredBuffFoods or {}

-- Augment rune reminder scaffolding
addon.Runes = addon.Runes or {}
addon.Runes.functions = addon.Runes.functions or {}
addon.Runes.filteredRunes = addon.Runes.filteredRunes or {}

-- Weapon buff reminder scaffolding
addon.WeaponBuffs = addon.WeaponBuffs or {}
addon.WeaponBuffs.functions = addon.WeaponBuffs.functions or {}
addon.WeaponBuffs.filteredWeaponBuffs = addon.WeaponBuffs.filteredWeaponBuffs or {}
addon.foodBagItemCountCache = addon.foodBagItemCountCache or {}
addon.foodBagItemCountCacheReady = addon.foodBagItemCountCacheReady == true
addon.foodBagItemCountCacheVersion = tonumber(addon.foodBagItemCountCacheVersion) or 0

-- Health macro module scaffolding
addon.Health = addon.Health or {}
addon.Health.functions = addon.Health.functions or {}
addon.Health.filteredHealth = addon.Health.filteredHealth or {}

local FOOD_SLOT_KEY_MULT = 1000
local foodTrackedItemIDs = {}
local foodTrackedItemIDsReady = false
local foodDirtyBags = {}
local foodSlotCache = {}
local foodBagSlotCounts = {}
local foodForceFullRebuild = addon.foodBagItemCountCacheReady ~= true

-- Shared Recuperate spell info (used by Drink and Health macros)
addon.Recuperate = addon.Recuperate or {
	id = 1231411, -- Recuperate spell id
	name = nil,
	known = false,
}
addon.macroWarnings = addon.macroWarnings or {}

local function wipeMap(target)
	if type(target) ~= "table" then return end
	if wipe then
		wipe(target)
		return
	end
	for key in pairs(target) do
		target[key] = nil
	end
end

local function makeFoodSlotKey(bag, slot)
	return bag * FOOD_SLOT_KEY_MULT + slot
end

local function getMaxBagID()
	return tonumber(NUM_TOTAL_EQUIPPED_BAG_SLOTS) or tonumber(NUM_BAG_SLOTS) or 4
end

local function syncSharedFoodBagItemCountCache(counts, bumpVersion)
	addon.foodBagItemCountCache = counts
	addon.foodBagItemCountCacheReady = true
	if bumpVersion ~= false then addon.foodBagItemCountCacheVersion = (tonumber(addon.foodBagItemCountCacheVersion) or 0) + 1 end
	addon.Flasks.bagItemCountCache = counts
	addon.Flasks.bagItemCountCacheReady = true
	addon.BuffFoods.bagItemCountCache = counts
	addon.BuffFoods.bagItemCountCacheReady = true
	addon.Runes.bagItemCountCache = counts
	addon.Runes.bagItemCountCacheReady = true
	addon.WeaponBuffs.bagItemCountCache = counts
	addon.WeaponBuffs.bagItemCountCacheReady = true
	return counts
end

local function invalidateSharedFoodBagItemCountCache(forceFull)
	addon.foodBagItemCountCacheReady = false
	addon.Flasks.bagItemCountCacheReady = false
	addon.BuffFoods.bagItemCountCacheReady = false
	addon.Runes.bagItemCountCacheReady = false
	addon.WeaponBuffs.bagItemCountCacheReady = false
	if forceFull ~= false then foodForceFullRebuild = true end
end

local function addTrackedFoodEntry(entry)
	if type(entry) ~= "table" or entry.isSpell == true then return end
	local id = tonumber(entry.id)
	if id and id > 0 then foodTrackedItemIDs[id] = true end
end

local function addTrackedFoodList(list)
	if type(list) ~= "table" then return end
	for index = 1, #list do
		addTrackedFoodEntry(list[index])
	end
end

local function addTrackedFoodMapOfLists(map)
	if type(map) ~= "table" then return end
	for _, list in pairs(map) do
		addTrackedFoodList(list)
	end
end

local function rebuildFoodTrackedItemIDs()
	wipeMap(foodTrackedItemIDs)
	addTrackedFoodList(addon.Drinks and addon.Drinks.drinkList)
	addTrackedFoodList(addon.Drinks and addon.Drinks.manaPotions)
	addTrackedFoodMapOfLists(addon.Flasks and addon.Flasks.typeFlasks)
	addTrackedFoodMapOfLists(addon.Flasks and addon.Flasks.fleetingTypeFlasks)
	addTrackedFoodMapOfLists(addon.BuffFoods and addon.BuffFoods.typeFoods)
	addTrackedFoodList(addon.Runes and addon.Runes.items)
	addTrackedFoodList(addon.WeaponBuffs and addon.WeaponBuffs.items)
	addTrackedFoodList(addon.Health and addon.Health.healthList)
	foodTrackedItemIDsReady = true
end

local function ensureFoodTrackedItemIDs()
	if not foodTrackedItemIDsReady then rebuildFoodTrackedItemIDs() end
end

function addon.functions.invalidateFoodTrackedItemIDs()
	foodTrackedItemIDsReady = false
	invalidateSharedFoodBagItemCountCache(true)
end

function addon.functions.invalidateFoodBagItemCountCache(forceFull)
	invalidateSharedFoodBagItemCountCache(forceFull ~= false)
end

function addon.functions.shouldMaintainFoodBagItemCountCache()
	local db = addon.db
	if db and (db.flaskMacroEnabled == true or db.buffFoodMacroEnabled == true) then return true end

	local reminder = addon.ClassBuffReminder
	if not reminder then return false end
	if not reminder.IsEnabled or reminder:IsEnabled() ~= true then return false end
	if reminder.IsFlaskTrackingEnabled and reminder:IsFlaskTrackingEnabled() then return true end
	if reminder.IsFoodTrackingEnabled and reminder:IsFoodTrackingEnabled() then return true end
	if reminder.IsRuneTrackingEnabled and reminder:IsRuneTrackingEnabled() then return true end
	if reminder.IsWeaponBuffTrackingEnabled and reminder:IsWeaponBuffTrackingEnabled() then return true end
	return false
end

function addon.functions.rebuildFoodBagItemCountCache()
	ensureFoodTrackedItemIDs()

	local counts = addon.foodBagItemCountCache
	if type(counts) ~= "table" then
		counts = {}
		addon.foodBagItemCountCache = counts
	else
		wipeMap(counts)
	end

	wipeMap(foodSlotCache)
	wipeMap(foodBagSlotCounts)
	wipeMap(foodDirtyBags)

	local maxBag = getMaxBagID()

	if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemID then
		for bag = 0, maxBag do
			local slotCount = C_Container.GetContainerNumSlots(bag) or 0
			foodBagSlotCounts[bag] = slotCount
			for slot = 1, slotCount do
				local rawItemId = C_Container.GetContainerItemID(bag, slot)
				local itemId = rawItemId and tonumber(rawItemId) or nil
				if itemId and foodTrackedItemIDs[itemId] then
					local stackCount = 1
					if C_Container.GetContainerItemInfo then
						local info = C_Container.GetContainerItemInfo(bag, slot)
						stackCount = tonumber(info and info.stackCount) or 1
					end
					counts[itemId] = (counts[itemId] or 0) + stackCount
					foodSlotCache[makeFoodSlotKey(bag, slot)] = {
						itemID = itemId,
						count = stackCount,
					}
				end
			end
		end
	elseif GetContainerNumSlots and GetContainerItemID and GetContainerItemInfo then
		for bag = 0, maxBag do
			local slotCount = GetContainerNumSlots(bag) or 0
			foodBagSlotCounts[bag] = slotCount
			for slot = 1, slotCount do
				local rawItemId = GetContainerItemID(bag, slot)
				local itemId = rawItemId and tonumber(rawItemId) or nil
				if itemId and foodTrackedItemIDs[itemId] then
					local _, stackCount = GetContainerItemInfo(bag, slot)
					stackCount = tonumber(stackCount) or 1
					counts[itemId] = (counts[itemId] or 0) + stackCount
					foodSlotCache[makeFoodSlotKey(bag, slot)] = {
						itemID = itemId,
						count = stackCount,
					}
				end
			end
		end
	end

	foodForceFullRebuild = false
	return syncSharedFoodBagItemCountCache(counts)
end

local function applyFoodSlotDelta(counts, key, newItemID, newCount)
	local old = foodSlotCache[key]
	local changed = false

	if old and (old.itemID ~= newItemID or old.count ~= newCount) then
		local oldID = old.itemID
		local oldCount = tonumber(old.count) or 0
		counts[oldID] = math.max(0, (counts[oldID] or 0) - oldCount)
		if counts[oldID] == 0 then counts[oldID] = nil end
		foodSlotCache[key] = nil
		changed = true
	end

	if newItemID and newCount > 0 and (not old or old.itemID ~= newItemID or old.count ~= newCount) then
		counts[newItemID] = (counts[newItemID] or 0) + newCount
		foodSlotCache[key] = {
			itemID = newItemID,
			count = newCount,
		}
		changed = true
	end

	return changed
end

local function markFoodBagDirty(bag)
	if type(bag) ~= "number" then return end
	if bag < 0 or bag > getMaxBagID() then return end
	foodDirtyBags[bag] = true
	addon.foodBagItemCountCacheReady = false
end

local function updateFoodBagItemCountCacheDirty()
	if foodForceFullRebuild or type(addon.foodBagItemCountCache) ~= "table" then return addon.functions.rebuildFoodBagItemCountCache() end
	ensureFoodTrackedItemIDs()

	local counts = addon.foodBagItemCountCache
	if not next(foodDirtyBags) then return syncSharedFoodBagItemCountCache(counts, false) end

	local changed = false

	if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemID then
		for bag in pairs(foodDirtyBags) do
			local oldSlotCount = foodBagSlotCounts[bag] or 0
			local slotCount = C_Container.GetContainerNumSlots(bag) or 0
			local maxSlot = math.max(oldSlotCount, slotCount)

			for slot = 1, maxSlot do
				local key = makeFoodSlotKey(bag, slot)
				if slot > slotCount then
					changed = applyFoodSlotDelta(counts, key, nil, 0) or changed
				else
					local rawItemId = C_Container.GetContainerItemID(bag, slot)
					local itemId = rawItemId and tonumber(rawItemId) or nil
					local trackedID = itemId and foodTrackedItemIDs[itemId] and itemId or nil
					local stackCount = 0
					if trackedID then
						local info = C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bag, slot) or nil
						stackCount = tonumber(info and info.stackCount) or 1
					end
					changed = applyFoodSlotDelta(counts, key, trackedID, stackCount) or changed
				end
			end

			foodBagSlotCounts[bag] = slotCount
		end
	elseif GetContainerNumSlots and GetContainerItemID and GetContainerItemInfo then
		for bag in pairs(foodDirtyBags) do
			local oldSlotCount = foodBagSlotCounts[bag] or 0
			local slotCount = GetContainerNumSlots(bag) or 0
			local maxSlot = math.max(oldSlotCount, slotCount)

			for slot = 1, maxSlot do
				local key = makeFoodSlotKey(bag, slot)
				if slot > slotCount then
					changed = applyFoodSlotDelta(counts, key, nil, 0) or changed
				else
					local rawItemId = GetContainerItemID(bag, slot)
					local itemId = rawItemId and tonumber(rawItemId) or nil
					local trackedID = itemId and foodTrackedItemIDs[itemId] and itemId or nil
					local stackCount = 0
					if trackedID then
						local _, count = GetContainerItemInfo(bag, slot)
						stackCount = tonumber(count) or 1
					end
					changed = applyFoodSlotDelta(counts, key, trackedID, stackCount) or changed
				end
			end

			foodBagSlotCounts[bag] = slotCount
		end
	end

	wipeMap(foodDirtyBags)
	return syncSharedFoodBagItemCountCache(counts, changed)
end

function addon.functions.getFoodBagItemCountCache()
	if addon.foodBagItemCountCacheReady == true and type(addon.foodBagItemCountCache) == "table" then return addon.foodBagItemCountCache end
	if not foodForceFullRebuild and type(addon.foodBagItemCountCache) == "table" then return updateFoodBagItemCountCacheDirty() end
	return addon.functions.rebuildFoodBagItemCountCache()
end

function addon.functions.getFoodBagItemCountCacheVersion()
	if addon.foodBagItemCountCacheReady ~= true then addon.functions.getFoodBagItemCountCache() end
	return tonumber(addon.foodBagItemCountCacheVersion) or 0
end

function addon.functions.getFoodBagItemCount(itemId)
	local targetId = tonumber(itemId)
	if not targetId or targetId <= 0 then return 0 end
	ensureFoodTrackedItemIDs()
	if not foodTrackedItemIDs[targetId] then
		foodTrackedItemIDs[targetId] = true
		foodForceFullRebuild = true
		addon.foodBagItemCountCacheReady = false
	end
	local cache = addon.functions.getFoodBagItemCountCache()
	return tonumber(cache[targetId]) or 0
end

local sharedFoodBagItemCountCacheFrame = addon.sharedFoodBagItemCountCacheFrame or CreateFrame("Frame")
addon.sharedFoodBagItemCountCacheFrame = sharedFoodBagItemCountCacheFrame
sharedFoodBagItemCountCacheFrame:RegisterEvent("PLAYER_LOGIN")
sharedFoodBagItemCountCacheFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
sharedFoodBagItemCountCacheFrame:RegisterEvent("BAG_UPDATE")
sharedFoodBagItemCountCacheFrame:RegisterEvent("BAG_UPDATE_DELAYED")
sharedFoodBagItemCountCacheFrame:SetScript("OnEvent", function(_, event, bag)
	if event == "BAG_UPDATE" then
		markFoodBagDirty(bag)
		return
	end

	if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
		foodTrackedItemIDsReady = false
		invalidateSharedFoodBagItemCountCache(true)
		return
	end

	if event == "BAG_UPDATE_DELAYED" then
		if addon.functions.shouldMaintainFoodBagItemCountCache and addon.functions.shouldMaintainFoodBagItemCountCache() then
			updateFoodBagItemCountCacheDirty()
		else
			invalidateSharedFoodBagItemCountCache(false)
		end
	end
end)

function addon.Recuperate.Update()
	local spellInfo = C_Spell.GetSpellInfo(addon.Recuperate.id)
	addon.Recuperate.name = spellInfo and spellInfo.name or nil
	addon.Recuperate.known = addon.Recuperate.name and C_SpellBook.IsSpellInSpellBook(addon.Recuperate.id) or false
end

function addon.functions.newItem(id, name, isSpell)
	local self = {}

	self.id = id
	self.name = name
	self.isSpell = isSpell

	local function setName()
		local itemInfoName = C_Item.GetItemInfo(self.id)
		if itemInfoName ~= nil then self.name = itemInfoName end
	end

	function self.getId()
		if self.isSpell then return C_Spell.GetSpellName(self.id) end
		return "item:" .. self.id
	end

	function self.getName() return self.name end

	function self.getCount()
		if self.isSpell then return 1 end
		if addon.functions and addon.functions.getFoodBagItemCount then return addon.functions.getFoodBagItemCount(self.id) end
		return C_Item.GetItemCount(self.id, false, false)
	end

	return self
end

function addon.functions.WarnMacroLimitReachedOnce(key, message)
	if not key or not message then return end
	if addon.macroWarnings[key] then return end
	addon.macroWarnings[key] = true
	print(message)
end

function addon.functions.EnsureGlobalMacro(name, icon, body, warningKey, warningMessage)
	if not name then return false end
	if GetMacroInfo(name) ~= nil then return true end
	if InCombatLockdown and InCombatLockdown() then return false end

	local globalMacros = 0
	if GetNumMacros then globalMacros = select(1, GetNumMacros()) or 0 end
	local globalLimit = _G.MAX_ACCOUNT_MACROS or 120
	if globalMacros >= globalLimit then
		addon.functions.WarnMacroLimitReachedOnce(warningKey or name, warningMessage)
		return false
	end

	CreateMacro(name, icon or "INV_Misc_QuestionMark")
	if body and GetMacroInfo(name) ~= nil and not (InCombatLockdown and InCombatLockdown()) then EditMacro(name, name, nil, body) end
	return GetMacroInfo(name) ~= nil
end
