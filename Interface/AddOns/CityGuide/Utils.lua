-- Utility functions for City Guide

-- Function to get scale for current map
function CityGuide_GetMapScale(mapID)
    -- Get scales from registry
    local scales = CityGuide_GetCityScales()
    return scales[mapID] or 1.0
end

-- Function to calculate distance between two points
function CityGuide_CalculateDistance(x1, y1, x2, y2)
    local dx = (x1 - x2) * 1000
    local dy = (y1 - y2) * 1000
    return math.sqrt(dx * dx + dy * dy)
end

-- Function to get cluster center position
function CityGuide_GetClusterCenter(cluster)
    local sumX, sumY = 0, 0
    for _, npc in ipairs(cluster) do
        sumX = sumX + npc.x
        sumY = sumY + npc.y
    end
    return sumX / #cluster, sumY / #cluster
end

-- Function to get player's faction
function CityGuide_GetPlayerFaction()
    local factionName = UnitFactionGroup("player")
    -- Returns "Alliance" or "Horde"
    return factionName
end

-- Function to check if there's a faction-specific version of this NPC for the player
local function HasFactionSpecificVersion(npcName, npcList, playerFaction)
    for _, npc in ipairs(npcList) do
        if npc.name == npcName and npc.faction == playerFaction then
            return true
        end
    end
    return false
end

-- Function to check if NPC should be shown based on faction
function CityGuide_ShouldShowNPCByFaction(npc, mapID, fullNPCList)
    -- Check if this city has "Faction POIs Only" mode enabled (Silvermoon-specific feature)
    CityGuideConfig.factionPOIsOnly = CityGuideConfig.factionPOIsOnly or {}
    if CityGuideConfig.factionPOIsOnly[mapID] then
        local playerFaction = CityGuide_GetPlayerFaction()
        
        -- If this is a faction-tagged POI that matches player's faction, show it
        if npc.faction == playerFaction then
            return true
        end
        
        -- If this is a neutral POI (no faction field)
        if not npc.faction then
            -- Check if there's a faction-specific version with the same name
            if HasFactionSpecificVersion(npc.name, fullNPCList, playerFaction) then
                return false  -- Hide this neutral version since faction-specific exists
            else
                return true  -- Show neutral POI because no faction-specific version exists
            end
        end
        
        -- Hide faction POIs that don't match player's faction
        return false
    end
    
    -- Normal mode: Check global faction POI setting
    -- If NPC has no faction field, always show it (neutral POI)
    if not npc.faction then
        return true
    end
    
    -- If faction POIs setting is disabled globally, hide faction-flagged POIs
    if not CityGuideConfig.showFactionPOIs then
        return false  -- Hide faction-specific POIs when setting is off
    end
    
    -- Setting is enabled, check if NPC's faction matches player's faction
    local playerFaction = CityGuide_GetPlayerFaction()
    return npc.faction == playerFaction
end

-- Function to check if NPC name starts with "Decor"
local function StartsWithDecor(npcName)
    return npcName:match("^Decor") ~= nil
end

-- Function to check if NPC should be shown based on decor filter
function CityGuide_ShouldShowNPCByDecor(npc)
    -- If decor POIs are disabled and this NPC starts with "Decor", hide it
    if not CityGuideConfig.showDecorPOIs and StartsWithDecor(npc.name) then
        return false
    end
    return true
end

-- Function to clean decor text from NPC names
-- Removes "Decor\n" or "\nDecor" from names that contain but don't start with Decor
function CityGuide_CleanDecorFromName(npcName)
    -- If setting is disabled and name contains but doesn't start with "Decor", remove it
    if not CityGuideConfig.showDecorPOIs then
        -- Remove "Decor\n" (Decor followed by newline)
        npcName = npcName:gsub("Decor\n", "")
        -- Remove "\nDecor" (newline followed by Decor)
        npcName = npcName:gsub("\nDecor", "")
        -- Trim any extra whitespace
        npcName = npcName:match("^%s*(.-)%s*$")
    end
    return npcName
end