local addonName, BBM = ...

BBM.GameVersion = select(4, GetBuildInfo())
BBM.NewMidnightAuras = (BBM.GameVersion >= 120100)
BBM.LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

BBM.defaultSettings = {
    classIcons = {
        showFriendly     = true,
        showEnemy        = false,
        showOnPlayerPet  = true,
        showInArena      = true,
        showInBG         = true,
        showInWorld      = true,
        showInCity       = true,
        showSpecIcon     = true,
        showHealerIcon   = true,
        classColorBorder = true,
        hidePetHealthbars    = true,
        hidePetHealthbarsFriendly = true,
        hidePetHealthbarsEnemy    = false,
        hideFriendlyNames    = false,
        showTargetGlow       = true,
        targetGlowClassColor = false,
        strata               = "BACKGROUND",
        showCC           = true,
        showCCFriendly   = true,
        showCCEnemy      = true,
        pinMode          = true,
        pinModeFriendly  = true,
        pinModeEnemy     = false,
        separateSettings = false,
        anchor           = "TOP",
        xPos             = 0,
        yPos             = 0,
        scale            = 1.0,
        friendlyAnchor   = "TOP",
        friendlyXPos     = 0,
        friendlyYPos     = 0,
        friendlyScale    = 1.0,
        enemyAnchor      = "TOP",
        enemyXPos        = 0,
        enemyYPos        = 0,
        enemyScale       = 1.0,
    },
    totemIcons = {
        showEnemy        = true,
        showFriendly     = false,
        showOnPlayerPet  = true,
        showInArena      = true,
        showInBG         = true,
        showInWorld      = true,
        showInCity       = true,
        showTargetGlow       = true,
        targetGlowClassColor = false,
        strata               = "BACKGROUND",
        separateSettings = false,
        anchor           = "TOP",
        xPos             = 0,
        yPos             = 0,
        scale            = 1.7,
        friendlyAnchor   = "TOP",
        friendlyXPos     = 0,
        friendlyYPos     = 0,
        friendlyScale    = 1.7,
        enemyAnchor      = "TOP",
        enemyXPos        = 0,
        enemyYPos        = 0,
        enemyScale       = 1.7,
        showGlow         = true,
        showOtherTotems  = false,
        showColor        = true,
        colorName        = true,
        colorHealthbar   = true,
        colorOthers      = false,
        totemColors = {
            grounding     = {r=1.00, g=0.00, b=1.00},
            capacitor     = {r=1.00, g=0.69, b=0.00},
            psyfiend      = {r=0.49, g=0.00, b=1.00},
            healingStream = {r=0.00, g=1.00, b=0.78},
            others        = {r=0.70, g=0.70, b=0.70},
        },
    },
    arenaNames = {
        enabled        = true,
        showOnEnemy    = true,
        showOnFriendly = false,
        abbreviateSpec = false,
        classColorArenaNames = true,
        namesMode      = "replace",
        fontKey        = "",
        enemyShowArenaID = true,
        enemyShowSpec    = true,
        enemyShowName    = false,
        friendlyShowArenaID = false,
        friendlyShowSpec    = true,
        friendlyShowName    = true,
        specNameFontSize = 18,
        specNameXPos     = 0,
        specNameYPos     = 4,
        specNameAnchor   = "TOP",
        arenaIDFontSize  = 30,
        arenaIDXPos      = 0,
        arenaIDYPos      = 0,
        arenaIDAnchor    = "TOP",
        arenaIDAnchorTo  = "specName",
    },
    others = {
        hideRealmNames  = true,
        classColorNames = false,
        moveableSettingsPanel = true,
        nameOnlyMode = {
            showInArena = false,
            showInBG    = false,
            showInWorld = false,
            showInCity  = false,
            showInPvE   = false,
        },
    },
}

BBM.anchorOpposite = {
    TOPLEFT     = "BOTTOMRIGHT",
    TOP         = "BOTTOM",
    TOPRIGHT    = "BOTTOMLEFT",
    LEFT        = "RIGHT",
    CENTER      = "CENTER",
    RIGHT       = "LEFT",
    BOTTOMLEFT  = "TOPRIGHT",
    BOTTOM      = "TOP",
    BOTTOMRIGHT = "TOPLEFT",
}

BBM.anchorValues = {
    TOPLEFT     = "Top Left",
    TOP         = "Top",
    TOPRIGHT    = "Top Right",
    LEFT        = "Left",
    CENTER      = "Center",
    RIGHT       = "Right",
    BOTTOMLEFT  = "Bottom Left",
    BOTTOM      = "Bottom",
    BOTTOMRIGHT = "Bottom Right",
}

