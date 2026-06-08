-- ============================================================
-- NemPetAlerts/Specs/MageFrost.lua
-- Frost Mage spec module.
-- ============================================================

local NPA = _G.NemPetAlerts
if not NPA then return end

local UnitIsDead     = UnitIsDead

-- ============================================================
-- Spec Constants
-- ============================================================
local SPEC_ID = 64

-- ============================================================
-- Spell IDs
-- ============================================================
local SPELL_SUMMON_WATER_ELEMENTAL = 31687        -- SpellID

-- ============================================================
-- State
-- ============================================================
local state = {
    petResurrecting = false,
}

-- ============================================================
-- Alert Definitions
-- ============================================================
local ALERTS = {
    { key = "petDead",         label = "Water Ele Died",          text = "* WATER ELE DIED *",          defaultColor = { r=1.0,    g=0.2039, b=0.1569 }, yOffset =  52, defaultSound = "Mage: Water Ele Died",          soundLabel = "Water Ele Died",          priority = NPA.VOICE_PRIO_CRITICAL },
    { key = "noPet",           label = "Summon Water Ele",        text = "* SUMMON WATER ELE *",        defaultColor = { r=0.9098, g=0.4118, b=0.0    }, yOffset =  -2, defaultSound = "Mage: Summon Water Ele",        soundLabel = "Summon Water Ele",        priority = NPA.VOICE_PRIO_CRITICAL },
    { key = "petInCC",    label = "Water Ele In CC",         text = "* WATER ELE IN CC *",         defaultColor = { r=0.2824, g=0.6549, b=1.0    }, yOffset = -83, defaultSound = "Mage: Water Ele in CC",         soundLabel = "Water Ele CC",            priority = NPA.VOICE_PRIO_HIGH },
    { key = "healPet",         label = "Water Ele Health Low",    text = "* WATER ELE HEALTH LOW *",    defaultColor = { r=0.1882, g=1.0,    b=0.3098 }, yOffset =  25, defaultSound = "Mage: Water Ele Health Low",    soundLabel = "Water Ele Health Low",    noSound = true },
    { key = "petPassive",      label = "Water Ele On Passive",    text = "* WATER ELE ON PASSIVE *",    defaultColor = { r=1.0,    g=0.5843, b=0.1333 }, yOffset = -29, defaultSound = "Mage: Water Ele on Passive",    soundLabel = "Water Ele On Passive",    priority = NPA.VOICE_PRIO_NORMAL },
    { key = "petNotAttacking", label = "Water Ele Not Attacking", text = "* WATER ELE NOT ATTACKING *", defaultColor = { r=1.0,    g=0.8588, b=0.0    }, yOffset = -56, defaultSound = "Mage: Water Ele Not Attacking", soundLabel = "Water Ele Not Attacking", priority = NPA.VOICE_PRIO_HIGH },
}

