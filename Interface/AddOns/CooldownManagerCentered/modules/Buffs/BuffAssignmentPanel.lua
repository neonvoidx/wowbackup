local _, ns = ...
local Affected = ns.API.Affected

-- Settings UI for the custom buff containers. Injects a "Buffs" tab into Blizzard's
-- CooldownViewerSettings (below CMC's custom-tracker tab) whose panel lists the
-- tracked buffs in sections: "Default Tracked Buffs Frame" (unassigned, rendered in
-- the native buff row) followed by one section per custom container. Buffs are moved
-- between sections by drag-and-drop or a right-click "Move to" menu; the container
-- count auto-grows so there is always one empty trailing section.
--
-- Deliberately mirrors TrackerAssignmentPanel so the tab looks/behaves 1:1 with the
-- tracker tab and Blizzard's own tabs: it reuses Blizzard's category template
-- (ResizeLayoutFrame + its GridLayoutFrame .Container) and item template, and the
-- same show/hide (IsTabButton) mechanics.
local BuffAssignmentPanel = {}
ns.BuffAssignmentPanel = BuffAssignmentPanel

local BuffData = ns.BuffData

local ITEM_SIZE = 38
local ITEM_SPACING = 8
local STRIDE = 7
local PORTRAIT = "Interface\\Addons\\CooldownManagerCentered\\Media\\CooldownManagerCenteredIcon"

-- Drag state shared across all buff buttons for the lifetime of a pickup.
local draggedEntry = nil
local dragCursor = nil

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

local function EndBuffDrag()
    draggedEntry = nil
    if dragCursor then
        dragCursor:Hide()
    end
    local panel = BuffAssignmentPanel:GetPanel()
    if panel then
        panel:UnregisterEvent("GLOBAL_MOUSE_UP")
    end
end

local function BeginBuffDrag(entry)
    if not entry or IsDragging() then
        return
    end
    draggedEntry = entry
    local cursor = EnsureDragCursor()
    cursor.tex:SetTexture(entry.iconID or 134400)
    cursor:Show()
    if PlaySound and SOUNDKIT and SOUNDKIT.UI_CURSOR_PICKUP_OBJECT then
        PlaySound(SOUNDKIT.UI_CURSOR_PICKUP_OBJECT)
    end
    local panel = BuffAssignmentPanel:GetPanel()
    if panel then
        panel:RegisterEvent("GLOBAL_MOUSE_UP")
    end
end

local function ApplyAssignment(key, containerIndex)
    if not key then
        return
    end
    if BuffData.GetContainerForStableKey(key) == containerIndex then
        return
    end
    BuffData.AssignKey(key, containerIndex)
    if ns.BuffContainerViewer then
        ns.BuffContainerViewer:ReconcileContainerCount()
    end
    BuffAssignmentPanel:RefreshPanel()
end

-- Assigns the currently dragged buff to a container (index nil = default row).
local function DropOnContainer(containerIndex)
    if not IsDragging() then
        return
    end
    local key = draggedEntry.stableKey
    EndBuffDrag()
    if PlaySound and SOUNDKIT and SOUNDKIT.UI_CURSOR_DROP_OBJECT then
        PlaySound(SOUNDKIT.UI_CURSOR_DROP_OBJECT)
    end
    ApplyAssignment(key, containerIndex)
end

local function ShowMoveMenu(button)
    local entry = Affected(button).buffEntry
    if not entry then
        return
    end
    MenuUtil.CreateContextMenu(button, function(_, root)
        root:CreateTitle(entry.name or ("Buff " .. tostring(entry.cooldownID)))
        root:CreateButton("Default Tracked Buffs Frame", function()
            ApplyAssignment(entry.stableKey, nil)
        end)
        for i = 1, BuffData.GetContainerCount() do
            root:CreateButton("Buffs " .. i, function()
                ApplyAssignment(entry.stableKey, i)
            end)
        end
    end)
end

function BuffAssignmentPanel:GetPanel()
    local settings = _G["CooldownViewerSettings"]
    return settings and Affected(settings).buffPanel or nil
end

-- One-time script/setup for a pooled item button (mirrors the tracker's
-- InitializeItemButton). Buttons come from Blizzard's item template, so they already
-- have .Icon/.Cooldown and registerForDrag; we override the scripts for our
-- assignment drag + "Move to" menu + spell tooltip.
local function InitializeButton(button)
    if Affected(button).buffInitialized then
        return
    end

    if button.Cooldown then
        CooldownFrame_Clear(button.Cooldown)
        button.Cooldown:SetDrawSwipe(false)
        button.Cooldown:SetDrawEdge(false)
    end

    button:SetScript("OnMouseUp", function(self, mouseButton)
        if IsDragging() then
            DropOnContainer(Affected(self).buffContainerIndex)
        elseif mouseButton == "RightButton" and not Affected(self).buffEmpty then
            ShowMoveMenu(self)
        elseif mouseButton == "LeftButton" and not Affected(self).buffEmpty and Affected(self).buffEntry then
            if PlaySound and SOUNDKIT and SOUNDKIT.UI_CURSOR_PICKUP_OBJECT then
                PlaySound(SOUNDKIT.UI_CURSOR_PICKUP_OBJECT)
            end
            BeginBuffDrag(Affected(self).buffEntry)
        end
    end)
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function(self)
        if not Affected(self).buffEmpty and Affected(self).buffEntry then
            BeginBuffDrag(Affected(self).buffEntry)
        end
    end)
    button:SetScript("OnReceiveDrag", function(self)
        DropOnContainer(Affected(self).buffContainerIndex)
    end)
    button:SetScript("OnEnter", function(self)
        local entry = Affected(self).buffEntry
        if entry and entry.spellID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(entry.spellID)
            GameTooltip:Show()
        elseif Affected(self).buffEmpty then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Empty Slot")
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnLeave", function()
        GameTooltip_Hide()
    end)
    button:HookScript("OnShow", function(self)
        if not self.Icon then
            return
        end
        if Affected(self).buffEmpty then
            self.Icon:SetTexture(nil)
            self.Icon:SetAtlas("cdm-empty", true)
            self.Icon:SetDesaturated(false)
        elseif Affected(self).buffEntry then
            self.Icon:SetAtlas(nil)
            self.Icon:SetTexture(Affected(self).buffEntry.iconID or 134400)
        end
    end)

    Affected(button).buffInitialized = true
