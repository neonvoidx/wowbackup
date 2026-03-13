-- Clustering logic for City Guide

-- Profession names for grouping
local professions = {
    ["Alchemy"] = true,
    ["Blacksmithing"] = true,
    ["Enchanting"] = true,
    ["Engineering"] = true,
    ["Inscription"] = true,
    ["Jewelcrafting"] = true,
    ["Leatherworking"] = true,
    ["Tailoring"] = true,
    ["Alch"] = true,
    ["BS"] = true,
    ["Ench"] = true,
    ["Engi"] = true,
    ["Insc"] = true,
    ["Jewel"] = true,
    ["LW"] = true,
    ["Tailor"] = true,
}

-- Function to check if all items in cluster are professions
local function AreAllProfessions(cluster)
    for _, npc in ipairs(cluster) do
        if not professions[npc.name] then
            return false
        end
    end
    return true
end

-- Function to check if an NPC is a profession
function CityGuide_IsProfessionNPC(npcName)
    return professions[npcName] == true
end

-- Function to generate cluster label text
function CityGuide_GetClusterLabel(cluster)
    -- Check if this is a condensed profession hub
    if cluster.isProfessionHub then
        return cluster.professionHubName or "Profession Tables"
    end
    
    if #cluster == 1 then
        return cluster[1].name
    end
    
    if #cluster == 2 then
        return cluster[1].name .. " & " .. cluster[2].name
    end
    
    -- Check if all are professions
    if AreAllProfessions(cluster) then
        -- Sort professions by X coordinate (left to right)
        local sortedProfs = {}
        for _, npc in ipairs(cluster) do
            table.insert(sortedProfs, npc)
        end
        table.sort(sortedProfs, function(a, b) return a.x < b.x end)
        
        -- Create comma-separated list of profession names
        local profNames = {}
        for _, prof in ipairs(sortedProfs) do
            table.insert(profNames, prof.name)
        end
        return table.concat(profNames, ", ")
    end
    
    -- Mixed items - list all names
    local names = {}
    for i, npc in ipairs(cluster) do
        table.insert(names, npc.name)
    end
    return table.concat(names, ", ")
end

-- Function to cluster nearby NPCs
function CityGuide_ClusterNPCs(npcList, clusterRadius)
    clusterRadius = clusterRadius or 60 -- Radius for clustering
    local clusters = {}
    local assigned = {}
    
    for i, npc in ipairs(npcList) do
        if not assigned[i] then
            -- If this NPC has noCluster flag, create a cluster with just itself
            if npc.noCluster then
                table.insert(clusters, {npc})
                assigned[i] = true
            else
                -- Start a new cluster
                local cluster = {npc}
                assigned[i] = true
                
                -- Find all nearby NPCs (that also don't have noCluster)
                for j, otherNpc in ipairs(npcList) do
                    if not assigned[j] and not otherNpc.noCluster then
                        local distance = CityGuide_CalculateDistance(npc.x, npc.y, otherNpc.x, otherNpc.y)
                        if distance < clusterRadius then
                            table.insert(cluster, otherNpc)
                            assigned[j] = true
                        end
                    end
                end
                
                table.insert(clusters, cluster)
            end
        end
    end
    
    return clusters
end

-- NEW SIMPLIFIED APPROACH: Filter out profession NPCs and add hub labels instead
function CityGuide_FilterAndAddProfessionHubs(npcList, professionHubs)
    if not professionHubs then
        return npcList  -- No hubs defined, return as-is
    end
    
    -- Check if professionHubs is a single hub (old format) or multiple hubs (new format)
    -- Old format: {x = ..., y = ...} (has x field directly)
    -- New format: {{x = ..., y = ...}, {...}} (first element is a table with x)
    local isMultipleHubs = type(professionHubs[1]) == "table" and professionHubs[1].x ~= nil
    local hubsList = isMultipleHubs and professionHubs or {professionHubs}
    
    local filtered = {}
    local professionsByFaction = {
        neutral = false,    -- neutral professions exist?
        Horde = false,
        Alliance = false
    }
    
    -- Pass 1: Check which faction groups have professions
    for _, npc in ipairs(npcList) do
        if CityGuide_IsProfessionNPC(npc.name) then
            local factionKey = npc.faction or "neutral"
            professionsByFaction[factionKey] = true
        end
    end
    
    -- Pass 2: Filter out professions, keep everything else
    for _, npc in ipairs(npcList) do
        if not CityGuide_IsProfessionNPC(npc.name) then
            -- Not a profession, keep it
            table.insert(filtered, npc)
        end
        -- Professions are filtered out (not added to filtered list)
    end
    
    -- Pass 3: Add hub labels for faction groups that have professions
    for _, hub in ipairs(hubsList) do
        local hubFaction = hub.faction or "neutral"  -- nil for neutral, "Horde", or "Alliance"
        
        if professionsByFaction[hubFaction] then
            -- This faction group has professions, add the hub label
            local hubNPC = {
                x = hub.x,
                y = hub.y,
                name = hub.name or "Profession Tables",
                icon = "Interface\\Icons\\Trade_Alchemy",  -- Dummy icon
                minimapIcon = "Interface\\Minimap\\Tracking\\Profession",
                color = hub.color or "00FF00",
                textDirection = hub.textDirection or "none",
                labelDistance = hub.labelDistance or 1.0,
                noCluster = true,  -- Don't cluster hub labels
                isProfessionHub = true  -- Mark as hub for special handling
            }
            
            table.insert(filtered, hubNPC)
        end
    end
    
    return filtered
end

-- Old condensation function - kept for backward compatibility but no longer used
function CityGuide_CondenseProfessionClusters(clusters, professionHubs)
    -- This function is no longer used with the new approach
    -- Keeping it here to avoid breaking anything that might reference it
    return clusters
end