-- ManaRise - Core.lua
-- Namespace, API capability detection, secret-value helpers, event dispatch
-- and a single coalescing scheduler. Loaded first.

local ADDON_NAME, ns = ...

ns.name = ADDON_NAME
ns.version = "1.12.29"

---------------------------------------------------------------------------
-- Output
---------------------------------------------------------------------------
local PREFIX = "|cff2589e8ManaRise|r: "

function ns:Print(msg, ...)
    if select("#", ...) > 0 then
        msg = string.format(msg, ...)
    end
    if ns.capture then            -- /mr report collects the output instead
        ns.capture[#ns.capture + 1] = tostring(msg)
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. tostring(msg))
end

function ns:Debug(msg, ...)
    if self.db and self.db.debug then
        if select("#", ...) > 0 then
            msg = string.format(msg, ...)
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff2589e8ManaRise|r |cff888888[debug]|r " .. tostring(msg))
    end
end

---------------------------------------------------------------------------
-- Caught errors
-- The last few errors ManaRise caught (event handlers, liquid setup, panel
-- build) so /mr report can show them. Identical repeats only raise a count.
---------------------------------------------------------------------------
ns.errors = {}
local MAX_ERRORS = 5

function ns:LogError(where, err)
    local msg = string.sub(tostring(err), 1, 240)
    where = tostring(where)
    local last = self.errors[#self.errors]
    if last and last.where == where and last.msg == msg then
        last.count = last.count + 1
        return
    end
    self.errors[#self.errors + 1] = { where = where, msg = msg, count = 1 }
    if #self.errors > MAX_ERRORS then table.remove(self.errors, 1) end
end

---------------------------------------------------------------------------
-- Localization
-- ns.L[key] gives the text for the client's language. English (ns.L_EN,
-- Locales/enUS.lua) is the fallback for anything a translation leaves out.
-- Translations register as functions (Locales/<code>.lua), so only the one
-- for the client's language is ever built into a table.
---------------------------------------------------------------------------
ns.LOCALES = {}           -- [code] = function() return { KEY = "text" } end
ns.LOCALE_ALIAS = { enGB = "enUS", esMX = "esES", ptPT = "ptBR" }
ns.locale = "enUS"

local L = setmetatable({}, { __index = function(_, key)
    local en = ns.L_EN and ns.L_EN[key]
    if en == nil then
        ns.missingKeys = ns.missingKeys or {}   -- a bug: checked by the tests
        ns.missingKeys[key] = true
        return tostring(key)
    end
    return en
end })
ns.L = L

-- The placeholders of a format string in order, e.g. "%d %s %%".
function ns.FormatSpec(text)
    local specs = {}
    for spec in string.gmatch(text, "%%[%-%+0]*%d*%.?%d*[%a%%]") do
        specs[#specs + 1] = spec
    end
    return table.concat(specs, " ")
end

-- Use the translation for a client locale code (GetLocale()). Entries whose
-- placeholders differ from the English text are skipped (they would break
-- string.format), so English shows for them instead.
function ns:ApplyLocale(code)
    for key in pairs(L) do rawset(L, key, nil) end
    self.locale = "enUS"
    self.localeRejected = {}
    code = self.LOCALE_ALIAS[code] or code
    local load = self.LOCALES[code]
    if type(load) ~= "function" then return end
    local ok, t = pcall(load)
    if not ok or type(t) ~= "table" then return end
    for key, text in pairs(t) do
        local en = self.L_EN[key]
        if type(text) == "string" and type(en) == "string" and ns.FormatSpec(text) == ns.FormatSpec(en) then
            rawset(L, key, text)
        else
            self.localeRejected[#self.localeRejected + 1] = tostring(key)
        end
    end
    self.locale = code
end

---------------------------------------------------------------------------
-- Secret-value helpers
-- WoW: Forever uses Mainline secret-value restrictions. Addon code must not
-- compare, do arithmetic on, or boolean-test a secret value. Every value that
-- *could* be secret is passed through IsSecret() before it is inspected.
---------------------------------------------------------------------------
local _issecretvalue = issecretvalue
local _canaccesstable = canaccesstable

function ns.IsSecret(value)
    if _issecretvalue then
        return _issecretvalue(value) == true
    end
    return false
end

-- True when we are allowed to index this table (it is not a secret table,
-- or the client does not implement secret tables at all).
function ns.CanAccessTable(t)
    if _canaccesstable then
        return _canaccesstable(t) == true
    end
    return true
end

---------------------------------------------------------------------------
-- API capability detection (Phase 1: verify, don't assume)
-- Each entry resolves to the function the client actually exposes, or nil.
---------------------------------------------------------------------------
ns.api = {}

function ns:ResolveAPIs()
    local api = self.api
    local CAB = C_ActionBar
    local CS = C_Spell

    api.UnitPower          = UnitPower
    api.UnitPowerMax       = UnitPowerMax
    api.UnitIsDeadOrGhost  = UnitIsDeadOrGhost
    api.GetActionInfo      = GetActionInfo
    api.HasAction          = (CAB and CAB.HasAction) or HasAction
    api.IsUsableAction     = (CAB and CAB.IsUsableAction) or IsUsableAction
    api.GetSpellPowerCost  = (CS and CS.GetSpellPowerCost) or GetSpellPowerCost
    api.GetSpellName       = (CS and CS.GetSpellName) or nil
    api.GetSpellInfo       = (CS and CS.GetSpellInfo) or GetSpellInfo   -- table (new) or multiple returns (old)
    api.InCombatLockdown   = InCombatLockdown
    api.TimerAfter         = C_Timer and C_Timer.After or nil
    api.IsEventValid       = C_EventUtils and C_EventUtils.IsEventValid or nil
    api.GetAtlasInfo       = C_Texture and C_Texture.GetAtlasInfo or nil
    api.IsActionInRange    = (CAB and CAB.IsActionInRange) or IsActionInRange
    api.EnableActionRangeCheck = CAB and CAB.EnableActionRangeCheck or nil
    api.PlaySound          = PlaySound
    api.PlaySoundFile      = PlaySoundFile
    api.GetTime            = GetTime

    api.POWER_MANA = (Enum and Enum.PowerType and Enum.PowerType.Mana) or 0
    api.StatusBarInterpolation = Enum and Enum.StatusBarInterpolation or nil

    -- Hard requirements. Without these ManaRise cannot show honest data.
    local missing = {}
    local required = {
        "UnitPower", "UnitPowerMax", "GetActionInfo", "HasAction",
        "GetSpellPowerCost", "InCombatLockdown", "TimerAfter",
    }
    for i = 1, #required do
        if type(api[required[i]]) ~= "function" then
            missing[#missing + 1] = required[i]
        end
    end
    self.missingAPIs = missing
    return #missing == 0
end

function ns:InCombat()
    return self.api.InCombatLockdown and self.api.InCombatLockdown() or false
end

---------------------------------------------------------------------------
-- Event dispatch
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
ns.eventFrame = eventFrame
local handlers = {}

function ns:On(event, fn)
    handlers[event] = fn
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    local fn = handlers[event]
    if fn then
        -- A failing handler is logged for /mr report and then reported to
        -- the game's own error handler exactly as before.
        local ok, err = pcall(fn, event, ...)
        if not ok then
            ns:LogError(event, err)
            local report = geterrorhandler and geterrorhandler()
            if report then report(err) end
        end
    end
end)

function ns:IsEventValid(event)
    if self.api.IsEventValid then
        return self.api.IsEventValid(event) == true
    end
    return true
end

-- Register only events that the client reports as valid. Returns true on success.
function ns:RegisterEventSafe(event, unit)
    if not self:IsEventValid(event) then
        self:Debug(L.DBG_EVENT_SKIPPED, event)
        return false
    end
    if unit then
        eventFrame:RegisterUnitEvent(event, unit)
    else
        eventFrame:RegisterEvent(event)
    end
    return true
end

function ns:UnregisterEventSafe(event)
    if eventFrame:IsEventRegistered(event) then
        eventFrame:UnregisterEvent(event)
    end
end

---------------------------------------------------------------------------
-- Coalescing scheduler
-- Structural events (page changes, slot changes, auras) can burst. We mark
-- work as pending and run it once on the next frame, after Blizzard's own
-- action buttons have finished updating their .action values.
---------------------------------------------------------------------------
local pending = { discover = false, slots = false, costs = false, mana = false }
local scheduled = false

local function Flush()
    scheduled = false
    local AB = ns.ActionBars
    if not AB then return end

    if pending.discover then
        pending.discover = false
        AB:Discover()
        pending.slots = true
        -- Say once if the liquid look couldn't be built, instead of silently
        -- showing the flat look.
        if not ns.liquidWarned and ns.db.style == "liquid" then
            local built, total, problem = AB:LiquidInfo()
            if total > 0 and built < total and problem then
                ns.liquidWarned = true
                ns:Print(L.LIQUID_UNAVAILABLE, total - built, total, problem)
            end
        end
    end
    if pending.slots then
        pending.slots = false
        pending.costs = false
        pending.mana = false
        AB:RefreshSlots()
    elseif pending.costs then
        pending.costs = false
        pending.mana = false
        AB:RefreshCosts()
    elseif pending.mana then
        pending.mana = false
        AB:UpdateAll()
    end
end

function ns:Schedule(what)
    pending[what] = true
    if not scheduled then
        scheduled = true
        self.api.TimerAfter(0, Flush)
    end
end

---------------------------------------------------------------------------
-- Runtime events (registered only while enabled)
---------------------------------------------------------------------------
local RUNTIME_EVENTS = {
    -- resource
    { "UNIT_POWER_UPDATE", "player" },
    { "UNIT_MAXPOWER", "player" },
    { "UNIT_DISPLAYPOWER", "player" },
    -- costs can change with auras (e.g. free-cast procs), forms and talents
    { "UNIT_AURA", "player" },
    -- signals (range tint)
    { "ACTION_RANGE_CHECK_UPDATE" },
    { "PLAYER_TARGET_CHANGED" },
    { "SPELLS_CHANGED" },
    { "UPDATE_SHAPESHIFT_FORM" },
    { "PLAYER_SPECIALIZATION_CHANGED", "player" },
    { "ACTIONBAR_UPDATE_USABLE" },
    { "SPELL_UPDATE_USABLE" },
    -- slot contents / paging
    { "ACTIONBAR_SLOT_CHANGED" },
    { "ACTIONBAR_PAGE_CHANGED" },
    { "UPDATE_BONUS_ACTIONBAR" },
    -- layout
    { "EDIT_MODE_LAYOUTS_UPDATED" },
    { "COOLDOWN_VIEWER_SPELL_OVERRIDE_UPDATED" },
    -- life state
    { "PLAYER_DEAD" },
    { "PLAYER_ALIVE" },
    { "PLAYER_UNGHOST" },
}

function ns:RegisterRuntimeEvents()
    for i = 1, #RUNTIME_EVENTS do
        local e = RUNTIME_EVENTS[i]
        self:RegisterEventSafe(e[1], e[2])
    end
end

function ns:UnregisterRuntimeEvents()
    for i = 1, #RUNTIME_EVENTS do
        self:UnregisterEventSafe(RUNTIME_EVENTS[i][1])
    end
end

---------------------------------------------------------------------------
-- Enable / disable
---------------------------------------------------------------------------
function ns:Enable()
    if not self.apiOK then return end
    self:RegisterRuntimeEvents()
    self:Schedule("discover")
end

function ns:Disable()
    self:UnregisterRuntimeEvents()
    if self.ActionBars then
        self.ActionBars:StopSimulation(true)
        self.ActionBars:HideAll("disabled")
    end
    if self.Animation then
        self.Animation:StopAll()
    end
end

-- Re-apply all settings to live indicators (colors, smoothing, etc.)
function ns:ApplySettings()
    if self.ActionBars then
        self.ActionBars:ApplyStyle()
    end
    if self.db.enabled then
        self:Enable()
    else
        self:Disable()
    end
    if self.ActionBars then self.ActionBars:ResumePreview() end
end

---------------------------------------------------------------------------
-- Lifecycle
---------------------------------------------------------------------------
ns:On("PLAYER_LOGIN", function()
    ns:ApplyLocale(GetLocale and GetLocale() or "enUS")
    ns:InitDB()
    local meta = C_AddOns and C_AddOns.GetAddOnMetadata
    if meta then
        local v = meta(ADDON_NAME, "Version")
        if type(v) == "string" and v ~= "" then ns.version = v end
    end
    ns.apiOK = ns:ResolveAPIs()
    ns.Options:Register()
    ns.Minimap:Update()
    ns:Greet()

    if not ns.apiOK then
        ns:Print(L.MISSING_APIS, table.concat(ns.missingAPIs, ", "))
        return
    end

    ns.Animation:Init()
    ns.Mana:Init()

    -- Always-on: combat transitions (deferred discovery, simulation guard)
    ns:RegisterEventSafe("PLAYER_REGEN_ENABLED")
    ns:RegisterEventSafe("PLAYER_REGEN_DISABLED")
    ns:RegisterEventSafe("PLAYER_ENTERING_WORLD")

    -- Bartender4 / Dominos / ElvUI action bars (BarAddons.lua). They load
    -- before us (OptionalDeps); ADDON_LOADED catches any that load later.
    ns.BarAddons:Detect()
    ns:RegisterEventSafe("ADDON_LOADED")

    if ns.db.enabled then
        ns:Enable()
    end
end)

ns:On("PLAYER_ENTERING_WORLD", function()
    if ns.db and ns.db.enabled then
        ns:Schedule("discover")
    end
end)

-- One message after an install or update, then silence until the next one.
function ns:Greet()
    local root = self.root
    if root.lastVersion == self.version then return end
    local first = self.isNewInstall
    root.lastVersion = self.version
    self:Print(first and L.WELCOME or L.WHATS_NEW, self.version)
end

ns:On("PLAYER_REGEN_ENABLED", function()
    if ns.Minimap then ns.Minimap:Update() end
    if ns.Options then ns.Options:OnCombatEnded() end
    if ns.ActionBars and ns.ActionBars.restyleAfterCombat then
        ns.ActionBars:ApplyStyle()
    end
    if ns.db and ns.db.enabled and ns.ActionBars and ns.ActionBars.discoverAfterCombat then
        ns:Schedule("discover")
    end
end)

ns:On("PLAYER_REGEN_DISABLED", function()
    if ns.ActionBars then
        ns.ActionBars:StopSimulation(false)
    end
end)

eventFrame:RegisterEvent("PLAYER_LOGIN")
