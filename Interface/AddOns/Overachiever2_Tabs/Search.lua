-- Overachiever2_Tabs: Search Tab
-- Search for achievements by name, description, criteria, or rewards.

local addonName, ns = ...

local GetAchievementInfo = GetAchievementInfo
local PlaySound = PlaySound

local Overachiever2 = _G["Overachiever2"]
local Utils = Overachiever2 and Overachiever2.Utils

-- State
local settings       -- reference to Overachiever2_Tabs_Settings
local achievementList -- the shared list widget
local currentResults = {}  -- store current search results for re-sorting
local sortMode = 0
local searchType = 0
local includeUnlisted = false
local searchInProgress = false
local frame, tab, leftPane

local SORT_LABELS = { "Name", "Complete", "Points", "ID" }
local TYPE_LABELS = { "All", "Personal", "Guild", "Other" }

-- UI elements
local editBoxes = {}
local EditName, EditDesc, EditCriteria, EditReward, EditAny
local SubmitBtn, ResetBtn, ResultsLabel, SearchingLabel
local IncludeUnlistedCheckbox

-- ============================================================================
-- Core Functions
-- ============================================================================

local function ClearResults()
    currentResults = {}
    achievementList:SetAchievements({})
    ResultsLabel:Hide()
end

local function ProcessSearchResults(results)
    searchInProgress = false
    SearchingLabel:Hide()

    -- Store and sort results
    currentResults = results
    ns.SortAchievements(currentResults, sortMode)

    -- Display results
    achievementList:SetAchievements(currentResults)
    ResultsLabel:SetText(string.format(ns.L["TAB_SEARCH_RESULTS"], #currentResults))
    ResultsLabel:Show()
end

local function BeginSearch()
    if searchInProgress then return end
    if not Overachiever2 or not Overachiever2.StartFullSearch then
        print("|cffff0000Error: Search engine not loaded|r")
        return
    end

    -- Get search terms
    local nameOrID = EditName:GetText()
    local desc = EditDesc:GetText()
    local criteria = EditCriteria:GetText()
    local reward = EditReward:GetText()
    local any = EditAny:GetText()

    -- Check if at least one field is filled
    if nameOrID == "" and desc == "" and criteria == "" and reward == "" and any == "" then
        return
    end

    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)

    -- Determine achievement type
    local achType = nil
    local includeHidden = includeUnlisted

    if searchType == 1 then
        achType = "p"  -- Personal
    elseif searchType == 2 then
        achType = "g"  -- Guild
    elseif searchType == 3 then
        achType = "o"  -- Other
        includeHidden = true
    end

    -- Start search
    searchInProgress = true
    ClearResults()
    SearchingLabel:Show()

    Overachiever2.StartFullSearch(
        includeHidden,
        achType,
        false,  -- strictCase
        nameOrID,
        desc,
        criteria,
        reward,
        any,
        ProcessSearchResults
    )
end

local function ResetEditBoxes()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    for _, editBox in ipairs(editBoxes) do
        editBox:SetText("")
    end
    ClearResults()
end

-- ============================================================================
-- Sort Dropdown
-- ============================================================================

local function SetSortMode(newMode)
    sortMode = newMode
    if settings then
        settings.SearchSort = sortMode
    end
    -- Re-sort current results if any
    if #currentResults > 0 then
        ns.SortAchievements(currentResults, sortMode)
        achievementList:SetAchievements(currentResults)
    end
end

-- ============================================================================
-- Type Dropdown
-- ============================================================================

local function SetSearchType(newType)
    searchType = newType
    if settings then
        settings.SearchType = searchType
    end

    -- Disable "Include unlisted" checkbox for "Other" type
    if searchType == 3 then
        IncludeUnlistedCheckbox:Disable()
        IncludeUnlistedCheckbox.Text:SetTextColor(0.5, 0.5, 0.5)
    else
        IncludeUnlistedCheckbox:Enable()
        IncludeUnlistedCheckbox.Text:SetTextColor(1, 1, 1)
    end
end

-- ============================================================================
-- Include Unlisted Checkbox
-- ============================================================================

local function ToggleIncludeUnlisted()
    includeUnlisted = IncludeUnlistedCheckbox:GetChecked()
    if settings then
        settings.SearchFullList = includeUnlisted
    end
    PlaySound(includeUnlisted and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
end

-- ============================================================================
-- EditBox Helpers
-- ============================================================================

local function CreateEditBox(name, labelText, anchorTo, xOffset, yOffset)
    local editBox = Utils.CreateEditBox(leftPane, labelText, anchorTo, xOffset, yOffset)

    -- Enter key submits search
    editBox:SetScript("OnEnterPressed", BeginSearch)

    -- Tab key cycles through editboxes
    editBox:SetScript("OnTabPressed", function(self)
        self:SetAutoFocus(false)
        local nextIndex = nil
        for i, eb in ipairs(editBoxes) do
            if eb == self then
                nextIndex = (i % #editBoxes) + 1
                break
            end
        end
        if nextIndex then
            editBoxes[nextIndex]:SetFocus()
        end
    end)

    table.insert(editBoxes, editBox)
    return editBox
end

-- ============================================================================
-- Initialization (called once on first tab show)
-- ============================================================================

local function InitSearch(self)
    -- Saved variables
    settings = Overachiever2_Tabs_Settings or {}
    Overachiever2_Tabs_Settings = settings

    settings.SearchSort = settings.SearchSort or 0
    settings.SearchType = settings.SearchType or 0
    settings.SearchFullList = settings.SearchFullList or false

    sortMode = settings.SearchSort
    searchType = settings.SearchType
    includeUnlisted = settings.SearchFullList

    -- Left pane container
    leftPane = CreateFrame("Frame", nil, AchievementFrameCategories)
    leftPane:SetAllPoints()
    leftPane:Hide()

    -- Title label
    local titleLabel = leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    titleLabel:SetPoint("TOPLEFT", leftPane, "TOPLEFT", 12, -10)
    titleLabel:SetText(ns.L["TAB_SEARCH"])

    -- Help icon
    local helpIcon = CreateFrame("Frame", nil, leftPane)
    helpIcon:SetSize(32, 32)
    helpIcon:SetPoint("LEFT", titleLabel, "RIGHT", 0, 0)

    local helpTexture = helpIcon:CreateTexture(nil, "ARTWORK")
    helpTexture:SetAllPoints()
    helpTexture:SetTexture("Interface\\common\\help-i")

    helpIcon:SetScript("OnEnter", function(self)
        Utils.ShowTip(self, "ANCHOR_RIGHT", ns.L["TAB_SEARCH"], ns.L["TAB_SEARCH_DESC"])
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
        rootDescription:SetTag("MENU_OVERACHIEVER2_SEARCH_SORT")
        for i, label in ipairs(SORT_LABELS) do
            local mode = i - 1
            rootDescription:CreateRadio(label, function() return sortMode == mode end, SetSortMode, mode)
        end
    end)
    sortDropdown:SetDefaultText("Sort: " .. SORT_LABELS[sortMode + 1])

    -- EditBoxes
    EditName = CreateEditBox("Name", ns.L["TAB_SEARCH_NAME"], sortDropdown, 5, -25)
    EditDesc = CreateEditBox("Desc", ns.L["TAB_SEARCH_FIELD_DESC"], EditName)
    EditCriteria = CreateEditBox("Criteria", ns.L["TAB_SEARCH_CRITERIA"], EditDesc)
    EditReward = CreateEditBox("Reward", ns.L["TAB_SEARCH_REWARD"], EditCriteria)
    EditAny = CreateEditBox("Any", ns.L["TAB_SEARCH_ANY"], EditReward)
    EditName:SetWidth(168)
    EditDesc:SetWidth(168)
    EditCriteria:SetWidth(168)
    EditReward:SetWidth(168)
    EditAny:SetWidth(168)

    -- Type dropdown
    local typeLabel = leftPane:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    typeLabel:SetPoint("TOPLEFT", EditAny, "BOTTOMLEFT", -5, -15)
    typeLabel:SetText(Utils.WhiteText(ns.L["TAB_SEARCH_TYPE"]))

    local typeDropdown = CreateFrame("DropdownButton", nil, leftPane, "WowStyle2DropdownTemplate")
    typeDropdown:SetSize(173, 22)
    typeDropdown:SetPoint("TOPLEFT", typeLabel, "BOTTOMLEFT", 0, -3)
    typeDropdown:SetupMenu(function(dropdown, rootDescription)
        rootDescription:SetTag("MENU_OVERACHIEVER2_SEARCH_TYPE")
        for i, label in ipairs(TYPE_LABELS) do
            local typeValue = i - 1
            local labelText = ns.L["TAB_SEARCH_TYPE_" .. label:upper()] or label
            rootDescription:CreateRadio(labelText, function() return searchType == typeValue end, SetSearchType, typeValue)
        end
    end)
    typeDropdown:SetDefaultText("Type: " .. TYPE_LABELS[searchType + 1])

    -- Include unlisted checkbox
    IncludeUnlistedCheckbox = CreateFrame("CheckButton", nil, leftPane, "InterfaceOptionsCheckButtonTemplate")
    IncludeUnlistedCheckbox:SetPoint("TOPLEFT", typeDropdown, "BOTTOMLEFT", 0, -8)
    IncludeUnlistedCheckbox.Text:SetText(ns.L["TAB_SEARCH_INCLUDE_UNLISTED"])
    IncludeUnlistedCheckbox.Text:SetFontObject("GameFontHighlight")
    IncludeUnlistedCheckbox.Text:SetWidth(150)  -- Set max width, text will wrap
    IncludeUnlistedCheckbox.Text:SetWordWrap(true)  -- Enable word wrapping
    IncludeUnlistedCheckbox.Text:SetJustifyH("LEFT")  -- Left align the text
    IncludeUnlistedCheckbox:SetChecked(includeUnlisted)
    IncludeUnlistedCheckbox:SetScript("OnClick", ToggleIncludeUnlisted)
    IncludeUnlistedCheckbox:SetScript("OnEnter", function(self)
        local tip = Utils.OA2Tooltip
        tip:SetOwner(self, "ANCHOR_RIGHT")
        tip:SetText(ns.L["TAB_SEARCH_INCLUDE_UNLISTED_TIP"], 1, 1, 1, 1, true)
        tip:Show()
    end)
    IncludeUnlistedCheckbox:SetScript("OnLeave", function() Utils.HideTip() end)

    -- Submit button
    SubmitBtn = CreateFrame("Button", nil, leftPane, "UIPanelButtonTemplate")
    SubmitBtn:SetSize(84, 24)
    SubmitBtn:SetPoint("TOPLEFT", IncludeUnlistedCheckbox, "BOTTOMLEFT", 0, -8)
    SubmitBtn:SetText(ns.L["TAB_SEARCH_SUBMIT"])
    SubmitBtn:SetScript("OnClick", BeginSearch)

    -- Reset button
    ResetBtn = CreateFrame("Button", nil, leftPane, "UIPanelButtonTemplate")
    ResetBtn:SetSize(84, 24)
    ResetBtn:SetPoint("LEFT", SubmitBtn, "RIGHT", 5, 0)
    ResetBtn:SetText(ns.L["TAB_SEARCH_RESET"])
    ResetBtn:SetScript("OnClick", ResetEditBoxes)

    -- Results label
    ResultsLabel = leftPane:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ResultsLabel:SetPoint("TOPLEFT", SubmitBtn, "BOTTOMLEFT", 0, -8)
    ResultsLabel:Hide()

    -- Searching label (overlays the achievement list)
    SearchingLabel = self:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    SearchingLabel:SetPoint("TOP", self, "TOP", 0, -189)
    SearchingLabel:SetText(ns.L["TAB_SEARCH_SEARCHING"])
    SearchingLabel:SetTextColor(1, 1, 1)
    SearchingLabel:Hide()

    -- Achievement list widget
    achievementList = ns.CreateAchievementList(self, {
        emptyText = ns.L["TAB_SEARCH_EMPTY_TEXT"],
        enableAltClickAddToWatch = true,
    })

    -- Initialize type dropdown state
    SetSearchType(searchType)
end

-- ============================================================================
-- Tab Registration
-- ============================================================================

local function OnSearchShow()
    if leftPane then leftPane:Show() end
end

local function OnSearchHide()
    if leftPane then leftPane:Hide() end
end

-- Custom left-pane watermark for the Watch tab.
-- Change .texture to any valid texture path (e.g. "Interface\\AddOns\\YourAddon\\watermark").
-- Optional .texCoords = {left, right, top, bottom} defaults to {0, 1, 0, 1}.
local SEARCH_CATEGORY_WATERMARK = {
    texture = "Interface\\ARCHEOLOGY\\ArchRare-TheInnKeepersDaughter",
    texCoords = { 0.35, 0.85, 0, 1 },
}

frame, tab = ns.RegisterTab("Overachiever2_SearchFrame", ns.L["TAB_SEARCH"], {
    showCategories = false,
    loadFunc = InitSearch,
    onShow = OnSearchShow,
    onHide = OnSearchHide,
    -- categoryWaterMark = SEARCH_CATEGORY_WATERMARK, -- too noisy
})