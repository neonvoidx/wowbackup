-- Overachiever2_Tabs: Suggestions Tab
-- Shows zone-appropriate achievement suggestions based on the player's current location.

local addonName, ns = ...

local GetAchievementInfo = GetAchievementInfo

local Overachiever2 = _G["Overachiever2"]
local Utils = Overachiever2 and Overachiever2.Utils

-- State
local settings
local achievementList
local currentResults = {}      -- array of achievement IDs (for display)
local currentResultsMap = {}   -- map from CollectSuggestions: [achID] = { {criteriaUID, criteriaIndex}, ... }
local sortMode = 0
local includeCompleted = false
local includeOtherFaction = false
local lastMapID = nil
local frame, tab, leftPane

local SORT_LABELS = { "Name", "Complete", "Points", "ID" }

-- UI elements
local ResultsLabel, LocationLabel

-- ============================================================================
-- Core Functions
-- ============================================================================

local function GetCurrentMapID()
    return C_Map.GetBestMapForUnit("player")
end

local function HasZoneChanged()
    return GetCurrentMapID() ~= lastMapID
end

local function GetMapName(mapID)
    if not mapID then return "Unknown" end
    local info = C_Map.GetMapInfo(mapID)
    local name = info and info.name or ("Map " .. mapID)
    if Utils.IsDebugMode() then
        name = name .. "  |cff888888(ID: " .. mapID .. ")|r"
    end
    return name
end

