local addonName = ...
local L = _G.RCT_LOCALE or {}
local RdysCrateTracker = LibStub("AceAddon-3.0"):GetAddon("RdysCrateTracker", true)

if not RdysCrateTracker then
    error(L["ADDON_NOT_FOUND"] or "RdysCrateTracker addon not found. Please ensure it is loaded.")
end

local function alphaOverlaycheck()
    return LibStub("AceAddon-3.0"):GetAddon("RdysCrateTracker", true) ~= nil
end

RdysCrateTracker.alphaOverlaycheck = alphaOverlaycheck

local vignetteHistory = {}
local seenVignettes = {}
local liveVignettes = {}
local announcedVignettes = {}

local lastSeenPos = nil
local FALLING_ID = 3689
local currentPredictedPoint = nil

local instantMarkIDs = {
    [2967] = true,
    [6066] = true,
    [6067] = true,
    [6068] = true,
}

------------------------------------------------------------
-- STATIC POINTS (MAP ID BASED)
------------------------------------------------------------

-- Immutable defaults table
local staticPointsDefaults = {

    [2214] = { -- Ringing Deeps
        {40.4,31.7},{46.5,41.7},{51.2,41.4},{55.7,72.4},
        {48.7,54.3},{50.6,67.0},{55.69,68.0},{58.6,36.5},{62.87,42.04},
    },

    [2369] = { -- Siren Isle
        {39.9,51.3},{45.5,44.4},{52.9,35.0},{42.4,69.4},
        {30.6,74.7},{52.3,72.1},{65.3,88.1},
    },

    [2255] = { -- Azj-Kahet
        {54.7,53.9},{62.7,66.5},{65.2,83.2},{68.7,55.2},
        {76.6,76.6},{72.6,42.8},{51.3,78.8},{45.0,85.7},{47.1,90.4},
    },

    [2248] = { -- Isle of Dorn
        {29.1,61.8},{40.2,61.3},{59.8,71.1},{56.1,30.4},
        {57.7,41.9},{64.6,23.1},{74.7,57.8},{79.1,46.8},{38.5,78.3},
    },

    [2215] = { -- Hallowfall
        {26.1,53.1},{35.9,45.8},{38.4,54.7},{40.7,34.7},
        {46.4,62.4},{54.3,31.4},{58.1,58.9},{59.3,46.3},{6.1,63.7},
    },

    [2346] = { -- Undermine
        {33.4,67.4},{35.8,19.9},{46.6,63.7},{50.4,14.9},
        {50.4,85.4},{51.9,48.9},{63.2,32.7},{63.2,79.6},{68.9,61.4},
    },

    [2371] = { -- K’aresh
        {45.8,52.0},{65.8,48.8},{51.0,68.1},{72.5,45.3},
        {78.2,49.2},{75.2,25.3},{66.1,41.0},
    },

    --------------------------------------------------
    -- NEW ZONES
    --------------------------------------------------

    [2395] = { -- Eversong Woods
        {41.3,48.1}, {47.7,75.3}, {51.4,51.0}, {57.7,72.7}, {59.0,67.0}, {43.4,87.2}, {60.0, 50.8},
        {39.54,15.80}, {60.53,75.36}, {41.31,57.78}, {75.81,62.14}, {42.27,49.45}
    },

    [2437] = { -- Zul'Aman
        {39.8,27.5}, {46.84,62.1}, {40.2,78.4}, {45.7,37.7}, {46.9,67.2},
        {36.87,67.85}, {32.76,77.55}, {44.35,29.83}, {37.45,34.12}, {48.93,69.26}
    },

    [2413] = { -- Harandar
        {43.2,46.7}, {49.1,72.7}, {59.3,52.8}, {37.4,67.4}, {59.2,52.67}, {38.9, 50.6}, {63.4, 39.2},
        {37.34,68.31}, {42.97,61.36}, {56.49,41.41}
    },

    [2405] = { -- VoidStorm
        {46.20,80.63}, {34.6,64.5}, {59.5,66.6}, {53.4,65.34}, {46.25,80.63}, {59.5, 54.3},
        {38.23,56.83}, {53.85,65.59}, {39.65,68.26}, {49.33,35.53}
    },
    [2444] = { -- Slayer's Rise
        {71.5,58.0}, {29.1,34.7}, {45.6,53.3}, {52.1,82.9}, {61.2,83.2}, {45.1,63.0}, {48.4, 71.1}, {53.8, 42.5},
        {50.78,58.87}, {59.45,54.10}, {71.58,57.41}, {50.54,59.40},
        {45.28,52.80}, {52.44,82.49}, {53.78,41.19}, {53.65,41.71}
    },

}


