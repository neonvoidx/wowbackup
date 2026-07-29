local _, ns = ...

local BuffAssignmentPanel = {}
ns.BuffAssignmentPanel = BuffAssignmentPanel
local CMCCooldownViewerSettingsBuffPanel = nil
local CMCCooldownViewerSettingsBuffTab = nil

local BuffData = ns.BuffData
local CustomAuraProvider = ns.CustomAuraProvider

local ITEM_SIZE = 38
local ITEM_SPACING = 8
local STRIDE = 7
local PORTRAIT = "Interface\\Addons\\CooldownManagerCentered\\Media\\CooldownManagerCenteredIcon"
local CUSTOM_AURA_BADGE_ATLAS = "Warfronts-BaseMapIcons-Horde-Barracks"

local draggedEntry = nil
local dragSourceButton = nil
local dragTarget = nil
local dragTargetButton = nil
local dragOffset = 0
local dragEatNextGlobalMouseUp = nil
local dragCursor = nil
local reorderMarker = nil
local contextMenuExtended = false

local function EnsureReorderMarker()
    if reorderMarker then
        return reorderMarker
    end
    reorderMarker = CreateFrame("Frame", nil, BuffAssignmentPanel:GetPanel())
    local texture = reorderMarker:CreateTexture(nil, "OVERLAY")
    texture:SetAllPoints()
    texture:SetAtlas("cdm-vertical", true)
    reorderMarker:SetSize(ITEM_SPACING, ITEM_SIZE)
    reorderMarker:Hide()
    return reorderMarker
end

local function EnsureDragCursor()
    if dragCursor then
        return dragCursor
    end
    dragCursor = CreateFrame("Frame", nil, UIParent)
    dragCursor:SetSize(32, 32)
    dragCursor:SetFrameStrata("TOOLTIP")
    dragCursor:Hide()
    dragCursor.tex = dragCursor:CreateTexture(nil, "OVERLAY")
    dragCursor.tex:SetAllPoints()
    dragCursor:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale + 16, y / scale - 16)
    end)
    return dragCursor
end

local function IsDragging()
    return draggedEntry ~= nil
end

local function SetDragTarget(target)
    if IsDragging() then
        dragTarget = target
    end
end

local function ClearBuffDrag()
    if
        dragSourceButton
        and dragSourceButton.Icon
        and dragSourceButton.buffEntry
        and dragSourceButton.buffEntry.custom
    then
        dragSourceButton.Icon:SetDesaturated(false)
    end
    draggedEntry = nil
    dragSourceButton = nil
    dragTarget = nil
    dragTargetButton = nil
    dragOffset = 0
    dragEatNextGlobalMouseUp = nil
    if dragCursor then
        dragCursor:Hide()
    end
    if reorderMarker then
        reorderMarker:Hide()
    end
    local panel = BuffAssignmentPanel:GetPanel()
    if panel then
        panel:SetScript("OnUpdate", nil)
        panel:UnregisterEvent("GLOBAL_MOUSE_UP")
    end
end

local function UpdateDragMarker()
    local marker = EnsureReorderMarker()
    marker:SetShown(dragTarget ~= nil)
    if not dragTarget then
        return
    end

    local cursorX, cursorY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    cursorX, cursorY = cursorX / scale, cursorY / scale
    dragTargetButton = dragTarget.GetBestCooldownItemTarget and dragTarget:GetBestCooldownItemTarget(cursorX, cursorY)
        or nil
    if not dragTargetButton or not dragTargetButton.UpdateReorderMarkerPosition then
        marker:Hide()
        return
    end
    if draggedEntry and draggedEntry.custom and not dragTargetButton.buffContainerIndex then
        dragTargetButton = nil
        marker:Hide()
        return
    end

    marker:ClearAllPoints()
    dragOffset = dragTargetButton:UpdateReorderMarkerPosition(marker, cursorX, cursorY) and 1 or 0
end

local function FinishBuffDrag()
    local entry = draggedEntry
    local sourceButton = dragSourceButton
    local targetButton = dragTargetButton
    if not entry or not targetButton or targetButton == sourceButton then
        ClearBuffDrag()
        return
    end

    local targetContainerIndex = targetButton.buffContainerIndex
    if entry.custom and not targetContainerIndex then
        ClearBuffDrag()
        return
    end
    local targetEntry = targetButton.buffEmpty and nil or targetButton.buffEntry
    BuffData.InsertEntryAt(targetContainerIndex, entry, targetEntry, dragOffset == 0)
    ClearBuffDrag()

    PlaySound(SOUNDKIT.UI_CURSOR_DROP_OBJECT)
    ns.BuffContainerViewer:ReconcileContainerCount()
    BuffAssignmentPanel:RefreshPanel()
end

