-- =============================================================
-- Specs/MageFrost.lua
-- Nem: Pet Alerts — Frost Mage spec module
--
-- FULLY SELF-CONTAINED. Zero dependencies on other spec modules.
--
-- Frost Mage requires Summon Water Elemental to be known.
--
-- Alerts:
--   1. Water Ele Died         — Water Elemental dies
--   2. (unused)               — slot reserved for layout consistency
--   3. Summon Water Ele       — no pet out
--   4. (unused)               — no taunt for Mage
--   5. Water Ele In CC        — pet has crowd control aura
--   6. Water Ele Health Low   — pet health below threshold (ColorCurve)
--   7. Water Ele On Passive   — passive stance while in combat
--   8. Water Ele Not Attacking — pet idle in combat after grace period
-- =============================================================

local NPA = _G.NemPetAlerts
if not NPA then return end

local GetTime        = GetTime
local UnitExists     = UnitExists
local UnitIsDead     = UnitIsDead

-- =============================================================
-- Spec Constants
-- =============================================================
local SPEC_ID = 64  -- Frost

-- =============================================================
-- Spell IDs
-- =============================================================
local SPELL_SUMMON_WATER_ELEMENTAL = 31687

-- =============================================================
-- State
-- =============================================================
local state = {
    petResurrecting  = false,
    petCCWasActive   = false,
    petDeadWasActive = false,
}

-- =============================================================
-- Alert Definitions
-- =============================================================
-- Row layout (Y offsets):
--   Row 1 (+52):  [1] Water Ele Died
--   Row 2 (+25):  [6] Water Ele Health Low
--   Row 3 ( -2):  [3] Summon Water Ele
--   Row 4 (-29):  [2] (unused)  /  [7] Water Ele On Passive
--   Row 5 (-56):  [4] (unused)  /  [8] Water Ele Not Attacking
--   Row 6 (-83):  [5] Water Ele In CC

local ALERTS = {
    { key = "petDead",         label = "Water Ele Died",                      text = "* WATER ELE DIED *",            defaultColor = { r=1.0,    g=0.2039, b=0.1569 }, yOffset =  52, defaultSound = "OhNo",   soundLabel = "Pet Died" },
    { key = "fakeDeath",       label = "Wake Up Pet  (Hunter only)",          text = "* WAKE UP PET *",               defaultColor = { r=0.6980, g=0.3333, b=1.0    }, yOffset = -29 },
    { key = "noPet",           label = "Summon Water Ele",                    text = "* SUMMON WATER ELE *",           defaultColor = { r=0.9098, g=0.4118, b=0.0    }, yOffset =  -2 },
    { key = "tauntAuto",       label = "Taunt  (Hunter/Warlock only)",        text = "* TURN OFF AUTOCAST TAUNT *",    defaultColor = { r=0.9059, g=0.2667, b=1.0    }, yOffset = -56 },
    { key = "notAttacking",    label = "Water Ele In CC",                     text = "* WATER ELE IN CC *",            defaultColor = { r=0.2824, g=0.6549, b=1.0    }, yOffset = -83, defaultSound = "Sonarr", soundLabel = "Pet CC"  },
    { key = "healPet",         label = "Water Ele Health Low",                text = "* WATER ELE HEALTH LOW *",       defaultColor = { r=0.1882, g=1.0,    b=0.3098 }, yOffset =  25 },
    { key = "petPassive",      label = "Water Ele On Passive",                text = "* WATER ELE ON PASSIVE *",       defaultColor = { r=1.0,    g=0.5843, b=0.1333 }, yOffset = -29 },
    { key = "petNotAttacking", label = "Water Ele Not Attacking",             text = "* WATER ELE NOT ATTACKING *",    defaultColor = { r=1.0,    g=0.8588, b=0.0    }, yOffset = -56 },
}

-- =============================================================
-- Test Slots (Mage: no fakeDeath or taunt)
-- =============================================================
local TEST_SLOTS = { [1]=true, [3]=true, [5]=true, [6]=true, [7]=true, [8]=true }

-- =============================================================
-- Defaults
-- =============================================================
local DEFAULTS = {
    petDeadEnabled           = true,
    petDeadSoundEnabled      = true,
    petDeadSoundName         = "OhNo",
    fakeDeathEnabled         = false,  -- not applicable to Mage
    noPetEnabled             = true,
    tauntAutoEnabled         = false,  -- not applicable to Mage
    notAttackingEnabled      = true,
    notAttackingSoundEnabled = true,
    notAttackingSoundName    = "Sonarr",
    healPetEnabled           = true,
    petPassiveEnabled        = true,
    petNotAttackingEnabled   = true,
}

