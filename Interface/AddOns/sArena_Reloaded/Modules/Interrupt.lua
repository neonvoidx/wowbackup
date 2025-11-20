local interruptSpells = {
    1766,   -- Kick (Rogue)
    2139,   -- Counterspell (Mage)
    6552,   -- Pummel (Warrior)
    19647,  -- Spell Lock (Warlock)
    47528,  -- Mind Freeze (Death Knight)
    57994,  -- Wind Shear (Shaman)
    96231,  -- Rebuke (Paladin)
    106839, -- Skull Bash (Feral)
    115781, -- Optical Blast (Warlock)
    116705, -- Spear Hand Strike (Monk)
    132409, -- Spell Lock (Warlock)
    119910, -- Spell Lock (Warlock Pet)
    89766,  -- Axe Toss (Warlock Pet)
    171138, -- Shadow Lock (Warlock)
    147362, -- Countershot (Hunter)
    183752, -- Disrupt (Demon Hunter)
    187707, -- Muzzle (Hunter)
    212619, -- Call Felhunter (Warlock)
    351338, -- Quell (Evoker)
    34490,  -- Silencing Shot (Hunter)
}

-- Function to find and return the interrupt spell the player knows
local function GetInterruptSpell()
    for _, spellID in ipairs(interruptSpells) do
        if IsSpellKnownOrOverridesKnown(spellID) or (UnitExists("pet") and IsSpellKnownOrOverridesKnown(spellID, true)) then
            return spellID
        end
    end
    return nil
end

local playerKick = GetInterruptSpell()

-- Recheck interrupt spells when lock resummons/sacrifices pet
local petSummonSpells = {
    [30146]  = true, -- Summon Demonic Tyrant (Demonology)
    [691]    = true, -- Summon Felhunter (for Spell Lock)
    [108503] = true, -- Grimoire of Sacrifice
}

sArenaMixin.interruptIcon = CreateFrame("Frame")
sArenaMixin.interruptIcon.cooldown = CreateFrame("Cooldown", nil, sArenaMixin.interruptIcon, "CooldownFrameTemplate")
sArenaMixin.interruptIcon.cooldown:HookScript("OnCooldownDone", function()
    sArenaMixin.interruptReady = true
    sArenaMixin:UpdateCastbarInterruptStatus()
end)

function sArenaMixin:UpdateCastbarInterruptStatus()
    for i = 1, sArenaMixin.maxArenaOpponents do
        local frame = _G["sArenaEnemyFrame" .. i]
        local castBar = frame.CastBar
        if castBar:IsShown() then
            sArenaMixin:CastbarOnEvent(castBar)
        end
    end
end

-- Function to update the interrupt icon
local function UpdateInterruptIcon(frame)
    if not playerKick then
        playerKick = GetInterruptSpell()
    end
    if playerKick then
        -- Update cooldown
        local cooldownInfo = C_Spell.GetSpellCooldown(playerKick)
        if cooldownInfo then
            frame.cooldown:SetCooldown(cooldownInfo.startTime, cooldownInfo.duration)
            local isOnCooldown = frame.cooldown:IsShown()
            sArenaMixin.interruptReady = not isOnCooldown
            sArenaMixin:UpdateCastbarInterruptStatus()
        end
    end
end

local function OnPetEvent(self, event, unit, _, spellID)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if not petSummonSpells[spellID] then return end
    end
    C_Timer.After(0.1, function()
        playerKick = GetInterruptSpell()
        UpdateInterruptIcon(sArenaMixin.interruptIcon)
    end)
end


local cooldownFrame = CreateFrame("Frame")
cooldownFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
cooldownFrame:SetScript("OnEvent", function(self, event, spellID)
    if spellID ~= playerKick then return end
    UpdateInterruptIcon(sArenaMixin.interruptIcon)
end)

local interruptSpellUpdate = CreateFrame("Frame")
if sArenaMixin.playerClass == "WARLOCK" then
    interruptSpellUpdate:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
end
interruptSpellUpdate:RegisterEvent("TRAIT_CONFIG_UPDATED")
interruptSpellUpdate:RegisterEvent("PLAYER_TALENT_UPDATE")
interruptSpellUpdate:SetScript("OnEvent", OnPetEvent)