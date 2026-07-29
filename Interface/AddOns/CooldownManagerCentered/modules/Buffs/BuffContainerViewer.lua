local _, ns = ...

-- Custom buff containers: movable Edit Mode frames that own no icons of their own.
-- The native BuffIconCooldownViewer icon frames stay Blizzard-managed children of
-- that viewer; cooldownManager.lua partitions the visible ones by assignment and
-- calls container:LayoutIcons(group, total) so each container re-anchors + centers its
-- buffs within a footprint sized to its total assigned set. Containers with no
-- currently visible entries keep their layout size but hide their Edit Mode anchor.
-- Each frame is CENTER anchored. Orientation, icon direction, padding, size, and
-- alignment are configured independently for each container.
local BuffContainerViewer = {}
ns.BuffContainerViewer = BuffContainerViewer

local BuffData = ns.BuffData
local WilduUICore = ns.WilduUICore
local LEM = LibStub("WildForkLibEQOLEditMode-1.0")

local DEFAULT_ICON_PADDING = 2
local DEFAULT_ICON_SIZE = 1
local MIN_EMPTY_SIZE = 30

-- Colored "Cooldown Manager Centered" gradient reused as the Edit Mode label prefix.
local NAME_PREFIX =
    "|cff008945Cool|r|cff1e9a4e|r|cff3faa4fdown Ma|r|cff5fb64anag|r|cff7ac243er Ce|r|cff8ccd00ntered|r"

local function GetDisplayName(index)
    return NAME_PREFIX .. " Buffs " .. index
end

---@param configKey string
---@return CMCEditModeFrameConfig?
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

local function SetFrameSizeIfChanged(frame, width, height)
    local currentWidth, currentHeight = frame:GetSize()
    if currentWidth ~= width or currentHeight ~= height then
        frame:SetSize(width, height)
    end
end

local function PositionNativeFrame(frame, anchor, point, x, y, scale)
    frame:SetScale(scale)
    frame:ClearAllPoints()
    frame:SetPoint(point, anchor, point, x, y)
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
        hasVisibleEntries = false,
        anchor = nil,
    }, ContainerInstance)
end

function ContainerInstance:SetHasVisibleEntries(hasVisibleEntries)
    local hadVisibleEntries = self.hasVisibleEntries
    self.hasVisibleEntries = hasVisibleEntries == true
    if not self.anchor then
        return
    end

    local shouldShow = self.active and self.hasVisibleEntries
    if LEM.SetFrameOverlayToggleEnabled then
        LEM:SetFrameOverlayToggleEnabled(self.anchor, shouldShow)
    end

    -- Edit Mode moves unavailable frames off-screen. Restore the saved position if
    -- this container gains visible contents while Edit Mode is still open.
    if shouldShow and not hadVisibleEntries then
        self.anchor._wt_hideOnEditModeExit = nil
        WilduUICore.ApplyFramePosition(self.anchor, self.configKey, false)
    end
    self.anchor:SetShown(shouldShow)
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

function ContainerInstance:GetIconSize()
    return GetConfigValue(self.configKey, "iconSize", DEFAULT_ICON_SIZE)
end

function ContainerInstance:GetAlignment()
    local alignment = GetConfigValue(self.configKey, "alignment", nil)
    if alignment == nil then
        alignment = ns.db.profile.cooldownManager_alignBuffIcons_growFromDirection
    end
    return alignment or "CENTER"
end

