-- ============================================================
-- NemPetAlerts/Specs/HunterMarksmanship.lua
-- Marksmanship Hunter spec module.
-- ============================================================

local NPA = _G.NemPetAlerts
if not NPA then return end

local GetTime        = GetTime
local UnitIsDead     = UnitIsDead
local issecretvalue  = NPA.issecretvalue
local C_UnitAuras    = C_UnitAuras

-- ============================================================
-- Spec Constants
-- ============================================================
local SPEC_ID = 254

-- ============================================================
-- Spell IDs
-- ============================================================
local SPELL_UNBREAKABLE_BOND = 1223323     -- SpellID
local SPELL_GROWL            = 2649        -- SpellID
local SPELL_PLAY_DEAD        = 209997      -- SpellID
local SPELL_WAKE_UP          = 210000      -- SpellID

-- ============================================================
-- State
-- ============================================================
local state = {
    petFakeDeathActive = false,
    wakeOverrideUntil  = 0,
    petResurrecting    = false,
}

-- ============================================================
-- Alert Definitions
-- ============================================================
local ALERTS = {
    { key = "petDead",         label = "Pet Died",             text = "* PET DIED *",              defaultColor = { r=1.0,    g=0.2039, b=0.1569 }, yOffset =  52, defaultSound = "Hunter: Pet Died",          soundLabel = "Pet Died",            priority = NPA.VOICE_PRIO_CRITICAL },
    { key = "fakeDeath",       label = "Wake Up Pet",          text = "* WAKE UP PET *",           defaultColor = { r=0.6980, g=0.3333, b=1.0    }, yOffset = -29, defaultSound = "Hunter: Wake Up Pet",       soundLabel = "Wake Up Pet",         priority = NPA.VOICE_PRIO_HIGH },
    { key = "noPet",           label = "Call Pet",             text = "* CALL PET *",              defaultColor = { r=0.9098, g=0.4118, b=0.0    }, yOffset =  -2, defaultSound = "Hunter: Call Pet",          soundLabel = "Call Pet",            priority = NPA.VOICE_PRIO_CRITICAL },
    { key = "tauntAuto",       label = "Pet Taunt Autocast",   text = "* TURN OFF PET TAUNT *",    defaultColor = { r=0.9059, g=0.2667, b=1.0    }, yOffset = -56, defaultSound = "Hunter: Toggle Pet Taunt",  soundLabel = "Pet Taunt Autocast",  priority = NPA.VOICE_PRIO_NORMAL },
    { key = "petInCC",    label = "Pet In CC",            text = "* PET IN CC *",             defaultColor = { r=0.2824, g=0.6549, b=1.0    }, yOffset = -83, defaultSound = "Hunter: Pet in CC",         soundLabel = "Pet CC",              priority = NPA.VOICE_PRIO_HIGH },
    { key = "healPet",         label = "Heal Pet",             text = "* HEAL PET *",              defaultColor = { r=0.1882, g=1.0,    b=0.3098 }, yOffset =  25, defaultSound = "Hunter: Heal Pet",          soundLabel = "Heal Pet",            noSound = true },
    { key = "petPassive",      label = "Pet On Passive",       text = "* PET ON PASSIVE *",        defaultColor = { r=1.0,    g=0.5843, b=0.1333 }, yOffset = -29, defaultSound = "Hunter: Pet on Passive",    soundLabel = "Pet On Passive",      priority = NPA.VOICE_PRIO_NORMAL },
    { key = "petNotAttacking", label = "Pet Not Attacking",    text = "* PET NOT ATTACKING *",     defaultColor = { r=1.0,    g=0.8588, b=0.0    }, yOffset = -56, defaultSound = "Hunter: Pet Not Attacking", soundLabel = "Pet Not Attacking",   priority = NPA.VOICE_PRIO_HIGH },
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
    petDeadSoundName            = "Hunter: Pet Died",
    fakeDeathEnabled            = true,
    fakeDeathSoundEnabled       = true,
    fakeDeathSoundName          = "Hunter: Wake Up Pet",
    noPetEnabled                = true,
    noPetSoundEnabled           = true,
    noPetSoundName              = "Hunter: Call Pet",
    tauntAutoEnabled            = true,
    tauntAutoSoundEnabled       = true,
    tauntAutoSoundName          = "Hunter: Toggle Pet Taunt",
    petInCCEnabled         = true,
    petInCCSoundEnabled    = true,
    petInCCSoundName       = "Hunter: Pet in CC",
    healPetEnabled              = true,
    petPassiveEnabled           = true,
    petPassiveSoundEnabled      = true,
    petPassiveSoundName         = "Hunter: Pet on Passive",
    petNotAttackingEnabled      = true,
    petNotAttackingSoundEnabled = true,
    petNotAttackingSoundName    = "Hunter: Pet Not Attacking",
}

