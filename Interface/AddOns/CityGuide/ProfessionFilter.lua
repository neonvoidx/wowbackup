-- Profession filtering for City Guide

-- Map WoW profession IDs to our NPC names
local professionMapping = {
    [171] = {"Alchemy", "Alch"},           -- Alchemy
    [164] = {"Blacksmithing", "BS"},       -- Blacksmithing
    [333] = {"Enchanting", "Ench"},        -- Enchanting
    [202] = {"Engineering", "Engi"},       -- Engineering
    [773] = {"Inscription", "Insc"},       -- Inscription
    [755] = {"Jewelcrafting", "Jewel"},    -- Jewelcrafting
    [165] = {"Leatherworking", "LW"},      -- Leatherworking
    [197] = {"Tailoring", "Tailor"},       -- Tailoring
}

-- Function to get player's main professions (excluding secondaries)
function CityGuide_GetPlayerProfessions()
    local playerProfs = {}
    local prof1, prof2 = GetProfessions()
    
    if prof1 then
        local name, _, _, _, _, _, skillID = GetProfessionInfo(prof1)
        if professionMapping[skillID] then
            table.insert(playerProfs, professionMapping[skillID])
        end
    end
    
    if prof2 then
        local name, _, _, _, _, _, skillID = GetProfessionInfo(prof2)
        if professionMapping[skillID] then
            table.insert(playerProfs, professionMapping[skillID])
        end
    end
    
    return playerProfs
end

-- Function to check if an NPC matches player's professions
function CityGuide_NPCMatchesProfessions(npcName, playerProfs)
    -- If no professions or filter disabled, show everything
    if not playerProfs or #playerProfs == 0 then
        return true
    end
    
    -- Check if this NPC name matches any of the player's profession names
    for _, profNames in ipairs(playerProfs) do
        for _, profName in ipairs(profNames) do
            if npcName == profName then
                return true
            end
        end
    end
    
    return false
end

-- Function to filter NPC list based on profession filter setting
function CityGuide_FilterNPCsByProfession(npcList)
    if not CityGuideConfig.filterByProfession then
        return npcList -- Filter disabled, return all
    end
    
    local playerProfs = CityGuide_GetPlayerProfessions()
    if #playerProfs == 0 then
        return npcList -- No professions learned, show all
    end
    
    local filtered = {}
    for _, npc in ipairs(npcList) do
        -- Always show non-profession NPCs (those with noCluster flag or not in profession list)
        local isProfession = CityGuide_IsProfessionNPC(npc.name)
        
        if not isProfession or CityGuide_NPCMatchesProfessions(npc.name, playerProfs) then
            table.insert(filtered, npc)
        end
    end
    
    return filtered
end

-- Helper function to check if an NPC is a profession trainer
function CityGuide_IsProfessionNPC(npcName)
    local professionNames = {
        "Alchemy", "Blacksmithing", "Enchanting", "Engineering",
        "Inscription", "Jewelcrafting", "Leatherworking", "Tailoring",
        "Alch", "BS", "Ench", "Engi", "Insc", "Jewel", "LW", "Tailor"
    }
    
    for _, profName in ipairs(professionNames) do
        if npcName == profName then
            return true
        end
    end
    
    return false
end