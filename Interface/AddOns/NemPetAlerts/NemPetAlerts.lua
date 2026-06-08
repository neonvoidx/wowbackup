-- ============================================================
-- NemPetAlerts.lua  v12.0.26
-- Nem: Pet Alerts — core engine.
--
-- MIT License
-- Copyright (c) 2026 Nemreaper
--
-- Permission is hereby granted, free of charge, to any person
-- obtaining a copy of this software and associated documentation
-- files (the "Software"), to deal in the Software without
-- restriction, including without limitation the rights to use,
-- copy, modify, merge, publish, distribute, sublicense, and/or
-- sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following
-- conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
-- OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
-- HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
-- OTHER DEALINGS IN THE SOFTWARE.
-- ============================================================

local ADDON_NAME = ...
local NPA = CreateFrame("Frame")
_G.NemPetAlerts = NPA

-- ============================================================
-- Upvalues
-- ============================================================
local pairs, ipairs           = pairs, ipairs
local math_floor, math_max    = math.floor, math.max
local math_min, math_sin      = math.min, math.sin
local math_pi                 = math.pi
local string_format           = string.format
local CreateFrame             = CreateFrame
local GetTime                 = GetTime
local UnitClass               = UnitClass
local UnitExists              = UnitExists
local UnitIsDead              = UnitIsDead
local IsInGroup, IsInRaid     = IsInGroup, IsInRaid
local GetNumGroupMembers      = GetNumGroupMembers
local C_UnitAuras             = C_UnitAuras
local CopyTable               = CopyTable
local issecretvalue           = issecretvalue or function() return false end

local NPA_VERSION = "v12.0.26"

-- ============================================================
-- Cascade Isolation
-- ============================================================
-- All entry points that can be reached during alert evaluation
-- are wrapped via SafeCall. Errors accumulate in NPA._errors
-- instead of breaking sibling alerts or the addon.
NPA._errors = {}

local function SafeCall(label, func, ...)
    local ok, err = pcall(func, ...)
    if not ok then
        NPA._errors[label] = { msg = tostring(err), time = GetTime() }
    end
    return ok
end
NPA.SafeCall = SafeCall

-- ============================================================
-- Asset Paths
-- ============================================================
local NPA_FONTS  = "Interface\\AddOns\\NemPetAlerts\\Fonts\\"
local NPA_MEDIA  = "Interface\\AddOns\\NemPetAlerts\\Media\\"

local ALERT_FONT = NPA_FONTS .. "GothamNarrow-Ultra.ttf"
local UI_FONT    = NPA_FONTS .. "Prototype.ttf"

-- ============================================================
-- Class Detection
-- ============================================================
local activeClass = nil

local function GetActiveClass()
    local _, class = UnitClass("player")
    return class
end

-- ============================================================
-- Spec Module Registry
-- ============================================================
NPA.specModules     = {}
NPA.activeModule    = nil
NPA.activeModuleKey = nil

function NPA:RegisterSpec(key, mod)
    self.specModules[key] = mod
end

local function FindActiveModule()
    if not activeClass then return nil, nil end
    local currentSpecID = NPA.GetSpecID()
    if not currentSpecID then return nil, nil end
    for key, mod in pairs(NPA.specModules) do
        if mod.class == activeClass then
            local ok, match = pcall(function()
                return mod.specID == currentSpecID
            end)
            if ok and match then
                return key, mod
            end
        end
    end
    return nil, nil
end

local function IsFullyImplemented()
    return NPA.activeModule ~= nil
end

-- ============================================================
-- Class Theme Colors
-- ============================================================
-- Class theme colors are sourced live from Blizzard's master class-color table
-- (C_ClassColor.GetClassColor → RAID_CLASS_COLORS) rather than hardcoded, so they
-- self-correct if Blizzard ever retunes a class color. Verified ✅ in NemWiki's API
-- ledger (2026-05-27). CLASS_THEME_DEFAULT is the fallback when class is unknown.
local CLASS_THEME_DEFAULT = { r=0, g=0.8, b=1.0 }    -- #00CCFF

local function GetClassTheme()
    local cls = activeClass
    if not cls and UnitClass then
        local _, c = UnitClass("player")
        cls = c
    end
    if cls and C_ClassColor and C_ClassColor.GetClassColor then
        local col = C_ClassColor.GetClassColor(cls)
        if col then return col.r, col.g, col.b end
    end
    return CLASS_THEME_DEFAULT.r, CLASS_THEME_DEFAULT.g, CLASS_THEME_DEFAULT.b
end

-- ============================================================
-- LibSharedMedia
-- ============================================================
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- ============================================================
-- Sounds
-- ============================================================
local VOICE_CLIPS = {
    ["Death Knight: Raise Ghoul"]   = NPA_MEDIA .. "deathknight_raise_ghoul.ogg",
    ["Death Knight: Ghoul in CC"]   = NPA_MEDIA .. "deathknight_ghoul_in_cc.ogg",
    ["Death Knight: Ghoul on Passive"]= NPA_MEDIA .. "deathknight_ghoul_on_passive.ogg",
    ["Death Knight: Ghoul Not Attacking"]= NPA_MEDIA .. "deathknight_ghoul_not_attacking.ogg",
    ["Hunter: Pet Died"]            = NPA_MEDIA .. "hunter_pet_died.ogg",
    ["Hunter: Call Pet"]            = NPA_MEDIA .. "hunter_call_pet.ogg",
    ["Hunter: Heal Pet"]            = NPA_MEDIA .. "hunter_heal_pet.ogg",
    ["Hunter: Pet in CC"]           = NPA_MEDIA .. "hunter_pet_in_cc.ogg",
    ["Hunter: Pet Not Attacking"]   = NPA_MEDIA .. "hunter_pet_not_attacking.ogg",
    ["Hunter: Pet on Passive"]      = NPA_MEDIA .. "hunter_pet_on_passive.ogg",
    ["Hunter: Toggle Pet Taunt"]    = NPA_MEDIA .. "hunter_toggle_pet_taunt.ogg",
    ["Hunter: Wake Up Pet"]         = NPA_MEDIA .. "hunter_wake_up_pet.ogg",
    ["Mage: Summon Water Ele"]      = NPA_MEDIA .. "mage_summon_water_ele.ogg",
    ["Mage: Summon Wele"]           = NPA_MEDIA .. "mage_summon_wele.ogg",
    ["Mage: Water Ele Died"]        = NPA_MEDIA .. "mage_water_ele_died.ogg",
    ["Mage: Wele Died"]             = NPA_MEDIA .. "mage_wele_died.ogg",
    ["Mage: Water Ele Health Low"]  = NPA_MEDIA .. "mage_water_ele_health_low.ogg",
    ["Mage: Wele Health Low"]       = NPA_MEDIA .. "mage_wele_health_low.ogg",
    ["Mage: Water Ele in CC"]       = NPA_MEDIA .. "mage_water_ele_in_cc.ogg",
    ["Mage: Wele in CC"]            = NPA_MEDIA .. "mage_wele_in_cc.ogg",
    ["Mage: Water Ele Not Attacking"]=NPA_MEDIA .. "mage_water_ele_not_attacking.ogg",
    ["Mage: Wele Not Attacking"]    = NPA_MEDIA .. "mage_wele_not_attacking.ogg",
    ["Mage: Water Ele on Passive"]  = NPA_MEDIA .. "mage_water_ele_on_passive.ogg",
    ["Mage: Wele on Passive"]       = NPA_MEDIA .. "mage_wele_on_passive.ogg",
    ["Warlock: Demon Died"]         = NPA_MEDIA .. "warlock_demon_died.ogg",
    ["Warlock: Summon Demon"]       = NPA_MEDIA .. "warlock_summon_demon.ogg",
    ["Warlock: Sacrifice Demon"]    = NPA_MEDIA .. "warlock_sacrifice_demon.ogg",
    ["Warlock: Heal Demon"]         = NPA_MEDIA .. "warlock_heal_demon.ogg",
    ["Warlock: Demon in CC"]        = NPA_MEDIA .. "warlock_demon_in_cc.ogg",
    ["Warlock: Demon Not Attacking"]= NPA_MEDIA .. "warlock_demon_not_attacking.ogg",
    ["Warlock: Demon on Passive"]   = NPA_MEDIA .. "warlock_demon_on_passive.ogg",
    ["Warlock: Toggle Demon Taunt"] = NPA_MEDIA .. "warlock_toggle_demon_taunt.ogg",
}

-- Maps the active module's class token to the prefix used in VOICE_CLIPS keys.
-- Drives the per-spec filter that hides other classes' TTS clips in sound dropdowns.
local CLASS_VOICE_PREFIX = {
    DEATHKNIGHT = "Death Knight",
    HUNTER      = "Hunter",
    MAGE        = "Mage",
    WARLOCK     = "Warlock",
}

local function GetActiveClassVoicePrefix()
    local mod = NPA.activeModule
    if not mod then return nil end
    return CLASS_VOICE_PREFIX[mod.class]
end

local BUNDLED_SOUNDS = {
    ["Bell"]             = NPA_MEDIA .. "Bell.ogg",
    ["Bleeper"]          = NPA_MEDIA .. "Bleeper.ogg",
    ["Drums"]            = NPA_MEDIA .. "Drums.ogg",
    ["HeartbeatSingle"]  = NPA_MEDIA .. "HeartbeatSingle.ogg",
    ["Lamp"]             = NPA_MEDIA .. "Lamp.ogg",
    ["MetalGearSpotted"] = NPA_MEDIA .. "MetalGearSpotted.ogg",
    ["OhNo"]             = NPA_MEDIA .. "OhNo.ogg",
    ["Ping"]             = NPA_MEDIA .. "Ping.ogg",
    ["Redfox"]           = NPA_MEDIA .. "Redfox.ogg",
    ["RobotBlip"]        = NPA_MEDIA .. "RobotBlip.ogg",
    ["SharpPunch"]       = NPA_MEDIA .. "SharpPunch.ogg",
    ["Shotgun"]          = NPA_MEDIA .. "Shotgun.ogg",
    ["Sonar"]            = NPA_MEDIA .. "Sonar.ogg",
    ["Sonarr"]           = NPA_MEDIA .. "Sonarr.ogg",
    ["WaterDrop"]        = NPA_MEDIA .. "WaterDrop.ogg",
}

if LSM then
    for name, path in pairs(BUNDLED_SOUNDS) do
        LSM:Register("sound", name, path)
    end
end

if LSM then
    for name, path in pairs(VOICE_CLIPS) do
        LSM:Register("sound", name, path)
    end
end

local function GetSoundPath(name)
    if not name then return BUNDLED_SOUNDS["RobotBlip"] end
    if BUNDLED_SOUNDS[name] then return BUNDLED_SOUNDS[name] end
    if VOICE_CLIPS[name]    then return VOICE_CLIPS[name]    end
    if LSM then
        local p = LSM:Fetch("sound", name)
        if type(p) == "string" then return p:gsub("/", "\\") end
    end
    return BUNDLED_SOUNDS["RobotBlip"]
end

local function IsTTSSound(name)
    return name and name:find("^%w+:") ~= nil
end

-- Resolves the effective sound name for an alert under the account-global
-- model. Generic sounds (Bell, Sonar...) match every class and pass through.
-- A TTS clip whose class prefix ("Hunter:", "Warlock:"...) doesn't match the
-- active class falls back to that alert's per-spec default sound, so a shared
-- global choice still plays correctly-flavored audio on each pet class.
local function ClassAwareSoundName(alertKey)
    local db = NPA.db
    local stored = db and db[alertKey .. "SoundName"]
    if stored and not IsTTSSound(stored) then return stored end
    local prefix = GetActiveClassVoicePrefix()
    if stored and prefix and stored:find("^" .. prefix .. ":") then
        return stored
    end
    local mod = NPA.activeModule
    if mod and mod.alerts then
        for _, a in ipairs(mod.alerts) do
            if a.key == alertKey then return a.defaultSound end
        end
    end
    return stored
end

