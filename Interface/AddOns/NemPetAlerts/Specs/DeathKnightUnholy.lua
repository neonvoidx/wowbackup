-- ============================================================
-- NemPetAlerts/Specs/DeathKnightUnholy.lua
-- Unholy Death Knight spec module.
-- ============================================================

local NPA = _G.NemPetAlerts
if not NPA then return end

local UnitIsDead     = UnitIsDead

-- ============================================================
-- Spec Constants
-- ============================================================
local SPEC_ID = 252

-- ============================================================
-- State
-- ============================================================
local state = {}

-- ============================================================
-- Alert Definitions
-- ============================================================
local ALERTS = {
    { key = "noPet",           label = "Raise Ghoul",         text = "* RAISE GHOUL *",            defaultColor = { r=0.9098, g=0.4118, b=0.0    }, yOffset =  -2, defaultSound = "Death Knight: Raise Ghoul",          soundLabel = "Raise Ghoul",          priority = NPA.VOICE_PRIO_CRITICAL },
    { key = "petInCC",    label = "Ghoul In CC",          text = "* GHOUL IN CC *",           defaultColor = { r=0.2824, g=0.6549, b=1.0    }, yOffset = -83, defaultSound = "Death Knight: Ghoul in CC",          soundLabel = "Ghoul CC",             priority = NPA.VOICE_PRIO_HIGH },
    { key = "healPet",         label = "Heal Ghoul",           text = "* HEAL GHOUL *",            defaultColor = { r=0.1882, g=1.0,    b=0.3098 }, yOffset =  25,                                                                                                          noSound = true },
    { key = "petPassive",      label = "Ghoul On Passive",     text = "* GHOUL ON PASSIVE *",      defaultColor = { r=1.0,    g=0.5843, b=0.1333 }, yOffset = -29, defaultSound = "Death Knight: Ghoul on Passive",     soundLabel = "Ghoul On Passive",     priority = NPA.VOICE_PRIO_NORMAL },
    { key = "petNotAttacking", label = "Ghoul Not Attacking",  text = "* GHOUL NOT ATTACKING *",   defaultColor = { r=1.0,    g=0.8588, b=0.0    }, yOffset = -56, defaultSound = "Death Knight: Ghoul Not Attacking",  soundLabel = "Ghoul Not Attacking",  priority = NPA.VOICE_PRIO_HIGH },
}

-- ============================================================
-- Test Slots
-- ============================================================
local TEST_SLOTS = { [1]=true, [2]=true, [3]=true, [4]=true, [5]=true }

-- ============================================================
-- Defaults
-- ============================================================
local DEFAULTS = {
    noPetEnabled                = true,
    noPetSoundEnabled           = true,
    noPetSoundName              = "Death Knight: Raise Ghoul",
    petInCCEnabled         = true,
    petInCCSoundEnabled    = true,
    petInCCSoundName       = "Death Knight: Ghoul in CC",
    healPetEnabled              = true,
    petPassiveEnabled           = true,
    petPassiveSoundEnabled      = true,
    petPassiveSoundName         = "Death Knight: Ghoul on Passive",
    petNotAttackingEnabled      = true,
    petNotAttackingSoundEnabled = true,
    petNotAttackingSoundName    = "Death Knight: Ghoul Not Attacking",
}

-- ============================================================
-- Module Table
-- ============================================================
local DeathKnightUnholy = {
    class             = "DEATHKNIGHT",
    specID            = SPEC_ID,
    specName          = "Unholy Death Knight",
    alerts            = ALERTS,
    testSlots         = TEST_SLOTS,
    defaults          = DEFAULTS,
    state             = state,
    hasHealPet        = true,
    healPetAlertIndex = 3,

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
function DeathKnightUnholy:ShouldRun(db)
    if not db.enabled then return false end
    return NPA.GetSpecID() == SPEC_ID
end

-- ============================================================
-- OnActivate
-- ============================================================
function DeathKnightUnholy:OnActivate(db)
    if not (NPA.PetExists() and not UnitIsDead("pet")) then
        -- Safety net for UNIT_PET that fired before activation.
        C_Timer.After(0.5, NPA.Evaluate)
    end
end

-- ============================================================
-- ClearAllState
-- ============================================================
function DeathKnightUnholy:ClearAllState()
    NPA.notAttackingState.petNotAttackingStartTime = nil
    NPA.notAttackingState.petLastHadTargetTime     = nil
end

-- ============================================================
-- GetHighestPriorityAlert
-- ============================================================
function DeathKnightUnholy:GetHighestPriorityAlert(db)
    if NPA.PetExists() then
        if db.petInCCEnabled    and NPA.PetIsCC() then return 2 end
        if db.petPassiveEnabled      and NPA.PetIsPassive() then return 4 end
        if db.petNotAttackingEnabled and NPA.PetNotAttacking() then return 5 end
        if db.healPetEnabled         and NPA.PetNeedsHealing() then return 3 end
        return nil
    else
        if db.noPetEnabled and not NPA.ShouldSuppressNoPet() then
            return 1
        end
        return nil
    end
end

-- ============================================================
-- OnEvent
-- ============================================================
function DeathKnightUnholy:OnEvent(db, event, ...)
    if event == "UNIT_PET" then
        local unit = ...
        if unit == "player" then
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
function DeathKnightUnholy:Debug(db)
    local ok, err = pcall(function()
        NPA.Msg("spec=Unholy"
            .. "  isUnholy=" .. tostring(NPA.GetSpecID() == SPEC_ID)
            .. "  specID=" .. tostring(NPA.GetSpecID()))
    end)
    if not ok then NPA.Msg("ERROR(dk_unholy): " .. tostring(err)) end
end

-- ============================================================
-- Alert Options
-- ============================================================
function DeathKnightUnholy:BuildAlertOptions(box, db, helpers)
    helpers:MakeNumericInput("Heal Pet Threshold (%)", 1, 99,
        function() return db.healPetThreshold or 50 end,
        function(v) db.healPetThreshold = v; NPA.ResetHealthCurve() end)
end

-- ============================================================
-- Register
-- ============================================================
NPA:RegisterSpec("DeathKnightUnholy", DeathKnightUnholy)
