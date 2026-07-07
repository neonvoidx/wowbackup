local _, ns = ...

-- Custom buff containers: movable Edit Mode frames that own no icons of their own.
-- The native BuffIconCooldownViewer icon frames stay Blizzard-managed children of
-- that viewer; cooldownManager.lua partitions the visible ones by assignment and
-- calls container:LayoutIcons(group, total) so each container re-anchors + centers its
-- buffs within a footprint sized to its total assigned set. Each frame is CENTER
-- anchored. Only orientation / icon direction / icon padding are exposed — icon size
-- and opacity are inherited from Blizzard's base buff settings (see plan).
local BuffContainerViewer = {}
ns.BuffContainerViewer = BuffContainerViewer

local BuffData = ns.BuffData
local WilduUICore = ns.WilduUICore
local LEM = LibStub("WildForkLibEQOLEditMode-1.0")

local DEFAULT_ICON_PADDING = 2
local MIN_EMPTY_SIZE = 30

-- Colored "Cooldown Manager Centered" gradient reused as the Edit Mode label prefix.
local NAME_PREFIX =
    "|cff008945Cool|r|cff1e9a4e|r|cff3faa4fdown Ma|r|cff5fb64anag|r|cff7ac243er Ce|r|cff8ccd00ntered|r"

local function GetDisplayName(index)
    return NAME_PREFIX .. " Buffs " .. index
end

local function GetConfig(configKey)
    return ns.db.profile.editMode and ns.db.profile.editMode[configKey]
end

local function GetConfigValue(configKey, key, default)
    local cfg = GetConfig(configKey)
    if cfg and cfg[key] ~= nil then
        return cfg[key]
    end
    return default
end

local ContainerInstance = {}
ContainerInstance.__index = ContainerInstance

function ContainerInstance:New(index)
    return setmetatable({
        index = index,
        configKey = "buffContainer" .. index,
        frameName = "CMCBuffContainer" .. index,
        editModeName = GetDisplayName(index),
        active = false,
        anchor = nil,
    }, ContainerInstance)
end

function ContainerInstance:GetOrientation()
    return GetConfigValue(self.configKey, "orientation", "Horizontal")
end

function ContainerInstance:GetIconDirection()
    return GetConfigValue(self.configKey, "iconDirection", "Normal")
end

function ContainerInstance:GetIconPadding()
    return GetConfigValue(self.configKey, "iconPadding", DEFAULT_ICON_PADDING)
end

-- Anchors the given native buff icon frames into this container and sizes the
-- container to fit them. The footprint is sized to `total` (all buffs assigned to the
-- container, active or not) and the currently-visible icons are centered within it, so
-- the group stays put as individual buffs toggle instead of jumping to just the shown
-- ones. When nothing is assigned the container keeps a minimal selectable box so it can
-- still be picked up in Edit Mode. Returns whether the container currently shows any buffs.
function ContainerInstance:LayoutIcons(iconFrames, total)
    if not self.anchor then
        return false
    end
    local count = iconFrames and #iconFrames or 0
    total = math.max(total or count, count)

    if total == 0 then
        self.anchor:SetSize(MIN_EMPTY_SIZE, MIN_EMPTY_SIZE)
        return false
    end

    -- Prefer a live icon's dimensions; fall back to the known buff-icon size so an
    -- all-hidden (but non-empty) container still keeps its stable total footprint.
    local w, h
    if count > 0 then
        local ref = iconFrames[1]
        w, h = ref:GetWidth(), ref:GetHeight()
    end
    if not w or w == 0 or not h or h == 0 then
        w, h = ns.Sizes.GetViewerIconSize("BuffIcons")
    end
    if not w or w == 0 or not h or h == 0 then
        self.anchor:SetSize(MIN_EMPTY_SIZE, MIN_EMPTY_SIZE)
        return count > 0
    end

    local padding = self:GetIconPadding()
    local orientation = self:GetOrientation()
    local reversed = self:GetIconDirection() == "Reversed"
    -- The icon frames carry the viewer's iconScale as their own scale, so the unscaled
    -- SetPoint offsets already resolve to the correct (scaled) spacing — same as the
    -- base viewer's layout. Only the container frame (a scale-1 UIParent child) must
    -- have iconScale folded into its size so it matches the icons' rendered extent.
    local iconScale = (BuffIconCooldownViewer and BuffIconCooldownViewer.iconScale) or 1

    -- Inset that centers the `count` visible icons inside the `total`-slot footprint.
    local missing = total - count

    if orientation == "Vertical" then
        local step = h + padding
        local inset = (missing / 2) * step
        self.anchor:SetSize(w * iconScale, (total * h + (total - 1) * padding) * iconScale)
        for i, icon in ipairs(iconFrames) do
            icon:ClearAllPoints()
            if reversed then
                icon:SetPoint("BOTTOM", self.anchor, "BOTTOM", 0, inset + (i - 1) * step)
            else
                icon:SetPoint("TOP", self.anchor, "TOP", 0, -(inset + (i - 1) * step))
            end
        end
    else
        local step = w + padding
        local inset = (missing / 2) * step
        self.anchor:SetSize((total * w + (total - 1) * padding) * iconScale, h * iconScale)
        for i, icon in ipairs(iconFrames) do
            icon:ClearAllPoints()
            if reversed then
                icon:SetPoint("RIGHT", self.anchor, "RIGHT", -(inset + (i - 1) * step), 0)
            else
                icon:SetPoint("LEFT", self.anchor, "LEFT", inset + (i - 1) * step, 0)
            end
        end
    end
    return count > 0
