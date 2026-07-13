-- Overachiever2: Achievement Search Engine
-- Provides search functionality across all achievements with multi-field support
-- Modernized for WoW 12.0+ with async/throttled search using C_Timer

local addonName, ns = ...

local OA2 = Overachiever2

-- Local references for performance
local GetAchievementInfo = GetAchievementInfo
local GetAchievementNumCriteria = GetAchievementNumCriteria
local GetAchievementCategory = GetAchievementCategory
local GetCategoryList = GetCategoryList
local GetGuildCategoryList = GetGuildCategoryList
local strlower = strlower
local strfind = strfind
local tinsert = table.insert
local wipe = wipe

-- ============================================================================
-- Constants
-- ============================================================================

-- Achievement info field indices (from GetAchievementInfo)
local ACHINFO_ID = 1
local ACHINFO_NAME = 2
local ACHINFO_POINTS = 3
local ACHINFO_COMPLETED = 4
local ACHINFO_DESCRIPTION = 8
local ACHINFO_REWARD = 11
local ACHINFO_ISGUILD = 12

-- Special wildcard for "any non-blank" searches
local ANY_NON_BLANK = "~"

-- Search batch size (how many achievements to check before yielding)
local SEARCH_BATCH_SIZE = 100

-- Achievement ID gap threshold (stop scanning after this many consecutive invalid IDs)
local ID_GAP_THRESHOLD = 20000 -- this is a heuristic number, may need to be increased for future expansions

-- ============================================================================
-- Achievement List Cache
-- ============================================================================

local achievementListCache = {
    all = nil,          -- All achievement IDs
    personal = nil,     -- Non-guild achievement IDs
    guild = nil,        -- Guild achievement IDs
    other = nil,        -- Achievements not in any visible category
    standard = nil,     -- Standard (visible) achievement IDs
    standardPersonal = nil,
    standardGuild = nil,
}

