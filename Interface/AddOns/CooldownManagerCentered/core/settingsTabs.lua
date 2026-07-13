local _, ns = ...
local Affected = ns.API.Affected

-- Shared show/hide coordinator for the custom tabs CMC injects into Blizzard's
-- CooldownViewerSettings (the custom-tracker tab and the buff-container tab).
--
-- Blizzard's native tabs swap content in place; each custom tab instead shows a
-- full-frame panel over that content. Previously each panel hid the native content
-- into its own set and tried to hide the other panel ad hoc, which was asymmetric
-- (one direction hid the other explicitly, the other relied on a fragile hook) and
-- could leak one custom panel over another.
--
-- This manager centralizes it: every custom panel (with its tab) is registered, and
-- Activate/DeactivateAll guarantee exactly one custom panel is visible at a time, the
-- native content is hidden once and restored once (a single shared set), and the
-- custom tabs' checked states stay consistent — regardless of switch order.
local SettingsTabs = {}
ns.SettingsTabs = SettingsTabs

-- Chrome is never hidden as "content": the native side tabs (flagged
-- trackerIsTabButton by the tracker), any registered custom panel, or a Tab-named
-- frame. Everything else that's shown is native content to hide behind a panel.
local function IsChrome(child)
    if Affected(child).trackerIsTabButton or Affected(child).cmcCustomPanel then
        return true
    end
    local name = child:GetName()
    return name and name:find("Tab") ~= nil
end

local function GetEntries(settingsFrame)
    local entries = Affected(settingsFrame).cmcTabEntries
    if not entries then
        entries = {}
        Affected(settingsFrame).cmcTabEntries = entries
    end
    return entries
end

---Registers a custom panel (+ its tab button) so the manager can coordinate it.
---Idempotent per panel.
function SettingsTabs:RegisterPanel(settingsFrame, panel, tab, label)
    Affected(panel).cmcCustomPanel = true
    -- Also flagged so the tracker's own IsTabButton check treats it as chrome.
    Affected(panel).trackerIsTabButton = true
    local entries = GetEntries(settingsFrame)
    for _, entry in ipairs(entries) do
        if entry.panel == panel then
            return
        end
    end
    entries[#entries + 1] = { panel = panel, tab = tab, label = label }
end

local function HideNativeContent(settingsFrame)
    if Affected(settingsFrame).cmcHiddenNative then
        return
    end
    local hidden = {}
    for _, child in ipairs({ settingsFrame:GetChildren() }) do
        if child:IsShown() and not IsChrome(child) then
            child:Hide()
            hidden[#hidden + 1] = child
        end
    end
    Affected(settingsFrame).cmcHiddenNative = hidden
end

local function RestoreNativeContent(settingsFrame)
    local hidden = Affected(settingsFrame).cmcHiddenNative
    if not hidden then
        return
    end
    for _, child in ipairs(hidden) do
        if child and not child:IsShown() then
            child:Show()
        end
    end
    Affected(settingsFrame).cmcHiddenNative = nil
end

---Shows one custom panel: hides every other custom panel, hides native content
---(once), checks this panel's tab (unchecks the others), then shows + refreshes it.
function SettingsTabs:Activate(settingsFrame, panel, onActivated)
    for _, entry in ipairs(GetEntries(settingsFrame)) do
        if entry.panel ~= panel and entry.panel:IsShown() then
            entry.panel:Hide()
        end
        if entry.tab then
            entry.tab:SetChecked(entry.panel == panel)
        end
    end
    HideNativeContent(settingsFrame)
    Affected(settingsFrame).cmcActivePanel = panel
    if not panel:IsShown() then
        panel:Show()
    end
    if onActivated then
        onActivated()
    end
end

---Drops all custom panels and restores native content (a native tab was chosen).
function SettingsTabs:DeactivateAll(settingsFrame)
    for _, entry in ipairs(GetEntries(settingsFrame)) do
        if entry.panel:IsShown() then
            entry.panel:Hide()
        end
        if entry.tab then
            entry.tab:SetChecked(false)
        end
    end
    Affected(settingsFrame).cmcActivePanel = nil
    RestoreNativeContent(settingsFrame)
end