end

function ContainerInstance:Create()
    if self.anchor then
        return
    end

    local DEFAULT_CONFIG = {
        alpha = 1,
        point = "CENTER",
        x = 0,
        y = -150,
        scale = 1,
        strata = "MEDIUM",
        orientation = "Horizontal",
        iconDirection = "Normal",
        iconPadding = DEFAULT_ICON_PADDING,
    }
    WilduUICore.LoadFrameConfig(self.configKey, DEFAULT_CONFIG)

    self.anchor = CreateFrame("Frame", self.frameName, UIParent, "BackdropTemplate")
    self.anchor.editModeName = self.editModeName
    self.anchor:SetSize(MIN_EMPTY_SIZE, MIN_EMPTY_SIZE)
    self.anchor:SetClampedToScreen(true)

    WilduUICore.ApplyFramePosition(self.anchor, self.configKey, false)

    WilduUICore.RegisterEditModeCallbacks(self.anchor, self.configKey, function()
        return self.active
    end)

    local configKey = self.configKey
    local anchor = self.anchor
    local instance = self

    -- Containers center their icons within a fixed footprint, so the frame itself stays
    -- CENTER-anchored: moving it keeps the center fixed and size changes (assignments)
    -- grow symmetrically.
    local function OnPositionChanged(frame, layoutName, _point, _x, _y)
        -- Anchored to another frame: its anchor governs position, so ignore the drag and
        -- re-snap to the target instead of storing a free CENTER position.
        if ns.Anchoring and ns.Anchoring:HasTarget(configKey) then
            WilduUICore.ApplyFramePosition(frame, configKey, false)
            return
        end

        local cfg = ns.db.profile.editMode[configKey]

        local centerX, centerY = frame:GetCenter()
        local uiCenterX, uiCenterY = UIParent:GetCenter()
        if not centerX or not centerY or not uiCenterX or not uiCenterY then
            return
        end

        -- Store the frame's center offset from UIParent's center. The container is a
        -- scale-1 UIParent child, so its coordinate space matches UIParent's directly.
        cfg.point = "CENTER"
        cfg.x = centerX - uiCenterX
        cfg.y = centerY - uiCenterY
        WilduUICore.ApplyFramePosition(frame, configKey, false)
    end

    local function RefreshLayout()
        if ns.CooldownManager then
            ns.CooldownManager.ForceRefresh({ icons = true })
        end
    end

    local additionalSettings = {
        { kind = LEM.SettingType.Collapsible, id = "layout", name = "Layout", defaultCollapsed = false },
        {
            name = "Orientation",
            parentId = "layout",
            kind = LEM.SettingType.Dropdown,
            default = "Horizontal",
            get = function()
                return instance:GetOrientation()
            end,
            set = function(_layoutName, value)
                ns.db.profile.editMode[configKey].orientation = value
                OnPositionChanged(anchor, configKey)
                RefreshLayout()
            end,
            values = {
                { text = "Horizontal" },
                { text = "Vertical" },
            },
        },
        {
            name = "Icon Direction",
            parentId = "layout",
            kind = LEM.SettingType.Dropdown,
            default = "Normal",
            get = function()
                return instance:GetIconDirection()
            end,
            set = function(_layoutName, value)
                ns.db.profile.editMode[configKey].iconDirection = value
                OnPositionChanged(anchor, configKey)
                RefreshLayout()
            end,
            values = {
                { text = "Normal" },
                { text = "Reversed" },
            },
        },
        {
            name = "Icon Padding",
            parentId = "layout",
            kind = LEM.SettingType.Slider,
            default = DEFAULT_ICON_PADDING,
            get = function()
                return instance:GetIconPadding()
            end,
            set = function(_layoutName, value)
                ns.db.profile.editMode[configKey].iconPadding = value
                RefreshLayout()
            end,
            minValue = 0,
            maxValue = 20,
            valueStep = 1,
            formatter = function(value)
                return string.format("%d px", value)
            end,
        },
    }

    -- Anchor-to-another-frame section (custom trackers, other buff containers, unit
    -- frames, native CDM viewers). Shared with the custom trackers.
    local anchorSettings = ns.Anchoring:BuildSettings(configKey, {
        selfFrameName = self.frameName,
        onChanged = function()
            WilduUICore.ApplyFramePosition(anchor, configKey, false)
            RefreshLayout()
        end,
    })
    for _, setting in ipairs(anchorSettings) do
        tinsert(additionalSettings, setting)
    end

    -- skipGeneralSection: containers only anchor the native icons, so frame
    -- scale/strata wouldn't affect them — omit that section.
    WilduUICore.RegisterFrameWithLEM(self.anchor, self.configKey, additionalSettings, OnPositionChanged, true)
