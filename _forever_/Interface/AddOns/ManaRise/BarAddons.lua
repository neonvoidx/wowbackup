-- ManaRise - BarAddons.lua
-- Support for the action bars of Bartender4, Dominos, ElvUI and EllesmereUI.
--
-- When one of them is loaded, its buttons get the same overlay as the default
-- bars. Everything is event or callback driven (no polling):
--   * Bartender4 and ElvUI build their buttons with LibActionButton-1.0
--     (ElvUI ships its own copy, "LibActionButton-1.0-ElvUI"). We use the
--     library's public API: lib:GetAllButtons() to list buttons, the
--     OnButtonCreated / OnButtonUpdate / OnButtonContentsChanged callbacks
--     to hear about new buttons, paging and content changes, and
--     button:GetAction() to read the action slot a button shows right now.
--   * Dominos uses Blizzard's ActionBarButtonTemplate, so the slot is read
--     the same way as on the default bars. Its controller,
--     Dominos.ActionButtons, lists the buttons (GetAll). We post-hook its
--     GetOrCreateActionButton (new buttons) and OnActionChanged (paging) with
--     hooksecurefunc, which never changes what Dominos itself does.
--
--   * EllesmereUI's action bar module builds its own buttons from Blizzard's
--     ActionBarButtonTemplate and names them EABButton<slot> (global frames).
--     We list those by name. The slot is read from the button's "action"
--     attribute, which the module sets and pages; its .action field can be
--     stale because the module stops the template's own event handling.
--
--   * Other bar addons can register themselves: ManaRise_RegisterBarAddon(def)
--     (see Register below and the README). A registration only adds an entry
--     to the SOURCES list; it is then followed by the same code as the
--     built-in ones, so the same rules apply to it.
--
-- Nothing here changes a secure attribute, a button script, or any setting of
-- those addons, and nothing is written onto their button tables. Frame
-- creation still happens only in ActionBars:Discover, which waits for combat
-- to end. When none of the three is loaded this module does nothing.

local _, ns = ...

local BA = {}
local L = ns.L
ns.BarAddons = BA

BA.detected = {}   -- addon names in detection order, e.g. { "Bartender4" }
BA.problems = {}   -- [addon] = why it is loaded but its buttons can't be read
local hooked = {}  -- [addon] = true once its callbacks/hooks are in place
local libs = {}    -- [addon] = LibActionButton instance

---------------------------------------------------------------------------
-- Slot readers
---------------------------------------------------------------------------
-- LibActionButton: button:GetAction() returns the kind and value for the
-- button's current state (page). Only "action" kinds map to an action slot;
-- LAB can also hold spells, items and macros directly, which have no slot.
local function LABSlot(button)
    if type(button.GetAction) ~= "function" then return nil, "no-slot" end
    local kind, value = button:GetAction()
    if kind == "action" then
        value = tonumber(value)
        if value and value > 0 then return value end
        return nil, "no-slot"
    elseif kind == "empty" or kind == nil then
        return nil, "empty-slot"
    end
    return nil, "not-a-spell"
end
BA.LABSlot = LABSlot

-- EllesmereUI: the "action" attribute holds the slot the button shows.
local function EABSlot(button)
    local action
    if type(button.GetAttribute) == "function" then action = button:GetAttribute("action") end
    if type(action) ~= "number" then action = button.action end
    action = tonumber(action)
    if action and action > 0 then return action end
    return nil, "no-slot"
end
BA.EABSlot = EABSlot

---------------------------------------------------------------------------
-- Supported addons
---------------------------------------------------------------------------
local SOURCES = {
    { addon = "Bartender4", kind = "lab", major = "LibActionButton-1.0", prefix = "BT4Button" },
    { addon = "Dominos", kind = "dominos" },
    { addon = "ElvUI", kind = "lab", major = "LibActionButton-1.0-ElvUI", prefix = "ElvUI_Bar" },
    { addon = "EllesmereUIActionBars", label = "EllesmereUI", kind = "named", prefix = "EABButton", max = 200 },
}
BA.SOURCES = SOURCES
BA.registered = {}   -- sources added with ManaRise_RegisterBarAddon