local staticPoints = {}



local function loadStaticPoints()
    for mapID, points in pairs(staticPointsDefaults) do
        staticPoints[mapID] = {}
        for _, pt in ipairs(points) do
            table.insert(staticPoints[mapID], {pt[1], pt[2]})
        end
    end
end
loadStaticPoints()

------------------------------------------------------------
-- START LOCATIONS
------------------------------------------------------------

local startloc = {

    [2255] = {{62.0,86.9}}, -- Azj-Kahet
    [2215] = {{32.8,21.5}}, -- Hallowfall
    [2248] = {{69.9,75.8}}, -- Isle of Dorn
    [2214] = {{62.1,97.9}}, -- Ringing Deeps
    [2369] = {{95.6,53.9}}, -- Siren Isle
    [2346] = {{22.9,50.1}}, -- Undermine
    [2371] = {{69.8,4.9}},  -- K’aresh

    -- New zones
    [2395] = {{34.2,65.2}}, -- Eversong
    [2437] = {{38.1,21.0}}, -- Zul'Aman
    [2413] = {{47.4,15.1}}, -- Harandar
    [2405] = {{62.2,93.5}}, -- VoidStorm
    [2444] = {{58.8,31.2}}, -- Slayer's Rise

}

------------------------------------------------------------
-- UTILS
------------------------------------------------------------

local function distance(x1,y1,x2,y2)
    return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end


local function isFarFromAll(points, x, y, minDist)
    if not points then return true end
    for _, pt in ipairs(points) do
        if distance(x, y, pt[1], pt[2]) < minDist then
            return false
        end
    end
    return true
end

local function saveStaticPoint(mapID, x, y, minDist)
    if not RdysCrateTracker or not RdysCrateTracker.db or not RdysCrateTracker.db.profile then return end
    local staticPointsDB = RdysCrateTracker.db.profile.staticPointsDB
    if not staticPointsDB then
        staticPointsDB = {}
        RdysCrateTracker.db.profile.staticPointsDB = staticPointsDB
    end
    staticPointsDB[mapID] = staticPointsDB[mapID] or {}
    if isFarFromAll(staticPointsDB[mapID], x, y, minDist) then
        table.insert(staticPointsDB[mapID], {x, y})
        RdysCrateTracker:Print(string.format("Learned new crate drop: %.2f, %.2f (zone %d)", x, y, mapID))
    end
end

local function getActiveStaticPoints(zoneID)
    if RdysCrateTracker and RdysCrateTracker.db and RdysCrateTracker.db.profile and RdysCrateTracker.db.profile.staticPointsDB then
        local db = RdysCrateTracker.db.profile.staticPointsDB
        if db[zoneID] and #db[zoneID] > 0 then
            return db[zoneID]
        end
    end
    return staticPoints[zoneID]
end

local function predictTargetStaticPoint(zoneID,currentX,currentY)
    local BestPrediction = alphaOverlaycheck()
    if not BestPrediction then return end

    local start = startloc[zoneID] and startloc[zoneID][1]
    local candidates = getActiveStaticPoints(zoneID)
    if not start or not candidates then return end

    local sx,sy = start[1]/100,start[2]/100
    local bestMatch
    local bestAngle = math.huge
    for _,pt in ipairs(candidates) do
        local tx,ty = pt[1]/100,pt[2]/100
        local dx1,dy1 = tx-sx,ty-sy
        local dx2,dy2 = currentX-sx,currentY-sy
        local len1 = distance(sx,sy,tx,ty)
        local len2 = distance(sx,sy,currentX,currentY)
        if len1>0 and len2>0 then
            local dot = (dx1*dx2+dy1*dy2)/(len1*len2)
            local angle = math.acos(dot)
            if angle<0.15 and angle<bestAngle then
                bestAngle=angle
                bestMatch={x=pt[1],y=pt[2]}
            end
        end
    end
    return bestMatch
end

local function markWaypoint(mapID,x,y)

    if not mapID or not x or not y then return end

    local point = UiMapPoint.CreateFromCoordinates(mapID,x,y)
    if not point then return end

    C_Map.ClearUserWaypoint()
    C_Map.SetUserWaypoint(point)
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
end

local function pointsAreEqual(a,b)

    return a and b and
        math.abs(a.x-b.x)<0.01 and
        math.abs(a.y-b.y)<0.01
end


local predictframe = CreateFrame("Frame")

local function ReenableEvents()

    predictframe:RegisterEvent("VIGNETTES_UPDATED")
    predictframe:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