BBM.NAMEPLATE_ADDONS = { "Platynator", "Plater", "ThreatPlates", "BetterBlizzPlates", "ElvUI", "Kui_Nameplates" }

BBM.SpecNames = {
    -- Death Knight
    [250] = "Blood", [251] = "Frost", [252] = "Unholy",
    -- Demon Hunter
    [577] = "Havoc", [581] = "Vengeance", [1480] = "Devourer",
    -- Druid
    [102] = "Balance", [103] = "Feral", [104] = "Guardian", [105] = "Restoration",
    -- Evoker
    [1467] = "Devastation", [1468] = "Preservation", [1473] = "Augmentation",
    -- Hunter
    [253] = "Beast Mastery", [254] = "Marksmanship", [255] = "Survival",
    -- Mage
    [62] = "Arcane", [63] = "Fire", [64] = "Frost",
    -- Monk
    [268] = "Brewmaster", [270] = "Mistweaver", [269] = "Windwalker",
    -- Paladin
    [65] = "Holy", [66] = "Protection", [70] = "Retribution",
    -- Priest
    [256] = "Discipline", [257] = "Holy", [258] = "Shadow",
    -- Rogue
    [259] = "Assassination", [260] = "Outlaw", [261] = "Subtlety",
    -- Shaman
    [262] = "Elemental", [263] = "Enhancement", [264] = "Restoration",
    -- Warlock
    [265] = "Affliction", [266] = "Demonology", [267] = "Destruction",
    -- Warrior
    [71] = "Arms", [72] = "Fury", [73] = "Protection",
}

BBM.ShortSpecNames = {
    -- Death Knight
    [250] = "Blood", [251] = "Frost", [252] = "Unholy",
    -- Demon Hunter
    [577] = "Havoc", [581] = "Vengeance", [1480] = "Devourer",
    -- Druid
    [102] = "Balance", [103] = "Feral", [104] = "Guardian", [105] = "Resto",
    -- Evoker
    [1467] = "Dev", [1468] = "Pres", [1473] = "Aug",
    -- Hunter
    [253] = "BM", [254] = "Marksman", [255] = "Survival",
    -- Mage
    [62] = "Arcane", [63] = "Fire", [64] = "Frost",
    -- Monk
    [268] = "Brew", [270] = "Mist", [269] = "Wind",
    -- Paladin
    [65] = "Holy", [66] = "Prot", [70] = "Ret",
    -- Priest
    [256] = "Disc", [257] = "Holy", [258] = "Shadow",
    -- Rogue
    [259] = "Assa", [260] = "Outlaw", [261] = "Sub",
    -- Shaman
    [262] = "Ele", [263] = "Enha", [264] = "Resto",
    -- Warlock
    [265] = "Aff", [266] = "Demo", [267] = "Destro",
    -- Warrior
    [71] = "Arms", [72] = "Fury", [73] = "Prot",
}

BBM.HealerSpecs = {
    [105]  = true, -- Druid Restoration
    [270]  = true, -- Monk Mistweaver
    [65]   = true, -- Paladin Holy
    [256]  = true, -- Priest Discipline
    [257]  = true, -- Priest Holy
    [264]  = true, -- Shaman Restoration
    [1468] = true, -- Evoker Preservation
}

BBM.TankSpecs = {
    [250] = true, -- Death Knight Blood
    [581] = true, -- Demon Hunter Vengeance
    [104] = true, -- Druid Guardian
    [268] = true, -- Monk Brewmaster
    [66]  = true, -- Paladin Protection
    [73]  = true, -- Warrior Protection
}

BBM.classificationIcons = {
    [0]  = 132485,  -- FlagCarrierHorde
    [1]  = 132486,  -- FlagCarrierAlliance
    [2]  = 132487,  -- FlagCarrierNeutral
    [7]  = 1119885, -- OrbCarrierBlue
    [8]  = 1119886, -- OrbCarrierGreen
    [9]  = 1119887, -- OrbCarrierOrange
    [10] = 1119888, -- OrbCarrierPurple
}

