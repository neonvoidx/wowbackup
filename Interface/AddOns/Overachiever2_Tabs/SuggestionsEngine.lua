-- Overachiever2_Tabs: Suggestions Engine
-- Collects zone-appropriate achievement suggestions from DBZone data.

local addonName, ns = ...

local Overachiever2 = _G["Overachiever2"]

-- Field indices for DBZone entries
local F_ACHID = 1           -- Achievement ID (required)
local F_FACTION = 2         -- nil=both, 1=Horde, 2=Alliance
local F_DIFFICULTY = 3      -- nil=any, or WoW difficultyID
local F_CRITERIA_UID = 4    -- nil=entire achievement, or globally unique criteria ID
local F_CRITERIA_INDEX = 5  -- nil=entire achievement, or positional index (1-based)

-- Difficulty inheritance: higher difficulties also show achievements for lower ones
local DifficultyMap = {
    [2]  = {1},           -- Heroic dungeon also shows Normal dungeon achievements
    [9]  = {1},           -- Mythic dungeon also shows Normal dungeon achievements
    [15] = {14},          -- Heroic raid also shows Normal raid achievements
    [16] = {14, 15},      -- Mythic raid also shows Normal + Heroic raid achievements
    [23] = {1, 2, 9},     -- Mythic+ also shows Normal, Heroic, Mythic achievements
}

-- Player faction: 1=Horde, 2=Alliance (matches ATT's r= field convention)
local playerFaction
local function GetPlayerFaction()
    if not playerFaction then
        local eng = UnitFactionGroup("player")
        playerFaction = (eng == "Alliance") and 2 or 1
    end
    return playerFaction
end

-- Check if a difficulty matches the current difficulty (with inheritance)
local function MatchesDifficulty(entryDiff, currentDiff)
    if not entryDiff then return true end          -- nil = any difficulty
    if entryDiff == currentDiff then return true end
    local inherited = DifficultyMap[currentDiff]
    if inherited then
        for _, d in ipairs(inherited) do
            if entryDiff == d then return true end
        end
    end
    return false
end

-- Resolve a cross-reference string like "=147" to the actual mapID
local function ResolveMapID(dbZone, mapID)
    local data = dbZone[mapID]
    if type(data) == "string" and data:sub(1, 1) == "=" then
        local refID = tonumber(data:sub(2))
        if refID then
            return refID, dbZone[refID]
        end
    end
    return mapID, data
end

--[[
    ns.SuggestionsEngine.CollectSuggestions(mapID, options)

    Parameters:
        mapID (number): The map ID to collect suggestions for.
        options (table, optional):
            - includeCompleted (boolean): If true, include completed achievements/criteria.
            - includeOtherFaction (boolean): If true, include achievements from the
                opposite faction.

    Returns: resultsMap (table)
        [achID] = { {criteriaUID, criteriaIndex}, ... }
        or [achID] = {} for achievements with no criteria (or single-criterion).
]]
ns.SuggestionsEngine = {}

-- Check if a single criteria entry is completed.
-- Returns true if the criteria is confirmed complete, false otherwise.
local function IsCriteriaCompleted(achID, criteriaUID, criteriaIndex)
    -- Try by globally unique criteria ID first
    if criteriaUID then
        local ok, cName, _, cCompleted = pcall(GetAchievementCriteriaInfoByID, achID, criteriaUID)
        if ok and cName and cName ~= "" then
            return cCompleted
        end
        -- Fall through to index-based fallback
    end
    -- Fallback: try by positional index
    if criteriaIndex then
        local ok, cName, _, cCompleted = pcall(GetAchievementCriteriaInfo, achID, criteriaIndex)
        if ok and cName and cName ~= "" then
            return cCompleted
        end
    end
    -- Could not determine — treat as incomplete (include it)
    return false
end

function ns.SuggestionsEngine.CollectSuggestions(mapID, options)
    options = options or {}
    local includeCompleted = options.includeCompleted
    local includeOtherFaction = options.includeOtherFaction

    if not Overachiever2 or not Overachiever2.DB or not Overachiever2.DB.Zone then
        return {}
    end

    local dbZone = Overachiever2.DB.Zone
    local _, data = ResolveMapID(dbZone, mapID)
    if not data or type(data) ~= "table" then
        return {}
    end

    local faction = GetPlayerFaction()
    local _, _, currentDifficulty = GetInstanceInfo()

    local results = {}  -- [achID] = { {criteriaUID, criteriaIndex}, ... }

    for _, entry in ipairs(data) do
        local achID = entry[F_ACHID]
        local entryFaction = entry[F_FACTION]
        local entryDiff = entry[F_DIFFICULTY]
        local criteriaUID = entry[F_CRITERIA_UID]
        local criteriaIndex = entry[F_CRITERIA_INDEX]

        -- Faction filter
        if entryFaction and entryFaction ~= faction and not includeOtherFaction then
            -- skip: wrong faction
        -- Difficulty filter
        elseif not MatchesDifficulty(entryDiff, currentDifficulty) then
            -- skip: wrong difficulty
        else
            -- Verify the achievement actually exists
            local _, name, _, completed = GetAchievementInfo(achID)
            if name then
                -- Achievement-level completion check
                if not includeCompleted and completed then
                    -- skip: entire achievement is complete
                elseif criteriaUID or criteriaIndex then
                    -- Has criteria: check completion when filtering
                    if not includeCompleted and IsCriteriaCompleted(achID, criteriaUID, criteriaIndex) then
                        -- skip: criteria is complete
                    else
                        if not results[achID] then
                            results[achID] = {}
                        end
                        results[achID][#results[achID] + 1] = { criteriaUID, criteriaIndex }
                    end
                else
                    -- No criteria in this DB entry — add the achievement itself
                    if not results[achID] then
                        results[achID] = {}
                    end
                end
            end
        end
    end

    return results
end