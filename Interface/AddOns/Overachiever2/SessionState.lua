-- Overachiever2: Session State
-- Saves and restores the Achievement UI's last viewed tab, category, and achievement across sessions.

local addonName, ns = ...

local Utils = Overachiever2.Utils
local sessionRestored = false
local restoring = false
local achievementWindowOpen = false

-- Expose restoring state for other modules (e.g. History.lua)
function ns.IsSessionRestoring()
    return restoring
end

-- Returns true if the feature is enabled in settings
local function IsEnabled()
    return Overachiever2_Settings and Overachiever2_Settings.RestoreLastView
end

-- Returns the saved session state table (per-character), creating it if needed
local function GetState()
    Overachiever2_CharSettings = Overachiever2_CharSettings or {}
    if not Overachiever2_CharSettings.SessionState then
        Overachiever2_CharSettings.SessionState = {
            lastTab = nil,
            categories = {},
            achievements = {},
        }
    end
    return Overachiever2_CharSettings.SessionState
end

-- Returns true if the Achievement frame is currently in comparison (inspect) mode
local function IsComparisonMode()
    return AchievementFrameComparison and AchievementFrameComparison:IsShown()
end

-- Restore a single tab's category and achievement selection
local function RestoreTab(tabIndex, state)
    -- Restore tab selection
    AchievementFrameBaseTab_OnClick(tabIndex)

    -- Restore category selection
    local savedCategory = state.categories and state.categories[tabIndex]
    if not savedCategory then
        Utils.PrintDebug("RetoreTab: idx=" .. tabIndex .. ", no category")
        return
    end
    AchievementFrame_UpdateAndSelectCategory(savedCategory)

    -- If the saved category is not number, it must be "summary". We don't restore achievement in this case.
    -- Also, statistics tab (3) has no achievement selection
    if type(savedCategory) ~= "number" or tabIndex == 3 then
        Utils.PrintDebug("RetoreTab: idx=" .. tabIndex .. ", cat=" .. savedCategory)
        return
    end

    -- Restore achievement selection (handles category navigation and scrolling internally)
    local savedAchievement = state.achievements and state.achievements[tabIndex]
    if not savedAchievement then
        Utils.PrintDebug("RetoreTab: idx=" .. tabIndex .. ", cat=" .. savedCategory .. ", no achievement")
        return
    end
    if C_AchievementInfo.IsValidAchievement(savedAchievement) then
        AchievementFrame_SelectAchievement(savedAchievement)
    end

    Utils.PrintDebug("RetoreTab: idx=" .. tabIndex .. ", cat=" .. savedCategory .. ", ach=" .. savedAchievement)
end

-- Restore all tabs' selection (tab, category, and achievement)
local function RestoreSessionState()
    if not IsEnabled() or IsComparisonMode() then return end
    if sessionRestored then return end

    local state = GetState()
    local savedTab = state.lastTab
    if not savedTab then return end

    Utils.PrintDebug("RestoreSessionState: savedTab=" .. savedTab)

    -- Suppress tracking hooks during restore
    restoring = true

    -- Restore all tabs that have saved state, then end on the last active tab
    for _, tabIndex in ipairs({1, 2, 3}) do
        if tabIndex ~= savedTab then
            RestoreTab(tabIndex, state)
        end
    end

    -- Restore the last active tab last so it remains visible
    RestoreTab(savedTab, state)

    restoring = false
    sessionRestored = true
end

-- Install hooks on Blizzard_AchievementUI functions
local function InstallHooks()
    -- Hook 1: Track tab switches
    hooksecurefunc("AchievementFrameBaseTab_OnClick", function(tabIndex)
        -- Track the Blizzard's Achievement window's state via `achievementWindowOpen` (Open/Closed)
        -- Additionally, we track if the current click event comes from "window toggle" (Y key).
        -- `windowOpening` indicates the Blizzard's Achievement window is opening now and is used to determine
        -- whether we restore the last tab selection (see below).
        local windowOpening = false
        if not achievementWindowOpen then
            achievementWindowOpen = true
            windowOpening = true
            Utils.PrintDebug("Window Open")
        end

        if not IsEnabled() or IsComparisonMode() then return end
        if restoring then return end

        -- When the achievement window is open, the default UI always calls `AchievementFrameBaseTab_OnClick(1)`.
        -- So we handle the session restoration here.
        if not sessionRestored then
            RestoreSessionState()
            return
        end

        local state = GetState()

        -- If the Achievement window is opening, we restore the tab selection.
        if windowOpening and tabIndex ~= state.lastTab then
            restoring = true
            AchievementFrameBaseTab_OnClick(state.lastTab)
            tabIndex = state.lastTab
            restoring = false
        end

        state.lastTab = tabIndex

        Utils.PrintDebug("Tab=" .. tabIndex)
    end)

    -- Hook 2: Track category selections
    hooksecurefunc("AchievementFrameCategories_SelectElementData", function(elementData)
        if not IsEnabled() or IsComparisonMode() then return end
        if not sessionRestored or restoring then return end

        local state = GetState()
        local tab = state.lastTab or (AchievementFrame and AchievementFrame.selectedTab) or 1
        local categoryId = elementData and elementData.id
        if categoryId then
            state.categories[tab] = categoryId
        end

        -- If a category is clicked, no achievement is selected in the default UI.
        -- Reset achievement to honor this rule.
        if categoryId then
            state.achievements[tab] = nil
        end

        Utils.PrintDebug("Tab=" .. tab .. ", Cat=" .. categoryId)
    end)

    -- Hook 3: Track achievement selections (row clicks go through the mixin)
    local function SaveCurrentAchievement()
        if not IsEnabled() or IsComparisonMode() then return end
        if not sessionRestored or restoring then return end

        local state = GetState()
        local tab = state.lastTab or (AchievementFrame and AchievementFrame.selectedTab) or 1
        if tab == 3 then return end -- Statistics tab has no achievement selection

        local achId = AchievementFrameAchievements_GetSelectedAchievementId()
        if achId then
            state.achievements[tab] = achId
        end

        Utils.PrintDebug("Tab=" .. tab .. ", AchId=" .. achId)
    end

    -- Row click in the achievement list
    hooksecurefunc(AchievementTemplateMixin, "OnClick", function()
        SaveCurrentAchievement()
    end)

    -- Programmatic navigation (search, links, etc.)
    hooksecurefunc("AchievementFrame_SelectAchievement", function(id)
        SaveCurrentAchievement()
    end)

    -- Hook 3: To track the window's state
    AchievementFrame:HookScript("OnHide", function(self)
        -- Track the Blizzard's Achievement window's state via `achievementWindowOpen` (Open/Closed)
        achievementWindowOpen = false
        Utils.PrintDebug("Window Closed")
    end)
end

-- Initialize saved lastTab and install hooks
local function InitAndInstallHooks()
    if IsEnabled() then
        local state = GetState()
        if state and not state.lastTab and AchievementFrame then
            state.lastTab = AchievementFrame.selectedTab or 1
        end
    end
    InstallHooks()
end

-- Wait for Blizzard_AchievementUI to load, then install hooks
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedName)
    if loadedName == "Blizzard_AchievementUI" then
        InitAndInstallHooks()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- If Blizzard_AchievementUI is already loaded (e.g., addon load order), install immediately
if AchievementFrame_OnShow then
    InitAndInstallHooks()
    frame:UnregisterEvent("ADDON_LOADED")
end