BBM.petSpellIcons = {
    -- Hunter pet family abilities
    [160065] = 236195,  -- Aqiri - Tendon Rip
    [263841] = 877476,  -- Basilisk - Petrifying Gaze
    [344348] = 132182,  -- Bat - Sonic Screech
    [263934] = 132183,  -- Bear - Thick Fur
    [90339]  = 133570,  -- Beetle - Harden Carapace
    [263852] = 132192,  -- Bird of Prey - Talon Rend
    [288962] = 1687702, -- Blood Beast - Blood Bolt
    [263869] = 132184,  -- Boar - Bristle
    [341115] = 454771,  -- Camel - Hardy
    [279410] = 2011146, -- Carapid - Bulwark
    [24423]  = 132200,  -- Carrion Bird - Bloody Screech
    [263892] = 132185,  -- Cat - Catlike Reflexes
    [54644]  = 236190,  -- Chimaera - Frost Breath
    [160057] = 1044794, -- Clefthoof - Thick Hide
    [263867] = 236191,  -- Core Hound - Obsidian Skin
    [341117] = 2143073, -- Courser - Fleethoof
    [50245]  = 132186,  -- Crab - Pin
    [50433]  = 132187,  -- Crocolisk - Ankle Crack
    [54680]  = 236192,  -- Devilsaur - Monstrous Bite
    [263861] = 877480,  -- Direhorn - Gore
    [263887] = 132188,  -- Dragonhawk - Dragon's Guile
    [263916] = 929300,  -- Feathermane - Feather Flurry
    [160011] = 458223,  -- Fox - Agile Reflexes
    [263939] = 132189,  -- Gorilla - Silverback
    [263921] = 877477,  -- Gruffhorn - Gruff
    [279336] = 804969,  -- Hopper - Swarm of Flies
    [263423] = 877481,  -- Hound - Lock Jaw
    [263863] = 463493,  -- Hydra - Acid Bite
    [263853] = 132190,  -- Hyena - Infected Bite
    [392622] = 797547,  -- Lesser Dragonkin - Shimmering Scales
    [279362] = 2027936, -- Lizard - Grievous Bite
    [341118] = 132254,  -- Mammoth - Trample
    [263868] = 132247,  -- Mechanical - Defense Matrix
    [160044] = 877482,  -- Monkey - Primal Agility
    [344353] = 236193,  -- Moth - Serenity Dust
    [264023] = 616693,  -- Oxen - Niuzao's Fortitude
    [279399] = 1624590, -- Pterrordax - Ancient Hide
    [263854] = 132193,  -- Raptor - Savage Rend
    [263857] = 132194,  -- Ravager - Ravage
    [344349] = 132191,  -- Ray - Nether Energy
    [160018] = 1044490, -- Riverbeast - Gruesome Bite
    [263856] = 644001,  -- Rodent - Gnaw
    [263865] = 646378,  -- Scalehide - Scale Shield
    [160060] = 132195,  -- Scorpid - Deadly Sting
    [263904] = 136040,  -- Serpent - Serpent's Swiftness
    [160063] = 877478,  -- Shale Beast - Solid Shell
    [160067] = 132196,  -- Spider - Web Spray
    [344351] = 236165,  -- Spirit Beast - Spirit Pulse
    [344347] = 132197,  -- Sporebat - Spore Cloud
    [344352] = 1044501, -- Stag - Nature's Grace
    [160049] = 625905,  -- Stone Hound - Stone Armor
    [50285]  = 132198,  -- Tallstrider - Dust Cloud
    [26064]  = 132199,  -- Turtle - Shell Shield
    [35346]  = 132201,  -- Warp Stalker - Warp Time
    [263858] = 236196,  -- Wasp - Toxic Sting
    [344346] = 643423,  -- Water Strider - Soothing Waters
    [344350] = 877479,  -- Waterfowl - Oiled Feathers
    [264360] = 132202,  -- Wind Serpent - Winged Agility
    [263840] = 132203,  -- Wolf - Furious Bite
    [263446] = 236197,  -- Worm - Acid Spit
    -- Warlock pets
    [3110]   = 136218,  -- Imp - Firebolt
    [6360]   = 136220,  -- Succubus - Whiplash
    [19505]  = 136217,  -- Felhunter - Devour Magic
    [112042] = 136221,  -- Voidwalker - Suffering
    [89751]  = 136216,  -- Felguard - Legion Strike
    -- Mage
    [135029] = 135862,  -- Water Elemental - Water Jet
    -- Death Knight
    [47482]  = 1531513, -- Ghoul - Leap
}

BBM.petClasses = {
    ["DEATHKNIGHT"] = true,
    ["HUNTER"]      = true,
    ["MAGE"]        = true,
    ["WARLOCK"]     = true,
}