-- Anchors the given native buff icon frames into this container and sizes the
-- container to fit them. The footprint is sized to `total` (all buffs assigned to the
-- container, active or not). Dynamic alignments position the visible group within that
-- footprint; Disabled preserves every assigned buff's original slot. When nothing is
-- assigned the container keeps a minimal hidden footprint. Returns whether the
-- container currently shows any buffs.
function ContainerInstance:LayoutIcons(iconFrames, total)
    if not self.anchor then
        return false
    end
    local count = iconFrames and #iconFrames or 0
    total = math.max(total or count, count)

    local iconScale = self:GetIconSize()

    if total == 0 then
        SetFrameSizeIfChanged(self.anchor, MIN_EMPTY_SIZE, MIN_EMPTY_SIZE)
        self:SetHasVisibleEntries(false)
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
        SetFrameSizeIfChanged(self.anchor, MIN_EMPTY_SIZE, MIN_EMPTY_SIZE)
        self:SetHasVisibleEntries(count > 0)
        return count > 0
    end

    local padding = self:GetIconPadding()
    local orientation = self:GetOrientation()
    local reversed = self:GetIconDirection() == "Reversed"
    local alignment = self:GetAlignment()

    -- Offset the visible icons within the stable `total`-slot footprint. Disabled
    -- preserves gaps left by inactive assigned buffs rather than packing the group.
    local missing = total - count
    local function GetInset(step)
        if alignment == "END" then
            return missing * step
        elseif alignment == "CENTER" then
            return (missing / 2) * step
        end
        return 0
    end

    if orientation == "Vertical" then
        local step = h + padding
        local inset = GetInset(step)
        SetFrameSizeIfChanged(self.anchor, w * iconScale, (total * h + (total - 1) * padding) * iconScale)
        for i, icon in ipairs(iconFrames) do
            local position = alignment == "Disable" and (ns.API.Affected(icon).buffContainerSlot or i) or i
            if reversed then
                PositionNativeFrame(icon, self.anchor, "BOTTOM", 0, inset + (position - 1) * step, iconScale)
            else
                PositionNativeFrame(icon, self.anchor, "TOP", 0, -(inset + (position - 1) * step), iconScale)
            end
        end
    else
        local step = w + padding
        local inset = GetInset(step)
        SetFrameSizeIfChanged(self.anchor, (total * w + (total - 1) * padding) * iconScale, h * iconScale)
        for i, icon in ipairs(iconFrames) do
            local position = alignment == "Disable" and (ns.API.Affected(icon).buffContainerSlot or i) or i
            if reversed then
                PositionNativeFrame(icon, self.anchor, "RIGHT", -(inset + (position - 1) * step), 0, iconScale)
            else
                PositionNativeFrame(icon, self.anchor, "LEFT", inset + (position - 1) * step, 0, iconScale)
            end
        end
    end
    self:SetHasVisibleEntries(count > 0)
    return count > 0
end