local function BeginBuffDrag(button, eatNextGlobalMouseUp)
    local entry = button and button.buffEntry
    if not entry or IsDragging() then
        return
    end
    draggedEntry = entry
    dragSourceButton = button
    dragTarget = button
    dragTargetButton = button
    dragOffset = 0
    dragEatNextGlobalMouseUp = eatNextGlobalMouseUp
    if entry.custom and button.Icon then
        button.Icon:SetDesaturated(true)
    end
    local cursor = EnsureDragCursor()
    cursor.tex:SetTexture(entry.iconID or 134400)
    cursor:Show()
    PlaySound(SOUNDKIT.UI_CURSOR_PICKUP_OBJECT)
    local panel = BuffAssignmentPanel:GetPanel()
    panel:SetScript("OnUpdate", UpdateDragMarker)
    panel:RegisterEvent("GLOBAL_MOUSE_UP")
end

local function InstallContextMenuExtension()
    if contextMenuExtended then
        return
    end
    Menu.ModifyMenu("MENU_COOLDOWN_SETTINGS_ITEM", function(owner, rootDescription)
        if InCombatLockdown() then
            return
        end
        local entry = owner and owner["buffEntry"]
        if not entry then
            return
        end

        if entry.custom then
            local function RefreshCustomAuraStyle()
                CustomAuraProvider:SyncDefinitions(BuffData.GetCustomAuraDefinitions())
                BuffAssignmentPanel:RefreshPanel()
            end
            local function getStackColor()
                return BuffData.GetCustomAuraStackColor(entry.stableKey)
            end
            local function setStackColor(r, g, b)
                BuffData.SetCustomAuraStackColor(entry.stableKey, r, g, b)
            end
            local glowColorMenu = rootDescription:CreateButton("Glow & Color")
            ns.CooldownStyle.AddMenuColorButton(
                glowColorMenu,
                "Set Number Color",
                getStackColor,
                setStackColor,
                RefreshCustomAuraStyle,
                { 1, 1, 1 }
            )
            rootDescription:CreateButton("Reset to Defaults", function()
                setStackColor()
                RefreshCustomAuraStyle()
            end)
            rootDescription:CreateButton("Remove custom aura", function()
                if BuffData.RemoveCustomAura(entry.stableKey) then
                    CustomAuraProvider:SyncDefinitions(BuffData.GetCustomAuraDefinitions())
                    ns.BuffContainerViewer:ReconcileContainerCount()
                    BuffAssignmentPanel:RefreshPanel()
                end
            end)
            return
        end

        if not ns.CooldownStyle then
            return
        end
        local styleKey = ns.CooldownStyle.GetTrackedStyleKey(entry.cooldownID)
        if not styleKey then
            return
        end

        local function RefreshBuffStyle()
            ns.CooldownStyle.RefreshCooldownFrames()
        end

        local cooldownMenu = rootDescription:CreateButton("Cooldown")
        local glowColorMenu = rootDescription:CreateButton("Glow & Color")

        cooldownMenu:CreateCheckbox("Forced Cooldown Edge", function()
            return ns.CooldownStyle.GetTrackedAlwaysShowCooldownEdge(styleKey)
        end, function()
            ns.CooldownStyle.ToggleTrackedAlwaysShowCooldownEdge(styleKey)
            RefreshBuffStyle()
        end)
        glowColorMenu:CreateCheckbox("Always Glow", function()
            return ns.CooldownStyle.GetAlwaysGlow(styleKey)
        end, function()
            ns.CooldownStyle.ToggleAlwaysGlow(styleKey)
            RefreshBuffStyle()
        end)

        ns.CooldownStyle.AddEntryColorMenu(
            glowColorMenu,
            styleKey,
            "trackedGlowColor",
            "trackedStackColor",
            RefreshBuffStyle
        )
        rootDescription:CreateButton("Reset to Defaults", function()
            ns.CooldownStyle.SetTrackedAlwaysShowCooldownEdge(styleKey, false)
            ns.CooldownStyle.SetAlwaysGlow(styleKey, false)
            ns.CooldownStyle.SetStyleEntryColor(styleKey, "trackedGlowColor")
            ns.CooldownStyle.SetStyleEntryColor(styleKey, "trackedStackColor")
            RefreshBuffStyle()
        end)
    end)
    contextMenuExtended = true
end

local function ShowMoveMenu(button)
    if InCombatLockdown() then
        return
    end
    local entry = button.buffEntry
    if not entry then
        return
    end
    MenuUtil.CreateContextMenu(button, function(_, rootDescription)
        rootDescription:SetTag("MENU_COOLDOWN_SETTINGS_ITEM")
    end)
end

function BuffAssignmentPanel:GetPanel()
    return CMCCooldownViewerSettingsBuffPanel
end

