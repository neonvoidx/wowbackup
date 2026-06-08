-- ============================================================
-- NemPetAlerts/Specs/WarlockDemonology.lua
-- Demonology Warlock spec module.
-- ============================================================

local NPA = _G.NemPetAlerts
if not NPA then return end

local UnitIsDead     = UnitIsDead
local issecretvalue  = NPA.issecretvalue
local C_UnitAuras    = C_UnitAuras

-- ============================================================
-- Spec Constants
-- ============================================================
local SPEC_ID = 266

-- ============================================================
-- Spell IDs
-- ============================================================
local TAUNT_SPELL_IDS = {
    [17735]  = true,   -- Suffering, Voidwalker
    [112042] = true,   -- Threatening Presence, Voidwalker
    [134477] = true,   -- Threatening Presence, Felguard
}

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
    { key = "petDead",         label = "Demon Died",             text = "* DEMON DIED *",             defaultColor = { r=1.0,    g=0.2039, b=0.1569 }, yOffset =  52, defaultSound = "Warlock: Demon Died",          soundLabel = "Demon Died",          priority = NPA.VOICE_PRIO_CRITICAL },
    { key = "noPet",           label = "Summon Demon",           text = "* SUMMON DEMON *",           defaultColor = { r=0.9098, g=0.4118, b=0.0    }, yOffset =  -2, defaultSound = "Warlock: Summon Demon",        soundLabel = "Summon Demon",        priority = NPA.VOICE_PRIO_CRITICAL },
    { key = "tauntAuto",       label = "Demon Taunt Autocast",   text = "* TURN OFF DEMON TAUNT *",   defaultColor = { r=0.9059, g=0.2667, b=1.0    }, yOffset = -56, defaultSound = "Warlock: Toggle Demon Taunt",  soundLabel = "Demon Taunt",         priority = NPA.VOICE_PRIO_NORMAL },
    { key = "petInCC",    label = "Demon In CC",            text = "* DEMON IN CC *",            defaultColor = { r=0.2824, g=0.6549, b=1.0    }, yOffset = -83, defaultSound = "Warlock: Demon in CC",         soundLabel = "Demon CC",            priority = NPA.VOICE_PRIO_HIGH },
    { key = "healPet",         label = "Heal Demon",             text = "* HEAL DEMON *",             defaultColor = { r=0.1882, g=1.0,    b=0.3098 }, yOffset =  25, defaultSound = "Warlock: Heal Demon",          soundLabel = "Heal Demon",          noSound = true },
    { key = "petPassive",      label = "Demon On Passive",       text = "* DEMON ON PASSIVE *",       defaultColor = { r=1.0,    g=0.5843, b=0.1333 }, yOffset = -29, defaultSound = "Warlock: Demon on Passive",    soundLabel = "Demon On Passive",    priority = NPA.VOICE_PRIO_NORMAL },
    { key = "petNotAttacking", label = "Demon Not Attacking",    text = "* DEMON NOT ATTACKING *",    defaultColor = { r=1.0,    g=0.8588, b=0.0    }, yOffset = -56, defaultSound = "Warlock: Demon Not Attacking", soundLabel = "Demon Not Attacking", priority = NPA.VOICE_PRIO_HIGH },
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
    petDeadSoundName            = "Warlock: Demon Died",
    noPetEnabled                = true,
    noPetSoundEnabled           = true,
    noPetSoundName              = "Warlock: Summon Demon",
    tauntAutoEnabled            = true,
    tauntAutoSoundEnabled       = true,
    tauntAutoSoundName          = "Warlock: Toggle Demon Taunt",
    petInCCEnabled         = true,
    petInCCSoundEnabled    = true,
    petInCCSoundName       = "Warlock: Demon in CC",
    healPetEnabled              = true,
    petPassiveEnabled           = true,
    petPassiveSoundEnabled      = true,
    petPassiveSoundName         = "Warlock: Demon on Passive",
    petNotAttackingEnabled      = true,
    petNotAttackingSoundEnabled = true,
    petNotAttackingSoundName    = "Warlock: Demon Not Attacking",
}

-- ============================================================
-- Taunt Autocast Detection
-- ============================================================
local function IsWarlockPetTauntAutocastEnabled()
    if not HasPetUI() or not NPA.PetExists() then return false end
    for i = 1, 20 do
        local _, _, isToken, _, autoCastAllowed, autoCastEnabled, spellID = GetPetActionInfo(i)
        if not isToken and spellID then
            if TAUNT_SPELL_IDS[spellID] then
                if autoCastAllowed and autoCastEnabled then return true end
            end
        end
    end
    return false
end

-- ============================================================
-- Module Table
-- ============================================================
local WarlockDemonology = {
    class             = "WARLOCK",
    specID            = SPEC_ID,
    specName          = "Demonology Warlock",
    alerts            = ALERTS,
    testSlots         = TEST_SLOTS,
    defaults          = DEFAULTS,
    state             = state,
    hasHealPet        = true,
    healPetAlertIndex = 5,

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
    },

    extraUnitEvents = {
        { "UNIT_HEALTH", "pet" },
    },
}

-- ============================================================
-- ShouldRun
-- ============================================================
function WarlockDemonology:ShouldRun(db)
    if not db.enabled then return false end
    return NPA.GetSpecID() == SPEC_ID
end

-- ============================================================
-- ClearAllState
-- ============================================================
function WarlockDemonology:ClearAllState()
    state.petResurrecting = false
    NPA.notAttackingState.petNotAttackingStartTime = nil
    NPA.notAttackingState.petLastHadTargetTime     = nil
end

-- ============================================================
-- GetHighestPriorityAlert
-- ============================================================
function WarlockDemonology:GetHighestPriorityAlert(db)
    if not NPA.PetExists() then
        if state.petResurrecting then return 1 end
        if db.noPetEnabled and not NPA.ShouldSuppressNoPet() then
            return 2
        end
        return nil
    end

    if not UnitIsDead("pet") then state.petResurrecting = false end

    if db.petDeadEnabled     and UnitIsDead("pet") then
        state.petResurrecting = true
        return 1
    end
    if db.tauntAutoEnabled       and NPA.IsTauntGroupConditionMet()
                                 and IsWarlockPetTauntAutocastEnabled() then return 3 end
    if db.petInCCEnabled    and NPA.PetIsCC() then return 4 end
    if db.petPassiveEnabled      and NPA.PetIsPassive() then return 6 end
    if db.petNotAttackingEnabled and NPA.PetNotAttacking() then return 7 end
    if db.healPetEnabled         and NPA.PetNeedsHealing() then return 5 end

    return nil
end

-- ============================================================
-- OnEvent
-- ============================================================
function WarlockDemonology:OnEvent(db, event, ...)
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
function WarlockDemonology:Debug(db)
    local ok, err = pcall(function()
        NPA.Msg("spec=Demonology"
            .. "  specID=" .. tostring(NPA.GetSpecID()))
    end)
    if not ok then NPA.Msg("ERROR(warlock_demo): " .. tostring(err)) end
end

-- ============================================================
-- Alert Options
-- ============================================================
function WarlockDemonology:BuildAlertOptions(box, db, helpers)
    helpers:MakeNumericInput("Heal Pet Threshold (%)", 1, 99,
        function() return db.healPetThreshold or 50 end,
        function(v) db.healPetThreshold = v; NPA.ResetHealthCurve() end)
end

-- ============================================================
-- Register
-- ============================================================
NPA:RegisterSpec("WarlockDemonology", WarlockDemonology)
