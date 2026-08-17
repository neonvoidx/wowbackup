local parentAddonName = "EnhanceQoL"
local addonName, addon = ...

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}

-- Shared defensive aura catalog used by Group Frames and Cooldown Panels.
-- Disabled entries are omitted and enabled alternate IDs share one preset
-- record with their primary.
-- Keep class sections alphabetically ordered and preset records numerically
-- ordered by primarySpellID. These are aura IDs unless a comment says otherwise.
local defensiveAuraPresets = {
	-- Preset spell records that are not themselves aura IDs. Keep them in the
	-- catalog for source fidelity, but never add them to the Group Frames filter.
	presetOnlySpellIDs = {
		-- Monk
		[115203] = true, -- Fortifying Brew (cast/talent ID; aura is 120954)
	},
	externals = {
		-- Druid
		{ primarySpellID = 102342, spellIDs = { 102342 } }, -- Ironbark

		-- Evoker
		{ primarySpellID = 357170, spellIDs = { 357170 } }, -- Time Dilation

		-- Hunter
		{ primarySpellID = 53480, spellIDs = { 53480 } }, -- Roar of Sacrifice

		-- Monk
		{ primarySpellID = 116849, spellIDs = { 116849 } }, -- Life Cocoon

		-- Paladin
		{
			primarySpellID = 1022,
			spellIDs = {
				1022, -- Blessing of Protection
				1309794, -- Blessing of Protection (12.1 alternate aura ID)
			},
		},
		{ primarySpellID = 6940, spellIDs = { 6940 } }, -- Blessing of Sacrifice
		{ primarySpellID = 204018, spellIDs = { 204018 } }, -- Blessing of Spellwarding
		{ primarySpellID = 387804, spellIDs = { 387804 } }, -- Echoing Protection

		-- Priest
		{ primarySpellID = 33206, spellIDs = { 33206 } }, -- Pain Suppression
		{ primarySpellID = 47788, spellIDs = { 47788 } }, -- Guardian Spirit
	},
	raidArea = {
		-- Death Knight
		145629, -- Anti-Magic Zone

		-- Demon Hunter
		209426, -- Darkness

		-- Evoker
		374227, -- Zephyr

		-- Mage
		414661, -- Ice Barrier
		414662, -- Blazing Barrier
		414663, -- Prismatic Barrier

		-- Paladin
		31821, -- Aura Mastery

		-- Priest
		81782, -- Power Word: Barrier

		-- Shaman
		207498, -- Ancestral Protection
		325174, -- Spirit Link Totem

		-- Warrior
		97463, -- Rallying Cry
	},
	classes = {
		{
			classTag = "DEATHKNIGHT",
			presets = {
				{
					primarySpellID = 48707,
					spellIDs = {
						48707, -- Anti-Magic Shell
						444741, -- Anti-Magic Shell (alternate aura ID)
					},
				},
				{ primarySpellID = 48792, spellIDs = { 48792 } }, -- Icebound Fortitude
				{ primarySpellID = 55233, spellIDs = { 55233 } }, -- Vampiric Blood
				{ primarySpellID = 101568, spellIDs = { 101568 } }, -- Dark Succor
			},
		},
		{
			classTag = "DEMONHUNTER",
			presets = {
				{ primarySpellID = 187827, spellIDs = { 187827 } }, -- Metamorphosis
				{ primarySpellID = 207771, spellIDs = { 207771 } }, -- Fiery Brand (helpful self aura and harmful target aura)
				{ primarySpellID = 212800, spellIDs = { 212800 } }, -- Blur
			},
		},
		{
			classTag = "DRUID",
			presets = {
				{ primarySpellID = 22812, spellIDs = { 22812 } }, -- Barkskin
				{ primarySpellID = 22842, spellIDs = { 22842 } }, -- Frenzied Regeneration
				{ primarySpellID = 61336, spellIDs = { 61336 } }, -- Survival Instincts
				{ primarySpellID = 1261872, spellIDs = { 1261872 } }, -- Heart of the Wild
			},
		},
		{
			classTag = "EVOKER",
			presets = {
				{ primarySpellID = 363916, spellIDs = { 363916 } }, -- Obsidian Scales
				{ primarySpellID = 374349, spellIDs = { 374349 } }, -- Renewing Blaze
				{ primarySpellID = 404381, spellIDs = { 404381 } }, -- Defy Fate
			},
		},
		{
			classTag = "HUNTER",
			presets = {
				{ primarySpellID = 186265, spellIDs = { 186265 } }, -- Aspect of the Turtle
				{ primarySpellID = 264735, spellIDs = { 264735 } }, -- Survival of the Fittest
			},
		},
		{
			classTag = "MAGE",
			presets = {
				{ primarySpellID = 45438, spellIDs = { 45438 } }, -- Ice Block
				{ primarySpellID = 342246, spellIDs = { 342246 } }, -- Alter Time
				{ primarySpellID = 414658, spellIDs = { 414658 } }, -- Ice Cold
				{ primarySpellID = 449336, spellIDs = { 449336 } }, -- Merely a Setback
				{ primarySpellID = 1309793, spellIDs = { 1309793 } }, -- Amplified Refraction
			},
		},
		{
			classTag = "MONK",
			presets = {
				{
					primarySpellID = 115203,
					spellIDs = {
						115203, -- Fortifying Brew (cast/talent ID; aura is 120954)
						120954, -- Fortifying Brew (aura; cast/talent spell 115203)
					},
				},
				{ primarySpellID = 122783, spellIDs = { 122783 } }, -- Diffuse Magic
				{ primarySpellID = 125174, spellIDs = { 125174 } }, -- Touch of Karma
				{ primarySpellID = 132578, spellIDs = { 132578 } }, -- Invoke Niuzao, the Black Ox
				{ primarySpellID = 322507, spellIDs = { 322507 } }, -- Celestial Brew
				{ primarySpellID = 1241059, spellIDs = { 1241059 } }, -- Celestial Infusion
			},
		},
		{
			classTag = "PALADIN",
			presets = {
				{
					primarySpellID = 498,
					spellIDs = {
						498, -- Divine Protection
						403876, -- Divine Protection (alternate aura ID)
					},
				},
				{ primarySpellID = 642, spellIDs = { 642 } }, -- Divine Shield
				{ primarySpellID = 31850, spellIDs = { 31850 } }, -- Ardent Defender
				{ primarySpellID = 86659, spellIDs = { 86659 } }, -- Guardian of Ancient Kings
			},
		},
		{
			classTag = "PRIEST",
			presets = {
				{ primarySpellID = 586, spellIDs = { 586 } }, -- Fade
				{ primarySpellID = 19236, spellIDs = { 19236 } }, -- Desperate Prayer
				{ primarySpellID = 27827, spellIDs = { 27827 } }, -- Spirit of Redemption
				{ primarySpellID = 47585, spellIDs = { 47585 } }, -- Dispersion
				{ primarySpellID = 193065, spellIDs = { 193065 } }, -- Protective Light
			},
		},
		{
			classTag = "ROGUE",
			presets = {
				{ primarySpellID = 1966, spellIDs = { 1966 } }, -- Feint
				{ primarySpellID = 5277, spellIDs = { 5277 } }, -- Evasion
				{ primarySpellID = 31224, spellIDs = { 31224 } }, -- Cloak of Shadows
				{ primarySpellID = 185311, spellIDs = { 185311 } }, -- Crimson Vial
			},
		},
		{
			classTag = "SHAMAN",
			presets = {
				{ primarySpellID = 108271, spellIDs = { 108271 } }, -- Astral Shift
				{ primarySpellID = 260881, spellIDs = { 260881 } }, -- Spirit Wolf
			},
		},
		{
			classTag = "WARLOCK",
			presets = {
				{ primarySpellID = 104773, spellIDs = { 104773 } }, -- Unending Resolve
				{ primarySpellID = 108416, spellIDs = { 108416 } }, -- Dark Pact
				{ primarySpellID = 132413, spellIDs = { 132413 } }, -- Shadow Bulwark
				{ primarySpellID = 387636, spellIDs = { 387636 } }, -- Soulburn: Healthstone
				{ primarySpellID = 389614, spellIDs = { 389614 } }, -- Abyss Walker
			},
		},
		{
			classTag = "WARRIOR",
			presets = {
				{ primarySpellID = 871, spellIDs = { 871 } }, -- Shield Wall
				{ primarySpellID = 118038, spellIDs = { 118038 } }, -- Die by the Sword
				{ primarySpellID = 147833, spellIDs = { 147833 } }, -- Intervene
				{ primarySpellID = 184364, spellIDs = { 184364 } }, -- Enraged Regeneration
				{
					primarySpellID = 190456,
					spellIDs = {
						190456, -- Ignore Pain
						1277297, -- Ignore Pain (alternate aura ID)
					},
				},
				{ primarySpellID = 385391, spellIDs = { 385391 } }, -- Spell Reflection
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