local function EnsureCustomAuraBadge(button)
    local badge = button.buffCustomAuraBadge
    if badge then
        return badge
    end

    badge = CreateFrame("Frame", nil, button)
    badge:SetHeight(18)
    badge:SetPoint("TOPLEFT", button.Icon, "TOPLEFT", 0, -2)
    badge:SetPoint("TOPRIGHT", button.Icon, "TOPRIGHT", 0, -2)
    badge:SetFrameLevel(button:GetFrameLevel() + 20)
    badge:EnableMouse(false)

    local background = badge:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(badge)
    background:SetColorTexture(0, 0, 0, 0.7)

    local icon = badge:CreateTexture(nil, "ARTWORK")
    icon:SetAtlas(CUSTOM_AURA_BADGE_ATLAS)
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER")
    badge:Hide()
    button.buffCustomAuraBadge = badge
    return badge
end

local function InitializeButton(button)
    if not button.Icon then
        button:SetSize(ITEM_SIZE, ITEM_SIZE)
        button:EnableMouse(true)

        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(button)
        button.Icon = icon

        local highlight = button:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints(button)
        highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        highlight:SetBlendMode("ADD")
        button.Highlight = highlight
    end
    EnsureCustomAuraBadge(button)
    if button.buffInitialized then
        return
    end

    if button.Cooldown then
        CooldownFrame_Clear(button.Cooldown)
        button.Cooldown:SetDrawSwipe(false)
        button.Cooldown:SetDrawEdge(false)
    end

    button:SetScript("OnMouseUp", function(self, mouseButton)
        if IsDragging() then
            return
        elseif mouseButton == "RightButton" and not self.buffEmpty then
            ShowMoveMenu(self)
        elseif mouseButton == "LeftButton" and not self.buffEmpty and self.buffEntry then
            BeginBuffDrag(self, mouseButton)
        end
    end)
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function(self)
        if not self.buffEmpty and self.buffEntry then
            BeginBuffDrag(self)
        end
    end)
    button:SetScript("OnReceiveDrag", function(self)
        SetDragTarget(self)
    end)
    button:SetScript("OnEnter", function(self)
        SetDragTarget(self)
        local entry = self.buffEntry
        if entry and entry.spellID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(entry.spellID)
            if entry.custom then
                GameTooltip:AddLine("Custom aura", 0.55, 0.8, 1)
                GameTooltip:AddDoubleLine("Spell ID", entry.spellID, 0.7, 0.7, 0.7, 1, 1, 1)
            end
            GameTooltip:Show()
        elseif self.buffEmpty then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Empty Slot")
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        GameTooltip_Hide()
    end)

    function button:GetBestCooldownItemTarget(_cursorX, _cursorY)
        return self
    end

    function button:UpdateReorderMarkerPosition(marker, cursorX, _cursorY)
        local centerX = self:GetCenter()
        if centerX and cursorX < centerX then
            marker:SetPoint("CENTER", self, "LEFT", -4, 0)
            return false
        end
        marker:SetPoint("CENTER", self, "RIGHT", 4, 0)
        return true
    end

    button:HookScript("OnShow", function(self)
        if self.buffEmpty then
            self.Icon:SetTexture(nil)
            self.Icon:SetAtlas("cdm-empty", true)
            self.Icon:SetDesaturated(false)
        elseif self.buffEntry and self.buffEntry.custom then
            self.Icon:SetAtlas(nil)
            self.Icon:SetTexture(self.buffEntry.iconID or 134400)
            self.Icon:SetDesaturated(false)
        end
    end)

    button.buffInitialized = true
end

local function AcquireButton(category)
    local button = category.itemPool:Acquire()
    InitializeButton(button)
    button:Show()
    return button
end

local function ClearButtonCooldownData(button)
    button.emptyCategory = nil
    button.orderIndex = nil
    if ns.CooldownStyle then
        ns.CooldownStyle.HideSettingsItemIndicator(button)
    end
    if button.Icon then
        button.Icon:SetTexture(nil)
        button.Icon:SetDesaturated(false)
    end
end

local function SetButtonCooldownData(button, entry, orderIndex)
    button.emptyCategory = nil
    button.orderIndex = orderIndex
    button.Icon:SetAtlas(nil)
    button.Icon:SetTexture(entry.iconID or 134400)
    button.Icon:SetDesaturated(false)
    if ns.CooldownStyle then
        if entry.custom then
            ns.CooldownStyle.HideSettingsItemIndicator(button)
        else
            ns.CooldownStyle.RefreshSettingsItemIndicator(button, entry.cooldownID)
        end
    end
end

local function ValidateCustomAuraInput(text)
    local spellID = tonumber(strtrim(text or ""))
    if not spellID or spellID <= 0 or spellID ~= math.floor(spellID) then
        return nil, nil, nil, "Unknown spell ID"
    end

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    if not spellInfo or not spellInfo.name then
        return nil, nil, nil, "Unknown spell ID"
    end
    local name = spellInfo.name
    local iconID = spellInfo.iconID or C_Spell.GetSpellTexture(spellID)
    if BuffData.HasCustomAura(spellID) or BuffData.HasBlizzardAura(spellID) then
        return nil, name, iconID, "Aura already added"
    end
    return spellID, name, iconID, nil
end

