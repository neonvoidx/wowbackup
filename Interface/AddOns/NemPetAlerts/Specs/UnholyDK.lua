-- =============================================================
-- Specs/UnholyDK.lua
-- Nem: Pet Alerts — Unholy Death Knight class module
--
-- FULLY SELF-CONTAINED. Zero dependencies on other class modules.
--
-- Alerts:
--   1. (unused)              — no reliable Ghoul death detection
--   2. (unused)              — no fake death for DK
--   3. Raise Ghoul           — no pet out
--   4. (unused)              — no taunt for DK
--   5. Ghoul In CC           — pet has crowd control aura
--   6. Heal Ghoul            — pet health below threshold (ColorCurve)
--   7. Ghoul On Passive      — passive stance while in combat
--   8. Ghoul Not Attacking   — pet idle in combat after grace period
-- =============================================================

local NPA = _G.NemPetAlerts
if not NPA then return end

local UnitExists     = UnitExists
local UnitIsDead     = UnitIsDead

-- =============================================================
-- Spell IDs
-- =============================================================
local SPEC_UNHOLY_DK       = 252
local SPELL_RAISE_DEAD     = 46584

-- =============================================================
-- State
-- =============================================================
local state = {
    petCCWasActive = false,
}

-- =============================================================
-- Alert Definitions
-- =============================================================
local ALERTS = {
    { key = "petDead",         label = "Pet Died  (no Ghoul detection)",text = "* PET DIED *",             defaultColor = { r=1.0,    g=0.2039, b=0.1569 }, yOffset =  52 },
    { key = "fakeDeath",       label = "Wake Up Pet  (Hunter only)",    text = "* WAKE UP PET *",          defaultColor = { r=0.6980, g=0.3333, b=1.0    }, yOffset = -29 },
    { key = "noPet",           label = "Raise Ghoul",                   text = "* RAISE GHOUL *",          defaultColor = { r=0.9098, g=0.4118, b=0.0    }, yOffset =  -2 },
    { key = "tauntAuto",       label = "Taunt  (Hunter/Warlock only)",  text = "* TURN OFF AUTOCAST TAUNT *",defaultColor = { r=0.9059, g=0.2667, b=1.0  }, yOffset = -56 },
    { key = "notAttacking",    label = "Ghoul In CC",                   text = "* GHOUL IN CC *",          defaultColor = { r=0.2824, g=0.6549, b=1.0    }, yOffset = -83, defaultSound = "Sonarr", soundLabel = "Pet CC"   },
    { key = "healPet",         label = "Heal Ghoul",                    text = "* HEAL GHOUL *",           defaultColor = { r=0.1882, g=1.0,    b=0.3098 }, yOffset =  25 },
    { key = "petPassive",      label = "Ghoul On Passive",              text = "* GHOUL ON PASSIVE *",     defaultColor = { r=1.0,    g=0.5843, b=0.1333 }, yOffset = -29 },
    { key = "petNotAttacking", label = "Ghoul Not Attacking",           text = "* GHOUL NOT ATTACKING *",  defaultColor = { r=1.0,    g=0.8588, b=0.0    }, yOffset = -56 },
}

-- =============================================================
-- Test Slots (DK: no petDead, fakeDeath, or taunt)
-- =============================================================
local TEST_SLOTS = { [3]=true, [5]=true, [6]=true, [7]=true, [8]=true }

-- =============================================================
-- Defaults
-- =============================================================
local DEFAULTS = {
    petDeadEnabled         = false,  -- no reliable Ghoul death detection
    fakeDeathEnabled       = false,  -- not applicable to DK
    noPetEnabled           = true,
    tauntAutoEnabled       = false,  -- not applicable to DK
    notAttackingEnabled    = true,
    notAttackingSoundEnabled = true,
    notAttackingSoundName  = "Sonarr",
    healPetEnabled         = true,
    petPassiveEnabled      = true,
    petNotAttackingEnabled = true,
}

-- =============================================================
-- Module Table
-- =============================================================
local UnholyDK = {
    class             = "DEATHKNIGHT",
    className         = "Unholy Death Knight",
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
function UnholyDK:ShouldRun(db)
    if not db.enabled then return false end
    return NPA.GetSpecID() == SPEC_UNHOLY_DK
end

-- =============================================================
-- OnActivate
-- =============================================================
function UnholyDK:OnActivate(db)
    if NPA.PetExists() and not UnitIsDead("pet") then
        NPA.StartPetHealthTicker()
    else
        NPA:StartModuleTicker("dk", 0.25, function()
            if NPA.PetExists() and not UnitIsDead("pet") then
                NPA:StopModuleTicker("dk")
            end
            NPA.Evaluate()
        end)
    end
end

-- =============================================================
-- ClearAllState
-- =============================================================
function UnholyDK:ClearAllState()
    state.petCCWasActive = false
    NPA.notAttackingState.petNotAttackingStartTime = nil
    NPA.notAttackingState.petLastHadTargetTime     = nil
end

-- =============================================================
-- PreEvaluate  (rising-edge sounds)
-- =============================================================
function UnholyDK:PreEvaluate(db)
    if db.notAttackingEnabled then
        local ccNow = NPA.PetIsCC()
        if ccNow and not state.petCCWasActive then
            NPA:PlayAlertSound("notAttacking")
        end
        state.petCCWasActive = ccNow
    end
end

-- =============================================================
-- GetHighestPriorityAlert
-- =============================================================
function UnholyDK:GetHighestPriorityAlert(db)
    if NPA.PetExists() then
        if db.notAttackingEnabled    and NPA.PetIsCC() then return 5 end
        if db.petPassiveEnabled      and NPA.PetIsPassive() then return 7 end
        if db.petNotAttackingEnabled and NPA.PetNotAttacking() then return 8 end
        if db.healPetEnabled         and NPA.PetNeedsHealing() then return 6 end
        return nil
    else
        if db.noPetEnabled and not NPA.ShouldSuppressNoPet() then
            return 3  -- RAISE GHOUL
        end
        return nil
    end
end

-- =============================================================
-- OnEvent
-- =============================================================
function UnholyDK:OnEvent(db, event, ...)
    if event == "UNIT_PET" then
        local unit = ...
        if unit == "player" then
            local petBack = NPA.PetExists() and not UnitIsDead("pet")
            if petBack then
                NPA:StopModuleTicker("dk")
                NPA.StartPetHealthTicker()
                NPA.SetDisplaySlot(nil)
            else
                NPA.StopPetHealthTicker()
                NPA:StartModuleTicker("dk", 0.25, function()
                    if NPA.PetExists() and not UnitIsDead("pet") then
                        NPA:StopModuleTicker("dk")
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
function UnholyDK:Debug(db)
    local ok, err = pcall(function()
        NPA.Msg("specID=" .. tostring(NPA.GetSpecID())
            .. "  isUnholy=" .. tostring(NPA.GetSpecID() == SPEC_UNHOLY_DK))
    end)
    if not ok then NPA.Msg("ERROR(dk): " .. tostring(err)) end
end

-- =============================================================
-- Register
-- =============================================================
NPA:RegisterClass("DEATHKNIGHT", UnholyDK)
