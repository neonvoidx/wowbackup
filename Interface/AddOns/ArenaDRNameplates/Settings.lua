local _, ns = ...
ns = ns or {}

local Shared = ns.Shared
local S = Shared.S

local SettingsUI = ns.SettingsUI
if not SettingsUI or not SettingsUI.Initialize then
    print(S("ERR_SETTINGS_UI_MODULE_NOT_LOADED"))
    return
end

local eventFrame = CreateFrame("Frame", SettingsUI.NextFrameName("Settings", "EventFrame"))
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(0.5, function()
            SettingsUI.Initialize()
        end)
    end
end)