if CustomAuraProvider then
    local customAuraPreview = CreateFrame("Frame", nil, UIParent)
    customAuraPreview:SetSize(280, 36)
    customAuraPreview:SetFrameStrata("TOOLTIP")
    customAuraPreview:SetClampedToScreen(true)
    customAuraPreview:Hide()
    local customAuraPreviewIcon = customAuraPreview:CreateTexture(nil, "ARTWORK")
    customAuraPreviewIcon:SetSize(32, 32)
    customAuraPreviewIcon:SetPoint("LEFT", customAuraPreview, "LEFT", 0, 0)
    local customAuraPreviewText = customAuraPreview:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    customAuraPreviewText:SetPoint("LEFT", customAuraPreviewIcon, "RIGHT", 8, 0)
    customAuraPreviewText:SetPoint("RIGHT", customAuraPreview, "RIGHT", 0, 0)
    customAuraPreviewText:SetJustifyH("LEFT")
    local customAuraPreviewStatus = customAuraPreview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    customAuraPreviewText:ClearAllPoints()
    customAuraPreviewText:SetPoint("TOPLEFT", customAuraPreviewIcon, "TOPRIGHT", 8, -1)
    customAuraPreviewText:SetPoint("RIGHT", customAuraPreview, "RIGHT", 0, 0)
    customAuraPreviewStatus:SetPoint("TOPLEFT", customAuraPreviewText, "BOTTOMLEFT", 0, -3)
    customAuraPreviewStatus:SetPoint("RIGHT", customAuraPreview, "RIGHT", 0, 0)
    customAuraPreviewStatus:SetJustifyH("LEFT")

    local function UpdateCustomAuraPreview(editBox)
        local dialog = editBox:GetParent()
        local spellID, name, iconID, errorMessage = ValidateCustomAuraInput(editBox:GetText())
        dialog:GetButton1():SetEnabled(spellID ~= nil)

        customAuraPreviewIcon:SetTexture(iconID)
        customAuraPreviewIcon:SetShown(iconID ~= nil)
        if name then
            customAuraPreviewText:SetText(name)
            customAuraPreviewText:SetTextColor(1, 1, 1)
            customAuraPreviewStatus:SetText(errorMessage or "")
            customAuraPreviewStatus:SetTextColor(1, 0.25, 0.25)
        else
            customAuraPreviewText:SetText(errorMessage or "")
            customAuraPreviewText:SetTextColor(1, 0.25, 0.25)
            customAuraPreviewStatus:SetText("")
        end
    end

    StaticPopupDialogs["CMC_ADD_CUSTOM_AURA"] = {
        text = "Add a custom player buff by spell ID",
        button1 = _G.ADD,
        button2 = _G.CANCEL,
        hasEditBox = true,
        editBoxWidth = 220,
        maxLetters = 10,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        OnShow = function(dialog)
            if dialog.which ~= "CMC_ADD_CUSTOM_AURA" then
                return
            end
            customAuraPreview:ClearAllPoints()
            customAuraPreview:SetPoint("BOTTOM", dialog, "TOP", 0, 8)
            customAuraPreview:Show()

            customAuraPreviewIcon:SetTexture(nil)
            customAuraPreviewIcon:Hide()
            customAuraPreviewText:SetText("")
            customAuraPreviewStatus:SetText("")
            dialog:GetButton1():Disable()
            dialog:GetEditBox():SetText("")
            dialog:GetEditBox():SetFocus()
            UpdateCustomAuraPreview(dialog:GetEditBox())
        end,
        OnAccept = function(dialog)
            local spellID = ValidateCustomAuraInput(dialog:GetEditBox():GetText())
            if not spellID then
                return
            end
            local stableKey = BuffData.AddCustomAura(spellID)
            if not stableKey then
                return
            end
            CustomAuraProvider:SyncDefinitions(BuffData.GetCustomAuraDefinitions())
            ns.BuffContainerViewer:ReconcileContainerCount()
            BuffAssignmentPanel:RefreshPanel()
        end,
        OnHide = function(dialog)
            if dialog.which == "CMC_ADD_CUSTOM_AURA" then
                customAuraPreview:Hide()
                customAuraPreview:ClearAllPoints()
            end
            dialog:GetEditBox():SetText("")
        end,
        EditBoxOnEnterPressed = function(editBox)
            local dialog = editBox:GetParent()
            if dialog:GetButton1():IsEnabled() then
                StaticPopup_OnClick(dialog, 1)
            end
        end,
        EditBoxOnTextChanged = function(editBox)
            UpdateCustomAuraPreview(editBox)
        end,
        EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
    }
end

