local isRetail = sArenaMixin.isRetail
local GetSpellTexture = GetSpellTexture or C_Spell.GetSpellTexture
local tooltipInfoAuras = {}

if isRetail then
    sArenaMixin.interruptList = {
        [1766]   = 3, -- Kick (Rogue)
        [2139]   = 5, -- Counterspell (Mage)
        [6552]   = 3, -- Pummel (Warrior)
        [19647]  = 5, -- Spell Lock (Warlock)
        [47528]  = 3, -- Mind Freeze (Death Knight)
        [57994]  = 2, -- Wind Shear (Shaman)
        [91802]  = 2, -- Shambling Rush (Death Knight)
        [96231]  = 3, -- Rebuke (Paladin)
        [106839] = 3, -- Skull Bash (Feral)
        [115781] = 5, -- Optical Blast (Warlock)
        [116705] = 3, -- Spear Hand Strike (Monk)
        [132409] = 5, -- Spell Lock (Warlock)
        [147362] = 3, -- Countershot (Hunter)
        [171138] = 5, -- Shadow Lock (Warlock)
        [183752] = 3, -- Consume Magic (Demon Hunter)
        [187707] = 3, -- Muzzle (Hunter)
        [212619] = 5, -- Call Felhunter (Warlock)
        [231665] = 3, -- Avengers Shield (Paladin)
        [351338] = 4, -- Quell (Evoker)
        [97547]  = 4, -- Solar Beam
    }

    -- Auras we want tooltip info from to display as stacks
    --tooltipInfoAuras = {}

    sArenaMixin.auraList = {
        -- Spell ID = Priority
        -- CCs
        [33786] = 9,  -- Cyclone (Disorient)
        [5211] = 9,   -- Mighty Bash (Stun)
        [108194] = 9, -- Asphyxiate (Unholy) (Stun)
        [221562] = 9, -- Asphyxiate (Blood) (Stun)
        [377048] = 9, -- Absolute Zero (Frost) (Stun)
        [91797] = 9,  -- Monstrous Blow (Mutated Ghoul) (Stun)
        [287254] = 9, -- Dead of Winter (Stun)
        [210141] = 9, -- Zombie Explosion (Stun)
        [118905] = 9, -- Static Charge (Stun)
        [1833] = 9,   -- Cheap Shot (Stun)
        [853] = 9,    -- Hammer of Justice (Stun)
        [179057] = 9, -- Chaos Nova (Stun)
        [132169] = 9, -- Storm Bolt (Stun)
        [408] = 9,    -- Kidney Shot (Stun)
        [163505] = 9, -- Rake (Stun)
        [119381] = 9, -- Leg Sweep (Stun)
        [89766] = 9,  -- Axe Toss (Stun)
        [30283] = 9,  -- Shadowfury (Stun)
        [24394] = 9,  -- Intimidation (Stun)
        [117526] = 9, -- Binding Shot (Stun)
        [357021] = 9, -- Consecutive Concussion (Stun)
        [211881] = 9, -- Fel Eruption (Stun)
        [91800] = 9,  -- Gnaw (Stun)
        [205630] = 9, -- Illidan's Grasp (Stun)
        [208618] = 9, -- Illidan's Grasp (Stun)
        [203123] = 9, -- Maim (Stun)
        [202244] = 9, -- Overrun
        [200200] = 9, -- Holy Word: Chastise, Censure Talent (Stun)
        [22703] = 9,  -- Infernal Awakening (Stun)
        [132168] = 9, -- Shockwave (Stun)
        [20549] = 9,  -- War Stomp (Stun)
        [199085] = 9, -- Warpath (Stun)
        [305485] = 9, -- Lightning Lasso (Stun)
        [64044] = 9,  -- Psychic Horror (Stun)
        [255723] = 9, -- Bull Rush (Stun)
        [202346] = 9, -- Double Barrel (Stun)
        [213688] = 9, -- Fel Cleave (Stun)
        [204399] = 9, -- Earthfury (Stun)
        [118345] = 9, -- Pulverize (Stun)
        [171017] = 9, -- Meteor Strike (Infernal) (Stun)
        [171018] = 9, -- Meteor Strike (Abyssal) (Stun)
        [46968] = 9,  -- Shockwave
        [287712] = 9, -- Haymaker (Stun)
        [372245] = 9, -- Terror of the Skies (stun)
        [389831] = 9, -- Snowdrift (Stun)

        -- Disorients
        [5246] = 9,   -- Intimidating Shout (Disorient)
        [316593] = 9, -- Intimidating Shout (Menace Main Target) (Disorient)
        [316595] = 9, -- Intimidating Shout (Menace Other Targets) (Disorient)
        [8122] = 9,   -- Psychic Scream (Disorient)
        [2094] = 9,   -- Blind (Disorient)
        [605] = 9,    -- Mind Control (Disorient)
        [105421] = 9, -- Blinding Light (Disorient)
        [207167] = 9, -- Blinding Sleet (Disorient)
        [31661] = 9,  -- Dragon's Breath (Disorient)
        [207685] = 9, -- Sigil of Misery (Disorient)
        [198909] = 9, -- Song of Chi-ji (Disorient)
        [202274] = 9, -- Incendiary Brew (Disorient)
        [130616] = 9, -- Fear (Warlock Horrify talent)
        [118699] = 9, -- Fear (Disorient)
        [1513] = 9,   -- Scare Beast (Disorient)
        [10326] = 9,  -- Turn Evil (Disorient)
        [6358] = 9,   -- Seduction (Disorient)
        [261589] = 9, -- Seduction 2 (Disorient)
        [5484] = 9,   -- Howl (Disorient)
        [115268] = 9, -- Mesmerize (Shivarra) (Disorient)
        [87204] = 9,  -- Sin and Punishment (Disorient)
        [2637] = 9,   -- Hibernate (Disorient)
        [226943] = 9, -- Mind Bomb (Disorient)
        [236748] = 9, -- Intimidating Roar (Disorient)
        [331866] = 9, -- Agent of Chaos (Disorient)
        [324263] = 9, -- Sulfuric Emission (Disorient)
        [360806] = 9, -- Sleep Walk (Disorient)
        [358861] = 9, -- Void Volley (Disorient)

        -- Incapacitates
        [51514] = 9,  -- Hex (Incapacitate)
        [211004] = 9, -- Hex: Spider (Incapacitate)
        [210873] = 9, -- Hex: Raptor (Incapacitate)
        [211015] = 9, -- Hex: Cockroach (Incapacitate)
        [211010] = 9, -- Hex: Snake (Incapacitate)
        [196942] = 9, -- Hex: Voodoo Totem (Incapacitate)
        [277784] = 9, -- Hex: Wicker Mongrel (Incapacitate)
        [277778] = 9, -- Hex: Zandalari Tendonripper (Incapacitate)
        [269352] = 9, -- Hex: Skeletal Hatchling (Incapacitate)
        [309328] = 9, -- Hex: Living Honey (Incapacitate)
        [118] = 9,    -- Polymorph (Incapacitate)
        [61305] = 9,  -- Polymorph: Black Cat (Incapacitate)
        [28272] = 9,  -- Polymorph: Pig (Incapacitate)
        [61721] = 9,  -- Polymorph: Rabbit (Incapacitate)
        [61780] = 9,  -- Polymorph: Turkey (Incapacitate)
        [28271] = 9,  -- Polymorph: Turtle (Incapacitate)
        [161353] = 9, -- Polymorph: Polar Bear Cub (Incapacitate)
        [126819] = 9, -- Polymorph: Porcupine (Incapacitate)
        [161354] = 9, -- Polymorph: Monkey (Incapacitate)
        [161355] = 9, -- Polymorph: Penguin (Incapacitate)
        [161372] = 9, -- Polymorph: Peacock (Incapacitate)
        [277792] = 9, -- Polymorph: Bumblebee (Incapacitate)
        [277787] = 9, -- Polymorph: Baby Direhorn (Incapacitate)
        [391622] = 9, -- Polymorph: Duck (Incapacitate)
        [383121] = 9, -- Mass Polymorph (Incapacitate)
        [3355] = 9,   -- Freezing Trap (Incapacitate)
        [203337] = 9, -- Freezing Trap, Diamond Ice Honor Talent (Incapacitate)
        [115078] = 9, -- Paralysis (Incapacitate)
        [213691] = 9, -- Scatter Shot (Incapacitate)
        [6770] = 9,   -- Sap (Incapacitate)
        [20066] = 9,  -- Repentance (Incapacitate)
        [200196] = 9, -- Holy Word: Chastise (Incapacitate)
        [221527] = 9, -- Imprison, Detainment Honor Talent (Incapacitate)
        [217832] = 9, -- Imprison (Incapacitate)
        [99] = 9,     -- Incapacitating Roar (Incapacitate)
        [82691] = 9,  -- Ring of Frost (Incapacitate)
        [1776] = 9,   -- Gouge (Incapacitate)
        [107079] = 9, -- Quaking Palm (Incapacitate)
        [236025] = 9, -- Enraged Maim (Incapacitate)
        [197214] = 9, -- Sundering (Incapacitate)
        [9484] = 9,   -- Shackle Undead (Incapacitate)
        [710] = 9,    -- Banish (Incapacitate)
        [6789] = 9,   -- Mortal Coil (Incapacitate)

        -- Immunities
        [456499] = 8, -- Absolute Serenity
        [473909] = 8, -- Ancient of Lore
        [378441] = 8, -- Time Stop
        [354610] = 8, -- Demon Hunter: Glimpse
        [642] = 8,    -- Divine Shield
        [186265] = 8, -- Aspect of the Turtle
        [45438] = 8,  -- Ice Block
        [196555] = 8, -- Demon Hunter: Netherwalk
        [47585] = 8,  -- Priest: Dispersion
        [377362] = 8, -- Precog
        [1022] = 8,   -- Blessing of Protection
        [204018] = 8, -- Blessing of Spellwarding
        [323524] = 8, -- Ultimate Form
        [216113] = 8, -- Way of the Crane
        [31224] = 8,  -- Cloak of Shadows
        [212182] = 8, -- Smoke Bomb
        [212183] = 8, -- Smoke Bomb
        [8178] = 8,   -- Grounding Totem Effect
        [199448] = 8, -- Blessing of Sacrifice
        [236321] = 8, -- War Banner
        [215769] = 8, -- Spirit of Redemption
        [5277] = 8,   -- Rogue: Evasion
        [227847] = 8, -- Warrior: Bladestorm (Arms)
        [118038] = 8, -- Warrior: Die by the Sword
        [357210] = 8, -- Deep Breath
        [359816] = 8, -- Dream Flight
        [408557] = 8, -- Phase Shift
        [408558] = 8, -- Phase Shift
        [362486] = 8, -- Keeper of the Grove
        [116849] = 8, -- Monk: Life Cocoon
        [212800] = 8, -- Demon Hunter: Blur
        [147833] = 8, -- Friendly Intervene
        [48792] = 8,  -- Death Knight: Icebound Fortitude
        [409293] = 8, -- Burrow

        -- Anti-CC / Immunity Buffs
        [23920] = 7,  -- Spell Reflection
        [213610] = 7, -- Priest: Holy Ward
        [212295] = 7, -- Warlock: Nether Ward
        [48707] = 7,  -- Death Knight: Anti-Magic Shell
        [410358] = 7, -- Death Knight: Anti-Magic Shell
        [5384] = 7,   -- Hunter: Feign Death
        [353319] = 7, -- Monk: Peaceweaver
        [378464] = 7, -- Evoker: Nullifying Shroud
        [31821] = 7,  -- Aura Mastery
        [206803] = 7, -- Rain from Above
        [131558] = 7, -- Shaman: Spiritwalker's Aegis

        -- Interrupts
        [1766] = 6,   -- Kick (Rogue)
        [2139] = 6,   -- Counterspell (Mage)
        [6552] = 6,   -- Pummel (Warrior)
        [19647] = 6,  -- Spell Lock (Warlock)
        [47528] = 6,  -- Mind Freeze (Death Knight)
        [57994] = 6,  -- Wind Shear (Shaman)
        [91802] = 6,  -- Shambling Rush (Death Knight)
        -- [96231] = 6, -- Rebuke (Paladin)
        [106839] = 6, -- Skull Bash (Feral)
        [115781] = 6, -- Optical Blast (Warlock)
        [116705] = 6, -- Spear Hand Strike (Monk)
        [132409] = 6, -- Spell Lock (Warlock)
        [147362] = 6, -- Countershot (Hunter)
        [171138] = 6, -- Shadow Lock (Warlock)
        [183752] = 6, -- Consume Magic (Demon Hunter)
        [187707] = 6, -- Muzzle (Hunter)
        [212619] = 6, -- Call Felhunter (Warlock)
        [231665] = 6, -- Avengers Shield (Paladin)
        [351338] = 6, -- Quell (Evoker)
        [97547] = 6,  -- Solar Beam

        -- Silences
        [202933] = 6,  -- Spider Sting
        [356727] = 6,  -- Spider Venom
        [1330] = 6,    -- Garrote
        [15487] = 6,   -- Silence
        [199683] = 6,  -- Last Word
        [47476] = 6,   -- Strangulate
        [31935] = 6,   -- Avenger's Shield
        [204490] = 6,  -- Sigil of Silence
        [217824] = 6,  -- Shield of Virtue
        [43523] = 6,   -- Unstable Affliction Silence 1
        [196364] = 6,  -- Unstable Affliction Silence 2
        [317589] = 6,  -- Tormenting Backlash
        [410065] = 6,  -- Reactive Resin
        [375901] = 6,  -- Mindgames
        [81261] = 5.5, -- Solar Beam

        -- Disarms
        [410126] = 5, -- Searing Glare
        [410201] = 5, -- Searing Glare
        [236077] = 5, -- Disarm
        [236236] = 5, -- Disarm (Protection)
        [209749] = 5, -- Faerie Swarm (Disarm)
        [233759] = 5, -- Grapple Weapon
        [207777] = 5, -- Dismantle

        -- Offensive Debuffs
        [383005] = 4.5, -- Chrono Loop
        [372048] = 4.5, -- Opressing Roar
        [356723] = 4.5, -- Scorpid Venom


        -- Roots
        [376080] = 4, -- Spear
        [105771] = 4, -- Charge
        [356356] = 4, -- Warbringer
        [324382] = 4, -- Clash
        [114404] = 4, -- Void Tendril's
        [356738] = 4, -- Earth Unleashed
        [288515] = 4, -- Surge of Power
        [339] = 4,    -- Entangling Roots
        [170855] = 4, -- Entangling Roots (Nature's Grasp)
        [201589] = 4, -- Entangling Roots (Tree of Life)
        [235963] = 4, -- Entangling Roots (Feral honor talent)
        [122] = 4,    -- Frost Nova
        [386770] = 4, -- Freezing Cold
        [102359] = 4, -- Mass Entanglement
        [64695] = 4,  -- Earthgrab
        [200108] = 4, -- Ranger's Net
        [212638] = 4, -- Tracker's Net
        [162480] = 4, -- Steel Trap
        [204085] = 4, -- Deathchill
        [233395] = 4, -- Frozen Center
        [233582] = 4, -- Entrenched in Flame
        [201158] = 4, -- Super Sticky Tar
        [33395] = 4,  -- Freeze
        [228600] = 4, -- Glacial Spike
        [116706] = 4, -- Disable
        [45334] = 4,  -- Immobilized
        [53148] = 4,  -- Charge (Hunter Pet)
        [190927] = 4, -- Harpoon
        [136634] = 4, -- Narrow Escape (unused?)
        [157997] = 4, -- Ice Nova
        [378760] = 4, -- Frostbite
        [241887] = 4, -- Landslide
        [355689] = 4, -- Landslide
        [393456] = 4, -- Entrapment

        -- Refreshments
        [167152] = 3.5, -- Mage Food
        [274914] = 3.5, -- Rockskip Mineral Water
        [396920] = 3.5, -- Delicious Dragon Spittle
        [369162] = 3.5, -- drink
        [452382] = 3.5, -- drink
        [461063] = 3.5, -- quiet contemplation (earthen dwarf racial)


        -- Offensive Buffs
        [51271] = 3,  -- Death Knight: Pillar of Frost
        -- [47568] = 3, -- Death Knight: Empower Rune Weapon
        [207289] = 3, -- Death Knight: Unholy Assault
        [162264] = 3, -- Demon Hunter: Metamorphosis
        [194223] = 3, -- Druid: Celestial Alignment
        [383410] = 3, -- Druid: Celestial Alignment (Orbital Strike)
        [102560] = 3, -- Druid: Incarnation: Chosen of Elune
        [390414] = 3, -- Druid: Incarnation: Chosen of Elune (Orbital Strike)
        [5217] = 3,   -- Tiger's Fury
        [102543] = 3, -- Druid: Incarnation: King of the Jungle
        [19574] = 3,  -- Hunter: Bestial Wrath
        [266779] = 3, -- Hunter: Coordinated Assault
        [288613] = 3, -- Hunter: Trueshot
        -- [260402] = 3, -- Hunter: Double Tap
        [365362] = 3, -- Mage: Arcane Surge
        [190319] = 3, -- Mage: Combustion
        [324220] = 3, -- Mage: Deathborne
        [198144] = 3, -- Mage: Ice Form
        [12472] = 3,  -- Mage: Icy Veins
        [80353] = 3,  -- Mage: Time Warp
        [152173] = 3, -- Monk: Serenity
        [137639] = 3, -- Monk: Storm, Earth, and Fire
        [31884] = 3,  -- Paladin: Avenging Wrath (Retribution)
        [152262] = 3, -- Paladin: Seraphim
        [231895] = 3, -- Paladin: Crusade
        [185313] = 3, -- Rogue: Shadow Dance
        [185422] = 3, -- Rogue: Shadow Dance
        [457333] = 3, -- Death's Arrival
        [197871] = 3, -- Priest: Dark Archangel
        [194249] = 3, -- Priest: Voidform
        [384631] = 3, -- Rogue: Flagellation
        [13750] = 3,  -- Rogue: Adrenaline Rush
        [121471] = 3, -- Rogue: Shadow Blades
        [114050] = 3, -- Shaman: Ascendance (Elemental)
        [114051] = 3, -- Shaman: Ascendance (Enhancement)
        [2825] = 3,   -- Shaman: Bloodlust
        [204361] = 3, -- Shaman: Bloodlust (Honor Talent)
        [32182] = 3,  -- Shaman: Heroism
        [204362] = 3, -- Shaman: Heroism (Honor Talent)
        [191634] = 3, -- Shaman: Stormkeeper
        [204366] = 3, -- Shaman: Thundercharge
        [113858] = 3, -- Warlock: Dark Soul: Instability
        [113860] = 3, -- Warlock: Dark Soul: Misery
        [399680] = 3, -- Soul Swap
        [442726] = 3, -- Malevolence
        [328774] = 3, -- Amp Curse
        [107574] = 3, -- Warrior: Avatar
        -- [260708] = 3, -- Warrior: Sweeping Strikes
        [262228] = 3, -- Warrior: Deadly Calm
        [1719] = 3,   -- Warrior: Recklessness
        [375087] = 3, -- Evoker: Dragonrage
        [370553] = 3, -- Evoker: Tip the Scales
        [10060] = 3,  -- Priest: Power Infusion
        [360952] = 3, -- Hunter: Coordinated Assault

        -- Defensive Buffs
        [199450] = 2.6, -- Ultimate Sacrifice
        [232707] = 2.5, -- Priest: Ray of Hope
        [232708] = 2.5, -- Ray of Hope
        [49039] = 2.5,  -- Death Knight: Lichborne
        [145629] = 2.5, -- Death Knight: Anti-Magic Zone
        [81256] = 2.5,  -- Death Knight: Dancing Rune Weapon
        [55233] = 2.5,  -- Death Knight: Vampiric Blood

        [188499] = 2.5, -- Demon Hunter: Blade Dance
        [209426] = 2.5, -- Demon Hunter: Darkness

        [132158] = 2.5, -- Druid: NS
        [22842] = 2.5,  -- Frenzied Regen
        [102342] = 2.5, -- Druid: Ironbark
        [22812] = 2.5,  -- Druid: Barkskin
        [61336] = 2.5,  -- Druid: Survival Instincts
        [117679] = 2.5, -- Druid: Incarnation: Tree of Life
        [236696] = 2.5, -- Druid: Thorns
        [305497] = 2.5, -- Druid: Thorns
        [29166] = 2.5,  -- Innervate

        [53480] = 2.5,  -- Hunter: Roar of Sacrifice
        [202748] = 2.5, -- Survival Tactics

        [113862] = 2.5, -- Greater Invisibility
        [198111] = 2.5, -- Mage: Temporal Shield
        [342246] = 2.5, -- Mage: Alter Time (Arcane)
        [110909] = 2.5, -- Mage: Alter Time (Fire, Frost)

        [125174] = 2.5, -- Monk: Touch of Karma
        [209584] = 2.5, -- Zen Focus Tea
        [120954] = 2.5, -- Monk: Fortifying Brew
        [122783] = 2.5, -- Monk: Diffuse Magic
        [122278] = 2.5, -- Dampen Harm

        [228050] = 2.5, -- Paladin: Guardian of the Forgotten Queen
        [86659] = 2.5,  -- Paladin: Guardian of Ancient Kings
        [210256] = 2.5, -- Paladin: Blessing of Sanctuary
        [6940] = 2.5,   -- Paladin: Blessing of Sacrifice
        [184662] = 2.5, -- Paladin: Shield of Vengeance
        [31850] = 2.5,  -- Paladin: Ardent Defender
        [210294] = 2.5, -- Paladin: Divine Favor
        [216331] = 2.5, -- Paladin: Avenging Crusader
        [31842] = 2.5,  -- Paladin: Avenging Wrath (Holy)
        [205191] = 2.5, -- Paladin: Eye for an Eye
        [498] = 2.5,    -- Paladin: Divine Protection
        [289655] = 2.5, -- Sanctified Ground

        [47788] = 2.5,  -- Priest: Guardian Spirit
        [33206] = 2.5,  -- Priest: Pain Suppression
        [81782] = 2.5,  -- Priest: Power Word: Barrier
        [15286] = 2.5,  -- Priest: Vampiric Embrace
        [19236] = 2.5,  -- Priest: Desperate Prayer
        [197862] = 2.5, -- Priest: Archangel
        [47536] = 2.5,  -- Priest: Rapture
        [271466] = 2.5, -- Priest: Luminous Barrier

        [207736] = 2.5, -- Rogue: Shadowy Duel
        [199754] = 2.5, -- Rogue: Riposte

        [378081] = 2.5, -- Shaman: NS
        [108271] = 2.5, -- Shaman: Astral Shift
        [114052] = 2.5, -- Shaman: Ascendance (Restoration)
        [108281] = 2.5, -- Ancestral Guidance

        [104773] = 2.5, -- Warlock: Unending Resolve
        [108416] = 2.5, -- Warlock: Dark Pact

        [12975] = 2.5,  -- Warrior: Last Stand
        [871] = 2.5,    -- Warrior: Shield Wall
        [213871] = 2.5, -- Warrior: Bodyguard
        [184364] = 2.5, -- Enraged Regeneration
        [345231] = 2.5, -- Trinket: Gladiator's Emblem
        [197690] = 2.5, -- Warrior: Defensive Stance

        [370960] = 2.5, -- Evoker: Emerald Communion
        [363916] = 2.5, -- Evoker: Obsidian Scales
        [406789] = 2.5, -- Paradox 1
        [406732] = 2.5, -- Paradox 2
        [374348] = 2.5, -- Evoker: Renewing Blaze
        [357170] = 2.5, -- Evoker: Time Dilation

        [201633] = 2.5, -- Earthen Wall
        [234084] = 2.5, -- Moon and Stars
        [281195] = 2.5, -- Survival of the Fittest

        -- Miscellaneous
        [172865] = 2.4, -- Stone Bulwark
        [320224] = 2.4, -- Podtender
        [327140] = 2.4, -- Forgeborne
        [188501] = 2.4, -- Spectral Sight
        [305395] = 2.4, -- Blessing of Freedom (Unbound Freedom)
        [1044] = 2.4,   -- Blessing of Freedom
        [54216] = 2.4,  -- Master's Call
        [41425] = 2.4,  -- Hypothermia
        [66] = 2.4,     -- Invisibility fade effect
        [96243] = 2.4,  -- Invisibility invis effect?
        [110960] = 2.4, -- Greater Invisibility
        [198158] = 2.4, -- Mass Invisibility
        [390612] = 2.4, -- Frost Bomb
        [205021] = 2.4, -- Ray of Frost
        [235450] = 2.4, -- Prismatic Barrier
        [127797] = 2.4, -- Vortex
        [342242] = 2.4, -- Time Warp

        -- Mobility
        [384100] = 2.3, -- Berserker Shout
        [48265] = 2.3,  -- Death Advance
        [1850] = 2.3,   -- Dash
        [106898] = 2.3, -- Stampeding Roar
        [77761] = 2.3,  -- Stampeding Roar
        [2983] = 2.3,   -- Sprint
        [358267] = 2.3, -- Hover
        [202163] = 2.3, -- Bounding Stride
        [190784] = 2.3, -- Divine Steed
        [393897] = 2.3, -- Tireless Pursuit
        [319454] = 2.3, -- Heart of the Wild (hotw)
        [109215] = 2.3, -- Posthaste
        [446044] = 2.3, -- Relentless Pursuit
        [202164] = 2.3, -- Heroic Leap speed buff

        -- Misc 2
        [212431] = 2, -- Explosive Shot
        [382440] = 2, -- Shifting Power
        [394087] = 2, -- Mayhem
        [431177] = 2, -- Frostfire Empowerement
        [455679] = 2, -- Embral Lattice
        [333889] = 2, -- Fel Dom
        [383269] = 2, -- Abo Limb
        [114108] = 2, -- Soul of the Forest
        [20594] = 2,  -- Stone Form
        [393903] = 2, -- Ursine Vigor
        [263165] = 2, -- Void Torrent
        [199845] = 2, -- Psyfiend
        [210824] = 2, -- Touch of the Magi
        [319504] = 2, -- Shiv
        [410598] = 2, -- Soul Rip
        [329543] = 2, -- Divine Ascension
        [236273] = 2, -- Duel
        [77606] = 2,  -- Dark Sim
        [12323] = 2,  -- Piercing Howl
        [274838] = 2, -- Feral Frenzy
        [80240] = 2,  -- Havoc
        [25771] = 2,  -- Forbearance
        [391528] = 2, -- Convoke
        [51690] = 2,  -- Killing Spree
        [200183] = 2, -- Apotheosis
        [212552] = 2, -- Wraith Walk
        [256948] = 2, -- Spatial Rift
        [208963] = 2, -- Totem of Wrath

        -- Thoughtstolen Variants
        [322459] = 2, -- Thoughtstolen (Shaman)
        [322464] = 2, -- Thoughtstolen (Mage)
        [322442] = 2, -- Thoughtstolen (Druid)
        [322462] = 2, -- Thoughtstolen (Priest - Holy)
        [322457] = 2, -- Thoughtstolen (Paladin)
        [322463] = 2, -- Thoughtstolen (Warlock)
        [322461] = 2, -- Thoughtstolen (Priest - Discipline)
        [322458] = 2, -- Thoughtstolen (Monk)
        [394902] = 2, -- Thoughtstolen (Evoker)
        [322460] = 2, -- Thoughtstolen (Priest - Shadow)

        [389714] = 2, -- Displacement Beacon
        [394112] = 2, -- Escape from Reality

        -- Druid Forms
        [768] = 1,    -- Cat form
        [783] = 1,    -- Travel form
        [5487] = 1,   -- Bear form
        [197625] = 1, -- Moonkin Form
    }
else
    sArenaMixin.interruptList = {
        [1766] = 5, -- Kick (Rogue)
        [2139] = 6, -- Counterspell (Mage)
        [6552] = 4, -- Pummel (Warrior)
        [132409] = 6, -- Spell Lock (Warlock)
        [19647] = 6, -- Spell Lock (Warlock, pet)
        [47528] = 4, -- Mind Freeze (Death Knight)
        [57994] = 3, -- Wind Shear (Shaman)
        [91807] = 2, -- Shambling Rush (Death Knight)
        [96231] = 4, -- Rebuke (Paladin)
        [93985] = 4, -- Skull Bash (Druid)
        [116705] = 4, -- Spear Hand Strike (Monk)
        [147362] = 3, -- Counter Shot (Hunter)
        [31935] = 3, -- Avenger's Shield (Paladin)
        [78675] = 5, -- Solar Beam
        [113286] = 5, -- Solar Beam (Symbiosis)
        [26679] = 5, -- Deadly Throw (Rogue) (4-6 sec interrupt depending on combos(3-5))

        [33871] = 8, -- Shield Bash (Warrior)
        [24259] = 6, -- Spell Lock (Warlock)
        [43523] = 5, -- Unstable Affliction (Warlock)
        --[16979] = 4, 	-- Feral Charge (Druid)
        [119911] = 6, -- Optical Blast (Warlock Observer)
        [115781] = 6, -- Optical Blast (Warlock Observer)
        [102060] = 4, -- Disrupting Shout
        [26090] = 2, -- Pummel (Gorilla)
        [50479] = 2, -- Nethershock
        [97547] = 5, -- Solar Beam
    }

    -- Auras we want tooltip info from to display as stacks
    tooltipInfoAuras = {
        [115867] = true, -- Mana Tea
        [1247275] = true, -- Tigereye Brew
    }

    sArenaMixin.auraList = {
        -- Special
        [122465] = 10, -- Dematerialize
        [114028] = 10, -- Mass Spell Reflection
        [23920]  = 10, -- Spell Reflection
        [113002] = 10, -- Spell Reflection (Symbiosis)
        [8178]   = 10, -- Grounding Totem Effect

        -- Full CC (Stuns and Disorients)
        [33786]  = 9, -- Cyclone (Disorient)
        --[58861] = 9,  -- Bash (Spirit Wolves) --not mop
        [5211]   = 9, -- Bash
        [6789]   = 9, -- Death Coil
        [1833]   = 9, -- Cheap Shot
        [7922]   = 9, -- Charge Stun
        --[12809] = 9,  -- Concussion Blow --not mop
        [44572]  = 9, -- Deep Freeze
        --[60995] = 9,  -- Demon Charge --not mop
        [47481]  = 9, -- Gnaw
        [853]    = 9, -- Hammer of Justice
        --[85388] = 9,  -- Throwdown --not mop
        [90337]  = 9, -- Bad Manner
        --[20253] = 9,  -- Intercept --not mop
        [30153]  = 9, -- Pursuit
        [24394]  = 9, -- Intimidation
        [408]    = 9, -- Kidney Shot
        [22570]  = 9, -- Maim
        [9005]   = 9, -- Pounce
        [64058]  = 9, -- Psychic Horror
        [6572]   = 9, -- Ravage
        [30283]  = 9, -- Shadowfury
        [46968]  = 9, -- Shockwave
        --[39796] = 9,  -- Stoneclaw Stun --not mop
        [20549]  = 9, -- War Stomp
        [61025]  = 9, -- Polymorph: Serpent
        [82691]  = 9, -- Ring of Frost
        [115078] = 9, -- Paralysis
        [76780]  = 9, -- Bind Elemental
        [107079] = 9, -- Quaking Palm (Racial)
        [99]     = 9, -- Disorienting Roar
        [123393] = 9, -- Glyph of Breath of Fire
        [108194] = 9, -- Asphyxiate
        [91797]  = 9, -- Monstrous Blow (Dark Transformation)
        [113801] = 9, -- Bash (Treants)
        [117526] = 9, -- Binding Shot
        [56626]  = 9, -- Sting (Wasp)
        [50519]  = 9, -- Sonic Blast
        [118271] = 9, -- Combustion Impact
        [119392] = 9, -- Charging Ox Wave
        [122242] = 9, -- Clash (Symbiosis)
        [122057] = 9, -- Clash
        [120086] = 9, -- Fists of Fury
        [119381] = 9, -- Leg Sweep
        [115752] = 9, -- Blinding Light (Glyphed)
        [110698] = 9, -- Hammer of Justice (Symbiosis)
        [119072] = 9, -- Holy Wrath
        [105593] = 9, -- Fist of Justice
        [118345] = 9, -- Pulverize (Primal Earth Elemental)
        [118905] = 9, -- Static Charge (Capacitor Totem)
        [89766]  = 9, -- Axe Toss (Felguard)
        [22703]  = 9, -- Inferno Effect
        [107570] = 9, -- Storm Bolt
        [132169] = 9, -- Storm Bolt
        [113004] = 9, -- Intimidating Roar (Symbiosis)
        [113056] = 9, -- Intimidating Roar (Symbiosis 2)
        [118699] = 9, -- Fear (alt ID)
        [113792] = 9, -- Psychic Terror (Psyfiend)
        [115268] = 9, -- Mesmerize (Shivarra)
        [104045] = 9, -- Sleep (Metamorphosis)
        [20511]  = 9, -- Intimidating Shout (secondary)
        [96201]  = 9, -- Web Wrap
        [132168] = 9, -- Shockwave
        [118895] = 9, -- Dragon Roar
        [115001] = 9, -- Remorseless Winter
        [102795] = 9, -- Bear Hug
        [77505]  = 9, -- Earthquake
        [15618]  = 9, -- Snap Kick
        [113953] = 9, -- Paralysis
        [137143] = 9, -- Blood Horror
        [87204]  = 9, -- Sin and Punishment
        [127361] = 9, -- Bear Hug (Symbiosis)

        -- Stun Procs
        [34510]  = 9, -- Stun (various procs)
        --[12355] = 9,  -- Impact --not mop
        [23454]  = 9, -- Stun

        -- Disorient / Incapacitate / Fear / Charm
        [2094]   = 9, -- Blind
        [31661]  = 9, -- Dragon's Breath
        [5782]   = 9, -- Fear
        [130616] = 9, -- Fear (Glyphed)
        [3355]   = 9, -- Freezing Trap
        [1776]   = 9, -- Gouge
        [51514]  = 9, -- Hex
        [2637]   = 9, -- Hibernate
        [5484]   = 9, -- Howl of Terror
        [49203]  = 9, -- Hungering Cold
        [5246]   = 9, -- Intimidating Shout
        [605]    = 9, -- Mind Control
        [118]    = 9, -- Polymorph
        [28271]  = 9, -- Polymorph: Turtle
        [28272]  = 9, -- Polymorph: Pig
        [61721]  = 9, -- Polymorph: Rabbit
        [61780]  = 9, -- Polymorph: Turkey
        [61305]  = 9, -- Polymorph: Black Cat
        [8122]   = 9, -- Psychic Scream
        [20066]  = 9, -- Repentance
        [6770]   = 9, -- Sap
        [1513]   = 9, -- Scare Beast
        [19503]  = 9, -- Scatter Shot
        [6358]   = 9, -- Seduction
        [9484]   = 9, -- Shackle Undead
        [1090]   = 9, -- Sleep
        [10326]  = 9, -- Turn Evil
        [145067] = 9, -- Turn Evil
        [19386]  = 9, -- Wyvern Sting
        [88625]  = 9, -- Chastise
        [710]    = 9, -- Banish
        [105421] = 9, -- Blinding Light
        [113506] = 9, -- Cyclone (Symbiosis)
        [126355] = 9, -- Paralyzing Quill
        [126246] = 9, -- Lullaby
        [91800]  = 9, -- Gnaw (Ghoul stun)
        [64044]  = 9, -- Psychic Horror (alt ID)
        [31117]  = 9, -- UA silence (on dispel)
        [126423] = 9, -- Petrifying Gaze (Basilisk pet) -- TODO: verify category
        [102546] = 9, -- Pounce

        -- Immunities
        [115760] = 7, -- Glyph of Ice Block, Immune to Spells
        [46924]  = 7, -- Bladestorm
        [19263]  = 7, -- Deterrence
        [110617] = 7, -- Deterrence (Symbiosis)
        [47585]  = 7, -- Dispersion
        [110715] = 7, -- Dispersion (Symbiosis)
        [642]    = 7, -- Divine Shield
        [110700] = 7, -- Divine Shield (Symbiosis)
        [498]    = 7, -- Divine Protection
        [45438]  = 7, -- Ice Block
        [110696] = 7, -- Ice Block (Symbiosis)
        [34692]  = 7, -- The Beast Within
        [26064]  = 7, -- Shell Shield
        [19574]  = 7, -- Bestial Wrath
        [1022]   = 7, -- Hand of Protection
        [3169]   = 7, -- Invulnerability
        --[20230]  = 7, -- Retaliation --not mop
        [16621]  = 7, -- Self Invulnerability
        [92681]  = 7, -- Phase Shift
        [20594]  = 7, -- Stoneform -- FIX
        [31224]  = 7, -- Cloak of Shadows
        [110788] = 7, -- Cloak of Shadows (Symbiosis)
        [27827]  = 7, -- Spirit of Redemption
        [49039]  = 7, -- Lichborne
        [148467] = 7, -- Deterrence

        [12043]  = 6.6, -- Presence of Mind
        [132158] = 6.6, -- Natures's Swiftness
        [16188]  = 6.6, -- Nature's Swiftness

        -- Anti-CCs
        [115018] = 6.5, -- Desecrated Ground (All CC Immunity)
        [48707]  = 6.5, -- Anti-Magic Shell
        [110570] = 6.5, -- Anti-Magic Shell (Symbiosis)
        [137562] = 6.5, -- Nimble Brew
        [6940]   = 6.5, -- Hand of Sacrifice
        [5384]   = 6.5, -- Feign Death
        [34471]  = 6.5, -- The Beast Within

        -- Silences
        [25046]  = 6, -- Arcane Torrent
        [1330]   = 6, -- Garrote
        [15487]  = 6, -- Silence (Priest)
        [18498]  = 6, -- Silenced - Gag Order (Warrior)
        --[18469] = 6, -- Silenced - Improved Counterspell (Mage)--not mop
        [55021]  = 6, -- Silenced - Improved Counterspell (Mage alt)
        --[18425] = 6, -- Silenced - Improved Kick (Rogue) --not mop
        [34490]  = 6, -- Silencing Shot (Hunter)
        [24259]  = 6, -- Spell Lock (Felhunter)
        [47476]  = 6, -- Strangulate (Death Knight)
        [43523]  = 6, -- Unstable Affliction (Silence effect)
        [114238] = 6, -- Glyph of Fae Silence
        [102051] = 6, -- Frostjaw
        [137460] = 6, -- Ring of Peace (Silence)
        [115782] = 6, -- Optical Blast (Observer)
        [50613]  = 6, -- Arcane Torrent (Runic Power)
        [28730]  = 6, -- Arcane Torrent (Mana)
        [69179]  = 6, -- Arcane Torrent (Rage)
        [80483]  = 6, -- Arcane Torrent (Focus)
        [31935]  = 6, -- Avenger's Shield
        [116709] = 6, -- Spear Hand Strike
        [142895] = 6, -- Silence (Ring of Peace?)

        [1766]   = 6, -- Kick (Rogue)
        [2139]   = 6, -- Counterspell (Mage)
        [6552]   = 6, -- Pummel (Warrior)
        [19647]  = 6, -- Spell Lock (Warlock)
        [47528]  = 6, -- Mind Freeze (Death Knight)
        [57994]  = 6, -- Wind Shear (Shaman)
        [91802]  = 6, -- Shambling Rush (Death Knight)
        -- [96231] = 6, -- Rebuke (Paladin) -- intentionally commented out
        [106839] = 6, -- Skull Bash (Feral)
        [115781] = 6, -- Optical Blast (Warlock)
        [116705] = 6, -- Spear Hand Strike (Monk)
        [132409] = 6, -- Spell Lock (Warlock)
        [147362] = 6, -- Countershot (Hunter)
        --[171138] = 6, -- Shadow Lock (Warlock) --not mop
        --[183752] = 6, -- Consume Magic (Demon Hunter) --not mop
        --[187707] = 6, -- Muzzle (Hunter) -- not mop
        --[212619] = 6, -- Call Felhunter (Warlock) --not mop
        --[231665] = 6, -- Avenger's Shield (Paladin) --not mop
        --[351338] = 6, -- Quell (Evoker) --not mop
        [97547]  = 6, -- Solar Beam
        [113286] = 6, -- Solar Beam
        [78675]  = 6, -- Solar Beam
        [81261]  = 6, -- Solar Beam

        -- Disarms
        [676]    = 5, -- Disarm
        [15752]  = 5, -- Disarm
        --[14251]  = 5, -- Riposte --not mop
        [51722]  = 5, -- Dismantle
        [50541]  = 5, -- Clench (Scorpid)
        [91644]  = 5, -- Snatch (Bird of Prey)
        [117368] = 5, -- Grapple Weapon
        [126458] = 5, -- Grapple Weapon (Symbiosis)
        [137461] = 5, -- Ring of Peace (Disarm)
        [118093] = 5, -- Disarm (Voidwalker/Voidlord)
        [142896] = 5, -- Disarmed
        [116844] = 5, -- Ring of Peace (Silence / Disarm)

        -- Important Stuff
        [116849] = 4.5, -- life Cocoon
        [110575] = 4.5, -- Icebound Fortitude (Druid)
        [48792]  = 4.5, -- Icebound Fortitude
        [122783] = 4.5, -- Diffuse Magic
        [122470] = 4.5, -- Touch of Karma
        --[378081] = 4.5, -- Natures's Swiftness --not mop

        -- Roots
        [339]    = 4, -- Entangling Roots
        [19975]  = 4, -- Entangling Roots (Nature's Grasp talent)
        [25999]  = 4, -- Boar Charge
        [4167]   = 4, -- Web
        [122]    = 4, -- Frost Nova
        [33395]  = 4, -- Freeze (Water Elemental)
        [96294]  = 4, -- Chains of Ice (Chilblains)
        [113275] = 4, -- Entangling Roots (Symbiosis)
        [113770] = 4, -- Entangling Roots (Treant)
        [102359] = 4, -- Mass Entanglement
        [128405] = 4, -- Narrow Escape
        [90327]  = 4, -- Lock Jaw (Dog)
        [54706]  = 4, -- Venom Web Spray (Silithid)
        [50245]  = 4, -- Pin (Crab)
        [110693] = 4, -- Frost Nova (Symbiosis)
        [116706] = 4, -- Disable
        [87194]  = 4, -- Glyph of Mind Blast
        [114404] = 4, -- Void Tendrils
        [115197] = 4, -- Partial Paralysis
        [63685]  = 4, -- Freeze (Frost Shock)
        [107566] = 4, -- Staggering Shout
        [115757] = 4, -- Frost nova
        [105771] = 4, -- Warbringer
        [53148]  = 4, -- Charge
        [136634] = 4, -- Narrow Escape
        --[127797] = 4, -- Ursol's Vortex
        [81210]  = 4, -- Net
        [35963]  = 4, -- Improved Wing Clip
        [19185]  = 4, -- Entrapment
        --[23694]  = 4, -- Improved Hamstring --not mop
        [64803]  = 4, -- Entrapment
        [111340] = 4, -- Ice Ward
        [123407] = 4, -- Spinning Fire Blossom
        [64695]  = 4, -- Earthgrab Totem
        [91807]  = 4, -- Shambling Rush
        [135373] = 4, -- Entrapment
        [45334]  = 4, -- Immobilized

        -- Defensive Buffs
        [115610] = 3.5, -- Temporal Shield
        [147833] = 3.4, -- Intervene
        [114029] = 3.4, -- Safeguard
        [3411]   = 3.4, -- Intervene
        [122292] = 3.4, -- Intervene (Symbiosis)
        [53476]  = 3.4, -- Intervene (Hunter Pet)
        [111264] = 3.3, -- Ice Ward (Buff)
        [89485]  = 3.3, -- Inner Focus (instant cast immunity)
        [113862] = 3.3, -- Greater Invisibility (90% dmg reduction)
        [111397] = 3.3, -- Blood Horror (flee on attack)
        [45182]  = 3.2, -- Cheating Death (85% reduced inc dmg)
        [31821]  = 3.2, -- Aura Mastery
        [53480]  = 3.1, -- Roar of Sacrifice
        [124280] = 3, -- Touch of Karma
        [871]    = 3, -- Shield Wall
        [118038] = 3, -- Die by the Sword
        [33206]  = 3, -- Pain Suppresion
        [47788]  = 3, -- Guardian Spirit
        --[47000]  = 3, -- Improved Blink --not mop
        [5277]   = 3, -- Evasion
        [126456] = 3, -- Fortifying Brew (Symbiosis)
        [110791] = 3, -- Evasion (Symbiosis)
        [122291] = 3, -- Unending Resolve (Symbiosis)
        [30823]  = 3, -- Shamanistic Rage
        [18499]  = 3, -- Berserker Rage
        [55694]  = 3, -- Enraged Regeneration
        [31842]  = 3, -- Divine Favor
        [1044]   = 3, -- Hand of Freedom
        [22812]  = 3, -- Barkskin
        [47484]  = 3, -- Huddle
        [97463]  = 3, -- Rallying Cry
        [86669]  = 3, -- Guardian of Ancient Kings
        [108359] = 3, -- Dark Regeneration
        [108416] = 3, -- Sacrificial Pact
        [104773] = 3, -- Unending Resolve
        [110913] = 3, -- Dark Bargain
        [79206]  = 3, -- Spiritwalker's Grace (movement casting)
        [108271] = 3, -- Astral Shift
        [108281] = 3, -- Ancestral Guidance (healing)
        [31616]  = 3, -- Nature’s Guardian
        [114052] = 3, -- Ascendance (Restoration)
        [61336]  = 3, -- Survival Instincts
        [106922] = 3, -- Might of Ursoc
        [122278] = 3, -- Dampen Harm
        [120954] = 3, -- Fortifying Brew
        [115176] = 3, -- Zen Meditation
        [81782]  = 3, -- Power Word: Barrier
        [109964] = 2.9, -- Spirit Shell (Buff)
        [102342] = 2.9, -- Ironbark
        [50461]  = 2.9, -- Anti-Magic Zone
        [29166]  = 2.9, -- Innervate
        [114908] = 2.8, -- Spirit Shell (Absorb Shield)
        [64901]  = 2.8, -- Hymn of Hope
        [98007]  = 2.8, -- Spirit Link Totem
        [114214] = 2, -- Angelic Bulwark
        [114893] = 2, -- Stone Bulwark Totem
        [145629] = 2, -- Anti-Magic Zone
        [117679] = 2, -- Incarnation: Tree of Life

        -- Offensive Buffs
        [13750]  = 2, -- Adrenaline Rush
        [12042]  = 2, -- Arcane Power
        [31884]  = 2, -- Avenging Wrath
        [34936]  = 2, -- Backlash
        [50334]  = 2, -- Berserk
        [2825]   = 2, -- Bloodlust
        [12292]  = 2, -- Death Wish
        [16166]  = 2, -- Elemental Mastery
        [12051]  = 2, -- Evocation
        [12472]  = 2, -- Icy Veins
        [131078] = 2, -- Icy Veins (split)
        [32182]  = 2, -- Heroism
        [51690]  = 2, -- Killing Spree
        [17941]  = 2, -- Shadow Trance
        [10060]  = 2, -- Power Infusion
        [3045]   = 2, -- Rapid Fire
        [1719]   = 2, -- Recklessness
        [51713]  = 2, -- Shadow Dance
        [107574] = 2, -- Avatar
        [121471] = 2, -- Shadow Blades
        [105809] = 2, -- Holy Avenger
        [86698]  = 2, -- Guardian of Ancient Kings (alt)
        [113858] = 2, -- Dark Soul: Instability
        [113860] = 2, -- Dark Soul: Misery
        [113861] = 2, -- Dark Soul: Knowledge
        [114050] = 2, -- Ascendance (Enhancement)
        [114051] = 2, -- Ascendance (Elemental)
        [102543] = 2, -- Incarnation: King of the Jungle
        [102560] = 2, -- Incarnation: Chosen of Elune
        [106951] = 2, -- Berserk
        [124974] = 2, -- Nature’s Vigil
        [51271]  = 2, -- Pillar of Frost
        [49206]  = 2, -- Summon Gargoyle
        [114868] = 2, -- Soul Reaper (Buff)
        [137639] = 2, -- Storm, Earth, and Fire
        [12328]  = 2, -- Sweeping Strikes
        [84747]  = 1.9, -- Deep Insight (Red Buff Rogue)
        [1247275] = 1.9, -- Tigereye Brew (Monk)


        [76577] = 1.8, -- Smoke Bomb
        [88611] = 1.8, -- Smoke Bomb

        -- Freedoms
        [96268] = 1.4, -- Deaths Advance
        [62305] = 1.4, -- Master's Call

        -- Lesser defensives
        [1966]  = 1.3, -- Feint
        --[102351] = 1.2, -- Cenarion Ward
        --[33763] = 1.1, -- Lifebloom
        --[121279] = 1.1, -- Lifebloom


        -- Misc
        [34709]  = 0.9, -- Shadow Sight (Arena Eye)
        [110806] = 0.9, -- Spirit Walker's Grace (Symbiosis)
        [11426]  = 0.8, -- Ice Barrier
        [113656] = 0.8, -- Fists of Fury
        [83853]  = 0.8, -- Combustion (Debuff)
        [77616]  = 0.7, -- Dark Simulacrum (Buff, has spell)
        [44544]  = 0.6, -- Fingers of Frost
        [41635]  = 0.5, -- Prayer of Mending
        [64844]  = 0.5, -- Divine Hymn
        [116841] = 0.5, -- Tiger's Lust (70% speed)
        [114896] = 0.5, -- Windwalk Totem
        [114206] = 0.5, -- Skull Banner

        -- Forms
        [5487]   = 0.5, -- Bear Form
        [783]    = 0.5, -- Travel Form
        [768]    = 0.5, -- Cat Form
        [24858]  = 0.5, -- Moonkin Form

        -- Slows
        [50435]  = 0.4, -- Chilblains (50%)
        [12323]  = 0.4, -- Piercing Howl (50%)
        [113092] = 0.4, -- Frost Bomb (70%)
        [120]    = 0.4, -- Cone of Cold (70%)
        [60947]  = 0.4, -- Nightmare (30%)
        [1715]   = 0.4, -- Hamstring (50%)

        -- Miscellaneous
        [25771]  = 0.3, -- Forbearance (debuff)
        [22734]  = 0.2, -- Drink
        [115867] = 0.1, -- Mana Tea
        --[28612]  = 0.2, -- Cojured Food --not mop
        --[33717]  = 0.2, -- Cojured Food --not mop
        [108366] = 0.1, -- Soul Leech
        [41425]  = 0.1, -- Hypothermia
        [108199] = 0, -- Gorefiend's Grasp
        [102793] = 0, -- Ursol's Vortex
        [61391]  = 0, -- Typhoon
        [13812]  = 0, -- Glyph of Explosive Trap
        [51490]  = 0, -- Thunderstorm
        [6360]   = 0, -- Whiplash
        [115770] = 0, -- Fellash
        [114018] = 0, -- Shroud of Concealment
        [110960] = 0, -- Greater Invisibility (Invis)
        [66]     = 0, -- Invisibility
        [6346]   = 0, -- Fear Ward
        [110717] = 0, -- Fear Ward (Symbiosis)
        [2457]   = 0, -- Battle Stance
        [2458]   = 0, -- Berserker Stance
        [71]     = 0, -- Defensive Stance



        -- ##########################
        -- Cata bonus ids, needs to be verified
        -- ##########################
        -- *** Controlled Stun Effects ***
        [93433] = 9, -- Burrow Attack (Worm)
        --[83046] = 9, -- Improved Polymorph (Rank 1) --not mop
        --[83047] = 9, -- Improved Polymorph (Rank 2) --not in mop
        --[2812]  = 9, -- Holy Wrath
        --[88625] = "Stunned", -- Holy Word: Chastise
        --[93986] = 9, -- Aura of Foreboding--not mop
        [54786] = 9, -- Demon Leap

        -- *** Non-controlled Stun Effects ***
        [85387] = 9, -- Aftermath
        [15283] = 9, -- Stunning Blow (Weapon Proc)
        [56]    = 9, -- Stun (Weapon Proc)

        -- *** Fear Effects ***
        [5134]  = 9, -- Flash Bomb Fear (Item)

        -- *** Controlled Root Effects ***
        --[96293] = 4, -- Chains of Ice (Chilblains Rank 1) --not mop
        --[87193] = 4, -- Paralysis -- not mop

        -- *** Non-controlled Root Effects ***
        [47168] = 4, -- Improved Wing Clip
        --[83301] = 4, -- Improved Cone of Cold (Rank 1) --not mop
        --[83302] = 4, -- Improved Cone of Cold (Rank 2) --not mop
        --[55080] = 4, -- Shattered Barrier (Rank 1) --not mop
        --[83073] = 4, -- Shattered Barrier (Rank 2) --not mop
        [50479] = 6, -- Nether Shock (Nether Ray)
        --[86759] = 6, -- Silenced - Improved Kick (Rank 2) --not mop
    }
end

local spellLockReducer = {
    [317920] = 0.7, -- Concentration Aura
    [234084] = 0.5, -- Moon and Stars
    [383020] = 0.5, -- Tranquil Air
}

function sArenaFrameMixin:FindInterrupt(event, spellID)
    local interruptDuration = sArenaMixin.interruptList[spellID]
    local unit = self.unit
    local _, _, _, _, _, _, notInterruptable = UnitChannelInfo(unit)

    if (event == "SPELL_INTERRUPT" or notInterruptable == false) then
        for n = 1, 30 do
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, n, "HELPFUL")
            if not aura then break end
            local mult = spellLockReducer[aura.spellId]
            if mult then
                interruptDuration = interruptDuration * mult
            end
        end
        self.currentInterruptSpellID = spellID
        self.currentInterruptDuration = interruptDuration
        self.currentInterruptExpirationTime = GetTime() + interruptDuration
        self.currentInterruptTexture = GetSpellTexture(spellID)
        self:FindAura()
        C_Timer.After(interruptDuration, function()
            self.currentInterruptSpellID = nil
            self.currentInterruptDuration = 0
            self.currentInterruptExpirationTime = 0
            self.currentInterruptTexture = nil
            self:FindAura()
        end)
    end
end

local tooltipScanner = CreateFrame("GameTooltip", "sArenaTooltipScanner", nil, "GameTooltipTemplate")
tooltipScanner:SetOwner(WorldFrame, "ANCHOR_NONE")

local function AuraTooltipContains(unit, index, filter, search)
    tooltipScanner:ClearLines()
    tooltipScanner:SetUnitAura(unit, index, filter)

    local line
    for i = 1, tooltipScanner:NumLines() do
        line = _G["sArenaTooltipScannerTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text and text:find(search, 1, true) then
                return true
            end
        end
    end

    return false
end

local function AuraTooltipExtractPercent(unit, index, filter)
    tooltipScanner:ClearLines()
    tooltipScanner:SetUnitAura(unit, index, filter)

    local line
    for i = 1, tooltipScanner:NumLines() do
        line = _G["sArenaTooltipScannerTextLeft" .. i]
        if line then
            local text = line:GetText()
            if text then
                local percent = text:match("(%d+%%)")
                if percent then
                    return percent
                end
            end
        end
    end

    return nil
end

function sArenaFrameMixin:FindAura()
    local unit = self.unit
    local auraList = sArenaMixin.auraList

    local currentSpellID, currentDuration, currentExpirationTime, currentTexture, currentApplications
    local currentPriority, currentRemaining = 0, 0

    if self.currentInterruptSpellID then
        currentSpellID = self.currentInterruptSpellID
        currentDuration = self.currentInterruptDuration
        currentExpirationTime = self.currentInterruptExpirationTime
        currentTexture = self.currentInterruptTexture
        currentPriority = 5.9 -- Below Silence, need to clean list
        currentRemaining = currentExpirationTime - GetTime()
        currentApplications = nil
    end

    for i = 1, 2 do
        local filter = (i == 1 and "HELPFUL" or "HARMFUL")

        for n = 1, 30 do
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, n, filter)
            if not aura then break end

            local spellID = aura.spellId
            local priority = auraList[spellID]

            if priority then

                local duration = aura.duration or 0
                local expirationTime = aura.expirationTime or 0
                local texture = aura.icon
                local applications = aura.applications or 0

                -- Mists of Pandaria unique checks
                if not isRetail then
                    -- Icebound Fortitude, Check if it's glyphed to be immune to CC
                    if spellID == 51271 then
                        if AuraTooltipContains(unit, n, filter, "70%%") then
                            priority = 7
                        end
                    end
                    -- Handle percentage-based auras
                    if tooltipInfoAuras[spellID] then
                        local percent = AuraTooltipExtractPercent(unit, n, filter)
                        if percent then
                            applications = percent
                        end
                    end
                end

                -- Check for manual override of duration
                if sArenaMixin.activeNonDurationAuras[spellID] then
                    local tracked = sArenaMixin.nonDurationAuras[spellID]
                    if tracked then
                        duration = tracked.duration
                        expirationTime = sArenaMixin.activeNonDurationAuras[spellID] + duration
                        texture = tracked.texture or texture
                    end
                end

                local remaining = expirationTime - GetTime()

                if (priority > currentPriority)
                    or (priority == currentPriority and remaining > currentRemaining)
                then
                    currentSpellID = spellID
                    currentDuration = duration
                    currentExpirationTime = expirationTime
                    currentTexture = texture
                    currentPriority = priority
                    currentRemaining = remaining
                    currentApplications = applications
                end
            end
        end
    end

    if currentSpellID then
        self.currentAuraSpellID = currentSpellID
        self.currentAuraStartTime = currentExpirationTime - currentDuration
        self.currentAuraDuration = currentDuration
        self.currentAuraTexture = currentTexture
        self.currentAuraApplications = currentApplications
    else
        self.currentAuraSpellID = nil
        self.currentAuraStartTime = 0
        self.currentAuraDuration = 0
        self.currentAuraTexture = nil
        self.currentAuraApplications = nil
    end

    self:UpdateAuraStacks()
    self:UpdateClassIcon()
end

function sArenaFrameMixin:UpdateAuraStacks()
    if not self.currentAuraApplications then
        self.AuraStacks:SetText("")
        return
    end

    -- Show percentage for percentage-based auras, stacks >= 2 for others
    if tooltipInfoAuras[self.currentAuraSpellID] then
        self.AuraStacks:SetText(self.currentAuraApplications)
    elseif self.currentAuraApplications >= 2 then
        self.AuraStacks:SetText(self.currentAuraApplications)
        self.AuraStacks:SetScale(1)
    else
        self.AuraStacks:SetText("")
    end
end
