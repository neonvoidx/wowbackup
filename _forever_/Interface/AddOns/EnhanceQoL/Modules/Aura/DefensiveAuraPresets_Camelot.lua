local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}

-- Forever defensive auras shared by Group Frames and Cooldown Panels.
-- Spell ranks share one preset; cast-only IDs are excluded from native filters.
-- Do not include an ability solely because an unused spell record exists in the
-- client database. Talent choices must match the current Forever talent trees.
local defensiveAuraPresets = {
	presetOnlySpellIDs = {
		[12975] = true, -- Last Stand cast; the applied aura is 12976.
		[19028] = true, -- Soul Link cast; the applied aura is 25228.
	},
	externals = {
		-- Paladin
		{ primarySpellID = 1022, spellIDs = { 1022, 5599, 10278 } }, -- Blessing of Protection
		{ primarySpellID = 6940, spellIDs = { 6940, 20729 } }, -- Blessing of Sacrifice
		{ primarySpellID = 19752, spellIDs = { 19752 } }, -- Divine Intervention
		-- Priest
		{ primarySpellID = 17, spellIDs = { 17, 592, 600, 3747, 6065, 6066, 10898, 10899, 10900, 10901 } }, -- Power Word: Shield
		{
			primarySpellID = 1277462,
			spellIDs = {
				1277462, 1277634, 1277638, 1277639, 1277640, -- Contingency Plan wards
				1277463, 1277464, 1277465, 1277467, 1277466, -- Triggered shields
				1277456, 1277457, 1277458, 1277459, 1277460, -- Triggered healing
			},
		},
	},
	raidArea = {},
	classes = {
		{
			classTag = "DRUID",
			presets = {
				{ primarySpellID = 22812, spellIDs = { 22812 } }, -- Barkskin
				{ primarySpellID = 22842, spellIDs = { 22842 } }, -- Frenzied Regeneration
			},
		},
		{
			classTag = "HUNTER",
			presets = {
				{ primarySpellID = 19263, spellIDs = { 19263 } }, -- Deterrence
			},
		},
		{
			classTag = "MAGE",
			presets = {
				{ primarySpellID = 543, spellIDs = { 543, 8457, 8458, 10223, 10225 } }, -- Fire Ward
				{ primarySpellID = 1463, spellIDs = { 1463, 8494, 8495, 10191, 10192, 10193 } }, -- Mana Shield
				{ primarySpellID = 6143, spellIDs = { 6143, 8461, 8462, 10177, 28609 } }, -- Frost Ward
				{ primarySpellID = 11426, spellIDs = { 11426, 13031, 13032, 13033 } }, -- Ice Barrier
				{ primarySpellID = 11958, spellIDs = { 11958 } }, -- Ice Block
			},
		},
		{
			classTag = "PALADIN",
			presets = {
				{ primarySpellID = 498, spellIDs = { 498, 5573 } }, -- Divine Protection
				{ primarySpellID = 642, spellIDs = { 642, 1020 } }, -- Divine Shield
				{ primarySpellID = 20925, spellIDs = { 20925, 20927, 20928, 1239570 } }, -- Holy Shield
				{ primarySpellID = 1311015, spellIDs = { 1311015 } }, -- Templar's Bulwark
			},
		},
		{
			classTag = "PRIEST",
			presets = {
				{ primarySpellID = 586, spellIDs = { 586, 9578, 9579, 9592, 10941, 10942 } }, -- Fade
				{ primarySpellID = 27827, spellIDs = { 27827 } }, -- Spirit of Redemption
			},
		},
		{
			classTag = "ROGUE",
			presets = {
				{ primarySpellID = 5277, spellIDs = { 5277 } }, -- Evasion
				{ primarySpellID = 14278, spellIDs = { 14278 } }, -- Ghostly Strike
			},
		},
		{
			classTag = "WARLOCK",
			presets = {
				{ primarySpellID = 7812, spellIDs = { 7812, 19438, 19440, 19441, 19442, 19443 } }, -- Sacrifice
				{ primarySpellID = 19028, spellIDs = { 19028, 25228 } }, -- Soul Link
			},
		},
		{
			classTag = "WARRIOR",
			presets = {
				{ primarySpellID = 871, spellIDs = { 871 } }, -- Shield Wall
				{ primarySpellID = 2565, spellIDs = { 2565 } }, -- Shield Block
				{ primarySpellID = 12975, spellIDs = { 12975, 12976 } }, -- Last Stand
			},
		},
	},
}

-- Group Frames show defensives active on an individual unit: personal
-- defensives plus direct externals. Raid/area effects remain Cooldown Panels
-- presets and are deliberately excluded from this set.
defensiveAuraPresets.personalAndExternalSpellIDSet = {}
local function addPresetSpellIDsToSet(preset)
	local spellIDs = type(preset) == "table" and preset.spellIDs or { preset }
	for _, spellID in ipairs(spellIDs) do
		spellID = tonumber(spellID)
		if spellID and not defensiveAuraPresets.presetOnlySpellIDs[spellID] then defensiveAuraPresets.personalAndExternalSpellIDSet[spellID] = true end
	end
end

for _, preset in ipairs(defensiveAuraPresets.externals) do
	addPresetSpellIDsToSet(preset)
end
for _, classData in ipairs(defensiveAuraPresets.classes) do
	for _, preset in ipairs(classData.presets) do addPresetSpellIDsToSet(preset) end
end

addon.Aura.DefensiveAuraPresets = defensiveAuraPresets
