local _, ns = ...

local CooldownManager = {}
ns.CooldownManager = CooldownManager

local UpdateBuffIcons, UpdateBuffBars, UpdateCDViewer
local pendingSizeRefreshParts = {}
local protectedSizeRefreshFrame = CreateFrame("Frame")

local function QueueProtectedSizeRefresh(part)
    if not part then
        return
    end
    pendingSizeRefreshParts[part] = true
    protectedSizeRefreshFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

protectedSizeRefreshFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")

    local parts = pendingSizeRefreshParts
    pendingSizeRefreshParts = {}
    CooldownManager.ForceRefresh(parts)
end)

local function CanSetNativeFrameSize(frame, refreshPart)
    if C_RestrictedActions.CheckAllowProtectedFunctions(frame, true) then
        return true
    end

    QueueProtectedSizeRefresh(refreshPart)
    return false
end

local function GetViewerSizeRefreshPart(viewer)
    if viewer == EssentialCooldownViewer then
        return "essential"
    elseif viewer == UtilityCooldownViewer then
        return "utility"
    elseif viewer == BuffIconCooldownViewer then
        return "icons"
    end
end

local function BuildOffsets(count, step, direction, leadingSlots)
    local offsets = {}
    local start = (leadingSlots or 0) * step * direction
    for i = 1, count do
        offsets[i] = start + (i - 1) * step * direction
    end
    return offsets
end

local function BuildCenteredOffsets(count, size, padding, direction, limit)
    return BuildOffsets(count, size + padding, direction, (limit - count) / 2)
end

