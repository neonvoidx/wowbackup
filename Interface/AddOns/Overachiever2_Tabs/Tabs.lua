-- Overachiever2_Tabs: Tab Registration System
-- Modernized for Dragonflight/The War Within

local addonName, ns = ...

-- Get reference to parent addon namespace
local Overachiever2 = _G["Overachiever2"]
if not Overachiever2 then
    error("Overachiever2_Tabs requires Overachiever2 to be loaded first")
    return
end

-- Local references for performance
local CreateFrame = CreateFrame
local tinsert = table.insert

-- Tab tracking
local registeredTabs = {}
local activeCustomTab = nil -- tracks which custom tabInfo is currently shown
local BLIZZARD_TAB_COUNT = 3 -- Blizzard's built-in Achievement/Guild/Statistics tabs


-- ============================================================================
-- Manual Tab Visual Management (avoids tainting AchievementFrame.numTabs)
-- ============================================================================

-- Deselect all custom tabs visually
local function DeselectAllCustomTabs()
    for _, tabInfo in ipairs(registeredTabs) do
        PanelTemplates_DeselectTab(tabInfo.tab)
        tabInfo.tab.Text:SetPoint("CENTER", 0, -3)
    end
end

-- When a Blizzard tab is clicked, ensure custom tabs are visually deselected
hooksecurefunc("AchievementFrame_UpdateTabs", function(clickedTab)
    DeselectAllCustomTabs()
end)

-- When Blizzard navigates to a specific achievement (e.g. clicking a tracked
-- achievement in the objective tracker), switch back to tab 1 first so the
-- achievement is visible in the main Achievements panel instead of being hidden
-- behind a custom tab.
do
    local orig_SelectAchievement = AchievementFrame_SelectAchievement
    function AchievementFrame_SelectAchievement(id, forceSelect, ...)
        if activeCustomTab and AchievementFrameBaseTab_OnClick then
            AchievementFrameBaseTab_OnClick(1)
        end
        return orig_SelectAchievement(id, forceSelect, ...)
    end
end

-- ============================================================================
-- Tab Click Handlers
-- ============================================================================

local function OnTabClick(self, button)
    -- Reset Blizzard's internal achievementFunctions to non-guild mode.
    -- Without this, InGuildView() remains true after visiting the Guild tab,
    -- causing achievement items to render with guild background textures.
    if AchievementFrameBaseTab_OnClick then
        AchievementFrameBaseTab_OnClick(1)
    end

    -- Manually deselect Blizzard's built-in tabs (avoids tainting AchievementFrame.selectedTab)
    -- Also reset their text to the deselected y-offset (-3), since AchievementFrameBaseTab_OnClick
    -- above may have shifted tab 1's text to the selected position (-5).
    for i = 1, BLIZZARD_TAB_COUNT do
        local blizzTab = _G["AchievementFrameTab" .. i]
        if blizzTab then
            PanelTemplates_DeselectTab(blizzTab)
            blizzTab.Text:SetPoint("CENTER", 0, -3)
        end
    end

    -- Deselect all custom tabs, then select the clicked one
    DeselectAllCustomTabs()
    PanelTemplates_SelectTab(self)
    -- Match Blizzard's selected tab text offset
    self.Text:SetPoint("CENTER", 0, -5)

    -- Hide search results (normally done by AchievementFrame_UpdateTabs)
    if AchievementFrame.SearchResults then
        AchievementFrame.SearchResults:Hide()
    end

    if button then
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
    end

    -- Hide all Blizzard content subframes (Achievements, Stats, Summary, Comparison, etc.)
    if AchievementFrame_ShowSubFrame then
        AchievementFrame_ShowSubFrame()
    end

    -- Hide all custom tab frames
    for _, tabInfo in ipairs(registeredTabs) do
        if tabInfo.frame then
            tabInfo.frame:Hide()
        end
    end

    -- Find the tabInfo for the clicked tab
    local clickedTabInfo
    for _, tabInfo in ipairs(registeredTabs) do
        if tabInfo.tab == self then
            clickedTabInfo = tabInfo
            break
        end
    end

    -- Handle categories content and background visibility
    local CATEGORIES_DEFAULT_WIDTH = 175
    local CATEGORIES_EXPANDED_WIDTH = 197 -- absorbs the 22px scrollbar gap
    local CONTENT_DEFAULT_OFFSET = 22
    local CONTENT_EXPANDED_OFFSET = 0 -- keeps content frame in the same position

    if AchievementFrameCategories then
        if clickedTabInfo and clickedTabInfo.showCategories then
            if AchievementFrameCategories.ScrollBox then AchievementFrameCategories.ScrollBox:Show() end
            if AchievementFrameCategories.ScrollBar then AchievementFrameCategories.ScrollBar:Show() end
            AchievementFrameCategories:SetWidth(CATEGORIES_DEFAULT_WIDTH)
        else
            if AchievementFrameCategories.ScrollBox then AchievementFrameCategories.ScrollBox:Hide() end
            if AchievementFrameCategories.ScrollBar then AchievementFrameCategories.ScrollBar:Hide() end
            AchievementFrameCategories:SetWidth(CATEGORIES_EXPANDED_WIDTH)
        end

        -- Re-anchor all custom tab content frames so they stay in the same visual position
        local xOffset = (clickedTabInfo and not clickedTabInfo.showCategories)
            and CONTENT_EXPANDED_OFFSET or CONTENT_DEFAULT_OFFSET
        for _, tabInfo in ipairs(registeredTabs) do
            tabInfo.frame:SetPoint("TOPLEFT", AchievementFrameCategories, "TOPRIGHT", xOffset, 0)
        end

        -- Toggle gold border on the categories frame
        if clickedTabInfo and not clickedTabInfo.showCategoryBackground then
            AchievementFrameCategories:SetBackdropBorderColor(0, 0, 0, 0)
        elseif ACHIEVEMENT_GOLD_BORDER_COLOR then
            local c = ACHIEVEMENT_GOLD_BORDER_COLOR
            AchievementFrameCategories:SetBackdropBorderColor(c:GetRGBA())
        end

        -- Apply custom left-pane watermark if specified, otherwise hide it
        if AchievementFrameWaterMark then
            if clickedTabInfo and clickedTabInfo.categoryWaterMark then
                local bg = clickedTabInfo.categoryWaterMark
                AchievementFrameWaterMark:SetTexture(bg.texture)
                local tc = bg.texCoords or { 0, 1, 0, 1 }
                AchievementFrameWaterMark:SetTexCoord(tc[1], tc[2], tc[3], tc[4])
                AchievementFrameWaterMark:Show()
            else
                AchievementFrameWaterMark:Hide()
            end
        end

        AchievementFrameCategories:Show()
    end

    activeCustomTab = clickedTabInfo

    -- Show this tab's frame
    if self.frame then
        self.frame:Show()
    end
