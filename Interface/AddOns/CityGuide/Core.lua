-- Create our main frame
local frame = CreateFrame("Frame")

-- Table to store our label frames so we can clean them up
local activeLabels = {}

-- Configuration
CityGuideConfig = CityGuideConfig or {}
CityGuideConfig.displayMode = CityGuideConfig.displayMode or "smallboth"
CityGuideConfig.filterByProfession = CityGuideConfig.filterByProfession or false
CityGuideConfig.labelSize = CityGuideConfig.labelSize or 1.0
CityGuideConfig.iconSize = CityGuideConfig.iconSize or 1.0
CityGuideConfig.enabledCities = CityGuideConfig.enabledCities or {}
CityGuideConfig.cityIconSizes = CityGuideConfig.cityIconSizes or {}
CityGuideConfig.cityLabelSizes = CityGuideConfig.cityLabelSizes or {}
CityGuideConfig.condenseProfessions = CityGuideConfig.condenseProfessions or {}
CityGuideConfig.showFactionPOIs = CityGuideConfig.showFactionPOIs or false
CityGuideConfig.factionPOIsOnly = CityGuideConfig.factionPOIsOnly or {}
CityGuideConfig.showDecorPOIs = CityGuideConfig.showDecorPOIs ~= false -- Default to true
if CityGuideConfig.useTooltips == nil then
    CityGuideConfig.useTooltips = true -- Default to true for new users
end
-- Default to enabled - only disable if explicitly set to false
CityGuideConfig.showMapWidget = CityGuideConfig.showMapWidget ~= false
-- Waypoint: clicking an icon sets a map waypoint
CityGuideConfig.enableWaypoints = CityGuideConfig.enableWaypoints ~= false
-- Label/icon strata priority: "under" (below quests), "normal", "top" (always on top)
CityGuideConfig.labelPriority = CityGuideConfig.labelPriority or "normal"

-- First-time UX tutorial tracking
CityGuideConfig.tutorialSeen          = CityGuideConfig.tutorialSeen          or false
CityGuideConfig.tutorialRightClicked  = CityGuideConfig.tutorialRightClicked  or false
CityGuideConfig.tutorialMiddleClicked = CityGuideConfig.tutorialMiddleClicked or false

-- Function to clear old labels
local function ClearLabels()
    for i, label in ipairs(activeLabels) do
        label:Hide()
    end
    activeLabels = {}
end

-- Function to filter NPCs by faction
local function FilterNPCsByFaction(npcList, mapID)
    local filtered = {}
    for _, npc in ipairs(npcList) do
        if CityGuide_ShouldShowNPCByFaction(npc, mapID, npcList) then
            table.insert(filtered, npc)
        end
    end
    return filtered
end

-- Function to filter NPCs by decor setting
local function FilterNPCsByDecor(npcList)
    local filtered = {}
    for _, npc in ipairs(npcList) do
        if CityGuide_ShouldShowNPCByDecor(npc) then
            -- Create a copy of the NPC with cleaned name
            local cleanedNPC = {}
            for k, v in pairs(npc) do
                cleanedNPC[k] = v
            end
            -- Clean the name (removes "Decor" from middle of names when setting is off)
            cleanedNPC.name = CityGuide_CleanDecorFromName(npc.name)
            table.insert(filtered, cleanedNPC)
        end
    end
    return filtered
end

