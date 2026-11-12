local addon = _G.EnhanceQoL
local Reminder = addon.ClassBuffReminder
local L = LibStub("AceLocale-3.0"):GetLocale("EnhanceQoL")

local function spellName(id)
	if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
	if GetSpellInfo then return (GetSpellInfo(id)) end
end

function Reminder:IsSpellReminderDisabled(spellId, ignoreContent)
	if not ignoreContent then
		if not self:IsSpellReminderContentAllowed(spellId) then return true end
		if self:IsClassBuffCombatOnly(spellId) and not (InCombatLockdown and InCombatLockdown()) then return true end
	end
	local disabled = addon.db and addon.db.classBuffReminderDisabledSpells
	if not spellId or type(disabled) ~= "table" then return false end
	if disabled[spellId] == true then return true end
	-- A choice applies to all ranks of the same spell, including newly learned ranks.
	local name = spellName(spellId)
	if not name then return false end
	for id, selected in pairs(disabled) do
		if selected == true and spellName(id) == name then return true end
	end
	return false
end

function Reminder:GetEnabledReminderSpellIds(ids)
	local disabled = addon.db and addon.db.classBuffReminderDisabledSpells
	if (type(disabled) ~= "table" or next(disabled) == nil) and not (addon.db and (addon.db.classBuffReminderSpellContent or addon.db.classBuffReminderCombatOnlySpells)) then return ids end
	local enabled = {}
	for _, id in ipairs(ids or {}) do
		if not self:IsSpellReminderDisabled(id) then enabled[#enabled + 1] = id end
	end
	return enabled
end

function Reminder:GetMageMagicCandidates(ids)
	local candidates = {}
	for _, baseId in ipairs({ 604, 1008 }) do
		local name, ranks = spellName(baseId), {}
		if name then
			for _, id in ipairs(ids) do
				if spellName(id) == name then ranks[#ranks + 1] = id end
			end
			local spellId = self:GetInteractionSpellId(ranks)
			if spellId then candidates[#candidates + 1] = { spellId = spellId, baseId = baseId, label = name } end
		end
	end
	return candidates
end

function Reminder:GetSelectedMageMagicSpell(candidates)
	local selected = addon.db and addon.db.classBuffReminderMageMagicSelection
	for _, candidate in ipairs(candidates) do
		if candidate.baseId == selected then return candidate.spellId end
	end
	return candidates[1] and candidates[1].spellId
end

function Reminder:SelectMageMagicSpell(spellId, candidates)
	if not addon.db then return end
	for _, candidate in ipairs(candidates) do
		if candidate.spellId == spellId then
			addon.db.classBuffReminderMageMagicSelection = candidate.baseId
			self:InvalidateSelfProviderStatus()
			self:RequestUpdate(true)
			return
		end
	end
end

function Reminder:GetShamanWeaponCandidates(ids)
	local candidates = {}
	for _, baseId in ipairs({ 8232, 8024, 8033, 8017 }) do
		local name, ranks = spellName(baseId), {}
		if name then
			for _, id in ipairs(ids) do
				if spellName(id) == name then ranks[#ranks + 1] = id end
			end
			local spellId = self:GetInteractionSpellId(ranks)
			if spellId then candidates[#candidates + 1] = { spellId = spellId, baseId = baseId, label = name } end
		end
	end
	return candidates
end

function Reminder:GetSelectedShamanWeaponSpell(slot, candidates)
	local stored = addon.db and addon.db.classBuffReminderShamanWeaponSelection
	local selected = type(stored) == "table" and stored[slot]
	for _, candidate in ipairs(candidates) do
		if candidate.baseId == selected then return candidate.spellId end
	end
	return candidates[1] and candidates[1].spellId
end

function Reminder:SelectShamanWeaponSpell(slot, spellId, candidates)
	if not addon.db then return end
	for _, candidate in ipairs(candidates) do
		if candidate.spellId == spellId then
			if type(addon.db.classBuffReminderShamanWeaponSelection) ~= "table" then addon.db.classBuffReminderShamanWeaponSelection = {} end
			addon.db.classBuffReminderShamanWeaponSelection[slot] = candidate.baseId
			self:InvalidateSelfProviderStatus()
			self:RequestUpdate(true)
			return
		end
	end
end

function Reminder:GetClassicAlternativeCandidates(ids)
	local families, byName, candidates = {}, {}, {}
	for _, id in ipairs(ids) do
		local name = spellName(id)
		if name then
			local family = byName[name]
			if not family then
				family = { ids = {}, baseId = id, label = name }
				byName[name] = family
				families[#families + 1] = family
			end
			family.ids[#family.ids + 1] = id
			if id < family.baseId then family.baseId = id end
		end
	end
	for _, family in ipairs(families) do
		local spellId = self:GetInteractionSpellId(family.ids)
		if spellId then candidates[#candidates + 1] = { spellId = spellId, baseId = family.baseId, label = family.label } end
	end
	return candidates
end

function Reminder:GetSelectedClassicAlternative(key, candidates)
	local stored = addon.db and addon.db.classBuffReminderClassicSelections
	local selected = type(stored) == "table" and stored[key]
	for _, candidate in ipairs(candidates) do
		if candidate.baseId == selected then return candidate.spellId end
	end
	return candidates[1] and candidates[1].spellId
end

function Reminder:SelectClassicAlternative(key, spellId, candidates)
	if not addon.db then return end
	for _, candidate in ipairs(candidates) do
		if candidate.spellId == spellId then
			if type(addon.db.classBuffReminderClassicSelections) ~= "table" then addon.db.classBuffReminderClassicSelections = {} end
			addon.db.classBuffReminderClassicSelections[key] = candidate.baseId
			self:InvalidateSelfProviderStatus()
			self:RequestUpdate(true)
			return
		end
	end
end

Reminder.classTrackerKeys = {
	classBuffReminderTrackFlasks = "trackFlasks",
	classBuffReminderTrackFood = "trackFood",
	classBuffReminderTrackRunes = "trackRunes",
	classBuffReminderTrackWeaponBuffs = "trackWeaponBuffs",
	classBuffReminderTrackPets = "trackPets",
	classBuffReminderTrackStances = "trackStances",
	classBuffReminderTrackHealthstones = "trackHealthstones",
	classBuffReminderTrackGathering = "trackGathering",
}

function Reminder:GetClassTrackerSetting(key, fallback, class)
	class = class or self:GetClassToken()
	local settings = addon.db and addon.db.classBuffReminderClassTrackers
	local selected = type(settings) == "table" and settings[class]
	if type(selected) == "table" and type(selected[key]) == "boolean" then return selected[key] end
	local value = addon.db and addon.db[key]
	if value == nil then value = fallback end
	return value == true
end

function Reminder:SetClassTrackerSetting(class, key, enabled)
	if not (addon.db and self.classTrackerKeys[key]) then return end
	local settings = addon.db.classBuffReminderClassTrackers
	if type(settings) ~= "table" then settings = {}; addon.db.classBuffReminderClassTrackers = settings end
	if type(settings[class]) ~= "table" then settings[class] = {} end
	settings[class][key] = enabled == true
	self:OnSettingChanged()
end

function Reminder:IsClassBuffRowEnabled(row, class)
	if row.trackerKey then return self:GetClassTrackerSetting(row.trackerKey, self.defaults[self.classTrackerKeys[row.trackerKey]], class) end
	return not self:IsSpellReminderDisabled(row.spellIds[1], true)
end

function Reminder:SetClassBuffRowEnabled(row, class, enabled)
	if row.trackerKey then return self:SetClassTrackerSetting(class, row.trackerKey, enabled) end
	if not addon.db then return end
	local disabled = addon.db.classBuffReminderDisabledSpells
	if type(disabled) ~= "table" then disabled = {}; addon.db.classBuffReminderDisabledSpells = disabled end
	local names = {}
	for _, id in ipairs(row.spellIds) do
		local name = spellName(id)
		if name then names[name] = true end
	end
	-- Clear older rank choices as well, including saved IDs outside the current list.
	for id in pairs(disabled) do
		if names[spellName(id)] then disabled[id] = nil end
	end
	for _, id in ipairs(row.spellIds) do disabled[id] = not enabled and true or nil end
	self:OnSettingChanged()
end

function Reminder:GetClassBuffRows(class)
	local rows, byName = {}, {}
	local function addSource(source, split)
		if not source then return end
		local family
		for _, id in ipairs(source.spellIds or {}) do
			local name = spellName(id)
			if name then
				local row = not split and family or byName[name]
				if not row then
					local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
					row = { spellIds = {}, id = id, label = name, icon = info and info.iconID, kind = (source.group or source.singleTarget) and (_G.GROUP or L["ClassBuffReminderSectionClassBuffs"]) or (_G.PLAYER or L["ClassBuffReminderSectionClassBuffs"]) }
					rows[#rows + 1] = row
					byName[name] = row
				end
				row.spellIds[#row.spellIds + 1] = id
				family = row
			end
		end
		if family then
			for _, id in ipairs(source.aliases or {}) do family.spellIds[#family.spellIds + 1] = id end
		end
	end
	local group = self.classBuffGroupProviders and self.classBuffGroupProviders[class]
	if group then addSource({ spellIds = group.spellIds, aliases = group.knownSpellIds, group = true }, self.classicBuffs ~= nil) end
	for _, source in ipairs(self.classicBuffs and self.classicBuffs[class] or {}) do addSource(source, true) end
	for _, source in ipairs(self.classBuffExtraSources and self.classBuffExtraSources[class] or {}) do addSource(source, source.split) end
	if class == "PALADIN" and self.foreverBuffs then
		for _, key in ipairs(self.foreverBuffs.blessingOrder) do addSource({ spellIds = self.foreverBuffs.blessings[key], group = true }, true) end
	end
	local function tracker(key, label, icon)
		rows[#rows + 1] = { trackerKey = key, label = label, icon = icon, kind = L["ClassBuffReminderTrackerMatrixTracker"] }
	end
	tracker("classBuffReminderTrackWeaponBuffs", L["ClassBuffReminderSectionWeaponBuffs"], "Interface\\Icons\\INV_Stone_SharpeningStone_01")
	if not self.classicBuffs then
		tracker("classBuffReminderTrackFlasks", L["ClassBuffReminderSectionFlasks"], "Interface\\Icons\\INV_Potion_54")
		tracker("classBuffReminderTrackFood", L["ClassBuffReminderSectionFood"], "Interface\\Icons\\INV_Misc_Food_15")
		tracker("classBuffReminderTrackRunes", L["ClassBuffReminderSectionRunes"], "Interface\\Icons\\INV_Misc_Rune_01")
	else
		tracker("classBuffReminderTrackGathering", L["ClassBuffReminderGatheringTracking"], "Interface\\Icons\\INV_Pick_02")
	end
	if self.stanceTracking and (self.stanceTracking.definitions[class] or (class == "WARRIOR" and self.stanceTracking.definitions.WARRIOR_ARMS)) then
		tracker("classBuffReminderTrackStances", L["CooldownPanelStanceType"], "Interface\\Icons\\Ability_Warrior_BattleShout")
	end
	if class == "HUNTER" or class == "WARLOCK" or (not self.classicBuffs and (class == "DEATHKNIGHT" or class == "MAGE")) then
		tracker("classBuffReminderTrackPets", L["ClassBuffReminderSectionPets"], "Interface\\Icons\\Ability_Hunter_BeastCall")
	end
	if class == "WARLOCK" then
		tracker("classBuffReminderTrackHealthstones", L["ClassBuffReminderHealthstone"], "Interface\\Icons\\INV_Stone_04")
		if not self.classicBuffs then
			addSource({ spellIds = { self.petTracking.grimoireOfSacrificeBuff }, aliases = { self.petTracking.grimoireOfSacrifice } })
		end
	end
	table.sort(rows, function(a, b)
		if (a.trackerKey ~= nil) ~= (b.trackerKey ~= nil) then return a.trackerKey == nil end
		return a.label < b.label
	end)
	return rows
end

function Reminder:GetSpellReminderOptions()
	local options, seen = {}, {}
	local function add(id)
		local name = spellName(id)
		if not name or seen[name] then return end
		seen[name] = true
		options[#options + 1] = { value = id, text = name }
	end
	-- Keep saved choices visible even after changing specialization or learning a rank.
	for id, selected in pairs(addon.db.classBuffReminderDisabledSpells or {}) do
		if selected == true then add(id) end
	end
	local provider = self:GetProvider()
	for _, id in ipairs(provider and provider.spellIds or {}) do add(id) end
	table.sort(options, function(a, b) return a.text < b.text end)
	return options
end

-- Class-specific tracker selections inherit existing content choices until edited.
Reminder.classTrackerContent = {
	classBuffReminderTrackFlasks = { "GetFlaskTrackingContentSelection", "SetFlaskTrackingContentSelection" },
	classBuffReminderTrackFood = { "GetFoodTrackingContentSelection", "SetFoodTrackingContentSelection" },
	classBuffReminderTrackRunes = { "GetRuneTrackingContentSelection", "SetRuneTrackingContentSelection" },
	classBuffReminderTrackWeaponBuffs = { "GetWeaponBuffTrackingContentSelection", "SetWeaponBuffTrackingContentSelection" },
	classBuffReminderTrackPets = { "GetPetTrackingContentSelection", "SetPetTrackingContentSelection" },
	classBuffReminderTrackStances = { "GetStanceTrackingContentSelection", "SetStanceTrackingContentSelection" },
	classBuffReminderTrackHealthstones = { "GetHealthstoneTrackingContentSelection", "SetHealthstoneTrackingContentSelection" },
	classBuffReminderTrackGathering = { "GetGatheringTrackingContentSelection", "SetGatheringTrackingContentSelection" },
}
Reminder.legacyTrackerContentGetters = {}

function Reminder:GetClassBuffRowContent(row, class)
	class = class or self:GetClassToken()
	if row.trackerKey then
		local stored = addon.db and addon.db.classBuffReminderTrackerContent
		local selection = stored and stored[class] and stored[class][row.trackerKey]
		if type(selection) == "table" then return self.CopyTrackingContentSelection(selection) end
		local getter = self.legacyTrackerContentGetters[row.trackerKey]
		local inherited = getter and getter(self)
		return self.CopyTrackingContentSelection(inherited or self.CreateAllTrackingContentSelection())
	end
	local stored = addon.db and addon.db.classBuffReminderSpellContent
	local selections = stored and stored[class]
	if type(selections) == "table" then
		for _, id in ipairs(row.spellIds or {}) do
			if type(selections[id]) == "table" then return self.CopyTrackingContentSelection(selections[id]), true end
		end
		-- Resolve saved ranks by spell name after learning a new rank.
		local name = spellName(row.spellIds and row.spellIds[1])
		if name then
			for id, selection in pairs(selections) do
				if type(selection) == "table" and spellName(id) == name then return self.CopyTrackingContentSelection(selection), true end
			end
		end
	end
	return self.CreateAllTrackingContentSelection()
end

function Reminder:SetClassBuffRowContent(row, class, selection)
	if not addon.db then return end
	local key = row.trackerKey and "classBuffReminderTrackerContent" or "classBuffReminderSpellContent"
	if type(addon.db[key]) ~= "table" then addon.db[key] = {} end
	if type(addon.db[key][class]) ~= "table" then addon.db[key][class] = {} end
	local selections = addon.db[key][class]
	selection = select(1, self.NormalizeTrackingContentSelection(selection))
	if row.trackerKey then
		selections[row.trackerKey] = selection
	else
		local names = {}
		for _, id in ipairs(row.spellIds) do
			local name = spellName(id)
			if name then names[name] = true end
		end
		for id in pairs(selections) do
			if names[spellName(id)] then selections[id] = nil end
		end
		for _, id in ipairs(row.spellIds) do selections[id] = self.CopyTrackingContentSelection(selection) end
	end
	self:OnSettingChanged()
end

function Reminder:IsSpellReminderContentAllowed(spellId)
	if not spellId or not (addon.db and addon.db.classBuffReminderSpellContent) then return true end
	local selection, configured = self:GetClassBuffRowContent({ spellIds = { spellId } })
	if not configured then return true end
	return self:IsTrackingContentSelected(selection)
end

for key, methods in pairs(Reminder.classTrackerContent) do
	local getter = Reminder[methods[1]]
	Reminder.legacyTrackerContentGetters[key] = getter
	Reminder[methods[1]] = function(self) return self:GetClassBuffRowContent({ trackerKey = key }) end
	-- Edit Mode uses these setters too; keep it aligned with the class table.
	Reminder[methods[2]] = function(self, selection) self:SetClassBuffRowContent({ trackerKey = key }, self:GetClassToken(), selection) end
end

function Reminder:CanConfigureClassBuffCombatOnly(row, class)
	if class ~= "WARRIOR" or row.trackerKey then return false end
	for _, id in ipairs(row.spellIds or {}) do
		if id == 6673 or id == 403215 or id == 469 then return true end
	end
	return false
end

function Reminder:IsClassBuffCombatOnly(spellId)
	local stored = addon.db and addon.db.classBuffReminderCombatOnlySpells
	if not spellId or type(stored) ~= "table" then return false end
	if stored[spellId] == true then return true end
	local name = spellName(spellId)
	if name then
		for id, enabled in pairs(stored) do
			if enabled == true and spellName(id) == name then return true end
		end
	end
	return false
end

function Reminder:SetClassBuffCombatOnly(row, class, enabled)
	if not addon.db or not self:CanConfigureClassBuffCombatOnly(row, class) then return end
	local stored = addon.db.classBuffReminderCombatOnlySpells
	if type(stored) ~= "table" then stored = {}; addon.db.classBuffReminderCombatOnlySpells = stored end
	local names = {}
	for _, id in ipairs(row.spellIds) do
		local name = spellName(id)
		if name then names[name] = true end
	end
	for id in pairs(stored) do
		if names[spellName(id)] then stored[id] = nil end
	end
	for _, id in ipairs(row.spellIds) do stored[id] = enabled == true or nil end
	self:OnSettingChanged()
end
