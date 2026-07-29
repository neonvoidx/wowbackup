local _, ns = ...

-- AuraContainer and CustomAuraContainerTemplate are new in 12.1. Keep this as a
-- literal module-level return: 12.0.7 must neither touch the missing API nor expose
-- any UI suggesting that custom aura buffs are available.
local interfaceVersion = select(4, GetBuildInfo())
if not interfaceVersion or interfaceVersion < 120100 then
    return
end

local CustomAuraProvider = {}
ns.CustomAuraProvider = CustomAuraProvider

local frames = {}
local visuals = {}
local configurationPreviews = {}
local configurationPreviewVisuals = {}
local controller = nil
local sortMethodDefault = nil
local sortDirectionNormal = nil
local desiredEnabled = false
local desiredDefinitions = {}
local pendingApply = false

local NATIVE_MASK_ATLAS = "UI-HUD-CoolDownManager-Mask"
local NATIVE_OVERLAY_ATLAS = "UI-HUD-CoolDownManager-IconOverlay"
local NATIVE_SWIPE_TEXTURE = "Interface\\HUD\\UI-HUD-CoolDownManager-Icon-Swipe"
local SQUARE_MASK_TEXTURE = "Interface\\AddOns\\CooldownManagerCentered\\Media\\Art\\Square"

local function CopyDefinitions(source)
    local result = {}
    for stableKey, definition in pairs(source or {}) do
        if type(definition) == "table" and tonumber(definition.spellID) then
            result[stableKey] = {
                spellID = tonumber(definition.spellID),
                name = definition.name,
                iconID = definition.iconID,
                stackColor = type(definition.stackColor) == "table"
                        and definition.stackColor[1] ~= nil
                        and definition.stackColor[2] ~= nil
                        and definition.stackColor[3] ~= nil
                        and { definition.stackColor[1], definition.stackColor[2], definition.stackColor[3] }
                    or nil,
            }
        end
    end
    return result
end

local function SetNativeOverlayAnchors(overlay, icon, width, height)
    local ratio = width > 0 and height / width or 1
    overlay:ClearAllPoints()
    overlay:SetPoint("TOPLEFT", icon, "TOPLEFT", -8, 7 * ratio)
    overlay:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 8, -7 * ratio)
end

local function ApplyIconSurfaceStyle(frame, visual, width, height, square)
    local profile = ns.db.profile
    frame:SetSize(width, height)
    visual.icon:ClearAllPoints()
    visual.icon:SetAllPoints(frame)
    visual.mask:ClearAllPoints()
    visual.mask:SetAllPoints(frame)

    local borderThickness = 0
    if square then
        local zoom = profile.cooldownManager_squareIconsZoom_BuffIcons or 0
        local crop = math.max(0, math.min(0.49, zoom * 0.5))
        local ratio = width / height
        if ratio > 1 then
            local horizontalSpan = 1 - 2 * crop
            local verticalSpan = math.max(0, math.min(1, horizontalSpan / ratio))
            local verticalCrop = (1 - verticalSpan) * 0.5
            visual.icon:SetTexCoord(crop, 1 - crop, verticalCrop, 1 - verticalCrop)
        else
            visual.icon:SetTexCoord(crop, 1 - crop, crop, 1 - crop)
        end
        visual.mask:SetTexture(SQUARE_MASK_TEXTURE)
        visual.overlay:SetAlpha(0)
        borderThickness = profile.cooldownManager_squareIconsBorder_BuffIcons or 0
        if borderThickness > 0 then
            borderThickness = ns.Scaling:GetPixelSize(frame) * borderThickness
            visual.border:SetBackdrop({
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = borderThickness,
            })
            visual.border:SetBackdropBorderColor(0, 0, 0, 1)
            visual.border:Show()
        else
            visual.border:Hide()
        end
    else
        visual.icon:SetTexCoord(0, 1, 0, 1)
        visual.mask:SetAtlas(NATIVE_MASK_ATLAS)
        visual.overlay:SetAlpha(1)
        SetNativeOverlayAnchors(visual.overlay, visual.icon, width, height)
        visual.border:Hide()
    end
    return borderThickness