-- The table key of a source: the addon name for the built-in ones, the
-- registered name for the others.
local function KeyOf(src) return src.key or src.addon end
local function GateOf(src)   -- the addon that has to be loaded first (nil: none)
    if src.registered then return src.waitFor end
    return src.addon
end
local function NameOf(src) return src.label or src.addon or src.key end

local function IsLoaded(name)
    local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    if type(f) ~= "function" then return false end
    return f(name) and true or false
end

-- LibActionButton is shared: other addons (and LAB's own flyout buttons) can
-- create buttons with it too. Only buttons named like the addon's own are
-- taken.
local function Owns(src, button)
    if not src.prefix then return true end   -- registered library without a prefix
    local name = type(button.GetName) == "function" and button:GetName()
    return type(name) == "string" and string.sub(name, 1, #src.prefix) == src.prefix
end

local function DominosController()
    local D = _G.Dominos
    local ctl = type(D) == "table" and D.ActionButtons
    if type(ctl) == "table" and type(ctl.GetAll) == "function" then return ctl end
    return nil
end

local function Active()
    return ns.db and ns.db.enabled
end

-- A tracked button may now show a different slot (paging, or new contents).
local function SlotMaybeChanged(button)
    if not Active() then return end
    local AB = ns.ActionBars
    local ind = AB:GetIndicator(button)
    if not ind then return end
    if not ns:InCombat() then AB:SyncMasks(ind) end   -- skin may have changed
    -- Same slot as before: ACTIONBAR_SLOT_CHANGED already covers its
    -- contents. No slot: the button's own contents may have changed.
    local slot = AB.GetSlot(ind)
    if slot ~= ind.slot or slot == nil then ns:Schedule("slots") end
end

local function NewButton()
    if Active() then ns:Schedule("discover") end
end

local function HookLAB(src)
    local LibStub = _G.LibStub   -- a table with a __call metamethod
    local lib = LibStub and LibStub(src.major, true)
    if type(lib) ~= "table" or type(lib.RegisterCallback) ~= "function"
       or type(lib.GetAllButtons) ~= "function" then
        return false, string.format(L.BAR_NOT_FOUND, src.major)
    end
    -- CallbackHandler: the first argument is only our registration key.
    local key = {}
    lib.RegisterCallback(key, "OnButtonCreated", function(_, button)
        if Owns(src, button) then NewButton() end
    end)
    lib.RegisterCallback(key, "OnButtonUpdate", function(_, button) SlotMaybeChanged(button) end)
    lib.RegisterCallback(key, "OnButtonContentsChanged", function(_, button) SlotMaybeChanged(button) end)
    libs[KeyOf(src)] = lib
    return true
end

local function HookDominos()
    local ctl = DominosController()
    if not ctl then return false, string.format(L.BAR_NOT_FOUND, "Dominos.ActionButtons") end
    if type(ctl.GetOrCreateActionButton) == "function" then
        hooksecurefunc(ctl, "GetOrCreateActionButton", NewButton)
    end
    if type(ctl.OnActionChanged) == "function" then
        hooksecurefunc(ctl, "OnActionChanged", function(_, buttonName)
            local button = type(buttonName) == "string" and _G[buttonName]
            if button then SlotMaybeChanged(button) else ns:Schedule("slots") end
        end)
    end
    return true
end

-- Looks for newly loaded bar addons. Safe to call repeatedly (PLAYER_LOGIN,
-- then ADDON_LOADED for addons that load later). Returns true if a new one
-- was found.
function BA:Detect()
    local found = false
    for i = 1, #SOURCES do
        local src = SOURCES[i]
        local key, gate = KeyOf(src), GateOf(src)
        if not hooked[key] and (gate == nil or IsLoaded(gate)) then
            local ok, problem
            if src.kind == "lab" then
                ok, problem = HookLAB(src)
            elseif src.kind == "named" or src.kind == "custom" then
                ok = true   -- buttons are found by name or function; PLAYER_ENTERING_WORLD rescans
            else
                ok, problem = HookDominos()
            end
            if ok then
                hooked[key] = true
                self.problems[key] = nil
                self.detected[#self.detected + 1] = NameOf(src)
                found = true
                ns:Debug(L.DBG_BAR_DETECTED, NameOf(src))
            else
                self.problems[key] = problem
            end
        end
    end
    return found
end

-- Called from ActionBars:Discover (out of combat): hands every button of the
-- detected addons to track(button, source, slotReader).
function BA:EachButton(track)
    for i = 1, #SOURCES do
        local src = SOURCES[i]
        local key = KeyOf(src)
        if hooked[key] then
            if src.kind == "lab" then
                for button in pairs(libs[key]:GetAllButtons()) do
                    if Owns(src, button) then track(button, NameOf(src), src.getSlot or LABSlot) end
                end
            elseif src.kind == "named" then
                for n = 1, src.max do
                    local button = _G[src.prefix .. n]
                    if button then track(button, NameOf(src), src.getSlot or EABSlot) end
                end
            elseif src.kind == "custom" then
                local ok, result = pcall(src.buttons)
                if ok and type(result) == "table" then
                    self.problems[key] = nil
                    for k, v in pairs(result) do
                        local button = type(v) == "table" and v or k
                        if type(button) == "table" then track(button, NameOf(src), src.getSlot or EABSlot) end
                    end
                else
                    self.problems[key] = ok and L.BAR_REG_NOT_TABLE
                        or string.format(L.BAR_REG_FUNC_ERROR, string.sub(tostring(result), 1, 120))
                    ns:LogError("register", self.problems[key])
                end
            else
                local ctl = DominosController()
                if ctl then
                    for button in ctl:GetAll() do track(button, src.addon, nil) end
                end
            end
        end
    end
end

-- One line for /mr status and /mr scan.
function BA:Summary()
    local counts = ns.ActionBars:SourceCounts()
    local registered = {}
    for i = 1, #self.registered do registered[NameOf(self.registered[i])] = true end
    local parts = {}
    for i = 1, #self.detected do
        local name = self.detected[i]
        local n = counts[name] or 0
        if n == 0 and registered[name] then
            parts[#parts + 1] = string.format(L.BAR_REG_NO_BUTTONS, name)
        else
            parts[#parts + 1] = string.format(n == 1 and L.BAR_TRACKED_ONE or L.BAR_TRACKED, name, n)
        end
    end
    for i = 1, #SOURCES do
        local src = SOURCES[i]
        local problem = self.problems[KeyOf(src)]
        if problem then
            parts[#parts + 1] = string.format("|cffff4040%s: %s|r", NameOf(src), problem)
        elseif src.registered and not hooked[KeyOf(src)] and src.waitFor then
            parts[#parts + 1] = string.format(L.BAR_REG_WAITING, NameOf(src), src.waitFor)
        end
    end
    if #parts == 0 then return L.BAR_NONE end
    return table.concat(parts, ", ")
end

---------------------------------------------------------------------------
-- Registration
-- ManaRise_RegisterBarAddon(def) lets another addon's author describe their
-- action buttons. def is a table (ManaRise copies what it needs and never
-- changes it):
--   name    short text shown in /mr status (required)
--   waitFor optional addon name to wait for before looking for buttons
--   and ONE way to find the buttons:
--     lib     LibStub name of a LibActionButton copy (optional prefix keeps
--             only buttons whose global name starts with it)
--     prefix + max   global frame names prefix1 .. prefixMax
--     buttons a function returning a table of buttons (array, or [button]=true)
--   slot    how to read a button's action slot: "lab" (button:GetAction(),
--           default for lib), "attribute" (the "action" attribute, then the
--           .action field; default for prefix and buttons) or a function
--           button -> slot number
-- Returns true, or false and the reason (also printed once in chat). It
-- never raises an error.
---------------------------------------------------------------------------
local KNOWN_REASONS = { ["empty-slot"] = true, ["no-slot"] = true, ["not-a-spell"] = true }

-- Wraps an author's slot function: errors, secret or odd results become
-- "no slot" instead of a Lua error inside ManaRise.
local function WrapSlot(fn)
    return function(button)
        local ok, slot, reason = pcall(fn, button)
        if not ok then
            ns:LogError("register", slot)
            return nil, "no-slot"
        end
        if ns.IsSecret(slot) then return nil, "secret-action" end
        slot = tonumber(slot)
        if slot and slot > 0 and slot == math.floor(slot) then return slot end
        if type(reason) == "string" and KNOWN_REASONS[reason] then return nil, reason end
        return nil, "no-slot"
    end
end

local function Reject(name, reason)
    ns:Print(L.BAR_REG_REJECTED, tostring(name), reason)
    return false, reason
end

local function BadField(name, field, expected)
    return Reject(name, string.format(L.BAR_REG_BAD_FIELD, field, expected))
end

local function IsText(v) return type(v) == "string" and v ~= "" and #v <= 120 end

function BA:Register(def)
    if type(def) ~= "table" then return Reject("?", L.BAR_REG_BAD_TABLE) end
    local name = def.name
    if type(name) ~= "string" or name == "" or #name > 40 or string.find(name, "[%c|]") then
        return Reject("?", L.BAR_REG_BAD_NAME)
    end
    for i = 1, #SOURCES do
        if NameOf(SOURCES[i]) == name or KeyOf(SOURCES[i]) == name then
            if SOURCES[i].registered then return true end   -- the same call twice: nothing to do
            return Reject(name, L.BAR_REG_DUPLICATE)
        end
    end

    local hasLib, hasNamed, hasButtons = def.lib ~= nil, def.max ~= nil, def.buttons ~= nil
    local ways = (hasLib and 1 or 0) + (hasNamed and 1 or 0) + (hasButtons and 1 or 0)
    if ways == 0 then return Reject(name, L.BAR_REG_NEEDS_WAY) end
    if ways > 1 then return Reject(name, L.BAR_REG_ONE_WAY) end
    if def.waitFor ~= nil and not IsText(def.waitFor) then return BadField(name, "waitFor", "text") end

    local src = { registered = true, key = name, label = name, waitFor = def.waitFor }
    local slot = def.slot
    if hasLib then
        if not IsText(def.lib) then return BadField(name, "lib", "text") end
        if def.prefix ~= nil and not IsText(def.prefix) then return BadField(name, "prefix", "text") end
        src.kind, src.major, src.prefix = "lab", def.lib, def.prefix
    elseif hasNamed then
        if not IsText(def.prefix) then return BadField(name, "prefix", "text") end
        if type(def.max) ~= "number" or def.max < 1 or def.max > 500 or def.max ~= math.floor(def.max) then
            return BadField(name, "max", "a whole number from 1 to 500")
        end
        src.kind, src.prefix, src.max = "named", def.prefix, def.max
    else
        if type(def.buttons) ~= "function" then return BadField(name, "buttons", "a function") end
        src.kind, src.buttons = "custom", def.buttons
    end
    if slot == nil then
        slot = hasLib and "lab" or "attribute"
    end
    if slot == "lab" then
        src.getSlot = LABSlot
    elseif slot == "attribute" then
        src.getSlot = EABSlot
    elseif type(slot) == "function" then
        src.getSlot = WrapSlot(slot)
    else
        return BadField(name, "slot", "\"lab\", \"attribute\" or a function")
    end

    SOURCES[#SOURCES + 1] = src
    self.registered[#self.registered + 1] = src
    -- Before PLAYER_LOGIN ManaRise's settings do not exist yet: Detect runs
    -- then. Afterwards, pick the new source up right away.
    if ns.db then
        local ok, found = pcall(self.Detect, self)
        if not ok then
            self.problems[name] = string.sub(tostring(found), 1, 120)
            ns:LogError("register", found)
        elseif found and Active() and ns.apiOK then
            ns:Schedule("discover")   -- waits for the end of combat in ActionBars:Discover
        end
    end
    return true
end

function _G.ManaRise_RegisterBarAddon(def)
    local ok, result, reason = pcall(BA.Register, BA, def)
    if ok then return result, reason end
    ns:LogError("register", result)
    return Reject(type(def) == "table" and def.name or "?", L.BAR_REG_INTERNAL)
end

-- For addons that create buttons later (the buttons function is read again).
function _G.ManaRise_RefreshBarAddons()
    if ns.db and ns.apiOK and Active() then ns:Schedule("discover") end
end

ns:On("ADDON_LOADED", function(_, name)
    local found = BA:Detect()
    -- the Cooldown Manager is a load-on-demand Blizzard addon
    if (found or name == "Blizzard_CooldownViewer") and Active() then ns:Schedule("discover") end
end)
