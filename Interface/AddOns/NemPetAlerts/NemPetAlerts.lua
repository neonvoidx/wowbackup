-- =============================================================
-- NemPetAlerts.lua  v12.0.16
-- Nem: Pet Alerts — Pet status warnings for Hunter, Warlock,
-- Frost Mage, and Unholy Death Knight.
-- Part of the Nem addon suite.  Per-spec modular architecture.
--
-- This file is the CORE ENGINE. It contains:
--   • Spec module registration system
--   • Display construction & layout
--   • Options panel builder (driven by spec module definitions)
--   • Event routing to the active spec module
--   • Spec hot-swap on PLAYER_SPECIALIZATION_CHANGED
--   • Pet health ColorCurve infrastructure
--   • Shared pet utilities (CC, passive, not-attacking, mount suppression)
--   • Sound playback, font/sound asset management
--   • Slash commands, lock/unlock, test mode
--
-- It contains ZERO class-specific spell IDs, aura logic, or
-- priority functions. All spec behavior lives in Specs/*.lua
-- files which register themselves via NPA:RegisterSpec().
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
-- =============================================================

local ADDON_NAME = ...
local NPA = CreateFrame("Frame")
_G.NemPetAlerts = NPA

-- =============================================================
-- Upvalues
-- =============================================================
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

local NPA_VERSION = "v12.0.17"

-- =============================================================
-- Asset Paths  (all self-contained under NemPetAlerts\)
-- =============================================================
local NPA_FONTS  = "Interface\\AddOns\\NemPetAlerts\\Fonts\\"
local NPA_MEDIA  = "Interface\\AddOns\\NemPetAlerts\\Media\\"

local ALERT_FONT = NPA_FONTS .. "GothamNarrow-Ultra.ttf"
local UI_FONT    = NPA_FONTS .. "Prototype.ttf"

-- Expose to spec modules
NPA.FONTS_PATH = NPA_FONTS
NPA.MEDIA_PATH = NPA_MEDIA
NPA.UI_FONT    = UI_FONT

-- =============================================================
-- Class Detection  (cached at PLAYER_LOGIN)
-- =============================================================
local activeClass = nil

local function GetActiveClass()
    local _, class = UnitClass("player")
    return class
end

-- Spec support is determined entirely by registered spec modules.
-- If no module matches the player's class + specID, the panel
-- shows a "Spec Not Supported" message.

local function IsFullyImplemented()
    return NPA.activeModule ~= nil
end

-- =============================================================
-- Spec Module Registry
-- =============================================================
-- Modules register via NPA:RegisterSpec(key, module)
-- key format: "ClassSpec" e.g. "HunterBeastMastery", "WarlockAffliction"
--
-- Module table contract (all functions are optional unless noted):
-- {
--   class        = "CLASS",                    -- REQUIRED: WoW class token
--   specID       = 253,                        -- REQUIRED: WoW specialization ID
--   specName     = "Beast Mastery Hunter",     -- display name
--
--   -- Alert definitions: ordered list of alerts this spec provides.
--   -- Each entry drives display rows, options checkboxes, sound rows,
--   -- color swatches, and test mode — automatically.
--   alerts = {
--     {
--       key          = "petDead",              -- unique key, used in db and state
--       label        = "Pet Died",             -- display name in options
--       text         = "* PET DIED *",         -- alert text shown on screen
--       defaultColor = { r=1, g=0.2, b=0.15 },
--       yOffset      = 52,                     -- Y offset for alert text row
--       defaultSound = "OhNo",                 -- default sound name (nil = no sound row)
--       soundLabel   = "Pet Died",             -- label for sound row (defaults to label)
--     },
--     ...
--   },
--
--   -- Test mode slots: which alert indices to show in test mode.
--   -- e.g. { [1]=true, [2]=true, [3]=true, [5]=true, [6]=true }
--   testSlots = { ... },
--
--   -- Defaults merged into saved variables
--   defaults = { ... },
--
--   -- State table (module owns this entirely)
--   state = { ... },
--
--   -- REQUIRED: Returns the ALERT index (1-based) of the highest
--   -- priority active alert, or nil if none.
--   GetHighestPriorityAlert = function(self, db) end,
--
--   -- Called once at login when this spec is active.
--   OnActivate = function(self, db) end,
--
--   -- Called when switching away from this spec module.
--   OnDeactivate = function(self, db) end,
--
--   -- Event handler: receives (self, db, event, ...).
--   -- Return true to suppress the core's default ScheduleEvaluate.
--   OnEvent = function(self, db, event, ...) end,
--
--   -- Called every Evaluate cycle before GetHighestPriorityAlert.
--   -- Module should update its state here (sound triggers, etc.)
--   PreEvaluate = function(self, db) end,
--
--   -- Called to fully reset all runtime state.
--   ClearAllState = function(self) end,
--
--   -- Additional events this spec needs beyond the core set.
--   extraEvents = { ... },
--
--   -- Additional unit events: { { event, unit1, unit2 }, ... }
--   extraUnitEvents = { ... },
--
--   -- Whether the addon should run (spec/talent checks).
--   -- Core calls this to decide if alerts are active.
--   ShouldRun = function(self, db) end,
--
--   -- Heal Pet threshold: if true, the module uses the health curve system.
--   hasHealPet = true,
--
--   -- The alert index for the heal pet slot (for ColorCurve alpha).
--   healPetAlertIndex = 6,
--
--   -- Slash command extensions: { ["cmd"] = function(self, db) end, ... }
--   slashCommands = {},
-- }

NPA.specModules     = {}       -- key → module table
NPA.activeModule    = nil      -- currently active module (or nil)
NPA.activeModuleKey = nil      -- key string of active module

function NPA:RegisterSpec(key, mod)
    self.specModules[key] = mod
end

-- Find the module for the current specialization.
local function FindActiveModule()
    if not activeClass then return nil, nil end
    local currentSpecID = NPA.GetSpecID()
    if not currentSpecID then return nil, nil end
    for key, mod in pairs(NPA.specModules) do
        if mod.class == activeClass and mod.specID == currentSpecID then
            return key, mod
        end
    end
    return nil, nil
end

-- =============================================================
-- Class theme colors (used for panel borders, headers, accents)
-- =============================================================
local CLASS_THEME_COLORS = {
    HUNTER      = { r=0.6667, g=0.8275, b=0.4471 },  -- #AAD372
    WARLOCK     = { r=0.5294, g=0.5333, b=0.9333 },  -- #8788EE
    MAGE        = { r=0.2471, g=0.7804, b=0.9216 },  -- #3FC7EB
    DEATHKNIGHT = { r=0.7686, g=0.1176, b=0.2275 },  -- #C41E3A
}
local CLASS_THEME_DEFAULT = { r=0, g=0.8, b=1.0 }  -- #00CCFF (unsupported class)

local function GetClassTheme()
    local cls = activeClass
    if not cls and UnitClass then
        local _, c = UnitClass("player")
        cls = c
    end
    local col = CLASS_THEME_COLORS[cls] or CLASS_THEME_DEFAULT
    return col.r, col.g, col.b
end

-- =============================================================
-- LibSharedMedia (optional — enhances font/sound dropdowns)
-- =============================================================
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- =============================================================
-- Sounds
-- =============================================================
local BUNDLED_SOUNDS = {
    ["Bell"]            = NPA_MEDIA .. "Bell.ogg",
    ["Bleeper"]         = NPA_MEDIA .. "Bleeper.ogg",
    ["Drums"]           = NPA_MEDIA .. "Drums.ogg",
    ["HeartbeatSingle"] = NPA_MEDIA .. "HeartbeatSingle.ogg",
    ["Lamp"]            = NPA_MEDIA .. "Lamp.ogg",
    ["MetalGearSpotted"]= NPA_MEDIA .. "MetalGearSpotted.ogg",
    ["OhNo"]            = NPA_MEDIA .. "OhNo.ogg",
    ["Ping"]            = NPA_MEDIA .. "Ping.ogg",
    ["Redfox"]          = NPA_MEDIA .. "Redfox.ogg",
    ["RobotBlip"]       = NPA_MEDIA .. "RobotBlip.ogg",
    ["SharpPunch"]      = NPA_MEDIA .. "SharpPunch.ogg",
    ["Shotgun"]         = NPA_MEDIA .. "Shotgun.ogg",
    ["Sonar"]           = NPA_MEDIA .. "Sonar.ogg",
    ["Sonarr"]          = NPA_MEDIA .. "Sonarr.ogg",
    ["WaterDrop"]       = NPA_MEDIA .. "WaterDrop.ogg",
}

if LSM then
    for name, path in pairs(BUNDLED_SOUNDS) do
        LSM:Register("sound", name, path)
    end
end

local function GetSoundPath(name)
    if not name then return BUNDLED_SOUNDS["RobotBlip"] end
    if BUNDLED_SOUNDS[name] then return BUNDLED_SOUNDS[name] end
    if LSM then
        local path = LSM:Fetch("sound", name)
        if path then return path:gsub("/", "\\") end
    end
    return BUNDLED_SOUNDS["RobotBlip"]
end

-- Sorted sound list for dropdowns
local SOUND_NAMES = {}
do
    for k in pairs(BUNDLED_SOUNDS) do SOUND_NAMES[#SOUND_NAMES+1] = k end
    table.sort(SOUND_NAMES)
end

-- Expose for spec modules
NPA.GetSoundPath = GetSoundPath
NPA.SOUND_NAMES  = SOUND_NAMES

-- =============================================================
-- Fonts
-- =============================================================
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

local function GetCurrentFontPath()
    local name = NemPetAlertsSV and NemPetAlertsSV.fontName or "Gotham Narrow Ultra"
    if BUNDLED_FONTS[name] then return BUNDLED_FONTS[name] end
    if LSM then
        local path = LSM:Fetch("font", name)
        if path then return path:gsub("/", "\\") end
    end
    return ALERT_FONT
end

local FONT_NAMES = {}
do
    for k in pairs(BUNDLED_FONTS) do FONT_NAMES[#FONT_NAMES+1] = k end
    table.sort(FONT_NAMES)
end

-- =============================================================
-- Saved-Variable Defaults (core only — module defaults merged in)
-- =============================================================
local CORE_DEFAULTS = {
    enabled       = true,
    flash         = true,
    scale         = 1.0,
    fontSize      = 25,
    fontName      = "Gotham Narrow Ultra",
    x             = 0,
    y             = 140,
    point         = "CENTER",
    relativePoint = "CENTER",
    relativeTo    = "UIParent",
    healPetThreshold = 30,
    alertColors   = {},
    ver           = 2,
}

-- =============================================================
-- Runtime State (core only)
-- =============================================================
local coreState = {
    unlocked       = false,
    testMode       = false,
    testTicker     = nil,
    currentMessage = nil,
}

-- =============================================================
-- Utility
-- =============================================================
local function MergeDefaults(dst, defaults)
    for k, v in pairs(defaults) do
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

-- Expose for spec modules
NPA.Msg            = Msg
NPA.MergeDefaults  = MergeDefaults
NPA.issecretvalue  = issecretvalue

-- =============================================================
-- Sound Playback (generic — modules provide the key)
-- =============================================================
function NPA:PlayAlertSound(alertKey)
    local db = NemPetAlertsSV
    if not db then return end
    local enabledKey = alertKey .. "SoundEnabled"
    local nameKey    = alertKey .. "SoundName"
    if not db[enabledKey] then return end
    local p = GetSoundPath(db[nameKey])
    if p then PlaySoundFile(p, "Master") end
end

-- =============================================================
-- Shared Pet Utilities  (used by all spec modules)
-- =============================================================
function NPA.PetExists()
    return UnitExists("pet")
end

function NPA.PetAlive()
    if not UnitExists("pet") then return false end
    return not UnitIsDead("pet")
end

function NPA.ShouldSuppressNoPet()
    local mounted = IsMounted()
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

-- =============================================================
-- CC Detection  (shared across all spec modules)
-- =============================================================
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

-- =============================================================
-- Passive Detection  (shared across all spec modules)
-- =============================================================
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

-- =============================================================
-- Pet Not Attacking Detection  (shared across all spec modules)
-- =============================================================
local PET_NOT_ATTACKING_GRACE = 3  -- seconds before warning appears

local petCombatDetector = nil
local function GetPetCombatDetector()
    if not petCombatDetector then
        local bar = CreateFrame("StatusBar", "NPA_PetCombatDetector", UIParent)
        bar:SetSize(2, 2)
        bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -200, 200)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetStatusBarColor(1, 1, 1, 1)
        bar:SetAlpha(0)
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

-- Shared not-attacking state (owned by core, read/written by modules)
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

-- =============================================================
-- Taunt Group Condition  (shared by Hunter and Warlock specs)
-- =============================================================
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

-- =============================================================
-- Pet Health Warning  (ColorCurve pipeline for secret values)
-- =============================================================
local HEAL_PET_THRESHOLD = 30
local petHealthCurve
local petHealthCurveThreshold = nil

function NPA.GetPetHealthWarningAlpha()
    if not NPA.PetExists() or UnitIsDead("pet") then return nil end
    if not UnitHealthPercent or not C_CurveUtil or not C_CurveUtil.CreateColorCurve then return nil end
    local threshold = (NemPetAlertsSV and NemPetAlertsSV.healPetThreshold) or HEAL_PET_THRESHOLD
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

-- Expose curve threshold reset for options panel
function NPA.ResetHealthCurve()
    petHealthCurveThreshold = nil
end

-- =============================================================
-- Spec / Talent Helpers  (exposed for spec modules)
-- =============================================================
function NPA.GetSpecID()
    local idx = GetSpecialization()
    if not idx then return nil end
    return GetSpecializationInfo(idx)
end

function NPA.IsSpellKnownByPlayer(spellID)
    if not spellID then return false end
    if IsPlayerSpell and IsPlayerSpell(spellID) then return true end
    if IsSpellKnownOrOverridesKnown then
        return IsSpellKnownOrOverridesKnown(spellID)
    end
    return false
end

-- =============================================================
-- Forward-declare Evaluate
-- =============================================================
local Evaluate

-- =============================================================
-- Tickers
-- =============================================================
-- Pet health ticker: runs while a live pet exists for responsive
-- heal pet detection.
local petHealthTicker = nil

local function StartPetHealthTicker()
    if petHealthTicker then return end
    petHealthTicker = C_Timer.NewTicker(0.25, function()
        if not NPA.PetExists() or UnitIsDead("pet") then
            petHealthTicker:Cancel(); petHealthTicker = nil; return
        end
        Evaluate()
    end)
end

local function StopPetHealthTicker()
    if petHealthTicker then petHealthTicker:Cancel(); petHealthTicker = nil end
end

-- Expose for spec modules
NPA.StartPetHealthTicker = StartPetHealthTicker
NPA.StopPetHealthTicker  = StopPetHealthTicker

-- Module-owned tickers: modules can register/unregister their own
-- tickers via NPA.moduleTickers.  Core stops all on deactivation.
NPA.moduleTickers = {}

function NPA:StartModuleTicker(name, interval, func)
    if self.moduleTickers[name] then return end
    self.moduleTickers[name] = C_Timer.NewTicker(interval, func)
end

function NPA:StopModuleTicker(name)
    if self.moduleTickers[name] then
        self.moduleTickers[name]:Cancel()
        self.moduleTickers[name] = nil
    end
end

local function StopAllModuleTickers()
    for name, ticker in pairs(NPA.moduleTickers) do
        ticker:Cancel()
    end
    wipe(NPA.moduleTickers)
end

-- =============================================================
-- Display Frame
-- =============================================================
-- Alert rows are built dynamically from the active module's alerts[].
-- alertRows[i] = {
--   textFS  = FontString,
--   key     = "petDead",
--   alert   = { ... },  -- ref to alert def
-- }
-- Special: healPetFrame + healFlashTicker for the health-curve slot.
-- testFS is used during test mode for the healPet slot to bypass
-- the healPetFrame alpha chain.

local function CreateDisplay()
    local db = NemPetAlertsSV
    local f = CreateFrame("Frame", "NemPetAlertsFrame", UIParent,
                          BackdropTemplateMixin and "BackdropTemplate" or nil)
    f:SetSize(900, 150)
    f:SetPoint("CENTER", UIParent, "CENTER", db.x or 0, db.y or 140)
    f:SetMovable(true)
    f:EnableMouse(false)
    f:RegisterForDrag("LeftButton")

    f:SetScript("OnDragStart", function(self)
        if coreState.unlocked then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, relativeTo, relativePoint, x, y = self:GetPoint()
        NemPetAlertsSV.point         = point
        NemPetAlertsSV.relativeTo    = (relativeTo and relativeTo ~= UIParent) and relativeTo:GetName() or "UIParent"
        NemPetAlertsSV.relativePoint = relativePoint
        NemPetAlertsSV.x = math_floor(x + 0.5)
        NemPetAlertsSV.y = math_floor(y + 0.5)
    end)

    -- Flash animation
    local ag = f:CreateAnimationGroup()
    ag:SetLooping("REPEAT")
    local a1 = ag:CreateAnimation("Alpha")
    a1:SetFromAlpha(1); a1:SetToAlpha(0.15); a1:SetDuration(0.45); a1:SetOrder(1)
    local a2 = ag:CreateAnimation("Alpha")
    a2:SetFromAlpha(0.15); a2:SetToAlpha(1); a2:SetDuration(0.45); a2:SetOrder(2)

    f.flashGroup = ag
    f.alertRows  = {}

    NPA.display = f
end

-- Build alert row FontStrings from the active module's alerts[].
local function BuildAlertRows()
    local f   = NPA.display
    local db  = NemPetAlertsSV
    local mod = NPA.activeModule
    if not f or not db or not mod then return end

    -- Hide and release existing rows
    for _, row in ipairs(f.alertRows) do
        row.textFS:Hide()
    end
    wipe(f.alertRows)

    -- Clean up healPet special frames
    if f.healPetFrame then f.healPetFrame:Hide() end
    if f.healFlashTicker then f.healFlashTicker:Hide() end
    if f.testHealFS then f.testHealFS:Hide() end

    local fp = GetCurrentFontPath()
    local fs = db.fontSize or 25
    local sc = db.scale or 1.0
    local healPetIdx = mod.healPetAlertIndex

    for i, alert in ipairs(mod.alerts) do
        local col = db.alertColors and db.alertColors[alert.key]
                    or alert.defaultColor
                    or { r=1, g=1, b=1 }

        -- Heal Pet slot uses a dedicated parent frame for ColorCurve alpha
        local parent = f
        if mod.hasHealPet and i == healPetIdx then
            if not f.healPetFrame then
                local hpf = CreateFrame("Frame", nil, f)
                hpf:SetSize(900, 60)
                hpf:SetPoint("CENTER", f, "CENTER", 0, alert.yOffset or 0)
                hpf:SetAlpha(0)
                hpf:Hide()
                f.healPetFrame = hpf
            else
                f.healPetFrame:ClearAllPoints()
                f.healPetFrame:SetPoint("CENTER", f, "CENTER", 0, alert.yOffset or 0)
            end
            parent = f.healPetFrame
        end

        local textFS = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        textFS:SetFont(fp, fs, "OUTLINE")
        textFS:SetTextColor(col.r, col.g, col.b)
        textFS:SetText(alert.text)
        textFS:SetScale(sc)
        textFS:SetJustifyH("CENTER")
        textFS:SetShadowOffset(2, -2)

        if mod.hasHealPet and i == healPetIdx then
            textFS:SetPoint("CENTER", f.healPetFrame, "CENTER", 0, 0)
        else
            textFS:SetPoint("CENTER", f, "CENTER", 0, alert.yOffset or 0)
        end
        textFS:Hide()

        f.alertRows[i] = {
            textFS = textFS,
            key    = alert.key,
            alert  = alert,
        }
    end

    -- HealPet flash ticker (sine wave on alertFS alpha)
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
            if NemPetAlertsSV and NemPetAlertsSV.flash then
                healFlashT = healFlashT + dt
                local a = 0.15 + 0.85 * (0.5 + 0.5 * math_sin(healFlashT * (math_pi * 2 / 0.9)))
                ts:SetAlpha(a)
            else
                healFlashT = 0
                ts:SetAlpha(1)
            end
        end)

        -- Test mode FontString for heal pet (bypasses healPetFrame alpha chain)
        local def = mod.alerts[healPetIdx]
        local col = db.alertColors and db.alertColors[def.key]
                    or def.defaultColor or { r=1, g=1, b=1 }
        local testFS = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        testFS:SetFont(fp, fs, "OUTLINE")
        testFS:SetTextColor(col.r, col.g, col.b)
        testFS:SetText(def.text)
        testFS:SetScale(sc)
        testFS:SetJustifyH("CENTER")
        testFS:SetShadowOffset(2, -2)
        testFS:SetPoint("CENTER", f, "CENTER", 0, def.yOffset or 0)
        testFS:Hide()
        f.testHealFS = testFS
    end
end

-- =============================================================
-- ApplyDisplaySettings
-- =============================================================
local function ApplyDisplaySettings()
    local db = NemPetAlertsSV
    local f  = NPA.display
    if not f or not db then return end

    f:ClearAllPoints()
    local point        = db.point        or "CENTER"
    local relativePoint = db.relativePoint or "CENTER"
    local relativeTo   = (db.relativeTo and db.relativeTo ~= "UIParent" and _G[db.relativeTo]) or UIParent
    f:SetPoint(point, relativeTo, relativePoint, db.x or 0, db.y or 140)

    local fontPath = GetCurrentFontPath()
    local fs = db.fontSize or 25
    local sc = db.scale or 1.0

    for _, row in ipairs(f.alertRows) do
        local col = db.alertColors and db.alertColors[row.key]
                    or row.alert.defaultColor
                    or { r=1, g=1, b=1 }
        row.textFS:SetFont(fontPath, fs, "OUTLINE")
        row.textFS:SetScale(sc)
        row.textFS:SetTextColor(col.r, col.g, col.b)
    end

    if f.testHealFS then
        f.testHealFS:SetFont(fontPath, fs, "OUTLINE")
        f.testHealFS:SetScale(sc)
        local mod = NPA.activeModule
        if mod and mod.healPetAlertIndex then
            local def = mod.alerts[mod.healPetAlertIndex]
            if def then
                local col = db.alertColors and db.alertColors[def.key]
                            or def.defaultColor or { r=1, g=1, b=1 }
                f.testHealFS:SetTextColor(col.r, col.g, col.b)
            end
        end
    end

    f:EnableMouse(coreState.unlocked)
end

-- Expose for spec modules
NPA.ApplyDisplaySettings = ApplyDisplaySettings

-- =============================================================
-- SetDisplaySlot  (shows exactly one alert or clears all)
-- =============================================================
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
    elseif NemPetAlertsSV.flash then
        if not f.flashGroup:IsPlaying() then f.flashGroup:Play() end
    else
        if f.flashGroup:IsPlaying() then f.flashGroup:Stop() end
        f:SetAlpha(1)
    end
end

-- Expose for spec modules
NPA.SetDisplaySlot = SetDisplaySlot

-- =============================================================
-- PetNeedsHealing  (shared — always returns true if pet is alive;
-- actual threshold enforced by ColorCurve alpha)
-- =============================================================
function NPA.PetNeedsHealing()
    if not NPA.PetExists() or UnitIsDead("pet") then return false end
    return true
end

-- =============================================================
-- Evaluate  (core wrapper)
-- =============================================================
Evaluate = function()
    local db  = NemPetAlertsSV
    local mod = NPA.activeModule
    local f   = NPA.display
    if not f then return end

    -- Disabled check first — even test mode respects the toggle
    if not db or not db.enabled then
        SetDisplaySlot(nil)
        if coreState.testMode then
            coreState.testMode = false
            if coreState.testTicker then coreState.testTicker:Cancel(); coreState.testTicker = nil end
        end
        return
    end

    -- Test mode
    if coreState.testMode then
        if not mod then return end
        local testSlots = mod.testSlots or {}
        local healPetIdx = mod.healPetAlertIndex

        -- Use testHealFS for the heal pet slot (bypass ColorCurve chain)
        if f.testHealFS then
            if healPetIdx and testSlots[healPetIdx] then
                f.testHealFS:Show()
            else
                f.testHealFS:Hide()
            end
        end
        -- Hide real heal pet system during test
        if f.healPetFrame then
            if f.healFlashTicker then f.healFlashTicker:Hide() end
            f.healPetFrame:SetAlpha(0)
            f.healPetFrame:Hide()
        end

        -- Show/hide all other slots
        for i, row in ipairs(f.alertRows) do
            if not (mod.hasHealPet and i == healPetIdx) then
                if testSlots[i] then row.textFS:Show() else row.textFS:Hide() end
            end
        end

        coreState.currentMessage = "TEST"
        if NemPetAlertsSV.flash then
            if not f.flashGroup:IsPlaying() then f.flashGroup:Play() end
        else
            if f.flashGroup:IsPlaying() then f.flashGroup:Stop() end
            f:SetAlpha(1)
        end
        return
    end

    -- No module or module says don't run
    if not mod then SetDisplaySlot(nil); return end
    if mod.ShouldRun and not mod:ShouldRun(db) then
        SetDisplaySlot(nil); return
    end

    -- Pre-evaluate (module updates state, fires rising-edge sounds)
    if mod.PreEvaluate then mod:PreEvaluate(db) end

    -- Get the highest priority alert
    local alertIdx = mod:GetHighestPriorityAlert(db)
    SetDisplaySlot(alertIdx)

    -- Heal Pet ColorCurve alpha
    local healPetIdx = mod.healPetAlertIndex
    if mod.hasHealPet and coreState.currentMessage == healPetIdx and f.healPetFrame then
        local warningAlpha = NPA.GetPetHealthWarningAlpha()
        if warningAlpha ~= nil then
            pcall(f.healPetFrame.SetAlpha, f.healPetFrame, warningAlpha)
        else
            f.healPetFrame:SetAlpha(0)
        end
    end
end

-- Expose for spec modules
NPA.Evaluate = function() Evaluate() end

-- =============================================================
-- Module Activation / Deactivation
-- =============================================================
local registeredExtraEvents = {}

local function DeactivateCurrentModule()
    local mod = NPA.activeModule
    if not mod then return end

    if mod.OnDeactivate then mod:OnDeactivate(NemPetAlertsSV) end
    if mod.ClearAllState then mod:ClearAllState() end

    -- Unregister extra events
    for _, ev in ipairs(registeredExtraEvents) do
        NPA:UnregisterEvent(ev)
    end
    wipe(registeredExtraEvents)

    StopPetHealthTicker()
    StopAllModuleTickers()

    NPA.activeModule    = nil
    NPA.activeModuleKey = nil
end

local function ActivateModule(key, mod)
    DeactivateCurrentModule()

    NPA.activeModule    = mod
    NPA.activeModuleKey = key

    -- Merge module defaults into saved variables
    if mod.defaults then
        MergeDefaults(NemPetAlertsSV, mod.defaults)
    end

    -- Ensure alertColors exist for each alert
    NemPetAlertsSV.alertColors = NemPetAlertsSV.alertColors or {}
    for _, alert in ipairs(mod.alerts) do
        if not NemPetAlertsSV.alertColors[alert.key] then
            NemPetAlertsSV.alertColors[alert.key] = CopyTable(alert.defaultColor
                or { r=1, g=1, b=1 })
        end
    end

    -- Register extra events
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

    -- Build display rows from module alerts
    BuildAlertRows()
    ApplyDisplaySettings()

    -- Activate module
    if mod.OnActivate then mod:OnActivate(NemPetAlertsSV) end
    Evaluate()
end

-- =============================================================
-- Init: Database
-- =============================================================
function NPA:InitDatabase()
    NemPetAlertsSV = NemPetAlertsSV or CopyTable(CORE_DEFAULTS)
    local db = NemPetAlertsSV
    local wasNew = (db.ver or 0) < 2
    if wasNew then
        -- v2: modular architecture migration — reset if old monolithic format
        if db.ver == 1 then
            -- Preserve position and display settings from v1
            local saved = {
                enabled       = db.enabled,
                flash         = db.flash,
                scale         = db.scale,
                fontSize      = db.fontSize,
                fontName      = db.fontName,
                x             = db.x,
                y             = db.y,
                point         = db.point,
                relativePoint = db.relativePoint,
                relativeTo    = db.relativeTo,
                healPetThreshold = db.healPetThreshold,
            }
            -- Preserve per-alert sound settings from v1 using old key names
            local soundMigration = {
                sound            = db.sound,
                ccSoundName      = db.ccSoundName,
                petDeadSound     = db.petDeadSound,
                petDeadSoundName = db.petDeadSoundName,
            }
            -- Preserve alert enable/disable state
            local alertsMigration = db.alerts and CopyTable(db.alerts) or nil
            -- Preserve alert colors
            local colorsMigration = db.alertColors and CopyTable(db.alertColors) or nil

            NemPetAlertsSV = CopyTable(CORE_DEFAULTS)
            db = NemPetAlertsSV
            for k, v in pairs(saved) do
                if v ~= nil then db[k] = v end
            end
            -- Migrate old sound keys to new format
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
            -- Migrate alert toggles from old nested table to flat keys
            if alertsMigration then
                for alertKey, enabled in pairs(alertsMigration) do
                    db[alertKey .. "Enabled"] = enabled
                end
            end
            -- Migrate alert colors
            if colorsMigration then
                db.alertColors = colorsMigration
            end
        else
            NemPetAlertsSV = CopyTable(CORE_DEFAULTS)
            db = NemPetAlertsSV
        end
        db.ver = 2
    else
        MergeDefaults(db, CORE_DEFAULTS)
    end
end

-- =============================================================
-- Test Mode
-- =============================================================
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
    end
    if NPA.testBtn then
        NPA.testBtn:SetText(coreState.testMode and "Stop Test" or "Test")
    end
    Evaluate()
end

-- =============================================================
-- Lock / Unlock
-- =============================================================
local function SetLockState(unlocked)
    coreState.unlocked = unlocked
    ApplyDisplaySettings()
    if NPA.lockBtn then
        NPA.lockBtn:SetText(unlocked and "Lock Frame" or "Unlock Frame")
    end
    Msg(unlocked and "Frame unlocked. Drag to reposition." or "Frame locked.")
end

-- =============================================================
-- Init: Slash Commands
-- =============================================================
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

        -- Check for module-specific slash commands
        local mod = self.activeModule
        if mod and mod.slashCommands and mod.slashCommands[input] then
            mod.slashCommands[input](mod, NemPetAlertsSV)
            return
        end

        if input == "on" then
            NemPetAlertsSV.enabled = true
            Evaluate()
            Msg("Addon |cff00ff41enabled|r.")
            return
        end

        if input == "off" then
            NemPetAlertsSV.enabled = false
            SetDisplaySlot(nil)
            if NPA.display then NPA.display:SetAlpha(1) end
            coreState.testMode = false
            if coreState.testTicker then coreState.testTicker:Cancel(); coreState.testTicker = nil end
            if NPA.testBtn then NPA.testBtn:SetText("Test") end
            Evaluate()
            Msg("Addon |cffff4040disabled|r.")
            return
        end

        if input == "toggle" then
            if NemPetAlertsSV.enabled then
                NemPetAlertsSV.enabled = false
                SetDisplaySlot(nil)
                if NPA.display then NPA.display:SetAlpha(1) end
                coreState.testMode = false
                if coreState.testTicker then coreState.testTicker:Cancel(); coreState.testTicker = nil end
                if NPA.testBtn then NPA.testBtn:SetText("Test") end
                Msg("Addon |cffff4040disabled|r.")
            else
                NemPetAlertsSV.enabled = true
                Msg("Addon |cff00ff41enabled|r.")
            end
            Evaluate()
            return
        end

        if input == "test" then
            if not NemPetAlertsSV.enabled then
                Msg("Addon is disabled. Use |cffffd700/npa on|r first.")
                return
            end
            NPA:ToggleTest()
            Msg(coreState.testMode and "Test mode |cff00ff41on|r." or "Test mode |cffff4040off|r.")
            return
        end

        if input == "status" then
            local enabledStr = NemPetAlertsSV.enabled
                and "|cff00ff41Enabled|r" or "|cffff4040Disabled|r"
            local testStr = coreState.testMode
                and "|cffffff00On|r" or "Off"
            local classStr = activeClass or "Unknown"
            Msg(string_format("Status: %s  |  Test Mode: %s  |  Class: %s",
                enabledStr, testStr, classStr))
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

        -- Default: open options
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

-- =============================================================
-- Debug Command
-- =============================================================
function NPA:RunDebug()
    local db = NemPetAlertsSV
    local mod = self.activeModule
    local ok, err

    Msg("--- NemPetAlerts Debug ---")

    ok, err = pcall(function()
        Msg("class=" .. tostring(activeClass)
            .. "  module=" .. tostring(self.activeModuleKey)
            .. "  enabled=" .. tostring(db.enabled))
    end)
    if not ok then Msg("ERROR(1): " .. tostring(err)) end

    ok, err = pcall(function()
        Msg("petExists=" .. tostring(NPA.PetExists())
            .. "  petAlive=" .. tostring(NPA.PetAlive())
            .. "  petDead=" .. tostring(NPA.PetExists() and UnitIsDead("pet") or "n/a"))
    end)
    if not ok then Msg("ERROR(2): " .. tostring(err)) end

    if mod and mod.Debug then
        mod:Debug(db)
    end

    ok, err = pcall(function()
        Msg("inGroup=" .. tostring(IsInGroup())
            .. "  members=" .. tostring(GetNumGroupMembers()))
    end)
    if not ok then Msg("ERROR(3): " .. tostring(err)) end

    ok, err = pcall(function()
        Msg("CC(live)=" .. tostring(NPA.PetIsCC())
            .. "  passive=" .. tostring(NPA.PetIsPassive())
            .. "  notAttacking=" .. tostring(NPA.PetNotAttacking()))
    end)
    if not ok then Msg("ERROR(4): " .. tostring(err)) end
end

-- =============================================================
-- Options Panel
-- =============================================================
function NPA:BuildOptionsPanel()
    local db = NemPetAlertsSV
    local PW = 668

    local panel = CreateFrame("Frame", "NemPetAlertsOptionsPanel", UIParent)
    panel.name = "Nem: Pet Alerts"
    panel:SetSize(PW, 648)

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
    end

    -- ---- UI Helpers ----
    local function SectionBox(x, y, w, h)
        local box = CreateFrame("Frame", nil, panel,
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
        local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
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
                    -- Update display row color
                    local f = NPA.display
                    if f then
                        for _, row in ipairs(f.alertRows) do
                            if row.key == colorKey then
                                row.textFS:SetTextColor(nr, ng, nb)
                            end
                        end
                        -- Keep testHealFS in sync
                        local mod = NPA.activeModule
                        if mod and mod.healPetAlertIndex then
                            local hpAlert = mod.alerts[mod.healPetAlertIndex]
                            if hpAlert and hpAlert.key == colorKey and f.testHealFS then
                                f.testHealFS:SetTextColor(nr, ng, nb)
                            end
                        end
                    end
                    -- Keep threshold box in sync with healPet color
                    if NPA.healPetThreshBox then
                        local mod = NPA.activeModule
                        if mod and mod.healPetAlertIndex then
                            local hpAlert = mod.alerts[mod.healPetAlertIndex]
                            if hpAlert and hpAlert.key == colorKey then
                                NPA.healPetThreshBox:SetTextColor(nr, ng, nb)
                            end
                        end
                    end
                end

                if ColorPickerFrame.SetupColorPickerAndShow then
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
                else
                    ColorPickerFrame:SetColorRGB(cr, cg, cb2)
                    ColorPickerFrame.func = function()
                        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                        ApplyColor(nr, ng, nb)
                    end
                    ColorPickerFrame.cancelFunc = function()
                        ApplyColor(cr, cg, cb2)
                    end
                    ColorPickerFrame:Show()
                end
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
        slider.Low:SetText(tostring(minVal))
        slider.High:SetText(tostring(maxVal))
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
        dd:SetPoint("LEFT", cb, "RIGHT", 160, 0)
        dd:SetWidth(160)
        local function SetupMenu()
            dd:SetupMenu(function(_, root)
                for _, name in ipairs(SOUND_NAMES) do
                    local n = name
                    root:CreateRadio(n,
                        function() return getSound() == n end,
                        function() setSound(n); dd:SetDefaultText(n) end,
                        n)
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

    -- ================================================================
    -- TITLE
    -- ================================================================
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
    subtitle:SetText("Pet status warnings for Hunter, Warlock, Frost Mage, and Unholy Death Knight. Type /npa to open this panel.")
    subtitle:SetTextColor(0.75, 0.75, 0.75)

    -- ================================================================
    -- DISPLAY
    -- ================================================================
    local displayBox = SectionBox(12, -62, PW - 24, 175)
    SectionHeader(displayBox, "Display", 8, -6)

    checkboxes.enabled = MakeCheckbox("Enable Addon", 20, -90,
        function() return db.enabled end,
        function(v)
            db.enabled = v and true or false
            if not db.enabled then
                SetDisplaySlot(nil)
                if NPA.display then NPA.display:SetAlpha(1) end
                coreState.testMode = false
                if coreState.testTicker then coreState.testTicker:Cancel(); coreState.testTicker = nil end
                if NPA.testBtn then NPA.testBtn:SetText("Test") end
            end
        end)

    checkboxes.flash = MakeCheckbox("Flash Animation", 20, -114,
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

    -- Font picker
    do
        local fontLabel = displayBox:CreateFontString(nil, "OVERLAY")
        fontLabel:SetPoint("TOPLEFT", 8, -94)
        SetUIFont(fontLabel, 13, "OUTLINE")
        fontLabel:SetText("Alert Font")
        fontLabel:SetTextColor(THEME_R, THEME_G, THEME_B)
        themeFS[#themeFS + 1] = { fs=fontLabel, alpha=1 }

        local fontPool = {}
        local dropdown = CreateFrame("DropdownButton", "NemPetAlertsFontDrop",
                                     displayBox, "WowStyle1DropdownTemplate")
        dropdown:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", 0, -6)
        dropdown:SetWidth(220)
        dropdown:SetDefaultText(db.fontName or "Gotham Narrow Ultra")

        local function SetupMenu()
            local fonts = {}
            for name, path in pairs(BUNDLED_FONTS) do fonts[name] = path end
            if LSM then
                local lsmFonts = LSM:HashTable(LSM.MediaType and LSM.MediaType.FONT or "font")
                if lsmFonts then
                    for fontName, fontPath in pairs(lsmFonts) do
                        if not fonts[fontName] then
                            fonts[fontName] = fontPath:gsub("/", "\\")
                        end
                    end
                end
            end
            local sortedNames = {}
            for name in pairs(fonts) do sortedNames[#sortedNames + 1] = name end
            table.sort(sortedNames)

            dropdown:SetupMenu(function(_, rootDescription)
                local itemHeight = 16
                local maxVisible = 12
                rootDescription:SetScrollMode(maxVisible * itemHeight)
                for index, fontName in ipairs(sortedNames) do
                    local fontPath = fonts[fontName]
                    local n = fontName
                    local button = rootDescription:CreateButton("                                        ", function()
                        db.fontName = n
                        dropdown:SetDefaultText(n)
                        ApplyDisplaySettings()
                    end)
                    button:AddInitializer(function(btn)
                        local fontDisplay = fontPool[index]
                        if not fontDisplay then
                            fontDisplay = dropdown:CreateFontString(nil, "BACKGROUND")
                            fontPool[index] = fontDisplay
                        end
                        fontDisplay:SetParent(btn)
                        fontDisplay:ClearAllPoints()
                        fontDisplay:SetPoint("LEFT", btn, "LEFT", 5, 0)
                        fontDisplay:SetFont(fontPath, 12)
                        fontDisplay:SetText(n)
                        fontDisplay:Show()
                    end)
                end
            end)
        end

        hooksecurefunc(dropdown, "OnMenuClosed", function()
            for _, fs in pairs(fontPool) do fs:Hide() end
        end)
        C_Timer.After(0, SetupMenu)

        dropdown.Refresh = function()
            dropdown:SetDefaultText(db.fontName or "Gotham Narrow Ultra")
        end
        NPA.fontDropdown = dropdown
    end

    -- Sliders
    sliders.scale = MakeSlider(panel, "Alert Text Scale", 50, 200, 10, 370, -86, 270,
        function() return math_floor((db.scale or 1.0) * 100 + 0.5) end,
        function(v) db.scale = v / 100; ApplyDisplaySettings() end,
        function(v) return string_format("%.1f", v / 100) end)
    if sliders.scale then
        for _, child in next, { sliders.scale:GetChildren() } do
            if child.Low then child.Low:SetText("0.5x"); child.High:SetText("2.0x") end
        end
    end

    sliders.fontSize = MakeSlider(panel, "Font Size", 1, 100, 1, 370, -146, 270,
        function() return db.fontSize or 25 end,
        function(v) db.fontSize = v; ApplyDisplaySettings() end,
        nil)

    -- ================================================================
    -- SOUNDS (built dynamically from active module)
    -- ================================================================
    local soundBox = SectionBox(12, -245, PW - 24, 130)
    SectionHeader(soundBox, "Sounds", 8, -6)

    -- ================================================================
    -- ALERTS (built dynamically from active module)
    -- ================================================================
    local alertBox = SectionBox(12, -383, PW - 24, 161)
    SectionHeader(alertBox, "Alerts", 8, -6)

    local alertCheckboxes = {}

    -- ================================================================
    -- BUTTONS
    -- ================================================================
    local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testBtn:SetSize(110, 26)
    testBtn:SetText("Test")
    testBtn:SetScript("OnClick", function()
        if not IsFullyImplemented() then return end
        NPA:ToggleTest()
    end)
    NPA.testBtn = testBtn

    local lockBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    lockBtn:SetSize(140, 26)
    lockBtn:SetText("Unlock Frame")
    lockBtn:SetScript("OnClick", function()
        SetLockState(not coreState.unlocked)
    end)
    NPA.lockBtn = lockBtn

    local resetBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetBtn:SetSize(140, 26)
    resetBtn:SetText("Reset Position")
    resetBtn:SetScript("OnClick", function()
        db.x             = CORE_DEFAULTS.x
        db.y             = CORE_DEFAULTS.y
        db.point         = CORE_DEFAULTS.point
        db.relativePoint = CORE_DEFAULTS.relativePoint
        db.relativeTo    = CORE_DEFAULTS.relativeTo
        ApplyDisplaySettings()
        Msg("Position reset.")
    end)

    local btnSpacing = 12
    local totalBtnW = 110 + 140 + 140 + (btnSpacing * 2)
    local btnStartX = math_floor((PW - totalBtnW) / 2)
    testBtn:SetPoint("TOPLEFT", btnStartX, -552)
    lockBtn:SetPoint("LEFT", testBtn, "RIGHT", btnSpacing, 0)
    resetBtn:SetPoint("LEFT", lockBtn, "RIGHT", btnSpacing, 0)

    -- ================================================================
    -- CONTENT AREA BACKGROUND (solid black behind unsupported text)
    -- ================================================================
    local contentBG = CreateFrame("Frame", nil, panel,
        BackdropTemplateMixin and "BackdropTemplate" or nil)
    contentBG:SetPoint("TOPLEFT",     panel, "TOPLEFT",     0, -42)
    contentBG:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0,  22)
    contentBG:SetFrameLevel(panel:GetFrameLevel() + 1)
    if contentBG.SetBackdrop then
        contentBG:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        contentBG:SetBackdropColor(0, 0, 0, 1)
    end

    -- ================================================================
    -- INITIAL STATE: hide all content sections at build time.
    -- OnShow will show them if a supported spec is active.
    -- ================================================================
    subtitle:Hide()
    displayBox:Hide()
    soundBox:Hide()
    alertBox:Hide()
    testBtn:Hide()
    lockBtn:Hide()
    resetBtn:Hide()
    for _, cb in pairs(checkboxes) do cb:Hide() end
    for _, sl in pairs(sliders) do sl:Hide() end
    if NPA.fontDropdown then NPA.fontDropdown:Hide() end

    -- ================================================================
    -- UNSUPPORTED SPEC TEXT (parented to contentBG, auto-shows/hides)
    -- Text is set at build time — this IS the default panel state.
    -- ================================================================
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

    -- ================================================================
    -- VERSION FOOTER
    -- ================================================================
    local version = panel:CreateFontString(nil, "OVERLAY")
    version:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 8)
    SetUIFont(version, 10)
    version:SetText(NPA_VERSION)
    version:SetTextColor(THEME_R, THEME_G, THEME_B, 0.6)
    themeFS[#themeFS + 1] = { fs=version, alpha=0.6 }

    -- ================================================================
    -- OnShow: rebuild dynamic sections from active module
    -- ================================================================

    -- Helper: hide all content sections and buttons (unsupported state)
    local function HideAllContent()
        subtitle:Hide()
        displayBox:Hide()
        soundBox:Hide()
        alertBox:Hide()
        testBtn:Hide()
        lockBtn:Hide()
        resetBtn:Hide()
        for _, cb in pairs(checkboxes) do cb:Hide() end
        for _, sl in pairs(sliders) do sl:Hide() end
        for _, cb in pairs(soundCheckboxes) do cb:Hide() end
        for _, dd in pairs(soundDDs) do dd:Hide() end
        for _, cb in pairs(alertCheckboxes) do cb:Hide() end
        if NPA.fontDropdown then NPA.fontDropdown:Hide() end
        if NPA.healPetThreshBox then NPA.healPetThreshBox:Hide() end
        contentBG:Show()
    end

    -- Helper: show all content sections and buttons (supported state)
    local function ShowAllContent()
        subtitle:Show()
        displayBox:Show()
        soundBox:Show()
        alertBox:Show()
        testBtn:Show()
        lockBtn:Show()
        resetBtn:Show()
        for _, cb in pairs(checkboxes) do cb:Show() end
        for _, sl in pairs(sliders) do sl:Show() end
        if NPA.fontDropdown then NPA.fontDropdown:Show() end
        contentBG:Hide()
    end

    panel:SetScript("OnShow", function()
        UpdatePanelTheme()

        if not IsFullyImplemented() then
            -- ── Unsupported spec: default state, nothing to do ───
            HideAllContent()
            return
        end

        -- ── Supported spec: show full UI ─────────────────────────
        ShowAllContent()

        local mod = NPA.activeModule
        if not mod then return end

        -- ── Rebuild Sound Rows ─────────────────────────────
        for _, cb in pairs(soundCheckboxes) do cb:Hide() end
        for _, dd in pairs(soundDDs) do dd:Hide() end
        wipe(soundCheckboxes)
        wipe(soundDDs)

        local soundRowCount = 0
        for _, alert in ipairs(mod.alerts) do
            if alert.defaultSound then
                soundRowCount = soundRowCount + 1
                local k = alert.key
                local y = -28 - (soundRowCount - 1) * 40
                local cbS, ddS = MakeSoundRow(soundBox,
                    alert.soundLabel or alert.label, y,
                    function() return db[k .. "SoundEnabled"] end,
                    function(v) db[k .. "SoundEnabled"] = v end,
                    function() return db[k .. "SoundName"] end,
                    function(v) db[k .. "SoundName"] = v end)
                soundCheckboxes[k] = cbS
                soundDDs[k]        = ddS
            end
        end

        -- ── Rebuild Alert Rows ─────────────────────────────
        for _, cb in pairs(alertCheckboxes) do cb:Hide() end
        wipe(alertCheckboxes)

        -- Layout: 2 columns
        local alertCount = 0
        for _, alert in ipairs(mod.alerts) do
            alertCount = alertCount + 1
            local k = alert.key
            local col   = (alertCount - 1) % 2
            local row   = math_floor((alertCount - 1) / 2)
            local xPos  = col == 0 and 20 or 330
            local yPos  = -413 - row * 24
            alertCheckboxes[k] = MakeAlertRow(panel,
                alert.label, xPos, yPos,
                function() return db[k .. "Enabled"] end,
                function(v) db[k .. "Enabled"] = v end,
                k)
        end

        -- ── Heal Pet Threshold ─────────────────────────────
        if mod.hasHealPet and mod.healPetAlertIndex then
            local hpAlert = mod.alerts[mod.healPetAlertIndex]
            if hpAlert and alertCheckboxes[hpAlert.key] then
                local acb = alertCheckboxes[hpAlert.key]
                if not NPA.healPetThreshBox then
                    local threshBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
                    threshBox:SetSize(36, 18)
                    threshBox:SetAutoFocus(false)
                    threshBox:SetMaxLetters(3)
                    threshBox:SetFontObject("GameFontWhite")
                    threshBox:SetJustifyH("CENTER")
                    NPA.healPetThreshBox = threshBox

                    local pctLabel = panel:CreateFontString(nil, "OVERLAY")
                    pctLabel:SetPoint("LEFT", threshBox, "RIGHT", 2, 0)
                    SetUIFont(pctLabel, 11)
                    pctLabel:SetText("%")
                    pctLabel:SetTextColor(1, 1, 1)

                    local function CommitThreshold()
                        local val = tonumber(threshBox:GetText())
                        if val then
                            val = math_max(1, math_min(99, math_floor(val + 0.5)))
                            db.healPetThreshold = val
                            NPA.ResetHealthCurve()
                        end
                        threshBox:SetText(tostring(db.healPetThreshold or 30))
                        threshBox:SetCursorPosition(0)
                        threshBox:ClearFocus()
                    end

                    threshBox:SetScript("OnEnterPressed", CommitThreshold)
                    threshBox:SetScript("OnEditFocusLost", CommitThreshold)
                    threshBox:SetScript("OnEscapePressed", function(self)
                        self:SetText(tostring(db.healPetThreshold or 30))
                        self:SetCursorPosition(0)
                        self:ClearFocus()
                    end)
                end

                local threshBox = NPA.healPetThreshBox
                threshBox:ClearAllPoints()
                threshBox:SetPoint("LEFT", acb.label, "RIGHT", 10, 0)
                threshBox:SetText(tostring(db.healPetThreshold or 30))
                threshBox:SetCursorPosition(0)
                threshBox:Show()

                local hpc = db.alertColors and db.alertColors[hpAlert.key]
                if hpc then threshBox:SetTextColor(hpc.r, hpc.g, hpc.b) end
            end
        elseif NPA.healPetThreshBox then
            NPA.healPetThreshBox:Hide()
        end

        -- Refresh core checkboxes
        for _, cb in pairs(checkboxes) do cb:Refresh() end
        for _, sl in pairs(sliders) do sl.Refresh() end
        if NPA.fontDropdown then NPA.fontDropdown.Refresh() end
        lockBtn:SetText(coreState.unlocked and "Lock Frame" or "Unlock Frame")
        testBtn:SetText(coreState.testMode and "Stop Test" or "Test")
    end)

    -- ================================================================
    -- Register
    -- ================================================================
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

-- =============================================================
-- PLAYER_LOGIN
-- =============================================================
function NPA:OnLogin()
    activeClass = GetActiveClass()

    CreateDisplay()
    self:BuildOptionsPanel()
    self:InitCommands()

    -- Find and activate the correct spec module
    local key, mod = FindActiveModule()
    if key and mod then
        ActivateModule(key, mod)
    end
    ApplyDisplaySettings()
end

-- =============================================================
-- Event Handler
-- =============================================================
NPA:SetScript("OnEvent", function(self, event, ...)
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
    local db  = NemPetAlertsSV

    -- Spec / talent change: re-evaluate which module should be active
    if event == "PLAYER_SPECIALIZATION_CHANGED"
    or event == "PLAYER_TALENT_UPDATE"
    or event == "TRAIT_CONFIG_UPDATED" then
        -- With per-spec modules, a spec change may require a full module swap
        local newKey, newMod = FindActiveModule()
        if newKey ~= self.activeModuleKey then
            -- Different spec → swap modules
            if newKey and newMod then
                ActivateModule(newKey, newMod)
            else
                DeactivateCurrentModule()
                -- Rebuild display to clear stale rows
                if self.display then
                    SetDisplaySlot(nil)
                end
            end
        else
            -- Same module, but talents may have changed
            if mod and mod.OnEvent then
                mod:OnEvent(db, event, ...)
            end
        end
        C_Timer.After(0.1, Evaluate)
        return
    end

    -- Guard: no active module → ignore gameplay events
    if not mod then return end
    if not IsFullyImplemented() then return end

    if event == "PLAYER_ENTERING_WORLD" then
        ApplyDisplaySettings()
        if mod.OnEvent then mod:OnEvent(db, event, ...) end
        C_Timer.After(0.1, Evaluate)
        return
    end

    -- Delegate to module
    if mod.OnEvent then
        local handled = mod:OnEvent(db, event, ...)
        if not handled then
            C_Timer.After(0.1, Evaluate)
        end
    else
        C_Timer.After(0.1, Evaluate)
    end
end)

-- =============================================================
-- Core Event Registration (always active)
-- =============================================================
NPA:RegisterEvent("ADDON_LOADED")
NPA:RegisterEvent("PLAYER_LOGIN")
NPA:RegisterEvent("PLAYER_ENTERING_WORLD")
NPA:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
NPA:RegisterEvent("PLAYER_TALENT_UPDATE")
NPA:RegisterEvent("TRAIT_CONFIG_UPDATED")