end

local function OnTabUnselect()
    -- Called when a Blizzard tab is clicked
    -- Hide custom frames
    for _, tabInfo in ipairs(registeredTabs) do
        if tabInfo.frame and tabInfo.frame:IsShown() then
            tabInfo.frame:Hide()
        end
    end

    -- Restore categories scroll content and border if a custom tab had hidden them
    if activeCustomTab and AchievementFrameCategories then
        if not activeCustomTab.showCategories then
            if AchievementFrameCategories.ScrollBox then AchievementFrameCategories.ScrollBox:Show() end
            if AchievementFrameCategories.ScrollBar then AchievementFrameCategories.ScrollBar:Show() end
            AchievementFrameCategories:SetWidth(175)
            -- Restore content frame anchors to default offset
            for _, tabInfo in ipairs(registeredTabs) do
                tabInfo.frame:SetPoint("TOPLEFT", AchievementFrameCategories, "TOPRIGHT", 22, 0)
            end
        end
        if not activeCustomTab.showCategoryBackground and ACHIEVEMENT_GOLD_BORDER_COLOR then
            local c = ACHIEVEMENT_GOLD_BORDER_COLOR
            AchievementFrameCategories:SetBackdropBorderColor(c:GetRGBA())
        end

        -- Re-show watermark and reset texCoords (Blizzard only calls SetTexture, not SetTexCoord)
        if AchievementFrameWaterMark then
            AchievementFrameWaterMark:SetTexCoord(0, 1, 0, 1)
            AchievementFrameWaterMark:Show()
        end

    end

    activeCustomTab = nil
end

-- ============================================================================
-- Core Tab Registration Function
-- ============================================================================