end

-- Re-applies the saved CENTER position (Create() positions only once) after profile
-- switches / count changes.
function ContainerInstance:ReapplyPosition()
    if not self.anchor then
        return
    end
    WilduUICore.ApplyFramePosition(self.anchor, self.configKey, false)
end

function ContainerInstance:SetActive(active)
    self.active = active
    if not self.anchor then
        return
    end
    if LEM.SetFrameOverlayToggleEnabled then
        LEM:SetFrameOverlayToggleEnabled(self.anchor, active)
    end
    self.anchor:SetShown(active)
end

-- Pool of container instances, indexed 1..N; created lazily and reused (deactivated,
-- not destroyed) when the count shrinks, mirroring the custom-tracker pool.
local containers = {}

local function GetOrCreate(index)
    if not containers[index] then
        containers[index] = ContainerInstance:New(index)
    end
    return containers[index]
end

function BuffContainerViewer:GetContainer(index)
    return containers[index]
end

function BuffContainerViewer:GetActiveContainers()
    local result = {}
    for i = 1, BuffData.GetContainerCount() do
        if containers[i] and containers[i].active then
            result[i] = containers[i]
        end
    end
    return result
end

-- Creates/activates containers 1..count and deactivates any beyond it. Idempotent.
function BuffContainerViewer:EnsureContainers()
    if not BuffData.IsEnabled() then
        return
    end
    local count = BuffData.GetContainerCount()
    for i = 1, count do
        local container = GetOrCreate(i)
        container:Create()
        container:SetActive(true)
    end
    for i = 1, count do
        if containers[i] then
            containers[i]:ReapplyPosition()
        end
    end
    for i = count + 1, #containers do
        if containers[i] then
            containers[i]:SetActive(false)
        end
    end
end

-- Grows/shrinks to keep one empty trailing container and rewires the layout after
-- an assignment change. Returns true if the active count changed.
function BuffContainerViewer:ReconcileContainerCount()
    local before = BuffData.GetContainerCount()
    local desired = BuffData.ReconcileContainerCount()
    self:EnsureContainers()
    if ns.CooldownManager then
        ns.CooldownManager.ForceRefresh({ icons = true })
    end
    return desired ~= before
end

function BuffContainerViewer:HideAll()
    for _, container in ipairs(containers) do
        container:SetActive(false)
    end
    if ns.CooldownManager then
        ns.CooldownManager.ForceRefresh({ icons = true })
    end
end

function BuffContainerViewer:ShowAll()
    if not BuffData.IsEnabled() then
        return
    end
    if ns.CooldownManager then
        ns.CooldownManager.ForceRefresh({ icons = true })
    end
end

function BuffContainerViewer:Initialize()
    if not BuffData.IsEnabled() then
        return
    end
    BuffData.ReconcileContainerCount()
    self:EnsureContainers()
end

-- The cooldownID -> spellID mapping is spec/loadout dependent, so the cached buff
-- scan is dropped on these events; the layout + open settings panel then rebuild
-- against the fresh tracked-buff set.
local invalidationEvents = CreateFrame("Frame")
invalidationEvents:RegisterEvent("COOLDOWN_VIEWER_DATA_LOADED")
invalidationEvents:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
invalidationEvents:RegisterEvent("TRAIT_CONFIG_UPDATED")
invalidationEvents:SetScript("OnEvent", function()
    BuffData.InvalidateScan()
    if not BuffData.IsEnabled() then
        return
    end
    C_Timer.After(0.1, function()
        BuffData.InvalidateScan()
        BuffData.ReconcileContainerCount()
        BuffContainerViewer:EnsureContainers()
        if ns.CooldownManager then
            ns.CooldownManager.ForceRefresh({ icons = true })
        end
        local settings = _G["CooldownViewerSettings"]
        if settings and ns.BuffAssignmentPanel and settings:IsShown() then
            ns.BuffAssignmentPanel:RefreshPanel(settings)
        end
    end)
end)