-- Custom auras are permanent layout participants because their secure visibility
-- cannot be inspected. Visible native buffs are packed around those permanent
-- participants and aligned within the stable footprint of every assigned entry.
function ContainerInstance:LayoutEntries(entries, visibleNativeFrames, customAuraProvider)
    if not self.anchor then
        return false
    end

    local total = entries and #entries or 0
    if total == 0 then
        SetFrameSizeIfChanged(self.anchor, MIN_EMPTY_SIZE, MIN_EMPTY_SIZE)
        self:SetHasVisibleEntries(false)
        return false
    end

    local w, h = ns.Sizes.GetViewerIconSize("BuffIcons")
    if not w or w == 0 or not h or h == 0 then
        SetFrameSizeIfChanged(self.anchor, MIN_EMPTY_SIZE, MIN_EMPTY_SIZE)
        self:SetHasVisibleEntries(false)
        return false
    end

    local iconScale = self:GetIconSize()
    local padding = self:GetIconPadding()
    local orientation = self:GetOrientation()
    local reversed = self:GetIconDirection() == "Reversed"
    -- LayoutEntries is used only for containers containing custom auras. Their
    -- secure visibility cannot be inspected, so every entry keeps its persistent
    -- slot regardless of the centering setting.
    local layoutItems = {}
    for slotIndex, entry in ipairs(entries) do
        local frame = entry.custom and customAuraProvider:GetFrame(entry.stableKey)
            or visibleNativeFrames[entry.stableKey]
        if frame then
            layoutItems[#layoutItems + 1] = {
                frame = frame,
                custom = entry.custom == true,
                preview = entry.custom and customAuraProvider:GetPreview(entry.stableKey) or nil,
                slotIndex = slotIndex,
                stableKey = entry.stableKey,
            }
        end
    end

    local count = #layoutItems
    local step
    if orientation == "Vertical" then
        step = h + padding
        SetFrameSizeIfChanged(self.anchor, w * iconScale, (total * h + (total - 1) * padding) * iconScale)
    else
        step = w + padding
        SetFrameSizeIfChanged(self.anchor, (total * w + (total - 1) * padding) * iconScale, h * iconScale)
    end

    for _, item in ipairs(layoutItems) do
        local offset = (item.slotIndex - 1) * step
        local point, x, y
        if orientation == "Vertical" then
            point = reversed and "BOTTOM" or "TOP"
            x = 0
            y = reversed and offset or -offset
        else
            point = reversed and "RIGHT" or "LEFT"
            x = reversed and -offset or offset
            y = 0
        end
        if item.custom then
            customAuraProvider:PositionFrame(item.stableKey, self.anchor, point, x, y, iconScale)
        else
            PositionNativeFrame(item.frame, self.anchor, point, x, y, iconScale)
        end
        if item.preview then
            local strata = self.anchor:GetFrameStrata()
            local level = self.anchor:GetFrameLevel() + 1
            if item.preview:GetFrameStrata() ~= strata then
                item.preview:SetFrameStrata(strata)
            end
            if item.preview:GetFrameLevel() ~= level then
                item.preview:SetFrameLevel(level)
            end
            PositionNativeFrame(item.preview, self.anchor, point, x, y, iconScale)
        end
    end
    self:SetHasVisibleEntries(count > 0)
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
        iconSize = DEFAULT_ICON_SIZE,
    }
    WilduUICore.LoadFrameConfig(self.configKey, DEFAULT_CONFIG)

    self.anchor = CreateFrame("Frame", self.frameName, UIParent, "BackdropTemplate")
    self.anchor.editModeName = self.editModeName
    self.anchor:SetSize(MIN_EMPTY_SIZE, MIN_EMPTY_SIZE)
    self.anchor:SetClampedToScreen(true)

    WilduUICore.ApplyFramePosition(self.anchor, self.configKey, false)

    WilduUICore.RegisterEditModeCallbacks(self.anchor, self.configKey, function()
        return self.active and self.hasVisibleEntries
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
            name = "Alignment",
            parentId = "layout",
            kind = LEM.SettingType.Dropdown,
            default = "Default",
            isEnabled = function()
                return not BuffData.ContainerHasCustomAura(instance.index)
            end,
            get = function()
                return GetConfigValue(configKey, "alignment", nil) or "Default"
            end,
            set = function(_layoutName, value)
                ns.db.profile.editMode[configKey].alignment = value ~= "Default" and value or nil
                RefreshLayout()
            end,
            values = {
                { text = "Use |cff8ccd00Default|r", value = "Default" },
                { text = "Grow from the |cff8ccd00Start|r", value = "START" },
                { text = "Grow from |cff8ccd00Center|r", value = "CENTER" },
                { text = "Grow from the |cff8ccd00End|r", value = "END" },
                { text = "|cffff2020Disable|r centering", value = "Disable" },
            },
        },
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
            name = "Icon Size",
            parentId = "layout",
            kind = LEM.SettingType.Slider,
            default = DEFAULT_ICON_SIZE,
            get = function()
                return instance:GetIconSize()
            end,
            set = function(_layoutName, value)
                ns.db.profile.editMode[configKey].iconSize = value
                RefreshLayout()
            end,
            minValue = 0.5,
            maxValue = 2,
            valueStep = 0.05,
            formatter = function(value)
                return string.format("%.0f%%", value * 100)
            end,
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
        LEM:SetFrameOverlayToggleEnabled(self.anchor, active and self.hasVisibleEntries)
    end
    self.anchor:SetShown(active and self.hasVisibleEntries)
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
    if ns.CustomAuraProvider then
        ns.CustomAuraProvider:SetEnabled(false)
    end
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
    BuffData.ReconcileContainerCount()
    self:EnsureContainers()
    if ns.CustomAuraProvider then
        ns.CustomAuraProvider:SyncDefinitions(BuffData.GetCustomAuraDefinitions())
    elseif ns.CooldownManager then
        ns.CooldownManager.ForceRefresh({ icons = true })
    end
end

function BuffContainerViewer:Initialize()
    if not BuffData.IsEnabled() then
        return
    end
    BuffData.ReconcileContainerCount()
    self:EnsureContainers()
    if ns.CustomAuraProvider then
        ns.CustomAuraProvider:Initialize(BuffData.GetCustomAuraDefinitions())
    end
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
    BuffData.ReconcileContainerCount()
    BuffContainerViewer:EnsureContainers()
    if ns.CooldownManager then
        ns.CooldownManager.ForceRefresh({ icons = true })
    end
    local settings = _G["CooldownViewerSettings"]
    if settings and ns.BuffAssignmentPanel and settings:IsShown() then
        ns.BuffAssignmentPanel:RefreshPanel()
    end
end)