local SOUND_NAMES = {}
do
    for k in pairs(BUNDLED_SOUNDS) do SOUND_NAMES[#SOUND_NAMES+1] = k end
    for k in pairs(VOICE_CLIPS)    do SOUND_NAMES[#SOUND_NAMES+1] = k end
    table.sort(SOUND_NAMES, function(a, b)
        local aTTS, bTTS = IsTTSSound(a), IsTTSSound(b)
        if aTTS ~= bTTS then return aTTS end
        return a < b
    end)
end

-- ============================================================
-- Fonts
-- ============================================================
local BUNDLED_FONTS = {
    ["Accidental Presidency"]   = NPA_FONTS .. "Accidental Presidency.ttf",
    ["Action Man"]              = NPA_FONTS .. "ActionMan.ttf",
    ["Alba Super"]              = NPA_FONTS .. "ALBAS___.ttf",
    ["Arm Wrestler"]            = NPA_FONTS .. "ArmWrestler.ttf",
    ["Avant Garde LT Book"]     = NPA_FONTS .. "AvantGarde_LT_Book_Regular.ttf",
    ["Baars"]                   = NPA_FONTS .. "BAARS___.TTF",
    ["Blazed"]                  = NPA_FONTS .. "Blazed.ttf",
    ["Boris Black Bloxx"]       = NPA_FONTS .. "BorisBlackBloxx.ttf",
    ["Boris Black Bloxx Dirty"] = NPA_FONTS .. "BorisBlackBloxxDirty.ttf",
    ["Cabin"]                   = NPA_FONTS .. "Cabin-Regular.ttf",
    ["Celestia Medium Redux"]   = NPA_FONTS .. "CelestiaMediumRedux1.55.ttf",
    ["Century Gothic"]          = NPA_FONTS .. "centurygothic.ttf",
    ["Collegia"]                = NPA_FONTS .. "COLLEGIA.ttf",
    ["Continuum Medium"]        = NPA_FONTS .. "ContinuumMedium.ttf",
    ["DejaVu Sans"]             = NPA_FONTS .. "DejaVuSans.ttf",
    ["DejaVu Sans Bold"]        = NPA_FONTS .. "DejaVuSans-Bold.ttf",
    ["Die Die Die"]             = NPA_FONTS .. "DieDieDie.ttf",
    ["Diogenes"]                = NPA_FONTS .. "DIOGENES.ttf",
    ["Disko"]                   = NPA_FONTS .. "Disko.ttf",
    ["Expressway Bold"]         = NPA_FONTS .. "Expressway-Bold.ttf",
    ["Fraks"]                   = NPA_FONTS .. "FRAKS___.ttf",
    ["Fritz Quadrata"]          = NPA_FONTS .. "FRIZQUAD.TTF",
    ["Gotham Narrow Ultra"]     = NPA_FONTS .. "GothamNarrow-Ultra.ttf",
    ["Homespun"]                = NPA_FONTS .. "Homespun.ttf",
    ["Impact"]                  = NPA_FONTS .. "impact.ttf",
    ["JetBrains Mono"]          = NPA_FONTS .. "JetBrainsMono-Regular.ttf",
    ["Liberation Sans"]         = NPA_FONTS .. "LiberationSans-Regular.ttf",
    ["Liberation Serif"]        = NPA_FONTS .. "LiberationSerif-Regular.ttf",
    ["Mystik Orbs"]             = NPA_FONTS .. "MystikOrbs.ttf",
    ["Nanum Gothic"]            = NPA_FONTS .. "NanumGothic-Regular.ttf",
    ["Nunito"]                  = NPA_FONTS .. "Nunito-Regular.ttf",
    ["Pokemon Solid"]           = NPA_FONTS .. "Pokemon Solid.ttf",
    ["Prototype"]               = NPA_FONTS .. "Prototype.ttf",
    ["PT Sans Narrow Bold"]     = NPA_FONTS .. "PTSansNarrow-Bold.ttf",
    ["Roboto Condensed Bold"]   = NPA_FONTS .. "RobotoCondensed-Bold.ttf",
    ["Rock Show Whiplash"]      = NPA_FONTS .. "Rock Show Whiplash.ttf",
    ["SF Diego Sans"]           = NPA_FONTS .. "SF Diego Sans.ttf",
    ["Solange"]                 = NPA_FONTS .. "Solange.ttf",
    ["Starcine"]                = NPA_FONTS .. "starcine.ttf",
    ["Trashco"]                 = NPA_FONTS .. "trashco.ttf",
    ["Ubuntu Condensed"]        = NPA_FONTS .. "Ubuntu-C.ttf",
    ["Ubuntu Light"]            = NPA_FONTS .. "Ubuntu-L.ttf",
    ["Verdana"]                 = NPA_FONTS .. "Verdana.ttf",
    ["Waltograph UI"]           = NPA_FONTS .. "waltographUI.ttf",
    ["X360"]                    = NPA_FONTS .. "X360.ttf",
    ["Yanone Kaffeesatz"]       = NPA_FONTS .. "YanoneKaffeesatz-Regular.ttf",
}

if LSM then
    for name, path in pairs(BUNDLED_FONTS) do
        LSM:Register("font", name, path)
    end
end

local EXCLUDED_LSM_FONTS = {
    ["Friz Quadrata TT"] = true,
}

local function GetCurrentFontPath()
    local db = NPA.db
    local name = db and db.fontName or "Gotham Narrow Ultra"
    if BUNDLED_FONTS[name] then return BUNDLED_FONTS[name] end
    if LSM then
        local p = LSM:Fetch("font", name)
        if type(p) == "string" then return p:gsub("/", "\\") end
    end
    return ALERT_FONT
end

local FONT_NAMES = {}
do
    for k in pairs(BUNDLED_FONTS) do FONT_NAMES[#FONT_NAMES+1] = k end
    table.sort(FONT_NAMES)
end

-- ============================================================
-- Saved-Variable Defaults
-- ============================================================
local CORE_DEFAULTS = {
    enabled          = true,
    flash            = true,
    fontSize         = 25,
    fontName         = "Gotham Narrow Ultra",
    x                = 0,
    y                = 140,
    point            = "CENTER",
    relativePoint    = "CENTER",
    relativeTo       = "UIParent",
    healPetThreshold = 50,
    ver              = 7,
}

local coreState = {
    unlocked         = false,
    testMode         = false,
    testTicker       = nil,
    currentMessage   = nil,
    lastDisplayedIdx = nil,
    lastCueTime      = 0,
    suppressCueUntil = 0,
}

local CUE_GRACE             = 0.5
local ACTIVATION_SUPPRESS   = 1.0

-- ============================================================
-- Saved-Variable Key Routing
-- ============================================================
-- v7+ storage is a single flat table (NPA.db == NemPetAlertsSV). Every
-- key — display globals and per-alert toggles/sounds/colors/text — lives
-- at the top level, so all settings are account-global. GLOBAL_KEYS is
-- retained ONLY for the legacy v3→v4 migration split below.
local GLOBAL_KEYS = {
    enabled = true, flash = true, fontSize = true, fontName = true,
    x = true, y = true, point = true, relativePoint = true,
    relativeTo = true, ver = true,
}

-- ============================================================
-- Utility
-- ============================================================
local function MergeDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            MergeDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

local function Msg(text)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff66ccffNem: Pet Alerts:|r " .. tostring(text))
    end
end

local function ResolveRelativeFrame(db)
    if db.relativeTo and db.relativeTo ~= "UIParent" then
        return _G[db.relativeTo] or UIParent
    end
    return UIParent
end

NPA.Msg           = Msg
NPA.issecretvalue = issecretvalue

-- ============================================================
-- Sound Playback
-- ============================================================
-- Voice cues (sound name with "^%w+:" prefix) are routed through
-- a single-slot player with priority preemption, post-cue gap,
-- combat-start grace window, and per-alert cooldown. Generic
-- sounds (Bell, Sonar, etc.) bypass the queue entirely.

local VOICE_PRIO_LOW      = 1
local VOICE_PRIO_NORMAL   = 2
local VOICE_PRIO_HIGH     = 3
local VOICE_PRIO_CRITICAL = 4
NPA.VOICE_PRIO_LOW      = VOICE_PRIO_LOW
NPA.VOICE_PRIO_NORMAL   = VOICE_PRIO_NORMAL
NPA.VOICE_PRIO_HIGH     = VOICE_PRIO_HIGH
NPA.VOICE_PRIO_CRITICAL = VOICE_PRIO_CRITICAL

local VOICE_GAP_SECONDS         = 0.7
local VOICE_COMBAT_START_WINDOW = 1.5
local VOICE_COOLDOWN_SECONDS    = 4.0
local VOICE_CUE_DURATION_GUESS  = 1.5

local voice = {
    handle          = nil,
    priority        = 0,
    expectedEnd     = 0,
    lastEnd         = 0,
    combatStart     = 0,
    combatStartUsed = false,
    perAlertLast    = {},
}

local function _voiceStopCurrent()
    if voice.handle and StopSound then
        pcall(StopSound, voice.handle)
    end
    voice.handle      = nil
    voice.priority    = 0
    voice.lastEnd     = GetTime()
    voice.expectedEnd = GetTime()
end

local function _voiceTick()
    if voice.handle and GetTime() >= voice.expectedEnd then
        voice.lastEnd  = voice.expectedEnd
        voice.handle   = nil
        voice.priority = 0
    end
end

local function _voiceInCombatGrace()
    local now = GetTime()
    return (not voice.combatStartUsed)
        and (now < voice.combatStart + VOICE_COMBAT_START_WINDOW)
end

local function _voiceTryPlay(path, alertKey, priority)
    local now = GetTime()
    _voiceTick()

    -- Rule 1: per-alert cooldown.
    local last = voice.perAlertLast[alertKey]
    if last and now < last + VOICE_COOLDOWN_SECONDS then
        return
    end

    -- Rules 2/3/4 (NHA-shaped): preempt path skips the gap entirely;
    -- non-preempt path enforces the gap, with CRITICAL exempt and the
    -- combat-start grace exempt.
    if voice.handle then
        if priority <= voice.priority then
            return -- drop, current clip outranks new one
        end
        _voiceStopCurrent()
    else
        if now < voice.lastEnd + VOICE_GAP_SECONDS
           and priority < VOICE_PRIO_CRITICAL
           and not _voiceInCombatGrace() then
            return
        end
    end

    -- Rule 5: play and record state.
    local willPlay, handle = PlaySoundFile(path, "Master")
    if willPlay and handle then
        voice.handle      = handle
        voice.priority    = priority
        voice.expectedEnd = now + VOICE_CUE_DURATION_GUESS
        voice.perAlertLast[alertKey] = now
        if _voiceInCombatGrace() then
            voice.combatStartUsed = true
        end
    end
end

function NPA:PlayAlertSound(alertKey)
    local db = self.db
    if not db then return end
    if coreState and coreState.testMode then return end

    local enabledKey = alertKey .. "SoundEnabled"
    local nameKey    = alertKey .. "SoundName"
    if not db[enabledKey] then return end

    local soundName = ClassAwareSoundName(alertKey)
    local path      = GetSoundPath(soundName)

    local priority = VOICE_PRIO_NORMAL
    local mod = NPA.activeModule
    if mod and mod.alerts then
        for _, alert in ipairs(mod.alerts) do
            if alert.key == alertKey then
                priority = alert.priority or VOICE_PRIO_NORMAL
                break
            end
        end
    end

    if IsTTSSound(soundName) then
        _voiceTryPlay(path, alertKey, priority)
    else
        PlaySoundFile(path, "Master")
    end
end

-- ============================================================
-- Shared Pet Utilities
-- ============================================================
function NPA.PetExists()
    return UnitExists("pet")
end

function NPA.PetAlive()
    if not UnitExists("pet") then return false end
    return not UnitIsDead("pet")
end

function NPA.ShouldSuppressNoPet()
    local mounted = IsMounted and IsMounted()
    if issecretvalue and issecretvalue(mounted) then return true end
    if mounted then return true end
    if UnitOnTaxi("player") then return true end
    if UnitInVehicle("player") then return true end
    if IsFlying and IsFlying() then return true end
    if C_PlayerInfo and C_PlayerInfo.GetGlidingInfo then
        local isGliding, canGlide = C_PlayerInfo.GetGlidingInfo()
        if isGliding or canGlide then return true end
    end
    if UnitIsDeadOrGhost("player") then return true end
    return false
end

function NPA.PetIsCC()
    if not NPA.PetAlive() then return false end
    if not (C_UnitAuras and C_UnitAuras.GetUnitAuras) then return false end
    local auras = C_UnitAuras.GetUnitAuras("pet", "HARMFUL|CROWD_CONTROL")
    if not auras then return false end
    for _, aura in ipairs(auras) do
        if aura.spellId then return true end
    end
    return false
end

function NPA.PetIsPassive()
    if not HasPetUI() or not NPA.PetAlive() then return false end
    if not InCombatLockdown() then return false end
    for i = 1, 10 do
        local name, _, isToken, isActive = GetPetActionInfo(i)
        if isToken and name == "PET_MODE_PASSIVE" and isActive then
            return true
        end
    end
    return false
end

-- ============================================================
-- Pet Not Attacking Detection
-- ============================================================
local PET_NOT_ATTACKING_GRACE = 3

local petCombatDetector = nil
local function GetPetCombatDetector()
    if not petCombatDetector then
        local bar = CreateFrame("StatusBar", "NPA_PetCombatDetector", UIParent)
        bar:SetSize(2, 2)
        bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -200, 200)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetStatusBarColor(1, 1, 1, 1)
        bar:SetAlpha(0)
        bar:EnableMouse(false)
        bar:Show()
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(0)
        petCombatDetector = bar
    end
    return petCombatDetector
end

local function ResolvePetCombatState(secretBool)
    local det = GetPetCombatDetector()
    if secretBool == nil then
        det:SetValue(0)
    elseif issecretvalue and issecretvalue(secretBool) then
        det:SetValue(secretBool)
    else
        det:SetValue(secretBool and 1 or 0)
    end
    return det:GetStatusBarTexture():IsShown()
end

NPA.notAttackingState = {
    petNotAttackingStartTime = nil,
    petLastHadTargetTime     = nil,
}

function NPA.PetNotAttacking()
    if not InCombatLockdown() then return false end
    if not NPA.PetExists() or UnitIsDead("pet") then return false end

    local nas = NPA.notAttackingState
    local petHasTarget = UnitExists("pettarget")
    if petHasTarget then
        nas.petLastHadTargetTime     = GetTime()
        nas.petNotAttackingStartTime = nil
        return false
    end

    local petInCombat = ResolvePetCombatState(UnitAffectingCombat("pet"))
    if petInCombat and nas.petLastHadTargetTime then
        local sinceTarget = GetTime() - nas.petLastHadTargetTime
        if sinceTarget <= 2 then
            nas.petNotAttackingStartTime = nil
            return false
        end
    end

    if not nas.petNotAttackingStartTime then
        nas.petNotAttackingStartTime = GetTime()
    end
    local elapsed = GetTime() - nas.petNotAttackingStartTime
    return elapsed >= PET_NOT_ATTACKING_GRACE
end

-- ============================================================
-- Taunt Group Condition
-- ============================================================
function NPA.IsTauntGroupConditionMet()
    if not IsInGroup() or GetNumGroupMembers() < 5 then return false end
    local _, instanceType = IsInInstance()
    if instanceType == "arena" or instanceType == "pvp" then return false end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            if UnitExists("raid"..i) and UnitGroupRolesAssigned("raid"..i) == "TANK" then
                return true
            end
        end
    else
        for i = 1, 4 do
            if UnitExists("party"..i) and UnitGroupRolesAssigned("party"..i) == "TANK" then
                return true
            end
        end
    end
    return instanceType == "party" or instanceType == "raid"
end

-- ============================================================
-- Pet Health Warning
-- ============================================================
local HEAL_PET_THRESHOLD = 50
local petHealthCurve
local petHealthCurveThreshold = nil

function NPA.GetPetHealthWarningAlpha()
    if not NPA.PetExists() or UnitIsDead("pet") then return nil end
    if not UnitHealthPercent or not C_CurveUtil or not C_CurveUtil.CreateColorCurve then return nil end
    local threshold = (NPA.db and NPA.db.healPetThreshold) or HEAL_PET_THRESHOLD
    if not petHealthCurve or petHealthCurveThreshold ~= threshold then
        petHealthCurve = C_CurveUtil.CreateColorCurve()
        petHealthCurve:SetType(Enum.LuaCurveType.Step)
        petHealthCurve:AddPoint(0, CreateColor(1, 1, 1, 1))
        petHealthCurve:AddPoint(threshold / 100, CreateColor(1, 1, 1, 0))
        petHealthCurveThreshold = threshold
    end
    local ok, color = pcall(UnitHealthPercent, "pet", false, petHealthCurve)
    if not ok or not color or type(color.GetRGBA) ~= "function" then return nil end
    local _, _, _, a = color:GetRGBA()
    return a
end

function NPA.ResetHealthCurve()
    petHealthCurveThreshold = nil
end

-- ============================================================
-- Spec Helpers
-- ============================================================
function NPA.GetSpecID()
    local idx = GetSpecialization()
    if not idx then return nil end

    local ok, specID = pcall(GetSpecializationInfo, idx)
    if ok and specID and not issecretvalue(specID) then
        return specID
    end

    for i = 1, 4 do
        local sOk, sID = pcall(GetSpecializationInfo, i)
        if sOk and sID and not issecretvalue(sID) then
            for _, mod in pairs(NPA.specModules) do
                if mod.class == activeClass and mod.specID == sID then
                    local checkOk, checkResult = pcall(function()
                        return GetSpecialization() == i
                    end)
                    if checkOk and checkResult then
                        return sID
                    end
                end
            end
        end
    end

    return nil
end

function NPA.IsSpellKnownByPlayer(spellID)
    if not spellID then return false end
    if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
    if IsSpellKnownOrOverridesKnown then
        return IsSpellKnownOrOverridesKnown(spellID)
    end
    return false
end

local Evaluate

local evaluatePending = false
local function ScheduleEvaluate(delay)
    if evaluatePending then return end
    evaluatePending = true
    C_Timer.After(delay or 0, function()
        evaluatePending = false
        Evaluate()
    end)
end

-- ============================================================
-- Display Frame
-- ============================================================
local function StopHealPetTicker()
    local f = NPA.display
    if not f then return end
    if f.healPetAlphaTicker then
        f.healPetAlphaTicker:Cancel()
        f.healPetAlphaTicker = nil
    end
    if f.healPetFrame then
        f.healPetFrame:SetAlpha(0)
    end
end

local function StartHealPetTicker()
    local f = NPA.display
    if not f or f.healPetAlphaTicker then return end
    f.healPetAlphaTicker = C_Timer.NewTicker(0.5, function()
        SafeCall("HealPetAlphaTicker", function()
            local db  = NPA.db
            local mod = NPA.activeModule
            if not db or not db.enabled then
                f.healPetFrame:SetAlpha(0)
                return
            end
            if coreState and coreState.testMode then
                return -- test mode handles its own heal-pet visibility
            end
            if not mod or not mod.hasHealPet or not db.healPetEnabled then
                f.healPetFrame:SetAlpha(0)
                return
            end
            local a = NPA.GetPetHealthWarningAlpha()
            if a == nil then
                f.healPetFrame:SetAlpha(0)
                return
            end
            f.healPetFrame:SetAlpha(a)
            f.healPetFrame:Show()
        end)
    end)
end

local function CreateDisplay()
    local db = NPA.db

    local f = CreateFrame("Frame", "NemPetAlertsFrame", UIParent,
        BackdropTemplateMixin and "BackdropTemplate" or nil)
    f:SetSize(900, 160)
    f:SetPoint(db.point or "CENTER", ResolveRelativeFrame(db),
               db.relativePoint or "CENTER", db.x or 0, db.y or 140)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")

    f:SetScript("OnDragStart", function(self)
        if coreState.unlocked then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, relativeTo, relativePoint, x, y = self:GetPoint()
        NPA.db.point         = point
        NPA.db.relativeTo    = (relativeTo and relativeTo ~= UIParent) and relativeTo:GetName() or "UIParent"
        NPA.db.relativePoint = relativePoint
        NPA.db.x             = math_floor(x + 0.5)
        NPA.db.y             = math_floor(y + 0.5)
    end)

    local ag = f:CreateAnimationGroup()
    ag:SetLooping("REPEAT")
    local a1 = ag:CreateAnimation("Alpha")
    a1:SetFromAlpha(1); a1:SetToAlpha(0.15); a1:SetDuration(0.45); a1:SetOrder(1)
    local a2 = ag:CreateAnimation("Alpha")
    a2:SetFromAlpha(0.15); a2:SetToAlpha(1); a2:SetDuration(0.45); a2:SetOrder(2)

    f.flashGroup = ag
    f.alertRows  = {}

    -- ============================================================
    -- Heal-Pet Overlay Subframe
    -- ============================================================
    -- Created unconditionally so the ColorCurve alpha ticker
    -- can drive visibility without nil checks. Position is
    -- updated per-spec inside BuildAlertRows.
    local hpf = CreateFrame("Frame", "NemPetAlertsHealPetFrame", f)
    hpf:SetSize(900, 60)
    hpf:SetPoint("CENTER", f, "CENTER", 0, 0)
    hpf:SetAlpha(0)
    hpf:Hide()
    f.healPetFrame = hpf

    NPA.display = f

    if NPA.db and NPA.db.enabled then
        StartHealPetTicker()
    end
end

local function BuildAlertRows()
    local f   = NPA.display
    local db  = NPA.db
    local mod = NPA.activeModule
    if not f or not db or not mod then return end

    for _, row in ipairs(f.alertRows) do
        row.textFS:Hide()
    end
    wipe(f.alertRows)

    if f.healPetFrame    then f.healPetFrame:Hide()    end
    if f.healFlashTicker then f.healFlashTicker:Hide() end
    if f.testHealFS      then f.testHealFS:Hide()      end

    local fp = GetCurrentFontPath()
    local fs = db.fontSize or 25
    local scale = fs / 25
    local healPetIdx = mod.healPetAlertIndex

    for i, alert in ipairs(mod.alerts) do
        local col = db.alertColors and db.alertColors[alert.key]
                    or alert.defaultColor
                    or { r=1, g=1, b=1 }

        local parent = f
        if mod.hasHealPet and i == healPetIdx then
            f.healPetFrame:ClearAllPoints()
            f.healPetFrame:SetPoint("CENTER", f, "CENTER", 0, (alert.yOffset or 0) * scale)
            parent = f.healPetFrame
        end

        local textFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        textFS:SetFont(fp, fs, "OUTLINE")
        textFS:SetTextColor(col.r, col.g, col.b)
        local customText = db[alert.key .. "AlertText"]
        textFS:SetText((customText and customText ~= "") and customText or alert.text)
        textFS:SetJustifyH("CENTER")
        textFS:SetShadowOffset(2, -2)

        if mod.hasHealPet and i == healPetIdx then
            textFS:SetPoint("CENTER", f.healPetFrame, "CENTER", 0, 0)
        else
            textFS:SetPoint("CENTER", f, "CENTER", 0, (alert.yOffset or 0) * scale)
        end
        textFS:Hide()

        f.alertRows[i] = {
            textFS = textFS,
            key    = alert.key,
            alert  = alert,
        }
    end

    if mod.hasHealPet and healPetIdx then
        local healFlashT = 0
        if not f.healFlashTicker then
            f.healFlashTicker = CreateFrame("Frame", nil, UIParent)
        end
        f.healFlashTicker:Hide()
        f.healFlashTicker:SetScript("OnUpdate", function(_, dt)
            local row = f.alertRows[healPetIdx]
            if not row then return end
            local ts = row.textFS
            local sv = NPA.db
            if sv and sv.flash then
                healFlashT = healFlashT + dt
                local a = 0.15 + 0.85 * (0.5 + 0.5 * math_sin(healFlashT * (math_pi * 2 / 0.9)))
                ts:SetAlpha(a)
            else
                healFlashT = 0
                ts:SetAlpha(1)
            end
        end)

        local def = mod.alerts[healPetIdx]
        local col = db.alertColors and db.alertColors[def.key]
                    or def.defaultColor or { r=1, g=1, b=1 }
        local testFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        testFS:SetFont(fp, fs, "OUTLINE")
        testFS:SetTextColor(col.r, col.g, col.b)
        local testCustomText = db[def.key .. "AlertText"]
        testFS:SetText((testCustomText and testCustomText ~= "") and testCustomText or def.text)
        testFS:SetJustifyH("CENTER")
        testFS:SetShadowOffset(2, -2)
        testFS:SetPoint("CENTER", f, "CENTER", 0, (def.yOffset or 0) * scale)
        testFS:Hide()
        f.testHealFS = testFS
    end

end

-- ============================================================
-- ApplyDisplaySettings
-- ============================================================
local function ApplyDisplaySettings()
    local db = NPA.db
    local f  = NPA.display
    if not f or not db then return end

    f:ClearAllPoints()
    f:SetPoint(db.point or "CENTER", ResolveRelativeFrame(db),
               db.relativePoint or "CENTER", db.x or 0, db.y or 140)

    local fp = GetCurrentFontPath()
    local fs = db.fontSize or 25
    local scale = fs / 25
    local mod = NPA.activeModule
    local healPetIdx = mod and mod.healPetAlertIndex

    for i, row in ipairs(f.alertRows) do
        local col = db.alertColors and db.alertColors[row.key]
                    or row.alert.defaultColor
                    or { r=1, g=1, b=1 }
        row.textFS:SetFont(fp, fs, "OUTLINE")
        row.textFS:SetTextColor(col.r, col.g, col.b)
        local customText = db[row.key .. "AlertText"]
        row.textFS:SetText((customText and customText ~= "") and customText or row.alert.text)

        local y = (row.alert.yOffset or 0) * scale
        if mod and mod.hasHealPet and i == healPetIdx and f.healPetFrame then
            f.healPetFrame:ClearAllPoints()
            f.healPetFrame:SetPoint("CENTER", f, "CENTER", 0, y)
        else
            row.textFS:ClearAllPoints()
            row.textFS:SetPoint("CENTER", f, "CENTER", 0, y)
        end
    end

    if f.testHealFS then
        f.testHealFS:SetFont(fp, fs, "OUTLINE")
        if mod and mod.healPetAlertIndex then
            local def = mod.alerts[mod.healPetAlertIndex]
            if def then
                local col = db.alertColors and db.alertColors[def.key]
                            or def.defaultColor or { r=1, g=1, b=1 }
                f.testHealFS:SetTextColor(col.r, col.g, col.b)
                local ct = db[def.key .. "AlertText"]
                f.testHealFS:SetText((ct and ct ~= "") and ct or def.text)
                f.testHealFS:ClearAllPoints()
                f.testHealFS:SetPoint("CENTER", f, "CENTER", 0, (def.yOffset or 0) * scale)
            end
        end
    end

    f:EnableMouse(coreState.unlocked)
end

-- ============================================================
-- Display-coupled audio cue
-- ============================================================
local function MaybeFireDisplayCue(newIdx)
    if newIdx == coreState.lastDisplayedIdx then return end
    coreState.lastDisplayedIdx = newIdx
    if newIdx == nil then return end
    if coreState.testMode then return end
    if GetTime() < (coreState.suppressCueUntil or 0) then return end

    local mod = NPA.activeModule
    if not mod or not mod.alerts or not mod.alerts[newIdx] then return end
    local alert = mod.alerts[newIdx]
    local alertKey = alert.key
    if not alertKey then return end

    local now      = GetTime()
    local elapsed  = now - (coreState.lastCueTime or 0)
    local critical = (alert.priority or VOICE_PRIO_NORMAL) >= VOICE_PRIO_CRITICAL

    if critical or elapsed >= CUE_GRACE then
        coreState.lastCueTime = now
        NPA:PlayAlertSound(alertKey)
    else
        local targetIdx = newIdx
        local targetKey = alertKey
        C_Timer.After(CUE_GRACE - elapsed, function()
            if coreState.lastDisplayedIdx ~= targetIdx then return end
            coreState.lastCueTime = GetTime()
            NPA:PlayAlertSound(targetKey)
        end)
    end
end

-- ============================================================
-- SetDisplaySlot
-- ============================================================
local function SetDisplaySlot(idx)
    local f = NPA.display
    if not f or not f.alertRows then return end
    local mod = NPA.activeModule
    local healPetIdx = mod and mod.healPetAlertIndex

    if not idx then
        if f.flashGroup:IsPlaying() then f.flashGroup:Stop() end
        f:SetAlpha(1)
        for i, row in ipairs(f.alertRows) do
            if not (mod and mod.hasHealPet and i == healPetIdx) then
                row.textFS:Hide()
            end
        end
        if f.healPetFrame then f.healPetFrame:Hide() end
        if f.healFlashTicker then f.healFlashTicker:Hide() end
        if f.testHealFS then f.testHealFS:Hide() end
        coreState.currentMessage = nil
        MaybeFireDisplayCue(nil)
        return
    end

    if coreState.currentMessage ~= idx then
        for i, row in ipairs(f.alertRows) do
            if not (mod and mod.hasHealPet and i == healPetIdx) then
                if i == idx then row.textFS:Show() else row.textFS:Hide() end
            end
        end
        if f.healPetFrame then
            if mod and mod.hasHealPet and idx == healPetIdx then
                f.healPetFrame:Show()
                f.alertRows[healPetIdx].textFS:Show()
                if f.healFlashTicker then f.healFlashTicker:Show() end
            else
                f.healPetFrame:Hide()
                if f.healFlashTicker then f.healFlashTicker:Hide() end
            end
        end
        coreState.currentMessage = idx
    end

    if mod and mod.hasHealPet and idx == healPetIdx then
        if f.flashGroup:IsPlaying() then f.flashGroup:Stop() end
        f:SetAlpha(1)
    elseif NPA.db.flash then
        if not f.flashGroup:IsPlaying() then f.flashGroup:Play() end
    else
        if f.flashGroup:IsPlaying() then f.flashGroup:Stop() end
        f:SetAlpha(1)
    end

    MaybeFireDisplayCue(idx)
end

NPA.SetDisplaySlot = SetDisplaySlot

-- ============================================================
-- PetNeedsHealing
-- ============================================================
function NPA.PetNeedsHealing()
    if not NPA.PetExists() or UnitIsDead("pet") then return false end
    return true
end

-- ============================================================
-- Evaluate
-- ============================================================
Evaluate = function()
    SafeCall("Evaluate", function()
        local db  = NPA.db
        local mod = NPA.activeModule
        local f   = NPA.display
        if not f then return end

        if not db or not db.enabled then
            SetDisplaySlot(nil)
            if coreState.testMode then
                coreState.testMode = false
                if coreState.testTicker then coreState.testTicker:Cancel(); coreState.testTicker = nil end
            end
            return
        end

        if coreState.testMode then
            if not mod then return end
            local testSlots = mod.testSlots or {}
            local healPetIdx = mod.healPetAlertIndex

            if f.testHealFS then
                if healPetIdx and testSlots[healPetIdx] then
                    f.testHealFS:Show()
                else
                    f.testHealFS:Hide()
                end
            end
            if f.healPetFrame then
                if f.healFlashTicker then f.healFlashTicker:Hide() end
                f.healPetFrame:SetAlpha(0)
                f.healPetFrame:Hide()
            end

            for i, row in ipairs(f.alertRows) do
                if not (mod.hasHealPet and i == healPetIdx) then
                    if testSlots[i] then row.textFS:Show() else row.textFS:Hide() end
                end
            end

            coreState.currentMessage = "TEST"
            if NPA.db.flash then
                if not f.flashGroup:IsPlaying() then f.flashGroup:Play() end
            else
                if f.flashGroup:IsPlaying() then f.flashGroup:Stop() end
                f:SetAlpha(1)
            end
            return
        end

        if not mod then SetDisplaySlot(nil); return end
        if mod.ShouldRun and not mod:ShouldRun(db) then
            SetDisplaySlot(nil); return
        end

        if IsResting() then SetDisplaySlot(nil); return end

        if mod.PreEvaluate then
            SafeCall("PreEvaluate:" .. (mod.specName or "?"), function()
                mod:PreEvaluate(db)
            end)
        end

        local alertIdx = mod:GetHighestPriorityAlert(db)
        SetDisplaySlot(alertIdx)

        local healPetIdx = mod.healPetAlertIndex
        if mod.hasHealPet and coreState.currentMessage == healPetIdx and f.healPetFrame then
            local warningAlpha = NPA.GetPetHealthWarningAlpha()
            if warningAlpha ~= nil then
                pcall(f.healPetFrame.SetAlpha, f.healPetFrame, warningAlpha)
            else
                f.healPetFrame:SetAlpha(0)
            end
        end
    end)
end

NPA.Evaluate = function() Evaluate() end

-- ============================================================
-- Lock / Unlock
-- ============================================================
local function SetLockState(unlocked)
    coreState.unlocked = unlocked
    local f = NPA.display
    if f then f:EnableMouse(unlocked) end
    if NPA.lockBtn then
        NPA.lockBtn:SetText(unlocked and "Lock Frame" or "Unlock Frame")
    end
    Msg(unlocked
        and "Frame |cff00ff00unlocked|r — drag to reposition."
         or "Frame |cffff4444locked|r.")
end

-- ============================================================
-- Module Activation / Deactivation
-- ============================================================
local registeredExtraEvents = {}

local function DeactivateCurrentModule()
    local mod = NPA.activeModule
    if not mod then return end

    if mod.OnDeactivate then mod:OnDeactivate(NPA.db) end
    if mod.ClearAllState then mod:ClearAllState() end

    for _, ev in ipairs(registeredExtraEvents) do
        NPA:UnregisterEvent(ev)
    end
    wipe(registeredExtraEvents)

    NPA.activeModule    = nil
    NPA.activeModuleKey = nil
end

local function ActivateModule(key, mod)
    DeactivateCurrentModule()

    NPA.activeModule    = mod
    NPA.activeModuleKey = key

    if mod.defaults then
        MergeDefaults(NPA.db, mod.defaults)
    end

    -- Heal-pet sound is force-disabled: WoW's restricted-aura API blocks
    -- reliable pet-health detection, so a heal cue would fire incorrectly.
    NPA.db.healPetSoundEnabled = false

    NPA.db.alertColors = NPA.db.alertColors or {}
    for _, alert in ipairs(mod.alerts) do
        if not NPA.db.alertColors[alert.key] then
            NPA.db.alertColors[alert.key] = CopyTable(alert.defaultColor
                or { r=1, g=1, b=1 })
        end
    end

    if mod.extraEvents then
        for _, ev in ipairs(mod.extraEvents) do
            NPA:RegisterEvent(ev)
            registeredExtraEvents[#registeredExtraEvents+1] = ev
        end
    end
    if mod.extraUnitEvents then
        for _, spec in ipairs(mod.extraUnitEvents) do
            NPA:RegisterUnitEvent(spec[1], spec[2], spec[3])
            registeredExtraEvents[#registeredExtraEvents+1] = spec[1]
        end
    end

    coreState.lastDisplayedIdx = nil
    coreState.lastCueTime      = 0
    coreState.suppressCueUntil = GetTime() + ACTIVATION_SUPPRESS

    local activateOk = true
    if mod.OnActivate then
        activateOk = SafeCall("OnActivate:" .. (mod.specName or "?"), function()
            mod:OnActivate(NPA.db)
        end)
    end

    if not activateOk then
        -- Rollback: tear down the half-activated module so the addon
        -- ends in a clean "no module" state rather than half-swapped.
        DeactivateCurrentModule()
        return
    end

    -- Build rows only after activation is confirmed: a failed OnActivate then
    -- rolls back without leaking frames, and rows pick up any alert changes it made.
    BuildAlertRows()
    ApplyDisplaySettings()

    Evaluate()

    -- Spec switch with the panel open: rebuild its per-spec rows.
    if NPA.optionsPanel and NPA.optionsPanel:IsShown() then
        NPA.optionsPanel:Hide()
        NPA.optionsPanel:Show()
    end
end

-- ============================================================
-- Init: Database
-- ============================================================
function NPA:InitDatabase()
    NemPetAlertsSV = NemPetAlertsSV or {}
    local db = NemPetAlertsSV

    -- Legacy normalization runs only for pre-v7 data. A flat v7 db carries a
    -- top-level db.ver=7 (and no db.global), so it skips straight to the merge.
    if (db.ver or 0) < 7 then
    local isV4 = (type(db.global) == "table" and type(db.specs) == "table")

    if not isV4 then
        -- ===== Pre-v4 flat migrations: bring existing flat data to v3 first =====
        if (db.ver or 0) < 2 then
            if db.ver == 1 then
                local saved = {
                    enabled          = db.enabled,
                    flash            = db.flash,
                    fontSize         = db.fontSize,
                    fontName         = db.fontName,
                    x                = db.x,
                    y                = db.y,
                    point            = db.point,
                    relativePoint    = db.relativePoint,
                    relativeTo       = db.relativeTo,
                    healPetThreshold = db.healPetThreshold,
                }
                local soundMigration = {
                    sound            = db.sound,
                    ccSoundName      = db.ccSoundName,
                    petDeadSound     = db.petDeadSound,
                    petDeadSoundName = db.petDeadSoundName,
                }
                local alertsMigration = db.alerts and CopyTable(db.alerts) or nil
                local colorsMigration = db.alertColors and CopyTable(db.alertColors) or nil

                wipe(db)
                for k, v in pairs(CORE_DEFAULTS) do
                    if type(v) == "table" then db[k] = CopyTable(v) else db[k] = v end
                end
                for k, v in pairs(saved) do
                    if v ~= nil then db[k] = v end
                end
                if soundMigration.sound ~= nil then
                    db.ccSoundEnabled = soundMigration.sound
                end
                if soundMigration.ccSoundName then
                    db.ccSoundName = soundMigration.ccSoundName
                end
                if soundMigration.petDeadSound ~= nil then
                    db.petDeadSoundEnabled = soundMigration.petDeadSound
                end
                if soundMigration.petDeadSoundName then
                    db.petDeadSoundName = soundMigration.petDeadSoundName
                end
                if alertsMigration then
                    for alertKey, enabled in pairs(alertsMigration) do
                        db[alertKey .. "Enabled"] = enabled
                    end
                end
                if colorsMigration then
                    db.alertColors = colorsMigration
                end
            elseif (db.ver or 0) == 0 and next(db) == nil then
                for k, v in pairs(CORE_DEFAULTS) do
                    if type(v) == "table" then db[k] = CopyTable(v) else db[k] = v end
                end
            else
                wipe(db)
                for k, v in pairs(CORE_DEFAULTS) do
                    if type(v) == "table" then db[k] = CopyTable(v) else db[k] = v end
                end
            end
            db.ver = 2
        end
        if (db.ver or 0) < 3 then
            db.scale = nil
            db.ver   = 3
        end

        -- ===== v3 → v4: split flat → { global, specs, _pendingSpecMigration } =====
        local newGlobal = {}
        local pendingSpecData = {}
        for k, v in pairs(db) do
            if GLOBAL_KEYS[k] then
                newGlobal[k] = v
            else
                pendingSpecData[k] = v
            end
        end
        wipe(db)
        db.global = newGlobal
        db.specs  = {}
        if next(pendingSpecData) then
            db._pendingSpecMigration = pendingSpecData
        end
        db.global.ver = 4
    end

    -- ===== v5 → v6: rename CC alert key "notAttacking" → "petInCC" =====
    -- The CC alert's key is the stem for all its per-spec saved-variable
    -- fields. Renaming the key (to disambiguate it from the separate
    -- "petNotAttacking" alert) renames those fields too; copy each old value
    -- to its new name so existing users keep their CC toggle, sound, color,
    -- and custom text.
    if (db.global.ver or 0) < 6 then
        local CC_RENAME = {
            notAttackingEnabled      = "petInCCEnabled",
            notAttackingSoundEnabled = "petInCCSoundEnabled",
            notAttackingSoundName    = "petInCCSoundName",
            notAttackingAlertText    = "petInCCAlertText",
        }
        local function migrateCCKeys(t)
            if type(t) ~= "table" then return end
            for oldKey, newKey in pairs(CC_RENAME) do
                if t[oldKey] ~= nil and t[newKey] == nil then
                    t[newKey] = t[oldKey]
                end
                t[oldKey] = nil
            end
            if type(t.alertColors) == "table" then
                local c = t.alertColors
                if c.notAttacking ~= nil and c.petInCC == nil then
                    c.petInCC = c.notAttacking
                end
                c.notAttacking = nil
            end
        end
        if type(db.specs) == "table" then
            for _, specData in pairs(db.specs) do
                migrateCCKeys(specData)
            end
        end
        migrateCCKeys(db._pendingSpecMigration)
        db.global.ver = 6
    end

    -- ===== v6 → v7: collapse { global, specs } → flat account-global =====
    -- db.global, every db.specs[*] bucket, and the ancient
    -- db._pendingSpecMigration blob fold into one flat table. Conflicts (a key
    -- the user set differently across specs) resolve current-class-first,
    -- first-writer-wins. Warlock buckets' fakeDeath* keys remap to
    -- sacrificeDemon* so they don't collide with Hunter's fakeDeath* (Wake Up
    -- Pet) in the now-shared flat namespace.
    if type(db.global) == "table" then
        local flat = {}
        for k, v in pairs(db.global) do
            flat[k] = (type(v) == "table") and CopyTable(v) or v
        end

        local WARLOCK_RENAME = {
            fakeDeathEnabled      = "sacrificeDemonEnabled",
            fakeDeathSoundEnabled = "sacrificeDemonSoundEnabled",
            fakeDeathSoundName    = "sacrificeDemonSoundName",
            fakeDeathAlertText    = "sacrificeDemonAlertText",
        }

        local function FoldBucket(bucket, isWarlock)
            if type(bucket) ~= "table" then return end
            for k, v in pairs(bucket) do
                if k == "alertColors" and type(v) == "table" then
                    flat.alertColors = flat.alertColors or {}
                    for ck, cv in pairs(v) do
                        local nk = (isWarlock and ck == "fakeDeath") and "sacrificeDemon" or ck
                        if flat.alertColors[nk] == nil then
                            flat.alertColors[nk] = (type(cv) == "table") and CopyTable(cv) or cv
                        end
                    end
                else
                    local nk = (isWarlock and WARLOCK_RENAME[k]) or k
                    if flat[nk] == nil then
                        flat[nk] = (type(v) == "table") and CopyTable(v) or v
                    end
                end
            end
        end

        local _, playerClass = UnitClass("player")
        local ordered = {}
        if type(db.specs) == "table" then
            for specKey in pairs(db.specs) do ordered[#ordered + 1] = specKey end
        end
        table.sort(ordered, function(a, b)
            local ca = NPA.specModules[a] and NPA.specModules[a].class
            local cb = NPA.specModules[b] and NPA.specModules[b].class
            local pa = (ca == playerClass) and 0 or 1
            local pb = (cb == playerClass) and 0 or 1
            if pa ~= pb then return pa < pb end
            return a < b
        end)
        for _, specKey in ipairs(ordered) do
            local cls = NPA.specModules[specKey] and NPA.specModules[specKey].class
            FoldBucket(db.specs[specKey], cls == "WARLOCK")
        end

        FoldBucket(db._pendingSpecMigration, false)

        wipe(db)
        for k, v in pairs(flat) do db[k] = v end
    end
    db.ver = 7
    end

    MergeDefaults(db, CORE_DEFAULTS)
    db.ver = 7
    self.db = db
end

-- ============================================================
-- Test Mode
-- ============================================================
function NPA:ToggleTest()
    if not IsFullyImplemented() then return end
    coreState.testMode = not coreState.testMode
    if coreState.testMode then
        if not coreState.testTicker then
            coreState.testTicker = C_Timer.NewTicker(0.1, Evaluate)
        end
    else
        if coreState.testTicker then coreState.testTicker:Cancel(); coreState.testTicker = nil end
        coreState.currentMessage = nil
        SetDisplaySlot(nil)
        coreState.suppressCueUntil = GetTime() + ACTIVATION_SUPPRESS
    end
    if NPA.testBtn then
        NPA.testBtn:SetText(coreState.testMode and "Stop Test" or "Test")
    end
    Evaluate()
end

-- ============================================================
-- Init: Slash Commands
-- ============================================================
function NPA:InitCommands()
    local function HandleNPACommand(input)
        input = (input or ""):lower():match("^%s*(.-)%s*$")

        local NEEDS_SUPPORT = {
            on=true, off=true, toggle=true, test=true,
            lock=true, unlock=true, reset=true,
        }
        if NEEDS_SUPPORT[input] and not IsFullyImplemented() then
            Msg("Your current spec is not supported.")
            return
        end

        local mod = self.activeModule
        if mod and mod.slashCommands and mod.slashCommands[input] then
            mod.slashCommands[input](mod, self.db)
            return
        end

        if input == "on" then
            self.db.enabled = true
            StartHealPetTicker()
            Evaluate()
            Msg("Addon |cff00ff41enabled|r.")
            return
        end

        if input == "off" then
            self.db.enabled = false
            StopHealPetTicker()
            if mod and mod.ClearAllState then mod:ClearAllState() end
            SetDisplaySlot(nil)
            if NPA.display then NPA.display:SetAlpha(1) end
            if coreState.testMode then NPA:ToggleTest() end
            Evaluate()
            Msg("Addon |cffff4040disabled|r.")
            return
        end

        if input == "toggle" then
            if self.db.enabled then
                self.db.enabled = false
                StopHealPetTicker()
                if mod and mod.ClearAllState then mod:ClearAllState() end
                SetDisplaySlot(nil)
                if NPA.display then NPA.display:SetAlpha(1) end
                if coreState.testMode then NPA:ToggleTest() end
                Msg("Addon |cffff4040disabled|r.")
            else
                self.db.enabled = true
                StartHealPetTicker()
                Msg("Addon |cff00ff41enabled|r.")
            end
            Evaluate()
            return
        end

        if input == "test" then
            if not self.db.enabled then
                Msg("Addon is disabled. Use |cffffd700/npa on|r first.")
                return
            end
            NPA:ToggleTest()
            Msg(coreState.testMode and "Test mode |cff00ff41on|r." or "Test mode |cffff4040off|r.")
            return
        end

        if input == "status" then
            local enabledStr = self.db.enabled
                and "|cff00ff41Enabled|r" or "|cffff4040Disabled|r"
            local testStr = coreState.testMode
                and "|cffffff00On|r" or "Off"
            local classStr = activeClass or "Unknown"
            Msg(string_format("Status: %s  |  Test Mode: %s  |  Class: %s",
                enabledStr, testStr, classStr))

            local errorCount = 0
            for _ in pairs(NPA._errors) do errorCount = errorCount + 1 end
            Msg(string_format("Errors logged: %d", errorCount))
            if errorCount > 0 then
                for label, entry in pairs(NPA._errors) do
                    Msg(string_format("  [%s] %s (at %.1fs)",
                        label, entry.msg or "?", entry.time or 0))
                end
            end
            return
        end

        if input == "help" then
            Msg("|cffffd700Nem: Pet Alerts — Commands:|r")
            Msg("  |cffffd700/npa|r  —  Open options")
            Msg("  |cffffd700/npa on|r  —  Enable addon")
            Msg("  |cffffd700/npa off|r  —  Disable addon")
            Msg("  |cffffd700/npa toggle|r  —  Toggle on/off")
            Msg("  |cffffd700/npa test|r  —  Toggle test mode")
            Msg("  |cffffd700/npa status|r  —  Show current status")
            Msg("  |cffffd700/npa reset|r  —  Reset all settings")
            Msg("  |cffffd700/npa version|r  —  Show addon version")
            Msg("  |cffffd700/npa help|r  —  Show this list")
            Msg("  (All commands also work with |cffffd700/petalerts|r)")
            if mod and mod.slashCommands then
                for cmd, _ in pairs(mod.slashCommands) do
                    Msg("  |cffffd700/npa " .. cmd .. "|r  —  (spec-specific)")
                end
            end
            return
        end

        if input == "version" then
            Msg("Nem: Pet Alerts " .. NPA_VERSION)
            return
        end

        if input == "reset" then
            NemPetAlertsSV = nil
            Msg("Saved variables reset. Reloading UI...")
            C_Timer.After(0.5, ReloadUI)
            return
        end

        if input == "unlock" then SetLockState(true);  return end
        if input == "lock"   then SetLockState(false); return end

        if input == "debug" then
            NPA:RunDebug()
            return
        end

        if NPA.optionsCategoryID then
            if InCombatLockdown() then
                Msg("Can't open options during combat.")
                return
            end
            if Settings and Settings.OpenToCategory then
                NPA._panelWasOpen = true
                Settings.OpenToCategory(NPA.optionsCategoryID)
            end
        end
    end

    SLASH_NEMPETALERTS1 = "/npa"
    SLASH_NEMPETALERTS2 = "/petalerts"
    SlashCmdList.NEMPETALERTS = HandleNPACommand

    if AddonCompartmentFrame then
        AddonCompartmentFrame:RegisterAddon({
            text = "Nem: Pet Alerts", notCheckable = true,
            func = function()
                if InCombatLockdown() then
                    Msg("Can't open options during combat.")
                else
                    if NPA.optionsCategoryID and Settings and Settings.OpenToCategory then
                        NPA._panelWasOpen = true
                        Settings.OpenToCategory(NPA.optionsCategoryID)
                    end
                end
            end,
        })
    end
end

-- ============================================================
-- Debug Command
-- ============================================================
function NPA:RunDebug()
    local db  = self.db
    local mod = self.activeModule
    local ok, err

    Msg("--- NemPetAlerts Debug ---")

    ok, err = pcall(function()
        Msg("class=" .. tostring(activeClass)
            .. "  module=" .. tostring(self.activeModuleKey)
            .. "  enabled=" .. tostring(db and db.enabled))
    end)
    if not ok then Msg("ERROR(1): " .. tostring(err)) end

    ok, err = pcall(function()
        Msg("petExists=" .. tostring(NPA.PetExists())
            .. "  petAlive=" .. tostring(NPA.PetAlive())
            .. "  petDead=" .. tostring(NPA.PetExists() and UnitIsDead("pet") or "n/a"))
    end)
    if not ok then Msg("ERROR(2): " .. tostring(err)) end

    ok, err = pcall(function()
        Msg("inGroup=" .. tostring(IsInGroup())
            .. "  inRaid=" .. tostring(IsInRaid())
            .. "  members=" .. tostring(GetNumGroupMembers()))
    end)
    if not ok then Msg("ERROR(3): " .. tostring(err)) end

    ok, err = pcall(function()
        Msg("CC(live)=" .. tostring(NPA.PetIsCC())
            .. "  passive=" .. tostring(NPA.PetIsPassive())
            .. "  notAttacking=" .. tostring(NPA.PetNotAttacking()))
    end)
    if not ok then Msg("ERROR(4): " .. tostring(err)) end

    if mod and mod.Debug then
        mod:Debug(db)
    end
end

-- ============================================================
-- Options Panel
-- ============================================================
function NPA:BuildOptionsPanel()
    local db = self.db
    local PW = 668

    local panel = CreateFrame("Frame", "NemPetAlertsOptionsPanel", UIParent)
    panel.name = "Nem: Pet Alerts"
    NPA.optionsPanel = panel
    panel:SetSize(PW, 580)

    -- ============================================================
    -- Scroll System
    -- ============================================================
    local SCROLL_TOP = -62
    local SCROLL_BTM =  56
    local SB_W       =  4
    local SB_MARGIN  = 10

    local VIEWPORT_L = 8
    local VIEWPORT_R = SB_MARGIN
    local BOX_INSET  = 2
    local CW = PW - VIEWPORT_L - VIEWPORT_R - (BOX_INSET * 2)

    local viewport = CreateFrame("Frame", nil, panel)
    viewport:SetPoint("TOPLEFT",     panel, "TOPLEFT",      VIEWPORT_L,  SCROLL_TOP)
    viewport:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -VIEWPORT_R,  SCROLL_BTM)
    viewport:SetClipsChildren(true)

    local scrollContent = CreateFrame("Frame", nil, viewport)
    scrollContent:SetWidth(CW)
    scrollContent:SetHeight(1)
    scrollContent:SetPoint("TOPLEFT", viewport, "TOPLEFT", BOX_INSET, 0)

    local scrollOffset = 0

    local function ApplyScroll(offset)
        local maxScroll = math_max(0, scrollContent:GetHeight() - viewport:GetHeight())
        if offset < 0         then offset = 0         end
        if offset > maxScroll then offset = maxScroll end
        scrollOffset = offset
        scrollContent:SetPoint("TOPLEFT", viewport, "TOPLEFT", BOX_INSET, scrollOffset)
        return scrollOffset, maxScroll
    end

    local sbBar = CreateFrame("Frame", nil, panel)
    sbBar:SetWidth(SB_W)
    sbBar:SetPoint("TOP",    panel, "TOPRIGHT",    -(SB_MARGIN - 2), SCROLL_TOP)
    sbBar:SetPoint("BOTTOM", panel, "BOTTOMRIGHT", -(SB_MARGIN - 2), SCROLL_BTM)
    sbBar:SetFrameLevel(panel:GetFrameLevel() + 10)

    local railTex = sbBar:CreateTexture(nil, "BACKGROUND")
    railTex:SetAllPoints(true)
    railTex:SetColorTexture(0.22, 0.22, 0.22, 0.85)

    local sbThumb = CreateFrame("Button", nil, sbBar)
    sbThumb:SetWidth(SB_W)
    sbThumb:SetHeight(40)
    sbThumb:SetPoint("TOP", sbBar, "TOP", 0, 0)

    local thumbTex = sbThumb:CreateTexture(nil, "ARTWORK")
    thumbTex:SetAllPoints(true)
    do local tr, tg, tb = GetClassTheme(); thumbTex:SetColorTexture(tr, tg, tb, 0.85) end

    local thumbHL = sbThumb:CreateTexture(nil, "HIGHLIGHT")
    thumbHL:SetAllPoints(true)
    thumbHL:SetColorTexture(1, 1, 1, 0.2)

    sbBar:EnableMouse(true)
    sbBar:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / UIParent:GetEffectiveScale()
        local trackTop    = sbBar:GetTop()
        local trackBottom = sbBar:GetBottom()
        if not trackTop or trackTop == trackBottom then return end
        local ratio = (trackTop - cursorY) / (trackTop - trackBottom)
        ratio = math_max(0, math_min(1, ratio))
        local maxScroll = math_max(0, scrollContent:GetHeight() - viewport:GetHeight())
        ApplyScroll(ratio * maxScroll)
        sbBar:UpdateScrollbar()
    end)

    function sbBar:UpdateScrollbar()
        local viewH     = viewport:GetHeight()
        local childH    = scrollContent:GetHeight()
        local maxScroll = math_max(0, childH - viewH)
        if viewH <= 0 then
            C_Timer.After(0.05, function() sbBar:UpdateScrollbar() end)
            return
        end
        if maxScroll <= 0 then sbBar:Hide(); return end
        sbBar:Show()
        local trackH = sbBar:GetHeight()
        local thumbH = math_floor(math_max(20, trackH * (viewH / childH)) + 0.5)
        sbThumb:SetHeight(thumbH)
        local travel = trackH - thumbH
        local pos    = travel > 0 and (scrollOffset / maxScroll) * travel or 0
        sbThumb:ClearAllPoints()
        sbThumb:SetPoint("TOP", sbBar, "TOP", 0, -math_floor(pos + 0.5))
    end

    local dragStartY, dragStartOffset
    sbThumb:RegisterForDrag("LeftButton")
    sbThumb:SetScript("OnDragStart", function(self)
        dragStartY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        dragStartOffset = scrollOffset
        self:SetScript("OnUpdate", function()
            local curY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
            local delta     = dragStartY - curY
            local trackH    = sbBar:GetHeight()
            local thumbH    = sbThumb:GetHeight()
            local viewH     = viewport:GetHeight()
            local childH    = scrollContent:GetHeight()
            local maxScroll = math_max(0, childH - viewH)
            local travel    = trackH - thumbH
            if travel > 0 then
                ApplyScroll(dragStartOffset + delta * (maxScroll / travel))
                sbBar:UpdateScrollbar()
            end
        end)
    end)
    sbThumb:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    viewport:EnableMouseWheel(true)
    viewport:SetScript("OnMouseWheel", function(self, delta)
        ApplyScroll(scrollOffset - delta * 40)
        sbBar:UpdateScrollbar()
    end)

    local function SetContentHeight(h)
        scrollContent:SetHeight(h)
        ApplyScroll(0)
        C_Timer.After(0.05, function() sbBar:UpdateScrollbar() end)
    end

    local CPW = CW - 4

    local function SetUIFont(fs, size, flags)
        fs:SetFont(UI_FONT, size or 12, flags or "")
    end

    local THEME_R, THEME_G, THEME_B
    if IsFullyImplemented() then
        THEME_R, THEME_G, THEME_B = GetClassTheme()
    else
        THEME_R = CLASS_THEME_DEFAULT.r
        THEME_G = CLASS_THEME_DEFAULT.g
        THEME_B = CLASS_THEME_DEFAULT.b
    end

    local themeFS    = {}
    local themeBoxes = {}

    local function UpdatePanelTheme()
        local r, g, b
        if IsFullyImplemented() then
            r, g, b = GetClassTheme()
        else
            r, g, b = CLASS_THEME_DEFAULT.r, CLASS_THEME_DEFAULT.g, CLASS_THEME_DEFAULT.b
        end
        THEME_R, THEME_G, THEME_B = r, g, b
        for _, entry in ipairs(themeFS) do
            if entry.setColor then
                entry.setColor(r, g, b)
            else
                entry.fs:SetTextColor(r, g, b, entry.alpha or 1)
            end
        end
        for _, box in ipairs(themeBoxes) do
            if box.SetBackdropBorderColor then
                box:SetBackdropBorderColor(r, g, b, 0.3)
            end
        end
        thumbTex:SetColorTexture(r, g, b, 0.85)
    end

    -- ============================================================
    -- UI Helpers
    -- ============================================================
    local function SectionBox(x, y, w, h)
        local box = CreateFrame("Frame", nil, scrollContent,
            BackdropTemplateMixin and "BackdropTemplate" or nil)
        box:SetPoint("TOPLEFT", x, y)
        box:SetSize(w, h)
        if box.SetBackdrop then
            box:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            box:SetBackdropColor(0.08, 0.08, 0.08, 0.6)
            box:SetBackdropBorderColor(THEME_R, THEME_G, THEME_B, 0.3)
        end
        themeBoxes[#themeBoxes + 1] = box
        return box
    end

    local function SectionHeader(parent, text, x, y)
        local fs = parent:CreateFontString(nil, "OVERLAY")
        fs:SetPoint("TOPLEFT", x, y)
        SetUIFont(fs, 15, "OUTLINE")
        fs:SetText(text)
        fs:SetTextColor(THEME_R, THEME_G, THEME_B)
        themeFS[#themeFS + 1] = { fs=fs, alpha=1 }
        return fs
    end

    local checkboxes = {}
    local function MakeCheckbox(labelText, x, y, getter, setter)
        local cb = CreateFrame("CheckButton", nil, scrollContent, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", x, y)
        cb:SetChecked(getter())
        cb:SetScript("OnClick", function(self)
            setter(self:GetChecked())
            Evaluate()
        end)
        local label = cb:CreateFontString(nil, "OVERLAY")
        label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        SetUIFont(label, 12)
        label:SetText(labelText)
        label:SetTextColor(1, 1, 1)
        cb.Refresh = function() cb:SetChecked(getter()) end
        cb.label = label
        return cb
    end

    local function MakeAlertRow(parent, labelText, x, y, getter, setter, colorKey)
        local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", x, y)
        cb:SetChecked(getter())
        cb:SetScript("OnClick", function(self)
            setter(self:GetChecked())
            Evaluate()
        end)

        local labelAnchor = cb
        if colorKey and db.alertColors and db.alertColors[colorKey] then
            local swatchBtn = CreateFrame("Button", nil, cb)
            swatchBtn:SetSize(12, 12)
            swatchBtn:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            swatchBtn:EnableMouse(true)
            local swatchTex = swatchBtn:CreateTexture(nil, "OVERLAY")
            swatchTex:SetAllPoints()
            local col0 = db.alertColors[colorKey]
            swatchTex:SetColorTexture(col0.r, col0.g, col0.b, 1)
            cb.swatchTex = swatchTex

            local swatchBorder = cb:CreateTexture(nil, "BORDER")
            swatchBorder:SetSize(14, 14)
            swatchBorder:SetPoint("CENTER", swatchBtn, "CENTER", 0, 0)
            swatchBorder:SetColorTexture(0, 0, 0, 1)

            swatchBtn:SetScript("OnClick", function()
                local c = db.alertColors[colorKey]
                local cr, cg, cb2 = c.r, c.g, c.b

                local function ApplyColor(nr, ng, nb)
                    swatchTex:SetColorTexture(nr, ng, nb, 1)
                    db.alertColors[colorKey] = { r=nr, g=ng, b=nb }
                    local f = NPA.display
                    if f then
                        for _, row in ipairs(f.alertRows) do
                            if row.key == colorKey then
                                row.textFS:SetTextColor(nr, ng, nb)
                            end
                        end
                        local mod = NPA.activeModule
                        if mod and mod.healPetAlertIndex then
                            local hpAlert = mod.alerts[mod.healPetAlertIndex]
                            if hpAlert and hpAlert.key == colorKey and f.testHealFS then
                                f.testHealFS:SetTextColor(nr, ng, nb)
                            end
                        end
                    end
                end

                ColorPickerFrame:SetupColorPickerAndShow({
                    swatchFunc = function()
                        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                        ApplyColor(nr, ng, nb)
                    end,
                    cancelFunc = function(prev)
                        ApplyColor(prev.r, prev.g, prev.b)
                    end,
                    r=cr, g=cg, b=cb2,
                })
            end)
            swatchBtn:SetScript("OnEnter", function(s) s:SetAlpha(0.65) end)
            swatchBtn:SetScript("OnLeave", function(s) s:SetAlpha(1) end)
            labelAnchor = swatchBtn
        end

        local label = cb:CreateFontString(nil, "OVERLAY")
        label:SetPoint("LEFT", labelAnchor, "RIGHT", 6, 0)
        SetUIFont(label, 12)
        label:SetText(labelText)
        label:SetTextColor(1, 1, 1)
        cb.label = label
        cb.Refresh = function() cb:SetChecked(getter()) end
        return cb
    end

    local sliders = {}
    local function MakeSlider(parent, labelText, minVal, maxVal, step, x, y, width, getter, setter, formatFunc)
        local container = CreateFrame("Frame", nil, parent)
        container:SetPoint("TOPLEFT", x, y)
        container:SetSize(width, 60)
        local label = container:CreateFontString(nil, "OVERLAY")
        label:SetPoint("TOPLEFT", 0, 0)
        SetUIFont(label, 12)
        label:SetText(labelText)
        label:SetTextColor(1, 1, 1)
        local slider = CreateFrame("Slider", nil, container, "OptionsSliderTemplate")
        slider:SetPoint("TOPLEFT", 0, -18)
        slider:SetWidth(width)
        slider:SetMinMaxValues(minVal, maxVal)
        slider:SetValueStep(step)
        slider:SetObeyStepOnDrag(true)
        slider:SetValue(getter())
        slider.Low:SetText("")
        slider.High:SetText("")
        local function DisplayVal(v)
            if formatFunc then return formatFunc(v) end
            return tostring(v)
        end
        local box = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
        box:SetPoint("TOP", slider, "BOTTOM", 0, -4)
        box:SetSize(60, 20)
        box:SetAutoFocus(false)
        box:SetMaxLetters(6)
        box:SetFontObject("GameFontWhite")
        box:SetJustifyH("CENTER")
        box:SetText(DisplayVal(getter()))
        box:SetCursorPosition(0)
        themeFS[#themeFS + 1] = { setColor = function(r, g, b) box:SetTextColor(r, g, b) end }
        slider:SetScript("OnValueChanged", function(_, val, userInput)
            if userInput ~= nil and not userInput then return end
            local snapped = math_floor(val / step + 0.5) * step
            setter(snapped)
            box:SetText(DisplayVal(snapped))
            box:SetCursorPosition(0)
            Evaluate()
        end)
        box:SetScript("OnTextChanged", function(_, userInput)
            if not userInput then return end
            local raw = box:GetText()
            local val = tonumber(raw)
            if val and formatFunc and val < minVal then
                val = math_floor(val * 100 + 0.5)
            end
            if not val then return end
            slider:SetValue(val)
            setter(val)
        end)
        box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        box:SetScript("OnEditFocusLost", function()
            local raw = box:GetText()
            local val = tonumber(raw)
            if val and formatFunc and val < minVal then
                val = math_floor(val * 100 + 0.5)
            end
            if val then
                val = math_max(minVal, math_min(maxVal, val))
                val = math_floor(val / step + 0.5) * step
                setter(val)
                slider:SetValue(val)
            end
            box:SetText(DisplayVal(getter()))
            box:SetCursorPosition(0)
        end)
        container.Refresh = function()
            slider:SetValue(getter())
            box:SetText(DisplayVal(getter()))
            box:SetCursorPosition(0)
        end
        return container
    end

    local soundCheckboxes = {}
    local soundDDs        = {}
    local function MakeSoundRow(parent, labelText, y, getEnabled, setEnabled, getSound, setSound)
        local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 8, y)
        cb:SetChecked(getEnabled())
        cb:SetScript("OnClick", function(self) setEnabled(self:GetChecked()) end)
        local lbl = cb:CreateFontString(nil, "OVERLAY")
        lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        SetUIFont(lbl, 12)
        lbl:SetText(labelText)
        lbl:SetTextColor(1, 1, 1)
        cb.Refresh = function() cb:SetChecked(getEnabled()) end

        local dd = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
        dd:SetPoint("LEFT", cb, "RIGHT", 284, 0)
        dd:SetWidth(220)
        local function SetupMenu()
            dd:SetupMenu(function(_, root)
                root:SetScrollMode(12 * 16)
                local activePrefix = GetActiveClassVoicePrefix()
                local ttsMatch     = activePrefix and ("^" .. activePrefix .. ":") or nil
                local function ShowName(name)
                    if IsTTSSound(name) then
                        return ttsMatch and name:find(ttsMatch) ~= nil
                    end
                    return true
                end
                local hasTTS, hasGeneric = false, false
                for _, name in ipairs(SOUND_NAMES) do
                    if ShowName(name) then
                        if IsTTSSound(name) then hasTTS = true else hasGeneric = true end
                    end
                end
                local showHeaders = hasTTS and hasGeneric
                local ttsHeader, genericHeader = false, false
                for _, name in ipairs(SOUND_NAMES) do
                    if ShowName(name) then
                        if IsTTSSound(name) then
                            if showHeaders and not ttsHeader then
                                root:CreateTitle("Class TTS")
                                ttsHeader = true
                            end
                        else
                            if showHeaders and not genericHeader then
                                root:CreateTitle("Generic")
                                genericHeader = true
                            end
                        end
                        local n = name
                        root:CreateRadio(n,
                            function() return getSound() == n end,
                            function() setSound(n); dd:SetDefaultText(n) end,
                            n)
                    end
                end
            end)
        end
        C_Timer.After(0, SetupMenu)
        dd:SetDefaultText(getSound() or "")

        local previewBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        previewBtn:SetSize(60, 20)
        previewBtn:SetPoint("LEFT", dd, "RIGHT", 6, 0)
        previewBtn:SetText("Preview")
        previewBtn:SetScript("OnClick", function()
            PlaySoundFile(GetSoundPath(getSound()), "Master")
        end)
        dd.Refresh = function()
            dd:SetDefaultText(getSound() or "")
            SetupMenu()
        end
        return cb, dd
    end

    -- ============================================================
    -- Title
    -- ============================================================
    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", panel, "TOP", 0, -16)
    SetUIFont(title, 20, "OUTLINE")
    title:SetText("Nem: Pet Alerts")
    title:SetTextColor(THEME_R, THEME_G, THEME_B)
    themeFS[#themeFS + 1] = { fs=title, alpha=1 }

    local subtitle = panel:CreateFontString(nil, "OVERLAY")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -6)
    subtitle:SetWidth(PW - 32)
    subtitle:SetJustifyH("CENTER")
    SetUIFont(subtitle, 11)
    subtitle:SetText("Pet status warnings for all pet classes. Type /npa to open this panel.")
    subtitle:SetTextColor(0.75, 0.75, 0.75)

    -- ============================================================
    -- Display
    -- ============================================================
    local displayBox = SectionBox(0, 0, CPW, 155)
    SectionHeader(displayBox, "Display", 8, -6)

    checkboxes.enabled = MakeCheckbox("Enable Addon", 8, -28,
        function() return db.enabled end,
        function(v)
            db.enabled = v and true or false
            if not db.enabled then
                StopHealPetTicker()
                SetDisplaySlot(nil)
                if NPA.display then NPA.display:SetAlpha(1) end
                coreState.testMode = false
                if coreState.testTicker then coreState.testTicker:Cancel(); coreState.testTicker = nil end
                if NPA.testBtn then NPA.testBtn:SetText("Test") end
            else
                StartHealPetTicker()
            end
        end)

    checkboxes.flash = MakeCheckbox("Flash Animation", 8, -68,
        function() return db.flash end,
        function(v)
            db.flash = v and true or false
            if not db.flash then
                if NPA.display then
                    local f = NPA.display
                    if f.flashGroup and f.flashGroup:IsPlaying() then f.flashGroup:Stop() end
                    f:SetAlpha(1)
                    if f.healPetFrame then f.healPetFrame:SetAlpha(1) end
                end
            end
        end)


    sliders.fontSize = MakeSlider(scrollContent, "Font Size", 1, 100, 1, 322, -24, 270,
        function() return db.fontSize or 25 end,
        function(v) db.fontSize = v; ApplyDisplaySettings() end,
        nil)

    local fontDDLabel = displayBox:CreateFontString(nil, "OVERLAY")
    fontDDLabel:SetPoint("TOPLEFT", 322, -92)
    SetUIFont(fontDDLabel, 12)
    fontDDLabel:SetText("Alert Font")
    fontDDLabel:SetTextColor(1, 1, 1)

    local fontPool = {}
    local fontDD = CreateFrame("DropdownButton", "NemPetAlertsFontDrop",
                               displayBox, "WowStyle1DropdownTemplate")
    fontDD:SetPoint("TOPLEFT", 322, -108)
    fontDD:SetWidth(220)
    fontDD:SetDefaultText(db.fontName or "Gotham Narrow Ultra")
    NPA.fontDropdown = fontDD

    local function BuildFontMenu()
        local fonts = {}
        for name, path in pairs(BUNDLED_FONTS) do fonts[name] = path end
        if LSM then
            local lsmFonts = LSM:HashTable(LSM.MediaType and LSM.MediaType.FONT or "font")
            if lsmFonts then
                for fontName, fontPath in pairs(lsmFonts) do
                    if not fonts[fontName] and not EXCLUDED_LSM_FONTS[fontName] then
                        fonts[fontName] = fontPath:gsub("/", "\\")
                    end
                end
            end
        end
        local sortedNames = {}
        for name in pairs(fonts) do sortedNames[#sortedNames + 1] = name end
        table.sort(sortedNames)
        fontDD:SetupMenu(function(_, rootDescription)
            rootDescription:SetScrollMode(12 * 16)
            for index, fontName in ipairs(sortedNames) do
                local fontPath = fonts[fontName]
                local n = fontName
                local button = rootDescription:CreateButton(
                    "                                        ",
                    function()
                        db.fontName = n
                        fontDD:SetDefaultText(n)
                        ApplyDisplaySettings()
                    end)
                button:AddInitializer(function(btn)
                    local fd = fontPool[index]
                    if not fd then
                        fd = fontDD:CreateFontString(nil, "BACKGROUND")
                        fontPool[index] = fd
                    end
                    fd:SetParent(btn)
                    fd:ClearAllPoints()
                    fd:SetPoint("LEFT", btn, "LEFT", 5, 0)
                    fd:SetFont(fontPath, 12)
                    fd:SetText(n)
                    fd:Show()
                end)
            end
        end)
    end
    hooksecurefunc(fontDD, "OnMenuClosed", function()
        for _, fs2 in pairs(fontPool) do fs2:Hide() end
    end)
    C_Timer.After(0, BuildFontMenu)
    fontDD.Refresh = function()
        fontDD:SetDefaultText(db.fontName or "Gotham Narrow Ultra")
        BuildFontMenu()
    end

    -- ============================================================
    -- Sounds
    -- ============================================================
    local soundBox = SectionBox(0, -163, CPW, 130)
    SectionHeader(soundBox, "Sounds", 8, -6)

    -- ============================================================
    -- Alerts
    -- ============================================================
    local alertBox = SectionBox(0, -301, CPW, 161)
    SectionHeader(alertBox, "Alerts", 8, -6)

    local alertCheckboxes = {}

    -- ============================================================
    -- Alert Options
    -- ============================================================
    local alertOptionsBox = SectionBox(0, -470, CPW, 100)
    SectionHeader(alertOptionsBox, "Alert Options", 8, -6)

    local alertOptionsWidgets = {}

    -- ============================================================
    -- Buttons
    -- ============================================================
    local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testBtn:SetSize(125, 26)
    testBtn:SetText("Test")
    testBtn:SetScript("OnClick", function() NPA:ToggleTest() end)
    NPA.testBtn = testBtn

    local lockBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    lockBtn:SetSize(125, 26)
    lockBtn:SetText("Unlock Frame")
    lockBtn:SetScript("OnClick", function()
        SetLockState(not coreState.unlocked)
    end)
    NPA.lockBtn = lockBtn

    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(125, 26)
    resetBtn:SetText("Center Position")
    resetBtn:SetScript("OnClick", function()
        db.x             = CORE_DEFAULTS.x
        db.y             = CORE_DEFAULTS.y
        db.point         = CORE_DEFAULTS.point
        db.relativePoint = CORE_DEFAULTS.relativePoint
        db.relativeTo    = CORE_DEFAULTS.relativeTo
        ApplyDisplaySettings()
        Msg("Position centered.")
    end)

    local restoreBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    restoreBtn:SetSize(125, 26)
    restoreBtn:SetText("Restore Defaults")
    restoreBtn:SetScript("OnClick", function()
        local mod = NPA.activeModule

        -- Globals (display + frame position)
        db.fontSize      = CORE_DEFAULTS.fontSize
        db.fontName      = CORE_DEFAULTS.fontName
        db.x             = CORE_DEFAULTS.x
        db.y             = CORE_DEFAULTS.y
        db.point         = CORE_DEFAULTS.point
        db.relativePoint = CORE_DEFAULTS.relativePoint
        db.relativeTo    = CORE_DEFAULTS.relativeTo

        -- Factory-reset the active spec's per-alert keys in the flat table:
        -- toggles, sound enables/names, and custom text for every alert this
        -- spec defines, then re-seed from mod.defaults + alert defaultColors.
        if mod and mod.alerts then
            for _, alert in ipairs(mod.alerts) do
                local k = alert.key
                db[k .. "Enabled"]      = nil
                db[k .. "SoundEnabled"] = nil
                db[k .. "SoundName"]    = nil
                db[k .. "AlertText"]    = nil
            end
            if mod.defaults then
                MergeDefaults(NPA.db, mod.defaults)
            end
            NPA.db.healPetSoundEnabled = false
            NPA.db.healPetThreshold    = CORE_DEFAULTS.healPetThreshold
            NPA.db.alertColors = NPA.db.alertColors or {}
            for _, alert in ipairs(mod.alerts) do
                NPA.db.alertColors[alert.key] = CopyTable(alert.defaultColor
                    or { r=1, g=1, b=1 })
            end
        end

        NPA.ResetHealthCurve()
        ApplyDisplaySettings()
        if panel:IsShown() then panel:Hide(); panel:Show() end
        Msg("Defaults restored.")
    end)
    NPA.restoreBtn = restoreBtn

    local btnSpacing = 10
    local btnW       = 125
    local totalBtnW  = (btnW * 4) + (btnSpacing * 3)
    local btnStartX  = math_floor((PW - totalBtnW) / 2) - 8
    testBtn:SetPoint("TOPLEFT",  btnStartX, -553)
    lockBtn:SetPoint("LEFT",    testBtn,    "RIGHT", btnSpacing, 0)
    resetBtn:SetPoint("LEFT",   lockBtn,    "RIGHT", btnSpacing, 0)
    restoreBtn:SetPoint("LEFT", resetBtn,   "RIGHT", btnSpacing, 0)

    -- ============================================================
    -- Content Area Background
    -- ============================================================
    local contentBG = CreateFrame("Frame", nil, panel,
        BackdropTemplateMixin and "BackdropTemplate" or nil)
    contentBG:SetPoint("TOPLEFT",     panel, "TOPLEFT",     0, SCROLL_TOP)
    contentBG:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, SCROLL_BTM)
    contentBG:SetFrameLevel(panel:GetFrameLevel() + 1)
    if contentBG.SetBackdrop then
        contentBG:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        contentBG:SetBackdropColor(0, 0, 0, 1)
    end

    -- ============================================================
    -- Initial State
    -- ============================================================
    subtitle:Hide()
    viewport:Hide(); sbBar:Hide()
    displayBox:Hide()
    soundBox:Hide()
    alertBox:Hide()
    alertOptionsBox:Hide()
    testBtn:Hide()
    lockBtn:Hide()
    resetBtn:Hide()
    restoreBtn:Hide()
    for _, cb in pairs(checkboxes) do cb:Hide() end
    for _, sl in pairs(sliders) do sl:Hide() end

    -- ============================================================
    -- Unsupported Spec Text
    -- ============================================================
    local unsupportedHeader = contentBG:CreateFontString(nil, "OVERLAY")
    unsupportedHeader:SetPoint("CENTER", contentBG, "CENTER", 0, 12)
    SetUIFont(unsupportedHeader, 18, "OUTLINE")
    unsupportedHeader:SetText("Spec Not Supported")
    unsupportedHeader:SetTextColor(0, 0.8, 1.0)

    local unsupportedSub = contentBG:CreateFontString(nil, "OVERLAY")
    unsupportedSub:SetPoint("TOP", unsupportedHeader, "BOTTOM", 0, -8)
    unsupportedSub:SetWidth(PW - 32)
    unsupportedSub:SetJustifyH("CENTER")
    SetUIFont(unsupportedSub, 11)
    unsupportedSub:SetText("Only Pet Specs Supported")
    unsupportedSub:SetTextColor(0, 0.8, 1.0)

    -- ============================================================
    -- Version Footer
    -- ============================================================
    local version = panel:CreateFontString(nil, "OVERLAY")
    version:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 8)
    SetUIFont(version, 10)
    version:SetText(NPA_VERSION)
    version:SetTextColor(THEME_R, THEME_G, THEME_B, 0.6)
    themeFS[#themeFS + 1] = { fs=version, alpha=0.6 }

    -- ============================================================
    -- OnShow
    -- ============================================================

    local function HideAllContent()
        subtitle:Hide()
        viewport:Hide(); sbBar:Hide()
        displayBox:Hide()
        soundBox:Hide()
        alertBox:Hide()
        alertOptionsBox:Hide()
        testBtn:Hide()
        lockBtn:Hide()
        resetBtn:Hide()
        restoreBtn:Hide()
        for _, cb in pairs(checkboxes) do cb:Hide() end
        for _, sl in pairs(sliders) do sl:Hide() end
        for _, cb in pairs(soundCheckboxes) do cb:Hide() end
        for _, dd in pairs(soundDDs) do dd:Hide() end
        for _, cb in pairs(alertCheckboxes) do cb:Hide() end
        for _, w in ipairs(alertOptionsWidgets) do if w.Hide then w:Hide() end end
        contentBG:Show()
    end

    local function ShowAllContent()
        subtitle:Show()
        viewport:Show()
        sbBar:Show()
        displayBox:Show()
        soundBox:Show()
        alertBox:Show()
        alertOptionsBox:Show()
        testBtn:Show()
        lockBtn:Show()
        resetBtn:Show()
        restoreBtn:Show()
        for _, cb in pairs(checkboxes) do cb:Show() end
        for _, sl in pairs(sliders) do sl:Show() end
        contentBG:Hide()
    end

    panel:SetScript("OnShow", function()
        UpdatePanelTheme()

        if not IsFullyImplemented() then
            HideAllContent()
            return
        end

        ShowAllContent()

        local mod = NPA.activeModule
        if not mod then return end

        -- ============================================================
        -- Rebuild Sound Rows
        -- ============================================================
        for _, cb in pairs(soundCheckboxes) do cb:Hide() end
        for _, dd in pairs(soundDDs) do dd:Hide() end
        wipe(soundCheckboxes)
        wipe(soundDDs)

        local soundRowCount = 0
        for _, alert in ipairs(mod.alerts) do
            if alert.defaultSound and not alert.noSound then
                soundRowCount = soundRowCount + 1
                local k = alert.key
                local y = -28 - (soundRowCount - 1) * 40
                local cbS, ddS = MakeSoundRow(soundBox,
                    alert.soundLabel or alert.label, y,
                    function() return db[k .. "SoundEnabled"] end,
                    function(v) db[k .. "SoundEnabled"] = v end,
                    function() return ClassAwareSoundName(k) end,
                    function(v) db[k .. "SoundName"] = v end)
                soundCheckboxes[k] = cbS
                soundDDs[k]        = ddS
            end
        end

        local soundBoxH = math_max(soundRowCount, 1) * 40 + 36
        soundBox:SetHeight(soundBoxH)

        local soundBoxY = -163
        local alertBoxY = soundBoxY - soundBoxH - 8
        alertBox:ClearAllPoints()
        alertBox:SetPoint("TOPLEFT", 0, alertBoxY)

        -- ============================================================
        -- Rebuild Alert Rows
        -- ============================================================
        for _, cb in pairs(alertCheckboxes) do cb:Hide() end
        wipe(alertCheckboxes)

        for i, alert in ipairs(mod.alerts) do
            local k     = alert.key
            local col   = (i - 1) % 2
            local row   = math_floor((i - 1) / 2)
            local xPos  = col == 0 and 8 or 318
            local yPos  = alertBoxY - 30 - row * 28
            alertCheckboxes[k] = MakeAlertRow(scrollContent,
                alert.label, xPos, yPos,
                function() return db[k .. "Enabled"] end,
                function(v) db[k .. "Enabled"] = v end,
                k)
        end

        local alertRows  = math_floor((#mod.alerts + 1) / 2)
        local alertBoxH  = 30 + alertRows * 28 + 12
        alertBox:SetHeight(alertBoxH)

        local alertOptionsY = alertBoxY - alertBoxH - 8
        alertOptionsBox:ClearAllPoints()
        alertOptionsBox:SetPoint("TOPLEFT", 0, alertOptionsY)

        -- ============================================================
        -- Rebuild Alert Options Section
        -- ============================================================
        for _, w in ipairs(alertOptionsWidgets) do if w.Hide then w:Hide() end end
        wipe(alertOptionsWidgets)

        local AO_SPEC_TO_TEXT_GAP = 10
        local specCursorY = -30

        local SPEC_ROW_H = 26
        local specHelpers = {
            alertOptionsBox = alertOptionsBox,
            db              = db,
        }

        function specHelpers:MakeCheckbox(label, getter, setter)
            local cb = CreateFrame("CheckButton", nil, alertOptionsBox, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 10, specCursorY)
            cb:SetChecked(getter())
            cb:SetScript("OnClick", function(self) setter(self:GetChecked()); Evaluate() end)
            local lbl = cb:CreateFontString(nil, "OVERLAY")
            lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
            SetUIFont(lbl, 12)
            lbl:SetText(label)
            lbl:SetTextColor(1, 1, 1)
            alertOptionsWidgets[#alertOptionsWidgets + 1] = cb
            specCursorY = specCursorY - SPEC_ROW_H
            return cb
        end

        function specHelpers:MakeCheckboxAt(label, xOff, getter, setter)
            local cb = CreateFrame("CheckButton", nil, alertOptionsBox, "UICheckButtonTemplate")
            cb:SetPoint("TOPLEFT", xOff, specCursorY + SPEC_ROW_H)
            cb:SetChecked(getter())
            cb:SetScript("OnClick", function(self) setter(self:GetChecked()); Evaluate() end)
            local lbl = cb:CreateFontString(nil, "OVERLAY")
            lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
            SetUIFont(lbl, 12)
            lbl:SetText(label)
            lbl:SetTextColor(1, 1, 1)
            alertOptionsWidgets[#alertOptionsWidgets + 1] = cb
            return cb
        end

        function specHelpers:MakeCheckboxRow(label1, get1, set1, label2, get2, set2)
            self:MakeCheckbox(label1, get1, set1)
            self:MakeCheckboxAt(label2, 200, get2, set2)
        end

        function specHelpers:MakeNumericInput(label, minV, maxV, getter, setter)
            local lbl = alertOptionsBox:CreateFontString(nil, "OVERLAY")
            lbl:SetPoint("TOPLEFT", 10, specCursorY - 4)
            SetUIFont(lbl, 12)
            lbl:SetText(label)
            lbl:SetTextColor(1, 1, 1)
            alertOptionsWidgets[#alertOptionsWidgets + 1] = lbl

            local box = CreateFrame("EditBox", nil, alertOptionsBox, "InputBoxTemplate")
            box:SetPoint("LEFT", lbl, "RIGHT", 8, 0)
            box:SetSize(40, 18)
            box:SetAutoFocus(false)
            box:SetMaxLetters(4)
            box:SetFontObject("GameFontWhite")
            box:SetJustifyH("CENTER")
            box:SetText(tostring(getter()))
            box:SetCursorPosition(0)
            box:SetTextColor(THEME_R, THEME_G, THEME_B)
            themeFS[#themeFS + 1] = { setColor = function(r, g, b) box:SetTextColor(r, g, b) end }
            local function Commit()
                local v = tonumber(box:GetText())
                if v then
                    v = math_max(minV, math_min(maxV, math_floor(v + 0.5)))
                    setter(v)
                end
                box:SetText(tostring(getter()))
                box:SetCursorPosition(0)
                box:ClearFocus()
            end
            box:SetScript("OnEnterPressed",  Commit)
            box:SetScript("OnEditFocusLost", Commit)
            box:SetScript("OnEscapePressed", function(self)
                self:SetText(tostring(getter()))
                self:SetCursorPosition(0)
                self:ClearFocus()
            end)
            alertOptionsWidgets[#alertOptionsWidgets + 1] = box

            specCursorY = specCursorY - 28
            return box
        end

        function specHelpers:MakeCheckboxWithNumeric(label1, get1, set1, label2, get2, set2,
                                                     numLabel, numMin, numMax, numGetter, numSetter)
            local rowY = specCursorY
            self:MakeCheckbox(label1, get1, set1)
            self:MakeCheckboxAt(label2, 200, get2, set2)

            local numLbl = alertOptionsBox:CreateFontString(nil, "OVERLAY")
            numLbl:SetPoint("TOPLEFT", 325, rowY - 4)
            SetUIFont(numLbl, 12)
            numLbl:SetText(numLabel)
            numLbl:SetTextColor(1, 1, 1)
            alertOptionsWidgets[#alertOptionsWidgets + 1] = numLbl

            local box = CreateFrame("EditBox", nil, alertOptionsBox, "InputBoxTemplate")
            box:SetPoint("LEFT", numLbl, "RIGHT", 8, 0)
            box:SetSize(40, 18)
            box:SetAutoFocus(false)
            box:SetMaxLetters(4)
            box:SetFontObject("GameFontWhite")
            box:SetJustifyH("CENTER")
            box:SetText(tostring(numGetter()))
            box:SetCursorPosition(0)
            box:SetTextColor(THEME_R, THEME_G, THEME_B)
            themeFS[#themeFS + 1] = { setColor = function(r, g, b) box:SetTextColor(r, g, b) end }
            local function Commit()
                local v = tonumber(box:GetText())
                if v then
                    v = math_max(numMin, math_min(numMax, math_floor(v + 0.5)))
                    numSetter(v)
                end
                box:SetText(tostring(numGetter()))
                box:SetCursorPosition(0)
                box:ClearFocus()
            end
            box:SetScript("OnEnterPressed",  Commit)
            box:SetScript("OnEditFocusLost", Commit)
            box:SetScript("OnEscapePressed", function(self)
                self:SetText(tostring(numGetter()))
                self:SetCursorPosition(0)
                self:ClearFocus()
            end)
            alertOptionsWidgets[#alertOptionsWidgets + 1] = box
        end

        function specHelpers:Spacer(px)
            specCursorY = specCursorY - (px or 8)
        end

        if mod.BuildAlertOptions then
            mod:BuildAlertOptions(alertOptionsBox, db, specHelpers)
        end

        local specOptionsH = (-30) - specCursorY

        local textEditorTopY = specCursorY - AO_SPEC_TO_TEXT_GAP
        local halfW = math_floor(CPW / 2) - 24
        local colR  = math_floor(CPW / 2) + 6
        local rowH  = 44

        for i, alert in ipairs(mod.alerts) do
            local k      = alert.key
            local colIdx = (i - 1) % 2
            local rowIdx = math_floor((i - 1) / 2)
            local xPos   = colIdx == 0 and 17 or colR
            local yPos   = textEditorTopY - rowIdx * rowH

            local lbl = alertOptionsBox:CreateFontString(nil, "OVERLAY")
            lbl:SetPoint("TOPLEFT", xPos, yPos)
            SetUIFont(lbl, 11)
            lbl:SetText(alert.label)
            lbl:SetTextColor(0.8, 0.8, 0.8)
            alertOptionsWidgets[#alertOptionsWidgets + 1] = lbl

            local editBox = CreateFrame("EditBox", nil, alertOptionsBox, "InputBoxTemplate")
            editBox:SetPoint("TOPLEFT", xPos, yPos - 16)
            editBox:SetSize(halfW, 20)
            editBox:SetAutoFocus(false)
            editBox:SetMaxLetters(80)
            editBox:SetFontObject("GameFontWhite")
            local saved = db[k .. "AlertText"]
            editBox:SetText((saved and saved ~= "") and saved or alert.text)
            editBox:SetCursorPosition(0)
            editBox:SetTextColor(THEME_R, THEME_G, THEME_B)
            themeFS[#themeFS + 1] = { setColor = function(r, g, b) editBox:SetTextColor(r, g, b) end }
            editBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
            editBox:SetScript("OnEditFocusLost", function(self)
                local t = self:GetText()
                if t == "" or t == alert.text then
                    db[k .. "AlertText"] = nil
                    self:SetText(alert.text)
                else
                    db[k .. "AlertText"] = t
                end
                self:SetCursorPosition(0)
                ApplyDisplaySettings()
            end)
            editBox.Refresh = function()
                local st = db[k .. "AlertText"]
                editBox:SetText((st and st ~= "") and st or alert.text)
                editBox:SetCursorPosition(0)
            end
            alertOptionsWidgets[#alertOptionsWidgets + 1] = editBox
        end

        local textEditorRows = math_floor((#mod.alerts + 1) / 2)
        local textEditorsH   = textEditorRows * rowH
        local aoH            = 30 + specOptionsH + AO_SPEC_TO_TEXT_GAP + textEditorsH + 12
        alertOptionsBox:SetHeight(aoH)

        local contentH = (-alertOptionsY) + aoH
        SetContentHeight(contentH)

        for _, cb in pairs(checkboxes) do cb:Refresh() end
        for _, sl in pairs(sliders) do sl.Refresh() end
        if NPA.fontDropdown then NPA.fontDropdown.Refresh() end
        lockBtn:SetText(coreState.unlocked and "Lock Frame" or "Unlock Frame")
        testBtn:SetText(coreState.testMode and "Stop Test" or "Test")
    end)

    panel:SetScript("OnSizeChanged", function()
        C_Timer.After(0, function() sbBar:UpdateScrollbar() end)
    end)

    -- ============================================================
    -- Register
    -- ============================================================
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        NPA.optionsCategoryID = category:GetID()
    end

    if SettingsPanel then
        SettingsPanel:HookScript("OnHide", function()
            if NPA._panelWasOpen then
                NPA._panelWasOpen = false
                C_Timer.After(0, function()
                    if GameMenuFrame and GameMenuFrame:IsShown() then
                        HideUIPanel(GameMenuFrame)
                    end
                end)
            end
        end)
    end
end

-- ============================================================
-- PLAYER_LOGIN
-- ============================================================
function NPA:OnLogin()
    if not self.db then self:InitDatabase() end
    activeClass = GetActiveClass()

    CreateDisplay()
    self:BuildOptionsPanel()
    self:InitCommands()

    local key, mod = FindActiveModule()
    if key and mod then
        ActivateModule(key, mod)
    end
    ApplyDisplaySettings()
end

-- ============================================================
-- Event Handler
-- ============================================================
NPA:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        voice.combatStart     = GetTime()
        voice.combatStartUsed = false
    end

    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == ADDON_NAME then
            self:InitDatabase()
        end
        return
    end

    if event == "PLAYER_LOGIN" then
        self:OnLogin()
        return
    end

    local mod = self.activeModule
    local db  = self.db

    if event == "PLAYER_SPECIALIZATION_CHANGED"
    or event == "PLAYER_TALENT_UPDATE"
    or event == "TRAIT_CONFIG_UPDATED" then
        local newKey, newMod = FindActiveModule()
        if newKey ~= self.activeModuleKey then
            if newKey and newMod then
                ActivateModule(newKey, newMod)
            else
                DeactivateCurrentModule()
                if self.display then
                    SetDisplaySlot(nil)
                end
            end
        else
            if mod and mod.OnEvent then
                mod:OnEvent(db, event, ...)
            end
        end
        ScheduleEvaluate()
        return
    end

    if not mod then return end

    if event == "PLAYER_ENTERING_WORLD" then
        ApplyDisplaySettings()
        if mod.OnEvent then mod:OnEvent(db, event, ...) end
        ScheduleEvaluate()
        return
    end

    if mod.OnEvent then
        local handled = mod:OnEvent(db, event, ...)
        if not handled then
            ScheduleEvaluate()
        end
    else
        ScheduleEvaluate()
    end
end)

-- ============================================================
-- Core Event Registration
-- ============================================================
NPA:RegisterEvent("ADDON_LOADED")
NPA:RegisterEvent("PLAYER_LOGIN")
NPA:RegisterEvent("PLAYER_ENTERING_WORLD")
NPA:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
NPA:RegisterEvent("PLAYER_TALENT_UPDATE")
NPA:RegisterEvent("TRAIT_CONFIG_UPDATED")
NPA:RegisterEvent("PLAYER_UPDATE_RESTING")
NPA:RegisterEvent("PLAYER_REGEN_DISABLED")
NPA:RegisterEvent("PLAYER_REGEN_ENABLED")
NPA:RegisterUnitEvent("UNIT_TARGET", "pet")

