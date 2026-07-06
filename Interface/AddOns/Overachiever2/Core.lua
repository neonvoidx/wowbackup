-- Overachiever2: Core
-- Modern rewritten initialization

local addonName, ns = ...

local Utils = Overachiever2.Utils

-- Expose internal tables on the global table for child addons (e.g. Overachiever2_Tabs)
Overachiever2.DB = ns.DB
Overachiever2.L = ns.L

local function CreateOptionsButton()
    local btn = CreateFrame("Button", "Overachiever2OptionsButton", AchievementFrame)
    btn:SetSize(22, 22)
    btn:SetPoint("RIGHT", AchievementFrameCloseButton, "LEFT", -2, 0)
    -- AchievementFrame.Header is a sibling with enableMouse="true" that covers
    -- this region. Raise our level above the close button so clicks reach us.
    btn:SetFrameLevel(AchievementFrameCloseButton:GetFrameLevel() + 1)

    btn:SetNormalTexture("Interface\\BUTTONS\\UI-OptionsButton")
    btn:SetHighlightTexture("Interface\\BUTTONS\\UI-OptionsButton")
    btn:GetHighlightTexture():SetAlpha(0.5)
    btn:SetPushedTexture("Interface\\BUTTONS\\UI-OptionsButton")
    btn:GetPushedTexture():SetVertexColor(0.7, 0.7, 0.7)

    btn:SetScript("OnClick", function()
        ns.OpenOptions()
    end)

    btn:SetScript("OnEnter", function(self)
        Utils.ShowTip(self, "ANCHOR_TOP", "Overachiever2 " .. ns.L["OPTIONS"])
    end)

    btn:SetScript("OnLeave", Utils.HideTip)
end

local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        Utils.Print(ns.L["CORE_INIT"])
        -- Setup default settings
        Overachiever2_Settings = Overachiever2_Settings or {}
    elseif event == "ADDON_LOADED" and ... == "Blizzard_AchievementUI" then
        CreateOptionsButton()
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Initial cache check or UI hooks could go here later
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", OnEvent)

ns.MainFrame = frame

-- SLASH COMMANDS
-------------------

SLASH_Overachiever21 = "/oa"
SlashCmdList["Overachiever2"] = function(msg)
    msg = msg:trim()
    local cmd, args = msg:match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()

    if cmd == "debug" then
        ns.ToggleDebugMode()
    elseif cmd == "search" then
        if args == "" then
            print("|cff00ff00Overachiever2 Search Debug|r")
            print("Usage: /oa search <query>")
            print("Example: /oa search 20 Dungeon Quests Completed")
        else
            local start = debugprofilestop()
            local results = Overachiever2.SearchAchievementByNameOrID(Overachiever2.GetAllAchievementIDs(), args, false)
            local elapsed = debugprofilestop() - start

            print(string.format("|cff00ff00Found %d achievements in %.2fms|r", #results, elapsed))
            for i = 1, math.min(5, #results) do
                local id, name = GetAchievementInfo(results[i])
                print(string.format("  [%d] %s", id, name))
            end
            if #results > 5 then
                print(string.format("  ... and %d more", #results - 5))
            end
        end
    elseif cmd == "history" then
        if args == "" then
            ns.HistoryPrintStatus()
        elseif args == "clear" then
            ns.HistoryClear()
            Utils.Print(ns.L["HISTORY_CLEARED"])
        elseif args == "back" then
            Overachiever2.HistoryGoBack()
        elseif args == "forward" then
            Overachiever2.HistoryGoForward()
        end
    else
        -- Default: print help
        print(Utils.BlizzardGreenText(ns.L["SLASH_CMD_HELP"]))
        print(ns.L["SLASH_CMD_DEBUG"])
        print(ns.L["SLASH_CMD_SEARCH"])
        print(ns.L["SLASH_CMD_HISTORY"])
        print(ns.L["SLASH_CMD_HISTORY_CLEAR"])
        print(ns.L["SLASH_CMD_HISTORY_BACK"])
        print(ns.L["SLASH_CMD_HISTORY_FORWARD"])
    end
end
