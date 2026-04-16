-- =============================================================
-- Specs/HunterBeastMastery.lua
-- Nem: Pet Alerts — Beast Mastery Hunter spec module
--
-- FULLY SELF-CONTAINED. Zero dependencies on other spec modules.
--
-- Alerts:
--   1. Pet Died            — pet dies or is resurrecting
--   2. Wake Up Pet         — Play Dead / Feign Death active
--   3. Call Pet            — no pet out (suppressed while mounted)
--   4. Turn Off Pet Taunt  — Growl autocast on in group 5+
--   5. Pet In CC           — pet has crowd control aura
--   6. Heal Pet            — pet health below threshold (ColorCurve)
--   7. Pet On Passive      — passive stance while in combat
--   8. Pet Not Attacking   — pet idle in combat after grace period
-- =============================================================

local NPA = _G.NemPetAlerts
if not NPA then return end

local GetTime        = GetTime
local UnitExists     = UnitExists
local UnitIsDead     = UnitIsDead
local issecretvalue  = NPA.issecretvalue
local C_UnitAuras    = C_UnitAuras

-- =============================================================
-- Spec Constants
-- =============================================================
local SPEC_ID = 253  -- Beast Mastery

-- =============================================================
-- Spell IDs
-- =============================================================
local SPELL_GROWL     = 2649
local SPELL_PLAY_DEAD = 209997
local SPELL_WAKE_UP   = 210000

-- =============================================================
-- State
-- =============================================================
local state = {
    petFakeDeathActive   = false,
    wakeOverrideUntil    = 0,
    petResurrecting      = false,
    petCCWasActive       = false,
    petDeadWasActive     = false,
}

-- =============================================================
-- Alert Definitions
-- =============================================================
-- Row layout (Y offsets):
--   Row 1 (+52):  [1] Pet Died
--   Row 2 (+25):  [6] Heal Pet
--   Row 3 ( -2):  [3] Call Pet
--   Row 4 (-29):  [2] Wake Up Pet  /  [7] Pet On Passive
--   Row 5 (-56):  [4] Turn Off Taunt  /  [8] Pet Not Attacking
--   Row 6 (-83):  [5] Pet In CC

local ALERTS = {
    { key = "petDead",         label = "Pet Died",             text = "* PET DIED *",              defaultColor = { r=1.0,    g=0.2039, b=0.1569 }, yOffset =  52, defaultSound = "OhNo",   soundLabel = "Pet Died" },
    { key = "fakeDeath",       label = "Wake Up Pet",          text = "* WAKE UP PET *",           defaultColor = { r=0.6980, g=0.3333, b=1.0    }, yOffset = -29 },
    { key = "noPet",           label = "Call Pet",             text = "* CALL PET *",              defaultColor = { r=0.9098, g=0.4118, b=0.0    }, yOffset =  -2 },
    { key = "tauntAuto",       label = "Pet Taunt Autocast",   text = "* TURN OFF PET TAUNT *",   defaultColor = { r=0.9059, g=0.2667, b=1.0    }, yOffset = -56 },
    { key = "notAttacking",    label = "Pet In CC",            text = "* PET IN CC *",             defaultColor = { r=0.2824, g=0.6549, b=1.0    }, yOffset = -83, defaultSound = "Sonarr", soundLabel = "Pet CC"  },
    { key = "healPet",         label = "Heal Pet",             text = "* HEAL PET *",              defaultColor = { r=0.1882, g=1.0,    b=0.3098 }, yOffset =  25 },
    { key = "petPassive",      label = "Pet On Passive",       text = "* PET ON PASSIVE *",        defaultColor = { r=1.0,    g=0.5843, b=0.1333 }, yOffset = -29 },
    { key = "petNotAttacking", label = "Pet Not Attacking",    text = "* PET NOT ATTACKING *",     defaultColor = { r=1.0,    g=0.8588, b=0.0    }, yOffset = -56 },
}

