local _, ns = ...

local Anchoring = {}
ns.Anchoring = Anchoring

local LEM = LibStub("WildForkLibEQOLEditMode-1.0")

local NONE = "NONE"
Anchoring.NONE = NONE

local function RequestSettingsRefresh()
    LEM.internal:RequestRefreshSettings()
end

-- Always-available targets: standard unit frames + the native CDM viewers.
local STANDARD_TARGETS = {
    { value = "PlayerFrame", label = "Player Frame" },
    { value = "TargetFrame", label = "Target Frame" },
    { value = "FocusFrame", label = "Focus Frame" },
    { value = "EssentialCooldownViewer", label = "Essential Viewer" },
    { value = "UtilityCooldownViewer", label = "Utility Viewer" },
    { value = "BuffIconCooldownViewer", label = "Buff Icon Viewer" },
    { value = "BuffBarCooldownViewer", label = "Buff Bar Viewer" },
}

local ANCHOR_POINTS = {
    "TOPLEFT",
    "TOP",
    "TOPRIGHT",
    "LEFT",
    "CENTER",
    "RIGHT",
    "BOTTOMLEFT",
    "BOTTOM",
    "BOTTOMRIGHT",
}

local function pointValues()
    local out = {}
    for _, p in ipairs(ANCHOR_POINTS) do
        out[#out + 1] = { text = p, value = p }
    end
    return out
end

-- Ensures and returns the anchor sub-table for a frame's config.
local function EnsureConfig(configKey)
    local editMode = ns.db.profile.editMode
    local frameCfg = editMode and editMode[configKey]
    if not frameCfg then
        return nil
    end
    if not frameCfg.anchor then
        frameCfg.anchor = { to = NONE, point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 }
    end
    return frameCfg.anchor
end
Anchoring.EnsureConfig = EnsureConfig

-- Maps a CMC frame name back to its anchor config, used for cycle detection through
-- chains of custom trackers / buff containers.
local function AnchorConfigForFrameName(name)
    if not name then
        return nil
    end
    local editMode = ns.db.profile.editMode
    if not editMode then
        return nil
    end
    local ti = name:match("^CMCTracker(%d+)$")
    if ti then
        local c = editMode["tracker" .. ti]
        return c and c.anchor
    end
    local bi = name:match("^CMCBuffContainer(%d+)$")
    if bi then
        local c = editMode["buffContainer" .. bi]
        return c and c.anchor
    end
    return nil
end

-- Detects whether anchoring selfFrameName to targetName would form a cycle through our
-- own frame chain (e.g. tracker 2 -> tracker 1 -> tracker 2). WoW errors on circular
-- SetPoint dependencies, so we bail to the stored position instead.
local function WouldCycle(selfFrameName, targetName)
    if not selfFrameName then
        return false
    end
    local visited = {}
    local cur = targetName
    while cur and cur ~= NONE and not visited[cur] do
        if cur == selfFrameName then
            return true
        end
        visited[cur] = true
        local cfg = AnchorConfigForFrameName(cur)
        cur = cfg and cfg.to
    end
    return false
end

-- True when the frame is configured to anchor to something other than None (whether or
-- not that target currently exists). Callers use this to skip the normal UIParent
-- positioning path.
function Anchoring:HasTarget(configKey)
    local editMode = ns.db.profile.editMode
    local frameCfg = editMode and editMode[configKey]
    local cfg = frameCfg and frameCfg.anchor
    return (cfg and cfg.to and cfg.to ~= NONE) or false
end

-- Applies the configured anchor to the frame. Returns true when it actually anchored
-- (target resolves and no cycle); false lets the caller fall back to the stored
-- position. Does not touch scale/alpha/strata — the caller's positioner still does that.
function Anchoring:ApplyAnchor(frame, configKey)
    local editMode = ns.db.profile.editMode
    local frameCfg = editMode and editMode[configKey]
    local cfg = frameCfg and frameCfg.anchor
    if not cfg or not cfg.to or cfg.to == NONE then
        return false
    end
    local target = _G[cfg.to]
    if not target or target == frame then
        return false
    end
    if WouldCycle(frame:GetName(), cfg.to) then
        return false
    end
    frame:ClearAllPoints()
    frame:SetPoint(cfg.point or "CENTER", target, cfg.relativePoint or "CENTER", cfg.x or 0, cfg.y or 0)
    return true
end

-- Builds the Anchor To dropdown option list for a frame, honoring which pools the
-- caller allows and excluding the frame itself. Rebuilt on demand (via the dropdown
-- generator) so newly auto-grown trackers/containers appear immediately.
function Anchoring:BuildTargetValues(selfFrameName, opts)
    opts = opts or {}
    local out = { { value = NONE, text = "None (Edit Mode position)" } }

    if opts.standard ~= false then
        for _, t in ipairs(STANDARD_TARGETS) do
            if t.value ~= selfFrameName and _G[t.value] then
                out[#out + 1] = { value = t.value, text = t.label }
            end
        end
    end

    if opts.customTrackers ~= false then
        local count = (ns.TrackerItemViewer and ns.TrackerItemViewer:GetTrackerCount())
            or ns.db.profile.tracker_count
            or 0
        for i = 1, count do
            local name = "CMCTracker" .. i
            if name ~= selfFrameName and _G[name] then
                out[#out + 1] = { value = name, text = "Custom Tracker " .. i }
            end
        end
    end

    if opts.customBuffs ~= false then
        local count = (ns.BuffData and ns.BuffData.GetContainerCount()) or 0
        for i = 1, count do
            local name = "CMCBuffContainer" .. i
            if name ~= selfFrameName and _G[name] then
                out[#out + 1] = { value = name, text = "Custom Buffs " .. i }
            end
        end
    end

    return out
end

-- Returns a list of LEM settings (a collapsible "Anchor" section + its controls) to
-- append to a frame's Edit Mode settings.
--   opts.selfFrameName  frame name to exclude from the target list (required)
--   opts.onChanged      called after any anchor field changes (re-apply + refresh)
--   opts.standard / opts.customTrackers / opts.customBuffs  toggle target pools
function Anchoring:BuildSettings(configKey, opts)
    opts = opts or {}
    local selfFrameName = opts.selfFrameName
    local onChanged = opts.onChanged or function() end

    local function cfg()
        return EnsureConfig(configKey)
    end

    local function isAnchored()
        local c = cfg()
        return c and c.to and c.to ~= NONE
    end

    local settings = {
        {
            kind = LEM.SettingType.Collapsible,
            id = "anchor",
            name = "Anchor",
            defaultCollapsed = true,
        },
        {
            name = "Anchor To",
            parentId = "anchor",
            kind = LEM.SettingType.Dropdown,
            default = NONE,
            get = function()
                return cfg().to or NONE
            end,
            set = function(_layoutName, value)
                cfg().to = value
                onChanged()
                RequestSettingsRefresh()
            end,
            generator = function(_owner, rootDescription)
                for _, v in ipairs(Anchoring:BuildTargetValues(selfFrameName, opts)) do
                    local val = v.value
                    rootDescription:CreateRadio(v.text, function()
                        return (cfg().to or NONE) == val
                    end, function()
                        cfg().to = val
                        onChanged()
                        RequestSettingsRefresh()
                    end)
                end
            end,
        },
        {
            name = "Anchor Point",
            parentId = "anchor",
            kind = LEM.SettingType.Dropdown,
            default = "CENTER",
            isShown = isAnchored,
            values = pointValues(),
            get = function()
                return cfg().point or "CENTER"
            end,
            set = function(_layoutName, value)
                cfg().point = value
                onChanged()
            end,
        },
        {
            name = "Relative Point",
            parentId = "anchor",
            kind = LEM.SettingType.Dropdown,
            default = "CENTER",
            isShown = isAnchored,
            values = pointValues(),
            get = function()
                return cfg().relativePoint or "CENTER"
            end,
            set = function(_layoutName, value)
                cfg().relativePoint = value
                onChanged()
            end,
        },
        {
            name = "X Offset",
            parentId = "anchor",
            kind = LEM.SettingType.Slider,
            default = 0,
            isShown = isAnchored,
            minValue = -500,
            maxValue = 500,
            valueStep = 1,
            get = function()
                return cfg().x or 0
            end,
            set = function(_layoutName, value)
                cfg().x = value
                onChanged()
            end,
            formatter = function(value)
                return string.format("%d px", value)
            end,
        },
        {
            name = "Y Offset",
            parentId = "anchor",
            kind = LEM.SettingType.Slider,
            default = 0,
            isShown = isAnchored,
            minValue = -500,
            maxValue = 500,
            valueStep = 1,
            get = function()
                return cfg().y or 0
            end,
            set = function(_layoutName, value)
                cfg().y = value
                onChanged()
            end,
            formatter = function(value)
                return string.format("%d px", value)
            end,
        },
    }

    return settings
end
