-- Forever consumables and self-buff trinkets checked against item-use links and
-- aura tooltips from the Forever database. Instant heals/restores are cooldown
-- entries only. Pet buffs and hidden/indirect item effects need a confirmed aura
-- mapping before they can be added to the player-aura preset.
local parentAddonName = "EnhanceQoL"
local addon = select(2, ...)

if _G[parentAddonName] then
	addon = _G[parentAddonName]
else
	error(parentAddonName .. " is not loaded")
end

addon.Aura = addon.Aura or {}
addon.Aura.CooldownPanels = addon.Aura.CooldownPanels or {}
local CooldownPanels = addon.Aura.CooldownPanels

CooldownPanels.foreverPotionItemIDs = { 2459, 3387, 3823, 4623, 5633, 5634, 6372, 9036, 9172, 13442, 13444, 13446, 13455, 13456, 13457, 13458, 13459, 13460, 13461, 13462, 18253, 20008 }

CooldownPanels.generatedAuraPresetCatalog = {
	build = "1.60.1",
	trinkets = {
		{
			key = "TRINKET_UPTIME",
			spellIDs = { 23271, 23721, 23723, 23724, 23725, 23726, 23733, 23734, 23780, 25891, 28773, 28777, 28779, 28780, 29602 },
			primarySpellID = 23271,
			labelKey = "CooldownPanelAuraPresetTrinketUptime",
			iconSpellID = 23271,
			maxFrameCount = 2,
			sourceItemIDs = { 18820, 19336, 19339, 19340, 19341, 19342, 19343, 19344, 19345, 21180, 23040, 23041, 23046, 23047, 23570 },
			spellIDsByItemID = {
				[18820] = { 23271 }, -- Talisman of Ephemeral Power
				[19336] = { 23721 }, -- Arcane Infused Gem
				[19339] = { 23723 }, -- Mind Quickening Gem
				[19340] = { 23724 }, -- Rune of Metamorphosis
				[19341] = { 23725 }, -- Lifegiving Gem
				[19342] = { 23726 }, -- Venomous Totem
				[19343] = { 23733 }, -- Scrolls of Blinding Light
				[19344] = { 23734 }, -- Natural Alignment Crystal
				[19345] = { 23780 }, -- Aegis of Preservation
				[21180] = { 25891 }, -- Earthstrike
				[23040] = { 28773 }, -- Glyph of Deflection
				[23041] = { 28777 }, -- Slayer's Crest
				[23046] = { 28779 }, -- The Restrained Essence of Sapphiron
				[23047] = { 28780 }, -- Eye of the Dead
				[23570] = { 29602 }, -- Jom Gabbar
			},
			spellCategories = {
				[23271] = { activation = { "ON_USE" }, effects = { "STATS" } }, -- Ephemeral Power
				[23721] = { activation = { "ON_USE" }, effects = { "DAMAGE" } }, -- Arcane Infused
				[23723] = { activation = { "ON_USE" }, effects = { "STATS" } }, -- Mind Quickening
				[23724] = { activation = { "ON_USE" }, effects = { "UTILITY" } }, -- Metamorphosis Rune
				[23725] = { activation = { "ON_USE" }, effects = { "HEALING", "STATS" } }, -- Gift of Life
				[23726] = { activation = { "ON_USE" }, effects = { "STATS" } }, -- Venomous Totem
				[23733] = { activation = { "ON_USE" }, effects = { "STATS" } }, -- Blinding Light
				[23734] = { activation = { "ON_USE" }, effects = { "STATS" } }, -- Nature Aligned
				[23780] = { activation = { "ON_USE" }, effects = { "HEALING", "STATS" } }, -- Aegis of Preservation
				[25891] = { activation = { "ON_USE" }, effects = { "STATS" } }, -- Earthstrike
				[28773] = { activation = { "ON_USE" }, effects = { "STATS" } }, -- Glyph of Deflection
				[28777] = { activation = { "ON_USE" }, effects = { "STATS" } }, -- Slayer's Crest
				[28779] = { activation = { "ON_USE" }, effects = { "STATS" } }, -- Essence of Sapphiron
				[28780] = { activation = { "ON_USE" }, effects = { "HEALING" } }, -- The Eye of the Dead
				[29602] = { activation = { "ON_USE" }, effects = { "STATS" } }, -- Jom Gabbar
			},
		},
	},
	potions = {
		{
			key = "COMBAT_POTION",
			spellIDs = { 2379, 3169, 3680, 4941, 6615, 7840, 11364, 11392, 17528, 17540, 17544, 17543, 17546, 17548, 17545, 17549, 24364 },
			primarySpellID = 2379,
			labelKey = "CooldownPanelAuraPresetCombatPotion",
			iconSpellID = 2379,
			maxFrameCount = 2,
			sourceItemIDs = { 2459, 3387, 3823, 4623, 5634, 6372, 9036, 9172, 13442, 13455, 13456, 13457, 13458, 13459, 13460, 13461, 20008 },
			spellIDsByItemID = {
				[2459] = { 2379 }, -- Swiftness Potion
				[3387] = { 3169 }, -- Limited Invulnerability Potion
				[3823] = { 3680 }, -- Lesser Invisibility Potion
				[4623] = { 4941 }, -- Lesser Stoneshield Potion
				[5634] = { 6615 }, -- Free Action Potion
				[6372] = { 7840 }, -- Swim Speed Potion
				[9036] = { 11364 }, -- Magic Resistance Potion
				[9172] = { 11392 }, -- Invisibility Potion
				[13442] = { 17528 }, -- Mighty Rage Potion
				[13455] = { 17540 }, -- Greater Stoneshield Potion
				[13456] = { 17544 }, -- Greater Frost Protection Potion
				[13457] = { 17543 }, -- Greater Fire Protection Potion
				[13458] = { 17546 }, -- Greater Nature Protection Potion
				[13459] = { 17548 }, -- Greater Shadow Protection Potion
				[13460] = { 17545 }, -- Greater Holy Protection Potion
				[13461] = { 17549 }, -- Greater Arcane Protection Potion
				[20008] = { 24364 }, -- Living Action Potion
			},
			spellCategories = {
				[2379] = { activation = { "ON_USE" }, effects = { "UTILITY" } }, -- Speed
				[3169] = { activation = { "ON_USE" }, effects = { "UTILITY" } }, -- Invulnerability
				[3680] = { activation = { "ON_USE" }, effects = { "UTILITY" } }, -- Lesser Invisibility
				[4941] = { activation = { "ON_USE" }, effects = { "STATS" } }, -- Stoneshield
				[6615] = { activation = { "ON_USE" }, effects = { "UTILITY" } }, -- Free Action
				[7840] = { activation = { "ON_USE" }, effects = { "UTILITY" } }, -- Swim Speed
				[11364] = { activation = { "ON_USE" }, effects = { "STATS" } }, -- Resistance
				[11392] = { activation = { "ON_USE" }, effects = { "UTILITY" } }, -- Invisibility
				[17528] = { activation = { "ON_USE" }, effects = { "STATS" } }, -- Mighty Rage
				[17540] = { activation = { "ON_USE" }, effects = { "STATS" } }, -- Greater Stoneshield
				[17544] = { activation = { "ON_USE" }, effects = { "ABSORB" } }, -- Frost Protection
				[17543] = { activation = { "ON_USE" }, effects = { "ABSORB" } }, -- Fire Protection
				[17546] = { activation = { "ON_USE" }, effects = { "ABSORB" } }, -- Nature Protection
				[17548] = { activation = { "ON_USE" }, effects = { "ABSORB" } }, -- Shadow Protection
				[17545] = { activation = { "ON_USE" }, effects = { "ABSORB" } }, -- Holy Protection
				[17549] = { activation = { "ON_USE" }, effects = { "ABSORB" } }, -- Arcane Protection
				[24364] = { activation = { "ON_USE" }, effects = { "UTILITY" } }, -- Living Free Action
			},
		},
	},
}