-- =============================================================
-- Test Slots (all 6 screen rows filled)
-- =============================================================
local TEST_SLOTS = { [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true }

-- =============================================================
-- Defaults
-- =============================================================
local DEFAULTS = {
    petDeadEnabled           = true,
    petDeadSoundEnabled      = true,
    petDeadSoundName         = "OhNo",
    fakeDeathEnabled         = true,
    noPetEnabled             = true,
    tauntAutoEnabled         = true,
    notAttackingEnabled      = true,
    notAttackingSoundEnabled = true,
    notAttackingSoundName    = "Sonarr",
    healPetEnabled           = true,
    petPassiveEnabled        = true,
    petNotAttackingEnabled   = true,
}

-- =============================================================
-- Fake Death Detection
-- =============================================================
local function DetectPetFakeDeathDirect()
    if not NPA.PetExists() or UnitIsDead("pet") then return false end
    if UnitIsFeignDeath and UnitIsFeignDeath("pet") then return true end
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local aura = C_UnitAuras.GetAuraDataByIndex("pet", i, "HELPFUL")
            if not aura then break end
            local id = aura.spellId
            if not (issecretvalue and issecretvalue(id)) then
                if id == SPELL_PLAY_DEAD then return true end
            end
        end
        return false
    end
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellID = UnitAura("pet", i, "HELPFUL")
        if not name then break end
        if spellID == SPELL_PLAY_DEAD then return true end
    end
    return false
end

local function PetHasPlayDead()
    if not NPA.PetExists() or UnitIsDead("pet") then return false end
    if state.wakeOverrideUntil > GetTime() then return false end
    if state.petFakeDeathActive then return true end
    return DetectPetFakeDeathDirect()
end

-- =============================================================
-- Growl Detection
-- =============================================================
local function IsGrowlAutocastEnabled()
    if not HasPetUI() or not NPA.PetExists() then return false end
    for i = 1, 20 do
        local _, _, isToken, _, autoCastAllowed, autoCastEnabled, spellID = GetPetActionInfo(i)
        if not isToken and spellID == SPELL_GROWL then
            return autoCastAllowed and autoCastEnabled
        end
    end
    return false
end

-- =============================================================
-- Module Table
-- =============================================================
local HunterBeastMastery = {
    class             = "HUNTER",
    specID            = SPEC_ID,
    specName          = "Beast Mastery Hunter",
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
        "UNIT_SPELLCAST_SUCCEEDED",
        "PET_BAR_UPDATE",
        "PET_BAR_UPDATE_USABLE",
        "PET_UI_UPDATE",
        "GROUP_ROSTER_UPDATE",
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
function HunterBeastMastery:ShouldRun(db)
    if not db.enabled then return false end
    return NPA.GetSpecID() == SPEC_ID
end

-- =============================================================
-- OnActivate
-- =============================================================
function HunterBeastMastery:OnActivate(db)
    state.petDeadWasActive = (NPA.PetExists() and UnitIsDead("pet")) or false
    if NPA.PetExists() and not UnitIsDead("pet") then
        NPA.StartPetHealthTicker()
    end
end

-- =============================================================
-- ClearAllState
-- =============================================================
function HunterBeastMastery:ClearAllState()
    state.petFakeDeathActive = false
    state.wakeOverrideUntil  = 0
    state.petResurrecting    = false
    state.petCCWasActive     = false
    state.petDeadWasActive   = false
    NPA.notAttackingState.petNotAttackingStartTime = nil
    NPA.notAttackingState.petLastHadTargetTime     = nil
end

-- =============================================================
-- PreEvaluate  (rising-edge sounds)
-- =============================================================
function HunterBeastMastery:PreEvaluate(db)
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
function HunterBeastMastery:GetHighestPriorityAlert(db)
    if not NPA.PetExists() then
        if state.petResurrecting then return 1 end  -- PET DIED
        if db.noPetEnabled and not NPA.ShouldSuppressNoPet() then
            return 3  -- CALL PET
        end
        return nil
    end

    if not UnitIsDead("pet") then state.petResurrecting = false end

    if db.petDeadEnabled     and UnitIsDead("pet") then
        state.petResurrecting = true
        return 1  -- PET DIED
    end
    if db.fakeDeathEnabled       and PetHasPlayDead() then return 2 end
    if db.tauntAutoEnabled       and NPA.IsTauntGroupConditionMet()
                                 and IsGrowlAutocastEnabled() then return 4 end
    if db.notAttackingEnabled    and NPA.PetIsCC() then return 5 end
    if db.petPassiveEnabled      and NPA.PetIsPassive() then return 7 end
    if db.petNotAttackingEnabled and NPA.PetNotAttacking() then return 8 end
    if db.healPetEnabled         and NPA.PetNeedsHealing() then return 6 end

    return nil
end

-- =============================================================
-- OnEvent
-- =============================================================
function HunterBeastMastery:OnEvent(db, event, ...)
    if event == "UNIT_PET" then
        local unit = ...
        if unit == "player" then
            state.petFakeDeathActive = false
            state.wakeOverrideUntil  = 0
            if NPA.PetExists() and not UnitIsDead("pet") then
                state.petResurrecting = false
                NPA.StartPetHealthTicker()
                NPA.SetDisplaySlot(nil)
            else
                NPA.StopPetHealthTicker()
            end
            C_Timer.After(0.1, NPA.Evaluate)
        end
        return true
    end

    if event == "UNIT_AURA" then
        local unit = ...
        if unit == "pet" then
            local direct = DetectPetFakeDeathDirect()
            if direct then
                state.petFakeDeathActive = true
            elseif state.wakeOverrideUntil <= GetTime() then
                state.petFakeDeathActive = false
            end
            C_Timer.After(0.1, NPA.Evaluate)
        elseif unit == "player" then
            C_Timer.After(0.1, NPA.Evaluate)
        end
        return true
    end

    if event == "UNIT_HEALTH" then
        NPA.Evaluate()
        return true
    end

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, _, spellID = ...
        if unitTarget ~= "pet" and unitTarget ~= "player" then return true end
        if spellID == SPELL_PLAY_DEAD then
            state.petFakeDeathActive = true
            state.wakeOverrideUntil  = 0
            NPA.Evaluate()
            C_Timer.After(0.1, NPA.Evaluate)
        elseif spellID == SPELL_WAKE_UP then
            state.petFakeDeathActive = false
            state.wakeOverrideUntil  = GetTime() + 1.5
            NPA.SetDisplaySlot(nil)
            C_Timer.After(0.1, NPA.Evaluate)
            C_Timer.After(1.6, function()
                state.wakeOverrideUntil = 0
                NPA.Evaluate()
            end)
        end
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
function HunterBeastMastery:Debug(db)
    local ok, err = pcall(function()
        NPA.Msg("spec=BeastMastery"
            .. "  fakeDeath=" .. tostring(state.petFakeDeathActive)
            .. "  petRes=" .. tostring(state.petResurrecting)
            .. "  specID=" .. tostring(NPA.GetSpecID()))
    end)
    if not ok then NPA.Msg("ERROR(hunter_bm): " .. tostring(err)) end
end

-- =============================================================
-- Register
-- =============================================================
NPA:RegisterSpec("HunterBeastMastery", HunterBeastMastery)
