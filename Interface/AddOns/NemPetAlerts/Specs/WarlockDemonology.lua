-- =============================================================
-- Specs/WarlockDemonology.lua
-- Nem: Pet Alerts — Demonology Warlock spec module
--
-- FULLY SELF-CONTAINED. Zero dependencies on other spec modules.
--
-- Alerts:
--   1. Demon Died           — pet dies
--   2. Sacrifice Demon      — Grimoire of Sacrifice reminder
--   3. Summon Demon         — no pet out
--   4. Turn Off Demon Taunt — Voidwalker/Felguard taunt autocast
--   5. Demon In CC          — pet has crowd control aura
--   6. Heal Demon           — pet health below threshold (ColorCurve)
--   7. Demon On Passive     — passive stance while in combat
--   8. Demon Not Attacking  — pet idle in combat after grace period
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
local SPEC_ID = 266  -- Demonology

-- =============================================================
-- Spell IDs
-- =============================================================
local SPELL_GRIMOIRE_OF_SACRIFICE = 108503
local SPELL_SAC_BUFF              = 196099
local SPELL_SUFFERING             = 17735
local SPELL_THREATENING_PRESENCE  = 112042

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
--   Row 1 (+52):  [1] Demon Died
--   Row 2 (+25):  [6] Heal Demon
--   Row 3 ( -2):  [3] Summon Demon
--   Row 4 (-29):  [2] Sacrifice Demon  /  [7] Demon On Passive
--   Row 5 (-56):  [4] Turn Off Taunt   /  [8] Demon Not Attacking
--   Row 6 (-83):  [5] Demon In CC