end

local function ShouldShowPreview()
    if ns.Runtime and (ns.Runtime.isInEditMode or ns.Runtime.hasSettingsOpened) then
        return true
    end
    return (EditModeManagerFrame
        and EditModeManagerFrame.IsEditModeActive
        and EditModeManagerFrame:IsEditModeActive()) == true
end

local function ApplyConfigurationPreviewStyle(frame)
    local visual = configurationPreviewVisuals[frame]
    if not visual or not ns.db or not ns.db.profile then
        return
    end

    local width, height = ns.Sizes.GetViewerIconSize("BuffIcons")
    local masqueActive = ns.MasqueModule and ns.MasqueModule:IsActive()
    local square = ns.db.profile.cooldownManager_squareIcons_BuffIcons and not masqueActive
    visual.border:SetFrameLevel(frame:GetFrameLevel() + 1)
    ApplyIconSurfaceStyle(frame, visual, width, height, square)
end

local function GetOrCreateConfigurationPreview(stableKey, definition)
    local preview = configurationPreviews[stableKey]
    if not preview then
        -- This is deliberately separate from the secure AuraContainer slot. It can
        -- show the saved spell texture while the real aura button remains hidden,
        -- without changing protected/forbidden aura state.
        preview = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        preview:EnableMouse(false)
        preview:Hide()

        local icon = preview:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(preview)

        local mask = preview:CreateMaskTexture(nil, "ARTWORK")
        mask:SetAllPoints(preview)
        mask:SetAtlas(NATIVE_MASK_ATLAS)
        icon:AddMaskTexture(mask)

        local overlay = preview:CreateTexture(nil, "OVERLAY")
        overlay:SetAtlas(NATIVE_OVERLAY_ATLAS)

        local border = CreateFrame("Frame", nil, preview, "BackdropTemplate")
        border:SetAllPoints(preview)
        border:SetFrameLevel(preview:GetFrameLevel() + 1)
        border:Hide()

        configurationPreviews[stableKey] = preview
        configurationPreviewVisuals[preview] = {
            icon = icon,
            mask = mask,
            overlay = overlay,
            border = border,
        }
    end

    configurationPreviewVisuals[preview].icon:SetTexture(definition.iconID or 134400)
    ApplyConfigurationPreviewStyle(preview)
    return preview
end

