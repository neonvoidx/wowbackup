local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local Reminder = addon.ClassBuffReminder
local F = {}
Reminder.foreverBuffs = F

local function plain(value)
	if _G.issecretvalue and _G.issecretvalue(value) then return nil end
	return value
end

F.playstyleClasses = { WARRIOR = true, PALADIN = true, DRUID = true, SHAMAN = true, PRIEST = true }
F.playstyles = { AUTO = true, MELEE = true, CASTER = true, HEALER = true, TANK = true }

F.paladinTalentGroups = { 11486, 11541, 11559 }
F.righteousFurySpellIds = { 25780 }

function Reminder:IsForeverProtectionPaladin()
	if self:GetClassToken() ~= "PALADIN" then return false end
	if not (C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GetConfigInfo and C_Traits.GetGroupCurrencyInfo) then return false end
	local configID = plain(C_ClassTalents.GetActiveConfigID())
	local config = configID and C_Traits.GetConfigInfo(configID)
	if not config then return false end
	if C_Traits.ConfigHasStagedChanges then
		local staged = plain(C_Traits.ConfigHasStagedChanges(configID))
		if staged ~= false then return false end
	end
	local paladinTree = false
	for _, treeID in ipairs(config.treeIDs or {}) do
		if plain(treeID) == 1100 then paladinTree = true end
	end
	if not paladinTree then return false end
	local infos = C_Traits.GetGroupCurrencyInfo(configID, F.paladinTalentGroups)
	if type(infos) ~= "table" then return false end
	-- Groups without spent talent points may be omitted by the Forever API.
	local points = { [11486] = 0, [11541] = 0, [11559] = 0 }
	for _, info in ipairs(infos) do
		local groupID = plain(info.traitNodeGroupID)
		if groupID and points[groupID] ~= nil then
			local currency = info.currencyInfos and info.currencyInfos[1]
			if currency then
				local spent = plain(currency.spent)
				if type(spent) ~= "number" then return false end
				points[groupID] = spent
			end
		elseif not groupID then
			return false
		end
	end
	return points[11541] > 0 and points[11541] > points[11486] and points[11541] > points[11559]
end

