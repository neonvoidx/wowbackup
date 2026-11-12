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

-- Cast IDs only. Variants of one ability share its stable primary key so preset
-- updates and talent changes retain member exclusions, order, and panel settings.
-- Availability is resolved from the current spellbook; cooldown state is not read.
local function spell(spellID, classID, options)
	local member = options or {}
	member.key = "spell:" .. spellID
	member.spellID = spellID
	member.classID = classID
	member.canonicalSpellID = spellID
	return member
end

SpellGroups.Presets = {
	order = { "KICKS", "MOVEMENT", "HARD_CC", "PERSONAL_DEFENSIVES", "ACTIVE_MITIGATION", "EXTERNAL_DEFENSIVES", "ROTATION", "ROTATIONAL_COOLDOWNS", "OFFENSIVE_COOLDOWNS", "HEALING_COOLDOWNS", "SUPPORT_COOLDOWNS", "DISPELS", "BATTLE_REZ", "RACIALS", "POTIONS" },
	byID = {
		KICKS = {
			id = "KICKS",
			nameKey = "SpellGroupsPresetKicks",
			descriptionKey = "SpellGroupsPresetKicksDescription",
			icon = "Interface\\Icons\\ability_kick",
			members = {
				-- Warrior
				spell(6552, 1), -- Pummel
				spell(386071, 1, { specIDs = { 73 } }), -- Disrupting Shout
				-- Paladin
				spell(96231, 2, { specIDs = { 66, 70 } }), -- Rebuke
				spell(31935, 2, { specIDs = { 66 } }), -- Avenger's Shield
				-- Hunter
				spell(147362, 3, { specIDs = { 253, 254 } }), -- Counter Shot
				spell(187707, 3, { specIDs = { 255 } }), -- Muzzle
				-- Rogue
				spell(1766, 4), -- Kick
				-- Priest
				spell(15487, 5, { specIDs = { 258 } }), -- Silence
				-- Death Knight
				spell(47528, 6), -- Mind Freeze
				-- Shaman
				spell(57994, 7), -- Wind Shear
				-- Mage
				spell(2139, 8), -- Counterspell
				-- Warlock
				spell(19647, 9, { aliases = { 119910, 132409 } }), -- Spell Lock
				spell(89766, 9, { aliases = { 119914 }, specIDs = { 266 }, pet = true }), -- Axe Toss
				-- Monk
				spell(116705, 10, { specIDs = { 268, 269 } }), -- Spear Hand Strike
				-- Druid
				spell(106839, 11, { specIDs = { 103, 104 } }), -- Skull Bash
				spell(78675, 11, { specIDs = { 102 } }), -- Solar Beam
				-- Demon Hunter
				spell(183752, 12), -- Disrupt
				spell(202137, 12, { specIDs = { 581 } }), -- Sigil of Silence
				-- Evoker
				spell(351338, 13, { specIDs = { 1467, 1473 } }), -- Quell
			},
		},
		MOVEMENT = {
			id = "MOVEMENT",
			nameKey = "SpellGroupsPresetMovement",
			descriptionKey = "SpellGroupsPresetMovementDescription",
			icon = "Interface\\Icons\\ability_rogue_sprint",
			members = {
				-- Warrior
				spell(100, 1), -- Charge
				spell(6544, 1), -- Heroic Leap
				-- Paladin
				spell(190784, 2), -- Divine Steed
				-- Hunter
				spell(186257, 3), -- Aspect of the Cheetah
				-- Rogue
				spell(2983, 4), -- Sprint
				spell(195457, 4, { specIDs = { 260 } }), -- Grappling Hook
				-- Priest
				spell(121536, 5), -- Angelic Feather
				-- Death Knight
				spell(48265, 6, { aliases = { 444347 } }), -- Death's Advance
				spell(212552, 6), -- Wraith Walk
				-- Shaman
				spell(192063, 7), -- Gust of Wind
				spell(58875, 7), -- Spirit Walk
				spell(192077, 7), -- Wind Rush Totem
				-- Mage
				spell(1953, 8, { aliases = { 212653 } }), -- Blink
				-- Warlock
				spell(48020, 9), -- Demonic Circle: Teleport
				spell(111400, 9), -- Burning Rush
				spell(111771, 9), -- Demonic Gateway
				-- Monk
				spell(109132, 10, { aliases = { 115008 } }), -- Roll
				spell(101545, 10, { specIDs = { 269 } }), -- Flying Serpent Kick
				spell(119996, 10), -- Transcendence: Transfer
				spell(116841, 10), -- Tiger's Lust
				-- Druid
				spell(1850, 11, { aliases = { 252216 } }), -- Dash
				spell(102401, 11, { aliases = { 49376, 16979, 102383, 102416, 102417 } }), -- Wild Charge
				spell(106898, 11), -- Stampeding Roar
				-- Demon Hunter
				spell(195072, 12, { specIDs = { 577 } }), -- Fel Rush
				spell(198793, 12, { specIDs = { 577 } }), -- Vengeful Retreat
				spell(189110, 12, { specIDs = { 581 } }), -- Infernal Strike
				spell(1234796, 12, { specIDs = { 1480 } }), -- Shift
				-- Evoker
				spell(358267, 13), -- Hover
			},
		},
		HARD_CC = {
			id = "HARD_CC",
			nameKey = "SpellGroupsPresetHardCC",
			descriptionKey = "SpellGroupsPresetHardCCDescription",
			icon = "Interface\\Icons\\spell_nature_polymorph",
			members = {
				-- Warrior
				spell(107570, 1), -- Storm Bolt
				spell(5246, 1), -- Intimidating Shout
				spell(46968, 1), -- Shockwave
				spell(385952, 1, { specIDs = { 73 } }), -- Shield Charge
				-- Paladin
				spell(853, 2), -- Hammer of Justice
				spell(115750, 2), -- Blinding Light
				spell(10326, 2), -- Turn Evil
				-- Hunter
				spell(187650, 3), -- Freezing Trap
				spell(19577, 3, { aliases = { 474421 } }), -- Intimidation
				spell(109248, 3), -- Binding Shot
				spell(213691, 3), -- Scatter Shot
				-- Rogue
				spell(408, 4), -- Kidney Shot
				spell(1833, 4), -- Cheap Shot
				spell(1776, 4), -- Gouge
				spell(2094, 4), -- Blind
				spell(6770, 4), -- Sap
				-- Priest
				spell(8122, 5), -- Psychic Scream
				spell(605, 5, { aliases = { 205364 } }), -- Mind Control
				spell(88625, 5, { specIDs = { 257 } }), -- Holy Word: Chastise
				spell(9484, 5), -- Shackle Horror
				-- Death Knight
				spell(221562, 6), -- Asphyxiate
				spell(207167, 6), -- Blinding Sleet
				spell(111673, 6), -- Control Undead
				-- Shaman
				spell(192058, 7), -- Capacitor Totem
				spell(51514, 7), -- Hex
				-- Mage
				spell(118, 8), -- Polymorph
				spell(31661, 8), -- Dragon's Breath
				-- Warlock
				spell(5782, 9), -- Fear
				spell(30283, 9), -- Shadowfury
				spell(6789, 9), -- Mortal Coil
				spell(6358, 9, { aliases = { 119909 }, pet = true }), -- Seduction
				spell(710, 9), -- Banish
				-- Monk
				spell(115078, 10), -- Paralysis
				spell(119381, 10), -- Leg Sweep
				-- Druid
				spell(5211, 11), -- Mighty Bash
				spell(22570, 11), -- Maim
				spell(99, 11), -- Incapacitating Roar
				spell(33786, 11), -- Cyclone
				spell(2637, 11), -- Hibernate
				-- Demon Hunter
				spell(179057, 12, { aliases = { 1234195 } }), -- Chaos Nova
				spell(217832, 12), -- Imprison
				spell(207684, 12), -- Sigil of Misery
				-- Evoker
				spell(360806, 13), -- Sleep Walk
			},
		},
		PERSONAL_DEFENSIVES = {
			id = "PERSONAL_DEFENSIVES",
			nameKey = "SpellGroupsPresetPersonalDefensives",
			descriptionKey = "SpellGroupsPresetPersonalDefensivesDescription",
			icon = "Interface\\Icons\\ability_warrior_shieldwall",
			members = {
				spell(49028, 6, { specIDs = { 250 } }), -- Dancing Rune Weapon
				-- Warrior
				spell(871, 1, { specIDs = { 73 } }), -- Shield Wall
				spell(184364, 1, { specIDs = { 72 } }), -- Enraged Regeneration
				spell(118038, 1, { specIDs = { 71 } }), -- Die by the Sword
				spell(23920, 1), -- Spell Reflection
				-- Paladin
				spell(642, 2), -- Divine Shield
				spell(498, 2, { aliases = { 403876 }, specIDs = { 65, 70 } }), -- Divine Protection
				spell(31850, 2, { specIDs = { 66 } }), -- Ardent Defender
				spell(86659, 2, { specIDs = { 66 } }), -- Guardian of Ancient Kings
				spell(389539, 2, { specIDs = { 66 } }), -- Sentinel
				-- Hunter
				spell(186265, 3), -- Aspect of the Turtle
				spell(264735, 3), -- Survival of the Fittest
				-- Rogue
				spell(31224, 4), -- Cloak of Shadows
				spell(5277, 4), -- Evasion
				spell(1966, 4), -- Feint
				-- Priest
				spell(19236, 5), -- Desperate Prayer
				spell(47585, 5, { specIDs = { 258 } }), -- Dispersion
				-- Death Knight
				spell(48707, 6), -- Anti-Magic Shell
				spell(48792, 6), -- Icebound Fortitude
				spell(55233, 6, { specIDs = { 250 } }), -- Vampiric Blood
				spell(49039, 6), -- Lichborne
				-- Shaman
				spell(108271, 7), -- Astral Shift
				-- Mage
				spell(45438, 8, { aliases = { 414658 } }), -- Ice Block
				spell(11426, 8, { specIDs = { 64 } }), -- Ice Barrier
				spell(235450, 8, { specIDs = { 62 } }), -- Prismatic Barrier
				spell(235313, 8, { specIDs = { 63 } }), -- Blazing Barrier
				spell(342245, 8), -- Alter Time
				-- Warlock
				spell(104773, 9), -- Unending Resolve
				spell(108416, 9), -- Dark Pact
				-- Monk
				spell(115203, 10), -- Fortifying Brew
				spell(122470, 10, { specIDs = { 269 } }), -- Touch of Karma
				-- Druid
				spell(22812, 11), -- Barkskin
				spell(61336, 11, { specIDs = { 103, 104 } }), -- Survival Instincts
				-- Demon Hunter
				spell(198589, 12, { specIDs = { 577, 1480 } }), -- Blur
				spell(187827, 12, { specIDs = { 581 } }), -- Metamorphosis
				-- Evoker
				spell(363916, 13), -- Obsidian Scales
			},
		},
		OFFENSIVE_COOLDOWNS = {
			id = "OFFENSIVE_COOLDOWNS",
			nameKey = "SpellGroupsPresetOffensiveCooldowns",
			descriptionKey = "SpellGroupsPresetOffensiveCooldownsDescription",
			icon = "Interface\\Icons\\warrior_talent_icon_innerrage",
			members = {
				spell(47568, 6, { specIDs = { 251 } }), -- Empower Rune Weapon
				spell(1856, 4, { specIDs = { 259, 261 } }), -- Vanish
								-- Warrior
				spell(1719, 1, { specIDs = { 72 } }), -- Recklessness
				spell(107574, 1, { specIDs = { 71, 72, 73 } }), -- Avatar
				spell(167105, 1, { specIDs = { 71 } }), -- Colossus Smash
				spell(227847, 1, { specIDs = { 71, 72 } }), -- Bladestorm
				spell(228920, 1, { specIDs = { 71, 73 } }), -- Ravager
				spell(436358, 1, { specIDs = { 71, 73 } }), -- Demolish
				spell(385059, 1, { specIDs = { 72 } }), -- Odyn's Fury
				-- Paladin
				spell(31884, 2, { specIDs = { 66, 70 }, excludeIfKnown = { 389539 } }), -- Avenging Wrath
				spell(375576, 2, { specIDs = { 66, 70 } }), -- Divine Toll
				spell(343527, 2, { specIDs = { 70 } }), -- Execution Sentence
				spell(255937, 2, { specIDs = { 70 } }), -- Wake of Ashes
				-- Hunter
				spell(19574, 3, { specIDs = { 253 } }), -- Bestial Wrath
				spell(288613, 3, { specIDs = { 254 } }), -- Trueshot
				spell(1250646, 3, { specIDs = { 255 } }), -- Takedown
				-- Rogue
				spell(13750, 4, { specIDs = { 260 } }), -- Adrenaline Rush
				spell(121471, 4, { specIDs = { 261 } }), -- Shadow Blades
				spell(360194, 4, { specIDs = { 259 } }), -- Deathmark
				spell(385627, 4, { specIDs = { 259 } }), -- Kingsbane
				spell(185313, 4, { specIDs = { 261 } }), -- Shadow Dance
				spell(280719, 4, { specIDs = { 261 } }), -- Secret Technique
				spell(51690, 4, { specIDs = { 260 } }), -- Killing Spree
				spell(381989, 4, { specIDs = { 260 } }), -- Keep It Rolling
				spell(1277933, 4, { specIDs = { 260 } }), -- Preparation
				-- Priest
				spell(120644, 5, { specIDs = { 258 } }), -- Halo
				spell(10060, 5, { specIDs = { 258 } }), -- Power Infusion
				spell(228260, 5, { aliases = { 1242173 }, specIDs = { 258 } }), -- Voidform
				-- Death Knight
				spell(51271, 6, { specIDs = { 251 } }), -- Pillar of Frost
				spell(42650, 6, { specIDs = { 252 } }), -- Army of the Dead
				spell(1233448, 6, { specIDs = { 252 } }), -- Dark Transformation
				spell(439843, 6, { specIDs = { 250, 251 } }), -- Reaper's Mark
				spell(1249658, 6, { specIDs = { 251 } }), -- Breath of Sindragosa
				spell(279302, 6, { specIDs = { 251 } }), -- Frostwyrm's Fury
				spell(1247378, 6, { specIDs = { 252 } }), -- Putrefy
				-- Shaman
				spell(114050, 7, { specIDs = { 262 } }), -- Ascendance
				spell(384352, 7, { aliases = { 114051 }, specIDs = { 263 } }), -- Doom Winds
				-- Mage
				spell(321507, 8, { specIDs = { 62 } }), -- Touch of the Magi
				spell(365350, 8, { specIDs = { 62 } }), -- Arcane Surge
				spell(190319, 8, { specIDs = { 63 } }), -- Combustion
				-- Warlock
				spell(1257052, 9, { specIDs = { 265 } }), -- Dark Harvest
				spell(442726, 9, { specIDs = { 265, 267 } }), -- Malevolence
				spell(1276452, 9, { specIDs = { 266 } }), -- Grimoire: Imp Lord
				spell(1276467, 9, { specIDs = { 266 } }), -- Grimoire: Fel Ravager
				spell(205180, 9, { specIDs = { 265 } }), -- Summon Darkglare
				spell(265187, 9, { specIDs = { 266 } }), -- Summon Demonic Tyrant
				spell(1276672, 9, { specIDs = { 266 } }), -- Summon Doomguard
				spell(1122, 9, { specIDs = { 267 } }), -- Summon Infernal
				-- Monk
				spell(1249625, 10, { specIDs = { 269 } }), -- Zenith
				spell(123904, 10, { aliases = { 443028 }, specIDs = { 269 } }), -- Invoke Xuen, the White Tiger
				spell(322109, 10, { specIDs = { 268, 269, 270 } }), -- Touch of Death
				spell(132578, 10, { specIDs = { 268 } }), -- Invoke Niuzao, the Black Ox
				spell(325153, 10, { specIDs = { 268 } }), -- Exploding Keg
				-- Druid
				spell(194223, 11, { aliases = { 102560 }, specIDs = { 102 } }), -- Celestial Alignment
				spell(1233272, 11, { aliases = { 1233346 }, specIDs = { 102 } }), -- Lunar Eclipse
				spell(205636, 11, { specIDs = { 102 } }), -- Force of Nature
				spell(202770, 11, { specIDs = { 102 } }), -- Fury of Elune
				spell(391528, 11, { specIDs = { 102, 103, 104 } }), -- Convoke the Spirits
				spell(106951, 11, { aliases = { 102543 }, specIDs = { 103 } }), -- Berserk
				spell(50334, 11, { aliases = { 102558 }, specIDs = { 104 } }), -- Berserk
				spell(204066, 11, { specIDs = { 104 } }), -- Lunar Beam
				spell(1261867, 11, { specIDs = { 104, 105 } }), -- Heart of the Wild
				-- Demon Hunter
				spell(191427, 12, { specIDs = { 577 } }), -- Metamorphosis
				spell(370965, 12, { specIDs = { 577 } }), -- The Hunt
				spell(207407, 12, { specIDs = { 581 } }), -- Soul Carver
				spell(390163, 12, { specIDs = { 581 } }), -- Sigil of Spite
				spell(1217605, 12, { specIDs = { 1480 } }), -- Void Metamorphosis
				spell(1246167, 12, { aliases = { 1259431 }, specIDs = { 1480 } }), -- The Hunt
				-- Evoker
				spell(375087, 13, { specIDs = { 1467 } }), -- Dragonrage
				spell(403631, 13, { aliases = { 442204 }, specIDs = { 1473 } }), -- Breath of Eons
				spell(357210, 13, { aliases = { 433874 }, specIDs = { 1467, 1468 } }), -- Deep Breath
			},
		},
		ROTATION = {
			id = "ROTATION",
			nameKey = "SpellGroupsPresetRotation",
			descriptionKey = "SpellGroupsPresetRotationDescription",
			icon = "Interface\\Icons\\ability_warrior_savageblow",
			members = {
				spell(184367, 1, { specIDs = { 72 } }), -- Rampage
				spell(23881, 1, { aliases = { 335096 }, specIDs = { 72 } }), -- Bloodthirst
				spell(6572, 1, { specIDs = { 73 } }), -- Revenge
				spell(163201, 1, { specIDs = { 71 } }), -- Execute
				spell(5308, 1, { specIDs = { 72, 73 } }), -- Execute
				spell(1464, 1, { specIDs = { 71 } }), -- Slam
				spell(190411, 1, { specIDs = { 72 } }), -- Whirlwind
				spell(19750, 2, { specIDs = { 65 } }), -- Flash of Light
				spell(20271, 2, { specIDs = { 65, 66, 70 } }), -- Judgment
				spell(35395, 2, { specIDs = { 70 } }), -- Crusader Strike
				spell(82326, 2, { specIDs = { 65 } }), -- Holy Light
				spell(156322, 2, { specIDs = { 65 } }), -- Eternal Flame
				spell(85222, 2, { specIDs = { 65 } }), -- Light of Dawn
				spell(53385, 2, { specIDs = { 70 } }), -- Divine Storm
				spell(383328, 2, { specIDs = { 70 } }), -- Final Verdict
				spell(34026, 3, { specIDs = { 253 } }), -- Kill Command
				spell(193455, 3, { specIDs = { 253 } }), -- Cobra Shot
				spell(19434, 3, { specIDs = { 254 } }), -- Aimed Shot
				spell(259489, 3, { specIDs = { 255 } }), -- Kill Command
				spell(186270, 3, { specIDs = { 255 } }), -- Raptor Strike
				spell(185358, 3, { specIDs = { 254 } }), -- Arcane Shot
				spell(257620, 3, { specIDs = { 254 } }), -- Multi-Shot
				spell(56641, 3, { specIDs = { 254 } }), -- Steady Shot
				spell(703, 4, { specIDs = { 259 } }), -- Garrote
				spell(1943, 4, { specIDs = { 259 } }), -- Rupture
				spell(1329, 4, { specIDs = { 259 } }), -- Mutilate
				spell(32645, 4, { specIDs = { 259 } }), -- Envenom
				spell(193315, 4, { specIDs = { 260 } }), -- Sinister Strike
				spell(185763, 4, { specIDs = { 260 } }), -- Pistol Shot
				spell(2098, 4, { specIDs = { 260 } }), -- Dispatch
				spell(185438, 4, { specIDs = { 261 } }), -- Shadowstrike
				spell(53, 4, { specIDs = { 261 } }), -- Backstab
				spell(196819, 4, { specIDs = { 261 } }), -- Eviscerate
				spell(335467, 5, { specIDs = { 258 } }), -- Shadow Word: Madness
				spell(585, 5, { specIDs = { 256, 257 } }), -- Smite
				spell(2061, 5, { specIDs = { 256, 257 } }), -- Flash Heal
				spell(17, 5, { specIDs = { 256 } }), -- Power Word: Shield
				spell(589, 5, { specIDs = { 256, 258 } }), -- Shadow Word: Pain
				spell(34914, 5, { specIDs = { 258 } }), -- Vampiric Touch
				spell(15407, 5, { specIDs = { 258 } }), -- Mind Flay
				spell(195182, 6, { specIDs = { 250 } }), -- Marrowrend
				spell(206930, 6, { specIDs = { 250 } }), -- Heart Strike
				spell(49020, 6, { specIDs = { 251 } }), -- Obliterate
				spell(49184, 6, { specIDs = { 251 } }), -- Howling Blast
				spell(49143, 6, { specIDs = { 251 } }), -- Frost Strike
				spell(85948, 6, { specIDs = { 252 } }), -- Festering Strike
				spell(55090, 6, { specIDs = { 252 } }), -- Scourge Strike
				spell(47541, 6, { specIDs = { 252 } }), -- Death Coil
				spell(188196, 7, { specIDs = { 262 } }), -- Lightning Bolt
				spell(8042, 7, { specIDs = { 262 } }), -- Earth Shock
				spell(77472, 7, { specIDs = { 264 } }), -- Healing Wave
				spell(1064, 7, { specIDs = { 264 } }), -- Chain Heal
				spell(30451, 8, { specIDs = { 62 } }), -- Arcane Blast
				spell(44425, 8, { specIDs = { 62 } }), -- Arcane Barrage
				spell(5143, 8, { specIDs = { 62 } }), -- Arcane Missiles
				spell(133, 8, { specIDs = { 63 } }), -- Fireball
				spell(11366, 8, { specIDs = { 63 } }), -- Pyroblast
				spell(116, 8, { specIDs = { 64 } }), -- Frostbolt
				spell(199786, 8, { specIDs = { 64 } }), -- Glacial Spike
				spell(980, 9, { specIDs = { 265 } }), -- Agony
				spell(30108, 9, { specIDs = { 265 } }), -- Unstable Affliction
				spell(686, 9, { aliases = { 1261153 }, specIDs = { 265, 266 } }), -- Shadow Bolt
				spell(105174, 9, { specIDs = { 266 } }), -- Hand of Gul'dan
				spell(264178, 9, { specIDs = { 266 } }), -- Demonbolt
				spell(29722, 9, { specIDs = { 267 } }), -- Incinerate
				spell(116858, 9, { specIDs = { 267 } }), -- Chaos Bolt
				spell(445465, 9, { specIDs = { 265, 267 } }), -- Wither
				spell(196277, 9, { specIDs = { 266 } }), -- Implosion
				spell(399491, 10, { specIDs = { 270 } }), -- Sheilun's Gift
				spell(100780, 10, { specIDs = { 268, 269 } }), -- Tiger Palm
				spell(100784, 10, { specIDs = { 268, 269 } }), -- Blackout Kick
				spell(116670, 10, { specIDs = { 270 } }), -- Vivify
				spell(124682, 10, { specIDs = { 270 } }), -- Enveloping Mist
				spell(5176, 11, { specIDs = { 102 } }), -- Wrath
				spell(194153, 11, { specIDs = { 102 } }), -- Starfire
				spell(78674, 11, { specIDs = { 102 } }), -- Starsurge
				spell(5221, 11, { specIDs = { 103 } }), -- Shred
				spell(1822, 11, { specIDs = { 103 } }), -- Rake
				spell(1079, 11, { specIDs = { 103 } }), -- Rip
				spell(22568, 11, { specIDs = { 103 } }), -- Ferocious Bite
				spell(774, 11, { specIDs = { 105 } }), -- Rejuvenation
				spell(8936, 11, { specIDs = { 105 } }), -- Regrowth
				spell(33763, 11, { specIDs = { 105 } }), -- Lifebloom
				spell(8921, 11, { specIDs = { 102, 104 } }), -- Moonfire
				spell(93402, 11, { specIDs = { 102 } }), -- Sunfire
				spell(191034, 11, { specIDs = { 102 } }), -- Starfall
				spell(400254, 11, { specIDs = { 104 } }), -- Raze
				spell(6807, 11, { specIDs = { 104 } }), -- Maul
				spell(473728, 12, { specIDs = { 1480 } }), -- Void Ray
				spell(1245412, 12, { aliases = { 1245483 }, specIDs = { 1480 } }), -- Voidblade
				spell(162794, 12, { specIDs = { 577 } }), -- Chaos Strike
				spell(228477, 12, { specIDs = { 581 } }), -- Soul Cleave
				spell(263642, 12, { specIDs = { 581 } }), -- Fracture
				spell(247454, 12, { specIDs = { 581 } }), -- Spirit Bomb
				spell(473662, 12, { aliases = { 1217610 }, specIDs = { 1480 } }), -- Consume
				spell(1221150, 12, { specIDs = { 1480 } }), -- Collapsing Star
				spell(362969, 13, { specIDs = { 1467 } }), -- Azure Strike
				spell(356995, 13, { specIDs = { 1467 } }), -- Disintegrate
				spell(364343, 13, { specIDs = { 1468 } }), -- Echo
				spell(361469, 13, { specIDs = { 1467, 1468, 1473 } }), -- Living Flame
				spell(395160, 13, { specIDs = { 1473 } }), -- Eruption
			},
		},
		ROTATIONAL_COOLDOWNS = {
			id = "ROTATIONAL_COOLDOWNS",
			nameKey = "SpellGroupsPresetRotationalCooldowns",
			descriptionKey = "SpellGroupsPresetRotationalCooldownsDescription",
			icon = "Interface\\Icons\\ability_warrior_savageblow",
			members = {
				spell(23922, 1, { specIDs = { 73 } }), -- Shield Slam
				spell(7384, 1, { specIDs = { 71 } }), -- Overpower
				spell(12294, 1, { specIDs = { 71 } }), -- Mortal Strike
				spell(6343, 1, { specIDs = { 72, 73 } }), -- Thunder Clap
				spell(85288, 1, { aliases = { 335097 }, specIDs = { 72 } }), -- Raging Blow
				spell(20473, 2, { specIDs = { 65 } }), -- Holy Shock
				spell(184575, 2, { specIDs = { 70 } }), -- Blade of Justice
				spell(26573, 2, { specIDs = { 66 } }), -- Consecration
				spell(204019, 2, { specIDs = { 66 } }), -- Blessed Hammer
				spell(53595, 2, { specIDs = { 66 } }), -- Hammer of the Righteous
				spell(259495, 3, { specIDs = { 255 } }), -- Wildfire Bomb
				spell(257044, 3, { specIDs = { 254 } }), -- Rapid Fire
				spell(217200, 3, { specIDs = { 253 } }), -- Barbed Shot
				spell(212431, 3, { specIDs = { 254 } }), -- Explosive Shot
				spell(260243, 3, { specIDs = { 254 } }), -- Volley
				spell(1261193, 3, { specIDs = { 255 } }), -- Boomstick
				spell(426591, 4, { specIDs = { 261 } }), -- Goremaw's Bite
				spell(271877, 4, { specIDs = { 260 } }), -- Blade Rush
				spell(315341, 4, { specIDs = { 260 } }), -- Between the Eyes
				spell(13877, 4, { specIDs = { 260 } }), -- Blade Flurry
				spell(1214909, 4, { specIDs = { 260 } }), -- Roll the Bones
				spell(8092, 5, { aliases = { 450405 }, specIDs = { 256, 258 } }), -- Mind Blast
				spell(33076, 5, { specIDs = { 257 } }), -- Prayer of Mending
				spell(34861, 5, { specIDs = { 257 } }), -- Holy Word: Sanctify
				spell(2050, 5, { specIDs = { 257 } }), -- Holy Word: Serenity
				spell(194509, 5, { specIDs = { 256 } }), -- Power Word: Radiance
				spell(47540, 5, { specIDs = { 256 } }), -- Penance
				spell(263165, 5, { specIDs = { 258 } }), -- Void Torrent
				spell(1227280, 5, { specIDs = { 258 } }), -- Tentacle Slam
				spell(32379, 5, { specIDs = { 258 } }), -- Shadow Word: Death
				spell(50842, 6, { specIDs = { 250 } }), -- Blood Boil
				spell(61295, 7, { specIDs = { 264 } }), -- Riptide
				spell(60103, 7, { specIDs = { 263 } }), -- Lava Lash
				spell(17364, 7, { specIDs = { 263 } }), -- Stormstrike
				spell(51505, 7, { specIDs = { 262 } }), -- Lava Burst
				spell(191634, 7, { specIDs = { 262 } }), -- Stormkeeper
				spell(197214, 7, { aliases = { 1218090 }, specIDs = { 263 } }), -- Sundering
				spell(444995, 7, { specIDs = { 263 } }), -- Surging Totem
				spell(44614, 8, { specIDs = { 64 } }), -- Flurry
				spell(108853, 8, { specIDs = { 63 } }), -- Fire Blast
				spell(153561, 8, { specIDs = { 63 } }), -- Meteor
				spell(205021, 8, { aliases = { 153595 }, specIDs = { 64 } }), -- Ray of Frost
				spell(84714, 8, { specIDs = { 64 } }), -- Frozen Orb
				spell(17962, 9, { specIDs = { 267 } }), -- Conflagrate
				spell(264130, 9, { specIDs = { 266 } }), -- Power Siphon
				spell(80240, 9, { specIDs = { 267 } }), -- Havoc
				spell(152108, 9, { specIDs = { 267 } }), -- Cataclysm
				spell(6353, 9, { specIDs = { 267 } }), -- Soul Fire
				spell(48181, 9, { specIDs = { 265 } }), -- Haunt
				spell(104316, 9, { specIDs = { 266 } }), -- Call Dreadstalkers
				spell(115151, 10, { specIDs = { 270 } }), -- Renewing Mist
				spell(107428, 10, { specIDs = { 269 } }), -- Rising Sun Kick
				spell(113656, 10, { specIDs = { 269 } }), -- Fists of Fury
				spell(115181, 10, { specIDs = { 268 } }), -- Breath of Fire
				spell(121253, 10, { specIDs = { 268 } }), -- Keg Smash
				spell(392983, 10, { specIDs = { 269 } }), -- Strike of the Windlord
				spell(1217413, 10, { specIDs = { 269 } }), -- Slicing Winds
				spell(33917, 11, { specIDs = { 104 } }), -- Mangle
				spell(18562, 11, { specIDs = { 105 } }), -- Swiftmend
				spell(88747, 11, { specIDs = { 102 } }), -- Wild Mushroom
				spell(5217, 11, { specIDs = { 103 } }), -- Tiger's Fury
				spell(274837, 11, { aliases = { 1243807 }, specIDs = { 103 } }), -- Feral Frenzy
				spell(1252871, 11, { specIDs = { 104 } }), -- Red Moon
				spell(77758, 11, { specIDs = { 104 } }), -- Thrash
				spell(188499, 12, { specIDs = { 577 } }), -- Blade Dance
				spell(198013, 12, { aliases = { 452497 }, specIDs = { 577 } }), -- Eye Beam
				spell(258860, 12, { specIDs = { 577 } }), -- Essence Break
				spell(212084, 12, { specIDs = { 581 } }), -- Fel Devastation
				spell(1226019, 12, { aliases = { 1245453 }, specIDs = { 1480 } }), -- Reap
				spell(258920, 12, { specIDs = { 577, 581 } }), -- Immolation Aura
				spell(204596, 12, { specIDs = { 581 } }), -- Sigil of Flame
				spell(1241937, 12, { specIDs = { 1480 } }), -- Soul Immolation
				spell(355936, 13, { specIDs = { 1468 } }), -- Dream Breath
				spell(357208, 13, { aliases = { 382266 } }), -- Fire Breath
				spell(359073, 13, { aliases = { 382411 }, specIDs = { 1467 } }), -- Eternity Surge
				spell(396286, 13, { aliases = { 408092 }, specIDs = { 1473 } }), -- Upheaval
				spell(366155, 13, { specIDs = { 1468 } }), -- Reversion
				spell(373861, 13, { specIDs = { 1468 } }), -- Temporal Anomaly
			},
		},
		ACTIVE_MITIGATION = {
			id = "ACTIVE_MITIGATION",
			nameKey = "SpellGroupsPresetActiveMitigation",
			descriptionKey = "SpellGroupsPresetActiveMitigationDescription",
			icon = "Interface\\Icons\\ability_warrior_shieldwall",
			members = {
				spell(2565, 1, { specIDs = { 73 } }), -- Shield Block
				spell(190456, 1, { specIDs = { 73 } }), -- Ignore Pain
				spell(53600, 2, { specIDs = { 66 } }), -- Shield of the Righteous
				spell(49998, 6, { specIDs = { 250 } }), -- Death Strike
				spell(322507, 10, { aliases = { 1241059 }, specIDs = { 268 } }), -- Celestial Brew
				spell(119582, 10, { specIDs = { 268 } }), -- Purifying Brew
				spell(22842, 11), -- Frenzied Regeneration
				spell(192081, 11, { specIDs = { 104 } }), -- Ironfur
				spell(203720, 12, { specIDs = { 581 } }), -- Demon Spikes
				spell(204021, 12, { specIDs = { 581 } }), -- Fiery Brand
			},
		},
		EXTERNAL_DEFENSIVES = {
			id = "EXTERNAL_DEFENSIVES",
			nameKey = "SpellGroupsPresetExternalDefensives",
			descriptionKey = "SpellGroupsPresetExternalDefensivesDescription",
			icon = "Interface\\Icons\\spell_holy_painsupression",
			members = {
				spell(31821, 2, { specIDs = { 65 } }), -- Aura Mastery
				spell(6940, 2), -- Blessing of Sacrifice
				spell(33206, 5, { specIDs = { 256 } }), -- Pain Suppression
				spell(47788, 5, { specIDs = { 257 } }), -- Guardian Spirit
				spell(98008, 7, { specIDs = { 264 } }), -- Spirit Link Totem
				spell(116849, 10, { specIDs = { 270 } }), -- Life Cocoon
				spell(102342, 11, { specIDs = { 105 } }), -- Ironbark
				spell(374227, 13), -- Zephyr
				spell(357170, 13, { specIDs = { 1468 } }), -- Time Dilation
				spell(1022, 2), -- Blessing of Protection
				spell(62618, 5), -- Power Word: Barrier
				spell(51052, 6), -- Anti-Magic Zone
				spell(196718, 12), -- Darkness
			},
		},
		HEALING_COOLDOWNS = {
			id = "HEALING_COOLDOWNS",
			nameKey = "SpellGroupsPresetHealingCooldowns",
			descriptionKey = "SpellGroupsPresetHealingCooldownsDescription",
			icon = "Interface\\Icons\\spell_holy_guardianspirit",
			members = {
				spell(31884, 2, { specIDs = { 65 } }), -- Avenging Wrath
				spell(375576, 2, { specIDs = { 65 } }), -- Divine Toll
				spell(472433, 5, { specIDs = { 256 } }), -- Evangelism
				spell(421453, 5, { specIDs = { 256 } }), -- Ultimate Penitence
				spell(200183, 5, { specIDs = { 257 } }), -- Apotheosis
				spell(64843, 5, { specIDs = { 257 } }), -- Divine Hymn
				spell(114052, 7, { specIDs = { 264 } }), -- Ascendance
				spell(108280, 7, { specIDs = { 264 } }), -- Healing Tide Totem
				spell(115310, 10, { aliases = { 388615 }, specIDs = { 270 } }), -- Revival
				spell(322118, 10, { aliases = { 325197 }, specIDs = { 270 } }), -- Invoke Yu'lon, the Jade Serpent
				spell(443028, 10, { specIDs = { 270 } }), -- Celestial Conduit
				spell(116680, 10, { specIDs = { 270 } }), -- Thunder Focus Tea
				spell(740, 11, { specIDs = { 105 } }), -- Tranquility
				spell(323764, 11, { specIDs = { 105 } }), -- Convoke the Spirits
				spell(33891, 11, { specIDs = { 105 } }), -- Incarnation: Tree of Life
				spell(48438, 11, { specIDs = { 105 } }), -- Wild Growth
				spell(370537, 13, { specIDs = { 1468 } }), -- Stasis
				spell(359816, 13, { specIDs = { 1468 } }), -- Dream Flight
				spell(363534, 13, { specIDs = { 1468 } }), -- Rewind
				spell(633, 2), -- Lay on Hands
				spell(444995, 7, { specIDs = { 264 } }), -- Surging Totem
			},
		},
		SUPPORT_COOLDOWNS = {
			id = "SUPPORT_COOLDOWNS",
			nameKey = "SpellGroupsPresetSupportCooldowns",
			descriptionKey = "SpellGroupsPresetSupportCooldownsDescription",
			icon = "Interface\\Icons\\spell_holy_powerinfusion",
			members = {
				spell(10060, 5, { specIDs = { 256, 257 } }), -- Power Infusion
				spell(370553, 13), -- Tip the Scales
				spell(395152, 13, { specIDs = { 1473 } }), -- Ebon Might
				spell(404977, 13, { specIDs = { 1473 } }), -- Time Skip
				spell(409311, 13, { specIDs = { 1473 } }), -- Prescience
				spell(443454, 7), -- Ancestral Swiftness
				spell(12051, 8, { specIDs = { 62 } }), -- Evocation
			},
		},
		DISPELS = {
			id = "DISPELS",
			nameKey = "SpellGroupsPresetDispels",
			descriptionKey = "SpellGroupsPresetDispelsDescription",
			icon = "Interface\\Icons\\spell_holy_dispelmagic",
			members = {
				-- Paladin
				spell(4987, 2, { specIDs = { 65 }, dispelKind = "FRIENDLY" }), -- Cleanse
				spell(213644, 2, { aliases = { 440013 }, dispelKind = "FRIENDLY" }), -- Cleanse Toxins
				-- Hunter
				spell(19801, 3, { dispelKind = "OFFENSIVE" }), -- Tranquilizing Shot
				-- Priest
				spell(527, 5, { specIDs = { 256, 257 }, dispelKind = "FRIENDLY" }), -- Purify
				spell(213634, 5, { aliases = { 440006 }, dispelKind = "FRIENDLY" }), -- Purify Disease
				spell(32375, 5, { dispelKind = "BOTH" }), -- Mass Dispel
				spell(528, 5, { dispelKind = "OFFENSIVE" }), -- Dispel Magic
				-- Shaman
				spell(51886, 7, { aliases = { 440012 }, dispelKind = "FRIENDLY" }), -- Cleanse Spirit
				spell(77130, 7, { specIDs = { 264 }, dispelKind = "FRIENDLY" }), -- Purify Spirit
				spell(370, 7, { dispelKind = "OFFENSIVE" }), -- Purge
				spell(383013, 7, { dispelKind = "FRIENDLY" }), -- Poison Cleansing Totem
				-- Mage
				spell(475, 8, { dispelKind = "FRIENDLY" }), -- Remove Curse
				spell(30449, 8, { dispelKind = "OFFENSIVE" }), -- Spellsteal
				-- Warlock
				spell(89808, 9, { aliases = { 119905, 132411 }, dispelKind = "FRIENDLY" }), -- Singe Magic
				spell(19505, 9, { pet = true, dispelKind = "OFFENSIVE" }), -- Devour Magic
				-- Monk
				spell(115450, 10, { specIDs = { 270 }, dispelKind = "FRIENDLY" }), -- Detox
				spell(218164, 10, { specIDs = { 268, 269 }, dispelKind = "FRIENDLY" }), -- Detox
				-- Druid
				spell(2782, 11, { aliases = { 440015 }, dispelKind = "FRIENDLY" }), -- Remove Corruption
				spell(88423, 11, { specIDs = { 105 }, dispelKind = "FRIENDLY" }), -- Nature's Cure
				spell(2908, 11, { dispelKind = "OFFENSIVE" }), -- Soothe
				-- Demon Hunter
				spell(278326, 12, { dispelKind = "OFFENSIVE" }), -- Consume Magic
				-- Evoker
				spell(365585, 13, { dispelKind = "FRIENDLY" }), -- Expunge
				spell(360823, 13, { specIDs = { 1468 }, dispelKind = "FRIENDLY" }), -- Naturalize
				spell(374251, 13, { dispelKind = "FRIENDLY" }), -- Cauterizing Flame
			},
		},
		BATTLE_REZ = {
			id = "BATTLE_REZ",
			nameKey = "SpellGroupsPresetBattleRez",
			descriptionKey = "SpellGroupsPresetBattleRezDescription",
			icon = "Interface\\Icons\\spell_nature_reincarnation",
			members = {
				-- Paladin
				spell(391054, 2), -- Intercession
				-- Death Knight
				spell(61999, 6), -- Raise Ally
				-- Warlock
				spell(20707, 9), -- Soulstone
				-- Druid
				spell(20484, 11), -- Rebirth
			},
		},
		RACIALS = {
			id = "RACIALS",
			nameKey = "CooldownPanelAddRacials",
			descriptionKey = "SpellGroupsPresetRacialsDescription",
			icon = "Interface\\Icons\\racial_orc_berserkerstrength",
			members = {
				spell(20572, nil, { aliases = { 33697, 33702 } }), -- Blood Fury
				spell(26297, nil), -- Berserking
				spell(7744, nil), -- Will of the Forsaken
				spell(20549, nil), -- War Stomp
				spell(28730, nil, { aliases = { 50613, 69179, 80483, 129597, 155145, 202719, 25046, 232633 } }), -- Arcane Torrent
				spell(69070, nil), -- Rocket Jump
				spell(59752, nil), -- Will to Survive
				spell(20594, nil), -- Stoneform
				spell(58984, nil), -- Shadowmeld
				spell(20589, nil), -- Escape Artist
				spell(28880, nil, { aliases = { 59542, 59543, 59544, 59545, 59547, 59548, 121093, 370626, 416250 } }), -- Gift of the Naaru
				spell(68992, nil), -- Darkflight
				spell(107079, nil), -- Quaking Palm
				spell(357214, nil), -- Wing Buffet
				spell(368970, nil), -- Tail Swipe
				spell(260364, nil), -- Arcane Pulse
				spell(255654, nil), -- Bull Rush
				spell(274738, nil), -- Ancestral Call
				spell(291944, nil), -- Regeneratin'
				spell(312411, nil), -- Bag of Tricks
				spell(256948, nil), -- Spatial Rift
				spell(255647, nil), -- Light's Judgment
				spell(265221, nil), -- Fireblood
				spell(287712, nil), -- Haymaker
				spell(312924, nil), -- Hyper Organic Light Originator
				spell(436344, nil), -- Azerite Surge
				spell(1237885, nil), -- Thorn Bloom
				spell(20577, nil), -- Cannibalize
				spell(69041, nil), -- Rocket Barrage
			},
		},
		POTIONS = {
			id = "POTIONS",
			nameKey = "CategoryPotions",
			descriptionKey = "SpellGroupsPresetPotionsDescription",
			icon = "Interface\\Icons\\inv_potion_54",
			members = {},
		},
	},
}

-- Reuse the current consumable catalogs and ECD rank families. One preset entry
-- represents each potion, including quality and fleeting variants.
do
	local members, seen = SpellGroups.Presets.byID.POTIONS.members, {}
	local function add(itemID)
		itemID = CooldownPanels.GetCanonicalItemRankID and CooldownPanels:GetCanonicalItemRankID(itemID) or itemID
		if not itemID or seen[itemID] then return end
		seen[itemID] = true
		members[#members + 1] = { key = "item:" .. itemID, type = "ITEM", itemID = itemID, useHighestRank = true }
	end
	for _, source in ipairs(CooldownPanels.generatedAuraPresetCatalog and CooldownPanels.generatedAuraPresetCatalog.potions or {}) do
		for _, itemID in ipairs(source.sourceItemIDs or {}) do add(itemID) end
	end
	for _, source in ipairs(addon.Health and addon.Health.healthList or {}) do
		if source.type == "potion" and (source.requiredLevel or 0) >= 81 then add(source.id) end
	end
	for _, source in ipairs(addon.Drinks and addon.Drinks.manaPotions or {}) do
		if (source.requiredLevel or 0) >= 81 then add(source.id) end
	end
end
