local parentAddonName = "EnhanceQoL"
local addon = _G[parentAddonName] or select(2, ...)
local Reminder = addon.ClassBuffReminder

-- SpellItemEnchantment, Forever 1.60.1.70058 (enUS).
-- Only class weapon imbues and poisons; totem enchants are excluded.
Reminder.foreverWeaponEnchantFamilies = {
	ROCKBITER = { class = "SHAMAN", enchantIds = { 1, 6, 29, 503, 683, 1663, 1664, 7568 } },
	FLAMETONGUE = { class = "SHAMAN", enchantIds = { 3, 4, 5, 523, 1665, 1666, 7567 } },
	FROSTBRAND = { class = "SHAMAN", enchantIds = { 2, 12, 524, 1667, 1668, 7566 } },
	WINDFURY = { class = "SHAMAN", enchantIds = { 283, 284, 525, 1669, 7569 } },
	EARTHLIVING = { class = "SHAMAN", enchantIds = { 6910, 6985 } },
	DEADLY = { class = "ROGUE", enchantIds = { 7, 8, 626, 627, 2630 } },
	INSTANT = { class = "ROGUE", enchantIds = { 323, 324, 325, 623, 624, 625 } },
	CRIPPLING = { class = "ROGUE", enchantIds = { 22, 603 } },
	MIND_NUMBING = { class = "ROGUE", enchantIds = { 23, 35, 643 } },
	WOUND = { class = "ROGUE", enchantIds = { 703, 704, 705, 706 } },
	LEECHING = { class = "ROGUE", enchantIds = { 6912 } },
	SEBACIOUS = { class = "ROGUE", enchantIds = { 7254 } },
	NUMBING = { class = "ROGUE", enchantIds = { 7255 } },
	ATROPHIC = { class = "ROGUE", enchantIds = { 7256 } },
	OCCULT = { class = "ROGUE", enchantIds = { 7542, 7651 } },
}
Reminder.foreverWeaponEnchants = {}
for family, data in pairs(Reminder.foreverWeaponEnchantFamilies) do
	for _, id in ipairs(data.enchantIds) do
		Reminder.foreverWeaponEnchants[id] = { family = family, class = data.class }
	end
end
local function plain(value)
	if issecretvalue and issecretvalue(value) then return nil end
	return value
end

-- Returns an active temporary enchant, optionally restricted to a class family.
-- Permanent enchants must never satisfy a weapon-buff reminder.
function Reminder:GetForeverWeaponEnchant(slot, class, enchantId)
	if not (C_Item and C_Item.GetWeaponEnchantInfo and Enum and Enum.WeaponSlot and Enum.ItemEnchantType) then return nil end
	local weaponSlot
	if slot == (_G.INVSLOT_MAINHAND or 16) then
		weaponSlot = Enum.WeaponSlot.MainHand
	elseif slot == (_G.INVSLOT_OFFHAND or 17) then
		weaponSlot = Enum.WeaponSlot.OffHand
	else
		return nil
	end
	local enchants = plain(C_Item.GetWeaponEnchantInfo(weaponSlot))
	if type(enchants) ~= "table" then return nil end
	local selected, selectedId, selectedTime, unknown
	for _, enchant in pairs(enchants) do
		enchant = plain(enchant)
		if type(enchant) == "table" then
			local active = plain(enchant.hasEnchant)
			local kind = plain(enchant.enchantType)
			if active == nil or (active == true and kind == nil) then
				unknown = true
			elseif active == true and (kind == Enum.ItemEnchantType.Temporary or kind == Enum.ItemEnchantType.Imbue) then
				local id, remaining = plain(enchant.enchantID), plain(enchant.timeLeft)
				local data = id and self.foreverWeaponEnchants[id]
				if remaining == nil or (class and id == nil) then
					unknown = true
				elseif (not class or (data and data.class == class)) and (not enchantId or id == enchantId) then
					-- Multiple slots may contain independent temporary enchants.
					if not selected or remaining > selectedTime then
						selected, selectedId, selectedTime = true, id, remaining
					end
				end
			end
		else
			unknown = true
		end
	end
	if selected then return true, selectedId, selectedTime, self.foreverWeaponEnchants[selectedId] end
	if unknown then return nil end
	return false
end

function Reminder.GetPlayerWeaponEnchantIds()
	local hasMain, mainId = Reminder:GetForeverWeaponEnchant(_G.INVSLOT_MAINHAND or 16)
	local hasOff, offId = Reminder:GetForeverWeaponEnchant(_G.INVSLOT_OFFHAND or 17)
	return hasMain, mainId, hasOff, offId
end

function Reminder.PlayerMainhandHasEnchantId(enchantId)
	local hasEnchant, id = Reminder:GetForeverWeaponEnchant(_G.INVSLOT_MAINHAND or 16, nil, enchantId)
	return hasEnchant == true and id == enchantId
end

function Reminder.PlayerOffhandHasEnchantId(enchantId)
	local hasEnchant, id = Reminder:GetForeverWeaponEnchant(_G.INVSLOT_OFFHAND or 17, nil, enchantId)
	return hasEnchant == true and id == enchantId
end