end

local function PredictionCrates()

    local db = RdysCrateTracker.db and RdysCrateTracker.db.profile
    if not db then return end

    if not db.enableTomTom then return end
    if not db.enable then return end
    if db.notPvp then return end
    if db.Combatdisable and UnitAffectingCombat("player") then return end

    local rawMapID = C_Map.GetBestMapForUnit("player")
    if not rawMapID then return end

    local zoneID = RdysCrateTracker:NormalizeZoneID(rawMapID)
    if not zoneID then return end

    local vignetteGUIDs = C_VignetteInfo.GetVignettes()

    for _,guid in ipairs(vignetteGUIDs) do

        C_Timer.After(2,function()

            local info = C_VignetteInfo.GetVignetteInfo(guid)
            local pos  = C_VignetteInfo.GetVignettePosition(guid,rawMapID)

            if not info or not pos then return end

            local vignetteID = info.vignetteID
            local x,y = pos.x,pos.y

            if announcedVignettes[guid] then return end



            if vignetteID==FALLING_ID then

                lastSeenPos={x=x,y=y,mapID=rawMapID}
                vignetteHistory[#vignetteHistory+1]=lastSeenPos

                local predicted = predictTargetStaticPoint(zoneID,x,y)

                if predicted and not pointsAreEqual(predicted,currentPredictedPoint) then

                    currentPredictedPoint=predicted

                    markWaypoint(rawMapID,predicted.x/100,predicted.y/100)

                    local message =
                        string.format(
                            "HatedGaming War Supply Crate - Predicted Drop Location: %.1f %.1f",
                            predicted.x,predicted.y
                        )

                    if IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
                        SendChatMessage(message,"RAID")

                    elseif IsInGroup() and UnitIsGroupLeader("player") then
                        SendChatMessage(message,"PARTY")
                    end
                end
            end




            if instantMarkIDs[vignetteID] and not announcedVignettes[guid] then
                announcedVignettes[guid]=true
                markWaypoint(rawMapID,x,y)

                
                saveStaticPoint(zoneID, x*100, y*100, 0.4)

                local message =
                    string.format(
                        "HatedGaming War Supply Crate Dropped - Location: %.1f %.1f",
                        x*100,y*100
                    )

                if IsInRaid() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
                    SendChatMessage(message,"RAID")
                elseif IsInGroup() and UnitIsGroupLeader("player") then
                    SendChatMessage(message,"PARTY")
                end
                predictframe:UnregisterEvent("VIGNETTES_UPDATED")
                predictframe:UnregisterEvent("VIGNETTE_MINIMAP_UPDATED")
                C_Timer.After(30,ReenableEvents)
            end

        end)
    end
end


predictframe:RegisterEvent("VIGNETTES_UPDATED")
predictframe:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
predictframe:SetScript("OnEvent",PredictionCrates)


--[[


-------------------------vig snffer------
local f = CreateFrame("Frame")

local KEYWORDS = {
    "crate",
    "supply",
    "drop",
    "air",
    "plane",
    "machine",
    "drill",
    "parachute",
}

local function IsRelevant(info)

    if not info then return false end

    local name  = info.name and info.name:lower() or ""
    local atlas = info.atlasName and info.atlasName:lower() or ""

    for _, word in ipairs(KEYWORDS) do
        if name:find(word) or atlas:find(word) then
            return true
        end
    end

    return false
end

local seen = {}

local function Scan()

    local rawMapID = C_Map.GetBestMapForUnit("player")
    if not rawMapID then return end

    local zoneID = RdysCrateTracker and RdysCrateTracker:NormalizeZoneID(rawMapID)

    for _, guid in ipairs(C_VignetteInfo.GetVignettes()) do

        if not seen[guid] then

            local info = C_VignetteInfo.GetVignetteInfo(guid)

            if info and IsRelevant(info) then

                seen[guid] = true

                local pos = C_VignetteInfo.GetVignettePosition(guid, rawMapID)

                local x = pos and pos.x * 100 or 0
                local y = pos and pos.y * 100 or 0

                print("|cff00ff00[CRATE DEBUG]|r",
                    info.name or "unknown",
                    "ID:", info.vignetteID,
                    "Map:", rawMapID,
                    "Zone:", zoneID,
                    string.format("(%.1f %.1f)", x, y),
                    "Atlas:", info.atlasName or "nil"
                )
            end

        end

    end

end

f:RegisterEvent("VIGNETTES_UPDATED")
f:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
f:SetScript("OnEvent", Scan)

]]
