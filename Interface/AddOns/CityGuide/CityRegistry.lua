-- City Registry - Single source of truth for all city configurations
-- Add new cities here in the order you want them to appear (latest expansion first)

CityGuideRegistry = {
    -- Each entry: {mapID, displayName, scale, allowProfessionCondensation, defaultCondensationEnabled}
    -- Scale: affects label/icon sizing for that map (default 1.0 if not specified)
    -- allowProfessionCondensation: true/false - enables the "Condense Profession Tables" option for this city
    -- defaultCondensationEnabled: true/false - whether condensation is enabled by default (only used if allowProfessionCondensation is true)
    
    {2393, "Silvermoon", 3.0,  true, true},
    {2339, "Dornogal", 3.0, true, false},
    {2472, "Tazavesh (K'aresh)", 1.0, false, false},
    {2112, "Valdrakken", 3.0, true, false},
    {627, "Dalaran (Legion/Remix)", 1.2, false, false},
    {85, "Orgrimmar", 1.0, false, false},
    {84, "Stormwind", 1.0, false, false},
    
    -- To add a new city, just add a line here:
    -- {mapID, "Display Name", scale, allowProfessionCondensation, defaultCondensationEnabled},
}

-- Helper functions to extract data from registry
function CityGuide_GetCityOrder()
    local order = {}
    for _, city in ipairs(CityGuideRegistry) do
        table.insert(order, city[1]) -- mapID
    end
    return order
end

function CityGuide_GetCityNames()
    local names = {}
    for _, city in ipairs(CityGuideRegistry) do
        names[city[1]] = city[2] -- [mapID] = displayName
    end
    return names
end

function CityGuide_GetCityScales()
    local scales = {}
    for _, city in ipairs(CityGuideRegistry) do
        scales[city[1]] = city[3] or 1.0 -- [mapID] = scale (default 1.0)
    end
    return scales
end

function CityGuide_GetCityAllowsProfessionCondensation()
    local allowCondensation = {}
    for _, city in ipairs(CityGuideRegistry) do
        allowCondensation[city[1]] = city[4] or false -- [mapID] = allowProfessionCondensation (default false)
    end
    return allowCondensation
end

function CityGuide_GetCityDefaultCondensation()
    local defaultCondensation = {}
    for _, city in ipairs(CityGuideRegistry) do
        if city[4] then -- Only set defaults for cities that allow condensation
            defaultCondensation[city[1]] = city[5] or false -- [mapID] = defaultCondensationEnabled (default false)
        end
    end
    return defaultCondensation
end