function Reminder:AppendForeverRighteousFuryEntry(entries, total)
	local spellId = F.righteousFurySpellIds[1]
	if not self:IsForeverProtectionPaladin() or not self:GetInteractionSpellId(F.righteousFurySpellIds) then return total end
	if self.IsSpellReminderDisabled and self:IsSpellReminderDisabled(spellId) then return total end
	if not self:UnitHasAnyAuraSpellIdOrDerivedName("player", F.righteousFurySpellIds) then
		local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellId)
		local entry = self:MakeSelfCastInteractionEntry(spellId, info and info.name)
		entry.warningSpellIds = F.righteousFurySpellIds
		entries[#entries + 1] = entry
	end
	return total + 1
end

function Reminder:GetForeverPlaystyleSelection()
	local selected = addon.db and addon.db.classBuffReminderForeverPlaystyle
	local class = self:GetClassToken()
	if not F.playstyleClasses[class] then return "AUTO" end
	if class == "PRIEST" and selected ~= "HEALER" and selected ~= "CASTER" then return "AUTO" end
	if class == "WARRIOR" and selected ~= "MELEE" and selected ~= "TANK" then return "AUTO" end
	return F.playstyles[selected] and selected or "AUTO"
end

function Reminder:GetForeverUnitPlaystyle(unit)
	local class = plain(select(2, UnitClass(unit)))
	local player = unit == "player" or (UnitIsUnit and plain(UnitIsUnit(unit, "player")) == true)
	local role = UnitGroupRolesAssigned and plain(UnitGroupRolesAssigned(unit))
	if role == "TANK" then return "TANK", class end
	if player and F.playstyleClasses[class] then
		local selected = self:GetForeverPlaystyleSelection()
		if selected ~= "AUTO" then return selected, class end
	end
	if role == "HEALER" then return "HEALER", class end
	if class == "WARRIOR" or class == "ROGUE" then return "MELEE", class end
	if class == "MAGE" or class == "WARLOCK" or class == "PRIEST" then return "CASTER", class end
	if class == "HUNTER" then return "RANGED", class end
	if class == "PALADIN" and role == "DAMAGER" then return "MELEE", class end
	if class == "DRUID" and UnitPowerType then
		local power = plain(select(2, UnitPowerType(unit)))
		if power == "ENERGY" or power == "RAGE" then return "MELEE", class end
	end
	-- Forever's class-only specialization IDs do not identify hybrid builds.
	return "UNKNOWN", class
end

-- Forever 1.60.1.69876: ItemXItemEffect -> ItemEffect -> SpellEffect (54)
-- -> SpellItemEnchantment; weapon masks come from SpellEquippedItems.
F.weaponItems = {
	{ id = 12404, kind = "PHYSICAL", mask = 33219, rank = 5 },
	{ id = 7964, kind = "PHYSICAL", mask = 33219, rank = 4 },
	{ id = 2871, kind = "PHYSICAL", mask = 33219, rank = 3 },
	{ id = 2863, kind = "PHYSICAL", mask = 33219, rank = 2 },
	{ id = 2862, kind = "PHYSICAL", mask = 33219, rank = 1 },
	{ id = 12643, kind = "PHYSICAL", mask = 9264, rank = 5 },
	{ id = 7965, kind = "PHYSICAL", mask = 9264, rank = 4 },
	{ id = 3241, kind = "PHYSICAL", mask = 9264, rank = 3 },
	{ id = 3240, kind = "PHYSICAL", mask = 9264, rank = 2 },
	{ id = 3239, kind = "PHYSICAL", mask = 9264, rank = 1 },
	{ id = 18262, kind = "MELEE_CRIT", mask = 42483, rank = 6 },
	{ id = 20749, kind = "CASTER", rank = 4 },
	{ id = 20750, kind = "CASTER", rank = 3 },
	{ id = 20746, kind = "CASTER", rank = 2 },
	{ id = 20744, kind = "CASTER", rank = 1 },
	{ id = 20748, kind = "MANA", rank = 3 },
	{ id = 20747, kind = "MANA", rank = 2 },
	{ id = 20745, kind = "MANA", rank = 1 },
	{ id = 3824, kind = "PHYSICAL", mask = 173555, rank = 0 },
	{ id = 3829, kind = "PHYSICAL", mask = 173555, rank = 0 },
}
F.weaponItemIds = {}
F.requestedItemData = {}
for _, item in ipairs(F.weaponItems) do F.weaponItemIds[item.id] = true end
F.weaponLocations = { INVTYPE_WEAPON = true, INVTYPE_2HWEAPON = true, INVTYPE_WEAPONMAINHAND = true, INVTYPE_WEAPONOFFHAND = true }

function F.GetWeaponPreference(kind, playstyle, class)
	if playstyle == "UNKNOWN" then return kind == "PHYSICAL" and 1 or nil end
	if class == "WARRIOR" or class == "ROGUE" then return (kind == "PHYSICAL" or kind == "MELEE_CRIT") and 1 or nil end
	if class == "HUNTER" then return kind == "MANA" and 1 or kind == "PHYSICAL" and 2 or nil end
	if playstyle == "HEALER" then return kind == "MANA" and 1 or kind == "CASTER" and 2 or kind == "PHYSICAL" and 3 or nil end
	if playstyle == "CASTER" then return kind == "CASTER" and 1 or kind == "MANA" and 2 or kind == "PHYSICAL" and 3 or nil end
	-- Elemental stones grant melee crit through spell 22755, rather than weapon damage.
	-- Ordinary weapon damage and on-hit oils are not offered for Feral forms.
	if class == "DRUID" then return kind == "MELEE_CRIT" and 1 or nil end
	if playstyle == "TANK" and class == "PALADIN" then
		return kind == "CASTER" and 1 or (kind == "PHYSICAL" or kind == "MELEE_CRIT") and 2 or kind == "MANA" and 3 or nil
	end
	if playstyle == "MELEE" then return (kind == "PHYSICAL" or kind == "MELEE_CRIT") and 1 or kind == "CASTER" and 2 or kind == "MANA" and 3 or nil end
	return kind == "PHYSICAL" and 1 or nil
end

function Reminder:GetForeverWeaponBuffCandidates(slot)
	if slot ~= (_G.INVSLOT_MAINHAND or 16) and slot ~= (_G.INVSLOT_OFFHAND or 17) then return nil end
	if not (C_Item and C_Item.GetItemInfoInstant and C_Item.GetItemInfo and C_Item.GetItemCount and GetInventoryItemID) then return nil end
	self.foreverWeaponBuffCandidates = self.foreverWeaponBuffCandidates or {}
	if self.foreverWeaponBuffCandidates[slot] then return self.foreverWeaponBuffCandidates[slot] end
	local weapon = plain(GetInventoryItemID("player", slot))
	if not weapon then return nil end
	local _, _, _, location, _, itemClass, subclass = C_Item.GetItemInfoInstant(weapon)
	location, itemClass, subclass = plain(location), plain(itemClass), plain(subclass)
	if not location or not subclass or itemClass ~= 2 or not F.weaponLocations[location] then return nil end
	local playstyle, class = self:GetForeverUnitPlaystyle("player")
	local level = UnitLevel and plain(UnitLevel("player"))
	if not level or level <= 0 then return nil end
	local candidates = {}
	for _, item in ipairs(F.weaponItems) do
		local preference = F.GetWeaponPreference(item.kind, playstyle, class)
		if preference and (not item.mask or bit.band(item.mask, 2 ^ subclass) ~= 0) then
			local count = plain(C_Item.GetItemCount(item.id, false, false))
			if count and count > 0 then
				local name, _, _, _, minimumLevel = C_Item.GetItemInfo(item.id)
				name, minimumLevel = plain(name), plain(minimumLevel)
				if name and minimumLevel and minimumLevel <= level then
					candidates[#candidates + 1] = { id = item.id, count = count, preference = preference, rank = item.rank }
				elseif not name and C_Item.RequestLoadItemDataByID and not F.requestedItemData[item.id] then
					F.requestedItemData[item.id] = true
					C_Item.RequestLoadItemDataByID(item.id)
				end
			end
		end
	end
	table.sort(candidates, function(a, b)
		if a.preference ~= b.preference then return a.preference < b.preference end
		if a.rank ~= b.rank then return a.rank > b.rank end
		return a.id < b.id
	end)
	self.foreverWeaponBuffCandidates[slot] = candidates
	return candidates
end

F.blessings = {
	MIGHT = { 25291, 19838, 19837, 19836, 19835, 19834, 19740, 25916, 25782 },
	WISDOM = { 25290, 19854, 19853, 19852, 19850, 19742, 25918, 25894 },
	KINGS = { 20217, 25898 },
}
F.blessingOrder = { "MIGHT", "WISDOM", "KINGS" }
F.blessingProfiles = {
	MELEE = { "MIGHT", "KINGS" },
	CASTER = { "WISDOM", "KINGS" },
	HEALER = { "WISDOM", "KINGS" },
	RANGED = { "WISDOM", "KINGS" },
	TANK_MELEE = { "KINGS", "MIGHT" },
	TANK_MANA = { "KINGS", "WISDOM", "MIGHT" },
	PALADIN_UNKNOWN = { "KINGS", "MIGHT" },
	UNKNOWN = { "KINGS" },
}
Reminder.foreverBlessingSpellIds = {}
F.blessingAuras = {}
for _, key in ipairs(F.blessingOrder) do
	for _, id in ipairs(F.blessings[key]) do Reminder.foreverBlessingSpellIds[#Reminder.foreverBlessingSpellIds + 1] = id end
end
Reminder.foreverPaladinSpellIds = { F.righteousFurySpellIds[1] }
for _, id in ipairs(Reminder.foreverBlessingSpellIds) do Reminder.foreverPaladinSpellIds[#Reminder.foreverPaladinSpellIds + 1] = id end
for playstyle, keys in pairs(F.blessingProfiles) do
	local ids = {}
	for _, key in ipairs(keys) do
		for _, id in ipairs(F.blessings[key]) do ids[#ids + 1] = id end
	end
	F.blessingAuras[playstyle] = ids
end

function Reminder:GetForeverBlessingCandidates()
	local candidates = {}
	if self:GetClassToken() ~= "PALADIN" then return candidates end
	for _, key in ipairs(F.blessingOrder) do
		local spellId = self:GetInteractionSpellId(F.blessings[key])
		if spellId then
			local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellId)
			candidates[#candidates + 1] = { key = key, spellId = spellId, label = info and info.name or ("spell:" .. spellId) }
		end
	end
	return candidates
end

function F.GetBlessingSelectionStore(create)
	local guid = UnitGUID and plain(UnitGUID("player"))
	if type(guid) ~= "string" or guid == "" then return nil end
	local privateDB = addon.functions and addon.functions.GetPrivateDB and addon.functions.GetPrivateDB() or addon.privateDB
	if type(privateDB) ~= "table" then return nil end
	local selections = privateDB.classBuffReminderForeverBlessingSelection
	if type(selections) ~= "table" then
		if not create then return nil end
		selections = {}
		privateDB.classBuffReminderForeverBlessingSelection = selections
	end
	return selections, guid
end

function Reminder:GetForeverBlessingSelection()
	if self:GetClassToken() ~= "PALADIN" then return "AUTO" end
	local selections, guid = F.GetBlessingSelectionStore(false)
	local key = selections and selections[guid]
	if key and F.blessings[key] and self:GetInteractionSpellId(F.blessings[key]) then return key end
	return "AUTO"
end

function Reminder:SelectForeverBlessing(key)
	if self:GetClassToken() ~= "PALADIN" then return end
	if key ~= "AUTO" and (not F.blessings[key] or not self:GetInteractionSpellId(F.blessings[key])) then return end
	local selections, guid = F.GetBlessingSelectionStore(true)
	if not selections then return end
	selections[guid] = key ~= "AUTO" and key or nil
	self:InvalidateSelfProviderStatus()
	self:RequestUpdate(true)
end

function Reminder:GetForeverBlessingMissingEntries(provider)
	local entries, total = {}, 0
	if not self:ShouldEvaluateGroupResponsibilities(provider) then return entries, total end
	local selection = self:GetForeverBlessingSelection()
	local fixedFamily = selection ~= "AUTO" and F.blessings[selection] or nil
	local buckets = {}
	for _, unit in ipairs(self:GetRosterUnits()) do
		local playstyle, class = self:GetForeverUnitPlaystyle(unit)
		if playstyle == "TANK" then playstyle = (class == "PALADIN" or class == "SHAMAN") and "TANK_MANA" or "TANK_MELEE" end
		if playstyle == "UNKNOWN" and class == "PALADIN" then playstyle = "PALADIN_UNKNOWN" end
		local selectedSpell, selectedKey, fallback
		if fixedFamily then
			selectedSpell, selectedKey = self:GetInteractionSpellId(fixedFamily), selection
		else
			for _, key in ipairs(F.blessingProfiles[playstyle]) do
				selectedSpell = self:GetInteractionSpellId(F.blessings[key])
				if selectedSpell then selectedKey = key; break end
			end
			if not selectedSpell then
				for _, key in ipairs(F.blessingOrder) do
					selectedSpell = self:GetInteractionSpellId(F.blessings[key])
					if selectedSpell then selectedKey, fallback = key, true; break end
				end
			end
		end
		local auraIds = fixedFamily or (fallback and self.foreverBlessingSpellIds or F.blessingAuras[playstyle])
		local cache = self:GetGroupBuffStateCache(auraIds, false)
		if cache then self:GetGroupBuffState(cache) end
		local status = cache and self:GetGroupBuffUnitMissingStatus(cache, unit)
		-- Group-cache statuses: -1 ineligible, 0 present, 1 missing.
		if status == 0 or status == 1 then
			if selectedSpell then
				total = total + 1
				if status == 1 then
					local bucket = buckets[selectedKey]
					if not bucket then
						bucket = { spellId = selectedSpell, candidates = {}, warningStates = {} }
						buckets[selectedKey] = bucket
					end
					bucket.warningStates[#bucket.warningStates + 1] = cache.unitStates[unit] or {}
					local guid = UnitGUID and plain(UnitGUID(unit))
					local name = GetUnitName and plain(GetUnitName(unit, true)) or UnitName and plain(UnitName(unit))
					bucket.candidates[#bucket.candidates + 1] = { unit = unit, guid = guid, label = name or unit }
				end
			end
		end
	end
	for _, key in ipairs(F.blessingOrder) do
		local bucket = buckets[key]
		if bucket then
			local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(bucket.spellId)
			local entry = self:MakeSpellInteractionEntry(F.blessings[key], bucket.spellId, info and info.name, #bucket.candidates, total, "PALADIN_BLESSING_" .. key, info and info.iconID)
			entry.warningStates = bucket.warningStates
			entry.selectionForeverBlessing = true
			entry.targetSelectionKey = "PALADIN_BLESSING_" .. key
			entry.targetCandidates = bucket.candidates
			entry.actionUnit = self:GetSelectedInteractionTargetUnit(entry.targetSelectionKey, bucket.candidates)
			entries[#entries + 1] = entry
		end
	end
	return entries, total
end