local ALERTS = {
    { key = "petDead",         label = "Demon Died",             text = "* DEMON DIED *",             defaultColor = { r=1.0,    g=0.2039, b=0.1569 }, yOffset =  52, defaultSound = "OhNo",   soundLabel = "Pet Died" },
    { key = "fakeDeath",       label = "Sacrifice Demon",        text = "* SACRIFICE DEMON *",        defaultColor = { r=0.6980, g=0.3333, b=1.0    }, yOffset = -29 },
    { key = "noPet",           label = "Summon Demon",           text = "* SUMMON DEMON *",           defaultColor = { r=0.9098, g=0.4118, b=0.0    }, yOffset =  -2 },
    { key = "tauntAuto",       label = "Demon Taunt Autocast",   text = "* TURN OFF DEMON TAUNT *",  defaultColor = { r=0.9059, g=0.2667, b=1.0    }, yOffset = -56 },
    { key = "notAttacking",    label = "Demon In CC",            text = "* DEMON IN CC *",            defaultColor = { r=0.2824, g=0.6549, b=1.0    }, yOffset = -83, defaultSound = "Sonarr", soundLabel = "Pet CC"  },
    { key = "healPet",         label = "Heal Demon",             text = "* HEAL DEMON *",             defaultColor = { r=0.1882, g=1.0,    b=0.3098 }, yOffset =  25 },
    { key = "petPassive",      label = "Demon On Passive",       text = "* DEMON ON PASSIVE *",       defaultColor = { r=1.0,    g=0.5843, b=0.1333 }, yOffset = -29 },
    { key = "petNotAttacking", label = "Demon Not Attacking",    text = "* DEMON NOT ATTACKING *",    defaultColor = { r=1.0,    g=0.8588, b=0.0    }, yOffset = -56 },
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
-- Sacrifice Buff Detection
-- =============================================================
local function IsWarlockSacBuffActive()
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i = 1, 40 do
            local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
            if not aura then break end
            local id = aura.spellId
            if issecretvalue and issecretvalue(id) then
                -- skip tainted
            elseif id == SPELL_SAC_BUFF then
                return true
            end
        end
        return false
    end
    for i = 1, 40 do
        local name, _, _, _, _, _, _, _, _, spellID = UnitAura("player", i, "HELPFUL")
        if not name then break end
        if spellID == SPELL_SAC_BUFF then return true end
    end
    return false
end

-- =============================================================
-- Taunt Autocast Detection
-- =============================================================
local function IsWarlockPetTauntAutocastEnabled()
    if not HasPetUI() or not NPA.PetExists() then return false end
    for i = 1, 20 do
        local _, _, isToken, _, autoCastAllowed, autoCastEnabled, spellID = GetPetActionInfo(i)
        if not isToken and spellID then
            if spellID == SPELL_SUFFERING or spellID == SPELL_THREATENING_PRESENCE then
                if autoCastAllowed and autoCastEnabled then return true end
            end
        end
    end
    return false
end

-- =============================================================
-- Module Table
-- =============================================================
local WarlockDemonology = {
    class             = "WARLOCK",
    specID            = SPEC_ID,
    specName          = "Demonology Warlock",
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
function WarlockDemonology:ShouldRun(db)
    if not db.enabled then return false end
    return NPA.GetSpecID() == SPEC_ID
end

-- =============================================================
-- OnActivate
-- =============================================================
function WarlockDemonology:OnActivate(db)
    state.petDeadWasActive = (NPA.PetExists() and UnitIsDead("pet")) or false
    if NPA.PetExists() and not UnitIsDead("pet") then
        NPA.StartPetHealthTicker()
    end
end

-- =============================================================
-- ClearAllState
-- =============================================================
function WarlockDemonology:ClearAllState()
    state.petResurrecting  = false
    state.petCCWasActive   = false
    state.petDeadWasActive = false
    NPA.notAttackingState.petNotAttackingStartTime = nil
    NPA.notAttackingState.petLastHadTargetTime     = nil
end

-- =============================================================
-- PreEvaluate  (rising-edge sounds)
-- =============================================================
function WarlockDemonology:PreEvaluate(db)
    -- CC sound
    if db.notAttackingEnabled then
        local ccNow = NPA.PetIsCC()
        if ccNow and not state.petCCWasActive then
            NPA:PlayAlertSound("notAttacking")
        end
        state.petCCWasActive = ccNow
    end

    -- Pet dead sound — suppressed when Sac buff is active
    if db.petDeadEnabled then
        local sacSuppressed = NPA.IsSpellKnownByPlayer(SPELL_GRIMOIRE_OF_SACRIFICE)
                              and IsWarlockSacBuffActive()
        local deadNow = not sacSuppressed
                        and ((NPA.PetExists() and UnitIsDead("pet")) or state.petResurrecting)
        if deadNow and not state.petDeadWasActive then
            NPA:PlayAlertSound("petDead")
        end
        state.petDeadWasActive = deadNow
    end
end

-- =============================================================
-- GetHighestPriorityAlert
-- =============================================================
function WarlockDemonology:GetHighestPriorityAlert(db)
    -- Grimoire of Sacrifice handling
    if NPA.IsSpellKnownByPlayer(SPELL_GRIMOIRE_OF_SACRIFICE) then
        if IsWarlockSacBuffActive() then
            return nil  -- Sac buff active: all alerts suppressed
        end
        if not NPA.PetExists() then
            if not NPA.ShouldSuppressNoPet() then
                return db.noPetEnabled and 3 or nil  -- SUMMON DEMON
            end
            return nil
        elseif UnitIsDead("pet") then
            -- Fall through to generic dead handler below
        else
            -- Pet alive with Sac talented but buff not active
            if db.notAttackingEnabled    and NPA.PetIsCC() then return 5 end
            if db.petPassiveEnabled      and NPA.PetIsPassive() then return 7 end
            if db.petNotAttackingEnabled and NPA.PetNotAttacking() then return 8 end
            if db.healPetEnabled         and NPA.PetNeedsHealing() then return 6 end
            if db.fakeDeathEnabled       then return 2 end  -- SACRIFICE DEMON
            return nil
        end
    end

    -- Generic handler (no Sac talent, or pet is dead with Sac talented)
    if not NPA.PetExists() then
        if state.petResurrecting then return 1 end
        if db.noPetEnabled and not NPA.ShouldSuppressNoPet() then
            return 3  -- SUMMON DEMON
        end
        return nil
    end

    if not UnitIsDead("pet") then state.petResurrecting = false end

    if db.petDeadEnabled     and UnitIsDead("pet") then
        state.petResurrecting = true
        return 1  -- DEMON DIED
    end
    if db.tauntAutoEnabled       and NPA.IsTauntGroupConditionMet()
                                 and IsWarlockPetTauntAutocastEnabled() then return 4 end
    if db.notAttackingEnabled    and NPA.PetIsCC() then return 5 end
    if db.petPassiveEnabled      and NPA.PetIsPassive() then return 7 end
    if db.petNotAttackingEnabled and NPA.PetNotAttacking() then return 8 end
    if db.healPetEnabled         and NPA.PetNeedsHealing() then return 6 end

    return nil
end

-- =============================================================
-- OnEvent
-- =============================================================
function WarlockDemonology:OnEvent(db, event, ...)
    if event == "UNIT_PET" then
        local unit = ...
        if unit == "player" then
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
function WarlockDemonology:Debug(db)
    local ok, err = pcall(function()
        NPA.Msg("spec=Demonology"
            .. "  sacTalent=" .. tostring(NPA.IsSpellKnownByPlayer(SPELL_GRIMOIRE_OF_SACRIFICE))
            .. "  sacBuff=" .. tostring(IsWarlockSacBuffActive())
            .. "  specID=" .. tostring(NPA.GetSpecID()))
    end)
    if not ok then NPA.Msg("ERROR(warlock_demo): " .. tostring(err)) end
end

-- =============================================================
-- Register
-- =============================================================
NPA:RegisterSpec("WarlockDemonology", WarlockDemonology)
