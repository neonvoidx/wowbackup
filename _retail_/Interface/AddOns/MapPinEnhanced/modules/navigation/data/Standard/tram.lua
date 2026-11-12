---@class MapPinEnhanced
local MapPinEnhanced = select(2, ...)
local Navigation = MapPinEnhanced:GetModule("Navigation")

local TRAM = {
    -- Model the whole journey at the city entrances. The interior map does not
    -- provide separate station geometry and would let implicit walking skip the ride.
    -- Zone: Stormwind City (map 84)
    -- Stormwind City (map 84 69.62,31.11) -> Ironforge (map 87 76.93,51.25) via tram
    {
        fromPointID = 200312,
        fromMap = 84,
        fromX = 0.6962,
        fromY = 0.3111,
        toPointID = 200326,
        toMap = 87,
        toX = 0.7693,
        toY = 0.5125,
        type = "tram",
        travelDuration = 180,
    },
    -- Zone: Ironforge (map 87)
    -- Ironforge (map 87 76.93,51.25) -> Stormwind City (map 84 69.62,31.11) via tram
    {
        fromPointID = 200326,
        fromMap = 87,
        fromX = 0.7693,
        fromY = 0.5125,
        toPointID = 200312,
        toMap = 84,
        toX = 0.6962,
        toY = 0.3111,
        type = "tram",
        travelDuration = 180,
    },
}

Navigation:RegisterPathData("tram", TRAM)