local function LayoutCategory(category, entries)
    category.itemPool:ReleaseAll()

    local container = category.Container
    local headerHeight = category.Header:GetHeight()
    local isCollapsed = category.IsCollapsed and category:IsCollapsed() or category.Collapsed
    if isCollapsed then
        if category.SetCollapsed then
            category:SetCollapsed(true)
        elseif container then
            container:Hide()
        end
        category:SetHeight(headerHeight)
        return
    end

    if category.SetCollapsed then
        category:SetCollapsed(false)
    elseif container then
        container:Show()
    end

    if #entries == 0 then
        local button = AcquireButton(category)
        ClearButtonCooldownData(button)
        button.buffEmpty = true
        button.buffEntry = nil
        button.buffContainerIndex = category.containerIndex
        button.layoutIndex = 1
        button:ClearAllPoints()
        button:SetSize(ITEM_SIZE, ITEM_SIZE)
        if button.Icon then
            button.Icon:SetTexture(nil)
            button.Icon:SetAtlas("cdm-empty", true)
            button.Icon:SetDesaturated(false)
        end
        button.buffCustomAuraBadge:Hide()
        if button.Cooldown then
            CooldownFrame_Clear(button.Cooldown)
        end
    else
        for index, entry in ipairs(entries) do
            local button = AcquireButton(category)
            button.buffEmpty = false
            button.buffEntry = entry
            button.buffContainerIndex = category.containerIndex
            button.layoutIndex = index
            button:ClearAllPoints()
            button:SetSize(ITEM_SIZE, ITEM_SIZE)
            SetButtonCooldownData(button, entry, index)
            if entry.custom and button.Icon then
                button.Icon:SetAtlas(nil)
                button.Icon:SetTexture(entry.iconID or 134400)
                button.Icon:SetDesaturated(false)
            end
            button.buffCustomAuraBadge:SetShown(entry.custom == true)
            if button.Cooldown then
                CooldownFrame_Clear(button.Cooldown)
            end
        end
    end

    if container and container.Layout then
        container.childXPadding = ITEM_SPACING
        container.childYPadding = ITEM_SPACING
        container.isHorizontal = true
        container.stride = STRIDE
        container.layoutFramesGoingRight = true
        container.layoutFramesGoingUp = false
        container.alwaysUpdateLayout = true
        container:Layout()
    end

    local contentHeight = container and container:GetHeight() or 0
    local totalHeight = nil
    if category.Header and container then
        local headerTop = category.Header:GetTop()
        local containerBottom = container:GetBottom()
        if headerTop and containerBottom then
            totalHeight = headerTop - containerBottom
        end
    end
    category:SetHeight(totalHeight or (headerHeight + 6 + contentHeight))
end

local function CreateCategory(parent, title, containerIndex)
    local category = CreateFrame("Frame", nil, parent, "CooldownViewerSettingsCategoryTemplate")
    category.containerIndex = containerIndex
    category.Collapsed = false
    category.Header:SetHeaderText(title)
    category:Layout()

    function category:SetCollapsed(collapsed)
        self.Collapsed = collapsed and true or false
        if self.Header and self.Header.UpdateCollapsedState then
            self.Header:UpdateCollapsedState(self.Collapsed)
        end
        if self.Container then
            self.Container:SetShown(not self.Collapsed)
            if self.Container.Layout then
                self.Container:Layout()
            end
        end
    end

    function category:IsCollapsed()
        return self.Collapsed == true
    end

    function category:ToggleCollapsed()
        self:SetCollapsed(not self:IsCollapsed())
        BuffAssignmentPanel:RefreshPanel()
    end

    if category.Header then
        if category.Header.CollapseButton then
            category.Header.CollapseButton:Hide()
            category.Header.CollapseButton:Disable()
        end
        if category.Header.Toggle then
            category.Header.Toggle:Hide()
            category.Header.Toggle:Disable()
        end
    end

    category:SetScript("OnEnter", function(self)
        SetDragTarget(self)
    end)
    category:SetScript("OnReceiveDrag", function(self)
        SetDragTarget(self)
    end)
    if category.Container then
        category.Container:SetScript("OnEnter", function()
            SetDragTarget(category)
        end)
        category.Container:SetScript("OnReceiveDrag", function()
            SetDragTarget(category)
        end)
    end

    category.itemPool = CreateFramePool("Frame", category.Container, nil, function(_, f)
        f:Hide()
        ClearButtonCooldownData(f)
        f.layoutIndex = nil
        f.buffEntry = nil
        f.buffEmpty = nil
        local badge = f.buffCustomAuraBadge
        if badge then
            badge:Hide()
        end
        if f.Icon then
            f.Icon:SetTexture(nil)
        end
    end)

    function category:RefreshSpellIcons()
        for button in self.itemPool:EnumerateActive() do
            local entry = button.buffEntry
            if entry and button.Icon then
                button.Icon:SetAtlas(nil)
                button.Icon:SetTexture(entry.iconID or 134400)
            end
        end
    end

    function category:GetBestCooldownItemTarget(cursorX, cursorY)
        local nearestItem = nil
        local nearestVertical = math.huge
        local nearestHorizontal = math.huge
        for item in self.itemPool:EnumerateActive() do
            local left, right, bottom, top = item:GetLeft(), item:GetRight(), item:GetBottom(), item:GetTop()
            if left and right and bottom and top then
                local centerX = (left + right) / 2
                local centerY = (bottom + top) / 2
                local horizontalDistance = math.abs(centerX - cursorX)
                local verticalDistance = math.abs(centerY - cursorY)
                if cursorY > bottom and cursorY < top then
                    verticalDistance = 0
                end
                if
                    verticalDistance < nearestVertical
                    or (verticalDistance == nearestVertical and horizontalDistance < nearestHorizontal)
                then
                    nearestItem = item
                    nearestVertical = verticalDistance
                    nearestHorizontal = horizontalDistance
                end
            end
        end
        return nearestItem
    end

    if category.Header and category.Header.SetClickHandler then
        category.Header:SetClickHandler(function(_, button)
            if button == "LeftButton" then
                category:ToggleCollapsed()
            end
        end)
    elseif category.Header then
        category.Header:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then
                category:ToggleCollapsed()
            end
        end)
    end

    category:SetCollapsed(false)

    return category
