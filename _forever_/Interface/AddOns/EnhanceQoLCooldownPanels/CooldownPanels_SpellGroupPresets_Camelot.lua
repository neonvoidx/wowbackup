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
CooldownPanels.SpellGroups = CooldownPanels.SpellGroups or {}
local SpellGroups = CooldownPanels.SpellGroups

-- Forever cast IDs, checked against the reviewed 1.60.1.70755 spell data.
-- No specialization filters: the learned player/pet spellbook determines availability.
-- Rank aliases run from highest to lowest; one stable key preserves exclusions and order.
local function spell(spellID, classID, options)
	local member = options or {}
	member.key = member.key or "spell:" .. spellID
	member.spellID = spellID
	member.classID = classID
	member.canonicalSpellID = spellID
	return member
end

SpellGroups.Presets = {
	order = { "ROTATION", "ROTATIONAL_COOLDOWNS", "HEALING_COOLDOWNS", "ACTIVE_MITIGATION", "EXTERNAL_DEFENSIVES", "SUPPORT_COOLDOWNS", "KICKS", "MOVEMENT", "HARD_CC", "PERSONAL_DEFENSIVES", "OFFENSIVE_COOLDOWNS", "DISPELS", "BATTLE_REZ", "RACIALS", "POTIONS" },
	byID = {
		ROTATION = {
			id = "ROTATION",
			nameKey = "SpellGroupsPresetRotation",
			descriptionKey = "SpellGroupsPresetRotationDescription",
			icon = "Interface\\Icons\\ability_warrior_savageblow",
			members = {
				spell(78, 1), -- Heroic Strike
				spell(772, 1), -- Rend
				spell(845, 1), -- Cleave
				spell(7386, 1), -- Sunder Armor
				spell(1240193, 1), -- Slam
				spell(635, 2), -- Holy Light
				spell(679, 2), -- Holy Strike
				spell(19750, 2), -- Flash of Light
				spell(20154, 2), -- Seal of Righteousness
				spell(20375, 2), -- Seal of Command
				spell(1311649, 2), -- Seal of Fury
				spell(1978, 3), -- Serpent Sting
				spell(2973, 3), -- Raptor Strike
				spell(24118, 3), -- Lacerate
				spell(53, 4), -- Backstab
				spell(703, 4), -- Garrote
				spell(1752, 4), -- Sinister Strike
				spell(1943, 4), -- Rupture
				spell(2098, 4), -- Eviscerate
				spell(5171, 4), -- Slice and Dice
				spell(8647, 4), -- Expose Armor
				spell(8676, 4), -- Ambush
				spell(1310707, 4), -- Mutilate
				spell(139, 5), -- Renew
				spell(585, 5), -- Smite
				spell(589, 5), -- Shadow Word: Pain
				spell(596, 5), -- Prayer of Healing
				spell(2050, 5), -- Lesser Heal
				spell(2054, 5), -- Heal
				spell(2060, 5), -- Greater Heal
				spell(2061, 5), -- Flash Heal
				spell(14914, 5), -- Holy Fire
				spell(15237, 5), -- Holy Nova
				spell(15407, 5), -- Mind Flay
				spell(331, 7), -- Healing Wave
				spell(403, 7), -- Lightning Bolt
				spell(1064, 7), -- Chain Heal
				spell(3599, 7), -- Searing Totem
				spell(5394, 7), -- Healing Stream Totem
				spell(8004, 7), -- Lesser Healing Wave
				spell(8190, 7), -- Magma Totem
				spell(10, 8), -- Blizzard
				spell(116, 8), -- Frostbolt
				spell(133, 8), -- Fireball
				spell(1449, 8), -- Arcane Explosion
				spell(2120, 8), -- Flamestrike
				spell(2948, 8), -- Scorch
				spell(5143, 8), -- Arcane Missiles
				spell(11366, 8), -- Pyroblast
				spell(400574, 8), -- Arcane Blast
				spell(1326079, 8), -- Arcane Wrath
				spell(401502, 8), -- Frostfire Bolt
				spell(172, 9), -- Corruption
				spell(348, 9), -- Immolate
				spell(686, 9), -- Shadow Bolt
				spell(689, 9, { aliases = { 403689, 403688, 403687, 403686, 403685, 403677 } }), -- Drain Life
				spell(980, 9), -- Bane of Agony
				spell(1120, 9), -- Drain Soul
				spell(1949, 9), -- Hellfire
				spell(5676, 9), -- Searing Pain
				spell(5740, 9), -- Rain of Fire
				spell(18265, 9), -- Siphon Life
				spell(403835, 9), -- Shadow Cleave
				spell(412758, 9), -- Incinerate
				spell(440892, 9), -- Curse of the Elements
				spell(770, 11), -- Faerie Fire
				spell(774, 11), -- Rejuvenation
				spell(779, 11), -- Swipe
				spell(1079, 11), -- Rip
				spell(1082, 11), -- Claw
				spell(1822, 11), -- Rake
				spell(2912, 11), -- Starfire
				spell(5176, 11), -- Wrath
				spell(5185, 11), -- Healing Touch
				spell(5221, 11), -- Shred
				spell(5570, 11), -- Insect Swarm
				spell(6807, 11), -- Maul
				spell(8921, 11), -- Moonfire
				spell(8936, 11), -- Regrowth
				spell(1328618, 11, { key = "spell:22568" }), -- Ferocious Bite
				spell(408120, 11), -- Wild Growth
				spell(1328617, 11, { key = "spell:414644" }), -- Lacerate
				spell(1454, 9), -- Life Tap
				spell(603, 9), -- Bane of Doom
				spell(1316697, 9), -- Wrack
				spell(1310703, 4), -- Venom
				spell(16511, 4), -- Hemorrhage
				spell(1310911, 2), -- Light's Vigil
				spell(5308, 1), -- Execute
			},
		},
		ROTATIONAL_COOLDOWNS = {
			id = "ROTATIONAL_COOLDOWNS",
			nameKey = "SpellGroupsPresetRotationalCooldowns",
			descriptionKey = "SpellGroupsPresetRotationalCooldownsDescription",
			icon = "Interface\\Icons\\ability_rogue_slicedice",
			members = {
				spell(5217, 11), -- Tiger's Fury
				spell(1310994, 2), -- Swift Judgement
				spell(6343, 1), -- Thunder Clap
				spell(6572, 1), -- Revenge
				spell(7384, 1), -- Overpower
				spell(12294, 1), -- Mortal Strike
				spell(23881, 1), -- Bloodthirst
				spell(23922, 1), -- Shield Slam
				spell(1680, 1), -- Whirlwind
				spell(879, 2, { aliases = { 415073, 415072, 415071, 415070, 415069, 415068 } }), -- Exorcism
				spell(2812, 2), -- Holy Wrath
				spell(24275, 2), -- Hammer of Wrath
				spell(26573, 2), -- Consecration
				spell(1311606, 2), -- Holy Shock
				spell(3044, 3), -- Arcane Shot
				spell(3674, 3), -- Black Arrow
				spell(13795, 3), -- Immolation Trap
				spell(13813, 3), -- Explosive Trap
				spell(19434, 3), -- Aimed Shot
				spell(1310687, 3), -- Sniper Shot
				spell(8092, 5), -- Mind Blast
				spell(401859, 5), -- Prayer of Mending
				spell(402174, 5), -- Penance
				spell(1309595, 5), -- Shadow Word: Death
				spell(421, 7), -- Chain Lightning
				spell(8050, 7), -- Flame Shock
				spell(8056, 7), -- Frost Shock
				spell(408341, 7), -- Fire Nova
				spell(408490, 7), -- Lava Burst
				spell(408521, 7), -- Riptide
				spell(120, 8), -- Cone of Cold
				spell(2136, 8), -- Fire Blast
				spell(11113, 8), -- Blast Wave
				spell(1312002, 8), -- Ice Lance
				spell(6353, 9), -- Soul Fire
				spell(17877, 9), -- Shadowburn
				spell(1293817, 9), -- Conflagrate
				spell(16914, 11), -- Hurricane
				spell(407995, 11), -- Primal Bite
				spell(20271, 2), -- Judgement
				spell(17364, 7), -- Stormstrike
				spell(2643, 3), -- Multi-Shot
				spell(1317257, 3), -- Strider Kick
				spell(1293241, 3), -- Summon Hawk
				spell(5229, 11), -- Enrage
			},
		},
		HEALING_COOLDOWNS = {
			id = "HEALING_COOLDOWNS",
			nameKey = "SpellGroupsPresetHealingCooldowns",
			descriptionKey = "SpellGroupsPresetHealingCooldownsDescription",
			icon = "Interface\\Icons\\spell_holy_guardianspirit",
			members = {
				spell(20216, 2), -- Divine Favor
				spell(1328548, 2), -- Oath of Light
				spell(14751, 5), -- Inner Focus
				spell(16188, 7), -- Nature's Swiftness
				spell(17116, 11), -- Nature's Swiftness
				spell(740, 11), -- Tranquility
				spell(724, 5), -- Lightwell
				spell(18562, 11), -- Swiftmend
			},
		},
		ACTIVE_MITIGATION = {
			id = "ACTIVE_MITIGATION",
			nameKey = "SpellGroupsPresetActiveMitigation",
			descriptionKey = "SpellGroupsPresetActiveMitigationDescription",
			icon = "Interface\\Icons\\ability_defend",
			members = {
				spell(2565, 1), -- Shield Block
				spell(20925, 2, { aliases = { 1239570, 20928, 20927 } }), -- Holy Shield
				spell(1311015, 2), -- Templar's Bulwark
			},
		},
		EXTERNAL_DEFENSIVES = {
			id = "EXTERNAL_DEFENSIVES",
			nameKey = "SpellGroupsPresetExternalDefensives",
			descriptionKey = "SpellGroupsPresetExternalDefensivesDescription",
			icon = "Interface\\Icons\\spell_holy_sealofprotection",
			members = {
				spell(633, 2, { aliases = { 10310, 2800 } }), -- Lay on Hands
				spell(1022, 2, { aliases = { 10278, 5599 } }), -- Blessing of Protection
				spell(17, 5, { aliases = { 10901, 10900, 10899, 10898, 6066, 6065, 3747, 600, 592 } }), -- Power Word: Shield
				spell(6940, 2), -- Blessing of Sacrifice
				spell(1044, 2), -- Blessing of Freedom
			},
		},
		SUPPORT_COOLDOWNS = {
			id = "SUPPORT_COOLDOWNS",
			nameKey = "SpellGroupsPresetSupportCooldowns",
			descriptionKey = "SpellGroupsPresetSupportCooldownsDescription",
			icon = "Interface\\Icons\\spell_nature_manaregentotem",
			members = {
				spell(10060, 5), -- Power Infusion
				spell(16190, 7, { aliases = { 1325256, 17359, 17354 } }), -- Mana Tide Totem
				spell(12051, 8), -- Evocation
				spell(29166, 11), -- Innervate
				spell(5675, 7), -- Mana Spring Totem
				spell(8075, 7), -- Strength of Earth Totem
				spell(8512, 7), -- Windfury Totem
				spell(8835, 7), -- Grace of Air Totem
				spell(2687, 1), -- Bloodrage
				spell(15286, 5), -- Vampiric Embrace
			},
		},
		KICKS = {
			id = "KICKS",
			nameKey = "SpellGroupsPresetKicks",
			descriptionKey = "SpellGroupsPresetKicksDescription",
			icon = "Interface\\Icons\\ability_kick",
			members = {
				spell(6552, 1, { aliases = { 6554 } }), -- Pummel
				spell(72, 1, { aliases = { 1672, 1671 } }), -- Shield Bash
				spell(425609, 2), -- Rebuke
				spell(1766, 4, { aliases = { 1769, 1768, 1767 } }), -- Kick
				spell(15487, 5), -- Silence
				spell(8042, 7, { aliases = { 10414, 10413, 10412, 8046, 8045, 8044 } }), -- Earth Shock
				spell(2139, 8), -- Counterspell
				spell(19244, 9, { pet = true, aliases = { 19647 } }), -- Spell Lock
				spell(16979, 11), -- Feral Charge (Bear)
			},
		},
		MOVEMENT = {
			id = "MOVEMENT",
			nameKey = "SpellGroupsPresetMovement",
			descriptionKey = "SpellGroupsPresetMovementDescription",
			icon = "Interface\\Icons\\ability_rogue_sprint",
			members = {
				spell(100, 1, { aliases = { 11578, 6178 } }), -- Charge
				spell(20252, 1, { aliases = { 20617, 20616 } }), -- Intercept
				spell(5118, 3), -- Aspect of the Cheetah
				spell(13159, 3), -- Aspect of the Pack
				spell(2983, 4, { aliases = { 11305, 8696 } }), -- Sprint
				spell(2645, 7), -- Ghost Wolf
				spell(1953, 8), -- Blink
				spell(1850, 11, { aliases = { 9821 } }), -- Dash
				spell(414924, 11), -- Feral Charge (Cat)
			},
		},
		HARD_CC = {
			id = "HARD_CC",
			nameKey = "SpellGroupsPresetHardCC",
			descriptionKey = "SpellGroupsPresetHardCCDescription",
			icon = "Interface\\Icons\\spell_nature_polymorph",
			members = {
				spell(5246, 1), -- Intimidating Shout
				spell(12809, 1), -- Concussion Blow
				spell(853, 2, { aliases = { 10308, 5589, 5588 } }), -- Hammer of Justice
				spell(2878, 2, { aliases = { 10326, 5627 } }), -- Turn Undead
				spell(20066, 2), -- Repentance
				spell(1499, 3, { aliases = { 14311, 14310 } }), -- Freezing Trap
				spell(19577, 3), -- Intimidation
				spell(19503, 3), -- Scatter Shot
				spell(1513, 3, { aliases = { 14327, 14326 } }), -- Scare Beast
				spell(408, 4, { aliases = { 8643 } }), -- Kidney Shot
				spell(1833, 4), -- Cheap Shot
				spell(1776, 4, { aliases = { 11286, 11285, 8629, 1777 } }), -- Gouge
				spell(2094, 4), -- Blind
				spell(6770, 4, { aliases = { 11297, 2070 } }), -- Sap
				spell(8122, 5, { aliases = { 10890, 10888, 8124 } }), -- Psychic Scream
				spell(605, 5, { aliases = { 10912, 10911 } }), -- Mind Control
				spell(9484, 5, { aliases = { 10955, 9485 } }), -- Shackle Undead
				spell(1277455, 5), -- Confounding Flash
				spell(118, 8, { aliases = { 12826, 12825, 12824 } }), -- Polymorph
				spell(5782, 9, { aliases = { 6215, 6213 } }), -- Fear
				spell(6789, 9, { aliases = { 17926, 17925 } }), -- Death Coil
				spell(6358, 9, { pet = true }), -- Seduction
				spell(710, 9, { aliases = { 18647 } }), -- Banish
				spell(5484, 9, { aliases = { 17928 } }), -- Howl of Terror
				spell(5211, 11, { aliases = { 8983, 6798 } }), -- Bash
				spell(2637, 11, { aliases = { 18658, 18657 } }), -- Hibernate
			},
		},
		PERSONAL_DEFENSIVES = {
			id = "PERSONAL_DEFENSIVES",
			nameKey = "SpellGroupsPresetPersonalDefensives",
			descriptionKey = "SpellGroupsPresetPersonalDefensivesDescription",
			icon = "Interface\\Icons\\ability_warrior_shieldwall",
			members = {
				spell(871, 1), -- Shield Wall
				spell(12975, 1), -- Last Stand
				spell(18499, 1), -- Berserker Rage
				spell(642, 2, { aliases = { 1020 } }), -- Divine Shield
				spell(498, 2, { aliases = { 5573 } }), -- Divine Protection
				spell(19263, 3), -- Deterrence
				spell(5384, 3), -- Feign Death
				spell(5277, 4), -- Evasion
				spell(1856, 4), -- Vanish
				spell(14278, 4), -- Ghostly Strike
				spell(1277462, 5), -- Contingency Plan
				spell(11958, 8), -- Ice Block
				spell(11426, 8, { aliases = { 13033, 13032, 13031 } }), -- Ice Barrier
				spell(1463, 8, { aliases = { 10193, 10192, 10191, 8495, 8494 } }), -- Mana Shield
				spell(543, 8, { aliases = { 10225, 10223, 8458, 8457 } }), -- Fire Ward
				spell(6143, 8, { aliases = { 28609, 10177, 8462, 8461 } }), -- Frost Ward
				spell(6229, 9, { aliases = { 28610, 11740, 11739 } }), -- Shadow Ward
				spell(7812, 9, { pet = true, aliases = { 19443, 19442, 19441, 19440, 19438 } }), -- Sacrifice
				spell(22812, 11), -- Barkskin
				spell(22842, 11), -- Frenzied Regeneration
			},
		},
		OFFENSIVE_COOLDOWNS = {
			id = "OFFENSIVE_COOLDOWNS",
			nameKey = "SpellGroupsPresetOffensiveCooldowns",
			descriptionKey = "SpellGroupsPresetOffensiveCooldownsDescription",
			icon = "Interface\\Icons\\warrior_talent_icon_innerrage",
			members = {
				spell(1719, 1), -- Recklessness
				spell(20230, 1), -- Retaliation
				spell(12292, 1), -- Sweeping Strikes
				spell(12328, 1), -- Death Wish
				spell(3045, 3), -- Rapid Fire
				spell(19574, 3), -- Bestial Wrath
				spell(13750, 4), -- Adrenaline Rush
				spell(13877, 4), -- Blade Flurry
				spell(14177, 4), -- Cold Blood
				spell(14185, 4), -- Preparation
				spell(14183, 4), -- Premeditation
				spell(425336, 7), -- Rage of the Farseer
				spell(12042, 8), -- Arcane Power
				spell(12043, 8), -- Presence of Mind
				spell(12472, 8), -- Cold Snap
				spell(11129, 8), -- Combustion
				spell(18708, 9), -- Fel Domination
				spell(18288, 9), -- Amplify Curse
				spell(1122, 9), -- Inferno
				spell(18540, 9), -- Ritual of Doom
				spell(417141, 11), -- Berserk
				spell(16166, 7), -- Elemental Mastery
				spell(18788, 9), -- Demonic Sacrifice
			},
		},
		DISPELS = {
			id = "DISPELS",
			nameKey = "SpellGroupsPresetDispels",
			descriptionKey = "SpellGroupsPresetDispelsDescription",
			icon = "Interface\\Icons\\spell_holy_dispelmagic",
			members = {
				spell(4987, 2, { dispelKind = "FRIENDLY" }), -- Cleanse
				spell(1152, 2, { dispelKind = "FRIENDLY" }), -- Purify
				spell(19801, 3, { dispelKind = "OFFENSIVE" }), -- Tranquilizing Shot
				spell(527, 5, { dispelKind = "BOTH", aliases = { 988 } }), -- Dispel Magic
				spell(528, 5, { dispelKind = "FRIENDLY" }), -- Cure Disease
				spell(552, 5, { dispelKind = "FRIENDLY" }), -- Abolish Disease
				spell(526, 7, { dispelKind = "FRIENDLY" }), -- Cure Poison
				spell(2870, 7, { dispelKind = "FRIENDLY" }), -- Cure Disease
				spell(8166, 7, { dispelKind = "FRIENDLY" }), -- Poison Cleansing Totem
				spell(8170, 7, { dispelKind = "FRIENDLY" }), -- Disease Cleansing Totem
				spell(8143, 7, { dispelKind = "FRIENDLY" }), -- Tremor Totem
				spell(370, 7, { dispelKind = "OFFENSIVE", aliases = { 8012 } }), -- Purge
				spell(475, 8, { dispelKind = "FRIENDLY" }), -- Remove Lesser Curse
				spell(19505, 9, { pet = true, dispelKind = "BOTH", aliases = { 19736, 19734, 19731 } }), -- Devour Magic
				spell(2782, 11, { dispelKind = "FRIENDLY" }), -- Remove Curse
				spell(8946, 11, { dispelKind = "FRIENDLY" }), -- Cure Poison
				spell(2893, 11, { dispelKind = "FRIENDLY" }), -- Abolish Poison
			},
		},
		BATTLE_REZ = {
			id = "BATTLE_REZ",
			nameKey = "SpellGroupsPresetBattleRez",
			descriptionKey = "SpellGroupsPresetBattleRezDescription",
			icon = "Interface\\Icons\\spell_nature_reincarnation",
			members = {
				spell(20484, 11, { aliases = { 20748, 20747, 20742, 20739 } }), -- Rebirth
			},
		},
		RACIALS = {
			id = "RACIALS",
			nameKey = "CooldownPanelAddRacials",
			descriptionKey = "SpellGroupsPresetRacialsDescription",
			icon = "Interface\\Icons\\racial_orc_berserkerstrength",
			members = {
				spell(20572, nil), -- Blood Fury
				spell(1299026, nil), -- Shatter Curse
				spell(20554, nil), -- Berserking
				spell(1260270, nil), -- Rapid Regeneration
				spell(7744, nil), -- Will of the Forsaken
				spell(20577, nil), -- Cannibalize
				spell(20549, nil), -- War Stomp
				spell(20594, nil), -- Stoneform
				spell(20600, nil), -- Perception
				spell(1259718, nil), -- Will to Survive
				spell(20580, nil), -- Shadowmeld
				spell(1259799, nil), -- Elune's Light
				spell(20589, nil), -- Escape Artist
				spell(1259812, nil, { aliases = { 1259813, 1259817, 1259821, 1259823 } }), -- Eureka!
				spell(1259416, nil), -- Walk on Air
				spell(1259686, nil), -- Skysight
				spell(1259705, nil), -- Read Ley Line
				spell(13908, 5, { aliases = { 19243, 19242, 19241, 19240, 19238, 19236 } }), -- Desperate Prayer
				spell(2651, 5), -- Elune's Grace
				spell(2652, 5), -- Touch of Weakness
				spell(2944, 5), -- Devouring Plague
				spell(9035, 5), -- Hex of Weakness
				spell(10797, 5), -- Starshards
				spell(13896, 5), -- Feedback
				spell(18137, 5), -- Shadowguard
				spell(6346, 5), -- Fear Ward
			},
		},
		POTIONS = {
			id = "POTIONS",
			nameKey = "CategoryPotions",
			descriptionKey = "SpellGroupsPresetPotionsClassicDescription",
			icon = "Interface\\Icons\\inv_potion_54",
			members = {
			},
		},
	},
}

-- Classic consumables use distinct item IDs instead of Retail quality variants.
-- Instant recovery potions have no persistent aura but remain useful cooldown entries.
do
	local members = SpellGroups.Presets.byID.POTIONS.members
	for _, itemID in ipairs(CooldownPanels.foreverPotionItemIDs or {}) do
		members[#members + 1] = { key = "item:" .. itemID, type = "ITEM", itemID = itemID }
	end
end
