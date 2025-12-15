sArenaMixin.specIconTextures = {
    DRUID = {
        ["Balance"] = 136096,
        ["Feral"] = 132115,
        ["Restoration"] = 136041,
    },
    HUNTER = {
        ["Beast Mastery"] = 132164,
        ["Marksmanship"] = 132222,
        ["Survival"] = 132215,
    },
    MAGE = {
        ["Arcane"] = 135932,
        ["Fire"] = 135812,
        ["Frost"] = 135846,
    },
    PALADIN = {
        ["Holy"] = 135920,
        ["Protection"] = 135893,
        ["Retribution"] = 135873,
    },
    PRIEST = {
        ["Discipline"] = 135940,
        ["Holy"] = 237542,
        ["Shadow"] = 136207,
    },
    ROGUE = {
        ["Assassination"] = 132292,
        ["Combat"] = 132090,
        ["Subtlety"] = 132320,
    },
    SHAMAN = {
        ["Elemental"] = 136048,
        ["Enhancement"] = 136051,
        ["Restoration"] = 136052,
    },
    WARLOCK = {
        ["Affliction"] = 136145,
        ["Demonology"] = 136172,
        ["Destruction"] = 136186,
    },
    WARRIOR = {
        ["Arms"] = 132355,
        ["Fury"] = 132347,
        ["Protection"] = 132341,
    },
}

sArenaMixin.tbcSpecBuffs = {
    -- DRUID
    [45283] = "Restoration", -- Natural Perfection
    [16880] = "Restoration", -- Nature's Grace
    [24858] = "Restoration", -- Moonkin Form (Dreamstate = Resto in TBC)
    [17007] = "Feral",       -- Leader of the Pack
    [16188] = "Restoration", -- Nature's Swiftness
    [33891] = "Restoration", -- Tree of Life

    -- HUNTER
    [34692] = "Beast Mastery", -- The Beast Within
    [20895] = "Beast Mastery", -- Spirit Bond
    [34455] = "Beast Mastery", -- Ferocious Inspiration
    [27066] = "Marksmanship",  -- Trueshot Aura
    [34501] = "Survival",      -- Expose Weakness

    -- MAGE
    [33405] = "Frost",  -- Ice Barrier
    [11129] = "Fire",   -- Combustion
    [12042] = "Arcane", -- Arcane Power
    [12043] = "Arcane", -- Presence of Mind
    [31589] = "Arcane", -- Slow
    [12472] = "Frost",  -- Icy Veins
    [46989] = "Arcane", -- Improved Blink

    -- PALADIN
    [31836] = "Holy",       -- Light's Grace
    [31842] = "Holy",       -- Divine Illumination
    [20216] = "Holy",       -- Divine Favor
    [20375] = "Retribution", -- Seal of Command
    [20049] = "Retribution", -- Vengeance
    [20218] = "Retribution", -- Sanctity Aura
    [26018] = "Retribution", -- Vindication
    [27179] = "Protection",  -- Holy Shield

    -- PRIEST
    [15473] = "Shadow",     -- Shadowform
    [15286] = "Shadow",     -- Vampiric Embrace
    [45234] = "Discipline", -- Focused Will
    [27811] = "Discipline", -- Blessed Recovery
    [33142] = "Holy",       -- Blessed Resilience
    [14752] = "Discipline", -- Divine Spirit
    [27681] = "Discipline", -- Prayer of Spirit
    [10060] = "Discipline", -- Power Infusion
    [33206] = "Discipline", -- Pain Suppression
    [14893] = "Discipline", -- Inspiration

    -- ROGUE
    [36554] = "Subtlety",     -- Shadowstep
    [44373] = "Subtlety",     -- Shadowstep Speed
    [36563] = "Subtlety",     -- Shadowstep DMG
    [14278] = "Subtlety",     -- Ghostly Strike
    [31233] = "Assassination", -- Find Weakness
    [13877] = "Combat",       -- Blade Flurry

    -- SHAMAN
    [30807] = "Enhancement",  -- Unleashed Rage
    [16280] = "Enhancement",  -- Flurry
    [30823] = "Enhancement",  -- Shamanistic Rage
    [16190] = "Restoration",  -- Mana Tide Totem
    [32594] = "Restoration",  -- Earth Shield
    [29202] = "Restoration",  -- Healing Way

    -- WARLOCK
    [19028] = "Demonology",   -- Soul Link
    [23759] = "Demonology",   -- Master Demonologist
    [35696] = "Demonology",   -- Demonic Knowledge
    [30302] = "Destruction",  -- Nether Protection
    [34935] = "Destruction",  -- Backlash

    -- WARRIOR
    [29838] = "Arms", -- Second Wind
    [12292] = "Arms", -- Death Wish
}