local function ApplyCustomAuraFontStyle(frame, visual)
    local profile = ns.db.profile
    local cooldownFontString = visual.cooldown:GetCountdownFontString()
    if cooldownFontString then
        if not visual.cooldownFontDefaults then
            local path, size, flags = cooldownFontString:GetFont()
            visual.cooldownFontDefaults = { path, size, flags or "" }
        end

        if profile.cooldownManager_cooldownFontSizeBuffIcons_enabled then
            local size = profile.cooldownManager_cooldownFontSizeBuffIcons
            if size == 0 then
                cooldownFontString:SetFontHeight(0)
            else
                if not size or size == "NIL" then
                    size = visual.cooldownFontDefaults[2] or 14
                end
                local fontPath = ns.API:GetFontPath(profile.cooldownManager_cooldownFontName)
                    or visual.cooldownFontDefaults[1]
                cooldownFontString:SetFont(fontPath, size, ns.API:GetFontFlags(profile.cooldownManager_cooldownFontFlags))
            end
            local x = profile.cooldownManager_cooldownTextBuffIcons_offsetX or 0
            local y = profile.cooldownManager_cooldownTextBuffIcons_offsetY or 0
            cooldownFontString:ClearAllPoints()
            cooldownFontString:SetPoint("CENTER", visual.cooldown, "CENTER", x, y)
        else
            cooldownFontString:SetFont(unpack(visual.cooldownFontDefaults))
            cooldownFontString:ClearAllPoints()
            cooldownFontString:SetPoint("CENTER", visual.cooldown, "CENTER", 0, 0)
        end
    end

    local applications = visual.applications
    if not visual.applicationFontDefaults then
        local path, size, flags = applications:GetFont()
        visual.applicationFontDefaults = { path, size, flags or "" }
    end

    applications:ClearAllPoints()
    if profile.cooldownManager_stackAnchorBuffIcons_enabled then
        local size = profile.cooldownManager_stackFontSizeBuffIcons
        if size == 0 then
            applications:SetFontHeight(0)
        else
            if not size or size == "NIL" then
                size = visual.applicationFontDefaults[2] or 14
            end
            local fontPath = ns.API:GetFontPath(profile.cooldownManager_stackFontName)
                or visual.applicationFontDefaults[1]
            applications:SetFont(fontPath, size, ns.API:GetFontFlags(profile.cooldownManager_stackFontFlags))
        end
        local point = profile.cooldownManager_stackAnchorBuffIcons_point or "BOTTOMRIGHT"
        applications:SetPoint(
            point,
            frame,
            point,
            profile.cooldownManager_stackAnchorBuffIcons_offsetX or 0,
            profile.cooldownManager_stackAnchorBuffIcons_offsetY or 0
        )
    else
        applications:SetFont(unpack(visual.applicationFontDefaults))
        applications:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    end

    local definition = visual.stableKey and desiredDefinitions[visual.stableKey]
    local stackColor = definition and definition.stackColor
    if stackColor then
        if not visual.applicationColorDefault then
            visual.applicationColorDefault = { applications:GetTextColor() }
        end
        applications:SetTextColor(stackColor[1], stackColor[2], stackColor[3], 1)
    elseif visual.applicationColorDefault then
        applications:SetTextColor(unpack(visual.applicationColorDefault))
        visual.applicationColorDefault = nil
    end
end

local function ApplyCustomAuraStyle(frame)
    if InCombatLockdown() then
        pendingApply = true
        return false
    end

    local visual = visuals[frame]
    if not visual or not ns.db or not ns.db.profile then
        return
    end

    local profile = ns.db.profile
    local width, height = ns.Sizes.GetViewerIconSize("BuffIcons")
    local masqueActive = ns.MasqueModule and ns.MasqueModule:IsActive()
    local square = profile.cooldownManager_squareIcons_BuffIcons and not masqueActive
    local borderThickness = ApplyIconSurfaceStyle(frame, visual, width, height, square)
    visual.cooldown:SetReverse(true)
    visual.cooldown:SetDrawEdge(false)
    visual.cooldown:SetSwipeColor(0, 0, 0, 0.49)
    if square then
        visual.cooldown:SetSwipeTexture(SQUARE_MASK_TEXTURE, 0, 0, 0, 0.49)
        visual.cooldown:ClearAllPoints()
        visual.cooldown:SetPoint("TOPLEFT", frame, "TOPLEFT", borderThickness, -borderThickness)
        visual.cooldown:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -borderThickness, borderThickness)
    else
        visual.cooldown:SetSwipeTexture(NATIVE_SWIPE_TEXTURE, 0, 0, 0, 0.49)
        visual.cooldown:ClearAllPoints()
        visual.cooldown:SetAllPoints(frame)
    end
    visual.applicationsFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
    visual.border:SetFrameLevel(frame:GetFrameLevel() + 1)
    ApplyCustomAuraFontStyle(frame, visual)
    return true
end