local function RefreshSuggestions()
    if not achievementList then return end

    lastMapID = GetCurrentMapID()

    -- Update location label
    if LocationLabel then
        LocationLabel:SetText(GetMapName(lastMapID) or "Unknown")
    end

    if not lastMapID then
        currentResults = {}
        achievementList:SetAchievements({})
        if ResultsLabel then
            ResultsLabel:SetText(ns.L["TAB_SUGGESTIONS_EMPTY"])
            ResultsLabel:Show()
        end
        return
    end

    -- Collect suggestions from the engine
    currentResultsMap = ns.SuggestionsEngine.CollectSuggestions(lastMapID, {
        includeCompleted = includeCompleted,
        includeOtherFaction = includeOtherFaction,
    })

    -- Extract achievement IDs into an array for sorting/display
    currentResults = {}
    for achID in pairs(currentResultsMap) do
        currentResults[#currentResults + 1] = achID
    end

    -- Sort
    ns.SortAchievements(currentResults, sortMode)

    -- Display
    achievementList:SetAchievements(currentResults)

    if ResultsLabel then
        if #currentResults > 0 then
            ResultsLabel:SetText(string.format(ns.L["TAB_SUGGESTIONS_RESULTS"], #currentResults))
        else
            ResultsLabel:SetText(ns.L["TAB_SUGGESTIONS_EMPTY"])
        end
        ResultsLabel:Show()
    end
end

-- ============================================================================
-- Sort Dropdown
-- ============================================================================

local function SetSortMode(newMode)
    sortMode = newMode
    if settings then
        settings.SuggestionsSort = sortMode
    end
    if #currentResults > 0 then
        ns.SortAchievements(currentResults, sortMode)
        achievementList:SetAchievements(currentResults)
    end
end

-- ============================================================================
-- Initialization (called once on first tab show)
-- ============================================================================

local function InitSuggestions(self)
    -- Saved variables
    settings = Overachiever2_Tabs_Settings or {}
    Overachiever2_Tabs_Settings = settings

    settings.SuggestionsSort = settings.SuggestionsSort or 0
    sortMode = settings.SuggestionsSort
    if settings.SuggestionsIncludeCompleted == nil then
        settings.SuggestionsIncludeCompleted = false
    end
    includeCompleted = settings.SuggestionsIncludeCompleted
    if settings.SuggestionsIncludeOtherFaction == nil then
        settings.SuggestionsIncludeOtherFaction = false
    end
    includeOtherFaction = settings.SuggestionsIncludeOtherFaction

    -- Left pane container
    leftPane = CreateFrame("Frame", nil, AchievementFrameCategories)
    leftPane:SetAllPoints()
    leftPane:Hide()

    -- Title label
    local titleLabel = leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    titleLabel:SetPoint("TOPLEFT", leftPane, "TOPLEFT", 12, -10)
    titleLabel:SetText(ns.L["TAB_SUGGESTIONS"])

    -- Help icon
    local helpIcon = CreateFrame("Frame", nil, leftPane)
    helpIcon:SetSize(32, 32)
    helpIcon:SetPoint("LEFT", titleLabel, "RIGHT", 0, 0)

    local helpTexture = helpIcon:CreateTexture(nil, "ARTWORK")
    helpTexture:SetAllPoints()
    helpTexture:SetTexture("Interface\\common\\help-i")

    helpIcon:SetScript("OnEnter", function(self)
        Utils.ShowTip(self, "ANCHOR_RIGHT", ns.L["TAB_SUGGESTIONS"], ns.L["TAB_SUGGESTIONS_DESC"])
    end)
    helpIcon:SetScript("OnLeave", function() Utils.HideTip() end)

    -- Sort dropdown
    local sortLabel = leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    sortLabel:SetPoint("TOPLEFT", titleLabel, "BOTTOMLEFT", 0, -15)
    sortLabel:SetText(Utils.WhiteText(ns.L["SORT_BY"]))

    local sortDropdown = CreateFrame("DropdownButton", nil, leftPane, "WowStyle2DropdownTemplate")
    sortDropdown:SetSize(173, 22)
    sortDropdown:SetPoint("TOPLEFT", sortLabel, "BOTTOMLEFT", 0, -3)
    sortDropdown:SetupMenu(function(dropdown, rootDescription)
        rootDescription:SetTag("MENU_OVERACHIEVER2_SUGGESTIONS_SORT")
        for i, label in ipairs(SORT_LABELS) do
            local mode = i - 1
            rootDescription:CreateRadio(label, function() return sortMode == mode end, SetSortMode, mode)
        end
    end)
    sortDropdown:SetDefaultText("Sort: " .. SORT_LABELS[sortMode + 1])

    -- Location editbox (read-only, with built-in label)
    LocationLabel = Utils.CreateEditBox(leftPane, Utils.WhiteText(ns.L["TAB_SUGGESTIONS_LOCATION"]), sortDropdown, 5, -25)
    LocationLabel:SetWidth(168)
    LocationLabel:EnableMouse(false)

    -- Include completed checkbox
    local includeCompletedCB = CreateFrame("CheckButton", nil, leftPane, "InterfaceOptionsCheckButtonTemplate")
    includeCompletedCB:SetPoint("TOPLEFT", LocationLabel, "BOTTOMLEFT", -6, -8)
    includeCompletedCB.Text:SetText(ns.L["TAB_SUGGESTIONS_INCLUDE_COMPLETED"])
    includeCompletedCB.Text:SetFontObject("GameFontHighlight")
    includeCompletedCB.Text:SetWidth(150)
    includeCompletedCB.Text:SetWordWrap(true)
    includeCompletedCB.Text:SetJustifyH("LEFT")
    includeCompletedCB:SetChecked(includeCompleted)
    includeCompletedCB:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        includeCompleted = checked
        if settings then
            settings.SuggestionsIncludeCompleted = checked
        end
        PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        RefreshSuggestions()
    end)
    includeCompletedCB:SetScript("OnEnter", function(self)
        Utils.ShowTip(self, "ANCHOR_RIGHT",
            ns.L["TAB_SUGGESTIONS_INCLUDE_COMPLETED"],
            ns.L["TAB_SUGGESTIONS_INCLUDE_COMPLETED_TIP"])
    end)
    includeCompletedCB:SetScript("OnLeave", function() Utils.HideTip() end)

    -- Include other faction checkbox
    local includeOtherFactionCB = CreateFrame("CheckButton", nil, leftPane, "InterfaceOptionsCheckButtonTemplate")
    includeOtherFactionCB:SetPoint("TOPLEFT", includeCompletedCB, "BOTTOMLEFT", 0, -4)
    includeOtherFactionCB.Text:SetText(ns.L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION"])
    includeOtherFactionCB.Text:SetFontObject("GameFontHighlight")
    includeOtherFactionCB.Text:SetWidth(150)
    includeOtherFactionCB.Text:SetWordWrap(true)
    includeOtherFactionCB.Text:SetJustifyH("LEFT")
    includeOtherFactionCB:SetChecked(includeOtherFaction)
    includeOtherFactionCB:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        includeOtherFaction = checked
        if settings then
            settings.SuggestionsIncludeOtherFaction = checked
        end
        PlaySound(checked and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        RefreshSuggestions()
    end)
    includeOtherFactionCB:SetScript("OnEnter", function(self)
        Utils.ShowTip(self, "ANCHOR_RIGHT",
            ns.L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION"],
            ns.L["TAB_SUGGESTIONS_INCLUDE_OTHER_FACTION_TIP"])
    end)
    includeOtherFactionCB:SetScript("OnLeave", function() Utils.HideTip() end)

    -- Results label
    ResultsLabel = leftPane:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ResultsLabel:SetPoint("TOPLEFT", includeOtherFactionCB, "BOTTOMLEFT", 6, -8)
    ResultsLabel:SetWidth(170)
    ResultsLabel:SetJustifyH("LEFT")
    ResultsLabel:SetWordWrap(true)
    ResultsLabel:Hide()

    -- Achievement list widget
    achievementList = ns.CreateAchievementList(self, {
        emptyText = ns.L["TAB_SUGGESTIONS_EMPTY"],
        enableAltClickAddToWatch = true,
    })

    -- Register zone change event to auto-refresh
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("NEW_WMO_CHUNK")
    eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    eventFrame:RegisterEvent("ZONE_CHANGED")
    eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
    eventFrame:RegisterEvent("NEW_WMO_CHUNK")
    eventFrame:SetScript("OnEvent", function()
        if frame and frame:IsShown() and HasZoneChanged() then
            RefreshSuggestions()
        end
    end)

    -- Initial refresh
    RefreshSuggestions()
end

-- ============================================================================
-- Tab Registration
-- ============================================================================

local function OnSuggestionsShow()
    if leftPane then leftPane:Show() end
    RefreshSuggestions()
end

local function OnSuggestionsHide()
    if leftPane then leftPane:Hide() end
end

frame, tab = ns.RegisterTab("Overachiever2_SuggestionsFrame", ns.L["TAB_SUGGESTIONS"], {
    showCategories = false,
    loadFunc = InitSuggestions,
    onShow = OnSuggestionsShow,
    onHide = OnSuggestionsHide,
})