-- ============================================================
-- Talent Helpers
-- ============================================================
local function MMHasPetTalent()
    return NPA.IsSpellKnownByPlayer(SPELL_UNBREAKABLE_BOND)
end

-- ============================================================
-- Fake Death Detection
-- ============================================================
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

-- ============================================================
-- Growl Detection
-- ============================================================
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

-- ============================================================
-- Module Table
-- ============================================================
local HunterMarksmanship = {
    class             = "HUNTER",
    specID            = SPEC_ID,
    specName          = "Marksmanship Hunter",
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
    },

    extraUnitEvents = {
        { "UNIT_HEALTH", "pet" },
    },
}

-- ============================================================
-- ShouldRun
-- ============================================================
function HunterMarksmanship:ShouldRun(db)
    if not db.enabled then return false end
    if NPA.GetSpecID() ~= SPEC_ID then return false end
    return MMHasPetTalent()
end

-- ============================================================
-- ClearAllState
-- ============================================================
function HunterMarksmanship:ClearAllState()
    state.petFakeDeathActive = false
    state.wakeOverrideUntil  = 0
    state.petResurrecting    = false
    NPA.notAttackingState.petNotAttackingStartTime = nil
    NPA.notAttackingState.petLastHadTargetTime     = nil
end

-- ============================================================
-- GetHighestPriorityAlert
-- ============================================================
function HunterMarksmanship:GetHighestPriorityAlert(db)
    if not NPA.PetExists() then
        if state.petResurrecting then return 1 end
        if db.noPetEnabled and not NPA.ShouldSuppressNoPet() and MMHasPetTalent() then
            return 3
        end
        return nil
    end

    if not UnitIsDead("pet") then state.petResurrecting = false end

    if db.petDeadEnabled     and UnitIsDead("pet") then
        state.petResurrecting = true
        return 1
    end
    if db.fakeDeathEnabled       and PetHasPlayDead() then return 2 end
    if db.tauntAutoEnabled       and NPA.IsTauntGroupConditionMet()
                                 and IsGrowlAutocastEnabled() then return 4 end
    if db.petInCCEnabled    and NPA.PetIsCC() then return 5 end
    if db.petPassiveEnabled      and NPA.PetIsPassive() then return 7 end
    if db.petNotAttackingEnabled and NPA.PetNotAttacking() then return 8 end
    if db.healPetEnabled         and NPA.PetNeedsHealing() then return 6 end

    return nil
end

-- ============================================================
-- OnEvent
-- ============================================================
function HunterMarksmanship:OnEvent(db, event, ...)
    if event == "UNIT_PET" then
        local unit = ...
        if unit == "player" then
            state.petFakeDeathActive = false
            state.wakeOverrideUntil  = 0
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
        if unit == "pet" and state.wakeOverrideUntil <= GetTime() then
            state.petFakeDeathActive = DetectPetFakeDeathDirect()
        end
        if unit == "pet" or unit == "player" then
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

-- ============================================================
-- Debug
-- ============================================================
function HunterMarksmanship:Debug(db)
    local ok, err = pcall(function()
        NPA.Msg("spec=Marksmanship"
            .. "  hasPetTalent=" .. tostring(MMHasPetTalent())
            .. "  fakeDeath=" .. tostring(state.petFakeDeathActive)
            .. "  petRes=" .. tostring(state.petResurrecting)
            .. "  specID=" .. tostring(NPA.GetSpecID()))
    end)
    if not ok then NPA.Msg("ERROR(hunter_mm): " .. tostring(err)) end
end

-- ============================================================
-- Alert Options
-- ============================================================
function HunterMarksmanship:BuildAlertOptions(box, db, helpers)
    helpers:MakeNumericInput("Heal Pet Threshold (%)", 1, 99,
        function() return db.healPetThreshold or 50 end,
        function(v) db.healPetThreshold = v; NPA.ResetHealthCurve() end)
end

-- ============================================================
-- Register
-- ============================================================
NPA:RegisterSpec("HunterMarksmanship", HunterMarksmanship)