end

local function RefreshPanelInternal()
    if not BuffData.IsEnabled() then
        return
    end
    local panel = CMCCooldownViewerSettingsBuffPanel
    if not panel then
        return
    end

    if panel.SetPortraitTextureRaw then
        panel:SetPortraitTextureRaw(PORTRAIT)
    end

    BuffData.ScanTrackedBuffs()

    local defaultCategory = panel.buffDefaultCategory
    local containerCategories = panel.buffContainerCategories
    local scrollChild = panel.buffScrollChild
    local scrollFrame = panel.buffScrollFrame
    if not defaultCategory or not containerCategories or not scrollChild then
        return
    end

    local searchTerm = panel.buffSearchTerm
    searchTerm = searchTerm and searchTerm ~= "" and searchTerm:lower() or nil
    local function filter(entries)
        if not searchTerm then
            return entries
        end
        local result = {}
        for _, entry in ipairs(entries) do
            local name = entry.name and entry.name:lower()
            if name and name:find(searchTerm, 1, true) then
                result[#result + 1] = entry
            end
        end
        return result
    end

    local ordered = {}
    LayoutCategory(defaultCategory, filter(BuffData.GetUnassignedBuffs()))
    ordered[#ordered + 1] = defaultCategory

    local count = BuffData.GetContainerCount()
    for i = 1, #containerCategories do
        local category = containerCategories[i]
        if i <= count then
            category:Show()
            local entries = BuffData.GetBuffsForContainer(i)
            local hasCustomAura = false
            for _, entry in ipairs(entries) do
                if entry.custom then
                    hasCustomAura = true
                    break
                end
            end
            local title = "Buffs " .. i
            if hasCustomAura then
                title = title .. " |cffff2020(centering unavailable)|r"
            end
            category.Header:SetHeaderText(title)
            LayoutCategory(category, filter(entries))
            ordered[#ordered + 1] = category
        else
            category:Hide()
        end
    end

    local yOffset = 0
    local previous = nil
    for _, category in ipairs(ordered) do
        category:ClearAllPoints()
        if previous then
            category:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -18)
        else
            category:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
        end
        yOffset = yOffset + category:GetHeight() + (previous and 18 or 0)
        previous = category
    end

    if scrollChild then
        scrollChild:SetHeight(math.max(1, yOffset))
    end
    if scrollFrame and scrollFrame.UpdateScrollChildRect then
        scrollFrame:UpdateScrollChildRect()
    end
end

function BuffAssignmentPanel:RefreshPanel()
    if InCombatLockdown() then
        return
    end
    RefreshPanelInternal()
end

StaticPopupDialogs["CMC_ENABLE_BUFF_CONTAINERS"] = {
    text = "Custom Buff Containers are disabled. Enable them now?",
    button1 = _G.YES,
    button2 = _G.NO,
    OnAccept = function(_, data)
        if not ns.db or not ns.db.profile then
            return
        end
        BuffData.SetEnabled(true)
        if ns.BuffContainerViewer then
            ns.BuffContainerViewer:Initialize()
        end
        if type(data) == "function" then
            data()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- When the feature is turned off while the custom Buffs panel is open, drop our
-- overlay. The native Cooldown Viewer content beneath it was never modified.
function BuffAssignmentPanel:OnBuffContainersDisabled()
    if not CMCCooldownViewerSettingsBuffPanel or not CMCCooldownViewerSettingsBuffPanel:IsShown() then
        return
    end
    ns.SettingsTabs:DeactivateAll()
end

function BuffAssignmentPanel:EnsureSettingsTab()
    if CMCCooldownViewerSettingsBuffPanel then
        return
    end

    InstallContextMenuExtension()

    CMCCooldownViewerSettingsBuffPanel =
        CreateFrame("Frame", "CMCCooldownViewerSettingsBuffPanel", CooldownViewerSettings, "ButtonFrameTemplate")
    CMCCooldownViewerSettingsBuffPanel:SetAllPoints(CooldownViewerSettings)
    CMCCooldownViewerSettingsBuffPanel:SetFrameStrata("HIGH")
    CMCCooldownViewerSettingsBuffPanel:SetFrameLevel(CooldownViewerSettings:GetFrameLevel() + 10)
    CooldownViewerSettingsCloseButton:SetFrameStrata("HIGH")
    -- CMCCooldownViewerSettingsBuffPanel:EnableMouse(true)
    CMCCooldownViewerSettingsBuffPanel:Hide()
    if CMCCooldownViewerSettingsBuffPanel.Inset and CMCCooldownViewerSettingsBuffPanel.Inset.Bg then
        CMCCooldownViewerSettingsBuffPanel.Inset.Bg:SetAtlas("character-panel-background", true)
        CMCCooldownViewerSettingsBuffPanel.Inset.Bg:SetHorizTile(false)
        CMCCooldownViewerSettingsBuffPanel.Inset.Bg:SetVertTile(false)
    end
    if
        CMCCooldownViewerSettingsBuffPanel.TitleContainer
        and CMCCooldownViewerSettingsBuffPanel.TitleContainer.TitleText
    then
        CMCCooldownViewerSettingsBuffPanel.TitleContainer.TitleText:SetText(ns.API.GradientText("CMC") .. " Buffs")
    end
    if CMCCooldownViewerSettingsBuffPanel.CloseButton then
        -- Leave Blizzard's native close button visible and clickable above our panel.
        CMCCooldownViewerSettingsBuffPanel.CloseButton:Hide()
    end

    hooksecurefunc(CooldownViewerSettings, "RefreshLayout", function()
        if InCombatLockdown() or not CMCCooldownViewerSettingsBuffPanel:IsShown() then
            return
        end
        BuffData.InvalidateScan()
        BuffAssignmentPanel:RefreshPanel()
    end)

    CMCCooldownViewerSettingsBuffPanel:SetScript("OnEvent", function(_, event, button)
        if event ~= "GLOBAL_MOUSE_UP" or not IsDragging() then
            return
        end
        if dragEatNextGlobalMouseUp == button then
            dragEatNextGlobalMouseUp = nil
            return
        end
        if button == "LeftButton" then
            FinishBuffDrag()
        else
            ClearBuffDrag()
        end
    end)

    local scrollFrame =
        CreateFrame("ScrollFrame", "$parent.BuffScroll", CMCCooldownViewerSettingsBuffPanel, "ScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 17, -72)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 29)
    local scrollChild = CreateFrame("Frame", "$parent.Content", scrollFrame)
    scrollChild:SetSize(300, 1)
    scrollChild:SetPoint("TOPLEFT", 0, 0)
    scrollChild:SetPoint("TOPRIGHT", 0, 0)
    scrollFrame:SetScrollChild(scrollChild)
    scrollFrame.ScrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 6, 0)
    scrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 6, 0)
    scrollFrame:SetScript("OnSizeChanged", function(self)
        scrollChild:SetWidth(self:GetWidth())
        BuffAssignmentPanel:RefreshPanel()
    end)

    CMCCooldownViewerSettingsBuffPanel.buffScrollChild = scrollChild
    CMCCooldownViewerSettingsBuffPanel.buffScrollFrame = scrollFrame

    local searchBox = CreateFrame("EditBox", nil, CMCCooldownViewerSettingsBuffPanel, "SearchBoxTemplate")
    searchBox:SetSize(290, 30)
    searchBox:SetPoint("TOPLEFT", CMCCooldownViewerSettingsBuffPanel, "TOPLEFT", 72, -30)
    searchBox.Instructions:SetText("Enter search text")
    searchBox:SetScript("OnTextChanged", function(self)
        self.Instructions:SetShown(self:GetText() == "")
        CMCCooldownViewerSettingsBuffPanel.buffSearchTerm = self:GetText()
        BuffAssignmentPanel:RefreshPanel()
    end)
    searchBox:Hide()
    CMCCooldownViewerSettingsBuffPanel.buffSearchBox = searchBox

    local trackMoreButton = CreateFrame("Button", nil, CMCCooldownViewerSettingsBuffPanel, "UIPanelButtonTemplate")
    trackMoreButton:SetPoint("BOTTOMLEFT", CMCCooldownViewerSettingsBuffPanel, "BOTTOMLEFT", 10, 4)
    trackMoreButton:SetHeight(22)
    trackMoreButton:SetText("Add more 'Tracked Buffs' in Buffs tab")
    trackMoreButton:SetWidth(trackMoreButton:GetFontString():GetStringWidth() + 30)
    trackMoreButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(
            "Opens Blizzard's Buffs tab, where you can add more buffs\nto 'Tracked Buffs'\nfrom 'Not Displayed'.",
            nil,
            nil,
            nil,
            nil,
            true
        )
        GameTooltip:Show()
    end)
    trackMoreButton:SetScript("OnLeave", GameTooltip_Hide)

    if CustomAuraProvider then
        local addCustomAuraButton =
            CreateFrame("Button", nil, CMCCooldownViewerSettingsBuffPanel, "UIPanelButtonTemplate")
        addCustomAuraButton:SetPoint("BOTTOMRIGHT", CMCCooldownViewerSettingsBuffPanel, "BOTTOMRIGHT", -10, 4)
        addCustomAuraButton:SetHeight(22)
        addCustomAuraButton:SetText("Add custom aura")
        addCustomAuraButton:SetWidth(addCustomAuraButton:GetFontString():GetStringWidth() + 30)
        addCustomAuraButton:SetScript("OnClick", function()
            StaticPopup_Show("CMC_ADD_CUSTOM_AURA")
        end)
    end

    local defaultCategory = CreateCategory(scrollChild, "Default Tracked Buffs Frame", nil)
    CMCCooldownViewerSettingsBuffPanel.buffDefaultCategory = defaultCategory

    local containerCategories = {}
    for i = 1, BuffData.GetMaxContainers() do
        containerCategories[i] = CreateCategory(scrollChild, "Buffs " .. i, i)
        containerCategories[i]:Hide()
    end
    CMCCooldownViewerSettingsBuffPanel.buffContainerCategories = containerCategories

    CMCCooldownViewerSettingsBuffPanel:HookScript("OnShow", function()
        scrollChild:SetWidth(scrollFrame:GetWidth())
        searchBox:Show()
        BuffAssignmentPanel:RefreshPanel()
    end)
    CMCCooldownViewerSettingsBuffPanel:HookScript("OnHide", function()
        searchBox:Hide()
        ClearBuffDrag()
    end)

    local aurasTab = CooldownViewerSettings.AurasTab
    local groupBuffsTab = CooldownViewerSettings.GroupBuffsTab

    CMCCooldownViewerSettingsBuffTab = CreateFrame("Button", nil, UIParent, "CooldownViewerSettingsTabTemplate")
    CMCCooldownViewerSettingsBuffTab:SetFrameStrata("HIGH")
    CMCCooldownViewerSettingsBuffTab.tooltipText = ns.API.GradientText("CMC") .. " Buffs"
    CMCCooldownViewerSettingsBuffTab.activeAtlas = "icon_trackedbuffs"
    CMCCooldownViewerSettingsBuffTab.inactiveAtlas = "icon_trackedbuffs"
    CMCCooldownViewerSettingsBuffTab.Icon:SetDesaturated(true)
    CMCCooldownViewerSettingsBuffTab.Icon:SetVertexColor(1, 1, 1, 1)
    CMCCooldownViewerSettingsBuffTab.Icon:SetGradient(
        "VERTICAL",
        CreateColor(0, 0.41, 0.405),
        CreateColor(0.825, 0.93, 0)
    )

    CMCCooldownViewerSettingsBuffTab:SetChecked(false)
    local trackerTab = CMCCooldownViewerSettingsTrackerTab
    if trackerTab then
        CMCCooldownViewerSettingsBuffTab:SetPoint("TOP", trackerTab, "BOTTOM", 0, -3)
    elseif groupBuffsTab then
        CMCCooldownViewerSettingsBuffTab:SetPoint("TOP", groupBuffsTab, "BOTTOM", 0, -3)
    else
        CMCCooldownViewerSettingsBuffTab:SetPoint("TOP", aurasTab, "BOTTOM", 0, -3)
    end

    ns.SettingsTabs:RegisterPanel(CMCCooldownViewerSettingsBuffPanel, CMCCooldownViewerSettingsBuffTab, "Buffs")

    local function ShowBuffTab()
        ns.SettingsTabs:Activate(CMCCooldownViewerSettingsBuffPanel, function()
            BuffAssignmentPanel:RefreshPanel()
        end)
    end

    hooksecurefunc(CooldownViewerSettings, "Hide", function()
        CMCCooldownViewerSettingsBuffPanel:Hide()
        CMCCooldownViewerSettingsBuffTab:Hide()
    end)
    hooksecurefunc(CooldownViewerSettings, "Show", function()
        if InCombatLockdown() then
            ns.SettingsTabs:DeactivateAll()
            CMCCooldownViewerSettingsBuffTab:Hide()
        else
            CMCCooldownViewerSettingsBuffTab:Show()
            ns.SettingsTabs:Restore()
        end
    end)

    CMCCooldownViewerSettingsBuffTab:SetScript("OnClick", function()
        if not BuffData.IsEnabled() then
            StaticPopup_Show("CMC_ENABLE_BUFF_CONTAINERS", nil, nil, ShowBuffTab)
            return
        end
        ns.SettingsTabs:DeactivateAll()
        ShowBuffTab()
    end)

    hooksecurefunc(CooldownViewerSettings, "SetDisplayMode", function()
        ns.SettingsTabs:DeactivateAll()
    end)

    if not InCombatLockdown() then
        CMCCooldownViewerSettingsBuffTab:Show()
    else
        CMCCooldownViewerSettingsBuffTab:Hide()
    end
end
