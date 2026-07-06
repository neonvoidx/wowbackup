-- Overachiever2: ChatLinkClick
-- Per-button dispatch for clicks on achievement chat hyperlinks.
-- Uses hooksecurefunc on SetItemRef so the original (secure) path runs first.
-- Replacing the global would taint the chat edit box on shift+click and break
-- SendChatMessage in protected channels (e.g. INSTANCE_CHAT in battlegrounds).

local _, ns = ...

local function OpenAndSelect(achID)
    if InCombatLockdown() then return end
    if not AchievementFrame then
        AchievementFrame_LoadUI()
    end
    if not AchievementFrame:IsShown() then
        ShowUIPanel(AchievementFrame)
    end
    AchievementFrame_SelectAchievement(achID, true)
end

local function IsMiddleClickAchievementOpen(link, button)
    if button ~= "MiddleButton" then return false end
    if not Overachiever2_Settings.EnableMiddleClickOpenAchievement then return false end
    if not link or link:sub(1, 12) ~= "achievement:" then return false end
    local achID = tonumber(link:match("^achievement:(%d+)"))
    if not achID or not C_AchievementInfo.IsValidAchievement(achID) then return false end
    return true, achID
end

-- Fires before SetItemRef from ChatFrameMixin:OnHyperlinkClick. Setting the flag here
-- lets Tooltips.lua's hook bail before it overwrites OA2ClickTooltip, preserving any
-- tooltip already showing for a different achievement.
EventRegistry:RegisterCallback("ChatFrame.OnHyperlinkClick", function(_, _, link, _, button)
    if IsMiddleClickAchievementOpen(link, button) then
        ns.suppressOA2ClickTooltip = true
    end
end, "Overachiever2_ChatLinkClick")

hooksecurefunc("SetItemRef", function(link, text, button, frame)
    local ok, achID = IsMiddleClickAchievementOpen(link, button)
    if not ok then return end
    ItemRefTooltip:Hide()
    OpenAndSelect(achID)
end)
