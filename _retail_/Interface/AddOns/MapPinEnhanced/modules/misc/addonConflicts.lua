---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)
local Options = MapPinEnhanced:GetModule("Options")
local L = MapPinEnhanced.L

local hasEnteredWorld = false
local floatingWarningShown = false
local navigationWarningShown = false

local function WarnAboutWaypointUI()
    if not hasEnteredWorld or not C_AddOns.IsAddOnLoaded("WaypointUI") then return end
    if not floatingWarningShown and
        Options:GetOptionValue("Wayfinder.Selection") == Options.WAYFINDER_SELECTION_FLOATING then
        MapPinEnhanced:Print(L
            ["The Floating wayfinder conflicts with WaypointUI. Consider disabling WaypointUI or switching to the arrow wayfinder."])
        floatingWarningShown = true
    end
    if not navigationWarningShown and Options:GetOptionValue("Navigation.Enable") == true then
        MapPinEnhanced:Print(L
            ["WaypointUI follows Blizzard navigation, so its steps may differ from Map Pin Enhanced’s and show a less ideal route."])
        navigationWarningShown = true
    end
end

-- Wait for the world so normal addons finish loading; also cover load-on-demand addons.
MapPinEnhanced:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    hasEnteredWorld = true
    WarnAboutWaypointUI()
end)

MapPinEnhanced:RegisterEvent("ADDON_LOADED", function(addonName)
    if addonName == "WaypointUI" then
        WarnAboutWaypointUI()
    end
end)

Options:SubscribeToOptionChanges("Wayfinder.Selection", WarnAboutWaypointUI)
Options:SubscribeToOptionChanges("Navigation.Enable", WarnAboutWaypointUI)
