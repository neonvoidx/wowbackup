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

-- Shared Recuperate spell info (used by Drink and Health macros)
addon.Recuperate = addon.Recuperate or {
	id = 1231411, -- Recuperate spell id
	name = nil,
	known = false,
}
addon.macroWarnings = addon.macroWarnings or {}

local function syncSharedFoodBagItemCountCache(counts)
	addon.foodBagItemCountCache = counts
	addon.foodBagItemCountCacheReady = true
	addon.foodBagItemCountCacheVersion = (tonumber(addon.foodBagItemCountCacheVersion) or 0) + 1
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

local function invalidateSharedFoodBagItemCountCache()
	addon.foodBagItemCountCacheReady = false
	addon.Flasks.bagItemCountCacheReady = false
	addon.BuffFoods.bagItemCountCacheReady = false
	addon.Runes.bagItemCountCacheReady = false
	addon.WeaponBuffs.bagItemCountCacheReady = false
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
	local counts = {}
	local maxBag = tonumber(NUM_TOTAL_EQUIPPED_BAG_SLOTS) or tonumber(NUM_BAG_SLOTS) or 4

	if C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo then
		for bag = 0, maxBag do
			local slotCount = C_Container.GetContainerNumSlots(bag) or 0
			for slot = 1, slotCount do
				local info = C_Container.GetContainerItemInfo(bag, slot)
				local itemId = info and tonumber(info.itemID) or nil
				if itemId and itemId > 0 then counts[itemId] = (counts[itemId] or 0) + (tonumber(info.stackCount) or 1) end
			end
		end
	elseif GetContainerNumSlots and GetContainerItemID and GetContainerItemInfo then
		for bag = 0, maxBag do
			local slotCount = GetContainerNumSlots(bag) or 0
			for slot = 1, slotCount do
				local itemId = tonumber(GetContainerItemID(bag, slot))
				if itemId and itemId > 0 then
					local _, stackCount = GetContainerItemInfo(bag, slot)
					counts[itemId] = (counts[itemId] or 0) + (tonumber(stackCount) or 1)
				end
			end
		end
	end

	return syncSharedFoodBagItemCountCache(counts)
end

function addon.functions.getFoodBagItemCountCache()
	if addon.foodBagItemCountCacheReady == true and type(addon.foodBagItemCountCache) == "table" then return addon.foodBagItemCountCache end
	return addon.functions.rebuildFoodBagItemCountCache()
end

function addon.functions.getFoodBagItemCountCacheVersion()
	if addon.foodBagItemCountCacheReady ~= true then addon.functions.getFoodBagItemCountCache() end
	return tonumber(addon.foodBagItemCountCacheVersion) or 0
end

function addon.functions.getFoodBagItemCount(itemId)
	local targetId = tonumber(itemId)
	if not targetId or targetId <= 0 then return 0 end
	local cache = addon.functions.getFoodBagItemCountCache()
	return tonumber(cache[targetId]) or 0
end

local sharedFoodBagItemCountCacheFrame = addon.sharedFoodBagItemCountCacheFrame or CreateFrame("Frame")
addon.sharedFoodBagItemCountCacheFrame = sharedFoodBagItemCountCacheFrame
sharedFoodBagItemCountCacheFrame:RegisterEvent("PLAYER_LOGIN")
sharedFoodBagItemCountCacheFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
sharedFoodBagItemCountCacheFrame:RegisterEvent("BAG_UPDATE_DELAYED")
sharedFoodBagItemCountCacheFrame:SetScript("OnEvent", function(_, event)
	if event ~= "PLAYER_LOGIN" and event ~= "PLAYER_ENTERING_WORLD" and event ~= "BAG_UPDATE_DELAYED" then return end
	invalidateSharedFoodBagItemCountCache()
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