local function InitializeAuraFrame(frame)
    frame:SetSize(40, 40)

    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints(frame)

    local mask = frame:CreateMaskTexture(nil, "ARTWORK")
    mask:SetAllPoints(frame)
    mask:SetAtlas(NATIVE_MASK_ATLAS)
    icon:AddMaskTexture(mask)
    frame:SetIcon(icon)

    local overlay = frame:CreateTexture(nil, "OVERLAY")
    overlay:SetAtlas(NATIVE_OVERLAY_ATLAS)
    SetNativeOverlayAnchors(overlay, icon, 40, 40)

    local cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    cooldown:SetAllPoints(frame)
    cooldown:SetReverse(true)
    cooldown:SetDrawEdge(false)
    cooldown:SetSwipeTexture(NATIVE_SWIPE_TEXTURE, 0, 0, 0, 0.49)
    cooldown:SetSwipeColor(0, 0, 0, 0.49)
    cooldown:SetUseAuraDisplayTime(true)
    frame:SetDurationCooldown(cooldown)

    local applicationsFrame = CreateFrame("Frame", nil, frame)
    applicationsFrame:SetAllPoints(frame)
    applicationsFrame:SetFrameLevel(frame:GetFrameLevel() + 10)
    local applications = applicationsFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    frame:SetApplicationCount(applications)

    local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    border:SetAllPoints(frame)
    border:SetFrameLevel(frame:GetFrameLevel() + 1)
    border:Hide()

    visuals[frame] = {
        icon = icon,
        mask = mask,
        overlay = overlay,
        cooldown = cooldown,
        applications = applications,
        applicationsFrame = applicationsFrame,
        border = border,
    }
    ApplyCustomAuraStyle(frame)
end

local function LoadAuraContainer()
    if C_AddOns.IsAddOnLoaded("Blizzard_AuraContainer") then
        return true
    end
    return C_AddOns.LoadAddOn("Blizzard_AuraContainer") == true
end

