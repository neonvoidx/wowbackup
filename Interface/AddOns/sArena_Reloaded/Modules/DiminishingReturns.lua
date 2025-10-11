local isRetail = sArenaMixin.isRetail
-- DR's are static 18 seconds on Retail and dynamic 15-20 on MoP.
-- 0.5 leeway is added for Retail
-- Can be changed in gui, /sarena
local drTime = (isRetail and 18.5) or 20 -- ^^^^^^^^^^^^
local drList
local drCategories
local severityColor = {
	[1] = { 0, 1, 0, 1 },
	[2] = { 1, 1, 0, 1 },
	[3] = { 1, 0, 0, 1 }
}

local GetTime = GetTime
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture

if isRetail then

	sArenaMixin.drCategories = {
		"Incapacitate",
		"Stun",
		"Root",
		"Disarm",
		"Disorient",
		"Silence",
		"Knock",
	}

	sArenaMixin.defaultSettings.profile.drCategories = {
		["Incapacitate"] = true,
		["Stun"] = true,
		["Root"] = true,
		["Disarm"] = true,
		["Disorient"] = true,
		["Silence"] = true,
		["Knock"] = true,
	}



	sArenaMixin.defaultSettings.profile.drIcons = {
		["Stun"] = 132298,
		["Incapacitate"] = 136071,
		["Disorient"] = 136183,
		["Silence"] = 458230,
		["Root"] = 136100,
		["Knock"] = 237589,
		["Disarm"] = 132343,
	}

	drList = {
		[207167]  = "Disorient", -- Blinding Sleet
		[207685]  = "Disorient", -- Sigil of Misery
		[33786]   = "Disorient", -- Cyclone
		[360806]  = "Disorient", -- Sleep Walk
		[1513]    = "Disorient", -- Scare Beast
		[31661]   = "Disorient", -- Dragon's Breath
		[198909]  = "Disorient", -- Song of Chi-ji
		[202274]  = "Disorient", -- Hot Trub
		[105421]  = "Disorient", -- Blinding Light
		[10326]   = "Disorient", -- Turn Evil
		[205364]  = "Disorient", -- Dominate Mind
		[605]     = "Disorient", -- Mind Control
		[8122]    = "Disorient", -- Psychic Scream
		[2094]    = "Disorient", -- Blind
		[118699]  = "Disorient", -- Fear
		[130616]  = "Disorient", -- Fear (Horrify)
		[5484]    = "Disorient", -- Howl of Terror
		[261589]  = "Disorient", -- Seduction (Grimoire of Sacrifice)
		[6358]    = "Disorient", -- Seduction (Succubus)
		[5246]    = "Disorient", -- Intimidating Shout
		[316593]  = "Disorient", -- Intimidating Shout (Menace Main Target)
		[316595]  = "Disorient", -- Intimidating Shout (Menace Other Targets)
		[331866]  = "Disorient", -- Agent of Chaos (Venthyr Covenant)
		[324263]  = "Disorient", -- Sulfuric Emission (Soulbind Ability)

		-- *** Incapacitate Effects ***
		[217832]  = "Incapacitate", -- Imprison
		[221527]  = "Incapacitate", -- Imprison (Honor talent)
		[2637]    = "Incapacitate", -- Hibernate
		[99]      = "Incapacitate", -- Incapacitating Roar
		[378441]  = "Incapacitate", -- Time Stop
		[3355]    = "Incapacitate", -- Freezing Trap
		[203337]  = "Incapacitate", -- Freezing Trap (Honor talent)
		[213691]  = "Incapacitate", -- Scatter Shot
		[383121]  = "Incapacitate", -- Mass Polymorph
		[118]     = "Incapacitate", -- Polymorph
		[28271]   = "Incapacitate", -- Polymorph (Turtle)
		[28272]   = "Incapacitate", -- Polymorph (Pig)
		[61025]   = "Incapacitate", -- Polymorph (Snake)
		[61305]   = "Incapacitate", -- Polymorph (Black Cat)
		[61780]   = "Incapacitate", -- Polymorph (Turkey)
		[61721]   = "Incapacitate", -- Polymorph (Rabbit)
		[126819]  = "Incapacitate", -- Polymorph (Porcupine)
		[161353]  = "Incapacitate", -- Polymorph (Polar Bear Cub)
		[161354]  = "Incapacitate", -- Polymorph (Monkey)
		[161355]  = "Incapacitate", -- Polymorph (Penguin)
		[161372]  = "Incapacitate", -- Polymorph (Peacock)
		[277787]  = "Incapacitate", -- Polymorph (Baby Direhorn)
		[277792]  = "Incapacitate", -- Polymorph (Bumblebee)
		[321395]  = "Incapacitate", -- Polymorph (Mawrat)
		[391622]  = "Incapacitate", -- Polymorph (Duck)
		[460396]  = "Incapacitate", -- Polymorph (Mosswool)
		[461489]  = "Incapacitate", -- Polymorph (Mosswool) 2
		[82691]   = "Incapacitate", -- Ring of Frost
		[115078]  = "Incapacitate", -- Paralysis
		[357768]  = "Incapacitate", -- Paralysis 2 (Perpetual Paralysis?)
		[20066]   = "Incapacitate", -- Repentance
		[9484]    = "Incapacitate", -- Shackle Undead
		[200196]  = "Incapacitate", -- Holy Word: Chastise
		[1776]    = "Incapacitate", -- Gouge
		[6770]    = "Incapacitate", -- Sap
		[51514]   = "Incapacitate", -- Hex
		[196942]  = "Incapacitate", -- Hex (Voodoo Totem)
		[210873]  = "Incapacitate", -- Hex (Raptor)
		[211004]  = "Incapacitate", -- Hex (Spider)
		[211010]  = "Incapacitate", -- Hex (Snake)
		[211015]  = "Incapacitate", -- Hex (Cockroach)
		[269352]  = "Incapacitate", -- Hex (Skeletal Hatchling)
		[309328]  = "Incapacitate", -- Hex (Living Honey)
		[277778]  = "Incapacitate", -- Hex (Zandalari Tendonripper)
		[277784]  = "Incapacitate", -- Hex (Wicker Mongrel)
		[197214]  = "Incapacitate", -- Sundering
		[710]     = "Incapacitate", -- Banish
		[6789]    = "Incapacitate", -- Mortal Coil
		[107079]  = "Incapacitate", -- Quaking Palm (Racial, Pandaren)

		-- *** Controlled Stun Effects ***
		[210141]  = "Stun", -- Zombie Explosion
		[377048]  = "Stun", -- Absolute Zero (Breath of Sindragosa)
		[108194]  = "Stun", -- Asphyxiate (Unholy)
		[221562]  = "Stun", -- Asphyxiate (Blood)
		[91800]   = "Stun", -- Gnaw (Ghoul)
		[91797]   = "Stun", -- Monstrous Blow (Mutated Ghoul)
		[287254]  = "Stun", -- Dead of Winter
		[179057]  = "Stun", -- Chaos Nova
		[205630]  = "Stun", -- Illidan's Grasp (Primary effect)
		[208618]  = "Stun", -- Illidan's Grasp (Secondary effect)
		[211881]  = "Stun", -- Fel Eruption
		[200166]  = "Stun", -- Metamorphosis (PvE Stun effect)
		[203123]  = "Stun", -- Maim
		[163505]  = "Stun", -- Rake (Prowl)
		[5211]    = "Stun", -- Mighty Bash
		[202244]  = "Stun", -- Overrun
		[325321]  = "Stun", -- Wild Hunt's Charge
		[372245]  = "Stun", -- Terror of the Skies
		[408544]  = "Stun", -- Seismic Slam
		[117526]  = "Stun", -- Binding Shot
		[357021]  = "Stun", -- Consecutive Concussion
		[24394]   = "Stun", -- Intimidation
		[389831]  = "Stun", -- Snowdrift
		[119381]  = "Stun", -- Leg Sweep
		[458605]  = "Stun", -- Leg Sweep 2
		[202346]  = "Stun", -- Double Barrel
		[853]     = "Stun", -- Hammer of Justice
		[255941]  = "Stun", -- Wake of Ashes
		[64044]   = "Stun", -- Psychic Horror
		[200200]  = "Stun", -- Holy Word: Chastise Censure
		[1833]    = "Stun", -- Cheap Shot
		[408]     = "Stun", -- Kidney Shot
		[118905]  = "Stun", -- Static Charge (Capacitor Totem)
		[118345]  = "Stun", -- Pulverize (Primal Earth Elemental)
		[305485]  = "Stun", -- Lightning Lasso
		[89766]   = "Stun", -- Axe Toss
		[171017]  = "Stun", -- Meteor Strike (Infernal)
		[171018]  = "Stun", -- Meteor Strike (Abyssal)
		[30283]   = "Stun", -- Shadowfury
		[385954]  = "Stun", -- Shield Charge
		[46968]   = "Stun", -- Shockwave
		[132168]  = "Stun", -- Shockwave (Protection)
		[145047]  = "Stun", -- Shockwave (Proving Grounds PvE)
		[132169]  = "Stun", -- Storm Bolt
		[199085]  = "Stun", -- Warpath
		[20549]   = "Stun", -- War Stomp (Racial, Tauren)
		[255723]  = "Stun", -- Bull Rush (Racial, Highmountain Tauren)
		[287712]  = "Stun", -- Haymaker (Racial, Kul Tiran)
		[332423]  = "Stun", -- Sparkling Driftglobe Core (Kyrian Covenant)

		-- *** Controlled Root Effects ***
		-- Note: Roots with duration <= 2s has no DR and are commented out
		[204085]  = "Root", -- Deathchill (Chains of Ice)
		[233395]  = "Root", -- Deathchill (Remorseless Winter)
		[454787]  = "Root", -- Ice Prison
		[339]     = "Root", -- Entangling Roots
		[235963]  = "Root", -- Entangling Roots (Earthen Grasp)
		[170855]  = "Root", -- Entangling Roots (Nature's Grasp)
		[102359]  = "Root", -- Mass Entanglement
		[355689]  = "Root", -- Landslide
		[393456]  = "Root", -- Entrapment (Tar Trap)
		[162480]  = "Root", -- Steel Trap
		[212638]  = "Root", -- Tracker's Net
		[201158]  = "Root", -- Super Sticky Tar
		[122]     = "Root", -- Frost Nova
		[33395]   = "Root", -- Freeze
		[386770]  = "Root", -- Freezing Cold
		[378760]  = "Root", -- Frostbite
		[114404]  = "Root", -- Void Tendril's Grasp
		[342375]  = "Root", -- Tormenting Backlash (Torghast PvE)
		[116706]  = "Root", -- Disable
		[324382]  = "Root", -- Clash
		[64695]   = "Root", -- Earthgrab (Totem effect)
		[285515]  = "Root", -- Surge of Power
		[199042]  = "Root", -- Thunderstruck (Protection PvP Talent)
		[39965]   = "Root", -- Frost Grenade (Item)
		[75148]   = "Root", -- Embersilk Net (Item)
		[55536]   = "Root", -- Frostweave Net (Item)
		[268966]  = "Root", -- Hooked Deep Sea Net (Item)
		--[16979]   = "Root", -- Wild Charge (has no DR)
		--[190927]  = "Root", -- Harpoon (has no DR)
		--[199786]  = "Root", -- Glacial Spike (has no DR)
		--[356738]  = "Root", -- Earth Unleashed
		--[356356]  = "Root", -- Warbringer

		-- *** Silence Effects ***
		[47476]   = "Silence", -- Strangulate
		[374776]  = "Silence", -- Tightening Grasp
		[204490]  = "Silence", -- Sigil of Silence
		[410065]  = "Silence", -- Reactive Resin
		[202933]  = "Silence", -- Spider Sting
		[356727]  = "Silence", -- Spider Venom
		[354831]  = "Silence", -- Wailing Arrow 1
		[355596]  = "Silence", -- Wailing Arrow 2
		[217824]  = "Silence", -- Shield of Virtue
		[15487]   = "Silence", -- Silence
		[1330]    = "Silence", -- Garrote
		[196364]  = "Silence", -- Unstable Affliction Silence Effect
		--[78675]   = "Silence", -- Solar Beam (has no DR)

		-- *** Disarm Weapon Effects ***
		[209749]  = "Disarm", -- Faerie Swarm (Balance Honor Talent)
		[407032]  = "Disarm", -- Sticky Tar Bomb 1
		[407031]  = "Disarm", -- Sticky Tar Bomb 2
		[207777]  = "Disarm", -- Dismantle
		[233759]  = "Disarm", -- Grapple Weapon
		[236077]  = "Disarm", -- Disarm


		-- *** Controlled Knock Effects ***
		-- Note: not every Knock has an aura.
		[204408]  = "Knock", -- Thunderstorm
		[108199]  = "Knock", -- Gorefiend's Grasp
		[202249]  = "Knock", -- Overrun
		[61391]   = "Knock", -- Typhoon
		[102793]  = "Knock", -- Ursol's Vortex
		[431620]  = "Knock", -- Upheaval
		[186387]  = "Knock", -- Bursting Shot
		[236776]  = "Knock", -- Hi-Explosive Trap
		[236777]  = "Knock", -- Hi-Explosive Trap 2
		[462031]  = "Knock", -- Implosive Trap
		[157981]  = "Knock", -- Blast Wave
		[51490]   = "Knock", -- Thunderstorm
		[368970]  = "Knock", -- Tail Swipe (Racial, Dracthyr)
		[357214]  = "Knock", -- Wing Buffet (Racial, Dracthyr)
	}

else
	-- Mists of Pandaria
	sArenaMixin.drCategories = {
		"Incapacitate",
		"Stun",
		"RandomStun",
		"RandomRoot",
		"Root",
		"Disarm",
		"Fear",
		"Disorient",
		"Silence",
		"Horror",
		"MindControl",
		"Cyclone",
		"Charge",
	}

	sArenaMixin.defaultSettings.profile.drCategories = {
		["Incapacitate"] = true,
		["Stun"] = true,
		["RandomStun"] = true,
		["RandomRoot"] = true,
		["Root"] = true,
		["Disarm"] = true,
		["Fear"] = true,
		["Disorient"] = true,
		["Silence"] = true,
		["Horror"] = true,
		["MindControl"] = true,
		["Cyclone"] = true,
		["Charge"] = false,
	}
	sArenaMixin.defaultSettings.profile.drIcons = {
		["Incapacitate"] = 136071,
		["Stun"] = 132298,
		["RandomStun"] = 133477,
		["RandomRoot"] = 135852,
		["Root"] = 135848,
		["Disarm"] = 132343,
		["Fear"] = 136183,
		["Disorient"] = 134153,
		["Silence"] = 458230,
		["Horror"] = 237568,
		["MindControl"] = 136206,
		["Cyclone"] = 136022,
		["Charge"] = 132337,
	}

	drList = {
		[49203]  = "Incapacitate", -- Hungering Cold
		[2637]   = "Incapacitate", -- Hibernate
		[3355]   = "Incapacitate", -- Freezing Trap Effect
		[19386]  = "Incapacitate", -- Wyvern Sting
		[118]    = "Incapacitate", -- Polymorph
		[28271]  = "Incapacitate", -- Polymorph: Turtle
		[28272]  = "Incapacitate", -- Polymorph: Pig
		[61721]  = "Incapacitate", -- Polymorph: Rabbit
		[61780]  = "Incapacitate", -- Polymorph: Turkey
		[61305]  = "Incapacitate", -- Polymorph: Black Cat
		[20066]  = "Incapacitate", -- Repentance
		[1776]   = "Incapacitate", -- Gouge
		[6770]   = "Incapacitate", -- Sap
		[710]    = "Incapacitate", -- Banish
		[9484]   = "Incapacitate", -- Shackle Undead
		[51514]  = "Incapacitate", -- Hex
		[13327]  = "Incapacitate", -- Reckless Charge (Rocket Helmet)
		[4064]   = "Incapacitate", -- Rough Copper Bomb
		[4065]   = "Incapacitate", -- Large Copper Bomb
		[4066]   = "Incapacitate", -- Small Bronze Bomb
		[4067]   = "Incapacitate", -- Big Bronze Bomb
		[4068]   = "Incapacitate", -- Iron Grenade
		[12421]  = "Incapacitate", -- Mithril Frag Bomb
		[4069]   = "Incapacitate", -- Big Iron Bomb
		[12562]  = "Incapacitate", -- The Big One
		[12543]  = "Incapacitate", -- Hi-Explosive Bomb
		[19769]  = "Incapacitate", -- Thorium Grenade
		[19784]  = "Incapacitate", -- Dark Iron Bomb
		[30216]  = "Incapacitate", -- Fel Iron Bomb
		[30461]  = "Incapacitate", -- The Bigger One
		[30217]  = "Incapacitate", -- Adamantite Grenade
		[61025]  = "Incapacitate", -- Polymorph: Serpent
		[82691]  = "Incapacitate", -- Ring of Frost
		[115078] = "Incapacitate", -- Paralysis
		[76780]  = "Incapacitate", -- Bind Elemental
		[107079] = "Incapacitate", -- Quaking Palm (Racial)

		[47481]  = "Stun",     -- Gnaw (Ghoul Pet)
		[5211]   = "Stun",     -- Bash
		[22570]  = "Stun",     -- Maim
		[24394]  = "Stun",     -- Intimidation
		[50519]  = "Stun",     -- Sonic Blast
		[50518]  = "Stun",     -- Ravage
		[44572]  = "Stun",     -- Deep Freeze
		[853]    = "Stun",     -- Hammer of Justice
		--[2812]  = "Stun",      -- Holy Wrath
		[408]    = "Stun",     -- Kidney Shot
		[1833]   = "Stun",     -- Cheap Shot
		[58861]  = "Stun",     -- Bash (Spirit Wolves)
		[30283]  = "Stun",     -- Shadowfury
		[12809]  = "Stun",     -- Concussion Blow
		[60995]  = "Stun",     -- Demon Charge
		[30153]  = "Stun",     -- Pursuit
		[20253]  = "Stun",     -- Intercept Stun
		[46968]  = "Stun",     -- Shockwave
		[20549]  = "Stun",     -- War Stomp (Racial)
		[85388]  = "Stun",     -- Throwdown
		[90337]  = "Stun",     -- Bad Manner (Hunter Pet Stun)
		[91800]  = "Stun",     -- Gnaw (DK Pet Stun)
		[108194] = "Stun",     -- Asphyxiate
		[91797]  = "Stun",     -- Monstrous Blow (Dark Transformation Ghoul)
		[115001] = "Stun",     -- Remorseless Winter
		[102795] = "Stun",     -- Bear Hug
		[113801] = "Stun",     -- Bash (Treants)
		[117526] = "Stun",     -- Binding Shot
		[126246] = "Stun",     -- Lullaby (Crane pet) -- TODO: verify category
		[126423] = "Stun",     -- Petrifying Gaze (Basilisk pet) -- TODO: verify category
		[126355] = "Stun",     -- Quill (Porcupine pet) -- TODO: verify category
		[56626]  = "Stun",     -- Sting (Wasp)
		[118271] = "Stun",     -- Combustion
		[119392] = "Stun",     -- Charging Ox Wave
		[122242] = "Stun",     -- Clash
		[120086] = "Stun",     -- Fists of Fury
		[119381] = "Stun",     -- Leg Sweep
		[115752] = "Stun",     -- Blinding Light (Glyphed)
		[110698] = "Stun",     -- Hammer of Justice (Symbiosis)
		[119072] = "Stun",     -- Holy Wrath
		[105593] = "Stun",     -- Fist of Justice
		[118345] = "Stun",     -- Pulverize (Primal Earth Elemental)
		[118905] = "Stun",     -- Static Charge (Capacitor Totem)
		[89766]  = "Stun",     -- Axe Toss (Felguard)
		[22703]  = "Stun",     -- Inferno Effect
		[132168] = "Stun",     -- Shockwave
		[107570] = "Stun",     -- Storm Bolt
		[132169] = "Stun",     -- Storm Bolt
		[96201]  = "Stun",     -- Web Wrap
		[122057] = "Stun",     -- Clash
		[15618]  = "Stun",     -- Snap Kick
		[9005]   = "Stun",     -- Pounce
		[102546] = "Stun",     -- Pounce (MoP)
		[127361] = "Stun",     -- Bear Hug (Symbiosis)

		[16922]  = "RandomStun", -- Celestial Focus (Starfire Stun)
		[28445]  = "RandomStun", -- Improved Concussive Shot
		[12355]  = "RandomStun", -- Impact
		[20170]  = "RandomStun", -- Seal of Justice Stun
		[39796]  = "RandomStun", -- Stoneclaw Stun
		[12798]  = "RandomStun", -- Revenge Stun
		[5530]   = "RandomStun", -- Mace Stun Effect (Mace Specialization)
		[15283]  = "RandomStun", -- Stunning Blow (Weapon Proc)
		[56]     = "RandomStun", -- Stun (Weapon Proc)
		[34510]  = "RandomStun", -- Stormherald/Deep Thunder (Weapon Proc)
		[113953] = "RandomStun", -- Paralysis
		[118895] = "RandomStun", -- Dragon Roar
		[77505]  = "RandomStun", -- Earthquake
		[100]    = "RandomStun", -- Charge
		[118000] = "RandomStun", -- Dragon Roar

		[1513]   = "Fear",     -- Scare Beast
		[10326]  = "Fear",     -- Turn Evil
		[8122]   = "Fear",     -- Psychic Scream
		[2094]   = "Fear",     -- Blind
		[5782]   = "Fear",     -- Fear
		[130616] = "Fear",     -- Fear (Glyphed)
		[6358]   = "Fear",     -- Seduction (Succubus)
		[5484]   = "Fear",     -- Howl of Terror
		[5246]   = "Fear",     -- Intimidating Shout
		[5134]   = "Fear",     -- Flash Bomb Fear (Item)
		[113004] = "Fear",     -- Intimidating Roar (Symbiosis)
		[113056] = "Fear",     -- Intimidating Roar (Symbiosis 2)
		[145067] = "Fear",     -- Turn Evil (Evil is a Point of View)
		[113792] = "Fear",     -- Psychic Terror (Psyfiend)
		[118699] = "Fear",     -- Fear 2
		[115268] = "Fear",     -- Mesmerize (Shivarra)
		[104045] = "Fear",     -- Sleep (Metamorphosis) -- TODO: verify this is the correct category
		[20511]  = "Fear",     -- Intimidating Shout (secondary targets)

		[339]    = "Root",     -- Entangling Roots
		[19975]  = "Root",     -- Nature's Grasp
		[50245]  = "Root",     -- Pin
		[33395]  = "Root",     -- Freeze (Water Elemental)
		[122]    = "Root",     -- Frost Nova
		[39965]  = "Root",     -- Frost Grenade (Item)
		[63685]  = "Root",     -- Freeze (Frost Shock)
		[96294]  = "Root",     -- Chains of Ice (Chilblains Root)
		[113275] = "Root",     -- Entangling Roots (Symbiosis)
		[102359] = "Root",     -- Mass Entanglement
		[128405] = "Root",     -- Narrow Escape
		--[53148]  = "Root", -- Charge (Tenacity pet)
		[90327]  = "Root",     -- Lock Jaw (Dog)
		[54706]  = "Root",     -- Venom Web Spray (Silithid)
		[4167]   = "Root",     -- Web (Spider)
		[110693] = "Root",     -- Frost Nova (Symbiosis)
		[116706] = "Root",     -- Disable
		[87194]  = "Root",     -- Glyph of Mind Blast
		[114404] = "Root",     -- Void Tendrils
		[115197] = "Root",     -- Partial Paralysis
		[107566] = "Root",     -- Staggering Shout
		[113770] = "Root",     -- Entangling Roots
		[53148]  = "Root",     -- Charge
		[136634] = "Root",     -- Narrow Escape
		--[127797] = "PseudoRoot", -- Ursol's Vortex
		[81210]  = "Root",     -- Net
		[135373] = "Root",     -- Entrapment (MoP)
		[45334]  = "Root",     -- Immobilized (MoP)

		[12494]  = "RandomRoot", -- Frostbite
		[55080]  = "RandomRoot", -- Shattered Barrier
		[58373]  = "RandomRoot", -- Glyph of Hamstring
		[23694]  = "RandomRoot", -- Improved Hamstring
		[47168]  = "RandomRoot", -- Improved Wing Clip
		[19185]  = "RandomRoot", -- Entrapment
		[64803]  = "RandomRoot", -- Entrapment
		[111340] = "RandomRoot", -- Ice Ward
		[123407] = "RandomRoot", -- Spinning Fire Blossom
		[64695]  = "RandomRoot", -- Earthgrab Totem

		[53359]  = "Disarm",   -- Chimera Shot (Scorpid)
		[50541]  = "Disarm",   -- Clench
		[64058]  = "Disarm",   -- Psychic Horror Disarm Effect
		[51722]  = "Disarm",   -- Dismantle
		[676]    = "Disarm",   -- Disarm
		[91644]  = "Disarm",   -- Snatch (Bird of Prey)
		[117368] = "Disarm",   -- Grapple Weapon
		[126458] = "Disarm",   -- Grapple Weapon (Symbiosis)
		[137461] = "Disarm",   -- Ring of Peace (Disarm effect)
		[118093] = "Disarm",   -- Disarm (Voidwalker/Voidlord)

		[47476]  = "Silence",  -- Strangulate
		[34490]  = "Silence",  -- Silencing Shot
		[35334]  = "Silence",  -- Nether Shock (Rank 1)
		[44957]  = "Silence",  -- Nether Shock (Rank 2)
		[18469]  = "Silence",  -- Silenced - Improved Counterspell (Rank 1)
		[55021]  = "Silence",  -- Silenced - Improved Counterspell (Rank 2)
		[15487]  = "Silence",  -- Silence
		[1330]   = "Silence",  -- Garrote - Silence
		[18425]  = "Silence",  -- Silenced - Improved Kick
		[24259]  = "Silence",  -- Spell Lock
		[43523]  = "Silence",  -- Unstable Affliction 1
		[31117]  = "Silence",  -- Unstable Affliction 2
		[18498]  = "Silence",  -- Silenced - Gag Order (Shield Slam)
		[50613]  = "Silence",  -- Arcane Torrent (Racial, Runic Power)
		[28730]  = "Silence",  -- Arcane Torrent (Racial, Mana)
		[25046]  = "Silence",  -- Arcane Torrent (Racial, Energy)
		-- [108194] = "Silence", -- Asphyxiate (TODO: check silence id)
		[114238] = "Silence",  -- Glyph of Fae Silence
		[102051] = "Silence",  -- Frostjaw
		[137460] = "Silence",  -- Ring of Peace (Silence effect)
		[116709] = "Silence",  -- Spear Hand Strike
		[31935]  = "Silence",  -- Avenger's Shield
		[115782] = "Silence",  -- Optical Blast (Observer)
		[69179]  = "Silence",  -- Arcane Torrent (Racial, Rage)
		[80483]  = "Silence",  -- Arcane Torrent (Racial, Focus)

		[64044]  = "Horror",   -- Psychic Horror
		[6789]   = "Horror",   -- Death Coil
		[137143] = "Horror",   -- Blood Horror

		-- Spells that DR with itself only
		[33786]  = "Cyclone", -- Cyclone
		[113506] = "Cyclone", -- Cyclone (Symbiosis)
		[605]    = "MindControl", -- Mind Control
		[13181]  = "MindControl", -- Gnomish Mind Control Cap
		[67799]  = "MindControl", -- Mind Amplification Dish (Item)
		[7922]   = "Charge", -- Charge Stun

		-- *** Disorient Effects ***
		[99]     = "Disorient", -- Disorienting Roar
		[19503]  = "Disorient", -- Scatter Shot
		[31661]  = "Disorient", -- Dragon's Breath
		[123393] = "Disorient", -- Glyph of Breath of Fire
		[88625]  = "Disorient", -- Holy Word: Chastise


		-- Bonus cata ones
		-- *** Controlled Stun Effects ***
		[93433] = "Stun",   -- Burrow Attack (Worm)
		[83046] = "Stun",   -- Improved Polymorph (Rank 1)
		[83047] = "Stun",   -- Improved Polymorph (Rank 2)
		--[88625] = "Stun", -- Holy Word: Chastise
		[93986] = "Stun",   -- Aura of Foreboding
		[54786] = "Stun",   -- Demon Leap
		-- *** Non-controlled Stun Effects ***
		[85387] = "RandomStun", -- Aftermath

		-- *** Controlled Root Effects ***
		[96293] = "Root", -- Chains of Ice (Chilblains Rank 1)
		[87193] = "Root", -- Paralysis
		[55536] = "Root", -- Frostweave Net (Item)

		-- *** Non-controlled Root Effects ***
		[83301] = "RandomRoot", -- Improved Cone of Cold (Rank 1)
		[83302] = "RandomRoot", -- Improved Cone of Cold (Rank 2)
		[83073] = "RandomRoot", -- Shattered Barrier (Rank 2)

		[50479] = "Silence", -- Nether Shock (Nether Ray)
		[86759] = "Silence", -- Silenced - Improved Kick (Rank 2)
	}
end
drCategories = sArenaMixin.drCategories
sArenaMixin.drList = drList

function sArenaMixin:UpdateDRTimeSetting()
	if not self.db.profile.drResetTimeDEL then
		self.db.profile.drResetTime = 18.5
		self.db.profile.drResetTimeDEL = true
	end
    drTime = self.db.profile.drResetTime or (isRetail and 18.5 or 20)
end

function sArenaFrameMixin:FindDR(combatEvent, spellID)
	local category = drList[spellID]
	
	-- Check if this DR category is enabled (considering per-spec, per-class, or global settings)
	local categoryEnabled = false
	local db = self.parent.db.profile
	
	if db.drCategoriesPerSpec then
		local specKey = sArenaMixin.playerSpecID or 0
		local perSpec = db.drCategoriesSpec or {}
		local specCategories = perSpec[specKey] or {}
		categoryEnabled = specCategories[category] ~= nil and specCategories[category] or db.drCategories[category]
	elseif db.drCategoriesPerClass then
		local classKey = sArenaMixin.playerClass
		local perClass = db.drCategoriesClass or {}
		local classCategories = perClass[classKey] or {}
		categoryEnabled = classCategories[category] ~= nil and classCategories[category] or db.drCategories[category]
	else
		categoryEnabled = db.drCategories[category]
	end
	
	if not categoryEnabled then return end

	local frame = self[category]
	local currTime = GetTime()

	if (combatEvent == "SPELL_AURA_REMOVED" or combatEvent == "SPELL_AURA_BROKEN") then
        local startTime, startDuration = frame.Cooldown:GetCooldownTimes()
        startTime, startDuration = startTime/1000, startDuration/1000

        local newDuration = drTime / (1 - ((currTime - startTime) / startDuration))
        local newStartTime = drTime + currTime - newDuration

        frame:Show()
        frame.Cooldown:SetCooldown(newStartTime, newDuration)

        return
	elseif (combatEvent == "SPELL_AURA_APPLIED" or combatEvent == "SPELL_AURA_REFRESH") then
		local unit = self.unit

		for i = 1, 30 do
			local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")

            if auraData then
                if not auraData.spellId then break end

                if (auraData.duration and spellID == auraData.spellId) then
                    frame:Show()
                    frame.Cooldown:SetCooldown(currTime, auraData.duration + drTime)
                    break
                end
            end
		end
	end
	-- Determine which texture to use for the DR icon.
	local useStatic = self.parent.db.profile.drStaticIcons
	local usePerSpec = self.parent.db.profile.drStaticIconsPerSpec
	local usePerClass = self.parent.db.profile.drStaticIconsPerClass
	local textureID = nil

	if usePerSpec and useStatic then
		local perSpec = self.parent.db.profile.drIconsPerSpec
		local specKey = sArenaMixin.playerSpecID or 0
		if perSpec and perSpec[specKey] and perSpec[specKey][category] then
			textureID = perSpec[specKey][category]
		end
	elseif usePerClass and useStatic then
		local perClass = self.parent.db.profile.drIconsPerClass
		if perClass and perClass[sArenaMixin.playerClass] and perClass[sArenaMixin.playerClass][category] then
			textureID = perClass[sArenaMixin.playerClass][category]
		end
	end

	if not textureID and useStatic then
		textureID = self.parent.db.profile.drIcons[category]
	end

	if not textureID then
		textureID = GetSpellTexture(spellID)
	end

	frame.Icon:SetTexture(textureID)

	-- Check if black DR borders are enabled
	local layout = self.parent.db.profile.layoutSettings[self.parent.db.profile.currentLayout]
	local blackDRBorder = layout.dr and layout.dr.blackDRBorder
	local borderColor = blackDRBorder and {0, 0, 0, 1} or severityColor[frame.severity]
	local pixelBorderColor = blackDRBorder and {0, 0, 0, 1} or severityColor[frame.severity]

	frame.Border:SetVertexColor(unpack(borderColor))
    if frame.PixelBorder then
        frame.PixelBorder:SetVertexColor(unpack(pixelBorderColor))
    end
    if frame.__MSQ_New_Normal then
        frame.__MSQ_New_Normal:SetDesaturated(true)
        frame.__MSQ_New_Normal:SetVertexColor(unpack(severityColor[frame.severity]))
    end
	local drText = frame.DRTextFrame.DRText
	if drText then
		if frame.severity == 1 then
			drText:SetText("½")
		elseif frame.severity == 2 then
			drText:SetText("¼")
		else
			drText:SetText("%")
		end
		drText:SetTextColor(unpack(severityColor[frame.severity]))
	end

	frame.severity = frame.severity + 1
	if frame.severity > 3 then
		frame.severity = 3
	end
end


function sArenaFrameMixin:UpdateDRCooldownReverse()
    local reverse = self.parent.db.profile.invertDRCooldown
    for i = 1, #sArenaMixin.drCategories do
        local category = sArenaMixin.drCategories[i]
        local frame = self[category]
        if frame and frame.Cooldown then
            frame.Cooldown:SetReverse(reverse)
        end
    end
end

function sArenaFrameMixin:UpdateDRPositions()
	local layoutdb = self.parent.layoutdb
	local numActive = 0
	local frame, prevFrame
	local spacing = layoutdb.dr.spacing
	local growthDirection = layoutdb.dr.growthDirection

	for i = 1, #drCategories do
		frame = self[drCategories[i]]

		if (frame:IsShown()) then
			frame:ClearAllPoints()
			if (numActive == 0) then
				frame:SetPoint("CENTER", self, "CENTER", layoutdb.dr.posX, layoutdb.dr.posY)
			else
				if (growthDirection == 4) then
					frame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
				elseif (growthDirection == 3) then
					frame:SetPoint("LEFT", prevFrame, "RIGHT", spacing, 0)
				elseif (growthDirection == 1) then
					frame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
				elseif (growthDirection == 2) then
					frame:SetPoint("BOTTOM", prevFrame, "TOP", 0, spacing)
				end
			end
			numActive = numActive + 1
			prevFrame = frame
		end
	end
end

function sArenaFrameMixin:ResetDR()
	for i = 1, #drCategories do
		self[drCategories[i]].Cooldown:Clear()
	end
end