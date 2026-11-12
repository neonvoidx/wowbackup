---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)
local Options = MapPinEnhanced:GetModule("Options")

-- Run after constants and released-save intake, before defaults and XML controls.
local WAYFINDER_SELECTION_OPTION = "Wayfinder.Selection"
local LEGACY_FLOATING_ENABLE_OPTION = "Wayfinder.Floating.Enable"
local LEGACY_ARROW_ENABLE_OPTION = "Wayfinder.Arrow.Enable"

local savedWayfinderSelection = MapPinEnhanced:GetVar("options", WAYFINDER_SELECTION_OPTION)
if savedWayfinderSelection ~= Options.WAYFINDER_SELECTION_ARROW and
    savedWayfinderSelection ~= Options.WAYFINDER_SELECTION_FLOATING then
    local floatingEnabled = MapPinEnhanced:GetVar("options", LEGACY_FLOATING_ENABLE_OPTION)
    local arrowEnabled = MapPinEnhanced:GetVar("options", LEGACY_ARROW_ENABLE_OPTION)
    if floatingEnabled ~= nil or arrowEnabled ~= nil then
        local selection = floatingEnabled == true and Options.WAYFINDER_SELECTION_FLOATING or
            Options.WAYFINDER_SELECTION_ARROW
        MapPinEnhanced:SetVar("options", WAYFINDER_SELECTION_OPTION, selection)
        MapPinEnhanced:DeleteVar("options", LEGACY_FLOATING_ENABLE_OPTION)
        MapPinEnhanced:DeleteVar("options", LEGACY_ARROW_ENABLE_OPTION)
    elseif savedWayfinderSelection ~= nil then
        MapPinEnhanced:DeleteVar("options", WAYFINDER_SELECTION_OPTION)
    end
end

-- Move retired Tiny selections to the smallest available preset before controls load.
for _, key in ipairs({ "Pins.MinimapScale", "Pins.WorldMapScale", "Tracker.Scale" }) do
    if MapPinEnhanced:GetVar("options", key) == 0.75 then
        MapPinEnhanced:SetVar("options", key, 0.9)
    end
end

-- Preserve Large/Huge selections once; 125% is now Huge and must survive later reloads.
if not MapPinEnhanced:GetVar("scalePresets110125Migrated") then
    for _, key in ipairs({ "FlightTimer.Scale", "Pins.MinimapScale", "Pins.WorldMapScale", "Tracker.Scale" }) do
        local scale = MapPinEnhanced:GetVar("options", key)
        if scale == 1.25 then
            MapPinEnhanced:SetVar("options", key, 1.1)
        elseif scale == 1.5 then
            MapPinEnhanced:SetVar("options", key, 1.25)
        end
    end
    MapPinEnhanced:SetVar("scalePresets110125Migrated", true)
end

-- The option becomes authoritative after importing the old frame scale once.
local trackerScaleKey = "Tracker.Scale"
local savedScale = MapPinEnhanced:GetVar("options", trackerScaleKey)
local validScale = false
for _, preset in ipairs(Options.SCALE_PRESETS) do
    if savedScale == preset.value then validScale = true end
end
if not validScale then
    local oldScale = MapPinEnhanced:GetVar("frames", "tracker", "scale")
    if not MapPinEnhanced:IsReadableNumber(oldScale) or oldScale ~= oldScale then oldScale = 1 end
    local nearest = Options.SCALE_PRESETS[1].value
    for _, preset in ipairs(Options.SCALE_PRESETS) do
        if math.abs(preset.value - oldScale) < math.abs(nearest - oldScale) - 0.000001 then
            nearest = preset.value
        end
    end
    MapPinEnhanced:SetVar("options", trackerScaleKey, nearest)
end

-- Keep the released drag lock editable through the current option. Later choices win.
local trackerLockKey = "Tracker.Lock"
if type(MapPinEnhanced:GetVar("options", trackerLockKey)) ~= "boolean" then
    MapPinEnhanced:SetVar("options", trackerLockKey,
        MapPinEnhanced:GetVar("tracker", "lockTracker") == true)
end

-- Retain the saved Close/Minimize choice when replacing the radio group with a checkbox.
local trackerCloseActionKey = "Tracker.CloseAction"
local savedCloseAction = MapPinEnhanced:GetVar("options", trackerCloseActionKey)
if type(savedCloseAction) ~= "boolean" then
    MapPinEnhanced:SetVar("options", trackerCloseActionKey, savedCloseAction == "minimize")
end

-- Preserve a button hidden before visibility became an option. The new preference wins thereafter.
local minimapVisibilityKey = "General.ShowMinimapButton"
if type(MapPinEnhanced:GetVar("options", minimapVisibilityKey)) ~= "boolean" then
    MapPinEnhanced:SetVar("options", minimapVisibilityKey,
        MapPinEnhanced:GetVar("minimapButton", "hide") ~= true)
end

-- Normalize the replaced preferences before XML registers their controls. New
-- values win on every later login, including false and an empty selection.
local beamKey = "Wayfinder.ShowBeam"
if type(MapPinEnhanced:GetVar("options", beamKey)) ~= "boolean" then
    MapPinEnhanced:SetVar("options", beamKey,
        MapPinEnhanced:GetVar("options", "Wayfinder.Floating.Style") ~= "simple")
end
MapPinEnhanced:DeleteVar("options", "Wayfinder.Floating.Style")

local etaKey = "Wayfinder.ShowETA"
if type(MapPinEnhanced:GetVar("options", etaKey)) ~= "boolean" then
    MapPinEnhanced:SetVar("options", etaKey,
        MapPinEnhanced:GetVar("options", "Wayfinder.General.ReadoutMode") ~= "distance")
end
MapPinEnhanced:DeleteVar("options", "Wayfinder.General.ReadoutMode")

-- Keep both route-layer choices, including neither. Missing checkboxes defaulted on.
local routeMapsKey = "Navigation.RouteMaps"
if type(MapPinEnhanced:GetVar("options", routeMapsKey)) ~= "table" then
    local worldMap = MapPinEnhanced:GetVar("options", "Navigation.WorldMap")
    local minimap = MapPinEnhanced:GetVar("options", "Navigation.Minimap")
    if worldMap ~= nil or minimap ~= nil then
        MapPinEnhanced:SetVar("options", routeMapsKey, {
            worldMap = worldMap ~= false or nil,
            minimap = minimap ~= false or nil,
        })
    end
end
MapPinEnhanced:DeleteVar("options", "Navigation.WorldMap")
MapPinEnhanced:DeleteVar("options", "Navigation.Minimap")

-- Retain an explicit dungeon choice; other transportation is always eligible.
local dungeonKey = "Navigation.IncludeDungeonPortals"
if type(MapPinEnhanced:GetVar("options", dungeonKey)) ~= "boolean" then
    local oldGroups = MapPinEnhanced:GetVar("options", "Navigation.TransportationGroups")
    local oldMethods = MapPinEnhanced:GetVar("options", "Wayfinder.Navigation.TransportationMethods")
    local enabled = false
    if type(oldGroups) == "table" then
        enabled = oldGroups.dungeonTeleports == true
    elseif type(oldMethods) == "table" then
        enabled = oldMethods.dungeonteleport == true
    end
    MapPinEnhanced:SetVar("options", dungeonKey, enabled)
end
MapPinEnhanced:DeleteVar("options", "Navigation.TransportationGroups")
MapPinEnhanced:DeleteVar("options", "Wayfinder.Navigation.TransportationMethods")