local function CreateController()
    if controller then
        return true
    end
    if InCombatLockdown() then
        return false
    end
    if not LoadAuraContainer() then
        return false
    end
    local sortMethods = _G["AuraContainerSortMethod"]
    local sortDirections = _G["AuraContainerSortDirection"]
    if not sortMethods or not sortDirections then
        return false
    end

    sortMethodDefault = sortMethods.Default
    sortDirectionNormal = sortDirections.Normal

    controller = CreateFrame("AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
    controller:SetUnit("player")
    return true
end

local function RegisterDefinition(stableKey, definition)
    if not controller or not definition then
        return nil
    end

    GetOrCreateConfigurationPreview(stableKey, definition)

    local candidateFilters = {
        includeSpellIDs = {
            [definition.spellID] = true,
        },
    }
    if frames[stableKey] then
        controller:SetAuraSlotCandidateFilters(stableKey, candidateFilters)
        return frames[stableKey]
    end

    local frame = controller:AddAuraSlot(stableKey, "HELPFUL", {
        initializeFrame = InitializeAuraFrame,
        candidateFilters = candidateFilters,
        sortMethod = sortMethodDefault,
        sortDirection = sortDirectionNormal,
    })
    frames[stableKey] = frame
    if frame and visuals[frame] then
        visuals[frame].stableKey = stableKey
    end
    return frame
end

local function ApplyDesiredDefinitions()
    for stableKey, frame in pairs(frames) do
        if not desiredDefinitions[stableKey] then
            controller:SetAuraSlotCandidateFilters(stableKey, { includeSpellIDs = {} })
            frame:ClearAllPoints()
            local preview = configurationPreviews[stableKey]
            if preview then
                preview:Hide()
                preview:ClearAllPoints()
            end
        end
    end

    for stableKey, definition in pairs(desiredDefinitions) do
        RegisterDefinition(stableKey, definition)
    end
end

local function DisableController()
    if not controller then
        return
    end
    for stableKey, frame in pairs(frames) do
        controller:SetAuraSlotCandidateFilters(stableKey, { includeSpellIDs = {} })
        frame:ClearAllPoints()
    end
    for _, preview in pairs(configurationPreviews) do
        preview:Hide()
        preview:ClearAllPoints()
    end
    controller:SetEnabled(false)
end

local function ApplyDesiredState()
    if InCombatLockdown() then
        pendingApply = true
        return false
    end

    pendingApply = false
    if desiredEnabled then
        if not CreateController() then
            pendingApply = true
            return false
        end
        ApplyDesiredDefinitions()
        controller:SetEnabled(true)
        for stableKey, frame in pairs(frames) do
            if desiredDefinitions[stableKey] then
                ApplyCustomAuraStyle(frame)
            end
        end
        for stableKey, preview in pairs(configurationPreviews) do
            if desiredDefinitions[stableKey] then
                ApplyConfigurationPreviewStyle(preview)
            end
        end
    else
        DisableController()
    end

    if ns.CooldownManager then
        ns.CooldownManager.ForceRefresh({ icons = true })
    end
    return true
end

local function SetDesiredDefinitions(newDefinitions)
    desiredDefinitions = CopyDefinitions(newDefinitions)
    for stableKey, preview in pairs(configurationPreviews) do
        if not desiredDefinitions[stableKey] then
            preview:Hide()
        end
    end
    pendingApply = true
end

function CustomAuraProvider:Initialize(newDefinitions)
    return self:SyncDefinitions(newDefinitions)
end

function CustomAuraProvider:SyncDefinitions(newDefinitions)
    desiredEnabled = true
    SetDesiredDefinitions(newDefinitions)
    return ApplyDesiredState()
end

function CustomAuraProvider:GetFrame(stableKey)
    return frames[stableKey]
end

function CustomAuraProvider:GetPreview(stableKey)
    local preview = configurationPreviews[stableKey]
    if preview then
        preview:SetShown(desiredEnabled and desiredDefinitions[stableKey] ~= nil and ShouldShowPreview())
    end
    return preview
end

function CustomAuraProvider:RefreshStyles()
    pendingApply = true
    return ApplyDesiredState()
end

function CustomAuraProvider:PositionFrame(stableKey, anchor, point, x, y, scale)
    local frame = frames[stableKey]
    if not frame then
        return false
    end
    if InCombatLockdown() then
        pendingApply = true
        return false
    end
    frame:SetScale(scale)
    frame:ClearAllPoints()
    frame:SetPoint(point, anchor, point, x, y)
    return true
end

function CustomAuraProvider:SetEnabled(enabled)
    desiredEnabled = enabled == true
    if not desiredEnabled then
        SetDesiredDefinitions(nil)
    end
    pendingApply = true
    return ApplyDesiredState()
end

local function SetConfigurationPreviewsShown(shouldShow)
    for stableKey, preview in pairs(configurationPreviews) do
        -- Preview frames are nonsecure, so visibility can still follow /cds while
        -- the real AuraContainer buttons are frozen by combat lockdown.
        preview:SetShown(
            desiredEnabled
                and desiredDefinitions[stableKey] ~= nil
                and shouldShow == true
                and preview:GetNumPoints() > 0
        )
    end
end

EventRegistry:RegisterCallback("EditMode.Enter", function()
    SetConfigurationPreviewsShown(true)
end)
EventRegistry:RegisterCallback("EditMode.Exit", function()
    SetConfigurationPreviewsShown(ns.Runtime and ns.Runtime.hasSettingsOpened == true)
end)
EventRegistry:RegisterCallback("CooldownViewerSettings.OnShow", function()
    if not InCombatLockdown() then
        SetConfigurationPreviewsShown(true)
    end
end)
EventRegistry:RegisterCallback("CooldownViewerSettings.OnHide", function()
    if not InCombatLockdown() then
        SetConfigurationPreviewsShown(ns.Runtime and ns.Runtime.isInEditMode == true)
    end
end)

local combatDeferral = CreateFrame("Frame")
combatDeferral:RegisterEvent("PLAYER_REGEN_ENABLED")
combatDeferral:SetScript("OnEvent", function()
    if pendingApply then
        ApplyDesiredState()
    end
end)