end

local function AcquireButton(category)
    local button = category.itemPool:Acquire()
    InitializeButton(button)
    button:Show()
    return button
end

-- Lays a section's buffs into its Blizzard GridLayoutFrame .Container (same template
-- + Layout params the tracker uses), then sizes the category from the header/content
-- extent. This is what makes the widths/anchors match the other tabs 1:1.
local function LayoutCategory(category, entries)
    category.itemPool:ReleaseAll()

    local container = category.Container
    local headerHeight = category.Header:GetHeight()

    if #entries == 0 then
        local button = AcquireButton(category)
        Affected(button).buffEmpty = true
        Affected(button).buffEntry = nil
        Affected(button).buffContainerIndex = category.containerIndex
        button.layoutIndex = 1
        button:ClearAllPoints()
        button:SetSize(ITEM_SIZE, ITEM_SIZE)
        if button.Icon then
            button.Icon:SetTexture(nil)
            button.Icon:SetAtlas("cdm-empty", true)
            button.Icon:SetDesaturated(false)
        end
        if button.Cooldown then
            CooldownFrame_Clear(button.Cooldown)
        end
    else
        for index, entry in ipairs(entries) do
            local button = AcquireButton(category)
            Affected(button).buffEmpty = false
            Affected(button).buffEntry = entry
            Affected(button).buffContainerIndex = category.containerIndex
            button.layoutIndex = index
            button:ClearAllPoints()
            button:SetSize(ITEM_SIZE, ITEM_SIZE)
            if button.Icon then
                button.Icon:SetAtlas(nil)
                button.Icon:SetTexture(entry.iconID or 134400)
                button.Icon:SetDesaturated(false)
            end
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
    category.Header:SetHeaderText(title)
    category:Layout()

    -- Sections here aren't collapsible/reorderable like Blizzard's.
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

    -- Dropping anywhere on the section (its GridLayoutFrame .Container from the
    -- template, or the category itself) assigns the dragged buff to it.
    local function onDrop()
        DropOnContainer(containerIndex)
    end
    category:SetScript("OnReceiveDrag", onDrop)
    category:SetScript("OnMouseUp", function(_, btn)
        if btn == "LeftButton" and IsDragging() then
            onDrop()
        end
    end)
    if category.Container then
        category.Container:SetScript("OnReceiveDrag", onDrop)
        category.Container:SetScript("OnMouseUp", function(_, btn)
            if btn == "LeftButton" and IsDragging() then
                onDrop()
            end
        end)
    end

    category.itemPool = CreateFramePool(
        "Frame",
        category.Container,
        "CooldownViewerSettingsItemTemplate",
        function(_, f)
            f:Hide()
            f.layoutIndex = nil
            Affected(f).buffEntry = nil
            Affected(f).buffEmpty = nil
            if f.Icon then
                f.Icon:SetTexture(nil)
            end
        end
    )

    return category
end