--[[
    ns.RegisterTab(name, title, options)

    Creates a new tab in the Achievement UI.

    Parameters:
        name (string): Unique frame name for the tab content
        title (string): Display text for the tab button
        options (table, optional): Configuration options
            - loadFunc (function(frame)): Called once when the tab is first shown
            - onShow (function(frame)): Called every time the tab is shown
            - onHide (function(frame)): Called every time the tab is hidden
            - showCategories (boolean): Keep the left category scroll list visible (default: false)
            - showCategoryBackground (boolean): Keep the left pane gold border visible (default: true)
            - showBackground (boolean): Show default background/border (default: true)

    Returns:
        frame (Frame): The main content frame for the tab
        tab (Button): The tab button
]]
function ns.RegisterTab(name, title, options)
    options = options or {}

    -- ========================================================================
    -- Step 1: Create Tab Button
    -- ========================================================================

    -- Find next available tab slot
    local numTabs = 0
    repeat
        numTabs = numTabs + 1
    until (not _G["AchievementFrameTab" .. numTabs])

    -- Create tab button using Blizzard's template
    local tab = CreateFrame("Button", "AchievementFrameTab" .. numTabs, AchievementFrame, "AchievementFrameTabButtonTemplate")
    tab:SetText(title)
    tab:SetID(numTabs)

    -- Anchor to previous tab
    if numTabs > 1 then
        tab:SetPoint("LEFT", "AchievementFrameTab" .. (numTabs - 1), "RIGHT", 0, 0)
    end

    -- NOTE: We intentionally do NOT call PanelTemplates_SetNumTabs() here.
    -- Doing so taints AchievementFrame.numTabs, which propagates through
    -- PanelTemplates_UpdateTabs → PanelTemplates_SelectTab during Blizzard
    -- tab clicks, ultimately causing ADDON_ACTION_FORBIDDEN when protected
    -- functions like C_AchievementTelemetry.LinkAchievementInWhisper are called.

    -- ========================================================================
    -- Step 2: Create Main Content Frame
    -- ========================================================================

    local frame = CreateFrame("Frame", name, AchievementFrame)
    frame:SetSize(504, 440)
    frame:SetPoint("TOPLEFT", AchievementFrameCategories, "TOPRIGHT", 22, 0)
    frame:SetPoint("BOTTOM", AchievementFrameCategories, "BOTTOM")
    frame:Hide()

    if options.showBackground ~= false then
        -- Background texture (matches Blizzard's AchievementFrameAchievements)
        local frameBG = frame:CreateTexture(nil, "BACKGROUND")
        frameBG:SetTexture("Interface\\AchievementFrame\\UI-Achievement-AchievementBackground")
        frameBG:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
        frameBG:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
        frameBG:SetTexCoord(0, 1, 0, 0.5)

        -- Darkening overlay
        local frameBGDarken = frame:CreateTexture(nil, "ARTWORK")
        frameBGDarken:SetAllPoints(frameBG)
        frameBGDarken:SetColorTexture(0, 0, 0, 0.75)

        -- Gold border (same template Blizzard uses for AchievementFrameAchievements)
        local frameBorder = CreateFrame("Frame", nil, frame, "AchivementGoldBorderBackdrop")
        frameBorder:SetAllPoints(frame)
    end

    -- ========================================================================
    -- Step 3: Link Tab and Frame
    -- ========================================================================

    tab.frame = frame
    frame.tab = tab

    tab:SetScript("OnClick", OnTabClick)

    -- ========================================================================
    -- Step 4: Set Up OnShow / OnHide Callbacks
    -- ========================================================================

    local loadFunc = options.loadFunc
    local onShowFunc = options.onShow
    local onHideFunc = options.onHide
    local loaded = false

    if loadFunc or onShowFunc then
        frame:SetScript("OnShow", function(self)
            if loadFunc and not loaded then
                loaded = true
                loadFunc(self)
            end
            if onShowFunc then
                onShowFunc(self)
            end
        end)
    end

    if onHideFunc then
        frame:SetScript("OnHide", function(self)
            onHideFunc(self)
        end)
    end

    -- ========================================================================
    -- Step 5: Hook Blizzard Tab Clicks (First Time Only)
    -- ========================================================================

    if #registeredTabs == 0 then
        hooksecurefunc("AchievementFrameBaseTab_OnClick", OnTabUnselect)
        if AchievementFrameComparisonTab_OnClick then
            hooksecurefunc("AchievementFrameComparisonTab_OnClick", OnTabUnselect)
        end
    end

    -- ========================================================================
    -- Step 6: Track Registration
    -- ========================================================================

    local tabInfo = {
        tab = tab,
        frame = frame,
        name = name,
        title = title,
        showCategories = options.showCategories or false,
        showCategoryBackground = options.showCategoryBackground ~= false, -- default true
--[[
    tab1's watermark
      texture = "Interface\\AchievementFrame\\UI-Achievement-AchievementWatermark",
      texCoords = { 0, 1, 0, 1 },

    tab3's watermark
      texture = "Interface\\AchievementFrame\\UI-Achievement-StatWatermark",
      texCoords = { 0, 1, 0, 1 },
]]
        categoryWaterMark = options.categoryWaterMark, -- { texture = "path", texCoords = {l,r,t,b} }
    }
    tinsert(registeredTabs, tabInfo)

    return frame, tab
end

-- ============================================================================
-- Utility Functions
-- ============================================================================

function ns.GetRegisteredTabs()
    return registeredTabs
end

function ns.GetTabCount()
    return #registeredTabs
end

-- Export to global namespace for debugging
Overachiever2.Tabs = ns
