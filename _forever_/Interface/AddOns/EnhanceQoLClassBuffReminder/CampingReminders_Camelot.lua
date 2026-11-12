local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)
if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

local Reminder = addon.ClassBuffReminder
local L = LibStub("AceLocale-3.0"):GetLocale(parentAddonName)
local M = {
	food = "classBuffReminderForeverFood",
	bag = "classBuffReminderForeverSleepingBag",
	camp = "classBuffReminderForeverCamp",
	bagItem = 211527,
	bagBuff = 429959,
	campBuff = 1229741,
	campRest = 1229739,
}
Reminder.foreverCamping = M

local function plain(value)
	if issecretvalue and issecretvalue(value) then return nil end
	return value
end
local function pack(...) return { ... }, select("#", ...) end
local function enabled(key) return addon.db and addon.db[key] == true end

function M.BagEligible()
	local level = UnitLevel and plain(UnitLevel("player"))
	local count = C_Item and C_Item.GetItemCount and plain(C_Item.GetItemCount(M.bagItem, false, false))
	return type(level) == "number" and level > 0 and level < 60 and type(count) == "number" and count > 0
end

function Reminder:CanCheckForeverCampingReminders()
	if not self:CanReadAuraData() or self:IsFlaskEnvironmentRestricted() or not self:IsGroupModeAllowed() then return false end
	return enabled(M.food) or enabled(M.camp) or (enabled(M.bag) and M.BagEligible())
end

-- Read actual helpful auras: casts, cooldowns and nearby fires do not prove coverage.
function M.ReadAuras()
	if not (C_UnitAuras and C_UnitAuras.GetAuraSlots and C_UnitAuras.GetAuraDataBySlot) then return nil end
	local result, continuation = {}, nil
	for _ = 1, 100 do
		local slots, count = pack(C_UnitAuras.GetAuraSlots("player", "HELPFUL", nil, continuation))
		if issecretvalue and issecretvalue(slots[1]) then return nil end
		continuation = slots[1]
		for i = 2, count do
			local slot = plain(slots[i])
			if not slot then return nil end
			local aura = plain(C_UnitAuras.GetAuraDataBySlot("player", slot))
			if not aura then return nil end
			local id = plain(aura.spellId)
			if not id then return nil end
			result[id] = aura
		end
		if continuation == nil then return result end
	end
end

function M.Entry(id, kind, label)
	local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
	local entry = Reminder:MakeSelfCastInteractionEntry(id, label or (info and info.name), nil, nil, kind, info and info.iconID)
	entry.actionSpellId = nil
	return entry
end

function Reminder:GetForeverCampingMissingEntries()
	local entries = {}
	if not self:CanCheckForeverCampingReminders() then return entries end
	local auras = M.ReadAuras()
	if not auras then return entries end
	if enabled(M.food) then
		local present = false
		for _, id in ipairs(addon.Aura.ForeverWellFedSpellIDs) do
			if auras[id] then present = true; break end
		end
		if not present then entries[#entries + 1] = M.Entry(1248406, "FOREVER_FOOD") end
	end
	if enabled(M.bag) and M.BagEligible() then
		local aura = auras[M.bagBuff]
		local stacks = 0
		if aura then stacks = plain(aura.applications) end
		if type(stacks) == "number" and stacks < 3 then
			local entry = M.Entry(M.bagBuff, "FOREVER_SLEEPING_BAG", L["ClassBuffReminderForeverSleepingBag"])
			entry.shortText = tostring(stacks) .. "/3"
			entry.itemId = M.bagItem
			entry.icon = Reminder.GetItemIcon(M.bagItem) or entry.icon
			entries[#entries + 1] = entry
		end
	end
	if enabled(M.camp) and not auras[M.campBuff] then
		local entry = M.Entry(M.campBuff, "FOREVER_CAMP")
		local resting = auras[M.campRest]
		local expiration = resting and plain(resting.expirationTime)
		if type(expiration) == "number" and expiration > GetTime() then entry.progressExpiration = expiration end
		entries[#entries + 1] = entry
	end
	return entries
end

function Reminder:GetForeverCampingOnlyProvider()
	self.foreverCampingOnlyProvider = self.foreverCampingOnlyProvider or {
		scope = "SELF", spellIds = { M.campBuff }, displaySpellId = M.campBuff, isSupplementalOnly = true,
	}
	return self.foreverCampingOnlyProvider
end

function Reminder:RegisterForeverCampingSettings(cat, section)
	for _, option in ipairs({
		{ key = M.food, label = "ClassBuffReminderForeverFood" },
		{ key = M.bag, label = "ClassBuffReminderForeverSleepingBag" },
		{ key = M.camp, label = "ClassBuffReminderForeverCamp" },
	}) do
		local key, label = option.key, option.label
		if addon.functions.InitDBValue then addon.functions.InitDBValue(key, false) end
		addon.functions.SettingsCreateCheckbox(cat, {
			var = key, text = L[label], desc = L[label .. "Desc"], default = false,
			get = function() return enabled(key) end,
			func = function(value)
				addon.db[key] = value == true
				Reminder:OnSettingChanged()
			end,
			isEnabled = function() return self:IsEnabled() end,
			parentSection = section, newTagID = label,
		})
	end
end
