-- Overachiever2_Tabs: AchievementList
-- Reusable ScrollBox-based achievement list widget using Blizzard's AchievementTemplate
-- Used by Watch, Search, Suggestion tabs

local addonName, ns = ...

local Overachiever2 = _G["Overachiever2"]
local Utils = Overachiever2 and Overachiever2.Utils

local GetAchievementInfo = GetAchievementInfo
local sort = table.sort

-- ============================================================================
-- Sorting Utility (shared across all tabs)
-- ============================================================================

local sortFuncs = {
    -- 0: Name (alphabetical)
    [0] = function(a, b)
        local nameA = select(2, GetAchievementInfo(a)) or ""
        local nameB = select(2, GetAchievementInfo(b)) or ""
        return nameA < nameB
    end,
    -- 1: Completion (completed first, then by name)
    [1] = function(a, b)
        local _, nameA, _, compA = GetAchievementInfo(a)
        local _, nameB, _, compB = GetAchievementInfo(b)
        if compA ~= compB then return compA end
        return (nameA or "") < (nameB or "")
    end,
    -- 2: Points (descending, then by name)
    [2] = function(a, b)
        local _, nameA, ptsA = GetAchievementInfo(a)
        local _, nameB, ptsB = GetAchievementInfo(b)
        if ptsA ~= ptsB then return (ptsA or 0) > (ptsB or 0) end
        return (nameA or "") < (nameB or "")
    end,
    -- 3: ID (ascending)
    [3] = function(a, b)
        return a < b
    end,
}

function ns.SortAchievements(idArray, mode)
    local func = sortFuncs[mode or 0] or sortFuncs[0]
    sort(idArray, func)
    return idArray
end

-- ============================================================================
-- Tab Flash Utility (shared across all tabs)
-- ============================================================================

function ns.FlashTab(tab)
    if not tab then return end
    if not tab.flashAnim then
        local highlight = tab:CreateTexture(nil, "OVERLAY")
        highlight:SetAllPoints()
        highlight:SetColorTexture(1, 0.82, 0, 0.3)
        highlight:SetAlpha(0)
        tab.flashHighlight = highlight

        local ag = highlight:CreateAnimationGroup()
        local fadeIn = ag:CreateAnimation("Alpha")
        fadeIn:SetFromAlpha(0)
        fadeIn:SetToAlpha(1)
        fadeIn:SetDuration(0.2)
        fadeIn:SetOrder(1)

        local fadeOut = ag:CreateAnimation("Alpha")
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0)
        fadeOut:SetDuration(0.4)
        fadeOut:SetOrder(2)

        ag:SetScript("OnFinished", function()
            highlight:SetAlpha(0)
        end)
        tab.flashAnim = ag
    end
    tab.flashHighlight:SetAlpha(0)
    tab.flashAnim:Stop()
    tab.flashAnim:Play()
end