local function RefreshPanelInternal(settingsFrame)
    if not BuffData.IsEnabled() then
        return
    end
    local frame = settingsFrame or _G["CooldownViewerSettings"]
    if not frame then
        return
    end
    local panel = Affected(frame).buffPanel
    if not panel then
        return
    end

    if panel.SetPortraitTextureRaw then
        panel:SetPortraitTextureRaw(PORTRAIT)
    end

    BuffData.ScanTrackedBuffs(true)
    BuffData.ReconcileContainerCount()
    if ns.BuffContainerViewer then
        ns.BuffContainerViewer:EnsureContainers()
    end

    local defaultCategory = Affected(panel).buffDefaultCategory
    local containerCategories = Affected(panel).buffContainerCategories
    local scrollChild = Affected(panel).buffScrollChild
    local scrollFrame = Affected(panel).buffScrollFrame
    if not defaultCategory or not containerCategories or not scrollChild then
        return
    end

    local searchTerm = Affected(panel).buffSearchTerm
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
    local revealedNew = false
    for i = 1, #containerCategories do
        local category = containerCategories[i]
        if i <= count then
            if not category:IsShown() then
                revealedNew = true
            end
            category:Show()
            LayoutCategory(category, filter(BuffData.GetBuffsForContainer(i)))
            ordered[#ordered + 1] = category
        else
            category:Hide()
        end
    end

    -- Stack the sections (TOPLEFT chain, 18px gap) exactly like the tracker; the
    -- category template (ResizeLayoutFrame) supplies each section's own width.
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

    if revealedNew then
        C_Timer.After(0.1, function()
            BuffAssignmentPanel:RefreshPanel(settingsFrame)
        end)
    end
end

-- Guarded so a refresh error can never propagate out of panel:Show()/OnShow and
-- leave the settings window blank (native content hidden, panel not populated).
function BuffAssignmentPanel:RefreshPanel(settingsFrame)
    local ok, err = pcall(RefreshPanelInternal, settingsFrame)
    if not ok and ns.Addon then
        ns.Addon:Print("|cffff5555CMC buff panel error:|r " .. tostring(err))
    end
end

local function ShowBuffPanel(settingsFrame)
    local panel = Affected(settingsFrame).buffPanel
    if not panel then
        return
    end
    ns.SettingsTabs:Activate(settingsFrame, panel, function()
        BuffAssignmentPanel:RefreshPanel(settingsFrame)
    end)
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

-- When the feature is turned off while the settings window is open on the Buffs tab,
-- drop the panel and switch back to the first tab so the user isn't stranded on an
-- empty/disabled tab. Mirrors TrackerAssignmentPanel:OnTrackerDisabled.
function BuffAssignmentPanel:OnBuffContainersDisabled()
    local settingsFrame = _G["CooldownViewerSettings"]
    if not settingsFrame then
        return
    end
    local panel = Affected(settingsFrame).buffPanel
    if not panel or not panel:IsShown() then
        return
    end
    if settingsFrame.SetDisplayMode then
        settingsFrame:SetDisplayMode("spells")
    elseif ns.SettingsTabs then
        ns.SettingsTabs:DeactivateAll(settingsFrame)
    end
end

function BuffAssignmentPanel:EnsureSettingsTab(settingsFrame)
    if Affected(settingsFrame).buffPanel then
        return
    end

    local panel = CreateFrame("Frame", "_cmc_buff_panel", settingsFrame, "ButtonFrameTemplate")
    panel:SetAllPoints(settingsFrame)
    panel:Hide()
    -- The shared manager flags this as chrome (cmcCustomPanel/trackerIsTabButton) when
    -- we RegisterPanel below, so no "hide native content" pass grabs it.
    if panel.Inset and panel.Inset.Bg then
        panel.Inset.Bg:SetAtlas("character-panel-background", true)
        panel.Inset.Bg:SetHorizTile(false)
        panel.Inset.Bg:SetVertTile(false)
    end
    if panel.TitleContainer and panel.TitleContainer.TitleText then
        panel.TitleContainer.TitleText:SetText(ns.API.GradientText("CMC") .. " Buffs")
    end
    if panel.CloseButton then
        panel.CloseButton:SetScript("OnClick", function()
            HideUIPanel(settingsFrame)
        end)
    end
    Affected(settingsFrame).buffPanel = panel

    -- Released a drag over empty space (no section handled OnReceiveDrag): cancel.
    panel:SetScript("OnEvent", function(_, event)
        if event == "GLOBAL_MOUSE_UP" and IsDragging() then
            EndBuffDrag()
        end
    end)

    local scrollFrame = CreateFrame("ScrollFrame", "$parent.BuffScroll", panel, "ScrollFrameTemplate")
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
        BuffAssignmentPanel:RefreshPanel(settingsFrame)
    end)

    Affected(panel).buffScrollChild = scrollChild
    Affected(panel).buffScrollFrame = scrollFrame

    -- Search box, positioned like the tracker/native tabs' search.
    local searchBox = CreateFrame("EditBox", nil, panel, "SearchBoxTemplate")
    searchBox:SetSize(290, 30)
    searchBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 72, -30)
    searchBox.Instructions:SetText("Enter search text")
    searchBox:SetScript("OnTextChanged", function(self)
        self.Instructions:SetShown(self:GetText() == "")
        Affected(panel).buffSearchTerm = self:GetText()
        BuffAssignmentPanel:RefreshPanel(settingsFrame)
    end)
    searchBox:Hide()
    Affected(panel).buffSearchBox = searchBox

    local trackMoreButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    trackMoreButton:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 4)
    trackMoreButton:SetHeight(22)
    trackMoreButton:SetText("Add more 'Tracked Buffs' in Buffs tab")
    trackMoreButton:SetWidth(trackMoreButton:GetFontString():GetStringWidth() + 30)
    trackMoreButton:SetScript("OnClick", function()
        settingsFrame:SetDisplayMode("auras")
    end)
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

    -- Pre-create the default section plus the full pool of container sections
    -- (template frames can't be destroyed); RefreshPanel shows only the active ones.
    local defaultCategory = CreateCategory(scrollChild, "Default Tracked Buffs Frame", nil)
    Affected(panel).buffDefaultCategory = defaultCategory

    local containerCategories = {}
    for i = 1, BuffData.GetMaxContainers() do
        containerCategories[i] = CreateCategory(scrollChild, "Buffs " .. i, i)
        containerCategories[i]:Hide()
    end
    Affected(panel).buffContainerCategories = containerCategories

    panel:HookScript("OnShow", function()
        scrollChild:SetWidth(scrollFrame:GetWidth())
        searchBox:Show()
        BuffAssignmentPanel:RefreshPanel(settingsFrame)
    end)
    panel:HookScript("OnHide", function()
        searchBox:Hide()
        EndBuffDrag()
    end)

    local spellsTab = settingsFrame.SpellsTab
    local aurasTab = settingsFrame.AurasTab
    local groupBuffsTab = settingsFrame.GroupBuffsTab
    local trackerTab = Affected(settingsFrame).trackerMiscTab

    local buffTab = CreateFrame("Button", nil, UIParent, "CooldownViewerSettingsTabTemplate")
    Affected(buffTab).trackerIsTabButton = true
    Affected(buffTab).cmcCustomTab = true
    buffTab.tooltipText = ns.API.GradientText("CMC") .. " Buffs"
    buffTab.activeAtlas = "icon_trackedbuffs"
    buffTab.inactiveAtlas = "icon_trackedbuffs"
    buffTab.Icon:SetDesaturated(true)
    buffTab.Icon:SetVertexColor(1, 1, 1, 1)
    buffTab.Icon:SetGradient("VERTICAL", CreateColor(0, 0.41, 0.405), CreateColor(0.825, 0.93, 0))

    buffTab:SetChecked(false)
    if trackerTab then
        buffTab:SetPoint("TOP", trackerTab, "BOTTOM", 0, -3)
    elseif groupBuffsTab then
        buffTab:SetPoint("TOP", groupBuffsTab, "BOTTOM", 0, -3)
    else
        buffTab:SetPoint("TOP", aurasTab, "BOTTOM", 0, -3)
    end

    Affected(settingsFrame).buffTab = buffTab
    ns.SettingsTabs:RegisterPanel(settingsFrame, panel, buffTab, "Buffs")

    settingsFrame:HookScript("OnHide", function()
        buffTab:Hide()
    end)
    settingsFrame:HookScript("OnShow", function()
        buffTab:Show()
    end)

    -- Native-tab clicks route through SetDisplayMode; the tracker's hook already calls
    -- the shared manager's DeactivateAll (which drops every registered custom panel,
    -- including this one), so no separate hook is needed here.

    local function ShowBuffTab()
        if Affected(settingsFrame).buffPanel:IsShown() then
            return
        end
        -- Native tabs' checked state is Blizzard's; uncheck them here. The manager
        -- checks buffTab and unchecks the other custom tabs in Activate.
        if spellsTab then
            spellsTab:SetChecked(false)
        end
        if aurasTab then
            aurasTab:SetChecked(false)
        end
        if groupBuffsTab then
            groupBuffsTab:SetChecked(false)
        end
        ShowBuffPanel(settingsFrame)
    end

    buffTab:SetScript("OnClick", function()
        if not BuffData.IsEnabled() then
            StaticPopup_Show("CMC_ENABLE_BUFF_CONTAINERS", nil, nil, ShowBuffTab)
            return
        end
        ShowBuffTab()
    end)

    buffTab:Show()
end