-- Get all category IDs (combination of personal and guild categories)
local function GetAllCategories()
    local list1 = GetCategoryList()
    local list2 = GetGuildCategoryList()

    -- Combine both lists
    local combined = {}
    for _, catID in ipairs(list1) do
        combined[#combined + 1] = catID
    end
    for _, catID in ipairs(list2) do
        combined[#combined + 1] = catID
    end

    return combined
end

-- Generate achievement list by scanning all possible IDs
-- filterFunc: optional function(id, categoryID, isGuild) -> bool to include achievement
local function GenerateAchievementList(filterFunc)
    local list = {}
    local gap = 0
    local i = 0

    -- Scan through all possible achievement IDs
    repeat
        i = i + 1
        local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild = GetAchievementInfo(i)

        if id then
            gap = 0

            -- Apply filter if provided
            if not filterFunc or filterFunc(id, GetAchievementCategory(id), isGuild) then
                list[#list + 1] = id
            end
        else
            gap = gap + 1
        end
    until gap > ID_GAP_THRESHOLD

    return list
end

-- Get list of all achievement IDs
function OA2.GetAllAchievementIDs()
    if not achievementListCache.all then
        achievementListCache.all = GenerateAchievementList()
    end
    return achievementListCache.all
end

-- Get list of personal (non-guild) achievement IDs
function OA2.GetPersonalAchievementIDs()
    if not achievementListCache.personal then
        achievementListCache.personal = GenerateAchievementList(function(id, categoryID, isGuild)
            return not isGuild
        end)
    end
    return achievementListCache.personal
end

-- Get list of guild achievement IDs
function OA2.GetGuildAchievementIDs()
    if not achievementListCache.guild then
        achievementListCache.guild = GenerateAchievementList(function(id, categoryID, isGuild)
            return isGuild
        end)
    end
    return achievementListCache.guild
end

-- Get list of "standard" achievement IDs (those visible in UI)
-- This is a simplified version - in the original, it includes achievements in series
function OA2.GetStandardAchievementIDs()
    if not achievementListCache.standard then
        local allCategories = {}
        for _, catID in ipairs(GetAllCategories()) do
            allCategories[catID] = true
        end

        achievementListCache.standard = GenerateAchievementList(function(id, categoryID, isGuild)
            return allCategories[categoryID] ~= nil
        end)
    end
    return achievementListCache.standard
end

-- Get standard personal achievement IDs
function OA2.GetStandardPersonalAchievementIDs()
    if not achievementListCache.standardPersonal then
        local personalCategories = {}
        for _, catID in ipairs(GetCategoryList()) do
            personalCategories[catID] = true
        end

        achievementListCache.standardPersonal = GenerateAchievementList(function(id, categoryID, isGuild)
            return personalCategories[categoryID] ~= nil
        end)
    end
    return achievementListCache.standardPersonal
end

-- Get standard guild achievement IDs
function OA2.GetStandardGuildAchievementIDs()
    if not achievementListCache.standardGuild then
        local guildCategories = {}
        for _, catID in ipairs(GetGuildCategoryList()) do
            guildCategories[catID] = true
        end

        achievementListCache.standardGuild = GenerateAchievementList(function(id, categoryID, isGuild)
            return guildCategories[catID] ~= nil
        end)
    end
    return achievementListCache.standardGuild
end

-- Get "other" achievement IDs (achievements not in any visible category)
function OA2.GetOtherAchievementIDs()
    if not achievementListCache.other then
        local allCategories = {}
        for _, catID in ipairs(GetAllCategories()) do
            allCategories[catID] = true
        end

        achievementListCache.other = GenerateAchievementList(function(id, categoryID, isGuild)
            return allCategories[categoryID] == nil
        end)
    end
    return achievementListCache.other
end

-- Clear cache (useful for debugging or when achievement data changes)
function OA2.ClearAchievementListCache()
    wipe(achievementListCache)
end

-- ============================================================================
-- Search Functions
-- ============================================================================

-- Check if text matches query (case-insensitive substring search)
local function MatchesQuery(text, query, strictCase)
    if not text or text == "" then
        return false
    end

    if query == ANY_NON_BLANK then
        return text ~= ""
    end

    if not strictCase then
        text = strlower(text)
        query = strlower(query)
    end

    return strfind(text, query, 1, true) ~= nil
end

-- Search a specific field of achievements
-- argnum: which return value from GetAchievementInfo to search (2=name, 8=desc, 11=reward)
-- query: search string
-- list: table of achievement IDs to search within
-- strictCase: if true, search is case-sensitive
function OA2.SearchAchievementField(list, argnum, query, strictCase)
    if not query or query == "" then
        return {}
    end

    local results = {}

    for _, id in ipairs(list) do
        local fieldValue = select(argnum, GetAchievementInfo(id))
        if fieldValue and MatchesQuery(fieldValue, query, strictCase) then
            results[#results + 1] = id
        end
    end

    return results
end

-- Search achievement by name or numeric ID
function OA2.SearchAchievementByNameOrID(list, query, strictCase)
    if not query or query == "" then
        return {}
    end

    local results = {}

    -- Check if query is a numeric ID
    local numericID = tonumber(query)
    if not numericID and query:sub(1, 1) == "#" then
        numericID = tonumber(query:sub(2))
    end

    if numericID then
        -- Validate that the ID exists
        local id = GetAchievementInfo(numericID)
        if id then
            results[#results + 1] = numericID
        end
    end

    -- Search by name (skip if we already found exact ID match with limit 1)
    if not numericID or #results == 0 then
        local nameResults = OA2.SearchAchievementField(list, ACHINFO_NAME, query, strictCase)
        for _, id in ipairs(nameResults) do
            -- Avoid duplicates if ID was already added
            if id ~= numericID then
                results[#results + 1] = id
            end
        end
    end

    return results
end

-- Search achievement criteria text
function OA2.SearchAchievementCriteria(list, query, strictCase)
    if not query or query == "" then
        return {}
    end

    local results = {}

    for _, id in ipairs(list) do
        local numCriteria = GetAchievementNumCriteria(id)
        local found = false

        for i = 1, numCriteria do
            local criteriaString = ns.GetAchievementCriteriaInfo(id, i)
            if criteriaString and MatchesQuery(criteriaString, query, strictCase) then
                found = true
                break
            end
        end

        if found then
            results[#results + 1] = id
        end
    end

    return results
end

-- ============================================================================
-- Async/Throttled Search
-- ============================================================================

local activeSearchTask = nil

-- Cancel any running search
local function CancelActiveSearch()
    if activeSearchTask then
        if activeSearchTask.timer then
            activeSearchTask.timer:Cancel()
        end
        activeSearchTask = nil
    end
end

-- Multi-field search (searches name, description, reward, criteria)
-- Used when user enters text in "Any" field
function OA2.SearchMultiField(list, query, strictCase, callback)
    if not query or query == "" then
        callback({})
        return
    end

    CancelActiveSearch()

    local results = {}
    local resultsLookup = {}
    local index = 1

    local function ProcessBatch()
        local batchEnd = math.min(index + SEARCH_BATCH_SIZE - 1, #list)

        for i = index, batchEnd do
            local id = list[i]
            local achID, name, points, completed, month, day, year, description, flags, icon, rewardText = GetAchievementInfo(id)

            if achID and not resultsLookup[id] then
                -- Check name, description, reward, or criteria
                local matches = (name and MatchesQuery(name, query, strictCase))
                    or (description and MatchesQuery(description, query, strictCase))
                    or (rewardText and MatchesQuery(rewardText, query, strictCase))

                if not matches then
                    -- Check criteria
                    local numCriteria = GetAchievementNumCriteria(id)
                    for j = 1, numCriteria do
                        local criteriaString = ns.GetAchievementCriteriaInfo(id, j)
                        if criteriaString and MatchesQuery(criteriaString, query, strictCase) then
                            matches = true
                            break
                        end
                    end
                end

                if matches then
                    results[#results + 1] = id
                    resultsLookup[id] = true
                end
            end
        end

        index = batchEnd + 1

        -- Continue or finish
        if index <= #list then
            activeSearchTask.timer = C_Timer.After(0.01, ProcessBatch)
        else
            callback(results)
            activeSearchTask = nil
        end
    end

    activeSearchTask = { timer = nil }
    ProcessBatch()
end

-- Full search with all fields (name/ID, description, criteria, reward, "any")
-- This is the main search function used by the Search tab
function OA2.StartFullSearch(includeHidden, achType, strictCase, nameOrID, desc, criteria, reward, any, callback)
    CancelActiveSearch()

    -- Get achievement list based on type and visibility filter
    local list
    if includeHidden then
        if achType == "p" then
            list = OA2.GetPersonalAchievementIDs()
        elseif achType == "g" then
            list = OA2.GetGuildAchievementIDs()
        elseif achType == "o" then
            list = OA2.GetOtherAchievementIDs()
        else
            list = OA2.GetAllAchievementIDs()
        end
    else
        if achType == "p" then
            list = OA2.GetStandardPersonalAchievementIDs()
        elseif achType == "g" then
            list = OA2.GetStandardGuildAchievementIDs()
        elseif achType == "o" then
            list = {}  -- "Other" achievements are hidden by definition
        else
            list = OA2.GetStandardAchievementIDs()
        end
    end

    -- Process searches sequentially to narrow down results
    local function DoSearch()
        -- Name/ID search first (most restrictive, can use numeric ID)
        if nameOrID and nameOrID ~= "" then
            list = OA2.SearchAchievementByNameOrID(list, nameOrID, strictCase)
        end

        -- Reward search (relatively rare, narrows quickly)
        if reward and reward ~= "" and #list > 0 then
            list = OA2.SearchAchievementField(list, ACHINFO_REWARD, reward, strictCase)
        end

        -- Description search
        if desc and desc ~= "" and #list > 0 then
            list = OA2.SearchAchievementField(list, ACHINFO_DESCRIPTION, desc, strictCase)
        end

        -- Criteria search (most expensive, do last)
        if criteria and criteria ~= "" and #list > 0 then
            list = OA2.SearchAchievementCriteria(list, criteria, strictCase)
        end

        -- "Any" field search (searches all fields)
        if any and any ~= "" and #list > 0 then
            OA2.SearchMultiField(list, any, strictCase, callback)
        else
            callback(list)
        end
    end

    -- Execute search (small delay to allow UI to update with "Searching..." message)
    C_Timer.After(0.05, DoSearch)
end

-- ============================================================================
-- Export Namespace
-- ============================================================================

ns.Search = {
    GetAllAchievementIDs = OA2.GetAllAchievementIDs,
    GetPersonalAchievementIDs = OA2.GetPersonalAchievementIDs,
    GetGuildAchievementIDs = OA2.GetGuildAchievementIDs,
    SearchMultiField = OA2.SearchMultiField,
    StartFullSearch = OA2.StartFullSearch,
}