sArenaMixin.tbcSpecSpells = {
    -- DRUID
    [33831] = "Balance",     -- Force of Nature
    [33983] = "Feral",       -- Mangle (Cat)
    [33987] = "Feral",       -- Mangle (Bear)
    [18562] = "Restoration", -- Swiftmend
    [17116] = "Restoration", -- Nature's Swiftness
    [33891] = "Restoration", -- Tree of Life

    -- HUNTER
    [19577] = "Beast Mastery", -- Intimidation
    [34490] = "Marksmanship",  -- Silencing Shot
    [27068] = "Survival",      -- Wyvern Sting
    [19306] = "Survival",      -- Counterattack
    [27066] = "Marksmanship",  -- Trueshot Aura

    -- MAGE
    [12042] = "Arcane", -- Arcane Power
    [33043] = "Fire",   -- Dragon's Breath
    [33933] = "Fire",   -- Blast Wave
    [33405] = "Frost",  -- Ice Barrier
    [31687] = "Frost",  -- Summon Water Elemental
    [12472] = "Frost",  -- Icy Veins
    [11958] = "Frost",  -- Cold Snap

    -- PALADIN
    [33072] = "Holy",        -- Holy Shock
    [20216] = "Holy",        -- Divine Favor
    [31842] = "Holy",        -- Divine Illumination
    [32700] = "Protection",  -- Avenger's Shield
    [27170] = "Retribution", -- Seal of Command
    [35395] = "Retribution", -- Crusader Strike
    [20066] = "Retribution", -- Repentance
    [20218] = "Retribution", -- Sanctity Aura

    -- PRIEST
    [10060] = "Discipline", -- Power Infusion
    [33206] = "Discipline", -- Pain Suppression
    [14752] = "Discipline", -- Divine Spirit
    [33143] = "Holy",       -- Blessed Resilience
    [34861] = "Holy",       -- Circle of Healing
    [15473] = "Shadow",     -- Shadowform
    [34917] = "Shadow",     -- Vampiric Touch
    [15286] = "Shadow",     -- Vampiric Embrace

    -- ROGUE
    [34413] = "Assassination", -- Mutilate
    [14177] = "Assassination", -- Cold Blood
    [13750] = "Combat",       -- Adrenaline Rush
    [13877] = "Combat",       -- Blade Flurry
    [14185] = "Subtlety",     -- Preparation
    [16511] = "Subtlety",     -- Hemorrhage
    [36554] = "Subtlety",     -- Shadowstep
    [14278] = "Subtlety",     -- Ghostly Strike
    [14183] = "Subtlety",     -- Premeditation

    -- SHAMAN
    [16166] = "Elemental",   -- Elemental Mastery
    [30706] = "Elemental",   -- Totem of Wrath
    [30823] = "Enhancement", -- Shamanistic Rage
    [17364] = "Enhancement", -- Stormstrike
    [16190] = "Restoration", -- Mana Tide Totem
    [32594] = "Restoration", -- Earth Shield
    [16188] = "Restoration", -- Nature's Swiftness

    -- WARLOCK
    [30405] = "Affliction",  -- Unstable Affliction
    [30108] = "Affliction",  -- Unstable Affliction
    [18220] = "Affliction",  -- Dark Pact
    [30414] = "Destruction", -- Shadowfury
    [30912] = "Destruction", -- Conflagrate
    [18708] = "Demonology",  -- Fel Domination

    -- WARRIOR
    [30330] = "Arms",       -- Mortal Strike
    [12292] = "Arms",       -- Death Wish
    [30335] = "Fury",       -- Bloodthirst
    [12809] = "Protection", -- Concussion Blow
    [30022] = "Protection", -- Devastation
    [30356] = "Protection", -- Shield Slam
}

function sArenaMixin:GetSpecNameFromSpell(spellID)
    local spec = self.tbcSpecSpells[spellID] or self.tbcSpecBuffs[spellID]
    return spec
end

function sArenaFrameMixin:CheckForSpecSpell(spellID)
    if self.specName then return end
    if not self.class then return end

    local detectedSpec = sArenaMixin:GetSpecNameFromSpell(spellID)
    if not detectedSpec then return end

    local classSpecs = sArenaMixin.specIconTextures[self.class]
    if not classSpecs or not classSpecs[detectedSpec] then
        return false
    end

    self.specName = detectedSpec
    self.isHealer = sArenaMixin.healerSpecNames[detectedSpec] or false
    self.specTexture = classSpecs[detectedSpec]

    self.SpecNameText:SetText(detectedSpec)
    local db = self.parent.db
    if db then
        self.SpecNameText:SetShown(db.profile.layoutSettings[db.profile.currentLayout].showSpecManaText)
    end

    self:UpdateSpecIcon()
    self:UpdateClassIcon(true)
    self:UpdateFrameColors()
    sArenaMixin:UpdateTextures()

    return true
end