-- ============================================================================
-- Achievement List Widget (uses Blizzard's AchievementTemplate)
-- ============================================================================

local COLLAPSED_HEIGHT = ACHIEVEMENTBUTTON_COLLAPSEDHEIGHT or 84
local SCROLLBAR_WIDTH = 20
local PADDING_V = 4
local REMOVE_BTN_SIZE = 20

-- Constants that are local in Blizzard's code — we need our own copies
local OA_FONTHEIGHT = nil -- lazily initialized from an AchievementTemplate button
local OA_MAX_LINES_COLLAPSED = 3
local OA_FORCE_COLUMNS_MAX_WIDTH = 220
local OA_FORCE_COLUMNS_MIN_CRITERIA = 20

-- Private measurement frames to avoid tainting Blizzard's protected PlaceholderName/PlaceholderHiddenDescription
local measureFrame = CreateFrame("Frame")
measureFrame:SetSize(1, 1)
local measureName = measureFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
local measureDesc = measureFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
-- Copy dimensions from Blizzard's placeholders once AchievementFrame is available
local measureInitialized = false
local function EnsureMeasureFrames()
    if measureInitialized then return end
    if AchievementFrame and AchievementFrame.PlaceholderName then
        local font, size, flags = AchievementFrame.PlaceholderName:GetFont()
        if font then measureName:SetFont(font, size, flags) end
        measureName:SetWidth(AchievementFrame.PlaceholderName:GetWidth())
    end
    if AchievementFrame and AchievementFrame.PlaceholderHiddenDescription then
        local font, size, flags = AchievementFrame.PlaceholderHiddenDescription:GetFont()
        if font then measureDesc:SetFont(font, size, flags) end
        measureDesc:SetWidth(AchievementFrame.PlaceholderHiddenDescription:GetWidth())
    end
    measureInitialized = true
end

-- Our own height calculator that uses GetAchievementInfo(id) instead of (category, index).
-- Blizzard's CalculateSelectedHeight requires category+index which we don't have.
local function CalculateSelectedHeightByID(elementData)
    local id = elementData.id
    if not id then return COLLAPSED_HEIGHT end

    local totalHeight = COLLAPSED_HEIGHT
    local objectivesHeight = 0

    EnsureMeasureFrames()
    if not ns.textCheckWidth then
        measureName:SetText("- ")
        ns.textCheckWidth = measureName:GetStringWidth()
    end

    local _, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = GetAchievementInfo(id)
    if not name then return COLLAPSED_HEIGHT end

    -- Lazily get font height from an existing AchievementTemplate Description font
    if not OA_FONTHEIGHT then
        local button = AchievementFrameAchievements and AchievementFrameAchievements.ScrollBox
            and AchievementFrameAchievements.ScrollBox:FindFrameByPredicate(function() return true end)
        if button and button.Description then
            local _, fontHeight = button.Description:GetFont()
            OA_FONTHEIGHT = fontHeight
        end
        if not OA_FONTHEIGHT then
            OA_FONTHEIGHT = 12 -- safe fallback
        end
    end

    if completed and GetPreviousAchievement(id) then
        local achievementCount = 1
        local nextID = id
        while GetPreviousAchievement(nextID) do
            achievementCount = achievementCount + 1
            nextID = GetPreviousAchievement(nextID)
        end
        local MaxAchievementsPerRow = 6
        objectivesHeight = math.ceil(achievementCount / MaxAchievementsPerRow) * ACHIEVEMENTUI_PROGRESSIVEHEIGHT
    else
        local numExtraCriteriaRows = 0
        local maxCriteriaWidth = 0
        local textStrings = 0
        local progressBars = 0
        local metas = 0
        local numMetaRows = 0
        local numCriteriaRows = 0
        if not completed then
            local requiresRep = GetAchievementGuildRep(id)
            if requiresRep then
                numExtraCriteriaRows = numExtraCriteriaRows + 1
            end
        end

        local numCriteria = GetAchievementNumCriteria(id)
        for i = 1, numCriteria do
            local criteriaString, criteriaType, criteriaCompleted, quantity, reqQuantity, charName, criteriaFlags, assetID, quantityString = GetAchievementCriteriaInfo(id, i)
            if criteriaType == CRITERIA_TYPE_ACHIEVEMENT and assetID then
                metas = metas + 1
                if metas == 1 or (math.fmod(metas, 2) ~= 0) then
                    numMetaRows = numMetaRows + 1
                end
            elseif bit.band(criteriaFlags, EVALUATION_TREE_FLAG_PROGRESS_BAR) == EVALUATION_TREE_FLAG_PROGRESS_BAR then
                progressBars = progressBars + 1
                numCriteriaRows = numCriteriaRows + 1
            else
                textStrings = textStrings + 1
                local stringWidth = 0
                local maxCriteriaContentWidth
                if criteriaCompleted then
                    maxCriteriaContentWidth = ACHIEVEMENTUI_MAXCONTENTWIDTH - ACHIEVEMENTUI_CRITERIACHECKWIDTH
                    measureName:SetText(criteriaString)
                    stringWidth = math.min(measureName:GetStringWidth(), maxCriteriaContentWidth)
                else
                    maxCriteriaContentWidth = ACHIEVEMENTUI_MAXCONTENTWIDTH - ns.textCheckWidth
                    local dashedString = "- " .. criteriaString
                    measureName:SetText(dashedString)
                    stringWidth = math.min(measureName:GetStringWidth() - ns.textCheckWidth, maxCriteriaContentWidth)
                end
                if measureName:GetWidth() > maxCriteriaContentWidth then
                    measureName:SetWidth(maxCriteriaContentWidth)
                end
                maxCriteriaWidth = math.max(maxCriteriaWidth, stringWidth + ACHIEVEMENTUI_CRITERIACHECKWIDTH)
                numCriteriaRows = numCriteriaRows + 1
            end
        end

        if textStrings > 0 and progressBars > 0 then
            -- mixed, no column optimization
        elseif textStrings > 1 then
            local numColumns = math.floor(ACHIEVEMENTUI_MAXCONTENTWIDTH / maxCriteriaWidth)
            local forceColumns = numColumns == 1 and textStrings >= OA_FORCE_COLUMNS_MIN_CRITERIA and maxCriteriaWidth <= OA_FORCE_COLUMNS_MAX_WIDTH
            if forceColumns then
                numColumns = 2
            end
            if numColumns > 1 then
                numCriteriaRows = math.ceil(numCriteriaRows / numColumns)
            end
        end

        numCriteriaRows = numCriteriaRows + numExtraCriteriaRows
        local height = numMetaRows * ACHIEVEMENTBUTTON_METAROWHEIGHT + numCriteriaRows * ACHIEVEMENTBUTTON_CRITERIAROWHEIGHT
        if metas > 0 or progressBars > 0 then
            height = height + 10
        end
        objectivesHeight = height
    end

    totalHeight = totalHeight + objectivesHeight

    measureDesc:SetText(description)
    local numLines = math.ceil(measureDesc:GetHeight() / OA_FONTHEIGHT)
    if (totalHeight ~= COLLAPSED_HEIGHT) or (numLines > OA_MAX_LINES_COLLAPSED) then
        local descriptionHeight = measureDesc:GetHeight()
        totalHeight = totalHeight + descriptionHeight - ACHIEVEMENTBUTTON_DESCRIPTIONHEIGHT
        if rewardText ~= "" then
            totalHeight = totalHeight + 4
        end
    end

    return totalHeight
end

--[[
    ns.CreateAchievementList(parent, options) -> controller

    Creates a ScrollBox-based achievement list using Blizzard's AchievementTemplate.

    Parameters:
        parent (Frame): The parent frame to attach the list to.
        options (table, optional):
            - topOffset (number): Extra vertical padding from the top of parent. Default: 0
            - showRemoveButton (boolean): Show a red X button on each row. Default: false
            - onRemove (function(id)): Callback when the remove button is clicked.
            - enableAltClickAddToWatch (boolean): Enable Alt+Click to add achievement to Watch tab. Default: false
            - emptyText (string): Text shown when the list is empty.
                Default: "No achievements to display."

    Returns:
        controller (table): Object with methods:
            :SetAchievements(idArray) - Replace the displayed list with the given IDs.
            :Refresh()               - Re-render the current list.
            :GetScrollBox()          - Return the underlying ScrollBox frame.
            :SetEmptyText(text)      - Change the empty-state label.
]]
function ns.CreateAchievementList(parent, options)
    options = options or {}
    local topOffset = options.topOffset or 0
    local showRemoveButton = options.showRemoveButton or false
    local onRemove = options.onRemove
    local enableAltClickAddToWatch = options.enableAltClickAddToWatch or false

    local controller = {}
    local currentData = {}

    -- ScrollBox (matches Blizzard's AchievementFrameAchievements.ScrollBox anchoring)
    local scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -(topOffset + 3))
    scrollBox:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 5)
    scrollBox:SetFrameStrata("HIGH")

    -- ScrollBar (outside parent to the right, matches Blizzard's layout)
    local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", parent, "TOPRIGHT", 6, -(topOffset + 8))
    scrollBar:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", 6, 6)
    scrollBar:SetFrameStrata("HIGH")

    -- Empty state label
    local emptyLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    emptyLabel:SetPoint("CENTER", parent, "CENTER", 0, 0)
    emptyLabel:SetText(options.emptyText or "No achievements to display.")
    emptyLabel:SetTextColor(0.6, 0.6, 0.6)
    emptyLabel:SetWidth(400)
    emptyLabel:Hide()

    -- Selection behavior (declared early so InitRow can reference it)
    local selectionBehavior

    -- Element initializer: uses Blizzard's AchievementTemplate for identical look
    local function InitRow(button, elementData)
        -- Let Blizzard's AchievementTemplateMixin:Init handle the visual setup
        button:Init(elementData)

        -- Override OnClick to use OUR selection behavior instead of Blizzard's
        -- (Blizzard's ProcessClick calls g_achievementSelectionBehavior:ToggleSelect
        -- which is a local var we can't access — so we replace the click handler)
        if not button.oaClickHooked then
            button.oaClickHooked = true
            button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            button:SetScript("OnClick", function(self, buttonName, down)
                -- Right-click actions
                if buttonName == "RightButton" then
                    -- Remove from the list (when remove button is enabled)
                    if showRemoveButton and IsAltKeyDown() and onRemove and self.id then
                        onRemove(self.id)
                    elseif self.id and ns.ContextMenu then
                        ns.ContextMenu.ShowForAchievement(self.id, self)
                    end
                    return
                end
                -- Alt+Click to add to Watch list (if enabled)
                if enableAltClickAddToWatch and IsAltKeyDown() and buttonName == "LeftButton" and self.id then
                    if ns.AddToWatchList then
                        ns.AddToWatchList(self.id)
                        return
                    end
                end
                -- Handle modifier clicks (chat link, tracking) via original ProcessClick logic
                local handled = false
                if IsModifiedClick() then
                    if IsModifiedClick("CHATLINK") then
                        local link = GetAchievementLink(self.id)
                        if link then
                            handled = ChatFrameUtil.InsertLink(link)
                        end
                    end
                    if not handled and IsModifiedClick("QUESTWATCHTOGGLE") then
                        if self.ToggleTracking then
                            self:ToggleTracking(self.id)
                        end
                        handled = true
                    end
                end
                -- For unhandled clicks (including normal clicks): toggle our selection
                if not handled and selectionBehavior then
                    selectionBehavior:ToggleSelect(self)
                end
            end)
        end

        -- Add remove button overlay (created once per button)
        if showRemoveButton and not button.oaRemoveBtn then
            local removeBtn = CreateFrame("Button", nil, button)
            removeBtn:SetSize(REMOVE_BTN_SIZE, REMOVE_BTN_SIZE)
            removeBtn:SetPoint("TOPRIGHT", button, "TOPRIGHT", -6, -6)
            removeBtn:SetFrameLevel(button:GetFrameLevel() + 10)

            removeBtn:SetNormalAtlas("common-icon-redx")
            removeBtn:SetHighlightAtlas("common-icon-redx")
            removeBtn:GetHighlightTexture():SetAlpha(0.5)

            removeBtn:SetScript("OnClick", function(self)
                local id = self:GetParent().id
                if onRemove and id then
                    onRemove(id)
                end
            end)
            removeBtn:SetScript("OnEnter", function(self)
                Utils.ShowTip(self, "ANCHOR_RIGHT", ns.L["TAB_WATCH_REMOVE_ACHIEVEMENT"])
            end)
            removeBtn:SetScript("OnLeave", function()
                Utils.HideTip()
            end)

            button.oaRemoveBtn = removeBtn
        end

        -- Ensure remove button is visible and on top
        if button.oaRemoveBtn then
            button.oaRemoveBtn:Show()
        end
    end

    -- View setup using Blizzard's AchievementTemplate
    local view = CreateScrollBoxListLinearView()
    view:SetElementInitializer("AchievementTemplate", InitRow)
    view:SetElementExtentCalculator(function(dataIndex, elementData)
        if SelectionBehaviorMixin.IsElementDataIntrusiveSelected(elementData) then
            return CalculateSelectedHeightByID(elementData)
        else
            return COLLAPSED_HEIGHT
        end
    end)
    view:SetPadding(2, 0, 0, 4, 0) -- matches Blizzard's AchievementFrameAchievements view padding

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

    -- Selection behavior: click to expand/collapse, matching Blizzard's achievement list
    selectionBehavior = ScrollUtil.AddSelectionBehavior(scrollBox, SelectionBehaviorFlags.Deselectable, SelectionBehaviorFlags.Intrusive)
    selectionBehavior:RegisterCallback(SelectionBehaviorMixin.Event.OnSelectionChanged, function(_, elementData, selected)
        local button = scrollBox:FindFrame(elementData)
        if button then
            button:SetSelected(selected)
        end
    end)
    ScrollUtil.AddResizableChildrenBehavior(scrollBox)

    -- Controller methods

    function controller:SetAchievements(idArray)
        currentData = idArray or {}
        self:Refresh()
    end

    function controller:Refresh()
        local dataProvider = CreateDataProvider()
        for _, id in ipairs(currentData) do
            dataProvider:Insert({ id = id })
        end
        scrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)

        if #currentData == 0 then
            emptyLabel:Show()
        else
            emptyLabel:Hide()
        end
    end

    function controller:GetScrollBox()
        return scrollBox
    end

    function controller:SetEmptyText(text)
        emptyLabel:SetText(text)
    end

    return controller
end