local function GetLocalizedSpecs()
    local specs = {}
    local locale = GetLocale()
    local classFirst = (locale == "esMX")

    local function AddSpec(specName, className, specID)
        if classFirst then
            specs[string.format("%s %s", className, specName)] = specID
        else
            specs[string.format("%s %s", specName, className)] = specID
        end
    end

    for classID = 1, GetNumClasses() do
        local _, class = GetClassInfo(classID)
        local classMale   = LOCALIZED_CLASS_NAMES_MALE[class]
        local classFemale = LOCALIZED_CLASS_NAMES_FEMALE[class]
        for specIndex = 1, C_SpecializationInfo.GetNumSpecializationsForClassID(classID) do
            local specID, specName = GetSpecializationInfoForClassID(classID, specIndex)
            if classMale then
                AddSpec(specName, classMale, specID)
            end
            if classFemale and classFemale ~= classMale then
                AddSpec(specName, classFemale, specID)
            end
        end
    end

    if locale == "esES" or locale == "esMX" then
        local esES_overrides = {
            ["Armas Guerrero"] = 71, ["Armas Guerrera"] = 71,
            ["Furia Guerrero"] = 72, ["Furia Guerrera"] = 72,
            ["Protección Guerrero"] = 73, ["Protección Guerrera"] = 73,
            ["Sagrado Paladín"] = 65, ["Sagrada Paladín"] = 65,
            ["Protección Paladín"] = 66,
            ["Reprensión Paladín"] = 70,
            ["Bestias Cazador"] = 253, ["Bestias Cazadora"] = 253,
            ["Puntería Cazador"] = 254, ["Puntería Cazadora"] = 254,
            ["Supervivencia Cazador"] = 255, ["Supervivencia Cazadora"] = 255,
            ["Asesinato Pícaro"] = 259, ["Asesinato Pícara"] = 259,
            ["Forajido Pícaro"] = 260, ["Forajida Pícara"] = 260,
            ["Sutileza Pícaro"] = 261, ["Sutileza Pícara"] = 261,
            ["Disciplina Sacerdote"] = 256, ["Disciplina Sacerdotisa"] = 256,
            ["Sagrado Sacerdote"] = 257, ["Sagrada Sacerdotisa"] = 257,
            ["Sombra Sacerdote"] = 258, ["Sombra Sacerdotisa"] = 258,
            ["Sangre Caballero de la Muerte"] = 250, ["Sangre Caballera de la Muerte"] = 250,
            ["Escarcha Caballero de la Muerte"] = 251, ["Escarcha Caballera de la Muerte"] = 251,
            ["Profano Caballero de la Muerte"] = 252, ["Profana Caballera de la Muerte"] = 252,
            ["Elemental Chamán"] = 262,
            ["Mejora Chamán"] = 263,
            ["Restauración Chamán"] = 264,
            ["Arcano Mago"] = 62, ["Arcana Maga"] = 62,
            ["Fuego Mago"] = 63, ["Fuego Maga"] = 63,
            ["Escarcha Mago"] = 64, ["Escarcha Maga"] = 64,
            ["Aflicción Brujo"] = 265, ["Aflicción Bruja"] = 265,
            ["Demonología Brujo"] = 266, ["Demonología Bruja"] = 266,
            ["Destrucción Brujo"] = 267, ["Destrucción Bruja"] = 267,
            ["Maestro cervecero Monje"] = 268, ["Maestra cervecera Monje"] = 268,
            ["Tejedor de niebla Monje"] = 270, ["Tejedora de niebla Monje"] = 270,
            ["Viajero del viento Monje"] = 269, ["Viajera del viento Monje"] = 269,
            ["Equilibrio Druida"] = 102,
            ["Feral Druida"] = 103,
            ["Guardián Druida"] = 104, ["Guardiana Druida"] = 104,
            ["Restauración Druida"] = 105,
            ["Devastación Cazador de demonios"] = 577, ["Devastación Cazadora de demonios"] = 577,
            ["Venganza Cazador de demonios"] = 581, ["Venganza Cazadora de demonios"] = 581,
            ["Devastación Evocador"] = 1467, ["Devastación Evocadora"] = 1467,
            ["Preservación Evocador"] = 1468, ["Preservación Evocadora"] = 1468,
            ["Aumento Evocador"] = 1473, ["Aumento Evocadora"] = 1473,
        }
        local esClassNames = {
            "Caballero de la Muerte", "Caballera de la Muerte",
            "Cazador de demonios", "Cazadora de demonios",
            "Sacerdotisa", "Sacerdote",
            "Evocadora", "Evocador",
            "Cazadora", "Cazador",
            "Guerrera", "Guerrero",
            "Paladín",
            "Pícara", "Pícaro",
            "Chamán",
            "Maga", "Mago",
            "Bruja", "Brujo",
            "Monje",
            "Druida",
        }
        for k, v in pairs(esES_overrides) do
            if classFirst then
                local swapped
                for _, className in ipairs(esClassNames) do
                    local specPart = k:match("^(.-)%s+" .. className .. "$")
                    if specPart then swapped = className .. " " .. specPart; break end
                end
                specs[swapped or k] = v
            else
                specs[k] = v
            end
        end
    elseif locale == "ruRU" then
        specs["Хранительница Пробудительница"] = 1468
    end

    return specs
end

BBM.ALL_SPECS = GetLocalizedSpecs()