-- =============================================================
-- Module Table
-- =============================================================
local MageFrost = {
    class             = "MAGE",
    specID            = SPEC_ID,
    specName          = "Frost Mage",
    alerts            = ALERTS,
    testSlots         = TEST_SLOTS,
    defaults          = DEFAULTS,
    state             = state,
    hasHealPet        = true,
    healPetAlertIndex = 6,

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
        "PLAYER_REGEN_DISABLED",
        "PLAYER_REGEN_ENABLED",
    },

    extraUnitEvents = {
        { "UNIT_HEALTH", "pet" },
        { "UNIT_TARGET", "pet" },
    },
}

-- =============================================================
-- ShouldRun
-- =============================================================
function MageFrost:ShouldRun(db)
    if not db.enabled then return false end
    if NPA.GetSpecID() ~= SPEC_ID then return false end
    return NPA.IsSpellKnownByPlayer(SPELL_SUMMON_WATER_ELEMENTAL)
end

-- =============================================================
-- OnActivate
-- =============================================================
function MageFrost:OnActivate(db)
    state.petDeadWasActive = (NPA.PetExists() and UnitIsDead("pet")) or false
    if NPA.PetExists() and not UnitIsDead("pet") then
        NPA.StartPetHealthTicker()
    else
        NPA:StartModuleTicker("mage", 0.25, function()
            if NPA.PetExists() and not UnitIsDead("pet") then
                NPA:StopModuleTicker("mage")
            end
            NPA.Evaluate()
        end)
    end
end

-- =============================================================
-- ClearAllState
-- =============================================================
function MageFrost:ClearAllState()
    state.petResurrecting  = false
    state.petCCWasActive   = false
    state.petDeadWasActive = false
    NPA.notAttackingState.petNotAttackingStartTime = nil
    NPA.notAttackingState.petLastHadTargetTime     = nil
end

-- =============================================================
-- PreEvaluate  (rising-edge sounds)
-- =============================================================
function MageFrost:PreEvaluate(db)
    -- CC sound
    if db.notAttackingEnabled then
        local ccNow = NPA.PetIsCC()
        if ccNow and not state.petCCWasActive then
            NPA:PlayAlertSound("notAttacking")
        end
        state.petCCWasActive = ccNow
    end

    -- Pet dead sound
    if db.petDeadEnabled then
        local deadNow = (NPA.PetExists() and UnitIsDead("pet")) or state.petResurrecting
        if deadNow and not state.petDeadWasActive then
            NPA:PlayAlertSound("petDead")
        end
        state.petDeadWasActive = deadNow
    end
end

-- =============================================================
-- GetHighestPriorityAlert
-- =============================================================
function MageFrost:GetHighestPriorityAlert(db)
    if NPA.PetExists() then
        if not UnitIsDead("pet") then state.petResurrecting = false end
        if db.petDeadEnabled     and UnitIsDead("pet") then
            state.petResurrecting = true
            return 1  -- WATER ELE DIED
        end
        if db.notAttackingEnabled    and NPA.PetIsCC() then return 5 end
        if db.petPassiveEnabled      and NPA.PetIsPassive() then return 7 end
        if db.petNotAttackingEnabled and NPA.PetNotAttacking() then return 8 end
        if db.healPetEnabled         and NPA.PetNeedsHealing() then return 6 end
        return nil
    else
        if state.petResurrecting then return 1 end  -- hold WATER ELE DIED
        if db.noPetEnabled and not NPA.ShouldSuppressNoPet() then
            return 3  -- SUMMON WATER ELE
        end
        return nil
    end
end

-- =============================================================
-- OnEvent
-- =============================================================
function MageFrost:OnEvent(db, event, ...)
    if event == "UNIT_PET" then
        local unit = ...
        if unit == "player" then
            if NPA.PetExists() and not UnitIsDead("pet") then
                state.petResurrecting = false
                NPA:StopModuleTicker("mage")
                NPA.StartPetHealthTicker()
                NPA.SetDisplaySlot(nil)
            else
                NPA.StopPetHealthTicker()
                NPA:StartModuleTicker("mage", 0.25, function()
                    if NPA.PetExists() and not UnitIsDead("pet") then
                        NPA:StopModuleTicker("mage")
                    end
                    NPA.Evaluate()
                end)
            end
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

-- =============================================================
-- Debug
-- =============================================================
function MageFrost:Debug(db)
    local ok, err = pcall(function()
        NPA.Msg("spec=Frost"
            .. "  hasSummon=" .. tostring(NPA.IsSpellKnownByPlayer(SPELL_SUMMON_WATER_ELEMENTAL))
            .. "  petRes=" .. tostring(state.petResurrecting)
            .. "  specID=" .. tostring(NPA.GetSpecID()))
    end)
    if not ok then NPA.Msg("ERROR(mage_frost): " .. tostring(err)) end
end

-- =============================================================
-- Register
-- =============================================================
NPA:RegisterSpec("MageFrost", MageFrost)