-- ============================================================
-- Test Slots
-- ============================================================
local TEST_SLOTS = { [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true }

-- ============================================================
-- Defaults
-- ============================================================
local DEFAULTS = {
    petDeadEnabled              = true,
    petDeadSoundEnabled         = true,
    petDeadSoundName            = "Mage: Water Ele Died",
    noPetEnabled                = true,
    noPetSoundEnabled           = true,
    noPetSoundName              = "Mage: Summon Water Ele",
    petInCCEnabled         = true,
    petInCCSoundEnabled    = true,
    petInCCSoundName       = "Mage: Water Ele in CC",
    healPetEnabled              = true,
    petPassiveEnabled           = true,
    petPassiveSoundEnabled      = true,
    petPassiveSoundName         = "Mage: Water Ele on Passive",
    petNotAttackingEnabled      = true,
    petNotAttackingSoundEnabled = true,
    petNotAttackingSoundName    = "Mage: Water Ele Not Attacking",
}

-- ============================================================
-- Module Table
-- ============================================================
local MageFrost = {
    class             = "MAGE",
    specID            = SPEC_ID,
    specName          = "Frost Mage",
    alerts            = ALERTS,
    testSlots         = TEST_SLOTS,
    defaults          = DEFAULTS,
    state             = state,
    hasHealPet        = true,
    healPetAlertIndex = 4,

    extraEvents = {
        "UNIT_PET",
        "UNIT_AURA",
        "UNIT_FLAGS",
        "PLAYER_MOUNT_DISPLAY_CHANGED",
        "UNIT_ENTERED_VEHICLE",
        "UNIT_EXITED_VEHICLE",
        "PET_BAR_UPDATE",
        "PET_BAR_UPDATE_USABLE",
        "PET_UI_UPDATE",
    },

    extraUnitEvents = {
        { "UNIT_HEALTH", "pet" },
    },
}

-- ============================================================
-- ShouldRun
-- ============================================================
function MageFrost:ShouldRun(db)
    if not db.enabled then return false end
    if NPA.GetSpecID() ~= SPEC_ID then return false end
    return NPA.IsSpellKnownByPlayer(SPELL_SUMMON_WATER_ELEMENTAL)
end

-- ============================================================
-- OnActivate
-- ============================================================
function MageFrost:OnActivate(db)
    if not (NPA.PetExists() and not UnitIsDead("pet")) then
        -- Safety net for UNIT_PET that fired before activation.
        C_Timer.After(0.5, NPA.Evaluate)
    end
end

-- ============================================================
-- ClearAllState
-- ============================================================
function MageFrost:ClearAllState()
    state.petResurrecting = false
    NPA.notAttackingState.petNotAttackingStartTime = nil
    NPA.notAttackingState.petLastHadTargetTime     = nil
end

-- ============================================================
-- GetHighestPriorityAlert
-- ============================================================
function MageFrost:GetHighestPriorityAlert(db)
    if NPA.PetExists() then
        if not UnitIsDead("pet") then state.petResurrecting = false end
        if db.petDeadEnabled     and UnitIsDead("pet") then
            state.petResurrecting = true
            return 1
        end
        if db.petInCCEnabled    and NPA.PetIsCC() then return 3 end
        if db.petPassiveEnabled      and NPA.PetIsPassive() then return 5 end
        if db.petNotAttackingEnabled and NPA.PetNotAttacking() then return 6 end
        if db.healPetEnabled         and NPA.PetNeedsHealing() then return 4 end
        return nil
    else
        if state.petResurrecting then return 1 end
        if db.noPetEnabled and not NPA.ShouldSuppressNoPet() then
            return 2
        end
        return nil
    end
end

-- ============================================================
-- OnEvent
-- ============================================================
function MageFrost:OnEvent(db, event, ...)
    if event == "UNIT_PET" then
        local unit = ...
        if unit == "player" then
            if NPA.PetExists() and not UnitIsDead("pet") then
                state.petResurrecting = false
            end
            NPA.Evaluate()
            C_Timer.After(0.1, NPA.Evaluate)
        end
        return true
    end

    if event == "UNIT_AURA" then
        local unit = ...
        if unit == "pet" or unit == "player" then
            C_Timer.After(0.1, NPA.Evaluate)
        end
        return true
    end

    if event == "UNIT_HEALTH" then
        NPA.Evaluate()
        return true
    end

    if event == "UNIT_FLAGS" or event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        local unit = (event == "UNIT_FLAGS") and (...) or "player"
        if unit == "player" or unit == "pet" then
            NPA.Evaluate()
            if unit == "player" then C_Timer.After(0.1, NPA.Evaluate) end
        end
        return true
    end

    if event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" then
        local unit = ...
        if unit == "player" then
            NPA.Evaluate()
            C_Timer.After(0.1, NPA.Evaluate)
        end
        return true
    end

    if event == "UNIT_TARGET" then
        local unit = ...
        if unit == "pet" then NPA.Evaluate() end
        return true
    end

    if event == "PLAYER_REGEN_DISABLED" then
        NPA.notAttackingState.petNotAttackingStartTime = nil
        NPA.Evaluate()
        return true
    end

    if event == "PLAYER_REGEN_ENABLED" then
        NPA.notAttackingState.petNotAttackingStartTime = nil
        NPA.notAttackingState.petLastHadTargetTime     = nil
        NPA.Evaluate()
        return true
    end

    return false
end

-- ============================================================
-- Debug
-- ============================================================
function MageFrost:Debug(db)
    local ok, err = pcall(function()
        NPA.Msg("spec=Frost"
            .. "  hasSummon=" .. tostring(NPA.IsSpellKnownByPlayer(SPELL_SUMMON_WATER_ELEMENTAL))
            .. "  petRes=" .. tostring(state.petResurrecting)
            .. "  specID=" .. tostring(NPA.GetSpecID()))
    end)
    if not ok then NPA.Msg("ERROR(mage_frost): " .. tostring(err)) end
end

-- ============================================================
-- Alert Options
-- ============================================================
function MageFrost:BuildAlertOptions(box, db, helpers)
    helpers:MakeNumericInput("Heal Pet Threshold (%)", 1, 99,
        function() return db.healPetThreshold or 50 end,
        function(v) db.healPetThreshold = v; NPA.ResetHealthCurve() end)
end

-- ============================================================
-- Register
-- ============================================================
NPA:RegisterSpec("MageFrost", MageFrost)