-- Function to add labels to the map
function CityGuide_UpdateMapLabels()
    ClearLabels()

    if not WorldMapFrame:IsShown() then
        return
    end

    local mapID = WorldMapFrame:GetMapID()
    
    -- Safety check: Make sure NPCData is loaded
    if not CityGuideNPCData then
        return
    end

    -- FEATURE 1: Show/hide widget based on showMapWidget setting (before city check)
    -- Widget stays visible even when city is disabled
    if mapID and CityGuideNPCData[mapID] then
        if CityGuideConfig.showMapWidget then
            CityGuide_CreateOrUpdateMapButton()
        else
            CityGuide_HideMapButton()
        end
    else
        CityGuide_HideMapButton()
    end

    -- Check if this city is enabled (now only affects labels, not widget)
    if CityGuideConfig.enabledCities[mapID] == false then
        return
    end

    -- If we don't have data for this map, return
    if not (mapID and CityGuideNPCData[mapID]) then
        return
    end

    local canvas = WorldMapFrame:GetCanvas()
    local scale = CityGuide_GetMapScale(mapID)
    
    -- Ensure cityIconSizes and cityLabelSizes tables exist
    CityGuideConfig.cityIconSizes = CityGuideConfig.cityIconSizes or {}
    CityGuideConfig.cityLabelSizes = CityGuideConfig.cityLabelSizes or {}
    
    -- Get per-city size multipliers (default to 1.0 if not set)
    local cityIconMultiplier = CityGuideConfig.cityIconSizes[mapID] or 1.0
    local cityLabelMultiplier = CityGuideConfig.cityLabelSizes[mapID] or 1.0
    local finalIconSize = CityGuideConfig.iconSize * cityIconMultiplier
    local finalLabelSize = CityGuideConfig.labelSize * cityLabelMultiplier
    
    -- Get the full NPC list
    local fullNPCList = CityGuideNPCData[mapID]
    
    -- Apply faction filter first
    local factionFilteredList = FilterNPCsByFaction(fullNPCList, mapID)
    
    -- Then apply decor filter
    local decorFilteredList = FilterNPCsByDecor(factionFilteredList)
    
    -- Finally apply profession filter
    local filteredNPCList = CityGuide_FilterNPCsByProfession(decorFilteredList)

    if CityGuideConfig.displayMode == "icons" then
        -- Icons only - NO CLUSTERING, use original positions, regular square icons
        for i, npc in ipairs(filteredNPCList) do
            local label = CityGuide_CreateIconOnly(canvas, npc.x, npc.y, npc.icon, nil, scale, finalIconSize, nil, npc.name)
            table.insert(activeLabels, label)
        end
        
    elseif CityGuideConfig.displayMode == "smallicons" then
        -- Small Icons only - NO CLUSTERING, use original positions, minimap style
        for i, npc in ipairs(filteredNPCList) do
            local label = CityGuide_CreateIconOnly(canvas, npc.x, npc.y, npc.icon, npc.minimapIcon, scale, finalIconSize, nil, npc.name)
            table.insert(activeLabels, label)
        end
        
    elseif CityGuideConfig.displayMode == "labels" then
        -- Labels only - USE CLUSTERING
        -- Apply profession condensation ONLY for labels
        local labelList = filteredNPCList
        CityGuideConfig.condenseProfessions = CityGuideConfig.condenseProfessions or {}
        if CityGuideConfig.condenseProfessions[mapID] and not CityGuideConfig.filterByProfession then
            local professionHubs = CityGuideProfessionHubs and CityGuideProfessionHubs[mapID]
            if professionHubs then
                labelList = CityGuide_FilterAndAddProfessionHubs(filteredNPCList, professionHubs)
            end
        end
        
        local clusters = CityGuide_ClusterNPCs(labelList)
        
        for _, cluster in ipairs(clusters) do
            local centerX, centerY
            local color, textDirection, labelDistance
            
            -- Check if this is a profession hub marker
            if cluster[1].isProfessionHub then
                local hub = cluster[1]
                centerX = hub.x
                centerY = hub.y
                color = hub.color or "00FF00"
                textDirection = hub.textDirection or "none"
                labelDistance = hub.labelDistance or 1.0
            else
                centerX, centerY = CityGuide_GetClusterCenter(cluster)
                color = cluster[1].color or "FFFFFF"
                textDirection = "none"
                labelDistance = 1.0
            end
            
            local labelText = CityGuide_GetClusterLabel(cluster)
            local label = CityGuide_CreateTextLabel(canvas, centerX, centerY, labelText, scale, textDirection, color, labelDistance, finalLabelSize)
            table.insert(activeLabels, label)
        end
        
    elseif CityGuideConfig.displayMode == "both" then
        -- Icons + Labels mode (regular square icons)
        
        if CityGuideConfig.useTooltips then
            -- Tooltip mode: Show icons with tooltips instead of labels
            -- NO CLUSTERING - each icon gets its own individual tooltip
            for i, npc in ipairs(filteredNPCList) do
                local icon = CityGuide_CreateIconOnly(canvas, npc.x, npc.y, npc.icon, nil, scale, finalIconSize, npc.name)
                table.insert(activeLabels, icon)
            end
        else
            -- Normal mode: Show icons and labels
            -- Show icons for FILTERED list (ALL icons stay, including professions)
            for i, npc in ipairs(filteredNPCList) do
                local icon = CityGuide_CreateIconOnly(canvas, npc.x, npc.y, npc.icon, nil, scale, finalIconSize, nil, npc.name)
                table.insert(activeLabels, icon)
            end
            
            -- Apply profession condensation ONLY for labels
            local labelList = filteredNPCList
            CityGuideConfig.condenseProfessions = CityGuideConfig.condenseProfessions or {}
            if CityGuideConfig.condenseProfessions[mapID] and not CityGuideConfig.filterByProfession then
                local professionHubs = CityGuideProfessionHubs and CityGuideProfessionHubs[mapID]
                if professionHubs then
                    labelList = CityGuide_FilterAndAddProfessionHubs(filteredNPCList, professionHubs)
                end
            end
            
            -- Cluster the label list (may have hubs instead of individual professions)
            local clusters = CityGuide_ClusterNPCs(labelList)
            
            for _, cluster in ipairs(clusters) do
                local centerX, centerY
                local color, textDirection, labelDistance
                
                -- Check if this is a profession hub marker
                if cluster[1].isProfessionHub then
                    local hub = cluster[1]
                    centerX = hub.x
                    centerY = hub.y
                    color = hub.color or "00FF00"
                    textDirection = hub.textDirection or "down"
                    labelDistance = hub.labelDistance or 1.0
                else
                    centerX, centerY = CityGuide_GetClusterCenter(cluster)
                    color = cluster[1].color or "FFFFFF"
                    textDirection = cluster[1].textDirection or "down"
                    labelDistance = cluster[1].labelDistance or 1.0
                end
                
                local labelText = CityGuide_GetClusterLabel(cluster)
                local label = CityGuide_CreateTextLabel(canvas, centerX, centerY, labelText, scale, textDirection, color, labelDistance, finalLabelSize)
                table.insert(activeLabels, label)
            end
        end
        
    elseif CityGuideConfig.displayMode == "smallboth" then
        -- Small Icons + Labels mode (minimap style with glow)
        
        if CityGuideConfig.useTooltips then
            -- Tooltip mode: Show icons with tooltips instead of labels
            -- NO CLUSTERING - each icon gets its own individual tooltip
            for i, npc in ipairs(filteredNPCList) do
                local icon = CityGuide_CreateIconOnly(canvas, npc.x, npc.y, npc.icon, npc.minimapIcon, scale, finalIconSize, npc.name)
                table.insert(activeLabels, icon)
            end
        else
            -- Normal mode: Show icons and labels
            -- Show icons for FILTERED list (ALL icons stay, including professions)
            for i, npc in ipairs(filteredNPCList) do
                local icon = CityGuide_CreateIconOnly(canvas, npc.x, npc.y, npc.icon, npc.minimapIcon, scale, finalIconSize, nil, npc.name)
                table.insert(activeLabels, icon)
            end
            
            -- Apply profession condensation ONLY for labels
            local labelList = filteredNPCList
            CityGuideConfig.condenseProfessions = CityGuideConfig.condenseProfessions or {}
            if CityGuideConfig.condenseProfessions[mapID] and not CityGuideConfig.filterByProfession then
                local professionHubs = CityGuideProfessionHubs and CityGuideProfessionHubs[mapID]
                if professionHubs then
                    labelList = CityGuide_FilterAndAddProfessionHubs(filteredNPCList, professionHubs)
                end
            end
            
            -- Cluster the label list (may have hubs instead of individual professions)
            local clusters = CityGuide_ClusterNPCs(labelList)
            
            for _, cluster in ipairs(clusters) do
                local centerX, centerY
                local color, textDirection, labelDistance
                
                -- Check if this is a profession hub marker
                if cluster[1].isProfessionHub then
                    local hub = cluster[1]
                    centerX = hub.x
                    centerY = hub.y
                    color = hub.color or "00FF00"
                    textDirection = hub.textDirection or "down"
                    labelDistance = hub.labelDistance or 1.0
                else
                    centerX, centerY = CityGuide_GetClusterCenter(cluster)
                    color = cluster[1].color or "FFFFFF"
                    textDirection = cluster[1].textDirection or "down"
                    labelDistance = cluster[1].labelDistance or 1.0
                end
                
                local labelText = CityGuide_GetClusterLabel(cluster)
                local label = CityGuide_CreateTextLabel(canvas, centerX, centerY, labelText, scale, textDirection, color, labelDistance, finalLabelSize)
                table.insert(activeLabels, label)
            end
        end
    end
end

-- Hook into map events
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    print("City Guide addon loaded! Type /cg for commands")

    WorldMapFrame:HookScript("OnShow", CityGuide_UpdateMapLabels)
    WorldMapFrame:HookScript("OnHide", ClearLabels)

    hooksecurefunc(WorldMapFrame, "OnMapChanged", CityGuide_UpdateMapLabels)
end)