local function BuildRows(children, limit)
    local rows = {}
    for i = 1, #children do
        local rowIndex = math.floor((i - 1) / limit) + 1
        rows[rowIndex] = rows[rowIndex] or {}
        rows[rowIndex][#rows[rowIndex] + 1] = children[i]
    end
    return rows
end

local function SortByLayoutIndex(a, b)
    return (a.layoutIndex or 0) < (b.layoutIndex or 0)
end

local function SortBuffFrames(frames, useCustomOrder)
    if useCustomOrder then
        ns.BuffData.SortCooldownFrames(frames)
    else
        table.sort(frames, SortByLayoutIndex)
    end
end

local function AppendGroup(groups, index, value)
    local group = groups[index]
    if not group then
        group = {}
        groups[index] = group
    end
    group[#group + 1] = value
end
local function CollectBuffIcons()
    local baseVisible, baseTotal = {}, 0
    local containerVisible, containerTotal = {}, {}
    local containerAssigned = {}
    local visibleNativeFrames = {}
    if not BuffIconCooldownViewer then
        return baseVisible, baseTotal, containerVisible, containerTotal, visibleNativeFrames
    end
    local buffsEnabled = ns.BuffData and ns.BuffData.IsEnabled()
    local children = BuffIconCooldownViewer:GetItemFrames()
    for _, child in ipairs(children) do
        if (child.icon or child.Icon) and child.layoutIndex ~= nil then
            ns.API.Affected(child).buffContainerSlot = nil
            if not ns.API:GetIsAffected(child, "cooldownManagerHooked") then
                ns.API:SetAffected(child, "cooldownManagerHooked")
                hooksecurefunc(child, "OnActiveStateChanged", UpdateBuffIcons)
            end

            local containerIndex = nil
            local stableKey = nil
            if buffsEnabled then
                local cooldownID = child.cooldownID or (child.GetCooldownID and child:GetCooldownID())
                stableKey = cooldownID and ns.BuffData.GetStableKeyForCooldownID(cooldownID) or nil
                containerIndex = cooldownID and ns.BuffData.GetContainerForCooldownID(cooldownID) or nil
            end

            local isShown = child:IsShown()
            if stableKey and isShown then
                visibleNativeFrames[stableKey] = child
            end

            if containerIndex then
                containerTotal[containerIndex] = (containerTotal[containerIndex] or 0) + 1
                AppendGroup(containerAssigned, containerIndex, child)
                if isShown then
                    AppendGroup(containerVisible, containerIndex, child)
                end
            else
                baseTotal = baseTotal + 1
                if isShown then
                    baseVisible[#baseVisible + 1] = child
                end
            end
        end
    end

    SortBuffFrames(baseVisible, buffsEnabled)
    for _, assigned in pairs(containerAssigned) do
        SortBuffFrames(assigned, buffsEnabled)
        for slot, child in ipairs(assigned) do
            ns.API.Affected(child).buffContainerSlot = slot
        end
    end
    for _, group in pairs(containerVisible) do
        SortBuffFrames(group, buffsEnabled)
    end
    return baseVisible, baseTotal, containerVisible, containerTotal, visibleNativeFrames
end

local function CollectVisibleBuffBars()
    if not BuffBarCooldownViewer then
        return {}
    end

    local active = {}
    for _, frame in ipairs(BuffBarCooldownViewer:GetItemFrames()) do
        if frame:IsShown() and frame:IsVisible() then
            active[#active + 1] = frame
        end
        if
            not ns.API:GetIsAffected(frame, "cooldownManagerHooked")
            and (frame.icon or frame.Icon or frame.bar or frame.Bar)
        then
            ns.API:SetAffected(frame, "cooldownManagerHooked")
            hooksecurefunc(frame, "OnActiveStateChanged", UpdateBuffBars)
            hooksecurefunc(frame, "OnUnitAuraAddedEvent", UpdateBuffBars)
            hooksecurefunc(frame, "OnUnitAuraRemovedEvent", UpdateBuffBars)
        end
    end
    table.sort(active, SortByLayoutIndex)
    return active
end

local function LayoutBaseBuffRow(icons, total, forceLayout)
    local count = #icons
    if count == 0 then
        return
    end

    local refIcon = icons[1]
    local iconWidth = refIcon:GetWidth()
    local iconHeight = refIcon:GetHeight()
    if not iconWidth or iconWidth == 0 or not iconHeight or iconHeight == 0 then
        return
    end

    local isHorizontal = BuffIconCooldownViewer.isHorizontal ~= false
    local iconDirection = BuffIconCooldownViewer.iconDirection == 1 and "NORMAL" or "REVERSED"

    local alignment = ns.db.profile.cooldownManager_alignBuffIcons_growFromDirection or "CENTER"
    if forceLayout and alignment == "Disable" then
        alignment = "CENTER"
    end
    local padding = isHorizontal and BuffIconCooldownViewer.childXPadding or BuffIconCooldownViewer.childYPadding

    local iconScale = BuffIconCooldownViewer.iconScale or 1
    for _, icon in ipairs(icons) do
        icon:SetScale(iconScale)
    end

    if isHorizontal then
        local direction = iconDirection == "NORMAL" and 1 or -1
        local anchor = iconDirection == "NORMAL" and "TOPLEFT" or "TOPRIGHT"
        local offsets
        if alignment == "START" then
            offsets = BuildOffsets(count, iconWidth + padding, direction)
        elseif alignment == "END" then
            offsets = BuildOffsets(count, iconWidth + padding, -direction)
            anchor = iconDirection == "NORMAL" and "TOPRIGHT" or "TOPLEFT"
        else
            local limit = forceLayout and count or total
            offsets = BuildCenteredOffsets(count, iconWidth, padding, direction, limit)
        end

        for i, icon in ipairs(icons) do
            icon:ClearAllPoints()
            icon:SetPoint(anchor, BuffIconCooldownViewer, anchor, offsets[i], 0)
        end
    else
        local direction = iconDirection == "NORMAL" and -1 or 1
        local anchor = iconDirection == "NORMAL" and "BOTTOMLEFT" or "TOPLEFT"
        local offsets
        if alignment == "START" then
            offsets = BuildOffsets(count, iconHeight + padding, -direction)
        elseif alignment == "END" then
            offsets = BuildOffsets(count, iconHeight + padding, direction)
            anchor = iconDirection == "NORMAL" and "TOPLEFT" or "BOTTOMLEFT"
        else
            local limit = forceLayout and count or total
            offsets = BuildCenteredOffsets(count, iconHeight, padding, -direction, limit)
        end

        for i, icon in ipairs(icons) do
            icon:ClearAllPoints()
            icon:SetPoint(anchor, BuffIconCooldownViewer, anchor, 0, offsets[i])
        end
    end

    if forceLayout then
        local targetWidth, targetHeight
        if isHorizontal then
            targetWidth = (count * iconWidth + (count - 1) * padding) * iconScale
            targetHeight = iconHeight * iconScale
        else
            targetWidth = iconWidth * iconScale
            targetHeight = (count * iconHeight + (count - 1) * padding) * iconScale
        end
        local currentWidth = BuffIconCooldownViewer:GetWidth() or 0
        local currentHeight = BuffIconCooldownViewer:GetHeight() or 0
        if math.abs(currentWidth - targetWidth) >= 2 or math.abs(currentHeight - targetHeight) >= 2 then
            if CanSetNativeFrameSize(BuffIconCooldownViewer, "icons") then
                BuffIconCooldownViewer:SetSize(targetWidth, targetHeight)
            end
        end
    end
end

UpdateBuffIcons = function()
    if not ns.Runtime:IsReady(BuffIconCooldownViewer) then
        return
    end
    local buffsEnabled = ns.BuffData and ns.BuffData.IsEnabled()
    local baseDisabled = ns.db.profile.cooldownManager_alignBuffIcons_growFromDirection == "Disable"

    if baseDisabled and not buffsEnabled then
        return
    end

    local baseVisible, baseTotal, containerVisible, containerTotal, visibleNativeFrames = CollectBuffIcons()

    if buffsEnabled and ns.BuffContainerViewer then
        for i = 1, ns.BuffData.GetContainerCount() do
            local container = ns.BuffContainerViewer:GetContainer(i)
            if container and container.active then
                if ns.CustomAuraProvider and ns.BuffData.ContainerHasCustomAura(i) then
                    local entries = ns.BuffData.GetBuffsForContainer(i)
                    container:LayoutEntries(entries, visibleNativeFrames, ns.CustomAuraProvider)
                else
                    container:LayoutIcons(containerVisible[i] or {}, containerTotal[i] or 0)
                end
            end
        end
    end

    if #baseVisible > 0 then
        LayoutBaseBuffRow(baseVisible, baseTotal, buffsEnabled)
    end
end

UpdateBuffBars = function()
    if not ns.Runtime:IsReady(BuffBarCooldownViewer) then
        return
    end

    local bars = CollectVisibleBuffBars()
    if #bars == 0 then
        return
    end

    local growSetting = ns.db.profile.cooldownManager_alignBuffBars_growFromDirection

    if growSetting == "Disable" then
        return
    end

    local barHeight = bars[1]:GetHeight()
    local spacing = BuffBarCooldownViewer.childYPadding or 0
    if not barHeight or barHeight == 0 then
        return
    end

    local growFromBottom = growSetting == "BOTTOM"

    for index, bar in ipairs(bars) do
        local offsetIndex = index - 1
        local y = growFromBottom and offsetIndex * (barHeight + spacing) or -offsetIndex * (barHeight + spacing)

        bar:ClearAllPoints()
        if growFromBottom then
            bar:SetPoint("BOTTOM", BuffBarCooldownViewer, "BOTTOM", 0, y)
        else
            bar:SetPoint("TOP", BuffBarCooldownViewer, "TOP", 0, y)
        end
    end
end

local weirdSpellsWithoutGCD = {
    [198793] = true, -- Vengeful Retreat
    [195072] = true, -- Fel Rush
    [232893] = true, -- Felblade
    [102401] = true, -- Wild Charge
    [106839] = true, -- Skull Bash
    [358267] = true, -- Hover
}

local function RestoreAlpha(viewer)
    for _, child in ipairs(viewer:GetItemFrames()) do
        if child.Icon then
            child:SetAlpha(1)
            local affected = ns.API.Affected(child)
            affected.utilityAppliedAlpha = nil
            affected.utilityCooldownActive = nil
        end
    end
end

local function WatchUtilityCooldownDone(child, affected)
    local cooldownFrame = child.Cooldown
    if not cooldownFrame or affected.utilityCooldownDoneFrame == cooldownFrame then
        return
    end

    affected.utilityCooldownDoneFrame = cooldownFrame
    cooldownFrame:HookScript("OnCooldownDone", function()
        C_Timer.After(0.1, function()
            CooldownManager.UpdateUtilityDimming()
        end)
    end)
end

local function ApplyUtilityAlphaState(child, affected, active, opacity)
    local stateChanged = affected.utilityCooldownActive ~= active
    affected.utilityCooldownActive = active
    local alpha = active and 1 or opacity
    if affected.utilityAppliedAlpha ~= alpha then
        affected.utilityAppliedAlpha = alpha
        child:SetAlpha(alpha)
    end
    return stateChanged
end

local function SetUtilityAlpha(child, opacity)
    if not child.cooldownID then
        return
    end

    local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(child.cooldownID)
    if not info then
        return
    end

    local affected = ns.API.Affected(child)
    local spellID = info.overrideSpellID or info.spellID
    affected.utilityMoveToEnd = weirdSpellsWithoutGCD[info.spellID] == true

    local charges = C_Spell.GetSpellCharges(spellID)
    if charges and charges.maxCharges > 1 and charges.isActive then
        WatchUtilityCooldownDone(child, affected)
        return ApplyUtilityAlphaState(child, affected, true, opacity)
    end

    local cooldown = spellID and C_Spell.GetSpellCooldown(spellID)
    if not cooldown or cooldown.isOnGCD then
        return ApplyUtilityAlphaState(child, affected, false, opacity)
    end

    if not cooldown.isActive then
        return ApplyUtilityAlphaState(child, affected, false, opacity)
    end

    if cooldown.isOnGCD == nil and weirdSpellsWithoutGCD[spellID] then
        return ApplyUtilityAlphaState(child, affected, false, opacity)
    end
    WatchUtilityCooldownDone(child, affected)
    return ApplyUtilityAlphaState(child, affected, true, opacity)
end

local function ShouldFilterUtilityLayout()
    if not ns.db.profile.cooldownManager_utility_dimWhenNotOnCD then
        return false
    end
    if (ns.db.profile.cooldownManager_utility_dimOpacity or 0) > 0 then
        return false
    end
    return not (ns.Runtime.isInEditMode or ns.Runtime.hasSettingsOpened)
end

local function GetUtilityRuntimeLayoutIndex(child)
    local affected = ns.API.Affected(child)
    return affected.utilitySortIndex or (child.layoutIndex or 0), affected.utilitySortMoved == true
end

local function SortUtilityRuntimeLayout(a, b)
    local aIndex, aMoved = GetUtilityRuntimeLayoutIndex(a)
    local bIndex, bMoved = GetUtilityRuntimeLayoutIndex(b)
    if aIndex ~= bIndex then
        return aIndex < bIndex
    end
    if aMoved ~= bMoved then
        return not aMoved
    end
    return (a.layoutIndex or 0) < (b.layoutIndex or 0)
end

local function UpdateUtilityDimming(forceLayout)
    local viewer = UtilityCooldownViewer
    if not viewer then
        return
    end
    if not ns.db.profile.cooldownManager_utility_dimWhenNotOnCD then
        if ns.API:GetIsAffected(viewer, "dimmed") then
            ns.API:UnsetAffected(viewer, "dimmed")
            RestoreAlpha(viewer)
        end
        return
    end

    local wasDimmed = ns.API:GetIsAffected(viewer, "dimmed")
    local forceVisible = ns.Runtime and (ns.Runtime.isInEditMode or ns.Runtime.hasSettingsOpened)
    local opacity = ns.db.profile.cooldownManager_utility_dimOpacity or 0
    local layoutChanged = false
    for _, child in ipairs(viewer:GetItemFrames()) do
        if child:IsShown() and child.Icon then
            if forceVisible then
                local affected = ns.API.Affected(child)
                if affected.utilityAppliedAlpha ~= 1 then
                    affected.utilityAppliedAlpha = 1
                    child:SetAlpha(1)
                end
            else
                layoutChanged = SetUtilityAlpha(child, opacity) or layoutChanged
            end
        end
    end
    ns.API:SetAffected(viewer, "dimmed")
    if ShouldFilterUtilityLayout() and (forceLayout or layoutChanged or not wasDimmed) then
        UpdateCDViewer(viewer, ns.db.profile.cooldownManager_centerUtility_growFromDirection)
    end
end

local utilityDimmingPending = false
local function RunUtilityDimming()
    utilityDimmingPending = false
    UpdateUtilityDimming()
end
local function RequestUtilityDimming()
    if utilityDimmingPending then
        return
    end
    utilityDimmingPending = true
    C_Timer.After(0.05, RunUtilityDimming)
end

local function CollectVisibleIcons(viewer)
    local visible = {}
    local filterInactiveUtility = viewer == UtilityCooldownViewer and ShouldFilterUtilityLayout()
    for _, child in ipairs(ns.API:GetViewerItemFrames(viewer)) do
        if filterInactiveUtility then
            local affected = ns.API.Affected(child)
            affected.utilitySortMoved = affected.utilityMoveToEnd == true
            affected.utilitySortIndex = (child.layoutIndex or 0) + (affected.utilitySortMoved and 50 or 0)
        end
        if
            child:IsShown()
            and child.Icon
            and child.layoutIndex
            and (not filterInactiveUtility or ns.API.Affected(child).utilityCooldownActive == true)
        then
            visible[#visible + 1] = child
        end
    end
    table.sort(visible, filterInactiveUtility and SortUtilityRuntimeLayout or SortByLayoutIndex)
    return visible
end

local function SetPointIfChanged(icon, viewer, anchor, x, y)
    local point, relativeTo, relativePoint, oldX, oldY = icon:GetPoint()
    if
        point == anchor
        and relativeTo == viewer
        and relativePoint == anchor
        and oldX
        and oldY
        and math.abs(x - oldX) < 1
        and math.abs(y - oldY) < 1
    then
        return
    end

    icon:ClearAllPoints()
    icon:SetPoint(anchor, viewer, anchor, x, y)
end

local function PositionRowHorizontal(viewer, row, yOffset, w, padding, iconDirectionModifier, rowAnchor, iconLimit)
    local xOffsets = BuildCenteredOffsets(#row, w, padding, iconDirectionModifier, iconLimit)
    for i, icon in ipairs(row) do
        SetPointIfChanged(icon, viewer, rowAnchor, xOffsets[i], yOffset)
    end
end

local function PositionRowVertical(viewer, row, xOffset, h, padding, iconDirectionModifier, colAnchor, iconLimit)
    local yOffsets = BuildCenteredOffsets(#row, h, padding, -iconDirectionModifier, iconLimit)
    for i, icon in ipairs(row) do
        SetPointIfChanged(icon, viewer, colAnchor, xOffset, yOffsets[i])
    end
end

local function UpdateViewerSizeIfChanged(viewer, children)
    children = children or CollectVisibleIcons(viewer)
    if #children == 0 then
        return
    end

    local top, right = -math.huge, -math.huge
    local bottom, left = math.huge, math.huge
    for _, child in ipairs(children) do
        local scale = child:GetEffectiveScale() / viewer:GetEffectiveScale()
        top = math.max(top, (child:GetTop() or 0) * scale)
        right = math.max(right, (child:GetRight() or 0) * scale)
        bottom = math.min(bottom, (child:GetBottom() or 0) * scale)
        left = math.min(left, (child:GetLeft() or 0) * scale)
    end

    local targetWidth = right - left
    local targetHeight = top - bottom
    if math.abs(viewer:GetWidth(true) - targetWidth) >= 2 or math.abs(viewer:GetHeight(true) - targetHeight) >= 2 then
        if not CanSetNativeFrameSize(viewer, GetViewerSizeRefreshPart(viewer)) then
            return
        end
        viewer:SetSize(targetWidth, targetHeight)
        return true
    end
end

local function UpdateViewerSize(viewer, children)
    UpdateViewerSizeIfChanged(viewer, children)
end

local function UpdateEssential()
    UpdateCDViewer(EssentialCooldownViewer, ns.db.profile.cooldownManager_centerEssential_growFromDirection)
end

local function UpdateUtility()
    UpdateCDViewer(UtilityCooldownViewer, ns.db.profile.cooldownManager_centerUtility_growFromDirection)
    RequestUtilityDimming()
end

UpdateCDViewer = function(viewer, fromDirection, proxyRelayoutPass)
    if not ns.Runtime:IsReady(viewer) then
        return
    end

    local isHorizontal = viewer.isHorizontal ~= false
    local iconDirection = viewer.iconDirection == 1 and "NORMAL" or "REVERSED"
    local iconLimit = viewer.iconLimit or 0
    if iconLimit <= 0 then
        return
    end

    local children = CollectVisibleIcons(viewer)
    local usesEssentialProxy = viewer == EssentialCooldownViewer
        and ns.EssentialCustomTracker
        and #ns.EssentialCustomTracker:GetItemFrames() > 0
    if fromDirection == "Disable" then
        if usesEssentialProxy then
            fromDirection = "TOP"
        else
            return
        end
    end
    if #children == 0 then
        return
    end

    local w, h = children[1]:GetWidth(), children[1]:GetHeight()
    if not w or w == 0 or not h or h == 0 then
        return
    end

    local padding = isHorizontal and viewer.childXPadding or viewer.childYPadding
    if
        viewer == UtilityCooldownViewer
        and ns.db.profile.cooldownManager_limitUtilitySizeToEssential
        and isHorizontal
    then
        local essentialWidth = EssentialCooldownViewer and EssentialCooldownViewer:GetWidth()
        if essentialWidth and essentialWidth > 0 then
            local scale = viewer.iconScale or 1
            local maxIcons = math.floor((essentialWidth + padding * scale) / ((w + padding) * scale))
            if maxIcons > 0 then
                iconLimit = math.max(math.min(iconLimit, maxIcons), math.min(iconLimit, 6))
            end
        end
    end

    local rows = BuildRows(children, iconLimit)
    local maxIcons = math.min(iconLimit, #children)
    local layoutFrame = usesEssentialProxy and ns.EssentialCustomTracker:PrepareLayoutFrame(isHorizontal, fromDirection)
        or viewer

    if isHorizontal then
        local growDirection = fromDirection == "BOTTOM" and 1 or -1
        local iconDirectionModifier = iconDirection == "NORMAL" and 1 or -1
        local rowAnchor = (fromDirection == "BOTTOM" and "BOTTOM" or "TOP")
            .. (iconDirection == "NORMAL" and "LEFT" or "RIGHT")
        for index, row in ipairs(rows) do
            local y = (index - 1) * (h + padding) * growDirection
            PositionRowHorizontal(layoutFrame, row, y, w, padding, iconDirectionModifier, rowAnchor, maxIcons)
        end
    else
        local growDirection = fromDirection == "BOTTOM" and -1 or 1
        local iconDirectionModifier = iconDirection == "NORMAL" and -1 or 1
        local columnAnchor = (iconDirection == "NORMAL" and "BOTTOM" or "TOP")
            .. (fromDirection == "BOTTOM" and "RIGHT" or "LEFT")
        for index, row in ipairs(rows) do
            local x = (index - 1) * (w + padding) * growDirection
            PositionRowVertical(layoutFrame, row, x, h, padding, iconDirectionModifier, columnAnchor, maxIcons)
        end
    end
    if layoutFrame ~= viewer then
        local sizeChanged = UpdateViewerSizeIfChanged(layoutFrame, children)
        if sizeChanged and not proxyRelayoutPass then
            UpdateCDViewer(viewer, fromDirection, true)
        end
    end
    UpdateViewerSize(viewer, children)
end

function CooldownManager.ForceRefresh(parts)
    parts = parts or { icons = true, bars = true, essential = true, utility = true }
    if parts.icons then
        UpdateBuffIcons()
    end
    if parts.bars then
        UpdateBuffBars()
    end
    if parts.essential then
        UpdateEssential()
    end
    if parts.utility then
        UpdateUtility()
    end
end

function CooldownManager.ForceRefreshAll()
    CooldownManager.ForceRefresh()
end

function CooldownManager.UpdateUtilityDimming(force)
    if force then
        UpdateUtilityDimming(true)
        return
    end
    RequestUtilityDimming()
end

function CooldownManager.RestoreUtilityAlpha()
    local viewer = UtilityCooldownViewer
    if viewer then
        RestoreAlpha(viewer)
    end
end

function CooldownManager.Initialize()
    CooldownManager.ForceRefreshAll()
end
